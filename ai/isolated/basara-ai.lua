-- Source: b6025acc ai/basara-ai.lua.
local need = AIValue.requireKnown
local query = AIValue.bindQuery {
    missing = function(method) ai_unsupported('basara method unavailable', method) end,
    known = need,
}

local function player(self,name)
    if name==false or name==nil then return nil end
    return need(self.room:findPlayerByObjectName(name,true),'event player')
end
local function has(row,names)
    local skills=need(row.skills,'owner printed general skills')
    for name in names:gmatch('[^|]+')do for _,skill in ipairs(skills)do if name==skill then return true end end end
    return false
end
local function show(self,row)
    local generals=need(row.generals,'owner temporary generals')
    local event=need(row.trigger_event,'triggerEvent')
    if event=='DamageInflicted'then
        local damage=need(row.damage,'triggerEventData')
        for _,general in ipairs(generals)do
            if damage~=false and has(general,sgs.masochism_skill..'|zhichi|zhiyu|fenyong')
                and not self:isFriend(player(self,damage.from),player(self,damage.to))then return 'yes'end
            if damage~=false and need(damage.amount,'damage amount')>query(self.player,'getHp')+self:getAllPeachNum()then return'yes'end
        end
    elseif event=='CardEffected'then
        local effect=need(row.effect,'triggerEventData')
        for _,general in ipairs(generals)do
            if effect==false then error('attempt to index a nil value',0)end
            if need(general.effect_prohibited,'temporary general prohibit')and self:isEnemy(player(self,effect.from),player(self,effect.to))then return'yes'end
            local card=CardView.new(need(effect.card,'effect card'))
            if has(general,'xiangle')and query(card,'isKindOf','Slash')then return'yes'end
            if has(general,'jiang')and((query(card,'isKindOf','Slash')and query(card,'isRed'))or query(card,'isKindOf','Duel'))then return'yes'end
            if has(general,'tuntian')then return'yes'end
        end
    end
    if query(self.room,'alivePlayerCount')<=3 then return'yes'end
    if sgs.getValue(self.player)<6 then return'no'end
    local skills='bazhen|yizhong|zaiqi|feiying|buqu|kuanggu|kofkuanggu|guanxing|luoshen|tuxi|nostuxi|zhiheng|qiaobian|longdan|liuli|longhun|shelie|luoying|anxian|yicong|wushuang|jueqing|niepan'
    for _,general in ipairs(generals)do if has(general,skills)then return'yes'end end
    if self.player:getDefensiveHorse()and self.player:getArmor()and not self:isWeak()then return'yes'end
end
ai_skill_choice.RevealGeneral=function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    -- Ordinary RevealGeneral outside a trigger: no hegemony variant, no queued generals.
    local tagged=self.player:getTag("roles")~=nil or self.player:getTag("triggerEvent")~=nil
        or self.player:getTag("triggerEventData")~=nil
    local row=need(not tagged and {hegemony_variant=self.world.enable_hegemony==true,
        trigger_event="other",generals={}} or nil,'basara')
    if need(row.hegemony_variant,'load-time RevealGeneral variant')~=false then
        ai_unsupported('alternate legacy hegemony model is not this effective callback','RevealGeneral')
    end
    if show(self,row)=='yes'then returnai_choice_result(('yes'), options)end
    local anjiang=0
    for _,other in sgs.qlist(self.room:getOtherPlayers(self.player))do
        if query(other,'getGeneralName')=='anjiang'then anjiang=anjiang+1 end
    end
    if math.random()>(anjiang+1)/(query(self.room,'alivePlayerCount')+1)then returnai_choice_result(('yes'), options)else returnai_choice_result(('no'), options)end

    return ai_choice_result(nil, options)
end
