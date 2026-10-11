local PACKAGE="gaoda"
local SELECTORS={["#map"]="map",["#bursta"]="bursta",["#burstd"]="burstd",["#burstp"]="burstp",["#bursts"]="bursts",["#burstj"]="burstj",["#burstl"]="burstl",["#skin"]="skin",["#yuexian"]="yuexian",["#gaoda_zhongjie"]="gaoda_zhongjie",["#bianxing"]="bianxing",["#jvjian"]="jvjian",["#tuci"]="tuci",["#huimie"]="huimie",["#zhonggong"]="zhonggong",["#linguang"]="linguang",["#siyi"]="siyi",["#xiezhan"]="xiezhan",["#zhenya"]="zhenya",["#ntdtwo"]="ntdtwo",["#ntdthree"]="ntdthree",["#shenniao"]="shenniao",["#fanshe"]="fanshe",["#luashipo"]="luashipo",["#leishe"]="leishe",["#haidaocard"]="haidao",["#shanguang"]="shanguang",["#shenzhang"]="shenzhang",["#aoyi"]="aoyi",["#m_aoyi"]="m_aoyi",["#wzpoint"]="wzpoint",["#shuangpao"]="shuangpao",["#zaizhan"]="zaizhan",["#shuanglong"]="shuanglong",["#weibo"]="weibo",["#weixing"]="weixing",["#gaoda_difa"]="gaoda_difa",["#jiechi"]="jiechi",["#juexin"]="juexin",["#hundun"]="hundun",["#bachi"]="bachi",["#hubi"]="hubi",["#jiqi"]="jiqi",["#jianmie"]="jianmie",["#exia_transam"]="exia_transam",["#dynames_transam"]="dynames_transam",["#chaobing"]="chaobing",["#kyrios_transam"]="kyrios_transam",["#virtue_transam"]="virtue_transam",["#jidong"]="jidong",["#fengong"]="fengong",["#zaisheng"]="zaisheng",["#reborns_transam"]="reborns_transam",["#harute_transam"]="harute_transam",["#ronghe"]="ronghe",["#fs_transam"]="fs_transam",["#shineng"]="shineng",["#dm_transam"]="dm_transam",["#ciyuanbawangliu"]="ciyuanbawangliu",["#hongbao"]="hongbao",["#yingxin"]="yingxin",["#redpacket"]="redpacket",["#songli"]="songli",["#gaoda_zhufu"]="gaoda_zhufu",["#qiefu"]="qiefu",["#lunwu"]="lunwu",["#longhou"]="longhou",["#boss_miehou"]="boss_miehou"}
local ORDINARY_SKILLS={["G_SELF_SPACE_skill"]=true,["aoyi"]=true,["baizhan"]=true,["baosang"]=true,["canguang"]=true,["canyingcard"]=true,["dadi"]=true,["daijin"]=true,["daijincard"]=true,["duzhan"]=true,["feijian"]=true,["gaoda_huiyun"]=true,["gaoda_jianhun"]=true,["gaoda_liuyan"]=true,["gaoda_qishe"]=true,["gaoda_shenpan"]=true,["gaoda_zhanshi"]=true,["gaoda_zhongjiecard"]=true,["gaoda_zuzhou"]=true,["gelin"]=true,["guanglei"]=true,["guangmang"]=true,["haidaocard"]=true,["hongjue"]=true,["huancai"]=true,["huantong"]=true,["huanyi"]=true,["huimiecard"]=true,["jianmie"]=true,["jingxi"]=true,["jvji"]=true,["kelong"]=true,["liangjian"]=true,["liuxing"]=true,["luashipo"]=true,["ntdfourcard"]=true,["ntdthree"]=true,["ntdtwo"]=true,["qianzhi"]=true,["qiji"]=true,["qingyu"]=true,["quanren"]=true,["shengfeng"]=true,["shewei"]=true,["shijiu"]=true,["shouwang"]=true,["shuangqiang"]=true,["sijue"]=true,["tupo"]=true,["wenshen"]=true,["xiaya"]=true,["zuzhuang"]=true}
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
local function raw_call(o,k,...)
 if not o or type(o[k])~='function' then unsupported(k)end
 local v=table.pack(o[k](o,...));if AIUnsupported.is(v[1])then error(v[1],0)end;return table.unpack(v,1,v.n)
end
local function fact(self,key)
 local all=self.world and self.world.strategy_facts;local p=all and all[PACKAGE];local v=p and p[key]
 if v==nil then unsupported(key)end;return v
end
local function clone(self,name,skill,suit,number)
 name=name or 'slash';local p=raw_call(self,'cloneEvaluationCard',name)
 if p==false then return nil end;if not p then unsupported('prototype.'..tostring(name))end
 local v={};clone_states[v]={self=self,name=raw_call(p,'objectName'),skill=skill or '',suit=suit==nil and sgs.Card_NoSuit or suit,number=number or 0,costs={},prototype=p,flags={}}
 return v
end
local function materialize(v)
 local s=clone_states[v];if not s then return v end
 if next(s.flags) then unsupported('clone_flags.'..s.skill)end
 local card
 if s.skill=='' and #s.costs==0 and s.suit==sgs.Card_NoSuit and s.number==0 then card=s.prototype
 elseif s.skill=='ntdtwo'or s.skill=='ntdthree'or s.skill=='luashipo'or s.skill=='haidaocard'or s.skill=='aoyi'
  or(s.skill==''and s.name=='slash'and s.suit==sgs.Card_NoSuitRed and s.number==0 and #s.costs==0)then
  -- Conditional products retain the full source constructor; this readonly
  -- endpoint never authorizes the later selected action or its payment.
  local ids={};for i,id in ipairs(s.costs)do ids[i]=id end
  card=raw_call(s.self,'evaluateOwnerViewAsCard',{source_key=s.skill==''and'aoyi'or(s.skill=='haidaocard'and'haidao'or s.skill),
   name=s.name,skill=s.skill,suit=s.suit,number=s.number,subcards=ids})
 else card=raw_call(s.self,'evaluateSkillCard',s.skill,s.name,s.costs)end
 if not card then unsupported('clone.'..s.skill..'.'..s.name)end
 if s.can_recast~=nil and raw_call(card,'canRecast')~=s.can_recast then unsupported('clone_recast.'..s.skill)end
 -- Current narrow endpoint has no arbitrary face parameters. A mismatched native
 -- clone is unknown, never a substitute with different suit/rank.
 local expected_suit=(s.suit>=0 and s.suit<6)and s.suit or sgs.Card_NoSuit
 local expected_number=s.number>0 and s.number or 0
 if #s.costs==0 and (raw_call(card,'getSuit')~=expected_suit or raw_call(card,'getNumber')~=expected_number)then unsupported('clone_face.'..s.skill)end
 if card~=s.prototype then clone_states[card]=s end;return card
end
local function copied_spec(s)
 local ids={};for i,id in ipairs(s.costs)do ids[i]=id end
 return{name=s.name,skill=s.skill,suit=s.suit,number=s.number,subcards=ids}
end
local function finish_turn(self,v,request)
 local s=clone_states[v];if not s then return v end
 if next(s.flags)then unsupported('turn_clone_flags.'..s.skill)end
 return raw_call(self,'evaluateTurnConversion',s.skill,raw_call(s.prototype,'getClassName'),copied_spec(s),request)
end
local function proposal(self,v)
 local s=clone_states[v];if s then return copied_spec(s)end
 if AIValue.isConversion(v)then return raw_call(v,'toCardSpec')end
 return raw_call(v,'getEffectiveId')
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
  if k=='addSubcard'then local x=args[1];s.costs[#s.costs+1]=type(x)=='number'and x or raw_call(x,'getEffectiveId');return end
  if k=='addSubcards'then for _,x in ipairs(args[1])do s.costs[#s.costs+1]=type(x)=='number'and x or raw_call(x,'getEffectiveId')end;return end
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
 return raw_call(o,k,table.unpack(args,1,args.n))
end
local function package_known(o,k,...)
 local v=table.pack(package_call(o,k,...));if v[1]==nil then unsupported(k)end;return table.unpack(v,1,v.n)
end
local function dummy(value,extra,current)local u=AIUsePlan.new();u.isDummy=value~=false;u.extra_target=extra or 0;u.current_targets=current or{};return u end
local function patterns_for(self,class)
 if class then return patterns(class)end
 local f=self.world and self.world.strategy_facts;local a=f and f.pattern_names
 if not AIValue.isList(a)then unsupported('pattern_names')end;return a
end
local function source_fact(self,key,kind)
 if key=='JilveWansha' and kind=='toBool' then
  local facts=self.world and self.world.strategy_facts
  local standard=facts and facts.standard
  local value=standard and standard.jilve_wansha
  if type(value)~='boolean' then unsupported('JilveWansha.owner_bool') end
  return value
 end
 local v=fact(self,key)
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
-- Fixed engine util.cpp ListS2I uses QString::toInt(&ok), appending only
-- successful signed base-10 int32 parses. Card::addSubcards(QList<int>) then
-- preserves that list (including negative IDs); readonly/payment validation is
-- a separate boundary. In particular the donor's literal %d is skipped, not 0.
-- This package's source constructor alphabet is ASCII; this is not a general
-- action parser and cannot create a payment receipt.
local function source_ids(text)
 if type(ai_source_wire_ids)~='function'then unsupported('source_numeric_costs')end
 local row=ai_source_wire_ids('gaoda',text)
 if type(row)~='table'or row.kind~='source_numeric_costs'or row.package~='gaoda'or type(row.ids)~='table'then unsupported('source_numeric_costs')end
 local out={}
 for i,id in ipairs(row.ids)do
  if type(id)~='number'or id%1~=0 or id< -2147483648 or id>2147483647 then unsupported('source_numeric_costs')end
  out[i]=id
 end
 return out
end
-- Only literals present in this package's source may enter this small grammar.
-- It is a pure policy constructor, never Card_Parse or an action-string parser.
local function source_skill(self,text,request)
 if type(text)~='string'then unsupported('source_skill')end
 text=text:match('^(.-)%->')or text
 local selector,cost,user=text:match('^(#[%w_]+):([^:]*):(.*)$')
 if not selector then unsupported('source_skill_shape')end
 return skill_source(self,selector,source_ids(cost),request,user)
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
local function disclosed_card(self,id)
 -- SWIG getCard(int) accepts numeric prompt fields; keep the disclosed-only domain.
 if type(id)=='string'and id:match('^%d+$')then id=tonumber(id)end
 if type(id)~='number'or id<0 or id%1~=0 then unsupported('disclosed_card_id')end
 return package_known(self,'getKnownCardById',id)
end
local function printed_card(self,id)return package_known(self,'getPrintedCardById',id)end
local function turn_count(self)local v=self.world and self.world.turn_count;if type(v)~='number'then unsupported('turn_count')end;return v end
local function owner_reason(self)local f=self.world and self.world.strategy_facts;local n=f and f.owner_current_card_use_reason;if type(n)~='number'then unsupported('owner_current_card_use_reason')end;return n end
local function ambient_pattern(self)unsupported('ambient_pattern')end
local function source_tag(self,key)return setmetatable({},{__index=function(_,kind)return function()return source_fact(self,key,kind)end end})end
local function foreign_fact(self,subject,key,kind)
 if subject==self.player then return source_fact(self,key,kind)end
 unsupported('foreign_tag.'..key)
end
local function translation(self,key)local rows=fact(self,'translations');if type(rows[key])~='string'then unsupported('translation.'..key)end;return rows[key]end
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
 local rows=fact(self,'owner_properties');local v=rows[key];if v==nil then unsupported('owner_property.'..key)end
 return{toString=function()if type(v)~='string'then unsupported('property_string.'..key)end;return v end,toInt=function()if type(v)~='number'then unsupported('property_number.'..key)end;return v end,toBool=function()if type(v)~='boolean'then unsupported('property_bool.'..key)end;return v end}
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
local function native_bans(self)local v=fact(self,'ban_packages');if not AIValue.isList(v)then unsupported('ban_packages')end;return v end
local function source_clock_seed(self)
 if type(ai_source_clock)~='function'then unsupported('zhanshi.source_clock')end
 local row=ai_source_clock('gaoda:shuffle:zhanshi')
 if type(row)~='table'or row.kind~='source_clock'or row.source_key~='gaoda:shuffle:zhanshi'
  or type(row.seconds)~='number'or row.seconds%1~=0 or row.seconds<0 or row.seconds>9007199254740991 then unsupported('zhanshi.source_clock')end
 -- Fixed engine luaGameRandomSeed checks an integer and returns without seeding.
 -- Do not turn this source no-op into a gameplay or AI RNG reset.
 math.randomseed(row.seconds)
end
local function source_shuffle_random(upper)
 if type(ai_source_gaoda_random)~='function'then unsupported('zhanshi.source_random')end
 local row=ai_source_gaoda_random(upper)
 if type(row)~='table'or row.kind~='source_gaoda_random'or row.upper~=upper
  or type(row.value)~='number'or row.value%1~=0 or row.value<1 or row.value>upper then unsupported('zhanshi.source_random')end
 return row.value
end
local function source_index_of(players,player)for i,p in ipairs(players)do if AIValue.sameLegacyIdentity(p,player)then return i-1 end end;return -1 end
local function source_jink_numbers(self,use)
 -- Only this viewer target's required-Jink count is lawful; no foreign tag array.
 local n=package_known(self,'getExpectedJinkNum',use)
 local at=source_index_of(use.to,self.player)+1;if at<1 then unsupported('jieneng.viewer_target')end;local result={};result[at]=n;return result
end

local Set,shuffle,perfectSum

local map_skill={}
map_skill.name="map"
table.insert(package_skills,map_skill)
map_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@map5") == 1 and #self.enemies > 0 then
		local card_str = ("#map:.:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#map"]=function(card,use,self,request)
	use.card = card
	for _,enemy in ipairs(self.enemies) do
		if use.to then package_call(use.to,"append",enemy) end
	end
end

sgs.ai_use_value["map"] = 8
sgs.ai_use_priority["map"] = 5.3


local bursta_skill={}
bursta_skill.name="bursta"
table.insert(package_skills,bursta_skill)
bursta_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@bursta") == 1 and package_known(self.player,"getStrategyMark","bursta") == 0 then
		local card_str = ("#bursta:.:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#bursta"]=function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["bursta"] = 10
sgs.ai_use_priority["bursta"] = 10

local burstd_skill={}
burstd_skill.name="burstd"
table.insert(package_skills,burstd_skill)
burstd_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@burstd") == 1 and package_known(self.player,"getStrategyMark","burstd") == 0 then
		local card_str = ("#burstd:.:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#burstd"]=function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["burstd"] = 10
sgs.ai_use_priority["burstd"] = 10

local burstp_skill={}
burstp_skill.name="burstp"
table.insert(package_skills,burstp_skill)
burstp_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@burstp") == 1 and package_known(self.player,"getStrategyMark","burstp") == 0 then
		local card_str = ("#burstp:.:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#burstp"]=function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["burstp"] = 10
sgs.ai_use_priority["burstp"] = 10

local bursts_skill={}
bursts_skill.name="bursts"
table.insert(package_skills,bursts_skill)
bursts_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@bursts") == 1 and package_known(self.player,"getStrategyMark","bursts") == 0 then
		local card_str = ("#bursts:.:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#bursts"]=function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["bursts"] = 10
sgs.ai_use_priority["bursts"] = 10

local burstj_skill={}
burstj_skill.name="burstj"
table.insert(package_skills,burstj_skill)
burstj_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@burstj") == 1 and package_known(self.player,"getStrategyMark","burstj") == 0 then
		local card_str = ("#burstj:.:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#burstj"]=function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["burstj"] = 10
sgs.ai_use_priority["burstj"] = 10

local burstl_skill={}
burstl_skill.name="burstl"
table.insert(package_skills,burstl_skill)
burstl_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@burstl") == 1 and package_known(self.player,"getStrategyMark","burstl") == 0 then
		local card_str = ("#burstl:.:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#burstl"]=function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["burstl"] = 10
sgs.ai_use_priority["burstl"] = 10


local skin_skill={}
skin_skill.name="skin"
table.insert(package_skills,skin_skill)
skin_skill.getTurnUseCard=function(self,inclusive,request)
	math.random()
	if not package_known(self.player,"hasUsed","#skin") and math.random(1, 100) <= 30 then
		local card_str = ("#skin:.:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#skin"]=function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["skin"] = 1
sgs.ai_use_priority["skin"] = 10


local yuexian_skill={}
yuexian_skill.name="yuexian"
table.insert(package_skills,yuexian_skill)
yuexian_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","yuexian") ~= 1 and ((package_known(self.player,"getStrategyMark","@rishi") == 0 and package_known(self.player,"hasSkill","rishi"))
		or (package_known(self.player,"getStrategyMark","@yihua") == 0 and package_known(self.player,"hasSkill","yihua")) or (package_known(self.player,"getStrategyMark","@shensheng") == 0 and package_known(self.player,"hasSkill","shensheng"))) then
		if (package_known(self.player,"getStrategyMark","@yihua") == 1 or not package_known(self.player,"hasSkill","yihua"))
			and (package_known(self.player,"getStrategyMark","@shensheng") == 1 or not package_known(self.player,"hasSkill","shensheng")) and #self.enemies < 2
			and package_known(self.player,"canSlash",self.enemies[1]) then
			return false
		end
		local card_str = ("#yuexian:.:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#yuexian"]=function(card,use,self,request)
	use.card = card
end

sgs.ai_skill_choice.yuexian = function(self, choices, data)
	choices = package_known(choices,"split","+")
	if #self.enemies < 2 and package_known(self.player,"canSlash",self.enemies[1]) then
		table.removeOne(choices, "rishi")
	end
	return choices[1]
end

sgs.dynamic_value.benefit["yuexian"] = true

sgs.ai_use_value["yuexian"] = sgs.ai_use_value.Analeptic + 1
sgs.ai_use_priority["yuexian"] = sgs.ai_use_value.Analeptic + 1

sgs.ai_skill_invoke.yihua = function(self, data)
	return true
end

sgs.ai_skill_invoke.shensheng = function(self, data)
	return true
end

sgs.ai_skill_choice.shensheng = function(self, choices, data)
	local id = package_known(data,"toString")
	if (disclosed_card(self,id):isKindOf("Weapon") and not package_call(self.player,"getWeapon")) or
	   (disclosed_card(self,id):isKindOf("Armor") and not package_call(self.player,"getArmor")) or
	   (disclosed_card(self,id):isKindOf("DefensiveHorse") and not package_known(self.player,"getDefensiveHorse")) or
	   (disclosed_card(self,id):isKindOf("OffensiveHorse") and not package_known(self.player,"getOffensiveHorse")) then
		return "ssuse"
	else
		return "ssobtain"
	end
end

ai_skill_use["@@shensheng"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	local card = package_known(prompt,"split",":")
	if card[2] == "slash" or card[2] == "fire_slash" or card[2] == "thunder_slash" then
		package_call(self,"sort",self.enemies, "defense")
		local targets = {}
		for _,enemy in ipairs(self.enemies) do
			if (not package_known(self,"slashProhibit",disclosed_card(self,card[5]), enemy)) and package_known(self.player,"canSlash",enemy, disclosed_card(self,card[5])) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",disclosed_card(self,card[5])) then break end
				table.insert(targets,package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return card[5] .. "->" .. table.concat(targets,"+")
		else
			return "."
		end
	elseif card[2] == "peach" or card[2] == "analeptic" or card[2] == "ex_nihilo" or card[2] == "amazing_grace" or card[2] == "savage_assault" or card[2] == "archery_attack" or card[2] == "god_salvation" then
		return card[5]
	elseif card[2] == "iron_chain" then








































		local use = dummy(false)
		package_call(self,"useTrickCard",disclosed_card(self,card[5]), use)
		if use.card and use.to and not package_known(use.to,"isEmpty") then
			local targets = {}
			for _, p in sgs.qlist(use.to) do
				table.insert(targets, package_known(p,"objectName"))
			end
			return card[5] .. "->" .. table.concat(targets,"+")
		else
			return "."
		end
	elseif card[2] == "fire_attack" then
		package_call(self,"sort",self.enemies, "hp")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isKongcheng")) and (not package_known(enemy,"isProhibited",enemy, disclosed_card(self,card[5]))) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",disclosed_card(self,card[5])) then break end
				table.insert(targets,package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return card[5] .. "->" .. table.concat(targets,"+")
		else
			return "."
		end
	elseif card[2] == "dismantlement" then
		package_call(self,"sort",self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isAllNude")) and (not package_known(enemy,"isProhibited",enemy, disclosed_card(self,card[5]))) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",disclosed_card(self,card[5])) then break end
				table.insert(targets,package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return card[5] .. "->" .. table.concat(targets,"+")
		else
			return "."
		end
	elseif card[2] == "snatch" then
		package_call(self,"sort",self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isAllNude")) and (not package_known(enemy,"isProhibited",enemy, disclosed_card(self,card[5]))) and
			package_known(self.player,"distanceTo",enemy) <= 1 + correct_target(self,"DistanceLimit",disclosed_card(self,card[5])) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",disclosed_card(self,card[5])) then break end
				table.insert(targets,package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return card[5] .. "->" .. table.concat(targets,"+")
		else
			return "."
		end
	elseif card[2] == "collateral" then
		package_call(self,"sort",self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if package_call(enemy,"getWeapon") and (not package_known(enemy,"isProhibited",enemy, disclosed_card(self,card[5]))) then
				for _, tos in ipairs(self.enemies) do
					if package_known(enemy,"objectName") ~= package_known(tos,"objectName") and
					package_known(enemy,"canSlash",tos, clone_native(self,"slash", sgs.Card_NoSuit, 0)) and
					(not package_known(tos,"isProhibited",tos, clone_native(self,"slash", sgs.Card_NoSuit, 0))) then
						table.insert(targets,package_known(enemy,"objectName"))
						table.insert(targets,package_known(tos,"objectName"))
						break
					end
				end
			end
		end
		if #targets > 1 then
			return card[5] .. "->" .. table.concat(targets,"+")
		else
			return "."
		end
	elseif card[2] == "duel" then
		package_call(self,"sort",self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isProhibited",enemy, disclosed_card(self,card[5]))) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",disclosed_card(self,card[5])) then break end
				table.insert(targets,package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return card[5] .. "->" .. table.concat(targets,"+")
		else
			return "."
		end
	elseif card[2] == "supply_shortage" then
		package_call(self,"sort",self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"containsTrick","supply_shortage")) and
			(not package_known(enemy,"isProhibited",enemy, disclosed_card(self,card[5]))) and
			package_known(self.player,"distanceTo",enemy) <= 1 + correct_target(self,"DistanceLimit",disclosed_card(self,card[5])) then
				table.insert(targets,package_known(enemy,"objectName"))
				break
			end
		end
		if #targets > 0 then
			return card[5] .. "->" .. table.concat(targets,"+")
		else
			return "."
		end
	elseif card[2] == "indulgence" then
		package_call(self,"sort",self.enemies, "hp")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"containsTrick","indulgence")) and (not package_known(enemy,"isProhibited",enemy, disclosed_card(self,card[5]))) then
				table.insert(targets,package_known(enemy,"objectName"))
				break
			end
		end
		if #targets > 0 then
			return card[5] .. "->" .. table.concat(targets,"+")
		else
			return "."
		end
	elseif card[2] == "tactical_combo" then
		local targets = {}
		local friends = self.friends

		for _,friend in pairs(self.friends) do
			if package_known(friend,"isProhibited",friend, disclosed_card(self,card[5])) then
				table.removeOne(friends, friend)
			end
		end

		for i = 1, 2, 1 do
			local n = math.random(#friends)
			table.insert(targets, package_known(friends[n],"objectName"))
			table.removeOne(friends, friends[n])
			if #friends == 0 then break end
		end
		if #targets > 0 then
			return card[5] .. "->" .. table.concat(targets,"+")
		else
			return "."
		end
	elseif package_known(card[2],"endsWith","shoot") then
		package_call(self,"sort",self.enemies, "defense")
		local targets = {}
		for _,enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isProhibited",enemy, disclosed_card(self,card[5]))) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",disclosed_card(self,card[5])) then break end
				table.insert(targets,package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return card[5] .. "->" .. table.concat(targets,"+")
		else
			return "."
		end
	else
		local dummy_use = package_known(self,"aiUseCard",disclosed_card(self,card[5]), dummy())
		if dummy_use and dummy_use.card and dummy_use.to and package_known(dummy_use.to,"length") > 0 then
			local targets = {}
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets,package_known(p,"objectName"))
			end
			return card[5] .. "->" .. table.concat(targets,"+")
		end
	end
	return "."
end











sgs.ai_skill_invoke.baizhan = function(self, data)
	local damage = package_known(data,"toDamage")
	return not package_known(self,"isFriend",damage.to)
end

ai_skill_use["@@baizhan"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	local name = source_property(self,"baizhan"):toString()
	local num = package_known(self.player,"getStrategyMark","baizhan")
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)

	for _, card in ipairs(cards) do
		if package_known(card,"getNumber") > num and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player))
			and (package_known(self.player,"getHp") > 1 or (not isCard("Jink", card, self.player) and not isCard("Analeptic", card, self.player))) then

			local baizhan_card = clone_native(self,name)
			package_call(baizhan_card,"addSubcard",card)

			if name == "slash" or name == "fire_slash" or name == "thunder_slash" then
				package_call(self,"sort",self.enemies, "defense")
				local targets = {}
				for _,enemy in ipairs(self.enemies) do
					if (not package_known(self,"slashProhibit",baizhan_card, enemy)) and package_known(self.player,"canSlash",enemy, baizhan_card) then
						if #targets >= 1 + correct_target(self,"ExtraTarget",baizhan_card) then break end
						table.insert(targets,package_known(enemy,"objectName"))
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "peach" or name == "analeptic" or name == "ex_nihilo" or name == "amazing_grace" or name == "savage_assault" or name == "archery_attack" or name == "god_salvation" then
				return ("%s:baizhan[%s:%s]=%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"))
			elseif name == "iron_chain" then








































				local use = dummy(false)
				package_call(self,"useTrickCard",baizhan_card, use)
				if use.card and use.to and not package_known(use.to,"isEmpty") then
					local targets = {}
					for _, p in sgs.qlist(use.to) do
						table.insert(targets, package_known(p,"objectName"))
					end
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "fire_attack" then
				package_call(self,"sort",self.enemies, "hp")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not package_known(enemy,"isKongcheng")) and (not package_known(enemy,"isProhibited",enemy, baizhan_card)) then
						if #targets >= 1 + correct_target(self,"ExtraTarget",baizhan_card) then break end
						table.insert(targets,package_known(enemy,"objectName"))
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "dismantlement" then
				package_call(self,"sort",self.enemies, "handcard")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not package_known(enemy,"isAllNude")) and (not package_known(enemy,"isProhibited",enemy, baizhan_card)) then
						if #targets >= 1 + correct_target(self,"ExtraTarget",baizhan_card) then break end
						table.insert(targets,package_known(enemy,"objectName"))
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "snatch" then
				package_call(self,"sort",self.enemies, "handcard")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not package_known(enemy,"isAllNude")) and (not package_known(enemy,"isProhibited",enemy, baizhan_card)) and
					package_known(self.player,"distanceTo",enemy) <= 1 + correct_target(self,"DistanceLimit",baizhan_card) then
						if #targets >= 1 + correct_target(self,"ExtraTarget",baizhan_card) then break end
						table.insert(targets,package_known(enemy,"objectName"))
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "collateral" then
				package_call(self,"sort",self.enemies, "handcard")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if package_call(enemy,"getWeapon") and (not package_known(enemy,"isProhibited",enemy, baizhan_card)) then
						for _, tos in ipairs(self.enemies) do
							if package_known(enemy,"objectName") ~= package_known(tos,"objectName") and
							package_known(enemy,"canSlash",tos, clone_native(self,"slash", sgs.Card_NoSuit, 0)) and
							(not package_known(tos,"isProhibited",tos, clone_native(self,"slash", sgs.Card_NoSuit, 0))) then
								table.insert(targets,package_known(enemy,"objectName"))
								table.insert(targets,package_known(tos,"objectName"))
								break
							end
						end
					end
				end
				if #targets > 1 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "duel" then
				package_call(self,"sort",self.enemies, "handcard")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not package_known(enemy,"isProhibited",enemy, baizhan_card)) then
						if #targets >= 1 + correct_target(self,"ExtraTarget",baizhan_card) then break end
						table.insert(targets,package_known(enemy,"objectName"))
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "supply_shortage" then
				package_call(self,"sort",self.enemies, "handcard")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not package_known(enemy,"containsTrick","supply_shortage")) and
					(not package_known(enemy,"isProhibited",enemy, baizhan_card)) and
					package_known(self.player,"distanceTo",enemy) <= 1 + correct_target(self,"DistanceLimit",baizhan_card) then
						table.insert(targets,package_known(enemy,"objectName"))
						break
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "indulgence" then
				package_call(self,"sort",self.enemies, "hp")
				local targets = {}
				for _, enemy in ipairs(self.enemies) do
					if (not package_known(enemy,"containsTrick","indulgence")) and (not package_known(enemy,"isProhibited",enemy, baizhan_card)) then
						table.insert(targets,package_known(enemy,"objectName"))
						break
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"),table.concat(targets,"+"))
				else
					return "."
				end
			elseif package_known(name,"endsWith","shoot") then
				package_call(self,"sort",self.enemies, "defense")
				local targets = {}
				for _,enemy in ipairs(self.enemies) do
					if (not package_known(self,"slashProhibit",baizhan_card, enemy)) then
						if #targets >= 1 + correct_target(self,"ExtraTarget",baizhan_card) then break end
						table.insert(targets,package_known(enemy,"objectName"))
					end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"),table.concat(targets,"+"))
				else
					return "."
				end
			elseif name == "tactical_combo" then
				local targets = {}
				local friends = self.friends

				for _,friend in pairs(self.friends) do
					if package_known(friend,"isProhibited",friend, disclosed_card(self,card[5])) then
						table.removeOne(friends, friend)
					end
				end

				for i = 1, 2, 1 do
					local n = math.random(#friends)
					table.insert(targets, package_known(friends[n],"objectName"))
					table.removeOne(friends, friends[n])
					if #friends == 0 then break end
				end
				if #targets > 0 then
					return ("%s:baizhan[%s:%s]=%s->%s"):format(name,package_known(card,"getSuitString"),package_known(card,"getNumberString"),package_known(card,"getId"),table.concat(targets,"+"))
				else
					return "."
				end
			end
		end
	end
	return "."
end

local gaoda_zhongjie_skill = {}
gaoda_zhongjie_skill.name = "gaoda_zhongjie"
table.insert(package_skills, gaoda_zhongjie_skill)
gaoda_zhongjie_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.enemies == 0 then return false end
	package_call(self,"sort",self.enemies, "hp")
	local pierce_shoot = clone_native(self,"pierce_shoot", sgs.Card_NoSuit, 0)
	package_call(pierce_shoot,"setSkillName","gaoda_zhongjiecard")
	package_call(pierce_shoot,"deleteLater")
	if package_known(self.player,"isProhibited",self.enemies[1], pierce_shoot) then return false end
	if package_known(self.player,"getStrategyMark","@gaoda_zhongjie") > 0 and ((package_known(self.player,"getHp") <= 1 and package_known(self.room,"alivePlayerCount") > 2 and not package_known(self.player,"isLord")) or
		(package_known(self.player,"getHp") <= 2 and package_known(self,"isWeak") and #self.enemies == 1 and package_known(self.enemies[1],"getHp") == 1)) then
		return source_construct(self,"#gaoda_zhongjie:.:")
	end
end

sgs.ai_skill_use_func["#gaoda_zhongjie"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "hp")
	use.card = card
	if use.to then
		package_call(use.to,"append",self.enemies[1])
		return
	end
end

sgs.ai_use_value["gaoda_zhongjie"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["gaoda_zhongjie"] = 0.01


sgs.ai_skill_invoke.huixing = function(self, data)
	if package_known(self.player,"getPhase") == sgs.Player_Draw then
		return true
	else
		local resp = package_known(data,"toCardResponse")
		return not package_known(self,"isFriend",resp.m_who)
	end
end


local bianxing_skill = {}
bianxing_skill.name = "bianxing"
table.insert(package_skills, bianxing_skill)
bianxing_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","#bianxing") then return false end
	if package_known(self.player,"hasSkill","jvjian") then
		if #self.enemies == 0 or package_known(self,"getCardsNum","Slash") == 0 or package_known(self.player,"getCardCount") <= 1 then return false end
		package_call(self,"sort",self.enemies, "defenseSlash")
		local f = function(a, b)
			return package_known(self.player,"distanceTo",a) < package_known(self.player,"distanceTo",b)
		end
		table.sort(self.enemies, f)
		if not package_known(self,"slashProhibit",clone_native(self,"slash"), self.enemies[1]) and package_known(self.player,"distanceTo",self.enemies[1]) - package_known(self.player,"getAttackRange") <= 1
			and (package_known(self.player,"distanceTo",self.enemies[1]) - package_known(self.player,"getAttackRange") == 1 or package_known(self,"getCardsNum","Slash") > 1 or package_call(self.enemies[1],"getArmor")) then
			return source_construct(self,"#bianxing:.:")
		end
	elseif package_known(self.player,"hasSkill","tuci") then
		if package_known(self.player,"getCardCount") > 1 and not fact(self,"slash_available") then
			return source_construct(self,"#bianxing:.:")
		end
	end
end

sgs.ai_skill_use_func["#bianxing"] = function(card,use,self,request)
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByUseValue",cards, true)
	for _,card in ipairs(cards) do do
		if package_known(card,"isKindOf","Peach") or package_known(card,"isKindOf","ExNihilo") then goto package_continue_1 end
		if package_known(card,"isKindOf","Jink") and package_known(self,"getCardsNum","Jink") == 1 then goto package_continue_1 end
		if package_known(self.player,"hasSkill","jvjian") and package_known(card,"isKindOf","Slash") and package_known(self,"getCardsNum","Slash") == 1 then goto package_continue_1 end
		use.card = source_construct(self,"#bianxing:"..package_known(card,"getId")..":")
		return
	end ::package_continue_1:: end
end

sgs.ai_use_value["bianxing"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["bianxing"] = sgs.ai_use_value.Slash + 1

ai_skill_use["@@bianxing!"]=function(self,prompt,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	for _,card in ipairs(cards) do do
		if package_known(card,"isKindOf","Peach") or package_known(card,"isKindOf","ExNihilo") then goto package_continue_2 end
		if package_known(card,"isKindOf","Jink") and package_known(self,"getCardsNum","Jink") == 1 then goto package_continue_2 end
		if package_known(card,"isKindOf","Slash") and package_known(self,"getCardsNum","Slash") == 1 then goto package_continue_2 end
		return ("#bianxing:"..package_known(card,"getId")..":")
	end ::package_continue_2:: end
end

sgs.ai_skill_invoke.gaoda_chihun = function(self, data)
	return true
end

sgs.ai_can_damagehp.gaoda_chihun = function(self,from,card,to)
	return package_known(to,"getHp")+package_known(self,"getAllPeachNum")-package_known(self,"ajustDamage",from,to,1,card)>0
	and package_known(self,"canLoseHp",from,card,to) and package_known(to,"getStrategyMark","@gaoda_chihun") == 0
end

local jvjian_skill = {}
jvjian_skill.name = "jvjian"
table.insert(package_skills, jvjian_skill)
jvjian_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@gaoda_chihun") > 0 and package_known(self.player,"getStrategyMark","@jvjian") > 0 and #self.enemies > 0 then
		for _,card in sgs.qlist(package_known(self.player,"getCards","he")) do
			if package_known(card,"isKindOf","Weapon") and package_known(card,"isRed") then
				return source_construct(self,"#jvjian:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#jvjian"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "hp")
	for _,card in sgs.qlist(package_known(self.player,"getCards","he")) do
		use.card = source_construct(self,"#jvjian:" .. package_known(card,"getId") .. ":")
		if use.to then package_call(use.to,"append",self.enemies[1]) end
		return
	end
end

sgs.ai_use_value["jvjian"] = sgs.ai_use_value.Slash * 2
sgs.ai_use_priority["jvjian"] = sgs.ai_use_priority.Slash

sgs.ai_skill_choice.chonglang = function(self, choices, data)
	choices = package_known(choices,"split","+")
	local use = package_known(data,"toCardUse")
	if table.contains(choices, "chonglangB") then
		if package_known(use.to,"first"):getArmor() then
			return "chonglangB"
		end
	end
	if table.contains(choices, "chonglangA") then
		if package_known(self.player,"getCardCount") > 1 and (not package_known(self.player,"hasUsed","#bianxing") or package_known(self,"getCardsNum","Slash") > 0)then
			return "chonglangA"
		else
			if table.contains(choices, "chonglangB") then
				return "chonglangB"
			end
		end
	end
	return "cancel"
end

local tuci_skill = {}
tuci_skill.name = "tuci"
table.insert(package_skills, tuci_skill)
tuci_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@gaoda_chihun") > 0 and package_known(self.player,"getStrategyMark","@tuci") > 0 and #self.enemies > 0 then
		local x = 1
		for _,p in sgs.qlist(package_known(self.room,"getPlayers")) do
			if package_known(p,"objectName") ~= package_known(self.player,"objectName") and package_known(p,"isDead") then
				x = x + 1
			end
		end
		if x >= (package_known(self.player,"getHp") + package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic"))
			and (package_known(self.player,"isLord") or #self.friends_noself == 0) then return false end
		for _, enemy in ipairs(self.enemies) do
			if package_known(self.player,"inMyAttackRange",enemy) then
				return source_construct(self,"#tuci:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#tuci"] = function(card,use,self,request)
	local f = function(a, b)
		return package_known(a,"getLostHp") < package_known(b,"getLostHp")
	end
	table.sort(self.enemies, f)
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"inMyAttackRange",enemy) then
			use.card = source_construct(self,"#tuci:.:")
			if use.to then package_call(use.to,"append",self.enemies[1]) end
			return
		end
	end
end

sgs.ai_use_value["tuci"] = 2.33
sgs.ai_use_priority["tuci"] = sgs.ai_use_value.Slash + 2.33


sgs.ai_skill_invoke.shenshou = function(self, data)
	local target = package_call(data,"toPlayer")
	return package_known(self,"isEnemy",target)
end

sgs.ai_skill_cardask["@@shenshou"] = function(self)
	if package_known(self.player,"hasSkill","xiaya") then
		return package_known(self,"getSuitNum","red",true,self.player) > 1
	elseif package_known(self.player,"hasSkill","huanyi") and package_known(self.player,"getStrategyMark","@huanyi") > 0 then
		return package_known(self,"getSuitNum","red",true,self.player) > 1 and package_known(self,"getSuitNum","red",false,self.player) > 0
	elseif package_known(self.player,"getStrategyMark","@supermode") > 0 and package_known(self.player,"getStrategyMark","jingxin") > 0 and package_known(self.player,"getStrategyMark","@point") > 0 then
		return package_known(self,"getSuitNum","red",true,self.player) > 0
	else
		if (package_known(self,"getCardsNum","Peach") > 0) or (package_known(self,"getSuitNum","red",true,self.player) < 2) or (package_known(self,"getCardsNum","Jink") == 0) then return "." end
		for _, card in sgs.qlist(package_known(self.player,"getCards","he")) do
			if package_known(self,"getCardsNum","Jink") > 1 then
				if package_known(card,"isRed") then
					return package_known(card,"getEffectiveId")
				end
			else
				if package_known(card,"isRed") and not isCard("Jink", card, self.player) then
					return package_known(card,"getEffectiveId")
				end
			end
		end
	end
end

sgs.ai_skill_choice.NTD = function(self, choices, data)
	return "ntdrecover"
end

sgs.ai_skill_invoke.huimie = function(self, data)
	local use = package_known(data,"toCardUse")
	return not package_known(use.card,"isKindOf","GodSalvation") and not package_known(use.card,"isKindOf","AmazingGrace") and package_known(self,"isEnemy",use.from) and package_known(self,"getSuitNum","red",false,self.player) > 0
end

sgs.ai_skill_cardask["@huimie"] = function(self,data,pattern)
	local use = package_known(data,"toCardUse")
	if sgs.ai_skill_use["@@huimie"](self, "#huimie:"..package_known(use.card,"objectName")) == "." then return "." end
	local player = self.player
	local cards = package_known(player,"getCards","he")
	cards = sgs.QList2Table(cards)
    package_call(self,"sortByKeepValue",cards)
   	for _,c in sgs.list(cards)do
    	if match_pattern(self,player,pattern,c)
		then return package_known(c,"getEffectiveId") end
	end
    return "."
end
ai_skill_use["@@huimie"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	local card = package_known(prompt,"split",":")
	if card[2] == "iron_chain" then








































		local use = dummy(false)
		package_call(self,"useTrickCard",clone_native(self,card[2], sgs.Card_NoSuit, 0), use)
		if use.card and use.to and not package_known(use.to,"isEmpty") then
			local targets = {}
			for _, p in sgs.qlist(use.to) do
				table.insert(targets, package_known(p,"objectName"))
			end
			return ("%s:huimiecard[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
		else
			return "."
		end
	end
	if card[2] == "fire_attack" then
		package_call(self,"sort",self.enemies, "hp")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isKongcheng")) and (not package_known(enemy,"isProhibited",enemy, clone_native(self,card[2], sgs.Card_NoSuit, 0))) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",clone_native(self,card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets,package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return ("%s:huimiecard[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
		else
			return "."
		end
	end
	if card[2] == "dismantlement" then
		package_call(self,"sort",self.enemies, "handcard")
		local targets = {}
		for _, friend in ipairs(self.friends_noself) do
			if (package_known(friend,"containsTrick","indulgence") or package_known(friend,"containsTrick","supply_shortage")) and (not package_known(friend,"isProhibited",friend, clone_native(self,card[2], sgs.Card_NoSuit, 0))) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",clone_native(self,card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets, package_known(friend,"objectName"))
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isAllNude")) and (not package_known(enemy,"isProhibited",enemy, clone_native(self,card[2], sgs.Card_NoSuit, 0))) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",clone_native(self,card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets,package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return ("%s:huimiecard[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
		else
			return "."
		end
	end
	if card[2] == "snatch" then
		package_call(self,"sort",self.enemies, "handcard")
		local targets = {}
		for _, friend in ipairs(self.friends_noself) do
			if (package_known(friend,"containsTrick","indulgence") or package_known(friend,"containsTrick","supply_shortage")) and (not package_known(friend,"isProhibited",friend, clone_native(self,card[2], sgs.Card_NoSuit, 0))) and
			package_known(self.player,"distanceTo",friend) <= 1 + correct_target(self,"DistanceLimit",clone_native(self,card[2], sgs.Card_NoSuit, 0)) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",clone_native(self,card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets,package_known(friend,"objectName"))
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isAllNude")) and (not package_known(enemy,"isProhibited",enemy, clone_native(self,card[2], sgs.Card_NoSuit, 0))) and
			package_known(self.player,"distanceTo",enemy) <= 1 + correct_target(self,"DistanceLimit",clone_native(self,card[2], sgs.Card_NoSuit, 0)) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",clone_native(self,card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets,package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return ("%s:huimiecard[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
		else
			return "."
		end
	end
	if card[2] == "collateral" then
		package_call(self,"sort",self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if package_call(enemy,"getWeapon") and (not package_known(enemy,"isProhibited",enemy, clone_native(self,card[2], sgs.Card_NoSuit, 0))) then
				for _, tos in ipairs(self.enemies) do
					if package_known(enemy,"objectName") ~= package_known(tos,"objectName") and
					package_known(enemy,"canSlash",tos, clone_native(self,"slash", sgs.Card_NoSuit, 0)) and
					(not package_known(tos,"isProhibited",tos, clone_native(self,"slash", sgs.Card_NoSuit, 0))) then
						table.insert(targets,package_known(enemy,"objectName"))
						table.insert(targets,package_known(tos,"objectName"))
						break
					end
				end
			end
		end
		if #targets > 1 then
			return ("%s:huimiecard[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
		else
			return "."
		end
	end
	if card[2] == "duel" then
		package_call(self,"sort",self.enemies, "handcard")
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isProhibited",enemy, clone_native(self,card[2], sgs.Card_NoSuit, 0))) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",clone_native(self,card[2], sgs.Card_NoSuit, 0)) then break end
				table.insert(targets,package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return ("%s:huimiecard[no_suit:0]=.->%s"):format(card[2], table.concat(targets,"+"))
		else
			return "."
		end
	end
	return "."
end

sgs.NTD_suit_value = {
	heart = 3.9,
	diamond = 3.9
}

function sgs.ai_cardneed.NTD(to, card)
	return package_known(card,"isRed")
end



Set=function(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

local zhonggong_skill = {}
zhonggong_skill.name = "zhonggong"
table.insert(package_skills, zhonggong_skill)
zhonggong_skill.getTurnUseCard = function(self,inclusive,request)
	if (not package_known(self.player,"hasUsed","#zhonggong")) and package_known(self.player,"hasEquipArea") then
		return source_construct(self,"#zhonggong:.:")
	end
end

sgs.ai_skill_use_func["#zhonggong"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		use.card = source_construct(self,"#zhonggong:.:")
		if use.to then package_call(use.to,"append",enemy) end
		return
	end
end

sgs.ai_skill_choice.zhonggong = function(self, choices, data)
	local equips = package_known(choices,"split","+")
	for _,installed in sgs.qlist(package_known(self.player,"getEquips")) do
		for _,equip in ipairs(equips) do



			if equip ~= "@Equip"..package_known(installed,"getRealCard"):toEquipCard():location().."lose" then
				return equip
			end
		end
	end
end

sgs.ai_use_value["zhonggong"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["zhonggong"] = sgs.ai_use_priority.Slash + 1

sgs.ai_target_revises.qingzhuang = function(to,card)
	if package_known(card,"isKindOf","Slash") and package_known(card,"isRed") and not package_known(to,"hasEquipArea")
	then return true end
end

local linguang_skill = {}
linguang_skill.name = "linguang"
table.insert(package_skills, linguang_skill)
linguang_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@linguang") > 0 and package_known(self.player,"isWounded") then
		if (package_known(self.player,"getHp") > 1 and not package_known(self.player,"hasEquipArea")) or package_known(self.player,"getHp") == 1 then
			return source_construct(self,"#linguang:.:")
		end
	end
end

sgs.ai_skill_use_func["#linguang"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["linguang"] = sgs.ai_use_value.Peach + 0.1
sgs.ai_use_priority["linguang"] = sgs.ai_use_priority.Peach - 0.1


sgs.ai_skill_invoke.qingyu = function(self, data)
	return #self.enemies > 0
end

ai_skill_use["@@qingyu"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	if prompt == "#qingyu1" then
		return ("savage_assault:qingyu[spade:0]=.")
	elseif prompt == "#qingyu2" then
		return ("archery_attack:qingyu[heart:0]=.")
	elseif prompt == "#qingyu3" then
		package_call(self,"sort",self.enemies, "handcard_defense")
		local targets = {}
		local card = clone_native(self,"dismantlement", sgs.Card_Club, 0)
		for _,enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isProhibited",enemy, card)) and (not package_known(enemy,"isAllNude")) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",card) then break end
				table.insert(targets, package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return ("dismantlement:qingyu[club:0]=.->%s"):format(table.concat(targets,"+"))
		else
			return "."
		end
	elseif prompt == "#qingyu4" then
		package_call(self,"sort",self.enemies, "handcard_defense")
		local targets = {}
		local card = clone_native(self,"snatch", sgs.Card_Club, 0)
		for _,enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isProhibited",enemy, card)) and (not package_known(enemy,"isAllNude")) and
			package_known(self.player,"distanceTo",enemy) <= 1 + correct_target(self,"DistanceLimit",card) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",card) then break end
				table.insert(targets, package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return ("snatch:qingyu[diamond:0]=.->%s"):format(table.concat(targets,"+"))
		else
			return "."
		end
	end
	return "."
end

sgs.ai_skill_invoke.siyi = function(self, data)
	local use = package_known(data,"toCardUse")
	if package_known(use.card,"isKindOf","AOE") then
		return #self.friends_noself > 0
	elseif package_known(use.card,"isKindOf","GlobalEffect") then
		return #self.enemies > 0
	else
		for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do do
			if (package_known(use.to,"contains",p) or package_known(self.room,"isProhibited",self.player, p, use.card)) then goto package_continue_3 end
			if (package_known(use.card,"targetFilter",sgs.PlayerList(), p, self.player) and package_known(self,"isEnemy",p)) then
				return true
			end
		end ::package_continue_3:: end
	end
	return false
end

ai_skill_use["@@siyi"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	if prompt == "#siyi1" then
		package_call(self,"sort",self.friends_noself, "hp")
		local selectset = {}
		for _, friend in ipairs(self.friends_noself) do
			if package_known(friend,"getStrategyFlag","siyitarget") then
				table.insert(selectset, package_known(friend,"objectName"))
				if #selectset >= package_known(self.player,"getEquips"):length() then break end
			end
		end
		if #selectset > 0 then
			return ("#siyi:.:->%s"):format(table.concat(selectset,"+"))
		else
			return "."
		end
	elseif prompt == "#siyi2" then
		package_call(self,"sort",self.enemies, "hp")
		local selectset = {}
		for _, enemy in ipairs(self.enemies) do
			if package_known(enemy,"getStrategyFlag","siyitarget") then
				table.insert(selectset, package_known(enemy,"objectName"))
				if #selectset >= package_known(self.player,"getEquips"):length() then break end
			end
		end
		if #selectset > 0 then
			return ("#siyi:.:->%s"):format(table.concat(selectset,"+"))
		else
			return "."
		end
	end
	return "."
end


sgs.ai_view_as.xiaya = function(card, player, card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if package_known(card,"isRed") then
		return ("jink:xiaya[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_skill_invoke.zaishi = function(self, data)
	return true
end

sgs.ai_skill_askforag["zaishi"] = function(self, card_ids)
	local cards = {}
	for _, id in ipairs(card_ids) do
		table.insert(cards, disclosed_card(self,id))
	end
	package_call(self,"sortByUseValue",cards, false)
	return package_known(cards[1],"getId")
end

sgs.ai_skill_invoke.wangling = function(self, data)
	local damage = package_known(data,"toDamage")

	local guard = 0
	if (package_known(self,"getCardsNum","Guard") + package_known(self,"getCardsNum","CounterGuard")) > 0 and damage.card and package_known(damage.card,"objectName"):endsWith("shoot") and package_known(damage.card,"objectName") ~= "pierce_shoot" then
		guard = 1
	end

	return package_known(self.player,"getHp") <= damage.damage and (package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") + guard) < (damage.damage - package_known(self.player,"getHp") + 1)
		and ((not damage.from) or (damage.from and package_known(self,"isEnemy",damage.from)))
end

sgs.ai_skill_choice.wangling = function(self, choices, data)
	choices = package_known(choices,"split","+")
	if table.contains(choices, "zaishi") then
		if package_known(self,"getSuitNum","red",true,self.player) > 1 then
			return "zaishi"
		end
	end
	if table.contains(choices, "xiaya") then
		if package_known(self,"getSuitNum","red",true,self.player) < 1 then
			return "xiaya"
		end
	end
	return choices[1]
end


sgs.ai_skill_invoke.duilie = function(self, data)
	local promptlist = package_known(data,"toString"):split(":")
	local effect = promptlist[1]
	local enemy = package_call(self.room,"findPlayerByObjectName",promptlist[2])
	if effect == "throw" then
		return enemy and package_known(self,"isEnemy",enemy)
	else
		return true
	end
end

sgs.ai_target_revises.duilie = function(to,card)
	if package_known(to,"getStrategyMark","@duilieB") > 0 and math.mod(package_known(card,"getNumber"),2) == 0 and package_known(card,"getNumber") > 0
	then return true end
end



sgs.ai_skill_invoke.zhihui = function(self, data)
	local friend = 0
	for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(self,"isFriend",p) and package_known(self.player,"inMyAttackRange",p) then
			friend = friend + 1
		end
	end
	return friend > 0
end

sgs.ai_skill_playerchosen.zhihui = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if package_known(self,"isFriend",target) then
			return target
		end
	end
end


local xiezhan_skill = {}
xiezhan_skill.name = "xiezhan"
table.insert(package_skills, xiezhan_skill)
xiezhan_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"isNude") then return false end
	return source_construct(self,"#xiezhan:.:")
end

sgs.ai_skill_use_func["#xiezhan"] = function(card,use,self,request)
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByUseValue",cards, true)
	for _,card in ipairs(cards) do
		for _,friend in ipairs(self.friends_noself) do
			local card_id = package_known(card,"getId")
			local range_fix = 0
			if package_call(self.player,"getWeapon") and package_call(self.player,"getWeapon"):getId() == card_id then
				local weapon = package_call(self.player,"getWeapon"):getRealCard():toWeapon()
				range_fix = range_fix + package_known(weapon,"getRange") - 1
			elseif package_known(self.player,"getOffensiveHorse") and package_known(self.player,"getOffensiveHorse"):getId() == card_id then
				range_fix = range_fix + 1
			end
			local i = package_known(card,"getRealCard"):toEquipCard():location()
			if ((package_known(card,"isKindOf","Weapon") and package_call(friend,"getWeapon") == nil) or
				(package_known(card,"isKindOf","Armor") and package_call(friend,"getArmor") == nil) or
				(package_known(card,"isKindOf","DefensiveHorse") and package_known(friend,"getDefensiveHorse") == nil) or
				(package_known(card,"isKindOf","OffensiveHorse") and package_known(friend,"getOffensiveHorse") == nil) or
				(package_known(card,"isKindOf","Treasure") and package_known(friend,"getTreasure") == nil)) and
				package_known(self.player,"distanceTo",friend, range_fix) <= package_known(self.player,"getAttackRange") and sgs.Slash_IsAvailable(friend) and package_known(friend,"hasEquipArea",i) then
				use.card = source_construct(self,"#xiezhan:"..card_id..":")
				if use.to then package_call(use.to,"append",friend) end
				return
			end
		end
	end
end

sgs.ai_skill_playerchosen["xiezhan"] = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if package_known(self,"isEnemy",target) then
			return target
		end
	end
end

sgs.ai_use_value["xiezhan"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["xiezhan"] = sgs.ai_use_priority.Slash

local tupo_skill = {}
tupo_skill.name = "tupo"
table.insert(package_skills, tupo_skill)
tupo_skill.getTurnUseCard = function(self,inclusive,request)
	local card = clone_native(self,"collateral", sgs.Card_NoSuit, 0)
	if package_known(card,"isAvailable",self.player) and (not package_known(self.player,"getStrategyFlag","tupo_used")) and package_known(self.player,"getHp") > 1 then
		local card_str = ("collateral:tupo[no_suit:0]=.")
		local card = source_construct(self,card_str)
		return card
	end
end

sgs.ai_skill_playerchosen["tupo"] = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if package_known(self,"isEnemy",target) then
			return target
		end
	end
end

sgs.ai_use_value["tupo"] = sgs.ai_use_value.Collateral
sgs.ai_use_priority["tupo"] = sgs.ai_use_priority.Collateral


Set=function(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

shuffle=function(self,tbl)
	source_clock_seed(self)
	for i = #tbl, 2, -1 do
		local j = source_shuffle_random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

ai_skill_use["@@gaoda_zhanshi"]=function(self,prompt,request)
	local tricks = {"snatch", "dismantlement", "collateral", "ex_nihilo", "duel",  "savage_assault", "archery_attack", "god_salvation"}
	if not (Set(native_bans(self)))["maneuvering"] then
		table.insert(tricks, "fire_attack")
		table.insert(tricks, "iron_chain")
	end
	if not (Set(native_bans(self)))["gaodacard"] then
		table.insert(tricks, "tactical_combo")
	end

	shuffle(self,tricks)

	for _, trick in ipairs(tricks) do do
		local qicecard = clone_native(self,trick)
		package_call(qicecard,"setSkillName","gaoda_zhanshi")

		if package_known(self.player,"isCardLimited",qicecard, sgs.Card_MethodUse, true) or not package_known(qicecard,"isAvailable",self.player) then goto package_continue_4 end

		local use = dummy(false)
		package_call(self,"useTrickCard",qicecard, use)
		if use.card then

			if package_known(qicecard,"canRecast") and package_known(use.to,"isEmpty") then goto package_continue_4 end

			if trick == "god_salvation" and not package_known(self,"willUseGodSalvation",qicecard) then goto package_continue_4 end

			if use.to then

				if trick == "tactical_combo" and package_known(use.to,"length") == 1 and package_known(use.to,"contains",self.player) and package_known(self,"getCardsNum","Slash") == 0 then goto package_continue_4 end

				local targets = {}
				for _, p in sgs.qlist(use.to) do
					table.insert(targets, package_known(p,"objectName"))
				end
				return ("%s:gaoda_zhanshi[no_suit:0]=.->%s"):format(trick, table.concat(targets, "+"))
			end

			return ("%s:gaoda_zhanshi[no_suit:0]=."):format(trick)
		end
	end ::package_continue_4:: end

	return "."
end

sgs.ai_skill_choice.gaoda_zhanshi = function(self, choices, data)
	local choice = package_known(choices,"split","+")
	return choice[math.random(1, #choice)]
end

sgs.ai_target_revises["@renwang_shield"] = function(to,card,self)
	if package_known(card,"isBlack") and package_known(card,"isKindOf","Slash") and not package_known(card,"hasFlag","qinggang")
	then return true end
end
sgs.ai_ajustdamage_to["@vine"] = function(self,from,to,card,nature)
	if nature=="F" and not IgnoreArmor(from,to)
	then return 1 end
end
sgs.ai_target_revises["@vine"] = function(to,card)
	if package_known(card,"isKindOf","SavageAssault")
	or package_known(card,"isKindOf","ArcheryAttack")
	or package_known(card,"isKindOf","Chuqibuyi")
	or package_known(card,"objectName")=="slash"
	then return true end
end


sgs.gaoda_zhanshi_suit_value = {
	spade = 3,
	club = 3
}

function sgs.ai_cardneed.anzhang(to, card)
	return package_known(card,"isBlack") and package_known(card,"isKindOf","BasicCard")
end


ai_skill_use["@@zhenya"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "handcard")
	if package_known(self.player,"getHandcardNum") <= 1 or package_known(self.player,"getHp") <= 1 then return "." end
	if (package_known(self.player,"containsTrick","indulgence") or package_known(self.player,"containsTrick","supply_shortage")) and package_known(self,"getCardsNum","Nullification") == 0 then return "." end
	if #self.enemies > 1 then
		return ("#zhenya:.:->%s+%s"):format(package_known(self.enemies[1],"objectName"), package_known(self.enemies[2],"objectName"))
	elseif #self.enemies == 1 and #self.friends_noself > 0 then
		for _, friend in ipairs(self.friends_noself) do
			local card = clone_native(self,"dismantlement")
			if package_known(self,"hasTrickEffective",card, friend, self.player) then
				if package_known(friend,"containsTrick","indulgence") or package_known(friend,"containsTrick","supply_shortage") then
					return ("#zhenya:.:->%s+%s"):format(package_known(self.enemies[1],"objectName"), package_known(friend,"objectName"))
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.zhenya = function(self, data)
	local prompt = package_known(data,"toString"):split(":")
	local target = package_call(self.room,"findPlayerByObjectName",prompt[2])
	if package_known(self,"isFriend",target) then
		if table.contains(prompt, "dismantlement") then
			local card = clone_native(self,"dismantlement")
			if package_known(self,"hasTrickEffective",card, target, self.player) then
				if package_known(target,"containsTrick","indulgence") or package_known(target,"containsTrick","supply_shortage") then
					return true
				end
			end
		end
	else
		for i = 3, #prompt do
			local card = clone_native(self,prompt[i])
			if package_known(self,"hasTrickEffective",card, target, self.player) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_choice.zhenya = function(self, choices, data)
	choices = package_known(choices,"split","+")
	local target = package_call(data,"toPlayer")
	for _, choice in ipairs(choices) do do
		if package_known(self,"isFriend",target) and choice ~= "dismantlement" then goto package_continue_5 end
		local card = clone_native(self,choice)
		if package_known(self,"hasTrickEffective",card, target, self.player) then
			return choice
		end
	end ::package_continue_5:: end
	return choices[1]
end

sgs.ai_skill_invoke.quzhu = function(self, data)
	local prompt = package_known(data,"toString"):split(":")
	local target = package_call(self.room,"findPlayerByObjectName",prompt[2])
	if package_known(self,"isEnemy",target) then
		return true
	end
	return false
end


sgs.ai_skill_invoke.mengshi = function(self, data)
	local use = package_known(data,"toCardUse")
	for _,p in sgs.qlist(use.to) do
		if package_known(self,"isEnemy",p) then
			return not (package_known(p,"isWounded") and package_call(p,"getArmor") and package_known(p,"getEquips"):length() == 1 and package_call(p,"getArmor"):getClassName() == "SilverLion")
		elseif package_known(self,"isFriend",p) then
			return (package_known(p,"isWounded") and package_call(p,"getArmor") and package_call(p,"getArmor"):getClassName() == "SilverLion")
		end
	end
	return false
end

sgs.ai_skill_cardchosen["mengshi"] = function(self, who, flags)
	local cards = sgs.QList2Table(package_known(who,"getEquips"))
	for i=1, #cards, 1 do
		if package_known(self,"isEnemy",who) then
			if not (package_known(who,"isWounded") and package_known(cards[i],"getClassName") == "SilverLion") then
				return cards[i]
			end
		elseif package_known(self,"isFriend",who) then
			if (package_known(who,"isWounded") and package_known(cards[i],"getClassName") == "SilverLion") then
				return cards[i]
			end
		end
	end
	return nil
end

local NTD2_skill = {}
NTD2_skill.name = "ntdtwo"
table.insert(package_skills,NTD2_skill)
NTD2_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@NTD2") > 0 and package_known(self.player,"isWounded") and package_known(self,"getSuitNum","black", false, self.player) > 0 then
		local card_str = ("#ntdtwo:%d:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#ntdtwo"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["ntdtwo"] = 5
sgs.ai_use_priority["ntdtwo"] = 9.2

ai_skill_use["@@ntdtwo"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "handcard")
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if (package_known(friend,"containsTrick","indulgence") or package_known(friend,"containsTrick","supply_shortage")) and (not package_known(friend,"isProhibited",friend, clone_native(self,"dismantlement", sgs.Card_NoSuit, 0))) then
			if #targets >= 1 + correct_target(self,"ExtraTarget",clone_native(self,"dismantlement", sgs.Card_NoSuit, 0)) then break end
			table.insert(targets, package_known(friend,"objectName"))
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if (not package_known(enemy,"isAllNude")) and (not package_known(enemy,"isProhibited",enemy, clone_native(self,"dismantlement", sgs.Card_NoSuit, 0))) then
			if #targets >= 1 + correct_target(self,"ExtraTarget",clone_native(self,"dismantlement", sgs.Card_NoSuit, 0)) then break end
			table.insert(targets, package_known(enemy,"objectName"))
		end
	end
	if #targets > 0 then
		return ("%s:ntdtwo[no_suit:0]=.->%s"):format("dismantlement", table.concat(targets,"+"))
	else
		return "."
	end
	return "."
end

sgs.NTD2_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.NTD2(to, card)
	return package_known(card,"isBlack")
end

sgs.ai_skill_invoke.baosang = function(self, data)
	local use = package_known(data,"toCardUse")
	if package_known(self,"getSuitNum","black", false, self.player) > 0 and package_known(self,"isEnemy",use.from) then
		for _,enemy in ipairs(self.enemies) do
			return ((not package_known(enemy,"containsTrick","indulgence")) and
				(not package_known(enemy,"isProhibited",enemy, clone_native(self,"indulgence", sgs.Card_NoSuit, 0)))) or
				((not package_known(enemy,"containsTrick","supply_shortage")) and
				(not package_known(enemy,"isProhibited",enemy, clone_native(self,"supply_shortage", sgs.Card_NoSuit, 0))))
		end
	end
	return false
end

sgs.ai_skill_choice.baosang = function(self, choices, data)
	for _,enemy in ipairs(self.enemies) do
		if (not package_known(enemy,"containsTrick","indulgence")) and
			(not package_known(enemy,"isProhibited",enemy, clone_native(self,"indulgence", sgs.Card_NoSuit, 0))) then
			return "indulgence"
		end
	end
	return "supply_shortage"
end

ai_skill_use["@@baosang"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	local pattern = package_known(prompt,"split",":")[2]
	local targets = {}
	if pattern == "indulgence" then
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"containsTrick",pattern)) and
				(not package_known(enemy,"isProhibited",enemy, clone_native(self,pattern, sgs.Card_NoSuit, 0))) then
				if #targets >= 1 then break end
				table.insert(targets, package_known(enemy,"objectName"))
			end
		end
		if #targets == 1 then
			local cards = package_known(self.player,"getCards","h")
			cards = sgs.QList2Table(cards)
			for _,card in ipairs(cards) do
				if package_known(card,"isBlack") then
					return ("%s:baosang[%s:%s]=%d->%s"):format(pattern, package_known(card,"getSuitString"), package_known(card,"getNumberString"), package_known(card,"getEffectiveId"), targets[1])
				end
			end
		else
			return "."
		end
	else
		package_call(self,"sort",self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"containsTrick",pattern)) and
				(not package_known(enemy,"isProhibited",enemy, clone_native(self,pattern, sgs.Card_NoSuit, 0))) and
				package_known(self.player,"distanceTo",enemy) <= 1 + correct_target(self,"DistanceLimit",clone_native(self,pattern, sgs.Card_NoSuit, 0)) then
				if #targets >= 1 then break end
				table.insert(targets, package_known(enemy,"objectName"))
			end
		end
		if #targets == 1 then
			local cards = package_known(self.player,"getCards","h")
			cards = sgs.QList2Table(cards)
			for _,card in ipairs(cards) do
				if package_known(card,"isBlack") then
					return ("%s:baosang[%s:%s]=%d->%s"):format(pattern, package_known(card,"getSuitString"), package_known(card,"getNumberString"), package_known(card,"getEffectiveId"), targets[1])
				end
			end
		else
			return "."
		end
	end
	return "."
end





































sgs.ai_skill_invoke.gaoda_shenshi = function(self, data)
	local use = package_known(data,"toCardUse")
	if package_known(use.from,"objectName") == package_known(self.player,"objectName") then
		local card = clone_native(self,"duel")
		package_call(card,"addSubcard",use.card)
		for _,p in sgs.qlist(use.to) do
			if package_known(self.player,"getStrategyMark","@xuanguang") > 0 and (package_known(use.card,"isKindOf","ThunderSlash") or package_known(use.card,"isKindOf","FireSlash"))
				and package_known(p,"getEquips"):isEmpty() then
				return true
			end
			if package_known(self,"hasHeavyDamage",self.player, use.card, p) then
				return false
			end
			if (not package_known(self,"hasTrickEffective",card, p, use.from)) and (package_known(self,"slashIsEffective",use.card, p, use.from, false)) then
				return false
			end
		end
		return true
	else
		if package_known(self.player,"getStrategyMark","@xuanguang") > 0 and (package_known(use.card,"isKindOf","ThunderSlash") or package_known(use.card,"isKindOf","FireSlash"))
			and package_known(self.player,"getEquips"):isEmpty() then
			return false
		end
		local card = clone_native(self,"duel")
		package_call(card,"addSubcard",use.card)
		if package_known(self,"hasTrickEffective",card, use.from, self.player) and (package_known(self,"getCardsNum","Slash") > 0 or package_known(self,"getCardsNum","Jink") == 0
			or package_known(self,"getCardsNum","Nullification") > 0 or package_known(self,"hasHeavyDamage",use.from, use.card, self.player)) then
			return true
		end
	end
end

local NTD3_skill = {}
NTD3_skill.name = "ntdthree"
table.insert(package_skills,NTD3_skill)
NTD3_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@NTD3") > 0 and package_known(self.player,"isWounded") and package_known(self,"getSuitNum","black", false, self.player) > 0 then
		local card_str = ("#ntdthree:%d:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#ntdthree"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["ntdthree"] = 5
sgs.ai_use_priority["ntdthree"] = 9.2

ai_skill_use["@@ntdthree"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "handcard")
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if (package_known(friend,"containsTrick","indulgence") or package_known(friend,"containsTrick","supply_shortage")) and (not package_known(friend,"isProhibited",friend, clone_native(self,"dismantlement", sgs.Card_NoSuit, 0))) then
			if #targets >= 1 + correct_target(self,"ExtraTarget",clone_native(self,"dismantlement", sgs.Card_NoSuit, 0)) then break end
			table.insert(targets, package_known(friend,"objectName"))
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if (not package_known(enemy,"isAllNude")) and (not package_known(enemy,"isProhibited",enemy, clone_native(self,"dismantlement", sgs.Card_NoSuit, 0))) then
			if #targets >= 1 + correct_target(self,"ExtraTarget",clone_native(self,"dismantlement", sgs.Card_NoSuit, 0)) then break end
			table.insert(targets, package_known(enemy,"objectName"))
		end
	end
	if #targets > 0 then
		return ("%s:ntdthree[no_suit:0]=.->%s"):format("dismantlement", table.concat(targets,"+"))
	else
		return "."
	end
	return "."
end

sgs.NTD3_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.NTD3(to, card)
	return package_known(card,"isBlack")
end

sgs.ai_ajustdamage_to["@xuanguang"]   = function(self, from, to, card, nature)
	if nature ~= "N" and package_known(to,"getEquips"):isEmpty() then
		return -99
	end
end



sgs.ai_skill_invoke.gaoda_zuzhou = function(self, data)
	local use = package_known(data,"toCardUse")
	if package_known(self,"getSuitNum","black", false, self.player) > 0 and package_known(self,"isEnemy",use.from) then
		package_call(self,"sort",self.enemies, "defenseSlash")
		for _,enemy in ipairs(self.enemies) do
			if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",clone_native(self,"slash", sgs.Card_NoSuitBlack, 0), enemy) then
				return true
			end
		end
	end
	return false
end

ai_skill_use["@@gaoda_zuzhou"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "defenseSlash")
	local targets = {}
	local slash = clone_native(self,"slash", sgs.Card_NoSuitBlack, 0)
	package_call(slash,"setSkillName","gaoda_zuzhou")
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",slash, enemy) then
			if #targets >= 1 + correct_target(self,"ExtraTarget",slash) then break end
			table.insert(targets, package_known(enemy,"objectName"))
		end
	end
	if #targets > 0 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByUseValue",cards, true)
		for _,card in ipairs(cards) do
			if package_known(card,"isBlack") and not (package_known(self.player,"getHp") == 1 and package_known(card,"isKindOf","Analeptic")) then
				return ("slash:gaoda_zuzhou[%s:%s]=%d->%s"):format(package_known(card,"getSuitString"), package_known(card,"getNumberString"), package_known(card,"getEffectiveId"), table.concat(targets, "+"))
			end
		end
	else
		return "."
	end
	return "."
end


local shenniao_skill = {}
shenniao_skill.name = "shenniao"
table.insert(package_skills, shenniao_skill)
shenniao_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","#shenniao") or package_known(self.player,"isKongcheng") then return false end
	if #self.enemies > 0 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)
		package_call(self,"sort",self.enemies, "hp")
		local f = function(a, b)
			return package_known(a,"getEquips"):length() > package_known(b,"getEquips"):length()
		end
		table.sort(self.enemies, f)
		local ids = {}
		local guard_num = package_known(self,"getCardsNum","Guard") + package_known(self,"getCardsNum","CounterGuard")
		local chosen_guard = false
		local targets = {}

		local hasOffensiveWeapon = function(player)
			local offensive_weapons = {"axe", "crossbow", "qinggang_sword", "sp_moonspear"}
			for _, weapon in ipairs(offensive_weapons) do
				if package_known(player,"hasWeapon",weapon) then
					return true
				end
			end
		end

		local hasDefensiveArmor = function(player)
			local defensive_armors = {"eight_diagram", "renwang_shield", "vine"}
			for _, armor in ipairs(defensive_armors) do
				if package_known(player,"hasArmorEffect",armor) then
					return true
				end
			end
		end

		for _, enemy in ipairs(self.enemies) do
			if guard_num > 0 or package_known(enemy,"getStrategyMark","Equips_Nullified_to_Yourself") == 0
				and (hasOffensiveWeapon(enemy) or hasDefensiveArmor(enemy)
				or (package_known(enemy,"getDefensiveHorse") and package_known(self.player,"inMyAttackRange",enemy, -1))) then
				table.insert(targets, package_known(enemy,"objectName"))
				if #targets == 2 then break end
			end
		end

		local g = function(a, b)
			return package_known(a,"getClassName"):endsWith("Guard") and not package_known(b,"getClassName"):endsWith("Guard")
		end
		table.sort(cards, g)

		for i, card in ipairs(cards) do
			if package_known(card,"isKindOf","BasicCard") and not isCard("Peach", card, self.player) then
				if chosen_guard and package_known(card,"getClassName"):endsWith("Guard") then
					local second_break = false
					for j = i + 1, #cards do
						if package_known(cards[j],"isKindOf","BasicCard") and not isCard("Peach", cards[j], self.player) then
							table.insert(ids, package_known(cards[j],"getId"))
							if #ids == math.min(#targets, 2) then second_break = true break end
						end
					end
					if second_break then break end
				end
				if package_known(card,"getClassName"):endsWith("Guard") then
					chosen_guard = true
				end
				table.insert(ids, package_known(card,"getId"))
				if #ids == math.min(#targets, 2) then break end
			end
		end

		local confirm_targets = {}
		for i = 1, #ids do
			table.insert(confirm_targets, targets[i])
		end

		if #confirm_targets > 0 then
			local card_str = ("#shenniao:%s:->%s"):format(table.concat(ids, "+"), table.concat(confirm_targets, "+"))
			local card = source_construct(self,card_str)
			return card
		end
	end
end

sgs.ai_skill_use_func["#shenniao"] = function(card,use,self,request)
	use.card = card
	if use.to then
			if #self.enemies > 0 then
				local cards = package_known(self.player,"getCards","h")
				cards = sgs.QList2Table(cards)
				package_call(self,"sortByKeepValue",cards)
				package_call(self,"sort",self.enemies, "hp")
				local f = function(a, b)
					return package_known(a,"getEquips"):length() > package_known(b,"getEquips"):length()
				end
				table.sort(self.enemies, f)
				local ids = {}
				local guard_num = package_known(self,"getCardsNum","Guard") + package_known(self,"getCardsNum","CounterGuard")
				local chosen_guard = false
				local targets = {}

				local hasOffensiveWeapon = function(player)
					local offensive_weapons = {"axe", "crossbow", "qinggang_sword", "sp_moonspear"}
					for _, weapon in ipairs(offensive_weapons) do
						if package_known(player,"hasWeapon",weapon) then
							return true
						end
					end
				end

				local hasDefensiveArmor = function(player)
					local defensive_armors = {"eight_diagram", "renwang_shield", "vine"}
					for _, armor in ipairs(defensive_armors) do
						if package_known(player,"hasArmorEffect",armor) then
							return true
						end
					end
				end

				for _, enemy in ipairs(self.enemies) do
					if guard_num > 0 or package_known(enemy,"getStrategyMark","Equips_Nullified_to_Yourself") == 0
						and (hasOffensiveWeapon(enemy) or hasDefensiveArmor(enemy)
						or (package_known(enemy,"getDefensiveHorse") and package_known(self.player,"inMyAttackRange",enemy, -1))) then
						table.insert(targets, enemy)
						if #targets == 2 then break end
					end
				end

				local g = function(a, b)
					return package_known(a,"getClassName"):endsWith("Guard") and not package_known(b,"getClassName"):endsWith("Guard")
				end
				table.sort(cards, g)

				for i, card in ipairs(cards) do
					if package_known(card,"isKindOf","BasicCard") and not isCard("Peach", card, self.player) then
						if chosen_guard and package_known(card,"getClassName"):endsWith("Guard") then
							local second_break = false
							for j = i + 1, #cards do
								if package_known(cards[j],"isKindOf","BasicCard") and not isCard("Peach", cards[j], self.player) then
									table.insert(ids, package_known(cards[j],"getId"))
									if #ids == math.min(#targets, 2) then second_break = true break end
								end
							end
							if second_break then break end
						end
						if package_known(card,"getClassName"):endsWith("Guard") then
							chosen_guard = true
						end
						table.insert(ids, package_known(card,"getId"))
						if #ids == math.min(#targets, 2) then break end
					end
				end

				local confirm_targets = {}
				for i = 1, #ids do
					package_call(use.to,"append",targets[i])
				end

			end
	end
end

sgs.ai_use_value["shenniao"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["shenniao"] = sgs.ai_use_priority.Slash + 0.05

function sgs.ai_cardneed.shenniao(to, card)
	return package_known(card,"getClassName"):endsWith("Guard")
end

ai_skill_use["@@ntdfour"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "defenseSlash")
	local targets = {}
	local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
	package_call(slash,"setSkillName","ntdfourcard")
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",slash, enemy) then
			if #targets >= 1 + correct_target(self,"ExtraTarget",slash) then break end
			table.insert(targets, package_known(enemy,"objectName"))
		end
	end
	if #targets > 0 then
		return ("slash:ntdfourcard[no_suit:0]=.->%s"):format(table.concat(targets, "+"))
	end
	return "."
end

sgs.ai_skill_invoke.qiji = function(self, data)
	return true
end

local qiji_skill={}
qiji_skill.name="qiji"
table.insert(package_skills,qiji_skill)
qiji_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getChangeSkillState","qiji") ~= 2 then return false end

	if package_known(self.player,"getHandcardNum") == 1 then
		local card = package_known(self.player,"getHandcards"):first()
		if (not isCard("ExNihilo", card, self.player)) and (not package_known(self.player,"isWounded") or not isCard("Peach", card, self.player)) then
			local suit = package_known(card,"getSuitString")
			local number = package_known(card,"getNumberString")
			local card_id = package_known(card,"getEffectiveId")
			local card_str = ("slash:qiji[%s:%s]=%d"):format(suit, number, card_id)
			local slash = source_construct(self,card_str)
			assert(slash)
			return slash
		end
	end
end

sgs.ai_view_as.qiji = function(card, player, card_place)
 local self=actor_ai(player)
	local cd = package_known(player,"getHandcards"):first()
	if package_known(player,"getHandcardNum") == 1 and package_known(player,"getChangeSkillState","qiji") == 2 then

		local suit = package_known(cd,"getSuitString")
		local number = package_known(cd,"getNumberString")
		local card_id = package_known(cd,"getEffectiveId")
		local pattern -- source unused ambient read omitted; next statement overwrites it
		if pattern == "slash" or pattern == "jink" then
			return ("%s:qiji[%s:%s]=%d"):format(pattern, suit, number, card_id)
		end
	end
end

sgs.ai_use_value["qiji"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["qiji"] = sgs.ai_use_priority.Slash + 1

sgs.ai_skill_playerchosen.qiji = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "hp")
	for _, target in ipairs(targets) do
		if package_known(self,"isFriend",target) then
			return target
		end
	end
	return nil
end


local fanshe_skill = {}
fanshe_skill.name = "fanshe"
table.insert(package_skills,fanshe_skill)
fanshe_skill.getTurnUseCard = function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#fanshe") and #self.friends_noself > 0 then
		for _,f in ipairs(self.friends) do
			for _,e in ipairs(self.enemies) do
				if package_known(f,"inMyAttackRange",e) or package_known(f,"distanceTo",e) == 1 then
					local card_str = ("#fanshe:%d:")
					return source_construct(self,card_str)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#fanshe"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_skill_playerchosen.fanshe = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if package_known(self,"isFriend",target) then
			for _,e in ipairs(self.enemies) do
				if package_known(target,"inMyAttackRange",e) or package_known(target,"distanceTo",e) == 1 then
					return target
				end
			end
		end
	end
	return targets[1]
end

ai_skill_use["@@fanshe"]=function(self,prompt,request)
	return ("#fanshe:.:")
end

sgs.ai_use_value["fanshe"] = 5
sgs.ai_use_priority["fanshe"] = 5

sgs.ai_skill_invoke.ALICE = function(self, data)
	return true
end


local luashipo_skill = {}
luashipo_skill.name = "luashipo"
table.insert(package_skills,luashipo_skill)
luashipo_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getPile","lizhan"):length() < 3 and (not package_known(self.player,"isKongcheng")) then
		local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		package_call(self,"sortByUseValue",cards,true)
		for _,card in ipairs(cards) do
			if package_known(card,"isKindOf","TrickCard") and (not package_known(card,"isKindOf","Nullification")) and (not package_known(card,"isKindOf","Snatch")) and
				(not package_known(card,"isKindOf","Dismantlement")) and (not package_known(card,"isKindOf","ExNihilo")) and (not package_known(card,"isKindOf","Indulgence")) then
				local card_str = ("#luashipo:"..package_known(card,"getId")..":")
				return source_construct(self,card_str)
			end
		end
	end
end

sgs.ai_skill_use_func["#luashipo"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["luashipo"] = 4
sgs.ai_use_priority["luashipo"] = 9.2

sgs.ai_view_as.luashipo = function(card, player, card_place)
 local self=actor_ai(player)
	if package_known(player,"getPile","lizhan"):isEmpty() then return false end
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceSpecial and package_known(player,"getPileName",card_id) == "lizhan" then
		return ("nullification:luashipo[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local leishe_skill = {}
leishe_skill.name= "leishe"
table.insert(package_skills,leishe_skill)
leishe_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@leishe") >= 3 and (not package_known(self.player,"hasUsed","#leishe")) then
		return source_construct(self,"#leishe:.:")
	end
end

sgs.ai_skill_use_func["#leishe"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"objectiveLevel",enemy) > 3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy) then
			use.card = source_construct(self,"#leishe:.:")
			if use.to then
				package_call(use.to,"append",enemy)
			end
			return
		end
	end
end

sgs.ai_use_value["leishe"] = 2.5
sgs.ai_use_priority["leishe"] = sgs.ai_use_value.Slash - 0.1
sgs.dynamic_value.damage_card["leishe"] = true



sgs.need_kongcheng = sgs.need_kongcheng .. "|fangcheng"

sgs.ai_view_as.canying = function(card, player, card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	local pattern -- source unused ambient read omitted; next statement overwrites it
	if pattern == "jink" and package_known(player,"getStrategyMark","@canying") > 0 and card_place == sgs.Player_PlaceHand and package_known(card,"isRed") and not package_known(card,"isKindOf","Peach") then
		for _,c in sgs.qlist(package_known(player,"getHandcards")) do
			if package_known(c,"isKindOf","Jink") then
				return "."
			end
		end
		return ("jink:canyingcard[%s:%s]=%d"):format(suit, number, card_id)
	end
end

ai_skill_use["@@canying"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "defenseSlash")
	local targets = {}
	local slash = clone_native(self,"slash", sgs.Card_NoSuitBlack, 0)
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",slash, enemy) then
			if #targets >= 1 + correct_target(self,"ExtraTarget",slash) then break end
			table.insert(targets, package_known(enemy,"objectName"))
		end
	end
	if #targets > 0 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByUseValue",cards, true)
		for _,card in ipairs(cards) do
			if package_known(card,"isBlack") and not (package_known(self.player,"getHp") == 1 and package_known(card,"isKindOf","Analeptic")) then
				return ("slash:canyingcard[%s:%s]=%d->%s"):format(package_known(card,"getSuitString"), package_known(card,"getNumberString"), package_known(card,"getEffectiveId"), table.concat(targets, "+"))
			end
		end
	else
		return "."
	end
	return "."
end


sgs.ai_use_revises.haidao = function(self,card,use)
	if package_known(card,"isKindOf","EquipCard") and package_known(self,"evaluateArmor",card)>-5
	then use.card = card return true end
end
sgs.ai_cardneed.haidao = sgs.ai_cardneed.equip


ai_skill_use["@@haidao"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	if #self.enemies == 0 then return "." end
	local name = source_property(self,"haidao"):toString()
	if name == "slash" then
		local acard = clone_native(self,name, sgs.Card_NoSuit, 0)
		package_call(acard,"setSkillName","haidaocard")

		package_call(self,"sort",self.enemies, "defense")
		local targets = {}
		for _,enemy in ipairs(self.enemies) do
			if (not package_known(self,"slashProhibit",acard, enemy)) and package_known(self.player,"canSlash",enemy, acard) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",acard) then break end
				table.insert(targets, package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return ("%s:haidaocard[no_suit:0]=.->%s"):format(name, table.concat(targets, "+"))
		else
			return "."
		end
	elseif name == "armor" then
		package_call(self,"sort",self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if package_known(self.player,"distanceTo",enemy) == 1 then
				return ("#haidaocard:.:->%s"):format(package_known(enemy,"objectName"))
			end
		end
	elseif name == "iron_chain" then
		local acard = clone_native(self,name, sgs.Card_NoSuit, 0)
		package_call(acard,"setSkillName","haidaocard")

		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isKongcheng")) and (not package_known(enemy,"isProhibited",enemy, acard))  then
				if #targets >= 2 + correct_target(self,"ExtraTarget",acard) then break end
				table.insert(targets, package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then

			return ("%s:haidaocard[no_suit:0]=.->%s"):format(name, table.concat(targets, "+"))
		else

			local use = dummy(false)
			package_call(self,"useTrickCard",acard, use)
			if use.card and use.to and not package_known(use.to,"isEmpty") then
				local targets = {}
				for _, p in sgs.qlist(use.to) do
					table.insert(targets, package_known(p,"objectName"))
				end
				return ("%s:haidaocard[no_suit:0]=.->%s"):format(name, table.concat(targets, "+"))
			else
				return "."
			end
		end
	elseif name == "shoot" then
		local acard = clone_native(self,name, sgs.Card_NoSuit, 0)
		package_call(acard,"setSkillName","haidaocard")

		package_call(self,"sort",self.enemies, "defense")
		local targets = {}
		for _,enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isProhibited",enemy, acard)) then
				if #targets >= 1 + correct_target(self,"ExtraTarget",acard) then break end
				table.insert(targets, package_known(enemy,"objectName"))
			end
		end
		if #targets > 0 then
			return ("%s:haidaocard[no_suit:0]=.->%s"):format(name, table.concat(targets, "+"))
		else
			return "."
		end
	end
	return "."
end


sgs.ai_skill_cardask["@@kulu"] = function(self, data)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)

	local damage = package_known(data,"toDamage")
	for _,card in ipairs(cards) do
		if package_known(card,"isKindOf","Slash") and package_known(card,"isRed") then
			return package_known(card,"getEffectiveId")
		end
	end

	if damage.from and not package_known(self,"isFriend",damage.from) then
		for _,card in ipairs(cards) do
			if package_known(card,"isKindOf","Slash") and package_known(card,"isBlack") then
				return package_known(card,"getEffectiveId")
			end
		end
	end

	return "."
end


sgs.ai_skill_cardask["@@shanguang"] = function(self, data)
	local source = package_call(data,"toPlayer")
	local player = self.player

	if package_known(self,"needToThrowArmor") then
		return package_call(player,"getArmor"):getEffectiveId()
	end

	if not package_known(self,"damageIsEffective",player, sgs.DamageStruct_Normal, source) then
		return "."
	end
	if package_known(self,"needToLoseHp",player, source) then
		return "."
	end

	local card_id
	if package_known(self,"hasSkills",sgs.lose_equip_skill, player) then
		if package_call(player,"getWeapon") then card_id = package_call(player,"getWeapon"):getId()
		elseif package_known(player,"getOffensiveHorse") then card_id = package_known(player,"getOffensiveHorse"):getId()
		elseif package_call(player,"getArmor") then card_id = package_call(player,"getArmor"):getId()
		elseif package_known(player,"getDefensiveHorse") then card_id = package_known(player,"getDefensiveHorse"):getId()
		end
	end

	if not card_id then
		for _, card in sgs.qlist(package_known(player,"getCards","h")) do
			if package_known(card,"isKindOf","EquipCard") then
				card_id = package_known(card,"getEffectiveId")
				break
			end
		end
	end

	if not card_id then
		if package_call(player,"getWeapon") then card_id = package_call(player,"getWeapon"):getId()
		elseif package_known(player,"getOffensiveHorse") then card_id = package_known(player,"getOffensiveHorse"):getId()
		elseif package_known(self,"isWeak",player) and package_call(player,"getArmor") then card_id = package_call(player,"getArmor"):getId()
		elseif package_known(self,"isWeak",player) and package_known(player,"getDefensiveHorse") then card_id = package_known(player,"getDefensiveHorse"):getId()
		end
	end

	if not card_id then return "." else return card_id end
end

local shanguang_skill = {}
shanguang_skill.name = "shanguang"
table.insert(package_skills, shanguang_skill)
shanguang_skill.getTurnUseCard = function(self,inclusive,request)
	if (package_known(self.player,"usedTimes","#shanguang") <= package_known(self.player,"getStrategyMark","@supermode")) and ((package_known(self.player,"getHp") >= 3 and package_known(self,"getCardsNum","Jink") > 0)
		or (package_known(self.player,"getHp") <= 2 and package_known(self,"getCardsNum","Jink") > 1) or (package_known(self.player,"getStrategyMark","@supermode") > 0 and package_known(self,"getCardsNum","Weapon") > 0)) then
		for _, enemy in ipairs(self.enemies) do
			if package_known(self.player,"inMyAttackRange",enemy) then
				return source_construct(self,"#shanguang:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#shanguang"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"inMyAttackRange",enemy) then
			local ids = {}
			for _,card in sgs.qlist(package_known(self.player,"getCards","he")) do
				local id = package_known(card,"getId")
				if package_known(card,"isKindOf","Jink") then
					table.insert(ids, id)
				elseif package_known(self.player,"getStrategyMark","@supermode") > 0 and package_known(card,"isKindOf","Weapon") then
					local rangefix = 0
					if package_call(self.player,"getWeapon") and package_call(self.player,"getWeapon"):getId() == id then
						local weapon = package_call(self.player,"getWeapon"):getRealCard():toWeapon()
						rangefix = rangefix + package_known(weapon,"getRange") - package_known(self.player,"getAttackRange",false)
					end
					if package_known(self.player,"inMyAttackRange",enemy, rangefix) then
						table.insert(ids, id)
					end
				end
			end
			if #ids == 0 then return end
			use.card = source_construct(self,"#shanguang:"..ids[math.random(#ids)]..":")
			if use.to then package_call(use.to,"append",enemy) end
			return
		end
	end
end

sgs.ai_use_value["shanguang"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["shanguang"] = sgs.ai_use_priority.Slash + 1

sgs.ai_skill_invoke.jingxin = function(self, data)
	if (package_known(self.player,"getHp") == 1 or (package_known(self,"getCardsNum","Jink") + package_known(self,"getCardsNum","Weapon")) > 1) and
		#self.enemies == 1 and (package_known(self.enemies[1],"getHp") == 1 or (package_known(self.enemies[1],"getHp") > 1 and package_known(self.enemies[1],"getCardCount") <= 1)) then
		return false
	end
	return true
end
sgs.ai_can_damagehp.chaojimoshi = function(self,from,card,to)
	return package_known(to,"getHp")+package_known(self,"getAllPeachNum")-package_known(self,"ajustDamage",from,to,1,card)>0
	and package_known(self,"canLoseHp",from,card,to) and package_known(to,"getStrategyMark","@supermode") == 0 and package_known(to,"getStrategyMark","supermode_damage") < 3
end

sgs.ai_skill_invoke.chaojimoshi = function(self, data)
	local can_attack = false
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"inMyAttackRange",enemy) then
			can_attack = true
			break
		end
	end
	if can_attack and package_known(self,"getCardsNum","Jink") > package_known(self.player,"getMaxCards") then return false end
	return true
end

function sgs.ai_cardneed.shanguang(to, card)
	return package_known(card,"isKindOf","Jink")
end


sgs.ai_skill_cardask["@@shenzhang"] = function(self, data)
	local shanguang = sgs.ai_skill_cardask["@@shanguang"]
	return shanguang(self, data)
end

local shenzhang_skill = {}
shenzhang_skill.name = "shenzhang"
table.insert(package_skills, shenzhang_skill)
shenzhang_skill.getTurnUseCard = function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#shenzhang") then
		for _, enemy in ipairs(self.enemies) do
			if package_known(self.player,"inMyAttackRange",enemy) then
				local cards = package_known(self.player,"getCards","he")
				cards = sgs.QList2Table(cards)
				package_call(self,"sortByUseValue",cards, true)
				for _,card in ipairs(cards) do
					if package_known(card,"getSuit") == sgs.Card_Heart and not (isCard("Peach", card, self.player) and package_known(self,"getCardsNum","Peach") == 1) and not isCard("ExNihilo", card, self.player) then
						return source_construct(self,"#shenzhang:.:")
					end
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#shenzhang"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"inMyAttackRange",enemy) then
			local cards = package_known(self.player,"getCards","he")
			cards = sgs.QList2Table(cards)
			package_call(self,"sortByUseValue",cards, true)
			for _,card in ipairs(cards) do
				if package_known(card,"getSuit") == sgs.Card_Heart and not (isCard("Peach", card, self.player) and package_known(self,"getCardsNum","Peach") == 1) and not isCard("ExNihilo", card, self.player) then
					use.card = source_construct(self,"#shenzhang:"..package_known(card,"getId")..":")
					if use.to then package_call(use.to,"append",enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_value["shenzhang"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["shenzhang"] = sgs.ai_use_priority.Slash + 1

sgs.ai_skill_invoke.aoyi = function(self, data)
	return true
end

ai_skill_use["@@aoyi"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "defenseSlash")
	local targets = {}
	local slash = clone_native(self,"slash", sgs.Card_NoSuitRed, 0)
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",slash, enemy) then
			if #targets >= 1 + correct_target(self,"ExtraTarget",slash) then break end
			table.insert(targets, package_known(enemy,"objectName"))
		end
	end
	if #targets > 0 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByUseValue",cards, true)
		for _,card in ipairs(cards) do
			if package_known(card,"isRed") and not (package_known(self.player,"getHp") == 1 and (package_known(card,"isKindOf","Analeptic") or package_known(card,"isKindOf","Peach"))) then
				return ("slash:aoyi[%s:%s]=%d->%s"):format(package_known(card,"getSuitString"), package_known(card,"getNumberString"), package_known(card,"getEffectiveId"), table.concat(targets, "+"))
			end
		end
	else
		return "."
	end
	return "."
end

local aoyi_skill = {}
aoyi_skill.name = "aoyi"
table.insert(package_skills, aoyi_skill)
aoyi_skill.getTurnUseCard = function(self,inclusive,request)
	if (not package_known(self.player,"hasUsed","#aoyi")) then
		if package_known(self.player,"getStrategyMark","@aoyi") == 2 then
			for _, enemy in ipairs(self.enemies) do
				if not package_known(enemy,"getEquips"):isEmpty() then
					return source_construct(self,"#aoyi:.:")
				end
			end
		elseif package_known(self.player,"getStrategyMark","@aoyi") == 3 then
			if package_known(self.player,"getHandcardNum") >= 2 and #self.enemies > 0 then
				return source_construct(self,"#aoyi:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#aoyi"] = function(card,use,self,request)
	if package_known(self.player,"getStrategyMark","@aoyi") == 2 then
		package_call(self,"sort",self.enemies, "hp")
		local max, target = 0, nil
		for _, enemy in ipairs(self.enemies) do
			local n = package_known(enemy,"getEquips"):length()
			if n > max then
				max = n
				target = enemy
			end
		end
		if target ~= nil then
			use.card = source_construct(self,"#aoyi:.:")
			if use.to then package_call(use.to,"append",target) end
		end
	elseif package_known(self.player,"getStrategyMark","@aoyi") == 3 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)
		package_call(self,"sort",self.enemies, "hp")
		use.card = source_construct(self,"#aoyi:"..package_known(cards[1],"getId").."+"..package_known(cards[2],"getId")..":")
		if use.to then package_call(use.to,"append",self.enemies[1]) end
	end
end

sgs.ai_use_value["aoyi"] = sgs.ai_use_value.Slash + 1.1
sgs.ai_use_priority["aoyi"] = sgs.ai_use_priority.Slash + 1.1

sgs.shenzhang_suit_value = {
	heart = 3.9
}

function sgs.ai_cardneed.shenzhang(to, card)
	return package_known(card,"getSuit") == sgs.Card_Heart
end


sgs.ai_skill_cardask["@anzhang"] = function(self)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)

	for _,card in ipairs(cards) do
		if package_known(card,"getSuit") == sgs.Card_Spade then
			return package_known(card,"getEffectiveId")
		end
	end

	return "."
end
sgs.ai_can_damagehp.anzhang = function(self,from,card,to)
	if from and package_known(to,"getHp")+package_known(self,"getAllPeachNum")-package_known(self,"ajustDamage",from,to,1,card)>0
	and package_known(self,"canLoseHp",from,card,to)
	then
		return package_known(self,"isEnemy",from) and sgs.ai_skill_cardask["@anzhang"](self) ~= "."
	end
end



sgs.ai_skill_cardask["@@anzhang"] = function(self, data)
	local shanguang = sgs.ai_skill_cardask["@@shanguang"]
	return shanguang(self, data)
end

sgs.anzhang_suit_value = {
	spade = 3.9
}

function sgs.ai_cardneed.anzhang(to, card)
	return package_known(card,"getSuit") == sgs.Card_Spade
end












perfectSum=function(numbers, sum, k)
	local subsets = {}


	local dp

	local function display(v)
		local ans = ""
		for i = 1, #v do
			ans = ans .. v[i]
			if i < #v then
				ans = ans .. "+"
			end
		end

		table.insert(subsets, ans)
	end



	local function printSubsetsRec(arr, i, sum, p)



		if (i == 0 and sum ~= 0 and dp[0][sum]) then
			table.insert(p, arr[i])
			display(p)
			return
		end


		if (i == 0 and sum == 0) then
			display(p)
			return
		end


		if (k ~= -1 and #subsets == k) then
			return
		end



		if (dp[i-1][sum]) then

			local b = {}
			for k, v in ipairs(p) do
				b[k] = v
			end
			printSubsetsRec(arr, i-1, sum, b)
		end



		if (sum >= arr[i] and dp[i-1][sum-arr[i]]) then
			table.insert(p, arr[i])
			printSubsetsRec(arr, i-1, sum-arr[i], p)
		end
	end


	local function printAllSubsets(arr, n, sum)
		if (n == 0 or sum < 0) then
		   return
		end


		dp = {}
		for i = 0, n - 1 do
			dp[i] = {}
			dp[i][0] = true
		end


		if (arr[0] <= sum) then
		   dp[0][arr[0]] = true
		end


		for i = 1, n - 1 do
			for j = 0, sum do
				if (arr[i] <= j) then
					dp[i][j] = dp[i-1][j] or dp[i-1][j-arr[i]]
				else
					dp[i][j] = dp[i - 1][j]
				end
			end
		end
		if (dp[n-1][sum] == false) then

			return
		end



		local p = {}
		printSubsetsRec(arr, n-1, sum, p)
	end

	local n = #numbers
	local arr = {}
	for i = 0, n - 1 do
	   arr[i] = numbers[i + 1]
	end
	printAllSubsets(arr, n, sum)

	return subsets
end

local m_aoyi_skill = {}
m_aoyi_skill.name = "m_aoyi"
table.insert(package_skills, m_aoyi_skill)
m_aoyi_skill.getTurnUseCard = function(self,inclusive,request)
	if (not package_known(self.player,"hasUsed","#m_aoyi")) then
		if package_known(self.player,"getStrategyMark","@m_aoyi") == 0 then
			if package_known(self.player,"isKongcheng") then return false end
			for _, enemy in ipairs(self.enemies) do
				if not package_known(enemy,"isNude") then
					return source_construct(self,"#m_aoyi:.:")
				end
			end
		elseif package_known(self.player,"getStrategyMark","@m_aoyi") == 1 then
			if #self.enemies > 0 then
				local cards = package_known(self.player,"getCards","he")
				cards = sgs.QList2Table(cards)
				package_call(self,"sortByKeepValue",cards)

				local numbers = {}
				for i, card in ipairs(cards) do

					if i > 10 then break end
					table.insert(numbers, package_known(card,"getNumber"))
				end

				table.sort(numbers, function(a, b) return a > b end)

				local subsets = perfectSum(numbers, 12, 1)

				if #subsets > 0 then

					local chosen_numbers = package_known(subsets[1],"split","+")
					local ids = {}
					for _, card in ipairs(cards) do
						if #chosen_numbers == 0 then break end
						if table.removeOne(chosen_numbers, tostring(package_known(card,"getNumber"))) then
							table.insert(ids, package_known(card,"getId"))
						end
					end

					return source_construct(self,"#m_aoyi:"..table.concat(ids, "+")..":")
				end
			end
		elseif package_known(self.player,"getStrategyMark","@m_aoyi") == 2 then
			for _, enemy in ipairs(self.enemies) do
				if not package_known(enemy,"getEquips"):isEmpty() then
					return source_construct(self,"#m_aoyi:.:")
				end
			end
		elseif package_known(self.player,"getStrategyMark","@m_aoyi") == 3 then
			if package_known(self.player,"getHandcardNum") >= 2 and #self.enemies > 0 then
				return source_construct(self,"#m_aoyi:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#m_aoyi"] = function(card,use,self,request)
	if package_known(self.player,"getStrategyMark","@m_aoyi") == 0 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)

		local f = function(a, b)
			local a_score, b_score = 0, 0
			for _, card in sgs.qlist(package_known(a,"getCards","e")) do
				if package_known(self,"getSuitNum",package_known(card,"getSuitString"), false, self.player) > 0 then
					a_score = a_score + 1
					break
				end
			end
			for _, card in sgs.qlist(package_known(b,"getCards","e")) do
				if package_known(self,"getSuitNum",package_known(card,"getSuitString"), false, self.player) > 0 then
					a_score = a_score + 1
					break
				end
			end
			if (a_score > 0) ~= (b_score > 0) then
				return a_score > b_score
			else
				return package_known(a,"getCardCount") < package_known(b,"getCardCount")
			end
		end

		table.sort(self.enemies, f)

		for _, enemy in ipairs(self.enemies) do
			if not package_known(enemy,"isNude") then
				local rank = function(card)
					if package_known(card,"isKindOf","Armor") then
						return 4
					elseif package_known(card,"isKindOf","DefensiveHorse") then
						return 3
					elseif package_known(card,"isKindOf","OffensiveHorse") then
						return 1
					end
					return 2
				end

				local g = function(a, b)
					return rank(a) > rank(b)
				end

				local equips = package_known(enemy,"getEquips")
				equips = sgs.QList2Table(equips)
				table.sort(equips, g)

				for _, equip in ipairs(equips) do
					for _, card in ipairs(cards) do
						if package_known(card,"getSuit") == package_known(equip,"getSuit") then
							source_state(self).m_aoyi_1= package_known(equip,"toString")
							use.card = source_construct(self,"#m_aoyi:"..package_known(card,"getId")..":")
							if use.to then package_call(use.to,"append",enemy) end
							return
						end
					end
				end
				use.card = source_construct(self,"#m_aoyi:"..package_known(cards[1],"getId")..":")
				if use.to then package_call(use.to,"append",enemy) end
				return
			end
		end
	elseif package_known(self.player,"getStrategyMark","@m_aoyi") == 1 then
		package_call(self,"sort",self.enemies, "hp")
		use.card = card
		if use.to then package_call(use.to,"append",self.enemies[1]) end
	elseif package_known(self.player,"getStrategyMark","@m_aoyi") == 2 then
		package_call(self,"sort",self.enemies, "hp")
		local max, target = 0, nil
		for _, enemy in ipairs(self.enemies) do
			local n = package_known(enemy,"getEquips"):length()
			if n > max then
				max = n
				target = enemy
			end
		end
		if target ~= nil then
			use.card = source_construct(self,"#m_aoyi:.:")
			if use.to then package_call(use.to,"append",target) end
		end
	elseif package_known(self.player,"getStrategyMark","@m_aoyi") == 3 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)
		package_call(self,"sort",self.enemies, "hp")
		use.card = source_construct(self,"#m_aoyi:"..package_known(cards[1],"getId").."+"..package_known(cards[2],"getId")..":")
		if use.to then package_call(use.to,"append",self.enemies[1]) end
	end
end

sgs.ai_skill_cardchosen["m_aoyi"] = function(self, who, flags)
	local card_str = (source_state(self).m_aoyi_1 or "")
	if card_str ~= "" then
		source_state(self).m_aoyi_1=nil
		return source_construct(self,card_str)
	end
	return nil
end

sgs.ai_use_value["m_aoyi"] = sgs.ai_use_value.Slash + 3
sgs.ai_use_priority["m_aoyi"] = sgs.ai_use_priority.Slash + 3


local wzpoint_skill = {}
wzpoint_skill.name = "wzpoint"
table.insert(package_skills,wzpoint_skill)
wzpoint_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@point") > 3 and (package_known(self.player,"getHandcardNum") <= 2 or package_known(self.player,"getHp") == 1) then
		local card_str = ("#wzpoint:%d:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#wzpoint"] = function(card,use,self,request)
	use.card = card
end

sgs.dynamic_value.benefit["wzpoint"] = true

sgs.ai_use_value["wzpoint"] = sgs.ai_use_value.Slash + 0.1
sgs.ai_use_priority["wzpoint"] = sgs.ai_use_priority.Slash + 0.1

local liuxing_skill = {}
liuxing_skill.name = "liuxing"
table.insert(package_skills, liuxing_skill)
liuxing_skill.getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	local newcards = {}
	for _, card in ipairs(cards) do
		if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then table.insert(newcards, card) end
	end
	if #newcards < 2 then return end

	local card_id1 = package_known(newcards[1],"getEffectiveId")
	local card_id2 = package_known(newcards[2],"getEffectiveId")

	if package_known(newcards[1],"isBlack") and package_known(newcards[2],"isBlack") then
		local black_slash = clone_native(self,"slash", sgs.Card_NoSuitBlack)
		local nosuit_slash = clone_native(self,"slash")

		package_call(self,"sort",self.enemies, "defenseSlash")
		for _, enemy in ipairs(self.enemies) do
			if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",nosuit_slash, enemy) and package_known(self,"slashIsEffective",nosuit_slash, enemy)
				and package_known(self,"canAttack",enemy) and package_known(self,"slashProhibit",black_slash, enemy) and package_known(self,"isWeak",enemy) then
				local redcards, blackcards = {}, {}
				for _, acard in ipairs(newcards) do
					if package_known(acard,"isBlack") then table.insert(blackcards, acard) else table.insert(redcards, acard) end
				end
				if #redcards == 0 then break end

				local redcard, othercard

				package_call(self,"sortByUseValue",blackcards, true)
				package_call(self,"sortByUseValue",redcards, true)
				redcard = redcards[1]

				othercard = #blackcards > 0 and blackcards[1] or redcards[2]
				if redcard and othercard then
					card_id1 = package_known(redcard,"getEffectiveId")
					card_id2 = package_known(othercard,"getEffectiveId")
					break
				end
			end
		end
	end

	local card_str = ("slash:liuxing[%s:%s]=%d+%d"):format("to_be_decided", 0, card_id1, card_id2)
	local slash = source_construct(self,card_str)
	return slash
end

sgs.ai_view_as.liuxing = function(card, player, card_place)
 local self=actor_ai(player)
	local usereason = owner_reason(self)
	if usereason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
	if card_place == sgs.Player_PlaceHand and package_known(player,"getHandcardNum") >= 2 then
		local slash = clone_native(self,"slash", sgs.Card_SuitToBeDecided, -1)
		local id1
		local id2
		for i = 0, 1, 1 do
			local id = package_known(player,"handCards"):at(i)
			package_call(slash,"addSubcard",id)
			if id1 == nil then
				id1 = id
			else
				id2 = id
			end
		end
		local suit = package_known(slash,"getSuitString")
		local number = package_known(slash,"getNumberString")
		return ("slash:liuxing[%s:%s]=%d+%d"):format(suit, number, id1, id2)
	end
end

sgs.ai_use_value["liuxing"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["liuxing"] = sgs.ai_use_priority.Slash

sgs.ai_skill_invoke.lingshi = function(self, data)
	return true
end
sgs.ai_card_priority.liuxing = function(self,card)
	if table.contains(package_known(card,"getSkillNames"), "liuxing")
	then
		if self.useValue
		then return 1 end
		return -0.2
	end
end

sgs.ai_ajustdamage_from.liuxing = function(self, from, to, card, nature)
	if card and table.contains(package_known(card,"getSkillNames"), "liuxing") and package_known(card,"hasFlag","liuxing") then
		return 1
	end
end


sgs.ai_skill_invoke.mosu = function(self, data)
	return true
end

sgs.ai_skill_invoke.cishi = function(self, data)
	return true
end
sgs.ai_can_damagehp.mosu = function(self,from,card,to)
	if from and package_known(to,"getHp")+package_known(self,"getAllPeachNum")-package_known(self,"ajustDamage",from,to,1,card)>0
	and package_known(self,"canLoseHp",from,card,to)
	then
		return package_known(self,"isEnemy",from) and package_known(from,"getPhase") ~= sgs.Player_NotActive
	end
end



local shuangpao_skill={}
shuangpao_skill.name="shuangpao"
table.insert(package_skills,shuangpao_skill)
shuangpao_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"hasUsed","#shuangpao") or package_known(self.player,"getHp") < 2 then return false end

	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	local willUse = false
	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
			willUse = true
			break
		end
	end
	if not willUse then return false end
	if package_known(self.player,"isKongcheng") then
		if package_known(self.player,"getStrategyMark","@ew_lingshi") > 0 then
			local card_str = ("#shuangpao:%d:")
			return source_construct(self,card_str)
		end
	else
		for _,enemy in ipairs(self.enemies) do
			local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
			package_call(slash,"deleteLater")
			if (not package_known(self,"slashProhibit",slash, enemy, self.player)) and (package_known(self.player,"canSlash",enemy, slash) or (package_known(self.player,"hasSkill","feiyi")
			and package_known(self.player,"getHp") < 4)) and (not package_known(self,"isWeak",self.player)) and package_known(self,"getCardsNum","Slash") > 0 and package_known(self,"slashIsAvailable") then
				local card_str = ("#shuangpao:%d:")
				return source_construct(self,card_str)
			end
		end
	end
end

sgs.ai_skill_use_func["#shuangpao"]=function(card,use,self,request)
	use.card = card
end

sgs.ai_use_priority["shuangpao"] = sgs.ai_use_value.Analeptic
sgs.ai_use_value["shuangpao"] = sgs.ai_use_value.Analeptic

sgs.ai_skill_invoke.ew_lingshi = function(self, data)
	return true
end
sgs.ai_ajustdamage_from.shuangpao = function(self, from, to, card, nature)
	if card and package_known(card,"hasFlag","shuangpao") then
		return 1
	end
end


sgs.ai_skill_invoke.yindun = function(self, data)
	return true
end

sgs.ai_skill_invoke.gaoda_ansha = function(self, data)
	local player = package_call(self.room,"getCurrent")
	return not package_known(self,"isFriend",player)
end


local gelin_skill = {}
gelin_skill.name = "gelin"
table.insert(package_skills, gelin_skill)
gelin_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getPile","dan"):isEmpty() or not fact(self,"slash_available") then
		return false
	end
	for i = 0, package_known(self.player,"getPile","dan"):length() - 1, 1 do
		local slash = disclosed_card(self,package_known(self.player,"getPile","dan"):at(i))
		local slash_str = ("spread_shoot:gelin[%s:%s]=%d"):format(package_known(slash,"getSuitString"), package_known(slash,"getNumberString"), package_known(self.player,"getPile","dan"):at(i))
		local gelinslash = source_construct(self,slash_str)
		for _,enemy in ipairs(self.enemies) do
			if package_known(self.player,"canSlash",enemy, gelinslash) and package_known(self,"slashIsEffective",gelinslash, enemy) then
				local suit = package_known(slash,"getSuitString")
				local number = package_known(slash,"getNumberString")
				local card_id = package_known(slash,"getEffectiveId")
				local card_str = ("spread_shoot:gelin[%s:%s]=%d"):format(suit, number, card_id)
				local slash = source_construct(self,card_str)
				assert(slash)
				return slash
			end
		end
	end
end

sgs.ai_view_as.gelin = function(card, player, card_place)
 local self=actor_ai(player)
	if package_known(player,"getPile","dan"):isEmpty() then return false end
	local pattern -- source unused ambient read omitted; next statement overwrites it
	if card_place == sgs.Player_PlaceSpecial then
		if pattern == "jink" then
			if package_known(player,"getPile","dan"):length() < 2 then return false end
			local jink = clone_native(self,"jink", sgs.Card_SuitToBeDecided, -1)
			local id1
			local id2
			for i = 0, 1, 1 do
				local id = package_known(player,"getPile","dan"):at(i)
				package_call(jink,"addSubcard",id)
				if id1 == nil then
					id1 = id
				else
					id2 = id
				end
			end
			local suit = package_known(jink,"getSuitString")
			local number = package_known(jink,"getNumberString")
			if package_known(player,"getPileName",id1) == "dan" and package_known(player,"getPileName",id2) == "dan" then
				return ("jink:gelin[%s:%s]=%d+%d"):format(suit, number, id1, id2)
			end







		end
	end
end

sgs.ai_use_value["gelin"] = sgs.ai_use_value.SpreadShoot
sgs.ai_use_priority["gelin"] = sgs.ai_use_priority.SpreadShoot

ai_skill_use["@@gelin"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "defenseSlash")
	local archery_attack = clone_native(self,"archery_attack")
	package_call(archery_attack,"setSkillName","gelin")
	local use = dummy(false)
	package_call(self,"useTrickCard",archery_attack, use)
	if use.card then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByUseValue",cards, true)
		for _,card in ipairs(cards) do
			if not package_known(card,"isKindOf","Peach") and not package_known(card,"isKindOf","ExNihilo") and not (package_known(self.player,"getHp") == 1 and package_known(card,"isKindOf","Analeptic")) then
				return ("archery_attack:gelin[%s:%s]=%d"):format(package_known(card,"getSuitString"), package_known(card,"getNumberString"), package_known(card,"getEffectiveId"))
			end
		end
	end
	return "."
end


sgs.ai_skill_invoke.shuanglian = function(self, data)
	local invoke = false
	local pattern = package_known(data,"toStringList")[1]
	if pattern == "slash" then
		for _,enemy in ipairs(self.enemies) do
			if package_known(self.player,"inMyAttackRange",enemy) then
				invoke = true
				break
			end
		end
		return invoke and package_known(self,"getCardsNum","Jink") > 0
	elseif pattern == "jink" then
		for _,enemy in ipairs(self.enemies) do
			local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
			if (not package_known(self,"slashProhibit",slash, enemy, self.player)) and package_known(self.player,"canSlash",enemy, slash) and package_known(self,"slashIsEffective",slash, enemy) then
				invoke = true
				break
			end
		end
		return invoke
	end
	return false
end
sgs.ai_skill_cardask["@@shuanglianjink"] = function(self, data, pattern)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do
		if match_pattern(self,self.player,pattern,h)
		then return package_known(h,"getEffectiveId") end
		if package_known(h,"isKindOf",pattern)
		then return package_known(h,"getEffectiveId") end
	end

    return "."
end
sgs.ai_skill_cardask["@@shuanglianjinkres"] = function(self, data, pattern)
	local target = package_known(data,"toCardUse").from
	if target and package_known(self,"needToLoseHp",self.player, target) then return "." end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do
		if match_pattern(self,self.player,pattern,h)
		then return package_known(h,"getEffectiveId") end
		if package_known(h,"isKindOf",pattern)
		then return package_known(h,"getEffectiveId") end
	end

    return "."
end

sgs.ai_playerchosen_intention.shuanglian = function(self, from, to)
	if not package_known(self,"needToLoseHp",to, from) then
		sgs.updateIntention(from, to, 50)
	end
end
sgs.ai_skill_playerchosen.shuanglian = function(self, targets)
	for _, target in sgs.qlist(targets) do
		local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		package_call(slash,"deleteLater")
		if package_known(self,"isEnemy",target) and ((not package_known(self.player,"getStrategyFlag","shuanglian_jink")) or package_known(self,"slashIsEffective",slash, target)) then
			return target
		end
	end
end

sgs.ai_skill_invoke.zaizhan = function(self, data)
	if #self.friends_noself > 0 then
		return package_known(self.player,"getLostHp") > 1
	else
		return package_known(self.player,"getHp") < 2 or package_known(self.player,"getHandcardNum") < 2
	end
	return false
end

ai_skill_use["@@zaizhan"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	if #self.friends_noself > 0 then
		package_call(self,"sort",self.friends, "handcard")
		local selectset = {}
		for _, friend in ipairs(self.friends) do
			table.insert(selectset, package_known(friend,"objectName"))
			if #selectset >= package_known(self.player,"getLostHp") then break end
		end
		if #selectset > 0 then
			return ("#zaizhan:.:->%s"):format(table.concat(selectset,"+"))
		else
			return "."
		end
	else
		return ("#zaizhan:.:->%s"):format(package_known(self.player,"objectName"))
	end
	return "."
end


local shuanglong_skill={}
shuanglong_skill.name="shuanglong"
table.insert(package_skills,shuanglong_skill)
shuanglong_skill.getTurnUseCard=function(self,inclusive,request)

	 if package_known(self.player,"getHandcardNum") < 2 or package_known(self.player,"hasUsed","#shuanglong") then return false end
	return source_construct(self,"#shuanglong:.:")
end

sgs.ai_skill_use_func["#shuanglong"]=function(card,use,self,request)
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	package_call(self,"sortByUseValue",cards,true)
	package_call(self,"sort",self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if not package_known(enemy,"isKongcheng") then
			for _, card in ipairs(cards) do
				if not package_known(card,"isKindOf","Peach") and not package_known(card,"isKindOf","ExNihilo") and not package_known(card,"isKindOf","Jink") then
					use.card = source_construct(self,"#shuanglong:"..package_known(card,"getId")..":")
					if use.to then package_call(use.to,"append",enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen["shuanglong1"] = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if package_known(self,"isEnemy",target) then
			return target
		end
	end
end

sgs.ai_skill_playerchosen["shuanglong2"] = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if package_known(self,"isFriend",target) then
			return target
		end
	end
end

sgs.ai_skill_cardchosen["shuanglong"] = function(self, who, flags)
	local cards = sgs.QList2Table(package_known(who,"getEquips"))
	for i=1,#cards,1 do
		if (package_known(cards[i],"isKindOf","Weapon") and package_call(self.player,"getWeapon") == nil) or
		(package_known(cards[i],"isKindOf","Armor") and package_call(self.player,"getArmor") == nil) or
		(package_known(cards[i],"isKindOf","DefensiveHorse") and package_known(self.player,"getDefensiveHorse") == nil) or
		(package_known(cards[i],"isKindOf","OffensiveHorse") and package_known(self.player,"getOffensiveHorse") == nil) then
			return cards[i]
		end
	end
	return nil
end

sgs.ai_use_value["shuanglong"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["shuanglong"] = sgs.ai_use_priority.Slash + 1

sgs.ai_cardneed.shuanglong = sgs.ai_cardneed.bignumber


local weibo_skill={}
weibo_skill.name="weibo"
table.insert(package_skills,weibo_skill)
weibo_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	local willUse = false
	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
			willUse = true
			break
		end
	end
	if not willUse then return false end

	local n = 0
	for _,enemy in ipairs(self.enemies) do
		local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		if (not package_known(self,"slashProhibit",slash, enemy, self.player)) and package_known(self.player,"canSlash",enemy, slash) and package_known(self,"slashIsEffective",slash, enemy) then
			n = n + 1
		end
	end
	if (n == 1 and package_known(self.player,"getStrategyMark","@point") > 0) or (n > 1 and package_known(self.player,"getStrategyMark","@point") > 2) and package_known(self,"getCardsNum","Slash") > 0 and fact(self,"slash_available") then
		local card_str = ("#weibo:%d:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#weibo"]=function(card,use,self,request)
	use.card = card
end

sgs.dynamic_value.benefit["weibo"] = true

sgs.ai_use_value["weibo"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["weibo"] = sgs.ai_use_priority.Analeptic

sgs.ai_ajustdamage_from.weibo = function(self,from,to,card,nature)
	if card and package_known(card,"isKindOf","Slash") and package_known(from,"getStrategyMark","weibo") > 0
	then return package_known(from,"getStrategyMark","weibo") end
end

local weixing_skill={}
weixing_skill.name="weixing"
table.insert(package_skills,weixing_skill)
weixing_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"hasUsed","#weixing") then return false end
		local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		local willUse = false
		for _,c in sgs.list(cards)do
			if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
				willUse = true
				break
			end
		end
		if not willUse then return false end

	local n = 0
	for _,enemy in ipairs(self.enemies) do
		local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		if (not package_known(self,"slashProhibit",slash, enemy, self.player)) and package_known(self.player,"canSlash",enemy, slash) and package_known(self,"slashIsEffective",slash, enemy) then
			n = n + 1
		end
	end
	if (n == 1 and package_known(self.player,"getStrategyMark","@point") > 1) or (n > 1 and package_known(self.player,"getStrategyMark","@point") > 3) and package_known(self,"getCardsNum","Slash") > 0 and fact(self,"slash_available") then
		local card_str = ("#weixing:%d:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#weixing"] = function(card,use,self,request)
	use.card = card
end

sgs.dynamic_value.benefit["weixing"] = true

sgs.ai_use_value["weixing"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["weixing"] = sgs.ai_use_priority.Analeptic

sgs.ai_skill_invoke.gaoda_difa = function(self, data)
	return true
end

ai_skill_use["@@gaoda_difa"]=function(self,prompt,request)
	local judge = source_fact(self,"gaoda_difa","toJudge")
	local ids = package_known(self.player,"getPile","gaoda_difa")
	if package_known(self.room,"getMode"):find("_mini_46") and not package_known(judge,"isGood") then return "#gaoda_difa:"..package_known(ids,"first")..":" end
	if package_known(self,"needRetrial",judge) then
		local cards = {}
		for _,id in sgs.qlist(ids) do
			table.insert(cards,disclosed_card(self,id))
		end
		local card_id = package_known(self,"getRetrialCardId",cards, judge)
		if card_id ~= -1 then
			return "#gaoda_difa:"..card_id..":"
		end
	end
	return "."
end


sgs.ai_skill_invoke.laobing = function(self, data)
	return true
end

sgs.ai_skill_invoke.baopo = function(self, data)
	local damage = package_known(data,"toDamage")
	if package_known(self,"isEnemy",damage.to) then
		return not (package_known(damage.to,"isWounded") and package_call(damage.to,"getArmor") and package_known(damage.to,"getEquips"):length() == 1 and package_call(damage.to,"getArmor"):getClassName() == "SilverLion")
	elseif package_known(self,"isFriend",damage.to) then
		return (package_known(damage.to,"isWounded") and package_call(damage.to,"getArmor") and package_call(damage.to,"getArmor"):getClassName() == "SilverLion")
	end
	return false
end

sgs.ai_skill_cardchosen["baopo"] = function(self, who, flags)
	local cards = sgs.QList2Table(package_known(who,"getEquips"))
	for i=1,#cards,1 do
		if package_known(self,"isEnemy",who) then
			if not (package_known(who,"isWounded") and package_known(cards[i],"getClassName") == "SilverLion") then
				return cards[i]
			end
		elseif package_known(self,"isFriend",who) then
			if (package_known(who,"isWounded") and package_known(cards[i],"getClassName") == "SilverLion") then
				return cards[i]
			end
		end
	end
	return nil
end


sgs.ai_skill_invoke.huanzhuang = function(self, data)
	local promptlist = package_known(data,"toString"):split(":")
	local effect = promptlist[1]
	local enemy = package_call(self.room,"findPlayerByObjectName",promptlist[2])
	if effect == "throw" then
		return enemy and package_known(self,"isEnemy",enemy)
	else



		local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		local willUse = false
		for _,c in sgs.list(cards)do
			if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
				willUse = true
				break
			end
		end
		if not willUse then return false end
		return true
	end
	return false
end

sgs.ai_ajustdamage_from.huanzhuang = function(self,from,to,card,nature)
	if card and package_known(card,"isKindOf","Slash") and package_known(from,"getStrategyMark","huanzhuangb") > 0
	then return 1 end
end







local jiechi_skill = {}
jiechi_skill.name = "jiechi"
table.insert(package_skills, jiechi_skill)
jiechi_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getHandcardNum") < 2 then return false end
	for _,enemy in ipairs(self.enemies) do
		if not package_known(enemy,"getEquips"):isEmpty() then
			return source_construct(self,"#jiechi:.:")
		end
	end
end

sgs.ai_skill_use_func["#jiechi"] = function(card,use,self,request)
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	for _,card in ipairs(cards) do
		if not (package_known(card,"isKindOf","Peach") or package_known(card,"isKindOf","ExNihilo")) then
			use.card = source_construct(self,"#jiechi:"..package_known(card,"getId")..":")
			if use.to then
				for _,enemy in ipairs(self.enemies) do
					if not package_known(enemy,"getEquips"):isEmpty() then
						package_call(use.to,"append",enemy)
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_value["jiechi"] = sgs.ai_use_value.Dismantlement
sgs.ai_use_priority["jiechi"] = sgs.ai_use_priority.Dismantlement

local juexin_skill = {}
juexin_skill.name = "juexin"
table.insert(package_skills, juexin_skill)
juexin_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.enemies == 0 then return false end
	if package_known(self.player,"getStrategyMark","@juexin") > 0 and ((package_known(self.player,"getHp") < 2 and package_known(self.room,"alivePlayerCount") > 2 and not package_known(self.player,"isLord")) or
		(package_known(self.player,"getHp") == 2 and package_known(self.player,"isKongcheng") and #self.enemies > 1) or
		(package_known(self.room,"alivePlayerCount") == 2 and ((package_known(self.enemies[1],"getHp") == 2 and package_known(self.enemies[1],"isKongcheng")) or
		(package_known(self.enemies[1],"getHp") == 1 and package_known(self.enemies[1],"getHandcardNum") < 2)))) then
		return source_construct(self,"#juexin:.:")
	end
end

sgs.ai_skill_use_func["#juexin"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "hp")
	use.card = card
	if use.to then
		package_call(use.to,"append",self.enemies[1])
		return
	end
end

sgs.ai_use_value["juexin"] = 3
sgs.ai_use_priority["juexin"] = 0.1


local shuangqiang_skill = {}
shuangqiang_skill.name = "shuangqiang"
table.insert(package_skills, shuangqiang_skill)
shuangqiang_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getPhase") ~= sgs.Player_Play then return false end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	local newcards = {}
	for _, card in ipairs(cards) do
		if (isCard("EquipCard", card, self.player) or isCard("TrickCard", card, self.player)) and not (isCard("ExNihilo", card, self.player)) then table.insert(newcards, card) end
	end
	if #newcards < 1 then return end

	local card_id1 = package_known(newcards[1],"getEffectiveId")

	if package_known(newcards[1],"isBlack") then
		local black_slash = clone_native(self,"slash", sgs.Card_NoSuitBlack)
		package_call(black_slash,"deleteLater")
		local nosuit_slash = clone_native(self,"slash")
		package_call(nosuit_slash,"deleteLater")

		package_call(self,"sort",self.enemies, "defenseSlash")
		for _, enemy in ipairs(self.enemies) do
			if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",nosuit_slash, enemy) and package_known(self,"slashIsEffective",nosuit_slash, enemy)
				and package_known(self,"canAttack",enemy) and package_known(self,"slashProhibit",black_slash, enemy) and package_known(self,"isWeak",enemy) then
				local redcards, blackcards = {}, {}
				for _, acard in ipairs(newcards) do
					if package_known(acard,"isBlack") then table.insert(blackcards, acard) else table.insert(redcards, acard) end
				end
				if #redcards == 0 then break end

				local redcard, othercard

				package_call(self,"sortByUseValue",blackcards, true)
				package_call(self,"sortByUseValue",redcards, true)
				redcard = redcards[1]

				othercard = #blackcards > 0 and blackcards[1]
				if redcard and othercard then
					card_id1 = package_known(redcard,"getEffectiveId")
					break
				end
			end
		end
	end

	local card_str = ("slash:shuangqiang[%s:%s]=%d"):format("to_be_decided", 0, card_id1)
	local slash = source_construct(self,card_str)
	return slash
end

sgs.ai_use_value["shuangqiang"] = sgs.ai_use_value.Slash + 0.1
sgs.ai_use_priority["shuangqiang"] = sgs.ai_use_priority.Slash + 0.1

local zuzhuang_skill = {}
zuzhuang_skill.name = "zuzhuang"
table.insert(package_skills, zuzhuang_skill)
zuzhuang_skill.getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	local equipcards = {}
	local trickcards = {}
	for _, card in ipairs(cards) do
		if isCard("EquipCard", card, self.player) then table.insert(equipcards, card)
		elseif isCard("TrickCard", card, self.player) and not (isCard("ExNihilo", card, self.player)) then table.insert(trickcards, card) end
	end
	if #equipcards < 1 or #trickcards < 1 then return end

	local card_id1 = package_known(equipcards[1],"getEffectiveId")
	local card_id2 = package_known(trickcards[1],"getEffectiveId")

	local card_str = ("slash:zuzhuang[%s:%s]=%d+%d"):format("to_be_decided", 0, card_id1, card_id2)
	local slash = source_construct(self,card_str)
	return slash
end

sgs.ai_use_value["zuzhuang"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["zuzhuang"] = sgs.ai_use_priority.Slash + 0.2

sgs.ai_skill_choice.zuzhuang = function(self, choices, data)
	local choice = package_known(choices,"split","+")
	return choice[math.random(1, #choice)]
end


local sijue_skill={}
sijue_skill.name="sijue"
table.insert(package_skills,sijue_skill)
sijue_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards,true)
	local card
	for _,acard in ipairs(cards)  do
		if (package_known(acard,"isBlack")) and (package_known(acard,"isKindOf","BasicCard")) then
			card = acard
			break
		end
	end
	if not card then return nil end
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	local card_str = ("duel:sijue[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = source_construct(self,card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_use_value["sijue"] = sgs.ai_use_value.Duel
sgs.ai_use_priority["sijue"] = sgs.ai_use_priority.Duel

sgs.ai_skill_invoke.pojia = function(self, data)
	local damage = package_known(data,"toDamage")
	return package_known(self,"isEnemy",damage.from)
end

sgs.ai_ajustdamage_to.pojia = function(self, from, to, card, nature)
	if card and package_known(card,"isKindOf","Duel") and table.contains(package_known(card,"getSkillNames"), "pojiacard") then
		return -99
	end
end


sgs.ai_skill_invoke.yinxian = function(self, data)
	return true
end

sgs.ai_skill_invoke.zhuanjin = function(self, data)
	return package_known(self,"isFriend",package_known(data,"toDying").who)
end


sgs.ai_skill_invoke.helie = function(self, data)
	local cards = package_known(self.player,"getHandcards")
	local n = 0
	for _, card in sgs.qlist(cards) do
		if package_known(card,"isKindOf","Peach") or package_known(card,"isKindOf","ExNihilo") then
			n = n + 1
		end
	end
	return n == 0 and package_known(self.player,"getHandcardNum") < package_known(self.player,"getHp")
end

sgs.ai_skill_invoke.jiaoxie = function(self, data)
	local dying = package_known(data,"toDying")
	local target
	if package_known(dying.damage.from,"objectName") == package_known(self.player,"objectName") then
		target = dying.who
	elseif package_known(dying.who,"objectName") == package_known(self.player,"objectName") then
		target = dying.damage.from
	end
	if target == nil then return false end
	return package_known(self,"isEnemy",target)
end

sgs.ai_skill_choice.jiaoxie = function(self, choices, data)
	local choice = package_known(choices,"split","+")
	return choice[math.random(1, #choice)]
end

local gaoda_qishe_skill = {}
gaoda_qishe_skill.name = "gaoda_qishe"
table.insert(package_skills, gaoda_qishe_skill)
gaoda_qishe_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"isKongcheng") then return false end
	if (#self.enemies > 1 or (#self.enemies == 1 and (package_known(self,"getCardsNum","Slash") == 0 or package_known(self.player,"distanceTo",self.enemies[1]) > package_known(self.player,"getAttackRange")))) and
		(package_known(self.player,"hasSkill","helie") or package_known(self.player,"getHandcardNum") < 3) then
		local cards = package_known(self.player,"getHandcards")
		cards = sgs.QList2Table(cards)
		local ids = {}
		for _,card in ipairs(cards) do
			table.insert(ids, package_known(card,"getId"))
		end
		local card_str = ("fire_slash:gaoda_qishe[%s:%s]=%s"):format("to_be_decided", 0, table.concat(ids, "+"))
		local card = source_construct(self,card_str)
		return card
	end
end

sgs.ai_use_value["gaoda_qishe"] = sgs.ai_use_value.FireSlash
sgs.ai_use_priority["gaoda_qishe"] = sgs.ai_use_priority.Slash - 0.5


local shouwang_skill = {}
shouwang_skill.name = "shouwang"
table.insert(package_skills, shouwang_skill)
shouwang_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getMaxHp") > 0 and package_known(self.player,"getStrategyMark","Global_PreventPeach") == 0 and
		(package_known(self.player,"getLostHp") > 1 or (package_known(self.player,"getMaxHp") == 2 and package_known(self.player,"getHp") == 1 and package_known(self.player,"hasSkill","shouwang"))) then
		local card_str = ("peach:shouwang[no_suit:0]=.")
		local card = source_construct(self,card_str)
		return card
	end
end

sgs.ai_view_as.shouwang = function(card, player, card_place)
 local self=actor_ai(player)
	if package_known(player,"getMaxHp") > 0 and package_known(player,"getStrategyMark","Global_PreventPeach") == 0 then
		return ("peach:shouwang[no_suit:0]=.")
	end
end

sgs.ai_use_value["shouwang"] = sgs.ai_use_value.Peach
sgs.ai_use_priority["shouwang"] = sgs.ai_use_priority.Peach - 0.5

sgs.ai_skill_invoke.huiwu = function(self, data)
	if package_known(self,"getCardsNum","Slash") > 0 and fact(self,"slash_available") then return false end
	return package_known(self.player,"getHandcardNum") == 1 or package_known(self.player,"hasSkill","helie")
end


local wenshen_skill = {}
wenshen_skill.name = "wenshen"
table.insert(package_skills, wenshen_skill)
wenshen_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self,"getCardsNum","EquipCard") == 0 then return false end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	if (package_known(self,"getCardsNum","EquipCard") < 2 and package_known(self,"getCardsNum","Slash") == 0) or not sgs.Analeptic_IsAvailable(self.player) then
		local newcards = {}
		for _, card in ipairs(cards) do
			if isCard("EquipCard", card, self.player) and (not package_known(card,"hasFlag","using")) then table.insert(newcards, card) end
		end
		if #newcards < 1 then return end

		local card_id1 = package_known(newcards[1],"getEffectiveId")

		if package_known(newcards[1],"isBlack") then
			local black_slash = clone_native(self,"slash", sgs.Card_NoSuitBlack)
			local nosuit_slash = clone_native(self,"slash")

			package_call(self,"sort",self.enemies, "defenseSlash")
			for _, enemy in ipairs(self.enemies) do
				if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",nosuit_slash, enemy) and package_known(self,"slashIsEffective",nosuit_slash, enemy)
					and package_known(self,"canAttack",enemy) and package_known(self,"slashProhibit",black_slash, enemy) and package_known(self,"isWeak",enemy) then
					local redcards, blackcards = {}, {}
					for _, acard in ipairs(newcards) do
						if package_known(acard,"isBlack") then table.insert(blackcards, acard) else table.insert(redcards, acard) end
					end
					if #redcards == 0 then break end

					local redcard, othercard

					package_call(self,"sortByUseValue",blackcards, true)
					package_call(self,"sortByUseValue",redcards, true)
					redcard = redcards[1]

					othercard = #blackcards > 0 and blackcards[1]
					if redcard and othercard then
						card_id1 = package_known(redcard,"getEffectiveId")
						break
					end
				end
			end
		end
		local scard = disclosed_card(self,card_id1)
		local card_str = ("slash:wenshen[%s:%s]=%d"):format(package_known(scard,"getSuitString"), package_known(scard,"getNumberString"), card_id1)
		local slash = source_construct(self,card_str)
		return slash
	else
		local card
		for _,acard in ipairs(cards)  do
			if isCard("EquipCard", acard, self.player) then
				card = acard
				break
			end
		end

		if not card then return nil end
		local card_str = ("analeptic:wenshen[%s:%s]=%d"):format(package_known(card,"getSuitString"), package_known(card,"getNumberString"), package_known(card,"getEffectiveId"))
		local analeptic = source_construct(self,card_str)
		local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		local willUse = false
		for _,c in sgs.list(cards)do
			if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
				willUse = true
				break
			end
		end

		if sgs.Analeptic_IsAvailable(self.player, analeptic) and willUse then
			assert(analeptic)
			return analeptic
		end
	end
end

sgs.ai_use_value["wenshen"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["wenshen"] = sgs.ai_use_priority.Analeptic - 0.1

sgs.ai_view_as.wenshen = function(card, player, card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	local usereason = owner_reason(self)
	local pattern -- source unused ambient read omitted; next statement overwrites it
	if package_known(card,"isKindOf","EquipCard") and (not package_known(card,"hasFlag","using")) then
		if pattern == "slash" and usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return ("slash:wenshen[%s:%s]=%d"):format(suit, number, card_id)
		else
			return ("analeptic:wenshen[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.wenshen_keep_value = {
	EquipCard = sgs.ai_keep_value.Analeptic
}

sgs.ai_skill_playerchosen.jinduan = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if package_known(self,"isEnemy",target) then
			return target
		end
	end
	return nil
end

sgs.ai_skill_invoke.liesha = function(self, data)
	return true
end
sgs.ai_card_priority.liesha = function(self,card)
	if package_known(card,"isKindOf","Slash") and package_known(card,"isBlack")
	then if self.useValue
		then return 1 end end
end
function sgs.ai_slash_prohibit.jinduan(self,from,to,card)
	if package_known(self,"isFriend",to,from) then return false end
	if package_known(from,"getStrategyFlag","NosJiefanUsed") then return false end
	if card and not package_known(card,"isRed") then return false end
	for _,friend in ipairs(package_known(self,"getFriends",from,true))do
		if package_known(self,"slashIsEffective",card,friend,from) then return true end
	end
end


sgs.ai_skill_invoke.quanyu = function(self, data)
	local prompt = package_known(data,"toString")
	if prompt == "A" then
		if package_known(self.player,"isNude") then return false end
		return package_known(self,"getCardsNum","Slash") > 0 or (package_known(self.player,"getHp") == 1 and package_known(self,"getCardsNum","Jink") + package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") + package_known(self,"getCardsNum","Guard") + package_known(self,"getCardsNum","CounterGuard") == 0)
	elseif package_known(prompt,"startsWith","S") then
		local name = package_known(prompt,"split",":")[2]
		local target = package_call(self.room,"findPlayerByObjectName",name)
		return package_known(self,"isEnemy",target)
	elseif prompt == "L" then
		return true
	end
	return true
end
sgs.ai_ajustdamage_from.quanyu = function(self, from, to, card, nature)
	if card and package_known(card,"isKindOf","Slash") and package_known(card,"hasFlag","quanyu_S1: " .. package_known(to,"objectName")) then
		return 1
	end
end

sgs.ai_skill_choice.quanyu = function(self, choices, data)
	choices = package_known(choices,"split","+")
	local use = package_known(data,"toCardUse")
	if choices[1] == "quanyu_S1" then
		local enemy = source_fact(self,"quanyu_S","toPlayer")
		if package_known(self,"isFriend",enemy) then
			return "cancel"
		end
		if package_known(self,"slashIsEffective",use.card, enemy) and (getCardsNum("Jink", enemy) < 1 or (package_known(self.player,"hasWeapon","axe") and package_known(self.player,"getCardCount") > 4)) then
			return choices[1]
		else
			return choices[2]
		end
	elseif choices[1] == "quanyu_L1" then
		for _, enemy in ipairs(self.enemies) do
			if package_known(self.player,"inMyAttackRange",enemy) then
				return choices[2]
			end
		end
		return choices[1]
	end
	return choices[1]
end


sgs.ai_skill_playerchosen.longqi = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "handcard")
	targets = sgs.reverse(targets)
	for _,target in ipairs(targets) do
		if package_known(self,"isEnemy",target) and (not package_known(target,"isKongcheng")) then
			return target
		end
	end
	return nil
end

sgs.ai_skill_cardchosen["longqi"] = function(self, who, flags)
	local cards = sgs.QList2Table(package_known(who,"getHandcards"))
	local cn = package_known(self.player,"getStrategyMark","longqi_ai")
	local sides = {}
	if cn > 1 then table.insert(sides, cn - 1) end
	if cn < 13 then table.insert(sides, cn + 1) end
	for _,card in ipairs(cards) do
		local idn = package_known(card,"getNumber")
		if table.contains(sides, idn) then
			return card
		end
	end
	for _,card in ipairs(cards) do
		local idn = package_known(card,"getNumber")
		if idn == cn then
			return card
		end
	end
	return cards[math.random(#cards)]
end


ai_skill_use["@@hundun"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	if #self.enemies > 0 then
		package_call(self,"sort",self.enemies, "defenseSlash")
		local selectset = {}
		for _,enemy in ipairs(self.enemies) do
			if not package_known(self,"slashProhibit",clone_native(self,"slash", sgs.Card_NoSuitBlack, 0), enemy) then
				table.insert(selectset, package_known(enemy,"objectName"))
			end
			if #selectset >= 2 then break end
		end
		if #selectset > 0 then
			return ("#hundun:.:->%s"):format(table.concat(selectset,"+"))
		end
	end
	return "."
end

sgs.ai_can_damagehp.shenyuan = function(self,from,card,to)
	return package_known(to,"getHp")+package_known(self,"getAllPeachNum")-package_known(self,"ajustDamage",from,to,1,card)>0
	and package_known(self,"canLoseHp",from,card,to) and card and package_known(card,"isRed") and not package_known(to,"isKongcheng") and package_known(to,"hasSkill","hundun") and sgs.ai_skill_use["@@hundun"] ~= "."
end



local dadi_skill={}
dadi_skill.name="dadi"
table.insert(package_skills,dadi_skill)
dadi_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getHandcardNum") == 1 then
		local card = package_known(self.player,"getHandcards"):first()
		if (not isCard("ExNihilo", card, self.player)) and (not package_known(self.player,"isWounded") or not isCard("Peach", card, self.player)) then
			local suit = package_known(card,"getSuitString")
			local number = package_known(card,"getNumberString")
			local card_id = package_known(card,"getEffectiveId")
			local card_str = ("slash:dadi[%s:%s]=%d"):format(suit, number, card_id)
			local slash = source_construct(self,card_str)
			assert(slash)
			return slash
		end
	end
end

sgs.ai_view_as.dadi = function(card, player, card_place)
 local self=actor_ai(player)
	local cd = package_known(player,"getHandcards"):first()
	if package_known(player,"getHandcardNum") == 1 and (package_known(player,"isWounded") or not package_known(player,"faceUp")) then
		local suit = package_known(cd,"getSuitString")
		local number = package_known(cd,"getNumberString")
		local card_id = package_known(cd,"getEffectiveId")
		return ("slash:dadi[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value["dadi"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["dadi"] = sgs.ai_use_priority.Slash + 1


sgs.ai_card_priority.dadi = function(self,card)
	if table.contains(package_known(card,"getSkillNames"), "dadi")
	then
		return 1
	end
end

sgs.ai_skill_choice.daohe = function(self, choices, data)
	choices = package_known(choices,"split","+")
	if table.contains(choices, "jiying") then
		package_call(self,"sort",self.enemies, "hp")
		local enemy = self.enemies[1]
		local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		package_call(slash,"deleteLater")
		local n = 0
		local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		local willUse = false
		for _,c in sgs.list(cards)do
			if package_known(c,"isKindOf","Analeptic") and package_known(self,"willUse",self.player,c) then
				n = 1
			end
		end
		for _,c in sgs.list(cards)do
			if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
				if package_known(self.player,"canSlash",enemy, slash) and package_known(self,"slashIsEffective",slash, enemy) and
					package_known(enemy,"getHp") <= 1 + n then
					return "jiying"
				end
			end
		end





	end
	if table.contains(choices, "meiying") then
		local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		local willUse = false
		for _,c in sgs.list(cards)do
			if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) and package_known(self,"getCardsNum","Slash") > 1 then
				return "meiying"
			end
		end



	end
	if table.contains(choices, "jianyingg") then
		return "jianyingg"
	end
	return choices[1]
end

sgs.ai_skill_invoke.jianyingg = function(self, data)
	return true
end

sgs.ai_skill_invoke.jiying = function(self, data)
	local damage = package_known(data,"toDamage")
	return package_known(self,"isEnemy",damage.to)
end
sgs.ai_can_damagehp.emeng = function(self,from,card,to)
	return package_known(to,"getHp")+package_known(self,"getAllPeachNum")-package_known(self,"ajustDamage",from,to,1,card)>0
	and package_known(self,"canLoseHp",from,card,to) and package_known(to,"hasSkill","daohe") and from and (not package_known(to,"inMyAttackRange",from)) and card and package_known(card,"isKindOf","Slash")
end


sgs.ai_skill_invoke.gaoda_shanzhuan = function(self, data)
	return true
end

ai_skill_use["@@gaoda_shanzhuan"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "defenseSlash")
	local id = tonumber(prompt)
	local card = disclosed_card(self,id)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",card, enemy) then
			table.insert(targets, package_known(enemy,"objectName"))
			if (not package_known(card,"isRed") and #targets == 1) or (package_known(card,"isRed") and #targets == 2) then break end
		end
	end
	if #targets > 0 then
		return ("%d->%s"):format(id, table.concat(targets, "+"))
	else
		return "."
	end
	return "."
end

sgs.ai_skill_invoke.zhongcheng = function(self, data)
	local damage = package_known(data,"toDamage")
	return package_known(self,"isEnemy",damage.from) and
	not (package_known(damage.from,"getEquips"):length() == 1 and package_call(damage.from,"getArmor") and package_call(damage.from,"getArmor"):getClassName() == "SilverLion")
end
sgs.ai_suppress_intention["huohai"] = true

sgs.ai_ajustdamage_from.kongju = function(self,from,to,card,nature)
	if package_known(from,"getStrategyMark","@kongju") > 0 and card and table.contains(package_known(card,"getSkillNames"), "huohai")
	then return 1 end
end
sgs.ai_target_revises.tiebi = function(to, card, self)
	if ((package_known(card,"isRed") and package_known(card,"isKindOf","Slash")) or package_known(card,"isKindOf","FireSlash"))
	then
		return package_known(to,"distanceTo",self.player) > 1
	end
end



ai_skill_use["@@bachi"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	if #self.enemies > 0 then
		package_call(self,"sort",self.enemies, "defenseSlash")
		local selectset = {}
		for _,enemy in ipairs(self.enemies) do
			if (not package_known(enemy,"isProhibited",enemy, clone_native(self,"slash", sgs.Card_NoSuitRed, 0))) then
				table.insert(selectset, package_known(enemy,"objectName"))
			end
			if #selectset >= 2 then break end
		end
		if #selectset > 0 then
			local cards = package_known(self.player,"getCards","he")
			cards = sgs.QList2Table(cards)
			package_call(self,"sortByUseValue",cards, true)
			return ("#bachi:%d:->%s"):format(package_known(cards[1],"getEffectiveId"), table.concat(selectset,"+"))
		else
			return "."
		end
	end
	return "."
end
sgs.ai_target_revises.bachi = function(to, card, self)
	if (package_known(card,"isRed") and (package_known(card,"isKindOf","Slash")) or package_known(card,"objectName"):endsWith("shoot"))
	then
		return package_known(to,"canDiscard",to, "he")
	end
end


local hubi_skill = {}
hubi_skill.name = "hubi"
table.insert(package_skills, hubi_skill)
hubi_skill.getTurnUseCard = function(self,inclusive,request)
	if (not package_known(self.player,"hasUsed","#hubi")) and package_known(self,"getCardsNum","Jink") > 0 then
		return source_construct(self,"#hubi:.:")
	end
end

sgs.ai_skill_use_func["#hubi"] = function(card,use,self,request)
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	package_call(self,"sortByUseValue",cards, true)
	package_call(self,"sort",self.friends, "defenseSlash")
	for _,card in ipairs(cards) do
		for _,friend in ipairs(self.friends) do
			local card_id = package_known(card,"getId")
			if package_known(card,"isKindOf","Jink") then
				use.card = source_construct(self,"#hubi:"..card_id..":")
				if use.to then package_call(use.to,"append",friend) end
				return
			end
		end
	end
end

sgs.ai_use_value["hubi"] = 5
sgs.ai_use_priority["hubi"] = 0.1

sgs.ai_skill_choice.hubi = function(self, choices, data)
	choices = package_known(choices,"split","+")
	local use = dummy(false)
	local card = clone_native(self,"archery_attack")
	package_call(self,"useTrickCard",card, use)
	if use.card then
		return choices[2]
	end
	return choices[1]
end


sgs.ai_skill_invoke.dajiu = function(self, data)
	local damage = package_known(data,"toDamage")
	if damage.from then
		return not package_known(self,"isFriend",damage.from) or package_known(damage.from,"isNude") or package_known(damage.from,"getCardCount") > 3
	end
	return true
end


local daijin_skill = {}
daijin_skill.name = "daijin"
table.insert(package_skills, daijin_skill)
daijin_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","daijin") then return false end
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	local newcards = {}
	local ids = {}
	for _, card in ipairs(cards) do
		if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
			table.insert(newcards, card)
			table.insert(ids, package_known(card,"getEffectiveId"))
		end
	end
	if #newcards < 2 then return end

	local card_id1 = package_known(newcards[1],"getEffectiveId")
	local card_id2 = package_known(newcards[2],"getEffectiveId")

	if package_known(newcards[1],"isBlack") and package_known(newcards[2],"isBlack") then
		local black_slash = clone_native(self,"fire_slash", sgs.Card_NoSuitBlack)
		package_call(black_slash,"setSkillName","daijin")
		local nosuit_slash = clone_native(self,"fire_slash")
		package_call(nosuit_slash,"setSkillName","daijin")

		package_call(self,"sort",self.enemies, "defenseSlash")
		for _, enemy in ipairs(self.enemies) do
			if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",nosuit_slash, enemy) and package_known(self,"slashIsEffective",nosuit_slash, enemy)
				and package_known(self,"canAttack",enemy) and package_known(self,"slashProhibit",black_slash, enemy) and package_known(self,"isWeak",enemy) then
				local redcards, blackcards = {}, {}
				for _, acard in ipairs(newcards) do
					if package_known(acard,"isBlack") then table.insert(blackcards, acard) else table.insert(redcards, acard) end
				end
				if #redcards == 0 then break end

				local redcard, othercard

				package_call(self,"sortByUseValue",blackcards, true)
				package_call(self,"sortByUseValue",redcards, true)
				redcard = redcards[1]

				othercard = #blackcards > 0 and blackcards[1] or redcards[2]
				if redcard and othercard then
					card_id1 = package_known(redcard,"getEffectiveId")
					card_id2 = package_known(othercard,"getEffectiveId")
					break
				end
			end
		end
	end

	local card_str = ("fire_slash:daijincard[%s:%s]=%d+%d"):format("to_be_decided", 0, card_id1, card_id2)

	if package_known(self.player,"getStrategyMark","@seedsf") > 0 and package_known(self.player,"getHandcardNum") > package_known(self.player,"getMaxCards") + 1 and #self.enemies > 2 then
		card_str = ("fire_slash:daijincard[%s:%s]=%s"):format("to_be_decided", 0, table.concat(ids, "+", 1, #self.enemies))
	end

	local slash = source_construct(self,card_str)
	return slash
end

sgs.ai_use_value["daijin"] = sgs.ai_use_value.FireSlash + 0.1
sgs.ai_use_priority["daijin"] = sgs.ai_use_priority.FireSlash

sgs.ai_skill_choice.daijin = function(self, choices, data)
	local choice = package_known(choices,"split","+")
	return choice[math.random(1, #choice)]
end

sgs.ai_skill_invoke.chaoqi = function(self, data)
	local use = package_known(data,"toCardUse")
	return not package_known(self,"isFriend",use.from)
end

sgs.ai_card_priority.daijin = function(self,card)
	if table.contains(package_known(card,"getSkillNames"), "daijincard")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end



sgs.ai_skill_invoke.hanwei = function(self, data)
	local name = package_known(data,"toString"):split(":")[3]
	local enemy = package_call(self.room,"findPlayerByObjectName",name)
	return enemy and package_known(self,"isEnemy",enemy)
end
sgs.ai_cardneed.hanwei = sgs.ai_cardneed.equip

ai_skill_use["@@shijiu"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "defenseSlash")
	local targets = {}
	local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",slash, enemy) then
			if #targets >= 1 + correct_target(self,"ExtraTarget",slash) then break end
			table.insert(targets, package_known(enemy,"objectName"))
		end
	end
	if #targets > 0 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByUseValue",cards, true)
		local suits = {}
		for _,cd in sgs.qlist(package_known(self.player,"getEquips")) do
			local suit = package_known(cd,"getSuit")
			if not table.contains(suits, suit) then
				table.insert(suits, suit)
			end
		end
		for _,card in ipairs(cards) do
			if table.contains(suits, package_known(card,"getSuit")) then
				return ("slash:shijiu[%s:%s]=%d->%s"):format(package_known(card,"getSuitString"), package_known(card,"getNumberString"), package_known(card,"getEffectiveId"), table.concat(targets, "+"))
			end
		end
	else
		return "."
	end
	return "."
end
sgs.ai_cardneed.shijiu = sgs.ai_cardneed.equip


sgs.ai_ajustdamage_from.feiniao = function(self,from,to,card,nature)
	if card and package_known(card,"objectName"):endsWith("shoot") and package_known(from,"getAttackRange") >= 4
	then return 1 end
end
sgs.ai_use_revises.feiniao = function(self,card,use)
	if package_known(card,"isKindOf","Slash") and package_known(self.player,"getAttackRange") == 2 then
		package_call(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end


sgs.ai_skill_invoke.huanyi = function(self, data)
	return true
end

sgs.ai_view_as.huanyi = function(card, player, card_place)
 local self=actor_ai(player)
	if package_known(player,"getStrategyMark","@huanyi") == 0 then return false end
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if package_known(card,"isRed") and card_place == sgs.Player_PlaceHand then
		return ("jink:huanyi[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_ajustdamage_from.nuhuo = function(self,from,to,card,nature)
	if package_known(from,"getStrategyMark","nuhuo_buff") > 0
	then return 1 end
end


sgs.ai_skill_invoke.jiqi = function(self, data)
	return true
end

ai_skill_use["@@jiqi"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	if #self.enemies > 0 then
		package_call(self,"sort",self.enemies, "defense")
		local selectset = {}
		for _,enemy in ipairs(self.enemies) do
			table.insert(selectset, package_known(enemy,"objectName"))
			if #selectset >= package_known(self.player,"getStrategyMark","jiqi") then break end
		end
		if #selectset > 0 then
			return ("#jiqi:.:->%s"):format(table.concat(selectset,"+"))
		end
	end
	return "."
end








sgs.ai_skill_invoke.kelong = function(self, data)
	return true
end

sgs.ai_view_as.kelong = function(card, player, card_place)
 local self=actor_ai(player)
	if package_known(player,"getPile","kelong"):isEmpty() then return false end
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if package_known(player,"getPileName",card_id) == "kelong" then
		return ("jink:kelong[%s:%s]=%d"):format(suit, number, card_id)
	end
end


local gaoda_jianhun_skill = {}
gaoda_jianhun_skill.name = "gaoda_jianhun"
table.insert(package_skills, gaoda_jianhun_skill)
gaoda_jianhun_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","gaoda_jianhun") or package_known(self.player,"getPile","hun"):length() >= 3 then return false end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	for _,card in ipairs(cards) do
		if package_known(card,"isRed") and not package_known(card,"isKindOf","ExNihilo") and not (package_known(self.player,"isWounded") and package_known(card,"isKindOf","Peach"))
			and not (package_known(self,"getCardsNum","Jink") == 1 and package_known(card,"isKindOf","Jink")) and not (package_known(self,"getCardsNum","Slash") == 1 and package_known(card,"isKindOf","Slash")) then
			local suit = package_known(card,"getSuitString")
			local number = package_known(card,"getNumberString")
			local card_id = package_known(card,"getEffectiveId")
			local card_str = ("ex_nihilo:gaoda_jianhun[%s:%s]=%d"):format(suit, number, card_id)
			local analeptic = source_construct(self,card_str)
			if sgs.Analeptic_IsAvailable(self.player, analeptic) then
				assert(analeptic)
				return analeptic
			end
		end
	end
end

sgs.ai_use_value["gaoda_jianhun"] = sgs.ai_use_value.Analeptic + 0.1
sgs.ai_use_priority["gaoda_jianhun"] = sgs.ai_use_priority.Analeptic + 0.1

sgs.ai_skill_invoke.gaoda_jianhun = function(self, data)
	local target = package_call(data,"toPlayer")
	return package_known(self,"isEnemy",target)
end

sgs.ai_use_revises.gaoda_jianhun = function(self,card,use)
	if package_known(card,"isKindOf","Slash") and package_known(card,"isBlack") and package_known(self.player,"getStrategyFlag","gaoda_jianhun-diamond") then
		package_call(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end


ai_skill_use["@@guanglei"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "defenseSlash")
	local targets = {}
	local slash = clone_native(self,"thunder_slash")
	package_call(slash,"setSkillName","guanglei")
	for i = 0, 2, 1 do
		package_call(slash,"addSubcard",package_known(self.player,"getPile","hun"):at(i))
	end
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"canSlash",enemy) and not package_known(enemy,"isProhibited",enemy, slash) then
			if #targets >= 1 + correct_target(self,"ExtraTarget",slash) then break end
			table.insert(targets, package_known(enemy,"objectName"))
		end
	end
	if #targets > 0 then
		return selected(self,slash,targets)
	end
	return "."
end

sgs.gaoda_jianhun_suit_value = {
	heart = 3.9,
	diamond = 3.9
}

function sgs.ai_cardneed.gaoda_jianhun(to, card)
	return package_known(card,"isRed")
end


sgs.ai_skill_invoke.luaqiangwu = function(self, data)
	return true
end

sgs.ai_skill_cardask["@luaqiangwu"] = function(self, data, pattern)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)

	local black_shoot, red_shoot = 0, 0
	local color = source_property(self,"luaqiangwucolor"):toString()
	local choice = ""

	for _,card in ipairs(cards) do
		if package_known(card,"objectName"):endsWith("shoot") and package_known(self.player,"getStrategyMark","luaqiangwut") == 0 and package_known(self.player,"getPhase") == sgs.Player_Play then
			if package_known(card,"isBlack") then
				black_shoot = 1
			elseif package_known(card,"isRed") then
				red_shoot = 1
			end
			if (black_shoot == 1 and red_shoot == 1) or (black_shoot == 1 and color == "red") or (red_shoot == 1 and color == "black") then
				choice = "TrickCard"
				break
			end
		end
		if package_known(card,"getSuit") == sgs.Card_Spade and package_known(self.player,"getStrategyMark","luaqiangwub") == 0 then
			choice = "BasicCard"
			break
		end
	end

	if choice ~= "" then
		for _,card in ipairs(cards) do do
			if package_known(card,"isKindOf",choice) then
				if (choice == "BasicCard" and package_known(card,"getSuit") == sgs.Card_Spade and package_known(self,"getSuitNum","spade", true, self.player) == 1) or
					(choice == "TrickCard" and package_known(card,"objectName"):endsWith("shoot") and (package_known(self,"getCardsNum","Shoot") + package_known(self,"getCardsNum","PierceShoot") + package_known(self,"getCardsNum","SpreadShoot")) == 1) then goto package_continue_6 end
				return package_known(card,"getEffectiveId")
			end
		end ::package_continue_6:: end
	end

	return package_known(self,"askForDiscard","luaqiangwu", 1, 1, false, true)[1]
end

sgs.ai_skill_invoke.shewei = function(self, data)
	local duel = clone_native(self,"duel")
	for _, enemy in ipairs(self.enemies) do
		if (not package_known(enemy,"isProhibited",enemy, duel)) then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardchosen["shewei"] = function(self, who, flags)
	local cards = package_known(self.player,"getCards","j")
	if not package_known(cards,"isEmpty") then
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByUseValue",cards, false)
		return cards[1]
	else
		cards = package_known(self.player,"getCards","e")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)
		return cards[1]
	end
	return nil
end

ai_skill_use["@@shewei"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	local duel = clone_native(self,"duel")
	local id = source_property(self,"shewei"):toInt()
	package_call(duel,"addSubcard",id)
	package_call(self,"sort",self.enemies, "handcard")
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if (not package_known(enemy,"isProhibited",enemy, duel)) then
			if #targets >= 1 + correct_target(self,"ExtraTarget",duel) then break end
			table.insert(targets, package_known(enemy,"objectName"))
		end
	end
	if #targets > 0 then
		return ("duel:shewei[%s:%s]=%s->%s"):format(package_known(duel,"getSuitString"), package_known(duel,"getNumberString"), id, table.concat(targets, "+"))
	end
	return "."
end


ai_skill_use["@@huantong"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	local subcard = nil
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	for _,card in ipairs(cards) do
		if package_known(card,"isBlack") and not package_known(card,"hasFlag","using") then
			subcard = card
		end
	end
	if subcard == nil then return "." end
	local iron_chain = clone_native(self,"iron_chain", package_known(subcard,"getSuit"), package_known(subcard,"getNumber"))
	package_call(iron_chain,"addSubcard",subcard)
	local targets = {}
	package_call(self,"sort",self.friends, "hp")
	for _, friend in ipairs(self.friends) do
		if package_known(friend,"isChained") and (not package_known(friend,"isProhibited",friend, iron_chain)) then
			if #targets >= 2 + correct_target(self,"ExtraTarget",iron_chain) then
				return ("iron_chain:huantong[%s:%s]=%s->%s"):format(package_known(iron_chain,"getSuitString"), package_known(iron_chain,"getNumberString"), package_known(subcard,"getEffectiveId"), table.concat(targets, "+"))
			end
			table.insert(targets, package_known(friend,"objectName"))
		end
	end
	package_call(self,"sort",self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if (not package_known(enemy,"isChained")) and (not package_known(enemy,"isProhibited",enemy, iron_chain)) then
			if #targets >= 2 + correct_target(self,"ExtraTarget",iron_chain) then break end
			table.insert(targets, package_known(enemy,"objectName"))
		end
	end
	if #targets > 0 then
		return ("iron_chain:huantong[%s:%s]=%s->%s"):format(package_known(iron_chain,"getSuitString"), package_known(iron_chain,"getNumberString"), package_known(subcard,"getEffectiveId"), table.concat(targets, "+"))
	elseif package_known(self.player,"getHp") <= 2 and package_known(self,"getCardsNum","Jink") == 0 then
		return ("iron_chain:huantong[%s:%s]=%s->%s"):format(package_known(iron_chain,"getSuitString"), package_known(iron_chain,"getNumberString"), package_known(subcard,"getEffectiveId"), package_known(self.enemies[1],"objectName"))
	end
	return "."
end

sgs.huantong_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.huantong(to, card)
	return package_known(card,"isBlack")
end

local jianmie_skill = {}
jianmie_skill.name = "jianmie"
table.insert(package_skills, jianmie_skill)
jianmie_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"isNude") or not fact(self,"slash_available") then
		return false
	end
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	for _,card in ipairs(cards) do
		local suit = package_known(card,"getSuitString")
		local number = package_known(card,"getNumberString")
		local card_id = package_known(card,"getEffectiveId")
		if package_known(card,"objectName") == "slash" and not package_known(card,"hasFlag","using") then
			local slash_str = ("fire_slash:jianmie[%s:%s]=%d"):format(suit, number, card_id)
			local jianmieslash = source_construct(self,slash_str)
			local targets = {}
			package_call(self,"sort",self.enemies, "defenseSlash")
			for _,enemy in ipairs(self.enemies) do
				if package_known(self.player,"canSlash",enemy, jianmieslash) and package_known(self,"slashIsEffective",jianmieslash, enemy) then
					if #targets == 1 then
						if package_known(enemy,"isChained") or package_call(self.room,"findPlayerByObjectName",targets[1]):isChained() then
							table.insert(targets, package_known(enemy,"objectName"))
						end
					else
						if #targets >= 2 + correct_target(self,"ExtraTarget",jianmieslash) then break end
						table.insert(targets, package_known(enemy,"objectName"))
					end
				end
			end
			if #targets > 0 then
				return source_construct(self,"#jianmie:" .. package_known(card,"getEffectiveId") .. ":->" .. table.concat(targets, "+"))
			end
		end
	end
end

sgs.ai_skill_use_func["#jianmie"] = function(card,use,self,request)
	use.card = card
	if use.to then
		local targets = {}
		package_call(self,"sort",self.enemies, "defenseSlash")
		local jianmieslash = clone(self,"fire_slash")
		for _,enemy in ipairs(self.enemies) do
			if package_known(self.player,"canSlash",enemy, jianmieslash) and package_known(self,"slashIsEffective",jianmieslash, enemy) then
				if #targets == 1 then
					if package_known(enemy,"isChained") or package_call(self.room,"findPlayerByObjectName",targets[1]):isChained() then
						table.insert(targets, package_known(enemy,"objectName"))
						package_call(use.to,"append",enemy)
					end
				else
					if #targets >= 2 + correct_target(self,"ExtraTarget",jianmieslash) then break end
					table.insert(targets, package_known(enemy,"objectName"))
					package_call(use.to,"append",enemy)
				end
			end
		end







	end
end

sgs.ai_use_value["jianmie"] = sgs.ai_use_value.FireSlash + 0.1
sgs.ai_use_priority["jianmie"] = sgs.ai_use_priority.Slash + 0.1


sgs.ai_skill_invoke.yuanjian = function(self, data)
	local target = package_call(data,"toPlayer")
	return not package_known(self,"isFriend",target)
end
sgs.ai_use_revises.yuanjian = function(self,card,use)
	if package_known(card,"isKindOf","Slash") and (package_known(card,"getSuit") == sgs.Card_Spade or (package_known(self.player,"getStrategyMark","exia_transammark") > 0 and package_known(card,"isBlack"))) then
		package_call(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end

local exia_transam_skill = {}
exia_transam_skill.name = "exia_transam"
table.insert(package_skills, exia_transam_skill)
exia_transam_skill.getTurnUseCard = function(self,inclusive,request)
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	local willUse = false
	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
			willUse = true
			break
		end
	end
	if package_known(self.player,"getStrategyMark","@exia_transam") > 0 and willUse then
		local n = package_known(self,"getCardsNum","Slash")
		package_call(self,"sort",self.enemies, "hp")
		local card = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		package_call(card,"deleteLater")
		if (n >= 2 and #self.enemies > 0 and not package_known(self.enemies[1],"isProhibited",self.enemies[1], card) and package_known(self,"slashIsEffective",card, self.enemies[1], self.player) and not package_known(self.enemies[1],"hasSkill","mosu")) or package_known(self.player,"getHp") == 1 then
			return source_construct(self,"#exia_transam:.:")
		end
	end
end

sgs.ai_skill_use_func["#exia_transam"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["exia_transam"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["exia_transam"] = sgs.ai_use_priority.Analeptic


local jvji_skill={}
jvji_skill.name="jvji"
table.insert(package_skills,jvji_skill)
jvji_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)

	local handcard

	package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)  do
		if package_known(card,"isKindOf","Slash") then
			handcard = card
			break
		end
	end

	if not handcard then return nil end
	local suit = package_known(handcard,"getSuitString")
	local number = package_known(handcard,"getNumberString")
	local card_id = package_known(handcard,"getEffectiveId")
	local card_str = ("shoot:jvji[%s:%s]=%d"):format(suit, number, card_id)
	local shoot = source_construct(self,card_str)
	assert(shoot)

	return shoot

end

sgs.ai_use_value["jvji"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["jvji"] = sgs.ai_use_priority.Slash + 0.6

sgs.ai_skill_invoke.jvji = function(self, data)
	local target = package_call(data,"toPlayer")
	return not package_known(self,"isFriend",target)
end

sgs.ai_card_priority.jvji = function(self,card,v)
	if package_known(card,"isKindOf","Shoot")
	then return 6 end
end


local dynames_transam_skill = {}
dynames_transam_skill.name = "dynames_transam"
table.insert(package_skills, dynames_transam_skill)
dynames_transam_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@dynames_transam") > 0 then
		local card = clone_native(self,"shoot", sgs.Card_NoSuit, 0)
		local use = dummy(false)
		package_known(self,"useCardShoot",card, use)
		if use.card then
			local shoots = {"Shoot", "PierceShoot", "SpreadShoot"}
			if package_known(self.player,"hasSkill","jvji") then
				table.insert(shoots, "Slash")
			end
			local n = package_known(self,"getCardsNum",shoots)
			package_call(self,"sort",self.enemies, "hp")
			if (n >= 2 and #self.enemies > 0 and not package_known(self.enemies[1],"isProhibited",self.enemies[1], card) and not package_known(self.enemies[1],"hasSkill","mosu")) or package_known(self.player,"getHp") == 1 then
				return source_construct(self,"#dynames_transam:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#dynames_transam"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["dynames_transam"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["dynames_transam"] = sgs.ai_use_priority.Analeptic


sgs.ai_skill_invoke.chaobing = function(self, data)
	return true
end

ai_skill_use["@@chaobing-slashshoot-AI"]=function(self,prompt,request)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	local card
	package_call(self,"sortByUseValue",cards,true)
	for _, c in ipairs(cards)  do
		if isCard("Slash", c, self.player) or package_known(c,"objectName"):endsWith("shoot") then
			card = c
			break
		end
	end
	if card then
		local use = dummy(false)
		if package_known(card,"isKindOf","Slash") then
			package_call(self,"useCardSlash",card, use)
		elseif package_known(self.player,"hasSkill","qianzhi") and package_known(card,"getClassName"):endsWith("Guard") then
			local qianzhi_slash = clone_native(self,"slash")
			package_call(qianzhi_slash,"addSubcard",card)
			package_call(qianzhi_slash,"setSkillName","qianzhi")
			card = qianzhi_slash
			package_call(self,"useCardSlash",card, use)
		elseif package_known(card,"objectName"):endsWith("shoot") then
			package_known(self,"useCardShoot",card, use)
		end
		if use.card and use.to then
			local targets = {}
			for _, p in sgs.qlist(use.to) do
				table.insert(targets, package_known(p,"objectName"))
			end
			return ("%s->%s"):format(package_known(card,"toString"), table.concat(targets, "+"))
		end
	end
	return "."
end

ai_skill_use["@@chaobing"]=function(self,prompt,request)
	local toObjName = package_known(prompt,"split",":")[2]
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"isKindOf","EquipCard") then
			return ("#chaobing:%d:->%s"):format(package_known(card,"getEffectiveId"), toObjName)
		end
	end

	local to = package_call(self.room,"findPlayerByObjectName",toObjName)
	if not package_known(self,"cantbeHurt",to) and package_known(self,"damageIsEffective",to) and package_known(self.player,"getHp") > package_known(to,"getHp") and package_known(self.player,"getHp") > 1 then
		return ("#chaobing:.:->%s"):format(toObjName)
	end
end

local qianzhi_skill={}
qianzhi_skill.name="qianzhi"
table.insert(package_skills,qianzhi_skill)
qianzhi_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)

	local handcard

	package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)  do
		if package_known(card,"getClassName"):endsWith("Guard") then
			handcard = card
			break
		end
	end

	if not handcard then return nil end
	local suit = package_known(handcard,"getSuitString")
	local number = package_known(handcard,"getNumberString")
	local card_id = package_known(handcard,"getEffectiveId")
	local card_str = ("slash:qianzhi[%s:%s]=%d"):format(suit, number, card_id)
	local slash = source_construct(self,card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.qianzhi = function(card, player, card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand and package_known(card,"getClassName"):endsWith("Guard") then
		return ("slash:qianzhi[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value["qianzhi"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["qianzhi"] = sgs.ai_use_priority.Slash

sgs.ai_ajustdamage_from.qianzhi = function(self,from,to,card,nature)
	if card and package_known(card,"isKindOf","Slash") and table.contains(package_known(card,"getSkillNames"), "qianzhi") and package_known(to,"isKongcheng")
	then return 1 end
end


local kyrios_transam_skill = {}
kyrios_transam_skill.name = "kyrios_transam"
table.insert(package_skills, kyrios_transam_skill)
kyrios_transam_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@kyrios_transam") > 0 then
		local card = clone_native(self,"shoot", sgs.Card_NoSuit, 0)
		local use = dummy(false)
		package_known(self,"useCardShoot",card, use)
		if use.card then
			local slashshoots = {"Slash", "Shoot", "PierceShoot", "SpreadShoot"}
			local n = package_known(self,"getCardsNum",slashshoots)
			package_call(self,"sort",self.enemies, "hp")
			if (n >= 2 and #self.enemies > 0 and not package_known(self.enemies[1],"isProhibited",self.enemies[1], card) and not package_known(self.enemies[1],"hasSkill","mosu")) or package_known(self.player,"getHp") == 1 then
				return source_construct(self,"#kyrios_transam:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#kyrios_transam"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["kyrios_transam"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["kyrios_transam"] = sgs.ai_use_priority.Analeptic


local hongjue_skill={}
hongjue_skill.name="hongjue"
table.insert(package_skills,hongjue_skill)
hongjue_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)

	local handcard, name

	package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)  do
		if package_known(card,"isKindOf","Slash") then
			local shoot = clone_native(self,"pierce_shoot", sgs.Card_NoSuit, 0)
			package_call(shoot,"addSubcard",package_known(card,"getEffectiveId"))
			package_call(shoot,"deleteLater")
			if package_known(shoot,"isAvailable",self.player) then
				handcard = card
				name = "pierce_shoot"
				break
			end
		elseif package_known(card,"isKindOf","Jink") then
			local analeptic = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
			package_call(analeptic,"addSubcard",package_known(card,"getEffectiveId"))
			package_call(analeptic,"deleteLater")
			if sgs.Analeptic_IsAvailable(self.player, analeptic) then
				handcard = card
				name = "analeptic"
				break
			end
		end
	end

	if not handcard then return nil end
	local suit = package_known(handcard,"getSuitString")
	local number = package_known(handcard,"getNumberString")
	local card_id = package_known(handcard,"getEffectiveId")
	local card_str = ("%s:hongjue[%s:%s]=%d"):format(name, suit, number, card_id)
	local acard = source_construct(self,card_str)
	assert(acard)

	return acard

end

sgs.ai_view_as.hongjue = function(card, player, card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand and package_known(card,"isKindOf","Jink") then
		return ("analeptic:hongjue[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value["hongjue"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["hongjue"] = sgs.ai_use_priority.Analeptic
sgs.ai_card_priority.hongjue = function(self,card,v)
	if package_known(card,"isKindOf","PierceShoot")
	then return 6 end
end
sgs.ai_ajustdamage_from.hongjue = function(self,from,to,card,nature)
	if card and package_known(card,"objectName"):endsWith("shoot") and foreign_fact(self,card,"drank","toInt") > 0
	then return foreign_fact(self,card,"drank","toInt") end
end

sgs.ai_skill_discard.liqiang = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	local index = 0
	local all_peaches = 0
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			all_peaches = all_peaches + 1
		end
	end
	if all_peaches >= 2 and package_known(self,"getOverflow") <= 0 then return {} end
	package_call(self,"sortByKeepValue",cards)
	cards = sgs.reverse(cards)

	for i = #cards, 1, -1 do
		local card = cards[i]
		if not isCard("Peach", card, self.player) and not package_known(card,"getClassName"):endsWith("Guard") and not package_known(self.player,"isJilei",card) then
			table.insert(to_discard, package_known(card,"getEffectiveId"))
			table.remove(cards, i)
			index = index + 1
			if index == discard_num then break end
		end
	end
	if #to_discard < discard_num then return {}
	else
		return to_discard
	end
end

local virtue_transam_skill = {}
virtue_transam_skill.name = "virtue_transam"
table.insert(package_skills, virtue_transam_skill)
virtue_transam_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@virtue_transam") > 0 then
		local card = clone_native(self,"shoot", sgs.Card_NoSuit, 0)
		package_call(card,"deleteLater")
		local use = dummy(false)
		package_known(self,"useCardShoot",card, use)
		if use.card then
			local shoots = {"Shoot", "PierceShoot", "SpreadShoot"}
			local n = package_known(self,"getCardsNum",shoots)
			if package_known(self.player,"hasSkill","hongjue") then
				n = n + package_known(self,"getCardsNum","Slash")
			end
			package_call(self,"sort",self.enemies, "hp")
			if (n >= 2 and #self.enemies > 0 and not package_known(self.enemies[1],"isProhibited",self.enemies[1], card) and not package_known(self.enemies[1],"hasSkill","mosu")) or package_known(self.player,"getHp") == 1 then
				return source_construct(self,"#virtue_transam:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#virtue_transam"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["virtue_transam"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["virtue_transam"] = sgs.ai_use_priority.Analeptic


sgs.ai_skill_invoke.gaoda_shenpan = function(self, data)
	return true
end

ai_skill_use["@@gaoda_shenpan"]=function(self,prompt,request)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"isKindOf","BasicCard") and (not isCard("Peach", card, self.player)) then
			local use = dummy(false)
			local acard = clone_native(self,"indulgence")
			package_call(acard,"addSubcard",package_known(card,"getEffectiveId"))
			package_call(acard,"setSkillName","gaoda_shenpan")
			package_known(self,"useCardIndulgence",acard, use)
			if use.card then
				if use.to then
					local targets = {}
					for _, p in sgs.qlist(use.to) do
						table.insert(targets, package_known(p,"objectName"))
					end
					return selected(self,use.card,targets)
				end
			end
		end
	end
end

function sgs.ai_cardneed.gaoda_shenpan(to, card)
	return package_known(card,"isKindOf","BasicCard")
end


local duzhan_skill={}
duzhan_skill.name="duzhan"
table.insert(package_skills,duzhan_skill)
duzhan_skill.getTurnUseCard=function(self,inclusive,request)
	for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if not package_known(p,"inMyAttackRange",self.player) then
			return false
		end
	end

	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)

	local handcard

	package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)  do
		if (not package_known(card,"isKindOf","Slash")) and (not isCard("Peach", card, self.player)) and (not isCard("ExNihilo", card, self.player)) then
			handcard = card
			break
		end
	end

	if not handcard then return nil end
	local suit = package_known(handcard,"getSuitString")
	local number = package_known(handcard,"getNumberString")
	local card_id = package_known(handcard,"getEffectiveId")
	local card_str = ("slash:duzhan[%s:%s]=%d"):format(suit, number, card_id)
	local slash = source_construct(self,card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.duzhan = function(card, player, card_place)
 local self=actor_ai(player)
	for _, p in sgs.qlist(package_known(player,"getRoom"):getOtherPlayers(player)) do
		if not package_known(p,"inMyAttackRange",player) then
			return false
		end
	end

	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceEquip then
		return ("jink:duzhan[%s:%s]=%d"):format(suit, number, card_id)
	else
		return ("slash:duzhan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value["duzhan"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["duzhan"] = sgs.ai_use_priority.Slash - 0.1


local jidong_skill = {}
jidong_skill.name = "jidong"
table.insert(package_skills, jidong_skill)
jidong_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"usedTimes","#jidong") >= 10 then return false end

	if (package_known(self.player,"getCardCount") > 2  and not package_known(self.player,"hasUsed","#jidong")) or package_known(self.player,"hasUsed","#reborns_transam") then
		if package_known(self.player,"getGeneralName") == "REBORNS_GUNDAM" and (package_known(self,"getCardsNum","FireSlash") + package_known(self,"getCardsNum","ThunderSlash")) == 0 then return false end
		if package_known(self.player,"getGeneralName") == "REBORNS_CANNON" and (package_known(self,"getCardsNum","FireSlash") + package_known(self,"getCardsNum","ThunderSlash")) > 0
			and (not package_known(self.player,"hasUsed","#fengong") or package_known(self.player,"hasUsed","#reborns_transam")) then return false end
		return source_construct(self,"#jidong:.:")
	end
end

sgs.ai_skill_use_func["#jidong"] = function(card,use,self,request)
	if package_known(self.player,"hasUsed","#reborns_transam") then
		use.card = source_construct(self,"#jidong:.:")
	else
		local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
		package_call(self,"sortByUseValue",cards, true)
		for _,card in ipairs(cards) do do
			if package_known(card,"isKindOf","Peach") or package_known(card,"isKindOf","ExNihilo") or package_known(card,"isKindOf","FireSlash") or package_known(card,"isKindOf","ThunderSlash") then goto package_continue_7 end
			use.card = source_construct(self,"#jidong:"..package_known(card,"getId")..":")
			return
		end ::package_continue_7:: end
	end
end

sgs.ai_use_value["jidong"] = sgs.ai_use_value.ExNihilo - 0.2
sgs.ai_use_priority["jidong"] = sgs.ai_use_priority.ExNihilo - 0.2

local fengong_skill = {}
fengong_skill.name = "fengong"
table.insert(package_skills, fengong_skill)
fengong_skill.getTurnUseCard = function(self,inclusive,request)
	if (package_known(self,"getCardsNum","FireSlash") > 0 or package_known(self,"getCardsNum","ThunderSlash") > 0)
		and (not package_known(self.player,"hasUsed","#fengong") or package_known(self.player,"hasUsed","#reborns_transam")) and #self.enemies > 0 then
		return source_construct(self,"#fengong:.:")
	end
end

sgs.ai_skill_use_func["#fengong"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "hp")
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	for _,card in ipairs(cards) do
		if package_known(card,"isKindOf","FireSlash") or package_known(card,"isKindOf","ThunderSlash") then
			use.card = source_construct(self,"#fengong:"..package_known(card,"getId")..":")
			if use.to then
				package_call(use.to,"append",self.enemies[1])
				if #self.enemies > 1 then
					package_call(use.to,"append",self.enemies[2])
				end
			end
			return
		end
	end
end

sgs.ai_use_value["fengong"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["fengong"] = sgs.ai_use_priority.Slash

local zaisheng_skill = {}
zaisheng_skill.name = "zaisheng"
table.insert(package_skills, zaisheng_skill)
zaisheng_skill.getTurnUseCard = function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#zaisheng") and not package_known(self.player,"isNude") then
		return source_construct(self,"#zaisheng:.:")
	end
end

sgs.ai_skill_use_func["#zaisheng"] = function(card,use,self,request)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))

	if package_known(self.player,"getHp") < 3 then
		local zcards = package_known(self.player,"getCards","he")
		local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
		local keep_slash = source_fact(self,"JilveWansha","toBool")
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = package_known(self,"aiUseCard",zcard, dummy())
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if package_known(p,"getHp") <= 1 then
									shouldUse = false
									if package_known(self.player,"distanceTo",p) > 1 then keep_weapon = package_call(self.player,"getWeapon") end
									break
								end
							end
							if package_known(dummy_use.to,"length") > 1 then shouldUse = false end
						end
						if not package_known(self,"isWeak") then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if package_known(zcard,"getTypeId") == sgs.Card_TypeTrick then
					local dummy_use = package_known(self,"aiUseCard",zcard, dummy())
					if dummy_use.card then shouldUse = false end
				end
				if package_known(zcard,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"hasEquip",zcard) then
					local dummy_use = package_known(self,"aiUseCard",zcard, dummy())
					if dummy_use.card then shouldUse = false end
					if keep_weapon and package_known(zcard,"getEffectiveId") == package_known(keep_weapon,"getEffectiveId") then shouldUse = false end
				end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","Armor") and not package_known(self,"needToThrowArmor") then shouldUse = false end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","DefensiveHorse") and not package_known(self,"needToThrowArmor") then shouldUse = false end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","WoodenOx") and package_known(self.player,"getPile","wooden_ox"):length() > 1 then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if package_known(self.player,"getHp") == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, package_known(zcard,"getId")) end
			end
		end
	end

	if #unpreferedCards == 0 then
		local use_slash_num = 0
		package_call(self,"sortByKeepValue",cards)
		for _, card in ipairs(cards) do
			if package_known(card,"isKindOf","Slash") then
				local will_use = false
				if use_slash_num <= correct_target(self,"Residue",card) then
					local dummy_use = package_known(self,"aiUseCard",card, dummy())
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, package_known(card,"getId")) end
			end
		end

		local num = package_known(self,"getCardsNum","Jink") - 1
		if package_call(self.player,"getArmor") then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if package_known(card,"isKindOf","Jink") and num > 0 then
					table.insert(unpreferedCards, package_known(card,"getId"))
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (package_known(card,"isKindOf","Weapon") and package_known(self.player,"getHandcardNum") < 3) or package_known(card,"isKindOf","OffensiveHorse")
				or package_known(self,"getSameEquip",card, self.player) or package_known(card,"isKindOf","AmazingGrace") then
				table.insert(unpreferedCards, package_known(card,"getId"))
			elseif package_known(card,"getTypeId") == sgs.Card_TypeTrick then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if not dummy_use.card then table.insert(unpreferedCards, package_known(card,"getId")) end
			end
		end

		if package_call(self.player,"getWeapon") and package_known(self.player,"getHandcardNum") < 3 then
			table.insert(unpreferedCards, package_call(self.player,"getWeapon"):getId())
		end

		if package_known(self,"needToThrowArmor") then
			table.insert(unpreferedCards, package_call(self.player,"getArmor"):getId())
		end

		if package_known(self.player,"getOffensiveHorse") and package_call(self.player,"getWeapon") then
			table.insert(unpreferedCards, package_known(self.player,"getOffensiveHorse"):getId())
		end
	end

	for index = #unpreferedCards, 1, -1 do
		if disclosed_card(self,unpreferedCards[index]):isKindOf("WoodenOx") and package_known(self.player,"getPile","wooden_ox"):length() > 1 then
			table.removeOne(unpreferedCards, unpreferedCards[index])
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		local card = disclosed_card(self,unpreferedCards[index])
		if not package_known(self.player,"isJilei",card) and not package_known(card,"isKindOf","FireSlash") and not package_known(card,"isKindOf","ThunderSlash") then
			table.insert(use_cards, unpreferedCards[index])
		end
	end

	if #use_cards > 0 then
		use.card = source_construct(self,"#zaisheng:"..table.concat(use_cards, "+")..":")
		return
	end
end

sgs.ai_use_value["zaisheng"] = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority["zaisheng"] = sgs.ai_use_priority.ZhihengCard
sgs.dynamic_value.benefit["zaisheng"] = true

local reborns_transam_skill = {}
reborns_transam_skill.name = "reborns_transam"
table.insert(package_skills, reborns_transam_skill)
reborns_transam_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@reborns_transam") > 0 and (package_known(self,"getCardsNum","FireSlash") + package_known(self,"getCardsNum","ThunderSlash")) > 1 and #self.enemies > 0 then
		return source_construct(self,"#reborns_transam:.:")
	end
end

sgs.ai_skill_use_func["#reborns_transam"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["reborns_transam"] = sgs.ai_use_value.ExNihilo + 0.2
sgs.ai_use_priority["reborns_transam"] = sgs.ai_use_priority.ExNihilo + 0.2
sgs.dynamic_value.benefit["reborns_transam"] = true


sgs.ai_view_as.feijian = function(card, player, card_place)
 local self=actor_ai(player)
	if package_known(player,"getPile","jian"):isEmpty() or package_known(player,"isNude") then return false end
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place ~= sgs.Player_PlaceSpecial and not package_known(card,"isKindOf","Peach") and not package_known(card,"hasFlag","using") then
		for _,id in sgs.qlist(package_known(player,"getPile","jian")) do
			if disclosed_card(self,id):getSuitString() == suit then
				return ("slash:feijian[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	end
end

local feijian_skill = {}
feijian_skill.name = "feijian"
table.insert(package_skills, feijian_skill)
feijian_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getPile","jian"):isEmpty() or package_known(self.player,"isNude") or not fact(self,"slash_available") then
		return false
	end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	for _,card in ipairs(cards) do
		local suit = package_known(card,"getSuitString")
		local number = package_known(card,"getNumberString")
		local card_id = package_known(card,"getEffectiveId")
		if not package_known(card,"isKindOf","Peach") and not package_known(card,"hasFlag","using") then
			for _,id in sgs.qlist(package_known(self.player,"getPile","jian")) do
				if disclosed_card(self,id):getSuitString() == suit then
					local slash_str = ("slash:feijian[%s:%s]=%d"):format(suit, number, card_id)
					local feijianslash = source_construct(self,slash_str)
					for _,enemy in ipairs(self.enemies) do
						if package_known(self.player,"canSlash",enemy, feijianslash) and package_known(self,"slashIsEffective",feijianslash, enemy) then
							assert(feijianslash)
							return feijianslash
						end
					end
				end
			end
		end
	end
end

sgs.ai_use_value["feijian"] = sgs.ai_use_value.Slash + 0.1
sgs.ai_use_priority["feijian"] = sgs.ai_use_priority.Slash + 0.1

local gaoda_liuyan_skill = {}
gaoda_liuyan_skill.name = "gaoda_liuyan"
table.insert(package_skills, gaoda_liuyan_skill)
gaoda_liuyan_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getPile","jian"):isEmpty() or package_known(self.player,"getStrategyMark","@MARUT") == 0 then
		return false
	end
	local spade, heart, club, diamond = 0, 0, 0, 0
	for _,i in sgs.qlist(package_known(self.player,"getPile","jian")) do
		local suits = disclosed_card(self,i):getSuitString()
		if suits == "spade" then
			spade = spade + 1
		elseif suits == "heart" then
			heart = heart + 1
		elseif suits == "club" then
			club = club + 1
		elseif suits == "diamond" then
			diamond = diamond + 1
		end
	end
	for _,id in sgs.qlist(package_known(self.player,"getPile","jian")) do
		local card = disclosed_card(self,id)
		local suit = package_known(card,"getSuitString")
		local number = package_known(card,"getNumberString")
		local card_id = package_known(card,"getEffectiveId")
		local peach = clone_native(self,"peach", package_known(card,"getSuit"), package_known(card,"getNumber"))
		local suit_no = math.max(spade, heart, club, diamond)
		if (suit_no == spade and suit == "spade") or (suit_no == heart and suit == "heart") or (suit_no == club and suit == "club")
			or (suit_no == diamond and suit == "diamond") then
			if package_known(peach,"isAvailable",self.player) then
				local peach_str = ("peach:gaoda_liuyan[%s:%s]=%d"):format(suit, number, card_id)
				local use = source_construct(self,peach_str)
				assert(use)
				return use
			end
		end
	end
end

sgs.ai_view_as.gaoda_liuyan = function(card, player, card_place)
 local self=actor_ai(player)
	if package_known(player,"getStrategyMark","@MARUT") == 0 or package_known(player,"getPile","jian"):isEmpty() then return false end
	local spade, heart, club, diamond = 0, 0, 0, 0
	for _,i in sgs.qlist(package_known(player,"getPile","jian")) do
		local suits = disclosed_card(self,i):getSuitString()
		if suits == "spade" then
			spade = spade + 1
		elseif suits == "heart" then
			heart = heart + 1
		elseif suits == "club" then
			club = club + 1
		elseif suits == "diamond" then
			diamond = diamond + 1
		end
	end
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	local suit_no = math.max(spade, heart, club, diamond)
	if (suit_no == spade and suit == "spade") or (suit_no == heart and suit == "heart") or (suit_no == club and suit == "club")
		or (suit_no == diamond and suit == "diamond") then
		if card_place == sgs.Player_PlaceSpecial and package_known(player,"getPileName",card_id) == "jian" and package_known(player,"getStrategyMark","Global_PreventPeach") == 0 then
			return ("peach:gaoda_liuyan[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_use_value["gaoda_liuyan"] = sgs.ai_use_value.Peach
sgs.ai_use_priority["gaoda_liuyan"] = sgs.ai_use_priority.Peach

local harute_transam_skill = {}
harute_transam_skill.name = "harute_transam"
table.insert(package_skills, harute_transam_skill)
harute_transam_skill.getTurnUseCard = function(self,inclusive,request)
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	local willUse = false
	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
			willUse = true
			break
		end
	end
	if package_known(self.player,"getStrategyMark","@harute_transam") > 0 and willUse then

		local n = 0
		local suits = {}
		for _,id in sgs.qlist(package_known(self.player,"getPile","jian")) do
			local suit = disclosed_card(self,id):getSuitString()
			if not table.contains(suits, suit) then
				table.insert(suits, suit)
			end
		end
		for _,card in sgs.qlist(package_known(self.player,"getCards","he")) do
			if (table.contains(suits, package_known(card,"getSuitString")) and not package_known(card,"isKindOf","Peach")) or package_known(card,"isKindOf","Slash")  then
				n = n + 1
			end
		end

		package_call(self,"sort",self.enemies, "hp")
		local card = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		local p = self.enemies[1]
		if n >= 3 and #self.enemies > 0 and not package_known(p,"isProhibited",p, card) and package_known(self,"slashIsEffective",card, p, self.player) and not package_known(p,"hasSkill","mosu") then
			return source_construct(self,"#harute_transam:.:")
		end
	end
end

sgs.ai_skill_use_func["#harute_transam"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["harute_transam"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["harute_transam"] = sgs.ai_use_priority.Analeptic


local ronghe_skill={}
ronghe_skill.name="ronghe"
table.insert(package_skills,ronghe_skill)
ronghe_skill.getTurnUseCard=function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#ronghe") then
		if #self.enemies == 0 and #self.friends_noself == 0 then return false end
		for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
			if not package_known(p,"isKongcheng") and package_known(p,"getHp") > package_known(self.player,"getHp") then
				local card_str = ("#ronghe:.:")
				return source_construct(self,card_str)
			end
		end
	end
end

sgs.ai_skill_use_func["#ronghe"]=function(card,use,self,request)


	local target = nil
	package_call(self,"sort",self.enemies, "handcard")
	for i = #self.enemies, 1, -1 do
		local enemy = self.enemies[i]
		if not package_known(enemy,"isKongcheng") and package_known(enemy,"getHp") > package_known(self.player,"getHp") then
			target = enemy
			break
		end
	end
	if target == nil then
		package_call(self,"sort",self.friends_noself, "handcard")
		for i = #self.friends_noself, 1, -1 do
			local friend = self.friends_noself[i]
			if not package_known(friend,"isKongcheng") and package_known(friend,"getHp") > package_known(self.player,"getHp") then
				target = friend
				break
			end
		end
	end
	if target ~= nil then
		use.card = card
		if use.to then
			package_call(use.to,"append",target)
		end
	end
end

sgs.ai_use_value["ronghe"] = 10
sgs.ai_use_priority["ronghe"] = 10









sgs.ai_skill_invoke.lijie = function(self, data)
	local damage = package_known(data,"toDamage")
	if package_known(self.player,"isWounded") then
		if package_known(self,"isFriend",damage.from) then
			if source_fact(self,"Dongchaer","toString") == package_known(self.player,"objectName")
				and source_fact(self,"Dongchaee","toString") == package_known(damage.from,"objectName") then
				for _,card in sgs.qlist(package_known(damage.from,"getHandcards")) do
					if package_known(card,"getSuit") == sgs.Card_Heart then
						return true
					end
				end
			end
		else
			return not (package_known(self.player,"getHp") > 1 and package_known(damage.from,"getHp") == 1)
		end
	end
	return false
end

sgs.ai_skill_cardchosen["lijie"] = function(self, who, flags)
	if source_fact(self,"Dongchaer","toString") == package_known(self.player,"objectName")
		and source_fact(self,"Dongchaee","toString") == package_known(who,"objectName") then
		for _,card in sgs.qlist(package_known(who,"getHandcards")) do
			if package_known(card,"getSuit") == sgs.Card_Heart then
				return card
			end
		end
	end
	return nil
end


sgs.ai_skill_invoke.quanren = function(self, data)
	local want_attack = false
	package_call(self,"sort",self.enemies, "defenseSlash")
	for _,enemy in ipairs(self.enemies) do
		if package_known(self.player,"canSlash",enemy) and not package_known(self,"slashProhibit",clone_native(self,"slash", sgs.Card_NoSuit, 0), enemy) then
			want_attack = true
			break
		end
	end
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	local willUse = false
	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
			willUse = true
			break
		end
	end
	if package_known(self.player,"hasSkill","fs_transam") and package_known(self.player,"getStrategyMark","@fs_transam") > 0 then
		return (willUse and package_known(self,"getCardsNum","Slash") >= 2) or (package_known(self,"getCardsNum","Slash") == 0 and want_attack)
	end
	return package_known(self,"getCardsNum","Slash") == 0 and want_attack
end

local quanren_skill={}
quanren_skill.name="quanren"
table.insert(package_skills,quanren_skill)
quanren_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)

	local list = source_property(self,"quanren"):toString():split("+")
	if #list == 0 then return false end

	local handcard

	package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)  do
		if (table.contains(list, tostring(package_known(card,"getEffectiveId")))) and (not package_known(card,"isKindOf","Slash")) and (not isCard("Peach", card, self.player)) and (not isCard("ExNihilo", card, self.player)) then
			handcard = card
			break
		end
	end

	if not handcard then return nil end
	local suit = package_known(handcard,"getSuitString")
	local number = package_known(handcard,"getNumberString")
	local card_id = package_known(handcard,"getEffectiveId")
	local card_str = ("slash:quanren[%s:%s]=%d"):format(suit, number, card_id)
	local slash = source_construct(self,card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.quanren = function(card, player, card_place)
 local self=actor_ai(player)
	local list = source_property(actor_ai(player),"quanren"):toString():split("+")
	if #list == 0 then return false end

	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand and table.contains(list, tostring(card_id)) then
		return ("slash:quanren[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value["quanren"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["quanren"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_choice.quanren = function(self, choices, data)
	choices = {"quanrenpile", "quanrenpile", "quanrenhand"}
	return choices[math.random(3)]
end

sgs.ai_skill_invoke.yueqian = function(self, data)
	return true
end

local fs_transam_skill = {}
fs_transam_skill.name = "fs_transam"
table.insert(package_skills, fs_transam_skill)
fs_transam_skill.getTurnUseCard = function(self,inclusive,request)
	local slash_count = 0
	for _,card in sgs.qlist(package_known(self.player,"getHandcards")) do
		if package_known(card,"isKindOf","Slash") then
			slash_count = slash_count + 1
		end
	end
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	local willUse = false
	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
			willUse = true
			break
		end
	end
	if package_known(self.player,"getStrategyMark","@fs_transam") > 0 and willUse and slash_count >= 2 then
		return source_construct(self,"#fs_transam:.:")
	end
end

sgs.ai_skill_use_func["#fs_transam"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["fs_transam"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["fs_transam"] = sgs.ai_use_priority.Slash + 0.05


sgs.ai_skill_invoke.jieneng = function(self, data)
	local use = package_known(data,"toCardUse")
	local jink_table = source_jink_numbers(self,use)
	local index = source_index_of(use.to,self.player) + 1
	return package_known(self.player,"getStrategyMark","@shineng") > 0 or package_known(self,"getCardsNum","Jink") == 0 or jink_table[index] == 0 or jink_table[index] > package_known(self,"getCardsNum","Jink")
end

local shineng_skill = {}
shineng_skill.name = "shineng"
table.insert(package_skills, shineng_skill)
shineng_skill.getTurnUseCard = function(self,inclusive,request)
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	local willUse = false
	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
			willUse = true
			break
		end
	end

	if package_known(self.player,"getStrategyMark","@shineng") > 0 and package_known(self.player,"getPile","neng"):length() > 1 and (willUse or package_known(self.player,"hasUsed","Slash") or package_known(self.player,"getMaxCards") <= 1) then
		return source_construct(self,"#shineng:.:")
	end
end

sgs.ai_skill_use_func["#shineng"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["shineng"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["shineng"] = sgs.ai_use_priority.Slash
sgs.dynamic_value.benefit["shineng"] = true

sgs.ai_skill_invoke.rg = function(self, data)
	return package_known(self.player,"getStrategyMark","@shineng") == 0
end

sgs.ai_ajustdamage_from.tiequan = function(self, from, to, card, nature)
	if card and package_known(card,"isKindOf","Slash")
	then
		return 1
	end
end



local dm_transam_skill = {}
dm_transam_skill.name = "dm_transam"
table.insert(package_skills, dm_transam_skill)
dm_transam_skill.getTurnUseCard = function(self,inclusive,request)
	local equips = package_known(self.player,"getEquips")
	local installed, unlimited = true, false
	if (package_known(self,"getCardsNum","Weapon") > 0 and package_call(self.player,"getWeapon") == nil)
		or (package_known(self,"getCardsNum","Armor") > 0 and package_call(self.player,"getArmor") == nil)
		or (package_known(self,"getCardsNum","DefensiveHorse") > 0 and package_known(self.player,"getDefensiveHorse") == nil)
		or (package_known(self,"getCardsNum","OffensiveHorse") > 0 and package_known(self.player,"getOffensiveHorse") == nil)
		or (package_known(self,"getCardsNum","Treasure") > 0 and package_known(self.player,"getTreasure") == nil) then
		installed = false
	end
	if package_call(self.player,"getWeapon") and package_call(self.player,"getWeapon"):getClassName() == "Crossbow" then
		unlimited = true
	end
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	local willUse = false
	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
			willUse = true
			break
		end
	end
	if package_known(self.player,"getStrategyMark","@dm_transam") > 0 and package_known(equips,"length") > 0 and installed
		and ((willUse and (not unlimited) and package_known(self,"getCardsNum","Slash") > (2 - math.floor(package_known(equips,"length") / 2)))
		or (package_known(self.player,"getHp") <= 1 and package_known(self.player,"getHandcardNum") <= 1)) then
		local ids = {}
		for _,card in sgs.qlist(equips) do
			table.insert(ids, package_known(card,"getId"))
		end
		return source_construct(self,"#dm_transam:"..(table.concat(ids, "+"))..":")
	end
end

sgs.ai_skill_use_func["#dm_transam"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["dm_transam"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["dm_transam"] = sgs.ai_use_priority.Slash + 0.05

sgs.ai_ajustdamage_to.gaoda_mingren = function(self, from, to, card, nature)
	if card and package_known(card,"isKindOf","Duel")
	then
		return -99
	end
end
sgs.ai_ajustdamage_from.gaoda_binghuo = function(self, from, to, card, nature)
	if card and package_known(card,"isKindOf","FireSlash") and package_known(to,"getStrategyMark","@ice") > 0 then
		return 1
	end
end



ai_skill_use["@@ciyuanbawangliu"]=function(self,prompt,request)
	local use = source_fact(self,"ciyuanbawangliu","toCardUse")
	if use.card and table.contains(package_known(use.card,"getSkillNames"), "shengfeng") then return "." end
	local quanfa = package_known(self.player,"getPile","quanfa")
	for _,p in sgs.qlist(use.to) do
		for _,id in sgs.qlist(quanfa) do
			local qcard = disclosed_card(self,id)
			local name = package_known(qcard,"objectName")
			if package_known(self.player,"getStrategyMark","@gaoda_tonghua") > 0 and package_known(qcard,"isRed") then
				name = "fire_slash"
			end
			local acard = clone_native(self,name, package_known(use.card,"getSuit"), package_known(use.card,"getNumber"))
			package_call(acard,"addSubcard",use.card)

			if (package_known(use.card,"isKindOf","Dismantlement") or package_known(use.card,"isKindOf","Snatch")) and (package_call(p,"getArmor") or package_known(p,"getDefensiveHorse")) then
				return "."
			end

			local effective = (package_known(acard,"isKindOf","Slash") and package_known(self,"slashIsEffective",acard, p, self.player))
								or (package_known(acard,"isKindOf","TrickCard") and package_known(self,"hasTrickEffective",acard, p, self.player))

			if package_known(self.player,"getStrategyMark","@gaoda_tonghua") == 0 then
				if package_known(use.card,"isKindOf","Slash") then
					if package_known(use.card,"hasFlag","drank") then
						if package_known(qcard,"isBlack") and package_known(qcard,"isKindOf","Slash") and package_known(self,"slashIsEffective",acard, p, self.player) then
							return ("#ciyuanbawangliu:" .. id .. ":")
						end
					else
						if package_known(qcard,"isBlack") and effective then
							return ("#ciyuanbawangliu:" .. id .. ":")
						end
					end
				else
					if package_known(qcard,"isBlack") and effective then
						return ("#ciyuanbawangliu:" .. id .. ":")
					end
				end
			else
				if package_known(use.card,"isKindOf","Slash") then
					if package_known(qcard,"isKindOf","TrickCard") and effective then
						return ("#ciyuanbawangliu:" .. id .. ":")
					end
				else
					if effective then
						return ("#ciyuanbawangliu:" .. id .. ":")
					end
				end
			end
		end
	end
	return "."
end


local hongbao_skill = {}
hongbao_skill.name = "hongbao"
table.insert(package_skills,hongbao_skill)
hongbao_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@hongbao") > 0 and package_known(self.player,"isWounded") and package_known(self,"getSuitNum","red", false, self.player) > 0 and package_known(self.player,"getPile","quanfa"):length() > 1 then
		local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		package_call(self,"sortByUseValue",cards,true)
		for _,card in ipairs(cards) do
			if package_known(card,"isRed") and (not package_known(card,"isKindOf","ExNihilo")) then
				local card_str = ("#hongbao:"..package_known(card,"getId")..":")
				return source_construct(self,card_str)
			end
		end
	end
end

sgs.ai_skill_use_func["#hongbao"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value["hongbao"] = sgs.ai_use_value.ExNihilo
sgs.ai_use_priority["hongbao"] = sgs.ai_use_value.ExNihilo - 0.5

local shengfeng_skill = {}
shengfeng_skill.name = "shengfeng"
table.insert(package_skills, shengfeng_skill)
shengfeng_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getPile","quanfa"):isEmpty() or package_known(self.player,"hasUsed","#shengfeng") then return false end

	local fire_attack = clone_native(self,"fire_attack", sgs.Card_SuitToBeDecided, -1)
	package_call(fire_attack,"setSkillName","shengfeng")

	for _,id in sgs.qlist(package_known(self.player,"getPile","quanfa")) do
		local new_suit = true
		for _,i in sgs.qlist(package_known(fire_attack,"getSubcards")) do
			if disclosed_card(self,id):getSuit() == disclosed_card(self,i):getSuit() then
				new_suit = false
				break
			end
		end
		if new_suit then
			package_call(fire_attack,"addSubcard",id)
		end
	end

	if package_known(fire_attack,"subcardsLength") < 2 then return false end

	for _,enemy in ipairs(self.enemies) do
		if package_known(self,"hasTrickEffective",fire_attack, enemy, self.player) then
			return fire_attack
		end
	end
end

sgs.ai_use_value["shengfeng"] = sgs.ai_use_value.FireAttack + 0.5
sgs.ai_use_priority["shengfeng"] = sgs.ai_use_value.FireAttack + 0.5


sgs.ai_skill_invoke["#G_SELF_skill"] = function(self, data)
	return true
end

sgs.ai_view_as.huanse = function(card, player, card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if package_known(player,"getStrategyMark","G_SELF_SPACE") > 0 and card_place == sgs.Player_PlaceHand then
		if package_known(card,"isKindOf","Jink") then
			return ("nullification:G_SELF_SPACE_skill[%s:%s]=%d"):format(suit, number, card_id)
		elseif package_known(card,"isKindOf","Nullification") then
			return ("jink:G_SELF_SPACE_skill[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_skill_invoke["#G_SELF_HT_skill"] = function(self, data)
	local target = source_fact(self,"G_SELF_HT_skill","toPlayer")
	return package_known(self,"isEnemy",target)
end

sgs.ai_ajustdamage_from.huanse = function(self, from, to, card, nature)
	if package_known(from,"getStrategyMark","G_SELF_ASS") > 0 and card and package_known(card,"isRed") and not package_known(card,"isKindOf","SkillCard") then
		return 1
	end
end


local huancai_skill = {}
huancai_skill.name = "huancai"
table.insert(package_skills, huancai_skill)
huancai_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","huancai") then return false end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	for _,card in ipairs(cards) do
		if not package_known(card,"isKindOf","ExNihilo") and not (package_known(self.player,"isWounded") and package_known(card,"isKindOf","Peach")) and not (package_known(self,"getCardsNum","Jink") == 1 and package_known(card,"isKindOf","Jink")) then
			local suit = package_known(card,"getSuitString")
			local number = package_known(card,"getNumberString")
			local card_id = package_known(card,"getEffectiveId")
			local card_str = ("ex_nihilo:huancai[%s:%s]=%d"):format(suit, number, card_id)
			return source_construct(self,card_str)
		end
	end
end

sgs.ai_use_value["huancai"] = sgs.ai_use_value.ExNihilo + 1
sgs.ai_use_priority["huancai"] = sgs.ai_use_priority.Slash + 0.5

sgs.ai_view_as.huancai = function(card, player, card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if package_known(player,"getStrategyMark","G_SELF_SPACE") > 0 and card_place == sgs.Player_PlaceHand then
		if package_known(card,"isKindOf","Jink") then
			return ("nullification:G_SELF_SPACE_skill[%s:%s]=%d"):format(suit, number, card_id)
		elseif package_known(card,"isKindOf","Nullification") then
			return ("jink:G_SELF_SPACE_skill[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end
sgs.ai_ajustdamage_from.huancai = function(self, from, to, card, nature)
	if package_known(from,"getStrategyMark","G_SELF_ASS") > 0 and card and package_known(card,"isRed") and not package_known(card,"isKindOf","SkillCard") then
		return 1
	end
end


sgs.ai_skill_invoke.tiexue = function(self, data)
	return true
end

sgs.ai_skill_choice.tiexue = function(self, choices, data)

	if sgs.ai_skill_invoke.nosluoyi(self, data) then
		return "tiexuebuff"
	end
	return "tiexuedraw"
end

function sgs.ai_cardneed.tiexue(to, card, self)
	return sgs.ai_cardneed.nosluoyi(to, card, self)
end

sgs.ai_ajustdamage_from.tiexue = function(self, from, to, card, nature)
	if card and (package_known(card,"isKindOf","Slash") or package_known(card,"isKindOf","Duel")) and package_known(from,"getStrategyMark","tiexue") > 0 then
		return package_known(from,"getLostHp")
	end
end

sgs.ai_getBestHp_skill.tiexue = function(owner)
	return package_known(owner,"getMaxHp") - 1
end



sgs.ai_skill_invoke.tianlang = function(self, data)
	return sgs.ai_skill_invoke.kunfen(self, data)
end

sgs.tianlang_suit_value = {
	spade = 3.9,
	club = 3.9
}

sgs.ai_skill_cardask["@@tianlang"] = function(self, data, pattern)
    local use = package_known(data,"toCardUse")
	for _, p in sgs.qlist(use.to) do
		if package_known(self,"isFriend",p) then
			return "."
		end
	end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do
		if match_pattern(self,self.player,pattern,h)
		then return package_known(h,"getEffectiveId") end
		if package_known(h,"isKindOf",pattern)
		then return package_known(h,"getEffectiveId") end
	end
    return "."
end


sgs.ai_skill_invoke.diwang = function(self, data)
	local x = package_known(data,"toString")
	if x and package_known(x,"startsWith","draw") then
		x = tonumber(package_known(x,"split",":")[2])
		if x < 2 then
			local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
			local willUse = false
			for _,c in sgs.list(cards)do
				if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
					willUse = true
					break
				end
			end
			return willUse and not package_known(self,"isWeak",self.player)
		else
			return true
		end
	else
		local damage = package_known(data,"toDamage")
		if package_known(self,"isEnemy",damage.to) then
			if package_known(damage.to,"isChained") and #self.enemies > 1 then
				for _, friend in pairs(self.friends) do
					if package_known(friend,"isChained") then
						return false
					end
				end
			end
			return true
		end
	end
end
sgs.ai_ajustdamage_from.diwang = function(self, from, to, card, nature)
	if package_known(from,"getHandcardNum") > package_known(to,"getHandcardNum") and card and (package_known(card,"isKindOf","Slash") or package_known(card,"isKindOf","Duel")) then
		return 1
	end
end



sgs.ai_skill_cardask["@@liangjian"] = function(self, data, pattern)
    local use = package_known(data,"toCardUse")
	for _, p in sgs.qlist(use.to) do
		if package_known(self,"isFriend",p) then
			return "."
		end
	end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do
		if match_pattern(self,self.player,pattern,h)
		then return package_known(h,"getEffectiveId") end
		if package_known(h,"isKindOf",pattern)
		then return package_known(h,"getEffectiveId") end
	end
    return "."
end

local liangjian_skill={}
liangjian_skill.name="liangjian"
table.insert(package_skills,liangjian_skill)
liangjian_skill.getTurnUseCard=function(self,inclusive,request)
	for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if not package_known(self.player,"inMyAttackRange",p) then
			return false
		end
	end

	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)

	local handcard

	package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)  do
		if (package_known(card,"getNumber") == 1 or package_known(card,"getNumber") == 7 or package_known(card,"getNumber") == 13) and
			(not package_known(card,"isKindOf","Slash")) and (not package_known(card,"isKindOf","Duel")) and (not isCard("Peach", card, self.player)) and (not isCard("ExNihilo", card, self.player)) then
			handcard = card
			break
		end
	end

	if not handcard then return nil end
	local suit = package_known(handcard,"getSuitString")
	local number = package_known(handcard,"getNumberString")
	local card_id = package_known(handcard,"getEffectiveId")
	local card_str = ("slash:liangjian[%s:%s]=%d"):format(suit, number, card_id)
	local slash = source_construct(self,card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.liangjian = function(card, player, card_place)
 local self=actor_ai(player)
	for _, p in sgs.qlist(package_known(player,"getRoom"):getOtherPlayers(player)) do
		if not package_known(player,"inMyAttackRange",p) then
			return false
		end
	end

	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand and (package_known(card,"getNumber") == 1 or package_known(card,"getNumber") == 7 or package_known(card,"getNumber") == 13) then
		return ("slash:liangjian[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value["liangjian"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["liangjian"] = sgs.ai_use_priority.Slash

function sgs.ai_cardneed.liangjian(to, card)
	return package_known(card,"isKindOf","Slash") or package_known(card,"isKindOf","Jink") or package_known(card,"isKindOf","Weapon") or package_known(card,"isKindOf","OffensiveHorse")
		or (package_known(card,"getNumber") == 1 or package_known(card,"getNumber") == 7 or package_known(card,"getNumber") == 13)
end

sgs.liangjian_keep_value = {
	Slash = 5.4,
	ThunderSlash = 5.5,
	FireSlash = 5.6,
	Duel = 5.6,
	Jink = 5.7,
	Guard = 5.7,
	CounterGuard = 5.8,
	Weapon = 4.9,
	OffensiveHorse = 4.8
}

sgs.ai_skill_invoke.haojiao = function(self, data)
	return true
end

sgs.ai_skill_cardask["@@haojiao"] = function(self, data)
	local from = package_call(self.room,"getCurrent")
	if package_known(self,"isFriend",from) then
		local target, cardid = sgs.ai_skill_askforyiji.nosyiji(self, package_known(self.player,"handCards"))
		return cardid
	end
	return "."
end


local yingxin_skill = {}
yingxin_skill.name = "yingxin"
table.insert(package_skills, yingxin_skill)
yingxin_skill.getTurnUseCard = function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#yingxin") and not package_known(self.player,"isNude") then
		return source_construct(self,"#yingxin:.:")
	end
end

sgs.ai_skill_use_func["#yingxin"] = function(card,use,self,request)
	local unpreferedCards = {}
	local cards = {}
	for _, card in sgs.qlist(package_known(self.player,"getCards","he")) do
		if package_known(card,"isBlack") then
			table.insert(cards, card)
		end
	end

	if package_known(self.player,"getHp") < 3 then
		local zcards = package_known(self.player,"getCards","he")
		local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
		local keep_slash = source_fact(self,"JilveWansha","toBool")
		for _, zcard in sgs.qlist(zcards) do do
			if not package_known(zcard,"isBlack") then goto package_continue_8 end
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = package_known(self,"aiUseCard",zcard, dummy())
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if package_known(p,"getHp") <= 1 then
									shouldUse = false
									if package_known(self.player,"distanceTo",p) > 1 then keep_weapon = package_call(self.player,"getWeapon") end
									break
								end
							end
							if package_known(dummy_use.to,"length") > 1 then shouldUse = false end
						end
						if not package_known(self,"isWeak") then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if package_known(zcard,"getTypeId") == sgs.Card_TypeTrick then
					local dummy_use = package_known(self,"aiUseCard",zcard, dummy())
					if dummy_use.card then shouldUse = false end
				end
				if package_known(zcard,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"hasEquip",zcard) then
					local dummy_use = package_known(self,"aiUseCard",zcard, dummy())
					if dummy_use.card then shouldUse = false end
					if keep_weapon and package_known(zcard,"getEffectiveId") == package_known(keep_weapon,"getEffectiveId") then shouldUse = false end
				end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","Armor") and not package_known(self,"needToThrowArmor") then shouldUse = false end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","DefensiveHorse") and not package_known(self,"needToThrowArmor") then shouldUse = false end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","WoodenOx") and package_known(self.player,"getPile","wooden_ox"):length() > 1 then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if package_known(self.player,"getHp") == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, package_known(zcard,"getId")) end
			end
		end ::package_continue_8:: end
	end

	if #unpreferedCards == 0 then
		local use_slash_num = 0
		package_call(self,"sortByKeepValue",cards)
		for _, card in ipairs(cards) do
			if package_known(card,"isKindOf","Slash") then
				local will_use = false
				if use_slash_num <= correct_target(self,"Residue",card) then
					local dummy_use = package_known(self,"aiUseCard",card, dummy())
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, package_known(card,"getId")) end
			end
		end

		local num = package_known(self,"getCardsNum","Jink") - 1
		if package_call(self.player,"getArmor") then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if package_known(card,"isKindOf","Jink") and num > 0 then
					table.insert(unpreferedCards, package_known(card,"getId"))
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (package_known(card,"isKindOf","Weapon") and package_known(self.player,"getHandcardNum") < 3) or package_known(card,"isKindOf","OffensiveHorse")
				or package_known(self,"getSameEquip",card, self.player) or package_known(card,"isKindOf","AmazingGrace") then
				table.insert(unpreferedCards, package_known(card,"getId"))
			elseif package_known(card,"getTypeId") == sgs.Card_TypeTrick then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if not dummy_use.card then table.insert(unpreferedCards, package_known(card,"getId")) end
			end
		end

		if package_call(self.player,"getWeapon") and package_known(self.player,"getHandcardNum") < 3 then
			table.insert(unpreferedCards, package_call(self.player,"getWeapon"):getId())
		end

		if package_known(self,"needToThrowArmor") then
			table.insert(unpreferedCards, package_call(self.player,"getArmor"):getId())
		end

		if package_known(self.player,"getOffensiveHorse") and package_call(self.player,"getWeapon") then
			table.insert(unpreferedCards, package_known(self.player,"getOffensiveHorse"):getId())
		end
	end

	for index = #unpreferedCards, 1, -1 do
		if disclosed_card(self,unpreferedCards[index]):isKindOf("WoodenOx") and package_known(self.player,"getPile","wooden_ox"):length() > 1 then
			table.removeOne(unpreferedCards, unpreferedCards[index])
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not package_known(self.player,"isJilei",disclosed_card(self,unpreferedCards[index])) then table.insert(use_cards, unpreferedCards[index]) end
	end

	if #use_cards > 0 then
		use.card = source_construct(self,"#yingxin:"..table.concat(use_cards, "+")..":")
		return
	end
end

sgs.ai_use_value["yingxin"] = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority["yingxin"] = sgs.ai_use_priority.ZhihengCard
sgs.dynamic_value.benefit["yingxin"] = true

local redpacket_skill = {}
redpacket_skill.name = "redpacket"
table.insert(package_skills, redpacket_skill)
redpacket_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"isKongcheng") then return end

	if package_known(self,"shouldUseRende") then
		return source_construct(self,"#redpacket:.:")
	end
end

sgs.ai_skill_use_func["#redpacket"] = function(card,use,self,request)
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))

	if #cards > math.ceil(package_known(self.player,"getHp") / 2) then
		package_call(self,"sortByUseValue",cards, true)
		package_call(self,"sort",self.friends_noself, "hp")
		local needCard, needFriend = package_call(self,"getCardNeedPlayer",cards)
		for _, friend in ipairs(self.friends_noself) do
			if package_known(friend,"getPile","redpacket"):isEmpty() then
				for _, card in ipairs(cards) do
					if package_known(card,"isRed") and (package_known(friend,"isWounded") or (needCard and package_known(needCard,"getId") == package_known(card,"getId") and needFriend and package_known(friend,"objectName") == package_known(needFriend,"objectName"))) then
						use.card = source_construct(self,"#redpacket:" .. package_known(card,"getId") .. ":")
						if use.to then package_call(use.to,"append",friend) end
						return
					end
				end
			end
		end

		package_call(self,"sortByUseValue",cards, false)
		package_call(self,"sort",self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if package_known(enemy,"getPile","redpacket"):isEmpty() then
				for _, card in ipairs(cards) do
					if package_known(card,"isBlack") then
						use.card = source_construct(self,"#redpacket:" .. package_known(card,"getId") .. ":")
						if use.to then package_call(use.to,"append",enemy) end
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_value["redpacket"] = sgs.ai_use_value.RendeCard
sgs.ai_use_priority["redpacket"] = sgs.ai_use_priority["yingxin"] - 0.2


local songli_skill = {}
songli_skill.name = "songli"
table.insert(package_skills, songli_skill)
songli_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"isKongcheng") then return end

	if package_known(self,"shouldUseRende") then
		return source_construct(self,"#songli:.:")
	end
end

sgs.ai_skill_use_func["#songli"] = function(card,use,self,request)
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards, true)

	for i = 1, package_known(self.player,"getHandcardNum") do do
		local card, friend = package_call(self,"getCardNeedPlayer",cards)
		if card and friend then
			cards = package_known(self,"resetCards",cards, card)
		else
			break
		end

		if package_known(friend,"objectName") == package_known(self.player,"objectName") or not package_known(self.player,"getHandcards"):contains(card) then goto package_continue_9 end
		local canJijiang = package_known(self.player,"hasLordSkill","jijiang") and package_known(friend,"getKingdom") == "shu"
		if package_known(card,"isAvailable",self.player) and ((package_known(card,"isKindOf","Slash") and not canJijiang) or package_known(card,"isKindOf","Duel") or package_known(card,"isKindOf","Snatch") or package_known(card,"isKindOf","Dismantlement")) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			local cardtype = package_known(card,"getTypeId")
			self["use" .. sgs.ai_type_name[cardtype + 1] .. "Card"](self, card, dummy_use)
			if dummy_use.card and package_known(dummy_use.to,"length") > 0 then
				if package_known(card,"isKindOf","Slash") or package_known(card,"isKindOf","Duel") then
					local t1 = package_known(dummy_use.to,"first")
					if package_known(dummy_use.to,"length") > 1 then goto package_continue_9
					elseif package_known(t1,"getHp") == 1 or getCardsNum("Jink", t1, self.player) < 1
							or package_known(t1,"isCardLimited",clone_native(self,"jink"), sgs.Card_MethodResponse) then goto package_continue_9
					end
				elseif (package_known(card,"isKindOf","Snatch") or package_known(card,"isKindOf","Dismantlement")) and package_known(self,"getEnemyNumBySeat",self.player, friend) > 0 then
					local hasDelayedTrick
					for _, p in sgs.qlist(dummy_use.to) do
						if package_known(self,"isFriend",p) and (package_known(self,"willSkipDrawPhase",p) or package_known(self,"willSkipPlayPhase",p)) then hasDelayedTrick = true break end
					end
					if hasDelayedTrick then goto package_continue_9 end
				end
			end
		elseif package_known(card,"isAvailable",self.player) and package_known(self,"getEnemyNumBySeat",self.player, friend) > 0 and (package_known(card,"isKindOf","Indulgence") or package_known(card,"isKindOf","SupplyShortage")) then
			local dummy_use = { isDummy = true }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then goto package_continue_9 end
		end

		if package_known(friend,"hasSkill","enyuan") and #cards >= 1 then
			use.card = source_construct(self,"#songli:" .. package_known(card,"getId") .. "+" .. package_known(cards[1],"getId") .. ":")
		else
			use.card = source_construct(self,"#songli:" .. package_known(card,"getId") .. ":")
		end
		if use.to then package_call(use.to,"append",friend) end
		return
	end ::package_continue_9:: end
end

sgs.ai_use_value["songli"] = sgs.ai_use_value.RendeCard
sgs.ai_use_priority["songli"] = sgs.ai_use_priority.RendeCard

sgs.ai_card_intention["songli"] = sgs.ai_card_intention.RendeCard

sgs.dynamic_value.benefit["songli"] = true

local gaoda_zhufu_skill={}
gaoda_zhufu_skill.name = "gaoda_zhufu"
table.insert(package_skills,gaoda_zhufu_skill)
gaoda_zhufu_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getHandcardNum") < 2 then return nil end
	if package_known(self.player,"hasUsed","#gaoda_zhufu") then return nil end
	if package_known(self,"needBear") and not package_known(self.player,"isWounded") and package_known(self,"isWeak") then return nil end

	local cards = package_known(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)

	local first, second
	package_call(self,"sortByUseValue",cards, true)
	for _, card in ipairs(cards) do
		if package_known(card,"isKindOf","TrickCard") then
			local dummy_use = {isDummy = true}
			package_call(self,"useTrickCard",card, dummy_use)
			if not dummy_use.card then
				if not first then first = package_known(card,"getEffectiveId")
				elseif first and not second then second = package_known(card,"getEffectiveId")
				end
			end
			if first and second then break end
		end
	end

	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") ~= sgs.Card_TypeEquip and (not package_known(self,"isValuableCard",card) or package_known(self.player,"isWounded")) then
			if not first then first = package_known(card,"getEffectiveId")
			elseif first and first ~= package_known(card,"getEffectiveId") and not second then second = package_known(card,"getEffectiveId")
			end
		end
		if first and second then break end
	end

	if not second or not first then return end
	local card_str = ("#gaoda_zhufu:%d+%d:"):format(first, second)
	assert(card_str)
	return source_construct(self,card_str)
end

sgs.ai_skill_use_func["#gaoda_zhufu"] = function(card,use,self,request)
	local arr1, arr2 = package_call(self,"getWoundedFriend",false)
	local target = nil

	repeat
		if #arr1 > 0 and (package_known(self,"isWeak",arr1[1]) or package_known(self,"isWeak") or package_known(self,"getOverflow") >= 1) then
			target = arr1[1]
			break
		end
		if #arr2 > 0 and package_known(self,"isWeak") then
			target = arr2[1]
			break
		end
	until true

	if not target and package_known(self,"isWeak") and package_known(self,"getOverflow") >= 2 and (self.role == "lord" or self.role == "renegade") then
		local others = package_known(self.room,"getOtherPlayers",self.player)
		for _, other in sgs.qlist(others) do
			if package_known(other,"isWounded") and package_known(other,"isMale") then
				if not package_known(self,"hasSkills",sgs.masochism_skill, other) then
					target = other
					package_call(self,"setStrategyPlayerFlag",self.player,"jieyin_isenemy_"..package_known(other,"objectName"),true)
					break
				end
			end
		end
	end

	if target then
		use.card = card
		if use.to then package_call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_priority["gaoda_zhufu"] = sgs.ai_use_priority.JieyinCard

sgs.ai_card_intention["gaoda_zhufu"] = function(self, card, from, tos)
	if not package_known(from,"getStrategyFlag","jieyin_isenemy_"..package_known(tos[1],"objectName")) then
		sgs.updateIntention(from, tos[1], -80)
	end
end

sgs.dynamic_value.benefit["gaoda_zhufu"] = true

local jingxi_skill = {}
jingxi_skill.name = "jingxi"
table.insert(package_skills, jingxi_skill)
jingxi_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","jingxi") then return false end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	for _,card in ipairs(cards) do
		if package_known(card,"getSuit") == sgs.Card_Heart and not package_known(card,"isKindOf","ExNihilo") and not package_known(card,"isKindOf","AmazingGrace") and not package_known(card,"isKindOf","Peach") and not (package_known(self,"getCardsNum","Jink") == 1 and package_known(card,"isKindOf","Jink")) then
			local suit = package_known(card,"getSuitString")
			local number = package_known(card,"getNumberString")
			local card_id = package_known(card,"getEffectiveId")
			local card_str = ("amazing_grace:jingxi[%s:%s]=%d"):format(suit, number, card_id)
			return source_construct(self,card_str)
		end
	end
end


local canguang_skill = {}
canguang_skill.name = "canguang"
table.insert(package_skills, canguang_skill)
canguang_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@HITO") >= 100 and package_known(self.player,"getStrategyMark","@HITO") < 666 then return false end
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)

	local has_anal = false
	for _,card in ipairs(cards)  do
		if package_known(card,"isRed") and not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
			has_anal = true
			break
		end
	end

	if not has_anal or not sgs.Analeptic_IsAvailable(self.player) then
		local newcard
		for _, card in ipairs(cards) do
			if package_known(card,"isBlack") and (not package_known(card,"hasFlag","using")) then
				newcard = card
				break
			end
		end
		if not newcard then return end

		local card_id1 = package_known(newcard,"getEffectiveId")

		local name = "slash"
		if package_known(self.player,"getStrategyMark","@HITO") == 666 then
			name = "fire_slash"
		end

		local scard = disclosed_card(self,card_id1)
		local card_str = ("%s:canguang[%s:%s]=%d"):format(name, package_known(scard,"getSuitString"), package_known(scard,"getNumberString"), card_id1)
		local slash = source_construct(self,card_str)
		return slash
	elseif package_known(self.player,"getStrategyMark","@HITO") == 666 then
		local acard
		for _,card in ipairs(cards)  do
			if package_known(card,"isRed") and not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player)
				and not (isCard("Slash", card, self.player) and package_known(self,"getCardsNum","Slash") == 1)
				and not (isCard("Jink", card, self.player) and package_known(self,"getCardsNum","Jink") == 1) then
				acard = card
				break
			end
		end

		if not acard then return nil end
		local card_str = ("ex_nihilo:canguang[%s:%s]=%d"):format(package_known(acard,"getSuitString"), package_known(acard,"getNumberString"), package_known(acard,"getEffectiveId"))

		local analeptic = source_construct(self,card_str)
		local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		local willUse = false
		for _,c in sgs.list(cards)do
			if package_known(c,"isKindOf","Slash") and package_known(self,"willUse",self.player,c) then
				willUse = true
				break
			end
		end

		if sgs.Analeptic_IsAvailable(self.player, analeptic)
			and package_known(self.player,"usedTimes","Analeptic") < 1 + correct_target(self,"Residue",analeptic)
			and willUse then
			assert(analeptic)
			return analeptic
		end
	end
end

sgs.ai_use_value["canguang"] = sgs.ai_use_value.Analeptic
sgs.ai_use_priority["canguang"] = sgs.ai_use_priority.Analeptic - 0.1

sgs.ai_view_as.canguang = function(card, player, card_place)
 local self=actor_ai(player)
	if package_known(player,"getStrategyMark","@HITO") >= 100 and package_known(player,"getStrategyMark","@HITO") < 666 then return false end

	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand then
		local pattern -- source unused ambient read omitted; next statement overwrites it
		if pattern == "slash" and package_known(card,"isBlack") then
			if package_known(player,"getStrategyMark","@HITO") == 666 then
				return ("fire_slash:canguang[%s:%s]=%d"):format(suit, number, card_id)
			else
				return ("slash:canguang[%s:%s]=%d"):format(suit, number, card_id)
			end
		elseif package_known(card,"isRed") and not package_known(card,"isKindOf","Peach") then
			if package_known(player,"getStrategyMark","@HITO") < 100 and pattern == "jink" then
				return ("jink:canguang[%s:%s]=%d"):format(suit, number, card_id)
			elseif package_known(player,"getStrategyMark","@HITO") == 666 and string.find(pattern, "analeptic") then
				return ("analeptic:canguang[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	end
end

local qiefu_skill = {}
qiefu_skill.name = "qiefu"
table.insert(package_skills, qiefu_skill)
qiefu_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@VVV_qiefu") > 0 and package_known(self.player,"getStrategyMark","@HITO") == 666 then
		if package_known(self.player,"getHandcardNum") >= 2 and #self.enemies > 0 then
			return source_construct(self,"#qiefu:.:")
		end
	end
end

sgs.ai_skill_use_func["#qiefu"] = function(card,use,self,request)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	use.card = source_construct(self,"#qiefu:"..package_known(cards[1],"getId").."+"..package_known(cards[2],"getId")..":")
	if use.to then
		local target_sets = {}

		for _, enemy in ipairs(self.enemies) do
			local targets = {}

			for _, neig in ipairs(self.enemies) do
				if package_known(enemy,"objectName") == package_known(neig,"objectName") or package_known(enemy,"isAdjacentTo",neig) then
					table.insert(targets, neig)
				end
			end

			table.insert(target_sets, targets)
		end

		local n_max, t = 0, 0

		for i, set in ipairs(target_sets) do
			if #set > n_max then
				n_max = #set
				t = i
			end
		end

		for _, p in ipairs(target_sets[t]) do
			package_call(use.to,"append",p)
		end
	end
end

sgs.ai_use_value["qiefu"] = sgs.ai_use_value.FireSlash + 0.1
sgs.ai_use_priority["qiefu"] = sgs.ai_use_priority.FireSlash + 0.1


local guangmang_skill={}
guangmang_skill.name="guangmang"
table.insert(package_skills,guangmang_skill)
guangmang_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@guangmang-black") == 0 then return false end

	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)

	local handcard

	package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)  do
		if package_known(card,"isBlack") and (not package_known(card,"isKindOf","Slash")) and (not isCard("Peach", card, self.player)) and (not isCard("ExNihilo", card, self.player)) then
			handcard = card
			break
		end
	end

	if not handcard then return nil end
	local suit = package_known(handcard,"getSuitString")
	local number = package_known(handcard,"getNumberString")
	local card_id = package_known(handcard,"getEffectiveId")
	local card_str = ("slash:guangmang[%s:%s]=%d"):format(suit, number, card_id)
	local slash = source_construct(self,card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.guangmang = function(card, player, card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if package_known(card,"isRed") and package_known(player,"getStrategyMark","@guangmang-red") == 1 then
		return ("jink:guangmang[%s:%s]=%d"):format(suit, number, card_id)
	elseif package_known(card,"isBlack") and package_known(player,"getStrategyMark","@guangmang-black") == 1 then
		return ("slash:guangmang[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_use_value["guangmang"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["guangmang"] = sgs.ai_use_priority.Slash - 0.1

sgs.ai_skill_invoke.guangge = function(self, data)
	return true
end

function sgs.ai_cardneed.guangge(to, card)
	if package_known(to,"getStrategyMark","@guangge") == 0 then
		return package_known(card,"isKindOf","GodSalvation") or package_known(card,"isKindOf","Treasure")
	end
end

local lunwu_skill = {}
lunwu_skill.name = "lunwu"
table.insert(package_skills, lunwu_skill)
lunwu_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@lunwu") == 0 or package_known(self.player,"isKongcheng") then return false end
	if #self.enemies > 0 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)
		package_call(self,"sort",self.enemies, "hp")
		local ids = {}
		for i, enemy in ipairs(self.enemies) do
			table.insert(ids, package_known(cards[i],"getId"))
			if i == math.min(#cards, 2) then break end
		end
		local card_str = ("#lunwu:%s:"):format(table.concat(ids, "+"))
		local card = source_construct(self,card_str)
		return card
	end
end

sgs.ai_skill_use_func["#lunwu"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "hp")
	for i, enemy in ipairs(self.enemies) do
		if use.to then package_call(use.to,"append",enemy) end
		if i == math.min(package_known(card,"subcardsLength"), 2) then
			use.card = card
			return
		end
	end
end

sgs.ai_use_value["lunwu"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["lunwu"] = sgs.ai_use_priority.Slash + 1

ai_skill_use["@@lunwu"]=function(self,prompt,request)
	if package_known(self.player,"getStrategyMark","@lunwu") == 0 or package_known(self.player,"isKongcheng") then return "." end
	if #self.enemies > 0 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)
		package_call(self,"sort",self.enemies, "hp")
		local ids, targets = {}, {}
		for i, enemy in ipairs(self.enemies) do
			table.insert(ids, package_known(cards[i],"getId"))
			table.insert(targets, package_known(enemy,"objectName"))
			if i == math.min(#cards, 2) then break end
		end
		return ("#lunwu:%s:->%s"):format(table.concat(ids, "+"), table.concat(targets, "+"))
	end
	return "."
end


local gaoda_huiyun_skill={}
gaoda_huiyun_skill.name="gaoda_huiyun"
table.insert(package_skills,gaoda_huiyun_skill)
gaoda_huiyun_skill.getTurnUseCard=function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","gaoda_huiyun") == 1 then return false end

	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)

	local jink_card

	package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)  do
		if package_known(card,"isKindOf","Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = package_known(jink_card,"getSuitString")
	local number = package_known(jink_card,"getNumberString")
	local card_id = package_known(jink_card,"getEffectiveId")
	local card_str = ("slash:gaoda_huiyun[%s:%s]=%d"):format(suit, number, card_id)
	local slash = source_construct(self,card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.gaoda_huiyun = function(card, player, card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand and package_known(player,"getStrategyMark","gaoda_huiyun") ~= 1 then
		if package_known(card,"isKindOf","Jink") then
			return ("slash:gaoda_huiyun[%s:%s]=%d"):format(suit, number, card_id)
		elseif package_known(card,"isKindOf","Slash") then
			return ("jink:gaoda_huiyun[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_skill_cardask["@gaoda_huiyun"] = function(self, data)
	if package_known(self.player,"getStrategyMark","gaoda_huiyun") == 1 then
		local longyin = sgs.ai_skill_cardask["@longyin"]
		return longyin(self, data)
	end
	return "."
end

sgs.ai_skill_invoke.fengge = function(self, data)
	return true
end

function sgs.ai_cardneed.fengge(to, card)
	if package_known(to,"getStrategyMark","@fengge") == 0 then
		return package_known(card,"isKindOf","GodSalvation") or package_known(card,"isKindOf","Treasure")
	end
end

local longhou_skill = {}
longhou_skill.name = "longhou"
table.insert(package_skills, longhou_skill)
longhou_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@longhou") == 0 or package_known(self.player,"isKongcheng") then return false end
	if #self.enemies > 0 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)
		package_call(self,"sort",self.enemies, "hp")
		local ids = {}
		for i, enemy in ipairs(self.enemies) do
			table.insert(ids, package_known(cards[i],"getId"))
			if i == math.min(#cards, 2) then break end
		end
		local card_str = ("#longhou:%s:"):format(table.concat(ids, "+"))
		local card = source_construct(self,card_str)
		return card
	end
end

sgs.ai_skill_use_func["#longhou"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "hp")
	for i, enemy in ipairs(self.enemies) do
		if use.to then package_call(use.to,"append",enemy) end
		if i == math.min(package_known(card,"subcardsLength"), 2) then
			use.card = card
			return
		end
	end
end

sgs.ai_use_value["longhou"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["longhou"] = sgs.ai_use_priority.Slash + 1

ai_skill_use["@@longhou"]=function(self,prompt,request)
	if package_known(self.player,"getStrategyMark","@longhou") == 0 or package_known(self.player,"isKongcheng") then return "." end
	if #self.enemies > 0 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)
		package_call(self,"sort",self.enemies, "hp")
		local ids, targets = {}, {}
		for i, enemy in ipairs(self.enemies) do
			table.insert(ids, package_known(cards[i],"getId"))
			table.insert(targets, package_known(enemy,"objectName"))
			if i == math.min(#cards, 2) then break end
		end
		return ("#longhou:%s:->%s"):format(table.concat(ids, "+"), table.concat(targets, "+"))
	end
	return "."
end




sgs.ai_skill_invoke.boss_juao = function(self, data)
	return true
end

sgs.ai_skill_cardask["@boss_fuchou"] = function(self, data)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)

	local use = package_known(data,"toCardUse")
	for _,card in ipairs(cards) do
		if package_known(card,"getSuit") == package_known(use.card,"getSuit") then
			return package_known(card,"getEffectiveId")
		end
	end

	return "."
end

local boss_miehou_skill = {}
boss_miehou_skill.name = "boss_miehou"
table.insert(package_skills,boss_miehou_skill)
boss_miehou_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@point") >= 6 and not package_known(self.player,"hasUsed","#boss_miehou") then
		local card_str = ("#boss_miehou:.:")
		return source_construct(self,card_str)
	end
end

sgs.ai_skill_use_func["#boss_miehou"] = function(card,use,self,request)
	use.card = card
end

sgs.dynamic_value.benefit["boss_miehou"] = true

sgs.ai_use_value["boss_miehou"] = sgs.ai_use_value.Slash + 0.1
sgs.ai_use_priority["boss_miehou"] = sgs.ai_use_priority.Slash + 0.1


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
