-- Lolihime source b6025acc. Preserve the fixed first-201 discard scan and the
-- source's ordered table.remove(1) behavior; neither is a suit-count heuristic.
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("Lolihime helper unavailable",method) end
    return object[method](object,...)
end
local function known(value,key)
    if value==nil then ai_unsupported("Lolihime fact unknown",key) end
    return value
end
local function q(object,method,...)return known(call(object,method,...),method)end
sgs.ai_fill_skill.shouji=function(self,inclusive,request)
    if q(self.player,"hasUsed","#shoujicard") then return end
    if q(self.player,"getHandcardNum")<q(self.player,"getHp")+1 then return end
    local black=0
    for _,card in ipairs(q(self.player,"getHandcards"))do if q(card,"isBlack")then black=black+1 end end
    if black*3<q(self.player,"getHandcardNum") and #known(self.enemies,"enemies")<q(self.player,"getHp")+1 then return end
    return q(self,"legacySkillSeed","shouji","#shoujicard",request)
end
sgs.ai_skill_use_func["#shoujicard"]=function(card,use,self,request)
    local needed={}
    local cards=q(self.player,"getHandcards")
    for _,material in ipairs(cards)do
        if q(material,"isBlack")then
            needed[#needed+1]=q(material,"getEffectiveId")
            if #needed>q(self.player,"getHp")then break end
        end
    end
    if #needed<q(self.player,"getHp")+1 then
        for _,material in ipairs(cards)do
            if q(material,"isRed")then
                needed[#needed+1]=q(material,"getEffectiveId")
                if #needed>q(self.player,"getHp")then break end
            end
        end
    end
    use.card=q(self,"bindSkillCard","shouji",needed,request,nil,"#shoujicard")
end
sgs.ai_use_value.shoujicard=8
sgs.ai_use_priority.shoujicard=5
sgs.ai_skill_invoke.SE_Xinyuan=function(self)return #known(self.friends,"friends")>1 end
sgs.ai_skill_playerchosen.SE_Xinyuan=function(self)
    return call(self,"findPlayerToDraw",false,q(self.player,"getMark","xinyuan_dis"))
end
local suitOrder={sgs.Card_Spade,sgs.Card_Heart,sgs.Card_Club,sgs.Card_Diamond}
local suitNames={"spade","heart","club","diamond"}
local function contains(list,value)for _,v in ipairs(list)do if v==value then return true end end;return false end
sgs.ai_skill_invoke.dandiao=function(self)
    local discard,hand={0,0,0,0},{0,0,0,0}
    local ids=q(self.room,"getDiscardPile")
    -- swig/list.i exposes QList.value(i), so missing IntList entries are 0.
    for index=1,201 do
        local id=ids[index] or 0
        if id>0 then
            local card=q(self,"getKnownCardById",id)
            for suit=1,4 do if q(card,"getSuit")==suitOrder[suit] then discard[suit]=discard[suit]+1 end end
        end
    end
    local maximum=math.max(discard[1],discard[2],discard[3],discard[4])
    local condition={}
    for suit=1,4 do if discard[suit]==maximum then condition[#condition+1]=suitNames[suit]end end
    for _,card in ipairs(q(self.player,"getHandcards"))do
        for suit=1,4 do if q(card,"getSuit")==suitOrder[suit]then hand[suit]=hand[suit]+1 end end
    end
    for suit=1,4 do if hand[suit]==0 then hand[suit]=1000 end end
    local minimum=math.min(hand[1],hand[2],hand[3],hand[4])
    if minimum~=1 then return end
    -- This intentionally removes the first entry, not the named matching suit.
    for suit=1,4 do if hand[suit]>minimum and contains(condition,suitNames[suit])then table.remove(condition,1)end end
    return #condition>0
end
local function goodTarget(self,target)
    local facts=self.world and self.world.strategy_facts
    local global=facts and facts.lolihime_good_target
    if type(global)~="table" or global.known~=true then ai_unsupported("effective sgs.isGoodTarget metadata is unknown","lolihime.isGoodTarget")end
    if global.present==false then
        q(self,"useKnowledgeEstimate",{status="estimate",value=true,viewer=q(self.player,"objectName"),
            basis="donor_error_repair.lolihime_missing_sgs_isGoodTarget_to_common_method"},"lolihime.dandiao")
        return q(self,"isGoodTarget",target)
    end
    if global.source=="@lua/ai/original-hegemony/heg-standard_cards-ai.lua" and global.line==61 then
        return q(self,"originalHegemonyGlobalGoodTargetWithoutSelf",target)
    end
    -- A replaced or unknown global is not this fixed provider.
    ai_unsupported("effective global isGoodTarget provider is not migrated","lolihime.isGoodTarget")
end
sgs.ai_skill_playerchosen.dandiao=function(self)
    local enemies=known(self.enemies,"enemies")
    if #enemies>0 then
        for _,enemy in ipairs(enemies)do
            if q(enemy,"isAlive") and goodTarget(self,enemy) and q(self,"isWeak",enemy)
                and q(self,"damageIsEffective",enemy,sgs.DamageStruct_Thunder,self.player)
                and not q(enemy,"hasArmorEffect","SilverLion")then return enemy end
        end
    end
    for _,enemy in ipairs(enemies)do if q(enemy,"isAlive")then return enemy end end
    for _,player in ipairs(q(self.room,"getAlivePlayers"))do if not q(self,"isFriend",player)then return player end end
end
sgs.ai_skill_choice.eastfast=function(self)
    local options=self.request and self.request.options
    local fact=options and options.context and options.context.eastfast
    if type(fact)~="table" or fact.known~=true or type(fact.card)~="table" or type(fact.draw_pile_count)~="number"then
        ai_unsupported("eastfast notified card/count is unknown","eastfast")
    end
    local card=known(CardView.new(fact.card),"eastfast.card")
    local num=(fact.draw_pile_count-3*#q(self.room,"getDiscardPile"))/6
    local judges=q(self.player,"getCards","j")
    if #judges>0 then
        for index,c in ipairs(judges)do
            if #q(self.player,"getPile","save")==2+#q(self.player,"getCards","j")-index then
                if q(c,"isKindOf","Indulgence")then
                    if q(card,"getSuit")==sgs.Card_Heart then return "save"end
                    return "drop"
                elseif q(c,"isKindOf","SupplyShortage")then
                    if q(card,"getSuit")==sgs.Card_Club then return "save"end
                    return "drop"
                elseif q(c,"isKindOf","Lightning")then
                    if q(card,"getSuit")==sgs.Card_Spade then return "drop"end
                end
            end
        end
    end
    if q(card,"isKindOf","Tacos")then return "save"end
    local evaluation
    local function value()
        -- Enrich the already notified physical face only when source valuation
        -- is reached. This carries no acquisition or submission authority.
        if not evaluation then evaluation=q(self,"getAcquiredCardEvaluation",card) end
        return q(self,"getUseValue",evaluation)
    end
    if value()>5 then return "save"end
    if num>#q(self.room,"getAlivePlayers")*3 and value()>4.5 then return "save"end
    if num>2 and value()>=5 then return "save"end
    return "drop"
end
sgs.ai_cardneed.eastfast=function(to,card,self)return q(card,"isKindOf","Tacos")end
