-- Fixed test package noslonghun; do not confuse this source with later variants.
local function q(o,k,...)
    if not o or type(o[k])~='function'then ai_unsupported('noslonghun method unavailable',k)end
    local v=o[k](o,...);if AIUnsupported.is(v)then error(v,0)end
    if v==nil then ai_unsupported('noslonghun value unknown',k)end;return v
end
local function spec(card,name,id)return{name=name,skill='noslonghun',suit=q(card,'getSuit'),number=q(card,'getNumber'),subcards={id}}end
sgs.ai_fill_skill.noslonghun=function(self,inclusive,request)
    if q(self.player,'getHp')>1 then return end
    local cards=self:sortByUseValue(q(self,'addHandPile','he'),true)
    for _,card in ipairs(cards)do
        if q(card,'getSuit')==sgs.Card_Diamond then
            return q(self,'evaluateTurnConversion','noslonghun','FireSlash',spec(card,'fire_slash',q(card,'getId')),request)
        end
    end
end
sgs.ai_view_as.noslonghun=function(card,player,card_place)
    local suit=q(card,'getSuitString');local number=q(card,'getNumberString');local id=q(card,'getEffectiveId')
    if q(player,'getHp')>1 or card_place==sgs.Player_PlaceSpecial then return end
    if q(card,'getSuit')==sgs.Card_Diamond then return spec(card,'fire_slash',id)
    elseif q(card,'getSuit')==sgs.Card_Club then return spec(card,'jink',id)
    elseif q(card,'getSuit')==sgs.Card_Heart then return spec(card,'peach',id)
    elseif q(card,'getSuit')==sgs.Card_Spade then return spec(card,'nullification',id)end
end
sgs.noslonghun_suit_value={heart=6.7,spade=5,club=4.2,diamond=3.9}
