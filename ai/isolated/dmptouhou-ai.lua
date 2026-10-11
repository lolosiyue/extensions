-- Fixed b6025acc dmptouhou effective policies; no repair of absent old prototypes.
local function known(v,k)
    if AIUnsupported.is(v) then error(v,0) end
    if v==nil then ai_unsupported("dmptouhou fact is unknown",k) end
    return v
end
local function call(o,k,...)
    if not o or type(o[k])~="function" then ai_unsupported("dmptouhou helper unavailable",k) end
    local v=o[k](o,...);if AIUnsupported.is(v) then error(v,0) end;return v
end
local function q(o,k,...) return known(call(o,k,...),k) end
local function facts(self) return known(self.world.strategy_facts and self.world.strategy_facts.dmptouhou,"dmptouhou") end
local function parse_nil(self,selector)
    local rows=facts(self).legacy_prototypes
    if type(rows)~="table" or rows[selector]~=false then ai_unsupported("dmptouhou source prototype absence is not proven",selector) end
    return nil
end
local function sort_in_place(self,values,key)
    local sorted=q(self,"sort",values,key)
    for i,value in ipairs(sorted)do values[i]=value end
end
local function skills(self,player,names)
    local value=q(player,"hasSkills",names)
    local row=rawget(player,"_view")
    if value or not row or row.skills_complete==true then return value end
    ai_unsupported("dmptouhou skill absence is not visible",names)
end
local function kuixin_used(self,player)
    local row=facts(self).kuixin_used
    local value=type(row)=="table" and row[q(player,"objectName")]
    if type(value)~="boolean" then ai_unsupported("public se_kuixin_used flag is not projected","se_kuixin_used") end
    return value
end
local function wounded(self)
    local a,b=self:getWoundedFriend(false,true)
    return known(a,"wounded first list"),b -- source returns before reading list2 when target is self
end
local function source_fangquan(self)
    local callback=sgs.ai_skill_invoke.fangquan
    if type(callback)~="function"then ai_unsupported("effective fangquan callback is unavailable","se_fuzhi")end
    local value=callback(self);if AIUnsupported.is(value)then error(value,0)end;return value
end
-- The shared immutable identity gate owns cardChosen.se_mingqie -> snatch.
sgs.ai_skill_invoke.se_mingqie = function(self, data)
	local use = q(data,"toCardUse")
	if q(self,"isEnemy",use.to:at(0)) and not skills(self,use.to:at(0),sgs.lose_equip_skill) then return true end
	if q(self,"isFriend",use.to:at(0)) and skills(self,use.to:at(0),sgs.lose_equip_skill) then return true end
	return false
end

sgs.ai_cardneed.se_mingqie = function(to, card, self)
	return q(card,"isKindOf","Dismantlement") or q(card,"isKindOf","Snatch")
end




sgs.ai_fill_skill.se_mopao = function(self, inclusive)
	if q(self.player,"hasUsed","#se_mopaocard") then return end
	if #self.enemies < 1 then return end
	if q(self.player,"getMark","@p_point") < 4 then return end
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			if q(enemy,"getEquips"):length() < 2 and not q(self,"cantDamageMore",self.player, enemy) then
				return parse_nil(self,"#se_mopaocard")
			end
		end
	end
	return
end

sgs.ai_skill_use_func["#se_mopaocard"] = function(card, use, self)
	local target
	call(self,"updatePlayers")
	sort_in_place(self,self.enemies,"hp")
	for _, enemy in ipairs(self.enemies) do
		if q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) and not q(self,"cantDamageMore",self.player, enemy) then
			target = enemy
			break
		end
	end
	if not target then return end

	local next_man = q(self.player,"getNextAlive")
	local friend_enemy = 0
	while (q(next_man,"objectName") ~= q(target,"objectName")) do
		if q(self,"isFriend",next_man) and q(self,"damageIsEffective",next_man, sgs.DamageStruct_Normal) then
			friend_enemy = friend_enemy + 1
		elseif q(self,"isEnemy",next_man) and q(self,"damageIsEffective",next_man, sgs.DamageStruct_Normal) then
			friend_enemy = friend_enemy - 1
		end
		next_man = q(next_man,"getNextAlive")
	end
	if friend_enemy < 0 then
		call(self,"setStrategyMemory","dmptouhou.mopao_direction","right")
	else
		call(self,"setStrategyMemory","dmptouhou.mopao_direction","left")
	end
	if target then
		use.card = parse_nil(self,"#se_mopaocard")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_choice["se_mopaocard"] = function(self, choices)
	local value,present=self:getStrategyMemory("dmptouhou.mopao_direction")
    if not present or(value~="left"and value~="right")then ai_unsupported("source global direction has no viewer-local observation","se_mopaocard")end
    return value
end



sgs.ai_use_value["se_mopaocard"]      = 8
sgs.ai_use_priority["se_mopaocard"]   = 2
sgs.ai_card_intention["se_mopaocard"] = 100



sgs.ai_skill_playerchosen.se_wuyi_losehp = function(self, targets)
	local targets = sgs.QList2Table(targets)
	targets=q(self,"sort",targets,"hp")
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and not q(self,"hasZhaxiangEffect",p) then
			return p
		end
	end
	return targets[1]
end


sgs.ai_playerchosen_intention.se_wuyi_losehp = 40

sgs.ai_skill_playerchosen.se_wuyi_draw = function(self, targets)
	local n = q(self.player,"getMark","se_wuyi-draw")
	return call(self,"findPlayerToDraw",true, n) --mostPlayer(self, true, 1)
end

sgs.ai_playerchosen_intention.se_wuyi_draw = -40

sgs.ai_skill_playerchosen.se_wuyi_recover = function(self, targets)
	local arr1, arr2 = wounded(self)
	local target = self.player

	if #arr1 > 0 and (q(self,"isWeak",arr1[1])) and q(arr1[1],"getHp") < q(self,"getBestHp",arr1[1]) then target = arr1[1] end
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
sgs.ai_fill_skill.se_kuixin = function(self, inclusive)
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if q(self.player,"distanceTo",p) == 1 and not kuixin_used(self,p) and q(p,"getHandcardNum") > 0 then
			if math.random(1, 5) > 1 then
				return parse_nil(self,"#se_kuixincard")
			end
		end
	end
	return
end
sgs.ai_skill_use_func["#se_kuixincard"] = function(card, use, self)
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if q(self.player,"distanceTo",p) == 1 and not kuixin_used(self,p) and q(p,"getHandcardNum") > 0 then
			use.card = card
			if use.to then use.to:append(p) end
			return
		end
	end
end

sgs.ai_use_value["se_kuixincard"] = 5
sgs.ai_use_priority["se_kuixincard"] = 10

sgs.ai_skill_askforag["se_huixiang"] = function(self, card_ids)
	if q(self.player,"getJudgingArea"):length() > 0 then
		local hasNull = false
		for _, card in sgs.qlist(q(self.player,"getHandcards")) do
			if q(card,"isKindOf","Nullification") then hasNull = true end
		end
		if not hasNull then
			for _, card_id in ipairs(card_ids) do
				if q(q(self,"getChoiceCard",card_id),"isKindOf","Nullification") then return card_id end
			end
		end
	end
	if q(self,"isWeak") then
		for _, card_id in ipairs(card_ids) do
			if q(q(self,"getChoiceCard",card_id),"isKindOf","Peach") then return card_id end
		end
	end
	local weakF = 0
	for _, p in ipairs(self.friends) do
		if q(self,"isWeak",p) then
			weakF = weakF + 1
		end
	end
	for _, card_id in ipairs(card_ids) do
		if q(q(self,"getChoiceCard",card_id),"isKindOf","ExNihilo") then return card_id end
	end
	if weakF > 1 then
		for _, card_id in ipairs(card_ids) do
			if q(q(self,"getChoiceCard",card_id),"isKindOf","GodSalvation") then return card_id end
		end
	end
	if #self.enemies - #self.friends > 1 then
		for _, card_id in ipairs(card_ids) do
			if q(q(self,"getChoiceCard",card_id),"isKindOf","AOE") then return card_id end
		end
	end
	return
end


ai_skill_use["@@se_huixiang"] = function(self, prompt, method)
	local cards = {}
	if q(self.player,"getPile","satori_memory"):length() < 1 then return "." end
	for _, id in sgs.qlist(q(self.player,"getPile","satori_memory")) do
		table.insert(cards, q(self,"getKnownCardById",id))
	end
	cards=q(self,"sortByUseValue",cards)
	--local card_str = string.format("#LuaMeilingCard:%d:->%s", card:getId(), q(target,"objectName"))
	local give_all_cards = {}
	local max = math.ceil(q(self.player,"getHp") / 2)
	for _, c in ipairs(cards) do
		if #give_all_cards < max then
			table.insert(give_all_cards, q(c,"getEffectiveId"))
		end
	end
	local card_str = string.format("#se_huixiang:%s:", table.concat(give_all_cards, "+"))
	--local card_str = "#se_huixiang:"..cardx:getId()..":"
	parse_nil(self,"#se_huixiang")
    local signal=AIUnsupported.new("dmptouhou donor response prototype is unavailable","@@se_huixiang")
    signal.terminal_response_selection=true;signal.donor_terminal_unavailable=true
    signal.source_wire=card_str;signal.selected_costs=give_all_cards
    error(signal,0)
end


--fuzhi




sgs.ai_skill_playerchosen.se_fuzhi = function(self, targets)
	if (source_fangquan(self)) then
		local AssistTarget = call(self,"AssistTarget")
		if AssistTarget and not q(self,"willSkipPlayPhase",AssistTarget) and not known(hasManjuanEffect(AssistTarget),"hasManjuanEffect") and q(AssistTarget,"getKingdom") == "touhou" then
			return AssistTarget
		end
		for _, friend in ipairs(self.friends_noself) do
			if not known(hasManjuanEffect(friend),"hasManjuanEffect") and skills(self,friend,sgs.cardneed_skill) and q(friend,"getKingdom") == "touhou" then
				return friend
			end
		end

		sort_in_place(self,self.friends_noself,"chaofeng")
		for _, friend in ipairs(self.friends_noself) do
			if not known(hasManjuanEffect(friend),"hasManjuanEffect") and q(friend,"getKingdom") == "touhou" then
				return friend
			end
		end
		--return self.friends_noself[1]
	end
	return nil
end

sgs.ai_playerchosen_intention.se_fuzhi = -80


sgs.ai_skill_discard["se_fuzhi"] = function(self, discard_num, min_num, optional, include_equip)
	local handcards = sgs.QList2Table(q(self.player,"getCards","h"))
	handcards=q(self,"sortByUseValue",handcards,true)
	local x = q(self.player,"getHandcardNum") - q(self.player,"getHp")
	local cards = {}
	for _, c in ipairs(handcards) do
		if #cards < x then
			table.insert(cards, q(c,"getEffectiveId"))
		end
	end
	if #cards > 0 then
		return cards
	end
	return {}
end
