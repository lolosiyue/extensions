-- Lolihime source b6025acc. Preserve the fixed first-201 discard scan and the
-- source's ordered table.remove(1) behavior; neither is a suit-count heuristic.
local function known(value,key)
    if value==nil then ai_unsupported("Lolihime fact unknown",key) end
    return value
end
sgs.ai_fill_skill.shouji=function(self,inclusive,request)
    if (self.player:getStrategyHasUsed("#shoujicard")) then return end
    if (self.player:getHandcardNum())<(self.player:getHp())+1 then return end
    local black=0
    for _,card in ipairs((self.player:getHandcards()))do if (card:isBlack())then black=black+1 end end
    if black*3<(self.player:getHandcardNum()) and #known(self.enemies,"enemies")<(self.player:getHp())+1 then return end
    return (self:legacySkillSeed("shouji","#shoujicard",request))
end
sgs.ai_skill_use_func["#shoujicard"]=function(card,use,self,request)
    local needed={}
    local cards=(self.player:getHandcards())
    for _,material in ipairs(cards)do
        if (material:isBlack())then
            needed[#needed+1]=(material:getKnownEffectiveId())
            if #needed>(self.player:getHp())then break end
        end
    end
    if #needed<(self.player:getHp())+1 then
        for _,material in ipairs(cards)do
            if (material:isRed())then
                needed[#needed+1]=(material:getKnownEffectiveId())
                if #needed>(self.player:getHp())then break end
            end
        end
    end
    use.card=(self:bindSkillCard("shouji",needed,request,nil,"#shoujicard"))
end
sgs.ai_use_value.shoujicard=8
sgs.ai_use_priority.shoujicard=5
sgs.ai_skill_invoke.SE_Xinyuan=function(self)return #known(self.friends,"friends")>1 end
sgs.ai_skill_playerchosen.SE_Xinyuan=function(self)
    return self:findPlayerToDraw(false,(self.player:getMark("xinyuan_dis")))
end
local suitOrder={sgs.Card_Spade,sgs.Card_Heart,sgs.Card_Club,sgs.Card_Diamond}
local suitNames={"spade","heart","club","diamond"}
local function contains(list,value)for _,v in ipairs(list)do if v==value then return true end end;return false end
sgs.ai_skill_invoke.dandiao=function(self)
    local discard,hand={0,0,0,0},{0,0,0,0}
    local ids=(self.room:getDiscardPile())
    -- swig/list.i exposes QList.value(i), so missing IntList entries are 0.
    for index=1,201 do
        local id=ids[index] or 0
        if id>0 then
            local card=(self:getKnownCardById(id))
            for suit=1,4 do if (card:getSuit())==suitOrder[suit] then discard[suit]=discard[suit]+1 end end
        end
    end
    local maximum=math.max(discard[1],discard[2],discard[3],discard[4])
    local condition={}
    for suit=1,4 do if discard[suit]==maximum then condition[#condition+1]=suitNames[suit]end end
    for _,card in ipairs((self.player:getHandcards()))do
        for suit=1,4 do if (card:getSuit())==suitOrder[suit]then hand[suit]=hand[suit]+1 end end
    end
    for suit=1,4 do if hand[suit]==0 then hand[suit]=1000 end end
    local minimum=math.min(hand[1],hand[2],hand[3],hand[4])
    if minimum~=1 then return end
    -- This intentionally removes the first entry, not the named matching suit.
    for suit=1,4 do if hand[suit]>minimum and contains(condition,suitNames[suit])then table.remove(condition,1)end end
    return #condition>0
end
local function goodTarget(self,target)
    -- The donor's global sgs.isGoodTarget has one definer, the Original Hegemony AI
    -- (heg-standard_cards-ai.lua:61), loaded exactly when the hegemony facts say so.
    local h=AIHegemony.facts(self.world)
    if type(h)~="table" then ai_unsupported("effective sgs.isGoodTarget metadata is unknown","lolihime.isGoodTarget")end
    if h.original_overrides_loaded~=true then
        self:useKnowledgeEstimate({status="estimate",value=true,viewer=(self.player:objectName()),
            basis="donor_error_repair.lolihime_missing_sgs_isGoodTarget_to_common_method"},"lolihime.dandiao")
        return (self:isGoodTarget(target))
    end
    return (self:originalHegemonyGlobalGoodTargetWithoutSelf(target))
end
sgs.ai_skill_playerchosen.dandiao=function(self)
    local enemies=known(self.enemies,"enemies")
    if #enemies>0 then
        for _,enemy in ipairs(enemies)do
            if (enemy:isAlive()) and goodTarget(self,enemy) and (self:isWeak(enemy))
                and (self:damageIsEffective(enemy,sgs.DamageStruct_Thunder,self.player))
                and not (enemy:hasArmorEffect("SilverLion"))then return enemy end
        end
    end
    for _,enemy in ipairs(enemies)do if (enemy:isAlive())then return enemy end end
    for _,player in ipairs((self.room:getAlivePlayers()))do if not (self:isFriend(player))then return player end end
end
sgs.ai_skill_choice.eastfast=function(self)
    local options=self.request and self.request.options
    local fact=options and options.context and options.context.eastfast
    if type(fact)~="table" or fact.known~=true or type(fact.card)~="table" or type(fact.draw_pile_count)~="number"then
        ai_unsupported("eastfast notified card/count is unknown","eastfast")
    end
    local card=known(CardView.new(fact.card),"eastfast.card")
    local num=(fact.draw_pile_count-3*#(self.room:getDiscardPile()))/6
    local judges=(self.player:getCards("j"))
    if #judges>0 then
        for index,c in ipairs(judges)do
            if #(self.player:getPile("save"))==2+#(self.player:getCards("j"))-index then
                if (c:isKindOf("Indulgence"))then
                    if (card:getSuit())==sgs.Card_Heart then return "save"end
                    return "drop"
                elseif (c:isKindOf("SupplyShortage"))then
                    if (card:getSuit())==sgs.Card_Club then return "save"end
                    return "drop"
                elseif (c:isKindOf("Lightning"))then
                    if (card:getSuit())==sgs.Card_Spade then return "drop"end
                end
            end
        end
    end
    if (card:isKindOf("Tacos"))then return "save"end
    local evaluation
    local function value()
        -- Enrich the already notified physical face only when source valuation
        -- is reached. This carries no acquisition or submission authority.
        if not evaluation then evaluation=(self:getAcquiredCardEvaluation(card)) end
        return (self:getUseValue(evaluation))
    end
    if value()>5 then return "save"end
    if num>#(self.room:getAlivePlayers())*3 and value()>4.5 then return "save"end
    if num>2 and value()>=5 then return "save"end
    return "drop"
end
sgs.ai_cardneed.eastfast=function(to,card,self)return (card:isKindOf("Tacos"))end
