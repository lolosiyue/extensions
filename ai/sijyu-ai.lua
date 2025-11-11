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
        (card:getSkillName() == "sijyu_youlong" and (self.player:getMark("&sijyu_youlong-Clear") == 0))
        and sgs.ai_use_priority[card:getClassName()] and self:getCardsNum("Slash") > 0 then
        sgs.ai_use_priority[card:getClassName()] = sgs.ai_use_priority[card:getClassName()] + 2
    end
end
sgs.ai_card_priority.sijyu_youlong = function(self, card)
    if card:getSkillName() == "sijyu_youlong"
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
            or (self.player:hasSkills("sijyu_youlong") and (card:getSkillName() == "sijyu_youlong" and (self.player:getMark("&sijyu_youlong-Clear") == 0 or self.player:getMark("&sijyu_kehou-Clear") == 0)))
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
    if card and card:getSkillName() == "sijyu_zhuluan" and from and from:getMark("zhuluandamage_lun") == 0 then
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
            if self.player:canPindian(enemy) and not enemy:hasSkills("tuntian+zaoxian") then
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
















