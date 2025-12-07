sgs.ai_skill_invoke.s4_cloud_yongqian = true

sgs.ai_skill_playerchosen.s4_cloud_yongqian = function(self, targets)
    self:sort(self.enemies, "handcard")
    for _, enemy in ipairs(self.enemies) do
        if self:canAttack(enemy, self.player) and not self:canLiuli(enemy, self.friends_noself) and
            not self:findLeijiTarget(enemy, 50, self.player) then
            return enemy
        end
    end
    return nil
end
function sgs.ai_cardneed.s4_cloud_yongqian(to, card)
    return to:getHandcardNum() < 3 and card:isKindOf("Slash")
end

function sgs.ai_cardneed.s4_cloud_tuxi(to, card)
    return to:isKongcheng()
end

sgs.ai_skill_choice.s4_cloud_tuxi = function(self, choices)
    return "1"
end

sgs.ai_skill_invoke.s4_cloud_tuxi = function(self, data)
    local target = data:toPlayer()
    if target and self:isEnemy(target) then
        if self.player:getHandcardNum() <= target:getHandcardNum() then
            return true
        end
        if self.player:getHp() <= target:getHp() then
            return true
        end
        if self.player:getEquips():length() <= target:getEquips():length() and self.player:canDiscard(self.player, "he") then
            return true
        end
    end
    return false
end

sgs.ai_skill_discard.s4_cloud_tuxi = function(self, discard_num, min_num, optional, include_equip)
    local target = self.room:getCurrent()

    if not target then
        return {}
    end
    if self:isEnemy(target) then
        if self.player:getHp() > 1 then
            return {}
        end
        return self:askForDiscard("dummy", 1, 1, false, include_equip)
    end
    return {}
end

sgs.ai_choicemade_filter.skillInvoke.s4_cloud_tuxi = function(self, player, promptlist)
    local current = self.room:getCurrent()
    if promptlist[#promptlist] == "yes" then
        if not self:needToLoseHp(current, player, nil) then
            sgs.updateIntention(player, current, 40)
        end
    end
end
sgs.drawpeach_skill = sgs.drawpeach_skill .. "|s4_cloud_tuxi"

sgs.ai_skill_invoke.s4_cloud_liegong = function(self, data)
    return sgs.ai_skill_invoke.liegong(self, data)
end

function sgs.ai_cardneed.s4_cloud_liegong(to, card)
    return to:getHandcardNum() < 3 and card:isKindOf("Slash")
end

sgs.card_value.s4_cloud_liegong = {
    Analeptic = 4.9,
    Slash = 7.2
}

sgs.ai_ajustdamage_from.s4_cloud_liegong = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and to and (to:getHp() >= from:getHp() or to:getHp() <= from:getAttackRange()) and not beFriend(to, from)
    then
        return 1
    end
end

sgs.ai_canliegong_skill.s4_cloud_liegong = function(self, from, to)
	return to:getHandcardNum() >= from:getHp() or to:getHandcardNum() <= from:getAttackRange()
end

sgs.ai_use_revises.s4_cloud_yongyi = function(self, card, use)
    local record = self.player:property("s4_cloud_yongyiRecords"):toString()
    local suit = card:getSuitString()
    local records
    if (record) then
        records = record:split(",")
    end
    if records and (not table.contains(records, suit) or not card:hasSuit())
        and card and card:getClassName() and sgs.ai_use_priority[card:getClassName()] then
        sgs.ai_use_priority[card:getClassName()] = sgs.ai_use_priority[card:getClassName()] + 5
    end
end

sgs.ai_skill_invoke.s4_cloud_yongyi = function(self, data)
    local card = data:toCard()
    local record = self.player:property("s4_cloud_yongyiRecords"):toString()
    local records
    if (record) then
        records = record:split(",")
    end
    if self:isWeak() and #records <= 2 then
        return false
    end
    return true
end

local s4_cloud_yongyi_skill = {}
s4_cloud_yongyi_skill.name = "s4_cloud_yongyi"
table.insert(sgs.ai_skills, s4_cloud_yongyi_skill)
s4_cloud_yongyi_skill.getTurnUseCard = function(self)
    if self.player:getMark("s4_cloud_yongyi_used-Clear") == 0 then
        return sgs.Card_Parse("#s4_cloud_yongyi:.:analeptic")
    end
    return nil
end

sgs.ai_skill_use_func["#s4_cloud_yongyi"] = function(card, use, self)
    local record = self.player:property("s4_cloud_yongyiRecords"):toString()
    local records

    if (record) then
        records = record:split(",")
    end
    local fs = sgs.Sanguosha:cloneCard("analeptic")
    fs:deleteLater()
    if fs then
        fs:setSkillName("s4_cloud_yongyi")
        local d = self:aiUseCard(fs)
        if fs:isAvailable(self.player) and #records > 0 and d.card and use.to then
            sgs.ai_use_priority.s4_cloud_yongyi = sgs.ai_use_priority.Analeptic
            use.card = sgs.Card_Parse("#s4_cloud_yongyi:.:analeptic")
            return
        end
    end
end
sgs.ai_use_priority["#s4_cloud_yongyi"] = sgs.ai_use_priority.Analeptic
sgs.ai_use_priority["s4_cloud_yongyi"] = sgs.ai_use_priority.Analeptic
sgs.ai_use_value["#s4_cloud_yongyi"] = 5

sgs.ai_guhuo_card.s4_cloud_yongyi = function(self, toname, class_name)
    if (class_name == "Analeptic") and sgs.Sanguosha:getCurrentCardUseReason() ==
        sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
        return "#s4_cloud_yongyi:.:" .. toname
    end
end

sgs.card_value.s4_cloud_yongyi = {
    Analeptic = 4.9,
    Slash = 7.2
}

sgs.ai_skill_defense.s4_cloud_yongyi = function(self, to)
    return #to:property("s4_cloud_yongyiRecords"):toString():split(",")
end

sgs.hit_skill = sgs.hit_skill .. "|s4_cloud_yongyi"


sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|s4_cloud_yingzi"
sgs.need_equip_skill = sgs.need_equip_skill .. "|s4_cloud_yingzi"



sgs.card_value.s4_xianfeng = {
    Slash = 7.2
}
sgs.double_slash_skill = sgs.double_slash_skill .. "|s4_xianfeng"
function sgs.ai_cardneed.s4_xianfeng(to, card)
    return card:isKindOf("Slash")
end

sgs.ai_skill_discard.s4_jiwu_invoke = function(self, discard_num, min_num, optional, include_equip)
    if min_num > 0 and (self.player:getCardCount() >= 2 or self:isWeak()) then
        return self:askForDiscard("dummy", min_num, min_num, false, include_equip)
    end
    return {}
end

sgs.ai_skill_choice.s4_jiwu = function(self, choices, data)
    local items = choices:split("+")
    local use = data:toCardUse()
    if table.contains(items, "s4_jiwu_nullified") then
        for _, to in sgs.qlist(use.to) do
            if self:isFriend(to) and use.from and not self:isFriend(use.from) and
                (self:isWeak(to) or self:hasHeavyDamage(use.from, use.card, to)) then
                if not (self:hasCrossbowEffect(use.from) or use.from:hasSkills(sgs.double_slash_skill)) or
                    getCardsNum("Slash", use.from) < 1 then
                    return "s4_jiwu_nullified"
                end
            end
        end
    end
    if table.contains(items, "s4_jiwu_draw") then
        if not use.card:hasFlag("s4_jiwu_nullified") then
            local invoke = true
            for _, to in sgs.qlist(use.to) do
                if ((use.card:isKindOf("Slash") and getCardsNum("Jink", to) > 0) or
                        (use.card:isKindOf("Duel") and getCardsNum("Nullification", to) > 0)) and
                    not self:needToLoseHp(to, use.from, use.card) then
                    invoke = false
                    break
                end
            end
            if invoke or use.card:hasFlag("s4_jiwu_no_respond") then
                return "s4_jiwu_draw"
            end
        end
    end
    if table.contains(items, "s4_jiwu_no_respond_list") then
        if use.from and self:isFriend(use.from) and not use.card:hasFlag("s4_jiwu_nullified") then
            for _, to in sgs.qlist(use.to) do
                if self:isEnemy(to) and
                    (self:isWeak(to) or self:hasHeavyDamage(use.from, use.card, to) or use.card:hasFlag("s4_jiwu")) then
                    if ((use.card:isKindOf("Slash") and getCardsNum("Jink", to) > 0 and
                                not (self:canLiegong(to, use.from))) or
                            (use.card:isKindOf("Duel") and getCardsNum("Slash", to, use.from) > 0)) then
                        return "s4_jiwu_no_respond_list"
                    end
                end
            end
        end
    end
    return "cancel"
end

function sgs.ai_cardneed.s4_jiwu(to, card)
    return to:getHandcardNum() < 3 and card:isKindOf("Slash")
end

sgs.card_value.s4_jiwu = {
    Slash = 7.2
}
sgs.hit_skill = sgs.hit_skill .. "|s4_jiwu"

sgs.ai_skill_askforag.s4_jiuzhu = function(self,card_ids)
	local cards = {}
	for _,id in ipairs(card_ids)do
        if sgs.Sanguosha:getEngineCard(id):isKindOf("BasicCard") then
		    table.insert(cards,sgs.Sanguosha:getEngineCard(id))
        end
	end
	self.yanyu_need_player = nil
	local card,player = self:getCardNeedPlayer(cards,true)
	if card and player then
		self.yanyu_need_player = player
		return card:getEffectiveId()
	end
	return card_ids[1]
end
sgs.ai_skill_playerchosen.s4_jiuzhu = function(self,targets)
    if self.player:hasFlag("s4_jiuzhu_current") then
        local current = self.room:getCurrent()
        if current and self:doDisCard(current, "he", true) then
            return current
        end
        return nil
    end
	local only_id = self.player:getMark("YanyuOnlyId")-1
    if only_id<0 then
        return self.yanyu_need_player
    else
        local card = sgs.Sanguosha:getEngineCard(only_id)
        local c,player = self:getCardNeedPlayer({ card },true)
        if player then
            return player
        end
    end
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense")
	for _,p in ipairs(targets)do
		if self:isFriend(p) and self:canDraw(p) then return p end
	end
    return self.player
end

sgs.ai_skill_discard.s4_jiuzhu_invoke = function(self, discard_num, min_num, optional, include_equip)
    if min_num > 0 and self.player:getHp() < getBestHp(self.player) then
        return self:askForDiscard("dummy", min_num, min_num, false, include_equip)
    end
    return {}
end
sgs.ai_skill_invoke.s4_jiuzhu = true

sgs.ai_choicemade_filter.cardChosen.s4_jiuzhu = sgs.ai_choicemade_filter.cardChosen.snatch
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|s4_jiuzhu"
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|s4_jiuzhu"


function SmartAI:getGeneralDuelCard(player, cards)
    player = player or self.player
	cards = cards or player:getHandcards()
	cards = sgs.QList2Table(cards)
	if #cards<1 then return end
    if player:hasSkill("s4_txbw_yishi") then
        self:sortByUseValue(cards, true)
        return cards[1]
    end
	local max_card,max_point = nil,0
	for _,card in ipairs(cards)do
		if player==self.player and self:isValuableCard(card) then continue end
		if self.player:canSeeHandcard(player) or card:hasFlag("visible")
		or card:hasFlag("visible_"..self.player:objectName().."_"..player:objectName()) then
			local point = card:getNumber()
			--add
			if point>max_point then max_point = point max_card = card end
		end
	end
	if player==self.player and not max_card then
		for _,card in ipairs(cards)do
			local point = card:getNumber()
			--add
			if point>max_point then max_point = point max_card = card end
		end
	end
	if player~=self.player then return max_card end
	if max_point>0 then
	end
	return max_card
end

function SmartAI:getGeneralDuelPoint(player, card)
    if not card then return end
    player = player or self.player
    local x = card:getNumber()
    if player:hasSkill("s4_txbw_motian") then
        x = x + player:getMark("TurnLengthCount")
    end
    return x
end

sgs.ai_fill_skill.s4_txbw_general_duel = function(self)
	return sgs.Card_Parse("#s4_txbw_general_duel_start:.:")
end

sgs.ai_skill_use_func["#s4_txbw_general_duel_start"] = function(card,use,self)
    local target
    self:sort(self.enemies,"handcard")
    local max_card = self:getGeneralDuelCard()
    if not max_card then return end

    local damage = sgs.DamageStruct()
    damage.card = nil
    damage.from = self.player
    damage.reason = "s4_txbw_general_duel"
    damage.damage = 1

    local max_point = self:getGeneralDuelPoint(self.player, max_card)
    for _,enemy in ipairs(self.enemies)do
        damage.to = enemy
        if self:damageStruct(damage) then
            if self:cantDamageMore(enemy, self.player) then
                if self.player:getMark("&s4_txbw_luoyi") > 0 then 
                    continue
                end
                if self.player:hasSkill("s4_txbw_wanpo") and not enemy:isWounded() then 
                    continue
                end
            end
            local enemy_max_card = self:getGeneralDuelCard(enemy)
            local enemy_max_point = enemy_max_card and self:getGeneralDuelPoint(enemy, enemy_max_card) or 100
            if (enemy_max_card and (max_point>enemy_max_point))  then
                self.s4_txbw_general_duel_start_card = max_card:getId()
                use.card = card
                use.to:append(enemy)
                return
            end
		end
	end
    for _,enemy in ipairs(self.enemies)do
        damage.to = enemy
        if self:damageStruct(damage) then
            local enemy_max_card = self:getGeneralDuelCard(enemy)
            local enemy_max_point = enemy_max_card and self:getGeneralDuelPoint(enemy, enemy_max_card) or 100
            if (enemy_max_card and (max_point>enemy_max_point)) or (max_point > 7) then
                self.s4_txbw_general_duel_start_card = max_card:getId()
                use.card = card
                use.to:append(enemy)
                return
            end
		end
	end
end

sgs.ai_card_intention["s4_txbw_general_duel_start"] = 80

sgs.ai_skill_discard.s4_txbw_general_duel = function(self, discard_num, min_num, optional, include_equip)
    if self.s4_txbw_general_duel_start_card then return { self.s4_txbw_general_duel_start_card } end
    if self:getGeneralDuelCard(self.player) then
        return { self:getGeneralDuelCard(self.player):getId() }
    end
    return self:askForDiscard("dummy", min_num, min_num, false, include_equip)
end

sgs.ai_cardneed.s4_txbw_general_duel = sgs.ai_cardneed.bignumber

sgs.ai_skill_invoke.s4_txbw_luoyi = sgs.ai_skill_invoke.luoyi

sgs.ai_skill_invoke.s4_txbw_feidang = function(self, data)
    local hand_weapon,cards
    cards = self.player:getHandcards()
    for _,card in sgs.qlist(cards)do
        if card:isKindOf("Weapon") then
            hand_weapon = card
            break
        end
    end
    if hand_weapon or self.player:getWeapon() then
        return true
    end
    local enemy = data:toPlayer()
    if enemy and self.player:getHp()>enemy:getHp() and self.player:getHp()>1 then
        return true
    end
    return false
end

sgs.ai_skill_cardask["@s4_txbw_feidang"] = function(self,data,pattern,target)
    return true
end

sgs.ai_skill_playerchosen.s4_txbw_tuxi = function(self, targets)
    self:sort(self.enemies, "handcard")
    for _, enemy in ipairs(self.enemies) do
        if self:doDisCard(enemy, "h",true) then
            return enemy
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if self:doDisCard(friend, "h", true) then
            return friend
        end
    end
    return nil
end

sgs.ai_playerchosen_intention.s4_txbw_tuxi = function(self,from,to)
	if not hasTuntianEffect(to) then
		sgs.updateIntention(from,to,40)
	end
end

sgs.ai_fill_skill.s4_txbw_zhenyue = function(self)
    return sgs.Card_Parse("#s4_txbw_zhenyue:.:")
end

sgs.ai_skill_use_func["#s4_txbw_zhenyue"] = function(card,use,self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
    for _, c in ipairs(cards) do
        if c:getNumber() == self.player:getMark("&s4_txbw_zhenyue") and not self:willUse(self.player, c) then
            use.card = sgs.Card_Parse("#s4_txbw_zhenyue:" .. c:getEffectiveId() .. ":")
            return
        end
    end
end

sgs.ai_card_priority["s4_txbw_zhenyue"] = 7

sgs.ai_fill_skill.s4_txbw_huibian = function(self)
    return sgs.Card_Parse("#s4_txbw_huibian:.:")
end

sgs.ai_skill_use_func["#s4_txbw_huibian"] = function(card,use,self)
    self:sort(self.friends_noself, "hp")
    local target1, target2
    for _, friend in ipairs(self.friends_noself) do
        if friend:getHp() > 1 and self:canDamage(friend,self.player, nil) and self:canDraw(friend) then
            target1 = friend
            break
        end
    end
    if not target1 then
        for _, enemy in ipairs(self.enemies) do
            if enemy:getHp() > 1 and self:canDamage(enemy,self.player, nil) then
                target1 = enemy
                break
            end
        end
    end
    if not target1 then return end
    for i = #self.friends_noself, 1, -1 do
        local friend = self.friends_noself[i]
        if friend:isWounded() and friend:objectName() ~= target1:objectName() then
            target2 = friend
            break
        end
    end
    if target1 and target2 then
        use.card = sgs.Card_Parse("#s4_txbw_huibian:.:")
        use.to:append(target1)
        use.to:append(target2)
        return
    end
end

sgs.ai_skill_invoke.s4_txbw_hujia = function(self, data)
    local target = data:toPlayer()
    if target and self:isFriend(target) then
        return true
    end
    return false
end

sgs.ai_choicemade_filter.skillInvoke.s4_txbw_hujia = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-80) end
	end
end

sgs.ai_target_revises.s4_txbw_yizhong = function(to,card,self)
	if card:isBlack() and card:isKindOf("Slash")
	then return true end
end

sgs.ai_skill_invoke.s4_txbw_niansheng = sgs.ai_skill_invoke.luanfeng

sgs.ai_ajustdamage_to["&s4_txbw_niansheng"] = function(self, from, to, card, nature)
    return -99
end

sgs.ai_skill_playerchosen.s4_txbw_taohui = sgs.ai_skill_playerchosen.mingjian

sgs.ai_playerchosen_intention.s4_txbw_taohui = -40

sgs.ai_skill_cardask["@s4_txbw_lianpo"] = true

sgs.ai_suppress_intention["s4_txbw_yanglei"] = true

sgs.ai_skill_choice.s4_txbw_yanglei = function(self, choices, data)
    local items = choices:split("+")
    local draw = getChoice(choices, "draw")
    local recover = getChoice(choices, "recover")
    local damage = data:toDamage()
    local target = damage.to
    if target and self:isFriend(target) then
        if ZishuEffect(target) > 0 and self:canDraw(target) then
            return draw
        end
        if recover and self:isWeak(target) then
            return recover
        end
    else
        if ZishuEffect(target) <= 0 or not self:canDraw(target) then
            for _, skill in sgs.list(target:getVisibleSkillList()) do
                local s = sgs.Sanguosha:getTriggerSkill(skill:objectName())
                if s and s:hasEvent(sgs.DrawNCards) then
                    return draw
                end
            end
        end
    end
    
    return "cancel"
end

sgs.ai_skill_playerchosen.s4_txbw_jushou = function(self, targets)
    self:sort(self.friends_noself, "hp")
    if sgs.ai_skill_invoke.nosjushou(self, "") then
        return self.player
    end
    return nil
end

sgs.ai_skill_invoke.s4_txbw_chili = function(self, data)
    return sgs.ai_skill_playerchosen.s4_txbw_chili(self, nil) ~= nil
end

sgs.ai_skill_playerchosen.s4_txbw_chili = function(self, targets)
    return self:findPlayerToDiscard("ej",true,false,targets,"")[1]
end

sgs.ai_choicemade_filter.cardChosen.s4_txbw_chili = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_cardsview_valuable.s4_txbw_chili = function(self, class_name, player)
	if class_name ~= "Nullification" then return end
	local nullification = sgs.Sanguosha:cloneCard("nullification")
	if player:getMark("@s4_txbw_general_1") > 0 then
		return ("nullification:s4_txbw_chili[no_suit:-1]=.")
	end
end


sgs.ai_skill_invoke.s4_txbw_yishi = function(self, data)
    local card = self.player:getTag("s4_txbw_general_duel_card"):toCard()
    if card and card:getNumber() <= 7 then
        return true
    end
    return false
end


sgs.ai_fill_skill.s4_txbw_qiaobian = function(self)
    return sgs.Card_Parse("#s4_txbw_qiaobian:.:")
end

sgs.ai_skill_use_func["#s4_txbw_qiaobian"] = function(card,use,self)
    local target1, target2
    if sgs.ai_skill_invoke.peiqi(self, ToData()) then
        for _,target in sgs.list(self.room:getAlivePlayers())do
			if target:objectName()==self.peiqiData.from:objectName()
			then target1 = target break end
		end
        local first_place = self.room:getCardPlace(self.peiqiData.cid)
        local card = sgs.Sanguosha:getEngineCard(self.peiqiData.cid)
        local second_area = ""
        if first_place == sgs.Player_PlaceHand then
            second_area = "h"
        elseif first_place == sgs.Player_PlaceEquip then
            second_area = "e"
        elseif first_place == sgs.Player_PlaceDelayedTrick then
            second_area = "j"
        end
        for _,target in sgs.list(self.room:getAlivePlayers())do
            if target:objectName()==self.peiqiData.to:objectName() and target:getCards(""..second_area):length()>0
            then target2 = target break end
        end
        for _,target in sgs.list(self.room:getAlivePlayers())do
            if target:getCards(""..second_area):length()>0
            then target2 = target break end
        end
    end
    if not target1 then
        if self.player:isKongcheng() then return end
        for _,target in sgs.list(self.room:getOtherPlayers(self.player))do
            if target:getCards("h"):length()>0 and self:doDisCard(target, "h", true)
            then 
                target1 = self.player
                target2 = target 
                break 
            end
        end
    end
    
    if target1 and target2 and target1:objectName() ~= target2:objectName() then
        use.card = sgs.Card_Parse("#s4_txbw_qiaobian:.:")
        use.to:append(target1)
        use.to:append(target2)
        return
    end
end
sgs.ai_skill_cardchosen.s4_txbw_qiaobian = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		local id = e:getEffectiveId()
		if id==self.peiqiData.cid
		then return id end
	end
    if who:objectName() == self.player:objectName() then
        local cards = self.player:getCards(flags)
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        return cards[1]:getEffectiveId()
    end
end

sgs.ai_skill_cardask["@s4_txbw_hongwu"] = function(self, data, pattern, target)
    local player = data:toPlayer()
    if self.player:objectName() == player:objectName() then
        return true
    end
    if self:isFriend(player) then
        return true
    end
    return "."
end


sgs.ai_skill_invoke.s4_txbw_xiaoguo = function(self, data)
    if self:getCardsNum("BasicCard") > 0 then
        return false
    end
    if player:getMaxHp() - player:getHandcardNum() < 1 then
        return false
    end
    return true
end

sgs.ai_skill_invoke.s4_txbw_shenwei = true

sgs.ai_skill_choice.s4_txbw_tianjian = sgs.ai_skill_choice.benghuai

sgs.ai_skill_cardask["@s4_txbw_zhisun"] = function(self, data, pattern, target)
    local number = data:toInt()
    local self_number = self.player:getTag("s4_txbw_general_duel_card"):toCard():getNumber()
    if self_number < number then
        return true
    end
    return "."
end





sgs.ai_skill_invoke.s4_weiT_lord = function(self, data)
    return true
end
sgs.ai_skill_invoke.s4_weiT_adviser = function(self, data)
    return true
end
sgs.ai_skill_invoke.s4_weiT_gerenal = function(self, data)
    return true
end

sgs.ai_skill_invoke.s4_weiT_xionglue = function(self, data)
    return true
end
sgs.ai_skill_invoke.s4_weiT_naxian = function(self, data)
    return true
end

sgs.ai_skill_invoke.s4_shiyong = function(self, data)
    local x = self.player:getHp() - self.player:getHandcardNum()
    if x < 2 then
        return true
    end
    if self:needToLoseHp(self.player) or hasZhaxiangEffect(self.player) then
        return true
    end
    if self.player:getHp() + self:getAllPeachNum() > 1 then
        return true
    end
    local current = self.room:getCurrent()
    if not current or current:getPhase() == sgs.Player_NotActive then return end
    if self.player:getMark("&s4_shiyong-"..current:getPhase().."Clear") > 0 then
        return true
    end
    return false
end



local s4_beizhen_skill = {}
s4_beizhen_skill.name = "s4_beizhen"
table.insert(sgs.ai_skills, s4_beizhen_skill)
s4_beizhen_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("s4_beizhen_buff") then
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Jink") or card:isKindOf("Peach") then
				return sgs.Card_Parse(("duel:s4_beizhen[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId()))
			end
		end
	end
end

sgs.ai_skill_invoke.s4_beizhen = function(self, data)
    if self:doDisCard(self.player ,"hej") then
        return true
    end
    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
    duel:deleteLater()
    local dummy_use = self:aiUseCard(duel, dummy())
	if dummy_use.card and dummy_use.to:length() > 0 then
		return true
    end
    return false
end
sgs.ai_skill_choice.s4_beizhen = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "damage") and self.player:getHp() + self:getAllPeachNum() - 1 <= 0 then
        return "damage"
    end
    table.removeOne(items, "cancel")
	return items[math.random(1, #items)]
end
sgs.ai_skill_cardchosen["s4_beizhen"] = function(self, who, flags)
	local cards = sgs.QList2Table(who:getCards(flags))
	self:sortByUseValue(cards, true)
	if self:isFriend(who) then
		if not who:getJudgingArea():isEmpty() then
			for _, judge in sgs.qlist(who:getJudgingArea()) do
				if not judge:isKindOf("YanxiaoCard") then
					return judge
				end
			end
		end
		if self:needToThrowArmor(who) then
			return who:getArmor()
		end
        local pcs = self:poisonCards("e") 
        for _,c in sgs.list(pcs)do
            return c
        end
	end
    return -1
end

sgs.ai_ajustdamage_to["&s4_beizhen"] = function(self, from, to, card, nature)
	return 1
end

sgs.ai_skill_choice.s4_fani = function(self, choices, data)
    local target = data:toPlayer()
    local items = choices:split("+")
    if table.contains(items, "discard") and self:doDisCard(target, "he") then
        if #self.toUse < 2 or math.random() < 0.5 then
            if table.contains(items, "bieshui") then
                return "bieshui"
            end
        end
        return "discard"
    end
    return "draw"
end

sgs.ai_choicemade_filter.cardChosen.s4_fani = sgs.ai_choicemade_filter.cardChosen.snatch



sgs.ai_skill_use["@@s4_juejing"] = function(self,prompt)
    local dying = self.room:getCurrentDyingPlayer()
	if not dying then return "." end
    if not self:isFriend(dying) then return "." end
    local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,0)
	indulgence:deleteLater()
	local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,0)
	supply_shortage:deleteLater()
    local cards = self:addHandPile("he")
	cards = self:sortByUseValue(cards,true)
    if (self.player:isProhibited(dying,indulgence) or dying:containsTrick("indulgence")) and 
	(self.player:isProhibited(dying,supply_shortage) or dying:containsTrick("supply_shortage")) then 
        return "."
    elseif  (self.player:isProhibited(dying,supply_shortage) or dying:containsTrick("supply_shortage")) then
		for _,card in ipairs(cards)do
            if card:isRed() then
		        return "#s4_juejing:"..card:getEffectiveId()..":->"..dying:objectName()
            end
        end
	elseif  (self.player:isProhibited(dying,indulgence) or dying:containsTrick("indulgence")) then
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards)do
            if card:isBlack() then
		        return "#s4_juejing:"..card:getEffectiveId()..":->"..dying:objectName()
            end
        end
	else
		for _,card in ipairs(cards)do
		    return "#s4_juejing:"..card:getEffectiveId()..":->"..dying:objectName()
        end
	end
    return "."
end

sgs.ai_suppress_intention["s4_juejing"] = true

sgs.ai_cardneed.s4_juejing = function(to, card)
    return to:getHandcardNum() < 3
end

sgs.ai_skill_playerchosen.s4_longhun_from = function(self,players)
	sgs.ai_skill_invoke.peiqi(self)
    for _,target in sgs.list(players)do
		if target==self.peiqiData.from
		then return target end
	end
    for _,target in sgs.list(players)do
        return target
    end
end

sgs.ai_skill_cardchosen.s4_longhun = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		local id = e:getEffectiveId()
		if id==self.peiqiData.cid
		then return id end
	end
end

sgs.ai_skill_playerchosen.s4_longhun_to = function(self,players)
    for _,target in sgs.list(players)do
		if target==self.peiqiData.to
		then return target end
	end
    for _,target in sgs.list(players)do
        return target
    end
end

sgs.ai_choicemade_filter.cardChosen.s4_longhun = sgs.ai_choicemade_filter.cardChosen.peiqi

sgs.ai_need_damaged.s4_longhun = function (self,attacker,player)
	if not player:hasSkills("s4_longhun") then return end
	local need_card = false
	local current = self.room:getCurrent()
	if self:hasCrossbowEffect(current) or current:hasSkill("paoxiao") or current:hasFlag("shuangxiong") then need_card = true end
	if self:hasSkills("jieyin|jijiu",current) and self:getOverflow(current)<=0 then need_card = true end
	if self:isFriend(current,player) and need_card then return true end

	local friends = {}
	for _,ap in sgs.qlist(self.room:getAlivePlayers())do
		if self:isFriend(ap,player) then
			table.insert(friends,ap)
		end
	end
	self:sort(friends,"hp")

	if #friends>0 and friends[1]:objectName()==player:objectName() and self:isWeak(player) and getCardsNum("Peach",player,(attacker or self.player))==0 then return false end
	if #friends>1 and self:isWeak(friends[2]) then return true end

	return player:getHp()>2 and sgs.turncount>2 and #friends>1
end

sgs.ai_can_damagehp.s4_longhun = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end

local s4_chiyuan_skill = {}
s4_chiyuan_skill.name = "s4_chiyuan"
table.insert(sgs.ai_skills, s4_chiyuan_skill)
s4_chiyuan_skill.getTurnUseCard = function(self)
    return sgs.Card_Parse("#s4_chiyuan:.:")
end

sgs.ai_skill_use_func["#s4_chiyuan"] = function(card, use, self)
    use.card = card
end


addAiSkills("s4_ganglu").getTurnUseCard = function(self)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
	if #cards<1 then return end
	for dc,pn in sgs.list(RandomList(patterns()))do
		dc = dummyCard(pn)
		if dc and dc:isKindOf("BasicCard")
		and dc:isAvailable(self.player)
		and self:getCardsNum(dc:getClassName())<1
		then
			dc:addSubcard(cards[1])
			dc:setSkillName("s4_ganglu")
			local d = self:aiUseCard(dc)
			if d.card and d.to
			then
				self.s4_ganglu_to = d.to
				if dc:canRecast() and d.to:length()<1 then continue end
				sgs.ai_use_priority.s4_ganglu = sgs.ai_use_priority[dc:getClassName()]-0.3
				return sgs.Card_Parse("#s4_ganglu:"..cards[1]:getEffectiveId()..":"..pn)
			end
		end
	end
end

sgs.ai_skill_use_func["#s4_ganglu"] = function(card,use,self)
	if self.s4_ganglu_to
	then
		use.card = card
		use.to = self.s4_ganglu_to
	end
end

sgs.ai_guhuo_card.s4_ganglu = function(self,toname,class_name)
    if self.player:getMark("s4_ganglu-Clear") > 0 then return end
    if class_name and self:getCardsNum(class_name) > 0 then return end

	local card = sgs.Sanguosha:cloneCard(toname, sgs.Card_SuitToBeDecided, -1)
    card:deleteLater()
    if (not card) or (not card:isKindOf("BasicCard")) then return end
    if self.player:isNude() then return end
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
    return "#s4_ganglu:"..cards[1]:getEffectiveId()..":"..toname
end

sgs.ai_cardneed.s4_ganglu = function(to,card,self)
	return to:getHandcardNum()<3
end

sgs.ai_used_revises.s4_pinglu = function(self,use)
	if use.card:isKindOf("Duel")
	and self.player:hasSkill("s4_ganglu")
    and self.player:getMark("s4_ganglu-Clear") == 0
	and not use.isDummy then
        local sk = sgs.ai_fill_skill["s4_ganglu"]
        if sk then
            sk = sk(self)
            if sk then
                local d = self:aiUseCard(sk)
                if d.card then
                    use.card = sk
                    use.to = d.to
                    return false
                end
            end
        end
	end
end



local s4_longxin_skill={}
s4_longxin_skill.name="s4_longxin"
table.insert(sgs.ai_skills,s4_longxin_skill)
s4_longxin_skill.getTurnUseCard=function(self)
	local cards = self:addHandPile()
	local jink_card
	self:sortByUseValue(cards,true)
	for _,card in ipairs(cards)  do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end
	if not jink_card then return nil end
	if self.player:isWounded() then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:s4_longxin[%s:%s]=%d"):format(suit,number,card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	return slash

end

sgs.ai_view_as.s4_longxin = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and not player:isWounded() then
		if card:isKindOf("Jink") then
			return ("slash:s4_longxin[%s:%s]=%d"):format(suit,number,card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:s4_longxin[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end

sgs.ai_skill_invoke.s4_longxin = function(self,data)
	local target = data:toPlayer()
	self.s4_longxinTarget = target
	if self:isFriend(target) then
		if hasManjuanEffect(self.player) then return false end
		if self:needKongcheng(target) and target:getHandcardNum()==1
		or self:getOverflow(target)>2
		then return true end
		return false
	else
		return not(self:needKongcheng(target) and target:getHandcardNum()==1)
	end
end

sgs.ai_choicemade_filter.skillInvoke.s4_longxin = function(self,player,promptlist)
	if self.s4_longxinTarget then
		local intention = 60
		if promptlist[3]=="yes" then
			if not self:hasLoseHandcardEffective(self.s4_longxinTarget)
			or (self:needKongcheng(self.s4_longxinTarget) and self.s4_longxinTarget:getHandcardNum()==1)
			then intention = 0 end
			if self:getOverflow(self.s4_longxinTarget)>2 then intention = 0 end
			sgs.updateIntention(player,self.s4_longxinTarget,intention)
		else
			if self:needKongcheng(self.s4_longxinTarget) and self.s4_longxinTarget:getHandcardNum()==1 then intention = 0 end
			sgs.updateIntention(player,self.s4_longxinTarget,-intention)
		end
	end
end

sgs.ai_slash_prohibit.s4_longxin = function(self,from,to,card)
	if self:isFriend(to,from) then return false end
	if self:canLiegong(to,from) then
		return false
	end
	if to:hasSkill("s4_longxin") and to:getHandcardNum()>=3 and from:getHandcardNum()>1 and not to:isWounded() then return true end
end
sgs.ai_card_priority.s4_longxin = function(self,card)
	if table.contains(card:getSkillNames(), "s4_longxin") and not self.player:isWounded()
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_cardneed.s4_longxin = sgs.ai_cardneed.longdan

sgs.ai_choicemade_filter.cardChosen.s4_longxin = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_invoke.s4_jiezhan = function(self,data)
	local cp = data:toPlayer()
	return self:canDraw() and self:isEnemy(cp)
	and (self:getCardsNum("Jink")>0 or not self:isWeak())
end

sgs.ai_skill_choice.s4_jiezhan = function(self,choices, data)
    local target = data:toPlayer()
    local items = choices:split("+")
	if table.contains(items, "draw") then
        if self:canDraw() and self:isEnemy(target)
	        and (self:getCardsNum("Jink")>0 or not self:isWeak()) then
            if self.player:getLostHp() >= 1 and self.player:getMaxHp() > 1 then return "bieshui" end
            return "draw"
        end
    end
	if table.contains(items, "slash") then
		return "slash"
	end
    if table.contains(items, "damage") then
        if self:isEnemy(target) and not self:cantDamageMore(target, self.player) then
            local damage = self.room:getTag("s4_jiezhan"):toDamage()
            if self:damageIsEffective(target,damage.card,self.player) then
                return "damage"
            end
        end
    end
    if table.contains(items, "obtain") then
        if self:doDisCard(target, "he", true) then
            return "obtain"
        end
        if self:isFriend(target) then
            return "obtain"
        end
    end
    if table.contains(items, "damage") then
        return "obtain"
    end
	return "cancel"
end

sgs.ai_choicemade_filter.cardChosen.s4_jiezhan = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_playerchosen.s4_xinggu = function(self, targets)
    return self.player
end

sgs.ai_target_revises.s4_daoli = function(to,card)
	if card:isKindOf("DelayedTrick")
	then return true end
end

sgs.ai_skill_invoke.s4_jianghu = true

sgs.ai_skill_use["@@jianghu"] = function(self,prompt)
	return "#s4_jianghu:.:"
end

sgs.ai_skill_choice["s4_jianghu"] = function(self, choices, data)
	local items = choices:split("+")
    local target = data:toPlayer()
    local patterns = self.room:getTag("s4_jianghu_cards"):toString():split("+")
	for _,pattern in ipairs(RandomList(patterns)) do
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("s4_jianghu")
        card:deleteLater()
        local dummy_use = self:aiUseCard(card, dummy(true, 99, self.room:getOtherPlayers(target)))
        if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
            return pattern
        end
    end
	return items[math.random(1,#items)]
end

sgs.ai_skill_use["@@jianghuUsing"] = function(self,prompt)
    local target
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("s4_jianghu") then
            target = p
            break
        end
    end
    if not target then return "." end
    local pattern = self.player:property("s4_jianghu"):toString()
    local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
    card:setSkillName("s4_jianghu")
    card:deleteLater()
    local dummy_use = self:aiUseCard(card, dummy(true, 99, self.room:getOtherPlayers(target)))
    if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
        return card:toString() .."->"..target:objectName()
    end
    return "."
end
sgs.ai_can_damagehp.s4_jianghu = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and from and to:getMark("s4_jianghu-Clear") == 0
end

sgs.ai_choicemade_filter.cardChosen.s4_jianghu = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_suppress_intention["s4_jianghu"] = true

sgs.ai_skill_playerchosen.s4_zuolong = function(self, targets)
    local use = self.room:getTag("s4_zuolong"):toCardUse()
    targets = sgs.QList2Table(targets)
    if use.card and use.card:targetFixed() then
        local dummy_use = self:aiUseCard(use.card, dummy(true))
        if dummy_use.card and dummy_use then
            for _,target in sgs.list(targets)do
                if self:isFriend(target) then
                    return target
                end
            end
            return targets[1]
        end
    end
    for _,target in sgs.list(targets)do
		if self:isFriend(target) then
            for _,p in sgs.list(use.to)do
                local dummy_use = self:aiUseCard(use.card, dummy(true, 99, self.room:getOtherPlayers(p)))
                if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(p) then
                    return target
                end
            end
        end
    end
    return nil
end

sgs.ai_suppress_intention["s4_zuolong"] = true

sgs.ai_skill_invoke.s4_xingshang = true

sgs.ai_skill_playerschosen.s4_xingshang = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        selected:append(target)
    end
    return selected
end

sgs.ai_skill_playerchosen.s4_fangzhu = function(self,targets)
	self:sort(self.friends_noself,"handcard")
	for _,friend in ipairs(self.friends_noself)do
		if not friend:faceUp() and targets:contains(friend) then
			return friend
		end
	end
	local n = 0
	for _,friend in ipairs(self.friends_noself)do
		if not self:toTurnOver(friend,n,"fangzhu") and targets:contains(friend) then
			return friend
		end
	end
	if n>=3 then
		local target = self:findPlayerToDraw(false,n)
		if target then return target end
		for _,enemy in ipairs(self.enemies)do
			if self:toTurnOver(enemy,n,"fangzhu") and hasManjuanEffect(enemy) and targets:contains(enemy) then
				return enemy
			end
		end
	else
		self:sort(self.enemies)
		for _,enemy in ipairs(self.enemies)do
			if self:toTurnOver(enemy,n,"fangzhu") and hasManjuanEffect(enemy) and targets:contains(enemy) then
				return enemy
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if self:toTurnOver(enemy,n,"fangzhu") and enemy:hasSkills(sgs.priority_skill) and targets:contains(enemy) then
				return enemy
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if self:toTurnOver(enemy,n,"fangzhu") and targets:contains(enemy) then
				return enemy
			end
		end
	end
    return nil
end

sgs.ai_playerchosen_intention.s4_fangzhu = sgs.ai_playerchosen_intention.fangzhu

sgs.ai_need_damaged.s4_fangzhu = sgs.ai_need_damaged.fangzhu

sgs.ai_skill_playerschosen.s4_songwei = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        selected:append(target)
    end
    return selected
end

sgs.ai_skill_invoke.s4_songwei = function(self, data)
    local target = data:toPlayer()
    if self:isFriend(target) then
        return true
    end
    return false
end

sgs.ai_skill_playerschosen.s4_zhaotao = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    local c = self.room:getTag("s4_zhaotao"):toCardUse().card
    for _,target in ipairs(can_choose) do
        if self:isFriend(target) and not target:isKongcheng() and selected:length() < max then
            local dummy_use = self:aiUseCard(c, dummy())
            if dummy_use.card and dummy_use and dummy_use.to:length() > 0 then
                selected:append(target)
            end
        end
    end
    return selected
end

sgs.ai_playerschosen_intention.s4_zhaotao = function(self, from, prompt)
    local intention = -40
    local tolist = prompt:split("+")
    for _, dest in ipairs(tolist) do
        local to = self.room:findPlayerByObjectName(dest)
        sgs.updateIntention(from, to, intention)
    end
end

sgs.ai_skill_use["@@s4_zhaotao"] = function(self,prompt)
	local cards = self:addHandPile("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
   
    for _, acard in ipairs(cards) do
        local name = sgs.Sanguosha:getCard(self.player:getMark("s4_zhaotao")):objectName()
        local new_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        new_card:deleteLater()
        
        new_card:setSkillName("s4_zhaotao")
        new_card:addSubcard(acard)
        local dummy_use = self:aiUseCard(new_card, dummy())
        
        if dummy_use and dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
            local tos = {}
            for _,p in sgs.list(dummy_use.to)do
                table.insert(tos,p:objectName())
            end
            return new_card:toString().."->"..table.concat(tos,"+")
        end
    end
    return "."
end




local s4_wuhu_wusheng_skill = {}
s4_wuhu_wusheng_skill.name = "s4_wuhu_wusheng"
table.insert(sgs.ai_skills, s4_wuhu_wusheng_skill)
s4_wuhu_wusheng_skill.getTurnUseCard = function(self, inclusive)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    if #cards <= 0 then return end

    local names = {"_ny_tenth_shuiyanqijun"}
    for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
        local card = sgs.Sanguosha:getEngineCard(id)
        if card:isKindOf("BasicCard") or card:isNDTrick() then
            if card:isDamageCard() then
                if (not table.contains(names, card:objectName())) then
                    table.insert(names, card:objectName())
                end
            end
        end
    end

    local able = {}
    for _,name in ipairs(names) do
        local card = sgs.Sanguosha:cloneCard(name)
        card:deleteLater()
        local mark = string.format("s4_wuhu_wusheng_%s-Clear", card:objectName())
        if card:isKindOf("Slash") then mark = "s4_wuhu_wusheng_Slash-Clear" end
        if self.player:getMark(mark) == 0 and card:isAvailable(self.player) then
            table.insert(able, name)
        end
    end
    if #able <= 0 then return end

    for _,pattern in ipairs(able) do
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:addSubcard(cards[1])
        card:deleteLater()
        local types = {"BasicCard","TrickCard"}
        local dummy_use = self:aiUseCard(card, dummy())
        if dummy_use.card and dummy_use.to then
            self.s4_wuhu_wusheng_to = dummy_use.to
            local card_str = string.format("#s4_wuhu_wusheng:%s:%s",cards[1]:getEffectiveId(), pattern)
            return sgs.Card_Parse(card_str)
        end
    end
        
end

sgs.ai_skill_use_func["#s4_wuhu_wusheng"] = function(card, use, self)
	use.card = card
    if use.to then use.to = self.s4_wuhu_wusheng_to end
end

sgs.ai_cardsview_valuable.s4_wuhu_wusheng = function(self, class_name, player)
	if self.player:isKongcheng() then return end
    if self.player:getMark("s4_wuhu_wusheng_Slash-Clear") > 0 then return end
    if self.player:getMark("s4_wuhu_wusheng_Used-Clear") > 0 then return end
    if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
	local classname2objectname = {
		["Slash"] = "slash", ["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
	if not name then return end
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf(class_name) then return end
    end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _,card in ipairs(cards) do
        local card_str = string.format("#s4_wuhu_wusheng:%s:%s",card:getEffectiveId(), name)    
        return card_str
    end
    return
end

sgs.ai_use_priority.s4_wuhu_wusheng = 7
sgs.ai_cardneed.s4_wuhu_wusheng = sgs.ai_cardneed.wusheng

local s4_wuhu_heduan_skill = {}
s4_wuhu_heduan_skill.name = "s4_wuhu_heduan"
table.insert(sgs.ai_skills, s4_wuhu_heduan_skill)
s4_wuhu_heduan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#s4_wuhu_heduan") then return nil end
	if self:needBear() then return nil end
    local slashcount = self:getCardsNum("Slash")
	if slashcount > 1 then
	    return sgs.Card_Parse("#s4_wuhu_heduan:.:")
    end
end

sgs.ai_skill_use_func["#s4_wuhu_heduan"] = function(card, use, self)
	use.card = sgs.Card_Parse("#s4_wuhu_heduan:.:")
end

sgs.ai_use_value["s4_wuhu_heduan"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["s4_wuhu_heduan"] = sgs.ai_use_priority.Slash + 0.2
sgs.ai_skill_invoke.s4_wuhu_heduan = true

sgs.ai_cardneed.s4_wuhu_heduan = sgs.ai_cardneed.paoxiao

sgs.ai_skill_invoke.s4_wuhu_fuyong = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end
sgs.ai_ajustdamage_from.s4_wuhu_fuyong   = function(self, from, to, card, nature)
	if card and (card:hasFlag("s4_wuhu_fuyong") or (from:getMark("s4_wuhu_fuyong-Clear") + 1 == 2)) then
		return 1
	end
end


sgs.ai_skill_invoke.s4_wuhu_liegong = function(self, data)
	local use = data:toCardUse()
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			return false
		end
	end
	return true
end

local s4_wuhu_longdan_skill={}
s4_wuhu_longdan_skill.name="s4_wuhu_longdan"
table.insert(sgs.ai_skills,s4_wuhu_longdan_skill)
s4_wuhu_longdan_skill.getTurnUseCard=function(self)
	local cards = self:addHandPile()
	local jink_card
	self:sortByUseValue(cards,true)
	for _,card in ipairs(cards)  do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end
	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:s4_wuhu_longdan[%s:%s]=%d"):format(suit,number,card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	return slash

end

sgs.ai_view_as.s4_wuhu_longdan = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceHand then
		if card:isKindOf("Jink") then
			return ("slash:s4_wuhu_longdan[%s:%s]=%d"):format(suit,number,card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:s4_wuhu_longdan[%s:%s]=%d"):format(suit,number,card_id)
        elseif not card:isKindOf("BasicCard") then
            return ("nullification:s4_wuhu_longdan[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end

sgs.ai_skill_invoke.s4_wuhu_longdan = function(self,data)
	local target = data:toPlayer()
	self.s4_wuhu_longdanTarget = target
	if self:isFriend(target) then
		if hasManjuanEffect(self.player) then return false end
		if self:needKongcheng(target) and target:getHandcardNum()==1
		or self:getOverflow(target)>2
		then return true end
		return false
	else
		return not(self:needKongcheng(target) and target:getHandcardNum()==1)
	end
end

sgs.ai_choicemade_filter.skillInvoke.s4_wuhu_longdan = function(self,player,promptlist)
	if self.s4_wuhu_longdanTarget then
		local intention = 60
		if promptlist[3]=="yes" then
			if not self:hasLoseHandcardEffective(self.s4_wuhu_longdanTarget)
			or (self:needKongcheng(self.s4_wuhu_longdanTarget) and self.s4_wuhu_longdanTarget:getHandcardNum()==1)
			then intention = 0 end
			if self:getOverflow(self.s4_wuhu_longdanTarget)>2 then intention = 0 end
			sgs.updateIntention(player,self.s4_wuhu_longdanTarget,intention)
		else
			if self:needKongcheng(self.s4_wuhu_longdanTarget) and self.s4_wuhu_longdanTarget:getHandcardNum()==1 then intention = 0 end
			sgs.updateIntention(player,self.s4_wuhu_longdanTarget,-intention)
		end
	end
end

sgs.ai_card_priority.s4_wuhu_longdan = function(self,card)
	if table.contains(card:getSkillNames(), "s4_wuhu_longdan")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_cardneed.s4_wuhu_longdan = sgs.ai_cardneed.longdan

addAiSkills("s4_lieren").getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
	if #cards<1 then return end
	local ids = {}
   	local fs = dummyCard("fire_slash")
	fs:setSkillName("s4_lieren")
  	for _,c in sgs.list(cards)do
		if self:getKeepValue(c)>3
		or fs:subcardsLength()>=#cards/2 then continue end
		fs:addSubcard(c)
	end
	if fs:subcardsLength()<1 and #cards>1
	then
		fs:addSubcard(cards[1])
	end
	local dummy = self:aiUseCard(fs)
	if fs:isAvailable(self.player)
	and dummy.card
	and dummy.to
	and fs:subcardsLength()>0
  	then
		return fs
	end
end


sgs.ai_target_revises.s4_juxiang = function(to,card)
	if card:isKindOf("SavageAssault")
	then return true end
end

sgs.ai_skill_invoke.s4_juxiang = function(self, data)
    local card = data:toPindian().to_card
    if card then
        if sgs.ai_poison_card[card:objectName()] then return false end
    end
    return true
end

sgs.ai_skill_playerchosen.s4_juxiang = function(self,targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense")
	for _,enemy in ipairs(targets)do
		if self:isEnemy(enemy) and enemy:isAlive() and self.player:canPindian(enemy) then
            if self.player:getHandcardNum() == 1 then
                if (self:needKongcheng() or not self:hasLoseHandcardEffective()) and not self:isWeak() then return enemy end
                local card = self.player:getHandcards():first()
                if card:isKindOf("Jink") or card:isKindOf("Peach") then return nil end
            end
            if self:doDisCard(enemy, "he", true) then return enemy end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.s4_juxiang = 60

function sgs.ai_skill_pindian.s4_juxiang(minusecard, self, requestor)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    if requestor:objectName() == self.player:objectName() then
        return cards[1]:getId()
    end
    return self:getMaxCard(self.player):getId()
end
sgs.ai_skill_choice.s4_juxiang = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items, "obtain") then
        if math.random()<0.4 and not self:cantDamageMore(target, self.player) then return "damage" end
        if self:doDisCard(target, "he", true) then return "obtain" end
    end
	if self:isEnemy(target)
	then return "damage" end
    return "cancel"
end

sgs.ai_ajustdamage_from.s4_juxiang = function(self, from, to, card, nature)
    if card and (card:isKindOf("SavageAssault") or card:isKindOf("Slash")) and from:getMark("s4_juxiang"..to:objectName()..card:getEffectiveId().."Card-SelfClear") > 0
    then
        return 1
    end
end

sgs.ai_ajustdamage_from.s4_benxi = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and (card:hasFlag("s4_benxi"..to:objectName()) or from:getMark("used_slash-Clear") == 0) and from:distanceTo(to) <= 1
    then
        return 1
    end
end

sgs.ai_view_as.s4_wusheng = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("slash:s4_wusheng[%s:%s]=%d"):format(suit,number,card_id)
	end
end

local s4_wusheng_skill = {}
s4_wusheng_skill.name = "s4_wusheng"
table.insert(sgs.ai_skills,s4_wusheng_skill)
s4_wusheng_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("he")
	cards = self:sortByUseValue(cards,true)
	local red_card = {}
	local useAll = false
	self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<2 and not enemy:hasArmorEffect("EightDiagram")
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash")<2
	or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao")
	then disCrossbow = true end

	self:sort(self.enemies,"defense")
	
	for _,card in ipairs(cards)do
		if card:isRed() and not card:isKindOf("Slash")
		and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (not isCard("Crossbow",card,self.player) or disCrossbow)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,dummyCard())>0)
		then table.insert(red_card,card) end
	end

	for _,card in ipairs(red_card)do
		local slash = dummyCard("slash")
		slash:addSubcard(card)
		slash:setSkillName("s4_wusheng")
		if slash:isAvailable(self.player)
		then return slash end
	end
end


sgs.ai_skill_invoke.s4_wusheng = function(self, data)
    local use = data:toCardUse()
    for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			return false
		end
	end
    return true
end

sgs.ai_cardneed.s4_wusheng = sgs.ai_cardneed.wusheng

sgs.ai_use_revises.s4_paoxiao = function(self,card,use)
	if card:isKindOf("Crossbow")
	then return false end
end
sgs.ai_cardneed.s4_paoxiao = sgs.ai_cardneed.paoxiao

sgs.ai_skill_invoke.s4_tieji = function(self,data)
	local target = data:toPlayer()
	if self:isFriend(target) then return false end
	return true
end


sgs.ai_skill_askforag.s4_tieji = function(self, card_ids)
    local red = 0
	for card_id in ipairs(card_ids) do
        if sgs.Sanguosha:getCard(card_id):isRed() then
            red = red + 1
        end
	end
    if red == 1 then
        for card_id in ipairs(card_ids) do
            if sgs.Sanguosha:getCard(card_id):isBlack() then
                return card_id
            end
        end
    end
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByUseValue(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end

sgs.ai_canliegong_skill.s4_liegong = function(self, from, to)
	return to:getHandcardNum() >= from:getHp() or to:getHandcardNum() <= from:getAttackRange()
end

sgs.ai_ajustdamage_from.s4_liegong = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and ((card:hasFlag("s4_liegong") and to and to:hasFlag("s4_liegong")) or (to:getHp() <= from:getAttackRange() or to:getHp() >= from:getHp()))
    then
        return 1
    end
end

sgs.ai_skill_playerchosen.s4_longdan = function(self, targets)
    return self:findPlayerToDiscard("hej", true, false, targets)[1]
end

sgs.ai_cardneed.s4_longdan = sgs.ai_cardneed.longdan

sgs.ai_choicemade_filter.cardChosen.s4_longdan = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_invoke.s4_longdan = true

local s4_longdan_skill={}
s4_longdan_skill.name="s4_longdan"
table.insert(sgs.ai_skills,s4_longdan_skill)
s4_longdan_skill.getTurnUseCard=function(self)
	local cards = self:addHandPile()
	local jink_card
	self:sortByUseValue(cards,true)
	for _,card in ipairs(cards)  do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end
	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:s4_longdan[%s:%s]=%d"):format(suit,number,card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	return slash

end

sgs.ai_view_as.s4_longdan = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceHand then
		if card:isKindOf("Jink") then
			return ("slash:s4_longdan[%s:%s]=%d"):format(suit,number,card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:s4_longdan[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end

sgs.ai_skill_playerchosen.s4_xianxing = function(self, targets)
    local destlist = sgs.QList2Table(targets) -- 将列表转换为表
	self:sort(destlist,"handcard")
    local record = self.player:property("s4_xianxingRecords"):toString()
    local records
    if (record) then
        records = record:split(",")
        if #records == 4 then
            for _,target in sgs.list(destlist)do
                if self:isEnemy(target) then return target end
            end
        end
        return nil
    end
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target) and (self:doDisCard(target, "he") or not self:canDraw(target, self.player))
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) and (self:doDisCard(target, "he") or self:canDraw(target, self.player) or ZishuEffect(target)>0)
        then return target end
    end
    return self:findPlayerToDiscard("he", true, false, targets)[1]
end

sgs.ai_skill_use["@@s4_xianxingDiscard"] = function(self,prompt)
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local discard = {}
    local suits = self.player:property("s4_xianxing"):toString():split(",")
	for _, card in ipairs(cards) do
        if not table.contains(suits,card:getSuitString()) then
		    table.insert(discard, card:getEffectiveId())
		    table.insert(suits, card:getSuitString())
        end
	end
    
	if #discard > 0 then
		return "#s4_xianxingDiscard:".. table.concat(discard, "+") ..":"
	end
    return "."
end

local s4_zhuochen_skill={}
s4_zhuochen_skill.name="s4_zhuochen"
table.insert(sgs.ai_skills,s4_zhuochen_skill)
s4_zhuochen_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse(("fire_attack:s4_zhuochen[%s:%s]=."):format("to_be_decided", 0))
end

sgs.ai_skill_use["@@s4_zhuochen"] = function(self,prompt)
	local fire_attack = dummyCard("fire_attack")
	fire_attack:setSkillName("s4_zhuochen")
	local d = self:aiUseCard(fire_attack)
	if d.card and d.to
	then
		local tos = {}
		for _,p in sgs.list(d.to)do
			table.insert(tos,p:objectName())
		end
		return fire_attack:toString().."->"..table.concat(tos,"+")
	end
    return "."
end



sgs.ai_skill_playerschosen.s4_chenzhu = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if self:isFriend(target) and self:canDraw(target, self.player) and selected:length() < max then
            selected:append(target)
        end
    end
    return selected
end

sgs.ai_playerschosen_intention.s4_chenzhu = function(self, from, prompt)
    local intention = -40
    local tolist = prompt:split("+")
    for _, dest in ipairs(tolist) do
        local to = self.room:findPlayerByObjectName(dest)
        sgs.updateIntention(from, to, intention)
    end
end

sgs.ai_skill_choice.s4_xingyi = sgs.ai_skill_choice.benghuai

addAiSkills("s4_xingyi").getTurnUseCard = function(self)
    if self.player:getMark("s4_yanshi") < 2 then
        if #self.friends_noself > 0 then
            return sgs.Card_Parse("#s4_xingyi:.:")
        end
        return nil
    else
        local slash = dummyCard("slash")
	    slash:setSkillName("s4_xingyi")
        local dummy = self:aiUseCard(slash)
        if dummy.card
        and dummy.to
        then
            self.s4_xingyi_to = dummy.to
            return sgs.Card_Parse("#s4_xingyi:.:")
        end
    end
end

sgs.ai_skill_use_func["#s4_xingyi"] = function(card, use, self)
    local function find_use_card(self, target)
    -- Try poisonCards("e"), then handcards, then equip cards
        local sources = {
            function() return self:poisonCards("e") end,
            function() return sgs.QList2Table(self.player:getCards("h")) end,
            function() return sgs.QList2Table(self.player:getCards("e")) end
        }
        for _, get_cards in ipairs(sources) do
            for _, card in ipairs(get_cards()) do
                if card:isBlack() or self.player:getMark("s4_yanshi") < 1 then
                    if (card:isKindOf("Snatch") or card:isKindOf("Dismantlement"))
			            and self:getEnemyNumBySeat(self.player,target)>0 then
				        local dummy_use = self:aiUseCard(card)
				        if dummy_use.card then
                            continue
                        end
                    end
                    return card
                end
            end
        end
        return nil
    end

    local function find_target(self)
        local friends = self.friends_noself
        self:sort(friends, "defense")
        for _, friend in ipairs(friends) do
            if self:canDraw(friend, self.player) and ZishuEffect(friend) > 0 then
                return friend
            end
        end
        for _, friend in ipairs(friends) do
            if self:canDraw(friend, self.player) then
                return friend
            end
        end
        return nil
    end

    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards, true)
    local h, friend = self:getCardNeedPlayer(cards)
    if h and friend then
        use.card = sgs.Card_Parse("#s4_xingyi:" .. h:getEffectiveId() .. ":")
        if use.to then
            use.to:append(friend)
        end
        return
    end
    if sgs.ai_skill_use["@@s4_xingyi"](self, "") == "." then
        return
    end
    

    -- Usage in skill function:
    local target = find_target(self)
    local use_card = find_use_card(self, target)
    

    if target and use_card then
        use.card = sgs.Card_Parse("#s4_xingyi:" .. use_card:getEffectiveId() .. ":")
        if use.to then
            use.to:append(target)
        end
        return
    elseif self.player:getMark("s4_yanshi") > 1 then
        use.card = card
	    if use.to then use.to = self.s4_xingyi_to end
    end
end


sgs.ai_skill_use["@@s4_xingyi"] = function(self,prompt)
	local slash = dummyCard("slash")
	slash:setSkillName("s4_xingyi")
	local d = self:aiUseCard(slash)
	if d.card and d.to
	then
		local tos = {}
		for _,p in sgs.list(d.to)do
			table.insert(tos,p:objectName())
		end
		return "#s4_xingyi:.:->"..table.concat(tos,"+")
	end
    return "."
end

sgs.ai_use_priority["s4_xingyi"] = sgs.ai_use_priority.RendeCard

sgs.dynamic_value.benefit["s4_xingyi"] = true

sgs.ai_choicemade_filter.cardChosen.s4_yuezhe = sgs.ai_choicemade_filter.cardChosen.peiqi

sgs.ai_skill_invoke.s4_yuezhe = true
sgs.ai_skill_playerchosen.s4_yuezhe_from = function(self, targets)
    self.s4_yuezheData = {}
    targets = sgs.QList2Table(targets)
    self:sort(targets,"defense")
	for _,ep in sgs.list(self.friends)do
		if self:doDisCard(ep,"ej",true) then
			local ejs = ep:getCards("ej")
			ejs = self:sortByKeepValue(ejs)
			for _,ej in sgs.list(ejs)do
				local i = ej:getEffectiveId()
				if self:doDisCard(ep,i,true) and (ej:isKindOf("Horse") or ej:isKindOf("DelayedTrick")) then
					self.s4_yuezheData.cid = i
					for _,fp in sgs.list(self.enemies)do
                        if ep:isAdjacentTo(fp) then
                            self.s4_yuezheData.to = fp
                            if ej:getTypeId()==3 then
                                local n = ej:getRealCard():toEquipCard():location()
                                if not fp:getEquip(n) and fp:hasEquipArea(n)
                                then return ep end
                            else
                                if self.player:canUse(ej,fp,true)
                                then return ep end
                            end
                        end
					end
				end
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if self:doDisCard(ep,"ej",true) then
			local ejs = ep:getCards("ej")
			ejs = self:sortByKeepValue(ejs,true)
			for _,ej in sgs.list(ejs)do
				local i = ej:getEffectiveId()
				if self:doDisCard(ep,i,true) and (ej:isKindOf("Horse") or ej:isKindOf("DelayedTrick")) then
					self.s4_yuezheData.cid = i
					for _,fp in sgs.list(self.friends)do
                        if ep:isAdjacentTo(fp) then
						self.s4_yuezheData.to = fp
                            if ej:getTypeId()==3 then
                                local n = ej:getRealCard():toEquipCard():location()
                                if not fp:getEquip(n) and fp:hasEquipArea(n)
                                then return ep end
                            else
                                if self.player:canUse(ej,fp,true)
                                then return ep end
                            end
                        end
					end
				end
			end
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if self:doDisCard(ep,"ej",true) and not self:isFriend(ep) then
			local ejs = ep:getCards("ej")
			ejs = self:sortByKeepValue(ejs,true)
			for _,ej in sgs.list(ejs)do
				local i = ej:getEffectiveId()
				if self:doDisCard(ep,i,true) and (ej:isKindOf("Horse") or ej:isKindOf("DelayedTrick")) then
					self.s4_yuezheData.cid = i
					for _,fp in sgs.list(self.friends)do
                        if ep:isAdjacentTo(fp) then
                            self.s4_yuezheData.to = fp
                            if ej:getTypeId()==3 then
                                local n = ej:getRealCard():toEquipCard():location()
                                if not fp:getEquip(n) and fp:hasEquipArea(n)
                                then return ep end
                            else
                                if not fp:containsTrick(ej:objectName())
                                and self.player:canUse(ej,fp,true)
                                then return ep end
                            end
                        end
					end
				end
			end
		end
	end
    return nil
end
sgs.ai_skill_playerchosen.s4_yuezhe_to = function(self, targets)
    for _,target in sgs.list(targets)do
		if target:objectName()==self.s4_yuezheData.to:objectName()
		then return target end
	end
end

sgs.ai_skill_cardchosen.s4_yuezhe = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		local id = e:getEffectiveId()
		if id==self.s4_yuezheData.cid and (e:isKindOf("Horse") or e:isKindOf("DelayedTrick"))
		then return id end
	end
    for _,e in sgs.list(who:getCards(flags))do
        if self:doDisCard(who,e:getEffectiveId()) and (e:isKindOf("Horse") or e:isKindOf("DelayedTrick"))
        then return e:getEffectiveId() end
    end
    return nil
end

sgs.ai_skill_playerschosen.s4_yuezhe = function(self, targets, max, min)
    local id = self.player:getMark("s4_yuezhe")
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    slash:addSubcard(id)
    slash:setSkillName("s4_yuezhe")
    slash:deleteLater()
	local dummy_use = self:aiUseCard(slash, dummy())
	local enemy = sgs.SPlayerList()
	if dummy_use.card and dummy_use.to:length() > 0 then
		for _, p in sgs.qlist(dummy_use.to) do
			if self:isEnemy(p) and targets:contains(p) then
				enemy:append(p)
				if enemy:length() >= max then
					break
				end
			end
		end
	end
	return enemy
end

sgs.ai_skill_playerchosen.s4_baojun = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets,"defense")
    for _,target in ipairs(targets)do
        if self:isFriend(target) then
            return target
        end
    end
    return nil
end

sgs.ai_fill_skill.s4_gonggeng_attach = function(self, target)
    return sgs.Card_Parse("#s4_gonggeng:.:")
end

sgs.ai_skill_use_func["#s4_gonggeng"] = function(card,use,self)
    for _,p in ipairs(self.friends) do
        if p:hasSkill("s4_gonggeng") then
            local cards = self.player:getCards("he")
	        cards = self:sortByKeepValue(cards)
            for _,c in ipairs(cards)do
                if c:isDamageCard() then
                    use.card = sgs.Card_Parse("#s4_gonggeng:"..c:getEffectiveId()..":")
                    if use.to then
                        use.to:append(p)
                    end
                    return
                end
            end
        end
    end
    use.card = nil
end

sgs.ai_skill_invoke.s4_tonghan = true

sgs.ai_skill_askforag.s4_tonghan = function(self, card_ids)
    for _,id in ipairs(RandomList(card_ids))do
		local card = sgs.Sanguosha:getCard(id)
		local dummy_use = self:aiUseCard(card, dummy())
		if card:isAvailable(self.player) and dummy_use.card then
			return id
		end
	end
end

sgs.ai_skill_use["@@s4_tonghan"] = function(self, prompt)
    local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
	pattern = self.player:getMark("s4_tonghan_id-Clear") - 1
	pattern = sgs.Sanguosha:getEngineCard(pattern)
    for _,c in sgs.list(cards)do
        pattern = sgs.Sanguosha:cloneCard(pattern:objectName())
        pattern:deleteLater()
        pattern:addSubcard(c:getEffectiveId())
        pattern:setSkillName("s4_tonghan")
        local dummy_use = self:aiUseCard(pattern, dummy())
        if dummy_use.to and dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, to:objectName())
            end
            return pattern:toString().."->"..table.concat(tos, "+")
        end
    end
    return "."
end

sgs.ai_target_revises.s4_xiemin = function(to,card,self,use)
    if card:isKindOf("IronChain") then return true end
end

sgs.ai_skill_playerschosen.s4_xiemin = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if self:isEnemy(target) and selected:length() < max then
            selected:append(target)
        end
    end
    for _,target in ipairs(can_choose) do
        if not selected:contains(target) and selected:length() < max then
            selected:append(target)
        end
    end
    return selected
end

sgs.ai_playerschosen_intention.s4_xiemin = function(self, from, prompt)
    local intention = 10
    local tolist = prompt:split("+")
    for _, dest in ipairs(tolist) do
        local to = self.room:findPlayerByObjectName(dest)
        sgs.updateIntention(from, to, intention)
    end
end

sgs.ai_skill_discard["@s4_xiemin-give"] = function(self, discard_num, min_num, optional, include_equip)
    local to
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if p:hasFlag("s4_xiemin_give") then
            to = p
            break
        end
    end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    if to then 
		if self:isFriend(to) then
			cards = sgs.reverse(cards)
		end
	end
    return {cards[1]:getEffectiveId()}
end

sgs.ai_skill_playerchosen.s4_zhaowu = function(self, targets)
    targets = sgs.QList2Table(targets)
    local target = self:findPlayerToUseSlash(true, targets, "s4_zhaowu", dummyCard("thunder_slash"), nil)
    if target then
        return target
    end
    return nil
end

sgs.ai_playerchosen_intention.s4_zhaowu = -40

sgs.ai_skill_playerschosen.s4_zhaowu = function(self, targets, max, min)
    local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
    slash:setSkillName("s4_zhaowu")
    slash:deleteLater()
	local dummy_use = self:aiUseCard(slash, dummy())
	local enemy = sgs.SPlayerList()
	if dummy_use.card and dummy_use.to:length() > 0 then
		for _, p in sgs.qlist(dummy_use.to) do
			if self:isEnemy(p) and targets:contains(p) then
				enemy:append(p)
				if enemy:length() >= max then
					break
				end
			end
		end
	end
	return enemy
end

sgs.ai_use_revises.s4_youlong = function(self,card,use)
	card:setFlags("Qinggang")
end

sgs.ai_poison_card.Adou = function(c, owner)
    if owner:hasSkill("s4_youlong") then
        return false
    end
    return true
end

sgs.ai_use_revises.s4_youlong = function(self,card,use)
	if card:isKindOf("Treasure")
	then return false end
end

-- soldier
sgs.ai_skill_playerchosen.s4_s_changqiang = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense")
	for _,target in ipairs(targets)do
		if self:isEnemy(target) and self:isGoodTarget(target,targets) then
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.s4_s_changqiang = 80

sgs.ai_used_revises.s4_s_jixing = function(self, use)
	if use.card:isKindOf("TrickCard") and (self.player:getDefensiveHorse() == nil and self.player:getOffensiveHorse() == nil) then
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		for _,card in ipairs(handcards)do
            if (card:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse() == nil) or (card:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse() == nil ) and CanToCard(card,self.player,self.player) then	
				use.card = card
				use.to = sgs.SPlayerList()
				return false
			end
		end
	end
end

sgs.ai_skill_invoke.s4_s_yuanshe = function(self, data)
    local card = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
    card:setSkillName("s4_s_yuanshe")
    card:deleteLater()
    local dummy_use = self:aiUseCard(card, dummy(true))
    if dummy_use.card and dummy_use then
        return true
    end
    return false
end

sgs.ai_fill_skill.s4_s_youdi = function(self)
	return sgs.Card_Parse("#s4_s_youdi:.:")
end

sgs.ai_skill_use_func["#s4_s_youdi"] = function(card,use,self)
	local distance = use.DefHorse and 1 or 0
	local targets = {}
    self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if self:isTiaoxinTarget(enemy) and self.player:inMyAttackRange(enemy)
		then table.insert(targets,enemy) end
	end

	if #targets==0 then return end

	sgs.ai_use_priority["s4_s_youdi"] = 8
	if not self.player:getArmor() and not self.player:isKongcheng() then
		for _,card in sgs.qlist(self.player:getCards("h"))do
			if card:isKindOf("Armor") and self:evaluateArmor(card)>3 then
				sgs.ai_use_priority["s4_s_youdi"] = 5.9
				break
			end
		end
	end

	self:sort(targets,"defenseSlash")
	use.to:append(targets[1])
	use.card = sgs.Card_Parse("#s4_s_youdi:.:")
end

sgs.ai_card_intention["s4_s_youdi"] = sgs.ai_card_intention.TiaoxinCard
sgs.ai_use_priority["s4_s_youdi"] = sgs.ai_use_priority.TiaoxinCard

sgs.ai_skill_cardask["@s4_s_youdi-slash"] = function(self,data,pattern,target)
    if hasZhaxiangEffect(self.player) and not self:isWeak() then return "." end
	if target then
		for _,slash in ipairs(self:getCards("Slash"))do
			if self:isFriend(target) and self:slashIsEffective(slash,target) then
				if self:needLeiji(target,self.player) then return slash:toString() end
				if self:needToLoseHp(target,self.player,nil,true) then return slash:toString() end
			end

			if not self:isFriend(target) and self:slashIsEffective(slash,target)
			and not self:needLeiji(target,self.player)
			then return slash:toString() end
		end
		for _,slash in ipairs(self:getCards("Slash"))do
			if not self:isFriend(target) then
				if not self:needLeiji(target,self.player) and not self:needToLoseHp(target,self.player,slash) then return slash:toString() end
				if not self:slashIsEffective(slash,target) then return slash:toString() end
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.s4_s_yexi = function(self, data)
    local target = data:toPlayer()
    return self:doDisCard(target, "he")
end

sgs.ai_skill_playerchosen.s4_s_touxi = function(self, targets)
    return self:findPlayerToDamage(1,self.player,"F",targets)[1]
end

sgs.ai_skill_cardask["@s4_s_ruqin"] = function(self, data, pattern, target)
    for _,c in sgs.qlist(self.player:getCards("he"))do
        if c:isKindOf("TrickCard") and c:isBlack() then
        local SavageAssault = sgs.Sanguosha:cloneCard("SavageAssault", c:getSuit(), c:getNumber())
        SavageAssault:addSubcard(c)
        SavageAssault:setSkillName("s4_s_ruqin")
        SavageAssault:deleteLater()
            local dummy_use = self:aiUseCard(SavageAssault, dummy(true))
            if dummy_use.card and dummy_use then
                return c:toString()
            end
        end
    end
end

sgs.ai_skill_playerchosen.s4_s_ruqin = function(self, targets)
    local data = self.room:getTag("s4_s_ruqin")
    local use = data:toCardUse()
	if sgs.ai_skill_choice.sheyan(self,"remove", data) == "remove" then
		if self.sheyan_remove_target then
			return self.sheyan_remove_target
		end
	end
    self:sort(self.friends_noself, "defense")
    local lord = self.room:getLord()
    if lord and use.to:contains(lord)
    and lord:objectName()~=self.player:objectName()
    and self:isFriend(lord) and self:isWeak(lord)
    and self:hasTrickEffective(use.card,lord,use.from)
    then
        return lord
    end
    for _,p in sgs.list(use.to)do
        if use.to:contains(p) and self:isFriend(p) and self:hasTrickEffective(use.card,p,use.from) then
            return p
        end
    end
end

sgs.ai_playerchosen_intention.s4_s_ruqin = -80

sgs.ai_skill_invoke.s4_s_wanqiang = true

sgs.ai_skill_invoke.s4_s_dujian = function(self, data)
    local use = data:toCardUse()
    local target = use.to:first()
    return self:toTurnOver(target,1,"s4_s_dujian")
end

sgs.ai_need_damaged.s4_s_roubo = function (self,attacker,player)
	if not player:hasSkill("s4_s_roubo") then return false end
	if not player:isKongcheng() then return false end
	if not attacker then return end
	if self:isEnemy(attacker,player) and self:isWeak(attacker) and attacker:getHandcardNum()<3
	  and not attacker:hasSkills(sgs.masochism_skill) then
		return not self:isWeak(player)
	end
end

sgs.ai_skill_cardask["@s4_s_jianta"] = function(self, data, pattern, target)
    local use = data:toCardUse()
    local target = use.to:first()
    if not self:isEnemy(target) then return "." end
	if self:cantDamageMore(self.player,target) then return "." end
    if (self:damageIsEffective(target, use.card, self.player) and (self:canHit(target,self.player) or math.random()<0.5)) then 
        return true
    end
    return "."
end

sgs.ai_ajustdamage_from.s4_s_jianta = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and from:hasFlag("s4_s_jianta") then
        return 1
    end
end

sgs.ai_fill_skill.s4_s_zhanchuan = function(self)
    local use_card
    local cards = self.player:getCards("h")
    cards = self:sortByUseValue(cards,true) -- 按保留值排序
	for i,h in sgs.list(cards)do
		if h:isKindOf("BasicCard") then
			use_card = h
			break
		end
	end
	if use_card then
		return sgs.Card_Parse("#s4_s_zhanchuan:"..use_card:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#s4_s_zhanchuan"] = function(card,use,self)
    use.card = card
end

sgs.ai_use_priority["s4_s_zhanchuan"] = 10

sgs.ai_use_revises.s4_s_zhanchuan = function(self,card,use)
	if not self.player:getPile("s4_s_zhanchuan"):isEmpty() and not card:isKindOf("SkillCard") then
		card:setFlags("Qinggang")
	end
end

sgs.ai_skill_invoke.s4_s_xuezhan = function(self,data)
	local to = data:toDamage().from
	if to then return not self:isFriend(to) end
	return false
end

sgs.ai_can_damagehp.s4_s_xuezhan = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
        if self:isEnemy(from) then
            local indulgence = sgs.Sanguosha:cloneCard("indulgence", sgs.Card_NoSuit, 0)
            local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage", sgs.Card_NoSuit, 0)
            indulgence:deleteLater()
            supply_shortage:deleteLater()
            return CanToCard(indulgence, to, from) or CanToCard(supply_shortage, to, from)
        end
		return false
	end
end


sgs.ai_skill_playerschosen.s4_s_yuangong = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	local card = dummyCard("thunder_slash")
	card:setSkillName("s4_s_yuangong")
	card:deleteLater()
	local dummy_use = self:aiUseCard(card, dummy(true, 2))
	if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do 
			if table.contains(can_choose, p) then
				selected:append(p)
			end
		end
	end
    if selected:length() >= 1 then
        local useds = self:getTurnUse()
        if #useds <= selected:length() or self:getOverflow() <= 1 then
            return selected
        end
    end
    return sgs.SPlayerList()
end

sgs.ai_fill_skill.s4_s_chuqi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        return sgs.Card_Parse("#s4_s_chuqi:" .. card:getEffectiveId() .. ":")
    end
end
sgs.ai_skill_use_func["#s4_s_chuqi"] = function(card,use,self)
    local choices = {}
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        for _, c in sgs.qlist(p:getEquips()) do
            if c:isKindOf("Weapon") and not table.contains(choices, c:objectName()) then
                table.insert(choices, c:objectName())
            end
        end
    end
    if #choices == 0 then return end
    use.card = card
end
sgs.ai_use_priority["s4_s_chuqi"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_invoke.s4_s_lumang = function(self, data)
    local effect = data:toCardEffect()
    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
    duel:setSkillName("s4_s_lumang")
    duel:deleteLater()
    local dummy_use = self:aiUseCard(duel, dummy(true, 99, self.room:getOtherPlayers(effect.to)))
    if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(effect.to) then
        return true
    end
    return false
end

sgs.ai_view_as.s4_s_mengzhan = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getMark("s4_s_mengzhan") > 0 and not card:hasFlag("using") and (card:isKindOf("Jink") or card:isKindOf("EquipCard")) then
		return ("slash:s4_s_mengzhan[%s:%s]=%d"):format(suit,number,card_id)
	end
end

sgs.ai_skill_cardask["@s4_s_qiezhan"] = function(self, data, pattern, target)
    if self.player:getHp() < getBestHp(self.player) then return true end
    return "."
end

sgs.ai_fill_skill.s4_s_2_xuezhan = function(self)
    return sgs.Card_Parse("#s4_s_2_xuezhan:.:")
end

sgs.ai_skill_use_func["#s4_s_2_xuezhan"] = function(card,use,self)
    local max_card = self:getMaxCard()
    if not max_card then return end
    local max_point = max_card:getNumber()

    local targets = {}
    self:sort(self.enemies,"defense")
    for _,enemy in sgs.list(self.enemies)do
        if self.player:canPindian(enemy) then
            local enemy_max_card = self:getMaxCard(enemy)
            local allknown = 0
            if self:getKnownNum(enemy)==enemy:getHandcardNum() then
                allknown = allknown+1
            end
            if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
                or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
                or (not enemy_max_card and max_point>10) and self:objectiveLevel(enemy)>3 and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and self:canDamage(enemy, self.player, nil) then
                self.s4_s_2_xuezhan_card = max_card:getEffectiveId()
                use.card = sgs.Card_Parse("#s4_s_2_xuezhan:.:")
                use.to:append(enemy)
                return
                
            end
        end
    end
end

sgs.ai_use_priority["s4_s_2_xuezhan"] = sgs.ai_use_priority.QiangxiCard

sgs.ai_fill_skill.s4_s_gongpo = function(self)
    if self:needBear() then return nil end
    if self.player:hasUsed("#s4_s_gongpo") then return nil end
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if card:isBlack() then
            return sgs.Card_Parse("#s4_s_gongpo:" .. card:getEffectiveId() .. ":")
        end
    end
end

sgs.ai_skill_use_func["#s4_s_gongpo"] = function(card,use,self)
    if #self.toUse > 1 then
        for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
            if c:isDamageCard() then
                if table.contains(self.toUse,c) then
                    use.card = card
                    return
                end
            end
        end
    end
end

sgs.ai_use_priority["s4_s_gongpo"] = 6

sgs.ai_canliegong_skill.s4_s_jinggong = function(self, from, to)
	return to and (to:getArmor() or to:getDefensiveHorse() or to:getOffensiveHorse())
end

sgs.ai_fill_skill.s4_s_jingjia = function(self)
    local cards = sgs.QList2Table(self.player:getCards("h"))
	for _,c in sgs.list(cards)do
		if c:isKindOf("EquipCard") then
			local equip = c:getRealCard():toEquipCard()
			local equip_index = equip:location()
			if self.player:isProhibited(self.player,c) or not self.player:hasEquipArea(equip_index) then
				return sgs.Card_Parse("#s4_s_jingjia:"..c:getEffectiveId()..":")
			end
			
			if self:willUse(self.player,c) then
				if c:isKindOf("Weapon") and self.player:getWeapon() then 
					return sgs.Card_Parse("#s4_s_jingjia:"..self.player:getWeapon():getEffectiveId()..":")
				elseif c:isKindOf("Armor") and self.player:getArmor() then
					return sgs.Card_Parse("#s4_s_jingjia:"..self.player:getArmor():getEffectiveId()..":")
				elseif c:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse() then
					return sgs.Card_Parse("#s4_s_jingjia:"..self.player:getDefensiveHorse():getEffectiveId()..":")
				elseif c:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse() then
					return sgs.Card_Parse("#s4_s_jingjia:"..self.player:getOffensiveHorse():getEffectiveId()..":")
				end
			else
				return sgs.Card_Parse("#s4_s_jingjia:"..c:getEffectiveId()..":")
			end
		end
	end
end

sgs.ai_skill_use_func["#s4_s_jingjia"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority["s4_s_jingjia"] = 10
sgs.ai_use_value["s4_s_jingjia"] = 10

sgs.ai_fill_skill.s4_s_lueduo = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if c:isKindOf("Snatch") then
			local dc = dummyCard("dismantlement")
			dc:setSkillName("s4_s_lueduo")
			dc:addSubcard(c)
			if dc:isAvailable(self.player) then
				return dc
			end
		end
	end
	for _,c in sgs.list(cards)do
		if c:isKindOf("Dismantlement") then
			local dc = dummyCard("snatch")
			dc:setSkillName("s4_s_lueduo")
			dc:addSubcard(c)
			if dc:isAvailable(self.player) then
				return dc
			end
		end
	end
end
sgs.ai_fill_skill.s4_s_zonghuo = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if c:isKindOf("FireAttack") then
			local dc = dummyCard("fire_slash")
			dc:setSkillName("s4_s_zonghuo")
			dc:addSubcard(c)
			if dc:isAvailable(self.player) then
				return dc
			end
		end
	end
end

sgs.ai_fill_skill.s4_s_yongwu = function(self)
    return sgs.Card_Parse("#s4_s_yongwu:.:")
end

sgs.ai_skill_use_func["#s4_s_yongwu"] = function(card,use,self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	self:sortByUseValue(cards,true)
    local use_cards = {}
	if slashcount > 0  then
        local slash = self:getCard("Slash")
        assert(slash)
        self.player:setFlags("InfinityAttackRange")
        local dummy_use = self:aiUseCard(slash,dummy(true))
        self.player:setFlags("-InfinityAttackRange")
        if dummy_use.card and dummy_use.to:length() > 0 then
            for _, enemy in sgs.qlist(dummy_use.to) do
                if not self.player:inMyAttackRange(enemy) then
                    for _, card in ipairs(cards) do
                        if ((not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0) and card:isRed() then
                            table.insert(use_cards, card:getEffectiveId())
                            break
                        end
                    end
                    break
                end
            end
            for _, enemy in sgs.qlist(dummy_use.to) do
                if enemy:hasArmorEffect(nil) then
                    for _, card in ipairs(cards) do
                        if ((not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0) and card:isBlack() then
                            table.insert(use_cards, card:getEffectiveId())
                            break
                        end
                    end
                    break
                end
            end
            if #use_cards > 0 then
                use.card = sgs.Card_Parse("#s4_s_yongwu:" .. table.concat(use_cards, "+") .. ":")
            end
        end
	end
end

sgs.ai_use_priority["s4_s_yongwu"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_invoke.s4_s_xianneng = function(self, data)
    return self.player:getHp() + self:getAllPeachNum() - 1 > 0
end

sgs.ai_fill_skill.s4_s_jijiu = function(self)
    return sgs.Card_Parse("#s4_s_jijiu:.:")
end

sgs.ai_skill_use_func["#s4_s_jijiu"] = function(card,use,self)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sort(self.friends, "hp")
    self.friends = sgs.reverse(self.friends)
    for _,friend in ipairs(self.friends)do
        if friend:getPile("s4_s_jijiu"):isEmpty() then
            for _,c in sgs.list(cards)do
                if c:getSuit() == sgs.Card_Diamond then
                    use.card = sgs.Card_Parse("#s4_s_jijiu:" .. c:getEffectiveId() .. ":")
                    use.to:append(friend)
                    return
                end
            end
        end
    end
    for _,friend in ipairs(self.friends)do
        for _,c in sgs.list(cards)do
            if c:getSuit() == sgs.Card_Diamond then
                use.card = sgs.Card_Parse("#s4_s_jijiu:" .. c:getEffectiveId() .. ":")
                use.to:append(friend)
                return
            end
        end
    end
end

sgs.ai_use_priority["s4_s_jijiu"] = sgs.ai_use_priority.QingnangCard

sgs.ai_fill_skill.s4_s_liaoshang_godSalvation = function(self)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByUseValue(cards, true)
    for _,c in sgs.list(cards)do
        if c:getSuit() == sgs.Card_Heart then
            local dc = dummyCard("god_salvation")
            dc:setSkillName("s4_s_liaoshang")
            dc:addSubcard(c)
            if dc:isAvailable(self.player) then
                return dc
            end
        end
    end
end

sgs.ai_fill_skill.s4_s_xingyi = function(self)
    return sgs.Card_Parse("#s4_s_xingyi:.:")
end

sgs.ai_skill_use_func["#s4_s_xingyi"] = function(card,use,self)
    self:sort(self.friends_noself, "defense")
    for _,friend in ipairs(self.friends_noself)do
        if self:hasSkills(sgs.need_maxhp_skill, friend) and friend:isWounded() then
            use.card = card
            use.to:append(friend)
            return
        end
    end
    local lord = self.room:getLord()
    if lord and self:isFriend(lord) and lord:isWounded() then
        use.card = card
        use.to:append(lord)
        return
    end
    if sgs.turncount <= 2 then return end
    for _,friend in ipairs(self.friends_noself)do
        if friend:isWounded() then
            use.card = card
            use.to:append(friend)
            return
        end
    end
end

sgs.ai_fill_skill.s4_s_anqi = function(self)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByUseValue(cards, true)
    for _,c in sgs.list(cards)do
        if c:isKindOf("Weapon") then
            local dc = dummyCard()
            dc:setSkillName("s4_s_anqi")
            dc:addSubcard(c)
            if dc:isAvailable(self.player) then
                return dc
            end
        end
    end
end

sgs.ai_skill_playerchosen.s4_s_citan = function(self, targets)
    local target_list = sgs.QList2Table(targets)
    self:sort(target_list, "handcard")
    for _, target in ipairs(target_list) do
        if self:isEnemy(target) and self:doDisCard(target, "h") then
            return target
        end
    end
    return target_list[1]
end

sgs.ai_target_revises.s4_s_qianfu = function(to,card,self)
	return to:getMark("s4_s_qianfu"..card:getColorString().."-Clear")>0 and not card:isKindOf("SkillCard")
end

sgs.ai_skill_invoke["s4_s_shangwu_liegong"] = function(self, data)
    return sgs.ai_skill_invoke.liegong(self, ToData(data:toCardUse().to:first()))
end
sgs.ai_skill_invoke["s4_s_shangwu_tuxi"] = function(self, data)
	local tuxi_string = sgs.ai_skill_use["@@tenyeartuxi"](self, "")
	if tuxi_string == "." then
		return false
	end
	return true
end

sgs.ai_fill_skill.s4_s_shangwu = function(self)
    return sgs.Card_Parse("#s4_s_shangwu:.:")
end

sgs.ai_skill_use_func["#s4_s_shangwu"] = function(card,use,self)
    local choices = {}
    if not self.player:hasFlag("s4_s_shangwuTianyi") then
        self.s4_s_shangwu = "tianyi"
        sgs.ai_use_priority["s4_s_shangwu"] = sgs.ai_use_priority.TianyiCard
        local c = sgs.Card_Parse("@TianyiCard=.")
        local dummy_use = dummy()
        self:useSkillCard(c,dummy_use)
        if dummy_use.card then 
            use.card = card
        end
    end
    if not self.player:hasFlag("s4_s_shangwuQiangxi") then
        self.s4_s_shangwu = "qiangxi"
        sgs.ai_use_priority["s4_s_shangwu"] = sgs.ai_use_priority.QiangxiCard
        local c = sgs.Card_Parse("@QiangxiCard=.")
        local dummy_use = dummy()
        self:useSkillCard(c,dummy_use)
        if dummy_use.card then 
            use.card = card
        end
    end
end

sgs.ai_skill_choice.s4_s_shangwu = function(self, choices, data)
    local items = choices:split("+")
    if self.s4_s_shangwu then
        return self.s4_s_shangwu
    end
    return items[math.random(1, #items)]
end

sgs.ai_ajustdamage_to.s4_s_yinghun = function(self, from, to, card, nature)
    if not to:faceUp() then
        return -99
    end
end

