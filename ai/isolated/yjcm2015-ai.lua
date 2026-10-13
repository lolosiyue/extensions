-- Fixed donor b6025acc: YJCM2015 policy; all action authority stays native.
local function known(v,key)if v==nil then ai_unsupported("YJCM2015 value unknown",key)end;return v end
local function call(o,m,...)
    if AIValue.isPlayer(o)then if m=="getMark"then m="getStrategyMark"elseif m=="hasFlag"then m="getStrategyFlag"end end
    if not o or type(o[m])~="function"then ai_unsupported("YJCM2015 query unavailable",m)end
    return known(o[m](o,...),m)
end
local function register_fill(row)
    setmetatable(row,{__newindex=function(t,k,v)rawset(t,k,v);if k=="getTurnUseCard"then sgs.ai_fill_skill[t.name]=v end end})
    if row.getTurnUseCard then sgs.ai_fill_skill[row.name]=row.getTurnUseCard end
    return row
end
local function addAiSkills(name)return register_fill({name=name})end
local function replace_order(t,sorted)for i,v in ipairs(sorted)do t[i]=v end;return t end
local function sort_players(self,t,...)return replace_order(t,call(self,"sort",t,...))end
local function sort_keep(self,t,...)return replace_order(t,call(self,"sortByKeepValue",t,...))end
local function sort_use(self,t,...)return replace_order(t,call(self,"sortByUseValue",t,...))end
local function pattern_names(self)return known(AICardCatalog.patternNames(),"public pattern order")end
local function evaluation(self,name)
    local names={ArcheryAttack="archery_attack",SavageAssault="savage_assault",Duel="duel",Slash="slash"}
    name=names[name or "slash"]or name or "slash"
    return self:getEvaluationCard(name)
end
-- PatternsCard scans Engine::getRandomCards, whose mode/banlist filtering is not projected.
local function pattern_card(self,name)
    ai_unsupported("PatternsCard random card pool is not projected",name)
end
-- Own TaoxiId tag; QVariant::toInt reads absent as 0, as the donor does.
local function own_taoxi_id(self)return tonumber(self.player:getTag("TaoxiId"))or 0 end
local function visible_card(self,id)return known(self:getKnownCardById(id),"lawfully disclosed card "..tostring(id))end
local function taoxi_id(self,player)
    if call(player,"objectName")~=call(self.player,"objectName")then ai_unsupported("Taoxi tag belongs to a different owner","taoxi.owner")end
    return own_taoxi_id(self)
end
local function taoxi_use(self)
    local value=self.player:getTag("taoxi_carduse")
    if type(value)~="table"or type(value.card)~="table"or next(value.card)==nil then ai_unsupported("Taoxi source requires current use","taoxi.use")end
    return {card=CardView.new(known(value.card,"Taoxi public used card"))}
end
local function disclosed_hand(self,player)
    local cards=call(player,"objectName")==call(self.player,"objectName")and call(player,"getHandcards")or player:getKnownCards()
    cards=known(cards,"disclosed hand")
    local count=call(player,"getHandcardNum")-#cards
    if count<0 then ai_unsupported("disclosed hand exceeds public count","taoxi.hand")end
    if count>0 then self:useKnowledgeEstimate({status="estimate",value=true,known_count=#cards,hidden_count=count,target=call(player,"objectName"),basis="taoxi_undisclosed_faces_omitted_unknown_cards_assumed_potentially_usable"},"taoxi.invoke")end
    return cards
end
local function known_hand(self,target)
    local cards=known(self:getKnownCards(target,self.player),"Wurong known hand")
    local count=call(target,"getHandcardNum")-#known(target:getKnownCards(),"Wurong disclosed physical hand")
    if count<0 then ai_unsupported("known hand exceeds public count","wurong.hand")end
    return cards,count
end
local function taoxi_limited(self,card)
    local evaluated=self:getAcquiredCardEvaluation(card)
    return call(self.player,"isCardLimited",evaluated or card,sgs.Card_MethodUse,false)
end
local function source_yanzhu_dot_false(self,player)
    -- Donor dot invocation passes Player as SmartAI receiver. The actual
    -- needToThrowArmor helper defaults its absent player argument to receiver.player
    -- (nil), then its userdata guard returns false before reading any armor.
    return false
end

local classes={MingjianCard="mingjian",HuaiyiCard="huaiyi",HuaiyiSnatchCard="huaiyi",QinwangCard="qinwang",ZhenshanCard="zhenshan",YanzhuCard="yanzhu",XingxueCard="xingxue",YjYanyuCard="yjyanyu",WurongCard="wurong",HuomoCard="huomo",AnguoCard="anguo",OLzhaofuCard="olzhaofu"}
local function policy_card(self,class,ids,declaration)
    -- The audited binder returns native authority wrapped in exact legacy
    -- prototype metadata, including response-only classes without Play seeds.
    return call(self,"bindSkillCard",known(classes[class],"authored class"),ids,nil,declaration,class)
end

-- Parse only this module's authored cost proposals, never arbitrary input or
-- an action result; the parsed costs are validated by bindSkillCard.
local function authored(self,text,bind)
    local class,body=text:match("^@([%w_]+)=(.*)$")
    if not class or not classes[class]then ai_unsupported("invalid YJCM2015 authored class",text)end
    local encoded,declaration=body:match("^([^:]*):(.*)$");if not encoded then encoded=body end
    if declaration==""then declaration=nil end
    local ids={};if encoded~="."then for id in encoded:gmatch("[^+]+")do local n=tonumber(id);if not n or n<0 or n%1~=0 then ai_unsupported("invalid authored cost",text)end;ids[#ids+1]=n end end
    if not bind and #ids==0 and not declaration then return call(self,"legacySkillSeed",classes[class],class)end
    return policy_card(self,class,ids,declaration)
end
local function duel_conversion(self,skill,request)
    local ids={};for _,c in ipairs(call(self.player,"getHandcards"))do ids[#ids+1]=call(c,"getEffectiveId")end
    return call(self,"evaluateTurnConversion",skill,"Duel",{name="duel",skill=skill,suit=sgs.Card_NoSuit,number=0,subcards=ids},request)
end

local function source_lihun_global_error()
    ai_unsupported("donor source error: lihun_skill is local to bgm-ai.lua, global is nil","taoxi.lihun_global")
end
local function can_to(self,card,target,prefix)
    -- Empty targetFilter has an exact native projection. Nonempty-prefix
    -- predicates need their explicit native query, not a final-combo guess.
    if type(self.cardTargetFilter)=="function"and not(type(card.isEvaluationOnly)=="function"and card:isEvaluationOnly())then return call(self,"cardTargetFilter",card,prefix,target)end
    if #prefix>0 then ai_unsupported("nonempty source targetFilter prefix not projected","yjcm2015.targetFilter")end
    local _,acquired=self:getAcquiredCardEvaluation(card)
    local candidate=acquired or self:getEvaluationCandidate(card)or(AIValue.isConversion(card)and card)or self:getCardCandidate(call(card,"getEffectiveId"))
    return call(known(candidate,"source targetFilter candidate"),"canTargetWithEmptyPrefix",target)
end

local function taoxi_available(self,card)
    if self.request.kind~="activate"then ai_unsupported("Taoxi fill requires its Play candidate","taoxi.fill")end
    local candidate=known(self:getCardCandidate(call(card,"getEffectiveId")),"issued Taoxi borrowed candidate")
    return call(candidate,"isAvailable")
end

-- Player::inMyAttackRange(to, fix) ends in distanceTo(to, fix) <= getAttackRange(); the
-- facade estimates the unfixed case the same way.
local function public_range(self,from,to,offset)
    if (offset or 0)==0 then return call(from,"inMyAttackRange",to) end
    if call(from,"objectName")==call(to,"objectName")then return false end
    return call(from,"distanceTo",to,offset)<=call(from,"getAttackRange")
end

sgs.ai_skill_playerchosen.huituo = function(self,targets)
    sort_players(self,self.friends)
	for _,p in sgs.list(self.friends)do
		if call(p,"isWounded") then
			return p
		end
	end
	for _,p in sgs.list(self.friends)do
		if self:canDraw(p) then
			return p
		end
	end
    return self.friends[1]
end

sgs.ai_playerchosen_intention.huituo = -80

sgs.ai_skill_playerchosen.nosmingjian = function(self,targets)
    if (sgs.ai_skill_invoke.fangquan(self) or self:needKongcheng(self.player)) then
        local cards = sgs.QList2Table(call(self.player,"getHandcards"))
        sort_keep(self,cards)
        if known(self:getRoleCounts(),"role counts").rebel==0 then
            local lord = self.room:getLord()
            if lord and self:isFriend(lord) and call(lord,"objectName")~=call(self.player,"objectName") then
                return lord
            end
        end

        local AssistTarget = self:AssistTarget()
        if AssistTarget and not self:willSkipPlayPhase(AssistTarget) then
            return AssistTarget
        end

        sort_players(self,self.friends_noself,"chaofeng")
        return self.friends_noself[1]
    end
    return nil
end

sgs.ai_playerchosen_intention.nosmingjian = -80

addAiSkills("mingjian").getTurnUseCard = function(self)
	return authored(self,"@MingjianCard=.:")
end

sgs.ai_skill_use_func["MingjianCard"] = function(card,use,self)
	sort_players(self,self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if self:isWeak(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
	sort_players(self,self.friends_noself,nil,true)
	for _,p in sgs.list(self.friends_noself)do
		if not self:isWeak(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.MingjianCard = 2.4
sgs.ai_use_priority.MingjianCard = -2.4


sgs.ai_skill_invoke.xingshuai = sgs.ai_skill_invoke.niepan

sgs.ai_skill_invoke._xingshuai = function(self)
    local lord = self.room:getCurrentDyingPlayer()
    local save = false
    if lord and call(lord,"getLostHp")>0 then
        if self:isFriend(lord) then
            save = true
        elseif self.role=="renegade" and call(lord,"isLord") and call(self.room,"alivePlayerCount")>2 then
            if call(lord,"getHp")<=0 then
                save = true
            end
        end
    end
    if save then
        local hp_max = call(lord,"getHp")+self:getAllPeachNum(lord)
        local must_save = ( hp_max<=0 )
        local others = call(self.room,"getOtherPlayers",lord)
        others:removeOne(self.player)
        local count = 0
        for _,p in sgs.qlist(others)do
            if call(p,"getKingdom")=="wei" and call(p,"getMark","xingshuai_act")==0 then
                if not self:isEnemy(p,lord) then
                    count = count+1
                end
            end
        end
        local am_safe = false
        if call(self.player,"getHp")>1 then
            am_safe = true
        elseif call(self.player,"hasSkill","buqu") then
            am_safe = true
        elseif call(self.player,"hasSkill","nosbuqu") then
            am_safe = true
        elseif call(self.player,"hasSkill","niepan") and call(self.player,"getMark","@nirvana")>0 then
            am_safe = true
        elseif call(self.player,"hasSkill","fuli") and call(self.player,"getMark","@laoji")>0 then
            am_safe = true
        elseif call(self.player,"hasSkill","zhichi") and call(self.player,"getMark","@late")>0 then
            am_safe = true
        elseif call(self.player,"hasSkill","fenyong") and call(self.player,"getMark","@fenyong")>0 then
            am_safe = true
        elseif call(self.player,"getMark","&dawu")>0 then
            am_safe = true
        elseif call(self.player,"hasSkill","sizhan") then
            am_safe = true
        elseif self:getAllPeachNum()>0 then
            am_safe = true
        end
        if call(self,"hasSkills",sgs.masochism_skill) and am_safe then
            return true
        elseif must_save then
            if am_safe then
                return true
            elseif hp_max+count<=0 then
                return true
            elseif self.role=="renegade" or self.role=="lord" then
                return false
            end
        end
        if am_safe then
            if self:getBestHp(self.player)>call(self.player,"getHp") then
                return true
            end
        elseif call(self.player,"hasSkill","wuhun") and self:needDeath(self.player) then
            if self.role~="renegade" and self.role~="lord" then
                return true
            end
        end
    end
    return false
end
sgs.ai_choicemade_filter["skillInvoke"]["_xingshuai"] = function(self,player,promptlist)
    if #promptlist=="yes" then
        local lord = self.room:getCurrentDyingPlayer()
        if lord and not call(self,"hasSkills",sgs.masochism_skill,player) then
            sgs.updateIntention(player,lord,-60)
        end
    end
end

sgs.ai_skill_invoke["taoxi"] = function(self,data)
    local to = data:toPlayer()
    if to and self:isEnemy(to) then

        if call(self.player,"hasSkill","lihun") and call(to,"isMale") and not call(self.player,"hasUsed","LihunCard") then
            local callback = source_lihun_global_error()
            if type(callback)=="function" then
                local skillcard = callback(self)
                if skillcard then
                    local dummy_use = AIUsePlan.new()
                    self:useSkillCard(skillcard,dummy_use)
                    if dummy_use.card then
                        for _,p in sgs.qlist(dummy_use.to)do
                            if call(p,"objectName")==call(to,"objectName") then
                                return true
                            end
                        end
                    end
                end
            end
        end

        if call(self.player,"hasSkill","dimeng") and not call(self.player,"hasUsed","DimengCard") then
            local callback = known(sgs.ai_fill_skill.dimeng,"dimeng fill dependency")
            if type(callback)=="function" then
                local skillcard = callback(self)
                if skillcard then
                    local dummy_use = AIUsePlan.new()
                    self:useSkillCard(skillcard,dummy_use)
                    if dummy_use.card then
                        for _,p in sgs.qlist(dummy_use.to)do
                            if call(p,"objectName")==call(to,"objectName") then
                                return true
                            end
                        end
                    end
                end
            end
        end

        local dismantlement_count = 0
        if call(to,"hasSkill","noswuyan") or call(to,"getMark","@late")>0 then
            if call(self.player,"hasSkill","yinling") then
                local black = self:getSuitNum("spade|club",true)
                local num = 4-call(self.player,"getPile","brocade"):length()
                dismantlement_count = dismantlement_count+math.max(0,math.min(black,num))
            end
        else
            dismantlement_count = dismantlement_count+self:getCardsNum("Dismantlement")
            if call(self.player,"distanceTo",to)==1 or call(self,"hasSkills","qicai|nosqicai") then
                dismantlement_count = dismantlement_count+self:getCardsNum("Snatch")
            end
        end

        local handcards = disclosed_hand(self,to)
        local hidden_count = call(to,"getHandcardNum")-#handcards
        if dismantlement_count>=call(to,"getHandcardNum") then
            return true
        end

        local can_use,cant_use = {},{}
        for _,c in sgs.qlist(handcards)do
            if taoxi_limited(self,c) then
                table.insert(cant_use,c)
            else
                table.insert(can_use,c)
            end
        end

        if #can_use==0 and hidden_count==0 and dismantlement_count==0 then
            return false
        end

        if self:needToLoseHp() then
            return true
        end

        local knowns,unknowns = {},hidden_count
        local flag = string.format("visible_%s_%s",call(self.player,"objectName"),call(to,"objectName"))
        for _,c in sgs.qlist(handcards)do
            if call(c,"hasFlag","visible") or call(c,"hasFlag",flag) then
                table.insert(knowns,c)
            else
                unknowns=unknowns+1
            end
        end

        if #knowns>0 then --Now I begin to lose control...Need more help.
            local can_use_record = {}
            for _,c in ipairs(can_use)do
                can_use_record[call(c,"getId")] = true
            end

            local can_use_count = 0
            local to_can_use_count = 0
            local function can_use_check(user,to_use)
                to_use=self:getAcquiredCardEvaluation(to_use)or to_use
                if call(to_use,"isKindOf","EquipCard") then
                    return not call(user,"isProhibited",user,to_use)
                elseif call(to_use,"isKindOf","BasicCard") then
                    if call(to_use,"isKindOf","Jink") then
                        return false
                    elseif call(to_use,"isKindOf","Peach") then
                        if call(user,"hasFlag","Global_PreventPeach") then
                            return false
                        elseif call(user,"getLostHp")==0 then
                            return false
                        elseif call(user,"isProhibited",user,to_use) then
                            return false
                        end
                        return true
                    elseif call(to_use,"isKindOf","Slash") then
                        if call(to_use,"isAvailable",user) then
                            local others = call(self.room,"getOtherPlayers",user)
                            for _,p in sgs.qlist(others)do
                                if call(user,"canSlash",p,to_use) then
                                    return true
                                end
                            end
                        end
                        return false
                    elseif call(to_use,"isKindOf","Analeptic") then
                        if call(to_use,"isAvailable",user) then
                            return not call(user,"isProhibited",user,to_use)
                        end
                    end
                elseif call(to_use,"isKindOf","TrickCard") then
                    if call(to_use,"isKindOf","Nullification") then
                        return false
                    elseif call(to_use,"isKindOf","DelayedTrick") then
                        if call(user,"containsTrick",call(to_use,"objectName")) then
                            return false
                        elseif call(user,"isProhibited",user,to_use) then
                            return false
                        end
                        return true
                    elseif call(to_use,"isKindOf","Collateral") then
                        local others = call(self.room,"getOtherPlayers",user)
                        local selected = sgs.PlayerList()
                        for _,p in sgs.qlist(others)do
                            if can_to(self,to_use,p,selected) then
                                local victims = call(self.room,"getOtherPlayers",p)
                                for _,p2 in sgs.qlist(victims)do
                                    if call(p,"canSlash",p2) then
                                        return true
                                    end
                                end
                            end
                        end
                    elseif call(to_use,"isKindOf","ExNihilo") then
                        return not call(user,"isProhibited",user,to_use)
                    else
                        local others = call(self.room,"getOtherPlayers",user)
                        for _,p in sgs.qlist(others)do
                            if not call(user,"isProhibited",p,to_use) then
                                return true
                            end
                        end
                        if call(to_use,"isKindOf","GlobalEffect") and not call(user,"isProhibited",user,to_use) then
                            return true
                        end
                    end
                end
                return false
            end
            for _,c in ipairs(knowns)do
                if can_use_record[call(c,"getId")] and can_use_check(self.player,c) then
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
            local use = taoxi_use(self)
            local ucard = use.card
            if call(ucard,"isKindOf","TrickCard") then
                my_trick = 1
                if call(ucard,"isKindOf","Duel") then
                    my_duel = 1
                elseif call(ucard,"isKindOf","ArcheryAttack") then
                    my_aa = 1
                elseif call(ucard,"isKindOf","SavageAssault") then
                    my_sa = 1
                end
            elseif call(ucard,"isKindOf","Slash") then
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
                    if call(to,"getHp")<=1 and to_is_weak then
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

            if can_use_count>=to_can_use_count+unknowns then
                return true
            elseif can_use_count>0 and ( can_use_count+0.01 )/( to_can_use_count+0.01 )>=0.5 then
                return true
            end
        end

        if self:getCardsNum("Peach")>0 then
            return true
        end
    end
    return false
end

local taoxi = {}
taoxi.name = "taoxi"
register_fill(taoxi)
taoxi.getTurnUseCard = function(self)
    if call(self.player,"hasFlag","TaoxiRecord")
	then
        local c = own_taoxi_id(self)
        if c and c>=0
		then
            c = visible_card(self,c)
			if taoxi_available(self,c)
			then return c end
        end
    end
end

sgs.ai_cardsview_valuable.taoxi = function(self,class_name,player)
    local id = taoxi_id(self,player)
     if id and id>=0
	then
		if visible_card(self,id):isKindOf(class_name)
		then return tostring(id) end
    end
end

local huaiyi_skill = {
    name = "huaiyi",
    getTurnUseCard = function(self,inclusive)
        if call(self.player,"isKongcheng") then return nil end
        local handcards = call(self.player,"getHandcards")
        local red,black = false,false
        for _,c in sgs.qlist(handcards)do
            if call(c,"isRed") and not red then
                red = true
                if black then
                    break
                end
            elseif call(c,"isBlack") and not black then
                black = true
                if red then
                    break
                end
            end
        end
        if red and black then
            return authored(self,"@HuaiyiCard=.")
        end
    end,
}
register_fill(huaiyi_skill)
sgs.ai_skill_use_func["HuaiyiCard"] = function(card,use,self)
    local handcards = call(self.player,"getHandcards")
    local reds,blacks = {},{}
    for _,c in sgs.qlist(handcards)do
        local dummy_use = AIUsePlan.new()
        if call(c,"isKindOf","BasicCard") then
            self:useBasicCard(c,dummy_use)
        elseif call(c,"isKindOf","EquipCard") then
            self:useEquipCard(c,dummy_use)
        elseif call(c,"isKindOf","TrickCard") then
            self:useTrickCard(c,dummy_use)
        end
        if dummy_use.card then
            return --It seems that self.player should use this card first.
        end
        if call(c,"isRed") then
            table.insert(reds,c)
        else
            table.insert(blacks,c)
        end
    end

    local targets = self:findPlayerToDiscard("he",false,false)
    local n_reds,n_blacks,n_targets = #reds,#blacks,#targets
    if n_targets==0 then
        return
    elseif n_reds-n_targets>=2 and n_blacks-n_targets>=2 and handcards:length()-n_targets>=5 then
        return
    end
    --------------------
    use.card = card
end

sgs.ai_skill_choice["huaiyi"] = function(self,choices,data)
    local choice = self:getStrategyMemory("yjcm2015.huaiyi_choice")
    if choice then
        self:setStrategyMemory("yjcm2015.huaiyi_choice",nil)
        return choice
    end
    local handcards = call(self.player,"getHandcards")
    local reds,blacks = {},{}
    for _,c in sgs.qlist(handcards)do
        if call(c,"isRed") then
            table.insert(reds,c)
        else
            table.insert(blacks,c)
        end
    end
    if #reds<#blacks then
        return "red"
    else
        return "black"
    end
end

sgs.ai_skill_use["@@huaiyi"] = function(self,prompt,method)
    local n = call(self.player,"getMark","huaiyi_num")
    if n>=2 then
        if self:needToLoseHp() then
        elseif self:isWeak() then
            n = 1
        end
    end
    if n==0 then
        return "."
    end
    local targets = self:findPlayerToDiscard("he",false,false)
    local names = {}
    for index,target in ipairs(targets)do
        if index<=n then
            table.insert(names,call(target,"objectName"))
        else
            break
        end
    end
    return "@HuaiyiSnatchCard=.->"..table.concat(names,"+")
end

sgs.ai_skill_invoke.jigong = function(self)
    if call(self.player,"isKongcheng") then return true end
    for _,c in sgs.qlist(call(self.player,"getHandcards"))do
        local x = nil
        if isCard("ArcheryAttack",c,self.player) then
            x = evaluation(self,"ArcheryAttack")
        elseif isCard("SavageAssault",c,self.player) then
            x = evaluation(self,"SavageAssault")
        else continue end

        local du = AIUsePlan.new()
        self:useTrickCard(x,du)
        if (du.card) then return true end
    end

    return false
end

sgs.ai_skill_invoke.shifei = function(self)
    local sf = {}
    for _,p in sgs.qlist(call(self.room,"getAlivePlayers"))do
        sf[call(p,"objectName")] = call(p,"getHandcardNum")
        if p==self.room:getCurrent() then
            sf[call(p,"objectName")] = call(p,"getHandcardNum")+1
        end
    end

    local most = {}
    for k,t in pairs(sf)do
        if #most==0 then
            table.insert(most,k)
            continue
        end

        if t>sf[most[1]] then
            most = {}
        end

        table.insert(most,k)
    end

    if table.contains(most,self.room:getCurrent():objectName()) then
        return table.contains(self.friends,self.room:getCurrent(),true)
    end

    for _,p in ipairs(most)do
        if table.contains(self.enemies,self.room:findPlayerByObjectName(p)) then return true end
    end
    return false
end

sgs.ai_skill_playerchosen.shifei = function(self,targets)
    targets = sgs.QList2Table(targets)
    for _,target in ipairs(targets)do
        if self:isEnemy(target) and call(target,"isAlive") then
            return target
        end
    end
end


local zhanjue_skill = {name = "zhanjue"}
register_fill(zhanjue_skill)
zhanjue_skill.getTurnUseCard = function(self,inclusive,request)
    if call(self.player,"getHandcardNum")>call(self.player,"getHp") or call(self.player,"isKongcheng") or #known(self.toUse,"planned card sequence")>1 then return end
    return duel_conversion(self,"zhanjue",request)
end

sgs.ai_use_revises.zhanjue = function(self,card,use)
	if table.contains(call(card,"getSkillNames"), "zhanjue") then
		for _,ep in sgs.list(self.enemies)do
			if can_to(self,card,ep,use.to)
			and getCardsNum("Slash",ep,self.player)<1 then
				use.card = card
				use.to:append(ep)
			end
		end
		return use.card==card
	end
end

addAiSkills("qinwang").getTurnUseCard = function(self)
	local can
    for _,target in sgs.list(call(self.room,"getLieges","shu",self.player))do
		if self:isFriend(target)
		and call(target,"getHandcardNum")>2
		then can = true break end
	end
    local cards = call(self.player,"getCards","he")
    cards = sort_keep(self,cards)
    if call(self.player,"getMark","qinwang-PlayClear")>0
	or not call(self.player,"hasLordSkill","qinwang")
	or call(self.player,"hasFlag","qinwangjijiang")
	or #cards<2 or not can then return end
   	local poi = evaluation(self)
   	local dummy = self:aiUseCard(poi)
 	if call(poi,"isAvailable",self.player)
	and dummy.card and dummy.to:length()>0
  	then
       	local parse = authored(self,"@QinwangCard="..call(cards[1],"getEffectiveId")..":slash")
      	assert(parse)
       	return parse
	end
end

sgs.ai_skill_use_func["QinwangCard"] = function(card,use,self)
   	local poi = evaluation(self)
   	local dummy = self:aiUseCard(poi)
	if dummy.card then use.card = card end
	if dummy.to then use.to = dummy.to end
end

sgs.ai_use_value.QinwangCard = 4
sgs.ai_use_priority.QinwangCard = 2.2

sgs.ai_guhuo_card.qinwang = function(self,toname,class_name)
    if call(self.player,"hasFlag","qinwangjijiang")
	or class_name~="Slash" then return end
	local can
    for _,target in sgs.list(call(self.room,"getLieges","shu",self.player))do
		if self:isFriend(target)
		then can = getCardsNum(class_name,target,self.player)>0 end
	end
    local cards = call(self.player,"getCards","he")
    cards = sort_keep(self,cards,nil,true) -- 按保留值排序
	if can and #cards>0 and self:getCardsNum(class_name)<1 and call(self.player,"hasLordSkill","qinwang")
	then return "@QinwangCard="..call(cards[1],"getEffectiveId")..":"..toname end
end

local olzhanjue_skill = {name = "olzhanjue"}
register_fill(olzhanjue_skill)
olzhanjue_skill.getTurnUseCard = function(self,inclusive,request)
    if call(self.player,"getHandcardNum")>call(self.player,"getHp") or call(self.player,"isKongcheng") then return end
    return duel_conversion(self,"olzhanjue",request)
end

sgs.ai_use_revises.olzhanjue = function(self,card,use)
	if table.contains(call(card,"getSkillNames"), "olzhanjue")
	then
		for _,ep in sgs.list(self.enemies)do
			if can_to(self,card,ep,use.to)
			and getCardsNum("Slash",ep,self.player)<1
			then
				use.card = card
				use.to:append(ep)
			end
		end
		return use.card==card
	end
end

sgs.ai_skill_playerchosen.zhenshan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	sort_players(self,destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	sort_players(self,destlist,"handcard",true)
	return destlist[1]
end

sgs.ai_guhuo_card.zhenshan = function(self,toname,class_name)
	local can
   	local poi = evaluation(self,toname)
	if not poi then return end
  	for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
		if not self:isEnemy(p)
		and call(p,"getHandcardNum")<call(self.player,"getHandcardNum")
		then can = true break end
	end
    if can and call(poi,"isKindOf","BasicCard")
	and self:getCardsNum(class_name)<1
	and not call(self.player,"hasFlag","ZhenshanUsed")
    then
        return "@ZhenshanCard=.:"..toname
	end
end

addAiSkills("zhenshan").getTurnUseCard = function(self)
	local can
  	for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
		if not self:isEnemy(p)
		and call(p,"getHandcardNum")<call(self.player,"getHandcardNum")
		then can = true break end
	end
	if not can
	then return end
   	for _,name in sgs.list(pattern_names(self))do
   		local poi = evaluation(self,name)
		if not poi then continue end
	   	if call(poi,"isAvailable",self.player)
	   	and call(poi,"isKindOf","BasicCard")
		and self:getCardsNum(call(poi,"getClassName"))<1
	   	then
         	local dummy = self:aiUseCard(poi)
	       	if dummy.card
           	and dummy.to
	       	then
				self.zhenshan_to = dummy.to
				local parse = authored(self,"@ZhenshanCard=.:"..name)
                assert(parse)
                return parse
	    	end
		end
	end
end

sgs.ai_skill_use_func["ZhenshanCard"] = function(card,use,self)
	use.card = card
   	use.to = self.zhenshan_to
end

sgs.ai_use_value.ZhenshanCard = 2.4
sgs.ai_use_priority.ZhenshanCard = 2.4


local yanzhu_skill = {name = "yanzhu"}
register_fill(yanzhu_skill)
yanzhu_skill.getTurnUseCard = function(self)
    return authored(self,"@YanzhuCard=.")
end


sgs.ai_skill_use_func.YanzhuCard = function(card,use,self)

    sort_players(self,self.enemies,"threat")
    for _,p in ipairs(self.enemies)do
        if not call(p,"isNude") then
            use.card = card
            if (use.to) then use.to:append(p) end
            -- use.from = self.player
            return
        end
    end

    for _,p in ipairs(self.friends_noself)do
        if source_yanzhu_dot_false(self,p) and p:getArmor() and not call(p,"isJilei",p:getArmor()) then
            use.card = card
            if (use.to) then use.to:append(p) end
            -- use.from = self.player
            return
        end
    end

    return nil
end

sgs.ai_use_priority.YanzhuCard = sgs.ai_use_priority.Dismantlement-0.1

sgs.ai_skill_discard.yanzhu = function(self,_,__,optional)
    if not optional then return self:recommendDiscard(1,1,false,true) end

    if self:needToThrowArmor() and self.player:getArmor() and not call(self.player,"isJilei",self.player:getArmor()) then return self.player:getArmor():getEffectiveId() end

    if self.player:getTreasure() then
        if (call(self.player,"getCardCount")==1) then return self.player:getTreasure():getEffectiveId()
        elseif not call(self.player,"isKongcheng") then return self:recommendDiscard(1,1,false,false) end
    end

    if call(self.player,"getEquips"):length()>2 and not call(self.player,"isKongcheng") then return self:recommendDiscard(1,1,false,false) end

    if call(self.player,"getEquips"):length()==1 then return {} end

     return self:recommendDiscard(1,1,false,true)
end

sgs.ai_skill_use["@@xingxue"] = function(self)

    local n = (call(self.player,"getMark","yanzhu_lost")==0) and call(self.player,"getHp") or call(self.player,"getMaxHp")
	n = math.min(n,#self.friends)
	if n<=0 then return "." end

	sort_players(self,self.friends,"defense",true)

    local l = AIList.new({})
    local s = {}
    for i = 1,n,1 do
        l:append(self.friends[i])
        table.insert(s,call(self.friends[i],"objectName"))
    end

    if #s==0 then return "." end

    self:setStrategyMemory("yjcm2015.xingxuelist",s)

    return "@XingxueCard=.->"..(table.concat(s,"+"))
end

-- 兴学剩下的部分大家想象吧，我懒得想
-- sgs.ai_skill_discard.xingxue = function(self) end

sgs.ai_skill_invoke.qiaoshi = true

local yanyu_skill = {name = "yjyanyu"}
register_fill(yanyu_skill)
yanyu_skill.getTurnUseCard = function(self)
    return authored(self,"@YjYanyuCard=.")
end

sgs.ai_skill_use_func.YjYanyuCard = function(card,use,self)
    local n = call(self.player,"getMark","yjyanyu")

    if n>=2 then return nil end

    local ns,fs,ts = {},{},{}
    for _,c in sgs.qlist(call(self.player,"getHandcards"))do
        if call(c,"isKindOf","Slash") then
            n = n+1
            if (call(c,"isKindOf","FireSlash")) then
                table.insert(fs,c)
            elseif (call(c,"isKindOf","ThunderSlash")) then
                table.insert(ts,c)
            else
                table.insert(ns,c)
            end
        end
    end

    if n<2 then return nil end

    local hasmale = false
    for _,p in ipairs(self.friends_noself)do
        if call(p,"isMale") then
            hasmale = true
            break
        end
    end

    if not hasmale then return nil end

    local id = -1
    if #ns>0 then
        id = call(ns[1],"getEffectiveId")
    elseif #ts>0 then
        id = call(ts[1],"getEffectiveId")
    elseif #fs>0 then
        id  = call(fs[1],"getEffectiveId")
    end

    if id<0 then return nil end

    use.card = authored(self,"@YjYanyuCard="..id)
end

sgs.ai_skill_playerchosen.yjyanyu = function(self)

    sort_players(self,self.friends_noself,"handcard")

    for i = #self.friends_noself,1,-1 do
        if call(self.friends_noself[i],"isMale") then
            return self.friends_noself[i]
        end
    end

    return nil
end

sgs.ai_use_priority.YjYanyuCard = sgs.ai_use_priority.Slash-0.01


local wurong_skill = {name = "wurong"}
register_fill(wurong_skill)
wurong_skill.getTurnUseCard = function(self)
    if call(self.player,"isKongcheng") then
        return nil
    end
    return authored(self,"@WurongCard=.")
end

sgs.ai_skill_use_func.WurongCard = function(card,use,self)
    local handcards = call(self.player,"getHandcards")
    local my_slashes,my_cards = {},{}
    for _,c in sgs.qlist(handcards)do
        if call(c,"isKindOf","Slash") then
            table.insert(my_slashes,c)
        else
            table.insert(my_cards,c)
        end
    end
    local no_slash = ( #my_slashes==0 )
    local all_slash = ( #my_cards==0 )
    local need_slash,target = nil,nil

    --自己展示的一定不是【杀】，目标展示的必须是【闪】，方可获得目标一张牌
    if no_slash then
        local others = call(self.room,"getOtherPlayers",self.player)
        local targets = self:findPlayerToDiscard("he",false,false,others)
        for _,p in ipairs(targets)do
            if not call(p,"isKongcheng") then
                local knowns,unknowns = known_hand(self,p)
                if unknowns==0 then
                    local all_jink = true
                    for _,jink in ipairs(knowns)do
                        if not call(jink,"isKindOf","Jink") then
                            all_jink = false
                            break
                        end
                    end
                    if all_jink then
                        need_slash,target = false,p
                        break
                    end
                end
            end
        end
    end

    --自己展示的一定是【杀】，目标展示的不是【闪】时，可对目标造成1点伤害
    if all_slash and not target then
        local targets = self:findPlayerToDamage(1,self.player,"N",nil,5)
        for _,p in ipairs(targets)do
            if not call(p,"isKongcheng") then
                local knowns,unknowns = known_hand(self,p)
                if self:isFriend(p) then
                    local all_jink = true
                    if unknowns==0 then
                        for _,c in ipairs(knowns)do
                            if not call(c,"isKindOf","Jink") then
                                all_jink = false
                                break
                            end
                        end
                    else
                        all_jink = false --队友会配合不展示【闪】的
                    end
                    if not all_jink then
                        need_slash,target = true,p
                        break
                    end
                else
                    local all_jink = false
                    if unknowns==0 then
                        for _,c in ipairs(knowns)do
                            if call(c,"isKindOf","Jink") then
                                all_jink = true
                                break
                            end
                        end
                    end
                    if not all_jink then
                        need_slash,target = true,p
                        break
                    end
                end
            end
        end
    end

    --自己展示的不一定是【杀】，可根据目标情况决定展示的牌
    if not target then
        local friends,enemies,others = {},{},{}
        for _,p in sgs.qlist(call(self.room,"getOtherPlayers",self.player))do
            if not call(p,"isKongcheng") then
                if self:isFriend(p) then
                    table.insert(friends,p)
                elseif self:isEnemy(p) then
                    table.insert(enemies,p)
                else
                    table.insert(others,p)
                end
            end
        end

        local to_damage = self:findPlayerToDamage(1,self.player,"N",enemies,5)
        for _,enemy in ipairs(to_damage)do
            local knowns,unknowns = known_hand(self,enemy)
            local no_jink = true
            if unknowns==0 then
                for _,jink in ipairs(knowns)do
                    if call(jink,"isKindOf","Jink") then
                        no_jink = false
                        break
                    end
                end
            else
                no_jink = false
            end
            if no_jink then
                need_slash,target = true,enemy
                break
            end
        end

        if not target then
            local other_players = call(self.room,"getOtherPlayers",self.player)
            local to_obtain = self:findPlayerToDiscard("he",false,false,other_players)
            for _,p in ipairs(to_obtain)do
                if not call(p,"isKongcheng") then
                    local knowns,unknowns = known_hand(self,p)
                    if self:isFriend(p) then
                        local has_jink = false
                        for _,jink in ipairs(knowns)do
                            if call(jink,"isKindOf","Jink") then
                                has_jink = true
                                break
                            end
                        end
                        if has_jink then
                            need_slash,target = false,p
                            break
                        end
                    else
                        local all_jink = true
                        if unknowns==0 then
                            for _,c in ipairs(knowns)do
                                if not call(c,"isKindOf","Jink") then
                                    all_jink = false
                                    break
                                end
                            end
                        else
                            all_jink = false
                        end
                        if all_jink then
                            need_slash,target = false,p
                            break
                        end
                    end
                end
            end
        end

        if not target then
            to_damage = self:findPlayerToDamage(1,self.player,"N",friends,25)
            for _,friend in ipairs(to_damage)do
                local knowns,unknowns = known_hand(self,friend)
                local all_jink = true
                for _,c in ipairs(knowns)do
                    if not call(c,"isKindOf","Jink") then
                        all_jink = false
                        break
                    end
                end
                if not all_jink then
                    need_slash,target = true,friend
                    break
                end
            end
        end

        if not target then
            local victim = self:findPlayerToDamage(1,self.player,"N",others,5)[1]
            if victim then
                need_slash,target = true,victim
            end
        end

        --只是为了看牌……
        if not target and #my_cards>0 and self:getOverflow()>0 then
            if #enemies>0 then
                sort_players(self,enemies,"handcard")
                need_slash,target = false,enemies[1]
            elseif #others>0 then
                sort_players(self,others,"threat")
                need_slash,target = false,others[1]
            end
        end

        if not target and #enemies>0 then
            sort_players(self,enemies,"defense",true)
            need_slash,target = (math.random(0,1)==0),enemies[1]
        end
    end

    if target and not call(target,"isKongcheng") and target~=self.player then
        local use_cards = need_slash and my_slashes or my_cards
        if #use_cards>0 then
            sort_use(self,use_cards,true)
            use.card = authored(self,"@WurongCard="..call(use_cards[1],"getEffectiveId"))
            use.to:append(target)
        end
    end
end
sgs.ai_use_priority["WurongCard"] = 3.1
sgs.ai_use_value["WurongCard"] = 4.5

-- sgs.ai_skill_discard.wurong = function(self) end

sgs.ai_guhuo_card.huomo = function(self,toname,class_name)
    local cards = call(self.player,"getCards","he")
    cards = sort_keep(self,cards) -- 按保留值排序
   	for d,c in sgs.list(cards)do
       	d = evaluation(self,toname)
        if call(c,"isBlack") and call(c,"getTypeId")~=1
		and call(self.player,"getMark","Huomo_"..call(d,"getClassName"))<1
       	and call(d,"isKindOf","BasicCard") and self:getCardsNum(class_name)<1
		and self.request.reason==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
      	then return "@HuomoCard="..call(c,"getEffectiveId")..":"..toname end
   	end
end

local huomo_skill = {name = "huomo"}
register_fill(huomo_skill)
huomo_skill.getTurnUseCard = function(self)
    local handcards = call(self.player,"getCards","he")
	handcards = sort_keep(self,handcards)
    for _,h in sgs.list(handcards)do
        if call(h,"isBlack") and call(h,"getTypeId")~=1
		then
			for dc,pn in sgs.list(pattern_names(self))do
				dc = pattern_card(self,pn)
				if dc and call(dc,"isKindOf","BasicCard")
				and self:getCardsNum(call(dc,"getClassName"))<1
				then
					local cn = call(dc,"getClassName")
					if call(dc,"isKindOf","Slash") then cn = "Slash" end
					if call(self.player,"getMark","Huomo_"..cn)>0
					then continue end
					cn = evaluation(self,pn)
					if cn and call(cn,"isAvailable",self.player)
					then
						cn=known(self:evaluateSkillCard("huomo",pn,{}),"Huomo pure zero-material declaration evaluation")
						dc = self:aiUseCard(cn)
						if dc.card and dc.to
						then
							self.huomo_to = dc.to
							self:setPriorityValue("HuomoCard",known(sgs.ai_use_priority[call(dc.card,"getClassName")],"Huomo source priority")-0.3,"huomo")
							return authored(self,"@HuomoCard="..call(h,"getEffectiveId")..":"..pn)
						end
					end
				end
			end
        end
    end
end

sgs.ai_skill_use_func.HuomoCard = function(card,use,self)
   if self.huomo_to
	then
		use.card = card
		use.to = self.huomo_to
    end
end

sgs.ai_use_value["HuomoCard"] = 2.7
sgs.ai_use_priority["HuomoCard"] = 3.5

sgs.ai_skill_playerchosen.zuoding = function(self,targets)
    local l = {}
    for _,p in sgs.qlist(targets)do
        if table.contains(self.friends,p,true) then
            table.insert(l,p)
        end
    end

    if #l==0 then return nil end

    sort_players(self,l,"defense")
    return l[#l]
end

local anguo_skill = {name = "anguo"}
register_fill(anguo_skill)
anguo_skill.getTurnUseCard = function(self)
    return authored(self,"@AnguoCard=.")
end

sgs.ai_skill_use_func.AnguoCard = function(card,use,self)
    local l = {}
    local function calculateMinus(player,range)
        if range<=0 then return 0 end
        local n = 0
        for _,p in sgs.qlist(call(self.room,"getAlivePlayers"))do
            if public_range(self,player,p,0) and not public_range(self,player,p,range) then n = n+1 end
        end
        return n
    end

    local function filluse(to,id)
        use.card = card
        if (use.to) then use.to:append(to) end
        self:setStrategyMemory("yjcm2015.anguoid",id)
    end

    for _,p in ipairs(self.enemies)do
        if (p:getWeapon()) then
            local weaponrange = known(p:getWeapon():getRange(),"weapon range")
            local n = calculateMinus(p,weaponrange-1)
            table.insert(l,{player = p,id = p:getWeapon():getEffectiveId(),minus = n})
        end
        if (p:getOffensiveHorse()) then
            local n = calculateMinus(p,1)
            table.insert(l,{player = p,id = p:getOffensiveHorse():getEffectiveId(),minus = n})
        end
    end

    if #l>0 then
        local function sortByMinus(a,b)
            return a.minus>b.minus
        end

        table.sort(l,sortByMinus)
        if l[1].minus>0 then
            filluse(l[1].player,l[1].id)
            return
        end
    end

    for _,p in ipairs(self.enemies)do
        if (p:getTreasure()) then
            filluse(p,p:getTreasure():getEffectiveId())
            return
        end
    end

    for _,p in ipairs(self.friends_noself)do
        if (self:needToThrowArmor(p) and p:getArmor()) then
            filluse(p,p:getArmor():getEffectiveId())
            return
        end
    end

    sort_players(self,self.enemies,"threat")
    for _,p in ipairs(self.enemies)do
        if (p:getArmor() and not p:getArmor():isKindOf("GaleShell")) then
            filluse(p,p:getArmor():getEffectiveId())
            return
        end
    end

    for _,p in ipairs(self.enemies)do
        if (p:getDefensiveHorse()) then
            filluse(p,p:getDefensiveHorse():getEffectiveId())
            return
        end
    end
end

sgs.ai_use_priority.AnguoCard = sgs.ai_use_priority.ExNihilo+0.01

sgs.ai_skill_cardchosen.anguo = function(self)
    return self:getStrategyMemory("yjcm2015.anguoid")
end

--OL诏缚
function SmartAIView:zhaofuSort()
	local func = function(a,b)
		local a1,b1 = 0,0
		for _,p in ipairs(self.friends)do
			if not public_range(self,p,a,0) and call(a,"getKingdom")=="wu" then --and canSlash
				a1 = a1+1
			end
		end
		for _,p in ipairs(self.friends)do
			if not public_range(self,p,b,0) and call(b,"getKingdom")=="wu" then
				b1 = b1+1
			end
		end
		if a1==b1 then
			if self:getDefenseSlash(a)>self:getDefenseSlash(b) then
				a1 = a1-1
			end
		end
		return a1>b1
	end
	table.sort(self.enemies,func)
end

local olzhaofu_skill = {}
olzhaofu_skill.name = "olzhaofu"
register_fill(olzhaofu_skill)
olzhaofu_skill.getTurnUseCard = function(self)
	if not call(self.player,"hasLordSkill","olzhaofu") or call(self.player,"getMark","@olzhaofuMark")<=0 then return end
	if #self.enemies<=0 then return end
	return authored(self,"@OLzhaofuCard=.")
end

sgs.ai_skill_use_func.OLzhaofuCard = function(card,use,self)
	self:zhaofuSort()

	local targets = {}
	for _,e in ipairs(self.enemies)do
		if #targets>=2 then break end
		local to
		for _,f in ipairs(self.friends)do
			if not public_range(self,f,e,0) and call(f,"getKingdom")=="wu" then
				to = e
				break
			end
		end
		if to then
			table.insert(targets,to)
		end
	end

	if #targets<=0 then return end

	use.card = card

	for i = 1,2 do
		if #targets<i then break end
		use.to:append(targets[i])
	end
end

sgs.ai_card_intention.OLzhaofuCard = 80

sgs.ai_use_priority.OLzhaofuCard = 10
sgs.ai_use_value.OLzhaofuCard = 3

sgs.ai_skill_playerchosen.yaoming = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	sort_players(self,destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and call(target,"getHandcardNum")<call(self.player,"getHandcardNum")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and call(target,"getHandcardNum")>call(self.player,"getHandcardNum")
		then return target end
	end
end



-- Seed cost selection remains in the original use function. Only its accepted
-- use is replaced by a native receipt, never an evaluation-only seed.
for class,skill in pairs(classes)do
    local fn=sgs.ai_skill_use_func[class]
    if type(fn)=="function"then sgs.ai_skill_use_func[class]=function(card,use,self)
        fn(card,use,self)
        if use.card and type(use.card.isStrategySeed)=="function"and use.card:isStrategySeed()then
            use.card=policy_card(self,class,{},nil)
        end
    end end
end
for _,name in ipairs{"@@huaiyi","@@xingxue"}do
    local fn=sgs.ai_skill_use[name]
    sgs.ai_skill_use[name]=function(self,...)
        local result=fn(self,...)
        if not result or result=="."then return {kind="pass"}end
        local text,names=result:match("^(.-)%->(.*)$");if not text then ai_unsupported("invalid source target proposal",name)end
        local use=AIUsePlan.new();use.card=authored(self,text,true)
        for target in names:gmatch("[^+]+")do use.to:append(known(self.room:findPlayerByObjectName(target),"response target"))end
        return use:toAnswer()
    end
end
-- Guhuo callbacks propose exact source-selected cost/declaration. The common
-- response resolver issues authority and preserves separate legacy metadata.
for name,class in pairs{qinwang="QinwangCard",zhenshan="ZhenshanCard",huomo="HuomoCard"}do
    local fn=sgs.ai_guhuo_card[name]
    sgs.ai_guhuo_card[name]=function(self,...)
        local value=fn(self,...);if not value then return nil end
        local ids,declaration=value:match("^@"..class.."=([^:]*):(.*)$")
        if not ids then ai_unsupported("malformed source response proposal",name)end
        local costs={};if ids~="."then for id in ids:gmatch("[^+]+")do costs[#costs+1]=tonumber(id)end end
        return {skill=name,legacy_class=class,subcards=costs,user_string=declaration}
    end
end
