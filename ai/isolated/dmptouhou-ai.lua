-- Source: b6025acc ai/dmptouhou-ai.lua.
local known = AIValue.requireKnown
local function parse_nil(self,selector)
    -- Whether LuaSkillCard::Parse knows the old selector is not projected.
    ai_unsupported("legacy prototype presence is not projected",selector)
end
local function skills(self,player,names)
    local value=(player:hasSkills(names))
    local row=rawget(player,"_view")
    if value or not row or row.skills_complete==true then return value end
    ai_unsupported("dmptouhou skill absence is not visible",names)
end
local function kuixin_used(self,player)
    return (player:hasFlag("se_kuixin_used"))
end
local function wounded(self)
    local a,b=self:getWoundedFriend(false,true)
    return known(a,"wounded first list"),b -- source returns before reading list2 when target is self
end
local function source_fangquan(self)
    local callback=ai_skill_invoke.fangquan
    if type(callback)~="function"then ai_unsupported("effective fangquan callback is unavailable","se_fuzhi")end
    local value=callback(self, {}, nil);if AIUnsupported.is(value)then error(value,0)end;return value
end
-- The shared immutable identity gate owns cardChosen.se_mingqie -> snatch.
ai_skill_invoke.se_mingqie = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = (data:toCardUse())
	if (self:isEnemy(use.to:at(0))) and not skills(self,use.to:at(0),sgs.lose_equip_skill) then return (true) or false end
	if (self:isFriend(use.to:at(0))) and skills(self,use.to:at(0),sgs.lose_equip_skill) then return (true) or false end
	return (false) or false
end

sgs.ai_cardneed.se_mingqie = function(to, card, self)
	return (card:isKindOf("Dismantlement")) or (card:isKindOf("Snatch"))
end




ai_fill_skill.se_mopao = function(self, options, request)
    local inclusive = options and options.inclusive

	if (self.player:getStrategyHasUsed("#se_mopaocard")) then return end
	if #self.enemies < 1 then return end
	if (self.player:getMark("@p_point")) < 4 then return end
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			if (enemy:getEquips()):length() < 2 and not (self:cantDamageMore(self.player,enemy)) then
				return parse_nil(self,"#se_mopaocard")
			end
		end
	end
	return
end

ai_card_use["#se_mopaocard"] = function(self, card, use, request)
	local target
	self:updatePlayers()
	self:sortInPlace(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if (self:damageIsEffective(enemy,sgs.DamageStruct_Normal)) and not (self:cantDamageMore(self.player,enemy)) then
			target = enemy
			break
		end
	end
	if not target then return end

	local next_man = (self.player:getNextAlive())
	local friend_enemy = 0
	while ((next_man:objectName()) ~= (target:objectName())) do
		if (self:isFriend(next_man)) and (self:damageIsEffective(next_man,sgs.DamageStruct_Normal)) then
			friend_enemy = friend_enemy + 1
		elseif (self:isEnemy(next_man)) and (self:damageIsEffective(next_man,sgs.DamageStruct_Normal)) then
			friend_enemy = friend_enemy - 1
		end
		next_man = (next_man:getNextAlive())
	end
	if friend_enemy < 0 then
		self:setStrategyMemory("dmptouhou.mopao_direction","right")
	else
		self:setStrategyMemory("dmptouhou.mopao_direction","left")
	end
	if target then
		use.card = parse_nil(self,"#se_mopaocard")
		if use.to then use.to:append(target) end
		return
	end
end

ai_skill_choice["se_mopaocard"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local value,present=self:getStrategyMemory("dmptouhou.mopao_direction")
    if not present or(value~="left"and value~="right")then ai_unsupported("source global direction has no viewer-local observation","se_mopaocard")end
    return ai_choice_result((value), options)
end



sgs.ai_use_value["se_mopaocard"]      = 8
sgs.ai_use_priority["se_mopaocard"]   = 2
sgs.ai_card_intention["se_mopaocard"] = 100



sgs.ai_skill_playerchosen.se_wuyi_losehp = function(self, targets)
	local targets = sgs.QList2Table(targets)
	targets=(self:sort(targets,"hp"))
	for _, p in ipairs(targets) do
		if (self:isEnemy(p)) and not (self:hasZhaxiangEffect(p)) then
			return p
		end
	end
	return targets[1]
end


sgs.ai_playerchosen_intention.se_wuyi_losehp = 40

sgs.ai_skill_playerchosen.se_wuyi_draw = function(self, targets)
	local n = (self.player:getMark("se_wuyi-draw"))
	return self:findPlayerToDraw(true,n) --mostPlayer(self, true, 1)
end

sgs.ai_playerchosen_intention.se_wuyi_draw = -40

sgs.ai_skill_playerchosen.se_wuyi_recover = function(self, targets)
	local arr1, arr2 = wounded(self)
	local target = self.player

	if #arr1 > 0 and ((self:isWeak(arr1[1]))) and (arr1[1]:getHp()) < (self:getBestHp(arr1[1])) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not skills(self,friend,"hunzi|longhun") then
				return friend
			end
		end
	end


	return target --mostPlayer(self, true, 3)
end


sgs.ai_playerchosen_intention.se_wuyi_recover = -40

--小五
ai_fill_skill.se_kuixin = function(self, options, request)
    local inclusive = options and options.inclusive

	for _, p in sgs.qlist((self.room:getOtherPlayers(self.player))) do
		if (self.player:distanceTo(p)) == 1 and not kuixin_used(self,p) and (p:getHandcardNum()) > 0 then
			if math.random(1, 5) > 1 then
				return parse_nil(self,"#se_kuixincard")
			end
		end
	end
	return
end
ai_card_use["#se_kuixincard"] = function(self, card, use, request)
	for _, p in sgs.qlist((self.room:getOtherPlayers(self.player))) do
		if (self.player:distanceTo(p)) == 1 and not kuixin_used(self,p) and (p:getHandcardNum()) > 0 then
			use.card = card
			if use.to then use.to:append(p) end
			return
		end
	end
end

sgs.ai_use_value["se_kuixincard"] = 5
sgs.ai_use_priority["se_kuixincard"] = 10

sgs.ai_skill_askforag["se_huixiang"] = function(self, card_ids)
	if (self.player:getJudgingArea()):length() > 0 then
		local hasNull = false
		for _, card in sgs.qlist((self.player:getHandcards())) do
			if (card:isKindOf("Nullification")) then hasNull = true end
		end
		if not hasNull then
			for _, card_id in ipairs(card_ids) do
				if ((self:getChoiceCard(card_id)):isKindOf("Nullification")) then return card_id end
			end
		end
	end
	if (self:isWeak()) then
		for _, card_id in ipairs(card_ids) do
			if ((self:getChoiceCard(card_id)):isKindOf("Peach")) then return card_id end
		end
	end
	local weakF = 0
	for _, p in ipairs(self.friends) do
		if (self:isWeak(p)) then
			weakF = weakF + 1
		end
	end
	for _, card_id in ipairs(card_ids) do
		if ((self:getChoiceCard(card_id)):isKindOf("ExNihilo")) then return card_id end
	end
	if weakF > 1 then
		for _, card_id in ipairs(card_ids) do
			if ((self:getChoiceCard(card_id)):isKindOf("GodSalvation")) then return card_id end
		end
	end
	if #self.enemies - #self.friends > 1 then
		for _, card_id in ipairs(card_ids) do
			if ((self:getChoiceCard(card_id)):isKindOf("AOE")) then return card_id end
		end
	end
	return
end


ai_skill_use["@@se_huixiang"] = function(self, prompt, request)
	local cards = {}
	if (self.player:getPile("satori_memory")):length() < 1 then return "." end
	for _, id in sgs.qlist((self.player:getPile("satori_memory"))) do
		table.insert(cards, (self:getKnownCardById(id)))
	end
	cards=(self:sortByUseValue(cards))
	local give_all_cards = {}
	local max = math.ceil((self.player:getHp()) / 2)
	for _, c in ipairs(cards) do
		if #give_all_cards < max then
			table.insert(give_all_cards, (c:getKnownEffectiveId()))
		end
	end
	local card_str = string.format("#se_huixiang:%s:", table.concat(give_all_cards, "+"))
	parse_nil(self,"#se_huixiang")
    local signal=AIUnsupported.new("dmptouhou donor response prototype is unavailable","@@se_huixiang")
    signal.terminal_response_selection=true;signal.donor_terminal_unavailable=true
    signal.source_wire=card_str;signal.selected_costs=give_all_cards
    error(signal,0)
end


--fuzhi




sgs.ai_skill_playerchosen.se_fuzhi = function(self, targets)
	if (source_fangquan(self)) then
		local AssistTarget = self:AssistTarget()
		if AssistTarget and not (self:willSkipPlayPhase(AssistTarget)) and not known(hasManjuanEffect(AssistTarget),"hasManjuanEffect") and (AssistTarget:getKnownKingdom()) == "touhou" then
			return AssistTarget
		end
		for _, friend in ipairs(self.friends_noself) do
			if not known(hasManjuanEffect(friend),"hasManjuanEffect") and skills(self,friend,sgs.cardneed_skill) and (friend:getKnownKingdom()) == "touhou" then
				return friend
			end
		end

		self:sortInPlace(self.friends_noself, "chaofeng")
		for _, friend in ipairs(self.friends_noself) do
			if not known(hasManjuanEffect(friend),"hasManjuanEffect") and (friend:getKnownKingdom()) == "touhou" then
				return friend
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.se_fuzhi = -80


sgs.ai_skill_discard["se_fuzhi"] = function(self, discard_num, min_num, optional, include_equip)
	local handcards = sgs.QList2Table((self.player:getCards("h")))
	handcards=(self:sortByUseValue(handcards,true))
	local x = (self.player:getHandcardNum()) - (self.player:getHp())
	local cards = {}
	for _, c in ipairs(handcards) do
		if #cards < x then
			table.insert(cards, (c:getKnownEffectiveId()))
		end
	end
	if #cards > 0 then
		return cards
	end
	return {}
end
