-- Fixed b6025acc mobile-ai.lua:2154–2159, exact damagehp predicate order.
-- Other mobile callbacks are outside this focused frozen-ID implementation.
local function q(object, method, ...)
    if object == nil then error("attempt to index a nil value", 0) end
    if method == "getMark" and AIValue.isPlayer(object) then method = "getStrategyMark" end
    if type(object[method]) ~= "function" then ai_unsupported("mobile damagehp helper absent", method) end
    local value = object[method](object, ...)
    if AIUnsupported.is(value) then error(value, 0) end
    if value == nil then ai_unsupported("mobile damagehp input is unknown", method) end
    return value
end
sgs.ai_can_damagehp.mobilemouganglie = function(self, from, card, to)
    if from and q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from,to,1,card) > 0
        and q(self,"canLoseHp",from,card,to) then
        return q(self,"isEnemy",from)
            and q(from,"getMark","MobileMouGangLieDamaged"..q(to,"objectName")) == 0
            and q(from,"getMark","MobileMouGangLieDamage"..q(to,"objectName")) == 0
    end
end


-- R49: complete fixed named damage/card-priority callbacks.
do
 local function q(o,k,...)
  if o==nil then error('attempt to index a nil value',0)end
  local f=o[k];if type(f)~='function'then ai_unsupported('Fixed named callback helper unavailable',k)end
  local v=f(o,...);if AIUnsupported.is(v)then error(v,0)end
  if v==nil and not SmartAIView.isKnownNilStrategyResult(o,k,f)then ai_unsupported('Fixed named callback input unknown',k)end
  return v
 end
sgs.ai_can_damagehp.mobilemouzongshi = function(self, from, card, to)
    if from and q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0 and
        q(self,"canLoseHp",from, card, to) then
        return q(self,"isEnemy",from) and q(from,"getMark","mobilemouzongshiUse") < 1 and q(from,"getHandcardNum") > 3
    end
end

sgs.ai_can_damagehp.mobilemoujieming = function(self,from,card,to)
	if q(self,"isFriend",to)
	and q(self,"canLoseHp",from,card,to)
	and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	then
		return q(self,"canDraw",self.player)
	end
end

end
-- End R49 named damage/card-priority callbacks.

-- R49: fixed mobilemouwushuang damage adjustment, mobile-ai.lua2336–2340.
do
 local function q(o,k,...)
  if o==nil then error('attempt to index a nil value',0)end
  local f=o[k];if type(f)~='function'then ai_unsupported('Mobile Wushuang source input unavailable',k)end
  local v=f(o,...);if AIUnsupported.is(v)then error(v,0)end
  if v==nil then ai_unsupported('Mobile Wushuang source input unknown',k)end
  return v
 end
 sgs.ai_ajustdamage_from.mobilemouwushuang=function(self,from,to,card,nature)
  if card and (q(card,'isKindOf','Slash') or (q(card,'isKindOf','Duel') and table.contains(q(q(self.room,'getTag','MobileMouWushuang_'..q(card,'toString')),'toStringList'),q(to,'objectName')))) and not q(card,'hasFlag','mobilemouwushuangUse'..q(to,'objectName'))then
   return 1
  end
 end
end
-- End R49 mobilemouwushuang.
