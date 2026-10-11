-- Fixed b6025acc FeiDIY source bodies; source errors are not repaired.
local function known(v,key)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("FeiDIY missing "..key,"feiDIY")end;return v end
local function q(o,m,...)
 if AIValue.isPlayer(o)then if m=="getMark"then m="getStrategyMark"elseif m=="hasFlag"then m="getStrategyFlag"end end
 if not o or type(o[m])~="function"then ai_unsupported("FeiDIY unavailable method "..m,"feiDIY")end
 return known(o[m](o,...),m)
end
local function dummy(_,extra)
 local use=AIUsePlan.new()
 use.isDummy,use.extra_target,use.current_targets=true,extra or 0,{}
 return use
end
local function source_clone(self,source,printed,name)
 return q(self,"evaluateOwnerViewAsCard",{source_key=source,skill=printed,name=name,
  suit=sgs.Card_NoSuit,number=0,subcards={}})
end
local function scope(self,key)local rows=q(self,"getDecisionContext").feiDIY;if type(rows)~="table"then ai_unsupported("Missing FeiDIY scoped data",key)end;return known(rows[key],key)end
local function scope_player(self,key)local name=scope(self,key);if name==false or name==""then return nil end;return q(self.room,"findPlayerByObjectName",name)end
local function scope_move(self,player)
 local row=known(scope(self,"feizhaohu_moves")[q(player,"objectName")],"feizhaohu move")
 if row==false then return{}end
 return{from=row.from~=false and row.from~=""and q(self.room,"findPlayerByObjectName",known(row.from,"move.from"))or nil}
end
local function scope_use(self,key)
 local row=scope(self,key);if row==false then return{to=AIList.new({})}end
 local c=row.card and CardView.new(row.card)or nil;local use={card=c,to=AIList.new({})}
 if row.from and row.from~=""then use.from=q(self.room,"findPlayerByObjectName",row.from)end
 for _,name in ipairs(known(row.to,key..".to"))do use.to:append(q(self.room,"findPlayerByObjectName",name))end
 return use
end
local function memory(self,key)local value,present=self:getStrategyMemory("feiDIY."..key);if not present then return nil end;return value~=false and value or nil end
sgs.ai_skill_invoke.feiqianxun = function(self, data)
    local effect
    if q(self.player,"getPhase") == sgs.Player_Judge then
        effect = data:toCardEffect()
    else
        effect = data:toCardUse()
    end
    if effect.card and q(effect.card,"isKindOf","Collateral") and self.player:getWeapon() then
        local victim = scope_player(self,"collateral_victim")
        if victim
            and sgs.ai_skill_cardask["collateral-slash"](self, nil, nil, victim, effect.from) ~= "."
        then
            return false
        end
    end
    if q(self.player,"getPhase") == sgs.Player_Judge then
        if q(effect.card,"isKindOf","Lightning")
            and q(self,"isWeak")
            and q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") > 0 then
            return false
        end
        return true
    end
    local current = self.room:getCurrent()
    if current and q(self,"isFriend",current) and effect.from and q(self,"isFriend",effect.from) then return true end
    if effect.card and q(effect.card,"isKindOf","Duel") and sgs.ai_skill_cardask["duel-slash"](self, data, nil, effect.from) ~= "." then return false end
    if effect.card and q(effect.card,"isKindOf","AOE") and sgs.ai_skill_cardask.aoe(self, data, nil, effect.from, q(effect.card,"objectName")) ~= "." then return false end
    if q(self.player,"getHandcardNum") < self:getLeastHandcardNum(self.player) then return true end
    local l_lim, u_lim = math.max(2, self:getLeastHandcardNum(self.player)), math.max(5, #self.friends)
    if u_lim <= l_lim then u_lim = l_lim + 1 end
    return math.random(0, 100) >= (q(self.player,"getHandcardNum") - l_lim) / (u_lim - l_lim + 1) * 100
end


sgs.ai_fill_skill.feiqianxun = function(self,inclusive,request)
    if q(self.room,"getTurnCount") <= 1 and #self.friends_noself == 0 and not q(self,"isWeak") and q(self,"getOverflow") <= 0 then return end
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)

    local red_card
    if q(self,"needBear") then return end
    self:sortByUseValue(cards, true)

    for _, card in ipairs(cards) do
        local shouldUse = true
        if q(card,"isKindOf","Slash") then
            local dummy_use = { isDummy = true }
            if q(self,"getCardsNum","Slash") == 1 then
                self:useBasicCard(card, dummy_use)
                if dummy_use.card then shouldUse = false end
            end
        end

        if q(self,"getUseValue",card) > sgs.ai_use_value["#feiqianxuncard"] and q(card,"isKindOf","TrickCard") then
            local dummy_use = { isDummy = true }
            self:useTrickCard(card, dummy_use)
            if dummy_use.card then shouldUse = false end
        end

        if shouldUse and not q(card,"isKindOf","Peach") then
            red_card = card
            break
        end
    end
    if red_card then
        return q(self,"bindSkillCard","feiqianxun",{},request,nil,"#feiqianxuncard")
    end
end

sgs.ai_skill_use_func["#feiqianxuncard"] = function(card, use, self,request)
    use.card = card
    if use.to then use.to:append(self.player) end
    for _, player in ipairs(self.friends) do
        if use.to and q(self,"canDraw",player, self.player) and q(player,"objectName") ~= q(self.player,"objectName") then
            if use.to:length() >= q(self.player,"getHandcardNum") then
                break
            end
            use.to:append(player)
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if use.to and hasManjuanEffect(enemy) then
            if use.to:length() >= q(self.player,"getHandcardNum") then
                break
            end
            use.to:append(enemy)
        end
    end
end

sgs.ai_use_value["#feiqianxuncard"] = 3
sgs.ai_use_priority["#feiqianxuncard"] = 2.2
sgs.ai_card_intention["#feiqianxuncard"] = function(self, card, from, tos, source)
    for _, to in ipairs(tos) do
        self:updateIntention(from,to,hasManjuanEffect(to) and 50 or -50)
    end
end

sgs.ai_getLeastHandcardNum_skill.feilianying = function(self, player, least)
    if least < 1 then
        return 1
    end
end

sgs.ai_skill_invoke.feilianying = function(self, data)
    return true
end
sgs.ai_skill_use["@@feilianying"] = function(self, prompt)
    if q(self.player,"getMark","feilianying") == 1 or q(self.player,"getMark","feilianying") == 0 then
        return "#feilianyingCard:.:->" .. q(self.player,"objectName")
    end
    local to = {}

    self:sort(self.enemies, "defense")
    self:setStrategyMemory("feiDIY.feilianyingchoice","Chain")
    for _, enemy in ipairs(self.enemies) do
        if q(self,"objectiveLevel",enemy) > 2
            and not (q(enemy,"isChained") or q(self,"needToLoseHp",enemy))
            and q(self,"isGoodTarget",enemy, self.enemies)
        then
            table.insert(to, q(enemy,"objectName"))
            if #to == q(self.player,"getMark","feilianying")
            then
                self:setStrategyMemory("feiDIY.feilianyingchoice","Chain")
                break
            end
        end
    end

    if (#to > 0) and (#to < q(self.player,"getMark","feilianying")) then
        self:sort(self.friends, "defense")
        for _, friend in ipairs(self.friends) do
            if not (q(friend,"isChained")) and q(self,"needToLoseHp",friend) then
                table.insert(to, q(friend,"objectName"))
                if #to == q(self.player,"getMark","feilianying")
                then
                    break
                end
            end
        end
    end
    if #to == 0 then
        self:setStrategyMemory("feiDIY.feilianyingchoice","draw")
        self:sort(self.friends, "defense")
        table.insert(to, q(self.player,"objectName"))
        for _, friend in ipairs(self.friends_noself) do
            if q(self,"canDraw",friend, self.player) then
                if #to == q(self.player,"getMark","feilianying")
                then
                    break
                end
                table.insert(to, q(friend,"objectName"))
            end
        end
    end






















    if (#to > 0) then
        assert(string.format("#feilianyingCard:.:->%s", table.concat(to, "+")))
        return string.format("#feilianyingCard:.:->%s", table.concat(to, "+"))
    end
    return "."
end
sgs.ai_skill_choice.feilianyingCard = function(self, choices)
    if q(self.player,"getMark","feilianying") == 1 or q(self.player,"getMark","feilianying") == 0 then
        return "draw"
    end
    return memory(self,"feilianyingchoice")
end


sgs.ai_skill_playerchosen.feilianyingCard = function(self, targets)
    local fire_attack = source_clone(self,"feilianying","feilianying","fire_attack")
    local dummy_use = self:evaluateCard(fire_attack)
    if dummy_use.card then
        if not dummy_use.to:isEmpty() then
            for _, p in sgs.qlist(dummy_use.to) do
                if q(self,"isEnemy",p) then
                    return p
                end
            end
        end
    end
    for _,enemy in ipairs(self.enemies)do
        return enemy
    end
    return targets[1]
end

sgs.ai_skill_invoke.feituxi = function(self, data)
    return self:doDisCard(self.room:getCurrent(), "h", true)
end

sgs.ai_choicemade_filter.skillInvoke.feituxi = function(self, player, promptlist)
    local current = self.room:getCurrent()
    if promptlist[#promptlist] == "yes" then
        self:updateIntention(player,current,40)
    end
end

sgs.drawpeach_skill = sgs.drawpeach_skill .. "|feituxi"

sgs.ai_skill_choice.feizhaohu = function(self, targets)
    local players = sgs.QList2Table(self.room:getAllPlayers())
    local move
    -- The exact current-question writer identities replace private mark reads;
    -- iterate the original roster, retaining its last-marked-player semantics.
    local marked = scope(self,"feizhaohu_marked")
    if not AIValue.isList(marked) then ai_unsupported("Feizhaohu marked actors unknown","feiDIY") end
    local selected = {};for _,name in ipairs(marked) do
        if type(name)~="string" then ai_unsupported("Feizhaohu actor is malformed","feiDIY") end
        selected[name]=true
    end
    for _, player in ipairs(players) do
        if selected[q(player,"objectName")] then
            move = scope_move(self,player)
        end
    end
    if q(self.player,"getMark","&feizhaohu") >= 2

        and move.from
        and q(self,"isEnemy",move.from)
        and q(self,"damageIsEffective",move.from) and not q(self,"cantbeHurt",move.from) and q(self,"canDamage",move.from,self.player,nil) then
        return "lose"
    end
    return "get"
end
sgs.ai_skill_invoke.feiyinghun = function(self, data)
    if q(self,"isWeak") and q(self,"getAllPeachNum",self.player) <= 0 then return false end
    local target = self.room:getCurrent()
    local n = q(self.player,"getMaxHp") - q(self.player,"getHp")
    if target then
        if q(self,"isFriend",target) then
            self:setStrategyMemory("feiDIY.feiyinghun","draw")
            if self:hasSkills(sgs.lose_equip_skill,target) and target:getCards("e"):length()>0 then
                return n * math.random() + (q(self.player,"getMark","&feiyinghun") / 2) > 2
            end
            if hasTuntianEffect(target) and q(self,"canDraw",target, self.player) then
                return n * math.random() + (q(self.player,"getMark","&feiyinghun") / 2) > 2
            end
            if self:needToThrowArmor(target) and q(self,"canDraw",target, self.player) then
                return n * math.random() + (q(self.player,"getMark","&feiyinghun") / 2) > 2
            end
            if self:doDisCard(target, "he") and q(self,"canDraw",target, self.player) then
                return n * math.random() + (q(self.player,"getMark","&feiyinghun") / 2) > 2
            end
        elseif q(self,"isEnemy",target) then
            self:setStrategyMemory("feiDIY.feiyinghun","throw")
            if hasManjuanEffect(target) and self:doDisCard(target, "he") then
                return n * math.random() + (q(self.player,"getMark","&feiyinghun") / 2) > 2
            end
            if self:doDisCard(target, "he") then
                return n * math.random() + (q(self.player,"getMark","&feiyinghun") / 2) > 2
            end
        end
    end
    return false
end
sgs.ai_skill_choice.feiyinghun = function(self, targets)
    return memory(self,"feiyinghun")
end

sgs.ai_getBestHp_skill.feiyinghun = function(owner)
    if q(owner,"getMark","&feiyinghun") >= 1 then
        return q(owner,"getMaxHp") - 2
    end
end

sgs.ai_skill_invoke.feijiangchi = function(self, data)
    if q(self,"getCardsNum","Slash") > 3 or q(self.player,"getHandcardNum") < q(self.player,"getHp") then
        return true
    end
    return false
end
sgs.ai_skill_choice.feijiangchi = function(self, targets)
    if q(self.player,"getHandcardNum") > q(self.player,"getHp") and q(self,"getCardsNum","Slash") >= 2 then
        return "play"
    else
        return "draw"
    end
end
sgs.ai_fill_skill.feihujue = function(self,inclusive,request)
    if q(self.player,"hasUsed","#feihujueCard") then return end
    -- Source parse assertion, selected native binding below validates the descriptor.
    return q(self,"bindSkillCard","feihujue",{},request,nil,"#feihujueCard")
end
sgs.ai_skill_use_func["#feihujueCard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "handcard")
    local duel = source_clone(self,"feihujue","feihujue","duel")
    local dummy_use = self:evaluateCard(duel, dummy(true, 99))
    if dummy_use.card then
        if not dummy_use.to:isEmpty() then
            for _, p in sgs.qlist(dummy_use.to) do
                if (getKnownCard(p, self.player, "red", false)) < q(self,"getCardsNum","Slash") then
                    use.card = card
                    if use.to then
                        use.to:append(p)
                        break
                    end
                end
                return
            end
        end
    end
end
sgs.ai_use_priority.feihujueCard = 4.9
sgs.ai_use_value.feihujueCard = 5
sgs.ai_card_intention.feihujueCard = 60

sgs.ai_fill_skill.feilangduo = function(self,inclusive,request)
    if q(self.player,"hasUsed","#feilangduoCard")
        or q(self.player,"isKongcheng") then
        return
    end
    -- Source parse assertion, selected native binding below validates the descriptor.
    return q(self,"bindSkillCard","feilangduo",{},request,nil,"#feilangduoCard")
end
sgs.ai_skill_use_func["#feilangduoCard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "hp")
    local max_card = self:getMaxCard()
    local max_point = q(max_card,"getNumber")
    local duel = source_clone(self,"feilangduo","feihujue","duel")
    local dummy_use = self:evaluateCard(duel, dummy(true, 99))
    if dummy_use.card then
        if not dummy_use.to:isEmpty() then
            for _, p in sgs.qlist(dummy_use.to) do
                if q(self.player,"canPindian",p) then
                    local enemy_max_card = self:getMaxCard(p)
                    local enemy_max_point = enemy_max_card and q(enemy_max_card,"getNumber") or 100
                    if max_point > enemy_max_point then
                        use.card = card
                        if use.to then
                            use.to:append(p)
                            break
                        end
                        return
                    end
                end
            end
        end
    end
end
sgs.ai_use_priority.feilangduoCard = 5.1
sgs.ai_use_value.feilangduoCard = 5
sgs.ai_card_intention.feilangduoCard = 90
sgs.ai_skill_invoke.feibenzi = function(self, data)
    return true
end
sgs.ai_skill_invoke.feifeijiang = function(self, data)







    local target = data:toPlayer()
    if target then
        if q(self,"isFriend",target) then
            return false
        else
            return true
        end
    end
    return false
end
sgs.ai_skill_invoke.feijiedou = function(self, data)
    local use = data:toCardUse()
    for _, p in sgs.qlist(use.to) do
        if q(self,"isFriend",p) then
            return true
        end
    end
    return false
end
sgs.ai_fill_skill.feisheji = function(self,inclusive,request)
    if #self.enemies < 1 then return end
    if q(self.player,"isKongcheng") then return end
    local cards = sgs.QList2Table(self.player:getHandcards())
    local card_OK = false
    for _, acard in ipairs(cards) do
        if q(acard,"isKindOf","EquipCard") then
            card_OK = true
        end
    end
    if not card_OK then return end
    local selfSub = q(self.player,"getHp") - q(self.player,"getHandcardNum")
    local selfDef = q(self,"getDefense",self.player)

    for _, enemy in ipairs(self.enemies) do
        local def = q(self,"getDefenseSlash",enemy)
        local slash = q(self,"getEvaluationCard","slash")
        local eff = q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash)

        if q(self.player,"canSlash",enemy, slash, true) and not q(self,"slashProhibit",nil, enemy) and def < 6 and eff then
            return q(self,"legacySkillSeed","feisheji","#feishejiCard",request)
        end
    end
end

sgs.ai_skill_use_func["#feishejiCard"] = function(card, use, self,request)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local target
    local card
    for _, acard in ipairs(cards) do
        if q(acard,"isKindOf","EquipCard") then
            card = acard
        end
    end
    local selfSub = q(self.player,"getHp") - q(self.player,"getHandcardNum")
    local selfDef = q(self,"getDefense",self.player)

    for _, enemy in ipairs(self.enemies) do
        local def = q(self,"getDefenseSlash",enemy)
        local slash = q(self,"getEvaluationCard","slash")
        local eff = q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, nil)

        if q(self.player,"canSlash",enemy, slash, true) and not q(self,"slashProhibit",nil, enemy) and def < 6 and eff then
            target = enemy
            break
        end
    end
    if target and card then
        use.card = q(self,"bindSkillCard","feisheji",{q(card,"getEffectiveId")},request,nil,"#feishejiCard")
        if use.to then use.to:append(target) end
        return
    end
end

sgs.ai_use_value["#feishejiCard"]      = 9
sgs.ai_use_priority["#feishejiCard"]   = 3.2
sgs.ai_card_intention["#feishejiCard"] = 80

sgs.ai_cardsview_valuable.feisheji = function(self, class_name, player)
    local usereason = known(self.world.strategy_facts.owner_current_card_use_reason,"current use reason")
    if usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return end

    local handcards = sgs.QList2Table(self.player:getCards("he"))
    local had_card = nil
    for _, c in ipairs(handcards) do
        if q(c,"isKindOf","Slash") then
            had_card = c
        end
    end

    if class_name == "slash" and had_card then
        for _, c in ipairs(handcards) do
            if q(c,"isKindOf","EquipCard") then
                local card_str = "#feishejiCard:" ..q(c,"getEffectiveId") ..":"
                return card_str
            end
        end

    end
end

sgs.ai_skill_invoke.feixiaohu          = function(self, data)
    return true
end
sgs.ai_skill_invoke.feifenhu           = function(self, data)
    local x = self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true))
    if x > #self.friends then
        return false
    end
    return true
end
sgs.ai_skill_use["@@feifenhu"]         = function(self, prompt)
    local players = self.room:getAllPlayers()
    players = sgs.QList2Table(players)
    local to = {}
    for _, player in ipairs(players) do
        if not q(self,"isEnemy",player) then
            table.insert(to, q(player,"objectName"))
        end
    end
    assert(string.format("#feifenhuCard:.:->%s", table.concat(to, "+")))
    return string.format("#feifenhuCard:.:->%s", table.concat(to, "+"))
end
sgs.ai_card_intention.feifenhuCard     = -20
sgs.ai_skill_invoke.feidaizui          = function(self, data)
    if q(self,"getCardsNum","Jink") > 0 then
        return false
    end
    return true
end
sgs.ai_skill_playerchosen.feidaizui    = function(self, targets)
    self:updatePlayers()
    local targetlist = sgs.QList2Table(targets)
    self:sort(self.friends_noself, "handcard")
    for _, friend in ipairs(self.friends_noself) do
        if friend and q(self,"needToLoseHp",friend, nil, nil) then
            return friend
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if friend and getKnownCard(friend, self.player, "Jink") > 0 then
            return friend
        end
    end
    return targetlist[1]
end
sgs.ai_skill_choice.feidaizui          = function(self, targets)
    if q(self,"getCardsNum","Jink") > 1 then
        return "give"
    end
    return "no"
end
sgs.ai_skill_invoke.feidaizuidraw      = function(self, data)
    local least = 1000
    local f, e = 0, 0
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        least = math.min(q(p,"getHandcardNum"), least)
    end
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if q(p,"getHandcardNum") == least then
            if q(self,"isFriend",p) then
                f = f + 1
            else
                e = e + 1
            end
        end
    end
    if f >= e then
        return true
    end
    return false
end
sgs.ai_can_damagehp.feidaizui          = function(self, from, card, to)
    local least = 1000
    local f, e = 0, 0
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        least = math.min(q(p,"getHandcardNum"), least)
    end
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if q(p,"getHandcardNum") == least then
            if q(self,"isFriend",p) then
                f = f + 1
            else
                e = e + 1
            end
        end
    end
    return q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0
        and q(self,"canLoseHp",from, card, to) and f >= e
end

sgs.ai_skill_choice.feitouhuo = function(self,choices,data)
    for _,friend in ipairs(self.friends)do
        if q(friend,"hasSkill","tianxiang") and (q(self.player,"getHp")>=3 or (q(self,"getCardsNum","Peach")+q(self,"getCardsNum","Analeptic")>0 and q(self.player,"getHp")>1)) then
            return "hp"
        end
    end
    if q(self.player,"getMaxHp")>=q(self.player,"getHp")+2 then
        if q(self.player,"getMaxHp")>5 and (q(self.player,"hasSkills","nosmiji|yinghun|juejing|zaiqi|nosshangshi") or q(self.player,"hasSkill","miji") and self:findPlayerToDraw(false)) then
            return "hp"
        end
        return "maxhp"
    else
        return "hp"
    end
end

sgs.ai_fill_skill.feizuijiao = function(self,inclusive,request)
    if q(self.player,"hasUsed","#feizuijiaoCard") then
        return
    end
    -- Source parse assertion, selected native binding below validates the descriptor.
    return q(self,"bindSkillCard","feizuijiao",{},request,nil,"#feizuijiaoCard")
end
sgs.ai_skill_use_func["#feizuijiaoCard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "hp")
    for _,enemy in ipairs(self.enemies)do
        if q(self,"canAttack",enemy,self.player)
                and not q(self,"canLiuli",enemy,self.friends_noself) and not self:findLeijiTarget(enemy,50,self.player) then
                use.card = card
            if use.to then
                use.to:append(enemy)
            end
            return
        end
    end
    for _, to in ipairs(self.enemies) do
        if to then
            use.card = card
            if use.to then
                use.to:append(to)
            end
            return
        end
    end
end
sgs.ai_skill_invoke.feizuijiao = function(self, data)
    if self.player:isWeak() then
        return true
    end
    if not q(self.player,"faceUp") then
        return true
    end
    if math.random() < 0.4 then
        return true
    end
    if q(self,"getCardsNum","Slash") > 2 then
        return true
    end
    return false
end
sgs.ai_use_priority.feizuijiaoCard = 4.4
sgs.ai_use_value.feizuijiaoCard = 4.5
sgs.ai_card_intention.feizuijiaoCard = 20
sgs.ai_skill_choice.feizuijiaoCard = function(self,choices,data)
    local items = choices:split("+")
    return items[math.random(1, #items)]
end
sgs.ai_skill_invoke.feihuchen = function(self, data)
    local move = data:toMoveOneTime()
    if q(self,"isFriend",move.to) then
        return true
    end
    return false
end

sgs.ai_fill_skill.feiwusheng = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    local card = nil
    for _, c in ipairs(cards) do
        if not q(c,"isKindOf","Slash") and not q(c,"isKindOf","Peach")
            and ((q(self,"getUseValue",c) < sgs.ai_use_value.Slash) or nil) then
            card = c
            break
        end
    end
    if not card then return nil end
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    local card_str = ("slash:feiwusheng[%s:%s]=%d"):format(suit, number, card_id)
    local slash = q(self,"bindTurnConversion","feiwusheng","Slash",{name="slash",skill_name="feiwusheng",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={card_id}},request)
    assert(slash)
    return slash
end
sgs.ai_view_as.feiwusheng = function(card,player,card_place)
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    if card_place~=sgs.Player_PlaceSpecial and not q(card,"isKindOf","Peach") and not q(card,"hasFlag","using") then
        return ("slash:feiwusheng[%s:%s]=%d"):format(suit,number,card_id)
    end
end
sgs.ai_ajustdamage_from.feiwusheng = function(self, from, to, card, nature)
    if q(to,"getHujia") > 0 and q(to,"getHp") ~= 1
    then
        return 1
    end
end


sgs.ai_fill_skill.feiyanjun = function(self,inclusive,request)
    if q(self.player,"hasUsed","#feiyanjunCard")
        or q(self.player,"isNude") then
        return
    end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    local card_ids = {}
    for _, c in pairs(cards) do
        if not q(c,"isKindOf","BasicCard") then
            table.insert(card_ids, q(c,"getEffectiveId"))
            break
        end
    end
    if #card_ids ~= 0 then
        return q(self,"bindSkillCard","feiyanjun",card_ids,request,nil,"#feiyanjunCard")
    else
        return nil
    end
end
sgs.ai_skill_use_func["#feiyanjunCard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "hp")
    local duel = source_clone(self,"feiyanjun","feiyanjunCard","duel")
    for _, to in ipairs(self.enemies) do
        if to and not (self:hasSkills(sgs.lose_equip_skill, to) and to:hasEquip()) and not hasZhaxiangEffect(to) and q(self,"damageIsEffective",to, sgs.DamageStruct_Thunder) and not q(self,"cantbeHurt",to) and q(self,"canDamage",to,self.player,nil) and self:hasTrickEffective(duel,to) then
            use.card = card
            if use.to then
                use.to:append(to)
            end
            return
        end
    end
    for _, to in ipairs(self.enemies) do
        if to and not (self:hasSkills(sgs.lose_equip_skill, to) and to:hasEquip()) and not hasZhaxiangEffect(to) and q(self,"damageIsEffective",to, sgs.DamageStruct_Thunder) and not q(self,"cantbeHurt",to) and q(self,"canDamage",to,self.player,nil)  then
            use.card = card
            if use.to then
                use.to:append(to)
            end
            return
        end
    end
    for _, to in ipairs(self.enemies) do
        if to and q(self,"isWeak",to)  then
            use.card = card
            if use.to then
                use.to:append(to)
            end
            return
        end
    end
end
sgs.ai_use_priority.feiyanjunCard = 7.9
sgs.ai_use_value.feiyanjunCard = 6
sgs.ai_card_intention.feiyanjunCard = 100
sgs.ai_skill_choice.feiyanjunCard = function(self,choices,data)
    local items = choices:split("+")
    if self:doDisCard(self.player, "e") and table.contains(items, "loseEquip") then
        return "loseEquip"
    end
    if q(self,"needToLoseHp",self.player) and table.contains(items, "damage") then
        return "damage"
    end
    if hasZhaxiangEffect(self.player) and not q(self,"isWeak") and table.contains(items, "losehp") then
        return "losehp"
    end

    return items[math.random(1, #items)]
end

sgs.ai_skill_use["@@feifengpo"] = function(self, prompt)
    local use = scope_use(self,"feifengpo_use")
    if use.from and q(self,"isFriend",use.from) then
        return "."
    end
    if self:needToThrowArmor() and self.player:getArmor() and self.player:getArmor():isRed() then
        return "#feifengpoCard:" ..
            self.player:getArmor():getEffectiveId() .. ":"
    end
    if not q(self,"slashIsEffective",use.card, self.player, use.from)
        or (q(self,"ajustDamage",use.from, self.player, 1, use.card) < 2
            and q(self,"needToLoseHp",self.player, use.from, use.card)) then
        return "."
    end
    if q(self,"ajustDamage",use.from, self.player, 1, use.card) and q(self,"getCardsNum","Peach") > 0 then return "." end
    if q(self,"getCardsNum","Jink") == 0 or not sgs.isJinkAvailable(use.from, self.player, use.card, true) then return "." end
    local equip_index = { 3, 0, 2, 4, 1 }
    if q(self.player,"hasSkills",sgs.lose_equip_skill) then
        for _, i in ipairs(equip_index) do
            if i == 4 then break end
            if self.player:getEquip(i) and self.player:getEquip(i):isRed() then
                return "#feifengpoCard:" ..
                    self.player:getEquip(i):getEffectiveId() .. ":"
            end
        end
    end
    local jiangqin = self.room:findPlayerBySkillName("niaoxiang")
    local need_double_jink = q(use.from,"hasSkill","wushuang")
        or (q(use.from,"hasSkill","roulin") and q(self.player,"isFemale"))
        or (q(self.player,"hasSkill","roulin") and q(use.from,"isFemale"))
        or (jiangqin and q(jiangqin,"isAdjacentTo",self.player) and q(use.from,"isAdjacentTo",self.player) and q(self,"isEnemy",jiangqin))
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if not q(card,"getSuitString"):isRed() or (not q(self,"isWeak") and (q(self,"getKeepValue",card) > 8 or self:isValuableCard(card)))
            or (isCard("Jink", card, self.player) and q(self,"getCardsNum","Jink") - 1 < (need_double_jink and 2 or 1)) then
            continue
        end
        return "#feifengpoCard:" ..
            q(card,"getEffectiveId") .. ":"
    end
    for _, i in ipairs(equip_index) do
        if self.player:getEquip(i) and self.player:getEquip(i):isRed() then
            if not (i == 1 and self:evaluateArmor() > 3)
                and not (i == 4 and self.player:getTreasure():isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() >= 3) then
                return "#feifengpoCard:" ..
                    self.player:getEquip(i):getEffectiveId() .. ":"
            end
        end
    end
    return "."
end
sgs.ai_skill_invoke.feifengpo   = function(self, data)






    local target = data:toPlayer()
    if not q(self,"isFriend",target) then
        return true
    end
    return false
end
ai_audited_aliases.register{id="ai_cardneed.feifengpo",registry="ai_cardneed",path={"feifengpo"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_ajustdamage_from.feifengpo = function(self, from, to, card, nature)
    if card and (q(card,"isKindOf","Slash") or q(card,"isKindOf","Duel")) and q(card,"hasFlag","feifengpo")
    then
        return 1
    end
end

sgs.ai_skill_invoke.feiniepan   = function(self, data)
    return true
end
sgs.ai_skill_invoke.feilianhuan = function(self, data)
    local pindian = data:toPindian()
    local to
    if pindian.to == self.player then
        to = pindian.from
    else
        to = pindian.to
    end
    if to and q(self,"isEnemy",to) and not q(self,"needToLoseHp",to) then
        return true
    end
    return false
end

sgs.ai_fill_skill.feilianhuan = function(self,inclusive,request)
    if q(self.player,"isKongcheng") then return end
    -- Source parse assertion, selected native binding below validates the descriptor.
    return q(self,"bindSkillCard","feilianhuan",{},request,nil,"#feilianhuanCard")
end
sgs.ai_skill_use_func["#feilianhuanCard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "value")
    for _, to in ipairs(self.enemies) do
        if to and q(self.player,"canPindian",to) and not q(to,"isChained") and  q(self,"objectiveLevel",to)>2
            and not q(self,"needToLoseHp",to)
            and q(self,"isGoodTarget",to,self.enemies) then
            use.card = card
            if use.to then
                use.to:append(to)
            end
            return
        end
    end
    for _, to in ipairs(self.enemies) do
        if to and q(self.player,"canPindian",to) and not q(to,"isChained")  and not q(self,"needToLoseHp",to) then
            use.card = card
            if use.to then
                use.to:append(to)
            end
            return
        end
    end
end
sgs.ai_use_priority.feilianhuanCard = 3.1
sgs.ai_use_value.feilianhuanCard = 4
sgs.ai_card_intention.feilianhuanCard = 30

function sgs.ai_cardneed.feilianhuan(to,card)
    return  q(card,"getSuit") == sgs.Card_Club
end

sgs.ai_can_damagehp.feiniepan = function(self,from,card,to)
    return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
    and q(self,"canLoseHp",from,card,to) and q(to,"isKongcheng") and (q(card,"isKindOf","FireAttack") or q(card,"isKindOf","FireSlash"))
end

sgs.ai_canNiepan_skill.feiniepan = function(player)
    return q(player,"getMark","@nirvana") > 0
end
