-- Existing source default; the package may replace it below.
if sgs.ai_ajustdamage_from.sijyu_zhuluan == nil then
    sgs.ai_ajustdamage_from.sijyu_zhuluan = function(self,from,to,card,nature)
        local damage_call, helpers = self:getDamageValueContext()
        if card and table.contains(self:cardSkillNamesKnowledge(card,"sijyu_zhuluan.skill_names"),"sijyu_zhuluan")
            and from and damage_call(from,"getMark","zhuluandamage_lun")==0 then return 1 end
    end
end

-- Source: b6025acc ai/sijyu-ai.lua.
sgs.ai_ajustdamage_from.sijyu_xiaowang = function(self, from, to, card, nature)
    if nature ~= sgs.DamageStruct_Fire then
        return 1
    end
end

do

 ai_skill_invoke.sijyu_xuanmeng=true
 ai_skill_use['@@sijyu_xuanmeng']=function(self, prompt, request)
  -- The fixed source returns its sole zero-cost Lua SkillCard immediately;
  -- selecting this answer is the first authority boundary, not a simulation.
  local method = request and request.handling_method
  local card=self:bindSkillCard('sijyu_xuanmeng',{},nil,nil,'#sijyu_xuanmeng')
  local plan=AIUsePlan.new();plan.card=card;return plan:toAnswer()
 end
 ai_skill_choice.sijyu_xuanmeng=function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

  local items=choices:split('+')
  local cards=sgs.QList2Table(self.player:getCards('h'))
  for _,card in ipairs(cards)do
   if table.contains(items,card:objectName())then return ai_choice_result((card:objectName()), options)end
  end
  return ai_choice_result((items[1]), options)
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
 ai_skill_invoke.sijyu_lijian=function(self, options, request)
  local data = request and self:getDecisionData(request) or nil
  local damage=data:toDamage()
  if not self:isFriend(damage.to)then return (true) or false end
  return (false) or false
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

-- Fixed sijyu-ai.lua300–309: conditions keep their source order. The last
-- registry truthiness check and addition happen together in the actual VM.
sgs.ai_use_revises.sijyu_qizhan=function(self,card,use)

 if card and card:getClassName()and
  ((not card:isVirtualCard()and(self.player:getMark('&sijyu_youlong-Clear')>0 or self.player:getMark('&sijyu_kehou-Clear')>0))
   or(self.player:hasSkills('sijyu_youlong')and(table.contains(card:getSkillNames(),'sijyu_youlong')and(self.player:getMark('&sijyu_youlong-Clear')==0 or self.player:getMark('&sijyu_kehou-Clear')==0))))then
  self:incrementNamedSourcePriority('sijyu_qizhan',card,card:getClassName())
 end
end

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
end)()
