-- Necessary fixed-source slice: sijyu-ai.lua:537-541 (b6025acc).
-- Other package callbacks are not claimed by this slice.
sgs.ai_ajustdamage_from.sijyu_xiaowang = function(self, from, to, card, nature)
    if nature ~= sgs.DamageStruct_Fire then
        return 1
    end
end

-- R47b complete fixed Xuanmeng / Zhanshi / Zuotai AI family (sijyu311–359).
do
 local function call(o,k,...)
  local f=o and o[k]
  if type(f)~='function'then ai_unsupported('Sijyu source method unavailable',k)end
  local values=table.pack(f(o,...))
  for i=1,values.n do if AIUnsupported.is(values[i])then error(values[i],0)end end
  if values[1]==nil and not SmartAIView.isKnownNilStrategyResult(o,k,f)then
   ai_unsupported('Sijyu source input unknown',k)
  end
  return table.unpack(values,1,values.n)
 end
 local function sort_source(self,k,cards,...)
  local f=self[k];if type(f)~='function'then ai_unsupported('Sijyu sorter unavailable',k)end
  local result=f(self,cards,...);if AIUnsupported.is(result)then error(result,0)end
  if result~=nil and result~=cards then
   if not AIValue.isList(result)then ai_unsupported('Sijyu sorted-copy malformed',k)end
   for i=#cards,1,-1 do cards[i]=nil end
   for i,v in ipairs(result)do cards[i]=v end
  end
 end
 sgs.ai_skill_invoke.sijyu_xuanmeng=true
 sgs.ai_skill_use['@@sijyu_xuanmeng']=function(self,prompt,method)
  -- The fixed source returns its sole zero-cost Lua SkillCard immediately;
  -- selecting this answer is the first authority boundary, not a simulation.
  local card=call(self,'bindSkillCard','sijyu_xuanmeng',{},nil,nil,'#sijyu_xuanmeng')
  local plan=AIUsePlan.new();plan.card=card;return plan:toAnswer()
 end
 sgs.ai_skill_choice.sijyu_xuanmeng=function(self,choices,data)
  local items=choices:split('+')
  local cards=sgs.QList2Table(call(self.player,'getCards','h'))
  for _,card in ipairs(cards)do
   if table.contains(items,call(card,'objectName'))then return call(card,'objectName')end
  end
  return items[1]
 end
 sgs.ai_skill_cardask['@sijyu_zhanshi']=function(self,data,pattern,target)
  if target and call(self,'isEnemy',target) and call(self,'damageIsEffective',target)
   and not call(self,'cantbeHurt',target)then
   local cards=sgs.QList2Table(call(self.player,'getCards','h'))
   local patterns=pattern:split(',')
   sort_source(self,'sortByKeepValue',cards)
   for _,card in ipairs(cards)do
    for _,name in ipairs(patterns)do
     if call(card,'getClassName')==name then return call(card,'toString')end
    end
   end
  end
  return '.'
 end
 sgs.ai_playerchosen_intention.sijyu_zuotai=-80
 sgs.ai_skill_playerchosen.sijyu_zuotai=function(self,targets)
  targets=sgs.QList2Table(targets)
  if call(self,'canDraw',self.player)and table.contains(targets,self.player)then return self.player end
  if not AIValue.isList(self.friends_noself)then ai_unsupported('Sijyu friends list unknown','sijyu_zuotai')end
  sort_source(self,'sort',self.friends_noself,'defense')
  self.friends_noself=sgs.reverse(self.friends_noself)
  for _,friend in ipairs(self.friends_noself)do
   if not call(self,'canDraw',friend)then continue end
   if (call(friend,'getHandcardNum')+(call(friend,'isWounded')and -2 or 1))<call(self.player,'getHandcardNum')
    and table.contains(targets,friend)then return friend end
  end
  return nil
 end
end

-- R47c complete fixed Sijyu Lijian family (source548–571).
do
 local function call(o,k,...)
  local f=o and o[k]
  if type(f)~='function'then ai_unsupported('Sijyu Lijian method unavailable',k)end
  local v=table.pack(f(o,...))
  for i=1,v.n do if AIUnsupported.is(v[i])then error(v[i],0)end end
  if v[1]==nil and not SmartAIView.isKnownNilStrategyResult(o,k,f)then
   ai_unsupported('Sijyu Lijian input unknown',k)
  end
  return table.unpack(v,1,v.n)
 end
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
 local function sort_keep(self,cards)
  local f=self.sortByKeepValue
  if type(f)~='function'then ai_unsupported('Sijyu Lijian sorter missing','sortByKeepValue')end
  local sorted=f(self,cards)
  if AIUnsupported.is(sorted)then error(sorted,0)end
  if sorted~=nil and sorted~=cards then
   if not AIValue.isList(sorted)then ai_unsupported('Sijyu Lijian sorted-copy malformed','sortByKeepValue')end
   for i=#cards,1,-1 do cards[i]=nil end
   for i,v in ipairs(sorted)do cards[i]=v end
  end
 end
 sgs.ai_skill_invoke.sijyu_lijian=function(self,data)
  local damage=data:toDamage()
  if not call(self,'isFriend',damage.to)then return true end
  return false
 end
 sgs.ai_skill_discard.sijyu_lijian=function(self,discard_num,min_num,optional,include_equip)
  local cards=sgs.QList2Table(call(self.player,'getCards','he'))
  local damage=current_damage(self)
  if damage then
   if not call(self,'needToLoseHp',self.player,damage.from,damage.card)then
    sort_keep(self,cards)
    local out={}
    for _,card in ipairs(cards)do
     if #out<discard_num and not call(card,'isKindOf','Peach')then out[#out+1]=call(card,'getEffectiveId')end
    end
    if #out>0 and #out==discard_num then return out end
   end
  end
  return{}
 end
end


-- R47d: fixed full Qixing/Fengyi bodies, sijyu-ai.lua641–737.
do
 local draw_provider=SmartAIView.findPlayerToDraw
 local function call(o,k,...)
  local f=o and o[k];if type(f)~='function'then ai_unsupported('Sijyu Qixing/Fengyi helper unavailable',k)end
  local v=table.pack(f(o,...));for i=1,v.n do if AIUnsupported.is(v[i])then error(v[i],0)end end
  if v[1]==nil and not (k=='findPlayerToDraw' and f==draw_provider) and not SmartAIView.isKnownNilStrategyResult(o,k,f)then ai_unsupported('Sijyu Qixing/Fengyi input unknown',k)end
  return table.unpack(v,1,v.n)
 end
 local function source_sort(self,cards,...)
  local provider=self.sort
  if type(provider)~='function'then ai_unsupported('Sijyu player sort unavailable','sort')end
  local sorted=provider(self,cards,...)
  if AIUnsupported.is(sorted)then error(sorted,0)end
  if sorted==nil then ai_unsupported('Sijyu player sort input unknown','sort')end
  if sorted~=nil and sorted~=cards then
   if not AIValue.isList(sorted)then ai_unsupported('Sijyu player ordering malformed','sort')end
   for i=#cards,1,-1 do cards[i]=nil end;for i,p in ipairs(sorted)do cards[i]=p end
  end
 end
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
  local cards=sgs.QList2Table(call(self.player,'getHandcards'))
  local to_discard={}
  local compare_func=function(a,b)return call(self,'getUseValue',a)<call(self,'getUseValue',b)end
  table.sort(cards,compare_func)
  for _,card in sgs.list(cards)do
   if #to_discard>=discard_num then break end
   table.insert(to_discard,call(card,'getId'))
  end
  return to_discard
 end
 sgs.ai_skill_playerchosen.sijyu_qixing=function(self,targets)return self.player end
 sgs.ai_skill_cardask['@sijyu_fengyi-card']=function(self,data)
  local judge=call(data,'toJudge')
  if call(self.room,'getMode'):find('_mini_46') and not call(judge,'isGood')then
   -- Preserve the source's first() and concatenation error before authority.
   local wire='$'..call(self.player,'handCards'):first()
   return selected(self,tonumber(wire:sub(2)))
  end
  local ids=call(self.player,'getPile','sijyu_xing')
  if call(self,'needRetrial',judge)then
   local cards={}
   for _,id in sgs.qlist(ids)do table.insert(cards,call(self,'getKnownCardById',id))end
   local card_id=call(self,'getRetrialCardId',cards,judge)
   if card_id~=-1 then return selected(self,card_id)end
  end
  return '.'
 end
 -- Fixed native Death producer is unreachable; retain the full source body,
 -- never manufacture that question or reconnect it under an alias.
 sgs.ai_skill_playerchosen.sijyu_fengyi=function(self,targets)
  source_sort(self,self.friends_noself,'handcard')
  local target=nil
  local n=call(self.player,'getPile','sijyu_xing'):length()
  for _,friend in ipairs(self.friends_noself)do
   if not call(friend,'faceUp')then target=friend;break end
   if not target then if not call(self,'toTurnOver',friend,n,'sijyu_fengyi')then target=friend;break end end
  end
  if not target then
   if n>=3 then
    target=call(self,'findPlayerToDraw',false,n)
    if not target then
     for _,enemy in ipairs(self.enemies)do
      if call(self,'toTurnOver',enemy,n,'sijyu_fengyi') and manjuan(enemy)then target=enemy;break end
     end
    end
   else
    source_sort(self,self.enemies)
    for _,enemy in ipairs(self.enemies)do
     if call(self,'toTurnOver',enemy,n,'sijyu_fengyi') and manjuan(enemy)then target=enemy;break end
    end
    if not target then
     for _,enemy in ipairs(self.enemies)do
      if call(self,'toTurnOver',enemy,n,'sijyu_fengyi') and call(self,'hasSkills',sgs.priority_skill,enemy)then target=enemy;break end
     end
    end
    if not target then
     for _,enemy in ipairs(self.enemies)do if call(self,'toTurnOver',enemy,n,'sijyu_fengyi')then target=enemy;break end end
    end
   end
  end
  return target
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
sgs.ai_can_damagehp.sijyu_tuodao = function(self, from, card, to)
    if from and q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0
        and q(self,"canLoseHp",from, card, to) and q(self,"getCardsNum","Slash") > 1
    then
        return q(self,"isEnemy",from) and not q(from,"isKongcheng") and
            ((not q(self,"isWeak") and q(self,"canAttack",from)) or q(self,"isWeak",from))
    end
end

sgs.ai_card_priority.sijyu_youlong = function(self, card)
    if table.contains(q(card,"getSkillNames"), "sijyu_youlong")
    then
        return 1
    end
end

sgs.ai_can_damagehp.sijyu_kehou = function(self, from, card, to)
    if from and q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) > 0
        and q(self,"canLoseHp",from, card, to)
    then
        return q(to,"getMark","&sijyu_kehou-Clear") == 0 and ((q(to,"getHp") - q(to,"getHandcardNum") > 2) or q(to,"isKongcheng"))
    end
end

end
-- End R49 named damage/card-priority callbacks.

-- Fixed sijyu-ai.lua300–309: conditions keep their source order. The last
-- registry truthiness check and addition happen together in the actual VM.
sgs.ai_use_revises.sijyu_qizhan=function(self,card,use)
 local function q(o,k,...)
  if not o or type(o[k])~='function'then ai_unsupported('qizhan source method missing',k)end
  local v=o[k](o,...);if AIUnsupported.is(v)then error(v,0)end
  if v==nil or(k=='hasSkills'and v==false and o:areSkillsComplete()~=true)then ai_unsupported('qizhan source input unknown',k)end;return v
 end
 if card and q(card,'getClassName')and
  ((not q(card,'isVirtualCard')and(q(self.player,'getMark','&sijyu_youlong-Clear')>0 or q(self.player,'getMark','&sijyu_kehou-Clear')>0))
   or(q(self.player,'hasSkills','sijyu_youlong')and(table.contains(q(card,'getSkillNames'),'sijyu_youlong')and(q(self.player,'getMark','&sijyu_youlong-Clear')==0 or q(self.player,'getMark','&sijyu_kehou-Clear')==0))))then
  self:incrementNamedSourcePriority('sijyu_qizhan',card,q(card,'getClassName'))
 end
end
