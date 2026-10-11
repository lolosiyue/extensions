-- Fixed b6025acc package policy; all selection uses pure views and native-issued receipts.
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("package helper unavailable",method) end
    local value=object[method](object,...)
    if AIUnsupported.is(value) then error(value,0) end
    return value
end
local function q(object,method,...)
    local value=call(object,method,...)
    if value==nil then ai_unsupported("package input is unknown",method) end
    return value
end
local function paid(self,skill,selector,request,old)
    local card=q(self,"bindSkillCard",skill,{},request,nil,selector)
    if old then card=q(self,"inheritLegacyCardIdentity",card,old) end
    return card
end
sgs.ai_fill_skill.kehuisuan = function(self, inclusive, request)
    if q(self.player,"hasUsed","#kehuisuanCard") then return end
    if #self.enemies < 1 then return end
    call(self,"updatePlayers")
    call(self,"sort",self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if q(self,"doDisCard",enemy, "he", true) then
                return q(self,"legacySkillSeed","kehuisuan","#kehuisuanCard",request)
            end
        end
    end
    return
end

sgs.ai_skill_use_func["#kehuisuanCard"] = function(card, use, self, request)
    call(self,"updatePlayers")
    call(self,"sort",self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if q(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, enemy) and q(self,"doDisCard",enemy, "he", true) and q(self,"needToLoseHp",self.player, enemy, nil) and not q(enemy,"isKongcheng") then
                use.card = paid(self,"kehuisuan","#kehuisuanCard",request)
                if use.to then call(use.to,"append",enemy) end
                return
            end
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if q(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, enemy) and q(self,"doDisCard",enemy, "he", true) and q(self,"canDamage",enemy, self.player, nil) and not q(enemy,"isKongcheng") then
                use.card = paid(self,"kehuisuan","#kehuisuanCard",request)
                if use.to then call(use.to,"append",enemy) end
                return
            end
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if q(self,"doDisCard",enemy, "he", true) and not (q(self,"isWeak") or q(self,"getOverflow") > 0) then
                use.card = paid(self,"kehuisuan","#kehuisuanCard",request)
                if use.to then call(use.to,"append",enemy) end
                return
            end
        end
    end
end
sgs.ai_card_intention["kehuisuanCard"] = 60

sgs.ai_skill_choice["caochong_guess"] = function(self, choices, data)
    local target = call(data,"toPlayer")
    local items = q(choices,"split","+")
    return items[math.random(1, #items)]
end

function sgs.ai_cardsview_valuable.kerenxin(self, class_name, player)
    local dying = call(self.room,"getCurrentDyingPlayer")
    if not q(player,"faceUp") then return nil end
    if not dying or dying == player or q(self,"isEnemy",dying) then return nil end
    if q(dying,"isLord") and q(self,"isFriend",dying) then return paid(self,"kerenxin","#kerenxinCard",nil) end
    if q(self,"playerGetRound",dying) < q(self,"playerGetRound",self.player)
    then
        return nil
    end
    return paid(self,"kerenxin","#kerenxinCard",nil)
end

sgs.ai_card_intention.kerenxinCard = sgs.ai_card_intention.Peach

sgs.ai_skill_invoke.kemiji = function(self, data)
    return true
end
-- Exact donor assignment captures the currently loaded callback; loader order is significant.
sgs.ai_skill_invoke.kezhenlie = sgs.ai_skill_invoke.zhenlie

sgs.ai_skill_invoke["kezhenliexiangying"] = function(self, data)
    local use = q(data,"toCardUse")
    for _, p in sgs.qlist(use.to) do
        if q(self,"isFriend",p) then
            return false
        end
        if not q(self,"doDisCard",p, "he") then
            return false
        end
    end
    if q(self.player,"getHp") + q(self,"getAllPeachNum") >= 2 and q(self,"isWeak") then
        return false
    end
    return true
end
sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|kemiji"


sgs.ai_fill_skill.keshilun = function(self,inclusive,request)
    return q(self,"legacySkillSeed","keshilun","#keshilun",request)
end

sgs.ai_skill_use_func["#keshilun"] = function(card, use, self, request)
    call(self,"sort",self.friends, "hp")
    for _, ep in sgs.list(self.friends) do
        if q(self,"isWeak",ep) and q(self.player,"getMaxHp") > 2
            and q(self.player,"getLostHp") > 1
        then
            use.card = paid(self,"keshilun","#keshilun",request,card)
            call(use.to,"append",ep)
            return
        end
    end
end

sgs.ai_use_value.keshilun = 8.4
sgs.ai_use_priority.keshilun = 8.5

sgs.ai_skill_playerchosen.keyijideath = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if q(self,"isFriend",target) and q(target,"isAlive") and q(self,"canDraw",target, self.player) then
            return target
        end
    end
    return nil
end

sgs.ai_playerchosen_intention.keyijideath = -50


sgs.ai_skill_invoke.kenvzhuang                  = function(self, data)
    if q(self.player,"getPhase") == sgs.Player_Start and q(self.player,"isMale") then
        return true
    elseif q(self.player,"getPhase") == sgs.Player_NotActive and q(self.player,"isFemale") then
        return true
    end
    return false
end

sgs.ai_skill_playerchosen.kenvzhuang            = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if q(self,"isEnemy",target) and q(self,"doDisCard",target, "he") then
            return target
        end
    end
    return nil
end

sgs.ai_skill_invoke.kezhangchunhuaxiangying     = function(self, data)
    local target = q(data,"toPlayer")
    if not q(self,"isFriend",target) then return true end
    return false
end

sgs.ai_skill_discard["kezhangchunhuaxiangying"] = function(self, discard_num, min_num, optional, include_equip)
    local usable_cards = sgs.QList2Table(q(self.player,"getCards","h"))
    local to_discard = {}
    for _, c in ipairs(usable_cards) do
        if #to_discard < discard_num and q(self,"getUseValue",c) < 6 then
            table.insert(to_discard, q(c,"getEffectiveId"))
        end
    end
    if #to_discard < discard_num then
        for _, c in ipairs(usable_cards) do
            if #to_discard < discard_num and not table.contains(to_discard, q(c,"getEffectiveId")) then
                table.insert(to_discard, q(c,"getEffectiveId"))
            end
        end
    end
    if #to_discard == discard_num then
        return to_discard
    end

    return {}
end
sgs.hit_skill                                   = sgs.hit_skill .. "|kezhangchunhuaxiangying"
sgs.ai_card_priority.kejiang                    = function(self, card)
    if q(card,"isDamageCard") and q(card,"isRed")
    then
        return 0.05
    end
end
sgs.ai_suit_priority.kejiang                    = function(self, card)
    return (q(card,"isDamageCard") or q(card,"isKindOf","Duel")) and "diamond|heart|club|spade" or "club|spade|diamond|heart"
end

sgs.ai_cardneed.kejiang                         = function(to, card, self)
    return isCard("Duel", card, to) or (q(card,"isDamageCard") and q(card,"isRed"))
end

sgs.ai_skill_invoke.kejiang                     = function(self, data)
    local use = q(data,"toCardUse")
    if q(use.card,"isRed") or q(use.card,"isKindOf","Duel") then
        return true
    end
    if q(self.player,"getPhase") == sgs.Player_Play then
        local cards = q(self.player,"getHandcards")
        for _, c in sgs.qlist(cards) do
            local dummy_use = q(self,"aiUseCard",c)
            if dummy_use.card and q(c,"isRed") and q(c,"isDamageCard") then return false end
        end
    end
    if not q(self,"isWeak") then return true end
    if q(self,"isWeak",self.player) and math.random(1, 2) == 1 then return true end
    return false
end
