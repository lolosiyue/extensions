-- Fixed emjr-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("emjr policy input is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("emjr policy helper unavailable",method) end
    local result=table.pack(object[method](object,...))
    if AIUnsupported.is(result[1]) then error(result[1],0) end
    return table.unpack(result,1,result.n)
end
local function q(object,method,...) return known(call(object,method,...),method) end
local function sorted(self,cards,method,...)
    local result=q(self,method,cards,...)
    for i,c in ipairs(result) do cards[i]=c end
    return cards
end
local function sort_players(self,cards,...) return sorted(self,cards,"sort",...) end
local function sort_use(self,cards,...) return sorted(self,cards,"sortByUseValue",...) end
local function sort_keep(self,cards,...) return sorted(self,cards,"sortByKeepValue",...) end
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return q(self,"legacySkillSeed",skill,class,action_request(self,request)) end
local function bind(self,skill,class,costs,request) return q(self,"bindSkillCard",skill,costs,action_request(self,request),nil,class) end
local function response(self,skill,class,costs,targets)
    local use=AIUsePlan.new();use.card=bind(self,skill,class,costs,nil);use.to=AIList.new(targets)
    return use:toAnswer()
end
local function etushou_flag(self,player,name)
    local value=call(player,"hasFlag",name)
    if value~=nil then return value end
    -- Flags are projected for every player; nil means the snapshot lacks them.
    return known(nil,"emjr."..name)
end
local efusha_skill = {}
efusha_skill.name = "efusha"
table.insert(package_skills, efusha_skill)
efusha_skill.getTurnUseCard = function(self,inclusive,request)
	if q(self.player,"isKongcheng") then return nil end
	if q(self.player,"hasUsed","#efusha") then return nil end
	return seed(self,"efusha","#efusha",request)
end

sgs.ai_skill_use_func["#efusha"] = function(card,use,self,request)
	local cards = AIList.new(q(self.player,"getHandcards"))
	sort_use(self,cards, true)

	sort_players(self,self.enemies, "hp")

	--if q(self,"getOverflow") <= 0 then return end
	q(self,"setPriorityValue","#efusha",0.2,"emjr.efusha")


	local suits = {}
	local suits_num = 0
	for _, c in ipairs(cards) do
		if not suits[q(c,"getSuitString")] then
			suits[q(c,"getSuitString")] = true
			suits_num = suits_num + 1
		end
	end
	local slash = q(self,"getEvaluationCard","slash")
	for _, enemy in ipairs(self.enemies) do
		if q(self,"canAttack",enemy) and not q(enemy,"hasSkills","qingnang|jijiu|tianxiang") then
			for _, card in ipairs(cards) do
				if q(self,"getUseValue",card) < 6 and not (q(card,"isKindOf","Peach") or q(card,"isKindOf","Analeptic")) and q(self.player,"canSlash",enemy) and not q(self,"slashProhibit",slash, enemy) and q(self,"getDefenseSlash",enemy) <= 2
					and q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash) then
					use.card = bind(self,"efusha","#efusha",{q(card,"getEffectiveId")},request)
					if use.to then call(use.to,"append",enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_card_intention["#efusha"] = 70




sgs.ai_skill_invoke.eweicheng = function(self, data)
	local target = call(data,"toPlayer")
	
	return q(self,"doDisCard",target,"he", false)
end

-- Audited eweicheng -> snatch alias is registered by event-intention.

sgs.ai_choicemade_filter.skillInvoke.eweicheng = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,50) end
	end
end

sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .."|eqiehu"

sgs.ai_skill_cardask["@eqiehu1"] = function(self, data, pattern, target)
	local current = call(self.room,"getCurrent")
	local usable_cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,usable_cards)
	if current and q(self,"isFriend",current) then
		for _, c in ipairs(usable_cards) do
			if q(c,"isKindOf","BasicCard") then
				return c
			end
		end
	end
	return "."
end


sgs.ai_skill_cardask["@eqiehu2"] = function(self, data, pattern, target)
	local current = call(self.room,"getCurrent")
	local usable_cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,usable_cards)
	if current and q(self,"isEnemy",current) and q(self,"doDisCard",current, "he") then
		if q(self.player,"hasArmorEffect","silver_lion") and q(self.player,"isWounded") then
			for _, c in ipairs(usable_cards) do
				if q(c,"isKindOf","SilverLion") then
					return c
				end
			end
		end
		if q(self.player,"hasSkills",sgs.lose_equip_skill) and #q(self.player,"getEquips") > 0 then
			local equipments = AIList.new(q(self.player,"getCards","e"))
			sort_keep(self,equipments)
			for _, e in ipairs(equipments) do
				return e
			end
		end
		for _, c in ipairs(usable_cards) do
			if not q(c,"isKindOf","BasicCard") then
				return c
			end
		end
	end
	return "."
end


sgs.ai_choicemade_filter.cardResponded["@eqiehu2"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = call(self.room,"getCurrent")
		if not current then return end
		call(self,"updateIntention",player, current, 80)
	end
end
sgs.ai_choicemade_filter.cardResponded["@eqiehu1"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = call(self.room,"getCurrent")
		if not current then return end
		call(self,"updateIntention",player, current, -80)
	end
end

function sgs.ai_cardneed.eqiehu(to, card)
	return q(to,"getHandcardNum") <= 2
end

sgs.ai_skill_invoke.ehuwu = function(self, data)
	local use = q(data,"toCardUse")
	if q(self,"isFriend",use.from) then
		return true
	end
	return q(self.room,"getCardPlace",q(use.card,"getEffectiveId")) == sgs.Player_DiscardPile
end


sgs.ai_skill_choice.ehuwu = function(self, choices, data)
	local use = q(data,"toCardUse")
	local obtain = getChoice(choices, "ehuwu1")
	local draw = getChoice(choices, "ehuwu2")
	if not use.card and q(self,"isFriend",use.from) then return draw end
	if not q(self,"isFriend",use.from) then return obtain end
	if q(use.card,"isKindOf","Slash") and not q(self,"hasCrossbowEffect",use.from) and getCardsNum("Slash", use.from, self.player) == 0 then
		return draw
	end
	if q(self,"isWeak",use.from) and (getCardsNum("Slash", use.from, self.player) or not q(use.card,"isKindOf","Slash") or q(use.from,"getHandcardNum") <= q(use.from,"getHp")) then
		return draw
	end
	if q(self,"willSkipPlayPhase",self.player) or q(self,"getOverflow") > 0 or q(self,"getOverflow",use.from) == 0 then
		return
			obtain
	end
	local items = q(choices,"split","+")
	if obtain then return obtain end
	return items[1]
end

sgs.ai_skill_invoke.echinei = function(self, data)
	return #self.friends_noself > 0
end


sgs.ai_skill_playerchosen.echinei = function(self, targets)
	return call(self,"findPlayerToDraw",false, q(self.player,"getLostHp") + 1)
end

sgs.ai_playerchosen_intention.echinei = -50


sgs.ai_skill_use["@@erangwai"] = function(self, prompt, method)
	local use_card = q(self,"evaluateSkillCard","erangwai","slash",{})
	local card
	local hcards = q(self.player,"getCards","h")
	hcards = AIList.new(hcards)
	sort_use(self,hcards, true)
	for _, c in ipairs(hcards) do
		if q(c,"isKindOf","BasicCard") and not q(c,"isKindOf","Peach") then
			card = c
			break
		end
	end
	local current = call(self.room,"getCurrent")

	if card and current and #self.enemies > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not q(self,"slashProhibit",nil, enemy) and q(self,"getDefenseSlash",enemy) <= 2 and q(self,"isGoodTarget",enemy, self.enemies, use_card) and q(current,"inMyAttackRange",enemy) then
				return response(self,"erangwai","#erangwaiCard",{q(card,"getEffectiveId")},{enemy})
			end
		end
	end
	return "."
end




local eyanshou_skill = {}
eyanshou_skill.name = "eyanshou"
table.insert(package_skills, eyanshou_skill)
eyanshou_skill.getTurnUseCard = function(self,inclusive,request)
	if q(self.player,"hasUsed","#eyanshouCard") then return nil end
	return seed(self,"eyanshou","#eyanshouCard",request)
end

sgs.ai_skill_use_func["#eyanshouCard"] = function(card,use,self,request)
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"hasEquip") and q(self,"doDisCard",enemy, "e") and q(self,"willSkipPlayPhase",enemy) then
			use.card = bind(self,"eyanshou","#eyanshouCard",{},request)
			if use.to then call(use.to,"append",enemy) end
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"hasEquip") and q(self,"doDisCard",enemy, "e") then
			use.card = bind(self,"eyanshou","#eyanshouCard",{},request)
			if use.to then call(use.to,"append",enemy) end
			return
		end
	end
	for _, friend in ipairs(self.friends) do
		if q(friend,"hasEquip") and q(self,"doDisCard",friend, "e") then
			use.card = bind(self,"eyanshou","#eyanshouCard",{},request)
			if use.to then call(use.to,"append",friend) end
			return
		end
	end
end

ai_audited_aliases.register{id="ai_cardneed.ejisi",registry="ai_cardneed",path={"ejisi"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
sgs.ai_cardsview_valuable.ejisi = function(self, class_name, player)
	local usereason = known(self.request and self.request.reason,"request.reason")
	if usereason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	local current = call(self.room,"getCurrent")
	local handcards = AIList.new(q(self.player,"getCards","h"))
	local had_card = nil
	for _, c in ipairs(handcards) do
		if q(c,"isKindOf","Nullification") then
			had_card = c
		end
	end

	local pattern = nil
	if class_name == "Nullification" and not q(player,"hasFlag","ejisiUsed") and had_card == nil and current and q(player,"canPindian",current, false) and not q(self,"isFriend",current) then
		pattern = "nullification"
	end
	if pattern then
		return {skill="ejisi",legacy_class="#ejisiCard",subcards={}}
	end
end

sgs.ai_skill_invoke.eqiangbian = function(self, data)
	local target = call(data,"toPlayer")
	if target and q(self,"isFriend",target) then return false end
	return true
end

sgs.ai_skill_invoke.eaocai = function(self, data)
	return q(self.player,"getHandcardNum") < 3 or q(self,"isWeak")
end


sgs.ai_skill_invoke.ezhuanquan = function(self, data)
	local target = call(self.room,"getCurrent")
	if q(self,"isEnemy",target) then
		if q(self,"doDisCard",target, "h") then
			return false
		end
	end
	if q(self,"isFriend",target) then
		return q(self,"doDisCard",target, "h")
	end
	return not q(self,"isFriend",target)
end

-- Audited ezhuanquan -> snatch alias is registered by event-intention.


sgs.ai_skill_invoke.etushou = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.etushou = function(self, targets)
	local targetlist = AIList.new(targets)
	local target
	sort_players(self,targetlist, "hp")
	for _, player in ipairs(targetlist) do
		if q(self,"isFriend",player) and q(self,"canDraw",player, self.player) then
			target = player
			break
		end
	end
	if target then return target end
	for _, player in ipairs(targetlist) do
		if q(self,"isFriend",player) then
			target = player
			break
		end
	end
	if target then return target end
	return targetlist[1]
end

sgs.ai_skill_choice.etushou = function(self, choices, data)
	local items = q(choices,"split","+")

	if table.contains(items, "etushou2") and q(self,"isWeak") then return "etushou2" end
	if table.contains(items, "etushou1") and q(self.player,"getMaxHp") - q(self.player,"getHandcardNum") > 2 then
		local maxHp = 0
		for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if q(p,"getHp") > maxHp then
				maxHp = q(p,"getHp")
			end
		end
		for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if q(p,"getHp") == maxHp and not q(self,"isEnemy",p) then
				return "etushou1"
			end
		end
	end
	return "cancel"
end

sgs.ai_ajustdamage_to.etushou = function(self, from, to, card, nature)
	if etushou_flag(self,to,"etushou2") then
		return -99
	end
end

sgs.ai_ajustdamage_from.etushou = function(self, from, to, card, nature)
	if etushou_flag(self,from,"etushou") then
		return -99
	end
end

local etiaobo_skill = {
	name = "etiaobo",
	getTurnUseCard = function(self,inclusive,request)
		if q(self.player,"hasUsed","#etiaoboCard") then return end
		if q(self.player,"isNude") then return end
		local can_use = false
		sort_players(self,self.enemies, "chaofeng")
		local slash = q(self,"getEvaluationCard","slash")
			for _, enemy in ipairs(self.enemies) do
			if q(self,"slashIsEffective",slash, enemy) and not q(enemy,"isKongcheng") then
                can_use = true
                break
            end
		end
		if can_use then
			return seed(self,"etiaobo","#etiaoboCard",request)
		end
	end,
}
table.insert(package_skills, etiaobo_skill) --加入AI可用技能表
sgs.ai_skill_use_func["#etiaoboCard"] = function(card,use,self,request)
	local slash = q(self,"getEvaluationCard","slash")
	local slasher, target
	sort_players(self,self.enemies, "defense")
	for _, enemy_a in ipairs(self.enemies) do
		for _, enemy_b in ipairs(self.enemies) do
			if q(enemy_b,"canSlash",enemy_a) and not q(self,"slashProhibit",slash, enemy_a) and q(self,"getDefenseSlash",enemy_a) <= 2
				and q(self,"slashIsEffective",slash, enemy_a) and q(self,"isGoodTarget",enemy_a, self.enemies, slash) and q(enemy_b,"getHandcardNum") < q(enemy_a,"getHandcardNum") and not q(enemy_a,"isKongcheng") and not q(enemy_b,"isKongcheng") and q(enemy_a,"objectName") ~= q(self.player,"objectName") then
				slasher = enemy_b
				target = enemy_a
				break
			end
		end
	end
	if not slasher then
		for _, enemy in ipairs(self.enemies) do
			for _, p in ipairs(AIList.new(q(self.room,"getOtherPlayers",enemy))) do
				if q(p,"canSlash",enemy) and not q(self,"slashProhibit",slash, enemy) and q(self,"getDefenseSlash",enemy) <= 2
					and q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash) and q(p,"getHandcardNum") < q(enemy,"getHandcardNum") and q(enemy,"objectName") ~= q(self.player,"objectName") and not q(p,"isKongcheng") and not q(enemy,"isKongcheng") then
					slasher = p
					target = enemy
					break
				end
			end
		end
	end

	if slasher and target then
		local card_str = "#etiaoboCard:.:"
		local acard = bind(self,"etiaobo","#etiaoboCard",{},request)
		use.card = acard
		if use.to then
			call(use.to,"append",slasher)
			call(use.to,"append",target)
		end
	end
end

sgs.ai_use_priority["#etiaoboCard"] = 0
sgs.ai_use_value["#etiaoboCard"] = 0
sgs.ai_card_intention["#etiaoboCard"] = 80

for _,skill in ipairs(package_skills) do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end

-- 曹操傳 E鳴驚人技能的 Isolated AI；只使用 viewer 可見的 mark 與純值 view。
local function value(player, method, ...)
    if not player or type(player[method]) ~= "function" then return nil end
    return player[method](player, ...)
end

local function side(player)
    return value(player, "getStrategyMark", "emjr_cc_side")
        or value(player, "getMark", "emjr_cc_side") or 0
end

local function is_friend(self, player)
    local own_side, target_side = side(self.player), side(player)
    if own_side > 0 and target_side > 0 then return own_side == target_side end
    return player and self:isFriend(player) or false
end

local function is_enemy(self, player)
    local own_side, target_side = side(self.player), side(player)
    if own_side > 0 and target_side > 0 then return own_side ~= target_side end
    return player and self:isEnemy(player) or false
end

local function choose_enemy(self, candidates)
    for _, target in ipairs(candidates or {}) do
        if is_enemy(self, target) then return target end
    end
    return nil
end

-- 技能候選由 Room 提供；關係使用曹操傳全局隊伍 mark，避免身份局內奸推測。
for _, skill in ipairs({ "emjr_cc_fanji", "emjr_cc_chuanji", "emjr_cc_huiqiang" }) do
    if skill == "emjr_cc_fanji" then
        sgs.ai_skill_invoke[skill] = function(self, data)
            local attacker = data and type(data.toPlayer) == "function" and data:toPlayer() or nil
            return attacker and is_enemy(self, attacker) or false
        end
    elseif skill == "emjr_cc_huiqiang" then
        sgs.ai_skill_invoke[skill] = function(self, data)
            local target = data and type(data.toPlayer) == "function" and data:toPlayer() or nil
            return target and is_enemy(self, target) or false
        end
    else
        -- TriggerSkill 已確認有合法相鄰敵軍候選；穿擊不消耗資源，可直接發動。
        sgs.ai_skill_invoke[skill] = function(self)
            return true
        end
        sgs.ai_skill_playerchosen[skill] = choose_enemy
    end
end

local function spirit(player)
    return value(player, "getStrategyMark", "@emjr_cc_spirit")
        or value(player, "getMark", "@emjr_cc_spirit") or 0
end

local function beast(player)
    return (value(player, "getStrategyMark", "emjr_cc_beast")
        or value(player, "getMark", "emjr_cc_beast") or 0) == 1
end

local function can_spend(player)
    return beast(player) or spirit(player) > 0
end

local function treasure(player)
    return value(player, "getStrategyMark", "emjr_cc_treasure")
        or value(player, "getMark", "emjr_cc_treasure") or 0
end

-- 青龍雷擊／朱雀天火只在敵人受傷且尚有靈氣時消耗觸發資源。
sgs.ai_skill_invoke["emjr_cc_jinglei"] = function(self, data)
    local damaged = data and type(data.toPlayer) == "function" and data:toPlayer() or nil
    local access = beast(self.player) or treasure(self.player) == 1
    if not access or not can_spend(self.player) then return false end
    for _, enemy in ipairs(self.enemies or {}) do
        if is_enemy(self, enemy) and (not damaged or enemy:objectName() ~= damaged:objectName()) then return true end
    end
    return false
end
sgs.ai_skill_invoke["emjr_cc_tianhuo"] = function(self, data)
    local damaged = data and type(data.toPlayer) == "function" and data:toPlayer() or nil
    local access = beast(self.player) or treasure(self.player) == 3
    if not access or not can_spend(self.player) then return false end
    for _, enemy in ipairs(self.enemies or {}) do
        if is_enemy(self, enemy) and (not damaged or enemy:objectName() ~= damaged:objectName()) then return true end
    end
    return false
end

local function use_skill(self, skill, card_class, card_kind, useful, request)
    if not useful(self) then return nil end
    local cards = self.player:getCards("he")
    if cards == nil then return nil end
    cards = sgs.QList2Table(cards)
    cards = self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if card:isKindOf(card_kind) and value(self.player, "isJilei", card) == false then
            local cost = card:getEffectiveId()
            if type(cost) == "number" then
                local receipt = self:bindSkillCard(skill, { cost }, request, nil, card_class)
                if receipt then
                    local use = AIUsePlan.new()
                    use.card = receipt
                    return use:toAnswer()
                end
            end
        end
    end
    return nil
end

-- 地佑值得用於至少一名受傷友軍；混沌對至少一名敵軍可施加狀態時使用。
ai_skill_activate["emjr_cc_diyou"] = function(self, request)
    local available = (beast(self.player) or treasure(self.player) == 2) and can_spend(self.player)
    if not available then return nil end
    local injured = value(self.player, "isWounded") == true
    for _, friend in ipairs(self.friends or {}) do
        if is_friend(self, friend) and value(friend, "isWounded") == true then injured = true break end
    end
    if not injured then return nil end
    return use_skill(self, "emjr_cc_diyou", "#emjr_cc_diyouCard", "BasicCard",
        function() return true end, request)
end

ai_skill_activate["emjr_cc_hundun"] = function(self, request)
    local available = (beast(self.player) or treasure(self.player) == 4) and can_spend(self.player)
    if not available then return nil end
    local has_enemy = false
    for _, enemy in ipairs(self.enemies or {}) do
        if is_enemy(self, enemy) then
            for _, mark in ipairs({ "@emjr_cc_state_poison", "@emjr_cc_state_curse",
                "@emjr_cc_state_paralysis", "@emjr_cc_state_chain", "@emjr_cc_state_flip" }) do
                if (value(enemy, "getStrategyMark", mark) or value(enemy, "getMark", mark) or 0) == 0 then
                    has_enemy = true
                    break
                end
            end
        end
        if has_enemy then break end
    end
    if not has_enemy then return nil end
    return use_skill(self, "emjr_cc_hundun", "#emjr_cc_hundunCard", "TrickCard",
        function() return true end, request)
end
