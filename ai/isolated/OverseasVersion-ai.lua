-- Fixed b6025acc source bodies; request-scoped readonly planning and selected payment.
local function known(v,k) if AIUnsupported.is(v) then error(v,0) end;if v==nil then ai_unsupported('overseas value is not observed',k) end;return v end
local function q(o,k,...) if o==nil then error('attempt to index a nil value',0) end;if AIValue.isPlayer(o) then if k=='getMark' then k='getStrategyMark' elseif k=='hasFlag' then k='getStrategyFlag' end end;if type(o[k])~='function' then ai_unsupported('overseas method missing',k) end;return known(o[k](o,...),k) end
local function visible(self,id)
 local c=self:getKnownCardById(id);if not c and type(self.getChoiceCard)=='function'then c=self:getChoiceCard(id)end
 return known(c,'overseas disclosed physical card')
end
local function copy(t) local r={} for k,v in pairs(t)do r[k]=type(v)=='table' and copy(v) or v end;return r end
local function dummy_plan(v,extra,current) local u=AIUsePlan.new();u.isDummy=v~=false;u.extra_target=extra or 0;u.current_targets=current or {};return u end
local classes={['#ov_lingbaoCard']='ov_lingbao',['#ov_beiniCard']='ov_beini',['#ov_weipoCard']='ov_weipo',['#ov_weipobfCard']='ov_weipobf',['#ov_mouzhuCard']='ov_mouzhu',['#ov_daojiCard']='ov_daoji',['#ov_yujuevsCard']='ov_yujuevs',['#ov_sfzhouhuCard']='ov_sfzhouhu',['#ov_sffengqiCard']='ov_sffengqi',['#ov_gongqiCard']='ov_gongqi',['#ov_jiefanCard']='ov_jiefan',['#ov_fuzuanCard']='ov_fuzuan',['#ov_zhuiduCard']='ov_zhuidu',['#ov_luannianCard']='ov_luannianvs',['#ov_bingdeCard']='ov_bingde',['#ov_xiongsiCard']='ov_xiongsi',['#ov_xiongxiCard']='ov_xiongxi',['#ov_juxiangCard']='ov_juxiangvs',['#ov_shijunCard']='ov_shijunvs',['#ov_xingzhuiCard']='ov_xingzhui',['#ov_luanlveCard']='ov_luanlve',['#ov_jichouCard']='ov_jichou',['#ov_mutaoCard']='ov_mutao',['#ov_kujianCard']='ov_kujian',['#ov_bomingCard']='ov_boming',['#ov_jinglveCard']='ov_jinglve',['#ov_fumanCard']='ov_fuman',['#ov_mouliCard']='ov_mouli',['#ov_yuanhuCard']='ov_yuanhu',['#ov_qingceCard']='ov_qingce',['#ov_luanchouCard']='ov_luanchou',['#ov_gongxinCard']='ov_gongxin',['#ov_kaizengCard']='ov_kaizengvs',['#ov_xiechangCard']='ov_xiechang',['#ov_yuejianCard']='ov_yuejian',['#ov_muyueCard']='ov_muyue',['#ov_fubiCard']='ov_fubi',['#ov_quanqianCard']='ov_quanqian',['#ov_chengxiCard']='ov_chengxi',['#ov_danlieCard']='ov_danlie',['#ov_huajingCard']='ov_huajing',['#ov_jieqiuCard']='ov_jieqiu',['#ov_enchouCard']='ov_enchou',['#ov_yanshiYLCard']='ov_yanshiYL',['#ov_huanjiCard']='ov_huanji',['#ov_qinghanCard']='ov_qinghan',['#ov_xianyuanCard']='ov_xianyuan',['#ov_lifengCard']='ov_lifeng',['#ov_guihanCard']='ov_guihan',['#ov_renxianCard']='ov_renxian',['#ov_liaoluanCard']='ov_liaoluanvs',['#ov_fenxianCard']='ov_fenxian',['#ov_shiyiCard']='ov_shiyi',['#ov_miyongCard']='ov_miyong',['#ov_hanhongCard']='ov_hanhong',['#ov_qianxiongCard']='ov_qianxiong',['#ov_fushuCard']='ov_fushu',['#ov_zhenjunCard']='ov_zhenjun',['#ov_yanhuoCard']='ov_yanhuo',['#ov_kaijiCard']='ov_kaiji',['#ov_fenghanCard']='ov_fenghan',['#ov_yingjiCard']='ov_yingji',['#ov_xiongzhengCard']='ov_xiongzheng',['#ov_poluCard']='ov_polu',['#ov_dingzhenCard']='ov_dingzhen',['#ov_chaofengCard']='ov_chaofeng',['#ov_zhenhuCard']='ov_zhenhu',['#ov_xuanhuoCard']='ov_xuanhuo',['#ov_hongjuCard']='ov_hongju',['#ov_xingluanCard']='ov_xingluan',['#ov_zaoliCard']='ov_zaoli',['#ov_liexiCard']='ov_liexi',['#ov_xingwuCard']='ov_xingwu',['#ov_lijianCard']='ov_lijian',['#ov_niwoCard']='ov_niwo',['#ov_xiumuCard']='ov_xiumu'}
local recipes=setmetatable({},{__mode='k'})
local function ids(s)local r={}if s~='.' and s~='' then for n in s:gmatch('[^+]+')do r[#r+1]=assert(tonumber(n))end end;return r end
local function printed_spec(s)
 local name,skill,suit,num,cost=s:match('^([%w_]+):([%w_]*)%[([^:]+):([^%]]+)%]=(.*)$');if not name then return end
 local suits={spade=sgs.Card_Spade,club=sgs.Card_Club,heart=sgs.Card_Heart,diamond=sgs.Card_Diamond,no_suit=sgs.Card_NoSuit,no_suit_red=sgs.Card_NoSuitRed,no_suit_black=sgs.Card_NoSuitBlack,to_be_decided=sgs.Card_SuitToBeDecided}
 local nums={A=1,J=11,Q=12,K=13};return{name=name,skill=skill,suit=known(suits[suit],'printed suit'),number=known(tonumber(num)or nums[num],'printed number'),subcards=ids(cost)}
end
local function decode(text)
 local cl,raw=text:match('^@([%w_]+)=(.*)$');local user
 if cl then local cs,u=raw:match('^(.-):(.*)$');raw=cs or raw;user=u else cl,raw,user=text:match('^#([%w_]+):([^:]*):(.*)$');if cl then cl='#'..cl end end
 return known(cl,'source prototype'),known(classes[cl],'source skill'),ids(raw),user~=''and user or nil
end
local function policy(self,text,request)
 if text==""then return nil end
 if type(text)=="string"and text:match("^%d+$")then return visible(self,tonumber(text))end
 request=request or self._overseas_request
 local row=printed_spec(text)
 if row then row.source_key=self._overseas_key;local c=self:evaluateOwnerViewAsCard(row);if c then recipes[c]=row end;return c end
 local cl,sk,cs,u=decode(text);local c=self:evaluateTurnSkillCard(sk,cl,cs,request,u);recipes[c]={prototype=cl,skill=sk,subcards=cs,user=u};return c
end
local function clone(self,name,suit,number,skill)
 if type(suit)=="string"then skill=suit;suit=sgs.Card_NoSuit end
 local spec={source_key=self._overseas_key or 'overseas',name=name or 'slash',skill=skill or '',suit=suit or sgs.Card_NoSuit,number=number or 0,subcards={}}
 local c;if spec.skill=='' and spec.suit==sgs.Card_NoSuit and spec.number==0 then c=self:getEvaluationCard(spec.name) else c=self:evaluateOwnerViewAsCard(spec) end
 if c then recipes[c]=spec end;return c
end
local function mutate(self,c,k,v)
 local spec=copy(known(recipes[c],'source readonly constructor'));if k=='add'then spec.subcards[#spec.subcards+1]=type(v)=='number'and v or q(v,'getEffectiveId')elseif k=='adds'then for _,id in ipairs(v)do spec.subcards[#spec.subcards+1]=id end else spec[k]=v end
 local n=self:evaluateOwnerViewAsCard(spec);self:inheritLegacyCardIdentity(n,c);recipes[n]=spec;return n
end
local function proposal(text)
 if type(text)~='string'or text=='.'then return text end
 local v=printed_spec(text);if v then return v end
 local cl,sk,cs,u=decode(text);v={skill=sk,legacy_class=cl,subcards=cs};if u then v.user_string=u end;return v
end
local selected_response
local function response(self,text)
 if type(text)~='string'or text=='.'or text==''then return text end
 local wire,targets=text:match('^(.-)%->(.*)$');wire=wire or text
 if wire:match('^%d+$')then return{kind='use_card',card_ids={tonumber(wire)},targets=targets and targets:split('+')or{}}end
 local c;if printed_spec(wire)then c=selected_response(self,wire)else local cl,sk,cs,u=decode(wire);if sk=="ov_niwo" and cl=="#ov_niwoCard" and u==nil then c=self:bindOverseasNiwoSelected(cs)else c=self:bindSkillCard(sk,cs,nil,u,cl)end end
 return{kind='use_card',card_spec=c:toCardSpec(),targets=targets and targets:split('+')or{}}
end
local function source_role(self,p)
 local role=p:getRole();if role~=nil and role~='unknown'and role~='neutral'then return role end
 role=self:getRoleEstimate(p);if role==nil or role=='neutral'or role=='unknown'then ai_unsupported('private role is not resolved for this viewer','overseas.role')end
 return self:useKnowledgeEstimate({value=role,status='estimate',basis='viewer_role_inference_replaces_private_role',viewer=self.player:objectName(),target=p:objectName()},'overseas.role')
end
local function observed_hand(self,p)
 if p:objectName()==self.player:objectName()then return known(p:getHandcards(),'owner hand')end
 -- These source loops themselves filter visible/visible_observer flags. No hidden face is inspected.
 return known(p:getKnownCards(),'observer disclosed hand')
end
local function fact(self,k)return known(known(self:getDecisionContext().round27_choice,'Overseas scoped context')[k],k)end
local function player(self,n)return n~=false and n~=nil and known(self.room:findPlayerByObjectName(n,true),'scoped player')or nil end
local function use_view(self,r)
 if r==false then return{to=AIList.new({})}end
 local tos=AIList.new({});for _,n in ipairs(known(r.to,'scoped targets'))do tos:append(player(self,n))end
 return{from=player(self,r.from),to=tos,card=r.card and r.card~=false and CardView.new(r.card)or nil}
end
local function tag(self,k,kind)
 local remembered,ok=self:getStrategyMemory('OverseasVersion.tag:'..k)
 if ok then if kind=='Player'then return player(self,remembered)elseif kind=='CardUse'then return use_view(self,remembered)else return remembered end end
 local r=known(fact(self,'owner_tags')[k],k)
 if kind=='Player'then return player(self,r)elseif kind=='CardUse'then return use_view(self,r)elseif kind=='IntList'then return AIList.new(r)end
 return r
end
local function foreign_tag(self,p,k,kind)
 if p:objectName()==self.player:objectName()then return tag(self,k,kind)end
 local row=known(known(fact(self,'public_target_tags')[p:objectName()],'disclosed target tag')[k],k)
 if kind=='Player'then return player(self,row)end;return row
end
local function property(self,k)return known(fact(self,'owner_properties')[k],k)end
local function can_to(self,c,from,to,tos)
 if from:objectName()==self.player:objectName()then return self:cardTargetFilter(c,tos or{},to)end
 -- Fixed Tiaojiyanmei calls targetFilter with a foreign source before its
 -- public hand-count checks. Do not reorder or probe private limitations.
 ai_unsupported('foreign source targetFilter requires disclosed limitation/modifier/prohibit facts','OverseasVersion.CanToCard')
end
local function is_current(use,p)for _,n in ipairs(use.current_targets or{})do if n==p:objectName()or(AIValue.isPlayer(n)and n:objectName()==p:objectName())then return true end end;return false end
local function extra_targets(self,c)return known(self:getEvaluationCandidate(c):getExtraTargetCount(),'extra target modifier')end
local function same_card_in(cards,card)
 for _,other in ipairs(cards)do if AIValue.sameLegacyIdentity(other,card)then return true end end
 return false
end
local function same_player(a,b)return a and b and a:objectName()==b:objectName()end

selected_response=function(self,text)
 local spec=type(text)=='string'and printed_spec(text);if not spec then return text end
 local base=known(self:getEvaluationCard(spec.name),'selected printed response')
 local policy=known(self:getConversionPolicy(base:getClassName()),'selected response catalog');local source
 for _,row in ipairs(policy.skills or{})do if row.skill_name==spec.skill then source=row;break end end
 return known(self:resolveResponseConversion(spec,known(source,'exact selected response source')),'selected response receipt')
end

local function equip(self,p,slot)local c=p:getEquip(slot);return type(c)=='number'and visible(self,c)or c end
local function complete_hand(self,p)
 if p:objectName()==self.player:objectName()then return known(p:getHandcards(),'owner hand')end
 local cards=known(p:getKnownCards(),'disclosed hand');if #cards~=q(p,'getHandcardNum')then ai_unsupported('source branch requires undisclosed foreign hand faces','OverseasVersion.hand')end;return cards
end
local function list_i2c(self,ids)local r=AIList.new({});for _,id in ipairs(ids)do r:append(visible(self,id))end;return r end
local function source_patterns(self)return known(self.world.strategy_facts.pattern_names,'public source patterns')end
local function pattern_card(self,name,islist,derivative)
 if islist then ai_unsupported('whole pattern list is not requested by audited Overseas callsites','PatternsCard')end
 if type(ai_sample_pattern_log_name)~='function'then ai_unsupported('source pattern sampler unavailable','PatternsCard')end
 local r=ai_sample_pattern_log_name(name,derivative==true)
 if type(r)~='table'or r.pattern~=name or type(r.found)~='boolean'then ai_unsupported('source pattern sample malformed',name)end
 if derivative==true and r.derivative~=true then ai_unsupported('derivative source shuffle not proven',name)end
 if not r.found then return nil end;return CardView.new(known(r.printed_card,'sampled printed face'))
end
local function encode(self,v)
 if v==nil then return{kind='nil'}end
 if AIValue.isPlayer(v)then return{kind='player',name=v:objectName()}end
 if AIValue.isCard(v)or AIValue.isConversion(v)then return{kind='card',face=self:capturePriorTurnPlan(v)}end
 if type(v)~='table'then return{kind='scalar',value=v}end
 local r={kind='table',list=AIValue.isList(v),value={}};for k,x in pairs(v)do if type(x)~='function'then r.value[k]=encode(self,x)end end;return r
end
local function decode_state(self,v)
 if v.kind=='nil'then return nil elseif v.kind=='scalar'then return v.value elseif v.kind=='player'then return player(self,v.name)elseif v.kind=='card'then return self:restorePriorTurnPlan(v.face)elseif v.kind=='table'then
 local r={};for k,x in pairs(v.value)do r[k]=decode_state(self,x)end;return v.list and AIList.new(r)or r end
 ai_unsupported('invalid primitive observation cache','OverseasVersion.state')
end
local function load_state(self,keys)
 self._overseas_loaded=self._overseas_loaded or{}
 for _,k in ipairs(keys)do if not self._overseas_loaded[k]then local v,ok=self:getStrategyMemory('OverseasVersion.'..k);if ok then self[k]=decode_state(self,v)end;self._overseas_loaded[k]=true end end
end
local function save_state(self,keys)for _,k in ipairs(keys)do self:setStrategyMemory('OverseasVersion.'..k,encode(self,self[k]))end end
local source_prefix_keys={
 ai_skill_playerchosen={ov_yingjia=true},ai_skill_invoke={ov_beini=true},
 ai_skill_choice={shifa=true,ov_xiafeng=true,wangxing=true,ov_zenhui=true,ov_yizhu=true},
}
local function dynamic(self,registry,key,v)
 local keys=source_prefix_keys[registry]
 if keys and keys[key]then
  if type(ai_response_choice_continuity)~='function'then ai_unsupported('actual named source registry assignment unavailable',key)end
  local out=ai_response_choice_continuity{op='source_prefix',registry=registry,key=key,value=encode(self,v)}
  if AIUnsupported.is(out)then error(out,0)end
  if type(out)~='table'or out.known~=true or out.written~=true then
   ai_unsupported('actual named source registry assignment is not admitted',key)
  end
 end
 self:setStrategyMemory('OverseasVersion.registry:'..registry..':'..key,{value=encode(self,v),decision_id=self.request.decision_id,state_revision=self.request.state_revision})
end
local function dynamic_read(self,registry,key)
 local v,ok=self:getStrategyMemory('OverseasVersion.registry:'..registry..':'..key)
 if not ok or v.decision_id~=self.request.decision_id or v.state_revision~=self.request.state_revision then ai_unsupported('global registry last-writer provenance is not observed across questions',key)end;return decode_state(self,v.value)
end
local authored={}
local function remember_function(reg,key,fn,read,write)
 authored[#authored+1]={reg=reg,key=key,fn=fn,read=read,write=write}
end
local function increment_yujue(self)
 local epochs=known(self.world.strategy_facts.strategy_play_clear_epochs,'Play clear epochs');local epoch=known(epochs[self.player:objectName()],'owner Play clear epoch')
 local prior,seen=self:getStrategyMemory('OverseasVersion.yujue_mark')
 local amount=seen and prior.epoch==epoch and prior.amount or 0
 self:setStrategyMemory('OverseasVersion.yujue_mark',{epoch=epoch,amount=amount+1})
end
local function write_delegate(self,key,use)
 if type(self.observeOverseasDelegateUse)~='function'then ai_unsupported('scoped source-to-common use observation bridge unavailable',key)end
 return self:observeOverseasDelegateUse(self._overseas_key,key,use)
end

local function yujue_mark(self)
 local native=q(self.player,'getMark','ov_yujue_use-PlayClear')
 local v,ok=self:getStrategyMemory('OverseasVersion.yujue_mark');if not ok then return native end
 local epochs=known(self.world.strategy_facts.strategy_play_clear_epochs,'Play clear epochs');local epoch=known(epochs[self.player:objectName()],'owner Play clear epoch')
 return native+(v.epoch==epoch and v.amount or 0)
end

local function card_names(self)
 if type(ai_response_catalogue)~='function'then ai_unsupported('source getCardNames sampler unavailable','ov_qinyi')end
 local row=ai_response_catalogue('ov_qinyi_names');if AIUnsupported.is(row)then error(row,0)end
 if type(row)~='table'or row.known~=true or row.key~='ov_qinyi_names'then ai_unsupported('source getCardNames result malformed','ov_qinyi')end
 return known(row.names,'ov_qinyi names')
end

local function promote_fill(self,key,c,request)
 if not AIValue.isCard(c)or not recipes[c]or recipes[c].prototype then return c end
 if type(self.isReadonlyTurnConversion)=='function'and self:isReadonlyTurnConversion(c)then return c end
 local spec=copy(recipes[c]);spec.source_key=nil
 local result=self:evaluateTurnConversion(key,c:getClassName(),spec,request)
 self:inheritLegacyCardIdentity(result,c);recipes[result]=spec;return result
end
local function siblings(self,alive)
 local values=AIList.new({});for _,name in ipairs(fact(self,'sibling_names'))do
  local p=player(self,name);if not alive or q(p,'isAlive')then values:append(p)end
 end;return values
end
local function card_targets(self,from,card,except)
 if from:objectName()~=self.player:objectName()then ai_unsupported('foreign getCardTargets is not an owner query','OverseasVersion.targets')end
 local values=AIList.new({});for _,name in ipairs(fact(self,'card_target_names'))do values:append(player(self,name))end;return values
end
local function scoped_data(self,key,data)
 local kind=({ov_fupan='String',ov_enyuan='String',ov_yuzhang='String',ov_xinshou='String',ov_qiji2='String',ov_qiaosi='IntListCount'})[key]
 if not kind then return data end
 local row=known(fact(self,'data'),'Overseas source data')
 if row.kind~=kind then ai_unsupported('source scalar QVariant kind mismatch',key)end
 local methods={}
 if kind=='String'then
  if type(row.value)~='string'then ai_unsupported('source string is unknown',key)end
  methods.toString=function()return row.value end
 else
  if type(row.count)~='number'or row.count<0 or row.count%1~=0 then ai_unsupported('source list length is unknown',key)end
  methods.toIntList=function()return setmetatable({length=function()return row.count end},{__index=function()ai_unsupported('only source IntList length is disclosed',key)end})end
 end
 return setmetatable(methods,{__index=function(_,k)return data and data[k]end})
end
local function peiqi_state(self)
 -- Same per-viewer self.peiqiData slot used by the already audited common
 -- package bridge. No global registry assumption and no foreign VM sharing.
 local row,present=self:getStrategyMemory('yjcm2022.peiqiData')
 if present and row then self.peiqiData={cid=row.cid,from=player(self,row.from),to=player(self,row.to)};return end
 row,present=self:getStrategyMemory('tenyear_hc.peiqiData')
 if not present then ai_unsupported('source Peiqi writer has not been observed','ov_zhilve')end
 local function read(v)
  if v.type=='nil'then return nil elseif v.type=='scalar'then return v.value elseif v.type=='player'then return player(self,v.name)
  elseif v.type=='table'then local t={};for k,x in pairs(v.value)do t[k]=read(x)end;return t end
  ai_unsupported('unexpected Peiqi observation shape','ov_zhilve')
 end
 self.peiqiData=read(row)
end

local function gongxin_ag(self,card_ids)
 local target,observed=self:getStrategyMemory('OverseasVersion.tag:gongxin')
 if not observed then return sgs.ai_skill_askforag.gongxin(self,card_ids)end
 local prior=rawget(self,'getDecisionContext');local original=self.getDecisionContext
 self.getDecisionContext=function(ai)local context=original(ai);context.gongxin_target=target;return context end
 local result=table.pack(pcall(sgs.ai_skill_askforag.gongxin,self,card_ids))
 self.getDecisionContext=prior
 if not result[1]then error(result[2],0)end
 return table.unpack(result,2,result.n)
end


sgs.ai_skill_cardask["ov_danfa0"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	local ids = self.player:getPile("ov_dan")
	for _,h in sgs.list(cards)do
		if q(self.player,"getPhase")==sgs.Player_Start
		and self.player:getJudgingArea():length()>0
		and #self:getCards("Nullification")>0
		and same_card_in(self:getCards("Nullification"),h)
		or q(self.player,"getPhase")==sgs.Player_Finish and #cards<3
		then continue end
		local can = true
		for _,c in sgs.list(list_i2c(self,ids))do
			if q(c,"getSuit")==q(h,"getSuit")
			then can = false end
		end
		if can
		then
			return q(h,"getEffectiveId")
		end
	end
    return #cards>2 and q(cards[1],"getEffectiveId") or "."
end


remember_function('ai_skill_cardask','ov_danfa0',sgs.ai_skill_cardask['ov_danfa0'],{},{})
sgs.ai_fill_skill["ov_lingbao"] = function(self,inclusive,request)
    local cards = self.player:getPile("ov_dan")
	if cards:length()<2 then return end
	local valid,suit = {},sgs.IntList()
	for _,h in sgs.list(list_i2c(self,cards))do
		if suit:contains(q(h,"getSuit")) then continue end
		self.ov_lingbao_to = sgs.SPlayerList()
		for _,p in sgs.list(self.friends)do
			if self:isWeak(p)
			and h:isRed()
			then
				self.ov_lingbao_to:append(p)
				table.insert(valid,q(h,"getEffectiveId"))
				suit:append(q(h,"getSuit"))
				break
			end
		end
		if #valid>1 then return policy(self,"#ov_lingbaoCard:"..table.concat(valid,"+")..":") end
	end
	valid,suit = {},sgs.IntList()
	for _,h in sgs.list(list_i2c(self,cards))do
		if suit:contains(q(h,"getSuit")) then continue end
		self.ov_lingbao_to = sgs.SPlayerList()
		for _,p in sgs.list(self.enemies)do
			if q(p,"getHandcardNum")>0
			and p:hasEquip()
			and h:isBlack()
			then
				self.ov_lingbao_to:append(p)
				table.insert(valid,q(h,"getEffectiveId"))
				suit:append(q(h,"getSuit"))
				break
			end
		end
		h = policy(self,"#ov_lingbaoCard:"..table.concat(valid,"+")..":")
		if #valid>1 then self:setPriorityValue("ov_lingbaoCard",3.4,"OverseasVersion") return h end
	end
	valid,suit = {},sgs.IntList()
	self.enemies = self:sort(self.enemies,"card")
	self.friends = self:sort(self.friends,"card")
	for _,h in sgs.list(list_i2c(self,cards))do
		if suit:contains(q(h,"getSuit")) then continue end
		self.ov_lingbao_to = sgs.SPlayerList()
		for _,p in sgs.list(self.enemies)do
			if p:getCardCount()>0
			then
				if #valid>0
				and q(h,"getColor")==visible(self,valid[1]):getColor()
				then break end
				self.ov_lingbao_to:append(self.friends[1])
				self.ov_lingbao_to:append(p)
				table.insert(valid,q(h,"getEffectiveId"))
				suit:append(q(h,"getSuit"))
				break
			end
		end
		h = policy(self,"#ov_lingbaoCard:"..table.concat(valid,"+")..":")
		if #valid>1 then return h end
	end
end


remember_function('ai_fill_skill','ov_lingbao',sgs.ai_fill_skill['ov_lingbao'],{'ov_lingbao_to'},{'ov_lingbao_to'})
sgs.ai_skill_use_func["#ov_lingbaoCard"] = function(card,use,self)
	use.card = card
	use.to = self.ov_lingbao_to
end


remember_function('ai_skill_use_func','#ov_lingbaoCard',sgs.ai_skill_use_func['#ov_lingbaoCard'],{'ov_lingbao_to'},{})
sgs.ai_use_value.ov_lingbaoCard = 6.4
sgs.ai_use_priority.ov_lingbaoCard = 0.4

sgs.ai_can_damagehp._ov_chongyingshenfu = function(self,from,card,to)
	if card and q(to,"getMark","_ov_chongyingshenfu"..card:objectName())>0
	then return self:canLoseHp(from,card,to) end
	return card and self:canLoseHp(from,card,to)
	and q(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
end


remember_function('ai_can_damagehp','_ov_chongyingshenfu',sgs.ai_can_damagehp['_ov_chongyingshenfu'],{},{})
sgs.ai_armor_value._ov_chongyingshenfu = 5
sgs.ai_armor_value._ov_taijifuchen = 3
sgs.ai_armor_value._ov_lingbaoxianhu = 4

sgs.ai_keep_value.OvChongyingshenfu = 11
sgs.ai_keep_value.OvTaijifuchen = 11
sgs.ai_keep_value.OvLingbaoxianhu = 11

sgs.ai_skill_invoke.ov_miaolve = function(self,data)
	return true
end


remember_function('ai_skill_invoke','ov_miaolve',sgs.ai_skill_invoke['ov_miaolve'],{},{})
sgs.ai_skill_choice.ov_miaolve = function(self,choices)
	local items = choices:split("+")
	return items[1]
end


remember_function('ai_skill_choice','ov_miaolve',sgs.ai_skill_choice['ov_miaolve'],{},{})
sgs.ai_skill_cardask["ov_yingjia0"] = function(self,data,pattern)
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
	self.friends = self:sort(self.friends,"handcard",true)
	for _,fp in sgs.list(self.friends)do
		if q(fp,"getHandcardNum")>1
		and #cards>0
		then
			dynamic(self,'ai_skill_playerchosen','ov_yingjia',fp)
			return q(cards[1],"getEffectiveId")
		end
	end
	dynamic(self,'ai_skill_playerchosen','ov_yingjia',self.friends[1])
    return #self.friends>0 and #cards>1 and q(cards[1],"getEffectiveId") or "."
end


remember_function('ai_skill_cardask','ov_yingjia0',sgs.ai_skill_cardask['ov_yingjia0'],{},{})
function SmartAIView:useCardMantianguohai(card,use)
	local extraTarget = 1+extra_targets(self,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	self.enemies = self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if is_current(use,ep) then continue end
		if not use.to:contains(ep) and can_to(self,card,self.player,ep)
		and self:doDisCard(ep,"ej") and q(self.player,"getHandcardNum")>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		if is_current(use,ep) then continue end
		if not use.to:contains(ep) and can_to(self,card,self.player,ep)
		and self:doDisCard(ep,"ej") and q(self.player,"getHandcardNum")>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		if is_current(use,ep) then continue end
		if not use.to:contains(ep) and can_to(self,card,self.player,ep)
		and q(ep,"getHandcardNum")>0 and q(self.player,"getHandcardNum")>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	self.enemies = self:sort(self.enemies,"card",true)
	for _,ep in sgs.list(self.enemies)do
		if is_current(use,ep) then continue end
		if not use.to:contains(ep) and can_to(self,card,self.player,ep)
		and ep:getCardCount()>0 and q(self.player,"getHandcardNum")>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if is_current(use,ep) then continue end
		if not use.to:contains(ep) and can_to(self,card,self.player,ep)
		and ep:getCardCount()>0 and q(self.player,"getHandcardNum")>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end

remember_function('SmartAIView','useCardMantianguohai',SmartAIView['useCardMantianguohai'],{},{})
sgs.ai_use_priority.Mantianguohai = 5.4
sgs.ai_keep_value.Mantianguohai = 4
sgs.ai_use_value.Mantianguohai = 3.7

sgs.ai_nullification.Mantianguohai = function(self,trick,from,to,positive)
    local null_num = self:getCardsNum("Nullification")
    if positive
	then
		if self:isEnemy(from)
		and self:isFriend(to)
		then
			if null_num>1
			then
				return to:hasEquip()
			else
				return to:getCardCount()>0
				and self:isWeak(to)
			end
		elseif self:isEnemy(from)
		and self:isEnemy(to)
		then
			return to:getJudgingArea():length()>0
		end
	else
		if self:isFriend(from)
		and self:isFriend(to)
		then
			return self:doDisCard(to,"ej")
		end
	end
end


remember_function('ai_nullification','Mantianguohai',sgs.ai_nullification['Mantianguohai'],{},{})
sgs.ai_skill_cardask["ov_cuijin0"] = function(self,data,pattern)
	local use = data:toCardUse()
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
	local can = #cards>1 and q(cards[1],"getEffectiveId")
	if self:isEnemy(use.from)
	then
		for _,to in sgs.list(use.to)do
			if q(to,"getHandcardNum")<2
			then can = false break end
			if to:objectName()==self.player:objectName()
			then
				local jink = self:getCards("Jink")
				if #jink>0 and q(jink[1],"getEffectiveId")~=can
				then break end
			end
		end
	else
		for _,to in sgs.list(use.to)do
			if q(to,"getHandcardNum")>1
			then can = false break end
			if to:objectName()==self.player:objectName()
			then
				local jink = self:getCards("Jink")
				if #jink>0 and q(jink[1],"getEffectiveId")~=can
				then can = false break end
			end
		end
	end
	return can or "."
end


remember_function('ai_skill_cardask','ov_cuijin0',sgs.ai_skill_cardask['ov_cuijin0'],{},{})
sgs.ai_fill_skill["ov_beini"] = function(self,inclusive,request)
	return policy(self,"#ov_beiniCard:.:")
end


remember_function('ai_fill_skill','ov_beini',sgs.ai_fill_skill['ov_beini'],{},{})
sgs.ai_skill_use_func["#ov_beiniCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard")
	dynamic(self,'ai_skill_invoke','ov_beini',false)
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getHp")>q(self.player,"getHp")
		and (q(ep,"getHandcardNum")<1 or not self:isWeak() or self:getCardsNum("Jink")>0)
		then
			use.card = card
			use.to:append(ep) 
			dynamic(self,'ai_skill_invoke','ov_beini',q(ep,"getHandcardNum")<1)
			return
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		if q(ep,"getHp")>q(self.player,"getHp")
		and q(ep,"getHandcardNum")>1
		and (not self:isWeak() or self:getCardsNum("Jink")>0)
		then
			use.card = card
			use.to:append(ep)
			dynamic(self,'ai_skill_invoke','ov_beini',q(self.player,"getHandcardNum")>3)
			return
		end
	end
	for _,ep in sgs.list(self.room:getAlivePlayers())do
		if q(ep,"getHp")>q(self.player,"getHp")
		and (not self:isWeak() or self:getCardsNum("Jink")>0)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_beiniCard',sgs.ai_skill_use_func['#ov_beiniCard'],{},{})
sgs.ai_use_value.ov_beiniCard = 2.4
sgs.ai_use_priority.ov_beiniCard = 4.8

sgs.ai_skill_invoke.ov_dingfa = function(self,data)
	return true
end


remember_function('ai_skill_invoke','ov_dingfa',sgs.ai_skill_invoke['ov_dingfa'],{},{})
sgs.ai_skill_playerchosen.ov_dingfa = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	return destlist[1]
end

remember_function('ai_skill_playerchosen','ov_dingfa',sgs.ai_skill_playerchosen['ov_dingfa'],{},{})
sgs.ai_playerchosen_intention.ov_dingfa = 55

sgs.ai_skill_choice.ov_dingfa = function(self,choices)
	local items = choices:split("+")
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getHp")<2 then return items[1] end
	end
	return #items>1 and self:isWeak() and items[2] or items[1]
end


remember_function('ai_skill_choice','ov_dingfa',sgs.ai_skill_choice['ov_dingfa'],{},{})
sgs.ai_skill_use["@@ov_zhenjun"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,fp in sgs.list(self.friends_noself)do
		for _,p in sgs.list(siblings(self,true))do
			if self:isEnemy(p) and q(fp,"inMyAttackRange",p)
			then
				return string.format("#ov_zhenjunCard:%s:->%s",q(cards[1],"getEffectiveId"),fp:objectName())
			end
		end
	end
    for _,fp in sgs.list(siblings(self,true))do
		for _,p in sgs.list(siblings(self,true))do
			if not self:isEnemy(fp) and self:isEnemy(p) and q(fp,"inMyAttackRange",p)
			then
				return string.format("#ov_zhenjunCard:%s:->%s",q(cards[1],"getEffectiveId"),fp:objectName())
			end
		end
	end
    for _,fp in sgs.list(siblings(self,true))do
		for _,p in sgs.list(siblings(self,true))do
			if not self:isEnemy(fp) and not self:isFriend(p) and q(fp,"inMyAttackRange",p)
			then
				return string.format("#ov_zhenjunCard:%s:->%s",q(cards[1],"getEffectiveId"),fp:objectName())
			end
		end
	end
end


remember_function('ai_skill_use','@@ov_zhenjun',sgs.ai_skill_use['@@ov_zhenjun'],{},{})
sgs.ai_skill_playerchosen.ov_zhenjun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	return destlist[1]
end

remember_function('ai_skill_playerchosen','ov_zhenjun',sgs.ai_skill_playerchosen['ov_zhenjun'],{},{})
sgs.ai_playerchosen_intention.ov_zhenjun = 55

sgs.ai_fill_skill["ov_weipo"] = function(self,inclusive,request)
	return policy(self,"#ov_weipoCard:.:")
end


remember_function('ai_fill_skill','ov_weipo',sgs.ai_fill_skill['ov_weipo'],{},{})
sgs.ai_skill_use_func["#ov_weipoCard"] = function(card,use,self)
	local slashs = self:getCards("Slash")
	if #slashs>0
	then
		for _,s in sgs.list(slashs)do
			if self:wasPreviouslyPlannedCard(s)
			then table.removeOne(slashs,s) end
		end
		if #slashs>0
		then
			use.card = card
			use.to:append(self.player)
			return
		end
	end
	self.friends_noself = self:sort(self.friends_noself,"handcard",true)
	for _,ep in sgs.list(self.friends_noself)do
		if q(ep,"getHandcardNum")>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_weipoCard',sgs.ai_skill_use_func['#ov_weipoCard'],{},{})
sgs.ai_use_value.ov_weipoCard = 5.4
sgs.ai_use_priority.ov_weipoCard = 3.8

sgs.ai_fill_skill["ov_weipobf"] = function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if q(c,"isKindOf","Slash")
		and not self:wasPreviouslyPlannedCard(c)
		then
			return policy(self,"#ov_weipobfCard:"..q(c,"getEffectiveId")..":")
		end
	end
end


remember_function('ai_fill_skill','ov_weipobf',sgs.ai_fill_skill['ov_weipobf'],{},{})
sgs.ai_skill_use_func["#ov_weipobfCard"] = function(card,use,self)
	for _,ep in sgs.list(self.room:findPlayersBySkillName("ov_weipo"))do
		if q(self.player,"getMark","&ov_weipo+#"..ep:objectName())>0
		and q(self.player,"getMark",ep:objectName().."ov_weipo-PlayClear")<1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_weipobfCard',sgs.ai_skill_use_func['#ov_weipobfCard'],{},{})
sgs.ai_use_value.ov_weipobfCard = 2.4
sgs.ai_use_priority.ov_weipobfCard = 3.8

sgs.ai_skill_cardask["ov_chenshi0"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
	if cards:length()<2 then return "." end
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	local owner = data:toPlayer()
	if not self:isEnemy(owner) then
		return q(cards[1],"getEffectiveId")
	end
end


remember_function('ai_skill_cardask','ov_chenshi0',sgs.ai_skill_cardask['ov_chenshi0'],{},{})
sgs.ai_skill_cardask["ov_chenshi1"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
	if cards:length()<1 then return "." end
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	local owner = data:toPlayer()
	if not self:isEnemy(owner) or self:isWeak() then
		return q(cards[1],"getEffectiveId")
	end
end


remember_function('ai_skill_cardask','ov_chenshi1',sgs.ai_skill_cardask['ov_chenshi1'],{},{})
sgs.ai_can_damagehp.ov_moushi = function(self,from,card,to)
	return card and self:canLoseHp(from,card,to)
	and q(to,"getMark","&ov_moushi+"..q(card,"getSuitString").."_char")>0
end


remember_function('ai_can_damagehp','ov_moushi',sgs.ai_can_damagehp['ov_moushi'],{},{})
function SmartAIView:useCardBinglinchengxia(card,use)
	self.enemies = self:sort(self.enemies,"hp")
	local extraTarget = extra_targets(self,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.enemies)do
		if is_current(use,ep) then continue end
		if can_to(self,card,self.player,ep)
		and self:isGoodTarget(ep,self.enemies,clone(self))
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if is_current(use,ep) then continue end
		if can_to(self,card,self.player,ep) and not self:isFriend(ep)
		and self:isGoodTarget(ep,self.enemies,clone(self))
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end

remember_function('SmartAIView','useCardBinglinchengxia',SmartAIView['useCardBinglinchengxia'],{},{})
sgs.ai_use_priority.Binglinchengxia = 4.4
sgs.ai_keep_value.Binglinchengxia = 4
sgs.ai_use_value.Binglinchengxia = 3.3
sgs.ai_card_intention.Binglinchengxia = 44

sgs.ai_nullification.Binglinchengxia = function(self,trick,from,to,positive)
    local null_num = self:getCardsNum("Nullification")
    if positive
	then
		if self:isFriend(to)
		then
			if null_num>1 then return not to:getArmor()
			else return self:isWeak(to) end
		end
	else
		if self:isFriend(from) and self:isEnemy(to)
		then return self:isWeak(to) end
	end
end


remember_function('ai_nullification','Binglinchengxia',sgs.ai_nullification['Binglinchengxia'],{},{})
sgs.ai_skill_choice.ov_weipo = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"_ov_binglinchengxia")
	then return "_ov_binglinchengxia" end
	for c,cn in sgs.list(items)do
		c = pattern_card(self,cn,nil,true)
		if c and q(c,"isAvailable",self.player)
		then return cn end
	end
end


remember_function('ai_skill_choice','ov_weipo',sgs.ai_skill_choice['ov_weipo'],{},{})
sgs.ai_skill_invoke.ov_fengpo = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_fengpo',sgs.ai_skill_invoke['ov_fengpo'],{},{})
sgs.ai_skill_choice.ov_fengpo = function(self,choices,data)
	local use = data:toCardUse()
	local items = choices:split("+")
	local x = 0
	for _,c in sgs.list(complete_hand(self,use.to:at(0)))do
		if c:isRed() and q(self.player,"getMark","ov_fengpo_deathdamage")>0
		or q(c,"getSuit")==3
		then x = x+1 end
		if q(c,"isKindOf","Jink")
		and q(use.card,"isKindOf","Slash")
		then return items[1] end
	end
	return items[2]
end


remember_function('ai_skill_choice','ov_fengpo',sgs.ai_skill_choice['ov_fengpo'],{},{})
sgs.ai_skill_invoke.ov_moukui = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_moukui',sgs.ai_skill_invoke['ov_moukui'],{},{})
sgs.ai_skill_choice.ov_moukui = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target and not self:isFriend(target)
	and #items>2 then return items[3] end
	return self:isFriend(target) and items[1] or #items>1 and items[2]
end


remember_function('ai_skill_choice','ov_moukui',sgs.ai_skill_choice['ov_moukui'],{},{})
sgs.ai_skill_choice.ov_mouzhu = function(self,choices)
	local items = choices:split("+")
	return self:getCardsNum("Jink")>0 and items[1] or #items>1 and items[2]
end


remember_function('ai_skill_choice','ov_mouzhu',sgs.ai_skill_choice['ov_mouzhu'],{},{})
sgs.ai_fill_skill["ov_mouzhu"] = function(self,inclusive,request)
	return policy(self,"#ov_mouzhuCard:.:")
end


remember_function('ai_fill_skill','ov_mouzhu',sgs.ai_fill_skill['ov_mouzhu'],{},{})
sgs.ai_skill_use_func["#ov_mouzhuCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getHp")>=q(self.player,"getHp")
		and siblings(self,true):length()>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if not self:isFriend(ep)
		and q(ep,"getHp")>=q(self.player,"getHp")
		and siblings(self,true):length()>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_mouzhuCard',sgs.ai_skill_use_func['#ov_mouzhuCard'],{},{})
sgs.ai_use_value.ov_mouzhuCard = 3.4
sgs.ai_use_priority.ov_mouzhuCard = 4.8

sgs.ai_skill_cardask["ov_mouzhu0"] = function(self,data,pattern)
	local owner = data:toPlayer()
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	if self:isFriend(owner) or self:isWeak()
	then
		return #cards>0 and q(cards[1],"getEffectiveId")
	end
end


remember_function('ai_skill_cardask','ov_mouzhu0',sgs.ai_skill_cardask['ov_mouzhu0'],{},{})
sgs.ai_skill_use["@@ov_yanhuo"] = function(self,prompt)
	local valid = {}
	local destlist = siblings(self,true)
	for _,friend in sgs.list(destlist)do
		if #valid>=self.player:getCardCount() then break end
		if not self:isFriend(friend) and friend:getCardCount()>0
		then table.insert(valid,friend:objectName()) end
	end
	if #valid>self.player:getCardCount()/2
	then
    	return string.format("#ov_yanhuoCard:.:->%s",table.concat(valid,"+"))
	end
	valid = {}
	for _,friend in sgs.list(destlist)do
		if self:isEnemy(friend) and friend:getCardCount()>self.player:getCardCount()/2
		then
			table.insert(valid,friend:objectName())
			return string.format("#ov_yanhuoCard:.:->%s",table.concat(valid,"+"))
		end
	end
	for _,friend in sgs.list(destlist)do
		if #valid>=self.player:getCardCount() then break end
		if not self:isFriend(friend) and friend:getCardCount()>0
		then table.insert(valid,friend:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_yanhuoCard:.:->%s",table.concat(valid,"+"))
	end
end


remember_function('ai_skill_use','@@ov_yanhuo',sgs.ai_skill_use['@@ov_yanhuo'],{},{})
sgs.ai_use_revises.ov_shenxing = function(self,card,use)
	if q(card,"isKindOf","DefensiveHorse")
	then return false
	elseif q(card,"isKindOf","OffensiveHorse")
	and (q(self.player,"getHandcardNum")>q(self.player,"getHp") or not self:isWeak())
	then return false end
end


remember_function('ai_use_revises','ov_shenxing',sgs.ai_use_revises['ov_shenxing'],{},{})
sgs.ai_fill_skill["ov_daoji"] = function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if q(c,"getTypeId")~=1
		then
			return policy(self,"#ov_daojiCard:"..q(c,"getEffectiveId")..":")
		end
	end
end


remember_function('ai_fill_skill','ov_daoji',sgs.ai_fill_skill['ov_daoji'],{},{})
sgs.ai_skill_use_func["#ov_daojiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if self:doDisCard(ep,"e")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if self:doDisCard(ep,"he")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if self:doDisCard(ep,"he")
		and not self:isFriend(ep)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_daojiCard',sgs.ai_skill_use_func['#ov_daojiCard'],{},{})
sgs.ai_use_value.ov_daojiCard = 6.4
sgs.ai_use_priority.ov_daojiCard = 4.8

sgs.ai_skill_invoke.ov_hengjiang = function(self,data)
	local use = data:toCardUse()
	local n = 0
    for _,target in sgs.list(self.room:getAllPlayers())do
		if q(self.player,"inMyAttackRange",target)
		and not use.to:contains(target)
		then
			if use.card:isDamageCard()
			then
				if self:isFriend(target)
				then n = n-1 else n = n+1 end
			elseif self:isEnemy(use.to:at(0))
			and self:isEnemy(target)
			then n = n+1 end
		end
	end
	return n>0
end


remember_function('ai_skill_invoke','ov_hengjiang',sgs.ai_skill_invoke['ov_hengjiang'],{},{})
sgs.ai_skill_playerchosen.ov_gezhi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_gezhi',sgs.ai_skill_playerchosen['ov_gezhi'],{},{})
sgs.ai_playerchosen_intention.ov_gezhi = -55

sgs.ai_skill_invoke.ov_yujue = function(self,data)
	local target = data:toPlayer()
	if target
	then
		self["ov_yujue_to_"..target:objectName()] = self:isFriend(target)
		return self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_yujue',sgs.ai_skill_invoke['ov_yujue'],{},{})
sgs.ai_fill_skill["ov_yujuevs"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for n,lh in sgs.list(self.room:findPlayersBySkillName("ov_yujue"))do
		n = 2-q(self.player,"getMark",lh:objectName().."ov_yujue-PlayClear")
		if q(lh,"hasLordSkill","ov_fengqi") and q(self.player,"getKingdom")=="qun" then n = n+2 end
		if n<1 or #cards<1 then continue end
		if self:isFriend(lh,self.player)
		then
			local can = self:getPriorTurnUseCount()>0 and q(self.player,"getMark","ov_yujue2-Clear")<1
			for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
				if q(self.player,"getMark","ov_yujue1-Clear")<1
				and q(self.player,"inMyAttackRange",p)
				and self:doDisCard(p,"hej")
				and not self:isFriend(p)
				then can = true end
			end
			can = can and #cards>3 and (self["ov_yujue_to_"..self.player:objectName()]
							or yujue_mark(self)<1
							or q(self.player,"getHandcardNum")>q(self.player,"getMaxCards") and complete_hand(self,self.player):contains(cards[1]))
			local parse = policy(self,"#ov_yujuevsCard:"..q(cards[1],"getEffectiveId")..":")
			self.ov_yujuevs_to = lh
			assert(parse)
			if can then return parse end
		else
			local PC = self:poisonCards("h")
			if #PC>0
			then
				self.ov_yujuevs_to = lh
				return policy(self,"#ov_yujuevsCard:"..q(PC[1],"getEffectiveId")..":")
			end
		end
	end
end


remember_function('ai_fill_skill','ov_yujuevs',sgs.ai_fill_skill['ov_yujuevs'],{'ov_yujuevs_to'},{'ov_yujuevs_to'})
sgs.ai_skill_use_func["#ov_yujuevsCard"] = function(card,use,self)
	if self.ov_yujuevs_to
	then
		use.card = card
		increment_yujue(self)
		use.to:append(self.ov_yujuevs_to)
	end
end


remember_function('ai_skill_use_func','#ov_yujuevsCard',sgs.ai_skill_use_func['#ov_yujuevsCard'],{'ov_yujuevs_to'},{})
sgs.ai_use_value.ov_yujuevsCard = 5.4
sgs.ai_use_priority.ov_yujuevsCard = 4.8

sgs.ai_skill_invoke.ov_fengqi = function(self,data)
	return true
end


remember_function('ai_skill_invoke','ov_fengqi',sgs.ai_skill_invoke['ov_fengqi'],{},{})
sgs.ai_skill_cardask["ov_gezhi0"] = function(self,data,pattern)
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	return #cards>1 and q(cards[1],"getEffectiveId")
	or #cards>0 and self:getKeepValue(cards[1])<3 and q(cards[1],"getEffectiveId")
end


remember_function('ai_skill_cardask','ov_gezhi0',sgs.ai_skill_cardask['ov_gezhi0'],{},{})
sgs.ai_skill_invoke.ov_lingfa = function(self,data)
	return true
end


remember_function('ai_skill_invoke','ov_lingfa',sgs.ai_skill_invoke['ov_lingfa'],{},{})
sgs.ai_skill_cardask["ov_lingfa1"] = function(self,data,pattern)
	local owner = data:toPlayer()
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
	if self:canDamageHp(owner) and not self:isWeak() then return "." end
	return #cards>0 and q(cards[1],"getEffectiveId") or "."
end


remember_function('ai_skill_cardask','ov_lingfa1',sgs.ai_skill_cardask['ov_lingfa1'],{},{})
sgs.ai_skill_cardask["ov_lingfa2"] = function(self,data,pattern)
	local owner = data:toPlayer()
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	if self:canDamageHp(owner) and not self:isWeak() then return "." end
	if self:isFriend(owner) or self:isWeak()
	then
		return #cards>0 and q(cards[1],"getEffectiveId") or "."
	end
end


remember_function('ai_skill_cardask','ov_lingfa2',sgs.ai_skill_cardask['ov_lingfa2'],{},{})
sgs.ai_skill_invoke.ov_zhian = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_zhian',sgs.ai_skill_invoke['ov_zhian'],{},{})
sgs.ai_skill_choice.ov_zhian = function(self,choices,data)
	local use = data:toCardUse()
	local items = choices:split("+")
	if self:isEnemy(use.from)
	then
		if self:isWeak(use.from)
		then return items[#items]
		elseif q(use.card,"isKindOf","DelayedTrick")
		and self:isFriend(use.to:at(0))
		and q(self.player,"getHandcardNum")>2
		then return items[2]
		elseif q(use.card,"isKindOf","EquipCard")
		and q(self.player,"getHandcardNum")>2
		then return items[2] end
	elseif not self:isFriend(use.from)
	and q(use.card,"isKindOf","DelayedTrick")
	and self:isFriend(use.to:at(0))
	then return items[2] end
	return items[1]
end


remember_function('ai_skill_choice','ov_zhian',sgs.ai_skill_choice['ov_zhian'],{},{})
sgs.ai_skill_cardask["ov_fengji0"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
  	for n,c in sgs.list(cards)do
		n = self:getRestCardsNum(q(c,"getClassName"))
		if n>1
		then
			n = n>3 and 3 or n
			dynamic(self,'ai_skill_choice','shifa',"shifa"..math.random(1,n))
			return q(c,"getEffectiveId")
		end
	end
end


remember_function('ai_skill_cardask','ov_fengji0',sgs.ai_skill_cardask['ov_fengji0'],{},{})
sgs.ai_skill_invoke.ov_budao = function(self,data)
	return q(self.player,"getLostHp")>1
end


remember_function('ai_skill_invoke','ov_budao',sgs.ai_skill_invoke['ov_budao'],{},{})
sgs.ai_skill_playerchosen.ov_budao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_budao',sgs.ai_skill_playerchosen['ov_budao'],{},{})
sgs.ai_playerchosen_intention.ov_budao = -55

sgs.ai_fill_skill["ov_sfzhouhu"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
   	for i,c in sgs.list(cards)do
		local n = q(self.player,"getLostHp")
		if c:isRed() and i<=#cards/2 and n>0
		then
			n = n>3 and 3 or n
			dynamic(self,'ai_skill_choice','shifa',"shifa"..n)
			return policy(self,"#ov_sfzhouhuCard:"..q(c,"getEffectiveId")..":")
		end
	end
   	for i,c in sgs.list(cards)do
		if c:isRed() and i<=#cards/2
		then
			local n = q(self.player,"getLostHp")
			local to = self.player:getNextAlive()
			while to:objectName()~=self.player:objectName()do
				if self:isEnemy(to)
				and math.random()>0.5
				then n = n+1 end
				to = to:getNextAlive()
			end
			n = n>3 and 3 or n
			n = n>q(self.player,"getHp") and q(self.player,"getHp") or n
			n = n==1 and not q(self.player,"isWounded") and n-1 or n
			dynamic(self,'ai_skill_choice','shifa',"shifa"..n)
			return n>0 and policy(self,"#ov_sfzhouhuCard:"..q(c,"getEffectiveId")..":")
		end
	end
end


remember_function('ai_fill_skill','ov_sfzhouhu',sgs.ai_fill_skill['ov_sfzhouhu'],{},{})
sgs.ai_skill_use_func["#ov_sfzhouhuCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_sfzhouhuCard',sgs.ai_skill_use_func['#ov_sfzhouhuCard'],{},{})
sgs.ai_use_value.ov_sfzhouhuCard = 3.4
sgs.ai_use_priority.ov_sfzhouhuCard = -0.8

sgs.ai_fill_skill["ov_sffengqi"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
   	for i,c in sgs.list(cards)do
		if c:isBlack() and i<#cards/2
		then
			local n = q(self.player,"getLostHp")
			local to = self.player:getNextAlive()
			while to:objectName()~=self.player:objectName()do
				if self:isEnemy(to)
				and math.random()>0.5
				then n = n+1 end
				to = to:getNextAlive()
			end
			n = n>3 and 3 or n<1 and math.random(1,3) or n
			n = n>q(self.player,"getHp") and q(self.player,"getHp") or n
			dynamic(self,'ai_skill_choice','shifa',"shifa"..n)
			return policy(self,"#ov_sffengqiCard:"..q(c,"getEffectiveId")..":")
		end
	end
end


remember_function('ai_fill_skill','ov_sffengqi',sgs.ai_fill_skill['ov_sffengqi'],{},{})
sgs.ai_skill_use_func["#ov_sffengqiCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_sffengqiCard',sgs.ai_skill_use_func['#ov_sffengqiCard'],{},{})
sgs.ai_use_value.ov_sffengqiCard = 3.4
sgs.ai_use_priority.ov_sffengqiCard = -0.8

sgs.ai_fill_skill["ov_sffengqi"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
   	for i,c in sgs.list(cards)do
		if q(c,"getTypeId")~=1 and i<=#cards/2
		then
			local n = q(self.player,"getLostHp")
			local to = self.player:getNextAlive()
			while to:objectName()~=self.player:objectName()do
				if self:isEnemy(to)
				and math.random()>0.5
				then n = n+1 end
				to = to:getNextAlive()
			end
			n = n>3 and 3 or n<1 and math.random(1,3) or n
			n = n>q(self.player,"getHp") and q(self.player,"getHp") or n
			dynamic(self,'ai_skill_choice','shifa',"shifa"..n)
			return policy(self,"#ov_sffengqiCard:"..q(c,"getEffectiveId")..":")
		end
	end
end


remember_function('ai_fill_skill','ov_sffengqi',sgs.ai_fill_skill['ov_sffengqi'],{},{})
sgs.ai_skill_use_func["#ov_sffengqiCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_sffengqiCard',sgs.ai_skill_use_func['#ov_sffengqiCard'],{},{})
sgs.ai_use_value.ov_sffengqiCard = 3.4
sgs.ai_use_priority.ov_sffengqiCard = -0.8

sgs.ai_fill_skill["ov_gongqi"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
  	for i,c in sgs.list(cards)do
		for it,ct in sgs.list(self:getPriorTurnUseCards())do
			if q(c,"getEffectiveId")~=q(ct,"getEffectiveId")
			and q(c,"getSuit")==q(ct,"getSuit")
			and q(ct,"isKindOf","Slash")
			then
				return policy(self,"#ov_gongqiCard:"..q(c,"getEffectiveId")..":")
			end
		end
	end
  	for i,c in sgs.list(cards)do
		if q(c,"isKindOf","EquipCard")
		and #self.enemies>0
		and i<#cards/2
		then
			return policy(self,"#ov_gongqiCard:"..q(c,"getEffectiveId")..":")
		end
	end
end


remember_function('ai_fill_skill','ov_gongqi',sgs.ai_fill_skill['ov_gongqi'],{},{})
sgs.ai_skill_use_func["#ov_gongqiCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_gongqiCard',sgs.ai_skill_use_func['#ov_gongqiCard'],{},{})
sgs.ai_use_value.ov_gongqiCard = 3.4
sgs.ai_use_priority.ov_gongqiCard = 3.8

sgs.ai_skill_playerchosen.ov_gongqi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"e")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target,"e")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target,"he")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and self:doDisCard(target,"e")
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_gongqi',sgs.ai_skill_playerchosen['ov_gongqi'],{},{})
sgs.ai_playerchosen_intention.ov_gongqi = 55

sgs.ai_fill_skill["ov_jiefan"] = function(self,inclusive,request)
	return policy(self,"#ov_jiefanCard:.:")
end


remember_function('ai_fill_skill','ov_jiefan',sgs.ai_fill_skill['ov_jiefan'],{},{})
sgs.ai_skill_use_func["#ov_jiefanCard"] = function(card,use,self)
	self.friends = self:sort(self.friends,"hp")
	for n,ep in sgs.list(self.friends)do
		n = 0
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if q(p,"inMyAttackRange",ep)
			then n = n+1 end
		end
		if n>#self.friends/2
		and n>q(ep,"getHp")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_jiefanCard',sgs.ai_skill_use_func['#ov_jiefanCard'],{},{})
sgs.ai_use_value.ov_jiefanCard = 4.4
sgs.ai_use_priority.ov_jiefanCard = 4.8

sgs.ai_fill_skill["ov_fuzuan"] = function(self,inclusive,request)
	return policy(self,"#ov_fuzuanCard:.:")
end


remember_function('ai_fill_skill','ov_fuzuan',sgs.ai_fill_skill['ov_fuzuan'],{},{})
sgs.ai_skill_use_func["#ov_fuzuanCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard",true)
	self.friends = self:sort(self.friends,"hp")
	if self:getPriorTurnUseCards()
	then
		for d,c in sgs.list(self:getPriorTurnUseCards())do
			if q(c,"isKindOf","Slash")
			then
				d = self:aiUseCard(c)
				if d.card and d.to
				then
					for i,to in sgs.list(d.to)do
						if not q(to,"hasSkill","ov_feifu") then continue end
						i = to:getChangeSkillState("ov_feifu")
						if i<2 or to:getCardCount()<1 then continue end
						use.card = card
						use.to:append(to)
						return
					end
				end
			end
		end
		for _,ep in sgs.list(self.enemies)do
			if not q(ep,"hasSkill","ov_feifu") then continue end
			i = ep:getChangeSkillState("ov_feifu")
			if i<2 or ep:getCardCount()<1 then continue end
			use.card = card
			use.to:append(ep)
			return
		end
		for _,ep in sgs.list(self.friends)do
			if not q(ep,"hasSkill","ov_feifu") then continue end
			i = ep:getChangeSkillState("ov_feifu")
			if i>1 then continue end
			use.card = card
			use.to:append(ep)
			return
		end
		for d,c in sgs.list(self:getPriorTurnUseCards())do
			if q(c,"isKindOf","Slash")
			then
				d = self:aiUseCard(c)
				if d.card and d.to
				then
					for i,to in sgs.list(d.to)do
						if not q(to,"hasSkill","ov_feifu") then continue end
						i = to:getChangeSkillState("ov_feifu")
						if i<2 then continue end
						use.card = card
						use.to:append(to)
						return
					end
				end
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if not q(ep,"hasSkill","ov_feifu") then continue end
		i = ep:getChangeSkillState("ov_feifu")
		if i<2 or ep:getCardCount()<1 then continue end
		use.card = card
		use.to:append(ep)
		return
	end
	for _,ep in sgs.list(self.friends)do
		if not q(ep,"hasSkill","ov_feifu") then continue end
		i = ep:getChangeSkillState("ov_feifu")
		if i>1 then continue end
		use.card = card
		use.to:append(ep)
		return
	end
	for _,ep in sgs.list(self.enemies)do
		if not q(ep,"hasSkill","ov_feifu") then continue end
		i = ep:getChangeSkillState("ov_feifu")
		if i<2 then continue end
		use.card = card
		use.to:append(ep)
		return
	end
end


remember_function('ai_skill_use_func','#ov_fuzuanCard',sgs.ai_skill_use_func['#ov_fuzuanCard'],{},{})
sgs.ai_use_value.ov_fuzuanCard = 2.4
sgs.ai_use_priority.ov_fuzuanCard = 3.8

sgs.ai_skill_use["@@ov_fuzuan"] = function(self,prompt)
	local destlist = self.room:getAlivePlayers()
    destlist = self:sort(destlist,"hp")
	for n,p in sgs.list(destlist)do
		if not q(p,"hasSkill","ov_feifu") then continue end
		n = p:getChangeSkillState("ov_feifu")
		if self:isEnemy(p) and n>1
		then return string.format("#ov_fuzuanCard:.:->%s",p:objectName()) end
	end
	for n,p in sgs.list(destlist)do
		if not q(p,"hasSkill","ov_feifu") then continue end
		n = p:getChangeSkillState("ov_feifu")
		if self:isFriend(p) and n<2
		then return string.format("#ov_fuzuanCard:.:->%s",p:objectName()) end
	end
	for n,p in sgs.list(destlist)do
		if not q(p,"hasSkill","ov_feifu") then continue end
		n = p:getChangeSkillState("ov_feifu")
		if not self:isFriend(p) and n<2
		or self:isFriend(p) and n>1
		then continue end
		return string.format("#ov_fuzuanCard:.:->%s",p:objectName())
	end
end


remember_function('ai_skill_use','@@ov_fuzuan',sgs.ai_skill_use['@@ov_fuzuan'],{},{})
sgs.ai_skill_invoke.ov_congqi = function(self,data)
	return #self.friends_noself>0
end


remember_function('ai_skill_invoke','ov_congqi',sgs.ai_skill_invoke['ov_congqi'],{},{})
sgs.ai_skill_playerchosen.ov_congqi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

remember_function('ai_skill_playerchosen','ov_congqi',sgs.ai_skill_playerchosen['ov_congqi'],{},{})
sgs.ai_playerchosen_intention.ov_congqi = -55

sgs.ai_skill_choice.ov_fuzuan = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"ov_feifu")
	then return "ov_feifu" end
end


remember_function('ai_skill_choice','ov_fuzuan',sgs.ai_skill_choice['ov_fuzuan'],{},{})
sgs.ai_skill_invoke.ov_zhenxi = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
		and target:getCardCount()>0
	end
end


remember_function('ai_skill_invoke','ov_zhenxi',sgs.ai_skill_invoke['ov_zhenxi'],{},{})
sgs.ai_skill_choice.ov_zhenxi = function(self,choices)
	local items = choices:split("+")
	if #items>2 then return items[3] end
end


remember_function('ai_skill_choice','ov_zhenxi',sgs.ai_skill_choice['ov_zhenxi'],{},{})
sgs.ai_skill_use["@@ov_kaiji"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAllPlayers()
    destlist = self:sort(destlist,"hp")
	for _,p in sgs.list(destlist)do
		if #valid>=q(self.player,"getMark","ov_kaiji") then break end
		if self:isFriend(p) then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>q(self.player,"getMark","ov_kaiji")/2 then break end
		if not self:isEnemy(p) and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_kaijiCard:.:->%s",table.concat(valid,"+"))
	end
end


remember_function('ai_skill_use','@@ov_kaiji',sgs.ai_skill_use['@@ov_kaiji'],{},{})
sgs.ai_skill_invoke.ov_shepan = function(self,data)
	local target = data:toPlayer()
	if target then return true end
	local use = tag(self,"ov_shepan","CardUse")
	if use and use.card
	then
		if use.card:isDamageCard()
		then return true
		elseif use.to:contains(use.from)
		then return false
		elseif self:isEnemy(use.from)
		then return true end
	end
end


remember_function('ai_skill_invoke','ov_shepan',sgs.ai_skill_invoke['ov_shepan'],{},{})
sgs.ai_skill_choice.ov_shepan = function(self,choices,data)
	local items = choices:split("+")
	local use = data:toCardUse()
	if self:isFriend(use.from)
	then
		if self:doDisCard(use.from,"ej")
		then return items[2]
		elseif use.card:isDamageCard()
		and self:isWeak()
		then
			local n = q(use.from,"getHandcardNum")-q(self.player,"getHandcardNum")
			if n==1 then return items[2] end
		end
	else
		if self:doDisCard(use.from,"ej")
		then return items[2]
		elseif use.card:isDamageCard()
		then
			local n = q(use.from,"getHandcardNum")-q(self.player,"getHandcardNum")
			if n==1 then return items[2] end
		end
	end
	return items[1]
end


remember_function('ai_skill_choice','ov_shepan',sgs.ai_skill_choice['ov_shepan'],{},{})
sgs.ai_skill_use["@@ov_fenghan"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAllPlayers()
    destlist = self:sort(destlist,"hp")
	for _,p in sgs.list(destlist)do
		if #valid>=q(self.player,"getMark","ov_fenghan") then break end
		if self:isFriend(p)
		then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>=q(self.player,"getMark","ov_fenghan") then break end
		if not self:isEnemy(p)
		and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_fenghanCard:.:->%s",table.concat(valid,"+"))
	end
end


remember_function('ai_skill_use','@@ov_fenghan',sgs.ai_skill_use['@@ov_fenghan'],{},{})
sgs.ai_skill_playerchosen.ov_congji = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_congji',sgs.ai_skill_playerchosen['ov_congji'],{},{})
sgs.ai_playerchosen_intention.ov_congji = -55

sgs.ai_guhuo_card.ov_yingji = function(self,toname,class_name)
	if q(self.player,"getPhase")==sgs.Player_NotActive
	and self.player:isKongcheng()
	then
        local c = clone(self,toname)
		if q(c,"getTypeId")==1 or c:isNDTrick()
	    then
           	return "#ov_yingjiCard:.:"..toname
        end
	end
end


remember_function('ai_guhuo_card','ov_yingji',sgs.ai_guhuo_card['ov_yingji'],{},{})
sgs.ai_skill_invoke.ov_shanghe = function(self,data)
	return self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<1
end


remember_function('ai_skill_invoke','ov_shanghe',sgs.ai_skill_invoke['ov_shanghe'],{},{})
sgs.ai_skill_invoke.ov_jieyu = function(self,data)
	return self.room:getDiscardPile():length()>q(self.player,"getHandcardNum")
	and self:getCardsNum("Peach")<1
end


remember_function('ai_skill_invoke','ov_jieyu',sgs.ai_skill_invoke['ov_jieyu'],{},{})
sgs.ai_fill_skill["ov_sidai"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
	local fs = clone(self,"slash")
	fs = mutate(self,fs,"skill","ov_sidai")
  	for i,c in sgs.list(cards)do
		if q(c,"getTypeId")==1
		then fs = mutate(self,fs,"add",c) end
	end
  	local d = self:aiUseCard(fs)
	if d.card and d.to
	and fs:subcardsLength()>1
	then
		for i,to in sgs.list(d.to)do
			if q(to,"getHandcardNum")<2
			then return fs end
		end
	end
end


remember_function('ai_fill_skill','ov_sidai',sgs.ai_fill_skill['ov_sidai'],{},{})
sgs.ai_skill_cardask["ov_sidai0"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		i = self:getCards("Jink")
		if q(c,"getTypeId")==1 and #i>0
		and q(i[1],"getEffectiveId")~=q(c,"getEffectiveId")
		then return q(c,"getEffectiveId") end
	end
end



remember_function('ai_skill_cardask','ov_sidai0',sgs.ai_skill_cardask['ov_sidai0'],{},{})
sgs.ai_skill_invoke.ov_shigong = function(self,data)
	return #self.friends>0
	and self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<1
end


remember_function('ai_skill_invoke','ov_shigong',sgs.ai_skill_invoke['ov_shigong'],{},{})
sgs.ai_fill_skill["ov_zhuidu"] = function(self,inclusive,request)
	return policy(self,"#ov_zhuiduCard:.:")
end


remember_function('ai_fill_skill','ov_zhuidu',sgs.ai_fill_skill['ov_zhuidu'],{},{})
sgs.ai_skill_use_func["#ov_zhuiduCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getHp")<=q(self.enemies[1],"getHp")
		and self:doDisCard(ep,"e")
		and q(ep,"isWounded")
		and ep:isFemale()
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"isWounded")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.room:getAlivePlayers())do
		if not self:isFriend(ep)
		and q(ep,"isWounded")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_zhuiduCard',sgs.ai_skill_use_func['#ov_zhuiduCard'],{},{})
sgs.ai_use_value.ov_zhuiduCard = 4.4
sgs.ai_use_priority.ov_zhuiduCard = 1.8

sgs.ai_skill_choice.ov_zhuidu = function(self,choices)
	local items = choices:split("+")
	if #items>2 then return items[3] end
	return items[1]
end


remember_function('ai_skill_choice','ov_zhuidu',sgs.ai_skill_choice['ov_zhuidu'],{},{})
sgs.ai_skill_playerchosen.ov_xiongzheng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	destlist = self:sort(destlist,"hp",true)
	return not self:isWeak(destlist[1])
	and #self.enemies>0
	and destlist[1]
end

remember_function('ai_skill_playerchosen','ov_xiongzheng',sgs.ai_skill_playerchosen['ov_xiongzheng'],{},{})
sgs.ai_playerchosen_intention.ov_xiongzheng = 55

sgs.ai_skill_use["@@ov_xiongzheng"] = function(self,prompt)
	local valid1,valid2 = {},{}
	local destlist = self.room:getAllPlayers()
    destlist = self:sort(destlist,"hp")
	local to = tag(self,"ov_xiongzheng","Player")
	for _,p in sgs.list(destlist)do
		if self:isFriend(p)
		and q(p,"getMark","&ov_xiongzheng+damage+#"..to:objectName())>0
		then table.insert(valid1,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if table.contains(valid1,p:objectName())
		then continue end
		if not self:isEnemy(p) and #valid1<#destlist/2
		and q(p,"getMark","&ov_xiongzheng+damage+#"..to:objectName())>0
		then table.insert(valid1,p:objectName()) end
	end
	for d,p in sgs.list(destlist)do
		d = clone(self)
		d = mutate(self,d,"skill","_ov_xiongzheng")
		if table.contains(valid2,p:objectName())
		then continue end
		if self.player:isProhibited(p,d) then continue end
		if self:isEnemy(p) and q(p,"getMark","&ov_xiongzheng+damage+#"..to:objectName())<1
		then table.insert(valid2,p:objectName()) end
	end
	for d,p in sgs.list(destlist)do
		d = clone(self)
		d = mutate(self,d,"skill","_ov_xiongzheng")
		if table.contains(valid2,p:objectName())
		then continue end
		if self.player:isProhibited(p,d)
		or #valid2>=#destlist/2 or self:isFriend(p)
		or q(p,"getMark","&ov_xiongzheng+damage+#"..to:objectName())>0
		then continue end
		table.insert(valid2,p:objectName())
	end
	valid1 = #valid1>#valid2 and valid1 or valid2
	if #valid1>0
	then
    	return string.format("#ov_xiongzhengCard:.:->%s",table.concat(valid1,"+"))
	end
end


remember_function('ai_skill_use','@@ov_xiongzheng',sgs.ai_skill_use['@@ov_xiongzheng'],{},{})
sgs.ai_fill_skill["ov_luannianvs"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for i,owner in sgs.list(self.room:findPlayersBySkillName("ov_luannian"))do
		local toids,to = {},foreign_tag(self,owner,"ov_xiongzheng","Player")
		if not q(owner,"hasLordSkill","ov_luannian")
		or q(owner,"getMark","ov_luannian-PlayClear")>0
		or not to or not self:isEnemy(to)
		then continue end
		for _,tc in sgs.list(cards)do
			if #toids>=q(owner,"getMark","&ov_luannian_lun") then break end
			table.insert(toids,q(tc,"getEffectiveId"))
		end
		self.ov_luannian_to = owner
		if #toids<=q(to,"getHp")
		then return policy(self,"#ov_luannianCard:"..table.concat(toids,"+")..":") end
	end
end


remember_function('ai_fill_skill','ov_luannianvs',sgs.ai_fill_skill['ov_luannianvs'],{'ov_luannian_to'},{'ov_luannian_to'})
sgs.ai_skill_use_func["#ov_luannianCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp")
	if self.ov_luannian_to
	then
		use.card = card
		use.to:append(self.ov_luannian_to)
	end
end


remember_function('ai_skill_use_func','#ov_luannianCard',sgs.ai_skill_use_func['#ov_luannianCard'],{'ov_luannian_to'},{})
sgs.ai_use_value.ov_luannianCard = 2.4
sgs.ai_use_priority.ov_luannianCard = 1.8

sgs.ai_skill_cardask["ov_qingtao0"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
  	for n,c in sgs.list(cards)do
		if q(c,"getTypeId")~=1 or q(c,"isKindOf","Analeptic")
		then return q(c,"getEffectiveId") end
	end
	return #cards>1 and q(cards[1],"getEffectiveId") or "."
end


remember_function('ai_skill_cardask','ov_qingtao0',sgs.ai_skill_cardask['ov_qingtao0'],{},{})
sgs.ai_fill_skill["ov_bingde"] = function(self,inclusive,request)
	local can = self:getPriorTurnUseCount()<2
	local suits = {"spade","club","heart","diamond","no_suit"}
	for _,s in sgs.list(suits)do
		if q(self.player,"getMark",s.."no_bingde-PlayClear")<1
		and q(self.player,"getMark",s.."ov_bingde-PlayClear")>0
		then can = can and true end
	end
	if not can then return end
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
  	for s,c in sgs.list(cards)do
		s = q(c,"getSuitString")
		if q(self.player,"getMark",s.."ov_bingde-PlayClear")>1
		and q(self.player,"getMark",s.."no_bingde-PlayClear")<1
		then
			self.ov_bingde_choice = s
			return policy(self,"#ov_bingdeCard:"..q(c,"getEffectiveId")..":")
		end
	end
  	for s,c in sgs.list(cards)do
		s = q(c,"getSuitString")
		if q(self.player,"getMark",s.."ov_bingde-PlayClear")>0
		and q(self.player,"getMark",s.."no_bingde-PlayClear")<1
		then
			self.ov_bingde_choice = s
			return policy(self,"#ov_bingdeCard:"..q(c,"getEffectiveId")..":")
		end
	end
	for _,s in sgs.list(suits)do
		if #cards>2 and q(self.player,"getMark",s.."no_bingde-PlayClear")<1
		and q(self.player,"getMark",s.."ov_bingde-PlayClear")>0
		then
			self.ov_bingde_choice = s
			return policy(self,"#ov_bingdeCard:"..q(cards[1],"getEffectiveId")..":")
		end
	end
end


remember_function('ai_fill_skill','ov_bingde',sgs.ai_fill_skill['ov_bingde'],{'ov_bingde_choice'},{'ov_bingde_choice'})
sgs.ai_skill_use_func["#ov_bingdeCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_bingdeCard',sgs.ai_skill_use_func['#ov_bingdeCard'],{},{})
sgs.ai_use_value.ov_bingdeCard = 5.4
sgs.ai_use_priority.ov_bingdeCard = 2.8

sgs.ai_skill_choice.ov_bingde = function(self,choices)
	local items = choices:split("+")
  	for _,pm in sgs.list(items)do
		if self.ov_bingde_choice==pm
		then return pm end
	end
  	for _,pm in sgs.list(items)do
		if q(self.player,"getMark",pm.."ov_bingde-PlayClear")>1
		then return pm end
	end
  	for _,pm in sgs.list(items)do
		if q(self.player,"getMark",pm.."ov_bingde-PlayClear")>0
		then return pm end
	end
end


remember_function('ai_skill_choice','ov_bingde',sgs.ai_skill_choice['ov_bingde'],{'ov_bingde_choice'},{'ov_bingde_choice'})
sgs.ai_fill_skill["ov_xiongsi"] = function(self,inclusive,request)
	local slash = clone(self)
	slash = mutate(self,slash,"skill","ov_xiongsi")
	self.ov_xiongsi_to = nil
	if q(slash,"isAvailable",self.player)
	then
		local use = {to=sgs.SPlayerList(),current_targets={},isDummy=true}
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if q(p,"getMark","ov_xiongsi")>0 then table.insert(use.current_targets,p) end
		end
		local d = self:aiUseCard(slash,use)
		if d.card and d.to
		then
			for _,to in sgs.list(d.to)do
				if q(to,"getMark","ov_xiongsi")<1
				then
					self.ov_xiongsi_to = to
					break
				end
			end
		end
	end
	return self.ov_xiongsi_to and policy(self,"#ov_xiongsiCard:.:")
end


remember_function('ai_fill_skill','ov_xiongsi',sgs.ai_fill_skill['ov_xiongsi'],{'ov_xiongsi_to'},{'ov_xiongsi_to'})
sgs.ai_skill_use_func["#ov_xiongsiCard"] = function(card,use,self)
	if self.ov_xiongsi_to
	then
		use.card = card
		use.to:append(self.ov_xiongsi_to)
	end
end


remember_function('ai_skill_use_func','#ov_xiongsiCard',sgs.ai_skill_use_func['#ov_xiongsiCard'],{'ov_xiongsi_to'},{})
sgs.ai_use_value.ov_xiongsiCard = 2.4
sgs.ai_use_priority.ov_xiongsiCard = 1.8

sgs.ai_skill_playerchosen.ov_linglu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and q(target,"getHandcardNum")<3
		then return target end
	end
	destlist = self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and q(target,"getHandcardNum")>3
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_linglu',sgs.ai_skill_playerchosen['ov_linglu'],{},{})
sgs.ai_playerchosen_intention.ov_linglu = 55

sgs.ai_skill_invoke.ov_linglu = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_linglu',sgs.ai_skill_invoke['ov_linglu'],{},{})
sgs.ai_skill_playerchosen.ov_juntun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
	local dying = self.room:getCurrentDyingPlayer()
    for _,target in sgs.list(destlist)do
		if not q(target,"hasSkill","ov_xiongjun")
		and (not dying or dying:objectName()~=target:objectName())
		and self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not q(target,"hasSkill","ov_xiongjun")
		and (not dying or dying:objectName()~=target:objectName())
		and not self:isEnemy(target)
		then return target end
	end
end


remember_function('ai_skill_playerchosen','ov_juntun',sgs.ai_skill_playerchosen['ov_juntun'],{},{})
sgs.ai_fill_skill["ov_xiongxi"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	local toids = {}
	local n = 5-q(self.player,"getMark","@ov_baonieNum")
  	for _,c in sgs.list(cards)do
		if #toids>=n then break end
		table.insert(toids,q(c,"getEffectiveId"))
	end
	return n<4 and #toids>=n and policy(self,"#ov_xiongxiCard:"..table.concat(toids,"+")..":")
end


remember_function('ai_fill_skill','ov_xiongxi',sgs.ai_fill_skill['ov_xiongxi'],{},{})
sgs.ai_skill_use_func["#ov_xiongxiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getMark","ov_xiongxi-Clear")<1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_xiongxiCard',sgs.ai_skill_use_func['#ov_xiongxiCard'],{},{})
sgs.ai_use_value.ov_xiongxiCard = 2.4
sgs.ai_use_priority.ov_xiongxiCard = 1.8

sgs.ai_skill_invoke.ov_xiafeng = function(self,data)
	local bn = tag(self,"ov_baonieNum","Int")
	if bn<1 then return end
	bn = bn>3 and 3 or bn
  	for _,c in sgs.list(self.player:getCards("h"))do
		if c:isDamageCard()
		then
			if q(c,"getTypeId")==1
			or q(c,"isKindOf","AOE")
			or q(c,"isKindOf","SingleTargetTrick")
			then
				self:setPriorityValue(q(c,"getClassName"),self:getSourcePriorityValue(q(c,"getClassName"))+5,"OverseasVersion")
				self:writeOverseasXiafengFlag(c,true)
			end
		end
	end
	return self:withOwnerRange("InfinityAttackRange","ov_xiafeng",function()
	local touse,_,unknown = self:getTurnUse();if unknown then error(unknown,0)end
	local n = 0
	for i=1,bn do
		if #touse>=i and touse[i]:isDamageCard()
		then n = n+1 end
	end
	n = n<2 and q(self.player,"getHandcardNum")>q(self.player,"getMaxCards") and math.random(1,bn) or n
  	for _,c in sgs.list(self.player:getCards("h"))do
		self:writeOverseasXiafengFlag(c,false)
	end
	-- End of native owner-range hypothesis; source trailing choice write remains in the same closure.
	dynamic(self,'ai_skill_choice','ov_xiafeng',""..n)
	return n>1
 end)
end


remember_function('ai_skill_invoke','ov_xiafeng',sgs.ai_skill_invoke['ov_xiafeng'],{},{})
sgs.ai_use_revises.ov_xiafeng = function(self,card,use)
	if q(self.player,"getMark","ov_xiafeng-Clear")>0
	then
		if card:isDamageCard()
		then
			if q(card,"getTypeId")==1 or q(card,"isKindOf","AOE") or q(card,"isKindOf","SingleTargetTrick")
			then self:setPriorityValue(q(card,"getClassName"),self:getSourcePriorityValue(q(card,"getClassName"))+5,"OverseasVersion") end
		elseif q(card,"isKindOf","EquipCard")
		then return false end
	end
end


remember_function('ai_use_revises','ov_xiafeng',sgs.ai_use_revises['ov_xiafeng'],{},{})
sgs.ai_skill_choice.ov_zhengjian = function(self,choices)
	local items = choices:split("+")
	if #items>1 and math.random(1,5)>=#items
	then return items[2] end
	return items[1]
end


remember_function('ai_skill_choice','ov_zhengjian',sgs.ai_skill_choice['ov_zhengjian'],{},{})
sgs.ai_skill_invoke.ov_zhengjian = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
	return math.random(1,5)<3
end


remember_function('ai_skill_invoke','ov_zhengjian',sgs.ai_skill_invoke['ov_zhengjian'],{},{})
sgs.ai_guhuo_card.ov_zhuitingvs = function(self,toname,class_name)
    local handcards = self:addHandPile()
    handcards = self:sortByKeepValue(handcards,nil,true) -- 按保留值排序
	for _,p in sgs.list(siblings(self,true))do
		if (q(self.player,"getKingdom")=="qun" or q(self.player,"getKingdom")=="wei")
		and q(p,"hasLordSkill","ov_zhuiting")
		and class_name=="Nullification"
		and q(p,"getMark","ov_zhuiting")>0
		then
			for c,h in sgs.list(handcards)do
				if q(h,"getColor")==q(p,"getMark","ov_zhuiting")-1
				then
					c = clone(self,toname)
					c = mutate(self,c,"skill","ov_zhuiting")
					c = mutate(self,c,"add",h)
					return c:getLegacyStringKey()
				end
			end
		end
	end
end


remember_function('ai_guhuo_card','ov_zhuitingvs',sgs.ai_guhuo_card['ov_zhuitingvs'],{},{})
sgs.ai_skill_invoke.ov_niju = function(self,data)
	self.ov_niju_choice = 1
	local pindian = data:toPindian()
	local qun = self.room:getLieges("qun",self.player):length()
	if pindian.from:objectName()==self.player:objectName()
	then
		if self:isFriend(pindian.to)
		then
			if pindian.from_number>pindian.to_number
			then
				dynamic(self,'ai_skill_askforag','ov_niju',q(pindian.to_card,"getEffectiveId"))
				if pindian.from_number<=pindian.to_number+qun
				then return true end
				self.ov_niju_choice = 2
				dynamic(self,'ai_skill_askforag','ov_niju',q(pindian.from_card,"getEffectiveId"))
				if pindian.from_number-qun<=pindian.to_number
				then return true end
			end
		else
			if pindian.from_number<=pindian.to_number
			then
				dynamic(self,'ai_skill_askforag','ov_niju',q(pindian.from_card,"getEffectiveId"))
				if pindian.from_number+qun>=pindian.to_number
				then return true end
				self.ov_niju_choice = 2
				dynamic(self,'ai_skill_askforag','ov_niju',q(pindian.to_card,"getEffectiveId"))
				if pindian.from_number>=pindian.to_number-qun
				then return true end
			end
		end
	else
		if self:isFriend(pindian.from)
		then
			if pindian.from_number<=pindian.to_number
			then
				dynamic(self,'ai_skill_askforag','ov_niju',q(pindian.from_card,"getEffectiveId"))
				if pindian.from_number+qun>pindian.to_number
				then return true end
				self.ov_niju_choice = 2
				dynamic(self,'ai_skill_askforag','ov_niju',q(pindian.to_card,"getEffectiveId"))
				if pindian.from_number>pindian.to_number-qun
				then return true end
			end
		else
			if pindian.from_number>pindian.to_number
			then
				dynamic(self,'ai_skill_askforag','ov_niju',q(pindian.to_card,"getEffectiveId"))
				if pindian.from_number<=pindian.to_number+qun
				then return true end
				self.ov_niju_choice = 2
				dynamic(self,'ai_skill_askforag','ov_niju',q(pindian.from_card,"getEffectiveId"))
				if pindian.from_number-qun<=pindian.to_number
				then return true end
			end
		end
	end
end


remember_function('ai_skill_invoke','ov_niju',sgs.ai_skill_invoke['ov_niju'],{'ov_niju_choice'},{'ov_niju_choice'})
sgs.ai_skill_choice.ov_niju = function(self,choices)
	local items = choices:split("+")
	if self.ov_niju_choice then return items[self.ov_niju_choice] end
	return items[1]
end


remember_function('ai_skill_choice','ov_niju',sgs.ai_skill_choice['ov_niju'],{'ov_niju_choice'},{})
sgs.ai_skill_discard.ov_chongwang = function(self)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local to = tag(self,"ov_chongwang","Player")
	if self:getCardsNum("AOE")>1 and self:isFriend(to)
	then table.insert(to_cards,q(cards[1],"getEffectiveId"))
	elseif self:isEnemy(to) and q(to,"getHandcardNum")>3
	and q(to,"inMyAttackRange",self.player) and self:isWeak()
	then table.insert(to_cards,q(cards[1],"getEffectiveId")) end
 	return to_cards
end


remember_function('ai_skill_discard','ov_chongwang',sgs.ai_skill_discard['ov_chongwang'],{},{})
sgs.ai_fill_skill["ov_juxiangvs"] = function(self,inclusive,request)
	local cards = self.player:getCards("e")
	cards = self:sortByKeepValue(cards)
	for i,owner in sgs.list(self.room:findPlayersBySkillName("ov_juxiang"))do
		if q(owner,"getMark","ov_juxiang-PlayClear")>0
		or not q(owner,"hasLordSkill","ov_juxiang")
		or q(self.player,"getKingdom")~="qun"
		or not self:isFriend(owner)
		then continue end
		i = nil
		local function can_juxiang(n)
			local x = 0
			for _,h in sgs.list(self.player:getCards("h"))do
				if q(h,"getTypeId")~=3 then continue end
				local e = h:getRealCard():toEquipCard():location()
				if e==n then x = x+1 end
			end
			return x
		end
		self.ov_juxiang_to = owner
		for _,tc in sgs.list(cards)do
			if i then break end
			local e = tknown(c:getEquipSlot(),"source equipment slot")
			if owner:hasEquipArea(e) then continue end
			i = q(tc,"getEffectiveId")
		end
		for c,tc in sgs.list(cards)do
			if i then break end
			local e = tknown(c:getEquipSlot(),"source equipment slot")
			c = equip(self,owner,e)
			if c and self:evaluateArmor(c,owner)>-5 then continue end
			if can_juxiang(e)>0 or self:isWeak(owner)
			then i = q(tc,"getEffectiveId") end
		end
		if i
		then
			return policy(self,"#ov_juxiangCard:"..i..":")
		end
	end
end


remember_function('ai_fill_skill','ov_juxiangvs',sgs.ai_fill_skill['ov_juxiangvs'],{'ov_juxiang_to'},{'ov_juxiang_to'})
sgs.ai_skill_use_func["#ov_juxiangCard"] = function(card,use,self)
	if self.ov_juxiang_to
	then
		use.card = card
		use.to:append(self.ov_juxiang_to)
	end
end


remember_function('ai_skill_use_func','#ov_juxiangCard',sgs.ai_skill_use_func['#ov_juxiangCard'],{'ov_juxiang_to'},{})
sgs.ai_use_value.ov_juxiangCard = 2.4
sgs.ai_use_priority.ov_juxiangCard = 5.8

sgs.ai_fill_skill["ov_shijunvs"] = function(self,inclusive,request)
	for i,owner in sgs.list(self.room:findPlayersBySkillName("ov_shijun"))do
		if q(owner,"getMark","ov_shijun-PlayClear")>0
		or not q(owner,"hasLordSkill","ov_shijun")
		or owner:getPile("rice"):length()>0
		or self.player:getNextAlive()==owner
		or q(self.player,"getKingdom")~="qun"
		or self:isEnemy(owner)
		then continue end
		self.ov_shijun_to = owner
		return policy(self,"#ov_shijunCard:.:")
	end
end


remember_function('ai_fill_skill','ov_shijunvs',sgs.ai_fill_skill['ov_shijunvs'],{'ov_shijun_to'},{'ov_shijun_to'})
sgs.ai_skill_use_func["#ov_shijunCard"] = function(card,use,self)
	if self.ov_shijun_to
	then
		use.card = card
		use.to:append(self.ov_shijun_to)
	end
end


remember_function('ai_skill_use_func','#ov_shijunCard',sgs.ai_skill_use_func['#ov_shijunCard'],{'ov_shijun_to'},{})
sgs.ai_use_value.ov_shijunCard = 2.4
sgs.ai_use_priority.ov_shijunCard = 4.8

sgs.ai_skill_use["@@ov_polu"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAllPlayers()
    destlist = self:sort(destlist,"hp")
	for _,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_poluCard:.:->%s",table.concat(valid,"+"))
	end
end


remember_function('ai_skill_use','@@ov_polu',sgs.ai_skill_use['@@ov_polu'],{},{})
sgs.ai_skill_use["@@ov_dingzhen"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAllPlayers()
    destlist = self:sort(destlist,"hp")
	for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		and q(self.player,"distanceTo",p)<=q(self.player,"getHp")
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_dingzhenCard:.:->%s",table.concat(valid,"+"))
	end
end


remember_function('ai_skill_use','@@ov_dingzhen',sgs.ai_skill_use['@@ov_dingzhen'],{},{})
sgs.ai_skill_askforyiji.ov_youye = function(self,card_ids,tos)
	local to = self.room:getCurrent()
	local cards = list_i2c(self,card_ids)
	cards = self:sortByKeepValue(cards,self:isFriend(to))
	if q(self.player,"hasFlag","Current")
	then return to,q(cards[1],"getEffectiveId") end
	local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to then return to,id end
	return self.player,q(cards[1],"getEffectiveId")
end


remember_function('ai_skill_askforyiji','ov_youye',sgs.ai_skill_askforyiji['ov_youye'],{},{})
sgs.ai_can_damagehp.ov_youye = function(self,from,card,to)
	local target = self.room:getCurrent()
	return self:canLoseHp(from,trick,to)
	and to:getPile("ov_xu"):length()>3
	and self:isFriend(target) and self:isFriend(to)
	and q(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
end


remember_function('ai_can_damagehp','ov_youye',sgs.ai_can_damagehp['ov_youye'],{},{})
sgs.ai_skill_cardask["ov_dingzhen1"] = function(self,data,pattern)
	local to = data:toPlayer()
	return self:isEnemy(to) and q(self.player,"inMyAttackRange",to)
	and self:getCardsNum("Slash")>math.random(0,2)
end


remember_function('ai_skill_cardask','ov_dingzhen1',sgs.ai_skill_cardask['ov_dingzhen1'],{},{})
sgs.ai_skill_use["@@ov_qingkou"] = function(self,prompt)
	local duel = clone(self,"duel")
	duel = mutate(self,duel,"skill","ov_qingkou")
	local d = self:aiUseCard(duel)
	if d.card and d.to
	then
		local tos = {}
		for _,p in sgs.list(d.to)do
			table.insert(tos,p:objectName())
		end
		return duel:getLegacyStringKey().."->"..table.concat(tos,"+")
	end
end


remember_function('ai_skill_use','@@ov_qingkou',sgs.ai_skill_use['@@ov_qingkou'],{},{})
sgs.ai_skill_invoke.ov_juchen = function(self,data)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for i,c in sgs.list(cards)do
		if i<=#cards/2 and c:isRed()
		then return true end
	end
	return #cards>1 and cards[1]:isRed()
end


remember_function('ai_skill_invoke','ov_juchen',sgs.ai_skill_invoke['ov_juchen'],{},{})
sgs.ai_skill_discard.ov_juchen = function(self)
	local to = self.room:getCurrent()
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for i,c in sgs.list(cards)do
		if i<=#cards/2 and c:isRed() and self:isFriend(to)
		then return {q(c,"getEffectiveId")} end
	end
	for i,c in sgs.list(cards)do
		if i<=#cards/2 and not c:isRed() and self:isEnemy(to)
		then return {q(c,"getEffectiveId")} end
	end
 	return {q(cards[1],"getEffectiveId")}
end


remember_function('ai_skill_discard','ov_juchen',sgs.ai_skill_discard['ov_juchen'],{},{})
sgs.ai_fill_skill["ov_xingzhui"] = function(self,inclusive,request)
	if not self:isWeak()
	and #self.enemies>0
	then
		local n = q(self.player,"getLostHp")-self:getCardsNum("Peach")
		local to = self.player:getNextAlive()
		while to:objectName()~=self.player:objectName()do
			if self:isEnemy(to)
			and math.random()>0.5
			then n = n+1 end
			to = to:getNextAlive()
		end
		n = n>3 and 3 or n<1 and math.random(1,3) or n
		n = n>q(self.player,"getHp") and q(self.player,"getHp") or n
		dynamic(self,'ai_skill_choice','shifa',"shifa"..n)
		return policy(self,"#ov_xingzhuiCard:.:")
	end
end


remember_function('ai_fill_skill','ov_xingzhui',sgs.ai_fill_skill['ov_xingzhui'],{},{})
sgs.ai_skill_use_func["#ov_xingzhuiCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_xingzhuiCard',sgs.ai_skill_use_func['#ov_xingzhuiCard'],{},{})
sgs.ai_use_value.ov_xingzhuiCard = 3.4
sgs.ai_use_priority.ov_xingzhuiCard = 0.8

sgs.ai_skill_playerchosen.ov_xingzhui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	if q(self.player,"getMark","ov_xingzhui_num")>=q(self.player,"getMark","ov_xingzhui_x") then
		for _,target in sgs.list(destlist)do
			if self:isEnemy(target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not self:isFriend(target)
			then return target end
		end
	else
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not self:isEnemy(target)
			then return target end
		end
	end
	return destlist[1]
end


remember_function('ai_skill_playerchosen','ov_xingzhui',sgs.ai_skill_playerchosen['ov_xingzhui'],{},{})
sgs.ai_skill_invoke.ov_jiekuang = function(self,data)
	local target = data:toPlayer()
	local use = tag(self,"ov_jiekuang","CardUse")
	if target and self:isWeak(target)
	and self:isFriend(target)
	then
		return use.card:isDamageCard()
		or self:isEnemy(use.from)
	end
end


remember_function('ai_skill_invoke','ov_jiekuang',sgs.ai_skill_invoke['ov_jiekuang'],{},{})
sgs.ai_skill_choice.ov_jiekuang = function(self,choices)
	local items = choices:split("+")
	if q(self.player,"isWounded") then return items[2] end
	return items[1]
end


remember_function('ai_skill_choice','ov_jiekuang',sgs.ai_skill_choice['ov_jiekuang'],{},{})
sgs.ai_fill_skill["ov_luanlve"] = function(self,inclusive,request)
	local snatch = clone(self,"snatch")
	snatch = mutate(self,snatch,"skill","ov_luanlve")
	local n = q(self.player,"getMark","&ov_luanlve")
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for i,c in sgs.list(cards)do
		if snatch:subcardsLength()>=n then break end
		if q(c,"isKindOf","Slash") then snatch = mutate(self,snatch,"add",c) end
	end
	self.ov_luanlve_to = nil
	if q(snatch,"isAvailable",self.player)
	and snatch:subcardsLength()>=n
	then
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if q(p,"getMark","ov_luanlve-PlayClear")>0
			then self:setStrategyMemory("OverseasVersion.aiNoTo:"..p:objectName(),true) end
		end
		n = self:aiUseCard(snatch)
		if n.card and n.to
		then
			for _,to in sgs.list(n.to)do
				if q(to,"getMark","ov_luanlve-PlayClear")<1
				then self.ov_luanlve_to = to break end
			end
		end
	end
	n = table.concat(sgs.QList2Table(snatch:getSubcards()),"+")
	return self.ov_luanlve_to and policy(self,"#ov_luanlveCard:"..n..":")
end


remember_function('ai_fill_skill','ov_luanlve',sgs.ai_fill_skill['ov_luanlve'],{'ov_luanlve_to'},{'ov_luanlve_to'})
sgs.ai_skill_use_func["#ov_luanlveCard"] = function(card,use,self)
	if self.ov_luanlve_to
	then
		use.card = card
		use.to:append(self.ov_luanlve_to)
	end
end


remember_function('ai_skill_use_func','#ov_luanlveCard',sgs.ai_skill_use_func['#ov_luanlveCard'],{'ov_luanlve_to'},{})
sgs.ai_use_value.ov_luanlveCard = 2.4
sgs.ai_use_priority.ov_luanlveCard = 4.8

sgs.ai_fill_skill["ov_jichou"] = function(self,inclusive,request)
	for _,p in sgs.list(source_patterns(self))do
		if q(self.player,"getMark","ov_jichou_"..p)>0 then continue end
		local c = clone(self,p)
		if c and c:isNDTrick() and q(c,"isAvailable",self.player)
		and self:getCardsNum(q(c,"getClassName"))<1 then
			c = mutate(self,c,"skill","ov_jichou")
			local d = self:aiUseCard(c)
			if d.card then
				self.ov_jichouUse = d
				self.ov_zhengjianChoice = "ov_jichou-Clear"
				if q(c,"canRecast") and d.to:length()<1 then continue end
				self:setPriorityValue("ov_jichouCard",self:getSourcePriorityValue(q(c,"getClassName")),"OverseasVersion")
				return policy(self,"#ov_jichouCard:.:")
			end
		end
	end
	self:setPriorityValue("ov_jichouCard",-1.8,"OverseasVersion")
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if #self.friends_noself>0
		and q(self.player,"getMark","ov_jichoucard-PlayClear")<1
		and q(self.player,"getMark","ov_jichou_"..c:objectName())>0 then
			self.ov_zhengjianChoice = "ov_jichoucard-PlayClear"
			return policy(self,"#ov_jichouCard:.:")
		end
	end
end


remember_function('ai_fill_skill','ov_jichou',sgs.ai_fill_skill['ov_jichou'],{'ov_jichouUse','ov_zhengjianChoice'},{'ov_jichouUse','ov_zhengjianChoice'})
sgs.ai_skill_use_func["#ov_jichouCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_jichouCard',sgs.ai_skill_use_func['#ov_jichouCard'],{},{})
sgs.ai_use_value.ov_jichouCard = 2.4
sgs.ai_use_priority.ov_jichouCard = -1.8

sgs.ai_skill_choice.ov_jichou = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,self.ov_zhengjianChoice)
	then return self.ov_zhengjianChoice end
	if table.contains(items,self.ov_jichouUse.card:objectName())
	then return self.ov_jichouUse.card:objectName() end
end


remember_function('ai_skill_choice','ov_jichou',sgs.ai_skill_choice['ov_jichou'],{'ov_jichouUse','ov_zhengjianChoice'},{})
sgs.ai_skill_use["@@ov_jichou"] = function(self,prompt)
	local cd = self.ov_jichouUse
	if cd.card then
		local tos = {}
		for _,p in sgs.list(cd.to)do
			table.insert(tos,p:objectName())
		end
		return cd.card:getLegacyStringKey().."->"..table.concat(tos,"+")
	end
end


remember_function('ai_skill_use','@@ov_jichou',sgs.ai_skill_use['@@ov_jichou'],{'ov_jichouUse'},{})
sgs.ai_guhuo_card.ov_jichou = function(self,toname,class_name)
	if q(self.player,"getMark","ov_jichou_"..toname)<1
	and q(self.player,"getMark","ov_jichou-Clear")<1 then
        local c = clone(self,toname)
		if c and c:isNDTrick() and self:getCardsNum(class_name)<1
	    then return "#ov_jichoucard:.:"..toname end
	end
end


remember_function('ai_guhuo_card','ov_jichou',sgs.ai_guhuo_card['ov_jichou'],{},{})
sgs.ai_skill_playerchosen.ov_jichou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

remember_function('ai_skill_playerchosen','ov_jichou',sgs.ai_skill_playerchosen['ov_jichou'],{},{})
sgs.ai_playerchosen_intention.ov_jichou = -55

sgs.ai_skill_invoke.ov_jilun = function(self,data)
	return #self.friends>0
end


remember_function('ai_skill_invoke','ov_jilun',sgs.ai_skill_invoke['ov_jilun'],{},{})
sgs.ai_skill_choice.ov_jilun = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"ov_jilun2") then
		local n = items[1]:split("=")[2]
		n = n-0
		n = n*1.7
		for _,p in sgs.list(source_patterns(self))do
			if q(self.player,"getMark","ov_jichou_"..p)<1
			or q(self.player,"getMark","ov_jilun_"..p)>0
			then continue end
			local c = clone(self,p)
			if c and c:isNDTrick()
			and q(c,"isAvailable",self.player) then
				c = mutate(self,c,"skill","_ov_jilun")
				self.ov_jichou_cn = p
				local d = self:aiUseCard(c)
				if d.card and self:getUseValue(c)>n then
					if q(c,"canRecast") and d.to:length()<1 then continue end
					self.ov_jichouUse = d
					return "ov_jilun2"
				end
			end
		end
		return items[1]
	elseif table.contains(items,self.ov_jichou_cn)
	then return self.ov_jichou_cn end
end


remember_function('ai_skill_choice','ov_jilun',sgs.ai_skill_choice['ov_jilun'],{'ov_jichouUse','ov_jichou_cn'},{'ov_jichouUse','ov_jichou_cn'})
sgs.ai_skill_use["@@ov_fenwu"] = function(self,prompt)
	local duel = clone(self)
	duel = mutate(self,duel,"skill","ov_fenwu")
	local d = self:aiUseCard(duel)
	local names = tag(self,"ov_fenwu","String"):split("+")
	if d.card and d.to:length()>0 and math.random(0,#names)>0
	and q(self.player,"getHp")+self:getCardsNum("Peach")+self:getCardsNum("Analeptic")>1
	then
		local tos = {}
		for _,p in sgs.list(d.to)do
			table.insert(tos,p:objectName())
		end
		return duel:getLegacyStringKey().."->"..table.concat(tos,"+")
	end
end


remember_function('ai_skill_use','@@ov_fenwu',sgs.ai_skill_use['@@ov_fenwu'],{},{})
sgs.ai_skill_invoke.ov_fupan = function(self,data)
	local to = data:toString()
	if to~=""
	then
		local n = 0
		to = BeMan(self.room,to:split(":")[2])
		for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
			if not self:isEnemy(ep) then n = n+1 end
		end
		if to
		then
			return self:isEnemy(to)
			and (self:isWeak(to) or n<1)
		end
	end
	return #self.friends>0
end


remember_function('ai_skill_invoke','ov_fupan',sgs.ai_skill_invoke['ov_fupan'],{},{})
sgs.ai_skill_askforyiji.ov_fupan = function(self,card_ids,tos)
	local cards = list_i2c(self,card_ids)
	cards = self:sortByKeepValue(cards)
	self.enemies = self:sort(self.enemies,"hp")
    for _,ep in sgs.list(self.enemies)do
		if q(ep,"getMark","ov_fupan_damage_"..self.player:objectName())<1
		and self:getKeepValue(cards[1])<4 and self:isWeak(ep)
		then return ep,q(cards[1],"getEffectiveId") end
	end
	local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to and q(to,"getMark","ov_fupan_damage_"..self.player:objectName())<1
	and to:objectName()~=self.player:objectName()
	then return to,id end
	to = self.room:getOtherPlayers(self.player)
	to = self:sort(to,"handcard")
    for _,ep in sgs.list(to)do
		if not self:isEnemy(ep)
		and q(ep,"getMark","ov_fupan_"..self.player:objectName())<1
		then return ep,q(cards[1],"getEffectiveId") end
	end
    for _,ep in sgs.list(to)do
		if #cards>4 and q(ep,"getMark","ov_fupan_"..self.player:objectName())<1
		and q(ep,"getMark","ov_fupan_damage_"..self.player:objectName())<1
		then return ep,q(cards[1],"getEffectiveId") end
	end
	self.friends_noself = self:sort(self.friends_noself,"handcard")
    for _,ep in sgs.list(self.friends_noself)do
		if q(ep,"getMark","ov_fupan_damage_"..self.player:objectName())<1
		then return ep,q(cards[1],"getEffectiveId") end
	end
    for _,ep in sgs.list(to)do
		if not self:isEnemy(ep)
		and q(ep,"getMark","ov_fupan_damage_"..self.player:objectName())<1
		then return ep,q(cards[1],"getEffectiveId") end
	end
    for _,ep in sgs.list(to)do
		if q(ep,"getMark","ov_fupan_damage_"..self.player:objectName())<1
		then return ep,q(cards[1],"getEffectiveId") end
	end
end


remember_function('ai_skill_askforyiji','ov_fupan',sgs.ai_skill_askforyiji['ov_fupan'],{},{})
sgs.ai_can_damagehp.ov_fupan = function(self,from,card,to)
    for _,ep in sgs.list(self.enemies)do
		if q(ep,"getMark","ov_fupan_damage_"..to:objectName())<1
		and self:isWeak(ep) and self:canLoseHp(from,card,to) and self:isFriend(to)
		and q(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
		then return true end
	end
end


remember_function('ai_can_damagehp','ov_fupan',sgs.ai_can_damagehp['ov_fupan'],{},{})
sgs.ai_fill_skill["ov_mutao"] = function(self,inclusive,request)
	return policy(self,"#ov_mutaoCard:.:")
end


remember_function('ai_fill_skill','ov_mutao',sgs.ai_fill_skill['ov_mutao'],{},{})
sgs.ai_skill_use_func["#ov_mutaoCard"] = function(card,use,self)
	local n = self:getCardsNum("Slash")
	if n>0
	then
		local to = self.player:getNextAlive(n)
		if self:isEnemy(to)
		then
			use.card = card
			use.to:append(self.player)
			return
		end
	end
	self.enemies = self:sort(self.enemies,"handcard",true)
	for _,ep in sgs.list(self.enemies)do
		if q(ep,"getHp")>=q(self.player,"getHp")
		and q(ep,"getHandcardNum")>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	n = self.room:getAlivePlayers()
	n = self:sort(n,"handcard",true)
	for _,ep in sgs.list(n)do
		if q(ep,"getHp")>=q(self.player,"getHp")
		and q(ep,"getHandcardNum")>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(n)do
		if q(ep,"getHandcardNum")>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_mutaoCard',sgs.ai_skill_use_func['#ov_mutaoCard'],{},{})
sgs.ai_use_value.ov_mutaoCard = 3.4
sgs.ai_use_priority.ov_mutaoCard = 2.8

sgs.ai_skill_invoke.ov_yimou = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_yimou',sgs.ai_skill_invoke['ov_yimou'],{},{})
sgs.ai_skill_choice.ov_yimou = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if #items>2 and self:isWeak(target)
	and not self:isWeak()
	then return items[3] end
	if #items>1 and #self.friends>1
	then return items[2] end
end


remember_function('ai_skill_choice','ov_yimou',sgs.ai_skill_choice['ov_yimou'],{},{})
sgs.ai_skill_playerchosen.ov_yimou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

remember_function('ai_skill_playerchosen','ov_yimou',sgs.ai_skill_playerchosen['ov_yimou'],{},{})
sgs.ai_playerchosen_intention.ov_yimou = -55

sgs.ai_fill_skill["ov_kujian"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if #toids>=3 or #toids>=#cards/2 then break end
		for _,ep in sgs.list(self.friends_noself)do
			if q(c,"isAvailable",ep)
			then
				table.insert(toids,q(c,"getEffectiveId"))
				break
			end
		end
	end
	if #toids<1 and #cards>2 and #self.friends_noself>0
	then table.insert(toids,q(cards[1],"getEffectiveId")) end
	return #toids>0 and policy(self,"#ov_kujianCard:"..table.concat(toids,"+")..":")
end


remember_function('ai_fill_skill','ov_kujian',sgs.ai_fill_skill['ov_kujian'],{},{})
sgs.ai_skill_use_func["#ov_kujianCard"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself,"handcard",true)
	for _,ep in sgs.list(self.friends_noself)do
		if q(ep,"getHandcardNum")<5
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		use.card = card
		use.to:append(ep)
		return
	end
end


remember_function('ai_skill_use_func','#ov_kujianCard',sgs.ai_skill_use_func['#ov_kujianCard'],{},{})
sgs.ai_use_value.ov_kujianCard = 3.4
sgs.ai_use_priority.ov_kujianCard = -1.8

sgs.ai_skill_playerchosen.ov_ruilian = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and q(target,"getHandcardNum")>2
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and q(target,"getHandcardNum")>0
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_ruilian',sgs.ai_skill_playerchosen['ov_ruilian'],{},{})
sgs.ai_playerchosen_intention.ov_ruilian = -55

sgs.ai_skill_invoke.ov_ruilian = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isEnemy(target)
	end
end


remember_function('ai_skill_invoke','ov_ruilian',sgs.ai_skill_invoke['ov_ruilian'],{},{})
sgs.ai_skill_invoke.ov_jiaohua = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_jiaohua',sgs.ai_skill_invoke['ov_jiaohua'],{},{})
sgs.ai_skill_playerchosen.ov_tanfeng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if (self:getCardsNum("Jink")>0 or not self:isWeak())
		and self:doDisCard(target,"ej")
		and self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if (self:getCardsNum("Jink")>0 or not self:isWeak())
		and self:doDisCard(target,"ej")
		and self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target)
		and self:getCardsNum("Jink")>0
		then return target end
	end
end


remember_function('ai_skill_playerchosen','ov_tanfeng',sgs.ai_skill_playerchosen['ov_tanfeng'],{},{})
sgs.ai_skill_choice.ov_tanfeng = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items,"Player_Judge")
	then
		if self:isFriend(target)
		then
			if self:doDisCard(target,"j")
			then return "Player_Judge"
			elseif table.contains(items,"Player_Discard")
			then return "Player_Discard"
			elseif table.contains(items,"Player_Finish")
			then return "Player_Finish" end
		elseif table.contains(items,"Player_Play")
		then return "Player_Play"
		elseif table.contains(items,"Player_Draw")
		then return "Player_Draw"
		elseif table.contains(items,"Player_Finish")
		then return "Player_Finish" end
	end
	if self:canDamageHp(target)
	and not self:isWeak()
	then return items[1] end
	return items[2]
end


remember_function('ai_skill_choice','ov_tanfeng',sgs.ai_skill_choice['ov_tanfeng'],{},{})
sgs.ai_skill_invoke.ov_xiawei = function(self,data)
	local n = self.player:getCardCount()
	n = n<2 and 2 or n
	n = math.random(1,n)
	n = n>4 and 4 or n
	dynamic(self,'ai_skill_choice','wangxing',""..n)
	return n>0
end


remember_function('ai_skill_invoke','ov_xiawei',sgs.ai_skill_invoke['ov_xiawei'],{},{})
sgs.ai_card_priority.ov_xiawei = function(self,card)
	return self.player:getPile("&ov_wei"):contains(q(card,"getEffectiveId")) and 0.5
end


remember_function('ai_card_priority','ov_xiawei',sgs.ai_card_priority['ov_xiawei'],{},{})
sgs.ai_skill_discard.wangxing = function(self,x,n,optional,include_equip)
	local todn = tag(self,"wangxing_ai","String")
	local toids = sgs.ai_skill_discard[todn.."_wangxing"]
	if type(toids)=="function"
	then
		toids = toids(self,x,n,optional,include_equip)
		if type(toids)=="table" then return #toids>=n and toids or {} end
	end
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	toids = {}
	for i,c in sgs.list(cards)do
		if #toids>=n then break end
		table.insert(toids,q(c,"getEffectiveId"))
	end
 	return #toids>=n and toids or {}
end


remember_function('ai_skill_discard','wangxing',sgs.ai_skill_discard['wangxing'],{},{})
sgs.ai_skill_playerchosen.ov_jianwei = function(self,players)
	local mc = self:getMaxCard()
	if not mc or q(mc,"getNumber")+q(self.player,"getAttackRange")<9 then return end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"e")
		and self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"he")
		and self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"e")
		and self:doDisCard(target,"j")
		and self:isFriend(target)
		then return target end
	end
end


remember_function('ai_skill_playerchosen','ov_jianwei',sgs.ai_skill_playerchosen['ov_jianwei'],{},{})
sgs.ai_skill_playerchosen.ov_jianweibf = function(self,players)
	local mc = self:getMaxCard()
	if not mc or q(mc,"getNumber")<10 then return end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if target:getWeapon()
		and self:isEnemy(target)
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_jianweibf',sgs.ai_skill_playerchosen['ov_jianweibf'],{},{})
sgs.ai_playerchosen_intention.ov_jianweibf = 55

sgs.ai_fill_skill["ov_jiange"] = function(self,inclusive,request)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for c,h in sgs.list(cards)do
		if q(h,"getTypeId")~=1
		then
			c = clone(self)
			c = mutate(self,c,"skill","ov_jiange")
			c = mutate(self,c,"add",h)
			if q(c,"isAvailable",self.player)
			then return c end
		end
	end
end


remember_function('ai_fill_skill','ov_jiange',sgs.ai_fill_skill['ov_jiange'],{},{})
sgs.ai_guhuo_card.ov_jiange = function(self,toname,class_name)
	if class_name=="Slash"
	and q(self.player,"getMark","ov_jiange-Clear")<1
	then
		local cards = self:addHandPile("he")
		cards = self:sortByKeepValue(cards,nil,true)
		for c,h in sgs.list(cards)do
			if q(h,"getTypeId")~=1
			then
				c = clone(self)
				c = mutate(self,c,"skill","ov_jiange")
				c = mutate(self,c,"add",h)
				return c:getLegacyStringKey()
			end
		end
	end
end


remember_function('ai_guhuo_card','ov_jiange',sgs.ai_guhuo_card['ov_jiange'],{},{})
sgs.ai_card_priority.ov_jiange = function(self,card)
	if table.contains(card:getSkillNames(), "ov_jiange") then
		if q(self.player,"getPhase")==sgs.Player_NotActive
		then return 1 else return -1 end
	end
end


remember_function('ai_card_priority','ov_jiange',sgs.ai_card_priority['ov_jiange'],{},{})
sgs.ai_skill_playerchosen.ov_chuanshu = function(self,players)
	local mc = self:getMaxCard()
	if mc and q(mc,"getNumber")+3>10 and #self.enemies>0
	then return self.player end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if q(target,"getHandcardNum")>2
		and self:isFriend(target)
		then return target end
	end
	return self.player
end

remember_function('ai_skill_playerchosen','ov_chuanshu',sgs.ai_skill_playerchosen['ov_chuanshu'],{},{})
sgs.ai_playerchosen_intention.ov_chuanshu = -55

sgs.ai_fill_skill["ov_chaofeng"] = function(self,inclusive,request)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for _,h in sgs.list(cards)do
		if q(h,"isKindOf","Jink")
		then
			for c,pn in sgs.list(source_patterns(self))do
				c = clone(self,pn)
				if c and q(c,"isKindOf","Slash")
				then
					c = mutate(self,c,"skill","ov_chaofeng")
					c = mutate(self,c,"add",h)
					if q(c,"isAvailable",self.player)
					and self:aiUseCard(c).card
					then return c end
				end
			end
		end
	end
end


remember_function('ai_fill_skill','ov_chaofeng',sgs.ai_fill_skill['ov_chaofeng'],{},{})
sgs.ai_guhuo_card.ov_chaofeng = function(self,toname,class_name)
	if class_name=="Slash"
	then
		local cards = self:addHandPile("he")
		cards = self:sortByKeepValue(cards,nil,true)
		for c,h in sgs.list(cards)do
			if q(h,"isKindOf","Jink")
			then
				c = clone(self,toname)
				c = mutate(self,c,"skill","ov_chaofeng")
				c = mutate(self,c,"add",h)
				return c:getLegacyStringKey()
			end
		end
	elseif class_name=="Jink"
	then
		local cards = self:addHandPile("he")
		cards = self:sortByKeepValue(cards,nil,true)
		for c,h in sgs.list(cards)do
			if q(h,"isKindOf","Slash")
			then
				c = clone(self,toname)
				c = mutate(self,c,"skill","ov_chaofeng")
				c = mutate(self,c,"add",h)
				return c:getLegacyStringKey()
			end
		end
	end
end


remember_function('ai_guhuo_card','ov_chaofeng',sgs.ai_guhuo_card['ov_chaofeng'],{},{})
sgs.ai_skill_use["@@ov_chaofeng"] = function(self,prompt)
	local valid = {}
	self.ov_chaofeng_card = nil
	local mc = self:getMaxCard()
	local destlist = self.room:getOtherPlayers(self.player)
    destlist = self:sort(destlist,"handcard")
	local n = q(self.player,"getMark","&ov_chuanshu+#"..self.player:objectName())>0 and mc and q(mc,"getNumber")+3 or mc and q(mc,"getNumber") or 0
	for _,p in sgs.list(destlist)do
		if #valid>=3 then break end
		if q(self.player,"canPindian",p) and self:isFriend(p)
		and q(p,"getMark","&ov_chuanshu+#"..self.player:objectName())>0
		and #self.enemies>0 and (#valid>0 or q(self.player,"canPindian",self.enemies[1]))
		then
			table.insert(valid,p:objectName())
			self.ov_chaofeng_card = self:getMinCard()
		end
		if self:isEnemy(p) and q(self.player,"canPindian",p)
		then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>1 then break end
		if not self:isFriend(p)
		and q(self.player,"canPindian",p)
		and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0 and (n>10 or self.ov_chaofeng_card)
	then
    	return string.format("#ov_chaofengCard:.:->%s",table.concat(valid,"+"))
	end
end


remember_function('ai_skill_use','@@ov_chaofeng',sgs.ai_skill_use['@@ov_chaofeng'],{'ov_chaofeng_card'},{'ov_chaofeng_card'})
sgs.ai_skill_pindian.ov_chaofeng = function(card,self,requestor,maxcard,mincard)
	if self:isFriend(requestor)
	then return maxcard end
end


remember_function('ai_skill_pindian','ov_chaofeng',sgs.ai_skill_pindian['ov_chaofeng'],{},{})
sgs.ai_skill_playerchosen.ov_lvren = function(self,players)
	local use = tag(self,"ov_lvren","CardUse")
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:canCanmou(target,use)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and self:canCanmou(target,use)
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_lvren',sgs.ai_skill_playerchosen['ov_lvren'],{},{})
sgs.ai_playerchosen_intention.ov_lvren = 55

sgs.ai_skill_use["@@ov_zhenhu!"] = function(self,prompt)
	local valid = {}
	local destlist = siblings(self,true)
    destlist = self:sort(destlist,"handcard")
	for _,p in sgs.list(destlist)do
		if #valid>=3 then break end
		if self:isEnemy(p) and q(self.player,"canPindian",p)
		then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>1 then break end
		if not self:isFriend(p) and q(self.player,"canPindian",p)
		and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>0 then break end
		if q(self.player,"canPindian",p)
		and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_zhenhuCard:.:->%s",table.concat(valid,"+"))
	end
end


remember_function('ai_skill_use','@@ov_zhenhu!',sgs.ai_skill_use['@@ov_zhenhu!'],{},{})
sgs.ai_skill_invoke.ov_zhenhu = function(self,data)
	local valid = {}
	local mc = self:getMaxCard()
	local destlist = siblings(self,true)
    destlist = self:sort(destlist,"handcard")
	for _,p in sgs.list(destlist)do
		if #valid>=3 then break end
		if self:isEnemy(p) and q(self.player,"canPindian",p)
		then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>=3 then break end
		if not self:isFriend(p)
		and q(self.player,"canPindian",p)
		and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	local n = mc and q(self.player,"hasSkill","ov_lvren") and q(mc,"getNumber")+(#valid*2) or mc and q(mc,"getNumber") or 0
	n = n<1 and math.random(4,7)+(#valid*2) or n
	return #valid>0 and n>10
end


remember_function('ai_skill_invoke','ov_zhenhu',sgs.ai_skill_invoke['ov_zhenhu'],{},{})
sgs.ai_skill_playerchosen.ov_yulong = function(self,players)
	local mc = self:getMaxCard()
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and mc and q(mc,"getNumber")>9
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_yulong',sgs.ai_skill_playerchosen['ov_yulong'],{},{})
sgs.ai_playerchosen_intention.ov_yulong = 55

sgs.ai_fill_skill["ov_lihuo"] = function(self,inclusive,request)
  	for _,c in sgs.list(self:addHandPile())do
	   	if q(c,"isKindOf","NatureSlash") then continue end
		local fs = clone(self,"fire_slash")
		fs = mutate(self,fs,"skill","mobilelihuo")
		fs = mutate(self,fs,"add",c)
		if q(fs,"isAvailable",self.player)
		and q(c,"isKindOf","Slash")
	   	then return fs end
	end
end


remember_function('ai_fill_skill','ov_lihuo',sgs.ai_fill_skill['ov_lihuo'],{},{})
sgs.ai_skill_invoke.ov_lihuo = function(self,data)
	local use = data:toCardUse()
	-- Reached native constructor records the fresh hypothetical use before evaluation.
	local fs = self:observeOverseasLihuoHypothesis()
	use.card = fs
	if self:aiUseCard(fs).card
	then return true end
end


remember_function('ai_skill_invoke','ov_lihuo',sgs.ai_skill_invoke['ov_lihuo'],{},{})
sgs.ai_skill_playerchosen.ov_lihuo = function(self,targets)
	return sgs.ai_skill_playerchosen.yb_zhuzhan2(self,targets)
end


remember_function('ai_skill_playerchosen','ov_lihuo',sgs.ai_skill_playerchosen['ov_lihuo'],{},{})
sgs.ai_skill_playerchosen.ov_chunlao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"hej")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:isWeak(target)
		then return target end
	end
	destlist = self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and q(target,"getHandcardNum")>3
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_chunlao',sgs.ai_skill_playerchosen['ov_chunlao'],{},{})
sgs.ai_playerchosen_intention.ov_chunlao = -55

sgs.ai_skill_invoke.ov_chunlao = function(self,data)
	local to = data:toPlayer()
	if to and self:isFriend(to)
	then return true end
end


remember_function('ai_skill_invoke','ov_chunlao',sgs.ai_skill_invoke['ov_chunlao'],{},{})
sgs.ai_skill_playerchosen.ov_chunlaobf = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:isWeak(target)
		then return target end
	end
	destlist = self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_chunlaobf',sgs.ai_skill_playerchosen['ov_chunlaobf'],{},{})
sgs.ai_playerchosen_intention.ov_chunlaobf = -55

sgs.ai_skill_discard.ov_chunlaobf = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
 	return #cards>1 and {q(cards[1],"getEffectiveId")}
end


remember_function('ai_skill_discard','ov_chunlaobf',sgs.ai_skill_discard['ov_chunlaobf'],{},{})
sgs.ai_fill_skill["ov_boming"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	if #cards<1 then return end
	local c,to = self:getCardNeedPlayer(cards,false)
  	if c and to then
		self.bm_to = to
		self:setPriorityValue("ov_bomingCard",8.8,"OverseasVersion")
		return policy(self,"#ov_bomingCard:"..q(c,"getEffectiveId")..":")
	end
	self:setPriorityValue("ov_bomingCard",1.8,"OverseasVersion")
	local card_ids = sgs.QList2Table(ListC2I(cards))
	local to,c = sgs.ai_skill_askforyiji.nosyiji(self,card_ids)
  	if c and to and to:objectName()~=self.player:objectName() then
		self.bm_to = to
		return policy(self,"#ov_bomingCard:"..c..":")
	end
	cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
	if #cards>q(self.player,"getMaxCards")
	and #self.friends_noself>0 then
		self.bm_to = self.friends_noself[1]
		return policy(self,"#ov_bomingCard:"..q(cards[1],"getEffectiveId")..":")
	end
end


remember_function('ai_fill_skill','ov_boming',sgs.ai_fill_skill['ov_boming'],{'bm_to'},{'bm_to'})
sgs.ai_skill_use_func["#ov_bomingCard"] = function(card,use,self)
	if self.bm_to
	then
		use.card = card
		use.to:append(self.bm_to)
	end
end


remember_function('ai_skill_use_func','#ov_bomingCard',sgs.ai_skill_use_func['#ov_bomingCard'],{'bm_to'},{})
sgs.ai_use_value.ov_bomingCard = 4.4
sgs.ai_use_priority.ov_bomingCard = 1.8

sgs.ai_skill_invoke.ov_ejian = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isEnemy(target)
	end
end


remember_function('ai_skill_invoke','ov_ejian',sgs.ai_skill_invoke['ov_ejian'],{},{})
sgs.ai_fill_skill["ov_jinglve"] = function(self,inclusive,request)
	return policy(self,"#ov_jinglveCard:.:")
end


remember_function('ai_fill_skill','ov_jinglve',sgs.ai_fill_skill['ov_jinglve'],{},{})
sgs.ai_skill_use_func["#ov_jinglveCard"] = function(card,use,self)
 local c=self:evaluateSkillCard("ov_jinglve","JinglveCard",{})
 self.enemies=self:sort(self.enemies,"handcard")
 for _,p in ipairs(self.enemies)do
  if p:isKongcheng()then continue end
  use.card=c;use.to:append(p);break
 end
 if use.to:length()>0 then use.card=card end
end


remember_function('ai_skill_use_func','#ov_jinglveCard',sgs.ai_skill_use_func['#ov_jinglveCard'],{},{})
sgs.ai_use_value.ov_jinglveCard = 4.4
sgs.ai_use_priority.ov_jinglveCard = 7.8

sgs.ai_fill_skill["ov_fuman"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
	if #cards>=q(self.player,"getMaxCards")
	and #self.friends_noself>0
	then
		return policy(self,"#ov_fumanCard:"..q(cards[1],"getEffectiveId")..":")
	end
end


remember_function('ai_fill_skill','ov_fuman',sgs.ai_fill_skill['ov_fuman'],{},{})
sgs.ai_skill_use_func["#ov_fumanCard"] = function(card,use,self)
	for c,fp in sgs.list(self.friends_noself)do
		if q(self.player,"getMark",fp:objectName().."ov_fuman-PlayClear")<1
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_fumanCard',sgs.ai_skill_use_func['#ov_fumanCard'],{},{})
sgs.ai_use_value.ov_fumanCard = 4.4
sgs.ai_use_priority.ov_fumanCard = 1.8

sgs.ai_skill_invoke.ov_cuorui = function(self,data)
	local n = q(self.player,"getHandcardNum")
	for i,p in sgs.list(self.room:getAlivePlayers())do
		i = q(p,"getHandcardNum")
		if i>n then n = i end
	end
	n = n-q(self.player,"getHandcardNum")
	n = n>5 and 5 or n
	return n>3 or self:isWeak() and n>2
end


remember_function('ai_skill_invoke','ov_cuorui',sgs.ai_skill_invoke['ov_cuorui'],{},{})
sgs.ai_skill_playerchosen.ov_cuorui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and not self:isWeak(target)
		then return target end
	end
	destlist = self:sort(destlist,"card",true)
    return destlist[1]
end

remember_function('ai_skill_playerchosen','ov_cuorui',sgs.ai_skill_playerchosen['ov_cuorui'],{},{})
sgs.ai_playerchosen_intention.ov_cuorui = 55

sgs.ai_skill_choice.ov_liewei = function(self,choices)
	local items = choices:split("+")
	if self:isWeak() then return items[1] end
	return items[2]
end


remember_function('ai_skill_choice','ov_liewei',sgs.ai_skill_choice['ov_liewei'],{},{})
sgs.ai_skill_invoke.ov_xiewei = function(self,data)
	local target = data:toPlayer()
	if target and self:isEnemy(target)
	then
		for _,fp in sgs.list(self.friends_noself)do
			if target:canSlash(fp) and self:isWeak(fp)
			then return true end
		end
		return not self:isWeak()
		and (self:getCardsNum("Slash")>2 or q(target,"getHandcardNum")<3)
	end
end


remember_function('ai_skill_invoke','ov_xiewei',sgs.ai_skill_invoke['ov_xiewei'],{},{})
sgs.ai_skill_choice.ov_liewei = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target)
	then
		if q(target,"getHandcardNum")<=q(self.player,"getHandcardNum")
		then return items[1] else return items[2] end
	else
		if #items>2
		then
			return items[3]
		end
		if q(target,"getHandcardNum")>q(self.player,"getHandcardNum")+1
		then return items[1] else return items[2] end
	end
end


remember_function('ai_skill_choice','ov_liewei',sgs.ai_skill_choice['ov_liewei'],{},{})
sgs.ai_skill_playerchosen.ov_shuangren = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
	local mc = self:getMaxCard()
	if not mc or q(mc,"getNumber")<9
	then return end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target) then
			for _,p in sgs.list(self.room:getAlivePlayers())do
				if q(target,"distanceTo",p)<=1 and self:isEnemy(p)
				and self:slashIsEffective(clone(self),p)
				and self.player:canSlash(p)
				then return target end
			end
		end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target) then
			for _,p in sgs.list(self.room:getAlivePlayers())do
				if q(target,"distanceTo",p)<=1 and self:isEnemy(p)
				and self:slashIsEffective(clone(self),p)
				and self.player:canSlash(p)
				then return target end
			end
		end
	end
end

remember_function('ai_skill_playerchosen','ov_shuangren',sgs.ai_skill_playerchosen['ov_shuangren'],{},{})
sgs.ai_playerchosen_intention.ov_shuangren = 55

sgs.ai_skill_cardask["ov_shuangren2"] = function(self,data,pattern,prompt)
	local tos = sgs.SPlayerList()
	for i,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if q(self.player,"canPindian",p)
		then tos:append(p) end
	end
	tos = sgs.ai_skill_playerchosen.ov_shuangren(self,tos)
	if tos then
		local cards = self.player:getCards("he")
		cards = self:sortByKeepValue(cards)
		for i,c in sgs.list(cards)do
			if q(c,"getEffectiveId")~=self:getMaxCard():getEffectiveId()
			then return q(c,"getEffectiveId") end
		end
	end
	return "."
end


remember_function('ai_skill_cardask','ov_shuangren2',sgs.ai_skill_cardask['ov_shuangren2'],{},{})
sgs.ai_skill_playerschosen.ov_shuangren = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
	local tos = {}
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isEnemy(target) and self.player:canSlash(target)
		and self:slashIsEffective(clone(self),target)
		then table.insert(tos,target) end
	end
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if not self:isFriend(target)
		and self.player:canSlash(target)
		and not table.contains(tos,target)
		and self:slashIsEffective(clone(self),target)
		then table.insert(tos,target) end
	end
	return tos
end


remember_function('ai_skill_playerschosen','ov_shuangren',sgs.ai_skill_playerschosen['ov_shuangren'],{},{})
sgs.ai_skill_playerchosen.ov_fenming = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getCardCount()>0
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_fenming',sgs.ai_skill_playerchosen['ov_fenming'],{},{})
sgs.ai_playerchosen_intention.ov_fenming = 55

sgs.ai_skill_choice.ov_liewei = function(self,choices)
	local items = choices:split("+")
	if self.player:isChained() then return items[3] end
	return items[1]
end


remember_function('ai_skill_choice','ov_liewei',sgs.ai_skill_choice['ov_liewei'],{},{})
sgs.ai_fill_skill["ov_mouli"] = function(self,inclusive,request)
    for _,pn in sgs.list(source_patterns(self))do
		local c = clone(self,pn)
		if c and q(c,"getTypeId")==1
		and q(c,"isAvailable",self.player)
		and self:getCardsNum(q(c,"getClassName"))<2
		and self:getRestCardsNum(q(c,"getClassName"))>0
		then
			c = self:aiUseCard(c)
			if c.card and c.to
			then
				self.ml_to = c.to
				return policy(self,"#ov_mouliCard:.:"..pn)
			end
		end
	end
end


remember_function('ai_fill_skill','ov_mouli',sgs.ai_fill_skill['ov_mouli'],{'ml_to'},{'ml_to'})
sgs.ai_skill_use_func["#ov_mouliCard"] = function(card,use,self)
	if self.ml_to
	then
		use.card = card
		use.to = self.ml_to
	end
end


remember_function('ai_skill_use_func','#ov_mouliCard',sgs.ai_skill_use_func['#ov_mouliCard'],{'ml_to'},{})
sgs.ai_use_value.ov_mouliCard = 4.4
sgs.ai_use_priority.ov_mouliCard = 2.8

sgs.ai_guhuo_card.ov_mouli = function(self,toname,class_name)
	if q(self.player,"getMark","ov_mouliUse-Clear")<1
	and self:getRestCardsNum(class_name)>0
	and clone(self,class_name):getTypeId()==1
	and self:getCardsNum(class_name)<2
	and known(self.request.reason,"current source reason")==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	then return "#ov_mouliCard:.:"..toname end
end


remember_function('ai_guhuo_card','ov_mouli',sgs.ai_guhuo_card['ov_mouli'],{},{})
sgs.ai_skill_invoke.ov_qianxi = function(self,data)
	return true
end


remember_function('ai_skill_invoke','ov_qianxi',sgs.ai_skill_invoke['ov_qianxi'],{},{})
sgs.ai_skill_discard.ov_qianxi = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
    for i,c in sgs.list(cards)do
		if i<#cards/2
		and c:isRed()
		then
			return {q(c,"getEffectiveId")}
		end
	end
	return #cards>0 and {q(cards[1],"getEffectiveId")}
end


remember_function('ai_skill_discard','ov_qianxi',sgs.ai_skill_discard['ov_qianxi'],{},{})
sgs.ai_skill_playerchosen.ov_qianxi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getCardCount()>0
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_qianxi',sgs.ai_skill_playerchosen['ov_qianxi'],{},{})
sgs.ai_playerchosen_intention.ov_qianxi = 55

sgs.ai_skill_invoke.ov_enyuan = function(self,data)
	-- The recovery prompt is asked while CardsMoveOneTime is still set.
	local prompt = data:toString():split(":")
	if prompt[1]=="ov_enyuan1"
	then
		local target = BeMan(self.room,prompt[2])
		return self:isFriend(target) and q(target,"isWounded")
	end
	-- Both initial prompts pass the source ServerPlayer, not the event struct.
	local target = data:toPlayer()
	if q(self.player,"hasFlag","Damaged")
	then
		return not self:isFriend(target)
	end
	if q(self.player,"hasFlag","CardsMoveOneTime")
	then
		return self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_enyuan',sgs.ai_skill_invoke['ov_enyuan'],{},{})
sgs.ai_skill_use["@@ov_xuanhuo"] = function(self,prompt)
	local to,ids = nil,{}
	local destlist = self.room:getOtherPlayers(self.player)
    destlist = self:sort(destlist,"handcard")
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		if #ids>1 then break end
		table.insert(ids,q(c,"getEffectiveId"))
	end
	for _,p in sgs.list(destlist)do
		if to then break end
		if self:isFriend(p)
		then to = p:objectName() end
		self.ov_xh_to = p
	end
	for _,p in sgs.list(destlist)do
		if to then break end
		if self:isEnemy(p)
		and #self.enemies>1
		then to = p:objectName() end
		self.ov_xh_to = p
	end
	for _,p in sgs.list(destlist)do
		if to then break end
		if #self.enemies>0
		then to = p:objectName() end
		self.ov_xh_to = p
	end
	if to
	and #ids>1
	then
    	return string.format("#ov_xuanhuoCard:%s:->%s",table.concat(ids,"+"),to)
	end
end


remember_function('ai_skill_use','@@ov_xuanhuo',sgs.ai_skill_use['@@ov_xuanhuo'],{'ov_xh_to'},{'ov_xh_to'})
sgs.ai_skill_playerchosen.ov_xuanhuo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and (self.ov_xh_to:canUse(clone(self),target,true) or self.ov_xh_to:canUse(clone(self,"duel"),target,true))
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and (self.ov_xh_to:canUse(clone(self),target,true) or self.ov_xh_to:canUse(clone(self,"duel"),target,true))
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_xuanhuo',sgs.ai_skill_playerchosen['ov_xuanhuo'],{'ov_xh_to'},{})
sgs.ai_playerchosen_intention.ov_xuanhuo = 55

sgs.ai_skill_choice.ov_xuanhuo = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items,"slash")
	then
		if self:isFriend(target)
		then
			if not self:hasTrickEffective(clone(self,"duel"),target,self.player)
			then return "duel" end
			if not(self:isWeak(target) and self:slashIsEffective(clone(self),target))
			then return "slash" end
		elseif q(self.player,"getHandcardNum")>q(target,"getHandcardNum")
		and self:hasTrickEffective(clone(self,"duel"),target,self.player)
		then
			return "duel"
		end
		return "slash"
	end
	if not self:isFriend(target)
	then return items[1] end
end


remember_function('ai_skill_choice','ov_xuanhuo',sgs.ai_skill_choice['ov_xuanhuo'],{},{})
sgs.ai_skill_playerchosen.ov_zenhui = function(self,players)
	dynamic(self,'ai_skill_choice','ov_zenhui',"ov_zenhui2")
	write_delegate(self,"yb_zhuzhan2_data",tag(self,"ov_zenhuiData","CardUse"))
	local to = sgs.ai_skill_playerchosen.yb_zhuzhan2(self,players)
	if to then return to end
	dynamic(self,'ai_skill_choice','ov_zenhui',"ov_zenhui1")
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"ej")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target,"he")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"hej")
		then return target end
	end
end


remember_function('ai_skill_playerchosen','ov_zenhui',sgs.ai_skill_playerchosen['ov_zenhui'],{},{})
sgs.ai_skill_playerchosen.ov_qirang1 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	return destlist[1]
end

remember_function('ai_skill_playerchosen','ov_qirang1',sgs.ai_skill_playerchosen['ov_qirang1'],{},{})
sgs.ai_playerchosen_intention.ov_qirang1 = 55

sgs.ai_skill_cardask["ov_jiaojin"] = function(self,data,pattern,prompt)
	local damage = data:toDamage()
	if self:canDamageHp(damage.from,damage.card,damage.to)
	and self:canLoseHp(damage.from,damage.card)
	and not self:isWeak() then return end
	return true
end


remember_function('ai_skill_cardask','ov_jiaojin',sgs.ai_skill_cardask['ov_jiaojin'],{},{})
sgs.ai_fill_skill["ov_yuanhu"] = function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		if q(c,"getTypeId")==3
		and self:evaluateArmor(c)>-5
		then
			i = known(c:getEquipSlot(),"source equipment slot")
			for n,fp in sgs.list(self.friends)do
				if fp:hasEquipArea(i)
				then 
					n = false
					for _,p in sgs.list(self.room:getAlivePlayers())do
						if i~=0 then break end
						if q(fp,"distanceTo",p)==1
						and self:doDisCard(p,"hej")
						then n = true end
					end
					if i==1
					then
						n = q(fp,"getHandcardNum")<3
					elseif i>1
					then
						n = self:isWeak(fp)
					end
					if n
					then
						self.ov_yh_to = fp
						return policy(self,"#ov_yuanhuCard:"..q(c,"getEffectiveId")..":")
					end
				end
			end
		end
	end
  	for i,c in sgs.list(cards)do
		if q(c,"getTypeId")==3
		and self:evaluateArmor(c)>-5
		then
			i = known(c:getEquipSlot(),"source equipment slot")
			for _,fp in sgs.list(self.friends)do
				if fp:hasEquipArea(i)
				and not equip(self,fp,i)
				then 
					self.ov_yh_to = fp
					return policy(self,"#ov_yuanhuCard:"..q(c,"getEffectiveId")..":")
				end
			end
		end
	end
	cards = self:poisonCards("e")
  	for i,c in sgs.list(cards)do
		i = known(c:getEquipSlot(),"source equipment slot")
		for _,fp in sgs.list(self.enemies)do
			if fp:hasEquipArea(i)
			then 
				self.ov_yh_to = fp
				return policy(self,"#ov_yuanhuCard:"..q(c,"getEffectiveId")..":")
			end
		end
	end
	cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		if q(c,"getTypeId")==3
		and self:evaluateArmor(c)<-5
		then
			i = known(c:getEquipSlot(),"source equipment slot")
			for _,fp in sgs.list(self.enemies)do
				if fp:hasEquipArea(i)
				then 
					self.ov_yh_to = fp
					return policy(self,"#ov_yuanhuCard:"..q(c,"getEffectiveId")..":")
				end
			end
		end
	end
end


remember_function('ai_fill_skill','ov_yuanhu',sgs.ai_fill_skill['ov_yuanhu'],{'ov_yh_to'},{'ov_yh_to'})
sgs.ai_skill_use_func["#ov_yuanhuCard"] = function(card,use,self)
	if self.ov_yh_to
	then
		use.card = card
		use.to:append(self.ov_yh_to)
	end
end


remember_function('ai_skill_use_func','#ov_yuanhuCard',sgs.ai_skill_use_func['#ov_yuanhuCard'],{'ov_yh_to'},{})
sgs.ai_use_value.ov_yuanhuCard = 9.4
sgs.ai_use_priority.ov_yuanhuCard = 7.8

sgs.ai_skill_use["@@ov_yuanhu"] = function(self,prompt)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		if q(c,"getTypeId")==3
		and self:evaluateArmor(c)>-5
		then
			i = known(c:getEquipSlot(),"source equipment slot")
			for n,fp in sgs.list(self.friends)do
				if fp:hasEquipArea(i)
				then 
					n = false
					for _,p in sgs.list(self.room:getAlivePlayers())do
						if i~=0 then break end
						if q(fp,"distanceTo",p)==1
						and self:doDisCard(p,"hej")
						then n = true end
					end
					if i==1
					then
						n = q(fp,"getHandcardNum")<3
					elseif i>1
					then
						n = self:isWeak(fp)
					end
					if n
					then
						return string.format("#ov_yuanhuCard:%s:->%s",q(c,"getEffectiveId"),fp:objectName())
					end
				end
			end
		end
	end
  	for i,c in sgs.list(cards)do
		if q(c,"getTypeId")==3
		and self:evaluateArmor(c)>-5
		then
			i = known(c:getEquipSlot(),"source equipment slot")
			for _,fp in sgs.list(self.friends)do
				if fp:hasEquipArea(i)
				and not equip(self,fp,i)
				then 
					return string.format("#ov_yuanhuCard:%s:->%s",q(c,"getEffectiveId"),fp:objectName())
				end
			end
		end
	end
	cards = self:poisonCards("e")
  	for i,c in sgs.list(cards)do
		i = known(c:getEquipSlot(),"source equipment slot")
		for _,fp in sgs.list(self.enemies)do
			if fp:hasEquipArea(i)
			then 
				return string.format("#ov_yuanhuCard:%s:->%s",q(c,"getEffectiveId"),fp:objectName())
			end
		end
	end
	cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		if q(c,"getTypeId")==3
		and self:evaluateArmor(c)<-5
		then
			i = known(c:getEquipSlot(),"source equipment slot")
			for _,fp in sgs.list(self.enemies)do
				if fp:hasEquipArea(i)
				then 
					return string.format("#ov_yuanhuCard:%s:->%s",q(c,"getEffectiveId"),fp:objectName())
				end
			end
		end
	end
end


remember_function('ai_skill_use','@@ov_yuanhu',sgs.ai_skill_use['@@ov_yuanhu'],{},{})
sgs.ai_skill_playerchosen.ov_juezhu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and (self:isWeak(target) or self:doDisCard(target,"j"))
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_juezhu',sgs.ai_skill_playerchosen['ov_juezhu'],{},{})
sgs.ai_playerchosen_intention.ov_juezhu = -55

sgs.ai_skill_invoke.ov_juezhu = function(self,data)
	return sgs.ai_skill_playerchosen.ov_juezhu(self,self.room:getAlivePlayers())
end


remember_function('ai_skill_invoke','ov_juezhu',sgs.ai_skill_invoke['ov_juezhu'],{},{})
sgs.ai_skill_invoke.ov_zhilve = function(self,data)
	return true
end


remember_function('ai_skill_invoke','ov_zhilve',sgs.ai_skill_invoke['ov_zhilve'],{},{})
sgs.ai_skill_choice.ov_zhilve = function(self,choices)
	local items = choices:split("+")
	if sgs.ai_skill_invoke.peiqi(self,{}) then
		if self.room:getCardPlace(self.peiqiData.cid)~=sgs.Player_PlaceEquip
		or not self:isWeak() then return items[1] end
	end
	return items[2]
end


remember_function('ai_skill_choice','ov_zhilve',sgs.ai_skill_choice['ov_zhilve'],{},{})
sgs.ai_skill_playerchosen["ov_zhilve_from"] = function(self,players)
	for _,target in sgs.list(players)do
		if target:objectName()==self.peiqiData.from:objectName()
		then return target end
	end
end


remember_function('ai_skill_playerchosen','ov_zhilve_from',sgs.ai_skill_playerchosen['ov_zhilve_from'],{},{})
sgs.ai_skill_playerchosen["ov_zhilve_to"] = function(self,players)
	for _,target in sgs.list(players)do
		if target:objectName()==self.peiqiData.to:objectName()
		then return target end
	end
end


remember_function('ai_skill_playerchosen','ov_zhilve_to',sgs.ai_skill_playerchosen['ov_zhilve_to'],{},{})
sgs.ai_skill_cardchosen.ov_zhilve = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		if q(e,"getEffectiveId")==self.peiqiData.cid
		then return q(e,"getEffectiveId") end
	end
end


remember_function('ai_skill_cardchosen','ov_zhilve',sgs.ai_skill_cardchosen['ov_zhilve'],{},{})
sgs.ai_skill_playerchosen.ov_zhengrong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"e")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target,"he")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"he")
		then return target end
	end
	return destlist[1]
end


remember_function('ai_skill_playerchosen','ov_zhengrong',sgs.ai_skill_playerchosen['ov_zhengrong'],{},{})
sgs.ai_skill_use["@@ov_hongju"] = function(self,prompt)
	local valid = {}
	local honor = list_i2c(self,self.player:getPile("honor"))
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(honor)do
		if self:aiUseCard(c).card
		then
			for i,h in sgs.list(cards)do
				i = q(h,"getEffectiveId")
				if table.contains(valid,i)
				then continue end
				if self:aiUseCard(h).card
				then
					if self:getUseValue(h)<self:getUseValue(c)
					then
						table.insert(valid,q(c,"getEffectiveId"))
						table.insert(valid,i)
						break
					end
				elseif self:getKeepValue(h)<self:getKeepValue(c)
				then
					table.insert(valid,q(c,"getEffectiveId"))
					table.insert(valid,i)
					break
				end
			end
		else
			for i,h in sgs.list(cards)do
				i = q(h,"getEffectiveId")
				if table.contains(valid,i)
				then continue end
				if self:aiUseCard(h).card
				then
				elseif self:getKeepValue(h)<self:getKeepValue(c)
				then
					table.insert(valid,q(c,"getEffectiveId"))
					table.insert(valid,i)
					break
				end
			end
		end
 	end
	return string.format("#ov_hongjuCard:%s:",table.concat(valid,"+"))
end


remember_function('ai_skill_use','@@ov_hongju',sgs.ai_skill_use['@@ov_hongju'],{},{})
sgs.ai_skill_invoke.ov_hongju = function(self,data)
	return q(self.player,"isWounded")
	or #self.enemies>0
end


remember_function('ai_skill_invoke','ov_hongju',sgs.ai_skill_invoke['ov_hongju'],{},{})
sgs.ai_fill_skill["ov_qingce"] = function(self,inclusive,request)
	local cards = self.player:getPile("honor")
	if cards:length()>0
	then
		return policy(self,"#ov_qingceCard:"..cards:at(0)..":")
	end
end


remember_function('ai_fill_skill','ov_qingce',sgs.ai_fill_skill['ov_qingce'],{},{})
sgs.ai_skill_use_func["#ov_qingceCard"] = function(card,use,self)
	for c,fp in sgs.list(self.friends_noself)do
		if self:doDisCard(fp,"ej")
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
	for c,fp in sgs.list(self.enemies)do
		if self:doDisCard(fp,"ej")
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
	for c,fp in sgs.list(self.enemies)do
		if self:doDisCard(fp,"hej")
		and fp:getCardCount()<3
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_qingceCard',sgs.ai_skill_use_func['#ov_qingceCard'],{},{})
sgs.ai_use_value.ov_qingceCard = 4.4
sgs.ai_use_priority.ov_qingceCard = 4.8

sgs.ai_skill_use["@@ov_xingluan!"] = function(self,prompt)
	local valid,to = {},nil
	local ids = tag(self,"ov_xingluanForAI","IntList")
    ids = self:sortByUseValue(list_i2c(self,ids))
	local n = q(self.player,"getMark","ov_xingluanNum-Clear")
	self.enemies = self:sort(self.enemies,"hp")
	for i,c in sgs.list(ids)do
		if to then break end
		i = q(c,"getEffectiveId")
		for _,se in sgs.list(self.enemies)do
			if to then break end
			if #valid+q(se,"getMark","ov_xingluanNum-Clear")>2
			or isCard("Peach",c,se) then continue end
			if n>=q(se,"getMark","ov_xingluanNum-Clear")
			then
				table.insert(valid,i)
				to = se:objectName()
			end
		end
 	end
	self.friends = self:sort(self.friends,"hp",true)
	ids = self:sortByKeepValue(ids,true)
	for i,c in sgs.list(ids)do
		if to then break end
		i = q(c,"getEffectiveId")
		for _,se in sgs.list(self.friends)do
			if to then break end
			if #valid+q(se,"getMark","ov_xingluanNum-Clear")>2
			or #self:poisonCards({c},se)>0 then continue end
			if n<=q(se,"getMark","ov_xingluanNum-Clear")
			or hasZhaxiangEffect(se)
			then
				table.insert(valid,i)
				to = se:objectName()
			end
		end
 	end
	for i,c in sgs.list(ids)do
		if to then break end
		i = q(c,"getEffectiveId")
		for _,se in sgs.list(self.enemies)do
			if to then break end
			if #valid+q(se,"getMark","ov_xingluanNum-Clear")>2
			then continue end
			table.insert(valid,i)
			to = se:objectName()
		end
 	end
	for i,c in sgs.list(ids)do
		if to then break end
		i = q(c,"getEffectiveId")
		for _,se in sgs.list(self.friends)do
			if to then break end
			if #valid+q(se,"getMark","ov_xingluanNum-Clear")>2
			then continue end
			table.insert(valid,i)
			to = se:objectName()
		end
 	end
	for i,c in sgs.list(ids)do
		if to then break end
		i = q(c,"getEffectiveId")
		for _,se in sgs.list(self.room:getAlivePlayers())do
			if to then break end
			if #valid+q(se,"getMark","ov_xingluanNum-Clear")>2
			then continue end
			table.insert(valid,i)
			to = se:objectName()
		end
 	end
	return to and string.format("#ov_xingluanCard:%s:->%s",table.concat(valid,"+"),to)
end


remember_function('ai_skill_use','@@ov_xingluan!',sgs.ai_skill_use['@@ov_xingluan!'],{},{})
sgs.ai_skill_invoke.ov_xingluan = function(self,data)
	return true
end


remember_function('ai_skill_invoke','ov_xingluan',sgs.ai_skill_invoke['ov_xingluan'],{},{})
sgs.ai_skill_playerchosen.ov_qirang = function(self,players)
	write_delegate(self,"yb_fujia2_data",tag(self,"ov_qirangData","CardUse"))
	local to = sgs.ai_skill_playerchosen.yb_fujia2(self,players)
	if to then return to end
	write_delegate(self,"yb_zhuzhan2_data",tag(self,"ov_qirangData","CardUse"))
	to = sgs.ai_skill_playerchosen.yb_zhuzhan2(self,players)
	if to then return to end
end


remember_function('ai_skill_playerchosen','ov_qirang',sgs.ai_skill_playerchosen['ov_qirang'],{},{})
sgs.ai_skill_invoke.ov_yuhua = function(self,data)
	sgs.guanXingFriend = true
	return true
end


remember_function('ai_skill_invoke','ov_yuhua',sgs.ai_skill_invoke['ov_yuhua'],{},{})
sgs.ai_skill_invoke.ov_xuhe = function(self,data)
	local target = data:toPlayer()
	if target then
		return not self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_xuhe',sgs.ai_skill_invoke['ov_xuhe'],{},{})
sgs.ai_skill_choice.ov_xuhe = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isEnemy(target)
	then
		if q(target,"getHandcardNum")>q(self.player,"getHandcardNum")*(math.random()+1.3)
		and not self:isWeak() then return items[1] end
	end
	return items[2]
end


remember_function('ai_skill_choice','ov_xuhe',sgs.ai_skill_choice['ov_xuhe'],{},{})
sgs.ai_skill_playerschosen.ov_wuhun = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	local tos = {}
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isEnemy(target)
		then table.insert(tos,target) end
	end
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if not self:isFriend(target)
		and not table.contains(tos,target)
		then table.insert(tos,target) end
	end
	return tos
end


remember_function('ai_skill_playerschosen','ov_wuhun',sgs.ai_skill_playerschosen['ov_wuhun'],{},{})
sgs.ai_skill_invoke.ov_wuhun = function(self,data)
	return #self.enemies>0
	or #self.friends>0
end


remember_function('ai_skill_invoke','ov_wuhun',sgs.ai_skill_invoke['ov_wuhun'],{},{})
sgs.ai_skill_playerchosen.ov_kuanji = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_kuanji',sgs.ai_skill_playerchosen['ov_kuanji'],{},{})
sgs.ai_playerchosen_intention.ov_kuanji = -55

sgs.ai_skill_playerchosen["_ov_tiaojiyanmei"] = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

remember_function('ai_skill_playerchosen','_ov_tiaojiyanmei',sgs.ai_skill_playerchosen['_ov_tiaojiyanmei'],{},{})
sgs.ai_playerchosen_intention._ov_tiaojiyanmei = -55

function SmartAIView:useCardTiaojiyanmei(card,use)
	if q(card,"canRecast") then use.card = card end
	self:setPriorityValue("Tiaojiyanmei",5.5,"OverseasVersion")
	if self.player:isLocked(card) then return end
	local extraTarget = 1+extra_targets(self,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	self.enemies = self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if is_current(use,ep) then continue end
		if use.to:length()<2 and can_to(self,card,ep,self.player,use.to) then
			use.to:append(ep)
			local remove1 = true
			for _,fp in sgs.list(self.friends)do
				if is_current(use,fp) then continue end
				if q(ep,"getHandcardNum")>q(fp,"getHandcardNum")
				and can_to(self,card,fp,self.player,use.to) then
					remove1 = false
					use.to:append(fp)
					use.card = card
					if use.to:length()>extraTarget
					then return end
				end
			end
			if remove1 then use.to:removeOne(ep) end
		end
	end
	for _,ep in sgs.list(self.room:getAlivePlayers())do
		if is_current(use,ep) then continue end
		if use.to:length()<2 and can_to(self,card,ep,self.player,use.to)
		and not self:isFriend(ep) then
			use.to:append(ep)
			local remove1 = true
			for _,fp in sgs.list(self.friends)do
				if is_current(use,fp) then continue end
				if q(ep,"getHandcardNum")>q(fp,"getHandcardNum")
				and can_to(self,card,fp,self.player,use.to) then
					remove1 = false
					use.to:append(fp)
					use.card = card
					if use.to:length()>extraTarget
					then return end
				end
			end
			if remove1 then use.to:removeOne(ep) end
		end
	end
	for _,fp in sgs.list(self.friends)do
		if is_current(use,fp) then continue end
		if use.to:length()>1 and use.to:at(0):getHandcardNum()>q(fp,"getHandcardNum")
		and can_to(self,card,fp,self.player,use.to) then
			use.to:append(fp)
			use.card = card
			if use.to:length()>extraTarget
			then return end
		end
	end
	if use.to:length()<2 then use.to:clear() end
	self:setPriorityValue("Tiaojiyanmei",9-q(self.player,"getHandcardNum"),"OverseasVersion")
end

remember_function('SmartAIView','useCardTiaojiyanmei',SmartAIView['useCardTiaojiyanmei'],{},{})
sgs.ai_use_priority.Tiaojiyanmei = 5.5
sgs.ai_keep_value.Tiaojiyanmei = 1
sgs.ai_use_value.Tiaojiyanmei = 5.7
sgs.ai_card_intention.Tiaojiyanmei = function(self,card,from,tos)
	for _,to1 in ipairs(tos)do
		for _,to2 in ipairs(tos)do
			if to1==to2 then continue end
			if q(to1,"getHandcardNum")<q(to2,"getHandcardNum")
			then self:updateIntention(from,to1,-10)
			else self:updateIntention(from,to1,10) end
		end
	end
end


remember_function('ai_card_intention','Tiaojiyanmei',sgs.ai_card_intention['Tiaojiyanmei'],{},{})
sgs.ai_skill_discard.ov_yizhu = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min then break end
		if q(h,"isKindOf","AOE") or q(h,"isKindOf","GlobalEffect") then continue end
		if q(h,"isAvailable",self.player) then table.insert(to_cards,q(h,"getEffectiveId")) end
	end
	cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min then break end
		if table.contains(to_cards,q(h,"getEffectiveId"))
		then continue end
		table.insert(to_cards,q(h,"getEffectiveId"))
	end
	return to_cards
end


remember_function('ai_skill_discard','ov_yizhu',sgs.ai_skill_discard['ov_yizhu'],{},{})
sgs.ai_skill_playerchosen.ov_yizhu = function(self,players)
	local use = tag(self,"ov_yizhuData","CardUse")
	local destlist = self:sort(players,"hp")
	dynamic(self,'ai_skill_choice','ov_yizhu',"ov_yizhu2")
	if not self:isFriend(use.from) then
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			and use.card:targetFixed()
			and not use.card:isDamageCard()
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			and q(use.card,"getTypeId")==3
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if self:isEnemy(target)
			and use.card:isDamageCard()
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if self:isEnemy(target)
			and q(use.card,"isKindOf","DelayedTrick")
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not self:isFriend(target)
			and q(use.card,"isKindOf","DelayedTrick")
			then return target end
		end
	end
	dynamic(self,'ai_skill_choice','ov_yizhu',"ov_yizhu3")
	write_delegate(self,"yb_zhuzhan2_data",tag(self,"ov_yizhuData","CardUse"))
	local to = sgs.ai_skill_playerchosen.yb_zhuzhan2(self,players)
	if to then return to end
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and use.card:targetFixed()
		and not use.card:isDamageCard()
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and use.card:isDamageCard()
		then return target end
	end
end


remember_function('ai_skill_playerchosen','ov_yizhu',sgs.ai_skill_playerchosen['ov_yizhu'],{},{})
sgs.ai_fill_skill["ov_luanchou"] = function(self,inclusive,request)
	return policy(self,"#ov_luanchouCard:.:")
end


remember_function('ai_fill_skill','ov_luanchou',sgs.ai_fill_skill['ov_luanchou'],{},{})
sgs.ai_skill_use_func["#ov_luanchouCard"] = function(card,use,self)
	self.friends = self:sort(self.friends,"hp")
	for c,fp1 in sgs.list(self.friends)do
		for _,fp2 in sgs.list(sgs.reverse(self.friends))do
			if q(fp2,"getHp")>q(fp1,"getHp")
			or fp2:objectName()~=fp1:objectName()
			then
				use.card = card
				use.to:append(fp1)
				use.to:append(fp2)
				return
			end
		end
	end
	for c,fp1 in sgs.list(self.room:getAlivePlayers())do
		if self:isEnemy(fp1) then continue end
		for _,fp2 in sgs.list(self.friends)do
			if q(fp2,"getHp")<=q(fp1,"getHp")
			and fp2:objectName()~=fp1:objectName()
			then
				use.card = card
				use.to:append(fp1)
				use.to:append(fp2)
				return
			end
		end
	end
end


remember_function('ai_skill_use_func','#ov_luanchouCard',sgs.ai_skill_use_func['#ov_luanchouCard'],{},{})
sgs.ai_use_value.ov_luanchouCard = 4.4
sgs.ai_use_priority.ov_luanchouCard = 7.8

sgs.ai_skill_invoke.ov_gonghuan = function(self,data)
	local target = data:toPlayer()
	if target
	then
		if self:isFriend(target)
		then
			return self:isWeak(target)
			and (not self:isWeak() or q(target,"getHp")<q(self.player,"getHp") or q(target,"getHandcardNum")>q(self.player,"getHandcardNum"))
		end
		return not self:isEnemy(target)
		and self:isWeak(target) and not self:isWeak()
	end
end


remember_function('ai_skill_invoke','ov_gonghuan',sgs.ai_skill_invoke['ov_gonghuan'],{},{})
sgs.ai_fill_skill["ov_gongxin"] = function(self,inclusive,request)
	return policy(self,"#ov_gongxinCard:.:")
end


remember_function('ai_fill_skill','ov_gongxin',sgs.ai_fill_skill['ov_gongxin'],{},{})
sgs.ai_skill_use_func["#ov_gongxinCard"] = function(card,use,self)
	local cas = true
	if cas
	then
		cas = self:evaluateSkillCard("ov_gongxin","GongxinCard",{})
		local gxUse = sgs.ai_skill_use_func["GongxinCard"]
		if gxUse
		then
			gxUse(cas,use,self)
			if use.to:length()>0
			then
				use.card = card
				self:setStrategyMemory("OverseasVersion.tag:gongxin",use.to:at(0):objectName())
			end
		end
	end
end


remember_function('ai_skill_use_func','#ov_gongxinCard',sgs.ai_skill_use_func['#ov_gongxinCard'],{},{})
sgs.ai_use_value.ov_gongxinCard = 4.4
sgs.ai_use_priority.ov_gongxinCard = 9.8

sgs.ai_skill_choice.ov_gongxin = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items,"ov_gongxin1")
	then
		if self.gongxinchoice=="put"
		then return "ov_gongxin1" end
		return "ov_gongxin2"
	end
	if table.contains(items,"red")
	then
		for i,h in sgs.list(complete_hand(self,target))do
			if self:isWeak(target)
			and (isCard("Peach",h,target) or isCard("Analeptic",h,target))
			then return q(h,"getColorString") end
		end
		for i,h in sgs.list(complete_hand(self,target))do
			if isCard("Jink",h,target)
			then return q(h,"getColorString") end
		end
		for i,h in sgs.list(complete_hand(self,target))do
			if isCard("Nullification",h,target)
			then return q(h,"getColorString") end
		end
	end
end


remember_function('ai_skill_choice','ov_gongxin',sgs.ai_skill_choice['ov_gongxin'],{'gongxinchoice'},{'gongxinchoice'})
sgs.ai_skill_askforag.ov_gongxin = function(self,card_ids)
	local id = gongxin_ag(self,card_ids)
	if id>=0 then return id end
	local cs = list_i2c(self,card_ids)
    cs = self:sortByUseValue(cs)
	return q(cs[1],"getEffectiveId")
end


remember_function('ai_skill_askforag','ov_gongxin',sgs.ai_skill_askforag['ov_gongxin'],{},{})
sgs.ai_skill_choice.ov_shelie = function(self,choices,data)
	local items = choices:split("+")
	local uses,_,unknown = self:getTurnUse();if unknown then error(unknown,0)end
	if #uses>2
	then
		return items[2]
	end
	return items[1]
end


remember_function('ai_skill_choice','ov_shelie',sgs.ai_skill_choice['ov_shelie'],{},{})
sgs.ai_skill_playerchosen.ov_suizheng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

remember_function('ai_skill_playerchosen','ov_suizheng',sgs.ai_skill_playerchosen['ov_suizheng'],{},{})
sgs.ai_playerchosen_intention.ov_suizheng = -55

sgs.ai_skill_discard.ov_suizheng = function(self,max,min,optional)
	local to_cards = {}
	local target = tag(self,"ov_suizheng","Player")
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min or self:isEnemy(target) or not self:isWeak() then break end
		if q(h,"getTypeId")==1 then table.insert(to_cards,q(h,"getEffectiveId")) end
	end
	return #to_cards>1 and to_cards
end


remember_function('ai_skill_discard','ov_suizheng',sgs.ai_skill_discard['ov_suizheng'],{},{})
sgs.ai_skill_invoke.ov_tuidao = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isEnemy(target)
	end
	return #self.friends_noself>0
	or #self.enemies<1
end


remember_function('ai_skill_invoke','ov_tuidao',sgs.ai_skill_invoke['ov_tuidao'],{},{})
sgs.ai_skill_choice.ov_tuidao = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target
	and table.contains(items,"BasicCard")
	then
		if target:hasEquip()
		then
			return items[3]
		end
		return items[1]
	end
	return items[2]
end


remember_function('ai_skill_choice','ov_tuidao',sgs.ai_skill_choice['ov_tuidao'],{},{})
sgs.ai_skill_playerchosen.ov_tuidao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

remember_function('ai_skill_playerchosen','ov_tuidao',sgs.ai_skill_playerchosen['ov_tuidao'],{},{})
sgs.ai_playerchosen_intention.ov_tuidao = -55

sgs.ai_skill_playerchosen.ov_gongge = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"skill",true)
	local n = 0
	for _,c in sgs.list(self:getPriorTurnUseCards())do
		if c:isDamageCard()
		then n = n+1 end
	end
	if n>1 then return end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end


remember_function('ai_skill_playerchosen','ov_gongge',sgs.ai_skill_playerchosen['ov_gongge'],{},{})
sgs.ai_playerchosen_intention.ov_gongge = 55

sgs.ai_skill_choice.ov_gongge = function(self,choices,data)
	local items = choices:split("+")
	local use = tag(self,"ov_gongge","CardUse")
	local target = data:toPlayer()
	if target
	then
		if q(target,"getHandcardNum")<2
		then return items[3] end
		if target:getCardCount()>2
		or q(target,"getHp")<q(self.player,"getHp")
		then return items[2] end
		if target:getSkillList():length()>2
		and q(self.player,"getHandcardNum")<3
		then return items[1] end
		if q(target,"getLostHp")<2
		then return items[3] end
	end
	return items[1]
end


remember_function('ai_skill_choice','ov_gongge',sgs.ai_skill_choice['ov_gongge'],{},{})
sgs.ai_skill_invoke.ov_qingxi = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_qingxi',sgs.ai_skill_invoke['ov_qingxi'],{},{})
sgs.ai_skill_choice.ov_qingxi = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target
	then
		if target:getEquips():length()<self.player:getEquips():length()
		and not self:isWeak() then return items[1] end
		if target:hasEquip() and self.player:hasEquip()
		and self:getCardsNum("Jink")>0
		then return items[2] end
	end
end


remember_function('ai_skill_choice','ov_qingxi',sgs.ai_skill_choice['ov_qingxi'],{},{})
sgs.ai_skill_use["@@ov_zaoli!"] = function(self,prompt)
	local valid = {}
    local cards = self.player:getCards("hej")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if q(h,"getTypeId")==3 then table.insert(valid,q(h,"getEffectiveId")) end
		if q(h,"isAvailable",self.player) and self:aiUseCard(h).card
		or table.contains(valid,q(h,"getEffectiveId"))
		or self:getKeepValue(h)>5 then continue end
    	table.insert(valid,q(h,"getEffectiveId"))
	end
	for _,h in sgs.list(self.player:getCards("j"))do
		if table.contains(valid,q(h,"getEffectiveId")) then continue end
		if self:doDisCard(self.player,q(h,"getEffectiveId"))
		then table.insert(valid,q(h,"getEffectiveId")) end
	end
	return string.format("#ov_zaoliCard:%s:",table.concat(valid,"+"))
end


remember_function('ai_skill_use','@@ov_zaoli!',sgs.ai_skill_use['@@ov_zaoli!'],{},{})
sgs.ai_skill_invoke.ov_yuzhang = function(self,data)
	local ts = data:toString()
	if ts:startsWith("ov_yuzhang")
	then
		ts = ts:split(":")[2]
		if ts=="Player_Judge"
		and self:doDisCard(self.player,"j")
		then return true end
		if ts=="Player_Discard"
		and q(self.player,"getHandcardNum")>q(self.player,"getMaxCards")*(math.random()+1)
		then return true end
		return
	end
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_yuzhang',sgs.ai_skill_invoke['ov_yuzhang'],{},{})
sgs.ai_skill_choice.ov_yuzhang = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target
	then
		if q(target,"getHandcardNum")>q(self.player,"getHandcardNum")*(math.random()+1)
		then return items[1] end
		if target:getCardCount()<4
		then return items[2] end
	end
end


remember_function('ai_skill_choice','ov_yuzhang',sgs.ai_skill_choice['ov_yuzhang'],{},{})
sgs.ai_skill_invoke.ov_guoyi = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_guoyi',sgs.ai_skill_invoke['ov_guoyi'],{},{})
sgs.ai_skill_use["@@ov_liexi"] = function(self,prompt)
	local valid = {}
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true)
	self.enemies = self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if self:damageIsEffective(ep,nil,self.player)
		then
			for _,h in sgs.list(cards)do
				if q(ep,"getHp")<#cards/2 or q(ep,"getHp")<=#cards/2 and self:isWeak(ep)
				then
					table.insert(valid,q(h,"getEffectiveId"))
					if #valid>q(ep,"getHp")
					then
						return "#ov_liexiCard:"..table.concat(valid,"+")..":->"..ep:objectName()
					end
				end
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if self:damageIsEffective(ep,nil,self.player)
		then
			for _,h in sgs.list(cards)do
				if q(h,"isKindOf","Weapon") and (q(self.player,"getHp")>1 and self:isWeak(ep) or not self:isWeak())
				then return "#ov_liexiCard:"..q(h,"getEffectiveId")..":->"..ep:objectName() end
			end
		end
	end
end


remember_function('ai_skill_use','@@ov_liexi',sgs.ai_skill_use['@@ov_liexi'],{},{})
sgs.ai_skill_playerschosen.ov_shezhong = function(self,players,x,n)
	local destlist = self:sort(players,"hp")
	local tos = {}
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isEnemy(target) then table.insert(tos,target) end
	end
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if not (self:isFriend(target) or self:isWeak(target))
		then table.insert(tos,target) end
	end
	return tos
end


remember_function('ai_skill_playerschosen','ov_shezhong',sgs.ai_skill_playerschosen['ov_shezhong'],{},{})
sgs.ai_skill_playerchosen.ov_shezhong = function(self,players)
	local destlist = self:sort(players,"handcard",true)
	return destlist[1]
end


remember_function('ai_skill_playerchosen','ov_shezhong',sgs.ai_skill_playerchosen['ov_shezhong'],{},{})
sgs.ai_fill_skill["ov_kaizengvs"] = function(self,inclusive,request)
	return policy(self,"#ov_kaizengCard:.:")
end


remember_function('ai_fill_skill','ov_kaizengvs',sgs.ai_fill_skill['ov_kaizengvs'],{},{})
sgs.ai_skill_use_func["#ov_kaizengCard"] = function(card,use,self)
	for c,fp in sgs.list(self.room:getAlivePlayers())do
		if q(fp,"hasSkill","ov_kaizeng")
		and q(fp,"getHandcardNum")>0
		then
			self.ov_kz_to = fp
			if self:isEnemy(fp) and math.random()>0.3 then continue end
			use.to:append(fp)
			use.card = card
			break
		end
	end
end


remember_function('ai_skill_use_func','#ov_kaizengCard',sgs.ai_skill_use_func['#ov_kaizengCard'],{'ov_kz_to'},{'ov_kz_to'})
sgs.ai_use_value.ov_kaizengCard = 5.4
sgs.ai_use_priority.ov_kaizengCard = 4.8

sgs.ai_skill_choice.ov_kaizeng = function(self,choices,data)
	local items = choices:split("+")
	for d,cn in sgs.list(items)do
		d = clone(self,cn)
		if d
		then
			if getKnownCard(self.ov_kz_to,self.player,q(d,"getClassName"),nil,"he")>0
			then return cn end
		elseif getKnownCard(self.ov_kz_to,self.player,cn,nil,"he")>0
		then return cn end
	end
end


remember_function('ai_skill_choice','ov_kaizeng',sgs.ai_skill_choice['ov_kaizeng'],{'ov_kz_to'},{})
sgs.ai_skill_discard.ov_kaizeng = function(self,max,min,optional)
	local to_cards = {}
	local target = self.room:getCurrent()
	local pc = self:poisonCards("he")
	if self:isFriend(target)
	then
		local kct = getKnownCards(self.player,target,"he")
		kct = self:sortByUseValue(kct,true)
		for _,c in sgs.list(kct)do
			if #to_cards>2 or table.contains(to_cards,q(c,"getEffectiveId")) then continue end
			if q(c,"isAvailable",target) then table.insert(to_cards,q(c,"getEffectiveId")) end
		end
		for _,c in sgs.list(pc)do
			if table.contains(to_cards,q(c,"getEffectiveId")) then continue end
			if q(c,"getTypeId")>2 then table.insert(to_cards,q(c,"getEffectiveId")) end
		end
		for _,c in sgs.list(kct)do
			if #to_cards>1 or table.contains(to_cards,q(c,"getEffectiveId")) then continue end
			table.insert(to_cards,q(c,"getEffectiveId"))
		end
		local cards = self.player:getCards("he")
		cards = self:sortByKeepValue(cards,true)
		for _,c in sgs.list(cards)do
			if #to_cards>1 or table.contains(to_cards,q(c,"getEffectiveId")) then continue end
			if q(c,"isAvailable",target) then table.insert(to_cards,q(c,"getEffectiveId")) end
		end
		for _,c in sgs.list(cards)do
			if #to_cards<1 or #to_cards>1 or table.contains(to_cards,q(c,"getEffectiveId")) then continue end
			table.insert(to_cards,q(c,"getEffectiveId"))
		end
	else
		for _,c in sgs.list(pc)do
			if table.contains(to_cards,q(c,"getEffectiveId")) then continue end
			if q(c,"getTypeId")<3 then table.insert(to_cards,q(c,"getEffectiveId")) end
		end
	end
	return to_cards
end


remember_function('ai_skill_discard','ov_kaizeng',sgs.ai_skill_discard['ov_kaizeng'],{},{})
sgs.ai_fill_skill["ov_xiechang"] = function(self,inclusive,request)
	return policy(self,"#ov_xiechangCard:.:")
end


remember_function('ai_fill_skill','ov_xiechang',sgs.ai_fill_skill['ov_xiechang'],{},{})
sgs.ai_skill_use_func["#ov_xiechangCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard")
	local xc = self:getMaxCard()
	self.ov_xiechang_card = xc
	for _,ep in sgs.list(self.enemies)do
		if ep:hasEquip()
		and xc and q(xc,"getNumber")>9
		and q(self.player,"canPindian",ep)
		then
			use.to:append(ep)
			use.card = card
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if q(self.player,"canPindian",ep)
		and xc and q(xc,"getNumber")>9
		then
			use.to:append(ep)
			use.card = card
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if q(self.player,"canPindian",ep)
		and q(self.player,"inMyAttackRange",ep)
		and q(ep,"getHandcardNum")<3
		then
			use.to:append(ep)
			use.card = card
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_xiechangCard',sgs.ai_skill_use_func['#ov_xiechangCard'],{'ov_xiechang_card'},{'ov_xiechang_card'})
sgs.ai_use_value.ov_xiechangCard = 4.4
sgs.ai_use_priority.ov_xiechangCard = 2.8

sgs.ai_skill_invoke.ov_duoren = function(self,data)
	local target = data:toPlayer()
	if target
	then
		local can
		for i,p in sgs.list(siblings(self,false))do
			if q(p,"isDead") then can = true end
		end
		for i,sk in sgs.list(target:getSkillList())do
			if sk:isAttachedLordSkill()
			or sk:isLordSkill()
			then continue end
			return can and q(self.player,"getLostHp")>0
		end
	end
end


remember_function('ai_skill_invoke','ov_duoren',sgs.ai_skill_invoke['ov_duoren'],{},{})
sgs.ai_skill_playerchosen.ov_yanshi = function(self,players)
	local destlist = self:sort(players,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end


remember_function('ai_skill_playerchosen','ov_yanshi',sgs.ai_skill_playerchosen['ov_yanshi'],{},{})
sgs.ai_playerchosen_intention.ov_yanshi = -55

sgs.ai_skill_invoke.ov_bingzhao = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
	end
end


remember_function('ai_skill_invoke','ov_bingzhao',sgs.ai_skill_invoke['ov_bingzhao'],{},{})
sgs.ai_skill_invoke.ov_wanwei = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
		and self:isWeak(target)
		and not self:isWeak()
	end
	return true
end


remember_function('ai_skill_invoke','ov_wanwei',sgs.ai_skill_invoke['ov_wanwei'],{},{})
sgs.ai_skill_use["@@ov_wanwei!"] = function(self,prompt)
	local valid = {}
	local c = visible(self,q(self.player,"getMark","ov_wanwei_id"))
    local d = self:aiUseCard(c)
	if d.card
	then
		if q(c,"canRecast")
		and d.to:length()<1
		then return end
		for _,p in sgs.list(d.to)do
			table.insert(valid,p:objectName())
		end
		return c:getLegacyStringKey().."->"..table.concat(valid,"+")
	end
end


remember_function('ai_skill_use','@@ov_wanwei!',sgs.ai_skill_use['@@ov_wanwei!'],{},{})
sgs.ai_fill_skill["ov_yuejian"] = function(self,inclusive,request)
	local ids = {}
	local n = q(self.player,"getHandcardNum")-q(self.player,"getMaxCards")
	n = n<1 and 1 or n
	for _,c in sgs.list(self:poisonCards("he"))do
		if #ids>=n then break end
		table.insert(ids,q(c,"getEffectiveId"))
	end
	if self:getOverflow()>0
	then
		local cs = complete_hand(self,self.player)
		cs = self:sortByKeepValue(cs)
		for _,c in sgs.list(cs)do
			if #ids>=n then break end
			table.insert(ids,q(c,"getEffectiveId"))
		end
	end
	return #ids>0 and policy(self,"#ov_yuejianCard:"..table.concat(ids,"+")..":")
end


remember_function('ai_fill_skill','ov_yuejian',sgs.ai_fill_skill['ov_yuejian'],{},{})
sgs.ai_skill_use_func["#ov_yuejianCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_yuejianCard',sgs.ai_skill_use_func['#ov_yuejianCard'],{},{})
sgs.ai_use_value.ov_yuejianCard = 3.4
sgs.ai_use_priority.ov_yuejianCard = -0.8

do
-- Fixed b6025acc OverseasVersion necessary dependency slice: ov_muyue only.
-- This supplies AgCardsToName's complete ACTN writer; the surrounding package
-- is not claimed ported. Persist scalar names, never cross-snapshot proxies.
local function known(value, key)
    if value == nil then ai_unsupported("ov_muyue value is unknown", key) end
    return value
end
local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then
        ai_unsupported("ov_muyue helper is unavailable", method)
    end
    return known(object[method](object, ...), method)
end
local function remember(self, card, target)
    self:setStrategyMemory("ACTN", call(card, "objectName"))
    if target then self:setStrategyMemory("ov_muyue_to", call(target, "objectName")) end
end
local function proposal(self, card, request)
    local costs = card and {call(card, "getEffectiveId")} or {}
    -- Source selects the cost before constructing its LuaSkillCard. Native
    -- authority still validates the exact selected cost (including zero-cost
    -- bonus, ownership, discard limitations and the current activation scope).
    return call(self, "evaluateTurnSkillCard", "ov_muyue", "#ov_muyueCard", costs, request)
end
sgs.ai_fill_skill.ov_muyue = function(self, inclusive, request)
    -- These resets occur at every source fill, even if no plan is produced.
    self:setStrategyMemory("ACTN", false)
    self:setStrategyMemory("ov_muyue_to", false)
    self:setPriorityValue("ov_muyueCard", 9.8, "ov_muyue")
    if call(self.player, "getStrategyMark", "ov_muyuebf") > 0 then
        return proposal(self, nil, request)
    end
    for _, card in ipairs(call(self, "poisonCards", "e")) do
        return proposal(self, card, request)
    end
    self:setPriorityValue("ov_muyueCard", 1.8, "ov_muyue")
    if type(self.getCardNeedPlayer) ~= "function" then ai_unsupported("ov_muyue card-need helper is unavailable", "getCardNeedPlayer") end
    local card, target = self:getCardNeedPlayer()
    if target and call(self, "isFriend", target) and card
        and (call(card, "isNDTrick") or call(card, "getTypeId") == 1)
        and call(self, "getRestCardsNum", call(card, "getClassName")) > 0 then
        remember(self, card, target)
        return proposal(self, card, request)
    end
    local cards = call(self, "sortByKeepValue", call(self.player, "getHandcards"))
    for _, friend in ipairs(known(self.friends_noself, "friends_noself")) do
        if call(self, "isWeak", friend) and call(friend, "getHandcardNum") < #cards then
            for _, candidate in ipairs(cards) do
                if (call(candidate, "isKindOf", "Peach") or call(candidate, "isKindOf", "Analeptic")
                    or call(candidate, "isKindOf", "Jink"))
                    and call(self, "getRestCardsNum", call(candidate, "getClassName")) > 0 then
                    remember(self, candidate, friend)
                    return proposal(self, candidate, request)
                end
            end
        end
    end
    for index, candidate in ipairs(cards) do
        if #cards / 2 < index and call(self, "wasPreviouslyPlannedCard", candidate)
            and call(self, "getRestCardsNum", call(candidate, "getClassName")) > 0 then
            remember(self, candidate, self.player)
            return proposal(self, candidate, request)
        end
    end
    if call(self, "getOverflow") > 0 then
        self:setPriorityValue("ov_muyueCard", -1.8, "ov_muyue")
        for index, candidate in ipairs(cards) do
            -- Preserve the source's rest-count query before its index check;
            -- that query consumes the original public-deck shuffle RNG.
            if call(self, "getRestCardsNum", call(candidate, "getClassName")) > 0 and #cards / 2 < index then
                remember(self, candidate)
                return proposal(self, candidate, request)
            end
        end
    end
end
sgs.ai_skill_use_func["#ov_muyueCard"] = function(card, use, self)
    use.card = card
end
sgs.ai_use_value.ov_muyueCard = 3.4
sgs.ai_use_priority.ov_muyueCard = 0.8
sgs.ai_skill_playerchosen.ov_muyue = function(self, players)
    local remembered, present = self:getStrategyMemory("ov_muyue_to")
    if present and type(remembered) == "string" then
        for _, player in ipairs(players) do
            if call(player, "objectName") == remembered then return player end
        end
    end
    local sorted = call(self, "sort", players, "handcard")
    for _, player in ipairs(sorted) do if call(self, "isFriend", player) then return player end end
    for _, player in ipairs(sorted) do if not call(self, "isEnemy", player) then return player end end
    return sorted[1]
end
sgs.ai_playerchosen_intention.ov_muyue = -55

end

sgs.ai_skill_playerchosen.ov_chayi = function(self,players)
	local destlist = self:sort(players,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and q(target,"getHandcardNum")<=q(target,"getHp")
		and q(target,"getHandcardNum")>0
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and q(target,"getHandcardNum")>0
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and q(target,"getHandcardNum")>0
		then return target end
	end
end


remember_function('ai_skill_playerchosen','ov_chayi',sgs.ai_skill_playerchosen['ov_chayi'],{},{})
sgs.ai_playerchosen_intention.ov_chayi = 55

sgs.ai_skill_choice.ov_chayi = function(self,choices,data)
	local items = choices:split("+")
	if q(self.player,"getHandcardNum")<1
	then return items[1]
	elseif self:isWeak()
	and q(self.player,"getHandcardNum")<=q(self.player,"getHp")
	then return items[2]
	elseif q(self.player,"getHandcardNum")>4
	then return items[2] end
end


remember_function('ai_skill_choice','ov_chayi',sgs.ai_skill_choice['ov_chayi'],{},{})
sgs.ai_skill_invoke.ov_zuici = function(self,data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		return q(target,"getPhase")>sgs.Player_Play
		or q(target,"getMark","&ov_dingyi1")>0
		or q(target,"getMark","&ov_dingyi2")>0 and self:getOverflow(target)>1
	end
end


remember_function('ai_skill_invoke','ov_zuici',sgs.ai_skill_invoke['ov_zuici'],{},{})
sgs.ai_skill_choice.ov_zuici = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	local cs = {}
	for _,cn in sgs.list(items)do
		local d = pattern_card(self,cn)
		if d then table.insert(cs,d) end
	end
	if #cs>0
	then
		cs = self:sortByUseValue(cs,self:isEnemy(target))
		return q(cs[1],"getClassName")
	end
end


remember_function('ai_skill_choice','ov_zuici',sgs.ai_skill_choice['ov_zuici'],{},{})
sgs.ai_fill_skill["ov_fubi"] = function(self,inclusive,request)
	self.ov_fubi_to = nil
	self.ov_fubi_choice = nil
	for _,p in sgs.list(self.friends)do
		if self:isWeak(p)
		and q(p,"getHandcardNum")<3
		and q(p,"getMark","&ov_dingyi4")<1
		and self:getAllPeachNum()>0
		then
			self.ov_fubi_to = p
			self.ov_fubi_choice = "ov_dingyi4"
			return policy(self,"#ov_fubiCard:.:")
		end
	end
	for _,p in sgs.list(self.friends)do
		if q(p,"getHandcardNum")<3
		and q(p,"getMark","&ov_dingyi1")<1
		then
			self.ov_fubi_to = p
			self.ov_fubi_choice = "ov_dingyi1"
			return policy(self,"#ov_fubiCard:.:")
		end
	end
	for _,p in sgs.list(self.friends)do
		if self:getOverflow(p)>1
		and q(p,"getMark","&ov_dingyi2")<1
		then
			self.ov_fubi_to = p
			self.ov_fubi_choice = "ov_dingyi2"
			return policy(self,"#ov_fubiCard:.:")
		end
	end
	for _,p in sgs.list(self.friends)do
		if self:getOverflow(p)>1
		and q(p,"getMark","&ov_dingyi3")<1
		and q(p,"getAttackRange")<2
		then
			self.ov_fubi_to = p
			self.ov_fubi_choice = "ov_dingyi3"
			return policy(self,"#ov_fubiCard:.:")
		end
	end
	for _,p in sgs.list(self.enemies)do
		if self:getOverflow(p)>0 and q(p,"getMark","&ov_dingyi2")+q(p,"getMark","&ov_dingyi3")>0
		or self:getOverflow(p)<1 and q(p,"getMark","&ov_dingyi1")>0
		then
			self.ov_fubi_to = p
			self.ov_fubi_choice = "ov_dingyi4"
			return policy(self,"#ov_fubiCard:.:")
		end
	end
	local id = self:poisonCards("e")
	id = #id>0 and q(id[1],"getEffectiveId")
	if not id
	and self:getOverflow()>=0
	then
		local cs = self.player:getCards("he")
		cs = self:sortByKeepValue(cs)
		id = #cs>0 and q(cs[1],"getEffectiveId")
	end
	if not id then return end
	id = policy(self,"#ov_fubiCard:"..id..":")
	for _,p in sgs.list(self.friends)do
		if self:isWeak(p)
		and q(p,"getHandcardNum")<3
		and q(p,"getMark","&ov_dingyi4")>0
		and self:getAllPeachNum()>0
		then
			self.ov_fubi_to = p
			return id
		end
	end
	for _,p in sgs.list(self.friends)do
		if q(p,"getHandcardNum")<3
		and q(p,"getMark","&ov_dingyi1")>0
		then
			self.ov_fubi_to = p
			return id
		end
	end
	for _,p in sgs.list(self.friends)do
		if self:getOverflow(p)>1
		and q(p,"getMark","&ov_dingyi2")>0
		then
			self.ov_fubi_to = p
			return id
		end
	end
	for _,p in sgs.list(self.friends)do
		if self:getOverflow(p)>1
		and q(p,"getMark","&ov_dingyi3")>0
		and q(p,"getAttackRange")<3
		then
			self.ov_fubi_to = p
			return id
		end
	end
end


remember_function('ai_fill_skill','ov_fubi',sgs.ai_fill_skill['ov_fubi'],{'ov_fubi_choice','ov_fubi_to'},{'ov_fubi_choice','ov_fubi_to'})
sgs.ai_skill_use_func["#ov_fubiCard"] = function(card,use,self)
	if self.ov_fubi_to
	then
		use.card = card
		use.to:append(self.ov_fubi_to)
	end
end


remember_function('ai_skill_use_func','#ov_fubiCard',sgs.ai_skill_use_func['#ov_fubiCard'],{'ov_fubi_to'},{})
sgs.ai_use_value.ov_fubiCard = 3.4
sgs.ai_use_priority.ov_fubiCard = 4.8

sgs.ai_skill_playerchosen.ov_huiyuan = function(self,players)
	local destlist = self:sort(players,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and q(self.player,"inMyAttackRange",target)
		and not q(target,"inMyAttackRange",self.player)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end


remember_function('ai_skill_playerchosen','ov_huiyuan',sgs.ai_skill_playerchosen['ov_huiyuan'],{},{})
sgs.ai_playerchosen_intention.ov_huiyuan = 55

sgs.ai_skill_playerchosen.ov_zhiqu = function(self,players)
	local destlist = self:sort(players,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and q(self.player,"inMyAttackRange",target)
		and q(target,"inMyAttackRange",self.player)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end


remember_function('ai_skill_playerchosen','ov_zhiqu',sgs.ai_skill_playerchosen['ov_zhiqu'],{},{})
sgs.ai_playerchosen_intention.ov_zhiqu = 55

sgs.ai_skill_choice.ov_xianfeng = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target)
	then return items[1] end
	if not self:isWeak() and self:canDraw()
	then return items[2] end
end


remember_function('ai_skill_choice','ov_xianfeng',sgs.ai_skill_choice['ov_xianfeng'],{},{})
sgs.ai_skill_cardask["ov_xingwu0"] = function(self,data,pattern,prompt)
	local damage = data:toDamage()
	if self:getOverflow()>0
	then
		local cs = complete_hand(self,self.player)
		cs = self:sortByKeepValue(cs)
		return q(cs[1],"getEffectiveId")
	end
	if self:isWeak(self.enemies)
	then
		local cs = self.player:getCards("he")
		cs = self:sortByKeepValue(cs)
		return q(cs[1],"getEffectiveId")
	end
end


remember_function('ai_skill_cardask','ov_xingwu0',sgs.ai_skill_cardask['ov_xingwu0'],{},{})
sgs.ai_skill_use["@@ov_xingwu"] = function(self,prompt)
	local valid = {}
	for _,id in sgs.list(self.player:getPile("ov_xingwu"))do
    	table.insert(valid,id)
		if #valid>2 then break end
	end
	self.enemies = self:sort(self.enemies,"hp")
	for _,p in sgs.list(self.enemies)do
		return #valid>2 and "#ov_xingwuCard:"..table.concat(valid,"+")..":->"..p:objectName()
	end
end


remember_function('ai_skill_use','@@ov_xingwu',sgs.ai_skill_use['@@ov_xingwu'],{},{})
sgs.ai_skill_invoke.ov_lijian = function(self,data)
	local target = data:toPlayer()
	self.ov_lijian_to = target
	return true
end


remember_function('ai_skill_invoke','ov_lijian',sgs.ai_skill_invoke['ov_lijian'],{'ov_lijian_to'},{'ov_lijian_to'})
sgs.ai_skill_use["@@ov_lijian"] = function(self,prompt)
	local valid = {}
	local ids = tag(self,"ov_lijianForAI","IntList")
	for _,id in sgs.list(ids)do
    	table.insert(valid,id)
		if #valid>=ids:length()/2 then break end
	end
	if self:isEnemy(self.ov_lijian_to) then table.remove(valid,1) end
	return #valid>0 and "#ov_lijianCard:"..table.concat(valid,"+")..":"
end


remember_function('ai_skill_use','@@ov_lijian',sgs.ai_skill_use['@@ov_lijian'],{'ov_lijian_to'},{})
sgs.ai_skill_invoke.ov_lijian_damage = function(self,data)
	return self:isEnemy(self.ov_lijian_to)
end


remember_function('ai_skill_invoke','ov_lijian_damage',sgs.ai_skill_invoke['ov_lijian_damage'],{'ov_lijian_to'},{})
sgs.ai_fill_skill["ov_quanqian"] = function(self,inclusive,request)
	local ids = {}
	for _,c in sgs.list(self:poisonCards("h"))do
		table.insert(ids,q(c,"getEffectiveId"))
	end
	if self:getOverflow()>0 then
		local cs = complete_hand(self,self.player)
		for _,c in sgs.list(self:sortByKeepValue(cs))do
			if table.contains(ids,q(c,"getEffectiveId")) or #ids>1 then continue end
			table.insert(ids,q(c,"getEffectiveId"))
		end
	end
	return #ids>1 and policy(self,"#ov_quanqianCard:"..table.concat(ids,"+")..":")
end


remember_function('ai_fill_skill','ov_quanqian',sgs.ai_fill_skill['ov_quanqian'],{},{})
sgs.ai_skill_use_func["#ov_quanqianCard"] = function(card,use,self)
	local n = 0
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if q(p,"getHandcardNum")>n then n = q(p,"getHandcardNum") end
	end
	for _,p in sgs.list(self.friends_noself)do
		if q(p,"getHandcardNum")>=n
		then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.enemies)do
		if q(p,"getHandcardNum")>=n
		then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if q(p,"getHandcardNum")>=n
		then
			use.card = card
			use.to:append(p)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_quanqianCard',sgs.ai_skill_use_func['#ov_quanqianCard'],{},{})
sgs.ai_use_value.ov_quanqianCard = 3.4
sgs.ai_use_priority.ov_quanqianCard = 5.8

sgs.ai_skill_choice.ov_quanqian = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	self.ov_quanqian_to = target
	if self:isFriend(target)
	then return items[1] end
	return items[2]
end


remember_function('ai_skill_choice','ov_quanqian',sgs.ai_skill_choice['ov_quanqian'],{'ov_quanqian_to'},{'ov_quanqian_to'})
sgs.ai_skill_suit.ov_quanqian = function(self)
	local sus = {}
	for s,h in sgs.list(self.complete_hand(self,ov_quanqian_to))do
		s = q(h,"getSuit")
		if sus[s] then sus[s] = sus[s]+1
		else sus[s] = 1 end
	end
	local function func(a,b)
		return a>b
	end
	table.sort(sus,func)
	for i,v in pairs(sus)do
		return i
	end
end


remember_function('ai_skill_suit','ov_quanqian',sgs.ai_skill_suit['ov_quanqian'],{},{})
sgs.ai_skill_invoke.ov_shenyi = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isEnemy(target)
		or self.player:isKongcheng()
	end
end


remember_function('ai_skill_invoke','ov_shenyi',sgs.ai_skill_invoke['ov_shenyi'],{},{})
sgs.ai_skill_choice.ov_shenyi = function(self,choices,data)
	local items = choices:split("+")
	local cs = {}
	for _,n in sgs.list(items)do
		table.insert(cs,clone(self,n))
	end
	cs = self:sortByKeepValue(cs,true)
	return cs[1]:objectName()
end


remember_function('ai_skill_choice','ov_shenyi',sgs.ai_skill_choice['ov_shenyi'],{},{})
sgs.ai_fill_skill["ov_xinghan"] = function(self,inclusive,request)
	local cs = {}
	for _,id in sgs.list(self.player:getPile("ov_xiayi"))do
		table.insert(cs,visible(self,id))
	end
	return cs
end


remember_function('ai_fill_skill','ov_xinghan',sgs.ai_fill_skill['ov_xinghan'],{},{})
function sgs.ai_cardsview.ov_xinghan(self,class_name,player)
	for _,id in sgs.list(player:getPile("ov_xiayi"))do
		if visible(self,id):isKindOf(class_name)
		then return id end
	end
end


remember_function('ai_cardsview','ov_xinghan',sgs.ai_cardsview['ov_xinghan'],{},{})
sgs.ai_skill_use["@@ov_xinghan"] = function(self,prompt)
	for _,id in sgs.list(self.player:getPile("ov_xiayi"))do
		local c = visible(self,id)
		local dummy = self:aiUseCard(c)
		if dummy.card then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,p:objectName())
			end
			if q(c,"canRecast") and dummy.to:length()<1 then break end
			return id.."->"..table.concat(tos,"+")
		end
		break
	end
end


remember_function('ai_skill_use','@@ov_xinghan',sgs.ai_skill_use['@@ov_xinghan'],{},{})
sgs.ai_fill_skill["ov_chengxi"] = function(self,inclusive,request)
	local mc = self:getMaxCard()
	if mc and q(mc,"getNumber")>10
	then
		for _,c in sgs.list(self:getPriorTurnUseCards())do
			if (q(c,"getTypeId")==1 or c:isNDTrick()) and mc~=c
			then
				return policy(self,"#ov_chengxiCard:.:")
			end
		end
	end
end


remember_function('ai_fill_skill','ov_chengxi',sgs.ai_fill_skill['ov_chengxi'],{},{})
sgs.ai_skill_use_func["#ov_chengxiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp")
	for _,p in sgs.list(self.enemies)do
		if q(self.player,"canPindian",p)
		then
			use.card = card
			self.ov_chengxi_to = p
			return
		end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if q(self.player,"canPindian",p) and not self:isFriend(p)
		then
			use.card = card
			self.ov_chengxi_to = p
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_chengxiCard',sgs.ai_skill_use_func['#ov_chengxiCard'],{'ov_chengxi_to'},{'ov_chengxi_to'})
sgs.ai_use_value.ov_chengxiCard = 3.4
sgs.ai_use_priority.ov_chengxiCard = 8.8

sgs.ai_skill_playerchosen.ov_chengxi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
    for _,target in sgs.list(destlist)do
    	if target==self.ov_chengxi_to
		then return target end
	end
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
    	if not self:isFriend(target)
		then return target end
	end
    return destlist[1]
end


remember_function('ai_skill_playerchosen','ov_chengxi',sgs.ai_skill_playerchosen['ov_chengxi'],{'ov_chengxi_to'},{})
sgs.ai_playerchosen_intention.ov_chengxi = 55

sgs.ai_skill_invoke.ov_huzhong = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isEnemy(target)
	end
end


remember_function('ai_skill_invoke','ov_huzhong',sgs.ai_skill_invoke['ov_huzhong'],{},{})
sgs.ai_skill_cardask["ov_huzhong0"] = function(self,data,pattern,prompt)
	local use = data:toCardUse()
	for _,p in sgs.list(card_targets(self,self.player,use.card,use.to))do
		if self:canCanmou(p,use)
		then return true end
	end
	return false
end


remember_function('ai_skill_cardask','ov_huzhong0',sgs.ai_skill_cardask['ov_huzhong0'],{},{})
sgs.ai_skill_cardask["ov_fenwang0"] = function(self,data,pattern,prompt)
	return true
end


remember_function('ai_skill_cardask','ov_fenwang0',sgs.ai_skill_cardask['ov_fenwang0'],{},{})
sgs.ai_fill_skill["ov_danlie"] = function(self,inclusive,request)
	local mc = self:getMaxCard()
	if mc and q(mc,"getNumber")+q(self.player,"getLostHp")>10 then
		for _,c in sgs.list(self:getPriorTurnUseCards())do
			if mc~=c then
				return policy(self,"#ov_danlieCard:.:")
			end
		end
	end
end


remember_function('ai_fill_skill','ov_danlie',sgs.ai_fill_skill['ov_danlie'],{},{})
sgs.ai_skill_use_func["#ov_danlieCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp")
	for _,p in sgs.list(self.enemies)do
		if q(self.player,"canPindian",p)
		and use.to:length()<3 then
			use.card = card
			use.to:append(p)
		end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if use.to:length()<3 and not use.to:contains(p) and #self.enemies>0
		and q(self.player,"canPindian",p) and not self:isFriend(p) then
			use.card = card
			use.to:append(p)
		end
	end
end


remember_function('ai_skill_use_func','#ov_danlieCard',sgs.ai_skill_use_func['#ov_danlieCard'],{},{})
sgs.ai_use_value.ov_danlieCard = 3.4
sgs.ai_use_priority.ov_danlieCard = 3.8

sgs.ai_skill_choice.ov_zhongyi = function(self,choices,data)
	local items = choices:split("+")
	local n = items[1]:split("=")[2]
	local m = items[3]:split("=")[2]
	if n-m>1 then return items[3] end
	if self:isWeak() then
		return items[2]
	end
	return items[1]
end


remember_function('ai_skill_choice','ov_zhongyi',sgs.ai_skill_choice['ov_zhongyi'],{},{})
sgs.ai_skill_invoke.ov_chue = function(self,data)
	local use = data:toCardUse()
	if use and use.card then
		local du = self:aiUseCard(use.card,dummy(true,99,use.to))
		if du.card and du.to:length()>0 then
			self.ov_chue_to = du.to
			return not self:isWeak()
		end
	else
		local dc = clone(self)
		dc = mutate(self,dc,"skill","_ov_chue")
		local dummy = self:aiUseCard(dc)
		return dummy.card~=nil
	end
end


remember_function('ai_skill_invoke','ov_chue',sgs.ai_skill_invoke['ov_chue'],{'ov_chue_to'},{'ov_chue_to'})
sgs.ai_skill_playerschosen.ov_chue = function(self,players,x,n)
	local destlist = {}
    for _,p in sgs.list(players)do
		if #destlist<x and self.ov_chue_to:contains(p)
		then table.insert(destlist,p) end
	end
    return destlist
end


remember_function('ai_skill_playerschosen','ov_chue',sgs.ai_skill_playerschosen['ov_chue'],{'ov_chue_to'},{})
sgs.ai_skill_use["@@ov_chue!"] = function(self,prompt)
	local dc = clone(self)
	dc = mutate(self,dc,"skill","_ov_chue")
	local dummy = self:aiUseCard(dc)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return dc:getLegacyStringKey().."->"..table.concat(tos,"+")
	end
end


remember_function('ai_skill_use','@@ov_chue!',sgs.ai_skill_use['@@ov_chue!'],{},{})
sgs.ai_skill_playerchosen.ov_tianshou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
    	if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
    	if not self:isEnemy(target)
		then return target end
	end
    return destlist[1]
end


remember_function('ai_skill_playerchosen','ov_tianshou',sgs.ai_skill_playerchosen['ov_tianshou'],{},{})
sgs.ai_playerchosen_intention.ov_tianshou = -66

sgs.ai_fill_skill["ov_huajing"] = function(self,inclusive,request)
	if self.player:usedTimes("#ov_huajingCard") >= 1 or q(self.player,"getMark","ov_huajing-Clear") > 0 then
		return
	end
	local hasWu = false
	for _, m in sgs.list(self.player:getMarkNames()) do
		if m:endsWith("+#ov_huajingWu") and q(self.player,"getMark",m) > 0 then
			hasWu = true
			break
		end
	end
	if not hasWu then return end
	local ids = {}
	local ss = {}
	local cs = complete_hand(self,self.player)
	cs = self:sortByKeepValue(cs)
	for _,c in sgs.list(cs)do
		if table.contains(ss,q(c,"getSuit"))
		or #ids>#cs/2 then continue end
		table.insert(ids,q(c,"getEffectiveId"))
		table.insert(ss,q(c,"getSuit"))
	end
	return #ids>0 and policy(self,"#ov_huajingCard:"..table.concat(ids,"+")..":")
end


remember_function('ai_fill_skill','ov_huajing',sgs.ai_fill_skill['ov_huajing'],{},{})
sgs.ai_skill_use_func["#ov_huajingCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_huajingCard',sgs.ai_skill_use_func['#ov_huajingCard'],{},{})
sgs.ai_use_value.ov_huajingCard = 3.4
sgs.ai_use_priority.ov_huajingCard = 4.8

sgs.ai_skill_cardask["ov_dengjian0"] = function(self,data,pattern,prompt)
	
	return q(self.player,"getHandcardNum")>2
end


remember_function('ai_skill_cardask','ov_dengjian0',sgs.ai_skill_cardask['ov_dengjian0'],{},{})
sgs.ai_skill_invoke.ov_xinshou = function(self,data)
	local st = data:toString()
	if st~="" then
		return #self.friends>1
	end
	return #self.friends>1
	or q(self.player,"getMark","ov_xinshou1-Clear")<1
end


remember_function('ai_skill_invoke','ov_xinshou',sgs.ai_skill_invoke['ov_xinshou'],{},{})
sgs.ai_skill_playerchosen.ov_xinshou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
    	if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
    	if not self:isEnemy(target)
		then return target end
	end
    return destlist[1]
end


remember_function('ai_skill_playerchosen','ov_xinshou',sgs.ai_skill_playerchosen['ov_xinshou'],{},{})
sgs.ai_playerchosen_intention.ov_xinshou = -66

sgs.ai_fill_skill["ov_jieqiu"] = function(self,inclusive,request)
	return policy(self,"#ov_jieqiuCard:.:")
end


remember_function('ai_fill_skill','ov_jieqiu',sgs.ai_fill_skill['ov_jieqiu'],{},{})
sgs.ai_skill_use_func["#ov_jieqiuCard"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		local can = true
		for i=0,4 do
			if not p:hasEquipArea(i)
			then can = false break end
		end
		if can and #self:poisonCards("e",p)>p:getEquips():length()/2 then
			use.card = card
			use.to:append(p)
			return 
		end
	end
	self.enemies = self:sort(self.enemies,"equip",true)
	for _,p in sgs.list(self.enemies)do
		local can = true
		for i=0,4 do
			if not p:hasEquipArea(i)
			then can = false break end
		end
		if can then
			use.card = card
			use.to:append(p)
			return 
		end
	end
end


remember_function('ai_skill_use_func','#ov_jieqiuCard',sgs.ai_skill_use_func['#ov_jieqiuCard'],{},{})
sgs.ai_use_value.ov_jieqiuCard = 3.4
sgs.ai_use_priority.ov_jieqiuCard = 4.8

sgs.ai_fill_skill["ov_enchou"] = function(self,inclusive,request)
	return policy(self,"#ov_enchouCard:.:")
end


remember_function('ai_fill_skill','ov_enchou',sgs.ai_fill_skill['ov_enchou'],{},{})
sgs.ai_skill_use_func["#ov_enchouCard"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself,"hp",true)
	for _,p in sgs.list(self.friends_noself)do
		local can = false
		for i=0,4 do
			if not p:hasEquipArea(i)
			then can = true break end
		end
		if can then
			use.card = card
			use.to:append(p)
			return 
		end
	end
	self.enemies = self:sort(self.enemies,"hp")
	for _,p in sgs.list(self.enemies)do
		local can = false
		for i=0,4 do
			if not p:hasEquipArea(i)
			then can = q(p,"getHandcardNum")>0 break end
		end
		if can then
			use.card = card
			use.to:append(p)
			return 
		end
	end
end


remember_function('ai_skill_use_func','#ov_enchouCard',sgs.ai_skill_use_func['#ov_enchouCard'],{},{})
sgs.ai_use_value.ov_enchouCard = 3.4
sgs.ai_use_priority.ov_enchouCard = 5.8

sgs.ai_skill_playerschosen.ov_duwang = function(self,players,x,n)
	local destlist = {}
	players = self:sort(players,"handcard")
    for _,p in sgs.list(players)do
		if #destlist<x and p:getCardCount()>0
		then table.insert(destlist,p) end
	end
    return destlist
end


remember_function('ai_skill_playerschosen','ov_duwang',sgs.ai_skill_playerschosen['ov_duwang'],{},{})
sgs.ai_fill_skill["ov_yanshiYL"] = function(self,inclusive,request)
	local cs = complete_hand(self,self.player)
	cs = self:sortByKeepValue(cs)
	local sc = nil
	for _,c in sgs.list(cs)do
		if q(c,"isKindOf","Slash") then sc = c break end
	end
	if sc==nil then return end
	local znc = copy(fact(self,"zhinang_cards"))
	table.insert(znc,"duel")
	for _,pm in sgs.list(znc)do
		local dc = clone(self,pm)
		dc = mutate(self,dc,"skill","ov_yanshiYL")
		dc = mutate(self,dc,"add",sc)
		if q(dc,"isAvailable",self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				if q(dc,"canRecast") and d.to:length()<1 then continue end
				self:setPriorityValue("ov_yanshiYLCard",self:getSourcePriorityValue(q(dc,"getClassName")),"OverseasVersion")
				dynamic(self,'ai_skill_invoke','ov_yanshiYL',pm)
				if q(self.player,"getMark","@ov_yanshiYL")<1
				then return policy(self,"#ov_yanshiYLCard:.:") end
				for _,p in sgs.list(d.to)do
					if self:isWeak(p) then
						return policy(self,"#ov_yanshiYLCard:.:")
					end
				end
			end
		end
	end
end


remember_function('ai_fill_skill','ov_yanshiYL',sgs.ai_fill_skill['ov_yanshiYL'],{},{})
sgs.ai_skill_use_func["#ov_yanshiYLCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_yanshiYLCard',sgs.ai_skill_use_func['#ov_yanshiYLCard'],{},{})
sgs.ai_use_value.ov_yanshiYLCard = 3.4
sgs.ai_use_priority.ov_yanshiYLCard = 5.8

sgs.ai_skill_cardask["ov_yanshiYLuse"] = function(self,data,pattern,prompt)
	local dc = policy(self,property(self,"ov_yanshiYLuse"))
	local dummy = self:aiUseCard(dc)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		if q(dc,"canRecast") and dummy.to:length()<1 then return end
		return dc:getLegacyStringKey().."->"..table.concat(tos,"+")
	end
	return "."
end


remember_function('ai_skill_cardask','ov_yanshiYLuse',sgs.ai_skill_cardask['ov_yanshiYLuse'],{},{})
sgs.ai_fill_skill["ov_juexing"] = function(self,inclusive,request)
	local dc = clone(self,"duel")
	dc = mutate(self,dc,"skill","ov_juexing")
	return dc
end


remember_function('ai_fill_skill','ov_juexing',sgs.ai_fill_skill['ov_juexing'],{},{})
sgs.ai_skill_invoke.ov_qiaosi = function(self,data)
	local st = data:toIntList()
	return st:length()>=q(self.player,"getHp")
	or not self:isWeak() and st:length()>math.random(1,2)
end


remember_function('ai_skill_invoke','ov_qiaosi',sgs.ai_skill_invoke['ov_qiaosi'],{},{})
sgs.ai_skill_playerschosen.ov_baizu = function(self,players,x,n)
	local destlist = {}
	players = self:sort(players,"handcard")
    for _,p in sgs.list(players)do
		if #destlist<x and q(p,"getHandcardNum")>0 and self:isEnemy(p)
		then table.insert(destlist,p) end
	end
    for _,p in sgs.list(players)do
		if #destlist<x and q(p,"getHandcardNum")>0
		and not table.contains(destlist,p) and not self:isFriend(p)
		then table.insert(destlist,p) end
	end
    return destlist
end



remember_function('ai_skill_playerschosen','ov_baizu',sgs.ai_skill_playerschosen['ov_baizu'],{},{})
sgs.ai_skill_invoke.ov_beiding = function(self,data)
	local cp = self.room:getCurrent()
	return cp~=self.player or q(self.player,"getHandcardNum")<3
end


remember_function('ai_skill_invoke','ov_beiding',sgs.ai_skill_invoke['ov_beiding'],{},{})
sgs.ai_skill_choice.ov_beiding = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"cancel") and math.random()>0.5 then
		return "cancel"
	end
	local cs = {}
	local cp = self.room:getCurrent()
    for _,pn in sgs.list(items)do
		local dc = clone(self,pn)
		if dc then
			dc = mutate(self,dc,"skill","ov_beiding")
			if q(dc,"isAvailable",self.player) then
				table.insert(cs,dc)
				if self.player:isProhibited(cp,dc) then continue end
				local d = self:aiUseCard(dc)
				if d.card then
					if d.to:contains(cp) or q(dc,"isKindOf","AOE") or q(dc,"isKindOf","GlobalEffect") then
						return pn
					end
				end
			end
		end
	end
	cs = self:sortByUseValue(cs)
    for _,dc in sgs.list(cs)do
		local d = self:aiUseCard(dc)
		if d.card then
			return pn
		end
	end
	return items[1]
end


remember_function('ai_skill_choice','ov_beiding',sgs.ai_skill_choice['ov_beiding'],{},{})
sgs.ai_skill_use["@@ov_beiding"] = function(self,prompt)
    local dc = property(self,"ov_beidingUse")
	dc = clone(self,dc)
	dc = mutate(self,dc,"skill","_ov_beiding")
    local d = self:aiUseCard(dc)
   	if d.card then
      	if q(dc,"canRecast") and d.to:length()<1 then return end
		local tos = {}
       	for _,p in sgs.list(d.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dc:getLegacyStringKey().."->"..table.concat(tos,"+")
    end
end



remember_function('ai_skill_use','@@ov_beiding',sgs.ai_skill_use['@@ov_beiding'],{},{})
sgs.ai_skill_invoke.ov_hunyou = function(self,data)
	return self:getAllPeachNum()+q(self.player,"getHp")<1
end


remember_function('ai_skill_invoke','ov_hunyou',sgs.ai_skill_invoke['ov_hunyou'],{},{})
sgs.ai_fill_skill["ov_huanji"] = function(self,inclusive,request)
	return q(self.player,"isWounded")
	and policy(self,"#ov_huanjiCard:.:")
end


remember_function('ai_fill_skill','ov_huanji',sgs.ai_fill_skill['ov_huanji'],{},{})
sgs.ai_skill_use_func["#ov_huanjiCard"] = function(card,use,self)
	local n = 0
	for _,h in sgs.list(complete_hand(self,self.player))do
		if h:isNDTrick() or q(h,"isKindOf","BasicCard") then
			if self:wasPreviouslyPlannedCard(h) and q(self.player,"getMark",h:objectName().."ov_beidingHistory")<1
			then n = n+1 end
		end
	end
	if n>q(self.player,"getHp")/2 then
		use.card = card
	end
end


remember_function('ai_skill_use_func','#ov_huanjiCard',sgs.ai_skill_use_func['#ov_huanjiCard'],{},{})
sgs.ai_use_value.ov_huanjiCard = 3.4
sgs.ai_use_priority.ov_huanjiCard = 11.8

sgs.ai_skill_choice.ov_huanji = function(self,choices,data)
	local items = choices:split("+")
	local cs = {}
    for _,pn in sgs.list(items)do
		for _,h in sgs.list(complete_hand(self,self.player))do
			if h:objectName()==pn then
				if self:wasPreviouslyPlannedCard(h)
				then return pn end
			end
		end
		local dc = clone(self,pn)
		dc = mutate(self,dc,"skill","ov_beiding")
		if q(dc,"isAvailable",self.player) then
			table.insert(cs,dc)
		end
	end
	cs = self:sortByUseValue(cs)
    for _,dc in sgs.list(cs)do
		if self:aiUseCard(dc).card then
			return pn
		end
	end
	return items[1]
end


remember_function('ai_skill_choice','ov_huanji',sgs.ai_skill_choice['ov_huanji'],{},{})
sgs.ai_skill_invoke.ov_jiezhan = function(self,data)
	local cp = data:toPlayer()
	return self:canDraw() and self:isEnemy(cp)
	and (self:getCardsNum("Jink")>0 or not self:isWeak())
end


remember_function('ai_skill_invoke','ov_jiezhan',sgs.ai_skill_invoke['ov_jiezhan'],{},{})
sgs.ai_fill_skill["ov_qinghan"] = function(self,inclusive,request)
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	for _,c in sgs.list(cs)do
		if q(c,"isKindOf","EquipCard") and q(c,"getNumber")>9 then
			return policy(self,"#ov_qinghanCard:"..c:getLegacyStringKey()..":")
		end
	end
end


remember_function('ai_fill_skill','ov_qinghan',sgs.ai_fill_skill['ov_qinghan'],{},{})
sgs.ai_skill_use_func["#ov_qinghanCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if q(self.player,"canPindian",p) then
			use.card = card
			use.to:append(p)
			break
		end
	end
end


remember_function('ai_skill_use_func','#ov_qinghanCard',sgs.ai_skill_use_func['#ov_qinghanCard'],{},{})
sgs.ai_use_value.ov_qinghanCard = 3.4
sgs.ai_use_priority.ov_qinghanCard = 5.8

sgs.ai_skill_choice.ov_qinghan = function(self,choices,data)
	local items = choices:split("+")
	local cs = {}
	local cp = data:toPlayer()
    for _,pn in sgs.list(items)do
		local dc = clone(self,pn)
		dc = mutate(self,dc,"skill","ov_qinghan")
		if q(dc,"isAvailable",self.player) then
			table.insert(cs,dc)
			if self.player:isProhibited(cp,dc) then continue end
			local d = self:aiUseCard(dc)
			if d.card then
				if d.to:contains(cp) or q(dc,"isKindOf","AOE") or q(dc,"isKindOf","GlobalEffect") then
					return pn
				end
			end
		end
	end
	cs = self:sortByUseValue(cs)
    for _,dc in sgs.list(cs)do
		if self:aiUseCard(dc).card then
			return pn
		end
	end
	return items[#items]
end


remember_function('ai_skill_choice','ov_qinghan',sgs.ai_skill_choice['ov_qinghan'],{},{})
sgs.ai_skill_invoke.ov_zhihuan = function(self,data)
	local damage = data:toDamage()
	self.ov_zhihuan_to = damage.to
	if self:isEnemy(damage.to) then
		return not self:isWeak(damage.to)
	end
	if self:isFriend(damage.to) then
		return #self:poisonCards("e",damage.to)>0
	end
	return true
end


remember_function('ai_skill_invoke','ov_zhihuan',sgs.ai_skill_invoke['ov_zhihuan'],{'ov_zhihuan_to'},{'ov_zhihuan_to'})
sgs.ai_skill_choice.ov_zhihuan = function(self,choices,data)
	local items = choices:split("+")
	if self:doDisCard(self.ov_zhihuan_to,"e",true) then
		return items[1]
	end
	return items[2]
end


remember_function('ai_skill_choice','ov_zhihuan',sgs.ai_skill_choice['ov_zhihuan'],{'ov_zhihuan_to'},{})
sgs.ai_fill_skill["ov_xianyuan"] = function(self,inclusive,request)
	return policy(self,"#ov_xianyuanCard:.:")
end


remember_function('ai_fill_skill','ov_xianyuan',sgs.ai_fill_skill['ov_xianyuan'],{},{})
sgs.ai_skill_use_func["#ov_xianyuanCard"] = function(card,use,self)
	local n = q(self.player,"getMark","&ov_xianyuan")
	self.friends_noself = self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if use.to:length()<n then
			use.card = card
			use.to:append(p)
		end
	end
	self.enemies = self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if use.to:length()<=n/2 then
			use.card = card
			use.to:append(p)
		end
	end
end


remember_function('ai_skill_use_func','#ov_xianyuanCard',sgs.ai_skill_use_func['#ov_xianyuanCard'],{},{})
sgs.ai_use_value.ov_xianyuanCard = 3.4
sgs.ai_use_priority.ov_xianyuanCard = 0.8

sgs.ai_skill_choice.ov_xianyuan = function(self,choices,data)
	local items = choices:split("+")
	if items[1]:contains("ov_xianyuan0") then
		return items[1]
	end
	local to = data:toPlayer()
	if self:isFriend(to) then
		return items[2]
	end
	return items[1]
end


remember_function('ai_skill_choice','ov_xianyuan',sgs.ai_skill_choice['ov_xianyuan'],{},{})
sgs.ai_skill_invoke.ov_lingyin = function(self,data)
	local use = data:toCardUse()
	return not self:isFriend(use.from) or use.card:isDamageCard()
end


remember_function('ai_skill_invoke','ov_lingyin',sgs.ai_skill_invoke['ov_lingyin'],{},{})
sgs.ai_skill_playerchosen.ov_zongquan = function(self,players,x,n)
	for _,p in sgs.list(players)do
		if p==self.ov_zongquan_tp then
			self.ov_zongquan_tp = nil
			return p
		end
	end
	players = self:sort(players)
    return players[1]
end


remember_function('ai_skill_playerchosen','ov_zongquan',sgs.ai_skill_playerchosen['ov_zongquan'],{'ov_zongquan_tp'},{'ov_zongquan_tp'})
sgs.ai_skill_invoke.ov_guimou = function(self,data)
	local judge = data:toJudge()
	self.ov_guimou_judge = judge
	return self:needRetrial(judge) or judge.reason=="ov_zongquan"
end


remember_function('ai_skill_invoke','ov_guimou',sgs.ai_skill_invoke['ov_guimou'],{'ov_guimou_judge'},{'ov_guimou_judge'})
sgs.ai_skill_askforag.ov_guimou = function(self,card_ids)
	local cs = {}
	for _,id in sgs.list(card_ids)do
		table.insert(cs,visible(self,id))
	end
	local judge = self.ov_guimou_judge
	if judge.reason=="ov_zongquan" then
		if self:isFriend(judge.who) then
			if tag(self,"ov_zongquanTo","Player")==judge.who then
				for _,c in sgs.list(cs)do
					if judge.foreign_tag(self,who,"ov_zongquanJudge","String")~=q(c,"getColorString") and c:isRed() then
						return c:getId()
					end
				end
			else
				for _,c in sgs.list(cs)do
					if c:isBlack() then
						self.ov_zongquan_tp = judge.who
						return c:getId()
					end
				end
			end
		else
			if tag(self,"ov_zongquanTo","Player")==judge.who then
				for _,c in sgs.list(cs)do
					if judge.foreign_tag(self,who,"ov_zongquanJudge","String")~=q(c,"getColorString") and c:isBlack() then
						return c:getId()
					end
				end
			elseif math.random()<0.5 then
				for _,c in sgs.list(cs)do
					if c:isRed() then
						self.ov_zongquan_tp = judge.who
						return c:getId()
					end
				end
			end
		end
	end
	local id = self:getRetrialCardId(cs,judge)
	if id>-1 then return id end
	return card_ids[1]
end


remember_function('ai_skill_askforag','ov_guimou',sgs.ai_skill_askforag['ov_guimou'],{'ov_guimou_judge','ov_zongquan_tp'},{'ov_zongquan_tp'})
sgs.ai_skill_playerchosen.ov_zongquan1 = function(self,players,x,n)
	players = self:sort(players)
	for _,p in sgs.list(players)do
		if self:isFriend(p) and self:canDraw(p) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isFriend(p) then
			return p
		end
	end
    return players[1]
end


remember_function('ai_skill_playerchosen','ov_zongquan1',sgs.ai_skill_playerchosen['ov_zongquan1'],{},{})
sgs.ai_skill_playerchosen.ov_qiji = function(self,players,x,n)
	local dc = clone(self)
	dc = mutate(self,dc,"skill","ov_liyuan")
	local d = self:aiUseCard(dc)
	for _,p in sgs.list(players)do
		if d.to:contains(p) and not self:isFriend(p) then
			return p
		end
	end
end


remember_function('ai_skill_playerchosen','ov_qiji',sgs.ai_skill_playerchosen['ov_qiji'],{},{})
sgs.ai_skill_playerchosen.ov_qiji1 = function(self,players,x,n)
	players = self:sort(players,nil,true)
	for _,p in sgs.list(players)do
		if self:isFriend(p) and self:canDraw(p) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isFriend(p) then
			return p
		end
	end
end


remember_function('ai_skill_playerchosen','ov_qiji1',sgs.ai_skill_playerchosen['ov_qiji1'],{},{})
sgs.ai_skill_invoke.ov_qiji2 = function(self,data)
	local sts = data:toString():split(":")
	local to = BeMan(self.room,sts[2])
	return self:isFriend(to)
	and (not self:isWeak() or self:getCardsNum("Jink")>0)
end


remember_function('ai_skill_invoke','ov_qiji2',sgs.ai_skill_invoke['ov_qiji2'],{},{})
sgs.ai_fill_skill["ov_lifeng"] = function(self,inclusive,request)
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	self.enemies = self:sort(self.enemies)
	for i,c in sgs.list(cs)do
		for n,h in sgs.list(cs)do
			if i<n and self:getKeepValue(h)<6 then
				local x = math.abs(q(c,"getNumber")-q(h,"getNumber"))
				for _,p in sgs.list(self.enemies)do
					if q(self.player,"distanceTo",p)<=x and self:damageIsEffective(p) then
						local ids = {c:getId(),h:getId()}
						self.ov_lifeng_to = p
						return policy(self,"#ov_lifengCard:"..table.concat(ids,"+")..":")
					end
				end
			end
		end
	end
end


remember_function('ai_fill_skill','ov_lifeng',sgs.ai_fill_skill['ov_lifeng'],{'ov_lifeng_to'},{'ov_lifeng_to'})
sgs.ai_skill_use_func["#ov_lifengCard"] = function(card,use,self)
	if self.ov_lifeng_to then
		use.card = card
		use.to:append(self.ov_lifeng_to)
	end
end


remember_function('ai_skill_use_func','#ov_lifengCard',sgs.ai_skill_use_func['#ov_lifengCard'],{'ov_lifeng_to'},{})
sgs.ai_use_value.ov_lifengCard = 3.4
sgs.ai_use_priority.ov_lifengCard = 1.8


sgs.ai_skill_cardask["ov_lifeng0"] = function(self,data,pattern,prompt)
	if self:isWeak() or self.player:getCardCount()>3 then
		return true
	end
end


remember_function('ai_skill_cardask','ov_lifeng0',sgs.ai_skill_cardask['ov_lifeng0'],{},{})
sgs.ai_skill_invoke.ov_lifeng = function(self,data)
	return true
end


remember_function('ai_skill_invoke','ov_lifeng',sgs.ai_skill_invoke['ov_lifeng'],{},{})
sgs.ai_skill_use["@@ov_niwo"] = function(self,prompt)
	local valid = {}
    local ucs,_,unknown = self:getTurnUse();if unknown then error(unknown,0)end
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if same_card_in(ucs,h) then continue end
    	table.insert(valid,q(h,"getEffectiveId"))
	end
    self.enemies = self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
		if q(p,"getHandcardNum")>1 and q(p,"getHandcardNum")<=#valid and q(self.player,"inMyAttackRange",p) then
			local ids = {}
			for i=1,q(p,"getHandcardNum") do
				table.insert(ids,valid[i])
			end
			return string.format("#ov_niwoCard:%s:->%s",table.concat(ids,"+"),p:objectName())
		end
	end
    for _,p in sgs.list(self.enemies)do
		if q(p,"getHandcardNum")>0 and q(p,"getHandcardNum")<=#valid and q(self.player,"inMyAttackRange",p) then
			local ids = {}
			for i=1,q(p,"getHandcardNum") do
				table.insert(ids,valid[i])
			end
			return string.format("#ov_niwoCard:%s:->%s",table.concat(ids,"+"),p:objectName())
		end
	end
    for _,p in sgs.list(self.enemies)do
		if q(p,"getHandcardNum")>0 and q(self.player,"inMyAttackRange",p) then
			local ids = {}
			for i=1,math.min(#valid,q(p,"getHandcardNum")) do
				table.insert(ids,valid[i])
			end
			return string.format("#ov_niwoCard:%s:->%s",table.concat(ids,"+"),p:objectName())
		end
	end
    for _,p in sgs.list(self.enemies)do
		if q(p,"getHandcardNum")>0 then
			local ids = {}
			for i=1,math.min(#valid,q(p,"getHandcardNum")) do
				table.insert(ids,valid[i])
			end
			return string.format("#ov_niwoCard:%s:->%s",table.concat(ids,"+"),p:objectName())
		end
	end
end


remember_function('ai_skill_use','@@ov_niwo',sgs.ai_skill_use['@@ov_niwo'],{},{})
sgs.ai_skill_cardask["ov_guihan0"] = function(self,data,pattern,prompt)
	if self:isWeak() or self.player:getCardCount()>2 then
		return true
	end
end


remember_function('ai_skill_cardask','ov_guihan0',sgs.ai_skill_cardask['ov_guihan0'],{},{})
sgs.ai_fill_skill["ov_guihan"] = function(self,inclusive,request)
	return policy(self,"#ov_guihanCard:.:")
end


remember_function('ai_fill_skill','ov_guihan',sgs.ai_fill_skill['ov_guihan'],{},{})
sgs.ai_skill_use_func["#ov_guihanCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if use.to:length()<3 and q(p,"getHandcardNum")>0 and q(p,"isWounded") then
			use.card = card
			use.to:append(p)
		end
	end
	local tos = self:sort(self.room:getAlivePlayers())
	for _,p in sgs.list(tos)do
		if use.to:length()<3 and q(p,"getHandcardNum")>0 and not use.to:contains(p)
		and q(p,"isWounded") and not self:isFriend(p) then
			use.card = card
			use.to:append(p)
		end
	end
end


remember_function('ai_skill_use_func','#ov_guihanCard',sgs.ai_skill_use_func['#ov_guihanCard'],{},{})
sgs.ai_use_value.ov_guihanCard = 3.4
sgs.ai_use_priority.ov_guihanCard = 2.8

sgs.ai_skill_choice.ov_guihan = function(self,choices,data)
	local items = choices:split("+")
	return items[2]
end


remember_function('ai_skill_choice','ov_guihan',sgs.ai_skill_choice['ov_guihan'],{},{})
sgs.ai_fill_skill["ov_renxian"] = function(self,inclusive,request)
	return policy(self,"#ov_renxianCard:.:")
end


remember_function('ai_fill_skill','ov_renxian',sgs.ai_fill_skill['ov_renxian'],{},{})
sgs.ai_skill_use_func["#ov_renxianCard"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			for _,h in sgs.list(complete_hand(self,self.player))do
				if q(h,"isKindOf","BasicCard") and q(h,"isAvailable",p) and sgs.ais[p:objectName()]:aiUseCard(h).card then
					use.card = card
					use.to:append(p)
					return
				end
			end
		end
	end
end


remember_function('ai_skill_use_func','#ov_renxianCard',sgs.ai_skill_use_func['#ov_renxianCard'],{},{})
sgs.ai_use_value.ov_renxianCard = 3.4
sgs.ai_use_priority.ov_renxianCard = -1.8

sgs.ai_skill_playerchosen.ov_chenxun = function(self,players,x,n)
	local dc = clone(self,"duel")
	dc = mutate(self,dc,"skill","ov_chenxun")
	local d = self:aiUseCard(dc,dummy(nil,9))
	for _,p in sgs.list(players)do
		if d.to:contains(p) and q(p,"getMark","ov_chenxunTo_lun")<1
		and not self:isFriend(p) then
			return p
		end
	end
end


remember_function('ai_skill_playerchosen','ov_chenxun',sgs.ai_skill_playerchosen['ov_chenxun'],{},{})
sgs.ai_skill_invoke.ov_chihui = function(self,data)
	local cp = self.room:getCurrent()
	return self:doDisCard(to,"ej") or self:isFriend(cp) and self:isWeak(cp)
end


remember_function('ai_skill_invoke','ov_chihui',sgs.ai_skill_invoke['ov_chihui'],{},{})
sgs.ai_skill_choice.ov_xianyuan = function(self,choices,data)
	local items = choices:split("+")
	if items[1]:contains("ov_chihui") then
		local cp = self.room:getCurrent()
		if self:doDisCard(to,"ej") then
			return items[1]
		end
	end
	return items[#items]
end


remember_function('ai_skill_choice','ov_xianyuan',sgs.ai_skill_choice['ov_xianyuan'],{},{})
sgs.ai_skill_invoke.ov_fuxi = function(self,data)
	return self:canDraw() or q(self.player,"getHp")<1
end


remember_function('ai_skill_invoke','ov_fuxi',sgs.ai_skill_invoke['ov_fuxi'],{},{})
sgs.ai_skill_choice.ov_fuxi = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"ov_fuxi4") then
		return "ov_fuxi4"
	end
	if table.contains(items,"ov_fuxi3") and q(self.player,"getHandcardNum")<3 then
		return "ov_fuxi3"
	end
	if table.contains(items,"ov_fuxi1") and self:isWeak(self.enemies) then
		return "ov_fuxi1"
	end
	return items[#items]
end


remember_function('ai_skill_choice','ov_fuxi',sgs.ai_skill_choice['ov_fuxi'],{},{})
sgs.ai_skill_invoke.ov_huangzhu = function(self,data)
	return self:canDraw()
end


remember_function('ai_skill_invoke','ov_huangzhu',sgs.ai_skill_invoke['ov_huangzhu'],{},{})
sgs.ai_fill_skill["ov_liyuan"] = function(self,inclusive,request)
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	for _,c in sgs.list(cs)do
		if q(c,"isKindOf","EquipCard") and not self.player:hasEquipArea(known(c:getEquipSlot(),"source equipment slot")) then
			local dc = clone(self)
			dc = mutate(self,dc,"skill","ov_liyuan")
			dc = mutate(self,dc,"add",c)
			return dc
		end
	end
end


remember_function('ai_fill_skill','ov_liyuan',sgs.ai_fill_skill['ov_liyuan'],{},{})
sgs.ai_skill_discard.ov_shouzhu = function(self,max,min,optional)
	local to_cards = {}
	local target = self.room:getCurrent()
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>#cards/2 or #to_cards>2 or self:isEnemy(target) then break end
		table.insert(to_cards,q(h,"getEffectiveId"))
	end
	return to_cards
end


remember_function('ai_skill_discard','ov_shouzhu',sgs.ai_skill_discard['ov_shouzhu'],{},{})
sgs.ai_skill_playerschosen.ov_daigui = function(self,players,x,n)
	local destlist = {}
	players = self:sort(players)
    for _,p in sgs.list(players)do
		if #destlist<x and self:isFriend(p) and self:canDraw(p)
		then table.insert(destlist,p) end
	end
    for _,p in sgs.list(players)do
		if #destlist<x and self:canDraw(p)
		and not table.contains(destlist,p) and not self:isEnemy(p)
		then table.insert(destlist,p) end
	end
    return destlist
end


remember_function('ai_skill_playerschosen','ov_daigui',sgs.ai_skill_playerschosen['ov_daigui'],{},{})
sgs.ai_fill_skill["ov_cairu"] = function(self,inclusive,request)
	local ts = {}
	if q(self.player,"getMark","fire_attackov_cairuUse-Clear")<2 then
		table.insert(ts,"fire_attack")
	end
	if q(self.player,"getMark","iron_chainov_cairuUse-Clear")<2 then
		table.insert(ts,"iron_chain")
	end
	if q(self.player,"getMark","ex_nihiloov_cairuUse-Clear")<2 then
		table.insert(ts,"ex_nihilo")
	end
	if #ts <1 then return end
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
		for n,h in sgs.list(cs)do
			if i<n and q(c,"getColor")~=q(h,"getColor") and self:getKeepValue(h)<6 then
				local dc = clone(self,ts[math.random(1,#ts)])
				dc = mutate(self,dc,"skill","ov_cairu")
				dc = mutate(self,dc,"can_recast",false)
				dc = mutate(self,dc,"add",h)
				dc = mutate(self,dc,"add",c)
				if q(dc,"isAvailable",self.player) and self:aiUseCard(dc).card then
					return dc
				end
			end
		end
	end
end


remember_function('ai_fill_skill','ov_cairu',sgs.ai_fill_skill['ov_cairu'],{},{})
sgs.ai_skill_playerchosen.tongxin = function(self,players,x,n)
	players = self:sort(players,nil,true)
	for _,p in sgs.list(players)do
		if self:isFriend(p) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if not self:isEnemy(p) then
			return p
		end
	end
end


remember_function('ai_skill_playerchosen','tongxin',sgs.ai_skill_playerchosen['tongxin'],{},{})
sgs.ai_playerchosen_intention.tongxin = -44

sgs.ai_skill_invoke.ov_ciyin = function(self,data)
	return self:canDraw()
end


remember_function('ai_skill_invoke','ov_ciyin',sgs.ai_skill_invoke['ov_ciyin'],{},{})
sgs.ai_skill_choice.ov_ciyin = function(self,choices,data)
	local items = choices:split("+")
	return items[1]
end


remember_function('ai_skill_choice','ov_ciyin',sgs.ai_skill_choice['ov_ciyin'],{},{})
sgs.ai_skill_choice.ov_qiyiju = function(self,choices,data)
	local items = choices:split("+")
	if self:isWeak() then return items[1] end
	return items[2]
end


remember_function('ai_skill_choice','ov_qiyiju',sgs.ai_skill_choice['ov_qiyiju'],{},{})
sgs.ai_skill_playerschosen.ov_jushou = function(self,players,x,n)
	local destlist = {}
	players = self:sort(players,nil,true)
    for _,p in sgs.list(players)do
		if #destlist<x and self:isFriend(p)
		then table.insert(destlist,p) end
	end
    for _,p in sgs.list(players)do
		if #destlist<x and self:isEnemy(p)
		and not table.contains(destlist,p)
		then table.insert(destlist,p) end
	end
    for _,p in sgs.list(players)do
		if #destlist<x and not table.contains(destlist,p)
		then table.insert(destlist,p) end
	end
    return destlist
end


remember_function('ai_skill_playerschosen','ov_jushou',sgs.ai_skill_playerschosen['ov_jushou'],{},{})
sgs.ai_skill_choice.ov_jushou = function(self,choices,data)
	local items = choices:split("+")
	local from = data:toPlayer()
	if not self:isEnemy(from) then return items[1] end
	return items[2]
end


remember_function('ai_skill_choice','ov_jushou',sgs.ai_skill_choice['ov_jushou'],{},{})
sgs.ai_fill_skill["ov_liaoluanvs"] = function(self,inclusive,request)
	return policy(self,"#ov_liaoluanCard:.:")
end


remember_function('ai_fill_skill','ov_liaoluanvs',sgs.ai_fill_skill['ov_liaoluanvs'],{},{})
sgs.ai_skill_use_func["#ov_liaoluanCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if q(self.player,"inMyAttackRange",p) and self:damageIsEffective(p) and self:isWeak(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
	if q(self.player,"faceUp") then return end
	for _,p in sgs.list(self.enemies)do
		if q(self.player,"inMyAttackRange",p) and self:damageIsEffective(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.enemies)do
		if q(self.player,"inMyAttackRange",p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if q(self.player,"inMyAttackRange",p) and not self:isFriend(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_liaoluanCard',sgs.ai_skill_use_func['#ov_liaoluanCard'],{},{})
sgs.ai_use_value.ov_liaoluanCard = 3.4
sgs.ai_use_priority.ov_liaoluanCard = 1.8

sgs.ai_skill_playerchosen.ov_huaying = function(self,players,x,n)
	players = self:sort(players,nil,true)
	for _,p in sgs.list(players)do
		if self:isFriend(p) and not q(p,"faceUp") then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isFriend(p) and p:isChained() then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isFriend(p) and q(p,"getMark","ov_liaoluanUse")>0 then
			return p
		end
	end
end


remember_function('ai_skill_playerchosen','ov_huaying',sgs.ai_skill_playerchosen['ov_huaying'],{},{})
sgs.ai_playerchosen_intention.ov_huaying = -66

sgs.ai_skill_playerschosen.ov_juqian = function(self,players,x,n)
    return sgs.ai_skill_playerschosen.ov_jushou(self,players,x,n)
end


remember_function('ai_skill_playerschosen','ov_juqian',sgs.ai_skill_playerschosen['ov_juqian'],{},{})
sgs.ai_skill_choice.ov_juqian = function(self,choices,data)
	return sgs.ai_skill_choice.ov_jushou(self,choices,data)
end


remember_function('ai_skill_choice','ov_juqian',sgs.ai_skill_choice['ov_juqian'],{},{})
sgs.ai_skill_playerschosen.ov_juluan = function(self,players,x,n)
    return sgs.ai_skill_playerschosen.ov_jushou(self,players,x,n)
end


remember_function('ai_skill_playerschosen','ov_juluan',sgs.ai_skill_playerschosen['ov_juluan'],{},{})
sgs.ai_skill_choice.ov_juluan = function(self,choices,data)
	return sgs.ai_skill_choice.ov_jushou(self,choices,data)
end


remember_function('ai_skill_choice','ov_juluan',sgs.ai_skill_choice['ov_juluan'],{},{})
sgs.ai_skill_invoke.ov_xianxing = function(self,data)
	return self:canDraw()
end


remember_function('ai_skill_invoke','ov_xianxing',sgs.ai_skill_invoke['ov_xianxing'],{},{})
sgs.ai_skill_choice.ov_xianxing = function(self,choices,data)
	local items = choices:split("+")
	if q(self.player,"getMark","&ov_xianxing-Clear")<4 and not self:isWeak()
	then return items[1] end
	return items[2]
end


remember_function('ai_skill_choice','ov_xianxing',sgs.ai_skill_choice['ov_xianxing'],{},{})
sgs.ai_fill_skill["ov_xijun"] = function(self,inclusive,request)
	local ts = {"slash","duel"}
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
		if c:isBlack() and self:getKeepValue(c)<6 then
			local dc = clone(self,ts[math.random(1,2)])
			dc = mutate(self,dc,"skill","ov_xijun")
			dc = mutate(self,dc,"add",c)
			if q(dc,"isAvailable",self.player) and self:aiUseCard(dc).card then
				return dc
			end
		end
	end
end


remember_function('ai_fill_skill','ov_xijun',sgs.ai_fill_skill['ov_xijun'],{},{})
sgs.ai_skill_use["@@ov_xijun"] = function(self,prompt)
	local ts = {"slash","duel"}
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
		if c:isBlack() and self:getKeepValue(c)<6 then
			local dc = clone(self,ts[math.random(1,2)])
			dc = mutate(self,dc,"skill","ov_xijun")
			dc = mutate(self,dc,"add",c)
			if q(dc,"isAvailable",self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					local tos = {}
					for _,p in sgs.list(d.to)do
						table.insert(tos,p:objectName())
					end
					return dc:getLegacyStringKey().."->"..table.concat(tos,"+")
				end
			end
		end
	end
end


remember_function('ai_skill_use','@@ov_xijun',sgs.ai_skill_use['@@ov_xijun'],{},{})
function sgs.ai_cardsview.ov_xijun(self,class_name,player)
	local dc = clone(self,class_name)
	if dc then
		dc = mutate(self,dc,"skill","ov_xijun")
		local cards = sgs.QList2Table(player:getCards("he"))
		cards = self:sortByKeepValue(cards)
		for _,c in sgs.list(cards)do
			if c:isBlack() then
				dc = mutate(self,dc,"add",c)
				if not self.player:isLocked(dc) then
					return dc:getLegacyStringKey()
				end
				dc = mutate(self,dc,"subcards",{})
			end
		end
	end
end


remember_function('ai_cardsview','ov_xijun',sgs.ai_cardsview['ov_xijun'],{},{})
sgs.ai_use_revises["&ov_xijun"] = function(self,card,use)
	if q(card,"isKindOf","Peach") or q(card,"isKindOf","Analeptic") and q(self.player,"getHp")<1 then
		if q(self.player,"getMark","&ov_xijun+no_recover-Clear")>0 then
			return false
		end
	end
end


remember_function('ai_use_revises','&ov_xijun',sgs.ai_use_revises['&ov_xijun'],{},{})
sgs.ai_skill_cardask["ov_ronggui0"] = function(self,data,pattern,prompt)
	local use = data:toCardUse()
	write_delegate(self,"JincanmouData",data:toCardUse())
	local tos = card_targets(self,self.player,use.card,use.to)
	local to = sgs.ai_skill_playerchosen.ov_ronggui(self,tos)
	if to then return true end
end


remember_function('ai_skill_cardask','ov_ronggui0',sgs.ai_skill_cardask['ov_ronggui0'],{},{})
sgs.ai_skill_playerchosen.ov_ronggui = function(self,players)
	return sgs.ai_skill_playerchosen.jincanmou(self,players)
end


remember_function('ai_skill_playerchosen','ov_ronggui',sgs.ai_skill_playerchosen['ov_ronggui'],{},{})
sgs.ai_skill_invoke.ov_tanlu = function(self,data)
	local to = data:toPlayer()
	return self:isEnemy(to) or not self:isFriend(to) and self:isWeak()
end


remember_function('ai_skill_invoke','ov_tanlu',sgs.ai_skill_invoke['ov_tanlu'],{},{})
sgs.ai_skill_discard.ov_tanlu = function(self,max,min,optional)
	local to_cards = {}
	local target = self.room:getCurrent()
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min or self:isEnemy(target) and not self:isWeak() then break end
		table.insert(to_cards,q(h,"getEffectiveId"))
	end
	return #to_cards>=min and to_cards
end


remember_function('ai_skill_discard','ov_tanlu',sgs.ai_skill_discard['ov_tanlu'],{},{})
sgs.ai_fill_skill["ov_bimeng"] = function(self,inclusive,request)
	local ts = {}
	local cs = self.player:getCards("h")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
		if self:getKeepValue(c)<6 then
			table.insert(ts,c)
		end
	end
	if #ts<q(self.player,"getHp") then return end
	cs = {}
	for _,pn in sgs.list(source_patterns(self))do
		local dc = clone(self,pn)
		if dc:isNDTrick() or q(dc,"getTypeId")==1 then
			dc = mutate(self,dc,"skill","ov_bimeng")
			for i=1,q(self.player,"getHp") do
				dc = mutate(self,dc,"add",ts[i])
			end
			if q(dc,"isAvailable",self.player) then
				table.insert(cs,dc)
			end
		end
	end
	cs = self:sortByUseValue(cs)
	for i,c in sgs.list(cs)do
		if self:aiUseCard(c).card then
			return c
		end
	end
end


remember_function('ai_fill_skill','ov_bimeng',sgs.ai_fill_skill['ov_bimeng'],{},{})
sgs.ai_skill_invoke.ov_zhue = function(self,data)
	local use = data:toCardUse()
	return self:isFriend(use.from) and self:canDraw(use.from)
end


remember_function('ai_skill_invoke','ov_zhue',sgs.ai_skill_invoke['ov_zhue'],{},{})
sgs.ai_skill_cardask["ov_fuzhu0"] = function(self,data,pattern,prompt)
	local use = data:toCardUse()
	if self:isFriend(use.from) then
		local cards = self.player:getCards("h")
		cards = self:sortByKeepValue(cards)
		for _,h in sgs.list(cards)do
			if q(h,"getTypeId")==2 and q(h,"isAvailable",use.from) then return h:getLegacyStringKey() end
		end
		return true
	end
end


remember_function('ai_skill_cardask','ov_fuzhu0',sgs.ai_skill_cardask['ov_fuzhu0'],{},{})
sgs.ai_skill_use["@@ov_fuzhu"] = function(self,prompt)
    for _,id in sgs.list(tag(self,"ov_fuzhuForAI","IntList"))do
		local dc = visible(self,id)
		if q(dc,"getTypeId")==2 and q(dc,"isAvailable",self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				if q(dc,"canRecast") and d.to:length()<1
				then continue end
				local tos = {}
				for _,p in sgs.list(d.to)do
					table.insert(tos,p:objectName())
				end
				return id.."->"..table.concat(tos,"+")
			end
		end
	end
end


remember_function('ai_skill_use','@@ov_fuzhu',sgs.ai_skill_use['@@ov_fuzhu'],{},{})
sgs.ai_fill_skill["ov_fenxian"] = function(self,inclusive,request)
	return policy(self,"#ov_fenxianCard:.:")
end


remember_function('ai_fill_skill','ov_fenxian',sgs.ai_fill_skill['ov_fenxian'],{},{})
sgs.ai_skill_use_func["#ov_fenxianCard"] = function(card,use,self)
	for _,p in sgs.list(self.friends)do
		if #self:poisonCards("ej",p)>0 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	self.enemies = self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if not self.player:hasEquip() and p:hasEquip() and #self:poisonCards("ej",p)<1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.enemies)do
		if #self.friends<2 and p:hasEquip() and not self.player:hasEquip() then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.enemies)do
		if #self.friends<2 and p:hasEquip() and #self:poisonCards("ej")==self.player:getEquips():length() then
			use.card = card
			use.to:append(p)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_fenxianCard',sgs.ai_skill_use_func['#ov_fenxianCard'],{},{})
sgs.ai_use_value.ov_fenxianCard = 3.4
sgs.ai_use_priority.ov_fenxianCard = 8.8

sgs.ai_skill_playerchosen.ov_fenxian = function(self,players,x,n)
	players = self:sort(players)
	for _,p in sgs.list(players)do
		if self:doDisCard(p,"ej",true) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isEnemy(p) then
			return p
		end
	end
end


remember_function('ai_skill_playerchosen','ov_fenxian',sgs.ai_skill_playerchosen['ov_fenxian'],{},{})
sgs.ai_skill_playerschosen.ov_fenxian = function(self,players,x,n)
	players = self:sort(players)
	local tos = {}
	local dc = clone(self,"duel")
	local d = self:aiUseCard(dc)
	for _,p in sgs.list(players)do
		if d.to:contains(p) and #tos<x then
			table.insert(tos,p)
		end
	end
	for _,p in sgs.list(players)do
		if not table.contains(tos,p) and self:isEnemy(p) and #tos<x then
			table.insert(tos,p)
		end
	end
	return tos
end


remember_function('ai_skill_playerschosen','ov_fenxian',sgs.ai_skill_playerschosen['ov_fenxian'],{},{})
sgs.ai_fill_skill["ov_shiyi"] = function(self,inclusive,request)
	return policy(self,"#ov_shiyiCard:.:")
end


remember_function('ai_fill_skill','ov_shiyi',sgs.ai_fill_skill['ov_shiyi'],{},{})
sgs.ai_skill_use_func["#ov_shiyiCard"] = function(card,use,self)
	for _,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if not self:isEnemy(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end


remember_function('ai_skill_use_func','#ov_shiyiCard',sgs.ai_skill_use_func['#ov_shiyiCard'],{},{})
sgs.ai_use_value.ov_shiyiCard = 3.4
sgs.ai_use_priority.ov_shiyiCard = 8.8

sgs.ai_skill_playerchosen.ov_chunhui = function(self,players,x,n)
	players = self:sort(players)
	for _,p in sgs.list(players)do
		if self:isFriend(p) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if not self:isEnemy(p) and #self.friends<2 then
			return p
		end
	end
end


remember_function('ai_skill_playerchosen','ov_chunhui',sgs.ai_skill_playerchosen['ov_chunhui'],{},{})
sgs.ai_playerchosen_intention.ov_chunhui = -66

sgs.ai_skill_invoke.ov_miewei = function(self,data)
	return #self.enemies>0
end


remember_function('ai_skill_invoke','ov_miewei',sgs.ai_skill_invoke['ov_miewei'],{},{})
sgs.ai_fill_skill["ov_miyong"] = function(self,inclusive,request)
	local cs = self.player:getCards("h")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
		if q(c,"isKindOf","Slash") and self:wasPreviouslyPlannedCard(c)
		and #self.enemies>0 and self:hasCrossbowEffect() then
			return policy(self,"#ov_miyongCard:"..c:getLegacyStringKey()..":")
		end
	end
end


remember_function('ai_fill_skill','ov_miyong',sgs.ai_fill_skill['ov_miyong'],{},{})
sgs.ai_skill_use_func["#ov_miyongCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_miyongCard',sgs.ai_skill_use_func['#ov_miyongCard'],{},{})
sgs.ai_use_value.ov_miyongCard = 3.4
sgs.ai_use_priority.ov_miyongCard = 1.8

sgs.ai_fill_skill["ov_hanhong"] = function(self,inclusive,request)
	if self:getOverflow()>0 then
		for _,s in sgs.list({"heart","diamond","club","spade"}) do
			if q(self.player,"getMark","ov_hanhong_tiansuan_remove_"..s.."-PlayClear")<1
			then return policy(self,"#ov_hanhongCard:.:"..s) end
		end
	end
end


remember_function('ai_fill_skill','ov_hanhong',sgs.ai_fill_skill['ov_hanhong'],{},{})
sgs.ai_skill_use_func["#ov_hanhongCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_hanhongCard',sgs.ai_skill_use_func['#ov_hanhongCard'],{},{})
sgs.ai_use_value.ov_hanhongCard = 3.4
sgs.ai_use_priority.ov_hanhongCard = 1.8

sgs.ai_skill_invoke.ov_miewei = function(self,data)
	return self:getOverflow()<1
end


remember_function('ai_skill_invoke','ov_miewei',sgs.ai_skill_invoke['ov_miewei'],{},{})
sgs.ai_fill_skill["ov_qianxiong"] = function(self,inclusive,request)
	return policy(self,"#ov_qianxiongCard:.:")
end


remember_function('ai_fill_skill','ov_qianxiong',sgs.ai_fill_skill['ov_qianxiong'],{},{})
sgs.ai_skill_use_func["#ov_qianxiongCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		use.card = card
		use.to:append(p)
		break
	end
end


remember_function('ai_skill_use_func','#ov_qianxiongCard',sgs.ai_skill_use_func['#ov_qianxiongCard'],{},{})
sgs.ai_use_value.ov_qianxiongCard = 3.4
sgs.ai_use_priority.ov_qianxiongCard = 8.8

sgs.ai_skill_choice.ov_qianxiong = function(self,choices,data)
	local tp = data:toPlayer()
	local ids = tp:getPile("ov_qianxiong")
	local cs = {}
	for _,id in sgs.list(ids)do
		local c = visible(self,id)
		if self:aiUseCard(c).card then table.insert(cs,c) end
	end
	if #cs>ids:length()/2 then
		return items[2]
	end
	return items[1]
end


remember_function('ai_skill_choice','ov_qianxiong',sgs.ai_skill_choice['ov_qianxiong'],{},{})
sgs.ai_skill_use["@@ov_qianxiong"] = function(self,prompt)
    for _,id in sgs.list(tag(self,"ov_qianxiongForAI","IntList"))do
		local dc = visible(self,id)
		if q(dc,"isAvailable",self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				if q(dc,"canRecast") and d.to:length()<1
				then continue end
				local tos = {}
				for _,p in sgs.list(d.to)do
					table.insert(tos,p:objectName())
				end
				return id.."->"..table.concat(tos,"+")
			end
		end
	end
end


remember_function('ai_skill_use','@@ov_qianxiong',sgs.ai_skill_use['@@ov_qianxiong'],{},{})
sgs.ai_skill_playerschosen.ov_zhengdi = function(self,players,x,n)
	players = self:sort(players)
	local tps = {}
	for _,p in sgs.list(players)do
		if #tps<x then
			table.insert(tps,p)
		end
	end
	return tps
end


remember_function('ai_skill_playerschosen','ov_zhengdi',sgs.ai_skill_playerschosen['ov_zhengdi'],{},{})
sgs.ai_skill_playerchosen.ov_zhengdi = function(self,players)
	players = self:sort(players)
	return players[#players]
end


remember_function('ai_skill_playerchosen','ov_zhengdi',sgs.ai_skill_playerchosen['ov_zhengdi'],{},{})
sgs.ai_skill_choice.ov_zhengdi = function(self,choices,data)
	local items = choices:split("+")
	local from = data:toPlayer()
	if self:isFriend(from) then return items[1] end
end


remember_function('ai_skill_choice','ov_zhengdi',sgs.ai_skill_choice['ov_zhengdi'],{},{})
sgs.ai_fill_skill["ov_fushu"] = function(self,inclusive,request)
	local ms = self:getMaxCard()
	if ms and self:aiUseCard(clone(self,"peach")) then
		return policy(self,"#ov_fushuCard:"..ms:getLegacyStringKey()..":")
	end
end


remember_function('ai_fill_skill','ov_fushu',sgs.ai_fill_skill['ov_fushu'],{},{})
sgs.ai_skill_use_func["#ov_fushuCard"] = function(card,use,self)
	use.card = card
end


remember_function('ai_skill_use_func','#ov_fushuCard',sgs.ai_skill_use_func['#ov_fushuCard'],{},{})
sgs.ai_use_value.ov_fushuCard = 3.4
sgs.ai_use_priority.ov_fushuCard = -1.8

function sgs.ai_guhuo_card.ov_fushu(self,toname,class_name)
	local ms = self:getMaxCard()
	if ms and class_name=="Peach" then
		return "#ov_fushuCard:"..ms:getLegacyStringKey()..":"
	end
end


remember_function('ai_guhuo_card','ov_fushu',sgs.ai_guhuo_card['ov_fushu'],{},{})
sgs.ai_skill_playerchosen.ov_xiumu = function(self,players,x,n)
	players = self:sort(players)
	for _,p in sgs.list(players)do
		if self:isFriend(p) and q(p,"getHandcardNum")<=q(self.player,"getHandcardNum") and self:isWeak(p) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isEnemy(p) and q(p,"getHandcardNum")>=q(self.player,"getHandcardNum") then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if not self:isFriend(p) and q(p,"getHandcardNum")>q(self.player,"getHandcardNum") then
			return p
		end
	end
end


remember_function('ai_skill_playerchosen','ov_xiumu',sgs.ai_skill_playerchosen['ov_xiumu'],{},{})
sgs.ai_skill_use["@@ov_xiumu!"] = function(self,prompt)
	local n = 0
	local valid = {}
	local cs = self.player:getCards("h")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
    	table.insert(valid,c:getLegacyStringKey())
		n = n+q(c,"getNumber")
		if n>12 then break end
	end
	return "#ov_xiumuCard:"..table.concat(valid,"+")..":"
end


remember_function('ai_skill_use','@@ov_xiumu!',sgs.ai_skill_use['@@ov_xiumu!'],{},{})
sgs.ai_skill_playerschosen.ov_huiyu = function(self,players,x,n)
	players = self:sort(players,nil,true)
	local tps = {}
	for _,p in sgs.list(players)do
		if #tps<1 and self:isEnemy(p) then
			table.insert(tps,p)
		end
	end
	for _,p in sgs.list(players)do
		if #tps<1 and not self:isFriend(p) then
			table.insert(tps,p)
		end
	end
	for _,p in sgs.list(players)do
		if #tps==1 and not self:isEnemy(p) then
			table.insert(tps,p)
		end
	end
	for _,p in sgs.list(players)do
		if #tps==1 and not table.contains(tps,p) then
			table.insert(tps,p)
		end
	end
	return tps
end


remember_function('ai_skill_playerschosen','ov_huiyu',sgs.ai_skill_playerschosen['ov_huiyu'],{},{})
sgs.ai_skill_invoke.ov_beixing = function(self,data)
	local to = data:toPlayer()
	return self:isEnemy(to)
end


remember_function('ai_skill_invoke','ov_beixing',sgs.ai_skill_invoke['ov_beixing'],{},{})
sgs.ai_skill_playerchosen.ov_beixing = function(self,players,x,n)
	players = self:sort(players)
	for _,p in sgs.list(players)do
		if self:isFriend(p) then
			return p
		end
	end
end


remember_function('ai_skill_playerchosen','ov_beixing',sgs.ai_skill_playerchosen['ov_beixing'],{},{})
sgs.ai_skill_invoke.ov_qinyi = function(self,data)
	for _,cn in sgs.list(card_names(self))do
		if q(self.player,"getMark","ov_qinyiBan"..cn)>0 then continue end
		local dc = clone(self,cn,"ov_qinyi")
		if q(dc,"isAvailable",self.player) and self:aiUseCard(dc).card then
			return true
		end
	end
end


remember_function('ai_skill_invoke','ov_qinyi',sgs.ai_skill_invoke['ov_qinyi'],{},{})
sgs.ai_skill_choice.ov_qinyi = function(self,choices,data)
	local items = choices:split("+")
	local cs = {}
	for _,cn in sgs.list(items)do
		local dc = clone(self,cn,"ov_qinyi")
		if q(dc,"isAvailable",self.player) then
			table.insert(cs,dc)
		end
	end
	cs = self:sortByUseValue(cs)
	for _,c in sgs.list(cs)do
		local d = self:aiUseCard(c)
		if d.card then
			if q(c,"canRecast") and d.to:length()<1 then continue end
			self.ov_qinyiUse = d
			return c:objectName()
		end
	end
end


remember_function('ai_skill_choice','ov_qinyi',sgs.ai_skill_choice['ov_qinyi'],{'ov_qinyiUse'},{'ov_qinyiUse'})
sgs.ai_skill_use["@@ov_qinyi"] = function(self,prompt)
	local d = self.ov_qinyiUse
	if d.card then
		local tos = {}
		for _,p in sgs.list(d.to)do
			table.insert(tos,p:objectName())
		end
		return d.card.."->"..table.concat(tos,"+")
	end
end


remember_function('ai_skill_use','@@ov_qinyi',sgs.ai_skill_use['@@ov_qinyi'],{'ov_qinyiUse'},{})
sgs.ai_skill_invoke.ov_jixin = function(self,data)
	return self:canDraw()
end

-----------------------------------
-- 武将自身的选将策略
-----------------------------------

-- 侠鲁肃：内奸不推荐

remember_function('ai_skill_invoke','ov_jixin',sgs.ai_skill_invoke['ov_jixin'],{},{})
sgs.ai_general_choice["ov_lusu"] = function(ai, lord, role)
	if role == "renegade" then
		return -1
	end
	return 0
end

-- 赵娥：小人数局不推荐；忠臣推荐；内奸不推荐

remember_function('ai_general_choice','ov_lusu',sgs.ai_general_choice['ov_lusu'],{},{})
sgs.ai_general_choice["ov_zhaoe"] = function(ai, lord, role)
	local player_count = ai.room:getAlivePlayers():length()
	if player_count <= 3 then
		return -1
	end

	if role == "loyalist" then
		return 1
	end

	if role == "renegade" then
		return -1
	end

	return 0
end









remember_function('ai_general_choice','ov_zhaoe',sgs.ai_general_choice['ov_zhaoe'],{},{})

for _,row in ipairs(authored)do
 local registry=row.reg=='SmartAIView'and SmartAIView or sgs[row.reg]
 -- A later literal writer wins. Never wrap another package's alias by prefix.
 if registry[row.key]==row.fn then
  local f,key,kind,read,write=row.fn,row.key,row.reg,row.read,row.write
  registry[key]=function(...)
   local a=table.pack(...);local self
   for i=1,a.n do if type(a[i])=='table'and a[i].player and a[i].world and a[i].request then self=a[i];break end end
   if not self then return f(...)end
   load_state(self,read)
   if kind=='ai_skill_invoke'then a[2]=scoped_data(self,key,a[2])end
   if key=='ov_zhilve_from'or key=='ov_zhilve_to'or key=='ov_zhilve'and kind=='ai_skill_cardchosen'then peiqi_state(self)end
   local previous,request=self._overseas_key,self._overseas_request;self._overseas_key=key;if kind=='ai_fill_skill'then self._overseas_request=a[3]end
   local out=table.pack(pcall(f,table.unpack(a,1,a.n)))
   self._overseas_key=previous;self._overseas_request=request;save_state(self,write)
   if not out[1]then error(out[2],0)end
   if kind=='ai_skill_use'then out[2]=response(self,out[2])
   elseif kind=='ai_guhuo_card'or kind=='ai_cardsview'then out[2]=proposal(out[2])
   elseif kind=='ai_fill_skill'then out[2]=promote_fill(self,key,out[2],a[3])end
   return table.unpack(out,2,out.n)
  end
 end
end
for _,name in ipairs{'Mantianguohai','Binglinchengxia','Tiaojiyanmei'}do
 ai_card_use[name]=function(self,card,use)return self['useCard'..name](self,card,use)end
end

sgs.ai_skill_playerchosen['ov_yingjia']=function(self,...) return dynamic_read(self,'ai_skill_playerchosen','ov_yingjia')end
sgs.ai_skill_invoke['ov_beini']=function(self,...) return dynamic_read(self,'ai_skill_invoke','ov_beini')end
sgs.ai_skill_choice['shifa']=function(self,...) return dynamic_read(self,'ai_skill_choice','shifa')end
sgs.ai_skill_choice['ov_xiafeng']=function(self,...) return dynamic_read(self,'ai_skill_choice','ov_xiafeng')end
sgs.ai_skill_askforag['ov_niju']=function(self,...) return dynamic_read(self,'ai_skill_askforag','ov_niju')end
sgs.ai_skill_choice['wangxing']=function(self,...) return dynamic_read(self,'ai_skill_choice','wangxing')end
sgs.ai_skill_choice['ov_zenhui']=function(self,...) return dynamic_read(self,'ai_skill_choice','ov_zenhui')end
sgs.ai_skill_choice['ov_yizhu']=function(self,...) return dynamic_read(self,'ai_skill_choice','ov_yizhu')end
sgs.ai_skill_invoke['ov_yanshiYL']=function(self,...) return dynamic_read(self,'ai_skill_invoke','ov_yanshiYL')end
