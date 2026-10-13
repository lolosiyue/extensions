-- Fixed Wind callbacks: source planning, retrial, targeting, intention and values.
-- No Engine lookup, native card parsing, payment fabrication or hidden tag read.
local function known(value, key)
    if value == nil then ai_unsupported("wind policy input is not projected", key) end
    return value
end
local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then
        ai_unsupported("wind policy helper is unavailable", method)
    end
    return known(object[method](object, ...), method)
end
local function dummy_use()
    local use=AIUsePlan.new()
    use.isDummy=true;use.extra_target=0;use.current_targets={}
    return use
end
local function sort_in_place(self,players,key,reverse)
    local ordered=call(self,"sort",players,key,reverse)
    for i,player in ipairs(ordered) do players[i]=player end
    return players
end
local function skill(self, player, names)
    local value = player:hasSkills(names)
    local row=type(player)=="table" and rawget(player,"_view")
    -- hasSkills() currently treats absent projected names as false. Only a
    -- complete roster proves that negative; a visible matching name proves true.
    if value==true or value~=nil and (not row or row.skills_complete==true) then return value end
    if player:objectName() == self.player:objectName() then
        ai_unsupported("owner skill list is incomplete", "wind.skills")
    end
    return self:useKnowledgeEstimate({status="estimate",value=false,
        basis="wind.undisclosed_skill_uses_visible_roster"},"wind.skills")
end

sgs.ai_skill_invoke.jushou = function(self)
    if not call(self.player,"faceUp") then return true end
    for _, friend in ipairs(known(self.friends,"jushou.friends")) do
        if skill(self,friend,"fangzhu|jilve") and not call(self,"isWeak",friend) then return true end
        if skill(self,friend,"junxing") and call(friend,"faceUp") and not call(self,"willSkipPlayPhase",friend)
            and not (call(friend,"isKongcheng") and call(self,"willSkipDrawPhase",friend)) then return true end
    end
    if not skill(self,self.player,"jiewei") then return false end
    for _, card in ipairs(call(self.player,"getHandcards")) do
        local use
        if call(card,"getTypeId")==sgs.Card_TypeTrick and not call(card,"isKindOf","Nullification") then
            use=dummy_use(); self:useTrickCard(card,use)
        elseif call(card,"getTypeId")==sgs.Card_TypeEquip then
            use=dummy_use(); self:useEquipCard(card,use)
        end
        if use and use.card then return true end
    end
    return math.random()+call(self.player,"getCardCount")/10+call(self.player,"getHp")/10>1.1
end
sgs.ai_skill_invoke.jiewei = true
sgs.ai_skill_invoke.liegong = function(self,data)
    local target=known(data and data:toPlayer(),"liegong.target")
    return not call(self,"isFriend",target)
end

sgs.ai_skill_cardask["@guidao-card"] = function(self,data)
    local all_cards=call(self,"addHandPile","he")
    if #all_cards<1 then return "." end
    local judge=known(data and data:toJudge(),"guidao.judge")
    local suit=call(known(judge.card,"guidao.judge.card"),"getSuit")
    local keep=suit~=sgs.Card_Spade and (not skill(self,self.player,"leiji") or suit~=sgs.Card_Club)
        and self:findLeijiTarget(self.player,50)
        and (call(self,"getCardsNum","Jink")>0 or call(self,"hasEightDiagramEffect"))
        and call(self,"getFinalRetrial")==1
    if not keep and call(judge.who,"getPhase")<=sgs.Player_Judge
        and call(judge.who,"containsTrick","lightning") and judge.reason~="lightning" then keep=true end
    local spades=keep and skill(self,self.player,"nosleiji|tenyearleiji") and 2 or 0
    local cards, by_id={},{}
    for _,card in ipairs(all_cards) do
        if call(card,"isBlack") and not call(card,"hasFlag","using") then
            if call(card,"getSuit")==sgs.Card_Spade then spades=spades-1 end
            cards[#cards+1]=card;by_id[call(card,"getEffectiveId")]=card
        end
    end
    if #cards<1 or spades==1 then return "." end
    local id=call(self,"getRetrialCardId",cards,judge,nil,true)
    if id<0 then return "." end
    local selected=known(by_id[id],"guidao.selected_material")
    if call(self,"needRetrial",judge) or call(self,"getUseValue",judge.card)>call(self,"getUseValue",selected) then return id end
    return "."
end

sgs.ai_cardneed.guidao = function(to,card,self)
    for _,player in ipairs(call(self.room,"getAllPlayers")) do
        if call(self,"getFinalRetrial",to)==1 then
            if call(player,"containsTrick","lightning") and not call(player,"containsTrick","YanxiaoCard") then
                return call(card,"getSuit")==sgs.Card_Spade and call(card,"getNumber")>=2 and call(card,"getNumber")<=9
                    and not call(self,"hasSkills","hongyan|olhongyan|wuyan")
            end
            if call(self,"isFriend",player) and call(self,"willSkipDrawPhase",player) then
                return call(card,"getSuit")==sgs.Card_Club and call(self,"hasSuit","club",true,to)
            end
        end
    end
    if call(self,"getFinalRetrial",to)==1 then
        if skill(self,to,"nosleiji|tenyearleiji") then return call(card,"getSuit")==sgs.Card_Spade end
        if skill(self,to,"leiji|olleiji|tenyearleiji") then return call(card,"isBlack") end
    end
end
sgs.guidao_suit_value = {spade=3.9,club=2.7}
sgs.ai_suit_priority.guidao = "diamond|heart|club|spade"
sgs.ai_suit_priority.hongyan = "club|diamond|spade|heart"

sgs.ai_skill_choice.guhuo = function(self)
    local yuji=self.room:findPlayerBySkillName("guhuo")
    local context
    if self.world then
        local uncertain=false
        for _,player in ipairs(call(self.room,"getAlivePlayers")) do
            if yuji and player:objectName()==yuji:objectName() then break end
            local row=rawget(player,"_view")
            if not row or row.skills_complete~=true then uncertain=true end
        end
        if not yuji then
            context=call(self,"getDecisionContext")
            local source=context.guhuo and context.guhuo.source
            yuji=type(source)=="string" and self.room:findPlayerByObjectName(source) or nil
            uncertain=true
        end
        if uncertain then self:useKnowledgeEstimate({status="estimate",value=true,
            basis="wind.guhuo_first_owner_uses_public_skill_roster_or_declared_source"},"guhuo.source") end
    end
    yuji=known(yuji,"guhuo.source")
    if not call(self,"isEnemy",yuji) then return "noquestion" end
    context=context or call(self,"getDecisionContext")
    local name=known(context.guhuo and context.guhuo.declaration,"guhuo.declaration")
    if name=="peach+analeptic" then name="peach" end
    if name=="normal_slash" then name="slash" end
    local card=call(self,"getEvaluationCard",name)
    local class=call(card,"getClassName")
    if call(self,"getRestCardsNum",class,yuji)==0 and call(self.player,"getHp")>0 then return "question" end
    if class=="AmazingGrace" then return "noquestion" end
    if skill(self,self.player,"hunzi") and call(self.player,"getMark","hunzi")==0
        and math.random(1,15)~=1 then return "noquestion" end
    if class:match("Slash") then
        if call(yuji,"getState")~="robot" and math.random(1,8)==1 then return "question" end
        if not call(self,"hasCrossbowEffect",yuji) then return "noquestion" end
    end
    local x=5
    if name=="peach" or name=="ex_nihilo" then
        x=2
        if known(getKnownCard(yuji,self.player,class,false),"guhuo.known_cards")>0 then x=x*3 end
    end
    return math.random(1,x)==1 and "question" or "noquestion"
end
sgs.ai_skill_choice.guhuo_saveself = function(self)
    -- getCard returning nil is the source's known absence, not a guessed cost.
    if self:getCard("Peach") or not self:getCard("Analeptic") then return "peach" end
    return "analeptic"
end
sgs.ai_skill_choice.guhuo_slash = function() return "slash" end
sgs.guhuo_suit_value={heart=5}
sgs.ai_skill_defense.guhuo = function(self,player)
    local siblings
    if type(player.getAliveSiblings)=="function" then siblings=call(player,"getAliveSiblings")
    else siblings=call(self.room,"getAlivePlayers") end
    for _,other in ipairs(siblings) do
        if other:objectName()~=player:objectName() and skill(self,other,"chanyuan") then return 1 end
    end
    return 0
end

-- Effective source: smart-ai.lua:9786, not nosguhuo/olguhuo. This callback
-- selects the exact material/declaration; resolveResponseConversion alone can
-- turn its pure proposal into a native, source-instance-bound cost receipt.
-- The fixed V2 skill's inherited legacy response gate is false. Wind's larger
-- turn-use planner below calls this selector directly before native cost binding.
sgs.ai_guhuo_card.guhuo = function(self,cname,class_name)
    local handcards=call(self,"addHandPile","h")
    if #handcards<1 then return end
    handcards=call(self,"sortByUseValue",handcards)
    local real,fake,question={},{},#known(self.enemies,"guhuo.enemies")
    local all=call(self.room,"getMode")=="_mini_48"
    for _,enemy in ipairs(self.enemies) do
        if skill(self,enemy,"chanyuan") or skill(self,enemy,"hunzi") and call(enemy,"getMark","hunzi")<1 then
            question=question-1
        end
        if question<1 then all=true end
    end
    for _,card in ipairs(handcards) do
        if call(card,"isKindOf",class_name) then real[#real+1]=card
        elseif call(self,"getCardsNum",class_name)>0 then fake[#fake+1]=card end
    end
    local function propose(card)
        return {name=cname,suit=call(card,"getSuit"),number=call(card,"getNumber"),
            subcards={call(card,"getEffectiveId")},user_string=cname,skill="guhuo"}
    end
    if all then real=handcards end
    if #real>1 or #real>0 and all then
        local index=1
        if not all and (class_name=="Peach" or class_name=="Analeptic" or class_name=="Jink") then index=#real end
        return propose(real[index])
    end
    question=question<1 and 100 or #self.enemies/question
    if #fake>0 and math.random(1,5)<=question then return propose(fake[1]) end
    if #real>0 then return propose(real[1]) end
    if call(self,"isWeak") then
        if class_name=="Analeptic" and call(self,"getCardsNum","Peach,Analeptic")<1 then return propose(handcards[1]) end
        if class_name=="Jink" then return propose(handcards[1]) end
    end
    if class_name=="Jink" and math.random(1,#handcards+1)<(#handcards+1)/2 then return propose(handcards[1])
    elseif class_name=="Slash" and math.random(1,#handcards+2)>(#handcards+1)/2 then return propose(handcards[1])
    elseif class_name=="Peach" or class_name=="Analeptic" then
        -- RoomView nil here is known public absence, as in the donor callback.
        local dying=self.room:getCurrentDyingPlayer()
        if dying and call(self,"isFriend",dying) and math.random(1,#handcards+1)>(#handcards+1)/2 then
            return propose(handcards[1])
        end
    end
end

-- Negative foreign skill/flag/role observations use only this viewer's facts.
local function flag(self,player,name)
    local value
    if type(self.hasStrategyPlayerFlag)=="function" then value=self:hasStrategyPlayerFlag(player,name) end
    if value==nil then value=player:hasFlag(name) end
    if value~=nil then return value end
    if player:objectName()==self.player:objectName() then known(nil,"wind.flag:"..name) end
    return self:useKnowledgeEstimate({value=false,status="estimate",basis="wind.foreign_flag_not_observed",flag=name,
        target=player:objectName()},"wind.flag")
end
local function actual_role(self,player)
    local role=player:getRole()
    if role~=nil then return role end
    return self:useKnowledgeEstimate({value=call(self,"getRoleEstimate",player),status="estimate",
        basis="wind.private_role_uses_viewer_inference",target=player:objectName()},"wind.role")
end
local function identity(player) return player and player:objectName() end
local function physical_answer(card,targets)
    local use=AIUsePlan.new();use.card=card;use.to=targets or AIList.new({})
    return known(use:toAnswer(),"wind.physical_answer")
end
local function memory_set(self,key,value)
    self[key]=value
    if type(self.setStrategyMemory)~="function" then ai_unsupported("strategy observation memory is unavailable",key) end
    return self:setStrategyMemory("wind."..key,value)
end
local function memory_get(self,key)
    if self[key]~=nil then return self[key] end
    return self:getStrategyMemory("wind."..key)
end

ai_skill_use["TrickCard+^Nullification,EquipCard|.|.|hand"] = function(self)
    local cards=call(self.player,"getHandcards")
    cards=call(self,"sortByUseValue",cards)
    for _,card in ipairs(cards) do
        if call(card,"getTypeId")==sgs.Card_TypeTrick and not call(card,"isKindOf","Nullification") then
            local use=dummy_use();self:useTrickCard(card,use)
            if use.card then return physical_answer(card,use.to) end
        elseif call(card,"getTypeId")==sgs.Card_TypeEquip then
            local use=dummy_use();self:useEquipCard(card,use)
            if use.card then
                memory_set(self,"jiewei_type",sgs.Card_TypeEquip)
                return physical_answer(card)
            end
        end
    end
    return "."
end
sgs.ai_skill_playerchosen.jiewei = function(self,targets)
    local kind=memory_get(self,"jiewei_type")
    if kind==sgs.Card_TypeTrick then return call(self,"findPlayerToDiscard","j",true,true,targets)[1]
    elseif kind==sgs.Card_TypeEquip then return call(self,"findPlayerToDiscard","e",true,true,targets)[1] end
end

sgs.ai_skill_playerchosen.leiji = function(self)
    local mode=call(self.room,"getMode")
    if mode:find("_mini_17") or mode:find("_mini_19") or mode:find("_mini_20") or mode:find("_mini_26") then
        for _,player in ipairs(call(self.room,"getAllPlayers")) do
            if call(player,"getState")~="robot" then return player end
        end
    end
    local target=self:findLeijiTarget(self.player,100,nil,1)
    return target or nil
end
sgs.ai_playerchosen_intention.leiji=80
sgs.ai_skill_playerchosen.tenyearleiji=function(self,targets) return sgs.ai_skill_playerchosen.leiji(self,targets) end
sgs.ai_playerchosen_intention.tenyearleiji=80
sgs.ai_slash_prohibit.leiji = function(self,from,to)
    if call(self,"isFriend",to) then return false end
    if flag(self,to,"QianxiTarget") and (not call(self,"hasEightDiagramEffect",to) or call(self.player,"hasWeapon","qinggang_sword")) then return false end
    from=from or known(self.room:getCurrent(),"leiji.current")
    local hand=call(to,"getHandcardNum")
    if call(self,"canLiegong",to,from) then return false end
    if actual_role(self,from)=="rebel" and call(to,"isLord") then
        local other
        for _,player in ipairs(call(self.room,"getOtherPlayers",from)) do
            if call(self,"getRoleEstimate",player)=="rebel" or call(self,"compareRoleEvaluation",player,"rebel","loyalist")=="rebel" then other=player;break end
        end
        if not other and (call(self,"hasSkills","hongyan") or call(self.player,"getHp")>=4)
            and (call(self,"getCardsNum","Peach")>0 or skill(self,self.player,"hongyan|ganglie|neoganglie")) then return false end
    end
    if known(getKnownCard(to,self.player,"Jink",true),"leiji.jink")>=1
        or call(self,"hasSuit","spade",true,to) and hand>=2 or hand>=4 then return true end
    if call(self,"hasEightDiagramEffect",to) and not call(self,"ignoreArmor",from,to) then return true end
end
sgs.ai_slash_prohibit.tenyearleiji=function(self,from,to,card) return sgs.ai_slash_prohibit.leiji(self,from,to,card) end
sgs.ai_slash_prohibit.tianxiang = function(self,from,to)
    if call(self,"hasJueqingEffect",from,to) or skill(self,from,"nosqianxi") and call(from,"distanceTo",to)==1 then return false end
    if flag(self,from,"NosJiefanUsed") then return false end
    if call(self,"isFriend",to,from) then return false end
    return call(self,"cantbeHurt",to,from)
end
sgs.tianxiang_suit_value={heart=4.9}
sgs.ai_cardneed.tianxiang=function(to,card,self)
    return (call(card,"getSuit")==sgs.Card_Heart or skill(self,to,"hongyan") and call(card,"getSuit")==sgs.Card_Spade)
        and known(getKnownCard(to,self.player,"heart",false),"tianxiang.heart")+known(getKnownCard(to,self.player,"spade",false),"tianxiang.spade")<2
end
sgs.ai_skill_defense.tianxiang=function(self,player) return call(player,"getHandcardNum")*.5 end
sgs.ai_cardneed.kuanggu=function(to,card,self)
    return call(card,"isKindOf","OffensiveHorse") and not (to:getOffensiveHorse() or known(getKnownCard(to,self.player,"OffensiveHorse",false),"kuanggu.horse")>0)
end
sgs.ai_skill_defense.kuanggu=function(self,player) return call(player,"getHp")>1 and .5 or 0 end
sgs.ai_skill_invoke.shelie=true
sgs.ai_skill_playerchosen.wuhun=function(self,targets)
    local list=call(self,"sort",targets,"hp")
    local target,lord
    for _,player in ipairs(list) do
        if call(player,"isLord") then lord=player end
        if call(self,"isEnemy",player) and (not target or call(target,"getHp")<call(player,"getHp")) then target=player end
    end
    if self.role=="rebel" and lord then return lord end
    if target then return target end
    if actual_role(self,self.player)=="loyalist" and call(known(list[1],"wuhun.targets"),"isLord") then return list[2] end
    return list[1]
end
sgs.ai_slash_prohibit.wuhun=function(self,from,to)
    if skill(self,from,"jueqing") then return false end
    if flag(self,from,"NosJiefanUsed") then return false end
    local damage=call(self,"ajustDamage",from,to,1,call(self,"getEvaluationCard","slash"))
    local friendly,hostile=0,0
    local mark="&nightmare+#"..to:objectName()
    for _,friend in ipairs(call(self,"getFriends",from)) do friendly=math.max(friendly,call(friend,"getMark",mark)) end
    for _,enemy in ipairs(call(self,"getEnemies",from)) do
        local value=call(enemy,"getMark",mark)
        if value>hostile and identity(enemy)~=identity(to) then hostile=value end
    end
    if call(self,"isEnemy",to,from) and not(call(to,"isLord") and actual_role(self,from)=="rebel") then
        if friendly+damage>=hostile and not(#call(self,"getEnemies",from)==1 and #call(self,"getFriends",from)+#call(self,"getEnemies",from)==call(self.room,"alivePlayerCount")) then
            if not(call(from,"getMark",mark)==friendly and actual_role(self,from)=="loyalist") then return true end
        end
    end
end
sgs.ai_skill_invoke.fenji=function(self)
    local move=known(call(self,"getDecisionContext").move,"fenji.move")
    local from=move.from
    if type(from)=="string" then from=self.room:findPlayerByObjectName(from) end
    if call(self,"isWeak") or not from or not call(self,"isFriend",from)
        or call(self,"hasManjuanEffect",from) or call(self,"needKongcheng",from,true) then return false end
    local reason=known(move.skill or move.reason and move.reason.skill_name,"fenji.reason")
    if reason=="rende" or reason=="nosrende" then return true end
    return call(from,"getHandcardNum")<(call(self.player,"getHp")<=1 and 3 or 5)
end
sgs.ai_choicemade_filter.skillInvoke=sgs.ai_choicemade_filter.skillInvoke or {}
sgs.ai_choicemade_filter.skillInvoke.fenji=function(self,player,promptlist)
    local target,available=self:getEventMemory("fenji_target")
    if not available then ai_unsupported("Fenji target observation is not initialized","fenji.target") end
    if target then
        if promptlist[3]=="yes" then sgs.updateIntention(player,self.room:findPlayerByObjectName(target),-10) end
        self:setEventMemory("fenji_target",nil)
    end
end
sgs.ai_card_intention.TianxiangCard=function(self,card,from,targets)
    local to=known(targets[1],"tianxiang.target")
    if call(self,"needToLoseHp",to) then return end
    local intention=10
    if known(hasBuquEffect(to),"tianxiang.buqu") then intention=0
    elseif call(to,"getHp")>=2 and skill(self,to,"yiji|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu")
        or call(to,"getHandcardNum")<3 and (skill(self,to,"nosrende") or skill(self,to,"rende") and not call(to,"hasUsed","RendeCard")) then intention=0 end
    sgs.updateIntention(from,to,intention)
end

local function bind_skill(self,name,costs,request,user_string,legacy_class)
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room) end
    return call(self,"bindSkillCard",name,costs,request,user_string,legacy_class)
end
local function skill_answer(self,name,costs,targets,request,user_string)
    local card=bind_skill(self,name,costs,request,user_string)
    return physical_answer(card,targets)
end
local function tianxiang_select(self,damage,method)
    local cards=call(self,"sortByUseValue",call(self.player,"getCards","h"),true)
    local id
    for _,card in ipairs(cards) do
        if not call(self.player,"isCardLimited",card,method) and call(card,"getSuit")==sgs.Card_Heart and not call(card,"isKindOf","Peach") then
            id=call(card,"getId");break
        end
    end
    if not id then return end
    self.enemies=sort_in_place(self,self.enemies,"hp")
    local amount=known(damage.damage or damage.amount,"tianxiang.damage")
    local nature=known(damage.nature,"tianxiang.nature")
    local source=damage.from or self.room:getCurrent()
    local function blocked(player) return damage.card and call(damage.card,"getTypeId")==sgs.Card_TypeTrick and skill(self,player,"wuyan") end
    for _,enemy in ipairs(self.enemies) do
        if call(enemy,"getHp")<=amount and call(enemy,"isAlive") and call(enemy,"getLostHp")+amount<3 then
            if (call(enemy,"getHandcardNum")<=2 or skill(self,enemy,"guose|leiji|ganglie|enyuan|qingguo|wuyan|kongcheng") or call(enemy,"containsTrick","indulgence"))
                and call(self,"canAttack",enemy,source,nature) and not blocked(enemy) then return id,enemy end
        end
    end
    for _,friend in ipairs(known(self.friends_noself,"tianxiang.friends")) do
        if call(friend,"getLostHp")+amount>1 and call(friend,"isAlive") then
            if call(friend,"isChained") and nature~=sgs.DamageStruct_Normal and not call(self,"isGoodChainTarget",friend,damage.card or nature,damage.from,amount) then
            elseif call(friend,"getHp")>=2 and amount<2 and (skill(self,friend,"yiji|buqu|nosbuqu|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu")
                or call(self,"needToLoseHp",friend) or call(friend,"getHandcardNum")<3 and (skill(self,friend,"nosrende") or skill(self,friend,"rende") and not call(friend,"hasUsed","RendeCard"))) then return id,friend
            elseif blocked(friend) and call(friend,"getLostHp")>1 then return id,friend
            elseif known(hasBuquEffect(friend),"tianxiang.buqu") then return id,friend end
        end
    end
    for _,enemy in ipairs(self.enemies) do
        if (call(enemy,"getLostHp")<=1 or amount>1) and call(enemy,"isAlive") and call(enemy,"getLostHp")+amount<4 then
            -- Source deliberately leaves hand<=2 and Indulgence outside the
            -- canAttack/Wuyan conjunction. Do not "fix" its operator precedence.
            if call(enemy,"getHandcardNum")<=2 or call(enemy,"containsTrick","indulgence")
                or skill(self,enemy,"guose|leiji|vsganglie|ganglie|enyuan|qingguo|wuyan|kongcheng") and call(self,"canAttack",enemy,source,nature) and not blocked(enemy) then return id,enemy end
        end
    end
    for i=#self.enemies,1,-1 do
        local enemy=self.enemies[i]
        if not call(enemy,"isWounded") and not call(self,"hasSkills",sgs.masochism_skill,enemy) and call(enemy,"isAlive")
            and call(self,"canAttack",enemy,source,nature) and (not(blocked(enemy) and call(enemy,"getLostHp")>0) or call(self,"isWeak")) then return id,enemy end
    end
end
-- The common damage preference calls the same source selection as a pure
-- hypothesis. It neither reads the active damage question nor binds payment.
function SmartAIView:canTianxiangHypothesis(damage,method)
    local id=tianxiang_select(self,damage,method)
    return id~=nil
end
ai_skill_use["@@tianxiang"]=function(self,prompt,request)
    local damage=known(call(self,"getDecisionContext").damage,"tianxiang.damage_context")
    local id,target=tianxiang_select(self,damage,request.handling_method or sgs.Card_MethodDiscard)
    if not id then return "." end
    return skill_answer(self,"tianxiang",{id},AIList.new({target}),request)
end

local function visible_card(self,id,engine_face)
    local context=call(self,"getDecisionContext")
    if engine_face then
        local rows=context.gongxin_engine_cards
        local row=type(rows)=="table" and (rows[tostring(id)] or rows[id])
        if not row then ai_unsupported("Gongxin disclosed printed face is not projected","gongxin.engine_card") end
        return type(row.getSuit)=="function" and row or CardView.new(row)
    end
    for _,card in ipairs(call(self,"getChoiceCards")) do if card:getEffectiveId()==id then return card end end
    ai_unsupported("Gongxin card is not among the disclosed choice cards","gongxin.card")
end
local function foreign_locked(self,player,card)
    local locked=player:isLocked(card)
    if locked~=nil then return locked end
    if identity(player)==identity(self.player) then known(nil,"gongxin.owner_locked") end
    return self:useKnowledgeEstimate({value=false,status="estimate",basis="gongxin.foreign_locked_uses_public_unrestricted_prior",
        target=identity(player),card_id=call(card,"getEffectiveId")},"gongxin.locked")
end
local function gongxin_ag(self,ids)
    self.gongxinchoice=nil
    local context=call(self,"getDecisionContext")
    local target=context.gongxin_target
    if type(target)=="string" then target=target~="" and self.room:findPlayerByObjectName(target) or nil
    elseif target==nil then ai_unsupported("Gongxin owner target is not projected","gongxin.target") end
    if not target or call(self,"isFriend",target) then return -1 end
    local nextAlive=self.player
    repeat nextAlive=call(nextAlive,"getNextAlive") until call(nextAlive,"faceUp")
    local peach,ex_nihilo,jink,nullification,slash
    for _,id in ipairs(ids) do
        local card=visible_card(self,id)
        if call(card,"isKindOf","Peach") then peach=id end
        if call(card,"isKindOf","ExNihilo") then ex_nihilo=id end
        if call(card,"isKindOf","Jink") then jink=id end
        if call(card,"isKindOf","Nullification") then nullification=id end
        if call(card,"isKindOf","Slash") then slash=id end
    end
    local valuable=peach or ex_nihilo or jink or nullification or slash or ids[1]
    local card=visible_card(self,known(valuable,"gongxin.offered_cards"))
    if call(self,"isEnemy",target) and skill(self,target,"tuntian") then
        local zhangjiao=self.room:findPlayerBySkillName("guidao")
        if zhangjiao and call(self,"isFriend",zhangjiao,target) and self:canRetrial(zhangjiao,target) and call(self,"isValuableCard",card,zhangjiao) then self.gongxinchoice="discard"
        else self.gongxinchoice="put" end
        return valuable
    end
    local willUseExNihilo,willRecast
    if call(self,"getCardsNum","ExNihilo")>0 then
        local c=self:getCard("ExNihilo")
        if c then local use=dummy_use();self:useTrickCard(c,use);if use.card then willUseExNihilo=true end end
    elseif call(self,"getCardsNum","IronChain")>0 then
        local c=self:getCard("IronChain")
        if c then local use=dummy_use();self:useTrickCard(c,use);if use.card and #use.to==0 then willRecast=true end end
    end
    if willUseExNihilo or willRecast then
        card=visible_card(self,valuable)
        if call(card,"isKindOf","Peach") then self.gongxinchoice="put";return valuable end
        if call(card,"isKindOf","TrickCard") or call(card,"isKindOf","Indulgence") or call(card,"isKindOf","SupplyShortage") then
            local use=dummy_use();self:useTrickCard(card,use)
            if use.card then self.gongxinchoice="put";return valuable end
        end
        if call(card,"isKindOf","Jink") and call(self,"getCardsNum","Jink")==0 then self.gongxinchoice="put";return valuable end
        if call(card,"isKindOf","Nullification") and call(self,"getCardsNum","Nullification")==0 then self.gongxinchoice="put";return valuable end
        if call(card,"isKindOf","Slash") and call(self,"slashIsAvailable") then
            local use=dummy_use();self:useBasicCard(card,use)
            if use.card then self.gongxinchoice="put";return valuable end
        end
        self.gongxinchoice="discard";return valuable
    end
    local hasLightning,hasIndulgence,hasSupplyShortage
    local tricks=call(nextAlive,"getJudgingArea")
    if #tricks>0 and not call(nextAlive,"containsTrick","YanxiaoCard") then
        local trick=tricks[#tricks]
        if call(self,"hasTrickEffective",trick,nextAlive) then
            if call(trick,"isKindOf","Lightning") then hasLightning=true
            elseif call(trick,"isKindOf","Indulgence") then hasIndulgence=true
            elseif call(trick,"isKindOf","SupplyShortage") then hasSupplyShortage=true end
        end
    end
    if call(self,"isEnemy",nextAlive) and skill(self,nextAlive,"luoshen") and valuable then self.gongxinchoice="put";return valuable end
    if skill(self,nextAlive,"yinghun") and call(nextAlive,"isWounded") then self.gongxinchoice=call(self,"isFriend",nextAlive) and "put" or "discard";return valuable end
    if skill(self,target,"hongyan") and hasLightning and call(self,"isEnemy",nextAlive) and not(skill(self,nextAlive,"qiaobian") and call(nextAlive,"getHandcardNum")>0) then
        for _,id in ipairs(ids) do
            local raw=visible_card(self,id,true)
            if call(raw,"getSuit")==sgs.Card_Spade and call(raw,"getNumber")>=2 and call(raw,"getNumber")<=9 then self.gongxinchoice="put";return id end
        end
    end
    if hasIndulgence and call(self,"isFriend",nextAlive) then self.gongxinchoice="put";return valuable end
    if hasSupplyShortage and call(self,"isEnemy",nextAlive) and not(skill(self,nextAlive,"qiaobian") and call(nextAlive,"getHandcardNum")>0) then
        local enemy_null=0
        for _,player in ipairs(call(self.room,"getOtherPlayers",self.player)) do
            if call(self,"isFriend",player) then enemy_null=enemy_null-known(getCardsNum("Nullification",player),"gongxin.nullification") end
            if call(self,"isEnemy",player) then enemy_null=enemy_null+known(getCardsNum("Nullification",player),"gongxin.nullification") end
        end
        enemy_null=enemy_null-call(self,"getCardsNum","Nullification")
        if enemy_null<.8 then self.gongxinchoice="put";return valuable end
    end
    if call(self,"isFriend",nextAlive) and not call(self,"willSkipDrawPhase",nextAlive) and not call(self,"willSkipPlayPhase",nextAlive)
        and not skill(self,nextAlive,"luoshen") and not skill(self,nextAlive,"tuxi") and not(skill(self,nextAlive,"qiaobian") and call(nextAlive,"getHandcardNum")>0) then
        if peach and valuable==peach or ex_nihilo and valuable==ex_nihilo then self.gongxinchoice="put";return valuable end
        if jink and valuable==jink and known(getCardsNum("Jink",nextAlive),"gongxin.jink")<1 then self.gongxinchoice="put";return valuable end
        if nullification and valuable==nullification and known(getCardsNum("Nullification",nextAlive),"gongxin.nullification")<1 then self.gongxinchoice="put";return valuable end
        if slash and valuable==slash and call(self,"hasCrossbowEffect",nextAlive) then self.gongxinchoice="put";return valuable end
    end
    card=visible_card(self,valuable)
    local keep=call(card,"isKindOf","Slash") or call(card,"isKindOf","Jink") or call(card,"isKindOf","EquipCard")
        or call(card,"isKindOf","Disaster") or call(card,"isKindOf","GlobalEffect") or call(card,"isKindOf","Nullification") or foreign_locked(self,target,card)
    self.gongxinchoice=identity(target)==identity(nextAlive) and keep and "put" or "discard"
    return valuable
end
sgs.ai_skill_askforag.gongxin=function(self,ids)
    local id=gongxin_ag(self,ids)
    memory_set(self,"gongxinchoice",self.gongxinchoice)
    return id
end
sgs.ai_skill_choice.gongxin=function(self) return memory_get(self,"gongxinchoice") or "discard" end
sgs.ai_use_value.GongxinCard=8.5
sgs.ai_use_priority.GongxinCard=9.5
sgs.ai_card_intention.GongxinCard=80

local function legacy_policy(self,receipt,name,subcards)
    local number=#subcards==1 and call(receipt,"getNumber") or 0
    local suit=known(sgs.Card_NoSuit,"NoSuit")
    if #subcards>0 then
        assert(#subcards==1,"Wind legacy SkillCard has one material")
        local material
        for _,card in ipairs(call(self.player,"getCards","he")) do
            if call(card,"getEffectiveId")==subcards[1] then material=card;break end
        end
        suit=call(known(material,"wind.legacy_material"),"getSuit")
    end
    local suit_name=({[sgs.Card_Spade]="spade",[sgs.Card_Club]="club",[sgs.Card_Heart]="heart",[sgs.Card_Diamond]="diamond",[sgs.Card_NoSuit]="no_suit"})[suit]
    if suit==sgs.Card_NoSuitBlack then suit_name="no_suit_black" elseif suit==sgs.Card_NoSuitRed then suit_name="no_suit_red" end
    local printed=number>13 and "JOKER" or ({[1]="A",[11]="J",[12]="Q",[13]="K"})[number] or tostring(number)
    local key="@"..name.."["..known(suit_name,"wind.legacy_suit")..":"..printed.."]="..(#subcards>0 and table.concat(subcards,"+") or ".")
    if name=="GuhuoCard" then key=key..":"..call(receipt,"getUserString") end
    local policy={name="",class_name=name,type_id=0,kind_of={name,"SkillCard","Card"},
        legacy_string_key=key,legacy_sort_key=key,subcards=subcards,suit=suit,number=number,
        red=suit==sgs.Card_Heart or suit==sgs.Card_Diamond or suit==sgs.Card_NoSuitRed,black=suit==sgs.Card_Spade or suit==sgs.Card_Club or suit==sgs.Card_NoSuitBlack,
        damage_card=false,can_recast=false,will_throw=name~="GuhuoCard" and name~="HuangtianCard",
        handling_method=(name=="GuhuoCard" or name=="HuangtianCard") and sgs.Card_MethodNone or sgs.Card_MethodDiscard}
    if #subcards>0 then policy.effective_id=subcards[1] end
    return call(self,"legacyPolicyCard",receipt,policy)
end
sgs.ai_fill_skill.huangtian_attach=function(self,inclusive,request)
    local cards=call(self,"sortByUseValue",call(self.player,"getCards","h"),true)
    for _,card in ipairs(cards) do
        if call(card,"isKindOf","Jink") then
            local costs={call(card,"getEffectiveId")}
            return legacy_policy(self,bind_skill(self,"huangtian_attach",costs,request),"HuangtianCard",costs)
        end
    end
end
sgs.ai_skill_use_func.HuangtianCard=function(card,use,self)
    if call(self,"needBear") or call(self,"getCardsNum","Jink","h")<=1 then return "." end
    local targets={}
    for _,friend in ipairs(known(self.friends_noself,"huangtian.friends")) do
        if call(friend,"hasLordSkill","huangtian") and not flag(self,friend,"HuangtianInvoked") and not call(self,"hasManjuanEffect",friend) then targets[#targets+1]=friend end
    end
    if #targets>0 then
        use.card=card;targets=sort_in_place(self,targets,"defense");use.to:append(targets[1])
    elseif call(self,"getCardsNum","Slash","he")>=2 then
        for _,enemy in ipairs(self.enemies) do
            if call(enemy,"hasLordSkill","huangtian") and not flag(self,enemy,"HuangtianInvoked") and not call(self,"hasManjuanEffect",enemy,true)
                and call(enemy,"isKongcheng") and not skill(self,enemy,"kongcheng") and not call(self,"hasTuntianEffect",enemy,true) then targets[#targets+1]=enemy end
        end
        if #targets>0 then
            local enabled=false
            if skill(self,self.player,"tianyi") and not call(self.player,"hasUsed","TianyiCard") then enabled=true
            elseif skill(self,self.player,"xianzhen") and not call(self.player,"hasUsed","XianzhenCard") then enabled=true
            elseif skill(self,self.player,"tenyearxianzhen") and not call(self.player,"hasUsed","TenyearXianzhenCard") then enabled=true
            elseif skill(self,self.player,"mobilexianzhen") and not call(self.player,"hasUsed","MobileXianzhenCard") then enabled=true end
            if enabled then
                local maximum=call(self,"getMaxCard",self.player)
                if call(maximum,"getNumber")>call(card,"getNumber") then
                    targets=sort_in_place(self,targets,"defense",true)
                    for _,enemy in ipairs(targets) do
                        if call(self.player,"canSlash",enemy,nil,false,0) then
                            use.card=card;self:setStrategyPlayerFlag(enemy,"AI_HuangtianPindian",true);use.to:append(enemy);break
                        end
                    end
                end
            end
        end
    end
end
sgs.ai_card_intention.HuangtianCard=function(self,card,from,targets)
    local target=known(targets[1],"huangtian.target")
    if call(target,"isKongcheng") and (skill(self,from,"tianyi") and not call(from,"hasUsed","TianyiCard")
        or skill(self,from,"xianzhen") and not call(from,"hasUsed","XianzhenCard")
        or skill(self,from,"tenyearxianzhen") and not call(from,"hasUsed","TenyearXianzhenCard")
        or skill(self,from,"mobilexianzhen") and not call(from,"hasUsed","MobileXianzhenCard")) then
    else sgs.updateIntention(from,target,-80) end
end
sgs.ai_use_priority.HuangtianCard=10
sgs.ai_use_value.HuangtianCard=8.5
sgs.ai_fill_skill.gongxin=function(self,inclusive,request)
    return legacy_policy(self,bind_skill(self,"gongxin",{},request),"GongxinCard",{})
end
sgs.ai_skill_use_func.GongxinCard=function(card,use,self)
    self.enemies=sort_in_place(self,self.enemies,"handcard")
    local reverse={};for i=#self.enemies,1,-1 do reverse[#reverse+1]=self.enemies[i] end;self.enemies=AIList.new(reverse)
    for _,enemy in ipairs(self.enemies) do
        if not call(enemy,"isKongcheng") and call(self,"objectiveLevel",enemy)>0
            and (call(self,"hasSuit","heart",false,enemy) or call(self,"getKnownNum",enemy)~=call(enemy,"getHandcardNum")) then use.card=card;use.to:append(enemy);return end
    end
end

local function evaluate_skill_card(self,name,skill_name,costs)
    return call(self,"evaluateSkillCard",skill_name,name,costs)
end
sgs.ai_get_cardType=function(card) return call(card,"getEquipSlot")+1 end
local function shensu_plan(self,costs,request,proposal_only)
    local slash=evaluate_skill_card(self,"slash","shensu",{})
    local use=call(self,"aiUseCard",slash)
    if use.card then
        if proposal_only then
            local ids,targets={},{}
            for i,id in ipairs(costs) do ids[i]=id end
            for i,p in ipairs(use.to) do targets[i]=call(p,"objectName") end
            return {subcards=ids,targets=targets}
        end
        return skill_answer(self,"shensu",costs,use.to,request)
    end
    return "."
end
local function shensu_one(self,prompt,request,proposal_only)
    self.enemies=sort_in_place(self,self.enemies,"defense")
    if call(self.player,"containsTrick","lightning") and #call(self.player,"getCards","j")==1
        and call(self,"hasWizard",self.friends) and not call(self,"hasWizard",self.enemies,true) then return "." end
    if call(self,"needBear") then return "." end
    return shensu_plan(self,{},request,proposal_only)
end
local function shensu_two(self,prompt,request,proposal_only)
    local cards=call(self,"sortByKeepValue",call(self.player,"getCards","he"),nil,true)
    local selected,counts
    counts={}
    if call(self,"needToThrowArmor") then selected=self.player:getArmor() end
    for _,card in ipairs(cards) do
        if call(card,"isKindOf","EquipCard") then local slot=sgs.ai_get_cardType(card);counts[slot]=(counts[slot] or 0)+1 end
    end
    for _,card in ipairs(cards) do
        if selected then break end
        if call(card,"isKindOf","EquipCard") and counts[sgs.ai_get_cardType(card)]>1 then selected=card end
    end
    for _,card in ipairs(cards) do
        if selected then break end
        if call(card,"isKindOf","EquipCard") and sgs.ai_get_cardType(card)>3 then selected=card end
    end
    for _,card in ipairs(cards) do
        if selected then break end
        if call(card,"isKindOf","EquipCard") and not call(card,"isKindOf","Armor") then selected=card end
    end
    if not selected then return "." end
    return shensu_plan(self,{call(selected,"getEffectiveId")},request,proposal_only)
end
ai_skill_use["@@shensu1"]=shensu_one
ai_skill_use["@@shensu2"]=shensu_two
-- Only proposal data escapes; the caller's provider owns any eventual receipt.
function SmartAIView:planShensuResponse(index,prompt)
    if index==1 then return shensu_one(self,prompt,nil,true) end
    if index==2 then return shensu_two(self,prompt,nil,true) end
    ai_unsupported("unknown Shensu source branch","shensu.proposal")
end
sgs.ai_cardneed.shensu=function(to,card,self)
    return call(card,"getTypeId")==sgs.Card_TypeEquip and known(getKnownCard(to,self.player,"EquipCard",false),"shensu.equip")<2
end
sgs.ai_card_intention.ShensuCard=sgs.ai_card_intention.Slash
sgs.shensu_keep_value=sgs.xiaoji_keep_value

local function ndtrick(card)
    return call(card,"isKindOf","TrickCard") and not call(card,"isKindOf","DelayedTrick")
end
local function guhuo_proposal(card,name)
    return {name=name,suit=call(card,"getSuit"),number=call(card,"getNumber"),subcards={call(card,"getId")},skill="guhuo",user_string=name}
end
local function guhuo_filled(self,proposal,request)
    -- The paid declaration scope supplies the audited GuhuoCard prototype and
    -- its class planning view; strategy code never invents receipt metadata.
    return bind_skill(self,"guhuo",proposal.subcards,request,proposal.name,"GuhuoCard")
end
sgs.ai_fill_skill.guhuo=function(self,inclusive,request)
    local cards=call(self,"sortByKeepValue",call(self.player,"getCards","h"),nil,true)
    if #cards<1 then return end
    local proposals={}
    for _,card in ipairs(cards) do
        if ndtrick(card) or call(card,"isKindOf","BasicCard") then proposals[#proposals+1]=guhuo_proposal(card,call(card,"objectName")) end
    end
    local peach=sgs.ai_guhuo_card.guhuo(self,"peach","Peach")
    if peach then proposals[#proposals+1]=peach end
    local question=#self.enemies
    for _,enemy in ipairs(self.enemies) do
        if skill(self,enemy,"chanyuan") or skill(self,enemy,"hunzi") and call(enemy,"getMark","hunzi")<1 then question=question-1 end
    end
    local ratio=question<1 and 100 or #self.enemies/question
    if #proposals>0 and ratio<100 then
        for i=1,5 do
            local proposal=proposals[math.random(1,#proposals)]
            local user=evaluate_skill_card(self,proposal.name,"guhuo",proposal.subcards)
            if user and call(user,"isAvailable",self.player) then
                local use=call(self,"aiUseCard",user)
                if use.card and not(call(user,"canRecast") and #use.to<1) then
                    self.guhuo_to=use.to
                    if call(user,"targetFixed") then
                        if math.random(1,3)<=ratio then return guhuo_filled(self,proposal,request) end
                    elseif math.random(1,4)<=ratio then return guhuo_filled(self,proposal,request) end
                end
            end
        end
    end
    if math.random(1,5)<=3*ratio then
        local function patterns()
            return known(self.world and AICardCatalog.patternNames(),"guhuo.patterns_order")
        end
        for pass=1,2 do
            for _,name in ipairs(patterns()) do
                local catalog=self:getEvaluationCard(name)
                if catalog and (call(catalog,"getTypeId")==1 or ndtrick(catalog))
                    and call(self,"getRestCardsNum",call(catalog,"getClassName"))>0
                    and (pass==2 or call(catalog,"isDamageCard")) then
                    local proposal=guhuo_proposal(cards[1],name)
                    local card=evaluate_skill_card(self,name,"guhuo",proposal.subcards)
                    if card and call(card,"isAvailable",self.player) then
                        local use=call(self,"aiUseCard",card)
                        if use.card and not(call(card,"canRecast") and #use.to<1) then
                            self.guhuo_to=use.to
                            return guhuo_filled(self,proposal,request)
                        end
                    end
                end
            end
        end
    end
    if call(self,"isWeak") then
        local proposal=sgs.ai_guhuo_card.guhuo(self,"peach","Peach")
        if proposal then
            local card=call(self,"getEvaluationCard","peach")
            if call(card,"isAvailable",self.player) then
                local use=call(self,"aiUseCard",card)
                if use.card and use.to then self.guhuo_to=use.to;return guhuo_filled(self,proposal,request) end
            end
        end
    end
    local proposal=sgs.ai_guhuo_card.guhuo(self,"slash","Slash")
    if proposal and call(self,"slashIsAvailable") then
        local use=call(self,"aiUseCard",call(self,"getEvaluationCard","slash"))
        if use.card then self.guhuo_to=use.to;return guhuo_filled(self,proposal,request) end
    end
end
sgs.ai_skill_use_func.GuhuoCard=function(card,use,self) use.card=card;use.to=self.guhuo_to end
sgs.ai_use_priority.GuhuoCard=10

-- Modern native ActiveSkillCard events expose activation identity; preserve the
-- legacy class callbacks at that public dispatch boundary.
sgs.ai_card_intention.shensu=sgs.ai_card_intention.ShensuCard
sgs.ai_card_intention.tianxiang=sgs.ai_card_intention.TianxiangCard
sgs.ai_card_intention.huangtian_attach=sgs.ai_card_intention.HuangtianCard
sgs.ai_card_intention.gongxin=sgs.ai_card_intention.GongxinCard

-- Audited effective KOF Liegong alias; no registration means no donor policy.
if ai_audited_aliases then
    ai_audited_aliases.register{id="ai_skill_invoke.kofliegong",registry="ai_skill_invoke",path={"kofliegong"},canonical_registry="ai_skill_invoke",canonical_path={"liegong"},self_index=1,defer_canonical=true}
end
