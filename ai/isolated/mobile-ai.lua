-- Fixed b6025acc mobile-ai.lua:2154–2159, exact damagehp predicate order.
-- Other mobile callbacks are outside this focused frozen-ID implementation.

sgs.ai_can_damagehp.mobilemouganglie = function(self, from, card, to)
    if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
        and self:canLoseHp(from, card, to) then
        return self:isEnemy(from)
            and from:getStrategyMark("MobileMouGangLieDamaged"..to:objectName()) == 0
            and from:getStrategyMark("MobileMouGangLieDamage"..to:objectName()) == 0
    end
end


-- R49: complete fixed named damage/card-priority callbacks.
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
-- End R49 named damage/card-priority callbacks.

-- R49: fixed mobilemouwushuang damage adjustment, mobile-ai.lua2336–2340.
do

 sgs.ai_ajustdamage_from.mobilemouwushuang=function(self,from,to,card,nature)
  if card and (card:isKindOf('Slash') or (card:isKindOf('Duel') and table.contains((self.room:getTag('MobileMouWushuang_'..card:toString())):toStringList(),to:objectName()))) and not card:hasFlag('mobilemouwushuangUse'..to:objectName())then
   return 1
  end
 end
end
-- End R49 mobilemouwushuang.
