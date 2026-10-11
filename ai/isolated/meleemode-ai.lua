-- Fixed source: same-clone availability precedes any selected-only payment.
local function q(o,k,...)
    if not o or type(o[k])~='function'then ai_unsupported('melee_peach method unavailable',k)end
    local v=o[k](o,...);if AIUnsupported.is(v)then error(v,0)end
    if v==nil then ai_unsupported('melee_peach value unknown',k)end;return v
end
local function spec(card,name)return{name=name,skill='melee_peach',suit=q(card,'getSuit'),number=q(card,'getNumber'),subcards={q(card,'getEffectiveId')}}end
sgs.ai_fill_skill.melee_peach=function(self,player,request)
    local cards=self:sortByUseValue(sgs.QList2Table(q(self.player,'getCards','h')),true)
    for _,card in ipairs(cards)do
        if q(card,'isKindOf','Peach')then
            local slash=q(self,'evaluateTurnConversion','melee_peach','Slash',spec(card,'slash'),request)
            if q(self,'readonlyTurnAvailability',slash)then return slash end
        end
    end
end
sgs.ai_cardsview.melee_peach=function(self,class_name,player)
    if not q(player,'hasSkill','melee_peach')then return end
    for _,card in sgs.list(q(player,'getCards','h'))do
        if q(card,'isKindOf','Peach')then
            if class_name=='Slash'then return spec(card,'slash')elseif class_name=='Jink'then return spec(card,'jink')end
        end
    end
end
sgs.ai_use_value.MeleeSlashJink=sgs.ai_use_value.Slash
sgs.ai_keep_value.MeleeSlashJink=sgs.ai_keep_value.Slash
