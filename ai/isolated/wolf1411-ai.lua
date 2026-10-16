-- Fixed wolf1411-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local known = AIValue.requireKnown
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return (self:legacySkillSeed(skill,class,action_request(self,request))) end
local function bind(self,skill,class,costs,request) return (self:bindSkillCard(skill,costs,action_request(self,request),nil,class)) end
local function response(self,skill,class,costs,targets)
    local use=AIUsePlan.new();use.card=bind(self,skill,class,costs,nil);use.to=AIList.new(targets)
    return use:toAnswer()
end
-- No such LuaSkillCard prototypes exist in the fixed rules; do not invent aliases.
local function absent_prototype() return nil end
local function absent_response(wire) ai_unsupported("fixed donor response names missing SkillCard prototype",wire) end
local function visible_card(self,id) return known(self:getKnownCardById(id) or self:getChoiceCard(id),"wolf1411.disclosed_card") end
local function visible_hand(self,player)
    -- Another player's known cards are the hand cards this viewer may see; the
    -- visible-flag subset of the viewer's own hand is not projected.
    if (player:objectName())==(self.player:objectName())then
        ai_unsupported("own visible-flag hand subset is not projected","wolf1411.source_visible_hand_ids")
    end
    return (player:getKnownCards())
end
local function visible_role(self,player)
    local role=player:getRole();if role~=nil then return role end
    return (self:useKnowledgeEstimate({status="estimate",value=(self:getRoleEstimate(player)),basis="viewer_role_estimate_private_role",player=(player:objectName())},"jieffan.role"))
end
local function set_lalong(self,player) self:setStrategyMemory("wolf1411.lalong_target",player and (player:objectName()) or false) end
local function get_lalong(self)
    local name,known=self:getStrategyMemory("wolf1411.lalong_target")
    if known and name then return (self.room:findPlayerByObjectName(name)) end
end
local function current_damage(self)
    -- CurrentDamageStruct is set from DamageDone to DamageComplete and a trigger is
    -- logged when its dispatch ends, so while a Damage/Damaged skill answers the
    -- latest damage event is that damage's DamageDone or Damage stage.
    local event=self:getLastEvent("damage")
    local stage=event and (event:getTriggerEvent())
    if stage~=sgs.DamageDone and stage~=sgs.Damage then ai_unsupported("CurrentDamageStruct is not projected","CurrentDamageStruct")end
    local out={}
    for key,method in pairs({from="getFrom",to="getTo"})do
    local name=AIValue.callKnown(event,method)
        if name~=""then out[key]=(self.room:findPlayerByObjectName(name,true))end
    end
    return out
end
sgs.ai_skill_playerchosen.tengxun = function(self, targets)
	local player_table = {}
	local players = AIList.new({})
	for _, enemy in ipairs(self.enemies) do
		if (enemy:getHandcardNum()) > (self.player:getHandcardNum()) and (self.player:canDiscard(enemy,"h")) and (self:doDisCard(enemy,"h",false,2)) then
			players:append(enemy)
		end
	end
	local enemies = {}
	if (players:isEmpty()) then return nil end
	for _, player in sgs.qlist(players) do
		if (self:isEnemy(player)) then table.insert(enemies, player) end
	end

	self:sortInPlace(enemies, "defense")

	for _, enemy in ipairs(enemies) do
		local cards = visible_hand(self,enemy)
		local flag = string.format("%s_%s_%s", "visible", (self.player:objectName()), (enemy:objectName()))
		if (enemy:getHandcardNum()) <= 2 and not (enemy:isKongcheng()) and (self:doDisCard(enemy,"h",false,2)) then
			for _, cc in ipairs(cards) do
				if true --[[visible_hand is the lawful visible-only subset]] and ((cc:isKindOf("Peach")) or (cc:isKindOf("Analeptic"))) and ((self.player:canDiscard(enemy,(cc:getKnownId())))) then
					table.insert(player_table, enemy)
				end
			end
		end
	end

	self:sortInPlace(enemies, "handcard")
	for _, enemy in ipairs(enemies) do
		if ((self.player:canDiscard(enemy,"h"))) and (self:doDisCard(enemy,"h",false,2)) then
			table.insert(player_table, enemy)
		end
	end
	if #player_table == 0 then return nil else return player_table[1] end
end

sgs.ai_playerchosen_intention.tengxun = 40

local wolfchicheng_skill = {}
wolfchicheng_skill.name = "wolfchicheng"
table.insert(package_skills, wolfchicheng_skill)
wolfchicheng_skill.getTurnUseCard = function(self,inclusive,request)
	if (self.player:getMark("@chicheng")) < 1 then return end
	if not (self.player:isWounded()) then return end
	if (#self.friends <= #self.enemies and (self.room:getTurnCount()) > 2 and (self.player:getLostHp()) > 0) or ((self.room:getTurnCount()) > 1 and (self:isWeak())) or #self.friends > 2 then
		return absent_prototype("#wolfchichengCard")
	end
end

sgs.ai_skill_use_func["#wolfchichengCard"] = function(card, use, self)
	use.card = card
	local min = math.min(3, #self.friends)
	for i = 1, min - 1 do
		if use.to then use.to:append(self.friends[i]) end
	end
end

sgs.ai_card_intention.wolfchichengCard = -80
sgs.ai_use_priority.wolfchichengCard = 9.31


sgs.ai_skill_invoke.xionglie = function(self, data)
	if ((self.player:getPile("incantation")):length()) > 0 then
		local card = visible_card(self,((self.player:getPile("incantation")):first()))
		if not ((self.player:getJudgingArea()):isEmpty()) and not (self.player:containsTrick("YanxiaoCard")) and not (self:hasWizard(self.enemies,true)) then
			local trick = ((self.player:getJudgingArea()):last())
			if (trick:isKindOf("Indulgence")) then
				if (card:getSuit()) == sgs.Card_Heart or ((self.player:hasSkill("hongyan")) and (card:getSuit()) == sgs.Card_Spade) then return false end
			elseif (trick:isKindOf("SupplyShortage")) then
				if (card:getSuit()) == sgs.Card_Club then return false end
			end
		end
		local zhangbao = self.room:findPlayerBySkillName("yingbing")
		if zhangbao and (self:isEnemy(zhangbao)) and not (zhangbao:hasSkill("manjuan"))
			and ((card:isRed()) or ((self.player:hasSkill("hongyan")) and (card:getSuit()) == sgs.Card_Spade)) then
			return false
		end
	end
	for _, p in ipairs(self.enemies) do
		if (self.player:distanceTo(p)) == 1 and not (p:isKongcheng()) then
			return true
		end
	end
	return false
end



sgs.ai_skill_playerchosen.xionglie = function(self, targets)
	local enemies = {}
	local slash = self:getCard("Slash") or (self:getEvaluationCard("slash"))

	for _, target in sgs.qlist(targets) do
		if (self:isEnemy(target)) and not (target:isKongcheng()) then
			table.insert(enemies, target)
		end
	end
	local friends = {}
	for _, target in sgs.qlist(targets) do
		if (self:isFriend(target)) and not (target:isKongcheng()) and (self:doDisCard(target,"h",false)) then
			table.insert(friends, target)
		end
	end
	if #enemies == 1 then
		return enemies[1]
	else
		self:sortInPlace(enemies, "defense")
		for _, enemy in ipairs(enemies) do
			if (enemy:hasSkill("qingguo")) and (self:slashIsEffective(slash,enemy)) then return enemy end
		end
		for _, enemy in ipairs(enemies) do
			if (enemy:hasSkill("kanpo")) then return enemy end
		end
		for _, enemy in ipairs(enemies) do
			if getKnownCard(enemy, self.player, "Jink", false, "h") > 0 and (self:slashIsEffective(slash,enemy)) and (self:isGoodTarget(enemy,self.enemies)) then
				return
					enemy
			end
		end
		for _, enemy in ipairs(enemies) do
			if getKnownCard(enemy, self.player, "Peach", true, "h") > 0 or (enemy:hasSkill("jijiu")) then return enemy end
		end
		for _, enemy in ipairs(enemies) do
			if getKnownCard(enemy, self.player, "Jink", false, "h") > 0 and (self:slashIsEffective(slash,enemy)) then
				return
					enemy
			end
		end
		for _, enemy in ipairs(enemies) do
			if (enemy:hasSkill("longhun")) then return enemy end
		end
		return enemies[1]
	end
	if #enemies == 0 then
		return (friends:first())
	end
	return (targets:first())
end

sgs.hit_skill = sgs.hit_skill .. "|xionglie"

sgs.ai_playerchosen_intention.xionglie = function(self, from, to)
	local intention = 80
	if not (self:doDisCard(to,"h",false)) then
		intention = 0
	end
	self:updateIntention(from,to,intention)
end

ai_audited_aliases.register{id="ai_cardneed.xionglie",registry="ai_cardneed",path={"xionglie"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_skill_cardask["jieffan"] = function(self, data, pattern, target)
	local cards = AIList.new((self.player:getCards("h")))
	self:sortByKeepValueInPlace(cards)
	local c
	local target = (data:toDying()).who
	local damage = (data:toDying()).damage
	for _, card in ipairs(cards) do
		if (card:isKindOf("TrickCard")) then
			c = card
			break
		end
	end
	if c and target then
		if (self:isEnemy(target)) then
			return "$" .. (c:getKnownEffectiveId())
		end
		if (self:isFriend(target)) and visible_role(self,target) == "rebel" then
			if damage and damage.from and (self:isFriend(damage.from)) then return "." end
			for _, friend in ipairs(self.friends) do
				if getKnownCard(friend, self.player, "Peach", true, "h") > 0 then return "." end
				if (friend:getHandcardNum()) > 3 then return "." end
			end
			return "$" .. (c:getKnownEffectiveId())
		end
	end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["jieffan"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local dying = self.room:getCurrentDyingPlayer()
		if not dying then return end
		self:updateIntention(player,dying,80)
	end
end

sgs.ai_cardneed.jieffan = function(to,card, self)
	if not (self:willSkipPlayPhase(to)) then
		return ((card:isKindOf("TrickCard")) and getKnownCard(to, "TrickCard", true) == 0)
	end
end
sgs.jieffan_keep_value = sgs.jizhi_keep_value



local tieti_skill = {}
tieti_skill.name = "tieti"
table.insert(package_skills, tieti_skill)
tieti_skill.getTurnUseCard = function(self,inclusive,request)
	if (self.player:getStrategyHasUsed("#tietiCard")) then return end
	if #self.enemies < 1 then return end
	return absent_prototype("#tietiCard")
end

sgs.ai_skill_use_func["#tietiCard"] = function(card, use, self)
	local cards = AIList.new((self.player:getCards("he")))
	local to_discard = {}
	self:sortByKeepValueInPlace(cards)
	for _, card in ipairs(cards) do
		if (card:isBlack()) and #to_discard < 2 then
			table.insert(to_discard, (card:getKnownEffectiveId()))
		end
	end
	if #to_discard == 2 then
		self:sortInPlace(self.enemies)
		local target
		for _, enemy in ipairs(self.enemies) do
			if (self:objectiveLevel(enemy)) > 3 and not (self:cantbeHurt(enemy))  and (self:damageIsEffective(enemy)) then
				if (self.player:distanceTo(enemy)) == 1 then
					target = enemy
					break
				end
			end
		end
		if target then
			local card_str = string.format("#tietiCard:%s:", table.concat(to_discard, "+"))
			use.card = absent_prototype(card_str)
			if use.to then use.to:append(target) end
			return
		end
	end
end

sgs.ai_use_value["#tietiCard"] = 2.5
sgs.ai_card_intention["#tietiCard"] = 80
sgs.dynamic_value.damage_card["#tietiCard"] = true


sgs.ai_skill_invoke.duanqiao = function(self, data)
	local target = (data:toDamage()).from
	if target then
		if (self:doDisCard(target,"he",false)) then
			return true
		end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.duanqiao = function(self,player,promptlist)
	local damage = current_damage(self)
	if damage.from and promptlist[3]=="yes" and not (self:doDisCard(damage.from,"he")) then
		self:updateIntention(player,damage.from,10)
	end
end

ai_audited_aliases.register{id="ai_cardneed.chenmu",registry="ai_cardneed",path={"chenmu"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_ajustdamage_from.suzhan = function(self, from, to, card, nature)
	if card and (card:isKindOf("Slash")) and ((to:getEquips()):isEmpty())
	then
		return 1
	end
end
ai_audited_aliases.register{id="ai_cardneed.suzhan",registry="ai_cardneed",path={"suzhan"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_use_revises.shuiyan = function(self, card, use)
	if (card:isKindOf("EquipCard"))
	then
		local same = self:getSameEquip(card)
		if same and (same:getSuit()) == (card:getSuit())
		then
			return false
		end
	end
end


local shuiyan_skill = {}
shuiyan_skill.name = "shuiyan"
table.insert(package_skills, shuiyan_skill)
shuiyan_skill.getTurnUseCard = function(self,inclusive,request)
	if ((self.player:getCards("he")):length()) < 3 then return end
	if not (self.player:getStrategyHasUsed("#shuiyanCard")) then
		return absent_prototype("#shuiyanCard")
	end
end

sgs.ai_skill_use_func["#shuiyanCard"] = function(card, use, self)
	local cards = AIList.new((self.player:getCards("he")))
	local to_discard = {}
	self:sortByKeepValueInPlace(cards)
	for _, card in ipairs(cards) do
		if #to_discard < 3 then
			if #to_discard > 0 then
				local same = false
				for i = 1, #to_discard, 1 do
					if (card:getSuit()) == (visible_card(self,to_discard[i]):getSuit()) then
						same = true
						break
					end
				end
				if not same then
					table.insert(to_discard, (card:getKnownEffectiveId()))
				end
			else
				table.insert(to_discard, (card:getKnownEffectiveId()))
			end
		end
	end
	if #to_discard == 3 then
		self:sortInPlace(self.enemies)

		local players = (self.room:getOtherPlayers(self.player))
		if (players:isEmpty()) then return nil end
		local value_e = 0
		local value_f = 0
		for _, player in sgs.qlist(players) do
			local value = 0
			for _, equip in sgs.qlist((player:getEquips())) do
				if (equip:isKindOf("Weapon")) then
					value = value + (self:evaluateWeapon(equip))
				elseif (equip:isKindOf("Armor")) then
					value = value + (self:evaluateArmor(equip))
					if (self:needToThrowArmor()) then value = value - 5 end
				elseif (equip:isKindOf("OffensiveHorse")) then
					value = value + 2.5
				elseif (equip:isKindOf("DefensiveHorse")) then
					value = value + 5
				end
			end
			if (self:hasZhaxiangEffect(player)) then
				value = value + 3
			end
			if (self:isEnemy(player)) then
				value_e = value_e + value
			elseif (self:isFriend(player)) then
				value_f = value_f + value
			end
		end
		if value_e > value_f then
			local card_str = string.format("#shuiyanCard:%s:", table.concat(to_discard, "+"))
			local acard = absent_prototype(card_str)
			use.card = acard
			return
		end
	end
end

-- sgs.ai_card_intention.shuiyan = function(self, card, from, tos)
-- 	for _, to in sgs.qlist((self.room:getOtherPlayers(self.player))) do
-- 		if (self:needToThrowArmor(to)) then
-- 		else
-- 			local intention = 40
-- 			if hasZhaxiangEffect(to) then
-- 				intention = -intention
-- 			end
-- 			self:updateIntention(from,to,intention)
-- 		end
-- 	end
-- end

sgs.ai_use_value.shuiyan = 5
sgs.ai_use_priority.shuiyan = 7



sgs.ai_skill_choice.shuiyan = function(self, choices, data)
	local target = data:toPlayer()
	if (self:needToLoseHp(self.player,target)) or (self:hasZhaxiangEffect(self.player)) and (self:canDraw()) and not (self:willSkipPlayPhase()) and ((self.player:getHp())>0 or hasBuquEffect(self.player) or (self:getSaveNum(true))>0) then
		return "be_lost"
	end
	if (self:isWeak()) and not (self:needDeath()) then return "throw_equips" end

	local value = 0
	for _, equip in sgs.qlist((self.player:getEquips())) do
		if (equip:isKindOf("Weapon")) then
			value = value + (self:evaluateWeapon(equip))
		elseif (equip:isKindOf("Armor")) then
			value = value + (self:evaluateArmor(equip))
			if (self:needToThrowArmor()) then value = value - 5 end
		elseif (equip:isKindOf("OffensiveHorse")) then
			value = value + 2.5
		elseif (equip:isKindOf("DefensiveHorse")) then
			value = value + 5
		end
	end
	if value < 8 then return "throw_equips" else return "be_lost" end
end



local lalong_skill = {}
lalong_skill.name = "lalong"
table.insert(package_skills, lalong_skill)
lalong_skill.getTurnUseCard = function(self,inclusive,request)
	if (self.player:getStrategyHasUsed("#lalongCard")) then return end

	local card
	if (self:needToThrowArmor()) and (self.player:getArmor():getSuit()) == sgs.Card_Spade then
		card = self.player:getArmor()
	end
	if not card then
		local hcards = (self.player:getCards("h"))
		hcards = AIList.new(hcards)
		self:sortByUseValueInPlace(hcards, true)

		for _, hcard in ipairs(hcards) do
			if (hcard:getSuit()) == sgs.Card_Spade then
				card = hcard
				break
			end
		end
	end
	if not card then
		local ecards = (self.player:getCards("e"))
		ecards = AIList.new(ecards)

		for _, ecard in ipairs(ecards) do
			if ((ecard:isKindOf("Weapon")) or (ecard:isKindOf("OffensiveHorse"))) and (ecard:getSuit()) == sgs.Card_Spade then
				card = ecard
				break
			end
		end
	end
	if card then
		card = absent_prototype("#lalongCard",(card:getKnownEffectiveId()))
		return card
	end

	return nil
end

sgs.ai_skill_use_func["#lalongCard"] = function(card, use, self)
	local target
	local friends = self.friends_noself
	local slash = (self:getEvaluationCard("slash"))

	set_lalong(self,nil)

	local canMingceTo = function(player)
		local canGive = not (self:needKongcheng(player,true))
		return canGive or (not canGive and (self:getEnemyNumBySeat(self.player,player)) == 0)
	end

	self:sortInPlace(self.enemies, "defense")
	for _, friend in ipairs(friends) do
		if canMingceTo(friend) and (self:canDraw(friend,self.player)) then
			for _, enemy in ipairs(self.enemies) do
				if (friend:canSlash(enemy)) and not (self:slashProhibit(slash,enemy)) and (self:getDefenseSlash(enemy)) <= 2
					and (self:slashIsEffective(slash,enemy)) and (self:isGoodTarget(enemy,self.enemies,slash))
					and (enemy:objectName()) ~= (self.player:objectName()) then
					target = friend
					set_lalong(self,enemy)
					break
				end
			end
		end
		if target then break end
	end

	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_card_intention.lalongCard = -40

sgs.ai_skill_playerchosen.lalong = function(self, targets)
	local remembered=get_lalong(self)
	if remembered then return remembered end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end
sgs.double_slash_skill = sgs.double_slash_skill .."|lalong"

sgs.ai_skill_playerchosen.renzha = function(self, targets)
	if (self:isWeak()) and (((self.player:getJudgingArea()):length()) == 0) then return nil end
	targets = AIList.new(targets)
	for _, target in ipairs(targets) do
		if (self:isFriend(target)) and (target:isAlive()) then
			if (((self.player:getJudgingArea()):length()) > 0)
				or ((self:isWeak(target)))
				or ((self.player:hasSkills(sgs.lose_equip_skill)) and ((self.player:getEquips()):length()) > 0)
				or ((self.player:hasSkills(sgs.need_kongcheng)) and (self.player:getHandcardNum()) == 1) then
				return target
			end
		end
	end
	return nil
end
-- Existing event-intention registers the audited renzha -> snatch alias.

sgs.ai_playerchosen_intention.renzha = function(self,from,to)
	if hasManjuanEffect(to) then return end
	local intention = -60
	if (self:needKongcheng(to,true)) then intention = 10 end
	self:updateIntention(from,to,intention)
end

sgs.ai_skill_invoke.shengui = function(self, data)
	local target = data:toPlayer()
	if target then
		if not (self:isFriend(target)) then
			if (self:hasHeavyDamage(self.player,nil,target)) and (self:canLiegong(target,self.player)) then
				if (self.player:canDiscard(target,"h")) and getCardsNum("Jink", target, self.player) > 1 then
					return false
				end
			end
			return true
		end
	end
	return false
end
ai_audited_aliases.register{id="ai_cardneed.shengui",registry="ai_cardneed",path={"shengui"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_choicemade_filter.skillInvoke.shengui = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then self:updateIntention(player,target,50) end
	end
end

sgs.hit_skill = sgs.hit_skill .. "|shengui"

sgs.ai_skill_use["@@sheji"] = function(self, prompt)
	local handcardnum = (self.player:getHandcardNum())
	local trash = self:getCard("Disaster") or self:getCard("GodSalvation") or self:getCard("AmazingGrace") or
		self:getCard("Slash") or self:getCard("FireAttack") or self:getCard("Jink") or self:getCard("shuugakulyukou") or
		self:getCard("strike_the_death") or self:getCard("together_go_die") or self:getCard("rotenburo") or
		self:getCard("bunkasai")
	local best_target, target
	local cards = AIList.new((self.player:getCards("h")))
	local to_discard = {}
	for _, card in ipairs(cards) do
		table.insert(to_discard, (card:getKnownEffectiveId()))
	end
	self:sortInPlace(self.enemies, "defenseSlash")
	if handcardnum <= 2 and trash and #self.enemies >= 1 then
		for _, enemy in ipairs(self.enemies) do
			local slash = (self:getEvaluationCard("slash"))
			if (self.player:canSlash(enemy,slash,false)) and not (self:slashProhibit(nil,enemy)) and (self.player:inMyAttackRange(enemy))
				and (self:slashIsEffective(slash,enemy)) and (self:isGoodTarget(enemy,self.enemies)) then
				if (enemy:getHp()) == 1 and getCardsNum("Jink", enemy) == 0 then
					best_target = enemy
					break
				end
				if (self:getDefense(enemy)) < 6 then
					best_target = enemy
					break
				end
			end
		
		end
		for _, enemy in ipairs(self.enemies) do
			local slash = (self:getEvaluationCard("slash"))
			if (self.player:canSlash(enemy,slash,false)) and not (self:slashProhibit(nil,enemy)) and (self.player:inMyAttackRange(enemy))
				and (self:slashIsEffective(slash,enemy)) and (self:isGoodTarget(enemy,self.enemies,slash)) then
				target = enemy
			end
		
		end
	end
	for _, acard in sgs.qlist((self.player:getHandcards())) do
		if isCard("Peach", acard, self.player) and (self.player:getHandcardNum()) > 1 and (self.player:isWounded())
			and not (self:needToLoseHp(self.player)) then
			return "."
		end
	end
	if best_target then
		return absent_response("#shejiCard:" .. table.concat(to_discard, "+") .. ":->" .. (best_target:objectName()))
	end
	if target then
		return absent_response("#shejiCard:" .. table.concat(to_discard, "+") .. ":->" .. (target:objectName()))
	end
end

for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
