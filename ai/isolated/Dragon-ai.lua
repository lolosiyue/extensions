-- Complete fixed b6025acc Dragon source policy bodies. Native receipts remain
-- authoritative; known source-unreachable/invalid-prototype branches are explicit.
local function known(v,k)if v==nil then ai_unsupported("Dragon fact is unknown",k)end return v end
local function q(o,k,...)
    if not o or type(o[k])~="function"then ai_unsupported("Dragon helper missing",k)end
    if k=="getMark"and type(o.getStrategyMark)=="function"then k="getStrategyMark"end
    if k=="hasFlag"and AIValue.isPlayer(o)and type(o.getStrategyFlag)=="function"then k="getStrategyFlag"end
    return known(o[k](o,...),k)
end
-- Donor consults another player's private response limitations. A missing
-- lawful projection uses the authorized inactive prior and records the change.
local function response_limited(self,player,card)
    local value=player:isCardLimited(card,sgs.Card_MethodResponse)
    if value~=nil then return value end
    if AIValue.sameLegacyIdentity(player,self.player)then ai_unsupported("owner response limitation is unknown","Dragon_rende")end
    return self:useKnowledgeEstimate({value=false,status="estimate",basis="Dragon_rende:foreign_private_response_limit_inactive_prior",viewer=q(self.player,"objectName"),observer=q(player,"objectName")},"Dragon_rende")
end
local function material(c,name,skill)return{name=name,skill=skill,suit=q(c,"getSuit"),number=q(c,"getNumber"),subcards={q(c,"getEffectiveId")}}end
local function seed(self,skill,class,request)return self:legacySkillSeed(skill,class,request)end
local function paid(self,skill,class,costs,request)return self:bindSkillCard(skill,costs,request,nil,class)end
local function standard_fact(self,key)return known(self.world.strategy_facts and self.world.strategy_facts.standard and self.world.strategy_facts.standard[key],key)end
local function current_damage(self)
    local row=standard_fact(self,"current_damage");if row==false then return{}end
    local d={};for k,v in pairs(row)do d[k]=v end
    for _,k in ipairs{"from","to"}do if type(d[k])=="string"then d[k]=known(self.room:findPlayerByObjectName(d[k],true),k)elseif d[k]==false then d[k]=nil end end
    if d.card and not AIValue.isCard(d.card)then d.card=known(CardView.new(d.card),"damage card")end
    d.damage=d.amount or d.damage;return d
end
local function visible_hand(self,p)
    if AIValue.sameLegacyIdentity(p,self.player)then return q(p,"getHandcards")end
    return q(p,"getKnownCards")
end
local function singleton_visible_hand(self,p)
    if q(p,"getHandcardNum")~=1 then return{}end
    local cards=visible_hand(self,p)
    if #cards==1 and q(cards[1],"hasFlag","visible")then return cards end
    return{}
end
local function retrial_hand(self,p)
    local cards=visible_hand(self,p)
    if not AIValue.sameLegacyIdentity(p,self.player)and #cards<q(p,"getHandcardNum")then
        self:useKnowledgeEstimate({value=#cards,status="estimate",basis="Dragon_fankui:viewer_known_retrial_suits",viewer=q(self.player,"objectName"),observer=q(p,"objectName"),known_count=#cards,hidden_count=q(p,"getHandcardNum")-#cards},"Dragon_fankui")
    end
    return cards
end
local function missing_jiuyuan_prototype(self)
    local f=self.world.strategy_facts and self.world.strategy_facts.dragon
    local exists=known(f and f.promote_jiuyuan_skill_prototype,"#Promote_jiuyuanCard prototype")
    if exists then ai_unsupported("unexpected legacy prototype registration","#Promote_jiuyuanCard")end
    return nil -- source Card_Parse cannot parse the registered BasicCard as a SkillCard
end
local function current_target(use,to)
    for _,p in ipairs(use.current_targets or{})do
        if p==q(to,"objectName")or AIValue.isPlayer(p)and AIValue.sameLegacyIdentity(p,to)then return true end
    end
    return false
end

sgs.ai_fill_skill.Dragon_rende = function(self,inclusive,request)
    if q(self.player,"isKongcheng") then return end
    --if self:shouldUseRende() then
        return seed(self,"Dragon_rende","#Dragon_rendeCard",request)
    --end
end

sgs.ai_skill_use_func["#Dragon_rendeCard"] = function(card,use,self)
    local cards = sgs.QList2Table(self.player:getHandcards())
    cards = self:sortByUseValue(cards,true)
    local notFound = false
    for i = 1,q(self.player,"getHandcardNum") do
        local h,friend = self:getCardNeedPlayer(cards)
        if h and friend then cards = self:resetCards(cards,h)
        else notFound = true break end
        if AIValue.sameLegacyIdentity(friend,self.player) or not self.player:handCards():contains(q(h,"getEffectiveId")) then continue end
        local canJijiang = q(self.player,"hasLordSkill","jijiang") and q(friend,"getKingdom")=="shu"
        if q(h,"isAvailable",self.player)
        and (q(h,"isKindOf","Slash") and not canJijiang or q(h,"isKindOf","Duel") or q(h,"isKindOf","Snatch") or q(h,"isKindOf","Dismantlement")) then
            local dummy_use = self:aiUseCard(h)
            if dummy_use.card then
                if q(h,"isKindOf","Slash") or q(h,"isKindOf","Duel") then
                    local t1 = dummy_use.to:first()
                    if dummy_use.to:length()>1 then continue
                    elseif q(t1,"getHp")<2 or getCardsNum("Jink", t1, self.player) < 1
                    or response_limited(self,t1,q(self,"getEvaluationCard","jink"))
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
        elseif q(h,"isAvailable",self.player)
        and (q(h,"isKindOf","Indulgence") or q(h,"isKindOf","SupplyShortage"))
        and self:getEnemyNumBySeat(self.player,friend)>0
        and self:aiUseCard(h).card then continue end
        if #cards>1 and q(friend,"hasSkill","enyuan")
        and not(self.room:getMode()=="04_1v3" and q(self.player,"getMark","Dragon_rende")==1)
        then use.card = paid(self,"Dragon_rende","#Dragon_rendeCard",{q(h,"getId"),q(cards[1],"getId")})
        else use.card = paid(self,"Dragon_rende","#Dragon_rendeCard",{q(h,"getId")}) end
        use.to:append(friend)
        return
    end
    if notFound and q(self.player,"isWounded")
     and q(self.player,"getMark","Dragon_rende")<2 then
        cards = self:sortByUseValue(self.player:getHandcards(),true)
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
            if not self:isFriend(p) and hasManjuanEffect(p) then
                local to_give = {}
                for _,h in ipairs(cards)do
                    if not isCard("Peach,ExNihilo",h,self.player)
                    then table.insert(to_give,q(h,"getId")) end
                    if #to_give>=2-q(self.player,"getMark","Dragon_rende")
                    then break end
                end
                if #to_give>0 then
                    use.card = paid(self,"Dragon_rende","#Dragon_rendeCard",to_give)
                    use.to:append(p)
                    return
                end
            end
        end
    end
end

sgs.ai_use_value["Dragon_rendeCard"] = sgs.ai_use_value.RendeCard
sgs.ai_use_priority["Dragon_rendeCard"] = sgs.ai_use_priority.RendeCard

-- Existing common immutable-source alias gate owns: sgs.ai_card_intention["Dragon_rendeCard"] = sgs.ai_card_intention.RendeCard

sgs.dynamic_value.benefit["Dragon_rendeCard"] = true

sgs.ai_use_revises.Dragon_rende = function(self,card,use)
    if q(self.player,"getLostHp")>1 and self:findFriendsByType(sgs.Friend_Draw)
    and q(self.player,"getMark","Dragon_rende")<2
    and #self.friends_noself>0
    then
        if q(card,"getTypeId")==1
        or q(card,"getTypeId")==3 and self:getSameEquip(card)
        or q(card,"getTypeId")==2 and not (q(card,"targetFixed") and q(card,"isDamageCard"))
        then return false end
    end
    local xy = q(self,"hasSkills","jieming|oljieming",self.friends_noself)
    if xy and q(card,"isDamageCard") and self:getOverflow()<0
    and self:hasTrickEffective(card,xy,nil,use.to)
    and self:getAllPeachNum()>1
    then
        use.card = card
        use.to:append(xy)
    end
end




sgs.ai_view_as.Dragon_wusheng = function(card,player,card_place)
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    if card_place~=sgs.Player_PlaceSpecial and q(card,"isRed") and not q(card,"isKindOf","Peach") and not q(card,"hasFlag","using") then
        return material(card,"slash","Dragon_wusheng")
    end
end

sgs.ai_fill_skill.Dragon_wusheng = function(self,inclusive,request)
    local cards = self:addHandPile("he")
    cards = self:sortByUseValue(cards,true)
    local red_card = {}
    local useAll = false
    self.enemies = self:sort(self.enemies,"defense")
    for _,enemy in ipairs(self.enemies)do
        if q(enemy,"getHp")<2 and not q(enemy,"hasArmorEffect","EightDiagram")
        and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
        and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
        then useAll = true break end
    end
    self.enemies = self:sort(self.enemies,"defense")
    for _,card in ipairs(cards)do
        if q(card,"isRed") and not q(card,"isKindOf","Slash")   and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
        and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or q(q(self,"getEvaluationCard","slash"),"getTargetModResidue",self.player)>0)
        then table.insert(red_card,card) end
    end


    for _,card in ipairs(red_card)do
        local slash = q(self,"evaluateSkillCard","Dragon_wusheng","slash",{q(card,"getEffectiveId")})
        if q(slash,"isAvailable",self.player)
        then return self:bindTurnConversion("Dragon_wusheng","Slash",material(card,"slash","Dragon_wusheng"),request) end
    end
end

function sgs.ai_cardneed.Dragon_wusheng(to,card)
    return q(to,"getHandcardNum")<3 and q(card,"isRed")
end

-- Existing common immutable-source alias gate owns: sgs.ai_cardneed.Dragon_feijiang = sgs.ai_cardneed.paoxiao
sgs.double_slash_skill = sgs.double_slash_skill .. "|Dragon_feijiang"
sgs.ai_use_revises.Dragon_feijiang = function(self,card,use)
    if q(card,"isKindOf","Crossbow")
    then return false end
end

sgs.ai_fill_skill.Dragon_feijiang = function(self,inclusive,request)
    if q(self.player,"isKongcheng") then return end
        if self:getCardsNum("Slash") == 0 then return false end
        if #self.enemies == 0 then return false end
        if q(self.player,"getMark","Dragon_feijiangFailed-PlayClear") > 0 then return false end
    return seed(self,"Dragon_feijiang","#Dragon_feijiangCard",request)
end

sgs.ai_skill_use_func["#Dragon_feijiangCard"] = function(card,use,self)
    use.card = paid(self,"Dragon_feijiang","#Dragon_feijiangCard",{})
end
sgs.need_kongcheng = sgs.need_kongcheng .. "|Dragon_kongcheng"

sgs.ai_target_revises.Dragon_kongcheng = function(to,card)
    if q(card,"isKindOf","Slash") and q(to,"isKongcheng")
    then return true end
end


function sgs.ai_cardneed.Dragon_jizhi(to,card)
    return q(card,"isKindOf","TrickCard")
end

sgs.Dragon_jizhi_keep_value = sgs.jizhi_keep_value

sgs.ai_card_priority.Dragon_jizhi = function(self,card,v)
    if self.useValue
    and q(card,"isKindOf","TrickCard")
    then v = v+3 end
end

sgs.ai_skill_discard.Dragon_zhiheng = function(self)
    local to_discard = {}
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    cards = self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if self:getKeepValue(card)<5 then
            table.insert(to_discard, q(card,"getEffectiveId"))
        end
    end
    if #to_discard > 0 then
        return to_discard
    end
    return {}
end


sgs.ai_fill_skill.Dragon_fuyuanVS = function(self,inclusive,request)
    if q(self.player,"hasFlag","Dragon_fuyuan") then return nil end
    if q(self.player,"getKingdom") ~= "wu" then return nil end

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    local card
    cards = self:sortByUseValue(cards, true)
    for _, acard in ipairs(cards) do
        card = acard
        break
    end
    if not card then return nil end

    local card_id = q(card,"getEffectiveId")
    local card_str = "#Dragon_fuyuanCard:" .. card_id .. ":"
    local skillcard = paid(self,"Dragon_fuyuanVS","#Dragon_fuyuanCard",{card_id},request)

    assert(skillcard)
    return skillcard
end

sgs.ai_skill_use_func["#Dragon_fuyuanCard"] = function(card, use, self)
    if self:needBear() or self:getCardsNum("Jink", "h") <= 1 then
        return
    end
    local targets = {}
    for _, friend in ipairs(self.friends_noself) do
        if q(friend,"hasLordSkill","Dragon_fuyuan") then
            if not q(friend,"hasFlag","Dragon_fuyuanInvoked") then
                if not hasManjuanEffect(friend) then
                    table.insert(targets, friend)
                end
            end
        end
    end
    if #targets > 0 then --黄天己方
        use.card = card
        targets = self:sort(targets, "defense")
        if use.to then
            use.to:append(targets[1])
        end
    elseif self:getCardsNum("Slash", "he") >= 2 then --黄天对方
        for _, enemy in ipairs(self.enemies) do
            if q(enemy,"hasLordSkill","Dragon_fuyuan") then
                if not q(enemy,"hasFlag","Dragon_fuyuanInvoked") then
                    if not hasManjuanEffect(enemy) then
                        if q(enemy,"isKongcheng") and not q(enemy,"hasSkill","kongcheng") and not hasTuntianEffect(enemy, true) then --必须保证对方空城，以保证天义/陷阵的拼点成功
                            table.insert(targets, enemy)
                        end
                    end
                end
            end
        end
        if #targets > 0 then
            local flag = false
            if q(self.player,"hasSkill","tianyi") and not q(self.player,"hasUsed","TianyiCard") then
                flag = true
            elseif q(self.player,"hasSkill","xianzhen") and not q(self.player,"hasUsed","XianzhenCard") then
                flag = true
            end
            if flag then
                local maxCard = self:getMaxCard(self.player) --最大点数的手牌
                if q(maxCard,"getNumber") > q(card,"getNumber") then --可以保证拼点成功
                    targets = self:sort(targets, "defense", true)
                    for _, enemy in ipairs(targets) do
                        if self.player:canSlash(enemy, nil, false, 0) then --可以发动天义或陷阵
                            use.card = card
                            self:setStrategyPlayerFlag(enemy,"AI_HuangtianPindian")
                            if use.to then
                                use.to:append(enemy)
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end

sgs.ai_card_intention["Dragon_fuyuanCard"] = function(self, card, from, tos)
    if q(tos[1],"isKongcheng") and ((q(from,"hasSkill","tianyi") and not q(from,"hasUsed","TianyiCard"))
            or (q(from,"hasSkill","xianzhen") and not q(from,"hasUsed","XianzhenCard"))) then
    else
        sgs.updateIntention(from, tos[1], -80)
    end
end

sgs.ai_use_priority["Dragon_fuyuanCard"] = 10
sgs.ai_use_value["Dragon_fuyuanCard"] = 8.5

sgs.ai_fill_skill.tongling = function(self,inclusive,request)
    if q(self.player,"getMark","@bell") == 0 then return end
    return seed(self,"tongling","#tonglingCard",request)
end

sgs.ai_skill_use_func["#tonglingCard"]=function(card,use,self)
    use.card = paid(self,"tongling","#tonglingCard",{})
end
local card_finished=sgs.CardFinished or "CardFinished"
sgs.ai_event_callback[card_finished]=sgs.ai_event_callback[card_finished]or{}
sgs.ai_event_callback[card_finished].tonglingCard = function(self,player,event)
    if event.card_name=="tonglingCard" then
        local witness=known(self.world.strategy_facts and self.world.strategy_facts.tongling_role_witness,"tongling public role witness")
        if witness.player~=q(player,"objectName")then ai_unsupported("tongling witness actor mismatch","tongling")end
        local role=known(witness.role,"tongling public role")
        self:emitStrategyEffect({kind="tongling_role",player=q(player,"objectName"),role=role})
    end
end



sgs.ai_use_revises.Dragon_keji = function(self,card,use)
    if q(card,"isKindOf","Slash") and not self:hasCrossbowEffect()
    and (#self.enemies>1 or #self.friends>1) and self:getOverflow()>1
    then return false end
end


sgs.ai_fill_skill.Dragon_kurou = function(self,inclusive,request)
    if q(self.player,"getHp")==1 then return end
    --特殊场景
    -- Fixed classical_func has no Dragon_kurou entry (only kurou).
    --一般场景
    self:setPriorityValue("Dragon_kurouCard",6.8,"Dragon_kurou")
    local losthp = isLord(self.player) and 0 or 1
    if ((q(self.player,"getHp")>3 and q(self.player,"getLostHp")<=losthp and q(self.player,"getHandcardNum")>q(self.player,"getHp"))
        or (q(self.player,"getHp")-q(self.player,"getHandcardNum")>=2)) and not (isLord(self.player) and q(self,"getResponsePolicy").turn_count<=1) then
        return seed(self,"Dragon_kurou","#Dragon_kurouCard",request)
    end
    local slash = q(self,"getEvaluationCard","slash")
    if self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow")
    or q(self.player,"hasSkill","paoxiao") then
        for _,enemy in ipairs(self.enemies)do
            if self.player:canSlash(enemy,slash,true) and self:slashIsEffective(slash,enemy)
                and not (q(enemy,"hasSkill","kongcheng") and q(enemy,"isKongcheng"))
                and not (q(enemy,"hasSkills","Dragon_fankui|guixin") and not q(self.player,"hasSkill","paoxiao"))
                and not q(enemy,"hasSkills","fenyong|jilei|zhichi")
                and self:isGoodTarget(enemy,self.enemies,slash) and not self:slashProhibit(slash,enemy) and q(self.player,"getHp")>1 then
                return seed(self,"Dragon_kurou","#Dragon_kurouCard",request)
            end
        end
    end
    -- The remaining source HP == 1 suicide branches are unreachable after the entry guard.
end

sgs.ai_skill_use_func["#Dragon_kurouCard"]=function(card,use,self)
    if not use.isDummy then self:speak("kurou") end
    use.card = paid(self,"Dragon_kurou","#Dragon_kurouCard",{})
end

sgs.ai_use_priority["Dragon_kurouCard"] = 6.8




sgs.ai_fill_skill.Dragon_jiedao = function(self,inclusive,request)
    if q(self.player,"hasUsed","#Dragon_jiedaoCard") then return end
    return seed(self,"Dragon_jiedao","#Dragon_jiedaoCard",request)
end

sgs.ai_skill_use_func["#Dragon_jiedaoCard"] = function(card, use, self)
    self.friends_noself = self:sort(self.friends_noself, "defense")
    for _, p in ipairs(self.friends_noself) do
        if q(self,"hasSkill",sgs.lose_equip_skill, p) and p:getWeapon() then
            use.card = paid(self,"Dragon_jiedao","#Dragon_jiedaoCard",{})
            if use.to then use.to:append(p) end
            return
        end
    end
    self.enemies = self:sort(self.enemies, "defense")
    for _, p in ipairs(self.enemies) do
        if not q(self,"hasSkill",sgs.lose_equip_skill, p) and p:getWeapon() then
            use.card = paid(self,"Dragon_jiedao","#Dragon_jiedaoCard",{})
            if use.to then use.to:append(p) end
            return
        end
    end
    for _, p in ipairs(self.friends_noself) do
        if p:getWeapon() then
            use.card = paid(self,"Dragon_jiedao","#Dragon_jiedaoCard",{})
            if use.to then use.to:append(p) end
            return
        end
    end
end

sgs.ai_use_value["Dragon_jiedaoCard"]       = 8
sgs.ai_use_priority["Dragon_jiedaoCard"]    = 8
sgs.ai_card_intention["Dragon_jiedaoCard"]  = function(self,card,from,tos)
    local to = tos[1]
    if q(self,"hasSkill",sgs.lose_equip_skill, to) then
        sgs.updateIntention(from,to,-80)
    else
        sgs.updateIntention(from,to,20)
    end
end

sgs.ai_fill_skill.Dragon_guose = function(self,inclusive,request)
    local cards = self:addHandPile("he")
    local card
    cards = self:sortByUseValue(cards,true)
    local has_weapon,has_armor = false,false
    for _,acard in ipairs(cards)  do
        if q(acard,"isKindOf","Weapon") and not (q(acard,"getSuit")==sgs.Card_Diamond) then has_weapon=true end
    end
    for _,acard in ipairs(cards)  do
        if q(acard,"isKindOf","Armor") and not (q(acard,"getSuit")==sgs.Card_Diamond) then has_armor=true end
    end
    for _,acard in ipairs(cards)  do
        if (q(acard,"getSuit")==sgs.Card_Diamond) and ((self:getUseValue(acard)<sgs.ai_use_value.Indulgence) or inclusive) then
            local shouldUse=true
            if q(acard,"isKindOf","Armor") then
                if not self.player:getArmor() then shouldUse = false
                elseif q(self.player,"hasEquip",acard) and not has_armor and self:evaluateArmor()>0 then shouldUse = false
                end
            end
            if q(acard,"isKindOf","Weapon") then
                if not self.player:getWeapon() then shouldUse = false
                elseif q(self.player,"hasEquip",acard) and not has_weapon then shouldUse = false
                end
            end
            if shouldUse then
                card = acard
                break
            end
        end
    end
    if not card then return nil end
    return self:bindTurnConversion("Dragon_guose","Indulgence",material(card,"Dragon_indulgence","Dragon_guose"),request)
end

function sgs.ai_cardneed.Dragon_guose(to,card)
    return q(card,"getSuit")==sgs.Card_Diamond
end


sgs.ai_skill_invoke.Dragon_fankui = function(self,data)
    local target = data:toPlayer()
    if sgs.ai_need_damaged.Dragon_fankui(self,target,self.player) then return true end
    return self:doDisCard(target,"h", true)
end

sgs.ai_choicemade_filter.cardChosen.Dragon_fankui = function(self,player,promptlist)
    local damage = current_damage(self)
    if damage.from then
        local intention = 10
        -- Source performs an unused card lookup here; no strategy observation follows.
        if not self:doDisCard(damage.from,"h") then intention = -intention
        elseif sgs.ai_need_damaged.Dragon_fankui(self,damage.from,player)
        or self:getOverflow(damage.from)>2
        then intention = 0 end
        sgs.updateIntention(player,damage.from,intention)
    end
end

sgs.ai_skill_cardchosen.Dragon_fankui = function(self,who,flags)
    local suit = sgs.ai_need_damaged.Dragon_fankui(self,who,self.player)
    if not suit then return -1 end

    local cards = {}
    local handcards = singleton_visible_hand(self,who)
    if #handcards==1 then table.insert(cards,handcards[1]) end

    for i=1,#cards,1 do
        if (cards[i]:getSuit()==suit and suit~=sgs.Card_Spade) or
            (cards[i]:getSuit()==suit and suit==sgs.Card_Spade and cards[i]:getNumber()>=2 and cards[i]:getNumber()<=9) then
            return cards[i]:getId()
        end
    end
    return -1
end

sgs.ai_can_damagehp.Dragon_fankui = function(self,from,card,to)
    if from and q(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
    and self:canLoseHp(from,card,to)
    then
        return self:isEnemy(from) and self:isWeak(from) and not q(from,"isKongcheng")
    end
end

sgs.ai_need_damaged.Dragon_fankui = function (self,attacker,player)
    if not q(player,"hasSkills","guicai+Dragon_fankui") then return false end
    if not attacker then return end
    local need_retrial = function(target)
        local alive_num = self.room:alivePlayerCount()
        return alive_num+q(target,"getSeat") % alive_num>self.room:getCurrent():getSeat()
                and q(target,"getSeat")<alive_num+q(player,"getSeat") % alive_num
    end
    local retrial_card ={["spade"]=nil,["heart"]=nil,["club"]=nil}
    local attacker_card ={["spade"]=nil,["heart"]=nil,["club"]=nil}

    local handcards = retrial_hand(self,player)
    for i=1,#handcards,1 do
        if handcards[i]:getSuit()==sgs.Card_Spade and handcards[i]:getNumber()>=2 and handcards[i]:getNumber()<=9 then
            retrial_card.spade = true
        end
        if handcards[i]:getSuit()==sgs.Card_Heart then
            retrial_card.heart = true
        end
        if handcards[i]:getSuit()==sgs.Card_Club then
            retrial_card.club = true
        end
    end

    local cards = {}
    local handcards = singleton_visible_hand(self,attacker)
    if #handcards==1 then table.insert(cards,handcards[1]) end

    for i=1,#cards,1 do
        if cards[i]:getSuit()==sgs.Card_Spade and cards[i]:getNumber()>=2 and cards[i]:getNumber()<=9 then
            attacker_card.spade = sgs.Card_Spade
        end
        if cards[i]:getSuit()==sgs.Card_Heart then
            attacker_card.heart = sgs.Card_Heart
        end
        if cards[i]:getSuit()==sgs.Card_Club then
            attacker_card.club = sgs.Card_Club
        end
    end

    local players = self.room:getOtherPlayers(player)
    for _,aplayer in sgs.list(players)do
        if q(aplayer,"containsTrick","lightning") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) then
            if not retrial_card.spade and attacker_card.spade then return attacker_card.spade end
        end

        if self:isFriend(aplayer,player) and not q(aplayer,"containsTrick","YanxiaoCard") and not q(aplayer,"hasSkill","qiaobian") then
            if q(aplayer,"containsTrick","indulgence") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) and q(aplayer,"getHandcardNum")>=q(aplayer,"getHp") then
                if not retrial_card.heart and attacker_card.heart then return attacker_card.heart end
            end
            if q(aplayer,"containsTrick","supply_shortage") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) and q(self,"hasSkills","yongshi",aplayer) then
                if not retrial_card.club and attacker_card.club then return attacker_card.club end
            end
        end
    end
    return false
end




sgs.ai_skill_invoke.Dragon_ganglie = function(self,data)
    local mode = self.room:getMode()
    if mode:find("_mini_41") or mode:find("_mini_46") then return true end
    local damage = data:toDamage()
    if not damage.from then
        local zhangjiao = self.room:findPlayerBySkillName("guidao")
        return zhangjiao and self:isFriend(zhangjiao) and not q(zhangjiao,"isNude")
    end
    if self:needToLoseHp(damage.from,self.player,damage.card) then
        if self:isFriend(damage.from) then
            return true
        end
        return false
    end
    return not self:isFriend(damage.from) and self:canAttack(damage.from)
end

-- sgs.ai_need_damaged.Dragon_ganglie = function(self,attacker,player)
--  if not attacker then return end
--  if self:needToLoseHp(attacker,player) and not q(attacker,"hasSkill","Dragon_ganglie") then return self:isFriend(attacker,player) end
--  if self:isEnemy(attacker) and q(attacker,"getHp")+q(attacker,"getHandcardNum")<=3
--  and not (q(self,"hasSkills",sgs.need_kongcheng.."|buqu",attacker) and q(attacker,"getHandcardNum")>1) and self:isGoodTarget(attacker,self:getEnemies(attacker))
--  then
--      return true
--  end
--  return false
-- end

sgs.ai_skill_discard.Dragon_ganglie = function(self,discard_num,min_num,optional,include_equip)
    return nosganglie_discard(self,discard_num,min_num,optional,include_equip,"Dragon_ganglie")
end

function sgs.ai_slash_prohibit.Dragon_ganglie(self,from,to)
    if self:isFriend(from,to) then return false end
    if q(from,"hasSkill","jueqing") or (q(from,"hasSkill","nosqianxi") and from:distanceTo(to)==1) then return false end
    if q(from,"hasFlag","NosJiefanUsed") then return false end
    return q(from,"getHandcardNum")+q(from,"getHp")<4
end

sgs.ai_choicemade_filter.skillInvoke.Dragon_ganglie = function(self,player,promptlist)
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

sgs.ai_cardneed.Dragon_luoyi = sgs.ai_cardneed.slash
sgs.ai_ajustdamage_from.Dragon_luoyi = function(self,from,to,card,nature)
    if not from:getWeapon() and card and q(card,"isKindOf","Slash")
    then return 1 end
end

sgs.ai_view_as.Dragon_qingguo = function(card,player,card_place)
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    if card_place==sgs.Player_PlaceHand then
        return material(card,"jink","Dragon_qingguo")
    end
end

function sgs.ai_cardneed.Dragon_qingguo(to,card)
    return to:getCards("h"):length()<2
end



sgs.ai_fill_skill.Dragon_qingnang = function(self,inclusive,request)
    if q(self.player,"getHandcardNum")<1 then return nil end
    if not q(self.player,"isWounded") then return nil end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)

    local compare_func = function(a,b)
        local v1 = self:getKeepValue(a)+( q(a,"isRed") and 50 or 0 )+( q(a,"isKindOf","Peach") and 50 or 0 )
        local v2 = self:getKeepValue(b)+( q(b,"isRed") and 50 or 0 )+( q(b,"isKindOf","Peach") and 50 or 0 )
        return v1<v2
    end
    table.sort(cards,compare_func)

    return paid(self,"Dragon_qingnang","#Dragon_qingnangCard",{q(cards[1],"getId")},request)
end

sgs.ai_skill_use_func["#Dragon_qingnangCard"] = function(card,use,self)

    if q(self.player,"getHp")<getBestHp(self.player) then
        use.card = card
        return end
end

sgs.ai_use_priority["Dragon_qingnangCard"] = 4.2
sgs.ai_card_intention["Dragon_qingnangCard"] = -100

sgs.dynamic_value.benefit["Dragon_qingnangCard"] = true


sgs.ai_skill_cardask["@Dragon_jijiu"] = function(self,data,pattern)
    local dmg = data:toDamage()
    local invoke
    if self:isFriend(dmg.to) then
        if self:damageStruct(dmg) and not self:needToLoseHp(dmg.to,dmg.from,dmg.card)
        then invoke = true end
    end
    if invoke then
        local equipCards = {}
        for _,c in sgs.qlist(self.player:getCards("h"))do
            if q(c,"isRed") and q(self.player,"canDiscard",self.player,q(c,"getEffectiveId")) then
                table.insert(equipCards,c)
            end
        end
        if #equipCards>0 then
            equipCards = self:sortByKeepValue(equipCards)
            return q(equipCards[1],"getEffectiveId")
        end
    end
    return "."
end


sgs.hit_skill = sgs.hit_skill .. "|Dragon_wushuang"
sgs.ai_cardneed.Dragon_wushuang = sgs.ai_cardneed.slash

sgs.ai_skill_discard.Dragon_wushuang = function(self,x,n,o,e,p)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    cards = self:sortByKeepValue(cards)
    local to_cards = {}
    local cp = self.room:getCurrent()
    for i,c in sgs.list(cards)do
        if ((not self:isEnemy(cp) and not self:needToLoseHp(self.player)) or self:isWeak()) and not q(c,"isKindOf","Peach") then
            table.insert(to_cards,q(c,"getEffectiveId"))
            break
        end
    end
    return to_cards
end

sgs.ai_use_revises.Dragon_qiankun = function(self,card,use)
    if q(card,"isKindOf","Slash") or q(card,"isNDTrick") then
        self:setStrategyCardFlag(card,"Qinggang")
    end
end
sgs.weapon_range.Dragon_double_sword = 2
sgs.weapon_range.Dragon_blade = 3
sgs.weapon_range.Dragon_spear = 3
sgs.weapon_range.Dragon_axe = 3
sgs.weapon_range.Dragon_kylin_bow = 5

sgs.ai_view_as.Dragon_spear = function(card,player,card_place)
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    if card_place~=sgs.Player_PlaceSpecial and not q(card,"isKindOf","Peach") and not q(card,"hasFlag","using") and q(player,"getMark","Equips_Nullified_to_Yourself") == 0 and q(player,"getHp") > 2 and q(player,"hasFlag","Dragon_spear") then
        return material(card,"slash","Dragon_spear")
    end
end

sgs.ai_skill_invoke.Dragon_kylin_bowSkill = function(self,data)
    local damage = data:toDamage()
    if q(damage.from,"hasSkill","kuangfu") and damage.to:getCards("e"):length()==1 then return false end
    if q(self,"hasSkills",sgs.lose_equip_skill,damage.to) then
        return self:isFriend(damage.to)
    end
    return self:isEnemy(damage.to)
end


-- Existing common immutable-source alias gate owns: sgs.ai_skill_invoke.Promote_tieji = sgs.ai_skill_invoke.nostieji
sgs.hit_skill = sgs.hit_skill .. "|Promote_tieji"
sgs.ai_cardneed.Promote_tieji = sgs.ai_cardneed.slash


function sgs.ai_cardneed.Promote_jizhi(to,card)
    return q(card,"isKindOf","TrickCard")
end

sgs.Promote_jizhi_keep_value = sgs.jizhi_keep_value

sgs.ai_card_priority.Promote_jizhi = function(self,card,v)
    if self.useValue
    and q(card,"isKindOf","TrickCard")
    then v = v+3 end
end


sgs.ai_fill_skill.Promote_zhiheng = function(self,inclusive,request)
    return seed(self,"Promote_zhiheng","#Promote_zhihengCard",request)
end

sgs.ai_skill_use_func["#Promote_zhihengCard"] = function(card,use,self)
    local unpreferedCards = {}
    local cards = sgs.QList2Table(self.player:getHandcards())

    if q(self.player,"getHp")<3 then
        local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
        local keep_slash = standard_fact(self,"jilve_wansha")
        for _,zcard in sgs.list(self.player:getCards("he"))do
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
                                if q(p,"getHp")<=1 then
                                    shouldUse = false
                                    if self.player:distanceTo(p)>1 then keep_weapon = self.player:getWeapon() end
                                    break
                                end
                            end
                            if dummy_use.to:length()>1 then shouldUse = false end
                        end
                        if not self:isWeak() then shouldUse = false end
                        if not shouldUse then use_slash = true end
                    end
                end
                if q(zcard,"getTypeId")==sgs.Card_TypeTrick then
                    if self:aiUseCard(zcard).card then shouldUse = false end
                end
                if q(zcard,"getTypeId")==sgs.Card_TypeEquip and not q(self.player,"hasEquip",zcard) then
                    if self:aiUseCard(zcard).card then shouldUse = false end
                    if keep_weapon and q(zcard,"getEffectiveId")==q(keep_weapon,"getEffectiveId") then shouldUse = false end
                end
                if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","Armor") and not self:needToThrowArmor() then shouldUse = false end
                if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
                if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then shouldUse = false end
                if isCard("Jink",zcard,self.player) and not keep_jink then
                    keep_jink = true
                    shouldUse = false
                end
                if q(self.player,"getHp")<2 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
                    keep_analeptic = true
                    shouldUse = false
                end
                if shouldUse then table.insert(unpreferedCards,q(zcard,"getId")) end
            end
        end
    end

    if #unpreferedCards<1 then
        local use_slash_num = 0
        cards = self:sortByKeepValue(cards)
        for _,card in ipairs(cards)do
            if q(card,"isKindOf","Slash") then
                local will_use = false
                if use_slash_num<=q(card,"getTargetModResidue",self.player)
                then
                    if self:aiUseCard(card).card then
                        will_use = true
                        use_slash_num = use_slash_num+1
                    end
                end
                if not will_use then table.insert(unpreferedCards,q(card,"getId")) end
            end
        end

        local num = self:getCardsNum("Jink")-1
        if self.player:getArmor() then num = num+1 end
        if num>0 then
            for _,card in ipairs(cards)do
                if q(card,"isKindOf","Jink") and num>0 then
                    table.insert(unpreferedCards,q(card,"getId"))
                    num = num-1
                end
            end
        end
        for _,card in ipairs(cards)do
            if q(card,"isKindOf","Weapon") and q(self.player,"getHandcardNum")<3
            or self:getSameEquip(card,self.player)
            or q(card,"isKindOf","OffensiveHorse")
            or q(card,"isKindOf","AmazingGrace")
            then table.insert(unpreferedCards,q(card,"getId"))
            elseif q(card,"getTypeId")==sgs.Card_TypeTrick then
                if not self:aiUseCard(card).card then table.insert(unpreferedCards,q(card,"getId")) end
            end
        end

        if self.player:getWeapon() and q(self.player,"getHandcardNum")<3 then
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
        if q(self,"getKnownCardById",unpreferedCards[i]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then
            table.removeOne(unpreferedCards,unpreferedCards[i])
        end
    end

    local use_cards = {}
    for i = #unpreferedCards,1,-1 do
        if not q(self.player,"isJilei",q(self,"getKnownCardById",unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
    end

    if #use_cards>0 then
        if self.room:getMode()=="02_1v1" and q(self.room,"getDuelRule")~="Classical" then
            local use_cards_kof = {use_cards[1]}
            if #use_cards>1 then table.insert(use_cards_kof,use_cards[2]) end
            use.card = paid(self,"Promote_zhiheng","#Promote_zhihengCard",use_cards_kof)
        else
            use.card = paid(self,"Promote_zhiheng","#Promote_zhihengCard",use_cards)
        end
    end
end

sgs.ai_use_value["Promote_zhihengCard"] = 9
sgs.ai_use_priority["Promote_zhihengCard"] = 2.61
sgs.dynamic_value.benefit["Promote_zhihengCard"] = true


function sgs.ai_cardneed.Promote_zhiheng(to,card)
    return not q(card,"isKindOf","Jink")
end

sgs.ai_fill_skill.Promote_jiuyuanVS = function(self,inclusive,request)
    if q(self.player,"getKingdom") ~= "wu" then return nil end

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    local card
    cards = self:sortByUseValue(cards, true)
    for _, acard in ipairs(cards) do
        if q(acard,"isKindOf","Peach") then
            card = acard
            break
        end
    end
    if not card then return nil end

    local card_id = q(card,"getEffectiveId")
    local card_str = "#Promote_jiuyuanCard:" .. card_id .. ":"
    local skillcard = missing_jiuyuan_prototype(self)

    -- assert(skillcard)
    return skillcard
end
sgs.ai_skill_use_func["#Promote_jiuyuanCard"]=function(card,use,self)
    local peach = q(self,"getEvaluationCard","peach")
    for _,friend in ipairs(self.friends_noself)do
        if friend and q(friend,"hasLordSkill","Promote_jiuyuan") then
            if q(peach,"isAvailable",friend) and not q(self.player,"isProhibited",friend,peach) then
                use.card = card
                use.to:append(friend)
                return
            end
        end
    end
end


sgs.ai_fill_skill.Promote_fanjian = function(self,inclusive,request)
    if q(self.player,"isKongcheng") then return nil end
    return seed(self,"Promote_fanjian","#Promote_fanjianCard",request)
end

sgs.ai_skill_use_func["#Promote_fanjianCard"]=function(card,use,self)

    local cards = sgs.QList2Table(self.player:getHandcards())
    cards = self:sortByUseValue(cards,true)
    if #cards==1 and q(cards[1],"getSuit")==sgs.Card_Diamond then return end
    if #cards<=4 and (self:getCardsNum("Peach")>0 or self:getCardsNum("Analeptic")>0) then return end
    self.enemies = self:sort(self.enemies,"hp")
    local suits = {}
    local suits_num = 0
    for _,c in ipairs(cards)do
        if not suits[q(c,"getSuitString")] then
            suits[q(c,"getSuitString")] = true
            suits_num = suits_num+1
        end
    end

    local wgt = self.room:findPlayerBySkillName("buyi")
    if wgt and self:isFriend(wgt) then wgt = nil end

    for _,enemy in ipairs(self.enemies)do
        local visible = 0
        for _,card in ipairs(cards)do
            local flag = string.format("%s_%s_%s","visible",enemy:objectName(),self.player:objectName())
            if q(card,"hasFlag","visible") or q(card,"hasFlag",flag) then visible = visible+1 end
        end
        if visible>0 and (#cards<=2 or suits_num<=2) then continue end
        if self:canAttack(enemy) and not q(enemy,"hasSkills","qingnang|jijiu|tianxiang")
        and not (wgt and q(card,"getTypeId")~=sgs.Card_Basic and (q(enemy,"isKongcheng") or enemy:objectName()==wgt:objectName()))
        and self:damageIsEffective(enemy,card)
        then
            use.card = paid(self,"Promote_fanjian","#Promote_fanjianCard",{})
            use.to:append(enemy)
            return
        end
    end
end

sgs.ai_card_intention["Promote_fanjianCard"] = 70

function sgs.ai_skill_suit.Promote_fanjian(self)
    local map = {0,0,1,2,2,3,3,3}
    local suit = map[math.random(1,8)]
    local tg = self.room:getCurrent()
    local suits = {}
    local maxnum,maxsuit = 0,nil
    for _,c in sgs.qlist(visible_hand(self,tg))do
        local flag = string.format("%s_%s_%s","visible",self.player:objectName(),tg:objectName())
        if q(c,"hasFlag",flag) or q(c,"hasFlag","visible") then
            if not suits[q(c,"getSuitString")] then suits[q(c,"getSuitString")] = 1 else suits[q(c,"getSuitString")] = suits[q(c,"getSuitString")]+1 end
            if suits[q(c,"getSuitString")]>maxnum then
                maxnum = suits[q(c,"getSuitString")]
                maxsuit = q(c,"getSuit")
            end
        end
    end
    if q(self.player,"hasSkill","hongyan") and (maxsuit==sgs.Card_Spade or suit==sgs.Card_Spade) then
        return sgs.Card_Heart
    end
    if maxsuit then
        if q(self.player,"hasSkill","hongyan") and maxsuit==sgs.Card_Spade then return sgs.Card_Heart end
        return maxsuit
    else
        if q(self.player,"hasSkill","hongyan") and suit==sgs.Card_Spade then return sgs.Card_Heart end
        return suit
    end
end

sgs.dynamic_value.damage_card.Promote_fanjianCard = true








sgs.ai_choicemade_filter.skillInvoke.Promote_ganglie = sgs.ai_choicemade_filter.skillInvoke.Dragon_ganglie

sgs.ai_slash_prohibit.Promote_ganglie = sgs.ai_slash_prohibit.Dragon_ganglie
sgs.ai_skill_discard.Promote_ganglie = sgs.ai_skill_discard.Dragon_ganglie
sgs.ai_skill_invoke.Promote_ganglie = sgs.ai_skill_invoke.Dragon_ganglie

sgs.ai_ajustdamage_from.Promote_luoyi = function(self,from,to,card,nature)
    if from and q(from,"hasFlag","Promote_luoyi") and card and (q(card,"isKindOf","Slash") or q(card,"isKindOf","Duel"))
    then return 1 end
end


-- Existing common immutable-source alias gate owns: sgs.ai_skill_invoke.Promote_luoyi = sgs.ai_skill_invoke.nosluoyi


-- Existing common immutable-source alias gate owns: sgs.ai_cardneed.Promote_luoyi = sgs.ai_cardneed.nosluoyi

sgs.Promote_luoyi_keep_value = sgs.nosluoyi_keep_value



sgs.ai_fill_skill.Promote_qingnang = function(self,inclusive,request)
    if q(self.player,"getHandcardNum")<1 then return nil end
    if not q(self.player,"isWounded") then return nil end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)

    local compare_func = function(a,b)
        local v1 = self:getKeepValue(a)+( q(a,"isRed") and 50 or 0 )+( q(a,"isKindOf","Peach") and 50 or 0 )
        local v2 = self:getKeepValue(b)+( q(b,"isRed") and 50 or 0 )+( q(b,"isKindOf","Peach") and 50 or 0 )
        return v1<v2
    end
    table.sort(cards,compare_func)

    return paid(self,"Promote_qingnang","#Promote_qingnangCard",{q(cards[1],"getId")},request)
end

sgs.ai_skill_use_func["#Promote_qingnangCard"] = function(card,use,self)

    if q(self.player,"getHp")<getBestHp(self.player) then
        use.card = card
        return end
end

sgs.ai_use_priority["Promote_qingnangCard"] = 4.2
sgs.ai_card_intention["Promote_qingnangCard"] = -100

sgs.dynamic_value.benefit["Promote_qingnangCard"] = true

sgs.ai_skill_playerchosen.Promote_luohan = function(self, targets)
    local lord = self.room:getLord()
    return lord
end

sgs.ai_skill_invoke.Promote_luohan = function(self,data)
    local dmg = data:toDamage()
    return self:damageStruct(dmg) and not self:needToLoseHp(dmg.to,dmg.from,dmg.card)
end

sgs.ai_skill_playerchosen.Promote_xuanwu = function(self, targets)
    self.friends_noself = self:sort(self.friends_noself, "hp")
    for _, friend in ipairs(self.friends_noself) do
        return friend
    end
    return targets[1]
end
sgs.ai_skill_invoke.Promote_xuanwu = function(self,data)
    if math.random(1, 5) > 3 then return true else return false end
end
sgs.ai_skill_playerchosen.Promote_zhuyou = function(self, targets)
    self.friends_noself = self:sort(self.friends_noself, "hp")
    for _, friend in ipairs(self.friends_noself) do
        return friend
    end
    return targets[1]
end
sgs.ai_skill_invoke.Promote_zhuyou = function(self,data)
    if math.random(1, 5) > 3 then return true else return false end
end

function SmartAIView:useCardDragonPeach(card,use)
    for _,enemy in sgs.list(self.enemies)do
        if q(self.player,"getHandcardNum")<3 and q(enemy,"hasSkills",sgs.drawpeach_skill
        or getCardsNum("Dismantlement",enemy)>0
        or q(enemy,"hasSkill","jixi") and enemy:distanceTo(self.player)<2
        or q(enemy,"hasSkill","qixi") and getKnownCard(enemy,self.player,"black",nil,"he")>0
        or getCardsNum("Snatch",enemy)>0 and enemy:distanceTo(self.player)==1
        or q(enemy,"hasSkill","tiaoxin") and (self.player:inMyAttackRange(enemy) and self:getCardsNum("Slash")<1 or not self.player:canSlash(enemy)))
        then use.card = card use.to:append(self.player) return end
    end
    local arr1,arr2 = self:getWoundedFriend(false,true)
    local target = nil

    if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and q(arr1[1],"getHp")<getBestHp(arr1[1]) then target = arr1[1] end
    if target then
        use.card = card
        use.to:append(target)
        return
    end
    for _,friend in ipairs(arr2)do
        if not q(friend,"hasSkills","hunzi|longhun") then
            use.card = card
            use.to:append(friend)
            return
        end
    end
    local lord = getLord(self.player)
    if not(lord and self:isFriend(lord) and self:isWeak(lord)) and q(self.player,"getHp")<2
    or q(self.player,"getLostHp")>=2 and hasWulingEffect("@water")
    or self:getCardsNum("DragonPeach","h")>q(self.player,"getHp")
    or not q(self.player,"hasCard",card)
    then use.card = card use.to:append(self.player) return end
    local of = self:getOverflow()
    if of<1 and #self.friends_noself>0
    or self:needToLoseHp(self.player,nil,card,nil,true)
    then return end
    if lord and q(lord,"getHp")<=2 and self:isFriend(lord)
    and self:isWeak(lord) then
        if AIValue.sameLegacyIdentity(self.player,lord)
        or self:getCardsNum("DragonPeach")>1 and self:getCardsNum("DragonPeach,Jink")>q(self.player,"getMaxCards")
        then use.card = card use.to:append(self.player) end
        return
    end
    self.friends = self:sort(self.friends,"hp")
    if #self.friends>0 and AIValue.sameLegacyIdentity(self.friends[1],self.player)
    or q(self.player,"getHp")<2 then use.card = card return end
    if #self.friends>1 and (not hasBuquEffect(self.friends[2]) and q(self.friends[2],"getHp")<3 and of<2
    or not hasBuquEffect(self.friends[1]) and q(self.friends[1],"getHp")<2 and self:getCardsNum("DragonPeach","h")<=1 and of<3)
    then return end
    use.card = card
    use.to:append(self.player)
end

sgs.ai_card_intention.DragonPeach = function(self,card,from,tos)
    return known(sgs.ai_card_intention.Peach,"Peach intention dependency")(self,card,from,tos)
end

sgs.ai_use_value.DragonPeach = 6
sgs.ai_keep_value.DragonPeach = 7
sgs.ai_use_priority.DragonPeach = 0.9

function SmartAIView:useCardDragonCollateral(card,use)
    local fromList = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    local cmps = {}
    for _,p in ipairs(fromList)do
        cmps[p:objectName()] = self:objectiveLevel(p)
    end
    local cmp = function(a,b)
        local al = cmps[a:objectName()]
        local bl = cmps[b:objectName()]
        if al~=bl then return al>bl end
        return q(a,"getHandcardNum")<q(b,"getHandcardNum")
    end
    table.sort(fromList,cmp)
    local function useToCard(to)
        return to:getWeapon()
        and not(use.to:contains(to) or current_target(use,to)
        or q(self.player,"isProhibited",to,card))
    end
    local extraTarget = q(card,"getTargetModExtra",self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end

    if not self:hasCrossbowEffect() and self:getCardsNum("Slash")>2 then
        for _,from in ipairs(sgs.reverse(fromList))do
            if q(from,"hasWeapon","Crossbow")
            and useToCard(from) then
                use.card = card
                use.to:append(from)
                if use.to:length()>extraTarget
                then return end
            end
        end
    end

    for _,enemy in ipairs(fromList)do
        if useToCard(enemy) and self:objectiveLevel(enemy)>=0
        and not(self:loseEquipEffect(enemy) or q(enemy,"hasSkill","tuntian+zaoxian")) then
            use.card = card
            use.to:append(enemy)
            if use.to:length()>extraTarget
            then return end
        end
    end
    for _,friend in ipairs(fromList)do
        if useToCard(friend) and self:objectiveLevel(friend)<0 then
            use.card = card
            use.to:append(friend)
            if use.to:length()>extraTarget
            then return end
        end
    end
    for _,friend in ipairs(fromList)do
        if useToCard(friend) and self:objectiveLevel(friend)<0
        and self:loseEquipEffect(friend) then
            use.card = card
            use.to:append(friend)
            if use.to:length()>extraTarget
            then return end
        end
    end
end



sgs.ai_use_value.DragonCollateral = 5.8
sgs.ai_use_priority.DragonCollateral = 2.75
sgs.ai_keep_value.DragonCollateral = 3.40

sgs.dynamic_value.control_card.DragonCollateral = true

sgs.ai_judgestring.Dragon_indulgence = ".|heart"
sgs.ai_nullification.Dragon_indulgence = sgs.ai_nullification.indulgence
ai_card_use.DragonPeach=function(self,card,use)return self:useCardDragonPeach(card,use)end
ai_card_use.DragonCollateral=function(self,card,use)return self:useCardDragonCollateral(card,use)end
