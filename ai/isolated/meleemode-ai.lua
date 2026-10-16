-- Fixed source: same-clone availability precedes any selected-only payment.

local function spec(card,name)return{name=name,skill='melee_peach',suit=card:getSuit(),number=card:getNumber(),subcards={card:getKnownEffectiveId()}}end
sgs.ai_fill_skill.melee_peach=function(self,player,request)
    local cards=self:sortByUseValue(sgs.QList2Table(self.player:getCards('h')),true)
    for _,card in ipairs(cards)do
        if card:isKindOf('Peach')then
            local slash=self:evaluateTurnConversion('melee_peach', 'Slash', spec(card,'slash'), request)
            if self:readonlyTurnAvailability(slash)then return slash end
        end
    end
end
sgs.ai_cardsview.melee_peach=function(self,class_name,player)
    if not player:hasSkill('melee_peach')then return end
    for _,card in sgs.list(player:getCards('h'))do
        if card:isKindOf('Peach')then
            if class_name=='Slash'then return spec(card,'slash')elseif class_name=='Jink'then return spec(card,'jink')end
        end
    end
end
sgs.ai_use_value.MeleeSlashJink=sgs.ai_use_value.Slash
sgs.ai_keep_value.MeleeSlashJink=sgs.ai_keep_value.Slash
