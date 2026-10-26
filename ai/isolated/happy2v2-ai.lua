-- Source: b6025acc ai/happy2v2-ai.lua.
local known = AIValue.requireKnown

local function discard(self,target,flags)
    if type(self.doDisCard)~="function" then ai_unsupported("Happy2v2 discard helper unavailable","doDisCard") end
    local value=self:doDisCard(target,flags)
    if AIUnsupported and AIUnsupported.is(value) then error(value,0) end
    return value -- nil is a legitimate donor negative result.
end
-- Player::isYourFriend uses role initials, unlike SmartAI's beFriend.
-- Hidden identities are replaced by the viewer's explicit role estimate.
local function team_friend(self,target)
    local own=self.player:getKnownRole()
    local role=type(target.getRole)=="function" and target:getRole() or nil
    local estimated=role==nil
    if estimated then role=self:getRoleEstimate(target) end
    local value
    if own=="renegade" or role=="renegade" then value=self.player:objectName()==target:objectName()
    else value=own~="" and role~="" and own:sub(1,1)==role:sub(1,1) end
    if estimated then
        return self:useKnowledgeEstimate({value=value,status="estimate",viewer=self.player:objectName(),target=target:objectName(),
            basis="isYourFriend role-initial formula using viewer role estimate; hidden native role excluded"},"Happy2v2.team")
    end
    return value
end
ai_fill_skill.kuiji=function(self, options, request)
    local inclusive = options and options.inclusive

    return self:legacySkillSeed("kuiji", "KuijiCard", request)
end
ai_card_use.KuijiCard=function(self, card, use, request)
    local cards={}
    for _,c in ipairs(self.player:getCards("he")) do
        if c:isKindOf("BasicCard") and c:isBlack() then cards[#cards+1]=c end
    end
    if #cards==0 then return end
    cards=self:sortByKeepValue(cards)
    local material=cards[1]
    local id=material:getKnownEffectiveId()
    -- Preserve the source constructor as a hypothesis. Only the final selected
    -- plan binds payment; a using/invalid first material must not be skipped.
    use.card=self:evaluateTurnSkillCard("kuiji", "KuijiCard", {id}, request)
end
sgs.ai_skill_playerchosen.kuiji=function(self,targets)
    targets=self:sort(targets, "defense")
    if not team_friend(self,targets[1]) then
        for _,p in ipairs(targets) do
            if self:cantDamageMore(self.player, p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then return p end
        end
        for _,p in ipairs(targets) do if self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then return p end end
    end
    for _,p in ipairs(targets) do if self:isWeak(p) then return p end end
    return targets[#targets]
end
sgs.ai_use_priority.KuijiCard=10
sgs.ai_use_value.KuijiCard=10
sgs.ai_skill_playerchosen.happycuorui=function(self,targets)
    if team_friend(self,targets[1]) then return self:findPlayerToDiscard("hej", true, true, targets)[1] end
    local target=self:findPlayerToDiscard("e", false, true, targets)[1]
    if target then return target end
    local enemies={}
    for _,p in ipairs(targets) do
        if self.player:canDiscard(p, "e") and discard(self,p,"e") then enemies[#enemies+1]=p end
    end
    if #enemies>0 then return self:sort(enemies, "defense")[1] end
    for _,p in ipairs(targets) do if self.player:canDiscard(p, "e") then enemies[#enemies+1]=p end end
    if #enemies>0 then return self:sort(enemies, "defense")[1] end
    return targets[1]
end
ai_skill_choice.happycuorui=function(self, native_options, native_request)
    local choices = native_options and native_options.choices ~= nil and table.concat(native_options.choices, "+") or native_options and (native_options.inquiry_scope == "ordinary_top_level" or native_options.inquiry_scope == "original_top_level") and "" or nil
    local data = native_request and self:getDecisionData(native_request) or nil

    local context=self.request and self.request.options and self.request.options.context
    local row=type(context)=="table" and context.happycuorui_card
    if type(row)~="table" then ai_unsupported("HappyCuorui paid public card face is missing","happycuorui") end
    local card=CardView.new(row)
    local found=false
    for _,p in ipairs(self.room:getOtherPlayers(self.player)) do
        if not team_friend(self,p) then
            for _,c in ipairs(p:getEquips()) do
                if c:isRed()==card:isRed() and c:isBlack()==card:isBlack()
                    and self.player:canDiscard(p, c:getKnownEffectiveId()) and discard(self,p,"e") then found=true end
            end
        end
    end
    return ai_choice_result((found and "discard" or "show"), native_options)
end
sgs.ai_skill_playerchosen.happycuorui2=function(self,targets)
    return self:findPlayerToDiscard("e", false, true, targets)[1]
end
sgs.ai_skill_playerchosen.happycuorui3=function(self,targets)
    return self:sort(targets, "handcard")[1]
end
