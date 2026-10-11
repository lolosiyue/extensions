-- 通用決策流程的隔離版本：估值、排序、威脅評估與回合候選。
-- 全部只靠快照與 request 的候選運作，沒有 gameplay 全域，也不查 Engine。
-- 個別武將策略仍然用註冊表擴充，不寫進這裡。

-- 值型規則註冊表。鍵是牌名或類別名，值是數字或 function(self, card) 回數字。
ai_keep_value = ai_keep_value or {}
ai_use_value = ai_use_value or {}
ai_use_priority = ai_use_priority or {}

-- Printed values from standard_cards-ai.lua and maneuvering-ai.lua.  Keep the
-- original scale: priority differences are also consumed by package callbacks.
local default_keep_value = {Peach=7, Analeptic=4.1, Jink=5.2, Slash=3.6,
    FireSlash=3.63, ThunderSlash=3.66, Weapon=2.08, Armor=2.06, Horse=2.04,
    Snatch=3.46, Dismantlement=3.44, Duel=3.42, ExNihilo=3.9,
    AmazingGrace=-1, GodSalvation=3.32, Indulgence=3.5, SupplyShortage=3.48,
    Lightning=-1, Collateral=3.4, IronChain=3.34, FireAttack=3.3,
    ArcheryAttack=3.38, SavageAssault=3.36, Nullification=3.8}
local default_use_value = {Peach=6, Analeptic=5.98, Slash=4.5, Jink=8.9,
    FireSlash=4.6, ThunderSlash=4.55, Snatch=9, Dismantlement=5.6, Duel=3.7,
    ExNihilo=9, AmazingGrace=3, Indulgence=8, SupplyShortage=7,
    Collateral=5.8, IronChain=5.4, FireAttack=4.8, ArcheryAttack=3.8,
    SavageAssault=3.9, Nullification=8}
local default_use_priority = {Peach=0.9, Analeptic=3, Slash=2.6,
    FireSlash=2.7, ThunderSlash=2.7, Dismantlement=9.4, Snatch=9.3, Duel=2.9,
    ExNihilo=9.3, AmazingGrace=1.2, GodSalvation=4.1, Indulgence=0.5,
    SupplyShortage=0.5, Lightning=0, Collateral=2.75, IronChain=9.1,
    FireAttack=9.5, ArcheryAttack=3.5, SavageAssault=3.5,
    OffensiveHorse=2.69, DefensiveHorse=2.75, Axe=2.688, Halberd=2.685,
    KylinBow=2.68, Blade=2.675, GudingBlade=2.67, DoubleSword=2.665,
    spear=2.66, IceSword=2.65, QinggangSword=2.645, Crossbow=2.63,
    SilverLion=1, EightDiagram=0.8, RenwangShield=0.85, Fan=2.655, Vine=0.95}

local function finite_number(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function skill_hooks(self, name, player)
    if type(self.forSkillHooks) ~= "function" then
        ai_unsupported("strategy-hooks.lua must load before decision-core helpers", name)
    end
    return self:forSkillHooks(name, player)
end

local function value_call(object, method, ...)
    if not object then return nil end
    if method == "getMark" then
        local strategy_mark = object.getStrategyMark
        if type(strategy_mark) == "function" then return strategy_mark(object, ...) end
    end
    if method == "hasFlag" then
        local strategy_flag = object.getStrategyFlag
        if type(strategy_flag) == "function" then return strategy_flag(object, ...) end
    end
    local getter = object[method]
    if type(getter) ~= "function" then return nil end
    local result = getter(object, ...)
    if AIUnsupported.is(result) then error(result,0) end
    if result == nil and method == "hasSkills" then
        local names, players = ...
        if AIValue.isList(players) and not (type(AIValue.isPlayer)=="function" and AIValue.isPlayer(players)) then
            -- Legacy collection overload returns nil for known absence. Check
            -- every facade so an unknown skill projection is not folded away.
            for _, player in ipairs(players) do
                local known = player:hasSkills(names)
                if known == nil then return nil end
                if known then return player end
            end
            return false
        end
    end
    return result
end

local function value_known(value, label)
    if AIUnsupported.is(value) then error(value,0) end
    if value == nil then ai_unsupported("card valuation requires " .. label, "valuation") end
    return value
end

local function core_query(object, method, ...)
    local provider=object and object[method]
    local result=value_call(object,method,...)
    if AIUnsupported.is(result) then error(result,0) end
    if result==nil and type(SmartAIView.isKnownNilStrategyResult)=="function"
        and SmartAIView.isKnownNilStrategyResult(object,method,provider) then return nil end
    return value_known(result,method)
end

local function is_strategy_seed(card)
    return type(card)=="table" and type(card.isStrategySeed)=="function" and card:isStrategySeed()==true
end

-- Only facade-owned, request-bound turn hypotheses may enter the ordinary
-- proposal pipeline. They remain evaluation cards until activate selects one.
local function readonly_turn_conversion(self, card)
    return type(self.isReadonlyTurnConversion) == "function"
        and self:isReadonlyTurnConversion(card) == true
end

local function card_key(card)
    -- Facades are recreated freely. Use the authorized instance identity, never
    -- a facade address or a cross-request cache of a native card.
    if type(card.getAuthorityCard) == "function" then card = card:getAuthorityCard() or card end
    local id = card:getEffectiveId()
    return tostring(id) .. ":" .. tostring(value_call(card, "getConversionId") or "")
end

-- Native Lua equality compares CardLifetimeToken identity. Printed strings,
-- effective IDs and payment tickets describe different equivalence relations.
-- These opaque identities belong to the strategy object, not its authority.
function SmartAIView:sameLegacyCard(left, right)
    if rawequal(left, right) then return true end
    if left == nil or right == nil then return false end
    local first = value_call(left, "getLegacyIdentityToken")
    local second = value_call(right, "getLegacyIdentityToken")
    if type(first) ~= "string" or first == "" or type(second) ~= "string" or second == "" then
        ai_unsupported("native strategy card equality identity is unknown", "card_identity")
    end
    return first == second
end

-- Value identity follows the donor's serialized card, independently of the
-- capability used to submit it. ActiveSkillCard instances only disambiguate
-- aiCardKey (priority/use/need); keepValue deliberately uses plain toString.
local function legacy_string_key(card)
    local key = value_call(card, "getLegacyStringKey")
    if type(key) ~= "string" or key == "" then
        ai_unsupported("card valuation requires exact legacy string key", "valuation")
    end
    return key
end

local function legacy_sort_key(card)
    local key = value_call(card, "getLegacySortKey")
    if type(key) ~= "string" or key == "" then
        ai_unsupported("card sorting requires exact legacy sort key", "valuation")
    end
    return key
end

local function authority_candidate(self, card)
    if is_strategy_seed(card) then return nil end
    if type(card.getAuthorityCard) == "function" then card = card:getAuthorityCard() or card end
    return self:getCardCandidate(card:getEffectiveId())
end

local function strategy_candidate(self, card)
    if is_strategy_seed(card) then return nil end
    -- A legacy policy may describe a different card family from its native
    -- skill-action receipt. Only an explicitly attached read-only projection
    -- can supply that policy's planning rules; it never replaces authority.
    if type(card.getPolicyEvaluationCard) == "function" and card:getPolicyEvaluationCard() ~= nil then
        return value_known(value_call(self,"getEvaluationCandidate",card),"policy evaluation candidate")
    end
    if type(card.getAuthorityCard) == "function" then card = card:getAuthorityCard() or card end
    -- A reached RushB setter changes the same physical object. A lexical
    -- parent scope may retain an older candidate; only this private issued
    -- mutation family bypasses that captured candidate for current rules.
    local current=SmartAIView.getPhysicalMutationCandidate and SmartAIView.getPhysicalMutationCandidate(self,card)
    if current then return current end
    local scope = self._evaluation_scope
    if scope and scope.card == card then return scope.candidate end
    if type(card.isEvaluationOnly) == "function" and card:isEvaluationOnly() == true then
        return value_call(self, "getEvaluationCandidate", card)
    end
    return self:getCardCandidate(card:getEffectiveId())
end

local function printed_value(registry, defaults, self, card, key)
    key = key or card:getClassName()
    local rule = registry[key]
    if rule == nil then rule = defaults[key] end
    if type(rule) == "function" then rule = rule(self, card) end
    if rule == nil then return 0 end
    if not finite_number(rule) then ai_unsupported("invalid card value", key) end
    return rule
end

local function number_string(card)
    local n = value_known(value_call(card, "getNumber"), "card number")
    return ({[1]="A", [11]="J", [12]="Q", [13]="K"})[n] or tostring(n)
end

local function card_type(card)
    if card:isKindOf("SkillCard") then return "skill", 0 end
    if card:isKindOf("BasicCard") then return "basic", 1 end
    if card:isKindOf("TrickCard") then return "trick", 2 end
    if card:isKindOf("EquipCard") then return "equip", 3 end
    local id = value_call(card, "getTypeId")
    if id ~= nil then return value_call(card, "getType"), id end
    ai_unsupported("card type is unknown", "valuation")
end

local function own_equipped(self, card, owner)
    local equips = value_known((owner or self.player):getEquips(), "equipment collection")
    for _, equip in ipairs(equips) do
        if equip:getEffectiveId() == card:getEffectiveId() then return true end
    end
    return false
end

function SmartAIView:getSameEquip(card,player)
    if not card or not core_query(card,"isKindOf","EquipCard") then return end
    player=player or self.player
    local function at(slot)
        -- getEquip's nil is known empty only when its native slot projection
        -- exists. Resolve the returned ID to the same disclosed inner equip.
        local row=rawget(player,"_view")
        if row and type(row.equip_slots)~="table" then ai_unsupported("equipment slot projection is unavailable","getSameEquip") end
        local equip=player:getEquip(slot)
        if equip==nil or AIValue.isCard(equip) then return equip end
        for _,candidate in ipairs(value_known(player:getEquips(),"equipment collection"))do
            if candidate:getEffectiveId()==equip then return candidate end
        end
        ai_unsupported("equipped card metadata is unavailable","getSameEquip")
    end
    local locations=core_query(card,"getEquipOccupyLocations")
    for _,slot in sgs.qlist(locations)do
        local equip=at(slot)
        if equip then return equip end
    end
    return at(core_query(card,"getEquipSlot"))
end

local function priority_skills(self, owner)
    return value_known(owner:getSkills(), "visible skills")
end

-- Fixed load-time suit metadata is already audited in the shared catalogue.
-- Registered values retain precedence; absence alone consults that finite table.
local function source_suit_value(self, skill)
    local value = sgs[skill .. "_suit_value"]
    if value == nil then value = self:getSourceSuitValueTable(skill) end
    return value
end

function SmartAIView:getKeepValue(card,kept)
    self.keepValue = self.keepValue or {}
    self.keepdata = self.keepdata or {}
	if kept==nil then
		return self.keepValue[legacy_string_key(card)] or self.keepdata[core_query(card,"getClassName")] or ai_keep_value[core_query(card,"getClassName")] or 0
	end
	local id = core_query(card,"getEffectiveId")
	local class = core_query(card,"getClassName")
	local owner = self.room:getCardOwner(id) or self.player
	local x = self.keepdata[class] or ai_keep_value[class] or 0
	if type(kept)=="table" then
		x = self.keepValue[legacy_string_key(card)] or x
		if kept.count then
			local owner_count = kept.count[core_query(owner,"objectName")] or {}
			local dup = core_query(card,"isKindOf","Slash") and (owner_count.Slash or 0) or (owner_count[class] or 0)
			x = x-1.1*dup
		else
			for _,kc in ipairs(kept)do
				if core_query(card,"isKindOf","Slash") and isCard("Slash",kc,owner)
				or isCard(class,kc,owner) then x = x-1.1 end
			end
		end
		return x
	end
	for k,v in pairs(self.keepdata)do
		if v>x and isCard(k,card,owner)
		then x = v end
	end
	if core_query(self.room,"getCardPlace",id)==sgs.Player_PlaceEquip then
		if core_query(self,"loseEquipEffect",owner) or #core_query(self,"poisonCards",{card},owner)>0 then
			if core_query(card,"isKindOf","OffensiveHorse") then x = x-9
			elseif core_query(card,"isKindOf","Weapon") then x = x-8
			else x = x-7 end
		elseif core_query(self,"needKongcheng") then x = x+5 end
		if core_query(card,"isKindOf","Armor") then
			x = x+(core_query(self,"isWeak") and 3.2 or 2.2)
			if core_query(self,"needToThrowArmor") then x = x-7 end
		elseif core_query(card,"isKindOf","Weapon") then x = x+(core_query(owner,"getPhase")<=sgs.Player_Play and core_query(self,"slashIsAvailable",nil,false) and 1.4 or 1.2)
		elseif core_query(card,"isKindOf","WoodenOx") then x = x+(core_query(owner,"getPile","wooden_ox"):length()*2.2)
		elseif core_query(card,"isKindOf","DefensiveHorse") then x = x+(core_query(self,"isWeak") and 2.3 or 1.9)
		elseif core_query(card,"isKindOf","OffensiveHorse") then x = x+1.7
		else x = x+1.8 end
		return x+3
	end
	local owner_name = core_query(owner,"objectName")
	self._keep_skill_eval_cache = self._keep_skill_eval_cache or {}
	self._keep_skill_eval_cache[owner_name] = self._keep_skill_eval_cache[owner_name] or {}
	local card_key = table.concat({
		core_query(card,"getSuitString"),
		core_query(card,"getNumberString"),
		core_query(card,"getClassName"),
		core_query(card,"objectName"),
		core_query(card,"getColorString"),
		tostring(core_query(card,"getType"))
	},"|")
	local eval = self._keep_skill_eval_cache[owner_name][card_key]
	if not eval then
		local si,ni,ci,vs,vn,cvsum = 0,0,0,0,0,0
		for _,sk in sgs.qlist(core_query(owner,"getVisibleSkillList",true))do
			class = source_suit_value(self,sk:objectName())
			if class then
				class = class[core_query(card,"getSuitString")]
				if type(class)=="number" then
					vs = vs+class
					si = si+1
				end
			end
			class = sgs[sk:objectName().."_number_value"]
			if class then
				class = class[core_query(card,"getNumberString")]
				if type(class)=="number" then
					vn = vn+class
					ni = ni+1
				end
			end
			class = sgs.card_value[sk:objectName()]
			if class then
				local cv = class[core_query(card,"getSuitString")]
				if type(cv)=="number" then cvsum = cvsum+cv end
				cv = class[core_query(card,"getNumberString")]
				if type(cv)=="number" then cvsum = cvsum+cv end
				cv = class[core_query(card,"getClassName")]
				if type(cv)=="number" then cvsum = cvsum+cv end
				cv = class[core_query(card,"objectName")]
				if type(cv)=="number" then cvsum = cvsum+cv end
				cv = class[core_query(card,"getColorString")]
				if type(cv)=="number" then cvsum = cvsum+cv end
				cv = class[core_query(card,"getType")]
				if type(cv)=="number" then cvsum = cvsum+cv end
				ci = ci+1
			end
		end
		eval = {
			ci = ci,
			cvsum = cvsum,
			suit_add = si>0 and (vs/si) or 0,
			number_add = ni>0 and (vn/ni) or 0
		}
		self._keep_skill_eval_cache[owner_name][card_key] = eval
		self:persistKeepState()
	end
	if eval.ci>0 then x = (x+eval.cvsum)/eval.ci end
	x = x+eval.suit_add+eval.number_add

	if core_query(card,"isKindOf","Slash") then
		if core_query(card,"isKindOf","NatureSlash") then x = x+0.03 end
		if core_query(card,"isRed") then
			if core_query(owner,"hasSkill","jiang") then x = x+0.04 end
			if core_query(card,"getSuit")==sgs.Card_Heart and core_query(owner,"hasSkills","wushen|olwushen") then x = x+0.03 end
			x = x+0.02
		end
		if id>=0 and (core_query(card,"getEngineClassName")=="Analeptic")
		and core_query(owner,"hasSkills","jinjiu|mobilejinjiu") then x = x-0.02 end
	end
	class = core_query(owner,"getPileName",id)
	if class=="wooden_ox" or class:contains("&")
	then x = x-0.1 end
	class = {}
	for i,s in ipairs({"club","spade","diamond","heart","no_suit"})do
		class[s] = i
	end
	x = x+(class[core_query(card,"getSuitString")] or 6)/100
	return x+core_query(card,"getNumber")/100
end

function SmartAIView:getUseValue(card)
	--if type(card)~="userdata" then return 0 end
	local stack_overflow = false
	if core_query(self,"getUseValueRecursionFlag") then--add useless
		stack_overflow = true
		self:setUseValueRecursionFlag(false)
		return ai_use_value[core_query(card,"getClassName")]
	else
		self:setUseValueRecursionFlag(true)
	end
	local v = ai_use_value[core_query(card,"getClassName")] or 0
	if core_query(card,"isKindOf","ActiveSkillCard") then
		v = ai_use_value[core_query(card,"getSkillName")]
			or ai_use_value[core_query(card,"getSourceSkillName")] or v
	elseif core_query(card,"isKindOf","LuaSkillCard")
	then v = ai_use_value[core_query(card,"objectName")] or v
	elseif core_query(card,"isKindOf","EquipCard") then
		if core_query(self.player,"hasEquip",card) then
			if #core_query(self,"poisonCards",{card})>0 then v = 0
			elseif core_query(card,"isKindOf","OffensiveHorse")
			and core_query(self.player,"getAttackRange")>2 then v = v+2.5
			elseif core_query(card,"isKindOf","DefensiveHorse")
			and core_query(self.player,"hasArmorEffect","EightDiagram")
			then v = v+2.5 else v = v+3 end
		else
			if core_query(self,"loseEquipEffect") then v = v+10
			elseif not self:getSameEquip(card) then v = v+2.7 end
			if core_query(card,"isKindOf","Weapon")
			and self:wasPreviouslyPlannedCard(card)
			then v = v+2 end
		end
		if core_query(card,"isKindOf","EightDiagram")
		and self.role=="loyalist" and core_query(self.player,"getKingdom")=="wei"
		and self.room:getLord() and self.room:getLord():hasLordSkill("hujia")
		and not core_query(self.player,"hasSkill","bazhen") then v = v+4 end
	elseif core_query(card,"isKindOf","BasicCard") then
		if core_query(card,"isKindOf","Slash") then
			if core_query(self.player,"hasFlag","TianyiSuccess")
			or core_query(self.player,"hasFlag","JiangchiInvoke")
			then v = 8.7 end
			if core_query(self.player,"getPhase")==sgs.Player_Play
			and #self.enemies>0 and core_query(card,"isAvailable",self.player)
			and (not stack_overflow and core_query(self,"getCardsNum","Slash")==1) --add
			then v = v+5 end
			if core_query(self,"hasCrossbowEffect")
			then v = v+4 end
		elseif core_query(card,"isKindOf","Jink") then
			if not stack_overflow and core_query(self,"getCardsNum","Jink")>1 --add
			then v = v-6 end
		elseif core_query(card,"isKindOf","Peach")
		and core_query(self.player,"isWounded")
		then v = v+6 end
	elseif core_query(card,"isKindOf","TrickCard") then
		if core_query(card,"isKindOf","Duel") and not stack_overflow then v = v+core_query(self,"getCardsNum","Slash")*2 --add
		elseif core_query(card,"isKindOf","Collateral") and self.player:getWeapon()
		and not core_query(self,"loseEquipEffect") then v = 2 end
	end
	if core_query(self.player,"isLastHandCard",card)
	and core_query(self.player,"hasSkills",sgs.need_kongcheng)
	then v = v+9 end
	if core_query(self.player,"getPhase")<=sgs.Player_Play then
		self.useValue = true
		v = self:adjustUsePriority(card,v)
		self.useValue = false
	end
	self:setUseValueRecursionFlag(false)
	return v
end

function SmartAIView:adjustUsePriority(card,v)
	local suits_value,suits = false,{"club","spade","diamond","heart"}
	for _,s in ipairs(sgs.getPlayerSkillList(self.player))do
		local cb = sgs.ai_card_priority[s:objectName()]
		if type(cb)=="table" then
			cb = cb[core_query(card,"getSuitString")]
			if type(cb)=="number" then v = v+cb end
			cb = cb[core_query(card,"getNumberString")]
			if type(cb)=="number" then v = v+cb end
			cb = cb[core_query(card,"getClassName")]
			if type(cb)=="number" then v = v+cb end
			cb = cb[core_query(card,"objectName")]
			if type(cb)=="number" then v = v+cb end
			cb = cb[core_query(card,"getColorString")]
			if type(cb)=="number" then v = v+cb end
			cb = cb[core_query(card,"getSkillName")]
			if type(cb)=="number" then v = v+cb end
		elseif type(cb)=="function" then
			cb = cb(self,card,v)
			if type(cb)=="number" then v = v+cb end
		end
		if suits_value then continue end
		cb = sgs.ai_suit_priority[s]
		if type(cb)=="function" then
			suits_value = true
			suits = cb(self,card):split("|")
		elseif type(cb)=="string" then
			suits_value = true
			suits = cb:split("|")
		end
	end
	table.insert(suits,"no_suit")
	suits_value = core_query(self.player,"getPileName",core_query(card,"getEffectiveId"))
	if suits_value=="wooden_ox" or suits_value:startsWith("&") then v = v+0.2 end
	if core_query(card,"targetFixed") then
		if core_query(card,"getTypeId")<2 then
			suits_value = core_query(card,"getTargetResidue",self.player);
			if suits_value~=0 then v = v-math.min(suits_value*0.1,1) end
		end
	elseif core_query(card,"isDamageCard") then
		for _,p in ipairs(self.enemies)do
			suits_value = core_query(card,"getTargetResidue",p);
			if suits_value~=0 then v = v-math.min(suits_value*0.1,1) end
		end
	end
	if core_query(card,"isVirtualCard") then v = v-core_query(card,"subcardsLength")*0.15 end
	suits_value = {}
	for i,suit in ipairs(suits)do
		suits_value[suit] = -i
	end
	v = v+(suits_value[core_query(card,"getSuitString")] or 0)/100


	--add
	for _, p in sgs.list(core_query(self.room,"findPlayersBySkillName","s_newtype")) do
		if core_query(self.player,"getMark","s_newtype"..p:objectName().."-Clear") > 0 then
			local pattern = core_query(p,"getNewtypePattern")
			if core_query(card,"objectName") == pattern then
				return v+10
			end
		end
	end
	return v+(13-core_query(card,"getNumber"))/100
end

-- Package callbacks formerly wrote VM-global priorities from private hand
-- simulations. Keep those writes in the observer's strategy memory instead;
-- the intentionally missing cross-observer propagation is an explicit estimate.
function SmartAIView:setDefenseValue(key,value)
    if key~="yuyan" or (value~=0 and value~=4) then ai_unsupported("unapproved source defense write",key)end
    self:setStrategyMemory("defense_override.yuyan",value)
    return self:useKnowledgeEstimate({status="estimate",value=value,
        basis="viewer_local_defense_write_without_private_cross_viewer_propagation",
        defense_key=key,observer=self.player:objectName()},"defense")
end
function SmartAIView:getDefenseValue(key)
    if key=="yuyan" then
        local value,present=self:getStrategyMemory("defense_override.yuyan")
        if present then
            if value~=0 and value~=4 then ai_unsupported("invalid source defense memory",key)end
            return self:useKnowledgeEstimate({status="estimate",value=value,
                basis="viewer_local_defense_without_private_cross_viewer_propagation",
                defense_key=key,observer=self.player:objectName()},"defense")
        end
    end
    return sgs.ai_skill_defense[key]
end

function SmartAIView:setPriorityValue(key, value, source)
    if type(key) ~= "string" or value~=nil and not finite_number(value) then ai_unsupported("invalid priority override", "priority") end
    if self:writeOverseasPriority(key,value) then return value end
    local state, present = self:getStrategyMemory("priority_overrides")
    if not present or type(state) ~= "table" then state = {} end
    -- A source `table[key]=nil` removes the effective registration. Removing
    -- this memory entry instead would resurrect the immutable baseline.
    state[key] = value==nil and {removed=true,source=source or key} or {value=value,source=source or key}
    self:setStrategyMemory("priority_overrides", state)
    self:useKnowledgeEstimate({status="estimate",value=value==nil and true or value,
        removed=value==nil,basis="viewer_local_priority_write_without_private_cross_viewer_propagation",
        source=source or key,priority_key=key,observer=self.player:objectName()},"priority")
    return value
end

local function priority_entry(self,key)
    local state,present=self:getStrategyMemory("priority_overrides")
    local entry=present and type(state)=="table" and state[key]
    if entry~=nil and entry~=false then
        if type(entry)~="table" or (entry.removed~=nil and type(entry.removed)~="boolean")
            or (entry.removed==true and entry.value~=nil)
            or (entry.removed~=true and not finite_number(entry.value)) then
            ai_unsupported("invalid priority override",key)
        end
        return entry
    end
end

-- Direct source registry reads are not adjusted card priorities: no implicit
-- default table, no caller fallback, and no callback evaluation.
function SmartAIView:getSourcePriorityValue(key)
    local actual,value=self:readNamedSourcePriority(key)
    if actual then return value end
    if type(key)~="string" then ai_unsupported("invalid raw priority key","priority")end
    local tracked,raw=self:readOverseasPriority(key)
    if tracked then return raw end
    local entry=priority_entry(self,key)
    local value
    if entry then
        if entry.removed~=true then value=entry.value end
    else value=ai_use_priority[key] end
    if value~=nil and not finite_number(value) then ai_unsupported("source priority registry is not a scalar",key)end
    if entry or key=="Slash" or key=="TianyiCard" then
        self:useKnowledgeEstimate({status="estimate",value=value==nil and true or value,
            removed=entry and entry.removed==true or false,
            basis="viewer_local_priority_without_private_cross_viewer_propagation",
            source=entry and entry.source or "registered_baseline",priority_key=key,
            observer=self.player:objectName()},"priority.raw")
    end
    return value
end

function SmartAIView:getPriorityValue(key, card, fallback)
    local actual,value=self:readNamedSourcePriority(key)
    if actual then if value==nil then return fallback end;return value end
    local tracked,raw,removed=self:readOverseasPriority(key)
    if tracked then
        if raw==nil and not removed then raw=default_use_priority[key] end
        if raw==nil then raw=fallback end
        return raw
    end
    local entry=priority_entry(self,key)
    local value
    if entry then
        if entry.removed~=true then value=entry.value end
    else value=ai_use_priority[key] end
    if value == nil and not(entry and entry.removed==true) then value = default_use_priority[key] end
    if type(value)=="function" then value=value(self,card) end
    if value == nil then value=fallback end
    if value ~= nil and not finite_number(value) then ai_unsupported("invalid card priority",key) end
    if entry or value~=nil and (key=="Slash" or key=="TianyiCard") then
        self:useKnowledgeEstimate({status="estimate",value=value==nil and true or value,
            removed=entry and entry.removed==true or false,
            basis="viewer_local_priority_without_private_cross_viewer_propagation",
            source=entry and entry.source or "registered_baseline",priority_key=key,
            observer=self.player:objectName()},"priority")
    end
    return value
end

function SmartAIView:getUsePriority(card)
	--if type(card)~="userdata" then return 0 end
	local upv = self:getSourcePriorityValue(core_query(card,"getClassName")) or 0
	if core_query(card,"isKindOf","EquipCard") then
		if self:getSameEquip(card) then
		elseif core_query(card,"isKindOf","Weapon") then upv = upv+2
		elseif core_query(card,"isKindOf","Armor") then upv = upv+2.2
		elseif core_query(card,"isKindOf","DefensiveHorse") then upv = upv+2.8
		elseif core_query(card,"isKindOf","OffensiveHorse") then upv = upv+2.5 end
		if core_query(self,"loseEquipEffect") then upv = upv+6 end
	elseif core_query(card,"getTypeId")<1 then
		if core_query(card,"isKindOf","ActiveSkillCard") then
			upv = self:getSourcePriorityValue(core_query(card,"getSkillName"))
				or self:getSourcePriorityValue(core_query(card,"getSourceSkillName")) or upv
		elseif core_query(card,"isKindOf","LuaSkillCard")
		then upv = self:getSourcePriorityValue(core_query(card,"objectName")) or upv end
		return upv
	end
	return self:adjustUsePriority(card,upv)
end

function SmartAIView:getDynamicUsePriority(card)
    local killoff
    if type(self.hasStrategyCardFlag) == "function" then killoff = self:hasStrategyCardFlag(card, "AIGlobal_KillOff")
    else killoff = value_call(card, "hasFlag", "AIGlobal_KillOff") end
    if value_known(killoff, "card flags") then return 15 end
    if card:isKindOf("DelayedTrick") and #value_known(value_call(card, "getSkillName"), "skill name") > 0 then
        local v = self:getSourcePriorityValue(card:getClassName())
        return (v or 0.1) - 0.1
    end
    local v = value_known(self:getUsePriority(card), "use priority")
    if card:isKindOf("Weapon") and #value_known(self.enemies or self:getEnemies(), "enemy relations") > 0 and value_known(value_call(self.player, "getPhase"), "phase") <= sgs.Player_Play then
        local weapon, in_range = self:evaluateWeapon(card)
        if value_known(in_range, "weapon attack range") then v = v + 0.5 end
        v = v + value_known(weapon, "weapon value") / 10
    elseif card:isKindOf("AmazingGrace") then
        local dv = 10
        for _, player in ipairs(value_known(self.room:getOtherPlayers(self.player), "other players")) do
            dv = dv - 1
            local enemy = value_known(value_call(self, "isEnemy", player), "enemy relation")
            if enemy then dv = dv - ((core_query(player,"getHandcardNum") + core_query(player,"getHp")) / core_query(player,"getHp")) * dv
            else dv = dv + ((core_query(player,"getHandcardNum") + core_query(player,"getHp")) / core_query(player,"getHp")) * dv end
        end
        v = v + dv
    elseif card:isKindOf("Duel") then
        if core_query(self.player,"getHp") <= 1 and core_query(self,"getCardsNum","Slash") == 0 then v = v - 3
        elseif core_query(self,"hasCrossbowEffect") and core_query(self,"getCardsNum","Slash") > 0 then v = self:getSourcePriorityValue("Slash") + 0.5 end
    end
    return v
end

-- table.sort receives precisely the legacy score comparator; equal-score cards
-- are not reordered by an invented ID tie-break. Source Lua arrays mutate;
-- native QList projections are copied by QList2Table.
local function sorted_copy(cards, score, ascending, filter, key_of)
    key_of = key_of or legacy_sort_key
    if not AIValue.isList(cards) then return nil end
    local result, scores = sgs.QList2Table(cards), {}
    if filter then
        -- Original flags="j" checks and removes from the tail first.
        for index=#result,1,-1 do
            local allowed=filter(result[index])
            if allowed==nil then return nil end
            if not allowed then table.remove(result,index) end
        end
    end
    if #result < 2 then return result end
    for _, card in ipairs(result) do
        local value = score(card)
        -- Preserve source numeric values (including IEEE infinities/NaN).
        -- Nil/default decisions belong to the particular source caller.
        -- Evaluate every entry, including its RNG draw, before overwriting a
        -- serialized-key collision with the last score, exactly as the donor.
        scores[key_of(card)] = value
    end
    table.sort(result, function(a, b)
        if ascending then return scores[key_of(a)] < scores[key_of(b)] end
        return scores[key_of(a)] > scores[key_of(b)]
    end)
    return result
end

local function sort_filter(self, flags)
    if flags ~= "j" then return nil end
    return function(card)
        local jilei = core_query(self.player, "isJilei", card)
        return not jilei
    end
end

local function display_ids(self)
    local has_display = value_known(hasDisplaySkills(self.player),"display property presence")
    local cards = value_known(getDisplayCards(self.player,self.player), "display cards")
    local result = {}
    for _, card in ipairs(cards) do result[core_query(card,"getEffectiveId")] = true end
    return result, has_display
end

function SmartAIView:sortByKeepValue(cards, inverse, flags)
    local result = sgs.QList2Table(cards)
    if flags == "j" then
        for i=#result,1,-1 do if core_query(self.player,"isJilei",result[i]) then table.remove(result,i) end end
    end
    if #result < 2 then return result end
    local display, has_display = display_ids(self)
    self.keepValue = self.keepValue or {}
    for _, card in ipairs(result) do
        local v = self:getKeepValue(card)
        if self:wasPreviouslyPlannedCard(card) then v = v + 2 end
        if core_query(self.player,"isLocked",card) then v = v / 2 end
        if display[core_query(card,"getEffectiveId")] then v = v + (has_display and 1.5 or -1.5) end
        self.keepValue[legacy_string_key(card)] = v
        self:persistKeepState()
    end
    table.sort(result, function(a,b)
        if inverse then return self:getKeepValue(a)>self:getKeepValue(b) end
        return self:getKeepValue(a)<self:getKeepValue(b)
    end)
    return result
end

function SmartAIView:sortByUseValue(cards, inverse, flags)
    local display, has_display
    return sorted_copy(cards, function(card)
        if not display then display, has_display = display_ids(self) end
        local v = self:getUseValue(card) or 0
        if display[card:getEffectiveId()] then v = v + (has_display and -2 or 2) end
        return v
    end, not not inverse, sort_filter(self, flags))
end

local function priority_sort(self, cards, inverse, flags, method)
    local randomness
    return sorted_copy(cards, function(card)
        -- Capture once, after filtering/early return and before the first
        -- priority callback; callbacks may themselves change the registry.
        if randomness == nil then randomness = sgs.ai_card_randomness or 0 end
        local v = self[method](self, card) or 0
        local offset = 0
        if randomness > 0 then
            local radius = (card:isKindOf("Analeptic") or card:isKindOf("EquipCard")) and 0.2 or 1.2
            offset = (math.random() - 0.5) * radius * randomness
        end
        return v + offset
    end, not not inverse, sort_filter(self, flags))
end

function SmartAIView:sortByUsePriority(cards, inverse, flags)
    return priority_sort(self, cards, inverse, flags, "getUsePriority")
end
function SmartAIView:sortByDynamicUsePriority(cards, inverse, flags)
    return priority_sort(self, cards, inverse, flags, "getDynamicUsePriority")
end

-- Per-decision keep assignment mirrors SmartAI's override order and duplicate
-- reduction. No global turn count or other viewer's keep cache is consulted.
function SmartAIView:assignKeep(start)
    self.keepdata = self.keepdata or {}
	if start then
		self.keepdata = {}
		self:persistKeepState()
		for k,v in pairs(sgs.ai_keep_value)do
			self.keepdata[k] = v
			self:persistKeepState()
		end
		for _,sk in ipairs(sgs.getPlayerSkillList(self.player))do
			local kv = sgs[sk:objectName().."_keep_value"]
			if kv then
				for k,v in pairs(kv)do
					self.keepdata[k] = v
			self:persistKeepState()
				end
			end
		end
	end
	if core_query(self.room,"getTurnCount")<=1 or #self.enemies<1 then self.keepdata.Jink = 4.2; self:persistKeepState() end
	if core_query(self,"getOverflow",nil,true)==1 then-- 特殊情况下还是要留闪，待补充...
		self.keepdata.Analeptic = (self.keepdata.Jink or 5.2)+0.1
		self:persistKeepState()
	end
	if core_query(self,"isWeak") then
		if core_query(self,"hasSkills","buyi",self.friends) then
			self.keepdata.EquipCard = 7.9
			self:persistKeepState()
			self.keepdata.TrickCard = 8
			self:persistKeepState()
			self.keepdata.Peach = 10
			self:persistKeepState()
		end
	else
		if core_query(self.player,"getHandcardNum")>3 then
			for _,f in ipairs(self.friends_noself)do
				if core_query(self,"willSkipDrawPhase",f) or core_query(self,"willSkipPlayPhase",f)
				then self.keepdata.Nullification = 5.5; self:persistKeepState(); break end
			end
		end
		--add
		if core_query(self,"hasSkills","meizlzhuanchong",self.friends) then
			self.keepdata.Peach = 10
			self:persistKeepState()
			self.keepdata.EquipCard = 7.9
			self:persistKeepState()
		end
		if core_query(self.player,"getHp")>self:getBestHp(self.player)
		or not core_query(self,"isGoodTarget",self.player,self.friends)
		or core_query(self,"needToLoseHp") then
			self.keepdata.Slash = 5
			self:persistKeepState()
			self.keepdata.FireSlash = 5.1
			self:persistKeepState()
			self.keepdata.ThunderSlash = 5.2
			self:persistKeepState()
			self.keepdata.Jink = 4.5
			self:persistKeepState()
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if core_query(enemy,"hasSkill","nosqianxi",true)
		and core_query(enemy,"distanceTo",self.player)==1
		then self.keepdata.Jink = 6; self:persistKeepState() end
	end
	self._keep_skill_eval_cache = {}
	self:persistKeepState()
	self.keepValue = {}
	self:persistKeepState()
	for _,c in sgs.qlist(core_query(self.player,"getCards","he"))do
		self.keepValue[legacy_string_key(c)] = self:getKeepValue(c,true)
		self:persistKeepState()
	end
	local kept, kept_count = {}, {}
	for i,h in ipairs(self:sortByKeepValue(core_query(self.player,"getHandcards"),true))do
		if i>20 then break end
		self.keepValue[legacy_string_key(h)] = self:getKeepValue(h,{list=kept,count=kept_count})
		self:persistKeepState()
		table.insert(kept,h)
		local owner = self.room:getCardOwner(h:getEffectiveId()) or self.player
		local owner_name = owner:objectName()
		kept_count[owner_name] = kept_count[owner_name] or {}
		kept_count[owner_name][h:getClassName()] = (kept_count[owner_name][h:getClassName()] or 0)+1
		if h:isKindOf("Slash") then
			kept_count[owner_name].Slash = (kept_count[owner_name].Slash or 0)+1
		end
	end
end

function SmartAIView:getUsageState()
    local limit, penalty = 999, false
    local actor = self.player
    for _, player in sgs.qlist(core_query(self, "getCachedAlivePlayers")) do
        for _, name in ipairs(core_query(self, "getConnections", player)) do
            local callback = sgs.ai_card_usage_limit[name]
            if callback then
                -- Source calls every truthy registration; a malformed callable
                -- remains an ordinary error rather than disappearing.
                local value = callback(self, player, actor)
                if AIUnsupported.is(value)then error(value,0)end
                if type(value) == "number" and value < limit then limit = value end
            end
            if not penalty then
                callback = sgs.ai_card_usage_penalty[name]
                if callback then
                    local value=callback(self,player,actor)
                    if AIUnsupported.is(value)then error(value,0)end
                    if value then penalty=true end
                end
            end
        end
    end
    return limit, penalty
end

-- 快照沒有這個欄位時，getter 本身就不存在；先確認再呼叫，缺值回 fallback，
-- 不讓一個少掉的欄位變成 "attempt to call a nil value"。
local function scalar(player, method_name, fallback)
    local getter = player and player[method_name]
    if type(getter) ~= "function" then return fallback end
    local value = getter(player)
    if type(value) ~= "number" then return fallback end
    return value
end

-- Fixed smart-ai.lua:1159-1178 comparator bodies. Player views remain
-- viewer-bound; native-only hidden canSlash inputs retain the existing query bound.
sgs.ai_compare_funcs = sgs.ai_compare_funcs or {}
sgs.ai_compare_funcs.value = function(a,b) return sgs.getValue(a)<sgs.getValue(b) end
sgs.ai_compare_funcs.chaofeng = function(a,b) return sgs.getDefense(a)<sgs.getDefense(b) end
sgs.ai_compare_funcs.threat = function(a,b)
    local d1 = core_query(a,"getHandcardNum")
    for _,p in sgs.qlist(core_query(a,"getAliveSiblings")) do
        if core_query(a,"canSlash",p) then d1 = d1+10/sgs.getDefense(p) end
    end
    local d2 = core_query(b,"getHandcardNum")
    for _,p in sgs.qlist(core_query(b,"getAliveSiblings")) do
        if core_query(b,"canSlash",p) then d2 = d2+10/sgs.getDefense(p) end
    end
    return d1>d2
end

-- Legacy player ordering: default defenseSlash; ties always use public defense
-- ascending, even for inverse order. Unknown data never becomes zero.
local sort_keys = {
    defense = function(self, player) return self:getDefenseSlash(player) end,
    defenseSlash = function(self, player) return self:getDefenseSlash(player) end,
    chaofeng = function(self, player) return self:getDefense(player) end,
    hp = function(self, player)
        local hp, armor = scalar(player, "getHp"), scalar(player, "getHujia")
        if hp == nil or armor == nil then return nil end
        return hp + armor
    end,
    HP = function(self, player) return scalar(player, "getHp") end,
    maxhp = function(self, player) return scalar(player, "getMaxHp") end,
    maxcards = function(self, player) return scalar(player, "getMaxCards") end,
    handcard = function(self, player) return scalar(player, "getHandcardNum") end,
    equip = function(self, player) local cards = player:getEquips(); return cards and #cards end,
    skill = function(self, player) local skills = player:getVisibleSkillList(); return skills and #skills end,
    card = function(self, player) return scalar(player, "getCardCount") end,
    handcard_defense = function(self, player)
        local hand, defense = scalar(player, "getHandcardNum"), self:getDefenseSlash(player)
        if hand == nil or defense == nil then return nil end
        return hand + defense
    end
}

function SmartAIView:sort(players, key, anti)
    if not AIValue.isList(players) then return nil end
    local result = sgs.QList2Table(players)
    if #result < 2 then return result end
    value_known(value_call(self, "refreshDefenseSnapshotForSort", result), "defense snapshot freshness")
    local score = sort_keys[key or "defense"] or sort_keys.defense
    local scores = {}
    if key ~= "chaofeng" then
        for _, player in ipairs(result) do
            local value = score(self,player)
            if value == nil then ai_unsupported("player sort score is unknown","sort") end
            scores[player:objectName()] = value
        end
    end
    table.sort(result,function(a,b)
        if key=="chaofeng" or scores[a:objectName()]==scores[b:objectName()] then
            return sgs.ai_compare_funcs.chaofeng(a,b)
        end
        if anti then return scores[a:objectName()]>scores[b:objectName()] end
        return scores[a:objectName()]<scores[b:objectName()]
    end)
    if key == "chaofeng" and anti then
        local reversed={}
        for i=#result,1,-1 do reversed[#reversed+1]=result[i] end
        return reversed
    end
    return result
end

-- 威脅與防禦評估：只用快照裡的公開值與自己看得見的牌，缺資料就回 nil。
function SmartAIView:getCardsNum(class_name, flags, selfonly)
    -- Donor flags is a zone selector, not an alternate player. Any nonstring
    -- value reaches getCards' owner he+handpile domain, including PlayerView.
    if type(class_name) == "table" then
        local total = 0
        for _, name in ipairs(class_name) do total = total + value_known(self:getCardsNum(name, flags, selfonly), "card count") end
        return total
    end
    if type(class_name) ~= "string" then return 0 end
    local count = 0
    for _, card in ipairs(value_known(self:getCards(class_name, flags), "available cards")) do
        local skill = value_known(value_call(card, "getSkillName"), "card skill name")
        if ("spear|fuhun"):match(skill) then
            count = count + math.floor(#value_known(self:addHandPile(), "hand pile cards") / 2)
        else
            local skill_names = value_known(value_call(card, "getSkillNames"), "card skill names")
            local jiuzhu = false
            for _, name in ipairs(skill_names) do if name == "jiuzhu" then jiuzhu = true break end end
            if jiuzhu then
                count = math.max(count, math.max(0, math.min(value_known(value_call(self.player, "getCardCount"), "card count"), self.player:getHp() - 1)))
            elseif value_known(value_call(card, "getSkillName"), "card skill name"):find("chunlao", 1, true) then count = count + value_known(self.player:getPileCount("wine"), "wine pile count")
            else count = count + 1 end
        end
    end
    if selfonly then return count end
    local kingdom, name, skill
    if class_name:find("Jink", 1, true) then kingdom, name, skill = "wei", "Jink", "hujia"
    elseif class_name:find("Slash", 1, true) then kingdom, name, skill = "shu", "Slash", "jijiang" end
    if skill and value_known(self.player:hasLordSkill(skill), "lord skill") then
        for _, liege in ipairs(value_known(self.room:getLieges(kingdom, self.player), "lieges")) do
            if value_known(value_call(self, "isFriend", liege), "liege relation") then
                count = count + value_known(self:estimateCardsNum(name, liege), "liege card count")
            end
        end
    end
    return count
end

-- 已知與估計是兩個答案（計畫 §6.3）。上面的 getCardsNum 只數看得見的牌：別人的
-- 暗牌在那裡是「沒看到」，不是「沒有」。要把暗牌算進去的呼叫者改用 estimateCardsNum，
-- 拿回來的是估計值，而且呼叫端知道自己拿到的是估計值。

-- 這名玩家有幾張牌是這個觀察者看不見的。手牌全開時是 0；快照答不出張數時回 nil。
function SmartAIView:getUnknownCardsNum(player)
    player = player or self.player
    local total = player:getHandcardNum()
    if type(total) ~= "number" then return nil end
    local known = player:getKnownCards()
    if not known then return total end
    local unknown = total - #known
    if unknown < 0 then return 0 end
    return unknown
end

-- The actual baseline global getCardsNum delegates to getKnownCard with
-- view-as=true and flags="he". It does not apply a deck-density estimate.
function SmartAIView:estimateCardsNum(class_name, player)
    player = player or self.player
    if type(getKnownCard) ~= "function" then return nil end
    return getKnownCard(player, self.player, class_name, true, "he")
end

local function defense_query(object, method, ...)
    return value_known(value_call(object, method, ...), "defense " .. method)
end
function SmartAIView:calculateDefenseRefresh(player)
    local function estimate(value, basis)
        return defense_query(self, "useKnowledgeEstimate", {value=value,status="estimate",basis=basis,observer=self.player:objectName()}, "getDefense")
    end
    local thrown_samples = {}
    local function historical_means(key)
        local statistics, known = self:getEventMemory("defense_statistics")
        local samples = known and type(statistics) == "table" and statistics[key]
        local result = {}
        if type(samples) == "table" then
            for name, series in pairs(samples) do
                local sum = 0
                for _, number in ipairs(series) do sum = sum + number end
                result[name] = #series > 0 and sum / #series or 0
                if key == "throwData" and #series > 0 then thrown_samples[name] = true end
            end
        else
            local keymap = {drawData="draw_data",damageData="damage_data",throwData="throw_data",convertData="convert_data"}
            local observed, available = self:getEventMemory(keymap[key])
            if available and type(observed) == "table" then
                for name, total in pairs(observed) do
                    if finite_number(total) then
                        result[name] = total
                        if key == "throwData" then thrown_samples[name] = true end
                    end
                end
                estimate(0, "defense " .. key .. " uses current observed totals as one game sample")
            else estimate(0, "defense " .. key .. " has no observed samples; zero prior") end
        end
        return result
    end
    local draw, damage, thrown, converted = historical_means("drawData"), historical_means("damageData"), historical_means("throwData"), historical_means("convertData")
    local connections = defense_query(self, "getConnections", player)
    local value = #connections * 0.2
    local visible = {}
    for _, skill in ipairs(defense_query(player, "getSkills")) do visible[skill:objectName()] = skill end
    for _, name in ipairs(connections) do
        local callback = self:getDefenseValue(name)
        if type(callback) == "function" then callback = callback(self, player) end
        if type(callback) == "number" then value = value + callback end
        local metadata, known = visible[name], visible[name] ~= nil
        if not known and type(self.room.getPublicSkill) == "function" then metadata, known = self.room:getPublicSkill(name) end
        if metadata then
            if defense_query(metadata, "hasTriggerEvent", sgs.Damaged) then value = value + 3 end
            if defense_query(metadata, "getDescription"):find("已损失", 1, true) then value = value + 2 end
        elseif not known then estimate(0, "no public engine skill metadata for connection " .. name) end
        for _, means in ipairs({draw, damage, thrown, converted}) do
            if type(means[name]) == "number" then
                local amount = means[name]
                if means == thrown and thrown_samples[name] then
                    amount = defense_query(self, "useKnowledgeEstimate", {
                        value=amount, status="estimate", basis="throw_data.viewer_only_aggregate",
                        observer=self.player:objectName()
                    }, "getDefense.statistics")
                end
                value = value - amount
            end
        end
    end
    local keepdata = self.keepdata
    if type(keepdata) ~= "table" then
        keepdata = sgs.ai_keep_value
        estimate(0, "viewer keepdata not yet retained; printed keep values used")
    end
    for class, keep in pairs(keepdata) do
        local knowledge = defense_query(self, "estimateHasVirtualCard", player, class)
        if defense_query(self, "useKnowledgeEstimate", knowledge, "getDefense virtual-card deduction") then value = value - keep end
    end
    for name in (sgs.masochism_skill or ""):gmatch("[^|]+") do if defense_query(player, "hasSkill", name) then value = value + 1 end end
    for name in (sgs.exclusive_skill or ""):gmatch("[^|]+") do if defense_query(player, "hasSkill", name) then value = value + 3 end end
    if defense_query(player, "getMark", "@tied") > 0 then value = value + 1 end
    local siblings = defense_query(self.room, "getOtherPlayers", player)
    local function hate_bonus()
        for _, sibling in ipairs(siblings) do
            if defense_query(sibling, "getMark", "hate_" .. player:objectName()) > 0 and defense_query(sibling, "getMark", "@hate_to") > 0 then return defense_query(sibling, "getHp") end
        end
        return 0
    end
    if defense_query(player, "getMark", "xhate") > 0 and defense_query(player, "hasLordSkill", "shichou") then value = value + hate_bonus() end
    if defense_query(player, "getHp") <= 2 then value = value - 0.4 end
    if defense_query(player, "getHp") > defense_query(self, "getBestHp", player) then value = value + 0.8 end
    if defense_query(player, "isLord") then
        value = value - 0.4
        if defense_query(self, "isLordInDanger") then value = value - 0.7 end
    end
    if not defense_query(player, "faceUp") then value = value - 1 end
    if defense_query(player, "getMark", "@skill_invalidity") > 0 then value = value - 5 end
    if defense_query(player, "hasLordSkill", "shichou") and defense_query(player, "getMark", "xhate") > 0 then value = value + hate_bonus() end
    for _, sibling in ipairs(siblings) do
        if defense_query(sibling, "hasSkill", "SixZhongyong") and defense_query(player, "getHandcardNum") < defense_query(sibling, "getHandcardNum")
            and defense_query(self, "beFriend", sibling, player) then value = value + (defense_query(sibling, "getHandcardNum") + defense_query(sibling, "getHp")) * 0.5 break end
    end
    for _, sibling in ipairs(siblings) do
        if defense_query(sibling, "hasSkill", "y_yongjue") and defense_query(player, "getHandcardNum") < defense_query(player, "getHp")
            and defense_query(self, "beFriend", sibling, player) then value = value + (defense_query(sibling, "getHandcardNum") + defense_query(sibling, "getHp")) * 0.5 break end
    end
    for _, sibling in ipairs(siblings) do
        if defense_query(sibling, "hasSkill", "keguiqinwang") and defense_query(sibling, "getPhase") == sgs.Player_NotActive
            and defense_query(self, "beFriend", sibling, player) then value = value + (defense_query(sibling, "getHandcardNum") + defense_query(sibling, "getHp")) * 0.5 break end
    end
    local current = self.room:getCurrent()
    if current then
        local alive = defense_query(self.room, "alivePlayerCount")
        value = value + (alive - (defense_query(player, "getSeat") - defense_query(current, "getSeat")) % alive) / 4
    end
    return value
end

function SmartAIView:getValue(player)
    player = player or self.player
    return core_query(player,"getHp")*2 + core_query(player,"getHandcardNum") + core_query(player,"getHandPileCount")
end
function sgs.getValue(player)
    return core_query(player,"getHp")*2 + core_query(player,"getHandcardNum") + core_query(player,"getHandPileCount")
end
function sgs.getDefense(player,start)
    local room = type(player)=="table" and rawget(player,"_room")
    local ai = room and room._ai
    if not ai then ai_unsupported("defense requires a viewer-bound player facade","getDefense") end
    return ai:getDefense(player,start)
end

function SmartAIView:getDefense(player, start)
    player = player or self.player
    -- sgs.getDefense's ordinary branch is getValue plus a separately maintained
    -- defense baseline. The baseline is not a fresh estimate from visible cards.
    if start == true then
        local humanized = self.world and self.world.ai_humanized
        if type(humanized) ~= "boolean" then
            ai_unsupported("defense AIHumanized configuration is unknown", "getDefense")
        end
        if humanized then
            local turn = value_known(value_call(self.room, "getTurnCount"), "defense turn count")
            if turn >= 1 then
                if type(self.getDefenseRefreshCache) ~= "function" or type(self.setDefenseRefreshCache) ~= "function" then
                    ai_unsupported("defense refresh cache lifecycle is unavailable","getDefense")
                end
                local cached = self:getDefenseRefreshCache(player)
                if cached ~= nil then return cached end
                -- Match the donor's provisional value before callbacks. A
                -- recursive defense query in the same second returns this seed.
                self:setDefenseRefreshCache(player,self:getDefense(player,false))
                local value = self:calculateDefenseRefresh(player)
                self:setDefenseRefreshCache(player,value)
                return value
            end
        end
    end
    if type(self.getEventMemory) ~= "function" then
        ai_unsupported("defense baseline event memory is unavailable", "getDefense")
    end
    local snapshot, known = self:getEventMemory("defense_snapshot")
    if (known ~= true or type(snapshot) ~= "table") and type(self.ensureDefenseSnapshot) == "function" then
        value_known(self:ensureDefenseSnapshot(), "defense baseline initialization")
        snapshot, known = self:getEventMemory("defense_snapshot")
    end
    if known ~= true or type(snapshot) ~= "table" then
        ai_unsupported("defense baseline event memory is unknown", "getDefense")
    end
    local name = value_known(value_call(player, "objectName"), "defense player identity")
    local baseline = snapshot[name]
    if not finite_number(baseline) then
        ai_unsupported("defense baseline is missing for player", "getDefense")
    end
    local hp = value_known(value_call(player, "getHp"), "defense HP")
    local hand = value_known(value_call(player, "getHandcardNum"), "defense hand count")
    local pile = value_known(value_call(player, "getHandPileCount"), "defense hand pile count")
    local value = hp * 2 + hand + pile + baseline
    local branches, branches_known = self:getEventMemory("estimation_branches")
    if branches_known and type(branches) == "table" and branches["defense.late_initialization_seat_prior"] then
        return value_known(value_call(self, "useKnowledgeEstimate", {value=value,status="estimate",basis="defense.late_initialization_seat_prior",observer=self.player:objectName()}, "getDefense baseline"), "defense estimate")
    end
    return value
end

function SmartAIView:getNeedPeach(player)
    player = player or self.player
    if not player then return nil end
    if type(self.getEventMemory) ~= "function" then
        ai_unsupported("Peach reserve event memory is unavailable", "getNeedPeach")
    end
    local values, known = self:getEventMemory("need_peach")
    if known ~= true or type(values) ~= "table" then
        ai_unsupported("Peach reserve event memory is unknown", "getNeedPeach")
    end
    return value_known(values[player:objectName()], "Peach reserve for player")
end

function SmartAIView:isWeak(player, getAP)
    if AIValue.isList(player) then
        for _, target in ipairs(player) do
            local weak = self:isWeak(target, getAP)
            if AIUnsupported.is(weak) then error(weak,0) end
            if weak then return true end
        end
        return false
    end
    player = player or self.player
    local function query(method, ...)
        local value=value_call(player,method,...)
        if value==nil and method=="inYinniState"
            and player:objectName()~=self.player:objectName() then
            return self:useKnowledgeEstimate({status="estimate",value=false,
                basis="foreign_yinni_state_not_disclosed_assume_inactive",
                target=player:objectName()},"isWeak")
        end
        return value_known(value, "weakness " .. method)
    end
    if value_known(hasBuquEffect(player), "Buqu effect") or query("inYinniState") or query("hasSkill", "dev_shanbi")
        or query("getCardCount") > 2 and query("hasSkills", "longhun|newlonghun")
        or query("getHandcardNum") > 1 and query("hasSkills", "yingba+pinghe") then return false end
    local hp = query("getHp")
    if core_query(player,"getStrategyMark","hunzi") < 1 and hp > 1 and query("hasSkill", "hunzi")
        or core_query(player,"getStrategyMark","mobilehunzi") < 1 and hp > 2 and query("hasSkill", "mobilehunzi") then return false end
    for _, mark in ipairs(query("getMarkNames")) do
        if mark:find("ai_hp", 1, true) then hp = hp + core_query(player,"getStrategyMark",mark) end
    end
    hp = hp + query("getHujia")
    if hp > 2 then return false end
    if hp <= 1 then return true end
    -- Source reads the hand count before inspecting its pile length.
    local hand_count=query("getHandcardNum")
    local pile_count=query("getHandPileCount")
    return hp <= 2 and hand_count + pile_count <= 2
end

function SmartAIView:getThreat(player)
    player = player or self.player
    local value = core_query(player,"getHandcardNum")
    for _, other in ipairs(core_query(self.room,"getOtherPlayers",player)) do
        if core_query(player,"canSlash",other) then value=value+10/core_query(self,"getDefense",other) end
    end
    return value
end

function SmartAIView:getChaofeng(player)
    player = player or self.player
    if not player then return nil end
    local value = sgs.ai_chaofeng[player:objectName()]
    if type(value) == "function" then value = value(self, player) end
    -- Missing policy data remains uncovered; zero must be an explicit value.
    return finite_number(value) and value or nil
end

-- Original equipment value callback ABI and arithmetic, smart-ai.lua:6421-6492.
local function equipment_known(value, field)
    if AIUnsupported.is(value) then error(value,0) end
    if value == nil then ai_unsupported("equipment value input is unknown", field) end
    return value
end
local function equipment_call(object, method, ...)
    if not object or type(object[method]) ~= "function" then ai_unsupported("equipment value method missing", method) end
    return equipment_known(value_call(object,method,...), method)
end
local function equipment_count(self, kind, owner)
    return equipment_known(getCardsNum(kind,owner,self.player),kind)
end
local function r32_optional_equipment(player,method)
    local result=value_call(player,method)
    if result~=nil then return result end
    local row=rawget(player,"_view")
    if type(row)~="table" or not AIValue.isList(row.equips) then
        ai_unsupported("equipment zone is unavailable",method)
    end
    return nil
end
local function r32_equipment_callback(callback,...)
    local result=callback(...)
    if AIUnsupported.is(result) then error(result,0) end
    return result
end
function SmartAIView:evaluateWeapon(card, owner, target)
    if not card or not (AIValue.isCard(card) or AIValue.isConversion(card)) then return -1 end
    if not equipment_call(card, "isKindOf", "Weapon") then return -1 end
    local range = sgs.weapon_range[equipment_call(card, "getClassName")] or 1
    owner = owner or self.player
    local enemies = target and {target} or equipment_call(self, "getEnemies", owner)
    equipment_call(self,"sort",enemies)
    local value, in_range = 0, false
    for i, enemy in ipairs(enemies) do
        if equipment_call(owner, "distanceTo", enemy) <= range then
            local defense = equipment_call(self, "getDefenseSlash", enemy) / 2
            if defense < 0 then defense = 6 - defense
            elseif defense <= 1 then defense = 6
            else defense = 6 / defense end
            value, in_range = value + defense + #enemies - i, true
        end
    end
    if in_range and equipment_call(card, "isKindOf", "Crossbow") then
        local slashes = equipment_count(self, "Slash", owner)
        value = value + slashes * 2
        if equipment_call(owner, "hasSkill", "kurou") then
            value = value + equipment_count(self, "Peach,Analeptic", owner) + equipment_call(self.player, "getHp")
        end
        if slashes > 0 and r32_optional_equipment(owner,"getWeapon") and not equipment_call(self, "hasCrossbowEffect", owner) then
            for _, enemy in ipairs(enemies) do
                if equipment_call(owner, "distanceTo", enemy) <= range
                    and (slashes > 1 or equipment_count(self, "Jink", enemy) < 1) then value = value + 5 end
            end
        end
    end
    local callback = sgs.ai_weapon_value[equipment_call(card,"objectName")]
    if type(callback) == "function" then
        value = value + (r32_equipment_callback(callback,self,nil,owner) or 0)
        for _, enemy in ipairs(enemies) do
            if equipment_call(owner, "distanceTo", enemy) <= range then
                local filter = sgs.ai_slash_weaponfilter[equipment_call(card,"objectName")]
                if type(filter) == "function" and r32_equipment_callback(filter,self,enemy,owner) then value = value + 1 end
                value = value + (r32_equipment_callback(callback,self,enemy,owner) or 0)
            end
        end
    end
    if equipment_call(owner, "hasSkill", "jijiu") and equipment_call(card, "isRed") then value = value + 0.5 end
    if equipment_call(owner, "hasSkills", "qixi|guidao") and equipment_call(card, "isBlack") then value = value + 0.5 end
    return value, in_range
end
function SmartAIView:evaluateArmor(card, owner)
    owner = owner or self.player
    if type(card)=="number" then
        -- Engine IDs may name any lawfully disclosed current card, not only
        -- the evaluated owner's zones. Unknown foreign/hidden IDs stay unknown.
        card=equipment_known(self:getKnownCardById(card),"armor card identity")
    else card=card or r32_optional_equipment(owner,"getArmor") end
    local value = 0
    for _, skill in ipairs(equipment_call(owner,"getVisibleSkillList",true)) do
        local callback = sgs.ai_armor_value[equipment_call(skill, "objectName")]
        if type(callback) == "function" then value = value + (r32_equipment_callback(callback,owner,self,card) or 0)
        elseif type(callback) == "number" then value = value + callback end
    end
    if card then
        value = value + 0.1
        if equipment_call(card, "isRed") then
            if equipment_call(owner, "hasSkill", "jijiu") then value = value + 0.5 end
        elseif equipment_call(card, "isBlack") then
            if equipment_call(owner, "hasSkills", "qixi|guidao") then value = value + 0.5 end
        end
        local callback = sgs.ai_armor_value[equipment_call(card, "objectName")]
        if type(callback) == "function" then value = value + (r32_equipment_callback(callback,owner,self,card) or 0)
        elseif type(callback) == "number" then value = value + callback end
    end
    return value
end

function SmartAIView:bindConversionCosts(conversion, owned_by_id)
    if not AIValue.isConversion(conversion) then
        ai_unsupported("conversion cost binding needs a conversion", "conversion")
    end
    local getter = conversion.getCostCount
    local declared = type(getter) == "function" and getter(conversion) or nil
    if declared ~= nil and (not finite_number(declared) or declared < 0 or declared % 1 ~= 0) then
        ai_unsupported("conversion cost count is invalid", "conversion")
    end
    -- The facade's parameterized protocol starts at two cards. Fixed tickets
    -- already carry authority-bound subcards, even when cost_count is annotated.
    if declared == nil or declared < 2 then
        local subcards = conversion:getSubcards()
        -- Native cost_count=0 means an exact-subcards ticket, not a free card.
        if not subcards or (declared == 1 and #subcards ~= declared) then
            ai_unsupported("fixed conversion costs are incomplete", "conversion")
        end
        return conversion
    end
    local eligible, count = conversion:getCostSelection()
    if not eligible or count ~= declared then
        ai_unsupported("conversion cost projection is incomplete", "conversion")
    end
    owned_by_id = owned_by_id or {}
    local payments, seen = {}, {}
    for _, id in ipairs(eligible) do
        if not finite_number(id) or id < 0 or id % 1 ~= 0 then
            ai_unsupported("conversion cost id is invalid", "conversion")
        end
        if not seen[id] then
            seen[id] = true
            local card = owned_by_id[id]
            if not card or card:getId() ~= id then ai_unsupported("unknown conversion cost", "conversion") end
            local value = self:getKeepValue(card)
            if not finite_number(value) then ai_unsupported("invalid conversion cost value", "conversion") end
            payments[#payments + 1] = {id = id, value = value}
        end
    end
    local ids = {}
    -- O(k*n) minimum selection; score each unique card once, never pay an ID
    -- twice. withSubcards checks membership/count, not coupled native rules.
    for index = 1, count do
        local best, best_index
        for payment_index, payment in ipairs(payments) do
            if not best or payment.value < best.value
                or (payment.value == best.value and payment.id < best.id) then
                best, best_index = payment, payment_index
            end
        end
        if not best then ai_unsupported("conversion cost is too short", "conversion") end
        ids[index] = best.id
        table.remove(payments, best_index)
    end
    local bound = conversion:withSubcards(ids)
    if not bound then ai_unsupported("conversion cost membership rejected", "conversion") end
    return bound
end
function SmartAIView:getOfferedTurnUse(allow_partial, for_planning)
    local candidates, conversions = self:getCardCandidates(), self:getConversions()
    local unknown
    local function record(reason, key)
        local signal = AIUnsupported.new(reason, key)
        if not allow_partial then error(signal, 0) end
        unknown = unknown or signal
    end
    if not candidates then
        if not allow_partial then return nil end
        record("physical candidate projection is unknown", "candidate")
    end
    local by_id = {}
    for _, cards in ipairs({self.player:getHandcards() or {}, self.player:getEquips() or {}}) do
        for _, card in ipairs(cards) do by_id[card:getId()] = card end
    end
    local uses = AIList.new({})
    local function append(card, candidate, candidate_id)
        local targets = candidate:getLegalTargets()
        local rows = candidate:getTargetCombinations()
        if candidate:hasCompleteCoverage() ~= true or not targets or not rows then
            ai_unsupported("target combinations are incomplete", card:getClassName())
        end
        if #rows > 0 then
            local use = {card = card, card_id = card:getEffectiveId(), candidate_id = candidate_id,
                targets = targets, target_fixed = candidate:targetFixed(),
                needs_a_target = candidate:needsATarget()}
            -- Existing package consumers compare these public fields. The actual
            -- turn planner evaluates use value only in the legacy restricted branch.
            if not for_planning then
                use.priority = value_known(self:getUsePriority(card), "use priority")
                use.value = value_known(self:getUseValue(card), "use value")
            end
            uses:append(use)
        end
    end
    local function collect(fn)
        local ok, signal = AIUnsupported.capture(fn)
        if not ok then
            if not allow_partial then error(signal, 0) end
            unknown = unknown or signal
        end
    end
    for _, candidate in ipairs(candidates or {}) do
        collect(function()
            if type(candidate.isAvailable) ~= "function" or type(candidate.isLimited) ~= "function" then
                ai_unsupported("physical availability is unknown", "candidate")
            end
            local available, limited = candidate:isAvailable(), candidate:isLimited()
            if available == false or limited == true then return end
            if available ~= true or limited ~= false then ai_unsupported("physical availability is unknown", "candidate") end
            local card = by_id[candidate:getCardId()]
            if not card then ai_unsupported("candidate card metadata is unknown", "candidate") end
            append(card, candidate, candidate:getCandidateId())
        end)
    end
    if not conversions and allow_partial then record("conversion projection is unknown", "conversion") end
    for _, conversion in ipairs(conversions or {}) do
        collect(function()
            if type(conversion.isAvailable) ~= "function" then
                ai_unsupported("conversion availability is unknown", "conversion")
            end
            local available = conversion:isAvailable()
            if available == false then return end
            if available ~= true then ai_unsupported("conversion availability is unknown", "conversion") end
            local bound = self:bindConversionCosts(conversion, by_id)
            append(bound, bound)
        end)
    end
    if #uses > 128 then ai_unsupported("candidate budget exceeded", "planning") end
    if #uses > 1 then
        local ranked = AIList.new({})
        for _, use in ipairs(uses) do
            collect(function()
                use.priority = value_known(self:getDynamicUsePriority(use.card), "dynamic priority")
                local randomness = sgs.ai_card_randomness or 0
                if randomness > 0 then
                    local card = use.card
                    local radius = (card:isKindOf("Analeptic") or card:isKindOf("EquipCard")) and 0.2 or 1.2
                    use.priority = use.priority + (math.random() - 0.5) * radius * randomness
                end
                if not finite_number(use.priority) then ai_unsupported("non-finite dynamic priority", "planning") end
                ranked:append(use)
            end)
        end
        uses = ranked
        table.sort(uses, function(first, second) return first.priority > second.priority end)
    end
    return uses, unknown
end
-- 共用的目標排序。activate、aiUseCard 與每一張牌的策略都只用這一份：同一張牌無論
-- 由哪條路徑問，挑出來的人要一樣。stance 說這張牌想打誰——傷害牌找敵人，增益牌找
-- 友軍，"any" 才照原順序全收。回傳 PlayerView，不是名字。
function SmartAIView:rankTargets(target_names, stance)
    if not AIValue.isList(target_names) then return nil end
    stance = stance or "any"
    local ranked = {}
    for _, name in ipairs(target_names) do
        local target = self.room:findPlayerByObjectName(name, true)
        if not target then return nil end -- Missing roster data is not an empty target set.
        ranked[#ranked + 1] = {name = name, player = target}
    end
    -- 關係未知就是不知道，不是「沒有敵人」，也不是「誰都可以打」：認得出陣營才
    -- 排得出敵友，認不出時只有 "any" 還答得出東西。
    if not self:isModeManaged() then
        if stance ~= "any" then return nil end
        local plain = AIList.new({})
        for index, entry in ipairs(ranked) do plain[index] = entry.player end
        return plain
    end
    for _, entry in ipairs(ranked) do
        local relation = self:relationTo(entry.player)
        -- A managed policy may still leave this particular relationship unknown.
        if stance ~= "any" and (relation == nil or relation == "unknown") then return nil end
        entry.enemy = relation == "enemy"
        entry.friend = relation == "friend"
        local weak, threat = self:isWeak(entry.player), self:getThreat(entry.player)
        if weak == nil or threat == nil then return nil end
        entry.score = (entry.enemy and 100 or 0) + (weak and 10 or 0) + threat
    end
    table.sort(ranked, function(first, second)
        if first.score ~= second.score then return first.score > second.score end
        return first.name < second.name
    end)
    local chosen = AIList.new({})
    for _, entry in ipairs(ranked) do
        local wanted = stance == "any"
            or (stance == "enemy" and entry.enemy)
            or (stance == "friend" and entry.friend)
        if wanted then chosen[#chosen + 1] = entry.player end
    end
    return chosen
end

-- 名字版的薄入口，保留舊呼叫方式；排序本身還是上面那一份。
function SmartAIView:pickTargets(use, count)
    if type(use) ~= "table" or not use.targets then return nil end
    count = count or 1
    local ranked = self:rankTargets(use.targets, "enemy")
    if not ranked then return nil end
    local chosen = AIList.new({})
    for _, target in ipairs(ranked) do
        if #chosen >= count then break end
        chosen[#chosen + 1] = target:objectName()
    end
    return chosen
end

-- 出牌計劃：作者看到的 use。沿用舊寫法——use.card 有值代表「打算這樣打」，
-- use.to 是目標集合，append／first／length／isEmpty 都在。差別只有兩點且不可混淆：
-- use.to 是純 Lua 的 AIList，不是 SPlayerList；裡面是 PlayerView，不是 ServerPlayer。
AIUsePlan = {}
AIUsePlan.__index = AIUsePlan

function AIUsePlan.new()
    return setmetatable({to = AIList.new({})}, AIUsePlan)
end

-- 轉成值型答案。目標只送 object name，權威端自己重查人、重驗完整目標；
-- 這裡不宣稱這個組合合法，只宣稱「策略想這樣打」。
function AIUsePlan:toAnswer()
    if self._evaluation_only then return nil end
    if not self.card then return nil end
    if type(self.card.isEvaluationOnly) == "function" and self.card:isEvaluationOnly() == true then return nil end
    local answer = {kind = "use_card"}
    -- 轉化送的是票。牌名／花色／點數／成本一起送，只是讓權威端能比對出不一致並拒絕；
    -- 授權來自票，不來自這些欄位，所以偽造其中任何一欄都只會被擋下。
    if AIValue.isConversion(self.card) then
        answer.card_spec = self.card:toCardSpec()
    elseif self.card_spec ~= nil then
        answer.card_spec = self.card_spec
    else
        local id = self.card:getEffectiveId()
        if type(id) ~= "number" then return nil end
        answer.card_id = id
        -- 實體牌也帶票：持有一張牌不等於這一題問過它。權威端沒有發票給這個候選時
        -- （candidate_id 是 -1），就不要宣稱有票——送一個不存在的票號比不送更糟。
        local candidate = self.candidate_id
        if type(candidate) == "number" and candidate >= 0 then
            answer.candidate_id = candidate
        end
    end
    if self.to and #self.to > 0 then
        local names = {}
        for index, target in ipairs(self.to) do names[index] = target:objectName() end
        answer.targets = names
    end
    return answer
end

-- 牌策略註冊表。鍵是牌名（objectName）或類別名（getClassName），值是
-- function(self, card, use)，參數順序與舊 SmartAI:useCardXXX 相同。
-- 舊寫法 function SmartAIView:useCardSlash(card, use) 仍然有效：那是同一組策略的薄入口，
-- 不是第二套演算法。查找順序固定：牌名 → 類別名 → useCard<類別名>。
ai_card_use = ai_card_use or {}

local function find_card_use(card)
    local object_name = card:objectName()
    if type(object_name) == "string" and object_name ~= ""
        and type(ai_card_use[object_name]) == "function" then
        return ai_card_use[object_name], object_name
    end
    local class_name = card:getClassName()
    if type(class_name) ~= "string" or class_name == "" then
        return nil, type(object_name) == "string" and object_name or nil
    end
    if type(ai_card_use[class_name]) == "function" then
        return ai_card_use[class_name], class_name
    end
    local legacy = sgs.ai_skill_use_func or {}
    local names = {class_name, object_name}
    if card:isKindOf("LuaSkillCard") then names = {"#" .. object_name, class_name, object_name} end
    if card:isKindOf("ActiveSkillCard") and type(card.getSkillName) == "function" then
        names = {card:getSkillName(), class_name, object_name}
    end
    for _, name in ipairs(names) do
        if type(legacy[name]) == "function" then
            return function(self, offered, use)
                local request = AILegacyRequest.new(self.request, self.room)
                return legacy[name](offered, use, self, request)
            end, name
        end
    end
    -- Family fallbacks preserve the legacy `useBasicCard`/`useTrickCard` breadth
    -- without claiming an extension-specific effect is understood.
    local family = card:isKindOf("EquipCard") and "EquipCard"
        or card:isKindOf("AOE") and "AOE"
        or card:isKindOf("GlobalEffect") and "GlobalEffect"
        or card:isKindOf("DelayedTrick") and "DelayedTrick"
        or nil
    if family and type(ai_card_use[family]) == "function" then
        return ai_card_use[family], family
    end
    local method = rawget(SmartAIView, "useCard" .. class_name)
    if type(method) == "function" then return method, class_name end
    return nil, class_name
end

-- 規劃一張牌怎麼用，不真的出牌。沒有這張牌的策略就是未覆蓋，不是「決定不出牌」：
-- 預設丟出受控訊號記錄未知；整合規劃器可繼續評估其他已授權候選。要比較多個候選、自己決定怎麼
-- 處理未覆蓋的呼叫者改用 tryUseCard，拿回 (plan, status) 自己判斷。
function SmartAIView:aiUseCard(card, use)
    if self.resolvePriorTurnPlan then card=self:resolvePriorTurnPlan(card) end
    if use == nil then return self:evaluateCard(card) end
    -- SmartAI9068 keeps an explicitly supplied dummy exactly like dummy().
    -- A lawful readonly preview can therefore use that same caller-owned plan;
    -- evaluateCard preserves its targets/options and still forbids submission.
    if type(use) == "table" and use.isDummy == true
        and (AIValue.isCard(card) or AIValue.isConversion(card))
        and type(card.isEvaluationOnly) == "function" and card:isEvaluationOnly() == true then
        return self:evaluateCard(card, use)
    end
    local plan, status = self:tryUseCard(card, use)
    if status == "unsupported" then error(plan, 0) end
    return plan
end

local function copy_strategy_state(value, depth)
    if type(value) ~= "table" then return value end
    depth = (depth or 0) + 1
    if depth > 12 then ai_unsupported("strategy effect snapshot exceeds depth", "evaluation") end
    local result = {}
    for key, item in pairs(value) do result[key] = copy_strategy_state(item, depth) end
    return result
end
function SmartAIView:evaluateCard(card, use)
    use = use or AIUsePlan.new()
    use.isDummy, use._evaluation_only = true, true
    local previous = self._strategy_evaluation
    local previousGuanxingDummy=self._original_guanxing_dummy
    local policy = self.world and self.world.mode_policy
    local flags = policy and copy_strategy_state(policy.strategy_flags)
    local effects = copy_strategy_state(self._strategy_effects)
    self._strategy_evaluation = true
    local ok, plan, status = pcall(self.tryUseCard, self, card, use, true)
    self._strategy_evaluation = previous
    self._original_guanxing_dummy=previousGuanxingDummy
    if policy then policy.strategy_flags = flags end
    self._strategy_effects = effects
    if not ok then error(plan, 0) end
    if status == "unsupported" then error(plan, 0) end
    return plan
end

-- Tianyi probes the actual Slash with a read-only native hypothetical scope.
-- The returned descriptor is evaluation-only and never becomes an action ticket.
function SmartAIView:evaluateTianyiSlash(card,use)
    if type(ai_evaluate_tianyi_slash)~="function" then
        ai_unsupported("Tianyi Slash hypothesis is not available","tianyi")
    end
    local authority=type(card.getAuthorityCard)=="function" and card:getAuthorityCard() or card
    local row=ai_evaluate_tianyi_slash(authority:getEffectiveId())
    if type(row)~="table" or type(row.card)~="table" or type(row.candidate)~="table"
        or row.card.evaluation_only~=true then
        ai_unsupported(type(row)=="table" and row.error or "invalid Tianyi Slash hypothesis","tianyi")
    end
    local projected=CardView.new(row.card)
    projected._evaluation_candidate=row.candidate
    local previous=self._evaluation_scope
    self._evaluation_scope={card=projected,candidate=CandidateView.new(row.candidate)}
    use=use or AIUsePlan.new()
    use.extra_target,use.isDummy,use._evaluation_only=1,true,true
    -- The donor calls useBasicCard directly here, not aiUseCard. In particular,
    -- no generic revise callbacks or their humanization RNG draw are inserted.
    local ok,result=pcall(self.useBasicCard,self,projected,use)
    self._evaluation_scope=previous
    if not ok then error(result,0) end
    return use
end

function SmartAIView:evaluateAcquiredCard(card)
    local projected, candidate = self:getAcquiredCardEvaluation(card)
    if not projected or not candidate then ai_unsupported("acquired-card evaluation is not projected", "evaluation") end
    local previous = self._evaluation_scope
    self._evaluation_scope = {card=projected, candidate=candidate}
    local ok, result = pcall(self.evaluateCard, self, projected)
    self._evaluation_scope = previous
    if not ok then error(result, 0) end
    return result
end

SmartAIView.aiUsecard = SmartAIView.aiUseCard

-- status：planned（提出計劃）／declined（有策略，決定不打）／unsupported（接不住）。
-- 三者分開，因為最外層對它們的處置不同：前兩者可以作答，最後一個必須保留未覆蓋原因。
-- Private counters cannot be reset by writing scratch. All nested branches share
-- one request budget; only their pure-value reservations are copied.
local planning = setmetatable({}, {__mode = "k"})
-- Dispatch starts a new decision explicitly. Replacing public scratch during a
-- decision must not replenish its private budget or change the saved context.
function SmartAIView.resetPlanning(request)
    planning[request] = nil
end

-- Shared SmartAI helper compatibility.  These helpers consume only value facades;
-- skill/card callbacks are optional pure hooks and never receive engine userdata.
-- Preserve each legacy callback ABI explicitly; never infer arguments from strings.
local function known_skill(player, skill)
    return player and core_query(player,"hasSkill",skill) or false
end
local function category(player, name)
    local names = sgs[name]
    return type(names) == "string" and core_query(player,"hasSkills",names)
end
local function mark_value(player, name)
    return core_query(player,"getMark",name)
end
local function count_cards(player)
    local hand, equips = scalar(player, "getHandcardNum"), player:getEquips()
    if hand == nil or equips == nil then return nil end
    return hand + #equips
end

function SmartAIView:getLeastHandcardNum(player)
	local least = 0
	player = player or self.player

	-- Core leastHandcard skills (before --add)
	if core_query(player,"hasSkills","lianying|noslianying|kezhuanmanjuan") then least = 1 end
	if least<1 and core_query(self,"hasSkills","shoucheng",core_query(self,"getFriends",player)) then least = 1 end
	if least<math.min(2,core_query(player,"getLostHp")) and core_query(player,"hasSkill","shangshi") then least = math.min(2,core_query(player,"getLostHp")) end
	if least<core_query(player,"getLostHp") and core_query(player,"hasSkill","nosshangshi") then least = core_query(player,"getLostHp") end

	-- Check extended getLeastHandcardNum skills through table
	for _, s in ipairs(core_query(self,"getConnections",player)) do
		local skill_func = sgs.ai_getLeastHandcardNum_skill[s]
		if type(skill_func) == "function" then
			local result = skill_func(self, player, least)
			if AIUnsupported.is(result) then error(result, 0) end
			if type(result) == "number" and result > least then
				least = result
			end
		end
	end

	return least
end

function SmartAIView:hasLoseHandcardEffective(player, count)
    player = player or self.player
    count = count or core_query(player, "getHandcardNum")
    return count > core_query(self, "getLeastHandcardNum", player)
end

function SmartAIView:strategyCardLimited(player,card,method)
    local value = value_call(player,"isCardLimited",card,method)
    if type(value)=="boolean" then return value end
    if player:objectName()==self.player:objectName() then ai_unsupported("owner card limitation is missing","getOverflow") end
    return core_query(self,"useKnowledgeEstimate",{value=false,status="estimate",viewer=self.player:objectName(),target=player:objectName(),
        basis="foreign known card has no observed MethodIgnore limit; no-limit prior"},"getOverflow")
end

function SmartAIView:getOverflow(player,isMax)
	player = player or self.player
	local m = core_query(player,"getMaxCards")
	if core_query(player,"hasSkill","qiaobian") then m = math.max(core_query(self.player,"getHandcardNum")-1,m) end
	if core_query(player,"hasSkill","keji") and not core_query(player,"hasFlag","KejiSlashInPlayPhase")
	or core_query(player,"hasSkill","zaoyao") then m = core_query(self.player,"getHandcardNum") end
	if isMax and m>0 then return m end
	if core_query(player,"getPhase")<sgs.Player_Finish and core_query(player,"hasSkill","yongsi")
	and not(core_query(player,"hasSkill","keji") and not core_query(player,"hasFlag","KejiSlashInPlayPhase"))
	and not core_query(player,"hasSkill","conghui") then
		local kingdom_num = {}
		for _,ap in sgs.qlist(core_query(self.room,"getAlivePlayers"))do
			if table.contains(kingdom_num,core_query(ap,"getKingdom")) then continue end
			table.insert(kingdom_num,core_query(ap,"getKingdom"))
		end
		kingdom_num = #kingdom_num
		if kingdom_num>0 then
			if core_query(player,"getCardCount")>kingdom_num
			then m = math.min(m,core_query(player,"getCardCount")-kingdom_num)
			else m = 0 end
		end
	end
	--add
	if core_query(player,"hasSkill","heg_keji") and core_query(player,"getMark","heg_keji-Clear") == 0 then m = core_query(self.player,"getHandcardNum") end


	if isMax then return m end
	for _,c in ipairs(value_known(getKnownCards(player,self.player),"overflow known cards"))do
		if core_query(self,"strategyCardLimited",player,c,sgs.Card_MethodIgnore)
		then m = m+1 end
	end
	return core_query(player,"getHandcardNum")-m
end

function SmartAIView:hasManjuanEffect(player, manjuan_only)
    player = player or self.player
    local phase = player:getPhase()
    if phase == nil or sgs.Player_NotActive == nil then return nil end
    local manjuan = core_query(player,"hasSkill","manjuan")
    if manjuan == nil then return nil end
    if manjuan and phase == sgs.Player_NotActive then return true end
    if manjuan_only then return false end
    local zishu = core_query(player,"hasSkill","zishu")
    if zishu == nil then return nil end
    return zishu and phase == sgs.Player_NotActive
end

function SmartAIView:beifaSlashUseOpportunity(player)
    if player:objectName()==self.player:objectName() then
        return self:evaluateCard(core_query(self,"getEvaluationCard","slash")).card ~= nil
    end
    -- The donor asks another AI to use a free hypothetical Slash. Only the
    -- viewer's enemy model crosses this boundary; concealed costs/intentions do not.
    local targets = core_query(self,"getEnemies",player)
    return core_query(self,"useKnowledgeEstimate",{value=#targets>0,status="estimate",viewer=self.player:objectName(),target=player:objectName(),
        basis="beifa foreign AI dummy Slash plan replaced by viewer enemy-opportunity prior"},"needKongcheng.beifa")
end

local function r32_beifa_opportunity(self, player)
    if player:objectName() == self.player:objectName() then
        return core_query(self, "aiUseCard", core_query(self, "cloneEvaluationCard", "slash")).card
    end
    return core_query(self, "beifaSlashUseOpportunity", player)
end

function SmartAIView:needKongcheng(player,keep)
	player = player or self.player
	if keep then
		return core_query(player,"getHandcardNum")<1
		and (core_query(player,"hasSkill","kongcheng") or core_query(player,"hasSkill","zhiji") and core_query(player,"getMark","zhiji")<1
		or core_query(player,"hasSkill","mobilezhiji") and core_query(player,"getMark","mobilezhiji")<1 or core_query(player,"hasSkill","olzhiji") and core_query(player,"getMark","olzhiji")<1)
	end
	if not (player:objectName()==self.player:objectName() and self._mountain_xiangle_guard == true
        or core_query(player,"hasFlag","stack_overflow_xiangle"))
	and core_query(player,"getHandcardNum")>0 and core_query(player,"hasSkill","beifa")
	and r32_beifa_opportunity(self,player)
	then return true end
	if core_query(player,"getHandcardNum")>0 and not core_query(self,"hasLoseHandcardEffective",player) then return true end
	if core_query(player,"getMark","zhiji")<1 and core_query(player,"hasSkill","zhiji") then return true end
	if core_query(player,"getMark","mobilezhiji")<1 and core_query(player,"hasSkill","mobilezhiji") then return true end
	if core_query(player,"getMark","olzhiji")<1 and core_query(player,"hasSkill","olzhiji") then return true end
	if core_query(player,"getPhase")==sgs.Player_Play and core_query(player,"hasSkill","shude") then return true end
	--add
	if core_query(player,"hasSkill","LuaJuejing") and core_query(player,"getMark","LuaJuejing") < 1 then return true end
	if core_query(player,"hasSkill","meizlsecanhui") and core_query(player,"getMark","@meizlsejidu") > 0 then return true end
	if core_query(player,"hasSkill","meizlsebaonu") and core_query(player,"getMark","@meizlsebaonu") == 0 then return true end
	if core_query(player,"hasSkill","y_kongzhen") then return true end
	if core_query(player,"hasSkill","kezhuanmanjuan") then return true end
	if core_query(player,"hasSkill","sr_ruya") and core_query(player,"getPhase") == sgs.Player_Play then return true end
	if core_query(player,"hasSkill","kezhiji") and core_query(player,"getMark","kezhiji") == 0 and core_query(player,"getHandcardNum")<=1 then return true end
	if core_query(player,"hasSkill","s_w_longnu") and core_query(player,"getMark","s_w_longnu") == 0 and core_query(player,"getHandcardNum")<=1 then return true end
	if core_query(player,"hasSkill","s3_xiaohu") and core_query(player,"getMark","s3_xiaohu") == 0 and core_query(player,"getHandcardNum")<=1 then return true end

	return core_query(player,"hasSkills",sgs.need_kongcheng)
end

-- Keep the donor table construction and pairs precedence when skills coexist.
local function core_best_hp(owner)
    local max_hp = scalar(owner, "getMaxHp")
    if max_hp == nil or not owner:getSkills() then return nil end
    if known_skill(owner, "longhun") then
        local count = count_cards(owner)
        if count == nil then return nil end
        if count > 2 then return 1 end
    end
    if known_skill(owner, "hunzi") and mark_value(owner, "hunzi") < 1 then return 2 end
    for name, delta in pairs({ganlu=1,yinghun=2,nosmiji=1,xueji=1,baobian=math.max(0,max_hp-3)}) do
        if known_skill(owner, name) then
            local lord
            if type(owner.isLord) == "function" then lord = owner:isLord() end
            if type(lord) ~= "boolean" then
                local role = type(owner.getRole) == "function" and owner:getRole() or nil
                if role == nil then return nil end
                lord = role == "lord"
            end
            return math.max(lord and 3 or 2, max_hp - delta)
        end
    end
    if core_query(owner,"hasSkills","renjie+baiyin") and mark_value(owner, "baiyin") < 1
        or core_query(owner,"hasSkills","quanji+zili") and mark_value(owner, "zili") < 1 then
        return max_hp - 1
    end
    return max_hp, true
end

function getBestHp(owner)
    if not owner then return nil end
    local room = rawget(owner,"_room")
    if room and room._ai then return room._ai:getBestHp(owner) end
    local value, extended = core_best_hp(owner)
    if not extended then return value end
    local registry, seen = sgs.ai_getBestHp_skill or {}, {}
    for _, skill in ipairs(owner:getSkills()) do
        local name = skill:objectName()
        if not seen[name] and not skill:isInvalid() then
            seen[name] = true
            if type(registry[name]) == "function" then
                local result = registry[name](owner)
                if finite_number(result) then return result end
            end
        end
    end
    return value
end
function SmartAIView:getBestHp(player)
    player = player or self.player
    local value, extended = core_best_hp(player)
    if not extended then return value end
    for _, name in ipairs(core_query(self,"getConnections",player)) do
        local callback = (sgs.ai_getBestHp_skill or {})[name]
        if type(callback)=="function" then
            local result = callback(player)
            if result then return result end
        end
    end
    return value
end

-- Mandatory damage inputs stay distinct from explicitly marked viewer estimates.
local function damage_known(value, label)
    if AIUnsupported.is(value) then error(value,0) end
    if value == nil then ai_unsupported("damage projection is unknown: " .. label, "ajustDamage") end
    return value
end

local function damage_call(object, method, ...)
    local getter = object and object[method]
    if type(getter) ~= "function" then
        ai_unsupported("damage getter is unavailable: " .. method, "ajustDamage")
    end
    -- Mark/flag priors and the legacy collection hasSkills overload belong to
    -- value_call. Ordinary getters have already been resolved and validated:
    -- invoking that same function avoids two redundant facade lookups without
    -- caching its result or changing any strategy/helper call.
    if method == "getMark" or method == "hasFlag" or method == "hasSkills" then
        return damage_known(value_call(object,method,...), method)
    end
    local result=getter(object,...)
    if AIUnsupported.is(result) then error(result,0) end
    if result==nil and type(SmartAIView.isKnownNilStrategyResult)=="function"
        and SmartAIView.isKnownNilStrategyResult(object,method,getter) then return nil end
    return damage_known(result,method)
end

local function damage_special_mark(self, prefix, player)
    local count = 0
    for _, name in ipairs(damage_call(player, "getMarkNames")) do
        if name:sub(1,#prefix) == prefix and damage_call(player, "getMark", name) > 0 then count = count + 1 end
    end
    if player._view and player._view.marks_complete ~= true then
        return damage_call(self,"useKnowledgeEstimate",{value=count,status="estimate",
            basis="visible mark-prefix count excludes unobserved private marks",observer=self.player:objectName()},"damage special mark count")
    end
    return count
end
local function damage_jiaozi(self, player)
    if not damage_call(player, "hasSkill", "jiaozi") then return false end
    for _, sibling in sgs.qlist(damage_call(player,"getAliveSiblings")) do
        if damage_call(sibling, "getHandcardNum") >= damage_call(player, "getHandcardNum") then return false end
    end
    return true
end
local function damage_role(self, player)
    local role = value_call(player, "getRole")
    if type(role) == "string" and role ~= "" then return role end
    role = value_call(self, "getRoleEstimate", player)
    if type(role) ~= "string" or role == "" then role = "neutral" end
    return damage_call(self, "useKnowledgeEstimate", {value=role,status="estimate",basis="viewer inferred role replaces hidden role in damage policy",observer=self.player:objectName()}, "damage role")
end
local function damage_be_friend(self, to, from)
    if not(from and to) then return false end
    if from:objectName()==to:objectName() then return true end
    -- Preserve repeated source role reads; each foreign read retains its own
    -- approved viewer inference provenance rather than caching hidden truth.
    if damage_role(self,from)=="lord" or damage_role(self,from)=="loyalist" then
        if damage_call(self.room,"getTurnCount")<=1 and damage_role(self,to)=="renegade" and damage_call(from,"aliveCount")>7
            or damage_role(self,to)=="lord" or damage_role(self,to)=="loyalist" then return true end
    end
    if damage_role(self,from)=="rebel" and damage_role(self,to)=="rebel" then return true end
    if damage_role(self,from)=="renegade" then
        if damage_call(self.room,"getTurnCount")<=1 and damage_role(self,to)=="loyalist" and damage_call(from,"aliveCount")>7
            or damage_role(self,to)=="lord" and damage_call(from,"aliveCount")>2 then return true end
    end
    return false
end

local function damage_card_value(self, card, key, prior)
    local row = self:getDamageCardState(card)
    if row and row[key] ~= nil then return row[key] end
    return damage_call(self,"useKnowledgeEstimate",{value=prior,status="estimate",basis="no observed "..key.." on this card; inactive modifier prior",observer=self.player:objectName()},"damage card "..key)
end
local function damage_card_flag(self, card, flag)
    local scratch = self.request and self.request.scratch
    local key
    if AIValue.isConversion(card) then key="conversion:"..damage_call(card,"getConversionId")
    else
        local id=damage_call(card,"getEffectiveId")
        key=id<0 and "evaluation:"..id..":"..damage_call(card,"objectName") or "card:"..id
    end
    local flags = scratch and scratch.card_flags and scratch.card_flags[key]
    if flags and type(flags[flag]) == "boolean" then return flags[flag] end
    local row = self:getDamageCardState(card)
    if row and type(row.flags) == "table" then
        for _, name in ipairs(row.flags) do if name == flag then return true end end
        return false
    end
    local known = card:hasFlag(flag)
    if known == true then return true end
    local view = type(card) == "table" and rawget(card,"_view")
    -- Native owner descriptors explicitly cover these non-visibility flags.
    -- A missing/partial public descriptor still follows the existing prior.
    if known == false and type(view) == "table" and (view.flags_complete == true
        or type(view.known_flags) == "table" and view.known_flags[flag] == false) then return false end
    return damage_call(self,"useKnowledgeEstimate",{value=false,status="estimate",basis="no publicly observed "..flag.." card modifier",observer=self.player:objectName()},"damage card flag")
end
sgs.ai_ajustdamage_to = sgs.ai_ajustdamage_to or {}
sgs.ai_ajustdamage_from = sgs.ai_ajustdamage_from or {}
-- Fixed b6025acc damage registry bodies. Their mark/flag observations use the
-- same exact-owner / explicitly recorded viewer estimates as ajustDamage.
-- mobile-ai.lua:2038: do not replace the drank tag magnitude with a constant.
sgs.ai_ajustdamage_to.mobilemoujinjiu = function(self,from,to,card,nature)
    if card and card:isKindOf("Slash") and damage_card_flag(self,card,"drank") then
        return -damage_card_value(self,card,"drank_amount",0)
    end
end
-- olddiy-ai.lua:722: preserve the dynamic source-name key and actual magnitude.
sgs.ai_ajustdamage_from.bu_s2_benxi = function(self,from,to,card,nature)
    return damage_call(to,"getMark","&bu_s2_benxi+#"..from:objectName().."-Clear")
end
-- scarlet-ai.lua:3458: only Slash; the owner/observed flag retains precedence.
sgs.ai_ajustdamage_from.s4_s_jianta = function(self,from,to,card,nature)
    if card and card:isKindOf("Slash") and damage_call(from,"hasFlag","s4_s_jianta") then return 1 end
end
-- sijyu-ai.lua:414: keep the source skill-chain predicate before from/mark.
sgs.ai_ajustdamage_from.sijyu_zhuluan = function(self,from,to,card,nature)
    if card and table.contains(self:cardSkillNamesKnowledge(card,"sijyu_zhuluan.skill_names"),"sijyu_zhuluan")
        and from and damage_call(from,"getMark","zhuluandamage_lun")==0 then return 1 end
end
-- srkill-ai.lua:2820: damageincreased short-circuits before srganglieinvoked.
sgs.ai_ajustdamage_from.sr_ganglie = function(self,from,to,card,nature)
    if from and not damage_call(from,"hasFlag","damageincreased")
        and damage_call(from,"hasFlag","srganglieinvoked") then return 1 end
end

function SmartAIView:cantDamageMore(from,to)
    from,to = from or self.room:getCurrent() or self.player,to or self.player
    if not damage_call(self,"hasJueqingEffect",from,to) then
        if damage_call(to,"hasArmorEffect","SilverLion") and not damage_call(self,"ignoreArmor",from,to)
            or damage_call(to,"hasSkill","gongqing") and damage_call(from,"getAttackRange") < 3
            or damage_call(self,"hasOrangeEffect",to) then return true end
        local protector = self.room:findPlayerBySkillName("jgchiying")
        if protector then
            local source, target = damage_role(self,protector), damage_role(self,to)
            if source == target then return true end
        end
        if damage_special_mark(self,"&tiansuan4",to) + damage_special_mark(self,"&tiansuan5",to) < 1
            and (damage_special_mark(self,"&tiansuan2",to) > 0 or damage_special_mark(self,"&tiansuan3",to) > 0) then return true end
        if damage_call(to,"hasSkill","keyaoliandu") or damage_call(to,"hasSkill","kejieyaoliandu") then return true end
        if damage_call(to,"getMark","@silver_lion") > 0 and not damage_call(self,"ignoreArmor",from,to) then return true end
        if damage_call(to,"hasSkill","s2_gangzhi") or damage_call(to,"hasSkill","s4_s_gedang") then return true end
    end
    return false
end

function SmartAIView:ajustDamage(from,to,dmg,card,nature,depth)
	depth = depth or 0
	from = from or self.room:getCurrent() or self.player
	to = to or self.player
	dmg = dmg or 1
	if damage_call(self, "hasJueqingEffect", from,to) then return -dmg end
	if damage_call(self, "cantDamageMore", from,to) then return 1 end
	if damage_special_mark(self,"&tiansuan1",to)>0 then return 0 end
	if type(nature)~="string" then
		if type(nature)~="number" then
			nature = card and sgs.card_damage_nature[damage_call(card, "getClassName")] or sgs.DamageStruct_Normal
		end
		local na = {
			[sgs.DamageStruct_Normal]="N",
			[sgs.DamageStruct_Fire]="F",
			[sgs.DamageStruct_Thunder]="T",
			[sgs.DamageStruct_Ice]="I",
			[sgs.DamageStruct_Poison]="P",
			[sgs.DamageStruct_God]="G",
		}
		nature = na[nature] or "N"
	end
	if nature=="F" or damage_call(self, "hasWulingEffect", "@fire") then
		if damage_call(self, "hasWulingEffect", "@wind") then dmg = dmg+1 end
		if damage_call(self, "hasWulingEffect", "@earth") and not damage_call(to, "hasSkill", "ranshang") then return 1 end
		nature = "F"
	end

	--add
	if damage_call(from, "hasSkill", "Zhena") then
		if from:getWeapon() and not damage_be_friend(self,to,from) then
			if not damage_call(self, "cantDamageMore", from, to) and
				((damage_call(self, "isWeak", from) or damage_call(from, "getHp") == 1) or
					(damage_call(from, "getHp") <= damage_call(to, "getHp") and damage_call(self, "getCardsNum", "Peach") > 0) or damage_call(to, "isLord")) then
				nature = "F"
				dmg = damage_call(to, "getHp")
			end
		end
	end
	if damage_call(from, "hasSkill", "keyaoleimu") then
		nature = "T"
	end
	if damage_call(from, "hasSkill", "TH_SubterraneanSun") then
		nature = "F"
	end
	if damage_call(to, "getMark", "&undershouli-Clear")>0 then
		dmg = dmg+damage_call(to, "getMark", "&undershouli-Clear")
		nature = "T"
	end
	if damage_call(to, "getMark", "&tyshouli-Clear")>0 then
		dmg = dmg+damage_call(to, "getMark", "&tyshouli-Clear")
		nature = "T"
	end

	if damage_call(to, "getMark", "&shouli_debuff-Clear")>0 then
		dmg = dmg+damage_call(to, "getMark", "&shouli_debuff-Clear")
		nature = "T"
	end
	if damage_call(to, "getMark", "&f_jishen+jsweapon-SelfClear")>0 and card and not damage_call(card, "isVirtualCard") then
		dmg = dmg * 2
	end
	if card and table.contains(damage_call(self, "cardSkillNamesKnowledge", card, "ajustDamage.skill_names"), "s4_s_yuanshe") then
		nature = "T"
	end
	local sj = damage_call(self.room, "getGuanduEvent")
	if sj == "gd_huoshaowuchao" and nature == "N" then
		nature = "F"
	end

	self.to = to
	self.from = from
	self.card = card
	self.nature = nature
	for _,s in ipairs(damage_call(self, "getConnections", from))do
		local ad = sgs.ai_ajustdamage_from[s]
		if type(ad)=="function" then
			ad = ad(self,from,to,card,nature)
            if AIUnsupported.is(ad) then error(ad,0) end
			if type(ad)=="number" then dmg = dmg+ad end
		end
	end
	if nature=="T" then
		if damage_call(self, "hasWulingEffect", "@earth") then return 1 end
		if damage_call(self, "hasWulingEffect", "@thunder") then dmg = dmg+1 end
	end
	if damage_jiaozi(self,from) then dmg = dmg+1 end
	if damage_jiaozi(self,to) then dmg = dmg+1 end
	if card then
		if damage_call(card, "isKindOf", "Duel") then
			if damage_call(from, "hasFlag", "luoyi") then dmg = dmg+1 end
			if damage_call(from, "hasFlag", "neoluoyi") then dmg = dmg+1 end
			if damage_call(from, "hasFlag", "heg_luoyi") then dmg = dmg+1 end
		elseif damage_call(card, "isKindOf", "Slash") then
			if damage_card_flag(self,card,"drank") then dmg = dmg+math.max(1,damage_card_value(self,card,"drank_amount",0)) end
			if damage_call(from, "hasFlag", "nosluoyi") then dmg = dmg+1 end
			if damage_call(from, "hasFlag", "neoluoyi") then dmg = dmg+1 end
			if damage_call(from, "hasFlag", "heg_luoyi") then dmg = dmg+1 end
			if damage_call(self.room, "getKeqiyanhuoCount")>0 then dmg = dmg+1 end
			dmg = dmg+damage_call(from, "getMark", "&olpaoxiao_missed-Clear")+damage_call(to, "getMark", "&yise")
			if damage_card_flag(self,card,"yj_nvzhuang_debuff") then dmg = dmg+1 end
			local guanyu = self.room:findPlayerBySkillName("zhongyi")
			if guanyu and damage_call(guanyu, "getPile", "loyal"):length()>0 and damage_call(self, "isFriend", guanyu,from) then dmg = dmg+1 end
		elseif damage_call(card, "isKindOf", "AOE") and damage_card_flag(self,card,"hanyong") then dmg = dmg+1 end
		if damage_card_flag(self,card,"yb_canqu1_add_damage") then dmg = dmg+1 end
		if damage_card_flag(self,card,"cuijinAddDamage_1") then dmg = dmg+1 end
		if damage_card_flag(self,card,"cuijinAddDamage_2") then dmg = dmg+2 end
	end
	dmg = dmg+damage_special_mark(self,"&tiansuan4",to)+damage_special_mark(self,"&tiansuan5",to)

	--add
	if damage_call(from, "hasSkill", "se_yezhan") and dmg >= damage_call(to, "getHp") then
		dmg = dmg + 1
	end
	if damage_call(from, "hasSkill", "feitouhuo") and nature ~= "N" then
		nature = "F"
	end
	if damage_call(from, "hasSkill", "sy_wushuang") and card and math.fmod(damage_call(card, "getNumber"), 2) ~= 0 then
		dmg = 3
	end
	if card and damage_card_value(self,card,"midao_nature","") ~= "" then
		local newnature = damage_card_value(self,card,"midao_nature","")
        local facts=self.world and self.world.strategy_facts
        local captured=facts and facts.legacy_midao_na
        if type(captured)~="table" or captured.known~=true or captured.known_nil~=true then
            ai_unsupported("fixed-source Midao global na nil is not authenticated","ajustDamage.midao")
        end
        -- Fixed smart-ai.lua8312 reads GLOBAL na: the local nature table ended
        -- at 8201. Preserve its reached ordinary nil-index error (after the two
        -- card-tag reads), rather than repairing the donor's strategy.
        local legacy_na=nil
        nature=legacy_na[newnature] or "N"
	end

	for _,s in ipairs(damage_call(self, "getConnections", to))do
		local ad = sgs.ai_ajustdamage_to[s]
		if type(ad)=="function" then
			ad = ad(self,from,to,card,nature)
            if AIUnsupported.is(ad) then error(ad,0) end
			if type(ad)=="number" then dmg = dmg+ad end
		end
	end

	--add
	if damage_call(to, "getMark", "&kechengyechou")>0
		and dmg >= damage_call(to, "getHp") then
		dmg = dmg*2*damage_call(to, "getMark", "&kechengyechou")
	end
	if damage_call(to, "hasSkill", "keyaoliandu") and dmg > 1 then
		dmg = 1
	end
	if damage_call(to, "hasSkill", "kejieyaoliandu") and dmg > 1 then
		dmg = 1
	end
	if damage_call(to, "hasSkill", "Sixu") and dmg == 1 and not damage_call(to, "faceUp") then
		dmg = 0
	end
	if damage_call(from, "hasSkill", "nirendao") and card and damage_call(card, "isKindOf", "Slash") and dmg >= damage_call(to, "getHp") then
		dmg = 0
	end
	if damage_call(to, "hasSkill", "DSTP") and dmg > 1 then
		dmg = 1
	end

	if damage_call(to, "getMark", "@inu_to") and dmg > 1 then
		dmg = dmg - 1
	end
	if damage_call(to, "hasSkill", "luaRkuangyan") and nature == "N" and dmg == 1 then
		dmg = 0
	end
	if damage_call(to, "hasSkill", "luaRkuangyan") and dmg > 1 then
		dmg = dmg + 1
	end
	if damage_call(to, "hasSkill", "ark_kewang") and dmg > 1 then
		dmg = 0
	end
	if damage_call(to, "hasSkill", "sk_kuangyan") and nature == "N" and dmg == 1 then
		dmg = 0
	end
	if damage_call(to, "hasSkill", "sk_kuangyan") and dmg >= 2 then
		dmg = dmg + 1
	end
	if damage_call(to, "hasSkill", "Djianxiong") and dmg > 1 then
		local names = damage_call(to,"getDjianxiongRecord")
        -- A nil card here is an ordinary donor dereference error, not missing
        -- projection. Non-nil cards still require an exact printed identity.
        local name = card and damage_call(card,"objectName") or card:objectName()
		if damage_call(card, "isKindOf", "Slash") then name = "DjianxiongSlash" end
		if table.contains(names, name) then
			dmg = 1
		end
	end
	if damage_call(to, "hasSkill", "zhouchu") and dmg > 1 then
		dmg = dmg - 1
	end
	if damage_call(to, "hasSkill", "optimistic") and dmg > 1 and damage_call(to, "getMark", "@SuperLimitBreak") > 0 then
		dmg = 0
	end
	if sj == "gd_huoshaowuchao" then
		if from and to and damage_call(to, "getHp") > damage_call(from, "getHp") then
			dmg = dmg + 1
		end
	end
	if sj=="gd_liangjunxiangchi" then
		if card and damage_call(card, "isKindOf", "Slash") and damage_card_flag(self,card,"gd_liangjunxiangchi") then
			dmg = dmg + 1
		end
	end
	if damage_call(to, "hasSkill", "cheerful") and dmg > 1 then
		dmg = 1
	end
	if damage_call(to, "getMark", "&f_jishen+jsarmor-SelfClear") > 0 and dmg > 1 and card and not damage_call(card, "isVirtualCard") then
		dmg = dmg / 2
	end

	-- 核心修改：處理鐵索傳導感知、深度控制與 KillLord 判斷
    -- 僅在 depth == 0 時計算傳導，避免無限遞迴
    if depth == 0 and nature ~= "N" and damage_call(to, "isChained") then
        local friends_hurt = 0
        local enemies_hurt = 0
        local lord = self:getSourceLord(from)

        for _, p in sgs.qlist(damage_call(self.room, "getOtherPlayers", to)) do
            if damage_call(p, "isChained") then
                -- 這裡不能再調用 damageIsEffective，否則會重新進入 ajustDamage(depth=0) 造成遞迴爆棧
                local p_dmg = damage_call(self, "ajustDamage", from, p, dmg, card, nature, 1)
                if p_dmg > 0 then
                    if damage_call(self, "isFriend", p, from) then
                        friends_hurt = friends_hurt + p_dmg
                        local hp_left = damage_call(p, "getHp") + damage_call(p, "getHujia")
                        if p_dmg >= hp_left then
                            if lord and damage_call(p, "objectName") == damage_call(lord, "objectName") then
                                return -100
                            end
                            friends_hurt = friends_hurt + 10
                        end
                    elseif damage_call(self, "isEnemy", p, from) then
                        enemies_hurt = enemies_hurt + p_dmg
                        if p_dmg >= (damage_call(p, "getHp") + damage_call(p, "getHujia")) then
                            enemies_hurt = enemies_hurt + 2
                        end
                    end
                end
            end
        end

        dmg = dmg + (enemies_hurt * 1.2) - (friends_hurt * 2.5)
    end

	return dmg<-10 and 0 or dmg
end


function SmartAIView:damageIsEffective(to, card_nature, from)
    local struct={}
    struct.to=to or self.player
    struct.from=from or self.room:getCurrent() or self.player
    if AIValue.isCard(card_nature) or AIValue.isConversion(card_nature) then struct.card=card_nature
    else struct.nature=card_nature end
    local result=self:damageStruct(struct)
    if AIUnsupported.is(result) then error(result,0) end
    return result
end

function SmartAIView:canDamage(to, from, card)
    from, to = from or self.room:getCurrent() or self.player, to or self.player
    if not damage_call(self, "damageIsEffective", to, card, from) then return false end
    if damage_call(self, "isEnemy", to) then
        return not (damage_call(self,"needToLoseHp",to,from,card,true)
            or damage_known(self:isFriend(from), "damage source relation") and damage_known(self:cantbeHurt(to, from), "damage retaliation"))
    end
    return true
end

function SmartAIView:canLoseHp(from, card, to)
    from = from or self.room:getCurrent() or self.player
    to = to or self.player
    local damage = damage_call(self, "ajustDamage", from, to, 1, card)
    if damage < 0 then return end
    if not damage_call(self, "isFriend", to, from) then
        if damage_call(from, "getMark", "jinyimie-Clear") < 1
            and damage_call(from, "hasSkill", "jinyimie") then return end
        if damage_call(from, "getHp") <= damage_call(to, "getHp")
            and damage_call(from, "getHandcardNum") > 0
            and damage_call(from, "hasSkill", "jieyuan") then return end
        if damage_call(self, "isWeak", to) then
            if damage_call(from, "getMark", "@flyuqing") > 0
                and damage_call(from, "hasSkill", "zhenyi") then return end
            if damage_call(from, "hasSkill", "pojun") then return end
        end
        if damage_call(from, "getMark", "jiedao-Clear") > 0
            and damage_call(from, "getLostHp") >= damage_call(to, "getHp")
            and damage_call(from, "hasSkill", "jiedao") then return end
        if #damage_call(to, "getJudgingArea") < 1
            and damage_call(from, "hasSkill", "shanzhuan") then return end
        -- Source reads this property before testing skill ownership. Preserve
        -- that position: owner state is exact; foreign private acquisitions
        -- retain the explicit readiness prior, never an unmarked empty list.
        local duorui_ready
        if from:objectName() == self.player:objectName() then
            local facts = self.world and self.world.strategy_facts
            local names = damage_known(facts and facts.owner_duorui_skills, "owner duorui acquisition state")
            if not AIValue.isList(names) then ai_unsupported("invalid owner duorui acquisition state", "canLoseHp") end
            duorui_ready = #names < 1
        else
            duorui_ready = damage_call(self, "useKnowledgeEstimate", {
                value=true, status="estimate", viewer=self.player:objectName(), target=from:objectName(),
                basis="foreign_duorui_readiness_assumed_from_public_skill_private_acquisitions_excluded"
            }, "canLoseHp.duorui")
        end
        if duorui_ready and damage_call(from, "hasSkill", "duorui") then return end
        if damage_call(from, "hasSkill", "nosdanshou") then return end
        if damage_call(from, "hasSkill", "chuanxin") then return end
        if damage_call(from, "distanceTo", to) == 1 then
            if card and damage_call(card, "isKindOf", "Slash")
                and damage_call(from, "hasSkill", "nosqianxi") then return end
            if damage_call(from, "hasSkill", "kuanggu") then return end
        end
        if damage_call(from, "getMark", "fcj_yimie-Clear") < 1
            and damage_call(from, "hasSkill", "fcj_yimie") then return end
    end
    if damage_call(self, "isWeak", to) then
        if damage_call(to, "getMark", "@brutal") > 0
            and damage_call(from, "hasSkill", "xionghuo") then return end
        if damage_call(from, "hasSkill", "zhuixi")
            and (damage_call(from, "faceUp") and not damage_call(to, "faceUp")
                or damage_call(to, "faceUp") and not damage_call(from, "faceUp")) then return end
    end
    if damage >= damage_call(to, "getHp") then return end
    if card and damage_call(card, "isKindOf", "Slash")
        and damage_call(from, "getMark", "&kannan") >= damage_call(to, "getHp") then return end
    if damage_call(from, "hasSkill", "jiaozi")
        and damage_call(from, "getHandcardNum") > damage_call(to, "getHandcardNum") then return end
    if damage_call(from, "getPhase") ~= damage_known(sgs.Player_NotActive, "NotActive phase")
        and damage_call(from, "hasSkill", "ov_equan") then return end
    return true
end

function SmartAIView:needToLoseHp(to,from,card,passive,recover)
	from = from or self.room:getCurrent() or self.player
	to = to or self.player
	--add
	if damage_call(from,"hasSkill","ckhuansha") then
		return
	end
	if damage_call(from,"hasSkill","wugshashou") then
		return
	end
	if damage_call(from,"hasSkill","se_origin") and damage_call(from,"getMark","@origin_bullet") > 0 and card and damage_call(card,"isKindOf","Slash") then
		return
	end
	if damage_call(from,"hasSkill","LuaBimie") and card and damage_call(card,"isKindOf","Slash") then
		return
	end
	if damage_call(from,"hasSkill","fatebimie") and card and damage_call(card,"isKindOf","Slash") then
		return
	end
	if damage_call(from,"hasSkill","se_kuangquan") and card and damage_call(card,"isKindOf","Slash") and damage_call(from,"distanceTo",to)==1 then
		return
	end
	if damage_call(from,"hasSkill","qingyue") and card and damage_call(card,"isKindOf","Slash") and damage_call(to,"isMale") then
		return
	end
	if damage_call(from,"hasSkill","sinzhisi") and card and damage_call(card,"isKindOf","Slash") and damage_call(to,"getMark","@sharengui") > 0 then
		return
	end
	if damage_call(from,"hasSkill","meizlhuhun") and card and damage_call(card,"isKindOf","Slash") and table.contains(damage_call(self,"cardSkillNamesKnowledge",card,"needToLoseHp.skill_names"), "meizlhuhun") then
		return
	end
	if damage_call(from,"hasSkill","meizlxueshang") and damage_call(from,"getPhase") == sgs.Player_Play and damage_call(to,"getHp") <= 2 then
		return
	end
	if damage_call(from,"hasWeapon","tywz")  and card and damage_call(card,"isKindOf","Slash") and damage_call(to,"getMark","@hurt") >= damage_call(to,"getHp") then
		return
	end
	if damage_call(from,"hasWeapon","hqiangwei")  and card and damage_call(card,"isKindOf","Slash") and damage_call(to,"getMark","@hurt") >= damage_call(to,"getHp") then
		return
	end
	if damage_call(to,"getMark","@TH_terriblesouvenir") > 0 then
		return
	end
	if damage_call(from,"hasSkill","TH_aoyi_sanbubisha") and card and damage_call(card,"isKindOf","Slash") then
		return
	end
	if damage_call(from,"hasSkill","spmengyan") and damage_call(from,"hasSkill","spwuhun") then
		return
	end
	if damage_call(to,"hasSkill","sk_shiyong") and card and damage_call(card,"isKindOf","Slash") and damage_call(card,"isRed") then
		return
	end
	if damage_call(from,"hasSkill","nyarz_ninge") then
		return
	end
	if damage_call(from,"hasSkill","nyarz_ninge") and damage_call(self,"ajustDamage",from,to,1,card)==1 then
		return
	end
	if damage_call(from,"hasSkill","bu_s2_jiashe") and damage_call(self,"ajustDamage",from,to,1,card)>damage_call(to,"getHp") then
		return
	end
	if damage_call(from,"hasSkill","lxtx_zhuiji") then
		return
	end

	if damage_call(from,"hasSkill","s3_luofeng") and damage_call(self,"ajustDamage",from,to,1,card)>=damage_call(to,"getHp") and card and damage_call(card,"isKindOf","Slash") then
		return
	end



	for _,enemy in ipairs(damage_call(self,"getEnemies",to))do
		if damage_call(enemy,"hasSkill","jieffan") and damage_known(getKnownCard(enemy, to, "TrickCard"), "known enemy tricks") > 0 and damage_call(to,"getHp") == 1 then
			return
		end
	end

	local nature = card and sgs.card_damage_nature[damage_call(card,"getClassName")]
	local n = damage_call(self,"ajustDamage",from,to,1,card,nature)
	if damage_call(self,"hasJueqingEffect",from,to) or n<0 then
		if damage_call(to,"hasSkills",sgs.masochism_skill)
		then return end
	else
		if card and damage_call(card,"isKindOf","Slash") then
			if n>1 or damage_call(to,"hasSkill","sizhan")
			or damage_call(from,"hasWeapon","IceSword") and damage_call(to,"getCardCount")>1 and not damage_call(self,"isFriend",from,to)
			or damage_call(from,"hasSkill","nosqianxi") and damage_call(from,"distanceTo",to)==1 and not damage_call(self,"isFriend",from,to)
			then return end
		end
		if damage_call(to,"hasLordSkill","shichou") then
			local result=sgs.ai_need_damaged.shichou(self,from,to)
            if AIUnsupported.is(result) then error(result,0) end
            return result==1
		end
		-- if damage_call(to,"getMark","dev_110_first_time")<1
		-- and damage_call(to,"getPhase")==sgs.Player_NotActive and damage_call(from,"faceUp")
		-- and damage_call(self,"isWeak",from) and damage_call(to,"hasSkill","dev_110")
		-- then return true end--据守、放逐什么的再说吧
		if damage_call(self,"isGoodHp",to) then
			for _,as in ipairs(damage_call(self,"getConnections",to))do
				local nd = sgs.ai_need_damaged[as]
				if type(nd)=="function" then
                    local benefit=nd(self,from,to,card)
                    if AIUnsupported.is(benefit) then error(benefit,0) end
                    if benefit then return not sgs.ai_humanized or math.random()<0.95 end
                end
			end
		end
	end

	--add
	if damage_call(self,"isFriend",to, from) and damage_call(self,"dontHurt",to, from) then return end
	if damage_call(self,"isFriend",to, from) and damage_call(to,"hasSkill","LuaGaokang") and damage_call(to,"canDiscard",to, "he")
	then
		if card and sgs.card_damage_nature[damage_call(card,"getClassName")] == sgs.DamageStruct_Normal then
			return
		end
	end
	if damage_call(self,"isFriend",to, from) and damage_call(to,"hasSkill","guandu_cangchu") then
		if card and sgs.card_damage_nature[damage_call(card,"getClassName")] == sgs.DamageStruct_Fire then
			return
		end
	end
	if damage_call(self,"isFriend",to, from) and damage_call(from,"hasSkill","sp_guoguanzhanjiang") and damage_call(to,"getMark","&LeVeL") > 0
	then
		return true
	end
	if damage_call(to,"hasSkill","pifeng") and ((card and sgs.card_damage_nature[damage_call(card,"getClassName")] ~= sgs.DamageStruct_Normal) or (card and damage_call(card,"isRed") and damage_call(card,"objectName"):endsWith("shoot"))) and damage_call(to,"getMark","pifeng") < 3  then
		return
	end
	if damage_call(to,"hasSkill","sfofl_shaomou") and not damage_call(to,"isNude") and not damage_call(to,"getPile","sfofl_cangchu_liang"):isEmpty() and damage_call(self,"isFriend",to, from) then
		return
	end
	if damage_call(self,"isFriend",to, from) and damage_call(from,"hasSkill","f_jianyuan") and damage_call(to,"isMale")	then
		local JianYuanLu = damage_call(from,"getJianyuanRecord")
		if not table.contains(JianYuanLu, damage_call(to,"objectName")) then
			return true
		end
	end
	if damage_call(self,"isFriend",to, from) and damage_call(to,"hasSkill","f_jianyuan") and damage_call(from,"isMale")	then
		local JianYuanLu = damage_call(to,"getJianyuanRecord")
		if not table.contains(JianYuanLu, damage_call(from,"objectName")) then
			return true
		end
	end


	if from and damage_call(from,"getMark","@Frozen_Eu") > 0 and damage_call(self,"isFriend",from, to) and card and sgs.card_damage_nature[damage_call(card,"getClassName")] == sgs.DamageStruct_Fire then return true end
	if from and damage_call(from,"getMark","@meizlwuzhijingjichangstate") > 0 and damage_call(self,"isFriend",from, to) then return true end
	if from and damage_call(from,"getMark","@meizlwuzhijingjichangstate") > 0 and damage_call(self,"isEnemy",from, to) then return false end
	if damage_call(to,"hasSkill","xiehou") and card and sgs.card_damage_nature[damage_call(card,"getClassName")] ~= sgs.DamageStruct_Normal then return true end
	if from and damage_call(from,"getMark","FiveYingzhan") == 0 and damage_call(self,"isFriend",from, to) and not damage_call(from,"hasFlag","FiveYingzhan_Damage")
		and card and sgs.card_damage_nature[damage_call(card,"getClassName")] == sgs.DamageStruct_Fire then
		return true
	end
	if from and damage_call(self,"isFriend",to, from) and damage_call(from,"getMark","keguijingmumark") > 0 then
		return
	end


	local nature = card and sgs.card_damage_nature[damage_call(card,"getClassName")]
	if damage_call(self,"ajustDamage",from,to,1,card,nature)>=damage_call(to,"getHp") then return end
	local bh = damage_call(self,"getBestHp",to)


	--add
	if damage_call(to,"hasSkill","emeng") and damage_call(to,"hasSkill","daohe") and from and damage_call(self,"isFriend",to, from) and (not damage_call(to,"inMyAttackRange",from)) and card and damage_call(card,"isKindOf","Slash") then
		return true
	end
	if damage_call(self,"isFriend",to, from) and damage_call(to,"hasSkill","sy_jiancheng") and not damage_call(to,"getPile","jiancheng"):isEmpty() and card and sgs.card_damage_nature[damage_call(card,"getClassName")] ~=  sgs.DamageStruct_Normal then
		return
	end
	if not passive and damage_call(to,"getMaxHp")>2 then
        if damage_call(to,"hasSkills","longluo|miji|yinghun") and damage_call(self,"findFriendsByType",sgs.Friend_Draw,to)
		or damage_call(to,"hasSkills","nosrende|rende") and not damage_call(self,"willSkipPlayPhase",to) and damage_call(self,"findFriendsByType",sgs.Friend_Draw,to)
		or damage_call(to,"hasSkill","jspdanqi") and damage_call(self,"getOverflow")==0
		then bh = math.min(bh,damage_call(to,"getMaxHp")-1) end
        local count = damage_call(self.room,"getModePlayerCount")
        if damage_call(to,"hasSkill","qinxue") and (damage_call(self,"getOverflow")==1 and count>=7 or damage_call(self,"getOverflow")==2 and count<7)
		or damage_call(to,"hasSkill","canshi") and count>=3 then bh = math.min(bh,damage_call(to,"getMaxHp")-1) end
		--add
		if damage_call(to,"hasSkills","echinei") and damage_call(self,"findFriendsByType",sgs.Friend_Draw, to) and not damage_call(self,"willSkipDrawPhase",to) then bh = math.min(bh, damage_call(to,"getMaxHp") - 1) end
		if damage_call(to,"hasSkills","meizljichi") and damage_call(self,"findFriendsByType",sgs.Friend_Draw, to) and not damage_call(self,"willSkipPlayPhase",to) then bh = math.min(bh, damage_call(to,"getMaxHp") - 1)	end
    end

	if damage_call(to,"hasSkill","ronghe") and #damage_call(self,"getEnemies",to) > 0 and damage_call(to,"getPile","&ronghe"):length() == 0 and not damage_call(self,"willSkipPlayPhase",to) then
		local max = 0
		for _,p in ipairs(damage_call(self,"getEnemies",to))do
			if damage_call(p,"getHp") > max and not damage_call(p,"isKongcheng") then max = damage_call(p,"getHp") end
		end
		bh = math.min(bh, math.max(max-1, 1))
	end
	local xiangxiang = self.room:findPlayerBySkillName("jieyin")
    if xiangxiang and damage_call(xiangxiang,"isWounded")
	and not damage_call(to,"isWounded") and damage_call(to,"isMale")
	and damage_call(self,"isFriend",xiangxiang,to) then
        local need_jieyin = true
        for _,friend in ipairs(damage_call(self,"sort",damage_call(self,"getFriends",to, true),"hp"))do
            if damage_call(friend,"isMale") and damage_call(friend,"isWounded") then need_jieyin = false break end
        end
        if need_jieyin then bh = math.min(bh,damage_call(to,"getMaxHp")-1) end
    end
	return (recover and damage_call(to,"getHp")>=bh or damage_call(to,"getHp")>bh)
	and (not sgs.ai_humanized or math.random()<0.95)
end
SmartAIView.needToloseHp = SmartAIView.needToLoseHp

function SmartAIView:getSuitNum(suit_strings, include_equip, player)
    player = player or self.player
    -- Source reads the supplied player's zones first, then replaces that list
    -- for a foreign player with the current viewer's disclosed h/he cards.
    local cards = player:getCards(include_equip and "he" or "h")
    if player:objectName() ~= self.player:objectName() then
        cards = getKnownCards(player, self.player, include_equip and "he" or "h")
    end
    cards = value_known(cards, "suit-count cards")
    local n = 0
    for _, card in ipairs(cards) do
        for _, suit in ipairs(suit_strings:split("|")) do
            if value_known(value_call(card, "getColorString"), "card color") == suit
                or value_known(value_call(card, "getSuitString"), "card suit") == suit then
                -- Source counts each token, including repeated/overlapping
                -- color and suit matches on the same card.
                n = n + 1
            end
        end
    end
    return n
end

function SmartAIView:hasSuit(suit_strings, include_equip, player)
    local n = self:getSuitNum(suit_strings, include_equip, player)
    if AIUnsupported.is(n) then error(n, 0) end
    if n == nil then ai_unsupported("suit count is unknown", "hasSuit") end
    return n > 0
end

function SmartAIView:hasEightDiagramEffect(owner)
    owner = owner or self.player
    local result = owner:hasArmorEffect("EightDiagram")
    if AIUnsupported.is(result) then error(result, 0) end
    if result == nil then ai_unsupported("EightDiagram effect is unknown", "hasEightDiagramEffect") end
    return result
end

-- Original wind-ai cantbeHurt, snapshot-only. Missing role/mark/peach counts stay unknown.
function SmartAIView:cantbeHurt(player,from,damageNum)
	from = from or self.player
	if core_query(self,"hasJueqingEffect",from,player) then return false end
	damageNum = damageNum or 1
	if (core_query(player,"hasSkill","wuhun") or core_query(player,"hasSkills","spwuhun") or core_query(player,"hasSkills","sgkgodsuohun")) and not core_query(player,"isLord") and #core_query(self,"getFriends",player,true)>0 then
		local maxfriendmark,maxenemymark = 0,0
		for friendmark,friend in sgs.list(core_query(self,"getFriends",from))do
            friendmark = core_query(friend,"getMark","&nightmare+#"..core_query(player,"objectName"))
			if friendmark>maxfriendmark then maxfriendmark = friendmark end
		end
		for enemymark,enemy in sgs.list(core_query(self,"getEnemies",from))do
            enemymark = core_query(enemy,"getMark","&nightmare+#"..core_query(player,"objectName"))
			if enemymark>maxenemymark and enemy~=player
			then maxenemymark = enemymark end
		end
		if core_query(self,"isEnemy",player,from) then
			if maxfriendmark+damageNum-core_query(player,"getHp")/2>=maxenemymark
			and not (#core_query(self,"getEnemies",from)==1 and #core_query(self,"getFriends",from)+#core_query(self,"getEnemies",from)==core_query(self.room,"alivePlayerCount"))
            and not (core_query(from,"getMark","&nightmare+#"..core_query(player,"objectName"))==maxfriendmark and damage_role(self,from)=="loyalist")
			then return true end
		elseif maxfriendmark+damageNum-core_query(player,"getHp")/2>maxenemymark
		then return true end
	end
	if core_query(player,"hasSkill","duanchang") and not core_query(player,"isLord")
	and #core_query(self,"getFriends",player,true)>0 and core_query(player,"getHp")<=1 then
		if not (core_query(from,"getMaxHp")==3 and from:getArmor() and from:getDefensiveHorse()) then
			if core_query(from,"getMaxHp")<=3 or core_query(from,"isLord") and core_query(self,"isWeak",from) then return true end
			if core_query(from,"getMaxHp")<=3 or self.room:getLord() and damage_role(self,from)=="renegade" then return true end
		end
	end
	if core_query(player,"hasSkill","tianxiang")
	and core_query(self,"useKnowledgeEstimate",core_query(self,"estimateKnownCards",player,"diamond,club",from,false),"cantbeHurt.tianxiang")<core_query(player,"getHandcardNum") then
		for _,friend in sgs.list(core_query(self,"getFriends",from))do
			if core_query(friend,"getHp")+core_query(self,"estimateCardsNum","Peach",from)<2
			and core_query(player,"getHandcardNum")>0
			then return true end
		end
	end
	return false
end


-- Original standard_cards-ai isGoodTarget. Recursion uses a viewer-local guard
-- instead of room:setPlayerFlag. Helpers that are not projected leave the
-- matching skill branch unknown rather than inventing a veto.
local function good_query(object,method,...)
    local provider=object and object[method]
    local result=value_call(object,method,...)
    if AIUnsupported.is(result) then error(result,0) end
    if result==nil and type(SmartAIView.isKnownNilStrategyResult)=="function"
        and SmartAIView.isKnownNilStrategyResult(object,method,provider) then return nil end
    return value_known(result,"good target "..method)
end
local function good_target(self,to,targets,card)
    -- The donor reads updatePlayers' current lists only in the branches below.
    -- Recomputing both groups on every recursive target test changes relation
    -- query side effects and repeats the complete roster scan unnecessarily.
	if AIValue.isList(targets) then
		for _,p in ipairs(targets)do
			if good_query(self, "isGoodTarget", p,nil,card)
			then return good_query(p, "objectName")==good_query(to, "objectName") or good_query(self, "isGoodTarget", to,nil,card) end
		end
		return true
	end
	local damageNum = good_query(self, "ajustDamage", self.player,to,1,card)
	if damageNum==0 then return end
	if good_query(to, "getMark", "hunzi")<1 and good_query(to, "isLord") and good_query(to, "getHp")>=2 and math.abs(damageNum)==1
	and value_known(good_query(self,"getRoleCounts").loyalist,"loyalist count")>0 and good_query(to, "hasSkill", "hunzi") then return end
	if damageNum<0 then return true end
	if not good_query(to, "isLord") and good_query(to, "getHp")<=damageNum and good_query(to, "hasSkill", "huilei") then
		if good_query(self.player, "getHandcardNum")>=4 then return end
		return good_query(self, "compareRoleEvaluation", to,"rebel","loyalist")=="rebel"
	end
	local apn = good_query(self, "getAllPeachNum", to)
	if apn+good_query(to, "getHp")>damageNum then
		if good_query(to, "hasSkill", "jieming") and good_query(self, "getJiemingChaofeng", to)>-4 then return end
		if good_query(to, "hasSkill", "yiji") and not good_query(self, "findFriendsByType", sgs.Friend_Draw,to) then return end
		if good_query(to, "hasSkills", "nosmiji|miji") then return end
		if good_query(to, "hasSkills", "neoganglie|xuehen|xueji")
		and good_query(self, "isWeak", self.friends) then return end
		if good_query(self.player, "getHp")<2 and math.random()<0.5
		and good_query(to, "hasSkill", "ganglie") then return end
		if good_query(self.player, "getHp")<2 and math.random()<0.7
		and good_query(to, "hasSkill", "nosganglie") then return end
		if good_query(to, "aliveCount")>2 and good_query(to, "hasSkill", "guixin") then return end
		if self._good_target_guard == true then return true end
		self._good_target_guard = true
		if math.random()<0.6 and good_query(self, "needToLoseHp", to,self.player,card) then self._good_target_guard = false return end
		self._good_target_guard = false
	end
	if (good_query(to, "getLostHp")<2 or apn+good_query(to, "getHp")>damageNum and #good_query(self, "getFriends", to)>1)
	and good_query(to, "hasSkill", "fangzhu") then return end
	if not good_query(to, "isLord") and good_query(to, "hasSkill", "wuhun")
	and #good_query(self, "getFriends", to,true)>0 then
		local maxfriendmark,maxenemymark = 0,0
		for _,friend in ipairs(self.friends)do
            local friendmark = good_query(friend, "getMark", "&nightmare+#"..good_query(to, "objectName"))
			if friendmark>maxfriendmark then maxfriendmark = friendmark end
		end
		for _,enemy in ipairs(self.enemies)do
            local enemymark = good_query(enemy, "getMark", "&nightmare+#"..good_query(to, "objectName"))
			if enemymark>maxenemymark and enemy~=to
			then maxenemymark = enemymark end
		end
		if good_query(self, "isEnemy", to) then
			if maxfriendmark+damageNum-good_query(to, "getHp")/2>=maxenemymark
			and not(#self.enemies==1 and #self.friends+#self.enemies==good_query(self.room, "alivePlayerCount"))
            and not(good_query(self.player, "getMark", "&nightmare+#"..good_query(to, "objectName"))==maxfriendmark and good_query(self.player, "getRole")=="loyalist")
			then return end
		elseif maxfriendmark+damageNum-good_query(to, "getHp")/2>maxenemymark
		then return end
	end
	if good_query(to, "getHp")<=damageNum and good_query(self.player, "getMaxHp")<6
	and not good_query(to, "isLord") and #good_query(self, "getFriends", to,true)>0 and good_query(to, "hasSkill", "duanchang") then
		if not(good_query(self.player, "getMaxHp")>=3 and self.player:getArmor() and self.player:getDefensiveHorse()) then
			if good_query(self.player, "isLord") and good_query(self, "isWeak") or self.room:getLord() and good_query(self.player, "getRole")=="renegade"
			then return end
		end
	end
	if good_query(to, "hasSkill", "tianxiang")
	and value_known(getKnownCard(to,self.player,"diamond,club"),"tianxiang known suits")<good_query(to, "getHandcardNum") then
		for _,friend in ipairs(self.friends)do
			if good_query(friend, "getHp")+good_query(self, "getCardsNum", "Peach")-damageNum<2
			then return end
		end
	end
	if card and good_query(card, "isKindOf", "Slash") then
		if card and good_query(card, "isKindOf", "Slash") and not good_query(self, "slashIsEffective", card,to, self.player) then return end
		for _,askill in sgs.qlist(good_query(to, "getSkills"))do
			local filter = sgs.ai_slash_prohibit[good_query(askill, "objectName")]
			if type(filter)=="function" and filter(self,self.player,to,card)
			then return end
		end
	end
	--add
	if good_query(to, "hasSkill", "kechengshishou") and good_query(to, "hasSkill", "kechengcangchu") and good_query(to, "getMark", "Qingchengkechengcangchu") == 0 and card and (good_query(card, "isKindOf", "FireSlash") or good_query(card, "isKindOf", "FireAttack")) then return true end
	if good_query(to, "hasSkill", "LuaBimie") or good_query(to, "hasSkill", "fatebimie") then return true end
	if good_query(self.player, "hasSkill", "sp_guoguanzhanjiang") and good_query(to, "getMark", "&LeVeL") > 0 then return true end

	if self._good_target_guard == true then return true end
	self._good_target_guard = true
	if good_query(self, "needToLoseHp", to,self.player,card) and apn+good_query(to, "getHp")>damageNum
	and math.random()<0.66 then self._good_target_guard = false return end
	self._good_target_guard = false
	return true
end


function SmartAIView:isGoodTarget(to,targets,card)
    local guard = self._good_target_guard
    local ok, result = pcall(good_target,self,to,targets,card)
    self._good_target_guard = guard
    if not ok then error(result,0) end
    return result == true
end

-- Original standard_cards-ai canAttack. Nature defaults to normal; fire vine /
-- kuangfeng still raise the cantbeHurt estimate the way the donor does.
function SmartAIView:canAttack(enemy,attacker,nature)
	attacker = attacker or self.player
	nature = nature or sgs.DamageStruct_Normal
	local damage = 1
	if nature==sgs.DamageStruct_Fire and not core_query(enemy,"hasArmorEffect","SilverLion") then
		if core_query(enemy,"hasArmorEffect","Vine") then damage = damage+1 end
        if core_query(enemy,"getMark","&kuangfeng")>0 then damage = damage+1 end
	end
	if #self.enemies==1 or core_query(self,"hasSkills","jueqing") then return true end
	if core_query(self,"needToLoseHp",enemy,attacker,false,true) and #self.enemies>1
	or not core_query(self,"isGoodTarget",enemy,self.enemies)
	or core_query(self,"objectiveLevel",enemy)<=2
	or core_query(self,"cantbeHurt",enemy,self.player,damage)
	or not core_query(self,"damageIsEffective",enemy,nature,attacker)
	or nature~=sgs.DamageStruct_Normal and core_query(enemy,"isChained") and not core_query(self,"isGoodChainTarget",enemy,nature)
	then return false end
	return true
end

-- The donor evaluates a real printed Slash probe; nil would lose its skill branches.
function SmartAIView:canLiuli(other,another)
	if not core_query(other,"hasSkill","liuli") then return false end
	if AIValue.isList(another)
	then
		for _,target in sgs.list(another)do
			if core_query(target,"getHp")<3 and core_query(self,"canLiuli",other,target)
			then return true end
		end
		return false
	end
	if not core_query(self,"needToLoseHp",another,self.player,core_query(self,"getEvaluationCard","slash")) then return false end
	if core_query(other,"getHandcardNum")>0 and core_query(other,"distanceTo",another)<=core_query(other,"getAttackRange")
	or other:getWeapon() and other:getOffensiveHorse() and core_query(other,"distanceTo",another)<=core_query(other,"getAttackRange")
	or (other:getWeapon() or other:getOffensiveHorse()) and core_query(other,"distanceTo",another)<=1
	then return true end
    return false
end

-- Original SmartAI:canLiegong. Built-in liegong / kofliegong / tenyearliegong
-- keep their phase and count gates; package hooks stay truthy-only.
function SmartAIView:canLiegong(to, from)
    from = from or self.room:getCurrent()
    to = to or self.player
    if not from then return false end
    if not to then return nil end
    if core_query(from,"hasSkill","liegong") and core_query(from,"getPhase") == sgs.Player_Play
        and (core_query(to,"getHandcardNum") >= core_query(from,"getHp")
            or core_query(to,"getHandcardNum") <= core_query(from,"getAttackRange")) then return true end
    if core_query(from,"hasSkill","kofliegong") and core_query(from,"getPhase") == sgs.Player_Play
        and core_query(to,"getHandcardNum") >= core_query(from,"getHp") then return true end
    if core_query(from,"hasSkill","tenyearliegong")
        and core_query(to,"getHandcardNum") <= core_query(from,"getHandcardNum") then return true end
    local hooks = skill_hooks(self, "ai_canliegong_skill", from)
    if not hooks then return nil end
    for _, hook in ipairs(hooks) do
        local result = self:callHook("ai_canliegong_skill", hook.key, self, from, to)
        if result then return true end
    end
    return false
end

function SmartAIView:hasCrossbowEffect(player)
    player = player or self.player
    if core_query(player,"hasSkills","paoxiao|tenyearpaoxiao|olpaoxiao") or core_query(player,"hasWeapon","crossbow") then return true end
    -- Source invalidation is tied to actual filterEvent boundaries (including
    -- Death's second clear), not every recorded native event or snapshot.
    local query=rawget(_G,"ai_target_recommend_cache")
    if type(query)~="function" then ai_unsupported("Crossbow live cache epoch host is unavailable","hasCrossbowEffect") end
    local stamp=query({op="epoch"})
    if AIUnsupported.is(stamp) then error(stamp,0) end
    if type(stamp)~="table" or getmetatable(stamp)~=nil or stamp.known~=true
        or type(stamp.scope)~="string" or stamp.scope==""
        or type(stamp.epoch)~="string" or not stamp.epoch:match("^%d+$") then
        ai_unsupported("Crossbow cache requires actual scoped source epoch","hasCrossbowEffect")
    end
    local scope,epoch=stamp.scope,stamp.epoch
    local cache
    if epoch ~= "0" then
        local stored, known = self:getStrategyMemory("crossbow_effect")
        if known and type(stored) == "table" and stored.scope == scope
            and stored.epoch == epoch and type(stored.values) == "table" then
            cache = copy_strategy_state(stored)
        else cache = {scope=scope,epoch=epoch, values={}} end
    end
    local key = self.player:objectName() .. "|" .. player:objectName()
    local cached = cache and cache.values[key]
    if type(cached) == "table" and type(cached.value) == "boolean" then
        for _, entry in ipairs(cached.estimates or {}) do
            local provenance = copy_strategy_state(entry)
            provenance.count = nil
            provenance.status = "estimate"
            if provenance.value == nil then provenance.value = cached.value end
            self:useKnowledgeEstimate(provenance, entry.context or "hasCrossbowEffect")
        end
        return cached.value
    end
    local list, targets = {}, core_query(self,"getEnemies",player)
    for _, known in ipairs(core_query(self,"getKnownCards",player,self.player,"&he")) do
        local slash = isCard("Slash",known,player)
        if slash then list[#list+1] = slash end
    end
    if #list > 6 then
        local picked, seen, sample = {}, {}, {}
        for index, slash in ipairs(list) do
            local group = core_query(slash,"getClassName").."|"..core_query(slash,"getSuitString").."|"..core_query(slash,"getSkillName")
            if not seen[group] and #sample < 6 then seen[group],picked[index]=true,true; sample[#sample+1]=slash end
        end
        for index, slash in ipairs(list) do
            if #sample >= 6 then break end
            if not picked[index] then sample[#sample+1]=slash end
        end
        list = sample
    end
    local total = 0
    for _, slash in ipairs(list) do
        for _, target in ipairs(targets) do
            local residue
            if player:objectName() == self.player:objectName() then residue = core_query(slash,"getTargetResidue",target)
            else
                residue = value_call(self,"getSourceCardTargetResidue",player,slash,target)
                if residue == nil then residue = core_query(self,"useKnowledgeEstimate",{value=0,status="estimate",
                    basis="foreign Slash residue unavailable; no unobserved extra-use modifier prior",observer=self.player:objectName()},"hasCrossbowEffect") end
            end
            total = total + residue
        end
    end
    local result = total > #list / 2
    if cache then
        -- Conservatively retain all contributing request estimates. This can
        -- over-tag a cache hit, but cannot silently upgrade an estimate to fact.
        local scratch = self.request and self.request.scratch
        cache.values[key] = {value=result, estimates=copy_strategy_state(scratch and scratch.knowledge_estimates or {})}
        self:setStrategyMemory("crossbow_effect", cache)
    end
    return result
end

function SmartAIView:hasHeavyDamage(from,card,to,nature)
    local result=self:ajustDamage(from,to,1,card,nature)
    if AIUnsupported.is(result) then error(result,0) end
    return result>1
end

function SmartAIView:findLeijiTarget(player,leiji_value,slasher,latest_version)
	if not latest_version then
		return good_query(self, "findLeijiTarget", player,leiji_value,slasher,1)
		or good_query(self, "findLeijiTarget", player,leiji_value,slasher,-1)
	end
	if not good_query(player, "hasSkills", latest_version==1 and "leiji|olleiji|tenyearleiji" or "nosleiji|luafan|PlusLeiji|qhwindleiji|sfofl_huanlei") then return false end
	if slasher then
		if not good_query(self, "slashIsEffective", good_query(self, "getEvaluationCard", "slash"),player,slasher,good_query(slasher, "hasWeapon", "qinggang_sword")) then return false end
		if good_query(slasher, "hasSkill", "liegong") and good_query(slasher, "getPhase")==sgs.Player_Play and good_query(self, "isEnemy", player,slasher)
		and (good_query(player, "getHandcardNum")>=good_query(slasher, "getHp") or good_query(player, "getHandcardNum")<=good_query(slasher, "getAttackRange"))
		then return false end
		if good_query(slasher, "hasSkill", "kofliegong") and good_query(slasher, "getPhase")==sgs.Player_Play
		and good_query(self, "isEnemy", player,slasher) and good_query(player, "getHandcardNum")>=good_query(slasher, "getHp")
		then return false end
		if latest_version then
			if not good_query(self, "hasSuit", "black",true,player) and good_query(player, "getHandcardNum")<2 then return false end
		else
			if not good_query(self, "hasSuit", "spade",true,player) and good_query(player, "getHandcardNum")<3 then return false end
		end
		if not(getKnownCard(player,self.player,"Jink",true)>0
		or good_query(player, "getHandcardNum")>=4 and good_query(self, "estimateCardsNum", "Jink", player)>=1
		or not good_query(self, "isWeak", player) and good_query(self, "hasEightDiagramEffect", player) and not good_query(slasher, "hasWeapon", "qinggang_sword") and good_query(self, "estimateCardsNum", "Jink", player)>=1)
		then return false end
	end
	local function getCmpValue(enemy)
		if not good_query(self, "damageIsEffective", enemy,sgs.DamageStruct_Thunder,player) then return 99 end
		local value = 0
		if good_query(enemy, "hasSkills", "hongyan|olhongyan") then
			if latest_version==-1 then return 99
			elseif not good_query(self, "hasSuit", "club",true,player) and good_query(player, "getHandcardNum")<3
			then value = value+80
			else value = value+70 end
		end
		if good_query(self, "cantbeHurt", enemy,player,latest_version==1 and 1 or 2)
		or good_query(self, "objectiveLevel", enemy)<3
		or (good_query(enemy, "isChained") and not good_query(self, "isGoodChainTarget", enemy,sgs.DamageStruct_Thunder,player,latest_version==1 and 1 or 2))
		then return 100 end
		if not latest_version and good_query(enemy, "hasArmorEffect", "silver_lion") then value = value+20 end
		if good_query(enemy, "hasSkills", sgs.exclusive_skill) then value = value+10 end
		if good_query(enemy, "hasSkills", sgs.masochism_skill) then value = value+5 end
		if good_query(enemy, "isChained") and good_query(self, "isGoodChainTarget", enemy,sgs.DamageStruct_Thunder,player,latest_version==1 and 1 or 2)
		and #good_query(self, "getChainedEnemies", player)>1 then value = value-25 end
		if good_query(enemy, "isLord") then value = value-5 end
		value = value+good_query(enemy, "getHp")+good_query(self, "getDefenseSlash", enemy)*0.01
		if latest_version and good_query(player, "isWounded") and not good_query(self, "needToLoseHp", player) then value = value+15 end
		return value
	end
	local bcv = {}
	local enemies = good_query(self, "getEnemies", player)
	for _,enemy in ipairs(enemies)do
		bcv[good_query(enemy, "objectName")] = getCmpValue(enemy)
	end
	local function cmp(a,b)
		return bcv[good_query(a, "objectName")]<bcv[good_query(b, "objectName")]
	end
	table.sort(enemies,cmp)
	for _,enemy in ipairs(enemies)do
		if getCmpValue(enemy)<leiji_value then return enemy end
	end
	return false
end


local function card_in_player(player, id)
    for _, entry in ipairs({{player:getKnownCards(), "hand"}, {player:getEquips(), "equip"},
        {player:getJudgingArea(), "judge"}}) do
        for _, card in ipairs(entry[1] or {}) do
            if card:getEffectiveId() == id then return card, entry[2] end
        end
    end
end

-- Shared bad-card classification is extensible; callbacks receive the original
-- (self, card, owner) ABI. Unknown retrial outcomes are not guessed.
local function harmful_card(self, card, owner, zone)
    local custom = self:callHook("ai_poison_card", card:objectName(), self, card, owner)
    if type(custom) == "boolean" then return custom end
    if card:isKindOf("Shit") then return true end
    if zone == "judge" then
        if card:isKindOf("Xumou") or card:isKindOf("YanxiaoCard") then return false end
        if card:isKindOf("Lightning") then return nil end
        if owner:containsTrick("YanxiaoCard") or owner:containsTrick("shuugakulyukou") then return false end
        return card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")
    end
    if zone == "equip" then
        if category(owner, "lose_equip_skill") then return true end
        if card:isKindOf("SilverLion") then
            local hp, max_hp = scalar(owner, "getHp"), scalar(owner, "getMaxHp")
            if hp == nil or max_hp == nil then return nil end
            return hp < max_hp
        end
    end
    return false
end

local function discard_query(object, method, ...)
    return value_known(value_call(object, method, ...), "discard " .. method)
end
local function discard_relation(self, target)
    return discard_query(self, "isFriend", target)
end
function SmartAIView:loseEquipEffect(player)
    player=player or self.player
    if discard_query(player,"hasSkills",sgs.lose_equip_skill) then return true end
    for _,skill in ipairs(value_known(sgs.getPlayerSkillList(player),"source player skill list"))do
        local description=discard_query(skill,"getDescription")
        if string.find(description,"装备区") and string.find(description,"失去") then
            discard_query(skill,"objectName")
            -- Engine::getTriggerSkill(name) casts the same getSkill(name)
            -- definition whose complete class chain/events were projected.
            if discard_query(skill,"inherits","TriggerSkill") and discard_query(skill,"hasEvent",sgs.CardsMoveOneTime) then return true end
        end
    end
end

-- Fixed smart-ai.lua8958 base poison metadata; later package writers retain their order.
sgs.ai_poison_card = sgs.ai_poison_card or {}
sgs.ai_poison_card.shit = true

-- Source hand-membership is exact for the owner. For a foreign input, only an
-- already disclosed location can establish that membership; a visible face
-- alone cannot reveal that it moved into a hidden hand.
local function round32_poison_hand_contains(self, owner, id)
    if not AIValue.isPlayer(owner) or owner:objectName() == self.player:objectName() then
        return discard_query(owner, "handCards"):contains(id)
    end
    for _, card in ipairs(discard_query(owner, "getKnownCards")) do
        if discard_query(card, "getId") == id then return true end
    end
    if type(id) == "number" and id < 0 then return false end
    local place = self.room:getCardPlace(id)
    if place ~= nil then
        local holder = self.room:getCardOwner(id)
        return holder ~= nil and holder:objectName() == owner:objectName() and place == sgs.Player_PlaceHand
    end
    if discard_query(owner, "getHandcardNum") == 0 then return false end
    ai_unsupported("foreign poison-card hand membership is not disclosed", "poisonCards")
end

local function round32_poison_face(self, id)
    local card = self:getKnownCardById(id)
    if AIUnsupported.is(card) then error(card, 0) end
    if card then return card end
    local request = self.request
    if request and (request.kind == "amazing_grace" or request.kind == "guanxing") then
        for _, offered in ipairs(request.options and request.options.card_ids or {}) do
            if offered == id then
                card = self:getChoiceCard(id)
                if AIUnsupported.is(card) then error(card, 0) end
                if card and card:isVirtualCard() == false and card:getEffectiveId() == id then return card end
                break
            end
        end
    end
    ai_unsupported("poison card identity is not visible", "poisonCards")
end

function SmartAIView:poisonCards(flags, owner)
    owner = owner or self.player
    local result = AIList.new({})
    flags = flags or "h"
    if type(flags) == "string" then
        if not AIValue.isPlayer(owner) or owner:objectName() == self.player:objectName() then
            -- ServerPlayer::getCards ignores unrecognized flag characters.
            local normalized = (flags:find("h",1,true) and "h" or "")
                .. (flags:find("e",1,true) and "e" or "") .. (flags:find("j",1,true) and "j" or "")
            flags = normalized == "" and {} or discard_query(owner, "getCards", normalized)
        else
            -- Unknown hand identities are skipped by the source before any
            -- poison rule. Retain the disclosed subsequence, then e/j order.
            local cards = {}
            if flags:find("h",1,true) then
                for _, card in ipairs(discard_query(owner,"getKnownCards")) do cards[#cards+1] = card end
            end
            for _, zone in ipairs({"e","j"}) do
                if flags:find(zone,1,true) then
                    for _, card in ipairs(discard_query(owner,"getCards",zone)) do cards[#cards+1] = card end
                end
            end
            flags = cards
        end
    end
    for _, item in ipairs(flags) do
        local card, id = item, item
        if type(item) == "number" then card = round32_poison_face(self,item)
        else id = discard_query(item,"getEffectiveId") end
        if round32_poison_hand_contains(self,owner,id) then
            local seen = false
            for _, known in ipairs(value_known(getKnownCards(owner,self.player),"poisonCards known cards")) do
                seen = discard_query(known,"getId") == id
                if seen then break end
            end
            if not seen then continue end
        end
        local rule = sgs.ai_poison_card[discard_query(card,"objectName")]
        local poison = rule == true or type(rule) == "function" and rule(self,card,owner)
        if AIUnsupported.is(poison) then error(poison,0) end
        if poison or discard_query(owner,"getEquipsId"):contains(id)
            and discard_query(self,"evaluateArmor",card,owner) < -5
            or discard_query(owner,"getJudgingAreaID"):contains(id)
            and not (discard_query(owner,"containsTrick","YanxiaoCard") or discard_query(card,"isKindOf","Xumou")) then
            result:append(card)
        end
    end
    return result
end

function SmartAIView:randomHandDiscardToken(target)
    local facts=self.world and self.world.strategy_facts
    local rows=facts and facts.random_hand_discard
    local name=target and target:objectName()
    local capability=rows and rows[name]
    if type(capability)~="table" or type(capability.token)~="string" or capability.token==""
        or type(ai_sample_hidden_hand)~="function" then
        ai_unsupported("random hand authority is unavailable","Dismantlement")
    end
    local ok,sample=pcall(ai_sample_hidden_hand,capability.token,name)
    if not ok or type(sample)~="table" or sample.kind~="hand_discard_sample"
        or sample.token~=capability.token or sample.target~=name or type(sample.empty)~="boolean" then
        ai_unsupported("random hand authority rejected the query","Dismantlement")
    end
    return sample
end

-- Native samples the full hand at the original getRandomHandCard call site.
-- This value carries permission/visibility facts, never a hidden physical ID.
function SmartAIView:doDisCardHandSample(to, sample)
    if type(sample) ~= "table" or sample.kind ~= "hand_discard_sample"
        or type(sample.token) ~= "string" or sample.token == "" or sample.target ~= to:objectName()
        or type(sample.empty) ~= "boolean" then
        ai_unsupported("invalid random hand sample", "doDisCard")
    end
    if sample.empty then return false end
    if type(sample.can_discard) ~= "boolean" or type(sample.disabled) ~= "boolean" then
        ai_unsupported("random hand sample restrictions are unknown", "doDisCard")
    end
    if not sample.can_discard or sample.disabled then return false end
    local function is_poison()
      if sample.known_card_id ~= nil then
        if type(sample.known_card_id) ~= "number" then ai_unsupported("invalid known sample ID", "doDisCard") end
        local known
        for _, card in ipairs(discard_query(to,"getKnownCards")) do
            if card:getEffectiveId() == sample.known_card_id then known=card;break end
        end
        if not known then ai_unsupported("sample ID is not viewer-known hand metadata", "doDisCard") end
        return #discard_query(self,"poisonCards",{known},to)>0
      end
      return false
    end
    -- Source poisonCards skips an unobserved hand card before callbacks.
    if discard_relation(self,to) then return is_poison() end
    if #(self.enemies or discard_query(self,"getEnemies"))>1 and not discard_query(to,"hasFlag","CurrentPlayer")
        and discard_query(to,"hasSkill","zaoxian",true) then return false end
    return not is_poison()
end

-- R31 source policy calls preserve known nil returns from the audited boolean
-- helpers. Facade getters still require known values; a returned typed signal
-- is never treated as truthy policy data.
local function allocation_query(object, method, ...)
    if not object or type(object[method]) ~= "function" then
        ai_unsupported("allocation dependency is unavailable", method)
    end
    local provider = object[method]
    local value = value_call(object, method, ...)
    if AIUnsupported.is(value) then error(value, 0) end
    if value == nil and not (type(SmartAIView.isKnownNilStrategyResult) == "function"
        and SmartAIView.isKnownNilStrategyResult(object, method, provider)) then
        ai_unsupported("allocation dependency is unknown", method)
    end
    return value
end
local function allocation_zone_count(player, flags)
    local count = 0
    -- ServerPlayer::getCards simply concatenates these zones in h/e/j order.
    -- Its length needs public counts, never a foreign hand-face projection.
    if flags:find("h",1,true) then count = count + allocation_query(player,"getHandcardNum") end
    if flags:find("e",1,true) then count = count + #allocation_query(player,"getEquips") end
    if flags:find("j",1,true) then count = count + #allocation_query(player,"getJudgingArea") end
    return count
end

function SmartAIView:doDisCard(to, flags, obtain, n)
    flags = flags or "hej"
    if type(flags)=="table" and flags.kind=="hand_discard_sample" then
        if obtain then ai_unsupported("discard sample cannot authorize an obtain", "doDisCard") end
        return self:doDisCardHandSample(to,flags)
    end
    if not (obtain or allocation_query(self.player, "canDiscard", to, flags)) then return end
    local function enemies()
        return self.enemies or allocation_query(self, "getEnemies")
    end
    local function contains(method, id)
        return table.contains(allocation_query(to, method), id)
    end
    local function visible_card(method, id)
        for _, card in ipairs(allocation_query(to, method)) do
            if card:getEffectiveId() == id then return card end
        end
        ai_unsupported("discard public-zone card metadata is unavailable", "doDisCard")
    end
    if type(flags) == "number" then
        -- Match source short-circuit order: no card face/hand/relationship
        -- query is needed before the native Xixiu or cached-disabled guard.
        if not obtain and allocation_query(to, "hasSkill", "xixiu")
            and #allocation_query(to, "getEquips") < 2 and contains("getEquipsId", flags) then return end
        local disabled = self.disabled_ids
        if disabled == nil then
            local cached, known
            if type(self.getStrategyMemory)=="function" then cached,known=self:getStrategyMemory("discard_disabled_ids") end
            disabled = known and value_known(cached,"discard disabled ID cache") or {}
        end
        if table.contains(disabled, flags) then return end
        if allocation_query(self, "isFriend", to) then
            if contains("getJudgingAreaID", flags) then
                local card = visible_card("getJudgingArea", flags)
                if allocation_query(card,"isKindOf","Xumou") or allocation_query(to, "containsTrick", "YanxiaoCard")
                    or allocation_query(to, "containsTrick", "shuugakulyukou")
                    or allocation_query(card, "isDamageCard") and allocation_query(self, "getFinalRetrial", to) == 1 then return end
                return true
            end
            return #allocation_query(self, "poisonCards", {flags}, to) > 0
        end
        if contains("getEquipsId", flags) then
            local card = visible_card("getEquips", flags)
            if allocation_query(self.player, "hasSkill", "undershouli") or allocation_query(self.player, "hasSkill", "tyshouli")
                or allocation_query(self.player, "hasSkill", "shouli") then
                if allocation_query(card,"isKindOf","Horse") then return end
            end
        end
        local poison_item = flags
        if contains("getJudgingAreaID", flags) then
            local card = visible_card("getJudgingArea", flags)
            poison_item = card -- source overwrites flags only in this judge branch
            if allocation_query(card,"isKindOf","Xumou") then return end
            if allocation_query(card, "isDamageCard") and allocation_query(self, "getFinalRetrial", to) > 1
                or allocation_query(card,"isKindOf","YanxiaoCard") then return true end
        elseif contains("getEquipsId", flags)
            and (allocation_query(self, "loseEquipEffect", to) or core_query(to,"getMark","&dev_die") > 0) then return end
        if #enemies() > 1 and not allocation_query(to, "hasFlag", "CurrentPlayer")
            and allocation_query(to, "hasSkill", "zaoxian", true) then return end
        return #allocation_query(self, "poisonCards", {poison_item}, to) < 1
    end
    if type(flags) ~= "string" then ai_unsupported("discard flags are not a known ID or zone string", "doDisCard") end
    n = n or 1
    local friend = allocation_query(self, "isFriend", to)
    if not friend and #enemies() > 1 and not allocation_query(to, "hasFlag", "CurrentPlayer")
        and allocation_query(to, "hasSkill", "zaoxian", true) then return end
    if flags:find("e", 1, true) then
        if not obtain and allocation_query(to, "hasSkill", "xixiu") and allocation_zone_count(to, flags) < 2
            and #allocation_query(to,"getEquips") == 1 then return end
        if friend then
            if #allocation_query(self, "poisonCards", "e", to) >= n / 2 then return true end
        else
            if flags == "he" then
                if allocation_query(to, "hasEquip") then
                    if allocation_query(to, "getHandcardNum") <= n / 2
                        and (allocation_query(self, "loseEquipEffect", to) or core_query(to,"getMark","&dev_die") > 0) then return end
                elseif allocation_query(to, "getHandcardNum") <= n and allocation_query(self, "needKongcheng", to)
                    or allocation_query(self, "getLeastHandcardNum", to) >= n then return end
                return allocation_query(to, "getCardCount") > n / 2
            end
            if not obtain and #enemies() > 1 and allocation_query(to, "hasSkill", "lirang") then return end
            if #allocation_query(self, "poisonCards", "e", to) < #allocation_query(to,"getEquips")
                and not (allocation_query(self, "loseEquipEffect", to) or core_query(to,"getMark","&dev_die") > 0) then return true end
        end
    end
    if flags:find("h", 1, true) and allocation_query(to, "getHandcardNum") > 0 then
        if friend then
            if allocation_query(to, "getHandcardNum") <= n and allocation_query(self, "needKongcheng", to)
                or not obtain and allocation_query(to, "hasSkill", "lirang") and #allocation_query(self, "getFriends", to, true) > 0
                or allocation_query(self, "getLeastHandcardNum", to) >= n then return true end
        elseif not allocation_query(self, "needKongcheng", to) or allocation_query(self, "getLeastHandcardNum", to) < n then return true end
    end
    if flags:find("j", 1, true) then
        if friend then return #allocation_query(self, "poisonCards", "j", to) > 0 end
        for _, id in ipairs(allocation_query(to, "getJudgingAreaID")) do
            if self:doDisCard(to, id, obtain) then return true end
        end
    end
    return
end

SmartAIView.dodiscard = SmartAIView.doDisCard

-- Original shared cardNeed priorities, evaluated from visible values and the
-- existing per-skill value tables. No native card lookup or guessed hand IDs.
function SmartAIView:cardNeed(card)
    local function card_is(class)
        local request = self.request
        if request and request.kind == "guanxing" then
            local options = request.options
            local id = core_query(card, "getEffectiveId")
            if options and AIValue.isList(options.card_ids) and table.contains(options.card_ids, id)
                and AIValue.isCard(card) and not AIValue.isConversion(card)
                and core_query(card, "isVirtualCard") == false then
                -- Guanxing evaluates cards it has disclosed, before acquisition.
                -- This is only a class predicate: no conversion receipt/payment
                -- is requested, and the shared helper verifies the offered face.
                return core_query(self, "isCardForAcquisition", class, card)
            end
        end
        return isCard(class, card, self.player)
    end
	--if type(card)~="userdata" then return 0 end
	local value = core_query(self,"getUseValue",card)
	if card_is("Peach") then
		if core_query(self,"isWeak",self.friends) then value = value+4 end
		if (core_query(self.player,"getHp")<3 or core_query(self.player,"getLostHp")>1)
		or core_query(self.player,"hasSkills","kurou|benghuai") then value = value+6 end
	end
	if core_query(card,"getTypeId")>1 and core_query(self,"hasSkills","buyi",self.friends) then
		if (core_query(self.player,"getHp")<3 or core_query(self.player,"getLostHp")>1 and core_query(self,"isWeak"))
		or core_query(self.player,"hasSkills","kurou|benghuai") then value = value+5 end
	end
	if core_query(card,"isKindOf","EquipCard") and core_query(self,"hasSkills","meizlzhuanchong",self.friends) then
		if (core_query(self.player,"getHp")<3 or core_query(self.player,"getLostHp")>1 and core_query(self,"isWeak"))
		or core_query(self.player,"hasSkills","kurou|benghuai") then value = value+5 end
	end
	local i = 1
	for _,askill in sgs.qlist(core_query(self.player,"getVisibleSkillList",true))do
		local v = sgs[core_query(askill,"objectName").."_keep_value"]
		if type(v)=="table" then
			v = v[core_query(card,"getClassName")]
			if type(v)=="number" then
				value = value+v/i
				i = i+1
			end
		end
		v = source_suit_value(self,core_query(askill,"objectName"))
		if type(v)=="table" then
			v = v[core_query(card,"getSuitString")]
			if type(v)=="number" then
				value = value+v/i
				i = i+1
			end
		end
	end
	if core_query(card,"getTypeId")<3 then
		value = value-(core_query(self,"getCardsNum",core_query(card,"getClassName"))/4)*value
		if sgs.ai_poison_card[core_query(card,"objectName")] then value = value-10 end
	end
	if core_query(self,"isWeak") and card_is("Jink,Analeptic") then value = value+5
	elseif card_is("Slash") and (core_query(self,"getCardsNum","Crossbow")>0 or core_query(self,"hasCrossbowEffect")) then value = value+3
	elseif core_query(card,"isKindOf","Crossbow") then
		if core_query(self.player,"hasSkills","luoshen|yongsi|kurou|keji|wusheng|tenyearwusheng|wushen|olwushen|chixin")
		then value = value+core_query(self,"getCardsNum","Slash")*2 end
	elseif core_query(card,"isKindOf","Axe") then
		if core_query(self.player,"hasSkills","luoyi|jiushi|jiuchi|pojun")
		then value = value+5 end
	elseif core_query(card,"isKindOf","Nullification")
	and core_query(self,"getCardsNum","Nullification")<2 then
		for _,friend in ipairs(self.friends)do
			if core_query(self,"willSkipPlayPhase",friend)
			or core_query(self,"willSkipDrawPhase",friend)
			or core_query(friend,"getJudgingArea"):length()>0
			then value = value+5 break end
		end
	end
	return value
end

function SmartAIView:sortByCardNeed(cards,inverse,flags)
    if not AIValue.isList(cards) then return nil end
    local result = sgs.QList2Table(cards)
    if flags=="j" then
        for i=#result,1,-1 do if core_query(self.player,"isJilei",result[i]) then table.remove(result,i) end end
    end
    if #result<2 then return result end
    local values={}
    for _,card in ipairs(result) do values[legacy_sort_key(card)]=self:cardNeed(card) or 0 end
    table.sort(result,function(a,b)
        if inverse then return values[legacy_sort_key(a)]>values[legacy_sort_key(b)] end
        return values[legacy_sort_key(a)]<values[legacy_sort_key(b)]
    end)
    return result
end

-- Native Player::canUse(list) is existential over its single-player overload.
-- These facts include the donor's temporary xiyan mark, unlike target tickets.
function SmartAIView:canUse(card,players,from)
    players = players or core_query(self.room,"getAlivePlayers")
    from = from or self.player
    for _, player in ipairs(players) do if core_query(from,"canUse",card,player) then return true end end
    return false
end

function SmartAIView:willUse(player,card,ignoreDistance,disWeapon,play)
	local from = player or self.player
	if play then
		if core_query(self,"aiUseCard",card).card
		then return true end
	else
		if core_query(card,"isKindOf","Slash") then
			for _,to in sgs.list(self.enemies)do
				local far = false
				if core_query(from,"hasSkill","tenyearliegong") or core_query(from,"hasFlag","TianyiSuccess")
				or core_query(from,"hasFlag","JiangchiInvoke") or core_query(from,"hasFlag","InfinityAttackRange")
				or core_query(from,"getMark","InfinityAttackRange")>0 then far = true end
				if disWeapon then
					if core_query(from,"distanceTo",to)>1 and not far
					or core_query(to,"hasArmorEffect","renwang_shield") and core_query(card,"isBlack")
					or core_query(to,"hasArmorEffect","Vine") and not core_query(card,"isKindOf","NatureSlash")
					then continue end
				end
				if (core_query(from,"canSlash",to,card,not ignoreDistance) or far)
				and core_query(self,"slashIsEffective",card,to,from) and core_query(self,"isGoodTarget",to,self.enemies,card)
				and not core_query(self,"slashProhibit",card,to,from)
				then return true end
			end
		elseif core_query(card,"isKindOf","SupplyShortage") then
			if core_query(from,"hasSkill","jizhi") then ignoreDistance = true end
			for _,to in sgs.list(self.enemies)do
				if not ignoreDistance and core_query(from,"distanceTo",to)>1
				or core_query(to,"containsTrick","supply_shortage")
				or core_query(to,"containsTrick","YanxiaoCard")
				then continue end
				if core_query(self,"strategyProhibited",from,to,card)
				then else return true end
			end
		elseif core_query(card,"isKindOf","Snatch") then
			if core_query(from,"hasSkill","jizhi") then ignoreDistance = true end
			for _,to in sgs.list(self.enemies)do
				if not ignoreDistance and core_query(from,"distanceTo",to)>1 then continue end
				if core_query(self,"hasTrickEffective",card,to,from) and core_query(self,"doDisCard",to) then return true end
			end
		end
		if core_query(card,"getTypeId")>1 and core_query(from,"objectName")==core_query(self.player,"objectName")
		and core_query(self,"aiUseCard",card).card then return true end
	end
	return false
end


function SmartAIView:getRoleCountValue(role)
    local counts = core_query(self,"getRoleCounts")
    return value_known(counts[role],"role count "..role)
end
function SmartAIView:getRoleEvaluationValue(player, role)
    local policy = self.world and self.world.mode_policy
    local rows = policy and policy.role_values
    local row = rows and rows[player:objectName()]
    local value = row and row[role]
    if type(value)=="number" then return value end
    local inferred = core_query(self,"getRoleEstimate",player)
    return core_query(self,"useKnowledgeEstimate",{value=inferred==role and 1 or 0,status="estimate",viewer=self.player:objectName(),target=player:objectName(),
        basis="viewer role label substitutes missing legacy numerical role evaluation"},"getCardNeedPlayer.roleValue")
end
function SmartAIView:hasKnownExplicitRenegade()
    local policy = self.world and self.world.mode_policy
    if policy and type(policy.explicit_renegade)=="boolean" then return policy.explicit_renegade end
    local found=false
    for _, p in ipairs(core_query(self.room,"getAlivePlayers")) do if core_query(self,"getRoleEstimate",p)=="renegade" then found=true break end end
    return core_query(self,"useKnowledgeEstimate",{value=found,status="estimate",viewer=self.player:objectName(),
        basis="viewer inferred renegade substitutes missing explicit-renegade event marker"},"getCardNeedPlayer.explicitRenegade")
end
function SmartAIView:comesBefore(a,b)
    if a:objectName()==b:objectName() then return false end
    for _, p in ipairs(core_query(self.room,"getAllPlayers",true)) do
        if p:objectName()==a:objectName() then return true end
        if p:objectName()==b:objectName() then return false end
    end
    ai_unsupported("action-order player is missing","getCardNeedPlayer")
end

local function allocation_visible_hand(self, player)
    local facts = self.world and self.world.strategy_facts
    local scope = facts and facts.round31_choice
    local rows = scope and scope.visible_hand_ids
    local row = rows and rows[player:objectName()]
    if type(row) ~= "table" or row.known ~= true or not AIValue.isList(row.ids) then
        ai_unsupported("source visible-hand order/predicate is not projected", "findPlayerToDiscard")
    end
    local by_id, result, seen = {}, {}, {}
    for _, card in ipairs(allocation_query(player,"getKnownCards")) do
        by_id[allocation_query(card,"getEffectiveId")] = card
    end
    for _, id in ipairs(row.ids) do
        if type(id) ~= "number" or id < 0 or id % 1 ~= 0 or seen[id] or not by_id[id] then
            ai_unsupported("source visible-hand face is outside the lawful snapshot", "findPlayerToDiscard")
        end
        seen[id] = true
        result[#result+1] = by_id[id]
    end
    return result
end

local function allocation_callback(callback, ...)
    local value = callback(...)
    if AIUnsupported.is(value) then error(value, 0) end
    return value
end

function SmartAIView:getCardNeedPlayer(cards,include_self,tos)
	cards = cards or allocation_query(self.player,"getHandcards")
	tos = tos or include_self and allocation_query(self.room,"getAlivePlayers") or allocation_query(self.room,"getOtherPlayers",self.player)
	tos = sgs.QList2Table(tos)
	if #tos<1 then return end

	local pcs = allocation_query(self,"poisonCards",cards)

	local friends = {}
	for _,p in sgs.list(tos)do
		local exclude = allocation_query(self,"needKongcheng",p) or allocation_query(self,"willSkipPlayPhase",p)
		if	allocation_query(p,"getHp")-allocation_query(p,"getHandcardNum")>=3 or allocation_query(p,"hasSkills","keji|qiaobian|shensu")
		or allocation_query(p,"isLord") and allocation_query(self,"isWeak",p) and allocation_query(self,"getEnemyNumBySeat",self.player,p)>=1
		then exclude = false end
		local pl = allocation_query(self,"objectiveLevel",p)
		if pl<=-2 and not allocation_query(self,"hasManjuanEffect",p) and not exclude
		then table.insert(friends,p)
		elseif pl>=0 then
			for _,c in sgs.list(pcs)do
				if allocation_query(c,"getTypeId")<3 then return c,p end
			end
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and (allocation_query(self,"needKongcheng",AssistTarget,true) or allocation_query(self,"willSkipPlayPhase",AssistTarget) or allocation_query(AssistTarget,"hasSkill","manjuan"))
	then AssistTarget = nil end

	if allocation_query(self.player,"getRole")~="renegade" then
		local R_num = allocation_query(self,"getRoleCountValue","renegade")
		if R_num>0 and #friends>R_num then
			local k,temp_friends,new_friends = 0,{},{}
			for _,p in sgs.list(friends)do
				if k<R_num and allocation_query(self,"hasKnownExplicitRenegade") and allocation_query(self,"getRoleEstimate",p)=="renegade" then
					k = k+1
					if AssistTarget and allocation_query(p,"objectName")==allocation_query(AssistTarget,"objectName") then AssistTarget = nil end
				else table.insert(temp_friends,p) end
			end
			if k==R_num then
				friends = temp_friends
			else
				local cmp = function(a,b)
					local ar_value,br_value = allocation_query(self,"getRoleEvaluationValue",a,"renegade"),allocation_query(self,"getRoleEvaluationValue",b,"renegade")
					local al_value,bl_value = allocation_query(self,"getRoleEvaluationValue",a,"loyalist"),allocation_query(self,"getRoleEvaluationValue",b,"loyalist")
					return ar_value>br_value or ar_value==br_value and al_value>bl_value
				end
				table.sort(temp_friends,cmp)
				for _,p in sgs.list(temp_friends)do
					if k<R_num and allocation_query(self,"getRoleEvaluationValue",p,"renegade")>0 then
						if AssistTarget and allocation_query(p,"objectName")==allocation_query(AssistTarget,"objectName")
						then AssistTarget = nil end
						k = k+1
					else table.insert(new_friends,p) end
				end
				friends = new_friends
			end
		end
	end
	local specialnum = 0
	-- special move between liubei and xunyu and huatuo
	for _,p in sgs.list(friends)do
		if allocation_query(p,"hasSkill","jieming") or allocation_query(p,"hasSkill","jijiu")
		then specialnum = specialnum+1 end
		for _,c in sgs.list(pcs)do
			if allocation_query(c,"getTypeId")>2 then return c,p end
		end
	end
	if specialnum>1 and allocation_query(self.player,"getPhase")==sgs.Player_Play
	and allocation_query(self.player,"hasSkill","nosrende") then
		local xunyu = self.room:findPlayerBySkillName("jieming")
		local keptslash,cardtogivespecial = 0,{}
		for _,c in sgs.list(cards)do
			if isCard("Slash",c,self.player) then
				if xunyu and allocation_query(self.player,"canSlash",xunyu)
				and allocation_query(self,"slashIsEffective",c,xunyu) then keptslash = keptslash+1 end
				if keptslash>0 then table.insert(cardtogivespecial,c) end
			elseif isCard("Duel",c,self.player)
			then table.insert(cardtogivespecial,c) end
		end
		local redcardnum = 0
		for _,c in sgs.list(cardtogivespecial)do
			if allocation_query(c,"isRed") then redcardnum = redcardnum+1 end
		end
		local huatuo = self.room:findPlayerBySkillName("jijiu")
		if redcardnum>0 and xunyu and huatuo
		and allocation_query(self.player,"getHandcardNum")>#cardtogivespecial then
			for _,c in sgs.list(cardtogivespecial)do
				if allocation_query(c,"isRed") then return c,huatuo end
				return c,xunyu
			end
		end
	end

	allocation_query(self,"sort",friends)
	local cardtogive,keptjink = {},0
	for _,acard in sgs.list(cards)do
		if isCard("Jink",acard,self.player)
		and keptjink<1 then keptjink = keptjink+1
		else table.insert(cardtogive,acard) end
		for _,friend in sgs.list(friends)do
			if allocation_query(friend,"getHandcardNum")<3 and allocation_query(self,"isWeak",friend) then
				if allocation_query(acard,"isKindOf","Shit") then
				elseif isCard("Peach,Analeptic",acard,friend)
				or isCard("Jink",acard,friend) and allocation_query(self,"getEnemyNumBySeat",self.player,friend)>0
				then return acard,friend end
			end
		end
	end

	if allocation_query(self.player,"isWounded") and allocation_query(self.player,"getMark","nosrende")<2 and allocation_query(self.player,"hasSkill","nosrende") then
		if allocation_query(self.player,"getHandcardNum")<2 and allocation_query(self.player,"getMark","nosrende")<1 then return end
	end
	if allocation_query(self.player,"isWounded") and allocation_query(self.player,"getMark","rende")<2
	and allocation_query(self.player,"hasSkill","rende") and not allocation_query(self.player,"hasUsed","RendeCard") then
		if allocation_query(self.player,"getHandcardNum")<2 and allocation_query(self.player,"getMark","rende")<1 then return end

		if (allocation_query(self.player,"getHandcardNum")==2 and allocation_query(self.player,"getMark","rende")==0
		or allocation_query(self.player,"getHandcardNum")==1 and allocation_query(self.player,"getMark","rende")==1)
		and allocation_query(self,"getOverflow")<=0 then
			for _,enemy in sgs.list(self.enemies)do
				if allocation_query(enemy,"hasWeapon","GudingDlade")
				and (allocation_query(enemy,"canSlash",self.player) or allocation_query(enemy,"hasSkill","shensu") or allocation_query(enemy,"hasSkills","wushen|olwushen") or allocation_query(enemy,"hasSkill","jiangchi")) then return end
				if allocation_query(enemy,"canSlash",self.player,nil,true) and allocation_query(enemy,"hasSkill","nosqianxi") and allocation_query(enemy,"distanceTo",self.player)==1 then return end
			end
		end
	end

	-- Armor,DefensiveHorse
	for _,friend in sgs.list(friends)do
		if allocation_query(friend,"getHp")<=2 and allocation_query(friend,"faceUp") then
			for _,hcard in sgs.list(cards)do
				if allocation_query(hcard,"isKindOf","Armor") and not friend:getArmor() and not allocation_query(friend,"hasSkills","yizhong|bazhen")
				or allocation_query(hcard,"isKindOf","DefensiveHorse") and not friend:getDefensiveHorse()
				then return hcard,friend end
			end
		end
	end

	-- jijiu,jieyin
	cards = allocation_query(self,"sortByUseValue",cards,true)
	for _,friend in sgs.list(friends)do
		if allocation_query(friend,"getHandcardNum")<4 and allocation_query(friend,"hasSkills","jijiu|jieyin") then
			for _,h in sgs.list(cards)do
				if allocation_query(h,"isRed") and allocation_query(friend,"hasSkill","jijiu")
				or allocation_query(friend,"hasSkill","jieyin")
				then return h,friend end
			end
		end
	end

	--Crossbow
	for _,friend in sgs.list(friends)do
		if allocation_query(friend,"getHandcardNum")>=2 and allocation_query(friend,"hasSkills","longdan|ollongdan|wusheng|tenyearwusheng|keji|chixin")
		and not allocation_query(self,"hasCrossbowEffect",friend) then
			for _,hcard in sgs.list(cards)do
				if allocation_query(hcard,"isKindOf","Crossbow")
				then return hcard,friend end
			end
		end
	end

	for _,friend in sgs.list(friends)do
		if value_known(getKnownCard(friend,self.player,"Crossbow"),"allocation known Crossbow count")>0 then
			for _,p in sgs.list(self.enemies)do
				if allocation_query(self,"isGoodTarget",p,self.enemies,allocation_query(self,"cloneEvaluationCard","slash"))
				and allocation_query(friend,"distanceTo",p)<=1 then
					for _,hcard in sgs.list(cards)do
						if isCard("Slash",hcard,friend)
						then return hcard,friend end
					end
				end
			end
		end
	end
	local cmpByAction = function(a,b)
		return allocation_query(a,"objectName")~=allocation_query(b,"objectName") and allocation_query(self,"comesBefore",a,b)
	end
	table.sort(friends,cmpByAction)
	for _,friend in sgs.list(friends)do
		if allocation_query(friend,"faceUp") then
			local can_slash = false
			for _,p in sgs.list(self.enemies)do
				if allocation_query(self,"isGoodTarget",p,self.enemies,allocation_query(self,"cloneEvaluationCard","slash")) and allocation_query(friend,"distanceTo",p)<=allocation_query(friend,"getAttackRange")
				then can_slash = true break end
			end
			if not can_slash then
				local flag = string.format("weapon_done_%s_%s",allocation_query(self.player,"objectName"),allocation_query(friend,"objectName"))
				for _,p in sgs.list(self.enemies)do
					if allocation_query(self,"isGoodTarget",p,self.enemies,allocation_query(self,"cloneEvaluationCard","slash"))
					and allocation_query(friend,"distanceTo",p)>allocation_query(friend,"getAttackRange") then
						for _,hcard in sgs.list(cardtogive)do
							if allocation_query(hcard,"isKindOf","Weapon") and allocation_query(friend,"distanceTo",p)<=allocation_query(friend,"getAttackRange")+(sgs.weapon_range[allocation_query(hcard,"getClassName")] or 0)
							and not friend:getWeapon() and not allocation_query(self,"hasStrategyPlayerFlag",friend,flag) then
								self:setStrategyPlayerFlag(friend,flag,true)
								return hcard,friend
							end
							if allocation_query(hcard,"isKindOf","OffensiveHorse") and allocation_query(friend,"distanceTo",p)<=allocation_query(friend,"getAttackRange")+1
							and not friend:getOffensiveHorse() and not allocation_query(self,"hasStrategyPlayerFlag",friend,flag) then
								self:setStrategyPlayerFlag(friend,flag,true)
								return hcard,friend
							end
						end
					end
				end
			end
		end
	end

	local cmpByNumber = function(a,b)
		return allocation_query(a,"getNumber")>allocation_query(b,"getNumber")
	end
	table.sort(cardtogive,cmpByNumber)

	for _,friend in sgs.list(friends)do
		if allocation_query(friend,"faceUp") and not allocation_query(self,"needKongcheng",friend,true) then
			for _,askill in sgs.list(allocation_query(friend,"getVisibleSkillList",true))do
				local callback = sgs.ai_cardneed[allocation_query(askill,"objectName")]
				if type(callback)=="function" then
					for _,hcard in sgs.list(cardtogive)do
						if allocation_callback(callback,friend,hcard,self)
						then return hcard,friend end
					end
				end
			end
		end
	end

	-- shit
	for _,shit in sgs.list(cardtogive)do
		if allocation_query(shit,"isKindOf","Shit") then
			for _,friend in sgs.list(friends)do
				if allocation_query(self,"isWeak",friend) then
				elseif allocation_query(shit,"getSuit")==sgs.Card_Spade
				or allocation_query(friend,"hasSkill","jueqing") then
					if allocation_query(self,"hasZhaxiangEffect",friend) then return shit,friend end
				elseif allocation_query(friend,"hasSkills","guixin|jieming|yiji|nosyiji|chengxiang|noschengxiang|jianxiong")
				then return shit,friend end
			end
		end
	end

	-- slash
	if allocation_query(self.player,"getRole")=="lord" and allocation_query(self.player,"hasLordSkill","jijiang") then
		for _,friend in sgs.list(friends)do
			if allocation_query(friend,"getKingdom")=="shu" and allocation_query(friend,"getHandcardNum")<3 then
				for _,hcard in sgs.list(cardtogive)do
					if isCard("Slash",hcard,friend)
					then return hcard,friend end
				end
			end
		end
	end

	-- kongcheng
	allocation_query(self,"sort",self.enemies)
	if #self.enemies>0 and self.enemies[1]:isKongcheng() and allocation_query(self.enemies[1],"hasSkill","kongcheng")
	and not allocation_query(self,"hasManjuanEffect",self.enemies[1]) then
		for _,acard in sgs.list(cardtogive)do
			if allocation_query(acard,"isKindOf","Lightning") or allocation_query(acard,"isKindOf","Collateral") or (allocation_query(acard,"isKindOf","Slash") and allocation_query(self.player,"getPhase")==sgs.Player_Play)
			or allocation_query(acard,"isKindOf","OffensiveHorse") or allocation_query(acard,"isKindOf","Weapon") or allocation_query(acard,"isKindOf","AmazingGrace")
			then return acard,self.enemies[1] end
		end
	end

	if AssistTarget and table.contains(tos,AssistTarget) then
		for _,hcard in sgs.list(cardtogive)do
			return hcard,AssistTarget
		end
	end

	allocation_query(self,"sort",friends)
	for _,friend in sgs.list(friends)do
		if #cardtogive<1 then break end
		if not allocation_query(self,"needKongcheng",friend,true) and not allocation_query(friend,"hasSkill","manjuan")
		and not allocation_query(self,"willSkipPlayPhase",friend) and allocation_query(self,"hasSkills",sgs.priority_skill,friend)
		and (allocation_query(self,"getOverflow")>0 or allocation_query(self.player,"getHandcardNum")>3) and allocation_query(friend,"getHandcardNum")<=3
		then return cardtogive[1],friend end
	end

	local shoulduse = allocation_query(self.player,"isWounded") and (allocation_query(self.player,"hasSkill","rende") and not allocation_query(self.player,"hasUsed","RendeCard") and allocation_query(self.player,"getMark","rende")<2)
	or (allocation_query(self.player,"hasSkill","nosrende") and allocation_query(self.player,"getMark","nosrende")<2)

	if #cardtogive<1 and shoulduse then cardtogive = cards end

	allocation_query(self,"sort",friends,"handcard")
	for _,friend in sgs.list(friends)do
		if #cardtogive<1 then break end
		if not allocation_query(self,"needKongcheng",friend,true) and not allocation_query(friend,"hasSkill","manjuan") then
			if allocation_query(friend,"getHandcardNum")<=3 and (allocation_query(self,"getOverflow")>0 or allocation_query(self.player,"getHandcardNum")>3 or shoulduse)
			then return hcard,friend end
		end
	end

	for _,friend in sgs.list(friends)do
		if #cardtogive<1 then break end
		if (not allocation_query(self,"needKongcheng",friend,true) or #friends==1) and not allocation_query(friend,"hasSkill","manjuan") then
			if shoulduse or allocation_query(self.player,"getHandcardNum")>3 or allocation_query(self,"getOverflow")>0
			then return hcard,friend end
		end
	end

	for _,friend in sgs.list(tos)do
		if #cardtogive<1 then break end
		if allocation_query(self.room,"getTurnCount")>1 and (not allocation_query(self,"needKongcheng",friend,true) or #tos==1)
		and not allocation_query(self,"isEnemy",friend) and not allocation_query(self,"hasManjuanEffect",friend) then
			if allocation_query(self,"getOverflow")>0 or shoulduse
			then return hcard,friend end
		end
	end

	if #cardtogive>0 then cards = cardtogive end

	if #cards>0 and shoulduse then
		if allocation_query(self,"getRoleCountValue","rebel")<1 and allocation_query(self,"getRoleCountValue","loyalist")>0 and allocation_query(self.player,"isWounded")
		or allocation_query(self,"getRoleCountValue","rebel")>0 and allocation_query(self,"getRoleCountValue","renegade")>0 and allocation_query(self,"getRoleCountValue","loyalist")<1 and allocation_query(self,"isWeak") then
			allocation_query(self,"sort",tos)
			return cards[1],tos[1]
		end
	end
end


local function unique_players(players)
    if not AIValue.isList(players) then return nil end
    local result, seen = AIList.new({}), {}
    for _, player in ipairs(players) do
        if not AIValue.isPlayer(player) then return nil end
        local name = player:objectName()
        if not seen[name] then seen[name] = true; result:append(player) end
    end
    return result
end

function SmartAIView:canDraw(to,from)
	to = to or self.player
	if allocation_query(self,"needKongcheng",to,true) or allocation_query(self,"hasManjuanEffect",to)
		or allocation_query(to,"hasSkill","sfofl_suiqu") --add
	or allocation_query(self,"hasJieyingyEffect",to) and allocation_query(to,"getPhase")>4 and allocation_query(to,"getPhase")<7
	then return false end
	from = from or self.player
	return not allocation_query(self,"hasZhenguEffect",to,from)
end

function SmartAIView:findPlayerToDraw(include_self,drawnum,count)
	drawnum = drawnum or 1
	local friends,tos = {},{}
	for _,p in sgs.list(include_self and allocation_query(self.room,"getAlivePlayers") or allocation_query(self.room,"getOtherPlayers",self.player))do
		if allocation_query(self,"isFriend",p) and allocation_query(self,"canDraw",p) and allocation_query(self,"needDraw",p,drawnum)
		and not(drawnum<=2 and allocation_query(p,"isKongcheng") and allocation_query(p,"hasSkill","kongcheng"))
		then table.insert(friends,p) end
	end
	for _,p in sgs.list(include_self and allocation_query(self.room,"getAlivePlayers") or allocation_query(self.room,"getOtherPlayers",self.player))do
		if allocation_query(self,"isFriend",p) and allocation_query(self,"canDraw",p) and not table.contains(friends,p)
		and not(drawnum<=2 and allocation_query(p,"isKongcheng") and allocation_query(p,"hasSkill","kongcheng"))
		then table.insert(friends,p) end
	end

	allocation_query(self,"sort",friends)
	for _,friend in sgs.list(friends)do
		if allocation_query(friend,"getHandcardNum")<2 and not allocation_query(self,"needKongcheng",friend) and not allocation_query(self,"willSkipPlayPhase",friend) and allocation_query(self,"canDraw",friend) then
			if not table.contains(tos,friend) then table.insert(tos,friend) end
		end
	end

	local at = self:AssistTarget()
	if at and table.contains(friends,at) and not allocation_query(self,"willSkipPlayPhase",at) and allocation_query(self,"canDraw",at)
	and (allocation_query(at,"getHandcardNum")<allocation_query(at,"getMaxCards")*2 or allocation_query(at,"getHandcardNum")<allocation_query(self.player,"getHandcardNum")) then
		if not table.contains(tos,at) then table.insert(tos,at) end
	end

	for _,friend in sgs.list(friends)do
		if allocation_query(friend,"hasSkills",sgs.cardneed_skill) and not allocation_query(self,"willSkipPlayPhase",friend) and allocation_query(self,"canDraw",friend) then
			if not table.contains(tos,friend) then table.insert(tos,friend) end
		end
	end

	allocation_query(self,"sort",friends,"handcard")
	for _,friend in sgs.list(friends)do
		if not allocation_query(self,"needKongcheng",friend) and not allocation_query(self,"willSkipPlayPhase",friend) and allocation_query(self,"canDraw",friend) then
			if not table.contains(tos,friend) then table.insert(tos,friend) end
		end
	end
	return count and tos or tos[1]
end

-- R32: IsDis/getDamageValue are donor globals, not lexical recursion.
-- Keep same-request reentrant last-writer semantics in an active call tree.
-- No closures/facades survive the outer call; fixed-source readers are all
-- dominated by a reached assignment. Cross-request/viewer reuse is unavailable.
local r32_active_source_closures
local function r32_with_source_closures(self, callback)
    local request = self.request
    local active = r32_active_source_closures
    if active and (request == nil or not rawequal(active.request, request)
        or active.viewer ~= request.viewer or active.decision ~= request.decision_id
        or active.revision ~= request.state_revision) then
        ai_unsupported("source global closure reentry crosses request/viewer", "source_global_closure")
    end
    local outermost = active == nil
    if outermost then
        active = {request=request, viewer=request and request.viewer,
            decision=request and request.decision_id, revision=request and request.state_revision}
        r32_active_source_closures = active
    end
    local ok, result = pcall(callback, active)
    if outermost then r32_active_source_closures = nil end
    if not ok then error(result, 0) end
    return result
end

function SmartAIView:findPlayerToDiscard(flags,include_self,no_dis,players,reason)
    return r32_with_source_closures(self, function(r32_globals)
	local friends,enemies = {},{}
	if players then
		for _,p in sgs.list(players)do
			if allocation_query(self,"isEnemy",p) then table.insert(enemies,p)
			elseif allocation_query(self,"isFriend",p) and (include_self or allocation_query(p,"objectName")~=allocation_query(self.player,"objectName"))
			then table.insert(friends,p) end
		end
	else
		friends = include_self and self.friends or self.friends_noself
		enemies = self.enemies
	end
	flags = flags or "he"
	reason = reason or ""
	local player_table = {}
	no_dis = no_dis==false
	r32_globals.IsDis = function(from,to)
		if reason=="zhujinqiyuan" then
			if allocation_query(from,"distanceTo",to)>1
			then no_dis = false else no_dis = true end
		end
	end
	if type(flags)~="string" then return {} end
	allocation_query(self,"sort",enemies)

	if flags:contains("e") then
		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			local dangerous = allocation_query(self,"getDangerousCard",enemy)
			if dangerous and allocation_query(self,"doDisCard",enemy,dangerous,no_dis)
			then table.insert(player_table,enemy) end
		end
		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			if allocation_query(enemy,"hasArmorEffect","EightDiagram")
			and enemy:getArmor() and not allocation_query(self,"needToThrowArmor",enemy) then
				if allocation_query(self,"doDisCard",enemy,enemy:getArmor():getEffectiveId(),no_dis)
				then table.insert(player_table,enemy) end
			end
		end
	end
	if flags:contains("j") then
		for _,friend in sgs.list(friends)do
			r32_globals.IsDis(self.player,friend)
			if (allocation_query(friend,"containsTrick","indulgence") and not allocation_query(friend,"hasSkill","keji") or allocation_query(friend,"containsTrick","supply_shortage"))
			and (allocation_query(friend,"containsTrick","qhstandard_indulgence") and not allocation_query(friend,"hasSkill","keji") or allocation_query(friend,"containsTrick","supply_shortage"))
			and not allocation_query(friend,"containsTrick","YanxiaoCard") and not (allocation_query(friend,"hasSkill","qiaobian") and not allocation_query(friend,"isKongcheng"))
			and allocation_query(self,"doDisCard",friend,"j",no_dis)
			then table.insert(player_table,friend) end
		end
		for _,friend in sgs.list(friends)do
			r32_globals.IsDis(self.player,friend)
			if allocation_query(self,"hasWizard",enemies,true)
			and allocation_query(friend,"containsTrick","lightning")
			and allocation_query(self,"doDisCard",friend,"j",no_dis)
			then table.insert(player_table,friend) end
		end
		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			if allocation_query(self,"hasWizard",enemies,true)
			and allocation_query(enemy,"containsTrick","lightning")
			and allocation_query(self,"doDisCard",enemy,"j",no_dis)
			then table.insert(player_table,enemy) end
		end
	end
	if flags:contains("e") then
		for _,friend in sgs.list(friends)do
			r32_globals.IsDis(self.player,friend)
			if allocation_query(self,"doDisCard",friend,"e",no_dis)
			then table.insert(player_table,friend) end
		end
		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			if allocation_query(self,"doDisCard",enemy,"e",no_dis) then
				local valuable = allocation_query(self,"getValuableCard",enemy)
				if valuable and allocation_query(self,"doDisCard",enemy,valuable,no_dis)
				then table.insert(player_table,enemy) end
			end
		end
		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			if allocation_query(self,"hasSkills",sgs.need_equip_skill, enemy) then
				for _,e in sgs.list(allocation_query(enemy,"getEquips"))do
					if allocation_query(self,"doDisCard",enemy,allocation_query(e,"getId"),no_dis)
					then table.insert(player_table,enemy) break end
				end
			end
		end
		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			if allocation_query(enemy,"hasSkills","jijiu|beige|mingce|weimu|heg_qingcheng") then
				for _,e in sgs.list(allocation_query(enemy,"getEquips"))do
					if allocation_query(self,"doDisCard",enemy,allocation_query(e,"getId"),no_dis)
					then table.insert(player_table,enemy) break end
				end
			end
		end
	end
	if flags:contains("h") then
		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			if allocation_query(enemy,"getHandcardNum")<=2 and allocation_query(enemy,"getHandcardNum")>0
			and not(allocation_query(self,"hasTuntianEffect",enemy) and not allocation_query(enemy,"hasFlag","CurrentPlayer")) then
				local flag = string.format("%s_%s_%s","visible",allocation_query(self.player,"objectName"),allocation_query(enemy,"objectName"))
				for _,h in sgs.list(allocation_visible_hand(self,enemy))do
					if true
					and (allocation_query(h,"isKindOf","Peach") or allocation_query(h,"isKindOf","Analeptic"))
					and allocation_query(self,"doDisCard",enemy,allocation_query(h,"getEffectiveId"),no_dis)
					then table.insert(player_table,enemy) end
				end
			end
		end
	end
	if flags:contains("e") then
		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			if allocation_query(enemy,"hasEquip")
			and allocation_query(self,"doDisCard",enemy,"e",no_dis)
			then table.insert(player_table,enemy) end
		end
	end
	if flags:contains("j") then
		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			if allocation_query(self,"doDisCard",enemy,"j",no_dis)
			then table.insert(player_table,enemy) end
		end
	end
	if flags:contains("h") then
		allocation_query(self,"sort",enemies,"handcard")

		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			if allocation_query(self,"hasSkills",sgs.dont_kongcheng_skill, enemy) then
				if allocation_query(self,"doDisCard",enemy,"h",no_dis)
				then table.insert(player_table,enemy) end
			end
		end
		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			if allocation_query(self,"hasSkills",sgs.cardneed_skill, enemy) then
				if allocation_query(self,"doDisCard",enemy,"h",no_dis)
				then table.insert(player_table,enemy) end
			end
		end
		for _,enemy in sgs.list(enemies)do
			r32_globals.IsDis(self.player,enemy)
			if allocation_query(self,"doDisCard",enemy,"h",no_dis)
			then table.insert(player_table,enemy) end
		end
		local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
		if zhugeliang then
			r32_globals.IsDis(self.player,zhugeliang)
			if allocation_query(self,"isFriend",zhugeliang) and allocation_query(zhugeliang,"getHandcardNum")==1
			and allocation_query(self,"getEnemyNumBySeat",self.player,zhugeliang)>0 and allocation_query(zhugeliang,"getHp")<=2
			and allocation_query(self,"doDisCard",zhugeliang,"h",no_dis)
			then table.insert(player_table,zhugeliang) end
		end
		for _,friend in sgs.list(friends)do
			r32_globals.IsDis(self.player,friend)
			if allocation_query(self,"hasTuntianEffect",friend) then
				if allocation_query(self,"doDisCard",friend,"h",no_dis)
				then table.insert(player_table,friend) end
			end
		end
	end
	local new_player_table = {}	--有的角色重复加入了，需要去重
	for _,p in sgs.list(player_table)do
		if table.contains(new_player_table,p)
		then else table.insert(new_player_table,p) end
	end
	-- Add scoring function
    local function scoreTarget(player)
        local score = 0
        if allocation_query(self,"isEnemy",player) then
            score = score + 100
            score = score + allocation_query(player,"getHandcardNum") * 5
            if allocation_query(self,"getDangerousCard",player) then score = score + 50 end
            if allocation_query(self,"getValuableCard",player) then score = score + 30 end
        else
            -- Friend scoring for removing bad cards
            if allocation_query(player,"containsTrick","indulgence") or allocation_query(player,"containsTrick","supply_shortage") or allocation_query(player,"containsTrick","Dragon_indulgence") or allocation_query(player,"containsTrick","qhstandard_indulgence") then
                score = score + 80
            end
            if allocation_query(self,"hasTuntianEffect",player) then score = score + 20 end
        end
        return score
    end

    -- Sort by score descending
    table.sort(new_player_table, function(a, b)
        return scoreTarget(a) > scoreTarget(b)
    end)

    return new_player_table
    end)
end

-- Full smart-ai.lua:7344 donor algorithm; actual damage/relationship helpers
-- remain owner-provided dependencies. No native userdata or hidden hand reads.
local function damage_target_known(value, name)
    if value == nil then ai_unsupported("damage-target input is unknown", name) end
    return value
end
local function damage_target_call(object, method, ...)
    if not object or type(object[method]) ~= "function" then ai_unsupported("damage-target method is missing", method) end
    return damage_target_known(value_call(object,method,...), method)
end
function SmartAIView:findPlayerToDamage(damage,player,nature,targets,base_value,card)
    return r32_with_source_closures(self, function(r32_globals)
	damage = damage or 1
	base_value = base_value or 0
	targets = targets or self.room:getOtherPlayers(player)
	targets = sgs.QList2Table(damage_target_known(targets, "targets"))
	if #targets<2 then return targets end

	-- Auto-detect nature from card if not specified
	if card and not nature then
		nature = sgs.card_damage_nature[card:getClassName()] or "N"
	end
	nature = nature or "N"

	r32_globals.getDamageValue = function(target,self_only)
		-- Early validation checks using modern functions
		if not self_only then
			-- Check if damage is effective at all
			if not allocation_query(self, "damageIsEffective",target,nature,player) then
				return -999
			end

			-- Check comprehensive damage feasibility
			if allocation_query(self, "isEnemy",target) then
				if not allocation_query(self, "canDamage",target,player,card) then
					return -999  -- Can't damage this enemy effectively
				end
			elseif allocation_query(self, "isFriend",target) then
				-- For friends, check if we should avoid hurting them
				if allocation_query(self, "dontHurt",target,player) then
					return -999  -- Protected friend, don't damage
				end
				-- Only damage friends if they benefit from it
				local need_lose = allocation_query(self, "needToLoseHp",target,player,card,true)
				if not need_lose then
					return -999  -- Friend doesn't benefit from damage
				end
			end
		end

		local value,count = 0,allocation_query(self, "ajustDamage",player,target,damage,card,nature)
		if count>0 then
			value = value+count*20 --设1牌价值为10，且1体力价值2牌，1回合价值2.5牌，下同
			local hp = allocation_query(target, "getHp")
			local deathFlag = count>=hp and count>=hp+allocation_query(self, "getAllPeachNum",target)
			if deathFlag then
				value = value+500
			else
				if hp>=allocation_query(self, "getBestHp",target)+count then value = value-2 end
				if allocation_query(self, "isWeak",target) then value = value+15
				else value = value+12-allocation_query(self, "getDefense",target) end
				if hp<=count then
					if allocation_query(target, "faceUp") and allocation_query(target, "hasSkill","jiushi")
					then value = value+25 end
				end
				if allocation_query(self, "needToLoseHp",target,player,card) then
					value = value-5
					if allocation_query(target, "hasSkill","nosyiji") then value = value-20*count end
					if allocation_query(target, "hasSkill","yiji") then value = value-10*count end
					if allocation_query(target, "hasSkill","jieming") then
						local chaofeng = allocation_query(self, "getJiemingChaofeng",target)
						if chaofeng>0 then value = value-(5-chaofeng)*5
						else value = value+chaofeng*5 end
					end
					if allocation_query(target, "hasSkill","guixin") then
						local x = 0
						value = value+25
						for _,p in ipairs(self.room:getOtherPlayers(target))do
							if allocation_query(p, "getCardCount", true, true)>0 then
								if allocation_query(self, "isFriend",p,target)
								then if allocation_query(p, "getJudgingArea"):length()>0 then value = value-5 end
								elseif allocation_query(p, "isNude") then value = value+5 end
								x = x+1
							end
						end
						if not allocation_query(self, "hasManjuanEffect",target)
						then value = value-x*10 end
					end
					if allocation_query(target, "hasSkill","chengxiang") then value = value+15 end
					if allocation_query(target, "hasSkill","noschengxiang") then value = value+15 end
				end
                for _, sk in ipairs(damage_target_known(sgs.getPlayerSkillList(target), "source player skill list")) do
                    if allocation_query(sk, "inherits", "TriggerSkill") and allocation_query(sk, "hasEvent", sgs.Damaged) then value = value + 10 end
                end
				if count > 1 and allocation_query(self, "cantDamageMore",player, target) then
					value = value - 15
				end
			end
			if allocation_query(self, "isFriend",target) then value = -value
			elseif not allocation_query(self, "isEnemy",target) then value = value/2 end
			if self_only or nature=="N" then
			elseif allocation_query(target, "isChained") then
				for _,p in ipairs(self.room:getOtherPlayers(target))do
					if allocation_query(p, "isChained") then
						value = value+r32_globals.getDamageValue(p,true)
					end
				end
				--add
				if allocation_query(target, "hasSkill","kechengshishou") and allocation_query(target, "hasSkill","kechengcangchu") and allocation_query(target, "getMark","Qingchengkechengcangchu") == 0 and nature == "F" then value = value+15 end
			end
			if allocation_query(self, "cantbeHurt",target,player,count) then value = value-800 end
			if deathFlag and allocation_query(self.player, "getRole")=="renegade" and allocation_query(target, "isLord")
			and allocation_query(target, "aliveCount")>2 then value = value-1000 end
		end
		return value
	end
	local bcv = {}
	for _,p in ipairs(targets)do
		bcv[allocation_query(p, "objectName")] = r32_globals.getDamageValue(p)
	end
	local function func(a,b)
		return bcv[a:objectName()]>bcv[b:objectName()]
	end
	table.sort(targets,func)
	local result = {}
	for _,p in ipairs(targets)do
		if bcv[allocation_query(p, "objectName")]>base_value
		then table.insert(result,p) end
	end

	return result
    end)
end

function SmartAIView:findBestDamageTarget(damage, nature, min_value, card)
    damage = damage or 1
    nature = nature or "N"
    min_value = min_value or 5
    local targets = self:findPlayerToDamage(damage, self.player, nature, nil, min_value, card)
    if AIUnsupported.is(targets) then error(targets, 0) end
    return targets[1]
end

local function clone_scratch(value, depth, seen, budget)
    budget.n = budget.n - 1
    if budget.n < 0 or depth > 16 then ai_unsupported("scratch budget exceeded", "planning") end
    if type(value) ~= "table" then
        if type(value) ~= "nil" and type(value) ~= "boolean" and type(value) ~= "number"
            and type(value) ~= "string" then
            ai_unsupported("scratch must contain pure values", "planning")
        end
        return value
    end
    if getmetatable(value) ~= nil or seen[value] then
        ai_unsupported("scratch must be an acyclic pure value", "planning")
    end
    seen[value] = true
    local copy = {}
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            ai_unsupported("scratch key must be a value", "planning")
        end
        copy[key] = clone_scratch(item, depth + 1, seen, budget)
    end
    seen[value] = nil
    return copy
end

-- Revises use legacy positional ABIs. Merely registering an empty table never
-- supplies a strategy; only an explicit use.card proposal does.
function SmartAIView:useCardByClassName(card, use)
    local names = core_query(self, "getConnections", self.player)
    for _, name in ipairs(names) do
        local callback = self:getHooks("ai_skill_carduse")[name]
        if type(callback) == "function" then
            local value=callback(self,card,use)
            if AIUnsupported.is(value)then error(value,0)end
            if value==true then return true end
        end
    end
    local name = core_query(card, "getClassName")
    local method = self["useCard" .. name]
    -- Some migrated card families are registered pure policies rather than
    -- named methods. This adapter does not turn false/noncallable methods into
    -- a different strategy, nor add availability/target admission here.
    if method == nil then method = ai_card_use[name] end
    if method == ai_card_use.AOE then method = nil end
    if method then
        self.aiUsing = core_query(card, "getSubcards")
        return method(self, card, use)
    end
end

function SmartAIView:useBasicCard(card, use)
    self:useCardByClassName(card, use)
end
function SmartAIView:useEquipCard(card, use)
    return ai_card_use.EquipCard(self, card, use)
end
function SmartAIView:useTrickCard(card, use)
    if self:useCardByClassName(card, use) or use.card then return end
    if card:isKindOf("AOE") then return ai_card_use.AOE(self, card, use) end
end
local function dispatch_card_type(self, card, use)
    local kind = damage_call(card,"getTypeId")
    if kind == 1 then self:useBasicCard(card,use)
    elseif kind == 2 then self:useTrickCard(card,use)
    elseif kind == 3 then self:useEquipCard(card,use)
    else self:useSkillCard(card,use)
    end
end

function SmartAIView:targetRevises(use)
    if damage_call(use.card,"getTypeId") == 3 then return end
    local targets = {}
    if damage_call(use.card,"isKindOf","AOE") then
        for _, target in sgs.qlist(damage_call(self.room,"getAlivePlayers")) do
            if target ~= self.player and not damage_call(self.player,"isProhibited",target,use.card) then targets[#targets+1]=target end
        end
    elseif damage_call(use.card,"isKindOf","GlobalEffect") then
        for _, target in sgs.qlist(damage_call(self.room,"getAlivePlayers")) do
            if not damage_call(self.player,"isProhibited",target,use.card) then targets[#targets+1]=target end
        end
    elseif #use.to > 0 then
        for _, target in ipairs(use.to) do if target and damage_call(target,"isAlive") then targets[#targets+1]=target end end
    elseif damage_call(use.card,"targetFixed") then targets={self.player} end
    local rejected, original = {}, use.card
    for index, target in ipairs(targets) do
        local multiple, skip = #use.to > 1, false
        if multiple and damage_call(use.card,"isKindOf","SingleTargetTrick") then
            local candidate = strategy_candidate(self,use.card)
            if #use.to > 1+damage_call(candidate,"getExtraTargetCount",target) then
                skip = index%2 ~= 1
                multiple = #use.to > 2
            end
        end
        if not skip then
            local huangen = false
            if multiple and damage_call(use.card,"isKindOf","TrickCard") then
                local humanized = self.world and self.world.ai_humanized
                if humanized == nil then humanized = sgs.ai_humanized end
                humanized = damage_known(humanized,"target revise humanized configuration")
                huangen = (not humanized or math.random()<0.95) and damage_call(self,"isEnemy",target)
                    and damage_call(self,"hasHuangenEffect",target)
            end
            if huangen then rejected[#rejected+1]=target
            else
                local ignore = damage_card_flag(self,use.card,"Qinggang") or not damage_call(target,"hasArmorEffect",nil)
                for _, name in ipairs(core_query(self,"getConnections",target)) do
                    local isarmor = false
                    if ignore then
                        local facts = self.world and self.world.strategy_facts
                        local names = facts and facts.damage and facts.damage.armor_names
                        if names then isarmor = table.contains(names,name)
                        elseif type(sgs.armorName)=="table" then isarmor = sgs.armorName[name]
                        else ai_unsupported("public armor name catalog is unknown","targetRevises") end
                    end
                    if not isarmor then
                        local callback = self:getHooks("ai_target_revises")[name]
                        if type(callback)=="function" then
                            local value=callback(target,use.card,self,use)
                            if AIUnsupported.is(value)then error(value,0)end
                            if value then rejected[#rejected+1]=target;break end
                        end
                        if not self:sameLegacyCard(use.card, original) then return end
                    end
                end
            end
        end
    end
    if #rejected < 1 then return end
    -- The donor writes a Player property, not a scoped flag: successful reruns
    -- clear false (even if previously true), while an ordinary error preserves
    -- the reached true writes. The finite native observer retains only lawful
    -- same-viewer provenance; certified writes update the actual Player property without granting card authority.
    for _, target in ipairs(rejected) do
        if target and damage_call(target,"isAlive") then
            self:setTargetRevisesProperty(target,true)
        end
    end
    use.card, use.to = nil, AIList.new({})
    self.aiUsing = damage_call(original,"getSubcards")
    dispatch_card_type(self,original,use)
    for _, target in ipairs(rejected) do self:setTargetRevisesProperty(target,false) end
end

local function apply_use_revises(self, card, use, strategy)
    if core_query(card,"getTypeId") < 1 then
        self:useSkillCard(card,use)
        return
    end
    local owner_connections=core_query(self,"getConnections",self.player)
    local function pre(registry, names, player, with_target)
        for _,name in ipairs(names)do
            local callback=self:getHooks(registry)[name]
            if type(callback)=="function"then
                local value
                if with_target then value=callback(self,card,use,player)
                else value=callback(self,card,use)end
                if AIUnsupported.is(value)then error(value,0)end
                if type(value)=="boolean"then
                    if value then
                        if use.card then break end
                        self:useCardByClassName(card,use)
                    else return false end
                end
            end
        end
        return true
    end
    if not pre("ai_use_revises",owner_connections,self.player,false)then return end
    for _,player in sgs.qlist(core_query(self,"getCachedAlivePlayers"))do
        if not pre("ai_useto_revises",core_query(self,"getConnections",player),player,true)then return end
        for _,trick in sgs.qlist(core_query(player,"getJudgingArea"))do
            local callback=self:getHooks("ai_useto_revises")[core_query(trick,"objectName")]
            if type(callback)=="function"then
                local value=callback(self,card,use,player)
                if AIUnsupported.is(value)then error(value,0)end
                if type(value)=="boolean"then
                    if value then
                        if use.card then break end
                        self:useCardByClassName(card,use)
                    else return end
                end
            end
        end
    end
    if not use.card then
        self.aiUsing=core_query(card,"getSubcards")
        dispatch_card_type(self,card,use)
    end
    if use.card then
        self:targetRevises(use)
        if use.card and not use.isDummy then
            -- The source retains its original owner connection list, but reads
            -- each callback at the time it is reached (including mutations).
            for _,name in ipairs(owner_connections)do
                local callback=self:getHooks("ai_used_revises")[name]
                if type(callback)=="function"then
                    local humanized=self.world and self.world.ai_humanized
                    if humanized==nil then humanized=sgs.ai_humanized end
                    humanized=value_known(humanized,"used revise humanized configuration")
                    if not humanized or math.random()<0.95 then
                        local value=callback(self,use)
                        if AIUnsupported.is(value)then error(value,0)end
                    end
                end
            end
        end
    end
end

function SmartAIView:tryUseCard(card, use, evaluation, proposal_only)
    if not evaluation and not is_strategy_seed(card) and type(card) == "table" and type(card.isEvaluationOnly) == "function" and card:isEvaluationOnly() == true
        and not (proposal_only == true and readonly_turn_conversion(self, card)) then
        return AIUnsupported.new("evaluation cards cannot be submitted", "evaluation"), "unsupported"
    end
    if not AIValue.isCard(card) and not AIValue.isConversion(card) then
        return AIUnsupported.new("aiUseCard needs a card view"), "unsupported"
    end
    local strategy, key = find_card_use(card)
    -- Connected skill/revise callbacks may supply a proposal without a family
    -- strategy. Only run_strategy's final fallback can reject that path.
    key = key or card:objectName() or card:getClassName() or "unknown"
    self.request.scratch = self.request.scratch or {}
    local state = planning[self.request]
    if not state then
        local effective=type(self.getReadonlyPlayContext)=="function" and self:getReadonlyPlayContext() or nil
        effective=effective or self.request
        state = {depth = 0, candidates = 0, context = {
            kind = effective.kind, reason = effective.reason,
            pattern = effective.pattern, handling_method = effective.handling_method}}
        planning[self.request] = state
    end
    state.candidates = state.candidates + 1
    if state.depth >= 8 or state.candidates > 128 then
        return AIUnsupported.new("planning budget exceeded", "planning"), "unsupported"
    end
    -- Check coverage before a strategy can decline on an empty/partial projection.
    local offered = strategy_candidate(self, card)
    local qiuxin_source_query = evaluation == true
        and type(self.isAuditedExtra99SourceQueryPlan) == "function"
        and self:isAuditedExtra99SourceQueryPlan(card, use)
    if offered and not qiuxin_source_query and (offered:hasCompleteCoverage() ~= true
        or offered:getTargetCombinations() == nil) then
        return AIUnsupported.new("target combinations are incomplete", "targets"), "unsupported"
    end
    local parent = self.request.scratch or {}
    local copied, branch = AIUnsupported.capture(clone_scratch, parent, 0, {}, {n = 4096})
    if not copied then return branch, "unsupported" end
    use = use or AIUsePlan.new()
    use.to = use.to or AIList.new({})
    use.context = {}
    for k, v in pairs(state.context) do use.context[k] = v end
    use.scratch = branch
    branch.reserved_cards = branch.reserved_cards or {}
    branch.uses = branch.uses or {}
    branch.selected_targets = branch.selected_targets or {}
    local authority_card = type(card.getAuthorityCard) == "function" and card:getAuthorityCard() or card
    local costs = AIValue.isConversion(authority_card) and authority_card:getSubcards() or {authority_card:getEffectiveId()}
    if is_strategy_seed(card) or evaluation and type(card.isEvaluationOnly) == "function" and card:isEvaluationOnly() == true then costs = {} end
    for _, id in ipairs(costs or {}) do
        if branch.reserved_cards[id] then
            return AIUnsupported.new("a planning cost is already reserved", "planning"), "unsupported"
        end
        branch.reserved_cards[id] = true
    end
    branch.uses[key] = (branch.uses[key] or 0) + 1
    self.request.scratch = branch
    state.depth = state.depth + 1
    -- Always unwind, including programmer errors; pcall must not convert them to pass.
    local ok, signal = pcall(apply_use_revises, self, card, use, strategy)
    state.depth = state.depth - 1
    self.request.scratch = parent
    -- Estimated knowledge used during a probe still informs the final choice;
    -- retain its provenance after rolling back hypothetical card reservations.
    local prior_estimates = parent.knowledge_estimates or {}
    local estimates = branch.knowledge_estimates or {}
    if #estimates > #prior_estimates then
        parent.knowledge_estimates = prior_estimates
        for index = #prior_estimates + 1, #estimates do prior_estimates[#prior_estimates + 1] = estimates[index] end
    end
    if not ok then
        if AIUnsupported.is(signal) then return signal, "unsupported" end
        error(signal, 0)
    end
    -- Audited source-order planners may request this proposal. The donor
    -- appends callback output before activate selects its first card; rejecting
    -- an illegal proposal here would silently promote a later candidate. Other
    -- callers retain the existing validated-plan contract.
    if proposal_only == true then return use, use.card and "proposed" or "declined" end
    return self:validateStrategyUsePlan(use, branch, evaluation)
end


-- Validate a completed proposal without rerunning card strategies. Original
-- Hegemony directly dispatches card types; ordinary mode reaches this after
-- its revise pipeline. Neither route may borrow a different authority ticket.
function SmartAIView:validateStrategyUsePlan(use, branch, evaluation)
    branch = branch or {}
    if use.card == nil then return use, "declined" end
    if is_strategy_seed(use.card) then
        return AIUnsupported.new("strategy seed was not replaced by an authorized card", "candidate"), "unsupported"
    end
    if evaluation then
        -- Hypothetical use executes all strategy/revise stages, but has no
        -- submission ticket and can never be serialized into a real action.
        use._evaluation_only = true
        return use, "planned"
    end
    if type(use.card.isEvaluationOnly) == "function" and use.card:isEvaluationOnly() == true then
        return AIUnsupported.new("evaluation cards cannot be submitted", "evaluation"), "unsupported"
    end
    branch.selected_targets = {}
    for i, target in ipairs(use.to) do branch.selected_targets[i] = target:objectName() end
    local candidate = authority_candidate(self, use.card)
    if not candidate then
        return AIUnsupported.new("proposed card has no authority candidate", "candidate"), "unsupported"
    end
    local is_conversion = AIValue.isConversion(use.card)
    if AIValue.isConversion(candidate) ~= is_conversion then
        return AIUnsupported.new("proposal and authority ticket kinds differ", "candidate"), "unsupported"
    end
    if type(candidate.isAvailable) ~= "function" or candidate:isAvailable() ~= true then
        return AIUnsupported.new("proposed card is unavailable or availability is unknown", "candidate"), "unsupported"
    end
    -- Conversion availability already includes its activation/cost restrictions;
    -- physical candidates carry a separate authoritative MethodUse limit bit.
    if not is_conversion and (type(candidate.isLimited) ~= "function" or candidate:isLimited() ~= false) then
        return AIUnsupported.new("proposed card is limited or limits are unknown", "candidate"), "unsupported"
    end
    if is_conversion then
        local proposed, authority = use.card:toCardSpec(), candidate:toCardSpec()
        for _, field in ipairs({"name", "suit", "number", "skill"}) do
            if proposed[field] ~= authority[field] then
                return AIUnsupported.new("proposed conversion identity does not match its authority ticket", "conversion"), "unsupported"
            end
        end
        local valid = self:validatePlannedIntent("cost", {
            conversion_id = authority.conversion_id, subcards = proposed.subcards})
        if valid ~= true then
            return AIUnsupported.new("proposed conversion costs do not match its authority ticket", "conversion"), "unsupported"
        end
    end
    if candidate then
        if candidate:hasCompleteCoverage() ~= true then
            return AIUnsupported.new("target combinations are incomplete", "targets"), "unsupported"
        end
        if candidate:targetFixed() then
            if #use.to ~= 0 or candidate:isFeasibleWithNoTarget() ~= true then
                return AIUnsupported.new("strategy proposed an illegal target sequence", "targets"), "unsupported"
            end
        else
            local _, finish = candidate:getTargetSelection(branch.selected_targets)
            if finish ~= true then
                return AIUnsupported.new("strategy proposed an illegal target sequence", "targets"), "unsupported"
            end
        end
    end
    -- A revise may replace the original card. Its final ticket, never the input
    -- candidate's ticket, belongs in the answer. Conversions serialize their own.
    use.candidate_id = nil
    if not is_conversion and type(candidate.getCandidateId) == "function" then
        use.candidate_id = candidate:getCandidateId()
    end
    return use, "planned"
end

-- Choose only whole authority-approved sequences. Ranking stays in rankTargets;
-- this helper does no targetFilter/distance simulation and cannot invent pairs.
function SmartAIView:planTargetSequence(candidate, stance, accept)
    local page, cursor = candidate:getTargetCombinations()
    if not page then ai_unsupported("target combinations are incomplete", "targets") end
    local names, seen, rows = {}, {}, {}
    repeat
        for _, row in ipairs(page) do
            rows[#rows + 1] = row
            for _, name in ipairs(row) do
                if not seen[name] then seen[name] = true names[#names + 1] = name end
            end
        end
        if cursor then page, cursor = candidate:getTargetCombinations(cursor) else break end
    until false
    local ranked = self:rankTargets(names, stance)
    if not ranked then ai_unsupported("target relations are unknown", "targets") end
    local score, players = {}, {}
    for i, player in ipairs(ranked) do
        local name = player:objectName()
        score[name], players[name] = #ranked - i + 1, player
    end
    local best, best_score
    for _, row in ipairs(rows) do
        local value, chosen = 0, AIList.new({})
        for _, name in ipairs(row) do
            local excluded = self.request.scratch and self.request.scratch.revised_targets
            local accepted = true
            if accept and score[name] and not (excluded and excluded[name]) then
                accepted = accept(players[name])
                if accepted == nil then ai_unsupported("target acceptance is unknown", "targets") end
            end
            if not score[name] or (excluded and excluded[name]) or not accepted then value = nil break end
            value = value + score[name]
            chosen:append(players[name])
        end
        if value and #chosen > 0 and (not best_score or value > best_score) then
            best, best_score = chosen, value
        end
    end
    return best
end

if type(ai_coverage) == "table" then
    ai_coverage.declare("card_use", function()
        local keys = {}
        for key in pairs(ai_card_use) do keys[#keys + 1] = key end
        return keys
    end)
end

-- Standard-card policies below preserve SmartAI's branch order. Authority
-- supplies legality; strategy helpers only rank visible state and AI estimates.
local function plan_query(object, method, ...)
    return core_query(object,method,...)
end
local function plan_groups(self)
    local friends = self.friends or plan_query(self, "getFriends")
    local enemies = self.enemies or plan_query(self, "getEnemies")
    if self.friends_noself then return friends,enemies,self.friends_noself end
    local others = AIList.new({})
    for _, friend in ipairs(friends) do
        if friend:objectName() ~= self.player:objectName() then others:append(friend) end
    end
    return friends, enemies, others
end
local function same_player(a, b)
    return a ~= nil and b ~= nil and a:objectName() == b:objectName()
end
local function player_in(players, target)
    for _, player in ipairs(players or {}) do if same_player(player, target) then return true end end
    return false
end
local function current_target(use, target)
    for _, player in ipairs(use.current_targets or {}) do
        if player == target:objectName() or type(player) == "table" and same_player(player, target) then return true end
    end
    return false
end
local function plan_can_to(self, card, target)
    local candidate = strategy_candidate(self, card)
    if not candidate then ai_unsupported("target-filter projection is missing", "card_use") end
    -- CanToCard(card,from,to) in addFunction.lua calls targetFilter with an
    -- empty prefix. Its exact native fact is independent of whether bounded
    -- enumeration covered every final target combination (e.g. Zenhui +99).
    -- plan_query still rejects an absent fact instead of guessing a target.
    return plan_query(candidate, "canTargetWithEmptyPrefix", target)
end
local function plan_extra(self, card, use)
    local candidate = strategy_candidate(self, card)
    return plan_query(candidate, "getExtraTargetCount") + (use.extra_target or 0)
end
local function plan_estimate(self, name, player)
    return plan_query(self, "estimateCardsNum", name, player)
end
local function plan_role(self, player)
    if same_player(player, self.player) then return plan_query(player, "getRole") end
    return plan_query(self, "assessedRole", player)
end
local function plan_set_player_flag(self, name)
    if type(self.setStrategyPlayerFlag) ~= "function" then
        ai_unsupported("strategy flag lifecycle is not projected", name)
    end
    self:setStrategyPlayerFlag(self.player, name, true)
end
local function plan_has_player_flag(self, name)
    if type(self.hasStrategyPlayerFlag) == "function" then
        return value_known(self:hasStrategyPlayerFlag(self.player,name), "strategy player flag")
    end
    return plan_query(self.player,"hasFlag",name)
end
local function plan_chain(self, target, source)
    if plan_query(target, "isChained") then return true end
    if plan_query(target, "hasSkill", "qianjie") then return false end
    return source ~= nil and plan_query(source, "hasWeapon", "wutiesuolian") or false
end
local function plan_water(self)
    return plan_query(self, "hasWulingEffect", "@water")
end

ai_card_use.Slash = function(self, card, use)
    local friends, enemies, noself = plan_groups(self)
    local extra = plan_extra(self, card, use)
    local function add(target)
        if current_target(use, target) or player_in(use.to, target) then return end
        if plan_query(target, "isAiNoTo") then return end
        if use.card and not self:sameLegacyCard(use.card, card) then extra = plan_extra(self, use.card, use) end
        if #use.to > extra then return true end
        local actual = use.card or card
        if plan_can_to(self, actual, target) and not plan_query(self, "slashProhibit", actual, target, self.player)
            and plan_query(self, "slashIsEffective", actual, target, self.player)
            and plan_query(self, "ajustDamage", self.player, target, 1, actual) ~= 0 then
            if card:isKindOf("NatureSlash") and plan_chain(self, target, self.player) then
                if not plan_query(self, "isGoodChainTarget", target, card) then return end
            end
            use.card = card
            use.to:append(target)
        end
    end
    local role = plan_role(self, self.player)
    for _, friend in ipairs(noself) do
        if plan_role(self, friend) == role and plan_query(self, "isPriorFriendOfSlash", friend, use.card or card) and add(friend) then return end
    end
    local forbidden = {}
    enemies = plan_query(self, "sort", enemies, "defenseSlash")
    for _, enemy in ipairs(enemies) do
        if plan_query(self, "isGoodTarget", enemy, enemies, use.card or card) then
            if plan_query(self, "objectiveLevel", enemy) <= 3 or plan_query(self, "hasQiuyuanEffect", self.player, enemy) then
                forbidden[#forbidden + 1] = enemy
            elseif add(enemy) then return end
        end
    end
    for _, friend in ipairs(noself) do
        local actual = use.card or card
        if plan_role(self, friend) == role and plan_query(actual, "getSkillName") ~= "lihuo"
            and not (plan_query(friend, "isLord") and #enemies < 1)
            and plan_query(self, "needToLoseHp", friend, self.player, actual, true)
            and plan_query(self, "ajustDamage", self.player, friend, 1, actual) == 1 and add(friend) then return end
    end
    for _, target in ipairs(forbidden) do if add(target) then return end end
end

ai_card_use.Peach = function(self, card, use)
    local friends, enemies, noself = plan_groups(self)
    local player, lord = self.player, self.room:getLord()
    if plan_role(self, player) == "loyalist" and lord and not same_player(lord, player)
        and plan_query(self, "isWeak", lord) and plan_query(player, "getHp") > 1 then
        local mine, theirs = plan_query(self, "getDefense", player), plan_query(self, "getDefense", lord)
        local overflow, peaches = plan_query(self, "getOverflow"), plan_query(self, "getCardsNum", "Peach")
        if theirs - mine < 0 and overflow < 2 and peaches <= 1 then
            if math.random() < math.min(0.3 + math.abs(theirs - mine) * 0.1, 0.8) then return end
        end
    end
    for _, enemy in ipairs(enemies) do
        -- Parentheses in the source place the whole OR inside hasSkills;
        -- drawpeach_skill is a string and therefore wins before every later OR.
        if plan_query(player, "getHandcardNum") < 3 then
            if type(sgs.drawpeach_skill) ~= "string" then ai_unsupported("drawpeach skill category is missing", "Peach") end
            if plan_query(enemy, "hasSkills", sgs.drawpeach_skill) then use.card = card return end
        end
    end
    if (not (lord and plan_query(self, "isFriend", lord) and plan_query(self, "isWeak", lord)) and plan_query(player, "getHp") < 2)
        or (plan_query(player, "getLostHp") >= 2 and plan_water(self))
        or plan_query(self, "getCardsNum", "Peach", "h") > plan_query(player, "getHp")
        or not plan_query(player, "hasCard", card) then use.card = card return end
    local overflow = plan_query(self, "getOverflow")
    if overflow < 1 and #noself > 0 or plan_query(self, "needToLoseHp", player, nil, card, nil, true) then return end
    if lord and plan_query(lord, "getHp") <= 2 and plan_query(self, "isFriend", lord) and plan_query(self, "isWeak", lord) then
        if same_player(player, lord) or plan_query(self, "getCardsNum", "Peach") > 1
            and plan_query(self, "getCardsNum", "Peach,Jink") > plan_query(player, "getMaxCards") then use.card = card end
        return
    end
    friends = plan_query(self, "sort", friends, "hp")
    if #friends > 0 and same_player(friends[1], player) or plan_query(player, "getHp") < 2 then use.card = card return end
    if #friends > 1 then
        local function buqu(friend)
            if type(hasBuquEffect) ~= "function" then ai_unsupported("Buqu evaluator is missing", "Peach") end
            return value_known(hasBuquEffect(friend), "Buqu effect")
        end
        if not buqu(friends[2]) and plan_query(friends[2], "getHp") < 3 and overflow < 2
            or not buqu(friends[1]) and plan_query(friends[1], "getHp") < 2
                and plan_query(self, "getCardsNum", "Peach", "h") <= 1 and overflow < 3 then return end
    end
    use.card = card
end

function SmartAIView:useCardPeach(card, use)
    return ai_card_use.Peach(self, card, use)
end
function SmartAIView:useCardSlash(card, use)
    return ai_card_use.Slash(self, card, use)
end

function SmartAIView:JijiangSlash(player)
    if not player then return 0 end
    if not plan_query(player, "hasLordSkill", "jijiang") then return 0 end
    local total = 0
    for _, other in ipairs(plan_query(self.room, "getOtherPlayers", player)) do
        local count = plan_estimate(self, "Slash", other)
        if plan_query(other, "getKingdom") == "shu" and count >= 1 and
            (plan_query(self.room, "getTurnCount") <= 1 and plan_role(self, other) == "neutral"
                or plan_query(self, "isFriend", player, other)) then total = total + count end
    end
    return total
end

ai_card_use.Duel = function(self, card, use)
    local _, enemies = plan_groups(self)
    self.aiUsing = plan_query(card, "getSubcards")
    local mine = plan_query(self, "getCardsNum", "Slash")
    if plan_query(self.player, "hasSkill", "sfofl_boss_wushuang") then mine = 999 end
    if plan_query(self.player, "hasSkill", "wushuang") or use.isWuqian then mine = mine * 2 end
    local extra = plan_extra(self, card, use)
    if use.xiechan then extra = 100 end
    enemies = plan_query(self, "sort", enemies)
    local total, scores = 0, {}
    local function record(enemy)
        if plan_query(self.player, "getPhase") <= sgs.Player_Play and math.random() < 0.5 then
            -- The source sets an AI flag; retain only this viewer's named state.
            plan_set_player_flag(self,"duelTo_" .. enemy:objectName())
        end
        use.card = card
        use.to:append(enemy)
        return #use.to > extra
    end
    for _, enemy in ipairs(enemies) do
        scores[enemy:objectName()] = 0
        if not current_target(use, enemy) then
            local count = plan_estimate(self, "Slash", enemy)
            local flagged = plan_has_player_flag(self,"duelTo_" .. enemy:objectName())
            local skip = false
            if flagged and plan_can_to(self, card, enemy) and plan_query(self, "ajustDamage", self.player, enemy, 1, card) ~= 0 then
                if plan_query(enemy, "hasSkill", "wushuang") then count = count * 2 end
                total = total + count
                if mine < total and count > 0 then skip = true elseif record(enemy) then return end
            end
            if not skip then
                count = count + plan_query(enemy, "getHp")
                if not plan_query(self, "isWeak", enemy) and plan_query(enemy, "hasSkill", "jianxiong")
                    and not plan_query(self, "hasJueqingEffect", self.player, enemy) then count = count + 10 end
                if plan_query(self, "needToLoseHp", enemy, nil, card) then count = count + 15 end
                if plan_query(enemy, "hasSkills", sgs.masochism_skill) then count = count + 5 end
                if not plan_query(self, "isWeak", enemy) and plan_query(enemy, "hasSkill", "jiang") then count = count + 5 end
                if plan_query(enemy, "hasLordSkill", "jijiang") then count = count + self:JijiangSlash(enemy) * 2 end
                scores[enemy:objectName()] = count
            end
        end
    end
    table.sort(enemies, function(a, b) return scores[a:objectName()] < scores[b:objectName()] end)
    for _, enemy in ipairs(enemies) do
        if not current_target(use, enemy) and not player_in(use.to, enemy) and plan_can_to(self, card, enemy)
            and plan_query(self, "objectiveLevel", enemy) > 3 and plan_query(self, "isGoodTarget", enemy, enemies, card)
            and plan_query(self, "ajustDamage", self.player, enemy, 1, card) ~= 0 then
            local count = plan_estimate(self, "Slash", enemy)
            if plan_query(enemy, "hasSkill", "wushuang") then count = count * 2 end
            total = total + count
            if mine >= total or plan_query(self, "needToLoseHp", self.player, nil, card, true) or count < 1
                or plan_query(self.player, "hasSkill", "jianxiong") or plan_query(self.player, "hasShuangxiongColors") then
                if record(enemy) then return end
            end
        end
    end
end

local function plan_strip(self, card, use, obtain)
    local friends, enemies, noself = plan_groups(self)
    local extra = plan_extra(self, card, use)
    local function add(target, id)
        if current_target(use, target) or id == nil or player_in(use.to, target) then return end
        if not obtain and type(id) ~= "number" and not (type(id)=="table" and id.kind=="hand_discard_sample") then
            id = plan_query(id, "getEffectiveId")
        end
        if plan_query(self, "doDisCard", target, id, obtain or nil) then
            use.card = card
            use.to:append(target)
            return #use.to > extra
        end
    end
    local players = AIList.new({})
    for _, player in ipairs(plan_query(self.room, "getOtherPlayers", self.player)) do
        if plan_query(self.player, "canUse", card, player) then players:append(player) end
    end
    local classical = true
    if not obtain and plan_query(self.room, "getMode") == "02_1v1" then
        classical = plan_query(self.room, "getDuelRule") == "Classical"
    end
    if obtain or classical then
        for _, player in ipairs(players) do
            for _, trick in ipairs(plan_query(player, "getJudgingArea")) do
                if plan_query(trick, "isDamageCard") and not plan_query(player, "containsTrick", "YanxiaoCard") then
                    local prefer
                    if obtain then prefer = #friends > #enemies or plan_query(self, "getFinalRetrial", player) == 2
                    else prefer = plan_query(self, "getFinalRetrial", player) == 2 or #friends > #enemies end
                    if prefer and add(player, trick:getEffectiveId()) then return end
                end
            end
        end
    end
    local slash = self:getCard("Slash")
    if slash then
        local candidate = self:getCardCandidate(slash:getEffectiveId())
        if plan_query(candidate, "isAvailable") then
            local planned, status = self:tryUseCard(slash)
            if status == "unsupported" then error(planned, 0) end
            if status == "planned" and planned.card then
                for _, target in ipairs(planned.to) do
                    if player_in(players, target) and plan_query(target, "getHp") <= 2
                        and plan_query(target, "getHandcardNum") <= target:getHp() and not plan_query(self, "needKongcheng", target) then
                        local id = obtain and "h" or plan_query(self, "randomHandDiscardToken", target)
                        if add(target, id) then return end
                    end
                end
            end
        end
    end
    players = plan_query(self, "sort", players, "defense")
    for _, player in ipairs(players) do
        if plan_query(player, "hasEquip") and add(player, self:getDangerousCard(player)) then return end
    end
    noself = plan_query(self, "sort", noself, "defense")
    if obtain or classical then
        for _, friend in ipairs(noself) do
            if player_in(players, friend) then
                for _, item in ipairs(plan_query(friend, "getCards", "ej")) do
                    if item:isKindOf("Indulgence") then
                        if (plan_query(friend, "getHp") <= plan_query(friend, "getHandcardNum") or plan_query(friend, "isLord"))
                            and add(friend, item:getEffectiveId()) then return end
                    elseif add(friend, item:getEffectiveId()) then return end
                end
            end
        end
        for _, player in ipairs(players) do
            local judges = plan_query(player, "getJudgingArea")
            for _, trick in ipairs(judges) do
                if trick:isKindOf("YanxiaoCard") and #judges > 1 and add(player, trick:getEffectiveId()) then return end
            end
        end
    end
    for _, player in ipairs(players) do
        local count = 0
        -- Original iterates handcards but inspects only visible flags. The
        -- viewer-scoped known-hand list is precisely that visible subset.
        for _, hand in ipairs(plan_query(player, "getKnownCards")) do
            if (plan_query(hand, "hasFlag", "visible") or plan_query(hand, "hasFlag", "visible_" .. self.player:objectName() .. "_" .. player:objectName()))
                and isCard("Peach,Analeptic", hand, player) then
                count = count + 1
                if count >= plan_query(player, "getHandcardNum") / 2 and add(player, hand:getEffectiveId()) then return end
            end
        end
    end
    for _, friend in ipairs(noself) do
        if player_in(players, friend) then
            for _, equip in ipairs(plan_query(friend, "getEquips")) do if add(friend, equip:getEffectiveId()) then return end end
        end
    end
    for _, player in ipairs(players) do
        for _, equip in ipairs(plan_query(player, "getEquips")) do if add(player, equip:getEffectiveId()) then return end end
    end
    local function hand_target(player)
        if obtain then return add(player, "h") end
        return add(player, plan_query(self, "randomHandDiscardToken", player))
    end
    for _, player in ipairs(players) do
        if plan_query(player, "getHandcardNum") > 0 and plan_query(player, "hasSkills", sgs.cardneed_skill) and hand_target(player) then return end
    end
    if obtain then
        for _, player in ipairs(players) do if plan_query(player, "getHandcardNum") > 0 and hand_target(player) then return end end
    elseif plan_query(self, "getOverflow") > 0 then
        for _, stance in ipairs({"enemy", "not_friend", "any"}) do
            for _, player in ipairs(players) do
                if plan_query(player, "getHandcardNum") > 0 then
                    local matches = stance == "any"
                    if not matches then
                        if stance == "enemy" then matches = plan_query(self, "isEnemy", player)
                        else matches = not plan_query(self, "isFriend", player) end
                    end
                    if matches and hand_target(player) then return end
                end
            end
        end
    end
end
ai_card_use.Snatch = function(self, card, use) return plan_strip(self, card, use, true) end
ai_card_use.Dismantlement = function(self, card, use) return plan_strip(self, card, use, false) end

-- Explicit effect callbacks remain available to extension-defined policies.
ai_card_effect = ai_card_effect or {}

ai_card_use.AmazingGrace = function(self, card, use)
    local role = plan_role(self, self.player)
    if (role == "lord" or role == "loyalist") and plan_query(self.room, "getTurnCount") <= 2
        and plan_query(self.player, "getSeat") <= 3 and plan_query(self.player, "aliveCount") > 5 then return end
    local value, factor, coefficient = 1, 0.8, 0.8
    if plan_query(self, "needKongcheng") and plan_query(self.player, "getHandcardNum") == 1
        or plan_query(self.player, "hasSkills", "nosjizhi|jizhi") then factor, coefficient = 0.6, 0.6 end
    for _, player in ipairs(plan_query(self.room, "getOtherPlayers", self.player)) do
        local index = 0
        if plan_query(self.player, "canUse", card, player) then
            if plan_query(self, "isFriend", player) then index = 1
            elseif plan_query(self, "isEnemy", player) then index = -1 end
        end
        value = value + index * factor
        if value < 0 then return end
        factor = factor * coefficient
    end
    use.card = card
end

function SmartAIView:willUseGodSalvation(card)
    if not card then return false end
    local friends, enemies = plan_groups(self)
    local huangen = self.room:findPlayerBySkillName("huangen")
    local wounded_friend, wounded_enemy, good, bad = 0, 0, 0, 0
    if huangen then
        if plan_query(self, "isFriend", huangen) then
            if plan_query(self.player, "hasSkill", "noswuyan") and plan_query(huangen, "getHp") > 0 then return true end
            good = good + 7 * plan_query(huangen, "getHp")
        else
            if plan_query(self.player, "hasSkill", "noswuyan") and plan_query(self, "isEnemy", huangen)
                and plan_query(huangen, "getHp") > 1 and #enemies > 1 then return false end
            bad = bad + 7 * plan_query(huangen, "getHp")
        end
    end
    if plan_query(self.player, "hasSkills", "nosjizhi|jizhi") then good = good + 6 end
    if plan_query(self.player, "hasSkill", "kongcheng") and plan_query(self.player, "isLastHandCard", card)
        or not plan_query(self, "hasLoseHandcardEffective") then good = good + 5 end
    local function score(player)
        local value = 10 * plan_estimate(self, "Nullification", player)
        local wounded = false
        if plan_query(self.player, "canUse", card, player) then
            if plan_query(player, "isWounded") then
                wounded, value = true, value + 10
                local lord, hp = plan_query(player, "isLord"), plan_query(player, "getHp")
                if lord then value = value + 10 / math.max(hp, 1) end
                if plan_query(self, "hasSkills", sgs.masochism_skill, player) then value = value + 5 end
                if hp <= 1 and plan_query(self, "isWeak", player) then
                    value = value + 5
                    if lord then value = value + 10 end
                elseif lord then value = value + 5 end
                if plan_query(self, "needToLoseHp", player, nil, card, true, true) then value = value - 3 end
            elseif plan_query(player, "hasSkill", "danlao") then value = value + 5 end
        end
        return value, wounded
    end
    for _, friend in ipairs(friends) do
        local value, wounded = score(friend)
        good = good + value
        if wounded then wounded_friend = wounded_friend + 1 end
    end
    for _, enemy in ipairs(enemies) do
        local value, wounded = score(enemy)
        bad = bad + value
        if wounded then wounded_enemy = wounded_enemy + 1 end
    end
    return good - bad > 5 and wounded_friend > 0
        or wounded_friend + wounded_enemy < 1 and plan_query(self.player, "hasSkills", "nosjizhi|jizhi")
end
ai_card_use.GodSalvation = function(self, card, use)
    if self:willUseGodSalvation(card) then use.card = card end
end

ai_card_use.EquipCard = function(self, card, use)
    local friends, enemies, noself = self.friends, self.enemies, self.friends_noself
    local armor = plan_query(self, "evaluateArmor", card)
    if plan_query(self.player, "getHandcardNum") <= 1 and armor > -5 and plan_query(self, "needKongcheng")
        or armor > -5 and #enemies > 1 and plan_query(self, "loseEquipEffect") then use.card = card return end
    local same = self:getSameEquip(card)
    if same and plan_query(self, "hasSkills", "guzheng", friends) and plan_query(self, "evaluateArmor", same) > -5 then return end
    if self:useCardByClassName(card, use) then return end
    local overflow = plan_query(self, "getOverflow")
    if card:isKindOf("Weapon") then
        local available = plan_query(self, "slashIsAvailable", nil, false)
        if overflow <= (available and 1 or 0) then
            if not (available or plan_query(self.player, "hasWeapon", "Crossbow") or plan_query(self, "needKongcheng")) then return end
        end
        if same and overflow > 0 and self:getPriorTurnUseCount() < 2
            and plan_query(self, "evaluateWeapon", card) >= plan_query(self, "evaluateWeapon", same) then use.card = card return end
    elseif card:isKindOf("Armor") then
        if card:isKindOf("SilverLion") and plan_query(self.player, "isWounded") and not plan_query(self.player, "hasArmorEffect", nil) then use.card = card return end
        if armor > 0 and plan_query(self.player, "hasArmorEffect", "SilverLion") then
            local peach = value_known(value_call(self, "getEvaluationCard", "peach"), "Peach evaluation descriptor")
            local peach_use = self:evaluateCard(peach)
            if peach_use.card then use.card = card return end
        end
        if not same and armor > 0 and plan_query(self, "isWeak") then use.card = card return end
    elseif card:isKindOf("OffensiveHorse") then
        if same and not (plan_query(self, "slashIsAvailable", nil, false) or self:getCard("Snatch")) then return end
    elseif card:isKindOf("DefensiveHorse") then
        if not same and armor > 0 and plan_query(self, "isWeak") then use.card = card return end
    elseif card:isKindOf("Treasure") then
        for _, friend in ipairs(noself) do if plan_query(friend, "getPileCount", "wooden_ox") > 1 then return end end
    end
    if armor > -5 and overflow > 1 and plan_query(self, "hasSkills", "guzheng", enemies) then use.card = card
    else
        local other = same and plan_query(self, "evaluateArmor", same) or nil
        if type(other) == "number" then
            if overflow < 1 and other > 1 then return end
        else other = card:isKindOf("Armor") and plan_query(self, "evaluateArmor") or -1 end
        if armor > other or armor > 1 then use.card = card end
    end
end

ai_card_use.ExNihilo = function(self, card, use)
    -- useCardExNihilo selects the first enemy owning yanyu, then checks its mark;
    -- it does not test whether any later yanyu owner has a positive mark.
    local enemies = value_known(self.enemies or self:getEnemies(), "enemy relations")
    for _, enemy in ipairs(enemies) do
        if value_known(enemy:hasSkills("yanyu"), "yanyu skill") then
            if core_query(enemy,"getMark","YanyuDiscard2") > 0 then return end
            break
        end
    end
    -- Source proposal precedes native availability/target admission. A known
    -- response-only limit must be rejected by the final caller, not misread as
    -- missing target information in this target-free family callback.
    use.card = card
end

local function history_available(self, card, count, class)
    local candidate = strategy_candidate(self, card)
    if candidate and type(candidate.isAvailableWithHistoryOffset) == "function" then
        return plan_query(candidate, "isAvailableWithHistoryOffset", count, class)
    end
    return plan_query(card, "isAvailableWithHistoryOffset", count, class, self.player)
end
local function strategy_card_flag(self, card, flag)
    if type(self.hasStrategyCardFlag) == "function" then
        return value_known(self:hasStrategyCardFlag(card, flag), "strategy card flag")
    end
    return plan_query(card, "hasFlag", flag)
end
function SmartAIView:useCardAnaleptic(card, use)
    local expensive = plan_query(card, "subcardsLength") + plan_query(self, "getOverflow") > 1
        and not (plan_query(self.player, "hasEquip", card) or plan_query(self, "isWeak") or plan_query(self, "hasLoseHandcardEffective"))
    local elsewhere = false
    if not expensive and card:getEffectiveId() >= 0 then
        local owner = self.room:getCardOwner(card:getEffectiveId())
        if owner == nil and not plan_query(self.room, "isCardKnown", card:getEffectiveId()) then
            ai_unsupported("Analeptic owner is unknown", "Analeptic")
        end
        elsewhere = not same_player(owner, self.player)
    end
    if expensive or elsewhere then use.card = card
    elseif value_known(use.context and use.context.reason, "card-use reason") == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
        if plan_query(self.room, "getTurnCount") <= 1 and plan_role(self, self.player) == "renegade"
            and plan_query(self, "isLordHealthy") and plan_query(self, "getOverflow") < 2
            or plan_query(self.player, "hasFlag", "canshi") and plan_query(self.player, "getHandcardNum") < 3 then return end
        local count, slashes = 0, {}
        local residue = plan_query(card, "getTargetResidue", self.player)
        for _, slash in ipairs(plan_query(self, "sortByDynamicUsePriority", plan_query(self, "getCards", "Slash"))) do
            if #slashes > residue + 1 then break end
            if not plan_query(slash, "getSubcards"):contains(card:getEffectiveId()) then
                if history_available(self, slash, count, "Slash") then
                    local proposed = self:aiUseCard(slash)
                    if proposed and proposed.card then slashes[#slashes + 1] = proposed; count = count + 1 end
                end
            end
        end
        if #slashes < 1 then return end
        for index, proposed in ipairs(slashes) do
            if #slashes - index > residue then return end
            for _, target in ipairs(proposed.to) do
                if plan_query(self, "isFriend", target)
                    or plan_query(target, "getHandcardNum") > 0 and plan_query(self, "getOverflow") < 0 and plan_query(target, "hasSkill", "anxian")
                    or plan_query(target, "hasSkills", "zhenlie|mobilejxtpjinjiu") then return end
                if not (strategy_card_flag(self, proposed.card, "Qinggang") and plan_query(target, "hasArmorEffect", "SilverLion")) then
                    if plan_query(self, "ajustDamage", self.player, target, 2, proposed.card) == 0 then return end
                end
                local jinks = value_known(getKnownCard(target, self.player, "Jink", true, "he"), "known Jink count")
                if plan_query(target, "isFemale") and plan_query(self.player, "hasSkill", "roulin")
                    or plan_query(self.player, "isFemale") and plan_query(target, "hasSkill", "roulin")
                    or plan_query(self.player, "hasSkill", "wushuang") then if jinks > 1 then return end end
                if jinks >= plan_query(self.player, "getHp") and plan_query(self.player, "hasSkill", "kofliegong")
                    or (jinks >= plan_query(self.player, "getHp") or jinks <= plan_query(self.player, "getAttackRange")) and plan_query(self.player, "hasSkill", "liegong") then use.card = card return end
                if jinks > 0 and plan_query(self, "getOverflow") < 2 then return end
            end
        end
        use.card = card
    elseif self:getPriorTurnUseCount() > 1 then
        if self:hasPriorPlannedSlash() then use.card = card end
    end
end
ai_card_use.Analeptic = SmartAIView.useCardAnaleptic

function SmartAIView:useCardFireAttack(card, use)
    local suits = {spade=false, club=false, heart=false, diamond=false, no_shit=false}
    local discardable = {}
    for _, hand in ipairs(plan_query(self.player, "getHandcards")) do
        if hand:getEffectiveId() ~= card:getEffectiveId() and plan_query(self.player, "canDiscard", self.player, hand:getEffectiveId()) then
            discardable[#discardable + 1] = hand
            suits[plan_query(hand, "getSuitString")] = true
        end
    end
    local suit_count = 0
    for _, present in pairs(suits) do if present then suit_count = suit_count + 1 end end
    local _, raw_enemies = plan_groups(self)
    local sorted = plan_query(self, "sort", raw_enemies, "defense")
    self.enemies = sorted
    local enemies, targets = {}, {}
    for _, enemy in ipairs(sorted) do
        if not plan_query(self.player, "hasFlag", "FireAttackFailed_" .. enemy:objectName()) and not plan_query(self, "cantbeHurt", enemy, self.player)
            and plan_query(self, "objectiveLevel", enemy) > 2 and plan_query(self, "isGoodTarget", enemy, sorted, card)
            and (plan_query(self, "hasJueqingEffect", self.player, enemy)
                or not (plan_query(enemy, "hasSkill", "jianxiong") and not plan_query(self, "isWeak", enemy)
                    or plan_query(enemy, "isChained") and not plan_query(self, "isGoodChainTarget", enemy, card)
                    or plan_query(self, "needToLoseHp", enemy, self.player, card))) then enemies[#enemies + 1] = enemy end
    end
    for _, enemy in ipairs(enemies) do
        local known = plan_query(enemy,"getKnownCards")
        if #known > plan_query(enemy, "getHandcardNum") / 2 then
            local matching = 0
            for _, hand in ipairs(known) do if suits[plan_query(hand, "getSuitString")] then matching = matching + 1 end end
            if matching >= #known then targets[#targets + 1] = enemy end
        end
    end
    local attack_self
    for _, hand in ipairs(discardable) do
        if plan_query(self, "getCardsNum", "Peach,Analeptic") >= 2 or not isCard("Peach,Analeptic", hand, self.player) then
            attack_self = plan_query(self.player, "isChained"); break
        end
    end
    if plan_query(self.player, "getHandcardNum") > 1 and plan_role(self, self.player) ~= "renegade" and attack_self
        and plan_query(self, "isGoodChainTarget", self.player, card) and not plan_query(self, "cantbeHurt", self.player) then
        if plan_query(self, "canNiepan", self.player) or value_known(hasBuquEffect(self.player), "Buqu effect")
            or plan_query(self, "getCardsNum", "Peach,Analeptic") + plan_query(self.player, "getHp") > plan_query(self, "ajustDamage", self.player, self.player, 1, card) then targets[#targets + 1] = self.player end
    end
    if (suit_count == 2 and suits.diamond or suit_count <= 1) and #targets < 1
        and plan_query(self, "getOverflow") <= (plan_query(self.player, "hasSkills", "jizhi|nosjizhi") and -2 or 0) then return end
    for _, enemy in ipairs(enemies) do if not player_in(targets, enemy) then targets[#targets + 1] = enemy end end
    local extra = plan_extra(self, card, use)
    for _, target in ipairs(targets) do
        if not current_target(use, target) and plan_can_to(self, card, target)
            and plan_query(self, "ajustDamage", self.player, target, 1, card) ~= 0 then
            use.card = card
            local salvation = self:getCard("GodSalvation")
            if salvation and salvation:getEffectiveId() ~= card:getEffectiveId() and plan_query(target, "getLostHp") < 1
                and plan_query(self, "willUseGodSalvation", salvation) and plan_query(self, "hasTrickEffective", salvation, target, self.player) then use.card = salvation return end
            use.to:append(target)
            if #use.to > extra then return end
        end
    end
end
ai_card_use.FireAttack = SmartAIView.useCardFireAttack

function SmartAIView:useCardForCombo(card, use)
    if not card then return false end
    local callback = sgs.ai_card_combo_use[card:getClassName()]
    local used = false
    if type(callback) == "function" then
        used = callback(self, card, use)
        if AIUnsupported.is(used)then error(used,0)end
    elseif card:isKindOf("EquipCard") then use.card, used = card, true end
    if used and use.card then
        if type(self.setStrategyCardFlag) ~= "function" then ai_unsupported("combo flag scratch is unavailable", "combo") end
        self:setStrategyCardFlag(use.card, "AIGlobal_ComboFallback", true)
        return true
    end
    return false
end
sgs.ai_card_combo_use = sgs.ai_card_combo_use or {}
sgs.ai_card_combo_use.Slash = function(self, card, use)
    -- 1. 優先：狀態好且有賣血技能的友方
    self.friends_noself = plan_query(self, "sort", self.friends_noself, "hp")
    for _, friend in ipairs(self.friends_noself) do
        if not plan_query(self, "isWeak", friend) and plan_query(self, "canDamageHp", self.player, card, friend) and plan_query(self.player, "canSlash", friend, card, true) and not plan_query(self, "slashProhibit", card, friend, self.player) then
            use.card = card
            if use.to then use.to:append(friend) end
            return true
        end
    end
    self.enemies = plan_query(self, "sort", self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        if plan_query(self.player, "canSlash", enemy, card, true) and not plan_query(self, "slashProhibit", card, enemy, self.player) then
			use.card = card
			if use.to then use.to:append(enemy) end
			return true
        end
    end

    for _, friend in ipairs(self.friends_noself) do
        if not plan_query(self, "isWeak", friend) and plan_query(self.player, "canSlash", friend, card, true) and not plan_query(self, "slashProhibit", card, friend, self.player) then
            use.card = card
            if use.to then use.to:append(friend) end
            return true
        end
    end

    return false
end


sgs.ai_card_combo_use.Duel = function(self, card, use)
    self.friends_noself = plan_query(self, "sort", self.friends_noself, "hp")
    for _, friend in ipairs(self.friends_noself) do
        if not plan_query(self, "isWeak", friend) and plan_query(self, "canDamageHp", self.player, card, friend) and not plan_query(self.player, "isProhibited", friend, card) then
            use.card = card
            if use.to then use.to:append(friend) end
            return true
        end
    end

    for _, friend in ipairs(self.friends_noself) do
        if not plan_query(self, "isWeak", friend) and not plan_query(self.player, "isProhibited", friend, card) then
            use.card = card
            if use.to then use.to:append(friend) end
            return true
        end
    end

    return false
end


local function combo_snatch_dismantlement(self, card, use)
	local is_snatch = card:isKindOf("Snatch")

    local function can_target(target)
        if plan_query(target, "isAllNude") then return false end
        if plan_query(self.player, "isProhibited", target, card) then return false end
        -- 順手牽羊距離限制
        if is_snatch and plan_query(self.player, "distanceTo", target) > 1 and not plan_can_to(self, card, target) then
            return false
        end
        return true
    end

    -- 1. 優先：狀態好的友方
    self.friends_noself = plan_query(self, "sort", self.friends_noself, "hp")
    for _, friend in ipairs(self.friends_noself) do
        if not plan_query(self, "isWeak", friend) and can_target(friend) then
            use.card = card
            if use.to then use.to:append(friend) end
            return true
        end
    end

    -- 2. 兜底：狀態差的友方
    for _, friend in ipairs(self.friends_noself) do
        if plan_query(self, "isWeak", friend) and can_target(friend) then
            use.card = card
            if use.to then use.to:append(friend) end
            return true
        end
    end

    return false
end

sgs.ai_card_combo_use.Dismantlement = combo_snatch_dismantlement
sgs.ai_card_combo_use.Snatch = combo_snatch_dismantlement


sgs.ai_card_combo_use.FireAttack = function(self, card, use)
    -- 1. 優先：空城的敵方 (火攻對空城絕對無效)
    for _, enemy in ipairs(self.enemies) do
        if not plan_query(enemy, "isKongcheng") and not plan_query(self.player, "isProhibited", enemy, card) then
            use.card = card
            if use.to then use.to:append(enemy) end
            return true
        end
    end

    -- 2. 其次：狀態好且有賣血技能的友方
    self.friends_noself = plan_query(self, "sort", self.friends_noself, "hp")
    for _, friend in ipairs(self.friends_noself) do
        if not plan_query(friend, "isKongcheng") and not plan_query(self, "isWeak", friend) and plan_query(self, "canDamageHp", self.player, card, friend) and not plan_query(self.player, "isProhibited", friend, card) then
            use.card = card
            if use.to then use.to:append(friend) end
            return true
        end
    end

    -- 3. 兜底：狀態好的友方
    for _, friend in ipairs(self.friends_noself) do
        if not plan_query(friend, "isKongcheng") and not plan_query(self, "isWeak", friend) and not plan_query(self.player, "isProhibited", friend, card) then
            use.card = card
            if use.to then use.to:append(friend) end
            return true
        end
    end

    return false
end

-- The original combo entry point: only its public activation mark is read.
sgs.ai_skill_carduse = sgs.ai_skill_carduse or {}
if sgs.ai_skill_carduse.MobileZhiQinzheng == nil then
    sgs.ai_skill_carduse.MobileZhiQinzheng = function(self, card, use)
        if plan_query(self.player, "getPhase") ~= sgs.Player_Play then return false end
        local next_count = plan_query(self.player, "getMark", "&mobilezhiqinzheng") + 1
        if not (next_count % 15 == 0 or next_count % 24 == 0 or next_count % 40 == 0) then return false end
        local probe = {isDummy=true,to=AIList.new({}),context=use.context}
        local method = self["useCard" .. card:getClassName()]
        if type(method) == "function" then method(self, card, probe) end
        if probe.card and (#probe.to == 0 or #probe.to > 0) then return false end
        return self:useCardForCombo(card, use)
    end
end

local function plan_cost_card(self, class_name, id, owner)
    local card = card_in_player(owner, id)
    if not card then ai_unsupported("AOE payment card is not visible", "getAoeValue") end
    return isCard(class_name, card, owner)
end
function SmartAIView:isLordInDanger()
    for _, player in ipairs(plan_query(self, "getCachedAlivePlayers")) do
        if damage_role(self,player)=="lord" then
            local hp = plan_query(player, "getHp")
            if hp > 4 and plan_query(player, "hasSkill", "benghuai") then hp = 4 end
            return hp < 3
        end
    end
    return false
end
function SmartAIView:getAoeValueTo(card,to,from)
	local value,sj_num = 0,0
	if plan_query(card, "isKindOf", "ArcheryAttack") then
		value = -50
		sj_num = plan_estimate(self, "Jink",to)
		if sj_num<1 or plan_query(to, "isCardLimited", plan_query(self, "cloneEvaluationCard", "jink"),sgs.Card_MethodResponse)
		then value = -70 end
		if plan_query(to, "hasSkills", "leiji|nosleiji|olleiji")
		and (sj_num>=1 or plan_query(to, "hasArmorEffect", "EightDiagram"))
		and self:findLeijiTarget(to,50,self.player) then
			value = value+100
			if plan_query(self, "hasSuit", "spade",true,to) then value = value+150
			else value = value+plan_query(to, "getHandcardNum")*35 end
		elseif plan_query(to, "hasArmorEffect", "EightDiagram") then
			value = value+20
			if plan_query(self, "getFinalRetrial")==2 then value = value-15
			elseif plan_query(self, "getFinalRetrial")==1 then value = value+10 end
		end
		if sj_num>=1 and plan_query(to, "hasSkills", "mingzhe|gushou") then value = value+8 end
		if sj_num>=1 and plan_query(to, "hasSkill", "xiaoguo") then value = value-4 end
	elseif plan_query(card, "isKindOf", "SavageAssault") then
		value = -50
		sj_num = plan_estimate(self, "Slash",to)
		if sj_num<1 or plan_query(to, "isCardLimited", plan_query(self, "cloneEvaluationCard", "slash"),sgs.Card_MethodResponse)
		then value = -70 end
		if sj_num>=1 and plan_query(to, "hasSkill", "gushou") then value = value+8 end
		if sj_num>=1 and plan_query(to, "hasSkill", "xiaoguo") then value = value-4 end
	end
	value = value+math.min(20,plan_query(to, "getHp")*5)
	if plan_query(self, "needToLoseHp", to,from,card,true) then value = value+30 end
	if plan_query(to, "hasSkill", "chongzhen") and plan_query(self, "isEnemy", to)
	and plan_estimate(self, "Slash,Jink",to)>=1
	then value = value+15 end
	--xiemu
	if plan_query(to, "hasSkill", "xiemu") and plan_query(to, "getMark", "@xiemu_"..plan_query(from, "getKingdom"))>0 and plan_query(card, "isBlack") then value = value+35 end
	if plan_query(to, "getHp")<2 and plan_query(self, "getAllPeachNum", to)<1
	then value = value-30 end
	if not plan_query(self, "hasJueqingEffect", from,to) then
		if plan_query(self.room, "getMode")~="06_3v3" and plan_query(self.room, "getMode")~="06_XMode" and plan_query(to, "getHp")<2
		and (self:getSourceLord(from)==from) and plan_query(self,"getRoleEstimate",to)=="loyalist" and plan_query(self, "getCardsNum", "Peach")<1
		then value = value-plan_query(from, "getCardCount")*20 end
		if plan_query(to, "getHp")>1 then
			if plan_query(to, "hasSkill", "quanji") then value = value+10 end
			if plan_query(to, "hasSkill", "langgu") and plan_query(self, "isEnemy", to) then value = value-15 end
			if plan_query(to, "hasSkill", "jianxiong") then
				value = value+(plan_query(card, "isVirtualCard") and plan_query(card, "subcardsLength")*10 or 10)
			end
			if plan_query(to, "hasSkills", "fenyong+xuehen") and plan_query(to, "getMark", "@fenyong")<1
			then value = value+30 end
			if plan_query(to, "hasSkill", "shenfen") and plan_query(to, "hasSkill", "kuangbao") then
				value = value+math.min(25,plan_query(to, "getMark", "&wrath")*5)
			end
			if plan_query(to, "hasSkill", "beifa") and plan_query(to, "getHandcardNum")==1 and plan_query(self, "needKongcheng", to) then
				if sj_num==1 or plan_estimate(self, "Nullification",to)==1 then value = value+20
				elseif plan_query(self, "getKnownNum", to)<1 then value = value+5 end
			end
			if plan_query(to, "hasSkill", "tanlan") and plan_query(self, "isEnemy", to) and plan_query(from, "getCardCount")>0 then value = value+10 end
		end
	end
	if plan_query(to, "hasSkill", "juxiang") and not plan_query(card, "isVirtualCard")
	or plan_query(to, "hasSkill", "danlao") and plan_query(to, "aliveCount")>2
	or plan_query(self, "hasHuangenEffect", to)
	then value = value+20 end
	return value
end

local function aoe_value(self,card,from)
	local lord,good = self:getSourceLord(self.player),0
	from = from or self.player
	local function canHelpLord()
		local goodnull,kd = 0,{}
		if plan_query(card, "isVirtualCard") and plan_query(card, "subcardsLength")>0
		and from==self.player then
			for _,id in sgs.qlist(plan_query(card, "getSubcards"))do
				if plan_cost_card(self,"Nullification",id,from) then goodnull = goodnull-1 end
			end
		end
		if plan_query(card, "isKindOf", "SavageAssault") then
			for _,s in ipairs(sgs.getPlayerSkillList(lord))do
				if plan_query(s, "objectName"):contains("jijiang")
				or plan_query(s, "objectName"):contains("qinwang") and plan_query(lord, "getCardCount")>0
				then kd["shu"] = "Slash" break end
			end
		elseif plan_query(card, "isKindOf", "ArcheryAttack") then
			for _,s in ipairs(sgs.getPlayerSkillList(lord))do
				if plan_query(s, "objectName"):contains("hujia")
				then kd["wei"] = "Jink" break end
			end
		end
		for _,p in sgs.qlist(plan_query(self.room, "getAlivePlayers"))do
			if plan_query(self, "isFriend", lord,p) then
				if plan_estimate(self, "Peach",p)>0 then return true end
				if kd[plan_query(p, "getKingdom")] and plan_estimate(self, kd[plan_query(p, "getKingdom")],p)>0 then return true end
				goodnull = goodnull+plan_estimate(self, "Nullification",p)
			else goodnull = goodnull-plan_estimate(self, "Nullification",p) end
		end
		return goodnull>=2
	end
	local isEffective_F,isEffective_E,enemy_number = 0,0,0
	self.aoeTos = plan_query(self.room, "getOtherPlayers", from)
	for _,p in sgs.qlist(self.aoeTos)do
		if plan_query(self, "hasTrickEffective", card,p,from) then
			if plan_query(self, "isFriend", p) then
				isEffective_F = isEffective_F+1
				good = good+plan_query(self, "getAoeValueTo", card,p,from)
				if lord==p and not canHelpLord()
				and plan_query(self, "isLordInDanger") and not value_known(hasBuquEffect(p), "Buqu effect")
				then good = good-(plan_query(p, "getHp")<2 and 2013 or 250) end
				if plan_query(p, "hasSkill", "dushi") and not plan_query(from, "hasSkill", "benghuai")
				and plan_query(self, "isWeak", p) then good = good-40 end
			else
				enemy_number = enemy_number+1
				if plan_query(self, "isEnemy", p) then
					isEffective_E = isEffective_E+1
					good = good-plan_query(self, "getAoeValueTo", card,p,from)
					if lord==p and not canHelpLord()
					and plan_query(self, "isLordInDanger") and not value_known(hasBuquEffect(p), "Buqu effect") then
						good = good+300-plan_query(p, "getHp")*100
						if #self.enemies==1 or plan_query(p, "isKongcheng")
						then good = good+200 end
					end
				end
			end
			if plan_query(self, "cantbeHurt", p,from) then
				if plan_query(p, "hasSkill", "wuhun") and not plan_query(self, "isWeak", p) and plan_query(from, "getMark", "&nightmare+#"..plan_query(p, "objectName"))<1 then
					if from==self.player and self.role~="renegade" and self.role~="lord"
					or from~=self.player and not(plan_query(self, "isFriend", from) and from==lord)
					then else good = good-250 end
				else good = good-250 end
			end
		end
	end
	self.aoeTos = nil
	if plan_query(from, "hasSkills", "nosjizhi|jizhi") then good = good+50 end
	if isEffective_F+isEffective_E<1 then return good
	elseif isEffective_E<1 then good = good-500 end
	if plan_query(from, "hasSkills", "shenfen+kuangbao") then
		good = good+3*enemy_number
		if not plan_query(from, "hasSkill", "wumou") then good = good+3*enemy_number end
		if plan_query(from, "getMark", "&wrath")>0 then good = good+enemy_number end
	end
	if plan_query(from, "hasSkills", "jianxiong|luanji|qice|manjuan") then good = good+2*enemy_number end
	if plan_query(from, "getMark", "AI_fangjian-Clear")>0 then good = good+300 end
	local xiahou = self.room:findPlayerBySkillName("yanyu")
	if xiahou and plan_query(self, "isEnemy", xiahou) and plan_query(xiahou, "getMark", "YanyuDiscard2")>0 then good = good-50 end
	return good
end


function SmartAIView:getAoeValue(card,from)
    -- Donor leaves aoeTos at the reached list on an error, and nil after a
    -- completed loop. It never restores the previous list around recursion.
    return aoe_value(self,card,from)
end

local function plan_aoe(self, card, use)
    if plan_query(self.room, "alivePlayerCount") >= 20 then return end
    local mode = plan_query(self.room, "getMode")
    if mode:find("p") and mode >= "04p" then
        if card:isKindOf("ArcheryAttack") and core_query(self.player,"getMark","AI_fangjian-Clear") > 0 and plan_query(self, "getOverflow") < 1
            or plan_query(self.room, "getTurnCount") < 2 and
                (self.role == "loyalist" and card:isKindOf("ArcheryAttack") or self.role == "rebel" and card:isKindOf("SavageAssault")) then return end
    end
    if plan_query(self, "getAoeValue", card) > 0 then use.card = card end
end
ai_card_use.AOE = plan_aoe
ai_card_use.ArcheryAttack = plan_aoe
ai_card_use.SavageAssault = plan_aoe

local function plan_exclude(self,players,card)
    local result = AIList.new({})
    for _, player in ipairs(players) do
        if plan_query(self.player,"canUse",card,player) then result:append(player) end
    end
    return result
end
-- The fixed isCurrent body: preserve identity/name checks and their short
-- circuit order. A non-table current_targets value is not repaired to a list.
local function r53_collateral_current(use,to)
 if AIList.isNativeList(use.current_targets)then return use.current_targets:contains(to)end
 if type(use.current_targets)=='table'then
  for _,p in ipairs(use.current_targets)do if p==to or p==to:objectName()then return true end end
 elseif type(use.current_targets)=='userdata'then return use.current_targets:contains(to)end
end
function SmartAIView:useCardCollateral(card,use)
	local fromList = sgs.QList2Table(plan_query(self.room, "getOtherPlayers", self.player))
	local cmps = {}
	for _,p in ipairs(fromList)do
		cmps[plan_query(p, "objectName")] = plan_query(self, "objectiveLevel", p)
	end
	local cmp = function(a,b)
		local al = cmps[plan_query(a, "objectName")]
		local bl = cmps[plan_query(b, "objectName")]
		if al~=bl then return al>bl end
		al = plan_estimate(self, "Slash",a)
		bl = plan_estimate(self, "Slash",b)
		if al~=bl then return al<bl end
		return plan_query(a, "getHandcardNum")<plan_query(b, "getHandcardNum")
	end
	table.sort(fromList,cmp)
	function useToCard(to)
		return to:getWeapon()
		and not(use.to:contains(to) or r53_collateral_current(use,to)
		or plan_query(self.player, "isProhibited", to,card))
	end
	local toList = plan_query(self, "sort", plan_query(self.room, "getAlivePlayers"),"defense")
	local extraTarget = plan_extra(self,card,{})
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	extraTarget = extraTarget*2
	for _,enemy in ipairs(self.enemies)do
		if plan_query(self.player, "distanceTo", enemy)<2
		and plan_query(self, "isGoodTarget", enemy,self.enemies,card)
		and not plan_query(self, "hasCrossbowEffect") and plan_query(self, "getCardsNum", "Slash")>2 then
			for _,from in ipairs(sgs.reverse(fromList))do
				if plan_query(from, "hasWeapon", "Crossbow")
				and useToCard(from) then
					for _,enemy in ipairs(toList)do
						if plan_query(from, "canSlash", enemy)
						and plan_query(from, "inMyAttackRange", enemy) then
							plan_query(self,"collateralCrossbowFlag","set",self.player,card)
							use.card = card
							use.to:append(from)
							use.to:append(enemy)
							if use.to:length()>extraTarget
							then return end
							break
						end
					end
				end
			end
			break
		end
	end
	for _,enemy in ipairs(fromList)do
		if useToCard(enemy) and plan_query(self, "objectiveLevel", enemy)>=0
		and not(plan_query(self, "loseEquipEffect", enemy) or plan_query(enemy, "hasSkill", "tuntian+zaoxian")) then
			local final_enemy
			for _,enemy2 in ipairs(toList)do
				if final_enemy then break end
				if plan_query(enemy, "canSlash", enemy2)
				and plan_query(enemy, "inMyAttackRange", enemy2)
				and plan_query(self, "objectiveLevel", enemy2)>2
				then final_enemy = enemy2 end
			end
			for _,enemy2 in ipairs(toList)do
				if final_enemy then break end
				local ol = plan_query(self, "objectiveLevel", enemy2)
				if plan_query(enemy, "inMyAttackRange", enemy2)
				and plan_query(enemy, "canSlash", enemy2) and ol<=3 and ol>=0
				then final_enemy = enemy2 end
			end
			for _,friend in ipairs(sgs.reverse(toList))do
				if final_enemy then break end
				if plan_query(enemy, "canSlash", friend)
				and plan_query(enemy, "inMyAttackRange", friend)
				and plan_query(self, "objectiveLevel", friend)<0
				and plan_query(self, "needToLoseHp", friend,enemy,plan_query(self, "getEvaluationCard", "slash"),true)
				then final_enemy = friend end
			end
			for _,friend in ipairs(sgs.reverse(toList))do
				if final_enemy then break end
				if plan_query(enemy, "canSlash", friend)
				and plan_query(enemy, "inMyAttackRange", friend)
				and plan_query(self, "objectiveLevel", friend)<0
				and (plan_estimate(self, "Jink",friend)>1 or plan_estimate(self, "Slash",enemy)<1)
				then final_enemy = friend end
			end
			if final_enemy then
				use.card = card
				use.to:append(enemy)
				use.to:append(final_enemy)
				if use.to:length()>extraTarget
				then return end
			end
		end
	end
	for _,friend in ipairs(fromList)do
		if useToCard(friend) and plan_query(self, "objectiveLevel", friend)<0
		and plan_estimate(self, "Slash",friend)>0 then
			for _,enemy in ipairs(toList)do
				if plan_query(friend, "canSlash", enemy)
				and plan_query(self, "objectiveLevel", enemy)>2
				and plan_query(friend, "inMyAttackRange", enemy)
				and plan_query(self, "isGoodTarget", enemy,self.enemies,card) then
					use.card = card
					use.to:append(friend)
					use.to:append(enemy)
					if use.to:length()>extraTarget
					then return end
					break
				end
			end
		end
	end
	plan_query(self, "sortEnemies", toList)
	for _,friend in ipairs(fromList)do
		if useToCard(friend) and plan_query(self, "objectiveLevel", friend)<0
		and not(plan_query(friend, "hasWeapon", "Crossbow") and plan_estimate(self, "Slash",friend)>1)
		and plan_query(self, "loseEquipEffect", friend) then
			for _,enemy in ipairs(toList)do
				if plan_query(friend, "canSlash", enemy) and plan_query(self, "objectiveLevel", enemy)>=0
				and plan_query(friend, "inMyAttackRange", enemy) then
					use.card = card
					use.to:append(friend)
					use.to:append(enemy)
					if use.to:length()>extraTarget
					then return end
					break
				end
			end
			for _,enemy in ipairs(sgs.reverse(toList))do
				if plan_query(friend, "canSlash", enemy) and plan_query(self, "objectiveLevel", enemy)<0
				and plan_query(friend, "inMyAttackRange", enemy) then
					use.card = card
					use.to:append(friend)
					use.to:append(enemy)
					if use.to:length()>extraTarget
					then return end
					break
				end
			end
		end
	end
end


function SmartAIView:enemiesContainsTrick(EnemyCount)
    local friends, enemies = plan_groups(self)
	local trick_all,possible_indul_enemy,possible_ss_enemy = 0,0,0
	local indul_num = plan_query(self, "getCardsNum", "Indulgence")
	local ss_num = plan_query(self, "getCardsNum", "SupplyShortage")
	local enemy_num,temp_enemy = 0,nil
	local zhanghe = self.room:findPlayerBySkillName("qiaobian")
	if zhanghe and (not plan_query(self, "isEnemy", zhanghe) or plan_query(zhanghe, "isKongcheng") or not plan_query(zhanghe, "faceUp")) then zhanghe = nil end
	if plan_query(self.player, "hasSkill", "guose") then
		for _,acard in sgs.list(plan_query(self.player, "getCards", "he"))do
			if plan_query(acard, "getSuit")==sgs.Card_Diamond then indul_num = indul_num+1 end
		end
	end
	if plan_query(self.player, "hasSkill", "duanliang") then
		for _,acard in sgs.list(plan_query(self.player, "getCards", "he"))do
			if plan_query(acard, "isBlack") then ss_num = ss_num+1 end
		end
	end
	for _,enemy in sgs.list(enemies)do
		if not plan_query(enemy, "containsTrick", "YanxiaoCard") then
			if plan_query(enemy, "containsTrick", "indulgence") then
				if not plan_query(enemy, "hasSkills", "keji|conghui") and (not zhanghe or plan_query(self, "playerGetRound", enemy)>=plan_query(self, "playerGetRound", zhanghe)) then
					trick_all = trick_all+1
					if not temp_enemy or plan_query(temp_enemy, "objectName")~=plan_query(enemy, "objectName") then
						enemy_num = enemy_num+1
						temp_enemy = enemy
					end
				end
			else
				possible_indul_enemy = possible_indul_enemy+1
			end
			if plan_query(self.player, "distanceTo", enemy)==1 or plan_query(self.player, "hasSkill", "duanliang") and plan_query(self.player, "distanceTo", enemy)<=2 then
				if plan_query(enemy, "containsTrick", "supply_shortage") then
					if not plan_query(self, "hasSkills", "shensu|jisu",enemy) and (not zhanghe or plan_query(self, "playerGetRound", enemy)>=plan_query(self, "playerGetRound", zhanghe)) then
						trick_all = trick_all+1
						if not temp_enemy or plan_query(temp_enemy, "objectName")~=plan_query(enemy, "objectName") then
							enemy_num = enemy_num+1
							temp_enemy = enemy
						end
					end
				else
					possible_ss_enemy  = possible_ss_enemy+1
				end
			end
		end
	end
	indul_num = math.min(possible_indul_enemy,indul_num)
	ss_num = math.min(possible_ss_enemy,ss_num)
	if not EnemyCount then
		return trick_all+indul_num+ss_num
	else
		return enemy_num+indul_num+ss_num
	end
end


-- Public skill definitions distinguish no view-as skill from hidden availability.
-- The owner can use exact legality; another player's hidden cost/limit checks
-- use an explicit active-skill prior, never an unmarked false value.
function SmartAIView:isViewAsEnabledAtPlayEstimate(skill, player)
    local known = value_call(skill,"isViewAsEnabledAtPlay",player)
    if type(known)=="boolean" then return known end
    local facts = self.world and self.world.strategy_facts
    local rows = facts and facts.damage and facts.damage.view_as_skills
    local row = rows and rows[plan_query(skill,"objectName")]
    if type(row)~="table" or type(row.exists)~="boolean" then ai_unsupported("view-as skill definition is unknown","Indulgence") end
    if not row.exists then return false end
    if player:objectName()==self.player:objectName() then return value_known(row.owner_enabled_at_play,"owner view-as availability") end
    return plan_query(self,"useKnowledgeEstimate",{value=true,status="estimate",viewer=self.player:objectName(),target=player:objectName(),
        basis="public view-as skill assumed active; private opponent costs and enablement excluded"},"Indulgence.view_as_enabled")
end

function SmartAIView:useCardIndulgence(card,use)
    local friends, enemies = plan_groups(self)
	if #enemies<1 and plan_query(self.player, "getHandcardNum")-self:getPriorTurnUseCount()-plan_query(self.player, "getMaxCards")<1 then return end
	local zhanghe = self.room:findPlayerBySkillName("qiaobian")
	local zhanghe_seat = zhanghe and plan_query(zhanghe, "faceUp") and not plan_query(zhanghe, "isKongcheng") and not plan_query(self, "isFriend", zhanghe) and plan_query(zhanghe, "getSeat")
	local sb_daqiao = self.room:findPlayerBySkillName("yanxiao")
	local yanxiao = sb_daqiao and not plan_query(self, "isFriend", sb_daqiao) and plan_query(sb_daqiao, "faceUp")
		and (getKnownCard(sb_daqiao,self.player,"diamond",nil,"he")>0
		or plan_query(sb_daqiao, "getHandcardNum")+plan_query(self, "ImitateResult_DrawNCards", sb_daqiao,plan_query(sb_daqiao, "getSkills"))>3
		or plan_query(sb_daqiao, "containsTrick", "YanxiaoCard"))
	local getvalue = function(enemy)
		if not AIValue.isPlayer(enemy)
		or plan_query(enemy, "containsTrick", "YanxiaoCard")
		or plan_query(enemy, "hasSkill", "qiaobian") and plan_query(enemy, "getJudgingArea"):isEmpty() and plan_query(enemy, "getHandcardNum")>0
		or yanxiao and (plan_query(self, "playerGetRound", sb_daqiao)<=plan_query(self, "playerGetRound", enemy) and plan_query(self, "enemiesContainsTrick", true)<=1 or not plan_query(enemy, "faceUp"))
		or zhanghe_seat and (plan_query(self, "playerGetRound", zhanghe)<=plan_query(self, "playerGetRound", enemy) and plan_query(self, "enemiesContainsTrick")<=1 or not plan_query(enemy, "faceUp"))
		then return -100 end
		local value = plan_query(enemy, "getHandcardNum")-plan_query(enemy, "getHp")
		for _,sk in sgs.list(plan_query(enemy, "getSkills"))do
			if self:isViewAsEnabledAtPlayEstimate(sk, enemy) then value = value+6 end
            if plan_query(sk, "hasTriggerEvent", sgs.EventPhaseStart) then value = value-2 end
            if plan_query(sk, "hasTriggerEvent", sgs.EventPhaseChanging) then value = value-2 end
            if plan_query(sk, "hasTriggerEvent", sgs.FinishJudge) then value = value-2 end
		end
		if plan_query(self, "isWeak", enemy) then value = value+3 end
		if plan_query(enemy, "isLord") then value = value+3 end
		if plan_query(self, "objectiveLevel", enemy)<3 then value = value-6 end
		if not plan_query(enemy, "faceUp") then value = value-10 end
		if plan_query(enemy, "hasSkills", "keji|shensu|conghui") then value = value-plan_query(enemy, "getHandcardNum") end
		if plan_query(self, "needBear", enemy) then value = value-20 end
		if #enemies>1 and getKnownCard(enemy,self.player,"Dismantlement",true)>0 then value = value+3 end
		return value+(plan_query(enemy, "aliveCount")-plan_query(self, "playerGetRound", enemy))/2
	end
	local function cmp(a,b)
		return getvalue(a)>getvalue(b)
	end
	table.sort(enemies,cmp)
	for _,ep in sgs.list(enemies)do
		if plan_can_to(self,card,ep)
		and getvalue(ep)>-100 and use.to then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	local aps = plan_query(self.room, "getOtherPlayers", self.player)
	aps = sgs.QList2Table(aps)
	table.sort(aps,cmp)
	for _,ep in sgs.list(aps)do
		if plan_can_to(self,card,ep)
		and getvalue(ep)>-100 and use.to
		and not plan_query(self, "isFriend", ep) then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end


local function will_use_lightning(self,card)
    local friends, enemies = plan_groups(self)
	if plan_query(self.player, "isProhibited", self.player,card) then return end
	local function hasDangerousFriend()
		local hashy = false
		for _,p in sgs.list(enemies)do
			if plan_query(p, "hasSkill", "hongyan")
			then hashy = true break end
		end
		for _,p in sgs.list(enemies)do
			if plan_query(p, "hasSkill", "gongxin") and hashy
			or plan_query(p, "hasSkill", "guanxing")
			or plan_query(p, "hasSkill", "xinzhan") then
				if plan_query(self, "isFriend", plan_query(p, "getNextAlive"))
				then return true end
			end
		end
		return false
	end
	local n = plan_query(self, "getFinalRetrial", self.player)
	if n==2 then return
	elseif n==1 then return true
	elseif not hasDangerousFriend() then
		local friends = 0
		local enemies = 0
		for _,player in sgs.list(plan_query(self.room, "getAllPlayers"))do
			if plan_query(self, "objectiveLevel", player)>=4
			and not plan_query(player, "hasSkill", "hongyan") and not plan_query(player, "hasSkill", "wuyan")
			and not (plan_query(player, "hasSkill", "weimu") and plan_query(card, "isBlack"))
			then enemies = enemies+1
			elseif plan_query(self, "isFriend", player) and not plan_query(player, "hasSkill", "hongyan")
			and not plan_query(player, "hasSkill", "wuyan")
			and not (plan_query(player, "hasSkill", "weimu") and plan_query(card, "isBlack"))
			then friends = friends+1 end
		end
		return friends<1 or enemies/friends>1.5
	end
end

function SmartAIView:useCardLightning(card,use)
    local friends, enemies = plan_groups(self)
	if plan_query(self, "willUseLightning", card)
	then use.card = card end
end


function SmartAIView:hasGuanxingEffect(owner)
    owner = owner or self.player
    local function skill(method, names)
        local value = plan_query(owner, method, names)
        local row = type(owner)=="table" and rawget(owner,"_view")
        if value==false and type(row)=="table" and row.skills_complete~=true then
            ai_unsupported("Guanxing skill absence is not visible", "hasGuanxingEffect")
        end
        return value
    end
    if plan_query(owner,"aliveCount") > 3 and skill("hasSkills","guanxing|tenyearguanxing")
        or plan_query(owner,"getCardCount") > 2 and skill("hasSkill","zhiming") then return true end
end
function SmartAIView:useCardSupplyShortage(card,use)
    local friends, enemies = plan_groups(self)
	local enemies = plan_exclude(self,enemies,card)
	if #enemies<1 then return end
	local zhanghe = self.room:findPlayerBySkillName("qiaobian")
	local zhanghe_seat = zhanghe and plan_query(zhanghe, "faceUp") and plan_query(zhanghe, "getHandcardNum")>0 and not plan_query(self, "isFriend", zhanghe) and plan_query(zhanghe, "getSeat") or 0
	local sb_daqiao = self.room:findPlayerBySkillName("yanxiao")
	local yanxiao = sb_daqiao and not plan_query(self, "isFriend", sb_daqiao) and plan_query(sb_daqiao, "faceUp") and
		(getKnownCard(sb_daqiao,self.player,"diamond",nil,"he")>0
		or plan_query(sb_daqiao, "getHandcardNum")+plan_query(self, "ImitateResult_DrawNCards", sb_daqiao,plan_query(sb_daqiao, "getSkills"))>3
		or plan_query(sb_daqiao, "containsTrick", "YanxiaoCard"))
	local getvalue = function(enemy)
		if not AIValue.isPlayer(enemy)
		or plan_query(enemy, "getMark", "juao")>0
		or plan_query(enemy, "containsTrick", "YanxiaoCard")
		or plan_query(enemy, "containsTrick", "supply_shortage")
		or plan_query(enemy, "getJudgingArea"):isEmpty() and plan_query(enemy, "getHandcardNum")>0 and plan_query(enemy, "hasSkill", "qiaobian")
		or zhanghe_seat>0 and (plan_query(self, "playerGetRound", zhanghe)<=plan_query(self, "playerGetRound", enemy) and plan_query(self, "enemiesContainsTrick")<=1 or not plan_query(enemy, "faceUp"))
		or yanxiao and (plan_query(self, "playerGetRound", sb_daqiao)<=plan_query(self, "playerGetRound", enemy) and plan_query(self, "enemiesContainsTrick", true)<=1 or not plan_query(enemy, "faceUp"))
		then return -100 end
		local value = -plan_query(enemy, "getHandcardNum")
		for _,sk in ipairs(plan_query(enemy, "getSkills"))do
			if string.find(plan_query(sk, "getDescription"),"摸牌阶段") then value = value+3 end
			if plan_query(sk, "inherits", "ViewAsSkill") then value = value+2 end
			if plan_query(sk, "hasTriggerEvent", sgs.DrawNCards) then value = value+2 end
            if plan_query(sk, "hasTriggerEvent", sgs.AfterDrawNCards) then value = value+2 end
            if plan_query(sk, "hasTriggerEvent", sgs.AskForRetrial) then value = value-3 end
            if plan_query(sk, "hasTriggerEvent", sgs.FinishJudge) then value = value-2 end
		end
		if plan_query(enemy, "hasSkills", "manjuan|beige") then value = value+10 end
		if plan_query(enemy, "hasSkills", "qinyin|zhaoxin|toudu|renjie") then value = value+5 end
		if plan_query(enemy, "hasSkills", "buyi|chongzhen") then value = value+1 end
		if plan_query(self, "isWeak", enemy) then value = value+5 end
		if plan_query(enemy, "isLord") then value = value+3 end
		if not plan_query(enemy, "faceUp") then value = value-10 end
		if plan_query(enemy, "hasSkills", "keji|shensu|qingyi") then value = value-plan_query(enemy, "getHandcardNum") end
		if plan_query(self, "hasGuanxingEffect", enemy) then value = value-5 end
		if not plan_query(self, "isGoodTarget", enemy,enemies,card) then value = value-1 end
		if plan_query(self, "needKongcheng", enemy) then value = value-1 end
		if plan_query(enemy, "getMark", "@kuiwei")>0 then value = value-2 end
		return value
	end
	local pvs = {}
	for _,ep in ipairs(enemies)do
		pvs[plan_query(ep, "objectName")] = getvalue(ep)
	end
	local function cmp(a,b)
		return pvs[plan_query(a, "objectName")]>pvs[plan_query(b, "objectName")]
	end
	table.sort(enemies,cmp)
	for _,ep in ipairs(enemies)do
		if pvs[plan_query(ep, "objectName")]>-100
		and use.to then
			use.card = card
			use.to:append(ep)
			break
		end
	end
end


function SmartAIView:useCardIronChain(card,use)
    local friends, enemies = plan_groups(self)
	if plan_query(card, "canRecast") then use.card = card end
	if plan_query(self.player, "isLocked", card) then return end
	local friendtargets,friendtargets2,otherfriends = {},{},{}
	friends = plan_query(self, "sort", friends,"defense")
	for _,friend in ipairs(friends)do
		if plan_query(friend, "isChained") and not plan_query(self, "isGoodChainPartner", friend) then
			if plan_query(friend, "containsTrick", "lightning")
			then table.insert(friendtargets,friend)
			else table.insert(friendtargets2,friend) end
		else table.insert(otherfriends,friend) end
	end
	local extraTarget = 1+plan_extra(self,card,{})
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _, value in ipairs(friendtargets2) do table.insert(friendtargets,value) end
	for _,friend in ipairs(friendtargets)do
		if current_target(use,friend) then continue end
		if plan_can_to(self,card,friend) then
			use.to:append(friend)
			use.card = card
			if use.to:length()>extraTarget
			then return end
		end
	end
	enemies = plan_query(self, "sort", enemies,"defense")
	for _,enemy in ipairs(enemies)do
		if current_target(use,enemy) then continue end
		if plan_can_to(self,card,enemy) and plan_query(self, "objectiveLevel", enemy)>2
		and not(plan_query(enemy, "isChained") or plan_query(self, "needToLoseHp", enemy))
		and plan_query(self, "isGoodTarget", enemy,enemies) then
			use.to:append(enemy)
			use.card = card
			if use.to:length()>extraTarget
			then return end
		end
	end
	if not current_target(use,self.player)
	and use.to:length()>0 and not use.to:contains(self.player) and plan_can_to(self,card,self.player)
	and plan_query(self, "needToLoseHp", self.player) and not(plan_query(self.player, "isChained") or plan_query(self, "hasJueqingEffect", self.player))
	and (self:getCard("NatureSlash") or self:getCard("FireAttack") and plan_query(self.player, "getHandcardNum")>2) then
		use.to:append(self.player)
		use.card = card
		if use.to:length()>extraTarget
		then return end
	end
	for _,friend in ipairs(otherfriends)do
		if current_target(use,friend) then continue end
		if not use.to:contains(friend)
		and plan_can_to(self,card,friend)
		and plan_query(self, "hasHuangenEffect", friend) then
			use.to:append(friend)
			use.card = card
			if use.to:length()>extraTarget
			then return end
		end
	end
	if use.to:length()<2 then use.to = AIList.new({}) end
end


function SmartAIView:willUseLightning(card)
    return will_use_lightning(self,card) == true
end
local function lightning(self,card,use)
    if self:willUseLightning(card) then use.card = card end
end
ai_card_use.Collateral = function(self,card,use) return self:useCardCollateral(card,use) end
ai_card_use.Indulgence = function(self,card,use) return self:useCardIndulgence(card,use) end
ai_card_use.SupplyShortage = function(self,card,use) return self:useCardSupplyShortage(card,use) end
ai_card_use.Lightning = lightning
ai_card_use.IronChain = function(self,card,use) return self:useCardIronChain(card,use) end

-- 通用出牌流程：照優先序問每一張牌的策略，第一個提出計劃的就是答案。
-- 這裡不自己挑目標——activate 與 aiUseCard 是同一條路徑，同一張牌的判斷只有一份。
-- Owner skill callbacks choose which conversions enter the legacy turn list.
-- Enumerating every native conversion is not equivalent to fillSkillCards.
function SmartAIView:fillSkillCards(cards)
    cards = sgs.QList2Table(value_known(cards,"fill card list"))
    self.active_skill_requests = self.active_skill_requests or {}
    local function fill(name)
        local context = value_known(value_call(self, "getFillSkillContext", name), "fill skill context")
        if context.known ~= true or type(context.instance_id) ~= "number" then ai_unsupported("fill skill instance is unknown", name) end
        local instance, request = context.instance_id, context.request
        if instance > 0 and (not request or request:isValid() ~= true) then return end
        local callback = sgs.ai_fill_skill[name]
        if type(callback) ~= "function" and request then callback = sgs.ai_fill_skill[request:getSourceSkillName()] end
        if type(callback) ~= "function" or instance < 0 then return end
        if context.has_view_as == nil then ai_unsupported("view-as skill identity is unknown", name) end
        if context.has_view_as then
            if context.enabled_at_play == nil then ai_unsupported("view-as play availability is unknown", name) end
            if not context.enabled_at_play then return end
        end
        local filled = callback(self, #cards < 1, request)
        if AIUnsupported.is(filled) then error(filled, 0) end
        if AIValue.isCard(filled) or AIValue.isConversion(filled) then filled = {filled}
        elseif type(filled) ~= "table" then filled = {filled} end
        for _, card in ipairs(filled) do
            if AIUnsupported.is(card) then error(card, 0) end
            if AIValue.isCard(card) or AIValue.isConversion(card) then
                local seed=is_strategy_seed(card)
                local candidate = strategy_candidate(self, card)
                if not candidate and not seed then ai_unsupported("fill callback returned an unauthorized card", name) end
                if seed and (not request or instance<1) then ai_unsupported("strategy seed lacks an active source instance",name) end
                if instance > 0 and value_known(value_call(card, "isVirtualCard"), "filled virtual identity") then
                    if readonly_turn_conversion(self, card) then
                        if value_call(self, "readonlyTurnConversionMatchesRequest", card, request) ~= true then
                            ai_unsupported("filled readonly policy card does not match its skill instance", name)
                        end
                    elseif not AIValue.isConversion(card) and not seed
                        or card:getActivationInstanceId() ~= request:getActivationInstanceId()
                        or card:getActivationSkillName() ~= request:getActivationSkillName()
                        or card:getActivationOwner() ~= request:getActivationOwner()
                        or card:getSourceInstanceID() ~= request:getSourceInstanceID()
                        or card:getSourceSkillName() ~= request:getSourceSkillName()
                        or card:getSourceOwner() ~= request:getSourceOwner() then
                        ai_unsupported("filled policy card does not match its skill instance", name)
                    end
                end
                if request then self.active_skill_requests[card_key(card)] = request end
                table.insert(cards,card)
            end
        end
    end
    if type(sgs.getPlayerSkillList)~="function" then ai_unsupported("source fill skill roster unavailable","fillSkillCards") end
    for _, skill in ipairs(value_known(sgs.getPlayerSkillList(self.player), "fill skill roster")) do fill(skill:objectName()) end
    for _, mark in ipairs(value_known(self.player:getMarkNames(), "fill skill marks")) do
        if core_query(self.player,"getMark",mark) > 0 and mark:sub(1,12) == "ViewAsSkill_" then
            fill((mark:gsub("ViewAsSkill_", ""):gsub("Effect", "")))
        end
    end
    return cards
end

function SmartAIView:canMethodUse(card, turn_use)
    if is_strategy_seed(card) then
        -- Source canMethodUse checks the card's own handling-method availability.
        -- A separate MethodUse limitation is not equivalent for MethodDiscard seeds.
        return value_known(value_call(card,"isAvailable"),"strategy seed availability")
    end
    local candidate = strategy_candidate(self, card)
    if not candidate then ai_unsupported("turn card has no authority candidate", "canMethodUse") end
    -- The source short-circuits before querying KillOff for non-basic cards.
    -- Their availability does not depend on a projected strategy flag.
    if value_known(value_call(card, "getTypeId"), "card type") ~= 1 then
        return value_known(value_call(candidate, "isAvailable"), "turn card availability")
    end
    local kill
    if type(self.hasStrategyCardFlag) == "function" then kill = self:hasStrategyCardFlag(card, "AIGlobal_KillOff") end
    if kill == nil then kill = value_known(value_call(card, "hasFlag", "AIGlobal_KillOff"), "KillOff flag") end
    if kill then
        return value_known(value_call(candidate, "isAvailable"), "turn card availability")
    end
    local class = card:isKindOf("Slash") and "Slash" or card:getClassName()
    local offset = 0
    for _, prior in ipairs(turn_use) do if prior:isKindOf(class) then offset = offset + 1 end end
    return value_known(value_call(candidate, "isAvailableWithHistoryOffset", offset, class), "hypothetical card history availability")
end

-- updatePlayers(false) observes the previous completed planner list, not a
-- newly constructed facade's empty table. No facade or authority ticket is
-- retained. Zhaogujing consumes the last basic/ND-trick summary; source
-- table.contains(toUse, card) readers consume a separate ordered identity list.
local function turn_use_summary(cards)
    local summary={known=true,count=#cards}
    for _,card in ipairs(cards) do
        local kind=value_call(card,"getTypeId")
        local relevant=kind==1
        if kind==nil then return {known=false,count=#cards} end
        if not relevant then
            relevant=value_call(card,"isNDTrick")
            if relevant==nil then return {known=false,count=#cards} end
        end
        if relevant then
            local virtual=value_call(card,"isVirtualCard")
            if type(virtual)~="boolean" then return {known=false,count=#cards} end
            local id=not virtual and value_call(card,"getEffectiveId") or nil
            if not virtual and (type(id)~="number" or id<0) then return {known=false,count=#cards} end
            summary.last={virtual=virtual,physical_id=id,legacy_identity_token=value_call(card,"getLegacyIdentityToken")}
        end
    end
    return summary
end
function SmartAIView:getTurnUseSummary()
    local summary
    if self.toUse~=nil then summary=turn_use_summary(self.toUse)
    else
        local present
        summary,present=self:getStrategyMemory("turn_use_summary")
        if not present then
            local count,known=self:getStrategyMemory("turn_use_count")
            if not known or count==0 then summary={known=true,count=0} end
        end
    end
    if type(summary)~="table" or summary.known~=true then
        ai_unsupported("previous turn-use card identity is unknown","turn_use_summary")
    end
    return summary
end
local function turn_use_identities(cards)
    local state={known=true,count=#cards,tokens={}}
    for _,card in ipairs(cards) do
        local token=value_call(card,"getLegacyIdentityToken")
        if type(token)~="string" or token=="" then return {known=false,count=#cards} end
        state.tokens[#state.tokens+1]=token
    end
    return state
end
local function turn_use_faces(cards, scratch)
    local state={count=#cards,rows={},estimates=copy_strategy_state(scratch and scratch.knowledge_estimates or {})}
    for _,card in ipairs(cards) do
        -- These observations reproduce only Analeptic's class/string reads.
        -- Never retain a capability, CardView or authority cost in memory.
        local row={identity=value_call(card,"getLegacyIdentityToken"),
            is_slash=value_call(card,"isKindOf","Slash")}
        if row.is_slash~=true then row.legacy_string_key=value_call(card,"getLegacyStringKey") end
        if value_call(card,"isVirtualCard")==false then
            local id=value_call(card,"getEffectiveId")
            if finite_number(id) and id>=0 and id%1==0 then row.physical_id=id end
        end
        state.rows[#state.rows+1]=row
    end
    return state
end
function SmartAIView:hasPriorPlannedSlash()
    if self.toUse~=nil then
        for _,card in ipairs(self.toUse) do
            if plan_query(card,"isKindOf","Slash")
                or plan_query(card,"getLegacyStringKey"):match("slash") then return true end
        end
        return false
    end
    local count=self:getPriorTurnUseCount()
    if count==0 then return false end
    local state,present=self:getStrategyMemory("turn_use_faces")
    if not present or type(state)~="table" or state.count~=count
        or not AIValue.isList(state.rows) or #state.rows~=count then
        ai_unsupported("Analeptic prior planned card faces are unavailable","Analeptic")
    end
    for _,entry in ipairs(state.estimates or {}) do
        local estimate=copy_strategy_state(entry)
        estimate.status,estimate.value,estimate.count="estimate",true,nil
        self:useKnowledgeEstimate(estimate,entry.context or "turn_use_faces.cached")
    end
    for _,row in ipairs(state.rows) do
        if type(row)~="table" or type(row.identity)~="string" or row.identity=="" then
            ai_unsupported("prior planned face identity is unknown","Analeptic")
        end
        local current
        if finite_number(row.physical_id) and row.physical_id>=0 and row.physical_id%1==0 then
            current=self:getKnownCardById(row.physical_id)
            if current and value_call(current,"getLegacyIdentityToken")~=row.identity then current=nil end
        end
        local matches
        if current then
            -- Same WrappedCard identity can have a new face after takeOver.
            -- Its currently disclosed view, not the cached face, is authoritative.
            matches=plan_query(current,"isKindOf","Slash")
                or plan_query(current,"getLegacyStringKey"):match("slash")~=nil
        else
            if type(row.is_slash)~="boolean"
                or not row.is_slash and type(row.legacy_string_key)~="string" then
                ai_unsupported("prior planned face observation is incomplete","Analeptic")
            end
            matches=row.is_slash or row.legacy_string_key:match("slash")~=nil
            matches=self:useKnowledgeEstimate({status="estimate",value=matches,
                basis="turn_use_faces.last_observation_not_currently_disclosed",
                observer=self.player:objectName()},"Analeptic.prior_toUse")
        end
        if matches then return true end
    end
    return false
end
function SmartAIView:wasPreviouslyPlannedCard(card)
    if self.toUse~=nil then
        for _,prior in ipairs(self.toUse) do
            if self:sameLegacyCard(prior,card) then return true end
        end
        return false
    end
    local state,present=self:getStrategyMemory("turn_use_identities")
    if not present then
        local count,known=self:getStrategyMemory("turn_use_count")
        -- SmartAI initializes toUse={}. Older nonempty cache versions cannot
        -- reconstruct the missing identities from count or the last-card ID.
        if not known or count==0 then return false end
    end
    if type(state)~="table" or state.known~=true or type(state.count)~="number"
        or state.count<0 or state.count%1~=0 or not AIValue.isList(state.tokens)
        or #state.tokens~=state.count then
        ai_unsupported("previous turn-use equality identities are unknown","turn_use_identities")
    end
    if state.count==0 then return false end
    local token=value_call(card,"getLegacyIdentityToken")
    if type(token)~="string" or token=="" then
        ai_unsupported("native strategy card equality identity is unknown","card_identity")
    end
    for _,prior in ipairs(state.tokens) do
        if type(prior)~="string" or prior=="" then
            ai_unsupported("previous turn-use equality identity is malformed","turn_use_identities")
        end
        if prior==token then return true end
    end
    return false
end
function SmartAIView:getPriorTurnUseCount()
    if self.toUse~=nil then return #self.toUse end
    local count,known=self:getStrategyMemory("turn_use_count")
    if not known then return 0 end -- Source initialize creates an empty list.
    if not finite_number(count) or count<0 or count%1~=0 then
        ai_unsupported("previous turn-use count is malformed","turn_use_count")
    end
    return count
end
function SmartAIView:getPriorTurnUseCards()
    if self.toUse~=nil then return self.toUse end
    if self._prior_turn_use_cards then return self._prior_turn_use_cards end
    local count=self:getPriorTurnUseCount()
    if count==0 then return {} end
    local state,present=self:getStrategyMemory("turn_use_plans")
    if not present or type(state)~="table" or not AIValue.isList(state.rows)
        or state.count~=count or #state.rows~=count then
        ai_unsupported("prior turn plan observations are unavailable","prior_turn_plan")
    end
    for _,entry in ipairs(state.estimates or {}) do
        local estimate=copy_strategy_state(entry)
        estimate.status,estimate.value,estimate.count="estimate",true,nil
        self:useKnowledgeEstimate(estimate,entry.context or "prior_turn_plan.cached")
    end
    local cards={}
    for _,row in ipairs(state.rows) do cards[#cards+1]=self:restorePriorTurnPlan(row) end
    self._prior_turn_use_cards=cards
    return cards
end
function SmartAIView:recordTurnUse(cards)
    self.toUse = cards
    local plans={count=#cards,rows={},estimates=copy_strategy_state(self.request and self.request.scratch and self.request.scratch.knowledge_estimates or {})}
    for _,card in ipairs(cards) do plans.rows[#plans.rows+1]=self:capturePriorTurnPlan(card) end
    value_known(value_call(self,"setStrategyMemory","turn_use_plans",plans),"turn-use plan observation write")
    value_known(value_call(self,"setStrategyMemory","turn_use_count",#cards),"turn-use memory write")
    value_known(value_call(self,"setStrategyMemory","turn_use_summary",turn_use_summary(cards)),"turn-use summary write")
    value_known(value_call(self,"setStrategyMemory","turn_use_identities",turn_use_identities(cards)),"turn-use equality memory write")
    value_known(value_call(self,"setStrategyMemory","turn_use_faces",turn_use_faces(cards,self.request and self.request.scratch)),"turn-use face memory write")
    return cards
end

function SmartAIView:refreshModeForActivate()
    if not self.request or self.request.kind~="activate" then return end
    local policy=self.world and self.world.mode_policy
    if type(policy)~="table" or policy.standard_identity~=true then return end
    if type(self.getStrategyMemory)~="function" or type(ai_mode_refresh)~="function" then
        ai_unsupported("Activate relation refresh bridge is unavailable","updatePlayers")
    end
    local count,known=self:getStrategyMemory("turn_use_count")
    if not known then count=0 end -- SmartAI initialization sets toUse={}.
    if not finite_number(count) or count<0 or count%1~=0 then
        ai_unsupported("invalid previous turn-use count","updatePlayers")
    end
    local ok,result=pcall(ai_mode_refresh,count)
    if not ok or type(result)~="table" or type(result.relations)~="table"
        or type(result.strategy_marks)~="table" or not AIValue.isList(result.estimated_branches) then
        ai_unsupported("Activate relation refresh failed","updatePlayers")
    end
    for name,relation in pairs(result.relations) do
        if type(name)~="string" or not self.room:findPlayerByObjectName(name)
            or relation~="friend" and relation~="enemy" and relation~="neutral" then
            ai_unsupported("invalid refreshed relation row","updatePlayers")
        end
    end
    policy.strategy_marks=copy_strategy_state(result.strategy_marks)
    policy.relations=policy.relations or {}
    policy.relations[self.player:objectName()]=copy_strategy_state(result.relations)
    for _,basis in ipairs(result.estimated_branches) do
        if type(basis)~="string" then ai_unsupported("invalid refresh estimate basis","updatePlayers") end
        value_known(value_call(self,"useKnowledgeEstimate",{value=0,status="estimate",basis=basis},"updatePlayers"),"refresh estimate")
    end
end

-- BEGIN R37 ORIGINAL INITIALIZE PRESENCE
-- R37 owner-only source lifecycle. Absence of a witness is never constructor {}.
local function original_turn_presence(self,write)
    if type(ai_original_turn_use_presence)~='function'then return nil end
    local row=write and ai_original_turn_use_presence(write)or ai_original_turn_use_presence()
    if AIUnsupported.is(row)then error(row,0)end
    local request=self.request
    if type(row)~='table'or getmetatable(row)~=nil or row.kind~='original_turn_use_presence'
        or type(row.known)~='boolean'or(row.state~='empty'and row.state~='nil'and row.state~='unknown')
        or row.known~=(row.state~='unknown')or type(request)~='table'
        or row.viewer~=request.viewer or row.decision_id~=request.decision_id
        or row.state_revision~=request.state_revision or type(row.continuity_stamp)~='string'
        or not row.continuity_stamp:match('^%d+$')or(write and row.state~=write)then
        return nil
    end
    return row
end
function SmartAIView:restoreOriginalHegemonyTurnUsePresence()
    if self._original_to_use_restored then return end
    self._original_to_use_restored=true
    local row=original_turn_presence(self)
    self._original_to_use_stamp=row and row.continuity_stamp
    if row and row.known then
        if row.state=='empty'then self.toUse={}else self.toUse=nil end
    else self.toUse=nil;self._original_to_use_unavailable=true end
end
function SmartAIView:recordOriginalHegemonyTurnUsePresence()
    local state
    if self.toUse==nil then state='nil'
    elseif type(self.toUse)=='table'and #self.toUse==0 then state='empty'
    else state='unknown'end
    local row=original_turn_presence(self,state)
    if not row then ai_unsupported('Original toUse write witness unavailable','original_initialize.toUse')end
    self._original_to_use_stamp=row.continuity_stamp
    self._original_to_use_restored=true;self._original_to_use_unavailable=nil
end
function SmartAIView:getOriginalHegemonyCurrentTurnUse()
    local row=original_turn_presence(self)
    if self._original_to_use_unavailable or not row or row.continuity_stamp~=self._original_to_use_stamp then
        ai_unsupported('Original toUse continuity is unknown or interrupted','original_initialize.toUse')
    end
    -- An assigned nonempty list stays the actual same-request source object.
    -- The native witness is unknown for a future inquiry, never a stale receipt.
    return self.toUse
end
-- END R37 ORIGINAL INITIALIZE PRESENCE
local original_turn_numbers={retain=2,predictedRange=1,slashAvail=1}
function SmartAIView:restoreOriginalTurnState()
    local state,present=self:getStrategyMemory("original_turn_state")
    if present and type(state)~="table" then ai_unsupported("Original turn cache is malformed","original_turn_state")end
    state=present and state or original_turn_numbers
    for key,initial in pairs(original_turn_numbers)do
        local value=state[key]
        if not finite_number(value) then ai_unsupported("Original turn scalar is unknown",key)end
        self[key]=value
    end
    for _,key in ipairs({"weaponUsed","slash_distance_limit"})do
        local value=state[key]
        if value~=nil and type(value)~="boolean" then ai_unsupported("Original turn flag is malformed",key)end
        self[key]=value
    end
    self.kept=self.kept or {}
    self:restoreOriginalHegemonyTurnUsePresence()
end
function SmartAIView:persistOriginalTurnState()
    local state={}
    for key in pairs(original_turn_numbers)do
        local value=self[key]
        if not finite_number(value) then ai_unsupported("Original turn scalar is unknown",key)end
        state[key]=value
    end
    for _,key in ipairs({"weaponUsed","slash_distance_limit"})do
        local value=self[key]
        if value~=nil and type(value)~="boolean" then ai_unsupported("Original turn flag is malformed",key)end
        state[key]=value
    end
    self:setStrategyMemory("original_turn_state",state)
end
-- Original Hegemony common386/454/3778: no ordinary revise pass and no
-- dummy target list. Only the final proposal is authority-validated below.
local function hpipe_q(object,method,...)
 if AIValue.isPlayer(object)then
  if method=='hasFlag'then method='getStrategyFlag'elseif method=='getMark'then method='getStrategyMark'end
 end
 if not object or type(object[method])~='function'then ai_unsupported('Original pipeline dependency unavailable',method)end
 local value=object[method](object,...)
 if AIUnsupported.is(value)then error(value,0)end
 if value==nil then ai_unsupported('Original pipeline fact unavailable',method)end
 return value
end
local function hpipe_owner_fact(self,key)
 local value=self.world.strategy_facts and self.world.strategy_facts[key]
 if value==nil then ai_unsupported('Original owner pipeline fact unavailable',key)end
 return value
end
local function hpipe_dispatch(self,card,use,kind)
 local method=({[0]='useSkillCard',[1]='useBasicCard',[2]='useTrickCard',[3]='useEquipCard'})[kind]
 if not method or type(self[method])~='function'then ai_unsupported('Original card type dispatcher unavailable',tostring(kind))end
 self[method](self,card,use)
end
local function original_get_turn_use(self)
    -- Native V2 fill binds each candidate to the current activation request.
    self.active_skill_requests = {}
	local cards = {}
	for _ ,c in sgs.qlist(hpipe_q(self.player,"getHandcards")) do
		if hpipe_q(c,"isAvailable",self.player) then table.insert(cards, c) end
	end
	for _, id in sgs.qlist(hpipe_q(self.player,"getPile","wooden_ox")) do
		local c = hpipe_q(self,"getKnownCardById",id)
		if hpipe_q(c,"isAvailable",self.player) then table.insert(cards, c) end
	end

	local turnUse = {}
	local slash = hpipe_q(self,"getEvaluationCard","slash")
	local slashAvail = 1 + hpipe_q(slash,"getTargetModResidue",self.player)
	self.slashAvail = slashAvail
	self.predictedRange = hpipe_q(self.player,"getAttackRange")
	self.slash_distance_limit = (1 + hpipe_q(slash,"getTargetModDistance",self.player) > 50)

	self.weaponUsed = false
	self:fillSkillCards(cards)

	if hpipe_q(self.player,"hasWeapon","Crossbow") or #hpipe_owner_fact(self,"owner_extra_slash_specific_assignee"):split("+") > 1 then
		slashAvail = 100
		self.slashAvail = slashAvail
	end
	local slashes = {}

	for _, card in ipairs(cards) do

		local dummy_use = { isDummy = true }

		local type = hpipe_q(card,"getTypeId")
		hpipe_dispatch(self,card,dummy_use,type)

		if dummy_use.card then
			if hpipe_q(dummy_use.card,"isKindOf","Slash") then
				if hpipe_q(self,"hasStrategyCardFlag",dummy_use.card,"AIGlobal_KillOff") then table.insert(slashes, dummy_use.card) break end
				table.insert(slashes, dummy_use.card)
			else
				if hpipe_q(self.player,"hasFlag","InfinityAttackRange") or hpipe_q(self.player,"getMark","InfinityAttackRange") > 0 then
					self.predictedRange = 10000
				elseif hpipe_q(dummy_use.card,"isKindOf","Weapon") then
					self.predictedRange = self:originalHegemonyWeaponRange(hpipe_q(card,"getClassName")) or 1
					self.weaponUsed = true
				else
					self.predictedRange = 1
				end
				if hpipe_q(dummy_use.card,"objectName") == "Crossbow" then slashAvail = 100 self.slashAvail = slashAvail end
				table.insert(turnUse, dummy_use.card)
			end
			if hpipe_q(self,"getDynamicUsePriority",dummy_use.card) >= 9 then break end
		end
	end

	if slashAvail > 0 and #slashes > 0 then
		self:sortByUseValue(slashes)
		for i = 1, slashAvail do
			table.insert(turnUse, slashes[i])
		end
	end

	return turnUse
end

function SmartAIView:originalHegemonyGetTurnUse()
    -- The donor retains these prediction fields between all inquiries, including
    -- mutations made before a failing strategy callback. Never cache card views.
    local result=table.pack(pcall(original_get_turn_use,self))
    self:persistOriginalTurnState()
    if not result[1]then error(result[2],0)end
    return table.unpack(result,2,result.n)
end

function SmartAIView:originalHegemonyActivate(use)
	hpipe_q(self,"updatePlayers")
	self:assignKeep(true)
	self.toUse = hpipe_q(self,"getTurnUse")
    self:recordOriginalHegemonyTurnUsePresence()
	self:sortByDynamicUsePriority(self.toUse)
	for _, card in ipairs(self.toUse) do
		if not hpipe_q(self.player,"isCardLimited",card, hpipe_q(card,"getHandlingMethod"))
			or (hpipe_q(card,"canRecast") and not hpipe_q(self.player,"isCardLimited",card, sgs.Card_MethodRecast)) then
			local type = hpipe_q(card,"getTypeId")

			hpipe_dispatch(self,card,use,type)

			if use.card ~= nil then
				self:clearOriginalHegemonyTurnUse()
				return
			end
			if use.card and hpipe_q(use.card,"isKindOf","Slash") and (not use.to or hpipe_q(use.to,"isEmpty")) then
				self:clearOriginalHegemonyTurnUse()
				return
			end

			if use.card then self:speak(hpipe_q(use.card,"getClassName"), hpipe_q(self.player,"isFemale")) end
		end
	end
	self:clearOriginalHegemonyTurnUse()
end





function SmartAIView:originalHegemonyUseTrickCard(card, use)
	if not card then return end
	if hpipe_q(self,"needRende") and not hpipe_q(card,"isKindOf","ExNihilo") then return end
	self:useCardByClassName(card, use)
end


local function original_turn_pipeline(self)
    local facts=self.world and self.world.strategy_facts and self.world.strategy_facts.hegemony
    return facts and facts.enabled==true and facts.original_overrides_loaded==true
end
function SmartAIView:clearOriginalHegemonyTurnUse()
    -- activate clears its list on both success and pass. Persist that empty
    -- observational state, never CardView objects, before the next request.
    self:recordTurnUse({})
    self.toUse=nil
    self:recordOriginalHegemonyTurnUsePresence()
end
function SmartAIView:originalHegemonyPlanTurnUse()
    local use=AIUsePlan.new()
    self:originalHegemonyActivate(use)
    if use.card and value_call(use.card,"isEvaluationOnly")==true then
        -- Original selectors can reason about lawful hypothetical conversions.
        -- Bind only the already selected specification; never retry strategy
        -- callbacks or switch costs after an authority denial.
        use.card=value_known(value_call(self,"materializeOriginalSelectedCard",use.card),"Original selected card authority")
    end
    local plan,status=self:validateStrategyUsePlan(use)
    if status=="unsupported" then error(plan,0) end
    if status=="declined" then return nil end
    local answer=plan:toAnswer()
    if not answer then ai_unsupported("Original final plan cannot be serialized","planning")end
    return answer,plan
end

function SmartAIView:getTurnUse(allow_partial)
    if original_turn_pipeline(self) then return self:originalHegemonyGetTurnUse() end
    -- Preserve the existing isolated package convenience only when explicitly
    -- requested, but never erase its coverage debt at this decision boundary.
    -- getOfferedTurnUse itself retains its lower-level diagnostic tuple.
    if allow_partial == true then
        local offered,unknown=self:getOfferedTurnUse(true,false)
        if unknown then error(unknown,0) end
        return offered
    end
    local turn_use, plans, unknown = AIList.new({}), {}, nil
    self.use_to, self.active_skill_requests = {}, {}
    local limit, penalty = self:getUsageState()
    local restricted = limit <= 1 or penalty
    local zhixi_cost = core_query(self.player, "hasSkill", "zhixi")
    local hand_num = core_query(self.player, "getHandcardNum")
    local fill_ok, cards = pcall(function()
        return self:fillSkillCards(value_known(self:addHandPile(), "turn hand and piles"))
    end)
    if not fill_ok or AIUnsupported.is(cards) then
        self:recordTurnUse(turn_use)
        -- Fixed source 4954 catches an ordinary fill callback error and makes
        -- the turn list empty. Missing migration facts are a different signal.
        return turn_use, plans, AIUnsupported.is(cards) and cards or nil
    end
    local sort_ok, sorted = pcall(self.sortByDynamicUsePriority, self, cards)
    if not sort_ok or AIUnsupported.is(sorted) then
        self:recordTurnUse(turn_use)
        return turn_use, plans, AIUnsupported.is(sorted) and sorted or nil
    end
    cards = sorted
    -- These are explicit donor result-shape branches (4977–4987), not a
    -- fallback for unknown facts: exact getters must throw AIUnsupported.
    if type(cards) ~= "table" then
        self:recordTurnUse(turn_use)
        return turn_use, plans
    end
    for _, card in ipairs(cards) do
      if card then
        local processed, signal = AIUnsupported.capture(function()
            if restricted and self:getUseValue(card) < 5.5 and not value_known(value_call(card, "isDamageCard"), "damage card") then return end
            local can_ok, can_use = pcall(self.canMethodUse, self, card, turn_use)
            if not can_ok then
                if AIUnsupported.is(can_use) then error(can_use, 0) end
                return -- Source catches availability callback errors per card.
            end
            if not can_use then return end
            -- Source dummy(false) deliberately fires used-revise callbacks.
            local input = AIUsePlan.new(); input.isDummy = false
            local success, result, status = pcall(self.tryUseCard, self, card, input, false, true)
            if not success then
                if AIUnsupported.is(result) then unknown = unknown or result; return end
                -- The donor's recast branch is reached only when aiUseCard
                -- throws, not when a strategy declines or lacks projection.
                if value_known(value_call(card, "canRecast"), "recast ability") and value_known(value_call(card, "getTypeId"), "card type") > 0 then
                    local candidate = strategy_candidate(self, card)
                    -- Source appends the recast proposal even if its empty
                    -- target sequence is illegal. Preserve its position; the
                    -- activate authority gate must reject, never select a
                    -- later card on behalf of that failed first proposal.
                    local recast = AIUsePlan.new(); recast.card = card
                    recast.candidate_id = value_call(candidate, "getCandidateId")
                    turn_use:append(card); plans[#plans + 1] = recast
                end
                return
            end
            if status == "unsupported" then unknown = unknown or result; return end
            if result and result.card then
                if not self:sameLegacyCard(result.card, card) then
                    local limit_ok, limited = pcall(function()
                        local method = value_known(value_call(result.card, "getHandlingMethod"), "replacement handling method")
                        return value_known(value_call(self.player, "isCardLimited", result.card, method), "replacement card limit")
                    end)
                    if not limit_ok then
                        if AIUnsupported.is(limited) then error(limited, 0) end
                        return -- Source treats a failed replacement limit query as limited.
                    end
                    if limited then return end
                end
                if penalty and not (value_known(value_call(result.card, "isDamageCard"), "damage card") or result.card:isKindOf("Peach") or math.random() < 0.5) then return end
                local add_ok, add_error = pcall(function()
                    local key = legacy_sort_key(result.card)
                    local targets = {}
                    for _, target in ipairs(result.to or {}) do targets[#targets + 1] = target:objectName() end
                    self.use_to[key] = targets
                    turn_use:append(result.card); plans[#plans + 1] = result
                end)
                -- This is a separate source pcall: malformed callback targets
                -- do not discard later candidates. Missing typed facts still
                -- carry coverage debt instead of becoming known absence.
                if not add_ok and AIUnsupported.is(add_error) then error(add_error, 0) end
            end
        end)
        if not processed then unknown = unknown or signal end
        if #turn_use > 3 then break end
      end
    end
    self:recordTurnUse(turn_use)
    return turn_use, plans, unknown
end

function SmartAIView:planTurnUse()
    if original_turn_pipeline(self) then return self:originalHegemonyPlanTurnUse() end
    local success, cards, plans, unknown = pcall(self.getTurnUse,self)
    if not success then
        if AIUnsupported.is(cards) then error(cards,0) end
        return nil -- activate5175 catches the whole donor getTurnUse body.
    end
    -- The diagnostic tuple may contain independently known proposals, but an
    -- unknown earlier/later callback can alter source order or use_to state.
    -- Logging that debt while answering would falsely certify partial planning.
    if unknown then error(unknown, 0) end
    if #cards > 0 then
        local first = plans[1]
        if first then
            -- activate rebuilds its first card's targets from the last write to
            -- use_to[aiCardKey]. Two distinct receipts can have the same source
            -- key: preserve that overwrite without borrowing their authority.
            local saved=self.use_to[legacy_sort_key(first.card)] or {}
            local targets,names=AIList.new({}),{}
            for _,name in ipairs(saved) do
                local target=self.room:findPlayerByObjectName(name)
                if target then targets:append(target);names[#names+1]=name end
            end
            if readonly_turn_conversion(self, first.card) then
                -- Preserve the already chosen source proposal and cached
                -- target order. Authority refusal is terminal: never rerun the
                -- callback, change material, or promote a later proposal.
                local paid = value_call(self, "materializeTurnSelectedCard", first.card)
                if AIUnsupported.is(paid) then error(paid, 0) end
                first.card = value_known(paid, "selected turn conversion authority")
            end
            local candidate=authority_candidate(self,first.card)
            if not candidate or value_call(candidate,"hasCompleteCoverage")~=true then
                ai_unsupported("activate target authority is incomplete","planning")
            end
            local legal
            if value_call(candidate,"targetFixed") then
                legal=#names==0 and value_call(candidate,"isFeasibleWithNoTarget")==true
            else
                local _,finish=candidate:getTargetSelection(names)
                legal=finish==true
            end
            if not legal then
                ai_unsupported("source cached targets do not belong to the first card authority","planning")
            end
            first.to=targets
            local validated,status=self:validateStrategyUsePlan(first)
            if status=="unsupported" then error(validated,0) end
            if status~="planned" then ai_unsupported("first source proposal was not a final action","planning") end
            first=validated
        end
        local answer = first and first:toAnswer()
        if answer then return answer, first, unknown end
        unknown = unknown or AIUnsupported.new("planned action cannot be serialized", "planning")
    end
    if unknown then error(unknown, 0) end
    return nil
end

-- 逐技能 activate registry：key 是 activation_skill 名。各技能腳本用
-- ai_skill_activate["xxx"] = function(self, request) ... end 掛自己的出牌策略，
-- 回 nil 表示這次不啟動，繼續問下一個；都沒人接才落到通用出牌規劃。
ai_skill_activate = {}

-- 通用 activate：沒有任何武將策略時的預設出牌流程。
if type(ai_coverage) == "table" then
    ai_coverage.declare("activate", function()
        local keys = {"generic"}
        for key in pairs(ai_skill_activate) do keys[#keys + 1] = key end
        return keys
    end)
end

ai_register_handler("activate", function(self, request)
    -- 逐實例探測（request.skill_action）問的是「要不要啟動這個實例」：只派給
    -- 該技能的 handler，沒註冊或拒答就回 nil 記錄未處理，不讓通用規劃的答案
    -- 套到不相干的實例上。
    local probe = type(request.skill_action) == "table" and request.skill_action or nil
    if probe then
        local handler = ai_skill_activate[probe.activation_skill]
        return handler and handler(self, request) or nil
    end
    -- 一般 activate：按權威端給的 skill_actions 順序，先命中的技能 handler 先答。
    if type(request.skill_actions) == "table" then
        for _, action in ipairs(request.skill_actions) do
            local handler = type(action) == "table"
                and ai_skill_activate[action.activation_skill] or nil
            if handler then
                local result = handler(self, request)
                if result ~= nil then return result end
            end
        end
    end
    -- Unknown active skills prevent a pass, but do not veto an independently
    -- authorized card proposal. Defer their coverage debt until after planning.
    local unknown_skill
    if type(request.skill_actions) == "table" then
        local conversions = self:getConversions()
        -- Build the authorized conversion coverage index once per request.  The old
        -- action x conversion nested scan repeated the same lookup for every skill.
        local conversion_by_skill = {}
        if self:hasEnumeratedConversions() and conversions then
            for _, conversion in ipairs(conversions) do
                -- Unknown identity does not cover a skill or abort other cards.
                local key = type(conversion.getActivationSkillName) == "function"
                    and conversion:getActivationSkillName() or nil
                if type(key) == "string" and key ~= "" then
                    conversion_by_skill[key] = conversion_by_skill[key] or {}
                    conversion_by_skill[key][#conversion_by_skill[key] + 1] = conversion
                end
            end
        end
        for _, action in ipairs(request.skill_actions) do
            local key = type(action) == "table" and action.activation_skill or nil
            if type(key) == "string" and key ~= "" and not ai_skill_activate[key] then
                -- Limu's fixed complete fill/revise/usefunc family runs in
                -- planTurnUse below. A source nil fill is a covered decline,
                -- not evidence that a native conversion must already exist.
                -- This finite acknowledgement grants no candidate/authority;
                -- all collector unknowns and final validation remain below.
                local covered = (key == "xuanzhu" or key == "xufa" or key == "olspxixiang" or key == "limu" or key == "fuzhai" or key == "olquxi" or key == "miuyan" or key == "huiyun" or key == "zonglve") and type(sgs.ai_fill_skill[key]) == "function"
                -- 列不完就不能宣稱覆蓋：那是「不知道這個技能變得出什麼」。
                if self:hasEnumeratedConversions() and conversion_by_skill[key] then
                    covered = true
                    -- planTurnUse evaluates these conversions, including actual
                    -- connected hook probes when no family strategy exists.
                end
                if not covered then
                    unknown_skill = unknown_skill or AIUnsupported.new(
                        "an active skill in this turn has no isolated strategy", key)
                end
            end
        end
    end
    local plan, _, unknown = self:planTurnUse()
    if unknown then error(unknown, 0) end
    if unknown_skill then error(unknown_skill, 0) end
    if not plan then return {kind = "pass"} end
    return plan
end)


-- R31: optional equipment is source nil when absent, but a missing public
-- equipment snapshot is not evidence of absence. Keep each original getter call.
local function nullify_equipment(player, method)
    if AIValue.isPlayer(player) then damage_call(player, "getEquips") end
    local value = player[method](player)
    if AIUnsupported.is(value) then error(value, 0) end
    return value
end

function SmartAIView:evaluateCardThreat(use, target)
    local card = use.card
    local card_class = damage_call(card,"getClassName")
    local threat_level = 0

    -- O(1) 查表 (Table Lookup)
    local rule = sgs.ai_nullification_threat_table[card_class]

    if rule then
        -- 命中註冊表：注入上下文並執行專屬閉包
        threat_level = threat_level + (rule.base or 0)
        if type(rule.eval) == "function" then
            threat_level = rule.eval(self, use, target, threat_level)
            if AIUnsupported.is(threat_level) then error(threat_level, 0) end
        end
    else
        -- 兜底邏輯 (Fallback)：處理未註冊的自定義/新擴展卡牌
        local is_trick = damage_call(card,"getTypeId") == sgs.Card_TypeTrick
        local is_damage = damage_call(card,"isDamageCard")
        local use_value = sgs.ai_use_value[card_class] or 0

        if is_damage then
            threat_level = threat_level + 1
            if damage_call(self,"isWeak",target) then threat_level = threat_level + 2 end
        elseif is_trick then
            threat_level = threat_level + (use_value >= 5 and 2 or 1)
        end
    end

    -- 通用修飾器：目標擁有受傷收益技能時降低威脅
    if damage_call(card,"isDamageCard") and damage_call(self,"canDamage",target, use.from, card) then
        threat_level = threat_level - 2
    end

    return threat_level
end


-- 通用的有代价令牌无效技能判断函数
-- 判断是否应该发动需要弃牌/失去体力来无效卡牌的技能
-- @param use 卡牌使用结构
-- @param need_discard 是否需要弃牌
-- @param need_losehp 是否需要失去体力
-- @param discard_num 需要弃牌数量
-- @param target 受影响的目标，默认为self.player
-- @return boolean 是否应该发动技能
function SmartAIView:shouldInvokeCostNullifySkill(use, need_discard, need_losehp, discard_num, target)
	if not use or not use.from or damage_call(use.from,"isDead") then return false end

	target = target or self.player
	discard_num = discard_num or 1

	-- 判断敌我关系（基于target和use.from）
	local is_enemy_user = damage_call(self,"isEnemy",use.from)
	local is_friend_user = damage_call(self,"isFriend",use.from)
	local target_is_friend = damage_call(self,"isFriend",target)
	local target_is_enemy = damage_call(self,"isEnemy",target)

	-- 检查代价是否可以承受
	if need_losehp then
		-- 需要失去体力的情况
		if damage_call(self.player,"getHp") <= 1 and damage_call(self,"getAllPeachNum") < 1 then
			-- 体力为1且无桃时，只在极端情况下发动
			if not (is_enemy_user and damage_call(use.card,"isKindOf","Peach")) then
				return false
			end
		end
		-- 体力过低时谨慎
		if damage_call(self,"isWeak") and not damage_call(self,"needToLoseHp",self.player, use.from, use.card) then
			if damage_call(self.player,"getHp") - 1 <= 0 then
				return false
			end
		end
	end

	if need_discard then
		-- 需要弃牌的情况
		if not damage_call(self.player,"canDiscard",self.player, "he") then
			return false
		end
		if damage_call(self.player,"getCardCount",true) < discard_num then
			return false
		end
	end

	-- 基本情况：残局中与攻击者同阵营且目标濒死时的判断
	if self.role == "rebel" and damage_call(self,"getRoleEstimate",use.from) == "rebel"
		and damage_call(self,"hasJueqingEffect",use.from, target) and damage_call(target,"getHp") < 2
		and damage_call(self,"getAllPeachNum") < 1 and target_is_friend then
		return false
	end

	-- 判断是否应该为目标无效
	-- 如果目标是友方，且使用者是敌人，应该发动
	-- 如果目标是敌人，且使用者是友方（例如桃），不应该发动
	local should_nullify = false

	if target_is_friend then
		-- 目标是友方时
		should_nullify = is_enemy_user
			or (is_friend_user and self.role == "loyalist" and not damage_call(use.from,"hasSkill","jueqing")
				and damage_call(use.from,"isLord") and damage_call(target,"getHp") < 2)
	elseif target_is_enemy then
		-- 目标是敌人时，通常不无效（除非是有益卡牌）
		if damage_call(use.card,"isKindOf","Peach") or damage_call(use.card,"isKindOf","Analeptic")
			or damage_call(use.card,"isKindOf","GodSalvation") or damage_call(use.card,"isKindOf","ExNihilo") then
			should_nullify = true
		end
	end

	if not should_nullify then return false end

	-- 通用判断逻辑：基于卡牌对目标的威胁程度
	local card = use.card
	local threat_level = self:evaluateCardThreat(use, target)  -- source may return nil from rule.eval
	if AIUnsupported.is(threat_level) then error(threat_level, 0) end

	-- 1. 判断卡牌是否对目标有效
	if not damage_call(self,"hasTrickEffective",card, target, use.from) then
		return false
	end

	-- 2. 判断伤害类卡牌
	if damage_call(card,"isDamageCard") then
		-- 检查伤害是否有效
		local nature = sgs.DamageStruct_Normal
		if damage_call(card,"isKindOf","FireSlash") or damage_call(card,"isKindOf","FireAttack") then
			nature = sgs.DamageStruct_Fire
		elseif damage_call(card,"isKindOf","ThunderSlash") then
			nature = sgs.DamageStruct_Thunder
		end

		if not damage_call(self,"damageIsEffective",target, nature, use.from) then
			return false
		end

		-- 计算预期伤害
	local card_nature = nature or (card and sgs.card_damage_nature[damage_call(card,"getClassName")])
	local expected_damage = damage_call(self,"ajustDamage",use.from, target, 1, card, card_nature)

	-- 高伤害直接发动
	if expected_damage > 1 then
		threat_level = threat_level + 3
	elseif expected_damage > 0 then
		threat_level = threat_level + 2
	end

	-- 濒死状态下任何伤害都是高威胁
	if damage_call(self,"isWeak",target) then
		threat_level = threat_level + 3
	end

	-- 属性杀连环判断
	if damage_call(card,"isKindOf","NatureSlash") and damage_call(target,"isChained") then
		if not damage_call(self,"isGoodChainTarget",target, card, use.from) then
			threat_level = threat_level + 2
		end
	end

	-- 火攻特殊判断
	if damage_call(card,"isKindOf","FireAttack") then
		if damage_call(target,"hasArmorEffect","vine") or damage_call(target,"getMark","@gale") > 0 then
			threat_level = threat_level + 2
		end
	end

	-- 检查目标是否有应对手段
	if damage_call(card,"isKindOf","Slash") then
		local jink_num = damage_call(self,"getExpectedJinkNum",use)
		local target_jink = damage_call(self,"estimateCardsNum","Jink",target)
		if target_jink < jink_num then
			threat_level = threat_level + 2
		end
	elseif damage_call(card,"isKindOf","AOE") then
		local response_card = damage_call(card,"isKindOf","SavageAssault") and "Slash" or "Jink"
		if damage_call(self,"estimateCardsNum",response_card,target) == 0 then
			threat_level = threat_level + 2
		end
		elseif damage_call(card,"isKindOf","Duel") then
			if damage_call(self,"estimateCardsNum","Slash",target) == 0 then
				threat_level = threat_level + 2
			end
		end

		-- 检查目标的受伤收益技能（降低威胁）
		if damage_call(self,"canDamage",target,use.from,card) then
			threat_level = threat_level - 2
		end

	-- 3. 判断控制类卡牌
	elseif damage_call(card,"isKindOf","Dismantlement") or damage_call(card,"isKindOf","Snatch") or damage_call(card,"isKindOf","Zhujinqiyuan") or damage_call(card,"isKindOf","xianzhencard") then
		if not damage_call(target,"isAllNude") then
			-- 检查目标是否有重要牌
			if damage_call(self,"estimateCardsNum","Peach",target) > 0 and damage_call(self,"isWeak",target) then
				threat_level = threat_level + 3
			end
			if damage_call(self,"estimateCardsNum","Analeptic",target) > 0 and damage_call(self,"isWeak",target) then
				threat_level = threat_level + 2
			end
			-- 关键装备
			if nullify_equipment(target, "getWeapon") and damage_call(nullify_equipment(target, "getWeapon"),"isKindOf","Crossbow")
				and damage_call(self,"estimateCardsNum","Slash",target) > 1 then
				threat_level = threat_level + 2
			end
			if nullify_equipment(target, "getArmor") then
				if damage_call(nullify_equipment(target, "getArmor"),"isKindOf","EightDiagram")
					or damage_call(nullify_equipment(target, "getArmor"),"isKindOf","Vine")
					or damage_call(nullify_equipment(target, "getArmor"),"isKindOf","RenwangShield") then
					threat_level = threat_level + 2
				else
					threat_level = threat_level + 1
				end
			end
			-- 判定区保护
			if damage_call(self,"willSkipPlayPhase",target) or damage_call(self,"willSkipDrawPhase",target) then
				threat_level = threat_level + 2
			end
			-- 基础威胁
			threat_level = threat_level + 1
		end

	-- 4. 判断延时锦囊
	elseif damage_call(card,"isKindOf","Indulgence") or damage_call(card,"isKindOf","QhstandardIndulgence") then
		if not damage_call(self,"willSkipPlayPhase",target) then
			-- 出牌阶段重要性判断
			if damage_call(self,"hasSkills","zhiheng|rende|nosrende|jizhi|nosjizhi|luoyi|nosluoyi", target) then
				threat_level = threat_level + 3
			end
			if damage_call(self,"estimateCardsNum","Peach",target) > 0 and damage_call(self,"isWeak",target) then
				threat_level = threat_level + 2
			end
			for _, skill in sgs.list(damage_call(target,"getVisibleSkillList")) do
				if string.find(damage_call(skill,"getDescription"), "出牌阶段") or string.find(damage_call(skill,"getDescription"), "出牌阶段限一次") then
					threat_level = threat_level + 2
				end
			end
			threat_level = threat_level + 2
		end

	elseif damage_call(card,"isKindOf","SupplyShortage") then
		if not damage_call(self,"willSkipDrawPhase",target) then
			-- 摸牌阶段重要性判断
			if damage_call(self,"hasSkills","luoshen|yongsi|yinling", target) then
				threat_level = threat_level + 3
			end
			if damage_call(target,"getHandcardNum") <= 1 then
				threat_level = threat_level + 2
			end
			for _, skill in sgs.list(damage_call(target,"getVisibleSkillList")) do
				if string.find(damage_call(skill,"getDescription"), "摸牌阶段") then
					threat_level = threat_level + 2
				end
			end
			threat_level = threat_level + 2
		end

	elseif damage_call(card,"isKindOf","Lightning") then
		-- 闪电判断
		local can_retrial = damage_call(self,"hasSkills","guicai|guidao|nosguicai|jilve|huanshi", target)
		if not can_retrial then
			local enemy_retrial = false
			for _, enemy in ipairs(self.enemies) do
				if damage_call(enemy,"hasSkills","guicai|guidao|nosguicai|jilve") then
					enemy_retrial = true
					break
				end
			end
			if enemy_retrial then
				threat_level = threat_level + 2
			else
				threat_level = threat_level + 1
			end
		end

	-- 5. 判断借刀杀人
	elseif damage_call(card,"isKindOf","Collateral") then
		local victim = nil
		for _, p in sgs.qlist(damage_call(self,"getCachedAlivePlayers")) do
			if damage_call(p,"hasFlag","CollateralVictim") then
				victim = p
				break
			end
		end
		if victim then
			if damage_call(self,"isFriend",victim) then
				threat_level = threat_level + 3
			elseif not damage_call(target,"canSlash",victim, nil, false) then
				threat_level = threat_level + 2
			elseif damage_call(self,"estimateCardsNum","Slash",target) == 0 then
				threat_level = threat_level + 2
			else
				threat_level = threat_level + 1
			end
		end
	elseif damage_call(card,"isKindOf","quanxiang") then
		threat_level = threat_level + 2
	elseif damage_call(card,"isKindOf","together_go_die") then
		threat_level = threat_level + 2
	elseif damage_call(card,"isKindOf","Luojingxiashi") then
		threat_level = threat_level + 2
	elseif damage_call(card,"isKindOf","BearingDownBorder") then
		threat_level = threat_level + 2
	elseif damage_call(card,"isKindOf","GodFlower") then
		if damage_call(self,"estimateCardsNum","Slash",target) == 0 then
			threat_level = threat_level + 2
		else
			threat_level = threat_level + 1
		end

	-- 6. 铁索连环
	elseif damage_call(card,"isKindOf","IronChain") then
		if not damage_call(target,"isChained") then
			-- 将被横置
			if not damage_call(self,"isWeak",target) then
				threat_level = threat_level + 1
			end
		end

	-- 7. 有益卡牌的判断
	elseif damage_call(card,"isKindOf","ExNihilo") or damage_call(card,"isKindOf","Peach")
		or damage_call(card,"isKindOf","Analeptic") or damage_call(card,"isKindOf","GodSalvation")
		or damage_call(card,"isKindOf","AmazingGrace") or damage_call(card,"isKindOf","Dongzhuxianji") or damage_call(card,"isKindOf","Lianjunshengyan") or damage_call(card,"isKindOf","GodNihilo") or damage_call(card,"isKindOf","rotenburo") or damage_call(card,"isKindOf","EXCard_YJJG") or damage_call(card,"isKindOf","Yuanjun") or damage_call(card,"isKindOf","Tunliang") or damage_call(card,"isKindOf","TacticalCombo") or damage_call(card,"isKindOf","Liangleichadao") or damage_call(card,"isKindOf","Xiongdiqixin") or damage_call(card,"isKindOf","Shengsiyugong") or damage_call(card,"isKindOf","Hongyundangtou") or damage_call(card,"isKindOf","Wutianwujie") or damage_call(card,"isKindOf","JingxiangGoldenage") or damage_call(card,"isKindOf","Zengbingjianzao") then
		-- 如果目标是敌人，这些有益卡牌应该被无效
		if target_is_enemy then
			threat_level = threat_level + 2
		else
			return false
		end
	end

    if threat_level < 0 then return false end

    -- 2. 計算沉沒成本與代價 (Cost Calculation)
	local cost_value = 0
	if need_losehp then
        cost_value = cost_value + (damage_call(self.player,"getHp") <= 2 and 4 or 2)
	end
	if need_discard then
        cost_value = cost_value + (discard_num * 1.5)
	end
	return threat_level > cost_value
end


-- SmartAI6297 getLord is a source helper, separate from Room's actual lord.
function SmartAIView:getSourceLord(player)
    local enabled=self.world.strategy_facts and self.world.strategy_facts.source_enable_hegemony
    if type(enabled)~="boolean" then ai_unsupported("source hegemony config is unknown","getSourceLord")end
    if enabled then return nil end
    local lord=self.room:getLord()
    if lord then return lord end
    local function role(p)
        local value=p:getRole()
        if value~=nil then return value end
        return self:useKnowledgeEstimate({value=self:getRoleEstimate(p),status="estimate",
            basis="getLord:viewer_role_inference",observer=p:objectName(),viewer=self.player:objectName()},"getSourceLord")
    end
    local own=role(player)
    if own==nil or own=="neutral" then ai_unsupported("source lord role cannot be resolved","getSourceLord")end
    if own~="renegade" then
        for _,p in ipairs(self.room:getOtherPlayers(player)) do if role(p)==role(player) then return p end end
    end
    return player
end
