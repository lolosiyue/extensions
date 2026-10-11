-- Loong fixed b6025acc. Policy proposals are readonly until final selection.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported('Loong input unknown',k)end;return v end
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
local function q(o,k,...)
 if not o or type(o[k])~='function'then ai_unsupported('Loong helper unavailable',k)end
 local method=k;if k=='getMark'and AIValue.isPlayer(o)then method='getStrategyMark'end
 local r=table.pack(o[method](o,...));if AIUnsupported.is(r[1])then error(r[1],0)end
 if k=='sort'or k=='sortByKeepValue'or k=='sortByUseValue'then local t=(...);known(r[1],k);for i,x in ipairs(r[1])do t[i]=x end;return t end
 if k=='hasSkill'or k=='hasSkills'then local p=AIValue.isPlayer(o)and o or select(2,...)or o.player;local row=type(p)=='table'and rawget(p,'_view');if r[1]==false and row and row.skills_complete~=true then ai_unsupported('Loong foreign skill absence unknown',(...))end end
 if not nullable[k]then known(r[1],k)end;return table.unpack(r,1,r.n)
end
local function facts(self)return known(self.world.strategy_facts and self.world.strategy_facts.Loong,'Loong')end
local function own_ai(p)local a=p._room and p._room._ai;if not a or p~=a.player then ai_unsupported('Loong view-as requires owner legal materials','Loong.view_as')end;return a end
local function face(self,id)return q(self,'getKnownCardById',id)end
local function complete_hand(self,p)
 local cards=q(p,'getHandcards');if #cards~=q(p,'getHandcardNum')then ai_unsupported('Taoxi source inspects unavailable foreign hand identities','lxtx_taoxi.foreign_hand')end;return cards
end
local function spec(name,skill,costs,material,two)
 local suit,number=sgs.Card_NoSuit,0
 if material then suit=q(material,'getSuit');number=q(material,'getNumber')end
 if two then suit=(two=='red'and sgs.Card_NoSuitRed or sgs.Card_NoSuitBlack);number=0 end
 return{name=name,skill=skill,suit=suit,number=number,subcards=costs}
end
local class={slash='Slash',jink='Jink',peach='Peach',analeptic='Analeptic'}
local function turn(self,skill,name,costs,material,two,printed,request)
 -- Zhangwu's source uses dummyCard(NoSuit,0), not a face-specific Parse.
 local proposal=spec(name,printed or skill,costs,material,two)
 if skill=='lxtx_zhangwu'then proposal.suit,proposal.number=sgs.Card_NoSuit,0 end
 return q(self,'evaluateTurnConversion',skill,known(class[name],name),proposal,request)
end
local function evaluation(self,name)return q(self,'getEvaluationCard',name or 'slash')end
local function named_eval(self,skill,name,costs)return q(self,'evaluateSkillCard',skill,name,costs)end
local function seed(self,key,costs)
 if costs then return q(self,'evaluateTurnSkillCard',key,'#'..key,costs,self.request)end
 return q(self,'legacySkillSeed',key,'#'..key,self.request)
end
local function paid(self,key,costs)
 return q(self,'bindSkillCard',key,costs,self.request,nil,'#'..key)
end
local function response(self,key,costs,targets)
 local c=paid(self,key,costs);return{kind='use_card',card_spec=q(c,'toCardSpec'),targets=targets or{}}
end
local function source_use(self,key)
 local row=q(self,'getDecisionContext').Loong
 local use=row and row[key]
 if type(use)~='table'then ai_unsupported('Loong owner source CardUse is not projected',key)end
 return hydrate_context(self,use,'CardUse')
end
local function remember(self,key,v)return q(self,'setStrategyMemory','Loong.'..key,v)end
local function recall(self,key)local v,p=q(self,'getStrategyMemory','Loong.'..key);if p then return v end end
local function public_flag(self,p,key)
 local row=facts(self).public_flags;local flags=row and row[key];return known(flags and flags[q(p,'objectName')],key)
end
local function call(self,reg,key,...)
 local f=q(self,'getHooks',reg)[key];if type(f)~='function'then ai_unsupported('Loong shared callback unavailable',reg..'.'..key)end
 local v=f(...);if AIUnsupported.is(v)then error(v,0)end;return v
end


sgs.ai_skill_invoke["lxtx_taoxi"] = function(self,data)
    local to = q(data,"toPlayer")
    if to and q(self,"isEnemy",to) then
        local dismantlement_count = 0
        if q(to,"hasSkill","noswuyan") or q(to,"getMark","@late")>0 then
            if q(self.player,"hasSkill","yinling") then
                local black = q(self,"getSuitNum","spade|club",true)
                local num = 4-q(self.player,"getPile","brocade"):length()
                dismantlement_count = dismantlement_count+math.max(0,math.min(black,num))
            end
        else
            dismantlement_count = dismantlement_count+q(self,"getCardsNum","Dismantlement")
            if q(self.player,"distanceTo",to)==1 or q(self,"hasSkills","qicai|nosqicai") then
                dismantlement_count = dismantlement_count+q(self,"getCardsNum","Snatch")
            end
        end

        if dismantlement_count>=q(to,"getHandcardNum")then return true end
        local handcards = complete_hand(self,to)
        if dismantlement_count>=handcards:length() then
            return true
        end

        local can_use,cant_use = {},{}
        for _,c in sgs.qlist(handcards)do
            if q(self.player,"isCardLimited",c,sgs.Card_MethodUse,false) then
                table.insert(cant_use,c)
            else
                table.insert(can_use,c)
            end
        end

        if #can_use==0 and dismantlement_count==0 then
            return false
        end

        if q(self,"needToLoseHp") then
            return true
        end

        local knowns,unknowns = {},{}
        local flag = string.format("visible_%s_%s",q(self.player,"objectName"),q(to,"objectName"))
        for _,c in sgs.qlist(handcards)do
            if q(self.player,"canSeeHandcard",to) and q(c,"hasFlag","visible") or q(c,"hasFlag",flag) then
                table.insert(knowns,c)
            else
                table.insert(unknowns,c)
            end
        end

        if #knowns>0 then --Now I begin to lose control...Need more help.
            local can_use_record = {}
            for _,c in ipairs(can_use)do
                can_use_record[q(c,"getId")] = true
            end

            local can_use_count = 0
            local to_can_use_count = 0
            local function can_use_check(user,to_use)
                if q(to_use,"isKindOf","EquipCard") then
                    return not q(user,"isProhibited",user,to_use)
                elseif q(to_use,"isKindOf","BasicCard") then
                    if q(to_use,"isKindOf","Jink") then
                        return false
                    elseif q(to_use,"isKindOf","Peach") then
                        if q(user,"hasFlag","Global_PreventPeach") then
                            return false
                        elseif q(user,"getLostHp")==0 then
                            return false
                        elseif q(user,"isProhibited",user,to_use) then
                            return false
                        end
                        return true
                    elseif q(to_use,"isKindOf","Slash") then
                        if q(to_use,"isAvailable",user) then
                            local others = q(self.room,"getOtherPlayers",user)
                            for _,p in sgs.qlist(others)do
                                if q(user,"canSlash",p,to_use) then
                                    return true
                                end
                            end
                        end
                        return false
                    elseif q(to_use,"isKindOf","Analeptic") then
                        if q(to_use,"isAvailable",user) then
                            return not q(user,"isProhibited",user,to_use)
                        end
                    end
                elseif q(to_use,"isKindOf","TrickCard") then
                    if q(to_use,"isKindOf","Nullification") then
                        return false
                    elseif q(to_use,"isKindOf","DelayedTrick") then
                        if q(user,"containsTrick",q(to_use,"objectName")) then
                            return false
                        elseif q(user,"isProhibited",user,to_use) then
                            return false
                        end
                        return true
                    elseif q(to_use,"isKindOf","Collateral") then
                        local others = q(self.room,"getOtherPlayers",user)
                        local selected = sgs.PlayerList()
                        for _,p in sgs.qlist(others)do
                            if q(to_use,"targetFilter",selected,p,user) then
                                local victims = q(self.room,"getOtherPlayers",p)
                                for _,p2 in sgs.qlist(victims)do
                                    if q(p,"canSlash",p2) then
                                        return true
                                    end
                                end
                            end
                        end
                    elseif q(to_use,"isKindOf","ExNihilo") then
                        return not q(user,"isProhibited",user,to_use)
                    else
                        local others = q(self.room,"getOtherPlayers",user)
                        for _,p in sgs.qlist(others)do
                            if not q(user,"isProhibited",p,to_use) then
                                return true
                            end
                        end
                        if q(to_use,"isKindOf","GlobalEffect") and not q(user,"isProhibited",user,to_use) then
                            return true
                        end
                    end
                end
                return false
            end
            for _,c in ipairs(knowns)do
                if can_use_record[q(c,"getId")] and can_use_check(self.player,c) then
                    can_use_count = can_use_count+1
                end
            end

            local to_friends = q(self,"getFriends",to)
            local to_has_weak_friend = false
            local to_is_weak = q(self,"isWeak",to)
            for _,friend in ipairs(to_friends)do
                if q(self,"isEnemy",friend) and q(self,"isWeak",friend) then
                    to_has_weak_friend = true
                    break
                end
            end

            local my_trick,my_slash,my_aa,my_duel,my_sa = nil,nil,nil,nil,nil
            local use = source_use(self,"taoxi_carduse")
            local ucard = use.card
            if q(ucard,"isKindOf","TrickCard") then
                my_trick = 1
                if q(ucard,"isKindOf","Duel") then
                    my_duel = 1
                elseif q(ucard,"isKindOf","ArcheryAttack") then
                    my_aa = 1
                elseif q(ucard,"isKindOf","SavageAssault") then
                    my_sa = 1
                end
            elseif q(ucard,"isKindOf","Slash") then
                my_slash = 1
            end
            
            for _,c in ipairs(knowns)do
                if isCard("Nullification",c,to) then
                    my_trick = my_trick or ( q(self,"getCardsNum","TrickCard")-q(self,"getCardsNum","DelayedTrick") )
                    if my_trick>0 then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                end
                if isCard("Jink",c,to) then
                    my_slash = my_slash or q(self,"getCardsNum","Slash")
                    if my_slash>0 then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                    my_aa = my_aa or q(self,"getCardsNum","ArcheryAttack")
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
                    if q(to,"getHp")<=1 and to_is_weak then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                end
                if isCard("Slash",c,to) then
                    my_duel = my_duel or q(self,"getCardsNum","Duel")
                    if my_duel>0 then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                    my_sa = my_sa or q(self,"getCardsNum","SavageAssault")
                    if my_sa>0 then
                        to_can_use_count = to_can_use_count+1
                        continue
                    end
                end
            end

            if can_use_count>=to_can_use_count+#unknowns then
                return true
            elseif can_use_count>0 and ( can_use_count+0.01 )/( to_can_use_count+0.01 )>=0.5 then
                return true
            end
        end

        if q(self,"getCardsNum","Peach")>0 then
            return true
        end
        if math.random() < 0.6 then return true end
    end
    return false
end
sgs.ai_fill_skill.lxtx_taoxi = function(self,inclusive,request)
    if q(self.player,"getMark","lxtx_taoxi-SelfPlayClear") > 0
	then
        local c = q(self.player,"getMark","taoxiName-Clear")
        if c and c>=0
		then
            local list = named_eval(self,"lxtx_taoxi",face(self,c):objectName(),{})
            
			if q(list,"isAvailable",self.player)
			then return list end
        end
    end
end

sgs.ai_card_priority.lxtx_taoxi = function(self,card)
	if table.contains(q(card,"getSkillNames"), "lxtx_taoxi")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_skill_askforag.lxtx_taoxi = function(self,card_ids)
	for i,card_id in ipairs(card_ids)do
		local c = q(self,"getChoiceCard",card_id)
        local dummy_use = q(self,"aiUseCard",c, dummy())
        if dummy_use.card then
            return card_id
        end
	end

	return card_ids[1]
end

-- audited alias ai_cardneed.lxtx_jiangchi
sgs.ai_skill_invoke.lxtx_jiangchi = function(self,data)
    return true
end

sgs.ai_skill_discard.lxtx_jiangchi = function(self,discard_num,min_num,optional,include_equip)
    if q(self,"getCardsNum","Slash")>0	then 
        local cards = sgs.QList2Table(q(self.player,"getHandcards"))
        local to_discard = {}
        local compare_func = function(a,b)
            return q(self,"getKeepValue",a)<q(self,"getKeepValue",b)
        end
        table.sort(cards,compare_func)
        for _,card in sgs.list(cards)do
            if #to_discard>=1 then break end
            table.insert(to_discard,q(card,"getId"))
        end

        return to_discard
    end
	return "."
end


sgs.ai_fill_skill.lxtx_zhangwu = function(self,inclusive,request)
	local cards = q(self,"addHandPile","h")
	cards = q(self,"sortByUseValue",cards,true)
	local use_cards = {}
	local useAll = false
	q(self,"sort",self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if q(enemy,"getHp")<2 and not q(enemy,"hasArmorEffect","EightDiagram")
		and q(self.player,"distanceTo",enemy)<=q(self.player,"getAttackRange") and q(self,"isWeak",enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end

	for _,card in ipairs(cards)do
		if not q(card,"isKindOf","Slash") and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (q(self,"getUseValue",card)<sgs.ai_use_value.Slash or inclusive or q(evaluation(self),"getTargetResidue")>0)
		then table.insert(use_cards,card) end
	end

    if q(self.player,"getMark","lxtx_jiangchi_recast-Clear") > 0 then
        for _,card in ipairs(use_cards)do
            local slash=turn(self,"lxtx_zhangwu","slash",{q(card,"getEffectiveId")},card,nil,"lxtx_zhangwuu",request)
            if q(slash,"isAvailable",self.player)
            then return slash end
        end
    end
    if q(self.player,"getMark","lxtx_jiangchi_draw-Clear") > 0 and useAll then
        local costs={}
        for _,card in ipairs(cards)do
            if (not isCard("Peach",card,self.player) and not isCard("Analeptic",card,self.player) and not isCard("EquipCard",card,self.player)) then
                costs[#costs+1]=q(card,"getEffectiveId")
            end
        end
        local slash
        if #costs>0 then slash=turn(self,"lxtx_zhangwu","slash",costs,nil,nil,"lxtx_zhangwuu",request)end
        if #costs>0 and q(slash,"isAvailable",self.player)
            then return slash end
    end
    local costs={}
    for _,card in ipairs(cards)do
        if  useAll then
            costs[#costs+1]=q(card,"getEffectiveId")
        end
    end
    local slash
        if #costs>0 then slash=turn(self,"lxtx_zhangwu","slash",costs,nil,nil,"lxtx_zhangwuu",request)end
        if #costs>0 and q(slash,"isAvailable",self.player)
        then return slash end
end


sgs.ai_fill_skill.lxtx_zhengpi = function(self)
	local cards = q(self.player,"getCards","he")
	cards = q(self,"sortByKeepValue",cards)
  	for _,c in sgs.list(cards)do
		if q(c,"isKindOf","BasicCard")
		then
			return seed(self,"lxtx_zhengpi",{q(c,"getEffectiveId")})
		end
	end
end

sgs.ai_skill_use_func["#lxtx_zhengpi"] = function(card,use,self)
	q(self,"sort",self.friends_noself,"card",true)
	for _,p in sgs.list(self.friends_noself)do
		if q(p,"getCardCount")>1 and q(self,"doDisCard",p, "h")
		then
			use.card = card
			use.to:append(p)
			return
		end
	end
	q(self,"sort",self.enemies,"card",true)
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getCardCount")>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getCardCount")>0
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

sgs.ai_skill_invoke.lxtx_fengying = function(self,data)
    if q(self.player,"getMaxHp") - q(self.player,"getHandcardNum") > 0 then
        if #self.enemies > 0 and known(self.world.turn_count,"turn_count") > 0 then
            return true
        end
    end
    if q(self,"isWeak") and q(self,"getAllPeachNum") == 0 and math.random() < 0.6 then return true end
    return false
end

sgs.ai_skill_invoke.lxtx_jizhao = function(self,data)
	local dying = q(data,"toDying")
	local peaches = 1-q(dying.who,"getHp")

	return q(self,"getCardsNum","Peach")+q(self,"getCardsNum","Analeptic")<peaches
end

sgs.ai_canNiepan_skill.lxtx_jizhao = function(player)
	return q(player,"getMark","lxtx_jizhao") == 0
end


sgs.ai_fill_skill.lxtx_rende = function(self,inclusive,request)
	return seed(self,"lxtx_rende")
end

sgs.ai_skill_use_func["#lxtx_rende"] = function(card,use,self)
    q(self,"sort",self.friends_noself, "defense")
    local need = {}
    for _,p in ipairs(self.friends_noself) do
        table.insert(need, p)
    end

    local give = 0 
    if #need == 0 then return end
    if #need == 1 then give = math.max(2, q(self.player,"getHandcardNum") - q(self.player,"getMaxCards")) end
    if #need > 1 then give = 2 end

    local cards = sgs.QList2Table(q(self.player,"getCards","h"))
    q(self,"sortByKeepValue",cards)
    local usecards = {}
    for _,cc in ipairs(cards) do
		if q(self,"willUse",self.player,cc) then continue end
        table.insert(usecards, q(cc,"getEffectiveId"))
        give = give - 1
        if give <= 0 then break end
    end
    if give > 0 then return end
    local card_str = string.format("#lxtx_rende:%s:->%s", table.concat(usecards,"+"), need[1]:objectName())
    use.card = paid(self,"lxtx_rende",usecards)
    if use.to then use.to:append(need[1]) end
end

sgs.ai_skill_choice["lxtx_rende"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then return items[1] end
    if q(self.player,"getLostHp") > 1 then return "peach" end
    table.removeOne(items, "cancel")
    for _,pattern in ipairs(items) do
        local card = named_eval(self,"lxtx_rende_choice",pattern,{})
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        q(self,"useCardByClassName",card, usec)
        if usec.to and usec.to:length() > 0 then
            return pattern
        end
    end
    return "cancel"
end

sgs.ai_skill_use["@@lxtx_rende"] = function(self, prompt)
    local pattern = known(facts(self).rende_property,"lxtx_rende.property")

    if pattern == "peach" or pattern == "analeptic" then
        return response(self,"lxtx_rende_basic",{},{q(self.player,"objectName")})
    end

	local card = named_eval(self,"lxtx_rende_choice",pattern,{})
	
    local card = named_eval(self,"lxtx_rende_choice",pattern,{})
    local usec = {isDummy=true,to=sgs.SPlayerList()}
    q(self,"useCardByClassName",card, usec)
    if usec.to and usec.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(usec.to) do
            table.insert(tos, q(to,"objectName"))
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
	if enemy and q(enemy,"getHp") <= 1 and getCardsNum("Jink", enemy, self.player) == 0 then
		return 4.1
	end
end
function sgs.ai_slash_weaponfilter.LxtxFeiLongDuoFeng(self, to, player)
	if q(player,"distanceTo",to) > math.max(sgs.weapon_range.LxtxFeiLongDuoFeng, q(player,"getAttackRange")) then return end
	return getCardsNum("Peach", to, self.player) + getCardsNum("Jink", to, self.player) < 1
		and getCardsNum("Jink", to, self.player) == 0
end
sgs.ai_skill_invoke._lxtx_feilongduofeng_re = function(self, data)
	if not q(self.player,"isLord") and q(self.player,"getRole") == "renegade" then return false end
	return true
end
sgs.ai_skill_invoke._lxtx_feilongduofeng = function(self, data)
	local use = q(data,"toCardUse")
	for _, to in sgs.qlist(use.to) do
		local eff = q(self,"doDisCard",to)
		return eff and q(self,"isEnemy",to)
	end
	return
end

local function apply_feilong_role(self,actor,target)
 local witness=self.world.strategy_facts and self.world.strategy_facts.loong_feilong_role_witness
 local actor_name=q(actor,'objectName');local target_name=q(target,'objectName')
 if type(witness)~='table'or witness.actor~=actor_name or actor_name~=q(self.player,'objectName')then
  ai_unsupported('Feilong role effect lacks actor-private choice witness','Loong.feilong.role')
 end
 local found=false;for _,name in ipairs(witness.targets or{})do if name==target_name then found=true;break end end
 local roles={lord=true,loyalist=true,rebel=true,renegade=true}
 if not found or not roles[witness.role]then ai_unsupported('Feilong target/role is outside witnessed source domain','Loong.feilong.role')end
 -- Actor-private native ChoiceMade exposes only the owner's already known role.
 -- Foreign source roles are not queried or silently estimated here.
 self:emitStrategyEffect{kind='loong_feilong_role',actor=actor_name,player=target_name,role=witness.role}
end

sgs.ai_choicemade_filter.skillInvoke._lxtx_feilongduofeng_re=function(self,player,promptlist)
 if promptlist[#promptlist]=="yes"then
  for _,sb in ipairs(q(self.room,"getOtherPlayers",player))do
   if public_flag(self,sb,"LxtxFeiLongDuoFeng")then
    apply_feilong_role(self,player,sb)
    q(self,"updatePlayers")
   end
  end
 end
end

sgs.ai_view_as.lxtx_shouyue_wusheng = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place~=sgs.Player_PlaceSpecial and not q(card,"isKindOf","Peach") and not q(card,"hasFlag","using") then
		return spec("slash","lxtx_shouyue_wusheng",{card_id},card)
	end
end

sgs.ai_fill_skill.lxtx_shouyue_wusheng = function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	cards = q(self,"sortByUseValue",cards,true)
	local red_card = {}
	local useAll = false
	q(self,"sort",self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if q(enemy,"getHp")<2 and not q(enemy,"hasArmorEffect","EightDiagram")
		and q(self.player,"distanceTo",enemy)<=q(self.player,"getAttackRange") and q(self,"isWeak",enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end

	for _,card in ipairs(cards)do
		if not q(card,"isKindOf","Slash")
		and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (q(self,"getUseValue",card)<sgs.ai_use_value.Slash or inclusive or q(evaluation(self),"getTargetResidue")>0)
		then table.insert(red_card,card) end
	end


	for _,card in ipairs(red_card)do
		local slash=turn(self,"lxtx_shouyue_wusheng","slash",{q(card,"getEffectiveId")},card,nil,nil,request)
		if q(slash,"isAvailable",self.player)
		then return slash end
	end
end

-- audited alias ai_cardneed.lxtx_shouyue_wusheng
sgs.double_slash_skill = sgs.double_slash_skill .. "|lxtx_shouyue_paoxiao"
-- audited alias ai_cardneed.lxtx_shouyue_paoxiao
sgs.ai_use_revises.lxtx_shouyue_paoxiao = function(self,card,use)
	if q(card,"isKindOf","Slash") then
		q(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end


sgs.ai_fill_skill.lxtx_shouyue_longdan = function(self,inclusive,request)
	local cards = q(self,"addHandPile")
	local jink_card
	q(self,"sortByUseValue",cards,true)
	for _,card in ipairs(cards)  do
		if q(card,"isKindOf","Jink") then
			jink_card = card
			break
		end
	end
	if not jink_card then return nil end
	local suit = q(jink_card,"getSuitString")
	local number = q(jink_card,"getNumberString")
	local card_id = q(jink_card,"getEffectiveId")
	local card_str = ("slash:lxtx_shouyue_longdan[%s:%s]=%d"):format(suit,number,card_id)
	local slash=turn(self,"lxtx_shouyue_longdan","slash",{card_id},jink_card,nil,nil,request)
	assert(slash)
	return slash

end

sgs.ai_view_as.lxtx_shouyue_longdan = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place==sgs.Player_PlaceHand then
		if q(card,"isKindOf","Jink") then
			return spec("slash","lxtx_shouyue_longdan",{card_id},card)
		elseif q(card,"isKindOf","Slash") then
			return spec("jink","lxtx_shouyue_longdan",{card_id},card)
		end
	end
end


-- audited alias ai_cardneed.lxtx_shouyue_longdan
sgs.ai_card_priority.lxtx_shouyue_longdan = function(self,card)
	if table.contains(q(card,"getSkillNames"), "lxtx_shouyue_longdan")
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
	return q(from,"getPhase") == sgs.Player_Play and (q(to,"getHandcardNum") >= q(from,"getHp") or q(to,"getHandcardNum") <= q(from,"getAttackRange"))
end


-- audited alias ai_cardneed.lxtx_shouyue_tieqi
-- audited alias ai_skill_invoke.lxtx_shouyue_tieqi
sgs.hit_skill = sgs.hit_skill .. "|lxtx_shouyue_tieqi"





sgs.ai_view_as.lxtx_wupao = function(card,player,card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place~=sgs.Player_PlaceSpecial and q(card,"isRed") and not q(card,"isKindOf","Peach") and not q(card,"hasFlag","using") then
		return spec("slash","lxtx_wupao",{card_id},card)
	end
end

sgs.ai_fill_skill.lxtx_wupao = function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	cards = q(self,"sortByUseValue",cards,true)
	local red_card = {}
	local useAll = false
	q(self,"sort",self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if q(enemy,"getHp")<2 and not q(enemy,"hasArmorEffect","EightDiagram")
		and q(self.player,"distanceTo",enemy)<=q(self.player,"getAttackRange") and q(self,"isWeak",enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end

	for _,card in ipairs(cards)do
		if q(card,"isRed") and not q(card,"isKindOf","Slash") 
		and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (q(self,"getUseValue",card)<sgs.ai_use_value.Slash or inclusive or q(evaluation(self),"getTargetResidue")>0)
		then table.insert(red_card,card) end
	end

	for _,card in ipairs(red_card)do
		local slash=turn(self,"lxtx_wupao","slash",{q(card,"getEffectiveId")},card,nil,nil,request)
		if q(slash,"isAvailable",self.player)
		then return slash end
	end
end

function sgs.ai_cardneed.lxtx_wupao(to,card)
	return q(to,"getHandcardNum")<3 and q(card,"isRed")
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|lxtx_wupao"

sgs.ai_fill_skill.lxtx_yizan = function(self,inclusive,request)
	local usable_cards = {}
    local heart, diamond, club, spade = {},{},{},{}
	q(self,"sortByUseValue",usable_cards,true)
	
	local equips = sgs.QList2Table(q(self.player,"getCards","e"))
	for _, e in ipairs(equips) do
		if q(e,"isKindOf","DefensiveHorse") or q(e,"isKindOf","OffensiveHorse") then
			table.insert(usable_cards, e)
		end
	end
	for _, id in sgs.qlist(q(self.player,"getHandPile")) do
		table.insert(usable_cards, face(self,id))
	end
	q(self,"sortByUseValue",usable_cards, true)
	local two_diamond_cards = {}
	for _, c in ipairs(usable_cards) do
		if q(c,"getSuit") == sgs.Card_Diamond and #two_diamond_cards < 2 and not q(c,"isKindOf","Peach") and not (q(c,"isKindOf","WoodenOx") and q(self.player,"getPile","wooden_ox"):length() > 0) and not q(c,"isKindOf","Slash") then
			table.insert(two_diamond_cards, q(c,"getEffectiveId"))
		end
	end
	if #two_diamond_cards == 2 and q(self,"slashIsAvailable") and (q(self.player,"getMark","lxtx_longyuan") == 0) and q(self,"getOverflow") > 0 then
		return turn(self,"lxtx_yizan","slash",two_diamond_cards,nil,"red",nil,request)
	end
	if q(self,"slashIsAvailable") and q(self.player,"getMark","lxtx_longyuan") > 0 then
		for _, c in ipairs(usable_cards) do
			if q(c,"getSuit") == sgs.Card_Diamond and q(self,"slashIsAvailable") and not q(c,"isKindOf","Peach") and not (q(c,"isKindOf","Jink") and q(self,"getCardsNum","Jink") < 3) and not (q(c,"isKindOf","WoodenOx") and q(self.player,"getPile","wooden_ox"):length() > 0) then
				return turn(self,"lxtx_yizan","slash",{q(c,"getEffectiveId")},c,nil,nil,request)
			end
		end
	end
	local two_heart_cards = {}
	for _, c in ipairs(usable_cards) do
		if q(c,"getSuit") == sgs.Card_Heart and #two_heart_cards < 2 and not q(c,"isKindOf","Peach") and not (q(c,"isKindOf","WoodenOx") and q(self.player,"getPile","wooden_ox"):length() > 0) then
			table.insert(two_heart_cards, q(c,"getEffectiveId"))
		end
	end
	if #two_heart_cards == 2 and (q(self.player,"getMark","lxtx_longyuan") == 0) and q(self,"getOverflow") > 0 then
		return turn(self,"lxtx_yizan","peach",two_heart_cards,nil,"red",nil,request)
	end
	if q(self,"slashIsAvailable") and q(self.player,"getMark","lxtx_longyuan") > 0 then
		for _, c in ipairs(usable_cards) do
			if q(c,"getSuit") == sgs.Card_Heart and not q(c,"isKindOf","Peach") then
				return turn(self,"lxtx_yizan","peach",{q(c,"getEffectiveId")},c,nil,nil,request)
			end
		end
	end

	local two_spade_cards = {}
	for _, c in ipairs(usable_cards) do
		if q(c,"getSuit") == sgs.Card_spade and #two_spade_cards < 2 and not q(c,"isKindOf","Peach") and not (q(c,"isKindOf","WoodenOx") and q(self.player,"getPile","wooden_ox"):length() > 0) then
			table.insert(two_spade_cards, q(c,"getEffectiveId"))
		end
	end
	if #two_spade_cards == 2 and (q(self.player,"getMark","lxtx_longyuan") == 0) and q(self,"getOverflow") > 0 then
		return turn(self,"lxtx_yizan","analeptic",two_spade_cards,nil,"black",nil,request)
	end
	if q(self,"slashIsAvailable") and q(self.player,"getMark","lxtx_longyuan") > 0 then
		for _, c in ipairs(usable_cards) do
			if q(c,"getSuit") == sgs.Card_Spade and not q(c,"isKindOf","Peach") then
				return turn(self,"lxtx_yizan","analeptic",{q(c,"getEffectiveId")},c,nil,nil,request)
			end
		end
	end
    
end

sgs.ai_view_as.lxtx_yizan = function(card, player, card_place, class_name)
	if card_place == sgs.Player_PlaceSpecial then return end
	local usable_cards = sgs.QList2Table(q(player,"getCards","he"))
	for _, id in sgs.qlist(q(player,"getHandPile")) do
		table.insert(usable_cards, face(own_ai(player),id))
	end
	local two_club_cards = {}
	local two_heart_cards = {}
	local two_spade_cards = {}
	local two_diamond_cards = {}
	for _, c in ipairs(usable_cards) do
		if q(c,"getSuit") == sgs.Card_Club and #two_club_cards < 2 then
			table.insert(two_club_cards, q(c,"getEffectiveId"))
		elseif q(c,"getSuit") == sgs.Card_Heart and #two_heart_cards < 2 then
			table.insert(two_heart_cards, q(c,"getEffectiveId"))
		elseif q(c,"getSuit") == sgs.Card_Diamond and #two_diamond_cards < 2 then
			table.insert(two_diamond_cards, q(c,"getEffectiveId"))
		elseif q(c,"getSuit") == sgs.Card_Spade and #two_spade_cards < 2 then
			table.insert(two_spade_cards, q(c,"getEffectiveId"))
		end
	end

	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")

	if #two_club_cards == 2 and (q(player,"getMark","lxtx_longyuan") == 0) then
		return spec("jink","lxtx_yizan",two_club_cards,nil,"black")
	elseif q(card,"getSuit") == sgs.Card_Club and q(player,"getMark","lxtx_longyuan") > 0 then
		return spec("jink","lxtx_yizan",{card_id},card)
	end

	if #two_heart_cards == 2 and (q(player,"getMark","lxtx_longyuan") == 0) then
		return spec("peach","lxtx_yizan",two_heart_cards,nil,"red")
	elseif q(card,"getSuit") == sgs.Card_Heart and q(player,"getMark","lxtx_longyuan") > 0 then
		return spec("peach","lxtx_yizan",{card_id},card)
	end

	if #two_spade_cards == 2 and (q(player,"getMark","lxtx_longyuan") == 0) then
		return spec("analeptic","lxtx_yizan",two_spade_cards,nil,"black")
	elseif q(card,"getSuit") == sgs.Card_Spade and q(player,"getMark","lxtx_longyuan") > 0 then
		return spec("analeptic","lxtx_yizan",{card_id},card)
	end

	if #two_diamond_cards == 2 and (q(player,"getMark","lxtx_longyuan") == 0) then
		return spec("slash","lxtx_yizan",two_diamond_cards,nil,"red")
	elseif q(card,"getSuit") == sgs.Card_Diamond and q(player,"getMark","lxtx_longyuan") > 0 then
		return spec("slash","lxtx_yizan",{card_id},card)
	end
end

sgs.ai_skill_invoke.lxtx_qingren = true


sgs.ai_fill_skill.lxtx_lianheng = function(self)
	return seed(self,"lxtx_lianheng")
end

sgs.ai_skill_use_func["#lxtx_lianheng"] = function(card,use,self)
	q(self,"sort",self.enemies,"card",true)
	for _,ep in sgs.list(self.enemies)do
		if not q(ep,"isChained")
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


sgs.ai_fill_skill.lxtx_manjuan = function(self)
	return seed(self,"lxtx_manjuan")
end

sgs.ai_skill_use_func["#lxtx_manjuan"] = function(card,use,self)
    use.card = card
    return
end

sgs.ai_use_value["lxtx_manjuan"] = 9.4
sgs.ai_use_priority["lxtx_manjuan"] = 3.8
sgs.ai_card_intention["lxtx_manjuan"] = 50

sgs.ai_skill_choice.lxtx_manjuan = function(self,choices,data)
    local items = choices:split("+")
    if table.contains(items, "3") then return "3" end
    local previous=recall(self,"lxtx_manjuan");if previous then return previous end
	return "1"
end


sgs.ai_skill_invoke.lxtx_manjuan = function(self,data)
    local use = q(data,"toCardUse")
    if q(use.card,"isKindOf","Peach") and q(self.player,"getLostHp")>1 then 
        remember(self,"lxtx_manjuan","2") 
        return true
    elseif q(use.card,"isKindOf","Analeptic") then
        remember(self,"lxtx_manjuan","2") 
        return true
    elseif use.to:contains(self.player)	then 
        remember(self,"lxtx_manjuan","2") 
        return true
    elseif q(use.card,"isDamageCard") or q(use.card,"isKindOf","SingleTargetTrick") then
        for _,to in sgs.list(use.to)do
            if q(self,"isFriend",to)
            then return false end
        end
        for _,to in sgs.list(use.to) do
            if q(self,"isEnemy",to) then
                if q(self,"hasHeavyDamage",use.from,use.card,to) then
                    remember(self,"lxtx_manjuan","1") 
                    return true
                end
            end
        end
        remember(self,"lxtx_manjuan","2") 
        return true
    end
    return false
end

sgs.ai_skill_invoke.lxtx_canshi = function(self,data)
	local n = 0
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers"))do
		if q(p,"isWounded") or (q(self.player,"hasSkill","lxtx_guiming") and q(self.player,"isLord") and q(p,"getKingdom")=="wu" and q(self.player,"objectName")~=q(p,"objectName")) then n = n+1 end
	end
	if n<2 then return false end
	if n==3 and (not q(self,"isWeak") or q(self,"willSkipPlayPhase")) then return true end
	if n>3 then return true end
	return false
end


sgs.ai_fill_skill.lxtx_xianzhen = function(self,inclusive,request)
	return seed(self,"lxtx_xianzhen")
end

sgs.ai_skill_use_func["#lxtx_xianzhen"] = function(card,use,self)
	q(self,"sort",self.enemies,"handcard")
	local max_card = q(self,"getMaxCard")
	local max_point = q(max_card,"getNumber")
	local slashcount = q(self,"getCardsNum","Slash")
	if q(max_card,"isKindOf","Slash") then slashcount = slashcount-1 end

    local n = 1 + q(self.player,"getMark","lxtx_xianzhenDrew-Clear")
    local targets = sgs.SPlayerList()
    
	if slashcount>0  then
		for _,enemy in ipairs(self.enemies)do
			if not (q(enemy,"hasSkill","kongcheng") and q(enemy,"getHandcardNum")==1) and q(self.player,"canPindian",enemy) and q(self,"canAttack",enemy,self.player)
				and not q(self,"canLiuli",enemy,self.friends_noself) and not q(self,"findLeijiTarget",enemy,50,self.player) then
				local enemy_max_card = q(self,"getMaxCard",enemy)
				local enemy_max_point =enemy_max_card and q(enemy_max_card,"getNumber") or 100
				if max_point>enemy_max_point then
                    targets:append(enemy)
                    if targets:length() >= n then 
                        break
                    end
				end
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if not (q(enemy,"hasSkill","kongcheng") and q(enemy,"getHandcardNum")==1) and q(self.player,"canPindian",enemy) and q(self,"canAttack",enemy,self.player) and not targets:contains(enemy) and targets:length() < n
				and not q(self,"canLiuli",enemy,self.friends_noself) and not q(self,"findLeijiTarget",enemy,50,self.player) then
				if max_point>=10 then
					use.card = paid(self,"lxtx_xianzhen",{q(max_card,"getId")})
					use.to:append(enemy)
					if targets:length() >= n then 
                        break
                    end
				end
			end
		end
        if targets:length() > 0 then
            use.card = paid(self,"lxtx_xianzhen",{q(max_card,"getId")})
            use.to = targets
            return
        end
	end
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByUseValue",cards,true)
	if (q(self,"getUseValue",cards[1])<6 and q(self,"getKeepValue",cards[1])<6) or q(self,"getOverflow")>0 then
        for _,enemy in ipairs(self.enemies)do
            if public_flag(self,enemy,"xianzhenTarget") then
                return
            end
        end
		for _,enemy in ipairs(self.enemies)do
			if not (q(enemy,"hasSkill","kongcheng") and q(enemy,"getHandcardNum")==1) and q(self.player,"canPindian",enemy) and not q(self,"hasTuntianEffect",enemy, true) and targets:length() < n then
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
	local cards = q(to,"getHandcards")
	local has_big = false
	for _,c in sgs.qlist(cards)do
		local flag = string.format("%s_%s_%s","visible",q(self.room,"getCurrent"):objectName(),q(to,"objectName"))
		if q(c,"hasFlag","visible") or q(c,"hasFlag",flag) then
			if q(c,"getNumber")>10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return q(card,"getNumber")>10
	else
		return q(card,"isKindOf","Slash") or q(card,"isKindOf","Analeptic")
	end
end

function sgs.ai_skill_pindian.lxtx_xianzhen(minusecard,self,requestor)
	if q(requestor,"getHandcardNum")==1 then
		local cards = sgs.QList2Table(q(self.player,"getHandcards"))
		q(self,"sortByKeepValue",cards)
		return cards[1]
	end
	if q(requestor,"getHandcardNum")<=2 then return minusecard end
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
	local use = q(data,"toCardUse")
	if q(self,"needToThrowArmor") and q(self.player,"getArmor"):getSuitString()==suit then return "$"..self.player:getArmor():getEffectiveId() end
	if not q(self,"slashIsEffective",use.card,self.player,use.from)
	or (q(self,"ajustDamage",use.from,self.player,1,use.card)<2
	and q(self,"needToLoseHp",self.player,use.from,use.card)) then return "." end
	if q(self,"ajustDamage",use.from,self.player,1,use.card) and q(self,"getCardsNum","Peach")>0 then return "." end
	if q(self,"getCardsNum","Jink")==0 or not sgs.isJinkAvailable(use.from,self.player,use.card,true) then return "." end
	local equip_index = { 3,0,2,4,1 }
	if q(self.player,"hasSkills",sgs.lose_equip_skill) then
		for _,i in ipairs(equip_index)do
			if i==4 then break end
			if q(self.player,"getEquip",i) and q(self.player,"getEquip",i):getSuitString()==suit then return "$"..self.player:getEquip(i):getEffectiveId() end
		end
	end
	local jiangqin = q(self.room,"findPlayerBySkillName","niaoxiang")
	local need_double_jink = q(use.from,"hasSkill","wushuang")
		or (q(use.from,"hasSkill","roulin") and q(self.player,"isFemale"))
		or (q(self.player,"hasSkill","roulin") and q(use.from,"isFemale"))
		or (jiangqin and q(jiangqin,"isAdjacentTo",self.player) and q(use.from,"isAdjacentTo",self.player) and q(self,"isEnemy",jiangqin))
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByKeepValue",cards)
	for _,card in ipairs(cards)do
		if q(card,"getSuitString")~=suit or (not q(self,"isWeak") and (q(self,"getKeepValue",card)>8 or q(self,"isValuableCard",card)))
			or (isCard("Jink",card,self.player) and q(self,"getCardsNum","Jink")-1<(need_double_jink and 2 or 1)) then continue end
		return "$"..card:getEffectiveId()
	end
	for _,i in ipairs(equip_index)do
		if q(self.player,"getEquip",i) and q(self.player,"getEquip",i):getSuitString()==suit then
			if not (i==1 and q(self,"evaluateArmor")>3)
				and not (i==4 and q(self.player,"getTreasure"):isKindOf("WoodenOx") and q(self.player,"getPile","wooden_ox"):length()>=3) then
				return "$"..self.player:getEquip(i):getEffectiveId()
			end
		end
	end
end
sgs.ai_skill_use["@@lxtx_shichou"] = function(self,prompt)
	local use = source_use(self,"lxtx_shichou_data")
	local dummy_use = q(self,"aiUseCard",use.card,dummy(true, math.max(q(self.player,"getLostHp"), 1), use.to))
	if dummy_use.card and not dummy_use.to:isEmpty() then
		local lost = math.max(q(self.player,"getLostHp"), 1)
		local num = 0
		local tos = {}
		for _,p in sgs.qlist(dummy_use.to)do
			if num>=lost then break end
			num = num+1
			table.insert(tos,q(p,"objectName"))
		end
		if #tos>0 then return response(self,"lxtx_shichou",{},tos) end
	end
	return "."
end
sgs.ai_card_intention["lxtx_shichou"] = 70

sgs.ai_skill_invoke.lxtx_yishe = true
sgs.ai_skill_playerchosen.lxtx_yisheAsk = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if q(self,"isFriend",target) and q(target,"isAlive") then
			return target
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.lxtx_yishe = -40

sgs.ai_skill_invoke.lxtx_shicai = true
sgs.ai_skill_playerchosen.lxtx_chenggong = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if q(self,"isFriend",target) and q(target,"isAlive") then
			return target
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.lxtx_chenggong = -40


sgs.ai_fill_skill.lxtx_fushi = function(self)
	return seed(self,"lxtx_fushi")
end

sgs.ai_skill_use_func["#lxtx_fushi"] = function(card,use,self)
    if q(self.player,"isLord") then
        q(self,"sort",self.friends_noself,"card",true)
        for _,p in sgs.list(self.friends_noself)do
            if q(self,"doDisCard",p, "he", true)  then
                use.card = card
                use.to:append(p)
                return
            end
        end
        q(self,"sort",self.enemies,"card",true)
        for _,ep in sgs.list(self.enemies)do
            if q(self,"doDisCard",ep, "he", true)
            then
                use.card = card
                use.to:append(ep)
                return
            end
        end
        for _,p in sgs.list(self.friends_noself)do
            if q(p,"isNude")  then
                use.card = card
                use.to:append(p)
                return
            end
        end
    else
        local lord = q(self.room,"getLord")
        if (q(self,"isEnemy",lord) and not q(lord,"isNude")) or q(self,"isFriend",lord) then
            use.card = card
            use.to:append(lord)
            return
        end
    end
end

sgs.ai_use_value["lxtx_fushi"] = 9.4
sgs.ai_use_priority["lxtx_fushi"] = 3.8



sgs.ai_fill_skill.lxtx_yanpo = function(self,inclusive,request)
	if not q(self.player,"hasUsed","#lxtx_yanpo") then
		return seed(self,"lxtx_yanpo")
	end
end

sgs.ai_skill_use_func["#lxtx_yanpo"] = function(card, use, self)
	local target = nil
	q(self,"updatePlayers")
	q(self,"sort",self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if q(self,"damageIsEffective",enemy, sgs.DamageStruct_Fire) and not q(self,"cantbeHurt",enemy) and not q(enemy,"isKongcheng") then
            target = enemy
            break
        end
	end
    
	local handcards = sgs.QList2Table(q(self.player,"getCards","h"))
	local discard_cards = {}
	local spade_check = true
	local heart_check = true
	local club_check = true
	local diamond_check = true

	for _, c in ipairs(handcards) do
		if not q(c,"isKindOf","Peach")
			and not q(c,"isKindOf","Duel")
			and not q(c,"isKindOf","Indulgence")
			and not q(c,"isKindOf","SupplyShortage")
			and not (q(self,"getCardsNum","Jink") == 1 and q(c,"isKindOf","Jink"))
			and not (q(self,"getCardsNum","Analeptic") == 1 and q(c,"isKindOf","Analeptic"))
		then
			if spade_check and q(c,"getSuit") == sgs.Card_Spade then
				spade_check = false
				table.insert(discard_cards, q(c,"getEffectiveId"))
			elseif heart_check and q(c,"getSuit") == sgs.Card_Heart then
				heart_check = false
				table.insert(discard_cards, q(c,"getEffectiveId"))
			elseif club_check and q(c,"getSuit") == sgs.Card_Club then
				club_check = false
				table.insert(discard_cards, q(c,"getEffectiveId"))
			elseif diamond_check and q(c,"getSuit") == sgs.Card_Diamond then
				diamond_check = false
				table.insert(discard_cards, q(c,"getEffectiveId"))
			end
		end
	end
	if #discard_cards > 0 and target then
		use.card = paid(self,"lxtx_yanpo",discard_cards)
		if use.to then use.to:append(target) end
	end
end
sgs.ai_card_intention["lxtx_yanpo"] = 80

sgs.ai_skill_use["@@lxtx_yanpoheart"] = function(self,prompt)
    return sgs.ai_skill_use["@@lxtx_yanpo"](self, "heart")
end
sgs.ai_skill_use["@@lxtx_yanpodiamond"] = function(self,prompt)
    return sgs.ai_skill_use["@@lxtx_yanpo"](self, "diamond")
end
sgs.ai_skill_use["@@lxtx_yanpospade"] = function(self,prompt)
    return sgs.ai_skill_use["@@lxtx_yanpo"](self, "spade")
end
sgs.ai_skill_use["@@lxtx_yanpoclub"] = function(self,prompt)
    return sgs.ai_skill_use["@@lxtx_yanpo"](self, "club")
end

sgs.ai_skill_use["@@lxtx_yanpo"] = function(self,prompt)
    local cards = sgs.QList2Table(q(self.player,"getCards","h"))
    q(self,"sortByKeepValue",cards)
    for _, acard in ipairs(cards) do
        if q(acard,"hasFlag","lxtx_yanpo_showcard") then
            if q(self,"matchesDiscardPattern",prompt,acard)
            then return response(self,"lxtx_yanpo"..prompt,{q(acard,"getEffectiveId")}) end
            if q(acard,"getSuitString") == prompt
            then return response(self,"lxtx_yanpo"..prompt,{q(acard,"getEffectiveId")}) end
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

ai_audited_aliases.register({id="ai_skill_invoke.lxtx_shouyue_tieqi",registry="ai_skill_invoke",path={"lxtx_shouyue_tieqi"},canonical_registry="ai_skill_invoke",canonical_path={"nostieji"},self_index=1,defer_canonical=true})
