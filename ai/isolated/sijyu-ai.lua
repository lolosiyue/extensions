-- Necessary fixed-source slice: sijyu-ai.lua:537-541 (b6025acc).
-- Other package callbacks are not claimed by this slice.
sgs.ai_ajustdamage_from.sijyu_xiaowang = function(self, from, to, card, nature)
    if nature ~= sgs.DamageStruct_Fire then
        return 1
    end
end

-- R47b complete fixed Xuanmeng / Zhanshi / Zuotai AI family (sijyu311–359).
do

 sgs.ai_skill_invoke.sijyu_xuanmeng=true
 sgs.ai_skill_use['@@sijyu_xuanmeng']=function(self,prompt,method)
  -- The fixed source returns its sole zero-cost Lua SkillCard immediately;
  -- selecting this answer is the first authority boundary, not a simulation.
  local card=self:bindSkillCard('sijyu_xuanmeng',{},nil,nil,'#sijyu_xuanmeng')
  local plan=AIUsePlan.new();plan.card=card;return plan:toAnswer()
 end
 sgs.ai_skill_choice.sijyu_xuanmeng=function(self,choices,data)
  local items=choices:split('+')
  local cards=sgs.QList2Table(self.player:getCards('h'))
  for _,card in ipairs(cards)do
   if table.contains(items,card:objectName())then return card:objectName()end
  end
  return items[1]
 end
 sgs.ai_skill_cardask['@sijyu_zhanshi']=function(self,data,pattern,target)
  if target and self:isEnemy(target) and self:damageIsEffective(target)
   and not self:cantbeHurt(target)then
   local cards=sgs.QList2Table(self.player:getCards('h'))
   local patterns=pattern:split(',')
   self:sortByKeepValueInPlace(cards)
   for _,card in ipairs(cards)do
    for _,name in ipairs(patterns)do
     if card:getClassName()==name then return card:toString()end
    end
   end
  end
  return '.'
 end
 sgs.ai_playerchosen_intention.sijyu_zuotai=-80
 sgs.ai_skill_playerchosen.sijyu_zuotai=function(self,targets)
  targets=sgs.QList2Table(targets)
  if self:canDraw(self.player)and table.contains(targets,self.player)then return self.player end
  if not AIValue.isList(self.friends_noself)then ai_unsupported('Sijyu friends list unknown','sijyu_zuotai')end
  self:sortInPlace(self.friends_noself, 'defense')
  self.friends_noself=sgs.reverse(self.friends_noself)
  for _,friend in ipairs(self.friends_noself)do
   if not self:canDraw(friend)then continue end
   if (friend:getHandcardNum()+(friend:isWounded()and -2 or 1))<self.player:getHandcardNum()
    and table.contains(targets,friend)then return friend end
  end
  return nil
 end
end

-- R47c complete fixed Sijyu Lijian family (source548–571).
do

 local function current_damage(self)
  -- The raw question context carries CurrentDamageStruct only for invoke/choice/
  -- response asks, so an absent row is unknown here, not an absent tag.
  local options=self.request and self.request.options
  local row=type(options)=='table'and type(options.context)=='table'and options.context.damage
  if type(row)~='table'then ai_unsupported('CurrentDamageStruct is not projected','sijyu_lijian')end
  local damage={}
  local name=row.from
  if name~=false and name~=''then
   if type(name)~='string'then ai_unsupported('CurrentDamageStruct.from unknown','sijyu_lijian')end
   damage.from=self.room:findPlayerByObjectName(name,true)
   if not damage.from then ai_unsupported('CurrentDamageStruct.from unavailable','sijyu_lijian')end
  end
  if row.card~=nil and row.card~=false then
   if type(row.card)~='table'then ai_unsupported('CurrentDamageStruct.card malformed','sijyu_lijian')end
   if next(row.card)~=nil then damage.card=CardView.new(row.card)end
  end
  return damage
 end
 sgs.ai_skill_invoke.sijyu_lijian=function(self,data)
  local damage=data:toDamage()
  if not self:isFriend(damage.to)then return true end
  return false
 end
 sgs.ai_skill_discard.sijyu_lijian=function(self,discard_num,min_num,optional,include_equip)
  local cards=sgs.QList2Table(self.player:getCards('he'))
  local damage=current_damage(self)
  if damage then
   if not self:needToLoseHp(self.player,damage.from,damage.card)then
    self:sortByKeepValueInPlace(cards)
    local out={}
    for _,card in ipairs(cards)do
     if #out<discard_num and not card:isKindOf('Peach')then out[#out+1]=card:getEffectiveId()end
    end
    if #out>0 and #out==discard_num then return out end
   end
  end
  return{}
 end
end


-- R47d: fixed full Qixing/Fengyi bodies, sijyu-ai.lua641–737.
do

 local function manjuan(player)
  if type(hasManjuanEffect)~='function'then ai_unsupported('Sijyu global Manjuan helper unavailable','hasManjuanEffect')end
  local v=hasManjuanEffect(player)
  if AIUnsupported.is(v)then error(v,0)end
  if v==nil then ai_unsupported('Sijyu global Manjuan input unknown','hasManjuanEffect')end
  return v
 end
 local function selected(self,id)
  if type(id)~='number'or id%1~=0 or id<0 then ai_unsupported('Fengyi physical source answer unavailable','sijyu_fengyi')end
  -- The authority admits the selected physical card when it applies the answer.
  return{kind='answer',cards={id}}
 end
 sgs.ai_skill_discard.sijyu_qixing=function(self,discard_num,optional,include_equip)
  local cards=sgs.QList2Table(self.player:getHandcards())
  local to_discard={}
  local compare_func=function(a,b)return self:getUseValue(a)<self:getUseValue(b)end
  table.sort(cards,compare_func)
  for _,card in sgs.list(cards)do
   if #to_discard>=discard_num then break end
   table.insert(to_discard,card:getId())
  end
  return to_discard
 end
 sgs.ai_skill_playerchosen.sijyu_qixing=function(self,targets)return self.player end
 sgs.ai_skill_cardask['@sijyu_fengyi-card']=function(self,data)
  local judge=data:toJudge()
  if self.room:getMode():find('_mini_46') and not judge:isGood()then
   -- Preserve the source's first() and concatenation error before authority.
   local wire='$'..self.player:handCards():first()
   return selected(self,tonumber(wire:sub(2)))
  end
  local ids=self.player:getPile('sijyu_xing')
  if self:needRetrial(judge)then
   local cards={}
   for _,id in sgs.qlist(ids)do table.insert(cards,self:getKnownCardById(id))end
   local card_id=self:getRetrialCardId(cards,judge)
   if card_id~=-1 then return selected(self,card_id)end
  end
  return '.'
 end
 -- Fixed native Death producer is unreachable; retain the full source body,
 -- never manufacture that question or reconnect it under an alias.
 sgs.ai_skill_playerchosen.sijyu_fengyi=function(self,targets)
  self:sortInPlace(self.friends_noself, 'handcard')
  local target=nil
  local n=self.player:getPile('sijyu_xing'):length()
  for _,friend in ipairs(self.friends_noself)do
   if not friend:faceUp()then target=friend;break end
   if not target then if not self:toTurnOver(friend,n,'sijyu_fengyi')then target=friend;break end end
  end
  if not target then
   if n>=3 then
    target=self:findPlayerToDraw(false,n)
    if not target then
     for _,enemy in ipairs(self.enemies)do
      if self:toTurnOver(enemy,n,'sijyu_fengyi') and manjuan(enemy)then target=enemy;break end
     end
    end
   else
    self:sortInPlace(self.enemies)
    for _,enemy in ipairs(self.enemies)do
     if self:toTurnOver(enemy,n,'sijyu_fengyi') and manjuan(enemy)then target=enemy;break end
    end
    if not target then
     for _,enemy in ipairs(self.enemies)do
      if self:toTurnOver(enemy,n,'sijyu_fengyi') and self:hasSkills(sgs.priority_skill,enemy)then target=enemy;break end
     end
    end
    if not target then
     for _,enemy in ipairs(self.enemies)do if self:toTurnOver(enemy,n,'sijyu_fengyi')then target=enemy;break end end
    end
   end
  end
  return target
 end
end


-- R49: complete fixed named damage/card-priority callbacks.
do

sgs.ai_can_damagehp.sijyu_tuodao = function(self, from, card, to)
    if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from,to,1,card) > 0
        and self:canLoseHp(from,card,to) and self:getCardsNum("Slash") > 1
    then
        return self:isEnemy(from) and not from:isKongcheng() and
            ((not self:isWeak() and self:canAttack(from)) or self:isWeak(from))
    end
end

sgs.ai_card_priority.sijyu_youlong = function(self, card)
    if table.contains(card:getSkillNames(), "sijyu_youlong")
    then
        return 1
    end
end

sgs.ai_can_damagehp.sijyu_kehou = function(self, from, card, to)
    if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from,to,1,card) > 0
        and self:canLoseHp(from,card,to)
    then
        return to:getMark("&sijyu_kehou-Clear") == 0 and ((to:getHp() - to:getHandcardNum() > 2) or to:isKongcheng())
    end
end

end
-- End R49 named damage/card-priority callbacks.

-- Fixed sijyu-ai.lua300–309: conditions keep their source order. The last
-- registry truthiness check and addition happen together in the actual VM.
sgs.ai_use_revises.sijyu_qizhan=function(self,card,use)

 if card and card:getClassName()and
  ((not card:isVirtualCard()and(self.player:getMark('&sijyu_youlong-Clear')>0 or self.player:getMark('&sijyu_kehou-Clear')>0))
   or(self.player:hasSkills('sijyu_youlong')and(table.contains(card:getSkillNames(),'sijyu_youlong')and(self.player:getMark('&sijyu_youlong-Clear')==0 or self.player:getMark('&sijyu_kehou-Clear')==0))))then
  self:incrementNamedSourcePriority('sijyu_qizhan',card,card:getClassName())
 end
end
