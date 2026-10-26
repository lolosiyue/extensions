-- Source: b6025acc ai/tenyear_xd-ai.lua.
local known = AIValue.requireKnown
local function hydrate_context(self,value,kind)
 if value==nil then return nil end
 if kind=='Player' then
  if AIValue.isPlayer(value)then return value end
  return known(self.room:findPlayerByObjectName(value,true),'context.player:'..tostring(value))
 end
 if kind=='Card'then
  if AIValue.isCard(value)or AIValue.isConversion(value)then return value end
  return CardView.new(value,self.room)
 end
 if kind=='Bool'or kind=='String'or kind=='Int'then return value end
 if kind=='IntList'then return AIList.new(value)end
 local row={};for k,v in pairs(value)do row[k]=v end
 for _,k in ipairs{'from','who','m_who'}do if value[k]then row[k]=hydrate_context(self,value[k],'Player')end end
 for _,k in ipairs{'card','whocard','m_card','m_toCard'}do if value[k]then row[k]=hydrate_context(self,value[k],'Card')end end
 if kind=='CardUse'then row.to=AIList.new({});for _,v in ipairs(value.to or{})do row.to:append(hydrate_context(self,v,'Player'))end
 elseif value.to then row.to=hydrate_context(self,value.to,'Player')end
 if kind=='Dying'and value.damage then row.damage=hydrate_context(self,value.damage,'Damage')end
 return row
end
local nullable={getMaxCard=true,getCurrent=true,getArmor=true,getWeapon=true,getEquip=true,toPlayer=true,toJudge=true,getStrategyMemory=true,setStrategyMemory=true,useBasicCard=true,useTrickCard=true}

local function prop(self,k)local v=self.player:getPropertyValue(k);if v==nil then return''end;return v end
local function face(self,id)if type(id)=='string'then id=tonumber(id)end;return self:getKnownCardById(id)end
local function named(self,skill,name,costs)return self:evaluateSkillCard(skill, name, costs or{})end
local function evaluation(self,name)return self:getEvaluationCard(name or'slash')end
local function pattern(self,class)local f=self:getConversionPolicy(class);return known(f.card_name,class)end
local function spec(c,name,skill)return{name=name,skill=skill,suit=c:getSuit(),number=c:getNumber(),subcards={c:getKnownEffectiveId()}}end
-- These fixed one-material dummy constructors are speculative until selected.
-- Their NoSuit/0 face is derived natively; payment never changes source order.
local xd_printed_responses=setmetatable({}, {__mode='k'})
local function printed_hypothesis(self,skill,name,costs,request)
 local class=({slash='Slash',analeptic='Analeptic',duel='Duel'})[name]
 local proposal={name=name,skill=skill,suit=sgs.Card_NoSuit,number=0,subcards=costs}
 if self.request.kind=='activate' then
  return self:evaluateTurnConversion(skill, class, proposal, request)
 end
 if skill~='zhifeng' or self.request.kind~='use_card' or self.request.pattern~='@@zhifeng' then
  ai_unsupported('tenyear printed hypothesis outside source inquiry',skill)
 end
 local native={};for k,v in pairs(proposal)do native[k]=v end;native.source_key=skill
 local card=self:evaluateOwnerViewAsCard(native)
 local rows=xd_printed_responses[self];if not rows then rows=setmetatable({}, {__mode='k'});xd_printed_responses[self]=rows end
 rows[card]={request=self.request,decision=self.request.decision_id,revision=self.request.state_revision,viewer=self.request.viewer,
  class=class,name=card:objectName(),skill=card:getKnownSkillName(false),suit=card:getSuit(),number=card:getNumber(),costs={table.unpack(costs)}}
 return card
end
local function selected_printed_response(self,card)
 local rows=xd_printed_responses[self];local entry=rows and rows[card]
 if not entry then return nil end
 if entry.request~=self.request or entry.decision~=self.request.decision_id or entry.revision~=self.request.state_revision
  or entry.viewer~=self.request.viewer or self.request.kind~='use_card' or self.request.pattern~='@@zhifeng'
  or entry.name~=card:objectName() or entry.skill~=card:getKnownSkillName(false) or entry.suit~=card:getSuit()
  or entry.number~=card:getNumber() then ai_unsupported('stale or altered Zhifeng hypothesis','@@zhifeng')end
 local ids=card:getSubcards();if #ids~=#entry.costs then ai_unsupported('altered Zhifeng cost','@@zhifeng')end
 for i,id in ipairs(ids)do if id~=entry.costs[i]then ai_unsupported('reordered Zhifeng cost','@@zhifeng')end end
 -- A real ThWeijing trigger can ask a recipient who owns no Zhifeng skill.
 -- Its finite native question witness grants no synthetic skill instance.
 local context=self:getDecisionContext()
 local question=context.zhifeng_question
 if type(question)=='table' and question.known==true then
  return self:bindZhifengQuestion(card),true
 end
 -- The actual @@ window is a native V1 action request, not a Slash/Analeptic
 -- card-pattern request. Only an issued exact actor/question action may bind.
 local result=self:bindSkillCard('zhifeng', entry.costs, nil)
 if not AIValue.isConversion(result)then ai_unsupported('Zhifeng selected response has no native receipt','@@zhifeng')end
 if result:objectName()~=entry.name or result:getClassName()~=entry.class
  or result:getKnownSkillName(false)~=entry.skill or result:getSuit()~=entry.suit or result:getNumber()~=entry.number then
  ai_unsupported('Zhifeng native product differs from selected source hypothesis','@@zhifeng')
 end
 local actual=result:getSubcards();if #actual~=#entry.costs then ai_unsupported('Zhifeng native payment differs','@@zhifeng')end
 for i,id in ipairs(actual)do if id~=entry.costs[i]then ai_unsupported('Zhifeng native payment order differs','@@zhifeng')end end
 return self:inheritLegacyCardIdentity(result, card)
end
local function memory(self,key,value,write)
 if write then if value==nil then value=false end;self:setStrategyMemory('tenyear_xd.'..key, value);return end
 local value,present=self:getStrategyMemory('tenyear_xd.'..key);if present then return value~=false and value or nil end
end
local function save_targets(self,key,ts)local names={};for _,p in ipairs(ts or{})do names[#names+1]=p:objectName()end;memory(self,key,names,true)end
local function targets(self,key)local names=memory(self,key);if not names then return nil end;local out=AIList.new({});for _,n in ipairs(names)do out:append(known(self.room:findPlayerByObjectName(n),n))end;return out end
local function saved_player(self,key)local name=memory(self,key);return name and known(self.room:findPlayerByObjectName(name),key)end
local function taguse(self,key)
 local rows=self:getDecisionContext().tenyear_xd;local use=rows and rows[key]
 if type(use)~='table'then ai_unsupported('tenyear_xd typed source CardUse absent',key)end
 return hydrate_context(self,use,'CardUse')
end
local providers={ZhizheCard='zhizhe',JiangxianCard='jiangxian',ThKegouCard='thkegou',DixianCard='dixian',ZhongyanCard='zhongyan',SayingCard='saying',JiaohaoCard='jiaohao',ShimouCard='shimou',QuzhouCard='quzhou',DouweiCard='douwei',XianjuCard='xianju',WohengCard='woheng',ZhanpanCard='zhanpan',LingseCard='lingse',ChouxiCard='chouxi',JichaoCard='jichao',QiaoduiCard='qiaodui',ZhanyanCard='zhanyan',DianlunCard='dianlun',ThJiweiCard='thjiweivs',JunheCard='junhe',ZongtaoCard='zongtao',ShurenCard='shuren'}
local function decode(wire)
 local cls,rest=wire:match('^@([%w_]+)=(.*)$');if not providers[cls]then ai_unsupported('unmapped tenyear_xd source prototype',wire)end
 local names={};local arrow=rest:find('->',1,true);if arrow then for n in rest:sub(arrow+2):gmatch('[^+]+')do names[#names+1]=n end;rest=rest:sub(1,arrow-1)end
 local raw,user=rest:match('^([^:]*):(.*)$');raw=raw or rest;local ids={};if raw~='.'and raw~=''then for token in raw:gmatch('[^+]+')do local id=tonumber(token);if not id or id<0 or id%1~=0 then ai_unsupported('tenyear_xd malformed material literal',wire)end;ids[#ids+1]=id end end
 return cls,ids,user,names
end
local function parse(self,wire)
 local cls,ids,user=decode(wire);local c
 if #ids==0 and not user then c=self:legacySkillSeed(providers[cls], cls, self.request)
 else c=self:evaluateTurnSkillCard(providers[cls], cls, ids, self.request, user)end
 self._tenyear_source_seeds=self._tenyear_source_seeds or{};self._tenyear_source_seeds[c]={request=self.request,cls=cls,ids=ids,user=user};return c
end
local function proposal(self,wire)local cls,ids,user=decode(wire);return{skill=providers[cls],legacy_class=cls,subcards=ids,user_string=user}end
local function response(self,wire)local cls,ids,user,names=decode(wire);local c=self:bindSkillCard(providers[cls], ids, self.request, user, cls);return{kind='use_card',card_spec=c:toCardSpec(),targets=names}end
local function answer(self,c,tos)
 local printed,question=selected_printed_response(self,c)
 if printed then return{kind='use_card',card_spec=question and printed or printed:toCardSpec(),targets=tos or{}}end
 local seed=self._tenyear_source_seeds and self._tenyear_source_seeds[c]
 if seed then
  if seed.request~=self.request then ai_unsupported('tenyear_xd stale source seed','tenyear_xd.response')end
  c=self:bindSkillCard(providers[seed.cls], seed.ids, self.request, seed.user, seed.cls)
 elseif c:isEvaluationOnly()then
  local skill=c:getKnownSkillName(false);local ids=c:getSubcards();local receipt=self:bindSkillCard(skill, ids, self.request, c:objectName())
  for _,k in ipairs{'objectName','getSuit','getNumber'}do if AIValue.callKnown(receipt, k)~=AIValue.callKnown(c, k)then ai_unsupported('tenyear_xd selected receipt changes product',k)end end
  if receipt:getKnownSkillName(false)~=skill then ai_unsupported('tenyear_xd receipt changes raw skill',skill)end
  local got=receipt:getSubcards();if #got~=#ids then ai_unsupported('tenyear_xd receipt changes costs',skill)end;for i,id in ipairs(ids)do if got[i]~=id then ai_unsupported('tenyear_xd receipt reorders costs',skill)end end;c=receipt
 end
 if AIValue.isConversion(c)then return{kind='use_card',card_spec=c:toCardSpec(),targets=tos or{}}end
 if c:isVirtualCard()then ai_unsupported('tenyear_xd selected hypothesis has no receipt','tenyear_xd.response')end
 return{kind='use_card',card_ids={c:getKnownEffectiveId()},targets=tos or{}}
end
local function save_plan(self,key,d)
 local c=d.card;local value={name=c:objectName(),skill=c:getKnownSkillName(false),suit=c:getSuit(),number=c:getNumber(),costs={},targets={}}
 for _,id in ipairs(c:getSubcards())do value.costs[#value.costs+1]=id end
 for _,p in ipairs(d.to or{})do value.targets[#value.targets+1]=p:objectName()end;memory(self,key,value,true)
end
local function load_plan(self,key)
 local v=known(memory(self,key),key);local c=named(self,v.skill,v.name,v.costs)
 if c:getSuit()~=v.suit or c:getNumber()~=v.number then ai_unsupported('saved tenyear_xd hypothesis face changed',key)end
 local ts=AIList.new({});for _,name in ipairs(v.targets)do ts:append(known(self.room:findPlayerByObjectName(name),name))end;return{card=c,to=ts}
end
local function save_judge(self,judge)
 if not judge then memory(self,'kanyu_judge',false,true);return end
 local row=self:getDecisionContext().round24_kanyu
 if type(row)~='table' or row.present~=true or type(row.token)~='string'
  or row.who~=judge.who:objectName() or row.pattern~=judge.pattern then
  ai_unsupported('Kanyu saved judge recipe was not projected','kanyu.invoke')
 end
 -- Preserve the native predicate polarity, not getJudge().good (cached isGood).
 memory(self,'kanyu_judge',{token=row.token,who=row.who,pattern=row.pattern,predicate_good=row.predicate_good},true)
end
local function saved_judge_player(self)local j=known(memory(self,'kanyu_judge'),'kanyu_judge');return known(self.room:findPlayerByObjectName(j.who),'judge.who')end
local function saved_judge_good(self,id)
 local saved=known(memory(self,'kanyu_judge'),'kanyu_judge')
 local current=self:getDecisionContext().round24_kanyu
 if type(current)~='table' or current.present~=true or current.token~=saved.token
  or current.who~=saved.who or current.pattern~=saved.pattern or current.predicate_good~=saved.predicate_good then
  ai_unsupported('Kanyu saved judge is stale or belongs to another inquiry','kanyu.ag')
 end
 local value=type(current.outcomes)=='table'and current.outcomes[tostring(id)]
 if type(value)~='boolean' then ai_unsupported('Kanyu offered-card filtering or predicate is not legally known','kanyu.ag:'..tostring(id))end
 return value
end
local function RandomList(items)local copy={};for _,v in ipairs(items)do copy[#copy+1]=v end;while #copy>0 do local v=copy[math.random(1,#copy)];table.removeOne(copy,v);table.removeOne(items,v);items[#items+1]=v end;return items end


ai_fill_skill.zhizhe = function(self, options, request)
	local cs = {}
	for _,h in sgs.list(self:sortByUseValueInPlace(self.player:getCards("h")))do
		if h:getTypeId()<3 and not h:isKindOf("DelayedTrick")
		then table.insert(cs,h) end
	end
	if #cs<4 or self:getUseValue(cs[1])<8 then return end
	return parse(self,"@ZhizheCard="..cs[1]:getEffectiveId())
end

ai_card_use["ZhizheCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.ZhizheCard = 5.4
sgs.ai_use_priority.ZhizheCard = 13.8

sgs.ai_skill_playerschosen.qingshi = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	self:sortInPlace(destlist, "hp")
	local tos = {}
	for _,to in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isFriend(to) then table.insert(tos,to) end
	end
	for _,to in sgs.list(destlist)do
		if #tos>=x or #tos>self.player:aliveCount()/2 then break end
		if not table.contains(tos,to) and not self:isEnemy(to)
		then table.insert(tos,to) end
	end
	return tos
end

ai_skill_choice.qingshi = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if table.contains(items,"draw")
	and #self.friends_noself>self.player:getHp()
	and #self.toUse>3 then return ai_choice_result(("draw"), options) end
	for _,c in sgs.list(items)do
		if c:startsWith("selfdraw")
		then return ai_choice_result((c), options) end
	end
	return ai_choice_result((items[1]), options)
end

ai_skill_invoke.tenyearsuifu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = self.room:getCurrent()
	if target then
		return (not self:isFriend(target)
		or #self:poisonCards("he", target)>target:getCardCount()/2) or false
	end
	return false

end

sgs.ai_skill_playerschosen.tenyearpijing = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	self:sortInPlace(destlist, "hp")
	local tos = {}
	for _,to in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isFriend(to) then table.insert(tos,to) end
	end
	for _,to in sgs.list(destlist)do
		if #tos>=x or #tos>self.player:aliveCount()/2 then break end
		if not table.contains(tos,to) and not self:isEnemy(to)
		then table.insert(tos,to) end
	end
	return tos
end

ai_skill_invoke.lieqiong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target then
		return (not self:isFriend(target)) or false
	end
	return false

end

ai_skill_choice.lieqiong = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local damage = data:toDamage()
	if table.contains(items,"lq_tianchong")
	and self:isEnemy(damage.to)
	then return ai_choice_result(("lq_tianchong"), options) end
	if table.contains(items,"lq_zhongshu")
	and self.player:getStrategyMark("&lqjishang+:+lq_zhongshu-SelfClear")<1
	then return ai_choice_result(("lq_zhongshu"), options) end
	if table.contains(items,"lq_diji")
	and self.player:getStrategyMark("&lqjishang+:+lq_diji-SelfClear")<1
	then return ai_choice_result(("lq_diji"), options) end
	if table.contains(items,"lq_lifeng")
	then return ai_choice_result(("lq_lifeng"), options) end
	if table.contains(items,"lq_qihai")
	and self.player:getStrategyMark("&lqjishang+:+lq_qihai-SelfClear")<1
	then return ai_choice_result(("lq_qihai"), options) end

    return ai_choice_result(nil, options)
end

ai_skill_invoke.thzhanjue = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

ai_skill_choice.thzhanjue = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if table.contains(items,"thzhanjue1")
	and self.player:getLostHp()<self.player:getHp()
	then return ai_choice_result(("thzhanjue1"), options) end
	if table.contains(items,"thzhanjue2")
	and self.player:getLostHp()>self.player:getHp()
	then return ai_choice_result(("thzhanjue2"), options) end

    return ai_choice_result(nil, options)
end

sgs.ai_used_revises.fengliao = function(self,use)
	if use.to:length()~=1 or use.card:canRecast() then return end
	local tp = self.player
	if self.player:getChangeSkillState("fengliao")==1 then
		if use.card:isSingleTargetCard() and use.to:length()==1 then tp = use.to:at(0) end
		if self:isEnemy(tp) and #self.toUse>1 then use.card = nil end
	else
		if use.card:isSingleTargetCard() and use.to:length()==1 then tp = use.to:at(0) end
		if tp==self.player then
			if self:getCardsNum("Peach,Analeptic")<1 then use.card = nil end
		elseif self:isFriend(tp)
		then use.card = nil end
	end
end

ai_fill_skill.peiniang = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValueInPlace(cards)
	for i,c1 in sgs.list(cards)do
		if prop(self,"yitongSuit")~=c1:getSuitString()
		or table.contains(self.toUse,c1) then continue end
		local dc = printed_hypothesis(self,"peiniang","analeptic",{c1:getKnownEffectiveId()},request)
		if dc:isAvailable(self.player)
		then return dc end
	end
end

function sgs.ai_cardsview.peiniang(self,class_name,player)
    local cards = sgs.QList2Table(player:getCards("h"))
	self:sortByKeepValueInPlace(cards)
	for _,c in sgs.list(cards)do
        if c:isKindOf("Analeptic") then
            return c:getLegacyStringKey()
	   	end
	end
	for _,c in sgs.list(cards)do
        if prop(self,"yitongSuit")==c:getSuitString() then
	   		return spec(c,"analeptic","peiniang")
	   	end
	end
end

ai_skill_invoke.chaozhen = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

ai_skill_invoke.lianjie = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

ai_fill_skill.jiangxian = function(self, options, request)
	return parse(self,"@JiangxianCard=.")
end

ai_card_use["JiangxianCard"] = function(self, card, use, request)
	if self:isWeak() then
		if self.player:getMaxHp()<3 then
			memory(self,"choice.jiangxian","jiangxian1",true)
			use.card = card
		end
	end
end

sgs.ai_use_value.JiangxianCard = 5.4
sgs.ai_use_priority.JiangxianCard = 0.8

sgs.ai_skill_cardask.thshenduan0 = function(self,data,pattern)
    local pd = data:toPindian()
	if pd.to==self.player then
		if self:isEnemy(pd.from)
		then return true end
	else
		if self:isEnemy(pd.to)
		then return true end
	end
	return "."
end

ai_fill_skill.thkegou = function(self, options, request)
	return parse(self,"@ThKegouCard=.")
end

ai_card_use["ThKegouCard"] = function(self, card, use, request)
	self:sortInPlace(self.enemies)
	for _,to in sgs.list(self.enemies)do
		if self.player:canPindian(to) then
			use.to:append(to)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.ThKegouCard = 5.4
sgs.ai_use_priority.ThKegouCard = 3.8

ai_skill_use["@@thkegou"] = function(self, prompt, request)
	self:sortInPlace(self.enemies)
	for _,to in sgs.list(self.enemies)do
		if self.player:canPindian(to) then
			return response(self,string.format("@ThKegouCard=.->%s",to:objectName()))
		end
	end
end

ai_fill_skill.dixian = function(self, options, request)
	return parse(self,"@DixianCard=.")
end

ai_card_use["DixianCard"] = function(self, card, use, request)
	if self:isWeak() and self:getOverflow()<1 then
		use.card = card
	end
end

sgs.ai_use_value.DixianCard = 5.4
sgs.ai_use_priority.DixianCard = 3.8

sgs.ai_skill_playerchosen.ruijun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_discard.thzhiji = function(self)
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValueInPlace(handcards)
   	for _,h in sgs.list(handcards)do
		if #cards>#handcards/2 or self:getKeepValue(h)>7 then continue end
		table.insert(cards,h:getKnownEffectiveId())
	end
	return cards
end

sgs.ai_skill_playerschosen.thzhiji = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	self:sortInPlace(destlist)
	local tos = {}
	for _,to in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isEnemy(to) then table.insert(tos,to) end
	end
	for _,to in sgs.list(destlist)do
		if #tos>=x or table.contains(tos,to) then break end
		if not self:isFriend(to) then table.insert(tos,to) end
	end
	return tos
end

ai_fill_skill.zhongyan = function(self, options, request)
	return parse(self,"@ZhongyanCard=.")
end

ai_card_use["ZhongyanCard"] = function(self, card, use, request)
	self:sortInPlace(self.friends)
	for i,p in sgs.list(self.friends)do
		if i>=#self.friends/2 and p:getHandcardNum()>0 then
			use.to:append(p)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.ZhongyanCard = 5.4
sgs.ai_use_priority.ZhongyanCard = 3.8

ai_skill_use["@@zhongyan!"] = function(self, prompt, request)
	self.qianlong_use = false
	self:setStrategyMemory("tenyear_hc.qianlong_use", {type="scalar",value=false})
	local n1 = {}
	for _,id in sgs.list(self.player:getNotifiedTag("zhongyanForAI"))do
		table.insert(n1,face(self,id))
	end
	self:sortByKeepValueInPlace(n1, true)
	local hs = self:sortByKeepValueInPlace(self.player:getHandcards(), true)
	for _,c in sgs.list(n1)do
		local ids = {c:getLegacyStringKey()}
		for _,h in sgs.list(hs)do
			if self:getUseValue(c)>self:getUseValue(h) then
				table.insert(ids,c:getLegacyStringKey())
				return response(self,"@ZhongyanCard="..table.concat(ids,"+"))
			end
		end
	end
end

sgs.ai_skill_playerchosen.zhongyan = function(self,players)
	if self:isWeak() and self.player:isWounded() then return end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target) and self:doDisCard(target, "ej", true)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target, "ej", true)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

ai_skill_invoke.jinglun = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target then
		return (self:isFriend(target)) or false
	end
	return false

end

ai_fill_skill.saying = function(self, options, request)
	local es = self:sortByKeepValueInPlace(self.player:getEquips())
	for _,h in sgs.list(es)do
		if self.player:getStrategyMark("saying_juguan_remove_analeptic_lun")<1 then
			local dc = named(self,"saying","analeptic",{})
			local d = self:aiUseCard(dc)
			if d.card then
				save_targets(self,"sayingTo",d.to)
				return parse(self,"@SayingCard="..h:getLegacyStringKey()..":analeptic")
			end
		end
		if self.player:getStrategyMark("saying_juguan_remove_peach_lun")<1 then
			local dc = named(self,"saying","peach",{})
			local d = self:aiUseCard(dc)
			if d.card then
				save_targets(self,"sayingTo",d.to)
				return parse(self,"@SayingCard="..h:getLegacyStringKey()..":peach")
			end
		end
	end
	local hs = self:sortByKeepValueInPlace(self.player:getHandcards())
	for _,h in sgs.list(hs)do
		if h:getTypeId()==3 and self.player:getStrategyMark("saying_juguan_remove_slash_lun")<1
		and h:isAvailable(self.player) and self:aiUseCard(h).card then
			local dc = named(self,"saying","slash",{})
			local d = self:aiUseCard(dc)
			if d.card then
				save_targets(self,"sayingTo",d.to)
				return parse(self,"@SayingCard="..h:getLegacyStringKey()..":slash")
			end
		end
	end
end

ai_card_use["SayingCard"] = function(self, card, use, request)
	if targets(self,"sayingTo") then
		use.card = card
		use.to = targets(self,"sayingTo")
	end
end

sgs.ai_use_value.SayingCard = 5.4
sgs.ai_use_priority.SayingCard = 6.8

function sgs.ai_cardsview.saying(self,class_name,player)
   	local cn = pattern(self,class_name)
	if player:getStrategyMark("saying_juguan_remove_"..cn.."_lun")>0 then return end
	if class_name=="Slash" or class_name=="Jink" then
		local cards = sgs.QList2Table(player:getCards("h"))
		self:sortByKeepValueInPlace(cards)
		for _,c in sgs.list(cards)do
			if c:getTypeId()==3 and c:isAvailable(player) then
				return proposal(self,"@SayingCard="..c:getLegacyStringKey()..":"..cn)
			end
		end
	else
		local cards = sgs.QList2Table(player:getEquips())
		self:sortByKeepValueInPlace(cards)
		for _,c in sgs.list(cards)do
			return proposal(self,"@SayingCard="..c:getLegacyStringKey()..":"..cn)
		end
	end
end

ai_fill_skill.jiaohao = function(self, options, request)
	return parse(self,"@JiaohaoCard=.")
end

ai_card_use["JiaohaoCard"] = function(self, card, use, request)
	local mc = self:getMaxCard()
	if mc:getNumber()>9 then
		self:sortInPlace(self.enemies)
		for _,to in sgs.list(self.enemies)do
			if self.player:canPindian(to) and to:getEquips():length()<=self.player:getEquips():length() then
				use.to:append(to)
				use.card = card
				return
			end
		end
	end
	if self:getOverflow()>1 then
		self:sortInPlace(self.friends_noself, nil, true)
		for _,to in sgs.list(self.friends_noself)do
			if self.player:canPindian(to) and to:getEquips():length()<=self.player:getEquips():length() then
				use.to:append(to)
				use.card = card
				return
			end
		end
	end
end

sgs.ai_use_value.JiaohaoCard = 5.4
sgs.ai_use_priority.JiaohaoCard = 4.8

ai_skill_invoke.jiaohao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target then
		return (self:isFriend(target)) or false
	end
	return false

end

ai_fill_skill.shimou = function(self, options, request)
	return parse(self,"@ShimouCard=.")
end

ai_card_use["ShimouCard"] = function(self, card, use, request)
	if self.player:getChangeSkillState("shimou")==1 then
		local n = 999
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if p:getHandcardNum()<n then n = p:getHandcardNum() end
		end
		for _,p in sgs.list(self.friends)do
			if p:getHandcardNum()<=n and p:getHandcardNum()<5 then
				use.card = card
				break
			end
		end
	else
		local n = 0
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if p:getHandcardNum()>n then n = p:getHandcardNum() end
		end
		for _,p in sgs.list(self.enemies)do
			if p:getHandcardNum()>=n and p:getHandcardNum()>5 then
				use.card = card
				break
			end
		end
	end
end

sgs.ai_use_value.ShimouCard = 5.4
sgs.ai_use_priority.ShimouCard = 3.8

sgs.ai_skill_askforag.shimou = function(self,card_ids)
	memory(self,"shimouTo",false,true)
	for _,id in sgs.list(card_ids)do
		local cn = face(self,id):objectName()
		local dc = named(self,"shimou",cn,{})
		local d = self:aiUseCard(dc)
		if d.card then
			save_targets(self,"shimouTo",d.to)
			local pnts = prop(self,"shimouPN"):split(":")
			local tp = BeMan(self.room,pnts[2])
			for _,p in sgs.list(d.to)do
				if tp:canUse(dc, p) then continue end
				cn = false
				break
			end
			if cn then
				return id
			end
		end
	end
end

ai_skill_use["@@shimou!"] = function(self, prompt, request)
	local tps = {}
	for _,to in sgs.list(targets(self,"shimouTo") or {})do
		table.insert(tps,to:objectName())
	end
	local pnts = prop(self,"shimouPN"):split(":")
	return response(self,"@ShimouCard=.:"..pnts[#pnts].."->"..table.concat(tps,"+"))
end

sgs.ai_skill_playerchosen.bizuo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist, nil, true)
    for i,target in sgs.list(destlist)do
		if i<#destlist/2 and self:isFriend(target)
		then return target end
	end
end

ai_skill_invoke.lieji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

ai_fill_skill.quzhou = function(self, options, request)
	return parse(self,"@QuzhouCard=.:slash")
end

ai_card_use["QuzhouCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.QuzhouCard = 5.4
sgs.ai_use_priority.QuzhouCard = 2.8

ai_skill_use["@@quzhou"] = function(self, prompt, request)
	for _,id in sgs.list(self.player:getNotifiedTag("quzhouForAI"))do
		local c = face(self,id)
		local d = self:aiUseCard(c)
		if d.card then
			local tps = {}
			for _,p in sgs.list(d.to)do
				table.insert(tps,p:objectName())
			end
			return answer(self,c,tps)
		end
	end
end

sgs.ai_skill_playerchosen.baojia = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for i,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for i,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

ai_skill_invoke.baojia = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	if damage.to then
		return (self:isFriend(damage.to) and self:isWeak(damage.to)) or false
	end
	return false

end

ai_skill_choice.baojia = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	return ai_choice_result((items[#items]), options)
end

ai_fill_skill.douwei = function(self, options, request)
	local hs = self:sortByKeepValueInPlace(self.player:getHandcards(), nil, "j")
	for _,h in sgs.list(hs)do
		if h:isDamageCard() then
			local dc = named(self,"douwei",h:objectName(),{})
			local d = self:aiUseCard(dc, dummy(nil,99))
			if d.card then
				self.douweitps = {};save_targets(self,"douweitps",self.douweitps)
				for i,p in sgs.list(d.to)do
					if self.player:inMyAttackRange(p) then
						table.insert(self.douweitps,p)
					end
				end
				if #self.douweitps<1 then continue end
				save_targets(self,"douweitps",self.douweitps);return parse(self,"@DouweiCard="..h:getLegacyStringKey())
			end
		end
	end
end

ai_card_use["DouweiCard"] = function(self, card, use, request)
	for i,to in sgs.list(targets(self,"douweitps"))do
		use.to:append(to)
		use.card = card
	end
end

sgs.ai_use_value.DouweiCard = 5.4
sgs.ai_use_priority.DouweiCard = 3.8

sgs.ai_skill_playerchosen.yingjia = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist, nil, true)
    for i,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for i,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end

ai_fill_skill.xianju = function(self, options, request)
	return parse(self,"@XianjuCard=.")
end

ai_card_use["XianjuCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.XianjuCard = 5.4
sgs.ai_use_priority.XianjuCard = 3.8

ai_fill_skill.woheng = function(self, options, request)
	return parse(self,"@WohengCard=.")
end

ai_card_use["WohengCard"] = function(self, card, use, request)
	self:sortInPlace(self.friends_noself)
	local n = self.player:getStrategyMark("&woheng_lun")
	for i,to in sgs.list(self.friends_noself)do
		if n>=0 and self:canDraw(to) then
			use.to:append(to)
			use.card = card
			return
		end
	end
	self:sortInPlace(self.enemies)
	for i,to in sgs.list(self.enemies)do
		if n>0 and to:getCardCount()>=n then
			use.to:append(to)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.WohengCard = 5.4
sgs.ai_use_priority.WohengCard = 6.8

ai_skill_choice.woheng = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return ai_choice_result((items[1]), options)
	end
	return ai_choice_result((items[#items]), options)
end

ai_skill_use["@@woheng"] = function(self, prompt, request)
	self:sortInPlace(self.friends_noself)
	local n = self.player:getStrategyMark("&woheng_lun")
	for i,to in sgs.list(self.friends_noself)do
		if n>=0 and self:canDraw(to) then
			return response(self,string.format("@WohengCard=.->%s",to:objectName()))
		end
	end
	self:sortInPlace(self.enemies)
	for i,to in sgs.list(self.enemies)do
		if n>0 and to:getCardCount()>=n then
			return response(self,string.format("@WohengCard=.->%s",to:objectName()))
		end
	end
end

sgs.ai_skill_playerchosen.yugui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist, nil, true)
    for i,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_cardask["yugui1"] = function(self,data)
    local tp = data:toPlayer()
	if self:isFriend(tp)
   	then return true end
    return "."
end

sgs.ai_skill_playerchosen.juchui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:isWeak(p)
		and p:getMaxHp()<=self.player:getMaxHp()
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and p:isWounded()
		and p:getMaxHp()<=self.player:getMaxHp()
		then return p end
	end
end

ai_skill_choice.juchui = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items,"juchui1") then
		if self:isFriend(target) and table.contains(items,"juchui2") then
			return ai_choice_result(("juchui2"), options)
		end
		return ai_choice_result(("juchui1"), options)
	end
	return ai_choice_result((items[1]), options)
end

sgs.ai_skill_playerchosen.thlinjie = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p, "N", self.player)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isFriend(p) and self:damageIsEffective(p, "N", self.player)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if p:getStrategyMark("jianghuoDamage")<1
		then return p end
	end
	return destlist[#destlist]
end

ai_fill_skill.zhanpan = function(self, options, request)
	return self:canDraw() and parse(self,"@ZhanpanCard=.")
end

ai_card_use["ZhanpanCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.ZhanpanCard = 5.4
sgs.ai_use_priority.ZhanpanCard = 6.8

sgs.ai_skill_playerschosen.tiancheng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
	local tps = {}
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and p:getHandcardNum()-self.player:getHandcardNum()>3
		then table.insert(tps,p) end
	end
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and not table.contains(tps,p)
		 and self.player:getHandcardNum()-p:getHandcardNum()<3
		then table.insert(tps,p) end
	end
	return tps
end

ai_skill_invoke.duhai = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	if use.from then
		return (self:isEnemy(use.from)) or false
	end
	return false

end

ai_fill_skill.lingse = function(self, options, request)
	for _,h in sgs.list(self:sortByKeepValueInPlace(self.player:getCards("he")))do
		return parse(self,"@LingseCard="..h:getEffectiveId())
	end
end

ai_card_use["LingseCard"] = function(self, card, use, request)
	self:sortInPlace(self.enemies)
    for i,p in sgs.list(self.enemies)do
		if p:getCardCount()>1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	self:sortInPlace(self.friends_noself, nil, true)
    for i,p in sgs.list(self.friends_noself)do
		if p:getCardCount()>1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.LingseCard = 5.4
sgs.ai_use_priority.LingseCard = 3.8
 
ai_fill_skill.chouxi = function(self, options, request)
	local hs = self:sortByKeepValueInPlace(self.player:getCards("he"))
	if #hs<1 then return end
	local cns = {}
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		for _,id in sgs.list(p:getPile("cang_ming"))do
			local c = face(self,id)
			if self.player:getStrategyMark(c:objectName().."chouxiUse-Clear")>0
			or table.contains(cns,c:objectName()) then continue end
			if (c:getTypeId()==1 or c:isNDTrick()) then
				table.insert(cns,c:objectName())
			end
		end
	end
	for _,cn in sgs.list(RandomList(cns))do
		for _,h in sgs.list(hs)do
			local dc = named(self,"chouxi",cn,{h:getKnownEffectiveId()})
			if dc:isAvailable(self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					if dc:canRecast() and d.to:length()<1 then continue end
					save_plan(self,"chouxi_use",d)
					memory(self,"choice.chouxi",cn,true)
					return parse(self,"@ChouxiCard=.:"..cn)
				end
			end
		end
	end
end

ai_card_use["ChouxiCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.ChouxiCard = 5.4
sgs.ai_use_priority.ChouxiCard = 3.8

ai_skill_use["@@chouxi"] = function(self, prompt, request)
	local d = load_plan(self,"chouxi_use")
	if d.card then
		local tps = {}
		for _,p in sgs.list(d.to)do
			table.insert(tps,p:objectName())
		end
		return answer(self,d.card,tps)
	end
end

ai_fill_skill.jichao = function(self, options, request)
	return parse(self,"@JichaoCard=.")
end

ai_card_use["JichaoCard"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, nil, true)
	for i,to in sgs.list(self.enemies)do
		if to:getHandcardNum()>0 and to:hasEquip() then
			use.to:append(to)
			use.card = card
			return
		end
	end
	local n = 0
	for i,p in sgs.list(self.room:getAlivePlayers())do
		if p:getCardCount()>1 and not self:isFriend(p) then
			n = n+1
		else
			n = n-1
		end
	end
	if n>0 then
		use.card = card
	end
end

sgs.ai_use_value.JichaoCard = 5.4
sgs.ai_use_priority.JichaoCard = 7.8

ai_skill_invoke.kanyu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local judge = data:toJudge()
	if judge and judge.who then
		save_judge(self,judge)
		return (self:isFriend(judge.who) or self:isWeak()) or false
	end
	save_judge(self,nil)
	return (self:isWeak() and self:canDraw()) or false
end

sgs.ai_skill_askforag.kanyu = function(self,card_ids)
	if memory(self,"kanyu_judge") then
		for i,id in sgs.list(card_ids)do
			if saved_judge_good(self,id) then
				if self:isFriend(saved_judge_player(self)) then
					return -1
				end
			else
				if self:isEnemy(saved_judge_player(self)) then
					return -1
				end
			end
		end
	end
	if self:canDraw() then
		return card_ids[1]
	end
	return -1
end

ai_skill_invoke.chongzhu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_playerchosen.chongzhu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p, "N", self.player)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isFriend(p) and self:damageIsEffective(p, "N", self.player)
		then return p end
	end
end

ai_skill_invoke.zhenting = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local dps = data:toStringList()
	for i,p in sgs.list(self.friends)do
		if table.contains(dps,p:objectName()) and self:isWeak(p) then
			return (true) or false
		end
	end
	for i,p in sgs.list(self.friends)do
		if p:getStrategyMark("zhentingDamaged-Clear")>0 and self:canDraw(p) then
			return (true) or false
		end
	end
	return false

end

sgs.ai_skill_playerchosen.zhenting = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

ai_skill_invoke.chiguo = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

sgs.ai_skill_playerchosen.chiguo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

sgs.ai_use_revises.chiguo = function(self,card,use)
	
end

sgs.ai_skill_playerchosen.thjizhan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p, "N", self.player)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isFriend(p) and self:damageIsEffective(p, "N", self.player)
		then return p end
	end
end

sgs.ai_skill_playerchosen.zhiwang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for i,p in sgs.list(destlist)do
		if saved_player(self,"zhiwang_to")==p
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

sgs.ai_skill_askforag.zhiwang = function(self,card_ids)
	memory(self,"zhiwang_to",false,true)
	for i,id in sgs.list(card_ids)do
		local c = face(self,id)
		for _,fp in sgs.list(self.friends_noself)do
			if c:isAvailable(fp) and self:evaluateOtherPlayerCardUse(fp, c).card then
				memory(self,"zhiwang_to",fp:objectName(),true)
				return id
			end
		end
	end
	return card_ids[1]
end

ai_skill_use["@@zhiwang!"] = function(self, prompt, request)
	local c = face(self,self.player:getStrategyMark("zhiwangId"))
	local d = self:aiUseCard(c)
	if d.card then
		local tps = {}
		for _,p in sgs.qlist(d.to)do
			table.insert(tps,p:objectName())
		end
		return answer(self,c,tps)
	end
	if c:targetFixed() then
		return answer(self,c,{})
	end
	local aps = sgs.SPlayerList()
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		if self.player:canUse(c, p) then
			aps:append(p)
			if c:targetsFeasible(aps, self.player) then
				local tps = {}
				for _,p in sgs.qlist(aps)do
					table.insert(tps,p:objectName())
				end
				return answer(self,c,tps)
			end
		end
	end
end

ai_skill_use["@@qiaodui"] = function(self, prompt, request)
	local use = taguse(self,"qiaodui_data")
	if use.from==self.player then
		if self:isEnemy(use.to:at(0)) then
			
		else
			return
		end
	else
		if self:isWeak() and use.card:isDamageCard() then
			
		else
			return
		end
	end
	self:sortInPlace(self.friends_noself)
	local hs = self:sortByKeepValueInPlace(self.player:getCards("he"))
	for i,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			return "@QiaoduiCard="..hs[1].."->"..p:objectName()
		end
	end
	for i,p in sgs.list(self.room:getAlivePlayers())do
		if self.player~=p and not self:isEnemy(p) then
			return "@QiaoduiCard="..hs[1].."->"..p:objectName()
		end
	end
end

sgs.ai_skill_playerchosen.chiguo0 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	local use = taguse(self,"chiguo_data")
	self:sortInPlace(destlist)
    for i,p in sgs.list(destlist)do
		if use.to:contains(p) then
			continue
		end
		if self:canCanmou(p, use)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if use.to:contains(p) then
			if use.card:isDamageCard() then
				if self:isFriend(p) and self:isWeak(p) then
					return p
				end
			elseif use.to:contains(self.player) and use.card:targetFixed() then
				if self:isEnemy(p) then
					return p
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen.chiguo1 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

sgs.ai_skill_playerchosen.juce = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	local use = taguse(self,"juce_data")
	self:sortInPlace(destlist)
    for i,p in sgs.list(destlist)do
		if self:canCanmou(p, use)
		then return p end
	end
end

ai_skill_invoke.kangming = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

sgs.ai_skill_cardask.kangming0 = function(self,data,pattern)
    local use = data:toCardUse()
    for i,id in sgs.list(pattern:split(","))do
		local c = face(self,id)
		local dc = named(self,"kangming",c:objectName(),{})
		local d = self:aiUseCard(dc)
		if d.card then
			if d.to:contains(use.from) then
				return id
			end
			if c:isDamageCard() then
				if self:isEnemy(use.from) then
					return id
				end
			else
				if d.to:length()<1 then
					if self:isFriend(use.from) then
						return id
					end
				else
					if self:isFriend(d.to:at(0))==self:isFriend(use.from) then
						return id
					end
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_cardask["junmou0"] = function(self,data)
	if self.player:getChangeSkillState("junmou")==2
	or not self:isWeak() or self:getOverflow()>0
   	then return true end
    return "."
end

ai_skill_invoke.junmou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

sgs.ai_skill_playerschosen.junmou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
	local tps = {}
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and #tps<2
		then table.insert(tps,p) end
	end
    for i,p in sgs.list(destlist)do
		if not self:isFriend(p) and #tps<2
		then table.insert(tps,p) end
	end
	return tps
end

ai_fill_skill.zhanyan = function(self, options, request)
	return parse(self,"@ZhanyanCard=.")
end

ai_card_use["ZhanyanCard"] = function(self, card, use, request)
	self:sortInPlace(self.enemies)
	for i,p in sgs.list(self.enemies)do
		if p:isChained() and p:getHandcardNum()>0 then
			use.to:append(p)
		end
	end
	if use.to:length()>#self.enemies/2 then
		use.card = card
	end
	if self:isWeak() then
		for i,p in sgs.list(self.room:getAlivePlayers())do
			if self:isFriend(p) or use.to:contains(p) then continue end
			if p:isChained() and p:getHandcardNum()>0 then
				use.to:append(p)
			end
		end
	end
end

sgs.ai_use_value.ZhanyanCard = 5.4
sgs.ai_use_priority.ZhanyanCard = 0.8

ai_skill_use["@@zhanyan"] = function(self, prompt, request)
	local c = parse(self,"@ZhanyanCard=.")
	local d = self:aiUseCard(c)
	if d.card then
		local tps = {}
		for _,p in sgs.qlist(d.to)do
			table.insert(tps,p:objectName())
		end
		return answer(self,c,tps)
	end
end

sgs.ai_skill_cardask["zhanyan0"] = function(self,data)
	if self:isEnemy(data:toPlayer()) or self:getOverflow()>0
   	then return true end
    return "."
end

sgs.ai_skill_discard.qinqiang = function(self,m,x)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValueInPlace(handcards)
	local ids = {}
	for _,h in sgs.list(handcards)do
		table.insert(ids,h:getKnownId())
		if #ids>#handcards/2 then break end
	end
	return ids
end

ai_skill_invoke.shugang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

ai_fill_skill.shugang = function(self, options, request)
	for _,c in sgs.list(self.player:getCards("he"))do
		if c:hasTip("shugang") then
			local cs = {}
			for _,cn in sgs.list(known(AICardCatalog.patternNames(),"pattern_names"))do
				local dc = evaluation(self,cn)
				if dc:isDamageCard() then
					dc = named(self,"shugang",cn,{c:getKnownEffectiveId()})
					if dc:isAvailable(self.player) then
						table.insert(cs,dc)
					end
				end
			end
			return cs
		end
	end
end

ai_fill_skill.dianlun = function(self, options, request)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    if #handcards<1 then return end
	handcards = self:sortByKeepValueInPlace(handcards, nil, "j")
	local ids = {}
	for _,h1 in sgs.list(handcards)do
		local ids2 = {h1}
		for _,h2 in sgs.list(handcards)do
			if table.contains(ids2,h2) then continue end
			if #ids2>1 then
				local x = math.abs(ids2[1]:getNumber()-ids2[2]:getNumber())
				if x==math.abs(ids2[1]:getNumber()-h2:getNumber())
				or x==math.abs(ids2[#ids2]:getNumber()-h2:getNumber()) then
					
				else
					continue
				end
			end
			table.insert(ids2,h2)
			if #ids2>=#handcards/2 then 
				break
			end
		end
		if #ids2>=#handcards/2 then 
			for _,c in sgs.list(ids2)do
				table.insert(ids,c:getKnownId())
			end
			break
		end
	end
	return #ids>0 and parse(self,"@DianlunCard="..table.concat(ids,"+"))
end

ai_card_use["DianlunCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.DianlunCard = 5.4
sgs.ai_use_priority.DianlunCard = 6.8

ai_skill_use["@@dianlun"] = function(self, prompt, request)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    if #handcards<1 then return end
	handcards = self:sortByKeepValueInPlace(handcards, nil, "j")
	local ids = {}
	for _,h1 in sgs.list(handcards)do
		local ids2 = {h1}
		for _,h2 in sgs.list(handcards)do
			if table.contains(ids2,h2) then continue end
			if #ids2>1 then
				local x = math.abs(ids2[1]:getNumber()-ids2[2]:getNumber())
				if x==math.abs(ids2[1]:getNumber()-h2:getNumber())
				or x==math.abs(ids2[#ids2]:getNumber()-h2:getNumber()) then
					
				else
					continue
				end
			end
			table.insert(ids2,h2)
			if #ids2>=#handcards/2 or #ids2>2 then 
				break
			end
		end
		if #ids2>=#handcards/2 or #ids2>2 then 
			for _,c in sgs.list(ids2)do
				table.insert(ids,c:getKnownId())
			end
			break
		end
	end
	if #ids>0 then
		return response(self,"@DianlunCard="..table.concat(ids,"+"))
	end
end

ai_fill_skill.thjiweivs = function(self, options, request)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    if #handcards<1 or self:getOverflow()<1 then return end
	handcards = self:sortByKeepValueInPlace(handcards)
	return parse(self,"@ThJiweiCard="..handcards[1]:getId())
end

ai_card_use["ThJiweiCard"] = function(self, card, use, request)
	self:sortInPlace(self.friends_noself)
	for i,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) and p:hasSkill("thjiwei") then
			use.to:append(p)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.ThJiweiCard = 5.4
sgs.ai_use_priority.ThJiweiCard = 4.8

sgs.ai_skill_playerchosen.duoyue = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p, "N", self.player)
		then return p end
	end
	self:sortInPlace(destlist, nil, true)
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and self:getOverflow(p)>0
		and p:getKnownKingdom()=="wei" and not self:isWeak(p)
		then return p end
	end
end

ai_skill_invoke.duoyue = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local str = data:toString()
	for i,p in sgs.list(self.friends)do
		if str:endsWith(p:objectName()) then
			return (self:canDraw(P)) or false
		end
	end
    return false

end

ai_skill_use["@@junhe"] = function(self, prompt, request)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    if #cards<1 then return end
	local ids = {}
	local cts = {}
	for _,c in sgs.list(cards)do
		cts[c:getColorString()] = (cts[c:getColorString()] or 0)+1
		cts[c:getType()] = (cts[c:getType()] or 0)+1
	end
	local x = 0
	for t,n in pairs(cts)do
		x = math.max(x,n)
	end
	local r = ""
	for t,n in pairs(cts)do
		if n>=x then
			r = t
		end
	end
	for _,c in sgs.list(cards)do
		if c:getColorString()==r or c:getType()==r then
			table.insert(ids,c:getKnownId())
		end
	end
	if #ids>0 then
		return response(self,"@JunheCard="..table.concat(ids,"+"))
	end
end

sgs.ai_skill_cardask["junhe1"] = function(self,data)
	local damage = data:toDamage()
	if self:isEnemy(damage.to)
   	then return true end
    return "."
end

ai_skill_choice.xiongwei = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target) then
		for i,t in sgs.list(items)do
			if i>=#items/2 then
				return ai_choice_result((t), options)
			end
		end
	end
	return ai_choice_result((items[#items]), options)
end

ai_fill_skill.zongtao = function(self, options, request)
	return parse(self,"@ZongtaoCard=.")
end

ai_card_use["ZongtaoCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.ZongtaoCard = 5.4
sgs.ai_use_priority.ZongtaoCard = 8.8

ai_skill_choice.zongtao = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	return ai_choice_result((items[math.random(1,#items-1)]), options)
end

ai_skill_choice.thjizhanmc = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local n = self.player:getStrategyMark("thjizhanmcUse-Clear")
	for i,p in sgs.list(self.enemies)do
		if (p:getHp()<=n or self:isWeak(p)) and self:damageIsEffective(p, "N", self.player) then
			memory(self,"thjizhanmc2",true,true)
			return ai_choice_result((items[2]), options)
		end
	end
	return ai_choice_result((items[1]), options)
end

sgs.ai_skill_playerchosen.thjizhanmc = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sortInPlace(destlist)
	if memory(self,"thjizhanmc2") then
		memory(self,"thjizhanmc2",false,true)
		for i,p in sgs.list(destlist)do
			if self:isEnemy(p) and self:damageIsEffective(p, "N", self.player)
			then return p end
		end
	end
    for i,p in sgs.list(destlist)do
		if self:doDisCard(p, "he")
		then return p end
	end
	for i,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
end

ai_fill_skill.zhifeng = function(self, options, request)
    local inclusive = options and options.inclusive

    local handcards = sgs.QList2Table(self.player:getCards("he"))
    if #handcards<1 then return end
	handcards = self:sortByKeepValueInPlace(handcards)
	local n = #handcards-self.player:getHp()
	if n>0 then
		for i,h in sgs.list(handcards)do
			if h:isBlack() then
				local dc = printed_hypothesis(self,"zhifeng","analeptic",{h:getKnownEffectiveId()},request)
				if dc:isAvailable(self.player) then
					return dc
				end
			end
		end
	elseif n<1 then
		for i,h in sgs.list(handcards)do
			if h:isRed() then
				local dc = printed_hypothesis(self,"zhifeng","slash",{h:getKnownEffectiveId()},request)
				if dc:isAvailable(self.player) then
					return dc
				end
			end
		end
	else
		for i,h in sgs.list(handcards)do
			local dc = printed_hypothesis(self,"zhifeng","duel",{h:getKnownEffectiveId()},request)
			if dc:isAvailable(self.player) then
				return dc
			end
		end
	end
end

function sgs.ai_cardsview.zhifeng(self,class_name,player)
	local cards = sgs.QList2Table(player:getCards("he"))
	self:sortByKeepValueInPlace(cards)
	for _,c in sgs.list(cards)do
		if class_name=="Slash" then
			if c:isRed() then
				return spec(c,"slash","zhifeng")
			end
		elseif class_name=="Analeptic" then
			if c:isBlack() then
				return spec(c,"analeptic","zhifeng")
			end
		else
			return spec(c,"duel","zhifeng")
		end
	end
end

ai_skill_invoke.thweijing = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local tp = data:toPlayer()
	return (self:isEnemy(tp) or self:getOverflow(tp)>=0) or false
end

ai_skill_choice.thweijing = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
    local tp = data:toPlayer()
	if self:isEnemy(tp) then
		return ai_choice_result((items[1]), options)
	end
	return ai_choice_result((items[2]), options)
end

ai_skill_use["@@zhifeng"] = function(self, prompt, request)
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    if #handcards<1 then return end
	handcards = self:sortByKeepValueInPlace(handcards)
	local n = #handcards-self.player:getHp()
	if n>0 then
		for i,h in sgs.list(handcards)do
			if h:isBlack() then
				local dc = printed_hypothesis(self,"zhifeng","analeptic",{h:getKnownEffectiveId()})
				if dc:isAvailable(self.player) then
					local d = self:aiUseCard(dc)
					if d.card then
						local tps = {}
						for _,p in sgs.qlist(d.to)do
							table.insert(tps,p:objectName())
						end
						return answer(self,dc,tps)
					end
				end
			end
		end
	elseif n<1 then
		for i,h in sgs.list(handcards)do
			if h:isRed() then
				local dc = printed_hypothesis(self,"zhifeng","slash",{h:getKnownEffectiveId()})
				if dc:isAvailable(self.player) then
					local d = self:aiUseCard(dc)
					if d.card then
						local tps = {}
						for _,p in sgs.qlist(d.to)do
							table.insert(tps,p:objectName())
						end
						return answer(self,dc,tps)
					end
				end
			end
		end
	else
		for i,h in sgs.list(handcards)do
			local dc = printed_hypothesis(self,"zhifeng","duel",{h:getKnownEffectiveId()})
			if dc:isAvailable(self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					local tps = {}
					for _,p in sgs.qlist(d.to)do
						table.insert(tps,p:objectName())
					end
					return answer(self,dc,tps)
				end
			end
		end
	end
end

ai_fill_skill.shuren = function(self, options, request)
	if self:isWeak() then
		for i=4,0,-1 do
			if self.player:hasEquipArea(i) and self.player:getEquip(i) then
				memory(self,"choice.shuren","EquipArea"..i,true)
				return parse(self,"@ShurenCard=.")
			end
		end
	else
		for i=4,0,-1 do
			if self.player:hasEquipArea(i) then
				memory(self,"choice.shuren","EquipArea"..i,true)
				return parse(self,"@ShurenCard=.")
			end
		end
	end
end

ai_card_use["ShurenCard"] = function(self, card, use, request)
	self:sortInPlace(self.friends_noself)
	for i,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.ShurenCard = 5.4
sgs.ai_use_priority.ShurenCard = 1.8

ai_skill_choice.sharan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	return ai_choice_result((items[1]), options)
end












for _,skill in ipairs{"jiangxian","chouxi","shuren"}do ai_skill_choice[skill]=function(self, options, request)return ai_choice_result((known(memory(self,"choice."..skill),skill.." source choice has not been observed by this viewer")), options)end end
