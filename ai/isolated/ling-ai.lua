-- Source: b6025acc ai/ling-ai.lua.
local known = AIValue.requireKnown

local function paid(self,skill,class,id,request)
    return self:bindSkillCard(skill, {id}, request, nil, class)
end
local function ganglie_flags(self)
    local row,present=self:getStrategyMemory("ling.ganglie_targets")
    if not present then row={} end
    if type(row)~="table" then ai_unsupported("invalid NeoGanglie flag memory","neoganglie") end
    -- Original flags are shared mutable AI state. Only this viewer's prior
    -- writes are available; never read another AI's private strategy flags.
    self:useKnowledgeEstimate({value=true,status="estimate",basis="ling.ganglie_targets.viewer_local_shadow"},"neoganglie")
    return row
end
local function set_ganglie_flag(self,player,enabled)
    local row=ganglie_flags(self)
    row[player:objectName()]=enabled or nil
    self:setStrategyMemory("ling.ganglie_targets",row)
end
local function current_damage(self)
    -- CurrentDamageStruct is set from DamageDone to DamageComplete and a trigger is
    -- logged when its dispatch ends, so while a Damaged skill answers the latest
    -- damage event is that damage's DamageDone or Damage stage.
    local event=self:getLastEvent("damage")
    local stage=event and event:getTriggerEvent()
    if stage~=sgs.DamageDone and stage~=sgs.Damage then ai_unsupported("CurrentDamageStruct is not projected","neoganglie") end
    local row=rawget(event,"_view")
    local result={}
    if row.from~="" then result.from=known(self.room:findPlayerByObjectName(known(row.from,"damage.from"),true),"damage source") end
    local card=row.details and row.details.card
    if type(card)=="table" and next(card)~=nil then result.card=CardView.new(card) end
    return result
end

-- Unique sp-ai.lua:2193 dependency body, private to this package.
local function invoke_zhiman(self,data)
	local target = data:toPlayer()
	if not target then return end
	if self:isFriend(target) then
		if self:needToLoseHp(target,self.player)
		and (target:getJudgingArea():isEmpty() or target:containsTrick("YanxiaoCard"))
		then return false end
		return self:doDisCard(target,"ej")
	else
		if self:isWeak(target) then return false end
		if self:doDisCard(target,"e",true) then return true end
		return self:needToLoseHp(target,self.player)
		or self:getDangerousCard(target) or target:getDefensiveHorse()
	end
end

ai_fill_skill.neoluoyi = function(self, options, request)
    local inclusive = options and options.inclusive

	if self:needBear() then return nil end
	local luoyicard
	if self:needToThrowArmor() then
		luoyicard = self.player:getArmor()
		return paid(self,"neoluoyi","LuoyiCard",luoyicard:getKnownEffectiveId(),request)
	end

	if not self:slashIsAvailable(self.player) then return nil end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local slashtarget = 0
	local dueltarget = 0
	local equipnum = 0
	local offhorse = self.player:getOffensiveHorse()
	local noHorseTargets = 0
	self:sort(self.enemies,"hp")
	for _,card in sgs.qlist(self.player:getCards("he"))do
		if card:isKindOf("EquipCard") and not (card:isKindOf("Weapon") and self.player:hasEquip(card)) then
			equipnum = equipnum+1
		end
	end
	for _,card in ipairs(cards)do
		if card:isKindOf("Slash") then
			for _,enemy in ipairs(self.enemies)do
				if self.player:canSlash(enemy,card) and self:slashIsEffective(card,enemy) and self:objectiveLevel(enemy)>3 and self:isGoodTarget(enemy,self.enemies,card) then
					if getCardsNum("Jink",enemy)<1 or (self.player:hasWeapon("Axe") and self.player:getCards("he"):length()>4) then
						slashtarget = slashtarget+1
						if offhorse and self.player:distanceTo(enemy, 1)<=self.player:getAttackRange() then
							noHorseTargets = noHorseTargets+1
						end
					end
				end
			end
		end
		if card:isKindOf("Duel") then
			for _,enemy in ipairs(self.enemies)do
				if self:getCardsNum("Slash")>=getCardsNum("Slash",enemy) and self:isGoodTarget(enemy,self.enemies,card)
				and self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy,self.player,2) and self:damageIsEffective(enemy) and enemy:getStrategyMark("@late")==0 then
					dueltarget = dueltarget+1
				end
			end
		end
	end
	if (slashtarget+dueltarget)>0 and equipnum>0 then
		self:speak("luoyi")
		if self:needToThrowArmor() then
			luoyicard = self.player:getArmor()
		end

		if not luoyicard then
			for _,card in sgs.qlist(self.player:getCards("he"))do
				if card:isKindOf("EquipCard") and not self.player:hasEquip(card) then
					luoyicard = card
					break
				end
			end
		end
		if not luoyicard and offhorse then
			if noHorseTargets==0 then
				for _,card in sgs.qlist(self.player:getCards("he"))do
					if card:isKindOf("EquipCard") and not card:isKindOf("OffensiveHorse") then
						luoyicard = card
						break
					end
				end
				if not luoyicard and dueltarget==0 then return nil end
			end
		end
		if not luoyicard then
			for _,card in sgs.qlist(self.player:getCards("he"))do
				if card:isKindOf("EquipCard") and not (card:isKindOf("Weapon") and self.player:hasEquip(card)) then
					luoyicard = card
					break
				end
			end
		end
		if not luoyicard then return nil end
		return paid(self,"neoluoyi","LuoyiCard",luoyicard:getKnownEffectiveId(),request)
	end
end

ai_card_use.LuoyiCard=function(self, card, use, request)
	use.card = card
end

sgs.ai_use_priority.LuoyiCard = 9.2

ai_fill_skill.neofanjian = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:isKongcheng() then return nil end
	return self:legacySkillSeed("neofanjian", "NeoFanjianCard", request)
end

ai_card_use.NeoFanjianCard = function(self, card, use, request)
	self:sort(self.enemies,"defense")
	local target
	for _,enemy in ipairs(self.enemies)do
		if self:canAttack(enemy) and not self:hasSkills("qingnang|tianxiang",enemy) then
			target = enemy
			local wuguotai = self.room:findPlayerBySkillName("buyi")
			local care = (target:getHp()<=1) and (self:isFriend(target,wuguotai))
			local ucard = nil
			local handcards = self.player:getCards("h")
			handcards = sgs.QList2Table(handcards)
			self:sortByKeepValue(handcards)
			for _,cd in ipairs(handcards)do
				local flag = not (cd:isKindOf("Peach") or cd:isKindOf("Analeptic"))
				local suit = cd:getSuit()
				if flag and care then
					flag = cd:isKindOf("BasicCard")
				end
				if flag and target:hasSkill("longhun") then
					flag = (suit~=sgs.Card_Heart)
				end
				if flag and target:hasSkill("jiuchi") then
					flag = (suit~=sgs.Card_Spade)
				end
				if flag and target:hasSkill("jijiu") then
					flag = (cd:isBlack())
				end
				if flag then
					ucard = cd
					break
				end
			end
			if ucard
			and self:damageIsEffective(enemy,card)
			then
				local keep_value = self:getKeepValue(ucard)
				if ucard:getSuit()==sgs.Card_Diamond then keep_value = keep_value+0.5 end
				if keep_value<6 then
					use.card = paid(self,"neofanjian","NeoFanjianCard",ucard:getKnownEffectiveId(),request)
					use.to:append(target)
					return
				end
			end
		end
	end
end

-- NeoFanjianCard intention alias is centrally audited by event-intention.
sgs.dynamic_value.damage_card.NeoFanjianCard = true

function sgs.ai_skill_suit.neofanjian(self)
	local map = {0,0,1,2,2,3,3,3}
	local suit = map[math.random(1,8)]
	if self.player:hasSkill("hongyan") and suit==sgs.Card_Spade then return sgs.Card_Heart else return suit end
end

ai_skill_invoke.yishi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (invoke_zhiman(self,data)) or false
end

ai_skill_invoke.zhulou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local weaponnum = 0
	for _,card in sgs.qlist(self.player:getCards("h"))do
		if card:isKindOf("Weapon") then
			weaponnum = weaponnum+1
		end
	end

	if weaponnum>0 then return (true) or false end

	if self.player:getHandcardNum()<3 and self.player:getHp()>2 then
		return (true) or false
	end

	if self.player:getHp()<3 and self.player:getWeapon() then
		return (true) or false
	end

	return (false) or false
end

sgs.ai_skill_cardask["@zhulou-discard"] =  function(self,data)
	if self.player:getWeapon() then
		return "$"..self.player:getWeapon():getEffectiveId()
	end

	for _,card in sgs.qlist(self.player:getCards("he"))do
		if card:isKindOf("Weapon") then
			return "$"..card:getKnownEffectiveId()
		end
	end
	return "."
end

ai_audited_aliases.register{id="ai_cardneed.zhulou",registry="ai_cardneed",path={"zhulou"},canonical_registry="ai_cardneed",canonical_path={"weapon"},self_index=3,defer_canonical=true}

sgs.zhulou_keep_value = sgs.qiangxi_keep_value

function ai_skill_invoke.neojushou(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if not self.player:faceUp() then return (true) or false end
	for _,friend in ipairs(self.friends)do
		if self:hasSkills("fangzhu|jilve",friend) then return (true) or false end
	end
	return (self:isWeak()) or false
end

ai_skill_invoke.neoganglie = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	if not damage.from then
		local zhangjiao = self.room:findPlayerBySkillName("guidao")
		return (zhangjiao and self:isFriend(zhangjiao)) or false
	end
	local who = damage.from
	if self:isFriend(who) and self:needToLoseHp(who,self.player,damage.card,true) then
		set_ganglie_flag(self,who,true)
		return (true) or false
	end
	if self:needToLoseHp(who,self.player) and self:isEnemy(who) and who:getHandcardNum()<2 then
		return (false) or false
	end

	return (not self:isFriend(who)) or false
end

sgs.ai_choicemade_filter.skillInvoke.neoganglie = function(self,player,promptlist)
	local damage = current_damage(self)
	if damage.from then
		local target = damage.from
		local intention = 10
		if promptlist[3]=="yes" then
			if self:needToLoseHp(target,player,damage.card,true) then
				intention = 0
			end
			sgs.updateIntention(player,target,intention)
		elseif self:canAttack(target) then
			sgs.updateIntention(player,target,-10)
		end
	end
end

sgs.ai_need_damaged.neoganglie = function (self,attacker,player)
	if not player:hasSkill("neoganglie") then return false end
	if not attacker then return end
	if self:isEnemy(attacker,player) and attacker:getHp()<=2 and not attacker:hasSkill("buqu") then
		return not self:isWeak(player)
	end
end

ai_skill_choice.neoganglie = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local target
	for _,player in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if ganglie_flags(self)[player:objectName()]==true then
			target = player
			set_ganglie_flag(self,target,false)
		end
	end
	if self:needToLoseHp(target,self.player) and self:isFriend(target) then return ai_choice_result(("damage"), options) end

	if self:needToLoseHp(target,self.player) and target:getHandcardNum()>1 then
		return ai_choice_result(("throw"), options)
	end
	return ai_choice_result(("damage"), options)
end

sgs.ai_skill_discard.neoganglie = function(self,discard_num,min_num,optional,include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	local index = 0
	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)

	for i = #cards,1,-1 do
		local card = cards[i]
		if not self.player:isJilei(card) then
			table.insert(to_discard,card:getKnownEffectiveId())
			table.remove(cards,i)
			index = index+1
			if index==2 then break end
		end
	end
	return to_discard
end

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_target_damage["good_survival.ganglie_group"]
    local policy = function(self, to, context)
        local value, good_query = context.value, context.query
        local card, damageNum, apn, value_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4]
        if good_query(to, "hasSkills", "neoganglie|xuehen|xueji")
        		and good_query(self, "isWeak", self.friends) then return nil, true end
        return value
    end
    sgs.ai_target_damage["good_survival.ganglie_group"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "good_survival" and context.rule == "ganglie_group" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "good_survival.ganglie_group", {
        {phase="good_survival", order=4, rule="ganglie_group"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["chain_retaliation.ganglie"]
    local policy = function(self, to, context)
        local strategy_call = context.query
        local source, strategy_known = context.extra[1], context.extra[2]
        local result, killlord = context.value.result, context.value.killlord
        if strategy_call(self, "isEnemy", to, source)
                        and strategy_call(to, "hasSkills", "ganglie|neoganglie")
                        and strategy_call(source, "getHandcardNum") + strategy_call(source, "getHp")
                            + strategy_known(getKnownCard(source, self.player, "Peach", true, "he"), "Peach estimate") < 3 then
                        result = result + 3
                    end
        return {result=result, killlord=killlord}
    end
    sgs.ai_target_damage["chain_retaliation.ganglie"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "chain_retaliation" and context.rule == "ganglie" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "chain_retaliation.ganglie", {
        {phase="chain_retaliation", order=1, rule="ganglie"},
    })
end)()
end
