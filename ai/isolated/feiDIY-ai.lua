-- Fixed b6025acc FeiDIY source bodies; source errors are not repaired.
local known = AIValue.requireKnown

local dummy = AIUsePlan.dummy
local function source_clone(self,source,printed,name)
 return self:evaluateOwnerViewAsCard({source_key=source,skill=printed,name=name,
  suit=sgs.Card_NoSuit,number=0,subcards={}})
end
local function scope(self,key)local rows=self:getDecisionContext().feiDIY;if type(rows)~="table"then ai_unsupported("Missing FeiDIY scoped data",key)end;return known(rows[key],key)end
local function scope_player(self,key)local name=scope(self,key);if name==false or name==""then return nil end;return self.room:findPlayerByObjectName(name)end
local function scope_move(self,player)
 local row=known(scope(self,"feizhaohu_moves")[player:objectName()],"feizhaohu move")
 if row==false then return{}end
 return{from=row.from~=false and row.from~=""and self.room:findPlayerByObjectName(known(row.from,"move.from"))or nil}
end
local function scope_use(self,key)
 local row=scope(self,key);if row==false then return{to=AIList.new({})}end
 local c=row.card and CardView.new(row.card)or nil;local use={card=c,to=AIList.new({})}
 if row.from and row.from~=""then use.from=self.room:findPlayerByObjectName(row.from)end
 for _,name in ipairs(known(row.to,key..".to"))do use.to:append(self.room:findPlayerByObjectName(name))end
 return use
end
local function memory(self,key)local value,present=self:getStrategyMemory("feiDIY."..key);if not present then return nil end;return value~=false and value or nil end
sgs.ai_skill_invoke.feiqianxun = function(self, data)
    local effect
    if self.player:getPhase() == sgs.Player_Judge then
        effect = data:toCardEffect()
    else
        effect = data:toCardUse()
    end
    if effect.card and effect.card:isKindOf("Collateral") and self.player:getWeapon() then
        local victim = scope_player(self,"collateral_victim")
        if victim
            and sgs.ai_skill_cardask["collateral-slash"](self, nil, nil, victim, effect.from) ~= "."
        then
            return false
        end
    end
    if self.player:getPhase() == sgs.Player_Judge then
        if effect.card:isKindOf("Lightning")
            and self:isWeak()
            and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then
            return false
        end
        return true
    end
    local current = self.room:getCurrent()
    if current and self:isFriend(current) and effect.from and self:isFriend(effect.from) then return true end
    if effect.card and effect.card:isKindOf("Duel") and sgs.ai_skill_cardask["duel-slash"](self, data, nil, effect.from) ~= "." then return false end
    if effect.card and effect.card:isKindOf("AOE") and sgs.ai_skill_cardask.aoe(self, data, nil, effect.from, effect.card:objectName()) ~= "." then return false end
    if self.player:getHandcardNum() < self:getLeastHandcardNum(self.player) then return true end
    local l_lim, u_lim = math.max(2, self:getLeastHandcardNum(self.player)), math.max(5, #self.friends)
    if u_lim <= l_lim then u_lim = l_lim + 1 end
    return math.random(0, 100) >= (self.player:getHandcardNum() - l_lim) / (u_lim - l_lim + 1) * 100
end


sgs.ai_fill_skill.feiqianxun = function(self,inclusive,request)
    if self.room:getTurnCount() <= 1 and #self.friends_noself == 0 and not self:isWeak() and self:getOverflow() <= 0 then return end
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)

    local red_card
    if self:needBear() then return end
    self:sortByUseValue(cards, true)

    for _, card in ipairs(cards) do
        local shouldUse = true
        if card:isKindOf("Slash") then
            local dummy_use = { isDummy = true }
            if self:getCardsNum("Slash") == 1 then
                self:useBasicCard(card, dummy_use)
                if dummy_use.card then shouldUse = false end
            end
        end

        if self:getUseValue(card) > sgs.ai_use_value["#feiqianxuncard"] and card:isKindOf("TrickCard") then
            local dummy_use = { isDummy = true }
            self:useTrickCard(card, dummy_use)
            if dummy_use.card then shouldUse = false end
        end

        if shouldUse and not card:isKindOf("Peach") then
            red_card = card
            break
        end
    end
    if red_card then
        return self:bindSkillCard("feiqianxun", {}, request, nil, "#feiqianxuncard")
    end
end

sgs.ai_skill_use_func["#feiqianxuncard"] = function(card, use, self,request)
    use.card = card
    if use.to then use.to:append(self.player) end
    for _, player in ipairs(self.friends) do
        if use.to and self:canDraw(player, self.player) and player:objectName() ~= self.player:objectName() then
            if use.to:length() >= self.player:getHandcardNum() then
                break
            end
            use.to:append(player)
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if use.to and hasManjuanEffect(enemy) then
            if use.to:length() >= self.player:getHandcardNum() then
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
    if self.player:getStrategyMark("feilianying") == 1 or self.player:getStrategyMark("feilianying") == 0 then
        return "#feilianyingCard:.:->" .. self.player:objectName()
    end
    local to = {}

    self:sort(self.enemies, "defense")
    self:setStrategyMemory("feiDIY.feilianyingchoice","Chain")
    for _, enemy in ipairs(self.enemies) do
        if self:objectiveLevel(enemy) > 2
            and not (enemy:isChained() or self:needToLoseHp(enemy))
            and self:isGoodTarget(enemy, self.enemies)
        then
            table.insert(to, enemy:objectName())
            if #to == self.player:getStrategyMark("feilianying")
            then
                self:setStrategyMemory("feiDIY.feilianyingchoice","Chain")
                break
            end
        end
    end

    if (#to > 0) and (#to < self.player:getStrategyMark("feilianying")) then
        self:sort(self.friends, "defense")
        for _, friend in ipairs(self.friends) do
            if not (friend:isChained()) and self:needToLoseHp(friend) then
                table.insert(to, friend:objectName())
                if #to == self.player:getStrategyMark("feilianying")
                then
                    break
                end
            end
        end
    end
    if #to == 0 then
        self:setStrategyMemory("feiDIY.feilianyingchoice","draw")
        self:sort(self.friends, "defense")
        table.insert(to, self.player:objectName())
        for _, friend in ipairs(self.friends_noself) do
            if self:canDraw(friend, self.player) then
                if #to == self.player:getStrategyMark("feilianying")
                then
                    break
                end
                table.insert(to, friend:objectName())
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
    if self.player:getStrategyMark("feilianying") == 1 or self.player:getStrategyMark("feilianying") == 0 then
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
                if self:isEnemy(p) then
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
        if selected[player:objectName()] then
            move = scope_move(self,player)
        end
    end
    if self.player:getStrategyMark("&feizhaohu") >= 2

        and move.from
        and self:isEnemy(move.from)
        and self:damageIsEffective(move.from) and not self:cantbeHurt(move.from) and self:canDamage(move.from, self.player, nil) then
        return "lose"
    end
    return "get"
end
sgs.ai_skill_invoke.feiyinghun = function(self, data)
    if self:isWeak() and self:getAllPeachNum(self.player) <= 0 then return false end
    local target = self.room:getCurrent()
    local n = self.player:getMaxHp() - self.player:getHp()
    if target then
        if self:isFriend(target) then
            self:setStrategyMemory("feiDIY.feiyinghun","draw")
            if self:hasSkills(sgs.lose_equip_skill,target) and target:getCards("e"):length()>0 then
                return n * math.random() + (self.player:getStrategyMark("&feiyinghun") / 2) > 2
            end
            if hasTuntianEffect(target) and self:canDraw(target, self.player) then
                return n * math.random() + (self.player:getStrategyMark("&feiyinghun") / 2) > 2
            end
            if self:needToThrowArmor(target) and self:canDraw(target, self.player) then
                return n * math.random() + (self.player:getStrategyMark("&feiyinghun") / 2) > 2
            end
            if self:doDisCard(target, "he") and self:canDraw(target, self.player) then
                return n * math.random() + (self.player:getStrategyMark("&feiyinghun") / 2) > 2
            end
        elseif self:isEnemy(target) then
            self:setStrategyMemory("feiDIY.feiyinghun","throw")
            if hasManjuanEffect(target) and self:doDisCard(target, "he") then
                return n * math.random() + (self.player:getStrategyMark("&feiyinghun") / 2) > 2
            end
            if self:doDisCard(target, "he") then
                return n * math.random() + (self.player:getStrategyMark("&feiyinghun") / 2) > 2
            end
        end
    end
    return false
end
sgs.ai_skill_choice.feiyinghun = function(self, targets)
    return memory(self,"feiyinghun")
end

sgs.ai_getBestHp_skill.feiyinghun = function(owner)
    if owner:getStrategyMark("&feiyinghun") >= 1 then
        return owner:getMaxHp() - 2
    end
end

sgs.ai_skill_invoke.feijiangchi = function(self, data)
    if self:getCardsNum("Slash") > 3 or self.player:getHandcardNum() < self.player:getHp() then
        return true
    end
    return false
end
sgs.ai_skill_choice.feijiangchi = function(self, targets)
    if self.player:getHandcardNum() > self.player:getHp() and self:getCardsNum("Slash") >= 2 then
        return "play"
    else
        return "draw"
    end
end
sgs.ai_fill_skill.feihujue = function(self,inclusive,request)
    if self.player:getStrategyHasUsed("#feihujueCard") then return end
    -- Source parse assertion, selected native binding below validates the descriptor.
    return self:bindSkillCard("feihujue", {}, request, nil, "#feihujueCard")
end
sgs.ai_skill_use_func["#feihujueCard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "handcard")
    local duel = source_clone(self,"feihujue","feihujue","duel")
    local dummy_use = self:evaluateCard(duel, dummy(true, 99))
    if dummy_use.card then
        if not dummy_use.to:isEmpty() then
            for _, p in sgs.qlist(dummy_use.to) do
                if (getKnownCard(p, self.player, "red", false)) < self:getCardsNum("Slash") then
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
    if self.player:getStrategyHasUsed("#feilangduoCard")
        or self.player:isKongcheng() then
        return
    end
    -- Source parse assertion, selected native binding below validates the descriptor.
    return self:bindSkillCard("feilangduo", {}, request, nil, "#feilangduoCard")
end
sgs.ai_skill_use_func["#feilangduoCard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "hp")
    local max_card = self:getMaxCard()
    local max_point = max_card:getNumber()
    local duel = source_clone(self,"feilangduo","feihujue","duel")
    local dummy_use = self:evaluateCard(duel, dummy(true, 99))
    if dummy_use.card then
        if not dummy_use.to:isEmpty() then
            for _, p in sgs.qlist(dummy_use.to) do
                if self.player:canPindian(p) then
                    local enemy_max_card = self:getMaxCard(p)
                    local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
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
        if self:isFriend(target) then
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
        if self:isFriend(p) then
            return true
        end
    end
    return false
end
sgs.ai_fill_skill.feisheji = function(self,inclusive,request)
    if #self.enemies < 1 then return end
    if self.player:isKongcheng() then return end
    local cards = sgs.QList2Table(self.player:getHandcards())
    local card_OK = false
    for _, acard in ipairs(cards) do
        if acard:isKindOf("EquipCard") then
            card_OK = true
        end
    end
    if not card_OK then return end
    local selfSub = self.player:getHp() - self.player:getHandcardNum()
    local selfDef = self:getDefense(self.player)

    for _, enemy in ipairs(self.enemies) do
        local def = self:getDefenseSlash(enemy)
        local slash = self:getEvaluationCard("slash")
        local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

        if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(nil, enemy) and def < 6 and eff then
            return self:legacySkillSeed("feisheji", "#feishejiCard", request)
        end
    end
end

sgs.ai_skill_use_func["#feishejiCard"] = function(card, use, self,request)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local target
    local card
    for _, acard in ipairs(cards) do
        if acard:isKindOf("EquipCard") then
            card = acard
        end
    end
    local selfSub = self.player:getHp() - self.player:getHandcardNum()
    local selfDef = self:getDefense(self.player)

    for _, enemy in ipairs(self.enemies) do
        local def = self:getDefenseSlash(enemy)
        local slash = self:getEvaluationCard("slash")
        local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, nil)

        if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(nil, enemy) and def < 6 and eff then
            target = enemy
            break
        end
    end
    if target and card then
        use.card = self:bindSkillCard("feisheji", {card:getKnownEffectiveId()}, request, nil, "#feishejiCard")
        if use.to then use.to:append(target) end
        return
    end
end

sgs.ai_use_value["#feishejiCard"]      = 9
sgs.ai_use_priority["#feishejiCard"]   = 3.2
sgs.ai_card_intention["#feishejiCard"] = 80

sgs.ai_cardsview_valuable.feisheji = function(self, class_name, player)
    local usereason = known(self.request.reason,"current use reason")
    if usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return end

    local handcards = sgs.QList2Table(self.player:getCards("he"))
    local had_card = nil
    for _, c in ipairs(handcards) do
        if c:isKindOf("Slash") then
            had_card = c
        end
    end

    if class_name == "slash" and had_card then
        for _, c in ipairs(handcards) do
            if c:isKindOf("EquipCard") then
                local card_str = "#feishejiCard:" ..c:getKnownEffectiveId() ..":"
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
        if not self:isEnemy(player) then
            table.insert(to, player:objectName())
        end
    end
    assert(string.format("#feifenhuCard:.:->%s", table.concat(to, "+")))
    return string.format("#feifenhuCard:.:->%s", table.concat(to, "+"))
end
sgs.ai_card_intention.feifenhuCard     = -20
sgs.ai_skill_invoke.feidaizui          = function(self, data)
    if self:getCardsNum("Jink") > 0 then
        return false
    end
    return true
end
sgs.ai_skill_playerchosen.feidaizui    = function(self, targets)
    self:updatePlayers()
    local targetlist = sgs.QList2Table(targets)
    self:sort(self.friends_noself, "handcard")
    for _, friend in ipairs(self.friends_noself) do
        if friend and self:needToLoseHp(friend, nil, nil) then
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
    if self:getCardsNum("Jink") > 1 then
        return "give"
    end
    return "no"
end
sgs.ai_skill_invoke.feidaizuidraw      = function(self, data)
    local least = 1000
    local f, e = 0, 0
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        least = math.min(p:getHandcardNum(), least)
    end
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:getHandcardNum() == least then
            if self:isFriend(p) then
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
        least = math.min(p:getHandcardNum(), least)
    end
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:getHandcardNum() == least then
            if self:isFriend(p) then
                f = f + 1
            else
                e = e + 1
            end
        end
    end
    return to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
        and self:canLoseHp(from, card, to) and f >= e
end

sgs.ai_skill_choice.feitouhuo = function(self,choices,data)
    for _,friend in ipairs(self.friends)do
        if friend:hasSkill("tianxiang") and (self.player:getHp()>=3 or (self:getCardsNum("Peach")+self:getCardsNum("Analeptic")>0 and self.player:getHp()>1)) then
            return "hp"
        end
    end
    if self.player:getMaxHp()>=self.player:getHp()+2 then
        if self.player:getMaxHp()>5 and (self.player:hasSkills("nosmiji|yinghun|juejing|zaiqi|nosshangshi") or self.player:hasSkill("miji") and self:findPlayerToDraw(false)) then
            return "hp"
        end
        return "maxhp"
    else
        return "hp"
    end
end

sgs.ai_fill_skill.feizuijiao = function(self,inclusive,request)
    if self.player:getStrategyHasUsed("#feizuijiaoCard") then
        return
    end
    -- Source parse assertion, selected native binding below validates the descriptor.
    return self:bindSkillCard("feizuijiao", {}, request, nil, "#feizuijiaoCard")
end
sgs.ai_skill_use_func["#feizuijiaoCard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "hp")
    for _,enemy in ipairs(self.enemies)do
        if self:canAttack(enemy, self.player)
                and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy,50,self.player) then
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
    if not self.player:faceUp() then
        return true
    end
    if math.random() < 0.4 then
        return true
    end
    if self:getCardsNum("Slash") > 2 then
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
    if self:isFriend(move.to) then
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
        if not c:isKindOf("Slash") and not c:isKindOf("Peach")
            and ((self:getUseValue(c) < sgs.ai_use_value.Slash) or nil) then
            card = c
            break
        end
    end
    if not card then return nil end
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getKnownEffectiveId()
    local card_str = ("slash:feiwusheng[%s:%s]=%d"):format(suit, number, card_id)
    local slash = self:bindTurnConversion("feiwusheng", "Slash", {name="slash",skill_name="feiwusheng",suit=card:getSuit(),number=card:getNumber(),subcards={card_id}}, request)
    assert(slash)
    return slash
end
sgs.ai_view_as.feiwusheng = function(card,player,card_place)
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getKnownEffectiveId()
    if card_place~=sgs.Player_PlaceSpecial and not card:isKindOf("Peach") and not card:getStrategyFlag("using") then
        return ("slash:feiwusheng[%s:%s]=%d"):format(suit,number,card_id)
    end
end
sgs.ai_ajustdamage_from.feiwusheng = function(self, from, to, card, nature)
    if to:getHujia() > 0 and to:getHp() ~= 1
    then
        return 1
    end
end


sgs.ai_fill_skill.feiyanjun = function(self,inclusive,request)
    if self.player:getStrategyHasUsed("#feiyanjunCard")
        or self.player:isNude() then
        return
    end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    local card_ids = {}
    for _, c in pairs(cards) do
        if not c:isKindOf("BasicCard") then
            table.insert(card_ids, c:getKnownEffectiveId())
            break
        end
    end
    if #card_ids ~= 0 then
        return self:bindSkillCard("feiyanjun", card_ids, request, nil, "#feiyanjunCard")
    else
        return nil
    end
end
sgs.ai_skill_use_func["#feiyanjunCard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "hp")
    local duel = source_clone(self,"feiyanjun","feiyanjunCard","duel")
    for _, to in ipairs(self.enemies) do
        if to and not (self:hasSkills(sgs.lose_equip_skill, to) and to:hasEquip()) and not hasZhaxiangEffect(to) and self:damageIsEffective(to, sgs.DamageStruct_Thunder) and not self:cantbeHurt(to) and self:canDamage(to, self.player, nil) and self:hasTrickEffective(duel,to) then
            use.card = card
            if use.to then
                use.to:append(to)
            end
            return
        end
    end
    for _, to in ipairs(self.enemies) do
        if to and not (self:hasSkills(sgs.lose_equip_skill, to) and to:hasEquip()) and not hasZhaxiangEffect(to) and self:damageIsEffective(to, sgs.DamageStruct_Thunder) and not self:cantbeHurt(to) and self:canDamage(to, self.player, nil)  then
            use.card = card
            if use.to then
                use.to:append(to)
            end
            return
        end
    end
    for _, to in ipairs(self.enemies) do
        if to and self:isWeak(to)  then
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
    if self:needToLoseHp(self.player) and table.contains(items, "damage") then
        return "damage"
    end
    if hasZhaxiangEffect(self.player) and not self:isWeak() and table.contains(items, "losehp") then
        return "losehp"
    end

    return items[math.random(1, #items)]
end

sgs.ai_skill_use["@@feifengpo"] = function(self, prompt)
    local use = scope_use(self,"feifengpo_use")
    if use.from and self:isFriend(use.from) then
        return "."
    end
    if self:needToThrowArmor() and self.player:getArmor() and self.player:getArmor():isRed() then
        return "#feifengpoCard:" ..
            self.player:getArmor():getEffectiveId() .. ":"
    end
    if not self:slashIsEffective(use.card, self.player, use.from)
        or (self:ajustDamage(use.from, self.player, 1, use.card) < 2
            and self:needToLoseHp(self.player, use.from, use.card)) then
        return "."
    end
    if self:ajustDamage(use.from, self.player, 1, use.card) and self:getCardsNum("Peach") > 0 then return "." end
    if self:getCardsNum("Jink") == 0 or not sgs.isJinkAvailable(use.from, self.player, use.card, true) then return "." end
    local equip_index = { 3, 0, 2, 4, 1 }
    if self.player:hasSkills(sgs.lose_equip_skill) then
        for _, i in ipairs(equip_index) do
            if i == 4 then break end
            if self.player:getEquip(i) and self.player:getEquip(i):isRed() then
                return "#feifengpoCard:" ..
                    self.player:getEquip(i):getEffectiveId() .. ":"
            end
        end
    end
    local jiangqin = self.room:findPlayerBySkillName("niaoxiang")
    local need_double_jink = use.from:hasSkill("wushuang")
        or (use.from:hasSkill("roulin") and self.player:isFemale())
        or (self.player:hasSkill("roulin") and use.from:isFemale())
        or (jiangqin and jiangqin:isAdjacentTo(self.player) and use.from:isAdjacentTo(self.player) and self:isEnemy(jiangqin))
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if not card:getSuitString():isRed() or (not self:isWeak() and (self:getKeepValue(card) > 8 or self:isValuableCard(card)))
            or (isCard("Jink", card, self.player) and self:getCardsNum("Jink") - 1 < (need_double_jink and 2 or 1)) then
            continue
        end
        return "#feifengpoCard:" ..
            card:getKnownEffectiveId() .. ":"
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
    if not self:isFriend(target) then
        return true
    end
    return false
end
ai_audited_aliases.register{id="ai_cardneed.feifengpo",registry="ai_cardneed",path={"feifengpo"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_ajustdamage_from.feifengpo = function(self, from, to, card, nature)
    if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) and card:getStrategyFlag("feifengpo")
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
    if to and self:isEnemy(to) and not self:needToLoseHp(to) then
        return true
    end
    return false
end

sgs.ai_fill_skill.feilianhuan = function(self,inclusive,request)
    if self.player:isKongcheng() then return end
    -- Source parse assertion, selected native binding below validates the descriptor.
    return self:bindSkillCard("feilianhuan", {}, request, nil, "#feilianhuanCard")
end
sgs.ai_skill_use_func["#feilianhuanCard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "value")
    for _, to in ipairs(self.enemies) do
        if to and self.player:canPindian(to) and not to:isChained() and  self:objectiveLevel(to)>2
            and not self:needToLoseHp(to)
            and self:isGoodTarget(to, self.enemies) then
            use.card = card
            if use.to then
                use.to:append(to)
            end
            return
        end
    end
    for _, to in ipairs(self.enemies) do
        if to and self.player:canPindian(to) and not to:isChained()  and not self:needToLoseHp(to) then
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
    return  card:getSuit() == sgs.Card_Club
end

sgs.ai_can_damagehp.feiniepan = function(self,from,card,to)
    return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
    and self:canLoseHp(from, card, to) and to:isKongcheng() and (card:isKindOf("FireAttack") or card:isKindOf("FireSlash"))
end

sgs.ai_canNiepan_skill.feiniepan = function(player)
    return player:getStrategyMark("@nirvana") > 0
end
