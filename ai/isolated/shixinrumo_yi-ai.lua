local PACKAGE="shixinrumo_yi"
local SELECTORS={["#yisiguCard"]="yisigu",["#yizhengsiCard"]="yizhengsi",["#yihuiceCard"]="yihuice",["#manchanyuCard"]="manchanyu",["#manquchiCard"]="manquchi",["#chenxiangerCard"]="chenxianger",["#chenwanliCard"]="chenwanli",["#chenfubeiCard"]="chenfubei",["#chenlanjiaoCard"]="chenlanjiao",["#chenfusuiCard"]="chenfusui"}
-- Package-private source clone state. These plain records are not cards or receipts.
local active_requests=setmetatable({},{__mode="k"})
local clone_states=setmetatable({},{__mode='k'})
local function unsupported(key)ai_unsupported('source capability is not projected',PACKAGE..'.'..key)end
local function raw_call(o,k,...)
 if not o or type(o[k])~='function' then unsupported(k)end
 local v=table.pack(o[k](o,...));if AIUnsupported.is(v[1])then error(v[1],0)end;return table.unpack(v,1,v.n)
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
 else card=raw_call(s.self,'evaluateSkillCard',s.skill,s.name,s.costs)end
 if not card then unsupported('clone.'..s.skill..'.'..s.name)end
 -- Current narrow endpoint has no arbitrary face parameters. A mismatched native
 -- clone is unknown, never a substitute with different suit/rank.
 if #s.costs==0 and (raw_call(card,'getSuit')~=s.suit or raw_call(card,'getNumber')~=s.number)then unsupported('clone_face.'..s.skill)end
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

local function peiqi(self,data)
 local fn=sgs.ai_skill_invoke.peiqi;if type(fn)~="function"then ai_unsupported("source peiqi callback unavailable","shixinrumo_yi.peiqi")end
 local value=fn(self,data);if AIUnsupported.is(value)then error(value,0)end
 if self.peiqiData then local d=self.peiqiData;package_call(self,"setStrategyMemory","shixinrumo_yi.peiqi",{from=d.from and package_known(d.from,"objectName"),to=d.to and package_known(d.to,"objectName"),cid=d.cid})end;return value
end
local function peiqi_state(self)
 if self.peiqiData then return self.peiqiData end
 local d,known=package_call(self,"getStrategyMemory","shixinrumo_yi.peiqi");if not known or type(d)~="table"then ai_unsupported("source peiqi state is unobserved","shixinrumo_yi.peiqi")end
 return{from=d.from and package_known(self.room,"findPlayerByObjectName",d.from,true),to=d.to and package_known(self.room,"findPlayerByObjectName",d.to,true),cid=d.cid}
end

local function source_callback(self,registry,key)
 -- Donor callback presence: this VM's own registry is authoritative.
 local fn=sgs[registry][key]
 if fn==nil then return nil end
 if fn==false then return false end
 if type(fn)~="function"then error("attempt to call a "..type(fn).." value",0)end
 if ai_audited_aliases and type(ai_audited_aliases.resolve)=="function"then fn=ai_audited_aliases.resolve(self,fn)end
 if type(fn)~="function"then unsupported("chenbiyi_callback."..key)end
 return fn
end


sgs.ai_skill_invoke.yikuxin = function(self,data)
	return package_known(self,"canDraw")
end

sgs.ai_skill_playerchosen.yikuxin = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
	local has = false
	local ids = source_fact(self,"yikuxinIds","toIntList")
	for _,id in sgs.list(ids)do
		if package_known(self,"getKnownCardById",id):getSuit()==2 then has = true end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p)
		and package_known(p,"getHandcardNum")>package_known(ids,"length")
		and getKnownCard(p,self.player,"heart","h")>0
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and not has
		and getKnownCard(p,self.player,"heart","h")>0
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and not has
		then return p end
	end
end

sgs.ai_fill_skill.yisigu = function(self,inclusive,request)
	return source_skill(self,"#yisiguCard:.:")
end

sgs.ai_skill_use_func["#yisiguCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if package_known(self,"damageIsEffective",ep,"N",self.player) then
			use.card = card
			package_call(use.to,"append",ep)
			return
		end
	end
	package_call(self,"sort",self.friends_noself,nil,true)
	for i,p in sgs.list(self.friends_noself)do
		if i<#self.friends/2 and not package_known(self,"isWeak",p)
		and package_known(self,"damageIsEffective",p,"N",self.player) then
			use.card = card
			package_call(use.to,"append",p)
			return
		end
	end
end

sgs.ai_use_value.yisiguCard = 3.4
sgs.ai_use_priority.yisiguCard = 0.2

sgs.ai_fill_skill.yimiehai = function(self,inclusive,request)
    local cards = package_known(self.player,"getCards","he")
    cards = sgs.QList2Table(cards)
    package_call(self,"sortByKeepValue",cards)
	local dc = clone(self,"yj_stabs_slash","yimiehai")
	for i,c1 in sgs.list(cards)do do
		if table.contains(self.toUse,c1)
		or package_known(self,"getKeepValue",c1)>6 then goto package_continue_1 end
		for n,c2 in sgs.list(cards)do do
			if table.contains(self.toUse,c1)
			or package_known(self,"getKeepValue",c1)>6 then goto package_continue_2 end
			if i>n then
				package_call(dc,"addSubcard",c1)
				package_call(dc,"addSubcard",c2)
				if package_known(dc,"isAvailable",self.player)
				then return dc end
				package_call(dc,"clearSubcards")
			end
		end ::package_continue_2:: end
	end ::package_continue_1:: end
end

function sgs.ai_cardsview.yimiehai(self,class_name,player)
    local cards = package_known(player,"getCards","he")
    cards = sgs.QList2Table(cards)
    package_call(self,"sortByKeepValue",cards)
	local dc = clone(self,"yj_stabs_slash","yimiehai")
	for i,c1 in sgs.list(cards)do
		for n,c2 in sgs.list(cards)do
			if i>n then
				package_call(dc,"addSubcard",c1)
				package_call(dc,"addSubcard",c2)
				if package_known(dc,"isAvailable",player)
				then return proposal(self,dc) end
				package_call(dc,"clearSubcards")
			end
		end
	end
end

sgs.ai_skill_choice.shefu = function(self,choices)
	local items = package_known(choices,"split","+")
	return items[1]
end

sgs.ai_skill_playerchosen.yiqingjun = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
end

sgs.ai_skill_invoke.yijugu = function(self,data)
	return #self.enemies>0
end

sgs.ai_skill_playerchosen.yijugu = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"doDisCard",p,"he",true)
		then return p end
	end
end

sgs.ai_skill_invoke.yichengming = function(self,data)
	return #self.enemies>0
end

sgs.ai_fill_skill.yizhengsi = function(self,inclusive,request)
	return source_skill(self,"#yizhengsiCard:.:")
end

sgs.ai_skill_use_func["#yizhengsiCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if package_known(ep,"getHandcardNum")>0 and package_known(use.to,"isEmpty")
		then package_call(use.to,"append",ep) end
	end
	if package_known(use.to,"length")==1 then
		package_call(use.to,"append",self.player)
	end
	for i,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
		if not package_known(self,"isFriend",p) and not package_known(use.to,"contains",p)
		and package_known(use.to,"length")==2 and package_known(p,"getHandcardNum")>0 then
			package_call(use.to,"append",p)
			use.card = card
		end
	end
end

sgs.ai_use_value.yizhengsiCard = 3.4
sgs.ai_use_priority.yizhengsiCard = 4.2

sgs.ai_fill_skill.yihuice = function(self,inclusive,request)
	return source_skill(self,"#yihuiceCard:.:")
end

sgs.ai_skill_use_func["#yihuiceCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies)
	for _,p in sgs.list(self.enemies)do
		if package_known(self.player,"canPindian",p) and package_known(use.to,"length")<2
		then package_call(use.to,"append",p) end
	end
	for i,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
		if not package_known(self,"isFriend",p) and not package_known(use.to,"contains",p)
		and package_known(use.to,"length")<2 and package_known(self.player,"canPindian",p) then
			package_call(use.to,"append",p)
		end
	end
	if package_known(use.to,"length")==2 then
		use.card = card
	end
end

sgs.ai_use_value.yihuiceCard = 3.4
sgs.ai_use_priority.yihuiceCard = 4.2

sgs.ai_skill_invoke.yiqianliu = function(self,data)
	return #self.enemies>0
end

sgs.ai_skill_playerchosen.yimitu = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if package_known(self,"isEnemy",target)
		then return target end
	end
end

sgs.ai_skill_playerschosen.yimitu = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) and package_known(self,"canDraw",p)
		and #tps<x and #tps<package_known(self.player,"getLostHp")
		and #self.enemies>0 then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_invoke.yimitu = function(self,data)
	local ts = package_known(data,"toString"):split(":")
	return package_known(self,"isEnemy",package_known(self.room,"findPlayerByObjectName",ts[2],true))
end

sgs.ai_skill_playerchosen.yichengbian = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
	local dc = clone(self,"duel","_yichengbian")
	local d = package_known(self,"aiUseCard",dc)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(d.to,"contains",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(self,"hasTrickEffective",dc,p,self.player)
		then return p end
	end
end

sgs.ai_skill_discard.yichengbian = function(self)
	if package_known(self,"getCardsNum","Slash")>0 then return {} end
	local cards = {}
    local handcards = sgs.QList2Table(package_known(self.player,"getCards","h"))
    package_call(self,"sortByKeepValue",handcards)
   	for _,h in sgs.list(handcards)do
		table.insert(cards,package_known(h,"getEffectiveId"))
		if #cards>=#handcards/2 then break end
	end
	return cards
end

sgs.ai_skill_invoke.yiduibian = function(self,data)
	local damage = package_known(data,"toDamage")
	return #self.enemies>0 and (package_known(self,"isWeak") or package_known(self,"isEnemy",damage.from))
end

sgs.ai_skill_invoke.yiduibian0 = function(self,data)
	local ts = package_known(data,"toString"):split(":")
	return package_known(self,"isEnemy",package_known(self.room,"findPlayerByObjectName",ts[2],true))
end

sgs.ai_skill_playerschosen.yizongheng = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #tps<x
		then table.insert(tps,p) end
	end
	return #tps>1 and tps
end

sgs.ai_skill_playerchosen.manhanguo = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(p,"getCardCount")>0
		and package_known(self.player,"inMyAttackRange",p)
		then return p end
	end
end

sgs.ai_skill_playerschosen.manweiwo = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) and #tps<x
		then table.insert(tps,p) end
	end
	if #tps<2 then return {} end
	return tps
end

ai_skill_use["@@manhaibian"]=function(self,prompt,request)
    local dc = clone(self,"duel")
	package_call(dc,"setSkillName","manhaibian")
    local d = package_known(self,"aiUseCard",dc)
   	if d.card then
      	if package_known(dc,"canRecast") and package_known(d.to,"length")<1 then return end
      	local tos = {}
       	for _,p in sgs.qlist(d.to)do
       		table.insert(tos,package_known(p,"objectName"))
       	end
       	return selected(self,dc,tos)
    end
end

sgs.ai_fill_skill.manchanyu = function(self,inclusive,request)
	return source_skill(self,"#manchanyuCard:.:")
end

sgs.ai_skill_use_func["#manchanyuCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		if package_known(use.to,"length")<1 then
			package_call(use.to,"append",p)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.manchanyuCard = 3.4
sgs.ai_use_priority.manchanyuCard = 5.2

sgs.ai_skill_choice.manchanyu = function(self,choices)
	local items = package_known(choices,"split","+")
	local s2n = {}
	for _,c in sgs.qlist(package_known(self.player,"getHandcards"))do
		s2n[package_known(c,"getColorString")] = (s2n[package_known(c,"getColorString")] or 0)+1
		s2n[package_known(c,"getType")] = (s2n[package_known(c,"getType")] or 0)+1
	end
	local x = 999
    for s,n in pairs(s2n)do
		x = math.min(x,n)
	end
    for s,n in pairs(s2n)do
		if x>=n then
			return s
		end
	end
	return items[1]
end

sgs.ai_skill_invoke.mancongfeng = function(self,data)
	local tp = package_call(data,"toPlayer")
	if package_known(self.player,"getChangeSkillState","mancongfeng")==1 then
		return package_known(self,"isFriend",tp) and package_known(self,"canDraw",tp)
	else
		return package_known(self,"doDisCard",tp,"he")
	end
end

sgs.ai_target_revises.mankongzhi = function(to,card,self)
    if package_known(card,"isNDTrick") and package_known(to,"isWounded") then
		return true
	end
end

sgs.ai_skill_invoke.manbizha = function(self,data)
	return package_known(self,"canDraw") and package_known(self,"getOverflow")>=0
end

sgs.ai_skill_playerchosen.manbizha = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p)
		then return p end
	end
end

ai_skill_use["@@manbizha"]=function(self,prompt,request)
	local cs = {}
    for _,id in sgs.qlist(package_known(self.player,"getNotifiedTag","manbizhaForAI"))do
      	local c = package_known(self,"getKnownCardById",id)
		if package_known(self.player,"getStrategyMark","manbizhaNum")>package_known(c,"getNumber")
		and package_known(c,"isAvailable",self.player)
		then table.insert(cs,c) end
	end
    package_call(self,"sortByUsePriority",cs)
	for _,c in sgs.list(cs)do
      	local d = package_known(self,"aiUseCard",c)
		if d.card then
			if package_known(c,"canRecast") and package_known(d.to,"length")<1 then return end
			local tos = {}
			for _,p in sgs.list(d.to)do
				table.insert(tos,package_known(p,"objectName"))
			end
			return selected(self,c,tos)
		end
	end
end

sgs.ai_skill_playerchosen.mannuozhan = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p)
		then return p end
	end
end

sgs.ai_skill_invoke.mannuozhan = function(self,data)
	return not package_known(self,"isWeak") and package_known(self,"isEnemy",package_call(data,"toPlayer"))
end

sgs.ai_skill_playerschosen.manhuaibing = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_playerschosen.manhuoe = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x and package_known(self,"isEnemy",p)
		then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_playerchosen.manhuoe = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) and package_known(self,"canDraw",p)
		then return p end
	end
end

sgs.ai_skill_playerschosen.mansuwu = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_fill_skill.manrenwang = function(self,inclusive,request)
    local cards = package_known(self.player,"getCards","he")
    cards = sgs.QList2Table(cards)
    package_call(self,"sortByKeepValue",cards)
	for _,c in sgs.list(cards)do do
		if table.contains(self.toUse,c) or not package_known(c,"hasFlag","link_card")
		or package_known(self,"getKeepValue",c)>6 then goto package_continue_3 end
		local dc = clone(self,"peach","manrenwang")
		package_call(dc,"addSubcard",c)
		if package_known(dc,"isAvailable",self.player)
		then return dc end
	end ::package_continue_3:: end
end

sgs.ai_guhuo_card.manrenwang = function(self,card_name,class_name)
    if package_known(self,"getCardsNum",class_name)<1 then
		local cards = package_known(self.player,"getCards","he")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards)
		for _,c in sgs.list(cards)do do
			if not package_known(c,"hasFlag","link_card")
			or package_known(self,"getKeepValue",c)>6 then goto package_continue_4 end
			local dc = clone(self,"peach","manrenwang")
			package_call(dc,"addSubcard",c)
			return proposal(self,dc)
		end ::package_continue_4:: end
	end
end

sgs.ai_fill_skill.manquchi = function(self,inclusive,request)
	return source_skill(self,"#manquchiCard:.:")
end

sgs.ai_skill_use_func["#manquchiCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies)
	for _,p in sgs.list(self.enemies)do
		if package_known(self,"damageIsEffective",p,"F",self.player) then
			for _,c in sgs.list(getKnownCards(p,self.player,"h"))do
				if package_known(c,"hasFlag","link_card") then
					package_call(use.to,"append",p)
					use.card = card
					return
				end
			end
		end
	end
	for _,p in sgs.list(self.enemies)do
		if package_known(self,"damageIsEffective",p,"F",self.player) then
			package_call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.manquchiCard = 3.4
sgs.ai_use_priority.manquchiCard = 5.2


sgs.ai_skill_invoke.chenjiehuo = function(self,data)
	for _,c in sgs.list(package_known(self,"getCards","Duel,FireAttack","he"))do
		local d = package_known(self,"aiUseCard",c)
		if d.card and package_known(self,"isEnemy",package_known(d.to,"at",0)) then
			return true
		end
	end
	for _,c in sgs.list(package_known(self,"getCards","Slash","he"))do
		local d = package_known(self,"aiUseCard",c)
		if d.card and package_known(self,"isEnemy",package_known(d.to,"at",0)) and getCardsNum("Jink",package_known(d.to,"at",0),self.player)<1 then
			return true
		end
	end
	return package_known(self,"isWeak") and #self.enemies>0
end

sgs.ai_fill_skill.chenxianger = function(self,inclusive,request)
	return source_skill(self,"#chenxiangerCard:.:")
end

sgs.ai_skill_use_func["#chenxiangerCard"] = function(card,use,self,request)
	local p2n = {}
	for _,c in sgs.list(package_known(self,"addHandPile"))do
		if package_known(c,"isDamageCard") then
			for _,p in sgs.list(package_known(self,"aiUseCard",c).to)do
				p2n[package_known(p,"objectName")] = (p2n[package_known(p,"objectName")] or 0)+1
			end
		end
	end
	package_call(self,"sort",self.enemies)
	for _,p in sgs.list(self.enemies)do
		if p2n[package_known(p,"objectName")] and p2n[package_known(p,"objectName")]>1 then
			package_call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.chenxiangerCard = 6.4
sgs.ai_use_priority.chenxiangerCard = 7.2

sgs.ai_skill_playerchosen.chenmieguo = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"doDisCard",p,"he")
		then return p end
	end
end

sgs.ai_skill_playerschosen.chenmieguo = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x and package_known(self,"isFriend",p) then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_playerchosen.chenbingqu = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
    for i,p in sgs.list(destlist)do
		if i<#destlist/2 and package_known(self,"isEnemy",p)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if i>#destlist/2 and package_known(self,"isFriend",p)
		then return p end
	end
	return destlist[1]
end

sgs.ai_skill_choice.chenbingqu = function(self,choices,data)
	local items = package_known(choices,"split","+")
	local cs = {}
	for s,cn in ipairs(items)do
		table.insert(cs,clone(self,cn))
	end
    package_call(self,"sortByKeepValue",cs)
	if(package_known(self,"isFriend",package_call(data,"toPlayer")))then
		return package_known(cs[math.random(#cs/2,#cs)],"objectName")
	end
	return package_known(cs[math.random(1,#cs/2)],"objectName")
end

sgs.ai_skill_playerchosen.chenfanxin = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
end


sgs.ai_skill_playerchosen.chenxiezhong = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for i,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
	return destlist[#destlist]
end

sgs.ai_skill_invoke.chenqishi = function(self,data)
	return package_known(data,"toIntList"):length()>1 and package_known(self,"canDraw")
end

ai_skill_use["@@chenwanli"]=function(self,prompt,request)
    local cards = package_known(self.player,"getCards","he")
    cards = sgs.QList2Table(cards)
    package_call(self,"sortByKeepValue",cards)
	local cs = {}
    for i,c in sgs.list(cards)do
		if i<#cards/2 then
			table.insert(cs,package_known(c,"getEffectiveId"))
		end
	end
	package_call(self,"sort",self.enemies)
	for _,p in sgs.list(self.enemies)do
		return response_skill(self,"#chenwanliCard",cs,{package_known(p,"objectName")},request)
	end
end

sgs.ai_skill_playerchosen.chenlishuo = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for i,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
end

sgs.ai_skill_invoke.chenlishuo = function(self,data)
	return package_known(self,"canDraw")
end

sgs.ai_fill_skill.chenfubei = function(self,inclusive,request)
	return source_skill(self,"#chenfubeiCard:.:")
end

sgs.ai_skill_use_func["#chenfubeiCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value.chenfubeiCard = 6.4
sgs.ai_use_priority.chenfubeiCard = 7.2

-- Exact fixed nil-target edge, scoped to these two stored-Damage consumers.
-- Keep normal dynamic dispatch; only the known installed facade's nil result
-- needs the donor managed-mode/list boundary restored.
local chendancui_enemy_provider=SmartAIView.isEnemy
local function chendancui_enemy(self,target)
    local provider=self.isEnemy
    local result=package_call(self,"isEnemy",target)
    if result~=nil then return result end
    if target~=nil or provider~=chendancui_enemy_provider then unsupported("chendancui.isEnemy") end
    local mode=self.world and self.world.mode_policy
    if type(mode)~="table" or mode.managed~=true or mode.error~=nil then unsupported("chendancui.nil_enemy_mode") end
    if mode.legacy_managed==true then return false end
    if mode.legacy_base_update~=true then unsupported("chendancui.nil_enemy_provider") end
    if not AIValue.isList(self.enemies) then unsupported("chendancui.nil_enemy_list") end
    if #self.enemies<1 then return false end
    local missing=nil
    return missing:objectName() -- Original aiPlayerInList's ordinary nil error.
end

sgs.ai_skill_invoke.chendancui = function(self,data)
	local damage = source_fact(self,"chendancuiData","toDamage")
	return chendancui_enemy(self,damage.to)
end

sgs.ai_skill_discard.chendancui = function(self)
	local damage = source_fact(self,"chendancuiData","toDamage")
	if not chendancui_enemy(self,damage.to) then return {} end
	local cards = {}
    local handcards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    package_call(self,"sortByKeepValue",handcards)
   	for _,h in sgs.list(handcards)do
		table.insert(cards,package_known(h,"getEffectiveId"))
		if #cards>1 then return cards end
	end
	return {}
end

sgs.ai_fill_skill.chenlanjiao = function(self,inclusive,request)
	return source_skill(self,"#chenlanjiaoCard:.:")
end

sgs.ai_skill_use_func["#chenlanjiaoCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies)
	for _,p in sgs.list(self.enemies)do
		if package_known(self.player,"getStrategyMark",package_known(p,"objectName").."chenlanjiaoBan-Clear")<1 then
			package_call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.chenlanjiaoCard = 3.4
sgs.ai_use_priority.chenlanjiaoCard = 5.2

sgs.ai_skill_invoke.chenlanjiao = function(self,data)
	local ids = source_fact(self,"chenlanjiaoIds","toIntList")
    local handcards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    package_call(self,"sortByKeepValue",handcards)
	for i,c in sgs.list(handcards)do
		if i>#handcards/2 and package_known(ids,"contains",package_known(c,"getId")) and not package_known(self,"isWeak") then
			return true
		end
	end
	return package_known(self.player,"hasSkill","kurou")
end

sgs.ai_skill_invoke.chenyangbei = function(self,data)
	local srt = package_known(data,"toString")
	if srt~="" then
		for i,p in sgs.list(self.enemies)do
			if package_known(srt,"endsWith",package_known(p,"objectName")) and not package_known(self,"isWeak") then
				return true
			end
		end
	else
		return package_known(self,"canDraw")
	end
end

sgs.ai_skill_playerchosen.chenjiaozong = function(self,players)
	if peiqi(self) then
		for i,p in sgs.list(players)do
			if peiqi_state(self).from==p
			then return p end
		end
	end
end

sgs.ai_skill_playerchosen.chenjiaozong1 = function(self,players)
	if peiqi(self) then
		for i,p in sgs.list(players)do
			if peiqi_state(self).to==p
			then return p end
		end
	end
end

sgs.ai_skill_cardchosen.chenjiaozong = function(self,who,flags,method)
   	for _,c in sgs.list(package_known(who,"getCards",flags))do
		if package_known(c,"getId")==peiqi_state(self).cid
		then return package_known(c,"getId") end
	end
end

sgs.ai_fill_skill.chenfusui = function(self,inclusive,request)
	return source_skill(self,"#chenfusuiCard:.:")
end

sgs.ai_skill_use_func["#chenfusuiCard"] = function(card,use,self,request)
	local aps = package_known(self.room,"getAlivePlayers")
	aps = package_call(self,"sort",aps)
	for i,p in sgs.list(aps)do
		if i>#aps/2 and package_known(p,"isMale") and package_known(self,"isEnemy",p) then
			for _,s in sgs.qlist(package_known(p,"getVisibleSkillList"))do do
				if package_known(s,"isAttachedLordSkill") then goto package_continue_5 end
				local pt = package_known(self,"round50SkillDescription",s,p)
				if package_known(pt,"contains","技，") then goto package_continue_5 end
				package_call(use.to,"append",p)
				use.card = card
				return
			end ::package_continue_5:: end
		end
	end
	for i,p in sgs.list(aps)do
		if i<#aps/2 and package_known(p,"isMale") and package_known(self,"isFriend",p) then
			for _,s in sgs.qlist(package_known(p,"getVisibleSkillList"))do do
				if package_known(s,"isAttachedLordSkill") then goto package_continue_6 end
				local pt = package_known(self,"round50SkillDescription",s,p)
				if package_known(pt,"contains","技，") then goto package_continue_6 end
				package_call(use.to,"append",p)
				use.card = card
				return
			end ::package_continue_6:: end
		end
	end
end

sgs.ai_use_value.chenfusuiCard = 3.4
sgs.ai_use_priority.chenfusuiCard = 5.2

-- The viewer's own property, read like the donor's toString() (absent reads "").
local function chenbiyi_skill(self)return self.player:getPropertyValue("chenbiyi_skill")or""end
sgs.ai_fill_skill.chenbiyi = function(self,inclusive,request)
	local f=source_callback(self,"ai_fill_skill",chenbiyi_skill(self))
	return f and f(self)
end

sgs.ai_guhuo_card.chenbiyi = function(self,card_name,class_name)
	local f=source_callback(self,"ai_guhuo_card",chenbiyi_skill(self))
	return f and f(self,card_name,class_name)
end

function sgs.ai_cardsview.chenbiyi(self,class_name,player)
	local f=source_callback(self,"ai_cardsview",chenbiyi_skill(self))
	return f and f(self,class_name,player)
end

for _,key in ipairs({"yisigu","yimiehai","yizhengsi","yihuice","manchanyu","manrenwang","manquchi","chenxianger","chenfubei","chenlanjiao","chenfusui","chenbiyi"})do local fn=sgs.ai_fill_skill[key];sgs.ai_fill_skill[key]=function(self,inclusive,request)local old=active_requests[self];active_requests[self]=request;local ok,v=pcall(fn,self,inclusive,request);active_requests[self]=old;if not ok then error(v,0)end;return finish_turn(self,v,request)end end
