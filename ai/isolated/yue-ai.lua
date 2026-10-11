-- Yue, effective donor b6025acc. Policy identities stay distinct from native
-- V2 products; only issued receipts can become submitted actions.
local function call(object, method, ...)
    if not object or type(object[method])~="function" then ai_unsupported("Yue policy helper unavailable",method) end
    local value=object[method](object,...)
    if AIUnsupported.is(value) then error(value,0) end
    return value
end
local function known(value,key)
    if value==nil then ai_unsupported("Yue policy fact unknown",key) end
    return value
end
local function q(object,method,...) return known(call(object,method,...),method) end
local function sorted_in_place(self,list,key)
    local sorted=q(self,"sort",known(list,key),key)
    for i,p in ipairs(sorted) do list[i]=p end
    return list
end
local function legacy(self,skill,class,request,user_string)
    -- Native projects the original SkillCard's owner lock and evaluation rules;
    -- borrowing the ordinary V2 product's rules would change source decisions.
    return q(self,"bindSkillCard",skill,{},request,user_string,class)
end
sgs.ai_fill_skill.jinxuanbei=function(self,inclusive,request)
    return q(self,"legacySkillSeed","jinxuanbei","JinXuanbeiCard",request)
end
sgs.ai_skill_use_func.JinXuanbeiCard=function(card,use,self,request)
    sorted_in_place(self,self.enemies,"hp")
    local can=q(self,"getCardsNum","Jink")>0 or not q(self,"isWeak")
    local function choose(target)
        use.card=q(self,"inheritLegacyCardIdentity",legacy(self,"jinxuanbei","JinXuanbeiCard",request),card)
        use.to:append(target)
    end
    for _,p in ipairs(self.enemies) do if call(self,"doDisCard",p,"e") and can then choose(p);return end end
    for _,p in ipairs(known(self.friends_noself,"friends_noself")) do if call(self,"doDisCard",p,"ej") and can then choose(p);return end end
    for _,p in ipairs(self.enemies) do if call(self,"doDisCard",p,"he") and can then choose(p);return end end
    for _,p in ipairs(q(self.room,"getOtherPlayers",self.player)) do
        if call(self,"doDisCard",p,"he") and not q(self,"isFriend",p) and can then choose(p);return end
    end
end
-- These apparently unrelated keys are the literal donor assignments.
sgs.ai_use_value.bf_zhenliangCard=4.4
sgs.ai_use_priority.bf_zhenliangCard=3.8
sgs.ai_fill_skill.jinxianwan=function(self,inclusive,request)
    local slash=q(self,"evaluateSkillCard","jinxianwan","slash",{})
    if q(self.player,"isChained") and q(slash,"isAvailable",self.player) then
        local use=q(self,"aiUseCard",slash)
        -- The original VM-global write is kept viewer-local by the common
        -- transaction helper, which records its explicit privacy estimate.
        q(self,"setPriorityValue","jinxianwan",q(self,"getPriorityValue",q(slash,"getClassName"),slash),"jinxianwan")
        self.xw_to=use.to
        if use.card and use.to then return legacy(self,"jinxianwan","JinXianwanCard",request,"slash") end
    end
end
sgs.ai_skill_use_func.JinXianwanCard=function(card,use,self)
    if self.xw_to then use.card=card;use.to=self.xw_to end
end
sgs.ai_use_value.JinXianwanCard=9.4
sgs.ai_use_priority.JinXianwanCard=7.8
sgs.ai_guhuo_card.jinxianwan=function(self,toname,class_name)
    return {skill="jinxianwan",legacy_class="JinXianwanCard",subcards={},user_string=toname}
end
sgs.ai_skill_invoke.jinwanyi=function(self,data)
    local target=call(data,"toPlayer")
    if target then return q(self,"isFriend",target) and call(self,"doDisCard",target,"ej") or call(self,"doDisCard",target,"hej") end
end
sgs.ai_skill_playerchosen.jinwanyi=function(self,players)
    local targets=q(self,"sort",AIList.new(players),"hp")
    for _,target in ipairs(targets) do if q(self,"isFriend",target) then return target end end
    for _,target in ipairs(targets) do if not q(self,"isEnemy",target) then return target end end
    return targets[1]
end
sgs.ai_skill_invoke.jinmaihuo=function(self,data)
    local target=q(data,"toCardUse").from
    if target then return not q(self,"isFriend",target) end
end
