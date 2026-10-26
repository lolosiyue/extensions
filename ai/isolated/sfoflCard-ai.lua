local PACKAGE="sfoflCard"
local SELECTORS={["#sfofl_longyi"]="sfofl_longyi",["#sfofl_qichuCard"]="sfofl_qichu",["#sfofl_longxinCard"]="sfofl_longxin",["#sfofl_young_zhiheng"]="sfofl_young_zhiheng",["#sfofl_quanyi"]="sfofl_quanyi",["#sfofl_qupo"]="sfofl_qupo",["#sfofl_horsetailwhisk"]="sfofl_horsetailwhisk",["#sfofl_liaozou"]="sfofl_liaozou",["#sfofl_yijue"]="sfofl_yijue",["#sfofl_nuchen"]="sfofl_nuchen",["#sfofl_zhiji"]="sfofl_zhiji",["#sfofl_jiefeng"]="sfofl_jiefeng",["#sfofl_daohe"]="sfofl_daohe",["#sfofl_zhiyiz"]="sfofl_zhiyiz",["#sfofl_longyin"]="sfofl_longyin",["#sfofl_2_jianshu"]="sfofl_2_jianshu",["#undershouli"]="undershouli",["#sfofl_boss_wenjiu"]="sfofl_boss_wenjiu",["#sfofl_boss_xiuluo"]="sfofl_boss_xiuluo",["#sfofl_boss_shajue"]="sfofl_boss_shajue",["#sfofl_zhanyan"]="sfofl_zhanyan",["#sfofl_longsong"]="sfofl_longsong",["#sfofl_fuli"]="sfofl_fuli",["#sfofl_dehua"]="sfofl_dehua",["#sfofl_sancai"]="sfofl_sancai",["#yj_zhengyuCard"]="yj_zhengyu",["#sfofl_shuangren"]="sfofl_shuangren",["#sfofl_mujun"]="sfofl_mujun",["#sfofl_xuanshi"]="sfofl_xuanshi",["#sfofl_xiongye"]="sfofl_xiongye",["#sfofl_jieqiao_quyi"]="sfofl_jieqiao_quyi",["#sfofl_lianhuan"]="sfofl_lianhuan",["#sfofl_beirong"]="sfofl_beirong",["#sfofl_huoce"]="sfofl_huoce",["#sfofl_boyan"]="sfofl_boyan",["#sfofl_2_zhouji"]="sfofl_2_zhouji",["#sfofl_zhaxiong"]="sfofl_zhaxiong",["#sfofl_barbs"]="sfofl_barbs",["#sfofl_lilu"]="sfofl_lilu",["#sfofl_liaofu"]="sfofl_liaofu",["#sfofl_jianjing"]="sfofl_jianjing",["#sfofl_fenqi"]="sfofl_fenqi",["#sfofl_tuwei"]="sfofl_tuwei",["#sfofl_2_zhanyan"]="sfofl_2_zhanyan",["#sfofl_zainei"]="sfofl_zainei",["#sfofl_hanwei"]="sfofl_hanwei",["#sfofl_xiongshi"]="sfofl_xiongshiAttach",["#sfofl_deshi"]="sfofl_deshi",["#sfofl_qianjun"]="sfofl_qianjun",["#sfofl_nitian"]="sfofl_nitian",["#sfofl_jukou"]="sfofl_jukou",["#sfofl_shupan"]="sfofl_shupan",["#sfofl_houying"]="sfofl_houying",["#sfofl_qianhu"]="sfofl_qianhu",["#sfofl_fangtong"]="sfofl_fangtong",["#sfofl_zhouyuan"]="sfofl_zhouyuan",["#sfofl_zhengan_basicCard"]="sfofl_zhengan_basic",["#sfofl_weizhu"]="sfofl_weizhu",["#sfofl_zequan"]="sfofl_zequan",["#sfofl_cheji"]="sfofl_cheji",["#sfofl_cuixi"]="sfofl_cuixi",["#sfofl_jujun"]="sfofl_jujun",["#sfofl_sixi"]="sfofl_sixi",["#sfofl_bixiong"]="sfofl_bixiong",["#sfofl_qianmu"]="sfofl_qianmu",["#sfofl_lianji"]="sfofl_lianji",["#sfofl_jingongz"]="sfofl_jingongz",["#sfofl_liyu"]="sfofl_liyu",["#sfofl_sixiong"]="sfofl_sixiong",["#sfofl_chuce"]="sfofl_chuce",["#sfofl_dingxi"]="sfofl_dingxi",["#sfofl_dingluan"]="sfofl_dingluan",["#sfofl_chiyuan"]="sfofl_chiyuan",["#sfofl_dutan"]="sfofl_dutan",["#sfofl_zhanyi"]="sfofl_zhanyi",["#sfofl_jianshu"]="sfofl_jianshu",["#sfofl_zongma"]="sfofl_zongma",["#sfofl_xiaoguo"]="sfofl_xiaoguo",["#sfofl_dizhao"]="sfofl_dizhao",["#sfofl_batteringram"]="sfofl_batteringram",["#sfofl_yufeng"]="sfofl_yufeng",["#sfofl_zhengjing"]="sfofl_zhengjing",["#sfofl_juezhi"]="sfofl_juezhi",["#sfofl_qianjing"]="sfofl_qianjing",["#sfofl_qianjingEquipCard"]="sfofl_qianjing",["#sfofl_bianchi"]="sfofl_bianchi",["#sfofl_picai"]="sfofl_picai",["#sfofl_yaozhuo"]="sfofl_yaozhuo",["#sfofl_kuiji"]="sfofl_kuiji",["#sfofl_kuijidisCard"]="sfofl_kuiji",["#sfofl_xiaolu"]="sfofl_xiaoluAttach",["#sfofl_zhaoyuan"]="sfofl_zhaoyuan",["#sfofl_gezhi"]="sfofl_gezhi",["#sfofl_shenglv"]="sfofl_shenglv",["#sfofl_liufangc"]="sfofl_liufangc",["#sfofl_renwang"]="sfofl_renwang",["#sfofl_zunwei"]="sfofl_zunwei",["#sfofl_chongxu"]="sfofl_chongxu",["#sfofl_miaojing"]="sfofl_miaojing",["#sfofl_kannan"]="sfofl_kannan",["#sfofl_jianji"]="sfofl_jianji",["#sfofl_duliang"]="sfofl_duliang",["#sfofl_zhuren"]="sfofl_zhuren",["#sfofl_miewu"]="sfofl_miewu",["#sfofl_rengong"]="sfofl_rengong",["#sfofl_n_linzhen"]="sfofl_n_linzhen",["#sfofl_nujian"]="sfofl_nujian",["#sfofl_nujianAttach"]="sfofl_nujianAttach",["#sfofl_kuishe"]="sfofl_kuishe",["#sfofl_yuanlue"]="sfofl_yuanlue",["#sfofl_wuduan"]="sfofl_wuduan",["#sfofl_rende"]="sfofl_rende",["#sfofl_rende_basic"]="sfofl_rende_basic",["#sfofl_shoufan"]="sfofl_shoufan",["#sfofl_bingman"]="sfofl_bingman",["#sfofl_zaizheng"]="sfofl_zaizheng",["#sfofl_zhaoxin"]="sfofl_zhaoxin",["#sfofl_n_yangwu"]="sfofl_n_yangwu",["#sfofl_n_hujia"]="sfofl_n_hujia",["#sfofl_n_yuanlue"]="sfofl_n_yuanlue",["#sfofl_n_juezhanAttach"]="sfofl_n_juezhanAttach",["#sfofl_n_fenyin"]="sfofl_n_fenyin",["#sfofl_n_tongchou"]="sfofl_n_tongchou",["#sfofl_n_shiji"]="sfofl_n_shiji",["#sfofl_n_zhuifeng"]="sfofl_n_zhuifeng",["#sfofl_n_chongjian"]="sfofl_n_chongjian",["#sfofl_qinyi"]="sfofl_qinyi",["#sfofl_moqi"]="sfofl_moqi"}
local ORDINARY_SKILLS={["BearingDownBorder"]=true,["_sfofl_cheji"]=true,["_sfofl_dunji"]=true,["_sfofl_jubing"]=true,["_sfofl_nujian"]=true,["sfofl_2_xuezhan"]=true,["sfofl_baye"]=true,["sfofl_boss_wusheng"]=true,["sfofl_bozhan"]=true,["sfofl_chuce"]=true,["sfofl_cuiji"]=true,["sfofl_dehua"]=true,["sfofl_deshi"]=true,["sfofl_dingluan"]=true,["sfofl_dingxi"]=true,["sfofl_dizhao"]=true,["sfofl_dutan"]=true,["sfofl_fujing"]=true,["sfofl_hefa"]=true,["sfofl_horsetailwhisk"]=true,["sfofl_houying"]=true,["sfofl_huxiao"]=true,["sfofl_jianji"]=true,["sfofl_jiaozheng"]=true,["sfofl_jiefeng"]=true,["sfofl_jingongz"]=true,["sfofl_juedian"]=true,["sfofl_juedou"]=true,["sfofl_lianhuan"]=true,["sfofl_lianji"]=true,["sfofl_lizhen"]=true,["sfofl_longyi"]=true,["sfofl_longyin"]=true,["sfofl_miaojing"]=true,["sfofl_miewu"]=true,["sfofl_mouni"]=true,["sfofl_n_chongjian"]=true,["sfofl_n_duanji"]=true,["sfofl_n_juezhan"]=true,["sfofl_n_leiming"]=true,["sfofl_n_luanjian"]=true,["sfofl_n_moucheng"]=true,["sfofl_n_xuezhan"]=true,["sfofl_n_zhuifeng"]=true,["sfofl_n_zonghuo"]=true,["sfofl_nanbing"]=true,["sfofl_niqu"]=true,["sfofl_qianhu"]=true,["sfofl_qianjing"]=true,["sfofl_qianmu"]=true,["sfofl_qifeng"]=true,["sfofl_qingjin"]=true,["sfofl_qinyi"]=true,["sfofl_rende"]=true,["sfofl_sheji"]=true,["sfofl_shengcai"]=true,["sfofl_shice"]=true,["sfofl_sitong"]=true,["sfofl_sixi"]=true,["sfofl_taoluan"]=true,["sfofl_tigertally"]=true,["sfofl_wusheng"]=true,["sfofl_xiaolu"]=true,["sfofl_yanggu"]=true,["sfofl_yibing"]=true,["sfofl_zequan"]=true,["sfofl_zhaobing"]=true,["sfofl_zhengan_basic"]=true,["sfofl_zhongtao"]=true,["undershouli"]=true}
local package_skills={}
-- Capture before this package assigns anything: key prefixes are not ownership.
local initial_callbacks={}
for _,name in ipairs({'ai_fill_skill','ai_guhuo_card','ai_cardsview','ai_cardsview_valuable','ai_view_as'})do
 local before={};for key,value in pairs((name == "ai_skill_invoke" and ai_skill_invoke or (name == "ai_fill_skill" and ai_fill_skill or (name == "ai_skill_choice" and ai_skill_choice or sgs[name]))))do before[key]=value end;initial_callbacks[name]=before
end
initial_callbacks.ai_skill_use={};for key,value in pairs(ai_skill_use)do initial_callbacks.ai_skill_use[key]=value end
-- Native registries have independent ownership snapshots outside sgs.
initial_callbacks.ai_card_use={};for key,value in pairs(ai_card_use)do initial_callbacks.ai_card_use[key]=value end
local active_requests=setmetatable({},{__mode="k"})
local clone_states=setmetatable({},{__mode='k'})
local function unsupported(key)ai_unsupported('source capability is not projected',PACKAGE..'.'..key)end

-- Only the viewer's own tags are projected (absent reads as false); a room tag
-- reaches the VM only as the ask's context damage.
local OWN_TAGS={sfofl_zongfan=true,sfofl_bianchiForAI=true,sfofl_boss_wushuang=true,PresentCard=true,sfofl_YellowTurbanRebels0=true}
local function fact(self,key)
 if key=='CurrentDamageStruct'then
  local raw=type(self.request.options)=='table'and self.request.options.context
  local v=type(raw)=='table'and raw.damage or nil
  if v==nil then unsupported(key)end;return v
 end
 if not OWN_TAGS[key]then unsupported(key)end
 local v=package_call(self.player,'getTag',key)
 if v==nil then return false end;return v
end
local function clone(self,name,skill,suit,number)
 name=name or 'slash';local p=self:cloneEvaluationCard(name)
 if p==false then return nil end;if not p then unsupported('prototype.'..tostring(name))end
 local v={};clone_states[v]={self=self,name=p:objectName(),skill=skill or '',suit=suit==nil and sgs.Card_NoSuit or suit,number=number or 0,costs={},prototype=p,flags={}}
 return v
end
local function materialize(v)
 local s=clone_states[v];if not s then return v end
 if next(s.flags) then unsupported('clone_flags.'..s.skill)end
 local rangeKey=({sfofl_sitong='sfofl_sitong',sfofl_jiaozheng='sfofl_jiaozheng',sfofl_qingjin='sfofl_qingjin',
  BearingDownBorder=#s.costs==1 and '@sfofl_bearing_down_border' or 'BearingDownBorder',
  _sfofl_jubing='sfofl_jubing',sfofl_qifeng='@@sfofl_qifeng',sfofl_juedou='sfofl_juedou'})[s.skill]
 if rangeKey then
  if s.range_cached then return s.range_cached end
  local ids={};for i,id in ipairs(s.costs)do ids[i]=id end
  local card=s.self:evaluateOwnerViewAsCard({source_key='owner_range:'..rangeKey,name=s.name,
    skill=s.skill,suit=s.suit,number=s.number,subcards=ids})
  s.range_cached=card;return card
 end
 local card
 if s.skill=='' and #s.costs==0 and s.suit==sgs.Card_NoSuit and s.number==0 then card=s.prototype
 else card=s.self:evaluateSkillCard(s.skill, s.name, s.costs)end
 if not card then unsupported('clone.'..s.skill..'.'..s.name)end
 if s.can_recast~=nil and card:canRecast()~=s.can_recast then unsupported('clone_recast.'..s.skill)end
 -- Reject evaluation clones with a different suit or rank.
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
  if k=='setSkillName'or k=='setSuit'or k=='setNumber'or k=='setCanRecast'or k=='clearSubcards'or k=='addSubcard'or k=='addSubcards'or k=='setFlags'then s.range_cached=nil end
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
 if key=='JilveWansha' and kind=='toBool' then
  local value=package_call(self.player,'getTag','JilveWansha')
  if value==nil then value=false end
  if type(value)~='boolean' then unsupported('JilveWansha.owner_bool') end
  return value
 end
 local v=fact(self,key)
 if kind=='toPlayer'then return v~=false and package_known(self.room,'findPlayerByObjectName',v,true)or nil end
 if kind=='toInt'or kind=='toString'or kind=='toBool'then return v end
 if kind=='toIntList'then return AIList.new(v or{})end
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
 -- Native play keeps the supplied action scope; fill may still pass a facade.
 local action=type(request)=="table"and request.skill_action or nil
 if type(action)=="table"then skill=action.activation_skill
 elseif request and type(request.getActivationSkillName)=='function'then skill=request:getActivationSkillName()end
 return package_known(self,'evaluateTurnSkillCard',skill,selector,costs,request,user~=''and user or nil)
end
-- Parse only package-authored card specifications.
local function source_ids(text)
 -- ListS2I(text.split('+')): pieces that are not integers are skipped.
 local out={}
 for piece in (text..'+'):gmatch('([^+]*)%+')do
  local id=piece:match('^%s*[-+]?%d+%s*$')and tonumber(piece)
  if id and id>=-2147483648 and id<=2147483647 then out[#out+1]=id end
 end
 return out
end
local function source_skill(self,text,request)
 if type(text)~='string'then unsupported('source_skill')end
 text=text:match('^(.-)%->')or text
 local selector,cost,user=text:match('^(#[%w_]+):([^:]*):(.*)$')
 if not selector then unsupported('source_skill_shape')end
 local ids=source_ids(cost)
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
local function owner_reason(self)local n=self.request and self.request.reason;if type(n)~='number'then unsupported('owner_current_card_use_reason')end;return n end
local function ambient_pattern(self)unsupported('ambient_pattern')end
local function source_tag(self,key)return setmetatable({},{__index=function(_,kind)return function()return source_fact(self,key,kind)end end})end
local function foreign_fact(self,subject,key,kind)
 if subject==self.player then return source_fact(self,key,kind)end
 unsupported('foreign_tag.'..key)
end
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
 local v=package_call(self.player,'getPropertyValue',key)
 if v==nil then return{toString=function()return''end,toInt=function()return 0 end,toBool=function()return false end}end
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
-- addFunction.lua179/221/1545, private pure source dependencies.
local function source_kingdoms(self)
 local seen={[package_known(self.player,'getKingdom')]=true};local n=1
 for _,p in ipairs(package_known(self.room,'getOtherPlayers',self.player))do local k=package_known(p,'getKingdom');if not seen[k]then seen[k]=true;n=n+1 end end;return n
end
local function RandomList(items)
 local remaining={};for _,v in ipairs(items)do remaining[#remaining+1]=v end
 while #remaining>0 do local v=remaining[math.random(1,#remaining)];table.removeOne(remaining,v);table.removeOne(items,v);if AIList.isNativeList(items)then items:append(v)else table.insert(items,v)end end
 return items
end
local function InsertList(first,second)
 for _,v in ipairs(second)do if AIList.isNativeList(first)then first:append(v)else table.insert(first,v)end end;return first
end
local function public_deck_rows(self,key)
 -- Printed deck rows and their hypothetical availability are not projected.
 unsupported('public_deck_host')
end
local function PatternsCard(self,name,islist)
 if name~='BasicCard'or islist~=true then unsupported('public_deck_source_pattern')end
 return public_deck_rows(self,'sfofl_zhengan_basic_printed')
end
local function source_can_to_card(self,card,from,to)
 if from~=self.player then unsupported('foreign_empty_prefix_target_filter')end
 return package_known(self,'cardTargetFilter',card,{},to)
end
local function longmu_event(self,player,event)
 -- Death.who, generals, skills and marks are read from the public board.
 if event.kind~='death'then unsupported('longmu.death')end
 local target=package_known(self.room,'findPlayerByObjectName',event.to,true)
 if package_known(target,'getGeneralName'):find('zombie',1,true)or package_known(target,'getGeneral2Name'):find('zombie',1,true)then return end
 local function role(p)
  local value=package_call(p,'getRole')
  if value==nil then value=package_known(self,'getRoleEstimate',p);value=package_known(self,'useKnowledgeEstimate',{value=value,status='estimate',basis='sfofl_longmu:viewer_inference_replaces_foreign_private_role',viewer=package_known(self.player,'objectName'),observer=package_known(p,'objectName')},'sfofl_longmu.role')end
  if not({lord=true,loyalist=true,rebel=true,renegade=true})[value]then unsupported('longmu.role')end;return value
 end
 -- Keep donor roster order and update after every write.
 for _,source in ipairs(package_known(self.room,'getOtherPlayers',player))do
  local name=package_known(source,'objectName')
  if package_known(source,'hasSkill','sfofl_longmu')and package_known(target,'getMark','sfofl_longmu'..name)>0 then
   package_call(self,'emitStrategyEffect',{kind='sfofl_longmu_role',player=package_known(target,'objectName'),source_player=name,source_role=role(source),target_role=role(target)})
   package_call(self,'updatePlayers')
  end
 end
end

sgs.ai_event_callback[sgs.BeforeGameOverJudge]=sgs.ai_event_callback[sgs.BeforeGameOverJudge]or{}
sgs.ai_card_priority.sfofl_zhonghun = function(self, card, v)
    if package_known(card,"isRed") then
        return 0.5
    end
end

package_add("sfofl_longyi").getTurnUseCard = function(self,inclusive,request)
    for c, pn in sgs.list(RandomList(patterns_for(self))) do
        c = clone(self,pn)
        if c and package_known(c,"isKindOf","BasicCard") and package_known(self,"getCardsNum",c) == 0 then
            if package_known(c,"isKindOf","Analeptic") and package_known(self,"getCardsNum","TrickCard") == 0 then return end
            package_call(c,"setSkillName","sfofl_longyi")
            package_call(c,"addSubcards",package_known(self.player,"getHandcards"))
            if package_known(c,"isAvailable",self.player)
                and package_known(self,"aiUseCard",c).card
            then
                return c
            end
        end
    end
end

sgs.ai_guhuo_card.sfofl_longyi = function(self, toname, class_name)
    if class_name and package_known(self,"getCardsNum",class_name) > 0 then return end
    local c = clone(self,toname)
    package_call(c,"setSkillName","sfofl_longyi")
    package_call(c,"addSubcards",package_known(self.player,"getHandcards"))
    if (not c) or (not package_known(c,"isKindOf","BasicCard")) then return end
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
    local to_use = {}
    for _, card in ipairs(cards) do
        table.insert(to_use, package_known(card,"getId"))
    end
    if #to_use > 0 then
        return "#sfofl_longyi:"..table.concat(to_use, "+") ..":"..toname
    end
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|sfofl_longyi"

sgs.ai_ajustdamage_from.sfofl_shiyin = function(self, from, to, card, nature)
    if package_known(from,"getStrategyFlag","sfofl_shiyin_damage")
    then
        return 1
    end
end

sgs.ai_ajustdamage_from["&sfofl_liushang-Clear"] = function(self, from, to, card, nature)
    if package_known(to,"hasSkill","sfofl_liushang")
    then
        return -99
    end
end

sgs.ai_skill_cardask["@sfofl_liushang"] = function(self, data, pattern, target, target2)
	local target = package_call(data,"toPlayer")
	local usable_cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	package_call(self,"sortByKeepValue",usable_cards)

	if target then
		if package_known(self,"isFriend",target) then
			usable_cards = sgs.reverse(usable_cards)
			return package_known(usable_cards[1],"toString")
		else
			return package_known(usable_cards[1],"toString")
		end
	end
	return "."
end

ai_skill_invoke.sfofl_qibu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local dying = package_known(data,"toDying")
	local peaches = 1-package_known(dying.who,"getHp")

	return (package_known(self,"getCardsNum","Peach")+package_known(self,"getCardsNum","Analeptic")<peaches) or false
end

sgs.ai_canNiepan_skill.sfofl_qibu = function(player)
	return package_known(player,"getStrategyMark","@sfofl_qibu") > 0
end

ai_skill_invoke.sfofl_liushang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	for _, p in sgs.qlist(package_known(self.room,"findPlayersBySkillName","sfofl_liushang")) do
        if not package_known(self,"isEnemy",p) then
            return (true) or false
        end
    end
	return (false) or false
end


sgs.ai_skill_discard.sfofl_qizuo           = function(self)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	local damage = source_fact(self,"sfofl_qizuo","toDamage")
    local list = package_known(self.room,"getAlivePlayers")
	local target
	for _, p in sgs.qlist(list) do
		if package_known(p,"getStrategyFlag","sfofl_qizuo_target") then
			target = p
		end
	end
	if not target then return {} end
        if damage.to and package_known(self,"isFriend",damage.to) then
            if package_known(self,"needToLoseHp",damage.to,damage.from,damage.card) then
                return {}
            end
        else
            if package_known(self,"cantDamageMore",damage.from, damage.to) then
                return {}
            end
        end
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, package_known(card,"getEffectiveId"))
        break
	end
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end
ai_skill_choice.sfofl_qizuo = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local damage = package_known(data,"toDamage")
	if package_known(self,"isFriend",damage.to) and not package_known(self,"needToLoseHp",damage.to,damage.from,damage.card) then return ai_choice_result(("minus"), options) end
	return ai_choice_result(("add"), options)
end
sgs.ai_skill_cardask["@sfofl_quanmou"] = function(self, data, pattern, target)
	local use = package_known(data,"toCardUse")
    local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)
    for _, card in ipairs(cards) do
        if package_known(self,"getKeepValue",card) < package_known(self,"getKeepValue",use.card) and package_known(use.card,"sameColorWith",card) then
            return package_known(card,"getEffectiveId")
        end
    end
	return "."
end

ai_skill_invoke.sfofl_qijin = true


function sgs.ai_cardsview_valuable.sfofl_qichu(self,class_name,player)
	if class_name=="Slash"
	then return "#sfofl_qichuCard:.:slash"
	elseif class_name=="Peach" or class_name=="Analeptic"
	then
		local dying = package_known(self.room,"getCurrentDyingPlayer")
		if dying and package_known(dying,"objectName")==package_known(player,"objectName")
		then
			local user_string = "peach+analeptic"
			if package_known(player,"getStrategyMark","Global_PreventPeach")>0 then user_string = "analeptic" end
			return "#sfofl_qichuCard:.:"..user_string
		else
			local user_string
			if class_name=="Analeptic" then user_string = "analeptic" else user_string = "peach" end
			return "#sfofl_qichuCard:.:"..user_string
		end
	end
end

ai_skill_invoke.sfofl_qichu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local asked = package_known(data,"toStringList")
	local pattern = asked[1]
	local prompt = asked[2]
	return (package_known(self,"askForCard",pattern,prompt,1)~=".") or false
end

sgs.ai_skill_askforag.sfofl_qichu = function(self,card_ids)
	local card = disclosed_card(self,card_ids[1])
	if package_known(card,"isKindOf","Jink") and package_known(self.player,"getStrategyFlag","dahe") then
		for _,id in ipairs(card_ids)do
			if disclosed_card(self,id):getSuit()==sgs.Card_Heart then return id end
		end
		return -1
	end
	return card_ids[1]
end


ai_skill_use["@@sfofl_longxin"]=function(self,prompt,request)
	local disaster,indulgence,supply_shortage = -1,-1,-1
	for _,card in sgs.list(package_known(self.player,"getJudgingArea"))do
		if package_known(card,"isKindOf","Disaster") then disaster = package_known(card,"getId") end
		if package_known(card,"isKindOf","Indulgence") then indulgence = package_known(card,"getId") end
		if package_known(card,"isKindOf","SupplyShortage") then supply_shortage = package_known(card,"getId") end
	end
	local use_card
	for _,c in sgs.list(package_known(self.player,"getCards","he"))do
		if package_known(self.player,"canDiscard",self.player,package_known(c,"getEffectiveId")) and package_known(c,"isKindOf","EquipCard") then
			use_card = c
            break
		end
	end
    if not use_card then return "." end

	local discard = {}
    table.insert(discard,package_known(use_card,"getId"))
	if disaster>-1 and package_known(self,"hasSkills",sgs.wizard_skill,self.enemies) then
		table.insert(discard,disaster)
		return "#sfofl_longxinCard:"..table.concat(discard,"+") ..":"
	end

	if indulgence>-1 and package_known(self.player,"hasSkill","keji") and supply_shortage>-1 then
		table.insert(discard,supply_shortage)
		return "#sfofl_longxinCard:"..table.concat(discard,"+") ..":"
	end

	if indulgence>-1 and package_known(self,"getCardsNum","Peach")>1 and package_known(self,"isWeak") then
		table.insert(discard,indulgence)
		return "#sfofl_longxinCard:"..table.concat(discard,"+") ..":"
	end
    if not package_known(self,"isWeak")  then
		table.insert(discard,package_known(self.player,"getJudgingAreaID"):first())
		return "#sfofl_longxinCard:"..table.concat(discard,"+") ..":"
	end

	return "."
end



local sfofl_sheji_skill = { name = "sfofl_sheji" }
table.insert(package_skills, sfofl_sheji_skill)
sfofl_sheji_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	package_call(self,"updatePlayers")
	local has_weak_enemy = false
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"isWeak",enemy) then
			has_weak_enemy = true
		end
	end
	if (package_known(self.player,"isKongcheng")) then return end
	if not has_weak_enemy then
		if package_known(self,"getCardsNum","Peach") > 0 or package_known(self,"getCardsNum","Duel") > 0
			or (package_known(self,"getCardsNum","Analeptic") > 0 and package_known(self,"isWeak"))
			or (package_known(self,"getCardsNum","Jink") > 0 and package_known(self,"isWeak"))
			or package_known(self,"getCardsNum","SupplyShortage") > 0 or package_known(self,"getCardsNum","Indulgence") > 0
			or package_known(self,"getCardsNum","ArcheryAttack") > 0 or package_known(self,"getCardsNum","SavageAssault") > 0
		then
			return
		end
	end

	if package_known(self.player,"getHandcardNum") > 1 then
		for _, c in sgs.qlist(package_known(self.player,"getHandcards")) do
			if not package_known(c,"isKindOf","Analeptic") then
				if package_known(self,"willUse",self.player, c) or package_known(c,"isAvailable",self.player) then return end
			end
		end
	end
	local slash = clone_native(self,"slash", sgs.Card_SuitToBeDecided, -1)
	package_call(slash,"addSubcards",package_known(self.player,"getHandcards"))
	package_call(slash,"setSkillName","sfofl_sheji")
	return slash
end

sgs.ai_card_priority.sfofl_sheji = function(self, card)
	if package_known(card,"isKindOf","Slash") and package_known(self.player,"getHandcardNum") < 4 and table.contains(package_known(card,"getSkillNames"), "sfofl_sheji")
	then
		return 1
	end
end

ai_skill_invoke.sfofl_sheji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_known(data,"toDamage").to
	if not package_known(self,"doDisCard",target, "e", true) then
		return (false) or false
	end
	return (true) or false
end
sgs.need_kongcheng = sgs.need_kongcheng .. "|sfofl_hengzheng"

sgs.ai_getBestHp_skill.sfofl_hengzheng = function(owner)
	if package_known(owner,"getPhase") == sgs.Player_NotActive and package_known(owner,"getHp") <= 2 then
		return 1
	end
end

sgs.ai_skill_playerschosen.sijyuoffline_huyi = function(self, targets, max, min)
	local enemy = sgs.SPlayerList()
	for _, p in sgs.qlist(targets) do
		if package_known(self,"isEnemy",p) and not package_known(p,"isChained") then
			package_call(enemy,"append",p)
			if package_known(enemy,"length") > min then break end
		end
	end
	return enemy
end


ai_skill_invoke.sfofl_yice = true
sgs.ai_skill_askforag.sfofl_yice = function(self,card_ids)
	return card_ids[1]
end
sgs.ai_skill_playerchosen.sfofl_yice_damage = function(self, targets)
	package_call(self,"sort",self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"objectiveLevel",enemy) > 3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"canDamage",enemy,self.player,nil) and package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) then
			return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		return enemy
	end
	return package_known(targets,"first")
end


ai_skill_invoke.sfofl_young_ganglie = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local mode = package_known(self.room,"getMode")
	if package_known(mode,"find","_mini_41") or package_known(mode,"find","_mini_46") then return (true) or false end
	local damage = package_known(data,"toDamage")
	return (not package_known(self,"isFriend",damage.from) and package_known(self,"doDisCard",damage.from, "h")) or false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_young_ganglie = function(self,player,promptlist)
	local damage = source_fact(self,"CurrentDamageStruct","toDamage")
	if damage.from and damage.to then
		if promptlist[#promptlist]=="yes" then
			if not package_known(self,"doDisCard",damage.from, "h") then
				sgs.updateIntention(damage.to,damage.from,40)
			end
		end
	end
end
local sfofl_young_zhiheng_skill = {}
sfofl_young_zhiheng_skill.name = "sfofl_young_zhiheng"
table.insert(package_skills, sfofl_young_zhiheng_skill)
sfofl_young_zhiheng_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	local card
	package_call(self,"sortByUseValue",cards, true)
	for _, acard in ipairs(cards) do
		if package_known(self,"getUseValue",acard) < 6 then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = package_known(card,"getEffectiveId")
	local card_str = "#sfofl_young_zhiheng:" .. card_id .. ":"
	local skillcard = source_construct(self,card_str)

	return skillcard
end
ai_card_use["#sfofl_young_zhiheng"]=function(self, card, use, request)
	use.card = card
	return
end
sgs.ai_use_priority["sfofl_young_zhiheng"] = 2.61

sgs.hit_skill = sgs.hit_skill .. "|sfofl_young_wushuang"
sgs.ai_cardneed.sfofl_young_wushuang = sgs.ai_cardneed.slash

ai_skill_invoke.sfofl_young_eight_diagram =ai_skill_invoke.eight_diagram

local sfofl_quanyi_skill = {}
sfofl_quanyi_skill.name = "sfofl_quanyi"
table.insert(package_skills, sfofl_quanyi_skill)
sfofl_quanyi_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self,"needBear") then return end
	local card_str = "#sfofl_quanyi:.:"
	local skillcard = source_construct(self,card_str)

	return skillcard
end
ai_card_use["#sfofl_quanyi"]=function(self, card, use, request)
	package_call(self,"sort",self.enemies,"handcard")
	local cards = sgs.CardList()
	local peach = 0
	for _,c in sgs.qlist(package_known(self.player,"getHandcards"))do
		if isCard("Peach",c,self.player) and peach<2 then
			peach = peach+1
		else
			package_call(cards,"append",c)
		end
	end
	local max_card = package_call(self,"getMaxCard",self.player,cards)
	if max_card and package_known(max_card,"isRed") and package_known(max_card,"getNumber") >= 10  then
		for _,enemy in sgs.list(self.enemies)do
			if package_known(self.player,"canPindian",enemy) and package_known(self,"doDisCard",enemy,"he") then
				package_call(self,"setPriorityValue","sfofl_quanyi", 1.2,"sfoflCard.source")
				source_state(self).sfofl_quanyi_card = package_known(max_card,"getId")
				package_known(self.room,"addPlayerMark",self.player, "ai_sfofl_quanyi-PlayClear")
				use.card = source_construct(self,"#sfofl_quanyi:.:")
				package_call(use.to,"append",enemy)
				return
			end
		end
	end
	local zhugeliang = package_call(self.room,"findPlayerBySkillName","kongcheng")

	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards,true)
	if zhugeliang and package_known(self,"isFriend",zhugeliang) and package_known(zhugeliang,"getHandcardNum")==1
		and package_known(zhugeliang,"objectName")~=package_known(self.player,"objectName") and package_known(self,"getEnemyNumBySeat",self.player,zhugeliang)>=1 and package_known(self.player,"canPindian",zhugeliang) then
		if isCard("Jink",cards[1],self.player) and package_known(self,"getCardsNum","Jink")==1 then return end
		source_state(self).sfofl_quanyi_card = package_known(cards[1],"getId")
		use.card = source_construct(self,"#sfofl_quanyi:.:")
		package_call(use.to,"append",zhugeliang)
		return
	end
	if package_known(cards[1],"getNumber") < 7 and package_known(cards[1],"isBlack") then
		for _,enemy in sgs.list(self.enemies)do
			if package_known(self,"doDisCard",enemy,"h") and package_known(self.player,"canPindian",enemy) and not package_known(self,"hasZhaxiangEffect",enemy) then
				package_known(self.room,"addPlayerMark",self.player, "ai_sfofl_quanyi-PlayClear")
				source_state(self).sfofl_quanyi_card = package_known(cards[1],"getId")
				use.card = source_construct(self,"#sfofl_quanyi:.:")
				package_call(use.to,"append",enemy)
				return
			end
		end
	end

	for _,enemy in sgs.list(self.enemies)do
		if package_known(self,"doDisCard",enemy,"h") and package_known(self.player,"canPindian",enemy) then
			use.card = source_construct(self,"#sfofl_quanyi:.:")
			package_call(use.to,"append",enemy)
			return
		end
	end
	return nil
end
sgs.ai_card_intention["sfofl_quanyi"] = 80

ai_skill_invoke.sfofl_quanyi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if package_known(self.player,"getStrategyMark","ai_sfofl_quanyi-PlayClear") > 0 then return (false) or false end
	return (true) or false
end
ai_skill_use["@@sfofl_qupo"]=function(self,prompt,request)

	if not package_known(self.room,"hasCurrent") then return "." end
	local current = package_call(self.room,"getCurrent")
	if package_known(current,"isDead") then return "." end
	if package_known(self,"isEnemy",current) and package_known(self,"willSkipPlayPhase",current) and package_known(current,"getHandcardNum") <= 2 then return "." end
	if package_known(self,"isFriend",current) and (not package_known(self,"willSkipPlayPhase",current) or not package_known(self,"hasZhaxiangEffect",current)) then return "." end
	local target

	local give = {}
	if package_known(self,"needToThrowArmor") then table.insert(give,package_call(self.player,"getArmor"):getEffectiveId()) end
	if #give<1 then
		local allcards = sgs.QList2Table(package_known(self.player,"getCards","he"))
		package_call(self,"sortByKeepValue",allcards)
		table.insert(give,package_known(allcards[1],"getEffectiveId"))
	end
	if #give>0 then
		local card = give[1]
		if disclosed_card(self,card):isRed() then
			for _, friend in ipairs(self.friends_noself) do
				if package_known(current,"inMyAttackRange",friend) then
					target = friend
					break
				end
			end
		else
			for _, friend in ipairs(self.friends_noself) do
				if package_known(current,"inMyAttackRange",friend) then
					for _, enemy in ipairs(self.enemies) do
						if package_known(current,"inMyAttackRange",enemy) then
							target = enemy
							break
						end
					end
				end
			end
		end
	end
	if #give>0 and target then
		return "#sfofl_qupo:"..give[1]..":->"..package_known(target,"objectName")
	end
	return "."
end


sgs.ai_skill_cardask["@sfofl_baoquan"] = function(self,data,pattern)
	local damage = package_known(data,"toDamage")
	if package_known(self,"needToLoseHp",self.player, damage.from, damage.card) then return "." end
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

function sgs.ai_cardneed.sfofl_baoquan(to,card)
	return package_known(card,"isKindOf","TrickCard")
end

sgs.sfofl_baoquan_keep_value = sgs.jizhi_keep_value

local sfofl_horsetailwhisk_skill = {}
sfofl_horsetailwhisk_skill.name = "sfofl_horsetailwhisk"
table.insert(package_skills,sfofl_horsetailwhisk_skill)
sfofl_horsetailwhisk_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = package_known(self.player,"getHandcards")
	cards = package_call(self,"sortByUseValue",cards,true)
	if #cards>0 and (package_known(self,"getOverflow")>0 or package_known(self,"needKongcheng") and #cards<2) then
		package_call(self,"sortByKeepValue",cards)
		local card = cards[math.max(1,math.min(package_known(self.player,"getMaxCards"),#cards))]
		return source_construct(self,"#sfofl_horsetailwhisk:"..package_known(card,"getEffectiveId")..":")
	end
end

ai_card_use["#sfofl_horsetailwhisk"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_view_as.sfofl_horsetailwhisk = function(card,player,card_place,class_name)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place==sgs.Player_PlaceSpecial and package_known(player,"getPile","sfofl_horsetailwhisk"):contains(package_known(card,"getEffectiveId")) and not package_known(card,"hasFlag","using") and package_known(player,"getPile","sfofl_horsetailwhisk"):length() >= 2 then
		if class_name=="Nullification" and package_known(player,"getPile","sfofl_horsetailwhisk"):length() >= 3 then
			return ("nullification:sfofl_horsetailwhisk[%s:%s]=%d"):format(suit,number,card_id)
		elseif class_name=="Jink" and package_known(player,"getPile","sfofl_horsetailwhisk"):length() ~= 3 then
			return ("jink:sfofl_horsetailwhisk[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end

sgs.ai_target_revises.sfofl_plainclothes = function(to,card, self)
	if package_known(card,"isKindOf","Slash") and package_known(to,"getStrategyMark","sfofl_plainclothes-Clear") == 0 and not package_known(self,"hasCrossbowEffect")
	then return true end
end

sgs.ai_skill_discard.sfofl_2_shiyin = function(self)
	local to_discard = {}
	local cards = package_known(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		table.insert(to_discard, package_known(card,"getEffectiveId"))
		return to_discard
	end
	return {}
end
sgs.ai_target_revises.sfofl_quwu = function(to,card)
	if not package_known(to,"getPile","sfofl_noise"):isEmpty() then
        for _, id in sgs.qlist(package_known(to,"getPile","sfofl_noise")) do
			local c = disclosed_card(self,id)
			if package_known(card,"getSuit") == package_known(c,"getSuit")
			then return true end
		end
	end
end
local sfofl_liaozou_skill = {}
sfofl_liaozou_skill.name = "sfofl_liaozou"
table.insert(package_skills, sfofl_liaozou_skill)
sfofl_liaozou_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self.player,"getPile","sfofl_noise"):isEmpty() then return end
	for _, id in sgs.qlist(package_known(self.player,"getPile","sfofl_noise")) do
		local c = disclosed_card(self,id)
		for _, card in sgs.qlist(package_known(self.player,"getHandcards")) do
			if package_known(card,"getSuit") == package_known(c,"getSuit") then
				return
			end
		end
	end
	return source_construct(self,"#sfofl_liaozou:.:")
end

ai_card_use["#sfofl_liaozou"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_priority["sfofl_liaozou"] = 7
sgs.ai_use_value["sfofl_liaozou"] = 7

sgs.ai_view_as.sfofl_tigertally = function(card,player,card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place~=sgs.Player_PlaceSpecial and package_known(card,"isRed") and package_known(card,"isEquipped") and not package_known(card,"hasFlag","using") then
		return ("slash:sfofl_tigertally[%s:%s]=%d"):format(suit,number,card_id)
	end
end

local sfofl_tigertally_skill = {}
sfofl_tigertally_skill.name = "sfofl_tigertally"
table.insert(package_skills,sfofl_tigertally_skill)
sfofl_tigertally_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = package_known(self,"addHandPile","e")
	cards = package_call(self,"sortByUseValue",cards,true)
	local red_card = {}
	local useAll = false
	package_call(self,"sort",self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if package_known(enemy,"getHp")<2 and not package_known(enemy,"hasArmorEffect","EightDiagram")
		and package_known(self.player,"distanceTo",enemy)<=package_known(self.player,"getAttackRange") and package_known(self,"isWeak",enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end

	local disCrossbow = false
	if package_known(self,"getCardsNum","Slash")<2
	or package_known(self.player,"hasSkills","paoxiao|tenyearpaoxiao|olpaoxiao")
	then disCrossbow = true end

	package_call(self,"sort",self.enemies,"defense")

	package_call(self,"sort",self.enemies,"defense")

	for _,card in ipairs(cards)do
		if not isCard("Tigertally",card,self.player) and  (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (not isCard("Crossbow",card,self.player) or disCrossbow)
		and (package_known(self,"getUseValue",card)<sgs.ai_use_value.Slash or inclusive or correct_target(self,"Residue",clone(self))>0)
		then table.insert(red_card,card) end
	end

	for _,card in ipairs(red_card)do
		local slash = clone(self,"slash")
		package_call(slash,"addSubcard",card)
		package_call(slash,"setSkillName","sfofl_tigertally")
		if package_known(slash,"isAvailable",self.player)
		then return slash end
	end
end

ai_skill_invoke.sfofl_qixing = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if package_known(self,"needKongcheng") then return (true) or false end
	if 7 - package_known(self.player,"getHandcardNum") > math.random(1, 3) then return (true) or false end
	return (false) or false
end

sgs.ai_card_priority.sfofl_qixing = function(self,card,v)
	if package_known(self.player,"getStrategyMark","sfofl_qixing")>0 then
		if package_known(self.player,"getStrategyMark","sfofl_qixingCard"..package_known(card,"getTypeId")) == 0 then
			return 10
		end
	end
end

ai_skill_invoke.sfofl_lyre = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_known(data,"toDamage").from
	if target and package_known(self,"doDisCard",target, "he") then return (true) or false end
	return (false) or false
end
sgs.ai_choicemade_filter.cardChosen.sfofl_lyre = sgs.ai_choicemade_filter.cardChosen.snatch


local sfofl_yijue_skill = {}
sfofl_yijue_skill.name = "sfofl_yijue"
table.insert(package_skills,sfofl_yijue_skill)
sfofl_yijue_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self.player,"getKingdom") ~= "shu" then return end
	return source_construct(self,"#sfofl_yijue:.:")
end

ai_card_use["#sfofl_yijue"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies,"handcard")
	local max_card = package_call(self,"getMaxCard")
	if not max_card then return end
	local max_point = package_known(max_card,"getNumber")
	if package_known(self.player,"hasSkill","yingyang") then max_point = math.min(max_point+3,13) end
	if package_known(self.player,"hasSkill","kongcheng") and package_known(self.player,"getHandcardNum")==1 then
		for _,enemy in ipairs(self.enemies)do
			if package_known(self.player,"canPindian",enemy) and package_known(self,"hasLoseHandcardEffective",enemy) and not (package_known(self,"hasTuntianEffect",enemy, true) and package_known(enemy,"getHandcardNum")>2) then
				package_call(self,"setPriorityValue","sfofl_yijue", 1.2,"sfoflCard.source")
				source_state(self).sfofl_yijue_card = package_known(max_card,"getId")
				use.card = card
				package_call(use.to,"append",enemy)
				return
			end
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if package_known(enemy,"getStrategyFlag","AI_HuangtianPindian") and package_known(enemy,"getHandcardNum")==1 and package_known(self.player,"canPindian",enemy) then
			package_call(self,"setPriorityValue","sfofl_yijue", 7.2,"sfoflCard.source")
			source_state(self).sfofl_yijue_card = package_known(max_card,"getId")
			use.card = card
			package_call(use.to,"append",enemy)
			package_call(enemy,"setFlags","-AI_HuangtianPindian")
			return
		end
	end

	local zhugeliang = package_call(self.room,"findPlayerBySkillName","kongcheng")

	package_call(self,"setPriorityValue","sfofl_yijue", 7.2,"sfoflCard.source")
	package_call(self,"sort",self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _,enemy in ipairs(self.enemies)do
		if not (package_known(enemy,"hasSkill","kongcheng") and package_known(enemy,"getHandcardNum")==1) and package_known(self.player,"canPindian",enemy) then
			local enemy_max_card = package_call(self,"getMaxCard",enemy)
			local enemy_max_point = enemy_max_card and package_known(enemy_max_card,"getNumber") or 100
			if enemy_max_card and package_known(enemy,"hasSkill","yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
			if max_point>enemy_max_point then
				source_state(self).sfofl_yijue_card = package_known(max_card,"getId")
				use.card = card
				package_call(use.to,"append",enemy)
				return
			end
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if not (package_known(enemy,"hasSkill","kongcheng") and package_known(enemy,"getHandcardNum")==1) and package_known(self.player,"canPindian",enemy) then
			if max_point>=10 then
				source_state(self).sfofl_yijue_card = package_known(max_card,"getId")
				use.card = card
				package_call(use.to,"append",enemy)
				return
			end
		end
	end

	package_call(self,"setPriorityValue","sfofl_yijue", 1.2,"sfoflCard.source")
	local min_card = package_call(self,"getMinCard")
	if not min_card then return end
	local min_point = package_known(min_card,"getNumber")
	if package_known(self.player,"hasSkill","yingyang") then min_point = math.max(min_point-3,1) end

	local wounded_friends = package_call(self,"getWoundedFriend")
	if #wounded_friends>0 then
		for _,wounded in ipairs(wounded_friends)do
			if package_known(wounded,"getHandcardNum")>1 and package_known(wounded,"getLostHp")/package_known(wounded,"getMaxHp")>=0.3 and package_known(self.player,"canPindian",wounded) then
				local w_max_card = package_call(self,"getMaxCard",wounded)
				local w_max_number = w_max_card and package_known(w_max_card,"getNumber") or 0
				if w_max_card and package_known(wounded,"hasSkill","yingyang") then w_max_number = math.min(w_max_number+3,13) end
				if (w_max_card and w_max_number>=min_point) or min_point<=4 then
					source_state(self).sfofl_yijue_card = package_known(min_card,"getId")
					use.card = card
					package_call(use.to,"append",wounded)
					return
				end
			end
		end
	end

	if zhugeliang and package_known(self,"isFriend",zhugeliang) and package_known(zhugeliang,"getHandcardNum")==1 and package_known(zhugeliang,"objectName")~=package_known(self.player,"objectName")
		and package_known(self.player,"canPindian",zhugeliang) then
		if min_point<=4 then
			source_state(self).sfofl_yijue_card = package_known(min_card,"getId")
			use.card = card
			package_call(use.to,"append",zhugeliang)
			return
		end
		local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
		package_call(self,"sortByUseValue",cards,true)
		if package_known(self,"getEnemyNumBySeat",self.player,zhugeliang)>=1 then
			if isCard("Jink",cards[1],self.player) and package_known(self,"getCardsNum","Jink")==1 then return end
			source_state(self).sfofl_yijue_card = package_known(cards[1],"getId")
			use.card = card
			package_call(use.to,"append",zhugeliang)
			return
		end
	end
end

sgs.ai_skill_pindian.sfofl_yijue = sgs.ai_skill_pindian.yijue

sgs.ai_cardneed.sfofl_yijue = sgs.ai_cardneed.yijue

sgs.ai_card_intention["sfofl_yijue"] = 0
sgs.ai_use_value["sfofl_yijue"] = 8.5


local sfofl_nuchen_skill = {}
sfofl_nuchen_skill.name = "sfofl_nuchen"
table.insert(package_skills,sfofl_nuchen_skill)
sfofl_nuchen_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_nuchen:.:")
end

ai_card_use["#sfofl_nuchen"] = function(self, card, use, request)

	package_call(self,"sort",self.enemies,"handcard")
	for _,p in ipairs(self.enemies)do
		if package_known(self,"damageIsEffective",p, sgs.DamageStruct_Normal) and not package_known(self,"cantbeHurt",p) and not package_known(p,"isKongcheng") then
			use.card = source_construct(self,"#sfofl_nuchen:.:")
			package_call(use.to,"append",p)
			return
		end
	end
end

sgs.ai_use_priority["sfofl_nuchen"] = sgs.ai_use_priority.Slash+0.1
sgs.ai_use_value["sfofl_nuchen"] = 8.5
sgs.ai_skill_cardask["@sfofl_nuchen"] = function(self,data,pattern,target)
	local cards = package_known(self.player,"getCards","h")
	cards = package_call(self,"sortByUseValue",cards,true)
	for i,c in sgs.list(cards)do
		if match_pattern(self,self.player,pattern,c) or package_known(c,"isKindOf",pattern) then
			if package_known(self,"isFriend",target) then
				if package_known(self,"needToLoseHp",target,self.player,nil)
				then else break end
			end
			if i>#cards/2 and isCard("Peach",c,self.player) then
				if not package_known(self,"isWeak",nil,false) or package_known(self,"ajustDamage",self.player,target,1,nil)>1
				then return package_known(c,"getId") end
			else
				return package_known(c,"getId")
			end
		end
	end
	return "."
end

local sfofl_zhiji_skill = {}
sfofl_zhiji_skill.name = "sfofl_zhiji"
table.insert(package_skills, sfofl_zhiji_skill)
sfofl_zhiji_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self.player,"hasUsed","#sfofl_zhiji") then return nil end
	if #self.enemies==0 then return nil end
	return source_construct(self,"#sfofl_zhiji:.:")
end

ai_card_use["#sfofl_zhiji"] = function(self, card, use, request)
	package_call(self,"sort",self.friends,"defense",false)
	package_call(self,"sort",self.enemies,"defense")
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	local to_use = {}
	for _, card in ipairs(cards) do
		table.insert(to_use, package_known(card,"getId"))
		if #to_use == 2 then break end
	end
	if #to_use < 2 then
		return
	end
	for _,p in ipairs(self.enemies) do
		for _,q in ipairs(self.enemies) do
			if package_known(q,"objectName") ~=package_known(p,"objectName") and package_known(p,"canSlash",q,false)
				and package_known(q,"canSlash",p,false) then

				use.card = source_construct(self,"#sfofl_zhiji:".. table.concat(to_use, "+") ..":")
				if use.card and use.to then
					package_call(use.to,"append",p)
					package_call(use.to,"append",q)
				end
				return
			end
		end
	end
	local allplayers = sgs.QList2Table(package_known(self.room,"getOtherPlayers",self.player))
	package_call(self,"sort",allplayers,"defense",false)
	for _,p in ipairs(allplayers) do
		for _,q in ipairs(self.enemies) do
			if package_known(q,"objectName") ~=package_known(p,"objectName")
				and package_known(p,"canSlash",q,false)
				and package_known(q,"canSlash",p,false) then
				use.card = source_construct(self,"#sfofl_zhiji:".. table.concat(to_use, "+") ..":")
				if use.card and use.to then
					package_call(use.to,"append",p)
					package_call(use.to,"append",q)
				end
				return
			end
		end
	end
	return
end
sgs.ai_suppress_intention["sfofl_zhiji"] = true

local sfofl_jiefeng_skill = {}
sfofl_jiefeng_skill.name = "sfofl_jiefeng"
table.insert(package_skills, sfofl_jiefeng_skill)
sfofl_jiefeng_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies==0 then return nil end
	return source_construct(self,"#sfofl_jiefeng:.:")
end

ai_card_use["#sfofl_jiefeng"] = function(self, card, use, request)
	local archery_attack = clone_native(self,"archery_attack")
	package_call(archery_attack,"setSkillName","sfofl_jiefeng")
	package_call(archery_attack,"deleteLater")
	local dummy_use = package_known(self,"aiUseCard",archery_attack, dummy())
	if dummy_use.card then
		local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
		local to_use = {}
		for _, card in ipairs(cards) do
			if not isCard("ArcheryAttack",card,self.player) then
				table.insert(to_use, package_known(card,"getId"))
				if #to_use == 2 then break end
			end
		end
		if #to_use == 2 then
			use.card = source_construct(self,"#sfofl_jiefeng:".. table.concat(to_use, "+") ..":")
			return
		end
	end
end
sgs.ai_use_value["sfofl_jiefeng"] =  sgs.ai_use_value.ArcheryAttack
sgs.ai_use_priority["sfofl_jiefeng"] = sgs.ai_use_priority.ArcheryAttack
sgs.dynamic_value.damage_card["sfofl_jiefeng"] = true

ai_skill_invoke.sfofl_zhonghu = true

sgs.ai_skill_askforag.sfofl_weihou = function(self, card_ids)
	local judge = source_fact(self,"sfofl_weihou","toJudge")
	local cards = {}
	for card_id in ipairs(card_ids) do
		table.insert(cards, disclosed_card(self,card_id))
	end
	local card_id = package_known(self,"getRetrialCardId",cards, judge)
	if card_id ~= -1 then
		return card_id
	end

	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, disclosed_card(self,card_id))
	end
	package_call(self,"sortByUseValue",to_obtain, true)
	return package_known(to_obtain[1],"getEffectiveId")
end

sgs.ai_skill_playerchosen.sfofl_jianwei = function(self, targets)
	package_call(self,"sort",self.enemies, "hp")

	local max = 0
	local target
	for _, enemy in ipairs(self.enemies) do
		if package_known(enemy,"getCardCount") - package_known(self.player,"getCardCount") > max then
			max = package_known(enemy,"getCardCount") - package_known(self.player,"getCardCount")
			target = enemy
		end
	end
	if target and (max + package_known(self.player,"getJudgingArea"):length() - package_known(target,"getJudgingArea"):length() > 2) then
		return target
	end
	return nil
end

ai_skill_invoke.sfofl_mouchuan = true
sgs.ai_skill_playerchosen.sfofl_mouchuan = function(self, targets)
	package_call(self,"sort",self.friends_noself, "handcard")
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local c,to = package_call(self,"getCardNeedPlayer",cards)
	if c and to then
		return to
	end
	for _, friend in ipairs(self.friends_noself) do
		if package_known(self,"canDraw",friend, self.player) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		return friend
	end
	return package_known(targets,"last")
end

sgs.ai_can_damagehp.sfofl_qingsuan = function(self,from,card,to)
	if from and package_known(to,"getHp") + package_known(self,"getAllPeachNum") - package_known(self,"ajustDamage",from, to, 1, card) > 0
		and package_known(self,"canLoseHp",from, card, to)
	then
	return package_known(from,"getKingdom") ~= package_known(to,"getKingdom") and package_known(self,"isEnemy",from) and package_known(from,"getStrategyMark","sfofl_qingsuan"..package_known(to,"objectName")) == 0
	end
end

sgs.ai_skill_discard.sfofl_daohe = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByKeepValue",cards)

	table.insert(to_discard, package_known(cards[1],"getEffectiveId"))
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end


local sfofl_daohe_skill = {}
sfofl_daohe_skill.name = "sfofl_daohe"
table.insert(package_skills,sfofl_daohe_skill)
sfofl_daohe_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_daohe:.:")
end
ai_card_use["#sfofl_daohe"] = function(self, card, use, request)
	local arr1,arr2 = package_call(self,"getWoundedFriend",false,false)
	local target = nil

	if #arr1>0 and (package_known(self,"isWeak",arr1[1]) or package_known(self,"getOverflow")>=1) and package_known(arr1[1],"getHp")<getBestHp(arr1[1]) then target = arr1[1] end
	if target and not package_known(target,"isKongcheng") then
		use.card = card
		package_call(use.to,"append",target)
		return
	end
	if package_known(self,"getOverflow")>0 and #arr2>0 then
		for _,friend in ipairs(arr2)do
			if not package_known(friend,"hasSkills","hunzi|longhun") and not package_known(friend,"isKongcheng") then
				use.card = card
				package_call(use.to,"append",friend)
				return
			end
		end
	end
end

sgs.ai_use_priority["sfofl_daohe"] = 4.2
sgs.ai_card_intention["sfofl_daohe"] = -100

sgs.dynamic_value.benefit["sfofl_daohe"] = true

local sfofl_zhiyiz_skill = {}
sfofl_zhiyiz_skill.name = "sfofl_zhiyiz"
table.insert(package_skills,sfofl_zhiyiz_skill)
sfofl_zhiyiz_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_zhiyiz:.:")
end

ai_card_use["#sfofl_zhiyiz"] = function(self, card, use, request)
	local target
	package_call(self,"sort",self.enemies,"defense")
	if not target then
		for _,enemy in ipairs(self.enemies)do
			if not (package_known(self,"hasSkills",sgs.masochism_skill,enemy) and not package_known(self.player,"hasSkill","jueqing"))
			and package_known(self,"damageIsEffective",enemy,sgs.DamageStruct_Normal,self.player)
			and not package_known(self,"needToLoseHp",enemy)
			then target = enemy end
			if target then break end
		end
		if not target then
			for _,enemy in ipairs(self.enemies)do
				if not (package_known(self,"hasSkills",sgs.masochism_skill,enemy) and not package_known(self.player,"hasSkill","jueqing"))
				and not package_known(enemy,"hasSkills",sgs.cardneed_skill.."|jijiu|tianxiang|buyi")
				and package_known(self,"damageIsEffective",enemy,sgs.DamageStruct_Normal,self.player) and not package_known(self,"cantbeHurt",enemy)
				and not package_known(self,"needToLoseHp",enemy)
				then target = enemy end
				if target then break end
			end
		end
	end

	if target then
		use.card = source_construct(self,"#sfofl_zhiyiz:.:")
		package_call(use.to,"append",target)
	end
end



local sfofl_huxiao_skill = {}
sfofl_huxiao_skill.name = "sfofl_huxiao"
table.insert(package_skills, sfofl_huxiao_skill)
sfofl_huxiao_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local card = disclosed_card(self,package_known(self.player,"getStrategyMark","sfofl_huxiaoskill-Clear"))
	local usable_cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	if package_known(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(package_known(self.player,"getPile","wooden_ox")) do
			table.insert(usable_cards, disclosed_card(self,id))
		end
	end
	package_call(self,"sortByUseValue",usable_cards, true)
	for _,c in ipairs(usable_cards) do
		if package_known(c,"getSuit") == package_known(card,"getSuit") or package_known(c,"getNumber") == package_known(card,"getNumber") then
			local cardex = clone_native(self,package_known(card,"objectName"), package_known(c,"getSuit"), package_known(c,"getNumber"))
			package_call(cardex,"setSkillName","sfofl_huxiao")
			package_call(cardex,"deleteLater")
			if not package_known(self.player,"isCardLimited",cardex, sgs.Card_MethodUse, true) and package_known(cardex,"isAvailable",self.player) then
			local name = package_known(card,"objectName")
			local new_card = source_construct(self,(name..":sfofl_huxiao[%s:%s]=%d"):format(package_known(c,"getSuitString"), package_known(c,"getNumberString"), package_known(c,"getEffectiveId")))
				assert(new_card)
				return new_card
			end
		end
	end
end

sgs.ai_view_as.sfofl_huxiao = function(card, player, card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if package_known(player,"getStrategyMark","sfofl_huxiaoskill-Clear") == 0 then return nil end
	if card_place == sgs.Player_PlaceHand or package_known(player,"getPile","wooden_ox"):contains(card_id) then
		local c = disclosed_card(self,package_known(player,"getStrategyMark","sfofl_huxiaoskill-Clear"))
		local name = package_known(c,"objectName")
		if name and (package_known(card,"getSuit") == package_known(c,"getSuit") or package_known(card,"getNumber") == package_known(c,"getNumber")) then
			return (name..":sfofl_huxiao[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end


local function fangtongca(self,tasum, cards)
	local sum = 0
	local usecards = {}
	if #cards > 30 then
		for _,card in sgs.list(cards) do
			if (package_known(card,"getNumber") + sum) <= tasum then
				table.insert(usecards,package_known(card,"getEffectiveId"))
				sum = sum + package_known(card,"getNumber")
			end
		end
	else
		local n = #cards
		local allcards = {}
		for _,c in sgs.list(cards) do
			table.insert(allcards, package_known(c,"getEffectiveId"))
		end
		for i = 1, 2^n, 1 do
			sum = 0
			usecards = {}
			for j = 1, n, 1 do
				if bit32.band(i,(2^j)) ~= 0 then
					table.insert(usecards,allcards[j])
				end
			end
			for _,id in ipairs(usecards) do
				sum = sum + disclosed_card(self,id):getNumber()
			end
			if sum == tasum then break end
		end
	end

	if sum == tasum then
		return usecards
	else
		return {}
	end
end
sgs.ai_guhuo_card.sfofl_longyin = function(self, toname, class_name)
    if class_name and package_known(self,"getCardsNum",class_name) > 0 then return end
    local c = clone(self,toname)
    if (not c) then return end
	package_call(c,"setSkillName","sfofl_longyin")
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local sum = 0
	for _,c in sgs.list(cards) do
		sum = sum + package_known(c,"getNumber")
	end
	if sum < 13 then return end

	local usecards = {}
	for _,card in ipairs(cards) do
		sum = 0
		local tem = 13 - package_known(card,"getNumber")
		usecards = fangtongca(self,tem,cards)
		if #usecards > 0 then
			table.insert(usecards,package_known(card,"getEffectiveId"))
		end
		for _,c in ipairs(usecards) do
			sum = sum + disclosed_card(self,c):getNumber()
		end
		if sum == 13 then break end
	end
	if sum ~= 13 then return end
    if #usecards > 0 and (package_known(c,"isKindOf","BasicCard") or package_known(c,"isNDTrick")) then
        return "#sfofl_longyin:"..table.concat(usecards, "+") ..":"..toname
    end
end
package_add("sfofl_longyin").getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","sfofl_longyin-Clear") > 0 then return end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local usecards = {}
	local sum = 0
	for _,card in ipairs(cards) do
		sum = 0
		local tem = 13 - package_known(card,"getNumber")
		usecards = fangtongca(self,tem,cards)
		if #usecards > 0 then
			table.insert(usecards,package_known(card,"getEffectiveId"))
		end
		for _,c in ipairs(usecards) do
			sum = sum + disclosed_card(self,c):getNumber()
		end
		if sum == 13 then break end
	end
	if sum ~= 13 then return end
    for c, pn in sgs.list(RandomList(patterns_for(self))) do do
        c = clone(self,pn)
        if c and (package_known(c,"isKindOf","BasicCard") or package_known(c,"isNDTrick")) and package_known(self,"getCardsNum",c) == 0 then
            if package_known(c,"isKindOf","Analeptic") then goto package_continue_1 end
            package_call(c,"setSkillName","sfofl_longyi")

            for _,id in ipairs(usecards) do
				package_call(c,"addSubcard",disclosed_card(self,id))
			end
            if package_known(c,"isAvailable",self.player)
                and package_known(self,"aiUseCard",c).card
            then
                return c
            end
        end
    end ::package_continue_1:: end
end

sgs.ai_ajustdamage_from.sfofl_wushuang = function(self, from, to, card, nature)
    if card and package_known(card,"isKindOf","Slash") and package_known(from,"getStrategyMark","sfofl_xiuluo") > 1 and not package_known(card,"hasFlag","sfofl_wushuang"..package_known(to,"objectName"))
    then
        return 1
    end
end


local sfofl_2_jianshu_skill = {}
sfofl_2_jianshu_skill.name = "sfofl_2_jianshu"
table.insert(package_skills,sfofl_2_jianshu_skill)
sfofl_2_jianshu_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	package_call(self,"sort",self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if package_known(a,"canPindian",b) then
				local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
				package_call(self,"sortByKeepValue",cards)
				for _,c in sgs.list(cards)do
					return source_construct(self,"#sfofl_2_jianshu:"..package_known(c,"getEffectiveId")..":")
				end
			end
		end
	end
end

ai_card_use["#sfofl_2_jianshu"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if package_known(a,"canPindian",b)	then
				use.card = card
				package_call(use.to,"append",a)
				source_state(self).sfofl_2_jianshu = b
				return
			end
		end
	end
end

sgs.ai_use_priority["sfofl_2_jianshu"] = 0
sgs.ai_use_value["sfofl_2_jianshu"] = 2.5
sgs.ai_card_intention["sfofl_2_jianshu"] = 80

sgs.ai_skill_playerchosen.sfofl_2_jianshu = function(self, targets)
	if source_state(self).sfofl_2_jianshu then return source_state(self).sfofl_2_jianshu end
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if package_known(self,"doDisCard",target, "h") and not package_known(self,"isFriend",target) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if package_known(self,"doDisCard",target, "h") then
            return target
        end
    end
    return targets[1]
end

ai_skill_invoke["sfofl_jiufa"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local card = package_known(data,"toCard")
	if package_known(card,"isKindOf","EquipCard") then
		local i = package_known(card,"getRealCard"):toEquipCard():location()
		if package_call(self.player,"getEquip",i) and package_known(self.player,"hasEquipArea",i) and not package_known(self,"doDisCard",self.player, package_call(self.player,"getEquip",i):getEffectiveId()) then
			return (false) or false
		end
	end
	if package_known(card,"isKindOf","DelayedTrick") then
		return (false) or false
	end
	return (true) or false
end

ai_skill_invoke["underhengwu"] = true

sgs.ai_skill_discard.underhengwu = function(self, discard_num, min_num, optional, include_equip, pattern)
	local to_discard = {}
	for _, c in sgs.qlist(package_known(self.player,"getCards","he")) do
		if match_pattern(self,self.player,pattern,c) and package_known(self,"doDisCard",self.player, package_known(c,"getEffectiveId"))	then
			table.insert(to_discard, package_known(c,"getEffectiveId"))
		end
	end
	for _, c in sgs.qlist(package_known(self.player,"getCards","h")) do do
		if match_pattern(self,self.player,pattern,c) and not table.contains(to_discard, package_known(c,"getEffectiveId")) then
			if package_known(self,"getKeepValue",c) > 18 then goto package_continue_2 end
			table.insert(to_discard, package_known(c,"getEffectiveId"))
		end
	end ::package_continue_2:: end
	return to_discard
end

sgs.ai_card_priority.underhengwu = function(self,card,v)
	for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
		if package_known(p,"getEquips"):length() > 0 then
			for _,cc in sgs.qlist(package_known(p,"getEquips")) do
				if package_known(cc,"getSuitString") == package_known(card,"getSuitString") then
					return 10
				end
			end
		end
	end
end

package_add("undershouli").getTurnUseCard = function(self,inclusive,request)
	local cards = {}
  	for i,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
		for d,c in sgs.list(package_known(p,"getCards","ej"))do
			if package_known(c,"isKindOf","OffensiveHorse")
			then table.insert(cards,c) end
		end
	end
	package_call(self,"sortByKeepValue",cards,nil,"l")
  	for _,c in sgs.list(cards)do
		local dc = clone(self)
		package_call(dc,"setSkillName","undershouli")
		package_call(dc,"addSubcard",c)
		local d = package_known(self,"aiUseCard",dc)
		if d.card and d.to
		and package_known(dc,"isAvailable",self.player)
		then
			source_state(self).undershouli_to = d.to
			package_call(self,"setPriorityValue","undershouli", sgs.ai_use_priority.Slash+0.6,"sfoflCard.source")
			return source_construct(self,"#undershouli:"..package_known(c,"getEffectiveId")..":slash")
		end
	end
end

ai_card_use["undershouli"] = function(self, card, use, request)
	if source_state(self).undershouli_to
	then
		use.card = card
		use.to = source_state(self).undershouli_to
	end
end

sgs.ai_use_value.undershouli = 5.4
sgs.ai_use_priority.undershouli = 2.8


sgs.ai_card_priority.undershouli = function(self,card)
	if table.contains(package_known(card,"getSkillNames"), "undershouli")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_guhuo_card.undershouli = function(self,toname,class_name)
	local cards = {}
  	for _,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
		for _,c in sgs.list(package_known(p,"getCards","ej"))do
			if package_known(c,"isKindOf","OffensiveHorse") and class_name=="Slash"
			or package_known(c,"isKindOf","DefensiveHorse") and class_name=="Jink"
			then table.insert(cards,c) end
		end
	end
	package_call(self,"sortByKeepValue",cards,nil,"l")
  	for _,c in sgs.list(cards)do
		if package_known(self,"getCardsNum",class_name)>0 then break end
		return "#undershouli:"..package_known(c,"getEffectiveId")..":"..toname
	end
end






sgs.ai_ajustdamage_from.sfofl_tuodao = function(self, from, to, card, nature)
    if card and package_known(card,"isKindOf","Slash") and package_known(card,"isRed")
    then
        return 1
    end
end

function sgs.ai_cardsview.sfofl_baye(self,class_name,player)
	local c = clone(self)
	package_call(c,"setSkillName","sfofl_baye")
	local newcards = {}
	for _,c in sgs.list(owner_ai(self,player):addHandPile())do do
		if isCard("ExNihilo",c,player) and package_known(player,"getPhase")<=sgs.Player_Play
		or isCard("Peach",c,player) then goto package_continue_3 end
		if isCard("Slash",c,player) then return end
		table.insert(newcards,c)
	end ::package_continue_3:: end
	owner_ai(self,player):sortByKeepValue(newcards,nil,true)
	for _,h in sgs.list(newcards)do
		if package_known(c,"subcardsLength")<2
		then package_call(c,"addSubcard",h) end
	end
	if package_known(c,"subcardsLength")>=2
	then package_call(c,"setSuit",sgs.Card_NoSuitRed) return package_known(c,"toString") end
end

local sfofl_baye_skill = {}
sfofl_baye_skill.name = "sfofl_baye"
table.insert(package_skills,sfofl_baye_skill)
sfofl_baye_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local newcards = {}
	local cards = package_known(self,"addHandPile")
	cards = package_call(self,"sortByUseValue",cards,nil,true)
	for _,card in sgs.list(cards)do do
		if isCard("Peach",card,self.player)
		or isCard("ExNihilo",card,self.player) and package_known(self.player,"getPhase")<=sgs.Player_Play
		then goto package_continue_4 end
		table.insert(newcards,card)
	end ::package_continue_4:: end
	if #newcards<2
	or #cards<package_known(self.player,"getHp") and package_known(self.player,"getHp")<5
	and not package_known(self,"needKongcheng") then return end
	local slashs = {}
	local newcards2 = InsertList({},newcards)
	for _,c1 in sgs.list(newcards)do
		if #slashs>#newcards/2 or #slashs>3 then break end
		table.removeOne(newcards2,c1)
		for _,c2 in sgs.list(newcards2)do
			local dc = source_construct(self,"slash:sfofl_baye[no_suit_red:0]="..package_known(c1,"getId").."+"..package_known(c2,"getId"))
			if package_known(dc,"isAvailable",self.player) then table.insert(slashs,dc) end
		end
	end
	return #slashs>0 and slashs
end


ai_skill_use["@@sfofl_boss_wenjiu"]=function(self,prompt,request)
	if package_known(self.player,"getPile","sfofl_boss_wuhun"):length() > 0 then
		local red = 0
		local black = 0

		for _,id in sgs.qlist(package_known(self.player,"getPile","sfofl_boss_wuhun")) do
			local c = disclosed_card(self,id)
			if package_known(c,"isBlack") then
				black = black + 1
			else
				red = red + 1
			end
		end
		local cards = {}
		if red > black then
			for _, id in sgs.qlist(package_known(self.player,"getPile","sfofl_boss_wuhun")) do
				if disclosed_card(self,id):isBlack() then
					table.insert(cards, disclosed_card(self,id))
				end
			end
		else
			for _, id in sgs.qlist(package_known(self.player,"getPile","sfofl_boss_wuhun")) do
				if disclosed_card(self,id):isRed() then
					table.insert(cards, disclosed_card(self,id))
				end
			end
		end
		if #cards == 0 then
			local suits = {}
			local maxnum, maxsuit = 0, nil
			for _,id in sgs.qlist(package_known(self.player,"getPile","sfofl_boss_wuhun")) do
				local c = disclosed_card(self,id)
				if not suits[package_known(c,"getSuitString")] then suits[package_known(c,"getSuitString")] = 1 else suits[package_known(c,"getSuitString")] = suits[package_known(c,"getSuitString")] + 1 end
				if suits[package_known(c,"getSuitString")] > maxnum then
					maxnum = suits[package_known(c,"getSuitString")]
					maxsuit = package_known(c,"getSuit")
				end
			end
			for _,id in sgs.qlist(package_known(self.player,"getPile","sfofl_boss_wuhun")) do
				local c = disclosed_card(self,id):getSuit()
				if c ~= maxsuit then
					table.insert(cards, disclosed_card(self,id))
				end
			end
		end
		package_call(self,"sortByUseValue",cards)
		local give_all_cards = {}
		local max = 3
		for _, c in ipairs(cards) do
			if #give_all_cards < max then
				table.insert(give_all_cards, package_known(c,"getEffectiveId"))
			end
		end
		if #give_all_cards < max then
			for _,id in sgs.qlist(package_known(self.player,"getPile","sfofl_boss_wuhun")) do
				if #give_all_cards == 0 or not table.contains(give_all_cards, disclosed_card(self,id)) then
					table.insert(give_all_cards, id)
				end
				if #give_all_cards >= max then
					break
				end
			end
		end
		if #give_all_cards > 0 then
			local card_str = string.format("#sfofl_boss_wenjiu:%s:", table.concat(give_all_cards, "+"))
			return card_str
		end
	end

	return "."
end

sgs.ai_view_as.sfofl_boss_wusheng = function(card,player,card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	local red = 0
	local black = 0
	if not package_known(player,"getPile","sfofl_boss_wuhun"):isEmpty() then
		for _,id in sgs.qlist(package_known(player,"getPile","sfofl_boss_wuhun")) do
			local c = disclosed_card(self,id)
			if package_known(c,"isBlack") then
				black = black + 1
			else
				red = red + 1
			end
		end
		if red > black and card_place~=sgs.Player_PlaceSpecial and package_known(card,"isRed") and not package_known(card,"isKindOf","Peach") and not package_known(card,"hasFlag","using") then
			return ("slash:sfofl_boss_wusheng[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end

local sfofl_boss_wusheng_skill = {}
sfofl_boss_wusheng_skill.name = "sfofl_boss_wusheng"
table.insert(package_skills,sfofl_boss_wusheng_skill)
sfofl_boss_wusheng_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self.player,"getPile","sfofl_boss_wuhun"):isEmpty() then return end
	local cards = package_known(self,"addHandPile","he")
	cards = package_call(self,"sortByUseValue",cards,true)

	local red = 0
	local black = 0

	for _,id in sgs.qlist(package_known(self.player,"getPile","sfofl_boss_wuhun")) do
		local c = disclosed_card(self,id)
		if package_known(c,"isBlack") then
			black = black + 1
		else
			red = red + 1
		end
	end
	if red > black then
		local red_card = {}
		local useAll = false
		package_call(self,"sort",self.enemies,"defense")
		for _,enemy in ipairs(self.enemies)do
			if package_known(enemy,"getHp")<2 and not package_known(enemy,"hasArmorEffect","EightDiagram")
			and package_known(self.player,"distanceTo",enemy)<=package_known(self.player,"getAttackRange") and package_known(self,"isWeak",enemy)
			and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
			then useAll = true break end
		end

		local disCrossbow = false
		if package_known(self,"getCardsNum","Slash")<2
		or package_known(self.player,"hasSkills","paoxiao|tenyearpaoxiao|olpaoxiao")
		then disCrossbow = true end


		for _,card in ipairs(cards)do
			if package_known(card,"isRed") and not package_known(card,"isKindOf","Slash")
			and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
			and (not isCard("Crossbow",card,self.player) or disCrossbow)
			and (package_known(self,"getUseValue",card)<sgs.ai_use_value.Slash or inclusive or correct_target(self,"Residue",clone(self))>0)
			then table.insert(red_card,card) end
		end


		for _,card in ipairs(red_card)do
			local slash = clone(self,"slash")
			package_call(slash,"addSubcard",card)
			package_call(slash,"setSkillName","sfofl_boss_wusheng")
			if package_known(slash,"isAvailable",self.player)
			then return slash end
		end
	elseif black > red then
		local cards = package_known(self,"addHandPile","he")
		local black_card
		package_call(self,"sortByUseValue",cards,true)
		local has_weapon = false
		for _,card in ipairs(cards)  do
			if package_known(card,"isKindOf","Weapon") and package_known(card,"isBlack") then has_weapon=true end
		end
		for _,card in ipairs(cards)  do
			if package_known(card,"isBlack") and ((package_known(self,"getUseValue",card)<sgs.ai_use_value.Dismantlement) or inclusive or package_known(self,"getOverflow")>0) then
				local shouldUse = true
				if package_known(card,"isKindOf","Armor") then
					if not package_call(self.player,"getArmor") then shouldUse = false
					elseif package_known(self.player,"hasEquip",card) and not package_known(self,"needToThrowArmor") then shouldUse = false
					end
				end
				if package_known(card,"isKindOf","Weapon") then
					if not package_call(self.player,"getWeapon") then shouldUse = false
					elseif package_known(self.player,"hasEquip",card) and not has_weapon then shouldUse = false
					end
				end
				if package_known(card,"isKindOf","Slash") then
					local dummy_use = dummy()
					if package_known(self,"getCardsNum","Slash")==1 then
						package_call(self,"useBasicCard",card,dummy_use)
						if dummy_use.card then shouldUse = false end
					end
				end
				if package_known(self,"getUseValue",card)>sgs.ai_use_value.Dismantlement and package_known(card,"isKindOf","TrickCard") then
					local dummy_use = package_known(self,"aiUseCard",card, dummy())
					if dummy_use.card then shouldUse = false end
				end
				if shouldUse then
					black_card = card
					break
				end
			end
		end
		if black_card then
			local suit = package_known(black_card,"getSuitString")
			local number = package_known(black_card,"getNumberString")
			local card_id = package_known(black_card,"getEffectiveId")
			local card_str = ("dismantlement:sfofl_boss_wusheng[%s:%s]=%d"):format(suit,number,card_id)
			local dismantlement = source_construct(self,card_str)
			assert(dismantlement)
			return dismantlement
		end
	end
end

function sgs.ai_cardneed.sfofl_boss_wusheng(to,card)
	return package_known(to,"getHandcardNum")<3
end

sgs.ai_card_priority.sfofl_boss_feijun = function(self,card,v)
	local record = source_property(self,"sfofl_boss_feijunRecords"):toString()
	local suit = package_known(card,"getSuitString")
	local records
	if (record) then
		records = package_known(record,"split",",")
	end
	if records and (table.contains(records, suit) ) then

	else
		for _, equip in sgs.qlist(package_known(self.player,"getEquips")) do
			if package_known(equip,"getSuit") == package_known(card,"getSuit") then
				return 10
			end
		end
	end
end
sgs.ai_cardneed.sfofl_boss_wushuang = sgs.ai_cardneed.slash
sgs.ai_ajustdamage_from.sfofl_boss_wushuang = function(self, from, to, card, nature)
    if card and package_known(card,"isKindOf","Slash")
    then
        return 1
    end
end

sgs.hit_skill = sgs.hit_skill .. "|sfofl_boss_wushuang"
sgs.ai_card_priority.sfofl_boss_hanzhan_2 = function(self,card,v)
	for _,id in sgs.qlist(package_known(self.player,"getPile","sfofl_boss_zhanyi")) do
		if package_known(card,"getSuit") == disclosed_card(self,id):getSuit() then
			return 10
		end
	end
end

ai_skill_use["sfofl_boss_wushuang-jink"]=function(self,prompt,request)
	local data = source_tag(self,"sfofl_boss_wushuang")
	return sgs.ai_skill_cardask["slash-jink"](self,data,"jink",package_known(data,"toCardEffect").from)
end

local sfofl_boss_xiuluo_skill = {}
sfofl_boss_xiuluo_skill.name = "sfofl_boss_xiuluo"
table.insert(package_skills, sfofl_boss_xiuluo_skill)
sfofl_boss_xiuluo_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local card_str = "#sfofl_boss_xiuluo:.:"
	local skillcard = source_construct(self,card_str)

	return skillcard
end
ai_card_use["#sfofl_boss_xiuluo"]=function(self, card, use, request)
	local useable_cards = {}
	if package_known(self.player,"getPile","sfofl_boss_zhanyi"):length() >= 3 then
		for _, id in sgs.qlist(package_known(self.player,"getPile","sfofl_boss_zhanyi")) do
			table.insert(useable_cards, disclosed_card(self,id))
		end
	end
	if #useable_cards == 0 then return end
	local card_str = string.format("#sfofl_boss_xiuluo:%s:", package_known(useable_cards[1],"getEffectiveId"))
	local acard = source_construct(self,card_str)
	use.card = acard
	return
end
sgs.ai_skill_playerchosen.sfofl_boss_xiuluo = function(self, targets)
    targets = sgs.QList2Table(targets)
	if package_known(self.player,"getStrategyFlag","sfofl_boss_xiuluo_Discard_handcard") then
		for _, target in ipairs(targets) do
			if package_known(self,"doDisCard",target, "h") then
				return target
			end
		end
	end
    for _, target in ipairs(targets) do
        if package_known(self,"doDisCard",target, "e") then
            return target
        end
    end
    return nil
end

ai_skill_choice["sfofl_boss_xiuluo"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	if table.contains(items, "sfofl_boss_xiuluo_Discard_handcard") then
		package_known(self.room,"setPlayerFlag",self.player, "sfofl_boss_xiuluo_Discard_handcard")
		local targets_3 = sgs.SPlayerList()
        for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
            if package_known(self.player,"canDiscard",p, "h") and not package_known(p,"isKongcheng") then
                package_call(targets_3,"append",p)
            end
        end
        if not package_known(targets_3,"isEmpty") then
			local target = sgs.ai_skill_playerchosen.sfofl_boss_xiuluo(self, targets_3)
			package_known(self.room,"setPlayerFlag",self.player, "-sfofl_boss_xiuluo_Discard_handcard")
            if target ~= nil then
				return ai_choice_result(("sfofl_boss_xiuluo_Discard_handcard"), options)
			end
        end
	end
	if table.contains(items, "sfofl_boss_xiuluo_Discard_equip") then
		local targets_3 = sgs.SPlayerList()
        for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
            if package_known(self.player,"canDiscard",p, "h") and not package_known(p,"isKongcheng") then
                package_call(targets_3,"append",p)
            end
        end
        if not package_known(targets_3,"isEmpty") then
			local target = sgs.ai_skill_playerchosen.sfofl_boss_xiuluo(self, targets_3)
			if target ~= nil then
				return ai_choice_result(("sfofl_boss_xiuluo_Discard_equip"), options)
			end
		end
	end
	return ai_choice_result(("sfofl_boss_xiuluo_Draw"), options)
end

sgs.ai_cardneed.sfofl_boss_shayi = sgs.ai_cardneed.slash


ai_skill_use["@@sfofl_boss_shajue"]=function(self,prompt,request)
	if package_known(self.player,"getPile","sfofl_boss_shayi"):length() > 0 then
		local cards = {}
		for _, id in sgs.qlist(package_known(self.player,"getPile","sfofl_boss_shayi")) do
			table.insert(cards, disclosed_card(self,id))
		end
		package_call(self,"sortByUseValue",cards)
		local give_all_cards = {}
		local max = 3
		for _, c in ipairs(cards) do
			if #give_all_cards < max then
				table.insert(give_all_cards, package_known(c,"getEffectiveId"))
			end
		end
		if #give_all_cards > 0 then
			local card_str = string.format("#sfofl_boss_shajue:%s:", table.concat(give_all_cards, "+"))
			return card_str
		end
	end

	return "."
end

ai_skill_invoke.sfofl_boss_numu = true

sgs.ai_skill_playerchosen.sfofl_boss_shajue = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if package_known(self,"doDisCard",target, "he", true) then
            return target
        end
    end
    return nil
end
ai_skill_invoke.sfofl_yanmouz = true
sgs.ai_skill_askforag.sfofl_yanmouz = function(self,card_ids)
	for _,id in sgs.list(card_ids)do
		if #package_known(self,"poisonCards",{id})<1 then
			return id
		end
	end
	return -1
end


local sfofl_zhanyan_skill = {}
sfofl_zhanyan_skill.name = "sfofl_zhanyan"
table.insert(package_skills, sfofl_zhanyan_skill)
sfofl_zhanyan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies==0 then return nil end
	return source_construct(self,"#sfofl_zhanyan:.:")
end

ai_card_use["#sfofl_zhanyan"] = function(self, card, use, request)
	local good = 2
	local x = 0
	for _, id in sgs.qlist(package_known(self.room,"getDiscardPile")) do
		if disclosed_card(self,id):isKindOf("FireSlash") or disclosed_card(self,id):isKindOf("FireAttack") then
			x = x + 1
		end
	end
	for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
		if package_known(self.player,"inMyAttackRange",p) then
			if package_known(self,"needToLoseHp",p, self.player, nil) and package_known(self,"canDamageHp",self.player,nil,p) and package_known(self,"damageIsEffective",p, sgs.DamageStruct_Fire) and not package_known(self,"cantbeHurt",p) then
				if package_known(self,"isFriend",p) then
					good = good + 1
				elseif package_known(self,"isEnemy",p) then
					good = good - 1
				end
			else
				if package_known(self,"isFriend",p) then
					if x > 0 then
						good = good + 1
						x = x - 1
					else
						good = good - 1
					end
				elseif package_known(self,"isEnemy",p) then
					if x > 0 then
						good = good - 1
						x = x - 1
					else
						good = good + 1
					end
				end
			end

		end
	end
	if good > 0 then
		use.card = source_construct(self,"#sfofl_zhanyan:.:")
		return
	end
end
sgs.ai_skill_cardask["@sfofl_zhanyan"] = function(self,data,pattern)
	local target = package_call(data,"toPlayer")
	if package_known(self,"isFriend",target) then
		local x = 0
		for _, id in sgs.qlist(package_known(self.room,"getDiscardPile")) do
			if disclosed_card(self,id):isKindOf("FireSlash") or disclosed_card(self,id):isKindOf("FireAttack") then
				x = x + 1
			end
		end
		if x > 0 then
			return "."
		end
	end
	if package_known(self,"needToLoseHp",self.player, target, nil) or not package_known(self,"damageIsEffective",self.player, sgs.DamageStruct_Fire) then return "." end
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
sgs.ai_skill_askforag.sfofl_zhanyan = function(self,card_ids)
	local target = source_fact(self,"sfofl_zhanyan","toPlayer")
	if package_known(self,"needToLoseHp",self.player, target, nil)  or not package_known(self,"damageIsEffective",self.player, sgs.DamageStruct_Fire) then return -1 end
	for _,id in sgs.list(card_ids)do
		return id
	end
	return -1
end



sgs.ai_ajustdamage_to.sfofl_yuhuo = function(self,from,to,slash,nature)
	if nature == "F"
	then return -99 end
end
ai_skill_invoke.sfofl_diwan = true

sgs.ai_cardneed.sfofl_suiluan = sgs.ai_cardneed.slash
sgs.ai_skill_playerschosen.sfofl_suiluan = function(self, targets, max, min)
	local use = source_fact(self,"sfofl_suiluan","toCardUse")
	local dummy_use = package_known(self,"aiUseCard",use.card, dummy(true, 2, use.to))
	local enemy = sgs.SPlayerList()
	if dummy_use.card and package_known(dummy_use.to,"length") > 0 then
		for _, p in sgs.qlist(dummy_use.to) do
			if package_known(self,"isEnemy",p) and package_known(targets,"contains",p) then
				package_call(enemy,"append",p)
				if package_known(enemy,"length") >= max then
					break
				end
			end
		end
	end
	return enemy
end


ai_skill_use["@@sfofl_longsong"]=function(self,prompt,request)
    if #self.friends_noself <= 0 then return "." end
    package_call(self,"sort",self.friends_noself, "defense")
	local card
	local can_invoke = false
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
    if (not target) then return "." end
    if (not target) then target = self.friends_noself[1] end

	if target then
		for _, card in sgs.qlist(package_known(target,"getCards","he")) do
			if package_known(card,"isRed") then
				can_invoke = true
			end
		end
	end
	if can_invoke then
		local card_str = string.format("#sfofl_longsong:.:->%s", package_known(target,"objectName"))
    	return card_str
	else
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
		local card_str = string.format("#sfofl_longsong:%s:->%s", package_known(card,"getEffectiveId"), package_known(target,"objectName"))
    	return card_str
	end



    return nil
end

local sfofl_fuli_skill = {}
sfofl_fuli_skill.name = "sfofl_fuli"
table.insert(package_skills, sfofl_fuli_skill)
sfofl_fuli_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

    if package_known(self.player,"isNude") then return end
    if package_known(self.player,"hasUsed","#sfofl_fuli") then return end
    return source_construct(self,"#sfofl_fuli:.:")
end

ai_card_use["#sfofl_fuli"] = function(self, card, use, request)
	use.card = card
end

ai_skill_choice.sfofl_fuli = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    local items = package_known(choices,"split","+")
    if #items == 1 then return ai_choice_result((items[1]), options) end
    table.removeOne(items, "BasicCard")
    return ai_choice_result((items[math.random(1,#items)]), options)
end

sgs.ai_skill_playerchosen.sfofl_fuli = function(self, targets)
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

sgs.ai_playerchosen_intention.sfofl_fuli = 40

ai_skill_choice.sfofl_dehua = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    local items = package_known(choices,"split","+")
    if #items == 1 then return ai_choice_result((items[1]), options) end
    table.removeOne(items, "slash")
    for _,item in ipairs(items) do
        local card = clone_native(self,item, sgs.Card_SuitToBeDecided, -1)
        package_call(card,"deleteLater")
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        package_call(self,"useCardByClassName",card, usec)
        if usec.card then
            return ai_choice_result((item), options)
        end
    end
    return ai_choice_result((items[math.random(1,#items)]), options)
end

ai_skill_choice.sfofl_dehua_slash = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    return ai_choice_result(("slash"), options)
end

ai_skill_use["@@sfofl_dehua"]=function(self,prompt,request)
    local pattern = source_property(self,"sfofl_dehua_card"):toString()
	local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
    package_call(card,"setSkillName","sfofl_dehua")
    package_call(card,"deleteLater")

    if package_known(card,"targetFixed") then
        return string.format("#sfofl_dehua:.:%s",pattern)
    end

    local usec = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, usec)
    if usec.card then
        if package_known(usec.to,"length") > 0 then
            local tos = {}
            for _,to in sgs.qlist(usec.to) do
                table.insert(tos, package_known(to,"objectName"))
            end
            return string.format("#sfofl_dehua:.:%s->%s",pattern, table.concat(tos, "+"))
        else
            return string.format("#sfofl_dehua:.:%s",pattern)
        end
    end
end






sgs.ai_skill_playerchosen.sfofl_langxi = function(self,targets)
	local tos = package_known(self,"findPlayerToDamage",2,self.player,"N",targets)
	if #tos>0 then
		for _,p in ipairs(tos)do do
			if package_known(self,"cantDamageMore",self.player,p) or package_known(self,"isFriend",p) then goto package_continue_5 end
			return p
		end ::package_continue_5:: end
		for _,p in ipairs(tos)do do
			if package_known(self,"isFriend",p) then goto package_continue_6 end
			return p
		end ::package_continue_6:: end
	end
	package_call(self,"sort",self.enemies,"hp")
	for _,enemy in ipairs(self.enemies)do
		if package_known(enemy,"getHp")<=package_known(self.player,"getHp")
		and package_known(self,"damageIsEffective",enemy)
		and not package_known(self,"cantDamageMore",self.player,enemy)
		then return enemy end
	end
	for _,enemy in ipairs(self.enemies)do
		if package_known(enemy,"getHp")<=package_known(self.player,"getHp")
		and package_known(self,"damageIsEffective",enemy)
		then return enemy end
	end
end

package_add("sfofl_sancai").getTurnUseCard = function(self,inclusive,request)
	package_call(self,"setPriorityValue","sfofl_sancai", 0.8,"sfoflCard.source")
	source_state(self).yjzy_to = nil
	local hand = package_known(self.player,"getHandcards")
	local can_invoke = true
	for _, card in sgs.qlist(hand) do
		for _, card2 in sgs.qlist(hand) do
			if card ~= card2 and package_known(card,"getTypeId") ~= package_known(card2,"getTypeId") then
				can_invoke = false
				break
			end
		end
	end
	if not can_invoke then return end
	return source_construct(self,"#sfofl_sancai:.:")
end

ai_card_use["#sfofl_sancai"] = function(self, card, use, request)
	for _,c in sgs.list(package_call(self,"sortByKeepValue",package_known(self.player,"getHandcards")))do do
		if package_known(c,"isKindOf","Slash") then
			if table.contains(self.toUse,c)
			or package_known(self,"getCardsNum","Slash")<2 and package_known(self,"getOverflow")<1
			then goto package_continue_7 end
			source_state(self).yjzy_to = package_call(self,"AlPresentCardTo",c)
		elseif package_known(c,"isKindOf","Jink") then
			if package_known(self,"getCardsNum","Jink","h")<1 then goto package_continue_7 end
			source_state(self).yjzy_to = package_call(self,"AlPresentCardTo",c)
		elseif package_known(c,"isKindOf","Peach") then
			if package_known(self,"getCardsNum","Peach")<2
			and table.contains(self.toUse,c)
			then goto package_continue_7 end
			source_state(self).yjzy_to = package_call(self,"AlPresentCardTo",c)
		elseif package_known(c,"isKindOf","Poison") then
			local can = package_known(self,"isWeak") and math.random()<0.97
			local n = package_known(self,"getOverflow")
			if n>0 then
				n = package_known(self,"askForDiscard","Poison",n,n,false,false)
				if table.contains(n,package_known(c,"getId")) then can = false end
			end
			if can then goto package_continue_7 end
			if package_known(self.player,"hasArmorEffect","yj_yinfengyi")
			and (package_known(self.player,"getHp")<4 or package_known(self.player,"getMaxCards")>=package_known(self.player,"getHandcardNum")/2)
			and math.random()<0.9 then goto package_continue_7 end
			source_state(self).yjzy_to = package_call(self,"AlPresentCardTo",c,true)
			package_call(self,"setPriorityValue","sfofl_sancai", 0.8,"sfoflCard.source")
		elseif package_known(c,"isKindOf","Qixingbaodao")
		then source_state(self).yjzy_to = package_call(self,"AlPresentCardTo",c,true) or package_call(self,"AlPresentCardTo",c)
		elseif package_known(c,"isKindOf","EquipCard") then
			if table.contains(self.toUse,c) then goto package_continue_7 end
			local enemie = sgs.ai_poison_card[package_known(c,"objectName")] or package_known(self,"evaluateArmor",c)<-5
			source_state(self).yjzy_to = package_call(self,"AlPresentCardTo",c,enemie)
			package_call(self,"setPriorityValue","sfofl_sancai", 8,"sfoflCard.source")
		else
			if table.contains(self.toUse,c) then goto package_continue_7 end
			source_state(self).yjzy_to = package_call(self,"AlPresentCardTo",c,sgs.ai_poison_card[package_known(c,"objectName")])
		end
		if not source_state(self).yjzy_to or package_known(self.player,"getStrategyFlag",source_state(self).package_known(yjzy_to,"objectName").."yj_zhengyuUse"..package_known(c,"getId")) then goto package_continue_7 end
		use.card = card
	end ::package_continue_7:: end
end

sgs.ai_use_value.sfofl_sancai = 5.4
sgs.ai_use_priority.sfofl_sancai = 0.8

ai_skill_use["@@sfofl_sancai"]=function(self,prompt,request)
	if source_state(self).yjzy_to then
		for _,c in sgs.list(package_call(self,"sortByKeepValue",package_known(self.player,"getHandcards")))do
			package_call(self.player,"setFlags",source_state(self).package_known(yjzy_to,"objectName").."yj_zhengyuUse"..package_known(c,"getEffectiveId"))
			return "#yj_zhengyuCard:"..package_known(c,"getId")..":->"..source_state(self).package_known(yjzy_to,"objectName")
		end
	end
	package_call(self,"sort",self.friends_noself, "defense", true)
	for _,friend in ipairs(self.friends_noself) do
		for _,c in sgs.list(package_call(self,"sortByKeepValue",package_known(self.player,"getHandcards")))do
			if package_known(c,"isKindOf","TrickCard") then
				return "#yj_zhengyuCard:"..package_known(c,"getId")..":->"..package_known(friend,"objectName")
			end
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) and not package_known(self,"cantbeHurt",enemy) then
			for _,c in sgs.list(package_call(self,"sortByKeepValue",package_known(self.player,"getHandcards")))do
				if package_known(c,"isKindOf","Weapon") then
					return "#yj_zhengyuCard:"..package_known(c,"getId")..":->"..package_known(enemy,"objectName")
				end
			end
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if package_known(self,"doDisCard",enemy, "he", true) then
			for _,c in sgs.list(package_call(self,"sortByKeepValue",package_known(self.player,"getHandcards")))do
				if package_known(c,"isKindOf","EquipCard") then
					return "#yj_zhengyuCard:"..package_known(c,"getId")..":->"..package_known(enemy,"objectName")
				end
			end
		end
	end
end

ai_skill_invoke.sfofl_xiandao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local move = package_known(data,"toMoveOneTime")
	local target = package_call(self.room,"findPlayerByObjectName",package_known(move.to,"objectName"))
	local ids = {}
	for _,id in sgs.list(move.card_ids)do
		if foreign_fact(self,move.to,"PresentCard","toString")==tostring(id)
		then table.insert(ids,id) end
	end
	if #ids>0 then
		local c = disclosed_card(self,ids[1])
		if package_known(c,"isKindOf","TrickCard") then
			return (true) or false
		elseif package_known(c,"isKindOf","EquipCard") then
			if package_known(c,"isKindOf","Weapon") then
				return (package_known(self,"damageIsEffective",target, sgs.DamageStruct_Normal) and ((not package_known(self,"cantbeHurt",target) and package_known(self,"isEnemy",target)) or (package_known(self,"isFriend",target) and package_known(self,"needToLoseHp",target, self.player)))) or false
			end
			return (package_known(self,"doDisCard",target, "he", true)) or false
		end
	end
    return (package_known(self,"isEnemy",target)) or false
end



sgs.ai_skill_playerchosen.sfofl_yibing = function(self,targets)
	local move = source_fact(self,"sfofl_yibing","toMoveOneTime")
	local ids = sgs.IntList()
	for _,id in sgs.qlist(move.card_ids) do
		if package_known(self.room,"getCardOwner",id) == self.player and package_known(self.room,"getCardPlace",id) == sgs.Player_PlaceHand then
			package_call(ids,"append",id)
		end
	end
	if package_known(ids,"length") > 2 then return nil end
	local slash = clone_native(self,"slash", sgs.Card_SuitToBeDecided, -1)
	package_call(slash,"deleteLater")
	package_call(slash,"setSkillName","sfofl_yibing")
	package_call(slash,"addSubcards",ids)
	local dummy_use = package_known(self,"aiUseCard",slash, dummy())
    if dummy_use.card and dummy_use.to and package_known(dummy_use.to,"length") > 0 then
        for _,to in sgs.qlist(dummy_use.to) do
			return to
		end
	end
	return nil
end
sgs.ai_cardneed.sfofl_shuangren = sgs.ai_cardneed.bignumber
local sfofl_shuangren_skill = {}
sfofl_shuangren_skill.name = "sfofl_shuangren"
table.insert(package_skills,sfofl_shuangren_skill)
sfofl_shuangren_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self,"needBear") then return end
	return source_construct(self,"#sfofl_shuangren:.:")
end

ai_card_use["#sfofl_shuangren"] = function(self, card, use, request)
	local max_card = package_call(self,"getMaxCard")
	local max_point = package_known(max_card,"getNumber")

	if #self.enemies==0 then return end
	package_call(self,"sort",self.enemies,"handcard")
	local slash = clone(self)
	local dummy_use = dummy()
	package_call(self,"withOwnerRange","slashNoDistanceLimit","#sfofl_shuangren",function() package_call(self,"useBasicCard",slash,dummy_use) end)

	if dummy_use.card then
		for _,enemy in sgs.list(self.enemies)do
			if package_known(self.player,"canPindian",enemy) then
				local enemy_max_card = package_call(self,"getMaxCard",enemy)
				local allknown = 0
				if package_known(self,"getKnownNum",enemy)==package_known(enemy,"getHandcardNum") then
					allknown = allknown+1
				end
				if (enemy_max_card and max_point>package_known(enemy_max_card,"getNumber") and allknown>0)
					or (enemy_max_card and max_point>package_known(enemy_max_card,"getNumber") and allknown<1 and max_point>10)
					or (not enemy_max_card and max_point>10) then
					source_state(self).sfofl_shuangren_card = package_known(max_card,"getEffectiveId")
					use.card = source_construct(self,"#sfofl_shuangren:.:")
					package_call(use.to,"append",enemy)
					return

				end
			end
		end
	end
end

sgs.ai_skill_playerchosen["sfofl_shuangren"] = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_use_priority.sfofl_shuangren = 3


sgs.ai_view_as.sfofl_lizhen = function(card,player,card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place==sgs.Player_PlaceEquip and not package_known(card,"hasFlag","using") then
		return ("slash:sfofl_lizhen[%s:%s]=%d"):format(suit,number,card_id)
	end
end

local sfofl_lizhen_skill = {}
sfofl_lizhen_skill.name = "sfofl_lizhen"
table.insert(package_skills,sfofl_lizhen_skill)
sfofl_lizhen_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = package_known(self,"addHandPile","e")
	cards = package_call(self,"sortByUseValue",cards,true)
	local red_card = {}
	local useAll = false
	package_call(self,"sort",self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if package_known(enemy,"getHp")<2 and not package_known(enemy,"hasArmorEffect","EightDiagram")
		and package_known(self.player,"distanceTo",enemy)<=package_known(self.player,"getAttackRange") and package_known(self,"isWeak",enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end

	package_call(self,"sort",self.enemies,"defense")


	for _,card in ipairs(cards)do
		if (package_known(self,"getUseValue",card)<sgs.ai_use_value.Slash or inclusive or correct_target(self,"Residue",clone(self))>0)
		then table.insert(red_card,card) end
	end


	for _,card in ipairs(red_card)do
		local slash = clone(self,"slash")
		package_call(slash,"addSubcard",card)
		package_call(slash,"setSkillName","sfofl_lizhen")
		if package_known(slash,"isAvailable",self.player)
		then return slash end
	end
end


ai_skill_invoke.sfofl_qizhen = function(self, options, request)
   	local data = request and self:getDecisionData(request) or nil
   	local use = package_known(data,"toCardUse")
	if package_known(use.card,"hasFlag","DamageDone") then return (true) or false end
	for _,p in sgs.qlist(use.to) do
		if not package_known(self,"doDisCard",p, "e") then
			return (false) or false
		end
	end
    return (true) or false
end


local sfofl_mujun_skill = {}
sfofl_mujun_skill.name = "sfofl_mujun"
table.insert(package_skills, sfofl_mujun_skill)
sfofl_mujun_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.friends_noself==0 then return nil end
	return source_construct(self,"#sfofl_mujun:.:")
end

ai_card_use["#sfofl_mujun"] = function(self, card, use, request)
	local lieges = package_known(self.room,"getLieges","qun", self.player)
	for _,p in sgs.qlist(lieges) do
		if package_known(self,"isFriend",p) then
			use.card = card
			package_call(use.to,"append",p)
			return
		end
	end
end

local sfofl_xuanshi_skill = {}
sfofl_xuanshi_skill.name = "sfofl_xuanshi"
table.insert(package_skills, sfofl_xuanshi_skill)
sfofl_xuanshi_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies==0 then return nil end
	return source_construct(self,"#sfofl_xuanshi:.:")
end


ai_card_use["#sfofl_xuanshi"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies, "defense", true)
	for _,enemy in ipairs(self.enemies) do
		if package_known(self,"doDisCard",enemy, "he") then
			use.card = card
		 	if use.to then package_call(use.to,"append",enemy) end
			return
		end
	end
	package_call(self,"sort",self.friends_noself, "defense", true)
	for _,friend in ipairs(self.friends_noself) do
		if package_known(self,"doDisCard",friend, "he") then
			use.card = card
		 	if use.to then package_call(use.to,"append",friend) end
			return
		end
	end
end
sgs.ai_use_priority.sfofl_xuanshi = 10



local sfofl_xiongye_skill = {}
sfofl_xiongye_skill.name = "sfofl_xiongye"
table.insert(package_skills, sfofl_xiongye_skill)
sfofl_xiongye_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies==0 then return nil end
	return source_construct(self,"#sfofl_xiongye:.:")
end


ai_card_use["#sfofl_xiongye"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies, "defense", true)
	local targets = sgs.SPlayerList()
	for _,enemy in ipairs(self.enemies) do
		if package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) and not package_known(self,"cantbeHurt",enemy) and package_known(enemy,"getKingdom") == "qun" then
			package_call(targets,"append",enemy)
			if package_known(targets,"length") >= package_known(self.player,"getHandcardNum") then
				break
			end
		end
	end
	if package_known(targets,"length") > 0 then
		use.card = card
		use.to = targets
	end
end
sgs.ai_use_priority.sfofl_xiongye = 10


sgs.ai_skill_cardask["@sfofl_xiongye"] = function(self, data, pattern)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do
		if match_pattern(self,self.player,pattern,h)
		then return package_known(h,"getEffectiveId") end
		if package_known(h,"isKindOf",pattern)
		then return package_known(h,"getEffectiveId") end
	end
	return package_known(self,"getCardId",pattern)
end

ai_skill_invoke.sfofl_mingjian = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(self.room,"getCurrent")
    if target and package_known(self,"isFriend",target) then return (true) or false end
	return (false) or false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_mingjian = function(self, player, promptlist)
    local current = package_call(self.room,"getCurrent")
    if promptlist[#promptlist] == "yes" then
        sgs.updateIntention(player, current, -70)
    end
end

sgs.ai_skill_playerchosen.sfofl_huituo = function(self,targets)
    package_call(self,"sort",self.friends)
	for _,p in sgs.list(self.friends)do
		if package_known(p,"isWounded") then
			return p
		end
	end
	for _,p in sgs.list(self.friends)do
		if package_known(self,"canDraw",p) then
			return p
		end
	end
    return self.friends[1]
end

sgs.ai_playerchosen_intention.sfofl_huituo = -80

ai_skill_invoke.sfofl_yanggu = true



local sfofl_yanggu_skill = {}
sfofl_yanggu_skill.name = "sfofl_yanggu"
table.insert(package_skills,sfofl_yanggu_skill)
sfofl_yanggu_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self.player,"getChangeSkillState","sfofl_yanggu") == 2 then
		local cards = package_known(self,"addHandPile","h")
		cards = package_call(self,"sortByUseValue",cards,true)

		for _,card in ipairs(cards)do
				local slash = clone(self,"zd_shengdongjixi")
				package_call(slash,"addSubcard",card)
				package_call(slash,"setSkillName","sfofl_yanggu")
				if package_known(slash,"isAvailable",self.player)
				then return slash end
		end
	end
end

ai_skill_invoke.sfofl_zuifu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
    if target and package_known(self,"isEnemy",target) and package_known(self,"damageIsEffective",target, sgs.DamageStruct_Normal) and not package_known(self,"cantbeHurt",target) then return (true) or false end
	return (false) or false
end



sgs.ai_guhuo_card.sfofl_jieqiao_quyi = function(self,toname,class_name)
    if package_known(self.player,"getStrategyMark","&sfofl_jieqiao_quyi") <= 0 then return end
    if class_name and package_known(self,"getCardsNum",class_name) > 0 then return end

	local card = clone_native(self,toname, sgs.Card_SuitToBeDecided, -1)
    package_call(card,"deleteLater")
    if (not card) or (not package_known(card,"isKindOf","BasicCard")) then return end

    return "#sfofl_jieqiao_quyi:.:"..toname
end

local sfofl_jieqiao_quyi_skill = {}
sfofl_jieqiao_quyi_skill.name = "sfofl_jieqiao_quyi"
table.insert(package_skills, sfofl_jieqiao_quyi_skill)
sfofl_jieqiao_quyi_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

    if package_known(self.player,"getStrategyMark","&sfofl_jieqiao_quyi") <= 0 then return end

    local basics = {"peach", "analeptic", "thunder_slash", "slash", "fire_slash"}
    for _,name in ipairs(basics) do
        local card = clone_native(self,name, sgs.Card_SuitToBeDecided, -1)
        package_call(card,"deleteLater")
        if card and package_known(card,"isAvailable",self.player) then

            local dummy = {isDummy=true,to=sgs.SPlayerList()}
            package_call(self,"useCardByClassName",card, dummy)
            local num = package_known(self,"getCardsNum",package_known(card,"getClassName"),"he")
			if dummy.card and dummy.to and ((num < 1) or (package_known(self.player,"getStrategyMark","&sfofl_jieqiao_quyi") >= 3)) then
                source_state(self).sfofl_jieqiao_quyito = dummy.to
                return source_construct(self,"#sfofl_jieqiao_quyi:.:"..name)
            end
        end
	end
end

ai_card_use["#sfofl_jieqiao_quyi"] = function(self, card, use, request)
    use.card = card
	if use.to
	then
		use.to = source_state(self).sfofl_jieqiao_quyito
	end
end


local sfofl_lianhuan_skill = {}
sfofl_lianhuan_skill.name = "sfofl_lianhuan"
table.insert(package_skills, sfofl_lianhuan_skill)
sfofl_lianhuan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local card = clone_native(self,"iron_chain", sgs.Card_SuitToBeDecided, -1)
	package_call(card,"deleteLater")
	if card and package_known(card,"isAvailable",self.player) then
		local dummy_use = package_known(self,"aiUseCard",card, dummy())
		if dummy_use.card and dummy_use.to and package_known(dummy_use.to,"length") > 0 and package_known(self.player,"getHp") > 2 then
			return source_construct(self,"#sfofl_lianhuan:.:")
		end
	end
end

ai_card_use["#sfofl_lianhuan"] = function(self, card, use, request)
   local c = clone_native(self,"iron_chain", sgs.Card_SuitToBeDecided, -1)
	package_call(c,"deleteLater")
	package_call(c,"setSkillName","sfofl_lianhuan")
	if c and package_known(c,"isAvailable",self.player) then
		local dummy_use = package_known(self,"aiUseCard",c, dummy())
		if dummy_use.card and dummy_use.to and package_known(dummy_use.to,"length") > 0 and package_known(self.player,"getHp") > 2 then
			use.card = card
			for _,to in sgs.qlist(dummy_use.to) do
				package_call(use.to,"append",to)
			end
			return
		end
	end
end
sgs.ai_use_priority["sfofl_lianhuan"] = 2

ai_skill_invoke.sfofl_suozhou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local x = 0
	for _, p in sgs.list(package_known(self.room,"getAllPlayers")) do
		if package_known(p,"isChained") and package_known(self,"canDraw",p, self.player) then
			if package_known(self,"isFriend",p) then
				x = x + 1
			else
				x = x - 1
			end
		end
	end
	if x < 0 then return (false) or false end
	return (true) or false
end

sgs.ai_useto_revises.sfofl_yihuo = function(self, card, use, p)
	if package_known(card,"isKindOf","IronChain")
	then
		if package_known(self,"isFriend",p) and not package_known(p,"isChained") then
			use.card = card
			package_call(use.to,"append",p)
			return
		end
		return false
	end
end

sgs.ai_target_revises.sfofl_yihuo = function(to,card,self,use)
    if package_known(card,"isKindOf","IronChain") and ((package_known(self,"isFriend",to) and package_known(to,"isChained")) or (package_known(self,"isEnemy",to) and not package_known(to,"isChained"))) then return true end
end

ai_skill_invoke.sfofl_lijun = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_known(data,"toDamage").to
    if target and package_known(self,"isFriend",target) and package_known(self,"canDraw",target, self.player) then return (true) or false end
	return (false) or false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_lijun = function(self, player, promptlist)
    local damage = source_fact(self,"CurrentDamageStruct","toDamage")
	if damage.to then
    	if promptlist[#promptlist] == "yes" then
        	sgs.updateIntention(player, damage.to, -20)
		else
			sgs.updateIntention(player, damage.to, 20)
		end
    end
end


ai_skill_invoke.sfofl_tongbei = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = package_known(data,"toDamage")
    if damage.to and package_known(self,"isEnemy",damage.to) then return (true) or false end
	return (false) or false
end

sgs.ai_skill_cardask["@sfofl_tongbei"] = function(self, data, pattern, target)
	local damage = package_known(data,"toDamage")
	if package_known(self,"cantDamageMore",damage.from, self.player) then return "." end
	if not package_known(self,"damageIsEffective",self.player,damage.card,damage.from) then return "." end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do
		if match_pattern(self,self.player,pattern,h)
		then return package_known(h,"getEffectiveId") end
		if package_known(h,"isKindOf",pattern)
		then return package_known(h,"getEffectiveId") end
	end
	return package_known(self,"getCardId",pattern)
end

ai_fill_skill.sfofl_beirong = function(self, options, request)
    local inclusive = options and options.inclusive

	local valid = {}
    local cards = package_known(self.player,"getCards","h")
    cards = package_call(self,"sortByUseValue",cards,true)
	for i,h in sgs.list(cards)do
		if #valid>#cards/2 then break end
		local can = true
		for _,id in sgs.list(valid)do
			if package_known(h,"getSuit")==disclosed_card(self,id):getSuit()
			then can = false break end
		end
		if can then
			table.insert(valid,package_known(h,"getEffectiveId"))
		end
	end
	local suits = {}
	for _,h in sgs.list(package_known(self.player,"getCards","h"))do do
		if table.contains(valid,package_known(h,"getEffectiveId")) or table.contains(suits,package_known(h,"getSuit")) then goto package_continue_8 end
		table.insert(suits,package_known(h,"getSuit"))
	end ::package_continue_8:: end
	return #valid>#suits and source_construct(self,"#sfofl_beirong:"..table.concat(valid,"+")..":")
end

ai_card_use["#sfofl_beirong"] = function(self, card, use, request)
	use.card = card
end

ai_skill_invoke.sfofl_yujun = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = package_known(data,"toDamage")
	if package_known(self,"isWeak") and package_known(self,"getAllPeachNum") < 1 and damage.damage <= 1 then return (false) or false end
    if damage.to and package_known(self,"isFriend",damage.to) and package_known(self,"damageIsEffective",damage.to,damage.card,damage.from) and not package_known(self,"needToLoseHp",damage.to, damage.from, damage.card) then return (true) or false end
	return (false) or false
end

sgs.ai_useto_revises.sfofl_yujun = function(self, card, use, p)
	if package_known(card,"isKindOf","IronChain")
	then
		if package_known(self,"isFriend",p) and not package_known(p,"isChained") then
			use.card = card
			package_call(use.to,"append",p)
			return
		end
		return false
	end
end

sgs.ai_target_revises.sfofl_yujun = function(to,card,self,use)
    if package_known(card,"isKindOf","IronChain") and ((package_known(self,"isFriend",to) and package_known(to,"isChained")) or (package_known(self,"isEnemy",to) and not package_known(to,"isChained"))) then return true end
end

ai_skill_invoke.sfofl_cailue = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	if target then return (package_known(self,"doDisCard",target, "he")) or false end
	return (false) or false
end

ai_skill_invoke.sfofl_sashuang = true


local sfofl_huoce_skill = {}
sfofl_huoce_skill.name = "sfofl_huoce"
table.insert(package_skills, sfofl_huoce_skill)
sfofl_huoce_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies == 0 then return nil end
	return source_construct(self,"#sfofl_huoce:.:")
end

ai_card_use["#sfofl_huoce"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies)
	for _,enemy in ipairs(self.enemies) do
		if package_known(self,"doDisCard",enemy, "h") then
			use.card = card
		 	if use.to then package_call(use.to,"append",enemy) end
			return
		end
	end
	package_call(self,"sort",self.friends_noself)
	for _,friend in ipairs(self.friends_noself) do
		if package_known(self,"doDisCard",friend, "h") then
			use.card = card
		 	if use.to then package_call(use.to,"append",friend) end
			return
		end
	end
end
sgs.ai_use_priority["sfofl_huoce"] = 2.8

sgs.ai_skill_cardask["@sfofl_huoce"] = function(self, data, pattern, target, target2)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do
		if match_pattern(self,self.player,pattern,h)
		then return package_known(h,"getEffectiveId") end
		if package_known(h,"isKindOf",pattern)
		then return package_known(h,"getEffectiveId") end
	end
	return package_known(self,"getCardId",pattern)
end

sgs.ai_skill_playerchosen["sfofl_huoce"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
	for _,p in ipairs(targets) do
		if package_known(self,"isEnemy",p) and package_known(self,"damageIsEffective",p, sgs.DamageStruct_Fire) and not package_known(self,"cantbeHurt",p) then
			return p
		end
	end
	return nil
end

local sfofl_boyan_skill = {}
sfofl_boyan_skill.name = "sfofl_boyan"
table.insert(package_skills, sfofl_boyan_skill)
sfofl_boyan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies == 0 then return nil end
	return source_construct(self,"#sfofl_boyan:.:")
end

ai_card_use["#sfofl_boyan"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies)
	local max_card = package_call(self,"getMaxCard")
	local max_point = package_known(max_card,"getNumber")
	if package_known(self.player,"hasSkill","yingyang") then max_point = math.min(max_point+3,13) end
	if max_point >= 13 then package_call(self,"setPriorityValue","sfofl_boyan", 3,"sfoflCard.source") end
	if package_known(self,"getOverflow") > 1 and #self.toUse > 1 and math.random() < 0.3 then package_call(self,"setPriorityValue","sfofl_boyan", 0,"sfoflCard.source") end
	for _,enemy in ipairs(self.enemies) do
		if package_known(self.player,"canPindian",enemy) and package_known(enemy,"getStrategyMark","sfofl_boyan-PlayClear") == 0 then
			local enemy_max_card = package_call(self,"getMaxCard",enemy)
			local enemy_max_point = enemy_max_card and package_known(enemy_max_card,"getNumber") or 100
			if enemy_max_card and package_known(enemy,"hasSkill","yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
			if max_point>enemy_max_point or max_point>10 then
				use.card = card
				if use.to then package_call(use.to,"append",enemy) end
				return
			end
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if package_known(self.player,"canPindian",enemy) then
			local enemy_max_card = package_call(self,"getMaxCard",enemy)
			local enemy_max_point = enemy_max_card and package_known(enemy_max_card,"getNumber") or 100
			if enemy_max_card and package_known(enemy,"hasSkill","yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
			if max_point>enemy_max_point or max_point>10 then
				use.card = card
				if use.to then package_call(use.to,"append",enemy) end
				return
			end
		end
	end



	package_call(self,"sort",self.friends_noself)
	for _,friend in ipairs(self.friends_noself) do
		if package_known(self,"doDisCard",friend, "h") and package_known(self.player,"canPindian",friend) then
			use.card = card
		 	if use.to then package_call(use.to,"append",friend) end
			return
		end
	end
end
sgs.ai_use_priority["sfofl_boyan"] = 2.8

function sgs.ai_skill_pindian.sfofl_boyan(minusecard,self,requestor)
	if package_known(requestor,"getHandcardNum")==1 then
		local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
		package_call(self,"sortByKeepValue",cards)
		return cards[1]
	end
	local maxcard = package_call(self,"getMaxCard")
	return package_known(self,"isFriend",requestor) and package_call(self,"getMinCard") or ( package_known(maxcard,"getNumber")<6 and  minusecard or maxcard )
end

ai_skill_choice["sfofl_mushi"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local skill_items = package_known(choices,"split","+")
	if #skill_items == 1 then
		return ai_choice_result((skill_items[1]), options)
	else
		return ai_choice_result((skill_items[math.random(1,#skill_items)]), options)
	end
	return ai_choice_result(("cancel"), options)
end

ai_skill_invoke.sfofl_dimeng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local pindian = package_known(data,"toPindian")
	if pindian.from and pindian.to and package_known(self,"isFriend",pindian.to) and package_known(self,"isEnemy",pindian.from) then
		if package_known(pindian.to_card,"getNumber") < package_known(pindian.from_card,"getNumber") then
			return (true) or false
		end
	end
	if pindian.from and pindian.to and package_known(self,"isFriend",pindian.from) and package_known(self,"isEnemy",pindian.to) then
		if package_known(pindian.to_card,"getNumber") >= package_known(pindian.from_card,"getNumber") then
			return (true) or false
		end
	end
	return (false) or false
end

local sfofl_2_zhouji_skill = {}
sfofl_2_zhouji_skill.name = "sfofl_2_zhouji"
table.insert(package_skills, sfofl_2_zhouji_skill)
sfofl_2_zhouji_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies == 0 then return nil end
	return source_construct(self,"#sfofl_2_zhouji:.:")
end

ai_card_use["#sfofl_2_zhouji"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies)
	for _,enemy in ipairs(self.enemies) do
		if package_known(self.player,"canPindian",enemy) then
			use.card = card
			if use.to then package_call(use.to,"append",enemy) end
			return
		end
	end


	package_call(self,"sort",self.friends_noself)
	for _,friend in ipairs(self.friends_noself) do
		if package_known(self,"doDisCard",friend, "h") and package_known(self.player,"canPindian",friend) then
			use.card = card
		 	if use.to then package_call(use.to,"append",friend) end
			return
		end
	end
end

local sfofl_zhaxiong_skill = {}
sfofl_zhaxiong_skill.name = "sfofl_zhaxiong"
table.insert(package_skills,sfofl_zhaxiong_skill)
sfofl_zhaxiong_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies<=0 then return end
	return source_construct(self,"#sfofl_zhaxiong:.:")
end

ai_card_use["#sfofl_zhaxiong"] = function(self, card, use, request)
	for _,enemy in sgs.list(self.enemies)do
		if package_known(self,"damageMinusHp",enemy,1)>0
		or package_known(enemy,"getHp")<3 and package_known(self,"damageMinusHp",enemy,0)>0 and package_known(enemy,"getHandcardNum")>0
		then
			use.card = card
			return
		end
	end
end

sgs.ai_use_priority["sfofl_zhaxiong"] = 10

ai_skill_invoke["sfofl_louchuan"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	if package_known(self,"isEnemy",target) and not(package_known(target,"isChained") or package_known(self,"needToLoseHp",target))
		and package_known(self,"isGoodTarget",target,self.enemies) then return (true) or false end
	return (false) or false
end

ai_card_use.Yiguzuoqi=function(self,card,use, request)
	local slash = package_call(self,"getCard","Slash")
	if slash and #package_known(self,"getCards","Slash") > 1 and package_known(self.player,"getStrategyMark","&sfofl_yiguzuoqi-Clear") == 0 then
		local dummy_use = package_known(self,"aiUseCard",slash, dummy())
		if dummy_use.card and dummy_use.to and not package_known(dummy_use.to,"isEmpty") then
			use.card = card
		end
	end
end
sgs.ai_use_priority.Yiguzuoqi = 7
sgs.ai_keep_value.Yiguzuoqi = 2.2
sgs.ai_use_value.Yiguzuoqi = 4.7




local sfofl_barbs_skill = {}
sfofl_barbs_skill.name = "sfofl_barbs"
table.insert(package_skills, sfofl_barbs_skill)
sfofl_barbs_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies == 0 then return nil end
	return source_construct(self,"#sfofl_barbs:.:")
end

ai_card_use["#sfofl_barbs"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies)
	local max_card = package_call(self,"getMaxCard")
	local max_point = package_known(max_card,"getNumber")
	for _,enemy in ipairs(self.enemies) do
		if package_known(self.player,"canPindian",enemy) then
			local enemy_max_card = package_call(self,"getMaxCard",enemy)
			local enemy_max_point = enemy_max_card and package_known(enemy_max_card,"getNumber") or 100
			if enemy_max_card and package_known(enemy,"hasSkill","yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
			if max_point>enemy_max_point or max_point>10 then
				use.card = card
				if use.to then package_call(use.to,"append",enemy) end
				return
			end
		end
	end

end
sgs.ai_use_priority["sfofl_barbs"] = 1



ai_skill_invoke.sfofl_lilu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local invoke = false
	for _,p in ipairs(self.friends_noself)do do
		if package_known(p,"isKongcheng") and package_known(self,"needKongcheng",p,true) then goto package_continue_9 end
		invoke = true
		break
	end ::package_continue_9:: end
	if not invoke then return (false) or false end
	return (true) or false
end

ai_skill_use["@@sfofl_lilu!"]=function(self,prompt,request)
	local mark = package_known(self.player,"getStrategyMark","&sfofl_lilu")
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	package_call(self,"sortByUseValue",cards,true)
	package_call(self,"sort",self.friends_noself)

	local target
	for _,p in ipairs(self.friends_noself)do
		if package_known(self,"canDraw",p) and not package_known(self,"willSkipPlayPhase",p) then
			target = p
			break
		end
	end
	if not target then
		for _,p in ipairs(self.friends_noself)do
			if not (package_known(p,"isKongcheng") and package_known(self,"needKongcheng",p,true)) and not package_known(self,"willSkipPlayPhase",p) then
				target = p
				break
			end
		end
	end
	if not target then
		for _,p in ipairs(self.friends_noself)do
			if package_known(self,"canDraw",p) then
				target = p
				break
			end
		end
	end
	if not target then
		for _,p in ipairs(self.friends_noself)do
			if not (package_known(p,"isKongcheng") and package_known(self,"needKongcheng",p,true)) then
				target = p
				break
			end
		end
	end
	if not target then target = self.friends_noself[1] end

	local give,hand_num = {},package_known(self.player,"getHandcardNum")
	if hand_num<mark+1 and target then
		if package_known(self,"needToThrowLastHandcard",self.player,hand_num) then
			for _,c in ipairs(cards)do
				table.insert(give,package_known(c,"getEffectiveId"))
			end
			return "#sfofl_lilu:"..table.concat(give,"+")..":->"..package_known(target,"objectName")
		end
		local card,friend = package_call(self,"getCardNeedPlayer",cards,false)
		if card and friend then
			return "#sfofl_lilu:"..package_known(card,"getEffectiveId")..":->"..package_known(friend,"objectName")
		end
		return "#sfofl_lilu:"..package_known(cards[1],"getEffectiveId")..":->"..package_known(target,"objectName")
	end

	for i = 1,mark+1 do
		if #cards<i then break end
		table.insert(give,package_known(cards[i],"getEffectiveId"))
	end
	if #give>0 and target then
		return "#sfofl_lilu:"..table.concat(give,"+")..":->"..package_known(target,"objectName")
	end
	return "."
end
sgs.ai_card_intention["sfofl_lilu"] = -80

sgs.ai_skill_discard.sfofl_lilu = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	package_call(self,"sortByKeepValue",cards)
	for _,c in ipairs(cards)do do
		if package_known(self,"getKeepValue",c) > 10 then goto package_continue_10 end
		if package_known(self,"willUse",self.player,c, false,false, true) then goto package_continue_10 end
			table.insert(to_discard,package_known(c,"getEffectiveId"))
		end ::package_continue_10:: end
	for _,c in ipairs(sgs.QList2Table(package_known(self.player,"getCards","e")))do
		if package_known(self,"doDisCard",self.player, package_known(c,"getEffectiveId")) then
			table.insert(to_discard,package_known(c,"getEffectiveId"))
		end
	end
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end



sgs.ai_skill_playerchosen.sfofl_yizhengc = function(self,targets)
	if package_known(self.player,"getMaxHp")<=3 or #self.friends_noself<=0 then return nil end
	local friends = {}
	for _,p in ipairs(self.friends_noself)do
		if package_known(p,"getStrategyMark","&sfofl_yizhengc+to+#"..package_known(self.player,"objectName"))<=0 and not package_known(self,"willSkipPlayPhase",p) then
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		package_call(self,"sort",friends,"threat")
		return friends[1]
	end

	for _,p in ipairs(self.friends_noself)do
		if not package_known(self,"willSkipPlayPhase",p) then
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		package_call(self,"sort",friends,"threat")
		return friends[1]
	end

	for _,p in ipairs(self.friends_noself)do
		if package_known(p,"getStrategyMark","&sfofl_yizhengc+to+#"..package_known(self.player,"objectName"))<=0 then
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		package_call(self,"sort",friends,"threat")
		return friends[1]
	end

	for _,p in ipairs(self.friends_noself)do
		table.insert(friends,p)
	end
	if #friends>0 then
		package_call(self,"sort",friends,"threat")
		return friends[1]
	end

	package_call(self,"sort",self.friends_noself,"threat")
	return self.friends_noself[1]
end
sgs.ai_playerchosen_intention.sfofl_yizhengc = -40

ai_fill_skill.sfofl_liaofu = function(self, options, request)
    local inclusive = options and options.inclusive

	local use_card
    local cards = package_known(self.player,"getCards","h")
    cards = package_call(self,"sortByUseValue",cards,true)
	for i,h in sgs.list(cards)do
		if package_known(h,"isKindOf","Slash") and package_known(self.player,"getStrategyMark","sfofl_liaofu"..package_known(h,"objectName")) == 0 then
			use_card = h
			break
		end
	end
	if use_card then
		return source_construct(self,"#sfofl_liaofu:"..package_known(use_card,"getEffectiveId")..":")
	end
end

ai_card_use["#sfofl_liaofu"] = function(self, card, use, request)
	use.card = card
end

ai_skill_invoke.sfofl_liaofu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = package_known(data,"toCardUse")
	return (package_known(self,"isEnemy",use.from) and not package_known(self,"cantbeHurt",use.from) and package_known(self,"canDamage",use.from,self.player,use.card)) or false
end

ai_skill_invoke.sfofl_jinshou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (package_known(self,"isWeak") and package_known(self,"getAllPeachNum") + package_known(self.player,"getHp") - 1 - getCardsNum("Peach,Analeptic",self.player,self.player) > 0) or false
end

sgs.ai_target_revises.sfofl_jinshou = function(to,card,self)
	return package_known(card,"isDamageCard") and package_known(card,"isSingleTargetCard") and self.player~=to and package_known(to,"getStrategyMark","&sfofl_jinshou-Self"..sgs.Player_RoundStart.."Clear") > 0
end


ai_skill_invoke.sfofl_sitong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = package_known(data,"toCardUse")
	local target = use.from
	local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
	package_call(slash,"deleteLater")
	package_call(slash,"setSkillName","sfofl_sitong")
	local dummy_use = package_known(self,"withOwnerRange","slashNoDistanceLimit","sfofl_sitong",function() return package_known(self,"aiUseCard",slash, dummy(true, 99, package_known(self.room,"getOtherPlayers",target))) end)
	if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_skill_playerchosen.sfofl_jianjing = sgs.ai_skill_playerchosen.damage
local sfofl_jianjing_skill = {}
sfofl_jianjing_skill.name = "sfofl_jianjing"
table.insert(package_skills,sfofl_jianjing_skill)
sfofl_jianjing_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self,"needBear") then return end
	return source_construct(self,"#sfofl_jianjing:.:")
end

ai_card_use["#sfofl_jianjing"] = function(self, card, use, request)
	local max_card = package_call(self,"getMaxCard")
	local max_point = package_known(max_card,"getNumber")

	if #self.enemies==0 then return end
	package_call(self,"sort",self.enemies,"handcard")

	for _,enemy in sgs.list(self.enemies)do
		if package_known(self.player,"canPindian",enemy) then
			local enemy_max_card = package_call(self,"getMaxCard",enemy)
			local allknown = 0
			if package_known(self,"getKnownNum",enemy)==package_known(enemy,"getHandcardNum") then
				allknown = allknown+1
			end
			if (enemy_max_card and max_point>package_known(enemy_max_card,"getNumber") and allknown>0)
				or (enemy_max_card and max_point>package_known(enemy_max_card,"getNumber") and allknown<1 and max_point>10)
				or (not enemy_max_card and max_point>10) then
				for _,enemy2 in sgs.list(self.enemies)do
					if (package_known(enemy,"objectName")~=package_known(enemy2,"objectName"))
						and package_known(self.player,"distanceTo",enemy2)<=package_known(self.player,"getAttackRange") then
						source_state(self).sfofl_jianjing_card = package_known(max_card,"getEffectiveId")
						use.card = source_construct(self,"#sfofl_jianjing:.:")
						package_call(use.to,"append",enemy)
						return
					end
				end
			end
		end
	end
	local min_card = package_call(self,"getMinCard")
	local min_point = package_known(min_card,"getNumber")
	for _,friend in sgs.list(self.friends_noself)do
		if package_known(self.player,"canPindian",friend) and min_point < 6 then
			for _,enemy2 in sgs.list(self.enemies)do
				if package_known(friend,"distanceTo",enemy2)<=package_known(friend,"getAttackRange") then
					source_state(self).sfofl_jianjing_card = package_known(min_card,"getEffectiveId")
					use.card = source_construct(self,"#sfofl_jianjing:.:")
					package_call(use.to,"append",friend)
					return
				end
			end

		end
	end
end

sgs.ai_cardneed.sfofl_jianjing = sgs.ai_cardneed.bignumber

sgs.ai_can_damagehp.sfofl_dishou = function(self,from,card,to)
	if from and package_known(to,"getHp")+package_known(self,"getAllPeachNum")-package_known(self,"ajustDamage",from,to,1,card)>0
	and package_known(self,"canLoseHp",from,card,to) then
		return package_known(self,"isEnemy",from)
	end
end

ai_skill_choice["sfofl_dishou"]    = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	if package_known(self.player,"getHp") <= 1 and package_known(self,"getAllPeachNum") > 0 then
		return ai_choice_result(("losehp"), options)
	end
	if package_known(self.player,"getHp") > package_known(self.player,"getHandcardNum") and not package_known(self.player,"isKongcheng") then
		return ai_choice_result(("losehp"), options)
	end
	if package_known(self,"getCardsNum","Peach") > 0 then
		return ai_choice_result(("losehp"), options)
	end
	return ai_choice_result((items[math.random(1,#items)]), options)
end

sgs.ai_skill_playerschosen.sfofl_jiaozheng = function(self, targets, max, min)
    local selected = AIList.new({})
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
	local card = clone(self)
	package_call(card,"setSkillName","sfofl_jiaozheng")
	package_call(card,"deleteLater")
	local dummy_use = package_known(self,"withOwnerRange","slashNoDistanceLimit","sfofl_jiaozheng",function() return package_known(self,"aiUseCard",card, dummy()) end)
	if dummy_use.card and dummy_use.to and not package_known(dummy_use.to,"isEmpty") then
		for _, p in sgs.qlist(dummy_use.to) do
			if table.contains(can_choose, p) then
				package_call(selected,"append",p)
			end
		end
	else
		for _,target in ipairs(can_choose) do
			if package_known(self,"isEnemy",target) and package_known(self.player,"canUse",card, target) then
				package_call(selected,"append",target)
				if package_known(selected,"length") >= max then break end
			end
		end
	end
    return selected
end

sgs.ai_skill_playerchosen.sfofl_jiaozheng = function(self,targets)
	local slash = clone(self)
	package_call(slash,"setSkillName","sfofl_jiaozheng")
	for _,friend in ipairs(sgs.QList2Table(targets))do
		if package_known(self,"isFriend",friend) then
		for _,enemy in ipairs(self.enemies)do
				if package_known(friend,"canSlash",enemy, false) and not package_known(self,"slashProhibit",slash,enemy) and package_known(self,"getDefenseSlash",enemy)<=2
			and package_known(self,"slashIsEffective",slash,enemy) and package_known(self,"isGoodTarget",enemy,self.enemies,slash)
			and package_known(enemy,"objectName")~=package_known(self.player,"objectName") then
				return friend
			end
		end
	end
	end
	return nil
end

sgs.ai_playerchosen_intention.sfofl_jiaozheng = -80

ai_skill_invoke.sfofl_qingjin = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
	package_call(slash,"deleteLater")
	package_call(slash,"setSkillName","sfofl_qingjin")
	local dummy_use = package_known(self,"withOwnerRange","slashNoDistanceLimit","sfofl_qingjin",function() return package_known(self,"aiUseCard",slash, dummy(true, 99, package_known(self.room,"getOtherPlayers",target))) end)
	if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) then
		if not package_known(self,"isWeak") or getCardsNum("Jink",target,self.player)==0 then
			return (true) or false
		end
	end
	return (false) or false
end


ai_fill_skill.sfofl_fenqi = function(self, options, request)
    local inclusive = options and options.inclusive

	local Yiguzuoqi = clone_native(self,"sfofl_yiguzuoqi", sgs.Card_NoSuit, 0)
	package_call(Yiguzuoqi,"deleteLater")
	local dummy_use = package_known(self,"aiUseCard",Yiguzuoqi, dummy())
	if not dummy_use.card then return end
	return source_construct(self,"#sfofl_fenqi:.::")
end

ai_card_use["#sfofl_fenqi"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_priority["sfofl_fenqi"] = 10

sgs.ai_skill_playerchosen.sfofl_mouni = function(self,targets)
	local slash = clone(self)
	package_call(slash,"setSkillName","sfofl_mouni")
	package_call(self,"sort",self.enemies,"handcard",true)
	for _,enemy in ipairs(self.enemies)do
		if package_known(self.player,"canSlash",enemy, false) and not package_known(self,"slashProhibit",slash,enemy) and package_known(self,"slashIsEffective",slash,enemy) and ((package_known(self,"canHit",enemy, self.player) or (getCardsNum("Jink", enemy, self.player) < getCardsNum("Slash", enemy, self.player))) and (getCardsNum("Slash", enemy, self.player) > 0)) then
			return enemy
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if package_known(self.player,"canSlash",enemy, false) and not package_known(self,"slashProhibit",slash,enemy) and package_known(self,"slashIsEffective",slash,enemy) and (package_known(self,"isGoodTarget",enemy,self.enemies,slash) and math.random() < 0.4 and package_known(enemy,"getHandcardNum") > 2) then
			return enemy
		end
	end

	return nil
end

sgs.ai_playerchosen_intention.sfofl_mouni = 40

sgs.ai_skill_playerchosen.sfofl_zongfan = function(self,targets)
	for _,p in sgs.list(self.friends_noself)do
		if package_known(self,"canDraw",p, self.player) then
			return p
		end
	end
	return package_known(targets,"first")
end
sgs.ai_playerchosen_intention.sfofl_zongfan = -80

sgs.ai_skill_discard.sfofl_zongfan = function(self, discard_num, min_num, optional, include_equip)
	local target = source_fact(self,"sfofl_zongfan","toPlayer")
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, package_known(card,"getEffectiveId"))
		if #to_discard >= 5 or not package_known(self,"isFriend",target) then
        	break
		end
	end
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end

ai_card_use.JingxiangGoldenage=function(self,card,use, request)
    local recommend = self:targetRecommendScorer(card)
	local targets = sgs.SPlayerList()
	local value = 1
	local kingdoms = source_kingdoms(self)
	for _,ff in ipairs(self:orderTargetsByRecommend(self.friends_noself, recommend)) do
		if package_known(self,"canDraw",ff, self.player) and package_known(self.player,"canUse",card, ff) then
			package_call(targets,"append",ff)
			value = value + 1
			if package_known(targets,"length") >= kingdoms then break end
		end
	end
	if package_known(targets,"length") < kingdoms then
		for _,ff in ipairs(self:orderTargetsByRecommend(self.friends_noself, recommend)) do
			if not package_known(targets,"contains",ff) and package_known(self.player,"canUse",card, ff) then
				package_call(targets,"append",ff)
				value = value + 1
				if package_known(targets,"length") >= kingdoms then break end
			end
		end
	end
	if package_known(targets,"length") < kingdoms then
		for _,enemy in ipairs(self:orderTargetsByRecommend(self.enemies, recommend)) do
			if not package_known(self,"canDraw",enemy, self.player) and package_known(self.player,"canUse",card, enemy) then
				package_call(targets,"append",enemy)
				if package_known(targets,"length") >= kingdoms then break end
			end
		end
	end
	if package_known(targets,"length") < kingdoms then
		for _,enemy in ipairs(self:orderTargetsByRecommend(self.enemies, recommend)) do
			if package_known(self,"needKongcheng",enemy) and not package_known(targets,"contains",enemy) and package_known(self.player,"canUse",card, enemy) then
				package_call(targets,"append",enemy)
				value = value - 0.5
				if package_known(targets,"length") >= kingdoms then break end
			end
		end
	end
	if package_known(targets,"length") < kingdoms then
		for _,enemy in ipairs(self:orderTargetsByRecommend(self.enemies, recommend)) do
			if not package_known(targets,"contains",enemy) and package_known(self.player,"canUse",card, enemy) then
				package_call(targets,"append",enemy)
				value = value - 1
				if package_known(targets,"length") >= kingdoms then break end
			end
		end
	end
	if package_known(targets,"length") == kingdoms and value > 0 then
		use.card = card
		use.to = targets
	end
end
sgs.registerSkillCardType("JingxiangGoldenage", "draw")

sgs.ai_use_value.JingxiangGoldenage = sgs.ai_use_value.ExNihilo
sgs.ai_keep_value.JingxiangGoldenage = sgs.ai_keep_value.ExNihilo
sgs.ai_use_priority.JingxiangGoldenage = sgs.ai_use_priority.ExNihilo
sgs.dynamic_value.benefit.JingxiangGoldenage = true


sgs.ai_skill_playerschosen.sfofl_fujing = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
	local card = clone_native(self,"_sfofl_jingxiang_goldenage", sgs.Card_NoSuit, 0)
	package_call(card,"setSkillName","sfofl_fujing")
	package_call(card,"deleteLater")
	local dummy_use = package_known(self,"aiUseCard",card, dummy())
	if dummy_use.card and dummy_use.to and not package_known(dummy_use.to,"isEmpty") then
		for _, p in sgs.qlist(dummy_use.to) do
			if table.contains(can_choose, p) then
				package_call(selected,"append",p)
			end
		end
	else
		local kingdoms = source_kingdoms(self)
		for _,target in ipairs(can_choose) do
			if package_known(self,"isFriend",target) and package_known(self.player,"canUse",card, target) then
				package_call(selected,"append",target)
				if package_known(selected,"length") >= kingdoms then break end
			end
		end
		if package_known(selected,"length") < kingdoms then
			for _,enemy in ipairs(self.enemies) do
				if package_known(self.player,"canUse",card, enemy) then
					package_call(selected,"append",enemy)
					if package_known(selected,"length") >= kingdoms then break end
				end
			end
		end
	end
    return selected
end

sgs.ai_skill_cardask["@sfofl_yongrong_increase"] = function(self,data,pattern,target)
	local damage = package_known(data,"toDamage")
	local target = damage.to
	if not package_known(self,"isEnemy",target) then return "." end
	if package_known(self,"cantDamageMore",damage.from,target) then return "." end
	return true
end

sgs.ai_skill_cardask["@sfofl_yongrong_decrease"] = function(self,data,pattern,target)
	local damage = package_known(data,"toDamage")
	if package_known(self,"damageStruct",damage) and package_known(self,"needToLoseHp",damage.to, damage.from, damage.card) then
		return "."
	end
	return true
end

function ai_skill_invoke.sfofl_jushou(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local sbdiaochan = package_call(self.room,"findPlayerBySkillName","lihun")
	if sbdiaochan and package_known(sbdiaochan,"faceUp") and not package_known(self,"willSkipPlayPhase",sbdiaochan)
		and (package_known(self,"isEnemy",sbdiaochan) or (turn_count(self)<=1 and package_call(self,"getRoleEstimate",sbdiaochan)=="neutral")) then return (false) or false end
	if not package_known(self.player,"faceUp") then return (true) or false end
	if package_known(self,"toTurnOver",self.player,package_known(self.room,"getAlivePlayers"):length(),"sfofl_jushou") then return (true) or false end
	for _,friend in ipairs(self.friends)do
		if package_known(self,"hasSkills","fangzhu|jilve",friend) then return (true) or false end
		if package_known(friend,"faceUp") and package_known(friend,"hasSkill","junxing") and not package_known(self,"willSkipPlayPhase",friend)
			and not (package_known(friend,"isKongcheng") and package_known(self,"willSkipDrawPhase",friend)) then
			return (true) or false
		end
	end
	return (package_known(self,"isWeak")) or false
end
function ai_skill_invoke.sfofl_jushouTurnOver(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if package_known(self.player,"getHp") < 2 or package_known(self.player,"getHandcardNum") == 0 then
		return (true) or false
	end

	package_call(self,"sort",self.enemies,"defense")
	if package_known(self,"getCardsNum","Slash") == 0 then return (false) or false end

	local slashs = package_known(self,"getCards","Slash")
	if #slashs == 0 then return false end
	for _, slash in ipairs(slashs) do
		for _,enemy in ipairs(self.enemies) do
			if not package_known(self,"damageprohibit",enemy) and package_known(self,"TheWuhun",enemy) >= 0 and package_known(self,"damageIsEffective",enemy) and package_known(self.player,"distanceTo",enemy) == 1
				and package_known(self.player,"canSlash",enemy, slash) and not package_known(self,"slashProhibit",slash, enemy, self.player)
				and not package_known(enemy,"hasArmorEffect","SilverLion") and package_known(self,"hasCrossbowEffect") then
				return (true) or false
			end
		end
	end
	return false

end

local sfofl_tuwei_skill = {}
sfofl_tuwei_skill.name = "sfofl_tuwei"
table.insert(package_skills, sfofl_tuwei_skill)
sfofl_tuwei_skill.getTurnUseCard          = function(self, options, request)
    local inclusive = options and options.inclusive

	local ids = sgs.IntList()
	for _, id in sgs.qlist(package_known(self.room,"getDiscardPile")) do
		if disclosed_card(self,id):isKindOf("EquipCard") then
			package_call(ids,"append",id)
		end
	end
	if package_known(ids,"isEmpty") then return end
	for _, p in ipairs(self.friends) do
		if (package_call(p,"getArmor") and package_call(p,"getArmor"):isKindOf("SilverLion") and package_known(p,"isWounded")) or (package_known(p,"getHp") == 1 and package_known(self.player,"getHandcardNum") > 1) and package_known(p,"getStrategyMark","&sfofl_tuwei+to+#"..package_known(self.player,"objectName")) == 0 then
			return source_construct(self,"#sfofl_tuwei:.:")
		end
	end
	local handcards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByKeepValue",handcards)
	if package_known(handcards[1],"isKindOf","Peach") then return end
	for _, p in ipairs(self.friends) do
		if not package_call(p,"getArmor") and package_known(p,"isWounded") and package_known(p,"getStrategyMark","&sfofl_tuwei+to+#"..package_known(self.player,"objectName")) == 0 then
			return source_construct(self,"#sfofl_tuwei:.:")
		end
	end
	return source_construct(self,"#sfofl_tuwei:.:")
end

ai_card_use["#sfofl_tuwei"] = function(self, card, use, request)
	local target
	local card


	if package_known(self.player,"isKongcheng") then return end

	if not target then
		for _, p in ipairs(self.friends) do
			if (package_call(p,"getArmor") and package_call(p,"getArmor"):isKindOf("SilverLion")) and package_known(p,"getStrategyMark","&sfofl_tuwei+to+#"..package_known(self.player,"objectName")) == 0 then
				target = p
				break
			end
		end
	end


	if not target then
		for _, p in ipairs(self.friends) do
			if package_known(p,"getHp") == 1 and not package_call(p,"getArmor") and package_known(p,"getStrategyMark","&sfofl_tuwei+to+#"..package_known(self.player,"objectName")) == 0 then
				target = p
				break
			end
		end
	end

	if not target then
		for _, p in ipairs(self.friends) do
			if not package_call(p,"getArmor") and package_known(p,"getStrategyMark","&sfofl_tuwei+to+#"..package_known(self.player,"objectName")) == 0 then
				target = p
				break
			end
		end
	end
	if not target then
		for _, p in ipairs(self.friends) do
			if package_known(self,"hasSkills",sgs.lose_equip_skill, p) and package_known(p,"getStrategyMark","&sfofl_tuwei+to+#"..package_known(self.player,"objectName")) == 0 then
				target = p
				break
			end
		end
	end
	if not target then
		for _, p in ipairs(self.enemies) do
			if not package_known(self,"hasSkills",sgs.lose_equip_skill, p) and package_known(p,"getStrategyMark","&sfofl_tuwei+to+#"..package_known(self.player,"objectName")) == 0 then
				target = p
				break
			end
		end
	end

	if not target then return end
	if target then
		use.card = source_construct(self,"#sfofl_tuwei:.:")
		if use.to then package_call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["sfofl_tuwei"]       = 4
sgs.ai_use_priority["sfofl_tuwei"]    = 4
sgs.ai_card_intention["sfofl_tuwei"]  = -60

ai_skill_choice["sfofl_tuwei"]    = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	local target = package_call(data,"toPlayer")
	if table.contains(items, "draw") and package_known(self,"isFriend",target) and package_known(self,"canDraw",target, self.player)  then
		return ai_choice_result(("draw"), options)
	end
	if table.contains(items, "damage") and package_known(self,"isFriend",target) and package_known(self,"needToLoseHp",target, self.player)  then
		return ai_choice_result(("damage"), options)
	end
	if table.contains(items, "damage") and package_known(self,"isEnemy",target) and not package_known(self,"needToLoseHp",target, self.player)  then
		return ai_choice_result(("damage"), options)
	end

	return ai_choice_result(("cancel"), options)
end



local sfofl_2_zhanyan_skill = {}
sfofl_2_zhanyan_skill.name = "sfofl_2_zhanyan"
table.insert(package_skills, sfofl_2_zhanyan_skill)
sfofl_2_zhanyan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if not package_known(self.player,"hasUsed","#sfofl_2_zhanyan") then
		local x = 0
		for _, p in sgs.qlist(package_known(self.player,"getHandcards")) do
			if package_known(p,"isRed") then
				x = x + 1
			end
		end
		if x >= 3 then return nil end
		return source_construct(self,"#sfofl_2_zhanyan:.:")
	end
end

ai_card_use["#sfofl_2_zhanyan"] = function(self, card, use, request)
	local target = nil
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Fire) and not package_known(self,"cantbeHurt",enemy) then
            target = enemy
            break
        end
	end
	if target then
	use.card = source_construct(self,"#sfofl_2_zhanyan:%s:")
	if use.to then package_call(use.to,"append",target) end
	end
end
sgs.ai_card_intention["sfofl_2_zhanyan"] = 80

ai_skill_choice["sfofl_2_zhanyan"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	local target = package_call(data,"toPlayer")
	local not_red,known, red = 0,0, 0
	local flag = string.format("%s_%s_%s","visible",package_known(self.player,"objectName"),package_known(target,"objectName"))
	for _,c in sgs.qlist(package_known(target,"getCards","h"))do
		if package_known(self.player,"canSeeHandcard",target) or package_known(c,"hasFlag","visible") or package_known(c,"hasFlag",flag) then
			known = known+1
			if package_known(c,"isRed") then
				red = red + 1
			else
				not_red = not_red+1
			end
		end
	end
	if red > 0 then
		return ai_choice_result((red), options)
	end
	return ai_choice_result((items[math.random(1, #items)]), options)
end


ai_fill_skill.sfofl_wusheng = function(self, options, request)
    local inclusive = options and options.inclusive

	for _,p in sgs.list(patterns_for(self))do
		local dc = clone(self,p)
		if dc and package_known(dc,"getTypeId")==1 and package_known(self,"getCardsNum",package_known(dc,"getClassName"))<1
		and package_known(self.player,"getStrategyMark","sfofl_wusheng_guhuo_remove_"..p)<1 then
			local cards = package_known(self.player,"getCards","h")
			cards = sgs.QList2Table(cards)
			package_call(self,"sortByKeepValue",cards)
			package_call(dc,"setSkillName","sfofl_wusheng")
			for _,h in sgs.list(cards)do
				if package_known(h,"isRed") then
					package_call(dc,"addSubcard",h)
					if package_known(dc,"isAvailable",self.player) then
						local d = package_known(self,"aiUseCard",dc)
						if d.card then
							return dc
						end
					end
					package_call(dc,"clearSubcards")
					break
				end
			end
		end
	end
end

sgs.ai_guhuo_card.sfofl_wusheng = function(self,toname,class_name)
	if package_known(self,"getCardsNum",class_name)<1
		and package_known(self.player,"getStrategyMark","sfofl_wusheng_guhuo_remove_"..class_name)<1 then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)
		local dc = clone(self,toname)
		if (not dc) then return end
		package_call(dc,"setSkillName","sfofl_wusheng")
		for _,h in sgs.list(cards)do
			if package_known(h,"isRed") then
				package_call(dc,"addSubcard",h)
				if not package_known(self.player,"isLocked",dc) then
					return package_known(dc,"toString")
				end
				package_call(dc,"clearSubcards")
				break
			end
		end
	end
end

sgs.ai_skill_askforyiji.sfofl_yure = function(self,card_ids,tos)
    local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to and id then return to,id end
    for _,target in sgs.list(tos)do
		if package_known(self,"isFriend",target)
		then return target,card_ids[1] end
	end
    for _,target in sgs.list(tos)do
		return target,card_ids[1]
	end
end
ai_skill_invoke.sfofl_yure = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local move = package_known(data,"toMoveOneTime")
	local card_ids = sgs.IntList()
	for _,card_id in sgs.qlist(move.card_ids) do
		local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
		if flag == sgs.CardMoveReason_S_REASON_DISCARD and package_known(self.room,"getCardPlace",card_id) == sgs.Player_DiscardPile then
			package_call(card_ids,"append",card_id)
		end
	end
	if #self.friends_noself == 0 then return (false) or false end
	if package_known(card_ids,"length") > 3 then return (true) or false end
	if package_known(self,"isWeak") and package_known(card_ids,"length") >= 2 then return (true) or false end
	return (false) or false
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|sfofl_suiqu"
ai_skill_choice["sfofl_suiqu"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	if table.contains(items, "hp") then
		if (package_known(self,"hasSkills",sgs.need_maxhp_skill) or package_known(self.player,"getMaxHp") < 4) and not package_known(self,"isWeak") then
			return ai_choice_result(("maxhp"), options)
		end
		return ai_choice_result(("hp"), options)
	end
	return ai_choice_result(("maxhp"), options)
end

local sfofl_zainei_skill = {}
sfofl_zainei_skill.name = "sfofl_zainei"
table.insert(package_skills, sfofl_zainei_skill)
sfofl_zainei_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.friends_noself == 0 then return end
	if not package_known(self.player,"isKongcheng") and not package_known(self.player,"hasUsed","#sfofl_zainei") then
		return source_construct(self,"#sfofl_zainei:.:")
	end
end

ai_card_use["#sfofl_zainei"] = function(self, card, use, request)
	package_call(self,"sort",self.friends_noself, "handcard")
	if package_known(self.player,"hasSkill","sfofl_hanwei") then
		for _, friend in ipairs(self.friends_noself) do
			if not package_known(self,"needKongcheng",friend, true) and not hasManjuanEffect(friend) and package_known(self.player,"distanceTo",friend) > 1 then
				if package_known(friend,"hasSkills",sgs.cardneed_skill) then
					use.card = source_construct(self,"#sfofl_zainei:.:")
					if use.to then package_call(use.to,"append",friend) end
					return
				end
				if getCardsNum("Slash", friend, self.player) + package_known(self,"getCardsNum","Slash") > 1 then
					use.card = source_construct(self,"#sfofl_zainei:.:")
					if use.to then package_call(use.to,"append",friend) end
					return
				end
			end
		end
	end
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sort",self.enemies, "handcard")
	local slashcount = package_known(self,"getCardsNum","Slash")
	package_call(self,"sortByUseValue",cards, true)
	if slashcount > 0 then
		local slash = package_call(self,"getCard","Slash")
		if slash then
			assert(slash)
			local target
			local dummy_use = package_known(self,"withOwnerRange","slashNoDistanceLimit","#sfofl_zainei",function() return package_known(self,"aiUseCard",slash, dummy()) end)
			if dummy_use.card and dummy_use.to then
				if not package_known(dummy_use.to,"isEmpty") then
					for _, p in sgs.qlist(dummy_use.to) do
						if not package_known(self.player,"inMyAttackRange",p) then
							target = p
						end
					end
				end
			end
			if target then
				use.card = source_construct(self,"#sfofl_zainei:.:")
				if use.to then package_call(use.to,"append",target) end
				return
			end
		end
	end
end

sgs.ai_use_priority["sfofl_zainei"] = 10
sgs.ai_use_value["sfofl_zainei"] = 2.45
sgs.ai_card_intention.sfofl_zainei = -80

local sfofl_hanwei_skill = {}
sfofl_hanwei_skill.name = "sfofl_hanwei"
table.insert(package_skills, sfofl_hanwei_skill)
sfofl_hanwei_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.friends_noself == 0 then return end
	if not package_known(self.player,"isKongcheng") and not package_known(self.player,"hasUsed","#sfofl_hanwei") then
		return source_construct(self,"#sfofl_hanwei:.:")
	end
end

ai_card_use["#sfofl_hanwei"] = function(self, card, use, request)
	package_call(self,"sort",self.friends_noself, "handcard")
	local use_cards = {}
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	for _, acard in ipairs(cards) do
		if not package_known(acard,"isDamageCard") then
			table.insert(use_cards, package_known(acard,"getEffectiveId"))
		end
	end
	if #use_cards > 0 then
		for _, friend in ipairs(self.friends_noself) do
			if not package_known(self,"needKongcheng",friend, true) and not hasManjuanEffect(friend) and package_known(self.player,"distanceTo",friend) <= 1 then
				if package_known(friend,"hasSkills",sgs.cardneed_skill) then
					use.card = source_construct(self,"#sfofl_hanwei:" .. table.concat(use_cards, "+")..":")
					if use.to then package_call(use.to,"append",friend) end
					return
				end
				if getCardsNum("Slash", friend, self.player) + package_known(self,"getCardsNum","Slash") > 1 then
					use.card = source_construct(self,"#sfofl_hanwei:" .. table.concat(use_cards, "+")..":")
					if use.to then package_call(use.to,"append",friend) end
					return
				end
			end
		end
	end
end

sgs.ai_use_priority["sfofl_hanwei"] = 10
sgs.ai_use_value["sfofl_hanwei"] = 2.45
sgs.ai_card_intention.sfofl_hanwei = -80




local sfofl_xiongshiAttach_skill = {}
sfofl_xiongshiAttach_skill.name = "sfofl_xiongshiAttach"
table.insert(package_skills, sfofl_xiongshiAttach_skill)
sfofl_xiongshiAttach_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self.player,"getStrategyFlag","Forbidsfofl_xiongshi") then return nil end

	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	if not cards[1] then return nil end
	local card_str = "#sfofl_xiongshi:" .. package_known(cards[1],"getEffectiveId") .. ":"
	local skillcard = source_construct(self,card_str)
	return skillcard
end

ai_card_use["#sfofl_xiongshi"] = function(self, card, use, request)
	if package_known(self,"needBear") or package_known(self,"getCardsNum","Jink", "h") <= 1 then
		return
	end
	local targets = {}
	for _, friend in ipairs(self.friends) do
		if package_known(friend,"hasSkill","sfofl_xiongshi") then
			if not package_known(friend,"getStrategyFlag","sfofl_xiongshiInvoked") then
				table.insert(targets, friend)
			end
		end
	end
	if #targets > 0 then
		use.card = card
		package_call(self,"sort",targets, "defense")
		if use.to then
			package_call(use.to,"append",targets[1])
		end
	elseif package_known(self,"getCardsNum","Slash", "he") >= 2 then
		for _, enemy in ipairs(self.enemies) do
			if package_known(enemy,"hasSkill","sfofl_xiongshi") then
				if not package_known(enemy,"getStrategyFlag","sfofl_xiongshiInvoked") then
					if  package_known(enemy,"hasSkill","sfofl_defeng") then
						table.insert(targets, enemy)
					end
				end
			end
		end
		if #targets > 0 then

			package_call(self,"sort",targets, "defense", true)
			for _, enemy in ipairs(targets) do
				if package_known(self.player,"canSlash",enemy, nil, false, 0) and package_known(enemy,"hasSkill","sfofl_defeng") then
					use.card = card
					if use.to then
						package_call(use.to,"append",enemy)
					end
					break
				end
			end

		end
	end
end

sgs.ai_card_intention.sfofl_xiongshi = function(self, card, from, tos)
	if package_known(tos[1],"isKongcheng") and package_known(self,"needKongcheng",tos[1],true) then
	else
		sgs.updateIntention(from, tos[1], -80)
	end
end

sgs.ai_use_priority.sfofl_xiongshi = 10
sgs.ai_use_value.sfofl_xiongshi = 8.5

sgs.ai_ajustdamage_from.sfofl_defeng = function(self, from, to, card, nature)
	local ids = sgs.IntList()
	for _,key in sgs.list(package_known(from,"getPileNames"))do
		for _,id in sgs.list(package_known(from,"getPile",key))do
			package_call(ids,"append",id)
		end
	end
	if not package_known(ids,"isEmpty") and not package_known(self,"beFriend",to, from)
	then
		return 1
	end
end
sgs.ai_ajustdamage_to.sfofl_defeng = function(self, from, to, card, nature)
	local ids = sgs.IntList()
	for _,key in sgs.list(package_known(to,"getPileNames"))do
		for _,id in sgs.list(package_known(to,"getPile",key))do
			package_call(ids,"append",id)
		end
	end
	if not package_known(ids,"isEmpty") and not package_known(self,"beFriend",to, from)
	then
		return 1
	end
end
sgs.ai_skill_askforag.sfofl_defeng = function(self,card_ids)
	local damage = source_fact(self,"sfofl_defeng","toDamage")
	if package_known(self.player,"hasSkill","sfofl_defeng") then
		if damage.to and package_known(self,"isFriend",damage.to) then
			if not package_known(self,"damageStruct",damage) or package_known(self,"cantDamageMore",self.player, damage.to) then
				for _,id in sgs.list(card_ids)do
					return id
				end
			end
		else
			if package_known(self,"damageStruct",damage) and not package_known(self,"cantDamageMore",self.player, damage.to) then
				for _,id in sgs.list(card_ids)do
					return id
				end
			end
		end
	else
		if damage.to and package_known(self,"isFriend",damage.to) then
			if not package_known(self,"damageStruct",damage) or package_known(self,"cantDamageMore",self.player, damage.to) then
				for _,id in sgs.list(card_ids)do
					return id
				end
			end
		else
			if package_known(self,"damageStruct",damage) and not package_known(self,"cantDamageMore",self.player, damage.to) then
				for _,id in sgs.list(card_ids)do
					return id
				end
			end
		end
	end

	return -1
end

ai_skill_use["@@sfofl_deshi"]=function(self,prompt,request)
	package_call(self,"sort",self.enemies,"defense")
	if package_known(self,"needBear") then return "." end

	local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
	package_call(slash,"deleteLater")
	package_call(slash,"setSkillName","sfofl_deshi")
	package_call(slash,"addSubcards",package_known(self.player,"getHandcards"))
	local tos = {}
	for _,target in sgs.list(self.enemies)do
		if not package_known(self,"slashProhibit",slash,target) and
		package_known(self,"isGoodTarget",target,self.enemies,slash) and
		package_known(self,"slashIsEffective",slash,target) then
			if package_known(self.player,"getHandcardNum") >= package_known(target,"getHp") and not package_known(self,"cantDamageMore",self.player, target) and package_known(self,"canHit",target,self.player,true) then
				table.insert(tos,package_known(target,"objectName"))
				if #tos >= correct_target(self,"ExtraTarget",slash) then
					break
				end
			end
		end
	end
	if #tos > 0 then
		local to_give = {}
		local handcards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		for _,c in ipairs(handcards) do
			table.insert(to_give, package_known(c,"getEffectiveId"))
		end
		return "#sfofl_deshi:"..table.concat(to_give, "+")..":->"..table.concat(tos,"+")
	end


	return "."
end


sgs.ai_ajustdamage_from.sfofl_deshi = function(self, from, to, card, nature)
	if card and package_known(card,"isKindOf","Slash") and table.contains(package_known(card,"getSkillNames"), "sfofl_deshi")
	then
		return package_known(card,"subcardsLength") - 1
	end
end

sgs.ai_skill_playerchosen.sfofl_xianjiang = function(self,targets)
	return package_known(self,"findPlayerToDraw",false,2)
end
sgs.ai_playerchosen_intention.sfofl_xianjiang = -80

ai_skill_choice["sfofl_tianpan"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	local judge = package_known(data,"toJudge")
	if package_known(judge.card,"getSuit") == sgs.Card_Spade then
		if table.contains(items, "hp") then
			if (package_known(self,"hasSkills",sgs.need_maxhp_skill) or package_known(self.player,"getMaxHp") < 4) and not package_known(self,"isWeak") then
				return ai_choice_result(("gainmaxhp"), options)
			end
			return ai_choice_result(("gainhp"), options)
		end
	else
		return ai_choice_result((ai_skill_choice.benghuai(self,{reason="benghuai",choices=options and options.choices or (choices~=nil and {} or nil),inquiry_scope="nested"},request)), options)
	end
	return ai_choice_result(("maxhp"), options)
end

ai_skill_invoke.sfofl_gaiming = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local judge = package_known(data,"toJudge")
	if not package_known(judge,"isGood") then
	return (true) or false end
	return (false) or false
end

sgs.ai_ajustdamage_from.sfofl_tunquan = function(self, from, to, card, nature)
	if package_known(from,"getStrategyMark","sfofl_tunquan-Clear") > 0 and package_known(from,"getStrategyMark","sfofl_tunquan_damage-Clear") == 0 	then
		return 1
	end
end


local sfofl_qianjun_skill = {}
sfofl_qianjun_skill.name = "sfofl_qianjun"
table.insert(package_skills,sfofl_qianjun_skill)
sfofl_qianjun_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_qianjun:.:")
end

ai_card_use["#sfofl_qianjun"] = function(self, card, use, request)
	if package_known(self,"isWeak") then
		for _,friend in ipairs(self.friends_noself)do
			if package_known(friend,"hasSkills",sgs.need_equip_skill) then
				use.card = card
				package_call(use.to,"append",friend)
				return
			end
		end
		for _,friend in ipairs(self.friends_noself)do
			if not hasManjuanEffect(friend) then
				use.card = card
				package_call(use.to,"append",friend)
				return
			end
		end
		package_call(self,"sort",self.friends)
		for _,target in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player))do
			use.card = card
			package_call(use.to,"append",target)
			return
		end
	end
	if not package_known(self.player,"isWounded") then
		local killer
		package_call(self,"sort",self.friends_noself)
		for _,target in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player))do
			local canUse = false
			for _,friend in ipairs(self.friends_noself)do
				if package_known(friend,"inMyAttackRange",target) and package_known(self,"damageIsEffective",target,nil,friend)
					and not package_known(self,"needToLoseHp",target,friend) and package_known(self,"isWeak",target) then
					canUse = true
					killer = friend
					break
				end
			end
			if canUse then
				use.card = card
				package_call(use.to,"append",killer)
				return
			end
		end
	end

	if #self.friends_noself==0 then return end
	if package_known(self.player,"getEquips"):length()>2 or package_known(self.player,"getEquips"):length()>#self.enemies and turn_count(self)>2 then
		local function cmp_AttackRange(a,b)
			local ar_a = package_known(a,"getAttackRange")
			local ar_b = package_known(b,"getAttackRange")
			if ar_a==ar_b then
				return sgs.getDefense(a)>sgs.getDefense(b)
			else
				return ar_a>ar_b
			end
		end
		table.sort(self.friends_noself,cmp_AttackRange)
		use.card = card
		package_call(use.to,"append",self.friends_noself[1])
	end
end

sgs.ai_use_priority.sfofl_qianjun = 4.9
sgs.ai_card_intention.sfofl_qianjun = function(self,card,from,tos)
	if not package_known(from,"isWounded") then sgs.updateIntentions(from,tos,-10) end
end



sgs.ai_ajustdamage_from.sfofl_juedian = function(self, from, to, card, nature)
	if card and package_known(card,"hasFlag","sfofl_juedian") then
		return 1
	end
end


ai_skill_choice["sfofl_juedian"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = package_known(data,"toDamage").to
	local items = package_known(choices,"split","+")
	if table.contains(items, "beishui") and package_known(self.player,"getHp") > 1 and package_known(self.player,"getMaxHp") > 1 then
		if package_known(self,"objectiveLevel",target) > 3 and not package_known(self,"cantbeHurt",target) and not package_known(self,"cantDamageMore",self.player, target) then
			local duel = clone_native(self,"duel", sgs.Card_NoSuit, 0)
			package_call(duel,"deleteLater")
			package_call(duel,"setSkillName","sfofl_juedian")
			local dummy_use = package_known(self,"aiUseCard",duel, dummy(true, 0, package_known(self.room,"getOtherPlayers",target)))
			if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) then
				return ai_choice_result(("beishui"), options)
			end
		end
		if package_known(self.player,"getStrategyMark","sfofl_nitian-Clear") > 0 and package_known(self,"isEnemy",target) and not package_known(self,"cantDamageMore",self.player, target) then
			return ai_choice_result(("beishui"), options)
		end
	end
	if table.contains(items, "hp") then
		if (package_known(self,"hasSkills",sgs.need_maxhp_skill) or package_known(self.player,"getMaxHp") < 4) and not package_known(self,"isWeak") then
			return ai_choice_result(("maxhp"), options)
		end
		return ai_choice_result(("hp"), options)
	end
	return ai_choice_result(("maxhp"), options)
end


local sfofl_nitian_skill = {}
sfofl_nitian_skill.name = "sfofl_nitian"
table.insert(package_skills,sfofl_nitian_skill)
sfofl_nitian_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies<=0 then return end
	if package_known(self,"needBear") then return end
	for _,enemy in sgs.list(self.enemies)do
		if package_known(self,"damageMinusHp",enemy,1)>0
		or package_known(enemy,"getHp")<3 and package_known(self,"damageMinusHp",enemy,0)>0 and package_known(enemy,"getHandcardNum")>0
		then
			return source_construct(self,"#sfofl_nitian:.:")
		end
	end
	if self.role=="renegade" or self.role=="lord" then return end
	if (#self.friends>1) or (#self.enemies==1 and turn_count(self)>1) then
		if package_known(self,"getAllPeachNum")==0 and package_known(self.player,"getHp")==1 then
			return source_construct(self,"#sfofl_nitian:.:")
		end
		if package_known(self,"isWeak") and self.role=="rebel" and package_known(self.player,"inMyAttackRange",package_call(self.room,"getLord")) and package_known(self,"hasCrossbowEffect") then
			return source_construct(self,"#sfofl_nitian:.:")
		end
	end
end

ai_card_use["#sfofl_nitian"] = function(self, card, use, request)
	use.card = card
	return
end

sgs.ai_use_priority["sfofl_nitian"] = 10

ai_skill_invoke.sfofl_dafu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	if package_known(self,"isFriend",target) then
		if package_known(target,"isKongcheng") then return (true) or false end
		if (package_known(target,"getHandcardNum") >= 3 or package_known(self,"isWeak",target)) then return (false) or false end
		if package_known(self,"needToLoseHp",target,self.player) then
			return (true) or false
		end
	end
	if package_known(target,"isKongcheng") then return (false) or false end
	if package_known(self.player,"hasSkill","sfofl_jipin") and package_known(target,"getHandcardNum") + 1 >= package_known(self.player,"getHandcardNum") then return (true) or false end
	if math.random() < 0.5 then return (true) or false end
	return (false) or false
end

ai_skill_invoke.sfofl_jipin = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = package_known(data,"toDamage")
	return (package_known(self,"doDisCard",damage.to, "h", true)) or false
end
sgs.ai_skill_playerchosen.sfofl_jipin = function(self, targets)
	local cards = {}
	table.insert(cards,disclosed_card(self,package_known(self.player,"getStrategyMark","sfofl_jipin")))
	local card, friend = package_call(self,"getCardNeedPlayer",cards)
	if card and friend then
		if package_known(targets,"contains",friend) then
			return friend
		end
	end
	if package_known(self,"getOverflow") > 0 then
		return package_known(self,"findPlayerToDraw",false, 1)
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_jipin = -80

local sfofl_jukou_skill = {}
sfofl_jukou_skill.name = "sfofl_jukou"
table.insert(package_skills,sfofl_jukou_skill)
sfofl_jukou_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_jukou:.:")
end

ai_card_use["#sfofl_jukou"] = function(self, card, use, request)
	for _,p in sgs.list(sgs.QList2Table(package_known(self.room,"getAllPlayers")))do
		local ids = sgs.IntList()
		for _,key in sgs.list(package_known(p,"getPileNames"))do
			for _,id in sgs.list(package_known(p,"getPile",key))do
				package_call(ids,"append",id)
			end
		end
		if not package_known(ids,"isEmpty") then
			if package_known(self,"isFriend",p) and package_known(p,"hasSkill","sfofl_defeng") or package_known(self,"isEnemy",p) then
				use.card = card
				package_call(use.to,"append",p)
				return
			end
		end
	end
	local to = package_known(self,"findPlayerToDraw",false)
	if to then
		package_call(self,"setPriorityValue","sfofl_jukou", 0,"sfoflCard.source")
		use.card = card
		package_call(use.to,"append",to)
		return
	end
end
sgs.ai_use_priority["sfofl_jukou"] = 10

ai_skill_choice.sfofl_jukou = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local choice1 = getChoice(choices, "draw")
	local choice2 = getChoice(choices, "obtain")
	if choice2 then return ai_choice_result((choice2), options) end
	local items = package_known(choices,"split","+")
	if choice1 then return ai_choice_result((choice1), options) end
	return ai_choice_result((items[1]), options)
end

local sfofl_shupan_skill = {}
sfofl_shupan_skill.name = "sfofl_shupan"
table.insert(package_skills,sfofl_shupan_skill)
sfofl_shupan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self.room,"getAlivePlayers"):length()<3 then
		return
	end
	if #self.enemies<1 then	return end
	return source_construct(self,"#sfofl_shupan:.:")
end

ai_card_use["#sfofl_shupan"] = function(self, card, use, request)
	local first,second
	local max = 0
	local targets = sgs.QList2Table(package_known(self.room,"getOtherPlayers",self.player))
	package_call(self,"sort",targets,"handcard", true)
	for _,p in sgs.list(targets)do
		local x = 0
		local kc = getKnownCards(p,self.player)
		for _,c in sgs.list(kc)do
			if package_known(c,"isDamageCard") then
				x = x + 1
			end
		end
		x = x + package_known(p,"getHandcardNum")/3
		if x > max then
			max = x
		end
	end
	for _,p in sgs.list(targets)do
		local x = 0
		local kc = getKnownCards(p,self.player)
		for _,c in sgs.list(kc)do
			if package_known(c,"isDamageCard") then
				x = x + 1
			end
		end
		x = x + package_known(p,"getHandcardNum")/3
		if x == max then
			first = p
			break
		end
	end
	if max > 3 then
		package_call(self,"sort",self.enemies,"defense")
		for _,enemy in sgs.list(self.enemies)do
			if (package_known(self,"isGoodTarget",enemy,self.enemies) or hasManjuanEffect(enemy)) and package_known(first,"objectName") ~= package_known(enemy,"objectName")  then
				second = enemy
				break
			end
		end
	end
	if first and second then
		use.card = card
		package_call(use.to,"append",second)
		package_call(use.to,"append",first)
		return
	end
	if package_known(self,"isWeak") then
		local min = 999
		local targets = sgs.QList2Table(package_known(self.room,"getOtherPlayers",self.player))
		package_call(self,"sort",targets,"handcard")
		for _,p in sgs.list(targets)do
			local x = 0
			local kc = getKnownCards(p,self.player)
			for _,c in sgs.list(kc)do
				if package_known(c,"isDamageCard") then
					x = x + 1
				end
			end
			x = x + package_known(p,"getHandcardNum")/3
			if x < min then
				min = x
			end
		end
		for _,p in sgs.list(targets)do
			local x = 0
			local kc = getKnownCards(p,self.player)
			for _,c in sgs.list(kc)do
				if package_known(c,"isDamageCard") then
					x = x + 1
				end
			end
			x = x + package_known(p,"getHandcardNum")/3
			if x == min then
				first = p
				break
			end
		end
		local to = package_known(self,"findPlayerToDraw",false, 3)
		if to and package_known(first,"objectName") ~= package_known(to,"objectName") then
			use.card = card
			package_call(use.to,"append",to)
			package_call(use.to,"append",first)
		end
	end
end

sgs.ai_use_value.sfofl_shupan = 8.5
sgs.ai_use_priority.sfofl_shupan = 4

sgs.ai_ajustdamage_from.sfofl_yingzhan = function(self, from, to, card, nature)
	if nature ~= "N" then
		return 1
	end
end
sgs.ai_ajustdamage_to.sfofl_yingzhan = function(self, from, to, card, nature)
	if nature ~= "N" then
		return 1
	end
end

ai_skill_use["@@sfofl_cuiji"]=function(self,prompt,request)
	package_call(self,"sort",self.enemies,"defense")
	local slash = clone_native(self,"thunder_slash", sgs.Card_NoSuit, 0)
	package_call(slash,"deleteLater")
	package_call(slash,"setSkillName","sfofl_cuiji")
	local current = package_call(self.room,"getCurrent")
	if not current or package_known(current,"isDead") then return "." end
	local dummy_use = package_known(self,"aiUseCard",slash, dummy(true))
	if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",current) then
		local cards = package_known(self.player,"getCards","h")
		cards = package_call(self,"sortByKeepValue",cards,nil,true)
		for _,c in sgs.list(cards)do do
			if package_known(self,"getKeepValue",c)>3 then goto package_continue_11 end
			if (package_known(self.player,"hasSkill","sfofl_kunjun") and (#cards - package_known(slash,"subcardsLength") > package_known(current,"getHandcardNum"))) or (package_known(slash,"subcardsLength")<#cards/2) then
				package_call(slash,"addSubcard",c)
			end
		end ::package_continue_11:: end
		if package_known(slash,"subcardsLength")<1 and #cards>1	then
			package_call(slash,"addSubcard",cards[1])
		end
		return package_known(slash,"toString") ..":->"..package_known(current,"objectName")
	end
	return "."
end

sgs.ai_ajustdamage_from.sfofl_paoxi = function(self, from, to, card, nature)
	if package_known(from,"getStrategyMark","sfofl_paoxi+2_num-Clear") > 0 then
		return 1
	end
end
sgs.ai_ajustdamage_to.sfofl_paoxi = function(self, from, to, card, nature)
	if package_known(to,"getStrategyMark","sfofl_paoxi+1_num-Clear") > 0 then
		return 1
	end
end

package_add("sfofl_houying").getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards = package_call(self,"sortByKeepValue",cards,nil,true)
	if #cards<1 then return end
	local ids = {}
   	local fs = clone(self)
	package_call(fs,"setSkillName","sfofl_houying")
  	for _,c in sgs.list(cards)do do
		if package_known(self,"getKeepValue",c)>3 or not package_known(c,"isBlack")
		or #ids >= 2 then goto package_continue_12 end
		table.insert(ids,package_known(c,"getEffectiveId"))
	end ::package_continue_12:: end
	local dummy_use = package_known(self,"aiUseCard",fs)
	if package_known(fs,"isAvailable",self.player)
	and dummy_use.card
	and dummy_use.to
	and #ids>1
  	then
		source_state(self).olcb_to = dummy_use.to
		return source_construct(self,"#sfofl_houying:".. table.concat(ids,"+")..":")
	end
end

ai_card_use["#sfofl_houying"] = function(self, card, use, request)
	use.card = card
	use.to = source_state(self).olcb_to
end

sgs.ai_use_value.sfofl_houying = 9.4
sgs.ai_use_priority.sfofl_houying = 2.8

sgs.ai_ajustdamage_from.sfofl_wuxiao = function(self, from, to, card, nature)
	if package_known(from,"getStrategyMark","sfofl_wuxiao+2_num-Clear") > 0 then
		return 1
	end
end
sgs.ai_ajustdamage_to.sfofl_wuxiao = function(self, from, to, card, nature)
	if package_known(to,"getStrategyMark","sfofl_wuxiao+1_num-Clear") > 0 then
		return 1
	end
end

package_add("sfofl_qianhu").getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards = package_call(self,"sortByKeepValue",cards,nil,true)
	if #cards<1 then return end
	local ids = {}
   	local fs = clone(self,"duel")
	package_call(fs,"setSkillName","sfofl_qianhu")
  	for _,c in sgs.list(cards)do do
		if package_known(self,"getKeepValue",c)>3 or not package_known(c,"isRed")
		or #ids >= 2 then goto package_continue_13 end
		table.insert(ids,package_known(c,"getEffectiveId"))
	end ::package_continue_13:: end
	local dummy_use = package_known(self,"aiUseCard",fs)
	if package_known(fs,"isAvailable",self.player)
	and dummy_use.card
	and dummy_use.to
	and #ids>1
  	then
		source_state(self).olcb_to = dummy_use.to
		return source_construct(self,"#sfofl_qianhu:".. table.concat(ids,"+")..":")
	end
end

ai_card_use["#sfofl_qianhu"] = function(self, card, use, request)
	use.card = card
	use.to = source_state(self).olcb_to
end

sgs.ai_use_value.sfofl_qianhu = 9.4
sgs.ai_use_priority.sfofl_qianhu = 2.8


sgs.ai_use_revises.sfofl_sanshou = function(self,card)
	if package_known(self.player,"getPhase") < sgs.Player_Finish and package_known(self.player,"getStrategyMark","sfofl_shenzhangliang-Clear") == 0 and package_known(self,"getOverflow") < 1
	then
		if package_known(card,"isKindOf","TrickCard") and (package_known(card,"targetFixed") and not package_known(card,"isDamageCard") or package_known(card,"canRecast") or ("snatch|collateral"):match(package_known(card,"objectName"))) or package_known(card,"isKindOf","Slash")
		then return end
		return false
	end
end

ai_skill_invoke.sfofl_mingdao = true

ai_skill_choice.sfofl_YellowTurbanRebels = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	return ai_choice_result((items[math.random(1, #items)]), options)
end

ai_skill_invoke.sfofl_zhongfu = true

sgs.ai_choicemade_filter.cardResponded["@sfofl_zhongfu"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local target = package_call(self.room,"findPlayerByObjectName",promptlist[4])
		if target then
			sgs.updateIntention(player, target, -40)
		end
	end
end

sgs.ai_skill_cardask["@sfofl_zhongfu"] = function(self, data)
	local target = package_call(data,"toPlayer")
	if package_known(self,"isFriend",target) and package_known(target,"hasSkill","sfofl_dangjing") then
		local max = 0
		for _, p in sgs.qlist(package_known(self.room,"getAllPlayers")) do
			if package_known(p,"getEquips"):length() > max then
				max = package_known(p,"getEquips"):length()
			end
		end
		if package_known(target,"getEquips"):length() >= max then
			local cards = package_known(self.player,"getCards","he")
			cards = sgs.QList2Table(cards)
			package_call(self,"sortByKeepValue",cards)
			local suit
			for _, mark in sgs.list(package_known(target,"getMarkNames")) do
				if string.find(mark, "sfofl_zhongfu") and package_known(target,"getStrategyMark",mark) > 0 then
					suit = package_known(mark,"split","+")[3]:split("_")[1]
				end
			end
			if suit then
				for _,h in sgs.list(cards)do
					if package_known(h,"getSuitString") == suit then
						return package_known(h,"getEffectiveId")
					end
				end
			end
		end
		return true
	end
	if package_known(self,"doDisCard",self.player, "he", true) then return true end
	return "."
end

sgs.ai_skill_playerchosen.sfofl_dangjing = function(self,targets)
	return package_known(self,"findBestDamageTarget",1, "T")
end

sgs.ai_playerchosen_intention.sfofl_dangjing = sgs.ai_playerchosen_intention.leiji
ai_skill_invoke.sfofl_dangjing = true


ai_skill_invoke.sfofl_jijun = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local tr = package_known(data,"toString")
	if tr == "obtain" and not package_known(self.player,"hasSkill","sfofl_fangtong") then return (false) or false end
	return (true) or false
end


local function fangtongca(self,tasum, card_ids)
	local sum = 0
	local usecards = {}
	if package_known(card_ids,"length") > 30 then
		for _,id in sgs.qlist(card_ids) do
			local card = disclosed_card(self,id)
			if (package_known(card,"getNumber") + sum) <= tasum then
				table.insert(usecards,id)
				sum = sum + package_known(card,"getNumber")
			end
		end
	else
		local n = package_known(card_ids,"length")
		local allcards = {}
		for _,id in sgs.qlist(card_ids) do
			table.insert(allcards, id)
		end
		for i = 1, 2^n, 1 do
			sum = 0
			usecards = {}
			for j = 1, n, 1 do
				if bit32.band(i,(2^j)) ~= 0 then
					table.insert(usecards,allcards[j])
				end
			end
			for _,id in ipairs(usecards) do
				sum = sum + disclosed_card(self,id):getNumber()
			end
			if sum == tasum then break end
		end
	end

	if sum == tasum then
		return usecards
	else
		return {}
	end
end

sgs.ai_skill_cardask["@sfofl_fangtong-invoke"] = function(self, data)
	if package_known(self.player,"isNude") then return "." end
	local card_ids = package_known(self.player,"getPile","sfofl_fang")
	local allcards = {}
	local sum = 0
	for _,id in sgs.qlist(card_ids) do
		sum = sum + disclosed_card(self,id):getNumber()
		table.insert(allcards,id)
	end
	if sum < 23 then return "." end
	package_call(self,"sort",self.enemies, "defense")
	local target = nil
	for _,enemy in ipairs(self.enemies) do
		if package_known(enemy,"isAlive") and not package_known(self,"cantDamageMore",self.player, enemy) and package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder) and not package_known(self,"cantbeHurt",enemy) and package_known(self,"canDamage",enemy,self.player,nil) then
			target = enemy
			break
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if package_known(enemy,"isAlive") and package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder) and not package_known(self,"cantbeHurt",enemy) and package_known(self,"canDamage",enemy,self.player,nil) then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if package_known(enemy,"isAlive") then
				target = enemy
				break
			end
		end
	end

	if not target then return "." end
	source_state(self).fangtong_to = target
	local use_card
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local usecards = {}
	for _,card in ipairs(cards) do
		sum = 0
		local tem = 36 - package_known(card,"getNumber")
		usecards = fangtongca(self,tem,card_ids)
		if #usecards > 0 then
			table.insert(usecards,package_known(card,"getEffectiveId"))
		end
		for _,c in ipairs(usecards) do
			sum = sum + disclosed_card(self,c):getNumber()
		end
		if sum == 36 then use_card = card break end
	end
	if sum ~= 36 then return "." end
	if use_card then
		return package_known(use_card,"getEffectiveId")
	end
	return "."
end
ai_skill_use["@@sfofl_fangtong"]=function(self,prompt,request)
	local card_ids = package_known(self.player,"getPile","sfofl_fang")
	local allcards = {}
	local sum = 0
	package_call(self,"sort",self.enemies, "defense")
	local target = source_state(self).fangtong_to
	if not target then return "." end

	local usecards = {}
	local tem = 36 - source_property(self,"sfofl_fangtong"):toInt()
	usecards = fangtongca(self,tem,card_ids)
	for _,c in ipairs(usecards) do
		sum = sum + disclosed_card(self,c):getNumber()
	end
	sum = sum + source_property(self,"sfofl_fangtong"):toInt()
	if sum ~= 36 then return "." end
	local card_str = "#sfofl_fangtong:"..table.concat(usecards, "+")..":->"..package_known(target,"objectName")
	return card_str
end

sgs.ai_use_revises.sfofl_fangtong = function(self,card,use)
	if package_known(card,"isKindOf","EquipCard") and package_known(self,"evaluateArmor",card)>-5 and package_known(self.player,"hasSkill","sfofl_jijun")
	then use.card = card return true end
end

local sfofl_zhouyuan_skill = {}
sfofl_zhouyuan_skill.name = "sfofl_zhouyuan"
table.insert(package_skills, sfofl_zhouyuan_skill)
sfofl_zhouyuan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_zhouyuan:.:")
end

ai_card_use["#sfofl_zhouyuan"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies,"handcard",true)
	local red, black = {}, {}
	local use_cards = {}
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	for _, acard in ipairs(cards) do
		if package_known(acard,"isRed") then
			table.insert(red, package_known(acard,"getEffectiveId"))
		elseif package_known(acard,"isBlack") then
			table.insert(black, package_known(acard,"getEffectiveId"))
		end
	end
	if #red > #black then
		use_cards = black
	elseif #black > #red then
		use_cards = red
	else
		use_cards = black
	end
	if #use_cards == 0 then
		if #red > #black then
			use_cards = red
		elseif #black > #red then
			use_cards = black
		else
			use_cards = red
		end
	end
	if #use_cards == 0 then return end
	for _,enemy in sgs.list(self.enemies)do
		if not package_known(self,"needKongcheng",enemy) then
			if package_known(self,"damageMinusHp",enemy,1)>0
			or package_known(enemy,"getHp")<3 and package_known(self,"damageMinusHp",enemy,0)>0 and package_known(enemy,"getHandcardNum")>0
			or package_known(enemy,"getHandcardNum")>=package_known(enemy,"getHp") and package_known(enemy,"getHp")>2 and package_known(self,"damageMinusHp",enemy,0)>=-1
			or package_known(enemy,"getHandcardNum")-package_known(enemy,"getHp")>2
			then
				use.card = source_construct(self,"#sfofl_zhouyuan:".. table.concat(use_cards, "+")..":")
				package_call(use.to,"append",enemy)
				return
			end
		end
	end
	for _,enemy in sgs.list(self.enemies)do
		if package_known(enemy,"getHandcardNum")>=package_known(enemy,"getHp")
		then
			use.card = source_construct(self,"#sfofl_zhouyuan:".. table.concat(use_cards, "+")..":")
			package_call(use.to,"append",enemy)
			return
		end
	end
end

sgs.ai_use_value.sfofl_zhouyuan = 9.5
sgs.ai_use_priority.sfofl_zhouyuan = 3.5
sgs.ai_card_intention.sfofl_zhouyuan = 30

local sfofl_zhaobing_skill = {}
sfofl_zhaobing_skill.name = "sfofl_zhaobing"
table.insert(package_skills,sfofl_zhaobing_skill)
sfofl_zhaobing_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = {}
	for _,id in sgs.qlist(package_known(self.player,"getPile","sfofl_zhoubing")) do
		table.insert(cards, disclosed_card(self,id))
	end
	for _,enemy in ipairs(self.enemies)do
		if not package_known(enemy,"getPile","sfofl_zhoubing"):isEmpty() then
			for _,id in sgs.qlist(package_known(enemy,"getPile","sfofl_zhoubing")) do
				table.insert(cards, disclosed_card(self,id))
			end
		end
	end
	package_call(self,"sortByUseValue",cards,true)

	if cards[1] and package_known(cards[1],"isAvailable",self.player) then
		local suit = package_known(cards[1],"getSuitString")
		local number = package_known(cards[1],"getNumberString")
		local card_id = package_known(cards[1],"getEffectiveId")
		return source_construct(self,(package_known(cards[1],"objectName")..":sfofl_zhaobing[%s:%s]=%d"):format(suit,number,card_id))
	end
end
sgs.ai_use_priority.sfofl_zhaobing = 5
sgs.ai_card_priority.sfofl_zhaobing = function(self,card)
	if table.contains(package_known(card,"getSkillNames"), "sfofl_zhaobing")
	then return 5 end
end



sgs.ai_ajustdamage_from._sfofl_YellowTurbanRebels0 = function(self, from, to, card, nature)
	if nature == "T" and foreign_fact(self,from,"sfofl_YellowTurbanRebels0","toBool") then
		return 1
	end
end
sgs.ai_ajustdamage_to._sfofl_YellowTurbanRebels0 = function(self, from, to, card, nature)
	if nature == "T" and foreign_fact(self,to,"sfofl_YellowTurbanRebels0","toBool")  then
		return 1
	end
end
sgs.ai_can_damagehp.sfofl_YellowTurbanRebels3 = function(self,from,card,to)
	return package_known(to,"getHp")+package_known(self,"getAllPeachNum")-package_known(self,"ajustDamage",from,to,1,card)>0
	and package_known(self,"canLoseHp",from,card,to)
end

sgs.ai_skill_playerschosen.sfofl_shice = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
	local card = clone_native(self,"FireAttack", sgs.Card_NoSuit, 0)
	package_call(card,"setSkillName","sfofl_shice")
	package_call(card,"deleteLater")
	local dummy_use = package_known(self,"aiUseCard",card, dummy())
	if dummy_use.card and dummy_use.to and not package_known(dummy_use.to,"isEmpty") then
		for _, p in sgs.qlist(dummy_use.to) do
			if table.contains(can_choose, p) then
				package_call(selected,"append",p)
			end
		end
	else
		for _,target in ipairs(can_choose) do
			if package_known(self,"isEnemy",target) and package_known(self.player,"canUse",card, target) then
				package_call(selected,"append",target)
				if package_known(selected,"length") >= max then break end
			end
		end
	end
    return selected
end

ai_skill_invoke.sfofl_shice = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = package_known(data,"toCardUse")
	local target = package_known(use.to,"first")
	if target then
		if package_known(self,"doDisCard",target, "e") then
			local dummy_use = package_known(self,"aiUseCard",use.card, dummy(true, 0, package_known(self.room,"getOtherPlayers",target)))
			if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) then
				return (true) or false
			end
		end
	end
	return (false) or false
end

ai_skill_choice.sfofl_podai = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local target = package_call(data,"toPlayer")
    local items = package_known(choices,"split","+")
	local choice1 = getChoice(choices, "skill")
	local choice2 = getChoice(choices, "damage")
	if choice1 and package_known(self,"isEnemy",target) then
		return ai_choice_result((choice1), options)
	end
	if choice2 then
		if package_known(self,"isFriend",target) and (package_known(self,"needToLoseHp",target, self.player) or not package_known(self,"damageIsEffective",target,"F",self.player)) then
			return ai_choice_result((choice2), options)
		end
		if package_known(self,"isEnemy",target) and package_known(self,"damageIsEffective",target,"F",self.player) and package_known(self,"isGoodTarget",target,self.enemies) then
			return ai_choice_result((choice2), options)
		end
		if package_known(target,"hasSkill","sfofl_shice") and package_known(target,"getChangeSkillState","sfofl_shice") <= 1 and package_known(target,"objectName") == package_known(self.player,"objectName") then
			return ai_choice_result((choice2), options)
		end
	end
    return ai_choice_result(("cancel"), options)
end

ai_skill_choice.sfofl_podaiskill = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	choices = package_known(choices,"split","+")
	for _,choice in sgs.list(choices)do
		if package_known(self,"isValueSkill",choice,self.player,true) then
			return ai_choice_result((choice), options)
		end
	end
	for _,choice in sgs.list(choices)do
		if package_known(self,"isValueSkill",choice,self.player) then
			return ai_choice_result((choice), options)
		end
	end
	for _,choice in sgs.list(choices)do do
		if string.find(sgs.bad_skills,choice) then goto package_continue_14 end
		return ai_choice_result((choice), options)
	end ::package_continue_14:: end
	return ai_choice_result((choices[math.random(1,#choices)]), options)
end

sgs.ai_choicemade_filter.skillChoice["sfofl_podai"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local current = package_call(self.room,"getCurrent")
	if choice == "damage" then
		if package_known(self,"needToLoseHp",current,player) or not package_known(self,"damageIsEffective",current,"F",player) then return end
		sgs.updateIntention(player, current, 40)
	end
end

sgs.ai_choicemade_filter.skillChoice["sfofl_podaiskill"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local current = package_call(self.room,"getCurrent")
	if not string.find(sgs.bad_skills, choice) then
		sgs.updateIntention(player, current, 80)
	end
end





sgs.ai_skill_playerschosen.sfofl_zhengan = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if package_known(self,"isFriend",target) then
			package_call(selected,"append",target)
			if package_known(selected,"length") >= max then break end
		end
	end
    return selected
end

ai_skill_choice["sfofl_zhengan_basic"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
    if #items == 1 then return ai_choice_result((items[1]), options) end
    if package_known(self.player,"getLostHp") > 1 then return ai_choice_result(("peach"), options) end
    table.removeOne(items, "cancel")
    for _,pattern in ipairs(items) do
        local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
		package_call(card,"deleteLater")
		local dummy_use = package_known(self,"aiUseCard",card, dummy())
        if dummy_use.to and package_known(dummy_use.to,"length") > 0 then
            return ai_choice_result((pattern), options)
        end
    end
    return ai_choice_result(("cancel"), options)
end

ai_skill_use["@@sfofl_zhengan"]=function(self,prompt,request)
	local p_choices = {}
	for _,dc in sgs.list(PatternsCard(self,"BasicCard",true))do
		package_call(dc,"setSkillName","sfofl_zhengan_basic")
		if package_known(dc,"isAvailable",self.player)	then table.insert(p_choices,package_known(dc,"objectName")) end
	end
	if ai_skill_choice["sfofl_zhengan_basic"](self,{reason="sfofl_zhengan_basic",choices=p_choices,inquiry_scope="nested"},nil) ~= "cancel" then
		return "#sfofl_zhengan_basicCard:.:"
	end
	return "."
end


ai_skill_use["@@sfofl_zhengan_basic"]=function(self,prompt,request)
	local pattern -- source unused ambient read omitted; next statement overwrites it
	pattern = package_known(self.player,"getStrategyMark","sfofl_zhengan_basic_id")
	pattern = printed_card(self,pattern)
	pattern = clone_native(self,package_known(pattern,"objectName"))
	package_call(pattern,"deleteLater")
	package_call(pattern,"setSkillName","sfofl_zhengan_basic")

    if package_known(pattern,"objectName") == "peach" or package_known(pattern,"objectName") == "analeptic" then
        return selected(self,pattern,{package_known(self.player,"objectName")})
    end
	local dummy_use = package_known(self,"aiUseCard",pattern, dummy())
	if dummy_use.to and package_known(dummy_use.to,"length") > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, package_known(to,"objectName"))
        end
        return selected(self,pattern,tos)
    end
    return "."
end


local sfofl_weizhu_skill = {}
sfofl_weizhu_skill.name = "sfofl_weizhu"
table.insert(package_skills,sfofl_weizhu_skill)
sfofl_weizhu_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_weizhu:.:")
end

ai_card_use["#sfofl_weizhu"] = function(self, card, use, request)
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
					local dummy_use = package_known(self,"aiUseCard",zcard)
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
					if package_known(self,"aiUseCard",zcard).card then shouldUse = false end
				end
				if package_known(zcard,"getTypeId")==sgs.Card_TypeEquip and not package_known(self.player,"hasEquip",zcard) then
					if package_known(self,"aiUseCard",zcard).card then shouldUse = false end
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
					if package_known(self,"aiUseCard",card).card then
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
				if not package_known(self,"aiUseCard",card).card then table.insert(unpreferedCards,package_known(card,"getId")) end
			end
		end
	end

	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not package_known(self.player,"isJilei",disclosed_card(self,unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		use.card = source_construct(self,"#sfofl_weizhu:"..table.concat(use_cards,"+")..":")
	end
end

sgs.ai_use_value.sfofl_weizhu = 9
sgs.ai_use_priority.sfofl_weizhu = 2.61
sgs.dynamic_value.benefit.sfofl_weizhu = true

sgs.ai_skill_playerschosen.sfofl_weizhu = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if package_known(self,"isFriend",target) and package_known(self,"canDraw",target, self.player) then
			package_call(selected,"append",target)
			if package_known(selected,"length") >= max then break end
		end
	end
    return selected
end


ai_fill_skill.sfofl_zequan = function(self, options, request)
    local inclusive = options and options.inclusive

	for _,pn in sgs.list(patterns_for(self))do do
		if package_known(self.player,"getStrategyMark","sfofl_zequan_guhuo_remove_"..pn)>0 then goto package_continue_15 end
		local dc = clone(self,pn)
		if dc and package_known(dc,"isNDTrick") and package_known(self,"getCardsNum",package_known(dc,"getClassName"))<1 then
			local cards = package_known(self.player,"getCards","h")
			cards = sgs.QList2Table(cards)
			package_call(self,"sortByKeepValue",cards)
			package_call(dc,"setSkillName","sfofl_zequan")
			for _,h in sgs.list(cards)do
				if package_known(h,"isKindOf","EquipCard") then
					package_call(dc,"addSubcard",h)
					if package_known(dc,"isAvailable",self.player) then
						local dummy_use = package_known(self,"aiUseCard",dc, dummy())
						if dummy_use.card and dummy_use.to and package_known(dummy_use.to,"length") > 0 then
							local useto = sgs.SPlayerList()
							for _,to in sgs.qlist(dummy_use.to) do
								if package_known(to,"getHp") >= package_known(self.player,"getHp") then
									package_call(useto,"append",to)
								end
							end
							if package_known(useto,"length") > 0 then
								dummy_use.to = useto
								source_state(self).sfofl_zequanUse = dummy_use
								package_call(self,"setPriorityValue","sfofl_zequan", sgs.ai_use_priority[package_known(dc,"getClassName")],"sfoflCard.source")
								return source_construct(self,"#sfofl_zequan:".. package_known(h,"getEffectiveId") ..":"..pn)
							end
						end
					end
					package_call(dc,"clearSubcards")
				end
			end
		end
	end ::package_continue_15:: end
end
ai_card_use["#sfofl_zequan"] = function(self, card, use, request)
	local ut = source_state(self).sfofl_zequanUse
	if ut.card then
		use.card = card
		use.to = ut.to
	end
end

sgs.ai_use_value.sfofl_zequan = 3.4
sgs.ai_use_priority.sfofl_zequan = 9.2


local sfofl_cheji_skill = {}
sfofl_cheji_skill.name = "sfofl_cheji"
table.insert(package_skills,sfofl_cheji_skill)
sfofl_cheji_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_cheji:.:")
end

ai_card_use["#sfofl_cheji"] = function(self, card, use, request)
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
					local dummy_use = package_known(self,"aiUseCard",zcard)
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
					if package_known(self,"aiUseCard",zcard).card then shouldUse = false end
				end
				if package_known(zcard,"getTypeId")==sgs.Card_TypeEquip and not package_known(self.player,"hasEquip",zcard) then
					if package_known(self,"aiUseCard",zcard).card then shouldUse = false end
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
					if package_known(self,"aiUseCard",card).card then
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
				if not package_known(self,"aiUseCard",card).card then table.insert(unpreferedCards,package_known(card,"getId")) end
			end
		end
	end

	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not package_known(self.player,"isJilei",disclosed_card(self,unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		local target
		for _,friend in ipairs(self.friends_noself)do
			if package_known(self,"canDraw",friend, self.player) and (package_known(self,"needToLoseHp",friend,self.player) or not package_known(self,"damageIsEffective",friend,"F",self.player)) then
				target = friend
				break
			end
		end
		if not target then
			for _,friend in ipairs(self.friends_noself)do
				if package_known(self,"canDraw",friend, self.player) and not package_known(self,"isWeak",friend) then
					target = friend
					break
				end
			end
		end
		if not target then
			local dc = clone(self)
            package_call(dc,"setSkillName","_sfofl_cheji")
			for _,enemy in ipairs(self.enemies)do
				if not package_known(self,"canDraw",enemy, self.player) or package_known(self,"damageIsEffective",target,"F",self.player) or package_known(self,"isGoodTarget",enemy,self.enemies, dc) then
					target = enemy
					break
				end
			end
		end
		if target then
			use.card = source_construct(self,"#sfofl_cheji:"..table.concat(use_cards,"+")..":")
			package_call(use.to,"append",target)
		end
	end
end

sgs.ai_use_value.sfofl_cheji = 9
sgs.ai_use_priority.sfofl_cheji = 2.61
sgs.dynamic_value.benefit.sfofl_cheji = true

sgs.ai_skill_playerchosen.sfofl_cheji = function(self,targets)
	local target
	for _, p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
		if package_known(p,"getStrategyFlag","sfofl_cheji_target") then
			target = p
			break
		end
	end
	local dc = clone(self)
	package_call(dc,"setSkillName","_sfofl_cheji")
	for _,p in sgs.qlist(targets) do
		if package_known(self,"isEnemy",p) and package_known(self,"isGoodTarget",p,self.enemies, dc) and not package_known(self,"needToLoseHp",p, target, dc) and  package_known(self,"slashIsEffective",dc, p) then
			return p
		end
	end
	for _,p in sgs.qlist(targets) do
		if package_known(self,"isEnemy",p) and package_known(self,"isGoodTarget",p,self.enemies, dc) and  package_known(self,"slashIsEffective",dc, p) then
			return p
		end
	end
	for _,p in sgs.qlist(targets) do
		if package_known(self,"isFriend",p) and package_known(self,"needToLoseHp",p, target, dc) then
			return p
		end
	end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self,targets)
end

ai_skill_invoke.sfofl_kuixiang = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = nil
    for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
        if package_known(p,"getStrategyFlag","sfofl_kuixiangtarget") then
            target = p
            break
        end
    end
    if not target then return (false) or false end
    return (package_known(self,"isEnemy",target)) or false
end


sgs.ai_ajustdamage_from.sfofl_jicui = function(self, from, to, card, nature)
	if card and package_known(card,"isKindOf","NatureSlash") and package_known(from,"getPhase") ~= sgs.Player_NotActive and (package_known(from,"getStrategyMark","sfofl_jicui-Clear") > 0 or package_known(card,"hasFlag","sfofl_jicui")) then
		return 1
	end
end

ai_skill_invoke.sfofl_cuixi = true

local sfofl_cuixi_skill = {}
sfofl_cuixi_skill.name = "sfofl_cuixi"
table.insert(package_skills, sfofl_cuixi_skill)
sfofl_cuixi_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_cuixi:.:")
end

ai_card_use["#sfofl_cuixi"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies,"handcard",true)
	local use_cards = {}
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	for _, acard in ipairs(cards) do
		if package_known(self,"getKeepValue",acard)<6 then
			table.insert(use_cards, package_known(acard,"getEffectiveId"))
		end
	end
	local targets = {}
	for _,enemy in sgs.list(self.enemies)do
		if package_known(enemy,"getHp")<package_known(self.player,"getHp") then
			if not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy, "N", self.player) and package_known(self,"canDamage",enemy,self.player,nil) and not package_known(self,"cantDamageMore",self.player, enemy) then
				table.insert(targets, enemy)
			end
		end
	end
	for _,enemy in sgs.list(self.enemies)do
		if package_known(enemy,"getHp")<package_known(self.player,"getHp") then
			if not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy, "N", self.player) and package_known(self,"canDamage",enemy,self.player,nil) and not table.contains(targets, enemy) then
				table.insert(targets, enemy)
			end
		end
	end
	if #targets < 2 then return end
	if #use_cards > 0 then
		use.card = source_construct(self,"#sfofl_cuixi:".. table.concat(use_cards, "+")..":")
	else
		use.card = source_construct(self,"#sfofl_cuixi:.:")
	end
	package_call(use.to,"append",targets[1])
	package_call(use.to,"append",targets[2])
	return
end

sgs.ai_use_value.sfofl_cuixi = 9.5
sgs.ai_use_priority.sfofl_cuixi = 3.5
sgs.ai_card_intention.sfofl_cuixi = 70

sgs.ai_use_revises["&sfofl_jujun"] = function(self,card,use)
	if package_known(card,"isKindOf","Peach") or package_known(card,"isKindOf","Analeptic") and package_known(self.player,"getHp")<1 then
		if package_known(self.player,"getStrategyMark","&sfofl_jujun")>0 then
			return false
		end
	end
end

local sfofl_jujun_skill = {}
sfofl_jujun_skill.name = "sfofl_jujun"
table.insert(package_skills,sfofl_jujun_skill)
sfofl_jujun_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies<=0 then return end
	if not package_known(self,"isWeak") then return end
	for _,enemy in sgs.list(self.enemies)do
		if package_known(self,"damageMinusHp",enemy,1)>0
		or package_known(enemy,"getHp")<3 and package_known(self,"damageMinusHp",enemy,0)>0 and package_known(enemy,"getHandcardNum")>0
		then
			return source_construct(self,"#sfofl_jujun:.:")
		end
	end
	if (#self.friends>1) or (#self.enemies==1 and turn_count(self)>1) then
		if package_known(self,"getAllPeachNum")==0 and package_known(self.player,"getHp")==1 then
			return source_construct(self,"#sfofl_jujun:.:")
		end
		if package_known(self,"isWeak") and self.role=="rebel" and package_known(self.player,"inMyAttackRange",package_call(self.room,"getLord")) and package_known(self,"hasCrossbowEffect") then
			return source_construct(self,"#sfofl_jujun:.:")
		end
	end
end

ai_card_use["#sfofl_jujun"] = function(self, card, use, request)
	use.card = card
	return
end

sgs.ai_use_priority["sfofl_jujun"] = 10

ai_skill_invoke.sfofl_sixi = true

ai_skill_use["@@sfofl_sixi"]=function(self,prompt,request)
	local pattern = clone_native(self,"yj_stabs_slash")
	package_call(pattern,"deleteLater")
	package_call(pattern,"setSkillName","sfofl_sixi")
	local dummy_use = package_known(self,"aiUseCard",pattern, dummy())
	if dummy_use.to and package_known(dummy_use.to,"length") > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, package_known(to,"objectName"))
        end
        return selected(self,pattern,tos)
    end
    return "."
end

local sfofl_sixi_skill = {}
sfofl_sixi_skill.name = "sfofl_sixi"
table.insert(package_skills,sfofl_sixi_skill)
sfofl_sixi_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self,"needBear") then return end
	return source_construct(self,"#sfofl_sixi:.:")
end

ai_card_use["#sfofl_sixi"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies,"handcard")
	local cards = AIList.new({})
	local peach = 0
	for _,c in sgs.qlist(package_known(self.player,"getHandcards"))do
		if isCard("Peach",c,self.player) and peach<2 then
			peach = peach+1
		else
			package_call(cards,"append",c)
		end
	end
	local max_card = package_call(self,"getMaxCard",self.player,cards)
	if not max_card then return end
	local max_point = package_known(max_card,"getNumber")
	local slashcount = package_known(self,"getCardsNum","Slash")
	if isCard("Slash",max_card,self.player) then slashcount = slashcount-1 end

	local slash = package_call(self,"getCard","Slash")
	local dummy_use = dummy(true,1)
	package_call(self,"withOwnerRange","slashNoDistanceLimit","#sfofl_sixi",function() if slash then package_call(self,"useBasicCard",slash,dummy_use) end end)

	package_call(self,"setPriorityValue","sfofl_sixiCard", (slashcount>=1 and dummy_use.card) and 7.2 or 1.2,"sfoflCard.source")
	if slashcount>=1 and slash and dummy_use.card  then
		if #self.enemies<1 then return end
		if package_known(dummy_use.to,"length")>1 then
			package_call(self,"sort",self.friends_noself,"handcard")
			for index = #self.friends_noself,1,-1 do
				local friend = self.friends_noself[index]
				if package_known(self.player,"canPindian",friend) then
					local friend_min_card = package_call(self,"getMinCard",friend)
					local friend_min_point = friend_min_card and package_known(friend_min_card,"getNumber") or 100
					if max_point>friend_min_point then
						source_state(self).sfofl_sixi_card = package_known(max_card,"getId")
						use.card = source_construct(self,"#sfofl_sixi:.:")
						package_call(use.to,"append",friend)
						return
					end
				end
			end
		end

		if package_known(dummy_use.to,"length")>1 then
			for index = #self.friends_noself,1,-1 do
				local friend = self.friends_noself[index]
				if package_known(self.player,"canPindian",friend) then
					if max_point>=7 then
						source_state(self).sfofl_sixi_card = package_known(max_card,"getId")
						use.card = source_construct(self,"#sfofl_sixi:.:")
						package_call(use.to,"append",friend)
						return
					end
				end
			end
		end
	end

	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards,true)

	if package_known(self,"getOverflow")>0 then
		for _,enemy in sgs.list(self.enemies)do
			if package_known(self,"doDisCard",enemy,"h") and package_known(self.player,"canPindian",enemy) then
				source_state(self).sfofl_sixi_card = package_known(cards[1],"getId")
				use.card = source_construct(self,"#sfofl_sixi:.:")
				package_call(use.to,"append",enemy)
				return
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.sfofl_sixi(minusecard,self,requestor)
	if package_known(requestor,"getHandcardNum")==1 then
		local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
		package_call(self,"sortByKeepValue",cards)
		return cards[1]
	end
	local maxcard = package_call(self,"getMaxCard")
	return package_known(self,"isFriend",requestor) and package_call(self,"getMinCard") or ( package_known(maxcard,"getNumber")<6 and  minusecard or maxcard )
end

sgs.ai_cardneed.sfofl_sixi = sgs.ai_cardneed.tianyi

sgs.ai_card_intention["sfofl_sixi"] = 0
sgs.dynamic_value.control_card["sfofl_sixi"] = true

sgs.ai_use_value["sfofl_sixi"] = 8.5

ai_skill_invoke.sfofl_lvedao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = package_known(data,"toDamage")
	if package_known(self,"isEnemy",damage.to) then
		return (true) or false
	end
	return (false) or false
end

local sfofl_bixiong_skill = {}
sfofl_bixiong_skill.name = "sfofl_bixiong"
table.insert(package_skills,sfofl_bixiong_skill)
sfofl_bixiong_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies<=0 then return end
	if package_known(self,"needBear") then return end
	return source_construct(self,"#sfofl_bixiong:.:")
end

ai_card_use["#sfofl_bixiong"] = function(self, card, use, request)
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	local to_use = {}
	for _, card in ipairs(cards) do
		table.insert(to_use, package_known(card,"getId"))
		if #to_use == 2 then break end
	end
	if #to_use < 2 then
		return
	end
	use.card = source_construct(self,"#sfofl_bixiong:".. table.concat(to_use, "+") ..":")
end

function sgs.ai_cardneed.sfofl_xingwei(to,card)
	return package_known(card,"isRed")
end
ai_skill_invoke.sfofl_xingwei = true

package_add("sfofl_qianmu").getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = package_call(self,"sortByKeepValue",cards)
	for _,pc in sgs.list(patterns_for(self))do do
		if package_known(self,"getCardsNum",pc)>0 then goto package_continue_16 end
		if package_known(self.player,"getStrategyMark","sfofl_qianmu_guhuo_remove_"..pc.."-Clear")<1 then
			local dc = clone(self,pc)
			if package_known(dc,"isKindOf","TrickCard") and package_known(self.player,"getStrategyMark","sfofl_qianmu_trick-Clear") > 0
			then goto package_continue_16 end
			if package_known(dc,"isKindOf","BasicCard") and package_known(self.player,"getStrategyMark","sfofl_qianmu_basic-Clear") > 0
			then goto package_continue_16 end
			for _,c in sgs.list(cards)do do
				if package_known(dc,"isKindOf","TrickCard") and package_known(c,"getSuit") ~= sgs.Card_Heart
				then goto package_continue_17 end
				if package_known(dc,"isKindOf","BasicCard") and package_known(c,"getSuit") ~= sgs.Card_Diamond
				then goto package_continue_17 end
				package_call(dc,"clearSubcards")
				package_call(dc,"setSkillName","sfofl_qianmu")
				package_call(dc,"addSubcard",package_known(c,"getEffectiveId"))
				local dummy_use = package_known(self,"aiUseCard",dc, dummy())
				if package_known(dc,"isAvailable",self.player) and dummy_use.card then
					source_state(self).sfofl_qianmu_to = dummy_use.to
					package_call(self,"setPriorityValue","sfofl_qianmu", sgs.ai_use_priority[package_known(dc,"getClassName")],"sfoflCard.source")
					return source_construct(self,"#sfofl_qianmu:"..package_known(c,"getEffectiveId")..":".. pc)
				end
			end ::package_continue_17:: end
		end
	end ::package_continue_16:: end
end

ai_card_use["#sfofl_qianmu"] = function(self, card, use, request)
	use.card = card
	use.to = source_state(self).sfofl_qianmu_to
end

sgs.ai_guhuo_card.sfofl_qianmu = function(self,toname,class_name)
	if package_known(self.player,"getStrategyMark","sfofl_qianmu_guhuo_remove_"..toname.."-Clear")>0
	or package_known(self,"getCardsNum",class_name)>0 then return end
	local cards = package_known(self.player,"getCards","he")
	cards = package_call(self,"sortByKeepValue",cards)
	local dc = clone(self,toname)
	if (not dc) then return end
	package_call(dc,"setSkillName","sfofl_qianmu")
	if package_known(dc,"isKindOf","TrickCard") and package_known(self.player,"getStrategyMark","sfofl_qianmu_trick-Clear") > 0 then end
	if package_known(dc,"isKindOf","BasicCard") and package_known(self.player,"getStrategyMark","sfofl_qianmu_basic-Clear") > 0 then end
	for _,c in sgs.list(cards)do do
		if package_known(dc,"isKindOf","TrickCard") and package_known(c,"getSuit") ~= sgs.Card_Heart
		then goto package_continue_18 end
		if package_known(dc,"isKindOf","BasicCard") and package_known(c,"getSuit") ~= sgs.Card_Diamond
		then goto package_continue_18 end
		package_call(dc,"addSubcard",package_known(c,"getEffectiveId"))
		return "#sfofl_qianmu:"..package_known(c,"getEffectiveId")..":"..toname
	end ::package_continue_18:: end
end
function sgs.ai_cardneed.sfofl_qianmu(to,card)
	return package_known(card,"isRed")
end

sgs.ai_skill_playerschosen.sfofl_silve = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if package_known(self,"doDisCard",target, "he", true) then
			package_call(selected,"append",target)
			if package_known(selected,"length") >= max then break end
		end
	end
    return selected
end

ai_skill_choice.sfofl_suibian = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local use = package_known(data,"toCardUse")
	local draw = getChoice(choices, "draw")
	local damage = getChoice(choices, "damage")
	local null = getChoice(choices, "nullified")
	if package_known(self,"isFriend",package_known(use.to,"first")) and null then
		local target = package_known(use.to,"first")
		if not use.from or package_known(use.from,"isDead") then return ai_choice_result((draw), options) end
		if self.role == "rebel" and package_call(self,"getRoleEstimate",use.from) == "rebel" and package_known(self.player,"getHp") == 1 and package_known(self,"getAllPeachNum") < 1 then
			return ai_choice_result((draw), options)
		end
		if package_known(self,"isEnemy",use.from) or (package_known(self,"isFriend",use.from) and self.role == "loyalist" and package_known(use.card,"isDamageCard") and not package_known(self,"needToLoseHp",target,use.from,use.card) and package_known(use.from,"isLord") and package_known(self.player,"getHp") == 1) then
			if package_known(use.card,"isKindOf","AOE") then
				local from = use.from
				if package_known(use.card,"isKindOf","SavageAssault") then
					local menghuo = package_call(self.room,"findPlayerBySkillName","huoshou")
					if menghuo then from = menghuo end
				end

				local friend_null = 0
				for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
					if package_known(self,"isFriend",p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
					if package_known(self,"isEnemy",p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
				end
				friend_null = friend_null + package_known(self,"getCardsNum","Nullification")
				local sj_num = package_known(self,"getCardsNum",package_known(use.card,"isKindOf","SavageAssault") and "Slash" or "Jink")

				if package_known(self,"hasTrickEffective",use.card, self.player, from) then
					if package_known(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, from) then
						if package_known(use.from,"hasSkill","drwushuang") and package_known(self.player,"getCardCount") == 1 and package_known(self,"hasLoseHandcardEffective") then
							return	ai_choice_result((null), options)
						end
						if sj_num == 0 and friend_null <= 0 then
							if package_known(self,"isEnemy",from) and package_known(self,"hasJueqingEffect",from, target, sgs.card_damage_nature[package_known(use.card,"getClassName")]) then
								return	ai_choice_result((null), options)
							end
							if package_known(self,"isFriend",from) and self.role == "loyalist" and package_known(from,"isLord") and package_known(self.player,"getHp") == 1 and not package_known(self,"hasJueqingEffect",from, target, sgs.card_damage_nature[package_known(use.card,"getClassName")]) then
								return	ai_choice_result((null), options)
							end
							if (not (package_known(self,"hasSkills",sgs.masochism_skill) or (package_known(self.player,"hasSkills","tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or package_known(self,"hasJueqingEffect",from, target, sgs.card_damage_nature[package_known(use.card,"getClassName")])) then
								return ai_choice_result((null), options)
							end
						end
					end
				end
			elseif package_known(self,"isEnemy",use.from) and package_known(self,"isFriend",target) then
				if package_known(use.card,"isKindOf","FireAttack") and package_known(use.from,"getHandcardNum") > 0 then
					if package_known(self,"hasTrickEffective",use.card, target, use.from) then
						if package_known(self,"damageIsEffective",target, sgs.DamageStruct_Fire, use.from) then
							if (package_known(self.player,"hasArmorEffect","vine") or package_known(self.player,"getStrategyMark","@gale") > 0) and package_known(use.from,"getHandcardNum") > 3
								and not (package_known(use.from,"hasSkill","hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
								return ai_choice_result((null), options)
							elseif package_known(target,"isChained") and not package_known(self,"isGoodChainTarget",target, use.from) then
								return ai_choice_result((null), options)
							end
						end
					end
				elseif (package_known(use.card,"isKindOf","Snatch") or package_known(use.card,"isKindOf","Dismantlement"))  then
					if package_known(self,"hasTrickEffective",use.card, target, use.from) then
						return ai_choice_result((null), options)
					end
				elseif package_known(use.card,"isKindOf","Duel") then
					if package_known(self,"getCardsNum","Slash") == 0 or package_known(self,"getCardsNum","Slash") < getCardsNum("Slash", use.from, self.player) then
						if package_known(self,"hasTrickEffective",use.card, target, use.from) then
							if package_known(self,"damageIsEffective",target, sgs.DamageStruct_Normal, use.from) then
								return ai_choice_result((null), options)
							end
						end
					end
				elseif package_known(use.card,"isKindOf","Slash") then
					if package_known(self,"ajustDamage",use.from,target,1,use.card)> 1 or package_known(self,"ajustDamage",use.from,target,1,use.card)>= package_known(target,"getHp") then
						if package_known(self.player,"getHp") > 1 then
							return ai_choice_result((null), options)
						end
					end
				end
			end
		end
	end
	if use.from and package_known(self,"isEnemy",use.from) then
		if package_known(self,"isWeak",use.from) then
			if package_known(self,"damageIsEffective",use.from, sgs.DamageStruct_Normal, self.player) then
				return ai_choice_result((damage), options)
			end
		end
	end
	return ai_choice_result((draw), options)
end

sgs.ai_skill_playerchosen.sfofl_suibian = function(self,targets)
	local card = disclosed_card(self,package_known(self.player,"getStrategyMark","sfofl_suibian"))
	local c,to = package_call(self,"getCardNeedPlayer",{card},false)
  	if c and to then
		return to
	end
	for _,p in sgs.qlist(targets) do
		if package_known(self,"isFriend",p) and package_known(self,"canDraw",p, self.player) then
			return p
		end
	end
	return package_known(targets,"first")
end

sgs.ai_playerchosen_intention.sfofl_suibian = -40

sgs.ai_card_priority.sfofl_suibian = function(self,card)
	for _,id in sgs.qlist(package_known(self.player,"getPile","sfofl_silve_lve")) do
		if package_known(card,"getSuit") == disclosed_card(self,id):getSuit() then return 5 end
	end
end



local sfofl_lianji_skill = {}
sfofl_lianji_skill.name = "sfofl_lianji"
table.insert(package_skills, sfofl_lianji_skill)
sfofl_lianji_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.friends_noself == 0 then return end
	if not package_known(self.player,"hasUsed","#sfofl_lianji") then
		return source_construct(self,"#sfofl_lianji:.:")
	end
end

ai_card_use["#sfofl_lianji"] = function(self, card, use, request)
	package_call(self,"sort",self.friends_noself, "handcard")
	for _, friend in ipairs(self.friends_noself) do
		if package_known(self,"canDraw",friend, self.player) then
			if package_known(friend,"hasSkills",sgs.cardneed_skill) then
				use.card = source_construct(self,"#sfofl_lianji:.:")
				if use.to then package_call(use.to,"append",friend) end
				return
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if package_known(self,"canDraw",friend, self.player) then
			use.card = source_construct(self,"#sfofl_lianji:.:")
			if use.to then package_call(use.to,"append",friend) end
			return
		end
	end

end

sgs.ai_use_priority["sfofl_lianji"] = 3
sgs.ai_use_value["sfofl_lianji"] = 2.45
sgs.ai_card_intention.sfofl_lianji = -80

sgs.ai_skill_askforag.sfofl_lianji = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = disclosed_card(self,id)
		local dummy_use = package_known(self,"aiUseCard",card, dummy())
		if package_known(card,"isAvailable",self.player) and dummy_use.card then
			return id
		end
	end
end

ai_skill_use["@@sfofl_lianji!"]=function(self,prompt,request)
	local pattern -- source unused ambient read omitted; next statement overwrites it
	pattern = package_known(self.player,"getStrategyMark","sfofl_lianji_id-PlayClear") - 1
	pattern = printed_card(self,pattern)
	pattern = clone_native(self,package_known(pattern,"objectName"))
	package_call(pattern,"deleteLater")
	package_call(pattern,"setSkillName","sfofl_lianji")
	local dummy_use = package_known(self,"aiUseCard",pattern, dummy())
	if dummy_use.to and package_known(dummy_use.to,"length") > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, package_known(to,"objectName"))
        end
        return selected(self,pattern,tos)
    end
	if package_known(self.room,"getCardTargets",self.player, pattern):length() > 0 and package_known(pattern,"isSingleTargetCard") then
		return package_known(pattern,"toString").."->"..package_known(self.room,"getCardTargets",self.player, pattern):first():objectName()
	end
    return package_known(pattern,"toString")
end

package_add("sfofl_jingongz").getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","sfofl_jingongz-PlayClear") > 0	then return end
	local cards = package_known(self.player,"getCards","he")
	cards = package_call(self,"sortByKeepValue",cards)
	for _,pc in sgs.list(patterns_for(self))do do
		if package_known(self,"getCardsNum",pc)>0 then goto package_continue_19 end
		local dc = clone(self,pc)
		if package_known(dc,"isKindOf","TrickCard") then
			for _,c in sgs.list(cards)do
				if package_known(c,"isKindOf","Slash") or package_known(c,"isKindOf","EquipCard") then
					package_call(dc,"clearSubcards")
					package_call(dc,"setSkillName","sfofl_jingongz")
					package_call(dc,"addSubcard",package_known(c,"getEffectiveId"))
					local dummy_use = package_known(self,"aiUseCard",dc, dummy())
					if package_known(dc,"isAvailable",self.player) and dummy_use.card then
						source_state(self).sfofl_jingongz_to = dummy_use.to
						package_call(self,"setPriorityValue","sfofl_jingongz", sgs.ai_use_priority[package_known(dc,"getClassName")],"sfoflCard.source")
						return source_construct(self,"#sfofl_jingongz:"..package_known(c,"getEffectiveId")..":".. pc)
					end
				end
			end
		end
	end ::package_continue_19:: end
end

ai_card_use["#sfofl_jingongz"] = function(self, card, use, request)
	use.card = card
	use.to = source_state(self).sfofl_jingongz_to
end


local sfofl_liyu_skill = {}
sfofl_liyu_skill.name = "sfofl_liyu"
table.insert(package_skills,sfofl_liyu_skill)
sfofl_liyu_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_liyu:.:")
end

ai_card_use["#sfofl_liyu"] = function(self, card, use, request)

	package_call(self,"sort",self.enemies,"handcard")
	for _,p in ipairs(self.enemies)do
		if package_known(self,"doDisCard",p, "he", true) then
			use.card = source_construct(self,"#sfofl_liyu:.:")
			package_call(use.to,"append",p)
			return
		end
	end
end

sgs.ai_use_priority.sfofl_liyu = sgs.ai_use_priority.Slash+0.1
sgs.ai_use_value.sfofl_liyu = 8.5

sgs.ai_ajustdamage_from.sfofl_liyu = function(self, from, to, card, nature)
    if card and (package_known(card,"isKindOf","Slash") or package_known(card,"isKindOf","Duel")) and package_known(from,"getStrategyMark","sfofl_liyu-Clear") > 0
    then
        return 1
    end
end

ai_skill_invoke.sfofl_sixiong =  function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	for _,c in sgs.qlist(package_known(self.player,"getHandcards"))do
		if package_known(c,"isRed") then
			local good = 0
			for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
				if package_known(self.player,"inMyAttackRange",p) then
					if package_known(self,"damageIsEffective",p, nil, self.player) then
						if package_known(self,"isFriend",p) then
							good = good - 1
						else
							good = good + 1
							if package_known(self,"isWeak",p) then
								good = good + 1
							end
						end
					end
				end
			end
			if good > 0 then
				return (true) or false
			end
			break
		end
	end

	local max = 0
	for _,p in sgs.qlist(package_known(self.room,"getAllPlayers")) do
		if not package_known(p,"getPile","sfofl_weiju_ju"):isEmpty() then
			max = max + package_known(p,"getPile","sfofl_weiju_ju"):length()
		end
	end
	local black = 0
	for _,c in sgs.qlist(package_known(self.player,"getHandcards"))do
		if package_known(c,"isBlack") then black = black + 1 end
	end
	if max > black then
		return (true) or false
	end
	return (false) or false
end

ai_skill_choice.sfofl_sixiong = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	if table.contains(items, "red") then
		local good = 0
		for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
			if package_known(self.player,"inMyAttackRange",p) then
				if package_known(self,"damageIsEffective",p, nil, self.player) then
					if package_known(self,"isFriend",p) then
						good = good - 1
						if package_known(self,"isWeak",p) then
							good = good - 1
						end
					else
						good = good + 1
						if package_known(self,"isWeak",p) then
							good = good + 1
						end
					end
				end
			end
		end
		if good > 0 then
			if table.contains(items, "all") then
				local max = 0
				for _,p in sgs.qlist(package_known(self.room,"getAllPlayers")) do
					if not package_known(p,"getPile","sfofl_weiju_ju"):isEmpty() then
						max = max + package_known(p,"getPile","sfofl_weiju_ju"):length()
					end
				end
				local black = 0
				for _,c in sgs.qlist(package_known(self.player,"getHandcards"))do
					if package_known(c,"isBlack") then black = black + 1 end
				end
				if max > black then
					return ai_choice_result(("all"), options)
				end
			end
			return ai_choice_result(("red"), options)
		end
	end
	if table.contains(items, "black") then
		local max = 0
		for _,p in sgs.qlist(package_known(self.room,"getAllPlayers")) do
			if not package_known(p,"getPile","sfofl_weiju_ju"):isEmpty() then
				max = max + package_known(p,"getPile","sfofl_weiju_ju"):length()
			end
		end
		local black = 0
		for _,c in sgs.qlist(package_known(self.player,"getHandcards"))do
			if package_known(c,"isBlack") then black = black + 1 end
		end
		if max > black then
			return ai_choice_result(("black"), options)
		end
	end
	return ai_choice_result((items[math.random(1, #items)]), options)
end


ai_skill_use["@@sfofl_sixiong!"]=function(self,prompt,request)
	local x = package_known(self.player,"getStrategyMark","sfofl_sixiong")
	local use_cards = {}
	for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(self,"isEnemy",p) then
			for _,id in sgs.qlist(package_known(p,"getPile","sfofl_weiju_ju"))do
				table.insert(use_cards, id)
				if #use_cards >= x then
					break
				end
			end
		end
	end
	for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
		for _,id in sgs.qlist(package_known(p,"getPile","sfofl_weiju_ju"))do
			if not table.contains(use_cards, id) then
				table.insert(use_cards, id)
				if #use_cards >= x then
					break
				end
			end
		end
	end
	if #use_cards > 0 then
		return "#sfofl_sixiong:".. table.concat(use_cards, "+")..":"
	end
end


sgs.ai_skill_playerchosen.sfofl_sangluan = function(self,targets)
	if package_known(self.player,"hasSkill","sfofl_longmu") then
		for _,p in sgs.qlist(targets) do
			if package_known(self,"isEnemy",p) and package_known(p,"getStrategyMark","sfofl_longmu"..package_known(self.player,"objectName")) == 0 then
				return p
			end
		end
	end
	for _,p in sgs.qlist(targets) do
		if package_known(self,"isEnemy",p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.sfofl_sangluan = 20
sgs.ai_skill_playerchosen.sfofl_sangluan_slash = function(self,targets)
	for _,p in sgs.qlist(targets) do
		if package_known(self,"isEnemy",p) then
			return p
		end
	end
	for _,p in sgs.qlist(targets) do
		if package_known(self,"isFriend",p) and package_known(self,"needToLoseHp",p,self.player,nil) then
			return p
		end
	end
	return package_known(targets,"first")
end

sgs.ai_playerchosen_intention.sfofl_sangluan_slash = 40

package_add("sfofl_chuce").getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = package_call(self,"sortByKeepValue",cards)
	for _,pc in sgs.list(RandomList(patterns_for(self)))do
		local dc = clone(self,pc)
		if package_known(dc,"isKindOf","TrickCard") or package_known(dc,"isKindOf","BasicCard") then
			for _,c in sgs.list(cards)do
				if package_known(c,"isKindOf","TrickCard") then
					package_call(dc,"setSkillName","sfofl_chuce")
					package_call(dc,"addSubcard",package_known(c,"getEffectiveId"))
					local dummy_use = package_known(self,"aiUseCard",dc, dummy())
					if package_known(dc,"isAvailable",self.player) and dummy_use.card then
						source_state(self).sfofl_chuce_to = dummy_use.to
						package_call(self,"setPriorityValue","sfofl_chuce", sgs.ai_use_priority[package_known(dc,"getClassName")],"sfoflCard.source")
						return source_construct(self,"#sfofl_chuce:"..package_known(c,"getEffectiveId")..":".. pc)
					end
					package_call(dc,"clearSubcards")
				end
			end
		end
	end
end

ai_card_use["#sfofl_chuce"] = function(self, card, use, request)
	use.card = card
	use.to = source_state(self).sfofl_chuce_to
end

sgs.ai_guhuo_card.sfofl_chuce = function(self,toname,class_name)
	if owner_reason(self) ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	local cards = package_known(self.player,"getCards","he")
	cards = package_call(self,"sortByKeepValue",cards)
	local dc = clone(self,toname)
	if (not dc) then return end
	package_call(dc,"setSkillName","sfofl_chuce")
	for _,c in sgs.list(cards)do do
		if not package_known(c,"isKindOf","TrickCard") then goto package_continue_20 end
		package_call(dc,"addSubcard",package_known(c,"getEffectiveId"))
		return "#sfofl_chuce:"..package_known(c,"getEffectiveId")..":"..toname
	end ::package_continue_20:: end
end
ai_skill_use["@@sfofl_chuce"]=function(self,prompt,request)
	local pattern -- source unused ambient read omitted; next statement overwrites it
	pattern = package_known(self.player,"getStrategyMark","sfofl_chuce_id-PlayClear") - 1
	pattern = disclosed_card(self,pattern)
	pattern = clone_native(self,package_known(pattern,"objectName"))
	package_call(pattern,"deleteLater")
	package_call(pattern,"setSkillName","sfofl_chuce")
	local dummy_use = package_known(self,"aiUseCard",pattern, dummy())
	if dummy_use.to and package_known(dummy_use.to,"length") > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, package_known(to,"objectName"))
        end
        return selected(self,pattern,tos)
    end
    return "."
end

ai_skill_invoke.sfofl_chuce = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = package_known(data,"toCardUse")
    if use.from and package_known(self,"isEnemy",use.from) then return (true) or false end
	return (false) or false
end
ai_skill_invoke.sfofl_chuceuse = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local id = package_known(self.player,"getStrategyMark","sfofl_chuce_id-PlayClear") - 1
	local card = disclosed_card(self,id)
	card = clone_native(self,package_known(card,"objectName"))
	package_call(card,"setSkillName","sfofl_chuce")
	package_call(card,"deleteLater")
    local dummy_use = package_known(self,"aiUseCard",card, dummy())
	if package_known(card,"isAvailable",self.player) and dummy_use.card then
		return (true) or false
	end
	return (false) or false
end


sgs.ai_target_revises.sfofl_longmu = function(to,card)
	if package_known(card,"isKindOf","TrickCard")
	then return true end
end

sgs.ai_event_callback[sgs.BeforeGameOverJudge].sfofl_longmu = longmu_event


sgs.ai_skill_playerchosen._sfofl_lianshikui = function(self,targets)
	for _,p in sgs.qlist(targets) do
		if package_known(self,"isFriend",p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention._sfofl_lianshikui = -40

ai_skill_choice.sfofl_sixiong = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local current = package_call(self.room,"getCurrent")
	if current and not package_known(current,"hasSkill","sfofl_longmu")  then
		return ai_choice_result(("hp"), options)
	end
	return ai_choice_result(("gainHujia"), options)
end

package_add("sfofl_dingxi").getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","&sfofl_dingxi_can") < 2 then return end
	for _,pc in sgs.list(RandomList(patterns_for(self)))do do
		if package_known(self,"getCardsNum",pc)>0 then goto package_continue_21 end
		local dc = clone(self,pc)
		if package_known(dc,"isKindOf","TrickCard") or package_known(dc,"isKindOf","BasicCard") then
			local card_ids = package_known(self.room,"getNCards",1, false)
			local card = disclosed_card(self,package_known(card_ids,"first"))
			package_known(self.room,"returnToTopDrawPile",card_ids)
			if package_known(card,"getTypeId") == package_known(dc,"getTypeId") or math.random() < 0.3 then
				package_call(dc,"setSkillName","sfofl_dingxi")
				local dummy_use = package_known(self,"aiUseCard",dc, dummy())
				if package_known(dc,"isAvailable",self.player) and dummy_use.card then
					source_state(self).sfofl_dingxi_to = dummy_use.to
					package_call(self,"setPriorityValue","sfofl_dingxi", sgs.ai_use_priority[package_known(dc,"getClassName")],"sfoflCard.source")
					return source_construct(self,"#sfofl_dingxi:.:".. pc)
				end
			end
		end
	end ::package_continue_21:: end
end

ai_card_use["#sfofl_dingxi"] = function(self, card, use, request)
	use.card = card
	use.to = source_state(self).sfofl_dingxi_to
end

sgs.ai_guhuo_card.sfofl_dingxi = function(self,toname,class_name)
	if package_known(self.player,"getStrategyMark","&sfofl_dingxi_can") < 2 then return end
	if package_known(self,"getCardsNum",class_name)>0 then return end
	if owner_reason(self) ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	local dc = clone(self,toname)
	if (not dc) then return end
	local card_ids = package_known(self.room,"getNCards",1, false)
	local card = disclosed_card(self,package_known(card_ids,"first"))
	package_known(self.room,"returnToTopDrawPile",card_ids)
	if package_known(card,"getTypeId") ~= package_known(dc,"getTypeId") and math.random() < 0.9 then return end
	package_call(dc,"setSkillName","sfofl_dingxi")
	return "#sfofl_dingxi:.:"..toname
end


local sfofl_dingluan_skill = {}
sfofl_dingluan_skill.name = "sfofl_dingluan"
table.insert(package_skills,sfofl_dingluan_skill)
sfofl_dingluan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self,"isWeak") or package_known(self,"needBear") then return end
	if #self.enemies == 0 then return end
	return source_construct(self,"#sfofl_dingluan:.:")
end

ai_card_use["#sfofl_dingluan"] = function(self, card, use, request)
	local target
	for _,enemy in ipairs(self.enemies)do
		if package_known(self,"isGoodTarget",enemy,self.enemies, nil) then
			target = enemy
			break
		end
	end
	if target then
		use.card = source_construct(self,"#sfofl_dingluan:.:")
		package_call(use.to,"append",target)
	end
end

sgs.ai_use_value.sfofl_dingluan = 9
sgs.ai_use_priority.sfofl_dingluan = 5
sgs.ai_card_intention.sfofl_dingluan = 80
sgs.dynamic_value.benefit.sfofl_dingluan = true


ai_skill_choice.sfofl_dingluan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	local target = package_call(data,"toPlayer")
	if math.random() < 0.5 or #self.friends_noself < 3 then return ai_choice_result(("skill"), options) end
	local BearingDownBorder = clone_native(self,"_sfofl_bearing_down_border", sgs.Card_NoSuit, 0)
	package_call(BearingDownBorder,"setSkillName","sfofl_dingluan")
	package_call(BearingDownBorder,"deleteLater")
	local dummy_use = package_known(self,"aiUseCard",BearingDownBorder,dummy(true, 0, package_known(self.room,"getOtherPlayers",target)))
	if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) then
		return ai_choice_result(("BearingDownBorder"), options)
	end
	return ai_choice_result(("skill"), options)
end


sgs.ai_skill_playerchosen.sfofl_qianjiang = function(self,targets)
	local death = source_fact(self,"sfofl_qianjiang","toDeath")
	for _,p in sgs.qlist(targets) do
		if package_known(self,"isFriend",p) then
			if package_known(self,"playerGetRound",p) > package_known(self,"playerGetRound",death.who) and package_known(self,"playerGetRound",death.who) > 0 then
				return p
			end
		end
	end
	for _,p in sgs.qlist(targets) do
		if package_known(self,"isEnemy",p) then
			if package_known(self,"playerGetRound",p) <= package_known(self,"playerGetRound",death.who) or package_known(self,"playerGetRound",death.who) == 0 then
				return p
			end
		end
	end
	return nil
end

ai_card_use.BearingDownBorder=function(self,card,use, request)
    local recommend = self:targetRecommendScorer(card)
	if #self.friends_noself == 0 then return end
	local extraTarget = correct_target(self,"ExtraTarget",card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	local slash = clone_native(self,"slash", sgs.Card_SuitToBeDecided, -1)
	package_call(slash,"setSkillName","BearingDownBorder")
	package_call(slash,"deleteLater")
	local dummy_use = package_known(self,"withOwnerRange","InfinityAttackRange","BearingDownBorder",function() return package_known(self,"aiUseCard",slash,dummy(true, 99)) end)
	if dummy_use.card and dummy_use.to then
		if not package_known(dummy_use.to,"isEmpty") then
			for _, p in sgs.qlist(self:orderTargetsByRecommend(dummy_use.to, recommend)) do
				if package_known(self,"hasTrickEffective",card,p,self.player) then
					use.card = card
					package_call(use.to,"append",p)
					if package_known(use.to,"length")>extraTarget then break end
				end
			end
		end
	end
end

sgs.ai_skill_cardask["@sfofl_bearing_down_border"] = function(self, data, pattern, target, target2)
	local target = package_call(data,"toPlayer")
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)
    for _, c in ipairs(cards) do

		local slash = clone_native(self,"slash", sgs.Card_SuitToBeDecided, -1)
		package_call(slash,"addSubcard",c)
		package_call(slash,"setSkillName","BearingDownBorder")
		package_call(slash,"deleteLater")
		local dummy_use = package_known(self,"withOwnerRange","InfinityAttackRange","@sfofl_bearing_down_border",function() return package_known(self,"aiUseCard",slash,dummy(true, 0, package_known(self.room,"getOtherPlayers",target))) end)
		if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) then
			return package_known(c,"getEffectiveId")
		end
	end
	return "."
end

sgs.ai_card_intention.BearingDownBorder = function(self,card,from,tos)
	sgs.updateIntentions(from,tos,80)
end

ai_skill_invoke.sfofl_jubing = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = package_known(data,"toDamage")
    if damage.to and package_known(self,"isEnemy",damage.to) then
		local slash = clone_native(self,"slash", sgs.Card_SuitToBeDecided, -1)
		package_call(slash,"setSkillName","_sfofl_jubing")
		package_call(slash,"deleteLater")
		local dummy_use = package_known(self,"withOwnerRange","InfinityAttackRange","sfofl_jubing",function() return package_known(self,"aiUseCard",slash,dummy(true, 0, package_known(self.room,"getOtherPlayers",damage.to))) end)
		if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",damage.to) then
			return (true) or false
		end
	end
	return (false) or false
end


local sfofl_chiyuan_skill = {}
sfofl_chiyuan_skill.name = "sfofl_chiyuan"
table.insert(package_skills, sfofl_chiyuan_skill)
sfofl_chiyuan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_chiyuan:.:")
end

ai_card_use["#sfofl_chiyuan"] = function(self, card, use, request)
	local targets = sgs.SPlayerList()
	for _,p in ipairs(self.friends_noself) do
		if package_known(targets,"length") >= package_known(self.player,"getStrategyMark","&sfofl_zhuying") then
			break
		end
		if package_known(p,"getStrategyMark","&sfofl_zhuying+to+#"..package_known(self.player,"objectName")) == 0 then package_call(targets,"append",p) end
	end

	if package_known(targets,"length")> 0 then
		use.card = source_construct(self,"#sfofl_chiyuan::")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_priority["sfofl_chiyuan"] = 4.2
sgs.ai_card_intention["sfofl_chiyuan"] = -100



sgs.ai_skill_discard.sfofl_chiyuan = function(self)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	local damage = source_fact(self,"sfofl_chiyuan","toDamage")
	if damage.to and package_known(self,"isFriend",damage.to) then
		if package_known(self,"needToLoseHp",damage.to,damage.from,damage.card) then
			if damage.from and package_known(self,"isFriend",damage.from) then
				return {}
			end
			if damage.from and package_known(self,"isEnemy",damage.from) and not package_known(self,"canDamage",damage.from,self.player,nil) then
				return {}
			end
		end
	end
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, package_known(card,"getEffectiveId"))
        break
	end
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end

ai_skill_choice.sfofl_chiyuan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	local damage = package_known(data,"toDamage")
	local choice = getChoice(choices, "damage")
	if damage.to then
		if package_known(self,"isFriend",damage.to) then
			if package_known(self,"isWeak",damage.to) then
				if package_known(self,"damageStruct",damage) then
					return ai_choice_result(("prevented"), options)
				end
			end
		end
	end
	if choice then
		if damage.from then
			if package_known(self,"isEnemy",damage.from) then
				if package_known(self,"isWeak",damage.from) then
					return ai_choice_result((choice), options)
				end
				if package_known(self,"canDamage",damage.from,self.player,nil) then
					return ai_choice_result((choice), options)
				end
			end
		end
	end
	return ai_choice_result(("prevented"), options)
end



ai_skill_use["@@sfofl_qifeng"]=function(self,prompt,request)
	local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
	package_call(slash,"deleteLater")
	package_call(slash,"setSkillName","sfofl_qifeng")
	local dummy_use = package_known(self,"withOwnerRange","InfinityAttackRange","@@sfofl_qifeng",function() return package_known(self,"aiUseCard",slash, dummy(true, 0, package_known(self.room,"getOtherPlayers",package_call(self.room,"getCurrent")))) end)
	if dummy_use.to and package_known(dummy_use.to,"length") > 0 and package_known(dummy_use.to,"contains",package_call(self.room,"getCurrent")) then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, package_known(to,"objectName"))
        end
        return selected(self,slash,tos)
    end
    return "."
end

sgs.ai_ajustdamage_from.sfofl_qifeng = function(self, from, to, card, nature)
    if card and (package_known(card,"isKindOf","Slash") and table.contains(package_known(card,"getSkillNames"), "sfofl_qifeng"))   then
        return package_known(from,"getStrategyMark","sfofl_qifeng-Clear") - 1
    end
end



package_add("sfofl_dutan").getTurnUseCard = function(self,inclusive,request)
	local ids = {}
   	local fs = clone(self,"duel")
	package_call(fs,"setSkillName","sfofl_dutan")
	local dummy_use = package_known(self,"aiUseCard",fs, dummy(true, 99))
	if package_known(fs,"isAvailable",self.player)
	and dummy_use.card
	and dummy_use.to
  	then
		source_state(self).sfofl_dutan_to = dummy_use.to
		return source_construct(self,"#sfofl_dutan:.:")
	end
end

ai_card_use["#sfofl_dutan"] = function(self, card, use, request)
	use.card = card
	use.to = source_state(self).sfofl_dutan_to
end

sgs.ai_use_value.sfofl_dutan = 9.4
sgs.ai_use_priority.sfofl_dutan = sgs.ai_use_priority.Duel


ai_skill_use["@@sfofl_zhongtao"]=function(self,prompt,request)
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)
    for _, c in ipairs(cards) do
		local slash = clone_native(self,"slash", sgs.Card_SuitToBeDecided, -1)
		package_call(slash,"addSubcard",c)
		package_call(slash,"setSkillName","sfofl_zhongtao")
		package_call(slash,"deleteLater")
		local dummy_use = package_known(self,"aiUseCard",slash,dummy())
		if dummy_use.card and dummy_use and dummy_use.to then
			local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, package_known(to,"objectName"))
        end
        return selected(self,slash,tos)
		end
	end
    return "."
end


sgs.ai_skill_discard.sfofl_qiaobian = function(self, discard_num, min_num, optional, include_equip)
	local current = package_call(self.room,"getCurrent")
	if current and package_known(self,"isFriend",current) then return {} end
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)

	table.insert(to_discard, package_known(cards[1],"getEffectiveId"))
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end



local sfofl_zhanyi_skill = {}
sfofl_zhanyi_skill.name = "sfofl_zhanyi"
table.insert(package_skills,sfofl_zhanyi_skill)
sfofl_zhanyi_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self,"isWeak") or package_known(self,"needBear") then return end
	return source_construct(self,"#sfofl_zhanyi:.:")
end

ai_card_use["#sfofl_zhanyi"] = function(self, card, use, request)
	local to_discard
	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards,true)
	local TrickCards = {}
	for _,card in ipairs(cards)do
		if package_known(card,"isKindOf","Disaster") or package_known(card,"isKindOf","GodSalvation") or package_known(card,"isKindOf","AmazingGrace") or package_known(self,"getCardsNum","TrickCard")>1 then
			table.insert(TrickCards,card)
		end
	end
	if #TrickCards>0 and (package_known(self.player,"getHp")>2 or package_known(self,"getCardsNum","Peach")>0 ) and package_known(self.player,"getHp")>1 then
		to_discard = TrickCards[1]
	end

	local BasicCards = {}
	for _,card in ipairs(cards)do
		if package_known(card,"isKindOf","BasicCard") then
			table.insert(BasicCards,card)
		end
	end
	if (#BasicCards>3)
	then to_discard = BasicCards[1] end
	if to_discard then
		use.card = source_construct(self,"#sfofl_zhanyi:"..package_known(to_discard,"getEffectiveId")..":")
		return
	end
end

sgs.ai_use_priority["sfofl_zhanyi"] = 10


local sfofl_jianshu_skill = {}
sfofl_jianshu_skill.name = "sfofl_jianshu"
table.insert(package_skills,sfofl_jianshu_skill)
sfofl_jianshu_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	package_call(self,"sort",self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if package_known(a,"canPindian",b) then
				local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
				package_call(self,"sortByKeepValue",cards)
				for _,c in sgs.list(cards)do
					return source_construct(self,"#sfofl_jianshu:"..package_known(c,"getEffectiveId")..":")
				end
			end
		end
	end
end

ai_card_use["#sfofl_jianshu"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if package_known(a,"canPindian",b)	then
				use.card = card
				package_call(use.to,"append",a)
				source_state(self).sfofl_jianshu = b
				return
			end
		end
	end
end

sgs.ai_use_priority["sfofl_jianshu"] = 0
sgs.ai_use_value["sfofl_jianshu"] = 2.5
sgs.ai_card_intention["sfofl_jianshu"] = 80

sgs.ai_skill_playerchosen.sfofl_jianshu = function(self, targets)
	if source_state(self).sfofl_jianshu then return source_state(self).sfofl_jianshu end
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if package_known(self,"doDisCard",target, "h") and not package_known(self,"isFriend",target) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if package_known(self,"doDisCard",target, "h") then
            return target
        end
    end
    return targets[1]
end

sgs.ai_skill_discard.sfofl_zhenlue = function(self, discard_num, min_num, optional, include_equip)
	local use = source_fact(self,"sfofl_zhenlue","toCardUse")
	if use.from and package_known(self,"isFriend",use.from) then return {} end
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)

	table.insert(to_discard, package_known(cards[1],"getEffectiveId"))
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end


sgs.ai_skill_playerchosen.sfofl_yuma = function(self, targets)
    targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "handcard")
    for _, target in ipairs(targets) do
        if package_known(self,"doDisCard",target, "h", true) and not package_known(self,"loseEquipEffect",target) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if package_known(self,"doDisCard",target, "h", true) then
            return target
        end
    end
    return nil
end
sgs.ai_playerchosen_intention.sfofl_yuma = 80


sgs.ai_skill_discard.sfofl_qiangshu = function(self, discard_num, min_num, optional, include_equip)
	local damage = source_fact(self,"sfofl_qiangshu","toDamage")
	if damage.to and package_known(self,"isFriend",damage.to) then return {} end
	if package_known(self,"cantDamageMore",damage.from,damage.to)then return {} end
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, package_known(card,"getEffectiveId"))
		if #to_discard == min_num then
        	break
		end
	end
	if #to_discard == min_num then
		return to_discard
	end

	return {}
end


ai_skill_invoke.sfofl_bozhan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local current = package_call(self.room,"getCurrent")
	local duel = clone_native(self,"duel", sgs.Card_NoSuit, 0)
	package_call(duel,"deleteLater")
	package_call(duel,"setSkillName","sfofl_bozhan")
	local dummy_use = package_known(self,"aiUseCard",duel, dummy(true, 99, package_known(self.room,"getOtherPlayers",current)))
	if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",current) then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_canliegong_skill.sfofl_tieti = function(self, from, to)
	return package_known(from,"distanceTo",to) <= 1
end

ai_skill_invoke.sfofl_guwei = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target
    for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
        if package_known(p,"getStrategyFlag","sfofl_guwei_target") then
            target = p
            break
        end
    end
	local use = package_known(data,"toCardUse")
	if target and package_known(self,"isFriend",target) and package_known(self,"isWeak",target) and package_known(self,"slashIsEffective",use.card,target,use.from) then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.sfofl_guwei = function(self, player, promptlist)
   	local target
	for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",player))do
		if package_known(p,"getStrategyFlag","sfofl_guwei_target") then target = p break end
	end
	if target then
		if promptlist[#promptlist]=="yes" then
        	sgs.updateIntention(player, target, -80)
		end
    end
end


sgs.ai_card_priority.sfofl_zhitong = function(self,card,v)
	if package_known(self.player,"getChangeSkillState","sfofl_zhitong") <= 1 and package_known(card,"targetFixed")	then return 10 end
	if package_known(self.player,"getChangeSkillState","sfofl_zhitong") > 1 and not package_known(card,"targetFixed")	then return 10 end
end

sgs.ai_used_revises.sfofl_zhitong = function(self,use)
	if package_known(use.card,"canRecast") then return end
	if not package_known(use.card,"isKindOf","SkillCard")
	and package_known(self.player,"getChangeSkillState","sfofl_zhitong") <= 1
	and not package_known(self.player,"getStrategyFlag","AI_sfofl_zhitong_Fail")
	and not use.isDummy then
		package_call(self,"setStrategyPlayerFlag",self.player,"AI_sfofl_zhitong_Fail",true)
		local use_card
		for _, card in sgs.qlist(package_known(self.player,"getHandcards")) do
			if package_known(card,"isKindOf","EquipCard") then
				use_card = card
			end
		end
		if use_card then
			use.card = use_card
			use.to = sgs.SPlayerList()
			return false
		end
	end
	if package_known(self.player,"getChangeSkillState","sfofl_zhitong")<=1 then
	else
		local tp = self.player
		if not package_known(use.card,"isKindOf","SkillCard") and package_known(use.to,"length")>0 then tp = package_known(use.to,"at",0) end
		if tp==self.player then
			if package_known(self,"getCardsNum","Peach,Analeptic")<1 then use.card = nil end
		elseif package_known(self,"isFriend",tp)
		then use.card = nil end
	end
end


ai_skill_choice.sfofl_dengtian = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	items = RandomList(items)
	for _,item in sgs.list(items)do
		if package_known(self.player,"getStrategyMark",item) < 2 then
			return ai_choice_result((item), options)
		end
	end
	return ai_choice_result((items[math.random(1, #items)]), options)
end


sgs.ai_ajustdamage_from.sfofl_dengtian = function(self, from, to, card, nature)
    if package_known(from,"getStrategyMark","sfofl_dengtian-Clear") == 0
    then
        return package_known(from,"getStrategyMark","sfofl_dengtian_damage")
    end
end

sgs.bad_skills = sgs.bad_skills .. "|sfofl_mingshu"


ai_skill_invoke.sfofl_juedou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
	package_call(slash,"deleteLater")
	package_call(slash,"setSkillName","sfofl_juedou")
	local dummy_use = package_known(self,"withOwnerRange","slashNoDistanceLimit","sfofl_juedou",function() return package_known(self,"aiUseCard",slash, dummy(true, 0, package_known(self.room,"getOtherPlayers",target))) end)
	if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) then
		return (true) or false
	end
	return (false) or false
end

ai_skill_invoke.sfofl_wanwang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local current = package_call(self.room,"getCurrent")
	return (package_known(self,"isEnemy",current)) or false
end

sgs.ai_choicemade_filter.skillInvoke.sfofl_wanwang = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = package_call(self.room,"getCurrent")
		if target then sgs.updateIntention(player,target,50) end
	end
end

sgs.ai_skill_cardask["@sfofl_nagong"] = function(self,data, pattern, target)
	if package_known(self,"isEnemy",target) and package_known(target,"hasSkill","sfofl_wanwang") and package_known(target,"getStrategyMark","sfofl_wanwang_lun") == 0 then
		local useds = package_known(self,"getTurnUse")
		if #useds<1 then return "." end
		return math.random() < 0.7
	elseif package_known(self,"isFriend",target) then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)
		local targets = sgs.SPlayerList()
		package_call(targets,"append",target)
		local c,to = package_call(self,"getCardNeedPlayer",cards, false, targets)
		if c and to then
			return package_known(c,"getEffectiveId")
		end
	end
	return "."
end

ai_skill_use["@@sfofl_zongma"]=function(self,prompt,request)
	local use_card
	local target
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)

    for _, c in ipairs(cards) do
			use_card = c
			break
	end
	if use_card then
		for _, friend in ipairs(self.friends_noself) do
			if package_known(friend,"hasEquipArea",3) and package_call(friend,"getEquip",3)==nil then
				target = friend
				source_state(self).sfofl_zongma = "OffensiveHorse"
				break
			end
		end
		if not target then
			if package_known(self.player,"hasEquipArea",3) and package_call(self.player,"getEquip",3)==nil then
				target = self.player
				source_state(self).sfofl_zongma = "OffensiveHorse"
			end
		end
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if package_known(enemy,"hasEquipArea",2) and package_call(enemy,"getEquip",2)==nil and not package_known(self,"loseEquipEffect",enemy) then
					target = enemy
					source_state(self).sfofl_zongma = "DefensiveHorse"
					break
				end
			end
		end


	end
	if use_card and target then
		return "#sfofl_zongma:".. package_known(use_card,"getEffectiveId")..":->"..package_known(target,"objectName")
	end
	return "."
end

ai_skill_choice.sfofl_zongma = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	if source_state(self).sfofl_zongma then return ai_choice_result((source_state(self).sfofl_zongma), options) end

    return ai_choice_result(nil, options)
end


sgs.ai_skill_playerchosen.sfofl_jiaozi = function(self, targets)
    targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
	local id = source_fact(self,"sfofl_jiaozi","toInt")
	local card = disclosed_card(self,id)
	if card then
		local c,to = package_call(self,"getCardNeedPlayer",{cards}, false)
		if c and to then
			return to
		end
	end
    for _, target in ipairs(targets) do
        if package_known(self,"isFriend",target) and package_known(self,"canDraw",target, self.player) then
            return target
        end
    end
    return nil
end
sgs.ai_playerchosen_intention.sfofl_jiaozi = -40

sgs.ai_skill_playerchosen.sfofl_jieyue = function(self, targets)
    return self.player
end
ai_skill_choice.sfofl_jieyue = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	if not package_known(self,"isWeak") then
		return ai_choice_result(("turn"), options)
	end

	return ai_choice_result(("draw"), options)
end
sgs.ai_skill_playerchosen.sfofl_daidi = function(self, targets)
	local card = disclosed_card(self,source_fact(self,"sfofl_daidi","toInt"))
	if card then
		local c,to = package_call(self,"getCardNeedPlayer",{cards}, true)
		if c and to then
			return to
		end
	end
    return self.player
end

local sfofl_xiaoguo_skill = {}
sfofl_xiaoguo_skill.name = "sfofl_xiaoguo"
table.insert(package_skills,sfofl_xiaoguo_skill)
sfofl_xiaoguo_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive


	if #self.enemies == 0 then return end
	return source_construct(self,"#sfofl_xiaoguo:.:")
end


ai_card_use["#sfofl_xiaoguo"] = function(self, card, use, request)
	local cmp = function(a, b)
		if package_known(a,"getHp") < package_known(b,"getHp") then
			if package_known(a,"getHp") == 1 and package_known(b,"getHp") == 2 then return false else return true end
		end
		return false
	end
	local enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"canAttack",enemy, self.player) and package_known(self,"objectiveLevel",enemy) > 3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal,self.player) and package_known(self,"canDamage",enemy,self.player,nil) then table.insert(enemies, enemy) end
	end
	if #enemies == 0 then return end


	local card_ids = {}
	local zcards = package_known(self.player,"getHandcards")
	for _, zcard in sgs.qlist(zcards) do
		if package_known(zcard,"isKindOf","BasicCard") then
			table.insert(card_ids, package_known(zcard,"getId"))
		end
	end
	if #card_ids == 0 then return end
	local hc_num = #card_ids
	for _, enemy in ipairs(enemies) do
		if package_known(enemy,"getHp") > 1 then
			use.card = source_construct(self,"#sfofl_xiaoguo:.:")
			package_call(use.card,"addSubcard",card_ids[1])
			if use.to then package_call(use.to,"append",enemy) end
			return
		else
			if not package_known(self,"isWeak") or package_known(self,"getSaveNum",true) >= 1 then
				use.card = source_construct(self,"#sfofl_xiaoguo:.:")
				package_call(use.card,"addSubcard",card_ids[1])
				if use.to then package_call(use.to,"append",enemy) end
				return
			end
		end
	end
end


sgs.ai_skill_playerchosen.sfofl_dizhao = function(self, targets)
    targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
    for _, target in ipairs(targets) do
        if package_known(self,"isFriend",target) and package_known(self,"canDraw",target, self.player) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if package_known(self,"isFriend",target) then
            return target
        end
    end
    return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_dizhao = -40

sgs.ai_skill_playerchosen.sfofl_dizhaoheal = function(self, targets)
    targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
	local arr1,arr2 = package_call(self,"getWoundedFriend",false,false)
	local target = nil

	if #arr1>0 and (package_known(self,"isWeak",arr1[1]) or package_known(self,"getOverflow")>=1) and package_known(arr1[1],"getHp")<getBestHp(arr1[1]) then target = arr1[1] end
	if target and table.contains(targets, target) then
		return target
	end
	if #arr2>0 then
		for _,friend in ipairs(arr2)do
			if table.contains(targets, friend) then
				return friend
			end
		end
	end
    return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_dizhaoheal = -40


package_add("sfofl_dizhao").getTurnUseCard = function(self,inclusive,request)
	for _,pc in sgs.list(patterns_for(self))do do
		if package_known(self,"getCardsNum",pc)>0 then goto package_continue_22 end
		if package_known(self.player,"getStrategyMark","sfofl_dizhao_guhuo_remove_"..pc.."_lun")<1 then
			local dc = clone(self,pc)
			if package_known(dc,"isKindOf","TrickCard") and package_known(self.player,"getStrategyMark","sfofl_dizhao_trick_lun") > 0
			then goto package_continue_22 end
			if package_known(dc,"isKindOf","BasicCard") and package_known(self.player,"getStrategyMark","sfofl_dizhao_basic_lun") > 0
			then goto package_continue_22 end
			package_call(dc,"setSkillName","sfofl_dizhao")
			local dummy_use = package_known(self,"aiUseCard",dc, dummy())
			if package_known(dc,"isAvailable",self.player) and dummy_use.card then
				source_state(self).sfofl_dizhao_to = dummy_use.to
				package_call(self,"setPriorityValue","sfofl_dizhao", sgs.ai_use_priority[package_known(dc,"getClassName")],"sfoflCard.source")
				return source_construct(self,"#sfofl_dizhao:.:".. pc)
			end
		end
	end ::package_continue_22:: end
end

ai_card_use["#sfofl_dizhao"] = function(self, card, use, request)
	use.card = card
	use.to = source_state(self).sfofl_dizhao_to
end

sgs.ai_guhuo_card.sfofl_dizhao = function(self,toname,class_name)
	if package_known(self.player,"getStrategyMark","sfofl_dizhao_guhuo_remove_"..toname.."_lun")>0
	or package_known(self,"getCardsNum",class_name)>0 then return end
	local cards = package_known(self.player,"getCards","he")
	cards = package_call(self,"sortByKeepValue",cards)
	local dc = clone(self,toname)
	if (not dc) then return end
	package_call(dc,"setSkillName","sfofl_dizhao")
	if package_known(dc,"isKindOf","TrickCard") and package_known(self.player,"getStrategyMark","sfofl_dizhao_trick_lun") > 0 then end
	if package_known(dc,"isKindOf","BasicCard") and package_known(self.player,"getStrategyMark","sfofl_dizhao_basic_lun") > 0 then end
	return "#sfofl_dizhao:.:"..toname
end

ai_skill_choice.sfofl_jixi = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = package_call(data,"toPlayer")
	if package_known(self,"doDisCard",target, "he", true) then
		return ai_choice_result(("obtain"), options)
	end

	return ai_choice_result(("draw"), options)
end

local sfofl_batteringram_skill = {}
sfofl_batteringram_skill.name = "sfofl_batteringram"
table.insert(package_skills,sfofl_batteringram_skill)
sfofl_batteringram_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive


	if #self.enemies == 0 then return end
	return source_construct(self,"#sfofl_batteringram:.:")
end


ai_card_use["#sfofl_batteringram"] = function(self, card, use, request)
	local cmp = function(a, b)
		if package_known(a,"getHp") < package_known(b,"getHp") then
			if package_known(a,"getHp") == 1 and package_known(b,"getHp") == 2 then return false else return true end
		end
		return false
	end
	local enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"canAttack",enemy, self.player) and package_known(self,"objectiveLevel",enemy) > 3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal,self.player) and package_known(self,"canDamage",enemy,self.player,nil) then table.insert(enemies, enemy) end
	end
	if #enemies == 0 then return end

	for _, enemy in ipairs(enemies) do
		if package_known(enemy,"getHp") > 1 then
			use.card = source_construct(self,"#sfofl_batteringram:.:")
			if use.to then package_call(use.to,"append",enemy) end
			return
		else
			if not package_known(self,"isWeak") or package_known(self,"getSaveNum",true) >= 1 then
				use.card = source_construct(self,"#sfofl_batteringram:.:")
				if use.to then package_call(use.to,"append",enemy) end
				return
			end
		end
	end
end

ai_skill_invoke.sfofl_bladecart = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = package_known(data,"toCardUse")
	return (package_known(self,"isEnemy",use.from) and not package_known(self,"cantbeHurt",use.from) and package_known(self,"damageIsEffective",use.from, sgs.DamageStruct_Normal,self.player) and package_known(self,"canDamage",use.from,self.player,nil)) or false
end


local sfofl_yufeng_skill = {}
sfofl_yufeng_skill.name = "sfofl_yufeng"
table.insert(package_skills,sfofl_yufeng_skill)
sfofl_yufeng_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies == 0 then return end
	return source_construct(self,"#sfofl_yufeng:.:")
end

ai_card_use["#sfofl_yufeng"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_priority["sfofl_yufeng"] = 0
sgs.ai_use_value["sfofl_yufeng"] = 2.5

sgs.ai_skill_playerchosen.sfofl_yufeng = function(self, targets)
    targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
    for _, target in ipairs(targets) do
        if package_known(self,"isEnemy",target) then
            return target
        end
    end
    return targets[math.random(1, #targets)]
end
sgs.ai_playerchosen_intention.sfofl_yufeng = 80


sgs.ai_skill_discard.sfofl_tianshu = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)

	table.insert(to_discard, package_known(cards[1],"getEffectiveId"))
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end

sgs.ai_skill_playerchosen.sfofl_tianshu = function(self, targets)
    targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
    for _, target in ipairs(targets) do
        if package_known(self,"isFriend",target) and package_known(self,"loseEquipEffect",target) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if package_known(self,"isFriend",target) then
            return target
        end
    end
    return nil
end
sgs.ai_playerchosen_intention.sfofl_tianshu = -80


local sfofl_zhengjing_skill = {}
sfofl_zhengjing_skill.name = "sfofl_zhengjing"
table.insert(package_skills,sfofl_zhengjing_skill)
sfofl_zhengjing_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_zhengjing:.:")
end

ai_card_use["#sfofl_zhengjing"] = function(self, card, use, request)
	package_call(self,"sort",self.friends, "defense")
	for _, target in ipairs(self.friends) do
		if package_known(self,"canDraw",target, self.player) and package_known(target,"getJudgingArea"):length()>0 then
			use.card = card
			package_call(use.to,"append",target)
			return
		end
	end
	for _, target in ipairs(self.friends) do
		if package_known(target,"getJudgingArea"):length()>0 then
			use.card = card
			package_call(use.to,"append",target)
			return
		end
	end
	for _, target in ipairs(self.friends) do
		if package_known(self,"canDraw",target, self.player) then
			use.card = card
			package_call(use.to,"append",target)
			return
		end
	end
end



local sfofl_juezhi_skill = {}
sfofl_juezhi_skill.name = "sfofl_juezhi"
table.insert(package_skills,sfofl_juezhi_skill)
sfofl_juezhi_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	package_call(self,"setPriorityValue","sfofl_juezhi", 3,"sfoflCard.source")
	if package_known(self.player,"getCardCount",true)<2 then return false end
	if package_known(self,"getOverflow")<=0 then return false end
	if package_known(self,"isWeak") and package_known(self,"getOverflow")<=1 then return false end
	return source_construct(self,"#sfofl_juezhi:.:")
end
ai_card_use["#sfofl_juezhi"] = function(self, card, use, request)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByKeepValue",cards)

	local red_num,black_num = 0,0
	if package_known(self.player,"getHp")<3 then
		local zcards = package_known(self.player,"getCards","he")
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = source_fact(self,"JilveWansha","toBool")
		for _,zcard in sgs.qlist(zcards)do do
			if package_known(self.player,"isCardLimited",zcard,sgs.Card_MethodDiscard) then goto package_continue_23 end
			if not isCard("Peach",zcard,self.player) and not isCard("ExNihilo",zcard,self.player) then
				local shouldUse = true
				if isCard("Slash",zcard,self.player) and not use_slash then
					local dummy_use = dummy()
					package_call(self,"useBasicCard",zcard,dummy_use)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.qlist(dummy_use.to)do
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
					local dummy_use = dummy()
					package_call(self,"useTrickCard",zcard,dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if package_known(zcard,"getTypeId")==sgs.Card_TypeEquip and not package_known(self.player,"hasEquip",zcard) then
					local dummy_use = dummy()
					package_call(self,"useEquipCard",zcard,dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and package_known(zcard,"getEffectiveId")==package_known(keep_weapon,"getEffectiveId") then shouldUse = false end
				end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","Armor") and not package_known(self,"needToThrowArmor") then shouldUse = false end
				if package_known(self.player,"hasTreasure","wooden_ox") then shouldUse = false end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","DefensiveHorse") and not package_known(self,"needToThrowArmor") then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if package_known(self.player,"getHp")==1 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then
					if (table.contains(unpreferedCards,package_known(zcard,"getId"))) then goto package_continue_23 end
					table.insert(unpreferedCards,package_known(zcard,"getId"))
					if package_known(self.room,"getCardPlace",package_known(zcard,"getId"))==sgs.Player_PlaceHand then
						if package_known(zcard,"isRed") then red_num = red_num+1
						else black_num = black_num+1 end
					end
				end
				if #unpreferedCards==2 then
					use.card = source_construct(self,"#sfofl_juezhi:"..table.concat(unpreferedCards,"+")..":")
					return
				end
			end
		end ::package_continue_23:: end
	end

	local red = package_known(self,"getSuitNum","red")
	local black = package_known(self,"getSuitNum","black")
	if red-red_num<=2-#unpreferedCards then
		for _,c in ipairs(cards)do do
			if package_known(c,"isRed") and (not isCard("Peach",c,self.player) or not package_known(self,"findFriendsByType",sgs.Friend_Weak) and #cards>1) then
				if package_known(self.player,"isCardLimited",c,sgs.Card_MethodDiscard) then goto package_continue_24 end
				if table.contains(unpreferedCards,package_known(c,"getId")) then goto package_continue_24 end
				table.insert(unpreferedCards,package_known(c,"getId"))
			end
		end ::package_continue_24:: end
	elseif black-black_num<=2-#unpreferedCards then
		for _,c in ipairs(cards)do do
			if package_known(c,"isBlack") and (not isCard("Peach",c,self.player) or not package_known(self,"findFriendsByType",sgs.Friend_Weak) and #cards>1) then
				if package_known(self.player,"isCardLimited",c,sgs.Card_MethodDiscard) then goto package_continue_25 end
				if table.contains(unpreferedCards,package_known(c,"getId")) then goto package_continue_25 end
				table.insert(unpreferedCards,package_known(c,"getId"))
			end
		end ::package_continue_25:: end
	end

	if #unpreferedCards<2 then
		for _,c in ipairs(cards)do do
			if not package_known(self.player,"isCardLimited",c,sgs.Card_MethodDiscard) then
				if table.contains(unpreferedCards,package_known(c,"getId")) then goto package_continue_26 end
				table.insert(unpreferedCards,package_known(c,"getId"))
			end
			if #unpreferedCards==2 then break end
		end ::package_continue_26:: end
	end

	if #unpreferedCards==2 then
		use.card = source_construct(self,"#sfofl_juezhi:"..table.concat(unpreferedCards,"+")..":")
		package_call(self,"setPriorityValue","sfofl_juezhi", 0,"sfoflCard.source")
		return
	end

end

sgs.ai_use_priority.sfofl_juezhi = 3

sgs.ai_skill_askforag.sfofl_juezhi = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = disclosed_card(self,id)
		if package_known(self.player,"getStrategyMark","&xingtu") == package_known(card,"getNumber") then
			return id
		end
		if package_known(self.player,"getStrategyMark","&xingtu") % package_known(card,"getNumber") == 0 then
			return id
		end
	end
end

ai_skill_invoke.sfofl_xiaofan_damage = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = package_known(data,"toDamage")
	if damage.to and package_known(self,"isEnemy",damage.to) then
		if not package_known(self,"cantbeHurt",damage.to) and package_known(self,"canDamage",damage.to,self.player,nil) and package_known(self,"damageIsEffective",damage.to, sgs.DamageStruct_Normal, self.player) then
			return (true) or false
		end
	end
	if package_known(damage.to,"objectName") == package_known(self.player,"objectName") then
		if not package_known(self,"damageIsEffective",damage.to, sgs.DamageStruct_Normal, self.player) or package_known(self,"needToLoseHp",damage.to,self.player,nil) then
			return (true) or false
		end
		if not package_known(self,"isWeak") then
			return (math.random() < 0.5) or false
		end
	end
	return (false) or false
end

sgs.ai_ajustdamage_from.sfofl_huoluan = function(self, from, to, card, nature)
    if package_known(from,"getKingdom") == "qun" and package_known(to,"getKingdom") == "qun"
    then
        return 1
    end
end
sgs.ai_ajustdamage_to.sfofl_huoluan = function(self, from, to, card, nature)
    if package_known(from,"getKingdom") == "qun" and package_known(to,"getKingdom") == "qun"
    then
        return 1
    end
end

sgs.ai_skill_playerchosen.sfofl_anmou = function(self, targets)
    targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
    for _, target in ipairs(targets) do
        if package_known(self,"isEnemy",target) then
            return target
        end
    end
    return targets[math.random(1, #targets)]
end

sgs.ai_ajustdamage_from.sfofl_tousuan = function(self, from, to, card, nature)
    if package_known(to,"getStrategyMark","sfofl_anmou"..package_known(from,"objectName")) > 0
    then
        return 1
    end
end
sgs.ai_ajustdamage_to.sfofl_tousuan = function(self, from, to, card, nature)
    if package_known(from,"getStrategyMark","sfofl_anmou"..package_known(to,"objectName")) > 0
    then
        return 1
    end
end



package_add("sfofl_qianjing").getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasSkill","sfofl_bianchi") and package_known(self.player,"getStrategyMark","@sfofl_bianchi") > 0 then return end
	local cards = {}
  	for i,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
		for d,c in sgs.list(package_known(p,"getCards","ej"))do
			if package_known(c,"isKindOf","sfofl_xingbian")
			then table.insert(cards,c) end
		end
	end
	package_call(self,"sortByKeepValue",cards,nil,"l")
  	for _,c in sgs.list(cards)do
		local dc = clone(self)
		package_call(dc,"setSkillName","sfofl_qianjing")
		package_call(dc,"addSubcard",c)
		local d = package_known(self,"aiUseCard",dc)
		if d.card and d.to
		and package_known(dc,"isAvailable",self.player)
		then
			source_state(self).sfofl_qianjing_to = d.to
			package_call(self,"setPriorityValue","sfofl_qianjing", sgs.ai_use_priority.Slash+0.6,"sfoflCard.source")
			return source_construct(self,"#sfofl_qianjing:"..package_known(c,"getEffectiveId")..":slash")
		end
	end
end

ai_card_use["#sfofl_qianjing"] = function(self, card, use, request)
	if source_state(self).sfofl_qianjing_to
	then
		use.card = card
		use.to = source_state(self).sfofl_qianjing_to
	end
end

sgs.ai_use_value.sfofl_qianjing = 5.4
sgs.ai_use_priority.sfofl_qianjing = 2.8


ai_skill_use["@@sfofl_qianjing"]=function(self,prompt,request)
	local use_card
	local target
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)

    for _, c in ipairs(cards) do
		if package_known(c,"isKindOf","sfofl_xingbian") then
			use_card = c
			break
		end
	end
	if use_card then
		local n = package_known(use_card,"getRealCard"):toEquipCard():location()
		if package_known(self.player,"hasSkill","sfofl_bianchi") and package_known(self.player,"getStrategyMark","@sfofl_bianchi") > 0 then
			package_call(self,"sort",self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if package_known(enemy,"hasEquipArea",n) and package_call(enemy,"getEquip",n)==nil then
					target = enemy
					break
				end
			end
		end
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if package_known(enemy,"hasEquipArea",n) and package_call(enemy,"getEquip",n)==nil and not package_known(self,"loseEquipEffect",enemy) then
					target = enemy
					break
				end
			end
		end
		if not target then
			if package_known(self.player,"hasEquipArea",n) and package_call(self.player,"getEquip",n)==nil then
				target = self.player
			end
		end
	end
	if use_card and target then
		return "#sfofl_qianjingEquipCard:".. package_known(use_card,"getEffectiveId")..":->"..package_known(target,"objectName")
	end
	return "."
end

sgs.ai_card_priority.sfofl_qianjing = function(self,card)
	if table.contains(package_known(card,"getSkillNames"), "sfofl_qianjing")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end


sgs.ai_use_revises.sfofl_qianjing = function(self,card,use)
	if package_known(card,"isKindOf","sfofl_xingbian") then return false end

end
ai_skill_invoke.sfofl_bianchi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local x = 0
	for _,p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
		for _,card in sgs.qlist(package_known(p,"getCards","e")) do
			if package_known(card,"isKindOf","sfofl_xingbian") then
				if package_known(self,"isEnemy",p) and (package_known(p,"getHandcardNum") > 2 or package_known(self,"isWeak",p) ) then
					return (true) or false
				end
				if package_known(self,"isEnemy",p)  then
					x = x + 1
				end
			end
		end
	end
	if x >= 2 then
		return (true) or false
	end
	return (false) or false
end

ai_skill_choice.sfofl_bianchi = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local target = package_call(data,"toPlayer")
	local usecard = getChoice(choices, "usecard")
	if usecard then
		if package_known(self.player,"getHandcardNum") < 4 then
			return ai_choice_result((usecard), options)
		end
		if package_known(self.player,"getHp")+package_known(self,"getAllPeachNum")-2<=0 then
			return ai_choice_result((usecard), options)
		end
		return ai_choice_result((usecard), options)
	end

	return ai_choice_result(("losehp"), options)
end

ai_skill_use["@@sfofl_bianchi"]=function(self,prompt,request)
	if package_known(self.player,"getStrategyMark","sfofl_bianchi-Clear") > 0 then return "." end
	local card_ids = source_fact(self,"sfofl_bianchiForAI","toIntList")
	card_ids = sgs.QList2Table(card_ids)
	local target
	for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(p,"getStrategyFlag","sfofl_bianchi") then
			target = p
			break
		end
	end
    for _, id in ipairs(card_ids) do
		if package_known(self.room,"getCardPlace",id)==sgs.Player_PlaceHand then
			local c = disclosed_card(self,id)
			local dummy_use = package_known(self,"aiUseCard",c,dummy())
			if dummy_use.card and dummy_use and dummy_use.to then
				local tos = {}
				for _,to in sgs.qlist(dummy_use.to) do
					if source_can_to_card(self,c,target,to) then
						table.insert(tos, package_known(to,"objectName"))
					end
				end
				return "#sfofl_bianchi:"..id..":->"..table.concat(tos, "+")
			end
		end
	end
    return "."
end

sgs.ai_skill_playerchosen._sfofl_xingbian = function(self, targets)
    targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
    for _, target in ipairs(targets) do
        if package_known(self,"isEnemy",target) then
            return target
        end
    end
    return targets[math.random(1, #targets)]
end

sgs.ai_poison_card._sfofl_xingbian_weapon = function(self,c,player)
	return not package_known(player,"hasEquip",c) and package_known(player,"hasEquip") and not package_known(player,"hasSkill","sfofl_qianjing")
end
sgs.ai_poison_card._sfofl_xingbian_armor = function(self,c,player)
	return not package_known(player,"hasEquip",c) and package_known(player,"hasEquip") and not package_known(player,"hasSkill","sfofl_qianjing")
end
sgs.ai_poison_card._sfofl_xingbian_offensivehorse = function(self,c,player)
	return not package_known(player,"hasEquip",c) and package_known(player,"hasEquip") and not package_known(player,"hasSkill","sfofl_qianjing")
end
sgs.ai_poison_card._sfofl_xingbian_defensivehorse = function(self,c,player)
	return not package_known(player,"hasEquip",c) and package_known(player,"hasEquip") and not package_known(player,"hasSkill","sfofl_qianjing")
end
sgs.ai_poison_card._sfofl_xingbian_treasure = function(self,c,player)
	return not package_known(player,"hasEquip",c) and package_known(player,"hasEquip") and not package_known(player,"hasSkill","sfofl_qianjing")
end

ai_skill_invoke.sfofl_changshi = true
sgs.ai_skill_playerchosen.sfofl_changshi = function(self, targets)
    targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
    for _, target in ipairs(targets) do
        if package_known(self,"isEnemy",target) then
            return target
        end
    end
    return targets[math.random(1, #targets)]
end

package_add("sfofl_taoluan").getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = package_call(self,"sortByKeepValue",cards)
	for _,pc in sgs.list(RandomList(patterns_for(self)))do do
		if package_known(self,"getCardsNum",pc)>0 then goto package_continue_27 end
		for _,c in sgs.list(cards)do
			local dc = clone(self,pc)
			if package_known(dc,"isKindOf","TrickCard") or package_known(dc,"isKindOf","BasicCard") then
				package_call(dc,"addSubcard",package_known(c,"getEffectiveId"))
				package_call(dc,"setSkillName","sfofl_taoluan")
				local dummy_use = package_known(self,"aiUseCard",dc, dummy())
				if package_known(dc,"isAvailable",self.player) and dummy_use.card then
					local suit = package_known(c,"getSuitString")
					local number = package_known(c,"getNumberString")
					local card_id = package_known(c,"getEffectiveId")
					local card_str = (pc..":sfofl_taoluan[%s:%s]=%d"):format(suit,number,card_id)
					local card = source_construct(self,card_str)
					assert(card)
					return card
				end
			end
		end
	end ::package_continue_27:: end
end


ai_skill_invoke.sfofl_chiyan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	if package_known(self,"isEnemy",target) then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_ajustdamage_to["&sfofl_chiyan"] = function(self,from,to,card,nature)
	return 1
end

sgs.ai_damage_reason_suppress_intention["sfofl_zimou"] = true
sgs.ai_skill_discard.sfofl_zimou = function(self)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")


	if package_known(self,"needToLoseHp",self.player,nil, nil) then
		return {}
	end
	if not package_known(self,"damageIsEffective",self.player,"N", nil) and not package_known(self,"isFriend",package_call(self.room,"getCurrent")) then
		return {}
	end
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, package_known(card,"getEffectiveId"))
        break
	end
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end



local sfofl_picai_skill = {}
sfofl_picai_skill.name = "sfofl_picai"
table.insert(package_skills,sfofl_picai_skill)
sfofl_picai_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_picai:.:")
end

ai_card_use["#sfofl_picai"] = function(self, card, use, request)

	package_call(self,"sort",self.enemies,"handcard")

	local targets = sgs.SPlayerList()
	for _,enemy in ipairs(self.enemies) do
		if package_known(self,"doDisCard",enemy, "h") and not package_known(enemy,"isKongcheng") then
			package_call(targets,"append",enemy)
			if package_known(targets,"length") >= package_known(self.player,"getHp") then
				break
			end
		end
	end
	for _,friend in ipairs(self.friends_noself) do
		if package_known(self,"doDisCard",friend, "h") and not package_known(friend,"isKongcheng") then
			if package_known(targets,"length") >= package_known(self.player,"getHp")  then
				break
			end
			package_call(targets,"append",friend)
		end
	end
	if package_known(targets,"length") > 0 then
		use.card = card
		use.to = targets
	end

end

sgs.ai_use_priority.sfofl_picai = sgs.ai_use_priority.Slash+0.1
sgs.ai_use_value.sfofl_picai = 8.5



sgs.ai_cardneed.sfofl_yaozhuo = sgs.ai_cardneed.bignumber

package_add("sfofl_yaozhuo").getTurnUseCard = function(self,inclusive,request)
	return source_construct(self,"#sfofl_yaozhuo:.:")
end

ai_card_use["#sfofl_yaozhuo"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies)
    for _,p in sgs.list(self.enemies)do
		if package_known(self.player,"canPindian",p) then
			use.card = card
			package_call(use.to,"append",p)
			return
		end
	end
end

sgs.ai_use_value.sfofl_yaozhuo = 1.4
sgs.ai_use_priority.sfofl_yaozhuo = 5.8
sgs.ai_card_intention.sfofl_yaozhuo = 50
ai_skill_invoke.sfofl_yaozhuo = true

ai_skill_use["@@sfofl_yaozhuo"]=function(self,prompt,request)
	package_call(self,"sort",self.enemies)
    for _,p in sgs.list(self.enemies)do
		if package_known(self.player,"canPindian",p) then
            return "#sfofl_yaozhuo:.:->"..package_known(p,"objectName")
        end
    end
	return "."
end


local sfofl_kuiji_skill = {}
sfofl_kuiji_skill.name = "sfofl_kuiji"
table.insert(package_skills,sfofl_kuiji_skill)
sfofl_kuiji_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_kuiji:.:")
end

ai_card_use["#sfofl_kuiji"] = function(self, card, use, request)
	if #self.enemies<=0 then return end
	local target = nil
	package_call(self,"sort",self.enemies,"handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if package_known(self,"doDisCard",p,"h")
		then target = p	break end
	end
	if not target then return end
	source_state(self).sfofl_kuiji_target = nil
	if package_known(target,"getHandcardNum")>0 then
		use.card = card
		source_state(self).sfofl_kuiji_target = target
		package_call(use.to,"append",target)
	end
end

ai_skill_use["@@sfofl_kuiji"]=function(self,prompt,request)
	if source_state(self).sfofl_kuiji_target then
		local target_handcards = sgs.QList2Table(source_state(self).package_known(sfofl_kuiji_target,"getCards","h"))
		package_call(self,"sortByUseValue",target_handcards,inverse)
		local handcards = sgs.QList2Table(package_known(self.player,"getCards","h"))
		local discard_cards = {}
		local spade_check = true
		local heart_check = true
		local club_check = true
		local diamond_check = true
		local target_discard_count = 0

		for _,c in sgs.list(target_handcards)do
			if spade_check and package_known(c,"getSuit")==sgs.Card_Spade then
				spade_check = false
				table.insert(discard_cards,package_known(c,"getEffectiveId"))
			elseif heart_check and package_known(c,"getSuit")==sgs.Card_Heart then
				heart_check = false
				table.insert(discard_cards,package_known(c,"getEffectiveId"))
			elseif club_check and package_known(c,"getSuit")==sgs.Card_Club then
				club_check = false
				table.insert(discard_cards,package_known(c,"getEffectiveId"))
			elseif diamond_check and package_known(c,"getSuit")==sgs.Card_Diamond then
				diamond_check = false
				table.insert(discard_cards,package_known(c,"getEffectiveId"))
			end
			target_discard_count = #discard_cards
		end

		for _,c in sgs.list(handcards)do
			if not package_known(c,"isKindOf","Peach")
			and not package_known(c,"isKindOf","Duel")
			and not package_known(c,"isKindOf","Indulgence")
			and not package_known(c,"isKindOf","SupplyShortage")
			and not (package_known(self,"getCardsNum","Jink")==1 and package_known(c,"isKindOf","Jink"))
			and not (package_known(self,"getCardsNum","Analeptic")==1 and package_known(c,"isKindOf","Analeptic")) then
				if spade_check and package_known(c,"getSuit")==sgs.Card_Spade then
					spade_check = false
					table.insert(discard_cards,package_known(c,"getEffectiveId"))
				elseif heart_check and package_known(c,"getSuit")==sgs.Card_Heart then
					heart_check = false
					table.insert(discard_cards,package_known(c,"getEffectiveId"))
				elseif club_check and package_known(c,"getSuit")==sgs.Card_Club then
					club_check = false
					table.insert(discard_cards,package_known(c,"getEffectiveId"))
				elseif diamond_check and package_known(c,"getSuit")==sgs.Card_Diamond then
					diamond_check = false
					table.insert(discard_cards,package_known(c,"getEffectiveId"))
				end
			end
		end
		if #discard_cards==4 and target_discard_count>1 then
			return "#sfofl_kuijidisCard:"..table.concat(discard_cards,"+")..":"
		end
	end
	return "."
end

sgs.ai_use_priority.sfofl_kuiji = 3
sgs.ai_use_value.sfofl_kuiji = 3
sgs.ai_card_intention.sfofl_kuiji = 50


sgs.ai_ajustdamage_from.sfofl_chihe = function(self,from,to,card,nature)
	if card and package_known(card,"hasFlag","sfofl_chihe") then
		return 1
	end
end


ai_skill_invoke.sfofl_chihe = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = package_known(data,"toCardUse")
	if package_known(use.from,"objectName") == package_known(self.player,"objectName") then
		if package_known(self,"isFriend",package_known(use.to,"first")) then return (false) or false end
		return (true) or false
	else
		if use.from and package_known(self,"isEnemy",use.from) then
			if not package_known(self,"canLiegong",self.player, use.from) and (package_known(self,"getCardsNum","Jink")>0 or package_known(self,"hasEightDiagramEffect")) then
				return (true) or false
			end
			if package_known(self,"ajustDamage",use.from,self.player,1,use.card) <= 0 then
				return (true) or false
			end
		end
	end

	return (false) or false
end

ai_skill_invoke.sfofl_niqu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
	package_call(slash,"deleteLater")
	package_call(slash,"setSkillName","sfofl_niqu")
	local dummy_use = package_known(self,"aiUseCard",slash, dummy(true, 0, package_known(self.room,"getOtherPlayers",target)))
	if dummy_use.card and dummy_use and dummy_use.to and package_known(dummy_use.to,"contains",target) then
		return (true) or false
	end
	return (false) or false
end

ai_skill_invoke.sfofl_miaoyu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	if target and package_known(self,"isEnemy",target) then
		return (true) or false
	end
	return (false) or false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_miaoyu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = package_call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,50) end
	end
end


local sfofl_xiaoluAttach_skill = {}
sfofl_xiaoluAttach_skill.name = "sfofl_xiaoluAttach"
table.insert(package_skills, sfofl_xiaoluAttach_skill)
sfofl_xiaoluAttach_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	if not cards[1] then return nil end
	local card_str = "#sfofl_xiaolu:" .. package_known(cards[1],"getEffectiveId") .. ":"
	local skillcard = source_construct(self,card_str)
	return skillcard
end

ai_card_use["#sfofl_xiaolu"] = function(self, card, use, request)
	if package_known(self,"needBear") then
		return
	end
	local targets = {}
	for _, friend in ipairs(self.friends) do
		if package_known(friend,"hasSkill","sfofl_xiaolu") then
			if package_known(self.player,"getStrategyMark","sfofl_xiaolu"..package_known(friend,"objectName").."-PlayClear") == 0 then
				table.insert(targets, friend)
			end
		end
	end
	if #targets > 0 then
		use.card = card
		package_call(self,"sort",targets, "defense")
		if use.to then
			package_call(use.to,"append",targets[1])
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if package_known(enemy,"hasSkill","sfofl_xiaolu") then
				if package_known(self.player,"getStrategyMark","sfofl_xiaolu"..package_known(enemy,"objectName").."-PlayClear") == 0 then
					table.insert(targets, enemy)
				end
			end
		end
		if #targets > 0 then
			package_call(self,"sort",targets, "defense", true)
			for _, enemy in ipairs(targets) do
				use.card = card
				if use.to then
					package_call(use.to,"append",enemy)
				end
				break
			end

		end
	end
end

sgs.ai_use_priority.sfofl_xiaolu = 3
sgs.ai_use_value.sfofl_xiaolu = 8.5


sgs.ai_skill_askforag.sfofl_xiaolu = function(self,card_ids)
	for _,id in ipairs(RandomList(card_ids))do
		local card = disclosed_card(self,id)
		local dummy_use = package_known(self,"aiUseCard",card, dummy())
		if package_known(card,"isAvailable",self.player) and dummy_use.card then
			return id
		end
	end
end

sgs.ai_skill_playerchosen.sfofl_xiaolu = function(self, targets)
	local card = disclosed_card(self,package_known(self.player,"getStrategyMark","sfofl_xiaolu"))
	local use_card = clone_native(self,package_known(card,"objectName"), sgs.Card_NoSuit, 0)
	package_call(use_card,"setSkillName","sfofl_xiaolu")
	package_call(use_card,"deleteLater")
	local dummy_use = package_known(self,"aiUseCard",use_card, dummy())
    targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
    for _, target in ipairs(targets) do
        if package_known(dummy_use.to,"contains",target) then
			return target
		end
    end
    return targets[math.random(1, #targets)]
end

ai_skill_invoke.sfofl_tianzel = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (ai_skill_invoke.tianming(self, options, request)) or false
end
sgs.ai_skill_discard.sfofl_tianzel = function(self,discard_num,min_num,optional,include_equip)
	return sgs.ai_skill_discard.tianming(self,discard_num,min_num,optional,include_equip)
end

sgs.ai_skill_playerchosen.sfofl_tianzel = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
    for _, target in ipairs(targets) do
        if package_known(self,"isFriend",target) and package_known(self,"canDraw",target) then
            return target
        end
    end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_tianzel = -40

local sfofl_zhaoyuan_skill = {}
sfofl_zhaoyuan_skill.name = "sfofl_zhaoyuan"
table.insert(package_skills,sfofl_zhaoyuan_skill)
sfofl_zhaoyuan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self.player,"isKongcheng")
	or package_known(self,"needBear") then return end
	return source_construct(self,"#sfofl_zhaoyuan:.:")
end

ai_card_use["#sfofl_zhaoyuan"] = function(self, card, use, request)
	local count = 0
	local target
	for _,enemy in sgs.list(self.enemies)do
		if not package_known(enemy,"isKongcheng") then count = count+1 end
	end
	if not target then
		package_call(self,"sort",self.friends_noself,"defense")
		self.friends_noself = sgs.reverse(self.friends_noself)
		if count<1 then return end
		for _,friend in sgs.list(self.friends_noself)do
			if package_known(self,"hasTuntianEffect",friend) and not hasManjuanEffect(friend) and not package_known(self,"isWeak",friend) and package_known(self,"canDraw",friend, self.player)
			then target = friend break end
		end
		if not target then
			for _,friend in sgs.list(self.friends_noself)do
				if package_known(self,"canDraw",friend, self.player)
				then target = friend break end
			end
		end
	end
	if target then
		for _,c in sgs.list(package_known(self,"addHandPile"))do
			if isCard("Peach",c,self.player) and package_known(self.player,"getHandcardNum")>1 and package_known(self.player,"isWounded")
			and not package_known(self,"needToLoseHp",self.player,nil,c)
			then use.card = c return end
		end
		package_call(card,"addSubcards",package_known(self.player,"getHandcards"))
		use.card = card
		source_player_flag(self,target,"AI_sfofl_zhaoyuanTarget",true)
		package_call(use.to,"append",target)
	end
end

sgs.ai_use_priority.sfofl_zhaoyuan = 1.5
sgs.ai_card_intention.sfofl_zhaoyuan = 0
sgs.ai_playerchosen_intention.sfofl_zhaoyuan = 10

sgs.ai_skill_playerchosen.sfofl_zhaoyuan = function(self,targets)
	package_call(self,"sort",self.enemies,"defense")
	local slash = clone(self)
	for _,to in sgs.list(self.enemies)do
		if package_known(targets,"contains",to) and package_known(self,"slashIsEffective",slash,to,self.player) and not package_known(self,"needToLoseHp",to,self.player,slash) and package_known(self.player,"canPindian",to)
			and not package_known(self,"needToLoseHp",to,self.player,slash) and not package_known(self,"findLeijiTarget",to,50,self.player) then
			return to
		end
	end
	for _,to in sgs.list(self.enemies)do
		if package_known(targets,"contains",to) and package_known(self.player,"canPindian",to) then
			return to
		end
	end
end

function sgs.ai_skill_pindian.sfofl_zhaoyuan(minusecard,self,requestor,maxcard)
	local req
	if package_known(self.player,"objectName")==package_known(requestor,"objectName") then
		for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player))do
			if package_known(p,"getStrategyFlag","sfofl_zhaoyuanPindianTarget") then
				req = p
				break
			end
		end
	else
		req = requestor
	end
	local cards,maxcard = sgs.QList2Table(package_known(self.player,"getHandcards")),nil
	local max_value = 0
	package_call(self,"sortByKeepValue",cards)
	max_value = package_known(self,"getKeepValue",cards[#cards])
	local function compare_func1(a,b)
		return package_known(a,"getNumber")>package_known(b,"getNumber")
	end
	local function compare_func2(a,b)
		return package_known(a,"getNumber")<package_known(b,"getNumber")
	end
	if package_known(self,"isFriend",req) and package_known(self.player,"getHp")>package_known(req,"getHp") then
		table.sort(cards,compare_func2)
	else
		table.sort(cards,compare_func1)
	end
	for _,card in sgs.list(cards)do
		if max_value>7 or package_known(self,"getKeepValue",card)<7 or package_known(card,"isKindOf","EquipCard") then maxcard = card break end
	end
	return maxcard or cards[1]
end

ai_skill_invoke.sfofl_julian = true

ai_skill_use["@@sfofl_gezhi"]=function(self,prompt,request)
    local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local discard = {}
    local types = {}
	for _, card in ipairs(cards) do
        if not table.contains(types,package_known(card,"getType")) then
		    table.insert(discard, package_known(card,"getEffectiveId"))
		    table.insert(types, package_known(card,"getType"))
        end
	end

	if #discard == 3 then
		return "#sfofl_gezhi:".. table.concat(discard, "+") ..":"
	end
    return "."
end


ai_skill_choice.sfofl_gezhi = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = package_known(choices,"split","+")
	if table.contains(items, "recover") then
		if package_known(self,"isWeak") or math.random() < 0.3 then
			return ai_choice_result(("recover"), options)
		end
	end
	if table.contains(items, "damage") then
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
			if package_known(p,"getStrategyMark","sfofl_gezhi"..package_known(self.player,"objectName")) == 0 then
				package_call(targets,"append",p)
			end
		end
		if package_known(targets,"length") > 0 then
			if sgs.ai_skill_playerchosen.sfofl_gezhi(self, targets) ~= nil then
				return ai_choice_result(("damage"), options)
			end
		end
	end

	return ai_choice_result(("RemoveFromHistory"), options)
end

sgs.ai_skill_playerchosen.sfofl_gezhi = function(self,targets)
	return package_known(self,"findPlayerToDamage",1,self.player,"N",targets,1)[1]
end

sgs.ai_card_priority.sfofl_gezhi = function(self,card,v)
	if package_known(self.player,"getStrategyFlag","sfofl_gezhi") and (package_known(card,"isKindOf","Slash") or package_known(card,"isKindOf","Analeptic"))
	then return 10 end
end

package_add("sfofl_hefa").getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards = package_call(self,"sortByKeepValue",cards,nil,true)
	if #cards<1 then return end
	local ids = {}
   	local fs = clone(self)
	package_call(fs,"setSkillName","sfofl_hefa")
  	for _,c in sgs.list(cards)do do
		if package_known(self,"getKeepValue",c)>3
		or #ids>=#cards/2 then goto package_continue_28 end
		table.insert(ids,package_known(c,"getEffectiveId"))
		package_call(fs,"addSubcard",c)
	end ::package_continue_28:: end
	if #ids<1 and #cards>1
	then
		table.insert(ids,package_known(cards[1],"getEffectiveId"))
		package_call(fs,"addSubcard",cards[1])
	end
	local dummy = package_known(self,"aiUseCard",fs)
	if package_known(fs,"isAvailable",self.player)
	and dummy.card
	and dummy.to
	and #ids>0
  	then
		ids = #ids>0 and table.concat(ids,"+") or "."
		return fs
	end
end


sgs.ai_skill_playerchosen.sfofl_huanlei = function(self,targets)
	return package_known(self,"findBestDamageTarget",2, "T")
end

sgs.ai_playerchosen_intention.sfofl_huanlei = sgs.ai_playerchosen_intention.leiji


sgs.ai_skill_cardask["@sfofl_xiandaoz-card"]=function(self,data)
	local all_cards = package_known(self,"addHandPile","he")
	if #all_cards<1 then return "." end
	local judge = package_known(data,"toJudge")
	local needTokeep = package_known(judge.card,"getSuit")~=sgs.Card_Spade and (not package_known(self.player,"hasSkill","leiji") or package_known(judge.card,"getSuit")~=sgs.Card_Club)
		and package_known(self,"findLeijiTarget",self.player,50) and (package_known(self,"getCardsNum","Jink")>0 or package_known(self,"hasEightDiagramEffect")) and package_known(self,"getFinalRetrial")==1
	if not needTokeep and package_known(judge.who,"getPhase")<=sgs.Player_Judge
	and package_known(judge.who,"containsTrick","lightning") and judge.reason~="lightning"
	then needTokeep = true end
	local keptspade = 0
	if needTokeep and package_known(self.player,"hasSkills","nosleiji|tenyearleiji")
	then keptspade = 2 end
	local cards = {}
	for _,card in sgs.list(all_cards)do
		if package_known(card,"isBlack") and not package_known(card,"hasFlag","using") then
			if package_known(card,"getSuit")==sgs.Card_Spade then keptspade = keptspade-1 end
			table.insert(cards,card)
		end
	end
	if #cards<1 or keptspade==1 then return "." end
	local card_id = package_known(self,"getRetrialCardId",cards,judge,nil,true)
	if card_id<0 then return "." end
	if package_known(self,"needRetrial",judge)
	or package_known(self,"getUseValue",judge.card)>package_known(self,"getUseValue",disclosed_card(self,card_id))
	then return card_id end
	return "."
end

sgs.ai_cardneed.sfofl_xiandaoz = sgs.ai_cardneed.guidao

sgs.ai_use_revises.sfofl_xiandaoz = function(self,card,use)
	if package_known(card,"isKindOf","EquipCard")
	and package_known(card,"isBlack")
	then
		local same = package_known(self,"getSameEquip",card)
		if same and package_known(same,"isBlack")
		then return false end
	end
end

sgs.ai_suit_priority.sfofl_xiandaoz = sgs.ai_suit_priority.guidao

sgs.ai_useto_revises.sfofl_xiandaoz = function(self,card,use,p)
	if package_known(card,"isKindOf","Lightning")
	then
		if package_known(self,"isFriend",p) and package_known(p,"getCardCount")>2
		then use.card = card return end
		return false
	end
end

local sfofl_shenglv_skill = {}
sfofl_shenglv_skill.name = "sfofl_shenglv"
table.insert(package_skills,sfofl_shenglv_skill)
sfofl_shenglv_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local x = math.max(package_known(self.player,"usedTimes","#sfofl_shenglv"), 0)
	if x > 0 and package_known(self,"getCardsNum","Peach")+package_known(self.player,"getHp")-x<=0 then return end
	if x > 0 and (package_known(self,"isWeak") or package_known(self,"needBear")) then return end
	if x > 0 and package_known(self,"getOverflow") > 0 then return end
	if x > 1 then return end
	return source_construct(self,"#sfofl_shenglv:.:")
end

ai_card_use["#sfofl_shenglv"] = function(self, card, use, request)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))

	if package_known(self.player,"getHp")<3 then
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = source_fact(self,"JilveWansha","toBool")
		for _,zcard in sgs.list(package_known(self.player,"getCards","h"))do
			if not isCard("Peach",zcard,self.player)
			then
				local shouldUse = true
				if isCard("Slash",zcard,self.player)
				and not use_slash
				then
					local dummy_use = package_known(self,"aiUseCard",zcard)
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
					if package_known(self,"aiUseCard",zcard).card then shouldUse = false end
				end
				if package_known(zcard,"getTypeId")==sgs.Card_TypeEquip and not package_known(self.player,"hasEquip",zcard) then
					if package_known(self,"aiUseCard",zcard).card then shouldUse = false end
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
					if package_known(self,"aiUseCard",card).card then
						will_use = true
						use_slash_num = use_slash_num+1
					end
				end
				if not will_use then table.insert(unpreferedCards,package_known(card,"getId")) end
			end
			if package_known(card,"isKindOf","Peach") then
				table.insert(unpreferedCards,package_known(card,"getId"))
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
				if not package_known(self,"aiUseCard",card).card then table.insert(unpreferedCards,package_known(card,"getId")) end
			end
		end
	end
	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not package_known(self.player,"isJilei",disclosed_card(self,unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		use.card = source_construct(self,"#sfofl_shenglv:"..table.concat(use_cards,"+")..":")
	end
end

sgs.ai_use_value.sfofl_shenglv = 9
sgs.ai_use_priority.sfofl_shenglv = 2.61
sgs.dynamic_value.benefit.sfofl_shenglv = true


function sgs.ai_cardneed.sfofl_shenglv(to,card)
	return not package_known(card,"isKindOf","Jink")
end

sgs.ai_use_revises.sfofl_shenglv = function(self,card,use)
	if package_known(card,"isKindOf","Weapon")
	and not package_known(card,"isKindOf","Crossbow")
	and package_known(self,"getSameEquip",card)
	and math.max(package_known(self.player,"usedTimes","#sfofl_shenglv") - 1, 0) < 2
	then return false end
end



sgs.ai_card_priority.sfofl_jiang = function(self,card)
	if package_known(card,"isRed")
	then return 1 end
end


ai_skill_invoke.sfofl_zhiyang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	if target and package_known(self,"isFriend",target) then return (false) or false end
	local max_card = package_call(self,"getMaxCard")
	if max_card and package_known(max_card,"getNumber") >= 10  then
		return (true) or false
	end
	return (false) or false
end

ai_skill_invoke.sfofl_cuanzun = true

sgs.ai_skill_playerchosen.sfofl_liufangc = sgs.ai_skill_playerchosen.fangzhu
sgs.ai_playerchosen_intention.sfofl_liufangc = sgs.ai_playerchosen_intention.fangzhu

sgs.ai_need_damaged.sfofl_liufangc = sgs.ai_need_damaged.fangzhu

local sfofl_liufangc_skill = {}
sfofl_liufangc_skill.name = "sfofl_liufangc"
table.insert(package_skills,sfofl_liufangc_skill)
sfofl_liufangc_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_liufangc:.:")
end

ai_card_use["#sfofl_liufangc"] = function(self, card, use, request)
	package_call(self,"sort",self.friends_noself,"handcard")
	for _,friend in ipairs(self.friends_noself)do
		if not package_known(friend,"faceUp") then
			use.card = card
			package_call(use.to,"append",friend)
			return
		end
	end
	local n = package_known(self.player,"getLostHp")
	for _,friend in ipairs(self.friends_noself)do
		if not package_known(self,"toTurnOver",friend,n,"fangzhu") then
			use.card = card
			package_call(use.to,"append",friend)
			return
		end
	end
	if n>=3 then
		local target = package_known(self,"findPlayerToDraw",false,n)
		if target then return target end
		for _,enemy in ipairs(self.enemies)do
			if package_known(self,"toTurnOver",enemy,n,"fangzhu") and hasManjuanEffect(enemy) then
				use.card = card
				package_call(use.to,"append",enemy)
				return
			end
		end
	else
		package_call(self,"sort",self.enemies)
		for _,enemy in ipairs(self.enemies)do
			if package_known(self,"toTurnOver",enemy,n,"fangzhu") and hasManjuanEffect(enemy) then
				use.card = card
				package_call(use.to,"append",enemy)
				return
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if package_known(self,"toTurnOver",enemy,n,"fangzhu") and package_known(enemy,"hasSkills",sgs.priority_skill) then
				use.card = card
				package_call(use.to,"append",enemy)
				return
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if package_known(self,"toTurnOver",enemy,n,"fangzhu") then
				use.card = card
				package_call(use.to,"append",enemy)
				return
			end
		end
	end
end

sgs.ai_use_priority.sfofl_liufangc = 1.5

sgs.ai_card_intention.sfofl_liufangc = function(self, card, from, tos)
	if hasManjuanEffect(tos[1]) then sgs.updateIntention(from,tos[1],80) end
	local intention = 80/math.max(package_known(from,"getLostHp"),1)
	if not package_known(self,"toTurnOver",tos[1],package_known(from,"getLostHp")) then intention = -intention end
	if package_known(from,"getLostHp")<3 then
		sgs.updateIntention(from,tos[1],intention)
	else
		sgs.updateIntention(from,tos[1],math.min(intention,-30))
	end
end

ai_skill_invoke.sfofl_xiongtu = true


sgs.ai_can_damagehp.sfofl_xiongtu = function(self,from,card,to)
	return package_known(to,"getHp")+package_known(self,"getAllPeachNum")-package_known(self,"ajustDamage",from,to,1,card)>0
	and package_known(self,"canLoseHp",from,card,to)
end

sgs.ai_target_revises.sfofl_xiongtu = sgs.ai_target_revises.jianxiong


ai_skill_invoke.sfofl_fuxiang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if #self.friends==1 then return (false) or false end

	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))


	local limit = package_known(self.player,"getMaxCards")
	if package_known(self.player,"isKongcheng") then return (false) or false end
	if package_known(self,"getCardsNum","Peach")>=limit-2 and package_known(self.player,"isWounded") then return (false) or false end

	local to_discard = nil

	package_call(self,"sortByKeepValue",cards)
	if sgs.playerRoles.rebel==0 then
		local lord = package_call(self.room,"getLord")
		if lord and package_known(self,"isFriend",lord) then
			return (true) or false
		end
	end

	local AssistTarget = package_call(self,"AssistTarget")
	if AssistTarget and not package_known(self,"willSkipPlayPhase",AssistTarget) then
		return (true) or false
	end

	package_call(self,"sort",self.friends_noself,"handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,target in ipairs(self.friends_noself)do
		if not package_known(target,"hasSkill","dawu") and package_known(target,"hasSkills","yongsi|zhiheng|"..sgs.priority_skill.."|shensu")
			and (not package_known(self,"willSkipPlayPhase",target) or package_known(target,"hasSkill","shensu")) then
			return (true) or false
		end
	end

	for _,target in ipairs(self.friends_noself)do
		if package_known(target,"hasSkill","dawu") then
			local use = true
			for _,p in ipairs(self.friends_noself)do
				if package_known(p,"getStrategyMark","&dawu")>0 then use = false break end
			end
			if use then
				return (true) or false
			end
		else
			return (true) or false
		end
	end
	return (false) or false
end

sgs.ai_skill_playerchosen.sfofl_fuxiang = function(self,targets)
	local lord = package_call(self.room,"getLord")
	if lord and package_known(self,"isFriend",lord) and package_known(lord,"objectName")~=package_known(self.player,"objectName") then
		return lord
	end
	local AssistTarget = package_call(self,"AssistTarget")
	if AssistTarget and not package_known(self,"willSkipPlayPhase",AssistTarget) then
		return AssistTarget
	end
	package_call(self,"sort",self.friends_noself,"chaofeng")
	for _,target in ipairs(self.friends_noself)do
		if not package_known(target,"hasSkill","dawu") and package_known(target,"hasSkills","yongsi|zhiheng|"..sgs.priority_skill.."|shensu")
			and (not package_known(self,"willSkipPlayPhase",target) or package_known(target,"hasSkill","shensu")) then
			return target
		end
	end
	for _,target in ipairs(self.friends_noself)do
		if package_known(target,"hasSkill","dawu") then
			local use = true
			for _,p in ipairs(self.friends_noself)do
				if package_known(p,"getStrategyMark","&dawu")>0 then use = false break end
			end
			if use then
				return target
			end
		else
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.sfofl_fuxiang = -80


sgs.ai_target_revises.sfofl_lezong = sgs.ai_target_revises.xiangle


sgs.ai_skill_cardask["@sfofl_lezong"] = function(self,data, pattern, target)
	local use = package_known(data,"toCardUse")
	if package_known(use.card,"isKindOf","Slash") then
		if package_known(self,"isFriend",target) and not package_known(self,"findLeijiTarget",target,50,self.player) then return "." end
		local has_peach,has_analeptic,has_slash,has_jink
		for _,card in sgs.qlist(package_known(self.player,"getHandcards"))do
			if package_known(card,"isKindOf","Peach") then has_peach = card
			elseif package_known(card,"isKindOf","Analeptic") then has_analeptic = card
			elseif package_known(card,"isKindOf","Slash") then has_slash = card
			elseif package_known(card,"isKindOf","Jink") then has_jink = card
			end
		end

		if has_slash then return package_known(has_slash,"getEffectiveId")
		elseif has_jink then return package_known(has_jink,"getEffectiveId")
		elseif has_analeptic or has_peach then
			if getCardsNum("Jink",target,self.player)==0 and package_known(self.player,"getStrategyMark","drank")>0 and package_known(self,"getAllPeachNum",target)==0 then
				if has_analeptic then return package_known(has_analeptic,"getEffectiveId")
				else return package_known(has_peach,"getEffectiveId")
				end
			end
		else return "."
		end
	else
		if not package_known(self,"isFriend",target) then
			return true
		end
	end
	return "."
end




local sfofl_renwang_skill = {}
sfofl_renwang_skill.name = "sfofl_renwang"
table.insert(package_skills,sfofl_renwang_skill)
sfofl_renwang_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self.player,"isKongcheng") then return end
	return source_construct(self,"#sfofl_renwang:.:")
end

ai_card_use["#sfofl_renwang"] = function(self, card, use, request)
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards,true)
	local notFound = false
	for i = 1,package_known(self.player,"getHandcardNum") do do
		local h,friend = package_call(self,"getCardNeedPlayer",cards)
		if h and friend then cards = package_known(self,"resetCards",cards,h)
		else notFound = true break end
		if friend==self.player or not package_known(self.player,"handCards"):contains(package_known(h,"getEffectiveId")) then goto package_continue_29 end
		local canJijiang = package_known(self.player,"hasLordSkill","jijiang") and package_known(friend,"getKingdom")=="shu"
		if package_known(h,"isAvailable",self.player)
		and (package_known(h,"isKindOf","Slash") and not canJijiang or package_known(h,"isKindOf","Duel") or package_known(h,"isKindOf","Snatch") or package_known(h,"isKindOf","Dismantlement")) then
			local dummy_use = package_known(self,"aiUseCard",h)
			if dummy_use.card then
				if package_known(h,"isKindOf","Slash") or package_known(h,"isKindOf","Duel") then
					local t1 = package_known(dummy_use.to,"first")
					if package_known(dummy_use.to,"length")>1 then goto package_continue_29
					elseif package_known(t1,"getHp")<2 or getCardsNum("Jink",t1,self.player)<1
					or package_known(t1,"isCardLimited",clone(self,"jink"),sgs.Card_MethodResponse)
					then goto package_continue_29 end
				elseif package_known(self,"getEnemyNumBySeat",self.player,friend)>0 then
					local hasDelayedTrick
					for _,p in sgs.qlist(dummy_use.to)do
						if package_known(self,"isFriend",p) and (package_known(self,"willSkipDrawPhase",p) or package_known(self,"willSkipPlayPhase",p))
						then hasDelayedTrick = true break end
					end
					if hasDelayedTrick then goto package_continue_29 end
				end
			end
		elseif package_known(h,"isAvailable",self.player)
		and (package_known(h,"isKindOf","Indulgence") or package_known(h,"isKindOf","SupplyShortage"))
		and package_known(self,"getEnemyNumBySeat",self.player,friend)>0
		and package_known(self,"aiUseCard",h).card then goto package_continue_29 end
		if #cards>1 then use.card = source_construct(self,"#sfofl_renwang:"..package_known(h,"getId").."+"..package_known(cards[1],"getId")..":")  end
		package_call(use.to,"append",friend)
		return
	end ::package_continue_29:: end
	if notFound and package_known(self.player,"isWounded") and package_known(self,"getOverflow")>0 then
		cards = package_call(self,"sortByUseValue",package_known(self.player,"getHandcards"),true)
		for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player))do
			if not package_known(self,"isFriend",p) and hasManjuanEffect(p) then
				local to_give = {}
				for _,h in ipairs(cards)do
					if not isCard("Peach,ExNihilo",h,self.player)
					then table.insert(to_give,package_known(h,"getId")) end
					if #to_give>=2
					then break end
				end
				if #to_give==2 then
					use.card = source_construct(self,"#sfofl_renwang:"..table.concat(to_give,"+")..":")
					package_call(use.to,"append",p)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.sfofl_renwang = sgs.ai_use_value.RendeCard
sgs.ai_use_priority.sfofl_renwang = sgs.ai_use_priority.RendeCard

sgs.ai_card_intention.sfofl_renwang = sgs.ai_card_intention.RendeCard

sgs.dynamic_value.benefit.sfofl_renwang = true

sgs.ai_use_revises.sfofl_renwang = function(self,card,use)
	if package_known(self.player,"getLostHp")>1 and package_known(self,"findFriendsByType",sgs.Friend_Draw)
	and #self.friends_noself>0
	then
		if package_known(card,"getTypeId")==1
		or package_known(card,"getTypeId")==3 and package_known(self,"getSameEquip",card)
		or package_known(card,"getTypeId")==2 and not (package_known(card,"targetFixed") and package_known(card,"isDamageCard"))
		then return false end
	end
	local xy = package_known(self,"hasSkills","jieming|oljieming",self.friends_noself)
	if xy and package_known(card,"isDamageCard") and package_known(self,"getOverflow")<0
	and package_known(self,"hasTrickEffective",card,xy,nil,use.to)
	and package_known(self,"getAllPeachNum")>1
	then
		use.card = card
		package_call(use.to,"append",xy)
	end
end


sgs.ai_skill_playerchosen.yingzhen = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) then
			return p
		end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isEnemy",p) then
			return p
		end
	end
end


ai_skill_invoke.yuanjue = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (package_known(self,"getOverflow")>0) or false
end

ai_skill_invoke.aoyong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (package_known(self,"canDraw") or package_known(self.player,"isWounded")) or false
end

ai_skill_choice.aoyong = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	if table.contains(items,"aoyong2") and package_known(self,"isWeak") then
		return ai_choice_result(("aoyong2"), options)
	end
	if table.contains(items,"aoyong3") then
		for _,c in sgs.list(package_known(self.player,"getHandcards"))do
			if package_known(self,"aiUseCard",c) then
				return ai_choice_result(("aoyong3"), options)
			end
		end
	end
	if table.contains(items,"aoyong2") then
		return ai_choice_result(("aoyong2"), options)
	end
	if table.contains(items,"aoyong1") then
		return ai_choice_result(("aoyong1"), options)
	end

    return ai_choice_result(nil, options)
end

ai_skill_invoke.tongkai = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local to = package_call(data,"toPlayer")
	return (not package_known(self,"isEnemy",to)) or false
end


ai_fill_skill.jiechu = function(self, options, request)
    local inclusive = options and options.inclusive

	return clone(self,"snatch","jiechu")
end

sgs.ai_skill_cardask["jiechu1"] = function(self,data)
	local use = package_known(data,"toCardUse")
	if package_known(self.player,"getStrategyMark",package_known(use.card,"getSuitString").."daojueSuit")<1 then return "." end
    local cards = package_known(self.player,"getCards","h")
    cards = sgs.QList2Table(cards)
    package_call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do
		return package_known(dc,"toString")
	end
    return "."
end



ai_skill_invoke.tuonan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (package_known(self,"getCardsNum","Peach,Analeptic")+package_known(self.player,"getHp")<1) or false
end






local sfofl_zunwei_skill = {}
sfofl_zunwei_skill.name = "sfofl_zunwei"
table.insert(package_skills,sfofl_zunwei_skill)
sfofl_zunwei_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_zunwei:.:")
end

ai_card_use["#sfofl_zunwei"] = function(self, card, use, request)
	local recover_t,draw_t,equip_t = {},{},{}
	if package_known(self.player,"getStrategyMark","sfofl_zunwei_handcard") == 0 and package_known(self,"canDraw") then
		for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player))do
			if package_known(p,"getHandcardNum")>package_known(self.player,"getHandcardNum") then
				table.insert(draw_t,p)
			end
		end
	end
	if package_known(self.player,"getStrategyMark","sfofl_zunwei_hp") == 0 and package_known(self.player,"getLostHp")>0 then
		for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player))do
			if package_known(p,"getHp")>package_known(self.player,"getHp") then
				table.insert(recover_t,p)
			end
		end
	end
	if package_known(self.player,"getStrategyMark","sfofl_zunwei_equip") == 0 and package_known(self.player,"hasEquipArea") then
		for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player))do
			if package_known(p,"getEquips"):length()>package_known(self.player,"getEquips"):length() then
				table.insert(equip_t,p)
			end
		end
	end
	if #recover_t==0 and #draw_t==0 and #equip_t==0 then return end

	if #recover_t>0 then package_call(self,"sort",recover_t,"hp") recover_t = sgs.reverse(recover_t) end
	if #draw_t>0 then package_call(self,"sort",draw_t,"handcard") draw_t = sgs.reverse(draw_t) end
	if #equip_t>0 then package_call(self,"sort",equip_t,"equip") equip_t = sgs.reverse(equip_t) end

	if package_known(self,"isWeak") then
		if #recover_t>0 then
			package_call(self,"setPriorityValue","sfofl_zunwei", 10,"sfoflCard.source")
			source_state(self).sfofl_zunwei = "recover"
			use.card = card
			package_call(use.to,"append",recover_t[1])
			return
		end

		if #draw_t>0 then
			source_state(self).sfofl_zunwei = "draw"
			use.card = card
			package_call(use.to,"append",draw_t[1])
			return
		end

		if #equip_t>0 then
			source_state(self).sfofl_zunwei = "equip"
			use.card = card
			package_call(use.to,"append",equip_t[1])
			return
		end
	end

	if #recover_t>0 and package_known(recover_t[1],"getHp")-package_known(self.player,"getHp")>=2 and package_known(self.player,"getLostHp")>=2 then
		source_state(self).sfofl_zunwei = "recover"
		use.card = card
		package_call(use.to,"append",recover_t[1])
		return
	end

	if #draw_t>0 and ((package_known(draw_t[1],"getHandcardNum")-package_known(self.player,"getHandcardNum")>=2 and package_known(self,"slashIsAvailable",self.player)) or
	package_known(draw_t[1],"getHandcardNum")-package_known(self.player,"getHandcardNum")>=4) then
		source_state(self).sfofl_zunwei = "draw"
		use.card = card
		package_call(use.to,"append",draw_t[1])
		return
	end

	if #equip_t>0 and package_known(equip_t[1],"getEquips"):length()-package_known(self.player,"getEquips"):length()>=2 then
		source_state(self).sfofl_zunwei = "equip"
		use.card = card
		package_call(use.to,"append",equip_t[1])
		return
	end
end

sgs.ai_use_priority.sfofl_zunwei = 0


ai_skill_choice.sfofl_zunwei = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local hp = getChoice(choices, "hp")
	local equip = getChoice(choices, "equip")
	local handcard = getChoice(choices, "handcard")
	local items = package_known(choices,"split","+")
	if source_state(self).sfofl_zunwei then
		if source_state(self).sfofl_zunwei == "recover" and hp then
			return ai_choice_result((hp), options)
		end
		if source_state(self).sfofl_zunwei == "draw" and handcard then
			return ai_choice_result((handcard), options)
		end
		if source_state(self).sfofl_zunwei == "equip" and equip then
			return ai_choice_result((equip), options)
		end
	end
    return ai_choice_result((items[math.random(1,#items)]), options)
end




local sfofl_chongxu_skill = {}
sfofl_chongxu_skill.name = "sfofl_chongxu"
table.insert(package_skills,sfofl_chongxu_skill)
sfofl_chongxu_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_chongxu:.:")
end

ai_card_use["#sfofl_chongxu"] = function(self, card, use, request)
	use.card = card
	return
end
sgs.ai_use_priority["sfofl_chongxu"] = 10


local sfofl_miaojing={}
sfofl_miaojing.name="sfofl_miaojing"
table.insert(package_skills,sfofl_miaojing)


sfofl_miaojing.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not package_known(self.player,"hasUsed","#sfofl_miaojing") then
		local player = self.player
		local slash_card ={}
		local ex_card={}
		local cards = package_known(self,"addHandPile","he")
		cards = package_call(self,"sortByUseValue",cards,true)

		local level = package_known(player,"getStrategyMark","sfofl_chongxu_sfofl_miaojing")

		if level ~= 2 then
			for _,card in ipairs(cards)do
				if package_known(card,"isKindOf","Slash") then
					table.insert(slash_card,card)
				else
					if level == 0 then
						if package_known(card,"isNDTrick") then
							table.insert(ex_card,card)
						end
					else
						if not package_known(card,"isKindOf","BasicCard") then
							table.insert(ex_card,card)
						end
					end
				end
			end
			local miaojingpatterns = { "yj_stabs_slash", "ex_nihilo"}

			if level == 1 then

				if #ex_card > 0 then
					ex_card = package_call(self,"sortByUseValue",ex_card, true)
					for c, pn in sgs.list(RandomList(miaojingpatterns)) do
						c = clone(self,pn)
						package_call(c,"setSkillName","sfofl_miaojing")
						local dummy_use = package_known(self,"aiUseCard",c)
						if package_known(c,"isAvailable",self.player) and dummy_use.card and dummy_use.to then
							source_state(self).sfofl_miaojing_to = dummy_use.to
							for _,card in ipairs(ex_card) do
								if not package_known(self,"isValuableCard",card, self.player) then
									return source_construct(self,"#sfofl_miaojing:"..package_known(card,"getEffectiveId")..":")
								end
							end
							package_call(self,"setPriorityValue","sfofl_miaojing", sgs.ai_use_priority.ExNihilo,"sfoflCard.source")
							return source_construct(self,"#sfofl_miaojing:"..package_known(ex_card[1],"getEffectiveId")..":")
						end
					end
				end
			else
				if #ex_card > 0 then
					for c, pn in sgs.list(RandomList(miaojingpatterns)) do
						c = clone(self,pn)
						package_call(c,"setSkillName","sfofl_miaojing")
						local dummy_use = package_known(self,"aiUseCard",c)
						if package_known(c,"isAvailable",self.player) and dummy_use.card and dummy_use.to then
							source_state(self).sfofl_miaojing_to = dummy_use.to
							ex_card = package_call(self,"sortByUseValue",ex_card, true)
							package_call(self,"setPriorityValue","sfofl_miaojing", sgs.ai_use_priority.ExNihilo,"sfoflCard.source")
							return source_construct(self,"#sfofl_miaojing:"..package_known(ex_card[1],"getEffectiveId")..":")
						end
					end
				end
			end

			if #slash_card > 0 then
				for c, pn in sgs.list(RandomList(miaojingpatterns)) do
					c = clone(self,pn)
					package_call(c,"setSkillName","sfofl_miaojing")
					local dummy_use = package_known(self,"aiUseCard",c)
					if package_known(c,"isAvailable",self.player) and dummy_use.card and dummy_use.to then
						source_state(self).sfofl_miaojing_to = dummy_use.to
						slash_card = package_call(self,"sortByUseValue",slash_card, true)
						package_call(self,"setPriorityValue","sfofl_miaojing", 3,"sfoflCard.source")
						return source_construct(self,"#sfofl_miaojing:"..package_known(slash_card[1],"getEffectiveId")..":")
					end
				end
			end

		else
			local miaojingpatterns = { "yj_stabs_slash", "ex_nihilo"}
			for c, pn in sgs.list(RandomList(miaojingpatterns)) do
        		c = clone(self,pn)
				package_call(c,"setSkillName","sfofl_miaojing")
				package_call(self,"setPriorityValue","sfofl_miaojing", sgs.ai_use_priority[package_known(c,"getClassName")],"sfoflCard.source")
				return c
			end
		end
	end
end

ai_card_use["#sfofl_miaojing"] = function(self, card, use, request)
	local player = self.player
	local level = package_known(player,"getStrategyMark","sfofl_chongxu_sfofl_miaojing")
	local userstring = package_known(card,"toString")
	local room = self.room

	if level ~= 2 then
		local id = package_known(userstring,"split",":")[3]
		local kind = disclosed_card(self,id)

		if package_known(kind,"isKindOf","Slash") then
			use.card = card
			use.to = source_state(self).sfofl_miaojing_to
			return
		else
			use.card = card
			package_call(use.to,"append",player)
		end
	end
	return
end

sgs.ai_use_value.sfofl_miaojing = 7
sgs.ai_use_priority.sfofl_miaojing = 4



sgs.ai_target_revises.sfofl_lianhua = function(to,card,self,use)
	if package_known(card,"isKindOf","Slash") and package_known(to,"getStrategyMark","sfofl_chongxu_sfofl_lianhua") == 2
	and package_known(self.player,"getHandcardNum")-package_known(self,"getCardsNum","Peach")<2
	then return true end
end

sgs.ai_skill_cardask["@sfofl_lianhua"] = function(self,data, pattern, target)
	local use = package_known(data,"toCardUse")
	if package_known(self,"isFriend",target) and not package_known(self,"findLeijiTarget",target,50,self.player) then return "." end
	local has_peach,has_analeptic,has_slash,has_jink
	for _,card in sgs.qlist(package_known(self.player,"getHandcards"))do
		if package_known(card,"isKindOf","Peach") then has_peach = card
		elseif package_known(card,"isKindOf","Analeptic") then has_analeptic = card
		elseif package_known(card,"isKindOf","Slash") then has_slash = card
		elseif package_known(card,"isKindOf","Jink") then has_jink = card
		end
	end

	if has_slash then return package_known(has_slash,"getEffectiveId")
	elseif has_jink then return package_known(has_jink,"getEffectiveId")
	elseif has_analeptic or has_peach then
		if getCardsNum("Jink",target,self.player)==0 and package_known(self.player,"getStrategyMark","drank")>0 and package_known(self,"getAllPeachNum",target)==0 then
			if has_analeptic then return package_known(has_analeptic,"getEffectiveId")
			else return package_known(has_peach,"getEffectiveId")
			end
		end
	else
		for _,card in sgs.qlist(package_known(self.player,"getHandcards"))do
			if not package_known(card,"isKindOf","BasicCard") then
				return package_known(card,"getEffectiveId")
			end
		end
	end
	return "."
end

local sfofl_kannan_skill = {}
sfofl_kannan_skill.name = "sfofl_kannan"
table.insert(package_skills,sfofl_kannan_skill)
sfofl_kannan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_kannan:.:")
end

ai_card_use["#sfofl_kannan"] = function(self, card, use, request)
	local cards = sgs.CardList()
	local peach = 0
	for _,c in sgs.qlist(package_known(self.player,"getHandcards"))do
		if isCard("Peach",c,self.player) and peach<2 then
			peach = peach+1
		else
			package_call(cards,"append",c)
		end
	end

	local min_card = package_call(self,"getMinCard",self.player,cards)
	if min_card then
		local min_point = package_known(min_card,"getNumber")
		if package_known(self.player,"hasSkill","tianbian") and package_known(min_card,"getSuit")==sgs.Card_Heart then min_point = 13 end
		if min_point<7 then
			package_call(self,"sort",self.enemies,"handcard")
			for _,p in ipairs(self.enemies)do do
				if package_known(p,"getStrategyMark","sfofl_kannan"..package_known(self.player,"objectName").."-PlayClear")>0 or not package_known(self.player,"canPindian",p) then goto package_continue_30 end
				source_state(self).sfofl_kannan_card = min_card
				use.card = source_construct(self,"#sfofl_kannan:.:")
				package_call(use.to,"append",p)
				return
			end ::package_continue_30:: end
		end
	end

	local max_card = package_call(self,"getMaxCard",self.player,cards)
	if max_card then
		local max_point = package_known(max_card,"getNumber")
		if package_known(self.player,"hasSkill","tianbian") and package_known(max_card,"getSuit")==sgs.Card_Heart then max_point = 13 end
		if max_point>=7 then
			package_call(self,"sort",self.enemies,"handcard")
			for _,p in ipairs(self.enemies)do do
				if package_known(p,"getStrategyMark","sfofl_kannan"..package_known(self.player,"objectName").."-PlayClear")>0 or not package_known(self.player,"canPindian",p) or not package_known(self,"doDisCard",p,"h",true) then goto package_continue_31 end
				source_state(self).sfofl_kannan_card = max_card
				use.card = source_construct(self,"#sfofl_kannan:.:")
				package_call(use.to,"append",p)
				return
			end ::package_continue_31:: end
		end
		local slashcount = package_known(self,"getCardsNum","Slash")
		package_call(self,"sortByUseValue",cards, true)
		if slashcount > 0 and package_known(self.player,"getStrategyMark","drank") == 0 then
			package_call(self,"sort",self.friends_noself,"handcard")
			self.friends_noself = sgs.reverse(self.friends_noself)
			for _,p in ipairs(self.friends_noself)do do
				if package_known(p,"getStrategyMark","sfofl_kannan"..package_known(self.player,"objectName").."-PlayClear")>0 or not package_known(self.player,"canPindian",p) then goto package_continue_32 end
				source_state(self).sfofl_kannan_card = max_card
				use.card = source_construct(self,"#sfofl_kannan:.:")
				package_call(use.to,"append",p)
				return
			end ::package_continue_32:: end
		end
	end
end

sgs.ai_use_priority.sfofl_kannan = 7
sgs.ai_use_value.sfofl_kannan = 7

function sgs.ai_skill_pindian.sfofl_kannan(minusecard,self,requestor)
	return package_known(self,"isFriend",requestor) and package_call(self,"getMaxCard") or ( package_call(self,"getMinCard"):getNumber()>6 and  minusecard or package_call(self,"getMinCard") )
end

sgs.ai_ajustdamage_from.sfofl_kannan = function(self, from, to, card, nature)
    if package_known(to,"getStrategyMark","sfofl_kannanAnaleptic-Clear") > 0
    then
        return 1
    end
end

ai_skill_choice.sfofl_kannan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local up = getChoice(choices, "up")
	local down = getChoice(choices, "down")
	local items = package_known(choices,"split","+")
	local pindian = package_known(data,"toPindian")
	local target
	if pindian.from==self.player then
		target = pindian.to
	elseif pindian.to==self.player then
		target = pindian.from
	end
	if package_known(self.player,"getPhase") ~= sgs.Player_Play then
		if package_known(self,"isFriend",target) then
			return ai_choice_result((down), options)
		end
		return ai_choice_result((up), options)
	end
	if pindian.reason == "sfofl_kannan" then
		if package_known(self,"isFriend",target) then
			return ai_choice_result((up), options)
		end
		if math.random() < 0.5 then
			return ai_choice_result((down), options)
		end

		return ai_choice_result((up), options)
	end
    return ai_choice_result(("cancel"), options)
end


local sfofl_jianji_skill = {}
sfofl_jianji_skill.name = "sfofl_jianji"
table.insert(package_skills,sfofl_jianji_skill)
sfofl_jianji_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.friends_noself>0 then
		return source_construct(self,"#sfofl_jianji:.:")
	end
end

ai_card_use["#sfofl_jianji"] = function(self, card, use, request)
	package_call(self,"sort",self.friends_noself,"handcard")
	for _,friend in ipairs(self.friends_noself)do
		if package_known(self,"canDraw",friend) then
			use.card = card
			package_call(use.to,"append",friend)
			return
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if not hasManjuanEffect(friend) then
			use.card = card
			package_call(use.to,"append",friend)
			return
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if not hasManjuanEffect(friend,true) then
			use.card = card
			package_call(use.to,"append",friend)
			return
		end
	end
end

sgs.ai_use_priority.sfofl_jianji = 7
sgs.ai_use_value.sfofl_jianji = 7
sgs.ai_card_intention.sfofl_jianji = -20


sgs.ai_skill_playerchosen.sfofl_jianji = function(self, targets)
	local card
	for _, c in sgs.qlist(package_known(self.player,"getHandcards")) do
		if package_known(c,"hasFlag","sfofl_jianji") then
			card = c
			break
		end
	end
	if card then
		local use_card = clone_native(self,"slash", sgs.Card_NoSuit, 0)
		package_call(use_card,"setSkillName","sfofl_jianji")
		package_call(use_card,"addSubcard",card)
		package_call(use_card,"deleteLater")
		local dummy_use = package_known(self,"aiUseCard",use_card)
		if dummy_use.card then
			for _, p in sgs.qlist(targets) do
				if package_known(dummy_use.to,"contains",p) then
					return p
				end
			end
		end
	end
	return nil
end


sgs.ai_skill_discard.sfofl_fengpo = function(self)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getSuit") == sgs.Card_Diamond then
        	table.insert(to_discard, package_known(card,"getEffectiveId"))
        end
	end
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end
ai_skill_choice.sfofl_fengpo = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local use = package_known(data,"toCardUse")
	local draw = getChoice(choices, "sfofl_fengpo1")
	local damage = getChoice(choices, "sfofl_fengpo2")
	local target = package_known(use.to,"first")
	if package_known(self,"isEnemy",target) then
		if package_known(self,"ajustDamage",use.from,target,1,use.card)>0 and not package_known(self,"cantDamageMore",use.from, target) and not package_known(self,"cantbeHurt",target) and package_known(self,"canDamage",target,self.player,use.card) and package_known(self,"canHit",target,use.from,true) then
			return ai_choice_result((damage), options)
		end
	end
	return ai_choice_result((draw), options)
end
sgs.ai_ajustdamage_from.sfofl_fengpo = function(self, from, to, card, nature)
    if card and foreign_fact(self,card,"sfofl_fengpo","toInt") > 0
    then
        return foreign_fact(self,card,"sfofl_fengpo","toInt")
    end
end

local sfofl_duliang_skill = {}
sfofl_duliang_skill.name = "sfofl_duliang"
table.insert(package_skills,sfofl_duliang_skill)
sfofl_duliang_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_duliang:.:")
end

ai_card_use["#sfofl_duliang"] = function(self, card, use, request)
	local friends,enemies,others = {},{},{}
	for _,player in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player))do
		if not package_known(player,"isKongcheng") and package_known(self,"isFriend",player) then
			table.insert(friends,player)
		elseif package_known(self,"isEnemy",player) and package_known(self,"doDisCard",player,"h") then
			table.insert(enemies,player)
		elseif not package_known(player,"isKongcheng") then
			table.insert(others,player)
		end
	end

	if #friends==0 and #enemies==0 and #others==0 then return end
	local target
	package_call(self,"sort",friends,"handcard")
	friends = sgs.reverse(friends)

	for _,friend in ipairs(friends)do
		if package_known(self,"needToThrowCard",friend,"h") or package_known(friend,"hasSkill","tuxi") then
			target = friend
			break
		end
	end

	if not target then
		package_call(self,"sort",enemies,"defense")
		for _,enemy in ipairs(enemies)do
			if hasManjuanEffect(enemy) then
				target = enemy
				break
			end
		end
	end

	if not target then
		for _,enemy in ipairs(enemies)do
			if package_known(enemy,"hasSkills",sgs.dont_kongcheng_skill) then
				target = enemy
				break
			end
		end
	end

	for _,enemy in ipairs(enemies)do
		if package_known(enemy,"hasSkills",sgs.notActive_cardneed_skill) or package_known(self,"isWeak",enemy) then
			target = enemy
			break
		end
	end

	if not target then
		for _,enemy in ipairs(enemies)do
			target = enemy
			break
		end
	end

	if not target then
		for _,other in ipairs(others)do
			target = other
			break
		end
	end

	if not target then
		for _,friend in ipairs(friends)do
			target = friend
			break
		end
	end
	if not target then return end
	use.card = source_construct(self,"#sfofl_duliang:.:")
	package_call(use.to,"append",target)
end

sgs.ai_use_priority.sfofl_duliang = 7

sgs.ai_skill_playerchosen.sfofl_zhuitao = sgs.ai_skill_playerchosen.zhuitao


ai_skill_invoke.sfofl_xingshang = ai_skill_invoke.mobilexingshang

ai_skill_invoke.sfofl_xingshanglord = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if ai_skill_choice.mobilexingshang(self,{reason="mobilexingshang",choices={"get","recover"},inquiry_scope="nested"},request) == "recover" then return (true) or false end
	return (false) or false
end

sgs.ai_skill_playerchosen.sfofl_fangzhu = function(self,targets)
	return sgs.ai_skill_playerchosen.fangzhu(self,targets)
end

sgs.ai_skill_discard.sfofl_fangzhu = function(self,discard_num,min_num,optional,include_equip)
	if not package_known(self.player,"faceUp") or package_known(self,"needBear") then return {} end
	if package_known(self.player,"getCardCount")-discard_num<=2 and package_known(self.player,"getHp")<=2 then return {} end
	if (package_known(self.player,"getHp")>1 or hasBuquEffect(self.player) or package_known(self,"getSaveNum",true)>0) and discard_num <= 2 and math.random() < 0.8 then
		return package_known(self,"askForDiscard","dummy",discard_num,min_num,false,include_equip)
	end
	return {}
end

sgs.ai_playerchosen_intention.sfofl_fangzhu = function(self,from,to)
	return sgs.ai_playerchosen_intention.fangzhu(self,from,to)
end

sgs.ai_can_damagehp.sfofl_shengshen = function(self,from,card,to)
	return package_known(to,"getHp")+package_known(self,"getAllPeachNum")-package_known(self,"ajustDamage",from,to,1,card)>0
	and package_known(self,"canLoseHp",from,card,to) and package_known(to,"getStrategyMark","&ny_10th_xingshen") < 6
end

sgs.ai_need_damaged.sfofl_fangzhu = function (self,attacker,player)
	if not package_known(player,"hasSkill","sfofl_fangzhu") then return false end
	local enemies = package_known(self,"getEnemies",player)
	if #enemies<1 then return false end
	package_call(self,"sort",enemies,"defense")
	for _,enemy in ipairs(enemies)do
		if package_known(player,"getLostHp")<1 and package_known(self,"toTurnOver",enemy,package_known(player,"getLostHp")+1) then
			return true
		end
	end
	local friends = package_known(self,"getFriends",player,true)
	package_call(self,"sort",friends,"defense")
	for _,friend in ipairs(friends)do
		if not package_known(self,"toTurnOver",friend,package_known(player,"getLostHp")+1) then return true end
	end
	return false
end


package_add("sfofl_zhuren").getTurnUseCard = function(self,inclusive,request)
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	package_call(self,"sortByKeepValue",cards)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if package_known(c,"getNumber")>6 and package_call(self.player,"getWeapon")==nil
		then return source_construct(self,"#sfofl_zhuren:"..package_known(c,"getEffectiveId")..":") end
	end
  	for _,c in sgs.list(cards)do
		if package_known(c,"getNumber")<6
		and package_known(self,"getCardsNum","Slash")<1
		and package_known(self,"slashIsAvailable",self.player)
		then return source_construct(self,"#sfofl_zhuren:"..package_known(c,"getEffectiveId")..":") end
	end
end

ai_card_use["#sfofl_zhuren"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.sfofl_zhuren = 9.4
sgs.ai_use_priority.sfofl_zhuren = 4.8


sgs.ai_skill_cardask["@sfofl_xiying"] = function(self,data,pattern,prompt)
    if #self.enemies>0
	and package_known(self.player,"getHandcardNum")>3
	then return true end
	return "."
end



local sfofl_miewu = {}
sfofl_miewu.name = "sfofl_miewu"
table.insert(package_skills,sfofl_miewu)
sfofl_miewu.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

    for _,name in sgs.list(patterns_for(self))do do
        local card = clone(self,name)
        if card and package_known(card,"isAvailable",self.player)
       	and package_known(card,"isDamageCard") and (package_known(card,"isKindOf","BasicCard") or package_known(card,"isNDTrick")) then
			if package_known(self,"getCardsNum",package_known(card,"getClassName"))>1 and #cards>1 then goto package_continue_33 end
            package_call(card,"setSkillName","sfofl_miewu")
         	local dummy = package_known(self,"aiUseCard",card)
			if dummy.card
			then
				source_state(self).Miewudummy = dummy
				return source_construct(self,"#sfofl_miewu:.:"..name)
			end
		end
	end ::package_continue_33:: end
    for _,name in sgs.list(patterns_for(self))do do
        local card = clone(self,name)
        if card and package_known(card,"isAvailable",self.player) then
			if package_known(self,"getCardsNum",package_known(card,"getClassName"))>1 then goto package_continue_34 end
			if (package_known(card,"isKindOf","BasicCard") or package_known(card,"isNDTrick")) then
				package_call(card,"setSkillName","sfofl_miewu")
				local dummy = package_known(self,"aiUseCard",card)
				if dummy.card then
					source_state(self).Miewudummy = dummy
					if package_known(card,"canRecast") and package_known(dummy.to,"length")<1 then goto package_continue_34 end
					return source_construct(self,"#sfofl_miewu:.:"..name)
				end
			end
		end
	end ::package_continue_34:: end
end

ai_card_use["#sfofl_miewu"] = function(self, card, use, request)
	use.card = card
	use.to = source_state(self).Miewudummy.to
end

sgs.ai_guhuo_card.sfofl_miewu = function(self,toname,class_name)
	if package_known(self.player,"getStrategyMark","sfofl_miewu-Clear")>0 then return end
	if package_known(self.player,"getStrategyMark","&mobilezhiwuku") < 1  then return end
	if package_known(self,"getCardsNum",class_name)>0 then return end
	local dc = clone(self,toname)
	if (not dc) then return end
	if package_known(dc,"isKindOf","BasicCard") or package_known(dc,"isNDTrick") then
   		return "#sfofl_miewu:.:"..toname
	end
	return
end

sgs.ai_use_revises.sfofl_miewu = function(self,card,use)
	if package_known(card,"isKindOf","EquipCard")
	and package_known(self.player,"getStrategyMark","&mobilezhiwuku")>2
	and package_known(self.player,"getStrategyMark","sfofl_miewu-Clear")<1
	then return false end
end

ai_skill_invoke.sfofl_luoyi = ai_skill_invoke.luoyi

sgs.ai_ajustdamage_from["&sfofl_luoyi"] = function(self,from,to,card,nature)
	if card and (package_known(card,"isKindOf","Duel") or package_known(card,"isKindOf","Slash"))
	then return 1 end
end



local sfofl_rengong = {}
sfofl_rengong.name = "sfofl_rengong"
table.insert(package_skills,sfofl_rengong)
sfofl_rengong.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	for _, card in ipairs(cards) do
		if package_known(self,"getUseValue",card) < sgs.ai_use_value.Dismantlement or package_known(self,"getOverflow") > 0 then
			if not package_known(self,"isWeak") then
				local same = false
				for _, id in sgs.qlist(package_known(self.player,"getPile","sfofl_huangjin")) do
					local c = disclosed_card(self,id)
					if package_known(card,"getNumber") == package_known(c,"getNumber") then
						same = true
						break
					end
				end
				if not same then
					return source_construct(self,"#sfofl_rengong:"..package_known(card,"getId")..":")
				end
			else
				return source_construct(self,"#sfofl_rengong:"..package_known(card,"getId")..":")
			end
		end
	end
end

ai_card_use["#sfofl_rengong"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_skill_playerchosen.sfofl_rengong = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if package_known(self,"doDisCard",target, "he")  then
            return target
        end
    end
    return nil
end

sgs.ai_canNiepan_skill.sfofl_guiji = function(player)
	return true
end


sgs.ai_skill_playerchosen.sfofl_chedian = function(self,targets)
	return package_known(self,"findPlayerToDamage",1,self.player,"T",targets)[1]
end

package_add("sfofl_tiangong").getTurnUseCard = function(self,inclusive,request)
	local cs = {}
	for _,id in sgs.list(package_known(self.player,"getPile","sfofl_huangjin"))do
		table.insert(cs,disclosed_card(self,id))
	end
	return cs
end

function sgs.ai_cardsview.sfofl_tiangong(self,class_name,player)
	for _,id in sgs.list(package_known(player,"getPile","sfofl_huangjin"))do
		if disclosed_card(self,id):isKindOf(class_name)
		then return id end
	end
end
sgs.ai_use_priority.sfofl_tiangong = 5

sgs.ai_target_revises.sfofl_mingshi = function(to,card)
	if package_known(card,"isKindOf","NatureSlash") and package_call(to,"getArmor") == nil
	then return true end
end

sgs.ai_skill_playerschosen.sfofl_fubo = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if package_known(self,"isFriend",target) then
            package_call(selected,"append",target)
        end
    end
    return selected
end

local sfofl_n_linzhen_skill={}
sfofl_n_linzhen_skill.name="sfofl_n_linzhen"
table.insert(package_skills,sfofl_n_linzhen_skill)
sfofl_n_linzhen_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive


	package_call(self,"setPriorityValue","sfofl_n_linzhen", 6.8,"sfoflCard.source")
	local losthp = isLord(self.player) and 0 or 1
	if ((package_known(self.player,"getHp")>3 and package_known(self.player,"getLostHp")<=losthp and package_known(self.player,"getHandcardNum")>package_known(self.player,"getHp"))
		or (package_known(self.player,"getHp")-package_known(self.player,"getHandcardNum")>=2)) and not (isLord(self.player) and turn_count(self)<=1) then
		return source_construct(self,"#sfofl_n_linzhen:.:")
	end
	local slash = clone(self)
	if package_call(self.player,"getWeapon") and package_call(self.player,"getWeapon"):isKindOf("Crossbow")
	or package_known(self.player,"hasSkill","paoxiao") then
		for _,enemy in ipairs(self.enemies)do
			if package_known(self.player,"canSlash",enemy,slash,true) and package_known(self,"slashIsEffective",slash,enemy)
				and not (package_known(enemy,"hasSkill","kongcheng") and package_known(enemy,"isKongcheng"))
				and not (package_known(enemy,"hasSkills","fankui|guixin") and not package_known(self.player,"hasSkill","paoxiao"))
				and not package_known(enemy,"hasSkills","fenyong|jilei|zhichi")
				and package_known(self,"isGoodTarget",enemy,self.enemies,slash) and not package_known(self,"slashProhibit",slash,enemy) and package_known(self.player,"getHp")>1 then
				return source_construct(self,"#sfofl_n_linzhen:.:")
			end
		end
	end
	if package_known(self.player,"getHp")==1 and package_known(self,"getCardsNum","Analeptic")>=1 then
		return source_construct(self,"#sfofl_n_linzhen:.:")
	end


	local nextplayer = package_known(self.player,"getNextAlive")
	if package_known(self.player,"getHp")==1 and package_known(self.player,"getRole")~="lord" and package_known(self.player,"getRole")~="renegade" then
		local to_death = false
		if package_known(self,"isFriend",nextplayer) then
			for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player))do
				if package_known(p,"hasSkill","xiaoguo") and not package_known(self,"isFriend",p) and not package_known(p,"isKongcheng")
					and self.role=="rebel" and package_known(self.player,"getEquips"):isEmpty() then
					to_death = true
					break
				end
			end
			if not to_death and not package_known(self,"willSkipPlayPhase",nextplayer) then
				if package_known(nextplayer,"hasSkill","jieyin") and package_known(self.player,"isMale") then return end
				if package_known(nextplayer,"hasSkill","qingnang") then return end
			end
		end
		if package_known(self.player,"getRole")=="rebel" and not package_known(self,"isFriend",nextplayer) then
			if not package_known(self,"willSkipPlayPhase",nextplayer) or package_known(nextplayer,"hasSkill","shensu") then
				to_death = true
			end
		end
		local lord = package_call(self,"getSourceLord",self.player)
		if package_known(self.player,"getRole")=="loyalist" then
			if lord and package_known(lord,"getCards","he"):isEmpty() then return end
			if package_known(self,"isEnemy",nextplayer) and not package_known(self,"willSkipPlayPhase",nextplayer) then
				if package_known(nextplayer,"hasSkills","noslijian|lijian") and package_known(self.player,"isMale") and lord and package_known(lord,"isMale") then
					to_death = true
				elseif package_known(nextplayer,"hasSkill","quhu") and lord and package_known(lord,"getHp")>package_known(nextplayer,"getHp") and not package_known(lord,"isKongcheng")
					and package_known(lord,"inMyAttackRange",self.player) then
					to_death = true
				end
			end
		end
		if to_death then
			local caopi = package_call(self.room,"findPlayerBySkillName","xingshang")
			if caopi and package_known(self,"isEnemy",caopi) then
				if package_known(self.player,"getRole")=="rebel" and package_known(self.player,"getHandcardNum")>3 then to_death = false end
				if package_known(self.player,"getRole")=="loyalist" and lord and package_known(lord,"getCardCount",true)+2<=package_known(self.player,"getHandcardNum") then
					to_death = false
				end
			end
			if #self.friends==1 and #self.enemies==1 and package_known(self.player,"aliveCount")==2 then to_death = false end
		end
		if to_death then
			package_call(self,"setPriorityValue","sfofl_n_linzhen", 0,"sfoflCard.source")
			return source_construct(self,"#sfofl_n_linzhen:.:")
		end
	end
end

ai_card_use["#sfofl_n_linzhen"]=function(self, card, use, request)
	use.card=card
end

sgs.ai_use_priority.sfofl_n_linzhen = 6.8


local sfofl_nujian_skill={}
sfofl_nujian_skill.name="sfofl_nujian"
table.insert(package_skills,sfofl_nujian_skill)
sfofl_nujian_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	for _, card in ipairs(cards) do
		if package_known(card,"isKindOf","EquipCard") then
			return source_construct(self,"#sfofl_nujian:"..package_known(card,"getEffectiveId")..":")
		end
	end
end

ai_card_use["#sfofl_nujian"]=function(self, card, use, request)
	use.card=card
end

sgs.ai_skill_playerchosen.sfofl_nujian = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if package_known(self,"isFriend",target)  then
            return target
        end
    end
    return targets[1]
end

sgs.ai_cardsview["sfofl_nujianAttach"] = function(self,class_name,player)
	if class_name=="Slash" then
		for _, p in sgs.qlist(package_known(self.room,"findPlayersBySkillName","sfofl_nujian")) do
			if not package_known(self,"isEnemy",p) and package_known(p,"getPile","sfofl_nujian_jian"):length() > 0 then
				return "#sfofl_nujianAttach:.:"
			end
		end
	end
end

ai_skill_invoke.sfofl_nujian = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	return (target and package_known(self,"isFriend",target)) or false
end
sgs.ai_use_revises.sfofl_nujian = function(self,card,use)
	if package_known(card,"isKindOf","EquipCard") and package_known(card,"isRed") then
		local same = package_known(self,"getSameEquip",card)
		if same then return false end
	end
end
function sgs.ai_cardsview_valuable.sfofl_nujianAttach(self, class_name, player)
	if not class_name=="Slash" then return end
	if package_known(player,"getStrategyFlag","Global_sfofl_nujian_Failed") then return end
	for _, p in sgs.qlist(package_known(self.room,"findPlayersBySkillName","sfofl_nujian")) do
	if package_known(p,"getPile","sfofl_nujian_jian"):length() > 0 and package_known(self,"isFriend",p) then return "#sfofl_nujianAttach:.:" end
	end
end

package_add("sfofl_nujianAttach").getTurnUseCard = function(self,inclusive,request)
	local dc = clone_native(self,"slash", sgs.Card_NoSuit, 0)
	package_call(dc,"setSkillName","_sfofl_nujian")
	package_call(dc,"deleteLater")
	local dummy = package_known(self,"aiUseCard",dc)
	if dummy.card then
		source_state(self).sfofl_nujianAttachdummy = dummy
		for _, p in sgs.qlist(package_known(self.room,"findPlayersBySkillName","sfofl_nujian")) do
			if package_known(p,"getPile","sfofl_nujian_jian"):length() > 0 and package_known(self,"isFriend",p) and package_known(self,"slashIsAvailable",self.player)	then return source_construct(self,"#sfofl_nujianAttach:.:")
			end
		end
	end
end

ai_card_use["#sfofl_nujianAttach"] = function(self, card, use, request)
	use.card = card
	use.to = source_state(self).sfofl_nujianAttachdummy.to
end

sgs.ai_use_revises.sfofl_2_xuezhan = function(self,card,use)
	if package_known(card,"isKindOf","EquipCard") and package_known(self,"evaluateArmor",card)>-5
	then use.card = card return true end
end

local sfofl_2_xuezhan_skill = {}
sfofl_2_xuezhan_skill.name = "sfofl_2_xuezhan"
table.insert(package_skills,sfofl_2_xuezhan_skill)
sfofl_2_xuezhan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = package_known(self,"addHandPile","h")
	for _,id in sgs.qlist(package_known(self.player,"getPile","sfofl_2_xuezhan")) do
		table.insert(cards, disclosed_card(self,id))
	end
	cards = package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)do
		if package_known(card,"isKindOf","EquipCard") then
			local slash = clone(self,"duel")
			package_call(slash,"addSubcard",card)
			package_call(slash,"setSkillName","sfofl_2_xuezhan")
			if package_known(slash,"isAvailable",self.player)
			then return slash end
		end
	end
end

sgs.ai_skill_playerchosen.sfofl_2_qizhen = sgs.ai_skill_playerchosen.zhongyong


ai_skill_invoke.sfofl_sizhan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	return (target and package_known(self,"isEnemy",target) and package_known(self,"doDisCard",target, "h", true)) or false
end
ai_skill_invoke.sfofl_huzhu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	return (package_known(self,"isFriend",target)) or false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_huzhu = function(self,player,promptlist)
	local damage = source_fact(self,"CurrentDamageStruct","toDamage")
	if damage.to then
		if promptlist[#promptlist]=="yes" then
			sgs.updateIntention(player,damage.to,-80)
		end
	end
end



local sfofl_kuishe_skill = {}
sfofl_kuishe_skill.name = "sfofl_kuishe"
table.insert(package_skills, sfofl_kuishe_skill)
sfofl_kuishe_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if not package_known(self.player,"hasUsed","#sfofl_kuishe")  then
		return source_construct(self,"#sfofl_kuishe:.:")
	end
end

ai_card_use["#sfofl_kuishe"] = function(self, card, use, request)
	if #self.enemies == 0 then return end
	package_call(self,"sort",self.enemies, "handcard")
	local target
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"doDisCard",enemy, "he", true) then
			target = enemy
			break
		end
	end
	if target  then
		use.card = source_construct(self,"#sfofl_kuishe:.:")
		if use.to then package_call(use.to,"append",target) end
	end
end

sgs.ai_skill_playerchosen.sfofl_kuishe = function(self, targets)
	package_call(self,"sort",self.friends_noself, "hp")
	for _, friend in ipairs(self.friends_noself) do
		if package_known(self,"canDraw",friend, self.player)  then
			return friend
		end
	end
    for _, friend in ipairs(self.friends_noself) do
		return friend
	end
    local targetlist=sgs.QList2Table(targets)
	return targetlist[1]
end
sgs.ai_playerchosen_intention.sfofl_kuishe = function(self, from, to)
	sgs.updateIntention(from, to, -50)
end

sgs.ai_canNiepan_skill.sfofl_wuchao = function(player)
	return true
end

sgs.ai_ajustdamage_to.sfofl_liangying = function(self,from,to,slash,nature)
	if nature == "F"
	then return 1 end
end

sgs.ai_skill_playerchosen.sfofl_benxi = function(self, targets)
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if package_known(self,"doDisCard",p, "ej") then
			return p
		end
	end
	return nil
end

local sfofl_yuanlue_skill = {}
sfofl_yuanlue_skill.name= "sfofl_yuanlue"
table.insert(package_skills,sfofl_yuanlue_skill)
sfofl_yuanlue_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_yuanlue:.:")
end

ai_card_use["#sfofl_yuanlue"] = function(self, card, use, request)
	package_call(self,"sort",self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if package_known(self,"objectiveLevel",enemy)>3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"damageIsEffective",enemy)
		then
			use.card = source_construct(self,"#sfofl_yuanlue:.:")
			package_call(use.to,"append",enemy)
			return
		end
	end

end

sgs.ai_use_value.sfofl_yuanlue = 2.5
sgs.ai_card_intention.sfofl_yuanlue = 80
sgs.dynamic_value.damage_card.sfofl_yuanlue = true

ai_skill_use["@@sfofl_wuduan"]=function(self,prompt,request)
    local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
		return "#sfofl_wuduan:"..package_known(card,"getId")..":"
	end
	return "."
end

package_add("sfofl_juezhan").getTurnUseCard = function(self,inclusive,request)
	local cs = {}
	for _,id in sgs.list(package_known(self.player,"getPile","sfofl_wuchaoliang"))do
		table.insert(cs,disclosed_card(self,id))
	end
	return cs
end

function sgs.ai_cardsview.sfofl_juezhan(self,class_name,player)
	for _,id in sgs.list(package_known(player,"getPile","sfofl_wuchaoliang"))do
		if disclosed_card(self,id):isKindOf(class_name)
		then return id end
	end
end



local sfofl_rende_skill = {}
sfofl_rende_skill.name = "sfofl_rende"
table.insert(package_skills,sfofl_rende_skill)
sfofl_rende_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_rende:.:")
end

ai_card_use["#sfofl_rende"] = function(self, card, use, request)
    package_call(self,"sort",self.friends_noself, "defense")
    local need = {}
    for _,p in ipairs(self.friends_noself) do
        table.insert(need, p)
    end

    local give = 0
    if #need == 0 then return end
    if #need == 1 then give = math.max(2, package_known(self.player,"getHandcardNum") - package_known(self.player,"getMaxCards")) end
    if #need > 1 then give = 2 end

    local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",cards)
    local usecards = {}
    for _,cc in ipairs(cards) do do
		if package_known(self,"willUse",self.player,cc) then goto package_continue_35 end
        table.insert(usecards, package_known(cc,"getEffectiveId"))
        give = give - 1
        if give <= 0 then break end
    end ::package_continue_35:: end
    if give > 0 then return end
    local card_str = string.format("#sfofl_rende:%s:->%s", table.concat(usecards,"+"), package_known(need[1],"objectName"))
    use.card = source_construct(self,card_str)
    if use.to then package_call(use.to,"append",need[1]) end
end

ai_skill_choice["sfofl_rende"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
    if #items == 1 then return ai_choice_result((items[1]), options) end
    if package_known(self.player,"getLostHp") > 1 then return ai_choice_result(("peach"), options) end
    table.removeOne(items, "cancel")
    for _,pattern in ipairs(items) do
        local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        package_call(self,"useCardByClassName",card, usec)
        if usec.to and package_known(usec.to,"length") > 0 then
            return ai_choice_result((pattern), options)
        end
    end
    return ai_choice_result(("cancel"), options)
end

ai_skill_use["@@sfofl_rende"]=function(self,prompt,request)
    local pattern = source_property(self,"sfofl_rende"):toString()

    if pattern == "peach" or pattern == "analeptic" then
        return string.format("#sfofl_rende_basic:.:->%s", package_known(self.player,"objectName"))
    end

	local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
	package_call(card,"setSkillName","sfofl_rende")
    local card = clone_native(self,pattern, sgs.Card_SuitToBeDecided, -1)
    local usec = {isDummy=true,to=sgs.SPlayerList()}
    package_call(self,"useCardByClassName",card, usec)
    if usec.to and package_known(usec.to,"length") > 0 then
        local tos = {}
        for _,to in sgs.qlist(usec.to) do
            table.insert(tos, package_known(to,"objectName"))
        end
        local card_str = string.format("#sfofl_rende_basic:.:->%s", table.concat(tos, "+"))
        return card_str
    end
    return "."
end

sgs.ai_use_priority.sfofl_rende = 8.8
sgs.ai_use_value.sfofl_rende = 10.8



sgs.ai_skill_cardask["@sfofl_lianzhou"] = function(self,data,pattern,target)
	if target and package_known(self,"isFriend",target) then return "." end
	local damage = package_known(data,"toDamage")
	if not package_known(self,"damageStruct",damage) then
		return "."
	end

	return true
end

sgs.ai_ajustdamage_to.sfofl_lianzhou = function(self,from,to,card,nature)
	if card and package_known(card,"isBlack") then
		if package_known(self,"isFriend",to,from) then return -1
		else
			if package_known(from,"objectName")~=package_known(self.player,"objectName") then
				if package_known(from,"getHandcardNum")<=2
				then return -1 end
			else
				if getKnownCard(from,self.player,"red")<1
				then return -1 end
			end
		end
	end
end


ai_skill_invoke.sfofl_pocheng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (sgs.ai_skill_playerchosen.sfofl_pocheng(self, package_known(self.room,"getOtherPlayers",self.player)) ~= nil and not package_known(self.player,"isNude")) or false
end
sgs.ai_skill_playerchosen.sfofl_pocheng = function(self, targets)
	package_call(self,"sort",self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"objectiveLevel",enemy) > 3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"canDamage",enemy,self.player,nil) and package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) then
			return enemy
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_pocheng = 80

sgs.ai_skill_discard.sfofl_pocheng = function(self)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, package_known(card,"getEffectiveId"))
		if #to_discard == 2 then
        	break
		end
	end
	if #to_discard == 2 then
		return to_discard
	end
	return {}
end
sgs.ai_skill_cardask["@sfofl_pocheng_target"] = function(self, data, pattern, target)
	if not package_known(self,"damageIsEffective",self.player,nil,target) then return "." end
	if package_known(self,"needToLoseHp",self.player,target,nil) then return "." end
	return true
end


ai_skill_use["@@sfofl_shoufan!"]=function(self,prompt,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"hasFlag","sfofl_shoufan") and package_known(card,"isKindOf","EquipCard") then
			return "#sfofl_shoufan:"..package_known(card,"getId")..":"
		end
	end
	for _, card in ipairs(cards) do
		if package_known(card,"hasFlag","sfofl_shoufan") then
			return "#sfofl_shoufan:"..package_known(card,"getId")..":"
		end
	end
	return "."
end
ai_skill_invoke.sfofl_shoufan = true
ai_skill_invoke.sfofl_shoufan_equip = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local card = package_known(data,"toCard")
	local dummy_use = package_known(self,"aiUseCard",card)
	if dummy_use.card then
		return (true) or false
	end
	return (false) or false
end

ai_skill_use["@@sfofl_dunji"]=function(self,prompt,request)
	package_call(self,"updatePlayers")
	package_call(self,"sort",self.enemies, "defense")
	local slash = clone_native(self,"slash", sgs.Card_NoSuit, 0)
	package_call(slash,"setSkillName","_sfofl_dunji")
	package_call(slash,"deleteLater")
	local dummy_use = package_known(self,"aiUseCard",slash, dummy())
	if dummy_use.to and package_known(dummy_use.to,"length") > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, package_known(to,"objectName"))
        end
        return selected(self,slash,tos)
    end
	return "."
end

sgs.ai_ajustdamage_from.sfofl_jiedao = function(self,from,to,card,nature)
	if package_known(from,"getStrategyMark","sfofl_jiedao_damage-Clear") == 0 and not package_known(self,"beFriend",to,from)
	then return 1 end
end
ai_skill_invoke.sfofl_jiedao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local to = package_known(data,"toDamage").to
	return (package_known(self,"isEnemy",to) and not package_known(self,"cantDamageMore",self.player,to)) or false
end


sgs.ai_skill_playerchosen.sfofl_qukui = function(self, targets)
	if package_known(self,"isWeak") then return nil end
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if package_known(self,"doDisCard",p, "hej") then
			return p
		end
	end
	return nil
end

ai_skill_invoke.sfofl_liefu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	if not package_known(self,"isEnemy",target) then return (false) or false end

	if package_known(self.player,"getHandcardNum")==1 then
		if (package_known(self,"needKongcheng") or not package_known(self,"hasLoseHandcardEffective")) and not package_known(self,"isWeak") then return (true) or false end
		local card  = package_known(self.player,"getHandcards"):first()
		if package_known(card,"isKindOf","Jink") or package_known(card,"isKindOf","Peach") then return false end
	end
	if package_known(self,"doDisCard",target,"he",true,2) then return (true) or false end
	return false

end

local sfofl_bingman_skill={}
sfofl_bingman_skill.name="sfofl_bingman"
table.insert(package_skills,sfofl_bingman_skill)
sfofl_bingman_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_bingman:.:")
end

ai_card_use["#sfofl_bingman"]=function(self, card, use, request)
	use.card=card
end
sgs.ai_use_priority.sfofl_bingman = 6.8

local sfofl_nanbing_skill = {}
sfofl_nanbing_skill.name = "sfofl_nanbing"
table.insert(package_skills,sfofl_nanbing_skill)
sfofl_nanbing_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self.player,"isKongcheng") then return end
	if #self.toUse>=2 then return end
	local savage_assault = clone(self,"savage_assault")
	package_call(savage_assault,"addSubcards",package_known(self.player,"getHandcards"))
	package_call(savage_assault,"setSkillName","sfofl_nanbing")
	if not package_known(savage_assault,"isAvailable",self.player) or package_known(self,"getAoeValue",savage_assault)<=0 then return end
	local handcards = sgs.QList2Table(package_known(self.player,"handCards"))
	return savage_assault
end

local sfofl_zaizheng_skill={}
sfofl_zaizheng_skill.name="sfofl_zaizheng"
table.insert(package_skills,sfofl_zaizheng_skill)
sfofl_zaizheng_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_zaizheng:.:")
end

ai_card_use["#sfofl_zaizheng"]=function(self, card, use, request)
	use.card=card
end

sgs.ai_use_priority.sfofl_zaizheng = 6.8

sgs.ai_skill_playerchosen.sfofl_zaizheng = function(self, targets)
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if package_known(self,"doDisCard",p, "ej") then
			return p
		end
	end
	return nil
end

local sfofl_zhaoxin_skill={}
sfofl_zhaoxin_skill.name="sfofl_zhaoxin"
table.insert(package_skills,sfofl_zhaoxin_skill)
sfofl_zhaoxin_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_zhaoxin:.:")
end

ai_card_use["#sfofl_zhaoxin"]=function(self, card, use, request)
	local good = 0
	for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player))do
		if package_known(self,"damageIsEffective",p, nil, self.player) then
			if package_known(self,"isFriend",p) and package_known(p,"isKongcheng") then
				good = good - 1
				if package_known(self,"isWeak",p) then
					good = good - 1
				end
			else
				good = good + 1
				if package_known(self,"isWeak",p) then
					good = good + 1
				end
			end
		end
	end
	if good > 0 then
		use.card=card
	end
end

sgs.ai_skill_cardask["@sfofl_zhaoxin_target"] = function(self, data, pattern, target)
	if not package_known(self,"damageIsEffective",self.player,nil,target) then return "." end
	if package_known(self,"needToLoseHp",self.player,target,nil) then return "." end
	return true
end
sgs.ai_skill_playerchosen.sfofl_shidi = function(self, targets)
	package_call(self,"sort",self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"objectiveLevel",enemy) > 3 and not package_known(self,"cantbeHurt",enemy) and package_known(self,"canDamage",enemy,self.player,nil) and package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) then
			return enemy
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_shidi = 80

sgs.ai_skill_discard.sfofl_n_rengong = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	for _,c in sgs.list(cards)do
		local num = {}
		for _,id in sgs.list(package_known(self.player,"getPile","sfofl_huangjin"))do
			if not table.contains(num, disclosed_card(self,id):getNumber()) then
				table.insert(num, disclosed_card(self,id):getNumber())
			end
		end
		if not table.contains(num, package_known(c,"getNumber")) then
			table.insert(to_discard, package_known(c,"getEffectiveId"))
			break
		end
	end
	if #to_discard > 0 then
		return to_discard
	end
	if package_known(self,"isWeak") then
		return {package_known(cards[1],"getEffectiveId")}
	end
	return {}
end

ai_skill_invoke.sfofl_n_chedian = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	if not package_known(self,"isEnemy",target) then return (false) or false end
	if package_known(self,"canDamage",target,self.player,nil) and package_known(self,"damageIsEffective",target, sgs.DamageStruct_Thunder, self.player) then
		return (true) or false
	end
	return (false) or false
end


package_add("sfofl_n_tiangong").getTurnUseCard = function(self,inclusive,request)
	local cs = {}
	for _,id in sgs.list(package_known(self.player,"getPile","sfofl_huangjin"))do
		table.insert(cs,disclosed_card(self,id))
	end
	return cs
end

function sgs.ai_cardsview.sfofl_n_tiangong(self,class_name,player)
	for _,id in sgs.list(package_known(player,"getPile","sfofl_huangjin"))do
		if disclosed_card(self,id):isKindOf(class_name)
		then return id end
	end
end
sgs.ai_use_priority.sfofl_n_tiangong = 5

sgs.ai_skill_cardask["@sfofl_n_guishen-card"]=function(self,data)
	local all_cards = package_known(self,"addHandPile","he")
	if #all_cards<1 then return "." end
	local judge = package_known(data,"toJudge")
	local needTokeep = package_known(judge.card,"getSuit")~=sgs.Card_Spade and (not package_known(self.player,"hasSkill","leiji") or package_known(judge.card,"getSuit")~=sgs.Card_Club)
		and package_known(self,"findLeijiTarget",self.player,50) and (package_known(self,"getCardsNum","Jink")>0 or package_known(self,"hasEightDiagramEffect")) and package_known(self,"getFinalRetrial")==1
	if not needTokeep and package_known(judge.who,"getPhase")<=sgs.Player_Judge
	and package_known(judge.who,"containsTrick","lightning") and judge.reason~="lightning"
	then needTokeep = true end
	local keptspade = 0
	if needTokeep and package_known(self.player,"hasSkills","nosleiji|tenyearleiji")
	then keptspade = 2 end
	local cards = {}
	for _,card in sgs.list(all_cards)do
		if not package_known(card,"hasFlag","using") then
			if package_known(card,"getSuit")==sgs.Card_Spade then keptspade = keptspade-1 end
			table.insert(cards,card)
		end
	end
	if #cards<1 or keptspade==1 then return "." end
	local card_id = package_known(self,"getRetrialCardId",cards,judge,nil,true)
	if card_id<0 then return "." end
	if package_known(self,"needRetrial",judge)
	or package_known(self,"getUseValue",judge.card)>package_known(self,"getUseValue",disclosed_card(self,card_id))
	then return card_id end
	return "."
end

sgs.ai_view_as.sfofl_n_leiming = function(card,player,card_place)
 local self=actor_ai(player)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place~=sgs.Player_PlaceSpecial and package_known(card,"getClassName")=="Slash" and not package_known(card,"hasFlag","using") then
		return ("thunder_slash:sfofl_n_leiming[%s:%s]=%d"):format(suit,number,card_id)
	end
end

local sfofl_n_leiming_skill = {}
sfofl_n_leiming_skill.name = "sfofl_n_leiming"
table.insert(package_skills,sfofl_n_leiming_skill)
sfofl_n_leiming_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = package_known(self,"addHandPile")
	local slash
	package_call(self,"sortByUseValue",cards,true)
	for _,card in ipairs(cards)do
		if package_known(card,"getClassName")=="Slash" then
			slash = card
			break
		end
	end
	if not slash then return nil end
	local dummy_use = dummy()
	package_known(self,"useCardThunderSlash",slash,dummy_use)
	if dummy_use.card and package_known(dummy_use.to,"length")>0 then
	else return nil end
	if slash then
		local suit = package_known(slash,"getSuitString")
		local number = package_known(slash,"getNumberString")
		local card_id = package_known(slash,"getEffectiveId")
		local card_str = ("thunder_slash:sfofl_n_leiming[%s:%s]=%d"):format(suit,number,card_id)
		local mySlash = source_construct(self,card_str)
		assert(mySlash)
		return mySlash
	end
end
ai_skill_invoke.sfofl_n_leiming = true

sgs.ai_card_priority.sfofl_n_leiming = function(self,card)
	if table.contains(package_known(card,"getSkillNames"), "sfofl_n_leiming")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end


ai_skill_invoke.sfofl_n_luanjian = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if package_known(self.player,"getEquips"):length() <= 2 then return (true) or false end
	return (false) or false
end

local sfofl_n_luanjian_skill = {}
sfofl_n_luanjian_skill.name = "sfofl_n_luanjian"
table.insert(package_skills, sfofl_n_luanjian_skill)
sfofl_n_luanjian_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local archery = clone_native(self,"archery_attack")
	local first_found, second_found = false, false
	local first_card, second_card
	local x=0
	for _, card in sgs.qlist(package_known(self.player,"getHandcards")) do
		if  string.find(source_property(self,"sfofl_n_luanjian"):toString(),package_known(card,"getSuitString")) then
			x = x + 1
		end
	end
	if package_known(self.player,"getHandcardNum") + package_known(self.player,"getPile","wooden_ox"):length()-x>1 then
		local cards = package_known(self.player,"getHandcards")
		local same_suit = false
		cards = sgs.QList2Table(cards)

		if package_known(self.player,"getPile","wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(package_known(self.player,"getPile","wooden_ox")) do
				table.insert(cards ,disclosed_card(self,id))
			end
		end

		package_call(self,"sortByKeepValue",cards)
		local useAll = false
		for _, enemy in ipairs(self.enemies) do
			if package_known(enemy,"getHp") == 1 and not package_known(enemy,"hasArmorEffect","vine") and not package_known(self,"hasEightDiagramEffect",enemy) and package_known(self,"damageIsEffective",enemy, nil, self.player)
				and package_known(self,"isWeak",enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
			end
		end
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
			if useAll then fvalueCard = isCard("ArcheryAttack", fcard, self.player) end
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard and not string.find(source_property(self,"sfofl_n_luanjian"):toString(),package_known(scard,"getSuitString")) and  not string.find(source_property(self,"sfofl_n_luanjian"):toString(),package_known(first_card,"getSuitString"))
						and not svalueCard then

						local card_str = ("archery_attack:sfofl_n_luanjian[%s:%s]=%d+%d"):format("to_be_decided", 0, package_known(first_card,"getId"), package_known(scard,"getId"))
						local archeryattack = source_construct(self,card_str)

						assert(archeryattack)

						local dummy_use = { isDummy = true }
						package_call(self,"useTrickCard",archeryattack, dummy_use)
						if dummy_use.card then
							second_card = scard
							second_found = true
							break
						end
					end
				end
				if second_card then break end
			end
		end
	end

	if first_found and second_found then
		local first_id = package_known(first_card,"getId")
		local second_id = package_known(second_card,"getId")
		local card_str = ("archery_attack:sfofl_n_luanjian[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = source_construct(self,card_str)
		assert(archeryattack)
		return archeryattack
	end
end

ai_skill_invoke.sfofl_n_xuezhan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if package_known(self.player,"getEquips"):length() <= 2 then return (true) or false end
	return (false) or false
end
local sfofl_n_xuezhan_skill = {}
sfofl_n_xuezhan_skill.name = "sfofl_n_xuezhan"
table.insert(package_skills,sfofl_n_xuezhan_skill)
sfofl_n_xuezhan_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = package_known(self,"addHandPile","h")
	cards = package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)do
		if package_known(card,"isKindOf","EquipCard") then
			local slash = clone(self,"duel")
			package_call(slash,"addSubcard",card)
			package_call(slash,"setSkillName","sfofl_n_xuezhan")
			if package_known(slash,"isAvailable",self.player)
			then return slash end
		end
	end
end

ai_skill_invoke.sfofl_n_jianbing = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = package_known(data,"toDamage")
	if package_known(self,"doDisCard",damage.to, "he", true) then return (true) or false end
	if package_known(self,"isFriend",damage.to) and package_known(self,"isWeak",damage.to) and getKnownCard(damage.to,self.player,"heart")>0 then return (true) or false end
	return (false) or false
end

sgs.ai_target_revises.sfofl_n_bishi = function(to,card)
	if package_known(card,"isKindOf","Slash")
	then return true end
end


local sfofl_n_yangwu_skill={}
sfofl_n_yangwu_skill.name="sfofl_n_yangwu"
table.insert(package_skills,sfofl_n_yangwu_skill)
sfofl_n_yangwu_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_n_yangwu:.:")
end

ai_card_use["#sfofl_n_yangwu"]=function(self, card, use, request)
	package_call(self,"sort",self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if package_known(enemy,"getHandcardNum") > package_known(self.player,"getHandcardNum") and package_known(self,"doDisCard",enemy, "h", true) then
			use.card=card
			package_call(use.to,"append",enemy)
			return
		end
	end

end
sgs.ai_use_priority.sfofl_n_yangwu = 9.3




sgs.ai_skill_playerchosen.sfofl_n_lianji = function(self, targets)
	package_call(self,"sort",self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		if package_known(self,"canDraw",friend, self.player) then
			return friend
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_n_lianji = -40
ai_skill_invoke.sfofl_n_lianji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (package_known(self.player,"getHp") < getBestHp(self.player)) or false
end

sgs.ai_skill_playerchosen.sfofl_n_lianjiphase = function(self, targets)
	package_call(self,"sort",self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if package_known(self,"getOverflow",enemy) > 0 then
			return enemy
		end
	end
	for _, friend in ipairs(self.friends) do
        for _,s in sgs.qlist(package_known(friend,"getVisibleSkillList")) do
            local skillname = package_known(s,"objectName")
            if (not package_known(s,"isAttachedLordSkill")) and (not package_known(self.player,"hasSkill",skillname)) then
                local translation = package_known(s,"getDescription")
                if (string.find(translation,"结束阶段") or string.find(translation,"弃牌阶段") ) and string.find(translation,"你可以") then
                    return friend
                end
            end
        end
	end
	for _, friend in ipairs(self.friends) do
		if package_known(self,"getOverflow",friend) == 0 then
			return friend
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_n_lianjiphase = 40

local sfofl_n_moucheng_skill = {}
sfofl_n_moucheng_skill.name = "sfofl_n_moucheng"
table.insert(package_skills, sfofl_n_moucheng_skill)

sfofl_n_moucheng_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self.player,"getHandcardNum") < 1 then return end
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	local subcards = {}
	package_call(self,"sortByUseValue",cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
		if package_known(card,"isBlack") then table.insert(cardsq, card) end
	end
	if #cardsq == 0 then return end
	if package_known(self,"getKeepValue",cardsq[1]) > 18 then return end
	if package_known(self,"getUseValue",cardsq[1]) > 12 then return end
	table.insert(subcards, package_known(cardsq[1],"getId"))
	local card_str = "Collateral:sfofl_n_moucheng[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = source_construct(self,card_str)
	assert(AsCard)
	return AsCard
end



local sfofl_n_duanji_skill = {}
sfofl_n_duanji_skill.name = "sfofl_n_duanji"
table.insert(package_skills,sfofl_n_duanji_skill)
sfofl_n_duanji_skill.getTurnUseCard = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = package_known(self,"addHandPile","h")
	cards = package_call(self,"sortByUseValue",cards,true)

	for _,card in ipairs(cards)do
		if package_known(card,"isKindOf","EquipCard") then
			local slash = clone(self,"duel")
			package_call(slash,"addSubcard",card)
			package_call(slash,"setSkillName","sfofl_n_duanji")
			if package_known(slash,"isAvailable",self.player)
			then return slash end
		end
	end
end

sgs.ai_skill_cardask["@sfofl_n_hujia"] = function(self, data, pattern, target, target2)
	local target = package_call(data,"toPlayer")
	if package_known(self,"isFriend",target) then
		return true
	end
	return "."
end

sgs.ai_cardsview_valuable.sfofl_n_hujia = function(self, class_name, player)
	local current = package_call(self.room,"getCurrent")
	local handcards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
    if not name then return end
	local had_card = nil
	for _, c in ipairs(handcards) do
		if package_known(c,"isKindOf",name) then
			had_card = c
            break
		end
	end

	if name and not package_known(player,"getStrategyFlag","Global_sfofl_n_hujiaFailed") and had_card == nil  then
		return string.format("#sfofl_n_hujia:.:%s", name)
	end
end

sgs.ai_skill_discard.sfofl_n_liangying = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	table.insert(to_discard, package_known(cards[1],"getEffectiveId"))
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end
sgs.ai_skill_discard.sfofl_n_yuanlue = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	for _,c in sgs.list(cards)do
		table.insert(to_discard, package_known(c,"getEffectiveId"))
		if #to_discard == 2 then
			return to_discard
		end
	end
	return {}
end

ai_skill_invoke.sfofl_n_yuanlue = true


local sfofl_n_yuanlue_skill={}
sfofl_n_yuanlue_skill.name="sfofl_n_yuanlue"
table.insert(package_skills,sfofl_n_yuanlue_skill)
sfofl_n_yuanlue_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive


	package_call(self,"setPriorityValue","sfofl_n_yuanlue", 6.8,"sfoflCard.source")
	local losthp = isLord(self.player) and 0 or 1
	if ((package_known(self.player,"getHp")>3 and package_known(self.player,"getLostHp")<=losthp and package_known(self.player,"getHandcardNum")>package_known(self.player,"getHp"))
		or (package_known(self.player,"getHp")-package_known(self.player,"getHandcardNum")>=2)) and not (isLord(self.player) and turn_count(self)<=1) then
		return source_construct(self,"#sfofl_n_yuanlue:.:")
	end
	local slash = clone(self)
	if package_call(self.player,"getWeapon") and package_call(self.player,"getWeapon"):isKindOf("Crossbow")
	or package_known(self.player,"hasSkill","paoxiao") then
		for _,enemy in ipairs(self.enemies)do
			if package_known(self.player,"canSlash",enemy,slash,true) and package_known(self,"slashIsEffective",slash,enemy)
				and not (package_known(enemy,"hasSkill","kongcheng") and package_known(enemy,"isKongcheng"))
				and not (package_known(enemy,"hasSkills","fankui|guixin") and not package_known(self.player,"hasSkill","paoxiao"))
				and not package_known(enemy,"hasSkills","fenyong|jilei|zhichi")
				and package_known(self,"isGoodTarget",enemy,self.enemies,slash) and not package_known(self,"slashProhibit",slash,enemy) and package_known(self.player,"getHp")>1 then
				return source_construct(self,"#sfofl_n_yuanlue:.:")
			end
		end
	end
	if package_known(self.player,"getHp")==1 and package_known(self,"getCardsNum","Analeptic")>=1 then
		return source_construct(self,"#sfofl_n_yuanlue:.:")
	end

end

ai_card_use["#sfofl_n_yuanlue"]=function(self, card, use, request)
	use.card=card
end

sgs.ai_use_priority.sfofl_n_yuanlue = 6.8

sgs.ai_ajustdamage_to.sfofl_n_cangchu = function(self,from,to,slash,nature)
	if nature == "F"
	then return 1 end
end

sgs.ai_skill_playerchosen.sfofl_n_xiying = function(self, targets)
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if package_known(self,"doDisCard",p, "hej") then
			return p
		end
	end
	return nil
end

package_add("sfofl_n_juezhan").getTurnUseCard = function(self,inclusive,request)
	local cs = {}
	for _,id in sgs.list(package_known(self.player,"getPile","sfofl_wuchaoliang"))do
		table.insert(cs,disclosed_card(self,id))
	end
	return cs
end

function sgs.ai_cardsview.sfofl_n_juezhan(self,class_name,player)
	for _,id in sgs.list(package_known(player,"getPile","sfofl_wuchaoliang"))do
		if disclosed_card(self,id):isKindOf(class_name)
		then return id end
	end
end


package_add("sfofl_n_juezhanAttach").getTurnUseCard = function(self,inclusive,request)
	local cards = sgs.QList2Table(package_known(self.player,"getPile","sfofl_wuchaoliang"))
	local to_use = {}
	for _, id in ipairs(cards) do
		table.insert(to_use, id)
		if #to_use >= 2 then break end
	end
	if #to_use ~= 2 then return end
	for _, pn in sgs.list(RandomList(patterns_for(self))) do do
		local dc = clone(self,pn)
		if (package_known(dc,"isNDTrick") or package_known(dc,"isKindOf","BasicCard")) and package_known(self.player,"getStrategyMark","sfofl_n_juezhanAttach_guhuo_remove_"..pn.."-Clear") == 0  then
			package_call(dc,"setSkillName","sfofl_n_juezhan")
			local dummy_use = package_known(self,"aiUseCard",dc, dummy())
			if package_known(dc,"isAvailable",self.player) and dummy_use.card then
				if package_known(dc,"canRecast") and package_known(dummy_use.to,"length")<1 then goto package_continue_36 end
				source_state(self).sfofl_n_juezhan_to = dummy_use.to
				package_call(self,"setPriorityValue","sfofl_n_juezhanAttach", sgs.ai_use_priority[package_known(dc,"getClassName")],"sfoflCard.source")
				local card = source_construct(self,"#sfofl_n_juezhanAttach:"..table.concat(to_use, "+") ..":"..pn)
				assert(card)
				return card
			end
		end
	end ::package_continue_36:: end
end

ai_card_use["#sfofl_n_juezhanAttach"] = function(self, card, use, request)
	if source_state(self).sfofl_n_juezhan_to
	then
		use.card = card
		use.to = source_state(self).sfofl_n_juezhan_to
	end
end

sgs.ai_use_value.sfofl_n_juezhanAttach = 5.4
sgs.ai_use_priority.sfofl_n_juezhanAttach = 2.8

sgs.ai_guhuo_card.sfofl_n_juezhanAttach = function(self, toname, class_name)
    if owner_reason(self) ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
    if class_name and package_known(self,"getCardsNum",class_name) > 0 then return end
    if package_known(self.player,"getStrategyMark","sfofl_n_juezhanAttach_guhuo_remove_"..class_name.."-Clear") == 0  then return end
    local c = clone(self,toname)
    package_call(c,"setSkillName","sfofl_n_juezhan")
    if (not c) then return end
	if package_known(c,"isKindOf","BasicCard") or package_known(c,"isNDTrick") then
		local cards = sgs.QList2Table(package_known(self.player,"getPile","sfofl_wuchaoliang"))
		local to_use = {}
		for _, id in ipairs(cards) do
			table.insert(to_use, id)
			if #to_use >= 2 then break end
		end
		if #to_use == 2 then
			return "#sfofl_n_juezhanAttach:"..table.concat(to_use, "+") ..":"..toname
		end
	end
end


sgs.ai_ajustdamage_to.sfofl_n_huoshen = function(self,from,to,slash,nature)
	if nature == "F"
	then return -99 end
end


local sfofl_n_zonghuo_skill={}
sfofl_n_zonghuo_skill.name="sfofl_n_zonghuo"
table.insert(package_skills,sfofl_n_zonghuo_skill)
sfofl_n_zonghuo_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByUseValue",cards,true)
	local card
	for _,acard in sgs.list(cards)do
		if package_known(acard,"isRed") and not package_known(acard,"isKindOf","Peach") and (package_known(self,"getDynamicUsePriority",acard)<sgs.ai_use_value.FireAttack or package_known(self,"getOverflow")>0) then
			if package_known(acard,"isKindOf","Slash") and package_known(self,"getCardsNum","Slash")==1 then
				local keep
				local dummy_use = dummy()
				package_call(self,"useBasicCard",acard,dummy_use)
				if dummy_use.card and dummy_use.to and package_known(dummy_use.to,"length")>0 then
					for _,p in sgs.qlist(dummy_use.to)do
						if package_known(p,"getHp")<=1 then keep = true break end
					end
					if package_known(dummy_use.to,"length")>1 then keep = true end
				end
				if keep then package_call(self,"setPriorityValue","Slash", sgs.ai_use_priority.FireAttack+0.1,"sfoflCard.source")
				else
					package_call(self,"setPriorityValue","Slash", 2.6,"sfoflCard.source")
					card = acard
					break
				end
			else
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	local card_str = ("fire_attack:sfofl_n_zonghuo[%s:%s]=%d"):format(suit,number,card_id)
	local skillcard = source_construct(self,card_str)

	assert(skillcard)

	return skillcard
end
ai_skill_invoke.sfofl_n_zonghuo = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	return (package_known(self,"doDisCard",target, "he")) or false
end

local sfofl_n_fenyin_skill={}
sfofl_n_fenyin_skill.name="sfofl_n_fenyin"
table.insert(package_skills,sfofl_n_fenyin_skill)
sfofl_n_fenyin_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_n_fenyin:.:")
end

ai_card_use["#sfofl_n_fenyin"]=function(self, card, use, request)
	local good = 0
	for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player))do
		if package_known(self,"damageIsEffective",p, sgs.DamageStruct_Fire, self.player) then
			if package_known(self,"isFriend",p) and package_known(p,"isKongcheng") then
				good = good - 1
				if package_known(self,"isWeak",p) then
					good = good - 1
				end
			else
				good = good + 1
				if package_known(self,"isWeak",p) then
					good = good + 1
				end
			end
		end
	end
	if good > 0 then
		use.card=card
	end
end

sgs.ai_ajustdamage_to.sfofl_n_fengshen = function(self,from,to,card,nature)
	if card and (package_known(card,"isKindOf","Slash") or package_known(card,"isKindOf","Duel"))
	then return -99 end
end

ai_skill_invoke.sfofl_n_jifeng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	return (package_known(self,"isFriend",target)) or false
end

sgs.ai_choicemade_filter.skillInvoke.sfofl_n_jifeng = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = package_call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end

local sfofl_n_tongchou_skill={}
sfofl_n_tongchou_skill.name="sfofl_n_tongchou"
table.insert(package_skills,sfofl_n_tongchou_skill)
sfofl_n_tongchou_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	return source_construct(self,"#sfofl_n_tongchou:.:")
end

ai_card_use["#sfofl_n_tongchou"]=function(self, card, use, request)
	use.card=card
end

sgs.ai_use_priority.sfofl_n_tongchou = 6.8



ai_skill_invoke.sfofl_n_chongsha = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	if not package_known(self,"isFriend",target) then return (package_known(self,"doDisCard",target, "he", true)) or false end
	return (false) or false
end

sgs.ai_skill_playerchosen.sfofl_n_tuxi = function(self, targets)
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if package_known(self,"doDisCard",p, "h") then
			return p
		end
	end
	return nil
end

sgs.ai_skill_playerchosen.sfofl_n_huwei = function(self, targets)
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if package_known(self,"doDisCard",p, "e") and package_known(self,"isEnemy",p) then
			return p
		end
	end
    for _, p in ipairs(targets) do
		if package_known(self,"isEnemy",p) and package_known(self,"hasSkills",sgs.need_maxhp_skill, enemy) then
			return p
		end
	end
    for _, p in ipairs(targets) do
		if package_known(self,"isEnemy",p) and package_known(self,"isWeak") then
			return p
		end
	end
    for _, p in ipairs(targets) do
		if package_known(self,"isEnemy",p) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_cardask["@sfofl_n_baijiang"] = function(self, data, pattern, target, target2)
	return true
end
ai_skill_invoke.sfofl_n_baijiang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = package_known(data,"toCardUse")
	if use.from and package_known(self,"isFriend",use.from) then
		if package_known(self,"getOverflow") == 0 and package_known(use.from,"getMaxCards") - package_known(use.from,"getHandcardNum") > 2 then
			return (true) or false
		end
	end
	if not package_known(self,"isFriend",use.from) then
		if package_known(use.from,"getStrategyMark","sfofl_n_baijiang-Clear") == 0 then return (true) or false end
		if package_known(use.from,"getMaxCards") > 0 then return (true) or false end
	end
	return (false) or false
end
sgs.ai_skill_discard.sfofl_n_zhuying = function(self)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	local damage = source_fact(self,"sfofl_n_zhuying","toDamage")
    local list = package_known(self.room,"getAlivePlayers")
	if package_known(self,"needToLoseHp",damage.to,damage.from,damage.card) then
		return {}
	end
	if not package_known(self,"damageStruct",damage) then
		return {}
	end
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, c1 in ipairs(cards) do
		for _, c2 in ipairs(cards) do
			if c1 ~= c2 and package_known(c1,"getType") == package_known(c2,"getType") then
				table.insert(to_discard, package_known(c1,"getEffectiveId"))
				table.insert(to_discard, package_known(c2,"getEffectiveId"))
				break
			end
		end
		if #to_discard == 2 then
			break
		end
	end
	if #to_discard == 2 then
		return to_discard
	end
	if package_known(self,"isWeak") then
		return {package_known(cards[1],"getEffectiveId"), package_known(cards[2],"getEffectiveId")}
	end
	return {}
end


ai_skill_invoke.sfofl_n_youzhan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	return (package_known(self,"doDisCard",target, "he")) or false
end



ai_skill_use["@@sfofl_n_shiji"]=function(self,prompt,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"isKindOf","Jink") then
			package_call(self,"sort",self.friends_noself, "handcard")
			for _,p in ipairs(self.friends_noself) do
				if package_known(self,"canDraw",p, self.player) then
					return "#sfofl_n_shiji:"..package_known(card,"getId")..":->"..package_known(p,"objectName")
				end
			end
		end
	end
	return "."
end
sgs.ai_card_intention["#sfofl_n_shiji"] = -80

sgs.ai_canNiepan_skill.sfofl_n_menghuo_rule = function(player)
	return package_known(player,"property","sfofl_nw_shenmenghuo_Phase"):toInt() < 3
end

package_add("sfofl_n_zhuifeng").getTurnUseCard = function(self,inclusive,request)
	for _,cn in sgs.list(patterns_for(self))do
		local fs = clone(self,cn)
		if fs and package_known(self.player,"getKingdom")=="wei"
		and package_known(fs,"isKindOf","Duel")
		and package_known(fs,"isAvailable",self.player)
		and not package_known(self,"isWeak") then
			package_call(fs,"setSkillName","sfofl_n_zhuifeng")
			local d = package_known(self,"aiUseCard",fs)
			package_call(self,"setPriorityValue","sfofl_n_zhuifeng", sgs.ai_use_priority[package_known(fs,"getClassName")],"sfoflCard.source")
			source_state(self).cf_to = d.to
			if d.card and d.to then
				return source_construct(self,"#sfofl_n_zhuifeng:.:"..cn)
			end
		end
	end
end

ai_card_use["#sfofl_n_zhuifeng"] = function(self, card, use, request)
	use.card = card
	use.to = source_state(self).cf_to
end
sgs.ai_use_value.sfofl_n_zhuifeng = 5.4
sgs.ai_use_priority.sfofl_n_zhuifeng = 2.8

package_add("sfofl_n_chongjian").getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self,"addHandPile","he")
	cards = package_call(self,"sortByKeepValue",cards,nil,true)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","EquipCard")
		then table.insert(toids,c) end
	end
	for _,cn in sgs.list(patterns_for(self))do
	   	local fs = clone(self,cn)
		if fs and package_known(self.player,"getKingdom")=="wu"
		and (package_known(fs,"isKindOf","Slash") or package_known(fs,"isKindOf","Analeptic"))
		and #toids>0
		then
			package_call(fs,"setSkillName","sfofl_n_chongjian")
			package_call(fs,"addSubcard",toids[1])
			local d = package_known(self,"aiUseCard",fs)
			if package_known(fs,"isAvailable",self.player)
			and d.card and d.to
			then return fs end
		end
	end
end

sgs.ai_guhuo_card.sfofl_n_chongjian = function(self,toname,class_name)
	local cards = package_known(self,"addHandPile","he")
	cards = package_call(self,"sortByKeepValue",cards,nil,true)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","EquipCard")
		then table.insert(toids,package_known(c,"getEffectiveId")) end
	end
	if #toids>0
	then return "#sfofl_n_chongjian:"..toids[1]..":"..toname end
end

ai_skill_use["@@sfofl_qinyi"]=function(self,prompt,request)
	return "#sfofl_qinyi::"
end

sgs.ai_skill_askforag.sfofl_qinyi = function(self,card_ids)
	for _,id in ipairs(RandomList(card_ids))do
		local card = disclosed_card(self,id)
		local dummy_use = package_known(self,"aiUseCard",card, dummy())
		if package_known(card,"isAvailable",self.player) and dummy_use.card then
			return id
		end
	end
end

sgs.ai_skill_playerchosen.sfofl_qinyi = function(self, targets)
	local card = disclosed_card(self,package_known(self.player,"getStrategyMark","sfofl_qinyi"))
	local use_card = clone_native(self,package_known(card,"objectName"), sgs.Card_NoSuit, 0)
	package_call(use_card,"setSkillName","sfofl_qinyi")
	package_call(use_card,"deleteLater")
	local dummy_use = package_known(self,"aiUseCard",use_card, dummy())
    targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
    for _, target in ipairs(targets) do
        if package_known(dummy_use.to,"contains",target) then
			return target
		end
    end
    return targets[math.random(1, #targets)]
end



sgs.ai_skill_playerschosen.sfofl_taoyan = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if package_known(self,"isFriend",target) and package_known(self,"canDraw",target, self.player) then
			package_call(selected,"append",target)
			if package_known(selected,"length") >= max then break end
		end
	end
    return selected
end

ai_skill_invoke.sfofl_yanli = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_known(data,"toDying").who
    if target and package_known(self,"isFriend",target) then return (true) or false end
	return (false) or false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_yanli = function(self, player, promptlist)
    local dying = package_known(self.room,"getCurrentDyingPlayer")
    if dying and promptlist[#promptlist] == "yes" then
        sgs.updateIntention(player, dying, -70)
    end
end


sgs.ai_skill_cardask["@sfofl_shanwu"] = function(self, data, pattern, target, target2)
	local use = package_known(data,"toCardUse")
    if target and not package_known(self,"isFriend",target) then return "." end
	if use.card and package_known(use.card,"hasFlag","NosJiefanUsed") then return "." end

	if not use.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,use.from)
		or package_known(use.card,"isKindOf","NatureSlash") and package_known(self.player,"isChained") and package_known(self,"isGoodChainTarget",target,use.card,use.from)
		or package_known(self,"needToLoseHp",target,use.from,use.card) and package_known(self,"ajustDamage",use.from,target,1,use.card)==1 then return "." end
	if package_known(self,"needToLoseHp",target, use.from,use.card, true, true) then return "." end
	if getCardsNum("Jink", target, self.player) == 0 then return true end
	return true
end

sgs.ai_choicemade_filter.cardResponded["@sfofl_shanwu"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local target = package_call(self.room,"findPlayerByObjectName",promptlist[2])
		if target then
			sgs.updateIntention(player, target, -40)
		end
	end
end

ai_skill_invoke.sfofl_xianli = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
    if target and package_known(self,"doDisCard",target, "he", true) then return (true) or false end
	return (false) or false
end

sgs.ai_skill_cardask["@sfofl_guisha"] = function(self,data)
	local use = package_known(data,"toCardUse")
	local slash = use.card
	local slash_num = 0
	if package_known(use.from,"objectName")==package_known(self.player,"objectName") then
		slash_num = package_known(self,"getCardsNum","Slash")
	else
		slash_num = getCardsNum("Slash",use.from,self.player)
	end
	if package_known(self,"isEnemy",use.from) then return "." end
	if (use.m_reason==sgs.CardUseStruct_CARD_USE_REASON_PLAY and use.m_addHistory and package_known(self,"isFriend",use.from) and slash_num>=1) then
		return true
	end
	if package_known(self,"isFriend",use.from) and (not package_known(self,"isFriend",package_known(use.to,"first")) and not package_known(self,"cantDamageMore",use.from, package_known(use.to,"first"))) then
		return true
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@sfofl_guisha"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		package_known(self.room,"writeToConsole",promptlist[#promptlist]..": "..promptlist[4])
		local target = package_call(self.room,"findPlayerByObjectName",promptlist[4])
		if target then
			sgs.updateIntention(player, target, -40)
		end
	end
end

sgs.ai_ajustdamage_from.sfofl_guisha = function(self, from, to, card, nature)
    if card and package_known(card,"hasFlag","sfofl_guisha")  then
        return 1
    end
end

ai_skill_invoke.sfofl_shuli = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
    if target and package_known(self,"isFriend",target) then return (true) or false end
	return (false) or false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_shuli = function(self, player, promptlist)
    local target = package_call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
	if target then sgs.updateIntention(player,target,-50) end
end


ai_skill_invoke.sfofl_meiniang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(self.room,"getCurrent")
    if target and package_known(self,"isFriend",target) then return (true) or false end
	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.sfofl_meiniang = function(self, player, promptlist)
    local target = package_call(self.room,"getCurrent")
	if target then sgs.updateIntention(player,target,-50) end
end


ai_skill_invoke.sfofl_yaoli = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_known(data,"toCardUse").from
    if target and package_known(self,"isFriend",target) then return (true) or false end
	return (false) or false
end



sgs.ai_skill_discard.sfofl_leyu = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local current = package_call(self.room,"getCurrent")
	if not current then return {} end
	if #self.enemies<1 then return {} end
	local getvalue = function(enemy)
		if not AIValue.isPlayer(enemy) then return -100 end
		local value = package_known(enemy,"getHandcardNum")-package_known(enemy,"getHp")
		for _,sk in sgs.list(sgs.getPlayerSkillList(enemy))do
			local s = view_as_meta(self,package_known(sk,"objectName"))
			if s and package_known(s,"isEnabledAtPlay",enemy) then value = value+6 end
			s = trigger_meta(self,package_known(sk,"objectName"))
			if s and package_known(s,"hasEvent",sgs.EventPhaseStart) then value = value-2 end
			if s and package_known(s,"hasEvent",sgs.EventPhaseChanging) then value = value-2 end
			if s and package_known(s,"hasEvent",sgs.FinishJudge) then value = value-2 end
		end
		if package_known(self,"isWeak",enemy) then value = value+3 end
		if package_known(enemy,"isLord") then value = value+3 end
		if package_known(self,"objectiveLevel",enemy)<3 then value = value-6 end
		if package_known(enemy,"hasSkills","keji|shensu|conghui") then value = value-package_known(enemy,"getHandcardNum") end
		if package_known(self,"needBear",enemy) then value = value-20 end
		return value+(package_known(enemy,"aliveCount")-package_known(self,"playerGetRound",enemy))/2
	end
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	for _,c in ipairs(cards)do
		if #to_discard>=discard_num then break end
		table.insert(to_discard,package_known(c,"getEffectiveId"))
	end
	local function cmp(a,b)
		return getvalue(a)>getvalue(b)
	end
	table.sort(self.enemies,cmp)
	if package_known(self.enemies[1],"objectName") == package_known(current,"objectName") and getvalue(self.enemies[1]) >-100 then
		if #to_discard == 3 then
			return to_discard
		end
	elseif package_known(self.player,"getCardCount") - #to_discard > 3 and #to_discard == 3 then
		for _,p in sgs.list(self.enemies)do
			if package_known(p,"objectName") == package_known(current,"objectName") then
				return to_discard
			end
		end
	end
	return {}
end

sgs.ai_skill_playerchosen.sfofl_yuanli = function(self, targets)
	package_call(self,"sort",self.friends_noself, "handcard")
	for _, friend in ipairs(self.friends_noself) do
		if package_known(self,"canDraw",friend, self.player) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		return friend
	end
	return package_known(targets,"last")
end
sgs.ai_playerchosen_intention.sfofl_yuanli = -40

ai_skill_invoke.sfofl_moli_zhenji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local id = package_known(data,"toInt")
	local card = disclosed_card(self,id)
	if not package_known(card,"isBlack") then return (false) or false end
	return (package_known(self.player,"getStrategyMark","&sfofl_moli") < 5) or false
end
ai_skill_invoke.sfofl_jinghong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_call(data,"toPlayer")
	if package_known(self.player,"getStrategyMark","&sfofl_moli") <= 1 and package_known(self.player,"getPhase") ~= sgs.Player_NotActive then
		package_known(self,"getTurnUse")
		if #self.toUse > 2 then
			return (false) or false
		end
	end
	if target and package_known(self,"isFriend",target) and package_known(self,"canDraw",target) then return (true) or false end
	return (false) or false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_jinghong = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = package_call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end

sgs.ai_canliegong_skill.sfofl_youlong = function(self, from, to)
	return package_known(to,"getStrategyMark","&sfofl_youlong-SelfClear") > 0
end

ai_skill_invoke.sfofl_haiyou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = package_known(data,"toCardUse")
	local target
	for _, p in sgs.qlist(use.to) do
		if ((string.find(package_known(p,"getGeneralName"), "_change") and string.find(package_known(p,"getGeneralName"), "sfofl_")) or (string.find(package_known(p,"getGeneral2Name"), "_change") and string.find(package_known(p,"getGeneral2Name"), "sfofl_"))) then
			target = p
			break
		end
	end
	if package_known(use.card,"isKindOf","AOE") and use.from and package_known(self,"isFriend",use.from) then
		return (false) or false
	end
	return (package_known(self,"shouldInvokeCostNullifySkill",use, false, false, 0, target)) or false
end

sgs.ai_use_revises.sfofl_moli_woguotai = function(self,card,use)
	if package_known(card,"isKindOf","EquipCard") and package_known(self,"evaluateArmor",card)>-5
	then use.card = card return true end
end

ai_skill_invoke.sfofl_susheng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = package_known(data,"toDying").who
	if target and package_known(self,"isFriend",target) then return (true) or false end
	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.sfofl_susheng = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = package_known(self.room,"getCurrentDyingPlayer")
		if target then sgs.updateIntention(player,target,-50) end
	end
end

ai_skill_choice.sfofl_susheng = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = package_known(data,"toDying").who
	local items = package_known(choices,"split","+")
	if target and package_known(target,"objectName") == package_known(self.player,"objectName") then
		return ai_choice_result((items[math.max(#items-1, 1)]), options)
	end
	if target and package_known(self,"isFriend",target) then
		for _, item in ipairs(items) do
			local x = tonumber(item)
			if x + package_known(target,"getHp") >= 1 then
				return ai_choice_result((item), options)
			end
		end
	end
	return ai_choice_result(("1"), options)
end

ai_skill_choice.sfofl_fengshou = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local items = package_known(choices,"split","+")
	local x =sgs.ai_skill_playerschosen.sfofl_fengshou(self, package_known(self.room,"getOtherPlayers",self.player), package_known(self.player,"getStrategyMark","&sfofl_moli"), 1):length()
	if x > 0 and table.contains(items, tostring(x)) then
		return ai_choice_result((tostring(x)), options)
	end
	return ai_choice_result((itmes[1]), options)
end

sgs.ai_playerschosen_intention.sfofl_fengshou = function(self, from, prompt)
    local intention = 60
    local tolist = package_known(prompt,"split","+")
    for _, dest in ipairs(tolist) do
        local to = package_call(self.room,"findPlayerByObjectName",dest)
        sgs.updateIntention(from, to, intention)
    end
end

sgs.ai_skill_playerschosen.sfofl_fengshou = function(self, targets, max, min)
	local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if package_known(self,"isEnemy",target) and not package_known(self,"cantDamageMore",self.player, target) and package_known(self,"canDamage",target, self.player, nil) and package_known(self,"damageIsEffective",target,sgs.DamageStruct_Fire,self.player) then
			package_call(selected,"append",target)
			if package_known(selected,"length") >= max then break end
		end
	end
    return selected
end

sgs.ai_skill_playerchosen.sfofl_fengshou = function(self, targets)
	local target = nil
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if package_known(p,"getStrategyFlag","sfofl_fengshou_target") then
			target = p
			break
		end
	end
	if target then
		local x = package_known(self,"getNumBySeat",package_call(self.room,"getCurrent"), target)
		if not package_known(self,"isFriend",target) then
    		for _, p in ipairs(targets) do
				if package_known(self,"isFriend",p) and package_known(self,"getNumBySeat",package_call(self.room,"getCurrent"), p) > x then
					return p
				end
			end
		else
			for _, p in ipairs(targets) do
				if package_known(self,"isEnemy",p) and package_known(self,"getNumBySeat",package_call(self.room,"getCurrent"), p) < x then
					return p
				end
			end
		end
		return targets[1]
	else
		local nextalive = package_call(self.room,"getCurrent"):getNextAlive()
		if package_known(self,"isEnemy",nextalive) and #self.friends_noself > 0 then
			for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
				if package_known(self.player,"distanceTo",p) == 1 and package_known(self,"isFriend",p) then
					return nextalive
				end
			end
		end
	end
	return nil
end

package_add("sfofl_shengcai").getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards = package_call(self,"sortByKeepValue",cards,nil,true)
	if #cards<1 then return end
	local ids = {}
   	local fs = clone(self)
	package_call(fs,"setSkillName","sfofl_shengcai")
  	for _,c in sgs.list(cards)do do
		if package_known(self,"getKeepValue",c)>3 or #ids>=package_known(self.player,"getStrategyMark","&sfofl_moli")
		or #ids>=#cards/2 then goto package_continue_37 end
		table.insert(ids,package_known(c,"getEffectiveId"))
		package_call(fs,"addSubcard",c)
	end ::package_continue_37:: end
	if #ids<1 and #cards>1
	then
		table.insert(ids,package_known(cards[1],"getEffectiveId"))
		package_call(fs,"addSubcard",cards[1])
	end
	local dummy = package_known(self,"aiUseCard",fs)
	if package_known(fs,"isAvailable",self.player)
	and dummy.card
	and dummy.to
	and #ids>0
  	then
		return fs
	end
end

sgs.ai_ajustdamage_from.sfofl_shengcai = function(self, from, to, card, nature)
	if card and package_known(card,"isKindOf","Slash") and table.contains(package_known(card,"getSkillNames"), "sfofl_shengcai")  then
		return math.max(package_known(card,"subcardsLength") - 1, 0)
	end
end

sgs.ai_canliegong_skill.sfofl_guanghui = function(self, from, to)
	return not ((string.find(package_known(to,"getGeneralName"), "_change") and string.find(package_known(to,"getGeneralName"), "sfofl_")) or (string.find(package_known(to,"getGeneral2Name"), "_change") and string.find(package_known(to,"getGeneral2Name"), "sfofl_")))
end

ai_fill_skill.sfofl_moqi = function(self, options, request)
    local inclusive = options and options.inclusive

	if package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") == 0  then
		return nil
	end
	if #self.enemies == 0 then
		return nil
	end
	local c = source_construct(self,"@OLQimouCard=.")
	local dummy_use = dummy()
	package_known(self,"useSkillCard",c,dummy_use)
	if dummy_use.card then
		return source_construct(self,"#sfofl_moqi:.:")
	end
	return nil
end

ai_card_use["#sfofl_moqi"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_priority["sfofl_moqi"] = 10

ai_skill_choice.sfofl_henghui = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = package_known(choices,"split","+")
	if package_known(self.player,"getStrategyMark","&sfofl_moli") >= 4 then
		table.removeOne(items, "cancel")
	end
	return ai_choice_result((items[math.random(1, #items)]), options)
end

sgs.ai_ajustdamage_from.sfofl_henghui = function(self, from, to, card, nature)
	if package_known(from,"getStrategyMark","&sfofl_henghui_first") > 0 and card and package_known(card,"isKindOf","Slash")  then
		return 1
	end
end

sgs.ai_skill_playerchosen.sfofl_shengyan = function(self,targets)
	local targetlist = package_call(self,"sort",targets,"hp")
	return package_known(self,"findPlayerToDamage",1,self.player,"F",targets,0,nil)[1]
end

ai_skill_invoke.sfofl_gongming = true

sgs.ai_ajustdamage_from.sfofl_kuangbao = function(self, from, to, card, nature)
	if package_known(from,"getHandcardNum") > package_known(to,"getHandcardNum")  then
		return 1
	end
end
sgs.ai_ajustdamage_to.sfofl_kuangbao = function(self, from, to, card, nature)
	if package_known(from,"getHandcardNum") > package_known(to,"getHandcardNum")  then
		return 1
	end
end

sgs.ai_ajustdamage_from.sfofl_shiqiang = function(self, from, to, card, nature)
	if package_known(from,"getHandcardNum") > package_known(to,"getHandcardNum")  then
		return 1
	end
end
sgs.ai_ajustdamage_to.sfofl_shiqiang = function(self, from, to, card, nature)
	if package_known(from,"getHandcardNum") > package_known(to,"getHandcardNum")  then
		return 1
	end
end

























for _,skill in ipairs(package_skills)do ai_fill_skill[skill.name]=skill.getTurnUseCard end
for key,fn in pairs(ai_fill_skill)do
 if type(fn)=='function'and initial_callbacks.ai_fill_skill[key]~=fn then
  ai_fill_skill[key]=function(self, options, request)
    local inclusive = options and options.inclusive
local old=active_requests[self];active_requests[self]=request;local r=table.pack(pcall(fn,self,options,request));active_requests[self]=old;if not r[1]then error(r[2],0)end;return finish_turn(self,r[2],request)end
 end
end
for key,fn in pairs(ai_card_use)do
 if type(fn)=='function'and initial_callbacks.ai_card_use[key]~=fn then
  ai_card_use[key]=function(self, card, use, request)local old=active_requests[self];active_requests[self]=request;local r=table.pack(pcall(fn,self,card,use,request));active_requests[self]=old;if not r[1]then error(r[2],0)end;return table.unpack(r,2,r.n)end
 end
end
for key,fn in pairs(ai_skill_use)do
 if type(fn)=='function'and initial_callbacks.ai_skill_use[key]~=fn then
  ai_skill_use[key]=function(self,prompt,request)local r=table.pack(fn(self,prompt,request));if AIUnsupported.is(r[1])then error(r[1],0)end;if type(r[1])=='string'and r[1]~='.'then return source_response(self,r[1],request)end;return table.unpack(r,1,r.n)end
 end
end
for _,registry in ipairs({'ai_guhuo_card','ai_cardsview','ai_cardsview_valuable','ai_view_as'})do
 for key,fn in pairs((registry == "ai_card_use" and ai_card_use or (registry == "ai_skill_invoke" and ai_skill_invoke or (registry == "ai_fill_skill" and ai_fill_skill or (registry == "ai_skill_choice" and ai_skill_choice or sgs[registry])))))do
  if type(fn)=='function'and initial_callbacks[registry][key]~=fn then
   (registry == "ai_card_use" and ai_card_use or (registry == "ai_skill_invoke" and ai_skill_invoke or (registry == "ai_fill_skill" and ai_fill_skill or (registry == "ai_skill_choice" and ai_skill_choice or sgs[registry]))))[key]=function(...)local args=table.pack(...);local self=registry=='ai_view_as'and actor_ai(args[2])or args[1];local r=table.pack(fn(...));if AIUnsupported.is(r[1])then error(r[1],0)end;if type(r[1])=='string'and r[1]~='.'then return source_proposal(self,r[1])end;return table.unpack(r,1,r.n)end
  end
 end
end

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if damage_call(to, "getMark", "&undershouli-Clear")>0 then
            dmg = dmg+damage_call(to, "getMark", "&undershouli-Clear")
            nature = "T"
        end
        return dmg, nature
    end
    local previous_1 = sgs.ai_ajustdamage_from["undershouli"]
    sgs.ai_ajustdamage_from["undershouli"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "before_from" and context.rule == "undershouli" then
                local damage, next_nature, terminal = policy_1(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_from", "undershouli", {
        {phase="before_from", rule="undershouli", order=4400},
    })
end)()
