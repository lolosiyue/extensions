-- Standard generals. Fixed donor: b6025acc ai/standard-ai.lua.
-- Callback state belongs to this viewer's observational memory; actions always
-- bind native source scopes and retain their original receipts.
for _,name in ipairs{"skillInvoke","skillChoice","cardChosen","cardResponded","cardUsed","playerChosen"}do
    sgs.ai_choicemade_filter[name]=sgs.ai_choicemade_filter[name]or{}
end
local standard_initial_aliases={}
standard_initial_aliases["sgs.ai_use_value.LijianCard"]=sgs.ai_use_value.LijianCard
standard_initial_aliases["sgs.ai_use_priority.LijianCard"]=sgs.ai_use_priority.LijianCard
standard_initial_aliases["sgs.ai_card_intention.LijianCard"]=sgs.ai_card_intention.LijianCard
standard_initial_aliases["sgs.ai_use_value.RendeCard"]=sgs.ai_use_value.RendeCard
standard_initial_aliases["sgs.ai_use_priority.RendeCard"]=sgs.ai_use_priority.RendeCard
standard_initial_aliases["sgs.ai_card_intention.RendeCard"]=sgs.ai_card_intention.RendeCard
standard_initial_aliases["sgs.xiaoji_keep_value"]=sgs.xiaoji_keep_value

local function known(value,key)
    if value==nil then ai_unsupported("standard general fact is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("standard general method is missing",method) end
    return known(object[method](object,...),method)
end
local function dummy(is_dummy,extra,current)
    local use=AIUsePlan.new();use.isDummy=is_dummy~=false;use.extra_target=extra or 0;use.current_targets=current or {};return use
end
local function source_player(self,key)
    local name,present=self:getStrategyMemory("response_source:"..key)
    if not present or not name then return nil end
    if type(name)~="string" then ai_unsupported("invalid standard response-source cache",key) end
    return known(self.room:findPlayerByObjectName(name,true),key)
end
local function remember_source(self,key,player)
    self:setStrategyMemory("response_source:"..key,player and call(player,"objectName") or nil)
end
local function visible_card(self,id)
    id=tonumber(id)
    return known(self:getChoiceCard(id) or self:getKnownCardById(id),"disclosed card "..tostring(id))
end
local function player_name(self,name,key)
    if name==false or name=="" then return nil end
    return known(self.room:findPlayerByObjectName(known(name,key),true),key)
end
-- A struct-valued own tag arrives as a plain row; wrap its player names and card.
local function tag_event(self,key)
    local row=self.player:getTag(key)
    if type(row)~="table" then ai_unsupported("standard event is absent",key) end
    local value={};for k,v in pairs(row)do value[k]=v end
    for _,k in ipairs{"from","to","who"}do
        if type(value[k])=="string" then value[k]=player_name(self,value[k],key.."."..k) end
    end
    if type(value.to)=="table"then
        local targets=AIList.new({});for _,name in ipairs(value.to)do targets[#targets+1]=player_name(self,name,key..".to")end;value.to=targets
    end
    if value.card then value.card=known(CardView.new(value.card),key..".card") end
    if value.amount~=nil then value.damage=value.amount end
    return value
end
-- CurrentDamageStruct reaches only a decision's context; an event-only view has none.
local function current_damage(self)
    return known(self:getDecisionContext().damage,"current damage")
end
local function current_role(self,player)
    return player==self.player and call(player,"getRole") or call(self,"getRoleEstimate",player)
end
local function turncount(self)return known(self.world.turn_count,"turn count")end

-- A face-dependent foreign-hand policy uses only disclosed faces. The omitted
-- unknown faces are an explicit viewer estimate, never synthetic cards or IDs.
local function strategy_cards(self,player,flags)
    self=self or player._room and player._room._ai
    if not self then ai_unsupported("card policy has no viewing AI","standard cards") end
    local complete=player:getCards(flags)
    if complete then return complete end
    if player==self.player then ai_unsupported("owner card domain is unknown",flags) end
    local result=AIList.new({})
    if flags:find("h",1,true) then
        local cards=call(player,"getKnownCards")
        for _,card in ipairs(cards)do result[#result+1]=card end
        self:useKnowledgeEstimate({value=#cards,status="estimate",basis="disclosed_faces_only_unknown_faces_omitted",
            known_count=#cards,hidden_count=math.max(0,call(player,"getHandcardNum")-#cards),
            viewer=call(self.player,"objectName"),observer=call(player,"objectName")},"standard.foreign_hand_policy")
    end
    for _,zone in ipairs{{"e","getEquips"},{"j","getJudgingArea"}}do
        if flags:find(zone[1],1,true)then for _,card in ipairs(call(player,zone[2]))do result[#result+1]=card end end
    end
    return result
end

local function general_info(ai,name)
    local catalog=ai.request and ai.request.options and ai.request.options.context and ai.request.options.context.general_catalog
    local row=known(catalog and catalog[name],"public general catalog "..name)
    if not known(row.exists,"general existence")then return nil end
    return {getKingdom=function()return known(row.kingdom,"general kingdom")end,
        getMaxHp=function()return known(row.max_hp,"general max HP")end,
        getSkillDescription=function()return known(row.skill_description,"general skill description")end}
end

local function chained_count(self)
    local count,present=self:getEventMemory("is_chained")
    if present then return known(count,"observed chain count")end
    return self:useKnowledgeEstimate({value=0,status="estimate",basis="late_observer_chain_count_zero_prior"},"standard.is_chained")
end

local skill_classes={ExtraCollateralCard="nosmieji",NosJujianCard="nosjujian",NosXuanhuoCard="nosxuanhuo",NosLijianCard="noslijian",
    NosRendeCard="nosrende",NosFenchengCard="nosfencheng",NosKurouCard="noskurou",NosFanjianCard="nosfanjian",
    QingnangCard="qingnang",JijiangCard="jijiang",YijueCard="yijue",ZhihengCard="zhiheng",KurouCard="kurou",
    FanjianCard="fanjian",GuoseCard="guose",JieyinCard="jieyin",ChuliCard="chuli",LijianCard="lijian",JianyanCard="jianyan",
    NosTuxiCard="nostuxi",TuxiCard="tuxi",YijiCard="yiji",LianyingCard="lianying",LiuliCard="liuli",FenweiCard="fenwei"}
local function skill_card(self,class,costs,request)
    local skill=known(skill_classes[class],"standard authored skill class "..class)
    local authority=call(self,"bindSkillCard",skill,costs,request)
    local suit,number=sgs.Card_NoSuit,0
    if #costs==1 then local c=visible_card(self,costs[1]);suit,number=call(c,"getSuit"),call(c,"getNumber")
    elseif #costs>1 then local red,black=true,true
        for _,id in ipairs(costs)do local c=visible_card(self,id);red=red and call(c,"isRed");black=black and call(c,"isBlack")end
        suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
    end
    local suits={[sgs.Card_Spade]="spade",[sgs.Card_Club]="club",[sgs.Card_Heart]="heart",[sgs.Card_Diamond]="diamond",
        [sgs.Card_NoSuit]="no_suit",[sgs.Card_NoSuitRed]="no_suit_red",[sgs.Card_NoSuitBlack]="no_suit_black"}
    local rank=number>13 and "JOKER"or ({[1]="A",[11]="J",[12]="Q",[13]="K"})[number]or tostring(number)
    local no_throw=class=="NosRendeCard"or class=="FanjianCard"or class=="NosXuanhuoCard"
    -- Card::Parse derives this empty constructor skill name from its class.
    -- The native payment authority remains the actual nosmieji scope.
    local policy_skill=class=="ExtraCollateralCard"and "extracollateral"or skill
    return call(self,"legacyPolicyCard",authority,{name="",class_name=class,type_id=0,kind_of={class,"SkillCard","Card"},
        suit=suit,number=number,subcards=costs,effective_id=costs[1],skill_name=policy_skill,skill_names={policy_skill},
        legacy_string_key="@"..class.."["..known(suits[suit],"skill suit")..":"..rank.."]="..(#costs>0 and table.concat(costs,"+")or"."),
        will_throw=not no_throw,handling_method=(no_throw or class=="GuoseCard")and sgs.Card_MethodNone or sgs.Card_MethodDiscard,
        damage_card=false,can_recast=false,red=suit==sgs.Card_Heart or suit==sgs.Card_Diamond or suit==sgs.Card_NoSuitRed,
        black=suit==sgs.Card_Spade or suit==sgs.Card_Club or suit==sgs.Card_NoSuitBlack})
end
-- This private authored proposal is converted to scalar costs before a native
-- scope is queried. No string is accepted as an action or engine parse fallback.
local function selected_skill(self,text,request)
    local class,encoded=text:match("^@([%w_]+)=(.*)$")
    if not class or not skill_classes[class]then ai_unsupported("invalid authored standard skill choice",text)end
    local costs={}
    if encoded~="."then for id in encoded:gmatch("[^+]+")do
        local value=tonumber(id);if not value or value<0 or value%1~=0 then ai_unsupported("invalid authored skill cost",id)end
        costs[#costs+1]=value
    end end
    return skill_card(self,class,costs,request)
end
local function skill_seed(self,skill,class,request)return call(self,"legacySkillSeed",skill,class,request)end
local function rende_card(self,ids,request)return call(self,"bindSkillCard","rende",ids or{},request)end
local function answer_skill(self,card,targets)
    local use=AIUsePlan.new();use.card=card
    for _,p in ipairs(targets or{})do if type(p)=="string"then p=player_name(self,p,"skill target")end;use.to:append(p)end
    return use:toAnswer()
end

local getNosFenchengValue,getKurouCard,getFenweiValue,getPriorFriendsOfLiyu

local function response_choice(self,value)
    if value==nil or value=="."then return {kind="pass"}end
    if type(value)~="string"then return value end
    local declaration,names=value:match("^(.-)%->(.*)$")
    if not declaration then declaration=value;names=""end
    local targets={};for name in names:gmatch("[^+]+")do targets[#targets+1]=name end
    return answer_skill(self,selected_skill(self,declaration),targets)
end
local function observed_mark(self,player,name)
    local value,present=self:getStrategyMemory("standard_mark:"..call(player,"objectName")..":"..name)
    if present then return value end
    return call(player,"getStrategyMark",name)
end
local function strategy_mark(self,player,name,value)
    self:setStrategyMemory("standard_mark:"..call(player,"objectName")..":"..name,value)
end

local function yiji_cards(self,index)
    local cards,present=self:getStrategyMemory("yijicards"..index)
    return present and known(cards,"Yiji cost queue")or {}
end

local function material_spec(card,skill,name,printed)
    return {name=name,skill=skill,suit=call(card,"getSuit"),
        number=call(card,"getNumber"),subcards={call(card,"getEffectiveId")}}
end
local function material_conversion(self,card,skill,name,class,printed,request)
    return call(self,"bindTurnConversion",skill,class,material_spec(card,skill,name,printed),request)
end

local function nosguhuo_play_count(self,name)
    local marks,present=self:getStrategyMemory("standard.nosguhuo_play_marks")
    return call(self.player,"getStrategyMark",name.."-PlayClear")+(present and marks[name]or 0)
end
local function nosguhuo_proposal(card,name)
    local spec=material_spec(card,"nosguhuo",name,true);spec.user_string=name;return spec
end
local function nosguhuo_filled(self,proposal,request)
    local costs=proposal.subcards
    local receipt=call(self,"bindSkillCard","nosguhuo",costs,request,proposal.name)
    local material=visible_card(self,costs[1])
    -- Exact legacy SkillCard identity is separate from the native result card.
    local seed=call(self,"legacySkillSeed","nosguhuo","NosGuhuoCard",request)
    local policy={name=call(seed,"objectName"),class_name="NosGuhuoCard",type_id=0,kind_of={"NosGuhuoCard","SkillCard","Card"},
        suit=call(material,"getSuit"),number=call(material,"getNumber"),effective_id=costs[1],subcards=costs,
        legacy_string_key="@NosGuhuoCard["..call(material,"getSuitString")..":"..call(material,"getNumberString").."]="..costs[1]..":"..proposal.name,skill_name=call(seed,"getSkillName"),
        skill_names=call(seed,"getSkillNames"),will_throw=call(seed,"willThrow"),handling_method=call(seed,"getHandlingMethod"),
        damage_card=false,can_recast=false}
    local card=call(self,"legacyPolicyCard",receipt,policy)
    self._standard_nosguhuo_declaration=proposal.name
    return card
end

local function response_skill_proposal(skill,class,costs)
    return {skill=skill,legacy_class=class,subcards=costs or{}}
end

sgs.ai_skill_invoke.jianxiong=function(self,data)
    local remembered,present=self:getStrategyMemory("jianxiong")
    if self.jianxiong or present and remembered then
        self.jianxiong=nil;self:setStrategyMemory("jianxiong",nil);return true
    end
    return not call(self,"needKongcheng",self.player,true)
end
sgs.ai_skill_choice.jianxiong=function(self,choices,data)
    local damage=known(data:toDamage(),"jianxiong damage")
    if not damage.card then return "draw" end
    if call(damage.card,"isKindOf","Slash") and not call(self,"hasCrossbowEffect") and call(self,"getCardsNum","Slash")>0 then return "draw" end
    if call(self,"isWeak") and (call(self,"getCardsNum","Slash")>0 or not call(damage.card,"isKindOf","Slash")
        or call(self.player,"getHandcardNum")<=call(self.player,"getHp")) then return "draw" end
    return "obtain"
end
sgs.ai_skill_invoke.hujia=function(self,data)
    if source_player(self,"hujiasource") then return false end
    for _,friend in ipairs(self.friends_noself)do
        if call(friend,"getKingdom")=="wei" and call(self,"hasEightDiagramEffect",friend) then return true end
    end
    local current=self.room:getCurrent()
    if self:isFriend(current) and call(current,"getKingdom")=="wei" and call(self,"getOverflow",current)>2 then return true end
    for _,card in ipairs(call(self.player,"getHandcards"))do if isCard("Jink",card,self.player) then return false end end
    for _,player in ipairs(call(self.room,"getLieges","wei",self.player))do
        if call(self,"isFriend",player) or current_role(self,player)=="neutral" then return true end
    end
end
sgs.ai_choicemade_filter.skillInvoke.hujia=function(self,player,promptlist)
    if promptlist[#promptlist]=="yes" then remember_source(self,"hujiasource",player) end
end
sgs.ai_slash_prohibit.hujia=function(self,from,to)
    if call(self,"isFriend",to,from) then return false end
    local guojia=self.room:findPlayerBySkillName("tiandu")
    if guojia and call(guojia,"getKingdom")=="wei" and call(self,"isFriend",to,guojia) then
        return known(sgs.ai_slash_prohibit.tiandu,"tiandu policy")(self,from,guojia)
    end
end
sgs.ai_choicemade_filter.cardResponded["@hujia-jink"]=function(self,player,promptlist)
    local source=source_player(self,"hujiasource")
    if promptlist[#promptlist]~="" then
        sgs.updateIntention(player,source,-80)
        remember_source(self,"hujiasource",nil)
    elseif source then
        local lieges=call(self.room,"getLieges","wei",source)
        if #lieges>0 and call(player,"objectName")==call(lieges[#lieges],"objectName") then remember_source(self,"hujiasource",nil) end
    end
end
sgs.ai_skill_cardask["@hujia-jink"]=function(self)
    local lord=self.room:getLord()
    if not lord then return "." end
    local source=source_player(self,"hujiasource")
    local yuanshu=self.room:findPlayerBySkillName("weidi")
    if not source and not yuanshu then source=lord;remember_source(self,"hujiasource",source) end
    if not source or not call(self,"isFriend",source) or call(self,"needBear") then return "." end
    local dahe=self.room:findPlayerBySkillName("dahe")
    if dahe and call(dahe,"isAlive") and call(source,"getStrategyFlag","dahe") then
        for _,card in ipairs(call(self,"getCards","Jink"))do
            if call(card,"getSuit")==sgs.Card_Heart then return card end
        end
        return "."
    end
    return self:getCard("Jink") or "."
end

-- Additional source callbacks (same legacy callback ABI, pure value inputs).
sgs.ai_skill_cardask["@nosenyuan-heart"] = function(self,data)
    local damage = data:toDamage()
    if self:needToLoseHp(self.player,damage.to,damage.card,true) and not call(self,"hasSkills",sgs.masochism_skill) then return "." end
    if self:isFriend(damage.to) then return end
    if self:needToLoseHp(nil,nil,damage.card) and not call(self,"hasSkills",sgs.masochism_skill) then return "." end

    local cards = strategy_cards(self,self.player,"h")
    for _,card in sgs.qlist(cards)do
        if call(card,"getSuit")==sgs.Card_Heart and not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) then
            return call(card,"getEffectiveId")
        end
    end
    return "."
end


function sgs.ai_slash_prohibit.nosenyuan(self,from,to,card)
    if call(from,"hasSkill","jueqing") then return false end
    if call(from,"hasSkill","nosqianxi") and call(from,"distanceTo",to)==1 then return false end
    if call(from,"getStrategyFlag","NosJiefanUsed") then return false end
    if self:needToLoseHp(from) and not call(self,"hasSkills",sgs.masochism_skill,from) then return false end
    if call(from,"getHp")>3 then return false end

    local role = call(from,"objectName")==call(self.player,"objectName") and current_role(self,from) or current_role(self,from)
    if (role=="loyalist" or role=="lord") and call(self,"getRoleCounts").rebel+call(self,"getRoleCounts").renegade==1
        and call(to,"getHp")==1 and getCardsNum("Peach",to,self.player)<1 and getCardsNum("Analeptic",to,self.player)<1
        and (call(from,"getHp")>1 or getCardsNum("Peach",from,self.player)>=1 and getCardsNum("Analeptic",from,self.player)>=1) then
        return false
    end
    if role=="rebel" and isLord(to) and self:getAllPeachNum(player)<1 and call(to,"getHp")==1
        and (call(from,"getHp")>1 or getCardsNum("Peach",from,self.player)>=1 and getCardsNum("Analeptic",from,self.player)>=1) then
        return false
    end
    if role=="renegade" and call(from,"aliveCount")==2 and call(to,"getHp")==1 and getCardsNum("Peach",to,self.player)<1 and getCardsNum("Analeptic",to,self.player)<1
        and (call(from,"getHp")>1 or getCardsNum("Peach",from,self.player)>=1 and getCardsNum("Analeptic",from,self.player)>=1) then
        return false
    end

    local n = 0
    local cards = strategy_cards(self,from,"h")
    for _,card in sgs.qlist(cards)do
        if call(card,"getSuit")==sgs.Card_Heart and not isCard("Peach",card,from) and not isCard("ExNihilo",card,from) then
            if not call(card,"isKindOf","Slash") then return false end
            n = n+1
        end
    end
    if n<1 then return true end
    if n>1 then return false end
    if n==1 then return call(card,"getSuit")==sgs.Card_Heart end
    return self:isWeak(from)
end


sgs.ai_need_damaged.nosenyuan = function (self,attacker,player)
    if attacker and self:isEnemy(attacker,player) and self:isWeak(attacker)
    and not call(attacker,"hasSkills",sgs.masochism_skill)
    then return not self:isWeak(player) end
    return false
end


sgs.ai_skill_playerchosen.nosxuanhuo = function(self,targets)
    for _,player in sgs.qlist(targets)do
        if (call(player,"getHandcardNum")<=2 or call(player,"getHp")<2) and self:isFriend(player)
            and not call(player,"getStrategyFlag","AI_NosXuanhuoTarget") and not self:needKongcheng(player,true) and not call(player,"hasSkill","manjuan") then
            return player
        end
    end
    for _,player in sgs.qlist(targets)do
        if self:isFriend(player)
            and not call(player,"getStrategyFlag","AI_NosXuanhuoTarget") and not self:needKongcheng(player,true) and not call(player,"hasSkill","manjuan") then
            return player
        end
    end
    for _,player in sgs.qlist(targets)do
        if player==self.player then
            return player
        end
    end
end


sgs.ai_cardneed.nosxuanhuo = function(to,card)
    return call(card,"getSuit")==sgs.Card_Heart
end


sgs.ai_skill_choice.nosxuanfeng = function(self,choices)
    self.enemies = self:sort(self.enemies,"defenseSlash")
    local slash = call(self,"getEvaluationCard","slash")
    for _,enemy in ipairs(self.enemies)do
        if call(self.player,"distanceTo",enemy)<=1
        then return "damage"
        elseif not self:slashProhibit(slash,enemy)
        and self:isGoodTarget(enemy,self.enemies,slash)
        then return "slash" end
        end
    return "nothing"
end


function sgs.ai_cardneed.nosgongqi(to,card,self)
    return call(card,"getTypeId")==sgs.Card_TypeEquip and getKnownCard(to,self.player,"EquipCard",true)==0
end


function sgs.ai_cardneed.nosjiefan(to,card,self)
    return isCard("Slash",card,to) and getKnownCard(to,self.player,"Slash",true)==0
end


sgs.ai_skill_invoke.nosfuhun = function(self,data)
    local target = 0
    for _,enemy in ipairs(self.enemies)do
        if call(self.player,"distanceTo",enemy)<=call(self.player,"getAttackRange")
        then target = target+1 end
    end
    return target>0 and not call(self.player,"isSkipped",sgs.Player_Play)
end


sgs.ai_skill_invoke.noszhenlie = function(self,data)
    local judge = data:toJudge()
    if not judge:isGood() then
    return true end
    return false
end


sgs.ai_skill_playerchosen.nosmiji = function(self,targets)
    targets = sgs.QList2Table(targets)
    targets = self:sort(targets,"defense")
    local n = call(self.player,"getLostHp")
    if call(self.player,"getPhase")==sgs.Player_Start then
        if call(self.player,"getHandcardNum")-n<2 and not self:needKongcheng() and not self:willSkipPlayPhase() then return self.player end
    elseif call(self.player,"getPhase")==sgs.Player_Finish then
        if call(self.player,"getHandcardNum")-n<2 and not self:needKongcheng() then return self.player end
    end
    local to = self:findPlayerToDraw(true,n)
    return to or self.player
end


sgs.ai_playerchosen_intention.nosmiji = function(self,from,to)
    if not (self:needKongcheng(to,true) and call(from,"getLostHp")==1)
        and not hasManjuanEffect(to) then
        sgs.updateIntention(from,to,-10)
    end
end


sgs.ai_skill_invoke.nosqianxi = function(self,data)
    local damage = data:toDamage()
    local target = damage.to
    if self:isFriend(target) then return false end
    if call(target,"getLostHp")>=2 and call(target,"getHp")<=1 then return false end
    if call(target,"hasSkills",sgs.masochism_skill.."|"..sgs.recover_skill.."|longhun|buqu|nosbuqu") then return true end
    if self:ajustDamage(self.player,target,1,damage.card)>1 then return false end
    return (call(target,"getMaxHp")-call(target,"getHp"))<2
end


function sgs.ai_cardneed.nosqianxi(to,card,self)
    return isCard("Slash",card,to) and getKnownCard(to,self.player,"Slash",true)==0
end


sgs.ai_use_revises.nosrende = function(self,card,use)
    if call(self.player,"getLostHp")>1 and self:findFriendsByType(sgs.Friend_Draw)
    and call(self.player,"getStrategyMark","nosrende")<2
    and #self.friends_noself>0
    then
        if call(card,"getTypeId")==1
        or call(card,"getTypeId")==3 and self:getSameEquip(card)
        or call(card,"getTypeId")==2 and not (card:targetFixed() and call(card,"isDamageCard"))
        then return false end
    end
    local xy = call(self,"hasSkills","jieming|oljieming",self.friends_noself)
    if xy and call(card,"isDamageCard") and self:getOverflow()<0
    and self:hasTrickEffective(card,xy,nil,use.to)
    and self:getAllPeachNum()>1
    then
        use.card = card
        use.to:append(xy)
    end
end


sgs.ai_skill_defense.nosrende = function(self, player)
    if call(player,"getHp")>2 and call(player,"getHandcardNum")>1 then
        return 1
    end
    return 0
end


function sgs.ai_cardneed.nosjizhi(to,card)
    return call(card,"isNDTrick")
end


function sgs.ai_skill_invoke.nosjushou(self,data)
    local sbdiaochan = self.room:findPlayerBySkillName("lihun")
    if sbdiaochan and call(sbdiaochan,"faceUp") and not self:willSkipPlayPhase(sbdiaochan)
        and (self:isEnemy(sbdiaochan) or (turncount(self)<=1 and current_role(self,sbdiaochan)=="neutral")) then return false end
    if not call(self.player,"faceUp") then return true end
    for _,friend in ipairs(self.friends)do
        if call(self,"hasSkills","fangzhu|jilve",friend) then return true end
        if call(friend,"faceUp") and call(friend,"hasSkill","junxing") and not self:willSkipPlayPhase(friend)
            and not (call(friend,"isKongcheng") and self:willSkipDrawPhase(friend)) then
            return true
        end
    end
    return self:isWeak()
end


sgs.ai_skill_askforag.nosbuqu = function(self,card_ids)
    for i,card_id in ipairs(card_ids)do
        for j,card_id2 in ipairs(card_ids)do
            if i~=j and visible_card(self,card_id):getNumber()==visible_card(self,card_id2):getNumber() then
                return card_id
            end
        end
    end

    return card_ids[1]
end


function sgs.ai_skill_invoke.nosbuqu(self,data)
    if #self.enemies==1 and call(self.enemies[1],"hasSkill","nosguhuo") then
        return false
    else
        local damage = data:toDamage()
        if call(self.player,"getHp")==1 and damage.to and known(damage.reason,"damage reason")=="duwu" and self:getSaveNum(true)>=1 then return false end
        return true
    end
end




sgs.ai_skill_playerchosen.nosleiji = function(self,targets)
    local mode = call(self.room,"getMode")
    if mode:find("_mini_17") or mode:find("_mini_19") or mode:find("_mini_20") or mode:find("_mini_26") then
        local players = targets
        for _,aplayer in sgs.qlist(players)do
            if call(aplayer,"getState")~="robot" then
                return aplayer
            end
        end
    end
    local target = self:findLeijiTarget(self.player,100,nil,-1)
    if target and targets:contains(target) then return target end
end


function sgs.ai_slash_prohibit.nosleiji(self,from,to,card)
    if self:isFriend(to,from) then return false end
    if call(to,"getStrategyFlag","QianxiTarget") and (not self:hasEightDiagramEffect(to) or call(self.player,"hasWeapon","QinggangSword")) then return false end
    local hcard = call(to,"getHandcardNum")
    if call(from,"hasSkill","liegong") and (hcard>=call(from,"getHp") or hcard<=call(from,"getAttackRange")) then return false end
    if call(from,"hasSkill","kofliegong") and hcard>=call(from,"getHp") then return false end
    if current_role(self,from)=="rebel" and call(to,"isLord") then
        local other_rebel
        for _,player in sgs.qlist(call(self.room,"getOtherPlayers",from))do
            if current_role(self,player)=="rebel" or self:compareRoleEvaluation(player,"rebel","loyalist")=="rebel" then
                other_rebel = player
                break
            end
        end
        if not other_rebel and ((call(from,"getHp")>=4 and (getCardsNum("Peach",from,self.player)>0 or call(from,"hasSkills","nosganglie|vsnosganglie"))) or call(from,"hasSkill","hongyan"))
        then return false end
        end

    if hcard>=4 or (hcard>=2 and self:hasSuit("spade",true,to)) or getKnownCard(to,from,"Jink",true)>=1 then return true end
    if self:hasEightDiagramEffect(to) then return true end
end


function sgs.ai_cardneed.nosguhuo(to,card)
    return call(card,"getSuit")==sgs.Card_Heart and (call(card,"isKindOf","BasicCard") or call(card,"isNDTrick"))
end



sgs.ai_skill_invoke.noszhuikong = function(self,data)
    if call(self.player,"getHandcardNum")<=(self:isWeak() and 2 or 1) then return false end
    local current = self.room:getCurrent()
    if not current or self:isFriend(current) then return false end

    local max_card = self:getMaxCard()
    local max_point = call(max_card,"getNumber")
    if call(self.player,"hasSkill","yingyang") then max_point = math.min(max_point+3,13) end
    if not (call(current,"hasSkill","zhiji") and call(current,"getStrategyMark","zhiji")==0 and call(current,"getHandcardNum")==1) and not
        (call(current,"hasSkill","mobilezhiji") and call(current,"getStrategyMark","mobilezhiji")==0 and call(current,"getHandcardNum")==1) then
        local enemy_max_card = self:getMaxCard(current)
        local enemy_max_point = enemy_max_card and call(enemy_max_card,"getNumber") or 100
        if enemy_max_card and call(current,"hasSkill","yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
        if max_point>enemy_max_point or max_point>10 then
            self.noszhuikong_card = call(max_card,"getEffectiveId");self:remember("noszhuikong_card",self.noszhuikong_card)
            return true
        end
    end
    if call(current,"distanceTo",self.player)==1 and not self:isValuableCard(max_card) then
        self.noszhuikong_card = call(max_card,"getEffectiveId");self:remember("noszhuikong_card",self.noszhuikong_card)
        return true
    end
    return false
end


sgs.ai_skill_playerchosen.nosqiuyuan = function(self,targets)
    local targetlist = sgs.QList2Table(targets)
    targetlist = self:sort(targetlist,"handcard")
    local enemy
    for _,p in ipairs(targetlist)do
        if self:isEnemy(p) and not (call(p,"getHandcardNum")==1 and (call(p,"hasSkill","kongcheng") or (call(p,"hasSkill","zhiji") and call(p,"getStrategyMark","zhiji")==0))) then
            if call(p,"hasSkills",sgs.cardneed_skill) then return p
            elseif not enemy and not self:canLiuli(p,self.friends_noself) then enemy = p end
        end
    end
    if enemy then return enemy end
    targetlist = sgs.reverse(targetlist)
    local friend
    for _,p in ipairs(targetlist)do
        if self:isFriend(p) then
            if (call(p,"hasSkill","kongcheng") and call(p,"getHandcardNum")==1) or (call(p,"getCardCount")>=2 and self:canLiuli(p,self.enemies)) then return p
            elseif not friend and getCardsNum("Jink",p,self.player)>=1 then friend = p end
        end
    end
    return friend
end


function sgs.ai_slash_prohibit.nosqiuyuan(self,from,to)
    if self:isFriend(to,from) then return false end
    if call(from,"getStrategyFlag","NosJiefanUsed") then return false end
    for _,friend in ipairs(self:getFriends(from,true))do
        if not call(to,"isKongcheng") and not (call(to,"getHandcardNum")==1 and (call(to,"hasSkill","kongcheng") or (call(to,"hasSkill","zhiji") and call(to,"getStrategyMark","zhiji")==0))) then return true end
    end
end


sgs.ai_skill_invoke.nosjuece = function(self,data)
    local move = data:toMoveOneTime()
    if not move.from then return false end
    local from = self.room:findPlayerByObjectName(call(move.from,"objectName"))
    return from and ((self:isFriend(from) and self:needToLoseHp(from,self.player)) or (not self:isFriend(from) and self:canAttack(from)))
end


sgs.ai_skill_playerchosen.nosmieji = function(self,targets) -- extra target for Ex Nihilo
    return self:findPlayerToDraw(false,2)
end


sgs.ai_skill_discard.nosfencheng = function(self,discard_num,min_num,optional,include_equip)
    if discard_num==1 and self:needToThrowArmor() then return { self.player:getArmor():getEffectiveId() } end
    local liru = self.room:getCurrent()
    local juece_effect
    if liru and call(liru,"isAlive") and call(liru,"hasSkills","juece|nosjuece") then juece_effect = true end
    if not self:damageIsEffective(self.player,sgs.DamageStruct_Fire,liru) then return {} end
    if juece_effect and self:isEnemy(liru) and call(self.player,"getEquips"):isEmpty() and call(self.player,"getHandcardNum")==1 and not self:needKongcheng()
        and not (call(self.player,"isChained") or not self:isGoodChainTarget(self.player,"F",liru)) then return {} end
    if self:isGoodChainTarget(self.player,"F",liru) or self:needToLoseHp(self.player,liru) then return {} end
    local to_discard = self:recommendDiscard(discard_num,min_num,false,include_equip)
    if #to_discard<discard_num then return {} end
    for _,id in ipairs(to_discard)do
        if isCard("Peach",visible_card(self,id),self.player) then return {}
        elseif 1==call(self.player,"getHp") and isCard("Analeptic",visible_card(self,id),self.player) then return {}
        end
    end
    if not juece_effect then return to_discard
    else
        if call(self.player,"isKongcheng") then return to_discard end
        for _,id in sgs.qlist(call(self.player,"handCards"))do
            if not table.contains(to_discard,id) then return to_discard end
        end
        local cards = sgs.QList2Table(strategy_cards(self,self.player,"h"))
        cards = self:sortByKeepValue(cards,true)
        local wep_id,arm_id,def_id,off_id
        if self.player:getWeapon() then wep_id = self.player:getWeapon():getEffectiveId() end
        if self.player:getArmor() then arm_id = self.player:getArmor():getEffectiveId() end
        if self.player:getDefensiveHorse() then def_id = self.player:getDefensiveHorse():getEffectiveId() end
        if self.player:getOffensiveHorse() then off_id = self.player:getOffensiveHorse():getEffectiveId() end
        if self:needToThrowArmor() and not table.contains(to_discard,arm_id) then table.insert(to_discard,arm_id)
        else
            if self.player:getOffensiveHorse() and not table.contains(to_discard,off_id) then table.insert(to_discard,off_id)
            elseif self.player:getWeapon() and not table.contains(to_discard,wep_id) then table.insert(to_discard,wep_id)
            elseif self.player:getDefensiveHorse() and not table.contains(to_discard,def_id) then
                if self:isWeak() then table.insert(to_discard,def_id)
                else return {} end
            elseif self.player:getArmor() and not table.contains(to_discard,arm_id) then
                if self:isWeak() or (not call(liru,"hasSkill","jueqing") and call(self.player,"hasArmorEffect","Vine")) then table.insert(to_discard,arm_id)
                else return {} end
            end
            if #to_discard==discard_num+1 then table.removeOne(to_discard,call(cards[1],"getEffectiveId")) end
            return to_discard
        end
    end
end


sgs.ai_skill_invoke.noschengxiang = function(self,data)
    return not hasManjuanEffect(self.player)
end


sgs.ai_skill_askforag.noschengxiang = function(self,card_ids)
    return self:selectCurrentAmazingGrace(card_ids,false,"dummyreason")
end


sgs.ai_skill_invoke.nosjianxiong = function(self,data)
    if self.nosjianxiong then self.nosjianxiong = nil return true end
    return not self:needKongcheng(self.player,true)
end


sgs.ai_skill_invoke.nosfankui = function(self,data)
    local target = data:toPlayer()
    if sgs.ai_need_damaged.nosfankui(self,target,self.player) then return true end

    if self:isFriend(target) then
        if self:getOverflow(target)>2 then return true end
        if self:doDisCard(target,"he") then return true end
        return
    end
    if self:isEnemy(target) then
        if self:doDisCard(target,"true") then return true end
        return
    end
    --self:updateLoyalty(-0.8*sgs.ai_loyalty[target:objectName()],self.player:objectName())
    return true
end


sgs.ai_need_damaged.nosfankui = function (self,attacker,player)
    if not call(player,"hasSkills","nosguicai+nosfankui") then return false end
    if not attacker then return end
    local need_retrial = function(target)
        local alive_num = call(self.room,"alivePlayerCount")
        return alive_num+call(target,"getSeat") % alive_num>self.room:getCurrent():getSeat()
                and call(target,"getSeat")<alive_num+call(player,"getSeat") % alive_num
    end
    local retrial_card ={["spade"]=nil,["heart"]=nil,["club"]=nil}
    local attacker_card ={["spade"]=nil,["heart"]=nil,["club"]=nil}

    local handcards = sgs.QList2Table(strategy_cards(self,player,"h"))
    for i=1,#handcards,1 do
        if call(handcards[i],"getSuit")==sgs.Card_Spade and call(handcards[i],"getNumber")>=2 and call(handcards[i],"getNumber")<=9 then
            retrial_card.spade = true
        end
        if call(handcards[i],"getSuit")==sgs.Card_Heart then
            retrial_card.heart = true
        end
        if call(handcards[i],"getSuit")==sgs.Card_Club then
            retrial_card.club = true
        end
    end

    local cards = sgs.QList2Table(call(attacker,"getEquips"))
    local handcards = sgs.QList2Table(strategy_cards(self,attacker,"h"))
    if call(attacker,"getHandcardNum")==1 and #handcards==1 and call(handcards[1],"hasFlag","visible") then table.insert(cards,handcards[1]) end

    for i=1,#cards,1 do
        if call(cards[i],"getSuit")==sgs.Card_Spade and call(cards[i],"getNumber")>=2 and call(cards[i],"getNumber")<=9 then
            attacker_card.spade = sgs.Card_Spade
        end
        if call(cards[i],"getSuit")==sgs.Card_Heart then
            attacker_card.heart = sgs.Card_Heart
        end
        if call(cards[i],"getSuit")==sgs.Card_Club then
            attacker_card.club = sgs.Card_Club
        end
    end

    local players = call(self.room,"getOtherPlayers",player)
    for _,aplayer in sgs.qlist(players)do
        if call(aplayer,"containsTrick","lightning") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) then
            if not retrial_card.spade and attacker_card.spade then return attacker_card.spade end
        end

        if self:isFriend(aplayer,player) and not call(aplayer,"containsTrick","YanxiaoCard") and not call(aplayer,"hasSkill","qiaobian") then

            if call(aplayer,"containsTrick","indulgence") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) and call(aplayer,"getHandcardNum")>=call(aplayer,"getHp") then
                if not retrial_card.heart and attacker_card.heart then return attacker_card.heart end
            end

            if call(aplayer,"containsTrick","supply_shortage") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) and call(self,"hasSkills","yongshi",aplayer) then
                if not retrial_card.club and attacker_card.club then return attacker_card.club end
            end
        end
    end
    return false
end


sgs.ai_skill_cardask["@nosguicai-card"]=function(self,data)
    local judge = data:toJudge()
    if call(self.room,"getMode"):find("_mini_46") and not judge:isGood()
    then return "$"..call(self.player,"handCards"):first() end
    if self:needRetrial(judge) then
        local cards = self:addHandPile()
        local card_id = self:getRetrialCardId(cards,judge)
        if card_id~=-1 then
            return "$"..card_id
        end
    end
    return "."
end


function sgs.ai_cardneed.nosguicai(to,card,self)
    for _,player in sgs.qlist(call(self.room,"getAllPlayers"))do
        if self:getFinalRetrial(to)==1 then
            if call(player,"containsTrick","lightning") and not call(player,"containsTrick","YanxiaoCard") then
                return call(card,"getSuit")==sgs.Card_Spade and call(card,"getNumber")>=2 and call(card,"getNumber")<=9 and not call(self,"hasSkills","hongyan|wuyan")
            end
            if self:isFriend(player) and self:willSkipDrawPhase(player) then
                return call(card,"getSuit")==sgs.Card_Club
            end
            if self:isFriend(player) and self:willSkipPlayPhase(player) then
                return call(card,"getSuit")==sgs.Card_Heart
            end
        end
    end
end


sgs.ai_need_damaged.nosganglie = function(self,attacker,player)
    if not attacker then return end
    if self:isEnemy(attacker) and call(attacker,"getHp")+call(attacker,"getHandcardNum")<=3
    and not(call(self,"hasSkills",sgs.need_kongcheng.."|buqu",attacker) and call(attacker,"getHandcardNum")>1)
    then return true end
    return false
end


sgs.ai_skill_discard.nosganglie = function(self,discard_num,min_num,optional,include_equip)
    return nosganglie_discard(self,discard_num,min_num,optional,include_equip,"nosganglie")
end


function sgs.ai_slash_prohibit.nosganglie(self,from,to)
    if self:isFriend(from,to) then return false end
    if call(from,"hasSkill","jueqing") or (call(from,"hasSkill","nosqianxi") and call(from,"distanceTo",to)==1) then return false end
    if call(from,"getStrategyFlag","NosJiefanUsed") then return false end
    return call(from,"getHandcardNum")+call(from,"getHp")<4
end


sgs.ai_card_intention.NosTuxiCard = function(self,card,from,tos)
    local lord = getLord(self.player)
    local nostuxi_lord = false
    if current_role(self,from)=="neutral" and current_role(self,tos[1])=="neutral" and
        (not tos[2] or current_role(self,tos[2])=="neutral") and lord and not call(lord,"isKongcheng") and
        not (self:needKongcheng(lord) and call(lord,"getHandcardNum")==1 ) and
        self:hasLoseHandcardEffective(lord) and not(call(lord,"hasSkill","tuntian") and call(lord,"hasSkill","zaoxian",true)) and call(from,"aliveCount")>=4 then
            sgs.updateIntention(from,lord,-80)
        return
    end
    if call(from,"getState")=="online" then
        for _,to in ipairs(tos)do
            if call(to,"hasSkill","kongcheng") or call(to,"hasSkill","noslianying") or call(to,"hasSkill","zhiji")
                or (call(to,"hasSkill","tuntian") and call(to,"hasSkill","zaoxian")) then
            else
                sgs.updateIntention(from,to,80)
            end
        end
    else
        for _,to in ipairs(tos)do
            if lord and call(to,"objectName")==call(lord,"objectName") then nostuxi_lord = true end
            local intention = call(from,"getStrategyFlag","nostuxi_isfriend_"..call(to,"objectName")) and -5 or 80
            sgs.updateIntention(from,to,intention)
        end
        if turncount(self)<=1 and not nostuxi_lord and lord and not call(lord,"isKongcheng") and from:getRoom():alivePlayerCount()>2 then
            sgs.updateIntention(from,lord,-80)
        end
    end
end


sgs.ai_skill_invoke.nosluoyi = function(self,data)
    if call(self.player,"isSkipped",sgs.Player_Play) then return false end
    if self:needBear() then return false end
    local cards = strategy_cards(self,self.player,"h")
    cards = sgs.QList2Table(cards)
    local slashtarget = 0
    local dueltarget = 0
    self.enemies = self:sort(self.enemies,"hp")
    for _,card in ipairs(cards)do
        if call(card,"isKindOf","Slash") then
            for _,enemy in ipairs(self.enemies)do
                if call(self.player,"canSlash",enemy,card,true) and self:slashIsEffective(card,enemy) and self:objectiveLevel(enemy)>3 and self:isGoodTarget(enemy,self.enemies,card) then
                    if getCardsNum("Jink",enemy)<1 or (call(self.player,"hasWeapon","Axe") and strategy_cards(self,self.player,"he"):length()>4) then
                        slashtarget = slashtarget+1
                    end
                end
            end
        end
        if call(card,"isKindOf","Duel") then
            for _,enemy in ipairs(self.enemies)do
                if self:getCardsNum("Slash")>=getCardsNum("Slash",enemy) and self:isGoodTarget(enemy,self.enemies,card)
                and self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy,self.player,2)
                and self:damageIsEffective(enemy) and call(enemy,"getStrategyMark","@late")<1 then
                    dueltarget = dueltarget+1
                end
            end
        end
    end
    if (slashtarget+dueltarget)>0 then
        self:speak("luoyi")
        return true
    end
    return false
end


function sgs.ai_cardneed.nosluoyi(to,card,self)
    local slash_num = 0
    local target

    local need_slash = true
        local flag = string.format("%s_%s_%s","visible",self.room:getCurrent():objectName(),call(to,"objectName"))
    for _,c in sgs.qlist(strategy_cards(self,to,"h"))do
        if call(c,"hasFlag","visible") or call(c,"hasFlag",flag) then
            if isCard("Slash",c,to) then
                need_slash = false
                break
            end
        end
    end
    local slash = call(self,"getEvaluationCard","slash")
    self.enemies = self:sort(self.enemies,"defenseSlash")
    for _,enemy in ipairs(self.enemies)do
        if call(to,"canSlash",enemy) and not self:slashProhibit(slash,enemy)
        and self:slashIsEffective(slash,enemy) and self:getDefenseSlash(enemy)<=2 then
            target = enemy
            break
        end
    end

    if need_slash and target and isCard("Slash",card,to) then return true end
    return isCard("Duel",card,to)
end


sgs.ai_skill_invoke.nosyiji = function(self)
    local Shenfen_user
    for _,ap in sgs.qlist(call(self.room,"getAlivePlayers"))do
        if call(self.player,"getStrategyFlag","ShenfenUsing")
        then Shenfen_user = ap break end
    end
    if call(self.player,"getHandcardNum")<2 then return true end
    for _,friend in ipairs(self.friends)do
        if hasManjuanEffect(friend)
        or Shenfen_user and call(Shenfen_user,"objectName")~=call(friend,"objectName") and call(friend,"getHandcardNum")>=4
        or self:needKongcheng(friend,true)
        or self:isLihunTarget(friend)
        then continue end
        return true
    end
end


sgs.ai_skill_askforyiji.nosyiji = function(self,card_ids,tos)
    local cards = {}
    tos = tos or call(self.room,"getAlivePlayers")
    for _,id in ipairs(card_ids)do
        table.insert(cards,visible_card(self,id))
    end
    local Shenfen_user
    for _,p in sgs.list(tos)do
        if call(p,"getStrategyFlag","ShenfenUsing") then Shenfen_user = p break end
    end
    for _,c in ipairs(self:poisonCards(cards))do
        local id = call(c,"getEffectiveId")
        if self.player:getEquipsId():contains(id)
        or self.player:getJudgingAreaID():contains(id) then
            for _,p in sgs.list(tos)do
                if self:isFriend(p) then return p,id end
            end
            for _,p in sgs.list(tos)do
                if not self:isEnemy(p) then return p,id end
            end
            for _,p in sgs.list(tos)do
                return p,id
            end
        else
            for _,p in ipairs(self.enemies)do
                if self:isEnemy(p) and tos:contains(p)
                then return p,id end
            end
            for _,p in sgs.list(tos)do
                if not self:isFriend(p) then return p,id end
            end
        end
    end
    if Shenfen_user then
        if self:isFriend(Shenfen_user) then
            if Shenfen_user~=self.player then
                for _,id in ipairs(card_ids)do
                    return Shenfen_user,id
                end
            end
            return nil,-1
        else
            if call(self.player,"getHandcardNum")<self:getOverflow(false,true)
            then return nil,-1 end
            local card,friend = self:getCardNeedPlayer(cards)
            if card and friend and call(friend,"getHandcardNum")>=4
            and tos:contains(friend) then return friend,call(card,"getId") end
        end
    elseif call(self.player,"getHandcardNum")<=2
    then return nil,-1 end
    local new_friends = {}
    local CanKeep = self.player:hasShownRole()
    for _,friend in ipairs(self.friends)do
        if tos:contains(friend) and not hasManjuanEffect(friend)
        and not self:isLihunTarget(friend) and not self:needKongcheng(friend,true)
        and (not Shenfen_user or friend==Shenfen_user or call(friend,"getHandcardNum")>=4) then
            if friend~=self.player then table.insert(new_friends,friend)
            else CanKeep = true end
        end
    end
    if #new_friends>0 then
        local card,target = self:getCardNeedPlayer(cards)
        if card and target and table.contains(new_friends,target) then
            return target,call(card,"getId")
        end
        if Shenfen_user and self:isFriend(Shenfen_user)
        then return Shenfen_user,call(cards[1],"getId") end
        new_friends = self:sort(new_friends,"defense")
        cards = self:sortByKeepValue(cards,true)
        return new_friends[1],call(cards[1],"getId")
    elseif CanKeep then
        return nil,-1
    else
        local other = {}
        for _,p in sgs.list(tos)do
            if not(self:isEnemy(p) or self:isLihunTarget(p) or call(p,"hasSkill","lihun"))
            then table.insert(other,p) end
        end
        if #other<1 then return nil,-1 end
        return other[math.random(1,#other)],card_ids[math.random(1,#card_ids)]
    end
end


sgs.ai_need_damaged.nosyiji = function (self,attacker,player)
    if not call(player,"hasSkills","nosyiji|tenyearyiji") then return end
    local need_card = false
    local current = self.room:getCurrent()
    if self:hasCrossbowEffect(current) or call(current,"hasSkill","paoxiao") or call(current,"getStrategyFlag","shuangxiong") then need_card = true end
    if call(self,"hasSkills","jieyin|jijiu",current) and self:getOverflow(current)<=0 then need_card = true end
    if self:isFriend(current,player) and need_card then return true end

    local friends = {}
    for _,ap in sgs.qlist(call(self.room,"getAlivePlayers"))do
        if self:isFriend(ap,player) then
            table.insert(friends,ap)
        end
    end
    friends = self:sort(friends,"hp")

    if #friends>0 and call(friends[1],"objectName")==call(player,"objectName") and self:isWeak(player) and getCardsNum("Peach",player,(attacker or self.player))==0 then return false end
    if #friends>1 and self:isWeak(friends[2]) then return true end

    return call(player,"getHp")>2 and turncount(self)>2 and #friends>1
end


sgs.ai_skill_invoke.nostieji = function(self,data)
    local target = data:toPlayer()
    if self:isFriend(target) then return false end

    local zj = self.room:findPlayerBySkillName("guidao")
    if zj and self:isEnemy(zj) and self:canRetrial(zj) then return false end

    --[[
    if call(target,"hasArmorEffect","eight_diagram") and not IgnoreArmor(self.player,target) then return true end
    if call(target,"hasLordSkill","hujia") then
        for _,p in ipairs(self.enemies)do
            if call(p,"getKingdom")=="wei" and (call(p,"hasArmorEffect","eight_diagram") or call(p,"getHandcardNum")>0) then return true end
        end
    end
    if call(target,"hasSkill","longhun") and call(target,"getHp")==1 and self:hasSuit("club",true,target) then return true end

    if call(target,"isKongcheng") or (self:getKnownNum(target)==call(target,"getHandcardNum") and getKnownCard(target,self.player,"Jink",true)==0) then return false end
    ]]
    return true
end


sgs.ai_skill_invoke.nosyingzi = function(self,data)
    if call(self.player,"hasSkill","haoshi") then
        local num = call(self.player,"getHandcardNum")
        local skills = self.player:getVisibleSkillList(true)
        local count = self:ImitateResult_DrawNCards(self.player,skills)
        if num+count>5 then
            local others = call(self.room,"getOtherPlayers",self.player)
            local least = 999
            local target = nil
            for _,p in sgs.qlist(others)do
                local handcardnum = call(p,"getHandcardNum")
                if handcardnum<least then
                    least = handcardnum
                    target = p
                end
            end
            if target then
                if self:isFriend(target) then
                    return not call(target,"hasSkill","manjuan")
                end
            end
        end
    end
    return true
end


function sgs.ai_skill_suit.nosfanjian(self)
    local map = {0,0,1,2,2,3,3,3}
    local suit = map[math.random(1,8)]
    local tg = self.room:getCurrent()
    local suits = {}
    local maxnum,maxsuit = 0,nil
        local flag = string.format("%s_%s_%s","visible",call(self.player,"objectName"),call(tg,"objectName"))
    for _,c in sgs.qlist(strategy_cards(self,tg,"h"))do
        if call(c,"hasFlag",flag) or call(c,"hasFlag","visible") then
            if not suits[call(c,"getSuitString")] then suits[call(c,"getSuitString")] = 1 else suits[call(c,"getSuitString")] = suits[call(c,"getSuitString")]+1 end
            if suits[call(c,"getSuitString")]>maxnum then
                maxnum = suits[call(c,"getSuitString")]
                maxsuit = call(c,"getSuit")
            end
        end
    end
    if call(self.player,"hasSkill","hongyan") and (maxsuit==sgs.Card_Spade or suit==sgs.Card_Spade)
    then return sgs.Card_Heart end
    if maxsuit then
        if call(self.player,"hasSkill","hongyan") and maxsuit==sgs.Card_Spade
        then return sgs.Card_Heart end
        return maxsuit
    else
        if call(self.player,"hasSkill","hongyan") and suit==sgs.Card_Spade
        then return sgs.Card_Heart end
        return suit
    end
end


sgs.ai_skill_invoke.noslianying = function(self,data)
    if self:needKongcheng(self.player,true) then
        return call(self.player,"getPhase")==sgs.Player_Play
    end
    return true
end


function sgs.ai_cardneed.nosguose(to,card)
    return call(card,"getSuit")==sgs.Card_Diamond
end


sgs.ai_skill_invoke.fankui = function(self,data)
    local target = data:toPlayer()
    if sgs.ai_need_damaged.fankui(self,target,self.player) then return true end

    if self:isFriend(target) then
        if self:getOverflow(target)>2 then return true end
        return call(target,"hasSkills",sgs.lose_equip_skill) and call(target,"hasEquip")
    end
    return self:doDisCard(target,"he")
end


sgs.ai_can_damagehp.fankui = function(self,from,card,to)
    if from and call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
    and self:canLoseHp(from,card,to)
    then
        return self:isEnemy(from) and self:isWeak(from) and call(from,"getCardCount")>0
    end
end


sgs.ai_need_damaged.fankui = function (self,attacker,player)
    if not call(player,"hasSkills","guicai+fankui") then return false end
    if not attacker then return end
    local need_retrial = function(target)
        local alive_num = call(self.room,"alivePlayerCount")
        return alive_num+call(target,"getSeat") % alive_num>self.room:getCurrent():getSeat()
                and call(target,"getSeat")<alive_num+call(player,"getSeat") % alive_num
    end
    local retrial_card ={["spade"]=nil,["heart"]=nil,["club"]=nil}
    local attacker_card ={["spade"]=nil,["heart"]=nil,["club"]=nil}

    local handcards = sgs.QList2Table(strategy_cards(self,player,"h"))
    for i=1,#handcards,1 do
        if call(handcards[i],"getSuit")==sgs.Card_Spade and call(handcards[i],"getNumber")>=2 and call(handcards[i],"getNumber")<=9 then
            retrial_card.spade = true
        end
        if call(handcards[i],"getSuit")==sgs.Card_Heart then
            retrial_card.heart = true
        end
        if call(handcards[i],"getSuit")==sgs.Card_Club then
            retrial_card.club = true
        end
    end

    local cards = sgs.QList2Table(call(attacker,"getEquips"))
    local handcards = sgs.QList2Table(strategy_cards(self,attacker,"h"))
    if call(attacker,"getHandcardNum")==1 and #handcards==1 and call(handcards[1],"hasFlag","visible") then table.insert(cards,handcards[1]) end

    for i=1,#cards,1 do
        if call(cards[i],"getSuit")==sgs.Card_Spade and call(cards[i],"getNumber")>=2 and call(cards[i],"getNumber")<=9 then
            attacker_card.spade = sgs.Card_Spade
        end
        if call(cards[i],"getSuit")==sgs.Card_Heart then
            attacker_card.heart = sgs.Card_Heart
        end
        if call(cards[i],"getSuit")==sgs.Card_Club then
            attacker_card.club = sgs.Card_Club
        end
    end

    local players = call(self.room,"getOtherPlayers",player)
    for _,aplayer in sgs.list(players)do
        if call(aplayer,"containsTrick","lightning") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) then
            if not retrial_card.spade and attacker_card.spade then return attacker_card.spade end
        end

        if self:isFriend(aplayer,player) and not call(aplayer,"containsTrick","YanxiaoCard") and not call(aplayer,"hasSkill","qiaobian") then
            if call(aplayer,"containsTrick","indulgence") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) and call(aplayer,"getHandcardNum")>=call(aplayer,"getHp") then
                if not retrial_card.heart and attacker_card.heart then return attacker_card.heart end
            end
            if call(aplayer,"containsTrick","supply_shortage") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) and call(self,"hasSkills","yongshi",aplayer) then
                if not retrial_card.club and attacker_card.club then return attacker_card.club end
            end
        end
    end
    return false
end


sgs.ai_skill_cardask["@guicai-card"] = function(self,data)
    local judge = data:toJudge()
    if call(self.room,"getMode"):find("_mini_46") and not judge:isGood()
    then return "$"..call(self.player,"handCards"):first() end
    if self:needRetrial(judge) then
        local cards = self:addHandPile("he")
        local card_id = self:getRetrialCardId(cards,judge)
        if card_id~=-1 then return "$"..card_id end
    end
    return "."
end


function sgs.ai_cardneed.guicai(to,card,self)
    for _,player in sgs.list(call(self.room,"getAllPlayers"))do
        if self:getFinalRetrial(to)==1 then
            if call(player,"containsTrick","lightning") and not call(player,"containsTrick","YanxiaoCard") then
                return call(card,"getSuit")==sgs.Card_Spade and call(card,"getNumber")>=2 and call(card,"getNumber")<=9 and not call(self,"hasSkills","hongyan|wuyan")
            end
            if self:isFriend(player) and self:willSkipDrawPhase(player) then
                return call(card,"getSuit")==sgs.Card_Club
            end
            if self:isFriend(player) and self:willSkipPlayPhase(player) then
                return call(card,"getSuit")==sgs.Card_Heart
            end
        end
    end
end


sgs.ai_can_damagehp.ganglie = function(self,from,card,to)
    if from and call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
    and self:canLoseHp(from,card,to) then
        return self:isEnemy(from) and self:isWeak(from)
    end
end




sgs.ai_need_damaged.ganglie = function(self,attacker,player)
    if not attacker then return end
    if not call(attacker,"hasSkill","ganglie") and self:needToLoseHp(attacker,player)
    then return self:isFriend(attacker,player) end
    if self:isEnemy(attacker) and call(attacker,"getHp")+call(attacker,"getHandcardNum")<=3
    and not(call(attacker,"hasSkills",sgs.need_kongcheng.."|buqu") and call(attacker,"getHandcardNum")>1)
    and self:isGoodTarget(attacker,self:getEnemies(attacker))
    then return true end
    return false
end


function sgs.ai_slash_prohibit.ganglie(self,from,to)
    if self:isFriend(from,to) then return false end
    if call(from,"hasSkill","jueqing") or (call(from,"hasSkill","nosqianxi") and call(from,"distanceTo",to)==1) then return false end
    if call(from,"getStrategyFlag","NosJiefanUsed") then return false end
    if call(from,"getHandcardNum")==1 and call(from,"getEquips"):length()==0 then
        local cards=strategy_cards(self,from,"h")
        local sole_slash
        if #cards==1 then sole_slash=call(cards[1],"isKindOf","Slash")
        else
            sole_slash=self:useKnowledgeEstimate({value=false,status="estimate",
                basis="undisclosed_singleton_not_assumed_slash",known_count=0,hidden_count=1,
                viewer=call(self.player,"objectName"),observer=call(from,"objectName")},"standard.ganglie_singleton")
        end
        if sole_slash and call(from,"getHp")>=2 then return false end
    end
    return call(from,"getHp")+call(from,"getEquips"):length()<4 or call(from,"getHp")<2
end


sgs.ai_card_intention.TuxiCard = function(self,card,from,tos)
    local lord = getLord(self.player)
    local tuxi_lord = false
    if current_role(self,from)=="neutral" and current_role(self,tos[1])=="neutral" and
        (not tos[2] or current_role(self,tos[2])=="neutral") and lord and not call(lord,"isKongcheng") and
        not (self:needKongcheng(lord) and call(lord,"getHandcardNum")==1 ) and
        self:hasLoseHandcardEffective(lord) and not (call(lord,"hasSkill","tuntian") and call(lord,"hasSkill","zaoxian",true)) and call(from,"aliveCount")>=4 then
            sgs.updateIntention(from,lord,-80)
        return
    end
    if call(from,"getState")=="online" then
        for _,to in ipairs(tos)do
            if call(to,"hasSkill","kongcheng") or call(to,"hasSkill","lianying") or call(to,"hasSkill","zhiji")
                or (call(to,"hasSkill","tuntian") and call(to,"hasSkill","zaoxian")) then
            else
                sgs.updateIntention(from,to,80)
            end
        end
    else
        for _,to in ipairs(tos)do
            if lord and call(to,"objectName")==call(lord,"objectName") then tuxi_lord = true end
            local intention = call(from,"getStrategyFlag","tuxi_isfriend_"..call(to,"objectName")) and -5 or 80
            sgs.updateIntention(from,to,intention)
        end
        if turncount(self)<=1 and not tuxi_lord and lord and not call(lord,"isKongcheng") and from:getRoom():alivePlayerCount()>2 then
            sgs.updateIntention(from,lord,-80)
        end
    end
end


sgs.ai_skill_invoke.luoyi = function(self)
    if call(self.player,"getPile","yiji"):length()>1 then return false end
    local diaochan = self.room:findPlayerBySkillName("lijian") or self.room:findPlayerBySkillName("noslijian")
    if diaochan and self:isEnemy(diaochan) then
        for _,friend in ipairs(self.friends_noself)do
            if self:isWeak(friend) or call(friend,"getHp")<=2 then return false end
        end
    end
    return not self:isWeak()
end


function sgs.ai_cardneed.luoyi(to,card,self)
    local slash_num = 0
    local target

        local flag = string.format("%s_%s_%s","visible",self.room:getCurrent():objectName(),call(to,"objectName"))
    local need_slash = true
    for _,c in sgs.list(strategy_cards(self,to,"h"))do
        if call(c,"hasFlag","visible") or call(c,"hasFlag",flag) then
            if isCard("Slash",c,to) then
                need_slash = false
                break
            end
        end
    end

    local slash = call(self,"getEvaluationCard","slash")
    self.enemies = self:sort(self.enemies,"defenseSlash")
    for _,enemy in ipairs(self.enemies)do
        if call(to,"canSlash",enemy) and not self:slashProhibit(slash,enemy) and self:slashIsEffective(slash,enemy) and self:getDefenseSlash(enemy)<=2 then
            target = enemy
            break
        end
    end

    if need_slash and target and isCard("Slash",card,to) then return true end
    return isCard("Duel",card,to)
end


function sgs.ai_slash_prohibit.tiandu(self,from,to)
    if self:canLiegong(to,from) then return false end
    if self:isEnemy(to) and self:hasEightDiagramEffect(to) and not IgnoreArmor(from,to) and #self.enemies>1 then return true end
end


sgs.ai_skill_invoke.yiji = function(self)
    if self:needKongcheng(self.player,true)
    and call(self.player,"getHandcardNum")<1
    and #self.friends_noself<1
    then return false end
    return true
end


sgs.ai_need_damaged.yiji = function (self,attacker,player)
    if not call(player,"hasSkill","yiji") then return end

    local friends = {}
    for _,ap in sgs.list(call(self.room,"getAlivePlayers"))do
        if self:isFriend(ap,player) then
            table.insert(friends,ap)
        end
    end
    friends = self:sort(friends,"hp")

    if #friends>0 and call(friends[1],"objectName")==call(player,"objectName") and self:isWeak(player) and getCardsNum("Peach",player,(attacker or self.player))==0 then return false end

    return call(player,"getHp")>2 and turncount(self)>2 and #friends>1 and not self:isWeak(player) and call(player,"getHandcardNum")>=2
end


sgs.ai_can_damagehp.yiji = function(self,from,card,to)
    return call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
    and self:canLoseHp(from,card,to)
end


function sgs.ai_cardneed.qingguo(to,card)
    return call(to,"getHandcardNum")<2 and call(card,"isBlack")
end




sgs.ai_card_intention.RendeCard = function(self,card,from,tos)
    local to = tos[1]
    local intention = -70
    if hasManjuanEffect(to) then
        intention = 0
    elseif call(to,"hasSkill","kongcheng") and call(to,"isKongcheng") then
        intention = 30
    end
    sgs.updateIntention(from,to,intention)
end


sgs.ai_skill_use["@@rende"] = function(self,prompt)
    local cards = {}
    for _,h in sgs.list(strategy_cards(self,self.player,"h"))do
        table.insert(cards,h)
    end
    cards = self:sortByUseValue(cards,true)

    for i=1,call(self.player,"getHandcardNum") do
        if #cards<1 then return "." end
        local card,friend = self:getCardNeedPlayer(cards)
        if card and friend then table.removeOne(cards,card)
        else return "." end

        if friend==self.player or not call(self.player,"handCards"):contains(call(card,"getId")) then continue end
        if call(card,"isAvailable",self.player) then
            local canJijiang = call(friend,"getKingdom")=="shu" and call(self.player,"hasLordSkill","jijiang")
            if call(card,"isKindOf","Indulgence") or call(card,"isKindOf","SupplyShortage") then
                if table.contains(self.toUse,card)
                and self:getEnemyNumBySeat(self.player,friend)>0
                then continue end
            elseif call(card,"isKindOf","Slash") and not canJijiang
            or call(card,"isKindOf","Duel") or call(card,"isKindOf","Snatch")
            or call(card,"isKindOf","Dismantlement") then
                local d = self:aiUseCard(card)
                if d.card and d.to:length()>0 then
                if call(card,"isKindOf","Slash") or call(card,"isKindOf","Duel") then
                        local tp = d.to:first()
                        if d.to:length()>1 or call(tp,"getHp")<2 or getCardsNum("Jink",tp,self.player)<1
                        or call(tp,"isLocked",call(self,"getEvaluationCard","jink"))
                    then continue end
                elseif self:getEnemyNumBySeat(self.player,friend)>0 then
                    local hasDelayedTrick
                        for _,p in sgs.list(d.to)do
                        if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p))
                        then hasDelayedTrick = true break end
                    end
                    if hasDelayedTrick then continue end
                end
            end
            end
        end

        local usecard = rende_card(self,{call(card,"getId")})
        if call(friend,"hasSkill","enyuan") and #cards>0
        and not (call(self.room,"getMode")=="04_1v3" and call(self.player,"getStrategyMark","nosrende")==1)
        then usecard = rende_card(self,{call(card,"getId"), call(cards[1],"getId")}) end
        return answer_skill(self,usecard,{friend})
    end
end


sgs.ai_use_revises.rende = function(self,card,use)
    if call(self.player,"getLostHp")>1 and self:findFriendsByType(sgs.Friend_Draw)
    and call(self.player,"usedTimes","RendeCard")<1 then
        if call(card,"getTypeId")==1
        or call(card,"getTypeId")==2 and not (card:targetFixed() and call(card,"isDamageCard"))
        or call(card,"getTypeId")==3 and self:getSameEquip(card)
        then return false end
    end
end


sgs.ai_skill_defense.rende = function(self, player)
    if call(player,"getHp")>2 and call(player,"getHandcardNum")>1 then
        return 1
    end
    return 0
end


sgs.ai_card_intention.JijiangCard = function(self,card,from,tos)
    if not call(from,"isLord") and self.room:getCurrent():objectName()==call(from,"objectName") then
        return sgs.ai_card_intention.Slash(self,card,from,tos)
    end
end


sgs.ai_skill_cardask["@jijiang-slash"] = function(self,data)
    local from = data:toPlayer()
    if not from or not self:isFriend(from) then return "." end
    if self:needBear() then return "." end
    local jijiangtargets = {}
    for _,player in sgs.list(call(self.room,"getAllPlayers"))do
        if call(player,"getStrategyFlag","JijiangTarget") then
            if self:isFriend(player) and not self:needToLoseHp(player,from,call(self,"getEvaluationCard","slash")) then return "." end
            table.insert(jijiangtargets,player)
        end
    end
    if #jijiangtargets==0 then
        return self:getCard("Slash") or "."
    end
    jijiangtargets = self:sort(jijiangtargets,"defenseSlash")
    for _,slash in ipairs(self:getCards("Slash"))do
        for _,target in ipairs(jijiangtargets)do
            if not self:slashProhibit(slash,target,from) and self:slashIsEffective(slash,target,from)
            then return slash end
        end
    end
    return "."
end


function sgs.ai_cardneed.wusheng(to,card)
    return call(to,"getHandcardNum")<3 and call(card,"isRed")
end


function sgs.ai_skill_pindian.yijue(minusecard,self,requestor)
    if call(requestor,"getHandcardNum")==1 then
        local cards = sgs.QList2Table(strategy_cards(self,self.player,"h"))
        cards = self:sortByKeepValue(cards)
        return cards[1]
    end
    return self:getMaxCard()
end


sgs.ai_cardneed.yijue = function(to,card,self)
    local cards = strategy_cards(self,to,"h")
    local has_big = false
    for _,c in sgs.list(cards)do
        local flag = string.format("%s_%s_%s","visible",self.room:getCurrent():objectName(),call(to,"objectName"))
        if call(c,"hasFlag","visible") or call(c,"hasFlag",flag) then
            if call(c,"getNumber")>10 then
                has_big = true
                break
            end
        end
    end
    return not has_big and call(card,"getNumber")>10
end


sgs.ai_choicemade_filter.skillChoice.yijue = function(self,player,promptlist)
    local choice = promptlist[#promptlist]
    local intention = (choice=="recover") and -30 or 30
    local target = nil
    for _,p in sgs.list(call(self.room,"getOtherPlayers",player))do
        if call(p,"getStrategyFlag","YijueTarget") then
            target = p
            break
        end
    end
    if not target then return end
    sgs.updateIntention(player,target,intention)
end


function sgs.ai_cardneed.paoxiao(to,card,self)
    local cards = strategy_cards(self,to,"h")
    local has_weapon = to:getWeapon() and not to:getWeapon():isKindOf("Crossbow")
    local slash_num = 0
    for _,c in sgs.list(cards)do
        local flag=string.format("%s_%s_%s","visible",self.room:getCurrent():objectName(),call(to,"objectName"))
        if call(c,"hasFlag","visible") or call(c,"hasFlag",flag) then
            if call(c,"isKindOf","Weapon") and not call(c,"isKindOf","Crossbow") then
                has_weapon=true
            end
            if call(c,"isKindOf","Slash") then slash_num = slash_num +1 end
        end
    end

    if not has_weapon then
        return call(card,"isKindOf","Weapon") and not call(card,"isKindOf","Crossbow")
    else
        return call(to,"hasWeapon","spear") or call(card,"isKindOf","Slash") or (slash_num>1 and call(card,"isKindOf","Analeptic"))
    end
end


sgs.ai_skill_playerchosen.yajiao = function(self,targets)
    local id = call(self.player,"getStrategyMark","yajiao")
    local card = visible_card(self,id)
    local cards = { card }
    local c,friend = self:getCardNeedPlayer(cards,self.friends)
    if friend then return friend end

    self.friends = self:sort(self.friends)
    for _,friend in ipairs(self.friends)do
        if self:isValuableCard(card,friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then return friend end
    end
    for _,friend in ipairs(self.friends)do
        if self:isWeak(friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then return friend end
    end
    local trash = call(card,"isKindOf","Disaster") or call(card,"isKindOf","GodSalvation") or call(card,"isKindOf","AmazingGrace")
    if trash then
        for _,enemy in ipairs(self.enemies)do
            if call(enemy,"getPhase")>sgs.Player_Play and self:needKongcheng(enemy,true) and not hasManjuanEffect(enemy) then return enemy end
        end
    end
    for _,friend in ipairs(self.friends)do
        if not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then return friend end
    end
end


sgs.ai_playerchosen_intention.yajiao = function(self,from,to)
    if not self:needKongcheng(to,true) and not hasManjuanEffect(to) then sgs.updateIntention(from,to,-50) end
end


sgs.ai_skill_choice.yajiao = function(self,choices,data)
    local card = data:toCard()
    local valuable = self:isValuableCard(card)
    local current = self.room:getCurrent()
    if not current then return "throw" end -- avoid potential errors
    if call(current,"isAlive") then
        local currentMayObtain = getKnownCard(current,self.player,"ExNihilo")+getKnownCard(current,self.player,"IronChain")>0
        if currentMayObtain then
            local valuable = self:isValuableCard(card,current)
            return (self:isFriend(current)==valuable) and "cancel" or "throw"
        end
    end

    local hasLightning,hasIndulgence,hasSupplyShortage
    local nextAlive = current:getNextAlive()
    local tricks = call(nextAlive,"getJudgingArea")
    if not tricks:isEmpty() and not call(nextAlive,"containsTrick","YanxiaoCard") and not call(nextAlive,"hasSkill","qianxi") then
        local trick = tricks:at(tricks:length()-1)
        if self:hasTrickEffective(trick,nextAlive) then
            if call(trick,"isKindOf","Lightning") then hasLightning = true
            elseif call(trick,"isKindOf","Indulgence") then hasIndulgence = true
            elseif call(trick,"isKindOf","SupplyShortage") then hasSupplyShortage = true
            end
        end
    end

    if call(nextAlive,"hasSkill","luoshen") then
        local valid = call(card,"isRed")
        return (self:isFriend(nextAlive)==valid) and "throw" or "cancel"
    end
    if call(nextAlive,"hasSkill","yinghun") and call(nextAlive,"isWounded") then
        return self:isFriend(nextAlive) and "cancel" or "throw"
    end
    if hasLightning then
        local valid = (call(card,"getSuit")==sgs.Card_Spade and call(card,"getNumber")>=2 and call(card,"getNumber")<=9)
        return (self:isFriend(nextAlive)==valid) and "throw" or "cancel"
    end
    if hasIndulgence then
        local valid = (call(card,"getSuit")~=sgs.Card_Heart)
        return (self:isFriend(nextAlive)==valid) and "throw" or "cancel"
    end
    if hasSupplyShortage then
        local valid = (call(card,"getSuit")~=sgs.Card_Club)
        return (self:isFriend(nextAlive)==valid) and "throw" or "cancel"
    end

    if self:isFriend(nextAlive) and not self:willSkipDrawPhase(nextAlive) and not self:willSkipPlayPhase(nextAlive)
        and not call(nextAlive,"hasSkill","luoshen")
        and not call(nextAlive,"hasSkills","tuxi|nostuxi") and not (call(nextAlive,"hasSkill","qiaobian") and call(nextAlive,"getHandcardNum")>0) then
        if self:isValuableCard(card,nextAlive) then
            return "cancel"
        end
        if call(card,"isKindOf","Jink") and getCardsNum("Jink",nextAlive,self.player)<1 then
            return "cancel"
        end
        if call(card,"isKindOf","Nullification") and getCardsNum("Nullification",nextAlive,self.player)<1 then
            return "cancel"
        end
        if call(card,"isKindOf","Slash") and self:hasCrossbowEffect(nextAlive) then
            return "cancel"
        end
        for _,skill in ipairs(sgs.getPlayerSkillList(nextAlive))do
            if sgs.ai_cardneed[call(skill,"objectName")] and sgs.ai_cardneed[call(skill,"objectName")](nextAlive,card,self) then return "cancel" end
        end
    end

    local trash = call(card,"isKindOf","Disaster") or call(card,"isKindOf","AmazingGrace") or call(card,"isKindOf","GodSalvation")
    if trash and self:isEnemy(nextAlive) then return "cancel" end
    return "throw"
end


sgs.ai_skill_invoke.tieji = function(self,data)
    local target = data:toPlayer()
    if not self:isFriend(target) then return true end
    return false
end


sgs.ai_skill_cardask["@tieji-discard"] = function(self,data,pattern)
    local suit = pattern:split("|")[2]
    local use = data:toCardUse()
    if self:needToThrowArmor() and self.player:getArmor():getSuitString()==suit then return "$"..self.player:getArmor():getEffectiveId() end
    if not self:slashIsEffective(use.card,self.player,use.from)
    or (self:ajustDamage(use.from,self.player,1,use.card)<2
    and self:needToLoseHp(self.player,use.from,use.card)) then return "." end
    if self:ajustDamage(use.from,self.player,1,use.card) and self:getCardsNum("Peach")>0 then return "." end
    if self:getCardsNum("Jink")==0 or not sgs.isJinkAvailable(use.from,self.player,use.card,true) then return "." end
    local equip_index = { 3,0,2,4,1 }
    if call(self.player,"hasSkills",sgs.lose_equip_skill) then
        for _,i in ipairs(equip_index)do
            if i==4 then break end
            if self.player:getEquip(i) and self.player:getEquip(i):getSuitString()==suit then return "$"..self.player:getEquip(i):getEffectiveId() end
        end
    end
    local jiangqin = self.room:findPlayerBySkillName("niaoxiang")
    local need_double_jink = call(use.from,"hasSkill","wushuang")
        or (call(use.from,"hasSkill","roulin") and call(self.player,"isFemale"))
        or (call(self.player,"hasSkill","roulin") and call(use.from,"isFemale"))
        or (jiangqin and jiangqin:isAdjacentTo(self.player) and use.from:isAdjacentTo(self.player) and self:isEnemy(jiangqin))
    local cards = sgs.QList2Table(strategy_cards(self,self.player,"h"))
    cards = self:sortByKeepValue(cards)
    for _,card in ipairs(cards)do
        if call(card,"getSuitString")~=suit or (not self:isWeak() and (self:getKeepValue(card)>8 or self:isValuableCard(card)))
            or (isCard("Jink",card,self.player) and self:getCardsNum("Jink")-1<(need_double_jink and 2 or 1)) then continue end
        return "$"..call(card,"getEffectiveId")
    end
    for _,i in ipairs(equip_index)do
        if self.player:getEquip(i) and self.player:getEquip(i):getSuitString()==suit then
            if not (i==1 and self:evaluateArmor()>3)
                and not (i==4 and self.player:getTreasure():isKindOf("WoodenOx") and call(self.player,"getPile","wooden_ox"):length()>=3) then
                return "$"..self.player:getEquip(i):getEffectiveId()
            end
        end
    end
end


sgs.ai_choicemade_filter.skillInvoke.tieji = function(self,player,promptlist)
    if promptlist[#promptlist]=="yes" then
        local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
        if target then sgs.updateIntention(player,target,50) end
    end
end



sgs.ai_skill_cardask["@jizhi-exchange"] = function(self,data)
    local card = data:toCard()
    local handcards = sgs.QList2Table(strategy_cards(self,self.player,"h"))
    if call(self.player,"getPhase")~=sgs.Player_Play then
        if hasManjuanEffect(self.player) then return "." end
        handcards = self:sortByKeepValue(handcards)
        for _,card_ex in ipairs(handcards)do
            if self:getKeepValue(card_ex)<self:getKeepValue(card) and not self:isValuableCard(card_ex) then
                return "$"..call(card_ex,"getEffectiveId")
            end
        end
    else
        if call(card,"isKindOf","Slash") and not self:slashIsAvailable() then return "." end
        handcards = self:sortByUseValue(handcards)
        for _,card_ex in ipairs(handcards)do
            if self:getUseValue(card_ex)<self:getUseValue(card) and not self:isValuableCard(card_ex) then
                return "$"..call(card_ex,"getEffectiveId")
            end
        end
    end
    return "."
end


function sgs.ai_cardneed.jizhi(to,card)
    return call(card,"getTypeId")==sgs.Card_TypeTrick
end


function sgs.ai_cardneed.zhiheng(to,card)
    return not call(card,"isKindOf","Jink")
end


function sgs.ai_cardneed.qixi(to,card)
    return call(card,"isBlack")
end


sgs.ai_card_intention.FanjianCard = function(self,card,from,tos)
    local to = tos[1]
    if self:hasZhaxiangEffect(to) then
    elseif call(card,"getSuit")==sgs.Card_Spade and call(to,"hasSkill","hongyan") then
        sgs.updateIntention(from,to,-10)
    else
        sgs.updateIntention(from,to,60)
    end
end


sgs.ai_skill_invoke.fanjian_discard = function(self,data)
    if self:getCardsNum("Peach")>=1 and not self:willSkipPlayPhase() then return false end
    if not self:isWeak() and self:hasZhaxiangEffect(self.player) and not (call(self.player,"getHp")==2 and call(self.player,"hasSkill","chanyuan")) then return false end
    if call(self.player,"getHandcardNum")<=3 or self:isWeak() then return true end
    local suit = call(self.player,"getStrategyMark","FanjianSuit")
    local count = 0
    for _,card in sgs.list(strategy_cards(self,self.player,"h"))do
        if call(card,"getSuit")==suit then
            count = count+1
            if self:isValuableCard(card) then count = count+0.5 end
        end
    end
    local equip_val_table = { 2,2.5,1,1.5,2.2 }
    for i = 0,4,1 do
        if self.player:getEquip(i) and self.player:getEquip(i):getSuit()==suit then
            if i==1 and self:needToThrowArmor() then
                count = count-1
            else
                count = equip_val_table[i+1]
                if call(self.player,"hasSkills",sgs.lose_equip_skill) then count = count+0.5 end
            end
        end
    end
    return count/call(self.player,"getCardCount",true)<=0.6
end


function sgs.ai_cardneed.guose(to,card)
    return call(card,"getSuit")==sgs.Card_Diamond
end


function sgs.ai_slash_prohibit.liuli(self,from,to,card)
    if self:isFriend(to,from) then return false end
    if call(from,"getStrategyFlag","NosJiefanUsed") then return false end
    if call(to,"isNude") then return false end
    for _,friend in ipairs(self:getFriends(from,true))do
        if call(to,"canSlash",friend,card) and self:slashIsEffective(card,friend,from) then return true end
    end
end


function sgs.ai_cardneed.liuli(to,card)
    return call(to,"getHandcardNum")+call(to,"getEquips"):length()<=2
end


sgs.ai_card_intention.JieyinCard = function(self,card,from,tos)
    if not call(from,"getStrategyFlag","jieyin_isenemy_"..call(tos[1],"objectName")) then
        sgs.updateIntention(from,tos[1],-80)
    end
end


-- The donor passes nil as cardChosen.snatch's sender. updateIntention's
-- first guard returns without changing intention; no hidden chosen ID is needed.
sgs.ai_card_intention.ChuliCard=function(self,card,from,tos)
    for _,to in ipairs(tos)do
        if self:chuliSourceMap("state") and self:chuliSourceMap("entry",call(to,"objectName")) then
            local em_prompt={"cardChosen","chuli",tostring(self:chuliSourceMap("entry",call(to,"objectName"))),call(to,"objectName")}
            sgs.ai_choicemade_filter.cardChosen.snatch(self,nil,em_prompt)
        end
    end
end

sgs.ai_cardneed.jijiu = function(to,card)
    return call(card,"isRed")
end


sgs.ai_skill_cardask["@wushuang-slash-1"] = function(self,data,pattern,target)
    if self:standardNullFilter() then return "." end
    if self:canUseJieyuanDecrease(target) then return "." end
    if not call(target,"hasSkill","jueqing") and (call(self.player,"hasSkill","wuyan") or call(target,"hasSkill","wuyan")) then return "." end
    if self:getCardsNum("Slash")<2 and not (call(self.player,"getHandcardNum")==1 and call(self,"hasSkills",sgs.need_kongcheng)) then return "." end
end


sgs.ai_skill_cardask["@multi-jink-start"] = function(self,data,pattern,target,target2,arg)
    local rest_num = tonumber(arg)
    if rest_num<=1 then return self:selectSlashJink(self.request.options or{},self.request,target) end
    if self:standardNullFilter()
    or self:canUseJieyuanDecrease(target)
    then return "." end
    if call(self.player,"hasSkill","kongcheng") then
        if call(self.player,"getHandcardNum")==1 and self:getCardsNum("Jink")==1 and call(target,"hasWeapon","guding_blade") then return "." end
    else
        --add
        if call(target,"hasSkill","sfofl_wushuang") and not data:toCardEffect().call(card,"hasFlag","sfofl_wushuang"..call(self.player,"objectName")) then
            return self:selectSlashJink(self.request.options or{},self.request,target)
        end
        --add
        if call(target,"hasSkill","ahmouwushuang") and not data:toCardEffect().call(card,"hasFlag","ahmouwushuang"..call(self.player,"objectName")) then
            return self:selectSlashJink(self.request.options or{},self.request,target)
        end
        if self:getCardsNum("Jink")<rest_num and self:hasLoseHandcardEffective() then return "." end
    end
    return self:selectSlashJink(self.request.options or{},self.request,target)
end


sgs.ai_skill_invoke.biyue = function(self,data)
    return not self:needKongcheng(self.player,true)
end





sgs.ai_skill_choice.yaowu = function(self,choices)
    if call(self.player,"getHp")>=getBestHp(self.player) or (self:needKongcheng(self.player,true) and call(self.player,"getPhase")==sgs.Player_NotActive) then
        return "draw"
    end
    return "recover"
end


sgs.ai_skill_invoke.wangzun = function(self,data)
    local lord = self.room:getCurrent()
    if call(self.player,"objectName")==call(lord,"objectName") then return true end
    if self:isEnemy(lord) then
        if not self:needKongcheng(self.player) then
            return true
        end
    elseif self:isFriend(lord) then
        if not self:isWeak(lord) or (self:getOverflow(lord)<-2 or (self:willSkipDrawPhase(lord) and self:getOverflow(lord)<0)) then
            return true
        end
    end
    return false
end


sgs.ai_choicemade_filter.skillInvoke.wangzun = function(self,player,promptlist)
    if promptlist[#promptlist]=="yes" then
        local lord = self.room:getCurrent()
        if not self:isWeak(lord) or (self:getOverflow(lord)<-2 or (self:willSkipDrawPhase(lord) and self:getOverflow(lord)<0)) then return end
        sgs.updateIntention(player,lord,10)
    end
end


sgs.ai_skill_invoke.qiaomeng = function(self,data)
    local damage = data:toDamage()
    if self:isFriend(damage.to) then return damage.to:getArmor() and self:needToThrowArmor(damage.to) end
    return self:doDisCard(damage.to,"e")
end


function sgs.ai_skill_invoke.wangxi(self,data)
    local target = data:toPlayer()
    if target then
        if self:isFriend(target) and not self:needKongcheng(target)
        then return true
        else
            if not(call(target,"getPhase")~=sgs.Player_NotActive and (call(target,"hasSkills",sgs.Active_cardneed_skill) or call(target,"hasWeapon","Crossbow")))
            and not(call(target,"getPhase")==sgs.Player_NotActive and call(target,"hasSkills",sgs.notActive_cardneed_skill))
            or self:needKongcheng(target)
            then return true end
        end
    end
end


sgs.ai_can_damagehp.wangxi = function(self,from,card,to)
    if from and call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
    and self:canLoseHp(from,card,to) then return self:isFriend(from) end
end


sgs.ai_skill_cardask["@zhuhai-slash"] = function(self,data,pattern,target,target2)
    for _,slash in ipairs(self:getCards("Slash"))do
        if self:isFriend(target2) and self:slashIsEffective(slash,target2) then
            if self:findLeijiTarget(target2,50,self.player) then return slash end
            if self:needToLoseHp(target2,self.player,slash) then return slash end
        end

        local nature = sgs.DamageStruct_Normal
        if call(slash,"isKindOf","FireSlash") then nature = sgs.DamageStruct_Fire
        elseif call(slash,"isKindOf","ThunderSlash") then nature = sgs.DamageStruct_Thunder end
        if self:isEnemy(target2) and self:slashIsEffective(slash,target2) and self:canAttack(target2,self.player,nature)
        and not self:needToLoseHp(target2,self.player,slash) and not self:findLeijiTarget(target2,50,self.player)
        then
            return slash
        end
    end
    return "."
end


sgs.ai_skill_choice.jianyan = function(self,choices)
    local remembered=self:getStrategyMemory("jianyan_choice")
    if self.jianyan_choice or remembered then return self.jianyan_choice or remembered end
    for _,friend in ipairs(self.friends)do
        if call(friend,"isMale") and not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then
            if call(friend,"getHandcardNum")<3 and call(friend,"getEquips"):length()<2 then return "equip" end
        end
    end
    for _,friend in ipairs(self.friends)do
        if call(friend,"isMale") and not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then
            if call(friend,"hasSkills","jizhi|nosjizhi|jilve") then return "trick" end
        end
    end
    local rand = math.random(0,100)
    if rand>60 then return "trick"
    elseif rand>35 then return "red"
    elseif rand>10 then return "equip"
    elseif rand>2 then return "basic"
    else return "black"
    end
end


sgs.ai_skill_playerchosen.jianyan = function(self,targets)
    local remembered=source_player(self,"jianyan_enemy")
    if self.jianyan_enemy or remembered then return self.jianyan_enemy or remembered end

    local id = call(self.player,"getStrategyMark","jianyan")
    local card = visible_card(self,id)
    local cards = { card }
    local c,friend = self:getCardNeedPlayer(cards,self.friends)
    if friend then return friend end

    self.friends = self:sort(self.friends)
    for _,friend in ipairs(self.friends)do
        if call(friend,"isMale") and self:isValuableCard(card,friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then return friend end
    end
    for _,friend in ipairs(self.friends)do
        if call(friend,"isMale") and self:isWeak(friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then return friend end
    end
    local trash = call(card,"isKindOf","EquipCard") or call(card,"isKindOf","Disaster") or call(card,"isKindOf","GodSalvation") or call(card,"isKindOf","AmazingGrace") or call(card,"isKindOf","Slash")
    if trash then
        for _,enemy in ipairs(self.enemies)do
            if call(enemy,"isMale") and call(enemy,"getPhase")>sgs.Player_Play and self:needKongcheng(enemy,true) and not hasManjuanEffect(enemy) then return enemy end
        end
    end
    for _,friend in ipairs(self.friends)do
        if call(friend,"isMale") and not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then return friend end
    end
end


sgs.ai_playerchosen_intention.yajiao = function(self,from,to)
    if not self:needKongcheng(to,true) and not hasManjuanEffect(to) then sgs.updateIntention(from,to,-50) end
end


sgs.ai_general_choice_for_lord["nos_liubei"] = function(ai, generals, default_choice, lord)
    local role = call(ai.player,"getRole")
    local general_scores = {}
    for _, general_name in ipairs(generals) do
        local score = 0
        local general = general_info(ai,general_name)

        if general then
            local kingdom = call(general,"getKingdom")
            local desc = general:getSkillDescription(true) or ""

            if role == "loyalist" and kingdom == "shu" then
                score = score + 5
                if string.find(desc, "杀") then score = score + 3 end
            end

            local strategy_func = sgs.ai_general_choice[general_name]
            if type(strategy_func) == "function" then
                local recommend = strategy_func(ai, lord, role)
                if recommend == 1 then
                    score = score + 10
                elseif recommend == -1 then
                    score = score - 10
                end
            end
        end

        table.insert(general_scores, {name = general_name, score = score})
    end

    table.sort(general_scores, function(a, b) return a.score > b.score end)
    local best_score = general_scores[1] and general_scores[1].score or 0
    local best_generals = {}
    for _, gs in ipairs(general_scores) do
        if gs.score == best_score then
            table.insert(best_generals, gs.name)
        else
            break
        end
    end

    if #best_generals > 0 then
        return best_generals[math.random(1, #best_generals)]
    end

    return #generals > 0 and generals[math.random(1, #generals)] or default_choice
end


sgs.ai_general_choice_for_lord["guojia"] = function(ai, generals, default_choice, lord)
    local scores = hp_loss_lord_strategy_scores(ai, generals, lord, false)
    return select_best_general(scores, default_choice)
end


sgs.ai_general_choice_for_lord["nos_guojia"] = function(ai, generals, default_choice, lord)
    local scores = hp_loss_lord_strategy_scores(ai, generals, lord, false)
    return select_best_general(scores, default_choice)
end


sgs.ai_general_choice_for_lord["simayi"] = function(ai, generals, default_choice, lord)
    local scores = hp_loss_lord_strategy_scores(ai, generals, lord, false)
    return select_best_general(scores, default_choice)
end


sgs.ai_general_choice_for_lord["nos_simayi"] = function(ai, generals, default_choice, lord)
    local scores = hp_loss_lord_strategy_scores(ai, generals, lord, false)
    return select_best_general(scores, default_choice)
end


sgs.ai_general_choice_for_lord["xiahoudun"] = function(ai, generals, default_choice, lord)
    local scores = hp_loss_lord_strategy_scores(ai, generals, lord, false)
    return select_best_general(scores, default_choice)
end


sgs.ai_general_choice_for_lord["nos_xiahoudun"] = function(ai, generals, default_choice, lord)
    local scores = hp_loss_lord_strategy_scores(ai, generals, lord, false)
    return select_best_general(scores, default_choice)
end


sgs.ai_general_choice_for_lord["keolmou_yuanshao"] = function(ai, generals, default_choice, lord)
    local role = call(ai.player,"getRole")
    local general_scores = {}
    for _, general_name in ipairs(generals) do
        local score = 0
        local general = general_info(ai,general_name)

        if general then
            local desc = general:getSkillDescription(true) or ""
            local hp = call(general,"getMaxHp")

            if role == "loyalist" then
                if string.find(desc, "闪") then score = score + 3 end
                if string.find(desc, "受到伤害") and string.find(desc, "摸") then score = score + 5 end
                if hp >= 4 then score = score + 3 end
            else
                if string.find(desc, "受到伤害") then score = score + 5 end
            end

            local strategy_func = sgs.ai_general_choice[general_name]
            if type(strategy_func) == "function" then
                local recommend = strategy_func(ai, lord, role)
                if recommend == 1 then
                    score = score + 10
                elseif recommend == -1 then
                    score = score - 10
                end
            end
        end

        table.insert(general_scores, {name = general_name, score = score})
    end

    table.sort(general_scores, function(a, b) return a.score > b.score end)
    local best_score = general_scores[1] and general_scores[1].score or 0
    local best_generals = {}
    for _, gs in ipairs(general_scores) do
        if gs.score == best_score then
            table.insert(best_generals, gs.name)
        else
            break
        end
    end

    if #best_generals > 0 then
        return best_generals[math.random(1, #best_generals)]
    end

    return #generals > 0 and generals[math.random(1, #generals)] or default_choice
end


sgs.ai_general_choice["nos_xiahoudun"] = function(ai, lord, role)
    if role == "loyalist" then return -1 end
    return 0
end


sgs.ai_general_choice["nos_huanggai"] = function(ai, lord, role)
    local seat = call(ai.player,"getSeat")
    if seat > 4 then return -1 end
    return 0
end


sgs.ai_general_choice["liubei"] = function(ai, lord, role)
    if role == "renegade" then return -1 end
    return 0
end


sgs.ai_general_choice["nos_liubei"] = function(ai, lord, role)
    if role == "renegade" then return -1 end
    return 0
end


-- Shared selection policies; no skill action is bound during planning.
local function target_views(self,names)
    local result=AIList.new({})
    for _,name in ipairs(names)do result[#result+1]=player_name(self,name,"selected target") end
    return result
end
function SmartAIView:selectNosTuxiTargets(prompt)
    self.enemies = self:sort(self.enemies,"handcard_defense")
    local targets = {}

    local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
    local luxun = self.room:findPlayerBySkillName("noslianying")
    local dengai = self.room:findPlayerBySkillName("tuntian")
    local jiangwei = self.room:findPlayerBySkillName("zhiji")
    local zhijiangwei = self.room:findPlayerBySkillName("beifa")

    local add_player = function (player,isfriend)
        if call(player,"getHandcardNum")==0 or call(player,"objectName")==call(self.player,"objectName") then return #targets end
        if self:objectiveLevel(player)==0 and call(player,"isLord") and call(self,"getRoleCounts")["rebel"]>1 then return #targets end
        if #targets==0 then
            table.insert(targets,call(player,"objectName"))
        elseif #targets==1 then
            if call(player,"objectName")~=targets[1] then
                table.insert(targets,call(player,"objectName"))
            end
        end
        if isfriend and isfriend==1 then
            self:setStrategyPlayerFlag(self.player,"nostuxi_isfriend_"..call(player,"objectName"),true)
        end
        return #targets
    end

    local lord = self.room:getLord()
    if lord and self:isEnemy(lord) and turncount(self)<=1 and not call(lord,"isKongcheng") then
        add_player(lord)
    end

    if jiangwei and self:isFriend(jiangwei) and call(jiangwei,"getStrategyMark","zhiji")==0 and call(jiangwei,"getHandcardNum")==1
            and self:getEnemyNumBySeat(self.player,jiangwei)<=(call(jiangwei,"getHp")>=3 and 1 or 0) then
        if add_player(jiangwei,1)==2  then return target_views(self,targets) end
    end

    if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai)==0 )
            and call(dengai,"hasSkill","zaoxian") and call(dengai,"getStrategyMark","zaoxian")==0 and call(dengai,"getPile","field"):length()==2 and add_player(dengai,1)==2 then
        return target_views(self,targets)
    end

    if zhugeliang and self:isFriend(zhugeliang) and call(zhugeliang,"getHandcardNum")==1 and self:getEnemyNumBySeat(self.player,zhugeliang)>0 then
        if call(zhugeliang,"getHp")<=2 then
            if add_player(zhugeliang,1)==2 then return target_views(self,targets) end
        else
            local flag = string.format("%s_%s_%s","visible",call(self.player,"objectName"),call(zhugeliang,"objectName"))
            local cards = sgs.QList2Table(strategy_cards(self,zhugeliang,"h"))
            if #cards==1 and (call(cards[1],"hasFlag","visible") or call(cards[1],"hasFlag",flag)) then
                if call(cards[1],"isKindOf","TrickCard") or call(cards[1],"isKindOf","Slash") or call(cards[1],"isKindOf","EquipCard") then
                    if add_player(zhugeliang,1)==2 then return target_views(self,targets) end
                end
            end
        end
    end

    if luxun and self:isFriend(luxun) and call(luxun,"getHandcardNum")==1 and self:getEnemyNumBySeat(self.player,luxun)>0 then
        local flag = string.format("%s_%s_%s","visible",call(self.player,"objectName"),call(luxun,"objectName"))
        local cards = sgs.QList2Table(strategy_cards(self,luxun,"h"))
        if #cards==1 and (call(cards[1],"hasFlag","visible") or call(cards[1],"hasFlag",flag)) then
            if call(cards[1],"isKindOf","TrickCard") or call(cards[1],"isKindOf","Slash") or call(cards[1],"isKindOf","EquipCard") then
                if add_player(luxun,1)==2  then return target_views(self,targets) end
            end
        end
    end

    if zhijiangwei and self:isFriend(zhijiangwei) and call(zhijiangwei,"getHandcardNum")==1 and
        self:getEnemyNumBySeat(self.player,zhijiangwei)<=(call(zhijiangwei,"getHp")>=3 and 1 or 0) then
        local isGood
            local slash = call(self,"getEvaluationCard","slash")
        for _,enemy in ipairs(self.enemies)do
            if call(zhijiangwei,"canSlash",enemy,slash) and not self:slashProhibit(slash,enemy,zhijiangwei)
            and self:isGoodTarget(enemy,self.enemies,slash) and self:getDefenseSlash(enemy)<4 then
                isGood = true
            end
        end
        if isGood and add_player(zhijiangwei,1)==2  then return target_views(self,targets) end
    end

    for i = 1,#self.enemies,1 do
        local p = self.enemies[i]
        local cards = sgs.QList2Table(strategy_cards(self,p,"h"))
        local flag = string.format("%s_%s_%s","visible",call(self.player,"objectName"),call(p,"objectName"))
        for _,card in ipairs(cards)do
            if (call(card,"hasFlag","visible") or call(card,"hasFlag",flag)) and (call(card,"isKindOf","Peach") or call(card,"isKindOf","Nullification") or call(card,"isKindOf","Analeptic") ) then
                if add_player(p)==2  then return target_views(self,targets) end
            end
        end
    end

    for i = 1,#self.enemies,1 do
        local p = self.enemies[i]
        if call(p,"hasSkills","jijiu|qingnang|xinzhan|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
            if add_player(p)==2  then return target_views(self,targets) end
        end
    end

    for i = 1,#self.enemies,1 do
        local p = self.enemies[i]
        local x = call(p,"getHandcardNum")
        local good_target = true
        if x==1 and self:needKongcheng(p) then good_target = false end
        if x>=2 and call(p,"hasSkill","tuntian") and call(p,"hasSkill","zaoxian",true) then good_target = false end
        if good_target and add_player(p)==2 then return target_views(self,targets) end
    end


    if luxun and add_player(luxun,(self:isFriend(luxun) and 1 or nil))==2 then
        return target_views(self,targets)
    end

    if dengai and self:isFriend(dengai) and call(dengai,"hasSkill","zaoxian") and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai)==0 ) and add_player(dengai,1)==2 then
        return target_views(self,targets)
    end

    local others = call(self.room,"getOtherPlayers",self.player)
    for _,other in sgs.qlist(others)do
        if self:objectiveLevel(other)>=0 and not(call(other,"hasSkill","tuntian") and call(other,"hasSkill","zaoxian",true)) and add_player(other)==2 then
            return target_views(self,targets)
        end
    end

    for _,other in sgs.qlist(others)do
        if self:objectiveLevel(other)>=0 and not(call(other,"hasSkill","tuntian") and call(other,"hasSkill","zaoxian",true)) and add_player(other)==1 and math.random(0,5)<=1 and not call(self,"hasSkills","qiaobian") then
            return target_views(self,targets)
        end
    end

    return {}
end


function SmartAIView:selectZhihengCosts()
    local unpreferedCards = {}
    local cards = sgs.QList2Table(strategy_cards(self,self.player,"h"))

    if call(self.player,"getHp")<3 then
        local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
        -- QVariant::toBool of the own tag (it holds the acquired skill name).
        local wansha = self.player:getTag("JilveWansha")
        local keep_slash = wansha~=nil and wansha~=false and wansha~=""
        for _,zcard in sgs.list(strategy_cards(self,self.player,"he"))do
            if not isCard("Peach",zcard,self.player)
            then
                local shouldUse = true
                if isCard("Slash",zcard,self.player)
                and not use_slash
                then
                    local dummy_use = self:aiUseCard(zcard)
                    if dummy_use.card then
                        if keep_slash then shouldUse = false end
                        if dummy_use.to then
                            for _,p in sgs.list(dummy_use.to)do
                                if call(p,"getHp")<=1 then
                                    shouldUse = false
                                    if call(self.player,"distanceTo",p)>1 then keep_weapon = self.player:getWeapon() end
                                    break
                                end
                            end
                            if dummy_use.to:length()>1 then shouldUse = false end
                        end
                        if not self:isWeak() then shouldUse = false end
                        if not shouldUse then use_slash = true end
                    end
                end
                if call(zcard,"getTypeId")==sgs.Card_TypeTrick then
                    if self:aiUseCard(zcard).card then shouldUse = false end
                end
                if call(zcard,"getTypeId")==sgs.Card_TypeEquip and not call(self.player,"hasEquip",zcard) then
                    if self:aiUseCard(zcard).card then shouldUse = false end
                    if keep_weapon and call(zcard,"getEffectiveId")==call(keep_weapon,"getEffectiveId") then shouldUse = false end
                end
                if call(self.player,"hasEquip",zcard) and call(zcard,"isKindOf","Armor") and not self:needToThrowArmor() then shouldUse = false end
                if call(self.player,"hasEquip",zcard) and call(zcard,"isKindOf","DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
                if call(self.player,"hasEquip",zcard) and call(zcard,"isKindOf","WoodenOx") and call(self.player,"getPile","wooden_ox"):length()>1 then shouldUse = false end
                if isCard("Jink",zcard,self.player) and not keep_jink then
                    keep_jink = true
                    shouldUse = false
                end
                if call(self.player,"getHp")<2 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
                    keep_analeptic = true
                    shouldUse = false
                end
                if shouldUse then table.insert(unpreferedCards,call(zcard,"getId")) end
            end
        end
    end

    if #unpreferedCards<1 then
        local use_slash_num = 0
        cards = self:sortByKeepValue(cards)
        for _,card in ipairs(cards)do
            if call(card,"isKindOf","Slash") then
                local will_use = false
                if use_slash_num<=call(card,"getTargetModResidue",self.player)
                then
                    if self:aiUseCard(card).card then
                        will_use = true
                        use_slash_num = use_slash_num+1
                    end
                end
                if not will_use then table.insert(unpreferedCards,call(card,"getId")) end
            end
        end

        local num = self:getCardsNum("Jink")-1
        if self.player:getArmor() then num = num+1 end
        if num>0 then
            for _,card in ipairs(cards)do
                if call(card,"isKindOf","Jink") and num>0 then
                    table.insert(unpreferedCards,call(card,"getId"))
                    num = num-1
                end
            end
        end
        for _,card in ipairs(cards)do
            if call(card,"isKindOf","Weapon") and call(self.player,"getHandcardNum")<3
            or self:getSameEquip(card,self.player)
            or call(card,"isKindOf","OffensiveHorse")
            or call(card,"isKindOf","AmazingGrace")
            then table.insert(unpreferedCards,call(card,"getId"))
            elseif call(card,"getTypeId")==sgs.Card_TypeTrick then
                if not self:aiUseCard(card).card then table.insert(unpreferedCards,call(card,"getId")) end
            end
        end

        if self.player:getWeapon() and call(self.player,"getHandcardNum")<3 then
            table.insert(unpreferedCards,self.player:getWeapon():getId())
        end

        if self:needToThrowArmor() then
            table.insert(unpreferedCards,self.player:getArmor():getId())
        end

        if self.player:getOffensiveHorse() and self.player:getWeapon() then
            table.insert(unpreferedCards,self.player:getOffensiveHorse():getId())
        end
    end

    for i = #unpreferedCards,1,-1 do
        if visible_card(self,unpreferedCards[i]):isKindOf("WoodenOx") and call(self.player,"getPile","wooden_ox"):length()>1 then
            table.removeOne(unpreferedCards,unpreferedCards[i])
        end
    end

    local use_cards = {}
    for i = #unpreferedCards,1,-1 do
        if not call(self.player,"isJilei",visible_card(self,unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
    end

    if #use_cards>0 then
        if call(self.room,"getMode")=="02_1v1" and call(self.room,"getDuelRule")~="Classical" then
            local use_cards_kof = {use_cards[1]}
            if #use_cards>1 then table.insert(use_cards_kof,use_cards[2]) end
            return use_cards_kof
        else
            return use_cards
        end
    end
    return {}
end

local function caocao_lord_strategy(ai, generals, default_choice, lord)
    local role = call(ai.player,"getRole")
    local general_scores = {}
    for _, general_name in ipairs(generals) do
        local score = 0
        local general = general_info(ai,general_name)

        if general then
            local kingdom = call(general,"getKingdom")
            local desc = general:getSkillDescription(true) or ""

            if role == "loyalist" then
                if kingdom == "wei" then score = score + 5 end
                if string.find(desc, "造成过") then score = score + 3 end
                if string.find(desc, "万箭齐发") or string.find(desc, "南蛮入侵") then score = score + 3 end
            elseif role == "rebel" then
                if string.find(desc, "失效") then score = score + 5 end
                if string.find(desc, "乐不思蜀") then score = score + 3 end
            end

            local strategy_func = sgs.ai_general_choice[general_name]
            if type(strategy_func) == "function" then
                local recommend = strategy_func(ai, lord, role)
                if recommend == 1 then
                    score = score + 10
                elseif recommend == -1 then
                    score = score - 10
                end
            end
        end

        table.insert(general_scores, {name = general_name, score = score})
    end

    table.sort(general_scores, function(a, b) return a.score > b.score end)
    local best_score = general_scores[1] and general_scores[1].score or 0
    local best_generals = {}
    for _, gs in ipairs(general_scores) do
        if gs.score == best_score then
            table.insert(best_generals, gs.name)
        else
            break
        end
    end

    if #best_generals > 0 then
        return best_generals[math.random(1, #best_generals)]
    end

    return #generals > 0 and generals[math.random(1, #generals)] or default_choice
end

local function caopi_lord_strategy(ai, generals, default_choice, lord)
    local role = call(ai.player,"getRole")
    local general_scores = {}
    for _, general_name in ipairs(generals) do
        local score = 0
        local general = general_info(ai,general_name)

        if general then
            local kingdom = call(general,"getKingdom")
            local desc = general:getSkillDescription(true) or ""
            if role == "loyalist" or role == "renegade" or role == "villager" then
                if kingdom == "wei" and string.find(desc, "判定") then score = score + 3 end
                if string.find(desc, "万箭齐发") then score = score + 6 end
            end

            local strategy_func = sgs.ai_general_choice[general_name]
            if type(strategy_func) == "function" then
                local recommend = strategy_func(ai, lord, role)
                if recommend == 1 then
                    score = score + 10
                elseif recommend == -1 then
                    score = score - 10
                end
            end
        end

        table.insert(general_scores, {name = general_name, score = score})
    end

    table.sort(general_scores, function(a, b) return a.score > b.score end)
    local best_score = general_scores[1] and general_scores[1].score or 0
    local best_generals = {}
    for _, gs in ipairs(general_scores) do
        if gs.score == best_score then
            table.insert(best_generals, gs.name)
        else
            break
        end
    end

    if #best_generals > 0 then
        return best_generals[math.random(1, #best_generals)]
    end

    return #generals > 0 and generals[math.random(1, #generals)] or default_choice
end
sgs.ai_general_choice_for_lord.caocao=caocao_lord_strategy
sgs.ai_general_choice_for_lord.nos_caocao=caocao_lord_strategy
sgs.ai_general_choice_for_lord.double_fuck=caocao_lord_strategy
sgs.ai_general_choice_for_lord.caopi=caopi_lord_strategy
sgs.ai_general_choice_for_lord.mobile_caopi=caopi_lord_strategy

function nosganglie_discard(self,discard_num,min_num,optional,include_equip,skillName)
    local xiahou = self.room:findPlayerBySkillName(skillName)
    if xiahou and (not self:damageIsEffective(self.player,sgs.DamageStruct_Normal,xiahou) or self:needToLoseHp(self.player,xiahou)) then return {} end
    if xiahou and self:needToLoseHp(self.player,xiahou) then return {} end
    local to_discard = {}
    local cards = sgs.QList2Table(strategy_cards(self,self.player,"h"))
    local index = 0
    local all_peaches = 0
    for _,card in ipairs(cards)do
        if isCard("Peach",card,self.player) then
            all_peaches = all_peaches+1
        end
    end
    if all_peaches>=2 and self:getOverflow()<=0 then return {} end
    cards = self:sortByKeepValue(cards)
    cards = sgs.reverse(cards)

    for i = #cards,1,-1 do
        local card = cards[i]
        if not isCard("Peach",card,self.player) and not call(self.player,"isJilei",card) then
            table.insert(to_discard,call(card,"getEffectiveId"))
            table.remove(cards,i)
            index = index+1
            if index==2 then break end
        end
    end
    if #to_discard<2 then return {}
    else
        return to_discard
    end
end

function SmartAIView:resetCards(cards,except)
    local result = {}
    for _,c in ipairs(cards)do
        if call(c,"getEffectiveId")==call(except,"getEffectiveId") then continue
        else table.insert(result,c) end
    end
    return result
end

function SmartAIView:shouldUseRende()
    if (self:hasCrossbowEffect() or self:getCardsNum("Crossbow")>0)
    and self:getCardsNum("Slash")>0 then
        self.enemies = self:sort(self.enemies,"defense")
        for _,enemy in ipairs(self.enemies)do
            if call(self.player,"distanceTo",enemy)==1 or call(self.player,"distanceTo",enemy)==2
            and self:getCardsNum("OffensiveHorse")>0 and not self.player:getOffensiveHorse()
            and self:isGoodTarget(enemy,self.enemies) then
                local slash_count = 0
                for _,slash in ipairs(self:getCards("Slash"))do
                    if not self:slashProhibit(slash,enemy) and self:slashIsEffective(slash,enemy)
                    then slash_count = slash_count+1 end
                end
                if slash_count>=call(enemy,"getHp") then return false end
            end
        end
    end
    for _,enemy in ipairs(self.enemies)do
        if call(enemy,"canSlash",self.player) and not self:slashProhibit(nil,self.player,enemy) then
            if call(enemy,"hasWeapon","guding_blade") and call(self.player,"getHandcardNum")==1
            and getCardsNum("Slash",enemy)>=1 then return
            elseif self:hasCrossbowEffect(enemy) and getCardsNum("Slash",enemy)>1
            and self:getOverflow()<=0 then return end
        end
    end
    for _,player in ipairs(self.friends_noself)do
        if call(player,"hasSkill","haoshi") and not call(player,"containsTrick","supply_shortage")
        or call(player,"hasSkill","jijiu") then return true end
    end
    local keepNum = 1
    if call(self.player,"getStrategyMark","rende")+call(self.player,"getStrategyMark","nosrende")<1 then
        if call(self.player,"getHandcardNum")==3 then keepNum = 0 end
        if call(self.player,"getHandcardNum")>3 then keepNum = 3 end
    end
    if call(self.player,"hasSkill","kongcheng") then keepNum = 0 end
    if self:getOverflow()>0 then return true end
    if call(self.player,"getHandcardNum")>keepNum then return true end
    if call(self.player,"getStrategyMark","rende")>0 and call(self.player,"getStrategyMark","rende")<2
    and (2-call(self.player,"getStrategyMark","rende"))>=(call(self.player,"getHandcardNum")-keepNum)
    then return true end
    if call(self.player,"getStrategyMark","nosrende")>0 and call(self.player,"getStrategyMark","nosrende")<2
    and (2-call(self.player,"getStrategyMark","nosrende"))>=(call(self.player,"getHandcardNum")-keepNum)
    then return true end
end

function SmartAIView:getJijiangSlashNum(player)
    if not player then return 0 end
    if not call(player,"hasLordSkill","jijiang") and not call(player,"hasLordSkill","oljijiang") then return 0 end
    local slashs = 0
    for _,p in sgs.list(call(self.room,"getOtherPlayers",player))do
        if call(p,"getKingdom")=="shu" and ((turncount(self)<=1 and current_role(self,p)=="neutral") or self:isFriend(player,p)) then
            slashs = slashs+getCardsNum("Slash",p,self.player)
        end
    end
    return slashs
end

sgs.ai_choicemade_filter.cardChosen.nosfankui = function(self,player,promptlist)
    local damage = current_damage(self)
    if damage.from then
        local intention = 10
        local card = visible_card(self,promptlist[3])
        if call(card,"isKindOf","Armor") and self:needToThrowArmor(damage.from)
        and self.room:getCardPlace(promptlist[3])==sgs.Player_PlaceEquip
        then intention = -intention
        elseif not self:doDisCard(damage.from,"he") then intention = -intention
        elseif call(card,"isKindOf","EquipCard") and call(self,"hasSkills",sgs.lose_equip_skill,damage.from)
        and self.room:getCardPlace(promptlist[3])==sgs.Player_PlaceEquip
        and call(damage.from,"getEquips"):length()>0 then intention = -intention
        elseif sgs.ai_need_damaged.nosfankui(self,damage.from,player)
        or self:getOverflow(damage.from)>2
        then intention = 0 end
        sgs.updateIntention(player,damage.from,intention)
    end
end

sgs.ai_skill_cardchosen.nosfankui = function(self,who,flags)
    local suit = sgs.ai_need_damaged.nosfankui(self,who,self.player)
    if not suit then return -1 end

    local cards = sgs.QList2Table(call(who,"getEquips"))
    local handcards = sgs.QList2Table(strategy_cards(self,who,"h"))
    if call(who,"getHandcardNum")==1 and #handcards==1 and call(handcards[1],"hasFlag","visible") then table.insert(cards,handcards[1]) end

    for i=1,#cards do
        if (call(cards[i],"getSuit")==suit and suit~=sgs.Card_Spade) or
            (call(cards[i],"getSuit")==suit and suit==sgs.Card_Spade and call(cards[i],"getNumber")>=2 and call(cards[i],"getNumber")<=9) then
            return call(cards[i],"getId")
        end
    end
    return -1
end

sgs.ai_choicemade_filter.cardChosen.fankui = function(self,player,promptlist)
    local damage = current_damage(self)
    if damage.from then
        local intention = 10
        local card = visible_card(self,promptlist[3])
        if call(card,"isKindOf","Armor") and self:needToThrowArmor(damage.from)
        and self.room:getCardPlace(promptlist[3])==sgs.Player_PlaceEquip
        then intention = -intention
        elseif not self:doDisCard(damage.from,"he") then intention = -intention
        elseif call(card,"isKindOf","EquipCard") and call(self,"hasSkills",sgs.lose_equip_skill,damage.from)
        and self.room:getCardPlace(promptlist[3])==sgs.Player_PlaceEquip
        and call(damage.from,"getEquips"):length()>0 then intention = -intention
        elseif sgs.ai_need_damaged.fankui(self,damage.from,player)
        or self:getOverflow(damage.from)>2
        then intention = 0 end
        sgs.updateIntention(player,damage.from,intention)
    end
end

sgs.ai_skill_cardchosen.fankui = function(self,who,flags)
    local suit = sgs.ai_need_damaged.fankui(self,who,self.player)
    if not suit then return -1 end

    local cards = sgs.QList2Table(call(who,"getEquips"))
    local handcards = sgs.QList2Table(strategy_cards(self,who,"h"))
    if call(who,"getHandcardNum")==1 and #handcards==1 and call(handcards[1],"hasFlag","visible") then table.insert(cards,handcards[1]) end

    for i=1,#cards,1 do
        if (call(cards[i],"getSuit")==suit and suit~=sgs.Card_Spade) or
            (call(cards[i],"getSuit")==suit and suit==sgs.Card_Spade and call(cards[i],"getNumber")>=2 and call(cards[i],"getNumber")<=9) then
            return call(cards[i],"getId")
        end
    end
    return -1
end

sgs.ai_choicemade_filter.skillInvoke.nosganglie = function(self,player,promptlist)
    local damage = current_damage(self)
    if damage.from and damage.to then
        if promptlist[#promptlist]=="yes" then
            if not self:needToLoseHp(damage.from,player,damage.card) then
                sgs.updateIntention(damage.to,damage.from,40)
            end
        elseif self:canAttack(damage.from) then
            sgs.updateIntention(damage.to,damage.from,-40)
        end
    end
end

sgs.ai_choicemade_filter.skillInvoke.ganglie = function(self,player,promptlist)
    local damage = current_damage(self)
    if damage.from and damage.to then
        if promptlist[#promptlist]=="yes" then
            if not self:needToLoseHp(damage.from,player,damage.card) then
                sgs.updateIntention(damage.to,damage.from,40)
            end
        elseif self:canAttack(damage.from) then
            sgs.updateIntention(damage.to,damage.from,-40)
        end
    end
end

sgs.ai_choicemade_filter.skillInvoke.wangxi = function(self,player,promptlist)
    local damage = current_damage(self)
    local target = nil
    if damage.from==player then target = damage.to
    elseif damage.to==player then target = damage.from end
    if target and promptlist[3]=="yes" then
        if self:needKongcheng(target,true) then sgs.updateIntention(player,target,10)
        elseif not hasManjuanEffect(target) and call(player,"getState")=="robot"
        then sgs.updateIntention(player,target,-60) end
    end
end

sgs.ai_skill_invoke.nosganglie = function(self,data)
    local mode = call(self.room,"getMode")
    if mode:find("_mini_41") or mode:find("_mini_46") then return true end
    local damage = data:toDamage()
    if not damage.from then
        local zhangjiao = self.room:findPlayerBySkillName("guidao")
        return zhangjiao and self:isFriend(zhangjiao) and not call(zhangjiao,"isNude")
    end
    if self:needToLoseHp(damage.from,self.player,damage.card) then
        if self:isFriend(damage.from) then
            self:setStrategyMemory("nosganglie_effect",string.format("%s_%s_%d",call(self.player,"objectName"),call(damage.from,"objectName"),turncount(self)))
            return true
        end
        return false
    end
    return not self:isFriend(damage.from) and self:canAttack(damage.from)
end

sgs.ai_skill_invoke.ganglie = function(self,data)
    local mode = call(self.room,"getMode")
    if mode:find("_mini_41") or mode:find("_mini_46") then return true end
    local damage = data:toDamage()
    if not damage.from then
        local zhangjiao = self.room:findPlayerBySkillName("guidao")
        return zhangjiao and self:isFriend(zhangjiao) and not call(zhangjiao,"isNude")
    end
    if self:needToLoseHp(damage.from,self.player,damage.card) then
        if self:isFriend(damage.from) then
            self:setStrategyMemory("ganglie_effect",string.format("%s_%s_%d",call(self.player,"objectName"),call(damage.from,"objectName"),turncount(self)))
            return true
        end
        return false
    end
    return not self:isFriend(damage.from)
end

sgs.ai_skill_invoke.jijiang = function(self,data)
    if source_player(self,"jijiangsource") then return false end

    local current = self.room:getCurrent()
    if self:isFriend(current) and call(current,"getKingdom")=="shu" and self:getOverflow(current)>2 and not self:hasCrossbowEffect(current) then
        return true
    end

    for _,card in sgs.list(strategy_cards(self,self.player,"h"))do
        if isCard("Slash",card,self.player) then
            return false
        end
    end

    for _,p in sgs.list(call(self.room,"getLieges","shu",self.player))do
        if not self:isEnemy(p) then
            return true
        end
    end
end

sgs.ai_choicemade_filter.cardUsed.JijiangCard=function(self,player,carduse)remember_source(self,"jijiangsource",player)end
sgs.ai_choicemade_filter.skillInvoke.jijiang=function(self,player,promptlist)
    if promptlist[#promptlist]=="yes"then remember_source(self,"jijiangsource",player)end
end
sgs.ai_choicemade_filter.cardResponded["@jijiang-slash"]=function(self,player,promptlist)
    local source=source_player(self,"jijiangsource")
    if promptlist[#promptlist]~=""then
        sgs.updateIntention(player,source,-40)
        remember_source(self,"jijiangsource",nil);self:setStrategyMemory("jijiangtarget",nil)
    elseif source then
        local lieges=call(self.room,"getLieges","shu",source)
        if #lieges==0 then error("donor Jijiang empty lieges:last()",0)end
        if call(player,"objectName")==call(lieges[#lieges],"objectName")then
            remember_source(self,"jijiangsource",nil);self:setStrategyMemory("jijiangtarget",nil)
        end
    end
end

function SmartAIView:findLijianTarget(card_name,use)
    local lord = self.room:getLord()
    local duel = call(self,"getEvaluationCard","duel")

    local findFriend_maxSlash = function(self,first)

        local maxSlash = 0
        local friend_maxSlash
        local nos_fazheng,fazheng
        for _,friend in ipairs(self.friends_noself)do
            if call(friend,"isMale") and self:hasTrickEffective(duel,first,friend) then
                if call(friend,"hasSkill","nosenyuan") and call(friend,"getHp")>1 then nos_fazheng = friend end
                if call(friend,"hasSkill","enyuan") and call(friend,"getHp")>1 then fazheng = friend end
                if (getCardsNum("Slash",friend)>maxSlash) then
                    maxSlash = getCardsNum("Slash",friend)
                    friend_maxSlash = friend
                end
            end
        end

        if friend_maxSlash then
            local safe = false
            if call(self,"hasSkills","neoganglie|vsganglie|fankui|enyuan|ganglie|nosenyuan",first) and not call(self,"hasSkills","wuyan|noswuyan",first) then
                if (call(first,"getHp")<=1 and call(first,"getHandcardNum")==0) then safe = true end
            elseif (getCardsNum("Slash",friend_maxSlash)>=getCardsNum("Slash",first)) then safe = true end
            if safe then return friend_maxSlash end
        else self:log("unfound")
        end
        if nos_fazheng or fazheng then  return nos_fazheng or fazheng end       --备用友方，各种恶心的法正
        return nil
    end

    if self.role=="rebel" or (self.role=="renegade" and call(self,"getRoleCounts")["loyalist"]+1>call(self,"getRoleCounts")["rebel"]) then

        if lord and call(lord,"isMale") and not call(lord,"isNude") and call(lord,"objectName")~=call(self.player,"objectName") then      -- 优先离间1血忠和主
            self.enemies = self:sort(self.enemies,"handcard")
            local e_peaches = 0
            local loyalist

            for _,enemy in ipairs(self.enemies)do
                e_peaches = e_peaches+getCardsNum("Peach",enemy)
                if call(enemy,"getHp")==1 and self:hasTrickEffective(duel,enemy,lord) and call(enemy,"objectName")~=call(lord,"objectName")
                and call(enemy,"isMale") and not loyalist then
                    loyalist = enemy
                    break
                end
            end

            if loyalist and e_peaches<1 then return loyalist,lord end
        end

        if #self.friends_noself>=2 and self:getAllPeachNum()<1 then     --收友方反
            local nextplayerIsEnemy
            local nextp = self.player:getNextAlive()
            for i = 1,call(self.room,"alivePlayerCount")do
                if not self:willSkipPlayPhase(nextp) then
                    if not self:isFriend(nextp) then nextplayerIsEnemy = true end
                    break
                else
                    nextp = nextp:getNextAlive()
                end
            end
            if nextplayerIsEnemy then
                local round = 50
                local to_die,nextfriend
                self.enemies = self:sort(self.enemies,"hp")

                for _,a_friend in ipairs(self.friends_noself)do   -- 目标1：寻找1血友方
                    if call(a_friend,"getHp")==1 and call(a_friend,"isKongcheng") and not call(self,"hasSkills","kongcheng|yuwen",a_friend) and call(a_friend,"isMale") then
                        for _,b_friend in ipairs(self.friends_noself)do       --目标2：寻找位于我之后，离我最近的友方
                            if call(b_friend,"objectName")~=call(a_friend,"objectName") and call(b_friend,"isMale") and self:playerGetRound(b_friend)<round
                            and self:hasTrickEffective(duel,a_friend,b_friend) then
                                round = self:playerGetRound(b_friend)
                                to_die = a_friend
                                nextfriend = b_friend
                            end
                        end
                        if to_die and nextfriend then break end
                    end
                end

                if to_die and nextfriend then return to_die,nextfriend end
            end
        end
    end

    if lord and self:isFriend(lord) and call(lord,"hasSkill","hunzi") and call(lord,"getHp")==2 and call(lord,"getStrategyMark","hunzi")==0 and call(lord,"objectName")~=call(self.player,"objectName") then
        local enemycount = self:getEnemyNumBySeat(self.player,lord)
        local peaches = self:getAllPeachNum()
        if peaches>=enemycount then
            local f_target,e_target
            for _,ap in sgs.list(call(self.room,"getOtherPlayers",self.player))do
                if call(ap,"objectName")~=call(lord,"objectName") and call(ap,"isMale") and self:hasTrickEffective(duel,lord,ap) then
                    if call(self,"hasSkills","jiang|nosjizhi|jizhi",ap) and self:isFriend(ap) and not call(ap,"isLocked",duel) then
                        if not use.isDummy then self:setStrategyPlayerFlag(lord,"AIGlobal_NeedToWake",true) end
                        return lord,ap
                    elseif self:isFriend(ap) then
                        f_target = ap
                    else
                        e_target = ap
                    end
                end
            end
            if f_target or e_target then
                local target
                if f_target and not call(f_target,"isLocked",duel) then
                    target = f_target
                elseif e_target and not call(e_target,"isLocked",duel) then
                    target = e_target
                end
                if target then
                    if not use.isDummy then self:setStrategyPlayerFlag(lord,"AIGlobal_NeedToWake",true) end
                    return lord,target
                end
            end
        end
    end

    local shenguanyu = self.room:findPlayerBySkillName("wuhun")
    if shenguanyu and call(shenguanyu,"isMale") and call(shenguanyu,"objectName")~=call(self.player,"objectName") then
        if self.role=="rebel" and lord and call(lord,"isMale") and call(lord,"objectName")~=call(self.player,"objectName") and call(shenguanyu,"objectName")~=call(lord,"objectName")
            and not self:hasJueqingEffect(lord,shenguanyu) and self:hasTrickEffective(duel,shenguanyu,lord) then
            return shenguanyu,lord
        elseif self:isEnemy(shenguanyu) and #self.enemies>=2 then
            for _,enemy in ipairs(self.enemies)do
                if call(enemy,"objectName")~=call(shenguanyu,"objectName") and call(enemy,"isMale") and not call(enemy,"isLocked",duel)
                    and self:hasTrickEffective(duel,shenguanyu,enemy) then
                    return shenguanyu,enemy
                end
            end
        end
    end

    if not call(self.player,"hasUsed",card_name) then
        self.enemies = self:sort(self.enemies,"defense")
        local males,others = {},{}
        local first,second
        local zhugeliang_kongcheng,xunyu

        for _,enemy in ipairs(self.enemies)do
            if call(enemy,"isMale") and not call(enemy,"hasSkills","wuyan|noswuyan") then
                if call(enemy,"hasSkill","kongcheng") and call(enemy,"isKongcheng") then zhugeliang_kongcheng = enemy
                elseif call(enemy,"hasSkill","jieming") then xunyu = enemy
                else
                    for _,anotherenemy in ipairs(self.enemies)do
                        if call(anotherenemy,"isMale") and call(anotherenemy,"objectName")~=call(enemy,"objectName") then
                            if #males==0 and self:hasTrickEffective(duel,enemy,anotherenemy) then
                                if not (call(enemy,"hasSkill","hunzi") and call(enemy,"getStrategyMark","hunzi")<1 and call(enemy,"getHp")==2) then
                                    table.insert(males,enemy)
                                else
                                    table.insert(others,enemy)
                                end
                            end
                            if #males==1 and self:hasTrickEffective(duel,males[1],anotherenemy) then
                                if not call(anotherenemy,"hasSkills","nosjizhi|jizhi|jiang") then
                                    table.insert(males,anotherenemy)
                                else
                                    table.insert(others,anotherenemy)
                                end
                                if #males>=2 then break end
                            end
                        end
                    end
                end
                if #males>=2 then break end
            end
        end

        if #males>=1 and current_role(self,males[1])=="rebel" and call(males[1],"getHp")==1 then
            if lord and self:isFriend(lord) and call(lord,"isMale") and call(lord,"objectName")~=call(males[1],"objectName") and self:hasTrickEffective(duel,males[1],lord)
                and not call(lord,"isLocked",duel) and call(lord,"objectName")~=call(self.player,"objectName") and call(lord,"isAlive")
                and (getCardsNum("Slash",males[1])<1
                    or getCardsNum("Slash",males[1])<getCardsNum("Slash",lord)
                    or self:getKnownNum(males[1])==call(males[1],"getHandcardNum") and getKnownCard(males[1],self.player,"Slash",true,"he")==0)
                then
                return males[1],lord
            end

            local afriend = findFriend_maxSlash(self,males[1])
            if afriend and call(afriend,"objectName")~=call(males[1],"objectName") then
                return males[1],afriend
            end
        end

        if #males==1 then
            if isLord(males[1]) and turncount(self)<=1 and self.role=="rebel" and call(self.player,"aliveCount")>=3 then
                local p_slash,max_p,max_pp = 0,nil,nil
                for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
                    if call(p,"isMale") and not self:isFriend(p) and call(p,"objectName")~=call(males[1],"objectName") and self:hasTrickEffective(duel,males[1],p) and not call(p,"isLocked",duel)
                        and p_slash<getCardsNum("Slash",p) then
                        if call(p,"getKingdom")==call(males[1],"getKingdom") then
                            max_p = p
                            break
                        elseif not max_pp then
                            max_pp = p
                        end
                    end
                end
                if max_p then table.insert(males,max_p) end
                if max_pp and #males==1 then table.insert(males,max_pp) end
            end
        end

        if #males==1 then
            if #others>=1 and not call(others[1],"isLocked",duel) then
                table.insert(males,others[1])
            elseif xunyu and not call(xunyu,"isLocked",duel) then
                if getCardsNum("Slash",males[1])<1 then
                    table.insert(males,xunyu)
                else
                    local drawcards = 0
                    for _,enemy in ipairs(self.enemies)do
                        local x = call(enemy,"getMaxHp")>call(enemy,"getHandcardNum") and math.min(5,call(enemy,"getMaxHp")-call(enemy,"getHandcardNum")) or 0
                        if x>drawcards then drawcards = x end
                    end
                    if drawcards<=2 then
                        table.insert(males,xunyu)
                    end
                end
            end
        end

        if #males==1 and #self.friends_noself>0 then

            first = males[1]
            if zhugeliang_kongcheng and self:hasTrickEffective(duel,first,zhugeliang_kongcheng) then
                table.insert(males,zhugeliang_kongcheng)
            else
                local friend_maxSlash = findFriend_maxSlash(self,first)
                if friend_maxSlash then table.insert(males,friend_maxSlash) end
            end
        end

        if #males>=2 then
            first = males[1]
            second = males[2]
            if lord and call(first,"getHp")<=1 then
                if call(self.player,"isLord") or self:isRolePredictable() then
                    local friend_maxSlash = findFriend_maxSlash(self,first)
                    if friend_maxSlash then second = friend_maxSlash end
                elseif call(lord,"isMale") and not call(self,"hasSkills","wuyan|noswuyan",lord) then
                    if self.role=="rebel" and not call(first,"isLord") and self:hasTrickEffective(duel,first,lord) then
                        second = lord
                    else
                        if ( (self.role=="loyalist" or self.role=="renegade") and not call(self,"hasSkills","ganglie|enyuan|neoganglie|nosenyuan",first) )
                            and ( getCardsNum("Slash",first)<=getCardsNum("Slash",second) ) then
                            second = lord
                        end
                    end
                end
            end

            if first and second and call(first,"objectName")~=call(second,"objectName") and not call(second,"isLocked",duel) then
                return first,second
            end
        end
    end
end

sgs.ai_skill_invoke.nosdanshou = function(self,data)
    local damage = data:toDamage()
    local phase = call(self.player,"getPhase")
    if phase<sgs.Player_Play then
        return self:willSkipPlayPhase()
    elseif phase==sgs.Player_Play then
        if damage.chain or chained_count(self)>0 then
            for _,ap in sgs.qlist(call(self.room,"getAllPlayers"))do
                if call(ap,"isChained") and self:isGoodChainTarget(ap,damage.card,nil,damage.damage) then return false end
            end
            return true
        elseif self:getOverflow()>=2 then
            return true
        else
            if damage.chain or chained_count(self)>0 then
                local nextp
                for _,p in sgs.qlist(call(self.room,"getAllPlayers"))do
                    if call(p,"isChained") and self:damageIsEffective(p,damage.nature,self.player) then
                        nextp = p
                        break
                    end
                end
                return not nextp or self:isFriend(nextp)
            end
            if damage.card and call(damage.card,"isKindOf","Slash") and self:getCardsNum("Slash")>=1 and self:slashIsAvailable() then
                return false
            end
            if (damage.card and call(damage.card,"isKindOf","AOE")) or (call(self.player,"getStrategyFlag","ShenfenUsing") and call(self.player,"faceUp")) then
                if damage.to:getNextAlive():objectName()==call(self.player,"objectName") then return true
                else
                    local dmg_val = 0
                    local p = damage.to
                    repeat
                        if self:damageIsEffective(p,damage.card,self.player)
                        then
                            if self:isFriend(p) then
                                dmg_val = dmg_val+1
                            else
                                if self:cantbeHurt(p,self.player,damage.damage) then dmg_val = dmg_val+1 end
                                if self:needToLoseHp(p,self.player,damage.card) then dmg_val = dmg_val+0.5 end
                                if self:isEnemy(p) then dmg_val = dmg_val-1 end
                            end
                        end
                        p = p:getNextAlive()
                    until call(p,"objectName")==call(self.player,"objectName")
                    return dmg_val>=1.5
                end
            end
            if call(damage.to,"hasSkills",sgs.masochism_skill.."|zhichi|zhiyu|fenyong") then return self:isEnemy(damage.to) end
            return true
        end
    elseif phase>sgs.Player_Play and phase~=sgs.Player_NotActive then
        return true
    elseif phase==sgs.Player_NotActive then
        local current = self.room:getCurrent()
        if not current or not call(current,"isAlive") or call(current,"getPhase")==sgs.Player_NotActive then return true end
        if self:isFriend(current) then
            return self:getOverflow(current)>=2
        else
            if self:getOverflow(current)<=2 then
                return true
            else
                local threat = getCardsNum("Duel",current,self.player)+getCardsNum("AOE",current,self.player)
                if self:slashIsAvailable(current) and getCardsNum("Slash",current,self.player)>0 then threat = threat+math.min(1,getCardsNum("Slash",current,self.player)) end
                return threat>=1
            end
        end
    end
    return false
end

sgs.ai_skill_askforyiji.qingjian = function(self,card_ids,tos)
    local move_skill = self.player:getTag("QingjianCurrentMoveSkill")
    if move_skill=="rende" or move_skill=="nosrende" then return nil,-1 end
    return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
end

sgs.ai_skill_use_func.NosJujianCard = function(card,use,self)
    local abandon_card = {}
    local to
    local AssistTarget = self:AssistTarget()
    if AssistTarget and self:willSkipPlayPhase(AssistTarget) then AssistTarget = nil end

    local trick_num,basic_num,equip_num = 0,0,0
    if self:getCardsNum("Peach")<1 and call(self.player,"isWounded")
    and strategy_cards(self,self.player,"he"):length()>=3 then
        local cards = strategy_cards(self,self.player,"he")
        cards = sgs.QList2Table(cards)
        cards = self:sortByUseValue(cards,true)
        for _,card in ipairs(cards)do
            if call(card,"getTypeId")==sgs.Card_TypeTrick
            and not isCard("ExNihilo",card,self.player)
            then trick_num = trick_num+1
            elseif call(card,"getTypeId")==sgs.Card_TypeBasic
            then basic_num = basic_num+1
            elseif call(card,"getTypeId")==sgs.Card_TypeEquip
            then equip_num = equip_num+1 end
        end
        local result_class
        if trick_num>=3 then result_class = "TrickCard"
        elseif equip_num>=3 then result_class = "EquipCard"
        elseif basic_num>=3 then result_class = "BasicCard" end

        for _,fcard in ipairs(cards)do
            if result_class and call(fcard,"isKindOf",result_class)
            and not isCard("ExNihilo",fcard,self.player) then
                table.insert(abandon_card,call(fcard,"getId"))
                if #abandon_card>=3 then break end
            end
        end

        if #abandon_card>=3 then
            if AssistTarget and not call(AssistTarget,"hasSkill","manjuan") then
                to = AssistTarget
            else
                to = self:findPlayerToDraw(false,3)
            end
            if not to then return end
            use.to:append(to)
            use.card = selected_skill(self,"@NosJujianCard="..table.concat(abandon_card,"+"))
            return
        end
    end

    abandon_card = {}
    local cards = strategy_cards(self,self.player,"h")
    cards = sgs.QList2Table(cards)
    cards = self:sortByUseValue(cards,true)
    local slash_num = self:getCardsNum("Slash")
    local jink_num = self:getCardsNum("Jink")
    for _,card in ipairs(cards)do
        if call(card,"isKindOf","TrickCard") and not call(card,"isKindOf","Nullification") then
            table.insert(abandon_card,call(card,"getId"))
        elseif call(card,"isKindOf","EquipCard") then
            table.insert(abandon_card,call(card,"getId"))
        elseif call(card,"isKindOf","Slash") then
            table.insert(abandon_card,call(card,"getId"))
            slash_num = slash_num-1
        elseif call(card,"isKindOf","Jink") and jink_num>1 then
            table.insert(abandon_card,call(card,"getId"))
            jink_num = jink_num-1
        end
        if #abandon_card>=3 then break end
    end

    if #abandon_card>=3 then
        if AssistTarget and not call(AssistTarget,"hasSkill","manjuan") then
            to = AssistTarget
        else
            to = self:findPlayerToDraw(false,3)
        end
        if not to then return end
        use.to:append(to)
        use.card = selected_skill(self,"@NosJujianCard="..table.concat(abandon_card,"+"))
        return
    end

    local n = self:getOverflow()
    if n>0 then
        n = math.min(n,3)
        if AssistTarget and not call(AssistTarget,"hasSkill","manjuan") and not self:needKongcheng(AssistTarget,true) then
            to = AssistTarget
        else
            to = self:findPlayerToDraw(false,n)
        end
        if not to then return end
        local discard = self:recommendDiscard(n,n,false,true)
        use.card = selected_skill(self,"@NosJujianCard="..table.concat(discard,"+"))
        use.to:append(to)
        return
    end

    if #abandon_card>0 then
        if AssistTarget and not call(AssistTarget,"hasSkill","manjuan") and not self:needKongcheng(AssistTarget,true) then
            to = AssistTarget
        else
            to = self:findPlayerToDraw(false,#abandon_card)
        end
        if not to then return end
        use.card = selected_skill(self,"@NosJujianCard="..table.concat(abandon_card,"+"))
        use.to:append(to)
        return
    end
end

sgs.ai_skill_use_func.NosXuanhuoCard = function(card,use,self)
    local cards = strategy_cards(self,self.player,"h")
    cards = sgs.QList2Table(cards)
    cards = self:sortByKeepValue(cards)

    local target
    for _,friend in ipairs(self.friends_noself)do
        if call(self,"hasSkills",sgs.lose_equip_skill,friend) and not call(friend,"getEquips"):isEmpty() and not call(friend,"hasSkill","manjuan") then
            target = friend
            break
        end
    end
    if not target then
        for _,enemy in ipairs(self.enemies)do
            if self:getDangerousCard(enemy) then
                target = enemy
                break
            end
        end
    end
    if not target then
        for _,friend in ipairs(self.friends_noself)do
            if self:needToThrowArmor(friend) and not call(friend,"hasSkill","manjuan") then
                target = friend
                break
            end
        end
    end
    if not target then
        self.enemies = self:sort(self.enemies,"handcard")
        for _,enemy in ipairs(self.enemies)do
            if self:getValuableCard(enemy) then
                target = enemy
                break
            end
            if target then break end

            local cards = sgs.QList2Table(strategy_cards(self,enemy,"h"))
            local flag = string.format("%s_%s_%s","visible",call(self.player,"objectName"),call(enemy,"objectName"))
            if not call(enemy,"isKongcheng") and not hasTuntianEffect(enemy, true) then
                for _,cc in ipairs(cards)do
                    if (call(cc,"hasFlag","visible") or call(cc,"hasFlag",flag)) and (call(cc,"isKindOf","Peach") or call(cc,"isKindOf","Analeptic")) then
                        target = enemy
                        break
                    end
                end
            end
            if target then break end

            if self:getValuableCard(enemy) then
                target = enemy
                break
            end
            if target then break end
        end
    end
    if not target then
        for _,friend in ipairs(self.friends_noself)do
            if not call(friend,"hasSkill","manjuan") and hasTuntianEffect(friend, true) then
                target = friend
                break
            end
        end
    end
    if not target then
        for _,enemy in ipairs(self.enemies)do
            if not call(enemy,"isNude") and call(enemy,"hasSkill","manjuan") then
                target = enemy
                break
            end
        end
    end

    if target then
        local willUse
        if self:isFriend(target) then
            for _,card in ipairs(cards)do
                if call(card,"getSuit")==sgs.Card_Heart then
                    willUse = card
                    break
                end
            end
        else
            for _,card in ipairs(cards)do
                if call(card,"getSuit")==sgs.Card_Heart and not isCard("Peach",card,target) and not isCard("Nullification",card,target) then
                    willUse = card
                    break
                end
            end
        end

        if willUse then
            self:setStrategyPlayerFlag(target,"AI_NosXuanhuoTarget",true)
            use.card = selected_skill(self,"@NosXuanhuoCard="..call(willUse,"getEffectiveId"))
            use.to:append(target)
        end
    end
end

sgs.ai_skill_use_func.NosLijianCard = function(card,use,self)
    local first,second = self:findLijianTarget("NosLijianCard",use)
    if first and second then
        use.card = card
        use.to:append(first)
        use.to:append(second)
    end
end

sgs.ai_skill_use_func.NosRendeCard = function(card,use,self)
    local cards = sgs.QList2Table(strategy_cards(self,self.player,"h"))
    cards = self:sortByUseValue(cards,true)
    local notFound = false
    for i = 1,call(self.player,"getHandcardNum") do
        local h,friend = self:getCardNeedPlayer(cards)
        if h and friend then cards = self:resetCards(cards,h)
        else notFound = true break end
        if friend==self.player or not call(self.player,"handCards"):contains(call(h,"getEffectiveId")) then continue end
        local canJijiang = call(self.player,"hasLordSkill","jijiang") and call(friend,"getKingdom")=="shu"
        if call(h,"isAvailable",self.player)
        and (call(h,"isKindOf","Slash") and not canJijiang or call(h,"isKindOf","Duel") or call(h,"isKindOf","Snatch") or call(h,"isKindOf","Dismantlement")) then
            local dummy_use = self:aiUseCard(h)
            if dummy_use.card then
                if call(h,"isKindOf","Slash") or call(h,"isKindOf","Duel") then
                    local t1 = dummy_use.to:first()
                    if dummy_use.to:length()>1 then continue
                    elseif call(t1,"getHp")<2 or getCardsNum("Jink",t1,self.player)<1
                    or call(t1,"isCardLimited",call(self,"getEvaluationCard","jink"),sgs.Card_MethodResponse)
                    then continue end
                elseif self:getEnemyNumBySeat(self.player,friend)>0 then
                    local hasDelayedTrick
                    for _,p in sgs.qlist(dummy_use.to)do
                        if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p))
                        then hasDelayedTrick = true break end
                    end
                    if hasDelayedTrick then continue end
                end
            end
        elseif call(h,"isAvailable",self.player)
        and (call(h,"isKindOf","Indulgence") or call(h,"isKindOf","SupplyShortage"))
        and self:getEnemyNumBySeat(self.player,friend)>0
        and self:aiUseCard(h).card then continue end
        if #cards>1 and call(friend,"hasSkill","enyuan")
        and not(call(self.room,"getMode")=="04_1v3" and call(self.player,"getStrategyMark","nosrende")==1)
        then use.card = selected_skill(self,"@NosRendeCard="..call(h,"getId").."+"..call(cards[1],"getId"))
        else use.card = selected_skill(self,"@NosRendeCard="..call(h,"getId")) end
        use.to:append(friend)
        return
    end
    if notFound and call(self.player,"isWounded")
    and self:getOverflow()>0 and call(self.player,"getStrategyMark","nosrende")<2 then
        cards = self:sortByUseValue(strategy_cards(self,self.player,"h"),true)
        for _,p in sgs.qlist(call(self.room,"getOtherPlayers",self.player))do
            if not self:isFriend(p) and hasManjuanEffect(p) then
                local to_give = {}
                for _,h in ipairs(cards)do
                    if not isCard("Peach,ExNihilo",h,self.player)
                    then table.insert(to_give,call(h,"getId")) end
                    if #to_give>=2-call(self.player,"getStrategyMark","nosrende")
                    then break end
                end
                if #to_give>0 then
                    use.card = selected_skill(self,"@NosRendeCard="..table.concat(to_give,"+"))
                    use.to:append(p)
                    return
                end
            end
        end
    end
end

sgs.ai_skill_use_func.FenchengCard = function(card,use,self)
    use.card = card
end

sgs.ai_skill_use_func.NosKurouCard=function(card,use,self)
    if not use.isDummy then self:speak("noskurou") end
    use.card=card
end

sgs.ai_skill_use_func.NosFanjianCard=function(card,use,self)

    local cards = sgs.QList2Table(strategy_cards(self,self.player,"h"))
    cards = self:sortByUseValue(cards,true)
    if #cards==1 and call(cards[1],"getSuit")==sgs.Card_Diamond then return end
    if #cards<=4 and (self:getCardsNum("Peach")>0 or self:getCardsNum("Analeptic")>0) then return end
    self.enemies = self:sort(self.enemies,"hp")

    local suits = {}
    local suits_num = 0
    for _,c in ipairs(cards)do
        if not suits[call(c,"getSuitString")] then
            suits[call(c,"getSuitString")] = true
            suits_num = suits_num+1
        end
    end

    local wgt = self.room:findPlayerBySkillName("buyi")
    if wgt and self:isFriend(wgt) then wgt = nil end

    for _,enemy in ipairs(self.enemies)do
        local visible = 0
        for _,card in ipairs(cards)do
            local flag = string.format("%s_%s_%s","visible",call(enemy,"objectName"),call(self.player,"objectName"))
            if call(card,"hasFlag","visible") or call(card,"hasFlag",flag) then visible = visible+1 end
        end
        if visible>0 and (#cards<=2 or suits_num<=2) then continue end
        if self:canAttack(enemy) and not call(enemy,"hasSkills","qingnang|jijiu|tianxiang")
        and not (wgt and call(card,"getTypeId")~=sgs.Card_Basic and (call(enemy,"isKongcheng") or call(enemy,"objectName")==call(wgt,"objectName")))
        and self:damageIsEffective(enemy,card)
        then
            use.card = selected_skill(self,"@NosFanjianCard=.")
            use.to:append(enemy)
            return
        end
    end
end

sgs.ai_skill_use_func.QingnangCard = function(card,use,self)
    local arr1,arr2 = self:getWoundedFriend(false,true)
    local target = nil

    if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and call(arr1[1],"getHp")<getBestHp(arr1[1]) then target = arr1[1] end
    if target then
        use.card = card
        use.to:append(target)
        return
    end
    if self:getOverflow()>0 and #arr2>0 then
        for _,friend in ipairs(arr2)do
            if not call(friend,"hasSkills","hunzi|longhun") then
                use.card = card
                use.to:append(friend)
                return
            end
        end
    end
end

sgs.ai_skill_use_func.rende = function(card,use,self)
    local cards = sgs.QList2Table(strategy_cards(self,self.player,"h"))
    cards = self:sortByUseValue(cards,true)
    local notFound
    for i=1,call(self.player,"getHandcardNum") do
        local h,friend = self:getCardNeedPlayer(cards)
        if h and friend then table.removeOne(cards,h)
        else notFound = true break end
        if friend==self.player
        or not call(self.player,"handCards"):contains(call(h,"getId"))
        then continue end
        if call(h,"isAvailable",self.player) then
            local canJijiang = call(friend,"getKingdom")=="shu" and call(self.player,"hasLordSkill","jijiang")
            if call(h,"isKindOf","Slash") and not canJijiang or call(h,"isKindOf","Duel") then
                local dummy_use = self:aiUseCard(h)
                if dummy_use.card then
                    local t1 = dummy_use.to:first()
                    if dummy_use.to:length()>1 or call(t1,"getHp")<2 or getCardsNum("Jink",t1,self.player)<1
                    or call(t1,"isCardLimited",call(self,"getEvaluationCard","jink"),sgs.Card_MethodUse)
                    then continue end
                end
            elseif (call(h,"isKindOf","Snatch") or call(h,"isKindOf","Dismantlement"))
            and self:getEnemyNumBySeat(self.player,friend)>0 then
                local dummy_use = self:aiUseCard(h)
                if dummy_use.card then
                    local hasDelayedTrick
                    for _,p in sgs.list(dummy_use.to)do
                        if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p))
                        then hasDelayedTrick = true break end
                    end
                    if hasDelayedTrick then continue end
                end
            elseif call(h,"isKindOf","DelayedTrick")
            and self:getEnemyNumBySeat(self.player,friend)>0
            and self:aiUseCard(h).card
            then continue end
        end
        if call(friend,"hasSkill","enyuan") and #cards>0
        and not(call(self.room,"getMode")=="04_1v3" and call(self.player,"getStrategyMark","rende")==1)
        then use.card = rende_card(self,{call(h,"getId"), call(cards[1],"getId")})
        else use.card = rende_card(self,{call(h,"getId")}) end
        use.to:append(friend)
        return
    end
    if notFound and self:isWeak()
    and call(self.player,"getHandcardNum")>3
    and call(self.player,"getStrategyMark","rende")<2 then
        cards = self:sortByUseValue(strategy_cards(self,self.player,"h"),true)
        for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
            if not self:isEnemy(p) or hasManjuanEffect(p) then
                local to_give = {}
                for _,h in ipairs(cards)do
                    if not isCard("Peach",h,self.player)
                    then table.insert(to_give,call(h,"getId")) end
                    if #to_give==2-call(self.player,"getStrategyMark","rende") then break end
                end
                if #to_give>0 then
                    use.card = rende_card(self,to_give)
                    use.to:append(p)
                    break
                end
            end
        end
    end
end

sgs.ai_skill_use_func.JijiangCard = function(card,use,self)
    self.enemies = self:sort(self.enemies,"defenseSlash")
    local jijiangtargets = {};self:setStrategyMemory("jijiangtarget",{})
    local dummy_use = dummy()
    if call(self.player,"getStrategyFlag","slashTargetFix") then
        for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
            if call(p,"getStrategyFlag","SlashAssignee") then dummy_use.to:append(p) end
        end
    end
    local slash = call(self,"getEvaluationCard","slash")
    self:useCardSlash(slash,dummy_use)
    if dummy_use.card then
        use.card = card
        for _,p in sgs.list(dummy_use.to)do
            table.insert(jijiangtargets,call(p,"objectName"));self:setStrategyMemory("jijiangtarget",jijiangtargets)
            use.to:append(p)
        end
    end
end

sgs.ai_skill_use_func.YijueCard = function(card,use,self)
    self.enemies = self:sort(self.enemies,"handcard")
    local max_card = self:getMaxCard()
    if not max_card then return end
    local max_point = call(max_card,"getNumber")
    if call(self.player,"hasSkill","yingyang") then max_point = math.min(max_point+3,13) end
    if call(self.player,"hasSkill","kongcheng") and call(self.player,"getHandcardNum")==1 then
        for _,enemy in ipairs(self.enemies)do
            if self.player:canPindian(enemy) and self:hasLoseHandcardEffective(enemy) and not (hasTuntianEffect(enemy, true) and call(enemy,"getHandcardNum")>2) then
                self:setPriorityValue("YijueCard",1.2,"standard")
                self.yijue_card = call(max_card,"getId");self:remember("yijue_card",self.yijue_card)
                use.card = card
                use.to:append(enemy)
                return
            end
        end
    end
    for _,enemy in ipairs(self.enemies)do
        if call(enemy,"getStrategyFlag","AI_HuangtianPindian") and call(enemy,"getHandcardNum")==1 and self.player:canPindian(enemy) then
            self:setPriorityValue("YijueCard",7.2,"standard")
            self.yijue_card = call(max_card,"getId");self:remember("yijue_card",self.yijue_card)
            use.card = card
            use.to:append(enemy)
            self:setStrategyPlayerFlag(enemy,"AI_HuangtianPindian",false)
            return
        end
    end

    local zhugeliang = self.room:findPlayerBySkillName("kongcheng")

    self:setPriorityValue("YijueCard",7.2,"standard")
    self.enemies = self:sort(self.enemies)
    self.enemies = sgs.reverse(self.enemies)
    for _,enemy in ipairs(self.enemies)do
        if not (call(enemy,"hasSkill","kongcheng") and call(enemy,"getHandcardNum")==1) and self.player:canPindian(enemy) then
            local enemy_max_card = self:getMaxCard(enemy)
            local enemy_max_point = enemy_max_card and call(enemy_max_card,"getNumber") or 100
            if enemy_max_card and call(enemy,"hasSkill","yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
            if max_point>enemy_max_point then
                self.yijue_card = call(max_card,"getId");self:remember("yijue_card",self.yijue_card)
                use.card = card
                use.to:append(enemy)
                return
            end
        end
    end
    for _,enemy in ipairs(self.enemies)do
        if not (call(enemy,"hasSkill","kongcheng") and call(enemy,"getHandcardNum")==1) and self.player:canPindian(enemy) then
            if max_point>=10 then
                self.yijue_card = call(max_card,"getId");self:remember("yijue_card",self.yijue_card)
                use.card = card
                use.to:append(enemy)
                return
            end
        end
    end

    self:setPriorityValue("YijueCard",1.2,"standard")
    local min_card = self:getMinCard()
    if not min_card then return end
    local min_point = call(min_card,"getNumber")
    if call(self.player,"hasSkill","yingyang") then min_point = math.max(min_point-3,1) end

    local wounded_friends = self:getWoundedFriend()
    if #wounded_friends>0 then
        for _,wounded in ipairs(wounded_friends)do
            if call(wounded,"getHandcardNum")>1 and call(wounded,"getLostHp")/call(wounded,"getMaxHp")>=0.3 and self.player:canPindian(wounded) then
                local w_max_card = self:getMaxCard(wounded)
                local w_max_number = w_max_card and call(w_max_card,"getNumber") or 0
                if w_max_card and call(wounded,"hasSkill","yingyang") then w_max_number = math.min(w_max_number+3,13) end
                if (w_max_card and w_max_number>=min_point) or min_point<=4 then
                    self.yijue_card = call(min_card,"getId");self:remember("yijue_card",self.yijue_card)
                    use.card = card
                    use.to:append(wounded)
                    return
                end
            end
        end
    end

    if zhugeliang and self:isFriend(zhugeliang) and call(zhugeliang,"getHandcardNum")==1 and call(zhugeliang,"objectName")~=call(self.player,"objectName")
        and self.player:canPindian(zhugeliang) then
        if min_point<=4 then
            self.yijue_card = call(min_card,"getId");self:remember("yijue_card",self.yijue_card)
            use.card = card
            use.to:append(zhugeliang)
            return
        end
        local cards = sgs.QList2Table(strategy_cards(self,self.player,"h"))
        cards = self:sortByUseValue(cards,true)
        if self:getEnemyNumBySeat(self.player,zhugeliang)>=1 then
            if isCard("Jink",cards[1],self.player) and self:getCardsNum("Jink")==1 then return end
            self.yijue_card = call(cards[1],"getId");self:remember("yijue_card",self.yijue_card)
            use.card = card
            use.to:append(zhugeliang)
            return
        end
    end
end

sgs.ai_skill_use_func.KurouCard = function(card,use,self)
    use.card = card
end

sgs.ai_skill_use_func.FanjianCard = function(card,use,self)
    local cards = sgs.QList2Table(strategy_cards(self,self.player,"h"))
    cards = self:sortByUseValue(cards,true)
    self.enemies = self:sort(self.enemies,"defense")

    if self:getCardsNum("Slash")>0 then
        local slash = self:getCard("Slash")
        local dummy_use = dummy()
        self:useCardSlash(slash,dummy_use)
        if dummy_use.card and dummy_use.to:length()>0 then
            self:setPriorityValue("FanjianCard",call(self,"getPriorityValue","Slash")+0.15,"standard")
            local target = dummy_use.to:first()
            if self:isEnemy(target) and getCardsNum("Jink",target,self.player)>=1 and call(target,"getStrategyMark","yijue")==0
                and not call(target,"isKongcheng") and (self:getOverflow()>0 or call(target,"getHandcardNum")>2)
                and not (call(self.player,"hasSkill","liegong") and (call(target,"getHandcardNum")>=call(self.player,"getHp") or call(target,"getHandcardNum")<=call(self.player,"getAttackRange")))
                and not (call(self.player,"hasSkill","kofliegong") and call(target,"getHandcardNum")>=call(self.player,"getHp")) then
                if call(target,"hasSkill","qingguo") then
                    for _,card in ipairs(cards)do
                        if self:getUseValue(card)<6 and call(card,"isBlack") then
                            use.card = selected_skill(self,"@FanjianCard="..call(card,"getEffectiveId"))
                            use.to:append(target)
                            return
                        end
                    end
                end
                for _,card in ipairs(cards)do
                    if self:getUseValue(card)<6 and call(card,"getSuit")==sgs.Card_Diamond then
                        use.card = selected_skill(self,"@FanjianCard="..call(card,"getEffectiveId"))
                        use.to:append(target)
                        return
                    end
                end
            end
        end
    end

    if self:getOverflow()<=0 then return end
    self:setPriorityValue("FanjianCard",0.2,"standard")
    local suit_table = { "spade","club","heart","diamond" }
    local equip_val_table = { 1.2,1.5,0.5,1,1.3 }
    for _,enemy in ipairs(self.enemies)do
        if call(enemy,"getHandcardNum")>2 then
            local max_suit_num,max_suit = 0,{}
            for i = 0,3,1 do
                local suit_num = getKnownCard(enemy,self.player,suit_table[i+1])
                for j = 0,4,1 do
                    if enemy:getEquip(j) and enemy:getEquip(j):getSuit()==i then
                        local val = equip_val_table[j+1]
                        if j==1 and self:needToThrowArmor(enemy) then val = -0.5
                        else
                            if call(enemy,"hasSkills",sgs.lose_equip_skill) then val = val/8 end
                            if enemy:getEquip(j):getEffectiveId()==self:getValuableCard(enemy) then val = val*1.1 end
                            if enemy:getEquip(j):getEffectiveId()==self:getDangerousCard(enemy) then val = val*1.1 end
                        end
                        suit_num = suit_num+j
                    end
                end
                if suit_num>max_suit_num then
                    max_suit_num = suit_num
                    max_suit = { i }
                elseif suit_num==max_suit_num then
                    table.insert(max_suit,i)
                end
            end
            if max_suit_num==0 then
                max_suit = {}
                local suit_value = { 1,1,1.3,1.5 }
                for _,skill in ipairs(sgs.getPlayerSkillList(enemy))do
                    if sgs[call(skill,"objectName").."_suit_value"] then
                        for i = 1,4,1 do
                            local v = sgs[call(skill,"objectName").."_suit_value"][suit_table[i]]
                            if v then suit_value[i] = suit_value[i]+v end
                        end
                    end
                end
                local max_suit_val = 0
                for i = 0,3,1 do
                    local suit_val = suit_value[i+1]
                    if suit_val>max_suit_val then
                        max_suit_val = suit_val
                        max_suit = { i }
                    elseif suit_val==max_suit_val then
                        table.insert(max_suit,i)
                    end
                end
            end
            for _,card in ipairs(cards)do
                if self:getUseValue(card)<6 and table.contains(max_suit,call(card,"getSuit")) then
                    use.card = selected_skill(self,"@FanjianCard="..call(card,"getEffectiveId"))
                    use.to:append(enemy)
                    return
                end
            end
            if getCardsNum("Peach",enemy,self.player)<2 then
                for _,card in ipairs(cards)do
                    if self:getUseValue(card)<6 and not self:isValuableCard(card) then
                        use.card = selected_skill(self,"@FanjianCard="..call(card,"getEffectiveId"))
                        use.to:append(enemy)
                        return
                    end
                end
            end
        end
    end
    for _,friend in ipairs(self.friends_noself)do
        if call(friend,"hasSkill","hongyan") then
            for _,card in ipairs(cards)do
                if self:getUseValue(card)<6 and call(card,"getSuit")==sgs.Card_Spade then
                    use.card = selected_skill(self,"@FanjianCard="..call(card,"getEffectiveId"))
                    use.to:append(friend)
                    return
                end
            end
        end
        if self:hasZhaxiangEffect(friend) and not self:isWeak(friend) and not (call(friend,"getHp")==2 and call(friend,"hasSkill","chanyuan")) then
            for _,card in ipairs(cards)do
                if self:getUseValue(card)<6 then
                    use.card = selected_skill(self,"@FanjianCard="..call(card,"getEffectiveId"))
                    use.to:append(friend)
                    return
                end
            end
        end
    end
end

sgs.ai_skill_use_func.JieyinCard = function(card,use,self)
    local arr1,arr2 = self:getWoundedFriend(true)
    local target = nil

    repeat
        if #arr1>0 and (self:isWeak(arr1[1]) or self:isWeak() or self:getOverflow()>=1) then
            target = arr1[1]
            break
        end
        if #arr2>0 and self:isWeak() then
            target = arr2[1]
            break
        end
    until true

    if not target and self:isWeak() and self:getOverflow()>=2 and (self.role=="lord" or self.role=="renegade") then
        local others = call(self.room,"getOtherPlayers",self.player)
        for _,other in sgs.list(others)do
            if call(other,"isWounded") and call(other,"isMale") then
                if not call(self,"hasSkills",sgs.masochism_skill,other) then
                    target = other
                    self:setStrategyPlayerFlag(self.player,"jieyin_isenemy_"..call(other,"objectName"),true)
                    break
                end
            end
        end
    end

    if target then
        use.card = card
        use.to:append(target)
        return
    end
end

local function chuli_target_filter(self,targets,player)
    if player==self.player then return false end
    if known(self.world.enable_hegemony,"Hegemony setting")then
        if #targets>=3 or not call(self.player,"canDiscard",player,"he")then return false end
        if not call(player,"hasShownOneGeneral")then return true end
        for _,other in ipairs(targets)do if call(player,"isPublicHegemonyFriend",other)then return false end end
        return true
    end
    if not call(self.player,"canDiscard",player,"he")then return false end
    for _,other in ipairs(targets)do if call(player,"getKingdom")==call(other,"getKingdom")then return false end end
    return true
end
sgs.ai_skill_use_func.ChuliCard = function(card,use,self)
    self:chuliSourceMap("reset")
    local players = self:findPlayerToDiscard("he",false,true)
    local targets = sgs.PlayerList()
    -- Reuse the card's legality check so identity and Hegemony target rules stay shared.
    for _,player in ipairs(players)do
        if self:isFriend(player) and chuli_target_filter(self,targets,player) then
            targets:append(player)
        end
    end
    for _,player in ipairs(players)do
        if not targets:contains(player) and chuli_target_filter(self,targets,player) then
            targets:append(player)
        end
    end
    if targets:isEmpty() then return end
    for _,p in sgs.qlist(targets)do
        local recommendation=self:recommendCardChosen(p,"he","dummyreason",sgs.Card_MethodDiscard)
        local id=recommendation.id
        local chosen_card=id and visible_card(self,id)
        if recommendation.zone~="none" and (self:isFriend(p) or recommendation.zone~="e"
            or call(chosen_card,"getSuit")~=sgs.Card_Spade) then
            if not use.card then use.card = card end
            self:chuliSourceMap("set",call(p,"objectName"),id)
            if use.to then use.to:append(p) end
        end
    end
end

sgs.ai_skill_use_func.LijianCard = function(card,use,self)
    local first,second = self:findLijianTarget("LijianCard",use)
    if first and second then
        use.card = card
        use.to:append(first)
        use.to:append(second)
    end
end

sgs.ai_skill_use_func.JianyanCard = function(card,use,self)
    self.jianyan_choice = nil;self:setStrategyMemory("jianyan_choice",nil)
    self.jianyan_enemy = nil;remember_source(self,"jianyan_enemy",nil)
    self:setPriorityValue("JianyanCard",9.5,"standard")
    self.friends = self:sort(self.friends)
    local use_card
    for _,friend in ipairs(self.friends)do
        if call(friend,"isMale") and not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then
            if self:isWeak(friend) then self.jianyan_choice = "basic";self:setStrategyMemory("jianyan_choice","basic") end
            use_card = true
        end
    end
    if use_card then
        use.card = card
        return
    end

    self:setPriorityValue("JianyanCard",0.5,"standard")
    for _,enemy in ipairs(self.enemies)do
        if call(enemy,"isMale") and not hasManjuanEffect(enemy) and self:needKongcheng(enemy,true) then
            self.jianyan_choice = "equip";self:setStrategyMemory("jianyan_choice","equip")
            self.jianyan_enemy = enemy;remember_source(self,"jianyan_enemy",enemy)
            use.card = card
            return
        end
    end
end

sgs.ai_skill_use_func.ZhihengCard=function(card,use,self)
    local costs=self:selectZhihengCosts()
    if #costs>0 then use.card=skill_card(self,"ZhihengCard",costs)end
end
sgs.ai_skill_use["@@nostuxi"]=function(self,prompt)
    local targets=self:selectNosTuxiTargets(prompt)
    if #targets>0 then return answer_skill(self,skill_card(self,"NosTuxiCard",{}),targets)end
    return {kind="pass"}
end

sgs.weapon_range.MoonSpear = 3
sgs.ai_use_priority.MoonSpear = 2.635
sgs.ai_use_priority.NosJujianCard = 0
sgs.ai_use_value.NosJujianCard = 6.7
sgs.ai_card_intention.NosJujianCard = -100
sgs.dynamic_value.benefit.NosJujianCard = true
sgs.ai_playerchosen_intention.nosxuanfeng_damage = 80
sgs.ai_playerchosen_intention.nosxuanfeng_slash = 80
sgs.nosxuanfeng_keep_value = standard_initial_aliases["sgs.xiaoji_keep_value"]
sgs.ai_cardneed.nosxuanfeng = sgs.ai_cardneed.equip
sgs.ai_card_intention.NosJiefanCard = sgs.ai_card_intention.Peach
sgs.ai_use_value.NosLijianCard = standard_initial_aliases["sgs.ai_use_value.LijianCard"]
sgs.ai_use_priority.NosLijianCard = standard_initial_aliases["sgs.ai_use_priority.LijianCard"]
sgs.ai_card_intention.NosLijianCard = standard_initial_aliases["sgs.ai_card_intention.LijianCard"]
sgs.ai_use_value.NosRendeCard = standard_initial_aliases["sgs.ai_use_value.RendeCard"]
sgs.ai_use_priority.NosRendeCard = standard_initial_aliases["sgs.ai_use_priority.RendeCard"]
sgs.ai_card_intention.NosRendeCard = standard_initial_aliases["sgs.ai_card_intention.RendeCard"]
sgs.dynamic_value.benefit.NosRendeCard = true
sgs.nosjizhi_keep_value = sgs.jizhi_keep_value
sgs.ai_playerchosen_intention.nosleiji = sgs.ai_playerchosen_intention.leiji
sgs.ai_cardneed.nosleiji = sgs.ai_cardneed.leiji
sgs.ai_use_priority.NosGuhuoCard = 11
sgs.ai_playerchosen_intention.nosmieji = -50
sgs.ai_card_intention.NosRenxinCard = sgs.ai_card_intention.Peach
sgs.ai_use_priority.NosKurouCard = 6.8
sgs.ai_card_intention.NosFanjianCard = 70
sgs.dynamic_value.damage_card.NosFanjianCard = true
sgs.ai_use_priority.QingnangCard = 4.2
sgs.ai_card_intention.QingnangCard = -100
sgs.dynamic_value.benefit.QingnangCard = true
sgs.ai_use_value.RendeCard = 8.5
sgs.ai_use_priority.RendeCard = 8.8
sgs.dynamic_value.benefit.RendeCard = true
sgs.ai_use_value.rende = sgs.ai_use_value.RendeCard
sgs.ai_use_priority.rende = sgs.ai_use_priority.RendeCard
sgs.ai_card_intention.rende = sgs.ai_card_intention.RendeCard
sgs.dynamic_value.benefit.rende = true
sgs.ai_use_value.JijiangCard = 8.5
sgs.ai_use_priority.JijiangCard = 2.45
sgs.ai_card_intention.YijueCard = 0
sgs.ai_use_value.YijueCard = 8.5
sgs.ai_use_value.ZhihengCard = 9
sgs.ai_use_priority.ZhihengCard = 2.61
sgs.dynamic_value.benefit.ZhihengCard = true
sgs.ai_use_priority.KurouCard = 6.8
sgs.ai_use_priority.FanjianCard = 0.2
sgs.ai_use_priority.GuoseCard = 5.5
sgs.ai_use_value.GuoseCard = 5
sgs.ai_card_intention.GuoseCard = -60
sgs.ai_use_priority.JieyinCard = 2.8    -- 下调至决斗之后
sgs.dynamic_value.benefit.JieyinCard = true
sgs.ai_cardneed.xiaoji = sgs.ai_cardneed.equip
sgs.ai_use_value.ChuliCard = 5
sgs.ai_use_priority.ChuliCard = 4.6
sgs.ai_playerchosen_intention.liyu = 60
sgs.ai_use_value.LijianCard = 8.5
sgs.ai_use_priority.LijianCard = 4
sgs.dynamic_value.damage_card.LijianCard = true
sgs.ai_suit_priority.guose= "club|spade|heart|diamond"
sgs.ai_suit_priority.qixi= "diamond|heart|club|spade"
sgs.ai_suit_priority.qingguo= "diamond|heart|club|spade"
sgs.ai_use_priority.JianyanCard = 9.5
sgs.nosxuanhuo_suit_value = {
    heart = 3.9
}
sgs.nosguhuo_suit_value = {
    heart = 5,
}
sgs.nosguicai_suit_value = {
    heart = 3.9,
    club = 3.9,
    spade = 3.5
}
sgs.nosluoyi_keep_value = {
    Peach           = 6,
    Analeptic       = 5.8,
    Jink            = 5.2,
    Duel            = 5.5,
    FireSlash       = 5.6,
    Slash           = 5.4,
    ThunderSlash    = 5.5,
    Axe             = 5,
    Blade           = 4.9,
    spear           = 4.9,
    fan             = 4.8,
    KylinBow        = 4.7,
    Halberd         = 4.6,
    MoonSpear       = 4.5,
    SPMoonSpear = 4.5,
    DefensiveHorse  = 4
}
sgs.guicai_suit_value = {
    heart = 3.9,
    club = 3.9,
    spade = 3.5
}
sgs.luoyi_keep_value = {
    Peach = 6,
    Analeptic = 5.8,
    Jink = 5.2,
    Duel = 5.5,
    FireSlash = 5.6,
    Slash = 5.4,
    ThunderSlash = 5.5,
    Axe = 5,
    Blade = 4.9,
    Spear = 4.9,
    Fan = 4.8,
    KylinBow = 4.7,
    Halberd = 4.6,
    MoonSpear = 4.5,
    SPMoonSpear = 4.5,
    DefensiveHorse = 4
}
sgs.qingguo_suit_value = {
    spade = 4.1,
    club = 4.2
}
sgs.paoxiao_keep_value = {
    Peach = 6,
    Analeptic = 5.8,
    Jink = 5.7,
    FireSlash = 5.6,
    Slash = 5.4,
    ThunderSlash = 5.5,
    ExNihilo = 4.7
}
sgs.longdan_keep_value = {
    Peach = 6,
    Analeptic = 5.8,
    Jink = 5.7,
    FireSlash = 5.7,
    Slash = 5.6,
    ThunderSlash = 5.5,
    ExNihilo = 4.7
}
sgs.jizhi_keep_value = {
    Peach       = 6,
    Analeptic   = 5.9,
    Jink        = 5.8,
    ExNihilo    = 5.7,
    Snatch      = 5.7,
    Dismantlement = 5.6,
    IronChain   = 5.5,
    SavageAssault=5.4,
    Duel        = 5.3,
    ArcheryAttack = 5.2,
    AmazingGrace = 5.1,
    Collateral  = 5,
    FireAttack  =4.9
}
sgs.qixi_suit_value = {
    spade = 3.9,
    club = 3.9
}
sgs.guose_suit_value = {
    diamond = 3.9
}
sgs.guose_suit_value = {
    diamond = 3.9
}
sgs.xiaoji_keep_value = {
    Peach = 6,
    Jink = 5.1,
    Weapon = 4.9,
    Armor = 5,
    OffensiveHorse = 4.8,
    DefensiveHorse = 5
}
sgs.jijiu_suit_value = {
    heart = 6,
    diamond = 6
}

getNosFenchengValue=function(self,player)
    if not self:damageIsEffective(player,sgs.DamageStruct_Fire,self.player) then return 0 end
    if not call(player,"canDiscard",player,"he") then return self:isWeak(player) and 1.5 or 1 end
    if call(self.player,"hasSkills","juece|nosjuece") and self:isEnemy(player)
    and call(player,"getEquips"):isEmpty() and call(player,"getHandcardNum")==1 and not self:needKongcheng(player)
    and not (call(player,"isChained") or not self:isGoodChainTarget(player,"F")) then return self:isWeak(player) and 1.5 or 1 end
    if self:isGoodChainTarget(player,"F") or self:needToLoseHp(player,self.player) then return -0.1 end
    local num = call(player,"getEquips"):length()-call(player,"getHandcardNum")
    if num<0 then
        if self:needToThrowArmor(player) then num = 1 else num = 0 end
    elseif num==0 then
        num = 1
    end
    local equip_table = {}
    local needToTA = self:needToThrowArmor(player)
    if needToTA then table.insert(equip_table,1) end
    if player:getOffensiveHorse() then table.insert(equip_table,3) end
    if player:getWeapon() then table.insert(equip_table,0) end
    if player:getDefensiveHorse() then table.insert(equip_table,2) end
    if player:getArmor() and not needToTA then table.insert(equip_table,1) end

    local value = 0
    for i = 1,num,1 do
        local index = equip_table[i]
        if index==0 then value = value+0.4
        elseif index==1 then
            value = value+(needToTA and -0.5 or 0.8)
        elseif index==2 then value = value+0.7
        elseif index==3 then value = value+0.3 end
    end
    if call(player,"hasSkills","kofxiaoji|xiaoji") then value = value-0.8*num end
    if call(player,"hasSkills","xuanfeng|nosxuanfeng") and num>0 then value = value-0.8 end

    local handcard = call(player,"getHandcardNum")-num
    value = value+0.1*handcard
    if self:needKongcheng(player) or self:getLeastHandcardNum(player)>num then value = value-0.15
    elseif num==0 then value = value+0.1 end
    return value
end

getKurouCard=function(self,not_slash)
    local card_id
    local hold_crossbow = (self:getCardsNum("Slash")>1)
    local cards = strategy_cards(self,self.player,"h")
    cards = sgs.QList2Table(cards)
    cards = self:sortByKeepValue(cards)
    local lightning = self:getCard("Lightning")

    if self:needToThrowArmor() then
        card_id = self.player:getArmor():getId()
    elseif call(self.player,"getHandcardNum")>call(self.player,"getHp") then
        if lightning and not self:willUseLightning(lightning) then
            card_id = call(lightning,"getEffectiveId")
        else
            for _,acard in ipairs(cards)do
                if (call(acard,"isKindOf","BasicCard") or call(acard,"isKindOf","EquipCard") or call(acard,"isKindOf","AmazingGrace"))
                    and not self:isValuableCard(acard) and not (call(acard,"isKindOf","Crossbow") and hold_crossbow)
                    and not (call(acard,"isKindOf","Slash") and not_slash) then
                    card_id = call(acard,"getEffectiveId")
                    break
                end
            end
        end
    elseif not call(self.player,"getEquips"):isEmpty() then
        if self.player:getOffensiveHorse() then
            card_id=self:useKnowledgeEstimate({value=call(self.player:getOffensiveHorse(),"getId"),status="estimate",
                basis="donor_error_repair:getKurouCard_undefined_player_offensive_horse"},"standard.kurou")
        elseif self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon())<3
                and not (self.player:getWeapon():isKindOf("Crossbow") and hold_crossbow) then card_id = self.player:getWeapon():getId()
        elseif self.player:getArmor() and self:evaluateArmor(self.player:getArmor())<2 then card_id = self.player:getArmor():getId()
        end
    end
    if not card_id then
        if lightning and not self:willUseLightning(lightning) then
            card_id = call(lightning,"getEffectiveId")
        else
            for _,acard in ipairs(cards)do
                if (call(acard,"isKindOf","BasicCard") or call(acard,"isKindOf","EquipCard") or call(acard,"isKindOf","AmazingGrace"))
                    and not self:isValuableCard(acard) and not (call(acard,"isKindOf","Crossbow") and hold_crossbow)
                    and not (call(acard,"isKindOf","Slash") and not_slash) then
                    card_id = call(acard,"getEffectiveId")
                    break
                end
            end
        end
    end
    return card_id
end

sgs.ai_fill_skill.nosjujian=function(self,inclusive,request)
    if self:needBear() then return end
    return skill_seed(self,"nosjujian","NosJujianCard",request)
end

sgs.ai_fill_skill.nosxuanhuo=function(self,inclusive,request)
    return skill_seed(self,"nosxuanhuo","NosXuanhuoCard",request)
end

sgs.ai_fill_skill.noslijian=function(self,inclusive,request)
    if call(self.player,"isNude") or call(self.room,"getAlivePlayers"):length()<3
    then return end
    local card_id = self:getLijianCard()
    if card_id then return selected_skill(self,"@NosLijianCard="..card_id) end
end

sgs.ai_fill_skill.nosrende=function(self,inclusive,request)
    if call(self.player,"isKongcheng") then return end
    if self:shouldUseRende() then
        return skill_seed(self,"nosrende","NosRendeCard",request)
    end
end

sgs.ai_fill_skill.nosfencheng=function(self,inclusive,request)
    if turncount(self)<=1 then return end
    local lord = self.room:getLord()
    if (self.role=="loyalist" or self.role=="renegade") and (call(self,"isLordInDanger") or (lord and self:isWeak(lord))) then return end
    local value = 0
    for _,player in sgs.qlist(call(self.room,"getOtherPlayers",self.player))do
        if self:isFriend(player) then value = value-getNosFenchengValue(self,player)
        elseif self:isEnemy(player) then value = value+getNosFenchengValue(self,player) end
    end
    if #self.friends_noself>=#self.enemies and value>0 then return skill_seed(self,"nosfencheng","NosFenchengCard",request) end
    local ratio = value/(#self.enemies-#self.friends_noself)
    if ratio>=0.4 then return skill_seed(self,"nosfencheng","NosFenchengCard",request) end
end

sgs.ai_fill_skill.noskurou=function(self,inclusive,request)
    --特殊场景
    -- Fixed classical-ai.lua registers only "kurou", never "noskurou";
    -- the donor Tactic lookup is therefore a known nil for this key.
    --一般场景
    self:setPriorityValue("NosKurouCard",6.8,"noskurou")
    local losthp = isLord(self.player) and 0 or 1
    if ((call(self.player,"getHp")>3 and call(self.player,"getLostHp")<=losthp and call(self.player,"getHandcardNum")>call(self.player,"getHp"))
        or (call(self.player,"getHp")-call(self.player,"getHandcardNum")>=2)) and not (isLord(self.player) and turncount(self)<=1) then
        return skill_seed(self,"noskurou","NosKurouCard",request)
    end
    local slash = call(self,"getEvaluationCard","slash")
    if self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow")
    or call(self.player,"hasSkill","paoxiao") then
        for _,enemy in ipairs(self.enemies)do
            if call(self.player,"canSlash",enemy,slash,true) and self:slashIsEffective(slash,enemy)
                and not (call(enemy,"hasSkill","kongcheng") and call(enemy,"isKongcheng"))
                and not (call(enemy,"hasSkills","fankui|guixin") and not call(self.player,"hasSkill","paoxiao"))
                and not call(enemy,"hasSkills","fenyong|jilei|zhichi")
                and self:isGoodTarget(enemy,self.enemies,slash) and not self:slashProhibit(slash,enemy) and call(self.player,"getHp")>1 then
                return skill_seed(self,"noskurou","NosKurouCard",request)
            end
        end
    end
    if call(self.player,"getHp")==1 and self:getCardsNum("Analeptic")>=1 then
        return skill_seed(self,"noskurou","NosKurouCard",request)
    end

    --Suicide by NosKurou
    local nextplayer = self.player:getNextAlive()
    if call(self.player,"getHp")==1 and self.player:getRole()~="lord" and self.player:getRole()~="renegade" then
        local to_death = false
        if self:isFriend(nextplayer) then
            for _,p in sgs.qlist(call(self.room,"getOtherPlayers",self.player))do
                if call(p,"hasSkill","xiaoguo") and not self:isFriend(p) and not call(p,"isKongcheng")
                    and self.role=="rebel" and call(self.player,"getEquips"):isEmpty() then
                    to_death = true
                    break
                end
            end
            if not to_death and not self:willSkipPlayPhase(nextplayer) then
                if call(nextplayer,"hasSkill","jieyin") and call(self.player,"isMale") then return end
                if call(nextplayer,"hasSkill","qingnang") then return end
            end
        end
        if self.player:getRole()=="rebel" and not self:isFriend(nextplayer) then
            if not self:willSkipPlayPhase(nextplayer) or call(nextplayer,"hasSkill","shensu") then
                to_death = true
            end
        end
        local lord = getLord(self.player)
        if self.player:getRole()=="loyalist" then
            if lord and call(lord,"getHandcardNum")==0 and call(lord,"getEquips"):isEmpty() then return end
            if self:isEnemy(nextplayer) and not self:willSkipPlayPhase(nextplayer) then
                if call(nextplayer,"hasSkills","noslijian|lijian") and call(self.player,"isMale") and lord and call(lord,"isMale") then
                    to_death = true
                elseif call(nextplayer,"hasSkill","quhu") and lord and call(lord,"getHp")>call(nextplayer,"getHp") and not call(lord,"isKongcheng")
                    and call(lord,"inMyAttackRange",self.player) then
                    to_death = true
                end
            end
        end
        if to_death then
            local caopi = self.room:findPlayerBySkillName("xingshang")
            if caopi and self:isEnemy(caopi) then
                if self.player:getRole()=="rebel" and call(self.player,"getHandcardNum")>3 then to_death = false end
                if self.player:getRole()=="loyalist" and lord and call(lord,"getCardCount",true)+2<=call(self.player,"getHandcardNum") then
                    to_death = false
                end
            end
            if #self.friends==1 and #self.enemies==1 and call(self.player,"aliveCount")==2 then to_death = false end
        end
        if to_death then
            self:setStrategyPlayerFlag(self.player,"NosKurou_toDie",true)
            self:setPriorityValue("NosKurouCard",0,"noskurou")
            return skill_seed(self,"noskurou","NosKurouCard",request)
        end
        self:setStrategyPlayerFlag(self.player,"NosKurou_toDie",false)
    end
end

sgs.ai_fill_skill.nosfanjian=function(self,inclusive,request)
    if call(self.player,"isKongcheng") then return nil end
    return skill_seed(self,"nosfanjian","NosFanjianCard",request)
end

sgs.ai_fill_skill.qingnang=function(self,inclusive,request)
    if call(self.player,"getHandcardNum")<1 then return nil end

    local cards = strategy_cards(self,self.player,"h")
    cards = sgs.QList2Table(cards)

    local compare_func = function(a,b)
        local v1 = self:getKeepValue(a)+( call(a,"isRed") and 50 or 0 )+( call(a,"isKindOf","Peach") and 50 or 0 )
        local v2 = self:getKeepValue(b)+( call(b,"isRed") and 50 or 0 )+( call(b,"isKindOf","Peach") and 50 or 0 )
        return v1<v2
    end
    table.sort(cards,compare_func)

    return selected_skill(self,"@QingnangCard="..call(cards[1],"getId"))
end

sgs.ai_fill_skill.jijiang=function(self,inclusive,request)
    for _,p in sgs.list(call(self.room,"getLieges","shu",self.player))do
        if self:isFriend(p) then
            return skill_seed(self,"jijiang","JijiangCard",request)
        end
    end
end

sgs.ai_fill_skill.yijue=function(self,inclusive,request)
    return skill_seed(self,"yijue","YijueCard",request)
end

sgs.ai_fill_skill.zhiheng=function(self,inclusive,request)
    return skill_seed(self,"zhiheng","ZhihengCard",request)
end

sgs.ai_fill_skill.kurou=function(self,inclusive,request)
    if not self:hasZhaxiangEffect(self.player)
    or (call(self.player,"getHp")==2 and call(self.player,"hasSkill","chanyuan")) then return end
    if (call(self.player,"getHp")>3 and call(self.player,"getHandcardNum")>call(self.player,"getHp"))
    or (call(self.player,"getHp")-call(self.player,"getHandcardNum")>=2)
    then
        local id = getKurouCard(self)
        if id then return selected_skill(self,"@KurouCard="..id) end
    end

    local function can_kurou_with_cb(self)
        if call(self.player,"getHp")>1 then return true end
        local has_save = false
        local huatuo = self.room:findPlayerBySkillName("jijiu")
        if huatuo and self:isFriend(huatuo) then
            for _,equip in sgs.list(call(huatuo,"getEquips"))do
                if call(equip,"isRed") then has_save = true break end
            end
            if not has_save then has_save = (call(huatuo,"getHandcardNum")>3) end
        end
        if has_save then return true end
        local handang = self.room:findPlayerBySkillName("nosjiefan")
        if handang and self:isFriend(handang) and getCardsNum("Slash",handang,self.player)>=1 then return true end
        return false
    end

    if (call(self.player,"hasWeapon","Crossbow") or self:getCardsNum("Crossbow")>0) or self:getCardsNum("Slash")>1 then
        local slash = call(self,"getEvaluationCard","slash")
        for _,enemy in ipairs(self.enemies)do
            if call(self.player,"canSlash",enemy) and self:slashIsEffective(slash,enemy)
                and self:isGoodTarget(enemy,self.enemies,slash) and not self:slashProhibit(slash,enemy) and can_kurou_with_cb(self) then
                local id = getKurouCard(self,true)
                if id then return selected_skill(self,"@KurouCard="..id) end
            end
        end
    end

    if call(self.player,"getHp")<=1 and self:getCardsNum("Analeptic")+self:getCardsNum("Peach")>1 then
        local id = getKurouCard(self)
        if id then return skill_seed(self,"kurou","KurouCard",request) end
    end
end

sgs.ai_fill_skill.fanjian=function(self,inclusive,request)
    if call(self.player,"isKongcheng") then return nil end
    return skill_seed(self,"fanjian","FanjianCard",request)
end

sgs.ai_fill_skill.guose=function(self,inclusive,request)
    local cards = self:addHandPile("he")
    cards = self:sortByUseValue(cards,true)
    local card = nil
    local has_weapon,has_armor = false,false

    for _,acard in ipairs(cards)do
        if call(acard,"isKindOf","Weapon") and not call(acard,"getSuit")==sgs.Card_Diamond then has_weapon = true end
    end

    for _,acard in ipairs(cards)do
        if call(acard,"isKindOf","Armor") and not call(acard,"getSuit")==sgs.Card_Diamond then has_armor = true end
    end

    for _,acard in ipairs(cards)do
        if call(acard,"getSuit")==sgs.Card_Diamond
        and ((self:getUseValue(acard)<sgs.ai_use_value.Indulgence) or inclusive)
        then
            local shouldUse = true

            if call(acard,"isKindOf","Armor") then
                if not self.player:getArmor() then shouldUse = false
                elseif call(self.player,"hasEquip",acard) and not has_armor and self:evaluateArmor()>0
                then shouldUse = false end
            end

            if call(acard,"isKindOf","Weapon") then
                if not self.player:getWeapon() then shouldUse = false
                elseif call(self.player,"hasEquip",acard) and not has_weapon
                then shouldUse = false end
            end

            if shouldUse then
                card = acard
                break
            end
        end
    end

    if not card then return nil end
    return selected_skill(self,"@GuoseCard="..call(card,"getEffectiveId"))
end

sgs.ai_fill_skill.jieyin=function(self,inclusive,request)
    if call(self.player,"getHandcardNum")<2 then return nil end
    if self:needBear() and not call(self.player,"isWounded") and self:isWeak() then return nil end

    local cards = strategy_cards(self,self.player,"h")
    cards = sgs.QList2Table(cards)

    local first,second
    cards = self:sortByUseValue(cards,true)
    for _,card in ipairs(cards)do
        if call(card,"isKindOf","TrickCard") then
            local dummy_use = dummy()
            self:useTrickCard(card,dummy_use)
            if not dummy_use.card then
                if not first then first = call(card,"getEffectiveId")
                elseif first and not second then second = call(card,"getEffectiveId")
                end
            end
            if first and second then break end
        end
    end

    for _,card in ipairs(cards)do
        if call(card,"getTypeId")~=sgs.Card_TypeEquip and (not self:isValuableCard(card) or call(self.player,"isWounded")) then
            if not first then first = call(card,"getEffectiveId")
            elseif first and first~=call(card,"getEffectiveId") and not second then second = call(card,"getEffectiveId")
            end
        end
        if first and second then break end
    end

    if not second or not first then return end
    return selected_skill(self,("@JieyinCard=%d+%d"):format(first,second))
end

sgs.ai_fill_skill.chuli=function(self,inclusive,request)

    local cards = strategy_cards(self,self.player,"he")
    cards = sgs.QList2Table(cards)
    cards = self:sortByUseValue(cards,true)

    if self:needToThrowArmor() then return selected_skill(self,"@ChuliCard="..self.player:getArmor():getEffectiveId()) end
    for _,card in ipairs(cards)do
        if not self:isValuableCard(card) then
            if call(card,"getSuit")==sgs.Card_Spade then return selected_skill(self,"@ChuliCard="..call(card,"getEffectiveId")) end
        end
    end
    for _,card in ipairs(cards)do
        if not self:isValuableCard(card) and not (call(self.player,"hasSkill","jijiu") and call(card,"isRed") and self:getOverflow()<2) then
            if call(card,"getSuit")==sgs.Card_Spade then return selected_skill(self,"@ChuliCard="..call(card,"getEffectiveId")) end
        end
    end
end

sgs.ai_fill_skill.lijian=function(self,inclusive,request)
    if call(self.player,"isNude") or call(self.room,"getAlivePlayers"):length()<3 then
        return
    end
    local card_id = self:getLijianCard()
    if card_id then return selected_skill(self,"@LijianCard="..card_id) end
end

sgs.ai_fill_skill.jianyan=function(self,inclusive,request)
    return skill_seed(self,"jianyan","JianyanCard",request)
end

sgs.ai_fill_skill.rende=function(self,inclusive,request)
    return skill_seed(self,"rende","ActiveSkillCard",request)
end

getFenweiValue=function(self,who,card,from)
    if not self:hasTrickEffective(card,who,from) then return 0 end
    if call(card,"isKindOf","AOE") then
        if not self:isFriend(who) then return 0 end
        local value = self:getAoeValueTo(card,who,from)
        if value<0 then return -value/30 end
    elseif call(card,"isKindOf","GodSalvation") then
        if not self:isEnemy(who) or not call(who,"isWounded") or call(who,"getHp")>=getBestHp(who) then return 0 end
        if self:isWeak(who) then return 1.2 end
        if call(who,"hasSkills",sgs.masochism_skill) then return 1.0 end
        return 0.9
    elseif call(card,"isKindOf","AmazingGrace") then
        if not self:isEnemy(who) or hasManjuanEffect(who) then return 0 end
        local v = 1.2
        local p = self.room:getCurrent()
        while call(p,"objectName")~=call(who,"objectName")do
            v = v*0.9
            p = p:getNextAlive()
        end
        return v
    end
    return 0
end

getPriorFriendsOfLiyu=function(self,lvbu)
    lvbu = lvbu or self.player
    local prior_friends = {}
    if not string.startsWith(call(self.room,"getMode"),"06_") and not known(self.world.enable_hegemony,"EnableHegemony") then
        if call(lvbu,"isLord") then
            for _,friend in ipairs(self:getFriends(lvbu,true))do
                if current_role(self,friend)=="loyalist" then table.insert(prior_friends,friend) end
            end
        elseif current_role(self,lvbu)=="loyalist" then
            local lord = self.room:getLord()
            if lord then prior_friends = { lord } end
        elseif call(self.room,"getMode")=="couple" then
            local diaochan = ai_unsupported("donor source_error: Room:getPlayer is not a native Room API","standard.couple_liyue")
            if diaochan then prior_friends = { diaochan } end
        end
    elseif call(self.room,"getMode")=="06_3v3" then
        if current_role(self,lvbu)=="loyalist" then
            for _,friend in ipairs(self:getFriends(lvbu,true))do
                if current_role(self,friend)=="lord" then table.insert(prior_friends,friend) break end
            end
        elseif current_role(self,lvbu)=="rebel" then
            for _,friend in ipairs(self:getFriends(lvbu,true))do
                if current_role(self,friend)=="renegade" then table.insert(prior_friends,friend) break end
            end
        end
    elseif call(self.room,"getMode")=="06_XMode" then
        -- XModeLeader/XModeBackup are player tags: only the viewer's own are projected.
        local leader = player_name(self,lvbu:getTag("XModeLeader") or false,"XModeLeader")
        local backup = 0
        if leader then
            backup = #(leader:getTag("XModeBackup") or {})
            if backup==0 then
                prior_friends = self:getFriends(lvbu,true)
            end
        end
    end
    return prior_friends
end

function SmartAIView:hasLiyuEffect(target,slash)
    local upperlimit = tonumber(call(self.player,"hasSkill","wushuang") and 2 or 1)
    if #self.friends_noself==0 or call(self.player,"hasSkill","jueqing") then return false end
    if not self:slashIsEffective(slash,target,self.player) then return false end

    local targets = { target }
    if not call(self.player,"hasSkill","jueqing") and call(target,"isChained") and call(slash,"isKindOf","NatureSlash") then
        for _,p in sgs.list(call(self.room,"getOtherPlayers",target))do
            if call(p,"isChained") and call(p,"objectName")~=call(self.player,"objectName") then table.insert(targets,p) end
        end
    end
    local unsafe = false
    for _,p in ipairs(targets)do
        if self:isEnemy(target) and not call(target,"isNude") then
            unsafe = true
            break
        end
    end
    if not unsafe then return false end

    local duel = call(self,"getEvaluationCard","duel")
    if call(self.player,"isLocked",duel) then return false end

    local enemy_null = 0
    for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
        if self:isFriend(p) then enemy_null = enemy_null-getCardsNum("Nullification",p,self.player) end
        if self:isEnemy(p) then enemy_null = enemy_null+getCardsNum("Nullification",p,self.player) end
    end
    enemy_null = enemy_null-self:getCardsNum("Nullification")
    if enemy_null<=-1 then return false end

    local prior_friends = getPriorFriendsOfLiyu(self)
    if #prior_friends==0 then return false end
    for _,friend in ipairs(prior_friends)do
        if self:hasTrickEffective(duel,friend,self.player) and self:isWeak(friend) and (getCardsNum("Slash",friend,self.player)<upperlimit or self:isWeak()) then
            return true
        end
    end

    if sgs.isJinkAvailable(self.player,target,slash) and getCardsNum("Jink",target,self.player)>=upperlimit
    and not self:needToLoseHp(target,self.player,slash) then return false end
    if call(slash,"getStrategyFlag","AIGlobal_KillOff") or (call(target,"getHp")==1 and self:isWeak(target) and self:getSaveNum()<1) then return false end

        if call(self.player,"hasSkill","wumou") and call(self.player,"getStrategyMark","&wrath")==0 and (self:isWeak() or not self:hasZhaxiangEffect(self.player)) then return true end
        if call(self.player,"hasSkills","jizhi|nosjizhi") or (call(self.player,"hasSkill","jilve") and call(self.player,"getStrategyMark","&bear")>0) then return false end
    if not string.startsWith(call(self.room,"getMode"),"06_") and not known(self.world.enable_hegemony,"EnableHegemony") and self.role~="rebel" then
        for _,friend in ipairs(self.friends_noself)do
            if self:hasTrickEffective(duel,friend,self.player) and self:isWeak(friend) and (getCardsNum("Slash",friend,self.player)<upperlimit or self:isWeak())
                and self:getSaveNum(true)<1 then
                return true
            end
        end
    end
    return false
end

do
local select_response=function(self,prompt) -- extra target for Collateral
    local dummy_use = dummy()
    dummy_use.current_targets = (self.player:getPropertyValue("extra_collateral") or ""):split("+")
    self:useCardCollateral(call(self,"getEvaluationCard","collateral"),dummy_use)
    if dummy_use.card and dummy_use.to:length()==2 then
        local first = dummy_use.to:at(0):objectName()
        local second = dummy_use.to:at(1):objectName()
        return "@ExtraCollateralCard=.->"..first.."+"..second
    end
end
sgs.ai_skill_use["@@nosmieji"]=function(self,prompt,method,pattern,request)return response_choice(self,select_response(self,prompt,method))end
end

do
local select_response=function(self,prompt)
    self.enemies = self:sort(self.enemies,"handcard_defense")
    local tuxi_mark = call(self.player,"getStrategyMark","tuxi")
    local targets = {}

    local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
    local luxun = self.room:findPlayerBySkillName("lianying") or self.room:findPlayerBySkillName("noslianying")
    local dengai = self.room:findPlayerBySkillName("tuntian")
    local jiangwei = self.room:findPlayerBySkillName("zhiji")
    local zhijiangwei = self.room:findPlayerBySkillName("beifa")

    local add_player = function (player,isfriend)
        if call(player,"getHandcardNum")<call(self.player,"getHandcardNum") then return #targets end
        if call(player,"getHandcardNum")==0 or call(player,"objectName")==call(self.player,"objectName") then return #targets end
        if self:objectiveLevel(player)==0 and call(player,"isLord") and call(self,"getRoleCounts")["rebel"]>1 then return #targets end

        local f = false
        for _,c in ipairs(targets)do
            if c==call(player,"objectName") then
                f = true
                break
            end
        end

        if not f then table.insert(targets,call(player,"objectName")) end

        if isfriend and isfriend==1 then
            self:setStrategyPlayerFlag(self.player,"tuxi_isfriend_"..call(player,"objectName"),true)
        end
        return #targets
    end

    local parseTuxiCard = function()
        if #targets==0 then return "." end
        local s = table.concat(targets,"+")
        return "@TuxiCard=.->"..s
    end

    local lord = self.room:getLord()
    if lord and self:isEnemy(lord) and turncount(self)<=1 and not call(lord,"isKongcheng") then
        if add_player(lord)==tuxi_mark then return parseTuxiCard() end
    end

    if jiangwei and self:isFriend(jiangwei) and call(jiangwei,"getStrategyMark","zhiji")==0 and call(jiangwei,"getHandcardNum")==1
            and self:getEnemyNumBySeat(self.player,jiangwei)<=(call(jiangwei,"getHp")>=3 and 1 or 0) then
        if add_player(jiangwei,1)==tuxi_mark  then return parseTuxiCard() end
    end

    if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai)==0 )
            and call(dengai,"hasSkill","zaoxian") and call(dengai,"getStrategyMark","zaoxian")==0 and call(dengai,"getPile","field"):length()==2 and add_player(dengai,1)==tuxi_mark then
        return parseTuxiCard()
    end

    if zhugeliang and self:isFriend(zhugeliang) and call(zhugeliang,"getHandcardNum")==1 and self:getEnemyNumBySeat(self.player,zhugeliang)>0 then
        if call(zhugeliang,"getHp")<=2 then
            if add_player(zhugeliang,1)==tuxi_mark then return parseTuxiCard() end
        else
            local flag = string.format("%s_%s_%s","visible",call(self.player,"objectName"),call(zhugeliang,"objectName"))
            local cards = sgs.QList2Table(strategy_cards(self,zhugeliang,"h"))
            if #cards==1 and (call(cards[1],"hasFlag","visible") or call(cards[1],"hasFlag",flag)) then
                if call(cards[1],"isKindOf","TrickCard") or call(cards[1],"isKindOf","Slash") or call(cards[1],"isKindOf","EquipCard") then
                    if add_player(zhugeliang,1)==tuxi_mark then return parseTuxiCard() end
                end
            end
        end
    end

    if luxun and self:isFriend(luxun) and call(luxun,"getHandcardNum")==1 and self:getEnemyNumBySeat(self.player,luxun)>0 then
        local flag = string.format("%s_%s_%s","visible",call(self.player,"objectName"),call(luxun,"objectName"))
        local cards = sgs.QList2Table(strategy_cards(self,luxun,"h"))
        if #cards==1 and (call(cards[1],"hasFlag","visible") or call(cards[1],"hasFlag",flag)) then
            if call(cards[1],"isKindOf","TrickCard") or call(cards[1],"isKindOf","Slash") or call(cards[1],"isKindOf","EquipCard") then
                if add_player(luxun,1)==tuxi_mark  then return parseTuxiCard() end
            end
        end
    end

    if zhijiangwei and self:isFriend(zhijiangwei) and call(zhijiangwei,"getHandcardNum")==1 and
        self:getEnemyNumBySeat(self.player,zhijiangwei)<=(call(zhijiangwei,"getHp")>=3 and 1 or 0) then
        local isGood
            local slash = call(self,"getEvaluationCard","slash")
        for _,enemy in ipairs(self.enemies)do
            if call(zhijiangwei,"canSlash",enemy,slash) and not self:slashProhibit(slash,enemy,zhijiangwei)
            and self:slashIsEffective(slash,enemy,zhijiangwei) and self:isGoodTarget(enemy,self.enemies)
            and self:getDefenseSlash(enemy)<4 then
                isGood = true
            end
        end
        if isGood and add_player(zhijiangwei,1)==tuxi_mark  then return parseTuxiCard() end
    end

    for i = 1,#self.enemies,1 do
        local p = self.enemies[i]
        local cards = sgs.QList2Table(strategy_cards(self,p,"h"))
        local flag = string.format("%s_%s_%s","visible",call(self.player,"objectName"),call(p,"objectName"))
        for _,card in ipairs(cards)do
            if (call(card,"hasFlag","visible") or call(card,"hasFlag",flag)) and (call(card,"isKindOf","Peach") or call(card,"isKindOf","Nullification") or call(card,"isKindOf","Analeptic") ) then
                if add_player(p)==tuxi_mark  then return parseTuxiCard() end
            end
        end
    end

    for i = 1,#self.enemies,1 do
        local p = self.enemies[i]
        if call(p,"hasSkills","jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
            if add_player(p)==tuxi_mark  then return parseTuxiCard() end
        end
    end

    for i = 1,#self.enemies,1 do
        local p = self.enemies[i]
        local x = call(p,"getHandcardNum")
        local good_target = true
        if x==1 and self:needKongcheng(p) then good_target = false end
        if x>=2 and call(p,"hasSkill","tuntian") and call(p,"hasSkill","zaoxian",true) then good_target = false end
        if good_target and add_player(p)==tuxi_mark then return parseTuxiCard() end
    end


    if luxun and add_player(luxun,(self:isFriend(luxun) and 1 or nil))==tuxi_mark then
        return parseTuxiCard()
    end

    if dengai and self:isFriend(dengai) and call(dengai,"hasSkill","zaoxian") and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai)==0 ) and add_player(dengai,1)==tuxi_mark then
        return parseTuxiCard()
    end

    local others = call(self.room,"getOtherPlayers",self.player)
    for _,other in sgs.list(others)do
        if self:objectiveLevel(other)>=0 and not (call(other,"hasSkill","tuntian") and call(other,"hasSkill","zaoxian",true)) and add_player(other)==tuxi_mark then
            return parseTuxiCard()
        end
    end

    for _,other in sgs.list(others)do
        if self:objectiveLevel(other)>=0 and not (call(other,"hasSkill","tuntian") and call(other,"hasSkill","zaoxian",true)) and math.random(0,5)<=1 and not call(self,"hasSkills","qiaobian") then
            add_player(other)
        end
    end

    return parseTuxiCard()
end
sgs.ai_skill_use["@@tuxi"]=function(self,prompt,method,pattern,request)return response_choice(self,select_response(self,prompt,method))end
end

do
local select_response=function(self,prompt)
    local liuxie = self.room:findPlayerBySkillName("huangen")
    if liuxie and self:isFriend(liuxie) and not self:isWeak(liuxie) then return "." end

    local card = tag_event(self,"fenwei").card
    local from = tag_event(self,"fenwei").from

    local players = sgs.QList2Table(call(self.room,"getAllPlayers"))
    players = self:sort(players,"defense")
    local target_table = {}
    local targetslist = (self.player:getPropertyValue("fenwei_targets") or ""):split("+")
    local value = 0
    for _,player in ipairs(players)do
        if not (call(player,"hasSkill","danlao") or (call(player,"hasSkills","jianxiong|nosjianxiong") and not self:isWeak(player)))
        and table.contains(targetslist,call(player,"objectName")) then
            local val = getFenweiValue(self,player,card,from)
            if val>0 then
                value = value+val
                table.insert(target_table,call(player,"objectName"))
            end
        end
    end
    if #target_table==0 or value/(call(self.room,"alivePlayerCount")-1)<0.55 then return "." end
    return "@FenweiCard=.->"..table.concat(target_table,"+")
end
sgs.ai_skill_use["@@fenwei"]=function(self,prompt,method,pattern,request)return response_choice(self,select_response(self,prompt,method))end
end

sgs.ai_card_intention.FenweiCard = function(self,card,from,tos)
    if self.player:getTag("fenwei")==nil then return end
    local cardx = tag_event(self,"fenwei").card
    local from = tag_event(self,"fenwei").from
    if not cardx then return end
    local intention = (call(cardx,"isKindOf","AOE") and -50 or 50)
    for _,to in ipairs(tos)do
        if call(to,"hasSkill","danlao") or not self:hasTrickEffective(cardx,to,from) then continue end
        if call(cardx,"isKindOf","GodSalvation") and not call(to,"isWounded") then continue end
        sgs.updateIntention(from,to,intention)
    end
end

do
local select_response=function(self,prompt)
    -- LianyingMoveData (a card move) is not projected. Only Qianxun moves for reason
    -- "qianxun", and it leaves the moved hand in the viewer's own qianxun pile.
    if call(self.player,"hasSkill","qianxun") and (self.player:getPileCount("qianxun") or 0)>0 then
        ai_unsupported("Lianying move reason is not projected","lianying_move_reason")
    end
    local effect = nil
    local upperlimit = call(self.player,"getStrategyMark","lianying")

    local targets = {}
    if call(self.player,"getPhase")<=sgs.Player_Play then
        table.insert(targets,call(self.player,"objectName"))
        if upperlimit==1 then return "@LianyingCard=.->"..call(self.player,"objectName") end
    end
    local exclude_self,sn_dis_eff = false,nil
    if effect and (call(effect.card,"isKindOf","Snatch") or call(effect.card,"isKindOf","Dismantlement"))
        and call(effect.from,"isAlive") and self:isEnemy(effect.from) then
        if call(self.player,"getEquips"):isEmpty() then
            exclude_self = true
        else
            sn_dis_eff = true
        end
    end
    if hasManjuanEffect(self.player) then exclude_self = true end
    if not exclude_self and effect and call(effect.card,"isKindOf","FireAttack") and call(effect.from,"isAlive")
        and not call(effect.from,"isKongcheng") and self:isEnemy(effect.from) then
        exclude_self = true
    end

    local getValue = function(friend)
        local def = self:getDefense(friend)
        if call(friend,"objectName")==call(self.player,"objectName") then
            if sn_dis_eff then def = def+5 else def = def-2 end
        end
        return def
    end
    local cmp = function(a,b)
        return getValue(a)<getValue(b)
    end
    table.sort(self.friends,cmp)

    for _,friend in ipairs(self.friends)do
        if not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) and not table.contains(targets,call(friend,"objectName"))
            and not (exclude_self and call(friend,"objectName")==call(self.player,"objectName")) then
            table.insert(targets,call(friend,"objectName"))
            if #targets==upperlimit then break end
        end
    end
    if #targets>0 then return "@LianyingCard=.->"..table.concat(targets,"+") end
    return "."
end
sgs.ai_skill_use["@@lianying"]=function(self,prompt,method,pattern,request)return response_choice(self,select_response(self,prompt,method))end
end

do
local select_response=function(self,prompt,method)
    local others = call(self.room,"getOtherPlayers",self.player)
    local slash = CardView.new(known(self.player:getTag("liuli-card"),"liuli-card"))
    others = sgs.QList2Table(others)
    local source
    for _,player in ipairs(others)do
        if call(player,"getStrategyFlag","LiuliSlashSource") then
            source = player
            break
        end
    end
    self.enemies = self:sort(self.enemies,"defense")

    local doLiuli = function(who)
        if not self:isFriend(who) and call(who,"hasSkills","leiji|nosleiji|olleiji")
            and (self:hasSuit("spade",true,who) or call(who,"getHandcardNum")>=3)
            and (getKnownCard(who,self.player,"Jink",true)>=1 or self:hasEightDiagramEffect(who)) then
            return "."
        end

        local cards = strategy_cards(self,self.player,"h")
        cards = sgs.QList2Table(cards)
        cards = self:sortByKeepValue(cards)
        for _,card in ipairs(cards)do
            if not call(self.player,"isCardLimited",card,method) and call(self.player,"canSlash",who) then
                if self:isFriend(who) and not (isCard("Peach",card,self.player) or isCard("Analeptic",card,self.player)) then
                    return "@LiuliCard="..call(card,"getEffectiveId").."->"..call(who,"objectName")
                else
                    return "@LiuliCard="..call(card,"getEffectiveId").."->"..call(who,"objectName")
                end
            end
        end

        local cards = strategy_cards(self,self.player,"e")
        cards=sgs.QList2Table(cards)
        cards = self:sortByKeepValue(cards)
        for _,card in ipairs(cards)do
            local range_fix = 0
            if call(card,"isKindOf","Weapon") then range_fix = range_fix+sgs.weapon_range[call(card,"getClassName")]-call(self.player,"getAttackRange",false) end
            if call(card,"isKindOf","OffensiveHorse") then range_fix = range_fix+1 end
            if not call(self.player,"isCardLimited",card,method) and call(self.player,"canSlash",who,nil,true,range_fix) then
                return "@LiuliCard="..call(card,"getEffectiveId").."->"..call(who,"objectName")
            end
        end
        return "."
    end

    for _,enemy in ipairs(self.enemies)do
        if not (source and call(source,"objectName")==call(enemy,"objectName")) then
            local ret = doLiuli(enemy)
            if ret~="." then return ret end
        end
    end

    for _,player in ipairs(others)do
        if self:objectiveLevel(player)==0 and not (source and call(source,"objectName")==call(player,"objectName")) then
            local ret = doLiuli(player)
            if ret~="." then return ret end
        end
    end


    self.friends_noself = self:sort(self.friends_noself,"defense")
    self.friends_noself = sgs.reverse(self.friends_noself)


    for _,friend in ipairs(self.friends_noself)do
        if not self:slashIsEffective(slash,friend) or self:findLeijiTarget(friend,50,source) then
            if not (source and call(source,"objectName")==call(friend,"objectName")) then
                local ret = doLiuli(friend)
                if ret~="." then return ret end
            end
        end
    end

    for _,friend in ipairs(self.friends_noself)do
        if source~=friend and self:needToLoseHp(friend,source,call(self,"getEvaluationCard","slash")) then
                local ret = doLiuli(friend)
                if ret~="." then return ret end
            end
        end

    if (self:isWeak() or self:ajustDamage(source,nil,1,slash)>1) and call(source,"hasWeapon","Axe") and call(source,"getCardCount",true)>2
      and not self:getCard("Peach") and not self:getCard("Analeptic") then
        for _,friend in ipairs(self.friends_noself)do
            if not self:isWeak(friend) then
                if not (source and call(source,"objectName")==call(friend,"objectName")) then
                    local ret = doLiuli(friend)
                    if ret~="." then return ret end
                end
            end
        end
    end

    if (self:isWeak() or self:ajustDamage(source,nil,1,slash)>1) and not self:getCard("Jink") then
        for _,friend in ipairs(self.friends_noself)do
            if not self:isWeak(friend) or (self:hasEightDiagramEffect(friend) and getCardsNum("Jink",friend)>=1) then
                if not (source and call(source,"objectName")==call(friend,"objectName")) then
                    local ret = doLiuli(friend)
                    if ret~="." then return ret end
                end
            end
        end
    end
    return "."
end
sgs.ai_skill_use["@@liuli"]=function(self,prompt,method,pattern,request)return response_choice(self,select_response(self,prompt,method))end
end

sgs.ai_skill_invoke.qianxun = function(self,data)
    local effect = data:toCardEffect()
    if call(effect.card,"isKindOf","Collateral") and self.player:getWeapon() then
        local victim = player_name(self,self.player:getTag("collateralVictim") or false,"collateral victim")
        if victim and self:selectCollateralSlash(victim,effect.from)~="." then return false end
    end
    if call(self.player,"getPhase")==sgs.Player_Judge then
        if call(effect.card,"isKindOf","Lightning") and self:isWeak() and self:getCardsNum("Peach")+self:getCardsNum("Analeptic")>0 then return false end
        return true
    end
    local current = self.room:getCurrent()
    if current and self:isFriend(current) and effect.from and self:isFriend(effect.from) then return true end
    if call(effect.card,"isKindOf","Duel") and sgs.ai_skill_cardask["duel-slash"](self,data,nil,effect.from)~="." then return false end
    if call(effect.card,"isKindOf","AOE") and sgs.ai_skill_cardask.aoe(self,data,nil,effect.from,call(effect.card,"objectName"))~="." then return false end
    if call(self.player,"getHandcardNum")<self:getLeastHandcardNum(self.player) then return true end
    local l_lim,u_lim = math.max(2,self:getLeastHandcardNum(self.player)),math.max(5,#self.friends)
    if u_lim<=l_lim then u_lim = l_lim+1 end
    return math.random(0,100)>=(call(self.player,"getHandcardNum")-l_lim)/(u_lim-l_lim+1)*100
end

sgs.ai_skill_invoke["tishen"] = function(self,data)
    local cards = strategy_cards(self,self.player,"h")
    cards = sgs.QList2Table(cards)
    local peaches = 0
    local slashtarget = 0
    for _,card in ipairs(cards)do
        if call(card,"isKindOf","Peach") then
            peaches = peaches+1
        end
        if call(card,"isKindOf","Slash") then
            for _,enemy in ipairs(self.enemies)do
                if call(self.player,"canSlash",enemy,card,true) and self:isGoodTarget(enemy,self.enemies,card)
                then
                    slashtarget = slashtarget+1
                end
            end
        end
    end
    -- QVariant::toInt of the own property, as the donor reads it (0 when unset).
    local tishen_hp = tonumber(self.player:getPropertyValue("tishen_hp")) or 0

    if call(self.player,"getHp")<=1 and tishen_hp-call(self.player,"getHp")>0 and peaches==0 then return true end
    if tishen_hp-call(self.player,"getHp")>1 and slashtarget>0 then return true end
    return false
end

sgs.ai_skill_invoke.luoshen = function(self,data)
    if call(self.player,"getStrategyFlag","AI_doNotInvoke_luoshen") then
        self:setStrategyPlayerFlag(self.player,"AI_doNotInvoke_luoshen",false)
        return
    end
    if call(self.player,"getStrategyFlag","AI_Luoshen_Conflict_With_Guanxing") and observed_mark(self,self.player,"AI_loushen_times")==0 then return end
    if self:willSkipPlayPhase() then
        local erzhang = self.room:findPlayerBySkillName("guzheng")
        if erzhang and self:isEnemy(erzhang) and self:getOverflow()>1 then return false end
        if call(self.player,"getPile","incantation"):length()>0 then
            local card = visible_card(self,call(self.player,"getPile","incantation"):first())
            if not call(self.player,"getJudgingArea"):isEmpty() and not call(self.player,"containsTrick","YanxiaoCard") and not self:hasWizard(self.enemies,true) then
                local trick = call(self.player,"getJudgingArea"):last()
                if call(trick,"isKindOf","Indulgence") then
                    if call(card,"getSuit")==sgs.Card_Heart or (call(self.player,"hasSkill","hongyan") and call(card,"getSuit")==sgs.Card_Spade) then return false end
                elseif call(trick,"isKindOf","SupplyShortage") then
                    if call(card,"getSuit")==sgs.Card_Club then return false end
                end
            end
            local zhangbao = self.room:findPlayerBySkillName("yingbing")
            if zhangbao and self:isEnemy(zhangbao) and not call(zhangbao,"hasSkill","manjuan")
                and (call(card,"isRed") or (call(self.player,"hasSkill","hongyan") and call(card,"getSuit")==sgs.Card_Spade)) then return false end
        end
    end
    return true
end

sgs.ai_choicemade_filter.skillInvoke.luoshen = function(self,player,promptlist)
    if call(self.player,"getStrategyFlag","AI_Luoshen_Conflict_With_Guanxing") then
        if promptlist[#promptlist]=="yes" then
            strategy_mark(self,player,"AI_loushen_times",math.max(0,observed_mark(self,player,"AI_loushen_times")-1))
        else
            self:setStrategyPlayerFlag(self.player,"AI_Luoshen_Conflict_With_Guanxing",false)
            strategy_mark(self,self.player,"AI_loushen_times",0)
        end
    end
end

sgs.ai_skill_playerchosen.liyu = function(self,targets)
    local enemies = {}
    for _,target in sgs.list(targets)do
        if self:isEnemy(target) then table.insert(enemies,target) end
    end
    -- should give one card to Lv Bu
    local damage = current_damage(self)
    local lvbu = damage.from
    if not lvbu then return nil end
    local duel = call(self,"getEvaluationCard","duel")
    if call(lvbu,"isLocked",duel) then
        if self:isFriend(lvbu) and self:needToThrowArmor() and #enemies>0 then
            return enemies[1]
        else
            return nil
        end
    end
    if self:isFriend(lvbu) then
        if not self:isWeak() or self:needKongcheng() then
            return enemies[1]
        else
            return nil
        end
    else
        if call(self.player,"getEquips"):isEmpty() then
            local all_peach = true
            for _,card in sgs.list(strategy_cards(self,self.player,"h"))do
                if not isCard("Peach",card,lvbu) then all_peach = false break end
            end
            if all_peach then return nil end
        end
        local upperlimit = tonumber(call(lvbu,"hasSkill","wushuang") and 2 or 1)
        local prior_friends = getPriorFriendsOfLiyu(self,lvbu)
        if #prior_friends>0 then
            for _,friend in ipairs(prior_friends)do
                if self:hasTrickEffective(duel,friend,lvbu) then
                    return friend
                end
            end
        end
        if self:getValuableCard(self.player) then return nil end
        local valuable = 0
        for _,card in sgs.list(strategy_cards(self,self.player,"h"))do
            if self:isValuableCard(card) then valuable = valuable+1 end
        end
        if valuable/call(self.player,"getHandcardNum")>0.5 then return nil end
    end

    -- the target of the Duel
    enemies = self:sort(enemies,"defense")
    for _,enemy in ipairs(enemies)do
        if self:hasTrickEffective(duel,enemy,lvbu) then
            if not (self:isFriend(lvbu) and getCardsNum("Slash",enemy,self.player)>upperlimit and self:isWeak(lvbu)) then
                return enemy
            end
        end
    end
end

sgs.ai_skill_choice.nosguhuo = function(self,choices)
    local yuji = self.room:findPlayerBySkillName("nosguhuo")
    -- The declaration lives in the NosGuhuoType room tag and the choice's string data.
    local nosguhuoname = ai_unsupported("NosGuhuo declaration is not projected","nosguhuo_type")
    if nosguhuoname=="peach+analeptic" then nosguhuoname = "peach" end
    local nosguhuocard = call(self,"getEvaluationCard",nosguhuoname)
    if self:getRestCardsNum(call(nosguhuocard,"getClassName"),yuji)<1 and call(self.player,"getHp")>0 then return "question" end
    if call(nosguhuocard,"getClassName")=="AmazingGrace" then return "noquestion" end
    if call(nosguhuocard,"getClassName"):match("Slash") then
        if call(yuji,"getState")~="robot" and math.random(1,4)==1 and not source_player(self,"questioner") and self:isEnemy(yuji) then return "question" end
        if not self:hasCrossbowEffect(yuji) then return "noquestion" end
    end
    if call(yuji,"getStrategyFlag","NosGuhuoFailed") and math.random(1,6)==1 and self:isEnemy(yuji) and call(self.player,"getHp")>=3
    and call(self.player,"getHp")>call(self.player,"getLostHp") then return "question" end
    local x = math.random(1,5)
    self.friends = self:sort(self.friends,"hp")
    if call(self.player,"getHp")<2 and self:getCardsNum("Peach")<1 and call(self.room,"alivePlayerCount")>2 then return "noquestion" end
    if self:isFriend(yuji) or source_player(self,"questioner") then return "noquestion"
    elseif call(self.player,"getHp")<call(self.friends[#self.friends],"getHp")
    then return "noquestion"end
    if self:needToLoseHp(self.player) and not call(self.player,"hasSkills",sgs.masochism_skill) and x>1 and self:isEnemy(yuji) then return "question" end
    local questioner
    for _,friend in ipairs(self.friends)do
        if call(friend,"getHp")==call(self.friends[#self.friends],"getHp") then
            if call(friend,"hasSkills","nosrende|rende|kuanggu|kofkuanggu|zaiqi|buqu|nosbuqu|yinghun|longhun|xueji|baobian") then
                questioner = friend
                break
            end
        end
    end
    if not questioner then questioner = self.friends[#self.friends] end
    return call(self.player,"objectName")==call(questioner,"objectName") and x>1 and "question" or "noquestion"
end

sgs.ai_choicemade_filter.skillChoice.nosguhuo = function(self,player,promptlist)
    if promptlist[#promptlist]=="question" then
        remember_source(self,"questioner",player)
        local yuji = self.room:findPlayerBySkillName("nosguhuo")
        if not yuji then return end
        local nosguhuoname = ai_unsupported("NosGuhuo declaration is not projected","nosguhuo_type")
        if nosguhuoname=="peach+analeptic" or nosguhuoname=="peach" then
            sgs.updateIntention(player,yuji,80)
            return
        end
        local nosguhuocard = call(self,"getEvaluationCard",nosguhuoname)
        if nosguhuocard then
            if self:getRestCardsNum(call(nosguhuocard,"getClassName"),yuji)>0 then
                sgs.updateIntention(player,yuji,80)
                return
            end
        end
    else
        remember_source(self,"questioner",nil)
    end
end

sgs.ai_choicemade_filter.cardUsed.NosLijianCard=function(self,player,carduse)self:setCommonEventMemory("ai_lijian_effect",true)end

sgs.ai_choicemade_filter.cardUsed.LijianCard=function(self,player,carduse)self:setCommonEventMemory("ai_lijian_effect",true)end

sgs.ai_card_intention.LijianCard=function(self,card,from,tos)
    local first_role,second_role=current_role(self,tos[1]),current_role(self,tos[2])
    if first_role==second_role then
        if current_role(self,from)=="rebel" and first_role==current_role(self,from) and call(tos[1],"getHp")==1 then
        elseif call(tos[1],"hasSkill","hunzi") and call(tos[1],"getHp")==2 and call(tos[1],"getStrategyMark","hunzi")==0 then
        else sgs.updateIntentions(from,tos,40) end
    elseif not call(tos[1],"hasSkill","wuhun") then
        sgs.updateIntention(from,tos[1],80)
    end
end

sgs.ai_card_intention.LiuliCard=function(self,card,from,to)
    self:setCommonEventMemory("ai_liuli_effect",true)
    self:setCommonEventMemory("ai_liuli_user",not self:hasExplicitRebel()and from or nil)
end

sgs.ai_skill_use_func.GuoseCard = function(card,use,self)
    self.friends = self:sort(self.friends)
    local id = call(card,"getEffectiveId")
    local indul_only = call(self.player,"handCards"):contains(id)
    local rcard = visible_card(self,id)
    if not indul_only and not call(self.player,"isJilei",rcard)
    then
        self:setPriorityValue("GuoseCard",5.5,"standard")
        for _,friend in ipairs(self.friends)do
            if call(friend,"containsTrick","indulgence")
            and self:willSkipPlayPhase(friend)
            and not call(friend,"hasSkills","shensu|qingyi|qiaobian")
            and (self:isWeak(friend) or self:getOverflow(friend)>1)
            then
                for _,c in sgs.list(call(friend,"getJudgingArea"))do
                    if call(c,"isKindOf","Indulgence")
                    and call(self.player,"canDiscard",friend,call(card,"getEffectiveId"))
                    then
                        use.card = card
                        use.to:append(friend)
                        return
                    end
                end
            end
        end
    end

    local indulgence = call(self,"evaluateSkillCard","guose","indulgence",{id})
    if not call(self.player,"isLocked",indulgence) then
        local dummy_use = dummy()
        self:useCardIndulgence(indulgence,dummy_use)
        if dummy_use.card then
            use.card = card
            self:setPriorityValue("GuoseCard",call(self,"getPriorityValue","Indulgence"),"standard")
            use.to = dummy_use.to
            return
        end
    end

    self:setPriorityValue("GuoseCard",5.5,"standard")
    if not indul_only and not call(self.player,"isJilei",rcard) then
        for _,friend in ipairs(self.friends)do
            if call(friend,"containsTrick","indulgence")
            and self:willSkipPlayPhase(friend)
            then
                for _,c in sgs.list(call(friend,"getJudgingArea"))do
                    if call(c,"isKindOf","Indulgence") and call(self.player,"canDiscard",friend,call(card,"getEffectiveId"))
                    then
                        use.card = card
                        use.to:append(friend)
                        return
                    end
                end
            end
        end
    end

    if not indul_only and not call(self.player,"isJilei",rcard) then
        for _,friend in ipairs(self.friends)do
            if call(friend,"containsTrick","indulgence") then
                for _,c in sgs.list(call(friend,"getJudgingArea"))do
                    if call(c,"isKindOf","Indulgence") and call(self.player,"canDiscard",friend,call(card,"getEffectiveId")) then
                        use.card = card
                        use.to:append(friend)
                        return
                    end
                end
            end
        end
    end
end

local select_yiji=function(self,prompt)
    local target1,target2
    local yijicards1,yijicards2=yiji_cards(self,1),yiji_cards(self,2)
    local ids = {}
    local extra = self:getCardsNum("Jink")-call(self.player,"getHp")-self:getCardsNum("Peach")>0
    for _,c in sgs.list(strategy_cards(self,self.player,"h"))do
        if not extra and call(c,"isKindOf","Jink") or call(c,"isKindOf","Peach")
        or call(c,"isKindOf","Analeptic") then continue end
        table.insert(ids,call(c,"getId"))
    end
    for i=1,11 do
        if #ids<1 then break end
        local target,cardid = sgs.ai_skill_askforyiji.nosyiji(self,ids,call(self.room,"getOtherPlayers",self.player))
        if not target or target==self.player then continue end
        if not target1 or target1==target then
            target1 = target
            if #yijicards1<2 then table.insert(yijicards1,cardid) end
        elseif not target2 or target2==target then
            target2 = target
            if #yijicards2<2 then table.insert(yijicards2,cardid) end
        end
        table.removeOne(ids,cardid)
    end
    self:setStrategyMemory("yijicards1",yijicards1);self:setStrategyMemory("yijicards2",yijicards2)
    if not target1 then return "." end
    if target2 then return ("@YijiCard=.->%s+%s"):format(call(target1,"objectName"),call(target2,"objectName")) end
    return ("@YijiCard=.->%s"):format(call(target1,"objectName"))
end
sgs.ai_skill_use["@@yiji"]=function(self,prompt)return response_choice(self,select_yiji(self,prompt))end

sgs.ai_skill_discard.yiji=function(self,discard_num,min_num,optional,include_equip)
    for index=1,2 do
        local cards=yiji_cards(self,index)
        if #cards>0 then self:setStrategyMemory("yijicards"..index,{});local ids={};for _,id in ipairs(cards)do ids[#ids+1]=id end;return ids end
    end
end

sgs.ai_view_as.nosgongqi=function(card,player,place)
    if known(place,"NosGongqi place")~=sgs.Player_PlaceSpecial and call(card,"getTypeId")==sgs.Card_TypeEquip
        and not call(card,"hasFlag","using")then return material_spec(card,"nosgongqi","slash",true)end
end
sgs.ai_view_as.qingguo=function(card,player,place)
    if call(card,"isBlack")and known(place,"Qingguo place")==sgs.Player_PlaceHand then return material_spec(card,"qingguo","jink",true)end
end
sgs.ai_view_as.wusheng=function(card,player,place)
    if known(place,"Wusheng place")~=sgs.Player_PlaceSpecial and call(card,"isRed")and not call(card,"isKindOf","Peach")then
        return material_spec(card,"wusheng","slash",true)
    end
end
sgs.ai_view_as.longdan=function(card,player,place)
    if known(place,"Longdan place")==sgs.Player_PlaceHand then
        if call(card,"isKindOf","Jink")then return material_spec(card,"longdan","slash",true)
        elseif call(card,"isKindOf","Slash")then return material_spec(card,"longdan","jink",true)end
    end
end
sgs.ai_view_as.jijiu=function(card,player,place)
    if known(place,"Jijiu place")~=sgs.Player_PlaceSpecial and call(card,"isRed")then return material_spec(card,"jijiu","peach",true)end
end
sgs.ai_view_as.gdlonghun=function(card,player,place)
    known(place,"GDLonghun place")
    if place==sgs.Player_PlaceHand or place==sgs.Player_PlaceEquip then
        local name=({[2]="peach",[0]="nullification",[3]="fire_slash",[1]="jink"})[call(card,"getSuit")]
        if name then return material_spec(card,"gdlonghun",name,false)end
    end
end

sgs.ai_fill_skill.nosgongqi=function(self,inclusive,request)
    local cards = self:addHandPile("he")
    local equip_card
    cards = self:sortByUseValue(cards,true)
    for _,card in ipairs(cards)do
        if call(card,"getTypeId")==sgs.Card_TypeEquip and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive) then
            equip_card = card
            break
        end
    end
    if equip_card then
        return self:evaluateTurnConversion("nosgongqi","Slash",material_spec(equip_card,"nosgongqi","slash",true),request)
    end
end

sgs.ai_fill_skill.nosguose=function(self,inclusive,request)
    local cards = self:addHandPile("he")
    local card
    cards = self:sortByUseValue(cards,true)
    local has_weapon,has_armor = false,false
    for _,acard in ipairs(cards)  do
        if call(acard,"isKindOf","Weapon") and not (call(acard,"getSuit")==sgs.Card_Diamond) then has_weapon=true end
    end
    for _,acard in ipairs(cards)  do
        if call(acard,"isKindOf","Armor") and not (call(acard,"getSuit")==sgs.Card_Diamond) then has_armor=true end
    end
    for _,acard in ipairs(cards)  do
        if (call(acard,"getSuit")==sgs.Card_Diamond) and ((self:getUseValue(acard)<sgs.ai_use_value.Indulgence) or inclusive) then
            local shouldUse=true
            if call(acard,"isKindOf","Armor") then
                if not self.player:getArmor() then shouldUse = false
                elseif call(self.player,"hasEquip",acard) and not has_armor and self:evaluateArmor()>0 then shouldUse = false
                end
            end
            if call(acard,"isKindOf","Weapon") then
                if not self.player:getWeapon() then shouldUse = false
                elseif call(self.player,"hasEquip",acard) and not has_weapon then shouldUse = false
                end
            end
            if shouldUse then
                card = acard
                break
            end
        end
    end
    if not card then return nil end
    return self:evaluateTurnConversion("nosguose","Indulgence",{name="indulgence",skill="nosguose",
        suit=sgs.Card_NoSuit,number=0,subcards={call(card,"getEffectiveId")}},request)
end

sgs.ai_fill_skill.longdan=function(self,inclusive,request)
    local cards = self:addHandPile()
    local jink_card
    cards = self:sortByUseValue(cards,true)
    for _,card in ipairs(cards)  do
        if call(card,"isKindOf","Jink") then
            jink_card = card
            break
        end
    end
    if not jink_card then return nil end
    return self:evaluateTurnConversion("longdan","Slash",material_spec(jink_card,"longdan","slash",true),request)
end

sgs.ai_fill_skill.qixi=function(self,inclusive,request)
    local cards = self:addHandPile("he")
    local black_card
    cards = self:sortByUseValue(cards,true)
    local has_weapon = false
    for _,card in ipairs(cards)  do
        if call(card,"isKindOf","Weapon") and call(card,"isBlack") then has_weapon=true end
    end
    for _,card in ipairs(cards)  do
        if call(card,"isBlack") and ((self:getUseValue(card)<sgs.ai_use_value.Dismantlement) or inclusive or self:getOverflow()>0) then
            local shouldUse = true
            if call(card,"isKindOf","Armor") then
                if not self.player:getArmor() then shouldUse = false
                elseif call(self.player,"hasEquip",card) and not self:needToThrowArmor() then shouldUse = false
                end
            end
            if call(card,"isKindOf","Weapon") then
                if not self.player:getWeapon() then shouldUse = false
                elseif call(self.player,"hasEquip",card) and not has_weapon then shouldUse = false
                end
            end
            if call(card,"isKindOf","Slash") then
                local dummy_use = dummy()
                if self:getCardsNum("Slash")==1 then
                    self:useBasicCard(card,dummy_use)
                    if dummy_use.card then shouldUse = false end
                end
            end
            if self:getUseValue(card)>sgs.ai_use_value.Dismantlement and call(card,"isKindOf","TrickCard") then
                local dummy_use = dummy()
                self:useTrickCard(card,dummy_use)
                if dummy_use.card then shouldUse = false end
            end
            if shouldUse then
                black_card = card
                break
            end
        end
    end
    if black_card then
        return self:evaluateTurnConversion("qixi","Dismantlement",material_spec(black_card,"qixi","dismantlement",true),request)
    end
end

sgs.ai_fill_skill.wusheng=function(self,inclusive,request)
    local cards = self:addHandPile("he")
    cards = self:sortByUseValue(cards,true)
    local red_card = {}
    local useAll = false
    self.enemies = self:sort(self.enemies,"defense")
    for _,enemy in ipairs(self.enemies)do
        if call(enemy,"getHp")<2 and not call(enemy,"hasArmorEffect","EightDiagram")
        and call(self.player,"distanceTo",enemy)<=call(self.player,"getAttackRange") and self:isWeak(enemy)
        and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
        then useAll = true break end
    end

    local disCrossbow = false
    if self:getCardsNum("Slash")<2
    or call(self.player,"hasSkills","paoxiao|tenyearpaoxiao|olpaoxiao")
    then disCrossbow = true end

    local nuzhan_equip = false
    local nuzhan_equip_e = false
    self.enemies = self:sort(self.enemies,"defense")
    if call(self.player,"hasSkill","nuzhan") then
        for _,enemy in ipairs(self.enemies)do
            if not call(enemy,"hasArmorEffect","EightDiagram")
            and call(self.player,"distanceTo",enemy)<=call(self.player,"getAttackRange")
            and getCardsNum("Jink",enemy)<1
            then nuzhan_equip_e = true break end
        end
        for _,card in ipairs(cards)do
            if call(card,"isRed") and call(card,"isKindOf","TrickCard") and nuzhan_equip_e
            then nuzhan_equip = true break end
        end
    end

    local nuzhan_trick = false
    local nuzhan_trick_e = false
    self.enemies = self:sort(self.enemies,"defense")
    if call(self.player,"hasSkill","nuzhan") and not call(self.player,"getStrategyFlag","hasUsedSlash")
    and self:getCardsNum("Slash")>1 then
        for _,enemy in ipairs(self.enemies)do
            if  not call(enemy,"hasArmorEffect","EightDiagram")
            and call(self.player,"distanceTo",enemy)<=call(self.player,"getAttackRange")
            then nuzhan_trick_e = true break end
        end
        for _,card in ipairs(cards)do
            if call(card,"isRed") and call(card,"isKindOf","TrickCard") and nuzhan_trick_e
            then nuzhan_trick = true break end
        end
    end

    for _,card in ipairs(cards)do
        if call(card,"isRed") and not call(card,"isKindOf","Slash") and not (nuzhan_equip or nuzhan_trick)
        and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
        and (not isCard("Crossbow",card,self.player) or disCrossbow)
        and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or call(call(self,"getEvaluationCard","slash"),"getTargetModResidue",self.player)>0)
        then table.insert(red_card,card) end
    end

    if nuzhan_equip then
        for _,card in ipairs(cards)do
            if call(card,"isRed") and call(card,"isKindOf","EquipCard")
            then table.insert(red_card,card) end
        end
    end

    if nuzhan_trick then
        for _,card in ipairs(cards)do
            if call(card,"isRed") and call(card,"isKindOf","TrickCard")
            then table.insert(red_card,card) end
        end
    end

    for _,card in ipairs(red_card)do
        local slash = call(self,"evaluateSkillCard","wusheng","slash",{call(card,"getId")})
        if call(slash,"isAvailable",self.player)
        then return material_conversion(self,card,"wusheng","slash","Slash",false,request)end
    end
end

sgs.ai_fill_skill.gdlonghun=function(self,inclusive,request)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards)
    for _,c in sgs.list(cards)do
        local fs=self:evaluateTurnConversion("gdlonghun","FireSlash",{
            name="fire_slash",skill="gdlonghun",suit=sgs.Card_NoSuit,number=0,
            subcards={call(c,"getId")}},request)
        if call(c,"getSuit")==3
        and call(fs,"isAvailable",self.player)
        then return fs end
    end
end

sgs.ai_fill_skill.jijiu=function(self,inclusive,request)
    for _,card in ipairs(call(self,"sortByUseValue",call(self.player,"getCards","he"),true))do
        if call(card,"isRed")then return self:evaluateTurnConversion("jijiu","Peach",{
            name="peach",skill="jijiu",suit=sgs.Card_NoSuit,number=0,
            subcards={call(card,"getEffectiveId")}},request)end
    end
end

sgs.ai_skill_cardask["@nosqiuyuan-give"] = function(self,data,pattern,target)
    local cards = sgs.QList2Table(strategy_cards(self,self.player,"h"))
    cards = self:sortByKeepValue(cards)
    for _,card in ipairs(cards)do
        local e_card = call(self,"getPrintedCardById",call(card,"getEffectiveId"))
        if call(e_card,"isKindOf","Jink")
            and not (target and call(target,"isAlive") and call(target,"hasSkill","wushen") and (call(e_card,"getSuit")==sgs.Card_Heart or (call(target,"hasSkill","hongyan") and call(e_card,"getSuit")==sgs.Card_Spade))) then
            return "$"..call(card,"getEffectiveId")
        end
    end
    if (pattern=="Jink") then return "." end
    for _,card in ipairs(cards)do
        if not self:isValuableCard(card) and self:getKeepValue(card)<5 then return "$"..call(card,"getEffectiveId") end
    end
    return "$"..call(cards[1],"getEffectiveId")
end

sgs.ai_guhuo_card.nosguhuo = function(self,cname,class_name)
    if call(self.player,"getStrategyFlag",cname.."nosguhuoFailed") then return end
    local handcards = self:addHandPile("h")
    if #handcards>0 then
        handcards = self:sortByUseValue(handcards) -- 按保留值排序
        local hc,fake,question = {},{},#self.enemies
        for _,enemy in sgs.list(self.enemies)do
            if call(enemy,"getHp")<2 then question = question-1 end
        end
        for _,h in sgs.list(handcards)do
            if call(h,"isKindOf",class_name) and call(h,"getSuit")==2
            then table.insert(hc,h) end
        end
        for _,h in sgs.list(handcards)do
            if call(h,"isKindOf",class_name)
            then if call(h,"getSuit")~=2 then table.insert(hc,h) end
            elseif self:getCardsNum(class_name)>0
            then table.insert(fake,h) end
        end
        if question<1 then hc = handcards end
        self:setStrategyPlayerFlag(self.player,cname.."nosguhuoFailed",true)
        question = self.room:getCurrentDyingPlayer()
        if question and self:isFriend(question) and #hc>0
        then return "@NosGuhuoCard="..call(hc[1],"getEffectiveId")..":"..cname end
        if self:isWeak() then
            for _,h in sgs.list(handcards)do
                if class_name=="Analeptic" and not isCard("Peach,Analeptic",h,self.player)
                then return "@NosGuhuoCard="..call(h,"getEffectiveId")..":"..cname end
            end
            if #hc>0 then return"@NosGuhuoCard="..call(hc[1],"getEffectiveId")..":"..cname end
            if class_name=="Jink" then return"@NosGuhuoCard="..call(handcards[1],"getEffectiveId")..":"..cname end
        end
        if #fake>0 and self:isWeak()
        then return "@NosGuhuoCard="..call(fake[1],"getEffectiveId")..":"..cname end
        if #hc>1 or #hc>0 and call(hc[1],"getSuit")==2 then
            local index = 1
            if class_name=="Peach" or class_name=="Jink"
            or class_name=="Analeptic" then index = #hc end
            return "@NosGuhuoCard="..call(hc[index],"getEffectiveId")..":"..cname
        end
    end
end

sgs.ai_fill_skill.nosguhuo=function(self,inclusive,request)
    local cards = strategy_cards(self,self.player,"h")
    if cards:length()<1 then return end
    cards = self:sortByKeepValue(cards) -- 按保留值排序
    local can = true
    for _,ep in ipairs(self.enemies)do
        if call(ep,"getHp")>1 or #cards<2
        then can = false break end
    end
    local ps=known(AICardCatalog.patternNames(),"fixed pattern-name order")
    for i=1,9 do
        local name = ps[math.random(1,#ps)]
        local c = self:getEvaluationCard(name)
        if c and can and math.random(1,5)<3
        and call(c,"isAvailable",self.player)
        and (call(c,"isKindOf","BasicCard") or call(c,"isNDTrick"))
        and nosguhuo_play_count(self,name)<1
        and self:getRestCardsNum(call(c,"getClassName"))>0 then
            c=call(self,"evaluateSkillCard","nosguhuo",name,{call(cards[1],"getId")})
            local dummy = self:aiUseCard(c)
            if dummy.card then
                self.guhuo_to = dummy.to
                if call(c,"canRecast") and dummy.to:length()<1 then continue end
                return nosguhuo_filled(self,nosguhuo_proposal(cards[1],name),request)
            end
        end
    end
    can = #cards>2
    for _,ep in ipairs(self.enemies)do
        if self:isWeak(ep)
        then can = ep end
    end
    for _,h in ipairs(cards)do
        if call(h,"isAvailable",self.player)
        and (call(h,"isKindOf","BasicCard") or call(h,"isNDTrick"))
        and (can or self:getCardsNum(call(h,"getClassName"))>1) then
            local dummy = self:aiUseCard(h)
            if dummy.card then
                self.guhuo_to = dummy.to
                if call(h,"canRecast") and dummy.to:length()<1 then continue end
                return nosguhuo_filled(self,nosguhuo_proposal(h,call(h,"objectName")),request)
            end
        end
    end
    for _,h in ipairs(cards)do
        if call(h,"isAvailable",self.player) and call(h,"getSuit")==2
        and (call(h,"isKindOf","BasicCard") or call(h,"isNDTrick")) then
            local dummy = self:aiUseCard(h)
            if dummy.card then
                self.guhuo_to = dummy.to
                if call(h,"canRecast") and dummy.to:length()<1 then continue end
                return nosguhuo_filled(self,nosguhuo_proposal(h,call(h,"objectName")),request)
            end
        end
    end
    if self:isWeak() then
        local peach_str = sgs.ai_guhuo_card.nosguhuo(self,"peach","Peach")
        if peach_str and math.random(0,#cards)>2 then
            local dummy = call(self,"getEvaluationCard","peach")
            if call(dummy,"isAvailable",self.player) then
                dummy = self:aiUseCard(dummy)
                if dummy.card then
                    self.guhuo_to = dummy.to
                    return nosguhuo_filled(self,peach_str,request)
                end
            end
        end
    end
    local slash_str = sgs.ai_guhuo_card.nosguhuo(self,"slash","Slash")
    if slash_str and self:slashIsAvailable()
    and math.random(0,#cards)>1 then
        local dummy = self:aiUseCard(call(self,"getEvaluationCard","slash"))
        if dummy.card then
            self.guhuo_to = dummy.to
            return nosguhuo_filled(self,slash_str,request)
        end
    end
end

sgs.ai_skill_use_func.NosGuhuoCard=function(card,use,self)
    use.card=card
    local name=known(self._standard_nosguhuo_declaration,"selected NosGuhuo declaration")
    local marks,present=self:getStrategyMemory("standard.nosguhuo_play_marks")
    marks=present and marks or{};marks[name]=(marks[name]or 0)+1
    self:setStrategyMemory("standard.nosguhuo_play_marks",marks)
    use.to=self.guhuo_to
end

function sgs.ai_cardsview_valuable.nosjiefan(self,class_name,player)
    if observed_mark(self,player,"NosJiefanFailed-Clear")>5
    or self:getCardsNum("Slash")<1 then return end
    strategy_mark(self,player,"NosJiefanFailed-Clear",observed_mark(self,player,"NosJiefanFailed-Clear")+1)
    return response_skill_proposal("nosjiefan","NosJiefanCard")
end

function sgs.ai_cardsview_valuable.nosrenxin(self,class_name,player)
    local dying = self.room:getCurrentDyingPlayer()
    if not dying or dying==player or self:isEnemy(dying) then return nil end
    if call(dying,"isLord") and self:isFriend(dying) then return response_skill_proposal("nosrenxin","NosRenxinCard") end
    if hasManjuanEffect(dying) then
        local peach_num = 0
        for _,c in sgs.qlist(strategy_cards(self,player,"he"))do
            if isCard("Peach",c,player) then peach_num = peach_num+1 end
            if peach_num>1 then return nil end
        end
    end
    if self:playerGetRound(dying)<self:playerGetRound(self.player)
    then return nil end
    if call(player,"faceUp") then
        for _,c in sgs.qlist(strategy_cards(self,player,"h"))do
            if isCard("Peach",c,player) then return nil end
        end
        return response_skill_proposal("nosrenxin","NosRenxinCard")
    else
        if call(player,"getHp")<2 and getCardsNum("Jink,Analeptic",player,self.player)>0
        then return nil end
        return response_skill_proposal("nosrenxin","NosRenxinCard")
    end
end

function sgs.ai_cardsview.jijiang(self,class_name,player)
    local current = self.room:getCurrent()
    if current and call(current,"getKingdom")=="shu" and self:getOverflow(current)>2
    -- and not self:hasCrossbowEffect(current) then
     then
        self:setStrategyPlayerFlag(self.player,"stack_overflow_jijiang",true)
        local isfriend = self:isFriend(current,player)
        self:setStrategyPlayerFlag(self.player,"stack_overflow_jijiang",false)
        if isfriend then return response_skill_proposal("jijiang","JijiangCard") end
    end
    for _,card in sgs.list(strategy_cards(self,player,"h"))do
        if isCard("Slash",card,player) then return end
    end
    for _,p in sgs.list(call(self.room,"getLieges","shu",player))do
        self:setStrategyPlayerFlag(self.player,"stack_overflow_jijiang",true)
        local has_friend = self:isFriend(p,player)
        self:setStrategyPlayerFlag(self.player,"stack_overflow_jijiang",false)
        if has_friend then return response_skill_proposal("jijiang","JijiangCard") end
    end
end

for class,skill in pairs(skill_classes)do
    local callback=sgs.ai_skill_use_func[class]
    if type(callback)=="function"then
        local key,fn=class,callback
        sgs.ai_skill_use_func[class]=function(card,use,self,request)
            local value=fn(card,use,self,request)
            if use.card and type(use.card.isStrategySeed)=="function"and use.card:isStrategySeed()then
                use.card=skill_card(self,key,{},request)
            end
            return value
        end
    end
end
do
    local callback=sgs.ai_skill_use_func.rende
    sgs.ai_skill_use_func.rende=function(card,use,self,request)
        local value=callback(card,use,self,request)
        if use.card and type(use.card.isStrategySeed)=="function"and use.card:isStrategySeed()then
            use.card=rende_card(self,{},request)
        end
        return value
    end
end

sgs.ai_skill_use["@multi-jink-start"]=function(self,prompt,method,pattern,request)
    request=request or self.request
    local last_effect=self:getLastCardEffect()
    if type(last_effect)~="table"then ai_unsupported("last public CardEffect is unavailable","multi-jink")end
    local adapted,options,immediate={},{},{}
    for key,value in pairs(request)do adapted[key]=value end
    for key,value in pairs(request.options or{})do options[key]=value end
    for key,value in pairs(options.context or{})do immediate[key]=value end
    immediate.effect=last_effect;immediate.effect_present=true;options.context=immediate;adapted.options=options
    local prior=self.request;self.request=adapted
    local ok,selected=pcall(function()
        local data=self:getDecisionData();local effect=data:toCardEffect();local parts=prompt:split(":")
        return sgs.ai_skill_cardask["@multi-jink-start"](self,data,"jink",effect.from,nil,parts[#parts])
    end)
    self.request=prior
    if not ok then error(selected,0)end
    if selected=="."or selected==nil then return {kind="pass"}end
    if AIValue.isConversion(selected)then return {kind="use_card",card_spec=selected:toCardSpec()}end
    if AIValue.isCard(selected)then return {kind="use_card",card_id=call(selected,"getEffectiveId")}end
    ai_unsupported("multi-jink selected an invalid card value","multi-jink")
end
sgs.ai_skill_use["@multi-jink"]=sgs.ai_skill_use["@multi-jink-start"]

if sgs.ai_skill_playerchosen.damage~=nil then sgs.ai_skill_playerchosen.nosxuanfeng_damage = sgs.ai_skill_playerchosen.damage end

if sgs.ai_skill_playerchosen.zero_card_as_slash~=nil then sgs.ai_skill_playerchosen.nosxuanfeng_slash = sgs.ai_skill_playerchosen.zero_card_as_slash end

if sgs.ai_skill_invoke.shangshi~=nil then sgs.ai_skill_invoke.nosshangshi = sgs.ai_skill_invoke.shangshi end

if sgs.ai_skill_choice.guhuo_saveself~=nil then sgs.ai_skill_choice.nosguhuo_saveself = sgs.ai_skill_choice.guhuo_saveself end

if sgs.ai_skill_choice.guhuo_slash~=nil then sgs.ai_skill_choice.nosguhuo_slash = sgs.ai_skill_choice.guhuo_slash end

sgs.ai_skill_defense.qingnang = -2

if sgs.ai_skill_invoke.jianxiong~=nil then sgs.ai_skill_invoke.tiandu = sgs.ai_skill_invoke.jianxiong end

sgs.ai_skill_invoke.yajiao = true

sgs.ai_skill_defense.jieyin = -2.3

if sgs.ai_skill_cardask["@multi-jink-start"]~=nil then sgs.ai_skill_cardask["@multi-jink"] = sgs.ai_skill_cardask["@multi-jink-start"] end

sgs.registerTargetRecommend("rende", function(self, from, to, card, skill_owner, ctx)
    -- 只对摸牌行为生效
    if not ctx.isDraw then
        return 0
    end

    -- to已受伤，给他牌可以帮他凑仁德回血（不管这回合用没用完，下回合也能给回来）
    if call(to,"isWounded") then
        return 2  -- 推荐
    end

    return 0
end)

sgs.registerTargetRecommend("fankui", function(self, from, to, card, skill_owner, ctx)
    if not ctx.isDamage then
        return 0
    end
    if call(from,"getCardCount",true) <= 1 then
        return -2
    end
    if call(from,"getHp") <= 2 and (from:getWeapon() or from:getDefensiveHorse()) then
        return -2
    end
    return 0
end)

-- Audited literal source aliases; optional package presence is decided by the
-- immutable native load-time identity snapshot, never by this registration.
if ai_audited_aliases then
 ai_audited_aliases.register{id="ai_skill_invoke.diy_k_luoshang_judge",registry="ai_skill_invoke",path={"diy_k_luoshang_judge"},canonical_registry="ai_skill_invoke",canonical_path={"noszhenlie"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_invoke.Promote_luoyi",registry="ai_skill_invoke",path={"Promote_luoyi"},canonical_registry="ai_skill_invoke",canonical_path={"nosluoyi"},self_index=1}
 ai_audited_aliases.register{id="ai_cardneed.Luayezhan",registry="ai_cardneed",path={"Luayezhan"},canonical_registry="ai_cardneed",canonical_path={"nosluoyi"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.Promote_luoyi",registry="ai_cardneed",path={"Promote_luoyi"},canonical_registry="ai_cardneed",canonical_path={"nosluoyi"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.heg_luoyi",registry="ai_cardneed",path={"heg_luoyi"},canonical_registry="ai_cardneed",canonical_path={"nosluoyi"},self_index=3}
 ai_audited_aliases.register{id="ai_skill_invoke.Promote_tieji",registry="ai_skill_invoke",path={"Promote_tieji"},canonical_registry="ai_skill_invoke",canonical_path={"nostieji"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_invoke.lxtx_shouyue_tieqi",registry="ai_skill_invoke",path={"lxtx_shouyue_tieqi"},canonical_registry="ai_skill_invoke",canonical_path={"nostieji"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_invoke.PlusTiandu",registry="ai_skill_invoke",path={"PlusTiandu"},canonical_registry="ai_skill_invoke",canonical_path={"jianxiong"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_invoke.PlusLangmou",registry="ai_skill_invoke",path={"PlusLangmou"},canonical_registry="ai_skill_invoke",canonical_path={"fankui"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_invoke.SixLangmou",registry="ai_skill_invoke",path={"SixLangmou"},canonical_registry="ai_skill_invoke",canonical_path={"fankui"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_cardchosen.PlusLangmou",registry="ai_skill_cardchosen",path={"PlusLangmou"},canonical_registry="ai_skill_cardchosen",canonical_path={"fankui"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_cardchosen.SixLangmou",registry="ai_skill_cardchosen",path={"SixLangmou"},canonical_registry="ai_skill_cardchosen",canonical_path={"fankui"},self_index=1}
 ai_audited_aliases.register{id="ai_need_damaged.PlusLangmou",registry="ai_need_damaged",path={"PlusLangmou"},canonical_registry="ai_need_damaged",canonical_path={"fankui"},self_index=1}
 ai_audited_aliases.register{id="ai_need_damaged.SixLangmou",registry="ai_need_damaged",path={"SixLangmou"},canonical_registry="ai_need_damaged",canonical_path={"fankui"},self_index=1}
 ai_audited_aliases.register{id="ai_cardneed.TH_LastJudgement",registry="ai_cardneed",path={"TH_LastJudgement"},canonical_registry="ai_cardneed",canonical_path={"guicai"},self_index=3}
 ai_audited_aliases.register{id="ai_slash_prohibit.qhstandardganglie",registry="ai_slash_prohibit",path={"qhstandardganglie"},canonical_registry="ai_slash_prohibit",canonical_path={"ganglie"},self_index=1}
 ai_audited_aliases.register{id="ai_slash_prohibit.s4_ganglie",registry="ai_slash_prohibit",path={"s4_ganglie"},canonical_registry="ai_slash_prohibit",canonical_path={"ganglie"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_invoke.s4_txbw_luoyi",registry="ai_skill_invoke",path={"s4_txbw_luoyi"},canonical_registry="ai_skill_invoke",canonical_path={"luoyi"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_invoke.sfofl_luoyi",registry="ai_skill_invoke",path={"sfofl_luoyi"},canonical_registry="ai_skill_invoke",canonical_path={"luoyi"},self_index=1}
 ai_audited_aliases.register{id="ai_cardneed.qhstandardluoyi",registry="ai_cardneed",path={"qhstandardluoyi"},canonical_registry="ai_cardneed",canonical_path={"luoyi"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.sr_aozhan",registry="ai_cardneed",path={"sr_aozhan"},canonical_registry="ai_cardneed",canonical_path={"luoyi"},self_index=3}
 ai_audited_aliases.register{id="ai_skill_invoke.PlusYiji",registry="ai_skill_invoke",path={"PlusYiji"},canonical_registry="ai_skill_invoke",canonical_path={"yiji"},self_index=1}
 ai_audited_aliases.register{id="ai_can_damagehp.qhstandardyiji",registry="ai_can_damagehp",path={"qhstandardyiji"},canonical_registry="ai_can_damagehp",canonical_path={"yiji"},self_index=1}
 ai_audited_aliases.register{id="ai_cardneed.lxtx_shouyue_wusheng",registry="ai_cardneed",path={"lxtx_shouyue_wusheng"},canonical_registry="ai_cardneed",canonical_path={"wusheng"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.s4_fuhan",registry="ai_cardneed",path={"s4_fuhan"},canonical_registry="ai_cardneed",canonical_path={"wusheng"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.s4_wuhu_wusheng",registry="ai_cardneed",path={"s4_wuhu_wusheng"},canonical_registry="ai_cardneed",canonical_path={"wusheng"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.tenyearwusheng",registry="ai_cardneed",path={"tenyearwusheng"},canonical_registry="ai_cardneed",canonical_path={"wusheng"},self_index=3}
 ai_audited_aliases.register{id="ai_skill_pindian.sfofl_yijue",registry="ai_skill_pindian",path={"sfofl_yijue"},canonical_registry="ai_skill_pindian",canonical_path={"yijue"},self_index=2}
 ai_audited_aliases.register{id="ai_cardneed.sfofl_yijue",registry="ai_cardneed",path={"sfofl_yijue"},canonical_registry="ai_cardneed",canonical_path={"yijue"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.Dragon_feijiang",registry="ai_cardneed",path={"Dragon_feijiang"},canonical_registry="ai_cardneed",canonical_path={"paoxiao"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.heg_paoxiao",registry="ai_cardneed",path={"heg_paoxiao"},canonical_registry="ai_cardneed",canonical_path={"paoxiao"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.kenewpaoxiao",registry="ai_cardneed",path={"kenewpaoxiao"},canonical_registry="ai_cardneed",canonical_path={"paoxiao"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.keqifendi",registry="ai_cardneed",path={"keqifendi"},canonical_registry="ai_cardneed",canonical_path={"paoxiao"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.lianxie",registry="ai_cardneed",path={"lianxie"},canonical_registry="ai_cardneed",canonical_path={"paoxiao"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.lxtx_shouyue_paoxiao",registry="ai_cardneed",path={"lxtx_shouyue_paoxiao"},canonical_registry="ai_cardneed",canonical_path={"paoxiao"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.moupaoxiao",registry="ai_cardneed",path={"moupaoxiao"},canonical_registry="ai_cardneed",canonical_path={"paoxiao"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.s4_wuhu_heduan",registry="ai_cardneed",path={"s4_wuhu_heduan"},canonical_registry="ai_cardneed",canonical_path={"paoxiao"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.moujizhi",registry="ai_cardneed",path={"moujizhi"},canonical_registry="ai_cardneed",canonical_path={"jizhi"},self_index=3}
 ai_audited_aliases.register{id="ai_cardneed.s4_cangzhuo",registry="ai_cardneed",path={"s4_cangzhuo"},canonical_registry="ai_cardneed",canonical_path={"jizhi"},self_index=3}
 ai_audited_aliases.register{id="ai_slash_prohibit.dl_liuli",registry="ai_slash_prohibit",path={"dl_liuli"},canonical_registry="ai_slash_prohibit",canonical_path={"liuli"},self_index=1}
 ai_audited_aliases.register{id="ai_cardneed.dl_liuli",registry="ai_cardneed",path={"dl_liuli"},canonical_registry="ai_cardneed",canonical_path={"liuli"},self_index=3}
end
