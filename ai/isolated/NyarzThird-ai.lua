-- Fixed b6025acc NyarzThird source policies. Hypothetical clones are readonly;
-- only the selected @@ response binds its actual owner V2 action.
local function known(v,key)
    if v==nil then ai_unsupported("NyarzThird policy fact is unknown",key)end
    return v
end

local function property(self,key)
    -- The viewer's own property, read like the donor's toString() (absent reads "").
    local value=self.player:getPropertyValue(key)
    if value==nil then return "" end
    if type(value)~="string"then ai_unsupported("owner skill property is not a string",key)end
    return value
end
local function clone(self,skill,name)
    local card=self:evaluateSkillCard(skill,name,{})
    -- Donor invokes setSkillName before any nil test, including a surviving
    -- cancel entry. Keep that ordinary source error, not a pass or a repair.
    if card==nil then error("attempt to index a nil value (local 'card')",0)end
    return card
end
-- The candidate DTO is immutable for this one readonly class dispatch.
-- Reuse its facade just as evaluateTianyiSlash does; do not enter aiUseCard's
-- revise pipeline, cache policy results, or retain the projection across calls.
local function use_clone(self,card,use)
    local previous=self._evaluation_scope
    if previous and previous.card==card then return self:useCardByClassName(card,use)end
    local candidate
    if AIValue.isCard(card) and card:isEvaluationOnly() and type(self.getEvaluationCandidate)=="function"then
        candidate=self:getEvaluationCandidate(card)
    end
    if not candidate then return self:useCardByClassName(card,use)end
    self._evaluation_scope={card=card,candidate=candidate}
    local ok,result=pcall(self.useCardByClassName,self,card,use)
    self._evaluation_scope=previous
    if not ok then error(result,0)end
    return result
end
local function can_to(self,card,target)
    -- Native readonly cards expose the exact empty-prefix rule in their owner
    -- evaluation; physical/issued cards use the same narrow facade endpoint.
    return self:cardTargetFilter(card, {}, target)
end
local function sort_enemies(self)
    local current=known(self.enemies,"enemies")
    local sorted=self:sort(current)
    for i,p in ipairs(sorted)do current[i]=p end
end
local function response(self,skill,card,use,needs_target)
    if not use.card then return "."end
    if needs_target and (not use.to or #use.to==0)then return "."end
    local paid=self:bindSkillCard(skill, {})
    local targets={}
    for _,p in ipairs(use.to or{})do targets[#targets+1]=p:objectName()end
    -- Source returns the original hypothetical card, even if planning wrote a
    -- different use.card. Native scope must reproduce that original declaration.
    if paid:objectName()~=card:objectName()then
        ai_unsupported("selected response declaration changed","NyarzThird.response")
    end
    return {kind="use_card",card_spec=paid:toCardSpec(),targets=targets}
end

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
        local handcards = self:sortByUseValue(AIList.new(self.player:getHandcards()))
        for i = 1, num, 1 do
            table.insert(disCards, handcards[i]:getKnownEffectiveId())
        end
        return disCards
    end

    local maxValue = 0
    local bestNum = 0
    local target = self.room:getKnownCurrent()

    for i = 1, math.min(3,self.player:getHandcardNum()),1 do
        --先考虑自己弃牌可能带来的收益
        local value = -1*i
        local temHandcardNum = self.player:getHandcardNum() - i
        local others = {}
        for _,other in ipairs(self.room:getOtherPlayers(self.player)) do
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
            for _,other in ipairs(self.room:getOtherPlayers(target)) do
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
            for _,other in ipairs(self.room:getOtherPlayers(target)) do
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
        for _,pl in ipairs(self.room:getOtherPlayers(self.player)) do
            table.insert(num,pl:getHandcardNum())
        end
        if self.player:getHandcardNum() > (math.max(table.unpack(num)) + 5) then
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
        local handcards = AIList.new(self.player:getHandcards())
        if self.player:getPhase() == sgs.Player_NotActive then
            handcards = self:sortByKeepValue(handcards)
        else
            handcards = self:sortByUseValue(handcards, true)
        end
        for i = 1, bestNum, 1 do
            table.insert(disCards, handcards[i]:getKnownEffectiveId())
        end
    end


    return disCards
end

sgs.ai_skill_choice.nyarz_yuheng = function(self, choices, data)
    local num = known(self:getDecisionContext().nyarz_yuheng_count,"nyarz_yuheng count")
    local target = self.room:getKnownCurrent()

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
        for _,other in ipairs(self.room:getOtherPlayers(target)) do
            if other:getHandcardNum() == temNum[i] then
                canDraw = true
                break
            end
        end
        local others = {}
        for _,other in ipairs(self.room:getOtherPlayers(self.player)) do
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

function SmartAIView:useCardRetribution(card,use)
	sort_enemies(self)
	local enemies = {}
	for _,enemy in ipairs(self.enemies)do
		if can_to(self,card,enemy) then
            table.insert(enemies,enemy)
        end
	end

	if #enemies<1 then return end

	local extraTarget = card:getKnownTargetModExtra(self.player)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,enemy in ipairs(enemies)do
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


ai_card_use.Retribution=SmartAIView.useCardRetribution

-- 治世
sgs.ai_skill_use["@@nyarz_zhishi"]=function(self,prompt)
    if self:isWeak()and self.player:getPhase()==sgs.Player_Finish then return "."end
    local card=clone(self,"nyarz_zhishi",property(self,"nyarz_zhishi"))
    local use={isDummy=true,to=AIList.new({})}
    use_clone(self,card,use)
    return response(self,"nyarz_zhishi",card,use,false)
end
local function choose_slash(self,skill)
    for _,name in ipairs({"fire_slash","thunder_slash","slash"})do
        local card=clone(self,skill,name)
        local use={isDummy=true,to=AIList.new({})}
        use_clone(self,card,use)
        if use.card then return name end
    end
    return "slash"
end
sgs.ai_skill_choice.nyarz_zhishi_slash=function(self,choices,data)
    return choose_slash(self,"nyarz_zhishi")
end
sgs.ai_skill_choice.nyarz_zhishi=function(self,choices,data)
    local patterns=choices:split("+")
    if self.player:getPhase()==sgs.Player_Finish then
        if table.contains(patterns,"cancel")and table.contains(patterns,"slash")then
            if #patterns==2 then return "cancel"else table.removeOne(patterns,"slash")end
        end
    elseif table.contains(patterns,"cancel")then table.removeOne(patterns,"cancel")end
    for _,name in ipairs(patterns)do
        local card=clone(self,"nyarz_zhishi",name)
        local use={isDummy=true,to=AIList.new({})}
        use_clone(self,card,use)
        if use.card then return name end
    end
    return patterns[math.random(1,#patterns)]
end
sgs.ai_skill_invoke.nyarz_yangwu=true
sgs.ai_skill_invoke.nyarz_baguan=true
sgs.ai_skill_choice.nyarz_baguan_slash=function(self,choices,data)
    return choose_slash(self,"nyarz_baguan")
end
sgs.ai_skill_use["@@nyarz_baguan"]=function(self,prompt)
    local card=clone(self,"nyarz_baguan",property(self,"nyarz_baguan"))
    local use={isDummy=true,to=AIList.new({})}
    use_clone(self,card,use)
    return response(self,"nyarz_baguan",card,use,true)
end
