-- Existing source default; the package may replace it below.
if sgs.ai_ajustdamage_to.mobilemoujinjiu == nil then
    sgs.ai_ajustdamage_to.mobilemoujinjiu = function(self,from,to,card,nature)
        local damage_call, helpers = self:getDamageValueContext()
        local damage_card_flag = helpers.card_flag
        local damage_card_value = helpers.card_value
        if card and card:isKindOf("Slash") and damage_card_flag(self,card,"drank") then
            return -damage_card_value(self,card,"drank_amount",0)
        end
    end
end

-- Source: b6025acc ai/mobile-ai.lua.

sgs.ai_can_damagehp.mobilemouganglie = function(self, from, card, to)
    if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
        and self:canLoseHp(from, card, to) then
        return self:isEnemy(from)
            and from:getStrategyMark("MobileMouGangLieDamaged"..to:objectName()) == 0
            and from:getStrategyMark("MobileMouGangLieDamage"..to:objectName()) == 0
    end
end


do

sgs.ai_can_damagehp.mobilemouzongshi = function(self, from, card, to)
    if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0 and
        self:canLoseHp(from, card, to) then
        return self:isEnemy(from) and from:getMark("mobilemouzongshiUse") < 1 and from:getHandcardNum() > 3
    end
end

sgs.ai_can_damagehp.mobilemoujieming = function(self,from,card,to)
	if self:isFriend(to)
	and self:canLoseHp(from, card, to)
	and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	then
		return self:canDraw(self.player)
	end
end

end

do

 sgs.ai_ajustdamage_from.mobilemouwushuang=function(self,from,to,card,nature)
  if card and (card:isKindOf('Slash') or (card:isKindOf('Duel') and table.contains((self.room:getTag('MobileMouWushuang_'..card:toString())):toStringList(),to:objectName()))) and not card:hasFlag('mobilemouwushuangUse'..to:objectName())then
   return 1
  end
 end
end

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
end)()
