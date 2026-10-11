-- Pure counterparts of exclusive_cards-ai.lua. Native receipts authorize every
-- response action; pending strategies retain only names and ordered players.
local function known(value, label)
    if AIUnsupported.is(value) then error(value,0) end
    if value == nil then ai_unsupported("exclusive card requires " .. label,"exclusive_cards") end
    return value
end
local function query(object, method, ...)
    if type(object) ~= "table" or type(object[method]) ~= "function" then
        ai_unsupported("exclusive card requires " .. method,"exclusive_cards")
    end
    return known(object[method](object,...),method)
end
local function same_card(self,a,b)
    if a==b then return true end
    if not a or not b then return false end
    return query(self,"sameLegacyCard",a,b)
end
local function answer(self,skill,costs,targets,name)
    local card=query(self,"bindSkillCard",skill,costs,nil,name)
    local use=AIUsePlan.new();use.card=card
    for _,target in ipairs(targets or {}) do use.to:append(target) end
    return known(use:toAnswer(),"authorized skill response")
end

sgs.weapon_range.Hongduanqiang=3
sgs.weapon_range.Liecuidao=2
sgs.weapon_range.Shuibojian=2
sgs.weapon_range.Hunduwanbi=1
sgs.weapon_range.Piliche=9
sgs.weapon_range.SecondPiliche=9
sgs.ai_skill_invoke._hongduanqiang=function()return true end

sgs.ai_skill_use["@@_liecuidao"]=function(self,prompt)
    local name=prompt:split(":")[2]
    local to=self.room:findPlayerByObjectName(name)
    local cards=query(self,"sortByKeepValue",query(self.player,"getCards","he"))
    for _,card in ipairs(cards) do
        if not same_card(self,card,self.player:getWeapon()) and query(self,"isEnemy",to) then
            return answer(self,"_liecuidao",{query(card,"getEffectiveId")},{})
        end
    end
end

sgs.ai_skill_use["@@_shuibojian"]=function(self)
    local targets=query(self,"sort",query(self.player,"getAliveSiblings"),"hp")
    local use=query(self,"getShuibojianUse")
    local owner_target=false
    for _,target in ipairs(known(use.to,"pending use targets")) do
        if query(target,"objectName")==query(self.player,"objectName") then owner_target=true break end
    end
    for _,target in ipairs(targets) do
        if query(self,"isFriend",target) and owner_target and query(self,"isShuibojianCandidate",target) then
            return answer(self,"_shuibojian",{},{target})
        end
        if query(self,"isEnemy",target) and query(known(use.card,"pending use card"),"isDamageCard")
            and query(self,"isShuibojianCandidate",target) then return answer(self,"_shuibojian",{},{target}) end
        if query(self,"isEnemy",target) and not query(self,"isFriend",use.to[1])
            and query(self,"isShuibojianCandidate",target) then return answer(self,"_shuibojian",{},{target}) end
    end
end

sgs.ai_skill_invoke._hunduwanbi=function(self,data)
    local target=self.room:findPlayerByObjectName(query(data,"toString"):split(":")[2])
    if target then return not query(self,"isFriend",target) end
end
for _,name in ipairs({"_tianleiren","_piliche","_secondpiliche"}) do
    sgs.ai_skill_invoke[name]=function(self,data)
        local target=data:toPlayer()
        if target then return not query(self,"isFriend",target) end
    end
end
sgs.ai_skill_invoke._feilunzhanyu=function(self,data)return not query(self,"isFriend",data:toPlayer())end
sgs.ai_skill_invoke._tiejixuanyu=function(self,data)
    local target=data:toPlayer()
    return query(self,"isEnemy",target) and (query(target,"getHandcardNum")>1 or query(target,"hasEquip"))
end
sgs.ai_skill_invoke._sichengliangyu=function()return true end
sgs.ai_skill_discard._qiongshu=function(self,x,n)
    local hand=query(self,"sortByKeepValue",query(self.player,"getCards","he"))
    if type(sgs.getPlayerSkillList)~="function" then ai_unsupported("public player skill list unavailable","_qiongshu") end
    for _,skill in ipairs(known(sgs.getPlayerSkillList(self.player),"public skill list")) do
        -- The source inspects presence only. An unported callback can still
        -- exist in the donor registry; isolated absence is not known absence.
        if query(self,"hasLegacyCardAsk",query(skill,"objectName")) and not query(self,"isWeak") then return {} end
    end
    local selected={}
    for _,card in ipairs(hand) do
        if #selected>=n then break end
        if query(card,"objectName")~="_qiongshu" then selected[#selected+1]=query(card,"getEffectiveId") end
    end
    return #selected>=n and selected or {}
end
sgs.ai_skill_invoke._qiongshu=function()return true end
sgs.ai_skill_choice._xishu=function(self,choices)
    local items=choices:split("+")
    if table.contains(items,"judge") and query(self,"doDisCard",self.player,"j") then return "judge" end
    if table.contains(items,"discard") then return "discard" end
end
sgs.ai_skill_invoke._bintieshuangji=function(self)return not query(self,"isWeak") and #self.enemies>0 end

sgs.ai_use_revises._zhaogujing=function(self,card)
    local in_hand=false
    for _,held in ipairs(query(self.player,"getHandcards")) do if same_card(self,held,card) then in_hand=true break end end
    if in_hand and query(self,"getOverflow")<1 then
        if query(card,"getTypeId")==1 or query(card,"isNDTrick") then
            if self.toUse~=nil then
                local current=#self.toUse>0 and card
                for _,planned in ipairs(self.toUse) do
                    if query(planned,"getTypeId")==1 or query(planned,"isNDTrick") then current=planned end
                end
                if same_card(self,current,card) then return false end
            else
                local previous=query(self,"getTurnUseSummary")
                if previous.count>0 then
                    -- The source compares userdata, not payment IDs or printed faces.
                    if previous.last==nil then return false end
                    local token=known(previous.last.legacy_identity_token,"previous planned identity")
                    if type(token)~="string" or token=="" then ai_unsupported("previous planned identity malformed","_zhaogujing") end
                    if token==query(card,"getLegacyIdentityToken") then return false end
                end
            end
        end
    end
end
sgs.ai_skill_cardask._zhaogujing0=function(self)
    local cards=query(self,"sortByUseValue",query(self.player,"getHandcards"))
    for _,card in ipairs(cards) do
        if query(card,"isNDTrick") or query(card,"getTypeId")==1 then
            local probe=query(self,"evaluateSkillCard","_zhaogujing",query(card,"objectName"),{})
            if query(probe,"isAvailable",self.player) then
                local use=query(self,"evaluateCard",probe)
                if use.card and not (query(probe,"canRecast") and #use.to==0) then
                    local targets={}
                    for _,target in ipairs(use.to) do targets[#targets+1]=query(target,"objectName") end
                    self._zhaogujingUse=use
                    self:setStrategyMemory("exclusive.zhaogujing_use",{name=query(use.card,"objectName"),targets=targets})
                    return query(card,"getEffectiveId")
                end
            end
        end
    end
    return "."
end
sgs.ai_skill_use["@@_zhaogujing"]=function(self)
    local saved,present=self:getStrategyMemory("exclusive.zhaogujing_use")
    if not present or type(saved)~="table" then ai_unsupported("Zhaogujing has no prior viewer plan","_zhaogujing") end
    local targets={}
    for _,name in ipairs(known(saved.targets,"remembered targets")) do
        targets[#targets+1]=known(self.room:findPlayerByObjectName(name),"remembered target")
    end
    return answer(self,"_zhaogujing",{},targets,known(saved.name,"remembered card"))
end
sgs.ai_ajustdamage_to._taipingyaoshu=function(self,from,to,card,nature)
    if nature~="N" then return -99 end
end
