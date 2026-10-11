-- Fixed tenyear_hc b6025acc source policy. Readonly proposals never grant payment authority.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("tenyear_hc fact unknown",k)end;return v end
local function __hc_value_call(o,k,...)if o==nil then error("attempt to index a nil value",0)end;if k=="getMark"and AIValue.isPlayer(o)then k="getStrategyMark"elseif k=="hasFlag"and AIValue.isPlayer(o)then k="getStrategyFlag"end;if type(o[k])~="function"then ai_unsupported("tenyear_hc method unavailable",k)end;return known(o[k](o,...),k)end
local function fact(self,k)return known(known(self.world.strategy_facts.tenyear_hc,"tenyear_hc facts")[k],k)end
local function visible(self,id)
 local c=self:getKnownCardById(id);if c then return c end
 local row=self.world.strategy_facts.round49_notified_faces
 if type(row)=="table"and row.pattern==self.request.pattern and type(row.cards)=="table"then
  local v=row.cards[tostring(id)];if type(v)=="table"and v.effective_id==id then return CardView.new(v)end
 end
 return known(nil,"disclosed current notified face")
end
-- Only the fixed notified physical callbacks use this per-call cache.
local notified_cards=setmetatable({},{__mode="k"})
local function notified_card(self,id)
 local key=self._hc_callback_key
 if key~="@@chuiti"and key~="@@boxuan"and key~="@@tanluan"then ai_unsupported("notified source scope missing","tenyear_hc")end
 local entry=notified_cards[self]
 if not entry or entry.request~=self.request then entry={request=self.request,cards={}};notified_cards[self]=entry end
 local c=entry.cards[id]
 if not c then c=self:getPreviewCardEvaluation(id);entry.cards[id]=c end
 return c
end
local function property(self,k)return known(known(self.world.strategy_facts.owner_skill_properties,"owner properties")[k],k)end
local function tag(self,k,kind)
 local r=fact(self,k);if r==false then return nil end
 if kind=="Player"then return known(self.room:findPlayerByObjectName(r,true),k)elseif kind=="IntList"or kind=="StringList"then return AIList.new(r)
 elseif kind=="CardUse"then local to=AIList.new({});for _,n in ipairs(r.to)do to:append(known(self.room:findPlayerByObjectName(n,true),k))end;return{from=r.from and self.room:findPlayerByObjectName(r.from,true),to=to,card=CardView.new(r.card)}
 elseif kind=="Damage"then return{from=r.from and self.room:findPlayerByObjectName(r.from,true),to=r.to and self.room:findPlayerByObjectName(r.to,true),card=r.card and CardView.new(r.card),damage=r.amount,nature=r.nature,chain=r.chain,transfer=r.transfer}
 else return r end
end
local function dummy_plan(value,extra,current)local u=AIUsePlan.new();u.isDummy=value~=false;u.extra_target=extra or 0;u.current_targets=current or {};return u end
local recipes=setmetatable({},{__mode="k"})
local function copy(t)local r={}for k,v in pairs(t)do if type(v)=="table"then r[k]=copy(v)else r[k]=v end end;return r end
local function clone(self,name,suit,number,skill)
 if type(suit)=="string"then skill=suit;suit=sgs.Card_NoSuit end
 name=name or"slash";suit=suit or sgs.Card_NoSuit;number=number or 0
 local spec={source_key=self._hc_callback_key or "tenyear_hc",name=name,skill=skill or"",suit=suit,number=number,subcards={}}
 local c
 if ({fengying=true,fuping=true,jingong=true,tenyearjingong=true,choulve=true,["@@choulve!"]=true})[spec.source_key]then c=self:evaluateOwnerViewAsCard(spec)
 elseif spec.skill==""and suit==sgs.Card_NoSuit and number==0 then c=self:getEvaluationCard(name)
 else c=self:evaluateOwnerViewAsCard(spec)end
 if c then recipes[c]=spec end;return c
end
local function mutate(self,c,field,v)
 if c==nil and ({fengying=true,fuping=true,jingong=true,tenyearjingong=true,choulve=true,["@@choulve!"]=true})[self._hc_callback_key]then error("attempt to index a nil value",0)end
 local spec=recipes[c];if not spec then ai_unsupported("source mutates card outside its owned readonly clone","tenyear_hc.clone")end
 spec=copy(spec)
 if field=="clear"then spec.subcards={}elseif field=="can_recast"then if self._hc_callback_key~="fuhui"or v~=false then ai_unsupported("readonly clone recast mutation requires scoped native contract",self._hc_callback_key)end;spec.can_recast=false elseif field=="add"then spec.subcards[#spec.subcards+1]=type(v)=="number"and v or __hc_value_call(v,"getEffectiveId")else spec[field]=v end
 local next=self:evaluateOwnerViewAsCard(spec);self:inheritLegacyCardIdentity(next,c);recipes[next]=spec;return next
end
local function ids(raw)local out={};if raw~="."and raw~=""then for n in raw:gmatch("[^+]+")do out[#out+1]=assert(tonumber(n))end end;return out end
local function printed_spec(text)
 local name,skill,suit,n,raw=text:match("^([%w_]+):([%w_]+)%[([^:]+):([^%]]+)%]=(.*)$");if not name then return nil end
 local suits={spade=sgs.Card_Spade,club=sgs.Card_Club,heart=sgs.Card_Heart,diamond=sgs.Card_Diamond,no_suit=sgs.Card_NoSuit,no_suit_red=sgs.Card_NoSuitRed,no_suit_black=sgs.Card_NoSuitBlack};local nums={A=1,J=11,Q=12,K=13}
 return{name=name,skill=skill,suit=known(suits[suit],"suit"),number=known(tonumber(n)or nums[n],"number"),subcards=ids(raw)}
end
local classes={['XiaosiCard']='xiaosi',['XingguCard']='xinggu',['QiangzhiZHCard']='qiangzhizh',['LibangCard']='libang',['CaizhuangCard']='caizhuang',['JijiaoCard']='jijiao',['JianjiYHCard']='jianjiyh',['TenyearLingyinCard']='tenyearlingyin',['JinJianheCard']='jinjianhe',['TenyearGueCard']='tenyeargue',['XiangmianCard']='xiangmian',['TenyearJueCard']='tenyearjue',['TenyearZhaohanCard']='tenyearzhaohan',['AnzhiCard']='anzhi',['JingzaoCard']='jingzao',['FengyingCard']='fengying',['CuichuanCard']='cuichuan',['KanjiCard']='kanji',['ShuaijieCard']='shuaijie',['TenyearBingjiCard']='tenyearbingji',['QianlongCard']='qianlong',['XiaowuCard']='xiaowu',['ShawuCard']='shawu',['FupingCard']='fuping',['WeilieCard']='weilie',['TuoxianCard']='tuoxian',['SushouCard']='sushou',['SuizhengCard']='suizheng',['KaijiCard']='kaiji',['XunjiCard']='xunji',['MiduCard']='midu',['YongbiCard']='yongbi',['TenyearQuanjianCard']='tenyearquanjian',['ShilieCard']='shilie',['ShilieGetCard']='shilieget',['AnliaoCard']='anliao',['GongsunCard']='gongsun',['ZhouxuanCard']='zhouxuan',['YingruiCard']='yingrui',['YujueCard']='yujue',['SecondYujueCard']='secondyujue',['SpNiluanCard']='spniluan',['WeiwuCard']='weiwu',['CixiaoCard']='cixiao',['ExtraCollateralCard']='extracollateral',['JieyinghCard']='jieyingh',['MinsiCard']='minsi',['JijingCard']='jijing',['DaojiCard']='daoji',['PingjianCard']='pingjian',['ShoufuCard']='shoufu',['ShoufuPutCard']='shoufuput',['TenyearSongciCard']='tenyearsongci',['YoulongCard']='youlong',['SecondZhanyiCard']='secondzhanyi',['SecondZhanyiViewAsBasicCard']='secondzhanyiviewasbasic',['ZunweiCard']='zunwei',['BazhanCard']='bazhan',['LiluCard']='lilu',['TianjiangCard']='tianjiang',['ZhurenCard']='zhuren',['OLFenxunCard']='olfenxun',['JinzhiCard']='jinzhi',['SecondJinzhiCard']='secondjinzhi',['XingzuoCard']='xingzuo',['MiaoxianCard']='miaoxian',['TenyearLianjiCard']='tenyearlianji',['OLLianjiCard']='ollianji',['MobileLianjiCard']='mobilelianji',['NewShuliangCard']='newshuliang',['GuanxuCard']='guanxu',['GuanxuChooseCard']='guanxuchoose',['GuanxuDiscardCard']='guanxudiscard',['TenyearJiezhenCard']='tenyearjiezhen',['SpCuoruiCard']='spcuorui',['SecondSpCuoruiCard']='secondspcuorui',['TiansuanCard']='tiansuan',['JuguanCard']='juguan',['QuxiCard']='quxi',['LiehouCard']='liehou',['TenyearShuheCard']='tenyearshuhe',['TenyearHuoshuiCard']='tenyearhuoshui',['TenyearQingchengCard']='tenyearqingcheng',['CuijianCard']='cuijian',['SecondCuijianCard']='secondcuijian',['QingtanCard']='qingtan',['ZhukouCard']='zhukou',['ZhuningCard']='zhuning',['PingxiangCard']='pingxiang',['ShouliCard']='shouli',['ShencaiCard']='shencai',['FuxieCard']='fuxie',['ShouxingCard']='shouxing',['PingzhiCard']='pingzhi',['YinluCard']='yinlu',['ThShuliangCard']='thshuliang',['PingluCard']='pinglu',['ZhengyueCard']='zhengyue',['WanchanCard']='wanchan',['ThWuyanCard']='thwuyan',['ThZhenguiCard']='thzhengui',['JichunCard']='jichun',['YanzuoCard']='yanzuo',['JiusiCard']='jiusi',['ManhouCard']='manhou',['TanluanCard']='tanluan',['WeitiCard']='weiti',['GuilinCard']='guilin',['ThMuzhenCard']='thmuzhen',['ChuanyuCard']='chuanyu',['GengduCard']='gengdu',['JikunCard']='jikun',['JieshiCard']='jieshi',['BizuCard']='bizu',['JilieCard']='jilie',['QuxianCard']='quxian',['ZuoyiCard']='zuoyi',['FuhuiCard']='fuhui',['TenyearMingfaCard']='tenyearmingfa'}
local function decode(text)
 local cl,raw=text:match("^@([%w_]+)=(.*)$");local user
 if cl then local costs,u=raw:match("^(.-):(.*)$");raw=costs or raw;user=u
 else cl,raw,user=text:match("^#([%w_]+):([^:]*):(.*)$");if cl then cl="#"..cl end end
 local sk=cl and classes[cl];if not sk then ai_unsupported("source prototype wire outside authored catalog","tenyear_hc")end
 return cl,sk,ids(raw),user~=""and user or nil
end
local function policy(self,text,request)
 if text:match("^%d+$")then return visible(self,tonumber(text))end
 local row=printed_spec(text);if row then local b=known(self:getEvaluationCard(row.name),"printed source prototype");return self:evaluateTurnConversion(row.skill,b:getClassName(),row,request)end
 local cl,sk,costs,user=decode(text);local c=self:evaluateTurnSkillCard(sk,cl,costs,request,user);recipes[c]={prototype=cl,skill=sk,subcards=costs,user=user};return c
end
local function response(self,text)
 if type(text)~="string"or text=="."or text==""then return text end
 local wire,tos=text:match("^(.-)%->(.*)$");wire=wire or text;local c
 if self.request.pattern=="@@diou"then
  local selected=printed_spec(wire)
  if selected and selected.skill=="_diou"then return self:materializeDiouSavedWire(wire,tos and tos:split("+")or{})end
 end
 if wire:match("^%d+$")then
  local entry=notified_cards[self];local id=tonumber(wire)
  if (self.request.pattern=="@@chuiti"or self.request.pattern=="@@boxuan"or self.request.pattern=="@@tanluan")then
   if not entry or entry.request~=self.request or not entry.cards[id]then ai_unsupported("selected notified physical identity missing","tenyear_hc")end
   c=self:materializeBorrowedSelectedCard(entry.cards[id],tos and tos:split("+")or{})
  else c=visible(self,id)end
 elseif wire:sub(1,1)=="@"or wire:sub(1,1)=="#"then
  if self.request.pattern=="@@sushou" and wire:match("^@SushouCard=") then
   if tos~=nil then ai_unsupported("Sushou source has no target suffix","sushou.notified_costs")end
   return self:bindSushouNotifiedCosts(wire)
  end
  local cl,sk,cs,u=decode(wire)
  if cl=="JieyinghCard" and #cs==0 and u==nil and self:getDecisionContext().jieyingh_question~=nil then
   -- A marked recipient need not own Jieyingh. Only the actual native question
   -- can issue this distinct receipt; never synthesize a skill instance.
   return{kind="use_card",card_spec=self:bindJieyinghQuestion(),targets=tos and tos:split("+")or{}}
  end
  c=self:bindSkillCard(sk,cs,nil,u,cl)
 else local row=known(printed_spec(wire),"source response wire");local base=known(self:getEvaluationCard(row.name),"response prototype");local pol=known(self:getConversionPolicy(base:getClassName()),"response policy");local entry
  local provider=(self.request.pattern=="@@diou"and row.skill=="_diou")and"diou"or(self.request.pattern=="@@zhuning"and row.skill=="_zhuning")and"zhuning"or row.skill
  for _,v in ipairs(pol.skills or{})do if v.skill_name==provider then entry=v;break end end
  c=known(self:resolveResponseConversion(row,known(entry,"response skill")),"response authority")
 end
 if AIValue.isConversion(c)then return{kind="use_card",card_spec=c:toCardSpec(),targets=tos and tos:split("+")or{}}end
 if __hc_value_call(c,"isVirtualCard")then ai_unsupported("selected physical response has no issued authority","tenyear_hc")end
 return{kind="use_card",card_id=__hc_value_call(c,"getEffectiveId"),targets=tos and tos:split("+")or{}}
end
local function proposal(v)
 if type(v)~="string"or v=="."or v==""then return v end
 local row=printed_spec(v);if row then return row end
 local cl,sk,cs,u=decode(v);return{legacy_class=cl,skill=sk,subcards=cs,user_string=u}
end
local function can_to(self,c,from,to,targets)
 if from:objectName()~=self.player:objectName()then ai_unsupported("foreign hypothetical targetFilter lacks public rule contract","tenyear_hc")end
 return self:cardTargetFilter(c,targets or{},to)
end
local function private_draw(self)ai_unsupported("source inspects undisclosed draw-pile faces","zhuide")end
local function source_description(self,name)return known(known(self.world.strategy_facts.card_descriptions,"public card descriptions")[name],name)end
local function extra_targets(self,c)return known(self:getEvaluationCandidate(c):getExtraTargetCount(),"source extra target modifier")end
local function residue(self,c)return known(c:getTargetModResidue(self.player),"source residue")end
local function pingjian_catalog(self)
 if type(ai_response_choice_continuity)~="function"then ai_unsupported("Pingjian source catalog host unavailable","pingjian.catalog")end
 local row=ai_response_choice_continuity{op="pingjian_catalog"}
 if AIUnsupported.is(row)then error(row,0)end
 if type(row)~="table"or row.known~=true or type(row.skills)~="table"or type(row.descriptions)~="table"then ai_unsupported("Pingjian fixed current catalog unavailable","pingjian.catalog")end
 for _,entry in ipairs(row.skills)do
  if type(entry)~="table"or type(entry.name)~="string"or(type(row.descriptions[entry.name])~="string"and row.descriptions[entry.name]~=false)then ai_unsupported("Pingjian catalog entry unavailable","pingjian.catalog")end
 end
 return row.skills,row.descriptions
end
local function pingjian_skill(self,name,rows)local text=rows[name];if text==false then return nil end;return{getDescription=function()return known(text,name)end}end
local function pingjian_play(self,name)return known(known(fact(self,"pingjian_enabled_at_play"),"temporary skill enabled facts")[name],name)end
local function state_encode(self,v)
 if v==nil then return{type="nil"}end
 if AIValue.isPlayer(v)then return{type="player",name=v:objectName()}end
 if AIValue.isCard(v)or AIValue.isConversion(v)then
  if recipes[v]then return{type="recipe",value=copy(recipes[v])}end
  if type(v.isEvaluationOnly)=="function"and v:isEvaluationOnly()then ai_unsupported("untracked readonly card cannot persist across snapshots","tenyear_hc state")end
  return{type="card",id=__hc_value_call(v,"getEffectiveId")}
 end
 if type(v)~="table"then return{type="scalar",value=v}end
 local t={type="table",value={}};for k,x in pairs(v)do if type(x)~="function"then t.value[k]=state_encode(self,x)end end;return t
end
local function state_decode(self,v)
 if v.type=="nil"then return nil elseif v.type=="scalar"then return v.value elseif v.type=="player"then return known(self.room:findPlayerByObjectName(v.name,true),"cached target")elseif v.type=="card"then return visible(self,v.id)
 elseif v.type=="recipe"then local r=v.value;if r.prototype then return policy(self,(r.prototype:sub(1,1)=="#"and(r.prototype..":"..(#r.subcards>0 and table.concat(r.subcards,"+")or".")..":"..(r.user or""))or("@"..r.prototype.."="..(#r.subcards>0 and table.concat(r.subcards,"+")or".")..(r.user and":"..r.user or""))))end
 local c=self:evaluateOwnerViewAsCard(r);recipes[c]=copy(r);return c
 elseif v.type=="table"then local t={};for k,x in pairs(v.value)do t[k]=state_decode(self,x)end;if#t>0 then return AIList.new(t)end;return t end
 ai_unsupported("invalid source observation cache","tenyear_hc")
end
local state_fields={'pjsk_to','tenyearbingjiUse','tenyearhuace_to','yanzuoUse',}
local function load_state(self)
 if self._hc_state_loaded then return end;self._hc_state_loaded=true
 for _,k in ipairs(state_fields)do local r,ok=self:getStrategyMemory("tenyear_hc."..k);if ok then self[k]=state_decode(self,r)end end
end
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~="table"then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function save_state(self)
 for _,k in ipairs(state_fields)do local prior,present=self:getStrategyMemory("tenyear_hc."..k);local v=self[k]
  if present or v~=nil then local encoded=state_encode(self,v);if not present or not same(prior,encoded)then self:setStrategyMemory("tenyear_hc."..k,encoded)end end
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
 self:setStrategyMemory("tenyear_hc.mark:"..key,value)
end
local function observation_mark(self,key)
 local value,present=self:getStrategyMemory("tenyear_hc.mark:"..key)
 if present then return value end
 return __hc_value_call(self.player,"getMark",key)
end
local function pattern_card(self,name)
 if type(ai_sample_pattern_log_name)~="function"then ai_unsupported("public PatternsCard sampling endpoint missing",name)end
 local result=ai_sample_pattern_log_name(name)
 if type(result)~="table"or result.kind~="pattern_log_name"or result.pattern~=name or type(result.found)~="boolean"then ai_unsupported("invalid PatternsCard sample",name)end
 if not result.found then return nil end
 return CardView.new(known(result.printed_card,"sampled printed descriptor"))
end

sgs.ai_skill_invoke.yiyong = function(self,data)
	local target = data:toPlayer()
	if target then
		return self:isEnemy(target) or not self:isFriend(target) and not self:isWeak(target)
	end
end

sgs.ai_skill_cardask["@cuijin-discard"] = function(self,data,pattern)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    cards = self:sortByKeepValue(cards)
	local use = data:toCardUse()
   	for _,c in sgs.list(cards)do
    	if self.player:canDiscard(self.player,__hc_value_call(c,"getEffectiveId")) then
			for _,p in sgs.list(use.to)do
				if getCardsNum("Jink",p,self.player)<1 and self:isEnemy(p)
				then return __hc_value_call(c,"getEffectiveId") end
			end
			for _,p in sgs.list(use.to)do
				if getCardsNum("Jink",p,self.player)>0 and self:isEnemy(use.from)
				then return __hc_value_call(c,"getEffectiveId") end
			end
		end
	end
    return "."
end

sgs.ai_skill_use["@@jueman!"] = function(self,prompt)
	local cn = prompt:split(":")[2]
	cn = clone(self,cn)
	local tos = {}
	if cn then
		cn = mutate(self,cn,"skill","_jueman")
		local d = self:aiUseCard(cn)
		if d.card then
			for _,p in sgs.list(d.to)do
				table.insert(tos,p:objectName())
			end
			return cn:getLegacyStringKey().."->"..table.concat(tos,"+")
		end
		if cn:targetFixed() then return cn:getLegacyStringKey() end
		local players = self.room:getAlivePlayers()
		players = self:sort(players,"handcard")
		for _,p in sgs.list(players)do
			if self:isEnemy(p) and __hc_value_call(cn,"isDamageCard")
			and self.player:canUse(cn,p,true)
			then table.insert(tos,p:objectName()) end
		end
		if #tos>0 then
			return cn:getLegacyStringKey().."->"..table.concat(tos,"+")
		end
	end
end

sgs.ai_fill_skill["xiaosi"]=function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = self:sortByUseValue(cards)
  	for _,c in sgs.list(cards)do
		if __hc_value_call(c,"isKindOf","BasicCard")
		and __hc_value_call(c,"isAvailable",self.player) then
			local d = self:aiUseCard(c)
			if d.card then
				return policy(self,"@XiaosiCard="..__hc_value_call(c,"getEffectiveId"))
			end
		end
	end
  	for d,c in sgs.list(cards)do
		if __hc_value_call(c,"isKindOf","BasicCard")
		and __hc_value_call(c,"isAvailable",self.player) then
			return policy(self,"@XiaosiCard="..__hc_value_call(c,"getEffectiveId"))
		end
	end
  	for d,c in sgs.list(cards)do
		if __hc_value_call(c,"isKindOf","BasicCard")
		and __hc_value_call(self.player,"getHandcardNum")>2 then
			return policy(self,"@XiaosiCard="..__hc_value_call(c,"getEffectiveId"))
		end
	end
end

sgs.ai_skill_use_func["XiaosiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHandcardNum")>0
		and getKnownCard(self.player,ep,"BasicCard")>0 then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		local kc = getKnownCards(self.player,ep)
		for _,c in sgs.list(kc)do
			if __hc_value_call(c,"isKindOf","BasicCard")
			and __hc_value_call(c,"isAvailable",self.player) then
				d = self:aiUseCard(c)
				if d.card then
					use.card = card
					use.to:append(ep)
					return
				end
			end
		end
	end
	for _,ep in sgs.qlist(self.room:getOtherPlayers(self.player))do
		local kc = getKnownCards(self.player,ep)
		for _,c in sgs.list(kc)do
			if __hc_value_call(c,"isKindOf","BasicCard")
			and __hc_value_call(c,"isAvailable",self.player) then
				d = self:aiUseCard(c)
				if d.card then
					use.card = card
					use.to:append(ep)
					return
				end
			end
		end
	end
	for _,ep in sgs.qlist(self.room:getOtherPlayers(self.player))do
		local kc = getKnownCards(self.player,ep)
		for _,c in sgs.list(kc)do
			if __hc_value_call(c,"isKindOf","BasicCard")
			and __hc_value_call(c,"isAvailable",self.player) then
				use.card = card
				use.to:append(ep)
				return
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHandcardNum")>0 then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.XiaosiCard = 9.4
sgs.ai_use_priority.XiaosiCard = 7.8

sgs.ai_skill_discard.xiaosi = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local to = tag(self,"XiaosiFrom","Player")
   	for _,c in sgs.list(cards)do
   		if #to_cards>=min then break end
		if __hc_value_call(c,"getTypeId")~=1 then continue end
		if self:isFriend(to) then
			if __hc_value_call(c,"isAvailable",to) then
				table.insert(to_cards,__hc_value_call(c,"getEffectiveId"))
			end
		else
			if not __hc_value_call(c,"isAvailable",to) then
				table.insert(to_cards,__hc_value_call(c,"getEffectiveId"))
			end
		end
	end
   	for _,c in sgs.list(cards)do
   		if #to_cards>=min then break end
		if __hc_value_call(c,"getTypeId")~=1 then continue end
		table.insert(to_cards,__hc_value_call(c,"getEffectiveId"))
	end
	return to_cards
end

sgs.ai_skill_use["@@xiaosi"] = function(self,prompt)
	local cn = property(self,"XiaosiCards"):split("+")
	local tos = {}
	if #cn>0 then
		local cs = {}
		for _,t in sgs.list(cn)do
			table.insert(cs,policy(self,t))
		end
		cs = self:sortByUseValue(cs)
		for _,c in sgs.list(cs)do
			if __hc_value_call(c,"isAvailable",self.player) then
				local d = self:aiUseCard(c)
				if d.card then
					for _,p in sgs.list(d.to)do
						table.insert(tos,p:objectName())
					end
					if __hc_value_call(c,"canRecast") and d.to:length()<1 then continue end
					return c:getLegacyStringKey().."->"..table.concat(tos,"+")
				end
			end
		end
	end
end

sgs.ai_skill_invoke.tenyearqingren = function(self,data)
	return true
end

sgs.ai_skill_use["@@xinggu"] = function(self,prompt)
	for _,id in sgs.list(self.player:getPile("xinggu"))do
		local c = visible(self,id)
		if __hc_value_call(c,"getTypeId")~=3 then continue end
		if #self:poisonCards({c})>0 then
			for _,p in sgs.list(self.enemies)do
				local i = known(c:getEquipSlot(),"equipment slot")
				if p:hasEquipArea(i) then
					return "@XingguCard="..id.."->"..p:objectName()
				end
			end
		else
			for _,p in sgs.list(self.friends_noself)do
				local i = known(c:getEquipSlot(),"equipment slot")
				if p:hasEquipArea(i) then
					i = p:getEquip(i)
					if i and #self:poisonCards({i})<1 then continue end
					return "@XingguCard="..id.."->"..p:objectName()
				end
			end
		end
	end
end

sgs.ai_skill_invoke.hongji = function(self,data)
	local to = BeMan(self.room,data:toString():split(":")[2])
    return to and self:isFriend(to)
end

sgs.ai_skill_invoke.daili = function(self,data)
    if __hc_value_call(self.player,"faceUp") then
		return self:canDraw() and (self:isWeak() or __hc_value_call(self.player,"getHandcardNum")<3)
	else
		return self:canDraw()
	end
end

sgs.ai_skill_invoke.pitian = function(self,data)
    return self:canDraw()
end

sgs.ai_fill_skill.qiangzhizh = function(self)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHp")<2 and #cards>3
		and self:damageIsEffective(ep,"N",self.player) then
			local pc = {}
			for _,c in sgs.list(cards)do
				if #pc>=3 then break end
				table.insert(pc,__hc_value_call(c,"getEffectiveId"))
			end
			return policy(self,"@QiangzhiZHCard="..table.concat(pc,"+"))
		end
	end
	return #cards>0 and policy(self,"@QiangzhiZHCard="..__hc_value_call(cards[1],"getEffectiveId"))
end

sgs.ai_skill_use_func["QiangzhiZHCard"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself,"card",true)
	for _,ep in sgs.list(self.friends_noself)do
		local pc = self:poisonCards("e",ep)
		if #pc>1 then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHp")<2 and card:subcardsLength()>=3
		and self:damageIsEffective(ep,"N",self.player) then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self:sort(self.room:getOtherPlayers(self.player),"card"))do
		if ep:getCardCount()+card:subcardsLength()>3 and not self:isFriend(ep)
		and self:doDisCard(ep,"he") then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.QiangzhiZHCard = 5.4
sgs.ai_use_priority.QiangzhiZHCard = 5.8

sgs.ai_skill_askforyiji.libang = function(self,card_ids,targets)
	for _,p in sgs.list(targets)do
		if self:isFriend(p) then
			local cards = {}
			for c,id in sgs.list(card_ids)do
				table.insert(cards,visible(self,id))
			end
			cards = self:sortByUseValue(cards)
			return p,__hc_value_call(cards[1],"getEffectiveId")
		end
	end
	for _,p in sgs.list(targets)do
		if not self:isEnemy(p) then
			local cards = {}
			for c,id in sgs.list(card_ids)do
				table.insert(cards,visible(self,id))
			end
			cards = self:sortByUseValue(cards)
			return p,__hc_value_call(cards[1],"getEffectiveId")
		end
	end
end

sgs.ai_skill_use["@@libang"] = function(self,prompt)
	local d = clone(self)
	d = mutate(self,d,"skill","_libang")
	local use = self:aiUseCard(d)
	if use.card and use.to then
		local tos = {}
		for _,p in sgs.list(use.to)do
			table.insert(tos,p:objectName())
		end
		return d:getLegacyStringKey()"->"..table.concat(tos,"+")
	end
end

sgs.ai_fill_skill.libang = function(self)
    local cards = self.player:getCards("he")
    cards = self:sortByUseValue(cards,true,true) -- 按保留值排序
	return #cards>0 and policy(self,"@LibangCard="..__hc_value_call(cards[1],"getEffectiveId"))
end

sgs.ai_skill_use_func["LibangCard"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself,"card",true)
	for _,ep in sgs.list(self.friends_noself)do
		if use.to:length()<1
		and self:doDisCard(ep,"e")
		then use.to:append(ep) end
	end
	for _,ep in sgs.list(self:sort(self.room:getOtherPlayers(self.player),"card"))do
		if use.to:length()<2 and not self:isFriend(ep)
		and self:doDisCard(ep,"he")
		then use.to:append(ep) end
	end
	if use.to:length()>1
	then use.card = card end
end

sgs.ai_use_value.LibangCard = 5.4
sgs.ai_use_priority.LibangCard = 5.8

sgs.ai_skill_invoke.huayi = function(self,data)
    return true
end

sgs.ai_fill_skill.caizhuang = function(self)
	local valid = {}
    local cards = self.player:getCards("he")
    cards = self:sortByUseValue(cards,true) -- 按保留值排序
	for i,h in sgs.list(cards)do
		if #valid>#cards/2 then break end
		local can = true
		for _,id in sgs.list(valid)do
			if __hc_value_call(h,"getSuit")==visible(self,id):getSuit()
			then can = false break end
		end
		if can then
			table.insert(valid,__hc_value_call(h,"getEffectiveId"))
		end
	end
	local suits = {}
	for _,h in sgs.list(self.player:getCards("h"))do
		if table.contains(valid,__hc_value_call(h,"getEffectiveId")) or table.contains(suits,__hc_value_call(h,"getSuit")) then continue end
		table.insert(suits,__hc_value_call(h,"getSuit"))
	end
	return #valid>#suits and policy(self,"@CaizhuangCard="..table.concat(valid,"+"))
end

sgs.ai_skill_use_func["CaizhuangCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.CaizhuangCard = 7.4
sgs.ai_use_priority.CaizhuangCard = 5.8

-- R51: membership is PUBLIC discard absence/presence, not unknown private place.
-- The native producer validates the current public pile's mapping, object and face.
local function jijiao_in_discard(self,id)
 local rows=fact(self,"jijiao_discard")
 local v=rows[tostring(id)]
 if type(v)~="boolean"then return ai_unsupported("jijiao_discard","current public discard membership is unknown")end
 return v
end
local function jijiao_discard_card(self,id)
 for _,card in sgs.list(self.room:getDiscardCards())do
  if card:getEffectiveId()==id then return card end
 end
 return ai_unsupported("jijiao_discard","authenticated public discard face is absent")
end

sgs.ai_fill_skill.jijiao = function(self,inclusive,request)
	local ids = tag(self,"JijiaoRecord","IntList")
	if ids:length()<2 then return end
	return #self:getPriorTurnUseCards()<1 and policy(self,"@JijiaoCard=.",request)
end

sgs.ai_skill_use_func["JijiaoCard"] = function(card,use,self)
	local ids = tag(self,"JijiaoRecord","IntList")
	local n,xt = 0,0
	for _,id in sgs.list(ids)do
		if jijiao_in_discard(self,id) then
			n = n+1
			if self:aiUseCard(jijiao_discard_card(self,id)).card
			then xt = xt+1 end
			if xt>ids:length()/2
			and use.to then
				use.card = card
				use.to:append(self.player)
				return
			end
		end
	end
	if n<3 then return end
	self.friends = self:sort(self.friends,"card",true)
	for _,ep in sgs.list(self.friends)do
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.JijiaoCard = 6.4
sgs.ai_use_priority.JijiaoCard = 6.8

sgs.ai_skill_discard.huizhi = function(self,max,min)
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if __hc_value_call(p,"getHandcardNum")<__hc_value_call(self.player,"getHandcardNum") then continue end
		local cards = self.player:getCards("h")
		local to_cards = {}
		for _,h in sgs.list(self:sortByKeepValue(cards))do
			if #to_cards>min or #to_cards>cards:length()/2 then break end
			table.insert(to_cards,__hc_value_call(h,"getEffectiveId"))
		end
		return to_cards
	end
	return {}
end

sgs.ai_skill_choice.yuanmo = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"add") then
		local n = 0
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if __hc_value_call(self.player,"distanceTo",p)-1==__hc_value_call(self.player,"getAttackRange")
			and self:doDisCard(p,nil,true) then
				n = n+1
			end
		end
		if n>1 or n>0 and __hc_value_call(self.player,"getAttackRange")<2
		then return "add" end
	end
	if table.contains(items,"reduce")
	and __hc_value_call(self.player,"getAttackRange")>1
	then return "reduce" end
	return "cancel"
end

sgs.ai_skill_use["@@jianjiyh"] = function(self,prompt)
	local d = clone(self)
	d = mutate(self,d,"skill","_jianjiyh")
	local use = self:aiUseCard(d)
	if use.card and use.to then
		local tos = {}
		for _,p in sgs.list(use.to)do
			table.insert(tos,p:objectName())
		end
		return d:getLegacyStringKey().."->"..table.concat(tos,"+")
	end
end

sgs.ai_fill_skill.jianjiyh = function(self)
	return policy(self,"@JianjiYHCard=.")
end

sgs.ai_skill_use_func["JianjiYHCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"card")
	for _,ep in sgs.list(self.enemies)do
		if ep:getCardCount()>0 and use.to:length()<__hc_value_call(self.player,"getAttackRange") then
			if use.to:length()<1 then
				use.card = card
				use.to:append(ep)
				continue
			end
			for _,p in sgs.list(use.to)do
				if p:isAdjacentTo(ep) then
					use.to:append(ep)
					break
				end
			end
		end
	end
	self.friends = self:sort(self.friends,"card",true)
	for _,ep in sgs.list(self.friends)do
		if ep:getCardCount()>4 and use.to:length()>0
		and use.to:length()<__hc_value_call(self.player,"getAttackRange") then
			for _,p in sgs.list(use.to)do
				if p:isAdjacentTo(ep) then
					use.to:append(ep)
					break
				end
			end
		end
	end
	for _,ep in sgs.list(self:sort(self.room:getAlivePlayers(),"card"))do
		if ep:getCardCount()>0 and not self:isFriend(ep)
		and use.to:length()<__hc_value_call(self.player,"getAttackRange")
		and not use.to:contains(ep) then
			if use.to:length()<1 then
				use.card = card
				use.to:append(ep)
				continue
			end
			for _,p in sgs.list(use.to)do
				if p:isAdjacentTo(ep) then
					use.to:append(ep)
					break
				end
			end
		end
	end
end

sgs.ai_use_value.JianjiYHCard = 3.4
sgs.ai_use_priority.JianjiYHCard = 9.8

sgs.ai_skill_choice.xiangshuzk = function(self,choices,data)
	local items = choices:split("+")
	local to = data:toPlayer()
	if (not self:isFriend(to) or self:doDisCard(to,"ej"))
	and __hc_value_call(to,"getHandcardNum")<=7 then
		if __hc_value_call(to,"getHandcardNum")>3 then
			return tostring(__hc_value_call(to,"getHandcardNum")-2)
		else
			return tostring(__hc_value_call(to,"getHandcardNum")-1)
		end
	end
	return "cancel"
end

sgs.ai_skill_askforag.fozong = function(self,card_ids)
	if not self:isEnemy(self.room:getCurrent()) then
		local cards = {}
		for c,id in sgs.list(card_ids)do
			table.insert(cards,visible(self,id))
		end
		cards = self:sortByUseValue(cards)
		return __hc_value_call(cards[1],"getEffectiveId")
	end
	return -1
end

sgs.ai_skill_playerchosen.cansi = function(self,players)
	local destlist = self:sort(players,"card")
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:hasTrickEffective(clone(self),target,self.player)
		and self:hasTrickEffective(clone(self,"duel"),target,self.player)
		and self:hasTrickEffective(clone(self,"fire_attack"),target,self.player)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:hasTrickEffective(clone(self,"duel"),target,self.player)
		and self:hasTrickEffective(clone(self,"fire_attack"),target,self.player)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:hasTrickEffective(clone(self,"duel"),target,self.player)
		and self:hasTrickEffective(clone(self,"fire_attack"),target,self.player)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
    return destlist[1]
end

sgs.ai_skill_use["@@saowei"] = function(self,prompt)
	local d = clone(self)
	d = mutate(self,d,"skill","saowei")
	for _,h in sgs.list(self:sortByUseValue(self.player:getHandcards(),true,true))do
		if h:hasTip("qrasai") then
			d = mutate(self,d,"add",h)
			break
		end
	end
	local use = self:aiUseCard(d)
	if use.card and use.to then
		local tos = {}
		for _,p in sgs.list(use.to)do
			table.insert(tos,p:objectName())
		end
		return d:getLegacyStringKey().."->"..table.concat(tos,"+")
	end
end

sgs.ai_skill_invoke.aishou = function(self,data)
    return self:canDraw()
end

sgs.ai_skill_discard.jinjin = function(self,max,min)
	local to_cards = {}
	local damage = tag(self,"JinjinData","Damage")
	if self:isEnemy(damage.from) and min<self.player:getCardCount()/2 then
		local cards = self.player:getCards("he")
		for _,hcard in sgs.list(self:sortByKeepValue(cards))do
			if #to_cards>=min then break end
			table.insert(to_cards,__hc_value_call(hcard,"getEffectiveId"))
		end
	end
	return to_cards
end

sgs.ai_skill_invoke.jinjin = function(self,data)
    return __hc_value_call(self.player,"getHp")>__hc_value_call(self.player,"getHandcardNum")
end

sgs.ai_skill_discard.haochong = function(self,max,min)
	local to_cards = {}
	if min<2 then
		local cards = self.player:getCards("h")
		for _,hcard in sgs.list(self:sortByKeepValue(cards))do
			if #to_cards>=min then break end
			table.insert(to_cards,__hc_value_call(hcard,"getEffectiveId"))
		end
	end
	return to_cards
end

sgs.ai_skill_invoke.haochong = function(self,data)
    return self:canDraw()
end

sgs.ai_fill_skill.tenyearlingyin = function(self)
	local valid = {}
    local cards = self.player:getCards("he")
    cards = self:sortByUseValue(cards,true,true) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if __hc_value_call(h,"isKindOf","Weapon")
		or __hc_value_call(h,"isKindOf","Armor") then
			local d = clone(self,"duel")
			d = mutate(self,d,"skill","tenyearlingyin")
			d = mutate(self,d,"add",h)
			table.insert(valid,d)
		end
	end
	return #valid>0 and valid
end

sgs.ai_skill_use["@@tenyearlingyin"] = function(self,prompt)
	local valid = {}
    local cards1,cards2 = {},{}
	for _,id in sgs.list(self.player:getPile("thrjwywang"))do
		local c = visible(self,id)
		if #cards1<1 or cards1[1]:getColor()==c:getColor()
		then table.insert(cards1,c)
		else table.insert(cards2,c) end
	end
	local n = __hc_value_call(self.player,"getMark","tenyearlingyin_lun-PlayClear")
	if #cards1<=n
	then
		for _,c in sgs.list(cards1)do
			table.insert(valid,__hc_value_call(c,"getEffectiveId"))
		end
		set_observation_mark(self,"lingyin_valid",observation_mark(self,"lingyin_valid")+#valid)
		return "@TenyearLingyinCard="..table.concat(valid,"+")
	end
	if #cards2<=n and #cards2>0 then
		for _,c in sgs.list(cards2)do
			table.insert(valid,__hc_value_call(c,"getEffectiveId"))
		end
		set_observation_mark(self,"lingyin_valid",observation_mark(self,"lingyin_valid")+#valid)
		return "@TenyearLingyinCard="..table.concat(valid,"+")
	end
	for _,c in sgs.list(cards1)do
		if #valid>=n then break end
		table.insert(valid,__hc_value_call(c,"getEffectiveId"))
	end
	set_observation_mark(self,"lingyin_valid",observation_mark(self,"lingyin_valid")+#valid)
	return "@TenyearLingyinCard="..table.concat(valid,"+")
end

sgs.ai_skill_playerchosen.tenyearliying = function(self,players)
	local destlist = self:sort(players,"hp")
	local n = observation_mark(self,"lingyin_valid")
	set_observation_mark(self,"lingyin_valid",0)
	if n>1 then return end
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:canDraw(target)
		then return target end
	end
end

sgs.ai_skill_invoke.tenyearwangyuan = function(self,data)
    return true
end

sgs.ai_fill_skill.jinjianhe = function(self)
	local valid = {}
    local cards = self.player:getCards("he")
    cards = self:sortByUseValue(cards,true) -- 按保留值排序
	for i,h1 in sgs.list(cards)do
		for n,h2 in sgs.list(cards)do
			if i==n then continue end
			if h1:sameNameWith(h2)
			or __hc_value_call(h1,"getTypeId")==3 and __hc_value_call(h2,"getTypeId")==3 then
				table.insert(valid,__hc_value_call(h1,"getEffectiveId"))
				table.insert(valid,__hc_value_call(h2,"getEffectiveId"))
				return policy(self,"@JinJianheCard="..table.concat(valid,"+"))
			end
		end
	end
end

sgs.ai_skill_use_func["JinJianheCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"card")
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getMark","jinjianheTarget-PlayClear")<1 then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self:sort(self.room:getAlivePlayers(),"card"))do
		if __hc_value_call(ep,"getMark","jinjianheTarget-PlayClear")<1 and not self:isFriend(ep) then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.JinJianheCard = 3.4
sgs.ai_use_priority.JinJianheCard = 4.8

sgs.ai_use_revises.jinbihun = function(self,card,use)
	if not card:targetFixed()
	and __hc_value_call(self.player,"getHandcardNum")-1>__hc_value_call(self.player,"getMaxCards") then
		if __hc_value_call(card,"isKindOf","BasicCard")
		or __hc_value_call(card,"isKindOf","SingleTargetTrick") then
			for _,p in sgs.list(self.friends_noself)do
				if can_to(self,card,self.player,p) then
					use.card = card
					use.to:append(p)
					return
				end
			end
			return false
		end
	end
end

sgs.ai_skill_cardchosen.tenyearluochong = function(self,who,flags,method)
	if __hc_value_call(who,"getMark","luochongChosen-Clear")<2 then
		for _,c in sgs.list(who:getCards("ej"))do
			if self:doDisCard(who,__hc_value_call(c,"getEffectiveId")) then
				self:addStrategyPlayerMark(who,"luochongChosen-Clear",1)
				return __hc_value_call(c,"getEffectiveId")
			end
		end
		for _,p in sgs.list(self.room:getOtherPlayers(who))do
			if __hc_value_call(p,"getMark","luochongChosen-Clear")<1
			and self:doDisCard(p,"ej")
			then return -1 end
		end
		if who:objectName()==self.player:objectName() then
			if __hc_value_call(who,"getMark","luochongChosen-Clear")>0
			then return -1
			else
				self:addStrategyPlayerMark(who,"luochongChosen-Clear",1)
				return self:getCardRandomly(who,"h")
			end
		end
		if self:doDisCard(who,"h")
		and __hc_value_call(who,"getMark","luochongChosen-Clear")<2 then
			self:addStrategyPlayerMark(who,"luochongChosen-Clear",1)
			return self:getCardRandomly(who,"h")
		end
	end
	return -1
end

sgs.ai_skill_playerchosen.tenyearluochong = function(self,players)
	local destlist = self:sort(players,"hp")
	for _,target in sgs.list(destlist)do
		if self:isFriend(target) and __hc_value_call(target,"getMark","luochongChosen-Clear")<1
		and self:doDisCard(target,"ej")
		then return target end
	end
	if known(self.world.strategy_facts.draw_pile_count,"public draw pile count")>80
	and __hc_value_call(self.player,"hasSkill","tenyearaichen")
	and __hc_value_call(self.player,"getMark","luochongChosen-Clear")<1
	and players:contains(self.player)
	then return self.player end
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target) and __hc_value_call(target,"getMark","luochongChosen-Clear")<1
		and self:doDisCard(target,"ej")
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isFriend(target) and __hc_value_call(target,"getMark","luochongChosen-Clear")<1
		and self:doDisCard(target,"hej")
		then return target end
	end
end

sgs.ai_skill_discard.tenyearjinjie = function(self,max,min)
	local to_cards = {}
    local to = self.room:getCurrent()
	if self:isEnemy(to)
	and self:hasTrickEffective(clone(self),to,self.player) then
		local cards = self.player:getCards("h")
		for _,hcard in sgs.list(self:sortByKeepValue(cards))do
			if #to_cards>=min then break end
			table.insert(to_cards,__hc_value_call(hcard,"getEffectiveId"))
		end
	end
	return to_cards
end

sgs.ai_skill_invoke.tenyearsigong = function(self,data)
    local to = self.room:getCurrent()
	if self:isEnemy(to)
	and self:hasTrickEffective(clone(self),to,self.player)
	then return true end
end

sgs.ai_guhuo_card.tenyeargue = function(self,cname,class_name)
	local sj = 0
	for _,h in sgs.list(self.player:getCards("h"))do
		if __hc_value_call(h,"isKindOf","Slash")
		or __hc_value_call(h,"isKindOf","Jink")
		then sj = sj+1 end
	end
	return sj<2 and "@TenyearGueCard=.:"..cname
end

sgs.ai_skill_playerschosen.tenyearyuguan = function(self,players,x,n)
	local destlist = players
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	local tos = {}
	for _,to in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isFriend(to) and __hc_value_call(to,"getMaxHp")>__hc_value_call(to,"getHandcardNum")
		then table.insert(tos,to) end
	end
	for _,to in sgs.list(destlist)do
		if #tos>=x then break end
		if not table.contains(tos,to)
		then table.insert(tos,to) end
	end
	return tos
end

sgs.ai_skill_invoke.tenyearyuguan = function(self,data)
	local lh = __hc_value_call(self.player,"getLostHp")-1
	if lh>0 then
		local n = math.max(0,(__hc_value_call(self.player,"getMaxHp")-1)-__hc_value_call(self.player,"getHandcardNum"))
		if n>0 then lh = lh-1 end
		self.friends_noself = self:sort(self.friends_noself,"handcard")
		for _,p in sgs.list(self.friends_noself)do
			if lh<1 then break end
			local x = math.max(0,__hc_value_call(p,"getMaxHp")-__hc_value_call(p,"getHandcardNum"))
			if x>0 then lh = lh-1 n = n+x end
		end
		return lh<1 and n>2
	end
end

sgs.ai_skill_playerchosen.tenyearxuewei = function(self,players)
	local destlist = self:sort(players,"hp")
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:isWeak(target)
		then return target end
	end
	return self.player
end

sgs.ai_fill_skill.xiangmian = function(self)
	return policy(self,"@XiangmianCard=.")
end

sgs.ai_skill_use_func["XiangmianCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard",true)
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getMark","xiangmianTarget-Keep")<1 then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.XiangmianCard = 3.4
sgs.ai_use_priority.XiangmianCard = 9.8

sgs.ai_skill_use["@@tenyearjue"] = function(self,prompt)
	local use = dummy_plan(true,99)
	use = self:aiUseCard(clone(self),use)
	if use.card and use.to then
		for _,p in sgs.list(use.to)do
			if __hc_value_call(p,"getHp")==__hc_value_call(p,"getMaxHp")
			then return "@TenyearJueCard=.->"..p:objectName() end
		end
	end
end

sgs.ai_skill_discard.tenyearjinjie = function(self,max,min)
	local to_cards = {}
	local dy = self.room:getCurrentDyingPlayer()
	if not (dy and self:isFriend(dy)) then return {} end
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min then break end
		table.insert(to_cards,__hc_value_call(h,"getEffectiveId"))
	end
	return to_cards
end

sgs.ai_skill_invoke.tenyearjinjie = function(self,data)
	local to = BeMan(self.room,data:toString():split(":")[2])
    return to and self:isFriend(to)
end

sgs.ai_skill_use["@@tenyearzhaohan!"] = function(self,prompt)
	local valid,to = {},nil
	for _,p in sgs.list(self.friends_noself)do
		if p:isKongcheng() and not self:needKongcheng(p,true)
		then to = p break end
	end
    local cards = self.player:getCards("h")
    cards = self:sortByUseValue(cards,true) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if #valid>=2 then break end
    	table.insert(valid,__hc_value_call(h,"getEffectiveId"))
	end
	if #valid<2 then return end
	return "@TenyearZhaohanCard="..table.concat(valid,"+").."->"..to:objectName()
end

sgs.ai_skill_choice.tenyearzhaohan = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"give") then
		for _,p in sgs.list(self.friends_noself)do
			if p:isKongcheng()
			and not self:needKongcheng(p,true)
			then return "give" end
		end
	end
	return "discard"
end

sgs.ai_skill_invoke.tenyearzhaohan = function(self,data)
    return self:canDraw()
end

sgs.ai_skill_choice.juying = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"cishu")
	then return "cishu"
	elseif table.contains(items,"draw")
	and (__hc_value_call(self.player,"getHp")>1 or self:isWeak())
	then return "draw" end
	if table.contains(items,"maxcards")
	and 4-#items<__hc_value_call(self.player,"getHp")
	and self:getOverflow()>0 then
		return "maxcards"
	end
	return "cancel"
end

sgs.ai_skill_playerchosen.anzhi = function(self,players)
	local destlist = self:sort(players,"card")
	for _,target in sgs.list(destlist)do
		if self:isFriend(target) and self:canDraw(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	self:sourceImmediateEffect("anzhi","write",self.player,"ai_anzhi-PlayClear")
end

sgs.ai_fill_skill.anzhi = function(self)
	return (__hc_value_call(self.player,"getMark","&xialei_watch-Clear")>1 or #self:getPriorTurnUseCards()<1)
	and self:sourceImmediateEffect("anzhi","read",self.player,"ai_anzhi-PlayClear")<1
	and policy(self,"@AnzhiCard=.")
end

sgs.ai_skill_use_func["AnzhiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.AnzhiCard = 3.4
sgs.ai_use_priority.AnzhiCard = 9.8

sgs.ai_skill_invoke.anzhi = function(self,data)
    return __hc_value_call(self.player,"getMark","&xialei_watch-Clear")>1 or #self:getPriorTurnUseCards()<1
end

sgs.ai_skill_invoke.xialei = function(self,data)
    return self:canDraw()
end

sgs.ai_skill_playerchosen.zhanmeng = function(self,players)
	local destlist = self:sort(players,"card")
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

sgs.ai_skill_choice.zhanmeng = function(self,choices,data)
	local items = choices:split("+")
	local use = data:toCardUse()
	if table.contains(items,"last")
	then return "last"
	elseif table.contains(items,"next")
	then
		if __hc_value_call(self.player,"getMark","@extra_turn")>0
		then
			if self:getCardsNum(__hc_value_call(use.card,"getClassName"))>0
			then return "next" end
		else
			if getCardsNum(__hc_value_call(use.card,"getClassName"),self.room:getCurrent():getNextAlive(),self.player)>0
			then return "next" end
		end
	end
	if table.contains(items,"discard")
	and #self.enemies>0
	then
		return "discard"
	end

	return "cancel"
end

sgs.ai_skill_playerchosen.wumei = function(self,players)
	local destlist = self:sort(players,"handcard",true)
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_playerschosen.tingxian = function(self,players,x,n)
	local destlist = self:sort(players,"hp")
	local tos = {}
	for _,to in sgs.list(destlist)do
		if #tos<x and self:isFriend(to)
		and not self:isPriorFriendOfSlash(to,clone(self))
		then table.insert(tos,to) end
	end
	return tos
end

sgs.ai_skill_invoke.tingxian = function(self,data)
	for _,ep in sgs.list(self.friends_noself)do
		if __hc_value_call(self.player,"inMyAttackRange",ep)
		then return true end
	end
    return self:canDraw()
end

sgs.ai_target_revises.enyu = function(to,card,self,use)
	return __hc_value_call(to,"getMark","enyu_target_"..card:objectName().."-Clear")>0
end

sgs.ai_fill_skill.jingzao = function(self)
	return policy(self,"@JingzaoCard=.")
end

sgs.ai_skill_use_func["JingzaoCard"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself,"handcard",true)
	for _,ep in sgs.list(self.friends_noself)do
		if __hc_value_call(ep,"getMark","jingzao_target-PlayClear")>0 then continue end
		if __hc_value_call(ep,"getHandcardNum")>4
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self:sort(self.room:getOtherPlayers(self.player),"handcard",true))do
		if __hc_value_call(ep,"getMark","jingzao_target-PlayClear")>0 then continue end
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.JingzaoCard = 3.4
sgs.ai_use_priority.JingzaoCard = 9.8

sgs.ai_guhuo_card.fengying = function(self,cname,class_name)
	local d = clone(self,cname)
	if d
	then
		d = mutate(self,d,"skill","fengying")
		local cards = self.player:getCards("h")
		cards = self:sortByKeepValue(cards,nil,true)
		for _,h in sgs.list(cards)do
			if __hc_value_call(h,"getNumber")<=__hc_value_call(self.player,"getMark","&dgrlzjiao")
			then
				d = mutate(self,d,"add",h)
				return d:getLegacyStringKey()
			end
		end
	end
end

sgs.ai_fill_skill.fengying = function(self)
	local record = property(self,"SkillDescriptionRecord_fengying"):split("+")
	if #record<1 then return end
	local cancs = {}
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
  	for c,h in sgs.list(cards)do
		if __hc_value_call(h,"getNumber")>__hc_value_call(self.player,"getMark","&dgrlzjiao")
		then else table.insert(cancs,__hc_value_call(h,"getEffectiveId")) break end
	end
	if #cancs<1 then return end
	local records = {}
  	for _,cn in sgs.list(record)do
		local c = clone(self,cn)
		c = mutate(self,c,"skill","fengying")
		c = mutate(self,c,"add",cancs[1])
		if __hc_value_call(c,"isAvailable",self.player)
		then
			local uc = self:aiUseCard(c)
			if uc.card then
				self:writeCurrentSourceTargets("fengying_to",uc.to)
				if __hc_value_call(c,"canRecast") and uc.to:length()<1 then continue end
				self:setPriorityValue("FengyingCard",sgs.ai_use_priority[__hc_value_call(c,"getClassName")],"tenyear_hc")
				return policy(self,"@FengyingCard="..cancs[1]..":"..cn)
			end
		end
	end
end

sgs.ai_skill_use_func["FengyingCard"] = function(card,use,self)
	use.card = card
	use.to = self:readCurrentSourceTargets("fengying_to")
end

sgs.ai_use_value.FengyingCard = 3.4
sgs.ai_use_priority.FengyingCard = 9.8

sgs.ai_skill_playerchosen.lianzhi_shouze = function(self,players)
	local destlist = self:sort(players,"hp",true)
	for _,to in sgs.list(destlist)do
		if self:isFriend(to)
		then return to end
	end
	for _,to in sgs.list(destlist)do
		if not self:isEnemy(to)
		then return to end
	end
    return destlist[1]
end

sgs.ai_skill_playerchosen.lianzhi = function(self,players)
	local destlist = self:sort(players,"hp",true)
	for _,to in sgs.list(destlist)do
		if self:isFriend(to)
		then return to end
	end
	for _,to in sgs.list(destlist)do
		if not self:isEnemy(to)
		then return to end
	end
    return destlist[1]
end

sgs.ai_skill_choice.zuojian = function(self,choices,data)
	local items = choices:split("+")
	local maxE,minE = 0,0
	for i,p in sgs.list(self.room:getAlivePlayers())do
		if p:getEquips():length()>self.player:getEquips():length()
		then
			if self:isEnemy(p) then maxE = maxE-1
			else maxE = maxE+1 end
		elseif p:getEquips():length()<self.player:getEquips():length()
		then
			if self:isFriend(p) then maxE = maxE-1
			else maxE = maxE+1 end
		end
	end
	if maxE>0 then return "draw"
	elseif minE>0
	then return "discard" end
	if maxE>=0 then return "draw"
	elseif minE>=0
	then return "discard" end
	return "draw"
end

sgs.ai_skill_invoke.zhengxu = function(self,data)
	local str = data:toString()
	if str:match("draw") then
		return self:canDraw()
	else
		return not self:needToLoseHp()
	end
end

sgs.ai_fill_skill.cuichuan = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if #cards>2 or self:getOverflow()>0
		then return policy(self,"@CuichuanCard="..__hc_value_call(c,"getEffectiveId")) end
	end
end

sgs.ai_skill_use_func["CuichuanCard"] = function(card,use,self)
	self.friends = self:sort(self.friends,"hp")
	for _,ep in sgs.list(self.friends)do
		if ep:hasEquip()
		and ep:getEquips():length()<4
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.friends)do
		if ep:hasEquipArea()
		and ep:getEquips():length()<4
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self:sort(self.room:getAlivePlayers(),"equip"))do
		if ep:hasEquipArea() and not self:isEnemy(ep)
		and ep:getEquips():length()<4
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.CuichuanCard = 3.4
sgs.ai_use_priority.CuichuanCard = 4.8

sgs.ai_fill_skill.kanji = function(self)
	local suits = {}
  	for _,c in sgs.list(self.player:getCards("h"))do
		if table.contains(suits,__hc_value_call(c,"getSuit")) then return end
		table.insert(suits,__hc_value_call(c,"getSuit"))
	end
	return policy(self,"@KanjiCard=.")
end

sgs.ai_skill_use_func["KanjiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.KanjiCard = 3.4
sgs.ai_use_priority.KanjiCard = 9.8


sgs.ai_skill_playerchosen.silve = function(self,players)
	local destlist = self:sort(players,nil,true)
	for _,to in sgs.list(destlist)do
		if self:isFriend(to)
		then return to end
	end
	for _,to in sgs.list(destlist)do
		if not self:isEnemy(to)
		then return to end
	end
    return destlist[1]
end

sgs.ai_skill_invoke.silve = function(self,data)
	local damage = data:toDamage()
	return self:doDisCard(damage.to,"he",true)
end

sgs.ai_fill_skill.shuaijie = function(self)
	return policy(self,"@ShuaijieCard=.")
end

sgs.ai_skill_use_func["ShuaijieCard"] = function(card,use,self)
  	for _,p in sgs.list(self.room:getAlivePlayers())do
		if __hc_value_call(p,"getMark","&silve+#"..self.player:objectName())>0
		and self:isFriend(p) and self:isWeak(p) then return end
	end
	use.card = card
end

sgs.ai_use_value.ShuaijieCard = 3.4
sgs.ai_use_priority.ShuaijieCard = 9.8


sgs.ai_skill_invoke.tenyearfuning = function(self,data)
	local str = data:toString()
	local strs = str:split(":")
	local n = tonumber(strs[2])
	if n<3 or n<(self.player:getCardCount()+2)/2 then
		return self:canDraw()
	end
end

sgs.ai_fill_skill.tenyearbingji = function(self)
	return policy(self,"@TenyearBingjiCard=.")
end

sgs.ai_skill_use_func["TenyearBingjiCard"] = function(card,use,self)
  	local dcp = clone(self,"peach")
	dcp = mutate(self,dcp,"skill","tenyearbingji")
	self.friends_noself = self:sort(self.friends_noself)
  	for _,p in sgs.list(self.friends_noself)do
		if self:isWeak(p) and self.player:canUse(dcp,p) then
			self:setStrategyMemory("choice_override:tenyearbingji","peach")
			use.card = card
			return
		end
	end
  	local dc = clone(self)
	dc = mutate(self,dc,"skill","tenyearbingji")
	if not self.player:isLocked(dc) then
		local d = self:aiUseCard(dc)
		if d.card then
			self.tenyearbingjiUse = d
			self:setStrategyMemory("choice_override:tenyearbingji","slash")
			use.card = card
			return
		end
	end
  	for _,p in sgs.list(self.friends_noself)do
		if self.player:canUse(dcp,p) then
			self:setStrategyMemory("choice_override:tenyearbingji","peach")
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.TenyearBingjiCard = 3.4
sgs.ai_use_priority.TenyearBingjiCard = 2.8

sgs.ai_skill_use["@@tenyearbingji!"] = function(self,prompt)
	local use = self.tenyearbingjiUse
	if use.card then
		for _,p in sgs.list(use.to)do
			return use.card:getLegacyStringKey().."->"..p:objectName()
		end
	end
end

sgs.ai_skill_playerchosen.tenyearbingji = function(self,players)
	local destlist = self:sort(players)
	for _,to in sgs.list(destlist)do
		if self:isFriend(to)
		then return to end
	end
	for _,to in sgs.list(destlist)do
		if not self:isEnemy(to)
		then return to end
	end
    return destlist[1]
end











sgs.ai_skill_invoke.qianlong = function(self,data)
    return true
end

sgs.ai_skill_use["@@qianlong"] = function(self,prompt)
	self:writeCurrentSourceSlot("qianlong_use",false)
	local yuqi_help = tag(self,"qianlongForAI","IntList")
	local n1,n2 = {},{}
	for _,id in sgs.list(yuqi_help)do
		table.insert(n1,visible(self,id))
	end
	local n = __hc_value_call(self.player,"getLostHp")
	n1 = self:sortByKeepValue(n1,true)
	local poisons = self:poisonCards(n1)
	for _,c in sgs.list(n1)do
		if #n2>=n then break end
		if table.contains(poisons,c) or __hc_value_call(c,"isAvailable",self.player)
		then self:writeCurrentSourceSlot("qianlong_use",true) continue end
		table.insert(n2,__hc_value_call(c,"getEffectiveId"))
	end
	for _,c in sgs.list(n1)do
		if #n2>=n then break end
		if table.contains(poisons,c)
		or __hc_value_call(self.player,"getMark","@juetaoMark")>0
		or table.contains(n2,__hc_value_call(c,"getEffectiveId"))
		then continue end
		table.insert(n2,__hc_value_call(c,"getEffectiveId"))
	end
	if #n2<1 then table.insert(n2,__hc_value_call(n1[1],"getEffectiveId")) end
	return #n2>0 and ("@QianlongCard="..table.concat(n2,"+"))
end

sgs.ai_skill_playerchosen.fensi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	local dc = clone(self)
	dc = mutate(self,dc,"skill","_fensi")
    for _,target in sgs.list(destlist)do
		if target:canSlash(self.player,dc,false)
		then continue end
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if target:canSlash(self.player,dc,false)
		then continue end
		if not self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
	if not self:isWeak()
	then return self.player end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	return self.player
end

sgs.ai_skill_playerchosen.juetao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if __hc_value_call(self.player,"inMyAttackRange",target)
		and self:isEnemy(target)
		and self:isWeak(target)
		and self:readCurrentSourceSlot("qianlong_use")
		then return target end
	end
end

sgs.ai_skill_use["@@juetao!"] = function(self,prompt)
    local c = visible(self,__hc_value_call(self.player,"getMark","juetao_card_id"))
    local dummy = self:aiUseCard(c)
   	if dummy.card and dummy.to then
		if __hc_value_call(c,"canRecast")
		and dummy.to:length()<1
		then return end
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return c:getLegacyStringKey().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_playerschosen.zhushi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	local tos = {}
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target) and self:isWeak(target)
		or self:isFriend(target) then table.insert(tos,target) end
	end
	return tos
end

sgs.ai_fill_skill["xiaowu"]=function(self,inclusive,request)
	return policy(self,"@XiaowuCard=.")
end

local function write_hc_source_global(self,key,value)
 local encoded
 if value==nil then encoded={kind='nil'}
 elseif AIValue.isPlayer(value)then encoded={kind='player',name=value:objectName()}
 elseif key=='xiaowu_n'and value==0 then encoded={kind='scalar',value=0}
 else ai_unsupported('fixed source global value is not representable',key)end
 if type(ai_response_choice_continuity)~='function'then ai_unsupported('actual source global writer unavailable',key)end
 local r=ai_response_choice_continuity{op='source_global',key=key,value=encoded}
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.known~=true or r.written~=true then ai_unsupported('actual source global write is not admitted',key)end
end

sgs.ai_skill_use_func["XiaowuCard"] = function(card,use,self)
	use.card = card
	write_hc_source_global(self,"xiaowu_n",0)
end

sgs.ai_use_value.XiaowuCard = 3.4
sgs.ai_use_priority.XiaowuCard = 4.8

sgs.ai_skill_choice.xiaowu = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"xiajia")
	then return "xiajia" end
	if table.contains(items,"shangjia")
	then return "shangjia" end
	local target = data:toPlayer()
	ai_unsupported('Xiaowu actual global counter provenance is unavailable before this vote','xiaowu_n')
	-- Remaining source arithmetic is unreachable until a lawful current baseline exists.
	self.xiaowu_n = self.xiaowu_n or 0
	if self.xiaowu_n<1 and self:isWeak()
	or self:isFriend(target)
	then
		self.xiaowu_n = self.xiaowu_n+1
		return items[1]
	else
		self.xiaowu_n = self.xiaowu_n-1
		return items[2]
	end
end

sgs.ai_skill_playerchosen.xiaowu = function(self,players)
	return self.player
end

sgs.ai_skill_invoke.huaping = function(self,data)
	local n = 0
	for _,p in sgs.list(self.room:getPlayers())do
		if __hc_value_call(p,"isDead") then n = n+1 end
	end
	return n>1
end

sgs.ai_skill_playerchosen.huaping = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target) and self:isWeak(target)
		then return target end
	end
end

sgs.ai_skill_use["@@shawu"] = function(self,prompt)
	local valid = {}
	local to = tag(self,"ShawuTarget","Player")
	if not self:isEnemy(to) and self:isWeak(to)
	or self:isFriend(to)
	then return end
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if __hc_value_call(self.player,"getMark","&lyexwsha")*2>#cards
		or #valid>=2  then continue end
    	table.insert(valid,__hc_value_call(h,"getEffectiveId"))
	end
	valid = #valid>1 and table.concat(valid,"+") or "."
	return string.format("@ShawuCard=%s",valid)
end

sgs.ai_skill_playerchosen.tenyearxizhen = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		or not __hc_value_call(target,"isWounded")
		then continue end
		local use = {to = AIList.new({}),card = clone(self)}
		use.card = mutate(self,use.card,"skill","_tenyearxizhen")
		use.to:append(target)
		self:targetRevises(use)
		self:setStrategyMemory("choice_override:tenyearxizhen","slash="..target:objectName())
		if not use.to:contains(target) then return target end
		use.card = clone(self,"duel")
		use.card = mutate(self,use.card,"skill","_tenyearxizhen")
		self:targetRevises(use)
		self:setStrategyMemory("choice_override:tenyearxizhen","duel="..target:objectName())
		if not use.to:contains(target)
		and self:isFriend(target)
		and __hc_value_call(target,"isWounded")
		then return target end
	end
	destlist = self:sort(destlist,"hp",true)
    for d,target in sgs.list(destlist)do
		local dc = clone(self)
		dc = mutate(self,dc,"skill","_tenyearxizhen")
		d = self:aiUseCard(dc)
		self:setStrategyMemory("choice_override:tenyearxizhen","slash="..target:objectName())
		if d.to:contains(target)
		then return target end
		dc = clone(self,"duel")
		dc = mutate(self,dc,"skill","_tenyearxizhen")
		d = self:aiUseCard(dc)
		self:setStrategyMemory("choice_override:tenyearxizhen","duel="..target:objectName())
		if d.to:contains(target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.luochong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if target:objectName()==self:readCurrentSourceTarget("luochong_to"):objectName()
		then return target end
	end
end

sgs.ai_skill_choice.luochong = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"recover")
	then
		self.friends = self:sort(self.friends,"hp")
		for _,to in sgs.list(self.friends)do
			self:writeCurrentSourceTarget("luochong_to",to)
			if self:isWeak(to) and __hc_value_call(to,"isWounded")
			then return "recover" end
		end
	end
	if table.contains(items,"lose")
	then
		self.enemies = self:sort(self.enemies,"hp")
		for _,to in sgs.list(self.enemies)do
			self:writeCurrentSourceTarget("luochong_to",to)
			if self:isWeak(to)
			then return "lose" end
		end
	end
	if table.contains(items,"draw")
	then
		self.friends = self:sort(self.friends,"handcard")
		for _,to in sgs.list(self.friends)do
			self:writeCurrentSourceTarget("luochong_to",to)
			if __hc_value_call(to,"getHandcardNum")<4
			then return "draw" end
		end
	end
	if table.contains(items,"discard")
	then
		self.enemies = self:sort(self.enemies,"card")
		for _,to in sgs.list(self.enemies)do
			self:writeCurrentSourceTarget("luochong_to",to)
			if to:getCardCount()>1
			then return "discard" end
		end
		for _,to in sgs.list(self.friends_noself)do
			self:writeCurrentSourceTarget("luochong_to",to)
			if self:doDisCard(to,"e")
			then return "recover" end
		end
		for _,to in sgs.list(self.enemies)do
			self:writeCurrentSourceTarget("luochong_to",to)
			if to:getCardCount()>0
			then return "discard" end
		end
	end
	if table.contains(items,"draw")
	then
		self.friends = self:sort(self.friends,"handcard")
		for _,to in sgs.list(self.friends)do
			self:writeCurrentSourceTarget("luochong_to",to)
			return "draw"
		end
	end
	return items[#items]
end

sgs.ai_skill_choice.aicheng = function(self,choices)
	local items = choices:split("+")
	return items[#items]
end

sgs.ai_skill_playerschosen.tongxie = function(self,players)
	local tos = {}
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target) and #tos<2
		then table.insert(tos,target) end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target) and #tos<2
		and not table.contains(tos,target)
		then table.insert(tos,target) end
	end
	return #tos>1 and tos
end

sgs.ai_skill_invoke.fuping = function(self,data)
	local cn = data:toString()
	cn = cn:split(":")[2]
	if cn~=""
	then
		cn = clone(self,cn)
		return self:getUseValue(cn)>5
		or __hc_value_call(cn,"isDamageCard") and self:getUseValue(cn)>4
	end
end

sgs.ai_fill_skill["fuping"]=function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	local record = property(self,"SkillDescriptionRecord_fuping")
	record = record:split("+")
  	for _,c in sgs.list(cards)do
		if __hc_value_call(c,"getTypeId")==1 then continue end
		for d,pn in sgs.list(record)do
			if __hc_value_call(self.player,"getMark","fuping_guhuo_remove_"..pn.."-Clear")>0
			then continue end
			d = clone(self,pn)
			d = mutate(self,d,"add",c)
			d = mutate(self,d,"skill","fuping")
			local parse = self:aiUseCard(d)
			if __hc_value_call(d,"isAvailable",self.player) and parse.card and parse.to
			and self:getCardsNum(__hc_value_call(d,"getClassName"))<1
			then
				if __hc_value_call(d,"canRecast")
				and parse.to:length()<1
				then return end
				self:writeCurrentSourceTargets("fuping_to",parse.to)
				self:setPriorityValue("FupingCard",sgs.ai_use_priority[__hc_value_call(d,"getClassName")],"tenyear_hc")
				return policy(self,"@FupingCard="..__hc_value_call(c,"getEffectiveId")..":"..pn)
			end
		end
	end
end

sgs.ai_skill_use_func["FupingCard"] = function(card,use,self)
	if self:currentSourceTargetsPresent("fuping_to")
	then
		use.card = card
		use.to = self:readCurrentSourceTargets("fuping_to")
	end
end

sgs.ai_use_value.FupingCard = 5.4
sgs.ai_use_priority.FupingCard = 4.8

sgs.ai_guhuo_card.fuping = function(self,toname,class_name)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
	local record = property(self,"SkillDescriptionRecord_fuping")
	record = record:split("+")
	if #cards<1 or not table.contains(record,toname)
	or __hc_value_call(self.player,"getMark","fuping_guhuo_remove_"..toname.."-Clear")>0
	then return end
    local num = self:getCardsNum(class_name)
   	for _,c in sgs.list(cards)do
       	if __hc_value_call(c,"getTypeId")~=1
		and num<1
      	then
           	return "@FupingCard="..__hc_value_call(c,"getEffectiveId")..":"..toname
       	end
   	end
end

sgs.ai_fill_skill["weilie"]=function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	if __hc_value_call(self.player,"getMark","weilie_used_times")<__hc_value_call(self.player,"getMark","&weilie_time")+1
	and #cards>0
	then
		local parse = policy(self,"@WeilieCard="..__hc_value_call(cards[1],"getEffectiveId"))
		assert(parse)
		return parse
	end
end

sgs.ai_skill_use_func["WeilieCard"] = function(card,use,self)
	self.friends = self:sort(self.friends,"hp")
	for _,fp in sgs.list(self.friends)do
		if self:isWeak(fp)
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
end

sgs.ai_use_value.WeilieCard = 3.4
sgs.ai_use_priority.WeilieCard = 0.8

sgs.ai_fill_skill["tenyearjinggong"]=function(self,inclusive,request)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
  	for _,c in sgs.list(cards)do
		if __hc_value_call(c,"getTypeId")~=3 then continue end
		d = clone(self)
		d = mutate(self,d,"add",c)
		d = mutate(self,d,"skill","tenyearjinggong")
		local parse = self:aiUseCard(d)
		if __hc_value_call(d,"isAvailable",self.player)
		and parse.card and parse.to
		then return d end
	end
end

sgs.ai_guhuo_card.tenyearjinggong = function(self,toname,class_name)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
   local num = self:getCardsNum(class_name)
   	for d,c in sgs.list(cards)do
       	if __hc_value_call(c,"getTypeId")==3 and class_name=="Slash"	and num<1
		and known(self.request.reason,"response reason")==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
      	then
           	d = clone(self)
			d = mutate(self,d,"add",c)
			d = mutate(self,d,"skill","tenyearjinggong")
			return d:getLegacyStringKey()
       	end
   	end
end

sgs.ai_skill_invoke.tenyearxiaojun = function(self,data)
	local invoke = data:toString():split(":")
	if invoke
	then
		local to = BeMan(self.room,invoke[2])
		return not self:isFriend(to)
	end
end

sgs.ai_skill_invoke.tenyearmingfa = function(self,data)
	local cn = data:toString()
	cn = cn:split(":")[2]
	if cn~=""
	then
		cn = clone(self,cn)
		cn = mutate(self,cn,"skill","tenyearmingfa")
		self.tenyearmingfa_c = cn
		self:writeMingfaSavedCard(cn)
		return (#self.enemies>0 or #self.friends_noself<1)
		and (__hc_value_call(cn,"isDamageCard") or self:getUseValue(cn)>5)
	end
end

sgs.ai_skill_invoke.tenyeardeshao = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
		or __hc_value_call(target,"getHandcardNum")<=__hc_value_call(self.player,"getHandcardNum")
		or self:doDisCard(target,"e")
	end
end

sgs.ai_skill_playerchosen.tenyearmingfa = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:queryMingfaSavedCard("target_fixed")
		and self:queryMingfaSavedCard("can_use",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:queryMingfaSavedCard("can_use",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target) and not self:isWeak(target)
		and self:queryMingfaSavedCard("can_use",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and self:queryMingfaSavedCard("can_use",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:queryMingfaSavedCard("can_use",target)
		then return target end
	end
end

sgs.ai_skill_discard.liejie = function(self,max,min)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
   	for _,hcard in sgs.list(cards)do
   		if #to_cards>#cards/2
		or #to_cards>=max
		then break end
		table.insert(to_cards,__hc_value_call(hcard,"getEffectiveId"))
	end
	return to_cards
end

sgs.ai_skill_cardchosen.liejie = function(self,who,flags,method)
	if self:isFriend(who) then
		if self:doDisCard(who,"e") then
			for _,e in sgs.list(who:getEquipsId())do
				if self:doDisCard(who,e)
				then return e end
			end
		end
		return -1
	end
end

sgs.ai_skill_invoke.yuanzi = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
		and #self.enemies>0
	end
	return true
end

sgs.ai_skill_invoke.tongli = function(self,data)
    return true
end

sgs.ai_skill_invoke.shezang = function(self,data)
    return true
end

sgs.ai_skill_playerchosen.tuoxian = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
	local n = self.player:getChangeSkillState("piaoping")
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"ej")
		and __hc_value_call(self.player,"getMark","&piaoping_trigger-Clear")<3
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_use["@@tuoxian"] = function(self,prompt)
	local n1,n2 = self.player:getCards("hej"),{}
	n1 = self:sortByKeepValue(n1)
	for i,c in sgs.list(n1)do
		i = __hc_value_call(c,"getEffectiveId")
		if #n2>=__hc_value_call(self.player,"getMark","tuoxian_discard") then break end
		if self:doDisCard(self.player,i) then table.insert(n2,i) end
	end
	for i,c in sgs.list(n1)do
		i = __hc_value_call(c,"getEffectiveId")
		if #n2>=__hc_value_call(self.player,"getMark","tuoxian_discard") then break end
		if #n2>0 and not table.contains(n2,i)
		then table.insert(n2,i) end
	end
	return #n2>0 and ("@TuoxianCard="..table.concat(n2,"+"))
end

sgs.ai_skill_playerchosen.dunxi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
	local n = self.player:getChangeSkillState("piaoping")
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and __hc_value_call(target,"getMark","&bxdxdun")<1
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and __hc_value_call(target,"getMark","&bxdxdun")<1
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

sgs.ai_skill_invoke.tenyearxiecui = function(self,data)
	local cn = data:toString()
	cn = cn:split(":")
	if cn~=""
	then
		local to = BeMan(self.room,cn[3])
		local from = BeMan(self.room,cn[2])
		return self:isEnemy(to)
		or not self:isFriend(to) and self:isFriend(from)
	end
end

sgs.ai_skill_invoke.tenyearyouxu = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
		and #self.friends_noself>1
		or #self.friends_noself>0
		or not self:isFriend(target)
	end
end

sgs.ai_skill_playerchosen.tenyearyouxu = function(self,players)
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

sgs.ai_skill_invoke.zhongjie = function(self,data)
	local target = data:toPlayer()
	if target
	then
		if target:objectName()==self.player:objectName()
		then
			return self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<1
		end
		return self:isFriend(target)
	end
end

sgs.ai_skill_invoke.sushou = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return __hc_value_call(target,"getHandcardNum")>3
		and (not self:isWeak() or __hc_value_call(self.player,"hasSkill","zhongjie") and __hc_value_call(self.player,"getMark","zhongjie_used_lun")<1)
	end
end

sgs.ai_skill_use["@@sushou"] = function(self,prompt)
	local yuqi_help = tag(self,"sushouForAI","IntList")
	local n1,n2 = {},{}
	for c,id in sgs.list(yuqi_help)do
		table.insert(n1,visible(self,id))
	end
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
   	local target = self.room:getCurrent()
	local n = __hc_value_call(self.player,"getLostHp")*2
	n1 = self:sortByKeepValue(n1,true)
	local poisons = self:poisonCards(n1)
	for _,c in sgs.list(n1)do
		if #n2>=n then break end
		for _,h in sgs.list(cards)do
			if #n2>=n then break end
			if table.contains(poisons,c)
			or table.contains(n2,__hc_value_call(h,"getEffectiveId"))
			or self:getUseValue(c)>self:getUseValue(h) and self:isFriend(target)
			or self:getKeepValue(c)<=self:getKeepValue(h) then continue end
			table.insert(n2,__hc_value_call(c,"getEffectiveId"))
			table.insert(n2,__hc_value_call(h,"getEffectiveId"))
			break
		end
	end
	return #n2>1 and ("@SushouCard="..table.concat(n2,"+"))
end

sgs.ai_skill_playerchosen.suizheng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target~=self.player
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_use["@@suizheng"] = function(self,prompt)
    local c = clone(self)
	c = mutate(self,c,"skill","suizheng")
    local dummy = self:aiUseCard(c)
   	local tos = {}
   	if dummy.card
   	and dummy.to
   	then
       	for _,p in sgs.list(dummy.to)do
			if #tos>0 then break end
       		if __hc_value_call(p,"hasFlag","suizheng_target")
			then
				table.insert(tos,p:objectName())
			end
       	end
    end
	local Players = self.room:getOtherPlayers(self.player)
	Players = self:sort(Players,"handcard")
   	for _,p in sgs.list(Players)do
   		if #tos>0 then break end
		if __hc_value_call(p,"hasFlag","suizheng_target")
		and can_to(self,c,self.player,p) and self:isEnemy(p)
		then table.insert(tos,p:objectName()) end
   	end
   	for _,p in sgs.list(Players)do
   		if #tos>0 then break end
		if __hc_value_call(p,"hasFlag","suizheng_target")
		and can_to(self,c,self.player,p) and not self:isFriend(p)
		then table.insert(tos,p:objectName()) end
   	end
	if #tos>0
	then
		return "@SuizhengCard=.->"..table.concat(tos,"+")
	end
end

sgs.ai_skill_playerchosen["suizheng1"] = function(self,players)
    local c = clone(self)
	c = mutate(self,c,"skill","suizheng")
    local dummy = self:aiUseCard(c)
   	if dummy.card and dummy.to
   	then
       	for _,p in sgs.list(dummy.to)do
       		if players:contains(p)
			then return p end
       	end
    end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
   	for _,p in sgs.list(destlist)do
		if can_to(self,c,self.player,p) and self:isEnemy(p)
		then return p end
   	end
   	for _,p in sgs.list(destlist)do
		if can_to(self,c,self.player,p) and not self:isFriend(p)
		then return p end
   	end
end

sgs.ai_fill_skill["kaiji"]=function(self,inclusive,request)
	local n = self.player:getChangeSkillState("kaiji")
	self:setPriorityValue("KaijiCard",9.8,"tenyear_hc")
	if n<2
	then
		return policy(self,"@KaijiCard=.")
	end
	n = {}
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for _,c in sgs.list(cards)do
		if #n>#self.enemies or #n>=__hc_value_call(self.player,"getMaxHp")
		or #n>#cards/2 then break end
		table.insert(n,__hc_value_call(c,"getEffectiveId"))
	end
	self:setPriorityValue("KaijiCard",0.8,"tenyear_hc")
	if #n>0
	then
		return policy(self,"@KaijiCard="..table.concat(n,"+"))
	end
end

sgs.ai_skill_use_func["KaijiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.KaijiCard = 3.4
sgs.ai_use_priority.KaijiCard = 9.8

sgs.ai_skill_playerschosen.pingxi = function(self,players)
	local destlist = self:sort(players,"card")
	local tos,n = {},__hc_value_call(self.player,"getMark","pingxi_discard-Clear")
	for _,target in sgs.list(destlist)do
		if #tos>=n then break end
		if self:isEnemy(target)
		and self:doDisCard(target)
		then table.insert(tos,target) end
	end
	destlist = self:sort(destlist,"card",true)
	for _,target in sgs.list(destlist)do
		if #tos>=n then break end
		if self:isFriend(target)
		and self:doDisCard(target,"ej")
		then table.insert(tos,target) end
	end
	destlist = self:sort(destlist,"card")
	for _,target in sgs.list(destlist)do
		if #tos>=n then break end
		if not self:isFriend(target)
		and not table.contains(tos,target)
		and self:doDisCard(target)
		then table.insert(tos,target) end
	end
	for _,target in sgs.list(destlist)do
		if #tos>=n then break end
		if not self:isFriend(target)
		and not table.contains(tos,target)
		then table.insert(tos,target) end
	end
	return tos
end

sgs.ai_fill_skill["xunji"]=function(self,inclusive,request)
	local parse = policy(self,"@XunjiCard=.")
	assert(parse)
	return parse
end

sgs.ai_skill_use_func["XunjiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard",true)
	for _,fp in sgs.list(self.enemies)do
		if __hc_value_call(fp,"getHandcardNum")>2
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
	for _,fp in sgs.list(self.room:getOtherPlayers(self.player))do
		if __hc_value_call(fp,"getHandcardNum")>2
		and not self:isFriend(fp)
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
end

sgs.ai_use_value.XunjiCard = 3.4
sgs.ai_use_priority.XunjiCard = 3.8

sgs.ai_skill_invoke.fanyin = function(self,data)
    return true
end

sgs.ai_skill_use["@@fanyin"] = function(self,prompt)
    local c = visible(self,__hc_value_call(self.player,"getMark","fanyin_id"))
	self:setStrategyCardFlag(c,"fanyin_use_card",true)
    local dummy = self:aiUseCard(c)
   	if dummy.card
   	and dummy.to
   	then
		if __hc_value_call(c,"canRecast")
		and dummy.to:length()<1
		then return end
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return c:getLegacyStringKey().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_invoke.fanyin_targetfixed = function(self,data)
    local c = visible(self,__hc_value_call(self.player,"getMark","fanyin_id"))
	self:setStrategyCardFlag(c,"fanyin_use_card",true)
    local dummy = self:aiUseCard(c)
    return dummy.card and dummy.to
end

sgs.ai_skill_playerschosen.fanyin = function(self,players,x,n)
	local tos = {}
    return self:withNestedDelegateUse("fanyin",function()
	while true do
		local to = sgs.ai_skill_playerchosen.yb_zhuzhan2(self,players)
		if to and #tos<x
		then
			table.insert(tos,to)
			players:removeOne(to)
		else break end
	end
	return tos
    end)
end

sgs.ai_skill_invoke.peiqi = function(self,data)
	self:resetPeiqiSourceRecord()
	for _,ep in sgs.list(self.friends)do
		if self:doDisCard(ep,"ej",true) then
			self:writePeiqiSourceField("from",ep)
			local ejs = ep:getCards("ej")
			ejs = self:sortByKeepValue(ejs)
			for _,ej in sgs.list(ejs)do
				local i = __hc_value_call(ej,"getEffectiveId")
				if self:doDisCard(ep,i,true) then
					self:writePeiqiSourceField("cid",i)
					for _,fp in sgs.list(self.enemies)do
						self:writePeiqiSourceField("to",fp)
						if __hc_value_call(ej,"getTypeId")==3 then
							local n = known(ej:getEquipSlot(),"equipment slot")
							local equipCard = ej
							local occupy = equipCard and known(equipCard:getEquipOccupyLocations(),"equipment occupy locations")
							local all_available = true
							if occupy and not occupy:isEmpty() then
								for _, slot in sgs.qlist(occupy) do
									if fp:getEquip(slot) or not fp:hasEquipArea(slot) then
										all_available = false
										break
									end
								end
							else
								if fp:getEquip(n) or not fp:hasEquipArea(n) then
									all_available = false
								end
							end
							if all_available then return true end
						else
							if self.player:canUse(ej,fp,true)
							then return true end
						end
					end
				end
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if self:doDisCard(ep,"ej",true) then
			self:writePeiqiSourceField("from",ep)
			local ejs = ep:getCards("ej")
			ejs = self:sortByKeepValue(ejs,true)
			for _,ej in sgs.list(ejs)do
				local i = __hc_value_call(ej,"getEffectiveId")
				if self:doDisCard(ep,i,true) then
					self:writePeiqiSourceField("cid",i)
					for _,fp in sgs.list(self.friends)do
						self:writePeiqiSourceField("to",fp)
						if __hc_value_call(ej,"getTypeId")==3 then
							local n = known(ej:getEquipSlot(),"equipment slot")
							local equipCard = ej
							local occupy = equipCard and known(equipCard:getEquipOccupyLocations(),"equipment occupy locations")
							local all_available = true
							if occupy and not occupy:isEmpty() then
								for _, slot in sgs.qlist(occupy) do
									if fp:getEquip(slot) or not fp:hasEquipArea(slot) then
										all_available = false
										break
									end
								end
							else
								if fp:getEquip(n) or not fp:hasEquipArea(n) then
									all_available = false
								end
							end
							if all_available then return true end
						else
							if self.player:canUse(ej,fp,true)
							then return true end
						end
					end
				end
			end
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if self:doDisCard(ep,"ej",true) and not self:isFriend(ep) then
			self:writePeiqiSourceField("from",ep)
			local ejs = ep:getCards("ej")
			ejs = self:sortByKeepValue(ejs,true)
			for _,ej in sgs.list(ejs)do
				local i = __hc_value_call(ej,"getEffectiveId")
				if self:doDisCard(ep,i,true) then
					self:writePeiqiSourceField("cid",i)
					for _,fp in sgs.list(self.friends)do
						self:writePeiqiSourceField("to",fp)
						if __hc_value_call(ej,"getTypeId")==3 then
							local n = known(ej:getEquipSlot(),"equipment slot")
							local equipCard = ej
							local occupy = equipCard and known(equipCard:getEquipOccupyLocations(),"equipment occupy locations")
							local all_available = true
							if occupy and not occupy:isEmpty() then
								for _, slot in sgs.qlist(occupy) do
									if fp:getEquip(slot) or not fp:hasEquipArea(slot) then
										all_available = false
										break
									end
								end
							else
								if fp:getEquip(n) or not fp:hasEquipArea(n) then
									all_available = false
								end
							end
							if all_available then return true end
						else
							if not fp:containsTrick(ej:objectName())
							and self.player:canUse(ej,fp,true)
							then return true end
						end
					end
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen["peiqi_from"] = function(self,players)
	for _,target in sgs.list(players)do
		if AIValue.sameLegacyIdentity(target,self:readPeiqiSourceField("from"))
		then return target end
	end
end

sgs.ai_skill_playerchosen["peiqi_to"] = function(self,players)
	for _,target in sgs.list(players)do
		if AIValue.sameLegacyIdentity(target,self:readPeiqiSourceField("to"))
		then return target end
	end
end

sgs.ai_skill_cardchosen.peiqi = function(self,who,flags,method)
	for _,c in sgs.qlist(who:getCards(flags))do
		if c:getId()==self:readPeiqiSourceField("cid")
		then return c:getId() end
	end
end

sgs.ai_choicemade_filter.cardChosen.peiqi = function(self,player,promptlist)
	local em_prompt = {"cardChosen","peiqi",tostring(self:readPeiqiSourceField("cid")),self:readPeiqiSourceField("to"):objectName()}
	sgs.ai_choicemade_filter.cardChosen.snatch(self,nil,em_prompt)
end

sgs.ai_can_damagehp.peiqi = function(self,from,card,to)
	return __hc_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	and sgs.ai_skill_invoke.peiqi(self)
end

sgs.ai_skill_playerchosen.xiaoxinf = function(self,players)
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
		if not self:isFriend(target)
		and self:doDisCard(target,"he")
		then return target end
	end
end

sgs.ai_skill_choice.xiaoxinf = function(self,choices)
	local items = choices:split("+")
	for _,to in sgs.list(self.enemies)do
		if __hc_value_call(self.player,"getLostHp")>1
		and __hc_value_call(self.player,"inMyAttackRange",to)
		and table.contains(items,"lose=2")
		then return "lose=2" end
	end
	for dc,item in sgs.list(items)do
		if item:startsWith("slash")
		then
			dc = clone(self)
			dc = mutate(self,dc,"skill","xiaoxinf")
			dc = self:aiUseCard(dc)
			if dc.card and dc.to
			then
				for _,to in sgs.list(dc.to)do
					self:writeCurrentSourceTarget("xiaoxinf_to",to)
					if __hc_value_call(self.player,"inMyAttackRange",to)
					then return item end
				end
			end
		end
	end
	return items[1]
end

sgs.ai_skill_playerchosen["xiaoxinf_slash"] = function(self,players)
	for _,target in sgs.list(players)do
		if target:objectName()==self:readCurrentSourceTarget("xiaoxinf_to"):objectName()
		then return target end
	end
end

sgs.ai_skill_invoke.xiongrao = function(self,data)
    return __hc_value_call(self.player,"getMaxHp")<3
end

sgs.ai_skill_invoke.diting = function(self,data)
	local target = data:toPlayer()
	if target
	then
		self:writeCurrentSourceTarget("diting_to",target)
		return not self:isFriend(target)
		or __hc_value_call(target,"getHandcardNum")>1
	end
end

sgs.ai_skill_askforag.diting = function(self,ids)
	local cs = list_i2c(self,ids)
	cs = self:sortByUseValue(cs,self:isEnemy(self:readCurrentSourceTarget("diting_to")))
	for _,c in sgs.list(cs)do
		if __hc_value_call(c,"isDamageCard")
		then
			return __hc_value_call(c,"getEffectiveId")
		end
	end
	return __hc_value_call(cs[1],"getEffectiveId")
end

sgs.ai_skill_playerchosen.bihuof = function(self,players)
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

sgs.ai_skill_playerchosen.bihuof2 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_invoke.kanpodz = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end

sgs.ai_fill_skill["kanpodz"]=function(self,inclusive,request)
	local cards = self:addHandPile()
	cards = self:sortByKeepValue(cards,nil,true)
  	for _,c in sgs.list(cards)do
		if self:getCardsNum("Slash")>0
		then break end
		d = clone(self)
		d = mutate(self,d,"add",c)
		d = mutate(self,d,"skill","kanpodz")
		local parse = self:aiUseCard(d)
		if __hc_value_call(d,"isAvailable",self.player)
		and parse.card and parse.to
		then return d end
	end
end

sgs.ai_guhuo_card.kanpodz = function(self,toname,class_name)
    local cards = self:addHandPile()
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
   	for d,c in sgs.list(cards)do
       	if class_name=="Slash"and self:getCardsNum(class_name)<1
		and known(self.request.reason,"response reason")==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		and __hc_value_call(self.player,"getMark","kanpodz_used-Clear")<1
      	then
           	d = clone(self)
			d = mutate(self,d,"add",c)
			d = mutate(self,d,"skill","kanpodz")
			return d:getLegacyStringKey()
       	end
   	end
end

sgs.ai_skill_invoke.gengzhan = function(self,data)
    return true
end

sgs.ai_fill_skill["midu"]=function(self,inclusive,request)
	local parse = policy(self,"@MiduCard=.")
	assert(parse)
	return parse
end

sgs.ai_skill_use_func["MiduCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.MiduCard = 3.4
sgs.ai_use_priority.MiduCard = 6.8

sgs.ai_skill_playerchosen.midu = function(self,players)
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

sgs.ai_skill_playerschosen.yingyu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	local tos = {}
	for _,target in sgs.list(destlist)do
		if #tos>0 then break end
		if self:isFriend(target)
		then table.insert(tos,target) end
	end
	for _,target in sgs.list(destlist)do
		if #tos>0 then break end
		if not self:isEnemy(target)
		then table.insert(tos,target) end
	end
	for _,target in sgs.list(destlist)do
		if #tos>1 then break end
		if self:isEnemy(target)
		then table.insert(tos,target) end
	end
	for _,target in sgs.list(destlist)do
		if #tos>0 then break end
		if not self:isFriend(target)
		then table.insert(tos,target) end
	end
	return #tos>1 and tos or {}
end

sgs.ai_skill_playerchosen.yingyu = function(self,players)
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

sgs.ai_fill_skill["yongbi"]=function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
	local suits = {}
  	for s,c in sgs.list(cards)do
		s = __hc_value_call(c,"getSuit")
		if table.contains(suits,s)
		then continue end
		table.insert(suits,s)
	end
	return #suits>2 and policy(self,"@YongbiCard=.")
end

sgs.ai_skill_use_func["YongbiCard"] = function(card,use,self)
	self.friends = self:sort(self.friends,"hp",true)
	for _,fp in sgs.list(self.friends)do
		if __hc_value_call(fp,"isMale")
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
end

sgs.ai_use_value.YongbiCard = 3.4
sgs.ai_use_priority.YongbiCard = 0.8

sgs.ai_skill_cardask["@fenrui"] = function(self,data)
    return self.player:getCardCount()>2
end

sgs.ai_skill_playerchosen.fenrui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self.player:getEquips():length()-target:getEquips():length()>=__hc_value_call(target,"getHp")
		then return target end
	end
end

sgs.ai_skill_invoke.tenyeartujue = function(self,data)
    return self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<1
end

sgs.ai_fill_skill["tenyearquanjian"]=function(self,inclusive,request)
	return policy(self,"@TenyearQuanjianCard=.")
end

sgs.ai_skill_use_func["TenyearQuanjianCard"] = function(card,use,self)
	if __hc_value_call(self.player,"getMark","tenyearquanjian_tiansuan_remove_card-PlayClear")<1 then
		self.enemies = self:sort(self.enemies,"handcard",true)
		for _,ep in sgs.list(self.enemies)do
			if __hc_value_call(ep,"getHandcardNum")>__hc_value_call(ep,"getMaxCards") then
				use.card = policy(self,"@TenyearQuanjianCard=.:card")
				use.to:append(ep)
				return
			end
		end
		self.friends_noself = self:sort(self.friends_noself,"handcard")
		for _,fp in sgs.list(self.friends_noself)do
			if __hc_value_call(fp,"getHandcardNum")<__hc_value_call(fp,"getMaxCards") then
				use.card = policy(self,"@TenyearQuanjianCard=.:card")
				use.to:append(fp)
				return
			end
		end
	end
	if __hc_value_call(self.player,"getMark","tenyearquanjian_tiansuan_remove_damage-PlayClear")<1 then
		self.enemies = self:sort(self.enemies,"hp")
		for _,ep in sgs.list(self.enemies)do
			for _,fp in sgs.list(self.friends_noself)do
				if __hc_value_call(fp,"inMyAttackRange",ep)
				and __hc_value_call(ep,"getMark","&tenyearquanjian_debuff-Clear")>0 then
					use.card = policy(self,"@TenyearQuanjianCard=.:damage")
					use.to:append(fp)
					use.to:append(ep)
					return
				end
			end
			for _,fp in sgs.list(self.room:getOtherPlayers(self.player))do
				if __hc_value_call(fp,"inMyAttackRange",ep)
				and __hc_value_call(ep,"getMark","&tenyearquanjian_debuff-Clear")>0
				and self:isEnemy(fp) then
					use.card = policy(self,"@TenyearQuanjianCard=.:damage")
					use.to:append(fp)
					use.to:append(ep)
					return
				end
			end
		end
		for _,ep in sgs.list(self.enemies)do
			for _,fp in sgs.list(self.friends_noself)do
				if __hc_value_call(fp,"inMyAttackRange",ep) then
					use.card = policy(self,"@TenyearQuanjianCard=.:damage")
					use.to:append(fp)
					use.to:append(ep)
					return
				end
			end
			for _,fp in sgs.list(self.room:getOtherPlayers(self.player))do
				if __hc_value_call(fp,"inMyAttackRange",ep)
				and self:isEnemy(fp) then
					use.card = policy(self,"@TenyearQuanjianCard=.:damage")
					use.to:append(fp)
					use.to:append(ep)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.TenyearQuanjianCard = 3.4
sgs.ai_use_priority.TenyearQuanjianCard = 8.8

sgs.ai_skill_invoke.tenyearquanjian = function(self,data)
	local invoke = data:toString():split("+")
	if invoke[1]=="dodamage"
	then
		invoke = BeMan(self.room,invoke[2])
		if invoke
		then
			return not self:isFriend(invoke)
			or not self:isWeak(invoke)
		end
	end
    return true
end

sgs.ai_skill_discard.tenyearquanjian = function(self,max,min)
	local to_cards = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
   	for _,hcard in sgs.list(cards)do
   		if #to_cards>=min or min>2 then break end
		table.insert(to_cards,__hc_value_call(hcard,"getEffectiveId"))
	end
	return to_cards
end

sgs.ai_skill_invoke.suoliang = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_invoke.chongyi = function(self,data)
	local invoke = data:toString():split(":")
	if #invoke>1
	then
		invoke = BeMan(self.room,invoke[2])
		if invoke
		then
			return self:isFriend(invoke)
			or self:isWeak(invoke) and not self:isEnemy(invoke)
		end
	end
end

sgs.ai_skill_invoke.yingtu = function(self,data)
	local target = data:toPlayer()
	if target
	then
		local to = self.player:getNextAlive()
		if to==target
		then
			to = self.player:getNextAlive(self.player:getAliveSiblings():length())
		end
		if not self:isFriend(target)
		and not self:isEnemy(to)
		then return true end
		if self:doDisCard(target,"e")
		then return true end
		if self:isFriend(target)
		and self:isFriend(to)
		then return true end
		if not self:isFriend(target)
		and not self:isFriend(to)
		then return true end
	end
end

sgs.ai_skill_cardask["@tenyearpoyuan-discard"] = function(self,data,pattern)
    return self.player:getCardCount()>1
end

sgs.ai_skill_playerchosen.tenyearpoyuan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
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
		if not self:isFriend(target)
		and self:doDisCard(target,"e")
		then return target end
	end
end

sgs.ai_skill_cardchosen.tenyearpoyuan = function(self,who,flags,method)
	if self:doDisCard(who,flags)
	then
		for i,c in sgs.list(who:getCards(flags))do
			i = __hc_value_call(c,"getEffectiveId")
			if self:doDisCard(who,i)
			then return i end
		end
	end
	return -1
end

sgs.ai_fill_skill["tenyearhuace"]=function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
	for d,pn in sgs.list(source_patterns(self))do
		if __hc_value_call(self.player,"getMark","tenyearhuace_guhuo_remove_"..pn)>0
		or #cards<1 then continue end
		d = pattern_card(self,pn)
		if d and d:isNDTrick()
		and __hc_value_call(d,"isDamageCard")
		then
			d = clone(self,pn)
			d = mutate(self,d,"add",cards[1])
			d = mutate(self,d,"skill","tenyearhuace")
			local parse = self:aiUseCard(d)
			if __hc_value_call(d,"isAvailable",self.player) and parse.card and parse.to
			and self:getCardsNum(__hc_value_call(d,"getClassName"))<1
			then
				self.tenyearhuace_to = parse.to
				if __hc_value_call(d,"canRecast") and parse.to:length()<1 then continue end
				return d
			end
		end
	end
	for d,pn in sgs.list(source_patterns(self))do
		if __hc_value_call(self.player,"getMark","tenyearhuace_guhuo_remove_"..pn)>0
		or #cards<1 then continue end
		d = pattern_card(self,pn)
		if d and d:isNDTrick()
		then
			d = clone(self,pn)
			d = mutate(self,d,"add",cards[1])
			d = mutate(self,d,"skill","tenyearhuace")
			local parse = self:aiUseCard(d)
			if __hc_value_call(d,"isAvailable",self.player) and parse.card and parse.to
			and self:getCardsNum(__hc_value_call(d,"getClassName"))<1
			then
				if __hc_value_call(d,"canRecast") and parse.to:length()<1 then continue end
				self.tenyearhuace_to = parse.to
				return d
			end
		end
	end
end

sgs.ai_skill_use_func["TenyearHuaceCard"] = function(card,use,self)
	if self.tenyearhuace_to
	then
		use.card = card
		use.to = self.tenyearhuace_to
	end
end

sgs.ai_use_value.TenyearHuaceCard = 5.4
sgs.ai_use_priority.TenyearHuaceCard = 4.8

sgs.ai_skill_invoke.ruizhan = function(self,data)
	local target = data:toPlayer()
	if target
	then
		local mc = self:getMaxCard()
		return mc and __hc_value_call(mc,"getNumber")>10
		and (self:isEnemy(target) or not (self:isFriend(target) or self:isWeak(target)))
	end
end

sgs.ai_fill_skill["shilie"]=function(self,inclusive,request)
	return policy(self,"@ShilieCard=.")
end

sgs.ai_skill_use_func["ShilieCard"] = function(card,use,self)
	local pile = self.player:getPile("shilie")
	if self:isWeak() then
		self:setStrategyMemory("choice_override:shilie","recover")
		if self.player:getCardCount()>__hc_value_call(self.player,"getHp")
		or self.player:getCardCount()<1
		then use.card = card return end
	elseif pile:length()>1 then
		self:setStrategyMemory("choice_override:shilie","lose")
		self:sourceIntListOperation("reset")
		for _,c in sgs.list(list_i2c(self,pile))do
			if __hc_value_call(c,"isAvailable",self.player) then
				local d = self:aiUseCard(c)
				if d.card and d.to
				then self:sourceIntListOperation("append",__hc_value_call(c,"getEffectiveId")) end
			end
		end
		if self:sourceIntListOperation("length")>1
		then use.card = card return end
	end
	if __hc_value_call(self.player,"isWounded")
	and self.player:getCardCount()>__hc_value_call(self.player,"getHp")*(math.random()+1) then
		self:setStrategyMemory("choice_override:shilie","recover")
		use.card = card
	end
end

sgs.ai_use_value.ShilieCard = 3.4
sgs.ai_use_priority.ShilieCard = 5.8

sgs.ai_skill_use["@@shilie!"] = function(self,prompt)
	local n2 = {}
	for i,id in sgs.list(self.player:getPile("shilie"))do
		if self:sourceIntListOperation("contains",id) then table.insert(n2,id) end
	end
	return #n2>0 and ("@ShilieGetCard="..table.concat(n2,"+"))
end

sgs.ai_skill_playerchosen.shilie = function(self,players)
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

sgs.ai_fill_skill["qiaoli"]=function(self,inclusive,request)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if __hc_value_call(c,"getTypeId")~=3
		or (__hc_value_call(self.player,"getMark","qiaoliWeapon-PlayClear")>0 and __hc_value_call(c,"isKindOf","Weapon")
		or __hc_value_call(self.player,"getMark","qiaoliEquip-PlayClear")>0 and not __hc_value_call(c,"isKindOf","Weapon"))
		or self:getCardsNum("Duel")>0
		then continue end
		local dc = clone(self,"duel")
		dc = mutate(self,dc,"skill","qiaoli")
		dc = mutate(self,dc,"add",c)
		if __hc_value_call(dc,"isAvailable",self.player)
		and self:aiUseCard(dc).card then
			return dc
		end
	end
end

sgs.ai_skill_invoke.qingliang = function(self,data)
	return self:getCardsNum("Jink")>0
	or self:isWeak()
end

sgs.ai_skill_choice.qingliang = function(self,choices)
	local items = choices:split("+")
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
	local suits = {}
  	for s,c in sgs.list(cards)do
		s = __hc_value_call(c,"getSuitString")
		if suits[s] then suits[s] = suits[s]+1
		else suits[s] = 1 end
	end
	local function func(a,b)
		return a<b
	end
	table.sort(suits,func)
   	local target = self.room:getCurrent()
	if self:getCardsNum("Jink")>0
	and not self:isEnemy(target)
	then return items[1] end
  	for s,c in sgs.list(cards)do
		s = __hc_value_call(c,"getSuitString")
		if suits[1]==suits[s]
		then
			return "discard="..s
		end
	end
end

sgs.ai_skill_choice.chongwang = function(self,choices)
	local items = choices:split("+")
	if items
	then
		local to = items[1]:split("=")[2]
		to = BeMan(self.room,to)
		if to and self:isEnemy(to)
		then return items[2] end
		if to and self:isFriend(to)
		then return items[1] end
	end
	return items[#items]
end

sgs.ai_skill_playerschosen.huagui = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
	local tos = {}
	for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isFriend(target)
		then table.insert(tos,target) end
	end
	for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isEnemy(target)
		then table.insert(tos,target) end
	end
	for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if not table.contains(tos,target)
		then table.insert(tos,target) end
	end
	return tos
end

sgs.ai_skill_choice.huagui = function(self,choices,data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if self:isFriend(target)
	then return items[1] end
	if not self:isEnemy(target)
	and math.random()>0.3
	then return items[1] end
	return items[2]
end

sgs.ai_skill_invoke.jingjian = function(self,data)
	local target = data:toString()
	target = target:split(":")[2]
	target = BeMan(self.room,target)
	if target then
		local mc = self:getMaxCard()
		return mc and __hc_value_call(mc,"getNumber")>math.random(8,11)
		and (self:isEnemy(target) or not (self:isFriend(target) or self:isWeak(target)))
	end
end

sgs.ai_skill_choice.zhenze = function(self,choices)
	local items = choices:split("+")
	local function canZhenze(to)
		if __hc_value_call(to,"getHandcardNum")>__hc_value_call(to,"getHp")
		then return 1
		elseif __hc_value_call(to,"getHandcardNum")==__hc_value_call(to,"getHp")
		then return 0 end
		return -1
	end
	local n,x = canZhenze(self.player),0
	for _,target in sgs.list(self.room:getAllPlayers())do
		if n~=canZhenze(target)
		and not self:isFriend(target)
		then x = x+1 end
		if n==canZhenze(target)
		and not self:isEnemy(target)
		and __hc_value_call(target,"isWounded")
		then x = x-1 end
	end
	if x>0 then return "lose" end
	if x<0 then return "recover" end
	return items[#items]
end

sgs.ai_fill_skill["anliao"]=function(self,inclusive,request)
	return policy(self,"@AnliaoCard=.")
end

sgs.ai_skill_use_func["AnliaoCard"] = function(card,use,self)
	for _,fp in sgs.list(self.friends)do
		if self:doDisCard(fp,"e")
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHandcardNum")==1
		and __hc_value_call(ep,"getMark","anliao_to-PlayClear")<1
		then
			use.card = card
			use.to:append(ep)
			self:addStrategyPlayerMark(ep,"anliao_to-PlayClear",1)
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
	for _,c in sgs.list(self.player:getCards("he"))do
		if self:getKeepValue(c)<4
		or self.player:getCardCount()>3
		then
			use.card = card
			use.to:append(self.player)
			return
		end
	end
end

sgs.ai_use_value.AnliaoCard = 3.4
sgs.ai_use_priority.AnliaoCard = 5.8

sgs.ai_skill_invoke.xieshou = function(self,data)
	local target = data:toPlayer()
	return target and self:isFriend(target)
end

sgs.ai_skill_choice.xieshou = function(self,choices)
	if self:isWeak() then return "recover" end
	local items = choices:split("+")
	return items[#items]
end

sgs.ai_skill_invoke.qingyan = function(self,data)
	return true
end

sgs.ai_skill_cardask["@qingyan"] = function(self,data)
    return __hc_value_call(self.player,"getHandcardNum")>__hc_value_call(self.player,"getMaxCards")
end









--度断
sgs.ai_skill_cardask["@duoduan-card"] = function(self,data)
	if self:needToThrowArmor() then return "$"..self.player:getArmor():getEffectiveId() end
	local use = data:toCardUse()
	if __hc_value_call(use.card,"isKindOf","FireSlash") and self:slashIsEffective(use.card,self.player,use.from) and self:damageIsEffective(self.player,sgs.DamageStruct_Fire,use.from)
	and self.player:hasArmorEffect("Vine") and self.player:getArmor() and self.player:getArmor():objectName()=="vine" and
		(self:getCardsNum("Jink")==0 or self:canHit(self.player,use.from)) and not use.from:hasSkills("jueqing|gangzhi") then
		return "$"..self.player:getArmor():getEffectiveId()
	end

	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	if __hc_value_call(cards[1],"isKindOf","Jink") and self:getCardsNum("Jink")==1 then return "." end
	if __hc_value_call(cards[1],"isKindOf","Peach") or __hc_value_call(cards[1],"isKindOf","Analeptic") then return "." end

	local nature = sgs.DamageStruct_Normal
	if __hc_value_call(use.card,"isKindOf","FireSlash") then nature = sgs.DamageStruct_Fire end
	if __hc_value_call(use.card,"isKindOf","ThunderSlash") then nature = sgs.DamageStruct_Thunder end
	if self:getCardsNum("Jink")==0 and self:slashIsEffective(use.card,self.player,use.from) and self:damageIsEffective(self.player,nature,use.from) then return "$"..__hc_value_call(cards[1],"getEffectiveId") end
	if not self:isValuableCard(cards[1]) then return "$"..__hc_value_call(cards[1],"getEffectiveId") end
	return "."
end

sgs.ai_skill_discard.duoduan = function(self,discard_num,min_num,optional,include_equip)
	local use = tag(self,"duoduanForAI","CardUse")
	return self:askForDiscard("dummyreason",1,1,false,true)
end

--共损
sgs.ai_skill_use["@@gongsun"] = function(self,prompt)
	local valid,to = {},nil
    for _,p in sgs.list(self.player:getAliveSiblings())do
      	if self:isEnemy(p) and __hc_value_call(p,"getHandcardNum")>2
    	then to = p break end
	end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if #valid>=2 or to==nil or #cards<4 then break end
    	table.insert(valid,__hc_value_call(h,"getEffectiveId"))
	end
	if #valid<2 or #self.friends_noself<1 then return end
	return string.format("@GongsunCard=%s->%s",table.concat(valid,"+"),to:objectName())
end

sgs.ai_skill_askforag.GongsunCard = function(self,card_ids)
	for c,id in sgs.list(card_ids)do
		c = visible(self,id)
		if __hc_value_call(c,"isKindOf","Slash")
		then return id end
	end
	for c,id in sgs.list(card_ids)do
		c = visible(self,id)
		if __hc_value_call(c,"isKindOf","Jink")
		and self:getCardsNum("Slash")>0
		then return id end
	end
	for c,id in sgs.list(card_ids)do
		c = visible(self,id)
		if __hc_value_call(c,"isDamageCard")
		then return id end
	end
end

sgs.ai_skill_invoke.juanxia_slash = function(self,data)
	local items = data:toString():split(":")
	if items[1]=="juanxia_slash"
	then
        local target = self.room:findPlayerByObjectName(items[2])
    	return self:isEnemy(target)
	end
end

sgs.ai_skill_playerchosen.juanxia = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:isWeak(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"ej")
		and self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_choice.juanxia = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	local cs = {}
	for _,pn in sgs.list(items)do
		local dc = clone(self,pn)
		if dc then
			dc = mutate(self,dc,"skill","_juanxia")
			table.insert(cs,dc)
		end
	end
	cs = self:sortByUseValue(cs)
	for _,c in sgs.list(cs)do
		local d = self:aiUseCard(c)
		if d.card and d.to:contains(target)
		then return c:objectName() end
	end
	if self:isFriend(target) then
		for _,c in sgs.list(cs)do
			if self:doDisCard(target,"ej")
			and (__hc_value_call(c,"isKindOf","Snatch") or __hc_value_call(c,"isKindOf","Dismantlement") or __hc_value_call(c,"isKindOf","Zhujinquyuan"))
			then return c:objectName() end
		end
		for _,c in sgs.list(cs)do
			if c:targetFixed() and not __hc_value_call(c,"isDamageCard")
			then return c:objectName() end
		end
	else
		for _,c in sgs.list(cs)do
			if not c:targetFixed() or __hc_value_call(c,"isDamageCard")
			then return c:objectName() end
		end
	end
	return items[#items]
end

sgs.ai_skill_invoke.tenyearjuanxia_slash = function(self,data)
	local items = data:toString():split(":")
	if items[1]=="tenyearjuanxia_slash"
	then
        local target = self.room:findPlayerByObjectName(items[2])
    	return target and self:isEnemy(target)
	end
end

sgs.ai_skill_playerchosen.tenyearjuanxia = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:isWeak(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"ej")
		and self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_choice.tenyearjuanxia = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	for _,pn in sgs.list(items)do
		local c = clone(self,pn)
		if not c then continue end
		c = mutate(self,c,"skill","_tenyearjuanxia")
		local d = self:aiUseCard(c)
		if d.card and d.to:contains(target)
		then return pn end
	end
	if self:isFriend(target) then
		for _,pn in sgs.list(items)do
			local c = clone(self,pn)
			if not c then continue end
			c = mutate(self,c,"skill","_tenyearjuanxia")
			if self:doDisCard(target,"ej")
			and (__hc_value_call(c,"isKindOf","Snatch") or __hc_value_call(c,"isKindOf","Dismantlement") or __hc_value_call(c,"isKindOf","Zhujinquyuan"))
			then return pn end
		end
		for _,pn in sgs.list(items)do
			local c = clone(self,pn)
			if not c then continue end
			c = mutate(self,c,"skill","_tenyearjuanxia")
			if c:targetFixed() and not __hc_value_call(c,"isDamageCard")
			then return pn end
		end
	else
		for _,pn in sgs.list(items)do
			local c = clone(self,pn)
			if not c then continue end
			c = mutate(self,c,"skill","_tenyearjuanxia")
			if not c:targetFixed() or __hc_value_call(c,"isDamageCard")
			then return pn end
		end
	end
	return items[#items]
end

--周旋
sgs.ai_fill_skill["zhouxuan"] = function(self,inclusive,request)
	return policy(self,"@ZhouxuanCard=.")
end

sgs.ai_skill_use_func.ZhouxuanCard = function(card,use,self)
	local id = -1
	if self:needToThrowArmor() and self.player:canDiscard(self.player,self.player:getArmor():getEffectiveId()) then
		id = self.player:getArmor():getEffectiveId()
	else
		local cards = sgs.QList2Table(self.player:getCards("he"))
		cards = self:sortByKeepValue(cards)
		if __hc_value_call(cards[1],"isKindOf","Peach") or (__hc_value_call(cards[1],"isKindOf","Jink") and self:getCardsNum("Jink")==1) then return end
		id = __hc_value_call(cards[1],"getEffectiveId")
	end
	if id<0 or (self:getOverflow()<=0 and self.room:getCardPlace(id)==sgs.Player_PlaceHand) then return end
	use.card = policy(self,"@ZhouxuanCard="..id)
end

sgs.ai_use_priority.ZhouxuanCard = 0
sgs.ai_card_intention.ZhouxuanCard = 0

sgs.ai_skill_playerchosen.zhouxuan = function(self,targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets,"handcard")

	for _,p in ipairs(targets)do
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
		for _,cc in sgs.qlist(known(p:getKnownCards(),"known target hand"))do
			if (__hc_value_call(cc,"hasFlag","visible") or __hc_value_call(cc,"hasFlag",flag)) and __hc_value_call(cc,"isKindOf","TrickCard") and not __hc_value_call(cc,"isKindOf","Nullification") then
				self:setStrategyMemory("choice_override:zhouxuan","TrickCard")
				return p
            end
        end
	end

	for _,p in ipairs(targets)do
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
		for _,cc in sgs.qlist(known(p:getKnownCards(),"known target hand"))do
			if (__hc_value_call(cc,"hasFlag","visible") or __hc_value_call(cc,"hasFlag",flag)) and __hc_value_call(cc,"isKindOf","EquipCard") and p:canUse(cc) then
				self:setStrategyMemory("choice_override:zhouxuan","EquipCard")
				return p
            end
        end
	end

	for _,p in ipairs(targets)do
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
		for _,cc in sgs.qlist(known(p:getKnownCards(),"known target hand"))do
			if (__hc_value_call(cc,"hasFlag","visible") or __hc_value_call(cc,"hasFlag",flag)) and __hc_value_call(cc,"isKindOf","Peach") and p:canUse(cc) then
				self:setStrategyMemory("choice_override:zhouxuan","peach")
				return p
            end
        end
	end

	for _,p in ipairs(targets)do
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
		for _,cc in sgs.qlist(known(p:getKnownCards(),"known target hand"))do
			if (__hc_value_call(cc,"hasFlag","visible") or __hc_value_call(cc,"hasFlag",flag)) and __hc_value_call(cc,"isKindOf","Slash") and self:canUse(cc,self:getEnemies(p),p) then
				self:setStrategyMemory("choice_override:zhouxuan",cc:objectName())
				return p
            end
        end
	end

	for _,p in ipairs(targets)do
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
		for _,cc in sgs.qlist(known(p:getKnownCards(),"known target hand"))do
			if (__hc_value_call(cc,"hasFlag","visible") or __hc_value_call(cc,"hasFlag",flag)) and __hc_value_call(cc,"isKindOf","Analeptic") and p:canUse(cc) then
				self:setStrategyMemory("choice_override:zhouxuan",cc:objectName())
				return p
            end
        end
	end

	self:setStrategyMemory("choice_override:zhouxuan","slash")
	return targets[#targets]
end

sgs.ai_skill_askforyiji.zhouxuan = function(self,card_ids,tos)
	return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
end

sgs.ai_skill_invoke.wangzu = function(self,data)
	return __hc_value_call(self.player,"getHandcardNum")>1 or self:isWeak()
end

sgs.ai_skill_cardask["@wangzu-discard"] = function(self,data)
    local damage = data:toDamage()
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
	if self:canDamageHp(damage.from,damage.card,damage.to)
	and damage.damage<2
	then return "." end
	if #cards>0	then return __hc_value_call(cards[1],"getEffectiveId") end
    return "."
end

sgs.ai_fill_skill["yingrui"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
  	if #cards>0
	then
		return policy(self,"@YingruiCard="..__hc_value_call(cards[1],"getEffectiveId"))
	end
end

sgs.ai_skill_use_func["YingruiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"card",true)
	for _,ep in sgs.list(self.enemies)do
		if ep:getCardCount()>0
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.YingruiCard = 4.4
sgs.ai_use_priority.YingruiCard = 3.8

sgs.ai_skill_discard.yingrui = function(self,x,n)
	local ids = {}
    local cards = sgs.QList2Table(self.player:getCards("he"))
    cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
		if #ids>=n then break end
		if __hc_value_call(h,"isKindOf","EquipCard") and self:isWeak()
		then table.insert(ids,__hc_value_call(h,"getEffectiveId")) end
	end
	return #ids>=n and ids or {}
end

sgs.ai_skill_invoke.fuyuan = function(self,data)
	local target = data:toPlayer()
	if target then
		return not self:isEnemy(target)
	end
end

sgs.ai_skill_choice.olfengji = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"draw")
	and #self.friends_noself>0
	and __hc_value_call(self.player,"getHandcardNum")>3
	then return "draw" end
	if table.contains(items,"slash")
	and #self.friends_noself>0
	then
		local slash = clone(self,"slash")
		local n = extra_targets(self,slash)
		for _,to in sgs.list(self.enemies)do
			if self.player:canSlash(to)
			and self:isWeak(to)
			then n = n-1 end
		end
		if n>0
		then
			return "slash"
		end
	end
	return items[#items]
end

sgs.ai_skill_playerchosen.olfengji = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
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




--魅步
sgs.ai_skill_cardask["@tenyearmeibu-dis"] = function(self,data)
	local player = data:toPlayer()
	if self:isEnemy(player)
	then
		local cards = {}
		for _,c in sgs.qlist(self.player:getCards("he"))do
			if self.player:canDiscard(self.player,__hc_value_call(c,"getEffectiveId"))
			then table.insert(cards,c) end
		end
		if #cards>0 then
			cards = self:sortByKeepValue(cards)
			for _,c in ipairs(cards)do
				if not self:isValuableCard(c) then return "$"..__hc_value_call(c,"getEffectiveId") end
			end
		end
	end
	if not self:isFriend(player)
	and not __hc_value_call(player,"hasSkill","tenyearzhixi",true)
	then
		if self:needToThrowArmor()
		and self.player:canDiscard(self.player,self.player:getArmor():getEffectiveId())
		then return "$"..self.player:getArmor():getEffectiveId() end
	end
	return "."
end

sgs.ai_skill_cardask["@secondtenyearmeibu-dis"] = function(self,data)
	return sgs.ai_skill_cardask["@tenyearmeibu-dis"](self,data)
end

--穆穆
sgs.ai_skill_invoke.tenyearmumu = function(self,data)
	local targets,targets2 = {},{}
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		if (self:isFriend(p) and p:hasSkills(sgs.lose_equip_skill)) or (self:isEnemy(p) and self:doDisCard(p,"e")) then
			table.insert(targets,p)
		end
		if not p:getArmor() then continue end
		if (self:isFriend(p) and p:hasSkills(sgs.lose_equip_skill)) or (self:isEnemy(p) and self:doDisCard(p,"e")) then
			table.insert(targets2,p)
		end
	end

	if #targets2>0 then
		local will_use_slash = false
		if self:getCardsNum("Slash")>0 then
			local slash = clone(self,"slash")
			local dummy_use = dummy_plan()
			for _,p in sgs.qlist(self.room:getAlivePlayers())do
				if not self:isWeak(p) then
					table.insert(dummy_use.current_targets,p)
				end
			end
			self:useCardSlash(slash,dummy_use)
			if dummy_use.card and dummy_use.to:length()>0 then
				will_use_slash = true
			end
		end
		if not will_use_slash then
			self:setStrategyMemory("choice_override:tenyearmumu","get")
			targets2 = self:sort(targets2)
			for _,p in ipairs(targets2)do
				if self:isEnemy(p) then
					self:setStrategyMemory("tenyear_hc.target_override:tenyearmumu",(p):objectName())
					return true
				end
			end
			self:setStrategyMemory("tenyear_hc.target_override:tenyearmumu",(targets2[1]):objectName())
			return true
		end
	end

	if #targets>0 then
		self:setStrategyMemory("choice_override:tenyearmumu","discard")
		targets = self:sort(targets)
		for _,p in ipairs(targets)do
			if self:isEnemy(p) then
				self:setStrategyMemory("tenyear_hc.target_override:tenyearmumu",(p):objectName())
				return true
			end
		end
		self:setStrategyMemory("tenyear_hc.target_override:tenyearmumu",(targets[1]):objectName())
		return true
	end
	return false
end

sgs.ai_skill_invoke.SecondTenyearMumu = function(self,data)
	local targets,targets2 = {},{}
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		if (self:isFriend(p) and p:hasSkills(sgs.lose_equip_skill)) or (self:isEnemy(p) and self:doDisCard(p,"e")) then
			table.insert(targets,p)
		end
		if not p:hasEquip() then continue end
		if (self:isFriend(p) and p:hasSkills(sgs.lose_equip_skill)) or (self:isEnemy(p) and self:doDisCard(p,"e")) then
			table.insert(targets2,p)
		end
	end

	if #targets2>0 then
		local will_use_slash = false
		if self:getCardsNum("Slash")>0 then
			local slash = clone(self,"slash")
			local dummy_use = dummy_plan()
			for _,p in sgs.qlist(self.room:getAlivePlayers())do
				if not self:isWeak(p) then
					table.insert(dummy_use.current_targets,p)
				end
			end
			self:useCardSlash(slash,dummy_use)
			if dummy_use.card and dummy_use.to:length()>0 then
				will_use_slash = true
			end
		end
		if not will_use_slash then
			self:setStrategyMemory("choice_override:secondtenyearmumu","get")
			targets2 = self:sort(targets2)
			for _,p in ipairs(targets2)do
				if self:isEnemy(p) then
					self:setStrategyMemory("tenyear_hc.target_override:secondtenyearmumu",(p):objectName())
					return true
				end
			end
			self:setStrategyMemory("tenyear_hc.target_override:secondtenyearmumu",(targets2[1]):objectName())
			return true
		end
	end

	if #targets>0 then
		self:setStrategyMemory("choice_override:secondtenyearmumu","discard")
		targets = self:sort(targets)
		for _,p in ipairs(targets)do
			if self:isEnemy(p) then
				self:setStrategyMemory("tenyear_hc.target_override:secondtenyearmumu",(p):objectName())
				return true
			end
		end
		self:setStrategyMemory("tenyear_hc.target_override:secondtenyearmumu",(targets[1]):objectName())
		return true
	end
	return false
end

--止息
sgs.ai_skill_discard.tenyearzhixi = function(self,discard_num,min_num,optional,include_equip)
	return self:askForDiscard("dummyreason",1,1,false,false)
end

--鬻爵
local function getYujueTarget(self)


	for _,p in ipairs(self.friends_noself)do
		if p:isKongcheng() then continue end
		if self:needToThrowLastHandcard(p) then
			return p
		end
	end
	self.friends_noself = self:sort(self.friends_noself,"handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,p in ipairs(self.friends_noself)do
		if self:doDisCard(p,"h") then
			return p
		end
	end
	for _,p in ipairs(self.friends_noself)do
		if p:isKongcheng() then continue end
		return p
	end
	return nil
end

sgs.ai_fill_skill["yujue"] = function(self,inclusive,request)
	local target = getYujueTarget(self)
	write_hc_source_global(self,"yujue_target",target)
	if target then
		return policy(self,"@YujueCard=.")
	end
end

sgs.ai_skill_use_func.YujueCard = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.YujueCard = 7
sgs.ai_use_value.YujueCard = 1

sgs.ai_skill_choice.yujue = function(self,choices,data)
	local items = choices:split("+")
	if self:needToThrowArmor() and self.player:hasEquipArea(1) and table.contains(items,"1") then
		return "1"
	elseif self.player:hasEquipArea(4) and not self.player:getTreasure() and table.contains(items,"4") then
		return "4"
	elseif self.player:hasEquipArea(1) and not self.player:getArmor() and table.contains(items,"1") then
		return "1"
	elseif self.player:hasEquipArea(0) and not self.player:getWeapon() and table.contains(items,"0") then
		return "0"
	elseif self.player:hasEquipArea(3) and not self.player:getOffensiveHorse() and table.contains(items,"3") then
		return "3"
	elseif self.player:hasEquipArea(2) and not self.player:getDefensiveHorse() and table.contains(items,"2") then
		return "2"
	elseif self.player:hasEquipArea(4) and not self:keepWoodenOx() and table.contains(items,"4") then
		return "4"
	elseif self.player:hasEquipArea(1) and table.contains(items,"1") then
		return "1"
	elseif self.player:hasEquipArea(0) and table.contains(items,"0") then
		return "0"
	elseif self.player:hasEquipArea(3) and table.contains(items,"3") then
		return "3"
	elseif self.player:hasEquipArea(2) and table.contains(items,"2") then
		return "2"
	else
		return items[1]
	end
	return items[math.random(1,#items)]
end

sgs.ai_skill_playerchosen.yujue = function(self,targets)
	ai_unsupported('actual global target provenance is unavailable across questions','yujue_target')
	-- The source may only reach its fallback after a lawful actual-global read.
	if self.yujue_target and targets:contains(self.yujue_target) then return self.yujue_target end
	local p = getYujueTarget(self)
	if p then return p end
	return targets:at(math.random(0,targets:length()-1))
end

sgs.ai_skill_discard.yujue = function(self,discard_num,min_num,optional,include_equip)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByUseValue(cards,true)
	return {__hc_value_call(cards[1],"getEffectiveId")}
end

--二版鬻爵
sgs.ai_fill_skill["secondyujue"] = function(self,inclusive,request)
	local target = getYujueTarget(self)
	write_hc_source_global(self,"secondyujue_target",target)
	if target then
		return policy(self,"@SecondYujueCard=.")
	end
end

sgs.ai_skill_use_func.SecondYujueCard = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.SecondYujueCard = sgs.ai_use_priority.YujueCard
sgs.ai_use_value.SecondYujueCard = sgs.ai_use_value.YujueCard

sgs.ai_skill_playerchosen.secondyujue = function(self,targets)
	ai_unsupported('actual global target provenance is unavailable across questions','secondyujue_target')
	-- The source may only reach its fallback after a lawful actual-global read.
	if self.secondyujue_target and targets:contains(self.secondyujue_target) then return self.secondyujue_target end
	local p = getYujueTarget(self)
	if p then return p end
	return targets:at(math.random(0,targets:length()-1))
end

--逆乱
sgs.ai_fill_skill["spniluan"] = function(self,inclusive,request)
	--if __hc_value_call(self.player,"hasSkill","nuzhan") then sgs.ai_use_priority.SpNiluanCard = sgs.ai_use_priority.Slash+0.05 end
	--return policy(self,"@SpNiluanCard=.")
	local allcards = self.player:getCards("he")
	allcards = sgs.QList2Table(allcards)
	for _,id in sgs.qlist(self.player:getHandPile())do
		if visible(self,id):isBlack() then
			table.insert(allcards,visible(self,id))
		end
	end
	local cards = {}
	allcards = self:sortByUseValue(allcards,true)
	for _,c in ipairs(allcards)do
		if not c:isBlack() then continue end
		local slash = clone(self)
		slash = mutate(self,slash,"skill","spniluan")
		slash = mutate(self,slash,"add",c)
		if __hc_value_call(slash,"isAvailable",self.player) then return slash end
	end
end

sgs.ai_skill_use_func.SpNiluanCard = function(card,use,self)
	local allcards = self.player:getCards("he")
	allcards = sgs.QList2Table(allcards)
	for _,id in sgs.qlist(self.player:getHandPile())do
		if visible(self,id):isBlack() then
			table.insert(allcards,visible(self,id))
		end
	end
	local cards = {}
	allcards = self:sortByUseValue(allcards,true)
	for _,c in ipairs(allcards)do
		if not c:isBlack() then continue end
		local slash = clone(self,"slash")
		slash = mutate(self,slash,"skill","spniluan")
		slash = mutate(self,slash,"add",c)
		if self.player:isLocked(slash) then continue end
		local dummy_use = dummy_plan()
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if __hc_value_call(p,"getHp")<=__hc_value_call(self.player,"getHp") then
				table.insert(dummy_use.current_targets,p)
			end
		end
		self:useCardSlash(slash,dummy_use)
		if dummy_use.card and dummy_use.to:length()>0 then
			table.insert(cards,c)
		end
	end
	if #cards==0 then return end
	local black_card
	local useAll = false
	self.enemies = self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if __hc_value_call(enemy,"getHp")==1 and not enemy:hasArmorEffect("EightDiagram") and __hc_value_call(self.player,"distanceTo",enemy)<=__hc_value_call(self.player,"getAttackRange") and self:isWeak(enemy)
			and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)==0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash")<2 or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao") then
		disCrossbow = true
	end

	local nuzhan_equip = false
	local nuzhan_equip_e = false
	self.enemies = self:sort(self.enemies,"defense")
	if __hc_value_call(self.player,"hasSkill","nuzhan") then
		for _,enemy in ipairs(self.enemies)do
			if not enemy:hasArmorEffect("EightDiagram") and __hc_value_call(self.player,"distanceTo",enemy)<=__hc_value_call(self.player,"getAttackRange")
			and getCardsNum("Jink",enemy)<1 then
				nuzhan_equip_e = true
				break
			end
		end
		for _,card in ipairs(cards)do
			if __hc_value_call(card,"isKindOf","TrickCard") and nuzhan_equip_e then
				nuzhan_equip = true
				break
			end
		end
	end

	local nuzhan_trick = false
	local nuzhan_trick_e = false
	self.enemies = self:sort(self.enemies,"defense")
	if __hc_value_call(self.player,"hasSkill","nuzhan") and not __hc_value_call(self.player,"hasFlag","hasUsedSlash") and self:getCardsNum("Slash")>1 then
		for _,enemy in ipairs(self.enemies)do
			if not enemy:hasArmorEffect("EightDiagram") and __hc_value_call(self.player,"distanceTo",enemy)<=__hc_value_call(self.player,"getAttackRange") then
				nuzhan_trick_e = true
				break
			end
		end
		for _,card in ipairs(cards)do
			if __hc_value_call(card,"isKindOf","TrickCard") and nuzhan_trick_e then
				nuzhan_trick = true
				break
			end
		end
	end

	for _,card in ipairs(cards)do
		local slash = clone(self,"slash")
		if not __hc_value_call(card,"isKindOf","Slash") and not (nuzhan_equip or nuzhan_trick)
			and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
			and (not isCard("Crossbow",card,self.player) or disCrossbow)
			and (self:getUseValue(card)<sgs.ai_use_value.Slash or residue(self,slash)>0) then
			black_card = card
			break
		end
	end

	if nuzhan_equip then
		for _,card in ipairs(cards)do
			if __hc_value_call(card,"isKindOf","EquipCard") then
				black_card = card
				break
			end
		end
	end

	if nuzhan_trick then
		for _,card in ipairs(cards)do
			if __hc_value_call(card,"isKindOf","TrickCard")then
				black_card = card
				break
			end
		end
	end

	if black_card then
		local slash = clone(self,"slash")
		slash = mutate(self,slash,"skill","spniluan")
		slash = mutate(self,slash,"add",black_card)
		if self.player:isLocked(slash) then return end
		local dummy_use = dummy_plan()
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if __hc_value_call(p,"getHp")<=__hc_value_call(self.player,"getHp") then
				table.insert(dummy_use.current_targets,p)
			end
		end
		self:useCardSlash(slash,dummy_use)
		if dummy_use.card and dummy_use.to:length()>0 then
			use.card = policy(self,"@SpNiluanCard="..__hc_value_call(black_card,"getEffectiveId"))
			for i = 1,math.min(dummy_use.to:length(),1+residue(self,slash))do
				use.to:append(dummy_use.to:at(i-1))
			end
		end
	end
end

sgs.ai_use_priority.SpNiluanCard = sgs.ai_use_priority.Slash-0.05

--违忤
sgs.ai_fill_skill["weiwu"] = function(self,inclusive,request)
	if self.player:isNude() and self.player:getHandPile():isEmpty() then return end
	return policy(self,"@WeiwuCard=.")
end

sgs.ai_skill_use_func.WeiwuCard = function(card,use,self)
	local disCrossbow = false
	if self:getCardsNum("Slash")<2 or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao") then
		disCrossbow = true
	end
	local allcards = {}
	for _,c in sgs.qlist(self.player:getCards("he"))do
		if __hc_value_call(c,"isKindOf","WoodenOx") and not self.player:getPile("wooden_ox"):isEmpty() then continue end
		if c:isRed() and not __hc_value_call(c,"isKindOf","Snatch") and not __hc_value_call(c,"isKindOf","Peach") and not __hc_value_call(c,"isKindOf","ExNihilo") and (not __hc_value_call(c,"isKindOf","Crossbow") or disCrossbow) then
			table.insert(allcards,c)
		end
	end
	for _,id in sgs.qlist(self.player:getHandPile())do
		local c = visible(self,id)
		if c:isRed() and not __hc_value_call(c,"isKindOf","Snatch") and not __hc_value_call(c,"isKindOf","Peach") and not __hc_value_call(c,"isKindOf","ExNihilo") and (not __hc_value_call(c,"isKindOf","Crossbow") or disCrossbow) then
			table.insert(allcards,c)
		end
	end
	if #allcards==0 then return end
	allcards = self:sortByUseValue(allcards,true)
	local cards = {}
	for _,c in ipairs(allcards)do
		local snatch = clone(self,"snatch")
		snatch = mutate(self,snatch,"skill","weiwu")
		snatch = mutate(self,snatch,"add",c)
		if self.player:isLocked(snatch) then continue end
		local dummy_use = dummy_plan()
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if __hc_value_call(p,"getHandcardNum")<=__hc_value_call(self.player,"getHandcardNum") then
				table.insert(dummy_use.current_targets,p)
			end
		end
		self:aiUseCard(snatch,dummy_use)
		if dummy_use.card and dummy_use.to:length()>0 then
			if self:getUseValue(c)<self:getUseValue(snatch) or residue(self,snatch)>0 then
				table.insert(cards,c)
			end
		end
	end
	if #cards==0 then return end
	local snatch = clone(self,"snatch")
	snatch = mutate(self,snatch,"skill","weiwu")
	snatch = mutate(self,snatch,"add",cards[1])
	if self.player:isLocked(snatch) then return end
	local dummy_use = dummy_plan()
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if __hc_value_call(p,"getHandcardNum")<=__hc_value_call(self.player,"getHandcardNum")
		then table.insert(dummy_use.current_targets,p) end
	end
	self:aiUseCard(snatch,dummy_use)
	if dummy_use.card and dummy_use.to:length()>0 then
		use.card = policy(self,"@WeiwuCard="..__hc_value_call(cards[1],"getEffectiveId"))
		for i = 1,math.min(dummy_use.to:length(),1+residue(self,snatch))do
			use.to:append(dummy_use.to:at(i-1))
		end
	end
end

sgs.ai_use_priority.WeiwuCard = sgs.ai_use_priority.Snatch+0.05

--攻坚
local function gongjianDoNotDis2(self,to)
	if to:getCardCount(true)<2 then return true end
    local n = 0
	if self:doDisCard(to,"e") then
		for _,c in sgs.qlist(to:getCards("e"))do
			if self.player:canDiscard(to,__hc_value_call(c,"getEffectiveId")) then n = n+1 end
		end
	end
	if n<2 then
		if not self:hasLoseHandcardEffective(to,2-n) then return true end
		if __hc_value_call(to,"getHandcardNum")<=2-n and self:needKongcheng(to) then return true end
	end
	if self:hasSkills(sgs.lose_equip_skill,to) and __hc_value_call(to,"getHandcardNum")<2 then return true end
	if to:getCardCount(true)<=2 and self:needToThrowArmor(to) then return true end
end

sgs.ai_skill_invoke.gongjian = function(self,data)
	local player = data:toPlayer()
	if self:isFriend(player) then return false end

	local use = tag(self,"gongjianData","CardUse")
	if not use then

		return self:doDisCard(player,"he")
	end

	if player:objectName()==use.to:last():objectName() then

		return self:doDisCard(player,"he")
	end

	local players = {}
	local names = fact(self,"gongjian_slash_targets")
	for _,p in sgs.qlist(use.to)do
		if self:isFriend(p) or not table.contains(names,p:objectName()) then continue end
		local n = __hc_value_call(p,"getHandcardNum")
		for _,c in sgs.qlist(p:getCards("e"))do
			if n>=2 then break end
			if self.player:canDiscard(p,__hc_value_call(c,"getEffectiveId")) then n = n+1 end
		end
		if n==0 then continue end
		n = math.min(2,n)
		if n==2 and not gongjianDoNotDis2(self,p) then
			table.insert(players,p)
		end
	end
	if #players>0 then
		players = self:sort(players)
		return player:objectName()==players[1]:objectName()
	end
	for _,p in sgs.qlist(use.to)do
		if self:isFriend(p) or not table.contains(names,p:objectName()) then continue end
		if not self:doDisCard(player,"he") then continue end
		table.insert(players,p)
	end
	if #players>0 then
		players = self:sort(players)
		return player:objectName()==players[1]:objectName()
	end
	return false
end

sgs.ai_skill_choice.gongjian = function(self,choices,data)
	local player = data:toPlayer()
	if self:isFriend(player) and self:needToThrowLastHandcard(player,2) then return "2" end
	if self:isFriend(player) then return "1" end
	if gongjianDoNotDis2(self,player) then return "1" end
	return "2"
end

--慈孝
sgs.ai_skill_playerchosen.cixiao = function(self,targets)
	if #self.enemies>0 then
		self:sort(self.enemies,"chaofeng")
		local n = math.random(1,100)
		if n<=25 then self:emitSpeechLine(self.player,"伤害不高，但侮辱性极强","tenyear_hc:cixiao") end
		return self.enemies[1]
	end
	return nil
end

sgs.ai_skill_use["@@cixiao"] = function(self,prompt,method)
	if #self.enemies>0 then
		self.enemies = self:sort(self.enemies,"chaofeng")
		self.enemies = sgs.reverse(self.enemies)
		local first
		if __hc_value_call(self.player,"getMark","&cxyizi")>0 then first = self.player:objectName() end
		if not first then
			for _,p in ipairs(self.enemies)do
				if __hc_value_call(p,"getMark","&cxyizi")>0 then
					first = p:objectName()
					break
				end
			end
		end
		if not first then return "." end
		local second
		self.enemies = sgs.reverse(self.enemies)

		if self:needToThrowArmor() and self.player:canDiscard(self.player,self.player:getArmor():getEffectiveId()) then
			for _,p in ipairs(self.enemies)do
				if __hc_value_call(p,"getMark","&cxyizi")==0 and p:objectName()~=first then
					second = p:objectName()
					break
				end
			end
			if second then
				return "@CixiaoCard="..self.player:getArmor():getEffectiveId().."->"..first.."+"..second
			end
			for _,p in ipairs(self.enemies)do
				if p:objectName()~=first then
					second = p:objectName()
					break
				end
			end
			if second then
				return "@CixiaoCard="..self.player:getArmor():getEffectiveId().."->"..first.."+"..second
			end
			if self.player:objectName()~=first then
				return "@CixiaoCard="..self.player:getArmor():getEffectiveId().."->"..first.."+"..self.player:objectName()
			end
			return "."
		end

		for _,p in ipairs(self.enemies)do
			if p:objectName()==first then break end
			if __hc_value_call(p,"getMark","&cxyizi")==0 then
				second = p:objectName()
				break
			end
		end
		if not second then return "." end
		local cards = sgs.QList2Table(self.player:getCards("he"))
		cards = self:sortByKeepValue(cards)
		for _,c in ipairs(cards)do
			if not self:isValuableCard(c) and self.player:canDiscard(self.player,__hc_value_call(c,"getEffectiveId")) then
				return "@CixiaoCard="..__hc_value_call(c,"getEffectiveId").."->"..first.."+"..second
			end
		end
	end
	return "."
end

--叛弑
sgs.ai_skill_askforyiji.panshi = function(self,card_ids)
	local cards = {}
	for _,id in ipairs(card_ids)do
		table.insert(cards,visible(self,id))
	end
	cards = self:sortByUseValue(cards,true)

	local dingyuans,num,fri = {},0,0
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		if __hc_value_call(p,"hasFlag","dingyuan") then
			table.insert(dingyuans,p)
			if not self:isEnemy(p) then
				num = num+1
			end
			if self:isFriend(p) then
				fri = fri+1
			end
		end
	end
	dingyuans = self:sort(dingyuans)
	if __hc_value_call(self.player,"getHandcardNum")<=num then
		for _,p in ipairs(dingyuans)do
			if self:isFriend(p) then
				return p,__hc_value_call(cards[1],"getEffectiveId")
			end
		end
		for _,p in ipairs(dingyuans)do
			if not self:isEnemy(p) then
				return p,__hc_value_call(cards[1],"getEffectiveId")
			end
		end
		return dingyuans[1],__hc_value_call(cards[1],"getEffectiveId")
	else
		for _,p in ipairs(dingyuans)do
			if self:isEnemy(p) then
				return p,__hc_value_call(cards[1],"getEffectiveId")
			end
		end

		if __hc_value_call(self.player,"getHandcardNum")<=fri then
			for _,p in ipairs(dingyuans)do
				if self:isFriend(p) then
					return p,__hc_value_call(cards[1],"getEffectiveId")
				end
			end
			return dingyuans[1],__hc_value_call(cards[1],"getEffectiveId")
		else
			for _,p in ipairs(dingyuans)do
				if not self:isFriend(p) then
					return p,__hc_value_call(cards[1],"getEffectiveId")
				end
			end
			return dingyuans[1],__hc_value_call(cards[1],"getEffectiveId")
		end
	end
	return dingyuans[1],__hc_value_call(cards[1],"getEffectiveId")
end

--节应
sgs.ai_skill_playerchosen.jieyingh = function(self,targets)
	local slash = clone(self)
	self.enemies = self:sort(self.enemies,"handcard",true)
	for _,p in ipairs(self.enemies)do
		if self:canUse(slash,self.friends,p)
		and (self:hasCrossbowEffect(p) or p:hasSkills(sgs.double_slash_skill))
		then
			if getCardsNum("Slash",p,self.player)>1
			then return p end
		end
	end
	self.friends_noself = self:sort(self.friends_noself,"handcard")
	for _,p in ipairs(self.friends_noself)do
		if #self:getEnemies(p)>1
		and getCardsNum("ExNihilo,Snatch,Dismantlement,Duel",p,self.player)>0
		then return p end
	end
	for _,p in ipairs(self.friends_noself)do
		if not self:hasCrossbowEffect(p) then
			if (getCardsNum("Slash",p,self.player)>0 or __hc_value_call(p,"getHandcardNum")>=3)
			and not self:canUse(slash,self:getEnemies(p),p)
			then
				for _,enemy in ipairs(self:getEnemies(p))do
					if p:canSlash(enemy,nil,false) and not __hc_value_call(p,"inMyAttackRange",enemy)
					then return p end
				end
			end
		end
	end
	for _,p in ipairs(self.friends_noself)do
		if (getCardsNum("Slash",p,self.player)>0 or __hc_value_call(p,"getHandcardNum")>=3)
		and not self:canUse(slash,self:getEnemies(p),p)
		then
			for _,enemy in ipairs(self:getEnemies(p))do
				if p:canSlash(enemy,nil,false) and not __hc_value_call(p,"inMyAttackRange",enemy)
				then return p end
			end
		end
	end
	for _,p in ipairs(self.friends_noself)do
		if self:canUse(slash,self:getEnemies(p),p) and #self:getEnemies(p)>1
		and (getCardsNum("Slash",p,self.player)==1 or __hc_value_call(p,"getHandcardNum")>=3)
		then return p end
	end
	for _,p in ipairs(self.friends_noself)do
		if __hc_value_call(p,"getHandcardNum")<3
		then return p end
	end
	self.enemies = self:sort(self.enemies,"handcard")
	if #self.enemies>0 and #self:getEnemies(self.enemies[1])<=1
	then return self.enemies[1] end--]]
end

sgs.ai_skill_use["@@jieyingh"] = function(self,prompt,method)
	if __hc_value_call(self.player,"hasFlag","jieyingh_now_use_collateral")
	then
		local dummy_use = dummy_plan()
		dummy_use.current_targets = property(self,"extra_collateral"):split("+")
		local card = policy(self,dummy_use.current_targets[1])
		if not card then return "." end
		self:useCardCollateral(card,dummy_use)
		if dummy_use.card and dummy_use.to:length()==2 then
			return "@ExtraCollateralCard=.->"..dummy_use.to:first().."+"..dummy_use.to:last()
		end
	else
        return self:withNestedDelegateUse("@@jieyingh",function(use)
		if not use then return "." end
		local tos = AIList.new({})
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if use.to:contains(p) then continue end
			if self.player:canUse(use.card,p,true)
			then tos:append(p) end
		end
		tos = sgs.ai_skill_playerchosen.yb_zhuzhan2(self,tos)
		if tos then return "@JieyinghCard=.->"..tos:objectName() end
        return "."
        end)
	end
	return "."
end

--危迫
sgs.ai_skill_discard.weipo = function(self,discard_num,min_num,optional,include_equip)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByUseValue(cards,true)
	return {__hc_value_call(cards[1],"getEffectiveId")}
end

--敏思
sgs.ai_fill_skill["minsi"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local function toids(cs)
		local ids = {}
		for _,c1 in sgs.list(cs)do
			table.insert(ids,__hc_value_call(c1,"getEffectiveId"))
		end
		return ids
	end
	local function minsiNumber(cs,c)
		local n = __hc_value_call(c,"getNumber")
		for _,c1 in sgs.list(cs)do
			n = n+__hc_value_call(c1,"getNumber")
		end
		return n==13 and 2 or n<=13 and 1 or 0
	end
  	for _,c in sgs.list(cards)do
		local cs = {c}
		for i,c1 in sgs.list(cards)do
			if table.contains(cs,c1) then continue end
			i = minsiNumber(cs,c1)
			if i>0
			then
				table.insert(cs,c1)
				if i>1
				then
					cs = toids(cs)
					return policy(self,"@MinsiCard="..table.concat(cs,"+"))
				end
				for i,c2 in sgs.list(cards)do
					if table.contains(cs,c2) then continue end
					i = minsiNumber(cs,c2)
					if i>0
					then
						table.insert(cs,c2)
						if i>1
						then
							cs = toids(cs)
							return policy(self,"@MinsiCard="..table.concat(cs,"+"))
						end
					end
				end
			end
		end
	end
  	for _,c in sgs.list(cards)do
		if __hc_value_call(c,"getNumber")==13
		then
			return policy(self,"@MinsiCard="..__hc_value_call(c,"getEffectiveId"))
		end
	end
end

sgs.ai_skill_use_func["MinsiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.MinsiCard = 9.4
sgs.ai_use_priority.MinsiCard = 4.8

--吉境
sgs.ai_skill_invoke.jijing = function(self,data)
    return __hc_value_call(self.player,"isWounded")
end

sgs.ai_skill_use["@@jijing"] = function(self,prompt)
	local valid,ts = {},AIList.new({})
	local jn = property(self,"jijing_judge")
	local function toids(cs)
		local ids = {}
		for _,c1 in sgs.list(cs)do
			table.insert(ids,__hc_value_call(c1,"getEffectiveId"))
		end
		return ids
	end
	local function minsiNumber(cs,c)
		local n = __hc_value_call(c,"getNumber")
		for _,c1 in sgs.list(cs)do
			n = n+__hc_value_call(c1,"getNumber")
		end
		return n==jn and 2 or n<=jn and 1 or 0
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if __hc_value_call(c,"getNumber")==jn
		then
			return string.format("@JijingCard=%s",__hc_value_call(c,"getEffectiveId"))
		end
	end
  	for _,c in sgs.list(cards)do
		local cs = {c}
		for i,c1 in sgs.list(cards)do
			if table.contains(cs,c1) then continue end
			i = minsiNumber(cs,c1)
			if i>0
			then
				table.insert(cs,c1)
				if i>1
				then
					cs = toids(cs)
					return string.format("@JijingCard=%s",table.concat(cs,"+"))
				end
				for i,c2 in sgs.list(cards)do
					if table.contains(cs,c2) then continue end
					i = minsiNumber(cs,c2)
					if i>0
					then
						table.insert(cs,c2)
						if i>1
						then
							cs = toids(cs)
							return string.format("@JijingCard=%s",table.concat(cs,"+"))
						end
					end
				end
			end
		end
	end
end

--追德
sgs.ai_skill_playerchosen.zhuide = function(self,targets)
	self.friends_noself = self:sort(self.friends_noself)
	for _,p in ipairs(self.friends_noself)do
		if self:needKongcheng(p,true) or hasManjuanEffect(p) then continue end
		return p
	end
	local jink,ana,peach,slash = false,false,false,false
	for _,id in sgs.qlist(private_draw(self))do
		local card = visible(self,id)
		if __hc_value_call(card,"isKindOf","Jink") then jink = true
		elseif __hc_value_call(card,"isKindOf","Analeptic") then ana = true
		elseif __hc_value_call(card,"isKindOf","Peach") then peach = true
		elseif __hc_value_call(card,"isKindOf","Slash") then slash = true end
		if jink and ana and peach and slash then break end
	end
	if (jink and ana) or (jink and peach) or (ana and peach) then
		for _,p in ipairs(self.friends_noself)do
			if hasManjuanEffect(p) then continue end
			return p
		end
	end
	if slash and not jink and not ana and not peach then
		self.enemies = self:sort(self.enemies)
		for _,p in ipairs(self.enemies)do
			if hasManjuanEffect(p) then continue end
			if not self:needKongcheng(p,true) then continue end
			if self:getEnemyNumBySeat(self.player,p,p)>0 then
				return p
			end
		end
	end
	return nil
end

--毒逝
sgs.ai_skill_playerchosen.spdushi = function(self,targets)
	targets = sgs.QList2Table(targets)
	for _,p in ipairs(targets)do
		if self:isEnemy(p) and not __hc_value_call(p,"hasSkill","spdushi",true) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if not self:isFriend(p) and not __hc_value_call(p,"hasSkill","spdushi",true) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if self:isEnemy(p) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if not self:isFriend(p) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if self:isFriend(p) and __hc_value_call(p,"hasSkill","spdushi",true) then
			return p
		end
	end
	targets = sgs.reverse(targets)
	return targets[1]
end

--盗戟
sgs.ai_fill_skill["daoji"] = function(self,inclusive,request)
	return policy(self,"@DaojiCard=.")
end

sgs.ai_skill_use_func.DaojiCard = function(card,use,self)
	local id = -1
	if self:needToThrowArmor() and self.player:canDiscard(self.player,self.player:getArmor():getEffectiveId()) then id = self.player:getArmor():getEffectiveId() end
	if id<0 and self.player:getWeapon() and self.player:canDiscard(self.player,self.player:getWeapon():getEffectiveId()) then id = self.player:getWeapon():getEffectiveId() end
	local cards = {}
	for _,c in sgs.qlist(self.player:getCards("he"))do
		if __hc_value_call(c,"isKindOf","BasicCard") or self.player:canDiscard(self.player,__hc_value_call(c,"getEffectiveId")) then continue end
		table.insert(cards,c)
	end
	if #cards>0 then
		cards = self:sortByKeepValue(cards)
		if cards[1]:objectName()~="wooden_ox" or self.player:getPile("wooden_ox"):isEmpty() then
			if id<0 then id = __hc_value_call(cards[1],"getEffectiveId") end
		end
	end

	self.enemies = self:sort(self.enemies,"hp")
	self:writeDaojiSourceCard(nil)
	if id>=0 then
		for _,p in ipairs(self.enemies)do
			local damage = self:ajustDamage(self.player,p)
			if damage>=__hc_value_call(p,"getHp") and self:damageIsEffective(p,nil,self.player) and p:getWeapon() then
				local weapon = visible(self,p:getWeapon():getEffectiveId())
				if self.player:canUse(weapon) then
					self:writeDaojiSourceCard(weapon)
					use.card = policy(self,"@DaojiCard="..id)
					use.to:append(p)
					return
				end
			end
		end
		for _,p in ipairs(self.enemies)do
			if self:damageIsEffective(p,nil,self.player) and p:getWeapon() and self:doDisCard(p,"e",true) then
				local weapon = visible(self,p:getWeapon():getEffectiveId())
				if self.player:canUse(weapon) then
					self:writeDaojiSourceCard(weapon)
					use.card = policy(self,"@DaojiCard="..id)
					use.to:append(p)
					return
				end
			end
		end
	end

	self.enemies = self:sort(self.enemies)
	if self.player:getTreasure() and self.player:canDiscard(self.player,self.player:getTreasure():getEffectiveId()) then
		if self.player:getTreasure():objectName()~="wooden_ox" or self.player:getPile("wooden_ox"):isEmpty() then
			for _,p in ipairs(self.enemies)do
				if p:getTreasure() and self:doDisCard(p,"e",true) then
					local treasure = visible(self,p:getTreasure():getEffectiveId())
					if treasure:objectName()=="wooden_ox" and not p:getPile("wooden_ox"):isEmpty() then
						if self.player:canUse(treasure) then
							self:writeDaojiSourceCard(treasure)
							use.card = policy(self,"@DaojiCard="..self.player:getTreasure():getEffectiveId())
							use.to:append(p)
							return
						end
					end
				end
			end
		end
	end
	if self.player:getArmor() and self.player:canDiscard(self.player,self.player:getArmor():getEffectiveId()) then
		for _,p in ipairs(self.enemies)do
			if p:getArmor() and self:doDisCard(p,"e",true) then
				local armor = visible(self,p:getArmor():getEffectiveId())
				if self.player:canUse(armor) then
					self:writeDaojiSourceCard(armor)
					use.card = policy(self,"@DaojiCard="..self.player:getArmor():getEffectiveId())
					use.to:append(p)
					return
				end
			end
		end
	end
	if self.player:getDefensiveHorse() and self.player:canDiscard(self.player,self.player:getDefensiveHorse():getEffectiveId()) then
		for _,p in ipairs(self.enemies)do
			if p:getDefensiveHorse() and self:doDisCard(p,"e",true) then
				local horse = visible(self,p:getDefensiveHorse():getEffectiveId())
				if self.player:canUse(horse) then
					self:writeDaojiSourceCard(horse)
					use.card = policy(self,"@DaojiCard="..self.player:getDefensiveHorse():getEffectiveId())
					use.to:append(p)
					return
				end
			end
		end
	end
	if self.player:getOffensiveHorse() and self.player:canDiscard(self.player,self.player:getOffensiveHorse():getEffectiveId()) then
		for _,p in ipairs(self.enemies)do
			if p:getOffensiveHorse() and self:doDisCard(p,"e",true) then
				local horse = visible(self,p:getOffensiveHorse():getEffectiveId())
				if self.player:canUse(horse) then
					self:writeDaojiSourceCard(horse)
					use.card = policy(self,"@DaojiCard="..self.player:getOffensiveHorse():getEffectiveId())
					use.to:append(p)
					return
				end
			end
		end
	end
	if self.player:getTreasure() and self.player:canDiscard(self.player,self.player:getTreasure():getEffectiveId()) then
		if self.player:getTreasure():objectName()~="wooden_ox" or self.player:getPile("wooden_ox"):isEmpty() then
			for _,p in ipairs(self.enemies)do
				if p:getTreasure() and self:doDisCard(p,"e",true) then
					local treasure = visible(self,p:getTreasure():getEffectiveId())
					if self.player:canUse(treasure) then
						self:writeDaojiSourceCard(treasure)
						use.card = policy(self,"@DaojiCard="..self.player:getTreasure():getEffectiveId())
						use.to:append(p)
						return
					end
				end
			end
		end
	end

	if id>=0 then
		for _,p in ipairs(self.enemies)do
			if self:doDisCard(p,"e",true) then
				local c
				if p:getTreasure() and p:getTreasure():objectName()=="wooden_ox" and not p:getPile("wooden_ox"):isEmpty() then
					c = visible(self,p:getTreasure():getEffectiveId())
				elseif p:getArmor() and not self.player:getArmor() then
					c = visible(self,p:getArmor():getEffectiveId())
				elseif p:getDefensiveHorse() and not self.player:getDefensiveHorse() then
					c = visible(self,p:getDefensiveHorse():getEffectiveId())
				elseif p:getOffensiveHorse() and not self.player:getOffensiveHorse() then
					c = visible(self,p:getOffensiveHorse():getEffectiveId())
				elseif p:getTreasure() and not self.player:getTreasure() then
					c = visible(self,p:getTreasure():getEffectiveId())
				end
				if c then
					self:writeDaojiSourceCard(treasure)
					use.card = policy(self,"@DaojiCard="..id)
					use.to:append(p)
					return
				end
			end
		end
		for _,p in ipairs(self.enemies)do
			if self:doDisCard(p,"e",true) then
				use.card = policy(self,"@DaojiCard="..id)
				use.to:append(p)
				return
			end
		end
	end
end

sgs.ai_use_priority.DaojiCard = sgs.ai_use_priority.Slash+0.1

sgs.ai_skill_cardchosen.daoji = function(self,who,flags)
	if self:daojiSourceCardPresent() then
        local source_equips = who:getCards("e")
        if self:daojiSourceCardInEquips(who,source_equips) then return self:readDaojiSourceCard(who,source_equips) end
    end
	if who:getCards("e"):length()==1 then return who:getCards("e"):first() end
	return self:askForCardChosen(who,"e","snatch")
end

--手杀逆乱
sgs.ai_skill_cardask["@mobileniluan"] = function(self,data,pattern,target)
	if target then
		for _,slash in ipairs(self:getCards("Slash"))do
			if self:isFriend(target) and self:slashIsEffective(slash,target) then
				if self:needLeiji(target,self.player) then return slash:getLegacyStringKey() end
				if self:needToLoseHp(target,self.player,slash,true) then return slash:getLegacyStringKey() end
			end
			if self:isEnemy(target) and self:slashIsEffective(slash,target)
			and not self:needToLoseHp(target,self.player,slash) and not self:needLeiji(target,self.player)
			then return slash:getLegacyStringKey() end
		end
	end
	return "."
end

--骁袭
sgs.ai_view_as.mobilexiaoxi = function(card,player,card_place)
	local suit = __hc_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __hc_value_call(card,"getEffectiveId")
	if card_place~=sgs.Player_PlaceSpecial and card:isBlack() and not __hc_value_call(card,"isKindOf","Peach") and not __hc_value_call(card,"hasFlag","using") then
		return ("slash:mobilexiaoxi[%s:%s]=%d"):format(suit,number,card_id)
	end
end

sgs.ai_fill_skill["mobilexiaoxi"] = function(self,inclusive,request)
	local cards = self:addHandPile("he")
	local red_card
	cards = self:sortByUseValue(cards,true)

	local useAll = false
	self.enemies = self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if __hc_value_call(enemy,"getHp")==1 and not enemy:hasArmorEffect("EightDiagram") and __hc_value_call(self.player,"distanceTo",enemy)<=__hc_value_call(self.player,"getAttackRange") and self:isWeak(enemy)
			and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)==0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash")<2 or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao") then
		disCrossbow = true
	end

	local nuzhan_equip = false
	local nuzhan_equip_e = false
	self.enemies = self:sort(self.enemies,"defense")
	if __hc_value_call(self.player,"hasSkill","nuzhan") then
		for _,enemy in ipairs(self.enemies)do
			if  not enemy:hasArmorEffect("EightDiagram") and __hc_value_call(self.player,"distanceTo",enemy)<=__hc_value_call(self.player,"getAttackRange")
			and getCardsNum("Jink",enemy)<1 then
				nuzhan_equip_e = true
				break
			end
		end
		for _,card in ipairs(cards)do
			if card:isBlack() and __hc_value_call(card,"isKindOf","TrickCard") and nuzhan_equip_e then
				nuzhan_equip = true
				break
			end
		end
	end

	local nuzhan_trick = false
	local nuzhan_trick_e = false
	self.enemies = self:sort(self.enemies,"defense")
	if __hc_value_call(self.player,"hasSkill","nuzhan") and not __hc_value_call(self.player,"hasFlag","hasUsedSlash") and self:getCardsNum("Slash")>1 then
		for _,enemy in ipairs(self.enemies)do
			if  not enemy:hasArmorEffect("EightDiagram") and __hc_value_call(self.player,"distanceTo",enemy)<=__hc_value_call(self.player,"getAttackRange") then
				nuzhan_trick_e = true
				break
			end
		end
		for _,card in ipairs(cards)do
			if card:isBlack() and __hc_value_call(card,"isKindOf","TrickCard") and nuzhan_trick_e then
				nuzhan_trick = true
				break
			end
		end
	end

	for _,card in ipairs(cards)do
		if card:isBlack() and not __hc_value_call(card,"isKindOf","Slash") and not (nuzhan_equip or nuzhan_trick)
			and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
			and (not isCard("Crossbow",card,self.player) or disCrossbow)
			and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or residue(self,clone(self,"slash"))>0) then
			red_card = card
			break
		end
	end

	if nuzhan_equip then
		for _,card in ipairs(cards)do
			if card:isBlack() and __hc_value_call(card,"isKindOf","EquipCard") then
				red_card = card
				break
			end
		end
	end

	if nuzhan_trick then
		for _,card in ipairs(cards)do
			if card:isBlack() and __hc_value_call(card,"isKindOf","TrickCard")then
				red_card = card
				break
			end
		end
	end

	if red_card then
		local suit = __hc_value_call(red_card,"getSuitString")
		local number = red_card:getNumberString()
		local card_id = __hc_value_call(red_card,"getEffectiveId")
		return policy(self,("slash:mobilexiaoxi[%s:%s]=%d"):format(suit,number,card_id))
	end
end

function sgs.ai_cardneed.mobilexiaoxi(to,card)
	return __hc_value_call(to,"getHandcardNum")<3 and card:isBlack()
end

--评荐
sgs.ai_skill_invoke.pingjian = function(self,data)
    return true
end

local function PingjianSkill(self,player)
	local pingjian_skills = property(self,"pingjian_has_used_skills")
	local sks,descriptions = pingjian_catalog(self)
	for i=1,99 do
		if #sks<1 then break end
		local sk = sks[math.random(1,#sks)]
		if table.contains(pingjian_skills,sk.name) then continue end
		i = pingjian_skill(self,sk.name,descriptions)
		if i
		then
			i = i:getDescription()
			if string.find(i,"出牌阶段限一次，")
			or string.find(i,"阶段技，")
			or string.find(i,"出牌阶段限一次。")
			or string.find(i,"阶段技。")
			or string.find(i,"出牌阶段限一次")
			or string.find(i,"阶段技")
			then return sk end
		end
	end
end

sgs.ai_fill_skill["pingjian"]=function(self,inclusive,request)
	for i=1,3 do
		local tosk = PingjianSkill(self,self.player)
		if tosk and pingjian_play(self,tosk.name) then
			self.pjsk_to = known(sgs.ai_fill_skill[tosk.name],"temporary source skill policy")(self,false)
			if not self.pjsk_to then continue end
			local use = self:aiUseCard(self.pjsk_to)
			if use.card then
				self.pjsk_to = use.to
				self:setPriorityValue("PingjianCard",sgs.ai_use_priority[__hc_value_call(use.card,"getClassName")] or 5,"tenyear_hc")
				if __hc_value_call(use.card,"getTypeId")>0 then
					return policy(self,"@PingjianCard="..use.card:subcardString()..":"..tosk.name)
				end
				local us = use.card:getLegacyStringKey():split(":")
				return policy(self,"@PingjianCard="..use.card:subcardString()..":"..tosk.name.."|"..(us[3] or ""))
			end
		end
	end
end

sgs.ai_skill_use_func["PingjianCard"] = function(card,use,self)
	if self.pjsk_to then
		use.card = card
		use.to = self.pjsk_to
	end
end

sgs.ai_use_value.PingjianCard = 9.4
sgs.ai_use_priority.PingjianCard = 10.8


--授符
sgs.ai_fill_skill["shoufu"] = function(self,inclusive,request)
	for _,p in ipairs(self.enemies)do
		if p:getPile("sflu"):isEmpty() then
			return policy(self,"@ShoufuCard=.")
		end
	end
end

sgs.ai_skill_use_func.ShoufuCard = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.ShoufuCard = sgs.ai_use_priority.Slash+1
sgs.ai_use_value.ShoufuCard = 3.4

sgs.ai_skill_use["@@shoufu!"] = function(self,prompt,method)
	self.enemies = self:sort(self.enemies,"handcard")
	self.enemies = sgs.reverse(self.enemies)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	for _,p in ipairs(self.enemies)do
		if p:getPile("sflu"):isEmpty() then
			return "@ShoufuPutCard="..__hc_value_call(cards[1],"getEffectiveId").."->"..p:objectName()
		end
	end
	return "."
end

--颂词
sgs.ai_fill_skill["tenyearsongci"] = function(self,inclusive,request)
	return policy(self,"@TenyearSongciCard=.")
end

sgs.ai_skill_use_func.TenyearSongciCard = function(card,use,self)
	self.friends = self:sort(self.friends,"handcard")
	for _,friend in ipairs(self.friends)do
		if __hc_value_call(friend,"getMark","tenyearsongci"..self.player:objectName())==0 and __hc_value_call(friend,"getHandcardNum")<=__hc_value_call(friend,"getHp") and self:canDraw(friend) then
			use.card = policy(self,"@TenyearSongciCard=.")
			use.to:append(friend)
			return
		end
	end

	self.enemies = self:sort(self.enemies,"handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,enemy in ipairs(self.enemies)do
		if __hc_value_call(enemy,"getMark","tenyearsongci"..self.player:objectName())==0 and __hc_value_call(enemy,"getHandcardNum")>__hc_value_call(enemy,"getHp") and not enemy:isNude()
		and self:doDisCard(enemy,"he",false,2) then
			use.card = policy(self,"@TenyearSongciCard=.")
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_use_value.TenyearSongciCard = sgs.ai_use_value.SongciCard
sgs.ai_use_priority.TenyearSongciCard = sgs.ai_use_priority.SongciCard

--游龙
sgs.ai_fill_skill["youlong"]=function(self,inclusive,request)
	for _,name in sgs.list(source_patterns(self))do
        local c = clone(self,name)
		if c and __hc_value_call(c,"isAvailable",self.player)
		and __hc_value_call(self.player,"getMark","youlong_"..name)<1
		and (__hc_value_call(c,"isKindOf","BasicCard") and __hc_value_call(self.player,"getMark","youlong_basic_lun")<1 and self.player:getChangeSkillState("youlong")>1
		or c:isNDTrick() and __hc_value_call(self.player,"getMark","youlong_trick_lun")<1 and self.player:getChangeSkillState("youlong")<2)
		and self:getCardsNum(__hc_value_call(c,"getClassName"))<1
		and self.player:hasEquipArea()
		then
         	local dummy = self:aiUseCard(c)
    		if dummy.card and dummy.to
	     	then
				self:writeCurrentSourceTargets("youlong_to",dummy.to)
	           	if __hc_value_call(c,"canRecast") and dummy.to:length()<1 then continue end
				local source_class=__hc_value_call(c,"getClassName")
				self:copyNamedSourcePriority("YoulongCard",c,source_class)
				self:readNamedSourcePriority("YoulongCard")
                return policy(self,"@YoulongCard=.:"..name)
			end
		end
	end
end

sgs.ai_skill_use_func["YoulongCard"] = function(card,use,self)
	use.card = card
	use.to = self:readCurrentSourceTargets("youlong_to")
end

sgs.ai_use_value.YoulongCard = 10.4
sgs.ai_use_priority.YoulongCard = 10.4

sgs.ai_guhuo_card.youlong = function(self,toname,class_name)
	if self:getCardsNum(class_name)<1 and __hc_value_call(self.player,"getMark","youlong_"..toname)<1 then
        return "@YoulongCard=.:"..toname
	end
end

--鸾凤
sgs.ai_skill_invoke.luanfeng = function(self,data)
	local target = data:toPlayer()
	if __hc_value_call(target,"hasSkill","niepan") and __hc_value_call(target,"getMark","@nirvana")>0 then return false end
	if __hc_value_call(target,"hasSkill","mobileniepan") and __hc_value_call(target,"getMark","@mobileniepanMark")>0 then return false end
	if __hc_value_call(target,"hasSkill","olniepan") and __hc_value_call(target,"getMark","@olniepanMark")>0 then return false end
	return self:isFriend(target)
end

--战意
sgs.ai_fill_skill["secondzhanyi"] = function(self,inclusive,request)
	if not self.player:hasUsed("SecondZhanyiCard") then
		return policy(self,"@SecondZhanyiCard=.")
	end
	if __hc_value_call(self.player,"getMark","ViewAsSkill_secondzhanyiEffect-PlayClear")>0 then
		local use_basic = self:ZhanyiUseBasic()
		local cards = self.player:getCards("h")
		cards=sgs.QList2Table(cards)
		cards = self:sortByUseValue(cards,true)
		local BasicCards = {}
		for _,card in ipairs(cards)do
			if __hc_value_call(card,"isKindOf","BasicCard") then
				table.insert(BasicCards,card)
			end
		end
		if use_basic and #BasicCards>0 then
			return policy(self,"@SecondZhanyiViewAsBasicCard="..BasicCards[1]:getId()..":"..use_basic)
		end
	end
end

sgs.ai_skill_use_func.SecondZhanyiCard = function(card,use,self)
	local to_discard
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards,true)

	local TrickCards = {}
	for _,card in ipairs(cards)do
		if __hc_value_call(card,"isKindOf","Disaster") or __hc_value_call(card,"isKindOf","GodSalvation") or __hc_value_call(card,"isKindOf","AmazingGrace") or self:getCardsNum("TrickCard")>1 then
			table.insert(TrickCards,card)
		end
	end
	if #TrickCards>0 and (__hc_value_call(self.player,"getHp")>2 or self:getCardsNum("Peach")>0 ) and __hc_value_call(self.player,"getHp")>1 then
		to_discard = TrickCards[1]
	end

	local EquipCards = {}
	if self:needToThrowArmor() and self.player:getArmor() then table.insert(EquipCards,self.player:getArmor()) end
	for _,card in ipairs(cards)do
		if __hc_value_call(card,"isKindOf","EquipCard") then
			table.insert(EquipCards,card)
		end
	end
	if not self:isWeak() and self.player:getDefensiveHorse() then table.insert(EquipCards,self.player:getDefensiveHorse()) end
	if self.player:hasTreasure("wooden_ox") and self.player:getPile("wooden_ox"):length()==0 then table.insert(EquipCards,self.player:getTreasure()) end
	self.enemies = self:sort(self.enemies,"defense")
	if self:getCardsNum("Slash")>0 and
	((__hc_value_call(self.player,"getHp")>2 or self:getCardsNum("Peach")>0 ) and __hc_value_call(self.player,"getHp")>1) then
		for _,enemy in ipairs(self.enemies)do
			if (self:isWeak(enemy)) or (enemy:getCardCount(true)<=4 and enemy:getCardCount(true)>=1)
				and self.player:canSlash(enemy) and self:slashIsEffective(clone(self,"slash"),enemy,self.player)
				and __hc_value_call(self.player,"inMyAttackRange",enemy) and not self:needToThrowArmor(enemy) then
				to_discard = EquipCards[1]
				break
			end
		end
	end

	local BasicCards = {}
	for _,card in ipairs(cards)do
		if __hc_value_call(card,"isKindOf","BasicCard") then
			table.insert(BasicCards,card)
		end
	end
	local use_basic = self:ZhanyiUseBasic()
	if (use_basic=="peach" and __hc_value_call(self.player,"getHp")>1 and #BasicCards>3)
	--or (use_basic=="analeptic" and __hc_value_call(self.player,"getHp")>1 and #BasicCards>2)
	or (use_basic=="slash" and __hc_value_call(self.player,"getHp")>1 and #BasicCards>1)
	then
		to_discard = BasicCards[1]
	end

	if to_discard then
		use.card = policy(self,"@SecondZhanyiCard="..__hc_value_call(to_discard,"getEffectiveId"))
		return
	end
end

sgs.ai_use_priority.SecondZhanyiCard = sgs.ai_use_priority.ZhanyiCard

sgs.ai_skill_use_func.SecondZhanyiViewAsBasicCard=function(card,use,self)
	local userstring=card:getLegacyStringKey()
	userstring=(userstring:split(":"))[3]
	local zhanyicard=clone(self,userstring,__hc_value_call(card,"getSuit"),__hc_value_call(card,"getNumber"))
	zhanyicard = mutate(self,zhanyicard,"skill","secondzhanyi")
	if __hc_value_call(zhanyicard,"getTypeId")==sgs.Card_TypeBasic then
		if not use.isDummy and use.card and __hc_value_call(zhanyicard,"isKindOf","Slash") and (not use.to or use.to:isEmpty()) then return end
		self:useBasicCard(zhanyicard,use)
	end
	if not use.card then return end
	use.card=card
end

sgs.ai_use_priority.SecondZhanyiViewAsBasicCard = sgs.ai_use_priority.ZhanyiViewAsBasicCard

--偏宠
sgs.ai_skill_invoke.pianchong = function(self,data)
	return self.player:getPile("yiji"):isEmpty()
end

sgs.ai_skill_choice.pianchong = function(self,choices,data)
	local use_red,use_black,red,black = 0,0,0,0
	for _,c in sgs.qlist(self.player:getCards("h"))do
		if not self:willUse(self.player,c,false,false,true) then continue end
		if c:isRed() then use_red = use_red+1
		elseif c:isBlack() then use_black = use_black+1 end
	end
	if use_red>use_black then return "red"
	elseif use_red<use_black then return "black"
	else
		if red>black then return "red"
		elseif red<black then return "black" end
	end
	choices = choices:split("+")
	return choices[math.random(1,#choices)]
end

--尊位
sgs.ai_fill_skill["zunwei"] = function(self,inclusive,request)
	return policy(self,"@ZunweiCard=.",request)
end

local function zunwei_source_prefix(self,registry,key,value)
 if type(ai_response_choice_continuity)~='function'then ai_unsupported('Zunwei actual source registry unavailable',key)end
 local r=ai_response_choice_continuity{op='source_prefix',registry=registry,key=key,value={kind='scalar',value=value}}
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.known~=true or r.written~=true then ai_unsupported('Zunwei actual source prefix is not admitted',key)end
end
sgs.ai_skill_use_func.ZunweiCard = function(card,use,self)
	local recover_t,draw_t,equip_t = {},{},{}
	if not property(self,"zunwei_draw") and self:canDraw() then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if __hc_value_call(p,"getHandcardNum")>__hc_value_call(self.player,"getHandcardNum") then
				table.insert(draw_t,p)
			end
		end
	end
	if not property(self,"zunwei_recover") and __hc_value_call(self.player,"getLostHp")>0 then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if __hc_value_call(p,"getHp")>__hc_value_call(self.player,"getHp") then
				table.insert(recover_t,p)
			end
		end
	end
	if not property(self,"zunwei_equip") and self.player:hasEquipArea() then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if p:getEquips():length()>self.player:getEquips():length() then
				table.insert(equip_t,p)
			end
		end
	end
	if #recover_t==0 and #draw_t==0 and #equip_t==0 then return end

	if #recover_t>0 then recover_t = known(self:sort(recover_t,"hp"),"Zunwei sorted targets") recover_t = sgs.reverse(recover_t) end
	if #draw_t>0 then draw_t = known(self:sort(draw_t,"handcard"),"Zunwei sorted targets") draw_t = sgs.reverse(draw_t) end
	if #equip_t>0 then equip_t = known(self:sort(equip_t,"equip"),"Zunwei sorted targets") equip_t = sgs.reverse(equip_t) end

	if self:isWeak() then
		if #recover_t>0 then
			zunwei_source_prefix(self,"ai_use_priority","ZunweiCard",10)
			zunwei_source_prefix(self,"ai_skill_choice","zunwei","recover")
			use.card = card
			use.to:append(recover_t[1])
			return
		end

		if #draw_t>0 then
			zunwei_source_prefix(self,"ai_skill_choice","zunwei","draw")
			use.card = card
			use.to:append(draw_t[1])
			return
		end

		if #equip_t>0 then
			zunwei_source_prefix(self,"ai_skill_choice","zunwei","equip")
			use.card = card
			use.to:append(equip_t[1])
			return
		end
	end

	if #recover_t>0 and __hc_value_call(recover_t[1],"getHp")-__hc_value_call(self.player,"getHp")>=2 and __hc_value_call(self.player,"getLostHp")>=2 then
		zunwei_source_prefix(self,"ai_skill_choice","zunwei","recover")
		use.card = card
		use.to:append(recover_t[1])
		return
	end

	if #draw_t>0 and ((__hc_value_call(draw_t[1],"getHandcardNum")-__hc_value_call(self.player,"getHandcardNum")>=2 and sgs.Slash_IsAvailable(self.player)) or
	__hc_value_call(draw_t[1],"getHandcardNum")-__hc_value_call(self.player,"getHandcardNum")>=4) then
		zunwei_source_prefix(self,"ai_skill_choice","zunwei","draw")
		use.card = card
		use.to:append(draw_t[1])
		return
	end

	if #equip_t>0 and equip_t[1]:getEquips():length()-self.player:getEquips():length()>=2 then
		zunwei_source_prefix(self,"ai_skill_choice","zunwei","equip")
		use.card = card
		use.to:append(equip_t[1])
		return
	end
end

sgs.ai_use_priority.ZunweiCard = 0

--讨灭
sgs.ai_skill_invoke.taomie = function(self,data)
	local player = data:toPlayer()
	return not self:isFriend(player)
end

sgs.ai_skill_choice.taomie = function(self,choices,data)
	local damage = data:toDamage()
	local to = damage.to
	choices = choices:split("+")

	local damage = getChoice(choices,"damage")
	local get = getChoice(choices,"get")
	local all = getChoice(choices,"all")

	if #choices==2 then
		table.removeOne(choices,all)
		return choices[1]
	end
	if #choices==3 then
		if self:cantDamageMore(self.player,to) then
			if self:doDisCard(to) then return get end
			return damage
		end
		if self:doDisCard(to) then return get end
		return all
	end
	return choices[1]
end

sgs.ai_skill_askforyiji.taomie = function(self,card_ids,tos)
	return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
end

--粮营
sgs.ai_skill_invoke.liangying = function(self,data)
	for _,p in ipairs(self.friends)do
		if self:canDraw(p) then return true end
	end
	return false
end

sgs.ai_skill_choice.liangying = function(self,choices,data)
	choices = choices:split("+")
	local n = tonumber(choices[#choices])
	n = math.min(n,#self.friends)
	for _,p in ipairs(self.friends)do
		if not self:canDraw(p) then n = n-1 end
	end
	if n>0 then
		return ""..n
	else
		return choices[1]
	end
end

sgs.ai_skill_askforyiji.liangying = function(self,card_ids)
	local friends = {}
	for _,p in ipairs(self.friends)do
		if __hc_value_call(p,"getMark","liangying-Clear")<=0
		then
			table.insert(friends,p)
		end
	end
	local toGive,allcards = {},{}
	local keep
	for _,id in ipairs(card_ids)do
		local card = visible(self,id)
		if not keep and (isCard("Jink",card,self.player) or isCard("Analeptic",card,self.player))
		then keep = true else table.insert(toGive,card) end
		table.insert(allcards,card)
	end
	local cards = #toGive>0 and toGive or allcards
	cards = self:sortByKeepValue(cards,true)
	local id = cards[1]:getId()
	local card,friend = self:getCardNeedPlayer(cards,true,friends)
	if card and friend and table.contains(friends,friend) then return friend,card:getId() end
	if #friends>0
	then
		friends = self:sort(friends,"handcard")
		for _,afriend in ipairs(friends)do
			if not self:needKongcheng(afriend,true)
			then return afriend,id end
		end
		friends = self:sort(friends,"defense")
		return friends[1],id
	end
	return nil,-1
end

--把盏
sgs.ai_fill_skill["bazhan"] = function(self,inclusive,request)
	return policy(self,"@BazhanCard=.")
end

sgs.ai_skill_use_func.BazhanCard = function(card,use,self)
	local n = self.player:getChangeSkillState("bazhan")
	if n~=1 and n~=2 then return end
	if n==1 then
		if self.player:isKongcheng() then return end
		local cards = sgs.QList2Table(self.player:getCards("h"))
		cards = self:sortByUseValue(cards,true)
		local hearts = {}
		for _,c in ipairs(cards)do
			if __hc_value_call(c,"isKindOf","Analeptic") or __hc_value_call(c,"getSuit")==sgs.Card_Heart then
				table.insert(hearts,c)
			end
		end
		if #hearts>0 then
			self.friends_noself = self:sort(self.friends_noself,"hp")
			for _,p in ipairs(self.friends_noself)do
				if self:isWeak(p) and __hc_value_call(p,"getLostHp")>0 and not (p:isKongcheng() and self:needKongcheng(p,true)) then
					self:setPriorityValue("BazhanCard",7,"tenyear_hc")
					use.card = policy(self,"@BazhanCard="..__hc_value_call(hearts[1],"getEffectiveId"))
					use.to:append(p)
					return
				end
			end

			self.friends_noself = self:sort(self.friends_noself)
			for _,p in ipairs(self.friends_noself)do
				if not __hc_value_call(p,"faceUp") and not (p:isKongcheng() and self:needKongcheng(p,true)) then
					self:setPriorityValue("BazhanCard",7,"tenyear_hc")
					use.card = policy(self,"@BazhanCard="..__hc_value_call(hearts[1],"getEffectiveId"))
					use.to:append(p)
					return
				end
			end

			local card,friend = self:getCardNeedPlayer({hearts[1]},false)
			if card and friend then
				self:setPriorityValue("BazhanCard",7,"tenyear_hc")
				use.card = policy(self,"@BazhanCard="..__hc_value_call(card,"getEffectiveId"))
				use.to:append(friend)
				return
			end
		end

		if self:getOverflow()>0 then
			if not __hc_value_call(cards[1],"isKindOf","Jink") and not __hc_value_call(cards[1],"isKindOf","Peach") and not __hc_value_call(cards[1],"isKindOf","Analeptic") and not __hc_value_call(cards[1],"isKindOf","ExNihilo") then
				self.enemies = self:sort(self.enemies)
				for _,p in ipairs(self.enemies)do
					if p:isKongcheng() and self:needKongcheng(p,true) then
						use.card = policy(self,"@BazhanCard="..__hc_value_call(cards[1],"getEffectiveId"))
						use.to:append(p)
						return
					end
				end
			end

			local card,friend = self:getCardNeedPlayer({cards[1]},false)
			if card and friend then
				use.card = policy(self,"@BazhanCard="..__hc_value_call(card,"getEffectiveId"))
				use.to:append(friend)
				return
			end

			self.friends_noself = self:sort(self.friends_noself,"handcard")
			for _,p in ipairs(self.friends_noself)do
				if not (p:isKongcheng() and self:needKongcheng(p,true)) and not self:willSkipPlayPhase(p) then
					use.card = policy(self,"@BazhanCard="..__hc_value_call(cards[1],"getEffectiveId"))
					use.to:append(p)
					return
				end
			end

			for _,p in ipairs(self.friends_noself)do
				if not (p:isKongcheng() and self:needKongcheng(p,true)) then
					use.card = policy(self,"@BazhanCard="..__hc_value_call(cards[1],"getEffectiveId"))
					use.to:append(p)
					return
				end
			end
		end
	else
		if self.player:isKongcheng() and self:needKongcheng(self.player,true) then return end
		self.friends_noself = self:sort(self.friends_noself)
		self.friends_noself = sgs.reverse(self.friends_noself)
		for _,p in ipairs(self.friends_noself)do
			if self:needToThrowLastHandcard(p) then
				use.card = policy(self,"@BazhanCard=.")
				use.to:append(p)
				return
			end
		end

		self.friends_noself = self:sort(self.friends_noself,"handcard")
		self.friends_noself = sgs.reverse(self.friends_noself)
		for _,p in ipairs(self.friends_noself)do
			if self:doDisCard(p,"h",true) and not self:isWeak(p) then
				use.card = policy(self,"@BazhanCard=.")
				use.to:append(p)
				return
			end
		end

		self.enemies = self:sort(self.enemies)
		for _,p in ipairs(self.enemies)do
			if self:doDisCard(p,"h",true) then
				self:setPriorityValue("BazhanCard",sgs.ai_use_priority.Snatch,"tenyear_hc")
				use.card = policy(self,"@BazhanCard=.")
				use.to:append(p)
				return
			end
		end

		for _,p in ipairs(self.friends_noself)do
			if self:getOverflow(p)>1 and (not self:isWeak(p) or self:willSkipPlayPhase(p)) then
				use.card = policy(self,"@BazhanCard=.")
				use.to:append(p)
				return
			end
		end
	end
end

sgs.ai_use_priority.BazhanCard = 0

sgs.ai_skill_choice.bazhan = function(self,choices,data)
	local to = data:toPlayer()
	if not self:isFriend(to) then return "cancel" end
	choices = choices:split("+")

	local recover = getChoice(choices,"recover")
	local reset = getChoice(choices,"reset")

	if recover then
		if self:isWeak(to) then return recover end
		if not __hc_value_call(to,"faceUp") then return reset end
		if to:isChained() and self:getFinalRetrial(to)==2 then
			if self:hasSkills("leiji|nosleiji|olleiji|",self.enemies) then return reset end
			for _,p in sgs.qlist(self.room:getAlivePlayers())do
				if not p:containsTrick("YanxiaoCard") and p:containsTrick("lightning") then
					return reset
				end
			end
		end
		return recover
	end
	return reset
end

--醮影
sgs.ai_skill_playerchosen.jiaoying = function(self,targets)
	local player = sgs.ai_skill_playerchosen.jieming(self,targets)
	if player then return player end
	return self.player
end

--殃众
sgs.ai_skill_cardask["@yangzhong"] = function(self,data,pattern,target)
	if not target or __hc_value_call(target,"isDead") or self:isFriend(target) then return "." end
	local dis = {}
	if __hc_value_call(target,"getHp")<=1 and not hasBuquEffect(target) then
		dis = self:askForDiscard("dummyreason",2,2,false,true)
		if #dis>=2 then
			return "$"..table.concat(dis,"+")
		else
			return "."
		end
	end
	if hasZhaxiangEffect(target) and not self:willSkipPlayPhase(target) then return "." end
	dis = self:askForDiscard("dummyreason",2,2,false,true)
	if #dis==2 then
		for _,id in ipairs(dis)do
			if visible(self,id):isKindOf("Peach") then return "." end
			if visible(self,id):isKindOf("Analeptic") and self:isWeak() then return "." end
		end
		return "$"..table.concat(dis,"+")
	end
	return "."
end

--礼赂
sgs.ai_skill_invoke.lilu = function(self,data)
	local invoke = false
	for _,p in ipairs(self.friends_noself)do
		if p:isKongcheng() and self:needKongcheng(p,true) then continue end
		invoke = true
		break
	end
	if not invoke then return false end
	local draw = math.min(__hc_value_call(self.player,"getMaxHp"),5)-__hc_value_call(self.player,"getHandcardNum")
	local mark = __hc_value_call(self.player,"getMark","&lilu")
	if draw<=2 then
		if self:getOverflow()+math.max(draw,0)>=mark+1 and ((self.player:isSkipped(sgs.Player_Play) and self:getOverflow()+math.max(draw,0)>0) or
		self:getOverflow()-mark>=1 or mark<=1) then
			return true
		else
			return false
		end
	end

	return true
end

sgs.ai_skill_use["@@lilu!"] = function(self,prompt)
	local mark = __hc_value_call(self.player,"getMark","&lilu")
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByUseValue(cards,true)
	self.friends_noself = self:sort(self.friends_noself)

	local target
	for _,p in ipairs(self.friends_noself)do
		if self:canDraw(p) and not self:willSkipPlayPhase(p) then
			target = p
			break
		end
	end
	if not target then
		for _,p in ipairs(self.friends_noself)do
			if not (p:isKongcheng() and self:needKongcheng(p,true)) and not self:willSkipPlayPhase(p) then
				target = p
				break
			end
		end
	end
	if not target then
		for _,p in ipairs(self.friends_noself)do
			if self:canDraw(p) then
				target = p
				break
			end
		end
	end
	if not target then
		for _,p in ipairs(self.friends_noself)do
			if not (p:isKongcheng() and self:needKongcheng(p,true)) then
				target = p
				break
			end
		end
	end
	if not target then target = self.friends_noself[1] end

	local give,hand_num = {},__hc_value_call(self.player,"getHandcardNum")
	if hand_num<mark+1 and target then
		if self:needToThrowLastHandcard(self.player,hand_num) then
			for _,c in ipairs(cards)do
				table.insert(give,__hc_value_call(c,"getEffectiveId"))
			end
			return "@LiluCard="..table.concat(give,"+").."->"..target:objectName()
		end
		local card,friend = self:getCardNeedPlayer(cards,false)
		if card and friend then
			return "@LiluCard="..__hc_value_call(card,"getEffectiveId").."->"..friend:objectName()
		end
		return "@LiluCard="..__hc_value_call(cards[1],"getEffectiveId").."->"..target:objectName()
	end

	for i = 1,mark+1 do
		if #cards<i then break end
		table.insert(give,cards[i]:getEffectiveId())
	end
	if #give>0 and target then
		return "@LiluCard="..table.concat(give,"+").."->"..target:objectName()
	end
	return "."
end

--翊正
sgs.ai_skill_playerchosen.yizhengc = function(self,targets)
	if __hc_value_call(self.player,"getMaxHp")<=3 or #self.friends_noself<=0 then return nil end
	local friends = {}
	for _,p in ipairs(self.friends_noself)do
		if __hc_value_call(p,"getMaxHp")<__hc_value_call(self.player,"getMaxHp") and __hc_value_call(p,"getMark","&yizhengc+#"..self.player:objectName())<=0 and not self:willSkipPlayPhase(p) then
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		friends = self:sort(friends,"threat")
		return friends[1]
	end

	for _,p in ipairs(self.friends_noself)do
		if __hc_value_call(p,"getMaxHp")<__hc_value_call(self.player,"getMaxHp") and not self:willSkipPlayPhase(p) then
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		friends = self:sort(friends,"threat")
		return friends[1]
	end

	for _,p in ipairs(self.friends_noself)do
		if __hc_value_call(p,"getMaxHp")<__hc_value_call(self.player,"getMaxHp") and __hc_value_call(p,"getMark","&yizhengc+#"..self.player:objectName())<=0 then
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		friends = self:sort(friends,"threat")
		return friends[1]
	end

	for _,p in ipairs(self.friends_noself)do
		if __hc_value_call(p,"getMaxHp")<__hc_value_call(self.player,"getMaxHp") then
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		friends = self:sort(friends,"threat")
		return friends[1]
	end

	self.friends_noself = self:sort(self.friends_noself,"threat")
	return self.friends_noself[1]
end

--十周年揖让
sgs.ai_skill_playerchosen.tenyearyirang = function(self,targets)
	return sgs.ai_skill_playerchosen.yirang(self,targets)
end

--凤魄
sgs.ai_skill_choice.newfengpo = function(self,choices,data)
	return sgs.ai_skill_choice.fengpo(self,choices,data)
end

--天匠
sgs.ai_fill_skill["tianjiang"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("e"))
	cards = self:sortByKeepValue(cards)
  	for _,e in sgs.list(cards)do
		local equip = e
		local x = equip:location()
		for _,h in sgs.list(self.player:getCards("h"))do
			if __hc_value_call(h,"isKindOf","EquipCard") then
				local eq = h
				local n = eq:location()
				if x==n then
					n = self.friends_noself
					if self:evaluateArmor(e)<-5
					then n = self.enemies end
					for _,ep in sgs.list(n)do
						if ep:hasEquipArea(x) then
							self:writeCurrentSourceTarget("tj_to",ep)
							if self:isFriend(ep) then
								if ep:getEquip(x)==nil
								then return policy(self,"@TianjiangCard="..__hc_value_call(e,"getEffectiveId")) end
							else
								if ep:getEquip(x)~=nil
								then return policy(self,"@TianjiangCard="..__hc_value_call(e,"getEffectiveId")) end
							end
						end
					end
				end
			end
		end
	end
  	for _,e in sgs.list(cards)do
		local equip = e
		local x = equip:location()
		for _,h in sgs.list(self.player:getCards("h"))do
			if __hc_value_call(h,"isKindOf","EquipCard") then
				local eq = h
				local n = eq:location()
				if x==n then
					n = self.friends_noself
					if self:evaluateArmor(e)<-5
					then n = self.enemies end
					for _,ep in sgs.list(n)do
						if ep:hasEquipArea(x) then
							self:writeCurrentSourceTarget("tj_to",ep)
							if self:isFriend(ep) then
								if ep:getEquip(x)==nil
								then return policy(self,"@TianjiangCard="..__hc_value_call(e,"getEffectiveId")) end
							else return policy(self,"@TianjiangCard="..__hc_value_call(e,"getEffectiveId")) end
						end
					end
				end
			end
		end
	end
  	for _,e in sgs.list(cards)do
		local equip = e
		local x = equip:location()
		local n = self.friends_noself
		if self:evaluateArmor(e)<-5
		then n = self.enemies end
		for _,ep in sgs.list(n)do
			if ep:hasEquipArea(x) then
				self:writeCurrentSourceTarget("tj_to",ep)
				if self:isFriend(ep) then
					if ep:getEquip(x)==nil and self:isWeak(ep)
					then return policy(self,"@TianjiangCard="..__hc_value_call(e,"getEffectiveId")) end
				else return policy(self,"@TianjiangCard="..__hc_value_call(e,"getEffectiveId")) end
			end
		end
	end
  	for _,e in sgs.list(cards)do
		local equip = e
		local x = equip:location()
		for _,ep in sgs.list(self.friends_noself)do
			if ep:hasEquipArea(x) then
				self:writeCurrentSourceTarget("tj_to",ep)
				equip = e:objectName()
				if equip=="_hongduanqiang"
				or equip=="_liecuidao"
				or equip=="_shuibojian"
				or equip=="_hunduwanbi"
				or equip=="_tianleiren"
				then return policy(self,"@TianjiangCard="..__hc_value_call(e,"getEffectiveId")) end
			end
		end
	end
end

sgs.ai_skill_use_func["TianjiangCard"] = function(card,use,self)
	use.card = card
	use.to:append(self:readCurrentSourceTarget("tj_to"))
end

sgs.ai_use_value.TianjiangCard = 9.4
sgs.ai_use_priority.TianjiangCard = 4.8


--铸刃
sgs.ai_fill_skill["zhuren"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if __hc_value_call(c,"getNumber")>6 and self.player:getWeapon()==nil
		then return policy(self,"@ZhurenCard="..__hc_value_call(c,"getEffectiveId")) end
	end
  	for _,c in sgs.list(cards)do
		if __hc_value_call(c,"getNumber")<6
		and self:getCardsNum("Slash")<1
		and sgs.Slash_IsAvailable(self.player)
		then return policy(self,"@ZhurenCard="..__hc_value_call(c,"getEffectiveId")) end
	end
end

sgs.ai_skill_use_func["ZhurenCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ZhurenCard = 9.4
sgs.ai_use_priority.ZhurenCard = 4.8

--短兵
sgs.ai_skill_playerchosen.olduanbing = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

--奋迅
sgs.ai_fill_skill["olfenxun"]=function(self,inclusive,request)
	return policy(self,"@OLFenxunCard=.")
end

sgs.ai_skill_use_func["OLFenxunCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard")
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(self.player,"distanceTo",ep)>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.OLFenxunCard = 3.4
sgs.ai_use_priority.OLFenxunCard = 8.8

--筹略
sgs.ai_skill_playerchosen.choulve = function(self,players)
	local name = property(self,"choulve_damage_card")
	name = clone(self,name)
	if not name then return end
	name = mutate(self,name,"skill","_choulve")
	name = self:aiUseCard(name)
	if name.card==nil then return end
	self:writeCurrentSourceTargets("cl_to",name.to)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:getCardCount()>0
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and target:getCardCount()>0
		then return target end
	end
end

sgs.ai_skill_discard.choulve = function(self)
	local ids = {}
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
   	local target = self.room:getCurrent()
	if self:isFriend(target)
	and #cards>0
	then
		table.insert(ids,__hc_value_call(cards[1],"getEffectiveId"))
	end
	return ids
end

sgs.ai_skill_use["@@choulve!"] = function(self,prompt)
    local c = property(self,"choulve_damage_card")
	c = clone(self,c)
	c = mutate(self,c,"skill","_choulve")
   	if self:currentSourceTargetsPresent("cl_to") then
      	local tos = {}
       	for _,p in sgs.list(self:readCurrentSourceTargets("cl_to"))do
       		table.insert(tos,p:objectName())
       	end
		self:clearCurrentSourceTargets("cl_to")
       	return c:getLegacyStringKey().."->"..table.concat(tos,"+")
    end
end

--威仪
sgs.ai_skill_invoke.weiyi = function(self,data)
	local p = data:toPlayer()
	return self:isFriend(p) and __hc_value_call(p,"getHp")<=__hc_value_call(self.player,"getHp") and self:isWeak(p)
	or self:isEnemy(p) and __hc_value_call(p,"getHp")>=__hc_value_call(self.player,"getHp")
end

sgs.ai_skill_choice.weiyi = function(self,choices,data)
	local player = data:toPlayer()
	if not player or __hc_value_call(player,"isDead") then return "cancel" end
	choices = choices:split("+")
	local recover = getChoice(choices,"recover")
	local losehp = getChoice(choices,"losehp")
	if self:isFriend(player) and recover then return recover end
	if self:isEnemy(player) and losehp then return losehp end  --不管诈降了
	return "cancel"
end

--锦织

sgs.ai_fill_skill["jinzhi"]=function(self,inclusive,request)
	return policy(self,"@JinzhiCard=.")
end

sgs.ai_skill_use_func["JinzhiCard"] = function(card,use,self)
	local toids = {}
	local mark = __hc_value_call(self.player,"getMark","&jinzhi_lun")
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
	if #cards<=mark then return end
    cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if h:getColor()~=cards[1]:getColor() then continue end
		table.insert(toids,__hc_value_call(h,"getEffectiveId"))
		if #toids>mark then break end
	end
	if #toids<=mark or #toids>=#cards/2 then return end
	for _,name in sgs.list(source_patterns(self))do
        local c = clone(self,name)
		if c and __hc_value_call(c,"isKindOf","BasicCard")
		and __hc_value_call(c,"isAvailable",self.player)
		and self:getCardsNum(__hc_value_call(c,"getClassName"))<1
		then
         	for _,id in sgs.list(toids)do
				c = mutate(self,c,"add",id)
			end
			c = mutate(self,c,"suit",6)
			c = mutate(self,c,"number",0)
			local dummy = self:aiUseCard(c)
    		if dummy.card and dummy.to
	     	then
				toids = #toids>0 and table.concat(toids,"+") or "."
	           	if __hc_value_call(c,"canRecast") and dummy.to:length()<1 then continue end
				self:setPriorityValue("JinzhiCard",sgs.ai_use_priority[__hc_value_call(c,"getClassName")],"tenyear_hc")
				use.card = policy(self,"@JinzhiCard="..toids..":"..name)
				use.to = dummy.to
				break
			end
		end
	end
end

sgs.ai_use_value.JinzhiCard = 10.4
sgs.ai_use_priority.JinzhiCard = 10.4

sgs.ai_guhuo_card.jinzhi = function(self,toname,class_name)
	local toids = {}
	local mark = __hc_value_call(self.player,"getMark","&jinzhi_lun")
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
	if #cards<=mark then return end
    cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if h:getColor()~=cards[1]:getColor() then continue end
		table.insert(toids,__hc_value_call(h,"getEffectiveId"))
		if #toids>mark then break end
	end
	if self:getCardsNum(class_name)<1
	and #toids>mark and #toids<3
	then
		toids = #toids>0 and table.concat(toids,"+") or "."
        return "@JinzhiCard="..toids..":"..toname
	end
end

--二版锦织
sgs.ai_fill_skill["secondjinzhi"]=function(self,inclusive,request)
	local toids = {}
	local mark = __hc_value_call(self.player,"getMark","&secondjinzhi_lun")
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	if #cards<1 then return end
	for _,h in sgs.list(cards)do
		if h:getColor()~=cards[1]:getColor() then continue end
		table.insert(toids,__hc_value_call(h,"getEffectiveId"))
		if #toids>mark then break end
	end
	if #toids<=mark then return end
	for _,name in sgs.list(source_patterns(self))do
        local c = clone(self,name)
		if c and __hc_value_call(c,"isKindOf","BasicCard")
		and __hc_value_call(c,"isAvailable",self.player)
		and self:getCardsNum(__hc_value_call(c,"getClassName"))<1
		then
         	for _,id in sgs.list(toids)do
				c = mutate(self,c,"add",id)
			end
			c = mutate(self,c,"suit",6)
			c = mutate(self,c,"number",0)
         	local dummy = self:aiUseCard(c)
    		if dummy.card and dummy.to
	     	then
				self:writeCurrentSourceTargets("secondjinzhi_to",dummy.to)
				toids = #toids>0 and table.concat(toids,"+") or "."
	           	if __hc_value_call(c,"canRecast") and dummy.to:length()<1 then continue end
				local source_class=__hc_value_call(c,"getClassName")
				self:copyNamedSourcePriority("SecondJinzhiCard",c,source_class)
				self:readNamedSourcePriority("SecondJinzhiCard")
                return policy(self,"@SecondJinzhiCard="..toids..":"..name)
			end
		end
	end
end

sgs.ai_skill_use_func["SecondJinzhiCard"] = function(card,use,self)
	use.card = card
	use.to = self:readCurrentSourceTargets("secondjinzhi_to")
end

sgs.ai_use_value.SecondJinzhiCard = 10.4
sgs.ai_use_priority.SecondJinzhiCard = 10.4

sgs.ai_guhuo_card.secondjinzhi = function(self,toname,class_name)
	local toids = {}
	local mark = __hc_value_call(self.player,"getMark","&secondjinzhi_lun")
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
	if #cards<1 then return end
    cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if h:getColor()~=cards[1]:getColor() then continue end
		table.insert(toids,__hc_value_call(h,"getEffectiveId"))
		if #toids>mark then break end
	end
	if #toids>mark
	and self:getCardsNum(class_name)<1
	then
		toids = #toids>0 and table.concat(toids,"+") or "."
        return "@SecondJinzhiCard="..toids..":"..toname
	end
end


--兴作
sgs.ai_skill_invoke.xingzuo = function(self,data)
    return __hc_value_call(self.player,"getHandcardNum")>1
end

sgs.ai_skill_use["@@xingzuo"] = function(self,prompt)
	local valid = {}
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	local cidlist = tag(self,"xingzuoForAI","IntList")
	for _,h in sgs.list(cards)do
		for _,id in sgs.list(cidlist)do
			local c = visible(self,id)
			if self:getKeepValue(c)>self:getKeepValue(h)
			and not table.contains(valid,__hc_value_call(h,"getEffectiveId"))
			and not table.contains(valid,__hc_value_call(c,"getEffectiveId"))
			then
				table.insert(valid,__hc_value_call(h,"getEffectiveId"))
				table.insert(valid,__hc_value_call(c,"getEffectiveId"))
				break
			end
		end
	end
	return #valid>1 and ("@XingzuoCard="..table.concat(valid,"+"))
end

sgs.ai_skill_playerchosen.xingzuo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and __hc_value_call(target,"getHandcardNum")<3
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and __hc_value_call(target,"getHandcardNum")>0
		then return target end
	end
    return destlist[1]
end

--妙弦
sgs.ai_fill_skill["miaoxian"]=function(self,inclusive,request)
	local toids = {}
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	if #cards<1 then return end
	for _,h in sgs.list(cards)do
		if h:isBlack() then table.insert(toids,__hc_value_call(h,"getEffectiveId")) end
	end
	for _,name in sgs.list(source_patterns(self))do
        if #toids~=1 then continue end
		local c = clone(self,name)
		if c and c:isNDTrick()
		and __hc_value_call(c,"isAvailable",self.player)
		and self:getCardsNum(__hc_value_call(c,"getClassName"))<1
		then
         	local dummy = self:aiUseCard(c)
    		if dummy.card and dummy.to
	     	then
				self:writeCurrentSourceTargets("mx_to",dummy.to)
				toids = #toids>0 and table.concat(toids,"+") or "."
	           	if __hc_value_call(c,"canRecast") and dummy.to:length()<1 then continue end
				self:setPriorityValue("MiaoxianCard",sgs.ai_use_priority[__hc_value_call(c,"getClassName")],"tenyear_hc")
                return policy(self,"@MiaoxianCard="..toids..":"..name)
			end
		end
	end
end

sgs.ai_skill_use_func["MiaoxianCard"] = function(card,use,self)
	use.card = card
	use.to = self:readCurrentSourceTargets("mx_to")
end

sgs.ai_use_value.MiaoxianCard = 10.4
sgs.ai_use_priority.MiaoxianCard = 10.4

sgs.ai_guhuo_card.miaoxian = function(self,toname,class_name)
	local toids = {}
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	if #cards<1 then return end
	for _,h in sgs.list(cards)do
		if h:isBlack() then table.insert(toids,__hc_value_call(h,"getEffectiveId")) end
	end
	if __hc_value_call(self.player,"getMark","miaoxian-Clear")<1
	and #toids==1 and self:getCardsNum(class_name)<1
	then
		toids = #toids>0 and table.concat(toids,"+") or "."
        return "@MiaoxianCard="..toids..":"..toname
	end
end

--谋逆
sgs.ai_skill_playerchosen.mouni = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:getCardsNum("Slash")>=__hc_value_call(target,"getHp")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:getCardsNum("Slash")>0
		and self:isWeak(target)
		then return target end
	end
end


--纵反

sgs.ai_skill_playerchosen.fuzhong = function(self,players)
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






--美人计
function SmartAIView:useCardMeirenji(card,use)
	self.enemies = self:sort(self.enemies,"hp")
	local extraTarget = extra_targets(self,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.enemies)do
		if isCurrent(use,ep) then continue end
		if can_to(self,card,self.player,ep)
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end
sgs.ai_use_priority.Meirenji = 6.5
sgs.ai_keep_value.Meirenji = 2
sgs.ai_use_value.Meirenji = 3.7

--笑里藏刀
function SmartAIView:useCardXiaolicangdao(card,use)
	self.enemies = self:sort(self.enemies,"hp",true)
	local extraTarget = extra_targets(self,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.enemies)do
		if isCurrent(use,ep) then continue end
		if can_to(self,card,self.player,ep)
		and self:isGoodTarget(ep,self.enemies,card)
		and __hc_value_call(ep,"getHp")<2
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if isCurrent(use,ep) then continue end
		if can_to(self,card,self.player,ep)
		and self:isGoodTarget(ep,self.enemies,card)
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		if isCurrent(use,ep) then continue end
		if can_to(self,card,self.player,ep)
		and self:ajustDamage(self.player,ep,1,card)~=0
		and __hc_value_call(ep,"getHp")>1 and __hc_value_call(ep,"getLostHp")>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end
sgs.ai_use_priority.Xiaolicangdao = 5.5
sgs.ai_keep_value.Xiaolicangdao = 1
sgs.ai_use_value.Xiaolicangdao = 3.7

--连计

--矜功
sgs.ai_fill_skill["jingong"]=function(self,inclusive,request)
	local toids = {}
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards)
	if #cards<1 then return end
	for _,h in sgs.list(cards)do
		if __hc_value_call(h,"isKindOf","Slash")
		or __hc_value_call(h,"isKindOf","EquipCard")
		then table.insert(toids,__hc_value_call(h,"getEffectiveId")) end
	end
	local tricks = property(self,"jingong_tricks"):split("+")
	for _,name in sgs.list(tricks)do
        local c = clone(self,name)
		if c and __hc_value_call(c,"isAvailable",self.player)
		and self:getCardsNum(__hc_value_call(c,"getClassName"))<1
		and #toids>0
		then
         	c = mutate(self,c,"add",toids[1])
			c = mutate(self,c,"skill","jingong")
			local dummy = self:aiUseCard(c)
    		if dummy.card
	    	and dummy.to
	     	then
	           	if __hc_value_call(c,"canRecast")
				and dummy.to:length()<1
				then continue end
                return c
			end
		end
	end
end

sgs.ai_fill_skill["tenyearjingong"]=function(self,inclusive,request)
	local toids = {}
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards)
	if #cards<1 then return end
	for _,h in sgs.list(cards)do
		if __hc_value_call(h,"isKindOf","Slash")
		or __hc_value_call(h,"isKindOf","EquipCard")
		then table.insert(toids,__hc_value_call(h,"getEffectiveId")) end
	end
	local tricks = property(self,"tenyearjingong_tricks"):split("+")
	for _,name in sgs.list(tricks)do
        local c = clone(self,name)
		if c and __hc_value_call(c,"isAvailable",self.player)
		and self:getCardsNum(__hc_value_call(c,"getClassName"))<1
		and #toids>0
		then
         	c = mutate(self,c,"add",toids[1])
			c = mutate(self,c,"skill","tenyearjingong")
			local dummy = self:aiUseCard(c)
    		if dummy.card
	    	and dummy.to
	     	then
	           	if __hc_value_call(c,"canRecast")
				and dummy.to:length()<1
				then continue end
                return c
			end
		end
	end
end

--十周年连计
sgs.ai_fill_skill["tenyearlianji"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
  	if #cards<2 then return end
	return policy(self,"@TenyearLianjiCard="..__hc_value_call(cards[1],"getEffectiveId"))
end

sgs.ai_skill_use_func["TenyearLianjiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp",true)
	for _,ep in sgs.list(self.enemies)do
		use.card = card
		use.to:append(ep)
		return
	end
	for _,ep in sgs.list(self.friends_noself)do
		if __hc_value_call(ep,"getHandcardNum")>2
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.TenyearLianjiCard = 9.4
sgs.ai_use_priority.TenyearLianjiCard = 3.8

--OL连计
sgs.ai_fill_skill["ollianji"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
  	if #cards<2 then return end
	return policy(self,"@OLLianjiCard="..__hc_value_call(cards[1],"getEffectiveId"))
end

sgs.ai_skill_use_func["OLLianjiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp",true)
	for _,ep in sgs.list(self.enemies)do
		use.card = card
		use.to:append(ep)
		return
	end
	for _,ep in sgs.list(self.friends_noself)do
		if __hc_value_call(ep,"getHandcardNum")>2
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.OLLianjiCard = 9.4
sgs.ai_use_priority.OLLianjiCard = 3.8

sgs.ai_skill_playerchosen.ollianji = function(self,players)
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

sgs.ai_skill_playerchosen.ollianji_give = function(self,players)
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
	return destlist[1]
end

--手杀连计
sgs.ai_fill_skill["mobilelianji"]=function(self,inclusive,request)
	return policy(self,"@MobileLianjiCard=.")
end

sgs.ai_skill_use_func["MobileLianjiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp",true)
	for _,fp in sgs.list(self.friends_noself)do
		if __hc_value_call(fp,"getHandcardNum")>0
		then
			for _,ep in sgs.list(self.enemies)do
				use.card = card
				use.to:append(fp)
				use.to:append(ep)
				return
			end
		end
	end
end

sgs.ai_use_value.MobileLianjiCard = 9.4
sgs.ai_use_priority.MobileLianjiCard = 3.8

--屯储
sgs.ai_skill_invoke.newtunchu = function(self,data)
    return self:getCardsNum("Slash")<1 or #self.friends_noself>0
end

sgs.ai_skill_discard.newtunchu = function(self)
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    handcards = self:sortByKeepValue(handcards)
   	for _,h in sgs.list(handcards)do
		if #cards>2 or #cards>#handcards/2 then break end
		table.insert(cards,__hc_value_call(h,"getEffectiveId"))
	end
	return cards
end

--输粮
sgs.ai_skill_use["@@newshuliang"] = function(self,prompt)
    local ids = self.player:getPile("food")
   	local target = self.room:getCurrent()
	if ids:length()>0
	and self:isFriend(target)
	then
		return string.format("@NewShuliangCard=%s",ids:at(0))
	end
end

--观虚
sgs.ai_fill_skill["guanxu"]=function(self,inclusive,request)
	return policy(self,"@GuanxuCard=.")
end

sgs.ai_skill_use_func["GuanxuCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard",true)
	self:writeCurrentSourceSlot("guanxu_friends",false)
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHandcardNum")>2
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		if __hc_value_call(ep,"getHandcardNum")<4
		and __hc_value_call(ep,"getHandcardNum")>0
		then
			use.card = card
			use.to:append(ep)
			self:writeCurrentSourceSlot("guanxu_friends",true)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHandcardNum")>0
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.GuanxuCard = 9.4
sgs.ai_use_priority.GuanxuCard = 6.8

sgs.ai_skill_use["@@guanxu1"] = function(self,prompt)
	local valid = {}
	local guanxuhand = tag(self,"guanxuhandForAI","IntList")
	local guanxudrawpile = tag(self,"guanxudrawpileForAI","IntList")
	local n1,n2,suits = {},{},{}
	for _,id in sgs.list(guanxuhand)do
		local c = visible(self,id)
		table.insert(n1,c)
		if suits[__hc_value_call(c,"getSuitString")]
		then suits[__hc_value_call(c,"getSuitString")] = suits[__hc_value_call(c,"getSuitString")]+1
		else suits[__hc_value_call(c,"getSuitString")] = 1 end
	end
	for _,id in sgs.list(guanxudrawpile)do
		table.insert(n2,visible(self,id))
	end
	if self:readCurrentSourceSlot("guanxu_friends")
	then
		n1 = self:sortByKeepValue(n1)
		n2 = self:sortByKeepValue(n2,true)
		for _,h in sgs.list(n1)do
			for _,c in sgs.list(n2)do
				if self:getKeepValue(c)>self:getKeepValue(h)
				then
					table.insert(valid,__hc_value_call(h,"getEffectiveId"))
					table.insert(valid,__hc_value_call(c,"getEffectiveId"))
					return ("@GuanxuChooseCard="..table.concat(valid,"+"))
				end
			end
		end
	end
	n1 = self:sortByKeepValue(n1,true)
	n2 = self:sortByKeepValue(n2)
	for _,h in sgs.list(n1)do
		for _,c in sgs.list(n2)do
			if self:getKeepValue(c)<self:getKeepValue(h)
			and suits[__hc_value_call(c,"getSuitString")]==2
			then
				table.insert(valid,__hc_value_call(h,"getEffectiveId"))
				table.insert(valid,__hc_value_call(c,"getEffectiveId"))
				return ("@GuanxuChooseCard="..table.concat(valid,"+"))
			end
		end
	end
	for _,h in sgs.list(n1)do
		for _,c in sgs.list(n2)do
			if suits[__hc_value_call(c,"getSuitString")]==2
			then
				table.insert(valid,__hc_value_call(h,"getEffectiveId"))
				table.insert(valid,__hc_value_call(c,"getEffectiveId"))
				return ("@GuanxuChooseCard="..table.concat(valid,"+"))
			end
		end
	end
	for _,h in sgs.list(n1)do
		for _,c in sgs.list(n2)do
			if suits[__hc_value_call(c,"getSuitString")]==3
			and __hc_value_call(c,"getSuitString")==__hc_value_call(h,"getSuitString")
			and self:getKeepValue(c)<self:getKeepValue(h)
			then
				table.insert(valid,__hc_value_call(h,"getEffectiveId"))
				table.insert(valid,__hc_value_call(c,"getEffectiveId"))
				return ("@GuanxuChooseCard="..table.concat(valid,"+"))
			end
		end
	end
	for _,h in sgs.list(n1)do
		for _,c in sgs.list(n2)do
			if suits[__hc_value_call(c,"getSuitString")]==3
			and __hc_value_call(c,"getSuitString")==__hc_value_call(h,"getSuitString")
			then
				table.insert(valid,__hc_value_call(h,"getEffectiveId"))
				table.insert(valid,__hc_value_call(c,"getEffectiveId"))
				return ("@GuanxuChooseCard="..table.concat(valid,"+"))
			end
		end
	end
	for _,h in sgs.list(n1)do
		for _,c in sgs.list(n2)do
			if self:getKeepValue(c)<self:getKeepValue(h)
			then
				table.insert(valid,__hc_value_call(h,"getEffectiveId"))
				table.insert(valid,__hc_value_call(c,"getEffectiveId"))
				return ("@GuanxuChooseCard="..table.concat(valid,"+"))
			end
		end
	end
	return #valid>1 and ("@GuanxuChooseCard="..table.concat(valid,"+"))
end

sgs.ai_skill_use["@@guanxu2"] = function(self,prompt)
	local guanxuhand = tag(self,"guanxuForAI","IntList")
	local n1,n2,suits = {},{},{}
	for c,id in sgs.list(guanxuhand)do
		table.insert(n1,visible(self,id))
	end
	n1 = self:sortByKeepValue(n1,true)
	for _,c in sgs.list(n1)do
		if suits[__hc_value_call(c,"getSuitString")]
		then table.insert(suits[__hc_value_call(c,"getSuitString")],__hc_value_call(c,"getEffectiveId"))
		else
			suits[__hc_value_call(c,"getSuitString")] = {}
			table.insert(suits[__hc_value_call(c,"getSuitString")],__hc_value_call(c,"getEffectiveId"))
		end
	end
	for _,ids in ipairs(suits)do -- exact utilities.sgs.list(table): string-keyed suits do not iterate
		if #ids>=3
		then
			for i=1,3 do
				table.insert(n2,ids[i])
			end
			return ("@GuanxuDiscardCard="..table.concat(n2,"+"))
		end
	end
end

--雅士
sgs.ai_skill_invoke.yashi = function(self,data)
    return true
end

sgs.ai_skill_choice.yashi = function(self,choices,data)
	local damage = data:toDamage()
	local items = choices:split("+")
	if table.contains(items,"guanxu")
	then
		for _,ep in sgs.list(self.enemies)do
			if __hc_value_call(ep,"getHandcardNum")>2
			then return "guanxu" end
		end
		for _,ep in sgs.list(self.friends_noself)do
			if __hc_value_call(ep,"getHandcardNum")<4
			and __hc_value_call(ep,"getHandcardNum")>0
			then return "guanxu" end
		end
	elseif damage.from
	and not self:isFriend(damage.from)
	then return items[1] end
end

sgs.ai_skill_playerchosen.yashi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
	self:writeCurrentSourceSlot("guanxu_friends",false)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and __hc_value_call(target,"getHandcardNum")>2
		then return target end
	end
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and __hc_value_call(target,"getHandcardNum")<4
		and __hc_value_call(target,"getHandcardNum")>0
		then
			self:writeCurrentSourceSlot("guanxu_friends",true)
			return target
		end
	end
	return destlist[1]
end

sgs.ai_fill_skill["tenyearjiezhen"]=function(self,inclusive,request)
	return policy(self,"@TenyearJiezhenCard=.")
end

sgs.ai_skill_use_func["TenyearJiezhenCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies)
	local function JiezhenSkill(p)
		local n = 0
		for _,s in sgs.list(p:getSkillList())do
			if s:isLimitedSkill()
			or s:isAttachedLordSkill()
			or s:isLordSkill()
			or s:getFrequency(p)==sgs.Skill_Compulsory
			or s:getFrequency(p)==sgs.Skill_Wake
			then continue end
			n = n+1
		end
		return n
	end
	for _,ep in sgs.list(self.enemies)do
		if JiezhenSkill(ep)>0
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if JiezhenSkill(ep)>0
		and not self:isFriend(ep)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.TenyearJiezhenCard = 2.4
sgs.ai_use_priority.TenyearJiezhenCard = 9.8

sgs.ai_skill_playerchosen.tenyearzecai = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and __hc_value_call(target,"getHandcardNum")>3
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and __hc_value_call(target,"getHandcardNum")>2
		and self:isWeak()
		then
			return target
		end
	end
end

sgs.ai_can_damagehp.tenyearyinshi = function(self,from,card,to)
	return not (card and (card:isRed() or card:isBlack()))
	and __hc_value_call(to,"getMark","tenyearyinshi_damage-Clear")<1
	and self:canLoseHp(from,card,to)
end

sgs.ai_target_revises.tenyearyinshi = function(to,card,self,use)
	return card and (card:isRed() or card:isBlack())
	and __hc_value_call(to,"getMark","tenyearyinshi_damage-Clear")<1
end

--挫锐
sgs.ai_skill_use["@@spcuorui"] = function(self,prompt)
	local targets = self:findPlayerToDiscard("h",false,false)
	if #targets<=0 then return "." end

	local tos = {}
	for i = 1,math.min(__hc_value_call(self.player,"getHp"),#targets)do
		table.insert(tos,targets[i]:objectName())
	end
	return "@SpCuoruiCard=.->"..table.concat(tos,"+")
end

--裂围
sgs.ai_skill_invoke.spliewei = function(self,data)
	return self:canDraw()
end

--挫锐-二版
sgs.ai_fill_skill["secondspcuorui"]=function(self,inclusive,request)
	return policy(self,"@SecondSpCuoruiCard=.")
end

sgs.ai_skill_use_func["SecondSpCuoruiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp")
	local n = 0
	for _,ep in sgs.list(self.enemies)do
		if self:isWeak(ep)
		and __hc_value_call(ep,"getHandcardNum")>0
		then n = n+1 end
	end
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHandcardNum")>0
		and n>=#self.enemies/2
		then
			use.card = card
			use.to:append(ep)
			if use.to:length()>=__hc_value_call(self.player,"getHp")
			then return end
		end
	end
end

sgs.ai_use_value.SecondSpCuoruiCard = 9.4
sgs.ai_use_priority.SecondSpCuoruiCard = 6.8


--裂围-二版
sgs.ai_skill_invoke.secondspliewei = function(self,data)
	return self:canDraw()
end

--天算
local function getSpecialMark(special_mark,player)
	if not player then ai_unsupported("source current_self player is not supplied","getSpecialMark")end
	local num = 0
	for _,mark in ipairs(player:getMarkNames())do
		if mark:startsWith(special_mark) and __hc_value_call(player,"getMark",mark)>0 then num = num+1 end
	end
	return num
end

sgs.ai_fill_skill["tiansuan"]=function(self,inclusive,request)
	return policy(self,"@TiansuanCard=.:"..math.random(1,5))
end

sgs.ai_skill_use_func["TiansuanCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.TiansuanCard = 9.4
sgs.ai_use_priority.TiansuanCard = 6.8

sgs.ai_skill_playerchosen.tiansuan0 = function(self,players)--无法知道天算签
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and #self.enemies>0
		then return target end
	end
end

--掳掠
sgs.ai_skill_playerchosen.lulve = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
	destlist = self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and #self.enemies>0
		then return target end
	end
end

sgs.ai_skill_choice.lulve = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target) then return items[1]
	else return items[2] end
end

--望归
sgs.ai_skill_playerchosen.wanggui = function(self,targets)
	if targets:first():getKingdom()==__hc_value_call(self.player,"getKingdom") then
		local target = self:findPlayerToDraw(false,1)
		if target then return target end
		if self:canDraw() then return self.player end
	else
		return self:findPlayerToDamage(1,self.player,"N",targets)[1]
	end
end

--息兵
sgs.ai_skill_invoke.xibing = function(self,data)
	local target = data:toPlayer()
	local hand_num = __hc_value_call(target,"getHandcardNum")
	local num = __hc_value_call(target,"getHp")-hand_num
	if num<=0 then return false end
	if self:isFriend(target) then
		if hand_num>2 then return false end
		return true
	elseif self:isEnemy(target) then
		if hand_num<=2 then return false end
		if hand_num>=5 then return true end
	end
	return false
end

--诱言
sgs.ai_skill_invoke.youyan = function(self,data)
	return self:canDraw()
end

--追还
sgs.ai_skill_playerchosen.zhuihuan = function(self,targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets)
	for _,p in ipairs(targets)do
		if not self:isFriend(p) or __hc_value_call(p,"getMark","&zhuihuan")>0 then continue end
		return p
	end
	for _,p in ipairs(targets)do
		if not self:isFriend(p) then continue end
		return p
	end
	return nil
end

--抗歌
sgs.ai_skill_playerchosen.kangge = function(self,players)
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

sgs.ai_skill_invoke.kangge = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isEnemy(target)
	end
end

--节烈
sgs.ai_skill_invoke.jielie = function(self,data)
    return true
end

--拒关
sgs.ai_fill_skill["juguan"]=function(self,inclusive,request)
	local cards = self:addHandPile()
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		local fs = clone(self,"duel")
		fs = mutate(self,fs,"skill","juguan")
		fs = mutate(self,fs,"add",c)
		local d = self:aiUseCard(fs)
		self:writeCurrentSourceTargets("jg_to",d.to)
		self:setPriorityValue("JuguanCard",sgs.ai_use_priority.Duel,"tenyear_hc")
		if __hc_value_call(fs,"isAvailable",self.player) and d.card and d.to
		then return policy(self,"@JuguanCard="..__hc_value_call(c,"getEffectiveId")..":duel") end
	end
  	for _,c in sgs.list(cards)do
		local fs = clone(self,"slash")
		fs = mutate(self,fs,"skill","juguan")
		fs = mutate(self,fs,"add",c)
		local d = self:aiUseCard(fs)
		self:writeCurrentSourceTargets("jg_to",d.to)
		self:setPriorityValue("JuguanCard",sgs.ai_use_priority.Slash,"tenyear_hc")
		if __hc_value_call(fs,"isAvailable",self.player) and d.card and d.to
		then return policy(self,"@JuguanCard="..__hc_value_call(c,"getEffectiveId")..":slash") end
	end
end

sgs.ai_skill_use_func["JuguanCard"] = function(card,use,self)
	use.card = card
	use.to = self:readCurrentSourceTargets("jg_to")
end

sgs.ai_use_value.JuguanCard = 9.4
sgs.ai_use_priority.JuguanCard = 4.8

--驱徙
sgs.ai_skill_invoke.quxi = function(self,data)
    return __hc_value_call(self.player,"getHandcardNum")>=__hc_value_call(self.player,"getMaxCards")
	and sgs.ai_skill_use["@@quxi1"](self,"quxi1")
end

sgs.ai_skill_use["@@quxi1"] = function(self,prompt)
	local valid = {}
	local destlist = self.player:getAliveSiblings()
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    destlist = self:sort(destlist,"hp")
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		for _,ep in sgs.list(destlist)do
			if self:isFriend(fp) and self:isEnemy(ep)
			and __hc_value_call(fp,"getHandcardNum")<__hc_value_call(ep,"getHandcardNum")
			then
				table.insert(valid,fp:objectName())
				table.insert(valid,ep:objectName())
				break
			end
		end
	end
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		for _,ep in sgs.list(destlist)do
			if self:isFriend(fp) and not self:isFriend(ep)
			and __hc_value_call(fp,"getHandcardNum")<__hc_value_call(ep,"getHandcardNum")
			then
				table.insert(valid,fp:objectName())
				table.insert(valid,ep:objectName())
				break
			end
		end
	end
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		for _,ep in sgs.list(destlist)do
			if not self:isEnemy(fp) and self:isEnemy(ep)
			and __hc_value_call(fp,"getHandcardNum")<__hc_value_call(ep,"getHandcardNum")
			then
				table.insert(valid,fp:objectName())
				table.insert(valid,ep:objectName())
				break
			end
		end
	end
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		for _,ep in sgs.list(destlist)do
			if not self:isEnemy(fp) and not self:isFriend(ep)
			and __hc_value_call(fp,"getHandcardNum")<__hc_value_call(ep,"getHandcardNum")
			then
				table.insert(valid,fp:objectName())
				table.insert(valid,ep:objectName())
				break
			end
		end
	end
	if #valid>1
	then
    	return string.format("@QuxiCard=.->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_use["@@quxi2"] = function(self,prompt)
	local valid = {}
	local destlist = self.player:getAliveSiblings()
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    destlist = self:sort(destlist,"hp")
	local death = property(self,"QuxiDeathPlayer")
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		if fp:objectName()~=death then continue end
		for _,ep in sgs.list(destlist)do
			if ep:objectName()==death then continue end
			if __hc_value_call(fp,"getMark","&quxiqian")>0
			and self:isEnemy(ep)
			then
				table.insert(valid,fp:objectName())
				table.insert(valid,ep:objectName())
				break
			end
		end
	end
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		if fp:objectName()~=death then continue end
		for _,ep in sgs.list(destlist)do
			if ep:objectName()==death then continue end
			if __hc_value_call(fp,"getMark","&quxiqian")>0
			and not self:isFriend(ep)
			then
				table.insert(valid,fp:objectName())
				table.insert(valid,ep:objectName())
				break
			end
		end
	end
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		if fp:objectName()~=death then continue end
		for _,ep in sgs.list(destlist)do
			if ep:objectName()==death then continue end
			if __hc_value_call(fp,"getMark","&quxifeng")>0
			and self:isFriend(ep)
			then
				table.insert(valid,fp:objectName())
				table.insert(valid,ep:objectName())
				break
			end
		end
	end
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		if fp:objectName()~=death then continue end
		for _,ep in sgs.list(destlist)do
			if ep:objectName()==death then continue end
			if __hc_value_call(fp,"getMark","&quxifeng")>0
			and not self:isEnemy(ep)
			then
				table.insert(valid,fp:objectName())
				table.insert(valid,ep:objectName())
				break
			end
		end
	end
	if #valid>1
	then
    	return string.format("@QuxiCard=.->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_use["@@quxi3"] = function(self,prompt)
	local valid = {}
	local destlist = self.player:getAliveSiblings()
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    destlist = self:sort(destlist,"hp")
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		for _,ep in sgs.list(destlist)do
			if fp:objectName()==ep:objectName() then continue end
			if __hc_value_call(fp,"getMark","&quxiqian")>0
			and not self:isEnemy(fp)
			and self:isEnemy(ep)
			then
				table.insert(valid,fp:objectName())
				table.insert(valid,ep:objectName())
				break
			end
		end
	end
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		for _,ep in sgs.list(destlist)do
			if fp:objectName()==ep:objectName() then continue end
			if __hc_value_call(fp,"getMark","&quxifeng")>0
			and not self:isFriend(fp)
			and self:isFriend(ep)
			then
				table.insert(valid,fp:objectName())
				table.insert(valid,ep:objectName())
				break
			end
		end
	end
	if #valid>1
	then
    	return string.format("@QuxiCard=.->%s",table.concat(valid,"+"))
	end
end

--齐攻
sgs.ai_skill_playerchosen.qigong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard",true)
	if self:getCardsNum("Slash")>0
	then return self.player end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:objectName()~=self.player:objectName()
		and __hc_value_call(target,"getHandcardNum")>0
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and __hc_value_call(target,"getHandcardNum")>0
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and __hc_value_call(target,"getHandcardNum")>0
		then return target end
	end
end

--列侯
sgs.ai_fill_skill["liehou"]=function(self,inclusive,request)
	return policy(self,"@LiehouCard=.")
end

sgs.ai_skill_use_func["LiehouCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard")
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(self.player,"inMyAttackRange",ep)
		and __hc_value_call(ep,"getHandcardNum")>0
		then
			use.card = card
			use.to:append(ep)
			break
		end
	end
end

sgs.ai_use_value.LiehouCard = 9.4
sgs.ai_use_priority.LiehouCard = 4.8

sgs.ai_skill_askforyiji.liehou = function(self,card_ids)
	local target = tag(self,"LiehouTarget","Player")
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
	   	if __hc_value_call(self.player,"inMyAttackRange",p)
		and p:objectName()~=target:objectName()
		and known(self:isFriend(p),"liehou.isFriend")
		then return p,card_ids[1] end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
	   	if __hc_value_call(self.player,"inMyAttackRange",p)
		and p:objectName()~=target:objectName()
		and not known(self:isEnemy(p),"liehou.isEnemy")
		then return p,card_ids[1] end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
	   	if __hc_value_call(self.player,"inMyAttackRange",p)
		and p:objectName()~=target:objectName()
		then return p,card_ids[1] end
	end
end

sgs.ai_fill_skill.tenyearshuhe = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	local ids = {}
	for _,p in sgs.list(self.room:getAlivePlayers())do
		for _,c in sgs.list(p:getCards("ej"))do
			if self:doDisCard(p,c:getId(),true)
			then table.insert(ids,__hc_value_call(c,"getNumber")) end
		end
	end
	for _,c in sgs.list(cards)do
		if table.contains(ids,__hc_value_call(c,"getNumber"))
		then return policy(self,"@TenyearShuheCard="..c:getId()) end
	end
	if (#cards>2 or self:getOverflow()>0)
	and #self.friends_noself>0
	then
		return policy(self,"@TenyearShuheCard="..cards[1]:getId())
	end
end

sgs.ai_skill_use_func["TenyearShuheCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.TenyearShuheCard = 3.4
sgs.ai_use_priority.TenyearShuheCard = 6.2

sgs.ai_skill_playerchosen.tenyearshuhe = function(self,players)
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

sgs.ai_skill_discard.tenyearliehou = function(self,max,min,optional)
	local to_cards = self:poisonCards("e")
   	if #to_cards>=min then return to_cards end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
   	for _,c in sgs.list(cards)do
   		if #to_cards>=min then break end
     	table.insert(to_cards,__hc_value_call(c,"getEffectiveId"))
	end
	if (min<2 or self:isWeak()) and #to_cards>=min
	then return to_cards end
	return {}
end

--狼灭
sgs.ai_skill_invoke.langmie = function(self,data)
    return self:canDraw()
end

sgs.ai_skill_cardask["@langmie-dis"] = function(self,data,pattern,prompt)
   	local target = self.room:getCurrent()
    if self:isEnemy(target) then return true end
	return not self:isFriend(target) and self.player:getCardCount()>4
end

sgs.ai_skill_choice.secondlangmie = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items,"draw")
	and not self:isEnemy(target)
	then return "draw" end
	if self:isEnemy(target)
	or not self:isFriend(target) and self.player:getCardCount()>4
	then return items[#items-1] end
	if table.contains(items,"draw")
	then return "draw" end
end

sgs.ai_skill_cardask["@secondlangmie"] = function(self,data,pattern,prompt)
	local target = data:toPlayer()
    if self:isEnemy(target) then return true end
	return not self:isFriend(target) and self.player:getCardCount()>4 or self:canDraw()
end

sgs.ai_skill_cardask["@secondlangmie-damage"] = function(self,data,pattern,prompt)
	local target = data:toPlayer()
    if self:isEnemy(target) then return true end
	return not self:isFriend(target) and self.player:getCardCount()>4
end

sgs.ai_skill_cardask["@secondlangmie-draw"] = function(self,data,pattern,prompt)
	return self:canDraw()
end

--祸水
sgs.ai_skill_use["@@tenyearhuoshui"] = function(self,prompt)
	local valid = {}
	local destlist = self.player:getAliveSiblings()
    destlist = self:sort(destlist,"hp")
	local n = math.max(__hc_value_call(self.player,"getLostHp"),1)
	for _,fp in sgs.list(destlist)do
		if #valid>=n then break end
		if self:isEnemy(fp) then table.insert(valid,fp:objectName()) end
	end
	for _,fp in sgs.list(destlist)do
		if #valid>=n then break end
		if table.contains(valid,fp:objectName())
		or self:isFriend(fp)
		then continue end
		table.insert(valid,fp:objectName())
	end
	if #valid>0
	then
    	return string.format("@TenyearHuoshuiCard=.->%s",table.concat(valid,"+"))
	end
end

--倾城
sgs.ai_fill_skill["tenyearqingcheng"]=function(self,inclusive,request)
	return policy(self,"@TenyearQingchengCard=.")
end

sgs.ai_skill_use_func["TenyearQingchengCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard",true)
	local n = self:getCardsNum("Peach")
	local cs = self:poisonCards()
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"isMale") and #cs>0
		and __hc_value_call(self.player,"getHandcardNum")-__hc_value_call(ep,"getHandcardNum")<=#cs
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"isMale") and n<1
		and __hc_value_call(ep,"getHandcardNum")==__hc_value_call(self.player,"getHandcardNum")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		if __hc_value_call(ep,"isMale")
		and __hc_value_call(ep,"getHandcardNum")<=__hc_value_call(self.player,"getHandcardNum")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.TenyearQingchengCard = 9.4
sgs.ai_use_priority.TenyearQingchengCard = 3.8

--祈禳
sgs.ai_skill_invoke.tenyearqirang = function(self,data)
    return true
end

sgs.ai_skill_playerchosen.tenyearqirang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,id in sgs.list(tag(self,"tenyearqirang_tricks","IntList"))do
		local c = visible(self,id)
		for _,target in sgs.list(destlist)do
			if self:isEnemy(target)
				and __hc_value_call(c,"isDamageCard")
				then return target end
		end
	end
end

--寇略
sgs.ai_skill_invoke.koulve = function(self,data)
	local target = data:toPlayer()
	return not self:isFriend(target)
	and __hc_value_call(target,"getHandcardNum")>2
end

sgs.ai_skill_invoke.secondkoulve = function(self,data)
	local target = data:toPlayer()
	return not self:isFriend(target)
	and __hc_value_call(target,"getHandcardNum")>2
end

--随认
sgs.ai_skill_playerchosen.suirenq = function(self,players)
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

sgs.ai_skill_invoke.fengshimf = function(self,data)
	local target = data:toPlayer()
	return self:isEnemy(target)
end

--摧坚
sgs.ai_fill_skill["cuijian"]=function(self,inclusive,request)
	return policy(self,"@CuijianCard=.")
end

sgs.ai_skill_use_func["CuijianCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard",true)
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHandcardNum")>0
		then
			use.card = card
			use.to:append(ep)
			break
		end
	end
end

sgs.ai_use_value.CuijianCard = 9.4
sgs.ai_use_priority.CuijianCard = 4.8

sgs.ai_fill_skill["secondcuijian"]=function(self,inclusive,request)
	return policy(self,"@SecondCuijianCard=.")
end

sgs.ai_skill_use_func["SecondCuijianCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard",true)
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHandcardNum")>0
		then
			use.card = card
			use.to:append(ep)
			break
		end
	end
end

sgs.ai_use_value.SecondCuijianCard = 9.4
sgs.ai_use_priority.SecondCuijianCard = 4.8

--同援
sgs.ai_skill_playerchosen.secondtongyuan0 = function(self,players)--无法知道牌
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
end


sgs.ai_skill_cardask["@chaofeng-discard"] = function(self,data,pattern,prompt)
    local damage = data:toDamage()
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		if damage.card
		and __hc_value_call(damage.card,"getSuit")==__hc_value_call(c,"getSuit")
		then
			if self:isEnemy(damage.to)
			and __hc_value_call(damage.card,"getNumber")==__hc_value_call(c,"getNumber")
			then return __hc_value_call(c,"getEffectiveId") end
		end
	end
	for _,c in sgs.list(cards)do
		if damage.card
		then
			if self:isEnemy(damage.to)
			and __hc_value_call(damage.card,"getNumber")==__hc_value_call(c,"getNumber")
			then return __hc_value_call(c,"getEffectiveId") end
		end
	end
	for _,c in sgs.list(cards)do
		if damage.card
		and __hc_value_call(damage.card,"getSuit")==__hc_value_call(c,"getSuit")
		then return __hc_value_call(c,"getEffectiveId") end
	end
	return #cards>1 and __hc_value_call(cards[1],"getEffectiveId") or "."
end

sgs.ai_skill_cardask["@secondchaofeng-discard"] = function(self,data,pattern,prompt)
    local damage = data:toDamage()
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		if damage.card
		and damage.card:getColor()==c:getColor()
		then
			if self:isEnemy(damage.to)
			and __hc_value_call(damage.card,"getTypeId")==__hc_value_call(c,"getTypeId")
			then return __hc_value_call(c,"getEffectiveId") end
		end
	end
	for _,c in sgs.list(cards)do
		if damage.card
		then
			if self:isEnemy(damage.to)
			and __hc_value_call(damage.card,"getTypeId")==__hc_value_call(c,"getTypeId")
			then return __hc_value_call(c,"getEffectiveId") end
		end
	end
	for _,c in sgs.list(cards)do
		if damage.card
		and damage.card:getColor()==c:getColor()
		then return __hc_value_call(c,"getEffectiveId") end
	end
	return #cards>1 and __hc_value_call(cards[1],"getEffectiveId") or "."
end

sgs.ai_skill_playerchosen.chuanshu = function(self,players,reason)
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

sgs.ai_skill_playerchosen.secondchuanshu = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and #self.enemies>0
		then return target end
	end
end

sgs.ai_skill_invoke.chuanyun = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_invoke.xunde = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isEnemy(target)
	end
end

sgs.ai_skill_cardask["@chenjie-card"] = function(self,data)
	local judge = data:toJudge()
	local all_cards = self:addHandPile("he")
	if #all_cards<1 then return "." end
	local cards = {}
	for _,c in sgs.list(all_cards)do
		if __hc_value_call(c,"getSuit")==__hc_value_call(judge.card,"getSuit")
		then table.insert(cards,c) end
	end
	if #cards<1 then return "." end
	if self:needRetrial(judge)
	then
    	local id = self:getRetrialCardId(cards,judge)
    	if id~=-1 then return id end
	else
    	local id = self:getRetrialCardId(cards,judge)
    	if id~=-1 then return id end
	end
    return "."
end

sgs.ai_skill_invoke.jibing = function(self,data)
	if self:getCardsNum("Slash")<3
	and #self.enemies>0 then
		return true
	end
	return self:getCardsNum("Jink")<3
end

function sgs.ai_cardsview.jibing(self,class_name,player)
   	local ids = self.player:getPile("jbbing")
	if class_name=="Jink"
	then return ("jink:jibing[no_suit:0]="..ids:at(0))
	elseif class_name=="Slash"
    then return ("slash:jibing[no_suit:0]="..ids:at(0)) end
end

sgs.ai_fill_skill["jibing"]=function(self,inclusive,request)
  	for _,c in sgs.list(self.player:getPile("jbbing"))do
	   	local fs = clone(self,"slash")
		fs = mutate(self,fs,"skill","jibing")
		fs = mutate(self,fs,"add",c)
		if __hc_value_call(fs,"isAvailable",self.player)
	   	then return fs end
	end
end

sgs.ai_skill_playerchosen.binghuo = function(self,players,reason)
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
end

sgs.ai_skill_cardask["@huantu-invoke"] = function(self,data,pattern,prompt)
   	local target = self.room:getCurrent()
	local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
    if self:isFriend(target)
	and __hc_value_call(target,"getHandcardNum")<3 or __hc_value_call(target,"getHandcardNum")>4
	then return cards[math.random(1,#cards)]:getEffectiveId() end
    if not self:isEnemy(target)
	then return __hc_value_call(cards[1],"getEffectiveId") end
	return "."
end

sgs.ai_skill_invoke.huantu = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isEnemy(target)
	end
end

sgs.ai_skill_choice.huantu = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target)
	and self:isWeak(target)
	then return items[1] end
	return items[2]
end

sgs.ai_skill_invoke.bihuo = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
	end
end

sgs.ai_skill_invoke.yachai = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target) or __hc_value_call(target,"getHandcardNum")<3
	end
end

sgs.ai_skill_choice.yachai = function(self,choices,data)
	local damage = data:toDamage()
	local items = choices:split("+")
	if self:isFriend(damage.to)
	then return items[2] end
end

sgs.ai_skill_choice.yachai_suit = function(self,choices)
	local items = choices:split("+")
	local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	local suits = {}
	for _,c in sgs.list(cards)do
		if suits[__hc_value_call(c,"getSuitString")]
		then suits[__hc_value_call(c,"getSuitString")]=suits[__hc_value_call(c,"getSuitString")]+1
		else suits[__hc_value_call(c,"getSuitString")]=1 end
	end
    local compare_func = function(a,b)
        return a<b
    end
    table.sort(suits,compare_func)
	for _,s in sgs.list(items)do
		if suits[s]==suits[1]
		then return s end
	end
end

sgs.ai_fill_skill["qingtan"]=function(self,inclusive,request)
	return policy(self,"@QingtanCard=.")
end

sgs.ai_skill_use_func["QingtanCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard",true)
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHandcardNum")>0
		then
			use.card = card
		end
	end
end

sgs.ai_use_value.QingtanCard = 9.4
sgs.ai_use_priority.QingtanCard = 5.8

sgs.ai_skill_choice.qingtan = function(self,choices)
	local items = choices:split("+")
	table.removeOne(items,items[#items])
	return items[math.random(1,#items)]
end

sgs.ai_skill_invoke.zhukou = function(self,data)
    return true
end

sgs.ai_skill_use["@@zhukou"] = function(self,prompt)
	local valid = {}
	local destlist = self.player:getAliveSiblings()
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    destlist = self:sort(destlist,"hp")
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		if self:isEnemy(fp) then table.insert(valid,fp:objectName()) end
	end
	for _,fp in sgs.list(destlist)do
		if #valid>1 then break end
		if table.contains(valid,fp:objectName())
		or self:isFriend(fp)
		then continue end
		table.insert(valid,fp:objectName())
	end
	if #valid>1
	then
    	return string.format("@ZhukouCard=.->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_playerchosen.zhukou = function(self,players,reason)
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
end

sgs.ai_skill_choice.yuyun = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"maxhp")
	and __hc_value_call(self.player,"getLostHp")>1
	then return "maxhp" end
	if table.contains(items,"hp")
	then return "hp" end
	if table.contains(items,"damage")
	then
		for _,fp in sgs.list(self.enemies)do
			if self:isWeak(fp) then return "damage" end
		end
	end
	if table.contains(items,"drawmaxhp")
	then
		for _,fp in sgs.list(self.friends)do
			if __hc_value_call(fp,"getMaxHp")-__hc_value_call(fp,"getHandcardNum")>1
			and __hc_value_call(fp,"getHandcardNum")<5
			then return "drawmaxhp" end
		end
	end
	if table.contains(items,"obtain")
	then
		for _,fp in sgs.list(self.friends_noself)do
			if self:doDisCard(fp,"ej")
			then return "obtain" end
		end
	end
	if table.contains(items,"draw")
	and __hc_value_call(self.player,"getHandcardNum")<=__hc_value_call(self.player,"getMaxCards")
	then return "draw" end
	if table.contains(items,"maxcard")
	and __hc_value_call(self.player,"getHandcardNum")>__hc_value_call(self.player,"getMaxCards")
	then return "maxcard" end
end

sgs.ai_skill_playerchosen.yuyun = function(self,players,reason)
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
end

sgs.ai_skill_playerchosen.yuyun_obtain = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"ej")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and self:doDisCard(target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.yuyun_drawmaxhp = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
	for _,fp in sgs.list(destlist)do
		if __hc_value_call(fp,"getMaxHp")-__hc_value_call(fp,"getHandcardNum")>1
		and __hc_value_call(fp,"getHandcardNum")<5
		and self:isFriend(fp)
		then return fp end
	end
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.zhenge = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp",true)
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and __hc_value_call(target,"getMark","&zhenge")<1
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and __hc_value_call(target,"getMark","&zhenge")<1
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_invoke.zhenge = function(self,data)
	local items = data:toString():split(":")
    target = self.room:findPlayerByObjectName(items[2])
	if target
	then
		return self:isFriend(target)
	end
end

sgs.ai_skill_use["@@zhenge!"] = function(self,prompt)
    local c = clone(self)
	c = mutate(self,c,"skill","_zhenge")
    local dummy = self:aiUseCard(c)
   	local tos = {}
   	if dummy.card
   	and dummy.to
   	then
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return c:getLegacyStringKey().."->"..table.concat(tos,"+")
    end
	dummy.to = AIList.new({})
    for _,to in sgs.list(self.room:getAllPlayers())do
		if can_to(self,c,self.player,to,dummy.to) and self:isEnemy(to)
		then dummy.to:append(to) table.insert(tos,p:objectName()) end
	end
    for _,to in sgs.list(self.room:getAllPlayers())do
		if dummy.to:contains(to) then continue end
		if can_to(self,c,self.player,to,dummy.to) and not self:isFriend(to)
		then dummy.to:append(to) table.insert(tos,p:objectName()) end
	end
   	return #tos>0 and c:getLegacyStringKey().."->"..table.concat(tos,"+")
end

sgs.ai_skill_cardask["@tianze-discard"] = function(self,data,pattern,prompt)
	local use = data:toCardUse()
    if self:isEnemy(use.from)
	then return true end
	return "."
end

sgs.ai_skill_cardask["@difa"] = function(self,data,pattern,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if table.contains(pattern:split(","),h:getLegacyStringKey())
		then
			local d = self:aiUseCard(h)
			if d.card and d.to then continue end
			return __hc_value_call(h,"getEffectiveId")
		end
	end
end

sgs.ai_skill_invoke.zhuangshu = function(self,data)
    return true
end

sgs.ai_skill_cardask["@zhuangshu-discard"] = function(self,data,pattern,prompt)
	local target = data:toPlayer()
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
    if self:isFriend(target)
	and target:getTreasure()==nil and #cards>2
	then return __hc_value_call(cards[1],"getEffectiveId") end
	return "."
end

sgs.ai_skill_use["@@chuiti"] = function(self,prompt)
	local ids = tag(self,"chuitiForAI","IntList")
	for _,id in sgs.list(ids)do
		local c = notified_card(self,id)
		local d = self:aiUseCard(c)
		if d.card and d.to
		then
			local tos = {}
			for _,p in sgs.list(d.to)do
				table.insert(tos,p:objectName())
			end
			return c:getLegacyStringKey().."->"..table.concat(tos,"+")
		end
	end
end

sgs.ai_skill_invoke.wanwei = function(self,data)
    return true
end

sgs.ai_skill_invoke.yuejian = function(self,data)
	local use = data:toCardUse()
	for i,c in sgs.list(self.player:getCards("h"))do
		if __hc_value_call(c,"getSuit")==__hc_value_call(use.card,"getSuit")
		then return end
	end
	return true
end

sgs.ai_fill_skill["zhuning"]=function(self,inclusive,request)
	self:writeCurrentSourceSlot("isfriend",nil)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards<2 then return end
	cards = self:sortByKeepValue(cards)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if #self.friends_noself<1
		or #toids>=#cards/2
		then continue end
		table.insert(toids,__hc_value_call(c,"getEffectiveId"))
		self:writeCurrentSourceSlot("isfriend",true)
	end
	if #toids<1 then table.insert(toids,__hc_value_call(cards[1],"getEffectiveId")) end
	if #toids>0 then return policy(self,"@ZhuningCard="..table.concat(toids,"+")) end
end

sgs.ai_skill_use_func["ZhuningCard"] = function(card,use,self)
	if self:readCurrentSourceSlot("isfriend")
	then
		self.friends_noself = self:sort(self.friends_noself,"hp")
		for _,ep in sgs.list(self.friends_noself)do
			use.card = card
			use.to:append(ep)
			return
		end
	end
	self.enemies = self:sort(self.enemies,"hp",true)
	for _,ep in sgs.list(self.enemies)do
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.ZhuningCard = 9.4
sgs.ai_use_priority.ZhuningCard = 2.8

sgs.ai_skill_askforag.zhuning = function(self,card_ids)
	for _,id in sgs.list(card_ids)do
		local c = known(self:getChoiceCard(id),"zhuning offered source face")
		c = clone(self,c:objectName())
		c = mutate(self,c,"skill","_zhuning")
		local d = self:aiUseCard(c)
		self.zhuning_d = d
		self:writeZhuningSavedPlan(d)
		if d.card and d.to
		then return id end
	end
end

sgs.ai_skill_use["@@zhuning"] = function(self,prompt)
	self.zhuning_d = self:readZhuningSavedPlan()
	if self.zhuning_d then
		local tos = {}
		for _,p in sgs.list(self.zhuning_d.to)do
			table.insert(tos,p:objectName())
		end
		return self.zhuning_d.card:getLegacyStringKey().."->"..table.concat(tos,"+")
	end
end






sgs.ai_fill_skill["pingxiang"]=function(self,inclusive,request)
	if __hc_value_call(self.player,"getMaxHp")>9
	then
		return policy(self,"@PingxiangCard=.")
	end
end

sgs.ai_skill_use_func["PingxiangCard"] = function(card,use,self)
	local fs = clone(self,"fire_slash")
	fs = mutate(self,fs,"skill","_pingxiang")
	fs = self:aiUseCard(fs)
	if fs.card and fs.to
	then
		use.card = card
		self:setPriorityValue("PingxiangCard",sgs.ai_use_priority.Slash-0.3,"tenyear_hc")
	end
end

sgs.ai_use_value.PingxiangCard = 9.4
sgs.ai_use_priority.PingxiangCard = 2.8

sgs.ai_skill_use["@@pingxiang"] = function(self,prompt)
	local fs = clone(self,"fire_slash")
	fs = mutate(self,fs,"skill","_pingxiang")
    local dummy = self:aiUseCard(fs)
    local tos = {}
   	if dummy.card and dummy.to then
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return fs:getLegacyStringKey().."->"..table.concat(tos,"+")
    end
	dummy = AIList.new({})
	self.enemies = self:sort(self.enemies,"hp")
	for _,p in sgs.list(self.enemies)do
		if can_to(self,fs,self.player,p,dummy)
		and self:slashIsEffective(fs,p) then
			table.insert(tos,p:objectName())
			dummy:append(p)
		end
	end
	local OP = self.room:getOtherPlayers(self.player)
	OP = self:sort(OP,"hp")
	for _,p in sgs.list(OP)do
		if can_to(self,fs,self.player,p,dummy)
		and self:slashIsEffective(fs,p)
		and not self:isFriend(p) then
			table.insert(tos,p:objectName())
			dummy:append(p)
		end
	end
   	if #tos>0 then
       	return fs:getLegacyStringKey().."->"..table.concat(tos,"+")
    end
end

sgs.ai_fill_skill["shouli"]=function(self,inclusive,request)
	local cards = {}
  	for i,p in sgs.list(self.room:getAlivePlayers())do
		for d,c in sgs.list(p:getCards("ej"))do
			if __hc_value_call(c,"isKindOf","OffensiveHorse")
			then table.insert(cards,c) end
		end
	end
	cards = self:sortByKeepValue(cards,nil,"l")
  	for _,c in sgs.list(cards)do
		local dc = clone(self)
		dc = mutate(self,dc,"skill","shouli")
		dc = mutate(self,dc,"add",c)
		local d = self:aiUseCard(dc)
		if d.card and d.to
		and __hc_value_call(dc,"isAvailable",self.player)
		then
			self:writeCurrentSourceTargets("shouli_to",d.to)
			self:setPriorityValue("ShouliCard",sgs.ai_use_priority.Slash+0.6,"tenyear_hc")
			return policy(self,"@ShouliCard="..__hc_value_call(c,"getEffectiveId")..":slash")
		end
	end
end

sgs.ai_skill_use_func["ShouliCard"] = function(card,use,self)
	if self:currentSourceTargetsPresent("shouli_to")
	then
		use.card = card
		use.to = self:readCurrentSourceTargets("shouli_to")
	end
end

sgs.ai_use_value.ShouliCard = 5.4
sgs.ai_use_priority.ShouliCard = 2.8

sgs.ai_guhuo_card.shouli = function(self,toname,class_name)
	local cards = {}
  	for _,p in sgs.list(self.room:getAlivePlayers())do
		for _,c in sgs.list(p:getCards("ej"))do
			if __hc_value_call(c,"isKindOf","OffensiveHorse") and class_name=="Slash"
			or __hc_value_call(c,"isKindOf","DefensiveHorse") and class_name=="Jink"
			then table.insert(cards,c) end
		end
	end
	cards = self:sortByKeepValue(cards,nil,"l")
  	for _,c in sgs.list(cards)do
		if self:getCardsNum(class_name)>0 then break end
		return "@ShouliCard="..__hc_value_call(c,"getEffectiveId")..":"..toname
	end
end

sgs.ai_fill_skill["shencai"]=function(self,inclusive,request)
	return policy(self,"@ShencaiCard=.")
end

sgs.ai_skill_use_func["ShencaiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHp")>=__hc_value_call(self.player,"getHp")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	self.enemies = self:sort(self.enemies,"card",true)
	for _,ep in sgs.list(self.enemies)do
		if __hc_value_call(ep,"getHandcardNum")>=__hc_value_call(self.player,"getHandcardNum")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.ShencaiCard = 9.4
sgs.ai_use_priority.ShencaiCard = 4.8

sgs.ai_skill_playerschosen["#xunshi"] = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card")
	local tos = {}
	local use = {to = AIList.new({}),card = clone(self)}
	use.card = mutate(self,use.card,"skill","xunshi")
	for _,p in sgs.list(self.room:getAllPlayers())do
		if players:contains(p) then continue end
		use.to:append(p)
	end
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isEnemy(target) and self:canCanmou(target,use)
		then table.insert(tos,target) end
	end
    for _,target in sgs.list(destlist)do
		if #tos>=2 then break end
		if self:canCanmou(target,use)
		and not self:isFriend(target)
		and not table.contains(tos,target)
		then table.insert(tos,target) end
	end
	return tos
end

sgs.ai_skill_cardask["@tuoyu1"] = function(self,data,pattern)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
    cards = self:sortByKeepValue(cards)
	local d = clone(self)
   	for _,c in sgs.list(cards)do
    	if c:hasTip("sdatyfengtian")
		or c:hasTip("sdatyqingqu")
		or c:hasTip("sdatyjunshan")
		then continue end
		if __hc_value_call(c,"isKindOf","Peach")
		or __hc_value_call(c,"isKindOf","SingleTargetTrick")
		then d = mutate(self,d,"add",c) end
	end
    return d:subcardsLength()>0 and d:getLegacyStringKey() or "."
end

sgs.ai_skill_cardask["@tuoyu2"] = function(self,data,pattern)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
    cards = self:sortByKeepValue(cards)
	local d = clone(self)
   	for _,c in sgs.list(cards)do
    	if c:hasTip("sdatyfengtian")
		or c:hasTip("sdatyqingqu")
		or c:hasTip("sdatyjunshan")
		then continue end
		local late = source_description(self,c:objectName())
		if string.find(late,"距离")
		or string.find(late,"攻击范围")
		then d = mutate(self,d,"add",c) end
	end
    return d:subcardsLength()>0 and d:getLegacyStringKey() or "."
end

sgs.ai_skill_cardask["@tuoyu3"] = function(self,data,pattern)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
    cards = self:sortByKeepValue(cards)
	local d = clone(self)
   	for _,c in sgs.list(cards)do
    	if c:hasTip("sdatyfengtian")
		or c:hasTip("sdatyqingqu")
		or c:hasTip("sdatyjunshan")
		then continue end
		if __hc_value_call(c,"isKindOf","AOE") and not self:isWeak(self.friends)
		or __hc_value_call(c,"isDamageCard") and not c:targetFixed()
		then d = mutate(self,d,"add",c) end
	end
    return d:subcardsLength()>0 and d:getLegacyStringKey() or "."
end

sgs.ai_skill_choice.xianjin = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"sdatyfengtian")
	and sgs.ai_skill_cardask["@tuoyu1"](self)~="."
	then return "sdatyfengtian" end
	if table.contains(items,"sdatyqingqu")
	and sgs.ai_skill_cardask["@tuoyu2"](self)~="."
	then return "sdatyqingqu" end
	if table.contains(items,"sdatyjunshan")
	and sgs.ai_skill_cardask["@tuoyu3"](self)~="."
	then return "sdatyjunshan" end
end

sgs.ai_skill_playerchosen.qijing = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target) and self:isEnemy(target:getNextAlive())
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target) and not self:isFriend(target:getNextAlive())
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target) and self:isEnemy(target:getNextAlive())
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target) and not self:isFriend(target:getNextAlive())
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target) or not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_invoke.cuixin = function(self,data)
	local items = data:toString():split(":")
    local d = clone(self,items[2])
	if d then
		d = mutate(self,d,"skill","cuixin")
		local to = self.player:getNextAlive()
		if items[1]:match("shangjia") then to = self.player:getNextAlive(self.player:aliveCount()-1) end
		local use = dummy_plan(false)
		use.from = self.player
		use.card = d
		return self:canCanmou(target,use)
	end
end

sgs.ai_skill_playerchosen.tenyearyunjiu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target) and self:canDraw(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_invoke.tenyearmoshou = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_playerchosen.dangzhai = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target) and self:doDisCard(target,"j",true)
		then return target end
	end
end

sgs.ai_skill_playerchosen.shuangrui = function(self,players)
	local dc = clone(self)
	dc = mutate(self,dc,"skill","shensu")
	local d = self:aiUseCard(dc)
	if d.card then return d.to:first() end
end

sgs.ai_fill_skill["fuxie"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards,nil,"j")
  	for i,c in sgs.list(cards)do
		if i<#cards/2 and __hc_value_call(c,"isKindOf","Weapon") then
			self:setPriorityValue("FuxieCard",5.8,"tenyear_hc")
			return policy(self,"@FuxieCard="..c:getLegacyStringKey())
		end
	end
	local n = 0
	self:setPriorityValue("FuxieCard",0.8,"tenyear_hc")
	for i,s in sgs.list(self.player:getVisibleSkillList())do
		if s:isAttachedLordSkill() then continue end
		n = n+1
	end
	if n>2 then
		return policy(self,"@FuxieCard=.")
	end
end

sgs.ai_skill_use_func["FuxieCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if self:doDisCard(ep,"he",true,2) then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.FuxieCard = 9.4
sgs.ai_use_priority.FuxieCard = 0.8

sgs.ai_skill_choice.fuxie = function(self,choices)
	local items = choices:split("+")
	return items[#items]
end

sgs.ai_fill_skill["shouxing"]=function(self,inclusive,request)
	local nps = {}
	for i,p in sgs.list(self.player:getAliveSiblings())do
		if __hc_value_call(self.player,"inMyAttackRange",p)
		then table.insert(nps,p:objectName()) end
	end
	local dc = clone(self)
	dc = mutate(self,dc,"skill","shensu")
	local d = self:aiUseCard(dc,dummy_plan(nil,0,nps))
	if d.card then
		self:writeCurrentSourceTarget("shouxingTo",d.to:first())
		local cards = sgs.QList2Table(self.player:getCards("he"))
		cards = self:sortByKeepValue(cards)
		nps = {}
		dc = __hc_value_call(self.player,"distanceTo",self:readCurrentSourceTarget("shouxingTo"))
		for i,c in sgs.list(cards)do
			table.insert(nps,c:getLegacyStringKey())
			if #nps>=dc then
				return policy(self,"@ShouxingCard="..table.concat(nps,"+"))
			end
		end
	end
end

sgs.ai_skill_use_func["ShouxingCard"] = function(card,use,self)
	if self:currentSourceTargetPresent("shouxingTo") then
		use.to:append(self:readCurrentSourceTarget("shouxingTo"))
		use.card = card
	end
end

sgs.ai_use_value.ShouxingCard = 9.4
sgs.ai_use_priority.ShouxingCard = 1.8

sgs.ai_skill_invoke.shaxue = function(self,data)
	local damage = data:toDamage()
	return self:canDraw() and __hc_value_call(self.player,"distanceTo",damage.to)<(self.player:getCardCount()+2)/2
end

sgs.ai_fill_skill["pingzhi"]=function(self,inclusive,request)
	return policy(self,"@PingzhiCard=.")
end

sgs.ai_skill_use_func["PingzhiCard"] = function(card,use,self)
	if self.player:getChangeSkillState("pingzhi")==1 then
		self.enemies = self:sort(self.enemies)
		for _,ep in sgs.list(self.enemies)do
			if __hc_value_call(ep,"getHandcardNum")>0 then
				use.to:append(ep)
				use.card = card
				return
			end
		end
	else
		self.friends = self:sort(self.friends,nil,true)
		for _,ep in sgs.list(self.friends)do
			if __hc_value_call(ep,"getHandcardNum")>3 then
				use.to:append(ep)
				use.card = card
				return
			end
		end
		self.enemies = self:sort(self.enemies)
		for _,ep in sgs.list(self.enemies)do
			if __hc_value_call(ep,"getHandcardNum")>0 then
				use.to:append(ep)
				use.card = card
				return
			end
		end
	end
end

sgs.ai_use_value.PingzhiCard = 9.4
sgs.ai_use_priority.PingzhiCard = 4.8

sgs.ai_skill_askforag.pingzhi = function(self,card_ids)
	if self.player:getChangeSkillState("pingzhi")==2 then
		local cp = self.room:getCardOwner(card_ids[1])
		local hs = {}
		for _,id in sgs.list(card_ids)do
			table.insert(hs,visible(self,id))
		end
		if self:isFriend(cp) then
			hs = self:sortByUseValue(hs)
			for _,h in sgs.list(hs)do
				if __hc_value_call(h,"isAvailable",cp) then
					return h:getId()
				end
			end
		end
		hs = self:sortByKeepValue(hs,nil,true)
		for _,h in sgs.list(hs)do
			if __hc_value_call(h,"isAvailable",cp) then
				return h:getId()
			end
		end
	end
end

sgs.ai_skill_use["@@yinlu!"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAlivePlayers()
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    destlist = self:sort(destlist)
	for _,fp in sgs.list(destlist)do
		if self:isFriend(fp) then table.insert(valid,fp:objectName()) end
		if #valid>1 then break end
	end
	for _,fp in sgs.list(destlist)do
		if self:isEnemy(fp) or table.contains(valid,fp:objectName()) then continue end
		if #valid>1 then break end
		table.insert(valid,fp:objectName())
	end
	for _,fp in sgs.list(destlist)do
		if #valid==3 then break end
		if self:isEnemy(fp) then table.insert(valid,fp:objectName()) end
	end
	for _,fp in sgs.list(destlist)do
		if self:isFriend(fp) or table.contains(valid,fp:objectName()) then continue end
		if #valid==3 then break end
		table.insert(valid,fp:objectName())
	end
	if #valid>1 then
    	return string.format("@YinluCard=.->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_use["@@yinlu1"] = function(self,prompt)
	self.enemies = self:sort(self.enemies)
	self.friends = self:sort(self.friends)
	for _,p in sgs.list(self.enemies)do
		if __hc_value_call(p,"getMark","&yl_lequan")>0 or __hc_value_call(p,"getMark","&yl_huoxi")>0 then
			local valid = {p:objectName()}
			for _,t in sgs.list(self.friends)do
				table.insert(valid,t:objectName())
				return string.format("@YinluCard=.->%s",table.concat(valid,"+"))
			end
		end
	end
	for _,p in sgs.list(self.friends)do
		if __hc_value_call(p,"getMark","&yl_zhangqi")>0 then
			local valid = {p:objectName()}
			for _,t in sgs.list(self.enemies)do
				table.insert(valid,t:objectName())
				return string.format("@YinluCard=.->%s",table.concat(valid,"+"))
			end
		end
	end
end

sgs.ai_skill_cardask["yl_lequan0"] = function(self,data,pattern,prompt)
    if self:isWeak() or self:getOverflow()>=0
	then return true end
	return "."
end

sgs.ai_skill_cardask["yl_huoxi0"] = function(self,data,pattern,prompt)
    if self:canDraw() and self:getOverflow()>=0
	then return true end
	return "."
end

sgs.ai_skill_cardask["yl_zhangqi0"] = function(self,data,pattern,prompt)
    if self:isWeak() or self:getOverflow()>=0
	then return true end
	return "."
end

sgs.ai_skill_cardask["yl_yunxiang0"] = function(self,data,pattern,prompt)
    if self:isWeak() or self:getOverflow()>=0
	then return true end
	return "."
end

sgs.ai_skill_invoke.yl_yunxiang = function(self,data)
	return self:isWeak()
end

sgs.ai_skill_use["@@thshuliang"] = function(self,prompt)
	local ids = {}
	local tps,valid = {},{}
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if p:isKongcheng() then table.insert(tps,p) end
	end
	local n = #tps
	for i=0,n do
		local c,to = self:getCardNeedPlayer(nil,true,tps)
		if c and to then
			table.removeOne(tps,to)
			table.insert(valid,to:objectName())
			table.insert(ids,c:getLegacyStringKey())
		end
	end
	if #valid>0 then
    	return "@ThShuliangCard="..table.concat(ids,"+").."->"..table.concat(valid,"+")
	end
end

sgs.ai_skill_invoke.tanban = function(self,data)
	local n = 0
	for _,h in sgs.list(self.player:getHandcards())do
		if h:hasTip("tanban") then n = n+1 end
	end
	return __hc_value_call(self.player,"getHandcardNum")/2>n
end

sgs.ai_skill_cardask["diou0"] = function(self,data,pattern,prompt)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByUseValue(cards)
	for _,h in sgs.list(self.player:getHandcards())do
		if h:hasTip("tanban") then continue end
		if __hc_value_call(h,"isKindOf","BasicCard") or h:isNDTrick() then
			local dc = clone(self,h:objectName())
			dc = mutate(self,dc,"skill","_diou")
			local d = self:aiUseCard(dc)
			if d.card then
				self.diouUse = d
				self:writeDiouSavedPlan(d)
				return h:getLegacyStringKey()
			end
		end
	end
	return "."
end

sgs.ai_skill_use["@@diou"] = function(self,prompt)
	self.diouUse = self:readDiouSavedPlan()
	local tps = {}
	for _,p in sgs.list(self.diouUse.to)do
		table.insert(tps,p:objectName())
	end
   	return self.diouUse.card:getLegacyStringKey().."->"..table.concat(tps,"+")
end

sgs.ai_fill_skill["pinglu"]=function(self,inclusive,request)
	return policy(self,"@PingluCard=.")
end

sgs.ai_skill_use_func["PingluCard"] = function(card,use,self)
	for _,p in sgs.list(self.player:getAliveSiblings())do
		if __hc_value_call(p,"getHandcardNum")>0 and __hc_value_call(self.player,"inMyAttackRange",p)
		then use.card = card break end
	end
end

sgs.ai_use_value.PingluCard = 9.4
sgs.ai_use_priority.PingluCard = 4.8

sgs.ai_skill_invoke.feibai = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_invoke.zhengyue = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_use["@@zhengyue"] = function(self,prompt)
	local cs = {}
	for _,id in sgs.list(tag(self,"zhengyueForAI","IntList"))do
		table.insert(cs,visible(self,id))
	end
	cs = self:sortByUseValue(cs)
	local ids = {}
	for _,c in sgs.list(cs)do
		table.insert(ids,c:getLegacyStringKey())
	end
	return "@ZhengyueCard="..table.concat(ids,"+")
end

sgs.ai_skill_invoke.zhantao = function(self,data)
	local damage = data:toDamage()
	return damage.from and self:isEnemy(damage.from)
end

sgs.ai_skill_playerschosen.anjing = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
	local tos = {}
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then table.insert(tos,target) end
		if #tos>=x then break end
	end
	return tos
end

sgs.ai_skill_invoke.anjing = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_playerchosen.tg_wuyong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target) and self:damageIsEffective(target,nil,self.player)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target) and self:damageIsEffective(target,nil,self.player)
		then return target end
	end
	return destlist[#destlist]
end

sgs.ai_skill_playerchosen.tg_gangying = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and __hc_value_call(p,"isWounded")
		then return p end
	end
	return destlist[#destlist]
end

sgs.ai_skill_playerchosen.tg_guojue = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p)
		then return p end
	end
	return destlist[#destlist]
end

sgs.ai_skill_playerchosen.tg_renzhi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		and __hc_value_call(p,"getHandcardNum")<__hc_value_call(p,"getMaxHp")
		then return p end
	end
	return destlist[#destlist]
end

sgs.ai_fill_skill["wanchan"]=function(self,inclusive,request)
	return policy(self,"@WanchanCard=.")
end

sgs.ai_skill_use_func["WanchanCard"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself)
	for _,ep in sgs.list(self.friends_noself)do
		if self:canDraw(ep) then
			use.to:append(ep)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.WanchanCard = 9.4
sgs.ai_use_priority.WanchanCard = 4.8

sgs.ai_skill_invoke.jiangzhi = function(self,data)
	return true
end

sgs.ai_skill_playerchosen.jiangzhi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"he",true,2)
		then return p end
	end
	return destlist[#destlist]
end

sgs.ai_fill_skill["thwuyan"]=function(self,inclusive,request)
	return self:readCurrentSourceSlot("thwuyanHs")~=__hc_value_call(self.player,"getHandcardNum")
	and policy(self,"@ThWuyanCard=.")
end

sgs.ai_skill_use_func["ThWuyanCard"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself,nil,true)
	self.enemies = self:sort(self.enemies)
	for _,fp in sgs.list(self.friends_noself)do
		local cf = sgs.getDefense(fp)
		if not __hc_value_call(fp,"isMale") or self:readCurrentSourceSlot("thwuyanDp")==cf then continue end
		for _,ep in sgs.list(self.enemies)do
			if fp:canSlash(ep) then
				use.to:append(fp)
				use.to:append(ep)
				use.card = card
				self:writeCurrentSourceSlot("thwuyanDp",cf)
				self:writeCurrentSourceSlot("thwuyanHs",__hc_value_call(self.player,"getHandcardNum"))
				return
			end
		end
	end
end

sgs.ai_use_value.ThWuyanCard = 9.4
sgs.ai_use_priority.ThWuyanCard = 4.8

sgs.ai_skill_use["@@thwuyan"] = function(self,prompt)
	self.enemies = self:sort(self.enemies)
	self.friends_noself = self:sort(self.friends_noself,nil,true)
	for _,fp in sgs.list(self.friends_noself)do
		if not __hc_value_call(fp,"isMale") then continue end
		local valid = {fp:objectName()}
		for _,ep in sgs.list(self.enemies)do
			if fp:canSlash(ep) then
				table.insert(valid,ep:objectName())
				return string.format("@ThWuyanCard=.->%s",table.concat(valid,"+"))
			end
		end
	end
end

sgs.ai_skill_invoke.thwuyan = function(self,data)
	local tp = data:toPlayer()
	return not self:isFriend(tp)
end

sgs.ai_skill_cardask["zhanyu0"] = function(self,data,pattern,prompt)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByUseValue(cards)
	return cards[#cards]:getLegacyStringKey()
end

sgs.ai_fill_skill["thzhengui"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local ids = {}
  	for i,c in sgs.list(cards)do
		if table.contains(self:getPriorTurnUseCards(),c) then continue end
		table.insert(ids,c:getLegacyStringKey())
		if i>=#cards/2 or #ids>=__hc_value_call(self.player,"getMaxHp") then break end
	end
	if #ids>0 then
		return policy(self,"@ThZhenguiCard="..table.concat(ids,"+"))
	end
end

sgs.ai_skill_use_func["ThZhenguiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if not self:isWeak(ep) then
			use.to:append(ep)
			use.card = card
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		use.to:append(ep)
		use.card = card
		break
	end
end

sgs.ai_use_value.ThZhenguiCard = 9.4
sgs.ai_use_priority.ThZhenguiCard = 0.8

sgs.ai_fill_skill["jichun"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		if table.contains(self:getPriorTurnUseCards(),c) then continue end
		return policy(self,"@JichunCard="..c:getLegacyStringKey())
	end
end

sgs.ai_skill_use_func["JichunCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if __hc_value_call(p,"getHandcardNum")>__hc_value_call(self.player,"getHandcardNum")
		and __hc_value_call(self.player,"getMark","jichun2-PlayClear")<1 and self:doDisCard(p,"hej") then
			use.to:append(p)
			use.card = card
			return
		end
	end
	self.friends_noself = self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if __hc_value_call(p,"getHandcardNum")<__hc_value_call(self.player,"getHandcardNum")
		and __hc_value_call(self.player,"getMark","jichun1-PlayClear")<1 and self:canDraw(p) then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.JichunCard = 9.4
sgs.ai_use_priority.JichunCard = 4.8

sgs.ai_skill_invoke.hanying = function(self,data)
	return true
end

sgs.ai_skill_playerchosen.hanying = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
	local id = __hc_value_call(self.player,"getMark","hanyingId")
	local has = #self:poisonCards({id},p)>0
    for _,p in sgs.list(destlist)do
		if has then
			if self:isEnemy(p)
			then return p end
		else
			if self:isFriend(p)
			then return p end
		end
	end
    for _,p in sgs.list(destlist)do
		if has then
			if not self:isFriend(p)
			then return p end
		else
			if not self:isEnemy(p)
			then return p end
		end
	end
end

sgs.ai_skill_invoke.jianjiang = function(self,data)
	local damage = data:toDamage()
	if __hc_value_call(self.player,"getMark","jianjiang2-Clear")<1 and self:isWeak(damage.to)
	then return self:isEnemy(damage.to) end
	return __hc_value_call(self.player,"getMark","jianjiang1-Clear")<1
end

sgs.ai_skill_choice.jianjiang = function(self,choices,data)
	local items = choices:split("+")
	local damage = data:toDamage()
	if table.contains(items,"jianjiang2")
	and self:isWeak(damage.to) and self:isEnemy(damage.to)
	then return "jianjiang2" end
	if table.contains(items,"jianjiang1")
	then return "jianjiang1" end
end

sgs.ai_skill_invoke.thjueyan = function(self,data)
	return true
end

sgs.ai_fill_skill["yanzuo"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		if table.contains(self:getPriorTurnUseCards(),c) then continue end
		for i,id in sgs.list(RandomList(self.player:getPile("yanzuo")))do
			local ct = visible(self,id)
			if __hc_value_call(ct,"isKindOf","BasicCard") or ct:isNDTrick() then
				local dc = clone(self,ct:objectName())
				dc = mutate(self,dc,"skill","_yanzuo")
				local d = self:aiUseCard(dc)
				if d.card then
					self.yanzuoUse = d
					self:setStrategyMemory("choice_override:yanzuo",ct:objectName())
					return policy(self,"@YanzuoCard="..c:getLegacyStringKey())
				end
			end
		end
		break
	end
  	for i,c in sgs.list(cards)do
		if __hc_value_call(c,"isKindOf","BasicCard") or c:isNDTrick() then
			local dc = clone(self,c:objectName())
			dc = mutate(self,dc,"skill","_yanzuo")
			local d = self:aiUseCard(dc)
			if d.card then
				self.yanzuoUse = d
				self:setStrategyMemory("choice_override:yanzuo",c:objectName())
				return policy(self,"@YanzuoCard="..c:getLegacyStringKey())
			end
		end
	end
end

sgs.ai_skill_use_func["YanzuoCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.YanzuoCard = 9.4
sgs.ai_use_priority.YanzuoCard = 11.8

sgs.ai_skill_use["@@yanzuo!"] = function(self,prompt)
	local tps = {}
	for _,p in sgs.list(self.yanzuoUse.to)do
		table.insert(tps,p:objectName())
	end
   	return self.yanzuoUse.card:getLegacyStringKey().."->"..table.concat(tps,"+")
end

sgs.ai_skill_playerchosen.pijian = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p,nil,self.player)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and self:damageIsEffective(p,nil,self.player)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		then return p end
	end
	return destlist[#destlist]
end

sgs.ai_skill_invoke.thqixin = function(self,data)
	return self:canDraw()
end

sgs.ai_fill_skill["jiusi"]=function(self,inclusive,request)
  	for i,pn in sgs.list(source_patterns(self))do
		local dc = clone(self,pn)
		if dc and __hc_value_call(dc,"isKindOf","BasicCard") then
			dc = mutate(self,dc,"skill","jiusi")
			if __hc_value_call(dc,"isAvailable",self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					self:writeCurrentSourceTargets("jiusiTo",d.to)
					self:setPriorityValue("JiusiCard",sgs.ai_use_priority[__hc_value_call(dc,"getClassName")],"tenyear_hc")
					return policy(self,"@JiusiCard=.:"..pn)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["JiusiCard"] = function(card,use,self)
	if self:currentSourceTargetsPresent("jiusiTo") then
		use.to = self:readCurrentSourceTargets("jiusiTo")
		use.card = card
	end
end

sgs.ai_use_value.JiusiCard = 9.4
sgs.ai_use_priority.JiusiCard = 0.8

sgs.ai_guhuo_card.jiusi = function(self,toname,class_name)
	if self:getCardsNum(class_name)>0 then return end
	return "@JiusiCard=.:"..toname
end

sgs.ai_skill_invoke.chengyan = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_invoke.lianzhan = function(self,data)
	local use = data:toCardUse()
	self.lianzhanUse = use
	self:writeLianzhanSavedUse(use)
	return self:isEnemy(use.to:last())
end

sgs.ai_skill_playerchosen.lianzhan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:canCanmou(p,self:readLianzhanSavedUse())
		then return p end
	end
end

sgs.ai_fill_skill["manhou"]=function(self,inclusive,request)
	return policy(self,"@ManhouCard=.")
end

sgs.ai_skill_use_func["ManhouCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ManhouCard = 9.4
sgs.ai_use_priority.ManhouCard = 8.8

sgs.ai_skill_choice.manhou = function(self,choices,data)
	local items = choices:split("+")
	return items[#items]
end

sgs.ai_fill_skill["tanluan"]=function(self,inclusive,request)
	return policy(self,"@TanluanCard=.")
end

sgs.ai_skill_use_func["TanluanCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.TanluanCard = 9.4
sgs.ai_use_priority.TanluanCard = 0.8

sgs.ai_skill_use["@@tanluan"] = function(self,prompt)
	local cs = {}
	for _,id in sgs.list(tag(self,"tanluanForAI","IntList"))do
		table.insert(cs,notified_card(self,id))
	end
	cs = self:sortByUseValue(cs)
	for _,c in sgs.list(cs)do
		if __hc_value_call(c,"isAvailable",self.player) and __hc_value_call(c,"isDamageCard") then
			local d = self:aiUseCard(c)
			if d.card then
				local tps = {}
				for _,p in sgs.list(d.to)do
					table.insert(tps,p:objectName())
				end
				if __hc_value_call(c,"canRecast") and d.to:length()<1 then continue end
				return c:getLegacyStringKey().."->"..table.concat(tps,"+")
			end
		end
	end
	for _,c in sgs.list(cs)do
		if __hc_value_call(c,"isAvailable",self.player) then
			local d = self:aiUseCard(c)
			if d.card then
				local tps = {}
				for _,p in sgs.list(d.to)do
					table.insert(tps,p:objectName())
				end
				if __hc_value_call(c,"canRecast") and d.to:length()<1 then continue end
				return c:getLegacyStringKey().."->"..table.concat(tps,"+")
			end
		end
	end
end

sgs.ai_fill_skill["weiti"]=function(self,inclusive,request)
	return policy(self,"@WeitiCard=.")
end

sgs.ai_skill_use_func["WeitiCard"] = function(card,use,self)
	local destlist = sgs.QList2Table(self.room:getAlivePlayers()) -- 将列表转换为表
	destlist = self:sort(destlist,nil,true)
    for _,p in sgs.list(destlist)do
		use.card = card
		use.to:append(p)
		break;
	end
end

sgs.ai_use_value.WeitiCard = 9.4
sgs.ai_use_priority.WeitiCard = 2.8

sgs.ai_skill_invoke.yuanrong = function(self,data)
	return true
end

sgs.ai_skill_askforag.yuanrong = function(self,card_ids)
    self:writeCurrentSourceIds(card_ids)
	for _,id in sgs.list(card_ids)do
		local c = visible(self,id)
		local dc = clone(self,c:objectName())
		if dc and __hc_value_call(dc,"isAvailable",self.player) then
			local d = self:aiUseCard(dc)
			if d.card then return id end
		end
	end
end

sgs.ai_skill_use["@@yuanrong!"] = function(self,prompt)
	local ids = tag(self,"yuanrongForAI","IntList");
	for _,id in sgs.list(self:readCurrentSourceIds())do
		local c = visible(self,id)
		local dc = clone(self,c:objectName(),"yuanrong")
		for _,cid in sgs.list(ids)do
			dc = mutate(self,dc,"add",cid)
			if __hc_value_call(dc,"isAvailable",self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					local tps = {}
					for _,p in sgs.list(d.to)do
						table.insert(tps,p:objectName())
					end
					if not __hc_value_call(dc,"canRecast") or d.to:length()>0 then
						return dc:getLegacyStringKey().."->"..table.concat(tps,"+")
					end
				end
			end
			dc = mutate(self,dc,"clear")
		end
	end
end

sgs.ai_skill_invoke.boxuan = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_playerchosen.boxuan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"he")
		then return p end
	end
end

sgs.ai_skill_use["@@boxuan"] = function(self,prompt)
	for _,id in sgs.list(tag(self,"boxuanForAI","IntList"))do
		local c = notified_card(self,id)
		if __hc_value_call(c,"isAvailable",self.player) then
			local d = self:aiUseCard(c)
			if d.card then
				local tps = {}
				for _,p in sgs.list(d.to)do
					table.insert(tps,p:objectName())
				end
				if __hc_value_call(c,"canRecast") and d.to:length()<1 then continue end
				return c:getLegacyStringKey().."->"..table.concat(tps,"+")
			end
		end
	end
end

sgs.ai_skill_playerschosen.thyizheng = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and __hc_value_call(p,"getHandcardNum")>0 and #tps<x
		then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_playerchosen.thyizheng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:isFriend(p)
		then return p end
	end
end

sgs.ai_skill_use["@@guilin"] = function(self,prompt)
	if self:getCardsNum("Peach,Analeptic")<1 then
		return "@GuilinCard=."
	end
end

sgs.ai_skill_playerschosen.thguying = function(self,players,x)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x and self:isFriend(p)
		then table.insert(tps,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tps<x and not self:isEnemy(p)
		and not table.contains(tps,p)
		then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_fill_skill["thmuzhen"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local ids = {}
	local mt = ""
	for i,m in sgs.list(self.player:getMarkNames())do
		if m:contains("&thmuzhen+") then
			mt = m
			break
		end
	end
  	for i,c in sgs.list(cards)do
		if table.contains(self:getPriorTurnUseCards(),c) then continue end
		if mt~="" then
			table.insert(ids,c:getId())
			if mt:contains(c:getType()) or visible(self,ids[1]):getType()~=c:getType() then break end
			if #ids>=__hc_value_call(self.player,"getMark",mt) then
				return policy(self,"@ThMuzhenCard="..table.concat(ids,"+"))
			end
		else
			return policy(self,"@ThMuzhenCard="..c:getLegacyStringKey())
		end
	end
end

sgs.ai_skill_use_func["ThMuzhenCard"] = function(card,use,self)
	local destlist = sgs.QList2Table(self.room:getAlivePlayers()) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if p~=self.player then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.ThMuzhenCard = 9.4
sgs.ai_use_priority.ThMuzhenCard = 4.8

sgs.ai_skill_choice.thmuzhen = function(self,choices,data)
	local items = choices:split("+")
	local tp = data:toPlayer()
	if self:isFriend(tp)
	then return "3" end
end

sgs.ai_skill_invoke.chuanyu = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_use["@@chuanyu"] = function(self,prompt)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	for i=0,9 do
		local c,p = self:getCardNeedPlayer(cards,false)
		if c and p then
			if(__hc_value_call(c,"isAvailable",p) and __hc_value_call(c,"getTypeId")<3)then
				return "@ChuanyuCard="..c:getLegacyStringKey().."->"..p:objectName()
			end
			table.removeOne(cards,c)
			if(#cards<1)then break end
		end
	end
	for _,c in sgs.list(cards)do
		for _,p in sgs.list(self.friends_noself)do
			if(__hc_value_call(c,"isAvailable",p) and __hc_value_call(c,"getTypeId")<3)then
				return "@ChuanyuCard="..c:getLegacyStringKey().."->"..p:objectName()
			end
		end
		for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
			if(__hc_value_call(c,"isAvailable",p) and __hc_value_call(c,"getTypeId")<3)then
				return "@ChuanyuCard="..c:getLegacyStringKey().."->"..p:objectName()
			end
		end
	end
	for _,c in sgs.list(cards)do
		for _,p in sgs.list(self.friends_noself)do
			return "@ChuanyuCard="..c:getLegacyStringKey().."->"..p:objectName()
		end
		for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
			return "@ChuanyuCard="..c:getLegacyStringKey().."->"..p:objectName()
		end
	end
end

sgs.ai_skill_playerchosen.chuanyu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,nil,true)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
	return destlist[1]
end

sgs.ai_skill_use["@@chuanyu1"] = function(self,prompt)
	self.enemies = self:sort(self.enemies)
	for _,ep in sgs.list(self.enemies)do
		local tps = {ep:objectName()}
		for _,p in sgs.list(self.room:getOtherPlayers(ep))do
			if(__hc_value_call(p,"getMark","chuanyuBf_lun")>0 and p:canSlash(p,false))then
				table.insert(tps,p:objectName())
			end
		end
		if #tps>1 then
			return "@ChuanyuCard=.:@@chuanyu1->"..table.concat(tps,"+")
		end
	end
end

sgs.ai_skill_invoke.yitou = function(self,data)
	local tp = data:toPlayer()
	return self:isFriend(tp) and #self.enemies>0
end

sgs.ai_skill_invoke.gengdu = function(self,data)
	return self:canDraw()
end

sgs.ai_fill_skill["gengdu"]=function(self,inclusive,request)
  	for i,c in sgs.list(self.player:getCards("he"))do
		if table.contains(self:getPriorTurnUseCards(),c) or not c:isRed() then continue end
		return policy(self,"@GengduCard=.")
	end
end

sgs.ai_skill_use_func["GengduCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.GengduCard = 9.4
sgs.ai_use_priority.GengduCard = 2.8

sgs.ai_skill_askforag.gengdu = function(self,card_ids)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	for _,id in sgs.list(card_ids)do
		local c = known(self:getChoiceCard(id),"gengdu offered source face")
		if not __hc_value_call(c,"isDamageCard") then continue end
		local dc = clone(self,c:objectName(),"gengdu")
		for i,h in sgs.list(cards)do
			if table.contains(self:getPriorTurnUseCards(),h) or not h:isRed() then continue end
			dc = mutate(self,dc,"add",h)
			if __hc_value_call(dc,"isAvailable",self.player) then
				local d = self:aiUseCard(dc)
				self.gengduUse = d
				self:writeGengduSavedPlan(d)
				if d.card then return id end
			end
			dc = mutate(self,dc,"clear")
		end
	end
	for _,id in sgs.list(card_ids)do
		local c = known(self:getChoiceCard(id),"gengdu offered source face")
		local dc = clone(self,c:objectName(),"gengdu")
		for i,h in sgs.list(cards)do
			if table.contains(self:getPriorTurnUseCards(),h) or not h:isRed() then continue end
			dc = mutate(self,dc,"add",h)
			if __hc_value_call(dc,"isAvailable",self.player) then
				local d = self:aiUseCard(dc)
				self.gengduUse = d
				self:writeGengduSavedPlan(d)
				if d.card then return id end
			end
			dc = mutate(self,dc,"clear")
		end
	end
end

sgs.ai_skill_use["@@gengdu"] = function(self,prompt)
	self.gengduUse = self:readGengduSavedPlan()
	local d = self.gengduUse
	if d.card then
		local tps = {}
		for _,p in sgs.list(d.to)do
			table.insert(tps,p:objectName())
		end
		return d.card:getLegacyStringKey().."->"..table.concat(tps,"+")
	end
end

sgs.ai_skill_invoke.gumai = function(self,data)
	local damage = data:toDamage()
	return self:isFriend(damage.to) or self:isEnemy(damage.to) and self:isWeak(damage.to)
end

sgs.ai_skill_choice.gumai = function(self,choices,data)
	local items = choices:split("+")
	local damage = data:toDamage()
	if self:isFriend(damage.to)
	then return "2" end
	return "1"
end

sgs.ai_skill_cardask["gumai0"] = function(self,data,pattern,prompt)
	return __hc_value_call(self.player,"getHandcardNum")>1
end

sgs.ai_skill_invoke.pigua = function(self,data)
	local tp = data:toPlayer()
	return not self:isFriend(tp)
end

sgs.ai_skill_use["@@jikun"] = function(self,prompt)
	local n = 0
	local destlist = sgs.QList2Table(self.room:getAlivePlayers()) -- 将列表转换为表
	for _,p in sgs.list(destlist)do
		n = math.max(n,__hc_value_call(p,"getHandcardNum"))
	end
	destlist = self:sort(destlist)
	self.friends_noself = self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if not self:canDraw(p) then continue end
		local tps = {p:objectName()}
		for _,q in sgs.list(self.enemies)do
			if(__hc_value_call(q,"getHandcardNum")>=n)then
				table.insert(tps,q:objectName())
				return "@JikunCard=.->"..table.concat(tps,"+")
			end
		end
		for _,q in sgs.list(destlist)do
			if(__hc_value_call(q,"getHandcardNum")>=n and not self:isFriend(q))then
				table.insert(tps,q:objectName())
				return "@JikunCard=.->"..table.concat(tps,"+")
			end
		end
		for _,q in sgs.list(destlist)do
			if(__hc_value_call(q,"getHandcardNum")>=n and q~=p)then
				table.insert(tps,q:objectName())
				return "@JikunCard=.->"..table.concat(tps,"+")
			end
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		local tps = {p:objectName()}
		for _,q in sgs.list(self.enemies)do
			if(__hc_value_call(q,"getHandcardNum")>=n)then
				table.insert(tps,q:objectName())
				return "@JikunCard=.->"..table.concat(tps,"+")
			end
		end
		for _,q in sgs.list(destlist)do
			if(__hc_value_call(q,"getHandcardNum")>=n and not self:isFriend(q))then
				table.insert(tps,q:objectName())
				return "@JikunCard=.->"..table.concat(tps,"+")
			end
		end
		for _,q in sgs.list(destlist)do
			if(__hc_value_call(q,"getHandcardNum")>=n and q~=p)then
				table.insert(tps,q:objectName())
				return "@JikunCard=.->"..table.concat(tps,"+")
			end
		end
	end
end

sgs.ai_skill_invoke.dujun = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_playerchosen.dujun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		and self:isWeak(p) and __hc_value_call(p,"getHp")<__hc_value_call(self.player,"getHp")
		then return p end
	end
end

sgs.ai_fill_skill["jieshi"]=function(self,inclusive,request)
	return policy(self,"@JieshiCard=.")
end

sgs.ai_skill_use_func["JieshiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.JieshiCard = 9.4
sgs.ai_use_priority.JieshiCard = 7.8

sgs.ai_skill_discard.jieshi = function(self,m,x)
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    handcards = self:sortByKeepValue(handcards)
	local cards = {}
	for _,h in sgs.list(handcards)do
		table.insert(cards,h:getId())
		if #cards>=x then return cards end
		if #cards>=#handcards/2 then break end
	end
	return {}
end

sgs.ai_skill_invoke.zhidui = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_choice.zhidui = function(self,choices,data)
	local items = choices:split("+")
	local use = data:toCardUse()
	if __hc_value_call(use.card,"isKindOf","BasicCard")
	and not __hc_value_call(use.card,"isAvailable",use.from)
	then return "zhidui2" end
	return "zhidui1"
end

sgs.ai_fill_skill["bizu"]=function(self,inclusive,request)
	return policy(self,"@BizuCard=.")
end

sgs.ai_skill_use_func["BizuCard"] = function(card,use,self)
	local n = 0
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if __hc_value_call(self.player,"getHandcardNum")~=__hc_value_call(p,"getHandcardNum") then continue end
		if self:isFriend(p) then n = n+1 else n = n-1 end
	end
	if n>0 then
		use.card = card
	end
end

sgs.ai_use_value.BizuCard = 9.4
sgs.ai_use_priority.BizuCard = 7.8

sgs.ai_skill_playerchosen.wuxie = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,nil,true)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and __hc_value_call(p,"getHandcardNum")>=__hc_value_call(self.player,"getHandcardNum")
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and __hc_value_call(p,"getHandcardNum")>=__hc_value_call(self.player,"getHandcardNum")
		then return p end
	end
end

sgs.ai_skill_invoke.shuhe = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_choice.shuhe = function(self,choices,data)
	local items = choices:split("+")
	local tp = data:toPlayer()
	if self:isEnemy(tp)
	then return "shuhe1" end
	return "shuhe2"
end

sgs.ai_fill_skill["jilie"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local ids = {}
  	for i,c in sgs.list(cards)do
		if table.contains(self:getPriorTurnUseCards(),c) then continue end
		table.insert(ids,c:getId())
		if #ids>=__hc_value_call(self.player,"getHp") and self:aiUseCard(clone(self)).card then
			return policy(self,"@JilieCard="..table.concat(ids,"+"))
		end
	end
end

sgs.ai_skill_use_func["JilieCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.JilieCard = 9.4
sgs.ai_use_priority.JilieCard = 2.8

sgs.ai_skill_use["@@jilie"] = function(self,prompt)
	local dc = clone(self,property(self,"jilieCn"),"_jilie")
	local d = self:aiUseCard(dc)
	if d.card then
		local tps = {}
		for _,p in sgs.qlist(d.to)do
			table.insert(tps,p:objectName())
		end
		return dc:getLegacyStringKey().."->"..table.concat(tps,"+")
	end
end

sgs.ai_skill_playerchosen.qingleng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"he")
		then return p end
	end
end

sgs.ai_skill_invoke.qingleng = function(self,data)
	local cn = data:toString():split(":")[2]
	return self:aiUseCard(clone(self,cn)).card
end

sgs.ai_skill_discard.dandu = function(self,m,x)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    handcards = self:sortByUseValue(handcards)
	local cards = {}
	for _,h in sgs.list(handcards)do
		if __hc_value_call(h,"isKindOf","BasicCard") or h:isNDTrick() then
			local dc = clone(self,h:objectName(),"_dandu")
			if self:aiUseCard(dc).card then
				table.insert(cards,h:getId())
				if #cards>=x then return cards end
			end
		end
	end
	return {}
end

sgs.ai_skill_use["@@quxian"] = function(self,prompt)
	self.enemies = self:sort(self.enemies)
	for _,ep in sgs.list(self.enemies)do
		local n = 0
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if p:canSlash(ep) then
				if self:isFriend(p) and getCardsNum("Slash",p,self.player)>0 then
					n = n+1
				else
					n = n-1
				end
			end
		end
		if n>0 then
			return "@QuxianCard=.->"..ep:objectName()
		end
	end
end

sgs.ai_skill_cardask["huachang0"] = function(self,data,pattern,prompt)
	return self:getOverflow()>=0
end

sgs.ai_skill_cardask["yuzhi0"] = function(self,data,pattern,prompt)
	return self:getCardsNum("Jink")<1
end

sgs.ai_fill_skill["zuoyi"]=function(self,inclusive,request)
	return policy(self,"@ZuoyiCard=.")
end

sgs.ai_skill_use_func["ZuoyiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ZuoyiCard = 9.4
sgs.ai_use_priority.ZuoyiCard = 7.8

sgs.ai_skill_choice.zuoyi = function(self,choices,data)
	local items = choices:split("+")
	return items[1]
end

sgs.ai_skill_playerchosen.zuoyi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
	if tag(self,"zuoyi","String")=="zuoyi1" then
		for _,p in sgs.list(destlist)do
			if self:doDisCard(p,"he")
			then return p end
		end
	else
		for _,p in sgs.list(destlist)do
			if self:isFriend(p) and self:canDraw(p)
			then return p end
		end
		for _,p in sgs.list(destlist)do
			if not self:isEnemy(p)
			then return p end
		end
	end
end

sgs.ai_skill_invoke.yanxi = function(self,data)
	local tp = data:toPlayer()
	return self:isEnemy(tp) and self:slashIsEffective(clone(self),tp,self.player)
end

sgs.ai_skill_discard.yuxian = function(self,m,x)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    cards = self:sortByKeepValue(cards)
	local ids = {}
	for _,h in sgs.list(cards)do
		table.insert(ids,h:getId())
		if #ids>=m then break end
	end
	return ids
end

sgs.ai_skill_invoke.yuxian = function(self,data)
	local tp = data:toPlayer()
	return not self:isEnemy(tp) and self:canDraw()
end

sgs.ai_skill_playerchosen.minshan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
	for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
	for _,p in sgs.list(destlist)do
		if not self:isEnemy(p) and self:isWeak()
		then return p end
	end
end

sgs.ai_skill_invoke.fuhui = function(self,data)
	return self:canDraw()
end

sgs.ai_fill_skill["fuhui"]=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	local ids = {}
  	for i,c in sgs.list(cards)do
		if table.contains(self:getPriorTurnUseCards(),c) then continue end
		table.insert(ids,c:getId())
		if #ids>=2 then break end
	end
	if #ids<2 then return end
	for i,cn in sgs.list(source_patterns(self))do
		if __hc_value_call(self.player,"getMark","fuhui_guhuo_remove_"..cn.."-Clear")>0 then continue end
		local dc = clone(self,cn,"fuhui")
		if __hc_value_call(dc,"isKindOf","BasicCard") or dc:isNDTrick() then
			dc = mutate(self,dc,"add",ids[1])
			dc = mutate(self,dc,"add",ids[2])
			dc = mutate(self,dc,"can_recast",false)
			if __hc_value_call(dc,"isAvailable",self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					self:writeCurrentSourceTargets("fuhui_to",d.to)
					self:setPriorityValue("FuhuiCard",sgs.ai_use_priority[__hc_value_call(dc,"getClassName")],"tenyear_hc")
					return policy(self,"@FuhuiCard="..table.concat(ids,"+")..":"..cn)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["FuhuiCard"] = function(card,use,self)
	use.card = card
	use.to = self:readCurrentSourceTargets("fuhui_to")
end

sgs.ai_use_value.FuhuiCard = 9.4
sgs.ai_use_priority.FuhuiCard = 2.8

function sgs.ai_cardsview.fuhui(self,class_name,player)
   	local cn = source_patterns(self,class_name)
	if __hc_value_call(player,"getMark","fuhui_guhuo_remove_"..cn.."-Clear")>0 then return end
	local cards = sgs.QList2Table(player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	local ids = {}
	for _,c in sgs.list(cards)do
		table.insert(ids,c:getId())
       	if #ids>1 then
	   		return "@FuhuiCard="..table.concat(ids,"+")..":"..cn
	   	end
	end
end



local function wrap(f,key,kind)
 return function(...)
  local args=table.pack(...);local self
  for i=1,args.n do local v=args[i];if type(v)=="table"and v.player and v.world and v.request then self=v;break end end
  if not self then return f(...)end
  local outer=not self._hc_callback_depth;local previous=self._hc_callback_key
  if outer and (key=="@@chuiti"or key=="@@boxuan"or key=="@@tanluan")then notified_cards[self]=nil end
  self._hc_callback_depth=(self._hc_callback_depth or 0)+1;self._hc_callback_key=key
  if outer then load_state(self)end
  local result=table.pack(pcall(f,table.unpack(args,1,args.n)))
  local saved=outer and table.pack(pcall(save_state,self))or{true}
  self._hc_callback_depth=self._hc_callback_depth-1;if self._hc_callback_depth==0 then self._hc_callback_depth=nil end;self._hc_callback_key=previous
  if not result[1]then error(result[2],0)end
  if not saved[1]then error(saved[2],0)end
  if outer and kind=="ai_skill_use_func"and args[2]and args[2].card and recipes[args[2].card]and not recipes[args[2].card].prototype then
   local c=args[2].card;local row=copy(recipes[c]);row.source_key=nil;local mapped=self:evaluateTurnConversion(row.skill,c:getClassName(),row,nil);self:inheritLegacyCardIdentity(mapped,c);args[2].card=mapped
  elseif outer and kind=="ai_skill_use"then result[2]=response(self,result[2])
  elseif outer and(kind=="ai_cardsview"or kind=="ai_cardsview_valuable"or kind=="ai_guhuo_card")then result[2]=proposal(result[2])
  elseif outer and kind=="ai_fill_skill"and key=="tenyearlingyin"and type(result[2])=="table"and not AIValue.isCard(result[2])and not AIValue.isConversion(result[2])then
   -- Fixed source returns ordered independent hypotheses, not one card.
   for i,c in ipairs(result[2])do
    local row=recipes[c]
    if not row or row.prototype then ai_unsupported("untracked TenyearLingyin fill hypothesis",key)end
    row=copy(row);row.source_key=nil
    local mapped=self:evaluateTurnConversion(row.skill,c:getClassName(),row,args[3]);self:inheritLegacyCardIdentity(mapped,c);result[2][i]=mapped
   end
  elseif outer and kind=="ai_fill_skill"and result[2]and recipes[result[2]]and not recipes[result[2]].prototype then
   local c=result[2];local row=copy(recipes[c]);row.source_key=nil
   local mapped=self:evaluateTurnConversion(row.skill,c:getClassName(),row,args[3]);self:inheritLegacyCardIdentity(mapped,c);result[2]=mapped
  end
  return table.unpack(result,2,result.n)
 end
end
sgs.ai_skill_invoke['yiyong']=wrap(sgs.ai_skill_invoke['yiyong'],'yiyong','ai_skill_invoke')
sgs.ai_skill_cardask['@cuijin-discard']=wrap(sgs.ai_skill_cardask['@cuijin-discard'],'@cuijin-discard','ai_skill_cardask')
sgs.ai_skill_use['@@jueman!']=wrap(sgs.ai_skill_use['@@jueman!'],'@@jueman!','ai_skill_use')
sgs.ai_fill_skill['xiaosi']=wrap(sgs.ai_fill_skill['xiaosi'],'xiaosi','ai_fill_skill')
sgs.ai_skill_use_func['XiaosiCard']=wrap(sgs.ai_skill_use_func['XiaosiCard'],'XiaosiCard','ai_skill_use_func')
sgs.ai_skill_discard['xiaosi']=wrap(sgs.ai_skill_discard['xiaosi'],'xiaosi','ai_skill_discard')
sgs.ai_skill_use['@@xiaosi']=wrap(sgs.ai_skill_use['@@xiaosi'],'@@xiaosi','ai_skill_use')
sgs.ai_skill_invoke['tenyearqingren']=wrap(sgs.ai_skill_invoke['tenyearqingren'],'tenyearqingren','ai_skill_invoke')
sgs.ai_skill_use['@@xinggu']=wrap(sgs.ai_skill_use['@@xinggu'],'@@xinggu','ai_skill_use')
sgs.ai_skill_invoke['hongji']=wrap(sgs.ai_skill_invoke['hongji'],'hongji','ai_skill_invoke')
sgs.ai_skill_invoke['daili']=wrap(sgs.ai_skill_invoke['daili'],'daili','ai_skill_invoke')
sgs.ai_skill_invoke['pitian']=wrap(sgs.ai_skill_invoke['pitian'],'pitian','ai_skill_invoke')
sgs.ai_fill_skill['qiangzhizh']=wrap(sgs.ai_fill_skill['qiangzhizh'],'qiangzhizh','ai_fill_skill')
sgs.ai_skill_use_func['QiangzhiZHCard']=wrap(sgs.ai_skill_use_func['QiangzhiZHCard'],'QiangzhiZHCard','ai_skill_use_func')
sgs.ai_skill_askforyiji['libang']=wrap(sgs.ai_skill_askforyiji['libang'],'libang','ai_skill_askforyiji')
sgs.ai_skill_use['@@libang']=wrap(sgs.ai_skill_use['@@libang'],'@@libang','ai_skill_use')
sgs.ai_fill_skill['libang']=wrap(sgs.ai_fill_skill['libang'],'libang','ai_fill_skill')
sgs.ai_skill_use_func['LibangCard']=wrap(sgs.ai_skill_use_func['LibangCard'],'LibangCard','ai_skill_use_func')
sgs.ai_skill_invoke['huayi']=wrap(sgs.ai_skill_invoke['huayi'],'huayi','ai_skill_invoke')
sgs.ai_fill_skill['caizhuang']=wrap(sgs.ai_fill_skill['caizhuang'],'caizhuang','ai_fill_skill')
sgs.ai_skill_use_func['CaizhuangCard']=wrap(sgs.ai_skill_use_func['CaizhuangCard'],'CaizhuangCard','ai_skill_use_func')
sgs.ai_fill_skill['jijiao']=wrap(sgs.ai_fill_skill['jijiao'],'jijiao','ai_fill_skill')
sgs.ai_skill_use_func['JijiaoCard']=wrap(sgs.ai_skill_use_func['JijiaoCard'],'JijiaoCard','ai_skill_use_func')
sgs.ai_skill_discard['huizhi']=wrap(sgs.ai_skill_discard['huizhi'],'huizhi','ai_skill_discard')
sgs.ai_skill_choice['yuanmo']=wrap(sgs.ai_skill_choice['yuanmo'],'yuanmo','ai_skill_choice')
sgs.ai_skill_use['@@jianjiyh']=wrap(sgs.ai_skill_use['@@jianjiyh'],'@@jianjiyh','ai_skill_use')
sgs.ai_fill_skill['jianjiyh']=wrap(sgs.ai_fill_skill['jianjiyh'],'jianjiyh','ai_fill_skill')
sgs.ai_skill_use_func['JianjiYHCard']=wrap(sgs.ai_skill_use_func['JianjiYHCard'],'JianjiYHCard','ai_skill_use_func')
sgs.ai_skill_choice['xiangshuzk']=wrap(sgs.ai_skill_choice['xiangshuzk'],'xiangshuzk','ai_skill_choice')
sgs.ai_skill_askforag['fozong']=wrap(sgs.ai_skill_askforag['fozong'],'fozong','ai_skill_askforag')
sgs.ai_skill_playerchosen['cansi']=wrap(sgs.ai_skill_playerchosen['cansi'],'cansi','ai_skill_playerchosen')
sgs.ai_skill_use['@@saowei']=wrap(sgs.ai_skill_use['@@saowei'],'@@saowei','ai_skill_use')
sgs.ai_skill_invoke['aishou']=wrap(sgs.ai_skill_invoke['aishou'],'aishou','ai_skill_invoke')
sgs.ai_skill_discard['jinjin']=wrap(sgs.ai_skill_discard['jinjin'],'jinjin','ai_skill_discard')
sgs.ai_skill_invoke['jinjin']=wrap(sgs.ai_skill_invoke['jinjin'],'jinjin','ai_skill_invoke')
sgs.ai_skill_discard['haochong']=wrap(sgs.ai_skill_discard['haochong'],'haochong','ai_skill_discard')
sgs.ai_skill_invoke['haochong']=wrap(sgs.ai_skill_invoke['haochong'],'haochong','ai_skill_invoke')
sgs.ai_fill_skill['tenyearlingyin']=wrap(sgs.ai_fill_skill['tenyearlingyin'],'tenyearlingyin','ai_fill_skill')
sgs.ai_skill_use['@@tenyearlingyin']=wrap(sgs.ai_skill_use['@@tenyearlingyin'],'@@tenyearlingyin','ai_skill_use')
sgs.ai_skill_playerchosen['tenyearliying']=wrap(sgs.ai_skill_playerchosen['tenyearliying'],'tenyearliying','ai_skill_playerchosen')
sgs.ai_skill_invoke['tenyearwangyuan']=wrap(sgs.ai_skill_invoke['tenyearwangyuan'],'tenyearwangyuan','ai_skill_invoke')
sgs.ai_fill_skill['jinjianhe']=wrap(sgs.ai_fill_skill['jinjianhe'],'jinjianhe','ai_fill_skill')
sgs.ai_skill_use_func['JinJianheCard']=wrap(sgs.ai_skill_use_func['JinJianheCard'],'JinJianheCard','ai_skill_use_func')
sgs.ai_use_revises['jinbihun']=wrap(sgs.ai_use_revises['jinbihun'],'jinbihun','ai_use_revises')
sgs.ai_skill_cardchosen['tenyearluochong']=wrap(sgs.ai_skill_cardchosen['tenyearluochong'],'tenyearluochong','ai_skill_cardchosen')
sgs.ai_skill_playerchosen['tenyearluochong']=wrap(sgs.ai_skill_playerchosen['tenyearluochong'],'tenyearluochong','ai_skill_playerchosen')
sgs.ai_skill_discard['tenyearjinjie']=wrap(sgs.ai_skill_discard['tenyearjinjie'],'tenyearjinjie','ai_skill_discard')
sgs.ai_skill_invoke['tenyearsigong']=wrap(sgs.ai_skill_invoke['tenyearsigong'],'tenyearsigong','ai_skill_invoke')
sgs.ai_guhuo_card['tenyeargue']=wrap(sgs.ai_guhuo_card['tenyeargue'],'tenyeargue','ai_guhuo_card')
sgs.ai_skill_playerschosen['tenyearyuguan']=wrap(sgs.ai_skill_playerschosen['tenyearyuguan'],'tenyearyuguan','ai_skill_playerschosen')
sgs.ai_skill_invoke['tenyearyuguan']=wrap(sgs.ai_skill_invoke['tenyearyuguan'],'tenyearyuguan','ai_skill_invoke')
sgs.ai_skill_playerchosen['tenyearxuewei']=wrap(sgs.ai_skill_playerchosen['tenyearxuewei'],'tenyearxuewei','ai_skill_playerchosen')
sgs.ai_fill_skill['xiangmian']=wrap(sgs.ai_fill_skill['xiangmian'],'xiangmian','ai_fill_skill')
sgs.ai_skill_use_func['XiangmianCard']=wrap(sgs.ai_skill_use_func['XiangmianCard'],'XiangmianCard','ai_skill_use_func')
sgs.ai_skill_use['@@tenyearjue']=wrap(sgs.ai_skill_use['@@tenyearjue'],'@@tenyearjue','ai_skill_use')
sgs.ai_skill_invoke['tenyearjinjie']=wrap(sgs.ai_skill_invoke['tenyearjinjie'],'tenyearjinjie','ai_skill_invoke')
sgs.ai_skill_use['@@tenyearzhaohan!']=wrap(sgs.ai_skill_use['@@tenyearzhaohan!'],'@@tenyearzhaohan!','ai_skill_use')
sgs.ai_skill_choice['tenyearzhaohan']=wrap(sgs.ai_skill_choice['tenyearzhaohan'],'tenyearzhaohan','ai_skill_choice')
sgs.ai_skill_invoke['tenyearzhaohan']=wrap(sgs.ai_skill_invoke['tenyearzhaohan'],'tenyearzhaohan','ai_skill_invoke')
sgs.ai_skill_choice['juying']=wrap(sgs.ai_skill_choice['juying'],'juying','ai_skill_choice')
sgs.ai_skill_playerchosen['anzhi']=wrap(sgs.ai_skill_playerchosen['anzhi'],'anzhi','ai_skill_playerchosen')
sgs.ai_fill_skill['anzhi']=wrap(sgs.ai_fill_skill['anzhi'],'anzhi','ai_fill_skill')
sgs.ai_skill_use_func['AnzhiCard']=wrap(sgs.ai_skill_use_func['AnzhiCard'],'AnzhiCard','ai_skill_use_func')
sgs.ai_skill_invoke['anzhi']=wrap(sgs.ai_skill_invoke['anzhi'],'anzhi','ai_skill_invoke')
sgs.ai_skill_invoke['xialei']=wrap(sgs.ai_skill_invoke['xialei'],'xialei','ai_skill_invoke')
sgs.ai_skill_playerchosen['zhanmeng']=wrap(sgs.ai_skill_playerchosen['zhanmeng'],'zhanmeng','ai_skill_playerchosen')
sgs.ai_skill_choice['zhanmeng']=wrap(sgs.ai_skill_choice['zhanmeng'],'zhanmeng','ai_skill_choice')
sgs.ai_skill_playerchosen['wumei']=wrap(sgs.ai_skill_playerchosen['wumei'],'wumei','ai_skill_playerchosen')
sgs.ai_skill_playerschosen['tingxian']=wrap(sgs.ai_skill_playerschosen['tingxian'],'tingxian','ai_skill_playerschosen')
sgs.ai_skill_invoke['tingxian']=wrap(sgs.ai_skill_invoke['tingxian'],'tingxian','ai_skill_invoke')
sgs.ai_target_revises['enyu']=wrap(sgs.ai_target_revises['enyu'],'enyu','ai_target_revises')
sgs.ai_fill_skill['jingzao']=wrap(sgs.ai_fill_skill['jingzao'],'jingzao','ai_fill_skill')
sgs.ai_skill_use_func['JingzaoCard']=wrap(sgs.ai_skill_use_func['JingzaoCard'],'JingzaoCard','ai_skill_use_func')
sgs.ai_guhuo_card['fengying']=wrap(sgs.ai_guhuo_card['fengying'],'fengying','ai_guhuo_card')
sgs.ai_fill_skill['fengying']=wrap(sgs.ai_fill_skill['fengying'],'fengying','ai_fill_skill')
sgs.ai_skill_use_func['FengyingCard']=wrap(sgs.ai_skill_use_func['FengyingCard'],'FengyingCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['lianzhi_shouze']=wrap(sgs.ai_skill_playerchosen['lianzhi_shouze'],'lianzhi_shouze','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['lianzhi']=wrap(sgs.ai_skill_playerchosen['lianzhi'],'lianzhi','ai_skill_playerchosen')
sgs.ai_skill_choice['zuojian']=wrap(sgs.ai_skill_choice['zuojian'],'zuojian','ai_skill_choice')
sgs.ai_skill_invoke['zhengxu']=wrap(sgs.ai_skill_invoke['zhengxu'],'zhengxu','ai_skill_invoke')
sgs.ai_fill_skill['cuichuan']=wrap(sgs.ai_fill_skill['cuichuan'],'cuichuan','ai_fill_skill')
sgs.ai_skill_use_func['CuichuanCard']=wrap(sgs.ai_skill_use_func['CuichuanCard'],'CuichuanCard','ai_skill_use_func')
sgs.ai_fill_skill['kanji']=wrap(sgs.ai_fill_skill['kanji'],'kanji','ai_fill_skill')
sgs.ai_skill_use_func['KanjiCard']=wrap(sgs.ai_skill_use_func['KanjiCard'],'KanjiCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['silve']=wrap(sgs.ai_skill_playerchosen['silve'],'silve','ai_skill_playerchosen')
sgs.ai_skill_invoke['silve']=wrap(sgs.ai_skill_invoke['silve'],'silve','ai_skill_invoke')
sgs.ai_fill_skill['shuaijie']=wrap(sgs.ai_fill_skill['shuaijie'],'shuaijie','ai_fill_skill')
sgs.ai_skill_use_func['ShuaijieCard']=wrap(sgs.ai_skill_use_func['ShuaijieCard'],'ShuaijieCard','ai_skill_use_func')
sgs.ai_skill_invoke['tenyearfuning']=wrap(sgs.ai_skill_invoke['tenyearfuning'],'tenyearfuning','ai_skill_invoke')
sgs.ai_fill_skill['tenyearbingji']=wrap(sgs.ai_fill_skill['tenyearbingji'],'tenyearbingji','ai_fill_skill')
sgs.ai_skill_use_func['TenyearBingjiCard']=wrap(sgs.ai_skill_use_func['TenyearBingjiCard'],'TenyearBingjiCard','ai_skill_use_func')
sgs.ai_skill_use['@@tenyearbingji!']=wrap(sgs.ai_skill_use['@@tenyearbingji!'],'@@tenyearbingji!','ai_skill_use')
sgs.ai_skill_playerchosen['tenyearbingji']=wrap(sgs.ai_skill_playerchosen['tenyearbingji'],'tenyearbingji','ai_skill_playerchosen')
sgs.ai_skill_invoke['qianlong']=wrap(sgs.ai_skill_invoke['qianlong'],'qianlong','ai_skill_invoke')
sgs.ai_skill_use['@@qianlong']=wrap(sgs.ai_skill_use['@@qianlong'],'@@qianlong','ai_skill_use')
sgs.ai_skill_playerchosen['fensi']=wrap(sgs.ai_skill_playerchosen['fensi'],'fensi','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['juetao']=wrap(sgs.ai_skill_playerchosen['juetao'],'juetao','ai_skill_playerchosen')
sgs.ai_skill_use['@@juetao!']=wrap(sgs.ai_skill_use['@@juetao!'],'@@juetao!','ai_skill_use')
sgs.ai_skill_playerschosen['zhushi']=wrap(sgs.ai_skill_playerschosen['zhushi'],'zhushi','ai_skill_playerschosen')
sgs.ai_fill_skill['xiaowu']=wrap(sgs.ai_fill_skill['xiaowu'],'xiaowu','ai_fill_skill')
sgs.ai_skill_use_func['XiaowuCard']=wrap(sgs.ai_skill_use_func['XiaowuCard'],'XiaowuCard','ai_skill_use_func')
sgs.ai_skill_choice['xiaowu']=wrap(sgs.ai_skill_choice['xiaowu'],'xiaowu','ai_skill_choice')
sgs.ai_skill_playerchosen['xiaowu']=wrap(sgs.ai_skill_playerchosen['xiaowu'],'xiaowu','ai_skill_playerchosen')
sgs.ai_skill_invoke['huaping']=wrap(sgs.ai_skill_invoke['huaping'],'huaping','ai_skill_invoke')
sgs.ai_skill_playerchosen['huaping']=wrap(sgs.ai_skill_playerchosen['huaping'],'huaping','ai_skill_playerchosen')
sgs.ai_skill_use['@@shawu']=wrap(sgs.ai_skill_use['@@shawu'],'@@shawu','ai_skill_use')
sgs.ai_skill_playerchosen['tenyearxizhen']=wrap(sgs.ai_skill_playerchosen['tenyearxizhen'],'tenyearxizhen','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['luochong']=wrap(sgs.ai_skill_playerchosen['luochong'],'luochong','ai_skill_playerchosen')
sgs.ai_skill_choice['luochong']=wrap(sgs.ai_skill_choice['luochong'],'luochong','ai_skill_choice')
sgs.ai_skill_choice['aicheng']=wrap(sgs.ai_skill_choice['aicheng'],'aicheng','ai_skill_choice')
sgs.ai_skill_playerschosen['tongxie']=wrap(sgs.ai_skill_playerschosen['tongxie'],'tongxie','ai_skill_playerschosen')
sgs.ai_skill_invoke['fuping']=wrap(sgs.ai_skill_invoke['fuping'],'fuping','ai_skill_invoke')
sgs.ai_fill_skill['fuping']=wrap(sgs.ai_fill_skill['fuping'],'fuping','ai_fill_skill')
sgs.ai_skill_use_func['FupingCard']=wrap(sgs.ai_skill_use_func['FupingCard'],'FupingCard','ai_skill_use_func')
sgs.ai_guhuo_card['fuping']=wrap(sgs.ai_guhuo_card['fuping'],'fuping','ai_guhuo_card')
sgs.ai_fill_skill['weilie']=wrap(sgs.ai_fill_skill['weilie'],'weilie','ai_fill_skill')
sgs.ai_skill_use_func['WeilieCard']=wrap(sgs.ai_skill_use_func['WeilieCard'],'WeilieCard','ai_skill_use_func')
sgs.ai_fill_skill['tenyearjinggong']=wrap(sgs.ai_fill_skill['tenyearjinggong'],'tenyearjinggong','ai_fill_skill')
sgs.ai_guhuo_card['tenyearjinggong']=wrap(sgs.ai_guhuo_card['tenyearjinggong'],'tenyearjinggong','ai_guhuo_card')
sgs.ai_skill_invoke['tenyearxiaojun']=wrap(sgs.ai_skill_invoke['tenyearxiaojun'],'tenyearxiaojun','ai_skill_invoke')
sgs.ai_skill_invoke['tenyearmingfa']=wrap(sgs.ai_skill_invoke['tenyearmingfa'],'tenyearmingfa','ai_skill_invoke')
sgs.ai_skill_invoke['tenyeardeshao']=wrap(sgs.ai_skill_invoke['tenyeardeshao'],'tenyeardeshao','ai_skill_invoke')
sgs.ai_skill_playerchosen['tenyearmingfa']=wrap(sgs.ai_skill_playerchosen['tenyearmingfa'],'tenyearmingfa','ai_skill_playerchosen')
sgs.ai_skill_discard['liejie']=wrap(sgs.ai_skill_discard['liejie'],'liejie','ai_skill_discard')
sgs.ai_skill_cardchosen['liejie']=wrap(sgs.ai_skill_cardchosen['liejie'],'liejie','ai_skill_cardchosen')
sgs.ai_skill_invoke['yuanzi']=wrap(sgs.ai_skill_invoke['yuanzi'],'yuanzi','ai_skill_invoke')
sgs.ai_skill_invoke['tongli']=wrap(sgs.ai_skill_invoke['tongli'],'tongli','ai_skill_invoke')
sgs.ai_skill_invoke['shezang']=wrap(sgs.ai_skill_invoke['shezang'],'shezang','ai_skill_invoke')
sgs.ai_skill_playerchosen['tuoxian']=wrap(sgs.ai_skill_playerchosen['tuoxian'],'tuoxian','ai_skill_playerchosen')
sgs.ai_skill_use['@@tuoxian']=wrap(sgs.ai_skill_use['@@tuoxian'],'@@tuoxian','ai_skill_use')
sgs.ai_skill_playerchosen['dunxi']=wrap(sgs.ai_skill_playerchosen['dunxi'],'dunxi','ai_skill_playerchosen')
sgs.ai_skill_invoke['tenyearxiecui']=wrap(sgs.ai_skill_invoke['tenyearxiecui'],'tenyearxiecui','ai_skill_invoke')
sgs.ai_skill_invoke['tenyearyouxu']=wrap(sgs.ai_skill_invoke['tenyearyouxu'],'tenyearyouxu','ai_skill_invoke')
sgs.ai_skill_playerchosen['tenyearyouxu']=wrap(sgs.ai_skill_playerchosen['tenyearyouxu'],'tenyearyouxu','ai_skill_playerchosen')
sgs.ai_skill_invoke['zhongjie']=wrap(sgs.ai_skill_invoke['zhongjie'],'zhongjie','ai_skill_invoke')
sgs.ai_skill_invoke['sushou']=wrap(sgs.ai_skill_invoke['sushou'],'sushou','ai_skill_invoke')
sgs.ai_skill_use['@@sushou']=wrap(sgs.ai_skill_use['@@sushou'],'@@sushou','ai_skill_use')
sgs.ai_skill_playerchosen['suizheng']=wrap(sgs.ai_skill_playerchosen['suizheng'],'suizheng','ai_skill_playerchosen')
sgs.ai_skill_use['@@suizheng']=wrap(sgs.ai_skill_use['@@suizheng'],'@@suizheng','ai_skill_use')
sgs.ai_skill_playerchosen['suizheng1']=wrap(sgs.ai_skill_playerchosen['suizheng1'],'suizheng1','ai_skill_playerchosen')
sgs.ai_fill_skill['kaiji']=wrap(sgs.ai_fill_skill['kaiji'],'kaiji','ai_fill_skill')
sgs.ai_skill_use_func['KaijiCard']=wrap(sgs.ai_skill_use_func['KaijiCard'],'KaijiCard','ai_skill_use_func')
sgs.ai_skill_playerschosen['pingxi']=wrap(sgs.ai_skill_playerschosen['pingxi'],'pingxi','ai_skill_playerschosen')
sgs.ai_fill_skill['xunji']=wrap(sgs.ai_fill_skill['xunji'],'xunji','ai_fill_skill')
sgs.ai_skill_use_func['XunjiCard']=wrap(sgs.ai_skill_use_func['XunjiCard'],'XunjiCard','ai_skill_use_func')
sgs.ai_skill_invoke['fanyin']=wrap(sgs.ai_skill_invoke['fanyin'],'fanyin','ai_skill_invoke')
sgs.ai_skill_use['@@fanyin']=wrap(sgs.ai_skill_use['@@fanyin'],'@@fanyin','ai_skill_use')
sgs.ai_skill_invoke['fanyin_targetfixed']=wrap(sgs.ai_skill_invoke['fanyin_targetfixed'],'fanyin_targetfixed','ai_skill_invoke')
sgs.ai_skill_playerschosen['fanyin']=wrap(sgs.ai_skill_playerschosen['fanyin'],'fanyin','ai_skill_playerschosen')
sgs.ai_skill_invoke['peiqi']=wrap(sgs.ai_skill_invoke['peiqi'],'peiqi','ai_skill_invoke')
sgs.ai_skill_playerchosen['peiqi_from']=wrap(sgs.ai_skill_playerchosen['peiqi_from'],'peiqi_from','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['peiqi_to']=wrap(sgs.ai_skill_playerchosen['peiqi_to'],'peiqi_to','ai_skill_playerchosen')
sgs.ai_skill_cardchosen['peiqi']=wrap(sgs.ai_skill_cardchosen['peiqi'],'peiqi','ai_skill_cardchosen')
sgs.ai_can_damagehp['peiqi']=wrap(sgs.ai_can_damagehp['peiqi'],'peiqi','ai_can_damagehp')
sgs.ai_skill_playerchosen['xiaoxinf']=wrap(sgs.ai_skill_playerchosen['xiaoxinf'],'xiaoxinf','ai_skill_playerchosen')
sgs.ai_skill_choice['xiaoxinf']=wrap(sgs.ai_skill_choice['xiaoxinf'],'xiaoxinf','ai_skill_choice')
sgs.ai_skill_playerchosen['xiaoxinf_slash']=wrap(sgs.ai_skill_playerchosen['xiaoxinf_slash'],'xiaoxinf_slash','ai_skill_playerchosen')
sgs.ai_skill_invoke['xiongrao']=wrap(sgs.ai_skill_invoke['xiongrao'],'xiongrao','ai_skill_invoke')
sgs.ai_skill_invoke['diting']=wrap(sgs.ai_skill_invoke['diting'],'diting','ai_skill_invoke')
sgs.ai_skill_askforag['diting']=wrap(sgs.ai_skill_askforag['diting'],'diting','ai_skill_askforag')
sgs.ai_skill_playerchosen['bihuof']=wrap(sgs.ai_skill_playerchosen['bihuof'],'bihuof','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['bihuof2']=wrap(sgs.ai_skill_playerchosen['bihuof2'],'bihuof2','ai_skill_playerchosen')
sgs.ai_skill_invoke['kanpodz']=wrap(sgs.ai_skill_invoke['kanpodz'],'kanpodz','ai_skill_invoke')
sgs.ai_fill_skill['kanpodz']=wrap(sgs.ai_fill_skill['kanpodz'],'kanpodz','ai_fill_skill')
sgs.ai_guhuo_card['kanpodz']=wrap(sgs.ai_guhuo_card['kanpodz'],'kanpodz','ai_guhuo_card')
sgs.ai_skill_invoke['gengzhan']=wrap(sgs.ai_skill_invoke['gengzhan'],'gengzhan','ai_skill_invoke')
sgs.ai_fill_skill['midu']=wrap(sgs.ai_fill_skill['midu'],'midu','ai_fill_skill')
sgs.ai_skill_use_func['MiduCard']=wrap(sgs.ai_skill_use_func['MiduCard'],'MiduCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['midu']=wrap(sgs.ai_skill_playerchosen['midu'],'midu','ai_skill_playerchosen')
sgs.ai_skill_playerschosen['yingyu']=wrap(sgs.ai_skill_playerschosen['yingyu'],'yingyu','ai_skill_playerschosen')
sgs.ai_skill_playerchosen['yingyu']=wrap(sgs.ai_skill_playerchosen['yingyu'],'yingyu','ai_skill_playerchosen')
sgs.ai_fill_skill['yongbi']=wrap(sgs.ai_fill_skill['yongbi'],'yongbi','ai_fill_skill')
sgs.ai_skill_use_func['YongbiCard']=wrap(sgs.ai_skill_use_func['YongbiCard'],'YongbiCard','ai_skill_use_func')
sgs.ai_skill_cardask['@fenrui']=wrap(sgs.ai_skill_cardask['@fenrui'],'@fenrui','ai_skill_cardask')
sgs.ai_skill_playerchosen['fenrui']=wrap(sgs.ai_skill_playerchosen['fenrui'],'fenrui','ai_skill_playerchosen')
sgs.ai_skill_invoke['tenyeartujue']=wrap(sgs.ai_skill_invoke['tenyeartujue'],'tenyeartujue','ai_skill_invoke')
sgs.ai_fill_skill['tenyearquanjian']=wrap(sgs.ai_fill_skill['tenyearquanjian'],'tenyearquanjian','ai_fill_skill')
sgs.ai_skill_use_func['TenyearQuanjianCard']=wrap(sgs.ai_skill_use_func['TenyearQuanjianCard'],'TenyearQuanjianCard','ai_skill_use_func')
sgs.ai_skill_invoke['tenyearquanjian']=wrap(sgs.ai_skill_invoke['tenyearquanjian'],'tenyearquanjian','ai_skill_invoke')
sgs.ai_skill_discard['tenyearquanjian']=wrap(sgs.ai_skill_discard['tenyearquanjian'],'tenyearquanjian','ai_skill_discard')
sgs.ai_skill_invoke['suoliang']=wrap(sgs.ai_skill_invoke['suoliang'],'suoliang','ai_skill_invoke')
sgs.ai_skill_invoke['chongyi']=wrap(sgs.ai_skill_invoke['chongyi'],'chongyi','ai_skill_invoke')
sgs.ai_skill_invoke['yingtu']=wrap(sgs.ai_skill_invoke['yingtu'],'yingtu','ai_skill_invoke')
sgs.ai_skill_cardask['@tenyearpoyuan-discard']=wrap(sgs.ai_skill_cardask['@tenyearpoyuan-discard'],'@tenyearpoyuan-discard','ai_skill_cardask')
sgs.ai_skill_playerchosen['tenyearpoyuan']=wrap(sgs.ai_skill_playerchosen['tenyearpoyuan'],'tenyearpoyuan','ai_skill_playerchosen')
sgs.ai_skill_cardchosen['tenyearpoyuan']=wrap(sgs.ai_skill_cardchosen['tenyearpoyuan'],'tenyearpoyuan','ai_skill_cardchosen')
sgs.ai_fill_skill['tenyearhuace']=wrap(sgs.ai_fill_skill['tenyearhuace'],'tenyearhuace','ai_fill_skill')
sgs.ai_skill_use_func['TenyearHuaceCard']=wrap(sgs.ai_skill_use_func['TenyearHuaceCard'],'TenyearHuaceCard','ai_skill_use_func')
sgs.ai_skill_invoke['ruizhan']=wrap(sgs.ai_skill_invoke['ruizhan'],'ruizhan','ai_skill_invoke')
sgs.ai_fill_skill['shilie']=wrap(sgs.ai_fill_skill['shilie'],'shilie','ai_fill_skill')
sgs.ai_skill_use_func['ShilieCard']=wrap(sgs.ai_skill_use_func['ShilieCard'],'ShilieCard','ai_skill_use_func')
sgs.ai_skill_use['@@shilie!']=wrap(sgs.ai_skill_use['@@shilie!'],'@@shilie!','ai_skill_use')
sgs.ai_skill_playerchosen['shilie']=wrap(sgs.ai_skill_playerchosen['shilie'],'shilie','ai_skill_playerchosen')
sgs.ai_fill_skill['qiaoli']=wrap(sgs.ai_fill_skill['qiaoli'],'qiaoli','ai_fill_skill')
sgs.ai_skill_invoke['qingliang']=wrap(sgs.ai_skill_invoke['qingliang'],'qingliang','ai_skill_invoke')
sgs.ai_skill_choice['qingliang']=wrap(sgs.ai_skill_choice['qingliang'],'qingliang','ai_skill_choice')
sgs.ai_skill_choice['chongwang']=wrap(sgs.ai_skill_choice['chongwang'],'chongwang','ai_skill_choice')
sgs.ai_skill_playerschosen['huagui']=wrap(sgs.ai_skill_playerschosen['huagui'],'huagui','ai_skill_playerschosen')
sgs.ai_skill_choice['huagui']=wrap(sgs.ai_skill_choice['huagui'],'huagui','ai_skill_choice')
sgs.ai_skill_invoke['jingjian']=wrap(sgs.ai_skill_invoke['jingjian'],'jingjian','ai_skill_invoke')
sgs.ai_skill_choice['zhenze']=wrap(sgs.ai_skill_choice['zhenze'],'zhenze','ai_skill_choice')
sgs.ai_fill_skill['anliao']=wrap(sgs.ai_fill_skill['anliao'],'anliao','ai_fill_skill')
sgs.ai_skill_use_func['AnliaoCard']=wrap(sgs.ai_skill_use_func['AnliaoCard'],'AnliaoCard','ai_skill_use_func')
sgs.ai_skill_invoke['xieshou']=wrap(sgs.ai_skill_invoke['xieshou'],'xieshou','ai_skill_invoke')
sgs.ai_skill_choice['xieshou']=wrap(sgs.ai_skill_choice['xieshou'],'xieshou','ai_skill_choice')
sgs.ai_skill_invoke['qingyan']=wrap(sgs.ai_skill_invoke['qingyan'],'qingyan','ai_skill_invoke')
sgs.ai_skill_cardask['@qingyan']=wrap(sgs.ai_skill_cardask['@qingyan'],'@qingyan','ai_skill_cardask')
sgs.ai_skill_cardask['@duoduan-card']=wrap(sgs.ai_skill_cardask['@duoduan-card'],'@duoduan-card','ai_skill_cardask')
sgs.ai_skill_discard['duoduan']=wrap(sgs.ai_skill_discard['duoduan'],'duoduan','ai_skill_discard')
sgs.ai_skill_use['@@gongsun']=wrap(sgs.ai_skill_use['@@gongsun'],'@@gongsun','ai_skill_use')
sgs.ai_skill_askforag['GongsunCard']=wrap(sgs.ai_skill_askforag['GongsunCard'],'GongsunCard','ai_skill_askforag')
sgs.ai_skill_invoke['juanxia_slash']=wrap(sgs.ai_skill_invoke['juanxia_slash'],'juanxia_slash','ai_skill_invoke')
sgs.ai_skill_playerchosen['juanxia']=wrap(sgs.ai_skill_playerchosen['juanxia'],'juanxia','ai_skill_playerchosen')
sgs.ai_skill_choice['juanxia']=wrap(sgs.ai_skill_choice['juanxia'],'juanxia','ai_skill_choice')
sgs.ai_skill_invoke['tenyearjuanxia_slash']=wrap(sgs.ai_skill_invoke['tenyearjuanxia_slash'],'tenyearjuanxia_slash','ai_skill_invoke')
sgs.ai_skill_playerchosen['tenyearjuanxia']=wrap(sgs.ai_skill_playerchosen['tenyearjuanxia'],'tenyearjuanxia','ai_skill_playerchosen')
sgs.ai_skill_choice['tenyearjuanxia']=wrap(sgs.ai_skill_choice['tenyearjuanxia'],'tenyearjuanxia','ai_skill_choice')
sgs.ai_fill_skill['zhouxuan']=wrap(sgs.ai_fill_skill['zhouxuan'],'zhouxuan','ai_fill_skill')
sgs.ai_skill_use_func['ZhouxuanCard']=wrap(sgs.ai_skill_use_func['ZhouxuanCard'],'ZhouxuanCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['zhouxuan']=wrap(sgs.ai_skill_playerchosen['zhouxuan'],'zhouxuan','ai_skill_playerchosen')
sgs.ai_skill_askforyiji['zhouxuan']=wrap(sgs.ai_skill_askforyiji['zhouxuan'],'zhouxuan','ai_skill_askforyiji')
sgs.ai_skill_invoke['wangzu']=wrap(sgs.ai_skill_invoke['wangzu'],'wangzu','ai_skill_invoke')
sgs.ai_skill_cardask['@wangzu-discard']=wrap(sgs.ai_skill_cardask['@wangzu-discard'],'@wangzu-discard','ai_skill_cardask')
sgs.ai_fill_skill['yingrui']=wrap(sgs.ai_fill_skill['yingrui'],'yingrui','ai_fill_skill')
sgs.ai_skill_use_func['YingruiCard']=wrap(sgs.ai_skill_use_func['YingruiCard'],'YingruiCard','ai_skill_use_func')
sgs.ai_skill_discard['yingrui']=wrap(sgs.ai_skill_discard['yingrui'],'yingrui','ai_skill_discard')
sgs.ai_skill_invoke['fuyuan']=wrap(sgs.ai_skill_invoke['fuyuan'],'fuyuan','ai_skill_invoke')
sgs.ai_skill_choice['olfengji']=wrap(sgs.ai_skill_choice['olfengji'],'olfengji','ai_skill_choice')
sgs.ai_skill_playerchosen['olfengji']=wrap(sgs.ai_skill_playerchosen['olfengji'],'olfengji','ai_skill_playerchosen')
sgs.ai_skill_cardask['@tenyearmeibu-dis']=wrap(sgs.ai_skill_cardask['@tenyearmeibu-dis'],'@tenyearmeibu-dis','ai_skill_cardask')
sgs.ai_skill_cardask['@secondtenyearmeibu-dis']=wrap(sgs.ai_skill_cardask['@secondtenyearmeibu-dis'],'@secondtenyearmeibu-dis','ai_skill_cardask')
sgs.ai_skill_invoke['tenyearmumu']=wrap(sgs.ai_skill_invoke['tenyearmumu'],'tenyearmumu','ai_skill_invoke')
sgs.ai_skill_invoke['SecondTenyearMumu']=wrap(sgs.ai_skill_invoke['SecondTenyearMumu'],'SecondTenyearMumu','ai_skill_invoke')
sgs.ai_skill_discard['tenyearzhixi']=wrap(sgs.ai_skill_discard['tenyearzhixi'],'tenyearzhixi','ai_skill_discard')
sgs.ai_fill_skill['yujue']=wrap(sgs.ai_fill_skill['yujue'],'yujue','ai_fill_skill')
sgs.ai_skill_use_func['YujueCard']=wrap(sgs.ai_skill_use_func['YujueCard'],'YujueCard','ai_skill_use_func')
sgs.ai_skill_choice['yujue']=wrap(sgs.ai_skill_choice['yujue'],'yujue','ai_skill_choice')
sgs.ai_skill_playerchosen['yujue']=wrap(sgs.ai_skill_playerchosen['yujue'],'yujue','ai_skill_playerchosen')
sgs.ai_skill_discard['yujue']=wrap(sgs.ai_skill_discard['yujue'],'yujue','ai_skill_discard')
sgs.ai_fill_skill['secondyujue']=wrap(sgs.ai_fill_skill['secondyujue'],'secondyujue','ai_fill_skill')
sgs.ai_skill_use_func['SecondYujueCard']=wrap(sgs.ai_skill_use_func['SecondYujueCard'],'SecondYujueCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['secondyujue']=wrap(sgs.ai_skill_playerchosen['secondyujue'],'secondyujue','ai_skill_playerchosen')
sgs.ai_fill_skill['spniluan']=wrap(sgs.ai_fill_skill['spniluan'],'spniluan','ai_fill_skill')
sgs.ai_skill_use_func['SpNiluanCard']=wrap(sgs.ai_skill_use_func['SpNiluanCard'],'SpNiluanCard','ai_skill_use_func')
sgs.ai_fill_skill['weiwu']=wrap(sgs.ai_fill_skill['weiwu'],'weiwu','ai_fill_skill')
sgs.ai_skill_use_func['WeiwuCard']=wrap(sgs.ai_skill_use_func['WeiwuCard'],'WeiwuCard','ai_skill_use_func')
sgs.ai_skill_invoke['gongjian']=wrap(sgs.ai_skill_invoke['gongjian'],'gongjian','ai_skill_invoke')
sgs.ai_skill_choice['gongjian']=wrap(sgs.ai_skill_choice['gongjian'],'gongjian','ai_skill_choice')
sgs.ai_skill_playerchosen['cixiao']=wrap(sgs.ai_skill_playerchosen['cixiao'],'cixiao','ai_skill_playerchosen')
sgs.ai_skill_use['@@cixiao']=wrap(sgs.ai_skill_use['@@cixiao'],'@@cixiao','ai_skill_use')
sgs.ai_skill_askforyiji['panshi']=wrap(sgs.ai_skill_askforyiji['panshi'],'panshi','ai_skill_askforyiji')
sgs.ai_skill_playerchosen['jieyingh']=wrap(sgs.ai_skill_playerchosen['jieyingh'],'jieyingh','ai_skill_playerchosen')
sgs.ai_skill_use['@@jieyingh']=wrap(sgs.ai_skill_use['@@jieyingh'],'@@jieyingh','ai_skill_use')
sgs.ai_skill_discard['weipo']=wrap(sgs.ai_skill_discard['weipo'],'weipo','ai_skill_discard')
sgs.ai_fill_skill['minsi']=wrap(sgs.ai_fill_skill['minsi'],'minsi','ai_fill_skill')
sgs.ai_skill_use_func['MinsiCard']=wrap(sgs.ai_skill_use_func['MinsiCard'],'MinsiCard','ai_skill_use_func')
sgs.ai_skill_invoke['jijing']=wrap(sgs.ai_skill_invoke['jijing'],'jijing','ai_skill_invoke')
sgs.ai_skill_use['@@jijing']=wrap(sgs.ai_skill_use['@@jijing'],'@@jijing','ai_skill_use')
sgs.ai_skill_playerchosen['zhuide']=wrap(sgs.ai_skill_playerchosen['zhuide'],'zhuide','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['spdushi']=wrap(sgs.ai_skill_playerchosen['spdushi'],'spdushi','ai_skill_playerchosen')
sgs.ai_fill_skill['daoji']=wrap(sgs.ai_fill_skill['daoji'],'daoji','ai_fill_skill')
sgs.ai_skill_use_func['DaojiCard']=wrap(sgs.ai_skill_use_func['DaojiCard'],'DaojiCard','ai_skill_use_func')
sgs.ai_skill_cardchosen['daoji']=wrap(sgs.ai_skill_cardchosen['daoji'],'daoji','ai_skill_cardchosen')
sgs.ai_skill_cardask['@mobileniluan']=wrap(sgs.ai_skill_cardask['@mobileniluan'],'@mobileniluan','ai_skill_cardask')
do local f=sgs.ai_view_as['mobilexiaoxi'];sgs.ai_view_as['mobilexiaoxi']=function(...)return proposal(f(...))end end
sgs.ai_fill_skill['mobilexiaoxi']=wrap(sgs.ai_fill_skill['mobilexiaoxi'],'mobilexiaoxi','ai_fill_skill')
sgs.ai_cardneed['mobilexiaoxi']=wrap(sgs.ai_cardneed['mobilexiaoxi'],'mobilexiaoxi','ai_cardneed')
sgs.ai_skill_invoke['pingjian']=wrap(sgs.ai_skill_invoke['pingjian'],'pingjian','ai_skill_invoke')
sgs.ai_fill_skill['pingjian']=wrap(sgs.ai_fill_skill['pingjian'],'pingjian','ai_fill_skill')
sgs.ai_skill_use_func['PingjianCard']=wrap(sgs.ai_skill_use_func['PingjianCard'],'PingjianCard','ai_skill_use_func')
sgs.ai_fill_skill['shoufu']=wrap(sgs.ai_fill_skill['shoufu'],'shoufu','ai_fill_skill')
sgs.ai_skill_use_func['ShoufuCard']=wrap(sgs.ai_skill_use_func['ShoufuCard'],'ShoufuCard','ai_skill_use_func')
sgs.ai_skill_use['@@shoufu!']=wrap(sgs.ai_skill_use['@@shoufu!'],'@@shoufu!','ai_skill_use')
sgs.ai_fill_skill['tenyearsongci']=wrap(sgs.ai_fill_skill['tenyearsongci'],'tenyearsongci','ai_fill_skill')
sgs.ai_skill_use_func['TenyearSongciCard']=wrap(sgs.ai_skill_use_func['TenyearSongciCard'],'TenyearSongciCard','ai_skill_use_func')
sgs.ai_fill_skill['youlong']=wrap(sgs.ai_fill_skill['youlong'],'youlong','ai_fill_skill')
sgs.ai_skill_use_func['YoulongCard']=wrap(sgs.ai_skill_use_func['YoulongCard'],'YoulongCard','ai_skill_use_func')
sgs.ai_guhuo_card['youlong']=wrap(sgs.ai_guhuo_card['youlong'],'youlong','ai_guhuo_card')
sgs.ai_skill_invoke['luanfeng']=wrap(sgs.ai_skill_invoke['luanfeng'],'luanfeng','ai_skill_invoke')
sgs.ai_fill_skill['secondzhanyi']=wrap(sgs.ai_fill_skill['secondzhanyi'],'secondzhanyi','ai_fill_skill')
sgs.ai_skill_use_func['SecondZhanyiCard']=wrap(sgs.ai_skill_use_func['SecondZhanyiCard'],'SecondZhanyiCard','ai_skill_use_func')
sgs.ai_skill_use_func['SecondZhanyiViewAsBasicCard']=wrap(sgs.ai_skill_use_func['SecondZhanyiViewAsBasicCard'],'SecondZhanyiViewAsBasicCard','ai_skill_use_func')
sgs.ai_skill_invoke['pianchong']=wrap(sgs.ai_skill_invoke['pianchong'],'pianchong','ai_skill_invoke')
sgs.ai_skill_choice['pianchong']=wrap(sgs.ai_skill_choice['pianchong'],'pianchong','ai_skill_choice')
sgs.ai_fill_skill['zunwei']=wrap(sgs.ai_fill_skill['zunwei'],'zunwei','ai_fill_skill')
sgs.ai_skill_use_func['ZunweiCard']=wrap(sgs.ai_skill_use_func['ZunweiCard'],'ZunweiCard','ai_skill_use_func')
sgs.ai_skill_invoke['taomie']=wrap(sgs.ai_skill_invoke['taomie'],'taomie','ai_skill_invoke')
sgs.ai_skill_choice['taomie']=wrap(sgs.ai_skill_choice['taomie'],'taomie','ai_skill_choice')
sgs.ai_skill_askforyiji['taomie']=wrap(sgs.ai_skill_askforyiji['taomie'],'taomie','ai_skill_askforyiji')
sgs.ai_skill_invoke['liangying']=wrap(sgs.ai_skill_invoke['liangying'],'liangying','ai_skill_invoke')
sgs.ai_skill_choice['liangying']=wrap(sgs.ai_skill_choice['liangying'],'liangying','ai_skill_choice')
sgs.ai_skill_askforyiji['liangying']=wrap(sgs.ai_skill_askforyiji['liangying'],'liangying','ai_skill_askforyiji')
sgs.ai_fill_skill['bazhan']=wrap(sgs.ai_fill_skill['bazhan'],'bazhan','ai_fill_skill')
sgs.ai_skill_use_func['BazhanCard']=wrap(sgs.ai_skill_use_func['BazhanCard'],'BazhanCard','ai_skill_use_func')
sgs.ai_skill_choice['bazhan']=wrap(sgs.ai_skill_choice['bazhan'],'bazhan','ai_skill_choice')
sgs.ai_skill_playerchosen['jiaoying']=wrap(sgs.ai_skill_playerchosen['jiaoying'],'jiaoying','ai_skill_playerchosen')
sgs.ai_skill_cardask['@yangzhong']=wrap(sgs.ai_skill_cardask['@yangzhong'],'@yangzhong','ai_skill_cardask')
sgs.ai_skill_invoke['lilu']=wrap(sgs.ai_skill_invoke['lilu'],'lilu','ai_skill_invoke')
sgs.ai_skill_use['@@lilu!']=wrap(sgs.ai_skill_use['@@lilu!'],'@@lilu!','ai_skill_use')
sgs.ai_skill_playerchosen['yizhengc']=wrap(sgs.ai_skill_playerchosen['yizhengc'],'yizhengc','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['tenyearyirang']=wrap(sgs.ai_skill_playerchosen['tenyearyirang'],'tenyearyirang','ai_skill_playerchosen')
sgs.ai_skill_choice['newfengpo']=wrap(sgs.ai_skill_choice['newfengpo'],'newfengpo','ai_skill_choice')
sgs.ai_fill_skill['tianjiang']=wrap(sgs.ai_fill_skill['tianjiang'],'tianjiang','ai_fill_skill')
sgs.ai_skill_use_func['TianjiangCard']=wrap(sgs.ai_skill_use_func['TianjiangCard'],'TianjiangCard','ai_skill_use_func')
sgs.ai_fill_skill['zhuren']=wrap(sgs.ai_fill_skill['zhuren'],'zhuren','ai_fill_skill')
sgs.ai_skill_use_func['ZhurenCard']=wrap(sgs.ai_skill_use_func['ZhurenCard'],'ZhurenCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['olduanbing']=wrap(sgs.ai_skill_playerchosen['olduanbing'],'olduanbing','ai_skill_playerchosen')
sgs.ai_fill_skill['olfenxun']=wrap(sgs.ai_fill_skill['olfenxun'],'olfenxun','ai_fill_skill')
sgs.ai_skill_use_func['OLFenxunCard']=wrap(sgs.ai_skill_use_func['OLFenxunCard'],'OLFenxunCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['choulve']=wrap(sgs.ai_skill_playerchosen['choulve'],'choulve','ai_skill_playerchosen')
sgs.ai_skill_discard['choulve']=wrap(sgs.ai_skill_discard['choulve'],'choulve','ai_skill_discard')
sgs.ai_skill_use['@@choulve!']=wrap(sgs.ai_skill_use['@@choulve!'],'@@choulve!','ai_skill_use')
sgs.ai_skill_invoke['weiyi']=wrap(sgs.ai_skill_invoke['weiyi'],'weiyi','ai_skill_invoke')
sgs.ai_skill_choice['weiyi']=wrap(sgs.ai_skill_choice['weiyi'],'weiyi','ai_skill_choice')
sgs.ai_fill_skill['jinzhi']=wrap(sgs.ai_fill_skill['jinzhi'],'jinzhi','ai_fill_skill')
sgs.ai_skill_use_func['JinzhiCard']=wrap(sgs.ai_skill_use_func['JinzhiCard'],'JinzhiCard','ai_skill_use_func')
sgs.ai_guhuo_card['jinzhi']=wrap(sgs.ai_guhuo_card['jinzhi'],'jinzhi','ai_guhuo_card')
sgs.ai_fill_skill['secondjinzhi']=wrap(sgs.ai_fill_skill['secondjinzhi'],'secondjinzhi','ai_fill_skill')
sgs.ai_skill_use_func['SecondJinzhiCard']=wrap(sgs.ai_skill_use_func['SecondJinzhiCard'],'SecondJinzhiCard','ai_skill_use_func')
sgs.ai_guhuo_card['secondjinzhi']=wrap(sgs.ai_guhuo_card['secondjinzhi'],'secondjinzhi','ai_guhuo_card')
sgs.ai_skill_invoke['xingzuo']=wrap(sgs.ai_skill_invoke['xingzuo'],'xingzuo','ai_skill_invoke')
sgs.ai_skill_use['@@xingzuo']=wrap(sgs.ai_skill_use['@@xingzuo'],'@@xingzuo','ai_skill_use')
sgs.ai_skill_playerchosen['xingzuo']=wrap(sgs.ai_skill_playerchosen['xingzuo'],'xingzuo','ai_skill_playerchosen')
sgs.ai_fill_skill['miaoxian']=wrap(sgs.ai_fill_skill['miaoxian'],'miaoxian','ai_fill_skill')
sgs.ai_skill_use_func['MiaoxianCard']=wrap(sgs.ai_skill_use_func['MiaoxianCard'],'MiaoxianCard','ai_skill_use_func')
sgs.ai_guhuo_card['miaoxian']=wrap(sgs.ai_guhuo_card['miaoxian'],'miaoxian','ai_guhuo_card')
sgs.ai_skill_playerchosen['mouni']=wrap(sgs.ai_skill_playerchosen['mouni'],'mouni','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['fuzhong']=wrap(sgs.ai_skill_playerchosen['fuzhong'],'fuzhong','ai_skill_playerchosen')
sgs.ai_fill_skill['jingong']=wrap(sgs.ai_fill_skill['jingong'],'jingong','ai_fill_skill')
sgs.ai_fill_skill['tenyearjingong']=wrap(sgs.ai_fill_skill['tenyearjingong'],'tenyearjingong','ai_fill_skill')
sgs.ai_fill_skill['tenyearlianji']=wrap(sgs.ai_fill_skill['tenyearlianji'],'tenyearlianji','ai_fill_skill')
sgs.ai_skill_use_func['TenyearLianjiCard']=wrap(sgs.ai_skill_use_func['TenyearLianjiCard'],'TenyearLianjiCard','ai_skill_use_func')
sgs.ai_fill_skill['ollianji']=wrap(sgs.ai_fill_skill['ollianji'],'ollianji','ai_fill_skill')
sgs.ai_skill_use_func['OLLianjiCard']=wrap(sgs.ai_skill_use_func['OLLianjiCard'],'OLLianjiCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['ollianji']=wrap(sgs.ai_skill_playerchosen['ollianji'],'ollianji','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['ollianji_give']=wrap(sgs.ai_skill_playerchosen['ollianji_give'],'ollianji_give','ai_skill_playerchosen')
sgs.ai_fill_skill['mobilelianji']=wrap(sgs.ai_fill_skill['mobilelianji'],'mobilelianji','ai_fill_skill')
sgs.ai_skill_use_func['MobileLianjiCard']=wrap(sgs.ai_skill_use_func['MobileLianjiCard'],'MobileLianjiCard','ai_skill_use_func')
sgs.ai_skill_invoke['newtunchu']=wrap(sgs.ai_skill_invoke['newtunchu'],'newtunchu','ai_skill_invoke')
sgs.ai_skill_discard['newtunchu']=wrap(sgs.ai_skill_discard['newtunchu'],'newtunchu','ai_skill_discard')
sgs.ai_skill_use['@@newshuliang']=wrap(sgs.ai_skill_use['@@newshuliang'],'@@newshuliang','ai_skill_use')
sgs.ai_fill_skill['guanxu']=wrap(sgs.ai_fill_skill['guanxu'],'guanxu','ai_fill_skill')
sgs.ai_skill_use_func['GuanxuCard']=wrap(sgs.ai_skill_use_func['GuanxuCard'],'GuanxuCard','ai_skill_use_func')
sgs.ai_skill_use['@@guanxu1']=wrap(sgs.ai_skill_use['@@guanxu1'],'@@guanxu1','ai_skill_use')
sgs.ai_skill_use['@@guanxu2']=wrap(sgs.ai_skill_use['@@guanxu2'],'@@guanxu2','ai_skill_use')
sgs.ai_skill_invoke['yashi']=wrap(sgs.ai_skill_invoke['yashi'],'yashi','ai_skill_invoke')
sgs.ai_skill_choice['yashi']=wrap(sgs.ai_skill_choice['yashi'],'yashi','ai_skill_choice')
sgs.ai_skill_playerchosen['yashi']=wrap(sgs.ai_skill_playerchosen['yashi'],'yashi','ai_skill_playerchosen')
sgs.ai_fill_skill['tenyearjiezhen']=wrap(sgs.ai_fill_skill['tenyearjiezhen'],'tenyearjiezhen','ai_fill_skill')
sgs.ai_skill_use_func['TenyearJiezhenCard']=wrap(sgs.ai_skill_use_func['TenyearJiezhenCard'],'TenyearJiezhenCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['tenyearzecai']=wrap(sgs.ai_skill_playerchosen['tenyearzecai'],'tenyearzecai','ai_skill_playerchosen')
sgs.ai_can_damagehp['tenyearyinshi']=wrap(sgs.ai_can_damagehp['tenyearyinshi'],'tenyearyinshi','ai_can_damagehp')
sgs.ai_target_revises['tenyearyinshi']=wrap(sgs.ai_target_revises['tenyearyinshi'],'tenyearyinshi','ai_target_revises')
sgs.ai_skill_use['@@spcuorui']=wrap(sgs.ai_skill_use['@@spcuorui'],'@@spcuorui','ai_skill_use')
sgs.ai_skill_invoke['spliewei']=wrap(sgs.ai_skill_invoke['spliewei'],'spliewei','ai_skill_invoke')
sgs.ai_fill_skill['secondspcuorui']=wrap(sgs.ai_fill_skill['secondspcuorui'],'secondspcuorui','ai_fill_skill')
sgs.ai_skill_use_func['SecondSpCuoruiCard']=wrap(sgs.ai_skill_use_func['SecondSpCuoruiCard'],'SecondSpCuoruiCard','ai_skill_use_func')
sgs.ai_skill_invoke['secondspliewei']=wrap(sgs.ai_skill_invoke['secondspliewei'],'secondspliewei','ai_skill_invoke')
sgs.ai_fill_skill['tiansuan']=wrap(sgs.ai_fill_skill['tiansuan'],'tiansuan','ai_fill_skill')
sgs.ai_skill_use_func['TiansuanCard']=wrap(sgs.ai_skill_use_func['TiansuanCard'],'TiansuanCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['tiansuan0']=wrap(sgs.ai_skill_playerchosen['tiansuan0'],'tiansuan0','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['lulve']=wrap(sgs.ai_skill_playerchosen['lulve'],'lulve','ai_skill_playerchosen')
sgs.ai_skill_choice['lulve']=wrap(sgs.ai_skill_choice['lulve'],'lulve','ai_skill_choice')
sgs.ai_skill_playerchosen['wanggui']=wrap(sgs.ai_skill_playerchosen['wanggui'],'wanggui','ai_skill_playerchosen')
sgs.ai_skill_invoke['xibing']=wrap(sgs.ai_skill_invoke['xibing'],'xibing','ai_skill_invoke')
sgs.ai_skill_invoke['youyan']=wrap(sgs.ai_skill_invoke['youyan'],'youyan','ai_skill_invoke')
sgs.ai_skill_playerchosen['zhuihuan']=wrap(sgs.ai_skill_playerchosen['zhuihuan'],'zhuihuan','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['kangge']=wrap(sgs.ai_skill_playerchosen['kangge'],'kangge','ai_skill_playerchosen')
sgs.ai_skill_invoke['kangge']=wrap(sgs.ai_skill_invoke['kangge'],'kangge','ai_skill_invoke')
sgs.ai_skill_invoke['jielie']=wrap(sgs.ai_skill_invoke['jielie'],'jielie','ai_skill_invoke')
sgs.ai_fill_skill['juguan']=wrap(sgs.ai_fill_skill['juguan'],'juguan','ai_fill_skill')
sgs.ai_skill_use_func['JuguanCard']=wrap(sgs.ai_skill_use_func['JuguanCard'],'JuguanCard','ai_skill_use_func')
sgs.ai_skill_invoke['quxi']=wrap(sgs.ai_skill_invoke['quxi'],'quxi','ai_skill_invoke')
sgs.ai_skill_use['@@quxi1']=wrap(sgs.ai_skill_use['@@quxi1'],'@@quxi1','ai_skill_use')
sgs.ai_skill_use['@@quxi2']=wrap(sgs.ai_skill_use['@@quxi2'],'@@quxi2','ai_skill_use')
sgs.ai_skill_use['@@quxi3']=wrap(sgs.ai_skill_use['@@quxi3'],'@@quxi3','ai_skill_use')
sgs.ai_skill_playerchosen['qigong']=wrap(sgs.ai_skill_playerchosen['qigong'],'qigong','ai_skill_playerchosen')
sgs.ai_fill_skill['liehou']=wrap(sgs.ai_fill_skill['liehou'],'liehou','ai_fill_skill')
sgs.ai_skill_use_func['LiehouCard']=wrap(sgs.ai_skill_use_func['LiehouCard'],'LiehouCard','ai_skill_use_func')
sgs.ai_skill_askforyiji['liehou']=wrap(sgs.ai_skill_askforyiji['liehou'],'liehou','ai_skill_askforyiji')
sgs.ai_fill_skill['tenyearshuhe']=wrap(sgs.ai_fill_skill['tenyearshuhe'],'tenyearshuhe','ai_fill_skill')
sgs.ai_skill_use_func['TenyearShuheCard']=wrap(sgs.ai_skill_use_func['TenyearShuheCard'],'TenyearShuheCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['tenyearshuhe']=wrap(sgs.ai_skill_playerchosen['tenyearshuhe'],'tenyearshuhe','ai_skill_playerchosen')
sgs.ai_skill_discard['tenyearliehou']=wrap(sgs.ai_skill_discard['tenyearliehou'],'tenyearliehou','ai_skill_discard')
sgs.ai_skill_invoke['langmie']=wrap(sgs.ai_skill_invoke['langmie'],'langmie','ai_skill_invoke')
sgs.ai_skill_cardask['@langmie-dis']=wrap(sgs.ai_skill_cardask['@langmie-dis'],'@langmie-dis','ai_skill_cardask')
sgs.ai_skill_choice['secondlangmie']=wrap(sgs.ai_skill_choice['secondlangmie'],'secondlangmie','ai_skill_choice')
sgs.ai_skill_cardask['@secondlangmie']=wrap(sgs.ai_skill_cardask['@secondlangmie'],'@secondlangmie','ai_skill_cardask')
sgs.ai_skill_cardask['@secondlangmie-damage']=wrap(sgs.ai_skill_cardask['@secondlangmie-damage'],'@secondlangmie-damage','ai_skill_cardask')
sgs.ai_skill_cardask['@secondlangmie-draw']=wrap(sgs.ai_skill_cardask['@secondlangmie-draw'],'@secondlangmie-draw','ai_skill_cardask')
sgs.ai_skill_use['@@tenyearhuoshui']=wrap(sgs.ai_skill_use['@@tenyearhuoshui'],'@@tenyearhuoshui','ai_skill_use')
sgs.ai_fill_skill['tenyearqingcheng']=wrap(sgs.ai_fill_skill['tenyearqingcheng'],'tenyearqingcheng','ai_fill_skill')
sgs.ai_skill_use_func['TenyearQingchengCard']=wrap(sgs.ai_skill_use_func['TenyearQingchengCard'],'TenyearQingchengCard','ai_skill_use_func')
sgs.ai_skill_invoke['tenyearqirang']=wrap(sgs.ai_skill_invoke['tenyearqirang'],'tenyearqirang','ai_skill_invoke')
sgs.ai_skill_playerchosen['tenyearqirang']=wrap(sgs.ai_skill_playerchosen['tenyearqirang'],'tenyearqirang','ai_skill_playerchosen')
sgs.ai_skill_invoke['koulve']=wrap(sgs.ai_skill_invoke['koulve'],'koulve','ai_skill_invoke')
sgs.ai_skill_invoke['secondkoulve']=wrap(sgs.ai_skill_invoke['secondkoulve'],'secondkoulve','ai_skill_invoke')
sgs.ai_skill_playerchosen['suirenq']=wrap(sgs.ai_skill_playerchosen['suirenq'],'suirenq','ai_skill_playerchosen')
sgs.ai_skill_invoke['fengshimf']=wrap(sgs.ai_skill_invoke['fengshimf'],'fengshimf','ai_skill_invoke')
sgs.ai_fill_skill['cuijian']=wrap(sgs.ai_fill_skill['cuijian'],'cuijian','ai_fill_skill')
sgs.ai_skill_use_func['CuijianCard']=wrap(sgs.ai_skill_use_func['CuijianCard'],'CuijianCard','ai_skill_use_func')
sgs.ai_fill_skill['secondcuijian']=wrap(sgs.ai_fill_skill['secondcuijian'],'secondcuijian','ai_fill_skill')
sgs.ai_skill_use_func['SecondCuijianCard']=wrap(sgs.ai_skill_use_func['SecondCuijianCard'],'SecondCuijianCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['secondtongyuan0']=wrap(sgs.ai_skill_playerchosen['secondtongyuan0'],'secondtongyuan0','ai_skill_playerchosen')
sgs.ai_skill_cardask['@chaofeng-discard']=wrap(sgs.ai_skill_cardask['@chaofeng-discard'],'@chaofeng-discard','ai_skill_cardask')
sgs.ai_skill_cardask['@secondchaofeng-discard']=wrap(sgs.ai_skill_cardask['@secondchaofeng-discard'],'@secondchaofeng-discard','ai_skill_cardask')
sgs.ai_skill_playerchosen['chuanshu']=wrap(sgs.ai_skill_playerchosen['chuanshu'],'chuanshu','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['secondchuanshu']=wrap(sgs.ai_skill_playerchosen['secondchuanshu'],'secondchuanshu','ai_skill_playerchosen')
sgs.ai_skill_invoke['chuanyun']=wrap(sgs.ai_skill_invoke['chuanyun'],'chuanyun','ai_skill_invoke')
sgs.ai_skill_invoke['xunde']=wrap(sgs.ai_skill_invoke['xunde'],'xunde','ai_skill_invoke')
sgs.ai_skill_cardask['@chenjie-card']=wrap(sgs.ai_skill_cardask['@chenjie-card'],'@chenjie-card','ai_skill_cardask')
sgs.ai_skill_invoke['jibing']=wrap(sgs.ai_skill_invoke['jibing'],'jibing','ai_skill_invoke')
sgs.ai_cardsview['jibing']=wrap(sgs.ai_cardsview['jibing'],'jibing','ai_cardsview')
sgs.ai_fill_skill['jibing']=wrap(sgs.ai_fill_skill['jibing'],'jibing','ai_fill_skill')
sgs.ai_skill_playerchosen['binghuo']=wrap(sgs.ai_skill_playerchosen['binghuo'],'binghuo','ai_skill_playerchosen')
sgs.ai_skill_cardask['@huantu-invoke']=wrap(sgs.ai_skill_cardask['@huantu-invoke'],'@huantu-invoke','ai_skill_cardask')
sgs.ai_skill_invoke['huantu']=wrap(sgs.ai_skill_invoke['huantu'],'huantu','ai_skill_invoke')
sgs.ai_skill_choice['huantu']=wrap(sgs.ai_skill_choice['huantu'],'huantu','ai_skill_choice')
sgs.ai_skill_invoke['bihuo']=wrap(sgs.ai_skill_invoke['bihuo'],'bihuo','ai_skill_invoke')
sgs.ai_skill_invoke['yachai']=wrap(sgs.ai_skill_invoke['yachai'],'yachai','ai_skill_invoke')
sgs.ai_skill_choice['yachai']=wrap(sgs.ai_skill_choice['yachai'],'yachai','ai_skill_choice')
sgs.ai_skill_choice['yachai_suit']=wrap(sgs.ai_skill_choice['yachai_suit'],'yachai_suit','ai_skill_choice')
sgs.ai_fill_skill['qingtan']=wrap(sgs.ai_fill_skill['qingtan'],'qingtan','ai_fill_skill')
sgs.ai_skill_use_func['QingtanCard']=wrap(sgs.ai_skill_use_func['QingtanCard'],'QingtanCard','ai_skill_use_func')
sgs.ai_skill_choice['qingtan']=wrap(sgs.ai_skill_choice['qingtan'],'qingtan','ai_skill_choice')
sgs.ai_skill_invoke['zhukou']=wrap(sgs.ai_skill_invoke['zhukou'],'zhukou','ai_skill_invoke')
sgs.ai_skill_use['@@zhukou']=wrap(sgs.ai_skill_use['@@zhukou'],'@@zhukou','ai_skill_use')
sgs.ai_skill_playerchosen['zhukou']=wrap(sgs.ai_skill_playerchosen['zhukou'],'zhukou','ai_skill_playerchosen')
sgs.ai_skill_choice['yuyun']=wrap(sgs.ai_skill_choice['yuyun'],'yuyun','ai_skill_choice')
sgs.ai_skill_playerchosen['yuyun']=wrap(sgs.ai_skill_playerchosen['yuyun'],'yuyun','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['yuyun_obtain']=wrap(sgs.ai_skill_playerchosen['yuyun_obtain'],'yuyun_obtain','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['yuyun_drawmaxhp']=wrap(sgs.ai_skill_playerchosen['yuyun_drawmaxhp'],'yuyun_drawmaxhp','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['zhenge']=wrap(sgs.ai_skill_playerchosen['zhenge'],'zhenge','ai_skill_playerchosen')
sgs.ai_skill_invoke['zhenge']=wrap(sgs.ai_skill_invoke['zhenge'],'zhenge','ai_skill_invoke')
sgs.ai_skill_use['@@zhenge!']=wrap(sgs.ai_skill_use['@@zhenge!'],'@@zhenge!','ai_skill_use')
sgs.ai_skill_cardask['@tianze-discard']=wrap(sgs.ai_skill_cardask['@tianze-discard'],'@tianze-discard','ai_skill_cardask')
sgs.ai_skill_cardask['@difa']=wrap(sgs.ai_skill_cardask['@difa'],'@difa','ai_skill_cardask')
sgs.ai_skill_invoke['zhuangshu']=wrap(sgs.ai_skill_invoke['zhuangshu'],'zhuangshu','ai_skill_invoke')
sgs.ai_skill_cardask['@zhuangshu-discard']=wrap(sgs.ai_skill_cardask['@zhuangshu-discard'],'@zhuangshu-discard','ai_skill_cardask')
sgs.ai_skill_use['@@chuiti']=wrap(sgs.ai_skill_use['@@chuiti'],'@@chuiti','ai_skill_use')
sgs.ai_skill_invoke['wanwei']=wrap(sgs.ai_skill_invoke['wanwei'],'wanwei','ai_skill_invoke')
sgs.ai_skill_invoke['yuejian']=wrap(sgs.ai_skill_invoke['yuejian'],'yuejian','ai_skill_invoke')
sgs.ai_fill_skill['zhuning']=wrap(sgs.ai_fill_skill['zhuning'],'zhuning','ai_fill_skill')
sgs.ai_skill_use_func['ZhuningCard']=wrap(sgs.ai_skill_use_func['ZhuningCard'],'ZhuningCard','ai_skill_use_func')
sgs.ai_skill_askforag['zhuning']=wrap(sgs.ai_skill_askforag['zhuning'],'zhuning','ai_skill_askforag')
sgs.ai_skill_use['@@zhuning']=wrap(sgs.ai_skill_use['@@zhuning'],'@@zhuning','ai_skill_use')
sgs.ai_fill_skill['pingxiang']=wrap(sgs.ai_fill_skill['pingxiang'],'pingxiang','ai_fill_skill')
sgs.ai_skill_use_func['PingxiangCard']=wrap(sgs.ai_skill_use_func['PingxiangCard'],'PingxiangCard','ai_skill_use_func')
sgs.ai_skill_use['@@pingxiang']=wrap(sgs.ai_skill_use['@@pingxiang'],'@@pingxiang','ai_skill_use')
sgs.ai_fill_skill['shouli']=wrap(sgs.ai_fill_skill['shouli'],'shouli','ai_fill_skill')
sgs.ai_skill_use_func['ShouliCard']=wrap(sgs.ai_skill_use_func['ShouliCard'],'ShouliCard','ai_skill_use_func')
sgs.ai_guhuo_card['shouli']=wrap(sgs.ai_guhuo_card['shouli'],'shouli','ai_guhuo_card')
sgs.ai_fill_skill['shencai']=wrap(sgs.ai_fill_skill['shencai'],'shencai','ai_fill_skill')
sgs.ai_skill_use_func['ShencaiCard']=wrap(sgs.ai_skill_use_func['ShencaiCard'],'ShencaiCard','ai_skill_use_func')
sgs.ai_skill_playerschosen['#xunshi']=wrap(sgs.ai_skill_playerschosen['#xunshi'],'#xunshi','ai_skill_playerschosen')
sgs.ai_skill_cardask['@tuoyu1']=wrap(sgs.ai_skill_cardask['@tuoyu1'],'@tuoyu1','ai_skill_cardask')
sgs.ai_skill_cardask['@tuoyu2']=wrap(sgs.ai_skill_cardask['@tuoyu2'],'@tuoyu2','ai_skill_cardask')
sgs.ai_skill_cardask['@tuoyu3']=wrap(sgs.ai_skill_cardask['@tuoyu3'],'@tuoyu3','ai_skill_cardask')
sgs.ai_skill_choice['xianjin']=wrap(sgs.ai_skill_choice['xianjin'],'xianjin','ai_skill_choice')
sgs.ai_skill_playerchosen['qijing']=wrap(sgs.ai_skill_playerchosen['qijing'],'qijing','ai_skill_playerchosen')
sgs.ai_skill_invoke['cuixin']=wrap(sgs.ai_skill_invoke['cuixin'],'cuixin','ai_skill_invoke')
sgs.ai_skill_playerchosen['tenyearyunjiu']=wrap(sgs.ai_skill_playerchosen['tenyearyunjiu'],'tenyearyunjiu','ai_skill_playerchosen')
sgs.ai_skill_invoke['tenyearmoshou']=wrap(sgs.ai_skill_invoke['tenyearmoshou'],'tenyearmoshou','ai_skill_invoke')
sgs.ai_skill_playerchosen['dangzhai']=wrap(sgs.ai_skill_playerchosen['dangzhai'],'dangzhai','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['shuangrui']=wrap(sgs.ai_skill_playerchosen['shuangrui'],'shuangrui','ai_skill_playerchosen')
sgs.ai_fill_skill['fuxie']=wrap(sgs.ai_fill_skill['fuxie'],'fuxie','ai_fill_skill')
sgs.ai_skill_use_func['FuxieCard']=wrap(sgs.ai_skill_use_func['FuxieCard'],'FuxieCard','ai_skill_use_func')
sgs.ai_skill_choice['fuxie']=wrap(sgs.ai_skill_choice['fuxie'],'fuxie','ai_skill_choice')
sgs.ai_fill_skill['shouxing']=wrap(sgs.ai_fill_skill['shouxing'],'shouxing','ai_fill_skill')
sgs.ai_skill_use_func['ShouxingCard']=wrap(sgs.ai_skill_use_func['ShouxingCard'],'ShouxingCard','ai_skill_use_func')
sgs.ai_skill_invoke['shaxue']=wrap(sgs.ai_skill_invoke['shaxue'],'shaxue','ai_skill_invoke')
sgs.ai_fill_skill['pingzhi']=wrap(sgs.ai_fill_skill['pingzhi'],'pingzhi','ai_fill_skill')
sgs.ai_skill_use_func['PingzhiCard']=wrap(sgs.ai_skill_use_func['PingzhiCard'],'PingzhiCard','ai_skill_use_func')
sgs.ai_skill_askforag['pingzhi']=wrap(sgs.ai_skill_askforag['pingzhi'],'pingzhi','ai_skill_askforag')
sgs.ai_skill_use['@@yinlu!']=wrap(sgs.ai_skill_use['@@yinlu!'],'@@yinlu!','ai_skill_use')
sgs.ai_skill_use['@@yinlu1']=wrap(sgs.ai_skill_use['@@yinlu1'],'@@yinlu1','ai_skill_use')
sgs.ai_skill_cardask['yl_lequan0']=wrap(sgs.ai_skill_cardask['yl_lequan0'],'yl_lequan0','ai_skill_cardask')
sgs.ai_skill_cardask['yl_huoxi0']=wrap(sgs.ai_skill_cardask['yl_huoxi0'],'yl_huoxi0','ai_skill_cardask')
sgs.ai_skill_cardask['yl_zhangqi0']=wrap(sgs.ai_skill_cardask['yl_zhangqi0'],'yl_zhangqi0','ai_skill_cardask')
sgs.ai_skill_cardask['yl_yunxiang0']=wrap(sgs.ai_skill_cardask['yl_yunxiang0'],'yl_yunxiang0','ai_skill_cardask')
sgs.ai_skill_invoke['yl_yunxiang']=wrap(sgs.ai_skill_invoke['yl_yunxiang'],'yl_yunxiang','ai_skill_invoke')
sgs.ai_skill_use['@@thshuliang']=wrap(sgs.ai_skill_use['@@thshuliang'],'@@thshuliang','ai_skill_use')
sgs.ai_skill_invoke['tanban']=wrap(sgs.ai_skill_invoke['tanban'],'tanban','ai_skill_invoke')
sgs.ai_skill_cardask['diou0']=wrap(sgs.ai_skill_cardask['diou0'],'diou0','ai_skill_cardask')
sgs.ai_skill_use['@@diou']=wrap(sgs.ai_skill_use['@@diou'],'@@diou','ai_skill_use')
sgs.ai_fill_skill['pinglu']=wrap(sgs.ai_fill_skill['pinglu'],'pinglu','ai_fill_skill')
sgs.ai_skill_use_func['PingluCard']=wrap(sgs.ai_skill_use_func['PingluCard'],'PingluCard','ai_skill_use_func')
sgs.ai_skill_invoke['feibai']=wrap(sgs.ai_skill_invoke['feibai'],'feibai','ai_skill_invoke')
sgs.ai_skill_invoke['zhengyue']=wrap(sgs.ai_skill_invoke['zhengyue'],'zhengyue','ai_skill_invoke')
sgs.ai_skill_use['@@zhengyue']=wrap(sgs.ai_skill_use['@@zhengyue'],'@@zhengyue','ai_skill_use')
sgs.ai_skill_invoke['zhantao']=wrap(sgs.ai_skill_invoke['zhantao'],'zhantao','ai_skill_invoke')
sgs.ai_skill_playerschosen['anjing']=wrap(sgs.ai_skill_playerschosen['anjing'],'anjing','ai_skill_playerschosen')
sgs.ai_skill_invoke['anjing']=wrap(sgs.ai_skill_invoke['anjing'],'anjing','ai_skill_invoke')
sgs.ai_skill_playerchosen['tg_wuyong']=wrap(sgs.ai_skill_playerchosen['tg_wuyong'],'tg_wuyong','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['tg_gangying']=wrap(sgs.ai_skill_playerchosen['tg_gangying'],'tg_gangying','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['tg_guojue']=wrap(sgs.ai_skill_playerchosen['tg_guojue'],'tg_guojue','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['tg_renzhi']=wrap(sgs.ai_skill_playerchosen['tg_renzhi'],'tg_renzhi','ai_skill_playerchosen')
sgs.ai_fill_skill['wanchan']=wrap(sgs.ai_fill_skill['wanchan'],'wanchan','ai_fill_skill')
sgs.ai_skill_use_func['WanchanCard']=wrap(sgs.ai_skill_use_func['WanchanCard'],'WanchanCard','ai_skill_use_func')
sgs.ai_skill_invoke['jiangzhi']=wrap(sgs.ai_skill_invoke['jiangzhi'],'jiangzhi','ai_skill_invoke')
sgs.ai_skill_playerchosen['jiangzhi']=wrap(sgs.ai_skill_playerchosen['jiangzhi'],'jiangzhi','ai_skill_playerchosen')
sgs.ai_fill_skill['thwuyan']=wrap(sgs.ai_fill_skill['thwuyan'],'thwuyan','ai_fill_skill')
sgs.ai_skill_use_func['ThWuyanCard']=wrap(sgs.ai_skill_use_func['ThWuyanCard'],'ThWuyanCard','ai_skill_use_func')
sgs.ai_skill_use['@@thwuyan']=wrap(sgs.ai_skill_use['@@thwuyan'],'@@thwuyan','ai_skill_use')
sgs.ai_skill_invoke['thwuyan']=wrap(sgs.ai_skill_invoke['thwuyan'],'thwuyan','ai_skill_invoke')
sgs.ai_skill_cardask['zhanyu0']=wrap(sgs.ai_skill_cardask['zhanyu0'],'zhanyu0','ai_skill_cardask')
sgs.ai_fill_skill['thzhengui']=wrap(sgs.ai_fill_skill['thzhengui'],'thzhengui','ai_fill_skill')
sgs.ai_skill_use_func['ThZhenguiCard']=wrap(sgs.ai_skill_use_func['ThZhenguiCard'],'ThZhenguiCard','ai_skill_use_func')
sgs.ai_fill_skill['jichun']=wrap(sgs.ai_fill_skill['jichun'],'jichun','ai_fill_skill')
sgs.ai_skill_use_func['JichunCard']=wrap(sgs.ai_skill_use_func['JichunCard'],'JichunCard','ai_skill_use_func')
sgs.ai_skill_invoke['hanying']=wrap(sgs.ai_skill_invoke['hanying'],'hanying','ai_skill_invoke')
sgs.ai_skill_playerchosen['hanying']=wrap(sgs.ai_skill_playerchosen['hanying'],'hanying','ai_skill_playerchosen')
sgs.ai_skill_invoke['jianjiang']=wrap(sgs.ai_skill_invoke['jianjiang'],'jianjiang','ai_skill_invoke')
sgs.ai_skill_choice['jianjiang']=wrap(sgs.ai_skill_choice['jianjiang'],'jianjiang','ai_skill_choice')
sgs.ai_skill_invoke['thjueyan']=wrap(sgs.ai_skill_invoke['thjueyan'],'thjueyan','ai_skill_invoke')
sgs.ai_fill_skill['yanzuo']=wrap(sgs.ai_fill_skill['yanzuo'],'yanzuo','ai_fill_skill')
sgs.ai_skill_use_func['YanzuoCard']=wrap(sgs.ai_skill_use_func['YanzuoCard'],'YanzuoCard','ai_skill_use_func')
sgs.ai_skill_use['@@yanzuo!']=wrap(sgs.ai_skill_use['@@yanzuo!'],'@@yanzuo!','ai_skill_use')
sgs.ai_skill_playerchosen['pijian']=wrap(sgs.ai_skill_playerchosen['pijian'],'pijian','ai_skill_playerchosen')
sgs.ai_skill_invoke['thqixin']=wrap(sgs.ai_skill_invoke['thqixin'],'thqixin','ai_skill_invoke')
sgs.ai_fill_skill['jiusi']=wrap(sgs.ai_fill_skill['jiusi'],'jiusi','ai_fill_skill')
sgs.ai_skill_use_func['JiusiCard']=wrap(sgs.ai_skill_use_func['JiusiCard'],'JiusiCard','ai_skill_use_func')
sgs.ai_guhuo_card['jiusi']=wrap(sgs.ai_guhuo_card['jiusi'],'jiusi','ai_guhuo_card')
sgs.ai_skill_invoke['chengyan']=wrap(sgs.ai_skill_invoke['chengyan'],'chengyan','ai_skill_invoke')
sgs.ai_skill_invoke['lianzhan']=wrap(sgs.ai_skill_invoke['lianzhan'],'lianzhan','ai_skill_invoke')
sgs.ai_skill_playerchosen['lianzhan']=wrap(sgs.ai_skill_playerchosen['lianzhan'],'lianzhan','ai_skill_playerchosen')
sgs.ai_fill_skill['manhou']=wrap(sgs.ai_fill_skill['manhou'],'manhou','ai_fill_skill')
sgs.ai_skill_use_func['ManhouCard']=wrap(sgs.ai_skill_use_func['ManhouCard'],'ManhouCard','ai_skill_use_func')
sgs.ai_skill_choice['manhou']=wrap(sgs.ai_skill_choice['manhou'],'manhou','ai_skill_choice')
sgs.ai_fill_skill['tanluan']=wrap(sgs.ai_fill_skill['tanluan'],'tanluan','ai_fill_skill')
sgs.ai_skill_use_func['TanluanCard']=wrap(sgs.ai_skill_use_func['TanluanCard'],'TanluanCard','ai_skill_use_func')
sgs.ai_skill_use['@@tanluan']=wrap(sgs.ai_skill_use['@@tanluan'],'@@tanluan','ai_skill_use')
sgs.ai_fill_skill['weiti']=wrap(sgs.ai_fill_skill['weiti'],'weiti','ai_fill_skill')
sgs.ai_skill_use_func['WeitiCard']=wrap(sgs.ai_skill_use_func['WeitiCard'],'WeitiCard','ai_skill_use_func')
sgs.ai_skill_invoke['yuanrong']=wrap(sgs.ai_skill_invoke['yuanrong'],'yuanrong','ai_skill_invoke')
sgs.ai_skill_askforag['yuanrong']=wrap(sgs.ai_skill_askforag['yuanrong'],'yuanrong','ai_skill_askforag')
sgs.ai_skill_use['@@yuanrong!']=wrap(sgs.ai_skill_use['@@yuanrong!'],'@@yuanrong!','ai_skill_use')
sgs.ai_skill_invoke['boxuan']=wrap(sgs.ai_skill_invoke['boxuan'],'boxuan','ai_skill_invoke')
sgs.ai_skill_playerchosen['boxuan']=wrap(sgs.ai_skill_playerchosen['boxuan'],'boxuan','ai_skill_playerchosen')
sgs.ai_skill_use['@@boxuan']=wrap(sgs.ai_skill_use['@@boxuan'],'@@boxuan','ai_skill_use')
sgs.ai_skill_playerschosen['thyizheng']=wrap(sgs.ai_skill_playerschosen['thyizheng'],'thyizheng','ai_skill_playerschosen')
sgs.ai_skill_playerchosen['thyizheng']=wrap(sgs.ai_skill_playerchosen['thyizheng'],'thyizheng','ai_skill_playerchosen')
sgs.ai_skill_use['@@guilin']=wrap(sgs.ai_skill_use['@@guilin'],'@@guilin','ai_skill_use')
sgs.ai_skill_playerschosen['thguying']=wrap(sgs.ai_skill_playerschosen['thguying'],'thguying','ai_skill_playerschosen')
sgs.ai_fill_skill['thmuzhen']=wrap(sgs.ai_fill_skill['thmuzhen'],'thmuzhen','ai_fill_skill')
sgs.ai_skill_use_func['ThMuzhenCard']=wrap(sgs.ai_skill_use_func['ThMuzhenCard'],'ThMuzhenCard','ai_skill_use_func')
sgs.ai_skill_choice['thmuzhen']=wrap(sgs.ai_skill_choice['thmuzhen'],'thmuzhen','ai_skill_choice')
sgs.ai_skill_invoke['chuanyu']=wrap(sgs.ai_skill_invoke['chuanyu'],'chuanyu','ai_skill_invoke')
sgs.ai_skill_use['@@chuanyu']=wrap(sgs.ai_skill_use['@@chuanyu'],'@@chuanyu','ai_skill_use')
sgs.ai_skill_playerchosen['chuanyu']=wrap(sgs.ai_skill_playerchosen['chuanyu'],'chuanyu','ai_skill_playerchosen')
sgs.ai_skill_use['@@chuanyu1']=wrap(sgs.ai_skill_use['@@chuanyu1'],'@@chuanyu1','ai_skill_use')
sgs.ai_skill_invoke['yitou']=wrap(sgs.ai_skill_invoke['yitou'],'yitou','ai_skill_invoke')
sgs.ai_skill_invoke['gengdu']=wrap(sgs.ai_skill_invoke['gengdu'],'gengdu','ai_skill_invoke')
sgs.ai_fill_skill['gengdu']=wrap(sgs.ai_fill_skill['gengdu'],'gengdu','ai_fill_skill')
sgs.ai_skill_use_func['GengduCard']=wrap(sgs.ai_skill_use_func['GengduCard'],'GengduCard','ai_skill_use_func')
sgs.ai_skill_askforag['gengdu']=wrap(sgs.ai_skill_askforag['gengdu'],'gengdu','ai_skill_askforag')
sgs.ai_skill_use['@@gengdu']=wrap(sgs.ai_skill_use['@@gengdu'],'@@gengdu','ai_skill_use')
sgs.ai_skill_invoke['gumai']=wrap(sgs.ai_skill_invoke['gumai'],'gumai','ai_skill_invoke')
sgs.ai_skill_choice['gumai']=wrap(sgs.ai_skill_choice['gumai'],'gumai','ai_skill_choice')
sgs.ai_skill_cardask['gumai0']=wrap(sgs.ai_skill_cardask['gumai0'],'gumai0','ai_skill_cardask')
sgs.ai_skill_invoke['pigua']=wrap(sgs.ai_skill_invoke['pigua'],'pigua','ai_skill_invoke')
sgs.ai_skill_use['@@jikun']=wrap(sgs.ai_skill_use['@@jikun'],'@@jikun','ai_skill_use')
sgs.ai_skill_invoke['dujun']=wrap(sgs.ai_skill_invoke['dujun'],'dujun','ai_skill_invoke')
sgs.ai_skill_playerchosen['dujun']=wrap(sgs.ai_skill_playerchosen['dujun'],'dujun','ai_skill_playerchosen')
sgs.ai_fill_skill['jieshi']=wrap(sgs.ai_fill_skill['jieshi'],'jieshi','ai_fill_skill')
sgs.ai_skill_use_func['JieshiCard']=wrap(sgs.ai_skill_use_func['JieshiCard'],'JieshiCard','ai_skill_use_func')
sgs.ai_skill_discard['jieshi']=wrap(sgs.ai_skill_discard['jieshi'],'jieshi','ai_skill_discard')
sgs.ai_skill_invoke['zhidui']=wrap(sgs.ai_skill_invoke['zhidui'],'zhidui','ai_skill_invoke')
sgs.ai_skill_choice['zhidui']=wrap(sgs.ai_skill_choice['zhidui'],'zhidui','ai_skill_choice')
sgs.ai_fill_skill['bizu']=wrap(sgs.ai_fill_skill['bizu'],'bizu','ai_fill_skill')
sgs.ai_skill_use_func['BizuCard']=wrap(sgs.ai_skill_use_func['BizuCard'],'BizuCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['wuxie']=wrap(sgs.ai_skill_playerchosen['wuxie'],'wuxie','ai_skill_playerchosen')
sgs.ai_skill_invoke['shuhe']=wrap(sgs.ai_skill_invoke['shuhe'],'shuhe','ai_skill_invoke')
sgs.ai_skill_choice['shuhe']=wrap(sgs.ai_skill_choice['shuhe'],'shuhe','ai_skill_choice')
sgs.ai_fill_skill['jilie']=wrap(sgs.ai_fill_skill['jilie'],'jilie','ai_fill_skill')
sgs.ai_skill_use_func['JilieCard']=wrap(sgs.ai_skill_use_func['JilieCard'],'JilieCard','ai_skill_use_func')
sgs.ai_skill_use['@@jilie']=wrap(sgs.ai_skill_use['@@jilie'],'@@jilie','ai_skill_use')
sgs.ai_skill_playerchosen['qingleng']=wrap(sgs.ai_skill_playerchosen['qingleng'],'qingleng','ai_skill_playerchosen')
sgs.ai_skill_invoke['qingleng']=wrap(sgs.ai_skill_invoke['qingleng'],'qingleng','ai_skill_invoke')
sgs.ai_skill_discard['dandu']=wrap(sgs.ai_skill_discard['dandu'],'dandu','ai_skill_discard')
sgs.ai_skill_use['@@quxian']=wrap(sgs.ai_skill_use['@@quxian'],'@@quxian','ai_skill_use')
sgs.ai_skill_cardask['huachang0']=wrap(sgs.ai_skill_cardask['huachang0'],'huachang0','ai_skill_cardask')
sgs.ai_skill_cardask['yuzhi0']=wrap(sgs.ai_skill_cardask['yuzhi0'],'yuzhi0','ai_skill_cardask')
sgs.ai_fill_skill['zuoyi']=wrap(sgs.ai_fill_skill['zuoyi'],'zuoyi','ai_fill_skill')
sgs.ai_skill_use_func['ZuoyiCard']=wrap(sgs.ai_skill_use_func['ZuoyiCard'],'ZuoyiCard','ai_skill_use_func')
sgs.ai_skill_choice['zuoyi']=wrap(sgs.ai_skill_choice['zuoyi'],'zuoyi','ai_skill_choice')
sgs.ai_skill_playerchosen['zuoyi']=wrap(sgs.ai_skill_playerchosen['zuoyi'],'zuoyi','ai_skill_playerchosen')
sgs.ai_skill_invoke['yanxi']=wrap(sgs.ai_skill_invoke['yanxi'],'yanxi','ai_skill_invoke')
sgs.ai_skill_discard['yuxian']=wrap(sgs.ai_skill_discard['yuxian'],'yuxian','ai_skill_discard')
sgs.ai_skill_invoke['yuxian']=wrap(sgs.ai_skill_invoke['yuxian'],'yuxian','ai_skill_invoke')
sgs.ai_skill_playerchosen['minshan']=wrap(sgs.ai_skill_playerchosen['minshan'],'minshan','ai_skill_playerchosen')
sgs.ai_skill_invoke['fuhui']=wrap(sgs.ai_skill_invoke['fuhui'],'fuhui','ai_skill_invoke')
sgs.ai_fill_skill['fuhui']=wrap(sgs.ai_fill_skill['fuhui'],'fuhui','ai_fill_skill')
sgs.ai_skill_use_func['FuhuiCard']=wrap(sgs.ai_skill_use_func['FuhuiCard'],'FuhuiCard','ai_skill_use_func')
sgs.ai_cardsview['fuhui']=wrap(sgs.ai_cardsview['fuhui'],'fuhui','ai_cardsview')
sgs.ai_skill_playerchosen['tenyearmumu']=function(self)local name,ok=self:getStrategyMemory("tenyear_hc.target_override:tenyearmumu");if not ok then ai_unsupported("source dynamic target writer not observed","tenyearmumu")end;return known(self.room:findPlayerByObjectName(name,true),"source dynamic target")end
sgs.ai_skill_playerchosen['secondtenyearmumu']=function(self)local name,ok=self:getStrategyMemory("tenyear_hc.target_override:secondtenyearmumu");if not ok then ai_unsupported("source dynamic target writer not observed","secondtenyearmumu")end;return known(self.room:findPlayerByObjectName(name,true),"source dynamic target")end

-- External literal writers in scarlet-ai.lua (fixed lines 728/1115/2997).
-- Native immutable source-identity witnesses decide whether each alias existed.
ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.s4_longhun",registry="ai_choicemade_filter",path={"cardChosen","s4_longhun"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","peiqi"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.s4_yuezhe",registry="ai_choicemade_filter",path={"cardChosen","s4_yuezhe"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","peiqi"},self_index=1,defer_canonical=true}
ai_audited_aliases.register{id="ai_skill_invoke.s4_txbw_niansheng",registry="ai_skill_invoke",path={"s4_txbw_niansheng"},canonical_registry="ai_skill_invoke",canonical_path={"luanfeng"},self_index=1,defer_canonical=true}

-- Source global string dispatch cannot be replaced by viewer memory/default RNG.
-- No actual-global read is authorized until foreign writer-capable entry proof.
sgs.ai_skill_choice.zunwei=function(self)
 ai_unsupported('Zunwei actual global choice provenance is unavailable across questions','zunwei')
end
