-- Source: b6025acc ai/sy-ai.lua.
local known = AIValue.requireKnown

local function known_card(self,id)return self:getKnownCardById(id)end
local function scoped_use(self)
 local c=self:getDecisionContext().sy;if type(c)~="table"then ai_unsupported("Sy owner Luanzheng tag unavailable","sy_luanzheng")end
 local row=known(c.luanzheng_use,"luanzheng_use");local use={to=AIList.new({})};if row==false then return use end
 if row.from and row.from~=""then use.from=self.room:findPlayerByObjectName(row.from)end
 if row.card then use.card=known(CardView.new(row.card),"Luanzheng card")end
 for _,name in ipairs(known(row.to,"Luanzheng targets"))do use.to:append(self.room:findPlayerByObjectName(name))end
 return use
end

ai_skill_invoke.sy_xiuluo = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
    if not use.from then return (false) or false end
    if self:isFriend(use.from) then return (false) or false end
    if use.card:isKindOf("Duel") then return (true) or false end
    if use.card:isKindOf("Slash") or use.card:isNDTrick() then
        if use.from:hasSkills("tieji|liegong|mouliegongf|liegong|sr_benxi|fuqi|jiaozi|luoyi|wushuang") then return (true) or false end
        if self:getCardsNum("Slash") >= 2 or self.player:getHandcardNum() >= use.from:getHandcardNum() or use.from:getHandcardNum() - self.player:getHandcardNum() <= 2 then return (true) or false end
        if use.from:hasWeapon("axe") or use.card:getStrategyFlag("drank") then return (true) or false end
    end
    return false

end

function sgs.ai_cardneed.sy_wushuang(to,card,self)
    if not self:willSkipPlayPhase(to) then
        return card:isDamageCard() and math.fmod(card:getNumber(), 2) ~= 0
    end
end

sgs.ai_ajustdamage_from.sy_hengxing = function(self,from,to,card,nature)
    if from:getPhase() ~= sgs.Player_Play
    then return 1 end
end

ai_skill_invoke.sy_lingnue = true
sgs.ai_suppress_intention["sy_baozheng"] = true

ai_skill_invoke.sy_renji = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    if self:needKongcheng(self.player, true) then return (false) or false end
    return (true) or false
end

sgs.ai_can_damagehp.sy_renji = function(self,from,card,to)
    return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
    and self:canLoseHp(from, card, to)
end

ai_skill_invoke.sy_guiming = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local dying = data:toDying()
    local peaches = 1 - dying.who:getHp()
    return (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches) or false
end

sgs.ai_canNiepan_skill.sy_guiming = function(player)
    return player:getStrategyMark("@guiming") > 0
end

sgs.ai_can_damagehp.sy_fangu = function(self,from,card,to)
    return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
    and self:canLoseHp(from, card, to) and from and not self:isFriend(from)
end

ai_skill_invoke.sy_canlue = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local move = data:toMoveOneTime()
    if move and move.from and move.card_ids and move.card_ids:length() > 0 then
        local from = self.room:findPlayerByObjectName(move.from:objectName())
        if from then return (self:isEnemy(from)) or false end
    end
    return false
end

sgs.ai_skill_playerchosen.sy_luanzheng = function(self, targets)
    local room = self.room
    local use = scoped_use(self)
    if not use.from then return nil end
    local to = use.to:at(0)
    if use.card:isKindOf("Peach") then
        local friends = {}
        for _, t in sgs.qlist(targets) do
            if self:isFriend(t) and t:isWounded() then table.insert(friends, t) end
        end
        self:sort(friends, "chaofeng")
        return friends[1]
    elseif use.card:isKindOf("ExNihilo") then
        local tos = {}
        for _, t in sgs.qlist(targets) do
            if self:isFriend(t) and not self:needKongcheng(t, true) then
                table.insert(tos, t)
            end
        end
        self:sort(tos, "chaofeng")
        return tos[1]
    elseif use.card:isKindOf("Slash") then
        local tos = {}
        for _, t in sgs.qlist(targets) do
            if self:isEnemy(t) and (not to:hasSkills("leiji|guixin|sgkgodguixin|sgkgodyinshi")) then
                table.insert(tos, t)
            end
        end
        self:sort(tos, "chaofeng")
        return tos[1]
    else
        local tos = {}
        for _, t in sgs.qlist(targets) do
            if self:isEnemy(t) then
                table.insert(tos, t)
            end
        end
        self:sort(tos, "chaofeng")
        return tos[1]
    end
end

sgs.ai_skill_playerchosen.sy_shiao = function(self, targets)
    local tos = {}
    local slash = self:getEvaluationCard("slash")
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) then
            if not self:strategyProhibited(self.player, p, slash) and self:slashIsEffective(slash, p) and self:isGoodTarget(p, self.enemies, slash) then table.insert(tos, p) end
        end
    end
    if #tos > 0 then
        self:sort(tos, "defenseSlash")
        return tos[1]
    else
        return nil
    end
    return nil
end

ai_skill_invoke.sy_kuangxi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local room = self.room
    local use = data:toCardUse()
    if not use.card then return (false) or false end
    if not use.card:isKindOf("TrickCard") then return (false) or false end
    local F = 0
    local E = 0
    if use.card:isKindOf("AmazingGrace") or use.card:isKindOf("GodSalvation") then
        for _, p in sgs.qlist(use.to) do
            if self:isFriend(p) then
                F = F + 1
            end
            if self:isEnemy(p) then
                E = E + 1
            end
        end
        if ((E - F >= 2) or (E > 0 and F <= 1)) and not self:isWeak() then return (true) or false else return (false) or false end
    end
    F = 0
    E = 0
    if use.card:isKindOf("IronChain") then
        for _, p in sgs.qlist(use.to) do
            if self:isFriend(p) then
                F = F + 1
            end
            if self:isEnemy(p) then
                E = E + 1
            end
        end
        if F == 0 and E > 0 then
            if math.random(1, 5) > 3 then return (true) or false else return (false) or false end
        end
    end
    F = 0
    E = 0
    for _, p in sgs.qlist(use.to) do
        if self:isFriend(p) then
            F = F + 1
        end
        if self:isEnemy(p) then
            E = E + 1
        end
    end
    if F == 0 and E > 0 then
        if math.random(1, 100) >= 50 then return (true) or false else return (false) or false end
    end
    return (false) or false
end






































































ai_skill_invoke.sy_bujiao = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    if not self:isFriend(to) then return (true) or false end
    if self:isEnemy(to) and (not self:isWeak()) and self:objectiveLevel(to) >= 3 then
        return (true) or false
    end
    return (false) or false
end

ai_skill_invoke.sy_taiping = true

ai_fill_skill.sy_yaohuo = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyHasUsed("#sy_yaohuoCard") then return nil end
    if #self.enemies <= 0 then return nil end
    if self.player:isKongcheng() then return nil end
    return self:bindSkillCard("sy_yaohuo", {}, request, nil, "#sy_yaohuoCard")
end

ai_card_use["#sy_yaohuoCard"] = function(self, card, use, request)
    if self.player:getStrategyHasUsed("#sy_yaohuoCard") then return nil end
    self:sort(self.enemies, "handcard")
    self.enemies = sgs.reverse(self.enemies)
    local target
    local a = self.player:getHandcardNum() + self.player:getEquips():length()
    local b = -999
    local less = {}
    for _, k in ipairs(self.enemies) do
        if k:getHandcardNum() <= a and not k:isKongcheng() then table.insert(less, k) end
    end
    for _, m in ipairs(less) do
        b = math.max(b, m:getHandcardNum())
    end
    for _, enemy in ipairs(self.enemies) do
        if enemy:getHandcardNum() == b then
            target = enemy
            break
        end
    end
    if not target then
        for _, enemy in ipairs(self.enemies) do
            if a < b then
                if a > enemy:getHandcardNum() and (not enemy:isKongcheng()) and a - enemy:getHandcardNum() <= 2 then
                    target = enemy
                    break
                end
            end
        end
    end
    if not target then
        local c = -999
        local less_skill_num = {}
        for _, enemy in ipairs(self.enemies) do
            if enemy:getVisibleSkillList():length() <= a then
                local has_bad = false
                for _, sk in sgs.qlist(enemy:getVisibleSkillList()) do
                    if string.find(sgs.bad_skills, sk:objectName()) then
                        has_bad = true
                        break
                    end
                end
                if not has_bad then table.insert(less_skill_num, enemy) end
            end
        end
        for _, m in ipairs(less_skill_num) do
            c = math.max(c, m:getVisibleSkillList():length())
        end
        for _, enemy in ipairs(self.enemies) do
            if enemy:getVisibleSkillList():length() == c then
                target = enemy
                break
            end
        end
    end
    if target then
        use.card = card
        if use.to then use.to:append(target) end
    end
end


ai_skill_choice.sy_yaohuo = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local n = math.random(1, 100)
    local yaohuo = choices:split("+")
    if n >= 1 and n <= 50 then
        return ai_choice_result((yaohuo[1]), options)
    else
        return ai_choice_result((yaohuo[2]), options)
    end

    return ai_choice_result(nil, options)
end

sgs.ai_use_value["sy_yaohuoCard"] = 10
sgs.ai_use_priority["sy_yaohuoCard"] = 9.3
sgs.ai_card_intention["sy_yaohuoCard"] = 90

ai_skill_invoke.sy_sanzhi = true

ai_fill_skill.sy_zuijiu = function(self, options, request)
    local inclusive = options and options.inclusive

    if self:isWeak() then return nil end
    if #self.enemies == 0 then return nil end
    local E = 0
    local slash = self:getEvaluationCard("slash")
    for _, enemy in ipairs(self.enemies) do
        if not self:strategyProhibited(self.player, enemy, slash) then E = E + 1 end
    end
    if E == 0 then return nil end
    if self.player:getHandcardNum() - self.player:getStrategyMark("&sy_zuijiu") <= 2 then return nil end
    return self:bindSkillCard("sy_zuijiu", {}, request, nil, "#sy_zuijiuCard")
end

ai_card_use["#sy_zuijiuCard"] = function(self, card, use, request)
    use.card = card
end

ai_skill_use["@@sy_zuijiuNormalSlash"] = function(self, prompt, request)
    if #self.enemies == 0 then return "." end
    self:sort(self.enemies, "defense")
    local slash = self:getEvaluationCard("slash")
    local target
    for _, enemy in ipairs(self.enemies) do
        if not self:strategyProhibited(self.player, enemy, slash) and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, nil) then
            target = enemy
            break
        end
    end
    if not target then target = self:findPlayerToSlash(false) end
    return "#sy_zuijiuNormalSlashCard:.:->" .. target:objectName()
end

ai_skill_invoke.sy_huangyin = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    if self:needKongcheng(self.player, true) then return (false) or false end
    return (true) or false
end

ai_fill_skill.sy_luansi = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyHasUsed("#sy_luansiCard") then return nil end
    if #self.enemies == 0 then return nil end
    local j = 0
    for _, p in ipairs(self.enemies) do
        if (not p:isKongcheng()) then j = j + 1 end
    end
    if j < 1 then return nil end
    return self:bindSkillCard("sy_luansi", {}, request, nil, "#sy_luansiCard")
end

ai_card_use["#sy_luansiCard"] = function(self, card, use, request)
    if self.player:getStrategyHasUsed("#sy_luansiCard") then return nil end
    self:sort(self.enemies, "defense")
    local tar1, tar2
    for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() then
            tar1 = p
            break
        end
    end
    if not tar2 then
        for _, m in ipairs(self.enemies) do
            if m:objectName() ~= tar1:objectName() and (not m:isKongcheng()) then
                tar2 = m
                break
            end
        end
    end
    if not tar2 then
        tar2 = self.player
    end
    if tar1 and tar2 then
        use.card = card
        if use.to then
            use.to:append(tar1)
            use.to:append(tar2)
        end
    else
        return nil
    end
end

sgs.ai_use_value["sy_luansiCard"] = 10
sgs.ai_use_priority["sy_luansiCard"] = 8.5
sgs.ai_card_intention["sy_luansiCard"] = 0

ai_fill_skill.sy_dihui = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyHasUsed("#sy_dihuiCard") then return nil end
    if #self.enemies <= 0 then return nil end
    if self.player:getHp() <= 0 then return nil end
    return self:bindSkillCard("sy_dihui", {}, request, nil, "#sy_dihuiCard")
end

ai_card_use["#sy_dihuiCard"] = function(self, card, use, request)
    if self.player:getStrategyHasUsed("#sy_dihuiCard") then return nil end
    local room = self.room
    local no_min_hp = {}
    local _minhp = 99999
    local players = room:getOtherPlayers(self.player)
    for _, p in sgs.qlist(room:getOtherPlayers(self.player)) do
        _minhp = math.min(_minhp, p:getHp())
    end
    for _, t in sgs.qlist(room:getOtherPlayers(self.player)) do
        if t:getHp() > _minhp then
            table.insert(no_min_hp, t)
        end
    end
    local target1
    if #no_min_hp == 0 then return nil end
    self:sort(no_min_hp, "chaofeng")
    for _, _min in ipairs(no_min_hp) do
        if self:isFriend(_min) then
            target1 = _min
            break
        end
    end
    if not target1 then
        for _, _to in ipairs(no_min_hp) do
            if self:isEnemy(_to) then
                target1 = _to
                break
            end
        end
    end
    if not target1 then
        target1 = self.player
    end
    if target1 then
        use.card = card
        if use.to then
            use.to:append(target1)
        end
    end
end

sgs.ai_skill_playerchosen.sy_dihui = function(self, targets)
    local players = {}
    for _, p in sgs.qlist(targets) do
        if self:isEnemy(p) then table.insert(players, p) end
    end
    if #players > 0 then
        self:sort(players, "hp")
        return players[1]
    else
        self:sort(self.enemies, "hp")
        return self.enemies[1]
    end
end


sgs.ai_use_value["sy_dihuiCard"] = 9
sgs.ai_use_priority["sy_dihuiCard"] = 7

sgs.ai_damage_reason_suppress_intention["sy_dihui"] = true

local function canMoveCard(self,target)
    if not target:isKongcheng() then return true end
    local others = self.room:getOtherPlayers(target)
    local tos = AIList.new({})
    if target:getJudgingArea():length() > 0 then
        for _, card in sgs.qlist(target:getJudgingArea()) do
            for _, pe in sgs.qlist(others) do
                if not self:strategyProhibited(target, pe, card) and not pe:containsTrick(card:objectName()) and (not tos:contains(pe)) then
                    tos:append(pe)
                end
            end
        end
    end
    if target:hasEquip() then
        for _, card in sgs.qlist(target:getEquips()) do
            local index = card:getEquipSlot()
            for _, pe in sgs.qlist(others) do
                if pe:getEquip(index) == nil and pe:hasEquipArea(index) and (not tos:contains(pe)) then
                    tos:append(pe)
                end
            end
        end
    end
    if tos:isEmpty() then return false else return true end
end

ai_fill_skill.sy_chanxian = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyHasUsed("#sy_chanxianCard") then return nil end
    local can_move = {}
    for _, pe in sgs.qlist(self.room:getAlivePlayers()) do
        if canMoveCard(self,pe) then table.insert(can_move, pe) end
    end
    if #can_move == 0 or #self.enemies == 0 then return nil end
    return self:bindSkillCard("sy_chanxian", {}, request, nil, "#sy_chanxianCard")
end

ai_card_use["#sy_chanxianCard"] = function(self, card, use, request)
    local target
    local can_move = {}
    for _, pe in sgs.qlist(self.room:getAlivePlayers()) do
        if canMoveCard(self,pe) then table.insert(can_move, pe) end
    end
    if #can_move == 0 then return nil end
    self:sort(can_move, "defenseSlash")
    for _, pe in ipairs(can_move) do
        if self:isEnemy(pe) then
            target = pe
            break
        end
    end
    if not target then
        target = can_move[1]
    end
    if target then
        use.card = card
        if use.to then use.to:append(target) end
    end
end

sgs.ai_skill_playerchosen.sy_chanxian = function(self, targets)
    local move_to = {}
    for _, ap in sgs.qlist(targets) do
        if self:isEnemy(ap) or self.player:getSeat() == ap:getSeat() then
            table.insert(move_to, ap)
        end
    end
    self:sort(move_to, "hp")
    local target
    for _, to in ipairs(move_to) do
        if self:isEnemy(to) then
            target = to
            break
        end
    end
    if not target then
        for _, to in ipairs(move_to) do
            if self.player:getSeat() == to:getSeat() then
                target = to
                break
            end
        end
    end
    if not target then
        target = move_to[1]
    end
    return target
end


sgs.ai_use_value["sy_chanxianCard"] = 6
sgs.ai_use_priority["sy_chanxianCard"] = 0

sgs.ai_suppress_intention["sy_chanxian"] = true

local function canShenji(lvbu)
    if lvbu:getKnownGeneralName() == "sy_lvbu1" then return true end
    if lvbu:getKnownGeneralName() == "sy_lvbu2" then return true end
    if lvbu:getGeneral2Name() == "sy_lvbu1" then return true end
    if lvbu:getGeneral2Name() == "sy_lvbu2" then return true end
    if lvbu:hasSkills("shenji|sy_shenji") then return true end
    return false
end


ai_skill_invoke["#W_recast"] = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    for _, skill in sgs.qlist(self.player:getVisibleSkillList()) do
        if string.find(skill:objectName(), "xuanfeng") then return (false) or false end
    end
    local card_use = data:toCardUse()
    local card = card_use.card
    if card and card:isKindOf("DefensiveHorse") then
        if not self.player:getDefensiveHorse() then
            return (false) or false
        else
            if math.random(1, 100) <= 50 then return (true) or false else return (false) or false end
        end
    end
    if card and card:isKindOf("OffensiveHorse") then
        if not self.player:getOffensiveHorse() then
            return (false) or false
        else
            if math.random(1, 100) <= 50 then return (true) or false else return (false) or false end
        end
    end
    if not self.player:getWeapon() then
        if canShenji(self.player) then
            if not card:isKindOf("Crossbow") then
                return (true) or false
            else
                return (false) or false
            end
        else
            return (false) or false
        end
    else
        if self:doDisCard(self.player, self.player:getWeapon():getEffectiveId()) then return (false) or false end
        if not card:isKindOf("Crossbow") then
            if canShenji(self.player) then
                return (true) or false
            else
                if math.random(1, 100) <= 75 then return (true) or false else return (false) or false end
            end
        else
            return (false) or false
        end
    end
    return (false) or false
end












































ai_skill_choice["sy_huoxin"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local huoxin = choices:split("+")
    local caifuren = self.room:findPlayerBySkillName("sy_huoxin")
    if self:isFriend(caifuren) then
        return ai_choice_result((huoxin[1]), options)
    else
        return ai_choice_result((huoxin[math.random(1, #huoxin)]), options)
    end

    return ai_choice_result(nil, options)
end

sgs.ai_ajustdamage_from.sy_zhuzai = function(self,from,to,card,nature)
    if card and card:isKindOf("TrickCard")
    then return 1 end
end

sgs.ai_ajustdamage_to.sy_zhuzai = function(self,from,to,card,nature)
    if card and card:isKindOf("TrickCard")
    then return -1 end
end

ai_fill_skill.sy_zhiheng = function(self, options, request)
    local inclusive = options and options.inclusive

    if not self.player:getStrategyHasUsed("#sy_zhiheng") then
        return self:legacySkillSeed("sy_zhiheng", "#sy_zhiheng", request)
    end
end

ai_card_use["#sy_zhiheng"] = function(self, card, use, request)
    local unpreferedCards = {}
    local cards = sgs.QList2Table(self.player:getHandcards())

    if self.player:getHp() < 3 then
        local zcards = self.player:getCards("he")
        local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
        local wansha = self.player:getTag("JilveWansha")
        if wansha ~= nil and type(wansha) ~= "string" then ai_unsupported("owner JilveWansha is unknown","JilveWansha") end
        local keep_slash = wansha ~= nil and wansha ~= "" and wansha ~= "0" and wansha:lower() ~= "false"
        for _, zcard in sgs.qlist(zcards) do
            if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
                local shouldUse = true
                if isCard("Slash", zcard, self.player) and not use_slash then
                    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
                    self:useBasicCard(zcard, dummy_use)
                    if dummy_use.card then
                        if keep_slash then shouldUse = false end
                        if dummy_use.to then
                            for _, p in sgs.qlist(dummy_use.to) do
                                if p:getHp() <= 1 then
                                    shouldUse = false
                                    if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
                                    break
                                end
                            end
                            if dummy_use.to:length() > 1 then shouldUse = false end
                        end
                        if not self:isWeak() then shouldUse = false end
                        if not shouldUse then use_slash = true end
                    end
                end
                if zcard:getTypeId() == sgs.Card_TypeTrick then
                    local dummy_use = { isDummy = true }
                    self:useTrickCard(zcard, dummy_use)
                    if dummy_use.card then shouldUse = false end
                end
                if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
                    local dummy_use = { isDummy = true }
                    self:useEquipCard(zcard, dummy_use)
                    if dummy_use.card then shouldUse = false end
                    if keep_weapon and zcard:getKnownEffectiveId() == keep_weapon:getKnownEffectiveId() then shouldUse = false end
                end
                if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
                if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
                if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then shouldUse = false end
                if isCard("Jink", zcard, self.player) and not keep_jink then
                    keep_jink = true
                    shouldUse = false
                end
                if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
                    keep_analeptic = true
                    shouldUse = false
                end
                if shouldUse then table.insert(unpreferedCards, zcard:getKnownId()) end
            end
        end
    end

    if #unpreferedCards == 0 then
        local use_slash_num = 0
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            if card:isKindOf("Slash") then
                local will_use = false
                if use_slash_num <= card:getTargetModResidue(self.player) then
                    local dummy_use = { isDummy = true }
                    self:useBasicCard(card, dummy_use)
                    if dummy_use.card then
                        will_use = true
                        use_slash_num = use_slash_num + 1
                    end
                end
                if not will_use then table.insert(unpreferedCards, card:getKnownId()) end
            end
        end

        local num = self:getCardsNum("Jink") - 1
        if self.player:getArmor() then num = num + 1 end
        if num > 0 then
            for _, card in ipairs(cards) do
                if card:isKindOf("Jink") and num > 0 then
                    table.insert(unpreferedCards, card:getKnownId())
                    num = num - 1
                end
            end
        end
        for _, card in ipairs(cards) do
            if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
                or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
                table.insert(unpreferedCards, card:getKnownId())
            elseif card:getTypeId() == sgs.Card_TypeTrick then
                local dummy_use = { isDummy = true }
                self:useTrickCard(card, dummy_use)
                if not dummy_use.card then table.insert(unpreferedCards, card:getKnownId()) end
            end
        end

        if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
            table.insert(unpreferedCards, self.player:getWeapon():getId())
        end

        if self:needToThrowArmor() then
            table.insert(unpreferedCards, self.player:getArmor():getId())
        end

        if self.player:getOffensiveHorse() and self.player:getWeapon() then
            table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
        end
    end

    for index = #unpreferedCards, 1, -1 do
        if known_card(self,unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then
            table.removeOne(unpreferedCards, unpreferedCards[index])
        end
    end

    local use_cards = {}
    for index = #unpreferedCards, 1, -1 do
        if not self.player:isJilei(known_card(self,unpreferedCards[index])) then table.insert(use_cards, unpreferedCards[index]) end
    end

    if #use_cards > 0 then
        use.card = self:bindSkillCard("sy_zhiheng", use_cards, request, nil, "#sy_zhiheng")
        return
    end
end

sgs.ai_use_value["sy_zhiheng"] = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority["sy_zhiheng"] = sgs.ai_use_priority.ZhihengCard
sgs.dynamic_value.benefit["sy_zhiheng"] = sgs.dynamic_value.benefit.ZhihengCard

function sgs.ai_cardneed.sy_zhiheng(to, card)
    return not card:isKindOf("Jink")
end

local function countJuewangSkills(target)
    local n = 0
    if target:hasSkill("jw_chunbai") then n = n + 1 end
    if target:hasSkill("jw_heiyang") then n = n + 1 end
    if target:hasSkill("jw_shenchao") then n = n + 1 end
    if target:hasSkill("jw_shenglang") then n = n + 1 end
    if target:hasSkill("jw_ruanruo") then n = n + 1 end
    if target:hasSkill("jw_canmeng") then n = n + 1 end
    return n
end

ai_fill_skill.sy_zhongzhang = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyHasUsed("#sy_zhongzhang") then return nil end
    return self:bindSkillCard("sy_zhongzhang", {}, request, nil, "#sy_zhongzhang")
end

ai_card_use["#sy_zhongzhang"] = function(self, card, use, request)
    self:sort(self.enemies, "defense")
    local target
    for _, enemy in ipairs(self.enemies) do
        if self:objectiveLevel(enemy) >= 3 and countJuewangSkills(enemy) < 3 then
            target = enemy
            break
        end
    end
    if not target then
        for _, enemy in ipairs(self.enemies) do
            if countJuewangSkills(enemy) == 0 and (not self:isWeak()) then
                target = enemy
                break
            end
        end
    end
    if not target then
        target = self.player
    end
    if target then
        use.card = card
        if use.to then use.to:append(target) end
    end
end


sgs.ai_use_value["sy_zhongzhang"] = 10
sgs.ai_use_priority["sy_zhongzhang"] = sgs.ai_use_priority.ExNihilo - 0.2
sgs.ai_card_intention["sy_zhongzhang"] = 100

ai_skill_invoke.sy_xiaoshi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local dying = data:toDying()
    local peaches = 1 - dying.who:getHp()
    if self.player:getStrategyMark("@xiaoshi") > 0 then
        return (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches) or false
    end
    return (false) or false
end

sgs.ai_canNiepan_skill.sy_xiaoshi = function(player)
    return player:getStrategyMark("@xiaoshi") > 0
end

sgs.ai_skill_cardask["@xiaoshiask"] = function(self, data)
    local miku = data:toPlayer()
    if self:isFriend(miku) then return "." end
end

ai_skill_invoke.sy_beiyuan = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local damage = data:toDamage()
    if self:isFriend(damage.from) then
        return (false) or false
    end
    return (true) or false
end

sgs.ai_can_damagehp.sy_beiyuan = function(self,from,card,to)
    if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
    and self:canLoseHp(from, card, to)
    then
        return self:isEnemy(from)
    end
end

ai_skill_invoke.sy_jiancheng = true


sgs.ai_skill_cardask["@jiancheng-discard"] = function(self,data, pattern)
    local target = data:toPlayer()
    if self:isFriend(target) then return "." end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        if self:matchesDiscardPattern(pattern, h)
        then return h:getKnownEffectiveId() end
        if h:getSuitString() == pattern:split("|")[2]
        then return h:getKnownEffectiveId() end
    end
    return "."
end

sgs.ai_ajustdamage_from.sy_baodao = function(self,from,to,slash,nature)
    if slash and slash:isKindOf("Slash") and to:isKongcheng()
    then return 1 end
end

sgs.ai_skill_playerchosen.sy_xushu = function(self, targets)
    self:sort(self.enemies, "defense")
    for _,enemy in ipairs(self.enemies) do
        if enemy then
            return enemy
        end
    end
    return self.enemies[1]
end

ai_skill_invoke.sy_xishou = true

ai_skill_invoke.sy_caoying = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:getStrategyMark("caoying_AI") > 0 then
            target = p
            break
        end
    end
    return (self:isEnemy(target) and self:doDisCard(target, "he")) or false
end

ai_skill_invoke.sy_shengjian_black = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (#self.enemies > 0) or false
end

sgs.ai_skill_playerchosen.sy_shengjian_black = function(self, targets)
    self:sort(self.enemies, "defense")
    local enemies = {}
    for _, enemy in ipairs(self.enemies) do
        if math.abs(self.player:getEquips():length() - enemy:getEquips():length()) > 0 then
            table.insert(enemies, enemy)
        end
    end
    if #enemies > 0 then
        return enemies[1]
    else
        return self.enemies[1]
    end
end

ai_skill_invoke.sy_fengzhan = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (#self.enemies > 0) or false
end

sgs.ai_skill_playerchosen.sy_fengzhan = function(self, targets)
    self:updatePlayers()
    self:sort(self.enemies)
    local target
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            target = enemy
            break
        end
    end
    if target then
        return target
    else
        return nil
    end
end

ai_skill_use["@@sy_baofeng"] = function(self, prompt, request)
    local cardToUse
    for _,card in sgs.list(self.player:getHandcards()) do
        if card:isKindOf("Slash") then
            cardToUse = card
        end
    end
    if cardToUse then
        local enemytargets = {}
        for _, enemy in ipairs(self.enemies) do
            if  (self:objectiveLevel(enemy) >= 3)
                and not self:needToLoseHp(enemy) and self:isGoodTarget(enemy, self.enemies, nil)
                and #enemytargets < 2  then
                table.insert(enemytargets, enemy:objectName())
            end
        end
        if #enemytargets > 1 then
            return "#sy_baofengCard:".. cardToUse:getKnownEffectiveId() ..":->" .. table.concat(enemytargets, "+")
        end
    end
end

ai_skill_invoke.sy_wuqiao = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
    if use.to:contains(self.player) and use.from then
        return (self:isEnemy(use.from)) or false
    end
    local damage = data:toDamage()
    if damage.from:objectName() == self.player:objectName() then
        return (self:isEnemy(damage.to)) or false
    end
    return false

end

ai_skill_invoke.sy_fengying = true

sgs.ai_ajustdamage_to.sy_fengying = function(self, from, to, card, nature)
    if from and from:distanceTo(to) > 1
    then
        return -99
    end
end

ai_skill_invoke.sy_juexi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if (not enemy:faceUp()) and enemy:getStrategyMark("@fiercewind") > 0 then
            table.insert(targets, enemy)
        end
    end
    return (#targets > 0) or false
end

ai_skill_invoke.sy_qinggang = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local damage = data:toDamage()
    return (self:isEnemy(damage.to)) or false
end

sgs.ai_skill_discard.sy_qinggang = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
    local zhaoyun
    if self.room:findPlayerBySkillName("sy_qinggang") then zhaoyun = self.room:findPlayerBySkillName("sy_qinggang") end
    if zhaoyun and self:needToLoseHp(self.player, zhaoyun) then return to_discard end
    local n = math.random(1, 100)
    if self.player:getStrategyFlag("qinggang_AI") then
        if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then
            if n <= 95 then
                return to_discard
            else
                local cards = sgs.QList2Table(self.player:getCards("h"))
                self:sortByKeepValue(cards)
                local index = 0
                for i = #cards, 1, -1 do
                    local card = cards[i]
                    if (not isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and (not self.player:isJilei(card)) then
                        table.insert(to_discard, card:getKnownEffectiveId())
                        table.remove(cards, i)
                        index = index + 1
                        if index == 1 then break end
                    end
                end
                if #to_discard < 1 then return {}
                else return to_discard end
            end
        else
            if math.random(1, 100) <= 30 then return to_discard end
            local cards = sgs.QList2Table(self.player:getCards("h"))
            self:sortByKeepValue(cards, true)
            local index = 0
            for i = #cards, 1, -1 do
                local card = cards[i]
                if not (isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and not self.player:isJilei(card) then
                    table.insert(to_discard, card:getKnownEffectiveId())
                    table.remove(cards, i)
                    index = index + 1
                    if index == 1 then break end
                end
            end
            if #to_discard < 1 then return {}
            else return to_discard end
        end
    end
end

ai_fill_skill.sy_longnu = function(self, options, request)
    local inclusive = options and options.inclusive

    local angers = self.player:getPile("Angers")
    local first_found, second_found = false, false
    local first_card, second_card
    if angers:length() >= 2 then

        for _, id1 in sgs.qlist(angers) do
            local cd1 = known_card(self,id1)
            if cd1:isBlack() then
                first_card = cd1
                first_found = true
                for _, id2 in sgs.qlist(angers) do
                    local cd2 = known_card(self,id2)
                    if first_card:getKnownEffectiveId() ~= cd2:getKnownEffectiveId() and cd2:getSuitString() == first_card:getSuitString() then
                        second_card = cd2
                        second_found = true
                        break
                    end
                end
                if second_card then break end
            end
        end
    end
    if first_found and second_found and (self:getCardsNum("Slash") > 0 or self:getCardsNum("Jink") > 0) and (not self.player:getStrategyHasUsed("Slash")) and (not self.player:getStrategyHasUsed("#sy_longnuCard")) then
        local first_id = first_card:getKnownEffectiveId()
        local second_id = second_card:getKnownEffectiveId()
        return self:bindSkillCard("sy_longnu", {first_id,second_id}, request, nil, "#sy_longnuCard")
    end
end

ai_card_use["#sy_longnuCard"] = function(self, card, use, request)
    use.card = card
end


sgs.ai_use_value["sy_longnuCard"] = 5.98
sgs.ai_use_priority["sy_longnuCard"] = 2.7

sgs.ai_canliegong_skill.sy_longnu = function(self, from, to)
    return from:getStrategyMark("longnu_nojink") > 0
end

ai_fill_skill.sy_yuxue = function(self, options, request)
    local inclusive = options and options.inclusive

    local angers = self.player:getPile("Angers")
    local redangers = AIList.new({})
    for _,id in sgs.qlist(angers) do
        local cd = known_card(self,id)
        if cd:isRed() then
            redangers:append(id)
        end
    end
    if redangers:isEmpty() or (not self.player:isWounded()) then return nil end
    local card = known_card(self,redangers:first())
    if not card then return nil end
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getKnownEffectiveId()
    local card_str = ("peach:sy_yuxue[%s:%s]=%d"):format(suit, number, card_id)
    local skillcard = self:bindTurnConversion("sy_yuxue", "Peach", {name="peach",skill_name="sy_yuxue",suit=card:getSuit(),number=card:getNumber(),subcards={card_id}}, request)
    assert(skillcard)
    return skillcard
end

function sgs.ai_cardsview.sy_yuxue(class_name, player)
    if class_name == "Peach" then
        if player:hasSkill("sy_yuxue") and not player:getPile("Angers"):isEmpty() then
            return ai_fill_skill.sy_yuxue -- Original returns a function (not a card/string).
        end
    end
end

sgs.ai_view_as.sy_yuxue = function(card, player, card_place)
    local angers = player:getPile("Angers")
    local redangers = AIList.new({})
    for _,id in sgs.qlist(angers) do
        local cd = known_card(known(player:getRoom()._ai,"view-as viewer"),id)
        if cd:isRed() then
            redangers:append(id)
        end
    end
    if redangers:isEmpty() then return nil end

    local card = known_card(known(player:getRoom()._ai,"view-as viewer"),redangers:first())
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getKnownEffectiveId()
    return ("peach:sy_yuxue[%s:%s]=%d"):format(suit, number, card_id)
end

ai_skill_invoke.sy_longyin = true

sgs.ai_skill_askforag.sy_longyin = function(self, card_ids)
    local angers = self.player:getPile("Angers")
    local redAngers, blackAngers = AIList.new({}), AIList.new({})
    for _, id in sgs.list(card_ids) do
        local cd = self:getChoiceCard(id)
        if cd:isRed() then
            redAngers:append(id)
        else
            blackAngers:append(id)
        end
    end
    local has_redAngers, has_blackAngers = AIList.new({}), AIList.new({})
    for _, id in sgs.list(angers) do
        local cd = known_card(self,id)
        if cd:isRed() and not (cd:inherits("Peach") and cd:inherits("ExNihilo")) then
            has_redAngers:append(id)
        elseif cd:isBlack() and not cd:inherits("Analeptic") then
            has_blackAngers:append(id)
        end
    end
    if has_redAngers:length() >= has_blackAngers:length() then
        self.sy_longyin = redAngers:first()
    else
        self.sy_longyin = blackAngers:first()
    end

    return self.sy_longyin
end

ai_skill_invoke.sy_beiliang = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    if self.player:getCards("h"):length() <= 2 then
        return (true) or false
    end
    return (false) or false
end

ai_fill_skill.sy_juwu = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:isKongcheng() then return nil end
    local sy_zhaoyun = false
    for _, t in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if (string.find(t:getKnownGeneralName(), "sy_zhaoyun1") or string.find(t:getGeneral2Name(), "sy_zhaoyun1")) and self:isFriend(t) then
            sy_zhaoyun = t
            break
        end
    end
    if not sy_zhaoyun then
        for _, t in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if (string.find(t:getKnownGeneralName(), "sy_zhaoyun2") or string.find(t:getGeneral2Name(), "sy_zhaoyun2")) and self:isFriend(t) then
                sy_zhaoyun = t
                break
            end
        end
    end
    if not sy_zhaoyun then return nil end
    if (not sy_zhaoyun:containsTrick("supply_shortage") or not sy_zhaoyun:containsTrick("indulgence")) and sy_zhaoyun:faceUp() then
        return self:legacySkillSeed("sy_juwu", "#sy_juwuCard", request)
    end
    if (self.player:usedTimes("#sy_juwuCard") < 1 or self:getOverflow() > 0) and (not self:isWeak()) and self.player:getStrategyMark("juwu_given") < self.player:getHp() then
        return self:legacySkillSeed("sy_juwu", "#sy_juwuCard", request)
    end
end

ai_card_use["#sy_juwuCard"] = function(self, card, use, request)
    local danger = false
    if self.player:getHandcardNum() == 1 then
        for _, enemy in ipairs(self.enemies) do
            if enemy:getWeapon() == "guding_blade" and enemy:canSlash(self.player, true) then
                danger = true
                break
            end
        end
    end
    if danger then return nil end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards, true)
    local sy_zhaoyun = false
    for _, t in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if (string.find(t:getKnownGeneralName(), "sy_zhaoyun1") or string.find(t:getGeneral2Name(), "sy_zhaoyun1")) and self:isFriend(t) then
            sy_zhaoyun = t
            break
        end
    end
    if not sy_zhaoyun then
        for _, t in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if (string.find(t:getKnownGeneralName(), "sy_zhaoyun2") or string.find(t:getGeneral2Name(), "sy_zhaoyun2")) and self:isFriend(t) then
                sy_zhaoyun = t
                break
            end
        end
    end
    local card = self:getCardNeedPlayer(cards)
    if card and sy_zhaoyun then
        use.card = nil -- Original wire lacks the second colon; LuaSkillCard::Parse returns nullptr.
        if use.to then use.to:append(sy_zhaoyun) end
        return
    end
    if self:getOverflow()>0 then
        local card_id = self:getCardRandomly(self.player, "h")
        use.card = nil -- Same original malformed wire; do not manufacture payment authority.
        if use.to then use.to:append(sy_zhaoyun) end
        return
    end
end


sgs.ai_use_value["sy_juwuCard"] = 8.5
sgs.ai_use_priority["sy_juwuCard"] = 5.8
sgs.ai_card_intention["sy_juwuCard"] = -70
sgs.dynamic_value.benefit["sy_juwuCard"] = true

ai_fill_skill.sy_shishen = function(self, options, request)
    local inclusive = options and options.inclusive

    local angers = self.player:getPile("Angers")
    local first_found, second_found = false, false
    local first_card, second_card
    if angers:length() >= 2 then
        local same_color = false
        for _, id1 in sgs.qlist(angers) do
            local cd1 = known_card(self,id1)
            if cd1:isBlack() then
                first_card = cd1
                first_found = true
                for _, id2 in sgs.qlist(angers) do
                    local cd2 = known_card(self,id2)
                    if first_card:getKnownEffectiveId() ~= cd2:getKnownEffectiveId() and first_card:sameColorWith(cd2) then
                        second_card = cd2
                        second_found = true
                        break
                    end
                end
                if second_card then break end
            end
        end
    end
    if first_found and second_found then
        local sy_shishenCard = {}
        local first_id = first_card:getKnownEffectiveId()
        local second_id = second_card:getKnownEffectiveId()
        return self:bindSkillCard("sy_shishen", {first_id,second_id}, request, nil, "#sy_shishenCard")
    end
end

ai_card_use["#sy_shishenCard"] = function(self, card, use, request)
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        use.card = card
        if use.to then use.to:append(enemy) end
        return
    end
end

ai_fill_skill.sy_chanshe = function(self, options, request)
    local inclusive = options and options.inclusive

    local angers = self.player:getPile("Angers")
    local redangers = AIList.new({})
    for _,id in sgs.qlist(angers) do
        local cd = known_card(self,id)
        if cd:getSuit() == sgs.Card_Diamond then
            redangers:append(id)
        end
    end
    if redangers:isEmpty() then return nil end
    local card = known_card(self,redangers:first())
    if not card then return nil end
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getKnownEffectiveId()
    local card_str = ("indulgence:sy_chanshe[%s:%s]=%d"):format(suit, number, card_id)
    local skillcard = self:bindTurnConversion("sy_chanshe", "Indulgence", {name="indulgence",skill_name="sy_chanshe",suit=card:getSuit(),number=card:getNumber(),subcards={card_id}}, request)
    assert(skillcard)
    return skillcard
end

ai_skill_invoke.sy_guiren = true

ai_skill_invoke.sy_yinbing = true

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if damage_call(from, "hasSkill", "sy_wushuang") and card and math.fmod(damage_call(card, "getNumber"), 2) ~= 0 then
            dmg = 3
        end
        return dmg, nature
    end
    local previous_1 = sgs.ai_ajustdamage_from["sy_wushuang"]
    sgs.ai_ajustdamage_from["sy_wushuang"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "after_from_tail" and context.rule == "sy_wushuang" then
                local damage, next_nature, terminal = policy_1(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_from", "sy_wushuang", {
        {phase="after_from_tail", rule="sy_wushuang", order=5600},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["sy_jiancheng"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(self,"isFriend",to, from) and damage_call(to,"hasSkill","sy_jiancheng") and not damage_call(to,"getPile","jiancheng"):isEmpty() and card and sgs.card_damage_nature[damage_call(card,"getClassName")] ~=  sgs.DamageStruct_Normal then
        		return nil, true
        	end
        return value
    end
    sgs.ai_need_damaged["sy_jiancheng"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_before_best" and context.rule == "sy_jiancheng" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "sy_jiancheng", {
        {phase="need_hp_before_best", order=2, rule="sy_jiancheng"},
    })
end)()
end
