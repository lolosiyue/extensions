local LuaFengxi_skill = {}
LuaFengxi_skill.name = "LuaFengxi"
table.insert(sgs.ai_skills, LuaFengxi_skill)
LuaFengxi_skill.getTurnUseCard = function(self)
    if not getOEList(self.player):isEmpty() and not self.player:hasUsed("#LuaFengxiCard") then
        return sgs.Card_Parse("#LuaFengxiCard:.:")
    end
end

sgs.ai_skill_use_func["#LuaFengxiCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
    for _, p in ipairs(self.enemies) do
        if getOEList(self.player):contains(p) and not p:isNude() then
            use.card = sgs.Card_Parse("#LuaFengxiCard:.:")
            if use.to then use.to:append(p) end
            return
        end
    end
end

sgs.ai_use_priority["LuaFengxiCard"] = sgs.ai_use_priority.Dismantlement + 0.1
sgs.ai_use_value["LuaFengxiCard"] = 8.5

function sgs.ai_skill_invoke.LuaLinying(self, data)
    return (self:isWeak() and self.player:getMaxHp() - self.player:getHandcardNum() > 2) or
        sgs.ai_skill_playerchosen.LuaLinying(self, self.room:getOtherPlayers(self.player)) ~= nil
end

sgs.ai_skill_playerchosen.LuaLinying = function(self, targets)
    self:updatePlayers()
    self:sort(self.friends_noself, "handcard")
    local target = nil
    local n = 1
    for _, friend in ipairs(self.friends_noself) do
        if not friend:faceUp() and getOEList(self.player):contains(friend) then
            target = friend
            break
        end
        if not target then
            if not self:toTurnOver(friend, n, "LuaLinying") and getOEList(self.player):contains(friend) then
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
                    if self:toTurnOver(enemy, n, "LuaLinying") and hasManjuanEffect(enemy) and getOEList(self.player):contains(enemy) then
                        target = enemy
                        break
                    end
                end
            end
        else
            self:sort(self.enemies)
            for _, enemy in ipairs(self.enemies) do
                if self:toTurnOver(enemy, n, "LuaLinying") and hasManjuanEffect(enemy) and getOEList(self.player):contains(enemy) then
                    target = enemy
                    break
                end
            end
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if self:toTurnOver(enemy, n, "LuaLinying") and self:hasSkills(sgs.priority_skill, enemy) and getOEList(self.player):contains(enemy) then
                        target = enemy
                        break
                    end
                end
            end
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if self:toTurnOver(enemy, n, "LuaLinying") and getOEList(self.player):contains(enemy) then
                        target = enemy
                        break
                    end
                end
            end
        end
    end

    return target
end

sgs.ai_playerchosen_intention.LuaLinying = function(self, from, to)
    if hasManjuanEffect(to) then sgs.updateIntention(from, to, 80) end
    local intention = 80
    if not self:toTurnOver(to, 1) then intention = -intention end
    sgs.updateIntention(from, to, intention)
end

local LuaLinlu_skill = {}
LuaLinlu_skill.name = "LuaLinlu"
table.insert(sgs.ai_skills, LuaLinlu_skill)
LuaLinlu_skill.getTurnUseCard = function(self)
    if self.player:getMark("@LuaLinlu") == 0 then return end
    if self.player:hasUsed("#LuaLinluCard") then return end
    if #self.enemies < 1 then return end
    return sgs.Card_Parse("#LuaLinluCard:.:")
end

sgs.ai_skill_use_func["#LuaLinluCard"] = function(card, use, self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local to_discard_black = {}
    local to_discard_red = {}
    local to_discard = {}
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if card:isBlack() and #to_discard_black < 2 then
            table.insert(to_discard_black, card:getEffectiveId())
        end
    end
    for _, card in ipairs(cards) do
        if card:isRed() and #to_discard_red < 2 then
            table.insert(to_discard_red, card:getEffectiveId())
        end
    end
    if #to_discard_black == 2 or #to_discard_red == 2 then
        self:sort(self.enemies)
        local target
        for _, enemy in ipairs(self.enemies) do
            if self:objectiveLevel(enemy) > 3 and not self:canAttack(enemy, self.player) and self:damageIsEffective(enemy) and not getOEMark(enemy)  then
                target = enemy
                break
            end
        end
        if not target then
            for _, enemy in ipairs(self.enemies) do
                if self:objectiveLevel(enemy) > 3 and not self:canAttack(enemy, self.player) and self:damageIsEffective(enemy) then
                    target = enemy
                    break
                end
            end
        end
        if target then
            if #to_discard_red == 2 then
                to_discard = to_discard_red
            end
            if #to_discard_black == 2 then
                to_discard = to_discard_black
            end
            local card_str = string.format("#LuaLinluCard:%s:", table.concat(to_discard, "+"))
            use.card = sgs.Card_Parse(card_str)
            if use.to then use.to:append(target) end
            return
        end
    end
end

sgs.ai_use_value["LuaLinluCard"] = 2.5
sgs.ai_card_intention["LuaLinluCard"] = 80
sgs.dynamic_value.damage_card["LuaLinluCard"] = true
sgs.ai_use_priority["LuaLinluCard"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_use["@@LuaHuowei"] = function(self, data, method)
    if not method then method = sgs.Card_MethodDiscard end
    local card_id
    local target
    local cant_use_skill
    local dmg

    if data == "@LuaHuowei" then
        dmg = self.player:getTag("LuaHuoweiDamage"):toDamage()
    else
        dmg = data
    end

    if not dmg then
        self.room:writeToConsole(debug.traceback())
        return "."
    end
    self.room:writeToConsole("huowei")
    if dmg.to:objectName() ~= self.player:objectName() then return "." end
    self.room:writeToConsole("huowei2")

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if not self.player:isCardLimited(card, method) and card:isRed() and not card:isKindOf("Peach") then
            card_id = card:getId()
            break
        end
    end
    if not card_id then return "." end

    self:sort(self.enemies, "hp")

    for _, enemy in ipairs(self.enemies) do
        if getOEList(self.player):contains(enemy) and (enemy:getHp() <= dmg.damage and enemy:isAlive()) then
            if (enemy:getHandcardNum() <= 2 or enemy:hasSkills("guose|leiji|ganglie|enyuan|qingguo|wuyan|kongcheng") or enemy:containsTrick("indulgence"))
                and self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return "#LuaHuoweiCard:" .. card_id .. ":->" .. enemy:objectName()
            end
        end
    end

    for _, enemy in ipairs(self.enemies) do
        if getOEList(self.player):contains(enemy) and (enemy:getLostHp() <= 1 or dmg.damage > 1) and enemy:isAlive() then
            if (enemy:getHandcardNum() <= 2)
                or enemy:containsTrick("indulgence") or enemy:hasSkills("guose|leiji|vsganglie|ganglie|enyuan|qingguo|wuyan|kongcheng")
                and self:canAttack(enemy, (dmg.from or self.room:getCurrent()), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return "#LuaHuoweiCard:" .. card_id .. ":->" .. enemy:objectName()
            end
        end
    end

    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        if getOEList(self.player):contains(enemy) and not enemy:isWounded() and not self:hasSkills(sgs.masochism_skill, enemy) and enemy:isAlive()
            and self:canAttack(enemy, dmg.from or self.room:getCurrent(), dmg.nature)
            and (not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan") and enemy:getLostHp() > 0) or self:isWeak()) then
            return "#LuaHuoweiCard:" .. card_id .. ":->" .. enemy:objectName()
        end
    end

    return "."
end

function sgs.ai_cardneed.LuaHuowei(to,card,self)
	return (card:isRed())
	and (getKnownCard(to,self.player,"heart",false)+getKnownCard(to,self.player,"diamond",false))<2
end

function sgs.ai_skill_invoke.LuaYinyan(self, data)
    local target = data:toPlayer()
    local maxcard = self:getMaxCard()
    local number = maxcard:getNumber()
    if target and self:isEnemy(target) and self.player:canPindian(target) and number >= 7
        and self:objectiveLevel(target) > 3 and not self:cantbeHurt(target)
        and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) then
        return true
    end
    return false
end
sgs.ai_cardneed.LuaYinyan = sgs.ai_cardneed.bignumber

sgs.ai_skill_playerchosen.LuaYanling = function(self, targets)
    local slash = self.player:getTag("LuaYanling"):toCard() or dummyCard()
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defenseSlash")
    for _, target in sgs.list(targets) do
        if self:isEnemy(target) and getOEList(self.player):contains(target)
            and not self:slashProhibit(slash, target)
            and self:isGoodTarget(target, targetlist, slash)
            and self:slashIsEffective(slash, target)
        then
            return target
        end
    end
    return nil
end

sgs.ai_cardneed.LuaYanling = sgs.ai_cardneed.slash


LuaDuanjian_skill={}
LuaDuanjian_skill.name = "LuaDuanjian"
table.insert(sgs.ai_skills, LuaDuanjian_skill)

LuaDuanjian_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isNude() then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local card
	for _,c in ipairs(cards) do if c:isKindOf("Weapon") then card = c end end
	if card then return sgs.Card_Parse("#LuaDuanjianCard:"..card:getEffectiveId()..":") end
end

sgs.ai_skill_use_func["#LuaDuanjianCard"] = function(card, use, self)
	local target1, target2
	local myoldenemy = findMyOE(self.player, self.room)
	if myoldenemy then
		target1 = self.player
		target2 = myoldenemy
	end
	if not (target1 and target2) then
		self:sort(self.enemies, "threat")
		for _, enemy in ipairs(self.enemies) do
			local theoldenemy = findMyOE(enemy, self.room)
			if theoldenemy then
				target1 = enemy
				target2 = theoldenemy
				break
			end
		end
	end
	if target1 and target2 then
		use.card = card
		if use.to then
			use.to:append(target1)
			use.to:append(target2)
		end
	end
end

sgs.ai_use_value["LuaDuanjianCard"] = 7.6
sgs.ai_use_priority["LuaDuanjianCard"] = 2.2

sgs.LuaDuanjian_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 5
}
sgs.ai_cardneed.LuaDuanjian = sgs.ai_cardneed.weapon

