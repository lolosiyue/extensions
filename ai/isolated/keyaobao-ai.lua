-- Fixed b6025acc keyaobao, server QSAN_ENGINE_BUILD domain.
local function known(v,key)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("Keyaobao missing "..key,"keyaobao")end;return v end
local function q(o,m,...)
 if AIValue.isPlayer(o)then if m=="getMark"then m="getStrategyMark"elseif m=="hasFlag"then m="getStrategyFlag"end end
 if not o or type(o[m])~="function"then ai_unsupported("Keyaobao unavailable method "..m,"keyaobao")end
 return known(o[m](o,...),m)
end
local function dummy()return AIUsePlan.new({isDummy=true})end
local function source_pair(self,skill,name,ids)
 -- Card::Parse maps source's literal "to_be_decided" to NoSuit, then
 -- its two material getters derive the resulting color. Preserve construction.
 return q(self,"evaluateOwnerViewAsCard",{source_key=skill,skill=skill,name=name,
  suit=sgs.Card_NoSuit,number=0,subcards=ids})
end
-- Fixed Card::isEquipped, card.cpp319: server build returns false, independently of zone.
local function server_is_equipped(card)return false end
local classes={archery_attack="ArcheryAttack",savage_assault="SavageAssault",god_salvation="GodSalvation",amazing_grace="AmazingGrace"}
local function convert(self,skill,name,ids,first,request)
 -- Card::Parse's unrecognized to_be_decided maps to NoSuit; two same-color costs
 -- derive NoSuitRed/Black, NOT their shared printed suit. Native may reject it.
 local suit=q(first,"isRed")and sgs.Card_NoSuitRed or sgs.Card_NoSuitBlack
 return q(self,"bindTurnConversion",skill,classes[name],{name=name,skill_name=skill,suit=suit,number=0,subcards=ids},request)
end
--change

sgs.ai_skill_invoke.yaochangetupo = function(self, data)
    --[[local num = math.random(0,1)
    if (num == 0) then
        return true
    else
        return false
    end]]
    return false
end

--张角

sgs.ai_skill_invoke.keyaotuzhong = function(self, data)
    if q(self,"isWeak") then return true end
    if self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) > 2 then
        return false
    end
    return sgs.ai_skill_playerchosen.keyaotuzhong(self) ~= nil
end

sgs.ai_skill_playerchosen.keyaotuzhong = function(self, targets)
    --targets = sgs.QList2Table(targets)
    local arr1, arr2 = self:getWoundedFriend(false, true)
    local target = nil
    if #arr1 > 0 and (q(self,"isWeak",arr1[1]) or q(self,"getOverflow") >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then
        target =
            arr1[1]
    end
    if target then
        return target
    end
    if #arr2 > 0 then
        for _, friend in ipairs(arr2) do
            return friend
        end
    end
    return nil
end

sgs.ai_playerchosen_intention.keyaotuzhong = function(self, from, to)
    self:updateIntention(from,to,-50)
end


sgs.ai_fill_skill.keyaotaiping = function(self,inclusive,request)
    local first_found, second_found = false, false
    local first_card, second_card
    if q(self.player,"getHandcardNum") + self.player:getPile("wooden_ox"):length() >= 2 and not q(self.player,"hasFlag","useyaotaiping") then
        local cards = self.player:getHandcards()
        local same_suit = false
        cards = sgs.QList2Table(cards)

        if self.player:getPile("wooden_ox"):length() > 0 then
            for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
                table.insert(cards, q(self,"getKnownCardById",id))
            end
        end

        self:sortByKeepValue(cards)
        local useAll = false
        for _, enemy in ipairs(self.enemies) do
            if q(enemy,"getHp") == 1 and not q(enemy,"hasArmorEffect","vine") and not q(self,"hasEightDiagramEffect",enemy) and q(self,"damageIsEffective",enemy, nil, self.player)
                and q(self,"isWeak",enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
                useAll = true
            end
        end
        for _, fcard in ipairs(cards) do
            local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
            if useAll then fvalueCard = isCard("ArcheryAttack", fcard, self.player) end
            if not fvalueCard and q(fcard,"getSuit") == sgs.Card_Heart then
                first_card = fcard
                first_found = true
                for _, scard in ipairs(cards) do
                    local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
                    if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
                    if not AIValue.sameLegacyIdentity(first_card,scard) and q(scard,"getSuit") == q(first_card,"getSuit")
                        and not svalueCard then
                        local archeryattack = source_pair(self,"keyaotaiping","archery_attack",{q(first_card,"getId"),q(scard,"getId")})

                        assert(archeryattack)

                        local dummy_use = self:evaluateCard(archeryattack, dummy())
                        if dummy_use.card then
                            second_card = scard
                            second_found = true
                            break
                        end
                    end
                end
                if second_card then break end
            end
        end
    end

    if first_found and second_found then
        local first_id = q(first_card,"getId")
        local second_id = q(second_card,"getId")
        local archeryattack = convert(self,"keyaotaiping","archery_attack",{first_id,second_id},first_card,request)
        assert(archeryattack)
        return archeryattack
    end
    local first_found, second_found = false, false
    local first_card, second_card
    if q(self.player,"getHandcardNum") + self.player:getPile("wooden_ox"):length() >= 2 and not q(self.player,"hasFlag","useyaotaiping") then
        local cards = self.player:getHandcards()
        local same_suit = false
        cards = sgs.QList2Table(cards)

        if self.player:getPile("wooden_ox"):length() > 0 then
            for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
                table.insert(cards, q(self,"getKnownCardById",id))
            end
        end

        self:sortByKeepValue(cards)


        for _, fcard in ipairs(cards) do
            local fvalueCard = (isCard("SavageAssault", fcard, self.player))
            if not fvalueCard and q(fcard,"getSuit") == sgs.Card_Spade then
                first_card = fcard
                first_found = true
                for _, scard in ipairs(cards) do
                    local svalueCard = (isCard("SavageAssault", scard, self.player))
                    if not AIValue.sameLegacyIdentity(first_card,scard) and q(scard,"getSuit") == q(first_card,"getSuit")
                        and not svalueCard then
                        local archeryattack = source_pair(self,"keyaotaiping","savage_assault",{q(first_card,"getId"),q(scard,"getId")})

                        assert(archeryattack)

                        local dummy_use = self:evaluateCard(archeryattack, dummy())
                        if dummy_use.card then
                            second_card = scard
                            second_found = true
                            break
                        end
                    end
                end
                if second_card then break end
            end
        end
    end
    if first_found and second_found then
        local first_id = q(first_card,"getId")
        local second_id = q(second_card,"getId")
        local archeryattack = convert(self,"keyaotaiping","savage_assault",{first_id,second_id},first_card,request)
        assert(archeryattack)
        return archeryattack
    end
    local first_found, second_found = false, false
    local first_card, second_card
    if q(self.player,"getHandcardNum") + self.player:getPile("wooden_ox"):length() >= 2 and not q(self.player,"hasFlag","useyaotaiping") then
        local cards = self.player:getHandcards()
        local same_suit = false
        cards = sgs.QList2Table(cards)

        if self.player:getPile("wooden_ox"):length() > 0 then
            for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
                table.insert(cards, q(self,"getKnownCardById",id))
            end
        end

        self:sortByKeepValue(cards)


        for _, fcard in ipairs(cards) do
            local fvalueCard = (isCard("GodSalvation", fcard, self.player))
            if not fvalueCard and q(fcard,"getSuit") == sgs.Card_Diamond then
                first_card = fcard
                first_found = true
                for _, scard in ipairs(cards) do
                    local svalueCard = (isCard("GodSalvation", scard, self.player))
                    if not AIValue.sameLegacyIdentity(first_card,scard) and q(scard,"getSuit") == q(first_card,"getSuit")
                        and not svalueCard then
                        local archeryattack = source_pair(self,"keyaotaiping","god_salvation",{q(first_card,"getId"),q(scard,"getId")})

                        assert(archeryattack)

                        local dummy_use = self:evaluateCard(archeryattack, dummy())
                        if dummy_use.card then
                            second_card = scard
                            second_found = true
                            break
                        end
                    end
                end
                if second_card then break end
            end
        end
    end
    if first_found and second_found then
        local first_id = q(first_card,"getId")
        local second_id = q(second_card,"getId")
        local archeryattack = convert(self,"keyaotaiping","god_salvation",{first_id,second_id},first_card,request)
        assert(archeryattack)
        return archeryattack
    end

    local first_found, second_found = false, false
    local first_card, second_card
    if q(self.player,"getHandcardNum") + self.player:getPile("wooden_ox"):length() >= 2 and not q(self.player,"hasFlag","useyaotaiping") then
        local cards = self.player:getHandcards()
        local same_suit = false
        cards = sgs.QList2Table(cards)

        if self.player:getPile("wooden_ox"):length() > 0 then
            for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
                table.insert(cards, q(self,"getKnownCardById",id))
            end
        end

        self:sortByKeepValue(cards)

        for _, fcard in ipairs(cards) do
            local fvalueCard = (isCard("AmazingGrace", fcard, self.player))
            if not fvalueCard and q(fcard,"getSuit") == sgs.Card_Club then
                first_card = fcard
                first_found = true
                for _, scard in ipairs(cards) do
                    local svalueCard = (isCard("AmazingGrace", scard, self.player))
                    if not AIValue.sameLegacyIdentity(first_card,scard) and q(scard,"getSuit") == q(first_card,"getSuit")
                        and not svalueCard then
                        local archeryattack = source_pair(self,"keyaotaiping","amazing_grace",{q(first_card,"getId"),q(scard,"getId")})

                        assert(archeryattack)

                        local dummy_use = self:evaluateCard(archeryattack, dummy())
                        if dummy_use.card then
                            second_card = scard
                            second_found = true
                            break
                        end
                    end
                end
                if second_card then break end
            end
        end
    end
    if first_found and second_found then
        local first_id = q(first_card,"getId")
        local second_id = q(second_card,"getId")
        local archeryattack = convert(self,"keyaotaiping","amazing_grace",{first_id,second_id},first_card,request)
        assert(archeryattack)
        return archeryattack
    end
end


--界张角


sgs.ai_skill_invoke.kejieyaotuzhong = function(self, data)
    if q(self,"isWeak") then return true end
    if self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) > 2 then
        return false
    end
    return sgs.ai_skill_playerchosen.kejieyaotuzhong(self) ~= nil
end

sgs.ai_skill_playerchosen.kejieyaotuzhong = function(self, targets)
    local arr1, arr2 = self:getWoundedFriend(false, true)
    local target = nil
    if #arr1 > 0 and (q(self,"isWeak",arr1[1]) or q(self,"getOverflow") >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then
        target =
            arr1[1]
    end
    if target then
        return target
    end
    if #arr2 > 0 then
        for _, friend in ipairs(arr2) do
            return friend
        end
    end
    return nil
end

sgs.ai_playerchosen_intention.kejieyaotuzhong = function(self, from, to)
    self:updateIntention(from,to,-50)
end


sgs.ai_fill_skill.kejieyaotaiping = function(self,inclusive,request)
    local first_found, second_found = false, false
    local first_card, second_card
    if q(self.player,"getHandcardNum") + self.player:getPile("wooden_ox"):length() >= 2 then
        local cards = self.player:getHandcards()
        local same_suit = false
        cards = sgs.QList2Table(cards)

        if self.player:getPile("wooden_ox"):length() > 0 then
            for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
                table.insert(cards, q(self,"getKnownCardById",id))
            end
        end

        self:sortByKeepValue(cards)
        local useAll = false
        for _, enemy in ipairs(self.enemies) do
            if q(enemy,"getHp") == 1 and not q(enemy,"hasArmorEffect","vine") and not q(self,"hasEightDiagramEffect",enemy) and q(self,"damageIsEffective",enemy, nil, self.player)
                and q(self,"isWeak",enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
                useAll = true
            end
        end
        for _, fcard in ipairs(cards) do
            local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
            if useAll then fvalueCard = isCard("ArcheryAttack", fcard, self.player) end
            if not fvalueCard and q(fcard,"getSuit") == sgs.Card_Heart then
                first_card = fcard
                first_found = true
                for _, scard in ipairs(cards) do
                    local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
                    if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
                    if not AIValue.sameLegacyIdentity(first_card,scard) and q(scard,"getSuit") == q(first_card,"getSuit")
                        and not svalueCard then
                        local archeryattack = source_pair(self,"kejieyaotaiping","archery_attack",{q(first_card,"getId"),q(scard,"getId")})

                        assert(archeryattack)

                        local dummy_use = self:evaluateCard(archeryattack, dummy())
                        if dummy_use.card then
                            second_card = scard
                            second_found = true
                            break
                        end
                    end
                end
                if second_card then break end
            end
        end
    end

    if first_found and second_found then
        local first_id = q(first_card,"getId")
        local second_id = q(second_card,"getId")
        local archeryattack = convert(self,"kejieyaotaiping","archery_attack",{first_id,second_id},first_card,request)
        assert(archeryattack)
        return archeryattack
    end
    local first_found, second_found = false, false
    local first_card, second_card
    if q(self.player,"getHandcardNum") + self.player:getPile("wooden_ox"):length() >= 2 and not q(self.player,"hasFlag","useyaotaiping") then
        local cards = self.player:getHandcards()
        local same_suit = false
        cards = sgs.QList2Table(cards)

        if self.player:getPile("wooden_ox"):length() > 0 then
            for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
                table.insert(cards, q(self,"getKnownCardById",id))
            end
        end

        self:sortByKeepValue(cards)


        for _, fcard in ipairs(cards) do
            local fvalueCard = (isCard("SavageAssault", fcard, self.player))
            if not fvalueCard and q(fcard,"getSuit") == sgs.Card_Spade then
                first_card = fcard
                first_found = true
                for _, scard in ipairs(cards) do
                    local svalueCard = (isCard("SavageAssault", scard, self.player))
                    if not AIValue.sameLegacyIdentity(first_card,scard) and q(scard,"getSuit") == q(first_card,"getSuit")
                        and not svalueCard then
                        local archeryattack = source_pair(self,"kejieyaotaiping","savage_assault",{q(first_card,"getId"),q(scard,"getId")})

                        assert(archeryattack)

                        local dummy_use = self:evaluateCard(archeryattack, dummy())
                        if dummy_use.card then
                            second_card = scard
                            second_found = true
                            break
                        end
                    end
                end
                if second_card then break end
            end
        end
    end
    if first_found and second_found then
        local first_id = q(first_card,"getId")
        local second_id = q(second_card,"getId")
        local archeryattack = convert(self,"kejieyaotaiping","savage_assault",{first_id,second_id},first_card,request)
        assert(archeryattack)
        return archeryattack
    end
    local first_found, second_found = false, false
    local first_card, second_card
    if q(self.player,"getHandcardNum") + self.player:getPile("wooden_ox"):length() >= 2 and not q(self.player,"hasFlag","useyaotaiping") then
        local cards = self.player:getHandcards()
        local same_suit = false
        cards = sgs.QList2Table(cards)

        if self.player:getPile("wooden_ox"):length() > 0 then
            for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
                table.insert(cards, q(self,"getKnownCardById",id))
            end
        end

        self:sortByKeepValue(cards)


        for _, fcard in ipairs(cards) do
            local fvalueCard = (isCard("GodSalvation", fcard, self.player))
            if not fvalueCard and q(fcard,"getSuit") == sgs.Card_Diamond then
                first_card = fcard
                first_found = true
                for _, scard in ipairs(cards) do
                    local svalueCard = (isCard("GodSalvation", scard, self.player))
                    if not AIValue.sameLegacyIdentity(first_card,scard) and q(scard,"getSuit") == q(first_card,"getSuit")
                        and not svalueCard then
                        local archeryattack = source_pair(self,"kejieyaotaiping","god_salvation",{q(first_card,"getId"),q(scard,"getId")})

                        assert(archeryattack)

                        local dummy_use = self:evaluateCard(archeryattack, dummy())
                        if dummy_use.card then
                            second_card = scard
                            second_found = true
                            break
                        end
                    end
                end
                if second_card then break end
            end
        end
    end
    if first_found and second_found then
        local first_id = q(first_card,"getId")
        local second_id = q(second_card,"getId")
        local archeryattack = convert(self,"kejieyaotaiping","god_salvation",{first_id,second_id},first_card,request)
        assert(archeryattack)
        return archeryattack
    end

    local first_found, second_found = false, false
    local first_card, second_card
    if q(self.player,"getHandcardNum") + self.player:getPile("wooden_ox"):length() >= 2 and not q(self.player,"hasFlag","useyaotaiping") then
        local cards = self.player:getHandcards()
        local same_suit = false
        cards = sgs.QList2Table(cards)

        if self.player:getPile("wooden_ox"):length() > 0 then
            for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
                table.insert(cards, q(self,"getKnownCardById",id))
            end
        end

        self:sortByKeepValue(cards)

        for _, fcard in ipairs(cards) do
            local fvalueCard = (isCard("AmazingGrace", fcard, self.player))
            if not fvalueCard and q(fcard,"getSuit") == sgs.Card_Club then
                first_card = fcard
                first_found = true
                for _, scard in ipairs(cards) do
                    local svalueCard = (isCard("AmazingGrace", scard, self.player))
                    if not AIValue.sameLegacyIdentity(first_card,scard) and q(scard,"getSuit") == q(first_card,"getSuit")
                        and not svalueCard then
                        local archeryattack = source_pair(self,"kejieyaotaiping","amazing_grace",{q(first_card,"getId"),q(scard,"getId")})

                        assert(archeryattack)

                        local dummy_use = self:evaluateCard(archeryattack, dummy())
                        if dummy_use.card then
                            second_card = scard
                            second_found = true
                            break
                        end
                    end
                end
                if second_card then break end
            end
        end
    end
    if first_found and second_found then
        local first_id = q(first_card,"getId")
        local second_id = q(second_card,"getId")
        local archeryattack = convert(self,"kejieyaotaiping","amazing_grace",{first_id,second_id},first_card,request)
        assert(archeryattack)
        return archeryattack
    end
end



--司马懿

sgs.ai_skill_invoke.keyaozhabing = function(self, data)
    if q(self,"isWeak") and q(self,"getAllPeachNum") > 0 then
        return true
    end
    if q(self.player,"getHp") > getBestHp(self.player) then
        return true
    end
    return false
end

sgs.ai_ajustdamage_to["&keyaozhabing"] = function(self, from, to, card, nature)
    return -99
end

sgs.ai_getBestHp_skill.keyaoguimou = function(owner)
    return q(owner,"getMaxHp") - 1
end

--界司马懿

sgs.ai_skill_invoke.kejieyaozhabing = function(self, data)
    if q(self,"isWeak") and q(self,"getAllPeachNum") > 0 then
        return true
    end
    if q(self.player,"getHp") > getBestHp(self.player) then
        return true
    end
    return false
end

sgs.ai_getBestHp_skill.kejieyaoguimou = function(owner)
    return q(owner,"getMaxHp") - 1
end

--周泰
sgs.ai_skill_invoke.kejieyaofenwei = function(self, data)
    return sgs.ai_skill_playerchosen.kejieyaofenwei(self, self.room:getOtherPlayers(self.player)) ~= nil
end
sgs.ai_skill_playerchosen.kejieyaofenwei = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, friend in ipairs(targets) do
        if q(self,"isFriend",friend) and not q(friend,"hasSkill","kejieyaobuhui") then
            return friend
        end
    end
    return nil
end

sgs.ai_playerchosen_intention.kejieyaofenwei = function(self, from, to)
    self:updateIntention(from,to,-50)
end

sgs.ai_skill_invoke.kejieyaofenwei_shouhui = function(self, data)
    return true
end
sgs.ai_skill_invoke.kejieyaofenwei_mopai = function(self, data)
    local target = data:toPlayer()
    if target and q(self,"isEnemy",target) then
        return false
    end
    return true
end

--小乔

sgs.ai_fill_skill.keyaoquwu = function(self,inclusive,request)
    if q(self.player,"hasUsed","#keyaoquwuCard") then return end
    return q(self,"legacySkillSeed","keyaoquwu","#keyaoquwuCard",request)
end

sgs.ai_skill_use_func["#keyaoquwuCard"] = function(card, use, self,request)
    if not q(self.player,"hasUsed","#keyaoquwuCard") then
        self:sort(self.enemies)
        self.enemies = sgs.reverse(self.enemies)
        for _, enemy in ipairs(self.enemies) do
            if q(self.player,"inMyAttackRange",enemy) then
                if q(enemy,"getMark","&keyaoquwu") == 0 then
                    use.card = q(self,"bindSkillCard","keyaoquwu",{},request,nil,"#keyaoquwuCard")
                    if use.to then use.to:append(enemy) end
                    return
                end
            end
        end
        for _, enemy in ipairs(self.enemies) do
            if q(self.player,"inMyAttackRange",enemy) then
                use.card = q(self,"bindSkillCard","keyaoquwu",{},request,nil,"#keyaoquwuCard")
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end
sgs.ai_use_value.keyaoquwuCard = 8.5
sgs.ai_use_priority.keyaoquwuCard = 9.5
sgs.ai_card_intention.keyaoquwuCard = 80

sgs.ai_use_revises.keyaotongque = function(self, card, use)
    if q(card,"isKindOf","Analeptic")
    then
        return false
    end
end

sgs.ai_target_revises.keyaotongque = function(to, card, self, use)
    if q(card,"isKindOf","IronChain") then return true end
end

sgs.ai_fill_skill.kejieyaoquwu = function(self,inclusive,request)
    if (q(self.player,"getMark","canusequwucishu") <= 0) then return end
    --if self.player:usedTimes("#kejieyaoquwuCard") < q(self.player,"getMark","canusequwucishu") then
    return q(self,"legacySkillSeed","kejieyaoquwu","#kejieyaoquwuCard",request)
end

sgs.ai_skill_use_func["#kejieyaoquwuCard"] = function(card, use, self,request)
    self:sort(self.enemies)
    self.enemies = sgs.reverse(self.enemies)
    for _, enemy in ipairs(self.enemies) do
        if q(enemy,"getMark","&kejieyaoquwu") == 0 then
            use.card = q(self,"bindSkillCard","kejieyaoquwu",{},request,nil,"#kejieyaoquwuCard")
            if use.to then use.to:append(enemy) end
            return
        end
    end
    for _, enemy in ipairs(self.enemies) do
        use.card = q(self,"bindSkillCard","kejieyaoquwu",{},request,nil,"#kejieyaoquwuCard")
        if use.to then use.to:append(enemy) end
        return
    end
end

sgs.ai_use_value.kejieyaoquwuCard = 8.5
sgs.ai_use_priority.kejieyaoquwuCard = 9.5
sgs.ai_card_intention.kejieyaoquwuCard = 80

sgs.ai_target_revises.kejieyaotongque = function(to, card, self, use)
    if q(card,"isKindOf","IronChain") then return true end
end
sgs.ai_use_revises.kejieyaotongque = function(self, card, use)
    if q(card,"isKindOf","Analeptic") then use.card = card end
end
sgs.ai_cardneed.kejieyaotongque = function(to, card, self)
    return q(card,"isKindOf","Analeptic")
end


sgs.ai_skill_invoke.kejieyaoquwutwo = function(self, data)
    return true
end

sgs.ai_skill_invoke.kejieyaotongquetwo = function(self, data)
    return true
end

sgs.ai_skill_discard.kejieyaotongquetwo = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    table.insert(to_discard, cards[1]:getEffectiveId())
    return to_discard
end

sgs.ai_skill_choice.kejieyaozhongshangtwo = function(self, choices, data)
    if q(self.player,"getHp") < getBestHp(self.player) then
        return "maxhp"
    end
    return "handmax"
end

--卞氏

sgs.ai_fill_skill.keyaojiahuo = function(self,inclusive,request)
    if q(self.player,"getHandcardNum") < 1 then return end
    if q(self.player,"hasFlag","usedyaojiahuo") then return end
    local cards = sgs.QList2Table(self.player:getCards("h"))
    local subcards = {}
    self:sortByUseValue(cards, true)
    local cardsq = {}
    for _, card in ipairs(cards) do
        if q(card,"isBlack") then table.insert(cardsq, card) end
    end
    if #cardsq == 0 then return end
    if q(self,"getKeepValue",cardsq[1]) > 18 then return end
    if q(self,"getUseValue",cardsq[1]) > 12 then return end
    table.insert(subcards, cardsq[1]:getId())
    local card_str = "Collateral:keyaojiahuo[to_be_decided:0]=" .. table.concat(subcards, "+")
    local AsCard = q(self,"bindTurnConversion","keyaojiahuo","Collateral",{name="collateral",skill_name="keyaojiahuo",suit=cardsq[1]:getSuit(),number=cardsq[1]:getNumber(),subcards=subcards},request)
    assert(AsCard)
    return AsCard
end



sgs.ai_cardneed.keyaojiahuo = function(to, card, self)
    return q(card,"isBlack") and q(to,"getHandcardNum") <= 3
end

sgs.ai_skill_choice.keyaoyaohou = function(self, choices, data)
    local items = choices:split("+")
    local damage = data:toDamage()
    if q(self,"isEnemy",damage.to) then
        return "huode"
    else
        return "mopai"
    end
    return "mopai"
end


--吉平

sgs.ai_fill_skill.keyaoshidu = function(self,inclusive,request)
    if not q(self.player,"isNude") then
        return q(self,"legacySkillSeed","keyaoshidu","#keyaoshiduCard",request)
    end
end

sgs.ai_skill_use_func["#keyaoshiduCard"] = function(card, use, self,request)
    local hand_weapon, cards
    cards = self.player:getHandcards()
    for _, card in sgs.qlist(cards) do
        if q(card,"getSuit") == sgs.Card_Spade and (q(card,"isKindOf","BasicCard") or q(card,"isKindOf","EquipCard")) then
            hand_weapon = card
            break
        end
    end
    self:sort(self.enemies)
    for _, enemy in ipairs(self.enemies) do
        if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy) and q(enemy,"getMark","keyaoshidu" .. q(self.player,"objectName")) == 0 then
            if hand_weapon then
                use.card = q(self,"bindSkillCard","keyaoshidu",{q(hand_weapon,"getId")},request,nil,"#keyaoshiduCard")
                if use.to then
                    use.to:append(enemy)
                end
                break
            end
        end
    end
end

sgs.ai_use_value.keyaoshiduCard = 8.5
sgs.ai_use_priority.keyaoshiduCard = 9.5
sgs.ai_card_intention.keyaoshiduCard = 80

function sgs.ai_cardneed.keyaoshidu(to, card)
    return (q(card,"getSuit") == sgs.Card_Spade) and (q(card,"isKindOf","BasicCard") or q(card,"isKindOf","EquipCard"))
end

sgs.ai_view_as.keyaogongdu = function(card, player, card_place)
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    if card_place ~= sgs.Player_PlaceSpecial and (q(card,"isBlack") and not server_is_equipped(card)) and q(player,"getPhase") == sgs.Player_NotActive
        and q(player,"getMark","Global_PreventPeach") == 0 then
        return ("peach:keyaogongdu[%s:%s]=%d"):format(suit, number, card_id)
    end
end

sgs.ai_card_priority.keyaogongdu = function(self, card)
    if card and table.contains(q(self,"cardSkillNamesKnowledge",card,"keyaogongdu.priority"), "keyaogongdu") then
        return 1
    end
end

sgs.keyaogongdu_suit_value = {
    spade = 6,
    club = 6
}

sgs.ai_cardneed.keyaogongdu = function(to, card)
    return (q(card,"isBlack") and not server_is_equipped(card))
end

--界妖吉平

sgs.ai_fill_skill.kejieyaoshidu = function(self,inclusive,request)
    if q(self.player,"canDiscard",self.player, "he") then
        return q(self,"legacySkillSeed","kejieyaoshidu","#kejieyaoshiduCard",request)
    end
end

sgs.ai_skill_use_func["#kejieyaoshiduCard"] = function(card, use, self,request)
    local hand_weapon, cards
    cards = self.player:getHandcards()
    for _, card in sgs.qlist(cards) do
        if (q(card,"isKindOf","BasicCard") or q(card,"isKindOf","EquipCard")) then
            hand_weapon = card
            break
        end
    end
    self:sort(self.enemies)
    for _, enemy in ipairs(self.enemies) do
        if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy)
            and q(enemy,"getMark","kejieyaoshidu" .. q(self.player,"objectName")) == 0 then
            if hand_weapon then
                use.card = q(self,"bindSkillCard","kejieyaoshidu",{q(hand_weapon,"getId")},request,nil,"#kejieyaoshiduCard")
                if use.to then
                    use.to:append(enemy)
                end
                break
            end
        end
    end
end

sgs.ai_use_value.kejieyaoshiduCard = 8.5
sgs.ai_use_priority.kejieyaoshiduCard = 9.5
sgs.ai_card_intention.kejieyaoshiduCard = 80

function sgs.ai_cardneed.kejieyaoshidu(to, card)
    return (q(card,"isKindOf","BasicCard") or q(card,"isKindOf","EquipCard"))
end

sgs.ai_view_as.kejieyaogongdu = function(card, player, card_place)
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    if card_place ~= sgs.Player_PlaceSpecial and q(card,"isBlack")
        and q(player,"getMark","Global_PreventPeach") == 0 then
        return ("peach:kejieyaogongdu[%s:%s]=%d"):format(suit, number, card_id)
    end
end

sgs.kejieyaogongdu_suit_value = {
    spade = 6,
    club = 6
}

sgs.ai_cardneed.kejieyaogongdu = function(to, card)
    return q(card,"isBlack")
end


--凌统

sgs.ai_skill_invoke.keyaozhongyi = function(self, data)
    return true
end

sgs.ai_getLeastHandcardNum_skill.keyaozhongyi = function(self, player, least)
    if least < 1 then
        return q(player,"getHp")
    end
end

--程昱



ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.keyaoxieqin",registry="ai_choicemade_filter",path={"cardChosen","keyaoxieqin"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"},self_index=1,defer_canonical=true}

sgs.ai_skill_playerchosen.keyaoxieqin = function(self, targets)
    targets = sgs.QList2Table(targets)
    if self:findPlayerToDiscard("he", true, false, targets, "keyaoxieqin") ~= {} then
        local target = self:findPlayerToDiscard("he", true, false, targets, "keyaoxieqin")[1]
        return target
    end
    return nil
end

sgs.ai_skill_choice["keyaoshiwei"] = function(self, choices, data)
    local items = choices:split("+")
    return items[math.random(1, #items)]
end



sgs.ai_skill_invoke.keyaoshiwei = function(self, data)
    return true
end


ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.kejieyaoxieqin",registry="ai_choicemade_filter",path={"cardChosen","kejieyaoxieqin"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"},self_index=1,defer_canonical=true}

sgs.ai_skill_invoke.kejieyaoxieqin = function(self, data)
    return sgs.ai_skill_playerchosen.kejieyaoxieqin(self, self.room:getOtherPlayers(data:toDamage().to)) ~= nil
end
sgs.ai_skill_playerchosen.kejieyaoxieqin = function(self, targets)
    targets = sgs.QList2Table(targets)

    if self:findPlayerToDiscard("he", true, false, targets, "kejieyaoxieqin") ~= {} then
        local target = self:findPlayerToDiscard("he", true, false, targets, "kejieyaoxieqin")[1]
        return target
    end
    return nil
end

sgs.ai_playerchosen_intention.kejieyaoxieqin = 80

sgs.ai_skill_invoke.kejieyaoshiwei = function(self, data)
    return true
end

sgs.ai_skill_choice["kejieyaoshiwei"] = function(self, choices, data)
    local items = choices:split("+")
    return items[math.random(1, #items)]
end

