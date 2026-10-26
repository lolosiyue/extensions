-- Fixed test package noslonghun; do not confuse this source with later variants.

local function spec(card,name,id)return{name=name,skill='noslonghun',suit=card:getSuit(),number=card:getNumber(),subcards={id}}end
ai_fill_skill.noslonghun=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getHp()>1 then return end
    local cards=self:sortByUseValue(self:addHandPile('he'),true)
    for _,card in ipairs(cards)do
        if card:getSuit()==sgs.Card_Diamond then
            return self:evaluateTurnConversion('noslonghun', 'FireSlash', spec(card,'fire_slash',card:getKnownId()), request)
        end
    end
end
sgs.ai_view_as.noslonghun=function(card,player,card_place)
    local suit=card:getSuitString();local number=card:getNumberString();local id=card:getKnownEffectiveId()
    if player:getHp()>1 or card_place==sgs.Player_PlaceSpecial then return end
    if card:getSuit()==sgs.Card_Diamond then return spec(card,'fire_slash',id)
    elseif card:getSuit()==sgs.Card_Club then return spec(card,'jink',id)
    elseif card:getSuit()==sgs.Card_Heart then return spec(card,'peach',id)
    elseif card:getSuit()==sgs.Card_Spade then return spec(card,'nullification',id)end
end
sgs.noslonghun_suit_value={heart=6.7,spade=5,club=4.2,diamond=3.9}
