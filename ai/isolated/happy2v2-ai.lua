-- Happy2v2 source b6025acc; package policy only, no mode/rule changes.
local function known(value,key)
    if AIUnsupported and AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("Happy2v2 query is unknown",key) end
    return value
end
local function q(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("Happy2v2 query unavailable",method) end
    return known(object[method](object,...),method)
end
local function discard(self,target,flags)
    if type(self.doDisCard)~="function" then ai_unsupported("Happy2v2 discard helper unavailable","doDisCard") end
    local value=self:doDisCard(target,flags)
    if AIUnsupported and AIUnsupported.is(value) then error(value,0) end
    return value -- nil is a legitimate donor negative result.
end
-- Player::isYourFriend uses role initials, unlike SmartAI's beFriend.
-- Hidden identities are replaced by the viewer's explicit role estimate.
local function team_friend(self,target)
    local own=q(self.player,"getRole")
    local role=type(target.getRole)=="function" and target:getRole() or nil
    local estimated=role==nil
    if estimated then role=q(self,"getRoleEstimate",target) end
    local value
    if own=="renegade" or role=="renegade" then value=q(self.player,"objectName")==q(target,"objectName")
    else value=own~="" and role~="" and own:sub(1,1)==role:sub(1,1) end
    if estimated then
        return self:useKnowledgeEstimate({value=value,status="estimate",viewer=self.player:objectName(),target=target:objectName(),
            basis="isYourFriend role-initial formula using viewer role estimate; hidden native role excluded"},"Happy2v2.team")
    end
    return value
end
sgs.ai_fill_skill.kuiji=function(self,inclusive,request)
    return q(self,"legacySkillSeed","kuiji","KuijiCard",request)
end
sgs.ai_skill_use_func.KuijiCard=function(card,use,self,request)
    local cards={}
    for _,c in ipairs(q(self.player,"getCards","he")) do
        if q(c,"isKindOf","BasicCard") and q(c,"isBlack") then cards[#cards+1]=c end
    end
    if #cards==0 then return end
    cards=q(self,"sortByKeepValue",cards)
    local material=cards[1]
    local id=q(material,"getEffectiveId")
    -- Preserve the source constructor as a hypothesis. Only the final selected
    -- plan binds payment; a using/invalid first material must not be skipped.
    use.card=q(self,"evaluateTurnSkillCard","kuiji","KuijiCard",{id},request)
end
sgs.ai_skill_playerchosen.kuiji=function(self,targets)
    targets=q(self,"sort",targets,"defense")
    if not team_friend(self,targets[1]) then
        for _,p in ipairs(targets) do
            if q(self,"cantDamageMore",self.player,p) and q(self,"damageIsEffective",p,sgs.DamageStruct_Normal,self.player) then return p end
        end
        for _,p in ipairs(targets) do if q(self,"damageIsEffective",p,sgs.DamageStruct_Normal,self.player) then return p end end
    end
    for _,p in ipairs(targets) do if q(self,"isWeak",p) then return p end end
    return targets[#targets]
end
sgs.ai_use_priority.KuijiCard=10
sgs.ai_use_value.KuijiCard=10
sgs.ai_skill_playerchosen.happycuorui=function(self,targets)
    if team_friend(self,targets[1]) then return q(self,"findPlayerToDiscard","hej",true,true,targets)[1] end
    local target=q(self,"findPlayerToDiscard","e",false,true,targets)[1]
    if target then return target end
    local enemies={}
    for _,p in ipairs(targets) do
        if q(self.player,"canDiscard",p,"e") and discard(self,p,"e") then enemies[#enemies+1]=p end
    end
    if #enemies>0 then return q(self,"sort",enemies,"defense")[1] end
    for _,p in ipairs(targets) do if q(self.player,"canDiscard",p,"e") then enemies[#enemies+1]=p end end
    if #enemies>0 then return q(self,"sort",enemies,"defense")[1] end
    return targets[1]
end
sgs.ai_skill_choice.happycuorui=function(self,choices,data)
    local context=self.request and self.request.options and self.request.options.context
    local row=type(context)=="table" and context.happycuorui_card
    if type(row)~="table" then ai_unsupported("HappyCuorui paid public card face is missing","happycuorui") end
    local card=CardView.new(row)
    local found=false
    for _,p in ipairs(q(self.room,"getOtherPlayers",self.player)) do
        if not team_friend(self,p) then
            for _,c in ipairs(q(p,"getEquips")) do
                if q(c,"isRed")==q(card,"isRed") and q(c,"isBlack")==q(card,"isBlack")
                    and q(self.player,"canDiscard",p,q(c,"getEffectiveId")) and discard(self,p,"e") then found=true end
            end
        end
    end
    return found and "discard" or "show"
end
sgs.ai_skill_playerchosen.happycuorui2=function(self,targets)
    return q(self,"findPlayerToDiscard","e",false,true,targets)[1]
end
sgs.ai_skill_playerchosen.happycuorui3=function(self,targets)
    return q(self,"sort",targets,"handcard")[1]
end
