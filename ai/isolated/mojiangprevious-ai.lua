-- Source: b6025acc ai/mojiangprevious-ai.lua.
local package_skills={}
local known = AIValue.requireKnown
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return (self:legacySkillSeed(skill,class,action_request(self,request))) end
local function bind(self,skill,class,costs,request) return (self:bindSkillCard(skill,costs,action_request(self,request),nil,class)) end
-- Source Card_Parse in use_func allocates a fresh policy object, not authority.
-- Keep exact ordered costs; only the final selected proposal may bind.
local function fresh_policy(self,skill,class,costs,request)
    return (self:evaluateTurnSkillCard(skill,class,costs,action_request(self,request)))
end
local function response(self,skill,class,costs,targets)
    local use=AIUsePlan.new();use.card=bind(self,skill,class,costs,nil);use.to=AIList.new(targets)
    return use:toAnswer()
end
local function visible_card(self,id) return known(self:getKnownCardById(id),"sanzhi.own_material") end
local function move_count(move)
    if type(move.card_count)=="number" then return move.card_count end
    if move.card_ids then return #move.card_ids end
    ai_unsupported("huangyin move count unknown","sy_old_huangyin")
end
--博略
local sy_old_bolue_skill = {}
sy_old_bolue_skill.name = "sy_old_bolue"
table.insert(package_skills, sy_old_bolue_skill)
sy_old_bolue_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

    if (self.player:getStrategyHasUsed("#sy_old_bolueCard")) then return nil end
	if (self.player:getHp()) <= 0 then return nil end
	return seed(self,"sy_old_bolue","#sy_old_bolueCard",request)
end

ai_card_use["#sy_old_bolueCard"] = function(self, card, use, request)
	use.card = (self:inheritLegacyCardIdentity(bind(self,"sy_old_bolue","#sy_old_bolueCard",{},request),card))
end

sgs.ai_use_value["sy_old_bolueCard"] = 100
sgs.ai_use_priority["sy_old_bolueCard"] = 9.5

--忍忌
ai_skill_invoke.sy_old_renji = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local damage = (data:toDamage())
	if (self:isEnemy(damage.from)) then
	    return (true) or false
	end
	return (false) or false
end

sgs.ai_can_damagehp.sy_old_renji = function(self,from,card,to)
	if from and (to:getHp())+(self:getAllPeachNum())-(self:ajustDamage(from,to,1,card))>0
	and (self:canLoseHp(from,card,to))
	then
		return (self:isEnemy(from)) and (from:getCardCount())>0
	end
end




--归命
ai_skill_invoke.sy_old_guiming = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local dying = (data:toDying())
	local peaches = 1 - (dying.who:getHp())
	return ((self:getCardsNum("Peach")) + (self:getCardsNum("Analeptic")) < peaches) or false
end


--横行
ai_skill_invoke.sy_old_hengxing = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (#(self.player:getEquips()) + (self.player:getHandcardNum()) >= (self.player:getHp()) and (self.player:getHp()) <= 2) or false
end


--恃傲
sgs.ai_skill_playerchosen.sy_old_shiao = function(self, targets)
	local room = self.room
	local tos = {}
	local slash = (self:getEvaluationCard("slash"))
	for _, p in sgs.qlist(targets) do
		if (self:isEnemy(p)) then
			if not (self.player:isProhibited(p,slash)) then table.insert(tos, p) end
		end
	end
	if #tos > 0 then
		self:sortInPlace(tos, "defenseSlash")
		return tos[1]
	else
	    return nil
	end
	return nil
end


--狂袭
ai_skill_invoke.sy_old_kuangxi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local room = self.room
	local use = (data:toCardUse())
	if (use.to:contains(self.player)) then return (false) or false end
	if not (use.card:isNDTrick()) then return (false) or false end
	local F = 0
	local E = 0
	if (use.card:isKindOf("AmazingGrace")) or (use.card:isKindOf("GodSalvation")) then
	    for _, p in sgs.qlist(use.to) do
		    if (self:isFriend(p)) then
			    F = F + 1
			elseif (self:isEnemy(p)) then
			    E = E + 1
			end
		end
		if E - F >= 2 then return (true) or false else return (false) or false end
	end
	if (use.card:isKindOf("IronChain")) then
	    for _, p in sgs.qlist(use.to) do
		    if (self:isFriend(p)) then
			    F = F + 1
			elseif (self:isEnemy(p)) then
			    E = E + 1
			end
		end
		if F == 0 and E > 0 then
		    if math.random(1, 5) > 3 then return (true) or false else return (false) or false end
		end
	end
	for _, p in sgs.qlist(use.to) do
		if (self:isFriend(p)) then
		    F = F + 1
		elseif (self:isEnemy(p)) then
		    E = E + 1
		end
	end
	if F == 0 and E > 0 then
	    local n = 0
	    for _, t in sgs.qlist(use.to) do
		    if (self:isEnemy(t)) and (self:objectiveLevel(t)) > 3 and (self:damageIsEffective(t)) then
			    n = n + 1
			end
		end
		if E == n then
		    if math.random(1, 100) >= 45 then return (true) or false else return (false) or false end
		end
	end
	return (false) or false
end


--布教（旧）
sgs.ai_skill_cardask["@bujiao"] = function(self, data, pattern)
	local cards = AIList.new((self.player:getHandcards()))
	self:sortByKeepValueInPlace(cards)
	local zhangjiao = data:toPlayer()
	local bujiaocard
	if (self:isEnemy(zhangjiao)) or (not (self:isFriend(zhangjiao)))then
		if (self:getCardsNum("Peach")) + (self:getCardsNum("Analeptic")) == #cards then
			bujiaocard = cards[math.random(1, #cards)]
		else
			local bc
			for _, card in ipairs(cards) do
				if (not (card:isKindOf("Peach"))) and (not (card:isKindOf("Analeptic"))) then
					bc = card
					break
				end
			end
			bujiaocard = bc
		end
	else
		if (self:isFriend(zhangjiao)) then
			if ((zhangjiao:containsTrick("SupplyShortage")) or (zhangjiao:containsTrick("Indulgence"))) and (self:getCardsNum("Nullification")) > 0 then
				for _, card in ipairs(cards) do
					if (card:isKindOf("Nullification")) then
						bujiaocard = card
						break
					end
				end
			end
			if not bujiaocard then
				if (self:isWeak(zhangjiao)) and ((self:getCardsNum("Peach")) > 0 or (self:getCardsNum("Analeptic")) > 0) then
					for _, card in ipairs(cards) do
						if (card:isKindOf("Peach")) or (card:isKindOf("Analeptic")) then
							bujiaocard = card
							break
						end
					end
				end
			end
			if not bujiaocard then
				if (zhangjiao:hasSkills("jizhi|nosjizhi")) then
					for _, card in ipairs(cards) do
						if (card:isNDTrick()) then
							bujiaocard = card
							break
						end
					end
				end
			end
			if not bujiaocard then
				if (zhangjiao:hasSkills("qiangxi|sgkgodzhiji")) then
					for _, card in ipairs(cards) do
						if (card:isKindOf("Weapon")) then
							bujiaocard = card
							break
						end
					end
				end
			end
			if not bujiaocard then
				bujiaocard = cards[math.random(1, #cards)]
			end
		end
	end
	if not bujiaocard then
		bujiaocard = cards[math.random(1, #cards)]
	end
	return "$" .. (bujiaocard:getKnownEffectiveId())
end


--太平
sgs.ai_skill_playerchosen.sy_old_taiping = function(self, targets)
    if #self.enemies == 0 then return self.player end
	for _, enemy in ipairs(self.enemies) do
	    return enemy
	end
	return self.enemies[1]
end

ai_skill_invoke.sy_old_taiping = true


--妖惑
local sy_old_yaohuo_skill = {}
sy_old_yaohuo_skill.name = "sy_old_yaohuo"
table.insert(package_skills, sy_old_yaohuo_skill)
sy_old_yaohuo_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

    if (self.player:getStrategyHasUsed("#sy_old_yaohuoCard")) then return nil end
	if #self.enemies <= 0 then return nil end
	if (self.player:isKongcheng()) then return nil end
	return seed(self,"sy_old_yaohuo","#sy_old_yaohuoCard",request)
end

ai_card_use["#sy_old_yaohuoCard"] = function(self, card, use, request)
	local cards = (self.player:getHandcards())
	cards = AIList.new(cards)
	if (self.player:getStrategyHasUsed("#sy_old_yaohuoCard")) then return nil end
	self:sortInPlace(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local target
	local a = (self.player:getHandcardNum()) + #(self.player:getEquips())
	local b = -999
	for _, k in ipairs(self.enemies) do
	    b = math.max(b, (k:getHandcardNum()))
	end
	for _, enemy in ipairs(self.enemies) do
	    if a > (enemy:getHandcardNum()) and (not (enemy:isKongcheng())) and (enemy:getHandcardNum()) == b then
		    target = enemy
		    break
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if a < b then
			    if a > (enemy:getHandcardNum()) and (not (enemy:isKongcheng())) and a - (enemy:getHandcardNum()) <= 2 then
				    target = enemy
					break
				end
			end
		end
	end
	if not target then return nil end
	if target then
	    use.card = (self:inheritLegacyCardIdentity(bind(self,"sy_old_yaohuo","#sy_old_yaohuoCard",{},request),card))
		if use.to then use.to:append(target) end
	end
end


ai_skill_choice.sy_old_yaohuo = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local n = math.random(1, 100)
	local yaohuo = (choices:split("+"))
	if n >= 1 and n <= 98 then
	    return ai_choice_result((yaohuo[1]), options)
	else
	    return ai_choice_result((yaohuo[2]), options)
	end

    return ai_choice_result(nil, options)
end

sgs.ai_use_value["sy_old_yaohuoCard"] = 100
sgs.ai_use_priority["sy_old_yaohuoCard"] = 8
sgs.ai_card_intention["sy_old_yaohuoCard"] = 90

--三治
local sy_old_sanzhi_skill = {}
sy_old_sanzhi_skill.name = "sy_old_sanzhi"
table.insert(package_skills, sy_old_sanzhi_skill)
sy_old_sanzhi_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

    if (self.player:isKongcheng()) then return nil end
	if (self.player:getStrategyHasUsed("#sy_old_sanzhiCard")) then return nil end
	if #self.enemies == 0 then return nil end
	return seed(self,"sy_old_sanzhi","#sy_old_sanzhiCard",request)
end


ai_card_use["#sy_old_sanzhiCard"] = function(self, card, use, request)
    if (self.player:getStrategyHasUsed("#sy_old_sanzhiCard")) then return nil end
	if (self.player:isKongcheng()) then return nil end
	self:sortInPlace(self.enemies)
	local need_cards = {}
	local cards = AIList.new((self.player:getHandcards()))
	self:sortByUseValueInPlace(cards)
	for _,c in ipairs(cards) do
	    if #need_cards == 0 then
		    table.insert(need_cards, (c:getKnownEffectiveId()))
		else
		    local can_do = true
			for _, p in ipairs(need_cards) do
			    if (c:getTypeId()) == (visible_card(self,p):getTypeId()) then
				    can_do = false
					break
				end
			end
			if can_do then
			    table.insert(need_cards, (c:getKnownEffectiveId()))
			end
		end
		if #need_cards == math.min(#self.enemies, 3) then break end
	end
	local to_use = false
	if #self.enemies > 0 then to_use = true end
	if to_use then
	    use.card = fresh_policy(self,"sy_old_sanzhi","#sy_old_sanzhiCard",need_cards,request)
		if use.to then
		    for _, enemy in ipairs(self.enemies) do
				use.to:append(enemy)
				if (use.to:length()) == #need_cards then break end
			end
			assert((use.to:length()) > 0)
		end
	end
end

sgs.ai_card_intention["#sy_old_sanzhiCard"] = function(self, card, from, tos)
    local room = (from:getRoom())
	local huatuo = room:findPlayerBySkillName("jijiu")
	for _,to in ipairs(tos) do
		local intention = 80
		if (to:hasSkill("yiji")) and not (from:hasSkill("jueqing")) then
			if (huatuo and (self:isFriend(huatuo)) and (huatuo:getHandcardNum()) >= 3 and (huatuo:objectName()) ~= (from:objectName())) then
				intention = -30
			end
			if (to:getLostHp()) == 0 and (to:getMaxHp()) >= 3 then
				intention = -10
			end
		end
		if (to:hasSkill("hunzi")) and (to:getMark("hunzi")) == 0 then
			if (to:objectName()) == ((from:getNextAlive()):objectName()) and (to:getHp()) == 2 then
				intention = -20
			end
		end
		if not (self:damageIsEffective(to)) then intention = -20 end
		self:updateIntention(from,to,intention)
	end
end

sgs.ai_use_value["sy_old_sanzhiCard"] = 100
sgs.ai_use_priority["sy_old_sanzhiCard"] = 7


--纵欲
function sgs.ai_cardsview.sy_old_zongyu(self, class_name, player)
	if class_name == "Analeptic" then
		if (player:hasSkill("sy_old_zongyu")) and (player:getHp()) >= 2 then
			return {name="analeptic",skill="sy_old_zongyu",suit=sgs.Card_NoSuit,number=0,subcards={}}
		end
	end
end


--凌虐
ai_skill_invoke.sy_old_lingnue = true
ai_audited_aliases.register{id="ai_cardneed.sy_old_lingnue",registry="ai_cardneed",path={"sy_old_lingnue"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.double_slash_skill = sgs.double_slash_skill .. "|sy_old_lingnue"


--暴政
sgs.ai_skill_cardask["@baozheng_old"] = function(self, data, pattern)
	local cards = AIList.new((self.player:getCards("he")))
	self:sortByKeepValueInPlace(cards)
	local dongzhuo = data:toPlayer()
	local baozhengcard
	local diamond_cards = {}
	if (self:isEnemy(dongzhuo)) or (not (self:isFriend(dongzhuo))) then
		for _, c in ipairs(cards) do
			if (not (c:isKindOf("Peach"))) and (not (c:isKindOf("Analeptic"))) and (c:getSuit()) == sgs.Card_Diamond then
				table.insert(diamond_cards, c)
			end
		end
		if #diamond_cards > 0 then
			self:sortByKeepValueInPlace(diamond_cards)
			baozhengcard = diamond_cards[1]
		else
			return "."
		end
	else
		if (self:isFriend(dongzhuo)) then
			if ((dongzhuo:containsTrick("SupplyShortage")) or (dongzhuo:containsTrick("Indulgence"))) and (self:getCardsNum("Nullification")) > 0 then
				for _, card in ipairs(cards) do
					if (card:isKindOf("Nullification")) and (card:getSuit()) == sgs.Card_Diamond then
						baozhengcard = card
						break
					end
				end
			end
			if not baozhengcard then
				if (self:isWeak(dongzhuo)) and ((self:getCardsNum("Peach")) > 0 or (self:getCardsNum("Analeptic")) > 0) then
					for _, card in ipairs(cards) do
						if ((card:isKindOf("Peach")) or (card:isKindOf("Analeptic"))) and (card:getSuit()) == sgs.Card_Diamond then
							baozhengcard = card
							break
						end
					end
				end
			end
			if not baozhengcard then
				if (dongzhuo:hasSkills("jizhi|nosjizhi")) then
					for _, card in ipairs(cards) do
						if (card:isNDTrick()) and (card:getSuit()) == sgs.Card_Diamond then
							baozhengcard = card
							break
						end
					end
				end
			end
			if not baozhengcard then
				if (dongzhuo:hasSkills("qiangxi|sgkgodzhiji")) then
					for _, card in ipairs(cards) do
						if (card:isKindOf("Weapon")) and (card:getSuit()) == sgs.Card_Diamond then
							baozhengcard = card
							break
						end
					end
				end
			end
			if not baozhengcard then
				for _, c in ipairs(cards) do
					if (c:getSuit()) == sgs.Card_Diamond then
						table.insert(diamond_cards, c)
					end
				end
				if #diamond_cards > 0 then
					self:sortByKeepValueInPlace(diamond_cards)
					baozhengcard = diamond_cards[1]
				else
					return "."
				end
			end
		end
	end
	if not baozhengcard then
		return "."
	end
	return "$" .. (baozhengcard:getKnownEffectiveId())
end
sgs.ai_damage_reason_suppress_intention["sy_old_baozheng"] = true

--醉酒
local sy_old_zuijiu_skill = {}
sy_old_zuijiu_skill.name = "sy_old_zuijiu"
table.insert(package_skills, sy_old_zuijiu_skill)
sy_old_zuijiu_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

    if (self.player:isKongcheng()) then return nil end
	if #self.enemies <= 0 then return nil end
	local s = 0
	for _, enemy in ipairs(self.enemies) do
	    if (self.player:canSlash(enemy)) then s = s + 1 end
	end
	if s <= 0 then return nil end
	if (self:getCardsNum("Slash")) <= 0 then return nil end
	if (self.player:getStrategyHasUsed("#sy_old_zuijiuCard")) then return nil end
    local red_count = 0
	local black_count = 0
	for _, c in sgs.qlist((self.player:getHandcards())) do
	    if (c:isRed()) then
		    red_count = red_count + 1
		elseif (c:isBlack()) then
		    black_count = black_count + 1
		end
	end
	if black_count < red_count then
	    return nil
	else
	    local analeptic = nil -- Fixed extension has no such legacy prototype; preserve subsequent assertion.
		local zuijiu_ana = (self:getEvaluationCard("analeptic"))
		if (self.player:isCardLimited(zuijiu_ana,sgs.Card_MethodUse)) or (self.player:isProhibited(self.player,zuijiu_ana)) then return nil end
		if (self.player:usedTimes("Analeptic")) > (zuijiu_ana:getTargetModResidue()) then return nil end
		if (self:readonlyTurnAvailability(zuijiu_ana)) then
		    assert(analeptic)
		    return analeptic
		end
	end
end

ai_card_use["#sy_old_zuijiuCard"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_use_value["sy_old_zuijiuCard"] = 100
sgs.ai_use_priority["sy_old_zuijiuCard"] = 7.5


--荒淫
ai_skill_invoke.sy_old_huangyin = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local room = self.room
	local move = (data:toMoveOneTime())
	local x = move_count(move)
	local s = 0
	for _, p in ipairs(self.enemies) do
	    if (not (self:isFriend(p))) and #(p:getEquips()) + (p:getHandcardNum()) >= x then
		    s = s + 1
		end
	end
	if s <= 0 then
	    return (false) or false
	else
	    local a = math.random(1, 100)
		return (a >= 70) or false
	end
    return false

end

sgs.ai_skill_playerchosen["huangyin-invoke"] = function(self, targets)
    local room = self.room
	local X = (self.player:getMark("huangyin-AI"))
	local tos = {}
	for _, p in sgs.qlist(targets) do
		if (self:isEnemy(p)) then
		    if #(p:getEquips()) + (p:getHandcardNum()) >= X then table.insert(tos, p) end
		end
	end
	if #tos == 0 then return nil end
	self:sortInPlace(tos, "defense")
	return tos[1]
end


--乱嗣
local sy_old_luansi_skill = {}
sy_old_luansi_skill.name = "sy_old_luansi"
table.insert(package_skills, sy_old_luansi_skill)
sy_old_luansi_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

    if (self.player:getStrategyHasUsed("#sy_old_luansiCard")) then return nil end
	if #self.enemies <= 1 then return nil end
	local j = 0
	for _, p in ipairs(self.enemies) do
	    if (not (p:isNude())) then j = j + 1 end
	end
	if j <= 1 then return nil end
	return seed(self,"sy_old_luansi","#sy_old_luansiCard",request)
end

ai_card_use["#sy_old_luansiCard"] = function(self, card, use, request)
    if (self.player:getStrategyHasUsed("#sy_old_luansiCard")) then return nil end
	local tar1, tar2
	for _, p in ipairs(self.enemies) do
	    if (not (p:isKongcheng())) then
		    tar1 = p
			break
		end
	end
	for _, m in ipairs(self.enemies) do
	    if (m:objectName()) ~= tar1:objectName() and (not (m:isKongcheng())) then
		    tar2 = m
			break
		end
	end
	if tar1 and tar2 then
	    use.card = (self:inheritLegacyCardIdentity(bind(self,"sy_old_luansi","#sy_old_luansiCard",{},request),card))
		if use.to then
		    use.to:append(tar1)
			use.to:append(tar2)
		end
	else
	    return nil
	end
end

sgs.ai_use_value["sy_old_luansiCard"] = 90
sgs.ai_use_priority["sy_old_luansiCard"] = 8
sgs.ai_card_intention["sy_old_luansiCard"] = 90


--诋毁
local sy_old_dihui_skill = {}
sy_old_dihui_skill.name = "sy_old_dihui"
table.insert(package_skills, sy_old_dihui_skill)
sy_old_dihui_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

    if (self.player:getStrategyHasUsed("#sy_old_dihuiCard")) then return nil end
	if #self.enemies <= 0 then return nil end
	if (self.player:getHp()) <= 0 then return nil end
	return seed(self,"sy_old_dihui","#sy_old_dihuiCard",request)
end

ai_card_use["#sy_old_dihuiCard"] = function(self, card, use, request)
	if (self.player:getStrategyHasUsed("#sy_old_dihuiCard")) then return nil end
	local room = self.room
	local max_hp = {}
	local i_max
	local _maxhp = -1000
	local players = (room:getOtherPlayers(self.player))
	for _, p in sgs.qlist((room:getOtherPlayers(self.player))) do
	    _maxhp = math.max(_maxhp, (p:getHp()))
	end
	for _, t in sgs.qlist((room:getOtherPlayers(self.player))) do
	    if (t:getHp()) == _maxhp then
		    table.insert(max_hp, t)
			players:removeOne(t)
			break
		end
	end
	i_max = max_hp[1]
	local targetsB = (room:getOtherPlayers(self.player))
	targetsB:removeOne(i_max)
	local targetsA = AIList.new(targetsB)
	local others = {}
	for _, _player in ipairs(targetsA) do
	    if (self:isEnemy(_player)) then table.insert(others, _player) end
	end
	if i_max and #others > 0 then
	    use.card = (self:inheritLegacyCardIdentity(bind(self,"sy_old_dihui","#sy_old_dihuiCard",{},request),card))
		if use.to then
		    use.to:append(i_max)
		end
	end
end

sgs.ai_skill_playerchosen["dihuiothers-choose"] = function(self, targets)
	local tos = {}
	local players = AIList.new(targets)
	for _, p in ipairs(players) do
	    if (self:isEnemy(p)) then
		    table.insert(tos, p)
		end
	end
	self:sortInPlace(tos, "hp")
	return tos[1]
end


sgs.ai_use_value["sy_old_dihuiCard"] = 100
sgs.ai_use_priority["sy_old_dihuiCard"] = 7


--谗陷
local sy_old_chanxian_skill = {}
sy_old_chanxian_skill.name = "sy_old_chanxian"
table.insert(package_skills, sy_old_chanxian_skill)
sy_old_chanxian_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

    if (self.player:getStrategyHasUsed("#sy_old_chanxianCard")) then return nil end
	if #self.enemies <= 0 then return nil end
	if (self.player:getHandcardNum()) - (self:getCardsNum("Peach")) - (self:getCardsNum("Analeptic")) <= 0 then return nil end
	if (self.player:isKongcheng()) then return nil end
	if (self.player:getHandcardNum()) <= 2 and (self.player:getHp()) <= 2 then return nil end
	return seed(self,"sy_old_chanxian","#sy_old_chanxianCard",request)
end

ai_card_use["#sy_old_chanxianCard"] = function(self, card, use, request)
    if #self.enemies <= 0 then return nil end
    local cards = (self.player:getHandcards())
	cards = AIList.new(cards)
	self:sortByKeepValueInPlace(cards)
	local target
	local enemy_target = {}
	if #self.friends_noself <= 0 then
	    target = self.enemies[1]
	else
	    if #self.enemies > 0 and #self.friends > 0 then
	        target = self.friends[1]
	    end
	end
	if target then
	    local will_use
		if (self:isEnemy(target)) then
		    for _, card in ipairs(cards) do
			    if (not (card:isKindOf("Peach"))) and (not (card:isKindOf("Analeptic"))) and (not (card:isKindOf("Nullification"))) then
				    will_use = card
					break
				end
			end
		end
		if will_use then
		    use.card = fresh_policy(self,"sy_old_chanxian","#sy_old_chanxianCard",{(will_use:getKnownEffectiveId())},request)
			if use.to then use.to:append(target) end
		end
		return
	end
end

sgs.ai_skill_playerchosen["chanxian-choose"] = function(self, targets)
    local to_damage = {}
	local zhangrang = self.room:findPlayerBySkillName("sy_old_chanxian")
	for _, ap in sgs.qlist((self.room:getOtherPlayers(zhangrang))) do
	    if self.player:isEnemy(ap) then
		    table.insert(to_damage, ap)
		end
		if self.player:isFriend(ap) and (ap:getHp()) >= 2 and (self:hasSkills(sgs.masochism_skill,ap)) then
		    table.insert(to_damage, ap)
		end
	end
	return to_damage[1]
end


sgs.ai_use_value["sy_old_chanxianCard"] = 80
sgs.ai_use_priority["sy_old_chanxianCard"] = 5.2

--乱政
ai_skill_choice["sy_old_luanzheng"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local luanzheng = (choices:split("+"))
	return ai_choice_result((luanzheng[math.random(1, #luanzheng)]), options)
end


--嗜杀
sgs.ai_skill_discard.sy_old_shisha = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
	local sunhao
	if self.room:findPlayerBySkillName("sy_old_shisha") then sunhao = self.room:findPlayerBySkillName("sy_old_shisha") end
	if sunhao and (self:needToLoseHp(self.player,sunhao)) then return to_discard end
	local n = math.random(1, 100)
	if (self.player:getHp()) >= 3 or (self:getCardsNum("Peach")) + (self:getCardsNum("Analeptic")) > 0 then
	    if n <= 95 then
		    return to_discard
		else
		    local cards = AIList.new((self.player:getCards("he")))
			self:sortByKeepValueInPlace(cards)
			local index = 0
			for i = #cards, 1, -1 do
			    local card = cards[i]
				if (not isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and (not (self.player:isJilei(card))) then
				    table.insert(to_discard, (card:getKnownEffectiveId()))
			        table.remove(cards, i)
			        index = index + 1
			        if index == 2 then break end
		        end
			end
			if #to_discard < 2 then return {}
			else return to_discard end
		end
	else
	    local cards = AIList.new((self.player:getCards("he")))
		self:sortByKeepValueInPlace(cards, true)
		local index = 0
		for i = #cards, 1, -1 do
		    local card = cards[i]
			if not (isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and not (self.player:isJilei(card)) then
			    table.insert(to_discard, (card:getKnownEffectiveId()))
		        table.remove(cards, i)
		        index = index + 1
		        if index == 2 then break end
	        end
		end
		if #to_discard < 2 then return {}
		else return to_discard end
	end
end


--祸心
ai_skill_choice["sy_old_huoxin"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local huoxin = (choices:split("+"))
	local caifuren = self.room:findPlayerBySkillName("sy_old_huoxin")
	if (self:isFriend(caifuren)) then
	    return ai_choice_result((huoxin[1]), options)
	else
	    return ai_choice_result((huoxin[math.random(1, #huoxin)]), options)
	end

    return ai_choice_result(nil, options)
end
for _,skill in ipairs(package_skills)do ai_fill_skill[skill.name]=skill.getTurnUseCard end
