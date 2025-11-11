kehuisuan_skill = {}
kehuisuan_skill.name = "kehuisuan"
table.insert(sgs.ai_skills, kehuisuan_skill)
kehuisuan_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#kehuisuanCard") then return end
    if #self.enemies < 1 then return end
    self:updatePlayers()
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if self:doDisCard(enemy, "he", true) then
                return sgs.Card_Parse("#kehuisuanCard:.:")
            end
        end
    end
    return
end

sgs.ai_skill_use_func["#kehuisuanCard"] = function(card, use, self)
    self:updatePlayers()
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, enemy) and self:doDisCard(enemy, "he", true) and self:needToLoseHp(self.player, enemy, nil) and not enemy:isKongcheng() then
                use.card = sgs.Card_Parse("#kehuisuanCard:.:")
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, enemy) and self:doDisCard(enemy, "he", true) and self:canDamage(enemy, self.player, nil) and not enemy:isKongcheng() then
                use.card = sgs.Card_Parse("#kehuisuanCard:.:")
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            if self:doDisCard(enemy, "he", true) and not (self:isWeak() or self:getOverflow() > 0) then
                use.card = sgs.Card_Parse("#kehuisuanCard:.:")
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end
sgs.ai_card_intention["kehuisuanCard"] = 60

sgs.ai_skill_choice["caochong_guess"] = function(self, choices, data)
    local target = data:toPlayer()
    local items = choices:split("+")
    return items[math.random(1, #items)]
end

function sgs.ai_cardsview_valuable.kerenxin(self, class_name, player)
    local dying = self.room:getCurrentDyingPlayer()
    if not player:faceUp() then return nil end
    if not dying or dying == player or self:isEnemy(dying) then return nil end
    if dying:isLord() and self:isFriend(dying) then return "#kerenxinCard:.:" end
    if self:playerGetRound(dying) < self:playerGetRound(self.player)
    then
        return nil
    end
    return "#kerenxinCard:.:"
end

sgs.ai_card_intention.kerenxinCard = sgs.ai_card_intention.Peach

sgs.ai_skill_invoke.kemiji = function(self, data)
    return true
end
sgs.ai_skill_invoke.kezhenlie = sgs.ai_skill_invoke.zhenlie

sgs.ai_skill_invoke["kezhenliexiangying"] = function(self, data)
    local use = data:toCardUse()
    for _, p in sgs.qlist(use.to) do
        if self:isFriend(p) then
            return false
        end
        if not self:doDisCard(p, "he") then
            return false
        end
    end
    if self.player:getHp() + self:getAllPeachNum() >= 2 and self:isWeak() then
        return false
    end
    return true
end
sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|kemiji"


addAiSkills("keshilun").getTurnUseCard = function(self)
    return sgs.Card_Parse("#keshilun:.:")
end

sgs.ai_skill_use_func["#keshilun"] = function(card, use, self)
    self:sort(self.friends, "hp")
    for _, ep in sgs.list(self.friends) do
        if self:isWeak(ep) and self.player:getMaxHp() > 2
            and self.player:getLostHp() > 1
        then
            use.card = card
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


sgs.ai_skill_invoke.kenvzhuang                  = function(self, data)
    if self.player:getPhase() == sgs.Player_Start and self.player:isMale() then
        return true
    elseif self.player:getPhase() == sgs.Player_NotActive and self.player:isFemale() then
        return true
    end
    return false
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

sgs.ai_skill_invoke.kezhangchunhuaxiangying     = function(self, data)
    local target = data:toPlayer()
    if not self:isFriend(target) then return true end
    return false
end

sgs.ai_skill_discard["kezhangchunhuaxiangying"] = function(self, discard_num, min_num, optional, include_equip)
    local usable_cards = sgs.QList2Table(self.player:getCards("h"))
    local to_discard = {}
    for _, c in ipairs(usable_cards) do
        if #to_discard < discard_num and self:getUseValue(c) < 6 then
            table.insert(to_discard, c:getEffectiveId())
        end
    end
    if #to_discard < discard_num then
        for _, c in ipairs(usable_cards) do
            if #to_discard < discard_num and not table.contains(to_discard, c:getEffectiveId()) then
                table.insert(to_discard, c:getEffectiveId())
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

sgs.ai_skill_invoke.kejiang                     = function(self, data)
    local use = data:toCardUse()
    if use.card:isRed() or use.card:isKindOf("Duel") then
        return true
    end
    if self.player:getPhase() == sgs.Player_Play then
        local cards = self.player:getHandcards()
        for _, c in sgs.qlist(cards) do
            local dummy_use = self:aiUseCard(c)
            if dummy_use.card and c:isRed() and c:isDamageCard() then return false end
        end
    end
    if not self:isWeak() then return true end
    if self:isWeak(self.player) and math.random(1, 2) == 1 then return true end
    return false
end
