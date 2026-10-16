-- Fixed b6025acc DragonLoke policies. Old SkillCard parse failures remain nil;
-- selected response wires preserve the donor terminal failure; no V2 repair.
local function known(value,key)
    if AIUnsupported and AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("DragonLoke fact is not projected",key) end
    return value
end
local function sort_in_place(self,values,key)
    local ordered=(self:sort(values,key))
    for i,value in ipairs(ordered) do values[i]=value end
end
local function missing_prototype(self,selector)
    -- Whether the source's skill-card class is registered (Card_Parse) is engine
    -- registry state, not projected.
    ai_unsupported("DragonLoke source Card_Parse absence is not projected",selector)
end
local function cache_target(self,player)
    self:setStrategyMemory("dragonloke.dl_liuli",player and (player:objectName()) or false)
end
local function cached_target(self)
    local name,present=self:getStrategyMemory("dragonloke.dl_liuli")
    if not present or name==false then return nil end
    if type(name)~="string" then ai_unsupported("invalid DragonLoke target memory","dl_liuli") end
    return known(self.room:findPlayerByObjectName(name),"dl_liuli cached target")
end
local function liuli_context(self)
    local row=(self:getDecisionContext()).dragonloke_liuli
    if type(row)~="table" or row.known~=true or type(row.use)~="table"
        or not AIValue.isList(row.source_marked_names) then
        ai_unsupported("DragonLoke current public use is not projected","dl_liuli")
    end
    return row
end
local function can_slash_cost(self,row,card,target,range_fix)
    local id=(card:getKnownEffectiveId())
    local rows=row.can_slash_by_cost
    local facts=type(rows)=="table" and rows[tostring(id)]
    local value=type(facts)=="table" and facts[(target:objectName())]
    if type(value)~="boolean" then ai_unsupported("DragonLoke exact cost range check is unknown","dl_liuli:"..id) end
    return value
end
local function response(self,card,target,request)
    local id,name=(card:getKnownEffectiveId()),(target:objectName())
    local wire="#dl_liuli:"..id..":->"..name
    missing_prototype(self,"#dl_liuli")
    local signal=AIUnsupported.new("DragonLoke donor terminal SkillCard prototype is unavailable","@@dl_liuli")
    signal.terminal_response_selection=true
    signal.donor_terminal_unavailable=true
    signal.source_wire=wire
    signal.selected_costs={id}
    signal.selected_targets={name}
    error(signal,0)
end

sgs.ai_fill_skill.dl_chaju = function(self, inclusive)
    local card_str = ("#dl_chaju:%d:")
    return missing_prototype(self,"#dl_chaju")
end

sgs.ai_skill_use_func["#dl_chaju"] = function(card, use, self)
    for _,friend in ipairs(self.friends_noself)do
        if (friend:getHandcardNum()) <= (self.player:getHandcardNum()) and (self:doDisCard(friend,"h",true)) and not (friend:isKongcheng()) then
            use.card = card
            if use.to then
                use.to:append(friend)
                return
            end
        end
    end
    for _,friend in ipairs(self.friends_noself)do
        if (friend:getHandcardNum()) <= (self.player:getHandcardNum()) and not (friend:isKongcheng()) then
            use.card = card
            if use.to then
                use.to:append(friend)
                return
            end
        end
    end
end
sgs.ai_use_priority["dl_chaju"] = sgs.ai_use_priority.RendeCard

sgs.ai_skill_choice.dl_chaju = function(self,choices,data)
    local target = data:toPlayer()
    local x = (self.player:getMaxHp()) - (self.player:getHandcardNum())
    if target and (self:isFriend(target)) then
        x = x + target:getMaxHp() - target:getHandcardNum()
    end
    if x > 0 then
        return "2"
    end
    return "1"
end

sgs.ai_fill_skill.dl_pindi=function(self,inclusive)
	return missing_prototype(self,"#dl_pindi")
end

sgs.ai_skill_use_func["#dl_pindi"]=function(card,use,self)
	use.card=card
end
sgs.ai_use_priority["dl_pindi"] = 6.8


sgs.ai_fill_skill.dl_yanxiao = function(self)
	local cards = (self.player:getCards("he"))
	cards=sgs.QList2Table(cards)
	local use_card
	cards=(self:sortByUseValue(cards,true))

	for _,card in sgs.list(cards)  do
		if (card:isRed()) then
			use_card = card
			break
		end
	end

	if use_card then
		local id=(use_card:getKnownEffectiveId()) -- source reads the selected ID before Parse
        return missing_prototype(self,"#dl_yanxiao")
	end
end
sgs.ai_skill_use_func["#dl_yanxiao"] = function(card,use,self)
    if (self.player:hasSkill("dl_liuli")) then
        sort_in_place(self,self.friends_noself,"defense")
        if (self:getOverflow())>0 then
            local lord = self.room:getLord()
            if lord and (self:isFriend(lord))  then
                local can_invoke = true
                for _,c in sgs.qlist((lord:getJudgingArea()))do
                    if string.find((c:objectName()),"kehexumou") then
                        can_invoke = false
                        break
                    end
                end
                if can_invoke then
                    use.card = card
                    cache_target(self,lord)
                    return
                end
            end

            for _,friend in sgs.list(self.friends_noself)do
                local can_invoke = true
                for _,c in sgs.qlist((friend:getJudgingArea()))do
                    if string.find((c:objectName()),"kehexumou") then
                        can_invoke = false
                        break
                    end
                end
                if can_invoke then
                    use.card = card
                    cache_target(self,friend)
                    return
                end
            end
            local can_invoke = true
            for _,c in sgs.qlist((self.player:getJudgingArea()))do
                if string.find((c:objectName()),"kehexumou") then
                    can_invoke = false
                    break
                end
            end
            if can_invoke then
                use.card = card
                cache_target(self,nil)
                return
            end
        end
    end
    use.card = card
end


ai_skill_use["@@dl_liuli"] = function(self,prompt,request)
    local method=known(self.request and self.request.handling_method,"dl_liuli method")
	local others = (self.room:getOtherPlayers(self.player))
    local context=liuli_context(self)
    local use=context.use
    local slash=use.card and CardView.new(use.card)
    if slash then slash._room=self.room end
	others = sgs.QList2Table(others)
	local source
	for _,player in ipairs(others)do
		if table.contains(context.source_marked_names,(player:objectName())) then
			source = player
			break
		end
	end
	sort_in_place(self,self.enemies,"defense")
    local doLiuli = function(who)
        if not (self:isFriend(who)) and (who:hasSkills("leiji|nosleiji|olleiji"))
            and ((self:hasSuit("spade",true,who)) or (who:getHandcardNum())>=3)
            and (getKnownCard(who,self.player,"Jink",true)>=1 or (self:hasEightDiagramEffect(who))) then
            return "."
        end

        local cards = (self.player:getCards("h"))
        cards = sgs.QList2Table(cards)
        cards=(self:sortByKeepValue(cards))
        for _,card in ipairs(cards)do
            if not (self.player:isCardLimited(card,method)) and (self.player:canSlash(who)) then
                if (self:isFriend(who)) and not (isCard("Peach",card,self.player) or isCard("Analeptic",card,self.player)) then
                    return response(self,card,who,request)
                else
                    return response(self,card,who,request)
                end
            end
        end

        local cards = (self.player:getCards("e"))
        cards=sgs.QList2Table(cards)
        cards=(self:sortByKeepValue(cards))
        for _,card in ipairs(cards)do
            local range_fix = 0
            if (card:isKindOf("Weapon")) then range_fix = range_fix+sgs.weapon_range[(card:getClassName())]-(self.player:getAttackRange(false)) end
            if (card:isKindOf("OffensiveHorse")) then range_fix = range_fix+1 end
            if not (self.player:isCardLimited(card,method)) and can_slash_cost(self,context,card,who,range_fix) then
                return response(self,card,who,request)
            end
        end
        return "."
    end
    if slash and (slash:isKindOf("Slash")) then

        for _,enemy in ipairs(self.enemies)do
            if not (source and (source:objectName())==(enemy:objectName())) then
                local ret = doLiuli(enemy)
                if ret~="." then return ret end
            end
        end

        for _,player in ipairs(others)do
            if (self:objectiveLevel(player))==0 and not (source and (source:objectName())==(player:objectName())) then
                local ret = doLiuli(player)
                if ret~="." then return ret end
            end
        end


        sort_in_place(self,self.friends_noself,"defense")
        self.friends_noself = sgs.reverse(self.friends_noself)


        for _,friend in ipairs(self.friends_noself)do
            if not (self:slashIsEffective(slash,friend)) or self:findLeijiTarget(friend,50,source) then
                if not (source and (source:objectName())==(friend:objectName())) then
                    local ret = doLiuli(friend)
                    if ret~="." then return ret end
                end
            end
        end

        for _,friend in ipairs(self.friends_noself)do
            if source~=friend and (self:needToLoseHp(friend,source,(self:getEvaluationCard("slash")))) then
                local ret = doLiuli(friend)
                if ret~="." then return ret end
            end
        end

        if ((self:isWeak()) or (self:ajustDamage(source,nil,1,slash))>1) and (source:hasWeapon("axe")) and ((source:getHandcardNum())+(source:getEquips()):length())>2
        and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
            for _,friend in ipairs(self.friends_noself)do
                if not (self:isWeak(friend)) then
                    if not (source and (source:objectName())==(friend:objectName())) then
                        local ret = doLiuli(friend)
                        if ret~="." then return ret end
                    end
                end
            end
        end

        if ((self:isWeak()) or (self:ajustDamage(source,nil,1,slash))>1) and not self:getCardId("Jink") then
            for _,friend in ipairs(self.friends_noself)do
                if not (self:isWeak(friend)) or ((self:hasEightDiagramEffect(friend)) and getCardsNum("Jink",friend)>=1) then
                    if not (source and (source:objectName())==(friend:objectName())) then
                        local ret = doLiuli(friend)
                        if ret~="." then return ret end
                    end
                end
            end
        end
    else
        local cached=cached_target(self)
        if cached then
            local ret = doLiuli(cached)
            if ret~="." then return ret end
        else
            return "."
        end
    end
	return "."
end
-- The two source aliases are already installed by standard-ai.lua through
-- immutable native alias identity gates; do not capture or overwrite them here.
