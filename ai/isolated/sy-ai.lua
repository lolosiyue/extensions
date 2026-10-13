-- Fixed b6025acc sy policies. Original malformed proposals remain malformed outcomes.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("Sy missing "..k,"sy")end;return v end
local function q(o,m,...)
 if AIValue.isPlayer(o)then if m=="getMark"then m="getStrategyMark"elseif m=="hasFlag"then m="getStrategyFlag"end end
 if not o or type(o[m])~="function"then ai_unsupported("Sy unavailable method "..m,"sy")end
 return known(o[m](o,...),m)
end
local function known_card(self,id)return q(self,"getKnownCardById",id)end
local function scoped_use(self)
 local c=q(self,"getDecisionContext").sy;if type(c)~="table"then ai_unsupported("Sy owner Luanzheng tag unavailable","sy_luanzheng")end
 local row=known(c.luanzheng_use,"luanzheng_use");local use={to=AIList.new({})};if row==false then return use end
 if row.from and row.from~=""then use.from=q(self.room,"findPlayerByObjectName",row.from)end
 if row.card then use.card=known(CardView.new(row.card),"Luanzheng card")end
 for _,name in ipairs(known(row.to,"Luanzheng targets"))do use.to:append(q(self.room,"findPlayerByObjectName",name))end
 return use
end

sgs.ai_skill_invoke.sy_xiuluo = function(self, data)
    local use = data:toCardUse()
    if not use.from then return false end
    if q(self,"isFriend",use.from) then return false end
    if q(use.card,"isKindOf","Duel") then return true end
    if q(use.card,"isKindOf","Slash") or q(use.card,"isNDTrick") then
        if q(use.from,"hasSkills","tieji|liegong|mouliegongf|liegong|sr_benxi|fuqi|jiaozi|luoyi|wushuang") then return true end
        if q(self,"getCardsNum","Slash") >= 2 or q(self.player,"getHandcardNum") >= q(use.from,"getHandcardNum") or q(use.from,"getHandcardNum") - q(self.player,"getHandcardNum") <= 2 then return true end
        if q(use.from,"hasWeapon","axe") or q(use.card,"hasFlag","drank") then return true end
    end
end

function sgs.ai_cardneed.sy_wushuang(to,card,self)
    if not q(self,"willSkipPlayPhase",to) then
        return q(card,"isDamageCard") and math.fmod(q(card,"getNumber"), 2) ~= 0
    end
end

sgs.ai_ajustdamage_from.sy_hengxing = function(self,from,to,card,nature)
    if q(from,"getPhase") ~= sgs.Player_Play
    then return 1 end
end

sgs.ai_skill_invoke.sy_lingnue = true
sgs.ai_suppress_intention["sy_baozheng"] = true

sgs.ai_skill_invoke.sy_renji = function(self, data)
    if q(self,"needKongcheng",self.player, true) then return false end
    return true
end

sgs.ai_can_damagehp.sy_renji = function(self,from,card,to)
    return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
    and q(self,"canLoseHp",from,card,to)
end

sgs.ai_skill_invoke.sy_guiming = function(self, data)
    local dying = data:toDying()
    local peaches = 1 - q(dying.who,"getHp")
    return q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") < peaches
end

sgs.ai_canNiepan_skill.sy_guiming = function(player)
    return q(player,"getMark","@guiming") > 0
end

sgs.ai_can_damagehp.sy_fangu = function(self,from,card,to)
    return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
    and q(self,"canLoseHp",from,card,to) and from and not q(self,"isFriend",from)
end

sgs.ai_skill_invoke.sy_canlue = function(self, data)
    local move = data:toMoveOneTime()
    if move and move.from and move.card_ids and move.card_ids:length() > 0 then
        local from = self.room:findPlayerByObjectName(q(move.from,"objectName"))
        if from then return q(self,"isEnemy",from) end
    end
    return
end

sgs.ai_skill_playerchosen.sy_luanzheng = function(self, targets)
    local room = self.room
    local use = scoped_use(self)
    if not use.from then return nil end
    local to = use.to:at(0)
    if q(use.card,"isKindOf","Peach") then
        local friends = {}
        for _, t in sgs.qlist(targets) do
            if q(self,"isFriend",t) and q(t,"isWounded") then table.insert(friends, t) end
        end
        self:sort(friends, "chaofeng")
        return friends[1]
    elseif q(use.card,"isKindOf","ExNihilo") then
        local tos = {}
        for _, t in sgs.qlist(targets) do
            if q(self,"isFriend",t) and not q(self,"needKongcheng",t, true) then
                table.insert(tos, t)
            end
        end
        self:sort(tos, "chaofeng")
        return tos[1]
    elseif q(use.card,"isKindOf","Slash") then
        local tos = {}
        for _, t in sgs.qlist(targets) do
            if q(self,"isEnemy",t) and (not q(to,"hasSkills","leiji|guixin|sgkgodguixin|sgkgodyinshi")) then
                table.insert(tos, t)
            end
        end
        self:sort(tos, "chaofeng")
        return tos[1]
    else
        local tos = {}
        for _, t in sgs.qlist(targets) do
            if q(self,"isEnemy",t) then
                table.insert(tos, t)
            end
        end
        self:sort(tos, "chaofeng")
        return tos[1]
    end
end

sgs.ai_skill_playerchosen.sy_shiao = function(self, targets)
    local tos = {}
    local slash = q(self,"getEvaluationCard","slash")
    for _, p in sgs.qlist(targets) do
        if q(self,"isEnemy",p) then
            if not q(self,"strategyProhibited",self.player,p,slash) and q(self,"slashIsEffective",slash, p) and q(self,"isGoodTarget",p, self.enemies, slash) then table.insert(tos, p) end
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

sgs.ai_skill_invoke.sy_kuangxi = function(self, data)
    local room = self.room
    local use = data:toCardUse()
    if not use.card then return false end
    if not q(use.card,"isKindOf","TrickCard") then return false end
    local F = 0
    local E = 0
    if q(use.card,"isKindOf","AmazingGrace") or q(use.card,"isKindOf","GodSalvation") then
        for _, p in sgs.qlist(use.to) do
            if q(self,"isFriend",p) then
                F = F + 1
            end
            if q(self,"isEnemy",p) then
                E = E + 1
            end
        end
        if ((E - F >= 2) or (E > 0 and F <= 1)) and not q(self,"isWeak") then return true else return false end
    end
    F = 0
    E = 0
    if q(use.card,"isKindOf","IronChain") then
        for _, p in sgs.qlist(use.to) do
            if q(self,"isFriend",p) then
                F = F + 1
            end
            if q(self,"isEnemy",p) then
                E = E + 1
            end
        end
        if F == 0 and E > 0 then
            if math.random(1, 5) > 3 then return true else return false end
        end
    end
    F = 0
    E = 0
    for _, p in sgs.qlist(use.to) do
        if q(self,"isFriend",p) then
            F = F + 1
        end
        if q(self,"isEnemy",p) then
            E = E + 1
        end
    end
    if F == 0 and E > 0 then
        if math.random(1, 100) >= 50 then return true else return false end
    end
    return false
end






































































sgs.ai_skill_invoke.sy_bujiao = function(self, data)
    local to = data:toPlayer()
    if not q(self,"isFriend",to) then return true end
    if q(self,"isEnemy",to) and (not q(self,"isWeak")) and q(self,"objectiveLevel",to) >= 3 then
        return true
    end
    return false
end

sgs.ai_skill_invoke.sy_taiping = true

sgs.ai_fill_skill.sy_yaohuo = function(self,inclusive,request)
    if q(self.player,"hasUsed","#sy_yaohuoCard") then return nil end
    if #self.enemies <= 0 then return nil end
    if q(self.player,"isKongcheng") then return nil end
    return q(self,"bindSkillCard","sy_yaohuo",{},request,nil,"#sy_yaohuoCard")
end

sgs.ai_skill_use_func["#sy_yaohuoCard"] = function(card, use, self,request)
    if q(self.player,"hasUsed","#sy_yaohuoCard") then return nil end
    self:sort(self.enemies, "handcard")
    self.enemies = sgs.reverse(self.enemies)
    local target
    local a = q(self.player,"getHandcardNum") + self.player:getEquips():length()
    local b = -999
    local less = {}
    for _, k in ipairs(self.enemies) do
        if q(k,"getHandcardNum") <= a and not q(k,"isKongcheng") then table.insert(less, k) end
    end
    for _, m in ipairs(less) do
        b = math.max(b, q(m,"getHandcardNum"))
    end
    for _, enemy in ipairs(self.enemies) do
        if q(enemy,"getHandcardNum") == b then
            target = enemy
            break
        end
    end
    if not target then
        for _, enemy in ipairs(self.enemies) do
            if a < b then
                if a > q(enemy,"getHandcardNum") and (not q(enemy,"isKongcheng")) and a - q(enemy,"getHandcardNum") <= 2 then
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
                    if string.find(sgs.bad_skills, q(sk,"objectName")) then
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


sgs.ai_skill_choice.sy_yaohuo = function(self, choices, data)
    local n = math.random(1, 100)
    local yaohuo = choices:split("+")
    if n >= 1 and n <= 50 then
        return yaohuo[1]
    else
        return yaohuo[2]
    end
end

sgs.ai_use_value["sy_yaohuoCard"] = 10
sgs.ai_use_priority["sy_yaohuoCard"] = 9.3
sgs.ai_card_intention["sy_yaohuoCard"] = 90

sgs.ai_skill_invoke.sy_sanzhi = true

sgs.ai_fill_skill.sy_zuijiu = function(self,inclusive,request)
    if q(self,"isWeak") then return nil end
    if #self.enemies == 0 then return nil end
    local E = 0
    local slash = q(self,"getEvaluationCard","slash")
    for _, enemy in ipairs(self.enemies) do
        if not q(self,"strategyProhibited",self.player,enemy,slash) then E = E + 1 end
    end
    if E == 0 then return nil end
    if q(self.player,"getHandcardNum") - q(self.player,"getMark","&sy_zuijiu") <= 2 then return nil end
    return q(self,"bindSkillCard","sy_zuijiu",{},request,nil,"#sy_zuijiuCard")
end

sgs.ai_skill_use_func["#sy_zuijiuCard"] = function(card, use, self,request)
    use.card = card
end

sgs.ai_skill_use["@@sy_zuijiuNormalSlash"] = function(self, prompt)
    if #self.enemies == 0 then return "." end
    self:sort(self.enemies, "defense")
    local slash = q(self,"getEvaluationCard","slash")
    local target
    for _, enemy in ipairs(self.enemies) do
        if not q(self,"strategyProhibited",self.player,enemy,slash) and q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, nil) then
            target = enemy
            break
        end
    end
    if not target then target = self:findPlayerToSlash(false) end
    return "#sy_zuijiuNormalSlashCard:.:->" .. q(target,"objectName")
end

sgs.ai_skill_invoke.sy_huangyin = function(self, data)
    if q(self,"needKongcheng",self.player, true) then return false end
    return true
end

sgs.ai_fill_skill.sy_luansi = function(self,inclusive,request)
    if q(self.player,"hasUsed","#sy_luansiCard") then return nil end
    if #self.enemies == 0 then return nil end
    local j = 0
    for _, p in ipairs(self.enemies) do
        if (not q(p,"isKongcheng")) then j = j + 1 end
    end
    if j < 1 then return nil end
    return q(self,"bindSkillCard","sy_luansi",{},request,nil,"#sy_luansiCard")
end

sgs.ai_skill_use_func["#sy_luansiCard"] = function(card, use, self,request)
    if q(self.player,"hasUsed","#sy_luansiCard") then return nil end
    self:sort(self.enemies, "defense")
    local tar1, tar2
    for _, p in ipairs(self.enemies) do
        if not q(p,"isKongcheng") then
            tar1 = p
            break
        end
    end
    if not tar2 then
        for _, m in ipairs(self.enemies) do
            if q(m,"objectName") ~= q(tar1,"objectName") and (not q(m,"isKongcheng")) then
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

sgs.ai_fill_skill.sy_dihui = function(self,inclusive,request)
    if q(self.player,"hasUsed","#sy_dihuiCard") then return nil end
    if #self.enemies <= 0 then return nil end
    if q(self.player,"getHp") <= 0 then return nil end
    return q(self,"bindSkillCard","sy_dihui",{},request,nil,"#sy_dihuiCard")
end

sgs.ai_skill_use_func["#sy_dihuiCard"] = function(card, use, self,request)
    if q(self.player,"hasUsed","#sy_dihuiCard") then return nil end
    local room = self.room
    local no_min_hp = {}
    local _minhp = 99999
    local players = room:getOtherPlayers(self.player)
    for _, p in sgs.qlist(room:getOtherPlayers(self.player)) do
        _minhp = math.min(_minhp, q(p,"getHp"))
    end
    for _, t in sgs.qlist(room:getOtherPlayers(self.player)) do
        if q(t,"getHp") > _minhp then
            table.insert(no_min_hp, t)
        end
    end
    local target1
    if #no_min_hp == 0 then return nil end
    self:sort(no_min_hp, "chaofeng")
    for _, _min in ipairs(no_min_hp) do
        if q(self,"isFriend",_min) then
            target1 = _min
            break
        end
    end
    if not target1 then
        for _, _to in ipairs(no_min_hp) do
            if q(self,"isEnemy",_to) then
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
        if q(self,"isEnemy",p) then table.insert(players, p) end
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
    if not q(target,"isKongcheng") then return true end
    local others = self.room:getOtherPlayers(target)
    local tos = AIList.new({})
    if target:getJudgingArea():length() > 0 then
        for _, card in sgs.qlist(target:getJudgingArea()) do
            for _, pe in sgs.qlist(others) do
                if not q(self,"strategyProhibited",target,pe,card) and not q(pe,"containsTrick",q(card,"objectName")) and (not tos:contains(pe)) then
                    tos:append(pe)
                end
            end
        end
    end
    if q(target,"hasEquip") then
        for _, card in sgs.qlist(target:getEquips()) do
            local index = q(card,"getEquipSlot")
            for _, pe in sgs.qlist(others) do
                if pe:getEquip(index) == nil and q(pe,"hasEquipArea",index) and (not tos:contains(pe)) then
                    tos:append(pe)
                end
            end
        end
    end
    if tos:isEmpty() then return false else return true end
end

sgs.ai_fill_skill.sy_chanxian = function(self,inclusive,request)
    if q(self.player,"hasUsed","#sy_chanxianCard") then return nil end
    local can_move = {}
    for _, pe in sgs.qlist(self.room:getAlivePlayers()) do
        if canMoveCard(self,pe) then table.insert(can_move, pe) end
    end
    if #can_move == 0 or #self.enemies == 0 then return nil end
    return q(self,"bindSkillCard","sy_chanxian",{},request,nil,"#sy_chanxianCard")
end

sgs.ai_skill_use_func["#sy_chanxianCard"] = function(card, use, self,request)
    local target
    local can_move = {}
    for _, pe in sgs.qlist(self.room:getAlivePlayers()) do
        if canMoveCard(self,pe) then table.insert(can_move, pe) end
    end
    if #can_move == 0 then return nil end
    self:sort(can_move, "defenseSlash")
    for _, pe in ipairs(can_move) do
        if q(self,"isEnemy",pe) then
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
        if q(self,"isEnemy",ap) or q(self.player,"getSeat") == q(ap,"getSeat") then
            table.insert(move_to, ap)
        end
    end
    self:sort(move_to, "hp")
    local target
    for _, to in ipairs(move_to) do
        if q(self,"isEnemy",to) then
            target = to
            break
        end
    end
    if not target then
        for _, to in ipairs(move_to) do
            if q(self.player,"getSeat") == q(to,"getSeat") then
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
    if q(lvbu,"getGeneralName") == "sy_lvbu1" then return true end
    if q(lvbu,"getGeneralName") == "sy_lvbu2" then return true end
    if q(lvbu,"getGeneral2Name") == "sy_lvbu1" then return true end
    if q(lvbu,"getGeneral2Name") == "sy_lvbu2" then return true end
    if q(lvbu,"hasSkills","shenji|sy_shenji") then return true end
    return false
end


sgs.ai_skill_invoke["#W_recast"] = function(self, data)
    for _, skill in sgs.qlist(self.player:getVisibleSkillList()) do
        if string.find(q(skill,"objectName"), "xuanfeng") then return false end
    end
    local card_use = data:toCardUse()
    local card = card_use.card
    if card and q(card,"isKindOf","DefensiveHorse") then
        if not self.player:getDefensiveHorse() then
            return false
        else
            if math.random(1, 100) <= 50 then return true else return false end
        end
    end
    if card and q(card,"isKindOf","OffensiveHorse") then
        if not self.player:getOffensiveHorse() then
            return false
        else
            if math.random(1, 100) <= 50 then return true else return false end
        end
    end
    if not self.player:getWeapon() then
        if canShenji(self.player) then
            if not q(card,"isKindOf","Crossbow") then
                return true
            else
                return false
            end
        else
            return false
        end
    else
        if self:doDisCard(self.player, self.player:getWeapon():getEffectiveId()) then return false end
        if not q(card,"isKindOf","Crossbow") then
            if canShenji(self.player) then
                return true
            else
                if math.random(1, 100) <= 75 then return true else return false end
            end
        else
            return false
        end
    end
    return false
end












































sgs.ai_skill_choice["sy_huoxin"] = function(self, choices, data)
    local huoxin = choices:split("+")
    local caifuren = self.room:findPlayerBySkillName("sy_huoxin")
    if q(self,"isFriend",caifuren) then
        return huoxin[1]
    else
        return huoxin[math.random(1, #huoxin)]
    end
end

sgs.ai_ajustdamage_from.sy_zhuzai = function(self,from,to,card,nature)
    if card and q(card,"isKindOf","TrickCard")
    then return 1 end
end

sgs.ai_ajustdamage_to.sy_zhuzai = function(self,from,to,card,nature)
    if card and q(card,"isKindOf","TrickCard")
    then return -1 end
end

sgs.ai_fill_skill.sy_zhiheng = function(self,inclusive,request)
    if not q(self.player,"hasUsed","#sy_zhiheng") then
        return q(self,"legacySkillSeed","sy_zhiheng","#sy_zhiheng",request)
    end
end

sgs.ai_skill_use_func["#sy_zhiheng"] = function(card, use, self,request)
    local unpreferedCards = {}
    local cards = sgs.QList2Table(self.player:getHandcards())

    if q(self.player,"getHp") < 3 then
        local zcards = self.player:getCards("he")
        local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
        -- Own tag holds the granted skill name; QVariant::toBool reads absent as false.
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
                                if q(p,"getHp") <= 1 then
                                    shouldUse = false
                                    if q(self.player,"distanceTo",p) > 1 then keep_weapon = self.player:getWeapon() end
                                    break
                                end
                            end
                            if dummy_use.to:length() > 1 then shouldUse = false end
                        end
                        if not q(self,"isWeak") then shouldUse = false end
                        if not shouldUse then use_slash = true end
                    end
                end
                if zcard:getTypeId() == sgs.Card_TypeTrick then
                    local dummy_use = { isDummy = true }
                    self:useTrickCard(zcard, dummy_use)
                    if dummy_use.card then shouldUse = false end
                end
                if zcard:getTypeId() == sgs.Card_TypeEquip and not q(self.player,"hasEquip",zcard) then
                    local dummy_use = { isDummy = true }
                    self:useEquipCard(zcard, dummy_use)
                    if dummy_use.card then shouldUse = false end
                    if keep_weapon and q(zcard,"getEffectiveId") == q(keep_weapon,"getEffectiveId") then shouldUse = false end
                end
                if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","Armor") and not self:needToThrowArmor() then shouldUse = false end
                if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
                if q(self.player,"hasEquip",zcard) and q(zcard,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then shouldUse = false end
                if isCard("Jink", zcard, self.player) and not keep_jink then
                    keep_jink = true
                    shouldUse = false
                end
                if q(self.player,"getHp") == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
                    keep_analeptic = true
                    shouldUse = false
                end
                if shouldUse then table.insert(unpreferedCards, q(zcard,"getId")) end
            end
        end
    end

    if #unpreferedCards == 0 then
        local use_slash_num = 0
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            if q(card,"isKindOf","Slash") then
                local will_use = false
                if use_slash_num <= q(card,"getTargetModResidue",self.player) then
                    local dummy_use = { isDummy = true }
                    self:useBasicCard(card, dummy_use)
                    if dummy_use.card then
                        will_use = true
                        use_slash_num = use_slash_num + 1
                    end
                end
                if not will_use then table.insert(unpreferedCards, q(card,"getId")) end
            end
        end

        local num = q(self,"getCardsNum","Jink") - 1
        if self.player:getArmor() then num = num + 1 end
        if num > 0 then
            for _, card in ipairs(cards) do
                if q(card,"isKindOf","Jink") and num > 0 then
                    table.insert(unpreferedCards, q(card,"getId"))
                    num = num - 1
                end
            end
        end
        for _, card in ipairs(cards) do
            if (q(card,"isKindOf","Weapon") and q(self.player,"getHandcardNum") < 3) or q(card,"isKindOf","OffensiveHorse")
                or self:getSameEquip(card, self.player) or q(card,"isKindOf","AmazingGrace") then
                table.insert(unpreferedCards, q(card,"getId"))
            elseif card:getTypeId() == sgs.Card_TypeTrick then
                local dummy_use = { isDummy = true }
                self:useTrickCard(card, dummy_use)
                if not dummy_use.card then table.insert(unpreferedCards, q(card,"getId")) end
            end
        end

        if self.player:getWeapon() and q(self.player,"getHandcardNum") < 3 then
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
        if not q(self.player,"isJilei",known_card(self,unpreferedCards[index])) then table.insert(use_cards, unpreferedCards[index]) end
    end

    if #use_cards > 0 then
        use.card = q(self,"bindSkillCard","sy_zhiheng",use_cards,request,nil,"#sy_zhiheng")
        return
    end
end

sgs.ai_use_value["sy_zhiheng"] = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority["sy_zhiheng"] = sgs.ai_use_priority.ZhihengCard
sgs.dynamic_value.benefit["sy_zhiheng"] = sgs.dynamic_value.benefit.ZhihengCard

function sgs.ai_cardneed.sy_zhiheng(to, card)
    return not q(card,"isKindOf","Jink")
end

local function countJuewangSkills(target)
    local n = 0
    if q(target,"hasSkill","jw_chunbai") then n = n + 1 end
    if q(target,"hasSkill","jw_heiyang") then n = n + 1 end
    if q(target,"hasSkill","jw_shenchao") then n = n + 1 end
    if q(target,"hasSkill","jw_shenglang") then n = n + 1 end
    if q(target,"hasSkill","jw_ruanruo") then n = n + 1 end
    if q(target,"hasSkill","jw_canmeng") then n = n + 1 end
    return n
end

sgs.ai_fill_skill.sy_zhongzhang = function(self,inclusive,request)
    if q(self.player,"hasUsed","#sy_zhongzhang") then return nil end
    return q(self,"bindSkillCard","sy_zhongzhang",{},request,nil,"#sy_zhongzhang")
end

sgs.ai_skill_use_func["#sy_zhongzhang"] = function(card, use, self,request)
    self:sort(self.enemies, "defense")
    local target
    for _, enemy in ipairs(self.enemies) do
        if q(self,"objectiveLevel",enemy) >= 3 and countJuewangSkills(enemy) < 3 then
            target = enemy
            break
        end
    end
    if not target then
        for _, enemy in ipairs(self.enemies) do
            if countJuewangSkills(enemy) == 0 and (not q(self,"isWeak")) then
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

sgs.ai_skill_invoke.sy_xiaoshi = function(self, data)
    local dying = data:toDying()
    local peaches = 1 - q(dying.who,"getHp")
    if q(self.player,"getMark","@xiaoshi") > 0 then
        return q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") < peaches
    end
    return false
end

sgs.ai_canNiepan_skill.sy_xiaoshi = function(player)
    return q(player,"getMark","@xiaoshi") > 0
end

sgs.ai_skill_cardask["@xiaoshiask"] = function(self, data)
    local miku = data:toPlayer()
    if q(self,"isFriend",miku) then return "." end
end

sgs.ai_skill_invoke.sy_beiyuan = function(self, data)
    local damage = data:toDamage()
    if q(self,"isFriend",damage.from) then
        return false
    end
    return true
end

sgs.ai_can_damagehp.sy_beiyuan = function(self,from,card,to)
    if from and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
    and q(self,"canLoseHp",from,card,to)
    then
        return q(self,"isEnemy",from)
    end
end

sgs.ai_skill_invoke.sy_jiancheng = true


sgs.ai_skill_cardask["@jiancheng-discard"] = function(self,data, pattern)
    local target = data:toPlayer()
    if q(self,"isFriend",target) then return "." end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        if q(self,"matchesDiscardPattern",pattern,h)
        then return q(h,"getEffectiveId") end
        if q(h,"getSuitString") == pattern:split("|")[2]
        then return q(h,"getEffectiveId") end
    end
    return "."
end

sgs.ai_ajustdamage_from.sy_baodao = function(self,from,to,slash,nature)
    if slash and q(slash,"isKindOf","Slash") and q(to,"isKongcheng")
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

sgs.ai_skill_invoke.sy_xishou = true

sgs.ai_skill_invoke.sy_caoying = function(self, data)
    local target
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if q(p,"getMark","caoying_AI") > 0 then
            target = p
            break
        end
    end
    return q(self,"isEnemy",target) and self:doDisCard(target, "he")
end

sgs.ai_skill_invoke.sy_shengjian_black = function(self, data)
    return #self.enemies > 0
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

sgs.ai_skill_invoke.sy_fengzhan = function(self, data)
    return #self.enemies > 0
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

sgs.ai_skill_use["@@sy_baofeng"] = function(self, prompt)
    local cardToUse
    for _,card in sgs.list(self.player:getHandcards()) do
        if q(card,"isKindOf","Slash") then
            cardToUse = card
        end
    end
    if cardToUse then
        local enemytargets = {}
        for _, enemy in ipairs(self.enemies) do
            if  (q(self,"objectiveLevel",enemy) >= 3)
                and not q(self,"needToLoseHp",enemy) and q(self,"isGoodTarget",enemy, self.enemies, nil)
                and #enemytargets < 2  then
                table.insert(enemytargets, q(enemy,"objectName"))
            end
        end
        if #enemytargets > 1 then
            return "#sy_baofengCard:".. q(cardToUse,"getEffectiveId") ..":->" .. table.concat(enemytargets, "+")
        end
    end
end

sgs.ai_skill_invoke.sy_wuqiao = function(self, data)
    local use = data:toCardUse()
    if use.to:contains(self.player) and use.from then
        return q(self,"isEnemy",use.from)
    end
    local damage = data:toDamage()
    if q(damage.from,"objectName") == q(self.player,"objectName") then
        return q(self,"isEnemy",damage.to)
    end
end

sgs.ai_skill_invoke.sy_fengying = true

sgs.ai_ajustdamage_to.sy_fengying = function(self, from, to, card, nature)
    if from and q(from,"distanceTo",to) > 1
    then
        return -99
    end
end

sgs.ai_skill_invoke.sy_juexi = function(self, data)
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        if (not q(enemy,"faceUp")) and q(enemy,"getMark","@fiercewind") > 0 then
            table.insert(targets, enemy)
        end
    end
    return #targets > 0
end

sgs.ai_skill_invoke.sy_qinggang = function(self, data)
    local damage = data:toDamage()
    return q(self,"isEnemy",damage.to)
end

sgs.ai_skill_discard.sy_qinggang = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
    local zhaoyun
    if self.room:findPlayerBySkillName("sy_qinggang") then zhaoyun = self.room:findPlayerBySkillName("sy_qinggang") end
    if zhaoyun and q(self,"needToLoseHp",self.player, zhaoyun) then return to_discard end
    local n = math.random(1, 100)
    if q(self.player,"hasFlag","qinggang_AI") then
        if q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") > 0 then
            if n <= 95 then
                return to_discard
            else
                local cards = sgs.QList2Table(self.player:getCards("h"))
                self:sortByKeepValue(cards)
                local index = 0
                for i = #cards, 1, -1 do
                    local card = cards[i]
                    if (not isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and (not q(self.player,"isJilei",card)) then
                        table.insert(to_discard, q(card,"getEffectiveId"))
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
                if not (isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and not q(self.player,"isJilei",card) then
                    table.insert(to_discard, q(card,"getEffectiveId"))
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

sgs.ai_fill_skill.sy_longnu = function(self,inclusive,request)
    local angers = self.player:getPile("Angers")
    local first_found, second_found = false, false
    local first_card, second_card
    if angers:length() >= 2 then

        for _, id1 in sgs.qlist(angers) do
            local cd1 = known_card(self,id1)
            if q(cd1,"isBlack") then
                first_card = cd1
                first_found = true
                for _, id2 in sgs.qlist(angers) do
                    local cd2 = known_card(self,id2)
                    if q(first_card,"getEffectiveId") ~= q(cd2,"getEffectiveId") and q(cd2,"getSuitString") == q(first_card,"getSuitString") then
                        second_card = cd2
                        second_found = true
                        break
                    end
                end
                if second_card then break end
            end
        end
    end
    if first_found and second_found and (q(self,"getCardsNum","Slash") > 0 or q(self,"getCardsNum","Jink") > 0) and (not q(self.player,"hasUsed","Slash")) and (not q(self.player,"hasUsed","#sy_longnuCard")) then
        local first_id = q(first_card,"getEffectiveId")
        local second_id = q(second_card,"getEffectiveId")
        return q(self,"bindSkillCard","sy_longnu",{first_id,second_id},request,nil,"#sy_longnuCard")
    end
end

sgs.ai_skill_use_func["#sy_longnuCard"] = function(card, use, self,request)
    use.card = card
end


sgs.ai_use_value["sy_longnuCard"] = 5.98
sgs.ai_use_priority["sy_longnuCard"] = 2.7

sgs.ai_canliegong_skill.sy_longnu = function(self, from, to)
    return q(from,"getMark","longnu_nojink") > 0
end

sgs.ai_fill_skill.sy_yuxue = function(self,inclusive,request)
    local angers = self.player:getPile("Angers")
    local redangers = AIList.new({})
    for _,id in sgs.qlist(angers) do
        local cd = known_card(self,id)
        if q(cd,"isRed") then
            redangers:append(id)
        end
    end
    if redangers:isEmpty() or (not q(self.player,"isWounded")) then return nil end
    local card = known_card(self,redangers:first())
    if not card then return nil end
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    local card_str = ("peach:sy_yuxue[%s:%s]=%d"):format(suit, number, card_id)
    local skillcard = q(self,"bindTurnConversion","sy_yuxue","Peach",{name="peach",skill_name="sy_yuxue",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={card_id}},request)
    assert(skillcard)
    return skillcard
end

function sgs.ai_cardsview.sy_yuxue(class_name, player)
    if class_name == "Peach" then
        if q(player,"hasSkill","sy_yuxue") and not player:getPile("Angers"):isEmpty() then
            return sgs.ai_fill_skill.sy_yuxue -- Original returns a function (not a card/string).
        end
    end
end

sgs.ai_view_as.sy_yuxue = function(card, player, card_place)
    local angers = player:getPile("Angers")
    local redangers = AIList.new({})
    for _,id in sgs.qlist(angers) do
        local cd = known_card(known(player:getRoom()._ai,"view-as viewer"),id)
        if q(cd,"isRed") then
            redangers:append(id)
        end
    end
    if redangers:isEmpty() then return nil end

    local card = known_card(known(player:getRoom()._ai,"view-as viewer"),redangers:first())
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    return ("peach:sy_yuxue[%s:%s]=%d"):format(suit, number, card_id)
end

sgs.ai_skill_invoke.sy_longyin = true

sgs.ai_skill_askforag.sy_longyin = function(self, card_ids)
    local angers = self.player:getPile("Angers")
    local redAngers, blackAngers = AIList.new({}), AIList.new({})
    for _, id in sgs.list(card_ids) do
        local cd = q(self,"getChoiceCard",id)
        if q(cd,"isRed") then
            redAngers:append(id)
        else
            blackAngers:append(id)
        end
    end
    local has_redAngers, has_blackAngers = AIList.new({}), AIList.new({})
    for _, id in sgs.list(angers) do
        local cd = known_card(self,id)
        if q(cd,"isRed") and not (q(cd,"inherits","Peach") and q(cd,"inherits","ExNihilo")) then
            has_redAngers:append(id)
        elseif q(cd,"isBlack") and not q(cd,"inherits","Analeptic") then
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

sgs.ai_skill_invoke.sy_beiliang = function(self, data)
    if self.player:getCards("h"):length() <= 2 then
        return true
    end
    return false
end

sgs.ai_fill_skill.sy_juwu = function(self,inclusive,request)
    if q(self.player,"isKongcheng") then return nil end
    local sy_zhaoyun = false
    for _, t in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if (string.find(q(t,"getGeneralName"), "sy_zhaoyun1") or string.find(q(t,"getGeneral2Name"), "sy_zhaoyun1")) and q(self,"isFriend",t) then
            sy_zhaoyun = t
            break
        end
    end
    if not sy_zhaoyun then
        for _, t in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if (string.find(q(t,"getGeneralName"), "sy_zhaoyun2") or string.find(q(t,"getGeneral2Name"), "sy_zhaoyun2")) and q(self,"isFriend",t) then
                sy_zhaoyun = t
                break
            end
        end
    end
    if not sy_zhaoyun then return nil end
    if (not q(sy_zhaoyun,"containsTrick","supply_shortage") or not q(sy_zhaoyun,"containsTrick","indulgence")) and q(sy_zhaoyun,"faceUp") then
        return q(self,"legacySkillSeed","sy_juwu","#sy_juwuCard",request)
    end
    if (q(self.player,"usedTimes","#sy_juwuCard") < 1 or q(self,"getOverflow") > 0) and (not q(self,"isWeak")) and q(self.player,"getMark","juwu_given") < q(self.player,"getHp") then
        return q(self,"legacySkillSeed","sy_juwu","#sy_juwuCard",request)
    end
end

sgs.ai_skill_use_func["#sy_juwuCard"] = function(card, use, self,request)
    local danger = false
    if q(self.player,"getHandcardNum") == 1 then
        for _, enemy in ipairs(self.enemies) do
            if enemy:getWeapon() == "guding_blade" and q(enemy,"canSlash",self.player, true) then
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
        if (string.find(q(t,"getGeneralName"), "sy_zhaoyun1") or string.find(q(t,"getGeneral2Name"), "sy_zhaoyun1")) and q(self,"isFriend",t) then
            sy_zhaoyun = t
            break
        end
    end
    if not sy_zhaoyun then
        for _, t in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if (string.find(q(t,"getGeneralName"), "sy_zhaoyun2") or string.find(q(t,"getGeneral2Name"), "sy_zhaoyun2")) and q(self,"isFriend",t) then
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
    if q(self,"getOverflow")>0 then
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

sgs.ai_fill_skill.sy_shishen = function(self,inclusive,request)
    local angers = self.player:getPile("Angers")
    local first_found, second_found = false, false
    local first_card, second_card
    if angers:length() >= 2 then
        local same_color = false
        for _, id1 in sgs.qlist(angers) do
            local cd1 = known_card(self,id1)
            if q(cd1,"isBlack") then
                first_card = cd1
                first_found = true
                for _, id2 in sgs.qlist(angers) do
                    local cd2 = known_card(self,id2)
                    if q(first_card,"getEffectiveId") ~= q(cd2,"getEffectiveId") and q(first_card,"sameColorWith",cd2) then
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
        local first_id = q(first_card,"getEffectiveId")
        local second_id = q(second_card,"getEffectiveId")
        return q(self,"bindSkillCard","sy_shishen",{first_id,second_id},request,nil,"#sy_shishenCard")
    end
end

sgs.ai_skill_use_func["#sy_shishenCard"] = function(card, use, self,request)
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        use.card = card
        if use.to then use.to:append(enemy) end
        return
    end
end

sgs.ai_fill_skill.sy_chanshe = function(self,inclusive,request)
    local angers = self.player:getPile("Angers")
    local redangers = AIList.new({})
    for _,id in sgs.qlist(angers) do
        local cd = known_card(self,id)
        if q(cd,"getSuit") == sgs.Card_Diamond then
            redangers:append(id)
        end
    end
    if redangers:isEmpty() then return nil end
    local card = known_card(self,redangers:first())
    if not card then return nil end
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    local card_str = ("indulgence:sy_chanshe[%s:%s]=%d"):format(suit, number, card_id)
    local skillcard = q(self,"bindTurnConversion","sy_chanshe","Indulgence",{name="indulgence",skill_name="sy_chanshe",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={card_id}},request)
    assert(skillcard)
    return skillcard
end

sgs.ai_skill_invoke.sy_guiren = true

sgs.ai_skill_invoke.sy_yinbing = true
