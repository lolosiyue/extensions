-- MRmou fixed b6025acc effective policies. Native scopes and disclosed DTOs only.
local function known(v,key)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("MRmou missing "..key,"MRmou")end;return v end
local function q(o,m,...)
 if AIValue.isPlayer(o)then if m=="getMark"then m="getStrategyMark"elseif m=="hasFlag"then m="getStrategyFlag"end end
 if not o or type(o[m])~="function"then ai_unsupported("MRmou unavailable method "..m,"MRmou")end
 return known(o[m](o,...),m)
end
local function skill_suit_table(self,name)
 if type(self.getSourceSuitValueTable)~="function"then ai_unsupported("Fixed source suit catalog unavailable",name)end
 local value,present=self:getSourceSuitValueTable(name)
 if present~=true or value~=nil and type(value)~="table"then ai_unsupported("Invalid fixed source suit catalog result",name)end
 return value
end
local function dummy()return AIUsePlan.new({isDummy=true})end
-- jilve_wansha is the viewer's own JilveWansha tag read through toBool(); whether the
-- engine registers olwansha (has_olwansha_definition) is not projected.
local function fact(self,group,key)
 if group=="standard"and key=="jilve_wansha"then return self.player:getTag("JilveWansha")==true end
 ai_unsupported("engine skill registry is not projected",group..":"..key)
end
local function scope(self,key)local row=q(self,"getDecisionContext").MRmou;if type(row)~="table"then ai_unsupported("MRmou scoped data missing",key)end;return known(row[key],key)end
local function scoped_player(self,key)local name=scope(self,key);if name==false or name==""then return nil end;return q(self.room,"findPlayerByObjectName",name)end
local function scoped_use(self,key)
 local row=scope(self,key);if row==false then return{to=AIList.new({})}end
 local use={};for k,v in pairs(row)do use[k]=v end
 use.to=AIList.new({});for _,name in ipairs(known(row.to,key..".to"))do use.to:append(q(self.room,"findPlayerByObjectName",name))end
 if row.from and row.from~=""then use.from=q(self.room,"findPlayerByObjectName",row.from)end
 if type(row.card)=="table"then use.card=CardView.new(row.card);use.card._evaluation_candidate=row.card.evaluation_candidate end
 return use
end
local function engine_card(self,id)local rows=scope(self,"gongxin_engine_cards");return CardView.new(known(rows[tostring(id)],"disclosed original engine face"))end
local function set_gongxin(self,value)self:setStrategyMemory("MRmou.gongxin_choice",value)end
local function set_jilve(self,value)
 self:setStrategyMemory("MRmou.jilve_choice",value)
 self:useKnowledgeEstimate({status="estimate",value=value,basis="MRmou.jilve_choice_viewer_partition"},"MR_jilve")
end
local function viable_costs(self,ids)
 if not ids or #ids<1 then return false end
 local hp=q(self.player,"getHp")
 for _,id in ipairs(ids)do local c=q(self,"getKnownCardById",id);if q(c,"isKindOf","Poison")or q(c,"isKindOf","Shit")then hp=hp-1 end end
 return not(hp<1 and hp+q(self,"getAllPeachNum")<1)
end
local function mobile_costs(self)
    local unpreferedCards = {}
    local cards = sgs.QList2Table(self.player:getHandcards())
    if q(self.player,"getHp")<3 then
        local zcards = self.player:getCards("he")
        local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
        local keep_slash = fact(self,"standard","jilve_wansha")
        for _,zcard in sgs.qlist(zcards)do
            if not isCard("Peach",zcard,self.player) and not isCard("ExNihilo",zcard,self.player) then
                local shouldUse = true
                if isCard("Slash",zcard,self.player) and not use_slash then
                    local dummy_use = dummy()
                    self:useBasicCard(zcard,dummy_use)
                    if dummy_use.card then
                        if keep_slash then shouldUse = false end
                        if dummy_use.to then
                            for _,p in sgs.qlist(dummy_use.to)do
                                if q(p,"getHp")<=1 then
                                    shouldUse = false
                                    if q(self.player,"distanceTo",p)>1 then keep_weapon = self.player:getWeapon() end
                                    break
                                end
                            end
                            if dummy_use.to:length()>1 then shouldUse = false end
                        end
                        if not q(self,"isWeak") then shouldUse = false end
                        if not shouldUse then use_slash = true end
                    end
                end
                if q(zcard,"getTypeId")==sgs.Card_TypeTrick then
                    local dummy_use = dummy()
                    self:useTrickCard(zcard,dummy_use)
                    if dummy_use.card then shouldUse = false end
                end
                if q(zcard,"getTypeId")==sgs.Card_TypeEquip and not q(self.player,"hasEquip",zcard) then
                    local dummy_use = dummy()
                    self:useEquipCard(zcard,dummy_use)
                    if dummy_use.card then shouldUse = false end
                    if keep_weapon and q(zcard,"getEffectiveId")==q(keep_weapon,"getEffectiveId") then shouldUse = false end
                end
                if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","Armor") and not q(self,"needToThrowArmor") then shouldUse = false end
                if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","DefensiveHorse") and not q(self,"needToThrowArmor") then shouldUse = false end
                if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then shouldUse = false end
                if isCard("Jink",zcard,self.player) and not keep_jink then
                    keep_jink = true
                    shouldUse = false
                end
                if q(self.player,"getHp")==1 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
                    keep_analeptic = true
                    shouldUse = false
                end
                if shouldUse then table.insert(unpreferedCards,q(zcard,"getId")) end
            end
        end
    end

    if #unpreferedCards==0 then
        local use_slash_num = 0
        self:sortByKeepValue(cards)
        for _,card in ipairs(cards)do
            if q(card,"isKindOf","Slash") then
                local will_use = false
                if use_slash_num<=q(card,"getTargetResidue") then
                    local dummy_use = dummy()
                    self:useBasicCard(card,dummy_use)
                    if dummy_use.card then
                        will_use = true
                        use_slash_num = use_slash_num+1
                    end
                end
                if not will_use then table.insert(unpreferedCards,q(card,"getId")) end
            end
        end

        local num = q(self,"getCardsNum","Jink")-1
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
            if (q(card,"isKindOf","Weapon") and q(self.player,"getHandcardNum")<3) or q(card,"isKindOf","OffensiveHorse")
                or self:getSameEquip(card,self.player) or q(card,"isKindOf","AmazingGrace") then
                table.insert(unpreferedCards,q(card,"getId"))
            elseif q(card,"getTypeId")==sgs.Card_TypeTrick then
                local dummy_use = dummy()
                self:useTrickCard(card,dummy_use)
                if not dummy_use.card then table.insert(unpreferedCards,q(card,"getId")) end
            end
        end

        if self.player:getWeapon() and q(self.player,"getHandcardNum")<3 then
            table.insert(unpreferedCards,self.player:getWeapon():getId())
        end

        if q(self,"needToThrowArmor") then
            table.insert(unpreferedCards,self.player:getArmor():getId())
        end

        if self.player:getOffensiveHorse() and self.player:getWeapon() then
            table.insert(unpreferedCards,self.player:getOffensiveHorse():getId())
        end
    end

    for index = #unpreferedCards,1,-1 do
        if q(self,"getKnownCardById",unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then
            table.removeOne(unpreferedCards,unpreferedCards[index])
        end
    end

    local use_cards = {}
    for index = #unpreferedCards,1,-1 do
        if not q(self.player,"isJilei",q(self,"getKnownCardById",unpreferedCards[index])) then table.insert(use_cards,unpreferedCards[index]) end
    end

    if #use_cards>0 then
        return use_cards
    end
end

sgs.ai_fill_skill.MR_huishi = function(self,inclusive,request)
    if not q(self,"isWeak") then return end
    return q(self,"bindSkillCard","MR_huishi",{},request,nil,"#MR_huishi")
end

sgs.ai_skill_use_func["#MR_huishi"] = function(card,use,self,request)
    self:sort(self.friends,"handcard")
    for _,target in sgs.list(self.friends)do
        if q(self,"isFriend",target) and q(self,"canDraw",target, self.player)
        then
            use.card = card
            use.to:append(target)
            return
        end
    end
end

sgs.ai_use_value["MR_huishi"] = 8.4
sgs.ai_use_priority["MR_huishi"] = 8.4


sgs.ai_need_damaged.MR_yiji = function (self,attacker,player)
    if not q(player,"hasSkill","MR_yiji") then return end

    local friends = {}
    for _,ap in sgs.list(self.room:getAlivePlayers())do
        if q(self,"isFriend",ap,player) then
            table.insert(friends,ap)
        end
    end
    self:sort(friends,"hp")

    if #friends>0 and friends[1]:objectName()==q(player,"objectName") and q(self,"isWeak",player) and getCardsNum("Peach",player,(attacker or self.player))==0 then return false end

    return q(player,"getHp")>2 and q(self.room,"getTurnCount")>2 and #friends>1 and not q(self,"isWeak",player) and q(player,"getHandcardNum")>=2
end

sgs.ai_can_damagehp.MR_yiji = function(self,from,card,to)
    return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
    and q(self,"canLoseHp",from,card,to)
end
sgs.ai_skill_use["@@MR_yiji"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local targets = sgs.SPlayerList()
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        targets:append(p)
    end
    if targets:length() == 0 then return "." end
    local c,to = self:getCardNeedPlayer(cards, false, targets)
    if c and to then return "#MR_yiji:"..q(c,"getEffectiveId")..":->"..q(to,"objectName") end
    return "."
end


sgs.ai_skill_use["@mobilemouzhiheng"]=function(self,prompt)
    local costs=mobile_costs(self)
    if viable_costs(self,costs)then return "@MobileMouZhihengCard="..table.concat(costs,"+").."->."end
    return "."
end
sgs.ai_fill_skill.MR_jilve = function(self,inclusive,request)
    if not(q(self.player,"hasFlag","MR_jilveWansha") or q(self.player,"hasSkills","wansha|olwansha"))
    then
        for _,enemy in sgs.list(self.enemies)do
            if q(self.player,"canSlash",enemy) and q(self,"isWeak",enemy)
            and q(self,"damageMinusHp",enemy,1)>0 and #self.enemies>1
            then
                self:setPriorityValue("MR_jilve",8,"MR_jilve")
                set_jilve(self,fact(self,"MRmou","has_olwansha_definition") and "MR_jilve_olwansha" or "wansha")
                return q(self,"bindSkillCard","MR_jilve",{},request,nil,"#MR_jilve")
            end
        end
    end
    if not q(self.player,"hasFlag","MR_jilveZhiheng")
    then
        set_jilve(self,"zhiheng")
        self:setPriorityValue("MR_jilve",q(self,"getPriorityValue","TenyearZhihengCard"),"MR_jilve")
        local costs = self:selectZhihengCosts()
        if viable_costs(self,costs)then return q(self,"bindSkillCard","MR_jilve",{},request,nil,"#MR_jilve") end
    end
end

sgs.ai_skill_use_func["#MR_jilve"]=function(card,use,self,request)
    use.card = card
end


sgs.ai_fill_skill.MR_lianhuan = function(self,inclusive,request)
    local cards = self:addHandPile()
    self:sortByUseValue(cards,true)
    local card
    local slash = self:getCard("FireSlash") or self:getCard("ThunderSlash") or self:getCard("Slash")
    if slash then
        local dummy_use = dummy()
        self:useBasicCard(slash,dummy_use)
        if not dummy_use.card then slash = nil end
    end

    for _,acard in sgs.list(cards)do
        if not q(acard,"isKindOf","BasicCard") then
            local shouldUse = true
            if q(self,"getUseValue",acard)>sgs.ai_use_value.IronChain and q(acard,"getTypeId")==sgs.Card_TypeTrick then
                local dummy_use = dummy()
                self:useTrickCard(acard,dummy_use)
                if dummy_use.card then shouldUse = false end
            end
            if q(acard,"getTypeId")==sgs.Card_TypeEquip then
                local dummy_use = dummy()
                self:useEquipCard(acard,dummy_use)
                if dummy_use.card then shouldUse = false end
            end
            if shouldUse and (not slash or q(slash,"getEffectiveId")~=q(acard,"getEffectiveId")) then
                card = acard
                break
            end
        end
    end

    if not card then return nil end
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    local card_str = ("iron_chain:MR_lianhuan[club:%s]=%d"):format(number,card_id)
    local skillcard = q(self,"bindTurnConversion","MR_lianhuan","IronChain",{name="iron_chain",skill_name="MR_lianhuan",suit=sgs.Card_Club,number=q(card,"getNumber"),subcards={card_id}},request)
    assert(skillcard)
    return skillcard
end

sgs.ai_skill_use["@@MR_niepan"] = function(self, prompt)
    local peaches = 1-q(self.player,"getHp")
    if q(self,"getCardsNum","Peach")+q(self,"getCardsNum","Analeptic")<peaches then
        return "#MR_niepan:.:"
    end
    return "."
end

sgs.ai_canNiepan_skill.MR_niepan = function(player)
    return q(player,"getMark","MR_niepan") < 1
end

sgs.ai_ajustdamage_from["&MR_luofeng"] = function(self,from,to,card,nature)
    if card and (q(card,"isKindOf","SkillCard") or (q(card,"isVirtualCard") and q(card,"subcardsLength") > 0))
    then return 1 end
end




sgs.ai_fill_skill.MR_xuanhuo = function(self,inclusive,request)
    if q(self,"isWeak") or q(self.player,"isKongcheng") then return end
    if q(self.player,"usedTimes","#MR_xuanhuo") >= 1 then return end
    return q(self,"legacySkillSeed","MR_xuanhuo","#MR_xuanhuo",request)
end

sgs.ai_skill_use_func["#MR_xuanhuo"] = function(card,use,self,request)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
    use.card = q(self,"bindSkillCard","MR_xuanhuo",{cards[1]:getEffectiveId()},request,nil,"#MR_xuanhuo")
    return
end

sgs.ai_use_value.MR_xuanhuo = 4.4
sgs.ai_use_priority.MR_xuanhuo = 5.2

sgs.ai_need_damaged.MR_enyuan = function (self,attacker,player)
    if not q(player,"hasSkill","MR_enyuan") then return false end
    if not attacker then return end
    if q(self,"isEnemy",attacker,player) and q(self,"isWeak",attacker) and q(attacker,"getHandcardNum")<3
      and not self:hasSkills("lianying|noslianying|shangshi|nosshangshi",attacker)
      and not (q(attacker,"hasSkill","kongcheng") and q(attacker,"getHandcardNum")>0)
      and not q(attacker,"hasSkills",sgs.masochism_skill) then
        return not q(self,"isWeak",player)
    end
end



sgs.ai_fill_skill.MR_fanjian = function(self,inclusive,request)
    if q(self.player,"isKongcheng") then return nil end
    return q(self,"legacySkillSeed","MR_fanjian","#MR_fanjian",request)
end

sgs.ai_skill_use_func["#MR_fanjian"]= function(card,use,self,request)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards,true)
    self:sort(self.enemies,"defense")

    if q(self,"getCardsNum","Slash")>0 then
        local slash = self:getCard("Slash")
        local dummy_use = dummy()
        self:useCardSlash(slash,dummy_use)
        if dummy_use.card and dummy_use.to:length()>0 then
            self:setPriorityValue("MR_fanjian",q(self,"getPriorityValue","Slash")+0.15,"MR_fanjian")
            local target = dummy_use.to:first()
            if q(self,"isEnemy",target) and getCardsNum("Jink",target,self.player)>=1 and q(target,"getMark","yijue")==0
                and not q(target,"isKongcheng") and (q(self,"getOverflow")>0 or q(target,"getHandcardNum")>2)
                and not (q(self.player,"hasSkill","liegong") and (q(target,"getHandcardNum")>=q(self.player,"getHp") or q(target,"getHandcardNum")<=q(self.player,"getAttackRange")))
                and not (q(self.player,"hasSkill","kofliegong") and q(target,"getHandcardNum")>=q(self.player,"getHp")) then
                if q(target,"hasSkill","qingguo") then
                    for _,card in ipairs(cards)do
                        if q(self,"getUseValue",card)<6 and q(card,"isBlack") then
                            use.card = q(self,"bindSkillCard","MR_fanjian",{q(card,"getEffectiveId")},request,nil,"#MR_fanjian")
                            use.to:append(target)
                            return
                        end
                    end
                end
                for _,card in ipairs(cards)do
                    if q(self,"getUseValue",card)<6 and q(card,"getSuit")==sgs.Card_Diamond then
                        use.card = q(self,"bindSkillCard","MR_fanjian",{q(card,"getEffectiveId")},request,nil,"#MR_fanjian")
                        use.to:append(target)
                        return
                    end
                end
            end
        end
    end

    if q(self,"getOverflow")<=0 then return end
    self:setPriorityValue("MR_fanjian",0.2,"MR_fanjian")
    local suit_table = { "spade","club","heart","diamond" }
    local equip_val_table = { 1.2,1.5,0.5,1,1.3 }
    for _,enemy in ipairs(self.enemies)do
        if q(enemy,"getHandcardNum")>2 then
            local max_suit_num,max_suit = 0,{}
            for i = 0,3,1 do
                local suit_num = getKnownCard(enemy,self.player,suit_table[i+1])
                for j = 0,4,1 do
                    if enemy:getEquip(j) and enemy:getEquip(j):getSuit()==i then
                        local val = equip_val_table[j+1]
                        if j==1 and q(self,"needToThrowArmor",enemy) then val = -0.5
                        else
                            if q(enemy,"hasSkills",sgs.lose_equip_skill) then val = val/8 end
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
                    if skill_suit_table(self,q(skill,"objectName")) then
                        for i = 1,4,1 do
                            local v = skill_suit_table(self,q(skill,"objectName"))[suit_table[i]]
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
                if q(self,"getUseValue",card)<6 and table.contains(max_suit,q(card,"getSuit")) then
                    use.card = q(self,"bindSkillCard","MR_fanjian",{q(card,"getEffectiveId")},request,nil,"#MR_fanjian")
                    use.to:append(enemy)
                    return
                end
            end
            if getCardsNum("Peach",enemy,self.player)<2 then
                for _,card in ipairs(cards)do
                    if q(self,"getUseValue",card)<6 and not q(self,"isValuableCard",card) then
                        use.card = q(self,"bindSkillCard","MR_fanjian",{q(card,"getEffectiveId")},request,nil,"#MR_fanjian")
                        use.to:append(enemy)
                        return
                    end
                end
            end
        end
    end
    for _,friend in ipairs(self.friends_noself)do
        if q(friend,"hasSkill","hongyan") then
            for _,card in ipairs(cards)do
                if q(self,"getUseValue",card)<6 and q(card,"getSuit")==sgs.Card_Spade then
                    use.card = q(self,"bindSkillCard","MR_fanjian",{q(card,"getEffectiveId")},request,nil,"#MR_fanjian")
                    use.to:append(friend)
                    return
                end
            end
        end
        if hasZhaxiangEffect(friend) and not q(self,"isWeak",friend) and not (q(friend,"getHp")==2 and q(friend,"hasSkill","chanyuan")) then
            for _,card in ipairs(cards)do
                if q(self,"getUseValue",card)<6 then
                    use.card = q(self,"bindSkillCard","MR_fanjian",{q(card,"getEffectiveId")},request,nil,"#MR_fanjian")
                    use.to:append(friend)
                    return
                end
            end
        end
    end
end

sgs.ai_use_priority["MR_fanjian"] = 0.2

sgs.ai_skill_invoke.MR_haoshi = function(self,data)
    local num = self.room:getOtherPlayers(self.player):first():getHandcardNum()
    for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
        num = math.min(num,q(p,"getHandcardNum"))
    end

    local crossbow = false
    for _,c in sgs.qlist(self.player:getCards("h"))do
        if q(c,"isKindOf","Crossbow") and self.player:canUse(c) then
            crossbow = true
            break
        end
    end

    local use,slash,analeptic = 0,false,0
    for _,c in sgs.qlist(self.player:getCards("h"))do
        if not q(self,"willUse",self.player,c) then continue end
        if q(c,"isKindOf","Slash") and not slash then
            slash = true
            use = use+1
        elseif q(c,"isKindOf","Slash") and slash then
            if q(self.player,"canSlashWithoutCrossbow") or q(self.player,"hasWeapon","crossbow") or crossbow then
                use = use+1
            end
        elseif q(c,"isKindOf","Analeptic") then
            analeptic = analeptic+1
            if analeptic<=1+q(c,"getTargetResidue",self.player) then
                use = use+1
            end
        else
            use = use+1
        end
    end
    return q(self.player,"getHandcardNum")+2-use<=num
end

sgs.ai_skill_playerchosen.MR_haoshi = function(self,targets)
    local selfhand,targethand = q(self.player,"getHandcardNum"),targets:first():getHandcardNum()
    targets = sgs.QList2Table(targets)
    self:sort(targets,"defense")
    for _,p in ipairs(targets)do
        if not q(self,"isFriend",p) then continue end
        if q(self,"doDisCard",p,"h") then
            return p
        end
    end
    for _,p in ipairs(targets)do
        if not q(self,"isFriend",p) then continue end
        return p
    end
    for _,p in ipairs(targets)do
        if not q(self,"isEnemy",p) and q(self,"doDisCard",p,"h") then
            return p
        end
    end
    for _,p in ipairs(targets)do
        if not q(self,"isEnemy",p) then
            return p
        end
    end
    return targets[math.random(1,#targets)]
end




sgs.ai_skill_playerchosen.MR_jieming = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    local function func(a,b)
        return q(a,"getMaxHp")-q(a,"getHandcardNum")>q(b,"getMaxHp")-q(b,"getHandcardNum")
    end
    table.sort(destlist,func)
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        and q(target,"getHandcardNum")<5
        and q(target,"getHandcardNum")<q(target,"getMaxHp")
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        and q(target,"getHandcardNum")<6
        and q(target,"getHandcardNum")<=q(target,"getMaxHp")
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target)
        and q(target,"getHandcardNum")>q(target,"getMaxHp")*(math.random()+1)
        then return target end
    end
end

sgs.ai_can_damagehp.MR_jieming = function(self,from,card,to)
    if q(self,"isFriend",to)
    and q(self,"canLoseHp",from,card,to)
    and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
    then
        for _,fp in sgs.list(self.friends)do
            if q(fp,"getHandcardNum")<5
            and q(fp,"getHandcardNum")<q(fp,"getMaxHp")
            then return true end
        end
    end
end

sgs.ai_fill_skill.MR_quhu = function(self,inclusive,request)
    return q(self,"legacySkillSeed","MR_quhu","#MR_quhu",request)
end

sgs.ai_skill_use_func["#MR_quhu"] = function(card,use,self,request)
    if #self.enemies==0 then return end
    self:sort(self.enemies,"handcard")

    for _,enemy in sgs.list(self.enemies)do
        if q(self.player,"canPindian",enemy) then
            local enemy_max_card = self:getMaxCard(enemy)
            local allknown = 0
            if q(self,"getKnownNum",enemy)==q(enemy,"getHandcardNum") then
                allknown = allknown+1
            end
            for _,enemy2 in sgs.list(self.enemies)do
                if (q(enemy,"objectName")~=q(enemy2,"objectName"))
                    and q(enemy,"canPindian",enemy2) then
                    use.card = q(self,"bindSkillCard","MR_quhu",{},request,nil,"#MR_quhu")
                    use.to:append(enemy)
                    use.to:append(enemy2)
                    return
                end
            end
        end
    end
end

sgs.ai_choicemade_filter.cardUsed["MR_quhu"] = function(self,player,carduse)
    self:setEventMemory("ai_quhu_effect",true)
end

sgs.ai_skill_invoke.MR_zhian = function(self,data)
    local target = data:toCardUse().to:first()
    if target
    then
        return not q(self,"isFriend",target)
    end
end
sgs.ai_skill_discard["MR_lingfa"] = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    if #cards == 0 then return {} end
    self:sortByKeepValue(cards)
    local use = scoped_use(self,"lingfa_use")
    for _, p in sgs.qlist(use.to) do
        if p and q(self,"isFriend",p) and q(p,"hasSkill","MR_lingfa") then
            return {}
        end
    end
    local to_discard = {}
    for _, c in ipairs(cards) do
        if #to_discard < discard_num then
            table.insert(to_discard, q(c,"getEffectiveId"))
        end
    end
    if #to_discard == discard_num then
        return to_discard
    end
    return {}
end

sgs.ai_skill_choice.MR_zhian = function(self,choices,data)
    local use = data:toCardUse()
    local items = choices:split("+")
    if q(self,"isEnemy",use.from)
    then
        if q(self,"isWeak",use.from)
        then return items[#items]
        elseif q(use.card,"isKindOf","DelayedTrick")
        and q(self,"isFriend",use.to:at(0))
        and q(self.player,"getHandcardNum")>2
        then return items[2]
        elseif q(use.card,"isKindOf","EquipCard")
        and q(self.player,"getHandcardNum")>2
        then return items[2] end
    elseif not q(self,"isFriend",use.from)
    and q(use.card,"isKindOf","DelayedTrick")
    and q(self,"isFriend",use.to:at(0))
    then return items[2] end
    return items[1]
end



sgs.ai_fill_skill.MR_gongxin = function(self,inclusive,request)
    return q(self,"bindSkillCard","MR_gongxin",{},request,nil,"#MR_gongxin")
end

sgs.ai_skill_use_func["#MR_gongxin"]=function(card,use,self,request)
    self:sort(self.enemies,"handcard")
    self.enemies = sgs.reverse(self.enemies)

    for _,enemy in sgs.list(self.enemies)do
        if not q(enemy,"isKongcheng") and q(self,"objectiveLevel",enemy)>0
            and (q(self,"hasSuit","spade",false,enemy) or q(self,"hasSuit","diamond",false,enemy) or q(self,"hasSuit","heart",false,enemy) or q(self,"getKnownNum",enemy)~=q(enemy,"getHandcardNum")) then
            use.card = card
            use.to:append(enemy)
            return
        end
    end
end

sgs.ai_skill_askforag.MR_gongxin = function(self,card_ids)
    set_gongxin(self,false)
    local target = scoped_player(self,"gongxin_target")
    if not target or q(self,"isFriend",target) then return -1 end
    local nextAlive = self.player
    repeat
        nextAlive = nextAlive:getNextAlive()
    until q(nextAlive,"faceUp")

    local peach,ex_nihilo,jink,nullification,slash
    local valuable
    for _,id in sgs.list(card_ids)do
        local card = q(self,"getChoiceCard",id)
        if q(card,"isKindOf","Peach") then peach = id end
        if q(card,"isKindOf","ExNihilo") then ex_nihilo = id end
        if q(card,"isKindOf","Jink") then jink = id end
        if q(card,"isKindOf","Nullification") then nullification = id end
        if q(card,"isKindOf","Slash") then slash = id end
    end
    valuable = peach or ex_nihilo or jink or nullification or slash or card_ids[1]
    local card = q(self,"getChoiceCard",valuable)
    if q(self,"isEnemy",target) then
        set_gongxin(self,"obtain")
        return valuable
    end

    local willUseExNihilo,willRecast
    if q(self,"getCardsNum","ExNihilo")>0 then
        local ex_nihilo = self:getCard("ExNihilo")
        if ex_nihilo then
            local dummy_use = dummy()
            self:useTrickCard(ex_nihilo,dummy_use)
            if dummy_use.card then willUseExNihilo = true end
        end
    elseif q(self,"getCardsNum","IronChain")>0 then
        local iron_chain = self:getCard("IronChain")
        if iron_chain then
            local dummy_use = dummy()
            self:useTrickCard(iron_chain,dummy_use)
            if dummy_use.card and dummy_use.to:isEmpty() then willRecast = true end
        end
    end
    if willUseExNihilo or willRecast then
        local card = q(self,"getChoiceCard",valuable)
        if q(card,"isKindOf","Peach") then
            set_gongxin(self,"put")
            return valuable
        end
        if q(card,"isKindOf","TrickCard") or q(card,"isKindOf","Indulgence") or q(card,"isKindOf","SupplyShortage") then
            local dummy_use = dummy()
            self:evaluateAcquiredCard(card,dummy_use)
            if dummy_use.card then
                set_gongxin(self,"put")
                return valuable
            end
        end
        if q(card,"isKindOf","Jink") and q(self,"getCardsNum","Jink")==0 then
            set_gongxin(self,"put")
            return valuable
        end
        if q(card,"isKindOf","Nullification") and q(self,"getCardsNum","Nullification")==0 then
            set_gongxin(self,"put")
            return valuable
        end
        if q(card,"isKindOf","Slash") and self:slashIsAvailable() then
            local dummy_use = dummy()
            self:evaluateAcquiredCard(card,dummy_use)
            if dummy_use.card then
                set_gongxin(self,"put")
                return valuable
            end
        end
        set_gongxin(self,"discard")
        return valuable
    end

    local hasLightning,hasIndulgence,hasSupplyShortage
    local tricks = nextAlive:getJudgingArea()
    if not tricks:isEmpty() and not q(nextAlive,"containsTrick","YanxiaoCard") then
        local trick = tricks:at(tricks:length()-1)
        if q(self,"hasTrickEffective",trick,nextAlive) then
            if q(trick,"isKindOf","Lightning") then hasLightning = true
            elseif q(trick,"isKindOf","Indulgence") then hasIndulgence = true
            elseif q(trick,"isKindOf","SupplyShortage") then hasSupplyShortage = true
            end
        end
    end

    if q(self,"isEnemy",nextAlive) and q(nextAlive,"hasSkill","luoshen") and valuable then
        set_gongxin(self,"put")
        return valuable
    end
    if q(nextAlive,"hasSkill","yinghun") and q(nextAlive,"isWounded") then
        set_gongxin(self,q(self,"isFriend",nextAlive) and "put" or "discard")
        return valuable
    end
    if q(target,"hasSkill","hongyan") and hasLightning and q(self,"isEnemy",nextAlive) and not (q(nextAlive,"hasSkill","qiaobian") and q(nextAlive,"getHandcardNum")>0) then
        for _,id in sgs.list(card_ids)do
            local card = engine_card(self,id)
            if q(card,"getSuit")==sgs.Card_Spade and q(card,"getNumber")>=2 and q(card,"getNumber")<=9 then
                set_gongxin(self,"put")
                return id
            end
        end
    end
    if hasIndulgence and q(self,"isFriend",nextAlive) then
        set_gongxin(self,"put")
        return valuable
    end
    if hasSupplyShortage and q(self,"isEnemy",nextAlive) and not (q(nextAlive,"hasSkill","qiaobian") and q(nextAlive,"getHandcardNum")>0) then
        local enemy_null = 0
        for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
            if q(self,"isFriend",p) then enemy_null = enemy_null-getCardsNum("Nullification",p) end
            if q(self,"isEnemy",p) then enemy_null = enemy_null+getCardsNum("Nullification",p) end
        end
        enemy_null = enemy_null-q(self,"getCardsNum","Nullification")
        if enemy_null<0.8 then
            set_gongxin(self,"put")
            return valuable
        end
    end

    if q(self,"isFriend",nextAlive) and not q(self,"willSkipDrawPhase",nextAlive) and not q(self,"willSkipPlayPhase",nextAlive)
        and not q(nextAlive,"hasSkill","luoshen")
        and not q(nextAlive,"hasSkill","tuxi") and not (q(nextAlive,"hasSkill","qiaobian") and q(nextAlive,"getHandcardNum")>0) then
        if (peach and valuable==peach) or (ex_nihilo and valuable==ex_nihilo) then
            set_gongxin(self,"put")
            return valuable
        end
        if jink and valuable==jink and getCardsNum("Jink",nextAlive)<1 then
            set_gongxin(self,"put")
            return valuable
        end
        if nullification and valuable==nullification and getCardsNum("Nullification",nextAlive)<1 then
            set_gongxin(self,"put")
            return valuable
        end
        if slash and valuable==slash and q(self,"hasCrossbowEffect",nextAlive) then
            set_gongxin(self,"put")
            return valuable
        end
    end

    local card = q(self,"getChoiceCard",valuable)
    local keep = false
    if q(card,"isKindOf","Slash") or q(card,"isKindOf","Jink")
        or q(card,"isKindOf","EquipCard")
        or q(card,"isKindOf","Disaster") or q(card,"isKindOf","GlobalEffect") or q(card,"isKindOf","Nullification")
        or q(target,"isLocked",card) then
        keep = true
    end
    set_gongxin(self,"obtain")
    return valuable
end

sgs.ai_skill_choice.MR_gongxin = function(self,choices)
    local value,present=self:getStrategyMemory("MRmou.gongxin_choice");return value or "discard"
end

sgs.ai_use_value.MR_gongxin = 8.5
sgs.ai_use_priority.MR_gongxin = 9.5
sgs.ai_card_intention.MR_gongxin = 80


sgs.ai_skill_choice.MR_qingshi = function(self,choices,data)
    local items = choices:split("+")
    local use = data:toCardUse()
    if table.contains(items,"2")
    and q(self,"getPriorTurnUseCount")>3 then
        local good = 0
        for _, p in sgs.qlist(self.room:getAlivePlayers()) do
            if not use.to:contains(p) and q(self,"canDraw",p, self.player) then
                if q(self,"isFriend",p) then
                    good = good + 1
                else
                    good = good - 1
                end
            end
        end
        if good > 0 then
            return "2"
        end
    end
    if table.contains(items,"1") and q(use.card,"isDamageCard") then
        for _, p in sgs.qlist(use.to) do
            if q(self,"isFriend",p) or q(self,"cantDamageMore",use.from, p) then
                break
            else
                return "1"
            end
        end
    end
    for _,c in sgs.list(items)do
        if c:startsWith("3")
        then return c
        end
    end
    return items[1]
end

sgs.ai_ajustdamage_from.MR_qingshi = function(self, from, to, card, nature)
    if card and q(card,"hasFlag","mrqingshi") then
        return 1
    end
end


sgs.ai_fill_skill.MR_zhizhe = function(self,inclusive,request)
    self:updatePlayers()
    if q(self.player,"isNude") then return end

    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByUseValue(handcards, true)
    for _,c in ipairs(handcards) do
        --local poi = sgs.Sanguosha:cloneCard(c, sgs.Card_NoSuit, -1)
        if q(c,"isAvailable",self.player) and (q(c,"isKindOf","BasicCard") or q(c,"isNDTrick")) and q(self.player,"getMark",q(c,"objectName").."+MR_zhizhe-Clear") < 1 then
            local dummy_use = self:aiUseCard(c, dummy())
            if dummy_use.card and not (q(c,"canRecast") and dummy_use.to:isEmpty()) then
                return q(self,"bindSelectedMaterialConversion","MR_zhizhe",q(c,"getClassName"),{name=q(c,"objectName"),skill="MR_zhizhe",suit=sgs.Card_NoSuit,number=0,subcards={}}, {q(c,"getEffectiveId")}, request)
            end
        end
    end
end
sgs.ai_skill_choice.MR_jilve=function(self)
 local value,present=self:getStrategyMemory("MRmou.jilve_choice")
 if not present then ai_unsupported("MR_jilve global choice has no observed viewer write","MR_jilve")end
 return self:useKnowledgeEstimate({status="estimate",value=value,basis="MRmou.jilve_choice_viewer_partition"},"MR_jilve")
end
