-- Fixed b6025acc Mountainrumour; private helpers retain the original branch order.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("Mountainrumour missing "..k,"mountainrumour")end;return v end
local function q(o,m,...)
 if AIValue.isPlayer(o)then if m=="getMark"then m="getStrategyMark"elseif m=="hasFlag"then m="getStrategyFlag"end end
 if not o or type(o[m])~="function"then ai_unsupported("Mountainrumour unavailable "..m,"mountainrumour")end
 return known(o[m](o,...),m)
end
local function dummy()local use=AIUsePlan.new();use.isDummy=true;return use end
local function r45_shisheng(self,name,costs,preview)
 return q(self,"evaluateOwnerViewAsCard",{source_key=preview and "mountainrumour.shisheng_preview" or "mountainrumour.shisheng",
  name=name,skill=preview and "" or "shisheng",suit=preview and sgs.Card_NoSuit or sgs.Card_SuitToBeDecided,
  number=preview and -1 or 0,subcards=costs})
end
local function scope(self,key)local row=q(self,"getDecisionContext").mountainrumour;if type(row)~="table"then ai_unsupported("Mountainrumour scoped data unavailable",key)end;return known(row[key],key)end
local function choice_card(self,id)local c=q(self,"getChoiceCard",id);if type(self.getAcquiredCardEvaluation)=="function"then c=self:getAcquiredCardEvaluation(c)or c end;return c end
local function scope_player(self,key)local n=scope(self,key);if n==false or n==""then return nil end;return q(self.room,"findPlayerByObjectName",n)end
local function scope_card(self,key)
 local row=scope(self,key);if row==false then return nil end
 local c=known(CardView.new(row),key)
 if row.evaluation_candidate then c._evaluation_candidate=row.evaluation_candidate end;return c
end
local function caokong_evaluation(self,c)
 local actual=q(self,"evaluateSkillCard","luacaokong_context",q(c,"objectName"),{})
 for _,method in ipairs({"getEffectiveId","objectName","getClassName","getSuit","getNumber","getLegacyIdentityToken"})do
  if q(actual,method)~=q(c,method)then ai_unsupported("Caokong actual disclosed card changed","caokong_card")end
 end
 return actual
end
local function scope_damage(self,key)local row=scope(self,key);if row==false then return nil end;return row end
local function scope_use(self,key)
 local row=scope(self,key);local u={to=AIList.new({})};if row==false then return u end
 for _,n in ipairs(known(row.to,key..".to"))do u.to:append(q(self.room,"findPlayerByObjectName",n))end;return u
end
local function front(self,a,b)
 local players=q(self.room,"getAllPlayers",true);local ia,ib=-1,-1
 for i,p in ipairs(players)do if p:objectName()==a:objectName()then ia=i end;if p:objectName()==b:objectName()then ib=i end end
 return ia<ib and a or b
end
local function role_count(self,role)return known(q(self,"getRoleCounts")[role],"role count "..role)end
local function known_hand(self,p)
 if p:objectName()==self.player:objectName()then return q(p,"getHandcards")end
 return q(p,"getKnownCards") -- Subsequent original visible-flag checks are retained.
end
local function classify(self,kind,card,p)
 local opts=self.request and self.request.options
 if p:objectName()==self.player:objectName()and self.request.kind=="amazing_grace"and q(card,"isVirtualCard")==false then
  for _,id in ipairs(opts and opts.card_ids or{})do if id==q(card,"getEffectiveId")then return q(self,"isCardForAcquisition",kind,card)end end
 end
 return isCard(kind,card,p)
end
local function tongtang_player(self)
 local name,present=self:getStrategyMemory("mountainrumour.tongtang");if not present or name==false then return nil end
 self:useKnowledgeEstimate({status="estimate",value=true,basis="mountainrumour.room_ai_tag_viewer_partition"},"luatongtang")
 return q(self.room,"findPlayerByObjectName",name)
end
local function mark_state(self)
 local facts=self.world.strategy_facts;local name=self.player:objectName()
 local all=facts and facts.strategy_all_mark_clear_epochs;local turn=facts and facts.strategy_turn_clear_epochs
 local epochs={all=type(all)=="table"and all[name]or nil,clear=type(turn)=="table"and turn[name]or nil}
 if type(epochs.all)~="number"or type(epochs.clear)~="number"then ai_unsupported("Shisheng requires actual mark-reset lifecycle","mountainrumour.shisheng")end
 local old,present=self:getStrategyMemory("mountainrumour.marks");local state={all=epochs.all,clear=epochs.clear,values={}}
 if present and type(old)=="table"and old.all==epochs.all then for k,v in pairs(old.values)do if old.clear==epochs.clear or k:sub(-6)~="-Clear"then state.values[k]=v end end end
 return state
end
local function get_mark(self,key)local state=mark_state(self);if state.values[key]~=nil then return state.values[key]end;return q(self.player,"getMark",key)end
local function set_mark(self,key,value)local state=mark_state(self);state.values[key]=value;self:setStrategyMemory("mountainrumour.marks",state)end
local function add_mark(self,key)set_mark(self,key,get_mark(self,key)+1)end

local function card_need_player(self, players, cards)
    cards = cards or sgs.QList2Table(self.player:getHandcards())
    local cardtogivespecial = {}
    local specialnum = 0
    local keptslash = 0
    local friends = {}

    local cmpByAction = function(a, b)
        return q(a,"objectName") ~= q(b,"objectName") and front(self,a,b):objectName() == q(a,"objectName")
    end
    local cmpByNumber = function(a, b)
        return q(a,"getNumber") > q(b,"getNumber")
    end

    for _, player in ipairs(players) do
        local exclude = q(self,"needKongcheng",player) or q(self,"willSkipPlayPhase",player)
        if self:hasSkills("keji|qiaobian|shensu", player) or q(player,"getHp") - q(player,"getHandcardNum") >= 3
            or (player:isLord() and q(self,"isWeak",player) and self:getEnemyNumBySeat(self.player, player) >= 1) then
            exclude = false
        end
        if q(self,"objectiveLevel",player) <= -2 and not (q(player,"hasSkill","manjuan") and self.room:getCurrent() ~= player) and not exclude then
            table.insert(friends, player)
        end
    end

    for _, player in ipairs(friends) do
        if q(player,"hasSkill","jieming") or q(player,"hasSkill","jijiu") then
            specialnum = specialnum + 1
        end
    end
    if specialnum > 1 and #cardtogivespecial == 0 and q(self.player,"hasSkill","nosrende") and q(self.player,"getPhase") == sgs.Player_Play then
        local xunyu = self.room:findPlayerBySkillName("jieming")
        local huatuo = self.room:findPlayerBySkillName("jijiu")
        local no_distance = self.slash_distance_limit
        local redcardnum = 0
        for _, acard in ipairs(cards) do
            if classify(self,"Slash", acard, self.player) then
                if q(self.player,"canSlash",xunyu, nil, not no_distance) and q(self,"slashIsEffective",acard, xunyu) then
                    keptslash = keptslash + 1
                end
                if keptslash > 0 then
                    table.insert(cardtogivespecial, acard)
                end
            elseif classify(self,"Duel", acard, self.player) then
                table.insert(cardtogivespecial, acard)
            end
        end
        for _, hcard in ipairs(cardtogivespecial) do
            if q(hcard,"isRed") then redcardnum = redcardnum + 1 end
        end
        if q(self.player,"getHandcardNum") > #cardtogivespecial and redcardnum > 0 then
            for _, hcard in ipairs(cardtogivespecial) do
                if q(hcard,"isRed") then return hcard, huatuo end
                return hcard, xunyu
            end
        end
    end

    local cardtogive = {}
    local keptjink = 0
    for _, acard in ipairs(cards) do
        if classify(self,"Jink", acard, self.player) and keptjink < 1 then
            keptjink = keptjink + 1
        else
            table.insert(cardtogive, acard)
        end
    end

    self:sort(friends, "defense")
    for _, friend in ipairs(friends) do
    if q(self,"isWeak",friend) and q(friend,"getHandcardNum") < 3 then
        for _, hcard in ipairs(cards) do
            if classify(self,"Peach", hcard, friend)
                or (classify(self,"Jink", hcard, friend) and self:getEnemyNumBySeat(self.player, friend) > 0)
                or classify(self,"Analeptic", hcard, friend) then
                    return hcard, friend
                end
            end
        end
    end

    if (q(self.player,"hasSkill","nosrende") and q(self.player,"isWounded") and q(self.player,"getMark","nosrende") < 2) then
        if (q(self.player,"getHandcardNum") < 2 and q(self.player,"getMark","nosrende") == 0) then return end

        if ((q(self.player,"getHandcardNum") == 2 and q(self.player,"getMark","nosrende") == 0) or
            (q(self.player,"getHandcardNum") == 1 and q(self.player,"getMark","nosrende") == 1)) and q(self,"getOverflow") <= 0 then
            for _, enemy in ipairs(self.enemies) do
                if q(enemy,"hasWeapon","guding_blade")
                    and (q(enemy,"canSlash",self.player)
                    or self:hasSkills("shensu|jiangchi|tianyi|wushen|nosgongqi")) then
                    return
                end
                if q(enemy,"canSlash",self.player) and q(enemy,"hasSkill","nosqianxi") and q(enemy,"distanceTo",self.player) == 1 then return end
            end
        end
    end

    if (q(self.player,"hasSkill","rende") and not q(self.player,"hasUsed","RendeCard") and q(self.player,"isWounded") and q(self.player,"getMark","rende") < 2) then
        if (q(self.player,"getHandcardNum") < 2 and q(self.player,"getMark","rende") == 0) then return end

        if ((q(self.player,"getHandcardNum") == 2 and q(self.player,"getMark","rende") == 0) or
            (q(self.player,"getHandcardNum") == 1 and q(self.player,"getMark","rende") == 1)) and q(self,"getOverflow") <= 0 then
            for _, enemy in ipairs(self.enemies) do
                if q(enemy,"hasWeapon","guding_blade")
                    and (q(enemy,"canSlash",self.player)
                    or self:hasSkills("shensu|jiangchi|tianyi|wushen|nosgongqi")) then
                    return
                end
                if q(enemy,"canSlash",self.player) and q(enemy,"hasSkill","nosqianxi") and q(enemy,"distanceTo",self.player) == 1 then return end
            end
        end
    end

    for _, friend in ipairs(friends) do
        if q(friend,"getHp") <= 2 and q(friend,"faceUp") then
            for _, hcard in ipairs(cards) do
                if (q(hcard,"isKindOf","Armor") and not friend:getArmor() and not self:hasSkills("yizhong|bazhen", friend))
                    or (q(hcard,"isKindOf","DefensiveHorse") and not friend:getDefensiveHorse()) then
                    return hcard, friend
                end
            end
        end
    end

    self:sortByUseValue(cards, true)
    for _, friend in ipairs(friends) do
        if self:hasSkills("jijiu|jieyin", friend) and q(friend,"getHandcardNum") < 4 then
            for _, hcard in ipairs(cards) do
                if (q(hcard,"isRed") and q(friend,"hasSkill","jijiu")) or q(friend,"hasSkill","jieyin") then
                    return hcard, friend
                end
            end
        end
    end

    for _, friend in ipairs(friends) do
        if self:hasSkills("longdan|wusheng|keji", friend) and not self:hasSkills("paoxiao", friend) and q(friend,"getHandcardNum") >= 2 then
            for _, hcard in ipairs(cards) do
                if q(hcard,"isKindOf","Crossbow") then
                    return hcard, friend
                end
            end
        end
    end
    for _, friend in ipairs(friends) do
        if getKnownCard(friend, "Crossbow") then
            for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
                if q(self,"isEnemy",p) and q(self,"isGoodTarget",p, self.enemies, nil) and q(friend,"distanceTo",p) <= 1 then
                    for _, hcard in ipairs(cards) do
                        if classify(self,"Slash", hcard, friend) then
                            return hcard, friend
                        end
                    end
                end
            end
        end
    end

    table.sort(friends, cmpByAction)
    for _, friend in ipairs(friends) do
        if q(friend,"faceUp") then
            local can_slash = false
            for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
                if q(self,"isEnemy",p) and q(self,"isGoodTarget",p, self.enemies, nil) and q(friend,"distanceTo",p) <= q(friend,"getAttackRange") then
                    can_slash = true
                    break
                end
            end

            if not can_slash then
                for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
                    if q(self,"isEnemy",p) and q(self,"isGoodTarget",p, self.enemies, nil) and q(friend,"distanceTo",p) > q(friend,"getAttackRange") then
                        for _, hcard in ipairs(cardtogive) do
                            if q(hcard,"isKindOf","Weapon")
                                and q(friend,"distanceTo",p) <= q(friend,"getAttackRange") + (sgs.weapon_range[hcard:getClassName()] or 0) and not friend:getWeapon() then
                                return hcard, friend
                            end
                            if q(hcard,"isKindOf","OffensiveHorse")
                                and q(friend,"distanceTo",p) <= q(friend,"getAttackRange") + 1 and not friend:getOffensiveHorse() then
                                return hcard, friend
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(cardtogive, cmpByNumber)
    for _, friend in ipairs(friends) do
        if not q(self,"needKongcheng",friend) and q(friend,"faceUp") then
            for _, hcard in ipairs(cardtogive) do
                for _, askill in sgs.qlist(friend:getVisibleSkillList()) do
                    local callback = sgs.ai_cardneed[q(askill,"objectName")]
                    if type(callback) == "function" and callback(friend, hcard, self) then
                        return hcard, friend
                    end
                end
            end
        end
    end

    if self.role == "lord" and q(self.player,"hasLordSkill","jijiang") then
        for _, friend in ipairs(friends) do
            if q(friend,"getKingdom") == "shu" and q(friend,"getHandcardNum") < 3 then
                for _, hcard in ipairs(cardtogive) do
                    if classify(self,"Slash", hcard, friend) then
                        return hcard, friend
                    end
                end
            end
        end
    end

    self:sort(self.enemies, "defense")
    if #self.enemies > 0 and self.enemies[1]:isKongcheng() and self.enemies[1]:hasSkill("kongcheng") then
        local do_continue = false
        for _,p in ipairs(players) do
            if q(p,"objectName") == self.enemies[1]:objectName() then
                do_continue = true
                break
            end
        end
        if do_continue then
            for _, acard in ipairs(cardtogive) do
                if q(acard,"isKindOf","Lightning") or q(acard,"isKindOf","Collateral") or (q(acard,"isKindOf","Slash") and q(self.player,"getPhase") == sgs.Player_Play)
                    or q(acard,"isKindOf","OffensiveHorse") or q(acard,"isKindOf","Weapon") then
                    return acard, self.enemies[1]
                end
            end
        end
    end

    self:sort(friends, "defense")
    for _, hcard in ipairs(cardtogive) do
        for _, friend in ipairs(players) do
            if not q(self,"needKongcheng",friend) and not q(friend,"hasSkill","manjuan") and not q(self,"willSkipPlayPhase",friend)
                    and (self:hasSkills(sgs.priority_skill, friend) or (sgs.ai_chaofeng[self.player:getGeneralName()] or 0) > 2) then
                if (q(self,"getOverflow") > 0 or q(self.player,"getHandcardNum") > 3) and q(friend,"getHandcardNum") <= 3 then
                    return hcard, friend
                end
            end
        end
    end

    self:sort(friends, "handcard")
    for _, hcard in ipairs(cardtogive) do
        for _, friend in ipairs(players) do
            if not q(self,"needKongcheng",friend) and not (q(friend,"hasSkill","manjuan") and q(friend,"getPhase") == sgs.Player_NotActive) then
                if q(friend,"getHandcardNum") <= 3
                    and (q(self,"getOverflow") > 0 or q(self.player,"getHandcardNum") > 3
                        or (q(self.player,"hasSkill","nosrende") and q(self.player,"isWounded") and q(self.player,"getMark","nosrende") < 2)
                        or (q(self.player,"hasSkill","rende") and not q(self.player,"hasUsed","RendeCard") and q(self.player,"isWounded") and q(self.player,"getMark","rende") < 2)) then
                    return hcard, friend
                end
            end
        end
    end

    for _, hcard in ipairs(cardtogive) do
        for _, friend in ipairs(players) do
            if not q(self,"needKongcheng",friend) and not (q(friend,"hasSkill","manjuan") and q(friend,"getPhase") == sgs.Player_NotActive) then
                if (q(self,"getOverflow") > 0 or q(self.player,"getHandcardNum") > 3
                    or (q(self.player,"hasSkill","rende") and q(self.player,"isWounded") and q(self.player,"usedTimes","RendeCard") < 2)) then
                    return hcard, friend
                end
            end
        end
    end

    if #cards > 0 and ((q(self.player,"hasSkill","rende") and not q(self.player,"hasUsed","RendeCard") and q(self.player,"getMark","rende") < 2)
                        or (q(self.player,"hasSkill","nosrende") and q(self.player,"getMark","nosrende") < 2)) then
        local need_rende = (role_count(self,"rebel") == 0 and role_count(self,"loyalist")  > 0 and q(self.player,"isWounded"))
                            or (role_count(self,"rebel") > 0 and role_count(self,"renegade") > 0
                                and role_count(self,"loyalist")  == 0 and q(self,"isWeak"))
        if need_rende then
            self:sort(players, "defense")
            self:sortByUseValue(cards, true)
            return cards[1], players[1]
        end
    end
end

local function draw_player(players, drawnum, self)
    drawnum = drawnum or 1
    local friends = {}
    for _, player in ipairs(players) do
        if q(self,"isFriend",player) and not (q(player,"hasSkill","manjuan") and q(player,"getPhase") == sgs.Player_NotActive)
            and not (q(player,"hasSkill","kongcheng") and q(player,"isKongcheng") and drawnum <= 2) then
            table.insert(friends, player)
        end
    end
    if #friends == 0 then return end

    self:sort(friends, "defense")
    for _, friend in ipairs(friends) do
        if q(friend,"getHandcardNum") < 2 and not q(self,"needKongcheng",friend) and not q(self,"willSkipPlayPhase",friend) then
            return friend
        end
    end

    for _, friend in ipairs(friends) do
        if self:hasSkills(sgs.cardneed_skill, friend) and not q(self,"willSkipPlayPhase",friend) then
            return friend
        end
    end

    self:sort(friends, "handcard")
    for _, friend in ipairs(friends) do
        if not q(self,"needKongcheng",friend) and not q(self,"willSkipPlayPhase",friend) then
            return friend
        end
    end
    return nil
end



local tuxi_targets = function(self, players, target_num)
    self:sort(self.enemies, "handcard")
    local targets = {}

    local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
    local luxun = self.room:findPlayerBySkillName("lianying")
    local dengai = self.room:findPlayerBySkillName("tuntian")
    local jiangwei = self.room:findPlayerBySkillName("zhiji")

    local add_player = function(player, isfriend)
        local included = false
        for _,p in ipairs(players) do
            if q(p,"objectName") == q(player,"objectName") then
                included = true
                break
            end
        end
        if not included then return #targets end
        if q(player,"getHandcardNum") == 0 or q(player,"objectName") == q(self.player,"objectName") then return #targets end
        if q(self,"objectiveLevel",player) == 0 and player:isLord() and role_count(self,"rebel") > 1 then return #targets end
        if #targets == 0 then
            table.insert(targets, player)
        else
            local to_join = true
            for _,p in ipairs(targets) do
                if q(player,"objectName") ~= q(p,"objectName") then
                    to_join = false
                    break
                end
            end
            if to_join then
                table.insert(targets, player)
            end
        end
        if isfriend and isfriend == 1 then
            self:setStrategyPlayerFlag(self.player,"AI_TuxiToFriend_" .. q(player,"objectName"),true)
        end
        return #targets
    end

    local lord = self.room:getLord()
    if lord and q(self,"isEnemy",lord) and q(self.room,"getTurnCount") <= 1 and not q(lord,"isKongcheng") then
        add_player(lord)
    end

    if jiangwei and q(self,"isFriend",jiangwei) and q(jiangwei,"getMark","zhiji") == 0 and q(jiangwei,"getHandcardNum")== 1
        and self:getEnemyNumBySeat(self.player, jiangwei) <= (q(jiangwei,"getHp") >= 3 and 1 or 0) then
        if add_player(jiangwei, 1) == target_num then return targets end
    end
    if dengai and q(dengai,"hasSkill","zaoxian") and q(self,"isFriend",dengai) and (not q(self,"isWeak",dengai) or self:getEnemyNumBySeat(self.player, dengai) == 0)
        and q(dengai,"getMark","zaoxian") == 0 and dengai:getPile("field"):length() == 2 and add_player(dengai, 1) == target_num then
        return targets
    end

    if zhugeliang and q(self,"isFriend",zhugeliang) and q(zhugeliang,"getHandcardNum") == 1 and self:getEnemyNumBySeat(self.player, zhugeliang) > 0 then
        if q(zhugeliang,"getHp") <= 2 then
            if add_player(zhugeliang, 1) == target_num then return targets end
        else
            local flag = string.format("%s_%s_%s", "visible", q(self.player,"objectName"), q(zhugeliang,"objectName"))
            local cards = sgs.QList2Table(known_hand(self,zhugeliang))
            if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
                if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
                    if add_player(zhugeliang, 1) == target_num then return targets end
                end
            end
        end
    end

    if luxun and q(self,"isFriend",luxun) and q(luxun,"getHandcardNum") == 1 and self:getEnemyNumBySeat(self.player, luxun) > 0 then
        local flag = string.format("%s_%s_%s", "visible", q(self.player,"objectName"), q(luxun,"objectName"))
        local cards = sgs.QList2Table(known_hand(self,luxun))
        if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
            if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
                if add_player(luxun, 1) == target_num then return targets end
            end
        end
    end

    for i = 1, #self.enemies, 1 do
        local p = self.enemies[i]
        local cards = sgs.QList2Table(known_hand(self,p))
        local flag = string.format("%s_%s_%s", "visible", q(self.player,"objectName"), q(p,"objectName"))
        for _, card in ipairs(cards) do
            if (q(card,"hasFlag","visible") or q(card,"hasFlag",flag)) and (q(card,"isKindOf","Peach") or q(card,"isKindOf","Nullification") or q(card,"isKindOf","Analeptic")) then
                if add_player(p) == target_num then return targets end
            end
        end
    end

    for i = 1, #self.enemies, 1 do
        local p = self.enemies[i]
        if q(p,"hasSkills","jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
            if add_player(p) == target_num then return targets end
        end
    end

    for i = 1, #self.enemies, 1 do
        local p = self.enemies[i]
        local x = q(p,"getHandcardNum")
        local good_target = true
        if x == 1 and self:hasSkills(sgs.need_kongcheng, p) then good_target = false end
        if x >= 2 and hasTuntianEffect(p, true) then good_target = false end
        if good_target and add_player(p) == target_num then return targets end
    end

    if luxun and add_player(luxun, (q(self,"isFriend",luxun) and 1 or nil)) == target_num then
        return targets
    end

    if dengai and q(self,"isFriend",dengai) and (not q(self,"isWeak",dengai) or self:getEnemyNumBySeat(self.player, dengai) == 0) and add_player(dengai, 1) == target_num then
        return targets
    end

    local others = self.room:getOtherPlayers(self.player)
    for _, other in sgs.qlist(others) do
        if q(self,"objectiveLevel",other) >= 0 and hasTuntianEffect(other, true) and add_player(other) == target_num then
            return targets
        end
    end


    return targets
end


local function _aiPlayerChat(self, answers)
    local answer = answers[math.random(1, #answers)]
    self:emitSpeechLine(self.player,answer,"mountainrumour")
end

local function aiPlayerChat(self, skillname)
    local a = skillname
    local b = {}
    if a == "fendao_1" then
        b = {"邓艾：我们一起去偷窥姜小薇洗澡吧咕嘿嘿。钟会滚粗。"}
    elseif a == "fendao_2" then
        b = {"钟会：警察叔叔就是这个人！→邓艾：纳尼？"}
    elseif a == "shitu" then
        b = {"我在二郎神身边打过工。", "猎物休走！（舔舌头）", "我的优点是方向感好。"}
    elseif a == "tuogu" then
        b = {"哥几个罩住啊！", "我爸给你们发工资为了啥啊都想想！"}
    elseif a == "bawang" then
        b = {"还没完呢！", "再来再来！", "爽不爽？:-D", "站住别跑！直接撂倒！"}
    elseif a == "zhaoxu" then
        b = {"想娶我家香香，要先接受老身的试♂♀炼", "奶一口。奶水足足的。"}
    elseif a == "caokong" then
        b = {"我需要目标"}
    elseif a == "huanying" then
        b = {"你是信啊还是信啊还是信啊？", "让我们来做一道选择题。"}
    elseif a == "mengzhu" then
        b = {"乡亲们都出来吧！皇军不抢粮食！", "那谁谁！把你的胖次交出来！"}


    else
        b
            = {"看我的腻害！", "接受我的制裁吧！", "代表月亮消灭你！", "别看我只是一只羊~", "嘎啦嘎啦呜喵喵~", "咪啪~"}
    end
    _aiPlayerChat(self, b)
end



sgs.ai_skill_invoke.luatoudumr = function(self, data)
    return q(self.player,"getHandcardNum") - 2 > q(self.player,"getMaxCards")
end

sgs.ai_skill_choice.luatoudumr = function(self, choice)
    if q(self.player,"getHp") > 1 and (q(self,"getCardsNum","Peach") > 0 or q(self.player,"hasSkill","jieyin") or q(self.player,"hasSkill","qingnang") or hasZhaxiangEffect(self.player)) then return "toudu_dm" end
    return "toudu_dl"
end



sgs.ai_skill_use["@@luaxianhai"] = function(self, prompt, method)
    local others = self.room:getAlivePlayers()

    if q(self.player,"isKongcheng") then return "." end

    local from_card = scope_card(self,"xianhai_card")

    others = sgs.QList2Table(others)
    local source
    for _, player in ipairs(others) do
        if q(player,"getMark","xianhai_from") > 0 then
            source = player
            break
        end
    end
    self:sort(self.enemies, "defense")

    if source and (q(self,"isFriend",source))  then return "." end

    local doXianhai = function(who)

        if q(from_card,"isKindOf","Slash") or q(from_card,"isKindOf","AcheryAttack") then

            if not q(self,"isFriend",who) and q(who,"hasSkill","leiji")
                and (q(self,"hasSuit","spade", true, who) or q(who,"getHandcardNum") >= 3)
                and (getKnownCard(who, "Jink", true) >= 1 or q(self,"hasEightDiagramEffect",who)) then
                return "."
            end

        end

        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            if not q(self.player,"isCardLimited",card, method) and q(self.player,"inMyAttackRange",who) then
                if q(self,"isFriend",who) and not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) then
                    return "#luaxianhaicard:" .. q(card,"getEffectiveId") .. ":->" .. q(who,"objectName")
                elseif q(self,"isEnemy",who) and self:hasTrickEffective(from_card, who, source) and (q(from_card,"isKindOf","FireAttack") or (q(from_card,"isKindOf","Snatch") or q(from_card,"isKindOf","Dismantlement") or q(from_card,"isKindOf","Duel"))) then
                    return "#luaxianhaicard:" .. q(card,"getEffectiveId") .. ":->" .. q(who,"objectName")
                else
                    return "#luaxianhaicard:" .. q(card,"getEffectiveId") .. ":->" .. q(who,"objectName")
                end
            end
        end

        return "."
    end

    for _, enemy in ipairs(self.enemies) do
        if not (source and q(source,"objectName") == q(enemy,"objectName")) then
            local ret = doXianhai(enemy)
            if ret ~= "." then return ret end
        end
    end

    for _, player in ipairs(others) do
        if q(self,"objectiveLevel",player) == 0 and not (source and q(source,"objectName") == q(player,"objectName")) then
            local ret = doXianhai(player)
            if ret ~= "." then return ret end
        end
    end

    self:sort(self.friends_noself, "defense")
    self.friends_noself = sgs.reverse(self.friends_noself)

    for _, friend in ipairs(self.friends_noself) do
        if q(from_card,"isKindOf","Slash") and not q(self,"slashIsEffective",from_card, friend) then
            if not (source and q(source,"objectName") == q(friend,"objectName")) then
                local ret = doXianhai(friend)
                if ret ~= "." then return ret end
            end
        end
    end

    for _, friend in ipairs(self.friends_noself) do
        if q(self,"needToLoseHp",friend, source, from_card) then
            if not (source and q(source,"objectName") == q(friend,"objectName")) then
                local ret = doXianhai(friend)
                if ret ~= "." then return ret end
            end
        end
    end

    if (q(self,"isWeak")  or q(self,"hasHeavyDamage",source, from_card, self.player)) and q(source,"hasWeapon","axe") and (q(source,"getHandcardNum")+#source:getEquips()) > 2
        and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
        for _, friend in ipairs(self.friends_noself) do
            if not q(self,"isWeak",friend) then
                if not (source and q(source,"objectName") == q(friend,"objectName")) then
                    local ret = doXianhai(friend)
                    if ret ~= "." then return ret end
                end
            end
        end
    end

    if (q(self,"isWeak") or q(self,"hasHeavyDamage",source, from_card, self.player)) and not self:getCardId("Jink") then
        for _, friend in ipairs(self.friends_noself) do
            if not q(self,"isWeak",friend) then
                if not (source and q(source,"objectName") == q(friend,"objectName")) then
                    local ret = doXianhai(friend)
                    if ret ~= "." then return ret end
                end
            end
        end
    end
    return "."
end


sgs.ai_card_intention.luaxianhaicard = function(self, card, from, to)
    if not q(self,"isWeak",from) then self:updateIntention(from,to[1],50) end
end

function sgs.ai_slash_prohibit.liuxianhai(self, from, to, card)
    if q(self,"isFriend",to, from) then return false end
    if q(from,"hasFlag","NosJiefanUsed") then return false end
    if q(to,"isNude") then return false end
    for _, friend in ipairs(self:getFriends(from, true)) do
        if q(to,"canSlash",friend, card) and q(self,"slashIsEffective",card, friend, from) then return true end
    end
end

function sgs.ai_cardneed.luaxianhai(to, card)
    return q(to,"getHandcardNum") <= 2 and isCard("Jink", card, to)
end

sgs.bad_skills = sgs.bad_skills .. "|luazhenggongmr"

sgs.ai_use_revises.luazhenggongmr = function(self, card, use)
    if q(self.player,"getMark","fendao_used") == 0 and (q(card,"isKindOf","Slash") or (q(card,"isNDTrick") and not q(card,"isKindOf","AOE"))) and q(self,"getCardsNum",card:getName()) < 2  then
        return false
    end
end

sgs.ai_can_damagehp.luazhenggongmr = function(self, from, card, to)
    if q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0
        and q(self,"canLoseHp",from, card, to)
    then
        return q(to,"getLostHp") < 3 and q(to,"getMark","fendao_used") == 0
    end
end

sgs.ai_skill_cardask["@luazhenggongmr"] = function(self,data,pattern)
    local player = self.player
    local cards = player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,c in sgs.list(cards)do
        if q(self,"matchesDiscardPattern",pattern,c)
        then return q(c,"getEffectiveId") end
    end
    return "."
end

sgs.ai_fill_skill.luafendao = function(self,inclusive,request)
    if q(self.player,"getMark","@fendao") <= 0 then return nil end
    if q(self.player,"getMaxHp") < 5 then return nil end
    local card_str = ("#luafendaocard:.:")
    local card = q(self,"bindSkillCard","luafendao",{},request,nil,"#luafendaocard")
    return card
end

sgs.ai_skill_use_func["#luafendaocard"] = function(card, use, self,request)
    if math.random(0,q(self.player,"getLostHp"))+q(self.room,"getTurnCount")-1<=1 then return false end
    use.card = card
    return
end

sgs.ai_skill_choice.luafendaocard = function(self, choice)
    local rand = math.random(1, 3)
    if rand == 1 then
        aiPlayerChat(self, "fendao_1")
        return "luatoudumr"
    end
    aiPlayerChat(self, "fendao_2")
    return "luaxianhai"
end

sgs.ai_card_intention.luafendaocard = 99
sgs.ai_use_priority.luafendaocard = 9.9

sgs.ai_chaofeng.luazhanghe_zhuiji = 1

sgs.ai_fill_skill.luashitu = function(self,inclusive,request)
    local will_use = false
    if q(self.player,"hasUsed","#luashitucard") or q(self.player,"isKongcheng") then
        return false
    elseif q(self.player,"getMark","luazhuiji") == 0 then
        will_use = true
    else
        local others = self.room:getOtherPlayers(self.player)
        for _,p in sgs.qlist(others) do
            if q(self,"isEnemy",self.player, p) and q(self,"isGoodTarget",p, self.enemies, nil) then
                if q(self.player,"canSlash",p) then
                    will_use = false
                    break
                elseif q(self.player,"getAttackRange") + 1 == q(self.player,"distanceTo",p) then
                    if q(self,"isGoodTarget",p, self.enemies, nil) and p:getDefensiveHorse() and q(self,"getCardsNum","Slash") > 0 then
                        will_use = true
                    end
                end
            end
        end
    end
    if will_use then
        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            if q(self.player,"getMark","luazhuiji") == 0 or (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player)) then
                local card_str = ("#luashitucard:"..q(card,"getEffectiveId")..":")
                local card = q(self,"bindSkillCard","luashitu",{q(card,"getEffectiveId")},request,nil,"#luashitucard")
                return card
            end
        end
    end
    return nil
end

sgs.ai_skill_use_func["#luashitucard"] = function(card, use, self,request)
    use.card = card
    return
end

function sgs.ai_cardneed.luazhuiji(to, card)
    return q(card,"isNDTrick") or q(card,"isKindOf","Slash")
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|luazhuiji"

sgs.ai_use_priority.luashitucard = 8

sgs.ai_chaofeng.luajiangwei_qilin = 0

function sgs.ai_cardneed.luaqilin(to, card)
    return q(card,"isKindOf","TrickCard")
end

sgs.ai_skill_invoke.luadunjia = function(self, data)
    if q(self.player,"getMark","luadunjia") > 0 then return true end
    return sgs.ai_skill_invoke.jushou(self, data)
end

sgs.ai_skill_choice.luadunjia = function(self, choice)
    aiPlayerChat(self)
    if q(self.player,"getHp") == 1 then return "dunjiarecover" end
    if q(self.player,"getHp") > q(self.player,"getHandcardNum") then return "dunjiadraw" end
    return "dunjiarecover"
end

sgs.ai_chaofeng.lualiushan_fuyou = -4

sgs.ai_skill_invoke.luatuogu = function(self, data)
    local damage = data:toDamage().damage
    if q(self.player,"getHp") - damage <= 0 and q(self,"getCardsNum","Peach") == 0 and q(self,"getCardsNum","Analeptic") == 0 then
        aiPlayerChat(self, "tuogu")
        return true
    end
end

sgs.ai_skill_choice.luatuogu = function(self, data)
    local target
    for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if q(p,"getMark","luatuogu_who") == 1 then
            target = p
            break
        end
    end
    if target and q(self,"isEnemy",self.player, target) then return "tuogunonhelper" end

    local from
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if q(p,"getMark","luatuogu_from") == 1 then
            from = p
            break
        end
    end


    self:sort(self.friends, "defense")
    local helper = self.friends[#self.friends]

    for _,p in ipairs(self.friends) do
        if q(self,"needToLoseHp",p, from, nil) then
            helper = p
            break
        end
    end

    if helper and q(helper,"objectName") == q(self.player,"objectName") then
        return "tuoguhelper"
    end
    return "tuogunonhelper"
end

sgs.ai_chaofeng.luasunce_bawang = 2

sgs.ai_skill_invoke.luabawang = function(self, data)
    local target
    local damage = data:toDamage()
    if damage then
        target = damage.to
    end
    local pindian = data:toPindian()
    if pindian then
        target = pindian.from
        if q(pindian.from,"objectName") == q(self.player,"objectName") then
            target = pindian.to
        end
    end
    if target and q(self,"isEnemy",self.player, target) then
        if not q(self,"needToLoseHp",target, self.player, nil) then
            aiPlayerChat(self, "bawang")
            return true
        end
    end
    return false
end

sgs.ai_skill_discard.luabawang = function(self, discard_num, min_num, optional, include_equip)
    return nosganglie_discard(self, discard_num, min_num, optional, include_equip, "luabawang")
end

function sgs.ai_cardneed.luabawang(to, card)
    return q(card,"isKindOf","Slash") or q(card,"isKindOf","Duel")
end

sgs.ai_skill_cardask["@luajiebing"] = function(self, data)
    local asker
    for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if q(p,"getMark","luajiebing") == 1 then
            asker = p
            break
        end
    end

    if asker and q(self,"isEnemy",self.player, asker) then return "." end

    self:sort(self.friends, "defense")
    local helper = self.friends[#self.friends]
    for _,friend in ipairs(self.friends) do
        if self:needToThrowArmor(friend) or (self:hasSkills(sgs.lose_equip_skill, friend)
            or (hasTuntianEffect(friend, true) and q(friend,"getPhase") == sgs.Player_NotActive)) then
            helper = friend
            break
        end
    end
    if q(self.player,"objectName") == q(helper,"objectName") then
        if self:needToThrowArmor(self.player) then
            local to_discard = self:askForDiscard("jiebing", 1, 1, false, true)
            if #to_discard > 0 then
                return to_discard[1]
            end
        end
        local cards = self.player:getCards("he")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        return cards[#cards]:getEffectiveId()
    end
    return "."
end

sgs.ai_chaofeng.luawuguotai_tongtang = 5



sgs.ai_skill_askforag.luatongtang = function(self, card_ids)
    local cards = {}
    for _,i in ipairs(card_ids) do
        local card = choice_card(self,i)
        table.insert(cards, card)
    end
    local players = {}
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if q(p,"getKingdom") == "wu" then
            table.insert(players, p)
        end
    end
    local acard, friend = card_need_player(self, players, cards)
    if not acard then acard = cards[1] end
    if not friend then friend = self.player end
    self:setStrategyMemory("mountainrumour.tongtang",q(friend,"objectName"))
    return q(acard,"getEffectiveId")
end

sgs.ai_skill_playerchosen.luatongtang = function(self, targets)
    local choice = tongtang_player(self)
    if not choice then choice = self.player end
    for _,p in sgs.qlist(targets) do
        if q(p,"objectName") == q(choice,"objectName") then
            return choice
        end
    end
    return targets[1]
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|luazhaoxu"

sgs.ai_fill_skill.luazhaoxu = function(self,inclusive,request)
    local card_num = q(self.player,"getHandcardNum")
    if card_num <= 1 then return nil end
    if q(self.player,"hasUsed","#luazhaoxucard") then return nil end

    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)

    self:sort(self.friends_noself, "defense")
    self:sort(self.enemies, "defense")

    local targets = {}

    local counts = card_num - 1

    for _,p in ipairs(self.friends_noself) do
        if q(p,"isMale") and q(self,"isWeak",p) then
            table.insert(targets, p)
            counts = counts - 1
        elseif q(p,"isMale") and q(p,"isWounded") and (q(self.player,"getLostHp") > #targets or q(self.player,"getMaxCards") < counts) then
            table.insert(targets, p)
            counts = counts - 1
        end
        if counts == 0 then break end
    end

    if #targets > 0 then

        local card_ids = {}

        for i=1,#targets+1 do
            table.insert(card_ids, cards[i]:getEffectiveId())
        end

        local target_names = {}

        for i=1,#targets do
            table.insert(target_names, targets[i]:objectName())
        end

        local card_str = ("#luazhaoxucard:"..table.concat(card_ids, "+")..":")--->"..table.concat(target_names, "+"))
        local card = q(self,"bindSkillCard","luazhaoxu",card_ids,request,nil,"#luazhaoxucard")
        return card
    end
    return nil
end

sgs.ai_skill_use_func["#luazhaoxucard"] = function(card, use, self,request)
    use.card = card
    if use.to then
        self:sort(self.friends_noself, "defense")

        local counts = card:subcardsLength()

        for _,p in ipairs(self.friends_noself) do
            if q(p,"isMale") and q(p,"isWounded") then
                use.to:append(p)
                counts = counts - 1
            end
            if counts == 0 then break end
        end
    end
    return
end


sgs.ai_skill_choice.luazhaoxucard = function(self, data)
    aiPlayerChat(self, "zhaoxu")
    return "zhaoxurecoverhp"
end

sgs.ai_use_priority.luazhaoxucard = 3



sgs.ai_chaofeng.luacaiwenji_shushen = 0

sgs.ai_skill_use["@@luashushenmr"] = function(self, prompt, method)
    local cards = self.player:getCards("he")
    local equips = {}
    for _,c in sgs.qlist(cards) do
        if q(c,"isKindOf","EquipCard") then
            table.insert(equips, c)
        end
    end
    if #equips == 0 then return "." end
    if not sgs.ai_skill_invoke.nosjushou(self, {}) then return "." end
    local card_ids = {}
    for _,c in ipairs(equips) do
        if not self.player:getArmor() or self.player:getArmor():objectName() ~= q(c,"objectName") or (q(c,"objectName") == "silver_lion" and q(self.player,"getLostHp") > 0)
            and (not self.player:getDefensiveHorse() or self.player:getDefensiveHorse():objectName() ~= q(c,"objectName")) then
            table.insert(card_ids, q(c,"getEffectiveId"))
        end
    end
    if #card_ids ~= 0 then
        aiPlayerChat(self, "shushen")
        return "#luashushenmrcard:"..table.concat(card_ids, "+")..":"
    end
    return "."
end

function sgs.ai_cardneed.luashushenmr(to, card)
    return q(card,"isKindOf","EquipCard")
end



sgs.ai_fill_skill.luahujiamr = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    local blackslashes = {}
    local redslashes = {}
    for _,card in ipairs(cards) do
        if q(card,"isKindOf","Slash") and q(card,"isBlack") then
            table.insert(blackslashes, card)
        elseif q(card,"isKindOf","Slash") and q(card,"isRed") then
            table.insert(redslashes, card)
        end
    end
    if #blackslashes < 2 and #redslashes < 2 then
        return nil
    end
    local selected = {}
    local trick = ""
    if #blackslashes >= 2 then
        selected = blackslashes
    else
        selected = redslashes
    end
    self:sortByUseValue(selected, true)
    local card_str = ("savage_assault:luahujiamr[to_be_decided:0]=%d+%d"):format(selected[1]:getId(), selected[2]:getId())
    local new_card = q(self,"bindTurnConversion","luahujiamr","SavageAssault",{name="savage_assault",skill_name="luahujiamr",suit=selected[1]:isRed()and sgs.Card_NoSuitRed or sgs.Card_NoSuitBlack,number=0,subcards={selected[1]:getId(),selected[2]:getId()}},request)
    assert(new_card)
    return new_card
end


sgs.ai_chaofeng.luazuoci_caokong = 0

sgs.ai_skill_cardask["@luahuanying"] = function(self, data)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,c in ipairs(cards) do
        if q(c,"getSuitString") == "club" then
            return q(c,"getEffectiveId")
        end
    end
    if #cards > 0 then
        return cards[1]:getEffectiveId()
    else
        return nil
    end
end

sgs.ai_skill_invoke.luahuanying = function(self, data)
    aiPlayerChat(self, "huanying")
    return true
end

sgs.ai_skill_askforag.luahuanying = function(self, card_ids)
    for _,i in ipairs(card_ids) do
        if choice_card(self,i):getSuitString() == "club" then
            if math.random(1, 4) > 1 then
                return i
            end
        else
            if math.random(1, 4) == 1 then
                return i
            end
        end
    end
    return card_ids[1]
end

sgs.ai_skill_choice.luahuanying = function(self, choice)
    local from = scope_player(self,"huanying_target")
    local damage = scope_damage(self,"huanying_damage")
    if from then
        if q(self,"isFriend",from) then
            return "no_question"
        elseif damage and damage.damage > 1 then
            return "question"
        elseif q(self.player,"getHp") > 2 or q(from,"getHp") <= 1 then
            return "question"
        else
            if math.random(1, 2) == 1 then
                return "question"
            end
        end
    end
    return "no_question"
end

sgs.ai_skill_invoke.luacaokong = function(self, data)
    if data:toString() == "caokong_a" or data:toString() == "caokong_b" then
        local players = self.room:getOtherPlayers(self.player)
        players = sgs.QList2Table(players)
        local to_selects = tuxi_targets(self, players, 3)
        if to_selects == {} then return false end
        local current_targets = scope_use(self,"caokong_targets")
        for _,p in ipairs(to_selects) do
            if not current_targets or not current_targets.to
                or not current_targets.to:contains(p) then
                return true
            end
        end
        return false
    else
        local card = scope_card(self,"caokong_card")
        if not q(card,"isKindOf","AOE") and not q(card,"isKindOf","GlobalEffect") then
            return true
        else
            if q(card,"isKindOf","AOE") and self:getAoeValue(card) then
                return true
            end
        end
        local use = self:evaluateCard(caokong_evaluation(self,card), dummy())
        if use.card then
            return true
        end
        return false
    end

end
sgs.ai_skill_playerchosen.luacaokong = function(self, targets)
    local players = self.room:getOtherPlayers(self.player)
    players = sgs.QList2Table(players)
    local to_selects = tuxi_targets(self, players, 3)
    local current_targets = scope_use(self,"caokong_targets")
    for _,p in ipairs(to_selects) do
        if targets:contains(p)  then
            if not current_targets or not current_targets.to
            or not current_targets.to:contains(p) then
                return p
            end
        end
    end
    return targets:first()
end
sgs.ai_skill_use["@@luacaokong"] = function(self, prompt)
    local card = scope_card(self,"caokong_card")
    local use = self:evaluateCard(caokong_evaluation(self,card), dummy())
    if not use.card then
        aiPlayerChat(self, "caokong")
        return "."
    end
    local targets = {}
    if use.card and use.to and not use.to:isEmpty() then
        for _,p in sgs.qlist(use.to) do
            table.insert(targets, q(p,"objectName"))
        end
    end
    local parse = string.format(q(card,"objectName")..":luacaokong[%s:%s]=%d", q(card,"getSuit"), q(card,"getNumber"), q(card,"getEffectiveId"))
    if #targets > 0 then
        parse = parse.."->"..table.concat(targets, "+")
    end
    return parse
end

sgs.ai_can_damagehp.luacaokong = function(self, from, card, to)
    if from and q(self,"isEnemy",from) and q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0
        and q(self,"canLoseHp",from, card, to)
    then
        return q(to,"getMark","luacaokong") == 0 and q(to,"hasSkills","luahuanying") and to:getPile("huanyingpile"):length() > 0
    end
end

sgs.ai_chaofeng.luashenyuanshao_mengzhu = 6

sgs.ai_skill_invoke.luamengzhu = function(self, data)
    local f_data = {}
    local damage = {}
    damage.to = self.player
    damage.damage = 1
    f_data.damage=damage -- Source does not pass f_data to guixin.
    if sgs.ai_skill_invoke.guixin(self, data) then
        aiPlayerChat(self, "mengzhu")
        return true
    end
    return false
end

for i=1,10 do
    sgs.ai_fill_skill["shisheng"..i] = function(self,inclusive,request)
        local cards = sgs.QList2Table(self.player:getCards("he"))
        self:sortByKeepValue(cards)
        local patterns = {"slash","fire_slash","thunder_slash","jink","peach","analeptic","nullification","snatch","dismantlement","collateral","ex_nihilo","duel","fire_attack","amazing_grace","savage_assault","archery_attack","god_salvation","iron_chain"}
        local choices = {}
        for _, name in ipairs(patterns) do
            local poi = r45_shisheng(self,name,{},true)
            if q(poi,"isAvailable",self.player) then
                table.insert(choices, name)
            end
        end

        if next(choices) and get_mark(self,"AI_do_not_invoke_shisheng"..i.."-Clear") == 0 and get_mark(self,"AI_do_not_invoke_shisheng-Clear") == 0 then
            local markcost = 0
            if i <= 2 then
                markcost = 0
            elseif i <= 6 then
                markcost = 1
            elseif i <= 9 then
                markcost = 2
            else
                markcost = 3
            end
            if q(self.player,"getMark","@wins") < markcost then return end
            local cost = 0
            if i <= 2 then
                cost = 1
            elseif i <= 5 then
                cost = 2
            elseif i == 6 then
                cost = 3
            elseif i <= 9 then
                cost = 1
            else
                cost = 0
            end
            local use_cards = {}
            for _,c in sgs.list(cards)do
                if #use_cards >= cost then break end
                if q(c,"getNumber") == 5 and i == 1 then
                    table.insert(use_cards, q(c,"getEffectiveId"))
                elseif q(c,"getNumber") == 10 and i == 2 then
                    table.insert(use_cards, q(c,"getEffectiveId"))
                elseif i == 3 then
                    for _,c2 in sgs.list(cards)do
                        if q(c,"getNumber") == q(c2,"getNumber") and q(c,"getSuit") == q(c2,"getSuit") and not table.contains(use_cards, q(c,"getEffectiveId")) and not table.contains(use_cards, q(c2,"getEffectiveId")) then
                            table.insert(use_cards, q(c,"getEffectiveId"))
                            table.insert(use_cards, q(c2,"getEffectiveId"))
                            break
                        end
                    end
                elseif i == 4 then
                    for _,c2 in sgs.list(cards)do
                        if q(c,"getNumber") == q(c2,"getNumber") and not table.contains(use_cards, q(c,"getEffectiveId")) and not table.contains(use_cards, q(c2,"getEffectiveId")) then
                            table.insert(use_cards, q(c,"getEffectiveId"))
                            table.insert(use_cards, q(c2,"getEffectiveId"))
                            break
                        end
                    end
                elseif i == 5 then
                    for _,c2 in sgs.list(cards)do
                        if q(c,"getSuit") == q(c2,"getSuit") and not table.contains(use_cards, q(c,"getEffectiveId")) and not table.contains(use_cards, q(c2,"getEffectiveId")) then
                            table.insert(use_cards, q(c,"getEffectiveId"))
                            table.insert(use_cards, q(c2,"getEffectiveId"))
                            break
                        end
                    end
                elseif i == 6 then
                    table.insert(use_cards, q(c,"getEffectiveId"))
                elseif q(c,"isKindOf","TrickCard") and i == 7 then
                    table.insert(use_cards, q(c,"getEffectiveId"))
                elseif q(c,"isKindOf","EquipCard") and i == 8 then
                    table.insert(use_cards, q(c,"getEffectiveId"))
                elseif q(c,"isKindOf","BasicCard") and i == 9 then
                    table.insert(use_cards, q(c,"getEffectiveId"))
                end
            end
            if #use_cards == 0 then return end
            if #use_cards == cost then
                return q(self,"bindSkillCard","shisheng"..i,use_cards,request,nil,"#shisheng_sc"..i)
            end
        end
    end
end

for i=1,10 do
    sgs.ai_skill_use_func["#shisheng_sc"..i] = function(card,use,self,request)
        use.card = card
        set_mark(self,"shisheng",i)
    end
end

sgs.ai_skill_use["@@shisheng"] = function(self, prompt, method)
    local pattern = scope(self,"shisheng_sel")
    if pattern ~= "" then
        local x = get_mark(self,"shisheng")
        set_mark(self,"shisheng",0)
        if x > 0 then
            local markcost = 0
            if x <= 2 then
                markcost = 0
            elseif x <= 6 then
                markcost = 1
            elseif x <= 9 then
                markcost = 2
            else
                markcost = 3
            end
            if q(self.player,"getMark","@wins") >= markcost then
                local use_card -- Constructed readonly with the original selected subcards below.
                local cost = 0
                if x <= 2 then
                    cost = 1
                elseif x <= 5 then
                    cost = 2
                elseif x == 6 then
                    cost = 3
                elseif x <= 9 then
                    cost = 1
                else
                    cost = 0
                end
                local cards = sgs.QList2Table(self.player:getCards("he"))
                self:sortByKeepValue(cards)
                local use_cards = {}
                for _,c in sgs.list(cards)do
                    if #use_cards >= cost then break end
                    if q(c,"getNumber") == 5 and x == 1 then
                        table.insert(use_cards, q(c,"getEffectiveId"))
                    elseif q(c,"getNumber") == 10 and x == 2 then
                        table.insert(use_cards, q(c,"getEffectiveId"))
                    elseif x == 3 then
                        for _,c2 in sgs.list(cards)do
                            if q(c,"getNumber") == q(c2,"getNumber") and q(c,"getSuit") == q(c2,"getSuit") and not AIValue.sameLegacyIdentity(c,c2) and not table.contains(use_cards, q(c,"getEffectiveId")) and not table.contains(use_cards, q(c2,"getEffectiveId")) then
                                table.insert(use_cards, q(c,"getEffectiveId"))
                                table.insert(use_cards, q(c2,"getEffectiveId"))
                                break
                            end
                        end
                    elseif x == 4 then
                        for _,c2 in sgs.list(cards)do
                            if q(c,"getNumber") == q(c2,"getNumber") and not AIValue.sameLegacyIdentity(c,c2) and not table.contains(use_cards, q(c,"getEffectiveId")) and not table.contains(use_cards, q(c2,"getEffectiveId")) then
                                table.insert(use_cards, q(c,"getEffectiveId"))
                                table.insert(use_cards, q(c2,"getEffectiveId"))
                                break
                            end
                        end
                    elseif x == 5 then
                        for _,c2 in sgs.list(cards)do
                            if q(c,"getSuit") == q(c2,"getSuit") and not AIValue.sameLegacyIdentity(c,c2) and not table.contains(use_cards, q(c,"getEffectiveId")) and not table.contains(use_cards, q(c2,"getEffectiveId")) then
                                table.insert(use_cards, q(c,"getEffectiveId"))
                                table.insert(use_cards, q(c2,"getEffectiveId"))
                                break
                            end
                        end
                    elseif x == 6 then
                        table.insert(use_cards, q(c,"getEffectiveId"))
                    elseif q(c,"isKindOf","TrickCard") and x == 7 then
                        table.insert(use_cards, q(c,"getEffectiveId"))
                    elseif q(c,"isKindOf","EquipCard") and x == 8 then
                        table.insert(use_cards, q(c,"getEffectiveId"))
                    elseif q(c,"isKindOf","BasicCard") and x == 9 then
                        table.insert(use_cards, q(c,"getEffectiveId"))
                    end
                end
                if #use_cards == cost then
                    use_card=r45_shisheng(self,pattern,use_cards,false)
                    local dummyuse = self:evaluateCard(use_card, dummy())
                    local targets = {}
                    if not dummyuse.to:isEmpty() then
                        for _, p in sgs.qlist(dummyuse.to) do
                            table.insert(targets, q(p,"objectName"))
                        end
                        if #targets > 0 then
                            return use_card:toString() .. "->" .. table.concat(targets, "+")
                        end
                    end
                end
            end
            add_mark(self,"AI_do_not_invoke_shisheng"..x.."-Clear")
        end
    else
        return "#shisheng_card:.:"
    end
    return "."
end

for i=1,10 do
    sgs.ai_skill_choice["shisheng_sc_re"..i] = function(self, choices, data)
        local shisheng_vs_card = {}
        local items = choices:split("+")
        for _, card_name in ipairs(items) do
            if card_name ~= "esc" then
                local use_card = r45_shisheng(self,card_name,{},true)
                table.insert(shisheng_vs_card, use_card)
            end
        end
        self:sortByUsePriority(shisheng_vs_card)
        for _, c in ipairs(shisheng_vs_card) do
            if table.contains(items, q(c,"objectName")) then
                local dummyuse = self:evaluateCard(c)
                if not dummyuse.to:isEmpty() then
                    for _, p in sgs.qlist(dummyuse.to) do
                        self:setStrategyMemory("mountainrumour.ai_shisheng_sc_re"..i.."_card_name",q(c,"objectName"))
                        return q(c,"objectName")
                    end
                end
            end
        end
        -- Original console-only diagnostic; no game or strategy state.
        add_mark(self,"AI_do_not_invoke_shisheng"..i.."-Clear")
        return "esc"
    end
end
sgs.ai_skill_choice["shisheng_card"] = function(self, choices, data)
    local shisheng_vs_card = {}
    local items = choices:split("+")
    for _, card_name in ipairs(items) do
        if card_name ~= "esc" then
            local use_card = r45_shisheng(self,card_name,{},true)
            table.insert(shisheng_vs_card, use_card)
        end
    end
    self:sortByUsePriority(shisheng_vs_card)
    for _, c in ipairs(shisheng_vs_card) do
        if table.contains(items, q(c,"objectName")) then
            local dummyuse = self:evaluateCard(c)
            if not dummyuse.to:isEmpty() then
                for _, p in sgs.qlist(dummyuse.to) do
                    self:setStrategyMemory("mountainrumour.ai_shisheng_card_name",q(c,"objectName"))
                    return q(c,"objectName")
                end
            end
        end
    end
    add_mark(self,"AI_do_not_invoke_shisheng-Clear")
    return "esc"
end
