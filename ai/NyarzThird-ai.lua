--驭衡
local getDrawNumForNYTongYe
getDrawNumForNYTongYe = function(num,others)
    for _,other in ipairs(others) do
        if other == num then
            return 1 +  getDrawNumForNYTongYe(num+1,others)
        end
    end
    return 0
end

sgs.ai_skill_discard.nyarz_yuheng = function(self, max, min)
    local disCards = {}
    if self.player:isKongcheng() then return disCards end
    if (not self.player:hasSkill("nyarz_tongye")) and self.player:getPhase() == sgs.Player_NotActive then return disCards end

    if (not self.player:hasSkill("nyarz_tongye")) then
        local num = math.min(3,math.ceil(self.player:getHandcardNum()/2))
        if num == 0 then return disCards end
        local handcards = self:sortByUseValue(sgs.QList2Table(self.player:getHandcards()))
        for i = 1, num, 1 do
            table.insert(disCards, handcards[i]:getEffectiveId())
        end
        return disCards
    end
    
    local maxValue = 0
    local bestNum = 0
    local target = self.room:getCurrent()

    for i = 1, math.min(3,self.player:getHandcardNum()),1 do
        --先考虑自己弃牌可能带来的收益
        local value = -1*i
        local temHandcardNum = self.player:getHandcardNum() - i
        local others = {}
        for _,other in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            table.insert(others,other:getHandcardNum())
        end
        
        local temDraw = getDrawNumForNYTongYe(temHandcardNum,others)

        value = value + temDraw
        temHandcardNum = temHandcardNum + temDraw

        local disNum = math.min(i,target:getHandcardNum())
        local temTargetNum = {target:getHandcardNum() + i, target:getHandcardNum() - disNum}
        local temValue = {0,0}
        local canDraw = false
        --令当前回合角色摸牌收益
        if self:isFriend(target) then temValue[1] = temValue[1] + i end
        if self:isEnemy(target) then temValue[1] = temValue[1] - i end

        table.removeOne(others,target:getHandcardNum())
        table.insert(others,temTargetNum[1])
        if temTargetNum[1] == temHandcardNum then
            canDraw = true
        else
            for _,other in sgs.qlist(self.room:getOtherPlayers(target)) do
                if other:getHandcardNum() == temTargetNum[1] 
                and other:objectName() ~= self.player:objectName() then
                    canDraw = true
                    break
                end
            end
        end
        if canDraw then 
            temValue[1] = temValue[1] + 1 + getDrawNumForNYTongYe(temHandcardNum+1,others)
        else
            temValue[1] = temValue[1] + getDrawNumForNYTongYe(temHandcardNum,others)
        end

        --令当前回合角色弃牌收益
        if self:isFriend(target) then temValue[2] = temValue[2] - disNum end
        if self:isEnemy(target) then temValue[2] = temValue[2] + disNum end

        table.removeOne(others,temTargetNum[1])
        table.insert(others,temTargetNum[2])
        canDraw = false
        if temTargetNum[2] == temHandcardNum then
            canDraw = true
        else
            for _,other in sgs.qlist(self.room:getOtherPlayers(target)) do
                if other:getHandcardNum() == temTargetNum[2] 
                and other:objectName() ~= self.player:objectName() then
                    canDraw = true
                    break
                end
            end
        end
        if canDraw then 
            temValue[2] = temValue[2] + 1 + getDrawNumForNYTongYe(temHandcardNum+1,others)
        else
            temValue[2] = temValue[2] + getDrawNumForNYTongYe(temHandcardNum,others)
        end

        value = value + math.max(temValue[1],temValue[2])

        if value > maxValue then 
            maxValue = value 
            bestNum = i
        end
        
    end

    if bestNum == 0 then
        local num = {}
        for _,pl in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            table.insert(num,pl:getHandcardNum())
        end
        if self.player:getHandcardNum() > (math.max(unpack(num)) + 5) then
            if self.player:getPhase() == sgs.Player_NotActive then
                if self:isEnemy(target) then
                    bestNum = math.min(3,target:getHandcardNum())
                elseif self:isFriend(target) then
                    bestNum = 3
                end
            else
                bestNum = 3
            end
        end

    end

    if bestNum ~= 0 then
        local handcards = sgs.QList2Table(self.player:getHandcards())
        if self.player:getPhase() == sgs.Player_NotActive then
            self:sortByKeepValue(handcards)
        else
            self:sortByUseValue(handcards,true)
        end
        for i = 1, bestNum, 1 do
            table.insert(disCards, handcards[i]:getEffectiveId())
        end
    end
        

    return disCards
end

sgs.ai_skill_choice.nyarz_yuheng = function(self, choices, data)
    local num = data:toInt()
    local target = self.room:getCurrent()

    if (not self.player:hasSkill("nyarz_tongye")) then 
        if self:isEnemy(target) then return "discard"
        else return "draw" end
    end

    local value = {0,0}
    if self:isEnemy(target) then
        value[1] = -1*num
        value[2] = num
    elseif self:isFriend(target) then
        value[1] = math.min(num,target:getHandcardNum())
        value[2] = -1*math.min(num,target:getHandcardNum())
    end

    local temNum = {target:getHandcardNum()+num,target:getHandcardNum()-math.min(num,target:getHandcardNum())}
    for i = 1,2,1 do
        local canDraw = false
        for _,other in sgs.qlist(self.room:getOtherPlayers(target)) do
            if other:getHandcardNum() == temNum[i] then
                canDraw = true
                break
            end
        end
        local others = {}
        for _,other in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            table.insert(others,other:getHandcardNum())
        end
        if i == 1 then
            table.removeOne(others,target:getHandcardNum())
            table.insert(others,temNum[1])
        else
            table.removeOne(others,temNum[1])
            table.insert(others,temNum[2])
        end
        if canDraw then
            value[i] = value[i] + 1 + getDrawNumForNYTongYe(self.player:getHandcardNum()+1,others)
        else
            value[i] = value[i] + getDrawNumForNYTongYe(self.player:getHandcardNum(),others)
        end
    end

    if value[2] > value[1] then return "discard"
    else return "draw" end
end

--天下负我

function SmartAI:useCardRetribution(card,use)
	self:sort(self.enemies)
	local enemies = {}
	for _,enemy in sgs.list(self.enemies)do
		if CanToCard(card,self.player,enemy) then 
            table.insert(enemies,enemy) 
        end
	end

	if #enemies<1 then return end

	local extraTarget = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,enemy in sgs.list(enemies)do
		use.to:append(enemy)
		if use.to:length()>extraTarget
		then 
            use.card = card
            return 
        end
	end
end

sgs.ai_use_value.Retribution = 4.9
sgs.ai_keep_value.Retribution = 3.4
sgs.ai_use_priority.Retribution = sgs.ai_use_priority.Dismantlement+0.2

sgs.dynamic_value.damage_card.Retribution = true

sgs.ai_card_intention.Retribution = 80

sgs.ai_nullification.Retribution = function(self,trick,from,to,positive)
    local null_num = self:getCardsNum("Nullification")
	if positive then
        if to==self.player then
			return true
		end
		return self:isFriend(to) and (null_num>1 and self:isWeak(to))
	else
        return self:isEnemy(to) and self:isWeak(to)
	end
end

--治世

sgs.ai_skill_use["@@nyarz_zhishi"] = function(self, prompt)
    if self:isWeak() and self.player:getPhase() == sgs.Player_Finish then return "." end
    local pattern = self.player:property("nyarz_zhishi"):toString()
    local card = sgs.Sanguosha:cloneCard(pattern)
    card:setSkillName("_nyarz_zhishi_card")
    card:deleteLater()

    local usec = {isDummy=true,to=sgs.SPlayerList()}
    self:useCardByClassName(card, usec)
    if usec.card then
        if usec.to and usec.to:length() > 0 then
            local tos = {}
            for _,p in sgs.qlist(usec.to) do
                table.insert(tos, p:objectName())
            end
            return card:toString().."->"..table.concat(tos, "+")
        else
            return card:toString()
        end
    end

    --不适合的伤害牌就摸两张完事
    return "."
end

sgs.ai_skill_choice["nyarz_zhishi_slash"] = function(self, choices, data)
	local patterns = {"fire_slash","thunder_slash","slash"}
    for _,pattern in ipairs(patterns) do
        local card = sgs.Sanguosha:cloneCard(pattern)
        card:setSkillName("_nyarz_zhishi_card")
        card:deleteLater()

        local usec = {isDummy=true,to=sgs.SPlayerList()}
        self:useCardByClassName(card, usec)
        if usec.card then
            return pattern
        end
    end
    return "slash"
end

sgs.ai_skill_choice["nyarz_zhishi"] = function(self, choices, data)
	local patterns = choices:split("+")
    --回合外保留一下对【杀】的抗性
    if self.player:getPhase() == sgs.Player_Finish then
        if table.contains(patterns, "cancel") and table.contains(patterns, "slash") then
            if #patterns == 2 then
                return "cancel"
            else
                table.removeOne(patterns, "slash")
            end
        end
    else
        --回合内尽量用完所有记录，便于结束阶段回血摸牌
        if table.contains(patterns, "cancel") then
            table.removeOne(patterns, "cancel")
        end
    end

    --要用哪张牌就选哪张好了
    for _,pattern in ipairs(patterns) do
        local card = sgs.Sanguosha:cloneCard(pattern)
        card:setSkillName("_nyarz_zhishi_card")
        card:deleteLater()

        local usec = {isDummy=true,to=sgs.SPlayerList()}
        self:useCardByClassName(card, usec)
        if usec.card then
            return pattern
        end
    end

    --随机选一个不想用的牌名变成温暖的两张手牌
    return patterns[math.random(1,#patterns)]
end

--扬武

sgs.ai_skill_invoke.nyarz_yangwu = true

--霸关

sgs.ai_skill_invoke.nyarz_baguan = true

sgs.ai_skill_choice["nyarz_baguan_slash"] = function(self, choices, data)
	local patterns = {"fire_slash","thunder_slash","slash"}
    for _,pattern in ipairs(patterns) do
        local card = sgs.Sanguosha:cloneCard(pattern)
        card:setSkillName("nyarz_baguan")
        card:deleteLater()

        local usec = {isDummy=true,to=sgs.SPlayerList()}
        self:useCardByClassName(card, usec)
        if usec.card then
            return pattern
        end
    end
    return "slash"
end

sgs.ai_skill_use["@@nyarz_baguan"] = function(self, prompt)
    local pattern = self.player:property("nyarz_baguan"):toString()
    local card = sgs.Sanguosha:cloneCard(pattern)
    card:setSkillName("nyarz_baguan")
    card:deleteLater()

    local usec = {isDummy=true,to=sgs.SPlayerList()}
    self:useCardByClassName(card, usec)
    if usec.card then
        if usec.to and usec.to:length() > 0 then
            local tos = {}
            for _,p in sgs.qlist(usec.to) do
                table.insert(tos, p:objectName())
            end
            return card:toString().."->"..table.concat(tos, "+")
        end
    end

    return "."
end