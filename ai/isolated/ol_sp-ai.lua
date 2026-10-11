-- ol_sp fixed b6025acc. Owner/public policy and ordered source hypotheses.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported('ol_sp input unknown',k)end;return v end
local nullable={setGuowuDecisionContext=true,getCardNeedPlayer=true,getMinCard=true,getTreasure=true,toCardUse=true,toCardResponse=true,findPlayerByObjectName=true,updateIntention=true,getMaxCard=true,getCurrent=true,getArmor=true,getWeapon=true,getEquip=true,toPlayer=true,toJudge=true,getStrategyMemory=true,setStrategyMemory=true,useBasicCard=true,useTrickCard=true}
local function call(o,k,...)
 if k=='hasFlag'and AIValue.isPlayer(o)then
  local ai=o._room and o._room._ai;local fs=ai and ai.world.strategy_facts
  local rows=fs and fs.ol_sp and fs.ol_sp.public_flags
  local values=rows and rows[(...)];local v=values and values[o:objectName()]
  local audited={['xiongmang_target']=true,['olqingshiTo']=true}
  if audited[(...)]then if type(v)~='boolean'then ai_unsupported('public flag disclosure missing',(...))end;return v end
 end
 if not o or type(o[k])~='function'then ai_unsupported('ol_sp helper unavailable',k)end
 local m=k;if k=='getMark'and AIValue.isPlayer(o)then m='getStrategyMark'end
 local r=table.pack(o[m](o,...));if AIUnsupported.is(r[1])then error(r[1],0)end
 if k=='sort'or k=='sortByKeepValue'or k=='sortByUseValue'then local t=(...);known(r[1],k);for i,v in ipairs(r[1])do t[i]=v end;return t end
 if k=='hasSkill'or k=='hasSkills'then local p=AIValue.isPlayer(o)and o or select(2,...)or o.player;local row=type(p)=='table'and rawget(p,'_view');if r[1]==false and row and row.skills_complete~=true then ai_unsupported('ol_sp foreign skill absence unknown',(...))end end
 if not nullable[k]then known(r[1],k)end;return table.unpack(r,1,r.n)
end
local function facts(self)return known(self.world.strategy_facts.ol_sp,'ol_sp.facts')end
local function context(self)return known(call(self,'getDecisionContext').ol_sp,'ol_sp.context')end
local function face(self,id)return call(self,'getKnownCardById',tonumber(id)or id)end
local function evaluation(self,name)return call(self,'getEvaluationCard',name or 'slash')end
local function named(self,skill,name,costs,recast)
 local c=call(self,'evaluateSkillCard',skill,name or'slash',costs or{})
 if recast==false and call(c,'canRecast')~=false then ai_unsupported('source readonly canRecast=false was not projected',skill)end
 return c
end
local function flagged_choulie(self)
 local c=named(self,'choulie','slash',{})
 if call(c,'getSkillName',false)~=''or call(c,'hasFlag','Qinggang')~=true then ai_unsupported('source empty-skill Qinggang dummy requires exact clone','choulie')end
 return c
end
local function memory(self,key,value,write)
 if write then if value==nil then value=false end;call(self,'setStrategyMemory','ol_sp.'..key,value);return end
 local value,present=call(self,'getStrategyMemory','ol_sp.'..key);if present then return value~=false and value or nil end
end
local function save_targets(self,key,ts)if ts==nil then memory(self,key,false,true);return end;local ns={};for _,p in ipairs(ts)do ns[#ns+1]=call(p,'objectName')end;memory(self,key,ns,true)end
local function targets(self,key)local ns=memory(self,key);if not ns then return nil end;local ps=AIList.new({});for _,n in ipairs(ns)do ps:append(known(self.room:findPlayerByObjectName(n),n))end;return ps end
local function save_player(self,key,p)memory(self,key,p and call(p,'objectName'),true)end
local function saved_player(self,key)local name=memory(self,key);return name and known(self.room:findPlayerByObjectName(name),key)end
local function descriptor(c)local ids={};for _,id in ipairs(call(c,'getSubcards'))do ids[#ids+1]=id end;return{name=call(c,'objectName'),skill=call(c,'getSkillName',false),suit=call(c,'getSuit'),number=call(c,'getNumber'),subcards=ids}end
local function save_plan(self,key,d)
 local row={targets=false,card=false};if d.card then row.card=descriptor(d.card)end
 if d.to then row.targets={};for _,p in ipairs(d.to)do row.targets[#row.targets+1]=call(p,'objectName')end end;memory(self,key,row,true)
end
local function load_plan(self,key)
 local row=memory(self,key);if not row then return nil end;local d={}
 if row.card then local r=row.card;local c=named(self,r.skill,r.name,r.subcards);local got=descriptor(c)
  if got.suit~=r.suit or got.number~=r.number or got.skill~=r.skill or #got.subcards~=#r.subcards then ai_unsupported('saved source hypothesis changed',key)end
  for i,id in ipairs(r.subcards)do if got.subcards[i]~=id then ai_unsupported('saved source costs reordered',key)end end;d.card=c end
 if row.targets then d.to=AIList.new({});for _,n in ipairs(row.targets)do d.to:append(known(self.room:findPlayerByObjectName(n),n))end end;return d
end
local providers={["olYicheng2Card"]="olyicheng",["#juemouCard"]="juemou",["#olmoubaojingCard"]="olmoubaojing",["#olshoushuCard"]="olshoushu",["#olspxixiangCard"]="olspxixiang",["#olspzhubeiCard"]="olspzhubei",["BaoshuCard"]="baoshu",["BojueCard"]="bojue",["BoyanCard"]="boyan",["ChanniCard"]="channi",["ChanshuangCard"]="chanshuang",["ChenjianCard"]="chenjian",["DiciCard"]="dici",["DinglunCard"]="dinglun",["DunshiCard"]="dunshi",["FengshangCard"]="fengshang",["FushiCard"]="fushi",["GangqianCard"]="gangqian",["GuowuCard"]="guowu",["HeqiaCard"]="heqia",["HongtuCard"]="hongtu",["HuanhuoCard"]="huanhuo",["HuanpeiCard"]="huanpei",["HunjiangCard"]="hunjiang",["JianliangCard"]="jianliang",["JiewanCard"]="jiewan",["JiguCard"]="jigu",["JinChongxinCard"]="jinchongxin",["JinhuiCard"]="jinhui",["JinhuiUseCard"]="jinhui",["JinlanCard"]="jinlan",["JiqiaosyCard"]="jiqiaosy",["KouchaoCard"]="kouchao",["KuanmoCard"]="kuanmo",["LieyiCard"]="lieyi",["LucunCard"]="lucun",["LunzhanCard"]="lunzhan",["ManwangCard"]="manwang",["MengshiCard"]="mengshi",["MiluoCard"]="miluo",["OL2ShanjiaCard"]="ol2shanjia",["OLJinjinCard"]="oljinjin",["OLJueyanCard"]="oljueyan",["OLLiyongCard"]="olliyong",["OLQingshiCard"]="olqingshi",["PingduanCard"]="pingduan",["QiangangCard"]="qiangang",["QiaozhiCard"]="qiaozhi",["QushiCard"]="qushi",["RenxianCard"]="renxian",["ShengongCard"]="shengong",["ShuziCard"]="shuzi",["SibingCard"]="sibing",["SiqiCard"]="siqi",["SuyiCard"]="suyi",["WeifuCard"]="weifu",["WeijieCard"]="weijie",["WeimengCard"]="weimeng",["WeimianCard"]="weimian",["WenrenCard"]="wenren",["XianyingCard"]="xianying",["XieweiCard"]="xiewei",["XiongmangCard"]="xiongmang",["Xuanzhu2Card"]="xuanzhu",["XuanzhuCard"]="xuanzhu",["XunliCard"]="xunli",["XunliPutCard"]="xunli",["YanliangCard"]="yanliangvs",["YijiaoCard"]="yijiao",["YinglveCard"]="yinglve",["YouqueCard"]="youque",["YuanyuCard"]="yuanyu",["YuqiCard"]="yuqi",["ZaowangCard"]="zaowang",["ZhijueCard"]="zhijue",["ZhishiCard"]="zhishi",["ZonghuCard"]="zonghu",["ZuolianCard"]="zuolian",["olYichengCard"]="olyicheng"}
local function decode(wire)
 local cls,raw,user
 if wire:sub(1,1)=='#'then cls,raw,user=wire:match('^(#[%w_]+):([^:]*):(.*)$')else cls,raw=wire:match('^@([%w_]+)=(.*)$')end
 if not cls or not providers[cls]then ai_unsupported('source selector lacks finite native adapter',wire)end
 local names={};local tail=user or raw;local i=tail:find('->',1,true)
 if i then for n in tail:sub(i+2):gmatch('[^+]+')do names[#names+1]=n end;tail=tail:sub(1,i-1)end
 if cls:sub(1,1)=='#'then user=tail else raw,user=tail:match('^([^:]*):(.*)$');raw=raw or tail end
 local ids={};if raw~='.'and raw~=''then for v in raw:gmatch('[^+]+')do local id=tonumber(v);if not id or id<0 or id%1~=0 then ai_unsupported('source cost literal is malformed',wire)end;ids[#ids+1]=id end end
 return cls,ids,user,names
end
local function parse(self,wire)
 if wire:sub(1,1)~='@'and wire:sub(1,1)~='#'then return call(self,'evaluateSourcePropertyCard','ol_sp',wire)end
 local cls,ids,user=decode(wire);if #ids==0 and not user then return call(self,'legacySkillSeed',providers[cls],cls,self.request)end
 return call(self,'evaluateTurnSkillCard',providers[cls],cls,ids,self.request,user)
end
local function proposal(self,wire)local cls,ids,user=decode(wire);return{skill=providers[cls],legacy_class=cls,subcards=ids,user_string=user}end
local function response(self,wire)local cls,ids,user,names=decode(wire);local c=call(self,'bindSkillCard',providers[cls],ids,self.request,user,cls);return{kind='use_card',card_spec=call(c,'toCardSpec'),targets=names}end
local function answer(self,c,names)
 if call(c,'isEvaluationOnly')then local skill=call(c,'getSkillName',false);local ids=call(c,'getSubcards');local receipt=call(self,'bindSkillCard',(skill:gsub('^_','')),ids,self.request,call(c,'objectName'))
  for _,k in ipairs{'objectName','getSuit','getNumber'}do if call(receipt,k)~=call(c,k)then ai_unsupported('source selected receipt changes product',k)end end
  if call(receipt,'getSkillName',false)~=skill then ai_unsupported('source selected receipt changes raw skill',skill)end
  local got=call(receipt,'getSubcards');if #got~=#ids then ai_unsupported('source receipt changes material count',skill)end;for i,id in ipairs(ids)do if got[i]~=id then ai_unsupported('source receipt reorders costs',skill)end end;c=receipt end
 if AIValue.isConversion(c)then return{kind='use_card',card_spec=call(c,'toCardSpec'),targets=names or{}}end
 if call(c,'isVirtualCard')then ai_unsupported('source selected hypothesis lacks receipt','ol_sp.answer')end
 return{kind='use_card',card_ids={call(c,'getEffectiveId')},targets=names or{}}
end
-- Guowu's source writes a synthetic CardUse solely for the immediately nested
-- complete Yingbian policy. Override the pure context for that call and always
-- restore it, including ordinary errors and typed unknowns. Nothing is persisted.
local function nested(self,reg,key,...)
 local f=call(self,'getHooks',reg)[key];if type(f)~='function'then ai_unsupported('required source callback absent',reg..'.'..key)end
 local args=table.pack(...);local saved=rawget(self,'getDecisionContext')
 local use=self._ol_sp_guowu_use
 if key=='yb_zhuzhan2'and reg=='ai_skill_playerchosen'and use then
  if use.request~=self.request then ai_unsupported('Guowu temporary input belongs to another question','guowu')end
  local base=call(self,'getDecisionContext');local scoped={};for k,v in pairs(base)do scoped[k]=v end
  local yingbian={};for k,v in pairs(base.yingbian or{})do yingbian[k]=v end;scoped.yingbian=yingbian
  yingbian.use=use.row;self.getDecisionContext=function()return scoped end
 end
 local result=table.pack(pcall(f,table.unpack(args,1,args.n)))
 self.getDecisionContext=saved
 if key=='yb_zhuzhan2'then self._ol_sp_guowu_use=nil end
 if not result[1]then error(result[2],0)end
 if AIUnsupported.is(result[2])then error(result[2],0)end;return table.unpack(result,2,result.n)
end
local function save_choice(self,key,v)memory(self,'choice.'..key,v,true);sgs.ai_skill_choice[key]=function(ai)return known(memory(ai,'choice.'..key),key)end end
local function source_choice_continuity(self,op,key,row)
 if type(ai_response_choice_continuity)~='function'then ai_unsupported('native source choice continuity unavailable',key)end
 local result=ai_response_choice_continuity({op=op,key=key,row=row})
 if AIUnsupported.is(result)then error(result,0)end
 if type(result)~='table'or result.known~=true then
  if op=='record'then return end -- observation unavailable; never erase reached own source write
  ai_unsupported('source global choice continuation is unobserved',key)
 end
 if op=='record'then if result.recorded~=true then ai_unsupported('invalid source choice record',key)end;return end
 if type(result.present)~='boolean'or(result.present and type(result.value)~='string')then ai_unsupported('invalid source choice value',key)end
 return result.present and result.value or nil
end
local function capture_choice(self,key,from)
 if key=='olxuhe'and from=='xuhe'then
  if not ai_response_scalar_choices then ai_unsupported('Xuhe scalar lifecycle helper missing',key)end
  ai_response_scalar_choices.copy(self,key,from)
  return
 end
 local v=call(self,'getHooks','ai_skill_choice')[from]
 if type(v)=='string'then save_choice(self,key,v)else ai_unsupported('source dynamic callback closure needs immutable capture',key..'->'..from)end
end
local function cards_from_ids(self,ids)local cs=AIList.new({});for _,id in ipairs(ids)do cs:append(face(self,id))end;return cs end
local function hydrate(self,v,kind)
 if v==nil then return nil end
 if kind=='Player'then if AIValue.isPlayer(v)then return v end;return known(self.room:findPlayerByObjectName(v),v)end
 if kind=='Card'then if AIValue.isCard(v)or AIValue.isConversion(v)then return v end;return CardView.new(v)end
 if kind=='IntList'then return AIList.new(v)end
 if kind=='CardUse'or kind=='CardResponse'or kind=='Damage'then
  local r={};for k,x in pairs(v)do r[k]=x end
  for _,k in ipairs{'from','who','m_who'}do if v[k]then r[k]=hydrate(self,v[k],'Player')end end
  if kind=='Damage'then if v.to then r.to=hydrate(self,v.to,'Player')end
  elseif kind=='CardUse'then r.to=AIList.new({});for _,n in ipairs(v.to or{})do r.to:append(hydrate(self,n,'Player'))end end
  for _,k in ipairs{'card','whocard','m_card','m_toCard'}do if v[k]then r[k]=hydrate(self,v[k],'Card')end end
  return r
 end
 return v
end
local function tag(self,key,kind,owner)
 if kind=='IntList'and key:sub(-5)=='ForAI'then return call(self.player,'getNotifiedTag',key)end
 local rows=context(self).tags;local row=rows and rows[key]
 if type(row)~='table'or row.known~=true or row.kind~=kind or row.owner~=owner then ai_unsupported('source current tag not lawfully projected',key)end
 if row.present==false and (kind=='Player'or kind=='Card')then return nil end
 if kind=='Player'then return known(self.room:findPlayerByObjectName(row.value),key)end
 if kind=='IntList'then return AIList.new(known(row.value,key))end
 return hydrate(self,known(row.value,key),kind)
end
local function property(self,p,key)
 local rows=facts(self).properties;local row=rows and rows[call(p,'objectName')];return known(row and row[key],key)
end
local function cardnames(self,class)
 local keys={BasicCard='ol_sp_basic_names',['TrickCard+^DelayedTrick']='ol_sp_ndtrick_names'}
 if type(ai_response_catalogue)~='function'then ai_unsupported('source public catalog query unavailable',class)end
 local row=ai_response_catalogue(known(keys[class],class));if AIUnsupported.is(row)then error(row,0)end
 if type(row)~='table'or row.known~=true or row.key~=keys[class]then ai_unsupported('source public catalog query rejected',class)end
 return known(row.names,class)
end
local function matches(self,pattern,p,c)
 if p~=self.player then ai_unsupported('source matcher receiver not owner','ol_sp.matcher')end
 return call(self,'matchesDiscardPattern',pattern,c)
end
local function persistent_effect(self)
 local c=self.world.decision_context or{};if c.effect_present==false then return nil end
 if c.effect_present~=true or type(c.effect)~='table'then ai_unsupported('persistent source CardEffect is unknown','ol_sp.xiwu')end
 local raw=c.effect;local card=raw.card;if type(card)~='table'then ai_unsupported('persistent source CardEffect has no public card','ol_sp.xiwu')end
 local out={card=AIValue.isCard(card)and card or CardView.new(card)}
 for _,key in ipairs{'from','to'}do local p=raw[key];if type(p)=='string'then p=known(self.room:findPlayerByObjectName(p),key)end;out[key]=p end
 return out
end
local function historical_use(self,c)
 local ctx=context(self)
 if ctx.fuchao then
  if ctx.fuchao.known~=true then ai_unsupported('Fuchao actual question reference is unknown','fuchao.public_use')end
  return hydrate(self,known(ctx.fuchao.use,'fuchao.public_use'),'CardUse')
 end
 local rows=ctx.public_use_history;local row=rows and rows[call(c,'getLegacyStringKey')]
 return hydrate(self,known(row,'fuchao.public_use'),'CardUse')
end
local function fuchao_data(self,data)
 local ctx=call(self,'getDecisionContext').ol_sp;local row=ctx and ctx.fuchao
 if not row then return data end
 if row.known~=true or(row.mode~='use'and row.mode~='response')then ai_unsupported('Fuchao question input not projected','fuchao')end
 local use=row.mode=='use'and hydrate(self,row.input,'CardUse')or nil
 local response=row.mode=='response'and hydrate(self,row.input,'CardResponse')or nil
 return{toCardUse=function()return use end,toCardResponse=function()return response end}
end
local function set_guowu_context(self,use)
 if not self.request or not(AIValue.isCard(use.card)or AIValue.isConversion(use.card))then ai_unsupported('Guowu source hypothesis not a current pure card','guowu')end
 local raw=rawget(use.card,'_view');if type(raw)~='table'then ai_unsupported('Guowu source card descriptor missing','guowu')end
 local card={};for k,v in pairs(raw)do card[k]=v end
 if use.card._evaluation_candidate then card.evaluation_candidate=use.card._evaluation_candidate end
 local row={from=call(use.from,'objectName'),card=card,to={}}
 for _,p in ipairs(use.to)do row.to[#row.to+1]=call(p,'objectName')end
 self._ol_sp_guowu_use={request=self.request,row=row}
end
local function guowu_flag(self,p)
 local flags=context(self).guowu_canchoose
 return known(flags and flags[call(p,'objectName')],'guowu_canchoose')
end
local function judge_reason(self,key)
 local patterns,present=call(self,'getEventMemory','judge_patterns')
 if not present or type(patterns)~='table'then ai_unsupported('source judge history is not observed','tianhou0.judge_patterns')end
 if patterns[key]~=nil then return patterns[key]end
 -- Fixed initial registry differs when the original-hegemony loader ran.
 -- StartJudge overrides above remain authoritative in either source variant.
 local mode=self.world and self.world.strategy_facts and self.world.strategy_facts.hegemony
 if type(mode)~='table'or type(mode.enabled)~='boolean' then ai_unsupported('source judge registry mode is not projected','tianhou0.judge_patterns')end
 local defaults={indulgence='.|heart',supply_shortage='.|club',lightning={'.|spade|2~9',false}}
 if mode.enabled then
  if type(mode.original_overrides_loaded)~='boolean'then ai_unsupported('source judge registry loader is not projected','tianhou0.judge_patterns')end
  if mode.original_overrides_loaded then defaults={indulgence='heart',diamond='heart',supply_shortage='club',spade='club',club='club',lightning='spade'}end
 end
 return defaults[key]
end
local function source_global_jc(self)return face(self,known(facts(self).global_jc_id,'tianhou0.source_global_jc'))end
local function RandomList(items)local copy={};for _,v in ipairs(items)do copy[#copy+1]=v end;while #copy>0 do local v=copy[math.random(1,#copy)];table.removeOne(copy,v);table.removeOne(items,v);items[#items+1]=v end;return items end

local function material_proposal(c,name,skill)return{name=name,skill=skill,suit=call(c,'getSuit'),number=call(c,'getNumber'),subcards={call(c,'getEffectiveId')}}end
local function can_to(self,card,from,to,tos)if from~=self.player then ai_unsupported('source targetFilter requires owner evaluation','guowu')end;return call(self,'cardTargetFilter',card,tos or{},to)end

local select_fengshang


sgs.ai_skill_discard.zhouxuanz = function(self,x,n)
	local cards = {}
    local handcards = call(self.player,"getCards","h")
    handcards = call(self,"sortByKeepValue",handcards,true) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if #handcards-#cards<call(self.player,"getMaxCards")/2 or #cards>=x then break end
		table.insert(cards,call(h,"getEffectiveId"))
	end
	return cards
end

sgs.ai_skill_invoke.xianlve = function(self,data)
    return true
end

sgs.ai_skill_askforag.xianlve = function(self,card_ids)
	for _,id in sgs.list(card_ids)do
		local c = face(self,id)
		if call(self,"getUseValue",c)>4
		then return id end
	end
end

sgs.ai_fill_skill.zaowang = function(self)
	return parse(self,"@ZaowangCard=.")
end

sgs.ai_skill_use_func["ZaowangCard"] = function(card,use,self)
	call(self,"sort",self.friends,"hp",true)
	for _,ep in sgs.list(self.friends)do
		if call(ep,"getHp")>=call(self.player,"getHp")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.ZaowangCard = 9.4
sgs.ai_use_priority.ZaowangCard = 4.8

sgs.ai_skill_invoke.guowu = function(self,data)
    return true
end

sgs.ai_skill_use["@@guowu2"] = function(self,prompt)
	local valid = {}
	local pr = prompt:split(":")
	local n = pr[4]-0
	local destlist = call(self.room,"getAllPlayers")
    destlist = call(self,"sort",destlist,"hp")
	for i=1,n do
		local use = {to=AIList.new({})}
		use.from = self.player
		use.card = evaluation(self,pr[2])
		local tos = sgs.SPlayerList()
		for _,ep in sgs.list(destlist)do
			if guowu_flag(self,ep)
			then tos:append(ep)
			elseif can_to(self,use.card,self.player,ep,use.to)
			then use.to:append(ep) end
		end
		set_guowu_context(self,use)
		tos = nested(self,"ai_skill_playerchosen","yb_zhuzhan2",self,tos)
		if tos
		then
			table.insert(valid,tos:objectName())
			table.removeOne(destlist,tos)
		end
	end
	if #valid>0
	then
    	return response(self,string.format("@GuowuCard=.->%s",table.concat(valid,"+")))
	end
end

sgs.ai_skill_invoke.yuqi = function(self,data)
	local target = call(data,"toPlayer")
	if target then
		save_player(self,"yuqi_to",target)
	end
	return true
end

sgs.ai_skill_use["@@yuqi1"] = function(self,prompt)
	if not call(self,"isFriend",saved_player(self,"yuqi_to"))
	then return end
	local yuqi_help = tag(self,"yuqiForAI","IntList","owner")
	local n1,n2 = {},{}
	for c,id in sgs.list(yuqi_help)do
		table.insert(n1,face(self,id))
	end
	local n = call(self.player,"getMark","yuqi_help")
	call(self,"sortByKeepValue",n1,true)
	local poisons = call(self,"poisonCards",n1)
	for _,c in sgs.list(n1)do
		if #n2>=n then break end
		if table.contains(poisons,c) then continue end
		table.insert(n2,call(c,"getEffectiveId"))
	end
	return #n2>0 and response(self,"@YuqiCard="..table.concat(n2,"+"))
end

sgs.ai_skill_use["@@yuqi2"] = function(self,prompt)
	local valid = {}
	local yuqi_help = tag(self,"yuqiForAI","IntList","owner")
	local n1,n2 = {},{}
	for _,id in sgs.list(yuqi_help)do
		table.insert(n1,face(self,id))
	end
	local n = call(self.player,"getMark","yuqi_help")
	call(self,"sortByKeepValue",n1,true)
	local poisons = call(self,"poisonCards",n1)
	for _,c in sgs.list(n1)do
		if #n2>=n then break end
		if table.contains(poisons,c) then continue end
		table.insert(n2,call(c,"getEffectiveId"))
	end
	return #n2>0 and response(self,"@YuqiCard="..table.concat(n2,"+"))
end

sgs.ai_skill_invoke.shanshen = function(self,data)
    return true
end

sgs.ai_skill_invoke.xianjing = function(self,data)
    return true
end

sgs.ai_can_damagehp.yuqi = function(self,from,card,to)
	if (not card or call(card,"isDamageCard")) and not call(self,"isWeak",to)
	and call(to,"getMark","yuqi-Clear")<2
	and not call(self,"isFriend",from)
	and call(self,"canLoseHp",from,card)
	then return true end
end

sgs.ai_nullification.yuqi = function(self,trick,from,to,positive)
    if call(to,"hasSkill","yuqi")
	and call(self,"isFriend",to)
	and not call(self,"isWeak",to)
	and trick:isDamageCard()
	and call(to,"getMark","yuqi-Clear")<2
   	and call(self,"canLoseHp",from,trick,to)
	then return false end
end

sgs.ai_skill_invoke.huguan = function(self,data)
	local target = call(data,"toPlayer")
	if target then
		return call(self,"isFriend",target)
	end
end

sgs.ai_skill_cardask["@yaopei-discard"] = function(self,data,pattern,prompt)
    local parsed = call(data,"toPlayer")
    if call(self,"isFriend",parsed)
	then return true end
	return "."
end

sgs.ai_skill_choice.yaopei = function(self,choices,data)
	local items = choices:split("+")
	local target = call(data,"toPlayer")
	if call(self,"isWeak") then return items[1] end
	if call(self,"isWeak",target) then return items[2] end
	if call(self.player,"isWounded") then return items[1] end
	if call(target,"isWounded") then return items[2] end
	if call(target,"getHandcardNum")>=call(target,"getHandcardNum")
	then return items[2] else return items[1] end
end

sgs.ai_skill_use["@@heqia1"] = function(self,prompt)
	local valid,to = {},nil
	if #self.friends_noself<1 then return end
	call(self,"sort",self.friends_noself,"card",true)
    for _,p in sgs.list(self.friends_noself)do
      	if call(p,"getHandcardNum")>4
	then return call(self,"materializeHeqiaFirst",string.format("@HeqiaCard=.->%s",call(p,"objectName"))) end
	end
    local cards = call(self.player,"getCards","he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if #valid>=#cards/2 then break end
    	table.insert(valid,call(h,"getEffectiveId"))
	end
	to = self.friends_noself[#self.friends_noself]
	if #valid<1 then return end
	return call(self,"materializeHeqiaFirst",string.format("@HeqiaCard=%s->%s",table.concat(valid,"+"),call(to,"objectName")))
end

sgs.ai_skill_discard.heqia = function(self,x,n)
	local to_cards = {}
	local cards = call(self.player,"getCards","h")
	cards = call(self,"sortByUseValue",cards,true)
	if call(self,"isFriend",call(self.room,"getCurrent"))
	then
		for _,c in sgs.list(cards)do
			if #to_cards>=#cards/2 then break end
			table.insert(to_cards,call(c,"getEffectiveId"))
		end
	end
	for _,c in sgs.list(cards)do
		if #to_cards>=n then break end
		table.insert(to_cards,call(c,"getEffectiveId"))
	end
	return to_cards
end

sgs.ai_skill_askforag.heqia = function(self,card_ids)
	local cards = call(self.player,"getCards","h")
	if cards:length()<1 then return end
	for _,id in sgs.list(card_ids)do
		local c = call(self,"getChoiceCard",id)
		c = call(self,"evaluateHeqiaCard",id,cards:at(0):getEffectiveId(),call(c,"objectName"))
		local d = call(self,"aiUseCard",c)
		call(self,"rememberHeqiaUse",d,id)
		if d.card and d.to
		then return id end
	end
end

sgs.ai_skill_use["@@heqia2"] = function(self,prompt)
    local dummy = call(self,"loadHeqiaUse")
   	if dummy.card and dummy.to then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,call(p,"objectName"))
       	end
		if call(dummy.card,"isKindOf","Peach") then
			for _,p in sgs.list(self.friends_noself)do
				if call(self.player,"isProhibited",p,dummy.card)
				or not call(p,"isWounded")
				or #tos>=call(self.player,"getMark","heqia_get_card")
				then continue end
				table.insert(tos,call(p,"objectName"))
			end
		end
	return call(self,"materializeHeqiaUse",tos)
    end
end

sgs.ai_skill_invoke.lanjiang = function(self,data)
    return true
end

sgs.ai_skill_invoke.lanjiang_draw = function(self,data)
   	local target = call(self.room,"getCurrent")
	return call(self,"isFriend",target)
end

sgs.ai_skill_playerchosen.lanjiang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"hp")
    for _,target in sgs.list(destlist)do
		if call(self,"isEnemy",target)
		and call(target,"getHandcardNum")>=call(self.player,"getHandcardNum")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not call(self,"isFriend",target)
		and call(target,"getHandcardNum")>=call(self.player,"getHandcardNum")
		then return target end
	end
	call(self,"sort",destlist,"hp")
	for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		and call(target,"getHandcardNum")<call(self.player,"getHandcardNum")
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not call(self,"isEnemy",target)
		and call(target,"getHandcardNum")<call(self.player,"getHandcardNum")
		then return target end
	end

end

sgs.ai_skill_cardask["@mingluan-discard"] = function(self,data,pattern,prompt)
    local target = call(self.room,"getCurrent")
    if call(self.player,"getHandcardNum")<call(target,"getHandcardNum")
	and call(self.player,"getHandcardNum")<5
	then return true end
	return "."
end

sgs.ai_skill_playerchosen.bingqing = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	local n = call(self.player,"getMark","bingqing_suit-PlayClear")
	call(self,"sort",destlist,"hp")
	if n<3 then
		for _,target in sgs.list(destlist)do
			if call(self,"isFriend",target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not call(self,"isEnemy",target)
			then return target end
		end
	elseif n<4 then
		for _,target in sgs.list(destlist)do
			if call(self,"isFriend",target)
			and call(self,"doDisCard",target,"ej")
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if call(self,"isEnemy",target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not call(self,"isFriend",target)
			then return target end
		end
	elseif n<5 then
		for _,target in sgs.list(destlist)do
			if call(self,"isEnemy",target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not call(self,"isFriend",target)
			then return target end
		end
	end

end

sgs.ai_skill_playerchosen.yingfeng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"handcard",true)
	for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not call(self,"isEnemy",target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.jixianzl = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"handcard")
	for _,target in sgs.list(destlist)do
		if call(self,"isEnemy",target)
		and call(target,"getHandcardNum")<3
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not call(self,"isFriend",target)
		and call(target,"getHandcardNum")<3
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if call(self,"isEnemy",target)
		then return target end
	end
end

sgs.ai_fill_skill.jinhui = function(self)
	return parse(self,"@JinhuiCard=.")
end

sgs.ai_skill_use_func["JinhuiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.JinhuiCard = 9.4
sgs.ai_use_priority.JinhuiCard = 4.8

sgs.ai_skill_use["@@jinhui2!"] = function(self,prompt)
	local ids = tag(self,"jinhuiForAI","IntList","owner")
	local n1 = {}
	for c,id in sgs.list(ids)do
		table.insert(n1,face(self,id))
	end
	call(self,"sortByKeepValue",n1,true)
   	local target = call(self.room,"getCurrent")
	for _,c in sgs.list(n1)do
		if call(self.player,"canUse",c,target,true)
		then
			return response(self,"@JinhuiUseCard="..c:getEffectiveId())
		end
	end
	return response(self,"@JinhuiUseCard="..n1[1]:getEffectiveId())
end

sgs.ai_skill_use["@@jinhui1"] = function(self,prompt)
	local ids = tag(self,"jinhuiForAI","IntList","owner")
	local n1,n2 = {},{}
	for c,id in sgs.list(ids)do
		table.insert(n1,face(self,id))
	end
	call(self,"sortByKeepValue",n1,true)
	return response(self,"@JinhuiUseCard="..n1[1]:getEffectiveId())
end

sgs.ai_skill_playerchosen.jinhui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"handcard")
	for _,target in sgs.list(destlist)do
		if call(self,"isEnemy",target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not call(self,"isFriend",target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_choice.saodi = function(self,choices,data)
	local items = choices:split("+")
	local use = call(data,"toCardUse")
    local to = use.to:at(0)
	local rights,right,lefts,left = 0,0,0,0
    local to1 = call(self.player,"getNextAlive")
    while to1~=to do
        rights = rights+1
		right = call(self,"isFriend",to1) and right+1 or right
        to1 = to1:getNextAlive()
    end
    to1 = call(to,"getNextAlive")
    while to1~=self.player do
        lefts = lefts+1
		left = call(self,"isFriend",to1) and left+1 or left
        to1 = to1:getNextAlive()
    end
	if rights<lefts
	then
		if rights-right>=right
		then return items[1] end
	elseif rights>lefts
	then
		if lefts-left>=left
		then return items[1] end
	else
		if rights-right>=right
		then return items[1] end
		if lefts-left>=left
		then return items[2] end
	end
	return items[2]
end

sgs.ai_skill_playerchosen.zhuitao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"handcard")
	for _,target in sgs.list(destlist)do
		if call(self,"isEnemy",target)
		and call(self.player,"distanceTo",target)>1
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		and call(self.player,"distanceTo",target)>1
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not call(self,"isFriend",target)
		and call(self.player,"distanceTo",target)>1
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if call(self,"isEnemy",target)
		then return target end
	end
end

sgs.ai_skill_invoke.jiqiaosy = function(self,data)
    return call(self.player,"getMaxHp")>2
end

sgs.ai_skill_use["@@jiqiaosy!"] = function(self,prompt)
	local n1,n2 = {},{}
	n2.isRed = 0
	n2.isBlack = 0
	for _,id in sgs.list(call(self.player,"getPile","jiqiaosy"))do
		local c = face(self,id)
		table.insert(n1,c)
		if call(c,"isRed") then n2.isRed = n2.isRed+1
		else n2.isBlack = n2.isBlack+1 end
	end
	call(self,"sortByUseValue",n1,true)
	for _,c in sgs.list(n1)do
		local d = call(self,"aiUseCard",c)
		if d.card and call(c,"isAvailable",self.player)
		then
			if call(c,"isRed") and n2.isRed>n2.isBlack
			then return response(self,"@JiqiaosyCard="..c:getEffectiveId())
			elseif call(c,"isBlack") and n2.isRed<n2.isBlack
			then return response(self,"@JiqiaosyCard="..c:getEffectiveId()) end
		end
	end
	for _,c in sgs.list(n1)do
		if call(c,"isRed") and n2.isRed>n2.isBlack
		then return response(self,"@JiqiaosyCard="..c:getEffectiveId())
		elseif call(c,"isBlack") and n2.isRed<n2.isBlack
		then return response(self,"@JiqiaosyCard="..c:getEffectiveId()) end
	end
	call(self,"sortByKeepValue",n1,true)
	for _,c in sgs.list(n1)do
		local d = call(self,"aiUseCard",c)
		if d.card and call(c,"isAvailable",self.player)
		then
			return response(self,"@JiqiaosyCard="..c:getEffectiveId())
		end
	end
	return response(self,"@JiqiaosyCard="..n1[1]:getEffectiveId())
end

sgs.ai_skill_invoke.xiongyisy = function(self,data)
    local dying = call(data,"toDying")
	return dying.who:objectName()==call(self.player,"objectName")
	and call(self,"getCardsNum","Peach")+call(self,"getCardsNum","Analeptic")<1
end

sgs.ai_fill_skill.xiongmang = function(self)
	local cards = call(self,"addHandPile")
	call(self,"sortByKeepValue",cards,nil,true)
   	local fs = named(self,"xiongmang","slash",{})
 local xiongmang_costs={}
	local suits,n = {},0
   	for i,ep in sgs.list(self.enemies)do
		if call(self.player,"canSlash",ep,fs)
		then n = n+1 end
	end
  	for _,c in sgs.list(cards)do
		if suits[call(c,"getSuitString")]
		or #xiongmang_costs>=n
		then continue end
		suits[call(c,"getSuitString")]=true
		table.insert(xiongmang_costs,call(c,"getEffectiveId"))
	end
	fs=named(self,"xiongmang","slash",xiongmang_costs)
 if call(fs,"isAvailable",self.player)
	and call(fs,"subcardsLength")>#self.enemies/2
 	then return fs end
end

sgs.ai_skill_use["@@xiongmang"] = function(self,prompt)
	local valid = {}
	local xiongmang_c = property(self,self.player,"xiongmang")
	xiongmang_c = parse(self,xiongmang_c)
	local destlist = call(self.player,"getAliveSiblings")
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    call(self,"sort",destlist,"hp")
	for _,ep in sgs.list(destlist)do
		if #valid>=call(xiongmang_c,"subcardsLength")-1 then break end
		if call(self,"isEnemy",ep)
		and call(self.player,"canSlash",ep,xiongmang_c)
		and not call(ep,"hasFlag","xiongmang_target")
		then table.insert(valid,call(ep,"objectName")) end
	end
	for _,ep in sgs.list(destlist)do
		if #valid>=call(xiongmang_c,"subcardsLength")-1 then break end
		if table.contains(valid,call(ep,"objectName")) then continue end
		if not call(self,"isFriend",ep)
		and call(self.player,"canSlash",ep,xiongmang_c)
		and not call(ep,"hasFlag","xiongmang_target")
		then table.insert(valid,call(ep,"objectName")) end
	end
	if #valid>0
	then
    	return response(self,string.format("@XiongmangCard=.->%s",table.concat(valid,"+")))
	end
end

sgs.ai_skill_use["@@jianliang"] = function(self,prompt)
	local valid = {}
	local destlist = call(self.player,"getAliveSiblings")
	destlist:append(self.player)
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    call(self,"sort",destlist,"hp")
	for _,ep in sgs.list(destlist)do
		if #valid>1 then break end
		if call(self,"isFriend",ep) then table.insert(valid,call(ep,"objectName")) end
	end
	for _,ep in sgs.list(destlist)do
		if #valid>1 then break end
		if table.contains(valid,call(ep,"objectName")) then continue end
		if not call(self,"isEnemy",ep) then table.insert(valid,call(ep,"objectName")) end
	end
	if #valid>0
	then
    	return response(self,string.format("@JianliangCard=.->%s",table.concat(valid,"+")))
	end
end

sgs.ai_fill_skill.weimeng = function(self)
	if call(self.player,"getHp")>0
	then
		return parse(self,"@WeimengCard=.")
	end
end

sgs.ai_skill_use_func["WeimengCard"] = function(card,use,self)
	local destlist = call(self.room,"getOtherPlayers",self.player)
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
	call(self,"sort",destlist,"handcard",true)
   	for i,ep in sgs.list(destlist)do
		if call(ep,"getHandcardNum")>=call(self.player,"getHp")
		and call(self,"isEnemy",ep)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
   	for i,ep in sgs.list(destlist)do
		if call(ep,"getHandcardNum")>=call(self.player,"getHp")
		and not call(self,"isFriend",ep)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
   	for i,ep in sgs.list(destlist)do
		if call(self,"isFriend",ep)
		and call(ep,"getHandcardNum")>0
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.WeimengCard = 9.4
sgs.ai_use_priority.WeimengCard = 5.8

sgs.ai_skill_invoke.yusui = function(self,data)
	local target = call(data,"toPlayer")
	if target and call(self,"isEnemy",target)
	and not call(self,"isWeak")
	then
		return call(target,"getHp")>call(self.player,"getHp")
		or call(target,"getHandcardNum")-call(self.player,"getHandcardNum")>1
	end
end

sgs.ai_skill_choice.yusui = function(self,choices,data)
	local target = call(data,"toPlayer")
	local items = choices:split("+")
	if ((call(target,"getHp")-call(self.player,"getHp"))*2)>(call(target,"getHandcardNum")-call(self.player,"getHandcardNum"))
	then return items[2] end
	return items[1]
end

sgs.ai_fill_skill.boyan = function(self)
	return parse(self,"@BoyanCard=.")
end

sgs.ai_skill_use_func["BoyanCard"] = function(card,use,self)
	local destlist = call(self.room,"getOtherPlayers",self.player)
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
	call(self,"sort",destlist,"handcard")
   	for i,ep in sgs.list(destlist)do
		if call(self,"isFriend",ep)
		and call(ep,"getHandcardNum")<5
		and call(ep,"getHandcardNum")<call(ep,"getMaxHp")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
   	for i,ep in sgs.list(destlist)do
		if (call(ep,"getHandcardNum")>=call(ep,"getMaxHp") or call(ep,"getHandcardNum")>=5)
		and call(self,"isEnemy",ep)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
   	for i,ep in sgs.list(destlist)do
		if call(ep,"getHandcardNum")<5
		and call(ep,"getHandcardNum")<call(ep,"getMaxHp")
		and not call(self,"isEnemy",ep)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.BoyanCard = 9.4
sgs.ai_use_priority.BoyanCard = 6.8

sgs.ai_fill_skill.juesheng = function(self)
   	local fs = named(self,"juesheng","duel",{})
	local d = call(self,"aiUseCard",fs)
	if d.card and call(fs,"isAvailable",self.player) then
		for _,ep in sgs.list(d.to)do
			if call(ep,"getMark","JueshengSlashNum")>call(ep,"getHp") then return fs end
		end
	end
end

sgs.ai_skill_choice.zengou = function(self,choices,data)
	local items = choices:split("+")
	local target = call(self.room,"findPlayerByObjectName",items[1]:split("=")[2])
	if target and call(self,"isEnemy",target) then
		if items[1]:startsWith("lose") and call(self,"isWeak") then return "cancel" end
		if items[2]:startsWith("lose") and call(self,"isWeak") then return items[1] end
		return items[1]
	end
	return "cancel"
end

sgs.ai_skill_invoke.zengou = function(self,data)
	local use = call(data,"toCardUse")
	if use.from and call(self,"isEnemy",use.from) then
		return not call(self,"isWeak") or nested(self,"ai_skill_cardask","@zengou-discard",self,data)~="."
	end
	local use = call(data,"toCardResponse")
	if use.m_who and call(self,"isFriend",use.m_who) then
		return not call(self,"isWeak") or nested(self,"ai_skill_cardask","@zengou-discard",self,data)~="."
	end
end

sgs.ai_skill_cardask["@zengou-discard"] = function(self,data)
    local cards = call(self.player,"getCards","he")
    cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if call(self.player,"isJilei",h)
		and call(h,"getTypeId")==1 then continue end
		return call(h,"getEffectiveId")
	end
    return "."
end

sgs.ai_skill_invoke.zhangji = function(self,data)
	local items = call(data,"toString"):split(":")
   	local target = call(self.room,"getCurrent")
	if items[1]=="draw"
	then
		return not call(self,"isEnemy",target)
	else
		return not call(self,"isFriend",target)
	end
end

sgs.ai_skill_invoke.changji = function(self,data)
	return nested(self,"ai_skill_invoke","zhangji",self,data)
end

sgs.ai_skill_discard.shejian = function(self)
	local cards = {}
   	local target = call(self.room,"getCurrent")
    local handcards = sgs.QList2Table(call(self.player,"getCards","he"))
    call(self,"sortByKeepValue",handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if #cards>1 then break end
		if call(self,"isEnemy",target)
		and call(self,"isWeak",target)
		then
			table.insert(cards,call(h,"getEffectiveId"))
		end
	end
	return #cards>1 and cards
end

sgs.ai_skill_choice.shejian = function(self,choices,data)
	local items = choices:split("+")
	if string.startsWith(items[1],"damage")
	then return items[2] end
	if string.startsWith(items[2],"damage")
	then return items[2] end
	return items[1]
end

sgs.ai_skill_playerchosen.jinhuaiyuan = function(self,players)
	local destlist = call(self,"sort",players,"hp")
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not call(self,"isEnemy",target)
		then return target end
	end
end

sgs.ai_skill_choice.jinhuaiyuan = function(self,choices,data)
	local items = choices:split("+")
	local target = call(data,"toPlayer")
	if call(target,"getAttackRange")<3
	then return items[2] end
	if call(target,"getMaxCards")<5
	then return items[1] end
	return items[3]
end

sgs.ai_fill_skill.jinchongxin = function(self)
	if call(self.player,"getCardCount")>1
	then
		return parse(self,"@JinChongxinCard=.")
	end
end

sgs.ai_skill_use_func["JinChongxinCard"] = function(card,use,self)
	call(self,"sort",self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if call(ep,"getHandcardNum")==1
		and call(self.player,"inMyAttackRange",ep)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		if call(ep,"getHandcardNum")>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(call(self.room,"getOtherPlayers",self.player))do
		if call(ep,"getHandcardNum")>0
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.JinChongxinCard = 3.4
sgs.ai_use_priority.JinChongxinCard = 4.8

sgs.ai_skill_cardask["@jinchongxin-recast"] = function(self,data)
    local cards = call(self.player,"getCards","he")
    cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if call(self.player,"isCardLimited",h,sgs.Card_MethodRecast,call(self.player,"getHandcards"):contains(h))
    	then continue end
		return call(h,"getEffectiveId")
	end
    return "."
end

sgs.ai_skill_playerchosen.jinweishu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"hp")
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not call(self,"isEnemy",target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_playerchosen.jinweishu_dis = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"hp")
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		and call(self,"doDisCard",target,"e")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if call(self,"isEnemy",target)
		and call(self,"doDisCard",target,"he")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not call(self,"isFriend",target)
		and call(self,"doDisCard",target,"he")
		then return target end
	end
	return destlist[1]
end

sgs.ai_fill_skill.channi = function(self)
	local toids = {}
	local cards = call(self.player,"getCards","h")
	cards = call(self,"sortByKeepValue",cards)
  	for _,c in sgs.list(cards)do
		if #toids>#cards/2 then break end
		table.insert(toids,call(c,"getEffectiveId"))
	end
	if #toids<1 then return end
	return parse(self,"@ChanniCard="..table.concat(toids,"+"))
end

sgs.ai_skill_use_func["ChanniCard"] = function(card,use,self)
	call(self,"sort",self.friends_noself,"handcard",true)
	for _,fp in sgs.list(self.friends_noself)do
		local c = named(self,"_channi","duel",{})
		if call(c,"isAvailable",fp)
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
end

sgs.ai_use_value.ChanniCard = 2.4
sgs.ai_use_priority.ChanniCard = 0.8

sgs.ai_skill_use["@@channi"] = function(self,prompt)
    local n = call(self.player,"getMark","channi_mark-Clear")
	local c_costs={};local c
    local cards = call(self.player,"getCards","h")
    cards = call(self,"sortByKeepValue",cards,nil,true) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if #c_costs>=#cards/2
		or #c_costs>=n
		then break end
		if call(h,"isKindOf","Slash")
		and math.random()>0.4
		then continue end
		table.insert(c_costs,call(h,"getEffectiveId"))
	end
    c=named(self,"_channi","duel",c_costs);local dummy = call(self,"aiUseCard",c)
   	if dummy.card
   	and dummy.to
   	then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,call(p,"objectName"))
       	end
       	return answer(self,c,tos)
    end
end

sgs.ai_skill_invoke.tiqi = function(self,data)
    return true
end

sgs.ai_skill_choice.tiqi = function(self,choices,data)
	local items = choices:split("+")
	local target = call(data,"toPlayer")
	if call(self,"isFriend",target)
	then return items[1] end
	return items[2]
end

sgs.ai_skill_use["@@baoshu"] = function(self,prompt)
	local valid = {}
	local destlist = call(self.player,"getAliveSiblings")
	destlist:append(self.player)
    destlist = call(self,"sort",destlist,"hp")
	for _,friend in sgs.list(destlist)do
		if #valid>=call(self.player,"getMaxHp") then break end
		if call(self,"isFriend",friend)
		then table.insert(valid,call(friend,"objectName")) end
	end
	if #valid>0
	then
    	return response(self,string.format("@BaoshuCard=.->%s",table.concat(valid,"+")))
	end
end

sgs.ai_skill_invoke.tianyun = function(self,data)
    return true
end

sgs.ai_skill_playerchosen.tianyun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"hp")
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.yuyan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"hp")
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		and #self.enemies>#self.friends
		then return target end
		if call(self,"isEnemy",target)
		and #self.enemies<#self.friends
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_invoke.bingjie = function(self,data)
    local n = 0
    for _,c in sgs.list(call(self,"getTurnUse"))do
		if call(c,"getTypeId")==1
		or call(c,"getTypeId")==2
		then n = n+1 end
	end
	return n>1 and call(self.player,"isWounded")
end

sgs.ai_skill_invoke.qibie = function(self,data)
    return call(self.player,"getHandcardNum")>4
	or call(self.player,"isWounded")
end

sgs.ai_fill_skill.yijiao = function(self)
	return parse(self,"@YijiaoCard=.")
end

sgs.ai_skill_use_func["YijiaoCard"] = function(card,use,self)
	call(self,"sort",self.friends_noself,"handcard",true)
	save_choice(self,"yijiao",""..math.random(1,2))
	for _,ep in sgs.list(self.friends_noself)do
		if call(ep,"getHandcardNum")>0
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	save_choice(self,"yijiao",""..math.random(3,4))
	call(self,"sort",self.enemies,"handcard")
	for _,ep in sgs.list(self.enemies)do
		if call(ep,"getHandcardNum")>0
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	local tos = call(self.room,"getOtherPlayers",self.player)
	tos = call(self,"sort",tos,"handcard",true)
	save_choice(self,"yijiao",""..math.random(1,4))
	for _,ep in sgs.list(tos)do
		if call(ep,"getHandcardNum")>2
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.YijiaoCard = 1.4
sgs.ai_use_priority.YijiaoCard = 1.8

sgs.ai_skill_use["@@xunli2!"] = function(self,prompt)
	local valid = {}
	local jpxlli = tag(self,"xunliForAI","IntList","owner")
	jpxlli = cards_from_ids(self,jpxlli)
	jpxlli = call(self,"sortByUseValue",jpxlli)
	local put = 9-call(self.player,"getPile","jpxlli"):length()
	for _,c in sgs.list(jpxlli)do
		if #valid>=put then break end
		if call(c,"isAvailable",self.player)
		then
			table.insert(valid,call(c,"getEffectiveId"))
		end
	end
	for _,c in sgs.list(jpxlli)do
		if #valid>=put then break end
		if table.contains(valid,call(c,"getEffectiveId"))
		then continue end
		table.insert(valid,call(c,"getEffectiveId"))
	end
	return #valid>0 and response(self,string.format("@XunliPutCard=%s",table.concat(valid,"+")))
end

sgs.ai_skill_use["@@xunli1"] = function(self,prompt)
	local valid = {}
    local cards = call(self.player,"getCards","h")
	local jpxlli = call(self.player,"getPile","jpxlli")
	jpxlli = call(self,"sortByUseValue",cards_from_ids(self,jpxlli))
	for _,h in sgs.list(call(self,"sortByKeepValue",cards))do
		if not call(h,"isBlack") then continue end
		for i,c in sgs.list(jpxlli)do
			if call(self,"aiUseCard",c).card then
				if call(self,"aiUseCard",h).card then
					if call(self,"getUseValue",h)<call(self,"getUseValue",c) then
						table.insert(valid,call(h,"getEffectiveId"))
						table.insert(valid,call(c,"getEffectiveId"))
						table.remove(jpxlli,i)
						break
					end
				else
					table.insert(valid,call(h,"getEffectiveId"))
					table.insert(valid,call(c,"getEffectiveId"))
					table.remove(jpxlli,i)
					break
				end
			end
		end
	end
	return #valid>1 and response(self,string.format("@XunliCard=%s",table.concat(valid,"+")))
end

sgs.ai_skill_playerchosen.zhishi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"hp")
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_use["@@zhishi"] = function(self,prompt)
	local valid = {}
	local jpxlli = call(self.player,"getPile","jpxlli")
	jpxlli = cards_from_ids(self,jpxlli)
	jpxlli = call(self,"sortByUseValue",jpxlli)
	local to = tag(self,"ZhishiTarget","Player","owner")
	for _,h in sgs.list(jpxlli)do
		if call(to,"getHandcardNum")+#valid>3 or call(self,"isEnemy",to) then continue end
		table.insert(valid,call(h,"getEffectiveId"))
	end
	return #valid>0 and response(self,string.format("@ZhishiCard=%s",table.concat(valid,"+")))
end

sgs.ai_fill_skill.lieyi = function(self)
	if #self.toUse<2
	then
		return parse(self,"@LieyiCard=.")
	end
end

sgs.ai_skill_use_func["LieyiCard"] = function(card,use,self)
	local jpxlli = call(self.player,"getPile","jpxlli")
	jpxlli = cards_from_ids(self,jpxlli)
	call(self,"sort",self.enemies,"handcard")
	for _,ep in sgs.list(self.enemies)do
		local n = 0
		for _,c in sgs.list(jpxlli)do
			local d = call(self,"aiUseCard",c)
			if d.card and d.to:contains(ep)
			then n = n+1 end
		end
		if n>jpxlli:length()/2
		or n>call(ep,"getHp") then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	local tos = call(self.room,"getOtherPlayers",self.player)
	tos = call(self,"sort",tos,"handcard")
	for _,ep in sgs.list(tos)do
		local n = 0
		for _,c in sgs.list(jpxlli)do
			local d = call(self,"aiUseCard",c)
			if d.card and d.to:contains(ep)
			then n = n+1 end
		end
		if n>jpxlli:length()/2
		or n>call(ep,"getHp") then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.LieyiCard = 1.4
sgs.ai_use_priority.LieyiCard = 0.8

sgs.ai_fill_skill.manwang = function(self)
	local toids = {}
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards,nil,true)
	local n = 4-call(self.player,"getMark","manwang_remove_last")
  	for _,c in sgs.list(cards)do
		if #toids>=#cards/2 or #toids>=n then break end
		if call(self,"getUseValue",c)<3.5 then
			table.insert(toids,call(c,"getEffectiveId"))
		end
	end
	if #toids<1 or #cards<3 then return end
	if call(self.player,"hasSkill","panqin") and #toids<2 then return end
	if call(self,"isWeak") and #toids<3 then return end
	return parse(self,"@ManwangCard="..table.concat(toids,"+"))
end

sgs.ai_skill_use_func["ManwangCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ManwangCard = 2.4
sgs.ai_use_priority.ManwangCard = 1.8

sgs.ai_skill_invoke.panqin = function(self,data)
    local dc_costs={};local dc
    for _,id in sgs.list(tag(self,"PanqinRecord","IntList","owner"))do
		if call(self.room,"getCardPlace",id)==sgs.Player_DiscardPile
		then table.insert(dc_costs,id) end
	end
	return call(self,"aiUseCard",named(self,"panqin","SavageAssault",dc_costs)).card
end

sgs.ai_skill_invoke.jinjian = function(self,data)
	local invoke = call(data,"toString")
	local damage = tag(self,"JinjianDamage","Damage","owner")
	if invoke=="add" then
		return call(self,"isEnemy",damage.to)
		or not call(self,"isFriend",damage.to) and not call(self,"isWeak",damage.to)
	end
    return call(self,"isFriend",damage.to)
	or call(self,"isWeak",damage.to) and not call(self,"isEnemy",damage.to)
end

sgs.ai_guhuo_card.dunshi = function(self,toname,class_name)
	if class_name=="Slash" then toname = "slash" end
   	local target = call(self.room,"getCurrent")
	if call(self,"getCardsNum",class_name)<1 or call(self,"isFriend",target)
	then return proposal(self,"@DunshiCard=.:"..toname) end
end

sgs.ai_fill_skill.dunshi = function(self)
 	for _,pn in sgs.list({"slash","peach","analeptic"})do
		if call(self.player,"getMark","dunshi_used_"..pn)>0
		or pn=="slash" and call(self.player,"getLostHp")<1
		then continue end
		local dc = evaluation(self,pn)
		if dc and call(self,"getCardsNum",call(dc,"getClassName"))<1 then
			dc=named(self,"dunshi",pn,{})
			if call(dc,"isAvailable",self.player) then
				local dummy = call(self,"aiUseCard",dc)
				if dummy.card and dummy.to
				then
					save_targets(self,"dunshi_to",dummy.to)
					sgs.ai_use_priority.DunshiCard = sgs.ai_use_priority[call(dc,"getClassName")]
					return parse(self,"@DunshiCard=.:"..pn)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["DunshiCard"] = function(card,use,self)
	if targets(self,"dunshi_to")
	then
		use.card = card
		use.to = targets(self,"dunshi_to")
	end
end

sgs.ai_use_value.DunshiCard = 2.4
sgs.ai_use_priority.DunshiCard = 6.8

sgs.ai_skill_choice.dunshi = function(self,choices,data)
	local items = choices:split("+")
	local damage = call(data,"toDamage")
	if call(self,"isFriend",call(self.room,"getCurrent"))
	then
		if call(self.player,"isWounded") or call(self.player,"getMaxHp")>5 then return items[1] end
	end
	if #items>2
	then
		if call(self.player,"isWounded") or call(self.player,"getMaxHp")>5 then return items[2] end
		if call(self,"isFriend",damage.to) and call(self,"isWeak",damage.to)
		or call(self,"isFriend",damage.from) then return items[1] end
	else
		local cn = items[2]:split("=")[2]
		if cn=="slash" or cn=="analeptic"
		then return items[2] end
	end
	return items[1]
end

sgs.ai_skill_choice.dunshi_chooseskill = function(self,choices,data)
	local items = choices:split("+")
	local target = call(data,"toPlayer")
	if call(self,"isFriend",target)
	then
		if table.contains(items,"renzheng")
		then return "renzheng" end
		if table.contains(items,"lilu")
		then return "lilu" end
		if table.contains(items,"zhici")
		then return "zhici" end
	end
end

sgs.ai_skill_invoke.chenjian = function(self,data)
    return true
end

sgs.ai_skill_use["@@chenjian1"] = function(self,prompt)
	local valid = nested(self,"ai_skill_use","@@chenjian3",self,prompt)
	if valid then return valid end
	return nested(self,"ai_skill_use","@@chenjian2",self,prompt)
end

sgs.ai_skill_use["@@chenjian2"] = function(self,prompt)
	local jpxlli = tag(self,"chenjianForAI","IntList","owner")
	jpxlli = cards_from_ids(self,jpxlli)
	local suits = {}
    local cards = call(self.player,"getCards","he")
    cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c in sgs.list(jpxlli)do
		local s = call(c,"getSuitString")
		if suits[s] then suits[s] = suits[s]+1
		else suits[s] = 1 end
	end
	local func = function(a,b)
		return a>b
	end
	table.sort(suits,func)
	call(self,"sort",self.friends,"handcard")
	for _,c in sgs.list(cards)do
		local s = call(c,"getSuitString")
		if suits[s] and suits[s]>0 then
			return response(self,"@ChenjianCard="..c:getEffectiveId().."->"..self.friends[1]:objectName())
		end
	end
end

sgs.ai_skill_use["@@chenjian3"] = function(self,prompt)
	local valid = {}
	local jpxlli = tag(self,"chenjianForAI","IntList","owner")
	jpxlli = cards_from_ids(self,jpxlli)
	jpxlli = call(self,"sortByKeepValue",jpxlli,true)
	for _,c in sgs.list(jpxlli)do
		if call(c,"isAvailable",self.player) then
			local d = call(self,"aiUseCard",c)
			if d.card and d.to then
				if call(c,"canRecast") and d.to:length()<1
				then continue end
				for _,to in sgs.list(d.to)do
					table.insert(valid,call(to,"objectName"))
				end
				return answer(self,c,valid)
			end
		end
	end
end

sgs.ai_fill_skill.yuanyu = function(self)
	return parse(self,"@YuanyuCard=.")
end

sgs.ai_skill_use_func["YuanyuCard"] = function(card,use,self)
	call(self,"sort",self.enemies,"handcard",true)
	for _,ep in sgs.list(self.enemies)do
		if call(ep,"getHandcardNum")>0
		and call(ep,"getMark","&yuanyu+#"..self.player:objectName())<1
		then
			use.card = card
			return
		end
	end
	local tos = call(self.room,"getOtherPlayers",self.player)
	tos = call(self,"sort",tos,"handcard",true)
	for _,ep in sgs.list(tos)do
		if call(ep,"getHandcardNum")>0
		and not call(self,"isFriend",ep)
		then
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.YuanyuCard = 3.4
sgs.ai_use_priority.YuanyuCard = 3.8

sgs.ai_skill_playerchosen.yuanyu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if call(self,"isEnemy",target)
		and call(target,"getMark","&yuanyu+#"..self.player:objectName())<1
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not call(self,"isFriend",target)
		and call(target,"getMark","&yuanyu+#"..self.player:objectName())<1
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_playerchosen.jinzhefu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if call(self,"isEnemy",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not call(self,"isFriend",target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_discard.jinzhefu = function(self,max,min,optional,include_equip,pattern)
	local to_cards = {}
	local cards = call(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min then break end
		if call(self,"getKeepValue",h)<6
		and matches(self,pattern,self.player,h)
		then table.insert(to_cards,call(h,"getEffectiveId")) end
	end
	return to_cards
end


sgs.ai_skill_invoke.jinyidu = function(self,data)
	local target = call(data,"toPlayer")
	if target
	then
		return call(self,"isEnemy",target)
		or not call(self,"isFriend",target) and not call(self,"isWeak",target)
	end
end

sgs.ai_skill_invoke.xingchong = function(self,data)
    return true
end

sgs.ai_skill_choice.xingchong = function(self,choices,data)
	local items = choices:split("+")
	if #items>1 then return items[math.random(2,#items)] end
	return items[1]
end

sgs.ai_skill_discard.xingchong = function(self,max,min)
	local to_cards = {}
	local cards = call(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
	local uses = call(self,"getTurnUse")
   	for _,h in sgs.list(cards)do
   		if #to_cards>=max then break end
		if table.contains(uses,h)
		then
         	table.insert(to_cards,call(h,"getEffectiveId"))
		end
	end
	return to_cards
end

sgs.ai_skill_playerschosen.lianzhou = function(self,players,n,x)
	local tos = {}
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if call(self,"isEnemy",target)
		then table.insert(tos,target) end
	end
    for _,target in sgs.list(destlist)do
		if #tos>1 then break end
		if not call(self,"isFriend",target)
		then table.insert(tos,target) end
	end
	return tos
end

sgs.ai_skill_invoke.choutao = function(self,data)
	local target = call(data,"toPlayer")
	if target
	then
		return not call(self,"isFriend",target) and call(self,"getCardsNum","Jink")<1
		or call(self,"isFriend",target) and (call(self,"doDisCard",target,"e") or target==self.player and call(target,"getCardCount")>3)
	end
end

sgs.ai_skill_playerchosen.xiangshu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"hp")
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		and call(self,"isWeak",target)
		and call(self.player,"getMark","damage_point_round")>=call(target,"getLostHp")
		then return target end
	end
end

sgs.ai_skill_invoke.zhubi = function(self,data)
   	local target = call(self.room,"getCurrent")
	if call(target,"getPhase")<sgs.Player_Play
	then return call(self,"isFriend",target) end
	target = call(target,"getNextAlive")
	return call(self,"isFriend",target)
end

sgs.ai_skill_playerchosen.guili = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not call(self,"isEnemy",target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_playerchosen.caiyi = function(self,players)
	local n = call(self.player,"getChangeSkillState","caiyi")
	save_player(self,"caiyi_from",self.player)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"hp")
	if n>1
	then
		for _,target in sgs.list(destlist)do
			if call(self,"isEnemy",target)
			and (call(self,"isWeak",target) or call(self,"isWeak"))
			then return target end
		end
	else
		local removes = property(self,self.player,"SkillDescriptionRecord_caiyi"):split("+")
		n = 4-#removes
		for _,target in sgs.list(destlist)do
			if call(self,"isFriend",target)
			then
				if not table.contains(removes,"caiyi_recover") and (call(target,"getLostHp")>=n or call(self,"isWeak",target) and n>0)
				or not table.contains(removes,"caiyi_draw") and call(target,"getHandcardNum")+n<5
				or not table.contains(removes,"caiyi_fuyuan") and not call(target,"faceUp")
				or not table.contains(removes,"caiyi_random1") and call(self,"isWeak",target)
				then return target end
			end
		end
	end
end

sgs.ai_skill_choice.caiyi = function(self,choices,data)
	local caiyi_from = saved_player(self,"caiyi_from") or call(self.room,"getCurrent")
	local n = call(caiyi_from,"getChangeSkillState","caiyi")
	if n>1 then n = 4-#property(self,caiyi_from,"SkillDescriptionChoiceRecord1_caiyi"):split("+")
	else n = 4-#property(self,caiyi_from,"SkillDescriptionRecord_caiyi"):split("+") end
	local items = choices:split("+")
	for _,cho in sgs.list(items)do
		if cho:startsWith("recover")
		and (call(self.player,"getLostHp")>=n or call(self,"isWeak") and n>0)
		then return cho end
		if cho:startsWith("draw")
		and call(self.player,"getHandcardNum")+n<5
		then return cho end
		if cho:startsWith("fuyuan")
		and not call(self.player,"faceUp")
		then return cho end
		if cho:startsWith("discard")
		and call(self.player,"getCardCount")-n>1
		then return cho end
		if cho:startsWith("damage")
		and call(self.player,"getHp")-n>1
		then return cho end
	end
end

sgs.ai_fill_skill.shengong = function(self)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
  	for _,c in sgs.list(cards)do
		if call(c,"isKindOf","EquipCard") then
			local i = call(c,"getEquipSlot")
			if(call(self.player,"getMark",i.."shengong-PlayClear")>0)then continue end
			for _,p in sgs.list(self.friends)do
				for _,pc in sgs.list(call(self,"poisonCards","e",p))do
					local l = call(pc,"getEquipSlot")
					if(i==l)then
						save_player(self,"shengongTo",p)
						return parse(self,"@ShengongCard="..c:getId())
					end
				end
			end
			for _,p in sgs.list(self.friends)do
				if(call(p,"hasEquipArea",i) and not call(p,"getEquip",i))then
					save_player(self,"shengongTo",p)
					return parse(self,"@ShengongCard="..c:getId())
				end
			end
		end
	end
end

sgs.ai_skill_use_func["ShengongCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ShengongCard = 2.4
sgs.ai_use_priority.ShengongCard = 5.8

sgs.ai_skill_playerchosen.shengong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
    for _,target in sgs.list(destlist)do
		if saved_player(self,"shengongTo")==target
		then return target end
	end
	call(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_choice.shengong = function(self,choices,data)
	local to = call(data,"toPlayer")
	if(call(self,"isFriend",to)) then
		return "shengong1"
	end
	if(call(self,"isEnemy",to)) then
		return "shengong2"
	end
end

sgs.ai_skill_invoke.chishi = function(self,data)
   	local target = call(data,"toPlayer")
	return target and call(self,"isFriend",target) and call(self,"canDraw",target)
end

sgs.ai_fill_skill.weimian = function(self)
	call(self,"sort",self.friends)
	for _,p in sgs.list(self.friends)do
		if call(self,"isWeak",p) or call(p,"getHandcardNum")<2 and call(self,"canDraw",p) then
			save_player(self,"weimianTo",p)
			return parse(self,"@WeimianCard=.")
		end
	end
end

sgs.ai_skill_use_func["WeimianCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.WeimianCard = 2.4
sgs.ai_use_priority.WeimianCard = 5.8

sgs.ai_skill_choice.weimian = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"cancel")
	then return "cancel" end
	for _,t in sgs.list(items)do
		local e = call(self.player,"getEquip",t)
		if e and #call(self,"poisonCards",{e})>0 then
			return t
		end
	end
	for _,t in sgs.list(sgs.reverse(items))do
		local e = call(self.player,"getEquip",t)
		if e==nil then
			return t
		end
	end
	return items[#items]
end

sgs.ai_skill_playerchosen.weimian = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
    for _,target in sgs.list(destlist)do
		if saved_player(self,"weimianTo")==target
		then return target end
	end
	call(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_choice.weimian_target = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"weimian3")
	and call(self.player,"getHandcardNum")<2 and call(self,"canDraw")
	then return "weimian3" end
	if table.contains(items,"weimian2")
	and call(self,"isWeak")
	then return "weimian2" end
	return items[1]
end

sgs.ai_skill_choice.qingliu = function(self,choices)
	local items = choices:split("+")
	for _,p in sgs.list(self.friends_noself)do
		if table.contains(items,call(p,"getKingdom"))
		then return call(p,"getKingdom") end
	end
end

sgs.ai_skill_playerchosen.yongzu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for i,target in sgs.list(destlist)do
		if i<=#destlist/2 and call(self,"isFriend",target)
		and not call(target,"faceUp")
		then return target end
	end
    for i,target in sgs.list(destlist)do
		if i<=#destlist/2 and call(self,"isFriend",target)
		and call(target,"getKingdom")==call(self.player,"getKingdom")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not call(self,"isEnemy",target)
		then return target end
	end
end

sgs.ai_skill_choice.yongzu = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"yongzu3")
	and not call(self.player,"faceUp")
	then return "yongzu3" end
	if table.contains(items,"yongzu2")
	and call(self,"isWeak")
	then return "yongzu2" end
	if table.contains(items,"yongzu1")
	and call(self.player,"getHandcardNum")<2 and call(self,"canDraw")
	then return "yongzu1" end
	if table.contains(items,"yongzu4")
	and call(self,"getOverflow")>1
	then return "yongzu4" end
	return items[#items]
end

sgs.ai_fill_skill.kouchao = function(self)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
	local cns = property(self,self.player,"KouchaoCNS"):split("+");
	if #cns<2 then cns = {"slash","fire_attack","dismantlement"} end
  	for _,c in sgs.list(cards)do
		local n = 0
		for _,cn in sgs.list(cns)do
			n = n+1
			if call(self.player,"getMark",cn..n.."KouchaoUse_lun")>0
			or call(self.player,"getMark",n.."KouchaoNum_lun")>0
			then continue end
			local dc = named(self,"kouchao",cn,{call(c,"getEffectiveId")})
			if call(dc,"isAvailable",self.player) then
				local d = call(self,"aiUseCard",dc)
				if d.card then
					if call(dc,"canRecast") and d.to:length()<1 then continue end
					save_plan(self,"kouchaoUse",d)
					save_choice(self,"kouchao",cn)
					sgs.ai_use_priority.KouchaoCard = sgs.ai_use_priority[call(dc,"getClassName")]
					return parse(self,"@KouchaoCard=.")
				end
			end
		end
	end
end

sgs.ai_skill_use_func["KouchaoCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.KouchaoCard = 2.4
sgs.ai_use_priority.KouchaoCard = 5.8

sgs.ai_skill_use["@@kouchao"] = function(self,prompt)
	local valid = {}
	local d = load_plan(self,"kouchaoUse")
	if d.card then
		for _,to in sgs.list(d.to)do
			table.insert(valid,call(to,"objectName"))
		end
		return answer(self,d.card,valid)
	end
end

sgs.ai_guhuo_card.kouchao = function(self,toname,class_name)
	if call(self,"getCardsNum",class_name)<1 then
		local cards = call(self.player,"getCards","he")
		cards = call(self,"sortByKeepValue",cards)
		local cns = property(self,self.player,"KouchaoCNS"):split("+");
		if #cns<2 then cns = {"slash","fire_attack","dismantlement"} end
		for _,c in sgs.list(cards)do
			local n = 0
			for _,cn in sgs.list(cns)do
				n = n+1
				if call(self.player,"getMark",cn..n.."KouchaoUse_lun")>0
				or call(self.player,"getMark",n.."KouchaoNum_lun")>0
				or toname~=cn then continue end
				local dc = named(self,"kouchao",cn,{call(c,"getEffectiveId")})
				return descriptor(dc)
			end
		end
	end
end

sgs.ai_fill_skill.hunjiang = function(self)
	return parse(self,"@HunjiangCard=.")
end

sgs.ai_skill_use_func["HunjiangCard"] = function(card,use,self)
  	for _,p in sgs.list(call(self.room,"getAllPlayers"))do
		if call(self.player,"inMyAttackRange",p) then
			use.card = card
			use.to:append(p)
		end
	end
end

sgs.ai_use_value.HunjiangCard = 2.4
sgs.ai_use_priority.HunjiangCard = 5.8

sgs.ai_skill_choice.hunjiang = function(self,choices,data)
	local items = choices:split("+")
	local to = call(data,"toPlayer")
	if call(self,"isFriend",to) or call(self,"isWeak") and call(to,"canSlash",self.player)
	and getCardsNum("Slash",to,self.player)>0 and call(self,"isEnemy",to)
	then return items[2] end
	if call(self,"isEnemy",to)
	then return items[1] end
end

sgs.ai_skill_playerschosen.hunjiang = function(self,players,x)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local tos = {}
	local use = tag(self,"hunjiangUse","CardUse","owner")
    for _,p in sgs.list(destlist)do
		if #tos<x and not call(self,"isFriend",p) and call(self,"slashIsEffective",use.card,p)
		then table.insert(tos,p) end
	end
    return tos
end

sgs.ai_fill_skill.jinlan = function(self)
	return parse(self,"@JinlanCard=.")
end

sgs.ai_skill_use_func["JinlanCard"] = function(card,use,self)
  	for _,p in sgs.list(call(self.room,"getAllPlayers"))do
		local n = 0
		for _,s in sgs.list(call(p,"getVisibleSkillList"))do
			if not s:isAttachedLordSkill() then n = n+1 end
		end
		if n>call(self.player,"getHandcardNum") then
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.HunjiangCard = 6.4
sgs.ai_use_priority.HunjiangCard = 2.8

sgs.ai_skill_choice.jianman = function(self,choices)
	local items = choices:split("+")
  	for _,cn in sgs.list(items)do
		local dc = call(self,"evaluateJianmanCard",cn)
		if not call(self.player,"isLocked",dc) then
			local d = call(self,"aiUseCard",dc)
			if d.card then
				call(self,"rememberJianmanUse",d.card,d.to,cn,d)
				return cn
			end
		end
	end
end

sgs.ai_skill_use["@@jianman"] = function(self,prompt)
 return call(self,"materializeJianmanUse")
end

sgs.ai_skill_playerschosen.liwen = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<=#self.friends/2 and call(self,"isFriend",p) and call(p,"getHandcardNum")>1
		then table.insert(tos,p) end
	end
    return tos
end

sgs.ai_skill_choice.zhengyi = function(self,choices,data)
	local items = choices:split("+")
	local tp = call(data,"toPlayer")
	if call(self,"isFriend",tp) then
		local n = 0
		for _,p in sgs.list(call(self.room,"getAlivePlayers"))do
			if call(p,"getMark","&xianLW")>0 and call(p,"getHp")>n then
				n = call(p,"getHp")
			end
		end
		if call(self.player,"getHp")>=n then
			call(self,"sort",self.friends,nil,true)
			for i,p in sgs.list(self.friends)do
				if i<=#self.friends/2 and p==self.player then
					return "yes"
				end
			end
		end
	end
	return "no"
end

sgs.ai_skill_invoke.hongtu = function(self,data)
	return call(self,"canDraw")
end

sgs.ai_skill_use["@@hongtu!"] = function(self,prompt)
	local ids = {}
	call(self,"sort",self.friends_noself,nil,true)
	local cards = call(self.player,"getHandcards")
	cards = call(self,"sortByKeepValue",cards)
	for _,p in sgs.list(self.friends_noself)do
		for _,h in sgs.list(sgs.reverse(cards))do
			if #ids<2 and call(h,"isAvailable",p) then
				table.insert(ids,call(h,"getId"))
			end
		end
		for _,h in sgs.list(cards)do
			if #ids<3 and not table.contains(ids,call(h,"getId")) then
				table.insert(ids,call(h,"getId"))
			end
		end
		return response(self,"@HongtuCard="..table.concat(ids,"+").."->"..p:objectName())
	end
	for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
		if call(self,"isEnemy",p) then continue end
		for _,h in sgs.list(sgs.reverse(cards))do
			if #ids<2 and call(h,"isAvailable",p) then
				table.insert(ids,call(h,"getId"))
			end
		end
		for _,h in sgs.list(cards)do
			if #ids<3 and not table.contains(ids,call(h,"getId")) then
				table.insert(ids,call(h,"getId"))
			end
		end
		return response(self,"@HongtuCard="..table.concat(ids,"+").."->"..p:objectName())
	end
	for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
		for _,h in sgs.list(cards)do
			if #ids<3 then
				table.insert(ids,call(h,"getId"))
			end
		end
		return response(self,"@HongtuCard="..table.concat(ids,"+").."->"..p:objectName())
	end
end

sgs.ai_skill_use["@@hongtu"] = function(self,prompt)
	local cards = {}
	for _,id in sgs.list(tag(self,"hongtuForAI","IntList","owner"))do
		table.insert(cards,face(self,id))
	end
	cards = call(self,"sortByUseValue",cards)
	for _,c in sgs.list(cards)do
		if call(c,"isAvailable",self.player) then
			local d = call(self,"aiUseCard",c)
			if d.card then
				if call(c,"canRecast") and d.to:length()<1 then continue end
				local valid = {}
				for _,to in sgs.list(d.to)do
					table.insert(valid,call(to,"objectName"))
				end
				return answer(self,c,valid)
			end
		end
	end
end

sgs.ai_skill_discard.xiwu = function(self,max,min,optional,include_equip,pattern)
	local to_cards = {}
	if persistent_effect(self) and persistent_effect(self).card and persistent_effect(self).card:isDamageCard()
	and call(self,"canDamageHp",persistent_effect(self).from,persistent_effect(self).card)
	then return to_cards end
	local cards = call(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min then break end
		if matches(self,pattern,self.player,h)
		then table.insert(to_cards,call(h,"getEffectiveId")) end
	end
	return to_cards
end

sgs.ai_skill_invoke.dongdao = function(self,data)
	return call(self,"canDraw")
end

sgs.ai_fill_skill.fushi = function(self)
	local fss = call(self.player,"getPile","fushi")
	local ids = {}
  	for _,id in sgs.list(fss)do
		table.insert(ids,id)
		if #ids>fss:length()/2 then
			return parse(self,"@FushiCard="..table.concat(ids,"+"))
		end
	end
end

sgs.ai_skill_use_func["FushiCard"] = function(card,use,self)
  	local dc = named(self,"fushi","slash",{})
	if call(dc,"isAvailable",self.player) then
		local d = call(self,"aiUseCard",dc)
		if d.card then
			use.card = card
			use.to = d.to
		end
	end
end

sgs.ai_use_value.FushiCard = 5.4
sgs.ai_use_priority.FushiCard = 2.8

function sgs.ai_cardsview.fushi(self,class_name,player)
	local fss = call(player,"getPile","fushi")
	local ids = {}
  	for _,id in sgs.list(fss)do
		table.insert(ids,id)
		if #ids>fss:length()/2 then
			return proposal(self,"@FushiCard="..table.concat(ids,"+"))
		end
	end
end

sgs.ai_skill_choice.fushi = function(self,choices,data)
	local items = choices:split("+")
	local use = call(data,"toCardUse")
	if table.contains(items,"fushi1") then
		call(self,"sort",self.enemies)
		local dc = evaluation(self)
		save_player(self,"fushi1To",nil)
		for _,p in sgs.list(self.enemies)do
			if call(self.player,"canSlash",p,dc) and call(self,"slashIsEffective",dc,p) then
				save_player(self,"fushi1To",p)
				return "fushi1"
			end
		end
		for _,p in sgs.list(self.friends_noself)do
			if call(self.player,"canSlash",p,dc) and not call(self,"slashIsEffective",dc,p) then
				save_player(self,"fushi1To",p)
				return "fushi1"
			end
		end
	end
	if table.contains(items,"fushi2") then
		local dc = evaluation(self)
		save_player(self,"fushi2To",nil)
		for _,p in sgs.list(self.friends_noself)do
			if use.to:contains(p) then
				save_player(self,"fushi2To",p)
				return "fushi2"
			end
		end
	end
	if table.contains(items,"fushi3") then
		save_player(self,"fushi3To",nil)
		for _,p in sgs.list(self.enemies)do
			if use.to:contains(p) then
				save_player(self,"fushi3To",p)
				return "fushi2"
			end
		end
		return "fushi3"
	end
	return items[#items]
end

sgs.ai_skill_playerchosen.fushi1 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
    for _,target in sgs.list(destlist)do
		if saved_player(self,"fushi1To")==target
		then return target end
	end
	call(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if call(self,"isEnemy",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not call(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.fushi2 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
    for _,target in sgs.list(destlist)do
		if saved_player(self,"fushi2To")==target
		then return target end
	end
	call(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not call(self,"isEnemy",target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.fushi3 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
    for _,target in sgs.list(destlist)do
		if saved_player(self,"fushi3To")==target
		then return target end
	end
	call(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if call(self,"isEnemy",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not call(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_fill_skill.zuolian = function(self)
	return parse(self,"@ZuolianCard=.")
end

sgs.ai_skill_use_func["ZuolianCard"] = function(card,use,self)
	call(self,"sort",self.friends_noself,nil,true)
  	for _,p in sgs.list(self.friends_noself)do
		if use.to:length()<call(self.player,"getHp") and call(p,"getHandcardNum")>0 then
			use.card = card
			use.to:append(p)
		end
	end
end

sgs.ai_use_value.ZuolianCard = 2.4
sgs.ai_use_priority.ZuolianCard = 4.8

sgs.ai_skill_invoke.zuolian = function(self,data)
	return call(self,"canDraw")
end

sgs.ai_skill_playerschosen.jingzhou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<call(self.player,"getHp") and call(self,"isFriend",p)
		and call(p,"isChained") and p~=self.player
		then table.insert(tos,p) end
	end
	local damage = tag(self,"jingzhouDamage","Damage","owner")
	if damage.nature~=sgs.DamageStruct_Normal then
		if #tos<call(self.player,"getHp") and #self.enemies>0
		and not call(self.player,"isChained")
		then table.insert(tos,self.player) end
		for _,p in sgs.list(sgs.reverse(destlist))do
			if #tos<call(self.player,"getHp") and call(self,"isEnemy",p)
			and not call(p,"isChained")
			then table.insert(tos,p) end
		end
	else
		for _,p in sgs.list(sgs.reverse(destlist))do
			if #tos<call(self.player,"getHp") and call(self,"isEnemy",p)
			and not call(p,"isChained")
			then table.insert(tos,p) end
		end
	end
    return tos
end

sgs.ai_skill_playerschosen.pijing = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
	local tos = {}
	local n = math.max(1,call(self.player,"getLostHp"))
	local use = tag(self,"pijingUse","CardUse","owner")
    for _,p in sgs.list(destlist)do
		if #tos<n and call(self,"isFriend",p) and use.to:contains(p)
		and call(use.card,"isDamageCard") and not call(self,"canDamageHp",use.from,use.card)
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<n and call(self,"isEnemy",p) and not use.to:contains(p)
		and (call(use.card,"isDamageCard") or not call(self,"isFriend",use.to:at(0)))
		and call(self,"hasTrickEffective",use.card,p)
		then table.insert(tos,p) end
	end
    return tos
end

sgs.ai_skill_choice.pijing = function(self,choices,data)
	local items = choices:split("+")
	local to = call(data,"toPlayer")
	if table.contains(items,"pijing2") and call(self,"isFriend",to) then
		return "pijing2"
	end
	return items[1]
end


sgs.ai_fill_skill.weifu = function(self)
	if call(self,"getOverflow")<1 then return end
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
  	for _,c in sgs.list(cards)do
		if call(self.player,"isJilei",c) then continue end
		return parse(self,"@WeifuCard="..c:getId())
	end
end

sgs.ai_skill_use_func["WeifuCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.WeifuCard = 2.4
sgs.ai_use_priority.WeifuCard = 1.8

sgs.ai_skill_playerchosen.kuansai = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target) and call(self,"isWeak")
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_choice.kuansai = function(self,choices,data)
	local items = choices:split("+")
	local to = call(data,"toPlayer")
	if call(self,"isFriend",to) and call(to,"isWounded") then
		return items[2]
	end
	return items[1]
end

sgs.ai_skill_playerchosen.lianju = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target) and call(self,"canDraw")
		then return target end
	end
end

sgs.ai_skill_askforag.changxin = function(self,card_ids)
    local damage = tag(self,"changxinDamage","Damage","owner")
	if #card_ids>2 then
		memory(self,"changxin_damage",damage.damage,true)
	end
	for _,id in sgs.list(card_ids)do
		if face(self,id):getSuit()==2 then
			if memory(self,"changxin_damage")<1 or call(self,"canDamageHp",damage.from,damage.card) then
				continue
			else
				memory(self,"changxin_damage",memory(self,"changxin_damage")-1,true)
			end
		end
		return id
	end
	return -1
end

sgs.ai_skill_invoke.runwei = function(self,data)
	local to = call(data,"toPlayer")
	local n = call(self,"getOverflow",to)
	if call(self,"isFriend",to) then
		return call(self,"canDraw",to) and n<0 or n>1
	end
	return n<2
end

sgs.ai_skill_choice.runwei = function(self,choices,data)
	local items = choices:split("+")
	local to = call(data,"toPlayer")
	if call(self,"isFriend",to) then
		if call(self,"getOverflow",to)<0 then
			return items[1]
		end
	end
	return items[2]
end

function sgs.ai_cardsview.zhongshen(self,class_name,player)
  	for _,c in sgs.list(call(player,"getCards","he"))do
		if call(c,"isRed") and call(c,"hasTip","zhongshen_lun",false) then
			return material_proposal(c,"jink","zhongshen")
		end
	end
end

sgs.ai_skill_invoke.qingzhe = function(self,data)
	return true
end

sgs.ai_skill_use["@@qingzhe"] = function(self,prompt)
	local cards = {}
	for _,id in sgs.list(tag(self,"qingzheForAI","IntList","owner"))do
		table.insert(cards,face(self,id))
	end
	cards = call(self,"sortByUseValue",cards)
	for _,c in sgs.list(cards)do
		if call(c,"isAvailable",self.player) then
			local d = call(self,"aiUseCard",c)
			if d.card then
				if call(c,"canRecast") and d.to:length()<1 then continue end
				local valid = {}
				for _,to in sgs.list(d.to)do
					table.insert(valid,call(to,"objectName"))
				end
				return answer(self,c,valid)
			end
		end
	end
end

sgs.ai_fill_skill.olyicheng = function(self)
	return parse(self,"@olYichengCard=.")
end

sgs.ai_skill_use_func["olYichengCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.olYichengCard = 4.4
sgs.ai_use_priority.olYichengCard = 8.8

sgs.ai_skill_use["@@olyicheng"] = function(self,prompt)
	local cards = {}
	for _,id in sgs.list(tag(self,"olyichengForAI","IntList","owner"))do
		table.insert(cards,face(self,id))
	end
	local valid = {}
	cards = call(self,"sortByUseValue",cards)
	local hs = call(self,"sortByUseValue",call(self.player,"getHandcards"),true)
	for _,c in sgs.list(cards)do
		for _,h in sgs.list(hs)do
			if table.contains(valid,call(h,"getId")) then continue end
			if call(self,"getUseValue",c)>call(self,"getUseValue",h) and call(c,"isAvailable",self.player) then
				table.insert(valid,call(c,"getId"))
				table.insert(valid,call(h,"getId"))
				break
			end
		end
	end
	if #valid>1 then
		return response(self,"@olYicheng2Card="..table.concat(valid,"+"))
	end
end

sgs.ai_fill_skill.chanshuang = function(self)
	return parse(self,"@ChanshuangCard=.")
end

sgs.ai_skill_use_func["ChanshuangCard"] = function(card,use,self)
	call(self,"sort",self.friends_noself,nil,true)
    for _,p in sgs.list(self.friends_noself)do
		if call(self,"canDraw",p) or getCardsNum("Slash",p,self.player)>0 then
			use.card = card
			use.to:append(p)
			return
		end
	end
    for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
		if not call(self,"isEnemy",p) and (call(self,"canDraw",p) or getCardsNum("Slash",p,self.player)>0) then
			use.card = card
			use.to:append(p)
			return
		end
	end
    for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
		if not(call(self,"canDraw",p) or getCardsNum("Slash",p,self.player)>0) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.ChanshuangCard = 4.4
sgs.ai_use_priority.ChanshuangCard = 4.8

sgs.ai_skill_choice.chanshuang = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"chanshuang2") then
		for _,s in sgs.list(call(self,"getCards","Slash"))do
			if call(self,"aiUseCard",s).card then
				return "chanshuang2"
			end
		end
	end
	if table.contains(items,"chanshuang1") then
		return "chanshuang1"
	end
	return items[1]
end

sgs.ai_fill_skill.xuanzhu = function(self)
	local n = call(self.player,"getChangeSkillState","xuanzhu")
	if n==1 then
		for _,pn in sgs.list(known(self.world.strategy_facts.pattern_names,"pattern_names"))do
			local dc = self:evaluateXuanzhuSource(pn)
			if dc:getTypeId()==1 and call(dc,"isAvailable",self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					call(self,"rememberActualXuanzhuUse",d)
					return call(self,"evaluateXuanzhuFirst")
				end
			end
		end
	else
		for _,pn in sgs.list(known(self.world.strategy_facts.pattern_names,"pattern_names"))do
			local dc = self:evaluateXuanzhuSource(pn)
			if dc:getTypeId()==2 and call(dc,"isKindOf","SingleTargetTrick") and call(dc,"isAvailable",self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					if call(dc,"canRecast") and d.to:length()<1 then continue end
					call(self,"rememberActualXuanzhuUse",d)
					return call(self,"evaluateXuanzhuFirst")
				end
			end
		end
	end
end

sgs.ai_skill_use_func["Xuanzhu2Card"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.Xuanzhu2Card = 4.4
sgs.ai_use_priority.Xuanzhu2Card = 4.8

sgs.ai_skill_use["@@xuanzhu"] = function(self,prompt)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByUseValue",cards,true)
	local d = self:readActualXuanzhuUse(#cards>0)
	local valid = {}
	for _,p in sgs.list(d.to)do
		table.insert(valid,call(p,"objectName"))
	end
	for i,c in sgs.list(cards)do
		if i<=#cards/2 and call(c,"getTypeId")==3 then
			return call(self,"materializeXuanzhuSaved",c:getId(),d.card:objectName(),valid)
		end
	end
	for _,c in sgs.list(cards)do
		return call(self,"materializeXuanzhuSaved",c:getId(),d.card:objectName(),valid)
	end
end

sgs.ai_guhuo_card.xuanzhu = function(self,toname,class_name)
	if call(self,"getCardsNum",class_name)>0 then return end
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
	for i,c in sgs.list(cards)do
		if i<=#cards/2 and call(c,"getTypeId")==3 then
			return proposal(self,"@XuanzhuCard="..c:getId()..":"..toname)
		end
	end
	for _,c in sgs.list(cards)do
		return proposal(self,"@XuanzhuCard="..c:getId()..":"..toname)
	end
end

sgs.ai_fill_skill.qushi = function(self)
	return parse(self,"@QushiCard=.")
end

sgs.ai_skill_use_func["QushiCard"] = function(card,use,self)
	local tos = sgs.QList2Table(call(self.room,"getOtherPlayers",self.player))
	call(self,"sort",tos,nil,true)
    for i,p in sgs.list(tos)do
		if i<=#tos/2 and call(p,"getPile","qu_shi"):length()<1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
    for _,p in sgs.list(tos)do
		if call(p,"getPile","qu_shi"):length()<1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.QushiCard = 4.4
sgs.ai_use_priority.QushiCard = 5.8

sgs.ai_guhuo_card.weijie = function(self,toname)
	save_choice(self,"weijie",nil)
    for _,p in sgs.list(call(self.room,"getAlivePlayers"))do
		if not call(self,"isFriend",p) and call(self.player,"distanceTo",p)==1 then
			for _,c in sgs.list(getKnownCards(p,self.player))do
				if call(c,"getTypeId")==1 then
					save_player(self,"weijieTo",p)
					save_choice(self,"weijie",call(c,"objectName"))
					return proposal(self,"@WeijieCard=.:"..toname)
				end
			end
		end
	end
    for _,p in sgs.list(call(self.room,"getAlivePlayers"))do
		if call(self,"isWeak") and call(self.player,"distanceTo",p)==1 then
			for _,c in sgs.list(getKnownCards(p,self.player))do
				if call(c,"getTypeId")==1 then
					save_player(self,"weijieTo",p)
					save_choice(self,"weijie",call(c,"objectName"))
					return proposal(self,"@WeijieCard=.:"..toname)
				end
			end
		end
	end
    for _,p in sgs.list(call(self.room,"getAlivePlayers"))do
		if call(self,"isEnemy",p) and call(self.player,"distanceTo",p)==1 and call(self,"doDisCard",p,"h") then
			return proposal(self,"@WeijieCard=.:"..toname)
		end
	end
end

sgs.ai_skill_playerchosen.weijie = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
    for _,target in sgs.list(destlist)do
		if saved_player(self,"weijieTo")==target
		then return target end
	end
	call(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if not call(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.shilu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if not call(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_fill_skill.miuyan = function(self,inclusive,request)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
	for _,c in sgs.list(cards)do
		if call(c,"isBlack") then
			local dc = call(self,"evaluateTurnConversion","miuyan","FireAttack",{name="fire_attack",skill="miuyan",suit=6,number=0,subcards={call(c,"getEffectiveId")}},request)
			if call(dc,"isAvailable",self.player) then
				return dc
			end
		end
	end
end

sgs.ai_skill_playerschosen.gongjie = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and call(self,"isFriend",p)
		and call(self,"canDraw",p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_invoke.xiangxu = function(self,data)
	local to = call(self.room,"getCurrent")
	local n = call(to,"getHandcardNum")-call(self.player,"getHandcardNum")
	if n>0 then
		return call(self,"canDraw")
	else
		return n==-2 and call(self,"isWeak")
	end
end

sgs.ai_skill_askforyiji.xiangzuo = function(self,card_ids,tos)
	if call(self,"getAllPeachNum")+call(self.player,"getHp")>0
	then return nil,-1 end
	local destlist = sgs.QList2Table(tos) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if call(self,"isFriend",p) and call(self,"canDraw",p)
		and call(self.player,"getMark","gongjie"..p:objectName())>0
		and call(self.player,"getMark","xiangxu"..p:objectName())>0 then
			return p,card_ids[1]
		end
	end
	local p,id = nested(self,"ai_skill_askforyiji","nosyiji",self,card_ids,tos)
	if p and p~=self.player then
		return p,id
	end
end

sgs.ai_skill_playerchosen.jieyan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	if call(self.room,"getCurrent"):getPhase()==sgs.Player_Discard then
		for _,p in sgs.list(destlist)do
			if call(self,"isFriend",p) and call(self,"canDraw",p)
			then return p end
		end
		for _,p in sgs.list(destlist)do
			if call(self,"isFriend",p)
			then return p end
		end
		for _,p in sgs.list(destlist)do
			if not call(self,"isEnemy",p)
			then return p end
		end
	end
    for _,p in sgs.list(destlist)do
		if call(self,"isEnemy",p) and call(self,"damageIsEffective",p,"N")
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if call(self,"isEnemy",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not call(self,"isFriend",p)
		then return p end
	end
end

sgs.ai_skill_choice.jieyan = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"jieyan2") and call(self,"isWeak") then
		return "jieyan2"
	end
	return items[1]
end

sgs.ai_skill_invoke.jinghua = function(self,data)
	return #self.enemies>=#self.friends_noself
end

sgs.ai_skill_invoke.shuiyue = function(self,data)
	return #self.enemies>=#self.friends_noself
end

sgs.ai_fill_skill.pingduan = function(self)
	return parse(self,"@PingduanCard=.")
end

sgs.ai_skill_use_func["PingduanCard"] = function(card,use,self)
	local tos = sgs.QList2Table(call(self.room,"getAlivePlayers"))
	call(self,"sort",tos,nil,true)
    for _,p in sgs.list(tos)do
		if call(self,"isFriend",p) and call(p,"hasEquip") then
			use.card = card
			use.to:append(p)
			return
		end
	end
    for _,p in sgs.list(tos)do
		if call(self,"isFriend",p) and call(p,"getCardCount")>2 then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.PingduanCard = 4.4
sgs.ai_use_priority.PingduanCard = 5.8

sgs.ai_skill_cardask["pingduan2"] = function(self,data,pattern,prompt)
    return true
end

sgs.ai_skill_invoke.pingduan = function(self,data)
	local to = call(data,"toString"):split(":")[2]
	to = BeMan(self.room,to)
	return to and not call(self,"isEnemy",to)
end

sgs.ai_skill_choice.fuchao = function(self,choices,data)
 data=fuchao_data(self,data)
	local items = choices:split("+")
	local use = call(data,"toCardUse")
	local from,tocard
	if use and use.card then
		from = use.who
		tocard = use.whocard
	else
		use = call(data,"toCardResponse")
		from = use.m_who
		tocard = use.m_toCard
	end
	use = historical_use(self,tocard)
	if table.contains(items,"fuchao1") then
		local n=0
		for _,p in sgs.list(self.friends_noself)do
			if use.to:contains(p) and call(self,"playerGetRound",p)>call(self,"playerGetRound",self.player)
			then n=n-1 end
		end
		for _,p in sgs.list(self.enemies)do
			if use.to:contains(p) and call(self,"playerGetRound",p)>call(self,"playerGetRound",self.player)
			then n=n+1 end
		end
		if n>=0 then
			return "fuchao1"
		end
	end
	if table.contains(items,"fuchao2") then
		local n=0
		for _,p in sgs.list(self.friends_noself)do
			if use.to:contains(p) and call(self,"playerGetRound",p)>call(self,"playerGetRound",self.player)
			then n=n-1 end
		end
		for _,p in sgs.list(self.enemies)do
			if use.to:contains(p) and call(self,"playerGetRound",p)>call(self,"playerGetRound",self.player)
			then n=n+1 end
		end
		if n<0 and not call(self,"isWeak") then
			return "fuchao2"
		end
	end
	return items[1]
end

sgs.ai_skill_choice.leiluan = function(self,choices,data)
	local items = choices:split("+")
	for _,pc in sgs.list(items)do
		local dc = self:evaluateLeiluanCard(pc)
		if dc==nil then error("attempt to index a nil value (local dc)",0)end
		if call(dc,"isAvailable",self.player) then
			local d = call(self,"aiUseCard",dc)
			if d.card then
				if call(dc,"canRecast") and d.to:length()<1
				then continue end
				call(self,"rememberLeiluanUse",d.card,d.to,pc,d)
				return pc
			end
		end
	end
end

sgs.ai_skill_use["@@leiluan"] = function(self,prompt)
 return call(self,"materializeLeiluanUse")
end

sgs.ai_fill_skill.leiluan = function(self)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
	local ids = {}
	local n = call(self.player,"getMark","&leiluan")
	n = math.max(1,n)
	for _,c in sgs.list(cards)do
		if #ids<n then
			table.insert(ids,call(c,"getId"))
		end
	end
	if #ids<n or #ids>2 then return end
	for _,pc in sgs.list(known(self.world.strategy_facts.pattern_names,"pattern_names"))do
		if call(self.player,"getMark","leiluan_guhuo_remove_"..pc.."_lun")<1 then
			local dc = evaluation(self,pc)
			if call(dc,"getTypeId")~=1
			or call(self,"getCardsNum",call(dc,"getClassName"))>0
			then continue end
			dc=named(self,"leiluan",pc,ids)
			if call(dc,"isAvailable",self.player) and call(self,"aiUseCard",dc).card then
				return dc
			end
		end
	end
end

sgs.ai_guhuo_card.leiluan = function(self,toname,class_name)
	if call(self.player,"getMark","leiluan_guhuo_remove_"..toname.."_lun")>0
	or call(self,"getCardsNum",class_name)>0 then return end
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
	local ids = {}
	local n = call(self.player,"getMark","&leiluan")
	n = math.max(1,n)
	for _,c in sgs.list(cards)do
		if #ids<n then
			table.insert(ids,call(c,"getId"))
		end
	end
	if #ids<n or #ids>2 then return end
	local dc = named(self,"leiluan",toname,ids)
	return descriptor(dc)
end

sgs.ai_fill_skill.renxian = function(self)
	local ids,ids2 = {},{}
  	for _,h in sgs.list(call(self.player,"getHandcards"))do
		if call(h,"isDamageCard") then
			table.insert(ids,call(h,"getId"))
			if not call(self.player,"isJilei",h) then
				table.insert(ids2,call(h,"getId"))
			end
		end
	end
	sgs.ai_use_priority.RenxianCard = 2.2
	if #ids==2 and #ids==#ids2 then
		sgs.ai_use_priority.RenxianCard = 11.2
		return parse(self,"@RenxianCard="..table.concat(ids2,"+"))
	elseif #ids<1 then
		sgs.ai_use_priority.RenxianCard = 11.2
		return parse(self,"@RenxianCard=.")
	else
		return parse(self,"@RenxianCard=.")
	end
end

sgs.ai_skill_use_func["RenxianCard"] = function(card,use,self)
  	use.card = card
end

sgs.ai_use_value.RenxianCard = 5.4
sgs.ai_use_priority.RenxianCard = 2.2

sgs.ai_fill_skill.yanliangvs = function(self)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
	for i,c in sgs.list(cards)do
		if i<=#cards/2 and call(c,"isKindOf","EquipCard") then
			if call(self,"aiUseCard",evaluation(self,"analeptic")).card then
				return parse(self,"@YanliangCard="..c:getId())
			end
		end
	end
end

sgs.ai_skill_use_func["YanliangCard"] = function(card,use,self)
	for i,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
		if call(p,"hasSkill","yanliang") and not call(self,"isEnemy",p) then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.YanliangCard = 5.4
sgs.ai_use_priority.YanliangCard = 3.2

sgs.ai_skill_playerchosen.xiaoshi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local use = tag(self,"xiaoshiUse","CardUse","owner")
	if call(use.card,"isDamageCard") then
		for _,p in sgs.list(destlist)do
			if call(self,"isEnemy",p) and call(self,"isWeak",p)
			and call(self,"hasTrickEffective",use.card,p,use.from)
			then return p end
		end
		for _,p in sgs.list(destlist)do
			if call(self,"isFriend",p)
			and (not call(self,"isWeak",p) or not call(self,"hasTrickEffective",use.card,p,use.from))
			then return p end
		end
		for _,p in sgs.list(destlist)do
			if not call(self,"isFriend",p) then return p end
		end
	else
		for _,p in sgs.list(destlist)do
			if call(self,"isFriend",p) and not call(self,"hasTrickEffective",use.card,p,use.from)
			then return p end
		end
		for _,p in sgs.list(destlist)do
			if call(self,"isFriend",p)
			then return p end
		end
	end
end

sgs.ai_skill_playerchosen.xiaoshi1 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	for _,p in sgs.list(destlist)do
		if call(self,"isFriend",p)
		then return p end
	end
	for _,p in sgs.list(destlist)do
		if not call(self,"isEnemy",p)
		then return p end
	end
end

sgs.ai_skill_invoke.jinming = function(self,data)
	return call(self,"canDraw")
end

sgs.ai_skill_invoke.olmouhulie = function(self,data)
	local use = call(data,"toCardUse")
	return not call(self,"isFriend",use.to:at(0))
end

sgs.ai_skill_playerchosen.olmouhulie = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	for _,p in sgs.list(destlist)do
		if not call(self,"isWeak") and call(self,"getCardsNum","Jink")<1
		then return p end
	end
end

sgs.ai_skill_playerchosen.olmouyipo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local x = math.max(1, call(self.player,"getLostHp"))
	for _,p in sgs.list(destlist)do
		if call(self,"isEnemy",p) and call(p,"getCardCount")/2<x
		then return p end
	end
	for _,p in sgs.list(destlist)do
		if call(self,"isFriend",p) and call(self,"canDraw",p)
		then return p end
	end
end

sgs.ai_skill_choice.olmouyipo = function(self,choices,data)
	local items = choices:split("+")
	local to = call(data,"toPlayer")
	if call(self,"isFriend",to) then
		return items[1]
	else
		return items[2]
	end
end

sgs.ai_fill_skill.huiyun = function(self,inclusive,request)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
	for i,c in sgs.list(cards)do
		local dc = call(self,"evaluateTurnConversion","huiyun","FireAttack",{name="fire_attack",skill="huiyun",suit=6,number=0,subcards={call(c,"getEffectiveId")}},request)
		if call(dc,"isAvailable",self.player) then
			return dc
		end
	end
end

sgs.ai_skill_choice.huiyun = function(self,choices,data)
	local items = choices:split("+")
	local to = call(data,"toPlayer")
	if call(self,"isFriend",to) then
		return items[#items]
	else
		return items[1]
	end
end

sgs.ai_skill_invoke.chuyuan = function(self,data)
	local player = call(data,"toPlayer")
	if call(self.player,"getPile","cychu"):length()==2 then
		if call(self.player,"hasSkill","dengji") and call(self.player,"getMark","dengji")<=0 then return call(self.player,"getMaxHp")>1 end
		if call(self.player,"hasSkill","tianxing") and call(self.player,"getMark","tianxing")<=0 then return call(self.player,"getMaxHp")>1 end
	end
	if not call(self,"doDisCard",player,"h",true) then return false end
	return true
end

sgs.ai_skill_discard.chuyuan = function(self,discard_num,min_num,optional,include_equip)
	local cards = sgs.QList2Table(call(self.player,"getCards","h"))
	call(self,"sortByKeepValue",cards)
	return {cards[1]:getEffectiveId()}
end

sgs.ai_skill_choice.tianxing = function(self,choices,data)  --待补充
	local skills = choices:split("+")
	local skills2 = {}
	if table.contains(skills,"tenyearzhiheng") then table.insert(skills2,"tenyearzhiheng") end
	if table.contains(skills,"olluanji") then table.insert(skills2,"olluanji") end
	if #self.friends_noself<=0 and #skills2>0 then
		return skills2[math.random(1,#skills2)]
	end
	return skills[math.random(1,#skills)]
end

sgs.ai_skill_playerchosen.shenfu_ji = function(self,targets)
	local targets_table = call(self,"findPlayerToDamage",1,self.player,"T",targets)
	if #targets_table<=0 then return nil end
	if not call(self.player,"isChained") or not call(self,"isWeak") or not call(self,"damageIsEffective",self.player,sgs.DamageStruct_Thunder,self.player) then return targets_table[1] end
	for _,p in sgs.list(targets_table)do
		if call(p,"isChained") then continue end
		return p
	end
	return nil
end

sgs.ai_skill_playerchosen.shenfu_ou = function(self,targets)
	local targets_table1,targets_table2 = {},{}
	for _,target in sgs.list(targets)do
		if math.abs(call(target,"getHandcardNum")-call(target,"getHp"))==1 then
			table.insert(targets_table1,target)
		else
			if call(self,"isFriend",target) or (call(self,"isEnemy",target) and not call(target,"isKongcheng")) or (call(self,"isEnemy",target) and call(self,"needKongcheng",target,true)) then
				table.insert(targets_table2,target)
			end
		end
	end
	if #targets_table1>0 then
		call(self,"sort",targets_table1,"defense")
		return targets_table1[1]
	end
	if #targets_table2>0 then
		call(self,"sort",targets_table2,"defense")
		return targets_table2[1]
	end
	return nil
end

sgs.ai_skill_choice.shenfu = function(self,choices,data)
	local player = call(data,"toPlayer")
	if call(self,"isFriend",player) then
		if hasTuntianEffect(player) and call(player,"getHandcardNum")-call(player,"getHp")==1 then
			return "discard"
		end
		return "draw"
	end
	if call(self,"needKongcheng",player,true) then return "draw" end
	return "discard"
end


sgs.ai_skill_cardask["tianhou0"] = function(self,data)
	local js = call(self.player,"getCards","j")
	local handcards = call(self.player,"getCards","h")
	handcards = call(self,"sortByKeepValue",handcards) -- 按保留值排序
	if js:length()>0 then
		local jt = judge_reason(self,js:last():objectName())
		if type(jt)~="table" then
			if type(jt)=="string" then
				jt = {jt,true}
			else
				jt = {source_global_jc(self):getSuitString(),true}
			end
		end
		if jt then
			for _,h in sgs.list(handcards)do
				if matches(self,jt[1],self.player,h)==jt[2]
				then return h:getLegacyStringKey() end
			end
		end
	end
	local tc = face(self,call(data,"toInt"))
	for _,h in sgs.list(handcards)do
		if call(self,"getUseValue",tc)>call(self,"getUseValue",h)
		then return h:getLegacyStringKey() end
	end
	js = call(self,"poisonCards","h")
	if #js>0 then
		return js[1]:getLegacyStringKey()
	end
    return "."
end


sgs.ai_skill_playerchosen.tianhou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if call(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_discard.chenshuo = function(self,discard_num,min_num,optional,include_equip)
	local cards = sgs.QList2Table(call(self.player,"getCards","h"))
	return {cards[math.random(1,#cards)]:getEffectiveId()}
end


sgs.ai_skill_playerchosen.olfengyao = function(self,players)
    for _,p in sgs.list(players)do
		if not call(self,"isFriend",p)
		then return p end
	end
end

sgs.ai_skill_playerchosen.kuangxiang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if call(self,"isFriend",p) and call(self,"isWeak",p) and call(p,"getHandcardNum")<3
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if call(self,"isEnemy",p) and call(p,"getHandcardNum")>5
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if call(self,"isFriend",p) and call(p,"getHandcardNum")<3
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if call(self,"isEnemy",p) and call(p,"getHandcardNum")>4
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not call(self,"isEnemy",p) and call(p,"getHandcardNum")<4
		then return p end
	end
end

sgs.ai_fill_skill.zonglve = function(self,inclusive,request)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
	for i,c in sgs.list(cards)do
		local dc = call(self,"evaluateTurnConversion","zonglve","Slash",{name="slash",skill="zonglve",suit=6,number=0,subcards={call(c,"getEffectiveId")}},request)
		if call(dc,"isAvailable",self.player) then
			return dc
		end
	end
end

sgs.ai_skill_invoke.zonglve = function(self,data)
	local to = call(data,"toPlayer")
	return call(self,"doDisCard",to,"hej",true)
end

sgs.ai_fill_skill.shuzi = function(self)
	local ids = {}
	local cards = call(self.player,"getCards","h")
	cards = call(self,"sortByKeepValue",cards)
	local tp
  	for _,h in sgs.list(cards)do
		local c,p = call(self,"getCardNeedPlayer",{h},false)
		if c and p then
			if tp==p then
				table.insert(ids,call(h,"getId"))
				if #ids==2 then
					save_player(self,"shuzi_to",p)
					return parse(self,"@ShuziCard="..table.concat(ids,"+"))
				end
			else
				ids = {call(h,"getId")}
				tp = p
			end
		end
	end
end

sgs.ai_skill_use_func["ShuziCard"] = function(card,use,self)
  	if saved_player(self,"shuzi_to") then
		use.card = card
		use.to:append(saved_player(self,"shuzi_to"))
	end
end

sgs.ai_use_value.ShuziCard = 5.4
sgs.ai_use_priority.ShuziCard = 1.2

sgs.ai_skill_playerchosen.shuzi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
	local isf = call(self,"isFriend",saved_player(self,"shuzi_to"))
	if not isf and call(self,"damageIsEffective",saved_player(self,"shuzi_to"),"N") then
		return saved_player(self,"shuzi_to")
	end	
    for _,p in sgs.list(destlist)do
		if isf and call(self,"isEnemy",p) and #call(self,"poisonCards","e",p)<call(p,"getEquips"):length()
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not isf and call(self,"isFriend",p) and #call(self,"poisonCards","ej",p)>0
		then return p end
	end
end

sgs.ai_skill_invoke.xianying = function(self,data)
	return call(self,"canDraw")
end

sgs.ai_skill_use["@@xianying0!"] = function(self,prompt)
	local mt = ""
	for _,m in sgs.list(call(self.player,"getMarkNames"))do
		if m:startsWith("&xianying+:+") and call(self.player,"getMark",m)>0
		then mt = m end
	end
	local valid = {}
    local cards = call(self.player,"getCards","he")
    cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
    	table.insert(valid,call(h,"getEffectiveId"))
		if not mt:contains(tostring(#valid)) then break end
	end
	if #valid<1 then return end
	return response(self,"@XianyingCard="..table.concat(valid,"+"))
end

sgs.ai_skill_use["@@xianying1"] = function(self,prompt)
    local c = property(self,self.player,"xianyingName")
	c = named(self,"_xianying",c,{})
    local dummy = call(self,"aiUseCard",c)
   	if dummy.card then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,call(p,"objectName"))
       	end
		if call(c,"canRecast") and #tos<1 then return end
       	return answer(self,c,tos)
    end
end

sgs.ai_fill_skill.olliyong = function(self)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
  	for _,h in sgs.list(cards)do
		if call(self.player,"getChangeSkillState","olliyong")==1 then
			local mt = ""
			for _,m in sgs.list(call(self.player,"getMarkNames"))do
				if m:startsWith("&olliyong+") and m:endsWith("-Clear")
				and call(self.player,"getMark",m)>0 then mt = m end
			end
			if mt:contains(call(h,"getSuitString")) then continue end
			local dc = named(self,"olliyong","duel",{call(h,"getEffectiveId")})
			if call(dc,"isAvailable",self.player) then
				local d = call(self,"aiUseCard",dc)
				if d.card then
					save_targets(self,"olliyong_to",d.to)
					sgs.ai_use_priority.OLLiyongCard = sgs.ai_use_priority.Duel
					return parse(self,"@OLLiyongCard="..h:getId())
				end
			end
		else
			if call(self.player,"isJilei",h) then continue end
			for _,p in sgs.list(self.enemies)do
				if getCardsNum("Slash",p,self.player)<call(self,"getCardsNum","Slash")
				and evaluation(self,"duel"):isAvailable(p) then
					save_targets(self,"olliyong_to",sgs.SPlayerList())
					save_targets(self,"olliyong_to",{p})
					sgs.ai_use_priority.OLLiyongCard = 1.2
					return parse(self,"@OLLiyongCard="..h:getId())
				end
			end
		end
	end
end

sgs.ai_skill_use_func["OLLiyongCard"] = function(card,use,self)
  	if targets(self,"olliyong_to") then
		use.card = card
		use.to = targets(self,"olliyong_to")
	end
end

sgs.ai_use_value.OLLiyongCard = 5.4
sgs.ai_use_priority.OLLiyongCard = 1.2

sgs.ai_fill_skill.bojue = function(self)
	return parse(self,"@BojueCard=.")
end

sgs.ai_skill_use_func["BojueCard"] = function(card,use,self)
	call(self,"sort",self.enemies)
	for _,p in sgs.list(self.enemies)do
		if call(p,"getHandcardNum")>0 then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.BojueCard = 5.4
sgs.ai_use_priority.BojueCard = 1.2

sgs.ai_skill_cardask["xiongni0"] = function(self,data,pattern)
	if #self.enemies>#self.friends/2 then return true end
    return "."
end

sgs.ai_skill_cardask["xiongni1"] = function(self,data,pattern)
	local from = call(data,"toPlayer")
	if call(self,"canDamageHp",from) and not call(self,"isWeak") then return "." end
    return true
end

sgs.ai_fill_skill.fengshang = function(self)
	return parse(self,"@FengshangCard=.")
end

sgs.ai_skill_use_func["FengshangCard"] = function(card,use,self)
	if select_fengshang(self,"") then
		use.card = card
	end
end

sgs.ai_use_value.FengshangCard = 5.4
sgs.ai_use_priority.FengshangCard = 9.2

select_fengshang = function(self,prompt)
	local sn = {}
	local ids = {}
	local sus = {}
	for _,id in sgs.list(call(self.room,"getDiscardPile"))do
		local c = face(self,id)
		if call(self.player,"getMark",id.."fengshangId-Clear")>0
		and call(self.player,"getMark",call(c,"getSuitString").."fengshang_lun")<1 then
			local h,p = call(self,"getCardNeedPlayer",{c},true)
			sus[call(c,"getSuitString")] = sus[call(c,"getSuitString")] or {}
			table.insert(sus[call(c,"getSuitString")],c:getLegacyStringKey())
			if h==c and p then
				sn[c:getLegacyStringKey()] = call(p,"objectName")
			elseif #call(self,"poisonCards",{c})<1 then
				table.insert(ids,c)
			end
		end
	end
	for s,cs in pairs(sus)do
		if #cs>1 then
			local valid,tos = {},{}
			for _,c in ipairs(cs)do
				if sn[c] and not table.contains(tos,sn[c]) then
					table.insert(valid,c)
					table.insert(tos,sn[c])
					if #valid>=2 then
						return "@FengshangCard="..table.concat(valid,"+").."->"..table.concat(tos,"+")
					end
				end
			end
		end
	end
	call(self,"sortByKeepValue",ids,true)
	call(self,"sort",self.friends)
	for s,cs in pairs(sus)do
		if #cs>1 then
			local valid,tos = {},{}
			for _,c in ipairs(ids)do
				if call(c,"getSuitString")==s and #valid<2 then
					table.insert(valid,call(c,"getId"))
				end
			end
			if #valid<2 then continue end
			for _,p in sgs.list(self.friends)do
				if call(self,"canDraw",p) then
					table.insert(tos,call(p,"objectName"))
					if #tos>=2 then
						return "@FengshangCard="..table.concat(valid,"+").."->"..table.concat(tos,"+")
					end
				end
			end
		end
	end
	local aps = call(self,"sort",call(self.room,"getAlivePlayers"))
	for s,cs in pairs(sus)do
		if #cs>1 then
			local valid,tos = {},{}
			for _,c in ipairs(ids)do
				if call(c,"getSuitString")==s and #valid<2 then
					table.insert(valid,call(c,"getId"))
				end
			end
			if #valid<2 then continue end
			for _,p in sgs.list(aps)do
				if call(self,"canDraw",p) and not call(self,"isEnemy",p) then
					table.insert(tos,call(p,"objectName"))
					if #tos>=2 then
						return "@FengshangCard="..table.concat(valid,"+").."->"..table.concat(tos,"+")
					end
				end
			end
		end
	end
	for s,cs in pairs(sus)do
		if #cs>1 then
			local valid,tos = {},{}
			for _,c in ipairs(cs)do
				if #call(self,"poisonCards",{tonumber(c)})<1 then
					for _,p in sgs.list(aps)do
						if table.contains(tos,call(p,"objectName")) then continue end
						if call(self,"canDraw",p) and not call(self,"isEnemy",p) then
							table.insert(tos,call(p,"objectName"))
							table.insert(valid,c)
							break
						end
					end
				else
					for _,p in sgs.list(aps)do
						if table.contains(tos,call(p,"objectName")) then continue end
						if call(self,"isEnemy",p) then
							table.insert(tos,call(p,"objectName"))
							table.insert(valid,c)
							break
						end
					end
				end
				if #tos>=2 then
					return "@FengshangCard="..table.concat(valid,"+").."->"..table.concat(tos,"+")
				end
			end
		end
	end
end

sgs.ai_skill_use["@@jigu"] = function(self,prompt)
	local valid,ts = {},{}
	for _,id in sgs.list(call(self.player,"getPile","ji_gu"))do
		table.insert(ts,face(self,id))
	end
    local cards = call(self.player,"getCards","h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c in sgs.list(ts)do
		for _,h in sgs.list(cards)do
			if table.contains(valid,call(h,"getId"))
			or call(self,"getKeepValue",h)>=call(self,"getKeepValue",c)
			and call(self,"getUseValue",h)>=call(self,"getUseValue",c)
			then continue end
			table.insert(valid,call(h,"getId"))
			table.insert(valid,call(c,"getId"))
			break
		end
	end
	return #valid>1
	and string.format("@JiguCard=%s",table.concat(valid,"+"))
end

local function r52_jiewan_selected(self,wire,request)
 local cls,ids,user,names=decode(wire)
 local c=call(self,"bindSkillCard","jiewan",ids,request,user,cls)
 return {kind="use_card",card_spec=call(c,"toCardSpec"),targets=names}
end
sgs.ai_skill_use["@@jiewan"] = function(self,prompt,method,pattern,request)
	local tos,ts = {},{}
	for _,id in sgs.list(call(self.player,"getPile","ji_gu"))do
		table.insert(ts,id)
	end
    local cards = call(self.player,"getCards","h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		local dc = named(self,"jiewan","snatch",{call(h,"getEffectiveId")})
		if call(dc,"isAvailable",self.player) then
			local ids = {call(h,"getId")}
			if #ts>1 then
				table.insert(ids,ts[1])
				table.insert(ids,ts[2])
			elseif call(self.player,"getLostHp")<1 then
				break
			end
			local d = call(self,"aiUseCard",dc)
			if d.card then
				if d.to:length()<1 then return r52_jiewan_selected(self,"@JiewanCard="..table.concat(ids,"+"),request) end
				for _,p in sgs.list(d.to)do
					table.insert(tos,call(p,"objectName"))
				end
				return r52_jiewan_selected(self,"@JiewanCard="..table.concat(ids,"+").."->"..table.concat(tos,"+"),request)
			end
		end
	end
end

sgs.ai_fill_skill.olspxixiang = function(self,inclusive,request)
    local cards = call(self.player,"getCards","he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	local ids = {}
	for _,c in sgs.list(cards)do
		if table.contains(self.toUse,c)
		or call(self,"getKeepValue",c)>6 then continue end
		table.insert(ids,call(c,"getId"))
		if #ids>1 then return call(self,"evaluateTurnSkillCard","olspxixiang","#olspxixiangCard",ids,request,"") end
	end
end

sgs.ai_skill_use_func["#olspxixiangCard"] = function(card,use,self)
    local scope=call(self,"getFillSkillContext","olspxixiang")
    local request=known(scope.request,"olspxixiang.current_request")
    if call(self,"readonlyTurnConversionMatchesRequest",card,request)~=true then
        ai_unsupported("Olspxixiang source seed belongs to another action","olspxixiang")
    end
	for i=1,3 do
		local cs = {"slash","duel"}
		local dc = named(self,"olspxixiang",cs[math.random(1,2)],call(card,"getSubcards"))
		if call(self.player,"getMark","olspxixiang_juguan_remove_"..dc:objectName().."-PlayClear")<1
		and call(dc,"isAvailable",self.player) then
			local d = call(self,"aiUseCard",dc)
			if d.card then
				use.card = call(self,"evaluateTurnSkillCard","olspxixiang","#olspxixiangCard",sgs.QList2Table(call(card,"getSubcards")),request,dc:objectName())
				use.to = d.to
				break
			end
		end
	end
end

sgs.ai_use_value.olspxixiangCard = 3.4
sgs.ai_use_priority.olspxixiangCard = 2.2

sgs.ai_fill_skill.olspzhubei = function(self)
    return not call(self,"isWeak")
	and parse(self,"#olspzhubeiCard:.:")
end

sgs.ai_skill_use_func["#olspzhubeiCard"] = function(card,use,self)
	call(self,"sort",self.enemies)
	for _,p in sgs.list(self.enemies)do
		if call(p,"getCardCount")>0 then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.olspzhubeiCard = 3.4
sgs.ai_use_priority.olspzhubeiCard = 2.2

sgs.ai_skill_invoke.olspzhubei = function(self,data)
	local damage = call(data,"toDamage")
	if damage.to then
		return call(self,"canDraw")
	end
	local to = call(data,"toPlayer")
	return call(self.player,"getHandcardNum")<call(to,"getHandcardNum")
end

sgs.ai_use_revises["&keolranji_ban"] = function(self,card,use)
	if call(card,"isKindOf","Peach") or call(card,"isKindOf","Analeptic") and call(self.player,"getHp")<1 then
		if call(self.player,"getMark","&keolranji_ban")>0 then
			return false
		end
	end
end

sgs.ai_skill_playerchosen.olmoujiaodi = function(self,players)
	return nested(self,"ai_skill_playerchosen","jincanmou",self,players)
end

sgs.ai_fill_skill.olmoubaojing = function(self)
	return parse(self,"#olmoubaojingCard:.:")
end

sgs.ai_skill_use_func["#olmoubaojingCard"] = function(card,use,self)
	call(self,"sort",self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		if call(p,"getAttackRange")>1 then
			use.card = card
			use.to:append(p)
			save_choice(self,"olmoubaojing","2")
			return
		end
	end
	call(self,"sort",self.friends_noself,nil,true)
	for _,p in sgs.list(self.friends_noself)do
		if call(p,"getAttackRange")<3 then
			use.card = card
			use.to:append(p)
			save_choice(self,"olmoubaojing","1")
			return
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		use.card = card
		use.to:append(p)
		save_choice(self,"olmoubaojing","1")
		return
	end
end

sgs.ai_use_value.olmoubaojingCard = 5.4
sgs.ai_use_priority.olmoubaojingCard = 9.2

sgs.ai_skill_invoke.SkillEffect = function(self,data)
	local st = call(data,"toString")
	if st=="s1" or st=="s5" or st=="s9" or st=="s10" or st=="s21" or st=="s22" then
		return call(self,"canDraw")
	end
	if st=="s23" then
		return call(self,"canDraw") and (not call(self.player,"faceUp") or call(self.player,"getHandcardNum")<=call(self.player,"getHp"))
	end
	if st=="s26" then
		return call(self,"canDraw") and not call(self,"isWeak")
	end
	if st=="s29" then
		local damage = tag(self,"SkillEffect","Damage","owner")
		return call(self,"isEnemy",damage.to)
	end
	if st=="s30" then
		local damage = tag(self,"SkillEffect","Damage","owner")
		return call(self,"isFriend",damage.to) and (call(self,"isWeak",damage.to) or damage.from and call(self,"isFriend",damage.from))
		or call(self,"isEnemy",damage.to) and not call(self,"isWeak",damage.to) and damage.from and call(self,"isFriend",damage.from) and call(self,"canDraw",damage.from)
	end
	return true
end

for i=0,99 do
	sgs.ai_skill_playerchosen["qingshu_tianshu"..i] = function(self,players)
		local str = tag(self,"qingshu_tianshu"..i.."SkillEffect","String","room")
		local destlist = call(self,"sort",players)
		if str=="SkillEffect2" then
			for _,p in sgs.list(destlist)do
				if call(self,"doDisCard",p,"hej")
				then return p end
			end
		end
		if str=="SkillEffect7" then
			for _,p in sgs.list(destlist)do
				if call(self,"doDisCard",p,"hej",true)
				then return p end
			end
		end
		if str=="SkillEffect11" then
			for _,p in sgs.list(sgs.reverse(destlist))do
				if call(p,"getMark","skillInvalidity")<1
				and call(self,"isEnemy",p)
				then return p end
			end
			for _,p in sgs.list(sgs.reverse(destlist))do
				if call(p,"getMark","skillInvalidity")<1
				and not call(self,"isFriend",p)
				then return p end
			end
		end
		if str=="SkillEffect12" then
			for _,p in sgs.list(destlist)do
				if not call(p,"faceUp") and call(self,"isFriend",p)
				then return p end
			end
			for _,p in sgs.list(sgs.reverse(destlist))do
				if call(p,"faceUp") and call(self,"isEnemy",p)
				then return p end
			end
			for _,p in sgs.list(sgs.reverse(destlist))do
				if call(p,"faceUp") and not call(self,"isFriend",p)
				then return p end
			end
		end
		if str=="SkillEffect14" then
			for _,p in sgs.list(destlist)do
				if call(self,"damageIsEffective",p,"T",self.player)
				and call(self,"isEnemy",p)
				then return p end
			end
			for _,p in sgs.list(sgs.reverse(destlist))do
				if call(self,"damageIsEffective",p,"T",self.player)
				and not call(self,"isFriend",p)
				then return p end
			end
		end
		if str=="SkillEffect18" then
			for _,p in sgs.list(destlist)do
				if call(self,"doDisCard",p,"he",true)
				and call(self,"isEnemy",p) and call(p,"getCardCount")>2
				then return p end
			end
		end
		if str=="SkillEffect20" then
			for _,p in sgs.list(destlist)do
				if call(self,"isFriend",p)
				then return p end
			end
		end
		if str=="SkillEffect24" then
			for _,p in sgs.list(destlist)do
				if call(self.player,"getMark",call(p,"objectName").."SkillEffect24-SelfClear")<1
				and call(self,"isEnemy",p) and not call(self.player,"inMyAttackRange",p)
				then return p end
			end
			for _,p in sgs.list(destlist)do
				if call(self.player,"getMark",call(p,"objectName").."SkillEffect24-SelfClear")<1
				and call(self,"isEnemy",p)
				then return p end
			end
		end
		if str=="SkillEffect25" then
			for _,p in sgs.list(destlist)do
				if call(self,"isFriend",p) and call(p,"isWounded")
				then return p end
			end
		end
	end
	sgs.ai_skill_playerschosen["qingshu_tianshu"..i] = function(self,players)
		local str = tag(self,"qingshu_tianshu"..i.."SkillEffect","String","room")
		local destlist = call(self,"sort",players)
		if str=="SkillEffect27" then
			for _,p in sgs.list(destlist)do
				if call(self,"isFriend",p) and call(self,"canDraw",p) then
					for _,q in sgs.list(sgs.reverse(destlist))do
						if call(q,"getHandcardNum")<=call(p,"getHandcardNum") or call(self,"isFriend",q) then continue end
						return {p,q}
					end
				end
			end
			for _,p in sgs.list(destlist)do
				if not call(self,"isEnemy",p) then
					for _,q in sgs.list(sgs.reverse(destlist))do
						if call(q,"getHandcardNum")<=call(p,"getHandcardNum") or call(self,"isFriend",q) then continue end
						return {p,q}
					end
				end
			end
		end
		if str=="SkillEffect28" then
			for _,p in sgs.list(destlist)do
				if call(self,"isFriend",p) then
					for _,q in sgs.list(sgs.reverse(destlist))do
						if call(self,"isFriend",q)
						or call(q,"getEquips"):length()-#call(self,"poisonCards","e",q)<=call(p,"getEquips"):length()-#call(self,"poisonCards","e",p)
						then continue end
						return {p,q}
					end
				end
			end
			for _,p in sgs.list(destlist)do
				if not call(self,"isEnemy",p) then
					for _,q in sgs.list(sgs.reverse(destlist))do
						if call(self,"isFriend",q)
						or call(q,"getEquips"):length()-#call(self,"poisonCards","e",q)<=call(p,"getEquips"):length()-#call(self,"poisonCards","e",p)
						then continue end
						return {p,q}
					end
				end
			end
		end
		if str=="SkillEffect19" then
			local tos = {}
			for _,p in sgs.list(destlist)do
				if call(self,"isFriend",p) and call(self,"canDraw",p) then
					table.insert(tos,p)
					if #tos>1 then break end
				end
			end
			for _,p in sgs.list(destlist)do
				if not table.contains(tos,p) and not call(self,"isEnemy",p) then
					table.insert(tos,p)
					if #tos>1 then break end
				end
			end
			return tos
		end
	end
	sgs.ai_skill_discard["qingshu_tianshu"..i] = function(self)
		local str = tag(self,"qingshu_tianshu"..i.."SkillEffect","String","room")
		local cards = {}
		local handcards = sgs.QList2Table(call(self.player,"getCards","he"))
		call(self,"sortByKeepValue",handcards) -- 按保留值排序
		if str=="SkillEffect4" then
			for _,h in sgs.list(handcards)do
				if #cards>#handcards/2 or call(self,"getKeepValue",h)>6 then continue end
				table.insert(cards,call(h,"getEffectiveId"))
			end
			return cards
		end
		if str=="SkillEffect25" then
			for _,h in sgs.list(handcards)do
				if #cards>=2 then continue end
				table.insert(cards,call(h,"getEffectiveId"))
			end
			if #cards<2 then return {} end
			for _,p in sgs.list(self.friends_noself)do
				if call(self,"isWeak",p) and call(self.player,"isWounded") then
					return cards
				end
			end
		end
	end
end

sgs.ai_skill_use["@@skilleffectp"] = function(self,prompt)
    local c = named(self,"qingshu_tianshu0","slash",{})
    local dummy = call(self,"aiUseCard",c)
   	if dummy.card then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,call(p,"objectName"))
       	end
       	return answer(self,c,tos)
    end
end

sgs.ai_fill_skill.olshoushu = function(self)
	return parse(self,"#olshoushuCard:.:")
end

sgs.ai_skill_use_func["#olshoushuCard"] = function(card,use,self)
	call(self,"sort",self.friends_noself,nil,true)
	for _,p in sgs.list(self.friends_noself)do
		local has = false
		for _,s in sgs.qlist(call(p,"getVisibleSkillList"))do
			if s:objectName():startsWith("qingshu_tianshu")
			then has = true break end
		end
		if has then continue end
		use.card = card
		use.to:append(p)
		break
	end
end

sgs.ai_use_value.olshoushuCard = 3.4
sgs.ai_use_priority.olshoushuCard = 6.2

sgs.ai_skill_cardask["bingcai0"] = function(self,data,pattern)
	local use = call(data,"toCardUse")
	if call(self,"isFriend",use.from) and use.to:length()>0 then
		if not call(self,"isFriend",use.to:at(0)) then
			return true
		end
		if call(use.card,"targetFixed") and call(use.from,"getLostHp")>1 then
			return true
		end
	end
	return "."
end

sgs.ai_fill_skill.lixian = function(self)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
  	for _,h in sgs.list(cards)do
		if call(h,"hasTip","lixian") then
			local dc = named(self,"lixian","slash",{call(h,"getEffectiveId")})
			if call(dc,"isAvailable",self.player) then
				local d = call(self,"aiUseCard",dc)
				if d.card then
					return dc
				end
			end
		end
	end
end

function sgs.ai_cardsview.lixian(self,class_name,player)
  	for _,c in sgs.list(call(player,"getCards","he"))do
		if call(c,"hasTip","lixian") then
			if class_name=="Jink" then
				return material_proposal(c,"jink","lixian")
			else
				return material_proposal(c,"slash","lixian")
			end
		end
	end
end

sgs.ai_fill_skill.wenren = function(self)
	return parse(self,"@WenrenCard=.")
end

sgs.ai_skill_use_func["WenrenCard"] = function(card,use,self)
	call(self,"sort",self.friends)
	for _,p in sgs.list(self.friends)do
		if call(p,"getHandcardNum")<=call(self.player,"getHandcardNum") and call(self,"canDraw",p) then
			use.card = card
			use.to:append(p)
		end
	end
end

sgs.ai_use_value.WenrenCard = 5.4
sgs.ai_use_priority.WenrenCard = 9.2

sgs.ai_skill_playerchosen.zongluan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
    for _,p in sgs.list(destlist)do
		if call(self,"isFriend",p) then
			for _,q in sgs.list(destlist)do
				if call(p,"inMyAttackRange",q) and call(self,"isEnemy",q) and call(p,"canSlash",q) then
					return p
				end
			end
		end
	end
end

sgs.ai_skill_playerschosen.zongluan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if call(self,"isEnemy",p) then
			table.insert(tos,p)
		end
	end
	return tos
end

sgs.ai_skill_invoke.olxuhe = function(self,data)
	local has = nested(self,"ai_skill_invoke","xuhe",self,data)
	capture_choice(self,"olxuhe","xuhe")
	return has
end

sgs.ai_skill_choice.jiaoyu = function(self,choices,data)  --待补充
	local r = call(self.player,"getMark","jiaoyuRed")
	if r>call(self.player,"getEquips"):length()/2 then
		return "red"
	end
	return "black"
end

sgs.ai_skill_askforag.siqi = function(self,card_ids)
	return card_ids[#card_ids]
end

sgs.ai_skill_invoke.siqi = function(self,data)
	return true
end

sgs.ai_skill_use["@@siqi"] = function(self,prompt)
	local tos,ts = {},{}
	for _,id in sgs.list(tag(self,"siqiForAI","IntList","owner"))do
		table.insert(ts,face(self,id))
	end
    call(self,"sortByUseValue",ts)
	for _,c in sgs.list(ts)do
		if call(c,"isAvailable",self.player)
		and (call(c,"isKindOf","Peach") or call(c,"isKindOf","Analeptic") or call(c,"isKindOf","ExNihilo") or call(c,"isKindOf","EquipCard")) then
			local d = call(self,"aiUseCard",c)
			if d.card then
				if d.to:length()<1 then return response(self,"@SiqiCard="..c:getLegacyStringKey()) end
				for _,p in sgs.list(d.to)do
					table.insert(tos,call(p,"objectName"))
				end
				return response(self,"@SiqiCard="..c:getLegacyStringKey().."->"..table.concat(tos,"+"))
			end
		end
	end
	call(self,"sort",self.friends_noself)
	for _,c in sgs.list(ts)do
		for _,p in sgs.list(self.friends_noself)do
			if call(self.player,"isProhibited",p,c) then continue end
			if call(c,"isKindOf","Peach") then
				if call(c,"isWounded") then
					return response(self,"@SiqiCard="..c:getLegacyStringKey().."->"..p:objectName())
				end
			elseif call(c,"isKindOf","ExNihilo") then
				if call(self,"canDraw",p) then
					return response(self,"@SiqiCard="..c:getLegacyStringKey().."->"..p:objectName())
				end
			elseif call(c,"isKindOf","EquipCard") then
				local n = call(c,"getEquipSlot")
				if call(p,"getEquip",n) then
					if #call(self,"poisonCards",{call(p,"getEquip",n)},p)>0 then
						return response(self,"@SiqiCard="..c:getLegacyStringKey().."->"..p:objectName())
					end
				else
					return response(self,"@SiqiCard="..c:getLegacyStringKey().."->"..p:objectName())
				end
			elseif call(c,"isKindOf","Analeptic") then
				if getCardsNum("Slash",p,self.player)>0 then
					return response(self,"@SiqiCard="..c:getLegacyStringKey().."->"..p:objectName())
				end
			end
		end
	end
end

sgs.ai_fill_skill.qiaozhi = function(self)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
  	for _,h in sgs.list(cards)do
		if call(self,"canDraw") and not call(self.player,"isJilei",h) and call(self,"getKeepValue",h)<6 then
			return parse(self,"@QiaozhiCard="..h:getLegacyStringKey())
		end
	end
end

sgs.ai_skill_use_func["QiaozhiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.QiaozhiCard = 5.4
sgs.ai_use_priority.QiaozhiCard = 9.2

sgs.ai_skill_askforag.qiaozhi = function(self,card_ids)
	for _,id in sgs.list(card_ids)do
		local c = face(self,id)
		local d = call(self,"aiUseCard",c)
		if d.card then return id end
	end
end

sgs.ai_skill_playerchosen.choulie = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local to = nil
	local dc = flagged_choulie(self)
    for _,p in sgs.list(destlist)do
		if call(self,"isEnemy",p) and call(p,"getHandcardNum")<=call(self.player,"getCardCount")
		and call(self.player,"canSlash",p,nil,false) and call(self,"slashIsEffective",dc,p) then
			if call(p,"isLord") then
				return p
			end
			to = p
		end
	end
	return to
end

sgs.ai_skill_cardask["choulie1"] = function(self,data,pattern)
	local to = call(data,"toPlayer")
	local dc = flagged_choulie(self)
	if not call(self,"isFriend",to) and call(self,"slashIsEffective",dc,to) then
		return true
	end
end

sgs.ai_skill_cardask["choulie2"] = function(self,data,pattern)
	return true
end

sgs.ai_skill_choice.fengwei = function(self,choices,data)  --待补充
	local r = call(self.player,"getHp")
	if r>0 and r<5 then
		return ""..r
	end
	return "2"
end

sgs.ai_fill_skill.zonghu = function(self)
	return parse(self,"@ZonghuCard=.")
end

sgs.ai_skill_use_func["ZonghuCard"] = function(card,use,self)
	local dc = evaluation(self)
	if not call(dc,"isAvailable",self.player) then return end
	local n = call(self.player,"getMark","&zonghu_lun")
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
	local ids = {}
  	for _,h in sgs.list(cards)do
		if call(self,"getKeepValue",h)<6 then
			table.insert(ids,call(h,"getId"))
			if #ids>n then break end
		end
	end
	if #ids<=n then return end
	local d = call(self,"aiUseCard",dc)
	if d.card then use.to = d.to
	else return end
	if #call(self,"poisonCards",ids)>#ids/2 then
		call(self,"sort",self.enemies)
		for _,p in sgs.list(self.enemies)do
			use.card = parse(self,"@ZonghuCard="..table.concat(ids,"+")..":slash")
			save_player(self,"zonghuTo",p)
			return
		end
	end
	call(self,"sort",self.friends_noself)
  	for _,p in sgs.list(self.friends_noself)do
		if call(self,"canDraw",p) then
			save_player(self,"zonghuTo",p)
			use.card = parse(self,"@ZonghuCard="..table.concat(ids,"+")..":slash")
			return
		end
	end
  	for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
		if call(self,"isEnemy",p) then continue end
		save_player(self,"zonghuTo",p)
		use.card = parse(self,"@ZonghuCard="..table.concat(ids,"+")..":slash")
		return
	end
end

sgs.ai_use_value.ZonghuCard = 5.4
sgs.ai_use_priority.ZonghuCard = 1.2

sgs.ai_skill_playerchosen.zonghu = function(self,players)
    for _,p in sgs.list(players)do
		if saved_player(self,"zonghuTo")==p then
			return p
		end
	end
end

sgs.ai_guhuo_card.zonghu = function(self,toname,class_name)
	if call(self,"getCardsNum",class_name)>0 then return end
	local n = call(self.player,"getMark","&zonghu_lun")
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
	local ids = {}
  	for _,h in sgs.list(cards)do
		if call(self,"getKeepValue",h)<6 then
			table.insert(ids,call(h,"getId"))
			if #ids>n then break end
		end
	end
	if #ids<=n then return end
	if #call(self,"poisonCards",ids)>#ids/2 then
		call(self,"sort",self.enemies)
		for _,p in sgs.list(self.enemies)do
			save_player(self,"zonghuTo",p)
			return proposal(self,"@ZonghuCard="..table.concat(ids,"+")..":"..toname)
		end
	end
	call(self,"sort",self.friends_noself)
  	for _,p in sgs.list(self.friends_noself)do
		if call(self,"canDraw",p) then
			save_player(self,"zonghuTo",p)
			return proposal(self,"@ZonghuCard="..table.concat(ids,"+")..":"..toname)
		end
	end
  	for _,p in sgs.list(call(self.room,"getOtherPlayers",self.player))do
		if call(self,"isEnemy",p) then continue end
		save_player(self,"zonghuTo",p)
		return proposal(self,"@ZonghuCard="..table.concat(ids,"+")..":"..toname)
	end
end

sgs.ai_skill_cardask["olbiluan0"] = function(self,data,pattern)
	if call(self,"isWeak") or #self.enemies>0 then
		return true
	end
end

sgs.ai_skill_choice.ollixia = function(self,choices,data)
	local items = choices:split("+")
	local to = call(data,"toPlayer")
	if table.contains(items,"ollixia3")
	and call(self,"isFriend",to) and call(to,"isWounded")
	then return "ollixia3" end
	if table.contains(items,"ollixia1")
	and call(self,"canDraw")
	then return "ollixia1" end
	if table.contains(items,"ollixia2")
	and call(self,"isFriend",to) and call(self,"canDraw",to)
	then return "ollixia2" end
	if table.contains(items,"ollixia1")
	then return "ollixia1" end
	return items[#items]
end

sgs.ai_skill_askforag.xutu2 = function(self,card_ids)
	local cs = call(self,"poisonCards",card_ids)
	if #cs>0 then return cs[1]:getId() end
	for _,id in sgs.list(card_ids)do
		table.insert(cs,face(self,id))
	end
	call(self,"sortByKeepValue",cs)
	return cs[1]:getId()
end

sgs.ai_fill_skill.lunzhan = function(self)
  	local mt = ""
	for _,m in ipairs(call(self.player,"getMarkNames"))do
		if m:startsWith("&lunzhan+:+") then
			mt = m
			break
		end
	end
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByKeepValue",cards)
	local ids = {}
  	for _,h in sgs.list(cards)do
		if string.find(mt,tostring(#ids)) then
			table.insert(ids,call(h,"getId"))
			if #ids>5 then break end
		else
			if #ids<1 then return parse(self,"@LunzhanCard=.") end
			return parse(self,"@LunzhanCard="..table.concat(ids,"+"))
		end
	end
end

sgs.ai_skill_use_func["LunzhanCard"] = function(card,use,self)
	local dc = named(self,"lunzhan","Duel",call(card,"getSubcards"))
	if not call(dc,"isAvailable",self.player) then return end
	local nts = {}
  	for _,p in sgs.list(call(self.room,"getAlivePlayers"))do
		if call(p,"getMark","lunzhanBan-Clear")>0 then
			table.insert(nts,p)
		end
	end
	local d = call(self,"aiUseCard",dc,dummy(nil,0,nts))
	if d.card then
		use.card = card
		use.to = d.to
	end
end

sgs.ai_use_value.LunzhanCard = 5.4
sgs.ai_use_priority.LunzhanCard = 2.2

sgs.ai_skill_invoke.lunzhan = function(self,data)
	return call(self,"canDraw")
end

sgs.ai_skill_invoke.fulve = function(self,data)
	local use = call(data,"toCardUse")
	if use.to then
		return not call(self,"isFriend",use.to:last())
	end
end

sgs.ai_fill_skill.lucun = function(self)
  	for _,pn in sgs.list(RandomList(known(self.world.strategy_facts.pattern_names,"pattern_names")))do
		if call(self.player,"getMark","lucun_guhuo_remove_"..pn.."_lun")>0 then continue end
		local dc = named(self,"lucun",pn,{})
		if (call(dc,"getTypeId")==1 or call(dc,"isNDTrick"))
		and call(dc,"isAvailable",self.player) then
			local d = call(self,"aiUseCard",dc)
			if d.card then
				if call(dc,"canRecast") and d.to:length()<1 then continue end
				save_targets(self,"lucunTo",d.to)
				sgs.ai_use_priority.LucunCard = sgs.ai_use_priority[call(dc,"getClassName")]
				return parse(self,"@LucunCard=.:"..pn)
			end
		end
	end
end

sgs.ai_skill_use_func["LucunCard"] = function(card,use,self)
	if targets(self,"lucunTo") then
		use.to = targets(self,"lucunTo")
		use.card = card
	end
end

sgs.ai_use_value.LucunCard = 5.4
sgs.ai_use_priority.LucunCard = 9.2

sgs.ai_guhuo_card.lucun = function(self,toname,class_name)
	if call(self.player,"getMark","lucun_guhuo_remove_"..toname.."_lun")>0
	or call(self,"getCardsNum",class_name)>0 then return end
	return proposal(self,"@LucunCard=.:"..toname)
end

sgs.ai_skill_invoke.tuisheng = function(self,data)
	return call(self,"isWeak") and call(self,"getAllPeachNum")<1
end

sgs.ai_skill_choice.tuisheng = function(self,choices,data)
	local items = choices:split("+")
	local to = call(self.room,"getCurrent")
	if table.contains(items,"tuisheng2")
	and not call(self,"isEnemy",to)
	then return "tuisheng2" end
	return items[1]
end

sgs.ai_skill_playerchosen.pengbi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
    for _,p in sgs.list(destlist)do
		if call(self,"isFriend",p) then
			return p
		end
	end
    for _,p in sgs.list(destlist)do
		if not call(self,"isEnemy",p) then
			return p
		end
	end
end

sgs.ai_fill_skill.dici = function(self)
	return parse(self,"@DiciCard=.")
end

sgs.ai_skill_use_func["DiciCard"] = function(card,use,self)
	call(self,"sort",self.friends_noself)
  	for _,p in sgs.list(self.friends_noself)do
		if call(self,"isWeak",p) and call(p,"isWounded") and call(p,"getHandcardNum")>0 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	call(self,"sort",self.enemies)
  	for _,p in sgs.list(self.enemies)do
		if not call(p,"isWounded") and call(p,"getHandcardNum")>0 then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.DiciCard = 5.4
sgs.ai_use_priority.DiciCard = 6.2

sgs.ai_skill_discard.sibing = function(self,discard_num,min_num,optional,include_equip)
	local use = tag(self,"sibingData","CardUse","room")
	local cards = sgs.QList2Table(call(self.player,"getCards","he"))
	call(self,"sortByKeepValue",cards)
	local ids = {}
	if use.from==self.player then
		if call(self,"isFriend",use.to:last()) then return {} end
		for i,c in sgs.list(cards)do
			if i<=#cards/2 and call(c,"isRed") then
				table.insert(ids,call(c,"getId"))
			end
		end
	else
		for i,c in sgs.list(cards)do
			if i<=#cards/2 and #ids<min_num then
				table.insert(ids,call(c,"getId"))
			end
		end
		if #ids<min_num or not call(self,"isWeak") then return {} end
	end
	return ids
end

sgs.ai_skill_use["@@sibing"] = function(self,prompt)
    local cards = call(self.player,"getCards","he")
    cards = call(self,"sortByKeepValue",cards,nil,"j") -- 按保留值排序
	for _,h in sgs.list(cards)do
    	if call(h,"isBlack") then
			local dc = evaluation(self)
			local d = call(self,"aiUseCard",dc)
			if d.card then
				local tps = {}
				for _,p in sgs.list(d.to)do
					table.insert(tps,call(p,"objectName"))
				end
				return response(self,"@SibingCard="..h:getLegacyStringKey().."->"..table.concat(tps,"+"))
			end
			break
		end
	end
end

sgs.ai_skill_invoke.liance = function(self,data)
	return call(self,"canDraw")
end

sgs.ai_fill_skill.ol2shanjia = function(self)
	return parse(self,"@OL2ShanjiaCard=.:slash")
end

sgs.ai_skill_use_func["OL2ShanjiaCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.OL2ShanjiaCard = 5.4
sgs.ai_use_priority.OL2ShanjiaCard = 2.2

sgs.ai_skill_use["@@ol2shanjia"] = function(self,prompt,method,pattern,request)
    local c = named(self,"_ol2shanjia","slash",{})
    local dummy = call(self,"aiUseCard",c)
   	if dummy.card then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,call(p,"objectName"))
       	end
         -- Bind only the selected source clone through this live response scope.
        local paid=call(self,"bindSkillCard","ol2shanjia",{},request)
        for _,m in ipairs{"objectName","getSuit","getNumber","getLegacyStringKey"}do
            if call(paid,m)~=call(c,m)then ai_unsupported("OL2Shanjia selected source product changed",m)end
        end
        if call(paid,"getSkillName",false)~=call(c,"getSkillName",false)
            or #call(paid,"getSubcards")~=0 then ai_unsupported("OL2Shanjia source cost/skill changed","ol2shanjia")end
        return {kind="use_card",card_spec=call(paid,"toCardSpec"),targets=tos}
    end
end

sgs.ai_skill_playerchosen.liantao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if call(self,"isEnemy",p) then
			return p
		end
	end
end

sgs.ai_skill_playerchosen.olmomingcha = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
    for _,p in sgs.list(destlist)do
		if not call(self,"isFriend",p) then
			return p
		end
	end
	return destlist[#destlist]
end

sgs.ai_skill_use["@@huanhuo"] = function(self,prompt)
	local destlist = sgs.QList2Table(call(self.room,"getAlivePlayers")) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
	local tps = {}
	for _,p in sgs.list(destlist)do
		if #tps<2 and not call(self,"isFriend",p) then
			table.insert(tps,call(p,"objectName"))
		end
	end
    local cards = call(self.player,"getCards","he")
    cards = call(self,"sortByKeepValue",cards,nil,"j") -- 按保留值排序
	local ids = {}
	for _,h in sgs.list(cards)do
    	table.insert(ids,h:getLegacyStringKey())
		if #ids==#tps then
			return response(self,"@HuanhuoCard="..table.concat(ids,"+").."->"..table.concat(tps,"+"))
		end
	end
end

sgs.ai_skill_invoke.olqingshi = function(self,data)
	return not call(self,"isWeak") and #self.enemies>0
end

sgs.ai_skill_use["@@olqingshi"] = function(self,prompt)
    local cards = call(self.player,"getCards","he")
    cards = call(self,"sortByKeepValue",cards,nil,"j") -- 按保留值排序
	local use = tag(self,"olqingshiUse","CardUse","owner")
	local bps = {}
	local destlist = sgs.QList2Table(call(self.room,"getAlivePlayers")) -- 将列表转换为表
	for _,p in sgs.list(destlist)do
		if call(p,"hasFlag","olqingshiTo") then continue end
		table.insert(bps,p)
	end
	call(self,"sort",destlist)
	for _,h in sgs.list(cards)do
		local d = call(self,"aiUseCard",use.card,dummy(true,0,bps))
		if d.card and d.to:length()>0 and d.to:first()~=use.to:first() then
			return response(self,"@OLQingshiCard="..h:getLegacyStringKey().."->"..d.to:first():objectName())
		end
		if call(self,"isEnemy",use.from) and call(self,"isFriend",use.to:first()) then
			for _,p in sgs.list(destlist)do
				if call(p,"hasFlag","olqingshiTo") and call(self,"isEnemy",p) then
					return response(self,"@OLQingshiCard="..h:getLegacyStringKey().."->"..p:objectName())
				end
			end
			for _,p in sgs.list(destlist)do
				if call(p,"hasFlag","olqingshiTo") and not call(self,"isFriend",p) then
					return response(self,"@OLQingshiCard="..h:getLegacyStringKey().."->"..p:objectName())
				end
			end
		end
		break
	end
end

sgs.ai_fill_skill.kuanmo = function(self)
	return not call(self,"isWeak") and parse(self,"@KuanmoCard=.")
end

sgs.ai_skill_use_func["KuanmoCard"] = function(card,use,self)
	call(self,"sort",self.enemies)
  	for _,p in sgs.list(self.enemies)do
		if call(self.player,"inMyAttackRange",p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.KuanmoCard = 5.4
sgs.ai_use_priority.KuanmoCard = 6.2

sgs.ai_skill_use["@@kuanmo!"] = function(self,prompt)
	call(self,"sort",self.enemies)
  	for _,p in sgs.list(self.enemies)do
		if call(self.player,"inMyAttackRange",p) then
			return response(self,"@KuanmoCard=.->"..p:objectName())
		end
	end
	local destlist = sgs.QList2Table(call(self.room,"getAlivePlayers")) -- 将列表转换为表
	call(self,"sort",destlist)
	for _,p in sgs.list(destlist)do
		if not call(self,"isFriend",p) then
			return response(self,"@KuanmoCard=.->"..p:objectName())
		end
	end
	for _,p in sgs.list(destlist)do
		if p~=self.player then
			return response(self,"@KuanmoCard=.->"..p:objectName())
		end
	end
end

sgs.ai_fill_skill.gangqian = function(self)
	if call(self.player,"getMark","gangqianQi")>0 then
		local bps = {}
		for _,p in sgs.list(call(self.room,"getAlivePlayers"))do
			if call(self.player,"isAdjacentTo",p) then continue end
			table.insert(bps,p)
		end
		local dc = named(self,"gangqian","fire_slash",{})
		local cards = call(self.player,"getCards","he")
		cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
		for _,c in sgs.list(cards)do
			if call(c,"getTypeId")==3 then
				dc=named(self,"gangqian","fire_slash",{call(c,"getEffectiveId")})
				if call(dc,"isAvailable",self.player) then
					local d = call(self,"aiUseCard",dc,dummy(true,0,bps))
					if d.card then
						save_plan(self,"gangqianUse",d)
						return parse(self,"@GangqianCard="..c:getLegacyStringKey())
					end
				end
				dc=named(self,"gangqian","fire_slash",{})
			end
		end
		return
	end
    local cards = call(self.player,"getCards","h")
    cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
	local dc = named(self,"gangqian","duel",{})
	for _,c in sgs.list(cards)do
		if call(c,"getTypeId")==2 then
			dc=named(self,"gangqian","duel",{call(c,"getEffectiveId")})
			if call(dc,"isAvailable",self.player) then
				return dc
			end
			dc=named(self,"gangqian","duel",{})
		end
	end
end

sgs.ai_skill_use_func["GangqianCard"] = function(card,use,self)
	use.card = card
	use.to = load_plan(self,"gangqianUse").to
end

sgs.ai_use_value.GangqianCard = 5.4
sgs.ai_use_priority.GangqianCard = 2.2

sgs.ai_fill_skill.miluo = function(self)
    local cards = call(self.player,"getCards","he")
    cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
	local ids = {}
	local tps = {}
	for i=0,9 do
		local c,p = call(self,"getCardNeedPlayer",cards,false)
		if c and p then
			if not table.contains(tps,call(p,"objectName")) then
				table.insert(ids,c:getLegacyStringKey())
				table.insert(tps,call(p,"objectName"))
				if #tps>1 then break end
			end
			table.removeOne(cards,c)
			if #cards<1 then break end
		end
	end
	if #tps<1 and #cards>1 then
		local destlist = sgs.QList2Table(call(self.room,"getOtherPlayers",self.player)) -- 将列表转换为表
		call(self,"sort",destlist)
		ids = {cards[1]:getLegacyStringKey()}
		tps = {destlist[1]:objectName()}
	end
	if #tps>0 then
		memory(self,"miluo_to",tps,true)
		return parse(self,"@MiluoCard="..table.concat(ids,"+"))
	end
end

sgs.ai_skill_use_func["MiluoCard"] = function(card,use,self)
	for _,p in sgs.list(call(self.room,"getAlivePlayers"))do
		if table.contains(memory(self,"miluo_to"),call(p,"objectName")) then
			use.to:append(p)
			use.card = card
		end
	end
end

sgs.ai_use_value.MiluoCard = 5.4
sgs.ai_use_priority.MiluoCard = 1.2

sgs.ai_skill_choice.miluo = function(self,choices,data)
	local items = choices:split("+")
	for _,t in sgs.list(items)do
		if t:startsWith("miluo1") then
			for _,p in sgs.list(self.enemies)do
				if t:endsWith(call(p,"objectName")) and call(self,"isWeak",p) then
					return t
				end
			end
		else
			for _,p in sgs.list(self.friends)do
				if t:endsWith(call(p,"objectName")) and call(self,"isWeak",p) then
					return t
				end
			end
		end
	end
	for _,t in sgs.list(items)do
		if t:startsWith("miluo1") then
			for _,p in sgs.list(self.enemies)do
				if t:endsWith(call(p,"objectName")) then
					return t
				end
			end
		else
			for _,p in sgs.list(self.friends)do
				if t:endsWith(call(p,"objectName")) then
					return t
				end
			end
		end
	end
	return items[#items]
end

sgs.ai_fill_skill.oljueyan = function(self)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByUseValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if call(c,"isNDTrick") or call(c,"getTypeId")==1 and call(c,"getSuit")==2 then
			if call(self,"getCardsNum",call(c,"getClassName"))>1 then continue end
			local dc = named(self,"oljueyan",call(c,"objectName"),{})
			if call(dc,"isAvailable",self.player) then
				local d = call(self,"aiUseCard",dc)
				if d.card then
					save_plan(self,"oljueyanUse",d)
					sgs.ai_use_priority.OLJueyanCard = sgs.ai_use_priority[call(c,"getClassName")]
					return parse(self,"@OLJueyanCard="..c:getLegacyStringKey()..":"..c:objectName())
				end
			end
		end
	end
end

sgs.ai_skill_use_func["OLJueyanCard"] = function(card,use,self)
	use.card = card
	use.to = load_plan(self,"oljueyanUse").to
end

sgs.ai_use_value.OLJueyanCard = 5.4
sgs.ai_use_priority.OLJueyanCard = 2.2

sgs.ai_guhuo_card.oljueyan = function(self,toname,class_name)
	if call(self,"getCardsNum",class_name)>1 then return end
	for _,c in sgs.list(call(self.player,"getCards","he"))do
		if call(c,"isKindOf",class_name) then
			return proposal(self,"@OLJueyanCard="..c:getLegacyStringKey()..":"..toname)
		end
	end
end

sgs.ai_fill_skill.suyi = function(self)
	return parse(self,"@SuyiCard=.:slash")
end

sgs.ai_skill_use_func["SuyiCard"] = function(card,use,self)
	local dc = evaluation(self)
	local d = call(self,"aiUseCard",dc)
	if d.card then
		use.card = card
		use.to:append(d.to:first())
		return
	end
	call(self,"sort",self.enemies)
    for _,p in sgs.list(self.enemies)do
		if call(self.player,"canSlash",p,false) and call(self,"slashIsEffective",dc,p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.SuyiCard = 5.4
sgs.ai_use_priority.SuyiCard = 2.2

sgs.ai_fill_skill.xiewei = function(self)
	local cards = call(self.player,"getCards","h")
	cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
	local dc = named(self,"xiewei",nil,{})
	local ids = {}
	for _,c in sgs.list(cards)do
		if table.contains(self.toUse,c) then continue end
		table.insert(ids,c:getLegacyStringKey())
		if #ids==2 and call(dc,"isAvailable",self.player) then
			local d = call(self,"aiUseCard",dc)
			if d.card then
				save_plan(self,"xieweiUse",d)
				return parse(self,"@XieweiCard="..table.concat(ids,"+")..":slash")
			end
		end
	end
end

sgs.ai_skill_use_func["XieweiCard"] = function(card,use,self)
	use.card = card
	use.to = load_plan(self,"xieweiUse").to
end

sgs.ai_use_value.XieweiCard = 5.4
sgs.ai_use_priority.XieweiCard = 2.2

function sgs.ai_cardsview.xiewei(self,class_name,player)
	local cards = call(player,"getCards","h")
	cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
	local ids = {}
	for _,c in sgs.list(cards)do
		table.insert(ids,c:getLegacyStringKey())
		if #ids==2 then
			if class_name=="Jink" then
				return proposal(self,"@XieweiCard="..table.concat(ids,"+")..":jink")
			else
				return proposal(self,"@XieweiCard="..table.concat(ids,"+")..":slash")
			end
		end
	end
end

sgs.ai_fill_skill.youque = function(self)
	local cards = {}
	for _,id in sgs.list(call(self.player,"getPile","xw_er"))do
		table.insert(cards,face(self,id))
	end
	local n = 99
	for _,c in sgs.list(cards)do
		n = math.min(n,call(c,"getNumber"))
	end
	for _,c in sgs.list(cards)do
		if call(c,"getNumber")==n then
			return parse(self,"@YouqueCard="..c:getLegacyStringKey())
		end
	end
end

sgs.ai_skill_use_func["YouqueCard"] = function(card,use,self)
	call(self,"sort",self.enemies)
    for _,p in sgs.list(self.enemies)do
		if call(self.player,"canPindian",p) and call(self.player,"canSlash",p,false)
		and call(self,"slashIsEffective",evaluation(self),p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.YouqueCard = 5.4
sgs.ai_use_priority.YouqueCard = 3.2

sgs.ai_skill_choice.kuangxin = function(self,choices,data)
	local items = choices:split("+")
	return items[math.random(1,2)]
end

sgs.ai_skill_invoke.leishi = function(self,data)
	return call(self,"canDraw")
end

sgs.ai_skill_playerchosen.leishi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if call(self,"isEnemy",p) and call(self,"damageIsEffective",p,"F") then
			return p
		end
	end
    for _,p in sgs.list(destlist)do
		if not call(self,"isFriend",p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.zhuole = function(self,data)
	local tp = call(data,"toPlayer")
	return call(self,"isFriend",tp) and call(tp,"isWounded")
end

sgs.ai_skill_playerchosen.zhuole = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if call(p,"getMark","drank")<1 and call(self,"isFriend",p) then
			return p
		end
	end
    for _,p in sgs.list(destlist)do
		if call(self,"isFriend",p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.qiaowu = function(self,data)
	if call(self.player,"getChangeSkillState","qiaowu")==1 then
		local n = 0
		for _,p in sgs.qlist(call(self.room,"getAlivePlayers"))do
			if call(p,"getMark","drank")<1 then continue end
			if call(self,"canDraw",p) and call(self,"isFriend",p) then
				n = n+1
			else
				n = n-1
			end
		end
		return n>0
	end
	local n = 0
	for _,p in sgs.qlist(call(self.room,"getAlivePlayers"))do
		if call(p,"getMark","drank")<1 or getCardsNum("Slash",p,self.player)<1 then continue end
		if call(self,"isFriend",p) then
			n = n+1
		else
			n = n-1
		end
	end
	return n>0
end

sgs.ai_skill_playerschosen.jiyun = function(self,players,m,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<m and call(self,"isFriend",p) and call(self,"canDraw",p) then
			table.insert(tps,p)
		end
	end
    return tps
end

function sgs.ai_cardsview.olshuliang(self,class_name,player)
	for _,id in sgs.qlist(call(player,"getPile","jy_liang"))do
		if face(self,id):isKindOf(class_name) then
			return id
		end
	end
end

sgs.ai_fill_skill.olshuliang = function(self)
	local cards = {}
	for _,id in sgs.qlist(call(self.player,"getPile","jy_liang"))do
		table.insert(cards,face(self,id))
	end
	return cards
end

sgs.ai_skill_playerchosen.xuanliu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
    for _,p in sgs.list(destlist)do
		if call(self,"isFriend",p) and call(self,"canDraw",p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.dongxin = function(self,data)
	local tp = call(data,"toPlayer")
	local damage = tag(self,"dongxinData","Damage","owner")
	return call(self,"doDisCard",tp,"he") and damage.from
	and call(self,"isEnemy",damage.from) and call(self,"isWeak",damage.from)
end

sgs.ai_skill_discard.sibing = function(self,discard_num,min_num,optional,include_equip)
	local damage = tag(self,"dongxinData","Damage","owner")
	local cards = sgs.QList2Table(call(self.player,"getCards","he"))
	call(self,"sortByKeepValue",cards)
	local ids = {}
	for i,c in sgs.list(cards)do
		if call(self,"doDisCard",self.player,call(c,"getId")) then
			table.insert(ids,call(c,"getId"))
			if #ids>=discard_num then break end
		end
	end
	if #ids>min_num/2 or damage.from and call(self,"isEnemy",damage.from) and call(self,"isWeak",damage.from) then
		for i,c in sgs.list(cards)do
			if table.contains(ids,call(c,"getId")) or #ids>=discard_num then continue end
			table.insert(ids,call(c,"getId"))
		end
		return ids
	end
end

sgs.ai_skill_invoke.zhitian = function(self,data)
	local effect = call(data,"toCardEffect")
	return call(self,"isEnemy",effect.to)
end

sgs.ai_fill_skill.zhijue = function(self)
	if call(self.player,"getChangeSkillState","zhijue")==1 then
		local dc = named(self,"zhijue","fire_attack",{call(self.player,"getMark","zhijueId")})
		return dc
	end
	local cards = call(self.player,"getCards","h")
	cards = call(self,"sortByUseValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if table.contains(self.toUse,c) or not call(c,"isDamageCard")
		or call(self.player,"getMark",call(c,"getColorString").."zhijueColor-Clear")>0 then continue end
		local dc = named(self,"zhijue",call(c,"objectName"),{},false)
		local d = call(self,"aiUseCard",dc)
		if d.card and d.to:length()>0 then
			save_plan(self,"zhijueUse",d)
			local ids = {}
			for _,h in sgs.list(cards)do
				if call(c,"getColor")==call(h,"getColor") then
					table.insert(ids,call(h,"getId"))
				end
			end
			sgs.ai_use_priority.ZhijueCard = sgs.ai_use_priority[call(c,"getClassName")]
			return parse(self,"@ZhijueCard="..table.concat(ids,"+"))
		end
	end
end

sgs.ai_skill_use_func["ZhijueCard"] = function(card,use,self)
	use.card = card
	use.to = load_plan(self,"zhijueUse").to
end

sgs.ai_use_value.ZhijueCard = 5.4
sgs.ai_use_priority.ZhijueCard = 2.2

sgs.ai_skill_invoke.olduduan = function(self,data)
	return true
end

sgs.ai_fill_skill.yinglve = function(self)
	return parse(self,"@YinglveCard=.")
end

sgs.ai_skill_use_func["YinglveCard"] = function(card,use,self)
	call(self,"sort",self.friends,nil,true)
    for _,p in sgs.list(self.friends)do
		if call(self.player,"getMark","1yinglve-PlayClear")>0 and not call(self,"isWeak",p) then
			save_choice(self,"yinglve","1")
			use.card = card
			use.to:append(p)
			return
		end
	end
	call(self,"sort",self.friends)
    for _,p in sgs.list(self.friends)do
		if call(self.player,"getMark","2yinglve-PlayClear")>0 and call(self,"isWeak",p) then
			save_choice(self,"yinglve","2")
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.YinglveCard = 5.4
sgs.ai_use_priority.YinglveCard = 3.2

sgs.ai_skill_use["@@mengshi"] = function(self,prompt)
	call(self,"sort",self.enemies,nil,true)
	call(self,"sort",self.friends_noself)
	for _,ep in sgs.list(self.enemies)do
		for _,fp in sgs.list(self.friends_noself)do
			local x = call(ep,"getHp")-call(fp,"getHp")
			if x>0 and x<call(self.player,"getHp") and call(self,"isWeak",fp) then
				local tps = {call(ep,"objectName"),call(fp,"objectName")}
				return response(self,"@MengshiCard=.->"..table.concat(tps,"+"))
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		for _,fp in sgs.list(self.friends_noself)do
			local x = call(ep,"getHp")-call(fp,"getHp")
			if x>=0 and x<call(self.player,"getHp") and call(self,"isWeak") then
				local tps = {call(ep,"objectName"),call(fp,"objectName")}
				return response(self,"@MengshiCard=.->"..table.concat(tps,"+"))
			end
		end
	end
end

sgs.ai_guhuo_card.huanpei = function(self,toname,class_name)
	return proposal(self,"@HuanpeiCard=.:"..toname)
end

sgs.ai_fill_skill.huanpei = function(self)
	for _,cn in sgs.list(cardnames(self,"BasicCard"))do
		local dc = named(self,"huanpei",cn,{})
		if call(dc,"isAvailable",self.player) then
			local d = call(self,"aiUseCard",dc)
			if d.card then
				save_targets(self,"huanpei_to",d.to)
				sgs.ai_use_priority.HuanpeiCard = sgs.ai_use_priority[call(dc,"getClassName")]
				return parse(self,"@HuanpeiCard=.:"..cn)
			end
		end
	end
end

sgs.ai_skill_use_func["HuanpeiCard"] = function(card,use,self)
	use.card = card
	use.to = targets(self,"huanpei_to")
end

sgs.ai_use_value.HuanpeiCard = 5.4
sgs.ai_use_priority.HuanpeiCard = 2.2

sgs.ai_skill_cardask["wenyi0"] = function(self,data,pattern)
	local tp = call(data,"toPlayer")
	if call(self,"isFriend",tp) then
		return true
	end
end

sgs.ai_skill_invoke.bachao = function(self,data)
	return call(self,"canDraw")
end

sgs.ai_skill_cardask["bachao0"] = function(self,data,pattern)
	local tp = call(data,"toPlayer")
	if call(self,"isFriend",tp) and call(self,"getOverflow")>0 then
		return true
	end
end

sgs.ai_skill_playerchosen.bachao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if call(self,"isEnemy",p) and call(self,"isWeak",p) and call(self,"damageIsEffective",p,"N",self.player) then
			return p
		end
	end
	if destlist[#destlist]==self.player and call(self,"getOverflow")>1 then
		return self.player
	end
end

sgs.ai_fill_skill.fuzhai = function(self,inclusive,request)
	local cards = call(self.player,"getCards","he")
	cards = call(self,"sortByUseValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if table.contains(self.toUse,c) or call(c,"getTypeId")~=3 then continue end
		local dc = call(self,"evaluateTurnConversion","fuzhai","ExNihilo",{name="ex_nihilo",skill="fuzhai",suit=6,number=0,subcards={call(c,"getEffectiveId")},can_recast=false},request)
		if call(dc,"isAvailable",self.player) then
			return dc
		end
		dc = call(self,"evaluateTurnConversion","fuzhai","Collateral",{name="collateral",skill="fuzhai",suit=6,number=0,subcards={call(c,"getEffectiveId")},can_recast=false},request)
		if call(dc,"isAvailable",self.player) then
			return dc
		end
	end
end

sgs.ai_fill_skill.dinglun = function(self)
	return parse(self,"@DinglunCard=.")
end

sgs.ai_skill_use_func["DinglunCard"] = function(card,use,self)
	use.card = card
	local destlist = sgs.QList2Table(call(self.room,"getAlivePlayers")) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
	local n = 0
    for _,p in sgs.list(destlist)do
		if use.to:length()<#destlist/2 and call(self,"isFriend",p) then
			n = n+call(p,"getHandcardNum")
			use.to:append(p)
		else
			n = n-call(p,"getHandcardNum")
		end
	end
	if n>0 then
		use.card = card
		return
	end
	n = 0
	use.to:clear()
    for _,p in sgs.list(destlist)do
		if use.to:length()<#destlist/2 and not call(self,"isEnemy",p) then
			use.to:append(p)
			n = n+call(p,"getHandcardNum")
		else
			n = n-call(p,"getHandcardNum")
		end
	end
	if n>0 then
		use.card = card
		return
	end
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if use.to:contains(p) or call(p,"getHandcardNum")<1 then continue end
		if use.to:length()<#destlist/2 then
			n = n+call(p,"getHandcardNum")
			use.to:append(p)
			if(n>0)then
				use.card = card
				break
			end
		end
	end
end

sgs.ai_use_value.DinglunCard = 5.4
sgs.ai_use_priority.DinglunCard = 2.2

sgs.ai_skill_playerchosen.jieli = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	if call(self,"isWeak") then
		call(self,"sort",destlist,nil,true)
		save_player(self,"jieli_to",destlist[1])
		return destlist[1]
	end
end

sgs.ai_skill_choice.jieli = function(self,choices,data)
	local items = choices:split("+")
	local use = call(data,"toCardUse")
	if call(use.card,"isDamageCard") then
		return items[1]
	elseif not call(self,"isFriend",saved_player(self,"jieli_to")) and saved_player(self,"jieli_to"):getHandcardNum()>call(self.player,"getHandcardNum") then
		return items[2]
	end
	return items[1]
end

sgs.ai_fill_skill.olquxi = function(self,inclusive,request)
	local cards = call(self.player,"getCards","h")
	cards = call(self,"sortByUseValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if table.contains(self.toUse,c) then continue end
		if call(c,"isKindOf","Jink") then
			if call(self.player,"getMark","olquxiBanJink-PlayClear")>0 then continue end
			local dc = call(self,"evaluateTurnConversion","olquxi","Dismantlement",{name="dismantlement",skill="olquxi",suit=6,number=0,subcards={call(c,"getEffectiveId")},can_recast=false},request)
			if call(dc,"isAvailable",self.player) then
				return dc
			end
		elseif call(c,"isKindOf","Peach") then
			if call(self.player,"getMark","olquxiBanPeach-PlayClear")>0 then continue end
			local dc = call(self,"evaluateTurnConversion","olquxi","Snatch",{name="snatch",skill="olquxi",suit=6,number=0,subcards={call(c,"getEffectiveId")},can_recast=false},request)
			if call(dc,"isAvailable",self.player) then
				return dc
			end
		end
	end
end

sgs.ai_skill_playerchosen.xinchuan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if call(self,"isFriend",p) and call(self,"canDraw",p) then
			return p
		end
	end
end

sgs.ai_fill_skill.oljinjin = function(self)
	for _,cn in sgs.list(cardnames(self,"TrickCard+^DelayedTrick"))do
		local dc = named(self,"oljinjin",cn,{})
		if call(dc,"isAvailable",self.player) then
			local d = call(self,"aiUseCard",dc)
			if d.card then
				save_targets(self,"oljinjin_to",d.to)
				sgs.ai_use_priority.OLJinjinCard = sgs.ai_use_priority[call(dc,"getClassName")]-2
				return parse(self,"@OLJinjinCard=.:"..cn)
			end
		end
	end
end

sgs.ai_skill_use_func["OLJinjinCard"] = function(card,use,self)
	use.to = targets(self,"oljinjin_to")
	use.card = card
end

sgs.ai_use_value.OLJinjinCard = 5.4
sgs.ai_use_priority.OLJinjinCard = 2.2

sgs.ai_guhuo_card.oljinjin = function(self,toname,class_name)
    if call(self,"getCardsNum",class_name)>0 then return end
	return proposal(self,"@OLJinjinCard=.:"..toname)
end

sgs.ai_skill_playerchosen.oljinjin = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	if call(self,"isFriend",destlist[#destlist]) and call(self,"canDraw",destlist[#destlist]) then
		return destlist[#destlist]
	end
	return self.player
end

sgs.ai_skill_playerchosen.quanyu2 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local use = tag(self,"quanyu2_data","CardUse","owner")
    for _,p in sgs.list(destlist)do
		if call(self,"canCanmou",p,use) then
			return p
		end
	end
end

sgs.ai_fill_skill.qiangang = function(self)
	return parse(self,"@QiangangCard=.")
end

sgs.ai_skill_use_func["QiangangCard"] = function(card,use,self)
	if #self.enemies>#self.friends/2 and property(self,self.player,"quanyuBf")~="" then
		use.card = card
	end
end

sgs.ai_use_value.QiangangCard = 5.4
sgs.ai_use_priority.QiangangCard = 7.2











sgs.ai_skill_invoke.juemou = function(self,data)
	return call(self,"canDraw")
end

sgs.ai_skill_invoke.fuzhan = function(self,data)
	local tp = call(data,"toPlayer")
	return call(self,"isFriend",tp) and call(tp,"getLostHp")>1 and call(self,"isWeak",tp)
end

sgs.ai_skill_use["@@juemou"] = function(self,prompt)
	call(self,"sort",self.enemies)
	call(self,"sort",self.friends,nil,true)
	for _,ep in sgs.list(self.enemies)do
		for i,fp in sgs.list(self.friends)do
			if call(fp,"canDiscard",ep,"he") and i<#self.friends/2 then
				local tps = {call(fp,"objectName"),call(ep,"objectName")}
				return response(self,"#juemouCard:.:->"..table.concat(tps,"+"))
			end
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		if call(self,"doDisCard",ep,"e") then
			local tps = {call(self.player,"objectName"),call(ep,"objectName")}
			return response(self,"#juemouCard:.:->"..table.concat(tps,"+"))
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if call(self,"doDisCard",ep,"e") then
			local tps = {call(self.player,"objectName"),call(ep,"objectName")}
			return response(self,"#juemouCard:.:->"..table.concat(tps,"+"))
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if call(self,"doDisCard",ep,"he") then
			local tps = {call(self.player,"objectName"),call(ep,"objectName")}
			return response(self,"#juemouCard:.:->"..table.concat(tps,"+"))
		end
	end
end

sgs.ai_skill_use["@@fengshang"]=function(self,prompt)local wire=select_fengshang(self,prompt);if wire then return response(self,wire)end end

-- extra-ai.lua1508 captures this exact source callback; native immutable alias
-- metadata controls presence and source identity across actual loader orders.
ai_audited_aliases.register{id='ai_skill_invoke.heg_guowu',registry='ai_skill_invoke',path={'heg_guowu'},canonical_registry='ai_skill_invoke',canonical_path={'guowu'},self_index=1}

-- Fixed OL3928 copies even after a false invoke; the finite helper retains
-- known nil or unknown without manufacturing a global function alias.
sgs.ai_skill_choice.olxuhe=function(self)
 if not ai_response_scalar_choices then ai_unsupported('Xuhe scalar lifecycle helper missing','olxuhe')end
 return ai_response_scalar_choices.answer(self,'olxuhe')
end
