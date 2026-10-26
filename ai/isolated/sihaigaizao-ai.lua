-- Source: b6025acc ai/sihaigaizao-ai.lua.


local function paid(self,skill,selector,request,old)
    local card=self:bindSkillCard(skill, {}, request, nil, selector)
    if old then card=self:inheritLegacyCardIdentity(card, old) end
    return card
end
ai_fill_skill.kehuisuan = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyHasUsed("#kehuisuanCard") then return end
    if #self.enemies < 1 then return end
    self:updatePlayers()
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if self:doDisCard(enemy, "he", true) then
                return self:legacySkillSeed("kehuisuan", "#kehuisuanCard", request)
            end
        end
    end
    return
end

ai_card_use["#kehuisuanCard"] = function(self, card, use, request)
    self:updatePlayers()
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, enemy) and self:doDisCard(enemy, "he", true) and self:needToLoseHp(self.player, enemy, nil) and not enemy:isKongcheng() then
                use.card = paid(self,"kehuisuan","#kehuisuanCard",request)
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, enemy) and self:doDisCard(enemy, "he", true) and self:canDamage(enemy, self.player, nil) and not enemy:isKongcheng() then
                use.card = paid(self,"kehuisuan","#kehuisuanCard",request)
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if self:doDisCard(enemy, "he", true) and not (self:isWeak() or self:getOverflow() > 0) then
                use.card = paid(self,"kehuisuan","#kehuisuanCard",request)
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end
sgs.ai_card_intention["kehuisuanCard"] = 60

ai_skill_choice["caochong_guess"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local target = data:toPlayer()
    local items = choices:split("+")
    return ai_choice_result((items[math.random(1, #items)]), options)
end

function sgs.ai_cardsview_valuable.kerenxin(self, class_name, player)
    local dying = self.room:getCurrentDyingPlayer()
    if not player:faceUp() then return nil end
    if not dying or dying == player or self:isEnemy(dying) then return nil end
    if dying:isLord() and self:isFriend(dying) then return paid(self,"kerenxin","#kerenxinCard",nil) end
    if self:playerGetRound(dying) < self:playerGetRound(self.player)
    then
        return nil
    end
    return paid(self,"kerenxin","#kerenxinCard",nil)
end

sgs.ai_card_intention.kerenxinCard = sgs.ai_card_intention.Peach

ai_skill_invoke.kemiji = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end
-- Exact donor assignment captures the currently loaded callback; loader order is significant.
ai_skill_invoke.kezhenlie = ai_skill_invoke.zhenlie

ai_skill_invoke["kezhenliexiangying"] = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
    for _, p in sgs.qlist(use.to) do
        if self:isFriend(p) then
            return (false) or false
        end
        if not self:doDisCard(p, "he") then
            return (false) or false
        end
    end
    if self.player:getHp() + self:getAllPeachNum() >= 2 and self:isWeak() then
        return (false) or false
    end
    return (true) or false
end
sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|kemiji"


ai_fill_skill.keshilun = function(self, options, request)
    local inclusive = options and options.inclusive

    return self:legacySkillSeed("keshilun", "#keshilun", request)
end

ai_card_use["#keshilun"] = function(self, card, use, request)
    self:sort(self.friends, "hp")
    for _, ep in sgs.list(self.friends) do
        if self:isWeak(ep) and self.player:getMaxHp() > 2
            and self.player:getLostHp() > 1
        then
            use.card = paid(self,"keshilun","#keshilun",request,card)
            use.to:append(ep)
            return
        end
    end
end

sgs.ai_use_value.keshilun = 8.4
sgs.ai_use_priority.keshilun = 8.5

sgs.ai_skill_playerchosen.keyijideath = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if self:isFriend(target) and target:isAlive() and self:canDraw(target, self.player) then
            return target
        end
    end
    return nil
end

sgs.ai_playerchosen_intention.keyijideath = -50


ai_skill_invoke.kenvzhuang                  = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    if self.player:getPhase() == sgs.Player_Start and self.player:isMale() then
        return (true) or false
    elseif self.player:getPhase() == sgs.Player_NotActive and self.player:isFemale() then
        return (true) or false
    end
    return (false) or false
end

sgs.ai_skill_playerchosen.kenvzhuang            = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if self:isEnemy(target) and self:doDisCard(target, "he") then
            return target
        end
    end
    return nil
end

ai_skill_invoke.kezhangchunhuaxiangying     = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if not self:isFriend(target) then return (true) or false end
    return (false) or false
end

sgs.ai_skill_discard["kezhangchunhuaxiangying"] = function(self, discard_num, min_num, optional, include_equip)
    local usable_cards = sgs.QList2Table(self.player:getCards("h"))
    local to_discard = {}
    for _, c in ipairs(usable_cards) do
        if #to_discard < discard_num and self:getUseValue(c) < 6 then
            table.insert(to_discard, c:getKnownEffectiveId())
        end
    end
    if #to_discard < discard_num then
        for _, c in ipairs(usable_cards) do
            if #to_discard < discard_num and not table.contains(to_discard, c:getKnownEffectiveId()) then
                table.insert(to_discard, c:getKnownEffectiveId())
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
    if card:isDamageCard() and card:isRed()
    then
        return 0.05
    end
end
sgs.ai_suit_priority.kejiang                    = function(self, card)
    return (card:isDamageCard() or card:isKindOf("Duel")) and "diamond|heart|club|spade" or "club|spade|diamond|heart"
end

sgs.ai_cardneed.kejiang                         = function(to, card, self)
    return isCard("Duel", card, to) or (card:isDamageCard() and card:isRed())
end

ai_skill_invoke.kejiang                     = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
    if use.card:isRed() or use.card:isKindOf("Duel") then
        return (true) or false
    end
    if self.player:getPhase() == sgs.Player_Play then
        local cards = self.player:getHandcards()
        for _, c in sgs.qlist(cards) do
            local dummy_use = self:aiUseCard(c)
            if dummy_use.card and c:isRed() and c:isDamageCard() then return (false) or false end
        end
    end
    if not self:isWeak() then return (true) or false end
    if self:isWeak(self.player) and math.random(1, 2) == 1 then return (true) or false end
    return (false) or false
end
