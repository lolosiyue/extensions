function sgs.ai_cardneed.slash(to,card,self)
	if not self:willSkipPlayPhase(to) then
		return (isCard("Slash", card, to) and getKnownCard(to, "Slash", true) == 0)
	end
end

--武圣
addAiSkills("sijyu_wusheng").getTurnUseCard = function(self)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards, nil, true)
    for _, h in sgs.list(cards) do
        if h:isRed() and not h:isKindOf("Slash")
        then
            for c, pn in sgs.list(RandomList(patterns())) do
                c = dummyCard(pn)
                if c and c:isKindOf("Slash")
                then
                    c:setSkillName("sijyu_wusheng")
                    c:addSubcard(h)
                    if c:isAvailable(self.player)
                        and self:aiUseCard(c).card
                    then
                        return c
                    end
                end
            end
        end
    end
end

sgs.ai_guhuo_card.sijyu_wusheng = function(self, toname, class_name)
    if class_name == "Slash"
    then
        local cards = self:addHandPile("he")
        cards = self:sortByKeepValue(cards, nil, true)
        for c, h in sgs.list(cards) do
            if h:isRed() and not h:isKindOf("Slash")
            then
                c = dummyCard(toname)
                c:setSkillName("sijyu_wusheng")
                c:addSubcard(h)
                return c:toString()
            end
        end
    end
end


sgs.ai_use_revises.sijyu_wusheng = function(self, card, use)
    local record = self.player:property("sijyu_wushengRecords"):toString()
    local suit = card:getSuitString()
    local records
    if (record) then
        records = record:split(",")
    end
    if records and not table.contains(records, suit) and card and card:getClassName()
        and card:isKindOf("Slash") and not card:isVirtualCard() and sgs.ai_use_priority[card:getClassName()] then
        sgs.ai_use_priority[card:getClassName()] = sgs.ai_use_priority[card:getClassName()] + 3
    end
end

function sgs.ai_cardneed.sijyu_wusheng(to, card)
    return to:getHandcardNum() < 3 and card:isRed()
end

--奇锋
sgs.ai_skill_playerchosen.sijyu_qifeng_get = function(self, targets)
    if self.player:getHandcardNum() < 3 then return self.player end
    local card = self.room:getTag("sijyu_qifeng_get"):toCard()
    local cards = { card }
    local c, friend = self:getCardNeedPlayer(cards, self.friends)
    if friend then return friend end
    self:sort(self.friends)
    for _, friend in ipairs(self.friends) do
        if self:isValuableCard(card, friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then
            return
                friend
        end
    end
    for _, friend in ipairs(self.friends) do
        if self:isWeak(friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then
            return
                friend
        end
    end
    local trash = card:isKindOf("Disaster") or card:isKindOf("GodSalvation") or card:isKindOf("AmazingGrace")
    if trash then
        for _, enemy in ipairs(self.enemies) do
            if enemy:getPhase() > sgs.Player_Play and self:needKongcheng(enemy, true) and not hasManjuanEffect(enemy) then
                return
                    enemy
            end
        end
    end
    for _, friend in ipairs(self.friends) do
        if not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then return friend end
    end
    return self.player
end
sgs.ai_playerchosen_intention.sijyu_qifeng_get = function(self, from, to)
    if not self:needKongcheng(to, true) and not hasManjuanEffect(to) then sgs.updateIntention(from, to, -50) end
end
sgs.ai_skill_playerchosen.sijyu_qifeng = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    if self.player:getHandcardNum() < 3 then
        for _, enemy in ipairs(self.enemies) do
            if (self:doDisCard(enemy, "h", true) or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() then
                return enemy
            end
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if (self:doDisCard(enemy, "he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() then
            return enemy
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if (self:doDisCard(enemy, "h", true) or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() then
            return enemy
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
            or (self:needToThrowArmor(friend) and friend:getArmor()) or self:doDisCard(friend, "he") then
            return friend
        end
    end
    return nil
end
sgs.ai_skill_cardchosen.sijyu_qifeng = function(self, who, flags)
    local cards = sgs.QList2Table(who:getEquips())
    local handcards = sgs.QList2Table(who:getHandcards())
    if #handcards < 3 or handcards[1]:hasFlag("visible") then table.insert(cards, handcards[1]) end

    for i = 1, #cards do
        return cards[i]:getId()
    end
    return -1
end

--拖刀
sgs.ai_can_damagehp.sijyu_tuodao = function(self, from, card, to)
    if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
        and self:canLoseHp(from, card, to) and self:getCardsNum("Slash") > 1
    then
        return self:isEnemy(from) and not from:isKongcheng() and
            ((not self:isWeak() and self:canAttack(from)) or self:isWeak(from))
    end
end
function sgs.ai_slash_prohibit.sijyu_tuodao(self, from, to)
    if self:isFriend(from, to) then return false end
    if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
    if from:hasFlag("NosJiefanUsed") then return false end
    if from:getHandcardNum() == 1 and from:getEquips():length() == 0 and from:getHandcards():at(0):isKindOf("Slash") and from:getHp() >= 2 then return false end
    return from:getHp() + from:getEquips():length() < 4 or from:getHp() < 2
end

sgs.ai_skill_invoke.sijyu_tuodao = function(self, data)
    local mode = self.room:getMode()
    if mode:find("_mini_41") or mode:find("_mini_46") then return true end
    local target = data:toPlayer()
    if self:needToLoseHp(target, self.player, nil) then
        if self:isFriend(target) then
            return true
        end
        return false
    end
    return self:isEnemy(target)
end


sgs.ai_skill_playerchosen.sijyu_tuodao = function(self, targets)
    local target
    self:sort(self.friends, "defense")
    for _, friend in ipairs(self.friends) do
        if self:isWeak(friend) then
            target = friend
            break
        end
    end
    if target then
        return target
    end
    for _, friend in ipairs(self.friends) do
        if friend:getHp() < getBestHp(friend) then
            target = friend
            break
        end
    end
    if target then
        return target
    end
    return nil
end
sgs.ai_playerchosen_intention.sijyu_tuodao = function(self, from, to)
    if self:isWeak(to) or (to:getHp() < getBestHp(to)) then sgs.updateIntention(from, to, -80) end
end

--斩将

function sgs.ai_cardneed.sijyu_zhanjiang(to, card, self)
    local cards = to:getHandcards()
    local has_weapon = to:getWeapon() and not to:getWeapon():isKindOf("Crossbow")
    local slash_num = 0
    for _, c in sgs.list(cards) do
        local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
        if c:hasFlag("visible") or c:hasFlag(flag) then
            if c:isKindOf("Weapon") and not c:isKindOf("Crossbow") then
                has_weapon = true
            end
            if c:isKindOf("Slash") then slash_num = slash_num + 1 end
        end
    end

    if not has_weapon then
        return card:isKindOf("Weapon") and not card:isKindOf("Crossbow")
    else
        return to:hasWeapon("spear") or card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic"))
    end
end

sgs.sijyu_zhanjiang_keep_value = {
    Peach = 6,
    Analeptic = 5.8,
    Jink = 5.7,
    FireSlash = 5.6,
    Slash = 5.4,
    ThunderSlash = 5.5,
    ExNihilo = 4.7
}
sgs.double_slash_skill = sgs.double_slash_skill .."|sijyu_zhanjiang"


--游龙
--目的是想讓角色先用技能轉酒+刷新技能+技能轉殺 每回合就能多過兩張牌 但實際效果不佳 要是有大佬能指點一下就好
sgs.ai_use_revises.sijyu_youlong = function(self, card, use)
    if card and card:getClassName() and card:isKindOf("Analeptic") and
        (table.contains(card:getSkillNames(), "sijyu_youlong") and (self.player:getMark("&sijyu_youlong-Clear") == 0))
        and sgs.ai_use_priority[card:getClassName()] and self:getCardsNum("Slash") > 0 then
        sgs.ai_use_priority[card:getClassName()] = sgs.ai_use_priority[card:getClassName()] + 2
    end
end
sgs.ai_card_priority.sijyu_youlong = function(self, card)
    if table.contains(card:getSkillNames(), "sijyu_youlong")
    then
        return 1
    end
end

addAiSkills("sijyu_youlong").getTurnUseCard = function(self)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards, nil, true)
    for _, h in sgs.list(cards) do
        for c, pn in sgs.list(RandomList(patterns())) do
            c = dummyCard(pn)
            if c and c:isKindOf("BasicCard")
            then
                c:setSkillName("sijyu_youlong")
                c:addSubcard(h)
                if c:isAvailable(self.player)
                    and self:aiUseCard(c).card
                then
                    return c
                end
            end
        end
    end
end

sgs.ai_guhuo_card.sijyu_youlong = function(self, toname, class_name)
    if class_name == "Slash" or string.find(toname, "jink")
        or string.find(toname, "peach")
        or string.find(toname, "analeptic")
        or string.find(toname, "nullification")
    then
        local cards = self:addHandPile("he")
        cards = self:sortByKeepValue(cards, nil, true)
        for c, h in sgs.list(cards) do
            c = dummyCard(toname)
            c:setSkillName("sijyu_youlong")
            c:addSubcard(h)
            return c:toString()
        end
    end
end

--克祸

sgs.ai_can_damagehp.sijyu_kehou = function(self, from, card, to)
    if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
        and self:canLoseHp(from, card, to)
    then
        return to:getMark("&sijyu_kehou-Clear") == 0 and ((to:getHp() - to:getHandcardNum() > 2) or to:isKongcheng())
    end
end

--七战

sgs.ai_use_revises.sijyu_qizhan = function(self, card, use)
    if card and card:getClassName() and
        ((not card:isVirtualCard() and (self.player:getMark("&sijyu_youlong-Clear") > 0 or self.player:getMark("&sijyu_kehou-Clear") > 0))
            or (self.player:hasSkills("sijyu_youlong") and (table.contains(card:getSkillNames(), "sijyu_youlong") and (self.player:getMark("&sijyu_youlong-Clear") == 0 or self.player:getMark("&sijyu_kehou-Clear") == 0)))
        )
        and sgs.ai_use_priority[card:getClassName()] then
        sgs.ai_use_priority[card:getClassName()] = sgs.ai_use_priority[card:getClassName()] + 1
    end
end

--宣梦
sgs.ai_skill_invoke.sijyu_xuanmeng = true
sgs.ai_skill_use["@@sijyu_xuanmeng"] = function(self, prompt, method)
    return "#sijyu_xuanmeng:.:"
end

sgs.ai_skill_choice.sijyu_xuanmeng = function(self, choices, data)
    local items = choices:split("+")
    local cards = sgs.QList2Table(self.player:getCards("h"))
    for _, cd in ipairs(cards) do
        if table.contains(items, cd:objectName())
        then
            return cd:objectName()
        end
    end

    return items[1]
end
--斩侍
sgs.ai_skill_cardask["@sijyu_zhanshi"] = function(self, data, pattern, target)
    if target and self:isEnemy(target) and self:damageIsEffective(target) and not self:cantbeHurt(target) then
        local cards = sgs.QList2Table(self.player:getCards("h"))
        local pattern = pattern:split(",")
        self:sortByKeepValue(cards)
        for _, card in ipairs(cards) do
            for _, p in ipairs(pattern) do
                if card:getClassName() == p then
                    return card:toString()
                end
            end
        end
    end
    return "."
end

--作态
sgs.ai_playerchosen_intention.sijyu_zuotai = -80
sgs.ai_skill_playerchosen.sijyu_zuotai = function(self, targets)
    local targets = sgs.QList2Table(targets)
    if self:canDraw(self.player) and table.contains(targets, self.player) then return self.player end
    self:sort(self.friends_noself, "defense")
    self.friends_noself = sgs.reverse(self.friends_noself)
    for _, friend in ipairs(self.friends_noself) do
        if not self:canDraw(friend) then continue end
        if (friend:getHandcardNum() + (friend:isWounded() and -2 or 1)) < (self.player:getHandcardNum()) and table.contains(targets, friend) then
            return friend
        end
    end
    return nil
end


--诛乱
local sijyu_zhuluan_skill = {}
sijyu_zhuluan_skill.name = "sijyu_zhuluan"
table.insert(sgs.ai_skills, sijyu_zhuluan_skill)

sijyu_zhuluan_skill.getTurnUseCard = function(self)
    local alivenum = self.room:getAlivePlayers():length()
    if self.player:getHandcardNum() < alivenum then return end
    if self.player:getMark("&sijyu_zhuluanUsed-PlayClear") >= 3 then return end
    if self.player:hasFlag("Ai_sijyu_zhuluan_NotDiscard") then return end

    local cards = sgs.QList2Table(self.player:getHandcards())

    self:sortByUseValue(cards, true)
    if #cards == 0 or ((alivenum > 4) and (alivenum / self.player:getHandcardNum()) < 1.5) then return end

    return sgs.Card_Parse("#sijyu_zhuluan:.:")
end


sgs.ai_skill_use_func["#sijyu_zhuluan"] = function(card, use, self)
    local useable_cards = sgs.QList2Table(self.player:getCards("e"))
    self:sortByUseValue(useable_cards, true)
    local use_card = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
    use_card:setSkillName("_sijyu_zhuluan")
    use_card:deleteLater()
    local dummy = self:aiUseCard(use_card)
    if dummy.card then
        use.card = card
    end
end

sgs.ai_use_priority["sijyu_zhuluan"] = sgs.ai_use_priority.ArcheryAttack
sgs.ai_use_value["sijyu_zhuluan"] = sgs.ai_use_value.ArcheryAttack

sgs.ai_skill_discard.sijyu_zhuluan = function(self, discard_num, min_num, optional, include_equip)
    local usable_cards = sgs.QList2Table(self.player:getCards("h"))

    self:sortByKeepValue(usable_cards)
    local to_discard = {}
    for _, c in ipairs(usable_cards) do
        if #to_discard < discard_num and not c:isKindOf("Peach") then
            table.insert(to_discard, c:getEffectiveId())
        end
    end
    if #to_discard > 0 and #to_discard == discard_num then
        return to_discard
    end
    self.player:setFlags("Ai_sijyu_zhuluan_NotDiscard")
    return {}
end

sgs.ai_ajustdamage_from.sijyu_zhuluan = function(self, from, to, card, nature)
    if card and table.contains(card:getSkillNames(), "sijyu_zhuluan") and from and from:getMark("zhuluandamage_lun") == 0 then
        return 1
    end
end

--虎踞
sgs.ai_skill_invoke.sijyu_huju = function(self, data)
    local use = data:toCardUse()
    if not use and self:getOverflow() >= 2 then
        return true
    end
    if use then
        if sgs.ai_skill_cardask["@sijyu_huju"](self, data) ~= "." then
            return true
        end
    end
    return false
end
sgs.ai_skill_cardask["@sijyu_huju"] = function(self, data)
    local use = data:toCardUse()
    if not use.from or use.from:isDead() then return "." end
    local to_discard = {}
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        table.insert(to_discard, card:getEffectiveId())
    end
    if #to_discard == 0 then return "." end

    if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not use.from:hasSkill("jueqing") and use.from:isLord() and self.player:getHp() == 1) then
        if use.card:isKindOf("AOE") then
            local from = use.from
            if use.card:isKindOf("SavageAssault") then
                local menghuo = self.room:findPlayerBySkillName("huoshou")
                if menghuo then from = menghuo end
            end

            local friend_null = 0
            for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
                if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
            end
            friend_null = friend_null + self:getCardsNum("Nullification")
            local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

            if not self:hasTrickEffective(use.card, self.player, from) then return "." end
            if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then return "." end
            if use.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then
                return
                    "$" .. to_discard[1]
            end
            if sj_num == 0 and friend_null <= 0 then
                if self:isEnemy(from) and hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()]) then
                    return "$" .. to_discard[1]
                end
                if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()]) then
                    return "$" .. to_discard[1]
                end
                if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkill("tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()])
                    ) then
                    return "$" .. to_discard[1]
                end
            end
        elseif self:isEnemy(use.from) then
            if use.card:isKindOf("FireAttack") and use.from:getHandcardNum() > 0 then
                if not self:hasTrickEffective(use.card, self.player) then return false end
                if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, use.from) then return false end
                if (self.player:hasArmorEffect("vine") or self.player:getMark("&kuangfeng") > 0) and use.from:getHandcardNum() > 3
                    and not (use.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
                    return "$" .. to_discard[1]
                elseif self.player:isChained() and not self:isGoodChainTarget(self.player, nil, use.from)
                then
                    return "$" .. to_discard[1]
                end
            elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement"))
                and self:getCardsNum("Peach") == self.player:getHandcardNum() and not self.player:isKongcheng()
            then
                if not self:hasTrickEffective(use.card, self.player) then return false end
                return "$" .. to_discard[1]
            elseif use.card:isKindOf("Duel")
            then
                if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player)
                then
                    if not self:hasTrickEffective(use.card, self.player) then return false end
                    if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then return false end
                    return "$" .. to_discard[1]
                end
            elseif use.card:isKindOf("TrickCard") and not use.card:isKindOf("AmazingGrace")
            then
                if self:doDisCard(self.player, "he") then
                    return "$" .. to_discard[1]
                end
            end
        end
    end

    if #to_discard > 0 then return "$" .. to_discard[1] else return "." end
end

--忧病

sgs.ai_skill_choice["sijyu_youbing"] = function(self, choices, data)
    local items = choices:split("+")
    return items[math.random(1, #items)]
end

--平威
sgs.ai_skill_invoke.sijyu_pingwei = function(self, data)
    return true
end
sgs.ai_skill_cardask["@sijyu_pingwei"] = function(self, data)
    local lord = self.room:getLord()
    if lord and self:isEnemy(lord) then return "." end
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)

    for _, card in ipairs(cards) do
        return "$" .. card:getEffectiveId()
    end
end

--硝妄
sgs.ai_ajustdamage_from.sijyu_xiaowang = function(self, from, to, card, nature)
    if nature ~= sgs.DamageStruct_Fire then
        return 1
    end
end
--执志
sgs.ai_skill_invoke.sijyu_zhizhi = function(self, data)
    return true
end

--利剑
sgs.ai_skill_invoke.sijyu_lijian = function(self, data)
    local damage = data:toDamage()
    if not self:isFriend(damage.to) then return true end
    return false
end
sgs.ai_skill_discard.sijyu_lijian = function(self, discard_num, min_num, optional, include_equip)
    local usable_cards = sgs.QList2Table(self.player:getCards("he"))
    local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
    if damage then
        if not self:needToLoseHp(self.player, damage.from, damage.card) then
            self:sortByKeepValue(usable_cards)
            local to_discard = {}
            for _, c in ipairs(usable_cards) do
                if #to_discard < discard_num and not c:isKindOf("Peach") then
                    table.insert(to_discard, c:getEffectiveId())
                end
            end
            if #to_discard > 0 and #to_discard == discard_num then
                return to_discard
            end
        end
    end
    return {}
end



--思召
local sijyu_sizhao_skill = {}
sijyu_sizhao_skill.name = "sijyu_sizhao"
table.insert(sgs.ai_skills, sijyu_sizhao_skill)
sijyu_sizhao_skill.getTurnUseCard = function(self)
    if self.player:hasUsed("#sijyu_sizhao") then return end
    return sgs.Card_Parse("#sijyu_sizhao:.:")
end

sgs.ai_skill_use_func["#sijyu_sizhao"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards, true)
    if (self:getUseValue(cards[1]) < 10 and self:getKeepValue(cards[1]) < 10) or self.player:getMaxHp() <= 3 or self:getOverflow() > 0 then
        for _, enemy in ipairs(self.enemies) do
            if self.player:canPindian(enemy) and not hasTuntianEffect(enemy, true) then
                self.sijyu_sizhao_card = cards[1]:getId()
                use.card = card
                use.to:append(enemy)
                return
            end
        end
    end
end

sgs.ai_card_intention["#sijyu_sizhao"] = 70

sgs.dynamic_value.control_card["#sijyu_sizhao"] = true

sgs.ai_use_value["#sijyu_sizhao"] = 9.2
sgs.ai_use_priority["#sijyu_sizhao"] = 9.5

function sgs.ai_skill_pindian.sijyu_sizhao(minusecard, self, requestor)
    if requestor:getHandcardNum() == 1 then
        local cards = sgs.QList2Table(self.player:getHandcards())
        self:sortByKeepValue(cards)
        return cards[1]
    end
    if requestor:getHandcardNum() <= 2 then return minusecard end
end

--搦战
sgs.ai_skill_invoke.sijyu_nuozhan = true

--兴汉
sgs.ai_skill_playerchosen.sijyu_xinghan = function(self, targets)
    if self.player:getRole() == "loyalist" and self.room:getLord() then
        return self.room:getLord()
    end

    if self.player:getRole() == "rebel" then
        local new_targets = sgs.SPlayerList()
        for _, p in sgs.qlist(targets) do
            if p:isLord() then continue end
            new_targets:append(p)
        end
        if not new_targets:isEmpty() then
            return new_targets:at(math.random(0, new_targets:length() - 1))
        end
    end

    return targets:at(math.random(0, targets:length() - 1))
end

--七星

sgs.ai_skill_discard.sijyu_qixing = function(self, discard_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getHandcards())
    local to_discard = {}
    local compare_func = function(a, b)
        return self:getUseValue(a) < self:getUseValue(b)
    end
    table.sort(cards, compare_func)
    for _, card in sgs.list(cards) do
        if #to_discard >= discard_num then break end
        table.insert(to_discard, card:getId())
    end

    return to_discard
end
sgs.ai_skill_playerchosen.sijyu_qixing = function(self, targets)
    return self.player
end

--逢懿
sgs.ai_skill_cardask["@sijyu_fengyi-card"] = function(self, data)
    local judge = data:toJudge()

    if self.room:getMode():find("_mini_46") and not judge:isGood() then
        return "$" .. self.player:handCards():first()
    end
    local ids = self.player:getPile("sijyu_xing")

    if self:needRetrial(judge) then
        local cards = {}
        for _, id in sgs.qlist(ids) do
            table.insert(cards, sgs.Sanguosha:getCard(id))
        end
        local card_id = self:getRetrialCardId(cards, judge)
        if card_id ~= -1 then
            return "$" .. card_id
        end
    end

    return "."
end

sgs.ai_skill_playerchosen.sijyu_fengyi = function(self, targets)
    self:sort(self.friends_noself, "handcard")
    local target = nil
    local n = self.player:getPile("sijyu_xing"):length()
    for _, friend in ipairs(self.friends_noself) do
        if not friend:faceUp() then
            target = friend
            break
        end
        if not target then
            if not self:toTurnOver(friend, n, "sijyu_fengyi") then
                target = friend
                break
            end
        end
    end
    if not target then
        if n >= 3 then
            target = self:findPlayerToDraw(false, n)
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if self:toTurnOver(enemy, n, "sijyu_fengyi") and hasManjuanEffect(enemy) then
                        target = enemy
                        break
                    end
                end
            end
        else
            self:sort(self.enemies)
            for _, enemy in ipairs(self.enemies) do
                if self:toTurnOver(enemy, n, "sijyu_fengyi") and hasManjuanEffect(enemy) then
                    target = enemy
                    break
                end
            end
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if self:toTurnOver(enemy, n, "sijyu_fengyi") and self:hasSkills(sgs.priority_skill, enemy) then
                        target = enemy
                        break
                    end
                end
            end
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if self:toTurnOver(enemy, n, "sijyu_fengyi") then
                        target = enemy
                        break
                    end
                end
            end
        end
    end

    return target
end

sgs.ai_skill_playerchosen.gzj_leishen = function(self, targets)
	local getCmpValue = function(enemy)
		local value = 0
		if not self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player) then return 99 end
		if enemy:hasSkill("hongyan") then
			 return 99
		end
		if self:cantbeHurt(enemy, self.player, 3) or self:objectiveLevel(enemy) < 3
			or (enemy:isChained() and not self:isGoodChainTarget(enemy, self.player, sgs.DamageStruct_Thunder,  3)) then return 100 end
		if not self:isGoodTarget(enemy, self.enemies, nil) then value = value + 50 end
		if enemy:hasArmorEffect("silver_lion") then value = value + 20 end
		if enemy:hasSkills(sgs.exclusive_skill) then value = value + 10 end
		if enemy:hasSkills(sgs.masochism_skill) then value = value + 5 end
		if enemy:isChained() and self:isGoodChainTarget(enemy, self.player, sgs.DamageStruct_Thunder,  3) and #(self:getChainedEnemies(self.player)) > 1 then value = value - 25 end
		if enemy:isLord() then value = value - 5 end
		value = value + enemy:getHp() + self:getDefenseSlash(enemy) * 0.01
		return value
	end

	local cmp = function(a, b)
		return getCmpValue(a) < getCmpValue(b)
	end

	local enemies = self:getEnemies(self.player)
	table.sort(enemies, cmp)
	for _,enemy in ipairs(enemies) do
		if getCmpValue(enemy) < 100 then return enemy end
	end
	return nil
end


sgs.ai_playerchosen_intention.gzj_leishen = sgs.ai_playerchosen_intention.leiji


sgs.ai_slash_prohibit.gzj_leishen = function(self, from, to, card)
	local has_black_card = false
	for _,c in ipairs(sgs.QList2Table(to:getCards("he"))) do
		if c:getSuit() == sgs.Card_Spade then
			has_black_card = true
		end
	end
	local hcard = to:getHandcardNum()
	if self:isFriend(to, from) and has_black_card then return false end
	if to:hasFlag("QianxiTarget") and (not self:hasEightDiagramEffect(to) or self.player:hasWeapon("qinggang_sword")) then return false end
		
	
	if from:getRole() == "rebel" and to:isLord() then
		local other_rebel
		for _, player in sgs.qlist(self.room:getOtherPlayers(from)) do
			if sgs.ai_role[player:objectName()] == "rebel" or sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				other_rebel = player
				break
			end
		end
		if not other_rebel and ((from:getHp() >= 4 and (getCardsNum("Peach", from, self.player) > 0 or from:hasSkills("nosganglie|vsnosganglie"))) or from:hasSkill("hongyan")) then
			return false
		end
	end

	if (self:hasSuit("spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if to:getTreasure() and to:getPile("wooden_ox"):length() > 1 then return true end
end

sgs.ai_skill_invoke.gzj_jiazi = function(self)
	if self.player:hasFlag("DimengTarget") then
		local another
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasFlag("DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_askforag.gzj_jiazi = function(self, card_ids)
    local cards = {}
	for _,id in ipairs(card_ids)do
		table.insert(cards,sgs.Sanguosha:getCard(id))
	end
    for _,c in ipairs(self:poisonCards(cards))do
        return c:getEffectiveId()
    end
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end


sgs.exclusive_skill = sgs.exclusive_skill .. "|gzj_guifen"

sgs.ai_skill_playerchosen.gzj_guifen = function(self, targets)
	local targetlist=sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if player:isLord() then lord = player end
		if self:isEnemy(player) and (not target or target:getHp() < player:getHp()) then
			target = player
		end
	end
	if self.role == "rebel" and lord then return lord end
	if target then return target end
	self:sort(targetlist, "hp")
	if self.player:getRole() == "loyalist" and targetlist[1]:isLord() then return targetlist[2] end
	return nil
end


sgs.ai_slash_prohibit.gzj_guifen = function(self, from, to)
	if from:hasSkill("jueqing") then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if self:isEnemy(to, from) and (to:getHp() == 1 or self:isWeak(to)) then
		if  not (#(self:getEnemies(from)) == 1 and #(self:getFriends(from)) + #(self:getEnemies(from)) == self.room:alivePlayerCount()) then
				return true
		end
	end
end

sgs.wizard_skill = sgs.wizard_skill .. "|gzj_tiandao"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|gzj_tiandao"

sgs.ai_skill_cardask["@gzj_tiandao-card"]=function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("h")
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			all_cards:prepend(sgs.Sanguosha:getCard(id))
		end
	end
	
	if all_cards:isEmpty() then return "." end

	local needTokeep = judge.card:getSuit() ~= sgs.Card_Spade 	and sgs.ai_AOE_data and self:playerGetRound(judge.who) < self:playerGetRound(self.player) 

	if not needTokeep then
		local who = judge.who
		if who:getPhase() == sgs.Player_Judge and not who:getJudgingArea():isEmpty() and who:containsTrick("lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if self.player:hasSkill("gzj_guifen") then keptspade = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not card:hasFlag("using") then
			if card:getSuit() == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptspade == 1 and not self.player:hasSkill("gzj_guifen") then return "." end

	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			self:sortByUseValue(cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(sgs.Sanguosha:getCard(card_id)) then
		return "$" .. card_id
	end

	return "."
end


function sgs.ai_cardneed.gzj_tiandao(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart
			end
		end
	end
end

sgs.gzj_tiandao_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}



















--=====================================================================================
-- E4016 龙血玄黄 / E0059 暗金典藏 新增武将 AI（sfofl_e4_ / sfofl_aj_ 系列）
--=====================================================================================

-- 神馬超：叱霆 / 霆威 / 寂灭
sgs.ai_skill_playerchosen.sfofl_e4_tingwei = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_e4_tingwei = 60

sgs.ai_skill_playerchosen.sfofl_e4_jimie = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_e4_jimie = 70

-- 毌丘儉：摧阵 / 溃离
sgs.ai_skill_cardask["@sfofl_e4_cuizhen"] = function(self, data, pattern)
	local cards = {}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if c:isKindOf("EquipCard") then
			table.insert(cards, c)
		end
	end
	if #cards == 0 then return "." end
	self:sortByKeepValue(cards)
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_skill_choice.sfofl_e4_cuizhen = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "cuizhen_area") then return "cuizhen_area" end
	return items[1]
end

sgs.ai_skill_playerchosen.sfofl_e4_cuizhen = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "equip")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and p:hasEquip() then return p end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_e4_cuizhen = 60

sgs.ai_skill_playerschosen.sfofl_e4_cuizhen = function(self, targets, max, min)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "equip")
	local chosen = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and chosen:length() < min then
			chosen:append(p)
		end
	end
	for _, p in ipairs(targets) do
		if chosen:length() < min then
			chosen:append(p)
		end
	end
	return chosen
end

-- 文欽：李明 / 仇铠
addAiSkills("sfofl_e4_liming").getTurnUseCard = function(self)
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if self.player:getMark("sfofl_e4_liming_" .. c:getEffectiveId()) > 0 then
			return sgs.Card_Parse("#sfofl_e4_liminguse:" .. c:getEffectiveId() .. ":")
		end
	end
	if self.player:getMark("sfofl_e4_liming-PlayClear") > 0 then return end
	local list = self.room:getTag("sfofl_e4_liming_list")
	list = list and list:toString() or ""
	if list == "" then return end
	local parts = list:split("+")
	for i = #parts, 1, -1 do
		local id = tonumber(parts[i])
		if id and self.room:getCardPlace(id) == sgs.Player_DiscardPile
			and sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
			return sgs.Card_Parse("#sfofl_e4_liming:.:")
		end
	end
end

sgs.ai_skill_use_func["#sfofl_e4_liming"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_use_func["#sfofl_e4_liminguse"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_choice.sfofl_e4_liming = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "slash") and #self.enemies > 0 then return "slash" end
	if table.contains(items, "analeptic") then return "analeptic" end
	return items[1]
end

sgs.ai_skill_playerchosen.sfofl_e4_liming_equip = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isFriend(p) then return p end
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_e4_liming_equip = -50

sgs.ai_skill_playerchosen.sfofl_e4_liming_use = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_e4_liming_use = 50

sgs.ai_skill_choice.sfofl_e4_choukai = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "beishui") and self.player:getEquips():isEmpty() then return "beishui" end
	if table.contains(items, "extra") then return "extra" end
	return "damage"
end

sgs.ai_skill_playerchosen.sfofl_e4_choukai = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_e4_choukai = 50

-- 司馬孚：蹒襄 / 臣节
sgs.ai_skill_choice.sfofl_e4_panxiang = function(self, choices, data)
	local items = choices:split("+")
	local damage = data and data:toDamage()
	local kingdom = self.player:getKingdom()
	if damage then
		if damage.to and damage.to:getKingdom() == kingdom then
			if table.contains(items, "panxiang_discard") then return "panxiang_discard" end
		elseif damage.from and damage.from:getKingdom() == kingdom then
			if table.contains(items, "panxiang_give") then return "panxiang_give" end
		end
	end
	return items[1]
end

-- 成濟：狂戾 / 凶肆
sgs.ai_skill_cardask["@sfofl_e4_kuangli-self"] = function(self, data, pattern)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	if #cards == 0 then return "." end
	self.sfofl_e4_kuangli_type = cards[1]:getTypeId()
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_skill_cardchosen.sfofl_e4_kuangli = function(self, who, flags)
	local want = self.sfofl_e4_kuangli_type
	if want then
		for _, c in sgs.qlist(who:getEquips()) do
			if c:getTypeId() == want then return c:getEffectiveId() end
		end
	end
	local card = self:getDangerousCard(who) or self:getValuableCard(who)
	if card then return card:getEffectiveId() end
	for _, c in sgs.qlist(who:getCards(flags)) do
		return c:getEffectiveId()
	end
	return -1
end

addAiSkills("sfofl_e4_xiongsi").getTurnUseCard = function(self)
	if self.player:getMark("@sfofl_e4_xiongsi") > 0 and self.player:getMark("sfofl_e4_xiongsi_damage") >= 3
		and #self.enemies > #self.friends then
		return sgs.Card_Parse("#sfofl_e4_xiongsi:.:")
	end
end
sgs.ai_skill_use_func["#sfofl_e4_xiongsi"] = function(card, use, self)
	use.card = card
end
sgs.ai_use_priority.sfofl_e4_xiongsi = 9.5

-- 李昭&焦伯：佐佑 / 侍守
addAiSkills("sfofl_e4_zuoyou").getTurnUseCard = function(self)
	if self.player:getMark("sfofl_e4_zuoyou-PlayClear") > 0 then return end
	return sgs.Card_Parse("#sfofl_e4_zuoyou:.:")
end
sgs.ai_skill_use_func["#sfofl_e4_zuoyou"] = function(card, use, self)
	local yang = self.player:getChangeSkillState("sfofl_e4_zuoyou") <= 1
	self:sort(self.friends, "hp")
	local target = self.player
	if yang then
		for _, p in ipairs(self.friends) do
			if not self:needKongcheng(p, true) then target = p break end
		end
	else
		for _, p in ipairs(self.friends) do
			if p:getHujia() < 5 then target = p break end
		end
	end
	use.to:append(target)
	use.card = card
end
sgs.ai_use_priority.sfofl_e4_zuoyou = 9.4
sgs.ai_card_intention.sfofl_e4_zuoyou = -40

sgs.ai_skill_playerchosen.sfofl_e4_shishou = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isFriend(p) then return p end
	end
	return self.player
end
sgs.ai_playerchosen_intention.sfofl_e4_shishou = -40

-- 賈充：悖逆 / 定法
addAiSkills("sfofl_e4_beini").getTurnUseCard = function(self)
	if self.player:getMark("sfofl_e4_beini-PlayClear") > 0 then return end
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local has_give = false
		for _, c in sgs.qlist(p:getCards("he")) do
			if not c:isDamageCard() then has_give = true break end
		end
		if has_give or not self:isFriend(p) then
			return sgs.Card_Parse("#sfofl_e4_beini:.:")
		end
	end
end
sgs.ai_skill_use_func["#sfofl_e4_beini"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _, p in ipairs(self.enemies) do
		if p:objectName() ~= self.player:objectName() then
			use.to:append(p)
			use.card = card
			return
		end
	end
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		for _, c in sgs.qlist(p:getCards("he")) do
			if not c:isDamageCard() then
				use.to:append(p)
				use.card = card
				return
			end
		end
	end
end
sgs.ai_use_priority.sfofl_e4_beini = 9.3

sgs.ai_skill_choice.sfofl_e4_beini = function(self, choices, data)
	local items = choices:split("+")
	local jc = data and data:toPlayer()
	if jc and self:isEnemy(jc) and table.contains(items, "beini_use") then return "beini_use" end
	if table.contains(items, "beini_give") then return "beini_give" end
	return items[1]
end

sgs.ai_skill_playerchosen.sfofl_e4_beini = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_e4_beini = 60

sgs.ai_skill_askforag.sfofl_e4_beini = function(self, card_ids)
	local cards = {}
	for _, id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	self:sortByKeepValue(cards)
	return cards[1] and cards[1]:getEffectiveId() or -1
end

sgs.ai_skill_playerchosen.sfofl_e4_dingfa = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and not p:isNude() then return p end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and (self:needToThrowArmor(p) or p:getJudgingArea():length() > 0) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_e4_dingfa = 40

-- 司馬伷：避锋 / 宿望
sgs.ai_skill_invoke.sfofl_e4_bifeng = function(self, data)
	if self.player:faceUp() and self:isWeak() then return false end
	local use = data:toCardUse()
	if use.card and use.card:isKindOf("Slash") then return true end
	return self.player:isWounded() or self.player:getHandcardNum() > 3
end

sgs.ai_skill_invoke.sfofl_e4_suwang = function(self, data)
	if self.player:getHandcardNum() < 4 then return true end
	if self.player:faceUp() then
		for _, p in ipairs(self.friends) do
			if self:isWeak(p) then return true end
		end
	end
	return false
end

sgs.ai_skill_playerschosen.sfofl_e4_suwang = function(self, targets, max, min)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	local chosen = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if self:isFriend(p) and chosen:length() < min then
			chosen:append(p)
		end
	end
	for _, p in ipairs(targets) do
		if chosen:length() < min then
			chosen:append(p)
		end
	end
	return chosen
end
sgs.ai_playerchosen_intention.sfofl_e4_suwang = -30

sgs.ai_skill_cardask["@sfofl_e4_suwang-give"] = function(self, data, pattern)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if #cards == 0 then return "." end
	return "$" .. cards[1]:getEffectiveId()
end

-- 夏侯嵐：迅击 / 双锋 / 归刃 / 义驰
sgs.ai_skill_invoke.sfofl_aj_xunji = function(self, data)
	return #self.enemies > 0
end

sgs.ai_skill_playerchosen.sfofl_aj_xunji = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_aj_xunji = 50

sgs.ai_skill_choice.sfofl_aj_shuangfeng = function(self, choices, data)
	if self:getCardsNum("Slash") > 0 or self:getOverflow() > 0 then return "shuangfeng_play" end
	return "shuangfeng_draw"
end

sgs.ai_skill_playerchosen.sfofl_aj_guiren = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:objectName() ~= self.player:objectName() then return p end
	end
	return self.player
end
sgs.ai_playerchosen_intention.sfofl_aj_guiren = -30

sgs.ai_skill_playerchosen.sfofl_aj_yichi = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:isWounded() then return p end
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_aj_yichi = -60

-- 曹髦：潜龙 / 卫统 / 决进 / 无回
local function sfofl_e4_aiSkillScore(self, name)
	local sk = sgs.Sanguosha:getSkill(name)
	local desc = sgs.Sanguosha:translate(":" .. name:gsub("%$", "")) or ""
	local score = 0
	if sk and sk:isLordSkill() then score = score - 5 end
	if string.find(desc, "摸") then score = score + 3 end
	if string.find(desc, "伤害") then score = score + 2 end
	if string.find(desc, "回复") or string.find(desc, "护甲") then score = score + 1 end
	if string.find(desc, "限定技") or string.find(desc, "觉醒技") or string.find(desc, "主公技") then score = score - 2 end
	return score
end

sgs.ai_skill_choice.sfofl_e4_qianlong = function(self, choices, data)
	local items = choices:split("+")
	local best, bestscore = nil, -99
	for _, name in ipairs(items) do
		local score = sfofl_e4_aiSkillScore(self, name)
		if score > bestscore then best, bestscore = name, score end
	end
	return best or items[1]
end

sgs.ai_skill_choice.sfofl_e4_qianlong_lose = function(self, choices, data)
	local items = choices:split("+")
	local worst, worstscore = nil, 99
	for _, name in ipairs(items) do
		local score = sfofl_e4_aiSkillScore(self, name)
		if score < worstscore then worst, worstscore = name, score end
	end
	return worst or items[1]
end

addAiSkills("sfofl_e4_juejin").getTurnUseCard = function(self)
	if self.player:getMark("@sfofl_e4_juejin") <= 0 then return end
	local gain, loss = 0, 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		local x = math.max(0, p:getHp() - 1)
		if self:isEnemy(p) then
			gain = gain + x
		elseif p:objectName() ~= self.player:objectName() and self:isFriend(p) then
			loss = loss + x
		end
	end
	if self:isWeak() or self.player:getHp() <= 1 or gain > loss then
		return sgs.Card_Parse("#sfofl_e4_juejin:.:")
	end
end
sgs.ai_skill_use_func["#sfofl_e4_juejin"] = function(card, use, self)
	use.card = card
end
sgs.ai_use_priority.sfofl_e4_juejin = 9.9

addAiSkills("sfofl_e4_wuhui").getTurnUseCard = function(self)
	if self.player:getMark("@sfofl_e4_wuhui") <= 0 then return end
	return sgs.Card_Parse("#sfofl_e4_wuhui:.:")
end
sgs.ai_skill_use_func["#sfofl_e4_wuhui"] = function(card, use, self)
	use.card = card
end
sgs.ai_use_priority.sfofl_e4_wuhui = 9.8

-- 司馬昭：谦吞 / 挟征 / 威肆 / 昭凶 / 九锡
sgs.ai_skill_cardchosen.sfofl_e4_qiantun = function(self, who, flags)
	local card = self:getDangerousCard(who) or self:getValuableCard(who)
	if card then return card:getEffectiveId() end
	for _, c in sgs.qlist(who:getCards(flags)) do
		return c:getEffectiveId()
	end
	return -1
end

addAiSkills("sfofl_e4_xiezheng").getTurnUseCard = function(self)
	local seat1
	for _, p in sgs.qlist(self.room:getAllPlayers()) do
		if p:getSeat() == 1 then seat1 = p break end
	end
	if not (seat1 and seat1:isAlive()) then return end
	if seat1:objectName() == self.player:objectName() then return end
	if not self:isEnemy(seat1) then return end
	if self:getCardsNum("Slash") == 0 and not self:isWeak(seat1) then return end
	return sgs.Card_Parse("#sfofl_e4_xiezheng:.:")
end
sgs.ai_skill_use_func["#sfofl_e4_xiezheng"] = function(card, use, self)
	use.card = card
end
sgs.ai_use_priority.sfofl_e4_xiezheng = 4.5
sgs.ai_skill_cardchosen.sfofl_e4_xiezheng = function(self, who, flags)
	local card = self:getDangerousCard(who) or self:getValuableCard(who)
	if card then return card:getEffectiveId() end
	for _, c in sgs.qlist(who:getCards(flags)) do
		return c:getEffectiveId()
	end
	return -1
end

addAiSkills("sfofl_e4_zhaoxiong").getTurnUseCard = function(self)
	if self.player:getMark("@sfofl_e4_zhaoxiong") <= 0 then return end
	local noslash, weak = 0, false
	for _, p in ipairs(self.enemies) do
		if p:isAlive() then
			if getKnownCard(p, "Slash", true) == 0 then noslash = noslash + 1 end
			if self:isWeak(p) then weak = true end
		end
	end
	if noslash > 0 or weak then
		return sgs.Card_Parse("#sfofl_e4_zhaoxiong:.:")
	end
end
sgs.ai_skill_use_func["#sfofl_e4_zhaoxiong"] = function(card, use, self)
	use.card = card
end
sgs.ai_use_priority.sfofl_e4_zhaoxiong = 9.6

sgs.ai_skill_playerchosen.sfofl_e4_zhaoxiong = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_e4_zhaoxiong = 80

sgs.ai_skill_invoke.sfofl_e4_jiuxi_yifu = function(self, data)
	return true
end

sgs.ai_skill_invoke.sfofl_e4_jiuxi_lexian = function(self, data)
	local effect = data:toCardEffect()
	if not (effect and effect.card and effect.to) then return false end
	if (effect.card:isKindOf("SavageAssault") or effect.card:isKindOf("ArcheryAttack"))
		and self:isFriend(effect.to) then return true end
	if (effect.card:isKindOf("GodSalvation") or effect.card:isKindOf("AmazingGrace")
		or effect.card:isKindOf("AllianceFeast") or effect.card:isKindOf("FightTogether"))
		and self:isEnemy(effect.to) then return true end
	return false
end

sgs.ai_skill_cardask["@sfofl_e4_jiuxi_juchang"] = function(self, data, pattern)
	local judge = data:toJudge()
	if not (judge and judge.card) then return "." end
	local wantsuit
	if judge.reason == "lightning" then
		if not (judge.card:getSuit() == sgs.Card_Spade and judge.card:getNumber() >= 2 and judge.card:getNumber() <= 9) then return "." end
		wantsuit = function(c) return not (c:getSuit() == sgs.Card_Spade and c:getNumber() >= 2 and c:getNumber() <= 9) end
	elseif judge.reason == "indulgence" then
		if judge.card:getSuit() == sgs.Card_Heart then return "." end
		wantsuit = function(c) return c:getSuit() == sgs.Card_Heart end
	elseif judge.reason == "supply_shortage" then
		if judge.card:getSuit() == sgs.Card_Club then return "." end
		wantsuit = function(c) return c:getSuit() == sgs.Card_Club end
	end
	if not wantsuit then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if wantsuit(c) then return "$" .. c:getEffectiveId() end
	end
	return "."
end

addAiSkills("sfofl_e4_jiuxi_huben").getTurnUseCard = function(self)
	if self.player:getMark("&sfofl_e4_jiuxi_huben") == 0 then return end
	if self.player:getMark("sfofl_e4_jiuxi_huben-PlayClear") > 0 then return end
	if self:getCardsNum("Slash") > 0 then return end
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards, nil, true)
	for _, c in sgs.list(cards) do
		local slash = dummyCard("slash")
		if slash then
			slash:setSkillName("sfofl_e4_jiuxi_huben")
			slash:addSubcard(c)
			if slash:isAvailable(self.player) and self:aiUseCard(slash).card then
				return slash
			end
		end
	end
end

sgs.ai_guhuo_card.sfofl_e4_jiuxi_huben = function(self, toname, class_name)
	if class_name == "Slash" and self.player:getMark("&sfofl_e4_jiuxi_huben") > 0
		and self.player:getMark("sfofl_e4_jiuxi_huben-PlayClear") == 0 then
		local cards = self:addHandPile("he")
		cards = self:sortByKeepValue(cards, nil, true)
		for _, c in sgs.list(cards) do
			local slash = dummyCard(toname)
			if slash then
				slash:setSkillName("sfofl_e4_jiuxi_huben")
				slash:addSubcard(c)
				return slash:toString()
			end
		end
	end
end


--====================================================================--
--  全武将狂潮（五机甲将/未来战士） AI
--====================================================================--

local function kc_is_fw(player)
	local function isChange(name)
		return name and name:find("^sfofl_kc_.+_change$")
	end
	return player and (isChange(player:getGeneralName()) or isChange(player:getGeneral2Name()))
end

-- 孙尚香：结姻
addAiSkills("sfofl_kc_jieyin").getTurnUseCard = function(self)
	if self.player:getMark("sfofl_kc_jieyin-PlayClear") > 0 then return end
	local male_friend
	for _, p in ipairs(self.friends) do
		if p:isMale() then male_friend = p break end
	end
	if not male_friend then
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:isMale() and not self:isEnemy(p) then male_friend = p break end
		end
	end
	if not male_friend then return end
	-- 优先给出己方装备区无用的装备牌，否则给最不值钱的手牌
	local equip
	for _, c in sgs.qlist(self.player:getEquips()) do
		if not c:isKindOf("Weapon") then equip = c break end
	end
	if equip then
		return sgs.Card_Parse("#sfofl_kc_jieyin:" .. equip:getEffectiveId() .. ":.")
	end
	local cards = self:addHandPile("h")
	cards = self:sortByKeepValue(cards, nil, true)
	local c = cards[1]
	if c then
		return sgs.Card_Parse("#sfofl_kc_jieyin:" .. c:getEffectiveId() .. ":.")
	end
end
sgs.ai_skill_use_func["#sfofl_kc_jieyin"] = function(card, use, self)
	local best
	self:sort(self.friends, "hp")
	for _, p in ipairs(self.friends) do
		if p:isMale() then best = p break end
	end
	if not best then
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:isMale() and not self:isEnemy(p) then best = p break end
		end
	end
	if not best then return end
	use.card = card
	use.to:append(best)
end
sgs.ai_use_priority.sfofl_kc_jieyin = 6
sgs.ai_playerchosen_intention.sfofl_kc_jieyin = -60

-- 孙尚香(变)：灵跃（交给技能卡的 on_use 自行选择装备与虚拟牌）
addAiSkills("sfofl_kc_lingyue").getTurnUseCard = function(self)
	if self.player:getMark("&sfofl_nengliang") < 2 then return end
	-- 收回一件已装备但作用不大的装备（优先马/宝物），或装一件手牌装备
	for _, c in sgs.qlist(self.player:getEquips()) do
		if not c:isKindOf("Weapon") and not c:isKindOf("Armor") then
			return sgs.Card_Parse("#sfofl_kc_lingyue:" .. c:getEffectiveId() .. ":.")
		end
	end
	local cards = self:addHandPile("h")
	for _, c in sgs.qlist(cards) do
		if c:isKindOf("EquipCard") then
			return sgs.Card_Parse("#sfofl_kc_lingyue:" .. c:getEffectiveId() .. ":.")
		end
	end
end
sgs.ai_skill_use_func["#sfofl_kc_lingyue"] = function(card, use, self)
	use.card = card
end
sgs.ai_use_priority.sfofl_kc_lingyue = 8
-- 灵跃虚拟牌选择：优先 杀/决斗 打伤害，否则摸牌
sgs.ai_skill_choice.sfofl_kc_lingyue = function(self, choices)
	if #self.enemies > 0 then
		if table.contains(choices, "duel") then return "duel" end
		if table.contains(choices, "slash") then return "slash" end
	end
	if table.contains(choices, "ex_nihilo") then return "ex_nihilo" end
	if self:isWeak() and table.contains(choices, "peach") then return "peach" end
	return choices[math.random(#choices)]
end
sgs.ai_skill_playerchosen.sfofl_kc_lingyue = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_kc_lingyue = 70

-- 孙尚香(变)：枭影
sgs.ai_skill_playerchosen.sfofl_kc_xiaoying = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:isWounded() then return p end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_kc_xiaoying = -60

-- 孙尚香(变)：光梭
addAiSkills("sfofl_kc_guangsuo").getTurnUseCard = function(self)
	if self.player:getMark("sfofl_kc_guangsuo-PlayClear") > 0 then return end
	for _, p in ipairs(self.enemies) do
		if not p:getCards("ej"):isEmpty() then
			return sgs.Card_Parse("#sfofl_kc_guangsuo:.:")
		end
	end
end
sgs.ai_skill_use_func["#sfofl_kc_guangsuo"] = function(card, use, self)
	use.card = card
end
sgs.ai_skill_playerchosen.sfofl_kc_guangsuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_kc_guangsuo = 80
sgs.ai_use_priority.sfofl_kc_guangsuo = 7

-- 孙尚香(变)：重启（友方未来战士技能结算后重置其限次技）
sgs.ai_skill_invoke.sfofl_kc_chongqi = function(self, data)
	return self.player:getMark("&sfofl_nengliang") >= 3
end

-- 赵云：涯角（回合外用牌必发动）
sgs.ai_skill_invoke.sfofl_kc_yajiao = true

-- 赵云(变)：截天（摸二收益）
sgs.ai_skill_invoke.sfofl_kc_jietian = function(self, data)
	return true
end
-- 截天：敌方被迫对赵云用牌——尽量用废牌/装备
sgs.ai_skill_cardask["@sfofl_kc_jietian"] = function(self, data)
	local cards = self:addHandPile("h")
	cards = self:sortByKeepValue(cards, nil, true)
	for _, c in sgs.list(cards) do
		if not c:isKindOf("Peach") and not c:isKindOf("Jink") then
			return "$" .. c:getEffectiveId()
		end
	end
	return "."
end
sgs.ai_skill_cardask["@sfofl_kc_jietian2"] = function(self, data)
	local cards = self:addHandPile("h")
	cards = self:sortByKeepValue(cards, nil, true)
	for _, c in sgs.list(cards) do
		if c:isKindOf("Slash") or c:isKindOf("Duel") or c:isKindOf("Dismantlement") or c:isKindOf("Snatch") then
			return "$" .. c:getEffectiveId()
		end
	end
	return "."
end

-- 赵云(变)：虹闪
sgs.ai_skill_invoke.sfofl_kc_hongshan = true

-- 赵云(变)：超载（能量>2 时把废牌当数值+1的杀）
addAiSkills("sfofl_kc_chaozai").getTurnUseCard = function(self)
	if self.player:getMark("&sfofl_nengliang") < 2 then return end
	if #self.enemies == 0 then return end
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards, nil, true)
	for _, c in sgs.list(cards) do
		if not c:isKindOf("Peach") then
			return sgs.Card_Parse("#sfofl_kc_chaozai:" .. c:getEffectiveId() .. ":.")
		end
	end
end
sgs.ai_skill_use_func["#sfofl_kc_chaozai"] = function(card, use, self)
	use.card = card
end
sgs.ai_skill_choice.sfofl_kc_chaozai = function(self, choices)
	if #self.enemies > 0 and table.contains(choices, "slash") then return "slash" end
	if self:isWeak() and table.contains(choices, "peach") then return "peach" end
	return choices[1]
end
sgs.ai_skill_playerchosen.sfofl_kc_chaozai = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets[1]
end
sgs.ai_use_priority.sfofl_kc_chaozai = 5

-- 夏侯惇：刚烈
sgs.ai_skill_invoke.sfofl_kc_ganglie = function(self, data)
	local damage = data:toDamage()
	return damage.from and self:isEnemy(damage.from)
end

-- 夏侯惇：清俭（获得牌后扣置多余手牌，回合末给友方）
sgs.ai_skill_invoke.sfofl_kc_qingjian = function(self, data)
	return #self.friends > 0 and self.player:getHandcardNum() > 2
end
sgs.ai_skill_playerchosen.sfofl_kc_qingjian = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_kc_qingjian = -50

-- 夏侯惇(变)：极湮
addAiSkills("sfofl_kc_jiyan").getTurnUseCard = function(self)
	if self.player:getMark("&sfofl_nengliang") < 2 then return end
	return sgs.Card_Parse("#sfofl_kc_jiyan:.:")
end
sgs.ai_skill_use_func["#sfofl_kc_jiyan"] = function(card, use, self)
	use.card = card
end
sgs.ai_skill_choice.sfofl_kc_jiyan = function(self, choices)
	local inrange = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:objectName() ~= self.player:objectName() and self.player:inMyAttackRange(p) and self:isEnemy(p) then
			inrange = inrange + 1
		end
	end
	if inrange >= 1 and table.contains(choices, "jiyan_damage") then return "jiyan_damage" end
	return "jiyan_hujia"
end
sgs.ai_skill_playerschosen.sfofl_kc_jiyan = function(self, targets, min_num, max_num)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	local chosen = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and chosen:length() < max_num then chosen:append(p) end
	end
	if chosen:isEmpty() and targets[1] then chosen:append(targets[1]) end
	return chosen
end
sgs.ai_use_priority.sfofl_kc_jiyan = 6

-- 夏侯惇(变)：超频
sgs.ai_skill_invoke.sfofl_kc_chaopin = function(self, data)
	return self.player:getMark("&sfofl_nengliang") <= 2
		or self.player:getMark("&sfofl_nengliang") < 5
end

-- 颜良文丑：双雄
sgs.ai_skill_invoke.sfofl_kc_shuangxiong = function(self, data)
	return true
end
-- 双雄·决斗转换
addAiSkills("sfofl_kc_shuangxiong_duel").getTurnUseCard = function(self)
	local red = self.player:getMark("sfofl_kc_shuangxiong_black-Clear") > 0
	local black = self.player:getMark("sfofl_kc_shuangxiong_red-Clear") > 0
	if not (red or black) then return end
	local cards = self:addHandPile("h")
	cards = self:sortByKeepValue(cards, nil, true)
	for _, c in sgs.list(cards) do
		if (red and c:isRed()) or (black and c:isBlack()) then
			local duel = dummyCard("duel")
			if duel then
				duel:setSkillName("sfofl_kc_shuangxiong_duel")
				duel:addSubcard(c)
				if duel:isAvailable(self.player) and self:aiUseCard(duel).card then
					return duel
				end
			end
		end
	end
end

-- 颜良文丑(变)：双魔
sgs.ai_skill_invoke.sfofl_kc_shuangmo = true
sgs.ai_skill_choice.sfofl_kc_shuangmo = function(self, choices)
	-- 优先取伤害/过牌类技能
	local prefer = {"paoxiao", "wusheng", "sfofl_kc_jieyin", "sfofl_kc_guangsuo"}
	for _, n in ipairs(prefer) do
		if table.contains(choices, n) then return n end
	end
	return choices[1]
end

-- 颜良文丑(变)：暗域（能量富余且有敌方装备可失效时发动）
sgs.ai_skill_invoke.sfofl_kc_anyu = function(self, data)
	if self.player:getMark("&sfofl_nengliang") < 2 then return false end
	for _, p in ipairs(self.enemies) do
		if not p:getEquips():isEmpty() then return true end
	end
	return false
end

-- 颜良文丑(变)：磁炮
addAiSkills("sfofl_kc_cipao").getTurnUseCard = function(self)
	if self.player:getMark("&sfofl_nengliang") < 2 then return end
	for _, p in ipairs(self.enemies) do
		if kc_is_fw(p) then return sgs.Card_Parse("#sfofl_kc_cipao:.:") end
	end
end
sgs.ai_skill_use_func["#sfofl_kc_cipao"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _, p in ipairs(self.enemies) do
		if kc_is_fw(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end
sgs.ai_playerchosen_intention.sfofl_kc_cipao = 80
sgs.ai_use_priority.sfofl_kc_cipao = 6.5

-- 杜预：三陈（优先对友方，期望其换出不同类别牌再摸牌）
addAiSkills("sfofl_kc_sanchen").getTurnUseCard = function(self)
	if self.player:getMark("sfofl_kc_sanchen-PlayClear") > 0 then return end
	for _, p in ipairs(self.friends) do
		if p:getMark("sfofl_kc_sanchen_to-Clear") == 0 then
			return sgs.Card_Parse("#sfofl_kc_sanchen:.:")
		end
	end
end
sgs.ai_skill_use_func["#sfofl_kc_sanchen"] = function(card, use, self)
	self:sort(self.friends, "handcard")
	for _, p in ipairs(self.friends) do
		if p:getMark("sfofl_kc_sanchen_to-Clear") == 0 then
			use.card = card
			use.to:append(p)
			return
		end
	end
end
sgs.ai_playerchosen_intention.sfofl_kc_sanchen = -30
sgs.ai_use_priority.sfofl_kc_sanchen = 5

-- 杜预：破竹（手牌当出其不意）
addAiSkills("sfofl_kc_pozhu").getTurnUseCard = function(self)
	if self.player:getMark("sfofl_kc_pozhu_ban-Clear") > 0 or self.player:isKongcheng() then return end
	local cards = self:addHandPile("h")
	cards = self:sortByKeepValue(cards, nil, true)
	for _, c in sgs.list(cards) do
		if not c:isKindOf("Peach") then
			local cqb = dummyCard("chuqibuyi")
			if cqb then
				cqb:setSkillName("sfofl_kc_pozhu")
				cqb:addSubcard(c)
				if cqb:isAvailable(self.player) and self:aiUseCard(cqb).card then
					return cqb
				end
			end
		end
	end
end

-- 杜预(变)：超导（友方未来战士输出/回复牌数字+1）
sgs.ai_skill_invoke.sfofl_kc_chaodao = function(self, data)
	if self.player:getMark("&sfofl_nengliang") < 2 then return false end
	local use = data:toCardUse()
	if not (use and use.from and use.card) then return false end
	return self:isFriend(use.from) or use.from:objectName() == self.player:objectName()
end

-- 杜预(变)：重构（敌方用关键牌时无效化）
sgs.ai_skill_invoke.sfofl_kc_chonggou = function(self, data)
	if self.player:getMark("&sfofl_nengliang") < 2 then return false end
	local use = data:toCardUse()
	if not (use and use.from and use.card) then return false end
	if use.from:objectName() == self.player:objectName() then return false end
	if self:isFriend(use.from) then return false end
	return use.card:isKindOf("Slash") or use.card:isKindOf("Duel")
		or use.card:isKindOf("TrickCard") or use.card:isDamageCard()
end
sgs.ai_skill_choice.sfofl_kc_chonggou = function(self, choices)
	if table.contains(choices, "ex_nihilo") then return "ex_nihilo" end
	if table.contains(choices, "slash") then return "slash" end
	if self:isWeak() and table.contains(choices, "peach") then return "peach" end
	return choices[1]
end

-- 专属牌
-- 光影梭：用【闪】后是否视为用【杀】
sgs.ai_skill_invoke.sfofl_kc_guangyingsuo = function(self, data)
	return #self.enemies > 0
end
sgs.ai_skill_playerchosen.sfofl_kc_guangyingsuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets[1]
end
-- 银月枪：转换技状态选择（默认②加次数便于爆发，刀将用①强命）
sgs.ai_skill_choice.sfofl_kc_yinyueqiang = function(self, choices)
	if self:getCardsNum("Slash") >= 2 and table.contains(choices, "yinyueqiang2") then
		return "yinyueqiang2"
	end
	return "yinyueqiang1"
end
-- 风暴战刃：横置与目标距离X的角色
sgs.ai_skill_playerschosen.sfofl_kc_fengbaozhanren = function(self, targets, min_num, max_num)
	targets = sgs.QList2Table(targets)
	local chosen = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and not p:isChained() and chosen:length() < max_num then
			chosen:append(p)
		end
	end
	return chosen
end
-- 未来之心：变身 or 减上限
sgs.ai_skill_choice.sfofl_kc_weilaizhixin = function(self, choices)
	return "weilaizhixin_henshin"
end
-- 万物智联：作为普通锦囊直接使用（智能分配装备交给引擎询问）
