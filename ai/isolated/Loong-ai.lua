-- Source: b6025acc ai/Loong-ai.lua.
local known = AIValue.requireKnown
local function hydrate_context(self,value,kind)
 if value==nil then return nil end
 if kind=='Player' then
  if AIValue.isPlayer(value)then return value end
  return known(self.room:findPlayerByObjectName(value,true),'context.player:'..tostring(value))
 end
 if kind=='Card'then
  if AIValue.isCard(value)or AIValue.isConversion(value)then return value end
  return CardView.new(value,self.room)
 end
 if kind=='Bool'or kind=='String'or kind=='Int'then return value end
 if kind=='IntList'then return AIList.new(value)end
 local row={};for k,v in pairs(value)do row[k]=v end
 for _,k in ipairs{'from','who','m_who'}do if value[k]then row[k]=hydrate_context(self,value[k],'Player')end end
 for _,k in ipairs{'card','whocard','m_card','m_toCard'}do if value[k]then row[k]=hydrate_context(self,value[k],'Card')end end
 if kind=='CardUse'then row.to=AIList.new({});for _,v in ipairs(value.to or{})do row.to:append(hydrate_context(self,v,'Player'))end
 elseif value.to then row.to=hydrate_context(self,value.to,'Player')end
 if kind=='Dying'and value.damage then row.damage=hydrate_context(self,value.damage,'Damage')end
 return row
end
local nullable={useCardByClassName=true,applyLoongFeilongRole=true,toPlayer=true,getLord=true,getMaxCard=true,getArmor=true,getWeapon=true,getEquip=true,getTreasure=true,findPlayerBySkillName=true,findLeijiTarget=true,updatePlayers=true,setStrategyMemory=true,setStrategyCardFlag=true,getStrategyMemory=true}

local function own_ai(p)local a=p._room and p._room._ai;if not a or p~=a.player then ai_unsupported('Loong view-as requires owner legal materials','Loong.view_as')end;return a end
local function face(self,id)return self:getKnownCardById(id)end
local function complete_hand(self,p)
 local cards=p:getHandcards();if #cards~=p:getHandcardNum()then ai_unsupported('Taoxi source inspects unavailable foreign hand identities','lxtx_taoxi.foreign_hand')end;return cards
end
local function spec(name,skill,costs,material,two)
 local suit,number=sgs.Card_NoSuit,0
 if material then suit=material:getSuit();number=material:getNumber()end
 if two then suit=(two=='red'and sgs.Card_NoSuitRed or sgs.Card_NoSuitBlack);number=0 end
 return{name=name,skill=skill,suit=suit,number=number,subcards=costs}
end
local class={slash='Slash',jink='Jink',peach='Peach',analeptic='Analeptic'}
local function turn(self,skill,name,costs,material,two,printed,request)
 -- Zhangwu's source uses dummyCard(NoSuit,0), not a face-specific Parse.
 local proposal=spec(name,printed or skill,costs,material,two)
 if skill=='lxtx_zhangwu'then proposal.suit,proposal.number=sgs.Card_NoSuit,0 end
 return self:evaluateTurnConversion(skill, known(class[name],name), proposal, request)
end
local function evaluation(self,name)return self:getEvaluationCard(name or 'slash')end
local function named_eval(self,skill,name,costs)return self:evaluateSkillCard(skill, name, costs)end
local function seed(self,key,costs)
 if costs then return self:evaluateTurnSkillCard(key, '#'..key, costs, self.request)end
 return self:legacySkillSeed(key, '#'..key, self.request)
end
local function paid(self,key,costs)
 return self:bindSkillCard(key, costs, self.request, nil, '#'..key)
end
local function response(self,key,costs,targets)
 local c=paid(self,key,costs);return{kind='use_card',card_spec=c:toCardSpec(),targets=targets or{}}
end
local function source_use(self,key)
 local row=self:getDecisionContext().Loong
 local use=row and row[key]
 if type(use)~='table'then ai_unsupported('Loong owner source CardUse is not projected',key)end
 return hydrate_context(self,use,'CardUse')
end
local function remember(self,key,v)return self:setStrategyMemory('Loong.'..key, v)end
local function recall(self,key)local v,p=self:getStrategyMemory('Loong.'..key);if p then return v end end
local function public_flag(self,p,key)
 -- Player flags are projected for the viewer only; a foreign read stays unknown.
 return p:hasFlag(key)
end



ai_skill_invoke["lxtx_taoxi"] = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    if to and self:isEnemy(to) then
        local dismantlement_count = 0
        if to:hasSkill("noswuyan") or to:getStrategyMark("@late")>0 then
            if self.player:hasSkill("yinling") then
                local black = self:getSuitNum("spade|club", true)
                local num = 4-self.player:getPile("brocade"):length()
                dismantlement_count = dismantlement_count+math.max(0,math.min(black,num))
            end
        else
            dismantlement_count = dismantlement_count+self:getCardsNum("Dismantlement")
            if self.player:distanceTo(to)==1 or self:hasSkills("qicai|nosqicai") then
                dismantlement_count = dismantlement_count+self:getCardsNum("Snatch")
            end
        end

        if dismantlement_count>=to:getHandcardNum()then return (true) or false end
        local handcards = complete_hand(self,to)
        if dismantlement_count>=handcards:length() then
            return (true) or false
        end

        local can_use,cant_use = {},{}
        for _,c in sgs.qlist(handcards)do
            if self.player:isCardLimited(c, sgs.Card_MethodUse, false) then
                table.insert(cant_use,c)
            else
                table.insert(can_use,c)
            end
        end

        if #can_use==0 and dismantlement_count==0 then
            return (false) or false
        end

        if self:needToLoseHp() then
            return (true) or false
        end

        local knowns,unknowns = {},{}
        local flag = string.format("visible_%s_%s",self.player:objectName(),to:objectName())
        for _,c in sgs.qlist(handcards)do
            if self.player:canSeeHandcard(to) and c:hasFlag("visible") or c:hasFlag(flag) then
                table.insert(knowns,c)
            else
                table.insert(unknowns,c)
            end
        end

        if #knowns>0 then --Now I begin to lose control...Need more help.
            local can_use_record = {}
            for _,c in ipairs(can_use)do
                can_use_record[c:getKnownId()] = true
            end

            local can_use_count = 0
            local to_can_use_count = 0
            local function can_use_check(user,to_use)
                if to_use:isKindOf("EquipCard") then
                    return not user:isProhibited(user, to_use)
                elseif to_use:isKindOf("BasicCard") then
                    if to_use:isKindOf("Jink") then
                        return false
                    elseif to_use:isKindOf("Peach") then
                        if user:hasFlag("Global_PreventPeach") then
                            return false
                        elseif user:getLostHp()==0 then
                            return false
                        elseif user:isProhibited(user, to_use) then
                            return false
                        end
                        return true
                    elseif to_use:isKindOf("Slash") then
                        if to_use:isAvailable(user) then
                            local others = self.room:getOtherPlayers(user)
                            for _,p in sgs.qlist(others)do
                                if user:canSlash(p, to_use) then
                                    return true
                                end
                            end
                        end
                        return false
                    elseif to_use:isKindOf("Analeptic") then
                        if to_use:isAvailable(user) then
                            return not user:isProhibited(user, to_use)
                        end
                    end
                elseif to_use:isKindOf("TrickCard") then
                    if to_use:isKindOf("Nullification") then
                        return false
                    elseif to_use:isKindOf("DelayedTrick") then
                        if user:containsTrick(to_use:objectName()) then
                            return false
                        elseif user:isProhibited(user, to_use) then
                            return false
                        end
                        return true
                    elseif to_use:isKindOf("Collateral") then
                        local others = self.room:getOtherPlayers(user)
                        local selected = sgs.PlayerList()
                        for _,p in sgs.qlist(others)do
                            if to_use:targetFilter(selected, p, user) then
                                local victims = self.room:getOtherPlayers(p)
                                for _,p2 in sgs.qlist(victims)do
                                    if p:canSlash(p2) then
                                        return true
                                    end
                                end
                            end
                        end
                    elseif to_use:isKindOf("ExNihilo") then
                        return not user:isProhibited(user, to_use)
                    else
                        local others = self.room:getOtherPlayers(user)
                        for _,p in sgs.qlist(others)do
                            if not user:isProhibited(p, to_use) then
                                return true
                            end
                        end
                        if to_use:isKindOf("GlobalEffect") and not user:isProhibited(user, to_use) then
                            return true
                        end
                    end
                end
                return false
            end
            for _,c in ipairs(knowns)do
                if can_use_record[c:getKnownId()] and can_use_check(self.player,c) then
                    can_use_count = can_use_count+1
                end
            end

            local to_friends = self:getFriends(to)
            local to_has_weak_friend = false
            local to_is_weak = self:isWeak(to)
            for _,friend in ipairs(to_friends)do
                if self:isEnemy(friend) and self:isWeak(friend) then
                    to_has_weak_friend = true
                    break
                end
            end

            local my_trick,my_slash,my_aa,my_duel,my_sa = nil,nil,nil,nil,nil
            local use = source_use(self,"taoxi_carduse")
            local ucard = use.card
            if ucard:isKindOf("TrickCard") then
                my_trick = 1
                if ucard:isKindOf("Duel") then
                    my_duel = 1
                elseif ucard:isKindOf("ArcheryAttack") then
                    my_aa = 1
                elseif ucard:isKindOf("SavageAssault") then
                    my_sa = 1
                end
            elseif ucard:isKindOf("Slash") then
                my_slash = 1
            end
            
            for _,c in ipairs(knowns)do
                if isCard("Nullification",c,to) then
                    my_trick = my_trick or ( self:getCardsNum("TrickCard")-self:getCardsNum("DelayedTrick") )
                    if my_trick>0 then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                end
                if isCard("Jink",c,to) then
                    my_slash = my_slash or self:getCardsNum("Slash")
                    if my_slash>0 then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                    my_aa = my_aa or self:getCardsNum("ArcheryAttack")
                    if my_aa>0 then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                end
                if isCard("Peach",c,to) then
                    if to_has_weak_friend then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                end
                if isCard("Analeptic",c,to) then
                    if to:getHp()<=1 and to_is_weak then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                end
                if isCard("Slash",c,to) then
                    my_duel = my_duel or self:getCardsNum("Duel")
                    if my_duel>0 then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                    my_sa = my_sa or self:getCardsNum("SavageAssault")
                    if my_sa>0 then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                end
            end

            if can_use_count>=to_can_use_count+#unknowns then
                return (true) or false
            elseif can_use_count>0 and ( can_use_count+0.01 )/( to_can_use_count+0.01 )>=0.5 then
                return (true) or false
            end
        end

        if self:getCardsNum("Peach")>0 then
            return (true) or false
        end
        if math.random() < 0.6 then return (true) or false end
    end
    return (false) or false
end
ai_fill_skill.lxtx_taoxi = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyMark("lxtx_taoxi-SelfPlayClear") > 0
	then
        local c = self.player:getStrategyMark("taoxiName-Clear")
        if c and c>=0
		then
            local list = named_eval(self,"lxtx_taoxi",face(self,c):objectName(),{})
            
			if list:isAvailable(self.player)
			then return list end
        end
    end
end

sgs.ai_card_priority.lxtx_taoxi = function(self,card)
	if table.contains(card:getSkillNames(), "lxtx_taoxi")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_skill_askforag.lxtx_taoxi = function(self,card_ids)
	for i,card_id in ipairs(card_ids)do
		local c = self:getChoiceCard(card_id)
        local dummy_use = self:aiUseCard(c, dummy())
        if dummy_use.card then
            return card_id
        end
	end

	return card_ids[1]
end

-- audited alias ai_cardneed.lxtx_jiangchi
ai_skill_invoke.lxtx_jiangchi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

sgs.ai_skill_discard.lxtx_jiangchi = function(self,discard_num,min_num,optional,include_equip)
    if self:getCardsNum("Slash")>0	then
        local cards = sgs.QList2Table(self.player:getHandcards())
        local to_discard = {}
        local compare_func = function(a,b)
            return self:getKeepValue(a)<self:getKeepValue(b)
        end
        table.sort(cards,compare_func)
        for _,card in sgs.list(cards)do
            if #to_discard>=1 then break end
            table.insert(to_discard,card:getKnownId())
        end

        return to_discard
    end
	return "."
end


ai_fill_skill.lxtx_zhangwu = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile("h")
	cards = self:sortByUseValueInPlace(cards, true)
	local use_cards = {}
	local useAll = false
	self:sortInPlace(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<2 and not enemy:hasArmorEffect("EightDiagram")
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end

	for _,card in ipairs(cards)do
		if not card:isKindOf("Slash") and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or (evaluation(self)):getTargetResidue()>0)
		then table.insert(use_cards,card) end
	end

    if self.player:getStrategyMark("lxtx_jiangchi_recast-Clear") > 0 then
        for _,card in ipairs(use_cards)do
            local slash=turn(self,"lxtx_zhangwu","slash",{card:getKnownEffectiveId()},card,nil,"lxtx_zhangwuu",request)
            if slash:isAvailable(self.player)
            then return slash end
        end
    end
    if self.player:getStrategyMark("lxtx_jiangchi_draw-Clear") > 0 and useAll then
        local costs={}
        for _,card in ipairs(cards)do
            if (not isCard("Peach",card,self.player) and not isCard("Analeptic",card,self.player) and not isCard("EquipCard",card,self.player)) then
                costs[#costs+1]=card:getKnownEffectiveId()
            end
        end
        local slash
        if #costs>0 then slash=turn(self,"lxtx_zhangwu","slash",costs,nil,nil,"lxtx_zhangwuu",request)end
        if #costs>0 and slash:isAvailable(self.player)
            then return slash end
    end
    local costs={}
    for _,card in ipairs(cards)do
        if  useAll then
            costs[#costs+1]=card:getKnownEffectiveId()
        end
    end
    local slash
        if #costs>0 then slash=turn(self,"lxtx_zhangwu","slash",costs,nil,nil,"lxtx_zhangwuu",request)end
        if #costs>0 and slash:isAvailable(self.player)
        then return slash end
end


ai_fill_skill.lxtx_zhengpi = function(self, options, request)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValueInPlace(cards)
  	for _,c in sgs.list(cards)do
		if c:isKindOf("BasicCard")
		then
			return seed(self,"lxtx_zhengpi",{c:getKnownEffectiveId()})
		end
	end
end

ai_card_use["#lxtx_zhengpi"] = function(self, card, use, request)
	self:sortInPlace(self.friends_noself, "card", true)
	for _,p in sgs.list(self.friends_noself)do
		if p:getCardCount()>1 and self:doDisCard(p, "h")
		then
			use.card = card
			use.to:append(p)
			return
		end
	end
	self:sortInPlace(self.enemies, "card", true)
	for _,ep in sgs.list(self.enemies)do
		if ep:getCardCount()>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if ep:getCardCount()>0
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value["lxtx_zhengpi"] = 9.4
sgs.ai_use_priority["lxtx_zhengpi"] = 3.8
sgs.ai_card_intention["lxtx_zhengpi"] = 50

ai_skill_invoke.lxtx_fengying = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    if self.player:getMaxHp() - self.player:getHandcardNum() > 0 then
        if #self.enemies > 0 and known(self.world.turn_count,"turn_count") > 0 then
            return (true) or false
        end
    end
    if self:isWeak() and self:getAllPeachNum() == 0 and math.random() < 0.6 then return (true) or false end
    return (false) or false
end

ai_skill_invoke.lxtx_jizhao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local dying = data:toDying()
	local peaches = 1-dying.who:getHp()

	return (self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<peaches) or false
end

sgs.ai_canNiepan_skill.lxtx_jizhao = function(player)
	return player:getStrategyMark("lxtx_jizhao") == 0
end


ai_fill_skill.lxtx_rende = function(self, options, request)
    local inclusive = options and options.inclusive

	return seed(self,"lxtx_rende")
end

ai_card_use["#lxtx_rende"] = function(self, card, use, request)
    self:sortInPlace(self.friends_noself, "defense")
    local need = {}
    for _,p in ipairs(self.friends_noself) do
        table.insert(need, p)
    end

    local give = 0 
    if #need == 0 then return end
    if #need == 1 then give = math.max(2, self.player:getHandcardNum() - self.player:getMaxCards()) end
    if #need > 1 then give = 2 end

    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValueInPlace(cards)
    local usecards = {}
    for _,cc in ipairs(cards) do
		if self:willUse(self.player, cc) then continue end
        table.insert(usecards, cc:getKnownEffectiveId())
        give = give - 1
        if give <= 0 then break end
    end
    if give > 0 then return end
    local card_str = string.format("#lxtx_rende:%s:->%s", table.concat(usecards,"+"), need[1]:objectName())
    use.card = paid(self,"lxtx_rende",usecards)
    if use.to then use.to:append(need[1]) end
end

ai_skill_choice["lxtx_rende"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
    if #items == 1 then return ai_choice_result((items[1]), options) end
    if self.player:getLostHp() > 1 then return ai_choice_result(("peach"), options) end
    table.removeOne(items, "cancel")
    for _,pattern in ipairs(items) do
        local card = named_eval(self,"lxtx_rende_choice",pattern,{})
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        self:useCardByClassName(card, usec)
        if usec.to and usec.to:length() > 0 then
            return ai_choice_result((pattern), options)
        end
    end
    return ai_choice_result(("cancel"), options)
end

ai_skill_use["@@lxtx_rende"] = function(self, prompt, request)
    local pattern = self.player:getPropertyValue("lxtx_rende") or ""

    if pattern == "peach" or pattern == "analeptic" then
        return response(self,"lxtx_rende_basic",{},{self.player:objectName()})
    end

	local card = named_eval(self,"lxtx_rende_choice",pattern,{})
	
    local card = named_eval(self,"lxtx_rende_choice",pattern,{})
    local usec = {isDummy=true,to=sgs.SPlayerList()}
    self:useCardByClassName(card, usec)
    if usec.to and usec.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(usec.to) do
            table.insert(tos, to:objectName())
        end
        local card_str = string.format("#lxtx_rende_basic:.:->%s", table.concat(tos, "+"))
        return response(self,"lxtx_rende_basic",{},tos)
    end
    return "."
end

sgs.ai_use_priority.lxtx_rende = 8.8
sgs.ai_use_value.lxtx_rende = 10.8

sgs.weapon_range.LxtxFeiLongDuoFeng = 2
sgs.ai_use_priority.LxtxFeiLongDuoFeng = 5.400
function sgs.ai_weapon_value.LxtxFeiLongDuoFeng(self, enemy, player)
	if enemy and enemy:getHp() <= 1 and getCardsNum("Jink", enemy, self.player) == 0 then
		return 4.1
	end
end
function sgs.ai_slash_weaponfilter.LxtxFeiLongDuoFeng(self, to, player)
	if player:distanceTo(to) > math.max(sgs.weapon_range.LxtxFeiLongDuoFeng, player:getAttackRange()) then return end
	return getCardsNum("Peach", to, self.player) + getCardsNum("Jink", to, self.player) < 1
		and getCardsNum("Jink", to, self.player) == 0
end
ai_skill_invoke._lxtx_feilongduofeng_re = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if not self.player:isLord() and self.player:getKnownRole() == "renegade" then return (false) or false end
	return (true) or false
end
ai_skill_invoke._lxtx_feilongduofeng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	for _, to in sgs.qlist(use.to) do
		local eff = self:doDisCard(to)
		return (eff and self:isEnemy(to)) or false
	end
	return false
end

local function apply_feilong_role(self,actor,target)
 local actor_name=actor:objectName();local target_name=target:objectName()
 -- The skillInvoke choice reaches only its actor, so the role is the viewer's own;
 -- the caller has already seen the target's flag.
 if actor_name~=self.player:objectName()then
  ai_unsupported('Feilong role effect lacks actor-private choice witness','Loong.feilong.role')
 end
 local role=self.player:getKnownRole()
 local roles={lord=true,loyalist=true,rebel=true,renegade=true}
 if not roles[role]then ai_unsupported('Feilong target/role is outside witnessed source domain','Loong.feilong.role')end
 -- Foreign source roles are not queried or silently estimated here.
 self:emitStrategyEffect{kind='loong_feilong_role',actor=actor_name,player=target_name,role=role}
end

sgs.ai_choicemade_filter.skillInvoke._lxtx_feilongduofeng_re=function(self,player,promptlist)
 if promptlist[#promptlist]=="yes"then
  for _,sb in ipairs(self.room:getOtherPlayers(player))do
   if public_flag(self,sb,"LxtxFeiLongDuoFeng")then
    apply_feilong_role(self,player,sb)
    self:updatePlayers()
   end
  end
 end
end

sgs.ai_view_as.lxtx_shouyue_wusheng = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return spec("slash","lxtx_shouyue_wusheng",{card_id},card)
	end
end

ai_fill_skill.lxtx_shouyue_wusheng = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile("he")
	cards = self:sortByUseValueInPlace(cards, true)
	local red_card = {}
	local useAll = false
	self:sortInPlace(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<2 and not enemy:hasArmorEffect("EightDiagram")
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end

	for _,card in ipairs(cards)do
		if not card:isKindOf("Slash")
		and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or (evaluation(self)):getTargetResidue()>0)
		then table.insert(red_card,card) end
	end


	for _,card in ipairs(red_card)do
		local slash=turn(self,"lxtx_shouyue_wusheng","slash",{card:getKnownEffectiveId()},card,nil,nil,request)
		if slash:isAvailable(self.player)
		then return slash end
	end
end

-- audited alias ai_cardneed.lxtx_shouyue_wusheng
sgs.double_slash_skill = sgs.double_slash_skill .. "|lxtx_shouyue_paoxiao"
-- audited alias ai_cardneed.lxtx_shouyue_paoxiao
sgs.ai_use_revises.lxtx_shouyue_paoxiao = function(self,card,use)
	if card:isKindOf("Slash") then
		self:setStrategyCardFlag(card, "Qinggang", true)
	end
end


ai_fill_skill.lxtx_shouyue_longdan = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile()
	local jink_card
	self:sortByUseValueInPlace(cards, true)
	for _,card in ipairs(cards)  do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end
	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getKnownEffectiveId()
	local card_str = ("slash:lxtx_shouyue_longdan[%s:%s]=%d"):format(suit,number,card_id)
	local slash=turn(self,"lxtx_shouyue_longdan","slash",{card_id},jink_card,nil,nil,request)
	assert(slash)
	return slash

end

sgs.ai_view_as.lxtx_shouyue_longdan = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place==sgs.Player_PlaceHand then
		if card:isKindOf("Jink") then
			return spec("slash","lxtx_shouyue_longdan",{card_id},card)
		elseif card:isKindOf("Slash") then
			return spec("jink","lxtx_shouyue_longdan",{card_id},card)
		end
	end
end


-- audited alias ai_cardneed.lxtx_shouyue_longdan
sgs.ai_card_priority.lxtx_shouyue_longdan = function(self,card)
	if table.contains(card:getSkillNames(), "lxtx_shouyue_longdan")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end
sgs.hit_skill = sgs.hit_skill .. "|lxtx_shouyue_liegong"
-- audited alias ai_cardneed.lxtx_shouyue_liegong
-- audited alias ai_skill_invoke.lxtx_shouyue_liegong
sgs.ai_canliegong_skill.lxtx_shouyue_liegong = function(self, from, to)
	return from:getPhase() == sgs.Player_Play and (to:getHandcardNum() >= from:getHp() or to:getHandcardNum() <= from:getAttackRange())
end


-- audited alias ai_cardneed.lxtx_shouyue_tieqi
ai_skill_invoke.lxtx_shouyue_tieqi = ai_skill_invoke.nostieji
sgs.hit_skill = sgs.hit_skill .. "|lxtx_shouyue_tieqi"





sgs.ai_view_as.lxtx_wupao = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return spec("slash","lxtx_wupao",{card_id},card)
	end
end

ai_fill_skill.lxtx_wupao = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile("he")
	cards = self:sortByUseValueInPlace(cards, true)
	local red_card = {}
	local useAll = false
	self:sortInPlace(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<2 and not enemy:hasArmorEffect("EightDiagram")
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end

	for _,card in ipairs(cards)do
		if card:isRed() and not card:isKindOf("Slash")
		and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or (evaluation(self)):getTargetResidue()>0)
		then table.insert(red_card,card) end
	end

	for _,card in ipairs(red_card)do
		local slash=turn(self,"lxtx_wupao","slash",{card:getKnownEffectiveId()},card,nil,nil,request)
		if slash:isAvailable(self.player)
		then return slash end
	end
end

function sgs.ai_cardneed.lxtx_wupao(to,card)
	return to:getHandcardNum()<3 and card:isRed()
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|lxtx_wupao"

ai_fill_skill.lxtx_yizan = function(self, options, request)
    local inclusive = options and options.inclusive

	local usable_cards = {}
    local heart, diamond, club, spade = {},{},{},{}
	self:sortByUseValueInPlace(usable_cards, true)
	
	local equips = sgs.QList2Table(self.player:getCards("e"))
	for _, e in ipairs(equips) do
		if e:isKindOf("DefensiveHorse") or e:isKindOf("OffensiveHorse") then
			table.insert(usable_cards, e)
		end
	end
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(usable_cards, face(self,id))
	end
	self:sortByUseValueInPlace(usable_cards, true)
	local two_diamond_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Diamond and #two_diamond_cards < 2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and not c:isKindOf("Slash") then
			table.insert(two_diamond_cards, c:getKnownEffectiveId())
		end
	end
	if #two_diamond_cards == 2 and self:slashIsAvailable() and (self.player:getStrategyMark("lxtx_longyuan") == 0) and self:getOverflow() > 0 then
		return turn(self,"lxtx_yizan","slash",two_diamond_cards,nil,"red",nil,request)
	end
	if self:slashIsAvailable() and self.player:getStrategyMark("lxtx_longyuan") > 0 then
		for _, c in ipairs(usable_cards) do
			if c:getSuit() == sgs.Card_Diamond and self:slashIsAvailable() and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink") < 3) and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
				return turn(self,"lxtx_yizan","slash",{c:getKnownEffectiveId()},c,nil,nil,request)
			end
		end
	end
	local two_heart_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Heart and #two_heart_cards < 2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			table.insert(two_heart_cards, c:getKnownEffectiveId())
		end
	end
	if #two_heart_cards == 2 and (self.player:getStrategyMark("lxtx_longyuan") == 0) and self:getOverflow() > 0 then
		return turn(self,"lxtx_yizan","peach",two_heart_cards,nil,"red",nil,request)
	end
	if self:slashIsAvailable() and self.player:getStrategyMark("lxtx_longyuan") > 0 then
		for _, c in ipairs(usable_cards) do
			if c:getSuit() == sgs.Card_Heart and not c:isKindOf("Peach") then
				return turn(self,"lxtx_yizan","peach",{c:getKnownEffectiveId()},c,nil,nil,request)
			end
		end
	end

	local two_spade_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_spade and #two_spade_cards < 2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			table.insert(two_spade_cards, c:getKnownEffectiveId())
		end
	end
	if #two_spade_cards == 2 and (self.player:getStrategyMark("lxtx_longyuan") == 0) and self:getOverflow() > 0 then
		return turn(self,"lxtx_yizan","analeptic",two_spade_cards,nil,"black",nil,request)
	end
	if self:slashIsAvailable() and self.player:getStrategyMark("lxtx_longyuan") > 0 then
		for _, c in ipairs(usable_cards) do
			if c:getSuit() == sgs.Card_Spade and not c:isKindOf("Peach") then
				return turn(self,"lxtx_yizan","analeptic",{c:getKnownEffectiveId()},c,nil,nil,request)
			end
		end
	end
    
end

sgs.ai_view_as.lxtx_yizan = function(card, player, card_place, class_name)
	if card_place == sgs.Player_PlaceSpecial then return end
	local usable_cards = sgs.QList2Table(player:getCards("he"))
	for _, id in sgs.qlist(player:getHandPile()) do
		table.insert(usable_cards, face(own_ai(player),id))
	end
	local two_club_cards = {}
	local two_heart_cards = {}
	local two_spade_cards = {}
	local two_diamond_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Club and #two_club_cards < 2 then
			table.insert(two_club_cards, c:getKnownEffectiveId())
		elseif c:getSuit() == sgs.Card_Heart and #two_heart_cards < 2 then
			table.insert(two_heart_cards, c:getKnownEffectiveId())
		elseif c:getSuit() == sgs.Card_Diamond and #two_diamond_cards < 2 then
			table.insert(two_diamond_cards, c:getKnownEffectiveId())
		elseif c:getSuit() == sgs.Card_Spade and #two_spade_cards < 2 then
			table.insert(two_spade_cards, c:getKnownEffectiveId())
		end
	end

	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()

	if #two_club_cards == 2 and (player:getStrategyMark("lxtx_longyuan") == 0) then
		return spec("jink","lxtx_yizan",two_club_cards,nil,"black")
	elseif card:getSuit() == sgs.Card_Club and player:getStrategyMark("lxtx_longyuan") > 0 then
		return spec("jink","lxtx_yizan",{card_id},card)
	end

	if #two_heart_cards == 2 and (player:getStrategyMark("lxtx_longyuan") == 0) then
		return spec("peach","lxtx_yizan",two_heart_cards,nil,"red")
	elseif card:getSuit() == sgs.Card_Heart and player:getStrategyMark("lxtx_longyuan") > 0 then
		return spec("peach","lxtx_yizan",{card_id},card)
	end

	if #two_spade_cards == 2 and (player:getStrategyMark("lxtx_longyuan") == 0) then
		return spec("analeptic","lxtx_yizan",two_spade_cards,nil,"black")
	elseif card:getSuit() == sgs.Card_Spade and player:getStrategyMark("lxtx_longyuan") > 0 then
		return spec("analeptic","lxtx_yizan",{card_id},card)
	end

	if #two_diamond_cards == 2 and (player:getStrategyMark("lxtx_longyuan") == 0) then
		return spec("slash","lxtx_yizan",two_diamond_cards,nil,"red")
	elseif card:getSuit() == sgs.Card_Diamond and player:getStrategyMark("lxtx_longyuan") > 0 then
		return spec("slash","lxtx_yizan",{card_id},card)
	end
end

ai_skill_invoke.lxtx_qingren = true


ai_fill_skill.lxtx_lianheng = function(self, options, request)
	return seed(self,"lxtx_lianheng")
end

ai_card_use["#lxtx_lianheng"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "card", true)
	for _,ep in sgs.list(self.enemies)do
		if not ep:isChained()
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value["lxtx_lianheng"] = 9.4
sgs.ai_use_priority["lxtx_lianheng"] = 3.8
sgs.ai_card_intention["lxtx_lianheng"] = 50


ai_fill_skill.lxtx_manjuan = function(self, options, request)
	return seed(self,"lxtx_manjuan")
end

ai_card_use["#lxtx_manjuan"] = function(self, card, use, request)
    use.card = card
    return
end

sgs.ai_use_value["lxtx_manjuan"] = 9.4
sgs.ai_use_priority["lxtx_manjuan"] = 3.8
sgs.ai_card_intention["lxtx_manjuan"] = 50

ai_skill_choice.lxtx_manjuan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    if table.contains(items, "3") then return ai_choice_result(("3"), options) end
    local previous=recall(self,"lxtx_manjuan");if previous then return ai_choice_result((previous), options) end
	return ai_choice_result(("1"), options)
end


ai_skill_invoke.lxtx_manjuan = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
    if use.card:isKindOf("Peach") and self.player:getLostHp()>1 then
        remember(self,"lxtx_manjuan","2") 
        return (true) or false
    elseif use.card:isKindOf("Analeptic") then
        remember(self,"lxtx_manjuan","2") 
        return (true) or false
    elseif use.to:contains(self.player)	then 
        remember(self,"lxtx_manjuan","2") 
        return (true) or false
    elseif use.card:isDamageCard() or use.card:isKindOf("SingleTargetTrick") then
        for _,to in sgs.list(use.to)do
            if self:isFriend(to)
            then return (false) or false end
        end
        for _,to in sgs.list(use.to) do
            if self:isEnemy(to) then
                if self:hasHeavyDamage(use.from, use.card, to) then
                    remember(self,"lxtx_manjuan","1") 
                    return (true) or false
                end
            end
        end
        remember(self,"lxtx_manjuan","2") 
        return (true) or false
    end
    return (false) or false
end

ai_skill_invoke.lxtx_canshi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local n = 0
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		if p:isWounded() or (self.player:hasSkill("lxtx_guiming") and self.player:isLord() and p:getKnownKingdom()=="wu" and self.player:objectName()~=p:objectName()) then n = n+1 end
	end
	if n<2 then return (false) or false end
	if n==3 and (not self:isWeak() or self:willSkipPlayPhase()) then return (true) or false end
	if n>3 then return (true) or false end
	return (false) or false
end


ai_fill_skill.lxtx_xianzhen = function(self, options, request)
    local inclusive = options and options.inclusive

	return seed(self,"lxtx_xianzhen")
end

ai_card_use["#lxtx_xianzhen"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount-1 end

    local n = 1 + self.player:getStrategyMark("lxtx_xianzhenDrew-Clear")
    local targets = sgs.SPlayerList()
    
	if slashcount>0  then
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and self:canAttack(enemy, self.player)
				and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point =enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point>enemy_max_point then
                    targets:append(enemy)
                    if targets:length() >= n then 
                        break
                    end
				end
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and self:canAttack(enemy, self.player) and not targets:contains(enemy) and targets:length() < n
				and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
				if max_point>=10 then
					use.card = paid(self,"lxtx_xianzhen",{max_card:getKnownId()})
					use.to:append(enemy)
					if targets:length() >= n then 
                        break
                    end
				end
			end
		end
        if targets:length() > 0 then
            use.card = paid(self,"lxtx_xianzhen",{max_card:getKnownId()})
            use.to = targets
            return
        end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	if (self:getUseValue(cards[1])<6 and self:getKeepValue(cards[1])<6) or self:getOverflow()>0 then
        for _,enemy in ipairs(self.enemies)do
            if public_flag(self,enemy,"xianzhenTarget") then
                return
            end
        end
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and not self:hasTuntianEffect(enemy, true) and targets:length() < n then
				targets:append(enemy)
				if targets:length() >= n then 
                    break
                end
			end
		end
        if targets:length() > 0 then
            use.card = paid(self,"lxtx_xianzhen",{cards[1]:getId()})
            use.to = targets
            return
        end
	end
end

sgs.ai_cardneed.lxtx_xianzhen = function(to,card,self)
	local cards = to:getHandcards()
	local has_big = false
	for _,c in sgs.qlist(cards)do
		local flag = string.format("%s_%s_%s","visible",self.room:getCurrent():objectName(),to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber()>10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber()>10
	else
		return card:isKindOf("Slash") or card:isKindOf("Analeptic")
	end
end

function sgs.ai_skill_pindian.lxtx_xianzhen(minusecard,self,requestor)
	if requestor:getHandcardNum()==1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValueInPlace(cards)
		return cards[1]
	end
	if requestor:getHandcardNum()<=2 then return minusecard end
end

sgs.ai_card_intention["lxtx_xianzhen"] = 70

sgs.dynamic_value.control_card["lxtx_xianzhen"] = true

sgs.ai_use_value["lxtx_xianzhen"] = 9.2
sgs.ai_use_priority["lxtx_xianzhen"] = 9.2


sgs.ai_skill_cardask["@zhuiji-heart"] = function(self,data,pattern)
    return sgs.ai_skill_cardask["@zhuiji"](self,data,pattern)
end
sgs.ai_skill_cardask["@zhuiji-diamond"] = function(self,data,pattern)
    return sgs.ai_skill_cardask["@zhuiji"](self,data,pattern)
end
sgs.ai_skill_cardask["@zhuiji-spade"] = function(self,data,pattern)
    return sgs.ai_skill_cardask["@zhuiji"](self,data,pattern)
end
sgs.ai_skill_cardask["@zhuiji-club"] = function(self,data,pattern)
    return sgs.ai_skill_cardask["@zhuiji"](self,data,pattern)
end
sgs.ai_skill_cardask["@zhuiji"] = function(self,data,pattern)
	local suit = pattern:split("|")[2]
	local use = data:toCardUse()
	if self:needToThrowArmor() and self.player:getArmor():getSuitString()==suit then return "$"..self.player:getArmor():getEffectiveId() end
	if not self:slashIsEffective(use.card, self.player, use.from)
	or (self:ajustDamage(use.from, self.player, 1, use.card)<2
	and self:needToLoseHp(self.player, use.from, use.card)) then return "." end
	if self:ajustDamage(use.from, self.player, 1, use.card) and self:getCardsNum("Peach")>0 then return "." end
	if self:getCardsNum("Jink")==0 or not sgs.isJinkAvailable(use.from,self.player,use.card,true) then return "." end
	local equip_index = { 3,0,2,4,1 }
	if self.player:hasSkills(sgs.lose_equip_skill) then
		for _,i in ipairs(equip_index)do
			if i==4 then break end
			if self.player:getEquip(i) and self.player:getEquip(i):getSuitString()==suit then return "$"..self.player:getEquip(i):getEffectiveId() end
		end
	end
	local jiangqin = self.room:findPlayerBySkillName("niaoxiang")
	local need_double_jink = use.from:hasSkill("wushuang")
		or (use.from:hasSkill("roulin") and self.player:isFemale())
		or (self.player:hasSkill("roulin") and use.from:isFemale())
		or (jiangqin and jiangqin:isAdjacentTo(self.player) and use.from:isAdjacentTo(self.player) and self:isEnemy(jiangqin))
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	for _,card in ipairs(cards)do
		if card:getSuitString()~=suit or (not self:isWeak() and (self:getKeepValue(card)>8 or self:isValuableCard(card)))
			or (isCard("Jink",card,self.player) and self:getCardsNum("Jink")-1<(need_double_jink and 2 or 1)) then continue end
		return "$"..card:getEffectiveId()
	end
	for _,i in ipairs(equip_index)do
		if self.player:getEquip(i) and self.player:getEquip(i):getSuitString()==suit then
			if not (i==1 and self:evaluateArmor()>3)
				and not (i==4 and self.player:getTreasure():isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>=3) then
				return "$"..self.player:getEquip(i):getEffectiveId()
			end
		end
	end
end
ai_skill_use["@@lxtx_shichou"] = function(self, prompt, request)
	local use = source_use(self,"lxtx_shichou_data")
	local dummy_use = self:aiUseCard(use.card, dummy(true, math.max(self.player:getLostHp(), 1), use.to))
	if dummy_use.card and not dummy_use.to:isEmpty() then
		local lost = math.max(self.player:getLostHp(), 1)
		local num = 0
		local tos = {}
		for _,p in sgs.qlist(dummy_use.to)do
			if num>=lost then break end
			num = num+1
			table.insert(tos,p:objectName())
		end
		if #tos>0 then return response(self,"lxtx_shichou",{},tos) end
	end
	return "."
end
sgs.ai_card_intention["lxtx_shichou"] = 70

ai_skill_invoke.lxtx_yishe = true
sgs.ai_skill_playerchosen.lxtx_yisheAsk = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:isAlive() then
			return target
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.lxtx_yishe = -40

ai_skill_invoke.lxtx_shicai = true
sgs.ai_skill_playerchosen.lxtx_chenggong = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:isAlive() then
			return target
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.lxtx_chenggong = -40


ai_fill_skill.lxtx_fushi = function(self, options, request)
	return seed(self,"lxtx_fushi")
end

ai_card_use["#lxtx_fushi"] = function(self, card, use, request)
    if self.player:isLord() then
        self:sortInPlace(self.friends_noself, "card", true)
        for _,p in sgs.list(self.friends_noself)do
            if self:doDisCard(p, "he", true)  then
                use.card = card
                use.to:append(p)
                return
            end
        end
        self:sortInPlace(self.enemies, "card", true)
        for _,ep in sgs.list(self.enemies)do
            if self:doDisCard(ep, "he", true)
            then
                use.card = card
                use.to:append(ep)
                return
            end
        end
        for _,p in sgs.list(self.friends_noself)do
            if p:isNude()  then
                use.card = card
                use.to:append(p)
                return
            end
        end
    else
        local lord = self.room:getLord()
        if (self:isEnemy(lord) and not lord:isNude()) or self:isFriend(lord) then
            use.card = card
            use.to:append(lord)
            return
        end
    end
end

sgs.ai_use_value["lxtx_fushi"] = 9.4
sgs.ai_use_priority["lxtx_fushi"] = 3.8



ai_fill_skill.lxtx_yanpo = function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#lxtx_yanpo") then
		return seed(self,"lxtx_yanpo")
	end
end

ai_card_use["#lxtx_yanpo"] = function(self, card, use, request)
	local target = nil
	self:updatePlayers()
	self:sortInPlace(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Fire) and not self:cantbeHurt(enemy) and not enemy:isKongcheng() then
            target = enemy
            break
        end
	end
    
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local discard_cards = {}
	local spade_check = true
	local heart_check = true
	local club_check = true
	local diamond_check = true

	for _, c in ipairs(handcards) do
		if not c:isKindOf("Peach")
			and not c:isKindOf("Duel")
			and not c:isKindOf("Indulgence")
			and not c:isKindOf("SupplyShortage")
			and not (self:getCardsNum("Jink") == 1 and c:isKindOf("Jink"))
			and not (self:getCardsNum("Analeptic") == 1 and c:isKindOf("Analeptic"))
		then
			if spade_check and c:getSuit() == sgs.Card_Spade then
				spade_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			elseif heart_check and c:getSuit() == sgs.Card_Heart then
				heart_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			elseif club_check and c:getSuit() == sgs.Card_Club then
				club_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			elseif diamond_check and c:getSuit() == sgs.Card_Diamond then
				diamond_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			end
		end
	end
	if #discard_cards > 0 and target then
		use.card = paid(self,"lxtx_yanpo",discard_cards)
		if use.to then use.to:append(target) end
	end
end
sgs.ai_card_intention["lxtx_yanpo"] = 80

ai_skill_use["@@lxtx_yanpoheart"] = function(self, prompt, request)
    return ai_skill_use["@@lxtx_yanpo"](self, "heart", nil)
end
ai_skill_use["@@lxtx_yanpodiamond"] = function(self, prompt, request)
    return ai_skill_use["@@lxtx_yanpo"](self, "diamond", nil)
end
ai_skill_use["@@lxtx_yanpospade"] = function(self, prompt, request)
    return ai_skill_use["@@lxtx_yanpo"](self, "spade", nil)
end
ai_skill_use["@@lxtx_yanpoclub"] = function(self, prompt, request)
    return ai_skill_use["@@lxtx_yanpo"](self, "club", nil)
end

ai_skill_use["@@lxtx_yanpo"] = function(self, prompt, request)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValueInPlace(cards)
    for _, acard in ipairs(cards) do
        if acard:hasFlag("lxtx_yanpo_showcard") then
            if self:matchesDiscardPattern(prompt, acard)
            then return response(self,"lxtx_yanpo"..prompt,{acard:getKnownEffectiveId()}) end
            if acard:getSuitString() == prompt
            then return response(self,"lxtx_yanpo"..prompt,{acard:getKnownEffectiveId()}) end
        end
    end
    return "."
end


ai_audited_aliases.register({id="ai_cardneed.lxtx_jiangchi",registry="ai_cardneed",path={"lxtx_jiangchi"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.lxtx_shouyue_wusheng",registry="ai_cardneed",path={"lxtx_shouyue_wusheng"},canonical_registry="ai_cardneed",canonical_path={"wusheng"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.lxtx_shouyue_paoxiao",registry="ai_cardneed",path={"lxtx_shouyue_paoxiao"},canonical_registry="ai_cardneed",canonical_path={"paoxiao"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.lxtx_shouyue_longdan",registry="ai_cardneed",path={"lxtx_shouyue_longdan"},canonical_registry="ai_cardneed",canonical_path={"longdan"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.lxtx_shouyue_liegong",registry="ai_cardneed",path={"lxtx_shouyue_liegong"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_skill_invoke.lxtx_shouyue_liegong",registry="ai_skill_invoke",path={"lxtx_shouyue_liegong"},canonical_registry="ai_skill_invoke",canonical_path={"liegong"},self_index=1,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.lxtx_shouyue_tieqi",registry="ai_cardneed",path={"lxtx_shouyue_tieqi"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["lxtx_zhuiji"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(from,"hasSkill","lxtx_zhuiji") then
        		return nil, true
        	end
        return value
    end
    sgs.ai_need_damaged["lxtx_zhuiji"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_before_damage" and context.rule == "lxtx_zhuiji" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "lxtx_zhuiji", {
        {phase="need_hp_before_damage", order=20, rule="lxtx_zhuiji"},
    })
end)()
end
