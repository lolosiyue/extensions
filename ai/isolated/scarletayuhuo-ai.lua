-- Fixed scarletayuhuo b6025acc source policy. Readonly proposals never grant payment authority.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("scarletayuhuo fact unknown",k)end;return v end
local function __scarletayuhuo_value_call(o,k,...)if o==nil then error("attempt to index a nil value",0)end;if k=="getMark"and AIValue.isPlayer(o)then k="getStrategyMark"elseif k=="hasFlag"and AIValue.isPlayer(o)then k="getStrategyFlag"end;if type(o[k])~="function"then ai_unsupported("scarletayuhuo method unavailable",k)end;return known(o[k](o,...),k)end
local function fact(self,k)return known(known(self.world.strategy_facts.scarletayuhuo,"scarletayuhuo facts")[k],k)end
local function visible(self,id)
 local card=self:getKnownCardById(id)
 if not card and type(self.getChoiceCard)=="function"then card=self:getChoiceCard(id)end
 if not card then
  local f=self.world.strategy_facts.scarletayuhuo
  local rows=type(f)=="table"and f.disclosed_cards
  local row=type(rows)=="table"and rows[tostring(id)]
  if type(row)=="table"and row.effective_id==id then card=CardView.new(row)end
 end
 return known(card,"disclosed card")
end
local function property(self,k)return known(known(self.world.strategy_facts.owner_skill_properties,"owner properties")[k],k)end
local function tag(self,k,kind)
 local fact_key=(k=="CurrentUseStruct"and kind=="CardEffect")and"CurrentUseStruct_CardEffect"or(k=="s3_fans_jibian"and kind=="Player")and"s3_fans_jibian_Player"or k
 local r=fact(self,fact_key);if r==false then return nil end
 if kind=="Player"then return known(self.room:findPlayerByObjectName(r,true),k)elseif kind=="IntList"or kind=="StringList"then return AIList.new(r)
 elseif kind=="CardUse"then local to=AIList.new({});for _,n in ipairs(r.to)do to:append(known(self.room:findPlayerByObjectName(n,true),k))end;return{from=r.from and self.room:findPlayerByObjectName(r.from,true),to=to,card=CardView.new(r.card)}
 elseif kind=="CardEffect"then return{from=r.from and self.room:findPlayerByObjectName(r.from,true),to=r.to and self.room:findPlayerByObjectName(r.to,true),card=r.card and CardView.new(r.card),multiple=r.multiple,offset_num=r.offset_num}
 elseif kind=="Judge"then
  local j={who=known(self.room:findPlayerByObjectName(r.who,true),k),card=CardView.new(known(r.card,k)),reason=r.reason,pattern=r.pattern,good=known(r.predicate_good,k),negative=r.negative,play_animation=r.play_animation}
  function j:isGood(c)if c==nil then return known(r.good,k)end;local v=known(r.outcome_by_id,k)[tostring(c:getEffectiveId())];if type(v)~="boolean"then ai_unsupported("source judge outcome missing",k)end;return v end
  function j:isBad(c)return not self:isGood(c)end;return j
 elseif kind=="Dying"then return{who=r.who and self.room:findPlayerByObjectName(r.who,true),damage=r.damage}
 elseif kind=="SlashEffect"then return{from=r.from and self.room:findPlayerByObjectName(r.from,true),to=r.to and self.room:findPlayerByObjectName(r.to,true),slash=r.slash and CardView.new(r.slash),jink_num=r.jink_num,drank=r.drank,nature=r.nature}
 elseif kind=="Damage"then return{from=r.from and self.room:findPlayerByObjectName(r.from,true),to=r.to and self.room:findPlayerByObjectName(r.to,true),card=r.card and CardView.new(r.card),damage=r.amount,nature=r.nature,chain=r.chain,transfer=r.transfer}
 else return r end
end
local function dummy_plan(value,extra,current)local u=AIUsePlan.new();u.isDummy=value~=false;u.extra_target=extra or 0;u.current_targets=current or {};return u end
local recipes=setmetatable({},{__mode="k"})
local function copy(t)local r={}for k,v in pairs(t)do if type(v)=="table"then r[k]=copy(v)else r[k]=v end end;return r end
local function clone(self,name,suit,number,skill)
 if type(suit)=="string"then skill=suit;suit=sgs.Card_NoSuit end
 name=name or"slash";suit=suit or sgs.Card_NoSuit;number=number or 0
 local spec={source_key=self._scarletayuhuo_callback_key or "scarletayuhuo",name=name,skill=skill or"",suit=suit,number=number,subcards={}}
 local c
 if spec.skill==""and suit==sgs.Card_NoSuit and number==0 then c=self:getEvaluationCard(name)
 else c=self:evaluateOwnerViewAsCard(spec)end
 if c then recipes[c]=spec end;return c
end
local function mutate(self,c,field,v)
 local spec=recipes[c];if not spec then ai_unsupported("source mutates card outside its owned readonly clone","scarletayuhuo.clone")end
 spec=copy(spec)
 if field=="clear"then spec.subcards={}elseif field=="can_recast"then ai_unsupported("readonly clone recast mutation requires scoped native contract",self._scarletayuhuo_callback_key)elseif field=="add"then spec.subcards[#spec.subcards+1]=type(v)=="number"and v or __scarletayuhuo_value_call(v,"getEffectiveId")else spec[field]=v end
 local next
 if spec.prototype then next=self:evaluateTurnSkillCard(spec.skill,spec.prototype,spec.subcards,nil,spec.user)else next=self:evaluateOwnerViewAsCard(spec)end;self:inheritLegacyCardIdentity(next,c);recipes[next]=spec;return next
end
local function ids(raw)local out={};if raw~="."and raw~=""then for n in raw:gmatch("[^+]+")do out[#out+1]=tonumber(n)or 0 end end;return out end
local function printed_spec(text)
 local name,skill,suit,n,raw=text:match("^([%w_]+):([%w_]+)%[([^:]+):([^%]]+)%]=(.*)$");if not name then return nil end
 local suits={spade=sgs.Card_Spade,club=sgs.Card_Club,heart=sgs.Card_Heart,diamond=sgs.Card_Diamond,no_suit=sgs.Card_NoSuit,no_suit_red=sgs.Card_NoSuitRed,no_suit_black=sgs.Card_NoSuitBlack};local nums={A=1,J=11,Q=12,K=13}
 return{name=name,skill=skill,suit=suits[suit]or sgs.Card_NoSuit,number=known(tonumber(n)or nums[n],"number"),subcards=ids(raw)}
end
local classes={['#s_anren']='s_anren',['#s_biaoqiSlash']='s_biaoqiSlash',['#s_w_jiejiang']='s_w_jiejiang',['#s_w_qimouCard']='s_w_qimou',['#s_w_shenghun']='s_w_shenghun',['#s_w_changshu']='s_w_changshu',['#s_w_wuqian']='s_w_wuqian',['#s2_longhun']='s2_longhun',['#s2_duanzui']='s2_duanzui',['#s2_shenpan']='s2_shenpan',['#s2_jiange']='s2_jiange',['#s2_wushen']='s2_wushen',['#s2_houqi']='s2_houqi',['#s2_yizei']='s2_yizei',['#s2_zhanjiang']='s2_zhanjiang',['#s2_shanqi']='s2_shanqi',['#s2_longwei_select']='s2_longwei',['#s2_bayeCard']='s2_bayeVS',['#s2_xiaoguo']='s2_xiaoguo',['#s2_xiande']='s2_xiande',['#s2_jinchi']='s2_jinchi',['#s2_zhanpo']='s2_zhanpo',['#s2_danjing']='s2_danjing',['#s2_leiyin']='s2_leiyin',['#s2_andu']='s2_andu',['#s2_chizha']='s2_chizha',['#s2_xubian']='s2_xubian',['#s2_qiangrang']='s2_qiangrang',['#s2_mieshi']='s2_mieshi',['#s2_zhonghun']='s2_zhonghun',['#s2_tiantan']='s2_tiantan',['#s2_yinyang']='s2_yinyang',['#s2_danmu']='s2_danmu',['#s2_2_zhanjiang']='s2_2_zhanjiang',['#s3_jianyan']='s3_jianyan',['#s3_qiangyuan']='s3_qiangyuan',['#s3_qiane']='s3_qiane',['#s3_fenzhi']='s3_fenzhi',['#s3_fudao']='s3_fudao',['#s3_xiandao']='s3_xiandao',['#s3_yt_tongnan']='s3_yt_tongnan',['#s3_yt_qibing']='s3_yt_qibing',['#s3_yt_ruiqiDummyCard']='#s3_yt_ruiqiDiscard',['#s3_yt_qujin']='s3_yt_qujin',['#s3_huanxiangbenghuai']='s3_huanxiangbenghuai',['#s3_fans_handou']='s3_fans_handou',['#s3_fans_jibian']='s3_fans_jibian',['#s3_fans_feiyan']='s3_fans_feiyan',['#s3_fans_xianjia']='s3_fans_xianjia',['#s3_xianju']='s3_xianju',['#s3_jxwj_weiwan']='s3_jxwj_weiwan',['#s3_jxwj_zhuwei']='s3_jxwj_zhuwei',['#s3_jxwj_zijun']='s3_jxwj_zijun',['#s3_jxwj_shangdao']='s3_jxwj_shangdao',['#s3_jxwj_fuji']='s3_jxwj_fuji',['#s3_jxwj_jiujia']='s3_jxwj_jiujia'}
local function decode(text)
 local cl,raw=text:match("^@([%w_]+)=(.*)$");local user
 if cl then local costs,u=raw:match("^(.-):(.*)$");raw=costs or raw;user=u
 else cl,raw,user=text:match("^#([%w_]+):([^:]*):(.*)$");if cl then cl="#"..cl end end
 local sk=cl and classes[cl];if not sk then ai_unsupported("source prototype wire outside authored catalog","scarletayuhuo")end
 return cl,sk,ids(raw),user~=""and user or nil
end
local function policy(self,text,request)
 if text:match("^%d+$")then return visible(self,tonumber(text))end
 local row=printed_spec(text);if row then local b=known(self:getEvaluationCard(row.name),"printed source prototype");local c=self:evaluateTurnConversion(row.skill,b:getClassName(),row,request);recipes[c]=copy(row);return c end
 local cl,sk,costs,user=decode(text);local c=self:evaluateTurnSkillCard(sk,cl,costs,request,user);recipes[c]={prototype=cl,skill=sk,subcards=costs,user=user};return c
end
local function response(self,text)
 if type(text)~="string"or text=="."or text==""then return text end
 local wire,tos=text:match("^(.-)%->(.*)$");wire=wire or text;local c
 if wire:match("^%d+$")then c=visible(self,tonumber(wire))
 elseif wire:sub(1,1)=="@"or wire:sub(1,1)=="#"then local cl,sk,cs,u=decode(wire);c=self:bindSkillCard(sk,cs,nil,u,cl)
 else local row=known(printed_spec(wire),"source response wire");local base=known(self:getEvaluationCard(row.name),"response prototype");local pol=known(self:getConversionPolicy(base:getClassName()),"response policy");local entry
  for _,v in ipairs(pol.skills or{})do if v.skill_name==row.skill then entry=v;break end end
  c=known(self:resolveResponseConversion(row,known(entry,"response skill")),"response authority")
 end
 if AIValue.isConversion(c)then return{kind="use_card",card_spec=c:toCardSpec(),targets=tos and tos:split("+")or{}}end
 if __scarletayuhuo_value_call(c,"isVirtualCard")then ai_unsupported("selected physical response has no issued authority","scarletayuhuo")end
 return{kind="use_card",card_id=__scarletayuhuo_value_call(c,"getEffectiveId"),targets=tos and tos:split("+")or{}}
end
local function proposal(v)
 if type(v)~="string"or v=="."or v==""then return v end
 local row=printed_spec(v);if row then return row end
 local cl,sk,cs,u=decode(v);return{legacy_class=cl,skill=sk,subcards=cs,user_string=u}
end
local function can_to(self,c,from,to,targets)
 if from:objectName()~=self.player:objectName()then ai_unsupported("foreign hypothetical targetFilter lacks public rule contract","scarletayuhuo")end
 return self:cardTargetFilter(c,targets or{},to)
end
local function pending_tag(self,name,value)ai_unsupported("temporary yb_zhuzhan2 input requires pure callback adapter",name)end
local function private_draw(self)ai_unsupported("source inspects undisclosed draw-pile faces","zhachang")end
local function source_description(self,name)return known(known(self.world.strategy_facts.card_descriptions,"public card descriptions")[name],name)end
local function extra_targets(self,c)return known(self:getEvaluationCandidate(c):getExtraTargetCount(),"source extra target modifier")end
local function residue(self,c)return known(c:getTargetModResidue(self.player),"source residue")end
local function pingjian_catalog(self)return known(fact(self,"pingjian_skills"),"audited ordered AI skill catalog")end
local function pingjian_skill(self,name)local rows=known(fact(self,"pingjian_skill_descriptions"),"public skill descriptions");local text=rows[name];if text==false then return nil end;return{getDescription=function()return known(text,name)end}end
local function pingjian_play(self,name)return known(known(fact(self,"pingjian_enabled_at_play"),"temporary skill enabled facts")[name],name)end
local function state_encode(self,v)
 if v==nil then return{type="nil"}end
 if AIValue.isPlayer(v)then return{type="player",name=v:objectName()}end
 if AIValue.isCard(v)or AIValue.isConversion(v)then
  if recipes[v]then return{type="recipe",value=copy(recipes[v])}end
  if type(v.isEvaluationOnly)=="function"and v:isEvaluationOnly()then ai_unsupported("untracked readonly card cannot persist across snapshots","scarletayuhuo state")end
  return{type="card",id=__scarletayuhuo_value_call(v,"getEffectiveId")}
 end
 if type(v)~="table"then return{type="scalar",value=v}end
 local t={type="table",value={}};for k,x in pairs(v)do if type(x)~="function"then t.value[k]=state_encode(self,x)end end;return t
end
local function state_decode(self,v)
 if v.type=="nil"then return nil elseif v.type=="scalar"then return v.value elseif v.type=="player"then return known(self.room:findPlayerByObjectName(v.name,true),"cached target")elseif v.type=="card"then return visible(self,v.id)
 elseif v.type=="recipe"then local r=v.value;if r.prototype then return policy(self,(r.prototype:sub(1,1)=="#"and(r.prototype..":"..(#r.subcards>0 and table.concat(r.subcards,"+")or".")..":"..(r.user or""))or("@"..r.prototype.."="..(#r.subcards>0 and table.concat(r.subcards,"+")or".")..(r.user and":"..r.user or""))))end
 local c=self:evaluateOwnerViewAsCard(r);recipes[c]=copy(r);return c
 elseif v.type=="table"then local t={};for k,x in pairs(v.value)do t[k]=state_decode(self,x)end;if#t>0 then return AIList.new(t)end;return t end
 ai_unsupported("invalid source observation cache","scarletayuhuo")
end
local state_fields={'dahe_card','s_w_shenghun_card'}
local function load_state(self)
 if self._scarletayuhuo_state_loaded then return end;self._scarletayuhuo_state_loaded=true
 for _,k in ipairs(state_fields)do local r,ok=self:getStrategyMemory("scarletayuhuo."..k);if ok then self[k]=state_decode(self,r)end end

end
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~="table"then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function save_state(self)
 for _,k in ipairs(state_fields)do local prior,present=self:getStrategyMemory("scarletayuhuo."..k);local v=self[k]
  if present or v~=nil then local encoded=state_encode(self,v);if not present or not same(prior,encoded)then self:setStrategyMemory("scarletayuhuo."..k,encoded)end end
 end

end

local function BeMan(room,owner,dead)
 if AIValue.isPlayer(owner)then owner=owner:objectName()end
 for _,p in ipairs(known(room:getAllPlayers(),"registered room players"))do if p:objectName()==owner then return p end end
end
local function list_i2c(self,ids)local cards=AIList.new({});for _,id in ipairs(ids)do cards:append(visible(self,id))end;return cards end
local function source_patterns(self,class)
 local names=known(self.world.strategy_facts.pattern_names,"public pattern names")
 if type(class)~="string"then return names end
 local classes=known(self.world.strategy_facts.pattern_class_names,"public class-to-name catalog")
 return classes[class]or class
end
local function RandomList(items)
 local remaining={};for _,v in ipairs(items)do remaining[#remaining+1]=v end
 while #remaining>0 do local v=remaining[math.random(1,#remaining)];table.removeOne(remaining,v);table.removeOne(items,v);items[#items+1]=v end
 return items
end

local function set_observation_mark(self,key,value)
 self:setStrategyMemory("scarletayuhuo.mark:"..key,value)
end
local function observation_mark(self,key)
 local value,present=self:getStrategyMemory("scarletayuhuo.mark:"..key)
 if present then return value end
 return __scarletayuhuo_value_call(self.player,"getMark",key)
end
local function pattern_card(self,name)
 if type(ai_sample_pattern_log_name)~="function"then ai_unsupported("public PatternsCard sampling endpoint missing",name)end
 local result=ai_sample_pattern_log_name(name)
 if type(result)~="table"or result.kind~="pattern_log_name"or result.pattern~=name or type(result.found)~="boolean"then ai_unsupported("invalid PatternsCard sample",name)end
 if not result.found then return nil end
 return CardView.new(known(result.printed_card,"sampled printed descriptor"))
end

local function printed(self,id)return known(self:getPrintedCardById(id),"lawful printed card descriptor")end
local function set_observation(self,k,v)self:setStrategyMemory("scarletayuhuo.observation:"..k,v)end
local function room_tag(self,k,kind)
 if k:sub(1,3)=="ai_"then
  local v,ok=self:getStrategyMemory("scarletayuhuo.observation:"..k)
  if not ok then ai_unsupported("source room AI observation writer not seen",k)end
  if kind=="Player"then return v~=false and known(self.room:findPlayerByObjectName(v,true),k)or nil end
  return v~=false and v or(kind=="Int"and 0 or "")
 end
 return tag(self,k,kind)
end
local function room_data(self,k)return{toCardUse=function()return room_tag(self,k,"CardUse")end}end
local function history_use(self,id)
 local rows=fact(self,"use_history");local v=known(rows[id],"request-disclosed historical use");if v==false then return{to=AIList.new({})}end
 local targets=AIList.new({});for _,n in ipairs(v.to)do targets:append(known(self.room:findPlayerByObjectName(n,true),"history target"))end
 return{card=v.card and CardView.new(v.card),from=v.from and self.room:findPlayerByObjectName(v.from,true),to=targets}
end
local function foreign_property(self,p,k)
 if p:objectName()==self.player:objectName()then return property(self,k)end
 local rows=fact(self,"public_player_properties");return known(known(rows[p:objectName()],"public target properties")[k],k)
end
local function complete_hand(self,p)
 if p:objectName()==self.player:objectName()then return known(p:getHandcards(),"owner hand")end
 local cards=known(p:getKnownCards(),"known hand");if #cards~=__scarletayuhuo_value_call(p,"getHandcardNum")then ai_unsupported("source branch requires full foreign hand identity","scarletayuhuo.hand")end;return cards
end
local function viewer_role(self,p)
 local exact=p:getRole();if exact~=nil and exact~="unknown"and exact~="neutral"then return exact end
 local role=self:getRoleEstimate(p);if role==nil or role=="neutral"or role=="unknown"then ai_unsupported("source role unavailable from viewer knowledge","scarletayuhuo.role")end
 return self:useKnowledgeEstimate({value=role,status="estimate",basis="viewer_role_inference_replaces_private_role",viewer=self.player:objectName(),target=p:objectName()},"scarletayuhuo.role")
end
local function forbidden_foreign_ai(self)ai_unsupported("other AI private state is not available","scarletayuhuo")end
local function role_event(self,p,kind,role)
 local all=known(self.world.strategy_facts.role_row_update_witness,"public role event witness")
 local names=known(all[kind],kind);local present=false
 for _,name in ipairs(names)do if name==p:objectName()then present=true;break end end
 if not present then ai_unsupported("source role event target lacks public witness",kind)end
 if role~="lord"and role~="loyalist"and role~="rebel"and role~="renegade"then ai_unsupported("source role event inference unresolved",kind)end
 local assigned=kind=="Cjiyongbing"and role or(role=="rebel"and"loyalist"or role)
 self:emitStrategyEffect({kind="role_row_update",player=p:objectName(),role=role,assigned_role=assigned,assigned_value=kind=="Cjiyongbing"and 1000 or 0,source_skill=kind})
end

-- Only package-local authored CardUseStruct values, not an unrestricted native QVariant/tag gateway.
local function local_data()
 local value
 return{setValue=function(_,v)value=v end,toCardUse=function()return value or{to=AIList.new({})}end}
end

local function event_draw(data)
 if type(data)=="table"and type(data.toDraw)=="function"then return data:toDraw()end
 return known(type(data)=="table"and data.details and data.details.draw,"public DrawStruct event")
end
local function matches_source_pattern(self,pattern,card)
 local row=known(self:getDecisionContext().scarletayuhuo_pattern_matches,"source ExpPattern facts")
 if row.pattern~=pattern then ai_unsupported("source ExpPattern context mismatch","scarletayuhuo")end
 local result=known(row.by_id,"source pattern results")[tostring(card:getEffectiveId())]
 if type(result)~="boolean"then ai_unsupported("source ExpPattern match unknown","scarletayuhuo")end;return result
end
local function stage_delay(self,ms)self:stageSpeechDelay(ms,"scarletayuhuo:arkora")end
local function clear_source_mark(self,player,mark)
 ai_unsupported("source mark-clear writer/admission requires explicit event witness",mark)
end

-- These three source marks have no gameplay readers/writers; store only this viewer's visible-card observations.
local function public_count(self,p,k)
 local value,present=self:getStrategyMemory("scarletayuhuo.count:"..p:objectName()..":"..k)
 if present then return value end
 return __scarletayuhuo_value_call(p,"getMark",k)
end
local function set_public_count(self,p,k,v)self:setStrategyMemory("scarletayuhuo.count:"..p:objectName()..":"..k,v)end

local function sort_actor_keep(self,player,cards)
 if not AIValue.sameLegacyIdentity(player,self.player)then ai_unsupported("foreign AI keep cache is private","s_w_2_wenjiu")end
 local sorted=self:sortByKeepValue(cards)
 for i,c in ipairs(sorted)do cards[i]=c end
end
local function effect_data(self,k)
 local effect=room_tag(self,k,"CardEffect")
 return{toCardEffect=function()return effect end}
end

local function player_data(p)return{toPlayer=function()return p end}end

-- Fixed original-hegemony/heg-common-ai.lua:204-250. The Room-VM global
-- becomes one observer's atomic event memory; it never contains a Card object.
local aoe_memory_key="original_hegemony.aoe_stack"
local function aoe_enabled(self)
 local h=self.world.strategy_facts and self.world.strategy_facts.hegemony
 if type(h)~="table"or type(h.enabled)~="boolean"then ai_unsupported("hegemony load domain unknown","ai_AOE_data")end
 if not h.enabled then return false end
 if type(h.original_overrides_loaded)~="boolean"then ai_unsupported("original AOE writer load state unknown","ai_AOE_data")end
 return h.original_overrides_loaded
end
local function aoe_stack(self)
 local value,present=self:getEventMemory(aoe_memory_key)
 if not present then ai_unsupported("initial AOE observation history is unknown","ai_AOE_data")end
 if type(value)~="table"then ai_unsupported("AOE stack state malformed","ai_AOE_data")end
 local copy={}
 for i,row in ipairs(value)do
  if type(row)~="table"or type(row.identity)~="string"or type(row.confirmed)~="boolean"or type(row.relevant)~="boolean"then ai_unsupported("AOE frame malformed","ai_AOE_data")end
  copy[i]={identity=row.identity,confirmed=row.confirmed,relevant=row.relevant,targets={}}
  for name,v in pairs(row.targets or{})do copy[i].targets[name]=v end
 end
 return copy
end
local function aoe_card(event)
 local row=event.details and event.details.card
 if row==nil then return nil end
 local card=CardView.new(row)
 if not known(card:isKindOf("AOE"),"ai_AOE_data.card")then return nil end
 local identity=card:getLegacyIdentityToken()
 if type(identity)~="string"or identity==""then ai_unsupported("AOE native identity is missing","ai_AOE_data.identity")end
 return card,identity
end
local function aoe_frame(identity)return{identity=identity,targets={},confirmed=false,relevant=false}end
local function aoe_shown(self,name,skill)
 local h=self.world.strategy_facts.hegemony
 local row=h.players and h.players[name]
 if type(row)~="table"or type(row.shown_skills)~="table"then ai_unsupported("AOE public shown skills unknown","ai_AOE_data.shown_skills")end
 return row.shown_skills[skill]~=nil
end
local function aoe_initialize(self)
 if aoe_enabled(self)then
  local _,present=self:getEventMemory(aoe_memory_key)
  if not present then self:setEventMemory(aoe_memory_key,{})end
 end
end
local function aoe_prepare(self,player,event)
 if not aoe_enabled(self)then return end
 local card,identity=aoe_card(event)
 if not card or not event.from or event.from==""or not player or player:objectName()~=event.from then return end
 local stack=aoe_stack(self);local top=stack[#stack]
 if not top or top.identity~=identity or top.confirmed then stack[#stack+1]=aoe_frame(identity)end
 self:setEventMemory(aoe_memory_key,stack)
end
local function aoe_confirm(self,player,event)
 if not aoe_enabled(self)then return end
 local card,identity=aoe_card(event);if not card then return end
 local stack=aoe_stack(self);local top=stack[#stack]
 if not top or top.identity~=identity then top=aoe_frame(identity);stack[#stack+1]=top end
 top.targets,top.relevant,top.confirmed={},false,true
 if type(event.targets)~="table"then ai_unsupported("AOE targets are not projected","ai_AOE_data.targets")end
 for _,name in ipairs(event.targets)do
  top.targets[name]=true
  if aoe_shown(self,name,"mobilefangzhu")or(known(card:isKindOf("ArcheryAttack"),"ai_AOE_data.card")and aoe_shown(self,name,"guidao")and aoe_shown(self,name,"nosleiji"))then top.relevant=true end
 end
 self:setEventMemory(aoe_memory_key,stack)
end
local function aoe_finish(self,player,event)
 if not aoe_enabled(self)then return end
 local card,identity=aoe_card(event);if not card then return end
 local stack=aoe_stack(self)
 for i=#stack,1,-1 do if stack[i].identity==identity then table.remove(stack,i);break end end
 self:setEventMemory(aoe_memory_key,stack)
end
for event,callback in pairs({[sgs.PreCardUsed or "PreCardUsed"]=aoe_prepare,
 [sgs.TargetConfirmed or "TargetConfirmed"]=aoe_confirm,[sgs.CardFinished or "CardFinished"]=aoe_finish})do
 sgs.ai_event_callback[event]=sgs.ai_event_callback[event]or{}
 sgs.ai_event_callback[event].original_hegemony=callback
end
sgs.ai_event_callback[sgs.GameReady or "GameReady"]=sgs.ai_event_callback[sgs.GameReady or "GameReady"]or{}
sgs.ai_event_callback[sgs.GameReady or "GameReady"].scarlet_aoe_initialize=aoe_initialize
function SmartAIView:getObservedAOETruth()
 if not aoe_enabled(self)then return false end
 local stack=aoe_stack(self);local top=stack[#stack]
 return top~=nil and top.confirmed and top.relevant
end
local function aoe_truth(self)return self:getObservedAOETruth()end

local function response_source(self,key)
 local name,present=self:getStrategyMemory("response_source:"..key)
 if not present or name==false or name==nil then return nil end
 if type(name)~="string"then ai_unsupported("invalid allied response source",key)end
 return known(self.room:findPlayerByObjectName(name,true),key)
end
sgs.ai_fill_skill["s_anren"] = function(self,inclusive,request)
	if (__scarletayuhuo_value_call(self.player,"getHandcardNum")+self.player:getEquips():length()) < 1 then return nil end
	if self.player:hasUsed("#s_anren") then return nil end
	local card
	if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		hcards = self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:isBlack() then
				card = hcard
				break
			end
		end
	end
	if card then
		return policy(self,"#s_anren:.:")
	end
end

sgs.ai_skill_use_func["#s_anren"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "defense")
	local target = nil
	local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
			and enemy:objectName() ~= self.player:objectName() then
			target = enemy
			break
		end
	end
	local card
	if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		hcards = self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:isBlack() then
				card = hcard
				break
			end
		end
	end
	if card then
		if target then
			use.card = policy(self,"#s_anren:" .. card:getId() .. ":")
			if use.to then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_use_value["s_anren"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["s_anren"] = sgs.ai_use_priority.Slash - 0.2


sgs.ai_skill_invoke.s_nixing = function(self, data)
	local dmg = data:toDamage()
	if self:damageStruct(dmg) and self:needToLoseHp(dmg.to, dmg.from, dmg.card) then
		return false
	end
	return true
end

function sgs.ai_cardneed.s_wuqiang(to, card, self)
	local slash = __scarletayuhuo_value_call(card,"isKindOf","Slash")
	if self.player:getWeapon() then
		return (slash and getKnownCard(to, self.player, "Slash", false) == 0)
	else
		return (__scarletayuhuo_value_call(card,"isKindOf","Weapon") and card:getRealCard():toWeapon():getRange() > 2)
	end
end

local biaoqiSlashCard = function(pile)
	if #pile > 0 then return pile[1] end
	return nil
end


sgs.ai_fill_skill["s_biaoqiSlash"] = function(self,inclusive,request)
	if #self.enemies == 0 then return end
	return policy(self,"#s_biaoqiSlash:.:")


end

sgs.ai_skill_use_func["#s_biaoqiSlash"] = function(card, use, self)
	local slash = clone(self,"slash")
	local target
	local players = self.room:getOtherPlayers(self.player)
	for _, p in sgs.qlist(players) do
		if p and self:isEnemy(p) and (p:getPile("s_yong"):length() > 0) and self.player:canSlash(p) and self:canHit(p, self.player) then
			use.card = card
			use.card = mutate(self,use.card,"add",p:getPile("s_yong"):first())
			if use.to then use.to:append(p) end
		end
	end



end

sgs.ai_card_intention["#s_biaoqislash"] = function(self, card, from, tos)
	local slash = clone(self,"slash")
	if not self:slashIsEffective(slash, tos[1], from) then
		self:updateIntention(from, tos[1], -30)
	else
		return sgs.ai_card_intention.Slash(self, slash, from, tos)
	end
end


sgs.ai_fill_skill["s_w_yongjin"] = function(self,inclusive,request)
	if not known(self:slashIsAvailable(self.player),"Slash availability") or __scarletayuhuo_value_call(self.player,"getMark","&s_w_yongjin") < 1 then return end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards, true)
	for _, carda in ipairs(cards) do
		if __scarletayuhuo_value_call(carda,"isKindOf","Slash") then
			return
		end
	end

	local card_str = ("slash:s_w_yongjin[no_suit:0]=.")
	local card = policy(self,card_str)
	return card
end


sgs.ai_view_as.s_w_yongjin = function(card, player, card_place)
 local self=known(known(player:getRoom(),"view-as room")._ai,"view-as AI context")
	if __scarletayuhuo_value_call(player,"getMark","&s_w_yongjin") < 1 then return end
	local cards = complete_hand(self,player)
	cards = sgs.QList2Table(cards)
	for _, carda in ipairs(cards) do
		if __scarletayuhuo_value_call(carda,"isKindOf","Slash") then
			return
		end
	end
	return ("slash:s_w_yongjin[no_suit:0]=.")
end

sgs.ai_use_value["s_w_yongjin"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["s_w_yongjin"] = sgs.ai_use_priority.Slash - 0.5


sgs.ai_fill_skill["s_w_zhitui"] = function(self,inclusive,request)
	local card = clone(self,"peach", sgs.Card_NoSuit, 0)
	card:deleteLater()
	if not __scarletayuhuo_value_call(card,"isAvailable",self.player) or __scarletayuhuo_value_call(self.player,"getMark","&s_w_zhitui") < 1 then return end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards, true)
	for _, carda in ipairs(cards) do
		if __scarletayuhuo_value_call(carda,"isKindOf","peach") then
			return
		end
	end
	return policy(self,("peach:s_w_zhitui[no_suit:0]=."))
end

sgs.ai_view_as.s_w_zhitui = function(card, player, card_place, class_name)
 local self=known(known(player:getRoom(),"view-as room")._ai,"view-as AI context")
	if class_name == "Jink" then
		if __scarletayuhuo_value_call(player,"getMark","&s_w_zhitui") < 1 then return end
		local cards = complete_hand(self,player)
		cards = sgs.QList2Table(cards)
		for _, carda in ipairs(cards) do
			if __scarletayuhuo_value_call(carda,"isKindOf","Jink") then
				return
			end
		end

		return ("jink:s_w_zhitui[no_suit:0]=.")
	elseif class_name == "Peach" and __scarletayuhuo_value_call(player,"getMark","Global_PreventPeach") == 0 then
		if __scarletayuhuo_value_call(player,"getMark","&s_w_zhitui") < 1 then return end
		local cards = complete_hand(self,player)
		cards = sgs.QList2Table(cards)
		for _, carda in ipairs(cards) do
			if __scarletayuhuo_value_call(carda,"isKindOf","Peach") then --null部分有问题
				return
			end
		end
		return ("peach:s_w_zhitui[no_suit:0]=.")
	end
end
sgs.ai_use_value["s_w_zhitui"] = sgs.ai_use_value.Peach
sgs.ai_use_priority["s_w_zhitui"] = sgs.ai_use_priority.Peach - 0.5

sgs.ai_skill_choice["s_w_jianxiong"] = function(self, choices, data)
	local damage = data:toDamage()
	local items = choices:split("+")
	if not damage.card then return "draw" end
	if table.contains(items, "obtain") and self:isWeak() and __scarletayuhuo_value_call(self.player,"hasSkill","s_w_qipao") and sgs.ai_skill_cardask["#s_w_qipao"](self, data) ~= "." then return "obtain" end
	if __scarletayuhuo_value_call(damage.card,"isKindOf","Slash") and not self:hasCrossbowEffect() and self:getCardsNum("Slash") > 0 then return
		"draw" end
	if self:isWeak() and (self:getCardsNum("Slash") > 0 or not __scarletayuhuo_value_call(damage.card,"isKindOf","Slash") or __scarletayuhuo_value_call(self.player,"getHandcardNum") <= __scarletayuhuo_value_call(self.player,"getHp")) then return
		"draw" end
	if table.contains(items, "obtain") then return "obtain" end
	return items[1]
end

sgs.ai_target_revises.s_w_jianxiong = function(to,card,self)
	if __scarletayuhuo_value_call(card,"isDamageCard")
	and not self:isFriend(to)
	and card:subcardsLength()>0
	then
		for _,id in sgs.list(card:getSubcards())do
			if isCard("Peach,Analeptic",visible(self,id),to)
			then return true end
		end
	end
end

sgs.ai_can_damagehp.s_w_jianxiong = function(self, from, card, to)
	if from and __scarletayuhuo_value_call(to,"getHp") + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return __scarletayuhuo_value_call(card,"isKindOf","Duel") or __scarletayuhuo_value_call(card,"isKindOf","AOE")
	end
end

sgs.ai_skill_invoke.s_w_geran = function(self, data)
	local damage = data:toDamage()
	local target = damage.from
	if target then
		return self:doDisCard(target, "he")
	end
	return false
end

sgs.ai_skill_invoke.s_w_qipao = function(self, data)
	local damage = data:toDamage()
	local zhangjiao = self.room:findPlayerBySkillName("guidao")
	if zhangjiao and self:isEnemy(zhangjiao) then
		if getKnownCard(zhangjiao, self.player, "black", false, "he") > 1 then return false end
		if self:getCardsNum("Jink") > 1 and getKnownCard(zhangjiao, self.player, "black", false, "he") > 0 then return false end
	end
	return true
end

sgs.ai_skill_cardask["#s_w_qipao"] = function(self, data)
	local red = 0
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if c:isRed() then
			red = red + 1
		end
	end
	if (red == 0) and not self:isWeak(self.player) then return "." end

	local cards = {}
	local use_cards = {}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if self.player:canDiscard(self.player, c:getId()) and c:isRed() and (#cards < 2) then
			table.insert(cards, c)
		end
	end
	if #cards < 2 then return "." end
	if __scarletayuhuo_value_call(self.player,"getHp") > getBestHp(self.player) then return "." end
	cards = self:sortByKeepValue(cards)
	table.insert(use_cards, __scarletayuhuo_value_call(cards[1],"getEffectiveId"))
	table.insert(use_cards, __scarletayuhuo_value_call(cards[2],"getEffectiveId"))
	return "$"..table.concat(use_cards, "+")
end




sgs.ai_fill_skill["s_w_wushuang"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local red_card
	cards = self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if not __scarletayuhuo_value_call(card,"isKindOf","Slash") and not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not isCard("Analeptic", card, self.player) then
			red_card = card
			break
		end
	end

	if red_card then
		local suit = __scarletayuhuo_value_call(red_card,"getSuitString")
		local number = red_card:getNumberString()
		local card_id = __scarletayuhuo_value_call(red_card,"getEffectiveId")
		local card_str = ("slash:s_w_wushuang[%s:%s]=%d"):format(suit, number, card_id)
		local slash = policy(self,card_str)

		assert(slash)
		return slash
	end
end
sgs.ai_card_priority.s_w_wushuang = function(self,card,v)
	if table.contains(card:getSkillNames(), "s_w_wushuang")
	then return 1 end
end


sgs.ai_skill_discard["s_w_tongling"] = function(self, discard_num, min_num, optional, include_equip)
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	usable_cards = self:sortByKeepValue(usable_cards)
	local to_discard = {}
	for _, c in ipairs(usable_cards) do
		if #to_discard < discard_num and __scarletayuhuo_value_call(c,"isKindOf","BasicCard") and not __scarletayuhuo_value_call(c,"isKindOf","Peach") then
			table.insert(to_discard, __scarletayuhuo_value_call(c,"getEffectiveId"))
		end
	end
	if #to_discard > 0 then
		return to_discard
	end
end

sgs.ai_skill_use["@@s_ling"] = function(self, prompt)
	self:updatePlayers()
	local cards = self.player:getPile("s_ling")
	cards = sgs.QList2Table(cards)
	local card = cards[1]
	self.enemies = self:sort(self.enemies, "defense")
	local current = self.room:getCurrent()

	if current and self:isFriend(current) and not current:getCards("e"):isEmpty() and self:hasSkills(sgs.lose_equip_skill, current) then
		return ("#s_w_jiejiang:%d:"):format(card)
	end

	if current and self:isEnemy(current) then
		if not current:getCards("e"):isEmpty() and self:hasSkills(sgs.lose_equip_skill, current) then
			return "."
		end
		return ("#s_w_jiejiang:%d:"):format(card)
	end
	return "."
end


sgs.ai_skill_discard["s_w_jiejiang_q"] = function(self, discard_num, min_num, optional, include_equip)
	local usable_cards = sgs.QList2Table(self.player:getCards("e"))
	usable_cards = self:sortByKeepValue(usable_cards)
	local to_discard = {}
	for _, c in ipairs(usable_cards) do
		if #to_discard < 1 then
			table.insert(to_discard, __scarletayuhuo_value_call(c,"getEffectiveId"))
		end
	end
	if #to_discard > 0 then
		for _, player in sgs.qlist(self.room:getAllPlayers()) do
			if __scarletayuhuo_value_call(player,"hasFlag","s_w_jiejiang") then
				player:obtainCard(to_discard[1])
			end
		end
		return to_discard
	end
end


function sgs.ai_cardneed.s_w_shenyong(to, card, self)
	return __scarletayuhuo_value_call(card,"isKindOf","Slash")
end

sgs.ai_canliegong_skill.s_w_shenyong = function(self, from, to)
	return true
end

sgs.ai_ajustdamage_from.s_w_nilin = function(self, from, to, card, nature)
	if card and __scarletayuhuo_value_call(card,"isKindOf","Slash") and __scarletayuhuo_value_call(from,"getPhase") ~= sgs.Player_NotActive
	then
		return __scarletayuhuo_value_call(to,"getMark","&s_w_nilin+to+#"..from:objectName())
	end
end
sgs.ai_ajustdamage_to.s_w_juling = function(self, from, to, card, nature)
	if nature ~= "N" then
		return -99
	end
end





sgs.ai_skill_invoke.s_w_qimou_give = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.s_w_qimou = function(self, data)
	local damage = data:toDamage()

	if not __scarletayuhuo_value_call(damage.to,"faceUp") then
		return self:isFriend(damage.to)
	end

	local good = __scarletayuhuo_value_call(damage.to,"getHp") > 2
	if self:isFriend(damage.to) then
		return good
	elseif self:isEnemy(damage.to) then
		if not __scarletayuhuo_value_call(damage.to,"hasSkill","xiongshou") then
			return not good
		end
	end
end

sgs.ai_choicemade_filter.skillInvoke.s_w_qimou = function(self, player, promptlist)
	local intention = 60
	local index = promptlist[#promptlist] == "yes" and 1 or -1
	local damage = room_tag(self,"CurrentDamageStruct","Damage")
	if damage.from and damage.to then
		if not __scarletayuhuo_value_call(damage.to,"faceUp") then
			intention = index * intention
		elseif __scarletayuhuo_value_call(damage.to,"getHp") > 2 then
			intention = -index / 2 * intention
		elseif index == -1 then
			intention = -20
		end
		self:updateIntention(damage.from, damage.to, intention)
	end
end

sgs.ai_fill_skill["s_w_qimou"] = function(self,inclusive,request)
	if (__scarletayuhuo_value_call(self.player,"getMark","@s_mou") == 0) then return end
	if self:needBear() then return end
	if #self.enemies == 0 then return end
	if known(self:getRoleEstimate(self.player),"role estimate")=="neutral" then return end
	return policy(self,"#s_w_qimouCard:.:")
end
sgs.ai_skill_use_func["#s_w_qimouCard"] = function(card, use, self)
	local target
	for _, friend in ipairs(self.friends_noself) do
		if friend and not friend:isKongcheng() then
			if self:needKongcheng(friend) then
				target = friend
				break
			end
			if not self:isWeak(friend) then
				target = friend
				break
			end
		end
	end
	local enemies = self.enemies
	local selfDef = sgs.getDefense(self.player)
	local can_slash = false
	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = clone(self,"slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif def < 6 and eff then
			can_slash = true
		end
	end
	if target and can_slash then
		local card_str = ("#s_w_qimouCard:.:")
		use.card = policy(self,card_str)
		if use.to then use.to:append(target) end
	end
end
sgs.ai_use_priority["s_w_qimouCard"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_playerchosen.s_w_qimou = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end


sgs.ai_fill_skill["s_w_shenghun"] = function(self,inclusive,request)
	if self.player:hasUsed("#s_w_shenghun") or self.player:isKongcheng() then return end
	return policy(self,"#s_w_shenghun:.:")
end

sgs.ai_skill_use_func["#s_w_shenghun"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = __scarletayuhuo_value_call(max_card,"getNumber")
	local slashcount = self:getCardsNum("Slash")
	if __scarletayuhuo_value_call(max_card,"isKindOf","Slash") then slashcount = slashcount - 1 end

	if slashcount > 0 then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = self:aiUseCard(slash, dummy_plan())
		if dummy_use.card and dummy_use.to:length() > 0 then
			for _, enemy in sgs.qlist(dummy_use.to) do
				if not (__scarletayuhuo_value_call(enemy,"hasSkill","kongcheng") and __scarletayuhuo_value_call(enemy,"getHandcardNum") == 1) and not enemy:isKongcheng() and self:canAttack(enemy, self.player) and __scarletayuhuo_value_call(self.player,"canPindian",enemy)
					and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
					local enemy_max_card = self:getMaxCard(enemy)
					local enemy_max_point = enemy_max_card and __scarletayuhuo_value_call(enemy_max_card,"getNumber") or 100
					if max_point > enemy_max_point then
						use.card = policy(self,"#s_w_shenghun:.:")
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if not (__scarletayuhuo_value_call(enemy,"hasSkill","kongcheng") and __scarletayuhuo_value_call(enemy,"getHandcardNum") == 1) and not enemy:isKongcheng() and self:canAttack(enemy, self.player) and __scarletayuhuo_value_call(self.player,"canPindian",enemy)
					and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
					if max_point >= 10 then
						use.card = policy(self,"#s_w_shenghun:.:")
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByUseValue(cards, true)
	if (self:getUseValue(cards[1]) < 6 and self:getKeepValue(cards[1]) < 6) or self:getOverflow() > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not (__scarletayuhuo_value_call(enemy,"hasSkill","kongcheng") and __scarletayuhuo_value_call(enemy,"getHandcardNum") == 1) and not enemy:isKongcheng() and not hasTuntianEffect(enemy, true) and __scarletayuhuo_value_call(self.player,"canPindian",enemy) then
				use.card = policy(self,"#s_w_shenghun:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_cardneed.s_w_shenghun = function(to, card, self)
	local cards = complete_hand(self,to)
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if __scarletayuhuo_value_call(c,"hasFlag","visible") or __scarletayuhuo_value_call(c,"hasFlag",flag) then
			if __scarletayuhuo_value_call(c,"getNumber") > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return __scarletayuhuo_value_call(card,"getNumber") > 10
	else
		return __scarletayuhuo_value_call(card,"isKindOf","Slash") and card:isRed()
	end
end

function sgs.ai_skill_pindian.s_w_shenghun(minusecard, self, requestor)
	if __scarletayuhuo_value_call(requestor,"getHandcardNum") == 1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		cards = self:sortByKeepValue(cards)
		return cards[1]
	end
	if __scarletayuhuo_value_call(requestor,"getHandcardNum") <= 2 then return minusecard end
end

sgs.ai_card_intention["s_w_shenghun"] = 70


sgs.ai_use_value["s_w_shenghun"] = 9.2
sgs.ai_use_priority["s_w_shenghun"] = 9.2


sgs.ai_ajustdamage_from["s_w_wenjiu"]   = function(self, from, to, card, nature)
	if card and __scarletayuhuo_value_call(card,"isKindOf","Slash") and card:isRed() and __scarletayuhuo_value_call(from,"getMark","s_w_wenjiu-PlayClear") == 0 then
		return 1
	end
end



sgs.ai_skill_invoke.s_w_juezhan_buqu = function(self, data)
	return true
end

sgs.ai_skill_invoke.s_w_juezhan_tuxi = function(self,prompt)
	local tuxi_string = sgs.ai_skill_use["@@tenyeartuxi"](self, prompt)
	if tuxi_string == "." then
		return false
	end
	return true
end


sgs.ai_skill_invoke.s_w_juezhan_wushuang1 = function(self, data)
	if (__scarletayuhuo_value_call(self.player,"getMark","&s_w_yong") < 3) then return false end
	local use = data:toCardUse()
	for _, t in sgs.qlist(use.to) do
		if t and self:isEnemy(t) then
			return true
		end
	end
	return false
end

sgs.ai_skill_invoke.s_w_juezhan_wushuang2 = function(self, data)
	if (__scarletayuhuo_value_call(self.player,"getMark","&s_w_yong") < 3) then return false end
	local effect = data:toCardEffect()
	if effect.from and __scarletayuhuo_value_call(effect.from,"hasSkill","s_w_juezhan") then
		if effect.to and self:isFriend(effect.to) then
			return false
		end
	end
	if effect.to and __scarletayuhuo_value_call(effect.to,"hasSkill","s_w_juezhan") then
		if effect.from and self:isFriend(effect.from) then
			return false
		end
	end
	return true
end

sgs.ai_skill_use["@@s_w_changshu"] = function(self, prompt, method)
	if self:getOverflow() > 0 then
		local target
		self.friends_noself = self:sort(self.friends_noself, "hp")
		if #self.friends_noself > 0 then
			for _, friend in ipairs(self.friends_noself) do
				if getBestHp(friend) < __scarletayuhuo_value_call(friend,"getHp") and not hasManjuanEffect(friend) then
					target = friend
					break
				end
			end
			if not target then
				for _, friend in ipairs(self.friends_noself) do
					if (friend:hasSkills(sgs.notActive_cardneed_skill) or friend:hasSkills(sgs.Active_cardneed_skill)) and not hasManjuanEffect(friend) then
						target = friend
						break
					end
				end
			end
			if not target then
				for _, friend in ipairs(self.friends_noself) do
					if not hasManjuanEffect(friend) then
						target = friend
						break
					end
				end
			end
		end
		if target then
			local hcards = self.player:getCards("he")
			hcards = sgs.QList2Table(hcards)
			hcards = self:sortByUseValue(hcards, true)
			local use_card = {}
			local heartcard = {}
			local x = math.min(__scarletayuhuo_value_call(self.player,"getLostHp"), __scarletayuhuo_value_call(target,"getLostHp"))
			for _, c in ipairs(hcards) do
				if __scarletayuhuo_value_call(c,"getSuit") == sgs.Card_Heart and #heartcard < x then
					table.insert(heartcard, __scarletayuhuo_value_call(c,"getEffectiveId"))
				end
				table.insert(use_card, __scarletayuhuo_value_call(c,"getEffectiveId"))
				if #use_card >= 5 then
					break
				end
			end
			if #use_card > 0 then
				return "#s_w_changshu:" .. table.concat(use_card, "+") .. ":->" .. target:objectName()
			end
		end
	end
	return "."
end

sgs.ai_cardneed.s_w_yuma = function(to, card, self)
	local cards = to:getCards("e")
	if not to:getOffensiveHorse() then
		return __scarletayuhuo_value_call(card,"isKindOf","OffensiveHorse")
	elseif not to:getDefensiveHorse() then
		return __scarletayuhuo_value_call(card,"isKindOf","DefensiveHorse")
	end
end


function sgs.ai_cardsview.s_w_2_wenjiu(self, class_name, player)
	if class_name == "Analeptic" then
		local cards = complete_hand(self,player)
		cards = sgs.QList2Table(cards)
		local newcards = {}
		for _, card in ipairs(cards) do
			if not isCard("Analeptic", card, player) and not isCard("Peach", card, player) and not (isCard("ExNihilo", card, player)) then
				table.insert(newcards, card) end
		end
		if #newcards < 2 then return end
		sort_actor_keep(self,player,newcards)

		local first_found, second_found = false, false
		local first_card, second_card
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Analeptic", fcard, player) or isCard("Peach", fcard, player) or (isCard("ExNihilo", fcard, player)))
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Analeptic", scard, player) or isCard("Peach", scard, player) or (isCard("ExNihilo", scard, player)))
					if not AIValue.sameLegacyIdentity(first_card,scard) and __scarletayuhuo_value_call(scard,"getSuit") == __scarletayuhuo_value_call(first_card,"getSuit")
						and not svalueCard then
						local card_str = ("analeptic:%s[%s:%s]=%d+%d"):format("s_w_2_wenjiu", "to_be_decided", 0,
							first_card:getId(), scard:getId())
						second_card = scard
						second_found = true
						break
					end
				end
			end
			if second_card then break end
		end
		if first_found and second_found then
			local first_id = first_card:getId()
			local second_id = second_card:getId()
			local card_str = ("analeptic:%s[%s:%s]=%d+%d"):format("s_w_2_wenjiu", "to_be_decided", 0, first_id, second_id)
			return card_str
		end
	end
end

sgs.ai_fill_skill["s_w_2_wenjiu"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards)
	local newcards = {}
	for _, card in ipairs(cards) do
		if not isCard("Analeptic", card, self.player) and not isCard("Peach", card, self.player) and not (isCard("ExNihilo", card, self.player) and __scarletayuhuo_value_call(self.player,"getPhase") == sgs.Player_Play) then
			table.insert(newcards, card) end
	end
	if #cards <= __scarletayuhuo_value_call(self.player,"getHp") - 1 and __scarletayuhuo_value_call(self.player,"getHp") <= 4 and not self:hasSkills("kongcheng|lianying|noslianying|shangshi|noshangshi") then return end
	if #newcards < 2 then return end

	local first_found, second_found = false, false
	local first_card, second_card
	for _, fcard in ipairs(cards) do
		local fvalueCard = (isCard("Analeptic", fcard, self.player)) or isCard("Peach", fcard, self.player) or (isCard("ExNihilo", fcard, self.player) )
		if not fvalueCard then
			first_card = fcard
			first_found = true
			for _, scard in ipairs(cards) do
				local svalueCard = (isCard("Analeptic", scard, self.player)) or isCard("Peach", scard, self.player) or (isCard("ExNihilo", scard, self.player))
				if not AIValue.sameLegacyIdentity(first_card,scard) and __scarletayuhuo_value_call(scard,"getSuit") == __scarletayuhuo_value_call(first_card,"getSuit")
					and not svalueCard then
					local card_str = ("analeptic:%s[%s:%s]=%d+%d"):format("s_w_2_wenjiu", "to_be_decided", 0,
						first_card:getId(), scard:getId())
					second_card = scard
					second_found = true
					break
				end
			end
		end
		if second_card then break end
	end
	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("analeptic:%s[%s:%s]=%d+%d"):format("s_w_2_wenjiu", "to_be_decided", 0, first_id, second_id)
		local analeptic = policy(self,card_str)
		return analeptic
	end
end


sgs.ai_skill_invoke.s_w_shouyou = function(self, data)
	local damage = data:toDamage()
	if damage.to and self:isFriend(damage.to) then
		return true
	end
	return false
end



sgs.ai_skill_playerchosen.s_w_shenzi = function(self, targets)
	local x = __scarletayuhuo_value_call(self.player,"getLostHp") + 2
	if x == 2 and self.player:getJudgingArea():length() == 0 then
		return nil
	end
	self.friends_noself = self:sort(self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _, friend in ipairs(self.friends_noself) do
		if (friend:hasSkills(sgs.notActive_cardneed_skill) or friend:hasSkills(sgs.Active_cardneed_skill)) and not hasManjuanEffect(friend) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend, self.player) then
			return friend
		end
	end
	return targets[1]
end



sgs.ai_used_revises.s_w_wuqian = function(self,use)
	if __scarletayuhuo_value_call(use.card,"isKindOf","Slash")
	and not use.isDummy
	then
		for _,to in sgs.list(use.to)do
			if self:isEnemy(to) and self:isWeak(to)
			and __scarletayuhuo_value_call(to,"getMark","Armor_Nullified")<1
			and __scarletayuhuo_value_call(self.player,"getMark","&wrath")>=__scarletayuhuo_value_call(to,"getHp")
			then
				use.card = policy(self,"#s_w_wuqian:.:")
				use.to = AIList.new({})
				use.to:append(to)
				return false
			end
		end
	end
end
sgs.ai_fill_skill["s_w_wuqian"] = function(self,inclusive,request)
	if self.player:hasUsed("#s_w_wuqian") or __scarletayuhuo_value_call(self.player,"getMark","&wrath") < 2 then return end
	return policy(self,"#s_w_wuqian:.:")
end

sgs.ai_skill_use_func["#s_w_wuqian"] = function(wuqiancard, use, self)
	if self:getCardsNum("Slash") > 0 and not __scarletayuhuo_value_call(self.player,"hasSkill","wushuang") then
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if isCard("Duel", card, self.player) then
				local dummy_use = self:aiUseCard(card, dummy_plan())
				if dummy_use.card and dummy_use.to:length() > 0 and (self:isWeak(dummy_use.to:first()) or dummy_use.to:length() > 1) then
					use.card = wuqiancard
					if use.to then use.to:append(dummy_use.to:first()) end
					return
				end
			end
		end
	end
end

sgs.ai_use_value["s_w_wuqian"] = 5
sgs.ai_use_priority["s_w_wuqian"] = 10
sgs.ai_card_intention["s_w_wuqian"] = 80

sgs.ai_use_revises.s_w_wumou = function(self,card,use)
	if card:isNDTrick() and __scarletayuhuo_value_call(self.player,"getMaxHp") < 4
	then
        if not (__scarletayuhuo_value_call(card,"isKindOf","AOE") or __scarletayuhuo_value_call(card,"isKindOf","IronChain") or __scarletayuhuo_value_call(card,"isKindOf","Drowning"))
        and not (__scarletayuhuo_value_call(card,"isKindOf","Duel") and getCardsNum("Peach")>0)
		then return false end
	end
end
sgs.ai_skill_choice.s_w_wumou = function(self, choices)
	if __scarletayuhuo_value_call(self.player,"getMaxHp") >= __scarletayuhuo_value_call(self.player,"getHp") + 2 then
		if __scarletayuhuo_value_call(self.player,"getMaxHp") > 5 and (self.player:hasSkills("nosmiji|yinghun|juejing|zaiqi|nosshangshi") or __scarletayuhuo_value_call(self.player,"hasSkill","miji") and self:findPlayerToDraw(false)) then
			local enemy_num = 0
			for _, p in ipairs(self.enemies) do
				if __scarletayuhuo_value_call(p,"inMyAttackRange",self.player) and not self:willSkipPlayPhase(p) then enemy_num = enemy_num + 1 end
			end
			local ls = self:getStrategyMemory("fangquan_effect") and self.room:findPlayerBySkillName("fangquan")
			if ls then
				self:setStrategyMemory("fangquan_effect",false)
				enemy_num = self:getEnemyNumBySeat(ls, self.player, self.player)
			end
			local least_hp = isLord(self.player) and math.max(2, enemy_num - 1) or 1
			if (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + __scarletayuhuo_value_call(self.player,"getHp") > least_hp) then return
				"hp" end
		end
		return "maxhp"
	else
		return "hp"
	end
end

sgs.ai_skill_discard["s_w_guishen"] = function(self, discard_num, min_num, optional, include_equip)
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	usable_cards = self:sortByKeepValue(usable_cards)
	local to_discard = {}
	if __scarletayuhuo_value_call(self.player,"getHp") < 4 then
		for _, c in ipairs(usable_cards) do
			if #to_discard < discard_num and not __scarletayuhuo_value_call(c,"isKindOf","Peach") then
				table.insert(to_discard, __scarletayuhuo_value_call(c,"getEffectiveId"))
			end
		end
	end
	return {}
end


sgs.ai_skill_invoke.s_w_youhuo = true
sgs.ai_skill_choice.s_w_youhuo = function(self, choices, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		if damage.damage == 1 then
			return "s_w_youhuo_draw"
		else
			return "s_w_youhuo_recover"
		end
	end
	return "s_w_youhuo_draw"
end
sgs.ai_skill_playerchosen.s_w_juese = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if __scarletayuhuo_value_call(player,"isLord") then lord = player end
		if self:isEnemy(player) and (not target or __scarletayuhuo_value_call(target,"getHp") < __scarletayuhuo_value_call(player,"getHp")) then
			target = player
		end
	end
	if target then return target end
	targetlist = self:sort(targetlist, "hp")
	if lord then
		return lord
	end
	return targetlist[1]
end

sgs.ai_skill_invoke.s_w_yanzi = function(self, data)
	if self:isFriend(data:toPlayer()) and self:willSkipPlayPhase(data:toPlayer()) then
		return math.random() < 0.5
	end
    return true
end
sgs.ai_skill_choice.s_w_yanzi_disMark = function(self, choices, data)
	local target = data:toPlayer()
	if target then
		local x = __scarletayuhuo_value_call(target,"getMark","&s_w_juese")
		x = math.max(1, x)
		x = math.min(x, 3)
		return tostring(x)
	end
	return "1"
end
sgs.ai_skill_choice.s_w_yanzi_in_de = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) and not self:willSkipPlayPhase(target) then
		return "s_w_yanzi_in"
	end
	return "s_w_yanzi_de"
end

sgs.ai_choicemade_filter.skillChoice["s_w_yanzi_in_de"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local current = self.room:getCurrent()
	if choice == "s_w_yanzi_in" then
		self:updateIntention(player, current, -80)
	elseif not self:willSkipPlayPhase(current) then
		self:updateIntention(player, current, 80)
	end
end




sgs.ai_fill_skill["s2_longhun"] = function(self,inclusive,request)
	if not __scarletayuhuo_value_call(self.player,"isWounded") then return end
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "defense")
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(handcards, visible(self,id))
		end
	end
	handcards = self:sortByUseValue(handcards, true)
	local equipments = sgs.QList2Table(self.player:getCards("e"))
	equipments = self:sortByUseValue(equipments, true)
	local basic_cards = {}
	local basic_cards_count = 0
	local non_basic_cards = {}
	local use_cards = {}

	if self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and __scarletayuhuo_value_call(self.player,"isWounded") and __scarletayuhuo_value_call(self.player,"getLostHp") >= 2 then
		table.insert(non_basic_cards, self.player:getArmor():getEffectiveId())
	end

	for _, c in ipairs(handcards) do
		if not __scarletayuhuo_value_call(c,"isKindOf","Peach") then
			if __scarletayuhuo_value_call(c,"isKindOf","BasicCard") then
				basic_cards_count = basic_cards_count + 1
				table.insert(basic_cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
			else
				table.insert(non_basic_cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
			end
		end
	end
	for _, e in ipairs(equipments) do
		if __scarletayuhuo_value_call(e,"isKindOf","OffensiveHorse") then
			table.insert(non_basic_cards, __scarletayuhuo_value_call(e,"getEffectiveId"))
		end
	end
	if self:getOverflow() <= 0 then return end

	if #basic_cards > 0 then
		table.insert(use_cards, basic_cards[1])
	end
	if #use_cards == 0 then return end

	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and self:isGoodTarget(enemy, self.enemies, nil) and __scarletayuhuo_value_call(self.player,"inMyAttackRange",enemy) then
			local thunder_slash = clone(self,"thunder_slash")
			local fire_slash = clone(self,"fire_slash")
			local slash = clone(self,"slash")
			if not self:slashProhibit(fire_slash, enemy, self.player) and self:slashIsEffective(fire_slash, enemy, self.player) then
				return policy(self,"#s2_longhun:" .. table.concat(use_cards, "+") .. ":" .. "fire_slash")
			end
			if not self:slashProhibit(thunder_slash, enemy, self.player) and self:slashIsEffective(thunder_slash, enemy, self.player) then
				return policy(self,"#s2_longhun:" .. table.concat(use_cards, "+") .. ":" .. "thunder_slash")
			end
			if not self:slashProhibit(slash, enemy, self.player) and self:slashIsEffective(slash, enemy, self.player) then
				return policy(self,"#s2_longhun:" .. table.concat(use_cards, "+") .. ":" .. "slash")
			end
		end
	end
	if __scarletayuhuo_value_call(self.player,"isWounded") then
		if __scarletayuhuo_value_call(self.player,"getLostHp") == 1 and #self:getPriorTurnUseCards() > 0 then
			return
		end
		return policy(self,"#s2_longhun:" .. table.concat(use_cards, "+") .. ":" .. "peach")
	end
end

sgs.ai_skill_use_func["#s2_longhun"] = function(card, use, self)
	local userstring = card:getLegacyStringKey()
	userstring = (userstring:split(":"))[4]
	local xin_zhayi_jibencard = clone(self,userstring, __scarletayuhuo_value_call(card,"getSuit"), __scarletayuhuo_value_call(card,"getNumber"))
	xin_zhayi_jibencard = mutate(self,xin_zhayi_jibencard,"skill","s2_longhun")
	self:useBasicCard(xin_zhayi_jibencard, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["s2_longhun"] = 3
sgs.ai_use_value["s2_longhun"] = 3

sgs.ai_view_as["s2_longhun"] = function(card, player, card_place, class_name)
 local self=known(known(player:getRoom(),"view-as room")._ai,"view-as AI context")
	if not __scarletayuhuo_value_call(player,"isWounded") then return end
	local classname2objectname = {
		["Slash"] = "slash",
		["Jink"] = "jink",
		["Peach"] = "peach",
		["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash",
		["ThunderSlash"] = "thunder_slash"
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local no_have = true
	local cards = complete_hand(self,player)
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			cards:prepend(visible(self,id))
		end
	end
	for _, c in sgs.qlist(cards) do
		if __scarletayuhuo_value_call(c,"isKindOf",class_name) then
			no_have = false
			break
		end
	end
	if not no_have then return end


	local handcards = sgs.QList2Table(complete_hand(self,player))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(handcards, visible(self,id))
		end
	end
	local equipments = sgs.QList2Table(player:getCards("e"))
	local basic_cards = {}
	local non_basic_cards = {}
	local use_cards = {}

	if player:getArmor() and player:hasArmorEffect("silver_lion") and __scarletayuhuo_value_call(player,"isWounded") and __scarletayuhuo_value_call(player,"getLostHp") >= 2 then
		table.insert(non_basic_cards, player:getArmor():getEffectiveId())
	end

	for _, c in ipairs(handcards) do
		if not __scarletayuhuo_value_call(c,"isKindOf","Peach") then
			if __scarletayuhuo_value_call(c,"isKindOf","BasicCard") then
				table.insert(basic_cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
			else
				table.insert(non_basic_cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
			end
		end
	end
	for _, e in ipairs(equipments) do
		if not (__scarletayuhuo_value_call(e,"isKindOf","Armor") or __scarletayuhuo_value_call(e,"isKindOf","DefensiveHorse")) and not (__scarletayuhuo_value_call(e,"isKindOf","WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
			table.insert(non_basic_cards, __scarletayuhuo_value_call(e,"getEffectiveId"))
		end
	end

	if __scarletayuhuo_value_call(player,"getMark","@s2_longhunUsed") == 0 then
		if #basic_cards > 0 then
			table.insert(use_cards, basic_cards[1])
		end
		if #use_cards == 0 then return end
	else
		if #basic_cards > 0 and #non_basic_cards > 0 then
			table.insert(use_cards, basic_cards[1])
			table.insert(use_cards, non_basic_cards[1])
		elseif #basic_cards > 1 and #non_basic_cards == 0 then
			table.insert(use_cards, basic_cards[1])
			table.insert(use_cards, basic_cards[2])
		end
		if #use_cards ~= 2 then return end
	end

	if __scarletayuhuo_value_call(player,"getMark","@s2_longhunUsed") == 0 then
		if class_name == "Peach" then
			return (name .. ":s2_longhun[%s:%s]=%d"):format(sgs.Card_NoSuit, 0, use_cards[1])
		else
			return (name .. ":s2_longhun[%s:%s]=%d"):format(sgs.Card_NoSuit, 0, use_cards[1])
		end
	else
		if class_name == "Peach" then
			return (name .. ":s2_longhun[%s:%s]=%d+%d"):format(sgs.Card_NoSuit, 0, use_cards[1], use_cards[2])
		else
			return (name .. ":s2_longhun[%s:%s]=%d+%d"):format(sgs.Card_NoSuit, 0, use_cards[1], use_cards[2])
		end
	end
end

function sgs.ai_cardneed.s2_longhun(to, card, self)
	return __scarletayuhuo_value_call(card,"isKindOf","BasicCard")
end

sgs.ai_getBestHp_skill.s2_longhun = function(owner)
	return __scarletayuhuo_value_call(owner,"getMaxHp") - 1
end

sgs.need_kongcheng = sgs.need_kongcheng .. "|s2_juejing"

sgs.ai_skill_playerchosen.s2_juejing = function(self, targets)
	if self:needKongcheng(self.player, true) then
		return nil
	end
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and (not target:hasSkills(sgs.lose_equip_skill) or self:doDisCard(target)) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and ((target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 0) or target:needToThrowArmor()) then return
			target end
	end

	return targets[1]
end


sgs.ai_skill_cardchosen["s2_juejing"] = function(self, who, flags)
	self:updatePlayers()
	if __scarletayuhuo_value_call(self.player,"getPhase") == sgs.Player_Play then
		if flags:match("e") then
			if self:isEnemy(who) then
				if not who:hasSkills(sgs.lose_equip_skill) then
					for _, e in ipairs(sgs.QList2Table(who:getCards("e"))) do
						local equip_index = known(e:getEquipSlot(),"equipment slot")
						return __scarletayuhuo_value_call(e,"getEffectiveId")
					end
				end
			else
				if who:hasSkills(sgs.lose_equip_skill) then
					for _, e in ipairs(sgs.QList2Table(who:getCards("e"))) do
						local equip_index = known(e:getEquipSlot(),"equipment slot")
						return __scarletayuhuo_value_call(e,"getEffectiveId")
					end
				end
			end
		end
		if flags:match("j") then
			if self:isEnemy(who) then
				local judges = who:getJudgingArea()
				if who:containsTrick("YanxiaoCard") then
					for _, judge in sgs.qlist(judges) do
						if __scarletayuhuo_value_call(judge,"isKindOf","YanxiaoCard") then
							return __scarletayuhuo_value_call(judge,"getEffectiveId")
						end
					end
				end
			elseif self:isFriend(who) then
				local judges = who:getJudgingArea()
				for _, judge in sgs.qlist(judges) do
					if not __scarletayuhuo_value_call(judge,"isKindOf","YanxiaoCard") then
						return __scarletayuhuo_value_call(judge,"getEffectiveId")
					end
				end
			end
		end
		if flags:match("h") then
			if self:isEnemy(who) then
				for _, h in ipairs(sgs.QList2Table(complete_hand(self,who))) do
					return __scarletayuhuo_value_call(h,"getEffectiveId")
				end
			end
		end
	else
		if flags:match("h") then
			for _, h in ipairs(sgs.QList2Table(complete_hand(self,who))) do
				return __scarletayuhuo_value_call(h,"getEffectiveId")
			end
		end
	end
end


sgs.ai_fill_skill["s2_duanzui"] = function(self,inclusive,request)
	if __scarletayuhuo_value_call(self.player,"getMark","@s2_duanzui") <= 0 then return end
	if self.room:getMode() == "_mini_13" then return policy(self,"#s2_duanzui:.:") end
	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and self:isWeak(lord) then return end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) and self:damageIsEffective(player, sgs.DamageStruct_Fire) then
			if self:isFriend(player) then
				bad = bad + 1
			else
				good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(__scarletayuhuo_value_call(player,"getHp"), 1)
		if self:damageIsEffective(player, sgs.DamageStruct_Fire) then
			if getCardsNum("Analeptic", player) > 0 then
				if self:isFriend(player) then
					good = good + 1.0 / hp
				else
					bad = bad + 1.0 / hp
				end
			end


			local lost_value = 0
			if self:hasSkills(sgs.masochism_skill, player) then lost_value = __scarletayuhuo_value_call(player,"getHp") / 2 end
			local hp = math.max(__scarletayuhuo_value_call(player,"getHp"), 1)
			if self:isFriend(player) then
				bad = bad + (lost_value + 1) / hp
			else
				good = good + (lost_value + 1) / hp
			end
		end
	end

	if good > bad then return policy(self,"#s2_duanzui:.:") end
end

sgs.ai_skill_use_func["#s2_duanzui"] = function(card, use, self)
	use.card = card
end

sgs.dynamic_value.damage_card["#s2_duanzui"] = true


sgs.ai_fill_skill["s2_shenpan"] = function(self,inclusive,request)
	if not self.player:hasUsed("#s2_shenpan") then
		return policy(self,"#s2_shenpan:.:")
	end
end

sgs.ai_skill_use_func["#s2_shenpan"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
			if __scarletayuhuo_value_call(enemy,"getHandcardNum") >= 2 then
				use.card = policy(self,"#s2_shenpan:.:")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
end

sgs.ai_use_value.s2_shenpan = 2.5
sgs.ai_card_intention.s2_shenpan = 80
sgs.ai_use_priority.s2_shenpan = 4.2


sgs.ai_cardneed.s2_chengwu = function(to, card)
	return card:isRed() and isCard("Slash", card, to)
end

sgs.ai_ajustdamage_from.s2_chengwu = function(self, from, to, card, nature)
    if card and __scarletayuhuo_value_call(card,"isKindOf","Slash") and card:isRed()
    then
        return 1
    end
end



sgs.ai_need_damaged.s2_huzi = function(self, attacker, player)
	if not __scarletayuhuo_value_call(player,"hasSkill","chanyuan") and __scarletayuhuo_value_call(player,"hasSkill","s2_huzi") and __scarletayuhuo_value_call(player,"getMark","s2_huzi") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < __scarletayuhuo_value_call(player,"getHp")
		and (__scarletayuhuo_value_call(player,"getHp") > 3 or __scarletayuhuo_value_call(player,"getHp") == 3 and (__scarletayuhuo_value_call(player,"faceUp") or __scarletayuhuo_value_call(player,"hasSkill","guixin") or __scarletayuhuo_value_call(player,"hasSkill","toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end


sgs.ai_skill_invoke.s2_touben_wei = function(self, data)
	if not self:isWeak() and (__scarletayuhuo_value_call(self.player,"getHp") > 2 or (self:getCardsNum("Peach") > 0 and __scarletayuhuo_value_call(self.player,"getHp") > 1)) then
		return true
	end
	return false
end


sgs.ai_skill_invoke.s2_touben_wu = function(self, data)
	if not self:isWeak() and (__scarletayuhuo_value_call(self.player,"getHp") > 2 or (self:getCardsNum("Peach") > 0 and __scarletayuhuo_value_call(self.player,"getHp") > 1)) then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.s2_nixi = function(self, targets)
	local target = self:findBestDamageTarget(1, "N")
	return target
end

sgs.ai_fill_skill["s2_jiange"] = function(self,inclusive,request)
	if not self.player:hasUsed("#s2_jiange") then
		if __scarletayuhuo_value_call(self.player,"getHandcardNum") > 0 then
			return policy(self,"#s2_jiange:.:")
		end
	end
end

sgs.ai_skill_use_func["#s2_jiange"] = function(card, use, self)
	use.card = card
	return
end

sgs.ai_use_value["s2_jiange"] = 2                                     --卡牌使用价值
sgs.ai_use_priority["s2_jiange"] = sgs.ai_use_priority.ExNihilo - 0.1 --卡牌使用优先级

sgs.ai_skill_invoke.s2_jiange_obtain = function(self)
	return true
end

sgs.ai_skill_askforag.s2_jiange = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, visible(self,card_id))
	end
	to_obtain = self:sortByCardNeed(to_obtain, true)
	return __scarletayuhuo_value_call(to_obtain[1],"getEffectiveId")
end



sgs.ai_skill_cardask["@s2_jiange_add"] = function(self, data, pattern, target)
	return "."
end



sgs.ai_skill_invoke.s2_wuhun = function(self)
	if __scarletayuhuo_value_call(self.player,"getHp") >= getBestHp(self.player) then
		return false
	end
	return true
end


sgs.ai_view_as.s2_wuhun = function(card, player, card_place)
 local self=known(known(player:getRoom(),"view-as room")._ai,"view-as AI context")
	local suit = __scarletayuhuo_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __scarletayuhuo_value_call(card,"getEffectiveId")
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
		and card_place == sgs.Player_PlaceHand
		and __scarletayuhuo_value_call(card,"getSuit") == sgs.Card_Heart and not __scarletayuhuo_value_call(card,"isKindOf","Peach") and not __scarletayuhuo_value_call(card,"hasFlag","using") and not (__scarletayuhuo_value_call(card,"isKindOf","WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("slash:s2_wuhun[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_fill_skill["s2_wuhun"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, visible(self,id))
		end
	end
	local red_card
	cards = self:sortByUseValue(cards, true)

	local useAll = false
	self.enemies = self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if __scarletayuhuo_value_call(enemy,"getHp") == 1 and not enemy:hasArmorEffect("eight_diagram") and __scarletayuhuo_value_call(self.player,"distanceTo",enemy) <= __scarletayuhuo_value_call(self.player,"getAttackRange") and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") <= 0 or __scarletayuhuo_value_call(self.player,"hasSkill","paoxiao") then
		disCrossbow = true
	end

	for _, card in ipairs(cards) do
		if __scarletayuhuo_value_call(card,"getSuit") == sgs.Card_Heart and not __scarletayuhuo_value_call(card,"isKindOf","Slash")
			and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or residue(self,clone(self,"slash")) > 0)
			and not (__scarletayuhuo_value_call(card,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			red_card = card
			break
		end
	end

	if red_card then
		local suit = __scarletayuhuo_value_call(red_card,"getSuitString")
		local number = red_card:getNumberString()
		local card_id = __scarletayuhuo_value_call(red_card,"getEffectiveId")
		local card_str = ("slash:s2_wuhun[%s:%s]=%d"):format(suit, number, card_id)
		local slash = policy(self,card_str)

		assert(slash)
		return slash
	end
end

function sgs.ai_cardneed.s2_wuhun(to, card)
	return __scarletayuhuo_value_call(to,"getHandcardNum") < 3 and __scarletayuhuo_value_call(card,"getSuit") == sgs.Card_Heart
end

sgs.ai_skill_use["@@s2_wushen"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards, true)
	local slashcount = self:getCardsNum("Slash")
	local use_card = {}
	for _, card in ipairs(cards) do
		if __scarletayuhuo_value_call(card,"isKindOf","Slash") and #use_card < slashcount then
			table.insert(use_card, __scarletayuhuo_value_call(card,"getEffectiveId"))
		end
	end
	if slashcount > 1 then
		return string.format("#s2_wushen:%s:", table.concat(use_card, "+"))
	end
	return "."
end

sgs.ai_skill_invoke.s2_gn_nixi = function(self, data)
	local tuxi_string = sgs.ai_skill_use["@@tenyeartuxi"](self, prompt)
	if tuxi_string == "." then
		return false
	end
	return true
end


sgs.ai_fill_skill["s2_gn_nixi"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, visible(self,id))
		end
	end

	local black_card

	cards = self:sortByUseValue(cards, true)

	local has_weapon = false

	for _, card in ipairs(cards) do
		if __scarletayuhuo_value_call(card,"isKindOf","Weapon") and card:isBlack() then has_weapon = true end
	end

	for _, card in ipairs(cards) do
		if card:isBlack() and ((self:getUseValue(card) < sgs.ai_use_value.Dismantlement) or inclusive or self:getOverflow() > 0) then
			local shouldUse = true

			if __scarletayuhuo_value_call(card,"isKindOf","Armor") then
				if not self.player:getArmor() then
					shouldUse = false
				elseif self.player:hasEquip(card) and not self:needToThrowArmor() then
					shouldUse = false
				end
			end

			if __scarletayuhuo_value_call(card,"isKindOf","Weapon") then
				if not self.player:getWeapon() then
					shouldUse = false
				elseif self.player:hasEquip(card) and not has_weapon then
					shouldUse = false
				end
			end

			if __scarletayuhuo_value_call(card,"isKindOf","Slash") then
				local dummy_use = { isDummy = true }
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.Dismantlement and __scarletayuhuo_value_call(card,"isKindOf","TrickCard") then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse then
				black_card = card
				break
			end
		end
	end

	if black_card and __scarletayuhuo_value_call(self.player,"getMark","&s2_jie") > 2 then
		local suit = __scarletayuhuo_value_call(black_card,"getSuitString")
		local number = black_card:getNumberString()
		local card_id = __scarletayuhuo_value_call(black_card,"getEffectiveId")
		local card_str = ("dismantlement:s2_gn_nixi[%s:%s]=%d"):format(suit, number, card_id)
		local dismantlement = policy(self,card_str)

		assert(dismantlement)

		return dismantlement
	end
end

sgs.s2_gn_nixi_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.s2_gn_nixi(to, card)
	return card:isBlack()
end

sgs.ai_skill_cardask["@s2_guanhui-card"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return "." end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not __scarletayuhuo_value_call(card,"hasFlag","using") then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			cards = self:sortByUseValue(cards, true)
			if not self:needBear() and __scarletayuhuo_value_call(self.player,"getAttackRange") >= 3 then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) then
		local card = visible(self,card_id)
		return "$" .. card_id
	end

	return "."
end

sgs.ai_skill_askforag.s2_guanhui = function(self, card_ids)
	local judge = room_tag(self,"s2_guanhui","Judge")
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, visible(self,card_id))
	end
	local card_id = self:getRetrialCardId(to_obtain, judge)
	if card_id == -1 then
		return __scarletayuhuo_value_call(to_obtain[1],"getEffectiveId")
	else
		return card_id
	end
end
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|s2_guanhui"
sgs.wizard_skill = sgs.wizard_skill .. "|s2_guanhui"

sgs.double_slash_skill = sgs.double_slash_skill .. "|s2_jiangmen"
sgs.bad_skills = sgs.bad_skills .. "|s2_duanya"
sgs.ai_skill_discard.s2_duanya = function(self,discard_num,min_num,optional,include_equip)
	return nosganglie_discard(self,discard_num,min_num,optional,include_equip,"")
end

sgs.ai_skill_use["@@s2_houqi"] = function(self, prompt)
	if self.player and (self.player:getPile("s2_fa"):length() > 0) then
		local use_card = {}
		for _, c in ipairs(sgs.QList2Table(self.player:getPile("s2_fa"))) do
			if #use_card == 0 and visible(self,c):isRed() then
				table.insert(use_card, visible(self,c):getEffectiveId())
				break
			end
		end
		if #use_card == 0 then
			for _, c in ipairs(sgs.QList2Table(self.player:getPile("s2_fa"))) do
				if (#use_card < 2) and visible(self,c):isBlack() then
					table.insert(use_card, visible(self,c):getEffectiveId())
				end
			end
		end
		if #use_card > 0 then
			return "#s2_houqi:" .. table.concat(use_card, "+") .. ":"
		end
	end
	return "."
end


sgs.ai_skill_invoke.s2_yongbing = function(self, data)
	if self:willSkipPlayPhase() then return false end
	if self:willSkipDrawPhase() then return true end
	local card = clone(self,"amazing_grace", sgs.Card_NoSuit, 0)
	card = mutate(self,card,"skill","s2_yongbing")
	card:deleteLater()
	if __scarletayuhuo_value_call(self.player,"getHp") + self:getAllPeachNum() - 1 <= 0 then return false end
	local dummy = self:aiUseCard(card, dummy_plan())
    if dummy.card then
		return true
	end
	if __scarletayuhuo_value_call(self.player,"hasSkill","s2_lixian") then
		return true
	end
	return false
end


sgs.ai_skill_choice.s2_lixian = function(self, choices, data)
    local items = choices:split("+")
    local aglist = room_tag(self,"AmazingGrace","IntList")
	local basic = 0
	local equip = 0
	local trick = 0
	local max = 0
	for _, card_id in sgs.qlist(aglist) do
		local card = visible(self,card_id)
		if __scarletayuhuo_value_call(card,"isKindOf","BasicCard") then
			basic = basic + 1
		elseif __scarletayuhuo_value_call(card,"isKindOf","EquipCard") then
			equip = equip + 1
		elseif __scarletayuhuo_value_call(card,"isKindOf","TrickCard") then
			trick = trick + 1
		end
	end
	max = math.max(basic, equip, trick)
	if table.contains(items, "s2_lixian_basic") then
		if basic == max then
			return "s2_lixian_basic"
		end
	end
	if table.contains(items, "s2_lixian_equip") then
		if equip == max then
			return "s2_lixian_equip"
		end
	end
	if table.contains(items, "s2_lixian_trick") then
		if trick == max then
			return "s2_lixian_trick"
		end
	end
    return items[1]
end
sgs.ai_skill_playerchosen.s2_lixian = function(self, targets)
	local targetlist=sgs.QList2Table(targets)
	for _, player in ipairs(targetlist) do
		if self:isFriend(player) then return player end
	end
	for _, player in ipairs(targetlist) do
		return player
	end
end
function sgs.ai_armor_value.s2_jianzu(player, self, card)
	if card and (__scarletayuhuo_value_call(card,"isKindOf","KylinBow") or __scarletayuhuo_value_call(card,"isKindOf","Crossbow")) then return 4 end
end

sgs.ai_use_revises.s2_jianzu = function(self, card, use)
	if card and __scarletayuhuo_value_call(card,"isKindOf","Weapon")
	then
		local same = self:getSameEquip(card)
		if same and (__scarletayuhuo_value_call(same,"isKindOf","KylinBow") or __scarletayuhuo_value_call(same,"isKindOf","Crossbow"))
		then
			return false
		end
	end
end
function sgs.ai_cardneed.s2_jianzu(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return __scarletayuhuo_value_call(card,"isKindOf","KylinBow") or __scarletayuhuo_value_call(card,"isKindOf","Crossbow")
	end
end

sgs.ai_ajustdamage_from.s2_shengjian = function(self, from, to, card, nature)
    if card and __scarletayuhuo_value_call(card,"isKindOf","Slash") and from:getWeapon() ~= nil
    then
        return 1
    end
end

sgs.ai_skill_invoke.s2_zhengyi = function(self, data)
	local damage = data:toDamage()
	if damage.to and self:isFriend(damage.to, self.player) and (not damage.from or not self:isFriend(damage.from, self.player)) then
		return true
	end
end
sgs.ai_choicemade_filter.skillInvoke.s2_zhengyi = function(self, player, promptlist)
    if promptlist[#promptlist] == "yes" then
		local damage = room_tag(self,"CurrentDamageStruct","Damage")
        self:updateIntention(player, damage.to, -70)
    end
end


sgs.ai_fill_skill["s2_guimou"] = function(self,inclusive,request)
	if not __scarletayuhuo_value_call(self.player,"hasFlag","s2_guimoux") then return end
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(usable_cards, visible(self,id))
		end
	end
	usable_cards = self:sortByUseValue(usable_cards, true)
	local cards = {}
	for _, c in ipairs(usable_cards) do
		local cardex = clone(self,visible(self,__scarletayuhuo_value_call(self.player,"getMark","s2_guimouskill")):objectName(),
			__scarletayuhuo_value_call(c,"getSuit"), __scarletayuhuo_value_call(c,"getNumber"))
		if not self.player:isCardLimited(cardex, sgs.Card_MethodUse, true) and __scarletayuhuo_value_call(cardex,"isAvailable",self.player) and not __scarletayuhuo_value_call(c,"isKindOf","Peach") and not (__scarletayuhuo_value_call(c,"isKindOf","Jink") and self:getCardsNum("Jink") < 3) and not __scarletayuhuo_value_call(cardex,"isKindOf","IronChain") then
			local name = visible(self,__scarletayuhuo_value_call(self.player,"getMark","s2_guimouskill")):objectName()
			local new_card = policy(self,(name .. ":s2_guimou[%s:%s]=%d"):format(__scarletayuhuo_value_call(c,"getSuitString"),
				c:getNumberString(), __scarletayuhuo_value_call(c,"getEffectiveId")))
			assert(new_card)
			return new_card
		end
	end
end



sgs.ai_skill_playerchosen.s2_huandou = function(self, targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and not hasZhaxiangEffect(target)
			and (self:isWeak(target) or not __scarletayuhuo_value_call(self.player,"faceUp")) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and hasZhaxiangEffect(target) and not self:isWeak(target) and not (__scarletayuhuo_value_call(target,"getHp") == 2 and __scarletayuhuo_value_call(target,"hasSkill","chanyuan")) then return
			target end
	end
	return nil
end

sgs.ai_skill_playerchosen.s2_xingyi = function(self, targets)
	targets = sgs.QList2Table(targets)
	if #self.enemies > 0 then
		return self.enemies[math.random(1, #self.enemies)]
	end
	return targets[math.random(1, #targets)]
end
sgs.ai_playerchosen_intention.s2_xingyi = 40

sgs.ai_skill_choice["s2_xingyi"] = function(self, choices, data)
	local items = choices:split("+")
	local bad_skills = sgs.bad_skills:split("|")
	local can_duorui_items = {}
	for _, item in ipairs(items) do
		if not table.contains(bad_skills, item) then
			table.insert(can_duorui_items, item)
		end
	end
	return can_duorui_items[math.random(1, #can_duorui_items)]
end


sgs.ai_fill_skill["s2_yizei"] = function(self,inclusive,request)
	if not self.player:hasUsed("#s2_yizei") then
		return policy(self,"#s2_yizei:.:")
	end
end

sgs.ai_skill_use_func["#s2_yizei"] = function(card, use, self)

	if #self.enemies == 0 then return end
	self.enemies = self:sort(self.enemies, "handcard")
	local target
	local friendt
	for _, enemy in ipairs(self.enemies) do
		if __scarletayuhuo_value_call(enemy,"getHp") > __scarletayuhuo_value_call(self.player,"getHp") and not enemy:isKongcheng() and self:doDisCard(enemy, "h", true) then
			target = enemy
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if __scarletayuhuo_value_call(friend,"getHp") > __scarletayuhuo_value_call(self.player,"getHp") and not friend:isKongcheng() and self:doDisCard(friend, "h", true) then
				target = friend
				break
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if __scarletayuhuo_value_call(friend,"getHp") <= __scarletayuhuo_value_call(self.player,"getHp") then
			friendt = friend
			break
		end
	end
	if target and friendt then
		use.card = policy(self,"#s2_yizei:.:")
		if use.to then use.to:append(target) end
		if use.to then use.to:append(friendt) end
	end
end
sgs.ai_use_priority["s2_yizei"] = sgs.ai_use_priority.Peach + 0.1


sgs.ai_fill_skill["s2_zhanjiang"] = function(self,inclusive,request)
	if not self.player:hasUsed("#s2_zhanjiang") and not self.player:isKongcheng() then return policy(self,
		"#s2_zhanjiang:.:") end
end

sgs.ai_skill_use_func["#s2_zhanjiang"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard(self.player)
	local max_point = __scarletayuhuo_value_call(max_card,"getNumber")
	if __scarletayuhuo_value_call(self.player,"hasSkill","kongcheng") and __scarletayuhuo_value_call(self.player,"getHandcardNum") == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and __scarletayuhuo_value_call(self.player,"canPindian",enemy) and __scarletayuhuo_value_call(enemy,"getHp") < __scarletayuhuo_value_call(self.player,"getHp") then
				use.card = policy(self,"#s2_zhanjiang:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if (max_point > 10) then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and __scarletayuhuo_value_call(self.player,"canPindian",enemy) and __scarletayuhuo_value_call(enemy,"getHp") < __scarletayuhuo_value_call(self.player,"getHp") then
				use.card = policy(self,"#s2_zhanjiang:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end


sgs.ai_cardneed.s2_zhanjiang = sgs.ai_cardneed.bignumber
function sgs.ai_slash_prohibit.s2_hungui(self, from, to)
	if __scarletayuhuo_value_call(from,"hasSkill","jueqing") or (__scarletayuhuo_value_call(from,"hasSkill","nosqianxi") and __scarletayuhuo_value_call(from,"distanceTo",to) == 1) then return false end
	if __scarletayuhuo_value_call(from,"hasFlag","NosJiefanUsed") then return false end
	if __scarletayuhuo_value_call(to,"getHp") > 1 or #(self:getEnemies(from)) == 1 then return false end
	if __scarletayuhuo_value_call(from,"getMaxHp") == 3 and from:getArmor() and from:getDefensiveHorse() then return false end
	if __scarletayuhuo_value_call(from,"getMaxHp") <= 3 or (__scarletayuhuo_value_call(from,"isLord") and self:isWeak(from)) then return true end
	if __scarletayuhuo_value_call(from,"getMaxHp") <= 3 or (self.room:getLord() and viewer_role(self,from) == "renegade") then return true end
	return false
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|s2_hungui"
sgs.bad_skills = sgs.bad_skills .. "|s2_baizou"

sgs.ai_target_revises.s2_changsheng = function(to,card)
	if __scarletayuhuo_value_call(card,"isKindOf","Duel")
	then return true end
end
function sgs.ai_cardneed.s2_changsheng(to, card)
    return __scarletayuhuo_value_call(card,"isKindOf","Duel")
end
sgs.ai_cardneed.s2_danqi = sgs.ai_cardneed.slash

sgs.s2_danqi_keep_value = {
	Peach           = 6,
	Analeptic       = 5.8,
	Jink            = 5.2,
	Duel            = 5.5,
	FireSlash       = 5.6,
	Slash           = 5.4,
	ThunderSlash    = 5.5,
}

sgs.ai_skill_invoke.s2_danqi = function(self, data)
	local slashNum = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if __scarletayuhuo_value_call(card,"isKindOf","Slash") then
			slashNum = slashNum + 1
		end
	end
	return (__scarletayuhuo_value_call(self.player,"getHp") > 3 and slashNum > 0) or (__scarletayuhuo_value_call(self.player,"getHp") > 4)
end

sgs.ai_ajustdamage_from["s2_danqi"]   = function(self, from, to, card, nature)
	if card and __scarletayuhuo_value_call(card,"isKindOf","Slash") then
		return __scarletayuhuo_value_call(from,"getMark","s2_danqi")
	end
end

sgs.ai_skill_invoke.s2_tianjiang = function(self, data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end

sgs.ai_cardneed.s2_tianjiang = sgs.ai_cardneed.slash
sgs.ai_cardneed.s2_tieji = sgs.ai_cardneed.slash

sgs.ai_ajustdamage_from["s2_tianjiang"]   = function(self, from, to, card, nature)
	if card and __scarletayuhuo_value_call(card,"isKindOf","Slash") and __scarletayuhuo_value_call(card,"hasFlag","s2_tianjiang") then
		return 1
	end
end
sgs.ai_ajustdamage_from["s2_tieji"]   = function(self, from, to, card, nature)
	if card and __scarletayuhuo_value_call(card,"isKindOf","Slash") and (from:getOffensiveHorse() ~= nil or from:getDefensiveHorse() ~= nil) then
		return 1
	end
end
sgs.ai_skill_playerchosen.s2_haojiu = function(self, targets)
	local target = self:findPlayerToDraw(true, 1)
	if target then
		return target
	else
		self.enemies = self:sort(self.enemies, "hp")
		return self.enemies[1]
	end
end

sgs.bad_skills = sgs.bad_skills .. "|s2_cansi"
sgs.ai_skill_choice["s2_haojiu"] = function(self, choices, data)
	local items = choices:split("+")
	if self:isWeak() then
		return "s2_haojiu_draw"
	end
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __scarletayuhuo_value_call(p,"hasFlag","s2_haojiu") then
			if self:isFriend(p) then
				return "s2_haojiu_draw"
			elseif self:isEnemy(p) then
				if __scarletayuhuo_value_call(self.player,"getHp") > __scarletayuhuo_value_call(p,"getHp") and not hasZhaxiangEffect(p) then
					return "s2_haojiu_losthp"
				end
			end
		end
	end
	return items[math.random(1, #items)]
end



sgs.ai_skill_cardask["@s2_nuhou-give"] = function(self,data)
	local target = data:toPlayer()
	local has_peach,has_analeptic,has_slash,has_jink
	for _,card in sgs.qlist(self.player:getHandcards())do
		if __scarletayuhuo_value_call(card,"isKindOf","Peach") then has_peach = card
		elseif __scarletayuhuo_value_call(card,"isKindOf","Analeptic") then has_analeptic = card
		elseif __scarletayuhuo_value_call(card,"isKindOf","Slash") then has_slash = card
		elseif __scarletayuhuo_value_call(card,"isKindOf","Jink") then has_jink = card
		end
	end

	if has_slash then return "$"..__scarletayuhuo_value_call(has_slash,"getEffectiveId")
	elseif has_jink then return "$"..__scarletayuhuo_value_call(has_jink,"getEffectiveId")
	elseif has_analeptic or has_peach then
		if has_analeptic then return "$"..__scarletayuhuo_value_call(has_analeptic,"getEffectiveId")
		else return "$"..__scarletayuhuo_value_call(has_peach,"getEffectiveId")
		end
	else return "."
	end
end

sgs.ai_target_revises.s2_nuhou = function(to,card,self,use)
	if __scarletayuhuo_value_call(card,"isKindOf","TrickCard")
	and self:getCardsNum("BasicCard")-self:getCardsNum("Peach")<2
	then return true end
end



sgs.ai_fill_skill["s2_shanqi"] = function(self,inclusive,request)
	if not self.player:hasUsed("#s2_shanqi") then
		return policy(self,"#s2_shanqi:.:")
	end
end

sgs.ai_skill_use_func["#s2_shanqi"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())


	if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self:getCardsNum("Nullification") + self:getCardsNum("SavageAssault") + self:getCardsNum("ArcheryAttack") + self:getCardsNum("Duel") == 0 then
		local use_zhiheng_cards = {}
		for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
			if __scarletayuhuo_value_call(c,"isKindOf","OffensiveHorse") or __scarletayuhuo_value_call(c,"isKindOf","DefensiveHorse") then
				table.insert(use_zhiheng_cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
			end
		end
		for _, e in ipairs(sgs.QList2Table(self.player:getCards("e"))) do
			if __scarletayuhuo_value_call(e,"isKindOf","OffensiveHorse") or __scarletayuhuo_value_call(e,"isKindOf","DefensiveHorse") then
				table.insert(use_zhiheng_cards, __scarletayuhuo_value_call(e,"getEffectiveId"))
			end
		end
		if #use_zhiheng_cards > 0 then
			use.card = policy(self,"#s2_shanqi:" .. table.concat(use_zhiheng_cards, "+") .. ":")
			if use.to then use.to:append(self.player) end
			return
		end
	end
end

sgs.ai_use_value["#s2_shanqi"] = 9
sgs.ai_use_priority["#s2_shanqi"] = 2.61
sgs.dynamic_value.benefit["#s2_shanqi"] = true

sgs.ai_skill_choice["s2_shanqi"] = function(self, choices, data)
	return "s2_shanqi_draw"
end


sgs.ai_canliegong_skill.s2_baibu = function(self, from, to)
	local distance = 0
	for _, q in sgs.qlist(self.room:getOtherPlayers(from)) do
		if __scarletayuhuo_value_call(from,"inMyAttackRange",q) then
			distance = math.max(distance, __scarletayuhuo_value_call(from,"distanceTo",q))
		end
	end
	return distance == __scarletayuhuo_value_call(from,"distanceTo",to)
end


sgs.ai_fill_skill["s2_longwei"] = function(self,inclusive,request)
	self:updatePlayers()
	local patterns = {"slash", "jink", "analeptic", "nullification", "snatch", "dismantlement", "collateral", "duel", "fire_attack", "amazing_grace", "savage_assault", "archery_attack", "god_salvation", "iron_chain"}
	if not (Set(fact(self,"ban_packages")))["maneuvering"] then
		table.insert(patterns, 2, "thunder_slash")
		table.insert(patterns, 2, "fire_slash")
		table.insert(patterns, 2, "normal_slash")
	end
	local slash_patternslw = {"slash", "normal_slash", "thunder_slash", "fire_slash"}
	local choices = {}
	for _, name in ipairs(patterns) do
		local poi = clone(self,name, sgs.Card_NoSuit, -1)
		poi:deleteLater()
		if __scarletayuhuo_value_call(poi,"isAvailable",self.player) then
			table.insert(choices, name)
		end
	end
	if self.player:isNude() then return end
	if known(self:getRoleCounts().rebel,"rebel count") == 0 then return end
	if __scarletayuhuo_value_call(self.player,"getMark","AI_do_not_invoke_s2_longwei-Clear") > 0 then return end

	if next(choices) and __scarletayuhuo_value_call(self.player,"getMark","s2_longwei-Clear") == 0 then
		return policy(self,"#s2_longwei_select:.:")
	end
end

sgs.ai_skill_use_func["#s2_longwei_select"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	handcards = self:sortByUseValue(handcards, true)
	local useable_cards = {}
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if visible(self,id):isKindOf("Slash") then
				table.insert(handcards, visible(self,id))
			end
		end
	end
	for _, c in ipairs(handcards) do
		if not __scarletayuhuo_value_call(c,"isKindOf","EquipCard")
		then
			table.insert(useable_cards, c)
		end
	end
	local card_str = "#s2_longwei_select:.:"
	local acard = policy(self,card_str)
	if #useable_cards >= 1 then
		if __scarletayuhuo_value_call(useable_cards[1],"hasFlag","xiahui") then return end
		set_observation(self,"ai_s2_longwei_card_id",__scarletayuhuo_value_call(useable_cards[1],"getEffectiveId"))
		acard = mutate(self,acard,"add",__scarletayuhuo_value_call(useable_cards[1],"getEffectiveId"))
		use.card = acard
	end
end

sgs.ai_use_priority["s2_longwei_select"] = 3
sgs.ai_use_value["s2_longwei_select"] = 3

sgs.ai_skill_choice["s2_longwei-new-choicetype"] = function(self, choices, data)
	local ai_s2_longwei_card_id = room_tag(self,"ai_s2_longwei_card_id","Int")
	if visible(self,ai_s2_longwei_card_id):isKindOf("BasicCard") then
		return "basic"
	elseif math.random() < 0.5 then
		return "single_target_trick"
	else
		return "multiple_target_trick"
	end
end
sgs.ai_skill_choice["s2_longwei"] = function(self, choices, data)
	self:updatePlayers()
	local ai_s2_longwei_card_id = room_tag(self,"ai_s2_longwei_card_id","Int")
	set_observation(self,"ai_s2_longwei_card_id",false)
	local s2_longwei_vs_card = {}
	local items = choices:split("+")
	for _, card_name in ipairs(items) do
		if card_name ~= "cancel" then
			local use_card = clone(self,card_name, sgs.Card_SuitToBeDecided, -1)
			use_card:deleteLater()
			if not table.contains(s2_longwei_vs_card, use_card) then
				table.insert(s2_longwei_vs_card, use_card)
			end
		end
	end
	self:sortByUsePriority(s2_longwei_vs_card)
	for _, c in ipairs(s2_longwei_vs_card) do
		if table.contains(items, c:objectName()) then
			if c:targetFixed() then
				if __scarletayuhuo_value_call(c,"isKindOf","SavageAssault") then
					if self:getAoeValue(c) > 0 then
						return c:objectName()
					end
				end
				if __scarletayuhuo_value_call(c,"isKindOf","ArcheryAttack") then
					if self:getAoeValue(c) > 0 then
						return c:objectName()
					end
				end
				if __scarletayuhuo_value_call(c,"isKindOf","AmazingGrace") then
					local low_handcard_friend = false
					for _, friend in ipairs(self.friends_noself) do
						if __scarletayuhuo_value_call(friend,"getHandcardNum") <= 4 then
							low_handcard_friend = true
						end
					end
					if low_handcard_friend then
						return c:objectName()
					end
				end
				if __scarletayuhuo_value_call(c,"isKindOf","GodSalvation") then
					if self:willUseGodSalvation(c) then
						return c:objectName()
					end
				end
				if __scarletayuhuo_value_call(c,"isKindOf","Analeptic") then
					for _, slash in ipairs(self:getCards("Slash")) do
						if __scarletayuhuo_value_call(slash,"isKindOf","NatureSlash") and __scarletayuhuo_value_call(slash,"isAvailable",self.player) and
						(__scarletayuhuo_value_call(slash,"getEffectiveId") ~= ai_s2_longwei_card_id) then
							local dummy_use = self:aiUseCard(c, dummy_plan())
							if not dummy_use.to:isEmpty() then
								for _, p in sgs.qlist(dummy_use.to) do
									if self:shouldUseAnaleptic(p, slash) then
										return c:objectName()
									end
								end
							end
						end
					end
				end
			else
				if __scarletayuhuo_value_call(c,"isKindOf","NatureSlash") and self:getCardsNum("NatureSlash") == 0 then
					if __scarletayuhuo_value_call(c,"isKindOf","FireSlash") or __scarletayuhuo_value_call(c,"isKindOf","ThunderSlash") then
						local dummy_use = self:aiUseCard(c, dummy_plan())
						if not dummy_use.to:isEmpty() then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:isChained() then
									set_observation(self,"ai_s2_longwei_card_id",ai_s2_longwei_card_id)
									return c:objectName()
								end
							end
						end
					end
				end
				if __scarletayuhuo_value_call(c,"isKindOf","TrickCard") and not __scarletayuhuo_value_call(c,"isKindOf","Collateral") then
					local dummy_use = self:aiUseCard(c, dummy_plan())
					if not dummy_use.to:isEmpty() then
						for _, p in sgs.qlist(dummy_use.to) do
							set_observation(self,"ai_s2_longwei_card_id",ai_s2_longwei_card_id)
							return c:objectName()
						end
					end
				end
			end
		end
	end

	self:addStrategyPlayerMark(self.player,"AI_do_not_invoke_s2_longwei-Clear",1)
	return "cancel"
end

sgs.ai_skill_use["@@s2_longwei"] = function(self, prompt, method)
	local usecard = prompt:split(":")[2]
	local use_card = clone(self,usecard, sgs.Card_NoSuit, -1)
	use_card = mutate(self,use_card,"skill","s2_longwei")
	local ai_s2_longwei_card_id = room_tag(self,"ai_s2_longwei_card_id","Int")
	set_observation(self,"ai_s2_longwei_card_id",false)
	use_card = mutate(self,use_card,"add",ai_s2_longwei_card_id)
	local dummy_use = self:aiUseCard(use_card, dummy_plan())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return use_card:getLegacyStringKey() .. "->" .. table.concat(targets, "+")
		end
	end

	self:addStrategyPlayerMark(self.player,"AI_do_not_invoke_s2_longwei-Clear",1)
	return "."
end

sgs.ai_cardsview_valuable["s2_longwei"] = function(self, class_name, player)
	local classname2objectname = {
		["Slash"] = "slash",
		["Jink"] = "jink",
		["Analeptic"] = "analeptic",
		["Nullification"] = "nullification",
		["FireSlash"] = "fire_slash",
		["ThunderSlash"] = "thunder_slash"
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local no_have = true
	local cards = player:getCards("he")
	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
		cards:prepend(visible(self,id))
	end
	for _, c in sgs.qlist(cards) do
		if __scarletayuhuo_value_call(c,"isKindOf",class_name) then
			no_have = false
			break
		end
	end
	if not no_have or __scarletayuhuo_value_call(player,"getMark","s2_longwei-Clear") ~= 0 then return end
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local card
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			if visible(self,id):isKindOf("BasicCard") then
				card = visible(self,id)
				break
			end
		end
	end
	if card then
		local suit = __scarletayuhuo_value_call(card,"getSuitString")
		local number = card:getNumberString()
		local card_id = __scarletayuhuo_value_call(card,"getEffectiveId")
		return (name..":s2_longwei[%s:%s]=%d"):format(suit, number, card_id)
	end
	return
end

sgs.ai_skill_invoke.s2_tuxi = function(self, data)
	local target = data:toPlayer()
	return self:doDisCard(target, "h")
end
sgs.ai_cardneed.s2_tuxi = sgs.ai_cardneed.slash

sgs.ai_need_damaged.s2_wuwei = function(self, attacker, player)
	if not __scarletayuhuo_value_call(player,"hasSkill","chanyuan") and __scarletayuhuo_value_call(player,"hasSkill","s2_wuwei") and __scarletayuhuo_value_call(player,"getMark","s2_wuwei") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < __scarletayuhuo_value_call(player,"getHp")
		and (__scarletayuhuo_value_call(player,"getHp") > 3 or __scarletayuhuo_value_call(player,"getHp") == 3 and (__scarletayuhuo_value_call(player,"faceUp") or __scarletayuhuo_value_call(player,"hasSkill","guixin") or __scarletayuhuo_value_call(player,"hasSkill","toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end


sgs.ai_skill_playerchosen.s2_muyi = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and __scarletayuhuo_value_call(arr1[1],"getHp") < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				return friend
			end
		end
	end


	return target
end

sgs.ai_playerchosen_intention.s2_muyi = -80

sgs.ai_skill_choice["s2_muyi"] = function(self, choices, data)
	local items = choices:split("+")
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __scarletayuhuo_value_call(p,"hasFlag","s2_muyi_target") then
			local x = math.abs(__scarletayuhuo_value_call(p,"getHandcardNum") - __scarletayuhuo_value_call(self.player,"getHandcardNum"))
			if x > 1 then
				return "s2_muyi1"
			else
				return "s2_muyixd1"
			end
		end
	end
	return items[math.random(1, #items)]
end


sgs.ai_skill_invoke.s2_yaowu = function(self, data)
	local heart = 0
	local diamond = 0
	local spade = 0
	local club = 0
	local suit = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if __scarletayuhuo_value_call(card,"getSuitString") == "club" then
			club = 1
		elseif __scarletayuhuo_value_call(card,"getSuitString") == "spade" then
			spade = 1
		elseif __scarletayuhuo_value_call(card,"getSuitString") == "diamond" then
			diamond = 1
		elseif __scarletayuhuo_value_call(card,"getSuitString") == "heart" then
			heart = 1
		end
	end
	if club >= 1 then
		suit = suit + 1
	end
	if spade >= 1 then
		suit = suit + 1
	end
	if diamond >= 1 then
		suit = suit + 1
	end
	if heart >= 1 then
		suit = suit + 1
	end
	if suit == 2 then
		return true
	end
	if suit >= 3 or self:isWeak() then
		return true
	end
end


sgs.ai_fill_skill["s2_bayeVS"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)  do
		if (__scarletayuhuo_value_call(acard,"getSuit") == sgs.Card_Spade and __scarletayuhuo_value_call(self.player,"getKingdom") == "shu") or
		(__scarletayuhuo_value_call(acard,"getSuit") == sgs.Card_Heart and __scarletayuhuo_value_call(self.player,"getKingdom") == "wei") or
		(__scarletayuhuo_value_call(acard,"getSuit") == sgs.Card_Diamond and __scarletayuhuo_value_call(self.player,"getKingdom") == "wu") or
		(__scarletayuhuo_value_call(acard,"getSuit") == sgs.Card_Club and __scarletayuhuo_value_call(self.player,"getKingdom") == "qun")
			then
			return policy(self,"#s2_bayeCard:"..__scarletayuhuo_value_call(acard,"getEffectiveId")..":")
		end
	end
end

sgs.ai_skill_use_func["#s2_bayeCard"] = function(card,use,self)
	local targets = {}
	for _,friend in ipairs(self.friends_noself)do
		if __scarletayuhuo_value_call(friend,"hasLordSkill","s2_baye") then
			if not __scarletayuhuo_value_call(friend,"hasFlag","s2_bayeInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets,friend)
				end
			end
		end
	end
	if #targets>0 then --黄天己方
		use.card = card
		targets = self:sort(targets,"defense")
		use.to:append(targets[1])
	end
end

sgs.ai_card_intention["s2_bayeCard"] = function(self,card,from,tos)
	self:updateIntention(from,tos[1],-80)
end

sgs.ai_skill_invoke.s2_fanji = function(self, data)
	local target = data:toPlayer()
	local card = clone(self,"slash", sgs.Card_NoSuit, 0)
	card:deleteLater()
	card = mutate(self,card,"skill","s2_fanji")
	if target then
		local dummy_use = self:aiUseCard(card, dummy_plan(true, 0, self.room:getOtherPlayers(target)))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
			return true
		end
	end
	return false
end

sgs.ai_view_as.s2_fenzhan = function(card, player, card_place)
 local self=known(known(player:getRoom(),"view-as room")._ai,"view-as AI context")
	local usable_cards = sgs.QList2Table(complete_hand(self,player))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(usable_cards, visible(self,id))
		end
	end
	local suit = __scarletayuhuo_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __scarletayuhuo_value_call(card,"getEffectiveId")

	local two_cards = {}
	for _, c in ipairs(usable_cards) do
		if __scarletayuhuo_value_call(c,"getSuit") == __scarletayuhuo_value_call(card,"getSuit") and #two_cards < 2 then

			table.insert(two_cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
		end
	end


	if #two_cards == 2 and not __scarletayuhuo_value_call(card,"isKindOf","Jink") then
		return ("jink:s2_fenzhan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_cards[1], two_cards[2])
	end
end


sgs.ai_skill_invoke.s2_maifu = function(self, data)
	if __scarletayuhuo_value_call(self,"getHandcardNum") <= 4 and #self.enemies > 0 then return true end
	return false
end

sgs.ai_skill_playerchosen.s2_maifu = function(self, targets)
	targets = sgs.QList2Table(targets)
	self.enemies = self:sort(self.enemies, "hp")
	for _, p in ipairs(targets) do
		if p and self:isEnemy(p) then
			return p
		end
	end
	return targets[math.random(1, #targets)]
end

sgs.ai_skill_choice["s2_maifu"] = function(self, choices, data)
	local items = choices:split("+")
	local bad_skills = sgs.bad_skills:split("|")
	local can_duorui_items = {}
	for _, item in ipairs(items) do
		if not table.contains(bad_skills, item) then
			table.insert(can_duorui_items, item)
		end
	end
	return can_duorui_items[math.random(1, #can_duorui_items)]
end



sgs.ai_skill_invoke.s2_shuangdao = function(self, data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end


sgs.ai_skill_playerchosen.s2_huzhu = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) and friend:getEquips():length() then
			return friend
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.s2_huzhu = -80

sgs.ai_skill_defense["@s2_huzhu"] = function(self, player)
	local defense = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if __scarletayuhuo_value_call(p,"hasSkill","s2_huzhu") then
			defense = defense + __scarletayuhuo_value_call(p,"getHp")
			break
		end
	end
	return defense
end

sgs.ai_skill_playerchosen.s2_xiaoguo = function(self, targets)
	local target = self:findBestDamageTarget(1, "N")
	return target
end
sgs.ai_skill_cardask["s2_xiaoguo"] = function(self, data, pattern, target, target2)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local use_card = {}
	handcards = self:sortByKeepValue(handcards)
	for _, c in ipairs(handcards) do
		if not __scarletayuhuo_value_call(c,"isKindOf","Peach")
			and not __scarletayuhuo_value_call(c,"isKindOf","Analeptic")
			and not __scarletayuhuo_value_call(c,"isKindOf","Jink")
			and not __scarletayuhuo_value_call(c,"isKindOf","Nullification")
		then
			table.insert(use_card, c)
		end
	end
	if #use_card > 0 then
		return use_card[1]:toString()
	end
	return handcards[1]:toString()
end




sgs.ai_fill_skill["s2_xiaoguo"] = function(self,inclusive,request)
	if not self.player:hasUsed("#s2_xiaoguo") then return policy(self,"#s2_xiaoguo:.:") end
end

sgs.ai_skill_use_func["#s2_xiaoguo"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	handcards = self:sortByCardNeed(handcards, true)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if #targets < 2 and not enemy:isKongcheng() then
			table.insert(targets, enemy)
		else
			break
		end
	end
	if #targets ~= 2 then return end
	local card_str = ("#s2_xiaoguo:.:")
	local acard = policy(self,card_str)
	use.card = acard
	if use.to then
		for i = 1, #targets, 1 do
			use.to:append(targets[i])
		end
	end
end
sgs.ai_use_priority["s2_xiaoguo"] = 7
sgs.ai_use_value["s2_xiaoguo"] = 7


sgs.ai_fill_skill["s2_xiande"] = function(self,inclusive,request)
	if not self.player:hasUsed("#s2_xiande") and __scarletayuhuo_value_call(self.player,"getHp") >= 2 and sgs.ai_skill_playerchosen["s2_xiande_recover"](self,self.room:getAlivePlayers()) ~= nil  then return policy(self,"#s2_xiande:.:") end
end

sgs.ai_skill_use_func["#s2_xiande"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	handcards = self:sortByCardNeed(handcards, true)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if #targets < 2 and not enemy:isKongcheng() then
			table.insert(targets, enemy)
		else
			break
		end
	end
	if #targets ~= 2 then return end
	local card_str = ("#s2_xiande:.:")
	local acard = policy(self,card_str)
	use.card = acard
	if use.to then
		for i = 1, #targets, 1 do
			use.to:append(targets[i])
		end
	end
end
sgs.ai_use_priority["s2_xiande"] = 7
sgs.ai_use_value["s2_xiande"] = 7


sgs.ai_skill_cardask["s2_xiande"] = function(self, data, pattern, target, target2)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local use_card = {}
	handcards = self:sortByKeepValue(handcards)
	for _, c in ipairs(handcards) do
		if not __scarletayuhuo_value_call(c,"isKindOf","Peach")
			and not __scarletayuhuo_value_call(c,"isKindOf","Analeptic")
			and not __scarletayuhuo_value_call(c,"isKindOf","Jink")
			and not __scarletayuhuo_value_call(c,"isKindOf","Nullification")
		then
			table.insert(use_card, c)
		end
	end
	if #use_card > 0 then
		return use_card[1]:toString()
	end
	return handcards[1]:toString()
end


sgs.ai_skill_playerchosen["s2_xiande_draw"] = function(self, targets)
	local target = self:findPlayerToDraw(true, 2)
	if target then
		return target
	else
		self.friends = self:sort(self.friends, "hp")
		return self.friends[1]
	end
end
sgs.ai_skill_playerchosen["s2_xiande_recover"] = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1])) and __scarletayuhuo_value_call(arr1[1],"getHp") < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				return friend
			end
		end
	end


	return nil
end
sgs.ai_playerchosen_intention.s2_xiande_draw = -80
sgs.ai_playerchosen_intention.s2_xiande_recover = -80
sgs.exclusive_skill = sgs.exclusive_skill .. "|s2_toujing"

sgs.ai_skill_playerchosen.s2_toujing = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if __scarletayuhuo_value_call(player,"isLord") then lord = player end
		if self:isFriend(player) and (not target or __scarletayuhuo_value_call(target,"getHp") < __scarletayuhuo_value_call(player,"getHp")) then
			target = player
		end
	end
	if self.role == "loyalist" and lord then return lord end
	if target then return target end
	targetlist = self:sort(targetlist, "hp")
	return targetlist[1]
end

sgs.ai_skill_invoke["s2_tujin"] = function(self, data)
	local use = data:toCardUse()
	if use.to:length() > 1 then return true end
	local target = use.to:at(0)
	if self:isFriend(target) then return false end
	if not self:slashIsEffective(data:toCardUse().card, target) then return false end
	if getCardsNum("Jink", target, self.player) == 0 then return true end
	local player = use.from
	if target:isKongcheng() or self:canLiegong(target, player) then return true end
	if self:isWeak(target) and math.random(1, 2) == 1 then return true end
	if __scarletayuhuo_value_call(target,"getHandcardNum") == 1 and math.random(1, 3) > 1 then return true end
	if __scarletayuhuo_value_call(target,"getHandcardNum") > 3 then return false end
	return math.random(1, 5) == 1
end

sgs.ai_skill_playerchosen.s2_tujin = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if self:isEnemy(player) and (not target or __scarletayuhuo_value_call(target,"getHp") > __scarletayuhuo_value_call(player,"getHp")) then
			target = player
		end
	end
	if target then return target end
	targetlist = self:sort(targetlist, "hp")
	return targetlist[1]
end
sgs.ai_playerchosen_intention.s2_tujin = 50

sgs.ai_skill_choice["s2_zhenyan_draw"] = function(self, choices, data)
	return "5"
end

sgs.ai_skill_playerchosen.s2_zhenyan = function(self, targets)
	local target = self:findPlayerToDraw(true, 1)
	if target then
		return target
	else
		self.friends = self:sort(self.friends, "hp")
		return self.friends[1]
	end
end
sgs.ai_playerchosen_intention.s2_zhenyan = function(self, from, to)
	self:updateIntention(from, to, -50)
end


sgs.ai_skill_askforag["s2_zhenyan"] = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, visible(self,card_id))
	end
	to_obtain = self:sortByCardNeed(to_obtain, true)
	return __scarletayuhuo_value_call(to_obtain[1],"getEffectiveId")
end

sgs.ai_skill_invoke.s2_boxing = function(self, data)
	local damage = data:toDamage()
	if self:isWeak() or damage.damage >= 2 then
		return damage.nature == sgs.DamageStruct_Normal or
		(damage.nature ~= sgs.DamageStruct_Normal and not self:isGoodChainTarget(self.player, damage.card, damage.from, damage.damage))
	end
end

sgs.ai_skill_playerchosen.s2_boxing = function(self, targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getEquips():length() > 0 and (self:isWeak(p) or p:hasSkills(sgs.lose_equip_skill)) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getEquips():length() > 0 then
			return p
		end
	end
end
sgs.ai_playerchosen_intention.s2_boxing = function(self, from, to)
	self:updateIntention(from, to, -50)
end


sgs.ai_fill_skill["s2_jinchi"] = function(self,inclusive,request)
	if not self.player:getArmor() then return end

	return policy(self,"#s2_jinchi:.:")
end

sgs.ai_skill_use_func["#s2_jinchi"] = function(card, use, self)
	if not self.player:getArmor() then return end

	local target
	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) and friend:getEquip(2) == nil and friend:hasEquipArea(2) and __scarletayuhuo_value_call(friend,"getHandcardNum") > 5 and __scarletayuhuo_value_call(friend,"isMale") then
			target = friend
			break
		end
		if target then break end
		if friend:getEquip(2) == nil and friend:hasEquipArea(2) and __scarletayuhuo_value_call(friend,"getHandcardNum") > 5 and __scarletayuhuo_value_call(friend,"isMale") then
			target = friend
			break
		end
		if target then break end
	end

	if not target then return end
	local acard = policy(self,"#s2_jinchi:.:")
	use.card = acard
end


sgs.ai_skill_playerchosen.s2_jinchi = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) and friend:getEquip(2) == nil and friend:hasEquipArea(2) and __scarletayuhuo_value_call(friend,"getHandcardNum") > 5 and __scarletayuhuo_value_call(friend,"isMale") then
			return friend
		end
		if target then break end
		if friend:getEquip(2) == nil and friend:hasEquipArea(2) and __scarletayuhuo_value_call(friend,"getHandcardNum") > 5 and __scarletayuhuo_value_call(friend,"isMale") then
			return friend
		end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.s2_jinchi = function(self, from, to)
	self:updateIntention(from, to, -50)
end

sgs.ai_view_as.s2_douba = function(card, player, card_place)
 local self=known(known(player:getRoom(),"view-as room")._ai,"view-as AI context")
	local suit = __scarletayuhuo_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __scarletayuhuo_value_call(card,"getEffectiveId")
	if (card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id))
		and card:isRed() and not __scarletayuhuo_value_call(card,"isKindOf","Peach") and not __scarletayuhuo_value_call(card,"hasFlag","using") and not (__scarletayuhuo_value_call(card,"isKindOf","WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("slash:s2_douba[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_fill_skill["s2_douba"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, visible(self,id))
		end
	end
	local red_card
	local black_card
	cards = self:sortByUseValue(cards, true)

	local useAll = false
	self.enemies = self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if __scarletayuhuo_value_call(enemy,"getHp") == 1 and not enemy:hasArmorEffect("eight_diagram") and __scarletayuhuo_value_call(self.player,"distanceTo",enemy) <= __scarletayuhuo_value_call(self.player,"getAttackRange") and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") <= 0 or __scarletayuhuo_value_call(self.player,"hasSkill","paoxiao") then
		disCrossbow = true
	end


	for _, card in ipairs(cards) do
		if card:isRed() and not __scarletayuhuo_value_call(card,"isKindOf","Slash") and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or residue(self,clone(self,"slash")) > 0)
			and not (__scarletayuhuo_value_call(card,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			red_card = card
			break
		end
	end
	for _, card in ipairs(cards) do
		if card:isBlack() and (not isCard("Crossbow", card, self.player))
			and (self:getUseValue(card) < sgs.ai_use_value.Duel or inclusive) then
			black_card = card
			break
		end
	end

	if black_card then
		local suit = __scarletayuhuo_value_call(black_card,"getSuitString")
		local number = black_card:getNumberString()
		local card_id = __scarletayuhuo_value_call(black_card,"getEffectiveId")
		local card_str = ("duel:s2_douba[%s:%s]=%d"):format(suit, number, card_id)
		local duel = policy(self,card_str)

		assert(duel)
		return duel
	end
	if red_card then
		local suit = __scarletayuhuo_value_call(red_card,"getSuitString")
		local number = red_card:getNumberString()
		local card_id = __scarletayuhuo_value_call(red_card,"getEffectiveId")
		local card_str = ("slash:s2_douba[%s:%s]=%d"):format(suit, number, card_id)
		local slash = policy(self,card_str)

		assert(slash)
		return slash
	end
end


sgs.ai_fill_skill["s2_zhanpo"] = function(self,inclusive,request)
	local z = __scarletayuhuo_value_call(self.player,"getLostHp") + 1
	if not self.player:hasUsed("#s2_zhanpo") and __scarletayuhuo_value_call(self.player,"getMark","s2_zhanpoduel") >= z then
		return policy(self,"#s2_zhanpo:.:")
	end
end

sgs.ai_skill_use_func["#s2_zhanpo"] = function(card, use, self)
	local target
	for _, enemy in ipairs(self.enemies) do
		if not self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, enemy) and enemy:getWeapon() then
			target = enemy
			break
		end
		if target then break end
		if enemy:getWeapon() then
			target = friend
			break
		end
		if target then break end
	end

	if not target then return end
	local acard = policy(self,"#s2_zhanpo:.:")
	use.card = acard
	if use.to then use.to:append(target) end
end




sgs.ai_skill_playerchosen.s2_zhanpo = function(self, targets)
	self.friends_noself = self:sort(self.friends_noself, "handcard")
	for _, friend in ipairs(self.friends_noself) do
		if __scarletayuhuo_value_call(friend,"getHandcardNum") < __scarletayuhuo_value_call(self.player,"getHandcardNum") then
			return friend
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.s2_zhanpo = function(self, from, to)
	self:updateIntention(from, to, -50)
end

sgs.ai_skill_invoke.s2_taoni = function(self, data)
	local use = data:toCardUse()
	for _, p in sgs.qlist(use.to) do
		if p and self:isFriend(p) then
			return false
		end
	end
	return true
end
sgs.ai_cardneed.s2_taoni = sgs.ai_cardneed.slash

sgs.ai_skill_discard.s2_jubing = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	if cards[1] == nil then return {} end
	table.insert(to_discard, __scarletayuhuo_value_call(cards[1],"getEffectiveId"))
	if (sgs.ai_skill_invoke.fangquan(self)) then
		return to_discard
	end

	return {}
end
sgs.ai_skill_playerchosen.s2_jubing = function(self, targets)
	local lord = self.room:getLord()
	if lord and self:isFriend(lord) and lord:objectName() ~= self.player:objectName() then
		return lord
	end
	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) then
		return AssistTarget
	end

	self.friends_noself = self:sort(self.friends_noself, "chaofeng")
	for _, target in ipairs(self.friends_noself) do
		if not __scarletayuhuo_value_call(target,"hasSkill","dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
			and (not self:willSkipPlayPhase(target) or __scarletayuhuo_value_call(target,"hasSkill","shensu")) then
			return target
		end
	end

	for _, target in ipairs(self.friends_noself) do
		if __scarletayuhuo_value_call(target,"hasSkill","dawu") then
			local use = true
			for _, p in ipairs(self.friends_noself) do
				if __scarletayuhuo_value_call(p,"getMark","@fog") > 0 then
					use = false
					break
				end
			end
			if use then
				return target
			end
		else
			return target
		end
	end
end
sgs.ai_playerchosen_intention.s2_jubing = function(self, from, to)
	self:updateIntention(from, to, -80)
end



sgs.ai_skill_playerchosen.s2_budai = function(self, targets)
	self.friends = self:sort(self.friends, "hp")
	for _, friend in ipairs(self.friends) do
		if __scarletayuhuo_value_call(self.player,"inMyAttackRange",friend) then
			return friend
		end
	end
	return self.player
end
sgs.ai_playerchosen_intention.s2_budai = function(self, from, to)
	self:updateIntention(from, to, -50)
end




sgs.ai_skill_invoke.s2_bashi = function(self, data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end


sgs.ai_fill_skill["s2_danjing"] = function(self,inclusive,request)
	if not self.player:hasUsed("#s2_danjing") and self.player:getPile("s2_shi"):length() > __scarletayuhuo_value_call(self.player,"getLostHp") then
		return policy(self,"#s2_danjing:.:")
	end
end

sgs.ai_skill_use_func["#s2_danjing"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "handcard")
	local target
	for _, p in ipairs(self.enemies) do
		if __scarletayuhuo_value_call(self.player,"canPindian",p) then
			target = p
		end
	end
	if target then
		use.card = card
	end
	return
end

sgs.ai_use_priority["s2_danjing"] = 2.61

sgs.ai_skill_playerchosen.s2_danjing = function(self, targets)
	self.enemies = self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if __scarletayuhuo_value_call(self.player,"canPindian",enemy, true) then
			return enemy
		end
	end
	return targets[1]
end
sgs.ai_cardneed.s2_xuezhan = sgs.ai_cardneed.slash

sgs.ai_getBestHp_skill.s2_tuwei = function(owner)
	return __scarletayuhuo_value_call(owner,"getMaxHp") - 1
end


sgs.ai_fill_skill["s2_leiyin"] = function(self,inclusive,request)
	if self:needBear() then return end
	if not self.player:hasUsed("#s2_leiyin") and not self.player:isKongcheng() then return policy(self,
		"#s2_leiyin:.:") end
end

sgs.ai_skill_use_func["#s2_leiyin"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard(self.player)
	local max_point = __scarletayuhuo_value_call(max_card,"getNumber")
	local slashcount = self:getCardsNum("Slash")
	if __scarletayuhuo_value_call(max_card,"isKindOf","Slash") then slashcount = slashcount - 1 end
	if __scarletayuhuo_value_call(self.player,"hasSkill","kongcheng") and __scarletayuhuo_value_call(self.player,"getHandcardNum") == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and __scarletayuhuo_value_call(self.player,"canPindian",enemy) then
				use.card = policy(self,"#s2_leiyin:" .. max_card:getId() .. ":")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if slashcount > 0 then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = self:aiUseCard(slash, dummy_plan())
		for _, enemy in ipairs(self.enemies) do
			if not (__scarletayuhuo_value_call(enemy,"hasSkill","kongcheng") and __scarletayuhuo_value_call(enemy,"getHandcardNum") == 1 and __scarletayuhuo_value_call(enemy,"getHp") > __scarletayuhuo_value_call(self.player,"getHp"))
				and not enemy:isKongcheng() and self.player:canSlash(enemy, nil, true) and __scarletayuhuo_value_call(self.player,"canPindian",enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local allknown = 0
				if self:getKnownNum(enemy) == __scarletayuhuo_value_call(enemy,"getHandcardNum") then
					allknown = allknown + 1
				end
				if (enemy_max_card and max_point > __scarletayuhuo_value_call(enemy_max_card,"getNumber") and allknown > 0)
					or (enemy_max_card and max_point > __scarletayuhuo_value_call(enemy_max_card,"getNumber") and allknown < 1 and max_point > 10)
					or (not enemy_max_card and max_point > 10) then
					use.card = policy(self,"#s2_leiyin:" .. max_card:getId() .. ":")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

function sgs.ai_skill_pindian.s2_leiyin(minusecard, self, requestor)
	if self:isFriend(requestor) then return minusecard end
	return self:getMaxCard()
end

sgs.ai_use_priority["s2_leiyin"] = sgs.ai_use_priority.DaheCard
sgs.ai_use_value["s2_leiyin"] = sgs.ai_use_value.DaheCard
sgs.ai_cardneed.s2_leiyin = sgs.ai_cardneed.bignumber




sgs.ai_view_as.s2_yezhan = function(card, player, card_place)
 local self=known(known(player:getRoom(),"view-as room")._ai,"view-as AI context")
	local suit = __scarletayuhuo_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __scarletayuhuo_value_call(card,"getEffectiveId")
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
		and card:isBlack() and not __scarletayuhuo_value_call(card,"hasFlag","using") then
		return ("slash:s2_yezhan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_fill_skill["s2_yezhan"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, visible(self,id))
		end
	end
	local black_card
	cards = self:sortByUseValue(cards, true)

	local useAll = false
	self.enemies = self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if __scarletayuhuo_value_call(enemy,"getHp") == 1 and not enemy:hasArmorEffect("eight_diagram") and __scarletayuhuo_value_call(self.player,"distanceTo",enemy) <= __scarletayuhuo_value_call(self.player,"getAttackRange") and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") <= 0 or __scarletayuhuo_value_call(self.player,"hasSkill","paoxiao") then
		disCrossbow = true
	end

	self.enemies = self:sort(self.enemies, "defense")

	for _, card in ipairs(cards) do
		if card:isBlack() and not __scarletayuhuo_value_call(card,"isKindOf","Slash")
			and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or residue(self,clone(self,"slash")) > 0) then
			black_card = card
			break
		end
	end


	if black_card then
		local suit = __scarletayuhuo_value_call(black_card,"getSuitString")
		local number = black_card:getNumberString()
		local card_id = __scarletayuhuo_value_call(black_card,"getEffectiveId")
		local card_str = ("slash:s2_yezhan[%s:%s]=%d"):format(suit, number, card_id)
		local slash = policy(self,card_str)

		assert(slash)
		return slash
	end
end


sgs.ai_ajustdamage_from.s2_shenwei = function(self, from, to, card, nature)
    if card and __scarletayuhuo_value_call(card,"isKindOf","Slash") and (__scarletayuhuo_value_call(card,"hasFlag","s2_shenwei") or (not self:beFriend(to, from) and getCardsNum("Slash", from, to) > 0))
    then
        return 1
    end
end

function sgs.ai_cardneed.s2_yezhan(to, card)
	return __scarletayuhuo_value_call(to,"getHandcardNum") < 3 and card:isBlack()
end

sgs.ai_skill_invoke.s2_yizhan = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then
		if damage.damage == 1 and self:needToLoseHp(target, damage.from, damage.card) then
			return false
		end
		return true
	else
		if self:hasHeavyDamage(self.player, damage.card, target) then return false end
		if self:isWeak(target) then return false end
		if self:needToLoseHp(target, damage.from, damage.card) then return true end
		return false
	end
end

sgs.ai_use_revises.s2_chuanyang = function(self,card,use)
	if __scarletayuhuo_value_call(card,"isKindOf","Slash") then
		self:setStrategyCardFlag(card,'Qinggang',true)
	end
end
sgs.ai_can_damagehp.s2_guimou_2 = function(self,from,card,to)
	return __scarletayuhuo_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
	and self:canLoseHp(from,card,to)
end


sgs.ai_skill_use["@@s2_andu"] = function(self, prompt)
	if self.player and (self.player:getPile("s2_gong"):length() > 0) then
		local use_card = {}

		for _, c in ipairs(sgs.QList2Table(self.player:getPile("s2_gong"))) do
			if (#use_card < 2) then
				table.insert(use_card, visible(self,c):getEffectiveId())
			end
		end
		if #use_card == 2 then
			return "#s2_andu:" .. table.concat(use_card, "+") .. ":"
		end
	end
	return "."
end


sgs.ai_skill_invoke.s2_shemi = function(self, data)
	if self:needBear() then return true end
	if self:isWeak() or not __scarletayuhuo_value_call(self.player,"faceUp") then return true end
	if self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) + __scarletayuhuo_value_call(self.player,"getLostHp") + 2 <= 5 then
		return true
	end
	return false
end

sgs.ai_skill_invoke.s2_jiujia = function(self)
	local lord = self.room:getCurrentDyingPlayer()
	local save = false
	if lord and __scarletayuhuo_value_call(lord,"getLostHp") > 0 then
		if self:isFriend(lord) then
			save = true
		elseif self.role == "renegade" and __scarletayuhuo_value_call(lord,"isLord") and self.room:alivePlayerCount() > 2 then
			if __scarletayuhuo_value_call(lord,"getHp") <= 0 then
				save = true
			end
		end
	end
	if save then
		local hp_max = __scarletayuhuo_value_call(lord,"getHp") + self:getAllPeachNum(lord)
		local must_save = (hp_max <= 1)

		if not __scarletayuhuo_value_call(self.player,"faceUp") then
			return true
		elseif must_save then
			if hp_max <= 0 then
				return true
			elseif self.role == "renegade" or self.role == "lord" then
				return false
			end
		end
	end
	return false
end
sgs.ai_choicemade_filter["skillInvoke"]["s2_jiujia"] = function(self, player, promptlist)
	if #promptlist == "yes" then
		local lord = self.room:getCurrentDyingPlayer()
		if lord and not self:hasSkills(sgs.masochism_skill, player) then
			self:updateIntention(player, lord, -60)
		end
	end
end


sgs.ai_cardneed.s2_feijun = sgs.ai_cardneed.bignumber
sgs.ai_skill_invoke.s2_feijun = function(self, data)
	local damage = data:toDamage()
	local dummy_use = self:aiUseCard(damage.card,dummy_plan(true,0,self.room:getOtherPlayers(damage.to)))
	if dummy_use.card and dummy_use.to:contains(damage.to) then
		local max_card = self:getMaxCard()
		if max_card and __scarletayuhuo_value_call(max_card,"getNumber") > 10 then
			return self:isEnemy(damage.to)
		end
		if self:isEnemy(damage.to) then
			if self:getOverflow() > 0 then return true end
		end
	end
	return false
end

function sgs.ai_skill_pindian.s2_feijun(minusecard, self, requestor, maxcard)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local function compare_func(a, b)
		return __scarletayuhuo_value_call(a,"getNumber") > __scarletayuhuo_value_call(b,"getNumber")
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if __scarletayuhuo_value_call(card,"getNumber") > 10 then return card end
	end
	cards = self:sortByKeepValue(cards)
	return cards[1]
end

sgs.ai_fill_skill["s2_chizha"] = function(self,inclusive,request)
	if not self.player:hasUsed("#s2_chizha") then
		return policy(self,"#s2_chizha:.:")
	end
end

sgs.ai_skill_use_func["#s2_chizha"] = function(card, use, self)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)

	local target
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if self:getDangerousCard(enemy) then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				target = friend
				break
			end
		end
	end
	if not target then
		self.enemies = self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if self:getValuableCard(enemy) then
				target = enemy
				break
			end
			if target then break end

			local cards = sgs.QList2Table(complete_hand(self,enemy))
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
			if not enemy:isKongcheng() and not hasTuntianEffect(enemy, true) then
				for _, cc in ipairs(cards) do
					if (__scarletayuhuo_value_call(cc,"hasFlag","visible") or __scarletayuhuo_value_call(cc,"hasFlag",flag)) and (__scarletayuhuo_value_call(cc,"isKindOf","Peach") or __scarletayuhuo_value_call(cc,"isKindOf","Analeptic")) then
						target = enemy
						break
					end
				end
			end
			if target then break end

			if self:getValuableCard(enemy) then
				target = enemy
				break
			end
			if target then break end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if hasTuntianEffect(friend, true) and not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				target = friend
				break
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isNude() then
				target = enemy
				break
			end
		end
	end

	if target then
		local willUse
		if self:isFriend(target) then
			for _, card in ipairs(cards) do
				if __scarletayuhuo_value_call(card,"getSuit") == sgs.Card_Heart then
					willUse = card
					break
				end
			end
		else
			for _, card in ipairs(cards) do
				if __scarletayuhuo_value_call(card,"getSuit") == sgs.Card_Heart and not isCard("Peach", card, target) and not isCard("Nullification", card, target) then
					willUse = card
					break
				end
			end
		end

		if willUse then
			use.card = policy(self,"#s2_chizha:" .. __scarletayuhuo_value_call(willUse,"getEffectiveId") .. ":")
			if use.to then use.to:append(target) end
		end
	end
end


sgs.ai_skill_invoke.s2_chizha = function(self, data)
	local target = data:toPlayer()
	if target then
		if self:isFriend(target) then
			return (self:needKongcheng(target, true) or (self:isWeak(target) and __scarletayuhuo_value_call(target,"getHandcardNum") < 2 and self:getMaxCard(target) < 8))
		elseif self:isEnemy(target) then
			return true
		end
	end
end

sgs.ai_cardneed.s2_qigong = sgs.ai_cardneed.slash
sgs.s2_qigong_keep_value = sgs.paoxiao_keep_value

sgs.ai_need_damaged.s2_hengjiang = function(self, attacker, player)
	if not __scarletayuhuo_value_call(player,"hasSkill","chanyuan") and __scarletayuhuo_value_call(player,"hasSkill","s2_hengjiang") and __scarletayuhuo_value_call(player,"getMark","s2_hengjiang") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < __scarletayuhuo_value_call(player,"getHp")
		and (__scarletayuhuo_value_call(player,"getHp") > 2 or __scarletayuhuo_value_call(player,"getHp") == 2 and (__scarletayuhuo_value_call(player,"faceUp") or __scarletayuhuo_value_call(player,"hasSkill","guixin") or __scarletayuhuo_value_call(player,"hasSkill","toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end



sgs.ai_skill_playerchosen.s2_jizhan = sgs.ai_skill_playerchosen.zero_card_as_slash


sgs.ai_skill_cardask["@s2_jizhan-exchange"] = function(self, data)
	local suit = data:toString()
	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return "." end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not __scarletayuhuo_value_call(card,"hasFlag","using") and __scarletayuhuo_value_call(card,"getSuitString") == suit and not __scarletayuhuo_value_call(card,"isKindOf","Peach") then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	local slash = clone(self,"slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	local victims = AIList.new({})
	slash = mutate(self,slash,"skill","s2_jizhan")
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:canSlash(p, slash, false) then
			victims:append(p)
		end
	end
	if not victims:isEmpty() then
	if sgs.ai_skill_playerchosen.zero_card_as_slash(self,victims) ~= nil then
		return "$" .. cards[1]:getId()
	end
end
	return "."
end

sgs.ai_fill_skill["s2_xubian"] = function(self,inclusive,request)
	if self.player:isKongcheng() then return end
	if self.player:hasUsed("#s2_xubian") then return end
	if self:getCardsNum("BasicCard") + self:getCardsNum("Nullification") == __scarletayuhuo_value_call(self.player,"getHandcardNum") and __scarletayuhuo_value_call(self.player,"getHandcardNum") <= __scarletayuhuo_value_call(self.player,"getHp") then return end
	local handcards = sgs.QList2Table(self.player:getHandcards())
	handcards = self:sortByKeepValue(handcards)
	if __scarletayuhuo_value_call(handcards[1],"isKindOf","Peach") then return end
	return policy(self,"#s2_xubian:.:")
end

sgs.ai_skill_use_func["#s2_xubian"] = function(card, use, self)
	local card

	local to_use = {}
	if self.player:isKongcheng() then return end

	local handcards = sgs.QList2Table(self.player:getHandcards())
	handcards = self:sortByKeepValue(handcards)

	for _, c in ipairs(handcards) do
		if #to_use < 3 then
			if self:getOverflow() > 0 then
				if not __scarletayuhuo_value_call(c,"isKindOf","Peach") then
					table.insert(to_use, __scarletayuhuo_value_call(c,"getEffectiveId"))
				end
			else
				if __scarletayuhuo_value_call(c,"isKindOf","Jink") then
					table.insert(to_use, __scarletayuhuo_value_call(c,"getEffectiveId"))
				end
			end
		end
	end
	if #to_use > 0 then
		use.card = policy(self,"#s2_xubian:" .. table.concat(to_use, "+") .. ":")
		return
	end
end


sgs.ai_fill_skill["s2_qingfa"] = function(self,inclusive,request)
	if self.player:getPile("s2_zu"):isEmpty()
		or (__scarletayuhuo_value_call(self.player,"getHandcardNum") >= __scarletayuhuo_value_call(self.player,"getHp") + 2
			and self.player:getPile("s2_zu"):length() <= self.room:getAlivePlayers():length() / 2 - 1) then
		return
	end
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getPile("s2_zu"):length() >= 2 then
		local cards = {}
		local same_suit = false

		if self.player:getPile("s2_zu"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("s2_zu")) do
				table.insert(cards, visible(self,id))
			end
		end

		cards = self:sortByKeepValue(cards)
		for _, fcard in ipairs(cards) do
			first_card = fcard
			first_found = true
			for _, scard in ipairs(cards) do
				if not AIValue.sameLegacyIdentity(first_card,scard) then
					local card_str = ("snatch:s2_qingfa[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(),
						scard:getId())
					local snatch = policy(self,card_str)

					assert(snatch)

					local dummy_use = self:aiUseCard(snatch, dummy_plan())
					if dummy_use.card then
						second_card = scard
						second_found = true
						break
					end
				end
				if second_card then break end
			end
		end
	end

	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local snatch_str = ("snatch:s2_qingfa[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local jixisnatch = policy(self,snatch_str)

		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if (__scarletayuhuo_value_call(self.player,"distanceTo",player, 1) <= 1 + known(jixisnatch:getTargetModDistance(self.player),"Snatch distance modifier"))
				and not self.room:isProhibited(self.player, player, jixisnatch) and self:hasTrickEffective(jixisnatch, player) then
				local first_id = first_card:getId()
				local second_id = second_card:getId()
				local card_str = ("snatch:s2_qingfa[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
				local snatch = policy(self,card_str)
				assert(snatch)
				return snatch
			end
		end
	end
end


sgs.ai_view_as.s2_xubian = function(card, player, card_place)
 local self=known(known(player:getRoom(),"view-as room")._ai,"view-as AI context")
	local suit = __scarletayuhuo_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __scarletayuhuo_value_call(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "s2_zu" then
		return ("jink:s2_qingfa[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_skill_playerchosen.s2_guijin = function(self, targets)
    targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		return target
	end
	return nil
end

sgs.ai_use_revises.s2_guijin = function(self,card,use)
	if __scarletayuhuo_value_call(card,"isKindOf","Slash") and __scarletayuhuo_value_call(self.player,"hasSkill","s2_z_baye") and __scarletayuhuo_value_call(self.player,"getPhase") == sgs.Player_Play
	and (#self.enemies>1 or #self.friends>1)
	then
		local x = 0
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if __scarletayuhuo_value_call(p,"getKingdom") == "jin" then
				x = x + 1
			end
		end
		if x < (self.room:getAlivePlayers():length()/2) then
		return false end
		end
end

sgs.ai_skill_use["@@s2_qiangrang"] = function(self, prompt)
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	local effect = room_tag(self,"CurrentUseStruct","CardEffect")
	local card = effect.card
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if (__scarletayuhuo_value_call(self.player,"getHandcardNum") > 0) then
		for _, acard in ipairs(cards) do
			if #needed < 1 and not __scarletayuhuo_value_call(acard,"isKindOf","Peach") then
				table.insert(needed, __scarletayuhuo_value_call(acard,"getEffectiveId"))
			end
		end
	end
	if #needed > 0 and card then
		local target
		if __scarletayuhuo_value_call(card,"isKindOf","GodSalvation") then
			local lord = self.room:getLord()
			if self:isWeak(lord) and viewer_role(self,self.player) == "loyalist" and self:hasTrickEffective(card, effect.from, lord) and table.contains(targets, lord) then
				return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. lord:objectName()
			end
			self.friends = self:sort(self.friends, "hp")
			if self:isWeak() and self:hasTrickEffective(card, effect.from, self.player) then
				return "."
			else
				for _, p in sgs.qlist(self.friends) do
					if self:hasTrickEffective(card, effect.from, p) and __scarletayuhuo_value_call(p,"getHp") < getBestHp(p) and table.contains(targets, p) then
						return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. p:objectName()
					end
				end
			end
		elseif __scarletayuhuo_value_call(card,"isKindOf","Duel") or __scarletayuhuo_value_call(card,"isKindOf","FireAttack") or __scarletayuhuo_value_call(card,"isKindOf","EXCard_WWJZ") then
			local nature = sgs.DamageStruct_Normal
			if __scarletayuhuo_value_call(card,"isKindOf","FireAttack") then
				nature = sgs.DamageStruct_Fire
			end
			self.enemies = self:sort(self.enemies, "hp")
			self.friends = self:sort(self.friends, "hp")
			for _, enemy in ipairs(self.enemies) do
				if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nature) and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
			for _, friend in ipairs(self.friends) do
				if ((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, effect.from, false)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, effect.from, friend) or not self:damageIsEffective(friend, nature) and table.contains(targets, friend) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. friend:objectName()
				end
			end
		elseif __scarletayuhuo_value_call(card,"isKindOf","ArcheryAttack") or __scarletayuhuo_value_call(card,"isKindOf","SavageAssault") then
			local nature = sgs.DamageStruct_Normal
			if __scarletayuhuo_value_call(card,"isKindOf","FireAttack") then
				nature = sgs.DamageStruct_Fire
			end
			self.enemies = self:sort(self.enemies, "hp")
			self.friends = self:sort(self.friends, "hp")
			for _, enemy in ipairs(self.enemies) do
				if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nature) and not enemy:hasArmorEffect("vine") and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and not enemy:hasArmorEffect("vine") and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
			for _, friend in ipairs(self.friends) do
				if (((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, effect.from, false)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, effect.from, friend) or not self:damageIsEffective(friend, nature) or friend:hasArmorEffect("vine")) and table.contains(targets, friend) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. friend:objectName()
				end
			end
			return targets[1]
		elseif __scarletayuhuo_value_call(card,"isKindOf","Collateral") then
			self.enemies = self:sort(self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getWeapon()) and self:hasTrickEffective(card, effect.from, enemy) and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
		elseif __scarletayuhuo_value_call(card,"isKindOf","Dismantlement") or __scarletayuhuo_value_call(card,"isKindOf","Snatch") then
			if self:isFriend(effect.from) and (self.player:getJudgingArea():length() > 0 or self:hasSkills(sgs.lose_equip_skill, self.player)) and self:hasTrickEffective(card, effect.from, self.player) then
				return nil
			end
			if __scarletayuhuo_value_call(card,"isKindOf","Dismantlement") then
				self.enemies = self:sort(self.enemies, "handcard")
				for _, enemy in ipairs(self.enemies) do
					if self:doDisCard(enemy) and self:hasTrickEffective(card, effect.from, enemy) and table.contains(targets, enemy) then
						return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
					end
				end
				for _, enemy in ipairs(self.enemies) do
					if self:hasTrickEffective(card, effect.from, enemy) and table.contains(targets, enemy) then
						return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
					end
				end
			end
		elseif __scarletayuhuo_value_call(card,"isKindOf","GodFlower") or __scarletayuhuo_value_call(card,"isKindOf","Snatch") then
			self.enemies = self:sort(self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if self:isEnemy(effect.from) and self:hasTrickEffective(card, effect.from, enemy) and (enemy:getJudgingArea():length() < 1 or not self:hasSkills(sgs.lose_equip_skill, enemy)) and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
		elseif __scarletayuhuo_value_call(card,"isKindOf","IronChain") then
			for _, friend in ipairs(self.friends) do
				if self:hasTrickEffective(card, effect.from, friend) and friend:isChained() and table.contains(targets, friend) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. friend:objectName()
				end
			end

			for _, enemy in ipairs(self.enemies) do
				if self:hasTrickEffective(card, effect.from, enemy) and table.contains(targets, enemy) and not enemy:isChained() then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
		end
	end
	return "."
end


sgs.ai_ajustdamage_from.s2_mieshi = function(self, from, to, card, nature)
    if card and __scarletayuhuo_value_call(card,"isKindOf","Slash") and __scarletayuhuo_value_call(card,"hasFlag","s2_mieshi")
    then
        return __scarletayuhuo_value_call(from,"getMark","s2_mieshi")
    end
end

sgs.ai_skill_use["@@s2_mieshi"] = function(self, prompt)
	local suit = property(self,"s2_mieshi")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local use = room_tag(self,"CurrentUseStruct","CardUse")
	for _, p in sgs.qlist(use.to) do
		if p and self:isFriend(p) then
			return "."
		end
	end
	local needed = {}
	if (__scarletayuhuo_value_call(self.player,"getHandcardNum") > 0) then
		for _, acard in ipairs(cards) do
			if #needed < 1 and not __scarletayuhuo_value_call(acard,"isKindOf","Peach") and __scarletayuhuo_value_call(acard,"getSuitString") ~= suit then
				table.insert(needed, __scarletayuhuo_value_call(acard,"getEffectiveId"))
			end
		end
	end
	if #needed > 0 then
		return "#s2_mieshi:" .. table.concat(needed, "+") .. ":"
	end
	return "."
end


sgs.ai_skill_use["@@s2_zhonghun"] = function(self, prompt)
	self.friends = self:sort(self.friends, "hp")
	local targets = {}
	local lord = self.room:getLord()
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self.friends = self:sort(self.friends, "defense")
	if lord and self:isFriend(lord) and not known(self:isLordHealthy(),"lord health") and not __scarletayuhuo_value_call(self.player,"isLord")  then
		table.insert(targets, lord)
	else
		for _, friend in ipairs(self.friends_noself) do
			if self:isWeak(friend) then
				table.insert(targets, friend)
				break
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if not table.contains(targets, friend) then
				table.insert(targets, friend)
				break
			end
		end
	end
	local needed = {}
	if (__scarletayuhuo_value_call(self.player,"getHandcardNum") > 0) then
		for _, acard in ipairs(cards) do
			if #needed < 1 and not __scarletayuhuo_value_call(acard,"isKindOf","Peach") then
				table.insert(needed, __scarletayuhuo_value_call(acard,"getEffectiveId"))
			end
		end
	end
	if #targets > 0 and #needed > 0 then
		return "#s2_zhonghun:" .. table.concat(needed, "+") .. ":->" .. targets[1]:objectName()
	end
	return "."
end


sgs.ai_skill_invoke.s2_zhonghun = function(self, data)
	local use = data:toCardUse()
	if use.card and __scarletayuhuo_value_call(use.card,"hasFlag","NosJiefanUsed") then return false  end
	if not use.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,use.from)
	or __scarletayuhuo_value_call(use.card,"isKindOf","NatureSlash") and  self.player:isChained() and self:isGoodChainTarget( self.player,use.card,use.from)
	or self:needToLoseHp( self.player,use.from,use.card) and self:ajustDamage(use.from, self.player,1,use.card)==1 then return false end
	if self:needToLoseHp(self.player, use.from, use.card, true) then return false end
	if self:getCardsNum("Jink") == 0 then return true end

	return true
end


sgs.ai_skill_invoke.s2_guantian = true


sgs.ai_skill_discard.s2_duanjia = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards, true)
	local stealer
	for _, ap in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if ap:hasSkills("tuxi|nostuxi") and self:isEnemy(ap) then stealer = ap end
	end
	local card
	for i = 1, #cards, 1 do
		local isPeach = cards[i]:isKindOf("Peach")
		if isPeach then
			if stealer and self:isEnemy(stealer) and __scarletayuhuo_value_call(self.player,"getHandcardNum") <= 2 and __scarletayuhuo_value_call(self.player,"getHp") > 2
				and (not stealer:containsTrick("supply_shortage") or stealer:containsTrick("YanxiaoCard")) then
				card = cards[i]
				break
			end
			local to_discard_peach = true
			for _, fd in ipairs(self.friends) do
				if __scarletayuhuo_value_call(fd,"getHp") <= 2 and not __scarletayuhuo_value_call(fd,"hasSkill","niepan") then
					to_discard_peach = false
				end
			end
			if to_discard_peach then
				card = cards[i]
				break
			end
		else
			card = cards[i]
			break
		end
	end
	if card == nil then return {} end
	table.insert(to_discard, __scarletayuhuo_value_call(card,"getEffectiveId"))
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		if not current:containsTrick("YanxiaoCard") then
			if (current:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies))
				or (current:containsTrick("lightning") and #self.friends > #self.enemies) then
				return to_discard
			elseif current:containsTrick("supply_shortage") then
				if __scarletayuhuo_value_call(self.player,"getHp") > __scarletayuhuo_value_call(self.player,"getHandcardNum") then return to_discard end
			elseif current:containsTrick("indulgence") then
				if __scarletayuhuo_value_call(self.player,"getHandcardNum") > 3 or __scarletayuhuo_value_call(self.player,"getHandcardNum") > __scarletayuhuo_value_call(self.player,"getHp") - 1 then return
					to_discard end
				for _, friend in ipairs(self.friends_noself) do
					if not friend:containsTrick("YanxiaoCard") and (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
						return to_discard
					end
				end
			end
		end
	end
	return {}
end


sgs.ai_fill_skill["s2_tiantan"] = function(self,inclusive,request)
	if self.player:hasUsed("#s2_tiantan") then return end
	if #self.enemies < 1 then return end
	return policy(self,"#s2_tiantan:.:")
end

sgs.ai_skill_use_func["#s2_tiantan"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	cards = self:sortByKeepValue(cards)
	local first_found, second_found = false, false
	local first_card, second_card
	local acard
	for _, fcard in ipairs(cards) do
		local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
		if not fvalueCard then
			first_card = fcard
			first_found = true
			for _, scard in ipairs(cards) do
				local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
				if not AIValue.sameLegacyIdentity(first_card,scard) and __scarletayuhuo_value_call(scard,"getNumber") == __scarletayuhuo_value_call(first_card,"getNumber")
					and not svalueCard then
					second_card = scard
					second_found = true
					table.insert(to_discard, __scarletayuhuo_value_call(fcard,"getEffectiveId"))
					table.insert(to_discard, __scarletayuhuo_value_call(scard,"getEffectiveId"))
					break
				end
			end
			if second_card then break end
		end
	end

	if #to_discard == 2 and first_found and second_found then
		self.enemies = self:sort(self.enemies)
		local target
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				if __scarletayuhuo_value_call(self.player,"distanceTo",enemy) == 1 then
					target = enemy
					break
				end
			end
		end
		if target then
			local card_str = string.format("#s2_tiantan:%s:", table.concat(to_discard, "+"))
			use.card = policy(self,card_str)
			if use.to then use.to:append(target) end
			return
		end
	end
end

sgs.ai_use_value["#s2_tiantan"] = 2.5
sgs.ai_card_intention["#s2_tiantan"] = 80
sgs.dynamic_value.damage_card["#s2_tiantan"] = true




sgs.ai_fill_skill["s2_yinyang"] = function(self,inclusive,request)
	if __scarletayuhuo_value_call(self.player,"getMark","@s2_yinyang") <= 0 then return end
	if self.player:getPile("s2_fu"):length() == 0 or (self.player:getPile("s2_fu"):length() > 5 and not self:isWeak()) then return end
	if self.room:getMode() == "_mini_13" then return policy(self,"#s2_yinyang:.:") end
	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and self:isWeak(lord) then return end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) and self:damageIsEffective(player, sgs.DamageStruct_Normal) then
			if self:isFriend(player) then
				bad = bad + 1
			else
				good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(__scarletayuhuo_value_call(player,"getHp"), 1)
		if self:damageIsEffective(player, sgs.DamageStruct_Normal) then
			if getCardsNum("Analeptic", player) > 0 then
				if self:isFriend(player) then
					good = good + 1.0 / hp
				else
					bad = bad + 1.0 / hp
				end
			end


			local lost_value = 0
			if self:hasSkills(sgs.masochism_skill, player) then lost_value = __scarletayuhuo_value_call(player,"getHp") / 2 end
			local hp = math.max(__scarletayuhuo_value_call(player,"getHp"), 1)
			if self:isFriend(player) then
				bad = bad + (lost_value + 1) / hp
			else
				good = good + (lost_value + 1) / hp
			end
		end
	end

	if good > bad then return policy(self,"#s2_yinyang:.:") end
end

sgs.ai_skill_use_func["#s2_yinyang"] = function(card, use, self)
	use.card = card
end



sgs.ai_skill_use["@@s2_danmu"] = function(self, prompt, method)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "defense")
	local targets = {}
	local card = visible(self,__scarletayuhuo_value_call(self.player,"getMark","card_id"))
	local use_card = {}
	if card then
		for _, enemy in ipairs(self.enemies) do
			if #targets < self.player:getPile("s2_fu"):length() and not __scarletayuhuo_value_call(enemy,"hasFlag","s2_danmu") and self:cardTargetFilter(card,AIList.new({}),enemy) and not self.player:isProhibited(enemy, card) and self:slashIsEffective(card, enemy) then
				table.insert(targets, enemy:objectName())
			end
		end
	end
	if #targets > 0 then
		for _, id in sgs.qlist(self.player:getPile("s2_fu")) do
			if #use_card < #targets then
				table.insert(use_card, id)
			end
		end
		if #targets == #use_card then
			return "#s2_danmu:" .. table.concat(use_card, "+") .. ":->" .. table.concat(targets, "+")
		end
	end
	return "."
end

sgs.ai_skill_playerchosen["s2_saiqian"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "handcard")
	for _, p in ipairs(targets) do
		if not p:isNude() then
			if self:isEnemy(p) and not (p:hasArmorEffect("silver_lion") and __scarletayuhuo_value_call(p,"isWounded")) then
				if p:getEquips():length() > 0 then
					if not p:hasSkills(sgs.lose_equip_skill) then
						return p
					end
				else
					return p
				end
			end
		end
	end
	targets = sgs.reverse(targets)
	for _, p in ipairs(targets) do
		if not p:isNude() then
			if self:isFriend(p) and __scarletayuhuo_value_call(p,"getHp") > 2 and __scarletayuhuo_value_call(p,"getHandcardNum") > 2 then
				return p
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["s2_saiqian"] = function(self, from, to)
	if known(self.world.turn_count,"turn count") <= 1 then
		self:updateIntention(from, to, 80)
	end
end

sgs.ai_skill_cardask["@s2_saiqian"] = function(self, data, pattern, target, target2)
	local current = self.room:getCurrent()
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	usable_cards = self:sortByKeepValue(usable_cards)
	local give_card = {}
	if self.player:hasArmorEffect("silver_lion") and __scarletayuhuo_value_call(self.player,"isWounded") then
		for _, c in ipairs(usable_cards) do
			if __scarletayuhuo_value_call(c,"isKindOf","SilverLion") then
				return c:getLegacyStringKey()
			end
		end
	end
	if self:isFriend(current) then
		for _, c in ipairs(usable_cards) do
			if __scarletayuhuo_value_call(c,"isKindOf","Slash")
				or __scarletayuhuo_value_call(c,"isKindOf","Duel")
				or __scarletayuhuo_value_call(c,"isKindOf","SavageAssault")
				or __scarletayuhuo_value_call(c,"isKindOf","ArcheryAttack")
				or __scarletayuhuo_value_call(c,"isKindOf","Snatch")
				or __scarletayuhuo_value_call(c,"isKindOf","Dismantlement")
			then
				table.insert(give_card, c)
			end
		end
		if #give_card > 0 then
			return give_card[1]:toString()
		end
	end
	if self.player:hasSkills(sgs.lose_equip_skill) and self.player:getEquips():length() > 0 then
		local equipments = sgs.QList2Table(self.player:getCards("e"))
		equipments = self:sortByKeepValue(equipments)
		for _, e in ipairs(equipments) do
			return e:getLegacyStringKey()
		end
	end
	for _, c in ipairs(usable_cards) do
		return c:getLegacyStringKey()
	end
end

sgs.ai_ajustdamage_to.s2_hufu = function(self,from,to,slash,nature)
	if nature ~= "N"
	then return -99 end
end



sgs.ai_fill_skill["s2_2_zhanjiang"] = function(self,inclusive,request)
	if self.player:hasUsed("#s2_2_zhanjiang") or self.player:isKongcheng() then return end
	return policy(self,"#s2_2_zhanjiang:.:")
end

sgs.ai_skill_use_func["#s2_2_zhanjiang"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")

	if slashcount > 0 then
		local slash = self:getCard("Slash")
		local dummy_use = self:aiUseCard(slash, dummy_plan())
		if dummy_use.card then
			for _, enemy in ipairs(self.enemies) do
				if self:canAttack(enemy, self.player)
					and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
					use.card = policy(self,"#s2_2_zhanjiang:.:")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_cardneed.s2_2_zhanjiang = function(to, card, self)
	return __scarletayuhuo_value_call(card,"isKindOf","Slash")
end



sgs.ai_use_value["s2_2_zhanjiang"] = 9.2
sgs.ai_use_priority["s2_2_zhanjiang"] = 9.2


sgs.ai_skill_invoke.s2_2_huzi = function(self, data)
	local use = data:toCardUse()
	if self:hasWizard(self.enemies,true) and not self:hasWizard(self.friends,true) then
		return false
	end
	for _, to in sgs.qlist(use.to) do
		if self:isEnemy(to) and (not self:damageIsEffective(to, use.card, self.player) or self:cantDamageMore(self.player, to)) then
			return false
		end
	end
	if math.random() < 0.4 then
		return false
	end
	return true
end
sgs.ai_ajustdamage_from.s2_2_huzi = function(self, from, to, card, nature)
    if card and (__scarletayuhuo_value_call(card,"isKindOf","Slash") or __scarletayuhuo_value_call(card,"isKindOf","Duel"))
    then
        return __scarletayuhuo_value_call(from,"getMark","s2_2_huzi")
    end
end
sgs.ai_use_revises.s3_weihezhe = function(self,card,use)
	if __scarletayuhuo_value_call(card,"isKindOf","EquipCard")
	then
		local same = self:getSameEquip(card)
		if same and #self:poisonCards({card})<1
		then return false end
	end
end

sgs.ai_ajustdamage_from.s3_weihezhe = function(self, from, to, card, nature)
    if __scarletayuhuo_value_call(from,"getMark","@s3_weihezhe") + 1 == __scarletayuhuo_value_call(from,"getHp") or (card and __scarletayuhuo_value_call(card,"hasFlag","s3_weihezhe"))
    then
        return 1
    end
end
sgs.ai_skill_invoke.s3_shenqiangshou = function(self,data)
	local use = data:toCardUse()
	local good = 0
	for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
		if self:isEnemy(p) and not self:slashProhibit(use.card, p) and self:getDefenseSlash(p) <= 2
		and self:slashIsEffective(use.card, p) and self:isGoodTarget(p, self.enemies, use.card)then
			good = good + 1
			if self:isWeak(p) then
				good = good + 2
			end

		end
		if self:isFriend(p) and not self:slashProhibit(use.card, p) and self:getDefenseSlash(p) <= 2
		and self:slashIsEffective(use.card, p) and self:isGoodTarget(p, self.enemies, use.card) then
			good = good - 1
			if self:isWeak(p) then
				good = good - 2
			end
		end
	end
	return good>0
end

sgs.ai_skill_choice.s3_shenqiangshou = function(self, choices, data)
    local items = choices:split("+")
	return items[math.random(1, #items)]
end

sgs.ai_skill_discard.s3_zhuhai = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", 1, 1, false, true)
end

sgs.ai_skill_choice.s3_zhuhai = function(self, choices)
	local use = room_tag(self,"CurrentUseStruct","CardUse")
	local items = choices:split("+")
	if table.contains(items, "s3_zhuhai_discard") then
		if not use.from or __scarletayuhuo_value_call(use.from,"isDead") then return "cancel" end
		if self.role == "rebel" and known(self:getRoleEstimate(use.from),"role estimate") == "rebel" and not __scarletayuhuo_value_call(use.from,"hasSkill","jueqing")
			and __scarletayuhuo_value_call(self.player,"getHp") == 1 and self:getAllPeachNum() < 1 then
			return "cancel"
		end

		if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not __scarletayuhuo_value_call(use.from,"hasSkill","jueqing") and __scarletayuhuo_value_call(use.from,"isLord") and __scarletayuhuo_value_call(self.player,"getHp") == 1) then
			if __scarletayuhuo_value_call(use.card,"isKindOf","AOE") then
				local from = use.from
				if __scarletayuhuo_value_call(use.card,"isKindOf","SavageAssault") then
					local menghuo = self.room:findPlayerBySkillName("huoshou")
					if menghuo then from = menghuo end
				end

				local friend_null = 0
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
					if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
				end
				friend_null = friend_null + self:getCardsNum("Nullification")
				local sj_num = self:getCardsNum(__scarletayuhuo_value_call(use.card,"isKindOf","SavageAssault") and "Slash" or "Jink")

				if self:hasTrickEffective(use.card, self.player, from) then
					if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then
						if __scarletayuhuo_value_call(use.from,"hasSkill","drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then return
							"s3_zhuhai_discard" end
						if sj_num == 0 and friend_null <= 0 then
							if self:isEnemy(from) and __scarletayuhuo_value_call(from,"hasSkill","jueqing") then return "s3_zhuhai_discard" end
							if self:isFriend(from) and self.role == "loyalist" and __scarletayuhuo_value_call(from,"isLord") and __scarletayuhuo_value_call(self.player,"getHp") == 1 and not __scarletayuhuo_value_call(from,"hasSkill","jueqing") then return
								"s3_zhuhai_discard" end
							if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or __scarletayuhuo_value_call(use.from,"hasSkill","jueqing")) then
								return "s3_zhuhai_discard"
							end
						end
					end
				end
			elseif self:isEnemy(use.from) then
				if __scarletayuhuo_value_call(use.card,"isKindOf","FireAttack") and __scarletayuhuo_value_call(use.from,"getHandcardNum") > 0 then
					if self:hasTrickEffective(use.card, self.player) then
						if self:damageIsEffective(self.player, sgs.DamageStruct_Fire, use.from) then
							if (self.player:hasArmorEffect("vine") or __scarletayuhuo_value_call(self.player,"getMark","@gale") > 0) and __scarletayuhuo_value_call(use.from,"getHandcardNum") > 3
								and not (__scarletayuhuo_value_call(use.from,"hasSkill","hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
								return "s3_zhuhai_discard"
							elseif self.player:isChained() and not self:isGoodChainTarget(self.player, use.from) then
								return "s3_zhuhai_discard"
							end
						end
					end
				elseif (__scarletayuhuo_value_call(use.card,"isKindOf","Snatch") or __scarletayuhuo_value_call(use.card,"isKindOf","Dismantlement"))
					and not self.player:isKongcheng() then
					if self:hasTrickEffective(use.card, self.player) then
						return "s3_zhuhai_discard"
					end
				elseif __scarletayuhuo_value_call(use.card,"isKindOf","Duel") then
					if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player) then
						if self:hasTrickEffective(use.card, self.player) then
							if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then
								return "s3_zhuhai_discard"
							end
						end
					end
				end
			end
		end
	end

	if use.from and self:isEnemy(use.from) then
		local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		if self:slashIsEffective(slash, use.from) and not self:slashProhibit(slash, use.from) and self:isGoodTarget(use.from, self.enemies, slash) then
			return "s3_zhuhai_slash"
		end
	end



	return "cancel"
end


sgs.ai_fill_skill["s3_jianyan"] = function(self,inclusive,request)
	if self:needBear() then return end
	if not self.player:hasUsed("#s3_jianyan") then return policy(self,"#s3_jianyan:.:") end
end

sgs.ai_skill_use_func["#s3_jianyan"] = function(card, use, self)
	local abandon_card = {}
	local index = 0
	local hasPeach = (self:getCardsNum("Peach") > 0)
	local to
	local AssistTarget = self:AssistTarget()
	if AssistTarget and self:willSkipPlayPhase(AssistTarget) and __scarletayuhuo_value_call(AssistTarget,"getHandcardNum") >= __scarletayuhuo_value_call(self.player,"getHandcardNum") - 1 then AssistTarget = nil end


	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards, true)

	index = 0
	for _, card in ipairs(cards) do
		if index >= 1 then break end
		if __scarletayuhuo_value_call(card,"isKindOf","TrickCard") and not __scarletayuhuo_value_call(card,"isKindOf","Nullification") then
			table.insert(abandon_card, card:getId())
			index = index + 1
		elseif __scarletayuhuo_value_call(card,"isKindOf","EquipCard") and not (__scarletayuhuo_value_call(card,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			table.insert(abandon_card, card:getId())
			index = index + 1
		end
	end
	self.friends_noself = self:sort(self.friends_noself, "handcard")
	local x = 0
	local y = __scarletayuhuo_value_call(self.player,"getHandcardNum") - 1
	if AssistTarget and not hasManjuanEffect(AssistTarget) and __scarletayuhuo_value_call(AssistTarget,"getHandcardNum") < __scarletayuhuo_value_call(self.player,"getHandcardNum") - 1 then
		to = AssistTarget
	else
		for _, p in ipairs(self.friends_noself) do
			if y - __scarletayuhuo_value_call(p,"getHandcardNum") > x and __scarletayuhuo_value_call(p,"getHandcardNum") < y then
				to = p
				x = __scarletayuhuo_value_call(p,"getHandcardNum") - y
			end
		end
	end

	if index == 1 then
		if not to then return end
		if use.to then use.to:append(to) end
		use.card = policy(self,"#s3_jianyan:" .. table.concat(abandon_card, "+") .. ":")
		return
	end
end

sgs.ai_use_priority["#s3_jianyan"] = 0
sgs.ai_use_value["#s3_jianyan"] = 6.7

sgs.ai_card_intention["#s3_jianyan"] = -100



sgs.ai_skill_choice.s3_binglu = function(self, choices)
	local items = choices:split("+")
	local x
	if __scarletayuhuo_value_call(self.player,"getHandcardNum") > __scarletayuhuo_value_call(self.player,"getHp") then
		x = __scarletayuhuo_value_call(self.player,"getHandcardNum") - __scarletayuhuo_value_call(self.player,"getHp")
	else
		x = __scarletayuhuo_value_call(self.player,"getHp") - __scarletayuhuo_value_call(self.player,"getHp")
	end
	if x >= 2 and not self:isWeak() then
		return "s3_binglu_draw"
	end
	if self:isWeak() and not (x >= 2) and table.contains(items, "s3_binglu_discard") then
		return "s3_binglu_discard"
	end
	return "cancel"
end

sgs.ai_skill_discard.s3_binglu = function(self, discard_num, min_num, optional, include_equip)
	local x
	if __scarletayuhuo_value_call(self.player,"getHandcardNum") > __scarletayuhuo_value_call(self.player,"getHp") then
		x = __scarletayuhuo_value_call(self.player,"getHandcardNum") - __scarletayuhuo_value_call(self.player,"getHp")
	else
		x = __scarletayuhuo_value_call(self.player,"getHp") - __scarletayuhuo_value_call(self.player,"getHp")
	end
	return self:askForDiscard("dummyreason", x, x, false, false)
end

sgs.ai_skill_invoke.s3_zhijue = function(self, data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end

sgs.ai_can_damagehp.s3_zhijue = function(self,from,card,to)
	if from and __scarletayuhuo_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from)
	end
end



sgs.ai_skill_invoke.s3_lianzhan = function(self, data)
	local target = data:toPlayer()
	if target then
		local card = room_tag(self,"CurrentDamageStruct","Damage").card
		local dummy_use = self:aiUseCard(card, dummy_plan(true, 0, self.room:getOtherPlayers(target)))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
			return true
		end
	else
		return true
	end
	return false
end
sgs.ai_cardneed.s3_lianzhan = sgs.ai_cardneed.slash



sgs.ai_skill_invoke.s3_qiangyuan = function(self, data)
	return true
end

sgs.ai_skill_use["@@s3_qiangyuan"] = function(self, prompt, method)
	self:updatePlayers()
	self.friends = self:sort(self.friends, "defense")
	local targets = {}
	for _, player in ipairs(sgs.QList2Table(self.room:getAllPlayers())) do
		if self:isFriend(player) and not hasManjuanEffect(player) and not self:needKongcheng(player, true)
			and not (__scarletayuhuo_value_call(player,"hasSkill","kongcheng") and player:isKongcheng()) and #targets < 2 then
			table.insert(targets, player:objectName())
		end
	end
	if #targets > 0 then
		return "#s3_qiangyuan:.:->" .. table.concat(targets, "+")
	end
	return "."
end
sgs.ai_cardneed.s3_tianwei = sgs.ai_cardneed.slash



sgs.ai_fill_skill["s3_youlong"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, visible(self,id))
		end
	end

	local jink_card

	cards = self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if __scarletayuhuo_value_call(card,"isKindOf","Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = __scarletayuhuo_value_call(jink_card,"getSuitString")
	local number = jink_card:getNumberString()
	local card_id = __scarletayuhuo_value_call(jink_card,"getEffectiveId")
	local card_str = ("fire_slash:s3_youlong[%s:%s]=%d"):format(suit, number, card_id)
	local slash = policy(self,card_str)
	assert(slash)

	return slash
end

sgs.ai_view_as.s3_youlong = function(card, player, card_place)
 local self=known(known(player:getRoom(),"view-as room")._ai,"view-as AI context")
	local suit = __scarletayuhuo_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __scarletayuhuo_value_call(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		if __scarletayuhuo_value_call(card,"isKindOf","Jink") then
			return ("slash:s3_youlong[%s:%s]=%d"):format(suit, number, card_id)
		elseif __scarletayuhuo_value_call(card,"isKindOf","Slash") then
			return ("jink:s3_youlong[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end


sgs.ai_skill_invoke.s3_youlong = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if hasManjuanEffect(self.player) then return false end
		if self:needKongcheng(target) and __scarletayuhuo_value_call(target,"getHandcardNum") == 1 then return true end
		if self:getOverflow(target) > 2 then return true end
		return false
	else
		return not (self:needKongcheng(target) and __scarletayuhuo_value_call(target,"getHandcardNum") == 1)
	end
end

sgs.ai_choicemade_filter.skillInvoke.s3_youlong = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if __scarletayuhuo_value_call(p,"hasFlag","s3_youlongTarget") then
			target = p
			break
		end
	end
	if target then
		local intention = 60
		if promptlist[#promptlist] == "yes" then
			if not self:hasLoseHandcardEffective(target) or (self:needKongcheng(target) and __scarletayuhuo_value_call(target,"getHandcardNum") == 1) then
				intention = 0
			end
			if self:getOverflow(target) > 2 then intention = 0 end
			self:updateIntention(player, target, intention)
		else
			if self:needKongcheng(target) and __scarletayuhuo_value_call(target,"getHandcardNum") == 1 then intention = 0 end
			self:updateIntention(player, target, -intention)
		end
	end
end

sgs.ai_choicemade_filter.cardChosen.s3_youlong = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_slash_prohibit.s3_youlong = function(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if __scarletayuhuo_value_call(from,"hasSkill","tieji") or self:canLiegong(to, from) then
		return false
	end
	if self:SlashCanIgnoreJink(from, to) then return false end
	if __scarletayuhuo_value_call(to,"hasSkill","s3_youlong") and __scarletayuhuo_value_call(to,"getHandcardNum") >= 3 and __scarletayuhuo_value_call(from,"getHandcardNum") > 1 then return true end
	return false
end



sgs.ai_skill_discard.s3_youlong = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", 1, 1, false, true)
end

sgs.ai_card_priority.s3_youlong = function(self,card)
	if table.contains(card:getSkillNames(), "s3_youlong")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end


sgs.ai_skill_playerchosen["s3_kangdao"] = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		for _, enemy in ipairs(self.enemies) do
			if friend:canSlash(enemy) and not self:slashProhibit(nil, enemy) and self:getDefenseSlash(enemy) <= 2 and self:isGoodTarget(enemy, self.enemies, nil)
				and enemy:objectName() ~= self.player:objectName() and getCardsNum("Slash", friend, self.player) >= 1 then
				return friend
			end
		end
	end
	return nil
end

sgs.ai_skill_playerchosen["s3_kangdao_target"] = function(self, targets)
	local target = room_tag(self,"s3_kangdao","Player")
	for _, enemy in ipairs(self.enemies) do
		if target:canSlash(enemy) and not self:slashProhibit(nil, enemy) and self:getDefenseSlash(enemy) <= 2 and
			self:isGoodTarget(enemy, self.enemies, nil)  and enemy:objectName() ~= self.player:objectName() then
			return enemy
		end
	end
	return nil
end



sgs.ai_skill_use["@@s3_qiane"] = function(self, prompt, method)
	self:updatePlayers()
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	usable_cards = self:sortByKeepValue(usable_cards)
	local give_card = {}
	if self:willSkipPlayPhase() then
		for _, c in ipairs(usable_cards) do
			if not __scarletayuhuo_value_call(c,"isKindOf","Peach") and (#give_card < self:getOverflow()) then
				table.insert(give_card, __scarletayuhuo_value_call(c,"getEffectiveId"))
			end
		end
		if #give_card > 0 then
			return "#s3_qiane:" .. table.concat(give_card, "+") .. ":"
		end
	end
	if self:getTurnUse() then
		for _, c in ipairs(usable_cards) do
			if not table.contains(self:getPriorTurnUseCards(),c) then
				table.insert(give_card, __scarletayuhuo_value_call(c,"getEffectiveId"))
			end
		end
	end
	if #give_card > 0 then
		return "#s3_qiane:" .. table.concat(give_card, "+") .. ":"
	end
	return "."
end



sgs.ai_fill_skill["s3_fenzhi"] = function(self,inclusive,request)
	if self.player:hasUsed("#s3_fenzhi") then return end
	if #self.enemies < 1 then return end
	if __scarletayuhuo_value_call(self.player,"getHandcardNum") < 1 then return end
	return policy(self,"#s3_fenzhi:.:")
end

sgs.ai_skill_use_func["#s3_fenzhi"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local to_discard = {}
	cards = self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if #to_discard < 2 and not __scarletayuhuo_value_call(card,"isKindOf","Peach") then
			table.insert(to_discard, __scarletayuhuo_value_call(card,"getEffectiveId"))
		end
	end
	if #to_discard == 2 then
		self.enemies = self:sort(self.enemies)
		local target
		for _, friend in ipairs(self.friends_noself) do
			if friend:hasSkills(sgs.cardneed_skill) and not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				target = friend
				break
			end
		end
		if target == nil then
			for _, friend in ipairs(self.friends_noself) do
				if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
					target = friend
					break
				end
			end
		end
		if target then
			local card_str = string.format("#s3_fenzhi:%s:", table.concat(to_discard, "+"))
			use.card = policy(self,card_str)
			if use.to then use.to:append(target) end
			return
		end
	end
end


sgs.ai_skill_choice.s3_fenzhi = function(self, choices)
	local items = choices:split("+")
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __scarletayuhuo_value_call(p,"hasFlag","s3_fenzhi") then
			if self:isFriend(p) then
				return "s3_fenzhidraw"
			else
				if table.contains(items, "s3_fenzhiget") then
					return "s3_fenzhiget"
				end
			end
		end
	end
	return "s3_fenzhidraw"
end


sgs.ai_choicemade_filter.skillChoice["s3_fenzhi"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __scarletayuhuo_value_call(p,"hasFlag","s3_fenzhi") then
			if choice == "s3_fenzhidraw" then
				self:updateIntention(player, p, -80)
			else
				self:updateIntention(player, p, 80)
			end
		end
	end
end

sgs.ai_hasTuntianEffect_skill.s3_guyang = function(to, need_zaoxian)
	return __scarletayuhuo_value_call(to,"getPhase") == sgs.Player_NotActive
end


sgs.ai_fill_skill["s3_fudao"] = function(self,inclusive,request)
	if self.player:isKongcheng() then return nil end
	if self.player:hasUsed("#s3_fudao") then return nil end
	return policy(self,"#s3_fudao:.:")
end

sgs.ai_skill_use_func["#s3_fudao"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByUseValue(cards, true)
	if #cards == 1 and __scarletayuhuo_value_call(cards[1],"getSuit") == sgs.Card_Diamond then return end
	if #cards <= 4 and (self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then return end
	self.enemies = self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local suits = {}
	local suits_num = 0
	for _, c in ipairs(cards) do
		if not suits[__scarletayuhuo_value_call(c,"getSuitString")] then
			suits[__scarletayuhuo_value_call(c,"getSuitString")] = true
			suits_num = suits_num + 1
		end
	end


	for _, enemy in ipairs(self.enemies) do
		local visible = 0
		for _, card in ipairs(cards) do
			local flag = string.format("%s_%s_%s", "visible", enemy:objectName(), self.player:objectName())
			if __scarletayuhuo_value_call(card,"hasFlag","visible") or __scarletayuhuo_value_call(card,"hasFlag",flag) then visible = visible + 1 end
		end
		if visible > 0 and (#cards <= 2 or suits_num <= 2) then continue end
		if self:canAttack(enemy) then
			use.card = policy(self,"#s3_fudao:.:")
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_card_intention["s3_fudao"] = 70
sgs.ai_use_priority["s3_fudao"] = sgs.ai_use_priority.Peach

function sgs.ai_skill_suit.s3_fudao(self)
	local map = { 0, 0, 1, 2, 2, 3, 3, 3 }
	local suit = map[math.random(1, 8)]
	local tg = self.room:getCurrent()
	local suits = {}
	local maxnum, maxsuit = 0
	for _, c in sgs.qlist(complete_hand(self,tg)) do
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), tg:objectName())
		if __scarletayuhuo_value_call(c,"hasFlag",flag) or __scarletayuhuo_value_call(c,"hasFlag","visible") then
			if not suits[__scarletayuhuo_value_call(c,"getSuitString")] then suits[__scarletayuhuo_value_call(c,"getSuitString")] = 1 else suits[__scarletayuhuo_value_call(c,"getSuitString")] = suits
				[__scarletayuhuo_value_call(c,"getSuitString")] + 1 end
			if suits[__scarletayuhuo_value_call(c,"getSuitString")] > maxnum then
				maxnum = suits[__scarletayuhuo_value_call(c,"getSuitString")]
				maxsuit = __scarletayuhuo_value_call(c,"getSuit")
			end
		end
	end
	if __scarletayuhuo_value_call(self.player,"hasSkill","hongyan") and (maxsuit == sgs.Card_Spade or suit == sgs.Card_Spade) then
		return sgs.Card_Heart
	end
	if maxsuit then
		if __scarletayuhuo_value_call(self.player,"hasSkill","hongyan") and maxsuit == sgs.Card_Spade then return sgs.Card_Heart end
		return maxsuit
	else
		if __scarletayuhuo_value_call(self.player,"hasSkill","hongyan") and suit == sgs.Card_Spade then return sgs.Card_Heart end
		return suit
	end
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|s3_guizhou"


sgs.ai_skill_playerchosen.s3_guizhou = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if __scarletayuhuo_value_call(player,"isLord") then lord = player end
		if self:isEnemy(player) and (not target or __scarletayuhuo_value_call(target,"getHp") < __scarletayuhuo_value_call(player,"getHp")) then
			target = player
		end
	end
	if self.role == "rebel" and lord then return lord end
	if target then return target end
	targetlist = self:sort(targetlist, "hp")
	if viewer_role(self,self.player) == "loyalist" and __scarletayuhuo_value_call(targetlist[1],"isLord") then return targetlist[2] end
	return targetlist[1]
end

sgs.ai_cardneed.s3_luofeng = sgs.ai_cardneed.slash
sgs.ai_can_damagehp.s3_sizhan = function(self,from,card,to)
	if from and __scarletayuhuo_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) then
		return self:isEnemy(from) and self:isWeak(from) and sgs.ai_skill_cardask["@s3_sizhan"](self, player_data(from), "" , from) ~= "."
	end
end


sgs.ai_skill_cardask["@s3_sizhan"] = function(self, data, pattern, target)
	local target = data:toPlayer()
	if self:isFriend(target, self.player) then return "." end

	local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	if target and self:isEnemy(target) and self:slashIsEffective(slash, target) and not self:slashProhibit(slash, target) and self:isGoodTarget(target, self.enemies, slash)  then
		if self:needToThrowArmor() then
			return "$" .. self.player:getArmor():getEffectiveId()
		end
		local cards = sgs.QList2Table(self.player:getCards("he"))
		cards = self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if not __scarletayuhuo_value_call(card,"isKindOf","Peach") then
				return "$" .. __scarletayuhuo_value_call(card,"getEffectiveId")
			end
		end
		if self.player:canDiscard(self.player, "he") then
			return "$" .. __scarletayuhuo_value_call(cards[1],"getEffectiveId")
		end
	end
	return "."
end

sgs.ai_need_damaged.s3_zhonglie = function(self, attacker, player)
	if __scarletayuhuo_value_call(player,"hasSkill","s3_zhonglie") and __scarletayuhuo_value_call(player,"getMark","s3_zhonglie") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < __scarletayuhuo_value_call(player,"getHp")
		and (__scarletayuhuo_value_call(player,"getHp") > 3 or __scarletayuhuo_value_call(player,"getHp") == 3 and (__scarletayuhuo_value_call(player,"faceUp") or __scarletayuhuo_value_call(player,"hasSkill","guixin") or __scarletayuhuo_value_call(player,"hasSkill","toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end

sgs.ai_skill_discard["s3_wumou"] = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", 1, 1, false, false)
end
sgs.ai_use_revises.s3_wumou = function(self,card,use)
	if card:isNDTrick() and __scarletayuhuo_value_call(self.player,"getHandcardNum") <= 3
	then
        if not (__scarletayuhuo_value_call(card,"isKindOf","AOE") or __scarletayuhuo_value_call(card,"isKindOf","IronChain") or __scarletayuhuo_value_call(card,"isKindOf","Drowning"))
        and not (__scarletayuhuo_value_call(card,"isKindOf","Duel") and __scarletayuhuo_value_call(self.player,"getMark","&wrath")>0)
		then return false end
	end
end

sgs.ai_skill_invoke.s3_xiaoyong = function(self, data)
	local target = data:toPlayer()
	return self:doDisCard(target)
end

sgs.ai_choicemade_filter.cardChosen.s3_xiaoyong = sgs.ai_choicemade_filter.cardChosen.snatch



sgs.ai_cardneed.s3_xiongyi = sgs.ai_cardneed.slash


sgs.ai_skill_cardask["s3_xiongyi-invoke"] = function(self, data, pattern, target)
	local use = data:toCardUse()
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __scarletayuhuo_value_call(p,"hasFlag","s3_xiongyi_ing") then
			target = p
			break
		end
	end
	for _, q in sgs.qlist(self.room:getOtherPlayers(target)) do
		if __scarletayuhuo_value_call(target,"inMyAttackRange",q) and not use.to:contains(q) then
			if q and self:isEnemy(q) and self:slashIsEffective(use.card, q) and not self:slashProhibit(use.card, q) and self:isGoodTarget(q, self.enemies, use.card) then
				if self:needToThrowArmor() then
					return "$" .. self.player:getArmor():getEffectiveId()
				end
				local cards = sgs.QList2Table(self.player:getCards("he"))
				cards = self:sortByKeepValue(cards)
				for _, card in ipairs(cards) do
					if not __scarletayuhuo_value_call(card,"isKindOf","Peach") then
						return "$" .. __scarletayuhuo_value_call(card,"getEffectiveId")
					end
				end
				return "$" .. __scarletayuhuo_value_call(cards[1],"getEffectiveId")
			end
		end
	end
	return "."
end


sgs.ai_skill_playerchosen.s3_xiongyi = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end




sgs.ai_fill_skill["s3_xiandao"] = function(self,inclusive,request)
	if self.player:canDiscard(self.player, "he") then
		return policy(self,"#s3_xiandao:.:")
	end
end

sgs.ai_skill_use_func["#s3_xiandao"] = function(card, use, self)
	local weapon = self.player:getWeapon()
	if weapon then
		local hand_weapon, cards
		cards = self.player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if __scarletayuhuo_value_call(card,"isKindOf","Weapon") then
				hand_weapon = card
				break
			end
		end
		self.enemies = self:sort(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and hand_weapon and not self:hasSkills(sgs.lose_equip_skill, enemy) then
				use.card = policy(self,"#s3_xiandao:" .. hand_weapon:getId() .. ":")
				if use.to then
					use.to:append(enemy)
				end
				break
			end
		end
	end
end

sgs.ai_use_value["#s3_xiandao"] = 2.5
sgs.ai_card_intention["#s3_xiandao"] = 80
sgs.dynamic_value.damage_card["#s3_xiandao"] = true
sgs.ai_cardneed.s3_xiandao = sgs.ai_cardneed.weapon

sgs.s3_xiandao_keep_value = {
	Weapon = 5
}

sgs.ai_skill_invoke.s3_yt_fulin = function(self, data)
	local use = data:toCardUse()
	local card = use.card
	local target = use.to:first()
	if self:isEnemy(target) then
		if ((__scarletayuhuo_value_call(card,"isKindOf","TrickCard") and self:hasTrickEffective(card, target, self.player)) or (__scarletayuhuo_value_call(card,"isKindOf","Slash") and self:slashIsEffective(card, target, self.player))) then
			return true
		end
	end
	if self:isFriend(target) then
		return true
	end
	return not self:isEnemy(target)
end


sgs.ai_skill_choice.s3_yt_fulin = function(self, choices)
	local items = choices:split("+")
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __scarletayuhuo_value_call(p,"hasFlag","s3_yt_fulin") then
			if self:isFriend(p) then
				return "s3_yt_fulin_draw"
			else
				if table.contains(items, "s3_yt_fulin_use") then
					return "s3_yt_fulin_use"
				end
			end
		end
	end
	return "s3_yt_fulin_draw"
end


sgs.ai_choicemade_filter.skillChoice["s3_yt_fulin"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __scarletayuhuo_value_call(p,"hasFlag","s3_yt_fulin") then
			if choice == "s3_yt_fulin_draw" then
				self:updateIntention(player, p, -80)
			else
				self:updateIntention(player, p, 80)
			end
		end
	end
end



sgs.ai_fill_skill["s3_yt_baier"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, visible(self,id))
		end
	end

	local jink_card

	cards = self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if not __scarletayuhuo_value_call(card,"isKindOf","Peach") then
			jink_card = card
			break
		end
	end
	if math.ceil(__scarletayuhuo_value_call(self.player,"getHp") / 2) * 2 == __scarletayuhuo_value_call(self.player,"getHp") then return nil end
	if not jink_card then return nil end
	local suit = __scarletayuhuo_value_call(jink_card,"getSuitString")
	local number = jink_card:getNumberString()
	local card_id = __scarletayuhuo_value_call(jink_card,"getEffectiveId")
	local card_str = ("slash:s3_yt_baier[%s:%s]=%d"):format(suit, number, card_id)
	local slash = policy(self,card_str)
	assert(slash)

	return slash
end

sgs.ai_view_as.s3_yt_baier = function(card, player, card_place)
 local self=known(known(player:getRoom(),"view-as room")._ai,"view-as AI context")
	local suit = __scarletayuhuo_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __scarletayuhuo_value_call(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		if math.ceil(__scarletayuhuo_value_call(player,"getHp") / 2) * 2 == __scarletayuhuo_value_call(player,"getHp") then
			return ("slash:s3_yt_baier[%s:%s]=%d"):format(suit, number, card_id)
		elseif math.ceil(__scarletayuhuo_value_call(player,"getHp") / 2) * 2 ~= __scarletayuhuo_value_call(player,"getHp") then
			return ("jink:s3_yt_baier[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.s3_yt_baier_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.7,
	Slash = 5.6,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}


sgs.ai_skill_invoke.s3_yt_kuangjun = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) and __scarletayuhuo_value_call(target,"getHandcardNum") < 4 then
		return false
	end
	if self:isEnemy(target) and __scarletayuhuo_value_call(target,"getHandcardNum") >= 4 then
		return false
	end
	return true
end
sgs.ai_skill_cardask["@s3_yt_kuangjun"] = function(self, data, pattern, target)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if matches_source_pattern(self,pattern,h)
		then return __scarletayuhuo_value_call(h,"getEffectiveId") end
		if __scarletayuhuo_value_call(h,"isKindOf",pattern)
		then return __scarletayuhuo_value_call(h,"getEffectiveId") end
	end
	return self:getCardId(pattern)
end

sgs.ai_skill_invoke.s3_yt_huzheng = function(self, data)
	local target = data:toPlayer()
	for _, enemy in ipairs(self.enemies) do
		if target:canSlash(enemy) and not self:slashProhibit(nil, enemy) and self:getDefenseSlash(enemy) <= 2 and self:isGoodTarget(enemy, self.enemies, nil)
			and enemy:objectName() ~= self.player:objectName() then
			return self:isFriend(target)
		end
	end
	return false
end



sgs.ai_skill_playerchosen.s3_yt_huzheng = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end


sgs.ai_skill_invoke.s3_yt_huangyi = function(self, data)
	local target = self.room:getCurrent()
	if self:isFriend(target) then
		return not __scarletayuhuo_value_call(self.player,"faceUp")
	end
	if self:isEnemy(target) then
		return not (__scarletayuhuo_value_call(self.player,"faceUp")) or (self:isWeak(target))
	end
	return false
end
sgs.ai_skill_choice["s3_yt_huangyi_type"] = function(self, choices, data)
	self:updatePlayers()
	self.friends_noself = self:sort(self.friends_noself, "handcard")
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		return "TrickCard"
	end
	if current and self:isEnemy(current) then
		local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		if self:slashIsEffective(slash, current) and self:isGoodTarget(current, self.enemies, slash)  then
			set_observation(self,"ai_s3_yt_huangyi_card_name",slash:objectName())
			return "Slash"
		else
			return "TrickCard"
		end
	end

	return "cancel"
end


sgs.ai_skill_choice["s3_yt_huangyi"] = function(self, choices, data)
	self:updatePlayers()
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		return "TrickCard"
	end
	if current and self:isEnemy(current) then
		local duel = clone(self,"duel", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		if self:hasTrickEffective(duel, current, self.player) then
			set_observation(self,"ai_s3_yt_huangyi_card_name",duel:objectName())
			return "duel"
		end
	end
	if current and self:isFriend(current) then
		local duel = clone(self,"god_salvation", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		set_observation(self,"ai_s3_yt_huangyi_card_name",duel:objectName())
		return "god_salvation"
	end

	return "cancel"
end


sgs.ai_skill_use["@@s3_yt_huangyi"] = function(self, prompt, method)
	local ai_taoluan_card_name = room_tag(self,"ai_s3_yt_huangyi_card_name","String")
	set_observation(self,"ai_s3_yt_huangyi_card_name",false)

	local use_card = clone(self,ai_taoluan_card_name, sgs.Card_NoSuit, -1)
	use_card = mutate(self,use_card,"skill","s3_yt_huangyi")

	local current = self.room:getCurrent()
	local dummy_use = self:aiUseCard(use_card, dummy_plan())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			if p:objectName() == current:objectName() then
				return use_card:getLegacyStringKey() .. "->" .. current:objectName()
			end
		end
	end
	return "."
end




sgs.ai_skill_playerchosen.s3_yt_zhinan = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

sgs.ai_skill_discard["s3_yt_fuding"] = function(self, discard_num, min_num, optional, include_equip)
	local x = 0
	local y = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __scarletayuhuo_value_call(self.player,"inMyAttackRange",p) then
			if self:isEnemy(p) then
				y = y + 1
			end
			x = x + 1
		end
	end
	if (x >= __scarletayuhuo_value_call(self.player,"getHandcardNum") - 2) or (y > 2) then
		return self:askForDiscard("dummyreason", 1, 1, false, false)
	end
end
sgs.ai_skill_cardask["s3_yt_fuding_push"] = function(self, data, pattern, target)
	if target and not self:isFriend(target) then return "." end
	if target and self:isFriend(target) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		for _, card in ipairs(cards) do
			if __scarletayuhuo_value_call(card,"isKindOf","Slash") then
				return "$" .. __scarletayuhuo_value_call(card,"getEffectiveId")
			end
		end
		cards = self:sortByKeepValue(cards)
	end
	return "."
end



sgs.ai_skill_invoke.s3_yt_feijun = function(self, data)
	if __scarletayuhuo_value_call(self.player,"getHp") <= 2 then
		return true
	else
		local handcards = self.player:getHandcards()
		local basic = {}
		local trick = {}
		local equip = {}
		for _, c in sgs.qlist(handcards) do
			if __scarletayuhuo_value_call(c,"isKindOf","BasicCard") and not __scarletayuhuo_value_call(c,"isKindOf","Peach") then
				if self.player:canDiscard(self.player, __scarletayuhuo_value_call(c,"getEffectiveId")) then
					table.insert(basic, c)
				end
			end
			if __scarletayuhuo_value_call(c,"isKindOf","TrickCard") then
				if self.player:canDiscard(self.player, __scarletayuhuo_value_call(c,"getEffectiveId")) then
					table.insert(trick, c)
				end
			end
			if __scarletayuhuo_value_call(c,"isKindOf","EquipCard") then
				if self.player:canDiscard(self.player, __scarletayuhuo_value_call(c,"getEffectiveId")) then
					table.insert(equip, c)
				end
			end
		end
		if #basic == 1 or #trick == 1 or equip == 1 then
			for _, enemy in ipairs(self.enemies) do
				local def = self:getDefenseSlash(enemy)
				local slash = clone(self,"slash")
				slash:deleteLater()
				local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

				if not self.player:canSlash(enemy, slash) then
				elseif self:slashProhibit(nil, enemy) then
				elseif def < 6 and eff then
					return true
				end
			end
		end
	end
	return false
end

sgs.ai_skill_choice["s3_yt_feijun"] = function(self, choices, data)
	local handcards = self.player:getHandcards()
	local basic = {}
	local trick = {}
	local equip = {}
	for _, c in sgs.qlist(handcards) do
		if __scarletayuhuo_value_call(c,"isKindOf","BasicCard") and not __scarletayuhuo_value_call(c,"isKindOf","Peach") then
			if self.player:canDiscard(self.player, __scarletayuhuo_value_call(c,"getEffectiveId")) then
				table.insert(basic, c)
			end
		end
		if __scarletayuhuo_value_call(c,"isKindOf","TrickCard") then
			if self.player:canDiscard(self.player, __scarletayuhuo_value_call(c,"getEffectiveId")) then
				table.insert(trick, c)
			end
		end
		if __scarletayuhuo_value_call(c,"isKindOf","EquipCard") then
			if self.player:canDiscard(self.player, __scarletayuhuo_value_call(c,"getEffectiveId")) then
				table.insert(equip, c)
			end
		end
	end
	if #basic == 1 then
		return "BasicCard"
	elseif #trick <= 2 then
		return "TrickCard"
	elseif #equip <= 2 then
		return "EquipCard"
	end
end

sgs.ai_skill_playerchosen.s3_yt_feijun = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end
sgs.ai_cardneed.s3_yt_zhengtao = sgs.ai_cardneed.slash
sgs.ai_card_priority.s3_yt_zhengtao = function(self,card,v)
	local x = math.max(1, __scarletayuhuo_value_call(self.player,"getLostHp"))
	if __scarletayuhuo_value_call(self.player,"getMark","s3_yt_kangrui") > 0 then
		x = 1
	end
	if __scarletayuhuo_value_call(self.player,"getMark","s3_yt_zhengtao")+1==x and __scarletayuhuo_value_call(card,"isKindOf","Slash")
	then return 10 end
end

sgs.ai_skill_playerchosen.s3_yt_zhengtao = function(self, targets)
	return self.player
end


sgs.ai_skill_invoke.s3_yt_mangyong = function(self, data)
	local card = clone(self,"savage_assault", sgs.Card_NoSuit, 0)
	card:deleteLater()
	if self:getAoeValue(card) > 0 then
		return true
	end
	return false
end

sgs.ai_fill_skill["s3_yt_tongnan"] = function(self,inclusive,request)
	if self.player:hasUsed("#s3_yt_tongnan") then return nil end
	return policy(self,"#s3_yt_tongnan:.:")
end

sgs.ai_skill_use_func["#s3_yt_tongnan"] = function(card, use, self)
	use.card = card

	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() > 0 then
			if not self:hasSkills(sgs.lose_equip_skill, enemy) then
				for _, ecard in sgs.qlist(enemy:getCards("e")) do
					if __scarletayuhuo_value_call(ecard,"isKindOf","Armor") or __scarletayuhuo_value_call(ecard,"isKindOf","DefensiveHorse") or __scarletayuhuo_value_call(ecard,"isKindOf","Weapon") then
						if use.to then
							use.to:append(enemy)
						end
						return
					end
				end
			end
		end
	end
	if use.to then
		use.to:append(self.player)
	end
	return
end
sgs.ai_use_priority["s3_yt_tongnan"] = sgs.ai_use_priority.Peach

sgs.ai_skill_playerchosen["s3_yt_junlie"] = function(self, targets)
	local use = room_tag(self,"CurrentUseStruct","CardUse")
	if use.card then
		if __scarletayuhuo_value_call(use.card,"isKindOf","Slash") then
			if self:slashIsEffective(use.card, self.player, use.from) then
				local handcards = self.player:getHandcards()
				for _, c in sgs.qlist(handcards) do
					if __scarletayuhuo_value_call(c,"isKindOf","Jink") then
						return nil
					end
				end
				if __scarletayuhuo_value_call(self.player,"getHandcardNum") < __scarletayuhuo_value_call(self.player,"getHp") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:isKongcheng() then
							return enemy
						end
					end
				end
			end
		elseif __scarletayuhuo_value_call(use.card,"isKindOf","FireAttack") or __scarletayuhuo_value_call(use.card,"isKindOf","Dismantlement") or __scarletayuhuo_value_call(use.card,"isKindOf","Collateral") or __scarletayuhuo_value_call(use.card,"isKindOf","Snatch") or __scarletayuhuo_value_call(use.card,"isKindOf","AmazingGrace") then
			if __scarletayuhuo_value_call(self.player,"getHandcardNum") < __scarletayuhuo_value_call(self.player,"getHp") then
				for _, enemy in ipairs(self.enemies) do
					if not enemy:isKongcheng() then
						return enemy
					end
				end
			end
		elseif __scarletayuhuo_value_call(use.card,"isKindOf","Duel") or __scarletayuhuo_value_call(use.card,"isKindOf","SavageAssault") then
			if self:slashIsEffective(use.card, self.player, use.from) then
				local handcards = self.player:getHandcards()
				for _, c in sgs.qlist(handcards) do
					if __scarletayuhuo_value_call(c,"isKindOf","Slash") then
						return nil
					end
				end
				if __scarletayuhuo_value_call(self.player,"getHandcardNum") < __scarletayuhuo_value_call(self.player,"getHp") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:isKongcheng() then
							return enemy
						end
					end
				end
			end
		elseif __scarletayuhuo_value_call(use.card,"isKindOf","ArcheryAttack") then
			if self:slashIsEffective(use.card, self.player, use.from) then
				local handcards = self.player:getHandcards()
				for _, c in sgs.qlist(handcards) do
					if __scarletayuhuo_value_call(c,"isKindOf","Jink") then
						return nil
					end
				end
				if __scarletayuhuo_value_call(self.player,"getHandcardNum") < __scarletayuhuo_value_call(self.player,"getHp") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:isKongcheng() then
							return enemy
						end
					end
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_invoke.s3_yt_gangyong = function(self, data)
	local damage = data:toDamage()
	if damage.from and self:isEnemy(damage.from) then
		return true
	end
	return false
end



sgs.ai_fill_skill["s3_yt_qibing"] = function(self,inclusive,request)
	if __scarletayuhuo_value_call(self.player,"getMark","@s3_yt_qibing") > 0 then
		return policy(self,"#s3_yt_qibing:.:")
	end
end

sgs.ai_skill_use_func["#s3_yt_qibing"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then
			if __scarletayuhuo_value_call(self.player,"getHp") > __scarletayuhuo_value_call(enemy,"getHp") then
				use.card = policy(self,"#s3_yt_qibing:.:")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
end

sgs.ai_use_value["#s3_yt_qibing"] = 2.5
sgs.ai_card_intention["#s3_yt_qibing"] = 80
sgs.dynamic_value.damage_card["#s3_yt_qibing"] = true



sgs.ai_skill_discard["s3_yt_panjiang"] = function(self, discard_num, min_num, optional, include_equip)
	local target = self.room:getCurrent()
	if target:objectName() == self.player:objectName() then
		return self:askForDiscard("dummyreason", 1, 1, false, false)
	end
	if self:isFriend(target) and not self:isWeak() then
		return self:askForDiscard("dummyreason", 1, 1, false, false)
	end

	return {}
end

sgs.ai_skill_use["@@s3_yt_ruiqiDiscard"] = function(self, prompt, method)
	local data = effect_data(self,"s3_yt_ruiqi")
	if not data then return "." end
	local effect = data:toCardEffect()
	if not effect then return "." end
	local can_invoke = false
	if __scarletayuhuo_value_call(effect.card,"isKindOf","TrickCard") then
		if __scarletayuhuo_value_call(effect.card,"isDamageCard") then
			if self:needToLoseHp(self.player,effect.from,effect.card)
			or self:canDamageHp(effect.from,effect.card,self.player) then
			else
				local adn = self:ajustDamage(effect.from,self.player,1,effect.card)
				if adn<-1 or adn>1 or adn>=__scarletayuhuo_value_call(self.player,"getHp") then
					can_invoke = true
				end
			end
		end
	elseif __scarletayuhuo_value_call(effect.card,"isKindOf","Slash") then
		if sgs.ai_skill_cardask["slash-jink"](self,data,"jink",data:toCardEffect().from) or __scarletayuhuo_value_call(self.player,"getMark","ai_NoJinkCard"..__scarletayuhuo_value_call(effect.card,"getEffectiveId").."_targeted-Clear") > 0 then
			can_invoke = true
		end
	end
	if not can_invoke then return "." end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local trick = {}
	local nontrick = {}
	local discard = {}
	for _, card in ipairs(cards) do
		if __scarletayuhuo_value_call(card,"isKindOf","TrickCard") then
			table.insert(trick, card)
		elseif __scarletayuhuo_value_call(card,"isKindOf","BasicCard") then
			table.insert(nontrick, card)
		end
	end
	if #cards <= 2 then return "." end
	if #trick == 0 then
		for _, card in ipairs(nontrick) do
			table.insert(discard, __scarletayuhuo_value_call(card,"getEffectiveId"))
			if #discard == 2 or #discard == #nontrick then
				break
			end
		end
	end
	if #nontrick == 0 and #trick >= 1 then
		table.insert(discard, __scarletayuhuo_value_call(trick[1],"getEffectiveId"))
	end
	if #discard > 0 then
		return "#s3_yt_ruiqiDummyCard:".. table.concat(discard, "+") ..":"
	end
	return "."
end


sgs.ai_skill_invoke.s3_yt_ruiqi = function(self, data)
	local use = data:toCardUse()
	for _, p in sgs.qlist(use.to) do
		if p and self:isEnemy(p) then
			return true
		end
	end
	return false
end





sgs.ai_skill_cardask["@s3_yt_congzheng"] = function(self, data, pattern, target)
	local target = self.room:getCurrent()
	if self:needBear() then return "." end
	if target and self:isEnemy(target) and self:objectiveLevel(target) > 3 and not self:cantbeHurt(target) and self:damageIsEffective(target) and not self:willSkipPlayPhase(target) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		cards = self:sortByKeepValue(cards)
		if self:needToThrowArmor() and not self.player:isCardLimited(self.player:getArmor(), sgs.Card_MethodDiscard) then
			return "$" .. self.player:getArmor():getEffectiveId()
		end


		for _, card in ipairs(cards) do
			return "$" .. __scarletayuhuo_value_call(card,"getEffectiveId")
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@s3_yt_congzheng"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		self:updateIntention(player, current, 80)
	end
end


sgs.ai_card_priority.s3_yt_yinpan = function(self,card)
	if self.player:getPile("&s3_yinpan"):contains(__scarletayuhuo_value_call(card,"getEffectiveId"))
	then
		if self.useValue
		then return 2 end
		return 0.08
	end
end




sgs.ai_choicemade_filter.cardChosen.s3_yt_qujin_caoxiu = sgs.ai_choicemade_filter.cardChosen.dismantlement
sgs.ai_skill_cardchosen["s3_yt_qujin"] = function(self, who, flags)
	local cards = sgs.QList2Table(complete_hand(self,who))
	cards = self:sortByUseValue(cards, false)
	for _, card in ipairs(cards) do
		if __scarletayuhuo_value_call(card,"isKindOf","Slash") then
			return card
		end
	end
	for _, card in ipairs(cards) do
		if __scarletayuhuo_value_call(card,"isKindOf","TrickCard") and card:isBlack() then
			return card
		end
	end

	return cards[1]
end

sgs.ai_skill_choice.s3_yt_qujin = function(self, choices, data)
	local target = data:toPlayer()
	local x = target:getPile("qujin"):length()
	if self:isFriend(target) then
		if target:getCardCount(true) < x and x <= 2 then
			return "s3_yt_qujin_discard"
		end
	else
		if not self:isWeak(target) and target:getCardCount(true) > x and x > 2 then
			return "s3_yt_qujin_discard"
		end
	end
	return "s3_yt_qujin_damage"
end



sgs.ai_fill_skill["s3_yt_qujin"] = function(self,inclusive,request)
	if __scarletayuhuo_value_call(self.player,"hasFlag","s3_yt_qujin_dis") then return nil end
	return policy(self,"#s3_yt_qujin:.:")
end

sgs.ai_skill_use_func["#s3_yt_qujin"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "defense")
	local target
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he") then
			target = enemy
			break
		end
	end
	if target and not target:isNude() then
		use.card = policy(self,"#s3_yt_qujin:.:")
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value["s3_yt_qujin"] = sgs.ai_use_value.Slash + 0.1
sgs.ai_use_priority["s3_yt_qujin"] = sgs.ai_use_priority.Slash + 0.1









sgs.ai_skill_invoke.s3_yt_gangjian = function(self, data)
	if self:willSkipPlayPhase() then return false end
	if self.player:isKongcheng() then return true end
	if self:isWeak() and self:getCardsNum("Jink") + self:getCardsNum("Analeptic") + self:getCardsNum("Peach") + self:getCardsNum("Nullification") == 0 then
		return true
	end
	if __scarletayuhuo_value_call(self.player,"getHp") == 2 then return true end
	if self:getTurnUse() then
		for i,c in sgs.list(self:getPriorTurnUseCards())do
			if __scarletayuhuo_value_call(c,"isKindOf","Duel") then return true end
			if __scarletayuhuo_value_call(c,"isKindOf","FireAttack") then return true end
			if __scarletayuhuo_value_call(c,"isKindOf","AOE") then return true end
		end
	end

	return false
end
sgs.ai_card_priority.s3_yt_youxue = function(self,card,v)
	if card:isBlack() and __scarletayuhuo_value_call(card,"getNumber") <= __scarletayuhuo_value_call(self.player,"getMark","s3_yt_youxueNumber-".. __scarletayuhuo_value_call(self.player,"getPhase") .."Clear")
	then return 10 end
end

sgs.ai_skill_invoke.s3_yt_gaojiong = function(self, data)
	local good = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if __scarletayuhuo_value_call(self.player,"distanceTo",p) == 1 and self:damageIsEffective(p, nil, self.player) then
			if self:isFriend(p) then
				good = good - 1
			else
				good = good + 1
			end
		end
	end
	if good > 0 then
		if __scarletayuhuo_value_call(self.player,"getHp") <= 0 or not __scarletayuhuo_value_call(self.player,"faceUp") then
			return true
		end
		return not self:isWeak()
	end
	return false
end

sgs.ai_skill_discard.s3_touying = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	if (self.player:getPile("s3_jian"):length() >= self.room:getAlivePlayers():length() - 1) or self:needBear() then
		return {}
	end
	table.insert(to_discard, __scarletayuhuo_value_call(cards[1],"getEffectiveId"))

	return to_discard
end

sgs.ai_skill_use["@@s3_huanxiangbenghuai"] = function(self, prompt)
	local damage = room_tag(self,"CurrentDamageStruct","Damage")
	local target = damage.to
	if not self:isEnemy(target) then return "." end
	if target:hasArmorEffect("silver_lion") then return "." end

	local discard_cards = {}
	if self.player:getPile("s3_jian"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("s3_jian")) do
			table.insert(discard_cards, visible(self,id))
		end
		return "#s3_huanxiangbenghuai:" .. __scarletayuhuo_value_call(discard_cards[1],"getEffectiveId") .. ":"
	end
	return "."
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|s3_wuxianjianzhi"


sgs.ai_ajustdamage_from.s3_huanxiangbenghuai = function(self, from, to, card, nature)
    if not from:getPile("s3_jian"):isEmpty() and not self:beFriend(to, from)
    then
        return 1
    end
end
sgs.ai_ajustdamage_from.s3_fans_caomin = function(self, from, to, card, nature)
    return -99
end

sgs.ai_skill_invoke.s3_fans_jiegan = function(self, data)
	return (#self.enemies > 0)
end
sgs.ai_need_damaged.s3_fans_jiegan = function (self,attacker,player)
	if not __scarletayuhuo_value_call(player,"hasSkill","s3_fans_jiegan") then return end
	if __scarletayuhuo_value_call(player,"getMark","@s3_fans_jiegan") == 0 then return end

	return __scarletayuhuo_value_call(player,"getHp")>=2
end
sgs.ai_skill_cardask["@s3_fans_pianji"] = function(self, data, pattern, target)
	local isdummy = type(data) == "number"
	local function getJink(effect)
		if (self:getCardsNum("TrickCard") > 0 or (self:getCardsNum("Slash") > 1-__scarletayuhuo_value_call(self.player,"getMark","s3_fans_pianjiCard"..__scarletayuhuo_value_call(effect.card,"getEffectiveId").."-Clear"))) then
		return self:getCardId("TrickCard") or self:getCardId("Slash") or not isdummy and "."
		else
		return "."
		end
	end
	local effect = data:toCardEffect()
	local slash = effect.card
	local cards = sgs.QList2Table(self.player:getHandcards())
	if (not target or self:isFriend(target)) and __scarletayuhuo_value_call(slash,"hasFlag","nosjiefan-slash") then return "." end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end

	if not self:slashIsEffective(slash,self.player,effect.from)
		or (self:ajustDamage(effect.from,self.player,1,slash)<2
		and self:needToLoseHp(self.player,effect.from,slash)) then return "." end
		if self:ajustDamage(effect.from,self.player,1,slash) and self:getCardsNum("Peach")>0 then return "." end
	if not target then return getJink(effect) end
	if not self:hasHeavyDamage(target, slash, self.player) and self:needToLoseHp(self.player, target, slash) then return "." end

	if self:ajustDamage(target, nil, 1, slash) <= 0 then return "." end

	if __scarletayuhuo_value_call(slash,"isKindOf","NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, target, nil, nil, slash) then return "." end
	if self:isFriend(target) then
		if self:findLeijiTarget(self.player, 50, target) then return getJink(effect) end
		if __scarletayuhuo_value_call(target,"hasSkill","jieyin") and not __scarletayuhuo_value_call(self.player,"isWounded") and __scarletayuhuo_value_call(self.player,"isMale") and not self.player:hasSkills("leiji|nosleiji|olleiji|jieleiji") then return "." end
		if not __scarletayuhuo_value_call(target,"hasSkill","jueqing") then
			if (__scarletayuhuo_value_call(target,"hasSkill","nosrende") or (__scarletayuhuo_value_call(target,"hasSkill","rende") and not target:hasUsed("RendeCard"))) and __scarletayuhuo_value_call(self.player,"hasSkill","jieming") then return "." end
			if __scarletayuhuo_value_call(target,"hasSkill","pojun") and not __scarletayuhuo_value_call(self.player,"faceUp") then return "." end
			if __scarletayuhuo_value_call(target,"hasSkill","BurningLove") and __scarletayuhuo_value_call(slash,"isKindOf","FireSlash") then return "." end
		end
	else
		if self:hasHeavyDamage(target, slash, self.player) then return getJink(effect) end

		local current = self.room:getCurrent()
		if current and __scarletayuhuo_value_call(current,"hasSkill","juece") and __scarletayuhuo_value_call(self.player,"getHp") > 0 then
			local use = false
			for _, card in ipairs(self:getCards("Jink")) do
				if not self.player:isLastHandCard(card, true) then
					use = true
					break
				end
			end
			if not use then return not isdummy and "." end
		end
		if __scarletayuhuo_value_call(self.player,"getHandcardNum") == 1 and self:needKongcheng() then return getJink(effect) end
		if not self:hasLoseHandcardEffective() and not self.player:isKongcheng() then return getJink(effect) end
		if __scarletayuhuo_value_call(target,"hasSkill","mengjin") and not (__scarletayuhuo_value_call(target,"hasSkill","nosqianxi") and __scarletayuhuo_value_call(target,"distanceTo",self.player) == 1) then
			if (__scarletayuhuo_value_call(self.player,"getHandcardNum")+self.player:getEquips():length()) == 1 and not self.player:getArmor() then return getJink(effect) end
			if self.player:hasSkills("jijiu|qingnang") and (__scarletayuhuo_value_call(self.player,"getHandcardNum")+self.player:getEquips():length()) > 1 then return "." end
			if self:canUseJieyuanDecrease(target) then return "." end
			if (self:getCardsNum("Peach") > 0 or (self:getCardsNum("Analeptic") > 0 and self:isWeak()))
				and not hasTuntianEffect(self.player, true) and not self:willSkipPlayPhase() then
				return "."
			end
		end
		if __scarletayuhuo_value_call(self.player,"getHp") > 1 and getKnownCard(target, self.player, "Slash") >= 1 and getKnownCard(target, self.player, "Analeptic") >= 1 and self:getCardsNum("Jink") == 1
			and (__scarletayuhuo_value_call(target,"getPhase") < sgs.Player_Play or self:slashIsAvailable(target) and target:canSlash(self.player)) then
			return "."
		end
		if not (__scarletayuhuo_value_call(target,"hasSkill","nosqianxi") and __scarletayuhuo_value_call(target,"distanceTo",self.player) == 1) then
			if target:hasWeapon("axe") then
				if target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 1 and (__scarletayuhuo_value_call(target,"getHandcardNum")+target:getEquips():length()) > 2 then return not isdummy and "." end
				if __scarletayuhuo_value_call(target,"getHandcardNum") - __scarletayuhuo_value_call(target,"getHp") > 2 and not self:isWeak() and not self:getOverflow() then return not isdummy and "." end
			elseif target:hasWeapon("blade") then

				local has_weak_chained_friend = false
				for _, friend in ipairs(self.friends_noself) do
					if friend:isChained() and self:isWeak(friend) then
						has_weak_chained_friend = true
					end
				end
				if has_weak_chained_friend and __scarletayuhuo_value_call(slash,"isKindOf","NatureSlash") and self.player:isChained() then
					return getJink(effect)
				end

				if __scarletayuhuo_value_call(slash,"isKindOf","NatureSlash") and self.player:hasArmorEffect("vine")
					or self.player:hasArmorEffect("renwang_shield")
					or self:hasEightDiagramEffect()
					or self:hasHeavyDamage(target, slash, self.player)
					or (__scarletayuhuo_value_call(self.player,"getHp") == 1 and #self.friends_noself == 0) then
				elseif (self:getCardsNum("Jink") <= getCardsNum("Slash", target, self.player) or __scarletayuhuo_value_call(self.player,"hasSkill","qingnang")) and __scarletayuhuo_value_call(self.player,"getHp") > 1
					or (__scarletayuhuo_value_call(self.player,"hasSkill","jijiu") and getKnownCard(self.player, self.player, "red") > 0)
					or self:canUseJieyuanDecrease(target)
					then
					return not isdummy and "."
				end
			end
		end
	end
	return getJink(effect)
end
sgs.hit_skill = sgs.hit_skill .. "|s3_fans_pianji"
sgs.ai_cardneed.s3_fans_pianji = sgs.ai_cardneed.slash


sgs.ai_skill_invoke.s3_fans_jiongyan = function(self, data)
	local effect = data:toCardEffect()
	return self:doDisCard(effect.to)
end

sgs.ai_skill_choice.s3_fans_guzhi = function(self, choice)
	if __scarletayuhuo_value_call(self.player,"getHp") < __scarletayuhuo_value_call(self.player,"getMaxHp") - 1 then return "s3_fans_guzhirecover" end
	return "s3_fans_guzhidraw"
end

sgs.ai_skill_use["@@s3_fans_handou"] = function(self, prompt)
	if self.player:isKongcheng() then return "." end
	self.enemies = self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = __scarletayuhuo_value_call(max_card,"getNumber")

	local duel = clone(self,"duel")
	duel:deleteLater()
	local dummy_use = self:aiUseCard(duel, dummy_plan())

	if dummy_use.card then
		for _, enemy in ipairs(self.enemies) do
			if not (__scarletayuhuo_value_call(enemy,"hasSkill","kongcheng") and __scarletayuhuo_value_call(enemy,"getHandcardNum") == 1) and not enemy:isKongcheng() and __scarletayuhuo_value_call(self.player,"canPindian",enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and __scarletayuhuo_value_call(enemy_max_card,"getNumber") or 100
				if max_point > enemy_max_point then
					self:writeCurrentSourceSlot("s3_fans_handou_card",__scarletayuhuo_value_call(max_card,"getEffectiveId"))
					return "#s3_fans_handou:.:->" .. enemy:objectName()
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not (__scarletayuhuo_value_call(enemy,"hasSkill","kongcheng") and __scarletayuhuo_value_call(enemy,"getHandcardNum") == 1) and not enemy:isKongcheng() and __scarletayuhuo_value_call(self.player,"canPindian",enemy) then
				if max_point >= 10 then
					self:writeCurrentSourceSlot("s3_fans_handou_card",__scarletayuhuo_value_call(max_card,"getEffectiveId"))
					return "#s3_fans_handou:.:->" .. enemy:objectName()
				end
			end
		end
		if #self.enemies < 1 then return end
	end
	return "."
end




sgs.ai_skill_playerchosen.s3_fans_shanlan = function(self, targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "hp")
	for _, target in ipairs(targets) do
		if self:isFriend(target) and (__scarletayuhuo_value_call(target,"getMark","@s3_fans_shanlan") == 0) then
			return target
		end
	end
	return nil
end


sgs.ai_skill_invoke.s3_fans_shanlan = function(self, data)
	local dying = 0
	local handang = self.room:findPlayerBySkillName("nosjiefan")
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if __scarletayuhuo_value_call(aplayer,"getHp") < 1 and not __scarletayuhuo_value_call(aplayer,"hasSkill","nosbuqu") then
			dying = 1
			break
		end
	end
	if handang and self:isFriend(handang) and dying > 0 then return false end

	local heart_jink = false
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if __scarletayuhuo_value_call(card,"getSuit") == sgs.Card_Heart and isCard("Jink", card, self.player) then
			heart_jink = true
			break
		end
	end

	local current = self.room:getCurrent()
	if current and self:isFriend(current) and self.player:isChained() and self:isGoodChainTarget(self.player, current) then return false end --內奸跳反會有問題，非屬性殺也有問題。但狀況特殊，八卦陣原碼資訊不足，暫時這樣寫。

	if self:hasSkills("tiandu|leiji|nosleiji|olleiji|gushou") then
		if __scarletayuhuo_value_call(self.player,"hasFlag","dahe") and not heart_jink then return true end
		if response_source(self,"hujiasource") and not self:isFriend(response_source(self,"hujiasource")) and (response_source(self,"hujiasource"):hasFlag("dahe") or __scarletayuhuo_value_call(self.player,"hasFlag","dahe")) then return true end
		if response_source(self,"lianlisource") and not self:isFriend(response_source(self,"lianlisource")) and (response_source(self,"lianlisource"):hasFlag("dahe") or __scarletayuhuo_value_call(self.player,"hasFlag","dahe")) then return true end
		if __scarletayuhuo_value_call(self.player,"hasFlag","dahe") and handang and self:isFriend(handang) and dying > 0 then return true end
	end
	if __scarletayuhuo_value_call(self.player,"getHandcardNum") == 1 and self:getCardsNum("Jink") == 1 and self.player:hasSkills("zhiji|beifa") and self:needKongcheng() then
		local enemy_num = self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player)
		if __scarletayuhuo_value_call(self.player,"getHp") > enemy_num and enemy_num <= 1 then return false end
	end
	if handang and self:isFriend(handang) and dying > 0 then return false end
	if __scarletayuhuo_value_call(self.player,"hasFlag","dahe") then return false end
	if response_source(self,"hujiasource") and (not self:isFriend(response_source(self,"hujiasource")) or response_source(self,"hujiasource"):hasFlag("dahe")) then return false end
	if response_source(self,"lianlisource") and (not self:isFriend(response_source(self,"lianlisource")) or response_source(self,"lianlisource"):hasFlag("dahe")) then return false end
	if self:needToLoseHp(self.player, nil, true, true) then return false end
	if self:getCardsNum("Jink") == 0 then return true end

	return true
end



sgs.ai_playerchosen_intention.s3_fans_shanlan = -50


sgs.ai_skill_playerchosen.s3_fans_yanfeng = function(self, targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "hp")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and (__scarletayuhuo_value_call(target,"getMark","@s3_fans_yanfeng") == 0) then
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.s3_fans_yanfeng = 50

sgs.ai_skill_discard.s3_fans_yanfeng = function(self, discard_num, min_num, optional, include_equip)
	local cards = self.player:getCards("he")
	local to_discard = {}
	cards = sgs.QList2Table(cards)
	if self:needBear() then
		return {}
	end
	if self:needToThrowArmor() and self.player:getArmor():isBlack() then
		table.insert(to_discard, self.player:getArmor():getId())
		return to_discard
	end
	for _, card in ipairs(cards) do
		if not self.player:isJilei(card) and card:isBlack() then
			table.insert(to_discard, card:getId())
			return to_discard
		end
	end
	return to_discard
end

sgs.ai_skill_choice["s3_fans_luoshi"] = function(self, choices, data)
	local items = choices:split("+")

	if (self.player:containsTrick("indulgence") or self.player:containsTrick("supply_shortage")) then
		if __scarletayuhuo_value_call(self.player,"getHandcardNum") < __scarletayuhuo_value_call(self.player,"getHp") - 2 then
			if table.contains(items, "s3_fans_luoshi_jp") then return "s3_fans_luoshi_jp" end
		else
			if table.contains(items, "s3_fans_luoshi_jd") then return "s3_fans_luoshi_jd" end
		end
	end
	if not self:isWeak() then
		if table.contains(items, "s3_fans_luoshi_lose") then return "s3_fans_luoshi_lose" end
	end
	return "cancel"
end

local function getjibianValue(self, who, card, from)
	if not self:hasTrickEffective(card, who, from) then return 0 end
	if __scarletayuhuo_value_call(card,"isKindOf","AOE") then
		if not self:isFriend(who) then return 0 end
		local value = self:getAoeValueTo(card, who, from)
		if value < 0 then return -value / 30 end
	elseif __scarletayuhuo_value_call(card,"isKindOf","GodSalvation") then
		if not self:isEnemy(who) or not __scarletayuhuo_value_call(who,"isWounded") or __scarletayuhuo_value_call(who,"getHp") >= getBestHp(who) then return 0 end
		if self:isWeak(who) then return 1.2 end
		if who:hasSkills(sgs.masochism_skill) then return 1.0 end
		return 0.9
	elseif __scarletayuhuo_value_call(card,"isKindOf","AmazingGrace") then
		if not self:isEnemy(who) or hasManjuanEffect(who) then return 0 end
		local v = 1.2
		local p = self.room:getCurrent()
		while p:objectName() ~= who:objectName() do
			v = v * 0.9
			p = p:getNextAlive()
		end
		return v
	end
	return 0
end

sgs.ai_skill_use["@@s3_fans_jibian1"] = function(self, prompt)
	local liuxie = self.room:findPlayerBySkillName("huangen")
	if liuxie and self:isFriend(liuxie) and not self:isWeak(liuxie) then return "." end

	local card = room_tag(self,"s3_fans_jibian","CardUse").card
	local from = room_tag(self,"s3_fans_jibian","CardUse").from

	local players = sgs.QList2Table(self.room:getAllPlayers())
	players = self:sort(players, "defense")
	local target_table = {}
	local targetslist = property(self,"s3_fans_jibian_target"):split("+")
	local value = 0
	for _, player in ipairs(players) do
		if not (__scarletayuhuo_value_call(player,"hasSkill","danlao") or (player:hasSkills("jianxiong|nosjianxiong") and not self:isWeak(player)))
			and table.contains(targetslist, player:objectName()) and #target_table < __scarletayuhuo_value_call(self.player,"getHp") then
			local val = getjibianValue(self, player, card, from)
			if val > 0 then
				value = value + val
				table.insert(target_table, player:objectName())
			end
		end
	end
	if #target_table == 0 or value / (self.room:alivePlayerCount() - 1) < 0.55 then return "." end
	local cards = {}
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("he"))) do
		table.insert(cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
		if #cards == #target_table then
			break
		end
	end
	if #cards == #target_table then
		return "#s3_fans_jibian:" .. table.concat(cards, "+") .. ":->" .. table.concat(target_table, "+")
	end
	return "."
end


sgs.ai_skill_playerchosen.s3_fans_jibian = function(self, targets)
	if self:needKongcheng(self.player, true) then
		return nil
	end
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and (not target:hasSkills(sgs.lose_equip_skill) or self:doDisCard(target)) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and ((target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 0) or self:needToThrowArmor(target)) then return
			target end
	end

	return targets[1]
end

local function card_for_jibian(self, who, return_prompt)
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__scarletayuhuo_value_call(judge,"getEffectiveId"))
				if not __scarletayuhuo_value_call(judge,"isKindOf","YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (__scarletayuhuo_value_call(enemy,"hasSkill","hongyan") or __scarletayuhuo_value_call(judge,"isKindOf","Lightning")) then
							target = enemy
							break
						end
					end
					if target then break end
				end
			end
		end

		local equips = who:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, who) then
			for _, equip in sgs.qlist(equips) do
				if __scarletayuhuo_value_call(equip,"isKindOf","OffensiveHorse") then
					card = equip
					break
				elseif __scarletayuhuo_value_call(equip,"isKindOf","Weapon") then
					card = equip
					break
				elseif __scarletayuhuo_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif __scarletayuhuo_value_call(equip,"isKindOf","Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if __scarletayuhuo_value_call(card,"isKindOf","Armor") or __scarletayuhuo_value_call(card,"isKindOf","DefensiveHorse") then
					self.friends = self:sort(self.friends, "defense")
				else
					self.friends = self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end
		end
	else
		local judges = who:getJudgingArea()
		if who:containsTrick("YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if __scarletayuhuo_value_call(judge,"isKindOf","YanxiaoCard") then
					card = visible(self,__scarletayuhuo_value_call(judge,"getEffectiveId"))
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge)
							and not friend:getJudgingArea():isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge) then
							target = friend
							break
						end
					end
					if target then break end
				end
			end
		end
		if card == nil or target == nil then
			if not who:hasEquip() or self:hasSkills(sgs.lose_equip_skill, who) then return nil end
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(visible(self,card_id)) then card = visible(self,card_id) end

			if card then
				if __scarletayuhuo_value_call(card,"isKindOf","Armor") or __scarletayuhuo_value_call(card,"isKindOf","DefensiveHorse") then
					self.friends = self:sort(self.friends, "defense")
				else
					self.friends = self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and self:hasSkills(sgs.lose_equip_skill .. "|shensu", friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end
		end
	end

	if return_prompt == "card" then
		return card
	elseif return_prompt == "target" then
		return target
	else
		return (card and target)
	end
end

sgs.ai_skill_use["@@s3_fans_jibian2"] = function(self, prompt)
	local who = room_tag(self,"s3_fans_jibian","Player")
	if not who or not self:isFriend(who) then return "." end
	local target = card_for_jibian(self, who, "target")

	local cards = {}
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("he"))) do
		table.insert(cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
		if #cards == __scarletayuhuo_value_call(self.player,"getHp") - 1 then
			break
		end
	end
	if #cards == __scarletayuhuo_value_call(self.player,"getHp") - 1 and __scarletayuhuo_value_call(self.player,"getHp") - 1 < 4 and target then
		return "#s3_fans_jibian:" .. table.concat(cards, "+") .. ":->" .. target:objectName()
	end
	return "."
end


sgs.ai_fill_skill["s3_fans_feiyan"] = function(self,inclusive,request)
	if (__scarletayuhuo_value_call(self.player,"getHandcardNum")+self.player:getEquips():length()) < 1 then return nil end
	if self.player:hasUsed("#s3_fans_feiyan") then return nil end
	local card
	if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		hcards = self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if __scarletayuhuo_value_call(hcard,"isKindOf","EquipCard") then
				card = hcard
				break
			end
		end
	end
	if card then
		return policy(self,"#s3_fans_feiyan:.:")
	end
end

sgs.ai_skill_use_func["#s3_fans_feiyan"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "defense")
	local target = nil
	local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
			and enemy:objectName() ~= self.player:objectName() then
			target = enemy
			break
		end
	end
	local card
	if not card then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		hcards = self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if __scarletayuhuo_value_call(hcard,"isKindOf","EquipCard") then
				card = hcard
				break
			end
		end
	end
	if card then
		if target then
			use.card = policy(self,"#s3_fans_feiyan:" .. card:getId() .. ":")
			if use.to then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_use_value["#s3_fans_feiyan"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["#s3_fans_feiyan"] = sgs.ai_use_priority.Slash - 0.2




function sgs.ai_cardneed.s3_fans_feiyan(to, card, self)
	return __scarletayuhuo_value_call(card,"getTypeId") == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", true) == 0
end

sgs.ai_skill_invoke.s3_fans_qingyu = function(self, data)
	local dmg = data:toDamage()
	if self:damageStruct(dmg) and self:needToLoseHp(dmg.to, dmg.from, dmg.card) then
		return false
	end
	return true
end
sgs.ai_ajustdamage_from.s3_fans_caihua = function(self, from, to, card, nature)
    if card and __scarletayuhuo_value_call(card,"isKindOf","Slash") and __scarletayuhuo_value_call(card,"getSuitString") == "no_suit"
    then
        return 1
    end
end



sgs.ai_skill_invoke.s3_fans_shangji = function(self, data)
	return true
end



sgs.ai_skill_invoke.s3_fans_yunce = function(self, data)
	return true
end


sgs.ai_skill_choice["s3_fans_yunce"] = function(self, choices, data)
	self:updatePlayers()
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		local duel = clone(self,"savage_assault", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		if self:hasTrickEffective(duel, target, self.player) then
			return "duel"
		end
	end
	if target and self:isFriend(target) then
		local duel = clone(self,"ex_nihilo", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		return "ex_nihilo"
	end

	return "cancel"
end
sgs.ai_ajustdamage_from.s3_fans_wenjiu = function(self, from, to, card, nature)
    if card and (__scarletayuhuo_value_call(card,"isKindOf","Slash") or __scarletayuhuo_value_call(card,"isKindOf","Duel")) and __scarletayuhuo_value_call(from,"hasFlag","s3_fans_wenjiu") and from:objectName() ~= to:objectName()
    then
        return 1
    end
end

sgs.ai_cardneed.s3_fans_wenjiu = sgs.ai_cardneed.slash
sgs.ai_cardneed.s3_fans_longxiao = sgs.ai_cardneed.slash

sgs.ai_fill_skill["s3_fans_xianjia"] = function(self,inclusive,request)
	local card
	if self:needToThrowArmor() then
		card = self.player:getArmor()
	end
	if not card then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		hcards = self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if __scarletayuhuo_value_call(hcard,"isKindOf","EquipCard") then
				card = hcard
				break
			end
		end
	end
	if not card then
		local ecards = self.player:getCards("e")
		ecards = sgs.QList2Table(ecards)

		for _, ecard in ipairs(ecards) do
			if __scarletayuhuo_value_call(ecard,"isKindOf","Weapon") or __scarletayuhuo_value_call(ecard,"isKindOf","OffensiveHorse") then
				card = ecard
				break
			end
		end
	end
	if card then
		card = policy(self,"#s3_fans_xianjia:" .. __scarletayuhuo_value_call(card,"getEffectiveId") .. ":")
		return card
	end

	return nil
end

sgs.ai_skill_use_func["#s3_fans_xianjia"] = function(card, use, self)
	local target
	local friends = self.friends_noself

	local canMingceTo = function(player)
		local canGive = not self:needKongcheng(player, true)
		return canGive or (not canGive and self:getEnemyNumBySeat(self.player, player) == 0)
	end

	if not target then
		friends = self:sort(friends, "defense")
		for _, friend in ipairs(friends) do
			if canMingceTo(friend) then
				target = friend
				break
			end
		end
	end

	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value["#s3_fans_xianjia"] = sgs.ai_use_value.RendeCard
sgs.ai_use_priority["#s3_fans_xianjia"] = sgs.ai_use_priority.RendeCard

sgs.ai_card_intention["#s3_fans_xianjia"] = sgs.ai_card_intention.RendeCard

sgs.dynamic_value.benefit["#s3_fans_xianjia"] = true

sgs.ai_skill_invoke.s3_fans_yinbing = function(self, data)
	local target = data:toPlayer()
	local use = room_tag(self,"CurrentUseStruct","CardUse")
	if not self:isFriend(target) or self:isFriend(use.from) then return false end
	if target:hasSkills("liuli|tianxiang|ol_tianxiang") and __scarletayuhuo_value_call(target,"getHandcardNum") > 1 then return false end
	if not self:slashIsEffective(use.card, target, use.from) then return false end
	if target:hasSkills(sgs.masochism_skill) and not self:isWeak(target) then return false end

	if not self:slashIsEffective(use.card, self.player, use.from) then return true end

	if __scarletayuhuo_value_call(self.player,"getHandcardNum") + self.player:getEquips():length() < 2 and not self:isWeak(target) then return false end


	if self:isWeak(target) and not self:isWeak() then return true end
	if self:getCardsNum("Jink") > 0 then return true end

	return false
end

sgs.ai_skill_discard.s3_fans_yinbing = function(self)
	local to_discard = {}
	local use = room_tag(self,"CurrentUseStruct","CardUse")
	if not self:slashIsEffective(use.card, self.player, use.from) then return to_discard end
	if self.player:hasSkills(sgs.masochism_skill) and not self:isWeak(self.player) then
		return to_discard
	end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if __scarletayuhuo_value_call(card,"isKindOf","EquipCard") then
			table.insert(to_discard, __scarletayuhuo_value_call(card,"getEffectiveId"))
			break
		end
	end
	return to_discard
end


sgs.ai_skill_use["@@s3_xianju"] = function(self, prompt)
	local target


	local cards = {}
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if not __scarletayuhuo_value_call(c,"isKindOf","Peach") then
			table.insert(cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
			if #cards == 2 then
				break
			end
		end
	end

	local max = 0
	for _, friend in ipairs(self.friends_noself) do
		local temp = 0
		for _, enemy in ipairs(self.enemies) do
			if __scarletayuhuo_value_call(enemy,"inMyAttackRange",friend) then
				temp = temp + 1
			end
		end
		if temp + 6 - __scarletayuhuo_value_call(friend,"getHp") > max then
			max = temp + 6 - __scarletayuhuo_value_call(friend,"getHp")
			target = friend
		end
	end
	if self:needBear() then return "." end
	if #cards == 2 and target and self:isWeak(target) then
		return "#s3_xianju:" .. table.concat(cards, "+") .. ":->" .. target:objectName()
	end
	if target and self:isWeak(target) and not self:isWeak() then
		return "#s3_xianju:.:->" .. target:objectName()
	end
	return "."
end



sgs.ai_skill_playerchosen.s3_jxwj_fange = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

sgs.ai_cardneed.s3_jxwj_fange = sgs.ai_cardneed.slash
sgs.ai_cardneed.s3_jxwj_zhoudao = sgs.ai_cardneed.slash
sgs.ai_skill_playerchosen["s3_jxwj_zhoudao"] = function(self, targets)
	local x = math.max(1, __scarletayuhuo_value_call(self.player,"getLostHp"))
	local target = self:findPlayerToDraw(true, x)
	if target then
		return target
	else
		return self.player
	end
end

sgs.ai_playerchosen_intention["s3_jxwj_zhoudao"] = -20

sgs.ai_skill_cardask["@s3_jxwj_duce"] = function(self, data, pattern, target)
	local damage = data:toDamage()
	if (damage.from and self:isEnemy(damage.from) and self:isWeak(damage.from)) or (not damage.to:hasSkills(sgs.masochism_skill) and __scarletayuhuo_value_call(self.player,"getLostHp") > 1) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		cards = self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if __scarletayuhuo_value_call(card,"getSuit") == sgs.Card_Spade then
				return "$" .. __scarletayuhuo_value_call(card,"getEffectiveId")
			end
		end
	end
	return "."
end

sgs.ai_skill_choice.s3_jxwj_duce = function(self, choices)
	local damage = room_tag(self,"CurrentDamageStruct","Damage")
	if damage.from and self:isEnemy(damage.from) and self:isWeak(damage.from) then
		return "s3_jxwj_duce_lost"
	end
	return "s3_jxwj_duce_from"
end


sgs.ai_choicemade_filter.skillChoice["s3_jxwj_duce"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	if choice == "s3_jxwj_duce_lost" then
		local damage = room_tag(self,"CurrentDamageStruct","Damage")
		self:updateIntention(player, damage.from, 80)
	end
end



function sgs.ai_cardsview_valuable.s3_jxwj_weiwan(self, class_name, player)
	if class_name == "Peach" and __scarletayuhuo_value_call(player,"faceUp") then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then return nil end
		if dying:isKongcheng() then return nil end
		if __scarletayuhuo_value_call(dying,"isLord") and self:isFriend(dying, player) then return "#s3_jxwj_weiwan:.:" end

		if self:playerGetRound(dying) < self:playerGetRound(self.player) and __scarletayuhuo_value_call(dying,"getHp") < 0 then return nil end
		if __scarletayuhuo_value_call(player,"faceUp") then
			if __scarletayuhuo_value_call(dying,"getMark","Global_PreventPeach") == 0 then
				for _, c in sgs.qlist(complete_hand(self,player)) do
					if not isCard("Peach", c, player) then return nil end
				end
			end
			return "#s3_jxwj_weiwan:.:"
		end
		return nil
	end
end

function sgs.ai_cardsview.s3_jxwj_weiwan(self, class_name, player)
	if class_name == "Peach" and __scarletayuhuo_value_call(player,"faceUp") then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then return nil end
		if dying:isKongcheng() then return nil end
		if __scarletayuhuo_value_call(dying,"isLord") and self:isFriend(dying, player) then return "#s3_jxwj_weiwan:.:" end

		if not self:isWeak(player) then return "#s3_jxwj_weiwan:.:" end
		return nil
	end
end

sgs.ai_card_intention["#s3_jxwj_weiwan"] = sgs.ai_card_intention.Peach


sgs.ai_skill_invoke.s3_jxwj_miaoyan = function(self, data)
	local use = data:toCardUse()
	if not use.from or __scarletayuhuo_value_call(use.from,"isDead") then return false end
	if self.role == "rebel" and known(self:getRoleEstimate(use.from),"role estimate") == "rebel" and not __scarletayuhuo_value_call(use.from,"hasSkill","jueqing")
		and __scarletayuhuo_value_call(self.player,"getHp") == 1 and self:getAllPeachNum() < 1 then
		return false
	end

	if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not __scarletayuhuo_value_call(use.from,"hasSkill","jueqing") and __scarletayuhuo_value_call(use.from,"isLord") and __scarletayuhuo_value_call(self.player,"getHp") == 1) then
		if __scarletayuhuo_value_call(use.card,"isKindOf","AOE") then
			local from = use.from
			if __scarletayuhuo_value_call(use.card,"isKindOf","SavageAssault") then
				local menghuo = self.room:findPlayerBySkillName("huoshou")
				if menghuo then from = menghuo end
			end


			if __scarletayuhuo_value_call(use.from,"hasSkill","drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then return true end

			if self:isEnemy(from) and __scarletayuhuo_value_call(from,"hasSkill","jueqing") then return self:doDisCard(from) end
			if self:isFriend(from) and self.role == "loyalist" and __scarletayuhuo_value_call(from,"isLord") and __scarletayuhuo_value_call(self.player,"getHp") == 1 and not __scarletayuhuo_value_call(from,"hasSkill","jueqing") then return true end
			if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or __scarletayuhuo_value_call(use.from,"hasSkill","jueqing"))
				and self:doDisCard(use.from) then
				return true
			end
		elseif self:isEnemy(use.from) then
			if __scarletayuhuo_value_call(use.card,"isKindOf","FireAttack") and __scarletayuhuo_value_call(use.from,"getHandcardNum") > 0 then
				return self:doDisCard(use.from)
			elseif (__scarletayuhuo_value_call(use.card,"isKindOf","Snatch") or __scarletayuhuo_value_call(use.card,"isKindOf","Dismantlement"))
				and self:getCardsNum("Peach") == __scarletayuhuo_value_call(self.player,"getHandcardNum") and not self.player:isKongcheng() then
				return self:doDisCard(use.from)
			elseif __scarletayuhuo_value_call(use.card,"isKindOf","Duel") then
				return self:doDisCard(use.from)
			elseif __scarletayuhuo_value_call(use.card,"isKindOf","TrickCard") then
				if self:doDisCard(use.from) then
					return true
				end
			end
		end
	end
	return false
end



sgs.ai_skill_choice.s3_jxwj_dunwei = function(self, choices)
	local items = choices:split("+")
	if self:getOverflow() > 0 and table.contains(items, "s3_jxwj_dunwei_keji") then
		if __scarletayuhuo_value_call(self.player,"getHandcardNum") > __scarletayuhuo_value_call(self.player,"getMaxHp") then
			return "s3_jxwj_dunwei_keji"
		end
	end
	return "s3_jxwj_dunwei_draw"
end


sgs.ai_skill_cardask["@s3_jxwj_boji"] = function(self, data, pattern, target)
	local damage = data:toDamage()
	if self.player:objectName() == damage.from:objectName() then
		if not self:isEnemy(damage.to) then return "." end
		if damage.to:hasArmorEffect("silver_lion") then return "." end
	end
	if self.player:objectName() == damage.to:objectName() then
		if self:needToLoseHp(self.player, damage.from, damage.card) and damage.damage <= 1 then return "." end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	if self:needToThrowArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	for _, card in ipairs(cards) do
		if __scarletayuhuo_value_call(card,"isKindOf","EquipCard") then
			return "$" .. __scarletayuhuo_value_call(card,"getEffectiveId")
		end
	end
	return "."
end


sgs.ai_skill_invoke.s3_jxwj_zhuwei = function(self, data)
	if (self.player:getJudgingArea():length() > 0) or (self.player:isSkipped(sgs.Player_Draw)) then
		return true
	end
	return false
end



sgs.ai_skill_invoke.s3_jxwj_zhuwei_draw = function(self, data)
	return true
end


sgs.ai_skill_use["@@s3_jxwj_zhuwei"] = function(self, prompt)
	local target
	if self.player:getJudgingArea():length() > 0 then
		local cards = {}
		if self.player:containsTrick("indulgence") then
			for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
				if not __scarletayuhuo_value_call(c,"isKindOf","TrickCard") and c:isBlack() then
					table.insert(cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
					if #cards == 1 then
						break
					end
				end
			end
		elseif self.player:containsTrick("supply_shortage") then
			for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
				if not __scarletayuhuo_value_call(c,"isKindOf","TrickCard") and __scarletayuhuo_value_call(c,"getSuit") == sgs.Card_Diamond then
					table.insert(cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
					if #cards == 1 then
						break
					end
				end
			end
		else
			for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
				if not __scarletayuhuo_value_call(c,"isKindOf","TrickCard") and __scarletayuhuo_value_call(c,"getSuit") ~= sgs.Card_Heart then
					table.insert(cards, __scarletayuhuo_value_call(c,"getEffectiveId"))
					if #cards == 1 then
						break
					end
				end
			end
		end




		if #cards == 1 then
			return "#s3_jxwj_zhuwei:" .. table.concat(cards, "+") .. ":"
		end
	end


	return "."
end



sgs.ai_skill_use["@@s3_jxwj_zijun"] = function(self, prompt)
	self.friends_noself = self:sort(self.friends_noself, "handcard")

	if not __scarletayuhuo_value_call(self.player,"isWounded") then return "." end
	local equips = {}

	local ecards = self.player:getCards("e")
	ecards = sgs.QList2Table(ecards)

	for _, ecard in ipairs(ecards) do
		if __scarletayuhuo_value_call(ecard,"isKindOf","Weapon") or __scarletayuhuo_value_call(ecard,"isKindOf","OffensiveHorse") then
			table.insert(equips, ecard)
		end
	end

	if #equips == 0 then return "." end

	local select_equip, target
	for _, friend in ipairs(self.friends_noself) do
		for _, equip in ipairs(equips) do
			local equip_index = known(equip:getEquipSlot(),"equipment slot")
			if not self:getSameEquip(equip, friend) and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) and friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
		for _, equip in ipairs(equips) do
			local equip_index = known(equip:getEquipSlot(),"equipment slot")
			if not self:getSameEquip(equip, friend) and friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
	end



	if target and select_equip then
		return "#s3_jxwj_zijun:" .. select_equip:getId() .. ":->" .. target:objectName()
	end
	return "."
end




sgs.ai_fill_skill["s3_jxwj_shangdao"] = function(self,inclusive,request)
	if self:needBear() then return end
	if self.player:hasUsed("#s3_jxwj_shangdao") then return end
	card = policy(self,"#s3_jxwj_shangdao:.:")
	return card
end
local s3_jxwj_shangdao_discard = function(self, discard_num, mycards)
	local cards = mycards
	local to_discard = {}

	local aux_func = function(card)
		local place = self.room:getCardPlace(__scarletayuhuo_value_call(card,"getEffectiveId"))
		if self:getUseValue(card) >= 6 then
			return 3                           --使用价值高的牌，如顺手牵羊(9),下调至桃
		elseif self:hasSkills(sgs.lose_equip_skill) then
			return 5
		else
			return 0
		end
		return 0
	end

	local compare_func = function(a, b)
		if aux_func(a) ~= aux_func(b) then
			return aux_func(a) < aux_func(b)
		end
		return self:getKeepValue(a) < self:getKeepValue(b)
	end

	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if not self.player:isJilei(card) then table.insert(to_discard, card:getId()) end
		if #to_discard >= discard_num then break end
	end
	if #to_discard ~= discard_num then return {} end
	return to_discard
end

sgs.ai_skill_use_func["#s3_jxwj_shangdao"] = function(card, use, self)
	local mycards = {}

	local keepaslash
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if not self.player:isJilei(c) then
			local shouldUse
			if not keepaslash and isCard("Slash", c, self.player) then
				local dummy_use = { isDummy = true, to = AIList.new({}) }
				self:useBasicCard(c, dummy_use)
				if dummy_use.card and not dummy_use.to:isEmpty() and (dummy_use.to:length() > 1 or dummy_use.to:first():getHp() <= 1) then
					shouldUse = true
				end
			end
			if not shouldUse then table.insert(mycards, c) end
		end
	end

	if #mycards == 0 then return end
	mycards = self:sortByKeepValue(mycards)

	self.enemies = self:sort(self.enemies, "handcard")


	self.enemies = self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if hasManjuanEffect(enemy) then
			local e_hand = __scarletayuhuo_value_call(enemy,"getHandcardNum")

			local f_peach, f_hand = getCardsNum("Peach", self.player), __scarletayuhuo_value_call(self.player,"getHandcardNum")
			if (e_hand > f_hand - 1) and (e_hand - f_hand) <= #mycards and (f_hand > 0 or e_hand > 0) and f_peach <= 2 then
				if e_hand == f_hand then
					local discards = s3_jxwj_shangdao_discard(self, f_hand, mycards)
					if #discards > 0 then use.card = policy(self,"#s3_jxwj_shangdao:" ..
						table.concat(discards, "+") .. ":") end
				else
					local discard_num = 3
					local discards = s3_jxwj_shangdao_discard(self, discard_num, mycards)
					if #discards > 0 then use.card = policy(self,"#s3_jxwj_shangdao:" ..
						table.concat(discards, "+") .. ":") end
				end
				if use.card and use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		local e_hand = __scarletayuhuo_value_call(enemy,"getHandcardNum")

		local f_peach, f_hand = getCardsNum("Peach", self.player), __scarletayuhuo_value_call(self.player,"getHandcardNum")
		if (e_hand > f_hand - 1) and (e_hand - f_hand) <= #mycards and (f_hand > 0 or e_hand > 0) and f_peach <= 2 then
			if e_hand == f_hand then
				local discards = s3_jxwj_shangdao_discard(self, f_hand, mycards)
				if #discards > 0 then use.card = policy(self,"#s3_jxwj_shangdao:" .. table.concat(discards, "+") ..
					":") end
			else
				local discard_num = 3
				local discards = s3_jxwj_shangdao_discard(self, discard_num, mycards)
				if #discards > 0 then use.card = policy(self,"#s3_jxwj_shangdao:" .. table.concat(discards, "+") ..
					":") end
			end
			if use.card and use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end



sgs.ai_skill_choice.s3_jxwj_xiantu = function(self, choices)
	return "s3_jxwj_xiantu_show"
end



sgs.ai_skill_cardask["@s3_jxwj_qiangji"] = function(self, data, pattern, target)
	local move = data:toMoveOneTime()
	local card = visible(self,move.card_ids:first())
	if __scarletayuhuo_value_call(card,"isKindOf","ExNihilo") or __scarletayuhuo_value_call(card,"isKindOf","excard_yjjg") or __scarletayuhuo_value_call(card,"isKindOf","Snatch") then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _, c in ipairs(cards) do
			if __scarletayuhuo_value_call(c,"getSuit") == __scarletayuhuo_value_call(card,"getSuit") then
				return "$" .. __scarletayuhuo_value_call(c,"getEffectiveId")
			end
		end
	end
	return "."
end

sgs.ai_can_damagehp.s3_jxwj_gangli = function(self,from,card,to)
	if from and __scarletayuhuo_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and self:doDisCard(from, "he")
	end
end

sgs.ai_skill_invoke.s3_jxwj_gangli = function(self, data)
	local damage = data:toDamage()
	if damage.from and self:isEnemy(damage.from) then
		local x = __scarletayuhuo_value_call(damage.from,"getHandcardNum") - __scarletayuhuo_value_call(self.player,"getHp")
		if x > __scarletayuhuo_value_call(self.player,"getHp") then
			self:writeCurrentSourceSlot("s3_jxwj_ganglichoice","s3_jxwj_gangli_throwtohp")
		else
			self:writeCurrentSourceSlot("s3_jxwj_ganglichoice","s3_jxwj_gangli_throwhp")
		end
		return self:doDisCard(damage.from)
	end
	return false
end



sgs.ai_skill_choice.s3_jxwj_gangli = function(self, choices)
	return self:readCurrentSourceSlot("s3_jxwj_ganglichoice")
end




sgs.ai_fill_skill["s3_jxwj_fuji"] = function(self,inclusive,request)
	if self.player:getPile("s3_jxwj_fu"):length() == 0 and __scarletayuhuo_value_call(self.player,"getHandcardNum") > 0 then
		return policy(self,"#s3_jxwj_fuji:.:")
	end
end

sgs.ai_skill_use_func["#s3_jxwj_fuji"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	if __scarletayuhuo_value_call(cards[1],"isKindOf","Peach") or __scarletayuhuo_value_call(cards[1],"isKindOf","Nullification") or __scarletayuhuo_value_call(cards[1],"isKindOf","Analeptic") then return end
	use.card = policy(self,"#s3_jxwj_fuji:" .. __scarletayuhuo_value_call(cards[1],"getEffectiveId") .. ":")
	return
end


sgs.ai_skill_invoke.s3_jxwj_fuji = function(self, data)
	local use = data:toCardUse()
	local card = visible(self,self.player:getPile("s3_jxwj_fu"):first())
	if __scarletayuhuo_value_call(card,"getSuit") == __scarletayuhuo_value_call(use.card,"getSuit") and __scarletayuhuo_value_call(card,"getNumber") == __scarletayuhuo_value_call(use.card,"getNumber") then
		return true
	end
	if __scarletayuhuo_value_call(card,"getNumber") == __scarletayuhuo_value_call(use.card,"getNumber") then
		return true
	end
	if __scarletayuhuo_value_call(card,"getSuit") == __scarletayuhuo_value_call(use.card,"getSuit") and (__scarletayuhuo_value_call(use.card,"isKindOf","ExNihilo") or __scarletayuhuo_value_call(use.card,"isKindOf","excard_yjjg") or __scarletayuhuo_value_call(use.card,"isKindOf","Snatch")) then
		return true
	end


	return self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player, true) < __scarletayuhuo_value_call(self.player,"getHp")
end



sgs.ai_cardsview_valuable.s3_jxwj_jiujia = function(self, class_name, player)
	if __scarletayuhuo_value_call(player,"getPhase") ~= sgs.Player_NotActive then return end



	if (known(self.request.reason,"response reason") == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			or known(self.request.reason,"response reason") == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
	then
		if class_name == "Jink" then
			return ("#s3_jxwj_jiujia:.:jink")
		end
	end
end


sgs.ai_skill_choice.s3_jxwj_jiujia = function(self, choices)
	local items = choices:split("+")
	if table.contains(items, "s3_jxwj_jiujia_equip") then
		local card
		local target


		local equips = self.player:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, self.player) then
			for _, equip in sgs.qlist(equips) do
				if __scarletayuhuo_value_call(equip,"isKindOf","OffensiveHorse") then
					card = equip
					break
				elseif __scarletayuhuo_value_call(equip,"isKindOf","Weapon") then
					card = equip
					break
				elseif __scarletayuhuo_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak() then
					card = equip
					break
				elseif __scarletayuhuo_value_call(equip,"isKindOf","Armor") and (not self:isWeak() or self:needToThrowArmor()) then
					card = equip
					break
				end
			end

			if card then
				if __scarletayuhuo_value_call(card,"isKindOf","Armor") or __scarletayuhuo_value_call(card,"isKindOf","DefensiveHorse") then
					self.friends = self:sort(self.friends, "defense")
				else
					self.friends = self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName() then
						target = friend
						break
					end
				end
				if target then
					return "s3_jxwj_jiujia_equip"
				end
			end
		end
	end
	return "s3_jxwj_jiujia_lostHp"
end


sgs.ai_skill_cardchosen.s3_jxwj_jiujia = function(self, who, flags)
	local card
	local target
	if self:isFriend(who) then
		local equips = who:getCards("e")
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, who) then
			for _, equip in sgs.qlist(equips) do
				if __scarletayuhuo_value_call(equip,"isKindOf","OffensiveHorse") then
					card = equip
					break
				elseif __scarletayuhuo_value_call(equip,"isKindOf","Weapon") then
					card = equip
					break
				elseif __scarletayuhuo_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif __scarletayuhuo_value_call(equip,"isKindOf","Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if __scarletayuhuo_value_call(card,"isKindOf","Armor") or __scarletayuhuo_value_call(card,"isKindOf","DefensiveHorse") then
					self.friends = self:sort(self.friends, "defense")
				else
					self.friends = self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
				if target then
					return card
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen.s3_jxwj_jiujia = function(self, targets)
	local card
	local equips = self.player:getCards("e")
	local weak
	local target
	if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, self.player) then
		for _, equip in sgs.qlist(equips) do
			if __scarletayuhuo_value_call(equip,"isKindOf","OffensiveHorse") then
				card = equip
				break
			elseif __scarletayuhuo_value_call(equip,"isKindOf","Weapon") then
				card = equip
				break
			elseif __scarletayuhuo_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(self.player) then
				card = equip
				break
			elseif __scarletayuhuo_value_call(equip,"isKindOf","Armor") and (not self:isWeak(self.player) or self:needToThrowArmor(self.player)) then
				card = equip
				break
			end
		end

		if card then
			if __scarletayuhuo_value_call(card,"isKindOf","Armor") or __scarletayuhuo_value_call(card,"isKindOf","DefensiveHorse") then
				self.friends = self:sort(self.friends, "defense")
			else
				self.friends = self:sort(self.friends, "handcard")
				self.friends = sgs.reverse(self.friends)
			end

			for _, friend in ipairs(self.friends) do
				if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName()
					and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
					target = friend
					break
				end
			end
			for _, friend in ipairs(self.friends) do
				if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName() then
					target = friend
					break
				end
			end
			if target then
				return target
			end
		end
	end
end



sgs.ai_skill_invoke.s3_jxwj_xianci = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end































function sgs.ai_cardneed.s_lotus_stick(to, card)
	return __scarletayuhuo_value_call(card,"isKindOf","Duel")
end

function sgs.ai_cardneed.s_fire_sword(to, card)
	return __scarletayuhuo_value_call(card,"isKindOf","FireSlash") or __scarletayuhuo_value_call(card,"isKindOf","ThunderSlash")
end


function sgs.ai_cardneed.s_biaoqi(to, card)
	return __scarletayuhuo_value_call(card,"isKindOf","Slash")
end

sgs.ai_skill_invoke.s_biaoqi = function(self, data)
	local damage = data:toDamage()
	if damage.to and self:isEnemy(damage.to) then
		return true
	end
	return false
end







































sgs.ai_skill_playerchosen.gzj_leishen = function(self, targets)
	local getCmpValue = function(enemy)
		local value = 0
		if not self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, player) then return 99 end
		if __scarletayuhuo_value_call(enemy,"hasSkill","hongyan") then
			return 99
		end
		if self:cantbeHurt(enemy, player, 3) or self:objectiveLevel(enemy) < 3
			or (enemy:isChained() and not self:isGoodChainTarget(enemy, player, sgs.DamageStruct_Thunder, 3)) then
			return 100
		end
		if not self:isGoodTarget(enemy, self.enemies, nil)  then value = value + 50 end
		if enemy:hasArmorEffect("silver_lion") then value = value + 20 end
		if enemy:hasSkills(sgs.exclusive_skill) then value = value + 10 end
		if enemy:hasSkills(sgs.masochism_skill) then value = value + 5 end
		if enemy:isChained() and self:isGoodChainTarget(enemy, player, sgs.DamageStruct_Thunder, 3) and #(self:getChainedEnemies(player)) > 1 then value =
			value - 25 end
		if __scarletayuhuo_value_call(enemy,"isLord") then value = value - 5 end
		value = value + __scarletayuhuo_value_call(enemy,"getHp") + self:getDefenseSlash(enemy) * 0.01
		return value
	end

	local cmp = function(a, b)
		return getCmpValue(a) < getCmpValue(b)
	end

	local enemies = self:getEnemies(player)
	table.sort(enemies, cmp)
	for _, enemy in ipairs(enemies) do
		if getCmpValue(enemy) < 100 then return enemy end
	end
	return nil
end


sgs.ai_playerchosen_intention.gzj_leishen = sgs.ai_playerchosen_intention.leiji


sgs.ai_slash_prohibit.gzj_leishen = function(self, from, to, card)
	local has_black_card = false
	for _, c in ipairs(sgs.QList2Table(to:getCards("he"))) do
		if __scarletayuhuo_value_call(c,"getSuit") == sgs.Card_Spade then
			has_black_card = true
		end
	end
	local hcard = __scarletayuhuo_value_call(to,"getHandcardNum")
	if self:isFriend(to, from) and has_black_card then return false end
	if __scarletayuhuo_value_call(to,"hasFlag","QianxiTarget") and (not self:hasEightDiagramEffect(to) or self.player:hasWeapon("qinggang_sword")) then return false end


	if viewer_role(self,from) == "rebel" and __scarletayuhuo_value_call(to,"isLord") then
		local other_rebel
		for _, player in sgs.qlist(self.room:getOtherPlayers(from)) do
			if known(self:getRoleEstimate(player),"role estimate") == "rebel" or self:compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				other_rebel = player
				break
			end
		end
		if not other_rebel and ((__scarletayuhuo_value_call(from,"getHp") >= 4 and (getCardsNum("Peach", from, self.player) > 0 or from:hasSkills("nosganglie|vsnosganglie"))) or __scarletayuhuo_value_call(from,"hasSkill","hongyan")) then
			return false
		end
	end

	if (self:hasSuit("spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if to:getTreasure() and to:getPile("wooden_ox"):length() > 1 then return true end
end

sgs.ai_skill_invoke.gzj_jiazi = function(self)
	if __scarletayuhuo_value_call(self.player,"hasFlag","DimengTarget") then
		local another
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if __scarletayuhuo_value_call(player,"hasFlag","DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_askforag.gzj_jiazi = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end




sgs.ai_skill_playerchosen.gzj_guifen = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if __scarletayuhuo_value_call(player,"isLord") then lord = player end
		if self:isEnemy(player) and (not target or __scarletayuhuo_value_call(target,"getHp") < __scarletayuhuo_value_call(player,"getHp")) then
			target = player
		end
	end
	if self.role == "rebel" and lord then return lord end
	if target then return target end
	targetlist = self:sort(targetlist, "hp")
	if viewer_role(self,self.player) == "loyalist" and __scarletayuhuo_value_call(targetlist[1],"isLord") then return targetlist[2] end
	return nil
end


sgs.ai_slash_prohibit.gzj_guifen = function(self, from, to)
	if __scarletayuhuo_value_call(from,"hasSkill","jueqing") then return false end
	if __scarletayuhuo_value_call(from,"hasFlag","NosJiefanUsed") then return false end
	local damageNum = self:hasHeavySlashDamage(from, nil, to, true)

	if self:isEnemy(to, from) and (__scarletayuhuo_value_call(to,"getHp") == 1 or self:isWeak(to)) then
		if not (#(self:getEnemies(from)) == 1 and #(self:getFriends(from)) + #(self:getEnemies(from)) == self.room:alivePlayerCount()) then
			return true
		end
	end
end


sgs.ai_skill_cardask["@gzj_tiandao-card"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("h")

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			all_cards:prepend(visible(self,id))
		end
	end

	if all_cards:isEmpty() then return "." end

	local needTokeep = __scarletayuhuo_value_call(judge.card,"getSuit") ~= sgs.Card_Spade and aoe_truth(self) and
	self:playerGetRound(judge.who) < self:playerGetRound(self.player)

	if not needTokeep then
		local who = judge.who
		if __scarletayuhuo_value_call(who,"getPhase") == sgs.Player_Judge and not who:getJudgingArea():isEmpty() and who:containsTrick("lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if __scarletayuhuo_value_call(self.player,"hasSkill","gzj_guifen") then keptspade = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not __scarletayuhuo_value_call(card,"hasFlag","using") then
			if __scarletayuhuo_value_call(card,"getSuit") == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptspade == 1 and not __scarletayuhuo_value_call(self.player,"hasSkill","gzj_guifen") then return "." end

	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			cards = self:sortByUseValue(cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(visible(self,card_id)) then
		local card = visible(self,card_id)
		return "$" .. card_id
	end

	return "."
end


function sgs.ai_cardneed.gzj_tiandao(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return __scarletayuhuo_value_call(card,"getSuit") == sgs.Card_Spade and __scarletayuhuo_value_call(card,"getNumber") >= 2 and __scarletayuhuo_value_call(card,"getNumber") <= 9 and
				not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return __scarletayuhuo_value_call(card,"getSuit") == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return __scarletayuhuo_value_call(card,"getSuit") == sgs.Card_Heart
			end
		end
	end
end

sgs.gzj_tiandao_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}
local function wrap(f,key,kind)
 return function(...)
  local args=table.pack(...);local self
  for i=1,args.n do local v=args[i];if type(v)=="table"and v.player and v.world and v.request then self=v;break end end
  if not self then return f(...)end
  local outer=not self._scarletayuhuo_callback_depth;local previous=self._scarletayuhuo_callback_key
  self._scarletayuhuo_callback_depth=(self._scarletayuhuo_callback_depth or 0)+1;self._scarletayuhuo_callback_key=key
  if outer then load_state(self)end
  if kind=="ai_skill_use_func"and classes[key]and args[1]and not recipes[args[1]]then recipes[args[1]]={prototype=key,skill=classes[key],subcards=copy(__scarletayuhuo_value_call(args[1],"getSubcards")),user=__scarletayuhuo_value_call(args[1],"getUserString")}end
  local result=table.pack(pcall(f,table.unpack(args,1,args.n)))
  local saved=outer and table.pack(pcall(save_state,self))or{true}
  self._scarletayuhuo_callback_depth=self._scarletayuhuo_callback_depth-1;if self._scarletayuhuo_callback_depth==0 then self._scarletayuhuo_callback_depth=nil end;self._scarletayuhuo_callback_key=previous
  if not result[1]then error(result[2],0)end
  if not saved[1]then error(saved[2],0)end
  if outer and kind=="ai_skill_use_func"and args[2]and args[2].card and recipes[args[2].card]and not recipes[args[2].card].prototype then
   local c=args[2].card;local row=copy(recipes[c]);row.source_key=nil;local mapped=self:evaluateTurnConversion(row.skill,c:getClassName(),row,nil);self:inheritLegacyCardIdentity(mapped,c);args[2].card=mapped
  elseif outer and kind=="ai_skill_use"then result[2]=response(self,result[2])
  elseif outer and(kind=="ai_cardsview"or kind=="ai_cardsview_valuable"or kind=="ai_guhuo_card")then result[2]=proposal(result[2])
  elseif outer and kind=="ai_fill_skill"and result[2]and recipes[result[2]]and not recipes[result[2]].prototype then
   local c=result[2];local row=copy(recipes[c]);row.source_key=nil
   local mapped=self:evaluateTurnConversion(row.skill,c:getClassName(),row,args[3]);self:inheritLegacyCardIdentity(mapped,c);result[2]=mapped
  end
  return table.unpack(result,2,result.n)
 end
end
sgs.ai_fill_skill['s_anren']=wrap(sgs.ai_fill_skill['s_anren'],'s_anren','ai_fill_skill')
sgs.ai_skill_use_func['#s_anren']=wrap(sgs.ai_skill_use_func['#s_anren'],'#s_anren','ai_skill_use_func')
sgs.ai_skill_invoke['s_nixing']=wrap(sgs.ai_skill_invoke['s_nixing'],'s_nixing','ai_skill_invoke')
sgs.ai_cardneed['s_wuqiang']=wrap(sgs.ai_cardneed['s_wuqiang'],'s_wuqiang','ai_cardneed')
sgs.ai_fill_skill['s_biaoqiSlash']=wrap(sgs.ai_fill_skill['s_biaoqiSlash'],'s_biaoqiSlash','ai_fill_skill')
sgs.ai_skill_use_func['#s_biaoqiSlash']=wrap(sgs.ai_skill_use_func['#s_biaoqiSlash'],'#s_biaoqiSlash','ai_skill_use_func')
sgs.ai_card_intention['#s_biaoqislash']=wrap(sgs.ai_card_intention['#s_biaoqislash'],'#s_biaoqislash','ai_card_intention')
sgs.ai_fill_skill['s_w_yongjin']=wrap(sgs.ai_fill_skill['s_w_yongjin'],'s_w_yongjin','ai_fill_skill')
do local f=sgs.ai_view_as['s_w_yongjin'];sgs.ai_view_as['s_w_yongjin']=function(...)return proposal(f(...))end end
sgs.ai_fill_skill['s_w_zhitui']=wrap(sgs.ai_fill_skill['s_w_zhitui'],'s_w_zhitui','ai_fill_skill')
do local f=sgs.ai_view_as['s_w_zhitui'];sgs.ai_view_as['s_w_zhitui']=function(...)return proposal(f(...))end end
sgs.ai_skill_choice['s_w_jianxiong']=wrap(sgs.ai_skill_choice['s_w_jianxiong'],'s_w_jianxiong','ai_skill_choice')
sgs.ai_target_revises['s_w_jianxiong']=wrap(sgs.ai_target_revises['s_w_jianxiong'],'s_w_jianxiong','ai_target_revises')
sgs.ai_can_damagehp['s_w_jianxiong']=wrap(sgs.ai_can_damagehp['s_w_jianxiong'],'s_w_jianxiong','ai_can_damagehp')
sgs.ai_skill_invoke['s_w_geran']=wrap(sgs.ai_skill_invoke['s_w_geran'],'s_w_geran','ai_skill_invoke')
sgs.ai_skill_invoke['s_w_qipao']=wrap(sgs.ai_skill_invoke['s_w_qipao'],'s_w_qipao','ai_skill_invoke')
sgs.ai_skill_cardask['#s_w_qipao']=wrap(sgs.ai_skill_cardask['#s_w_qipao'],'#s_w_qipao','ai_skill_cardask')
sgs.ai_fill_skill['s_w_wushuang']=wrap(sgs.ai_fill_skill['s_w_wushuang'],'s_w_wushuang','ai_fill_skill')
sgs.ai_card_priority['s_w_wushuang']=wrap(sgs.ai_card_priority['s_w_wushuang'],'s_w_wushuang','ai_card_priority')
sgs.ai_skill_discard['s_w_tongling']=wrap(sgs.ai_skill_discard['s_w_tongling'],'s_w_tongling','ai_skill_discard')
sgs.ai_skill_use['@@s_ling']=wrap(sgs.ai_skill_use['@@s_ling'],'@@s_ling','ai_skill_use')
sgs.ai_skill_discard['s_w_jiejiang_q']=wrap(sgs.ai_skill_discard['s_w_jiejiang_q'],'s_w_jiejiang_q','ai_skill_discard')
sgs.ai_cardneed['s_w_shenyong']=wrap(sgs.ai_cardneed['s_w_shenyong'],'s_w_shenyong','ai_cardneed')
sgs.ai_canliegong_skill['s_w_shenyong']=wrap(sgs.ai_canliegong_skill['s_w_shenyong'],'s_w_shenyong','ai_canliegong_skill')
sgs.ai_ajustdamage_from['s_w_nilin']=wrap(sgs.ai_ajustdamage_from['s_w_nilin'],'s_w_nilin','ai_ajustdamage_from')
sgs.ai_ajustdamage_to['s_w_juling']=wrap(sgs.ai_ajustdamage_to['s_w_juling'],'s_w_juling','ai_ajustdamage_to')
sgs.ai_skill_invoke['s_w_qimou_give']=wrap(sgs.ai_skill_invoke['s_w_qimou_give'],'s_w_qimou_give','ai_skill_invoke')
sgs.ai_skill_invoke['s_w_qimou']=wrap(sgs.ai_skill_invoke['s_w_qimou'],'s_w_qimou','ai_skill_invoke')
sgs.ai_fill_skill['s_w_qimou']=wrap(sgs.ai_fill_skill['s_w_qimou'],'s_w_qimou','ai_fill_skill')
sgs.ai_skill_use_func['#s_w_qimouCard']=wrap(sgs.ai_skill_use_func['#s_w_qimouCard'],'#s_w_qimouCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['s_w_qimou']=wrap(sgs.ai_skill_playerchosen['s_w_qimou'],'s_w_qimou','ai_skill_playerchosen')
sgs.ai_fill_skill['s_w_shenghun']=wrap(sgs.ai_fill_skill['s_w_shenghun'],'s_w_shenghun','ai_fill_skill')
sgs.ai_skill_use_func['#s_w_shenghun']=wrap(sgs.ai_skill_use_func['#s_w_shenghun'],'#s_w_shenghun','ai_skill_use_func')
sgs.ai_cardneed['s_w_shenghun']=wrap(sgs.ai_cardneed['s_w_shenghun'],'s_w_shenghun','ai_cardneed')
sgs.ai_skill_pindian['s_w_shenghun']=wrap(sgs.ai_skill_pindian['s_w_shenghun'],'s_w_shenghun','ai_skill_pindian')
sgs.ai_ajustdamage_from['s_w_wenjiu']=wrap(sgs.ai_ajustdamage_from['s_w_wenjiu'],'s_w_wenjiu','ai_ajustdamage_from')
sgs.ai_skill_invoke['s_w_juezhan_buqu']=wrap(sgs.ai_skill_invoke['s_w_juezhan_buqu'],'s_w_juezhan_buqu','ai_skill_invoke')
sgs.ai_skill_invoke['s_w_juezhan_tuxi']=wrap(sgs.ai_skill_invoke['s_w_juezhan_tuxi'],'s_w_juezhan_tuxi','ai_skill_invoke')
sgs.ai_skill_invoke['s_w_juezhan_wushuang1']=wrap(sgs.ai_skill_invoke['s_w_juezhan_wushuang1'],'s_w_juezhan_wushuang1','ai_skill_invoke')
sgs.ai_skill_invoke['s_w_juezhan_wushuang2']=wrap(sgs.ai_skill_invoke['s_w_juezhan_wushuang2'],'s_w_juezhan_wushuang2','ai_skill_invoke')
sgs.ai_skill_use['@@s_w_changshu']=wrap(sgs.ai_skill_use['@@s_w_changshu'],'@@s_w_changshu','ai_skill_use')
sgs.ai_cardneed['s_w_yuma']=wrap(sgs.ai_cardneed['s_w_yuma'],'s_w_yuma','ai_cardneed')
sgs.ai_cardsview['s_w_2_wenjiu']=wrap(sgs.ai_cardsview['s_w_2_wenjiu'],'s_w_2_wenjiu','ai_cardsview')
sgs.ai_fill_skill['s_w_2_wenjiu']=wrap(sgs.ai_fill_skill['s_w_2_wenjiu'],'s_w_2_wenjiu','ai_fill_skill')
sgs.ai_skill_invoke['s_w_shouyou']=wrap(sgs.ai_skill_invoke['s_w_shouyou'],'s_w_shouyou','ai_skill_invoke')
sgs.ai_skill_playerchosen['s_w_shenzi']=wrap(sgs.ai_skill_playerchosen['s_w_shenzi'],'s_w_shenzi','ai_skill_playerchosen')
sgs.ai_used_revises['s_w_wuqian']=wrap(sgs.ai_used_revises['s_w_wuqian'],'s_w_wuqian','ai_used_revises')
sgs.ai_fill_skill['s_w_wuqian']=wrap(sgs.ai_fill_skill['s_w_wuqian'],'s_w_wuqian','ai_fill_skill')
sgs.ai_skill_use_func['#s_w_wuqian']=wrap(sgs.ai_skill_use_func['#s_w_wuqian'],'#s_w_wuqian','ai_skill_use_func')
sgs.ai_use_revises['s_w_wumou']=wrap(sgs.ai_use_revises['s_w_wumou'],'s_w_wumou','ai_use_revises')
sgs.ai_skill_choice['s_w_wumou']=wrap(sgs.ai_skill_choice['s_w_wumou'],'s_w_wumou','ai_skill_choice')
sgs.ai_skill_discard['s_w_guishen']=wrap(sgs.ai_skill_discard['s_w_guishen'],'s_w_guishen','ai_skill_discard')
sgs.ai_skill_choice['s_w_youhuo']=wrap(sgs.ai_skill_choice['s_w_youhuo'],'s_w_youhuo','ai_skill_choice')
sgs.ai_skill_playerchosen['s_w_juese']=wrap(sgs.ai_skill_playerchosen['s_w_juese'],'s_w_juese','ai_skill_playerchosen')
sgs.ai_skill_invoke['s_w_yanzi']=wrap(sgs.ai_skill_invoke['s_w_yanzi'],'s_w_yanzi','ai_skill_invoke')
sgs.ai_skill_choice['s_w_yanzi_disMark']=wrap(sgs.ai_skill_choice['s_w_yanzi_disMark'],'s_w_yanzi_disMark','ai_skill_choice')
sgs.ai_skill_choice['s_w_yanzi_in_de']=wrap(sgs.ai_skill_choice['s_w_yanzi_in_de'],'s_w_yanzi_in_de','ai_skill_choice')
sgs.ai_fill_skill['s2_longhun']=wrap(sgs.ai_fill_skill['s2_longhun'],'s2_longhun','ai_fill_skill')
sgs.ai_skill_use_func['#s2_longhun']=wrap(sgs.ai_skill_use_func['#s2_longhun'],'#s2_longhun','ai_skill_use_func')
do local f=sgs.ai_view_as['s2_longhun'];sgs.ai_view_as['s2_longhun']=function(...)return proposal(f(...))end end
sgs.ai_cardneed['s2_longhun']=wrap(sgs.ai_cardneed['s2_longhun'],'s2_longhun','ai_cardneed')
sgs.ai_getBestHp_skill['s2_longhun']=wrap(sgs.ai_getBestHp_skill['s2_longhun'],'s2_longhun','ai_getBestHp_skill')
sgs.ai_skill_playerchosen['s2_juejing']=wrap(sgs.ai_skill_playerchosen['s2_juejing'],'s2_juejing','ai_skill_playerchosen')
sgs.ai_skill_cardchosen['s2_juejing']=wrap(sgs.ai_skill_cardchosen['s2_juejing'],'s2_juejing','ai_skill_cardchosen')
sgs.ai_fill_skill['s2_duanzui']=wrap(sgs.ai_fill_skill['s2_duanzui'],'s2_duanzui','ai_fill_skill')
sgs.ai_skill_use_func['#s2_duanzui']=wrap(sgs.ai_skill_use_func['#s2_duanzui'],'#s2_duanzui','ai_skill_use_func')
sgs.ai_fill_skill['s2_shenpan']=wrap(sgs.ai_fill_skill['s2_shenpan'],'s2_shenpan','ai_fill_skill')
sgs.ai_skill_use_func['#s2_shenpan']=wrap(sgs.ai_skill_use_func['#s2_shenpan'],'#s2_shenpan','ai_skill_use_func')
sgs.ai_cardneed['s2_chengwu']=wrap(sgs.ai_cardneed['s2_chengwu'],'s2_chengwu','ai_cardneed')
sgs.ai_ajustdamage_from['s2_chengwu']=wrap(sgs.ai_ajustdamage_from['s2_chengwu'],'s2_chengwu','ai_ajustdamage_from')
sgs.ai_need_damaged['s2_huzi']=wrap(sgs.ai_need_damaged['s2_huzi'],'s2_huzi','ai_need_damaged')
sgs.ai_skill_invoke['s2_touben_wei']=wrap(sgs.ai_skill_invoke['s2_touben_wei'],'s2_touben_wei','ai_skill_invoke')
sgs.ai_skill_invoke['s2_touben_wu']=wrap(sgs.ai_skill_invoke['s2_touben_wu'],'s2_touben_wu','ai_skill_invoke')
sgs.ai_skill_playerchosen['s2_nixi']=wrap(sgs.ai_skill_playerchosen['s2_nixi'],'s2_nixi','ai_skill_playerchosen')
sgs.ai_fill_skill['s2_jiange']=wrap(sgs.ai_fill_skill['s2_jiange'],'s2_jiange','ai_fill_skill')
sgs.ai_skill_use_func['#s2_jiange']=wrap(sgs.ai_skill_use_func['#s2_jiange'],'#s2_jiange','ai_skill_use_func')
sgs.ai_skill_invoke['s2_jiange_obtain']=wrap(sgs.ai_skill_invoke['s2_jiange_obtain'],'s2_jiange_obtain','ai_skill_invoke')
sgs.ai_skill_askforag['s2_jiange']=wrap(sgs.ai_skill_askforag['s2_jiange'],'s2_jiange','ai_skill_askforag')
sgs.ai_skill_cardask['@s2_jiange_add']=wrap(sgs.ai_skill_cardask['@s2_jiange_add'],'@s2_jiange_add','ai_skill_cardask')
sgs.ai_skill_invoke['s2_wuhun']=wrap(sgs.ai_skill_invoke['s2_wuhun'],'s2_wuhun','ai_skill_invoke')
do local f=sgs.ai_view_as['s2_wuhun'];sgs.ai_view_as['s2_wuhun']=function(...)return proposal(f(...))end end
sgs.ai_fill_skill['s2_wuhun']=wrap(sgs.ai_fill_skill['s2_wuhun'],'s2_wuhun','ai_fill_skill')
sgs.ai_cardneed['s2_wuhun']=wrap(sgs.ai_cardneed['s2_wuhun'],'s2_wuhun','ai_cardneed')
sgs.ai_skill_use['@@s2_wushen']=wrap(sgs.ai_skill_use['@@s2_wushen'],'@@s2_wushen','ai_skill_use')
sgs.ai_skill_invoke['s2_gn_nixi']=wrap(sgs.ai_skill_invoke['s2_gn_nixi'],'s2_gn_nixi','ai_skill_invoke')
sgs.ai_fill_skill['s2_gn_nixi']=wrap(sgs.ai_fill_skill['s2_gn_nixi'],'s2_gn_nixi','ai_fill_skill')
sgs.ai_cardneed['s2_gn_nixi']=wrap(sgs.ai_cardneed['s2_gn_nixi'],'s2_gn_nixi','ai_cardneed')
sgs.ai_skill_cardask['@s2_guanhui-card']=wrap(sgs.ai_skill_cardask['@s2_guanhui-card'],'@s2_guanhui-card','ai_skill_cardask')
sgs.ai_skill_askforag['s2_guanhui']=wrap(sgs.ai_skill_askforag['s2_guanhui'],'s2_guanhui','ai_skill_askforag')
sgs.ai_skill_discard['s2_duanya']=wrap(sgs.ai_skill_discard['s2_duanya'],'s2_duanya','ai_skill_discard')
sgs.ai_skill_use['@@s2_houqi']=wrap(sgs.ai_skill_use['@@s2_houqi'],'@@s2_houqi','ai_skill_use')
sgs.ai_skill_invoke['s2_yongbing']=wrap(sgs.ai_skill_invoke['s2_yongbing'],'s2_yongbing','ai_skill_invoke')
sgs.ai_skill_choice['s2_lixian']=wrap(sgs.ai_skill_choice['s2_lixian'],'s2_lixian','ai_skill_choice')
sgs.ai_skill_playerchosen['s2_lixian']=wrap(sgs.ai_skill_playerchosen['s2_lixian'],'s2_lixian','ai_skill_playerchosen')
sgs.ai_armor_value['s2_jianzu']=wrap(sgs.ai_armor_value['s2_jianzu'],'s2_jianzu','ai_armor_value')
sgs.ai_use_revises['s2_jianzu']=wrap(sgs.ai_use_revises['s2_jianzu'],'s2_jianzu','ai_use_revises')
sgs.ai_cardneed['s2_jianzu']=wrap(sgs.ai_cardneed['s2_jianzu'],'s2_jianzu','ai_cardneed')
sgs.ai_ajustdamage_from['s2_shengjian']=wrap(sgs.ai_ajustdamage_from['s2_shengjian'],'s2_shengjian','ai_ajustdamage_from')
sgs.ai_skill_invoke['s2_zhengyi']=wrap(sgs.ai_skill_invoke['s2_zhengyi'],'s2_zhengyi','ai_skill_invoke')
sgs.ai_fill_skill['s2_guimou']=wrap(sgs.ai_fill_skill['s2_guimou'],'s2_guimou','ai_fill_skill')
sgs.ai_skill_playerchosen['s2_huandou']=wrap(sgs.ai_skill_playerchosen['s2_huandou'],'s2_huandou','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['s2_xingyi']=wrap(sgs.ai_skill_playerchosen['s2_xingyi'],'s2_xingyi','ai_skill_playerchosen')
sgs.ai_skill_choice['s2_xingyi']=wrap(sgs.ai_skill_choice['s2_xingyi'],'s2_xingyi','ai_skill_choice')
sgs.ai_fill_skill['s2_yizei']=wrap(sgs.ai_fill_skill['s2_yizei'],'s2_yizei','ai_fill_skill')
sgs.ai_skill_use_func['#s2_yizei']=wrap(sgs.ai_skill_use_func['#s2_yizei'],'#s2_yizei','ai_skill_use_func')
sgs.ai_fill_skill['s2_zhanjiang']=wrap(sgs.ai_fill_skill['s2_zhanjiang'],'s2_zhanjiang','ai_fill_skill')
sgs.ai_skill_use_func['#s2_zhanjiang']=wrap(sgs.ai_skill_use_func['#s2_zhanjiang'],'#s2_zhanjiang','ai_skill_use_func')
sgs.ai_slash_prohibit['s2_hungui']=wrap(sgs.ai_slash_prohibit['s2_hungui'],'s2_hungui','ai_slash_prohibit')
sgs.ai_target_revises['s2_changsheng']=wrap(sgs.ai_target_revises['s2_changsheng'],'s2_changsheng','ai_target_revises')
sgs.ai_cardneed['s2_changsheng']=wrap(sgs.ai_cardneed['s2_changsheng'],'s2_changsheng','ai_cardneed')
sgs.ai_skill_invoke['s2_danqi']=wrap(sgs.ai_skill_invoke['s2_danqi'],'s2_danqi','ai_skill_invoke')
sgs.ai_ajustdamage_from['s2_danqi']=wrap(sgs.ai_ajustdamage_from['s2_danqi'],'s2_danqi','ai_ajustdamage_from')
sgs.ai_skill_invoke['s2_tianjiang']=wrap(sgs.ai_skill_invoke['s2_tianjiang'],'s2_tianjiang','ai_skill_invoke')
sgs.ai_ajustdamage_from['s2_tianjiang']=wrap(sgs.ai_ajustdamage_from['s2_tianjiang'],'s2_tianjiang','ai_ajustdamage_from')
sgs.ai_ajustdamage_from['s2_tieji']=wrap(sgs.ai_ajustdamage_from['s2_tieji'],'s2_tieji','ai_ajustdamage_from')
sgs.ai_skill_playerchosen['s2_haojiu']=wrap(sgs.ai_skill_playerchosen['s2_haojiu'],'s2_haojiu','ai_skill_playerchosen')
sgs.ai_skill_choice['s2_haojiu']=wrap(sgs.ai_skill_choice['s2_haojiu'],'s2_haojiu','ai_skill_choice')
sgs.ai_skill_cardask['@s2_nuhou-give']=wrap(sgs.ai_skill_cardask['@s2_nuhou-give'],'@s2_nuhou-give','ai_skill_cardask')
sgs.ai_target_revises['s2_nuhou']=wrap(sgs.ai_target_revises['s2_nuhou'],'s2_nuhou','ai_target_revises')
sgs.ai_fill_skill['s2_shanqi']=wrap(sgs.ai_fill_skill['s2_shanqi'],'s2_shanqi','ai_fill_skill')
sgs.ai_skill_use_func['#s2_shanqi']=wrap(sgs.ai_skill_use_func['#s2_shanqi'],'#s2_shanqi','ai_skill_use_func')
sgs.ai_skill_choice['s2_shanqi']=wrap(sgs.ai_skill_choice['s2_shanqi'],'s2_shanqi','ai_skill_choice')
sgs.ai_canliegong_skill['s2_baibu']=wrap(sgs.ai_canliegong_skill['s2_baibu'],'s2_baibu','ai_canliegong_skill')
sgs.ai_fill_skill['s2_longwei']=wrap(sgs.ai_fill_skill['s2_longwei'],'s2_longwei','ai_fill_skill')
sgs.ai_skill_use_func['#s2_longwei_select']=wrap(sgs.ai_skill_use_func['#s2_longwei_select'],'#s2_longwei_select','ai_skill_use_func')
sgs.ai_skill_choice['s2_longwei-new-choicetype']=wrap(sgs.ai_skill_choice['s2_longwei-new-choicetype'],'s2_longwei-new-choicetype','ai_skill_choice')
sgs.ai_skill_choice['s2_longwei']=wrap(sgs.ai_skill_choice['s2_longwei'],'s2_longwei','ai_skill_choice')
sgs.ai_skill_use['@@s2_longwei']=wrap(sgs.ai_skill_use['@@s2_longwei'],'@@s2_longwei','ai_skill_use')
sgs.ai_cardsview_valuable['s2_longwei']=wrap(sgs.ai_cardsview_valuable['s2_longwei'],'s2_longwei','ai_cardsview_valuable')
sgs.ai_skill_invoke['s2_tuxi']=wrap(sgs.ai_skill_invoke['s2_tuxi'],'s2_tuxi','ai_skill_invoke')
sgs.ai_need_damaged['s2_wuwei']=wrap(sgs.ai_need_damaged['s2_wuwei'],'s2_wuwei','ai_need_damaged')
sgs.ai_skill_playerchosen['s2_muyi']=wrap(sgs.ai_skill_playerchosen['s2_muyi'],'s2_muyi','ai_skill_playerchosen')
sgs.ai_skill_choice['s2_muyi']=wrap(sgs.ai_skill_choice['s2_muyi'],'s2_muyi','ai_skill_choice')
sgs.ai_skill_invoke['s2_yaowu']=wrap(sgs.ai_skill_invoke['s2_yaowu'],'s2_yaowu','ai_skill_invoke')
sgs.ai_fill_skill['s2_bayeVS']=wrap(sgs.ai_fill_skill['s2_bayeVS'],'s2_bayeVS','ai_fill_skill')
sgs.ai_skill_use_func['#s2_bayeCard']=wrap(sgs.ai_skill_use_func['#s2_bayeCard'],'#s2_bayeCard','ai_skill_use_func')
sgs.ai_card_intention['s2_bayeCard']=wrap(sgs.ai_card_intention['s2_bayeCard'],'s2_bayeCard','ai_card_intention')
sgs.ai_skill_invoke['s2_fanji']=wrap(sgs.ai_skill_invoke['s2_fanji'],'s2_fanji','ai_skill_invoke')
do local f=sgs.ai_view_as['s2_fenzhan'];sgs.ai_view_as['s2_fenzhan']=function(...)return proposal(f(...))end end
sgs.ai_skill_invoke['s2_maifu']=wrap(sgs.ai_skill_invoke['s2_maifu'],'s2_maifu','ai_skill_invoke')
sgs.ai_skill_playerchosen['s2_maifu']=wrap(sgs.ai_skill_playerchosen['s2_maifu'],'s2_maifu','ai_skill_playerchosen')
sgs.ai_skill_choice['s2_maifu']=wrap(sgs.ai_skill_choice['s2_maifu'],'s2_maifu','ai_skill_choice')
sgs.ai_skill_invoke['s2_shuangdao']=wrap(sgs.ai_skill_invoke['s2_shuangdao'],'s2_shuangdao','ai_skill_invoke')
sgs.ai_skill_playerchosen['s2_huzhu']=wrap(sgs.ai_skill_playerchosen['s2_huzhu'],'s2_huzhu','ai_skill_playerchosen')
sgs.ai_skill_defense['@s2_huzhu']=wrap(sgs.ai_skill_defense['@s2_huzhu'],'@s2_huzhu','ai_skill_defense')
sgs.ai_skill_playerchosen['s2_xiaoguo']=wrap(sgs.ai_skill_playerchosen['s2_xiaoguo'],'s2_xiaoguo','ai_skill_playerchosen')
sgs.ai_skill_cardask['s2_xiaoguo']=wrap(sgs.ai_skill_cardask['s2_xiaoguo'],'s2_xiaoguo','ai_skill_cardask')
sgs.ai_fill_skill['s2_xiaoguo']=wrap(sgs.ai_fill_skill['s2_xiaoguo'],'s2_xiaoguo','ai_fill_skill')
sgs.ai_skill_use_func['#s2_xiaoguo']=wrap(sgs.ai_skill_use_func['#s2_xiaoguo'],'#s2_xiaoguo','ai_skill_use_func')
sgs.ai_fill_skill['s2_xiande']=wrap(sgs.ai_fill_skill['s2_xiande'],'s2_xiande','ai_fill_skill')
sgs.ai_skill_use_func['#s2_xiande']=wrap(sgs.ai_skill_use_func['#s2_xiande'],'#s2_xiande','ai_skill_use_func')
sgs.ai_skill_cardask['s2_xiande']=wrap(sgs.ai_skill_cardask['s2_xiande'],'s2_xiande','ai_skill_cardask')
sgs.ai_skill_playerchosen['s2_xiande_draw']=wrap(sgs.ai_skill_playerchosen['s2_xiande_draw'],'s2_xiande_draw','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['s2_xiande_recover']=wrap(sgs.ai_skill_playerchosen['s2_xiande_recover'],'s2_xiande_recover','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['s2_toujing']=wrap(sgs.ai_skill_playerchosen['s2_toujing'],'s2_toujing','ai_skill_playerchosen')
sgs.ai_skill_invoke['s2_tujin']=wrap(sgs.ai_skill_invoke['s2_tujin'],'s2_tujin','ai_skill_invoke')
sgs.ai_skill_playerchosen['s2_tujin']=wrap(sgs.ai_skill_playerchosen['s2_tujin'],'s2_tujin','ai_skill_playerchosen')
sgs.ai_skill_choice['s2_zhenyan_draw']=wrap(sgs.ai_skill_choice['s2_zhenyan_draw'],'s2_zhenyan_draw','ai_skill_choice')
sgs.ai_skill_playerchosen['s2_zhenyan']=wrap(sgs.ai_skill_playerchosen['s2_zhenyan'],'s2_zhenyan','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['s2_zhenyan']=wrap(sgs.ai_playerchosen_intention['s2_zhenyan'],'s2_zhenyan','ai_playerchosen_intention')
sgs.ai_skill_askforag['s2_zhenyan']=wrap(sgs.ai_skill_askforag['s2_zhenyan'],'s2_zhenyan','ai_skill_askforag')
sgs.ai_skill_invoke['s2_boxing']=wrap(sgs.ai_skill_invoke['s2_boxing'],'s2_boxing','ai_skill_invoke')
sgs.ai_skill_playerchosen['s2_boxing']=wrap(sgs.ai_skill_playerchosen['s2_boxing'],'s2_boxing','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['s2_boxing']=wrap(sgs.ai_playerchosen_intention['s2_boxing'],'s2_boxing','ai_playerchosen_intention')
sgs.ai_fill_skill['s2_jinchi']=wrap(sgs.ai_fill_skill['s2_jinchi'],'s2_jinchi','ai_fill_skill')
sgs.ai_skill_use_func['#s2_jinchi']=wrap(sgs.ai_skill_use_func['#s2_jinchi'],'#s2_jinchi','ai_skill_use_func')
sgs.ai_skill_playerchosen['s2_jinchi']=wrap(sgs.ai_skill_playerchosen['s2_jinchi'],'s2_jinchi','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['s2_jinchi']=wrap(sgs.ai_playerchosen_intention['s2_jinchi'],'s2_jinchi','ai_playerchosen_intention')
do local f=sgs.ai_view_as['s2_douba'];sgs.ai_view_as['s2_douba']=function(...)return proposal(f(...))end end
sgs.ai_fill_skill['s2_douba']=wrap(sgs.ai_fill_skill['s2_douba'],'s2_douba','ai_fill_skill')
sgs.ai_fill_skill['s2_zhanpo']=wrap(sgs.ai_fill_skill['s2_zhanpo'],'s2_zhanpo','ai_fill_skill')
sgs.ai_skill_use_func['#s2_zhanpo']=wrap(sgs.ai_skill_use_func['#s2_zhanpo'],'#s2_zhanpo','ai_skill_use_func')
sgs.ai_skill_playerchosen['s2_zhanpo']=wrap(sgs.ai_skill_playerchosen['s2_zhanpo'],'s2_zhanpo','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['s2_zhanpo']=wrap(sgs.ai_playerchosen_intention['s2_zhanpo'],'s2_zhanpo','ai_playerchosen_intention')
sgs.ai_skill_invoke['s2_taoni']=wrap(sgs.ai_skill_invoke['s2_taoni'],'s2_taoni','ai_skill_invoke')
sgs.ai_skill_discard['s2_jubing']=wrap(sgs.ai_skill_discard['s2_jubing'],'s2_jubing','ai_skill_discard')
sgs.ai_skill_playerchosen['s2_jubing']=wrap(sgs.ai_skill_playerchosen['s2_jubing'],'s2_jubing','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['s2_jubing']=wrap(sgs.ai_playerchosen_intention['s2_jubing'],'s2_jubing','ai_playerchosen_intention')
sgs.ai_skill_playerchosen['s2_budai']=wrap(sgs.ai_skill_playerchosen['s2_budai'],'s2_budai','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['s2_budai']=wrap(sgs.ai_playerchosen_intention['s2_budai'],'s2_budai','ai_playerchosen_intention')
sgs.ai_skill_invoke['s2_bashi']=wrap(sgs.ai_skill_invoke['s2_bashi'],'s2_bashi','ai_skill_invoke')
sgs.ai_fill_skill['s2_danjing']=wrap(sgs.ai_fill_skill['s2_danjing'],'s2_danjing','ai_fill_skill')
sgs.ai_skill_use_func['#s2_danjing']=wrap(sgs.ai_skill_use_func['#s2_danjing'],'#s2_danjing','ai_skill_use_func')
sgs.ai_skill_playerchosen['s2_danjing']=wrap(sgs.ai_skill_playerchosen['s2_danjing'],'s2_danjing','ai_skill_playerchosen')
sgs.ai_getBestHp_skill['s2_tuwei']=wrap(sgs.ai_getBestHp_skill['s2_tuwei'],'s2_tuwei','ai_getBestHp_skill')
sgs.ai_fill_skill['s2_leiyin']=wrap(sgs.ai_fill_skill['s2_leiyin'],'s2_leiyin','ai_fill_skill')
sgs.ai_skill_use_func['#s2_leiyin']=wrap(sgs.ai_skill_use_func['#s2_leiyin'],'#s2_leiyin','ai_skill_use_func')
sgs.ai_skill_pindian['s2_leiyin']=wrap(sgs.ai_skill_pindian['s2_leiyin'],'s2_leiyin','ai_skill_pindian')
do local f=sgs.ai_view_as['s2_yezhan'];sgs.ai_view_as['s2_yezhan']=function(...)return proposal(f(...))end end
sgs.ai_fill_skill['s2_yezhan']=wrap(sgs.ai_fill_skill['s2_yezhan'],'s2_yezhan','ai_fill_skill')
sgs.ai_ajustdamage_from['s2_shenwei']=wrap(sgs.ai_ajustdamage_from['s2_shenwei'],'s2_shenwei','ai_ajustdamage_from')
sgs.ai_cardneed['s2_yezhan']=wrap(sgs.ai_cardneed['s2_yezhan'],'s2_yezhan','ai_cardneed')
sgs.ai_skill_invoke['s2_yizhan']=wrap(sgs.ai_skill_invoke['s2_yizhan'],'s2_yizhan','ai_skill_invoke')
sgs.ai_use_revises['s2_chuanyang']=wrap(sgs.ai_use_revises['s2_chuanyang'],'s2_chuanyang','ai_use_revises')
sgs.ai_can_damagehp['s2_guimou_2']=wrap(sgs.ai_can_damagehp['s2_guimou_2'],'s2_guimou_2','ai_can_damagehp')
sgs.ai_skill_use['@@s2_andu']=wrap(sgs.ai_skill_use['@@s2_andu'],'@@s2_andu','ai_skill_use')
sgs.ai_skill_invoke['s2_shemi']=wrap(sgs.ai_skill_invoke['s2_shemi'],'s2_shemi','ai_skill_invoke')
sgs.ai_skill_invoke['s2_jiujia']=wrap(sgs.ai_skill_invoke['s2_jiujia'],'s2_jiujia','ai_skill_invoke')
sgs.ai_skill_invoke['s2_feijun']=wrap(sgs.ai_skill_invoke['s2_feijun'],'s2_feijun','ai_skill_invoke')
sgs.ai_skill_pindian['s2_feijun']=wrap(sgs.ai_skill_pindian['s2_feijun'],'s2_feijun','ai_skill_pindian')
sgs.ai_fill_skill['s2_chizha']=wrap(sgs.ai_fill_skill['s2_chizha'],'s2_chizha','ai_fill_skill')
sgs.ai_skill_use_func['#s2_chizha']=wrap(sgs.ai_skill_use_func['#s2_chizha'],'#s2_chizha','ai_skill_use_func')
sgs.ai_skill_invoke['s2_chizha']=wrap(sgs.ai_skill_invoke['s2_chizha'],'s2_chizha','ai_skill_invoke')
sgs.ai_need_damaged['s2_hengjiang']=wrap(sgs.ai_need_damaged['s2_hengjiang'],'s2_hengjiang','ai_need_damaged')
sgs.ai_skill_cardask['@s2_jizhan-exchange']=wrap(sgs.ai_skill_cardask['@s2_jizhan-exchange'],'@s2_jizhan-exchange','ai_skill_cardask')
sgs.ai_fill_skill['s2_xubian']=wrap(sgs.ai_fill_skill['s2_xubian'],'s2_xubian','ai_fill_skill')
sgs.ai_skill_use_func['#s2_xubian']=wrap(sgs.ai_skill_use_func['#s2_xubian'],'#s2_xubian','ai_skill_use_func')
sgs.ai_fill_skill['s2_qingfa']=wrap(sgs.ai_fill_skill['s2_qingfa'],'s2_qingfa','ai_fill_skill')
do local f=sgs.ai_view_as['s2_xubian'];sgs.ai_view_as['s2_xubian']=function(...)return proposal(f(...))end end
sgs.ai_skill_playerchosen['s2_guijin']=wrap(sgs.ai_skill_playerchosen['s2_guijin'],'s2_guijin','ai_skill_playerchosen')
sgs.ai_use_revises['s2_guijin']=wrap(sgs.ai_use_revises['s2_guijin'],'s2_guijin','ai_use_revises')
sgs.ai_skill_use['@@s2_qiangrang']=wrap(sgs.ai_skill_use['@@s2_qiangrang'],'@@s2_qiangrang','ai_skill_use')
sgs.ai_ajustdamage_from['s2_mieshi']=wrap(sgs.ai_ajustdamage_from['s2_mieshi'],'s2_mieshi','ai_ajustdamage_from')
sgs.ai_skill_use['@@s2_mieshi']=wrap(sgs.ai_skill_use['@@s2_mieshi'],'@@s2_mieshi','ai_skill_use')
sgs.ai_skill_use['@@s2_zhonghun']=wrap(sgs.ai_skill_use['@@s2_zhonghun'],'@@s2_zhonghun','ai_skill_use')
sgs.ai_skill_invoke['s2_zhonghun']=wrap(sgs.ai_skill_invoke['s2_zhonghun'],'s2_zhonghun','ai_skill_invoke')
sgs.ai_skill_discard['s2_duanjia']=wrap(sgs.ai_skill_discard['s2_duanjia'],'s2_duanjia','ai_skill_discard')
sgs.ai_fill_skill['s2_tiantan']=wrap(sgs.ai_fill_skill['s2_tiantan'],'s2_tiantan','ai_fill_skill')
sgs.ai_skill_use_func['#s2_tiantan']=wrap(sgs.ai_skill_use_func['#s2_tiantan'],'#s2_tiantan','ai_skill_use_func')
sgs.ai_fill_skill['s2_yinyang']=wrap(sgs.ai_fill_skill['s2_yinyang'],'s2_yinyang','ai_fill_skill')
sgs.ai_skill_use_func['#s2_yinyang']=wrap(sgs.ai_skill_use_func['#s2_yinyang'],'#s2_yinyang','ai_skill_use_func')
sgs.ai_skill_use['@@s2_danmu']=wrap(sgs.ai_skill_use['@@s2_danmu'],'@@s2_danmu','ai_skill_use')
sgs.ai_skill_playerchosen['s2_saiqian']=wrap(sgs.ai_skill_playerchosen['s2_saiqian'],'s2_saiqian','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['s2_saiqian']=wrap(sgs.ai_playerchosen_intention['s2_saiqian'],'s2_saiqian','ai_playerchosen_intention')
sgs.ai_skill_cardask['@s2_saiqian']=wrap(sgs.ai_skill_cardask['@s2_saiqian'],'@s2_saiqian','ai_skill_cardask')
sgs.ai_ajustdamage_to['s2_hufu']=wrap(sgs.ai_ajustdamage_to['s2_hufu'],'s2_hufu','ai_ajustdamage_to')
sgs.ai_fill_skill['s2_2_zhanjiang']=wrap(sgs.ai_fill_skill['s2_2_zhanjiang'],'s2_2_zhanjiang','ai_fill_skill')
sgs.ai_skill_use_func['#s2_2_zhanjiang']=wrap(sgs.ai_skill_use_func['#s2_2_zhanjiang'],'#s2_2_zhanjiang','ai_skill_use_func')
sgs.ai_cardneed['s2_2_zhanjiang']=wrap(sgs.ai_cardneed['s2_2_zhanjiang'],'s2_2_zhanjiang','ai_cardneed')
sgs.ai_skill_invoke['s2_2_huzi']=wrap(sgs.ai_skill_invoke['s2_2_huzi'],'s2_2_huzi','ai_skill_invoke')
sgs.ai_ajustdamage_from['s2_2_huzi']=wrap(sgs.ai_ajustdamage_from['s2_2_huzi'],'s2_2_huzi','ai_ajustdamage_from')
sgs.ai_use_revises['s3_weihezhe']=wrap(sgs.ai_use_revises['s3_weihezhe'],'s3_weihezhe','ai_use_revises')
sgs.ai_ajustdamage_from['s3_weihezhe']=wrap(sgs.ai_ajustdamage_from['s3_weihezhe'],'s3_weihezhe','ai_ajustdamage_from')
sgs.ai_skill_invoke['s3_shenqiangshou']=wrap(sgs.ai_skill_invoke['s3_shenqiangshou'],'s3_shenqiangshou','ai_skill_invoke')
sgs.ai_skill_choice['s3_shenqiangshou']=wrap(sgs.ai_skill_choice['s3_shenqiangshou'],'s3_shenqiangshou','ai_skill_choice')
sgs.ai_skill_discard['s3_zhuhai']=wrap(sgs.ai_skill_discard['s3_zhuhai'],'s3_zhuhai','ai_skill_discard')
sgs.ai_skill_choice['s3_zhuhai']=wrap(sgs.ai_skill_choice['s3_zhuhai'],'s3_zhuhai','ai_skill_choice')
sgs.ai_fill_skill['s3_jianyan']=wrap(sgs.ai_fill_skill['s3_jianyan'],'s3_jianyan','ai_fill_skill')
sgs.ai_skill_use_func['#s3_jianyan']=wrap(sgs.ai_skill_use_func['#s3_jianyan'],'#s3_jianyan','ai_skill_use_func')
sgs.ai_skill_choice['s3_binglu']=wrap(sgs.ai_skill_choice['s3_binglu'],'s3_binglu','ai_skill_choice')
sgs.ai_skill_discard['s3_binglu']=wrap(sgs.ai_skill_discard['s3_binglu'],'s3_binglu','ai_skill_discard')
sgs.ai_skill_invoke['s3_zhijue']=wrap(sgs.ai_skill_invoke['s3_zhijue'],'s3_zhijue','ai_skill_invoke')
sgs.ai_can_damagehp['s3_zhijue']=wrap(sgs.ai_can_damagehp['s3_zhijue'],'s3_zhijue','ai_can_damagehp')
sgs.ai_skill_invoke['s3_lianzhan']=wrap(sgs.ai_skill_invoke['s3_lianzhan'],'s3_lianzhan','ai_skill_invoke')
sgs.ai_skill_invoke['s3_qiangyuan']=wrap(sgs.ai_skill_invoke['s3_qiangyuan'],'s3_qiangyuan','ai_skill_invoke')
sgs.ai_skill_use['@@s3_qiangyuan']=wrap(sgs.ai_skill_use['@@s3_qiangyuan'],'@@s3_qiangyuan','ai_skill_use')
sgs.ai_fill_skill['s3_youlong']=wrap(sgs.ai_fill_skill['s3_youlong'],'s3_youlong','ai_fill_skill')
do local f=sgs.ai_view_as['s3_youlong'];sgs.ai_view_as['s3_youlong']=function(...)return proposal(f(...))end end
sgs.ai_skill_invoke['s3_youlong']=wrap(sgs.ai_skill_invoke['s3_youlong'],'s3_youlong','ai_skill_invoke')
sgs.ai_slash_prohibit['s3_youlong']=wrap(sgs.ai_slash_prohibit['s3_youlong'],'s3_youlong','ai_slash_prohibit')
sgs.ai_skill_discard['s3_youlong']=wrap(sgs.ai_skill_discard['s3_youlong'],'s3_youlong','ai_skill_discard')
sgs.ai_card_priority['s3_youlong']=wrap(sgs.ai_card_priority['s3_youlong'],'s3_youlong','ai_card_priority')
sgs.ai_skill_playerchosen['s3_kangdao']=wrap(sgs.ai_skill_playerchosen['s3_kangdao'],'s3_kangdao','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['s3_kangdao_target']=wrap(sgs.ai_skill_playerchosen['s3_kangdao_target'],'s3_kangdao_target','ai_skill_playerchosen')
sgs.ai_skill_use['@@s3_qiane']=wrap(sgs.ai_skill_use['@@s3_qiane'],'@@s3_qiane','ai_skill_use')
sgs.ai_fill_skill['s3_fenzhi']=wrap(sgs.ai_fill_skill['s3_fenzhi'],'s3_fenzhi','ai_fill_skill')
sgs.ai_skill_use_func['#s3_fenzhi']=wrap(sgs.ai_skill_use_func['#s3_fenzhi'],'#s3_fenzhi','ai_skill_use_func')
sgs.ai_skill_choice['s3_fenzhi']=wrap(sgs.ai_skill_choice['s3_fenzhi'],'s3_fenzhi','ai_skill_choice')
sgs.ai_hasTuntianEffect_skill['s3_guyang']=wrap(sgs.ai_hasTuntianEffect_skill['s3_guyang'],'s3_guyang','ai_hasTuntianEffect_skill')
sgs.ai_fill_skill['s3_fudao']=wrap(sgs.ai_fill_skill['s3_fudao'],'s3_fudao','ai_fill_skill')
sgs.ai_skill_use_func['#s3_fudao']=wrap(sgs.ai_skill_use_func['#s3_fudao'],'#s3_fudao','ai_skill_use_func')
sgs.ai_skill_suit['s3_fudao']=wrap(sgs.ai_skill_suit['s3_fudao'],'s3_fudao','ai_skill_suit')
sgs.ai_skill_playerchosen['s3_guizhou']=wrap(sgs.ai_skill_playerchosen['s3_guizhou'],'s3_guizhou','ai_skill_playerchosen')
sgs.ai_can_damagehp['s3_sizhan']=wrap(sgs.ai_can_damagehp['s3_sizhan'],'s3_sizhan','ai_can_damagehp')
sgs.ai_skill_cardask['@s3_sizhan']=wrap(sgs.ai_skill_cardask['@s3_sizhan'],'@s3_sizhan','ai_skill_cardask')
sgs.ai_need_damaged['s3_zhonglie']=wrap(sgs.ai_need_damaged['s3_zhonglie'],'s3_zhonglie','ai_need_damaged')
sgs.ai_skill_discard['s3_wumou']=wrap(sgs.ai_skill_discard['s3_wumou'],'s3_wumou','ai_skill_discard')
sgs.ai_use_revises['s3_wumou']=wrap(sgs.ai_use_revises['s3_wumou'],'s3_wumou','ai_use_revises')
sgs.ai_skill_invoke['s3_xiaoyong']=wrap(sgs.ai_skill_invoke['s3_xiaoyong'],'s3_xiaoyong','ai_skill_invoke')
sgs.ai_skill_cardask['s3_xiongyi-invoke']=wrap(sgs.ai_skill_cardask['s3_xiongyi-invoke'],'s3_xiongyi-invoke','ai_skill_cardask')
sgs.ai_skill_playerchosen['s3_xiongyi']=wrap(sgs.ai_skill_playerchosen['s3_xiongyi'],'s3_xiongyi','ai_skill_playerchosen')
sgs.ai_fill_skill['s3_xiandao']=wrap(sgs.ai_fill_skill['s3_xiandao'],'s3_xiandao','ai_fill_skill')
sgs.ai_skill_use_func['#s3_xiandao']=wrap(sgs.ai_skill_use_func['#s3_xiandao'],'#s3_xiandao','ai_skill_use_func')
sgs.ai_skill_invoke['s3_yt_fulin']=wrap(sgs.ai_skill_invoke['s3_yt_fulin'],'s3_yt_fulin','ai_skill_invoke')
sgs.ai_skill_choice['s3_yt_fulin']=wrap(sgs.ai_skill_choice['s3_yt_fulin'],'s3_yt_fulin','ai_skill_choice')
sgs.ai_fill_skill['s3_yt_baier']=wrap(sgs.ai_fill_skill['s3_yt_baier'],'s3_yt_baier','ai_fill_skill')
do local f=sgs.ai_view_as['s3_yt_baier'];sgs.ai_view_as['s3_yt_baier']=function(...)return proposal(f(...))end end
sgs.ai_skill_invoke['s3_yt_kuangjun']=wrap(sgs.ai_skill_invoke['s3_yt_kuangjun'],'s3_yt_kuangjun','ai_skill_invoke')
sgs.ai_skill_cardask['@s3_yt_kuangjun']=wrap(sgs.ai_skill_cardask['@s3_yt_kuangjun'],'@s3_yt_kuangjun','ai_skill_cardask')
sgs.ai_skill_invoke['s3_yt_huzheng']=wrap(sgs.ai_skill_invoke['s3_yt_huzheng'],'s3_yt_huzheng','ai_skill_invoke')
sgs.ai_skill_playerchosen['s3_yt_huzheng']=wrap(sgs.ai_skill_playerchosen['s3_yt_huzheng'],'s3_yt_huzheng','ai_skill_playerchosen')
sgs.ai_skill_invoke['s3_yt_huangyi']=wrap(sgs.ai_skill_invoke['s3_yt_huangyi'],'s3_yt_huangyi','ai_skill_invoke')
sgs.ai_skill_choice['s3_yt_huangyi_type']=wrap(sgs.ai_skill_choice['s3_yt_huangyi_type'],'s3_yt_huangyi_type','ai_skill_choice')
sgs.ai_skill_choice['s3_yt_huangyi']=wrap(sgs.ai_skill_choice['s3_yt_huangyi'],'s3_yt_huangyi','ai_skill_choice')
sgs.ai_skill_use['@@s3_yt_huangyi']=wrap(sgs.ai_skill_use['@@s3_yt_huangyi'],'@@s3_yt_huangyi','ai_skill_use')
sgs.ai_skill_playerchosen['s3_yt_zhinan']=wrap(sgs.ai_skill_playerchosen['s3_yt_zhinan'],'s3_yt_zhinan','ai_skill_playerchosen')
sgs.ai_skill_discard['s3_yt_fuding']=wrap(sgs.ai_skill_discard['s3_yt_fuding'],'s3_yt_fuding','ai_skill_discard')
sgs.ai_skill_cardask['s3_yt_fuding_push']=wrap(sgs.ai_skill_cardask['s3_yt_fuding_push'],'s3_yt_fuding_push','ai_skill_cardask')
sgs.ai_skill_invoke['s3_yt_feijun']=wrap(sgs.ai_skill_invoke['s3_yt_feijun'],'s3_yt_feijun','ai_skill_invoke')
sgs.ai_skill_choice['s3_yt_feijun']=wrap(sgs.ai_skill_choice['s3_yt_feijun'],'s3_yt_feijun','ai_skill_choice')
sgs.ai_skill_playerchosen['s3_yt_feijun']=wrap(sgs.ai_skill_playerchosen['s3_yt_feijun'],'s3_yt_feijun','ai_skill_playerchosen')
sgs.ai_card_priority['s3_yt_zhengtao']=wrap(sgs.ai_card_priority['s3_yt_zhengtao'],'s3_yt_zhengtao','ai_card_priority')
sgs.ai_skill_playerchosen['s3_yt_zhengtao']=wrap(sgs.ai_skill_playerchosen['s3_yt_zhengtao'],'s3_yt_zhengtao','ai_skill_playerchosen')
sgs.ai_skill_invoke['s3_yt_mangyong']=wrap(sgs.ai_skill_invoke['s3_yt_mangyong'],'s3_yt_mangyong','ai_skill_invoke')
sgs.ai_fill_skill['s3_yt_tongnan']=wrap(sgs.ai_fill_skill['s3_yt_tongnan'],'s3_yt_tongnan','ai_fill_skill')
sgs.ai_skill_use_func['#s3_yt_tongnan']=wrap(sgs.ai_skill_use_func['#s3_yt_tongnan'],'#s3_yt_tongnan','ai_skill_use_func')
sgs.ai_skill_playerchosen['s3_yt_junlie']=wrap(sgs.ai_skill_playerchosen['s3_yt_junlie'],'s3_yt_junlie','ai_skill_playerchosen')
sgs.ai_skill_invoke['s3_yt_gangyong']=wrap(sgs.ai_skill_invoke['s3_yt_gangyong'],'s3_yt_gangyong','ai_skill_invoke')
sgs.ai_fill_skill['s3_yt_qibing']=wrap(sgs.ai_fill_skill['s3_yt_qibing'],'s3_yt_qibing','ai_fill_skill')
sgs.ai_skill_use_func['#s3_yt_qibing']=wrap(sgs.ai_skill_use_func['#s3_yt_qibing'],'#s3_yt_qibing','ai_skill_use_func')
sgs.ai_skill_discard['s3_yt_panjiang']=wrap(sgs.ai_skill_discard['s3_yt_panjiang'],'s3_yt_panjiang','ai_skill_discard')
sgs.ai_skill_use['@@s3_yt_ruiqiDiscard']=wrap(sgs.ai_skill_use['@@s3_yt_ruiqiDiscard'],'@@s3_yt_ruiqiDiscard','ai_skill_use')
sgs.ai_skill_invoke['s3_yt_ruiqi']=wrap(sgs.ai_skill_invoke['s3_yt_ruiqi'],'s3_yt_ruiqi','ai_skill_invoke')
sgs.ai_skill_cardask['@s3_yt_congzheng']=wrap(sgs.ai_skill_cardask['@s3_yt_congzheng'],'@s3_yt_congzheng','ai_skill_cardask')
sgs.ai_card_priority['s3_yt_yinpan']=wrap(sgs.ai_card_priority['s3_yt_yinpan'],'s3_yt_yinpan','ai_card_priority')
sgs.ai_skill_cardchosen['s3_yt_qujin']=wrap(sgs.ai_skill_cardchosen['s3_yt_qujin'],'s3_yt_qujin','ai_skill_cardchosen')
sgs.ai_skill_choice['s3_yt_qujin']=wrap(sgs.ai_skill_choice['s3_yt_qujin'],'s3_yt_qujin','ai_skill_choice')
sgs.ai_fill_skill['s3_yt_qujin']=wrap(sgs.ai_fill_skill['s3_yt_qujin'],'s3_yt_qujin','ai_fill_skill')
sgs.ai_skill_use_func['#s3_yt_qujin']=wrap(sgs.ai_skill_use_func['#s3_yt_qujin'],'#s3_yt_qujin','ai_skill_use_func')
sgs.ai_skill_invoke['s3_yt_gangjian']=wrap(sgs.ai_skill_invoke['s3_yt_gangjian'],'s3_yt_gangjian','ai_skill_invoke')
sgs.ai_card_priority['s3_yt_youxue']=wrap(sgs.ai_card_priority['s3_yt_youxue'],'s3_yt_youxue','ai_card_priority')
sgs.ai_skill_invoke['s3_yt_gaojiong']=wrap(sgs.ai_skill_invoke['s3_yt_gaojiong'],'s3_yt_gaojiong','ai_skill_invoke')
sgs.ai_skill_discard['s3_touying']=wrap(sgs.ai_skill_discard['s3_touying'],'s3_touying','ai_skill_discard')
sgs.ai_skill_use['@@s3_huanxiangbenghuai']=wrap(sgs.ai_skill_use['@@s3_huanxiangbenghuai'],'@@s3_huanxiangbenghuai','ai_skill_use')
sgs.ai_ajustdamage_from['s3_huanxiangbenghuai']=wrap(sgs.ai_ajustdamage_from['s3_huanxiangbenghuai'],'s3_huanxiangbenghuai','ai_ajustdamage_from')
sgs.ai_ajustdamage_from['s3_fans_caomin']=wrap(sgs.ai_ajustdamage_from['s3_fans_caomin'],'s3_fans_caomin','ai_ajustdamage_from')
sgs.ai_skill_invoke['s3_fans_jiegan']=wrap(sgs.ai_skill_invoke['s3_fans_jiegan'],'s3_fans_jiegan','ai_skill_invoke')
sgs.ai_need_damaged['s3_fans_jiegan']=wrap(sgs.ai_need_damaged['s3_fans_jiegan'],'s3_fans_jiegan','ai_need_damaged')
sgs.ai_skill_cardask['@s3_fans_pianji']=wrap(sgs.ai_skill_cardask['@s3_fans_pianji'],'@s3_fans_pianji','ai_skill_cardask')
sgs.ai_skill_invoke['s3_fans_jiongyan']=wrap(sgs.ai_skill_invoke['s3_fans_jiongyan'],'s3_fans_jiongyan','ai_skill_invoke')
sgs.ai_skill_choice['s3_fans_guzhi']=wrap(sgs.ai_skill_choice['s3_fans_guzhi'],'s3_fans_guzhi','ai_skill_choice')
sgs.ai_skill_use['@@s3_fans_handou']=wrap(sgs.ai_skill_use['@@s3_fans_handou'],'@@s3_fans_handou','ai_skill_use')
sgs.ai_skill_playerchosen['s3_fans_shanlan']=wrap(sgs.ai_skill_playerchosen['s3_fans_shanlan'],'s3_fans_shanlan','ai_skill_playerchosen')
sgs.ai_skill_invoke['s3_fans_shanlan']=wrap(sgs.ai_skill_invoke['s3_fans_shanlan'],'s3_fans_shanlan','ai_skill_invoke')
sgs.ai_skill_playerchosen['s3_fans_yanfeng']=wrap(sgs.ai_skill_playerchosen['s3_fans_yanfeng'],'s3_fans_yanfeng','ai_skill_playerchosen')
sgs.ai_skill_discard['s3_fans_yanfeng']=wrap(sgs.ai_skill_discard['s3_fans_yanfeng'],'s3_fans_yanfeng','ai_skill_discard')
sgs.ai_skill_choice['s3_fans_luoshi']=wrap(sgs.ai_skill_choice['s3_fans_luoshi'],'s3_fans_luoshi','ai_skill_choice')
sgs.ai_skill_use['@@s3_fans_jibian1']=wrap(sgs.ai_skill_use['@@s3_fans_jibian1'],'@@s3_fans_jibian1','ai_skill_use')
sgs.ai_skill_playerchosen['s3_fans_jibian']=wrap(sgs.ai_skill_playerchosen['s3_fans_jibian'],'s3_fans_jibian','ai_skill_playerchosen')
sgs.ai_skill_use['@@s3_fans_jibian2']=wrap(sgs.ai_skill_use['@@s3_fans_jibian2'],'@@s3_fans_jibian2','ai_skill_use')
sgs.ai_fill_skill['s3_fans_feiyan']=wrap(sgs.ai_fill_skill['s3_fans_feiyan'],'s3_fans_feiyan','ai_fill_skill')
sgs.ai_skill_use_func['#s3_fans_feiyan']=wrap(sgs.ai_skill_use_func['#s3_fans_feiyan'],'#s3_fans_feiyan','ai_skill_use_func')
sgs.ai_cardneed['s3_fans_feiyan']=wrap(sgs.ai_cardneed['s3_fans_feiyan'],'s3_fans_feiyan','ai_cardneed')
sgs.ai_skill_invoke['s3_fans_qingyu']=wrap(sgs.ai_skill_invoke['s3_fans_qingyu'],'s3_fans_qingyu','ai_skill_invoke')
sgs.ai_ajustdamage_from['s3_fans_caihua']=wrap(sgs.ai_ajustdamage_from['s3_fans_caihua'],'s3_fans_caihua','ai_ajustdamage_from')
sgs.ai_skill_invoke['s3_fans_shangji']=wrap(sgs.ai_skill_invoke['s3_fans_shangji'],'s3_fans_shangji','ai_skill_invoke')
sgs.ai_skill_invoke['s3_fans_yunce']=wrap(sgs.ai_skill_invoke['s3_fans_yunce'],'s3_fans_yunce','ai_skill_invoke')
sgs.ai_skill_choice['s3_fans_yunce']=wrap(sgs.ai_skill_choice['s3_fans_yunce'],'s3_fans_yunce','ai_skill_choice')
sgs.ai_ajustdamage_from['s3_fans_wenjiu']=wrap(sgs.ai_ajustdamage_from['s3_fans_wenjiu'],'s3_fans_wenjiu','ai_ajustdamage_from')
sgs.ai_fill_skill['s3_fans_xianjia']=wrap(sgs.ai_fill_skill['s3_fans_xianjia'],'s3_fans_xianjia','ai_fill_skill')
sgs.ai_skill_use_func['#s3_fans_xianjia']=wrap(sgs.ai_skill_use_func['#s3_fans_xianjia'],'#s3_fans_xianjia','ai_skill_use_func')
sgs.ai_skill_invoke['s3_fans_yinbing']=wrap(sgs.ai_skill_invoke['s3_fans_yinbing'],'s3_fans_yinbing','ai_skill_invoke')
sgs.ai_skill_discard['s3_fans_yinbing']=wrap(sgs.ai_skill_discard['s3_fans_yinbing'],'s3_fans_yinbing','ai_skill_discard')
sgs.ai_skill_use['@@s3_xianju']=wrap(sgs.ai_skill_use['@@s3_xianju'],'@@s3_xianju','ai_skill_use')
sgs.ai_skill_playerchosen['s3_jxwj_fange']=wrap(sgs.ai_skill_playerchosen['s3_jxwj_fange'],'s3_jxwj_fange','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['s3_jxwj_zhoudao']=wrap(sgs.ai_skill_playerchosen['s3_jxwj_zhoudao'],'s3_jxwj_zhoudao','ai_skill_playerchosen')
sgs.ai_skill_cardask['@s3_jxwj_duce']=wrap(sgs.ai_skill_cardask['@s3_jxwj_duce'],'@s3_jxwj_duce','ai_skill_cardask')
sgs.ai_skill_choice['s3_jxwj_duce']=wrap(sgs.ai_skill_choice['s3_jxwj_duce'],'s3_jxwj_duce','ai_skill_choice')
sgs.ai_cardsview_valuable['s3_jxwj_weiwan']=wrap(sgs.ai_cardsview_valuable['s3_jxwj_weiwan'],'s3_jxwj_weiwan','ai_cardsview_valuable')
sgs.ai_cardsview['s3_jxwj_weiwan']=wrap(sgs.ai_cardsview['s3_jxwj_weiwan'],'s3_jxwj_weiwan','ai_cardsview')
sgs.ai_skill_invoke['s3_jxwj_miaoyan']=wrap(sgs.ai_skill_invoke['s3_jxwj_miaoyan'],'s3_jxwj_miaoyan','ai_skill_invoke')
sgs.ai_skill_choice['s3_jxwj_dunwei']=wrap(sgs.ai_skill_choice['s3_jxwj_dunwei'],'s3_jxwj_dunwei','ai_skill_choice')
sgs.ai_skill_cardask['@s3_jxwj_boji']=wrap(sgs.ai_skill_cardask['@s3_jxwj_boji'],'@s3_jxwj_boji','ai_skill_cardask')
sgs.ai_skill_invoke['s3_jxwj_zhuwei']=wrap(sgs.ai_skill_invoke['s3_jxwj_zhuwei'],'s3_jxwj_zhuwei','ai_skill_invoke')
sgs.ai_skill_invoke['s3_jxwj_zhuwei_draw']=wrap(sgs.ai_skill_invoke['s3_jxwj_zhuwei_draw'],'s3_jxwj_zhuwei_draw','ai_skill_invoke')
sgs.ai_skill_use['@@s3_jxwj_zhuwei']=wrap(sgs.ai_skill_use['@@s3_jxwj_zhuwei'],'@@s3_jxwj_zhuwei','ai_skill_use')
sgs.ai_skill_use['@@s3_jxwj_zijun']=wrap(sgs.ai_skill_use['@@s3_jxwj_zijun'],'@@s3_jxwj_zijun','ai_skill_use')
sgs.ai_fill_skill['s3_jxwj_shangdao']=wrap(sgs.ai_fill_skill['s3_jxwj_shangdao'],'s3_jxwj_shangdao','ai_fill_skill')
sgs.ai_skill_use_func['#s3_jxwj_shangdao']=wrap(sgs.ai_skill_use_func['#s3_jxwj_shangdao'],'#s3_jxwj_shangdao','ai_skill_use_func')
sgs.ai_skill_choice['s3_jxwj_xiantu']=wrap(sgs.ai_skill_choice['s3_jxwj_xiantu'],'s3_jxwj_xiantu','ai_skill_choice')
sgs.ai_skill_cardask['@s3_jxwj_qiangji']=wrap(sgs.ai_skill_cardask['@s3_jxwj_qiangji'],'@s3_jxwj_qiangji','ai_skill_cardask')
sgs.ai_can_damagehp['s3_jxwj_gangli']=wrap(sgs.ai_can_damagehp['s3_jxwj_gangli'],'s3_jxwj_gangli','ai_can_damagehp')
sgs.ai_skill_invoke['s3_jxwj_gangli']=wrap(sgs.ai_skill_invoke['s3_jxwj_gangli'],'s3_jxwj_gangli','ai_skill_invoke')
sgs.ai_skill_choice['s3_jxwj_gangli']=wrap(sgs.ai_skill_choice['s3_jxwj_gangli'],'s3_jxwj_gangli','ai_skill_choice')
sgs.ai_fill_skill['s3_jxwj_fuji']=wrap(sgs.ai_fill_skill['s3_jxwj_fuji'],'s3_jxwj_fuji','ai_fill_skill')
sgs.ai_skill_use_func['#s3_jxwj_fuji']=wrap(sgs.ai_skill_use_func['#s3_jxwj_fuji'],'#s3_jxwj_fuji','ai_skill_use_func')
sgs.ai_skill_invoke['s3_jxwj_fuji']=wrap(sgs.ai_skill_invoke['s3_jxwj_fuji'],'s3_jxwj_fuji','ai_skill_invoke')
sgs.ai_cardsview_valuable['s3_jxwj_jiujia']=wrap(sgs.ai_cardsview_valuable['s3_jxwj_jiujia'],'s3_jxwj_jiujia','ai_cardsview_valuable')
sgs.ai_skill_choice['s3_jxwj_jiujia']=wrap(sgs.ai_skill_choice['s3_jxwj_jiujia'],'s3_jxwj_jiujia','ai_skill_choice')
sgs.ai_skill_cardchosen['s3_jxwj_jiujia']=wrap(sgs.ai_skill_cardchosen['s3_jxwj_jiujia'],'s3_jxwj_jiujia','ai_skill_cardchosen')
sgs.ai_skill_playerchosen['s3_jxwj_jiujia']=wrap(sgs.ai_skill_playerchosen['s3_jxwj_jiujia'],'s3_jxwj_jiujia','ai_skill_playerchosen')
sgs.ai_skill_invoke['s3_jxwj_xianci']=wrap(sgs.ai_skill_invoke['s3_jxwj_xianci'],'s3_jxwj_xianci','ai_skill_invoke')
sgs.ai_cardneed['s_lotus_stick']=wrap(sgs.ai_cardneed['s_lotus_stick'],'s_lotus_stick','ai_cardneed')
sgs.ai_cardneed['s_fire_sword']=wrap(sgs.ai_cardneed['s_fire_sword'],'s_fire_sword','ai_cardneed')
sgs.ai_cardneed['s_biaoqi']=wrap(sgs.ai_cardneed['s_biaoqi'],'s_biaoqi','ai_cardneed')
sgs.ai_skill_invoke['s_biaoqi']=wrap(sgs.ai_skill_invoke['s_biaoqi'],'s_biaoqi','ai_skill_invoke')
sgs.ai_skill_playerchosen['gzj_leishen']=wrap(sgs.ai_skill_playerchosen['gzj_leishen'],'gzj_leishen','ai_skill_playerchosen')
sgs.ai_slash_prohibit['gzj_leishen']=wrap(sgs.ai_slash_prohibit['gzj_leishen'],'gzj_leishen','ai_slash_prohibit')
sgs.ai_skill_invoke['gzj_jiazi']=wrap(sgs.ai_skill_invoke['gzj_jiazi'],'gzj_jiazi','ai_skill_invoke')
sgs.ai_skill_askforag['gzj_jiazi']=wrap(sgs.ai_skill_askforag['gzj_jiazi'],'gzj_jiazi','ai_skill_askforag')
sgs.ai_skill_playerchosen['gzj_guifen']=wrap(sgs.ai_skill_playerchosen['gzj_guifen'],'gzj_guifen','ai_skill_playerchosen')
sgs.ai_slash_prohibit['gzj_guifen']=wrap(sgs.ai_slash_prohibit['gzj_guifen'],'gzj_guifen','ai_slash_prohibit')
sgs.ai_skill_cardask['@gzj_tiandao-card']=wrap(sgs.ai_skill_cardask['@gzj_tiandao-card'],'@gzj_tiandao-card','ai_skill_cardask')
sgs.ai_cardneed['gzj_tiandao']=wrap(sgs.ai_cardneed['gzj_tiandao'],'gzj_tiandao','ai_cardneed')
