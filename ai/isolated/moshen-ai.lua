-- Fixed moshen-ai.lua at b6025acc983331337614289d8cac79b078c003af.
-- Policy seeds carry no action authority; each selected action binds native costs.

local function sort_players(self,players,key)
    local sorted=self:sort(players, key)
    for i,p in ipairs(sorted) do players[i]=p end
    return players
end
local function sort_cards(self,cards,...)
    local sorted=self:sortByKeepValue(cards, ...)
    for i,c in ipairs(sorted) do cards[i]=c end
    return cards
end
local function action_request(self,request)
    -- Common callbacks receive an AILegacyRequest; direct Activate adapters may
    -- supply the outer decision DTO. Only its actual skill_action can become
    -- a source view. Without one, the common binder requires a unique native
    -- scope for this named skill (and rejects ambiguity).
    if request and type(request.getActivationSkillName)~="function" then
        return AILegacyRequest.new(request,self.room)
    end
    return request
end
local function seed(self,skill,class,request)
    return self:legacySkillSeed(skill, class, action_request(self,request))
end
local function bind(self,skill,class,costs,request)
    return self:bindSkillCard(skill, costs, action_request(self,request), nil, class)
end
sgs.ai_skill_playerchosen.ms_huangwei=function(self,targets)
    if #self.enemies==0 then return nil end
    local ts={}
    for _,enemy in ipairs(self.enemies) do
        if not enemy:isNude() then ts[#ts+1]=enemy end
    end
    if #ts>0 then sort_players(self,ts,"defense");return ts[1] end
end
sgs.ai_fill_skill.ms_mimou=function(self,inclusive,request)
    if not self.player:getStrategyHasUsed("#ms_mimou") then
        return seed(self,"ms_mimou","#ms_mimou",request)
    end
end
sgs.ai_skill_use_func["#ms_mimou"]=function(card,use,self,request)
    if #self.enemies<=0 and self.player:hasSkill("sy_canlue") then return nil end
    local cards=AIList.new(self.player:getHandcards())
    sort_cards(self,cards)
    local target
    local function select_for(chosen,relation)
        local will_use
        if AIValue.callKnown(self, relation, chosen) then
            for _,c in ipairs(cards) do
                if not c:isKindOf("Peach") and not c:isKindOf("Analeptic")
                    and not c:isKindOf("Nullification") then will_use=c;break end
            end
        end
        if will_use then
            use.card=bind(self,"ms_mimou","#ms_mimou",{will_use:getKnownEffectiveId()},request)
            if use.to then use.to:append(chosen) end
        end
    end
    if self.player:hasSkill("sy_canlue") then
        sort_players(self,self.enemies,"hp");target=self.enemies[1]
        if target then select_for(target,"isEnemy");return end
    else
        target=self.friends_noself[1]
        if target then select_for(target,"isFriend");return end
    end
    if not target then
        sort_players(self,self.enemies,"hp");target=self.enemies[1]
        if target then select_for(target,"isEnemy");return end
    end
end
sgs.ai_skill_choice.ms_mimou=function(self,choices,data)
    local source=data:toPlayer()
    if not source:hasSkill("sy_canlue") then
        if self:isFriend(source) then return "selfdraw3" end
    end
    local chs=choices:split("+")
    return chs[math.random(1,#chs)]
end
sgs.ai_use_value.ms_mimou=6
sgs.ai_use_priority.ms_mimou=0
sgs.ai_skill_invoke.ms_shawei=function(self,data)
    local use=data:toCardUse()
    if use.from then return self:isEnemy(use.from) end
end
sgs.ai_fill_skill.ms_yongheng=function(self,inclusive,request)
    if not self.player:getStrategyHasUsed("#ms_yonghengCard") then
        return seed(self,"ms_yongheng","#ms_yonghengCard",request)
    end
end
sgs.ai_skill_use_func["#ms_yonghengCard"]=function(card,use,self,request)
    -- Source updatePlayers must precede sorting and every role/target observation.
    self:updatePlayers()
    sort_players(self,self.friends,"hp")
    local reversed={}
    for i=#self.friends,1,-1 do reversed[#reversed+1]=self.friends[i] end
    self.friends=reversed
    local target
    for _,friend in ipairs(self.friends) do target=friend end
    if target==nil then return end
    use.card=self:inheritLegacyCardIdentity(bind(self,"ms_yongheng","#ms_yonghengCard",{},request), card)
    if use.to then use.to:append(target) end
end
sgs.ai_use_priority.ms_yonghengCard=10
sgs.ai_use_value.ms_yonghengCard=10
sgs.ai_card_intention.ms_yonghengCard=-100
sgs.ai_skill_invoke.ms_yuedong=true
sgs.ai_fill_skill.ms_guimou=function(self,inclusive,request)
    if self.player:isKongcheng() then return nil end
    if self.player:getMark("@guimou")<=0 then return nil end
    local suits={}
    -- Four separate scans and source suit-string calls are intentional.
    for _,suit in ipairs({sgs.Card_Spade,sgs.Card_Heart,sgs.Card_Club,sgs.Card_Diamond}) do
        for _,c in ipairs(self.player:getCards("he")) do
            if c:getSuit()==suit then suits[#suits+1]=c:getSuitString();break end
        end
    end
    if #suits>3 then return seed(self,"ms_guimou","#ms_guimou",request) end
end
sgs.ai_skill_use_func["#ms_guimou"]=function(card,use,self,request)
    local cards=AIList.new(self.player:getCards("he"))
    sort_cards(self,cards,false,true)
    local costs={};local spade,club,heart,diamond
    for _,c in ipairs(cards) do
        if c:getSuit()==sgs.Card_Spade then
            if not self.player:hasSkill("sy_renji") and not spade then
                spade=true;costs[#costs+1]=c:getKnownId()
            end
        elseif c:getSuit()==sgs.Card_Heart then
            if not self.player:hasSkill("sy_bolue") and not heart then
                heart=true;costs[#costs+1]=c:getKnownId()
            end
        elseif c:getSuit()==sgs.Card_Club then
            if not self.player:hasSkills("wansha|tongtian_wansha") and not club then
                club=true;costs[#costs+1]=c:getKnownId()
            end
        elseif c:getSuit()==sgs.Card_Diamond then
            if not self.player:hasSkill("sy_shisha") and not diamond then
                diamond=true;costs[#costs+1]=c:getKnownId()
            end
        end
    end
    if #costs<4 then return nil end
    use.card=bind(self,"ms_guimou","#ms_guimou",costs,request)
end
sgs.ai_use_value.ms_guimou=10
sgs.ai_use_priority.ms_guimou=9
