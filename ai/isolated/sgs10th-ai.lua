local PACKAGE="sgs10th"
local SELECTORS={["#ny_10th_xianshu"]="ny_10th_xianshu",["#ny_10th_jieling"]="ny_10th_jieling",["#ny_10th_chiying"]="ny_10th_chiying",["#ny_10th_changqu"]="ny_10th_changqu",["#ny_10th_humei"]="ny_10th_humei",["#ny_10th_moyu"]="ny_10th_moyu",["#ny_pandi_tenth"]="ny_pandi_tenth",["#ny_pandi_tenth_use"]="ny_pandi_tenth",["#ny_tenth_porui"]="ny_tenth_porui",["#ny_10th_jianguo"]="ny_10th_jianguo",["#ny_10th_chongxu"]="ny_10th_chongxu",["#ny_10th_jiuxian"]="ny_10th_jiuxian",["#ny_tenth_jianzheng"]="ny_tenth_jianzheng",["#ny_tenth_jianzheng_use"]="ny_tenth_jianzheng",["#ny_tenth_dagongche_slash"]="ny_tenth_dagongche_slash",["#ny_10th_paiyi"]="ny_10th_paiyi",["#ny_10th_jingdianzhiheng"]="ny_10th_jingdianzhiheng",["#ny_tenth_jingdianrende"]="ny_tenth_jingdianrende",["#ny_tenth_jingdianrende_basic"]="ny_tenth_jingdianrende_basic",["#ny_10th_lvecheng"]="ny_10th_lvecheng",["#ny_tenth_fuxue"]="ny_tenth_fuxue",["#ny_10th_shoutan"]="ny_10th_shoutan",["#ny_10th_jijiao"]="ny_10th_jijiao",["#ny_tenth_shujian"]="ny_tenth_shujian",["#ny_tenth_longsong"]="ny_tenth_longsong",["#ny_tenth_shizong_give"]="ny_tenth_shizong",["#ny_10th_beini"]="ny_10th_beini",["#ny_tenth_huahuo"]="ny_tenth_huahuo",["#ny_tenth_xiaoyin_buff"]="ny_tenth_xiaoyin",["#ny_tenth_xiaoyin"]="ny_tenth_xiaoyin",["#ny_10th_xinyou"]="ny_10th_xinyou",["#ny_10th_zigu"]="ny_10th_zigu",["#ny_tenth_shuangbi"]="ny_tenth_shuangbi",["#ny_tenth_shuangbi_card"]="ny_tenth_shuangbi_card",["#ny_10th_qiongying"]="ny_10th_qiongying",["#ny_10th_tongwei"]="ny_10th_tongwei",["#ny_tenth_fengying"]="ny_tenth_fengying",["#ny_tenth_wencan"]="ny_tenth_wencan",["#ny_tenth_wencanDisCard"]="ny_tenth_wencan",["#ny_10th_xianshu_second"]="ny_10th_xianshu_second",["#ny_tenth_zhifou"]="ny_tenth_zhifou",["#ny_10th_humei_second"]="ny_10th_humei_second",["#ny_10th_ruxian"]="ny_10th_ruxian",["#ny_10th_longhun"]="ny_10th_longhun",["#ny_10th_weiwan"]="ny_10th_weiwan",["#ny_tenth_silun"]="ny_tenth_silun",["#ny_tenth_posuo_select"]="ny_tenth_posuo",["#ny_tenth_posuo"]="ny_tenth_posuo",["#ny_10th_aoshi_give"]="ny_10th_aoshi_give",["#ny_tenth_zongshi"]="ny_tenth_zongshi",["#ny_tenth_linghui"]="ny_tenth_linghui",["#ny_tenth_chanjuan"]="ny_tenth_chanjuan",["#ny_10th_zhuangpo"]="ny_10th_zhuangpo",["#ny_tenth_miyun"]="ny_tenth_miyun",["#ny_10th_danyin"]="ny_10th_danyin",["#ny_tenth_dehua"]="ny_tenth_dehua",["#ny_10th_fuli"]="ny_10th_fuli",["#ny_tenth_yanjiao"]="ny_tenth_yanjiao",["#ny_10th_quanmou"]="ny_10th_quanmou",["#ny_10th_jianguo_second"]="ny_10th_jianguo_second",["#ny_10th_jujian"]="ny_10th_jujian",["#ny_tenth_jvewu"]="ny_tenth_jvewu",["#ny_tenth_wuyou"]="ny_tenth_wuyou_other",["#ny_tenth_yixian"]="ny_tenth_yixian",["#ny_10th_shicao"]="ny_10th_shicao",["#ny_10th_huace"]="ny_10th_huace",["#ny_10th_zhaowen"]="ny_10th_zhaowen",["#ny_tenth_shizong"]="ny_tenth_shizong"}
local ORDINARY_SKILLS={["_ny_tenth_dagongche"]=true,["_ny_tenth_dingji"]=true,["_ny_tenth_shuangbi_mouzhouyu"]=true,["_ny_tenth_shujian"]=true,["ny_10th_huace"]=true,["ny_10th_jieling"]=true,["ny_10th_lifeng"]=true,["ny_10th_longhun"]=true,["ny_10th_zhaowen"]=true,["ny_10th_zhuangpo"]=true,["ny_tenth_chanjuan"]=true,["ny_tenth_dehua"]=true,["ny_tenth_huahuo"]=true,["ny_tenth_jingdianrende"]=true,["ny_tenth_nuanhui"]=true,["ny_tenth_shanjia"]=true,["ny_tenth_shiji"]=true,["ny_tenth_shizong"]=true,["ny_tenth_zongshi"]=true}
local package_skills={}
-- Capture before this package assigns anything: key prefixes are not ownership.
local initial_callbacks={}
for _,name in ipairs({'ai_fill_skill','ai_skill_use_func','ai_guhuo_card','ai_cardsview','ai_cardsview_valuable','ai_view_as'})do
 local before={};for key,value in pairs(sgs[name])do before[key]=value end;initial_callbacks[name]=before
end
initial_callbacks.ai_skill_use={};for key,value in pairs(ai_skill_use)do initial_callbacks.ai_skill_use[key]=value end
-- Package-private source clone state. These plain records are not cards or receipts.
local active_requests=setmetatable({},{__mode="k"})
local clone_states=setmetatable({},{__mode='k'})
local function unsupported(key)ai_unsupported('source capability is not projected',PACKAGE..'.'..key)end

local function clone(self,name,skill,suit,number)
 name=name or 'slash';local p=self:cloneEvaluationCard(name)
 if p==false then return nil end;if not p then unsupported('prototype.'..tostring(name))end
 local v={};clone_states[v]={self=self,name=p:objectName(),skill=skill or '',suit=suit==nil and sgs.Card_NoSuit or suit,number=number or 0,costs={},prototype=p,flags={}}
 return v
end
local function materialize(v)
 local s=clone_states[v];if not s then return v end
 if next(s.flags) then unsupported('clone_flags.'..s.skill)end
 local card
 if s.skill=='' and #s.costs==0 and s.suit==sgs.Card_NoSuit and s.number==0 then card=s.prototype
 else card=s.self:evaluateSkillCard(s.skill, s.name, s.costs)end
 if not card then unsupported('clone.'..s.skill..'.'..s.name)end
 if s.can_recast~=nil and card:canRecast()~=s.can_recast then unsupported('clone_recast.'..s.skill)end
 -- Current narrow endpoint has no arbitrary face parameters. A mismatched native
 -- clone is unknown, never a substitute with different suit/rank.
 local expected_suit=(s.suit>=0 and s.suit<6)and s.suit or sgs.Card_NoSuit
 local expected_number=s.number>0 and s.number or 0
 if #s.costs==0 and (card:getSuit()~=expected_suit or card:getNumber()~=expected_number)then unsupported('clone_face.'..s.skill)end
 if card~=s.prototype then clone_states[card]=s end;return card
end
local function copied_spec(s)
 local ids={};for i,id in ipairs(s.costs)do ids[i]=id end
 return{name=s.name,skill=s.skill,suit=s.suit,number=s.number,subcards=ids}
end
local function finish_turn(self,v,request)
 local s=clone_states[v];if not s then return v end
 if next(s.flags)then unsupported('turn_clone_flags.'..s.skill)end
 return self:evaluateTurnConversion(s.skill, s.prototype:getClassName(), copied_spec(s), request)
end
local function proposal(self,v)
 local s=clone_states[v];if s then return copied_spec(s)end
 if AIValue.isConversion(v)then return v:toCardSpec()end
 return v:getEffectiveId()
end
local function package_call(o,k,...)
 local args=table.pack(...);local s=clone_states[o]
 if s then
  if k=='setSkillName'then s.skill=args[1];return end
  if k=='setSuit'then s.suit=args[1];return end
  if k=='setNumber'then s.number=args[1];return end
  if k=='setCanRecast'then s.can_recast=args[1];return end
  if k=='canRecast'and s.can_recast~=nil then return s.can_recast end
  if k=='deleteLater'then return end
  if k=='clearSubcards'then s.costs={};return end
  if k=='addSubcard'then local x=args[1];s.costs[#s.costs+1]=type(x)=='number'and x or x:getEffectiveId();return end
  if k=='addSubcards'then for _,x in ipairs(args[1])do s.costs[#s.costs+1]=type(x)=='number'and x or x:getEffectiveId()end;return end
  if k=='setFlags'then s.flags[args[1]]=true;return end
  if k=='subcardsLength'then return #s.costs end
  if k=='getSubcards'then return AIList.new(copied_spec(s).subcards)end
  if k=='getSkillName'then if args[1]~=false and s.skill:sub(1,1)=='_'then return s.skill:sub(2)end;return s.skill end
  if k=='objectName'then return s.name end
  o=materialize(o)
 end
 for i=1,args.n do
  if clone_states[args[i]]then args[i]=materialize(args[i])
  elseif AIValue.isList(args[i])then for j,v in ipairs(args[i])do if clone_states[v]then args[i][j]=materialize(v)end end end
 end
 if k=='toString' and (AIValue.isCard(o)or AIValue.isConversion(o))then k='getLegacyStringKey'end
 return AIValue.callOptional(o, k, table.unpack(args,1,args.n))
end
local function package_known(o,k,...)
 local v=table.pack(package_call(o,k,...));if v[1]==nil then unsupported(k)end;return table.unpack(v,1,v.n)
end
local dummy = AIUsePlan.dummy
local function patterns_for(self,class)
 if class then return patterns(class)end
 local a=AICardCatalog.patternNames()
 if not AIValue.isList(a)then unsupported('pattern_names')end;return a
end
local function source_fact(self,key,kind)
 -- The viewer's own tag; absent reads as the donor's empty QVariant conversion.
 local v=self.player:getTag(key)
 if v==nil then
  if kind=='toInt'then return 0 elseif kind=='toString'then return''elseif kind=='toBool'then return false elseif kind=='toIntList'then return AIList.new({})end
  v=false
 end
 if kind=='toPlayer'then return v~=false and package_known(self.room,'findPlayerByObjectName',v,true)or nil end
 if kind=='toInt'or kind=='toString'or kind=='toBool'then return v end
 if kind=='toIntList'then return AIList.new(v)end
 if kind=='toHpLost'or kind=='toMaxHp'then return v~=false and v or nil end
 if kind=='toMoveOneTime'then if v==false then return nil end;local d={};for k,x in pairs(v)do d[k]=x end;for _,k in ipairs({'card_ids','from_places'})do if d[k]then d[k]=AIList.new(d[k])end end;for _,k in ipairs({'from','to'})do if d[k]then d[k]=package_known(self.room,'findPlayerByObjectName',d[k],true)end end;return d end
 if kind=='toJudge'then if v==false then return nil end;local j={};for k,x in pairs(v)do j[k]=x end;j.who=j.who and package_known(self.room,'findPlayerByObjectName',j.who,true);j.card=j.card and CardView.new(j.card);function j:isGood(c)if not c then return self.good end;if self.outcomes_complete~=true or type(self.outcome_by_id)~='table'then unsupported('judge_outcomes.'..key)end;local n=self.outcome_by_id[tostring(package_known(c,'getEffectiveId'))];if type(n)~='boolean'then unsupported('judge_outcome.'..key)end;return n end;function j:isBad(c)return not self:isGood(c)end;return j end
 if kind=='toCardUse'then
  if v==false then return{to=AIList.new({})}end
  local u={card=v.card and CardView.new(v.card),from=v.from and package_known(self.room,'findPlayerByObjectName',v.from,true),to=AIList.new({})}
  for _,n in ipairs(v.to or{})do u.to:append(package_known(self.room,'findPlayerByObjectName',n,true))end;return u
 end
 if kind=='toCard'then return v~=false and CardView.new(v)or nil end
 if kind=='toDeath'then local d={};for k,x in pairs(v)do d[k]=x end;d.who=d.who and package_known(self.room,'findPlayerByObjectName',d.who,true);return d end
 if kind=='toCardEffect'then local d={};for k,x in pairs(v)do d[k]=x end;for _,k in ipairs({'from','to'})do if d[k]then d[k]=package_known(self.room,'findPlayerByObjectName',d[k],true)end end;if d.card then d.card=CardView.new(d.card)end;return d end
 if kind=='toDamage'then local d={};for k,x in pairs(v)do d[k]=x end;for _,k in ipairs({'from','to'})do if d[k]then d[k]=package_known(self.room,'findPlayerByObjectName',d[k],true)end end;if d.card then d.card=CardView.new(d.card)end;return d end
 unsupported(key..'.'..kind)
end
local function skill_source(self,selector,costs,request,user)
 request=request or active_requests[self]
 local skill=SELECTORS[selector];if not skill then unsupported('selector.'..selector)end
 if request and type(request.getActivationSkillName)=='function'then skill=request:getActivationSkillName()end
 return package_known(self,'evaluateTurnSkillCard',skill,selector,costs,request,user~=''and user or nil)
end
-- Only literals present in this package's source may enter this small grammar.
-- It is a pure policy constructor, never Card_Parse or an action-string parser.
local function source_skill(self,text,request)
 if type(text)~='string'then unsupported('source_skill')end
 text=text:match('^(.-)%->')or text
 local selector,cost,user=text:match('^(#[%w_]+):([^:]*):(.*)$')
 if not selector then unsupported('source_skill_shape')end
 local ids={};if cost~='.'and cost~=''then for x in cost:gmatch('[^+]+')do local id=tonumber(x);if not id or id<0 or id%1~=0 then unsupported('source_cost')end;ids[#ids+1]=id end end
 return skill_source(self,selector,ids,request,user)
end
local function selected(self,card,targets)
 local s=clone_states[card];local actual
 if s then actual=package_known(self,'bindOriginalSelectedConversion',copied_spec(s),package_known(s.prototype,'getClassName'),s.skill)
 elseif AIValue.isConversion(card)then actual=card
 elseif package_known(card,'isEvaluationOnly')then actual=package_known(self,'materializeTurnSelectedCard',card)
 else actual=card end
 local p=AIUsePlan.new();p.card=actual
 for _,n in ipairs(targets)do p.to:append(type(n)=='string'and package_known(self.room,'findPlayerByObjectName',n,true)or n)end
 return p:toAnswer()
end
local function response_skill(self,selector,costs,targets,request,user)
 local sk=SELECTORS[selector];if not sk then unsupported('response_selector.'..selector)end
 if request and type(request.getActivationSkillName)~='function'then request=AILegacyRequest.new(request,self.player,sk)end
 local c=package_known(self,'bindSkillCard',sk,costs,request,user,selector);return selected(self,c,targets)
end
local function save_plan(self,key,plan)
 local c=plan.card;local s=clone_states[c];local row=s and{spec=copied_spec(s)}or{card_id=c and package_known(c,'getEffectiveId')}
 row.targets={};for _,p in ipairs(plan.to or{})do row.targets[#row.targets+1]=package_known(p,'objectName')end
 package_call(self,'setStrategyMemory',PACKAGE..'.plan.'..key,row)
end
local function load_plan(self,key)
 local row,known=package_call(self,'getStrategyMemory',PACKAGE..'.plan.'..key);if not known or type(row)~='table'then unsupported('plan.'..key)end
 local p=dummy();if row.spec then local s=row.spec;p.card=clone(self,s.name,s.skill,s.suit,s.number);clone_states[p.card].costs=s.subcards else p.card=package_known(self,'getKnownCardById',row.card_id)end
 for _,n in ipairs(row.targets)do p.to:append(package_known(self.room,'findPlayerByObjectName',n,true))end;return p
end
local function package_add(name)local row={name=name};package_skills[#package_skills+1]=row;return row end
local function actor_ai(player)local self=player and player._room and player._room._ai;if not self or self.player~=player then unsupported('owner_ai')end;return self end
local function owner_ai(self,player)if self.player~=player then unsupported('foreign_ai')end;return self end
local function clone_native(self,name,suit,number)return clone(self,name,nil,suit==nil and sgs.Card_SuitToBeDecided or suit,number==nil and -1 or number)end
local function disclosed_card(self,id)return package_known(self,'getKnownCardById',id)end
local function printed_card(self,id)return package_known(self,'getPrintedCardById',id)end
local function turn_count(self)local v=self.world and self.world.turn_count;if type(v)~='number'then unsupported('turn_count')end;return v end
-- Engine getCurrentCardUseReason() during a card question is that question's reason.
local function owner_reason(self)
 local r=self.request;local card_ask=type(r)=='table'and(r.kind=='activate'or r.kind=='use_card'or r.kind=='respond_card')
 if not card_ask or type(r.reason)~='number'then unsupported('owner_current_card_use_reason')end;return r.reason
end
local function ambient_pattern(self)unsupported('ambient_pattern')end
local function source_tag(self,key)return setmetatable({},{__index=function(_,kind)return function()return source_fact(self,key,kind)end end})end
local function foreign_fact(self,subject,key,kind)
 if subject==self.player then return source_fact(self,key,kind)end
 unsupported('foreign_tag.'..key)
end
local function room_tag(self,key)unsupported('room_tag.'..key)end
local function translation(self,key)unsupported('translation.'..key)end
local function view_as_meta(self,name)unsupported('public_skill_view_as.'..name)end
local function trigger_meta(self,name)unsupported('public_trigger_skill.'..name)end
local function correct_target(self,kind,card)
 local methods={Residue='getTargetModResidue',ExtraTarget='getTargetModExtraTarget',DistanceLimit='getTargetModDistanceLimit'}
 local method=methods[kind];if not method then unsupported('target_modifier.'..kind)end;return package_known(card,method,self.player)
end
local function match_pattern(self,player,pattern,card)if self.player~=player then unsupported('foreign_pattern')end;return package_known(self,'matchesDiscardPattern',pattern,card)end
local function source_player_flag(self,player,key,value)
 if key=='InfinityAttackRange'or key=='slashNoDistanceLimit'then unsupported('transient_player_flag.'..key)end
 if not key:match('^AI_')then unsupported('player_flag.'..key)end
 return package_call(self,'setStrategyPlayerFlag',player,key,value)
end
local function source_ids(text)
 local out={};if text~='.'and text~=''then for x in text:gmatch('[^+]+')do local id=tonumber(x);if not id or id<0 or id%1~=0 then unsupported('source_cost')end;out[#out+1]=id end end;return out
end
-- Finite source constructor grammar, not a native action parser: normal-card
-- products remain pure specs and SkillCards require their exact issued scope.
local function constructor_parts(text)
 if type(text)~='string'then unsupported('source_constructor')end
 text=text:match('^(.-)%->')or text
 local physical=text:match('^%d+$');if physical then return{physical_id=tonumber(physical)}end
 local selector,face_suit,face_number,cost,user=text:match('^(#[%w_]+)%[([^:]+):([^%]]+)%]:([^:]*):(.*)$')
 local exact_wire=selector and text or nil
 if not selector then selector,cost,user=text:match('^(#[%w_]+):([^:]*):(.*)$')end
 if selector then if not SELECTORS[selector]then unsupported('selector.'..selector)end;return{selector=selector,costs=source_ids(cost),user=user,exact_wire=exact_wire}end
 local name,skill,suit,number,ids=text:match('^(%w+):([%w_]*)%[([^:]+):([^%]]+)%]=(.+)$')
 if name and ORDINARY_SKILLS[skill]then
  local suits={spade=sgs.Card_Spade,club=sgs.Card_Club,heart=sgs.Card_Heart,diamond=sgs.Card_Diamond,no_suit_red=sgs.Card_NoSuitRed,no_suit_black=sgs.Card_NoSuitBlack}
  local numbers={A=1,J=11,Q=12,K=13}
  return{name=name,skill=skill,suit=suits[suit]or sgs.Card_NoSuit,number=numbers[number]or tonumber(number)or 0,subcards=source_ids(ids)}
 end
 unsupported('source_constructor_shape')
end
local function source_construct(self,text,request)
 local row=constructor_parts(text)
 if row.physical_id then return disclosed_card(self,row.physical_id)end
 if row.selector then local card=skill_source(self,row.selector,row.costs,request,row.user);if row.exact_wire and package_known(card,'getLegacyStringKey')~=row.exact_wire then unsupported('skill_clone_face.'..row.selector)end;return card end
 local c=clone(self,row.name,row.skill,row.suit,row.number);if c then clone_states[c].costs=row.subcards end;return c
end
local function source_proposal(self,text)
 local row=constructor_parts(text)
 if row.physical_id then unsupported('physical_conversion_proposal')end
 if row.exact_wire then unsupported('skill_prototype_response.'..row.selector)end
 if row.selector then return{name=row.selector:sub(2),skill=SELECTORS[row.selector],suit=sgs.Card_NoSuit,number=0,subcards=row.costs,user_string=row.user~=''and row.user or nil}end
 return row
end
local function source_response(self,text,request)
 local row=constructor_parts(text);local target_text=text:match('%->(.*)$');local targets={};for name in (target_text or''):gmatch('[^+]+')do targets[#targets+1]=name end
 if row.selector then if row.exact_wire then unsupported('skill_prototype_response.'..row.selector)end;return response_skill(self,row.selector,row.costs,targets,request,row.user~=''and row.user or nil)end
 local card=source_construct(self,text,request);return selected(self,card,targets)
end
local state_instances=setmetatable({},{__mode='k'})
local function encode(self,v,seen)
 if v==nil then return{kind='nil'}end
 if type(v)~='table'then if type(v)=='number'or type(v)=='string'or type(v)=='boolean'then return v end;unsupported('cache_value')end
 seen=seen or{};if seen[v]then unsupported('cache_cycle')end;seen[v]=true
 local out
 if clone_states[v]then out={kind='clone',spec=copied_spec(clone_states[v])}
 elseif AIValue.isPlayer(v)then out={kind='player',name=package_known(v,'objectName')}
 elseif AIValue.isCard(v)or AIValue.isConversion(v)then
  if package_known(v,'isVirtualCard')then out={kind='clone',spec={name=package_known(v,'objectName'),skill=package_known(v,'getSkillName',false),suit=package_known(v,'getSuit'),number=package_known(v,'getNumber'),subcards=package_known(v,'getSubcards')}}
  else out={kind='card',id=package_known(v,'getEffectiveId')}end
 elseif getmetatable(v)==AIUsePlan then
  out={kind='plan',card=encode(self,v.card,seen),to=encode(self,v.to,seen)}
 elseif AIValue.isList(v)then
  out={kind='list',native=AIList.isNativeList(v),items={}};for i,x in ipairs(v)do out.items[i]=encode(self,x,seen)end
 else
  out={kind='table',items={}};for k,x in pairs(v)do if type(k)~='string'and type(k)~='number'then unsupported('cache_key')end;out.items[k]=encode(self,x,seen)end
 end
 seen[v]=nil;return out
end
local function decode(self,v)
 if type(v)~='table'then return v end
 if v.kind=='nil'then return nil end
 if v.kind=='player'then return package_known(self.room,'findPlayerByObjectName',v.name,true)end
 if v.kind=='card'then return disclosed_card(self,v.id)end
 if v.kind=='clone'then local s=v.spec;local c=clone(self,s.name,s.skill,s.suit,s.number);clone_states[c].costs=s.subcards;return c end
 if v.kind=='plan'then local p=dummy();p.card=decode(self,v.card);p.to=decode(self,v.to);return p end
 if v.kind=='list'then local out={};for i,x in ipairs(v.items)do out[i]=decode(self,x)end;out=AIList.new(out);return v.native and out or AIList.asLuaTable(out)end
 if v.kind=='table'then local out={};for k,x in pairs(v.items)do out[k]=decode(self,x)end;return out end
 unsupported('cache_schema')
end
local function source_state(self)
 local state=state_instances[self];if state then return state end
 local present,values={},{}
 state=setmetatable({},{__index=function(_,key)
  if present[key]then return values[key]end
  local raw,known=package_call(self,'getStrategyMemory',PACKAGE..'.cache.'..key)
  if not known then package_known(self,'useKnowledgeEstimate',{value=false,status='estimate',basis=PACKAGE..'.unobserved_source_cache.'..key},PACKAGE..'.cache.'..key)end
  local v=known and decode(self,raw)or nil;values[key]=v;present[key]=true;return v
 end,__newindex=function(_,key,v)
  local raw=encode(self,v);package_call(self,'setStrategyMemory',PACKAGE..'.cache.'..key,raw);values[key]=v;present[key]=true
 end});state_instances[self]=state;return state
end

local function source_property(self,key)
 -- The viewer's own property; absent reads as QVariant's empty conversion.
 local v=self.player:getPropertyValue(key)
 return{toString=function()if v==nil then return''end;if type(v)~='string'then unsupported('property_string.'..key)end;return v end,toInt=function()if v==nil then return 0 end;if type(v)~='number'then unsupported('property_number.'..key)end;return v end,toBool=function()if v==nil then return false end;if type(v)~='boolean'then unsupported('property_bool.'..key)end;return v end}
end
local function dispatch_source_type(self,card,use)
 local types={'BasicCard','TrickCard'};local suffix=types[package_known(card,'getTypeId')];if not suffix then unsupported('source_type_dispatch')end
 return package_call(self,'use'..suffix,card,use)
end

-- Three fixed LuaSkillCard globals in sgs10th are constructor state only.
-- Reading their wire value requires the real readonly native prototype.
local function prototype_clone(self,selector)
 if not SELECTORS[selector]then unsupported('prototype_selector.'..selector)end
 local costs,user={},''
 return {addSubcard=function(_,card)costs[#costs+1]=type(card)=='number'and card or package_known(card,'getEffectiveId')end,
 setUserString=function(_,value)if type(value)~='string'then unsupported('prototype_user_string')end;user=value end,
 toString=function()local card=skill_source(self,selector,costs,nil,user);return package_known(card,'getLegacyStringKey')end}
end

local function public_deck_rows(key)
 -- Engine getRandomCards() walked in shuffled order, rebuilt from the card catalog: the order
 -- in which names first occur in a shuffled deck is a draw without replacement weighted by
 -- each name's copy count. Only per-name printed kinds are known, not per-card faces.
 local names=AICardCatalog.patternNames();if not AIValue.isList(names)then unsupported('public_deck_host')end
 local pool,total={},0
 for _,name in ipairs(names)do local row=AICardCatalog.get(name);if row and(row.count or 0)>0 then pool[#pool+1]=row;total=total+row.count end end
 local out={}
 while #pool>0 do
  local pick,i=math.random(1,total),1
  while pick>pool[i].count do pick=pick-pool[i].count;i=i+1 end
  local row=table.remove(pool,i);total=total-row.count
  -- Restricted public metadata object, deliberately no payment/physical-card API.
  local card={}
  function card:objectName()return row.name end
  function card:isKindOf(name)if name=='BasicCard'then return row.type_id==sgs.Card_TypeBasic end;unsupported('public_deck_kind.'..tostring(name))end
  function card:isNDTrick()return row.nd_trick==true end
  function card:isDamageCard()return row.damage_card==true end
  out[#out+1]=card
 end
 return AIList.new(out)
end
local function public_deck_shuffle(self)return public_deck_rows('ny_tenth_jvewu_printed')end
local function hidden_draw_pile(self)unsupported("shicao.hidden_draw_pile")end
local function source_error(key)ai_unsupported("fixed donor compatibility unavailable",PACKAGE..".donor_error."..key)end
local function suit_tag(self,key)if type(key)~="string"or not key:match("^ny_tenth_posuo_[a-z_]+$")then unsupported("posuo_key")end;return room_tag(self,key)end


sgs.ai_skill_invoke.ny_10th_caixia = true

sgs.ai_skill_choice["ny_10th_caixia"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    return items[#items]
end



sgs.ai_skill_playerchosen.ny_10th_shangyu = function(self,targets)
	package_call(self,"updatePlayers")

    local min = 9999
    local result = nil
    for _,target in sgs.qlist(targets) do
        if package_known(self,"isFriend",target) and package_known(target,"getHandcardNum") < min then
            result = target
            min = package_known(target,"getHandcardNum")
        end
    end
    if result then return result end
    for _,target in sgs.qlist(targets) do
        if package_known(target,"objectName") == package_known(self.player,"objectName") then return target end
    end
    local max = 0
    for _,target in sgs.qlist(targets) do
        if not package_known(self,"isFriend",target) and package_known(target,"getHandcardNum") > max then
            result = target
            max = package_known(target,"getHandcardNum")
        end
    end
    if result then return result end
    local all = sgs.QList2Table(targets)
    return all[math.random(1,#all)]
end

sgs.ai_skill_cardask["@ny_tenth_pingliao"] = function(self,data,pattern)
	local use = package_known(data,"toCardUse")
	if package_known(self,"isFriend",use.from) then return "." end
	if package_known(self,"isGoodTarget",self.player,package_known(self,"getEnemies",use.from),use.card)
	and math.random()>0.4
	then return true end
    return "."
end



local ny_10th_xianshu_skill = {}
ny_10th_xianshu_skill.name = "ny_10th_xianshu"
table.insert(package_skills, ny_10th_xianshu_skill)
ny_10th_xianshu_skill.getTurnUseCard = function(self,inclusive,request)
	for _,card in sgs.qlist(package_known(self.player,"getHandcards")) do
        if package_known(card,"hasFlag","ny_10th_konghou") then
	        return source_construct(self,"#ny_10th_xianshu:.:")
        end
    end
end

sgs.ai_skill_use_func["#ny_10th_xianshu"] = function(card,use,self,request)
	package_call(self,"updatePlayers")

    local red = {}
    local black = {}
    local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)
    for _,card in ipairs(cards) do
        if package_known(card,"hasFlag","ny_10th_konghou") then
	        if package_known(card,"isRed") then table.insert(red, package_known(card,"getEffectiveId")) end
            if package_known(card,"isBlack") then table.insert(black, package_known(card,"getEffectiveId")) end
        end
    end

    local enduse = false
    if #red > 0 then
        package_call(self,"sort",self.friends, "hp")
        for _,friend in ipairs(self.friends) do
            if package_known(friend,"objectName") ~= package_known(self.player,"objectName")
            and package_known(friend,"getHp") <= package_known(self.player,"getHp") and package_known(friend,"isWounded") then
                local card_str = string.format("#ny_10th_xianshu:%s:->%s", red[1], package_known(friend,"objectName"))
		        local acard = source_construct(self,card_str)
		        assert(acard)
		        use.card = acard
		        if use.to then
			        package_call(use.to,"append",friend)
		        end
                enduse = true
                break
            end
        end
    end
    if #black > 0 and (not enduse) then
        package_call(self,"sort",self.enemies, "hp")
        for _,enemy in ipairs(self.enemies) do
            if package_known(enemy,"objectName") ~= package_known(self.player,"objectName")
            and package_known(enemy,"getHp") >= package_known(self.player,"getHp") then
                local card_str = string.format("#ny_10th_xianshu:%s:->%s", black[1], package_known(enemy,"objectName"))
		        local acard = source_construct(self,card_str)
		        assert(acard)
		        use.card = acard
		        if use.to then
			        package_call(use.to,"append",enemy)
		        end
                break
            end
        end
    end
end

sgs.ai_use_priority.ny_10th_xianshu = 10

sgs.ai_card_intention.ny_10th_xianshu = function(self, card, from, tos)
	for _,to in ipairs(tos) do
        if package_known(to,"getHp") > package_known(from,"getHp") then
		    sgs.updateIntention(from, to, 80)
        elseif package_known(to,"getHp") < package_known(from,"getHp") then
            sgs.updateIntention(from, to, -80)
        else
            if package_known(card,"isRed") then
                sgs.updateIntention(from, to, -80)
            elseif package_known(card,"isBlack") then
                sgs.updateIntention(from, to, 80)
            end
        end
	end
end



sgs.ai_skill_playerchosen.ny_10th_shengdu = function(self,targets)
    local nextp = package_known(self.player,"getNextAlive")
    while(package_known(nextp,"objectName")~= package_known(self.player,"objectName")) do
        if package_known(self,"isFriend",nextp) and package_known(nextp,"getStrategyMark","ny_10th_shengdu_from_"..package_known(self.player,"objectName")) == 0 then
            return nextp
        else
            nextp = package_known(nextp,"getNextAlive")
        end
    end
    nextp = package_known(self.player,"getNextAlive")
    while(package_known(nextp,"objectName")~= package_known(self.player,"objectName")) do
        if package_known(nextp,"getStrategyMark","ny_10th_shengdu_from_"..package_known(self.player,"objectName")) == 0 then
            return nextp
        else
            nextp = package_known(nextp,"getNextAlive")
        end
    end
    local all = sgs.QList2Table(targets)
    return all[math.random(1,#all)]
end



local ny_10th_jieling_skill = {}
ny_10th_jieling_skill.name = "ny_10th_jieling"
table.insert(package_skills, ny_10th_jieling_skill)
ny_10th_jieling_skill.getTurnUseCard = function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#ny_10th_jieling") then
		return source_construct(self,"#ny_10th_jieling:.:")
	end
end

sgs.ai_skill_use_func["#ny_10th_jieling"] = function(card,use,self,request)
	package_call(self,"updatePlayers")
	local red = {}
    local black = {}
    local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)
    for _,card in ipairs(cards) do
	    if package_known(card,"isRed") then table.insert(red, card) end
        if package_known(card,"isBlack") then table.insert(black, card) end
    end

    if #red > 0 and #black > 0 then
        local use_cards = {package_known(red[1],"getEffectiveId"),package_known(black[1],"getEffectiveId")}
        local slash = clone_native(self,"slash", sgs.Card_SuitToBeDecided, -1)
        package_call(slash,"setSkillName","ny_10th_jieling")
        package_call(slash,"addSubcard",red[1])
        package_call(slash,"addSubcard",black[1])


        local usec = {isDummy=true,to=sgs.SPlayerList()}
        package_call(self,"useCardByClassName",slash, usec)
        if usec.card then
            if usec.to and package_known(usec.to,"length") > 0 then
                local tos = {}
                for _,p in sgs.qlist(usec.to) do
                    table.insert(tos, package_known(p,"objectName"))
                end

				local card_str = string.format("#ny_10th_jieling:%s:->%s", table.concat(use_cards,"+"), table.concat(tos,"+"))
		        local acard = source_construct(self,card_str)
		        assert(acard)
		        use.card = acard
		        if use.to then
			        use.to = usec.to
		        end
            end
        end
    end
end



local ny_10th_chiying_skill = {}
ny_10th_chiying_skill.name = "ny_10th_chiying"
table.insert(package_skills, ny_10th_chiying_skill)
ny_10th_chiying_skill.getTurnUseCard = function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#ny_10th_chiying") then
		return source_construct(self,"#ny_10th_chiying:.:")
	end
end

sgs.ai_skill_use_func["#ny_10th_chiying"] = function(card,use,self,request)
	package_call(self,"updatePlayers")
	local room = self.room
    local can_dis = 0
    local target = nil

    for _,friend in ipairs(self.friends) do
        if package_known(friend,"getHp") <= package_known(self.player,"getHp") then
            local dis = 0
            for _,other in sgs.qlist(package_known(room,"getOtherPlayers",friend)) do
                if package_known(friend,"inMyAttackRange",other) and package_known(other,"objectName") ~= package_known(self.player,"objectName") then
                    if not package_known(self,"isFriend",other) then
                        if package_known(friend,"objectName") == package_known(self.player,"objectName") then
                            dis = dis + 1
                        else
                            dis = dis + 1.5
                        end
                    end
                end
            end
            if dis > can_dis then
                target = friend
                can_dis = dis
            end
        end
    end

	if not target then return end
	if target then
		local card_str = "#ny_10th_chiying:.:->"..package_known(target,"objectName")
		local acard = source_construct(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			package_call(use.to,"append",target)
		end
	end
end

sgs.ai_use_priority.ny_10th_chiying = 6



sgs.ai_skill_discard.ny_10th_changqu = function(self,max,min)
    local friend = false
    for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
        if package_known(p,"getPhase") == sgs.Player_Play then
            if package_known(self,"isFriend",p) then friend = true end
        end
    end

    local dis = {}
	if friend or ((package_known(self.player,"getStrategyMark","&ny_10th_changqu") + min) >= package_known(self.player,"getHp")) then
        local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	    package_call(self,"sortByKeepValue",cards)
	    if #cards >= min then
		    for i = 1, min, 1 do
                table.insert(dis, package_known(cards[i],"getEffectiveId"))
            end
	    end
    end
	return dis
end

local ny_10th_changqu_skill = {}
ny_10th_changqu_skill.name = "ny_10th_changqu"
table.insert(package_skills, ny_10th_changqu_skill)
ny_10th_changqu_skill.getTurnUseCard = function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#ny_10th_changqu") then
		return source_construct(self,"#ny_10th_changqu:.:")
	end
end

sgs.ai_skill_use_func["#ny_10th_changqu"] = function(card,use,self,request)
	package_call(self,"updatePlayers")
	local room = self.room
    local target = nil

    local move = package_known(self.room,"getAlivePlayers"):length()-1
    local left_now = package_known(self.player,"getNextAlive",move)
    local left_num_now = 0
    local left_num = 0
    local left = {}
    while(package_known(left_now,"objectName") ~= package_known(self.player,"objectName")) do
        local now = math.max(left_num_now,1)
        if package_known(self,"isFriend",left_now) then
            left_num = left_num - now
            if package_known(left_now,"getHandcardNum") < now then
                left_num = left_num - now
            end
        else
            left_num = left_num + now*1.5
            if package_known(left_now,"getHandcardNum") < now then
                left_num = left_num + now
            end
        end
        left_num_now = left_num_now + 1
        left_now = package_known(left_now,"getNextAlive",move)
        table.insert(left,left_num)
        if package_known(left_now,"getHandcardNum") < now then
            break
        end
    end

    local right_now = package_known(self.player,"getNextAlive",1)
    local right_num_now = 0
    local right_num = 0
    local right = {}
    while(package_known(right_now,"objectName") ~= package_known(self.player,"objectName")) do
        local now = math.max(right_num_now,1)
        if package_known(self,"isFriend",right_now) then
            right_num = right_num - now
            if package_known(right_now,"getHandcardNum") < now then
                right_num = right_num - now
            end
        else
            right_num = right_num + now*1.5
            if package_known(right_now,"getHandcardNum") < now then
                right_num = right_num + now
            end
        end
        right_num_now = right_num_now + 1
        right_now = package_known(right_now,"getNextAlive",1)
        table.insert(right,right_num)
        if package_known(right_now,"getHandcardNum") < now then
            break
        end
    end

    local left_max = left[1]
    local right_max = right[1]
    for _,p in ipairs(left) do
        if p > left_max then left_max = p end
    end
    for _,p in ipairs(right) do
        if p > right_max then right_max = p end
    end

    if left_max > right_max then
        target = package_known(self.player,"getNextAlive",-1)
    else
        target = package_known(self.player,"getNextAlive",1)
    end

	if not target then return end
	if target then
		local card_str = "#ny_10th_changqu:.:->"..package_known(target,"objectName")
		local acard = source_construct(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			package_call(use.to,"append",target)
		end
	end
end

sgs.ai_skill_playerchosen.ny_10th_changqu = function(self,targets)
    local move = package_known(self.room,"getAlivePlayers"):length() - 1
    if package_known(self.player,"getStrategyMark","ny_10th_changqu_right") > 0 then move = 1 end

    local direction_now = package_known(self.player,"getNextAlive",move)
    local direction_num_now = 0
    local direction_num = 0
    local direction = {}
    while(package_known(direction_now,"objectName") ~= package_known(self.player,"objectName")) do
        local now = math.max(direction_num_now,1)
        if package_known(self,"isFriend",direction_now) then
            direction_num = direction_num - now
            if package_known(direction_now,"getHandcardNum") < now then
                direction_num = direction_num - now
            end
        else
            direction_num = direction_num + now*1.5
            if package_known(direction_now,"getHandcardNum") < now then
                direction_num = direction_num + now
            end
        end
        direction_num_now = direction_num_now + 1
        direction_now = package_known(direction_now,"getNextAlive",move)
        table.insert(direction,direction_num)
        if package_known(direction_now,"getHandcardNum") < now then
            break
        end
    end
    local target = 1
    local now = 1
    local max = direction[1]
    for _,p in ipairs(direction) do
        if p > max then
            max = p
            target = now
        end
        now = now + 1
    end
    local result = self.player
    for i = 1, target, 1 do
        result = package_known(result,"getNextAlive",move)
    end
    return result
end



local ny_10th_humei_skill = {}
ny_10th_humei_skill.name = "ny_10th_humei"
table.insert(package_skills, ny_10th_humei_skill)
ny_10th_humei_skill.getTurnUseCard = function(self,inclusive,request)
    local choices = {"draw", "give", "recover"}
    for _,p in ipairs(choices) do
        if package_known(self.player,"getStrategyMark","ny_10th_humei_tiansuan_remove_"..p.."-PlayClear") == 0 then
            return source_construct(self,"#ny_10th_humei:.:"..p)
        end
    end
end

sgs.ai_skill_use_func["#ny_10th_humei"] = function(card,use,self,request)
	local choices = {"draw", "give", "recover"}
    for _,p in ipairs(choices) do
        if package_known(self.player,"getStrategyMark","ny_10th_humei_tiansuan_remove_"..p.."-PlayClear") == 0 then
            if p == "draw" then
                package_call(self,"sort",self.friends, "handcard")
                local target = nil
                for _,friend in ipairs(self.friends) do
                    if package_known(friend,"getHp") <= package_known(self.player,"getStrategyMark","&ny_10th_humei-PlayClear") then
                        target = friend
                        break
                    end
                end
                if target then
                    use.card = source_construct(self,"#ny_10th_humei:.:"..p)
                    if use.to then package_call(use.to,"append",target) end
                    break
                end
            end

            if p == "give" then
                package_call(self,"sort",self.enemies, "handcard")
                local target = nil
                for _,enemy in ipairs(self.enemies) do
                    if package_known(enemy,"getHp") <= package_known(self.player,"getStrategyMark","&ny_10th_humei-PlayClear") and (not package_known(enemy,"isNude")) then
                        target = enemy
                        break
                    end
                end
                if target then
                    use.card = source_construct(self,"#ny_10th_humei:.:"..p)
                    if use.to then package_call(use.to,"append",target) end
                    break
                end
            end

            if p == "recover" then
                package_call(self,"sort",self.friends, "hp")
                local target = nil
                for _,friend in ipairs(self.friends) do
                    if package_known(friend,"getHp") <= package_known(self.player,"getStrategyMark","&ny_10th_humei-PlayClear") and package_known(friend,"isWounded") then
                        target = friend
                        break
                    end
                end
                if target then
                    use.card = source_construct(self,"#ny_10th_humei:.:"..p)
                    if use.to then package_call(use.to,"append",target) end
                    break
                end
            end
        end
    end
end



sgs.ai_skill_invoke.ny_10th_jiaoxia = function(self,data)
    if package_known(self.player,"getHandcardNum") > package_known(self.player,"getMaxHp") then return false end
    if package_known(self,"getCardsNum","Slash") <= 1 then return true end
    if math.random(1,3) == 1 then return true end
    return false
end

ai_skill_use["@@ny_10th_jiaoxia"]=function(self,prompt,request)
    local card = disclosed_card(self,package_known(self.player,"getStrategyMark","ny_10th_jiaoxia_card"))

    local use = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, use)
    if use.card then
        if use.to and package_known(use.to,"length") > 0 then
            local tos = {}
            for _,p in sgs.qlist(use.to) do
                table.insert(tos, package_known(p,"objectName"))
            end
            return selected(self,card,tos)
        end
    end
end



local ny_10th_moyu_skill = {}
ny_10th_moyu_skill.name = "ny_10th_moyu"
table.insert(package_skills, ny_10th_moyu_skill)
ny_10th_moyu_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyMark","ny_10th_moyu_damage-Clear") > 0 then return end
    return source_construct(self,"#ny_10th_moyu:.:")
end

sgs.ai_skill_use_func["#ny_10th_moyu"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies,"handcard")
	for _,ep in sgs.list(self.enemies)do
		if package_known(ep,"getCardCount")>0 and package_known(ep,"getStrategyMark","ny_10th_moyu_chosen-PlayClear") == 0
		then
			if package_known(self,"getCardsNum","Jink","h")>0
			or (package_known(self.player,"getHandcardNum") > package_known(ep,"getHandcardNum")
            and package_known(self.player,"getStrategyMark","&ny_10th_moyu-Clear") < (package_known(self.player,"getHp") - 1))
			then
				use.card = card
				if use.to then package_call(use.to,"append",ep) end
				return
			end
		end
	end
    for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if (not package_known(p,"getJudgingArea"):isEmpty()) and package_known(p,"getStrategyMark","ny_10th_moyu_chosen-PlayClear") == 0 then
            use.card = card
			if use.to then package_call(use.to,"append",p) end
			return
        end
    end
end

sgs.ai_use_value.ny_10th_moyu = 9.4
sgs.ai_use_priority.ny_10th_moyu = 5.8



local ny_pandi_tenth_skill = {}
ny_pandi_tenth_skill.name = "ny_pandi_tenth"
table.insert(package_skills, ny_pandi_tenth_skill)
ny_pandi_tenth_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyMark","ny_pandi_tenth_notcard-PlayClear") > 0 then return end
    return source_construct(self,"#ny_pandi_tenth:.:")
end

sgs.ai_skill_use_func["#ny_pandi_tenth"] = function(card,use,self,request)
	for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if package_known(p,"getStrategyMark","ny_pandi_tenth_damage-Clear") == 0 then
            if package_known(self,"isFriend",p) then
				for _,h in sgs.qlist(package_known(self.player,"getHandcards"))do
					if package_known(h,"isKindOf","Peach") and package_known(p,"isWounded") then
                    use.card = card
                    if use.to then package_call(use.to,"append",p) end
                    return
                end
            end
            end
			for _,h in sgs.qlist(package_known(self.player,"getHandcards"))do
                if package_known(h,"isKindOf","Slash") then
					for _,slashto in sgs.qlist(package_known(self.room,"getCardTargets",p, h)) do
                    if not package_known(self,"isFriend",slashto) then
                        use.card = card
                        if use.to then package_call(use.to,"append",p) end
                        return
                    end
                end
                elseif package_known(h,"isKindOf","Duel") then
					for _,duelto in sgs.qlist(package_known(self.room,"getCardTargets",p, duel)) do
                    if not package_known(self,"isFriend",duelto) then
                        use.card = card
                        if use.to then package_call(use.to,"append",p) end
                        return
                    end
                end
            end
        end
    end
    end


    local equips = {}
	for _,h in sgs.qlist(package_known(self.player,"getHandcards"))do
		if package_known(h,"isKindOf","Armor") or package_known(h,"isKindOf","Weapon") then
			if not package_known(self,"getSameEquip",h) then
			elseif package_known(h,"isKindOf","GudingBlade") and package_known(self,"getCardsNum","Slash")>0 then
				local HeavyDamage
				local slash = package_call(self,"getCard","Slash")
				for _,enemy in ipairs(self.enemies)do
					if package_known(self.player,"canSlash",enemy,slash,true) and not package_known(self,"slashProhibit",slash,enemy)
					and package_known(self,"slashIsEffective",slash,enemy) and not package_known(self,"hasJueqingEffect",self.player,enemy) and package_known(enemy,"isKongcheng") then
							HeavyDamage = true
							break
					end
				end
				if not HeavyDamage then table.insert(equips,h) end
			else
				table.insert(equips,h)
			end
		elseif package_known(h,"getTypeId")==sgs.Card_TypeEquip then
			table.insert(equips,h)
		end
	end

	if #equips==0 then return end

	for _,friend in ipairs(self.friends_noself)do
        if package_known(friend,"getStrategyMark","ny_pandi_tenth_damage-Clear") == 0 then
            for _,equip in ipairs(equips)do do
                local index = package_known(equip,"getRealCard"):toEquipCard():location()
                if not package_known(friend,"hasEquipArea",index) then goto package_continue_1 end
                if not package_known(self,"getSameEquip",equip,friend) and package_known(self,"hasSkills",sgs.need_equip_skill.."|"..sgs.lose_equip_skill,friend) then
					use.card = card
					if use.to then
						package_call(use.to,"append",friend)
                end
                    return
                end
            end ::package_continue_1:: end
            for _,equip in ipairs(equips)do do
                local index = package_known(equip,"getRealCard"):toEquipCard():location()
                if not package_known(friend,"hasEquipArea",index) then goto package_continue_2 end
                if not package_known(self,"getSameEquip",equip,friend) then
					use.card = card
					if use.to then
						package_call(use.to,"append",friend)
                end
                    return
            end
        end ::package_continue_2:: end
	end
	end
end

ai_skill_use["@@ny_pandi_tenth"]=function(self,prompt,request)
    local target = nil
    for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if package_known(p,"getStrategyFlag","ny_pandi_tenth_target") then target = p end
    end
    if not target then return end

    if package_known(self,"isFriend",target) then
        if package_known(target,"isWounded") then
            for _,card in sgs.qlist(package_known(self.player,"getHandcards")) do
                if package_known(card,"isKindOf","Peach") then
                    return string.format("#ny_pandi_tenth_use:%s:->%s", package_known(card,"getEffectiveId"), package_known(target,"objectName"))
                end
            end
        end
    end
                for _,card in sgs.qlist(package_known(self.player,"getHandcards")) do
                    if package_known(card,"isKindOf","Slash") then
			for _,slashto in sgs.qlist(package_known(self.room,"getCardTargets",target, card)) do
				if not package_known(self,"isFriend",slashto) then
                        return string.format("#ny_pandi_tenth_use:%s:->%s", package_known(card,"getEffectiveId"), package_known(slashto,"objectName"))
                    end
                end
            end
        end
                for _,card in sgs.qlist(package_known(self.player,"getHandcards")) do
        for _,duelto in sgs.qlist(package_known(self.room,"getCardTargets",target, card)) do
            if not package_known(self,"isFriend",duelto) then
                    if package_known(card,"isKindOf","Duel") then
                        return string.format("#ny_pandi_tenth_use:%s:->%s", package_known(card,"getEffectiveId"), package_known(duelto,"objectName"))
                    end
                end
            end
        end


    local equips = {}
	for _,card in sgs.qlist(package_known(self.player,"getHandcards"))do
		if package_known(card,"isKindOf","Armor") or package_known(card,"isKindOf","Weapon") then
			if not package_known(self,"getSameEquip",card) then
			elseif package_known(card,"isKindOf","GudingBlade") and package_known(self,"getCardsNum","Slash")>0 then
				local HeavyDamage
				local slash = package_call(self,"getCard","Slash")
				for _,enemy in ipairs(self.enemies)do
					if package_known(self.player,"canSlash",enemy,slash,true) and not package_known(self,"slashProhibit",slash,enemy)
					and package_known(self,"slashIsEffective",slash,enemy) and not package_known(self,"hasJueqingEffect",self.player,enemy) and package_known(enemy,"isKongcheng") then
							HeavyDamage = true
							break
					end
				end
				if not HeavyDamage then table.insert(equips,card) end
			else
				table.insert(equips,card)
			end
		elseif package_known(card,"getTypeId")==sgs.Card_TypeEquip then
			table.insert(equips,card)
		end
	end

	if #equips==0 then return end

	for _,friend in ipairs(self.friends_noself)do
		for _,equip in ipairs(equips)do do
			local index = package_known(equip,"getRealCard"):toEquipCard():location()
			if not package_known(friend,"hasEquipArea",index) then goto package_continue_3 end
			if not package_known(self,"getSameEquip",equip,friend) and package_known(self,"hasSkills",sgs.need_equip_skill.."|"..sgs.lose_equip_skill,friend) then
				return string.format("#ny_pandi_tenth_use:%s:->%s", package_known(equip,"getEffectiveId"), package_known(friend,"objectName"))
			end
		end ::package_continue_3:: end
		for _,equip in ipairs(equips)do do
			local index = package_known(equip,"getRealCard"):toEquipCard():location()
			if not package_known(friend,"hasEquipArea",index) then goto package_continue_4 end
			if not package_known(self,"getSameEquip",equip,friend) then
				return string.format("#ny_pandi_tenth_use:%s:->%s", package_known(equip,"getEffectiveId"), package_known(friend,"objectName"))
		end
	end ::package_continue_4:: end
    end
    return "."
end



ai_skill_use["@@ny_tenth_porui"]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    package_call(self,"sortByKeepValue",cards)
    if #cards == 0 then return "." end
    local max = 0
    local target = nil
    for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if package_known(self,"isEnemy",p) and package_known(p,"getStrategyMark","&ny_tenth_porui-Clear") > max then
            target = p
            max = package_known(p,"getStrategyMark","&ny_tenth_porui-Clear")
        end
    end
    if target then
        return string.format("#ny_tenth_porui:%s:->%s", package_known(cards[1],"getEffectiveId"), package_known(target,"objectName"))
    end
end



sgs.ai_skill_playerchosen.ny_10th_gonghu = function(self,targets)
    local card = disclosed_card(self,package_known(self.player,"getStrategyMark","ny_10th_gonghu_card"))
    if card then
        if package_known(card,"objectName") == "ex_nihilo" then
            for _,p in sgs.qlist(targets) do
                if package_known(self,"isFriend",p) then return p end
            end
        else
            for _,p in sgs.qlist(targets) do
                if package_known(self,"isEnemy",p) then return p end
            end
        end
    end
    return nil
end



local ny_10th_jianguo_skill = {}
ny_10th_jianguo_skill.name = "ny_10th_jianguo"
table.insert(package_skills, ny_10th_jianguo_skill)
ny_10th_jianguo_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#ny_10th_jianguo") then return end
    return source_construct(self,"#ny_10th_jianguo:.:")
end

sgs.ai_skill_use_func["#ny_10th_jianguo"] = function(card,use,self,request)
    local target = nil
    local max = 0
    for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
        if package_known(self,"isFriend",p) then
            local num = -1 + math.floor((package_known(p,"getHandcardNum") - 1) / 2)
            num = num*1.1
            if num > max then
                target = p
                max = num
            end
        else
            local num = -1 + math.floor((package_known(p,"getHandcardNum") + 1) / 2)
            if num > max then
                target = p
                max = num
            end
        end
    end
    if target then
        use.card = card
        if use.to then package_call(use.to,"append",target) end
    end
end

sgs.ai_skill_choice["ny_10th_jianguo"] = function(self, choices, data)
	local target = package_call(data,"toPlayer")
    if package_known(self,"isFriend",target) then return "draw"
    else return "dis" end
end

sgs.ai_use_priority.ny_10th_jianguo = 6.8



sgs.ai_skill_playerchosen.ny_10th_qinshi = function(self, targets)
    local players = sgs.QList2Table(targets)
    package_call(self,"sort",players, "hp")
    for _,p in ipairs(players) do
        if package_known(self,"isEnemy",p) then return p end
    end
    return nil
end



sgs.ai_skill_playerchosen.ny_10th_huiling = function(self, targets)
    local players = sgs.QList2Table(targets)
    package_call(self,"sort",players, "defense")
    for _,p in ipairs(players) do
        if package_known(self,"isEnemy",p) then return p end
    end
    return nil
end



local ny_10th_chongxu_skill = {}
ny_10th_chongxu_skill.name = "ny_10th_chongxu"
table.insert(package_skills, ny_10th_chongxu_skill)
ny_10th_chongxu_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyMark","&ny_10th_huiling_ling") < 4 then return end
    if package_known(self.player,"getStrategyMark","@ny_10th_chongxu_mark") == 0 then return end
    return source_construct(self,"#ny_10th_chongxu:.:")
end

sgs.ai_skill_use_func["#ny_10th_chongxu"] = function(card,use,self,request)
    use.card = card
end



sgs.ai_skill_playerchosen.taji = function(self, targets)
    local players = sgs.QList2Table(targets)
    package_call(self,"sort",players, "defense")
    for _,p in ipairs(players) do
        if package_known(self,"isEnemy",p) then return p end
    end
    return nil
end



sgs.ai_skill_invoke.ny_10th_qinghuang = function(self, data)
    if package_known(self.player,"isWounded") and (package_known(self.player,"getMaxHp") > 4) then
        return true
    end
    return false
end



sgs.ai_skill_invoke.ny_10th_chenyong = function(self, data)
    return true
end



local ny_10th_jiuxian_skill = {}
ny_10th_jiuxian_skill.name = "ny_10th_jiuxian"
table.insert(package_skills, ny_10th_jiuxian_skill)
ny_10th_jiuxian_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getHandcardNum") == 0 then return end
    if package_known(self.player,"hasUsed","#ny_10th_jiuxian") then return end
    return source_construct(self,"#ny_10th_jiuxian:.:")
end

sgs.ai_skill_use_func["#ny_10th_jiuxian"] = function(card,use,self,request)
    local n = package_known(self.player,"getHandcardNum")
    n = math.ceil(n/2)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByKeepValue",cards)
    local usecards = {}
    for i = 1, n, 1 do
        table.insert(usecards, package_known(cards[i],"getEffectiveId"))
    end

    local duel = clone_native(self,"duel", sgs.Card_SuitToBeDecided, -1)

    local usec = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",duel, usec)
    if usec.card then
        local tos = {}
        for _,p in sgs.qlist(usec.to) do
            table.insert(tos, package_known(p,"objectName"))
        end
        local card_str = string.format("#ny_10th_jiuxian:%s:->%s", table.concat(usecards, "+"), table.concat(tos, "+"))
        local acard = source_construct(self,card_str)
        use.card = acard
        if use.to then use.to = usec.to end
    end
end

sgs.ai_skill_playerchosen.ny_10th_jiuxian = function(self, targets)
    local players = sgs.QList2Table(targets)
    package_call(self,"sort",players, "hp")
    for _,player in ipairs(players) do
        if package_known(self,"isFriend",player) then return player end
    end
    return nil
end

sgs.ai_playerchosen_intention.ny_10th_jiuxian = function(self, from, to)
	sgs.updateIntention(from, to, -80)
end

sgs.ai_use_priority.ny_10th_jiuxian = 4.8



local ny_tenth_jianzheng_skill = {}
ny_tenth_jianzheng_skill.name = "ny_tenth_jianzheng"
table.insert(package_skills, ny_tenth_jianzheng_skill)
ny_tenth_jianzheng_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#ny_tenth_jianzheng") then return end
    return source_construct(self,"#ny_tenth_jianzheng:.:")
end

sgs.ai_skill_use_func["#ny_tenth_jianzheng"] = function(card,use,self,request)
    package_call(self,"sort",self.enemies, "handcard")
    self.enemies = sgs.reverse(self.enemies)
    for _,enemy in ipairs(self.enemies) do
        if (not package_known(enemy,"isKongcheng")) then
            use.card = card
            if use.to then package_call(use.to,"append",enemy) end
            return
        end
    end
end

ai_skill_use["@@ny_tenth_jianzheng"]=function(self,prompt,request)
    local target = nil
    for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if package_known(p,"getStrategyFlag","ny_tenth_jianzheng_target") then
            target = p
            break
        end
    end

    local cards = sgs.QList2Table(package_known(target,"getHandcards"))
    package_call(self,"sortByUseValue",cards, true)
    for _,card in ipairs(cards) do

        local use = {isDummy=true,to=sgs.SPlayerList()}
        package_call(self,"useCardByClassName",card, use)
        if use.to and package_known(use.to,"length") > 0 then
            local tos = {}
            for _,p in sgs.qlist(use.to) do
                table.insert(tos, package_known(p,"objectName"))
            end
            local card_str = string.format("#ny_tenth_jianzheng_use:%s:->%s", package_known(card,"getEffectiveId"), table.concat(tos, "+"))
            return card_str
        end
    end
end

sgs.ai_use_priority.ny_tenth_jianzheng = 6.8
sgs.ai_card_intention.ny_tenth_jianzheng = 50



sgs.ai_skill_playerschosen.ny_10th_fumou = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local residue = max
    if not package_known(self.room,"canMoveField","ej") then
        local can_choose = sgs.QList2Table(targets)
        package_call(self,"sort",targets, "handcard")
        targets = sgs.reverse(targets)
        for _,p in ipairs(targets) do
            if package_known(self,"isEnemy",p) and package_known(p,"getHandcardNum") > 3 then
                package_call(selected,"append",p)
                residue = residue - 1
            end
            if package_known(self,"isFriend",p) and package_known(p,"getHandcardNum") < 2 then
                package_call(selected,"append",p)
                residue = residue - 1
            end
            if residue <= 0 then return selected end
        end
    else
        local from, card, to = package_call(self,"moveField")
	    if from and card and to then
            package_call(selected,"append",self.player)
            residue = residue - 1
        end
        if residue <= 0 then return selected end

        if ((package_known(self,"getCardsNum","Peach") == 0 and package_known(self.player,"getEquips"):length() > 0)
        or (package_known(self.player,"getEquips"):length() == 1)
        or (package_known(self.player,"getHp") == 1))
        and ( not package_known(selected,"contains",self.player))
        and package_known(self.player,"isWounded") then
            package_call(selected,"append",self.player)
            residue = residue - 1
        end
        if residue <= 0 then return selected end

        local can_choose = sgs.QList2Table(targets)
        for _,target in ipairs(can_choose) do
            if not package_known(selected,"contains",target) then
                if package_known(self,"isFriend",target) then
                    if package_known(target,"isWounded") and package_known(target,"getEquips"):length() > 0
                    and ((package_known(target,"getHp") == 1) or (package_known(target,"getEquips"):length() == 1)) then
                        package_call(selected,"append",target)
                        residue = residue - 1
                    elseif package_known(target,"getHandcardNum") <= 1 then
                        package_call(selected,"append",target)
                        residue = residue - 1
                    end
                end
            end
            if residue <= 0 then return selected end
        end
    end
    return selected
end



sgs.ai_skill_choice["ny_10th_fumou"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    if #items == 1 then return items[1] end
    if table.contains(items, "recover") then
        if package_known(self.player,"getHp") == 1 or package_known(self.player,"getEquips"):length() <= 2
        or package_known(self,"getCardsNum","Peach") == 0 then
            return "recover"
        end
    end
    if package_known(self.player,"getHandcardNum") > 4 then table.removeOne(items, "discard") end
    if table.contains(items, "move") then
        local from, card, to = package_call(self,"moveField")
	    if from and card and to then return "move" end
    end
    if package_known(self.player,"getHandcardNum") <= 2 then return "discard" end
    return items[math.random(1, #items)]
end



sgs.ai_skill_invoke.ny_10th_jiexing = true



sgs.ai_skill_invoke.ny_10th_sanshou = true



sgs.ai_skill_invoke.ny_10th_sijun = true



sgs.ai_skill_playerschosen.ny_10th_tianjie = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local n = max
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if package_known(self,"isEnemy",target) then
            package_call(selected,"append",target)
            n = n - 1
        end
        if n <= 0 then break end
    end
    return selected
end



sgs.ai_skill_invoke.ny_tenth_xianzhu = true

sgs.ai_skill_choice["ny_tenth_xianzhu"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    if table.contains(items, "ignore") then return "ignore" end
    if package_known(self.player,"getStrategyMark","SkillDescriptionArg2_ny_tenth_xianzhu") + 1 >= #self.enemies then
        table.removeOne(items, "targets")
    end
    return items[math.random(1, #items)]
end



ai_skill_use["@@ny_tenth_dagongche_slash"]=function(self,prompt,request)
    local slash = clone_native(self,"slash", sgs.Card_SuitToBeDecided, -1)
    package_call(slash,"setSkillName","_ny_tenth_dagongche")


    local use = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",slash, use)
    if use.to and package_known(use.to,"length") > 0 then
        local tos = {}
        for _,p in sgs.qlist(use.to) do
            table.insert(tos, package_known(p,"objectName"))
        end
        local card_str = string.format("#ny_tenth_dagongche_slash:.:->%s", table.concat(tos, "+"))
        return card_str
    end
end



sgs.ai_skill_invoke.ny_10th_quanji = true



local ny_10th_paiyi_skill = {}
ny_10th_paiyi_skill.name = "ny_10th_paiyi"
table.insert(package_skills, ny_10th_paiyi_skill)
ny_10th_paiyi_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getPile","ny_10th_quan"):length() <= 2 then return end
    local choices = {"draw", "damage"}
    for _,choice in ipairs(choices) do
        if package_known(self.player,"getStrategyMark","ny_10th_paiyi_tiansuan_remove_"..choice.."-PlayClear") == 0  then
            return source_construct(self,"#ny_10th_paiyi:.:"..choice)
        end
    end
end

sgs.ai_skill_use_func["#ny_10th_paiyi"] = function(card,use,self,request)
    local card_ids = sgs.QList2Table(package_known(self.player,"getPile","ny_10th_quan"))
    local choices = {"damage", "draw"}
    for _,choice in ipairs(choices) do
        if package_known(self.player,"getStrategyMark","ny_10th_paiyi_tiansuan_remove_"..choice.."-PlayClear") == 0  then
            if choice == "draw" then
                package_call(self,"sort",self.friends, "handcard")
                if #self.friends > 0 then
                    local card_str = string.format("#ny_10th_paiyi:%s:%s", card_ids[1], choice)
                    local acard = source_construct(self,card_str)
                    use.card = acard
                    if use.to then package_call(use.to,"append",self.friends[1]) end
                    return
                end
            end
            if choice == "damage" then
                package_call(self,"sort",self.enemies, "hp")
                local max = #card_ids - 1
                local targets = sgs.SPlayerList()
                if #self.enemies > 0 then
                    for _,enemy in ipairs(self.enemies) do
                        package_call(targets,"append",enemy)
                        max = max - 1
                        if max <= 0 then break end
                    end
                    if not package_known(targets,"isEmpty") then
                        if max > 0 and (package_known(self.player,"getHp") + package_known(self,"getCardsNum","Peach") > 2) then
                            package_call(targets,"append",self.player)
                        end
                        local card_str = string.format("#ny_10th_paiyi:%s:%s", card_ids[1], choice)
                        local acard = source_construct(self,card_str)
                        use.card = acard
                        if use.to then use.to = targets end
                        return
                    end
                end
            end
        end
    end
end

sgs.ai_use_priority.ny_10th_paiyi = 5.8



sgs.ai_skill_invoke.ny_10th_jingdianjianxiong = true



local ny_10th_jingdianzhiheng_skill = {}
ny_10th_jingdianzhiheng_skill.name = "ny_10th_jingdianzhiheng"
table.insert(package_skills,ny_10th_jingdianzhiheng_skill)
ny_10th_jingdianzhiheng_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"usedTimes","#ny_10th_jingdianzhiheng") < (1 + package_known(self.player,"getStrategyMark","&ny_10th_jingdianzhiheng-Clear")) then
    else return end
	return source_construct(self,"#ny_10th_jingdianzhiheng:.:")
end



sgs.ai_skill_use_func["#ny_10th_jingdianzhiheng"] = function(card,use,self,request)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))

	if package_known(self.player,"getHp")<3 then
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = source_fact(self,"JilveWansha","toBool")
		for _,zcard in sgs.list(package_known(self.player,"getCards","he"))do
			if not isCard("Peach",zcard,self.player)
			then
				local shouldUse = true
				if isCard("Slash",zcard,self.player)
				and not use_slash
				then

                    local dummy_use = {isDummy=true,to=sgs.SPlayerList()}
                    package_call(self,"useCardByClassName",zcard, dummy_use)

					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.list(dummy_use.to)do
								if package_known(p,"getHp")<=1 then
									shouldUse = false
									if package_known(self.player,"distanceTo",p)>1 then keep_weapon = package_call(self.player,"getWeapon") end
									break
								end
							end
							if package_known(dummy_use.to,"length")>1 then shouldUse = false end
						end
						if not package_known(self,"isWeak") then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if package_known(zcard,"getTypeId")==sgs.Card_TypeTrick then
                    local dummy_use = {isDummy=true,to=sgs.SPlayerList()}
                    package_call(self,"useCardByClassName",zcard, dummy_use)

					if dummy_use.card then shouldUse = false end
				end
				if package_known(zcard,"getTypeId")==sgs.Card_TypeEquip and not package_known(self.player,"hasEquip",zcard) then
                    local dummy_use = {isDummy=true,to=sgs.SPlayerList()}
                    package_call(self,"useCardByClassName",zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and package_known(zcard,"getEffectiveId")==package_known(keep_weapon,"getEffectiveId") then shouldUse = false end
				end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","Armor") and not package_known(self,"needToThrowArmor") then shouldUse = false end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","DefensiveHorse") and not package_known(self,"needToThrowArmor") then shouldUse = false end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","WoodenOx") and package_known(self.player,"getPile","wooden_ox"):length()>1 then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if package_known(self.player,"getHp")<2 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards,package_known(zcard,"getId")) end
			end
		end
	end

	if #unpreferedCards<1 then
		local use_slash_num = 0
		package_call(self,"sortByKeepValue",cards)
		for _,card in ipairs(cards)do
			if package_known(card,"isKindOf","Slash") then
				local will_use = false
				if use_slash_num<=correct_target(self,"Residue",card)
				then
                    local dummy_use = {isDummy=true,to=sgs.SPlayerList()}
                    package_call(self,"useCardByClassName",card, dummy_use)

					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num+1
					end
				end
				if not will_use then table.insert(unpreferedCards,package_known(card,"getId")) end
			end
		end

		local num = package_known(self,"getCardsNum","Jink")-1
		if package_call(self.player,"getArmor") then num = num+1 end
		if num>0 then
			for _,card in ipairs(cards)do
				if package_known(card,"isKindOf","Jink") and num>0 then
					table.insert(unpreferedCards,package_known(card,"getId"))
					num = num-1
				end
			end
		end
		for _,card in ipairs(cards)do
			if package_known(card,"isKindOf","Weapon") and package_known(self.player,"getHandcardNum")<3
			or package_known(self,"getSameEquip",card,self.player)
			or package_known(card,"isKindOf","OffensiveHorse")
			or package_known(card,"isKindOf","AmazingGrace")
			then table.insert(unpreferedCards,package_known(card,"getId"))
			elseif package_known(card,"getTypeId")==sgs.Card_TypeTrick then
                local dummy_use = {isDummy=true,to=sgs.SPlayerList()}
                    package_call(self,"useCardByClassName",card, dummy_use)
				if not dummy_use.card then table.insert(unpreferedCards,package_known(card,"getId")) end
			end
		end

		if package_call(self.player,"getWeapon") and package_known(self.player,"getHandcardNum")<3 then
			table.insert(unpreferedCards,package_call(self.player,"getWeapon"):getId())
		end

		if package_known(self,"needToThrowArmor") then
			table.insert(unpreferedCards,package_call(self.player,"getArmor"):getId())
		end

		if package_known(self.player,"getOffensiveHorse") and package_call(self.player,"getWeapon") then
			table.insert(unpreferedCards,package_known(self.player,"getOffensiveHorse"):getId())
		end
	end

	for i = #unpreferedCards,1,-1 do
		if disclosed_card(self,unpreferedCards[i]):isKindOf("WoodenOx") and package_known(self.player,"getPile","wooden_ox"):length()>1 then
			table.removeOne(unpreferedCards,unpreferedCards[i])
		end
	end

	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not package_known(self.player,"isJilei",disclosed_card(self,unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

    if #use_cards>0 then
		local card_str = string.format("#ny_10th_jingdianzhiheng:%s:", table.concat(use_cards,"+"))
		local acard = source_construct(self,card_str)
        use.card = acard
	end
end

sgs.ai_use_value.ny_10th_jingdianzhiheng = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority.ny_10th_jingdianzhiheng = sgs.ai_use_priority.ZhihengCard
sgs.dynamic_value.benefit.ny_10th_jingdianzhiheng = sgs.dynamic_value.benefit.ZhihengCard



local ny_tenth_jingdianrende_skill = {}
ny_tenth_jingdianrende_skill.name = "ny_tenth_jingdianrende"
table.insert(package_skills,ny_tenth_jingdianrende_skill)
ny_tenth_jingdianrende_skill.getTurnUseCard = function(self,inclusive,request)
	return source_construct(self,"#ny_tenth_jingdianrende:.:")
end

sgs.ai_skill_use_func["#ny_tenth_jingdianrende"] = function(card,use,self,request)
    package_call(self,"sort",self.enemies, "handcard")
    for _,enemy in ipairs(self.enemies) do
        if package_known(enemy,"getHandcardNum") > 0 and package_known(enemy,"getStrategyMark","ny_tenth_jingdianrende_get-PlayClear") == 0 then
            if use.to then package_call(use.to,"append",enemy) end
            use.card = card
            return
        end
    end
end

sgs.ai_skill_choice["ny_tenth_jingdianrende"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    if #items == 1 then return items[1] end
    if package_known(self.player,"getLostHp") > 1 then return "peach" end
    table.removeOne(items, "cancel")
    for _,pattern in ipairs(items) do
        local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        package_call(self,"useCardByClassName",card, usec)
        if usec.to and package_known(usec.to,"length") > 0 then
            return pattern
        end
    end
    return "cancel"
end

ai_skill_use["@@ny_tenth_jingdianrende"]=function(self,prompt,request)
    local pattern = source_property(self,"ny_tenth_jingdianrende_card"):toString()

    if pattern == "peach" or pattern == "analeptic" then
        return string.format("#ny_tenth_jingdianrende_basic:.:->%s", package_known(self.player,"objectName"))
    end

	local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
	package_call(card,"setSkillName","ny_tenth_jingdianrende")
    local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
    local usec = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, usec)
    if usec.to and package_known(usec.to,"length") > 0 then
        local tos = {}
        for _,to in sgs.qlist(usec.to) do
            table.insert(tos, package_known(to,"objectName"))
        end
        local card_str = string.format("#ny_tenth_jingdianrende_basic:.:->%s", table.concat(tos, "+"))
        return card_str
    end
    return "."
end

sgs.ai_use_priority.ny_tenth_jingdianrende = 8.8
sgs.ai_use_value.ny_tenth_jingdianrende = 10.8



sgs.ai_skill_invoke.ny_tenth_huishu = true



sgs.ai_skill_choice["ny_10th_yishu"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    for _,item in ipairs(items) do
        if string.find(item, "draw") then return item end
    end
    for _,item in ipairs(items) do
        if string.find(item, "discard") then return item end
    end
    return items[math.random(1,#items)]
end



sgs.ai_skill_choice["ny_10th_ligong"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    if #items > 1 then
        table.removeOne(items, "cancel")
    end
    return items[math.random(1,#items)]
end



sgs.ai_skill_discard.ny_10th_jiqiao = function(self,max,min)
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    local peach = 0
    local analeptic = 0
    local slash = 0
    local discards = {}
    for _,card in ipairs(cards) do
        if package_known(card,"isKindOf","EquipCard") then
            if package_known(card,"isKindOf","Weapon") and package_call(self.player,"getWeapon")
            and package_call(self.player,"getWeapon"):getEffectiveId() ~= package_known(card,"getEffectiveId") then
                table.insert(discards, package_known(card,"getEffectiveId"))
            elseif (not package_known(card,"isKindOf","Weapon")) then
                table.insert(discards, package_known(card,"getEffectiveId"))
            end
        end
        if package_known(card,"isKindOf","Peach") then
            if peach < (package_known(self.player,"getLostHp") + 1) then
                peach = peach + 1
            else
                table.insert(discards, package_known(card,"getEffectiveId"))
            end
        end
        if package_known(card,"isKindOf","Analeptic") then
            if analeptic < 1 then
                analeptic = analeptic + 1
            else
                table.insert(discards, package_known(card,"getEffectiveId"))
            end
        end
        if package_known(card,"isKindOf","Slash") then
            local limit = 1 + source_error("TargetModSkill.Residue")
            if slash < limit then
                slash = slash + 1
            else
                table.insert(discards, package_known(card,"getEffectiveId"))
            end
        end
        if package_known(card,"objectName") == "collateral" then
            table.insert(discards, package_known(card,"getEffectiveId"))
        end
    end
    return discards
end



sgs.ai_skill_invoke.ny_10th_zhongji = function(self, data)
    local draw = package_known(self.player,"getMaxHp") - package_known(self.player,"getHandcardNum")
    local dis = 1 + package_known(self.player,"getStrategyMark","&ny_10th_zhongji-Clear")
    if package_known(self.player,"getPhase") == sgs.Player_NotActive then
        return draw >= dis
    else
        return draw >= (dis + 1)
    end
end



local ny_10th_lvecheng_skill = {}
ny_10th_lvecheng_skill.name = "ny_10th_lvecheng"
table.insert(package_skills,ny_10th_lvecheng_skill)
ny_10th_lvecheng_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self,"getCardsNum","Slash") < 1 then return end
    if package_known(self.player,"hasUsed","#ny_10th_lvecheng") then return end
	return source_construct(self,"#ny_10th_lvecheng:.:")
end

sgs.ai_skill_use_func["#ny_10th_lvecheng"] = function(card,use,self,request)
    package_call(self,"sort",self.enemies, "defense")
    for _,enemy in ipairs(self.enemies) do
        if package_known(self.player,"canSlash",enemy) then
            if use.to then package_call(use.to,"append",enemy) end
            use.card = card
            return
        end
    end
end

sgs.ai_skill_invoke.ny_10th_lvecheng = function(self, data)
    local target
    for _,other in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if package_known(other,"hasFlag","ny_10th_lvecheng") then
            target = other
            break
        end
    end
    return target and package_known(self,"isEnemy",target)
end



sgs.ai_skill_invoke.ny_tenth_fuxue = function(self, data)
    return true
end

ai_skill_use["@@ny_tenth_fuxue"]=function(self,prompt,request)
    local n = package_known(self.player,"getHp")
    local card_ids = source_fact(self,"ny_tenth_fuxue_cards","toIntList")
    local cards = {}
    for _,id in sgs.qlist(card_ids) do
        table.insert(cards, disclosed_card(self,id))
    end
    package_call(self,"sortByUseValue",cards)
    local get = {}
    for _,card in ipairs(cards) do
        table.insert(get, package_known(card,"getEffectiveId"))
        n = n - 1
        if n <= 0 then break end
    end
    if #get > 0 then
        return string.format("#ny_tenth_fuxue:%s:", table.concat(get, "+"))
    end
    return "."
end



local ny_10th_shoutan_skill = {}
ny_10th_shoutan_skill.name = "ny_10th_shoutan"
table.insert(package_skills, ny_10th_shoutan_skill)
ny_10th_shoutan_skill.getTurnUseCard = function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#ny_10th_shoutan") then
        if (not package_known(self.player,"hasSkill","ny_10th_yaoyi"))
        and package_known(self.player,"getHandcardNum") < package_known(self.player,"getMaxCards") then return end
		return source_construct(self,"#ny_10th_shoutan:.:")
	end
end

sgs.ai_skill_use_func["#ny_10th_shoutan"] = function(card,use,self,request)
	if package_known(self.player,"hasSkill","ny_10th_yaoyi") then
		use.card = card
	else
		local usecard = nil
		local handcards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		package_call(self,"sortByUseValue",handcards)
		if package_known(self.player,"getChangeSkillState","ny_10th_shoutan") <= 1 then
			for _,cc in ipairs(handcards) do
				if not package_known(cc,"isBlack") then
					usecard = package_known(cc,"getEffectiveId")
					break
				end
			end
		else
			for _,cc in ipairs(handcards) do
				if package_known(cc,"isBlack") then
					usecard = package_known(cc,"getEffectiveId")
					break
				end
			end
		end
		if usecard then
			local card_str = "#ny_10th_shoutan:"..usecard..":"
			local acard = source_construct(self,card_str)
			assert(acard)
			use.card = acard
		end
	end
end



sgs.ai_skill_invoke.ny_10th_sujun = true



local ny_10th_lifeng_skill = {}
ny_10th_lifeng_skill.name = "ny_10th_lifeng"
table.insert(package_skills, ny_10th_lifeng_skill)
ny_10th_lifeng_skill.getTurnUseCard = function(self,inclusive,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByKeepValue",cards)
	for _,card in ipairs(cards) do do
        if package_known(self.player,"getStrategyMark",package_known(card,"getColorString").."ny_10th_lifeng-Clear")>0 then goto package_continue_5 end

		local slash = clone_native(self,"slash")
            package_call(slash,"addSubcard",card)
            package_call(slash,"setSkillName","ny_10th_lifeng")
            package_call(slash,"deleteLater")

            local usec = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",slash, usec)
            if usec.card then
			return slash
            end
        end ::package_continue_5:: end
    end

sgs.ai_skill_use_func["#ny_10th_lifeng"] = function(card,use,self,request)
	use.card = card
    if use.to then use.to = self.ny_10th_lifeng_to end
end

sgs.ai_view_as.ny_10th_lifeng = function(card, player, card_place)
 local self=actor_ai(player)
	if card_place == sgs.Player_PlaceHand then
        if package_known(player,"getStrategyMark",package_known(card,"getColorString").."ny_10th_lifeng-Clear")>0 then return end
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
		if ambient_pattern(self)=="nullification" then
            return ("nullification:ny_10th_lifeng[%s:%s]=%d"):format(suit, number, card_id)
		else
			return ("slash:ny_10th_lifeng[%s:%s]=%d"):format(suit, number, card_id)
        end
	end
end

sgs.ai_use_priority.ny_10th_lifeng = 8.8



sgs.ai_skill_playerchosen.ny_10th_jxqiangzhi = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if package_known(self,"isEnemy",target) then
			return target
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention.ny_10th_jxqiangzhi = function(self, from, to)
	sgs.updateIntention(from, to, 10)
end



sgs.ai_skill_invoke.ny_10th_jxxiantu = function(self, data)
    local peach = package_known(self,"getCardsNum","Peach")
    local target
    for _,player in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
        if package_known(player,"getPhase") == sgs.Player_Play then
            target = player
            break
        end
    end
    if not target then return false end
    if package_known(self,"isFriend",target) and ((package_known(self.player,"getHp") >= 2) or (peach > 0)) then
        return true
    else
        return false
    end
end

sgs.ai_skill_discard.ny_10th_jxxiantu = function(self,max,min)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByUseValue",cards)
    local n = max
    local give = {}
    for _,card in ipairs(cards) do
        table.insert(give, package_known(card,"getEffectiveId"))
        n = n - 1
        if n <= 0 then break end
    end
    if n > 0 then
        for _,card in sgs.qlist(package_known(self.player,"getCards","e")) do
            table.insert(give, package_known(card,"getEffectiveId"))
            n = n - 1
            if n <= 0 then break end
        end
    end
    return give
end



sgs.ai_skill_invoke.ny_tenth_shanjia = true

ai_skill_use["@@ny_tenth_shanjia"]=function(self,prompt,request)
    local slash = clone_native(self,"slash", sgs.Card_SuitToBeDecided, -1)
    package_call(slash,"setSkillName","ny_tenth_shanjia")
    package_call(slash,"deleteLater")

    local usec = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",slash, usec)
    if usec.card then
        local tos = {}
        for _,to in sgs.qlist(usec.to) do
            table.insert(tos, package_known(to,"objectName"))
        end
        return selected(self,slash,tos)
    end
end



sgs.ai_skill_invoke.ny_10th_poyuan = true

sgs.ai_skill_choice["ny_10th_poyuan"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    return items[#items]
end

sgs.ai_skill_playerchosen.ny_10th_poyuan = function(self, targets)
    local all = sgs.QList2Table(targets)
    package_call(self,"sort",all, "defense")
    for _,target in ipairs(all) do
        if package_known(self,"isEnemy",target) then
            return target
        end
    end
    return nil
end



local ny_10th_huace_skill = {}
ny_10th_huace_skill.name = "ny_10th_huace"
table.insert(package_skills, ny_10th_huace_skill)
ny_10th_huace_skill.getTurnUseCard = function(self,inclusive,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByKeepValue",cards, true)
    if #cards == 0 then return end
    if package_known(self.player,"hasUsed","#ny_10th_huace") then return false end
    local huace_patterns = room_tag(self,"ny_10th_huace_cards"):split("+")

	for _,pattern in ipairs(huace_patterns) do
        local canuse = false
        local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
        package_call(card,"addSubcard",cards[1])
        package_call(card,"setSkillName","ny_10th_huace")
        package_call(card,"deleteLater")

        local mark = string.format("ny_10th_huace_guhuo_remove_%s_lun", pattern)
        if package_known(self.player,"getStrategyMark",mark) == 0 and package_known(card,"isAvailable",self.player) then
            canuse = true
        end

        local cc = prototype_clone(self,"#ny_10th_huace")
        package_call(cc,"addSubcard",cards[1])
        package_known(cc,"setUserString",pattern)

        if canuse then
            local usec = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",card, usec)
            if usec.card and (not (package_known(card,"canRecast") and package_known(usec.to,"length") < 1)) then
                source_state(self).ny_10th_huace_to = usec.to

                local card_str = package_known(cc,"toString")
                return source_construct(self,card_str)
            end
        end
    end
end

sgs.ai_skill_use_func["#ny_10th_huace"] = function(card,use,self,request)
	use.card = card
    if use.to then use.to = source_state(self).ny_10th_huace_to end
end

sgs.ai_use_priority.ny_10th_huace = 6.8



sgs.ai_skill_invoke.ny_10th_huizhi = true

sgs.ai_skill_discard.ny_10th_huizhi = function(self, max, min)
    local max = 0
    for _,target in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if package_known(target,"getHandcardNum") > max then max = package_known(target,"getHandcardNum") end
    end
    if max < package_known(self.player,"getHandcardNum") then return {} end
    local discard = {}
    local candis = package_known(self.player,"getHandcardNum") - (max - 5)
    if candis <= 0 then return {} end
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByKeepValue",cards)
    local max = 3
    for _,card in ipairs(cards) do
        table.insert(discard, package_known(card,"getEffectiveId"))
        candis = candis - 1
        max = max - 1
        if candis <= 0 then break end
        if max <= 0 then break end
    end
    return candis
end



local ny_10th_jijiao_skill = {}
ny_10th_jijiao_skill.name = "ny_10th_jijiao"
table.insert(package_skills, ny_10th_jijiao_skill)
ny_10th_jijiao_skill.getTurnUseCard = function(self,inclusive,request)
    local ids = source_fact(self,"ny_10th_jijiao_cards","toIntList")
    if (not ids) or package_known(ids,"isEmpty") then return end
    local n = package_known(ids,"length")
    if package_known(self.player,"getStrategyMark","ny_10th_jijiao_new-Clear") == 0 then
        if n < 4 then return end
        if math.random(1,3) == 1 and n < 8 then return end
    end
    if package_known(self.player,"getStrategyMark","@ny_10th_jijiao_mark") == 0 then return end
    return source_construct(self,"#ny_10th_jijiao:.:")
end

sgs.ai_skill_use_func["#ny_10th_jijiao"] = function(card,use,self,request)
    use.card = card
    if use.to then package_call(use.to,"append",self.player) end
end



sgs.ai_skill_choice["ny_10th_qingbei"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    if #items > 4 then
        table.removeOne(items, "cancel")
    elseif #items == 4 and math.random(1, 2) == 1 then
        return "cancel"
    else
        return "cancel"
    end
    return items[math.random(1,#items)]
end



sgs.ai_skill_invoke.ny_10th_jiudun = function(self, data)
    return true
end

sgs.ai_skill_discard.ny_10th_jiudun = function(self, max, min)
    if package_known(self.player,"isKongcheng") then return {} end
    local use = room_tag(self,"ny_10th_jiudun_card")



    if package_known(use.card,"isKindOf","Analeptic") or package_known(use.card,"isKindOf","Peach") then return {} end

    local notc = {"ex_nihilo","amazing_grace","god_salvation", "iron_chain"}
    if table.contains(notc, package_known(use.card,"objectName")) then return {} end
    if package_known(use.card,"isKindOf","EquipCard") then return {} end

    local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)
    local dis = {}
    table.insert(dis, package_known(cards[1],"getEffectiveId"))
    return dis
end



sgs.ai_skill_invoke.ny_10th_zhaowen = function(self, data)
    return true
end

local function shuffle_zhaowen(t)
    if type(t)~="table" then
        return
    end
    local tab={}
    local index=1
    while #t~=0 do
        local n=math.random(0,#t)
        if t[n]~=nil then
            tab[index]=t[n]
            table.remove(t,n)
            index=index+1
        end
    end
    return tab
end

local ny_10th_zhaowen_skill = {}
ny_10th_zhaowen_skill.name = "ny_10th_zhaowen"
table.insert(package_skills, ny_10th_zhaowen_skill)
ny_10th_zhaowen_skill.getTurnUseCard = function(self,inclusive,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))

    package_call(self,"sortByUseValue",cards, true)
    if #cards == 0 then return end

    local use_card
    for _,card in ipairs(cards) do
        if package_known(card,"hasFlag","ny_10th_zhaowen") and package_known(card,"isBlack") then
            use_card = card
            break
        end
    end

    if not use_card then return end

    local zhaowen_patterns = room_tag(self,"ny_10th_zhaowen_cards"):split("+")
    local rand_patterns = shuffle_zhaowen(zhaowen_patterns)

	for _,pattern in ipairs(rand_patterns) do
        local canuse = false
        local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
        package_call(card,"addSubcard",cards[1])
        package_call(card,"setSkillName","ny_10th_zhaowen")
        package_call(card,"deleteLater")

        local mark = string.format("ny_10th_zhaowen_guhuo_remove_%s-Clear", pattern)
        if package_known(self.player,"getStrategyMark",mark) == 0 and package_known(card,"isAvailable",self.player) then
            canuse = true
        end

        local cc = prototype_clone(self,"#ny_10th_zhaowen")
        package_call(cc,"addSubcard",use_card)
        package_known(cc,"setUserString",pattern)

        if canuse then
            local usec = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",card, usec)
            if usec.card and (not (package_known(card,"canRecast") and package_known(usec.to,"length") < 1)) then
                source_state(self).ny_10th_zhaowen_to = usec.to

                local card_str = package_known(cc,"toString")
                return source_construct(self,card_str)
            end
        end
    end
end

sgs.ai_skill_use_func["#ny_10th_zhaowen"] = function(card,use,self,request)
	use.card = card
    if use.to then use.to = source_state(self).ny_10th_zhaowen_to end
end

sgs.ai_use_priority.ny_10th_zhaowen = 6
sgs.ai_use_value.ny_10th_zhaowen = 5



sgs.ai_skill_playerchosen.ny_10th_geyuan = function(self,targets)
    if package_known(self.player,"getStrategyFlag","ny_10th_gusuan_draw") then
        package_call(self,"sort",self.friends, "handcard")
        return self.friends[1]
    end
    if package_known(self.player,"getStrategyFlag","ny_10th_gusuan_discard") then
        local all = {}
        for _,target in sgs.qlist(targets) do
            if package_known(self,"isEnemy",target) and (not package_known(target,"isNude")) then
                table.insert(all, target)
            end
        end
        if #all > 0 then
            local max = -1
            local target
            package_call(self,"sort",all, "defense")
            for _,p in ipairs(all) do
                local value = math.min(4, package_known(p,"getCardCount"))
                if value > max then
                    target = p
                    max = value
                end
            end
            return target
        end
    end
    if package_known(self.player,"getStrategyFlag","ny_10th_gusuan_change") then
        local max = -9999
        local re
        for _,target in sgs.qlist(targets) do
            local value = 0
            if package_known(self,"isEnemy",target) and (not package_known(target,"isKongcheng")) then
                value = package_known(target,"getHandcardNum") - 5
            elseif package_known(self,"isFriend",target) and (not package_known(target,"isKongcheng")) then
                value = 5 - package_known(target,"getHandcardNum")
            end
            if value > max then
                max = value
                re = target
            end
        end
        return re
    end
    return nil
end



local ny_tenth_shujian_skill = {}
ny_tenth_shujian_skill.name = "ny_tenth_shujian"
table.insert(package_skills, ny_tenth_shujian_skill)
ny_tenth_shujian_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"isKongcheng") then return end
    if package_known(self.player,"usedTimes","#ny_tenth_shujian") >= 3 then return end
    if package_known(self.player,"getStrategyMark","ny_tenth_shujian_failed-PlayClear") > 0 then return end
    if #self.friends_noself <= 0 then return end
	return source_construct(self,"#ny_tenth_shujian:.:")
end

sgs.ai_skill_use_func["#ny_tenth_shujian"] = function(card,use,self,request)
    package_call(self,"sort",self.friends_noself, "defense")
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    if #cards <= 2 then return end


    package_call(self,"sortByKeepValue",cards)

    local card_str = string.format("#ny_tenth_shujian:%s:",package_known(cards[1],"getEffectiveId"))
    local acard = source_construct(self,card_str)
    use.card = acard
    if use.to then package_call(use.to,"append",self.friends_noself[1]) end
end

sgs.ai_skill_choice["ny_tenth_shujian"] = function(self, choices, data)
    local target = package_call(data,"toPlayer")
	local items = package_known(choices,"split","+")
    if target and package_known(self,"isFriend",target) and package_known(target,"getStrategyMark","ny_tenth_shujian-PlayClear") <= 1 then
        for _,item in ipairs(items) do
            if string.find(item, "draw") then return item end
        end
    end
    if (not target) or (target and package_known(self,"isEnemy",target)) then
        for _,item in ipairs(items) do
            if string.find(item, "dis") then return item end
        end
    end

    local card = clone_native(self,"dismantlement", sgs.Card_SuitToBeDecided, -1)
    package_call(card,"setSkillName","_ny_tenth_shujian")
    package_call(card,"deleteLater")
    local usec = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, usec)
    if usec.card then
        for _,item in ipairs(items) do
            if string.find(item, "dis") then return item end
        end
    end

    return items[math.random(1,#items)]
end

ai_skill_use["@@ny_tenth_shujian"]=function(self,prompt,request)
    local card = clone_native(self,"dismantlement", sgs.Card_SuitToBeDecided, -1)
    package_call(card,"setSkillName","_ny_tenth_shujian")
    package_call(card,"deleteLater")
    local usec = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, usec)
    if usec.card then
        local tos = {}
        for _,to in sgs.qlist(usec.to) do
            table.insert(tos, package_known(to,"objectName"))
        end
        return selected(self,card,tos)
    end
    return "."
end

sgs.ai_use_priority.ny_tenth_shujian = 6



sgs.ai_skill_invoke.ny_tenth_xiuwen = true



ai_skill_use["@@ny_tenth_longsong"]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    if #cards <= 0 then return false end
    local card

    package_call(self,"sortByUseValue",cards, true)
    for _,cc in ipairs(cards) do
        if package_known(cc,"isRed") then
            card = cc
            break
        end
    end
    if not card then return "." end

    if #self.friends_noself <= 0 then return "." end
    package_call(self,"sort",self.friends_noself, "defense")

    local target
    for _,p in ipairs(self.friends_noself) do
        local find = false
        local skills = package_known(p,"getVisibleSkillList")
        for _,s in sgs.qlist(skills) do
            local skillname = package_known(s,"objectName")
            if (not package_known(s,"isAttachedLordSkill")) and (not package_known(self.player,"hasSkill",skillname)) then
                local translation = package_known(s,"getDescription")
                if string.find(translation,"出牌阶段") then
                    find = true
                    break
                end
            end
        end
        if find then
            target = p
            break
        end
    end
    if (not target) and #cards <= 3 then return "." end
    if (not target) then target = self.friends_noself[1] end
    local card_str = string.format("#ny_tenth_longsong:%s:->%s", package_known(card,"getEffectiveId"), package_known(target,"objectName"))
    return card_str
end



sgs.ai_skill_invoke.ny_tenth_niji = true

ai_skill_use["@@ny_tenth_niji"]=function(self,prompt,request)
    local cards = {}
    for _,card in sgs.qlist(package_known(self.player,"getCards","h")) do
        if package_known(card,"hasTip","ny_tenth_niji") then
            table.insert(cards, card)
        end
    end
    if #cards <= 0 then return "." end
    package_call(self,"sortByUseValue",cards)

    for _,card in ipairs(cards) do
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        package_call(self,"useCardByClassName",card, usec)
        if usec.card then
            local tos = {}
            for _,to in sgs.qlist(usec.to) do
                table.insert(tos, package_known(to,"objectName"))
            end
            return selected(self,card,tos)
        end
    end

    return "."
end



sgs.ai_skill_discard.ny_tenth_shizong = function(self,max,min)
    local target = source_fact(self,"ny_tenth_shizong_from","toPlayer")
    if not package_known(self,"isFriend",target) then return {} end
    if package_known(self.player,"isNude") then return {} end
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))

    package_call(self,"sortByKeepValue",cards)
    return {package_known(cards[1],"getEffectiveId")}
end

ai_skill_use["@@ny_tenth_shizong!"]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))

    package_call(self,"sortByKeepValue",cards)
    local need = package_known(self.player,"getStrategyMark","&ny_tenth_shizong-Clear") + 1
    local give = {}
    for _,card in ipairs(cards) do
        table.insert(give, package_known(card,"getEffectiveId"))
        need = need - 1
        if need <= 0 then break end
    end

    local target
    if #self.friends_noself > 0 then
        package_call(self,"sort",self.friends_noself, "defense")
        target = self.friends_noself[1]
    end
    for _,friend in ipairs(self.friends_noself) do
        if package_known(friend,"getPhase") ~= sgs.Player_NotActive then
            target = friend
            break
        end
    end
    if not target then
        local all = sgs.QList2Table(package_known(self.room,"getOtherPlayers",self.player))
        target = all[math.random(1,#all)]
    end

    return string.format("#ny_tenth_shizong_give:%s:->%s", table.concat(give, "+"), package_known(target,"objectName"))
end

local ny_tenth_shizong_skill = {}
ny_tenth_shizong_skill.name = "ny_tenth_shizong"
table.insert(package_skills, ny_tenth_shizong_skill)
ny_tenth_shizong_skill.getTurnUseCard = function(self,inclusive,request)

    if package_known(self.player,"getStrategyMark","ny_tenth_shizong_disable-Clear") > 0 then return end
    if #self.friends_noself == 0 then return end
    local num = package_known(self.player,"getHandcardNum") + package_known(self.player,"getEquips"):length()
    local need = package_known(self.player,"getStrategyMark","&ny_tenth_shizong-Clear") + 1
    if num < need or need > 2 then return end

    local basics = {"peach", "analeptic", "thunder_slash", "slash", "fire_slash"}
    for _,basic in ipairs(basics) do
        local card = clone_native(self,basic, sgs.Card_SuitToBeDecided, -1)
        package_call(card,"setSkillName","ny_tenth_shizong")
        package_call(card,"deleteLater")

        local usec = {isDummy=true,to=sgs.SPlayerList()}
        package_call(self,"useCardByClassName",card, usec)
        if usec.card and package_known(self,"getCardsNum",package_known(card,"getClassName")) < 1 and package_known(card,"isAvailable",self.player) then
            source_state(self).ny_tenth_shizong_to = usec.to
            local cc = prototype_clone(self,"#ny_tenth_shizong")
            package_known(cc,"setUserString",basic)

            local card_str = package_known(cc,"toString")
            return source_construct(self,card_str)
        end
    end
end

sgs.ai_skill_use_func["#ny_tenth_shizong"] = function(card,use,self,request)
    use.card = card
    if use.to then use.to = source_state(self).ny_tenth_shizong_to end
end

sgs.ai_guhuo_card.ny_tenth_shizong = function(self,toname,class_name)
    if package_known(self.player,"getStrategyMark","ny_tenth_shizong_disable-Clear") > 0 then return end
    if #self.friends_noself == 0 then return end
    local num = package_known(self.player,"getHandcardNum") + package_known(self.player,"getEquips"):length()
    local need = package_known(self.player,"getStrategyMark","&ny_tenth_shizong-Clear") + 1
    if num < need or need > 2 then return end
    if owner_reason(self) ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return nil end
    if package_known(self,"getCardsNum",class_name) > 0 then return end

	local card = clone_native(self,toname, sgs.Card_SuitToBeDecided, -1)
    package_call(card,"deleteLater")
    if not package_known(card,"isKindOf","BasicCard") then return end

    local cc = prototype_clone(self,"#ny_tenth_shizong")
    package_known(cc,"setUserString",toname)
    return package_known(cc,"toString")
end

sgs.ai_use_priority.ny_tenth_shizong = 3



local ny_10th_beini_skill = {}
ny_10th_beini_skill.name = "ny_10th_beini"
table.insert(package_skills, ny_10th_beini_skill)
ny_10th_beini_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","#ny_10th_beini") then return end
    if #self.enemies == 0 then return end
	return source_construct(self,"#ny_10th_beini:.:")
end

sgs.ai_skill_use_func["#ny_10th_beini"] = function(card,use,self,request)
    package_call(self,"sort",self.enemies, "defense")
    use.card = card
    if #self.enemies > 1 then
        if use.to then
            package_call(use.to,"append",self.enemies[2])
            package_call(use.to,"append",self.enemies[1])
        end
    else
        if use.to then
            package_call(use.to,"append",self.player)
            package_call(use.to,"append",self.enemies[1])
        end
    end
end



sgs.ai_skill_playerchosen.ny_10th_yijia = function(self,targets)
    local name = source_fact(self,"ny_10th_yijia","toString")
    local target = package_call(self.room,"findPlayerByObjectName",name)
    if (not target) or (not package_known(self,"isFriend",target)) then return nil end
    local all = {}
    for _,p in sgs.qlist(targets) do
        if not package_known(self,"isFriend",p) then
            table.insert(all, p)
        end
    end
    if #all == 0 then return nil end
    package_call(self,"sort",all, "defense")
    for _,p in ipairs(all) do
        for _,card in sgs.qlist(package_known(p,"getEquips")) do
            local equip_index = package_known(card,"getEquipSlot")
            if package_known(target,"hasEquipArea",equip_index) and (not package_call(target,"getEquip",equip_index)) then
                return p
            end
        end
    end
    return all[1]
end

sgs.ai_skill_cardchosen.ny_10th_yijia = function(self, who,flags,reason,method)
    local enemy = who
    local name = source_fact(self,"ny_10th_yijia","toString")
    local target = package_call(self.room,"findPlayerByObjectName",name)
    if not target then
        local cards = sgs.QList2Table(package_known(enemy,"getCards","e"))

        for _,id in sgs.qlist(self.disabled_ids) do
            table.removeOne(cards, disclosed_card(self,id))
        end

        return package_known(cards[math.random(1,#cards)],"getEffectiveId")
    end

    for _,card in sgs.qlist(package_known(enemy,"getEquips")) do
        local equip_index = package_known(card,"getEquipSlot")
        if package_known(target,"hasEquipArea",equip_index) and (not package_call(target,"getEquip",equip_index)) then
            return package_known(card,"getEffectiveId")
        end
    end

    local cards = sgs.QList2Table(package_known(enemy,"getCards","e"))

    for _,id in sgs.qlist(self.disabled_ids) do
        table.removeOne(cards, disclosed_card(self,id))
    end

    return package_known(cards[math.random(1,#cards)],"getEffectiveId")
end



sgs.ai_skill_playerchosen.ny_tenth_dingji = function(self,targets)
    local max = -9999
    local maxtarget
    for _,target in sgs.qlist(targets) do
        local value
        if package_known(self,"isFriend",target) or package_known(target,"objectName") == package_known(self.player,"objectName") then
            value = 5.5 - package_known(target,"getHandcardNum")
            if package_known(target,"getHandcardNum") == 5 then value = -9999 end
        else
            value = package_known(target,"getHandcardNum") - 5
        end
        if (value > max) then
            max = value
            maxtarget = target
        end
    end
    return maxtarget
end

ai_skill_use["@@ny_tenth_dingji"]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    if #cards <= 0 then return "." end
    package_call(self,"sortByUseValue",cards)

    for _,handcard in ipairs(cards) do
        if package_known(handcard,"isNDTrick") or package_known(handcard,"isKindOf","BasicCard") then
            local card = clone_native(self,package_known(handcard,"objectName"), sgs.Card_SuitToBeDecided, -1)
            package_call(card,"setSkillName","_ny_tenth_dingji")
            package_call(card,"deleteLater")

            local usec = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",card, usec)
            if usec.card then
                local tos = {}
                for _,to in sgs.qlist(usec.to) do
                    table.insert(tos, package_known(to,"objectName"))
                end
                return selected(self,card,tos)
            end
        end
    end

    return "."
end



local ny_tenth_huahuo_skill = {}
ny_tenth_huahuo_skill.name = "ny_tenth_huahuo"
table.insert(package_skills, ny_tenth_huahuo_skill)
ny_tenth_huahuo_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#ny_tenth_huahuo") then return end
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByKeepValue",cards)
	for _,card in ipairs(cards) do
        if package_known(card,"isRed") then
            local slash = clone_native(self,"fire_slash", sgs.Card_SuitToBeDecided, -1)
            package_call(slash,"addSubcard",card)
            package_call(slash,"setSkillName","ny_tenth_huahuo")
            package_call(slash,"deleteLater")

            local usec = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",slash, usec)
            if usec.card then
                source_state(self).ny_tenth_huahuo_to = usec.to
                local card_str = string.format("#ny_tenth_huahuo:%s:", package_known(card,"getEffectiveId"))
                return source_construct(self,card_str)
            end
        end
    end
end

sgs.ai_skill_use_func["#ny_tenth_huahuo"] = function(card,use,self,request)
	use.card = card
    if use.to then use.to = source_state(self).ny_tenth_huahuo_to end
end

sgs.ai_skill_choice["ny_tenth_huahuo"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    if #items <= 1 then return "cancel" end
    local n = 0
    local card = clone_native(self,"fire_slash", sgs.Card_SuitToBeDecided, -1)
    package_call(card,"deleteLater")
    for _,other in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if (not package_known(other,"getPile","ny_tenth_xiaoyin"):isEmpty())
            and (not package_known(self.player,"isProhibited",other, card)) then
                if package_known(self,"isFriend",other) then n = n - 1.1
                else n = n + 1 end
        end
    end
    if n > 0 then return "change" end
    return "cancel"
end



sgs.ai_skill_invoke.ny_tenth_xiaoyin = true

ai_skill_use["@@ny_tenth_xiaoyin"]=function(self,prompt,request)
    local ids = source_fact(self,"ny_tenth_xiaoyin_tem","toIntList")
    if package_known(self.player,"getStrategyFlag","ny_tenth_xiaoyin_change") then
        local cards = {}
        for _,id in sgs.qlist(ids) do
            table.insert(cards, disclosed_card(self,id))
        end

        package_call(self,"sortByUseValue",cards)
        return string.format("#ny_tenth_xiaoyin_buff:%s:", package_known(cards[1],"getEffectiveId"))
    end
    if package_known(self.player,"getStrategyFlag","ny_tenth_xiaoyin_add") then
        local damage = source_fact(self,"ny_tenth_xiaoyin_buff","toDamage")
        if package_known(self,"isFriend",damage.to) or package_known(damage.to,"objectName") == package_known(self.player,"objectName") then return "." end

        local cards = {}
        for _,id in sgs.qlist(ids) do
            table.insert(cards, disclosed_card(self,id))
        end

        package_call(self,"sortByUseValue",cards, true)

        local selfcards = sgs.QList2Table(package_known(self.player,"getCards","he"))

        package_call(self,"sortByKeepValue",selfcards)

        for _,s in ipairs(selfcards) do
            for _,c in ipairs(cards) do
                local ctypes = {"BasicCard","TrickCard", "EquipCard"}
                for _,ctype in ipairs(ctypes) do
                    if package_known(s,"isKindOf",ctype) and package_known(c,"isKindOf",ctype) then
                        local card_str = string.format("#ny_tenth_xiaoyin_buff:%s+%s:",package_known(s,"getEffectiveId"),package_known(c,"getEffectiveId"))
                        return card_str
                    end
                end
            end
        end
        return "."
    end
    if #self.enemies == 0 then return "." end
    package_call(self,"sort",self.enemies,"defense")
    for _,id in sgs.qlist(ids) do
        local card = disclosed_card(self,id)
        if (not package_known(card,"hasFlag","ny_tenth_xiaoyin")) and package_known(card,"isBlack") then

            for _,target in ipairs(self.enemies) do
                local can = true

                local need = false
                for _,other in sgs.qlist(package_known(self.room,"getOtherPlayers",target)) do
                    if package_known(other,"hasFlag","ny_tenth_xiaoyin") then inneed = true end
                end

                if not need then
                    for _,other in sgs.qlist(package_known(self.room,"getOtherPlayers",target)) do
                        if package_known(other,"hasFlag","ny_tenth_xiaoyin") and package_known(target,"isAdjacentTo",other) then
                            can = true
                            break
                        end
                    end
                end

                if package_known(target,"getStrategyFlag","ny_tenth_xiaoyin") then can = false end

                if can then return string.format("#ny_tenth_xiaoyin:%s:->%s",id,package_known(target,"objectName")) end
            end
        end
    end
    return "."
end



sgs.ai_skill_invoke.ny_10th_yuandi = true

sgs.ai_skill_choice["ny_10th_yuandi"] = function(self, choices, data)
	local target = package_call(data,"toPlayer")
    if package_known(self,"isFriend",target) then
        return "draw="..package_known(target,"getGeneralName")
    else
        return "discard="..package_known(target,"getGeneralName")
    end
end



local ny_10th_xinyou_skill = {}
ny_10th_xinyou_skill.name = "ny_10th_xinyou"
table.insert(package_skills, ny_10th_xinyou_skill)
ny_10th_xinyou_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#ny_10th_xinyou") then return end
    return source_construct(self,"#ny_10th_xinyou:.:")
end

sgs.ai_skill_use_func["#ny_10th_xinyou"] = function(card,use,self,request)
	use.card = card
end



sgs.ai_skill_playerchosen.ny_10th_yingmou = function(self, targets)
    if package_known(self.player,"getStrategyFlag","ny_10th_yingmou_second_second") then
        for _,p in sgs.qlist(targets) do
            if not package_known(self,"isFriend",p) then return p end
        end
        local all = sgs.QList2Table(targets)
        return all[math.random(1,#all)]
    else
        local all = {}
        for _,p in sgs.qlist(targets) do
            if not package_known(self,"isFriend",p) then
                table.insert(all, p)
            end
        end
        if #all <= 0 then return nil end
        package_call(self,"sort",all, "defense")
        return all[1]
    end
end



sgs.ai_skill_invoke.ny_10th_zuowei = true

sgs.ai_skill_playerchosen.ny_10th_zuowei = function(self, targets)
    if #self.enemies <= 0 then return nil end
    package_call(self,"sort",self.enemies, "defense")
    return self.enemies[1]
end



local ny_10th_zigu_skill = {}
ny_10th_zigu_skill.name = "ny_10th_zigu"
table.insert(package_skills, ny_10th_zigu_skill)
ny_10th_zigu_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#ny_10th_zigu") then return end
    if #self.enemies <= 0 and package_known(self.player,"getEquips"):isEmpty() then return end
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    if (#cards <= 2) and package_known(self,"isWeak") then return end

    package_call(self,"sortByKeepValue",cards)
    return source_construct(self,"#ny_10th_zigu:"..package_known(cards[1],"getEffectiveId")..":")
end

sgs.ai_skill_use_func["#ny_10th_zigu"] = function(card,use,self,request)
    local target
    if #self.enemies > 0 then
        package_call(self,"sort",self.enemies, "defense")
        for _,enemy in ipairs(self.enemies) do
            if package_known(enemy,"getEquips"):length() > 0 then
                target = enemy
                break
            end
        end
    end
    if (not target) and (not package_known(self.player,"getEquips"):isEmpty()) then
        target = self.player
    end
	if target then
        use.card = card

    end
end

sgs.ai_skill_playerchosen.ny_10th_zigu = function(self, targets)
    local tos = sgs.QList2Table(targets)
    package_call(self,"sort",tos, "defense")
    for _,to in ipairs(tos) do
        if (not package_known(self,"isFriend",to)) then return to end
    end
    for _,to in ipairs(tos) do
        if package_known(to,"objectName") == package_known(self.player,"objectName") then return to end
    end
    return tos[math.random(1,#tos)]
end

sgs.ai_use_priority.ny_10th_zigu = 3



local ny_tenth_shuangbi_skill = {}
ny_tenth_shuangbi_skill.name = "ny_tenth_shuangbi"
table.insert(package_skills, ny_tenth_shuangbi_skill)
ny_tenth_shuangbi_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#ny_tenth_shuangbi") then return end
    return source_construct(self,"#ny_tenth_shuangbi:.:")
end

sgs.ai_skill_use_func["#ny_tenth_shuangbi"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_priority.ny_tenth_shuangbi = 6

sgs.ai_skill_choice["ny_tenth_shuangbi"] = function(self, choices, data)
    if package_known(data,"toInt") == 1 then
        if package_known(self,"isWeak") or package_known(self.player,"getHandcardNum") <= 2 then
            local item = string.format("draw=%s",package_known(self.room,"getAlivePlayers"):length())
            return item
        end
        local patterns = {"fire_slash", "fire_attack"}
        for _,pattern in ipairs(patterns) do
            local card = clone_native(self,pattern)
            package_call(card,"setSkillName","_ny_tenth_shuangbi_mouzhouyu")
            package_call(card,"deleteLater")
            local use = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",card, use)

            if use.card then return string.format("slash=%s",package_known(self.room,"getAlivePlayers"):length()) end
        end
        if (not package_known(self,"isWeak")) and (#self.friends_noself == 0) and (math.random(1,3) > 1)
        and (package_known(self.player,"getHandcardNum") > package_known(self.player,"getMaxCards")) then
            return string.format("damage=%s",package_known(self.room,"getAlivePlayers"):length())
        end
        return string.format("draw=%s",package_known(self.room,"getAlivePlayers"):length())
    else
        local patterns = {"fire_slash", "fire_attack"}
        for _,pattern in ipairs(patterns) do
            local card = clone_native(self,pattern)
            package_call(card,"setSkillName","_ny_tenth_shuangbi_mouzhouyu")
            package_call(card,"deleteLater")
            local use = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",card, use)

            if use.card then return pattern end
        end
        return "cancel"
    end
end

sgs.ai_skill_discard.ny_tenth_shuangbi = function(self,max,min)
    if #self.friends_noself > 0 then return {} end

    local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))

    package_call(self,"sortByKeepValue",cards)
    local need = max
    local discard = {}

    for _,c in ipairs(cards) do
        if package_known(self,"getUseValue",c) < sgs.ai_use_value.Slash then
            need = need - 1
            table.insert(discard, package_known(c,"getEffectiveId"))
        end
        if need <= 0 then break end
    end

    return discard
end

ai_skill_use["@@ny_tenth_shuangbi"]=function(self,prompt,request)
    local pattern = source_property(self,"ny_tenth_shuangbi_card"):toString()
    local card = clone_native(self,pattern)
    package_call(card,"setSkillName","_ny_tenth_shuangbi_mouzhouyu")
    package_call(card,"deleteLater")

    local use = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, use)
    if use.card then
        if use.to and package_known(use.to,"length") > 0 then
            local tos = {}
            for _,p in sgs.qlist(use.to) do
                table.insert(tos, package_known(p,"objectName"))
            end
            return "#ny_tenth_shuangbi_card:.:->"..table.concat(tos,"+")
        end
    end
    return "."
end



sgs.ai_skill_invoke.ny_10th_yinjun = function(self, data)
    local use = source_fact(self,"ny_10th_yinjun","toCardUse")
    local target = package_known(use.to,"at",0)
    return package_known(self,"isEnemy",target)
end



sgs.ai_skill_invoke.ny_10th_miyi = true

sgs.ai_skill_choice["ny_10th_miyi"] = function(self, choices, data)
    local damage = 0
    local recover = 0
    for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
        if package_known(self,"isEnemy",p) then
            if package_known(p,"getHp") <= 2 or package_known(self,"isWeak",p) then
                damage = damage + 1
            end
            if (not package_known(p,"isWounded")) then recover = recover + 2 end
        end
        if package_known(self,"isFriend",p) then
            if package_known(p,"isWounded") and (package_known(p,"objectName") == package_known(self.player,"objectName") or package_known(self,"isWeak",p)) then recover = recover + 1 end
        end
    end
    if damage >= recover then return "damage" end
    return "recover"
end

sgs.ai_skill_playerschosen.ny_10th_miyi = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    if package_known(self.player,"getStrategyFlag","ny_10th_miyi_damage") then
        for _,p in sgs.qlist(targets) do
            if package_known(self,"isEnemy",p) then package_call(selected,"append",p) end
        end
    else
        for _,p in sgs.qlist(targets) do
            if package_known(self,"isEnemy",p) and (not package_known(p,"isWounded")) then package_call(selected,"append",p) end
            if package_known(self,"isFriend",p) and package_known(p,"isWounded") then package_call(selected,"append",p) end
        end
    end
    return selected
end



sgs.ai_skill_playerchosen.ny_tenth_nuanhui = function(self, targets)
    local friends = {}
    for _,p in sgs.qlist(targets) do
        if package_known(self,"isFriend",p) then
            table.insert(friends, p)
        end
    end
    if #friends == 0 then return nil end
    package_call(self,"sort",friends, "defense")
    return friends[1]
end

sgs.ai_skill_choice["ny_tenth_nuanhui"] = function(self, choices, data)
    if package_known(self.player,"getStrategyMark","ny_tenth_nuanhui") > 1 then return "cancel" end
    local items = {"peach", "fire_slash", "thunder_slash", "slash"}
    for _,item in ipairs(items) do
        local card = clone_native(self,item, sgs.Card_SuitToBeDecided, -1)
        package_call(card,"deleteLater")
        if package_known(card,"isAvailable",self.player) then

            local use = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",card, use)
            if use.card then return item end
        end
    end
    return "cancel"
end

ai_skill_use["@@ny_tenth_nuanhui"]=function(self,prompt,request)
    local pattern = source_property(self,"ny_tenth_nuanhui_card"):toString()
    local card = clone_native(self,pattern)
    package_call(card,"setSkillName","ny_tenth_nuanhui")
    package_call(card,"deleteLater")

    local use = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, use)
    if use.card then
        local tos = {}
        for _,p in sgs.qlist(use.to) do
            table.insert(tos, package_known(p,"objectName"))
        end
        return selected(self,card,tos)
    end
    return "."
end



local ny_10th_qiongying_skill = {}
ny_10th_qiongying_skill.name = "ny_10th_qiongying"
table.insert(package_skills, ny_10th_qiongying_skill)
ny_10th_qiongying_skill.getTurnUseCard = function(self,inclusive,request)
    if not package_known(self.room,"canMoveField","ej") then return end
    if package_known(self.player,"hasUsed","#ny_10th_qiongying") then return end
    local from, card, to = package_call(self,"moveField")
    if from and card and to then else return false end
    return source_construct(self,"#ny_10th_qiongying:.:")
end

sgs.ai_skill_use_func["#ny_10th_qiongying"] = function(card,use,self,request)
    use.card = card
    local from, card, to = package_call(self,"moveField")
    if use.to then package_call(use.to,"append",from) end
end

sgs.ai_skill_playerchosen.ny_10th_qiongying = function(self, targets)
    local from, card, to = package_call(self,"moveField")
    if from and card and to then
        for _,target in sgs.qlist(targets) do
            if package_known(target,"objectName") == package_known(to,"objectName") then
                return target
            end
        end
    end
    local items = sgs.QList2Table(targets)
    return items[math.random(1, #items)]
end

sgs.ai_skill_cardchosen.ny_10th_qiongying = function(self, who,flags,reason,method)
    local from, card, to = package_call(self,"moveField")
    if from and card and to then
        return package_known(card,"getEffectiveId")
    end
    local cards = package_known(who,"getCards",flags)
    for _,card in sgs.qlist(cards) do
        if not package_known(self.disabled_ids,"contains",package_known(cards,"getEffectiveId")) then
            return package_known(card,"getEffectiveId")
        end
    end
end



local ny_10th_tongwei_skill = {}
ny_10th_tongwei_skill.name = "ny_10th_tongwei"
table.insert(package_skills, ny_10th_tongwei_skill)
ny_10th_tongwei_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#ny_10th_tongwei") then return end
    if package_known(self.player,"getCardCount") < 3 then return end
    if #self.enemies == 0 then return end
    return source_construct(self,"#ny_10th_tongwei:.:")
end

sgs.ai_skill_use_func["#ny_10th_tongwei"] = function(card,use,self,request)
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))

    package_call(self,"sortByUseValue",cards, true)
    local target
    package_call(self,"sort",self.enemies, "defense")
    for _,enemy in ipairs(self.enemies) do
        if package_known(enemy,"getStrategyMark","ny_10th_tongwei+"..package_known(self.player,"objectName")) == 0 then
            target = enemy
            break
        end
    end
    if target then
        local card_str = string.format("#ny_10th_tongwei:%s+%s:->%s", package_known(cards[1],"getEffectiveId"), package_known(cards[2],"getEffectiveId"), package_known(target,"objectName"))
        local acard = source_construct(self,card_str)
        use.card = acard
        if use.to then package_call(use.to,"append",target) end
    end
end

sgs.ai_skill_choice["ny_10th_tongwei"] = function(self, choices, data)
    local use = package_known(data,"toCardUse")
    local target = use.from
    if package_known(self,"isWeak",target) then return "slash" end
    if package_known(target,"getEquips"):length() > 1 then return "dismantlement" end
    return "slash"
end



sgs.ai_skill_playerchosen.ny_10th_lianzhi = function(self, targets)
    if package_known(self.player,"getStrategyFlag","ny_10th_shouze") then
        if #self.enemies == 0 then return nil end
        package_call(self,"sort",self.enemies, "hp")
        return self.enemies[1]
    else
        for _,target in sgs.qlist(targets) do
            if (not package_known(self,"isEnemy",target)) then
                return target
            end
        end
        local players = sgs.QList2Table(targets)
        return players[math.random(1,#players)]
    end
end



local ny_tenth_fengying_skill={}
ny_tenth_fengying_skill.name="ny_tenth_fengying"
table.insert(package_skills,ny_tenth_fengying_skill)
ny_tenth_fengying_skill.getTurnUseCard=function(self,inclusive,request)
    if package_known(self.player,"getStrategyMark","&ny_10th_jiao") <= 0 then return end

    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByKeepValue",cards)
    local need
    for _,card in ipairs(cards) do
        if package_known(card,"getNumber") <= package_known(self.player,"getStrategyMark","&ny_10th_jiao") then
            need = card
            break
        end
    end
    if (not need) then return end

    local names = source_fact(self,"ny_tenth_fengying","toString"):split("+")
    if (not names) or (#names <= 0) then return end

	for _,name in sgs.list(names)do do
        local c = clone_native(self,name)
        package_call(c,"addSubcard",need)
        local mark = string.format("ny_tenth_fengying_%s-Clear", name)
		if c and package_known(c,"isAvailable",self.player)
		and package_known(self,"getCardsNum",package_known(c,"getClassName"))<1
        and package_known(self.player,"getStrategyMark",mark) == 0
		then

            local dummy = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",c, dummy)

    		if dummy.card
	    	and dummy.to
	     	then
	           	if package_known(c,"canRecast")
				and package_known(dummy.to,"length")<1
				then goto package_continue_6 end
				source_state(self).ny_tenth_fengying_to = dummy.to
				package_call(self,"setPriorityValue","#ny_tenth_fengying", sgs.ai_use_priority[package_known(c,"getClassName")],"sgs10th.source")
                local card_str = string.format("#ny_tenth_fengying:%s:%s",package_known(need,"getEffectiveId"), name)
                return source_construct(self,card_str)
			end
		end
		if c then package_call(c,"deleteLater") end
	end ::package_continue_6:: end
end

sgs.ai_skill_use_func["#ny_tenth_fengying"] = function(card,use,self,request)
	use.card = card
	if use.to then use.to = source_state(self).ny_tenth_fengying_to end
end

sgs.ai_use_priority.ny_tenth_fengying = 6

sgs.ai_guhuo_card.ny_tenth_fengying = function(self,toname,class_name)
	if owner_reason(self) == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return end

    local names = source_fact(self,"ny_tenth_fengying","toString"):split("+")
    if (not names) or (#names <= 0) then return end

    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByKeepValue",cards)
    local need
    for _,card in ipairs(cards) do
        if package_known(card,"getNumber") <= package_known(self.player,"getStrategyMark","&ny_10th_jiao") then
            need = card
            break
        end
    end
    if (not need) then return end

    local pattern = toname
    if string.find(pattern, "slash") then pattern = "slash" end

    for _,name in ipairs(names) do
        if string.find(name, pattern) then
            local mark = string.format("ny_tenth_fengying_%s-Clear", name)
            if package_known(self.player,"getStrategyMark",mark) == 0 then
                local card_str = string.format("#ny_tenth_fengying:%s:%s",package_known(need,"getEffectiveId"), name)
                return card_str
            end
        end
    end
    return
end



sgs.ai_skill_invoke.ny_10th_caisi = true



sgs.ai_skill_invoke.ny_10th_danyi = true



local ny_tenth_wencan_skill = {}
ny_tenth_wencan_skill.name = "ny_tenth_wencan"
table.insert(package_skills, ny_tenth_wencan_skill)
ny_tenth_wencan_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#ny_tenth_wencan") then return end
    if #self.enemies == 0 then return end
    return source_construct(self,"#ny_tenth_wencan:.:")
end

sgs.ai_skill_use_func["#ny_tenth_wencan"] = function(card,use,self,request)
    local targets = {}
    package_call(self,"sort",self.enemies, "defense")
    if #self.enemies > 0 then
        for _,enemy in ipairs(self.enemies) do
            local can = true
            for _,target in ipairs(targets) do
                if package_known(target,"getHp") == package_known(enemy,"getHp") then
                    can = false
                    break
                end
            end
            if can then table.insert(targets, enemy) end
            if #targets >= 2 then break end
        end
        if #targets > 0 then
            use.card = card
            if use.to then
                for _,target in ipairs(targets) do
                    package_call(use.to,"append",target)
                end
            end
        end
    end
end


sgs.ai_use_priority.ny_tenth_wencan = 8

ai_skill_use["@@ny_tenth_wencan"]=function(self,prompt,request)
    local target
    for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
        if package_known(p,"getPhase") == sgs.Player_Play then
            target = p
            break
        end
    end
    if (not target) then return "." end
    local cards = {}
    local all = sgs.QList2Table(package_known(self.player,"getCards","he"))
    if #all <= 3 then return "." end
    package_call(self,"sortByKeepValue",all)
    for _,card in ipairs(all) do
        local can = true
        for _,cc in ipairs(cards) do
            if package_known(cc,"getSuit") == package_known(card,"getSuit") then
                can = false
                break
            end
        end
        if can then table.insert(cards, card) end
        if #cards >= 2 then break end
    end
    if #cards < 2 then return "." end
    if package_known(target,"getHandcardNum") < package_known(self.player,"getHandcardNum") then return "." end
    if package_known(self,"isWeak") then
        return string.format("#ny_tenth_wencanDisCard:%s+%s:", package_known(cards[1],"getEffectiveId"), package_known(cards[2],"getEffectiveId"))
    elseif package_known(target,"getHandcardNum") > package_known(self.player,"getHandcardNum") + 2 then
        return string.format("#ny_tenth_wencanDisCard:%s+%s:", package_known(cards[1],"getEffectiveId"), package_known(cards[2],"getEffectiveId"))
    end
    return "."
end




sgs.ai_skill_invoke.ny_10th_wangxi = true



local ny_10th_xianshu_second_skill = {}
ny_10th_xianshu_second_skill.name = "ny_10th_xianshu_second"
table.insert(package_skills, ny_10th_xianshu_second_skill)
ny_10th_xianshu_second_skill.getTurnUseCard = function(self,inclusive,request)
	for _,card in sgs.qlist(package_known(self.player,"getHandcards")) do
        if package_known(card,"hasFlag","ny_10th_konghou_second") then
	        return source_construct(self,"#ny_10th_xianshu_second:.:")
        end
    end
end

sgs.ai_skill_use_func["#ny_10th_xianshu_second"] = function(card,use,self,request)
	package_call(self,"updatePlayers")

    local red = {}
    local black = {}
    local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)
    for _,card in ipairs(cards) do
        if package_known(card,"hasFlag","ny_10th_konghou_second") then
	        if package_known(card,"isRed") then table.insert(red, package_known(card,"getEffectiveId")) end
            if package_known(card,"isBlack") then table.insert(black, package_known(card,"getEffectiveId")) end
        end
    end

    local enduse = false
    if #red > 0 then
        package_call(self,"sort",self.friends, "hp")
        for _,friend in ipairs(self.friends) do
            if package_known(friend,"objectName") ~= package_known(self.player,"objectName")
            and package_known(friend,"getHp") <= package_known(self.player,"getHp") and package_known(friend,"isWounded") then
                local card_str = string.format("#ny_10th_xianshu_second:%s:->%s", red[1], package_known(friend,"objectName"))
		        local acard = source_construct(self,card_str)
		        assert(acard)
		        use.card = acard
		        if use.to then
			        package_call(use.to,"append",friend)
		        end
                enduse = true
                break
            end
        end
    end
    if #black > 0 and (not enduse) then
        package_call(self,"sort",self.enemies, "hp")
        for _,enemy in ipairs(self.enemies) do
            if package_known(enemy,"objectName") ~= package_known(self.player,"objectName")
            and package_known(enemy,"getHp") >= package_known(self.player,"getHp") then
                local card_str = string.format("#ny_10th_xianshu_second:%s:->%s", black[1], package_known(enemy,"objectName"))
		        local acard = source_construct(self,card_str)
		        assert(acard)
		        use.card = acard
		        if use.to then
			        package_call(use.to,"append",enemy)
		        end
                break
            end
        end
    end
end

sgs.ai_use_priority.ny_10th_xianshu_second = 10

sgs.ai_card_intention.ny_10th_xianshu_second = function(self, card, from, tos)
	for _,to in ipairs(tos) do
        if package_known(to,"getHp") > package_known(from,"getHp") then
		    sgs.updateIntention(from, to, 80)
        elseif package_known(to,"getHp") < package_known(from,"getHp") then
            sgs.updateIntention(from, to, -80)
        else
            if package_known(card,"isRed") then
                sgs.updateIntention(from, to, -80)
            elseif package_known(card,"isBlack") then
                sgs.updateIntention(from, to, 80)
            end
        end
	end
end



sgs.ai_skill_discard.ny_10th_lingxi = function(self,max,min)
    local cards
    local need = package_known(self.player,"getMaxHp")
    if package_known(self.player,"getStrategyMark","ny_10th_lingxi_start") > 0 then
        if package_known(self.player,"isNude") then return {} end
        cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
        package_call(self,"sortByUseValue",cards, true)
        need = math.min(need, #cards - 2)
    else
        if package_known(self.player,"isKongcheng") then return {} end
        cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
        package_call(self,"sortByKeepValue",cards)
        need = math.min(need, package_known(self.player,"getHandcardNum") - package_known(self.player,"getMaxCards"))
    end
    if need <= 0 then return {} end
    if #cards <= 0 then return {} end
    local put = {}
    for _,card in ipairs(cards) do
        table.insert(put, package_known(card,"getEffectiveId"))
        need = need - 1
        if need <= 0 then break end
    end
    return put
end



sgs.ai_skill_invoke.ny_tenth_zhifou = function(self, data)
    if #self.enemies <= 0 and package_known(self.player,"getStrategyMark","ny_tenth_zhifou_put-Clear") > 0 then return false end
    if (package_known(self.player,"getHandcardNum") > 8)
    or (package_known(self.player,"getHandcardNum") > (2 * package_known(self.player,"getPile","ny_10th_yi"):length())) then return false end
    local need = package_known(self.player,"getStrategyMark","ny_tenth_zhifou-Clear") + 1
    local suits = {}
    for _,id in sgs.qlist(package_known(self.player,"getPile","ny_10th_yi")) do
        local suit = disclosed_card(self,id):getSuitString()
        if (not table.contains(suits, suit)) then
            table.insert(suits, suit)
        else
            need = need - 1
        end
    end
    local num = #suits
    if need > 0 then num = num - need end
    if num <= 0 then return false end
    num = num * 2
    if package_known(self,"isWeak") and (package_known(self.player,"getHandcardNum") < num) then return true end
    if (package_known(self.player,"getHandcardNum") +package_known(self.player,"getStrategyMark","ny_tenth_zhifou-Clear") + 1) > num then return false end
    return true
end

sgs.ai_skill_choice["ny_tenth_zhifou"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    table.removeOne(items, "cancel")
    if #items == 1 then return items[1] end
    if #self.enemies > 0 then
        package_call(self,"sort",self.enemies, "defense")
        for _,enemy in ipairs(self.enemies) do
            if package_known(enemy,"getHp") == 1 and table.contains(items, "lose") then return "lose" end
        end
        local n = package_known(self.player,"getPile","ny_10th_yi"):length()
        for _,enemy in ipairs(self.enemies) do
            if (not package_known(enemy,"isNude")) and n <= 8 and table.contains(items, "put") then return "put" end
        end
        for _,enemy in ipairs(self.enemies) do
            if package_known(self,"isWeak",enemy) and table.contains(items, "lose") then return "lose" end
        end
        return items[math.random(1, #items)]
    end
    local others = sgs.QList2Table(package_known(self.room,"getOtherPlayers",self.player))
    package_call(self,"sort",others, "defense")
    for _,other in ipairs(others) do
        if (not package_known(self,"isFriend",other)) and table.contains(items, "put") then return "put" end
    end
    return "cancel"
end

ai_skill_use["@@ny_tenth_zhifou"]=function(self,prompt,request)
    local target
    local need = package_known(self.player,"getStrategyMark","ny_tenth_zhifou-Clear") + 1
    if #self.enemies <= 0 and (not package_known(self.player,"getStrategyFlag","ny_tenth_zhifou_put")) then return "." end
    if #self.enemies <= 0 then
        local others = sgs.QList2Table(package_known(self.room,"getOtherPlayers",self.player))
        package_call(self,"sort",others, "defense")
        for _,other in ipairs(others) do
            if (not package_known(self,"isFriend",other)) then
                target = other
                break
            end
        end
    else
        package_call(self,"sort",self.enemies, "defense")
        if package_known(self.player,"getStrategyFlag","ny_tenth_zhifou_lose") then
            for _,enemy in ipairs(self.enemies) do
                if package_known(enemy,"getHp") == 1 then
                    target = enemy
                    break
                end
            end
            if (not target) then target = self.enemies[1] end
        else
            for _,enemy in ipairs(self.enemies) do
                if not package_known(enemy,"isNude") then
                    target = enemy
                    break
                end
            end
        end
    end
    if (not target) then return "." end

    local suits = {}
    local cards = {}
    local lastcards = {}
    for _,id in sgs.qlist(package_known(self.player,"getPile","ny_10th_yi")) do
        local card = disclosed_card(self,id)
        local suit = package_known(card,"getSuitString")
        if (not table.contains(suits, suit)) then
            table.insert(suits, suit)
            table.insert(lastcards, id)
        else
            table.insert(cards, id)
            need = need - 1
        end
        if need <= 0 then break end
    end
    if need > 0 then
        for _,id in ipairs(lastcards) do
            table.insert(cards, id)
            need = need - 1
            if need <= 0 then break end
        end
    end
    if need > 0 then return "." end

    return string.format("#ny_tenth_zhifou:%s:->%s", table.concat(cards, "+"), package_known(target,"objectName"))
end



sgs.ai_skill_invoke.ny_tenth_jiaoxia_second = function(self,data)
    if package_known(self,"isWeak") then return false end
    local n = 8
    if package_known(self.room,"getAlivePlayers"):length() <= 4 then n = 5 end
    if package_known(self.player,"getHandcardNum") > n then return false end
    if package_known(self,"getCardsNum","Slash") >= #self.enemies then return false end
    return true
end

ai_skill_use["@@ny_tenth_jiaoxia_second"]=function(self,prompt,request)
    local card = disclosed_card(self,package_known(self.player,"getStrategyMark","ny_tenth_jiaoxia_second_card"))

    local use = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, use)
    if use.card then
        if use.to and package_known(use.to,"length") > 0 then
            local tos = {}
            for _,p in sgs.qlist(use.to) do
                table.insert(tos, package_known(p,"objectName"))
            end
            return selected(self,card,tos)
        end
    end
end



local ny_10th_humei_second_skill = {}
ny_10th_humei_second_skill.name = "ny_10th_humei_second"
table.insert(package_skills, ny_10th_humei_second_skill)
ny_10th_humei_second_skill.getTurnUseCard = function(self,inclusive,request)
    local choices = {"draw", "give", "recover"}
    for _,p in ipairs(choices) do
        if package_known(self.player,"getStrategyMark","ny_10th_humei_second_tiansuan_remove_"..p.."-PlayClear") == 0 then
            return source_construct(self,"#ny_10th_humei_second:.:"..p)
        end
    end
end

sgs.ai_skill_use_func["#ny_10th_humei_second"] = function(card,use,self,request)
	local choices = {"draw", "give", "recover"}
    for _,p in ipairs(choices) do
        if package_known(self.player,"getStrategyMark","ny_10th_humei_second_tiansuan_remove_"..p.."-PlayClear") == 0 then
            if p == "draw" then
                package_call(self,"sort",self.friends, "handcard")
                local target = nil
                for _,friend in ipairs(self.friends) do
                    if package_known(friend,"getHp") <= package_known(self.player,"getStrategyMark","&ny_10th_humei_second-PlayClear") then
                        target = friend
                        break
                    end
                end
                if target then
                    use.card = source_construct(self,"#ny_10th_humei_second:.:"..p)
                    if use.to then package_call(use.to,"append",target) end
                    break
                end
            end

            if p == "give" then
                package_call(self,"sort",self.enemies, "handcard")
                local target = nil
                for _,enemy in ipairs(self.enemies) do
                    if package_known(enemy,"getHp") <= package_known(self.player,"getStrategyMark","&ny_10th_humei_second-PlayClear") and (not package_known(enemy,"isNude")) then
                        target = enemy
                        break
                    end
                end
                if target then
                    use.card = source_construct(self,"#ny_10th_humei_second:.:"..p)
                    if use.to then package_call(use.to,"append",target) end
                    break
                end
            end

            if p == "recover" then
                package_call(self,"sort",self.friends, "hp")
                local target = nil
                for _,friend in ipairs(self.friends) do
                    if package_known(friend,"getHp") <= package_known(self.player,"getStrategyMark","&ny_10th_humei_second-PlayClear") and package_known(friend,"isWounded") then
                        target = friend
                        break
                    end
                end
                if target then
                    use.card = source_construct(self,"#ny_10th_humei_second:.:"..p)
                    if use.to then package_call(use.to,"append",target) end
                    break
                end
            end
        end
    end
end



sgs.ai_skill_invoke.ny_10th_zhangcai = true



sgs.ai_skill_invoke.ny_10th_xiongmu = true

sgs.ai_skill_discard.ny_10th_xiongmu = function(self,max,min)
    local player = self.player
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	local dis = {}
    local n = 12
	for _,card in ipairs(cards) do
        table.insert(dis, package_known(card,"getEffectiveId"))
        n = n - 1
        if n <= 0 then break end
    end
	return dis
end



local ny_10th_ruxian_skill = {}
ny_10th_ruxian_skill.name = "ny_10th_ruxian"
table.insert(package_skills, ny_10th_ruxian_skill)
ny_10th_ruxian_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","ny_10th_ruxian_limit") == 0 then
		return source_construct(self,"#ny_10th_ruxian:.:")
	end
end

sgs.ai_skill_use_func["#ny_10th_ruxian"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_priority.ny_10th_ruxian = 10
sgs.ai_use_value.ny_10th_ruxian = 10



local ny_10th_longhun_skill = {}
ny_10th_longhun_skill.name = "ny_10th_longhun"
table.insert(package_skills, ny_10th_longhun_skill)
ny_10th_longhun_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyMark","&ny_10th_longhun-Clear") >= 20 then return end

    local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    cards = package_call(self,"sortByUseValue",cards, true)
    for _,card in ipairs(cards) do
        if package_known(card,"getSuit") == sgs.Card_Heart then
            local usecard = clone_native(self,"peach", sgs.Card_SuitToBeDecided, -1)
            package_call(usecard,"setSkillName","ny_10th_longhun")
            package_call(usecard,"addSubcard",card)
            package_call(usecard,"deleteLater")

            local usec = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",usecard, usec)
            if usec.card and package_known(self.player,"isWounded") then
                source_state(self).ny_10th_longhun_to = usec.to
                local card_str = string.format("#ny_10th_longhun:%s:%s",package_known(card,"getEffectiveId"), "peach")
                local acard = source_construct(self,card_str)
                return acard
            end
        end
        if package_known(card,"getSuit") == sgs.Card_Diamond then
            if package_call(self.player,"getWeapon") and (package_known(card,"getEffectiveId") == package_call(self.player,"getWeapon"):getId())
            and package_known(card,"isKindOf","Crossbow")  then
                if package_known(self.player,"canSlashWithoutCrossbow") then
                    local slash = clone_native(self,"fire_slash", sgs.Card_SuitToBeDecided, -1)
                    package_call(slash,"setSkillName","ny_10th_longhun")
                    package_call(slash,"addSubcard",card)
                    package_call(slash,"deleteLater")

                    local usec = {isDummy=true,to=sgs.SPlayerList()}
                    package_call(self,"useCardByClassName",slash, usec)
                    if usec.card and package_known(slash,"isAvailable",self.player) then
                        source_state(self).ny_10th_longhun_to = usec.to
                        local card_str = string.format("#ny_10th_longhun:%s:%s",package_known(card,"getEffectiveId"), "fire_slash")
                        local acard = source_construct(self,card_str)
                        return acard
                    end
                end
            else
                local slash = clone_native(self,"fire_slash", sgs.Card_SuitToBeDecided, -1)
                package_call(slash,"setSkillName","ny_10th_longhun")
                package_call(slash,"addSubcard",card)
                package_call(slash,"deleteLater")

                local usec = {isDummy=true,to=sgs.SPlayerList()}
                package_call(self,"useCardByClassName",slash, usec)
                if usec.card and package_known(slash,"isAvailable",self.player) then
                    source_state(self).ny_10th_longhun_to = usec.to
                    local card_str = string.format("#ny_10th_longhun:%s:%s",package_known(card,"getEffectiveId"), "fire_slash")
                    local acard = source_construct(self,card_str)
                    return acard
                end
            end
        end
    end
end

sgs.ai_skill_use_func["#ny_10th_longhun"] = function(card,use,self,request)
    use.card = card
    if use.to then use.to = source_state(self).ny_10th_longhun_to end
end

sgs.ai_use_priority.ny_10th_longhun = sgs.ai_use_priority.Slash





























































sgs.ai_view_as.ny_10th_longhun = function(card, player, card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if package_known(player,"getHp") > 1 or card_place == sgs.Player_PlaceSpecial then return end
	if package_known(card,"getSuit") == sgs.Card_Diamond then
		return ("fire_slash:ny_10th_longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif package_known(card,"getSuit") == sgs.Card_Club then
		return ("jink:ny_10th_longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif package_known(card,"getSuit") == sgs.Card_Heart and package_known(player,"getStrategyMark","Global_PreventPeach") == 0 then
		return ("peach:ny_10th_longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif package_known(card,"getSuit") == sgs.Card_Spade then
		return ("nullification:ny_10th_longhun[%s:%s]=%d"):format(suit, number, card_id)
	end
end



sgs.ai_skill_invoke.ny_10th_zhanjiang = function(self, data)
    for _, p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
        local weapon = package_call(p,"getWeapon")
        if weapon and package_known(weapon,"objectName") == "QinggangSword" then
            if package_known(self,"isEnemy",p) then return true end
            return false
        end
    end
    return false
end



local ny_10th_weiwan_skill = {}
ny_10th_weiwan_skill.name = "ny_10th_weiwan"
table.insert(package_skills, ny_10th_weiwan_skill)
ny_10th_weiwan_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#ny_10th_weiwan") then return end

    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    cards = package_call(self,"sortByUseValue",cards, true)
    for _,card in ipairs(cards) do
        if foreign_fact(self,card,"ny_10th_qin","toBool") then
            local card_str = string.format("#ny_10th_weiwan:%s:", package_known(card,"getEffectiveId"))
            return source_construct(self,card_str)
        end
    end
end

sgs.ai_skill_use_func["#ny_10th_weiwan"] = function(card,use,self,request)
    local target
    if #self.enemies == 0 then return end
    package_call(self,"sort",self.enemies,"defense")
    for _,enemy in ipairs(self.enemies) do
        if (not package_known(enemy,"isNude")) then
            target = enemy
            break
        end
    end
    if target then
        use.card = card
        if use.to then package_call(use.to,"append",target) end
    end
end

sgs.ai_use_priority.ny_10th_weiwan = 8
sgs.ai_use_value.ny_10th_weiwan = 8
sgs.ai_card_intention.ny_10th_weiwan = 80



sgs.ai_skill_invoke.ny_tenth_silun = true

sgs.ai_skill_choice["ny_tenth_silun"] = function(self, choices, data)
    return "bottom"
end

ai_skill_use["@@ny_tenth_silun!"]=function(self,prompt,request)
    if package_known(self.player,"isNude") then return "." end
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    package_call(self,"sortByKeepValue",cards)
    local target
    local needturn = false
    local need = {}
    if #self.friends > 0 then
        package_call(self,"sort",self.friends, "defense")
        for _,friend in ipairs(self.friends) do
            if (not package_known(friend,"faceUp")) then
                needturn = true
                table.insert(need, friend)
            end
        end
    end
    if needturn then
        for _,card in ipairs(cards) do
            if package_known(card,"isKindOf","EquipCard") then
                local equip_index = package_known(card,"getRealCard"):toEquipCard():location()
                for _,to_select in ipairs(need) do
                    if package_known(to_select,"hasEquipArea",equip_index) and (not package_call(to_select,"getEquip",equip_index)) then
                        return string.format("#ny_tenth_silun:%d:->%s", package_known(card,"getEffectiveId"), package_known(to_select,"objectName"))
                    end
                end
            end
        end
    end
    for _,card in ipairs(cards) do
        if package_known(card,"isKindOf","EquipCard") then
            local equip_index = package_known(card,"getRealCard"):toEquipCard():location()
            if package_known(self.player,"hasEquipArea",equip_index) and (not package_call(self.player,"getEquip",equip_index)) then
                return string.format("#ny_tenth_silun:%d:->%s", package_known(card,"getEffectiveId"), package_known(self.player,"objectName"))
            end
            for _,to_select in ipairs(self.friends) do
                if package_known(to_select,"hasEquipArea",equip_index) and (not package_call(to_select,"getEquip",equip_index)) then
                    return string.format("#ny_tenth_silun:%d:->%s", package_known(card,"getEffectiveId"), package_known(to_select,"objectName"))
                end
            end
        end
    end
    if #self.enemies > 0 then
        package_call(self,"sort",self.enemies, "defense")
        for _,card in ipairs(cards) do
            if package_known(card,"isKindOf","DelayedTrick") then
                for _,to_select in ipairs(self.enemies) do
                    if package_known(to_select,"hasJudgeArea") and (not package_known(to_select,"containsTrick",package_known(card,"objectName"))) then
                        return string.format("#ny_tenth_silun:%d:->%s", package_known(card,"getEffectiveId"), package_known(to_select,"objectName"))
                    end
                end
            end
        end
    end
    return string.format("#ny_tenth_silun:%d:", package_known(cards[1],"getEffectiveId"))
end



sgs.ai_skill_invoke.ny_tenth_shiji = function(self, data)
    local target = package_call(data,"toPlayer")
    if target and package_known(self,"isFriend",target) then return true end
    return false
end

ai_skill_use["@@ny_tenth_shiji"]=function(self,prompt,request)
    if package_known(self.player,"isKongcheng") then return "." end
    if package_known(self.player,"getHandcardNum") == 1 then return false end
    local pattern = source_property(self,"ny_tenth_shiji_card"):toString()
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByKeepValue",cards)

    local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
    package_call(card,"setSkillName","ny_tenth_shiji")
    package_call(card,"addSubcard",cards[1])
    local use = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, use)
    if use.card then
        if use.to then
            local tos = {}
            for _,to in sgs.qlist(use.to) do
                table.insert(tos, package_known(to,"objectName"))
            end
            return selected(self,card,tos)
        else
            return package_known(card,"toString")
        end
    end
    return "."
end

sgs.ai_skill_choice["ny_tenth_shiji"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    if #items > 1 then
        table.removeOne(items, "cancel")
    end
    return items[#items]
end



sgs.ai_skill_invoke.ny_10th_xiaoren = true

sgs.ai_skill_playerchosen.ny_10th_xiaoren = function(self, targets)
    if package_known(self.player,"getStrategyMark","ny_10th_xiaoren_recover") > 0 then
        if #self.friends > 0 then
            package_call(self,"sort",self.friends, "defense")
            return self.friends[1]
        end
        return self.player
    end
    local can_select = sgs.QList2Table(targets)
    package_call(self,"sort",can_select, "defense")
    for _,to in ipairs(can_select) do
        if (not package_known(self,"isFriend",to)) then return to end
    end
    return nil
end



local ny_tenth_posuo_skill = {}
ny_tenth_posuo_skill.name = "ny_tenth_posuo"
table.insert(package_skills, ny_tenth_posuo_skill)
ny_tenth_posuo_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyMark","ny_tenth_posuo_disable-PlayClear") > 0 then return end

    local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)
    for _,card in ipairs(cards) do
        local mark = string.format("ny_tenth_posuo_%s-PlayClear", package_known(card,"getSuitString"))
        if package_known(self.player,"getStrategyMark",mark) == 0 then
            local key = string.format("ny_tenth_posuo_%s", package_known(card,"getSuitString"))
            local all = suit_tag(self,key):split("+")
            if (not all) or (#all <= 0) then
                local card_str = "#ny_tenth_posuo_select:"..package_known(card,"getEffectiveId")..":"
                return source_construct(self,card_str)
            else
                for _,pattern in ipairs(all) do
                    local newcard = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
                    package_call(newcard,"addSubcard",card)
                    package_call(newcard,"deleteLater")

                    local use = {isDummy=true,to=sgs.SPlayerList()}
                    package_call(self,"useCardByClassName",newcard, use)
                    if use.card and package_known(newcard,"isAvailable",self.player) then
                        source_state(self).ny_tenth_posuo_to = use.to
                        local card_str = string.format("#ny_tenth_posuo:%s:%s",package_known(card,"getEffectiveId"), pattern)
                        local acard = source_construct(self,card_str)
                        return acard
                    end
                end
            end
        end
    end
end

sgs.ai_skill_use_func["#ny_tenth_posuo"] = function(card,use,self,request)
    use.card = card
    if use.to then use.to = source_state(self).ny_tenth_posuo_to end
end

sgs.ai_skill_use_func["#ny_tenth_posuo_select"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_skill_choice["ny_tenth_posuo"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    return "cancel"
end

sgs.ai_use_priority.ny_tenth_posuo = 8



sgs.ai_skill_discard.ny_10th_xiaoyan = function(self, max, min)
    if package_known(self.player,"isNude") then return {} end
    local target = room_tag(self,"ny_10th_xiaoyan")
    if target and package_known(self,"isFriend",target) then
        if (not package_known(self,"isWeak")) and (package_known(self.player,"getHandcardNum") > 1) then
            local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
            package_call(self,"sortByUseValue",cards)
            return {package_known(cards[1],"getEffectiveId")}
        end
    end
    if (not package_known(self,"isWeak")) then return {} end
    if (not package_known(self.player,"isWounded")) then return {} end
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    package_call(self,"sortByKeepValue",cards)
    return {package_known(cards[1],"getEffectiveId")}
end



local ny_10th_aoshi_give_skill = {}
ny_10th_aoshi_give_skill.name = "ny_10th_aoshi_give"
table.insert(package_skills, ny_10th_aoshi_give_skill)
ny_10th_aoshi_give_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getKingdom") ~= "qun" then return end
    if package_known(self.player,"hasUsed","#ny_10th_aoshi_give") then return end
    if package_known(self,"isWeak") or package_known(self.player,"getHandcardNum") <= 1 then return end

    for _,other in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if package_known(self,"isFriend",other) and package_known(other,"hasLordSkill","ny_10th_aoshi") then
            return source_construct(self,"#ny_10th_aoshi_give:.:")
        end
    end
end

sgs.ai_skill_use_func["#ny_10th_aoshi_give"] = function(card,use,self,request)
    local targets = {}
    for _,other in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if package_known(self,"isFriend",other) and package_known(other,"hasLordSkill","ny_10th_aoshi") then
            table.insert(targets, other)
        end
    end
    if #targets <= 0 then return end
    package_call(self,"sort",targets, "defense")
    local target = targets[1]
    if target then
        local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
        if package_known(self,"isWeak",target) then
            package_call(self,"sortByKeepValue",cards)
        else
            package_call(self,"sortByUseValue",cards, true)
        end
        local card_str = string.format("#ny_10th_aoshi_give:%s:", package_known(cards[#cards],"getEffectiveId"))
        local acard = source_construct(self,card_str)
        use.card = acard
        if use.to then package_call(use.to,"append",target) end
    end
end

sgs.ai_use_priority.ny_10th_aoshi_give = 8
sgs.ai_use_value.ny_10th_aoshi_give = 8
sgs.ai_card_intention.ny_10th_aoshi_give = -80



local ny_tenth_zongshi_skill = {}
ny_tenth_zongshi_skill.name = "ny_tenth_zongshi"
table.insert(package_skills, ny_tenth_zongshi_skill)
ny_tenth_zongshi_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self,"isWeak") or package_known(self.player,"getHandcardNum") <= 1 then return end

    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByUseValue",cards, true)
    for i,card in ipairs(cards) do do
        if (not package_known(card,"isKindOf","BasicCard")) and (not package_known(card,"isNDTrick")) then goto package_continue_7 end
                local ccc = clone_native(self,package_known(card,"objectName"))
                package_call(ccc,"setSkillName","ny_tenth_zongshi")
        for n,cc in ipairs(cards) do
            if package_known(cc,"getSuit") == package_known(card,"getSuit") and i~=n then
                package_call(ccc,"addSubcard",cc)
            end
        end
                package_call(ccc,"deleteLater")
		if package_known(ccc,"subcardsLength")>0 and package_known(ccc,"isAvailable",self.player) then
                    local usec = {isDummy=true,to=sgs.SPlayerList()}
                    package_call(self,"useCardByClassName",ccc, usec)
                    if usec.card then
				return source_construct(self,string.format("#ny_tenth_zongshi:%s:",package_known(card,"getEffectiveId")))
            end
        end
    end ::package_continue_7:: end
end

sgs.ai_skill_use_func["#ny_tenth_zongshi"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_priority.ny_tenth_zongshi = 3
sgs.ai_use_value.ny_tenth_zongshi = 8

sgs.ai_skill_playerschosen.ny_tenth_zongshi = function(self, targets, max, min)
    local card = source_fact(self,"ny_tenth_zongshi","toCard")

    local num = max
    local rtargets = sgs.SPlayerList()

    local usec = {isDummy=true,to=sgs.SPlayerList(),extra_target = max-1}
    package_call(self,"useCardByClassName",card, usec)
    if usec.card then
        for _,to in sgs.qlist(usec.to) do
            package_call(rtargets,"append",to)
            num = num - 1
            if num <= 0 then return rtargets end
        end
    end
    local items = sgs.QList2Table(targets)
    package_call(self,"sort",items, "defense")
    local good = {"ex_nihilo", "amazing_grace", "god_salvation", "peach"}
    if table.contains(good, package_known(card,"objectName")) then
        for _,to in ipairs(items) do
            if (not package_known(rtargets,"contains",to)) and package_known(self,"isFriend",to) then
                package_call(rtargets,"append",to)
                num = num - 1
                if num <= 0 then return rtargets end
            end
        end
        return rtargets
    end

    for _,to in ipairs(items) do
        if (not package_known(rtargets,"contains",to)) and package_known(self,"isEnemy",to) then
            package_call(rtargets,"append",to)
            num = num - 1
            if num <= 0 then return rtargets end
        end
    end
    return rtargets
end

ai_skill_use["@@ny_tenth_zongshi"]=function(self,prompt,request)
    if package_known(self,"isWeak") or package_known(self.player,"getHandcardNum") <= 1 then return end

    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByUseValue",cards, true)
    for i,card in ipairs(cards) do do
        if (not package_known(card,"isKindOf","BasicCard")) and (not package_known(card,"isNDTrick")) then goto package_continue_8 end
            local cc = clone_native(self,package_known(card,"objectName"))
            package_call(cc,"setSkillName","ny_tenth_zongshi")
        for n,c in ipairs(cards) do
            if package_known(c,"getSuit") == package_known(card,"getSuit") and i~=n then
                package_call(cc,"addSubcard",c)
            end
        end
            package_call(cc,"deleteLater")
		if package_known(cc,"subcardsLength")>0 and package_known(cc,"isAvailable",self.player) then
                local usec = {isDummy=true,to=sgs.SPlayerList()}
                package_call(self,"useCardByClassName",cc, usec)
                if usec.card then
				return string.format("#ny_tenth_zongshi:%s:",package_known(card,"getEffectiveId"))
            end
        end
    end ::package_continue_8:: end
end



ai_skill_use["@@ny_tenth_linghui"]=function(self,prompt,request)
    local cards = {}
    local num = 3
    for _,id in sgs.qlist(hidden_draw_pile(self)) do
        local card = disclosed_card(self,id)
        table.insert(cards, card)
        num = num - 1
        if num <= 0 then break end
    end
    package_call(self,"sortByUseValue",cards)
    for _,card in ipairs(cards) do
        local use = {isDummy=true,to=sgs.SPlayerList()}
        package_call(self,"useCardByClassName",card, use)
        if use.card then
            local tos = {}
            for _,to in sgs.qlist(use.to) do
                table.insert(tos, package_known(to,"objectName"))
            end
            return string.format("#ny_tenth_linghui:%s:->%s", package_known(card,"getEffectiveId"), table.concat(tos, "+"))
        end
    end
    return "."
end



sgs.ai_skill_discard.ny_10th_xiace = function(self, max, min)
    if package_known(self.player,"isNude") then return {} end
    if (not package_known(self.player,"isWounded")) then return {} end
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    package_call(self,"sortByKeepValue",cards)
    if #cards > 0 then return {package_known(cards[1],"getEffectiveId")} end
    return {}
end

sgs.ai_skill_playerchosen.ny_10th_xiace = function(self, targets)
    local now = package_call(self.room,"getCurrent")
    if now and package_known(self,"isEnemy",now) then return now end
    if #self.enemies <= 0 then return nil end
    package_call(self,"sort",self.enemies, "defense")
    return self.enemies[1]
end

sgs.ai_playerchosen_intention.ny_10th_xiace = function(self, from, to)
	sgs.updateIntention(from, to, 80)
end



sgs.ai_skill_invoke.ny_10th_yuxin = function(self, data)
    local target = room_tag(self,"ny_10th_yuxin")
    if (not target) or (not package_known(self,"isFriend",target)) then return false end
    if package_known(self,"getCardsNum","Peach") + package_known(target,"getHp") > 0 then return false end
    return package_known(self,"isFriend",target)
end



sgs.ai_skill_invoke.ny_10th_xunbie = function(self, data)
    if package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") + package_known(self.player,"getHp") > 0 then return false end
    return true
end



ai_skill_use["@@ny_tenth_chanjuan"]=function(self,prompt,request)
    local pattern = source_property(self,"ny_tenth_chanjuan_card"):toString()
    local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
	package_call(card,"setSkillName","ny_tenth_chanjuan")
    package_call(card,"deleteLater")
    local use = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, use)
    if use.card then
        if package_known(use.to,"length") > 0 then
            local tos = {}
            for _,to in sgs.qlist(use.to) do
                table.insert(tos, package_known(to,"objectName"))
            end
            return string.format("#ny_tenth_chanjuan:.:->%s",table.concat(tos, "+"))
        else
            return "#ny_tenth_chanjuan:.:"
        end
    end
    return "."
end



local ny_10th_zhuangpo_skill = {}
ny_10th_zhuangpo_skill.name = "ny_10th_zhuangpo"
table.insert(package_skills, ny_10th_zhuangpo_skill)
ny_10th_zhuangpo_skill.getTurnUseCard = function(self,inclusive,request)
    local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)
    for _,card in ipairs(cards) do
        local to_translate = ":"..package_known(card,"objectName")
        local translation = translation(self,to_translate)
        if package_known(card,"isKindOf","Slash") or string.find(translation, "【杀】") then
            local duel = clone_native(self,"duel", sgs.Card_SuitToBeDecided, -1)
            package_call(duel,"addSubcard",card)
            package_call(duel,"setSkillName","ny_10th_zhuangpo")
            package_call(duel,"deleteLater")

            local usec = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",duel, usec)
            if usec.card then
                source_state(self).ny_10th_zhuangpo_to = usec.to
                local card_str = string.format("#ny_10th_zhuangpo:%s:", package_known(card,"getEffectiveId"))
                return source_construct(self,card_str)
            end
        end
    end
end

sgs.ai_skill_use_func["#ny_10th_zhuangpo"] = function(card,use,self,request)
	use.card = card
    if use.to then use.to = source_state(self).ny_10th_zhuangpo_to end
end

sgs.ai_use_priority.ny_10th_zhuangpo = sgs.ai_use_priority.Duel

sgs.ai_skill_invoke.ny_10th_zhuangpo = function(self, data)
    local target = source_fact(self,"ny_10th_zhuangpo","toPlayer")
    return package_known(self,"isEnemy",target)
end

sgs.ai_skill_choice["ny_10th_zhuangpo"] = function(self, choices, data)
	local items = package_known(choices,"split","+")
    return items[#items]
end



sgs.ai_skill_playerchosen.ny_tenth_miyun = function(self, targets)
    local objects = sgs.QList2Table(targets)
    package_call(self,"sort",objects, "defense")
    for _,p in ipairs(objects) do
        if (not package_known(self,"isFriend",p)) then return p end
    end
    return objects[#objects]
end

ai_skill_use["@@ny_tenth_miyun!"]=function(self,prompt,request)
    if #self.friends_noself == 0 then
        for _,cc in sgs.qlist(package_known(self.player,"getHandcards")) do
            if package_known(cc,"hasFlag","ny_tenth_miyun_an") then
                local others = sgs.QList2Table(package_known(self.room,"getOtherPlayers",self.player))
                package_call(self,"sort",others, "defendse")
                return string.format("#ny_tenth_miyun:%s:->%s", package_known(cc,"getEffectiveId"), package_known(others[#others],"objectName"))
            end
        end
    else
        package_call(self,"sort",self.friends_noself, "defense")
        local give = {}
        for _,card in sgs.qlist(package_known(self.player,"getHandcards")) do
            table.insert(give, package_known(card,"getEffectiveId"))
        end
        return string.format("#ny_tenth_miyun:%s:->%s", table.concat(give, "+"), package_known(self.friends_noself[1],"objectName"))
    end
end

sgs.ai_card_intention.ny_tenth_miyun = -80



sgs.ai_cardsview_valuable.ny_10th_danyin = function(self,class_name,player)
    if package_known(player,"getStrategyMark","ny_10th_danyin-Clear") > 0 then return end
	local HandPile = sgs.QList2Table(package_known(player,"getHandcards"))
	package_call(self,"sortByKeepValue",HandPile)
    local find = false
	for _,c in sgs.list(HandPile)do
		if package_known(c,"isKindOf",class_name) and (not package_known(self,"isWeak")) then return end
        if package_known(c,"hasFlag","ny_tenth_miyun_an") then find = true end
	end
    if (not find) then return end
	local can_use = {["Slash"] = "slash", ["Jink"] = "jink"}
	local name = can_use[class_name]
	if not name then return end
	return string.format("#ny_10th_danyin:.:%s", name)
end

local ny_10th_danyin_skill = {}
ny_10th_danyin_skill.name = "ny_10th_danyin"
table.insert(package_skills, ny_10th_danyin_skill)
ny_10th_danyin_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyMark","ny_10th_danyin-Clear") > 0 then return end
	local HandPile = sgs.QList2Table(package_known(self.player,"getHandcards"))
    local find = false
	for _,c in sgs.list(HandPile)do
        if package_known(c,"hasFlag","ny_tenth_miyun_an") then find = true end
	end
    if (not find) then return end

    local card = clone_native(self,"slash", sgs.Card_SuitToBeDecided, -1)
	package_call(card,"deleteLater")
	local usec = {isDummy=true,to=sgs.SPlayerList()}
	package_call(self,"useCardByClassName",card, usec)
	if usec.card then
        source_state(self).ny_10th_danyin_to = usec.to
	    local card_str = string.format("#ny_10th_danyin:.:%s", "slash")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#ny_10th_danyin"] = function(card,use,self,request)
	use.card = card
    if use.to then use.to = source_state(self).ny_10th_danyin_to end
end

sgs.ai_use_priority.ny_tenth_miyun = sgs.ai_use_priority.Slash



sgs.ai_skill_choice.ny_tenth_dehua = function(self, choices)
    local items = package_known(choices,"split","+")
    if #items == 1 then return items[1] end
    table.removeOne(items, "slash")
    for _,item in ipairs(items) do
        local card = clone_native(self,item, sgs.Card_SuitToBeDecided, -1)
        package_call(card,"deleteLater")
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        package_call(self,"useCardByClassName",card, usec)
        if usec.card then
            return item
        end
    end
    return items[math.random(1,#items)]
end

sgs.ai_skill_choice.ny_tenth_dehua_slash = function(self, choices)
    return "slash"
end

ai_skill_use["@@ny_tenth_dehua"]=function(self,prompt,request)
    local pattern = source_property(self,"ny_tenth_dehua_card"):toString()
	local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
    package_call(card,"setSkillName","ny_tenth_dehua")
    package_call(card,"deleteLater")

    if package_known(card,"targetFixed") then
        return string.format("#ny_tenth_dehua:.:%s",pattern)
    end

    local usec = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, usec)
    if usec.card then
        if package_known(usec.to,"length") > 0 then
            local tos = {}
            for _,to in sgs.qlist(usec.to) do
                table.insert(tos, package_known(to,"objectName"))
            end
            return string.format("#ny_tenth_dehua:.:%s->%s",pattern, table.concat(tos, "+"))
        else
            return string.format("#ny_tenth_dehua:.:%s",pattern)
        end
    end
end



local ny_10th_fuli_skill = {}
ny_10th_fuli_skill.name = "ny_10th_fuli"
table.insert(package_skills, ny_10th_fuli_skill)
ny_10th_fuli_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"isNude") then return end
    if package_known(self.player,"hasUsed","#ny_10th_fuli") then return end
    return source_construct(self,"#ny_10th_fuli:.:")
end

sgs.ai_skill_use_func["#ny_10th_fuli"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_skill_choice.ny_10th_fuli = function(self, choices)
    local items = package_known(choices,"split","+")
    if #items == 1 then return items[1] end
    table.removeOne(items, "BasicCard")
    return items[math.random(1,#items)]
end

sgs.ai_skill_playerchosen.ny_10th_fuli = function(self, targets)
    local target = nil
    local min = 999
    for _,p in sgs.qlist(targets) do
        if package_known(self,"isEnemy",p) and package_known(p,"getAttackRange") >= 1 and package_known(p,"getAttackRange") <= min then
            target = p
            min = package_known(p,"getAttackRange")
        end
    end
    if not target then
        for _,p in sgs.qlist(targets) do
            if package_known(self,"isEnemy",p) then
                target = p
            end
        end
    end
    return target
end

sgs.ai_playerchosen_intention.ny_10th_fuli = 40



local ny_tenth_yanjiao_skill = {}
ny_tenth_yanjiao_skill.name = "ny_tenth_yanjiao"
table.insert(package_skills, ny_tenth_yanjiao_skill)
ny_tenth_yanjiao_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#ny_tenth_yanjiao") then return end
    if #self.friends_noself <= 0 then return end
    return source_construct(self,"#ny_tenth_yanjiao:.:")
end

sgs.ai_skill_use_func["#ny_tenth_yanjiao"] = function(card,use,self,request)
    package_call(self,"sort",self.friends_noself, "defense")
    if #self.friends_noself > 0 then
	    use.card = card
        if use.to then package_call(use.to,"append",self.friends_noself[1]) end
    end
end

sgs.ai_use_priority.ny_tenth_yanjiao = 8
sgs.ai_card_intention.ny_tenth_yanjiao = -80

sgs.ai_skill_choice.ny_tenth_yanjiao = function(self, choices)
    local target = package_call(self.room,"getCurrent")
    if target and package_known(self,"isEnemy",target) then
        return "no"
    else
        return "yes"
    end
end



sgs.ai_skill_invoke.ny_10th_xingshen = true



local ny_10th_quanmou_skill = {}
ny_10th_quanmou_skill.name = "ny_10th_quanmou"
table.insert(package_skills, ny_10th_quanmou_skill)
ny_10th_quanmou_skill.getTurnUseCard = function(self,inclusive,request)
    return source_construct(self,"#ny_10th_quanmou:.:")
end

sgs.ai_skill_use_func["#ny_10th_quanmou"] = function(card,use,self,request)
    local target
    for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if package_known(p,"getStrategyMark","ny_10th_quanmou_selelcted-PlayClear") == 0
        and package_known(self.player,"inMyAttackRange",p) then
            if package_known(self,"isFriend",p) and package_known(self.player,"getChangeSkillState","ny_10th_quanmou") <= 1 then
                target = p
                break
            else
                if (not package_known(self,"isFriend",p)) and package_known(self.player,"getChangeSkillState","ny_10th_quanmou") == 2 then
                    target = p
                    break
                end
            end
        end
    end

    if (not target) then
        for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
            if package_known(p,"getStrategyMark","ny_10th_quanmou_selelcted-PlayClear") == 0
            and package_known(self.player,"inMyAttackRange",p) then
                target = p
                break
            end
        end
    end

    if target then
	    use.card = card
        if use.to then package_call(use.to,"append",target) end
    end
end

sgs.ai_use_priority.ny_10th_quanmou = 10

sgs.ai_skill_playerschosen.ny_10th_quanmou = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local n = max
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if package_known(self,"isEnemy",target) then
            package_call(selected,"append",target)
            n = n - 1
        end
        if n <= 0 then break end
    end
    return selected
end



sgs.ai_skill_choice.ny_10th_jianzhuan = function(self, choices)
    if string.find(choices, "disself") then
        return "disself="..package_known(self.player,"getStrategyMark","&ny_10th_jianzhuan-PlayClear")
    elseif string.find(choices, "recast") then
        return "recast="..package_known(self.player,"getStrategyMark","&ny_10th_jianzhuan-PlayClear")
    end
    local items = package_known(choices,"split","+")
    return items[math.random(1,#items)]
end

sgs.ai_skill_playerchosen.ny_10th_jianzhuan = function(self, targets)
    if #self.enemies > 0 then
        package_call(self,"sort",self.enemies, "defense")
        for _,enemy in ipairs(self.enemies) do
            if (not package_known(enemy,"isNude")) then return enemy end
        end
    end
    local tos = package_known(self.room,"getOtherPlayers",self.player)
    return package_known(tos,"at",math.random(1, package_known(tos,"length")))
end

sgs.ai_playerchosen_intention.ny_10th_jianzhuan = 80



sgs.ai_skill_invoke.ny_10th_fudou = function(self, data)
    local use = source_fact(self,"ny_10th_fudou","toCardUse")
    local target = package_known(use.to,"at",0)
    return ((not package_known(self,"isWeak")) and package_known(self,"isEnemy",target) and package_known(use.card,"isBlack"))
    or (package_known(self,"isFriend",target) and package_known(use.card,"isRed"))
end



local ny_10th_jianguo_second_skill = {}
ny_10th_jianguo_second_skill.name = "ny_10th_jianguo_second"
table.insert(package_skills, ny_10th_jianguo_second_skill)
ny_10th_jianguo_second_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyMark","ny_10th_jianguo_second_tiansuan_remove_draw-PlayClear") == 0
    or package_known(self.player,"getStrategyMark","ny_10th_jianguo_second_tiansuan_remove_dis-PlayClear") == 0 then
        return source_construct(self,"#ny_10th_jianguo_second:.:")
    end
end

sgs.ai_skill_use_func["#ny_10th_jianguo_second"] = function(card,use,self,request)
    if package_known(self.player,"getStrategyMark","ny_10th_jianguo_second_tiansuan_remove_draw-PlayClear") == 0 then
        if #self.friends > 0 then
            package_call(self,"sort",self.friends, "handcard", true)
            use.card = source_construct(self,"#ny_10th_jianguo_second:.:draw")
            if use.to then package_call(use.to,"append",self.friends[1]) end
            return
        end
    end
    if package_known(self.player,"getStrategyMark","ny_10th_jianguo_second_tiansuan_remove_dis-PlayClear") == 0 then
        if #self.enemies > 0 then
            package_call(self,"sort",self.enemies, "handcard", true)
            use.card = source_construct(self,"#ny_10th_jianguo_second:.:dis")
            if use.to then package_call(use.to,"append",self.enemies[1]) end
            return
        end
    end
end

sgs.ai_use_priority.ny_10th_jianguo_second = 8



sgs.ai_skill_playerschosen.ny_10th_zhimin = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local n = max
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if package_known(self,"isEnemy",target) or (not package_known(self,"isFriend",target)) then
            package_call(selected,"append",target)
            n = n - 1
        end
        if n <= 0 then break end
    end
    if (not package_known(selected,"isEmpty")) then
        return selected
    end
    package_call(selected,"append",can_choose[#can_choose])
    return selected
end



local ny_10th_jujian_skill = {}
ny_10th_jujian_skill.name = "ny_10th_jujian"
table.insert(package_skills, ny_10th_jujian_skill)
ny_10th_jujian_skill.getTurnUseCard = function(self,inclusive,request)
    if (not package_known(self.player,"hasUsed","#ny_10th_jujian")) then
        return source_construct(self,"#ny_10th_jujian:.:")
    end
end

sgs.ai_skill_use_func["#ny_10th_jujian"] = function(card,use,self,request)
    local targets = package_known(self.room,"getOtherPlayers",self.player)
    local tos = sgs.QList2Table(targets)
    package_call(self,"sort",tos, "defense", true)
    for _,to in ipairs(tos) do
        if package_known(to,"getKingdom") == "wei" and (package_known(self,"isEnemy",to) and (not package_known(self,"isWeak",to))) then
            use.card = card
            if use.to then package_call(use.to,"append",to) end
            return
        end
    end
    for _,to in ipairs(tos) do
        if package_known(to,"getKingdom") == "wei" and (package_known(self,"isFriend",to)) then
            use.card = card
            if use.to then package_call(use.to,"append",to) end
            return
        end
    end
end



ai_card_use.NYTShuiyanqijun=function(self,card,use)
	local target_num = correct_target(self,"ExtraTarget",card) + 2
    local targets = package_known(self.room,"getAlivePlayers")
    local tos = sgs.SPlayerList()
    while(target_num > 0) do
        local target = package_known(self,"findPlayerToDamage",1,self.player,"N",targets)[1]
        if not target or package_known(self,"isFriend",target) then break end
        package_known(targets,"removeOne",target)
        if not package_known(self.player,"isProhibited",target, card) then
            target_num = target_num - 1
            package_call(tos,"append",target)
        end
        if package_known(targets,"isEmpty") then break end
    end
    if (not package_known(tos,"isEmpty")) then
        use.card = card
        if use.to then use.to = tos end
    end
end

sgs.ai_use_priority.NYTShuiyanqijun = 6.4
sgs.ai_keep_value.NYTShuiyanqijun = 4.4
sgs.ai_use_value.NYTShuiyanqijun = 5.4
sgs.ai_card_intention.NYTShuiyanqijun = 50



local ny_tenth_jvewu_skill = {}
ny_tenth_jvewu_skill.name = "ny_tenth_jvewu"
table.insert(package_skills, ny_tenth_jvewu_skill)
ny_tenth_jvewu_skill.getTurnUseCard = function(self,inclusive,request)
    local alls = sgs.QList2Table(package_known(self.player,"getCards","he"))
    package_call(self,"sortByKeepValue",alls)
    local cards = {}
    for _,card in ipairs(alls) do
        if package_known(card,"getNumber") == 2 then
            table.insert(cards, card)
        end
    end
    if #cards <= 0 then return end

    local names = {"_ny_tenth_shuiyanqijun"}
    for _,card in sgs.qlist(public_deck_shuffle(self)) do
        if package_known(card,"isKindOf","BasicCard") or package_known(card,"isNDTrick") then
            if package_known(card,"isDamageCard") then
                if (not table.contains(names, package_known(card,"objectName"))) then
                    table.insert(names, package_known(card,"objectName"))
                end
            end
        end
    end

    local able = {}
    for _,name in ipairs(names) do
        local card = clone_native(self,name)
        package_call(card,"deleteLater")
        local mark = string.format("ny_tenth_jvewu_%s-Clear", package_known(card,"objectName"))
        if package_known(card,"isKindOf","Slash") then mark = "ny_tenth_jvewu_Slash-Clear" end
        if package_known(self.player,"getStrategyMark",mark) == 0 and package_known(card,"isAvailable",self.player) then
            table.insert(able, name)
        end
    end
    if #able <= 0 then return end

    for _,pattern in ipairs(able) do
        local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
        package_call(card,"addSubcard",cards[1])
        package_call(card,"deleteLater")
        local types = {"BasicCard","TrickCard"}
        local dummy = {isDummy=true,to=sgs.SPlayerList()}
        dispatch_source_type(self,card,dummy)
        if dummy.card and dummy.to then
            source_state(self).ny_tenth_jvewu_to = dummy.to
            local card_str = string.format("#ny_tenth_jvewu:%s:%s",package_known(cards[1],"getEffectiveId"), pattern)
            return source_construct(self,card_str)
        end
    end

end

sgs.ai_skill_use_func["#ny_tenth_jvewu"] = function(card,use,self,request)
	use.card = card
    if use.to then use.to = source_state(self).ny_tenth_jvewu_to end
end

sgs.ai_cardsview_valuable.ny_tenth_jvewu = function(self, class_name, player)
	if package_known(self.player,"isKongcheng") then return end
    if package_known(self.player,"getStrategyMark","ny_tenth_jvewu_Slash-Clear") > 0 then return end
    if owner_reason(self) == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
	local classname2objectname = {
		["Slash"] = "slash", ["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
	if not name then return end
    for _,card in sgs.qlist(package_known(self.player,"getHandcards")) do
        if package_known(card,"isKindOf",class_name) then return end
    end
    local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    package_call(self,"sortByKeepValue",cards)
    for _,card in ipairs(cards) do
        if package_known(card,"getNumber") == 2 then
            local card_str = string.format("#ny_tenth_jvewu:%s:%s",package_known(card,"getEffectiveId"), name)
            return card_str
        end
    end
    return
end

sgs.ai_use_priority.ny_tenth_jvewu = 7



local ny_tenth_wuyou_other_skill = {}
ny_tenth_wuyou_other_skill.name = "ny_tenth_wuyou_other"
table.insert(package_skills, ny_tenth_wuyou_other_skill)
ny_tenth_wuyou_other_skill.getTurnUseCard = function(self,inclusive,request)
    if (package_known(self.player,"isKongcheng") or package_known(self,"isWeak")) and package_known(self.player,"getHandcardNum") <= package_known(self.player,"getMaxCards") then return end
    if (not package_known(self.player,"hasUsed","#ny_tenth_wuyou")) then
        for _,p in ipairs(self.friends) do
            if package_known(p,"hasSkill","ny_tenth_wuyou") then
                return source_construct(self,"#ny_tenth_wuyou:.:")
            end
        end
    end
end

sgs.ai_skill_use_func["#ny_tenth_wuyou"] = function(card,use,self,request)
    local hands = sgs.QList2Table(package_known(self.player,"getHandcards"))
    package_call(self,"sortByKeepValue",hands)
    package_call(self,"sort",self.friends, "defense")
    for _,friend in ipairs(self.friends) do
        if package_known(friend,"hasSkill","ny_tenth_wuyou") then
            local card_str = "#ny_tenth_wuyou:"..package_known(hands[1],"getEffectiveId")..":"
            use.card = source_construct(self,card_str)
            if use.to then package_call(use.to,"append",friend) end
            return
        end
    end
end

sgs.ai_card_intention.ny_tenth_wuyou = -40

sgs.ai_skill_discard.ny_tenth_wuyou = function(self, max, min)
    if package_known(self.player,"isKongcheng") or package_known(self,"isWeak") then return false end
    local target = package_call(self.room,"getCurrent")
    if target and package_known(self,"isFriend",target) then
        local hands = sgs.QList2Table(package_known(self.player,"getHandcards"))
        package_call(self,"sortByKeepValue",hands)
        return (package_known(hands[1],"getEffectiveId"))
    end
    return {}
end

sgs.ai_skill_choice.ny_tenth_wuyou = function(self, choices, data)
    local target = package_call(self.room,"getCurrent")
    if (not target) or (not package_known(self,"isWeak",target)) then
        local items = package_known(choices,"split","+")
        local cards = {}
        for _,item in ipairs(items) do
            local card = clone_native(self,item, sgs.Card_SuitToBeDecided, -1)
            package_call(card,"deleteLater")
            table.insert(cards, card)
        end
        package_call(self,"sortByUseValue",cards)
        return package_known(cards[1],"objectName")
    end
    local items = package_known(choices,"split","+")
    local cards = {}
    for _,item in ipairs(items) do
        local card = clone_native(self,item, sgs.Card_SuitToBeDecided, -1)
        package_call(card,"deleteLater")
        table.insert(cards, card)
    end
    package_call(self,"sortByKeepValue",cards)
    return package_known(cards[1],"objectName")
end

sgs.ai_use_priority.ny_tenth_wuyou = 4



local ny_tenth_yixian_skill = {}
ny_tenth_yixian_skill.name = "ny_tenth_yixian"
table.insert(package_skills, ny_tenth_yixian_skill)
ny_tenth_yixian_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyMark","@ny_tenth_yixian_mark") == 0 then return end
    local field = 0
    local discardpile = 0
    if package_known(self.player,"getEquips"):length() > 0 then
        field = field + package_known(self.player,"getEquips"):length()
        if package_known(self.player,"isWounded") then
            field = field + 1.5
            if package_known(self,"isWeak") then field = field + 1 end
        end
    end
    for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
        if package_known(p,"getEquips"):length() > 0 then
            if package_known(self,"isFriend",p) and package_known(p,"isWounded") then
                field = field + 2
                if package_known(self,"isWeak",p) then field = field + 1 end
            end
            if package_known(self,"isEnemy",p) then
                field = field + package_known(p,"getEquips"):length()
            end
            field = field + 0.5*(package_known(p,"getEquips"):length())
        end
    end
    local equips = {}
    for i = 0, 4, 0 do
        if package_call(self.player,"getEquip",i) then
            table.insert(equips, 1)
        else
            table.insert(equips, 0)
        end
    end
    for _,id in sgs.qlist(package_known(self.room,"getDiscardPile")) do
        local card = disclosed_card(self,id)
        if package_known(card,"isKindOf","EquipCard") then
            local equip_index = package_known(card,"getRealCard"):toEquipCard():location()
            if package_known(self.player,"hasEquipArea",equip_index) and equips[equip_index] == 0 then
                equips[equip_index] = 1
                discardpile = discardpile + 1
            else
                if package_known(card,"getNumber") == 2 then
                    discardpile = discardpile + 1
                end
            end
        end
    end
    if math.max(field, discardpile) < ((package_known(self.room,"getAlivePlayers"):length()) + 1) then return end
    if field >= discardpile then
        return source_construct(self,"#ny_tenth_yixian:.:field")
    else
        return source_construct(self,"#ny_tenth_yixian:.:discardpile")
    end
end

sgs.ai_skill_use_func["#ny_tenth_yixian"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_priority.ny_tenth_yixian = 3.8

sgs.ai_skill_choice.ny_tenth_yixian = function(self, choices, data)
    local target = package_call(data,"toPlayer")
    if target and package_known(self,"isFriend",target) then
        return "buff="..package_known(target,"getGeneralName")
    end
    return "cancel"
end



local ny_10th_shicao_skill = {}
ny_10th_shicao_skill.name = "ny_10th_shicao"
table.insert(package_skills, ny_10th_shicao_skill)
ny_10th_shicao_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyMark","ny_10th_shicao_disable-Clear") > 0 then return end
    return source_construct(self,"#ny_10th_shicao:.:")
end

sgs.ai_skill_use_func["#ny_10th_shicao"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_priority.ny_10th_shicao = 10

sgs.ai_skill_choice.ny_10th_shicao_place = function(self, choices)
    local items = package_known(choices,"split","+")
    return items[math.random(1,#items)]
end

sgs.ai_skill_choice.ny_10th_shicao_type = function(self, choices, data)
    local cardTypes = {"BasicCard","TrickCard","EquipCard"}
    local n = package_known(self.player,"usedTimes","#ny_10th_shicao")
    if math.random(0,n) < 2 then
        local place = package_known(data,"toString")
        if place == "top" then
            local card = disclosed_card(self,hidden_draw_pile(self):at(0))
            return cardTypes[package_known(card,"getTypeId")]
        else
            local card = disclosed_card(self,hidden_draw_pile(self):at(hidden_draw_pile(self):length() - 1))
            return cardTypes[package_known(card,"getTypeId")]
        end
    end
    local items = package_known(choices,"split","+")
    return items[math.random(1,#items)]
end
for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
for key,fn in pairs(sgs.ai_fill_skill)do
 if type(fn)=='function'and initial_callbacks.ai_fill_skill[key]~=fn then
  sgs.ai_fill_skill[key]=function(self,inclusive,request)local old=active_requests[self];active_requests[self]=request;local r=table.pack(pcall(fn,self,inclusive,request));active_requests[self]=old;if not r[1]then error(r[2],0)end;return finish_turn(self,r[2],request)end
 end
end
for key,fn in pairs(sgs.ai_skill_use_func)do
 if type(fn)=='function'and initial_callbacks.ai_skill_use_func[key]~=fn then
  sgs.ai_skill_use_func[key]=function(card,use,self,request)local old=active_requests[self];active_requests[self]=request;local r=table.pack(pcall(fn,card,use,self,request));active_requests[self]=old;if not r[1]then error(r[2],0)end;return table.unpack(r,2,r.n)end
 end
end
for key,fn in pairs(ai_skill_use)do
 if type(fn)=='function'and initial_callbacks.ai_skill_use[key]~=fn then
  ai_skill_use[key]=function(self,prompt,request)local r=table.pack(fn(self,prompt,request));if AIUnsupported.is(r[1])then error(r[1],0)end;if type(r[1])=='string'and r[1]~='.'then return source_response(self,r[1],request)end;return table.unpack(r,1,r.n)end
 end
end
for _,registry in ipairs({'ai_guhuo_card','ai_cardsview','ai_cardsview_valuable','ai_view_as'})do
 for key,fn in pairs(sgs[registry])do
  if type(fn)=='function'and initial_callbacks[registry][key]~=fn then
   sgs[registry][key]=function(...)local args=table.pack(...);local self=registry=='ai_view_as'and actor_ai(args[2])or args[1];local r=table.pack(fn(...));if AIUnsupported.is(r[1])then error(r[1],0)end;if type(r[1])=='string'and r[1]~='.'then return source_proposal(self,r[1])end;return table.unpack(r,1,r.n)end
  end
 end
end
