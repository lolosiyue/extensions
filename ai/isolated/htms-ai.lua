-- Fixed htms b6025acc source policy. Readonly proposals never grant payment authority.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("htms fact unknown",k)end;return v end
local function __htms_value_call(o,k,...)if o==nil then error("attempt to index a nil value",0)end;if k=="getMark"and AIValue.isPlayer(o)then k="getStrategyMark"elseif k=="hasFlag"and AIValue.isPlayer(o)then k="getStrategyFlag"end;if type(o[k])~="function"then ai_unsupported("htms method unavailable",k)end;return known(o[k](o,...),k)end
-- The remaining htms facts (Room tags voidid/voidtarget, pingjian catalogs, use history,
-- other players' properties) are not projected.
local function fact(self,k)ai_unsupported("htms fact is not projected",k)end
local function visible(self,id)return known(self:getKnownCardById(id),"disclosed card")end
-- Own dynamic property read as the donor's toString(): absent is "".
local function property(self,k)local v=self.player:getPropertyValue(k);if v==nil then return""end;return known(type(v)=="string"and v or nil,k)end
-- Room tags are not projected, except the two the decision context carries as its
-- `damage` (CurrentDamageStruct) and `use` (CurrentUseStruct); these asks carry no
-- struct data of their own. A missing one stays unknown here.
local function tag(self,k,kind)
 local key=(k=="CurrentDamageStruct"and"damage")or(k=="CurrentUseStruct"and"use")or nil
 if not key then ai_unsupported("room tag is not projected",k)end
 local v=known(self:getDecisionContext()[key],k)
 local context=type(self.request.options)=="table"and self.request.options.context
 local raw=type(context)=="table"and type(context[key])=="table"and context[key]or{}
 for _,f in ipairs({"from","to"})do if raw[f]==""then v[f]=nil end end
 if type(raw.card)~="table"or next(raw.card)==nil then v.card=nil end
 return v
end
local function dummy_plan(value,extra,current)local u=AIUsePlan.new();u.isDummy=value~=false;u.extra_target=extra or 0;u.current_targets=current or {};return u end
local recipes=setmetatable({},{__mode="k"})
local function copy(t)local r={}for k,v in pairs(t)do if type(v)=="table"then r[k]=copy(v)else r[k]=v end end;return r end
local function clone(self,name,suit,number,skill)
 if type(suit)=="string"then skill=suit;suit=sgs.Card_NoSuit end
 name=name or"slash";suit=suit or sgs.Card_NoSuit;number=number or 0
 local spec={source_key=self._htms_callback_key or "htms",name=name,skill=skill or"",suit=suit,number=number,subcards={}}
 local c
 if spec.skill==""and suit==sgs.Card_NoSuit and number==0 then c=self:getEvaluationCard(name)
 else c=self:evaluateOwnerViewAsCard(spec)end
 if c then recipes[c]=spec end;return c
end
local function mutate(self,c,field,v)
 if c==nil and self._htms_callback_key=="@@s_newtypeOther"then error("attempt to index a nil value",0)end
 local spec=recipes[c];if not spec then ai_unsupported("source mutates card outside its owned readonly clone","htms.clone")end
 spec=copy(spec)
 if field=="clear"then spec.subcards={}elseif field=="can_recast"then ai_unsupported("readonly clone recast mutation requires scoped native contract",self._htms_callback_key)elseif field=="add"then spec.subcards[#spec.subcards+1]=type(v)=="number"and v or __htms_value_call(v,"getEffectiveId")else spec[field]=v end
 local next
 if spec.prototype then next=self:evaluateTurnSkillCard(spec.skill,spec.prototype,spec.subcards,nil,spec.user)else next=self:evaluateOwnerViewAsCard(spec)end;self:inheritLegacyCardIdentity(next,c);recipes[next]=spec;return next
end
local function ids(raw)local out={};if raw~="."and raw~=""then for n in raw:gmatch("[^+]+")do out[#out+1]=tonumber(n)or 0 end end;return out end
local function printed_spec(text)
 local name,skill,suit,n,raw=text:match("^([%w_]+):([%w_]+)%[([^:]+):([^%]]+)%]=(.*)$");if not name then return nil end
 local suits={spade=sgs.Card_Spade,club=sgs.Card_Club,heart=sgs.Card_Heart,diamond=sgs.Card_Diamond,no_suit=sgs.Card_NoSuit,no_suit_red=sgs.Card_NoSuitRed,no_suit_black=sgs.Card_NoSuitBlack};local nums={A=1,J=11,Q=12,K=13}
 return{name=name,skill=skill,suit=suits[suit]or sgs.Card_NoSuit,number=known(tonumber(n)or nums[n],"number"),subcards=ids(raw)}
end
local classes={['QiaobianCard']='qiaobian',['#htms_zangsongCard']='htms_zangsong',['#fengwang']='fengwang',['#newfengwang']='newfengwang',['#wangzhe']='wangzhe',['#handsonicCard']='handsonic',['#frozenpuppetCard']='frozenpuppet',['#mie']='mie',['#diancp']='diancp',['#jiasugaobai']='jiasugaobai',['#jiujideqiyuan']='jiujideqiyuan',['#pojgjCard']='pojgj',['#LuamuguanCard']='Luamuguan',['#jfxl']='jfxl',['#guancha']='guancha',['#jiyi']='jiyi',['#pocdsf']='pocdsf',['#xiangruiCard']='xiangrui',['#geasstarget']='geasstarget',['#geass']='geass',['#znai']='znai',['#guailj']='guailj',['#smsy']='smsy',['#jiewq']='jiewq',['#qsas']='qsas',['#nidaorenCard']='nidaoren',['#badaozhaiCard']='badaozhai',['#feils2']='feils2',['#jiushu']='jiushu',['#changgui']='changgui',['#heihua']='heihua',['#kuixin']='kuixin',['#jueduiyazhiCard']='jueduiyazhi',['#guangzijupaoCard']='guangzijupao',['#yohane']='yohane',['#xieyancard']='xieyan',['#zangsongCard']='zangsong',['#chunrijilu']='chunrijilu',['#haite']='haite',['#yueying']='yueying',['#zuzhouCard']='zuzhou',['#xiangyangshi']='xiangyangshi',['#shengdanny']='shengdanny',['#yushicp']='yushicp',['#yugao']='yugao',['#jibanhyCard']='jibanhy',['#nvzidaoCard']='nvzidao',['#duandai']='duandai',['#wangwei']='wangwei',['#qiyuan']='qiyuan',['#Luayuanling']='Luayuanling',['#luakuaiqing']='luakuaiqing',['#luajieao']='luajieao',['#empaidui']='empaidui',['#qgjiesi']='qgjiesi',['#zjyizhenCard']='zjyizhen',['#zjaojiaol']='zjaojiaol',['#zchizeCard']='zchize',['#molwf']='molwf',['#html_shishengCard']='html_shisheng',['#ujyaozhanCard']='ujyaozhan',['#Sdorica_MiLingCard']='Sdorica_MiLing',['#void']='void',['#wzgzcard']='wzgz',['#htms_mozhi']='htms_mozhi',['#yiban']='yiban',['#zhachang']='zhachang',['#zhufu']='zhufu',['#paojixj']='paojixj',['#xinshengll']='xinshengll',['#shejiao']='shejiao',['#shejiaofuka']='shejiaofuka',['#s_yanmojianglin']='s_yanmojianglin',['#s_lianjie']='s_lianjie',['#s_polie']='s_polie',['#s_fudao']='s_fudao',['#s_kongyi']='s_kongyi',['#s_newtype']='s_newtype',['#htms_nishengCard']='htms_nisheng'}
local function decode(text)
 local cl,raw=text:match("^@([%w_]+)=(.*)$");local user
 if cl then local costs,u=raw:match("^(.-):(.*)$");raw=costs or raw;user=u
 else cl,raw,user=text:match("^#([%w_]+):([^:]*):(.*)$");if cl then cl="#"..cl end end
 local sk=cl and classes[cl];if not sk then ai_unsupported("source prototype wire outside authored catalog","htms")end
 return cl,sk,ids(raw),user~=""and user or nil
end
local function policy(self,text,request)
 if text:match("^%d+$")then return visible(self,tonumber(text))end
 local row=printed_spec(text);if row and self._htms_callback_key=="@@maware" and row.skill=="samsara" then
  row.source_key="@@maware";local c=self:evaluateOwnerViewAsCard(row);recipes[c]=copy(row);return c
 end
 if row then local b=known(self:getEvaluationCard(row.name),"printed source prototype");local c=self:evaluateTurnConversion(row.skill,b:getClassName(),row,request);recipes[c]=copy(row);return c end
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
 if __htms_value_call(c,"isVirtualCard")then ai_unsupported("selected physical response has no issued authority","htms")end
 return{kind="use_card",card_id=__htms_value_call(c,"getEffectiveId"),targets=tos and tos:split("+")or{}}
end
local function proposal(v)
 if type(v)~="string"or v=="."or v==""then return v end
 local row=printed_spec(v);if row then return row end
 local cl,sk,cs,u=decode(v);return{legacy_class=cl,skill=sk,subcards=cs,user_string=u}
end
local function can_to(self,c,from,to,targets)
 if from:objectName()~=self.player:objectName()then ai_unsupported("foreign hypothetical targetFilter lacks public rule contract","htms")end
 return self:cardTargetFilter(c,targets or{},to)
end
local function pending_tag(self,name,value)ai_unsupported("temporary yb_zhuzhan2 input requires pure callback adapter",name)end
local function private_draw(self)ai_unsupported("source inspects undisclosed draw-pile faces","zhachang")end
local function source_description(self,name)ai_unsupported("card descriptions are not projected",name)end
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
  if type(v.isEvaluationOnly)=="function"and v:isEvaluationOnly()then ai_unsupported("untracked readonly card cannot persist across snapshots","htms state")end
  return{type="card",id=__htms_value_call(v,"getEffectiveId")}
 end
 if type(v)~="table"then return{type="scalar",value=v}end
 local t={type="table",value={}};for k,x in pairs(v)do if type(x)~="function"then t.value[k]=state_encode(self,x)end end;return t
end
local function state_decode(self,v)
 if v.type=="nil"then return nil elseif v.type=="scalar"then return v.value elseif v.type=="player"then return known(self.room:findPlayerByObjectName(v.name,true),"cached target")elseif v.type=="card"then return visible(self,v.id)
 elseif v.type=="recipe"then local r=v.value;if r.prototype then return policy(self,(r.prototype:sub(1,1)=="#"and(r.prototype..":"..(#r.subcards>0 and table.concat(r.subcards,"+")or".")..":"..(r.user or""))or("@"..r.prototype.."="..(#r.subcards>0 and table.concat(r.subcards,"+")or".")..(r.user and":"..r.user or""))))end
 local c=self:evaluateOwnerViewAsCard(r);recipes[c]=copy(r);return c
 elseif v.type=="table"then local t={};for k,x in pairs(v.value)do t[k]=state_decode(self,x)end;if#t>0 then return AIList.new(t)end;return t end
 ai_unsupported("invalid source observation cache","htms")
end
local state_fields={'MingceTarget','dahe_card'}
local function load_state(self)
 if self._htms_state_loaded then return end;self._htms_state_loaded=true
 for _,k in ipairs(state_fields)do local r,ok=self:getStrategyMemory("htms."..k);if ok then self[k]=state_decode(self,r)end end

end
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~="table"then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function save_state(self)
 for _,k in ipairs(state_fields)do local prior,present=self:getStrategyMemory("htms."..k);local v=self[k]
  if present or v~=nil then local encoded=state_encode(self,v);if not present or not same(prior,encoded)then self:setStrategyMemory("htms."..k,encoded)end end
 end

end

local function BeMan(room,owner,dead)
 if AIValue.isPlayer(owner)then owner=owner:objectName()end
 for _,p in ipairs(known(room:getAllPlayers(),"registered room players"))do if p:objectName()==owner then return p end end
end
local function list_i2c(self,ids)local cards=AIList.new({});for _,id in ipairs(ids)do cards:append(visible(self,id))end;return cards end
local function source_patterns(self,class)
 local names=known(AICardCatalog.patternNames(),"public pattern names")
 if type(class)~="string"then return names end
 local classes=known(AICardCatalog.patternClassNames(),"public class-to-name catalog")
 return classes[class]or class
end
local function RandomList(items)
 local remaining={};for _,v in ipairs(items)do remaining[#remaining+1]=v end
 while #remaining>0 do local v=remaining[math.random(1,#remaining)];table.removeOne(remaining,v);table.removeOne(items,v);items[#items+1]=v end
 return items
end

local function set_observation_mark(self,key,value)
 self:setStrategyMemory("htms.mark:"..key,value)
end
local function observation_mark(self,key)
 local value,present=self:getStrategyMemory("htms.mark:"..key)
 if present then return value end
 return __htms_value_call(self.player,"getMark",key)
end
-- PatternsCard scans Engine::getRandomCards, whose mode/banlist filtering is not projected.
local function pattern_card(self,name)
 ai_unsupported("PatternsCard random card pool is not projected",name)
end

local function printed(self,id)return known(self:getPrintedCardById(id),"lawful printed card descriptor")end
local function set_observation(self,k,v)self:setStrategyMemory("htms.observation:"..k,v)end
local function room_tag(self,k,kind)
 if k:sub(1,3)=="ai_"then
  local v,ok=self:getStrategyMemory("htms.observation:"..k)
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
 ai_unsupported("other players' properties are not projected",k)
end
local function complete_hand(self,p)
 if p:objectName()==self.player:objectName()then return known(p:getHandcards(),"owner hand")end
 local cards=known(p:getKnownCards(),"known hand");if #cards~=__htms_value_call(p,"getHandcardNum")then ai_unsupported("source branch requires full foreign hand identity","htms.hand")end;return cards
end
local function viewer_role(self,p)
 local exact=p:getRole();if exact~=nil and exact~="unknown"and exact~="neutral"then return exact end
 local role=self:getRoleEstimate(p);if role==nil or role=="neutral"or role=="unknown"then ai_unsupported("source role unavailable from viewer knowledge","htms.role")end
 return self:useKnowledgeEstimate({value=role,status="estimate",basis="viewer_role_inference_replaces_private_role",viewer=self.player:objectName(),target=p:objectName()},"htms.role")
end
local function forbidden_foreign_ai(self)ai_unsupported("other AI private state is not available","htms")end
local function role_event(self,p,kind,role)
 -- Callers run on the skill's own event and pass a player whose skill is public.
 if role~="lord"and role~="loyalist"and role~="rebel"and role~="renegade"then ai_unsupported("source role event inference unresolved",kind)end
 local assigned=kind=="Cjiyongbing"and role or(role=="rebel"and"loyalist"or role)
 self:emitStrategyEffect({kind="role_row_update",player=p:objectName(),role=role,assigned_role=assigned,assigned_value=kind=="Cjiyongbing"and 1000 or 0,source_skill=kind})
end

-- Only package-local authored CardUseStruct values, not an unrestricted native QVariant/tag gateway.
local function local_data()
 local value
 return{setValue=function(_,v)value=v end,toCardUse=function()return value or{to=AIList.new({})}end}
end
sgs.ai_event_callback[sgs.GameStart]=sgs.ai_event_callback[sgs.GameStart]or{}
sgs.ai_event_callback[sgs.Death]=sgs.ai_event_callback[sgs.Death]or{}
sgs.ai_event_callback[sgs.TurnStart]=sgs.ai_event_callback[sgs.TurnStart]or{}
local function Table2Playerlist(thetable)
	assert(type(thetable)=="table")
	local playerlist = AIList.new({})
	for _,player in ipairs(thetable) do
		playerlist:append(player)
	end
	return playerlist
end
local function Table2SPlayerlist(thetable)
	assert(type(thetable)=="table")
	local playerlist = AIList.new({})
	for _,player in ipairs(thetable) do
		playerlist:append(player)
	end
	return playerlist
end
local function Ids2Cards(self,thetable)
	local cards = {}
	for _,card_id in ipairs(thetable) do
		table.insert(cards,visible(self,card_id))
	end
	return cards
end


local function Table2IntList(theTable)
	local result = AIList.new({})
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end



sgs.ai_cardneed.zhuisha = sgs.ai_cardneed.slash
sgs.ai_skill_invoke.zhuisha = function(self,data)
	local effect = data:toCardEffect()
	if self:isFriend(effect.to,self.player) then return false end
	return true
end
sgs.ai_skill_cardask["@zhuisha_ask"] = function(self,data,pattern,target)
	local card_list = self.player:getHandcards()
	local cards = sgs.QList2Table(card_list)
	cards = self:sortByKeepValue(cards,false)
	return "$"..__htms_value_call(cards[1],"getEffectiveId")
end
sgs.ai_ajustdamage_from.zhuisha = function(self, from, to, card, nature)
	if card and __htms_value_call(card,"isKindOf","Slash") then
		return to:getPile("zhui"):length()
	end
end
sgs.ai_ajustdamage_from.htms_zangsong = function(self, from, to, card, nature)
	if card and __htms_value_call(card,"isKindOf","Slash") and table.contains(card:getSkillNames(), "htms_zangsong") then
		return __htms_value_call(to,"getLostHp")
	end
end
sgs.ai_fill_skill["htms_zangsong"] = function(self,inclusive,request)
    if self.player:hasUsed("#htms_zangsongCard") then return nil end
	if  (#self.enemies == 0) then return nil end
	return policy(self,"#htms_zangsongCard:.:")
end

sgs.ai_skill_use_func["#htms_zangsongCard"] =function(card,use,self)
	self.enemies = self:sort(self.enemies, "defense")
	local use_card
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if __htms_value_call(card,"isDamageCard") then
			use_card = card
		end
	end
	if not use_card then return end
	local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
	slash = mutate(self,slash,"skill","htms_zangsong")
	slash = mutate(self,slash,"add",use_card)
	slash:deleteLater()

	local dummy = self:aiUseCard(slash, dummy_plan())
	if dummy.card and dummy.to:length() > 0
	then
		use.card = policy(self,"#htms_zangsongCard:"..__htms_value_call(use_card,"getEffectiveId") ..":")
		if use.to then use.to = dummy.to end
		return
	end
end

sgs.ai_use_value["htms_zangsongCard"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["htms_zangsongCard"] = sgs.ai_use_priority.Slash - 0.2
sgs.ai_skill_invoke.shilian = function(self,data)
	local damage = data:toDamage()
	local slash = clone(self,"slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	if self:isFriend(damage.from,self.player) then return false end
	if  damage.from and self:isEnemy(damage.from) and  self:slashIsEffective(slash, damage.from) and not self:slashProhibit(slash, damage.from) and self:isGoodTarget(damage.from, self.enemies, slash) then
	return true
	end
end

sgs.ai_skill_invoke.shilianEX = function(self,data)
	local damage = data:toDamage()
	local slash = clone(self,"slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	if self:isFriend(damage.from,self.player) then return false end
	if  damage.from and self:isEnemy(damage.from) and  self:slashIsEffective(slash, damage.from) and not self:slashProhibit(slash, damage.from) and self:isGoodTarget(damage.from, self.enemies, slash) then
	return true
	end
end
sgs.ai_choicemade_filter.skillInvoke.shilianEX = function(self,player,promptlist)
	local damage = room_tag(self,"CurrentDamageStruct","Damage")
	if damage.from and damage.to then
		if promptlist[#promptlist]=="yes" then
			if not self:needToLoseHp(damage.from,player,damage.card) then
				self:updateIntention(damage.to,damage.from,40)
			end
		elseif self:canAttack(damage.from) then
			self:updateIntention(damage.to,damage.from,-40)
		end
	end
end


sgs.ai_skill_invoke.xianxuefeiteng = function(self,data)
	if __htms_value_call(self.player,"getLostHp") > __htms_value_call(self.player,"getHp") then
		if self:isWeak() and self:getCardsNum("Slash") < 2 then
			return true
		end
	else
		if self:getCardsNum("Peach") > 0 then
			return true
		end
	end
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|xianxuefeiteng"

sgs.ai_skill_choice.fengwang = function(self,choices)
	if self:needKongcheng(self.player) or self:isWeak(self.player) then return "fengwang_discard" end
	local card_list = self.player:getHandcards()
	local x = 0
	for _,card in sgs.qlist(card_list) do
		if __htms_value_call(card,"isKindOf","Slash") then x = x + 1 end
	end
	if x > 2 then return "fengwang_equip" end
	return "fengwang_discard"
end
sgs.ai_skill_cardask["@fengwang_askforequip"] = function(self,data,pattern,target)
	local card_list = self.player:getCards("e")
	local cards = sgs.QList2Table(card_list)
	cards = self:sortByKeepValue(cards,false)
	return "$"..__htms_value_call(cards[1],"getEffectiveId")
end
sgs.ai_fill_skill["fengwang"] = function(self,inclusive,request)
	if self.player:hasUsed("#fengwang") then return end
	return policy(self,"#fengwang:.:")
end
sgs.ai_skill_use_func["#fengwang"] = function(card,use,self)
	local player = self.player
	local room = player:getRoom()
	local cards = sgs.QList2Table(complete_hand(self,player))
	for _,card in ipairs(cards) do
		if not __htms_value_call(card,"isKindOf","BasicCard") then table.removeOne(cards,card) end
	end
	cards = self:sortByKeepValue(cards,false)
	local players = sgs.QList2Table(room:getAlivePlayers())
	local targets = {}
	for _,target in ipairs(players) do
		local can_use = true
		if (self:isFriend(target,self.player)) or (target:isKongcheng()) or (target:getCards("e"):length() == 0) then can_use = false end
		if can_use then table.insert(targets,target) end
	end
	if #targets == 0 then
		use.card = nil
		return
	end
	local cards = sgs.QList2Table(complete_hand(self,player))
	cards = self:sortByUseValue(cards,true)
	local subcard
	for _,acard in ipairs(cards) do
		if __htms_value_call(acard,"isKindOf","BasicCard") then
			subcard = acard
			break
		end
	end
	if not subcard then
		use.card = nil
		return
	end
	use.card = policy(self,"#fengwang:.:")
	use.card = mutate(self,use.card,"add",subcard)
	targets = self:sort(targets,"handcard")
	if use.to then use.to:append(targets[#targets]) end
end
sgs.ai_use_value["fengwang"] = 9
sgs.ai_use_priority["fengwang"] = sgs.ai_use_priority.Dismantlement + 0.1
sgs.ai_card_intention["fengwang"] = sgs.ai_card_intention.Dismantlement
sgs.fengwang_keep_value = {
	BasicCard = 6
}

sgs.ai_skill_choice.newfengwang = function(self,choices, data)
	local target = data:toPlayer()
	if getKnownCard(target,self.player,"Jink")>0 and __htms_value_call(target,"getMark","&newfengwang+to+#".. self.player:objectName().. "-Clear") == 0  then return "newfengwang_discard" end
	if (not self:needToThrowArmor(target) and not target:hasArmorEffect("silver_lion") and not self:hasSkills(sgs.lose_equip_skill, target) or self:doDisCard(target, "e", true)) then return "newfengwang_equip" end
	return "newfengwang_equip"
end

sgs.ai_fill_skill["newfengwang"] = function(self,inclusive,request)
	if self.player:hasUsed("#newfengwang") then return end
	return policy(self,"#newfengwang:.:")
end
sgs.ai_skill_use_func["#newfengwang"] = function(card,use,self)
	local player = self.player
	local room = player:getRoom()
	local cards = sgs.QList2Table(complete_hand(self,player))
	for _,card in ipairs(cards) do
		if not __htms_value_call(card,"isKindOf","BasicCard") then table.removeOne(cards,card) end
	end
	cards = self:sortByKeepValue(cards,false)
	local players = sgs.QList2Table(room:getAlivePlayers())
	local targets, friends, enemies = {}, {}, {}
	for _, player in sgs.qlist(self.room:getPlayers()) do
        if not player:isKongcheng() then
            table.insert(targets, player)
            if self:isFriend(player) then
                table.insert(friends, player)
            elseif self:isEnemy(player) and self:doDisCard(player, "e", true) and not self:needToLoseHp(player) then
                table.insert(enemies, player)
            end
        end
    end

    if #targets == 0 then return end
    local target
	local slashcount = self:getCardsNum("Slash")
	if slashcount > 0 then
		local slashes = self:getCards("Slash")
		for _,slash in sgs.list(slashes)do
			local dummy_use = self:aiUseCard(slash, dummy_plan())
			if dummy_use.card then
				for _,p in sgs.qlist(dummy_use.to)do
					if p and self:isEnemy(p) and __htms_value_call(p,"getMark","&newfengwang+to+#".. self.player:objectName().. "-Clear") == 0 then
						target = p
                        break
					end
				end
			end
		end
	end

	 if not target then
        for _, enemy in ipairs(enemies) do
            if enemy:containsTrick("indulgence") then
                target = enemy
                break
            end
        end
    end

	if not target then
        for _, enemy in ipairs(enemies) do
            if self:getDangerousCard(enemy) then
                target = enemy
                break
            end
        end
    end

	 if not target then
        for _, enemy in ipairs(enemies) do
            if self:getValuableCard(enemy) then
                target = enemy
                break
            end
        end
    end

	if not target then
        for _, friend in ipairs(friends) do
            if self:needToThrowArmor(friend) or friend:hasArmorEffect("silver_lion") or __htms_value_call(friend,"hasSkill","yqijiang") then
                target = friend
                break
            end
        end
    end
	if not target then
        for _, enemy in ipairs(enemies) do
            if self:doDisCard(enemy, "e", true) then
                if enemy:getDefensiveHorse() then
                    target = enemy
                    break
                end
                if not target then
                    if enemy:getArmor() and not self:needToThrowArmor(enemy) then
                        target = enemy
                        break
                    end
                end
            end
        end
    end

	local cards = sgs.QList2Table(complete_hand(self,player))
	cards = self:sortByUseValue(cards,true)
	local subcard
	for _,acard in ipairs(cards) do
		if __htms_value_call(acard,"isKindOf","BasicCard") then
			subcard = acard
			break
		end
	end
	if not subcard then
		use.card = nil
		return
	end
	if not target then
		use.card = nil
		return
	end
	use.card = policy(self,"#newfengwang:.:")
	use.card = mutate(self,use.card,"add",subcard)
	targets = self:sort(targets,"handcard")
	if use.to then use.to:append(target) end
end

sgs.ai_cardneed.newfengwang = sgs.ai_cardneed.slash



sgs.ai_use_value["newfengwang"] = 9
sgs.ai_use_priority["newfengwang"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_card_intention["newfengwang"] = sgs.ai_card_intention.Dismantlement
sgs.fengwang_keep_value = {
	BasicCard = 6
}
sgs.hit_skill = sgs.hit_skill .. "|newfengwang"

sgs.ai_fill_skill["wangzhe"] = function(self,inclusive,request)
	local player = self.player
	local slash = clone(self,"Slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	if player:isLocked(slash) or __htms_value_call(player,"getMark","wangzhe_used") > 0 then return end
	local cards = sgs.QList2Table(player:getCards("he"))
	if #cards == 0 then return end
	return policy(self,"#wangzhe:.:")
end
sgs.ai_skill_use_func["#wangzhe"] = function(card,use,self)
	local player = self.player
	local cards = sgs.QList2Table(player:getCards("he"))
	cards = self:sortByKeepValue(cards,false,true)
	local enemies = self.enemies
	local targets = {}
	enemies = self:sort(enemies)
	local slash = clone(self,"slash",sgs.Card_NoSuit,0)
	slash = mutate(self,slash,"skill","wangzhe")
	slash:deleteLater()
	local rangefix = 0
	if player:getWeapon() and player:getWeapon():getId() == cards[1]:getId() then
		local card = player:getWeapon():getRealCard():toWeapon()
		rangefix = card:getRange() - __htms_value_call(player,"getAttackRange",false)
	end
	local dummy_use = self:aiUseCard(slash, dummy_plan(true, 2))
	if __htms_value_call(slash,"isAvailable",self.player) and dummy_use.card and dummy_use.to then
		for _,p in sgs.qlist(dummy_use.to)do
			if player:canSlash(p,slash,true,rangefix,Table2Playerlist(targets)) then
				table.insert(targets,p)
			end
		end
	end
	if #targets == 0 then
		use.card = nil
		return
	end
	targets = self:sort(targets,"hp")
	if not self:hasHeavyDamage(targets[1],use.card,player) and not self:isWeak() and not self:isWeak(targets[1]) then
		use.card = nil
		return
	end
	local card_str = ("#wangzhe:%d:"):format(cards[1]:getId())
	use.card = policy(self,card_str)
	if use.to then
		for _,p in sgs.list(targets)do
			use.to:append(p)
		end
	end

end
sgs.ai_use_priority["wangzhe"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_card_intention["wangzhe"] = sgs.ai_card_intention.Slash

sgs.ai_cardneed.wangzhe = sgs.ai_cardneed.slash

sgs.ai_skill_invoke.doubleslash = function(self)  --必定使用
		return true
end

sgs.ai_skill_cardask["@doubleslash"] = function(self, data, pattern)
	local cards = AIList.new({})
	local peach = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards, true)
	local slashcount = self:getCardsNum("Slash")
	if slashcount == 0 then return "$" .. __htms_value_call(cards[1],"getEffectiveId") end		--斷殺就隨便棄
	local slash = self:getCard("Slash")
	local dummy_use = { isDummy = true, extra_target = 1, to = AIList.new({}) }
	if slash then self:useBasicCard(slash, dummy_use) end
	if slashcount >= 1 and slash and dummy_use.card  then
		for _, card in ipairs(cards) do
			if card:isRed() and #self.enemies <= 1 then
				return "$" .. __htms_value_call(card,"getEffectiveId") 					--只有一個敵人就盡量棄紅的
			elseif card:isBlack() and #self.enemies > 1 then
				return "$" .. __htms_value_call(card,"getEffectiveId")
			end
		end
	end
	return "$" .. __htms_value_call(cards[1],"getEffectiveId")
end

sgs.ai_cardneed.doubleslash = sgs.ai_cardneed.slash

function sgs.ai_armor_value.doubleslash(player, self, card)
    if card and (__htms_value_call(card,"isKindOf","Elucidator")) then return 4 end
end

sgs.ai_skill_askforag["betacheater"] = function(self,card_ids)
	local cards = Ids2Cards(self,card_ids)
	cards = self:sortByUseValue(cards,true)
	return cards[1]:getId()
end



sgs.ai_fill_skill["handsonic"] = function(self,inclusive,request)
	if self.player:hasUsed("#handsonicCard") then return end
	return policy(self,"#handsonicCard:.:")
end
sgs.ai_skill_use_func["#handsonicCard"] = function(card,use,self)
	local player = self.player
	local room = player:getRoom()
	local cards = sgs.QList2Table(complete_hand(self,player))
	for _,card in ipairs(cards) do
		if not __htms_value_call(card,"isKindOf","BasicCard") then table.removeOne(cards,card) end
	end
	cards = self:sortByKeepValue(cards,false)
	local players = sgs.QList2Table(room:getOtherPlayers(player))
	local targets = {}
	local friend = 0
	local enemy = 0
	for _,target in ipairs(players) do
		if  (not target:isNude()) and (not target:getArmor()) then
			table.insert(targets,target)
				if self:isFriend(target,self.player) then
					friend = friend + 1
				else
					enemy = enemy + 1
				end
		end
	end
	if #targets == 0  or friend>=enemy then
		use.card = nil
		return
	end
	local cards = sgs.QList2Table(complete_hand(self,player))
	cards = self:sortByUseValue(cards,true)
	local subcard
	for _,acard in ipairs(cards) do
		if __htms_value_call(acard,"isKindOf","BasicCard") then
			subcard = acard
			break
		end
	end
	if not subcard then
		use.card = nil
		return
	end
	use.card = policy(self,"#handsonicCard:.:")
	use.card = mutate(self,use.card,"add",subcard)
end

sgs.ai_use_value["handsonic"] = 9
sgs.ai_use_priority["handsonic"] = sgs.ai_use_priority.Dismantlement + 0.1

sgs.ai_skill_discard.handsonic = function(self, discard_num, min_num, optional, include_equip)

	local user = self.room:getCurrent()

	if not user then return {} end
	if  self:isFriend(user) then
	return self:askForDiscard("dummy", discard_num, min_num, false, include_equip, ".")
	end
	return {}
end


sgs.ai_skill_cardask["@defencefieldask"] = function(self, data, pattern, target, target2)
	local isUse = data:toStringList()[3] == "use"
	local use
	if isUse then
		if data:toStringList()[4] then
			use = history_use(self,data:toStringList()[4])
		end
	end
	local dest
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if __htms_value_call(aplayer,"hasFlag","defencefield_Target") then dest = aplayer break end
	end
	if not self:isFriend(dest) then return "." end
	local card
	local handcards = sgs.QList2Table(self.player:getCards("he"))
	local use_card = {}
	handcards = self:sortByKeepValue(handcards)
	for _,c in ipairs(handcards) do
		if not __htms_value_call(c,"isKindOf","Peach")
		and not __htms_value_call(c,"isKindOf","Analeptic")
		and not __htms_value_call(c,"isKindOf","Nullification")
		and c:isRed()
		and not (__htms_value_call(c,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length() > 0)
		then
			table.insert(use_card, c)
		end
	end
	if #use_card == 0 then return "." end

	if dest and __htms_value_call(dest,"hasFlag","dahe") then return "."  end
	if isUse then
		if use.card and __htms_value_call(use.card,"hasFlag","NosJiefanUsed") then return "."  end
		if not use.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,use.from)
		or __htms_value_call(use.card,"isKindOf","NatureSlash") and dest:isChained() and self:isGoodChainTarget(dest,use.card,use.from)
		or self:needToLoseHp(dest,use.from,use.card) and self:ajustDamage(use.from,dest,1,use.card)==1 then return "." end
	end
	if self:needToLoseHp(dest, nil, nil, true) then return "."  end
	if self:getCardsNum("Jink") == 0 then return use_card[1]:toString() end
	if self:ajustDamage(nil,dest,1,nil)>1 then return use_card[1]:toString() end
	if __htms_value_call(self.player,"getHandcardNum")==1 and self:needKongcheng()
	or not(self:hasLoseHandcardEffective() or self.player:isKongcheng()) then return use_card[1]:toString() end


	return use_card[1]:toString()
end

sgs.ai_choicemade_filter.cardResponded["@defencefieldask"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
	local dest
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if __htms_value_call(aplayer,"hasFlag","defencefield_Target") then dest = aplayer break end
	end
	if dest then
		self:updateIntention(player, dest, -80)
		end
	end
end
function sgs.ai_cardneed.defencefield(to, card, self)
	return card:isRed() and to:getCards("he"):length() < 4
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|defencefield"

sgs.ai_fill_skill["frozenpuppet"] = function(self,inclusive,request)
	local player = self.player
	if __htms_value_call(player,"getHandcardNum") < 3 then return end
	if __htms_value_call(player,"getMark","@frozenpuppet") == 0 then return end
	return policy(self,"#frozenpuppetCard:.:")
end


sgs.ai_use_value["frozenpuppetCard"] = 7
sgs.ai_use_priority["frozenpuppetCard"] =sgs.ai_use_priority.Peach - 5

sgs.ai_card_intention["frozenpuppetCard"] = -80


sgs.ai_skill_use_func["#frozenpuppetCard"] = function(card, use, self)
	local player = self.player
	if __htms_value_call(player,"getHandcardNum") < 1 then return end
	if __htms_value_call(player,"getMark","@frozenpuppet") == 0 then return end
	local friends = self.friends
	friends = self:sort(friends, "defense")
	local target
	local use_value = 0
	local max_value = -10000

	for _, friend in ipairs(self.friends) do
		use_value = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if self:isEnemy(p) then
					use_value = use_value + __htms_value_call(p,"getHandcardNum") / 5
					if __htms_value_call(p,"inMyAttackRange",friend) or self:isWeak(friend) then
						use_value = use_value + 1
					end
				end
		end
		use_value = use_value - __htms_value_call(self.player,"getHandcardNum") / 2
		use_value = use_value - __htms_value_call(friend,"getHandcardNum") / 2
		use_value = use_value + __htms_value_call(friend,"getLostHp") / 2
		if use_value > max_value then
			max_value = use_value
			target = friend
		end
	end

	if target and max_value >= self.player:aliveCount() / 2   then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end

	if self:isWeak()  then
		use.card = card
		if use.to then use.to:append(self.player) end
		return
	end
end

sgs.ai_target_revises["@frozenpuppettarg"] = function(to,card,self)
	return card and not __htms_value_call(card,"isKindOf","SkillCard") and self.player:objectName() ~= to:objectName()
end

sgs.ai_skill_discard["chuszy"] = function(self, discard_num, min_num, optional, include_equip)
	local damage = room_tag(self,"CurrentDamageStruct","Damage")
	if not self:isFriend(damage.to) or self.player:getCards("he"):length() < 2  then return {} end
	if self:isWeak(self.player) and damage.to:objectName() ~= self.player:objectName() then return {} end
	if __htms_value_call(damage.to,"getHp") > getBestHp(damage.to) then return {} end
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	usable_cards = self:sortByKeepValue(usable_cards)
	local to_discard = {}
	for _,c in ipairs(usable_cards) do
		if #to_discard < discard_num  and not __htms_value_call(c,"isKindOf","Peach") then
			table.insert(to_discard, __htms_value_call(c,"getEffectiveId"))
		end
	end
	if #to_discard > 0 then
		return to_discard
	end
end
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|chuszy"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|chuszy"
function sgs.ai_slash_prohibit.htms_xiaoshi(self, from, to)
	if __htms_value_call(from,"hasSkill","jueqing") or (__htms_value_call(from,"hasSkill","nosqianxi") and __htms_value_call(from,"distanceTo",to) == 1) then return false end
	if __htms_value_call(from,"hasFlag","NosJiefanUsed") then return false end
	if self:isFriend(to, from) and self:isWeak(to) then return true end
	return #(self:getEnemies(from)) > 1 and self:isWeak(to) and from:getEquips():length() > 1
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|htms_xiaoshi"


sgs.ai_fill_skill["mie"] = function(self,inclusive,request)
if __htms_value_call(self.player,"getMark","@Luazuihou") > 0 then
	if self.player:usedTimes("#mie") == 2 then return end
	return policy(self,"#mie:.:")
	else
	if self.player:hasUsed("#mie") then return end
	return policy(self,"#mie:.:")
	end
end
sgs.ai_skill_use_func["#mie"] = function(card,use,self)
	local player = self.player
	local room = player:getRoom()
	local cards = sgs.QList2Table(player:getCards("he"))
	if __htms_value_call(self.player,"getMark","@Luazuihou") == 0 then
		for _,card in ipairs(cards) do
			if not __htms_value_call(card,"isKindOf","BasicCard") then table.removeOne(cards,card) end
		end
	end
	cards = self:sortByKeepValue(cards)
	local target
	if __htms_value_call(self.player,"getMark","@Luazuihou") > 0 then
		target = self:findPlayerToDiscard("he", false, false)[1]
	else
		target = self:findPlayerToDiscard("he", false, true)[1]
	end
	local players = sgs.QList2Table(room:getOtherPlayers(player))
	if not target then
		use.card = nil
		return
	end
	local subcard
	for _,acard in ipairs(cards) do
		if not __htms_value_call(acard,"isKindOf","Peach") then
			subcard = acard
			break
		end
	end
	if not subcard then
		use.card = nil
		return
	end
	use.card = policy(self,"#mie:.:")
	use.card = mutate(self,use.card,"add",subcard)
	if use.to then use.to:append(target) end
end
sgs.ai_use_value["mie"] = 9
sgs.ai_use_priority["mie"] = sgs.ai_use_priority.Dismantlement + 0.1
sgs.ai_card_intention["mie"] = sgs.ai_card_intention.Dismantlement
sgs.mie_keep_value = {
	BasicCard = 6
}

sgs.ai_fill_skill["diancp"] = function(self,inclusive,request)
	if #self.enemies == 0 then return end
	return policy(self,"#diancp:.:")
end


sgs.ai_skill_use_func["#diancp"] = function(card, use, self)
	local cmp = function(a, b)
		if __htms_value_call(a,"getHp") < __htms_value_call(b,"getHp") then
			if __htms_value_call(a,"getHp") == 1 and __htms_value_call(b,"getHp") == 2 then return false else return true end
		end
		return false
	end
	local enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if self:canAttack(enemy, self.player) and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder,self.player) and self:canDamage(enemy,self.player,nil) then table.insert(enemies, enemy) end
	end
	if #enemies == 0 then return end

	local card_ids = {}
	local zcards = self.player:getHandcards()
	for _, zcard in sgs.qlist(zcards) do
		if __htms_value_call(zcard,"isKindOf","ThunderSlash") then
			table.insert(card_ids, zcard:getId())
		end
	end
	if #card_ids == 0 then return end
	local hc_num = #card_ids
	for _, enemy in ipairs(enemies) do
		if __htms_value_call(enemy,"getHp") > 1 then
				use.card = policy(self,"#diancp:.:")
				use.card = mutate(self,use.card,"add",card_ids[1])
				if use.to then use.to:append(enemy) end
				return
		else
			if not self:isWeak() or self:getSaveNum(true) >= 1 then
					use.card = policy(self,"#diancp:.:")
					use.card = mutate(self,use.card,"add",card_ids[1])
					if use.to then use.to:append(enemy) end
					return
			end
		end
	end
end


sgs.ai_ajustdamage_to.leij = function(self, from, to, card, nature)
	if nature == sgs.DamageStruct_Thunder
	then
		return -99
	end
end

sgs.ai_use_value["diancp"] = 9
sgs.ai_use_priority["diancp"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_card_intention["diancp"] = sgs.ai_card_intention.Slash


sgs.ai_skill_cardask["@emeng"] = function(self, data)
	local target = data:toPlayer()
	if not self:isEnemy(target) then return "." end
	if self:cantDamageMore(self.player,target) then return "." end

	local cards = sgs.QList2Table(self.player:getCards("eh"))
	cards = self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if not __htms_value_call(card,"isKindOf","Peach") and self:getUseValue(card) < 7 then return "$" .. __htms_value_call(card,"getEffectiveId") end
	end
	return "."
end


sgs.ai_ajustdamage_from.Luayezhan = function(self, from, to, card, nature)
	if __htms_value_call(from,"hasFlag","Luayezhan") and card and (__htms_value_call(card,"isKindOf","Slash") or __htms_value_call(card,"isKindOf","Duel")) then
		return 1
	end
end

sgs.ai_cardneed.Luayezhan = sgs.ai_cardneed.nosluoyi


sgs.ai_skill_use["@@jiasugaobai"] = function(self, prompt, method)
	local data = room_data(self,"jiasugaobai")
	local use = data:toCardUse()
	if __htms_value_call(use.card,"isKindOf","Duel") then
		if not self:hasTrickEffective(use.card, self.player) then return "." end
		if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player) then
			local  drawnum =  1
			local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
			local friends = {}
			for _, player in ipairs(players) do
				if self:isFriend(player) and self:needDraw(player, false) and __htms_value_call(player,"isMale") then
					table.insert(friends, player)
				end
			end
			for _, player in ipairs(players) do
				if self:isFriend(player) and self:canDraw(player, self.player) and not table.contains(friends, player) and __htms_value_call(player,"isMale") then
					table.insert(friends, player)
				end
			end
			if #friends == 0 then return "." end

			friends = self:sort(friends, "defense")
			for _, friend in ipairs(friends) do
				if __htms_value_call(friend,"getHandcardNum") < 2 and not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
							return  "#jiasugaobai:.:->" .. friend:objectName()
				end
			end

			local AssistTarget = self:AssistTarget()
			if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and (__htms_value_call(AssistTarget,"getHandcardNum") < __htms_value_call(AssistTarget,"getMaxCards") * 2 or __htms_value_call(AssistTarget,"getHandcardNum") < __htms_value_call(self.player,"getHandcardNum"))then
				for _, friend in ipairs(friends) do
					if friend:objectName() == AssistTarget:objectName() and not self:willSkipPlayPhase(friend) then
							return  "#jiasugaobai:.:->" .. friend:objectName()
					end
				end
			end

			for _, friend in ipairs(friends) do
				if self:hasSkills(sgs.dont_kongcheng_skill, friend) and friend:isKongcheng() then

						return  "#jiasugaobai:.:->" .. friend:objectName()
					end
			end
			for _, friend in ipairs(friends) do
				if self:hasSkills(sgs.cardneed_skill, friend) and not self:willSkipPlayPhase(friend) then

						return  "#jiasugaobai:.:->" .. friend:objectName()
					end
			end

			friends = self:sort(friends, "handcard")
			for _, friend in ipairs(friends) do
				if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then

							return  "#jiasugaobai:.:->" .. friend:objectName()
				end
			end

		end
	end
	return "."
end
sgs.ai_skill_invoke.juedoujiasu = function(self,data)
	return true
end

function sgs.ai_cardneed.juedoujiasu(to,card)
	return __htms_value_call(card,"isKindOf","Duel")
end

sgs.ai_skill_invoke.jiasuduijue = function(self,data)
	local use = data:toCardUse()
	local Duel = clone(self,"Duel", sgs.Card_SuitToBeDecided, 0)
	Duel = mutate(self,Duel,"skill","jiasuduijue")
	Duel:deleteLater()
	if __htms_value_call(use.card,"isKindOf","Slash") and use.card:isBlack() then
		if use.from:objectName() == self.player:objectName() then
			local dummy_use = self:aiUseCard(Duel, dummy_plan(true, 99))

			if self:hasHeavyDamage(use.from, use.card, self.player) then return false end
			local invoke = true
			for _, player in sgs.qlist(use.to) do
				if dummy_use.card and dummy_use.to:length() > 0 then
					if not dummy_use.to:contains(player) then
						invoke = false
					end
				end
				if  self:getCardsNum("Slash") < getCardsNum("Slash", player, self.player)  then invoke = false end
				if not self:hasTrickEffective(Duel, player) then invoke = false end
				if self:ajustDamage(self.player,player,1,Duel)==0 then invoke = false end
				if  getCardsNum("Jink", player, use.from) == 0  then invoke = false end
			end
			return invoke
		else
			if self:getCardsNum("Jink") == 0 or self:getCardsNum("Slash") > getCardsNum("Slash", use.from, self.player) or  self:hasHeavyDamage(use.from, use.card, self.player)  then
				return true
			end
		end
	end
	return false
end

sgs.ai_view_as.xiangy = function(card, player, card_place)
	local suit = __htms_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __htms_value_call(card,"getEffectiveId")
	if  not (__htms_value_call(card,"isKindOf","WoodenOx") and player:getPile("wooden_ox"):length() > 0)
	and __htms_value_call(card,"isKindOf","EquipCard")    then
		return ("jink:xiangy[%s:%s]=%d"):format(suit, number, card_id)
	end
end
sgs.ai_skill_playerchosen["xiangy"] = function(self, targets)
	if self:findPlayerToDiscard("ej", true, false, targets) ~= {} then
		return self:findPlayerToDiscard("ej", true, false, targets)[1]
	end
	return nil
end

sgs.ai_skill_choice.xiangy = function(self, choices)
	if self:findPlayerToDiscard("ej", true, false) ~= {} and not self:isWeak() then
		return "dis"
		end
	return "draw1"
end

sgs.use_lion_skill = sgs.use_lion_skill .. "|xiangy"

sgs.ai_fill_skill["jiujideqiyuan"] = function(self,inclusive,request)
	if not self.player:canDiscard(self.player, "he") then return end
	if self.player:hasUsed("#jiujideqiyuan") then return end
	local hurtF = 0
	if __htms_value_call(self.player,"isWounded") then return policy(self,"#jiujideqiyuan:.:") end
	for _,p in ipairs(self.friends_noself) do
		if __htms_value_call(p,"isWounded") then hurtF = hurtF + 1 end
	end
	if hurtF > 0 then return policy(self,"#jiujideqiyuan:.:") end
	return
end
sgs.ai_skill_use_func["#jiujideqiyuan"] = function(card, use, self)
	local targets = AIList.new({})
	local cards = self.player:getCards("he")

	local use_card = {}
	cards = sgs.QList2Table(cards)
	if #cards == 0 then return end
	cards = self:sortByKeepValue(cards)
	local basic, trick,equip = true,true,true
	for _, card in ipairs(cards) do
		if __htms_value_call(card,"isKindOf","BasicCard") and basic then
		basic = false
		table.insert(use_card, card:getId())
		elseif __htms_value_call(card,"isKindOf","TrickCard") and trick then
		trick = false
		table.insert(use_card, card:getId())
		elseif __htms_value_call(card,"isKindOf","EquipCard") and not (__htms_value_call(card,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and equip then
		equip = false
		table.insert(use_card, card:getId())
		end
	end

		for _,p in ipairs(self.friends) do
			if __htms_value_call(p,"getHp") < getBestHp(p) then targets:append(p) end
			if targets:length() >= #use_card then
				break
			end
		end

	if targets:length() < #use_card  then
		table.removeOne(use_card, use_card[#use_card])
	end
	if targets:length() < #use_card  then
		table.removeOne(use_card, use_card[#use_card])
	end
	if targets:length()> 0 then
		if #use_card == 1 then
		use.card = policy(self,"#jiujideqiyuan:"..use_card[1] ..":")
		else
		use.card = policy(self,"#jiujideqiyuan:".. table.concat(use_card, "+")..":")
		end
		if use.to then use.to = targets end
		return
	end
end



sgs.ai_use_value["jiujideqiyuan"] = 8
sgs.ai_use_priority["jiujideqiyuan"]  = 4.2

sgs.ai_card_intention["jiujideqiyuan"] = -100

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|jiujideqiyuan"

sgs.ai_use_revises.jiujideqiyuan = function(self,card,use)
	if __htms_value_call(card,"isKindOf","Slash") and self:isWeak()
	and self:getOverflow()<=0
	then return false end
end

sgs.ai_skill_choice["fazededizao"] = function(self, choices, data)
	local items = choices:split("+")
	local value_j = 0
	local value_d = 0
	local value_p = 0
	local value_t = 0
	if table.contains(items, "fzndz_1") then
	local judges = self.player:getJudgingArea()
		if not judges:isEmpty() then
			return "fzndz_1"
		end
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			local judges = p:getJudgingArea()
			if self:isFriend(p) then
				if not judges:isEmpty() then
				value_j = value_j + 1
				end
			elseif self:isEnemy(p) and not judges:isEmpty() then
			value_j = value_j - 1
			end
		end
	end
	if table.contains(items, "fzndz_2") then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) then
				if __htms_value_call(p,"getHandcardNum") < 2 then
				value_d = value_d - 1
				end
			elseif self:isEnemy(p)  then
				if __htms_value_call(p,"getHandcardNum") < 2 then
					value_d = value_d + 1
				end
			end
		end
	end
	if table.contains(items, "fzndz_3") then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) then
				if self:getOverflow(p) > 0 then
				value_p = value_p - 1
				end
			elseif self:isEnemy(p)  then
				if self:getOverflow(p) > 0 then
					value_p = value_p + 1
				end
			end
		end
	end
	if table.contains(items, "fzndz_4") then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) then
				if self:getOverflow(p) > 0 then
				value_t = value_t + 1
				end
			elseif self:isEnemy(p)  then
				if self:getOverflow(p) > 0 then
					value_t = value_t - 1
				end
			end
		end
	end
	local temp = value_j
	if value_d > temp then
	temp = value_d
	end
	if value_p > temp then
	temp = value_p
	end
	if value_t > temp then
	temp = value_t
	end
	if temp > 0 then
		if temp == value_j and table.contains(items, "fzndz_1") then
		return "fzndz_1"
		elseif temp == value_p and table.contains(items, "fzndz_3") then
		return "fzndz_3"
		elseif temp == value_t and table.contains(items, "fzndz_4") then
		return "fzndz_4"
		elseif temp == value_d and table.contains(items, "fzndz_2") then
		return "fzndz_2"
		end
	else
		if #items == 2 then
			return items[math.random(1,#items)]
		end
		return "cancel"
	end
	return items[math.random(1,#items)]
end


sgs.ai_skill_invoke.gonglzs = function(self,data)
	local use = data:toCardUse()
	if not self.player:getJudgingArea():isEmpty() then
	return true
	end
	if self:isFriend(use.from) then
		if self:needToThrowArmor(self.player) and self:needToThrowArmor(use.from) then
			return true
		end
	else
		if self:needToThrowArmor(self.player) and not use.from:hasSkills(sgs.lose_equip_skill)  then
			return use.from:getCards("e"):length() > 0
		end
		if self.player:getCards("e"):length() > 0 and not use.from:hasSkills(sgs.lose_equip_skill) and ( use.from:getWeapon() and  use.from:getWeapon():isKindOf("Crossbow")) then
			return true
		end
		if self:getCardsNum("Jink") == 0 and __htms_value_call(self.player,"getHandcardNum") ~= self:getCardsNum("Peach") then
			return __htms_value_call(use.from,"getHandcardNum") > 0
		end
		if self:getCardsNum("Jink") > 1   then
			return __htms_value_call(use.from,"getHandcardNum") > 0
		end
	end

	return false
end

sgs.ai_skill_cardchosen["gonglzs"] = function(self, who, flags)
	local cards = sgs.QList2Table(who:getCards(flags))
	cards = self:sortByUseValue(cards, true)
	if self:isFriend(who) then
		if not who:getJudgingArea():isEmpty() then
			for _, judge in sgs.qlist(who:getJudgingArea()) do
				if not __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					return judge
				end
			end
		end
		if self:needToThrowArmor(who) then
			return who:getArmor()
		end
		return cards[1]
	else
		return cards[1]
	end
end
sgs.ai_choicemade_filter.cardChosen.gonglzs = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_invoke.shens = function(self,data)
	local target = data:toDying().who
	if self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.shens = function(self,player,promptlist)
	local dying = self.room:getCurrentDyingPlayer()
	if dying then
		if promptlist[#promptlist]=="yes" then
			self:updateIntention(player,dying,-10)
		end
	end
end

sgs.save_skill = sgs.save_skill .. "|shens"


sgs.ai_skill_playerchosen["hunq"] = function(self, targets)
	return self:findPlayerToDraw(true, 1)
end

sgs.ai_fill_skill["pojgj"] = function(self,inclusive,request)
	if self:isWeak() then return nil end

	local card_str = ("#pojgjCard:.:")
	return policy(self,card_str)
end

sgs.ai_skill_use_func["#pojgjCard"] = function(card, use, self)
	local arr1, arr2 = self:getWoundedFriend(false, false)
	if self:isWeak() then return  end
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and __htms_value_call(arr1[1],"getHp") < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority["pojgj"] = 4.2
sgs.ai_card_intention["pojgj"] = -100

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|pojgj"


sgs.ai_fill_skill["LuamuguanVS"] = function(self,inclusive,request)
	if not self.player:canDiscard(self.player,"he") then return end
	return policy(self,"#LuamuguanCard:.:")
end

sgs.ai_skill_use_func["#LuamuguanCard"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self.enemies = self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	cards = self:sortByUseValue(cards,true)
	if slashcount > 0  then
		for _, card in ipairs(cards) do
				if (not __htms_value_call(card,"isKindOf","Peach") and not __htms_value_call(card,"isKindOf","ExNihilo") and not __htms_value_call(card,"isKindOf","Jink")) or self:getOverflow() > 0 then
				local slash = self:getCard("Slash")
					assert(slash)
					local target
					local dummy_use = self:aiUseCard(slash, dummy_plan())
					if not dummy_use.to:isEmpty() then
						for _, p in sgs.qlist(dummy_use.to) do
							if __htms_value_call(p,"getMark","muguan") == 0 then
							target = p
								break
							end
						end
					end

						if target then
						use.card = policy(self,"#LuamuguanCard:"..card:getId()..":")
								if use.to then use.to:append(target) end
								return
						end
				end
			end
	end
end

sgs.ai_card_intention["LuamuguanCard"] = 70


sgs.ai_use_value["LuamuguanCard"] = 9.2
sgs.ai_use_priority["LuamuguanCard"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_ajustdamage_from.Luamuguan = function(self, from, to, card, nature)
	if to and __htms_value_call(from,"getMark","muguan") > 0 and __htms_value_call(to,"getMark","muguan") > 0 and from:objectName() ~= to:objectName()
	then
		return 1
	end
end
sgs.ai_ajustdamage_to.Luamuguan = function(self, from, to, card, nature)
	if to and __htms_value_call(from,"getMark","muguan") > 0 and __htms_value_call(to,"getMark","muguan") > 0 and from:objectName() ~= to:objectName()
	then
		return 1
	end
end

sgs.ai_view_as.soulfire = function(card, player, card_place)
	local suit = __htms_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __htms_value_call(card,"getEffectiveId")
	if  not (__htms_value_call(card,"isKindOf","WoodenOx") and player:getPile("wooden_ox"):length() > 0)
	and (__htms_value_call(card,"isKindOf","Jink") or __htms_value_call(card,"isKindOf","Slash"))   then
		return ("fire_slash:soulfire[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_skill_invoke.soulfire = function(self,data)
	local target = data:toDamage().to
	if self:isEnemy(target) and __htms_value_call(self.player,"getHp") > __htms_value_call(target,"getHp") and self:objectiveLevel(target) > 3 and not self:cantbeHurt(target) and self:canDamage(target,self.player,nil) and self:damageIsEffective(target) then
	return true
	end
	return false
end

sgs.ai_fill_skill["soulfire"] = function(self,inclusive,request)
	local cards = self:addHandPile("he")
	cards = self:sortByUseValue(cards,true)
	local red_card = {}
	self.enemies = self:sort(self.enemies,"defense")
	for _,card in ipairs(cards)do
		if (__htms_value_call(card,"isKindOf","Slash") or __htms_value_call(card,"isKindOf","Jink"))
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or residue(self,clone(self,"fire_slash"))>0)
		then table.insert(red_card,card) end
	end

	for _,card in ipairs(red_card)do
		local slash = clone(self,"fire_slash")
		slash = mutate(self,slash,"add",card)
		slash = mutate(self,slash,"skill","soulfire")
		if __htms_value_call(slash,"isAvailable",self.player)
		then return slash end
	end
end


sgs.ai_fill_skill["jfxl"] = function(self,inclusive,request)
	if not self.player:hasUsed("#jfxl") then
		return policy(self,"#jfxl:.:")
	end
end

sgs.ai_skill_use_func["#jfxl"] = function(card, use, self)
local handcards = sgs.QList2Table(self.player:getCards("he"))
	local use_card = {}
	handcards = self:sortByUseValue(handcards, true)
	for _,c in ipairs(handcards) do
		if (__htms_value_call(c,"isKindOf","Jink") and self:getCardsNum("Jink") > 1) or not __htms_value_call(c,"isKindOf","Peach") then
			table.insert(use_card, c)
		end
	end
		self.enemies = self:sort(self.enemies, "hp")
		local value = 0
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and self:canDamage(enemy,self.player,nil) then
				if __htms_value_call(enemy,"distanceTo",self.player) == 1 and __htms_value_call(self.player,"getHp") > __htms_value_call(enemy,"getHp") and __htms_value_call(self.player,"getHp") > 1 then
				value = value + 3
				end
			end
		end
	for _, friend in ipairs(self.friends_noself) do
		if __htms_value_call(friend,"distanceTo",self.player) == 1 then
			if (not self:cantbeHurt(friend) or self:damageIsEffective(friend)) then
				value = value - 2
			end
		end
	end
	if value > 0 then
	use.card = policy(self,"#jfxl:" .. __htms_value_call(use_card[1],"getEffectiveId")..":")

					return
					end
end

sgs.ai_use_value["#jfxl"] = 2.5
sgs.ai_card_intention["#jfxl"] = 80
sgs.dynamic_value.damage_card["#jfxl"] = true

sgs.ai_view_as.zhenhong = function(card, player, card_place)
	local suit = __htms_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __htms_value_call(card,"getEffectiveId")
	if  not (__htms_value_call(card,"isKindOf","WoodenOx") and player:getPile("wooden_ox"):length() > 0) and __htms_value_call(player,"getPhase") == sgs.Player_NotActive   then
		return ("fire_slash:zhenhong[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.hit_skill = sgs.hit_skill .. "|zhenhong"
sgs.ai_skill_invoke.tprs = function(self,data)
	local slash = clone(self,"fire_slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	slash = mutate(self,slash,"skill","tprs")
	local x = -(__htms_value_call(self.player,"getHp") - 1)
	local targets_list = AIList.new({})
	for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __htms_value_call(self.player,"distanceTo",target) <= 1 then
			targets_list:append(target)
		end
	end
	if targets_list:length() > 0 then
		for _, target in sgs.qlist(targets_list) do
			if self.player:canSlash(target) and not self:slashProhibit(slash, target) and self:slashIsEffective(slash, target) and self:isGoodTarget(target, self.enemies, slash) then
				if self:isFriend(target) then
					x = x - (__htms_value_call(self.player,"getHp") - 1)
				else
					x = x + (__htms_value_call(self.player,"getHp") - 1)
				end
			end
		end
		for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not targets_list:contains(target) and __htms_value_call(self.player,"inMyAttackRange",target) then
				if self:isEnemy(target) then
					if not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) and not self:needToLoseHp(target, self.player) then
						x = x + 1
					else
						x = x - 1
					end
				elseif self:isFriend(target) then
					if self:needToLoseHp(target, self.player) and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) then
						x = x + 1
					else
						x = x - 1
					end
				end
			end
		end
		if x > 0 then
			return true
		end
	end
	return false
end
sgs.ai_ajustdamage_from.tprs = function(self, from, to, card, nature)
	if card and __htms_value_call(card,"isKindOf","Slash") and table.contains(card:getSkillNames(), "tprs") then
		return __htms_value_call(from,"getMark","tprs")
	end
end

sgs.ai_skill_invoke.duanzui = function(self,data)
	local target = data:toPlayer()
	if self:isEnemy(target) then
		if not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) and not self:needToLoseHp(target, self.player) then
			return true
		end
	elseif self:isFriend(target) then
		return self:needToLoseHp(target, self.player) and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player)
	end
	return false
end

sgs.ai_skill_invoke.meihuomoyan = function(self,data)
	local use = data:toCardUse()
	if self:isFriend(use.to:first()) then
		if self:isEnemy(use.from)
			or (self:isFriend(use.from) and self.role=="loyalist" and not __htms_value_call(use.from,"hasSkill","jueqing") and __htms_value_call(use.from,"isLord")) then
				if __htms_value_call(use.card,"isKindOf","Slash") then
					if not self:slashIsEffective(use.card,use.to:first(),use.from) then return false end
					if self:ajustDamage(use.from,use.to:first(),1,use.card)>1 then return true end

					if self:getCardsNum("Jink")<1 then
						if __htms_value_call(use.card,"isKindOf","NatureSlash") and use.to:first():isChained() and not self:isGoodChainTarget(use.to:first(),use.card,use.from) then return true end
						if __htms_value_call(use.from,"hasSkill","nosqianxi") and __htms_value_call(use.from,"distanceTo",use.to:first())==1 then return true end
						if self:isFriend(use.from) and self.role=="loyalist" and not __htms_value_call(use.from,"hasSkill","jueqing") and __htms_value_call(use.from,"isLord") and use.to:first():getHp()<2 then return true end
						if (not (self:hasSkills(sgs.masochism_skill) or (use.to:first():hasSkill("tianxiang") and getKnownCard(use.to:first(),use.to:first(),"heart")>0)) or __htms_value_call(use.from,"hasSkill","jueqing"))  then
							return true
						end
					end
				elseif __htms_value_call(use.card,"isKindOf","AOE") then
					local from = use.from
					if __htms_value_call(use.card,"isKindOf","SavageAssault") then
						local menghuo = self.room:findPlayerBySkillName("huoshou")
						if menghuo then from = menghuo end
					end

					local friend_null = 0
					for _,p in sgs.qlist(self.room:getOtherPlayers(use.to:first()))do
						if self:isFriend(p) then friend_null = friend_null+getCardsNum("Nullification",p,use.to:first()) end
						if self:isEnemy(p) then friend_null = friend_null-getCardsNum("Nullification",p,use.to:first()) end
					end
					friend_null = friend_null+self:getCardsNum("Nullification")
					local sj_num = self:getCardsNum(__htms_value_call(use.card,"isKindOf","SavageAssault") and "Slash" or "Jink")

					if not self:hasTrickEffective(use.card,use.to:first(),from) then return false end
					if not self:damageIsEffective(use.to:first(),sgs.DamageStruct_Normal,from) then return false end
					if __htms_value_call(use.from,"hasSkill","drwushuang") and use.to:first():getCardCount()==1 and self:hasLoseHandcardEffective() then return true end
					if sj_num==0 and friend_null<=0 then
						if self:isEnemy(from) and __htms_value_call(from,"hasSkill","jueqing") then return true end
						if self:isFriend(from) and self.role=="loyalist" and __htms_value_call(from,"isLord") and use.to:first():getHp()==1 and not __htms_value_call(from,"hasSkill","jueqing") then return true end
						if (not (self:hasSkills(sgs.masochism_skill) or (use.to:first():hasSkill("tianxiang") and getKnownCard(use.to:first(),use.to:first(),"heart")>0)) or __htms_value_call(use.from,"hasSkill","jueqing"))  then
							return true
						end
					end
				elseif self:isEnemy(use.from) then
					if not self:hasTrickEffective(use.card,use.to:first()) then return false end
					if __htms_value_call(use.card,"isKindOf","FireAttack") and __htms_value_call(use.from,"getHandcardNum")>0 then
						if not self:damageIsEffective(use.to:first(),sgs.DamageStruct_Fire,use.from) then return false end
						if (use.to:first():hasArmorEffect("vine") or use.to:first():getMark("&kuangfeng")>0) and __htms_value_call(use.from,"getHandcardNum")>3
						and not(__htms_value_call(use.from,"hasSkill","hongyan") and getKnownCard(use.to:first(),use.to:first(),"spade")>0)
						then return true
						elseif use.to:first():isChained() and not self:isGoodChainTarget(use.to:first(),nil,use.from)
						then return true end
					elseif (__htms_value_call(use.card,"isKindOf","Snatch") or __htms_value_call(use.card,"isKindOf","Dismantlement"))
					and self:getCardsNum("Peach")==use.to:first():getHandcardNum() and not use.to:first():isKongcheng()
					then return true
					elseif __htms_value_call(use.card,"isKindOf","Duel") then
						if self:getCardsNum("Slash")<1
						or self:getCardsNum("Slash")<getCardsNum("Slash",use.from,use.to:first()) then
							if not self:damageIsEffective(use.to:first(),sgs.DamageStruct_Normal,use.from) then return false end
							return true
						end
					end
				end
			end
	elseif self:isEnemy(use.to:first()) then
		if __htms_value_call(use.card,"isKindOf","Peach") or __htms_value_call(use.card,"isKindOf","ExNihilo") then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen["meihuomoyan"] = function(self, targets)
	local targets = sgs.QList2Table(targets)
	local use = room_tag(self,"CurrentUseStruct","CardUse")
	local card = use.card
	local target = use.to:first()
	local dummy_use = self:aiUseCard(card, dummy_plan())
	if dummy_use.card and dummy_use.to:length() > 0 then
		for _,p in sgs.list(dummy_use.to)do
			if table.contains(targets, p) then
				return p
			end
		end
	end
	if __htms_value_call(card,"isKindOf","Peach") then
		local arr1,arr2 = self:getWoundedFriend(false,true)
		local target = nil

		if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and __htms_value_call(arr1[1],"getHp")<getBestHp(arr1[1]) then target = arr1[1] end
		if target and table.contains(targets, target) then
			return target
		end
		if self:getOverflow()>0 and #arr2>0 then
			for _,friend in ipairs(arr2)do
				if table.contains(targets, friend)  then
					return friend
				end
			end
		end
	end
	return nil
end
sgs.ai_skill_playerchosen.kaleidoscope = function(self, targets)
	targets = sgs.QList2Table(targets)
	return targets[math.random(1, #targets)]
end
sgs.ai_skill_cardask["@haniel"] = function(self, data, pattern)
	local hcards = self.player:getCards("he")
	hcards = sgs.QList2Table(hcards)
	hcards = self:sortByUseValue(hcards, true)
	for _, hcard in ipairs(hcards) do
		return "$" .. __htms_value_call(hcard,"getEffectiveId")
	end
end

sgs.bad_skills = sgs.bad_skills .. "|haniel"

sgs.ai_fill_skill["guancha"] = function(self,inclusive,request)
	if #self.friends <= 1 then return end
	local source = self.player
	if source:isKongcheng() then return end
	if source:hasUsed("#guancha") then return end
	return policy(self,"#guancha:.:")
end

sgs.ai_skill_use_func["#guancha"] = function(card,use,self)
	local target
	local max_num =  math.floor((__htms_value_call(self.player,"getHandcardNum") + 1) / 2)
	local max_x = 0
	for _,friend in ipairs(self.friends_noself) do
		local x = 5 - __htms_value_call(friend,"getHandcardNum")
		if x > max_x and not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and self:canDraw(friend, self.player) then
			max_x = x
			target = friend
		end
	end
	local cards=sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	local needed = {}
	for _,acard in ipairs(cards) do
		if #needed < max_num then
			table.insert(needed, __htms_value_call(acard,"getEffectiveId"))
		end
	end
	if target and needed then
		use.card = policy(self,"#guancha:"..table.concat(needed,"+")..":")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["guancha"] = 4
sgs.ai_use_priority["guancha"]  = 1
sgs.ai_card_intention["guancha"]  = -60

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|guancha"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|guancha"

sgs.ai_skill_invoke.jiyi = function(self,data)
	local cardstr = sgs.ai_skill_use["@@jiyi"](self, "@jiyi")
    if cardstr:match(":.:") then
        return true
	end
	return false
end


sgs.ai_skill_use["@@jiyi"]=function(self,prompt)
	if self:isWeak() then return "." end
	if self:getOverflow() > 0 and self:getCardsNum("Peach") < 1 then return "." end
	return "#jiyi:.:"
end


sgs.ai_skill_choice.jiyi = function(self, choices)
    return "jiyi_throw"
end

sgs.ai_can_damagehp.jiyi = function(self, from, card, to)
	return __htms_value_call(to,"getHp") + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to) and not __htms_value_call(self.player,"isWounded")
end

sgs.ai_skill_invoke.Luachicheng = function(self, data)
	if self:needBear() then return true end
	if self.player:isSkipped(sgs.Player_Play) then return true end

	local chance_value = 1
	local peach_num = self:getCardsNum("Peach")
	local can_save_card_num = self:getOverflow(self.player, true) - __htms_value_call(self.player,"getHandcardNum")

	if __htms_value_call(self.player,"getHp") <= 2 and __htms_value_call(self.player,"getHp") < getBestHp(self.player) then chance_value = chance_value + 1 end
	return self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) - can_save_card_num + peach_num  <= chance_value
end

sgs.ai_ajustdamage_from.lianjiqudong = function(self, from, to, card, nature)
	if card and __htms_value_call(card,"isKindOf","Slash") then
		return __htms_value_call(from,"getMark","@lianjiqudong")
	end
end

sgs.ai_skill_invoke.lunhui1 = function(self, data)
	return true
end

sgs.ai_skill_use["@@lunhui"] = function(self, prompt, method)
	local will_use = self.player:getPile("lunhui")
	if will_use:isEmpty() then return "." end
	for _,id in sgs.qlist(will_use) do
		local card = visible(self,id)
		local dummy_use = self:aiUseCard(card, dummy_plan())
		if dummy_use.card then
			local targets = {}
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					table.insert(targets, p:objectName())
				end
				if #targets > 0 then
					return card:getLegacyStringKey() .. "->" .. table.concat(targets, "+")
				else
					return card:getLegacyStringKey()
				end
			end
		end
		if __htms_value_call(card,"isKindOf","EquipCard") then
			local dummy_use = dummy_plan()
			self:useEquipCard(card,dummy_use)
			if dummy_use.card then
				return card:getLegacyStringKey()
			end
		end
	end
	return "."
end

sgs.ai_hasTuntianEffect_skill.lunhui = function(to, need_zaoxian)
	return __htms_value_call(to,"getPhase") == sgs.Player_NotActive
end

sgs.ai_fill_skill["pocdsf"] = function(self,inclusive,request)
	local source = self.player
	if source:hasUsed("#pocdsf") then return end
	return policy(self,"#pocdsf:.:")
end

sgs.ai_skill_use_func["#pocdsf"] = function(card,use,self)
	if self:isWeak(self.player) then return nil end
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	local value = 0
	for _, target in ipairs(targets) do
	local count = 0
	if self:isFriend(target) then
		if  target:getWeapon() and self:hasSkills(sgs.lose_equip_skill, target) then
			for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
				if __htms_value_call(target,"inMyAttackRange",p) and self:isEnemy(p) then
					count = count + 1
				end
			end
			value = value - count
			end
		else
			if not target:getWeapon() or self:hasSkills(sgs.lose_equip_skill, target) then continue end
			for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
				if __htms_value_call(target,"inMyAttackRange",p) and self:isFriend(p) then
					count = count + 1
				end
			end
			value = value + count
		end
	end
	if value >= 1 then
		use.card = policy(self,"#pocdsf:.:")
		return
	end
end
sgs.ai_use_value["pocdsf"] = 5
sgs.ai_use_priority["pocdsf"]  = 7

sgs.ai_can_damagehp.moxing = function(self,from,card,to)
	if from and __htms_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and self:getCardsNum("Slash") > 0
	end
end

sgs.ai_skill_invoke.xiangrui = function(self, data)
	local damage = data:toDamage()

	if self:hasHeavyDamage(damage.from, damage.card, self.player) then
		return true
	end
	if self:needToLoseHp(self.player, damage.from) and damage.damage <= 1 then return false end
	return true
end

sgs.ai_skill_use["@@xiangrui"] = function(self, prompt, method)
	self.enemies = self:sort(self.enemies)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards, true)
	local card = cards[1]
	if card then
		for _, enemy in ipairs(self.enemies) do
				if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and self:canDamage(enemy,self.player,nil) then
						return "#xiangruiCard:"..__htms_value_call(card,"getEffectiveId") ..":->"..enemy:objectName()
				end
			end
		end
	return "."
end

sgs.ai_can_damagehp.xiangrui = function(self,from,card,to)
	local d = {damage=1}
	d.nature = card and sgs.card_damage_nature[__htms_value_call(card,"getClassName")] or sgs.DamageStruct_Normal
	return sgs.ai_skill_use["@@xiangrui"](self,d,sgs.Card_MethodDiscard)~="." and __htms_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|xiangrui"


sgs.ai_ajustdamage_to.wnlz = function(self, from, to, card, nature)
	if not card or card:isVirtualCard()
	then
		return -2
	end
	if card and __htms_value_call(card,"isKindOf","Slash") then
		return 1
	end
end
sgs.ai_fill_skill["hxss"] = function(self,inclusive,request)
	if __htms_value_call(self.player,"getMark","hxss-PlayClear") > 0 then return end
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local card

	cards = self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards)  do
		if  __htms_value_call(acard,"isKindOf","BasicCard")  and (self:getDynamicUsePriority(acard)<sgs.ai_use_value.mouthgun) then
			card = acard
			break
		end
	end

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if not visible(self,id):isKindOf("Peach")
			and visible(self,id):isKindOf("BasicCard")
			and (self:getDynamicUsePriority(visible(self,id)) < sgs.ai_use_value.mouthgun)
			then
				card = visible(self,id)
			end
		end
	end

	if not card then return nil end
	local suit = __htms_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __htms_value_call(card,"getEffectiveId")
	local card_str = ("mouthgun:hxss[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = policy(self,card_str)

	assert(skillcard)

	return skillcard
end
sgs.ai_cardneed.hxss = sgs.ai_cardneed.bignumber

sgs.ai_fill_skill["Luachuyi"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local card

	cards = self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards)  do
		if  __htms_value_call(acard,"isKindOf","EquipCard")  and (self:getDynamicUsePriority(acard)<sgs.ai_use_value.Peach) then
			card = acard
			break
		end
	end

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if not visible(self,id):isKindOf("Peach")
			and visible(self,id):isKindOf("EquipCard")
			and (self:getDynamicUsePriority(visible(self,id)) < sgs.ai_use_value.Peach)
			then
				card = visible(self,id)
			end
		end
	end

	if not card then return nil end
	local suit = __htms_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __htms_value_call(card,"getEffectiveId")
	local card_str = ("Peach:Luachuyi[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = policy(self,card_str)

	assert(skillcard)

	return skillcard
end
sgs.ai_view_as.Luachuyi = function(card, player, card_place)
	local suit = __htms_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __htms_value_call(card,"getEffectiveId")
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
	and __htms_value_call(card,"isKindOf","EquipCard") and __htms_value_call(player,"getPhase") == sgs.Player_NotActive and not (__htms_value_call(card,"isKindOf","WoodenOx") and player:getPile("wooden_ox"):length() > 0)
		and __htms_value_call(player,"getMark","Global_PreventPeach") == 0 then
		return ("peach:Luachuyi[%s:%s]=%d"):format(suit, number, card_id)
	end
end
sgs.ai_cardneed.Luachuyi = function(to,card)
	return __htms_value_call(card,"isKindOf","EquipCard")
end

sgs.ai_skill_invoke.Lualianji = function(self, data)
	return true
end

sgs.ai_cardneed.Lualianji = sgs.ai_cardneed.slash

sgs.ai_fill_skill["geass"] = function(self,inclusive,request)
	if #self.enemies < 1 then return end
	local source = self.player
	if source:hasUsed("#geasstarget") then return end
	return policy(self,"#geasstarget:.:")
end

sgs.ai_skill_use_func["#geasstarget"] = function(card,use,self)
	local target
    self.enemies = self:sort(self.enemies, "handcard")
	sgs.reverse(self.enemies)
	for _,enemy in ipairs(self.enemies) do
		if __htms_value_call(enemy,"getHandcardNum") > 0 and enemy:getEquips():length() > 0 then
			target = enemy
			break
		end
	end
	if target  then
		use.card = policy(self,"#geasstarget:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_askforag["geass"] = function(self, card_ids)
    local cards = {}
	self:writeCurrentSourceTarget("geassTarget",nil)
    for _, card_id in ipairs(card_ids) do
        table.insert(cards, visible(self,card_id))
    end
	cards = self:sortByUseValue(cards)
	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __htms_value_call(p,"getMark","geass_touse") > 0 then
			target = p
		end
	end
    for _, card in ipairs(cards) do
        if __htms_value_call(card,"isKindOf","Slash") then
			for _,enemy in ipairs(self.enemies) do
				local def = self:getDefenseSlash(enemy)
				local eff = self:slashIsEffective(card, enemy) and self:isGoodTarget(enemy, self.enemies, card)

				if target:canSlash(enemy, card, true) and not self:slashProhibit(card, enemy, target) and eff then
				self:writeCurrentSourceTarget("geassTarget",enemy)
				return __htms_value_call(card,"getEffectiveId")
				end
			end
		end
		if __htms_value_call(card,"isKindOf","Analeptic") then
			return __htms_value_call(card,"getEffectiveId")
		end
		if __htms_value_call(card,"isKindOf","Duel") or __htms_value_call(card,"isKindOf","Snatch") or __htms_value_call(card,"isKindOf","Dismantlement")  or __htms_value_call(card,"isKindOf","SupplyShortage") or __htms_value_call(card,"isKindOf","Indulgence")  then
			local dummy_use = self:aiUseCard(card, dummy_plan())
			if dummy_use.card and dummy_use and dummy_use.to then
				self:writeCurrentSourceTarget("geassTarget",dummy_use.to:first())
				return __htms_value_call(card,"getEffectiveId")
			end
		end

		if  __htms_value_call(card,"isKindOf","SavageAssault") or __htms_value_call(card,"isKindOf","ArcheryAttack") or __htms_value_call(card,"isKindOf","GodSalvation") then
			local dummy_use = self:aiUseCard(card, dummy_plan())
			if dummy_use.card then
				return __htms_value_call(card,"getEffectiveId")
			end
		end
		if __htms_value_call(card,"isKindOf","EquipCard") and not self:hasSkills(sgs.lose_equip_skill, target) then
			if __htms_value_call(card,"isKindOf","Weapon")  and target:getWeapon() and self:evaluateWeapon(card) < self:evaluateWeapon(target:getWeapon()) then return __htms_value_call(card,"getEffectiveId")
			elseif __htms_value_call(card,"isKindOf","Armor") and target:getArmor() and self:evaluateArmor(card) < self:evaluateArmor(target:getArmor()) then return __htms_value_call(card,"getEffectiveId")
			end
		end
    end
    return -1
end
sgs.ai_skill_use["@@geass"] = function(self, prompt, method)
	self.enemies = self:sort(self.enemies)
	local card = visible(self,__htms_value_call(self.player,"getMark","geass"))
	if card then
		if card:targetFixed() then
			return "#geass:"..__htms_value_call(card,"getEffectiveId") ..":"
		else
			if self:currentSourceTargetPresent("geassTarget") then
			return "#geass:"..__htms_value_call(card,"getEffectiveId")..":->"..self:readCurrentSourceTarget("geassTarget"):objectName()
			end
		end
	end
	return "."
end
sgs.ai_card_intention["#geasstarget"] = 60

sgs.ai_skill_invoke.znai = function(self, data)
	local target = data:toPlayer()
	return target and self:isFriend(target)
end

sgs.ai_skill_choice["znai"] = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()

    if #items == 1 then
        return items[1]
	else
		if  (target:hasSkills(sgs.cardneed_skill) or self:isWeak(target)) then
			return "znai2"
		end
		if  (target:hasSkills(sgs.need_equip_skill) and not self:isWeak(target)) then
			for _, enemy in ipairs(self.enemies) do
				if (not enemy:getEquips():isEmpty()) and not enemy:hasSkills(sgs.lose_equip_skill) then
					return "znai1"
				end
			end
		end

    end
    return "znai2"
end

sgs.ai_skill_use["@@znai"] = function(self, prompt, method)
	self.enemies = self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if (not enemy:getEquips():isEmpty()) and not enemy:hasSkills(sgs.lose_equip_skill) then
			return "#znai:.:->"..enemy:objectName()
		end
	end
	return "."
end
sgs.ai_skill_invoke.changedfate = function(self, data)
	local current = self.room:getCurrent()
	return current and self:isFriend(current)
end

sgs.ai_skill_invoke.tmsp = function(self, data)
	return self:isWeak() or sgs.ai_skill_invoke["tishen"](self, data)
end


sgs.ai_skill_invoke.wangzbk = function(self, data)
	return true
end

sgs.ai_skill_cardask["@bings-increase"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return "." end
	if target:hasArmorEffect("silver_lion") then return "." end



	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if __htms_value_call(card,"isKindOf","EquipCard") then return "$" .. __htms_value_call(card,"getEffectiveId") end
	end
	return "."
end

sgs.ai_skill_cardask["@bings-decrease"] = function(self, data)
	local damage = data:toDamage()


	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	if damage.card and __htms_value_call(damage.card,"isKindOf","Slash") then
		if self:hasHeavyDamage(damage.from, damage.card, self.player) then


			for _,card in ipairs(cards) do
				if __htms_value_call(card,"isKindOf","EquipCard") then return "$" .. __htms_value_call(card,"getEffectiveId") end
			end
		end
	end
	if self:needToLoseHp(self.player, damage.from) and damage.damage <= 1 then return "." end


	for _,card in ipairs(cards) do
		if __htms_value_call(card,"isKindOf","EquipCard") then return "$" .. __htms_value_call(card,"getEffectiveId") end
	end
	return "."
end

sgs.ai_ajustdamage_to.bings = function(self,from,to,card,nature)
	if to:getEquips():length()>0
	then return -1 end
end
sgs.ai_ajustdamage_from.bings = function(self,from,to,card,nature)
	if from:getEquips():length()>0 and not self:beFriend(to,from)
	then return 1 end
end

sgs.need_equip_skill = sgs.need_equip_skill .. "|bings"
sgs.ai_cardneed.bings = sgs.ai_cardneed.equip


sgs.ai_skill_choice.guailj = function(self, choices, data)
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, self.player)
		or self:needToLoseHp(self.player, self.player) then return "guailj2" end
	if self:isWeak() and not self:needDeath() then return "guailj1" end

	local value = 0
	for _, equip in sgs.qlist(self.player:getEquips()) do
		if __htms_value_call(equip,"isKindOf","Weapon") then value = value + self:evaluateWeapon(equip)
		elseif __htms_value_call(equip,"isKindOf","Armor") then
			value = value + self:evaluateArmor(equip)
			if self:needToThrowArmor() then value = value - 5 end
		elseif __htms_value_call(equip,"isKindOf","OffensiveHorse") then value = value + 2.5
		elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") then value = value + 5
		end
	end
	if value < 8 then return "guailj1" else return "guailj2" end
end

sgs.ai_fill_skill["guailj"] = function(self,inclusive,request)
	if __htms_value_call(self.player,"getMark","@guailj") <= 0 then return end
	if self.room:getMode() == "_mini_13" then return policy(self,"#guailj:.:") end
	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and self:isWeak(lord) then return end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) then
			if self:isFriend(player) then bad = bad + 1
			else good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(__htms_value_call(player,"getHp"), 1)
		if getCardsNum("Analeptic", player) > 0 then
			if self:isFriend(player) then good = good + 1.0 / hp
			else bad = bad + 1.0 / hp
			end
		end

		if self:hasSkills(sgs.lose_equip_skill, player) or self:needToThrowArmor(player) then
			if self:isFriend(player) then good = good + 2
			else bad = bad + 2
			end
		end

		if not player:getArmor() then
			local lost_value = 0
			if self:hasSkills(sgs.masochism_skill, player) then lost_value = __htms_value_call(player,"getHp")/2 end
			local hp = math.max(__htms_value_call(player,"getHp"), 1)
			if self:isFriend(player) then bad = bad + (lost_value + 1) / hp
			else good = good + (lost_value + 1) / hp
			end
		end
	end

	if good > bad then return policy(self,"#guailj:.:") end
end

sgs.ai_skill_use_func["#guailj"]=function(card,use,self)
	use.card = card
end

sgs.dynamic_value.damage_card["#guailj"] = true


sgs.ai_skill_invoke.guichan = function(self, data)
	local target = data:toPlayer()
	if target then
		if self:isFriend(target) then
			local can_use = true
			for _, player in sgs.qlist(self.room:getAlivePlayers()) do
				if self:getAllPeachNum()+__htms_value_call(target,"getHp")>0 then
					can_use = false
					break
				end
			end
			if can_use then
				return true
			else
				return false
			end
		else
			return true
		end
	else
		return true
	end
	return true
end

sgs.ai_skill_invoke.dafan = function(self, data)
	local damage = data:toDamage()
	if damage and damage.from and self:isEnemy(damage.from) then
	return true
	end
	return false
end
sgs.ai_skill_cardask["@dafanuj-give"] = function(self, data)
	local damage = data:toDamage()
    local cards = sgs.QList2Table(self.player:getHandcards())
    cards = self:sortByKeepValue(cards)
	if damage.to:objectName() == self.player:objectName() then
		local target = damage.from
		if damage.card and __htms_value_call(damage.card,"isKindOf","Slash") then
            if self:hasHeavyDamage(damage.from, damage.card, self.player) then
                for _,card in ipairs(cards) do
                    if __htms_value_call(card,"isKindOf","Slash") then return "$" .. __htms_value_call(card,"getEffectiveId") end
                end
            end
        end
        if (self:needToLoseHp(self.player, damage.from)) and damage.damage <= 1 then
            for _,card in ipairs(cards) do
                    if __htms_value_call(card,"isKindOf","Slash") then return "$" .. __htms_value_call(card,"getEffectiveId") end
                end
            else
            if __htms_value_call(damage.from,"getHandcardNum") > __htms_value_call(self.player,"getHandcardNum") then
                for _,card in ipairs(cards) do
                    if __htms_value_call(card,"isKindOf","TrickCard") then return "$" .. __htms_value_call(card,"getEffectiveId") end
                end
            end
        end
        return "$" .. __htms_value_call(cards[1],"getEffectiveId")
	elseif damage.from:objectName() == self.player:objectName() then
		if __htms_value_call(self.player,"getHandcardNum") > __htms_value_call(damage.to,"getHandcardNum") then
			for _,card in ipairs(cards) do
				if not __htms_value_call(card,"isKindOf","TrickCard") then return "$" .. __htms_value_call(card,"getEffectiveId") end
			end
		end
		if  getCardsNum("Slash", damage.to) > 0 then
			for _,card in ipairs(cards) do
				if  __htms_value_call(card,"isKindOf","Slash") then return "$" .. __htms_value_call(card,"getEffectiveId") end
			end
		end
	return "$" .. __htms_value_call(cards[1],"getEffectiveId")
	end
	return "$" .. __htms_value_call(cards[1],"getEffectiveId")
end

sgs.ai_skill_choice.juejian = function(self, choices, data)
	local good, bad = 0, 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) then
			if self:isFriend(player) then bad = bad + 1
			else good = good + 1
			end
		end
	end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(__htms_value_call(player,"getHp"), 1)
		if getCardsNum("Analeptic", player) > 0 then
			if self:isFriend(player) then good = good + 1.0 / hp
			else bad = bad + 1.0 / hp
			end
		end

			local lost_value = 0
			if self:needToLoseHp(player, self.player) then lost_value = __htms_value_call(player,"getHp")/2 end
			local hp = math.max(__htms_value_call(player,"getHp"), 1)
			if self:isFriend(player) then bad = bad + (lost_value + 1) / hp
			else good = good + (lost_value + 1) / hp
			end
	end
	local value_lost = 0
	if good > bad then
		value_lost = good - bad
	end
	local value_dis = 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) then value_dis = value_dis - __htms_value_call(player,"getHandcardNum") + 1
			else  value_dis = value_dis + __htms_value_call(player,"getHandcardNum") - 1
			end
	end
	if value_lost > value_dis then
		return "juejian:ls"
	else
		return "juejian:qz"
	end
end

sgs.ai_skill_cardask["@smsy"] = function(self,data)
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return "." end
	if target:hasArmorEffect("silver_lion") then return "." end
	if self:cantDamageMore(self.player, target) then return "." end


	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		return "#smsy:"..__htms_value_call(card,"getEffectiveId") ..":"
	end
	return "."
end

sgs.ai_ajustdamage_from.smsy = function(self,from,to,card,nature)
	if card and (__htms_value_call(card,"isKindOf","Slash") or __htms_value_call(card,"isKindOf","Duel")) and from:canDiscard(from, "he") and not self:beFriend(to,from)
	then return 1 end
end
sgs.ai_cardneed.smsy = sgs.ai_cardneed.slash

sgs.ai_fill_skill["jiewq"] = function(self,inclusive,request)
	if #self.enemies<=0 then return end
	if self:getAllPeachNum()<=0 then return end
	return policy(self,"#jiewq:.:")
end

sgs.ai_skill_use_func["#jiewq"] = function(card,use,self)
	self:writeCurrentSourceSlot("jiewq_lose",0)
	local slashcount = self:getCardsNum("Slash")-1
	self:writeCurrentSourceSlot("jiewq_lose",math.min(slashcount,__htms_value_call(self.player,"getHp")))
	if self:readCurrentSourceSlot("jiewq_lose")<=0 then return end
	local slash = self:getCard("Slash")
	local dummy_use = dummy_plan()
	if slash then self:useBasicCard(slash,dummy_use) end
	if not dummy_use.card or dummy_use.to:isEmpty() then return end
	use.card = card
end
sgs.ai_use_priority["jiewq"] = sgs.ai_use_priority.TenyearQimouCard

sgs.ai_skill_choice.jiewq = function(self,choices)
	choices = choices:split("+")
	local num = self:readCurrentSourceSlot("jiewq_lose")
	for _,choice in ipairs(choices)do
		if tonumber(choice)==num and self:getAllPeachNum() > 0 then return choice end
	end
	return choices[1]
end
sgs.ai_cardneed.jiewq = sgs.ai_cardneed.slash

sgs.ai_ajustdamage_from.jiewq = function(self,from,to,card,nature)
	if card and (__htms_value_call(card,"isKindOf","Slash"))
	then return __htms_value_call(from,"getMark","jiewq-Clear") end
end

sgs.ai_can_damagehp.saiya = function(self,from,card,to)
	return __htms_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0 and __htms_value_call(to,"getHp")<=1
	and self:canLoseHp(from,card,to)
end



sgs.ai_skill_cardask["@muou"] = function(self, data)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local target
	local min_hp = 999
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if __htms_value_call(player,"getHp") < getBestHp(player) and self:isFriend(player) then
			if __htms_value_call(player,"getHp") < min_hp then
				target = player
				min_hp = __htms_value_call(player,"getHp")
			end
		end
	end
	if not target then
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if __htms_value_call(player,"getHp") < getBestHp(player) and self:isEnemy(player) then
				if getCardsNum("Peach", player, self.player) > 0 then
					for _,card in ipairs(cards) do
						if card:isBlack() then
							return "$" .. __htms_value_call(card,"getEffectiveId")
						end
					end
				end
			end
		end
	end
	if target then
		for _,card in ipairs(cards) do
			if card:isRed() and not __htms_value_call(card,"isKindOf","Peach") then
				set_observation_mark(self,"mozy_red",1)
				return "$" .. __htms_value_call(card,"getEffectiveId")
			end
		end
	end
	return "."
end
sgs.ai_skill_playerchosen["mozy"] = function(self, targets)
	local target
	if observation_mark(self,"mozy_red") > 0 then
		set_observation_mark(self,"mozy_red",0)
		local min_hp = 999
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if __htms_value_call(player,"getHp") < getBestHp(player) and self:isFriend(player) then
				if __htms_value_call(player,"getHp") < min_hp then
					target = player
					min_hp = __htms_value_call(player,"getHp")
				end
			end
		end
		return target
	else
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if __htms_value_call(player,"getHp") < getBestHp(player) and self:isEnemy(player) then
				if getCardsNum("Peach", player) > 0 then
					target = player
				end
			end
		end
		return target
	end
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|mozy"

sgs.ai_skill_invoke.zsmy = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return false end
	if target:hasArmorEffect("silver_lion") then return false end
	if self:cantDamageMore(self.player, target) then return false end
	if self:isWeak(target) and getCardsNum("Peach", target) < 1 and self:damageIsEffective(target, damage.nature, self.player) then
	return true
	end
	return false
end


sgs.ai_fill_skill["qsas"] = function(self,inclusive,request)
	if #self.enemies < 1 then return end
	local source = self.player
	if source:hasUsed("#qsas") then return end
	return policy(self,"#qsas:.:")
end

sgs.ai_skill_use_func["#qsas"] = function(card,use,self)
    self.enemies = self:sort(self.enemies, "defenseSlash")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local targets = {}
	local use_card
	local card = clone(self,"Slash")
	card:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if not self:slashProhibit(card, enemy) and self:isGoodTarget(enemy, self.enemies, card) and self:cardTargetFilter(card,AIList.new({}),enemy) then
			if not self:needToLoseHp(enemy,self.player,card) then table.insert(targets, enemy) end
		end
	end
	for _, card in ipairs(cards) do
		if  __htms_value_call(card,"isKindOf","TrickCard") then
			use_card = card
		end
	end
	if #targets > 0 and use_card then
		use.card = policy(self,"#qsas:"..__htms_value_call(use_card,"getEffectiveId") ..":")
		if use.to then use.to:append(targets[1]) end
		return
	end
end

sgs.ai_use_value["qsas"] = 5
sgs.ai_use_priority["qsas"]  = 7

sgs.ai_ajustdamage_from.nirendao = function(self, from, to, card, nature)
	if card and __htms_value_call(card,"isKindOf","Slash") then
		return 1
	end
end
sgs.ai_fill_skill["nidaoren"] = function(self,inclusive,request)
	if __htms_value_call(self.player,"getMark","@nidaoren") == 0 or __htms_value_call(self.player,"getHp") < 2 then return end
	return policy(self,"#nidaorenCard:.:")
end
sgs.ai_skill_use_func["#nidaorenCard"] = function(card, use, self)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies,"defense")
	local acard = policy(self,"#nidaorenCard:.:") --根据卡牌构成字符串产生实际将使用的卡牌
	assert(acard)
	local defense = 6
	local selfSub = __htms_value_call(self.player,"getHandcardNum") - __htms_value_call(self.player,"getHp")
	local slash = clone(self,"slash")
	slash:deleteLater()
	local best_target, target = nil, nil
	if #self.enemies <= 1 then return "." end
	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefense(enemy)

		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and __htms_value_call(self.player,"distanceTo",enemy) - math.min(__htms_value_call(self.player,"getHp")-1, self:getCardsNum("Slash")) <= 1

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff then
			if __htms_value_call(enemy,"getHp") == 1 and getCardsNum("Jink", enemy) == 0 then best_target = enemy break end
			if def < defense then
				best_target = enemy
				defense = def
			end
			target = enemy
		end
		if selfSub < 0 then return "." end
	end

	if __htms_value_call(self.player,"hasSkill","badaozhai") and __htms_value_call(self.player,"getMark","@badaozhai") > 0 then
		local value = 0
		local players = self.room:getOtherPlayers(self.player)
		for _,p in sgs.qlist(players) do
			if __htms_value_call(p,"getHp") < __htms_value_call(self.player,"getMaxHp") - 1 then
				if self:isFriend(p) then
					value = value - 2
				elseif self:isEnemy(p) then
					value = value + 2
				end
			end
		end
		if viewer_role(self,self.player) == "loyalist" and self:isWeak(self.room:getLord()) and self:getCardsNum("Peach") < 1 then
			return
		end

		if value > 0 then
			use.card=acard
		end
	else
		if best_target then
			if self:getCardsNum("Slash") > 1 and __htms_value_call(self.player,"getHp") > 1 then
				use.card=acard
			end
		end
		if target then
			if self:getCardsNum("Slash") > 1 and __htms_value_call(self.player,"getHp") > 2 then
				use.card=acard
			end
		end
		for _, c in sgs.qlist(self.player:getHandcards()) do
			local x = nil
			if isCard("ArcheryAttack", c, self.player) then
				x = clone(self,"ArcheryAttack")
			elseif isCard("SavageAssault", c, self.player) then
				x = clone(self,"SavageAssault")
			else continue end

			local du = { isDummy = true }
			self:useTrickCard(x, du)
			if (du.card) and __htms_value_call(self.player,"getHp") > 1 then use.card=acard end
		end
	end


end
sgs.ai_skill_choice.nidaorendraw = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		for _, c in sgs.qlist(self.player:getHandcards()) do
			local x = nil
			if isCard("ArcheryAttack", c, self.player) then
				x = clone(self,"ArcheryAttack")
			elseif isCard("SavageAssault", c, self.player) then
				x = clone(self,"SavageAssault")
			else continue end

			local du = { isDummy = true }
			self:useTrickCard(x, du)
			if (du.card) then return tostring(__htms_value_call(self.player,"getHp")-1) end
		end
		return tostring(math.min(__htms_value_call(self.player,"getHp")-1, self:getCardsNum("Slash")))
    end
    return items[1]
end
sgs.ai_use_value["nidaorenCard"] = 2 --卡牌使用价值
sgs.ai_use_priority["nidaorenCard"] = 3 --卡牌使用优先级


sgs.ai_fill_skill["badaozhai"] = function(self,inclusive,request)
	if __htms_value_call(self.player,"getMark","@badaozhai") == 0  then return end
	return policy(self,"#badaozhaiCard:.:")
end
sgs.ai_skill_use_func["#badaozhaiCard"] = function(card, use, self)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies,"defense")
	local acard = policy(self,"#badaozhaiCard:.:") --根据卡牌构成字符串产生实际将使用的卡牌
	assert(acard)
	local value = 0
	local players = self.room:getOtherPlayers(self.player)
		for _,p in sgs.qlist(players) do
			if __htms_value_call(p,"getHp") < __htms_value_call(self.player,"getLostHp") then
				if self:isFriend(p) then
					value = value - 2
				elseif self:isEnemy(p) then
					value = value + 2
				end
			end
		end
		if viewer_role(self,self.player) == "loyalist" and self:isWeak(self.room:getLord()) and self:getCardsNum("Peach") < 1 then
			return
		end

		if __htms_value_call(self.player,"getLostHp") > 0 and value > 0 then use.card=acard end
end
sgs.ai_use_value["badaozhaiCard"] = 2 --卡牌使用价值
sgs.ai_use_priority["badaozhaiCard"] = 2 --卡牌使用优先级


sgs.ai_fill_skill["feils2"] = function(self,inclusive,request)
    if self.player:hasUsed("#feils2") then return nil end

		return policy(self,"#feils2:.:")
end

sgs.ai_skill_use_func["#feils2"] =function(card,use,self)
	self.enemies = self:sort(self.enemies, "defense")
	self.MingceTarget = nil
	local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
				and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
				and enemy:objectName() ~= self.player:objectName() then
			self.MingceTarget = enemy
			break
		end
	end

	if self.MingceTarget then
	use.card = policy(self,"#feils2:.:")
		if use.to then
			use.to:append(self.MingceTarget)
		end
	end
end

sgs.ai_use_value["feils2"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["feils2"] = sgs.ai_use_priority.Slash - 0.2

sgs.double_slash_skill = sgs.double_slash_skill .. "|feils2"

sgs.ai_skill_invoke.jiushu = function(self, data)
	return true
end

sgs.ai_skill_use["@@jiushu"] = function(self, prompt, method, data)
	local first_card, second_card
	local first_found, second_found = false, false
	local use_card = {}
	if __htms_value_call(self.player,"getHandcardNum") >= 2 then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)


		cards = self:sortByKeepValue(cards)
		local useAll = false
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player))
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player))
					if first_card ~= scard and (__htms_value_call(scard,"getSuit") == __htms_value_call(first_card,"getSuit") or __htms_value_call(first_card,"getTypeId") == __htms_value_call(scard,"getTypeId")) then
						if not svalueCard then
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
	local target = self.room:getCurrentDyingPlayer()
	if first_found and second_found and target and self:isFriend(target) then
		table.insert(use_card, __htms_value_call(first_card,"getEffectiveId"))
		table.insert(use_card, __htms_value_call(second_card,"getEffectiveId"))
		return "#jiushu:".. table.concat(use_card, "+") ..":"
	end

	return "."
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|jiushu"
sgs.save_skill = sgs.save_skill .. "|jiushu"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|jiushu"

sgs.ai_skill_invoke.xieheng = function(self, data)
	return true
end

sgs.ai_skill_playerchosen["xieheng"] = function(self, targets)
	local target
	local cards = self.player:getCards("he")
	local have_red = false
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if fcard:isRed() and not __htms_value_call(fcard,"isKindOf","Peach") then
				have_red = true
			end
		end
		if have_red then
			cards = self:sortByKeepValue(cards)
			local min_hp = 999
			for _, player in sgs.qlist(self.room:getAlivePlayers()) do
				if __htms_value_call(player,"getHp") < getBestHp(player) and self:isFriend(player) then
					if __htms_value_call(player,"getHp") < min_hp then
						target = player
						min_hp = __htms_value_call(player,"getHp")
					end
				end
			end
			return target
		else
		return self:findPlayerToDraw(true, 1)
		end
	return self:findPlayerToDraw(true, 1)
end

sgs.ai_playerchosen_intention.xieheng = -40
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|xieheng"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|xieheng"

sgs.ai_skill_cardask["@xieheng"] = function(self, data)
	local target = data:toPlayer()
	local cards = self.player:getCards("he")
	if target and self:isFriend(target) and __htms_value_call(target,"getHp") < getBestHp(target) then
		cards = sgs.QList2Table(cards)
		for _,card in ipairs(cards) do
				if card:isRed() and not __htms_value_call(card,"isKindOf","Peach") then
					return "$" .. __htms_value_call(card,"getEffectiveId")
				end
			end

	end
	return "."
end

sgs.ai_skill_invoke.tjdzf = function(self, data)
	local damage = data:toDamage()
	if damage.from and damage.nature ~= sgs.DamageStruct_Normal and self:isFriend(damage.from) and self.player:isChained() and self:isGoodChainTarget(self.player, damage.card, damage.from, damage.damage) then return false end

	if self:needToLoseHp(damage.to,damage.from,damage.card) then return false end
	return true
end

sgs.ai_skill_invoke.qrdag = function(self, data)
	return true
end
sgs.ai_skill_choice["qrdag"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if self.player:getPile("qrdag_yin"):length() < __htms_value_call(self.player,"getHp") and __htms_value_call(self.player,"getHp") > 3  then
			return "qrdag_recover"
		end
    end
    return "qrdag_discard"
end

sgs.ai_cardneed.qrdag = sgs.ai_cardneed.slash

sgs.ai_skill_invoke.fenmao = function(self, data)
	return true
end

sgs.ai_skill_cardask["@fenmao-qp"] = function(self, data)
	local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		cards = self:sortByUseValue(cards)
		for _,card in ipairs(cards) do
				if not __htms_value_call(card,"isKindOf","Peach") then
					return "$" .. __htms_value_call(card,"getEffectiveId")
				end
			end
	return "."
end

sgs.ai_fill_skill["changgui"] = function(self,inclusive,request)
	if self.player:hasUsed("#changgui")then return false end
	local card_str = ("#changgui:%d:")
	return policy(self,card_str)
end

sgs.ai_skill_use_func["#changgui"] = function(card, use, self)
	use.card = card
end
sgs.ai_use_priority["changgui"] = 9.4
sgs.ai_use_value["changgui"] = 4.4
sgs.ai_fill_skill["heihua"] = function(self,inclusive,request)
	if self.player:hasUsed("#heihua") then return false end
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h", true) then
			return policy(self,"#heihua:.:")
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if (not enemy:isKongcheng()) then
			return policy(self,"#heihua:.:")
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "h", true) then
			return policy(self,"#heihua:.:")
		end
	end
end
sgs.ai_skill_use_func["#heihua"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h", true) then
			use.card = policy(self,"#heihua:.:")
			if use.to then use.to:append(enemy) end
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if (not enemy:isKongcheng()) then
			use.card = policy(self,"#heihua:.:")
			if use.to then use.to:append(enemy) end
			return
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "h", true) then
			use.card = policy(self,"#heihua:.:")
			if use.to then use.to:append(friend) end
			return
		end
	end
end
sgs.ai_use_value["heihua"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["heihua"] = sgs.ai_use_priority.Slash + 1


sgs.ai_skill_use["@@maware"] = function(self, data, method)
	if not method then method = sgs.Card_MethodUse end
	 local pattern = property(self,"maware_use"):split("+")
	local cards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, visible(self,id))
		end
	end
	cards = self:sortByKeepValue(cards)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "defense")

	local willuse_card = {}
	local class_name = pattern[2]
	local value = 0
	for _,c in ipairs(cards) do
	if __htms_value_call(c,"isKindOf","Peach")
	or (__htms_value_call(c,"isKindOf","Jink") and self:getCardsNum("Jink") == 1)
	or (__htms_value_call(c,"isKindOf","Analeptic") and self:getCardsNum("Analeptic") == 1 and __htms_value_call(self.player,"getHp") <= 1)
	then
		else
		if #willuse_card < tonumber(pattern[1]) then
			table.insert(willuse_card, __htms_value_call(c,"getEffectiveId"))
			value = value + self:getKeepValue(c)
			else
				break
		end
	end
	end
	if string.find(class_name, "analeptic") and __htms_value_call(self.player,"getHandcardNum") < 2 then return "." end
	if string.find(class_name, "peach") and not __htms_value_call(self.player,"isWounded") then return "." end
	if #willuse_card < tonumber(pattern[1]) then return "." end
	local card_str = ("%s:samsara[%s:%s]=."):format(class_name, sgs.Card_NoSuit, -1)
	local use_card = policy(self,card_str)
	local card = clone(self,class_name, sgs.Card_NoSuit, -1)
	card:deleteLater()
	use_card = mutate(self,use_card,"skill","samsara")
	for i = 1, #willuse_card, 1 do
		use_card = mutate(self,use_card,"add",willuse_card[i])
	end
	if value > self:getUseValue(use_card) and tonumber(pattern[1]) > 2 then return "." end

	if use_card:targetFixed() then
		if __htms_value_call(use_card,"isKindOf","SavageAssault") then
			local savage_assault = clone(self,"SavageAssault")
			savage_assault:deleteLater()
			if self:getAoeValue(savage_assault) <= 0 then
				return "."
			end
		end
		if __htms_value_call(use_card,"isKindOf","ArcheryAttack") then
			local archery_attack = clone(self,"ArcheryAttack")
			archery_attack:deleteLater()
			if self:getAoeValue(archery_attack) <= 0 then
				return "."
			end
		end
		if not __htms_value_call(use_card,"isKindOf","Analeptic") and not __htms_value_call(use_card,"isKindOf","Nullification") then
			return use_card:getLegacyStringKey()
		end
	else
		if string.find(class_name, "slash") then
			local dummy_use = self:aiUseCard(use_card, dummy_plan())
			local targets = {}
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					if self:getDefenseSlash(p) < 6 then
						table.insert(targets, p:objectName())
					end
				end
				if #targets > 0 then
					return use_card:getLegacyStringKey() .. "->" .. table.concat(targets, "+")
				end
			end
		end
		if use_card:isNDTrick() then
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
		end
	end
	return "."
end

sgs.ai_skill_choice["samsara"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if items[1] ~= "cancel"  then
			return  items[1]
		end
    end
    return "cancel"
end


sgs.ai_skill_use["@@kuixin"] = function(self, prompt, method, data)
	local target
	self.enemies = self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if __htms_value_call(self.player,"getHandcardNum") <= __htms_value_call(enemy,"getHandcardNum") then
			target = enemy
			break
		end
	end
	if target then
		return "#kuixin:.:->"..target:objectName()
	end
	if __htms_value_call(self.player,"getHandcardNum") > 3 then
		return "#kuixin:.:->"..target:objectName()
	end
	return "#kuixin:.:"
end



sgs.ai_skill_invoke.slash_defence = function(self, data)
	local damage = data:toDamage()
	local duel = clone(self,"duel", sgs.Card_NoSuit, 0)
	duel:deleteLater()
	duel = mutate(self,duel,"skill","zhanxianfanyu")
	if damage.to and self:isFriend(damage.to) and  self:needToLoseHp(damage.to, damage.from, damage.card) then
		return false
	end
	if damage.from and self:isFriend(damage.from) and not  self:needToLoseHp(damage.from, self.player, duel) then
		return false
	end
	return true
end
sgs.ai_skill_invoke.zhanxianfanyu = function(self, data)
	local change = data:toPhaseChange()
	self.friends = self:sort(self.friends, "defenseSlash")
	if change.to == sgs.Player_Draw and self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) < 4 then
		for _,friend in ipairs(self.friends) do
			if self:isWeak(friend) then
				return true
			end
		end
		return false
	end
	if change.to == sgs.Player_Play and self:getOverflow() < 3 then
		for _,friend in ipairs(self.friends) do
			if self:isWeak(friend) then
				return true
			end
		end
		return false
	end
	return false
end
sgs.ai_skill_playerchosen.zhanxianfanyu = function(self, targets)
	local target
	self.friends = self:sort(self.friends, "defenseSlash")
	for _,friend in ipairs(self.friends) do
        if self:isWeak(friend) and  __htms_value_call(friend,"getMark","@zhanxianfanyu") == 0 then
            return friend
        end
    end
	return self.player
end
sgs.ai_playerchosen_intention.zhanxianfanyu = -40


sgs.ai_skill_invoke.jixieshen = function(self, data)
	if self.player:getGeneralName() == "siluokayi" or self.player:getGeneral2Name() == "siluokayi" then
		return true
	end
	if self.player:getGeneralName() == "gaowen" or self.player:getGeneral2Name() == "gaowen" then
		if self:isWeak() then
			return true
		end
		if self:getCardsNum("Slash") > 0 then
			return true
		end
		if self:getCardsNum("Slash") > 0 or self:getCardsNum("Jink") > 0 then
			return true
		end
		return false
	end
	if self.player:getGeneralName() == "gemingji" or self.player:getGeneral2Name() == "gemingji" then
		if self:isWeak() then
			return true
		end
		if self:getCardsNum("Slash") > 0 then
			return false
		end
		if self:getCardsNum("Slash") == 0 or self:getCardsNum("Jink") == 0 then
			return true
		end
		return false
	end
	if self.player:getGeneralName() == "fuxiao" or self.player:getGeneral2Name() == "fuxiao" then
		if self:isWeak() then
			return false
		end
		if self:getCardsNum("Slash") > 0 then
			return true
		end
		if self:getCardsNum("Slash") == 0 or self:getCardsNum("Jink") == 0 then
			return true
		end
		return false
	end
	return false
end

sgs.ai_skill_choice["jixieshen"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if self:isWeak() and table.contains(items, "fuxiao") then
			return "fuxiao"
		end
		if self:getCardsNum("Slash") > 0 and table.contains(items, "gemingji")  then
			return "gemingji"
		end
		if (self:getCardsNum("Slash") == 0 or self:getCardsNum("Jink") == 0) and table.contains(items, "gaowen") then
			return "gaowen"
		end
    end
    return "siluokayi"
end

sgs.ai_skill_playerchosen.jixieshen = function(self, targets)
	local target = self:findPlayerToDamage(1, self.player, "N", targets)[1]
	return target
end

sgs.ai_skill_invoke["jixieshen:fixmachine"] = function(self, data)
    return true
end

sgs.ai_skill_choice["jixieshenfixmachine"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if __htms_value_call(self,"getMark","@fuxiao") <= 1 and table.contains(items, "fuxiao") then
			return "fuxiao"
		end
		if __htms_value_call(self,"getMark","@gemingji") <= 1 and table.contains(items, "gemingji")  then
			return "gemingji"
		end
		if __htms_value_call(self,"getMark","@gaowen") <= 1 and table.contains(items, "gaowen") then
			return "gaowen"
		end
    end
    return items[1]
end


sgs.ai_fill_skill["jixieshenchain"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, visible(self,id))
		end
	end

	local jink_card

	cards = self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:isRed() then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = __htms_value_call(jink_card,"getSuitString")
	local number = jink_card:getNumberString()
	local card_id = __htms_value_call(jink_card,"getEffectiveId")
	local card_str = ("slash:jixieshenchain[%s:%s]=%d"):format(suit, number, card_id)
	local slash = policy(self,card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.jixieshenchain = function(card, player, card_place)
	local suit = __htms_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __htms_value_call(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		if card:isRed() then
			return ("slash:jixieshenchain[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isBlack() then
			return ("jink:jixieshenchain[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_ajustdamage_to.jixieshendefense = function(self, from, to, card, nature)
	if nature~= "N"
	then
		return -99
	end
end


sgs.ai_skill_invoke.jixieshenslash = function(self, data)
	local use = data:toCardUse()
	if self:hasHeavyDamage(self.player) then return false end
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			if getCardsNum("Jink", p, self.player) > 0 and not self:needToLoseHp(p) and self:damageIsEffective(p, sgs.DamageStruct_Fire) then
				return false
			end
		else
			if not self:damageIsEffective(p, sgs.DamageStruct_Fire) then
				return false
			end
		end
	end
	return true
end
sgs.ai_cardneed.jixieshenslash = sgs.ai_cardneed.slash

sgs.ai_skill_playerchosen.loyal_inu = function(self, targets)
	if viewer_role(self,self.player) == "loyalist" then
		return self.room:getLord()
	end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if viewer_role(self,self.player) == "lord" and viewer_role(self,p) == "loyalist" then
			return p
		end
	end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if viewer_role(self,self.player) == viewer_role(self,p) then
			return p
		end
	end
	local player = self:AssistTarget()
	if player then
		return player
	end
	return nil
end
sgs.ai_playerchosen_intention.loyal_inu = -80

sgs.ai_skill_choice["kikann"] = function(self, choices, data)
	local items = choices:split("+")
		local target = self.room:findPlayerBySkillName("loyal_inu")
		if target then
			if __htms_value_call(target,"getHandcardNum") > __htms_value_call(self.player,"getHandcardNum") and table.contains(items, "kikann_2") then
				return "kikann_2"
			end
			if __htms_value_call(target,"getHp") > __htms_value_call(self.player,"getHp") and table.contains(items, "kikann_1") then
				return "kikann_1"
			end
		end
    return "cancel"
end

sgs.ai_skill_choice.jueduiyazhi = function(self, choices)
	local items = choices:split("+")
	if __htms_value_call(self.player,"getMark","@lanyu") > 4 and table.contains(items, "jueduiyazhi_loseMark") then return "jueduiyazhi_loseMark" end
	if __htms_value_call(self.player,"getHp") + self:getCardsNum("Peach") > 3 then return "jueduiyazhi_losehp"
	else if table.contains(items, "jueduiyazhi_loseMark") then return "jueduiyazhi_loseMark" end
	end
	return "jueduiyazhi_losehp"
end

sgs.ai_fill_skill["jueduiyazhi"] = function(self,inclusive,request)
	return policy(self,"#jueduiyazhiCard:.:")
end

sgs.ai_skill_use_func["#jueduiyazhiCard"] = function(card,use,self)
	local slashes = self:getCards("Slash")
	if #slashes<1 then return end
	self.enemies = self:sort(self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		for _,slash in sgs.list(slashes)do
			local d = self:aiUseCard(slash)
			if d.card and d.to:contains(enemy) then
				use.card = card
				use.to:append(enemy)
				return

			end
		end
	end
end

sgs.ai_use_priority["jueduiyazhiCard"] = sgs.ai_use_priority.Slash+0.5
sgs.ai_use_value["jueduiyazhiCard"] = 3



sgs.double_slash_skill = sgs.double_slash_skill .. "|lanyuhua"
sgs.ai_cardneed.lanyuhua = sgs.ai_cardneed.slash

sgs.ai_fill_skill["guangzijupao"] = function(self,inclusive,request)
	if  self.player:getCards("he"):length() < 1 then return nil end
    if self.player:hasUsed("#guangzijupaoCard") then return nil end
	local card
		if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		hcards = self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
				card = hcard
				break
		end
	end
		if card then
		return policy(self,"#guangzijupaoCard:.:")
		end
end

sgs.ai_skill_use_func["#guangzijupaoCard"] =function(card,use,self)
	self.enemies = self:sort(self.enemies, "defense")
	local target = nil
	local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
						and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and not enemy:isNude()
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
				card = hcard
				break
		end
	end
    if card then
	if target then
	use.card = policy(self,"#guangzijupaoCard:"..card:getId()..":")
		if use.to then
			use.to:append(target)
		end
	end
	end
end

sgs.ai_use_value["guangzijupaoCard"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["guangzijupaoCard"] = sgs.ai_use_priority.Slash - 0.2
sgs.double_slash_skill = sgs.double_slash_skill .. "|guangzijupao"





sgs.ai_skill_invoke.Luayanhu = function(self, data)
	local damage = data:toDamage()
	if damage.to and self:isFriend(damage.to) and self:damageIsEffective(damage.to, damage.nature, damage.from) then
		if self:isWeak(damage.to) or (not self:needToLoseHp(damage.to, damage.from, damage.card))  then
			return not self:isWeak()
		end
	end
	return false
end

sgs.ai_skill_invoke.xinsuo = function(self, data)
	local target = self.room:getCurrent()
	if  sgs.ai_role[target:objectName()] ~= "neutral" or __htms_value_call(target,"isLord")  then
			return true
	end
	return false
end

sgs.ai_skill_choice["xinsuo"] = function(self, choices, data)
	local target = self.room:getCurrent()
	local items = choices:split("+")

	if sgs.ai_role[target:objectName()]== "rebel" and table.contains(items, "rebel")  then
		return "rebel"
	elseif __htms_value_call(target,"isLord") and table.contains(items, "lord")  then
		return "lord"
	elseif sgs.ai_role[target:objectName()]== "loyalist" and table.contains(items, "loyalist")  then
		return "loyalist"
	elseif sgs.ai_role[target:objectName()]== "renegade" and table.contains(items, "renegade")  then
		return "renegade"
	end
	return items[1]
end

sgs.ai_skill_cardask["@fengfu-discard"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) and not self:findLeijiTarget(target, 50, self.player) then return "." end
	local  has_black
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isBlack() then has_black = card
		end
	end

	if has_black then return "$" .. __htms_value_call(has_black,"getEffectiveId")
	else return "."
	end
end


sgs.ai_fill_skill["yohane"] = function(self,inclusive,request)
	if self.player:hasUsed("#yohane") then return end
	local t=0
	for _,p in ipairs(self.friends_noself) do
	    if __htms_value_call(p,"getHandcardNum")>0 and foreign_property(self,p,"xinsuo_set") ~= "" then t=t+1 end
	end
	for _,q in ipairs(self.enemies) do
	    if __htms_value_call(q,"getHandcardNum")>0 and foreign_property(self,q,"xinsuo_set") ~= "" then t=t+1 end
	end
	if t>1 then
	    return policy(self,"#yohane:.:")
	end
end

sgs.ai_skill_use_func["#yohane"]=function(card,use,self)
    use.card=card
	if #self.friends_noself>=1 then
	    local friends={}
		self.friends_noself = self:sort(self.friends_noself, "handcard")
		self.friends_noself = sgs.reverse(self.friends_noself)
	    for _,friend in ipairs(self.friends_noself) do
		    if not friend:isAllNude() and foreign_property(self,friend,"xinsuo_set") ~= "" then
		        table.insert(friends, friend)
			end
	    end
        if #friends>0 then
	        self.enemies = self:sort(self.enemies,"defense")
		    for _,enemy in ipairs(self.enemies) do
			    if not enemy:isAllNude() and  foreign_property(self,enemy,"xinsuo_set") ~= "" and foreign_property(self,enemy,"xinsuo_set") ~=   foreign_property(self,friends[1],"xinsuo_set")  then
				    if use.to then
					    use.to:append(enemy)
					    use.to:append(friends[1])
					    return
					end
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_cardask["#yohane-distribute"] = function(self, data)
	local targetslist = data:toString():split("+")
	local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	for _, p in ipairs(players) do
		if self:isEnemy(p)	and table.contains(targetslist, p:objectName())  then
			local handcard = self.player:getHandcards()
			handcard = sgs.QList2Table(handcard)
			handcard = self:sortByUseValue(handcard, true)
			for _, card in ipairs(handcard) do
				if __htms_value_call(card,"isKindOf","DelayedTrick")  then
					self:yohaneRoomTag("ai_yohane_card_id","write",__htms_value_call(card,"getEffectiveId"))
					return "$" .. __htms_value_call(card,"getEffectiveId")
				end
			end

			for _, card in ipairs(handcard) do
				self:yohaneRoomTag("ai_yohane_card_id","write",__htms_value_call(card,"getEffectiveId"))
				return "$" .. __htms_value_call(card,"getEffectiveId")
			end
		end
		if self:isFriend(p)	and table.contains(targetslist, p:objectName())  then
			local handcard = self.player:getHandcards()
			handcard = sgs.QList2Table(handcard)
			handcard = self:sortByUseValue(handcard)
			for _, card in ipairs(handcard) do
				self:yohaneRoomTag("ai_yohane_card_id","write",__htms_value_call(card,"getEffectiveId"))
				return "$" .. __htms_value_call(card,"getEffectiveId")
			end
		end
	end
	local handcard = self.player:getHandcards()
			handcard = sgs.QList2Table(handcard)
			handcard = self:sortByUseValue(handcard, true)
	return "$" .. __htms_value_call(handcard[1],"getEffectiveId")
end

sgs.ai_skill_playerchosen.yohane = function(self, targets)
	local ai_yohane_card_id = self:yohaneRoomTag("ai_yohane_card_id","take")
	local card = visible(self,ai_yohane_card_id)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "defense")
	local to_player = local_data()
	for _, target in ipairs(targets) do
		if __htms_value_call(card,"isKindOf","DelayedTrick") then
			if self:isEnemy(target) and  (not self.player:isProhibited(target, card) and not target:containsTrick(card:objectName()) ) then
				to_player = target:objectName()
				self:yohaneRoomTag("ai_yohane_player","write",to_player)
				return target
			end
			if self:isFriend(target) then
				to_player = target:objectName()
				self:yohaneRoomTag("ai_yohane_player","write",to_player)
				return target
			end
		end
		if __htms_value_call(card,"isKindOf","EquipCard") then
			if self:isFriend(target) then
				to_player = target:objectName()
				self:yohaneRoomTag("ai_yohane_player","write",to_player)
				return target
			end
		end
		local handcard = self.player:getHandcards()
			handcard = sgs.QList2Table(handcard)
			handcard = self:sortByUseValue(handcard)
		if __htms_value_call(card,"getEffectiveId") == __htms_value_call(handcard[1],"getEffectiveId") then
			if self:isFriend(target) then
				to_player = target:objectName()
				self:yohaneRoomTag("ai_yohane_player","write",to_player)
				return target
			end
		end
		local handcard = self.player:getHandcards()
			handcard = sgs.QList2Table(handcard)
			handcard = self:sortByUseValue(handcard, true)
			if __htms_value_call(card,"getEffectiveId") == __htms_value_call(handcard[1],"getEffectiveId") then
			if self:isEnemy(target) then
				to_player = target:objectName()
				self:yohaneRoomTag("ai_yohane_player","write",to_player)
				return target
			end
		end
	end
	return targets[1]
end


sgs.ai_skill_choice.yohane = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		local target = self:yohaneRoomTag("ai_yohane_player","take")
		if table.contains(items, "pe") and target and self:isFriend(target) then
			return "pe"
		end
		if table.contains(items, "pj") and target and self:isEnemy(target) then
			return "pj"
		end
    end
    return "ph"
end





sgs.ai_skill_choice.fanyi = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if self:needBear() then
			if table.contains(items, "5draw_ad")  then
				return "5draw_ad"
			end
			if table.contains(items, "2maxcard_ad")  then
				return "2maxcard_ad"
			end
			if table.contains(items, "3available_re")  then
				return "3available_re"
			end
			if table.contains(items, "1range_re")  then
				return "1range_re"
			end
		end
	if __htms_value_call(self.player,"getAttackRange") >= 3 then
		if table.contains(items, "1range_re")  then
			return "1range_re"
		end
	else
		if table.contains(items, "1range_ad") and self.player:getSlashCount() > 0 then
			return "1range_ad"
		end
	end

	if self.player:getSlashCount() > 0 then
		if table.contains(items, "4target_ad") and #self.enemies > 1 then
			return "4target_ad"
		end
		if table.contains(items, "3available_ad")  then
			return "3available_ad"
		end
	else
		if table.contains(items, "3available_re")  then
			return "3available_re"
		end
	end

	if table.contains(items, "5draw_ad")  then
				return "5draw_ad"
	end
	if table.contains(items, "done")  then
				return "done"
	end
	if table.contains(items, "2maxcard_re") and self:getOverflow() == 0  then
				return "2maxcard_re"
	end
  end
    return items[1]
end


sgs.ai_skill_invoke.jihang = function(self, data)

	return true
end


sgs.ai_skill_playerchosen.jihang = function(self, targets)

	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target)  then return target end
	end

	return targets[1]
end

sgs.ai_skill_playerchosen.anni = function(self, targets)
	local use = room_tag(self,"CurrentUseStruct","CardUse")
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "defense")
	if not use.to:contains(self.player) then
		return self.player
	end

	for _, target in ipairs(targets) do
		if self:isFriend(target)  then return target end
	end

	return targets[1]
end

sgs.ai_skill_choice.anni = function(self, choices)

	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		local use = room_tag(self,"CurrentUseStruct","CardUse")
		for _, t in sgs.qlist(use.to) do
			if table.contains(items, "anni_hit") and (getCardsNum("Jink", t) == 0 or self:canLiegong(t, use.from) )  then
						return "anni_hit"
			end
		end
			if table.contains(items, "anni_miss")  then
						return "anni_miss"
			end
  end
    return items[1]
end

sgs.ai_choicemade_filter.cardChosen.anni = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_choice.jiaoxing = function(self, choices)
	local target = self.room:getCurrent()
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if target then
			if self:isFriend(target) then
				if target:isSkipped(sgs.Player_Play) and table.contains(items, "indulgence")  then
					return "indulgence"
				end
				if target:isSkipped(sgs.Player_Draw) and table.contains(items, "supply_shortage")  then
					return "supply_shortage"
				end
				if __htms_value_call(target,"getHandcardNum") < 3  and table.contains(items, "indulgence")  then
					return "indulgence"
				elseif __htms_value_call(target,"getHandcardNum") >= 3  and table.contains(items, "supply_shortage")  then
					return "supply_shortage"
				end
			elseif self:isEnemy(target) then
				if target:isSkipped(sgs.Player_Play) and table.contains(items, "supply_shortage")  then
					return "supply_shortage"
				end
				if target:isSkipped(sgs.Player_Draw) and table.contains(items, "indulgence")  then
					return "indulgence"
				end
				if __htms_value_call(target,"getHandcardNum") < 3  and table.contains(items, "supply_shortage")  then
					return "supply_shortage"
				elseif __htms_value_call(target,"getHandcardNum") >= 3  and table.contains(items, "indulgence")  then
					return "indulgence"
				end
			end
		end

  end
    return "cancel"
end

sgs.ai_skill_use["@@jiaoxing"] = function(self, prompt, method)
	self:updatePlayers()

	local jiaoxing = property(self,"jiaoxing"):split("+")
	for _, id in sgs.list(jiaoxing) do
		local rcard = visible(self,tonumber(id))

		local indulgence = clone(self,"Indulgence")
		indulgence = mutate(self,indulgence,"add",rcard)
		indulgence = mutate(self,indulgence,"skill","jiaoxing")
		if not self.player:isLocked(indulgence) then

			local dummy_use = { isDummy = true, to = AIList.new({}) }
			self:useCardIndulgence(indulgence, dummy_use)
			if dummy_use.card and dummy_use.to:length() > 0 then
				return ("indulgence:jiaoxing[%s:%s]=%s->%s"):format(__htms_value_call(rcard,"getSuitString"),rcard:getNumberString(),rcard:getId(),dummy_use.to:first():objectName())
			end
		end
	end
	return "."
end




sgs.ai_skill_choice.sandun = function(self, choices)
	local items = choices:split("+")


	for _,enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = clone(self,"slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif def < 6 and eff then return "use_slash"
		end
	end
    return "use_blackequip_discard"
end

sgs.ai_skill_playerchosen.sandun = sgs.ai_skill_playerchosen.zero_card_as_slash


sgs.need_equip_skill = sgs.need_equip_skill .. "|sandun"
sgs.ai_cardneed.sandun = sgs.ai_cardneed.equip

sgs.ai_fill_skill["xieyan"] = function(self,inclusive,request)
	self:updatePlayers()
	if self.player:isNude() then return end

	local handcards = sgs.QList2Table(self.player:getCards("h"))
	for _,c in ipairs(handcards) do
		if __htms_value_call(c,"isAvailable",self.player) and not __htms_value_call(c,"isKindOf","EquipCard") then
			return policy(self,"#xieyancard:.:")
		end
	end


end

sgs.ai_skill_use_func["#xieyancard"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	handcards = self:sortByUseValue(handcards, true)
	local useable_cards = {}
	for _,c in ipairs(handcards) do
		if  not __htms_value_call(c,"isKindOf","Analeptic")
		and not __htms_value_call(c,"isKindOf","Jink")
		and not __htms_value_call(c,"isKindOf","Nullification")
		and not __htms_value_call(c,"isKindOf","EquipCard")
		then
			table.insert(useable_cards, c)
		end
	end
	if #useable_cards == 0 then return end
	local card_str
	for _,c in ipairs(useable_cards) do
		if __htms_value_call(c,"getTypeId") == sgs.Card_TypeTrick and not __htms_value_call(c,"isKindOf","Nullification") and __htms_value_call(c,"isAvailable",self.player)  then
			local dummy_use = self:aiUseCard(c, dummy_plan())
			if dummy_use.card then
				card_str = string.format("#xieyancard:%s:", __htms_value_call(c,"getEffectiveId"))
				local acard = policy(self,card_str)
				use.card = acard
				if not dummy_use.to:isEmpty() then
					for _, p in sgs.qlist(dummy_use.to) do
						if use.to then
						use.to:append(p)
						end
					end
					break
				end

			end
		elseif __htms_value_call(c,"getTypeId") == sgs.Card_TypeBasic and __htms_value_call(c,"isAvailable",self.player) then
			local dummy_use = self:aiUseCard(c, dummy_plan())
			if dummy_use.card then
				card_str = string.format("#xieyancard:%s:", __htms_value_call(c,"getEffectiveId"))
				local acard = policy(self,card_str)
				use.card = acard
				if not dummy_use.to:isEmpty() then
					for _, p in sgs.qlist(dummy_use.to) do
						if use.to then
						use.to:append(p)
						end
					end
					break
				end
			end
		end
	end
	return nil
end
sgs.ai_use_value.xieyancard = 8.5
sgs.ai_use_priority.xieyancard = 6.6


sgs.ai_skill_invoke.sugong = function(self, data)

	return true
end
sgs.ai_skill_choice.sugong = function(self, choices)
	local items = choices:split("+")
    if self:getCardsNum("Peach") > 1 or self:needToLoseHp(self.player, nil, nil, true) then
		return "sugong:lius"
	end


    return "sugong:huix"
end

sgs.ai_skill_invoke.fuzou = function(self, data)
	local use = data:toCardUse()
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) and __htms_value_call(p,"getHandcardNum") >= 2 and __htms_value_call(p,"getPhase") == sgs.Player_NotActive then
			return true
		end
	end
	return false
end


sgs.ai_skill_playerchosen.fuzou = function(self, targets)

	targets = sgs.QList2Table(targets)

	for _, target in ipairs(targets) do
		if self:isFriend(target) and __htms_value_call(target,"getHandcardNum") >= 2 and __htms_value_call(target,"getPhase") == sgs.Player_NotActive then return target end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and __htms_value_call(target,"getPhase") == sgs.Player_NotActive  then return target end
	end
	return targets[1]
end

function NextSuit(x)
	if (x == 0) then
		return 2
	elseif (x == 1) then
		return 3
	elseif (x == 2) then
		return 1
	elseif (x == 3) then
		return 0
	else
		return -1
	end
end
sgs.ai_card_priority.haiyin = function(self,card,v)
	if self.player:getPile("yun"):length() > 0 and NextSuit(visible(self,self.player:getPile("yun"):first()):getSuit())==__htms_value_call(card,"getSuit")
	then return 10 end
end


sgs.ai_skill_invoke.tianqu = function(self, data)
	if self:isWeak() then
		if self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player, true) > __htms_value_call(self.player,"getHp") and self:getCardsNum("Peach") > 0 then
			return false
		end
	end
	return true
end
sgs.ai_skill_playerchosen.tianqu_from = function(self, targets)

	self.enemies = self:sort(self.enemies,"handcard")
	local friends = {}
	for _, player in ipairs(self.friends_noself) do
		if not hasManjuanEffect(player) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return targets[1] end

	friends = self:sort(friends, "defense")
	local function cmp_HandcardNum(a, b)
		local x = __htms_value_call(a,"getHandcardNum") - self:getLeastHandcardNum(a)
		local y = __htms_value_call(b,"getHandcardNum") - self:getLeastHandcardNum(b)
		return x < y
	end
	table.sort(friends, cmp_HandcardNum)

	self.enemies = self:sort(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if hasManjuanEffect(enemy) then
			local e_hand = __htms_value_call(enemy,"getHandcardNum")
			for _, friend in ipairs(friends) do
				local f_peach, f_hand = getCardsNum("Peach", friend), __htms_value_call(friend,"getHandcardNum")
				if (e_hand > f_hand - 1) and (f_hand > 0 or e_hand > 0) and f_peach <= 2 then
					return friend
				end
			end
		end
	end

	return targets[1]
end

sgs.ai_skill_playerchosen.tianqu_to = function(self, targets)

	self.enemies = self:sort(self.enemies,"handcard")
	local friends = {}
	for _, player in ipairs(self.friends_noself) do
		if not hasManjuanEffect(player) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return targets[1] end

	friends = self:sort(friends, "defense")
	local function cmp_HandcardNum(a, b)
		local x = __htms_value_call(a,"getHandcardNum") - self:getLeastHandcardNum(a)
		local y = __htms_value_call(b,"getHandcardNum") - self:getLeastHandcardNum(b)
		return x < y
	end
	table.sort(friends, cmp_HandcardNum)

	self.enemies = self:sort(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if hasManjuanEffect(enemy) then
			local e_hand = __htms_value_call(enemy,"getHandcardNum")
			for _, friend in ipairs(friends) do
				local f_peach, f_hand = getCardsNum("Peach", friend), __htms_value_call(friend,"getHandcardNum")
				if (e_hand > f_hand - 1) and (f_hand > 0 or e_hand > 0) and f_peach <= 2 then
					return enemy
				end
			end
		end
	end

	return targets[1]
end

sgs.ai_can_damagehp.tianqu = function(self,from,card,to)
	return __htms_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and card and __htms_value_call(card,"isKindOf","Slash") and not __htms_value_call(card,"isKindOf","NatureSlash") and sgs.ai_skill_invoke.tianqu(self, local_data())
end

sgs.ai_skill_invoke.htms_wanlan = function(self, data)
	if #self.enemies > 0 then
		for _, enemy in ipairs(self.enemies) do
			if  not enemy:isKongcheng() and self:objectiveLevel(enemy) > 3 and
			not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and self:canDamage(enemy,self.player,nil)  then
			return self:doDisCard(enemy, "he")
			end
		end
	end
	return false
end
sgs.ai_skill_playerchosen.htms_wanlan = function(self, targets)

	targets = sgs.QList2Table(targets)

	for _, target in ipairs(targets) do
		if self:isEnemy(target) and not target:isKongcheng() and self:objectiveLevel(target) > 3 and
			not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and not self:doDisCard(target, "he") and self:canDamage(target,self.player,nil) then
			return target
		end
	end

	return targets[1]
end
sgs.ai_skill_discard["htms_wanlan"] = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByCardNeed(cards)
	local to_discard = {}
	for _, card in ipairs(cards) do
		if not __htms_value_call(card,"isKindOf","Peach") and __htms_value_call(card,"getNumber") > 8 then
			if #to_discard >= 2 then break end
				table.insert(to_discard, __htms_value_call(card,"getEffectiveId"))
			end
		end


	return to_discard
end



sgs.ai_skill_choice.htms_wanlan = function(self, choices)
    return "draw_one_card"
end



sgs.ai_skill_playerchosen["huanggui"] = function(self, targets)
	local targets = sgs.QList2Table(targets)
	local use = room_tag(self,"huanggui","CardUse")
	local card = use.card
	local target
	if __htms_value_call(card,"isKindOf","AmazingGrace") or __htms_value_call(card,"isKindOf","ExNihilo") or __htms_value_call(card,"isKindOf","EXCard_YJJG") then
		for _, friend in ipairs(self.friends) do
			if friend:hasSkills(sgs.cardneed_skill) and not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and self:hasTrickEffective(card, use.from, friend)
			and __htms_value_call(self.player,"getHandcardNum") > 	__htms_value_call(friend,"getHandcardNum")	and table.contains(targets, friend)	then
				return friend
			end
		end
		return nil
	elseif  __htms_value_call(card,"isKindOf","EXCard_TJBZ") then
		return nil
	elseif __htms_value_call(card,"isKindOf","EXCard_YYDL")  then
		for _, friend in ipairs(self.friends) do
			if (self:hasSkills(sgs.lose_equip_skill, friend) or self:needToThrowArmor(friend)) and not hasManjuanEffect(friend) and self:hasTrickEffective(card, use.from, friend) and table.contains(targets, friend) 	then
				return friend
			end
		end
		return nil
	elseif __htms_value_call(card,"isKindOf","GodSalvation") then
		local lord = self.room:getLord()
		if self:isWeak(lord) and viewer_role(self,self.player) == "loyalist" and self:hasTrickEffective(card, use.from, lord)  and table.contains(targets, lord) then
			return lord
		end
		self.friends = self:sort(self.friends, "hp")
		if self:isWeak() and self:hasTrickEffective(card, use.from, self.player)  then
			return nil
		else
			for _, target in sgs.qlist(self.friends) do
				if self:hasTrickEffective(card, use.from, target) and __htms_value_call(target,"getHp") < getBestHp(target)   and table.contains(targets, target) then
					return target
				end
			end
		end
		return nil
	elseif  __htms_value_call(card,"isKindOf","Duel") or __htms_value_call(card,"isKindOf","FireAttack") or __htms_value_call(card,"isKindOf","EXCard_WWJZ") then
		local nature = sgs.DamageStruct_Normal
		if __htms_value_call(card,"isKindOf","FireAttack") then
			nature = sgs.DamageStruct_Fire
		end
		self.enemies = self:sort(self.enemies, "hp")
		self.friends = self:sort(self.friends, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, use.from, enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nature) and  table.contains(targets, enemy) and self:canDamage(enemy,self.player,nil)	then
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, use.from, enemy) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
		for _, friend in ipairs(self.friends) do
			if ((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, use.from, card)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, use.from, friend) or not self:damageIsEffective(friend, nature)  and  table.contains(targets, friend) then
				return friend
			end
		end
		return targets[1]
	elseif  __htms_value_call(card,"isKindOf","ArcheryAttack") or __htms_value_call(card,"isKindOf","SavageAssault") then
		local nature = sgs.DamageStruct_Normal
		if __htms_value_call(card,"isKindOf","FireAttack") then
			nature = sgs.DamageStruct_Fire
		end
		self.enemies = self:sort(self.enemies, "hp")
		self.friends = self:sort(self.friends, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, use.from, enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nature) and self:canDamage(enemy,self.player,nil) and not enemy:hasArmorEffect("vine") and  table.contains(targets, enemy) 	then
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, use.from, enemy) and not self:cantbeHurt(enemy)  and not enemy:hasArmorEffect("vine") and self:canDamage(enemy,self.player,nil)	and  table.contains(targets, enemy) then
				return enemy
			end
		end
		for _, friend in ipairs(self.friends) do
			if (((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, use.from, card)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, use.from, friend) or not self:damageIsEffective(friend, nature) or  friend:hasArmorEffect("vine")) and  table.contains(targets, friend) then
				return friend
			end
		end
		return targets[1]
	elseif __htms_value_call(card,"isKindOf","Collateral") then
		self.enemies = self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getWeapon()) and self:hasTrickEffective(card, use.from, enemy) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif __htms_value_call(card,"isKindOf","Dismantlement")  or __htms_value_call(card,"isKindOf","Snatch") then
		if self:isFriend(use.from) and (self.player:getJudgingArea():length() > 0 or self:hasSkills(sgs.lose_equip_skill, self.player)) and self:hasTrickEffective(card, use.from, self.player) then
			return nil
		end
			if __htms_value_call(card,"isKindOf","Dismantlement") then
				self.enemies = self:sort(self.enemies, "handcard")
				for _, enemy in ipairs(self.enemies) do
					if self:doDisCard(enemy, "hej") and self:hasTrickEffective(card, use.from, enemy) and  table.contains(targets, enemy)	then
						return enemy
					end
				end
				for _, enemy in ipairs(self.enemies) do
					if  self:hasTrickEffective(card, use.from, enemy) and  table.contains(targets, enemy)	then
						return enemy
					end
				end
			end
	elseif __htms_value_call(card,"isKindOf","GodFlower") or __htms_value_call(card,"isKindOf","Snatch") then
		self.enemies = self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if self:isEnemy(use.from) and self:hasTrickEffective(card, use.from, enemy) and (enemy:getJudgingArea():length() < 1 or not self:hasSkills(sgs.lose_equip_skill, enemy)) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif __htms_value_call(card,"isKindOf","IronChain") then
		for _, friend in ipairs(self.friends) do
			if self:hasTrickEffective(card, use.from, friend) and friend:isChained()  and  table.contains(targets, friend) then
				return friend
			end
		end

		for _, enemy in ipairs(self.enemies) do
			if  self:hasTrickEffective(card, use.from, enemy)  and  table.contains(targets, enemy) and not enemy:isChained()	then
				return enemy
			end
		end
	elseif __htms_value_call(card,"isKindOf","DelayedTrick") then

		for _, enemy in ipairs(self.enemies) do
			if  not self.player:isProhibited(enemy, card) and not enemy:containsTrick(card:objectName())   and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif __htms_value_call(card,"isKindOf","Slash") then

		for _, enemy in ipairs(self.enemies) do
			if  not self:slashProhibit(card, enemy)
				and self:slashIsEffective(card, enemy)
				and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	end

	return nil
end

sgs.ai_skill_invoke.fuqian = function(self, data)
	return self:isEnemy(self.room:getCurrent():getNextAlive())
end


sgs.ai_fill_skill["zangsong"] = function(self,inclusive,request)
    if self.player:hasUsed("#zangsongCard") then return nil end
	if  (#self.enemies == 0) then return nil end
		return policy(self,"#zangsongCard:.:")
end

sgs.ai_skill_use_func["#zangsongCard"] =function(card,use,self)
	self.enemies = self:sort(self.enemies, "defense")
	local target
	local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
						and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
						and enemy:objectName() ~= self.player:objectName() and not enemy:isKongcheng() then
					target = enemy
					break
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
				if  not enemy:isKongcheng() then
					target = enemy
					break
		end
		end
	end
	if target then
	use.card = policy(self,"#zangsongCard:.:")
		if use.to then
			use.to:append(target)
	end
	end
end

sgs.ai_use_value["zangsongCard"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["zangsongCard"] = sgs.ai_use_priority.Slash - 0.2

sgs.ai_skill_invoke.jianwushu = function(self, data)
	local target = data:toPlayer()
	return self:doDisCard(target, "he")
end

sgs.ai_choicemade_filter.cardChosen.jianwushu = sgs.ai_choicemade_filter.cardChosen.dismantlement

sgs.ai_event_callback[sgs.GameStart].Cjiyongbing = function(self, player, data)
		for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
			if __htms_value_call(sb,"hasSkill","Cjiyongbing") then
				role_event(self,sb,"Cjiyongbing",viewer_role(self,sb))
				self:updatePlayers()
			end
		end
end

sgs.ai_event_callback[sgs.Death].Cjiyongbing = function(self, player, data)
		for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
			if __htms_value_call(sb,"hasSkill","Cjiyongbing") then
				role_event(self,sb,"Cjiyongbing",viewer_role(self,sb))
				self:updatePlayers()
			end
		end
end
sgs.ai_event_callback[sgs.TurnStart].Cjiyongbing = function(self, player, data)
		for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
			if __htms_value_call(sb,"hasSkill","Cjiyongbing") then
				role_event(self,sb,"Cjiyongbing",viewer_role(self,sb))
				self:updatePlayers()
			end
		end
end


sgs.ai_skill_invoke.huoliquankai = function(self, data)
	if #self.enemies > 0 then
		for _, enemy in ipairs(self.enemies) do
			if  self:objectiveLevel(enemy) > 3 and
			not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and self:canDamage(enemy,self.player,nil)  then
			return self.player:getCards("he"):length() < 4
			end
		end
	end
	return false
end
sgs.ai_skill_playerchosen.huoliquankai = function(self, targets)

	targets = sgs.QList2Table(targets)

	for _, target in ipairs(targets) do
		if self:isEnemy(target)  and self:objectiveLevel(target) > 3 and
			not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and self:canDamage(target,self.player,nil) then
			return target
		end
	end

	return targets[1]
end
sgs.ai_skill_playerchosen.juexingmoshen = function(self, targets)

	targets = sgs.QList2Table(targets)

	for _, target in ipairs(targets) do
		if self:isEnemy(target)  and self:objectiveLevel(target) > 3 and
			not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and self:canDamage(target,self.player,nil) then
			return target
		end
	end

	return nil
end




sgs.ai_skill_invoke.wujinzhishu = function(self, data)
	return true
end



sgs.ai_fill_skill["chunrijilu"] = function(self,inclusive,request)
	self:updatePlayers()
	local choices = {}
	for _,id in sgs.qlist(self.player:getPile("s_ye")) do
		local card = visible(self,id)
		if __htms_value_call(card,"isAvailable",self.player) and self:getCardsNum(__htms_value_call(card,"getClassName")) == 0 then
			table.insert(choices, card)
		end
	end

	if next(choices) then
		return policy(self,"#chunrijilu:.:")
	end
end

sgs.ai_skill_use_func["#chunrijilu"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	handcards = self:sortByUseValue(handcards, true)
	local useable_cards = {}
	for _,c in ipairs(handcards) do
		if not __htms_value_call(c,"isKindOf","Peach")
		and not __htms_value_call(c,"isKindOf","Analeptic")
		and not (__htms_value_call(c,"isKindOf","Analeptic") and self:getCardsNum("Analeptic") == 1 and __htms_value_call(self.player,"getHp") <= 1)
		and not (__htms_value_call(c,"isKindOf","Jink") and self:getCardsNum("Jink") == 1)
		and not __htms_value_call(c,"isKindOf","Nullification")
		and not __htms_value_call(c,"isKindOf","SavageAssault")
		and not __htms_value_call(c,"isKindOf","ArcheryAttack")
		and not __htms_value_call(c,"isKindOf","Duel")
		and not __htms_value_call(c,"isKindOf","Armor")
		and not __htms_value_call(c,"isKindOf","DefensiveHorse")
		then
			table.insert(useable_cards, c)
		end
	end
	if #useable_cards == 0 then return end
	local card_str = string.format("#chunrijilu:%s:", __htms_value_call(useable_cards[1],"getEffectiveId"))
	local acard = policy(self,card_str)
	use.card = acard
end

sgs.ai_use_priority["chunrijilu"] = 1
sgs.ai_use_value["chunrijilu"] = 3


sgs.ai_skill_use["@@chunrijilu!"] = function(self, prompt, method)
	for _,id in sgs.qlist(self.player:getPile("s_ye")) do
		local card = visible(self,id)
		if __htms_value_call(card,"isAvailable",self.player) and self:getCardsNum(__htms_value_call(card,"getClassName")) == 0 then
			local dummy_use = self:aiUseCard(card, dummy_plan())
			local targets = {}
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					table.insert(targets, p:objectName())
				end
				if #targets > 0 then
					card = mutate(self,card,"skill","chunrijilu")
					return card:getLegacyStringKey() .. "->" .. table.concat(targets, "+")
				end
			end
		end
	end
	return "."
end

sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .. "|chunrijilu"

sgs.ai_skill_use["@@haite"] = function(self, prompt, method)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) then
			table.insert(targets, enemy:objectName())
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:damageIsEffective(friend, sgs.DamageStruct_Normal) and self:needToLoseHp(friend, self.player, nil) then
			table.insert(targets, friend:objectName())
		end
	end
	if #targets > 0 then
		return "#haite:.:->" .. table.concat(targets, "+")
	end
end

sgs.ai_fill_skill["yueying"] = function(self,inclusive,request)
	return policy(self,"#yueying:.:")
end

sgs.ai_skill_use_func["#yueying"] = function(card,use,self)
 local costs=self:selectZhihengCosts();if costs and #costs>0 then use.card=policy(self,"#yueying:"..table.concat(costs,"+")..":")end
end

sgs.ai_use_value["yueying"] = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority["yueying"] = sgs.ai_use_priority.ZhihengCard
sgs.dynamic_value.benefit["yueying"] = sgs.dynamic_value.benefit.ZhihengCard

function sgs.ai_cardneed.yueying(to,card)
	return not __htms_value_call(card,"isKindOf","Jink")
end

sgs.ai_ajustdamage_to.hmrleiji = function(self, from, to, card, nature)
	local names = foreign_property(self,to,"SkillDescriptionRecord_hmrleiji"):split("+")
	if card then
		local name = card:objectName()
		if __htms_value_call(card,"isKindOf","Slash") then name = "hmrleijiSlash" end
		if not table.contains(names, name) then
			return 1
		end
	end
end
sgs.ai_skill_invoke.jiyidiejia = function(self, data)
	local damage = data:toDamage()
	local names, name = foreign_property(self,damage.from,"SkillDescriptionRecord_hmrleiji"):split("+"), damage.card:objectName()
	if __htms_value_call(damage.card,"isKindOf","Slash") then name = "hmrleijiSlash" end
	if self:isFriend(damage.to) then
		if not table.contains(names, name) and (not self:needToLoseHp(damage.to, damage.from, damage.card)) then
			return true
		end
	elseif self:isEnemy(damage.to) then
		if not table.contains(names, name) and self:cantbeHurt(damage.to,damage.from) and self:canDamage(damage.to,damage.from,nil) then
			return true
		end
		if table.contains(names, name) and not self:cantDamageMore(damage.from, damage.to) and self:ajustDamage(damage.from,damage.to, 1, damage.card) > 0 then
			return true
		end
	else
		return true
	end

	return false
end




sgs.ai_skill_invoke.dushe = function(self, data)
	local judge = data:toJudge()
	if self:needRetrial(judge) then
			return true
	end
	return false
end




sgs.ai_fill_skill["zuzhou"] = function(self,inclusive,request)
	if __htms_value_call(self.player,"getMark","@zuzhou") <= 0 then return end
	return policy(self,"#zuzhouCard:.:")
end

sgs.ai_skill_use_func["#zuzhouCard"] = function(card, use, self)
	local weak_target = nil
	local target = nil
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "hp")
	self.enemies = sgs.reverse(self.enemies)

	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and
			not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and self:canDamage(enemy,self.player,nil) and __htms_value_call(enemy,"getHp") + self:getAllPeachNum(enemy) <= 2 then
		weak_target = enemy
		end
	end
	if weak_target == nil then return end
	use.card = card
	if use.to then use.to:append(weak_target) end
end

sgs.ai_use_priority["zuzhouCard"] = 0.5
sgs.ai_use_value["zuzhouCard"] = 0.5




sgs.ai_skill_use["@@xiangyangshi"] = function(self, prompt)
	self:updatePlayers()
	local targets = {}
	for _,p in ipairs(self.friends) do
			if ((__htms_value_call(p,"getHp") < getBestHp(p)) or (__htms_value_call(p,"getHp") < __htms_value_call(p,"getMaxHp") * 2 and __htms_value_call(self.player,"hasSkill","zhiyujz_jx"))) then table.insert(targets, p:objectName()) end
			if #targets >= __htms_value_call(self.player,"getMark","@yanliao") then
				break
			end
		end
	if #targets > 0 then
		return "#xiangyangshi:.:->"..table.concat(targets, "+")
	end
	return "."
end


sgs.recover_hp_skill = sgs.recover_hp_skill .. "|xiangyangshi"

function sgs.ai_cardneed.xiangyangshi(to, card, self)
	return __htms_value_call(to,"getHandcardNum") < 3
end


sgs.ai_fill_skill["shengdanny"] = function(self,inclusive,request)
	if __htms_value_call(self.player,"getHandcardNum") < 1 then return nil end
	 if self.player:hasUsed("#shengdanny") then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local compare_func = function(a, b)
		local v1 = self:getKeepValue(a) + ( a:isRed() and 50 or 0 ) + ( __htms_value_call(a,"isKindOf","Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b) + ( b:isRed() and 50 or 0 ) + ( __htms_value_call(b,"isKindOf","Peach") and 50 or 0 )
		return v1 < v2
	end
	table.sort(cards, compare_func)

	local card_str = ("#shengdanny:%d:"):format(cards[1]:getId())
	return policy(self,card_str)
end

sgs.ai_skill_use_func["#shengdanny"] = function(card, use, self)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and __htms_value_call(arr1[1],"getHp") < getBestHp(arr1[1]) then target = arr1[1] end
	if target and self:getAllPeachNum(self.player) + __htms_value_call(target,"getHp") > 0 then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
	if self:getOverflow() > 0 and #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:needToLoseHp(self.player, friend, nil) and self:damageIsEffective(friend, sgs.DamageStruct_Fire, self.player) and not self:cantbeHurt(friend) then
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
end

sgs.ai_use_priority["shengdanny"] = 4.2
sgs.ai_card_intention["shengdanny"] = -100

sgs.dynamic_value.benefit["shengdanny"] = true

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|shengdanny"
function sgs.ai_cardneed.shengdanny(to, card, self)
	return __htms_value_call(to,"getHandcardNum") < 3
end


sgs.ai_skill_invoke.leijijingyan = function(self, data)
	return true
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|leijijingyan"
function sgs.ai_cardneed.leijijingyan(to, card, self)
	return __htms_value_call(card,"isKindOf","Peach")
end


sgs.ai_skill_invoke.suoersiman = function(self, data)
	if #self.enemies > 0 and self:getCardsNum("Peach") == 0 then
		local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
				and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)  then
				return true
		end
	end
	end
	return false
end

sgs.ai_skill_playerchosen.suoersiman = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

sgs.ai_skill_invoke.yinbiman = function(self, data)
	if  #self.enemies > 0 and self:getCardsNum("Peach") + __htms_value_call(self.player,"getHp") > 1 and self:getCardsNum("Jink") == 0 then
				return true
	end
	if __htms_value_call(self.player,"getHp")  > getBestHp(self.player) then return true end
	if __htms_value_call(self.player,"getMark","@jujiman") > 0 and self:getCardsNum("Peach") + __htms_value_call(self.player,"getHp") > 0 then return true end
	return false
end
sgs.ai_skill_invoke.jujiman = function(self, data)
	local selfSub = self:getOverflow()
	if selfSub > 2 then return false end
	for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)  and self:canDamage(enemy,self.player,nil)
			and self:isGoodTarget(enemy, self.enemies, nil)  then
				return true
		end
		end
	return false
end
sgs.ai_skill_playerchosen.jujiman = function(self, targets)
	for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and not self:cantDamageMore(self.player, enemy) and self:canDamage(enemy,self.player,nil)
			and self:isGoodTarget(enemy, self.enemies, nil)  then
				return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
			if not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy) and not self:cantDamageMore(self.player, enemy)  then
				return enemy
		end
	end
end



sgs.ai_skill_playerchosen.mingduan_put = function(self, targets)
	if self.player:isKongcheng() then
		for _, friend in ipairs(self.friends_noself) do
			if not friend:isKongcheng() then
				return friend
			end
		end
	end
	return self.player
end

sgs.ai_skill_cardask["@mingduanqiuh"] = function(self, data)
	local card = data:toCard()
	local handcards = sgs.QList2Table(self.player:getHandcards())
	if __htms_value_call(self.player,"getPhase") ~= sgs.Player_Play then
		if hasManjuanEffect(self.player) then return "." end
		handcards = self:sortByKeepValue(handcards)
		for _, card_ex in ipairs(handcards) do
			if self:getKeepValue(card_ex) < self:getKeepValue(card) and not self:isValuableCard(card_ex) then
				return "$" .. __htms_value_call(card_ex,"getEffectiveId")
			end
		end
	else
		if __htms_value_call(card,"isKindOf","Slash") and not self:slashIsAvailable() then return "." end
		handcards = self:sortByUseValue(handcards)
		for _, card_ex in ipairs(handcards) do
			if self:getUseValue(card_ex) < self:getUseValue(card) and not self:isValuableCard(card_ex) then
				return "$" .. __htms_value_call(card_ex,"getEffectiveId")
			end
		end
	end
	return "."

end



sgs.ai_fill_skill["yushicp"] = function(self,inclusive,request)
	if not __htms_value_call(self.player,"isWounded") then return end
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "defense")
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	handcards = self:sortByUseValue(handcards, true)
	local use_cards = {}
	for _,c in ipairs(handcards) do
		if not __htms_value_call(c,"isKindOf","Peach") then
				table.insert(use_cards, __htms_value_call(c,"getEffectiveId"))
		end
	end
	if self:getOverflow() <= 0 then return end
	if #use_cards == 0 then return end
	for _, enemy in ipairs(self.enemies) do
			if __htms_value_call(self.player,"isWounded") and getCardsNum("Peach", enemy, self.player) > 0  and not __htms_value_call(enemy,"hasFlag","yushiflag") then
				return policy(self,"#yushicp:" .. use_cards[1] .. ":" .. "peach")
			end
			if  getCardsNum("FireSlash", enemy, self.player) > 0 and not __htms_value_call(enemy,"hasFlag","yushiflag") then
				return policy(self,"#yushicp:" .. use_cards[1] .. ":" .. "fire_slash")
			end
			if getCardsNum("ThunderSlash", enemy, self.player) > 0 and not __htms_value_call(enemy,"hasFlag","yushiflag") then
				return policy(self,"#yushicp:" .. use_cards[1] .. ":" .. "thunder_slash")
			end
			if getCardsNum("NatureSlash", enemy, self.player) > 0 and not __htms_value_call(enemy,"hasFlag","yushiflag") then
				return policy(self,"#yushicp:" .. use_cards[1] .. ":" .. "slash")
			end
	end
end

sgs.ai_skill_use_func["#yushicp"] = function(card, use, self)
	local userstring = card:getLegacyStringKey()
	userstring = (userstring:split(":"))[4]
	do end
	local use_cards = {}
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	handcards = self:sortByUseValue(handcards, true)
	for _,c in ipairs(handcards) do
		if not __htms_value_call(c,"isKindOf","Peach") then
			table.insert(use_cards, __htms_value_call(c,"getEffectiveId"))
		end
	end
	card = mutate(self,card,"add",use_cards[1])
	for _, enemy in ipairs(self.enemies) do
		if  getCardsNum(userstring, enemy, self.player) > 0  and not __htms_value_call(enemy,"hasFlag","yushiflag") then
			use.card = card
			if use.to then use.to:append(enemy) end
		end
	end
end

sgs.ai_guhuo_card.yushicp = function(self,toname,class_name)
	local cards = {}
  	for i,p in sgs.list(self.room:getOtherPlayers(self.player))do
		for d,c in sgs.list(complete_hand(self,p))do
			if __htms_value_call(c,"isKindOf",class_name) and class_name=="Slash"
			then table.insert(cards,c) end
		end
	end
	cards = self:sortByKeepValue(cards,nil,"l")
  	for d,c in sgs.list(cards)do
		if self:getCardsNum(class_name)>0 then break end
		return "#yushicp:.:"..toname
	end
end


sgs.ai_skill_invoke.wushitexing = function(self, data)
	local use = data:toCardUse()
	local good = 0
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal) then
			good = good - 1
		elseif self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal) then
			good = good + 1
		end
	end
	return good > 0
end

sgs.ai_cardneed.wushitexing = sgs.ai_cardneed.slash

sgs.ai_skill_invoke.shanyao = function(self,data)
	local effect = data:toCardEffect()
	local slash = clone(self,"slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	if self:isFriend(effect.to,self.player) then return false end
	if  effect.to and self:isEnemy(effect.to) and  self:slashIsEffective(slash, effect.to) and not self:slashProhibit(slash, effect.to) and self:isGoodTarget(effect.to, self.enemies, slash) then
	return true
	end
end
sgs.ai_card_priority.shanyao = function(self,card)
	if __htms_value_call(card,"isKindOf","Slash") and card:isRed()
	then return 0.05 end
end

sgs.ai_skill_playerchosen["jiansu"] = function(self, targets)
	local target = self.room:getCurrent()
	for _, enemy in ipairs(self.enemies) do
		if target and self:isFriend(target) and target:canSlash(enemy) and not self:slashProhibit(nil, enemy) and self:getDefenseSlash(enemy) <= 2 and self:isGoodTarget(enemy, self.enemies, nil)
				and enemy:objectName() ~= self.player:objectName() then
			return enemy
		end
	end
	return nil
end
sgs.ai_cardneed.shanyao = sgs.ai_cardneed.jiang
sgs.ai_cardneed.jiansu = sgs.ai_cardneed.slash

sgs.ai_fill_skill["yugao"] = function(self,inclusive,request)
	 if #self.enemies == 0 then return nil end
	 local id = room_tag(self,"yugao_card","Int")
	 if id ~= 0 then return nil end
	 if (__htms_value_call(self.player,"getMark","@yugao") == 0) then return nil end

	local card_str = ("#yugao:.:")
	return policy(self,card_str)
end

sgs.ai_skill_use_func["#yugao"] = function(card, use, self)

		self.enemies = self:sort(self.enemies, "handcard")
		self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end

end

sgs.ai_skill_use["@@yugao"] = function(self, prompt, method)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "handcard")
		self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				return "#yugao:.:->"..enemy:objectName()
			end
		end
	for _, player in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
		if not player:isKongcheng() then
			return "#yugao:->"..player:objectName()
		end
	end
	return "."
end

sgs.ai_skill_invoke.yugao = function(self,data)
	local target = data:toPlayer()
	if target then
		local cards = sgs.QList2Table(complete_hand(self,target))
		cards = self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if self:getUseValue(card) >= 6 then
				return true
			end
		end
		local id = room_tag(self,"yugao_card","Int")
		return id == 0
	end
end

sgs.ai_skill_askforag["yugao"] = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, visible(self,card_id))
	end
	cards = self:sortByUseValue(cards)
	if #cards > 0 then
		return __htms_value_call(cards[1],"getEffectiveId")
	end
end

sgs.ai_card_priority.guaidao = function(self,card)
	if card and __htms_value_call(card,"hasFlag","cardTip:yugao")
	then return 1 end
end



sgs.ai_skill_invoke.weituo = function(self,data)
	local damage = data:toDamage()
	if damage.to and self:isFriend(damage.to) and damage.from and self:isEnemy(damage.from) then
		return true
	end
	if damage.to and self:isEnemy(damage.to) and damage.from and self:isEnemy(damage.from) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.weituo11 = function(self,data)
	local damage = data:toDamage()
	if  damage.from and self:isEnemy(damage.from) then
		return true
	end
	return false
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|yuanhuo"




sgs.ai_skill_playerchosen["zhihouz"] = function(self, targets)
self.enemies = self:sort(self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if __htms_value_call(enemy,"getHp") >= __htms_value_call(self.player,"getHp") and not enemy:isKongcheng() then
					return enemy
				end
			end
	return nil
end
sgs.ai_skill_invoke.zhengdao = function(self,data)
	local use = data:toCardUse()

	if use.card then
	self.enemies = self:sort(self.enemies, "handcard")
		if __htms_value_call(use.card,"getNumber") > 10 and __htms_value_call(self.player,"getMark","@zhengdao") == 0 then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isKongcheng() then
					return true
				end
			end
		elseif __htms_value_call(use.card,"getNumber") < 8 and __htms_value_call(self.player,"getMark","@zhengdao") ~= 0 then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isKongcheng() then
					return true
				end
			end
		end
		if self:getUseValue(use.card) < 5.6 then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isKongcheng() then
					return true
				end
			end
		end
	end
	return false
end
sgs.ai_skill_playerchosen["zhengdao"] = function(self, targets)
	self.enemies = self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h", true) and self:hasSkills(sgs.dont_kongcheng_skill, enemy) then
			return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h", true) and self:hasSkills(sgs.cardneed_skill, enemy) then
			return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h", true) then
			return enemy
		end
	end
	return nil
end




sgs.ai_skill_invoke.jiqiangs = function(self,data)
	local use = data:toCardUse()
	local slash = clone(self,"slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p,self.player) then return false end
		if  p and self:isEnemy(p) and
		self:slashIsEffective(slash, p) and
		not self:slashProhibit(slash, p) and
		self:isGoodTarget(p, self.enemies, slash) then
		return true
		end
	end
end


sgs.ai_cardneed.jiqiangs = sgs.ai_cardneed.slash

function sgs.ai_cardneed.lanyushanbi(to,card,self)
	if not self:willSkipPlayPhase(to) then
		return (isCard("Jink", card, to) and getKnownCard(to, "Jink", true) == 0)
	end
end


sgs.ai_fill_skill["jibanvs"] = function(self,inclusive,request)

if not self.player:hasUsed("#jibanhyCard") then
	local target
	local players =  self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(players) do
		if  __htms_value_call(p,"hasSkill","jibanhy") and (self:isFriend(p) or sgs.ai_role[p:objectName()]=="neutral") then
			target = p
			break
		end
	end
	if target then
		return policy(self,"#jibanhyCard:.:")
		end
	end
end


sgs.ai_skill_use_func["#jibanhyCard"] = function(card,use,self)
	local target
	local players = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(players) do
		if __htms_value_call(p,"hasSkill","jibanhy") and (self:isFriend(p) or sgs.ai_role[p:objectName()]=="neutral") then
			target = p
			break
		end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_event_callback[sgs.GameStart].chenmohy = function(self, player, data)
	for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
		if __htms_value_call(sb,"hasSkill","chenmohy") then
			role_event(self,sb,"chenmohy",viewer_role(self,sb))
			self:updatePlayers()
		end
	end
end



sgs.ai_skill_playerchosen["weixiaojn"] = function(self, targets)
self.enemies = self:sort(self.enemies, "handcard")
self.enemies = sgs.reverse(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if  not enemy:isKongcheng() then
					return enemy
				end
			end
	return nil
end

sgs.ai_skill_playerchosen["nvzidao"] = function(self, targets)
self.enemies = self:sort(self.enemies, "handcard")
self.enemies = sgs.reverse(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if  not enemy:isKongcheng() then
					return enemy
				end
			end
	return nil
end
local function card_for_nvzidao(self, who, return_prompt)
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if not __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (__htms_value_call(enemy,"hasSkill","hongyan") or __htms_value_call(judge,"isKindOf","Lightning")) then
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
				if __htms_value_call(equip,"isKindOf","OffensiveHorse") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","Weapon") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif __htms_value_call(equip,"isKindOf","Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if __htms_value_call(card,"isKindOf","Armor") or __htms_value_call(card,"isKindOf","DefensiveHorse") then
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
				if __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					card = visible(self,__htms_value_call(judge,"getEffectiveId"))
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
		if card==nil or target==nil then
			if not who:hasEquip() or self:hasSkills(sgs.lose_equip_skill, who) then return nil end
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(visible(self,card_id)) then card = visible(self,card_id) end

			if card then
				if __htms_value_call(card,"isKindOf","Armor") or __htms_value_call(card,"isKindOf","DefensiveHorse") then
					self.friends = self:sort(self.friends, "defense")
				else
					self.friends = self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and self:hasSkills(sgs.lose_equip_skill .. "|shensu" , friend) then
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

	if return_prompt == "card" then return card
	elseif return_prompt == "target" then return target
	else
		return (card and target)
	end
end

sgs.ai_skill_use["@@nvzidao"] = function(self, prompt)
	self:updatePlayers()
		self.enemies = self:sort(self.enemies, "defense")
		for _, friend in ipairs(self.friends) do
			if not friend:getCards("j"):isEmpty() and not friend:containsTrick("YanxiaoCard") and card_for_nvzidao(self, friend, ".") then
				return "#nvzidaoCard:.:->".. friend:objectName()
			end
		end

		for _, enemy in ipairs(self.enemies) do
			if not enemy:getCards("j"):isEmpty() and enemy:containsTrick("YanxiaoCard") and card_for_nvzidao(self, enemy, ".") then
				return "#nvzidaoCard:.:->".. enemy:objectName()
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if not friend:getCards("e"):isEmpty() and self:hasSkills(sgs.lose_equip_skill, friend) and card_for_nvzidao(self, friend, ".") then
				return "#nvzidaoCard:.:->".. friend:objectName()
			end
		end

		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if card_for_nvzidao(self, enemy, ".") then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			targets = self:sort(targets, "defense")
			return "#nvzidaoCard:.:->".. targets[#targets]:objectName()
		end
	return "."
end

sgs.ai_skill_cardchosen["nvzidaoCard"] = function(self, who, flags)
	if flags == "ej" then
		return card_for_nvzidao(self, who, "card")
	end
end
sgs.ai_skill_playerchosen["nvzidaoCard"] = function(self, targets)
	local who = room_tag(self,"nvzidaoTarget","Player")
	if who then
		if not card_for_nvzidao(self, who, "target") then do end end
		return card_for_nvzidao(self, who, "target")
	end
end

sgs.ai_card_priority.nvzidao = function(self,card,v)
	if __htms_value_call(self.player,"getMark","@weixiao")+__htms_value_call(card,"getNumber") == 25
	then return 10 end
end
sgs.ai_card_priority.weixiaojn = function(self,card,v)
	if __htms_value_call(self.player,"getMark","@weixiao")+__htms_value_call(card,"getNumber") == 25
	then return 10 end
end


sgs.ai_skill_invoke.chuanxiao = function(self,data)
	local damage = data:toDamage()
	if self:needToLoseHp(self.player, damage.from, damage.card) then return false end
	return true
end

sgs.ai_cardneed.yijizho = sgs.ai_cardneed.slash
sgs.hit_skill = sgs.hit_skill .. "|yijizho"

sgs.ai_fill_skill["duandai"] = function(self,inclusive,request)
	if (__htms_value_call(self.player,"hasFlag","duandai_e") and __htms_value_call(self.player,"hasFlag","duandai_h") and __htms_value_call(self.player,"hasFlag","duandai_j")	) then return end
	local card, target
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(player) then
		local judges = player:getJudgingArea()
		if not judges:isEmpty() and not __htms_value_call(self.player,"hasFlag","duandai_j")  then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if not __htms_value_call(judge,"isKindOf","YanxiaoCard") then
							target = player
							break
				end
			end
		end

		local equips = player:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, player) and not __htms_value_call(self.player,"hasFlag","duandai_e") then
			for _, equip in sgs.qlist(equips) do
				if __htms_value_call(equip,"isKindOf","OffensiveHorse") then card = equip  target = player break
				elseif __htms_value_call(equip,"isKindOf","Weapon") then card = equip  target = player break
				elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(player) then
					card = equip
					target = player
					break
				elseif __htms_value_call(equip,"isKindOf","Armor") and (not self:isWeak(player) or self:needToThrowArmor(player)) then
					card = equip
					target = player
					break
				end
			end

		end
	else
		local judges = player:getJudgingArea()
		if player:containsTrick("YanxiaoCard") and not __htms_value_call(self.player,"hasFlag","duandai_j") then
			for _, judge in sgs.qlist(judges) do
				if __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					card = visible(self,__htms_value_call(judge,"getEffectiveId"))
							target = player
							break
				end
			end
		end
		if card==nil or target==nil then
			if  player:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, player) and not __htms_value_call(self.player,"hasFlag","duandai_e") then
			local card_id = self:askForCardChosen(player, "e", "snatch")
			if card_id >= 0 and player:hasEquip(visible(self,card_id)) then card = visible(self,card_id) end

			if card then

						target = player
						break
			end
			end
		end
		if card==nil or target==nil then
			if  not player:isKongcheng() and self:doDisCard(player, "hej") and not __htms_value_call(self.player,"hasFlag","duandai_h") then
			local card_id = self:askForCardChosen(player, "h", "snatch")
			if card_id >= 0 then card = visible(self,card_id) end

			if card then

						target = player
						break
			end
			end
		end
	end
	end
	if card  and target then return policy(self,"#duandai:.:") end
end

sgs.ai_skill_use_func["#duandai"]=function(card,use,self)
	local card, target
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(player) then
		local judges = player:getJudgingArea()
		if not judges:isEmpty() and not __htms_value_call(self.player,"hasFlag","duandai_j")  then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if not __htms_value_call(judge,"isKindOf","YanxiaoCard") then
							target = player
							break
				end
			end
		end

		local equips = player:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, player) and not __htms_value_call(self.player,"hasFlag","duandai_e") then
			for _, equip in sgs.qlist(equips) do
				if __htms_value_call(equip,"isKindOf","OffensiveHorse") then card = equip  target = player break
				elseif __htms_value_call(equip,"isKindOf","Weapon") then card = equip  target = player break
				elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(player) then
					card = equip
					target = player
					break
				elseif __htms_value_call(equip,"isKindOf","Armor") and (not self:isWeak(player) or self:needToThrowArmor(player)) then
					card = equip
					target = player
					break
				end
			end

		end
	else
		local judges = player:getJudgingArea()
		if player:containsTrick("YanxiaoCard") and not __htms_value_call(self.player,"hasFlag","duandai_j") then
			for _, judge in sgs.qlist(judges) do
				if __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					card = visible(self,__htms_value_call(judge,"getEffectiveId"))
							target = player
							break
				end
			end
		end
		if card==nil or target==nil then
			if  player:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, player) and not __htms_value_call(self.player,"hasFlag","duandai_e") then
			local card_id = self:askForCardChosen(player, "e", "snatch")
			if card_id >= 0 and player:hasEquip(visible(self,card_id)) then card = visible(self,card_id) end

			if card then

						target = player
						break
			end
			end
		end
		if card==nil or target==nil then
			if  not player:isKongcheng() and self:doDisCard(player, "hej") and not __htms_value_call(self.player,"hasFlag","duandai_h") then
			local card_id = self:askForCardChosen(player, "h", "snatch")
			if card_id >= 0 then card = visible(self,card_id) end

			if card then

						target = player
						break
			end
			end
		end
	end
	end
	if card  and target then
		use.card = policy(self,"#duandai:.:")
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_cardask["@duandai"]=function(self, data, pattern, target)
	local dest = data:toPlayer()
	if dest and self:isFriend(dest) then return "." end
	local color = "red"
	if string.find(pattern, color) then
	else
		color = "black"
	end
	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return "." end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not __htms_value_call(card,"hasFlag","using") and card:isRed() and  color == "red" and not __htms_value_call(card,"isKindOf","Peach")  then
			table.insert(cards, card)
			break
		end
		if not __htms_value_call(card,"hasFlag","using") and card:isBlack() and  color == "black"  then
			table.insert(cards, card)
			break
		end
	end

	if #cards == 0 then return "." end
	if #cards > 0 then
		return "$" .. cards[1]:getId()
	end
	return "."
end

sgs.ai_skill_choice["duandai"] = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	local card
	if self:isFriend(target) then
		local judges = target:getJudgingArea()
		if not judges:isEmpty() and not __htms_value_call(self.player,"hasFlag","duandai_j")  then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if not __htms_value_call(card,"isKindOf","YanxiaoCard") then
					return "duandai_j"
				end
			end
		end

		local equips = target:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, target) and not __htms_value_call(self.player,"hasFlag","duandai_e") then
			for _, equip in sgs.qlist(equips) do
				if __htms_value_call(equip,"isKindOf","OffensiveHorse") then card = equip   break
				elseif __htms_value_call(equip,"isKindOf","Weapon") then card = equip   break
				elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(target) then
					card = equip
					break
				elseif __htms_value_call(equip,"isKindOf","Armor") and (not self:isWeak(target) or self:needToThrowArmor(target)) then
					card = equip
					break
				end
			end
			if card then
				return "duandai_e"
			end
		end
	else
		local judges = target:getJudgingArea()
		if target:containsTrick("YanxiaoCard") and not __htms_value_call(self.player,"hasFlag","duandai_j") then
			for _, judge in sgs.qlist(judges) do
				if __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					card = visible(self,__htms_value_call(judge,"getEffectiveId"))
					return "duandai_j"
				end
			end
		end

			if  target:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, target) and not __htms_value_call(self.player,"hasFlag","duandai_e") then
			local card_id = self:askForCardChosen(target, "e", "snatch")
			if card_id >= 0 and target:hasEquip(visible(self,card_id)) then card = visible(self,card_id) end

			if card then
				return "duandai_e"
			end
			end

			if  not target:isKongcheng() and self:doDisCard(target, "hej") and not __htms_value_call(self.player,"hasFlag","duandai_h") then
			local card_id = self:askForCardChosen(target, "h", "snatch")
			if card_id >= 0 then card = visible(self,card_id) end

			if card then
				return "duandai_h"
			end
			end
	end
	return items[1]
end

sgs.ai_skill_cardchosen["duandai"] = function(self, who, flags)
	local card
	if flags == "j" then
		if self:isFriend(who) then
			local judges = who:getJudgingArea()
		if not judges:isEmpty()   then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if not __htms_value_call(judge,"isKindOf","YanxiaoCard") then
							return card
						end
					end
				end
		elseif self:isEnemy(who) then
			local judges = who:getJudgingArea()
		if not judges:isEmpty()   then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if __htms_value_call(judge,"isKindOf","YanxiaoCard") then
							return card
						end
					end
				end
		end
	end
	if flags == "e" then
	if self:isFriend(who) then
		local equips = who:getEquips()
		if not who and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, who)  then
			for _, equip in sgs.qlist(equips) do
				if __htms_value_call(equip,"isKindOf","OffensiveHorse") then card = equip   break
				elseif __htms_value_call(equip,"isKindOf","Weapon") then card = equip   break
				elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif __htms_value_call(equip,"isKindOf","Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end
			if card then
				return card
			end
		end
		elseif self:isEnemy(who) then
			if  who:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, who)  then
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(visible(self,card_id)) then card = visible(self,card_id) end

			if card then
				return card
			end
			end
		end
	end
	if flags == "h" then
		local cards = sgs.QList2Table(complete_hand(self,who))
		return cards[1]
	end
end

sgs.ai_cardneed.duandai = sgs.ai_cardneed.slash

sgs.ai_view_as.tucao = function(card, player, card_place)
	local suit = __htms_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __htms_value_call(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		if __htms_value_call(card,"isKindOf","BasicCard") and not __htms_value_call(player,"hasFlag","tucaoks") then
			return ("nullification:tucao[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end
sgs.ai_skill_playerchosen["tucao"] = function(self, targets)
	return self:findPlayerToDiscard("ej", true, false, targets, false)[1]
end

sgs.ai_skill_choice["#tucaoxx"] = function(self, choices)
	if self:getCardsNum("BasicCard") <= 1 then return "tucao:mp" end
	if self:findPlayerToDiscard("ej", true, false, nil, false) ~= {} and not self:isWeak() then
		return "tucao:qp"
		end
	return "tucao:mp"
end

sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|tucao"

function sgs.ai_cardneed.tucao(to,card,self)
	if not self:willSkipPlayPhase(to) then
		return (isCard("BasicCard", card, to) and getKnownCard(to, "BasicCard", true) == 0)
	end
end



sgs.ai_fill_skill["wangwei"] = function(self,inclusive,request)
	if __htms_value_call(self.player,"getHandcardNum") < 1 then return nil end
	if self.player:hasUsed("#wangwei") then return nil end

	return policy(self,"#wangwei:.:")
end

sgs.ai_skill_use_func["#wangwei"] = function(card, use, self)
	local targets = AIList.new({})
	local cards = self.player:getCards("h")

	local use_card = {}
	cards = sgs.QList2Table(cards)
	if #cards == 0 then return end
	cards = self:sortByKeepValue(cards)
	local color = cards[1]:isRed()
	for _, card in ipairs(cards) do
		if (card:isRed() and color) or (card:isBlack() and not color)  and not __htms_value_call(card,"isKindOf","Peach") then
			table.insert(use_card, card:getId())
		end
	end
		if __htms_value_call(self.player,"getMark","@wangquan") == 0 and #use_card > 0 then
			targets:append(self.player)
		end
		for _,p in ipairs(self.friends) do
			if targets:length() >= #use_card then
				break
			end
			if __htms_value_call(p,"getMark","@wangquan") == 0 and not targets:contains(p) then targets:append(p) end

		end

	if targets:length() < #use_card  then
		table.removeOne(use_card, use_card[#use_card])
	end
	if targets:length() < #use_card  then
		table.removeOne(use_card, use_card[#use_card])
	end
	if targets:length()> 0 then
		if #use_card == 1 then
		use.card = policy(self,"#wangwei:"..use_card[1] ..":")
		else
		use.card = policy(self,"#wangwei:".. table.concat(use_card, "+")..":")
		end
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_priority["wangwei"] = 4.2
sgs.ai_card_intention["wangwei"] = -100


sgs.ai_skill_choice["qidao"] = function(self, choices, data)
	local move = data:toMoveOneTime()
	local target = move.to
	local items = choices:split("+")
	local card_ids = AIList.new({})
	for _, card_id in sgs.qlist(move.card_ids) do
					if (move.to_place == sgs.Player_PlaceHand) then
						card_ids:append(card_id)
					end
				end
	if target then
		if self:isFriend(target) then
			if __htms_value_call(self.player,"getLostHp") > card_ids:length() then
				return "qidao_draw"
			end
		elseif self:isEnemy(target) then
			if target:canDiscard(target, "he") and table.contains(items, "qidao_dis") and self:doDisCard(target, "he") then
				return "qidao_dis"
			end
		end
	end
	return "cancel"
end

sgs.ai_choicemade_filter.skillChoice["qidao"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __htms_value_call(p,"hasFlag","qidao_target") then
			if choice == "qidao_draw" then
				self:updateIntention(player, p, -80)
			elseif choice == "qidao_dis" then
				self:updateIntention(player, p, 80)
			end
		end
	end
end

sgs.ai_skill_playerchosen["qiyuan"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "handcard")
	targets = sgs.reverse(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and  __htms_value_call(target,"getMaxCards") < 4 then
			return target
		end
	end
end
sgs.ai_fill_skill["qiyuan"] = function(self,inclusive,request)
	if __htms_value_call(self.player,"getMark","qidao_lun") == 0 then return end
	if self.player:hasUsed("#qiyuan") or (__htms_value_call(self.player,"getMark","@qiyuan") + __htms_value_call(self.player,"getMaxCards") < 4) then return end
	return policy(self,"#qiyuan:.:")
end

sgs.ai_skill_use_func["#qiyuan"] = function(wuqiancard, use, self)
	use.card = wuqiancard
end

sgs.ai_view_as.LuaLeishi = function(card, player, card_place)
    local suit = __htms_value_call(card,"getSuitString")
    local number = card:getNumberString()
    local card_id = __htms_value_call(card,"getEffectiveId")
    if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
	and card_place == sgs.Player_PlaceHand and not __htms_value_call(card,"hasFlag","using") and not __htms_value_call(player,"hasFlag","LuaLeishi_used") then
        return ("thunder_slash:LuaLeishi[%s:%s]=%d"):format(suit, number, card_id)
    end
end

sgs.ai_fill_skill["LuaLeishi"] = function(self,inclusive,request)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)

		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, visible(self,id))
			end
		end

    local slash
    cards = self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
            slash = card
            break
    end

    if not slash then return nil end
    if __htms_value_call(self.player,"hasFlag","LuaLeishi_used") then return nil end
		local card = clone(self,"thunder_slash", sgs.Card_NoSuit, 0)
		card = mutate(self,card,"add",slash)
		card:deleteLater()
	local dummy_use = self:aiUseCard(card, dummy_plan())
    if dummy_use.card and dummy_use.to:length() > 0 then
        local use = dummy_plan(false)
        use.from = self.player
        use.to = dummy_use.to
        use.card = slash
        local data = local_data()
        data:setValue(use)
        if not sgs.ai_skill_invoke.fulu(self, data) then return nil end
    else return nil end

    if slash then
        local suit = __htms_value_call(slash,"getSuitString")
        local number = slash:getNumberString()
        local card_id = __htms_value_call(slash,"getEffectiveId")
        local card_str = ("thunder_slash:LuaLeishi[%s:%s]=%d"):format(suit, number, card_id)
        local mySlash = policy(self,card_str)

        assert(mySlash)
        return mySlash
    end
end


sgs.ai_skill_invoke.Luayuanxing = function(self, data)
    local damage = data:toDamage()
	if self:cantDamageMore(self.player,damage.to) then return false end
    if not self:isFriend(damage.to) then return true end
    return false
end

sgs.ai_skill_use["@@Luayuanling"]=function(self,prompt)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies,"defense")
	local targets = {}
	if __htms_value_call(self.player,"hasSkill","lianhuo") then
		if __htms_value_call(self.player,"getHp") > 1 and not self.player:isChained() then table.insert(targets, self.player:objectName()) end
	end
	local x = math.max(__htms_value_call(self.player,"getMark","Luayuanling"), 1)
	for _, enemy in ipairs(self.enemies) do
		if #targets < x then
			if self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not enemy:isChained() then
				table.insert(targets, enemy:objectName())
			end
		else break end
	end
	if #targets > 0 then
	return "#Luayuanling:.:->"..table.concat(targets, "+")
	end
	return "."
end

sgs.ai_skill_invoke.Luashenyi = function(self, data)
		if #self.enemies == 0 then
			local lord = self.room:getLord()
			if lord and self:isFriend(lord) then
				return true
			end
		end

		local AssistTarget = self:AssistTarget()
		if AssistTarget  then
			return true
		end

		self.friends = self:sort(self.friends, "handcard")
		self.friends = sgs.reverse(self.friends)
		for _, target in ipairs(self.friends) do
			if not __htms_value_call(target,"hasSkill","dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
				and (not self:willSkipPlayPhase(target) or __htms_value_call(target,"hasSkill","shensu")) then
				return true
			end
		end

		for _, target in ipairs(self.friends) do
			if __htms_value_call(target,"hasSkill","dawu") then
				local use = true
				for _, p in ipairs(self.friends) do
					if __htms_value_call(p,"getMark","@fog") > 0 then use = false break end
				end
				if use then
					return true
				end
			else
				return true
			end
		end
	return sgs.ai_skill_playerchosen["Luashenyi"](self, self.room:getAlivePlayers()) ~= nil
end
sgs.ai_skill_playerchosen["Luashenyi"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "handcard")
	targets = sgs.reverse(targets)
	if #self.enemies == 0 then
			local lord = self.room:getLord()
			if lord and self:isFriend(lord) then
				return lord
			end
		end

		local AssistTarget = self:AssistTarget()
		if AssistTarget  then
			return AssistTarget
		end

		self.friends = self:sort(self.friends, "handcard")
		self.friends = sgs.reverse(self.friends)
		for _, target in ipairs(self.friends) do
			if not __htms_value_call(target,"hasSkill","dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
				and (not self:willSkipPlayPhase(target) or __htms_value_call(target,"hasSkill","shensu")) then
				return target
			end
		end

		for _, target in ipairs(self.friends) do
			if __htms_value_call(target,"hasSkill","dawu") then
				local use = true
				for _, p in ipairs(self.friends) do
					if __htms_value_call(p,"getMark","@fog") > 0 then use = false break end
				end
				if use then
					return target
				end
			else
				return target
			end
		end
		return self.player
end

sgs.ai_skill_invoke.luajiejie = function(self, data)
    local target = data:toPlayer()
    if not self:isFriend(target) then return true end
    return false
end




sgs.ai_fill_skill["luakuaiqing"] = function(self,inclusive,request)
	self:setPriorityValue("#luakuaiqing",3,"htms")
	if self.player:getCardCount(true) < 2 then return false end
	if self:getOverflow() <= 0 then return false end
	if self:isWeak() and self:getOverflow() <= 1 then return false end
	return policy(self,"#luakuaiqing:.:")
end
sgs.ai_skill_use_func["#luakuaiqing"] = function(card, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	local x = self.player:usedTimes("#luakuaiqing") + 1
	if x == 2 then
		if self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and __htms_value_call(self.player,"isWounded") then
			table.insert(unpreferedCards, self.player:getArmor():getEffectiveId())
		end
		if __htms_value_call(self.player,"getHp") < 3 then
			local zcards = self.player:getCards("he")
			local  keep_jink, keep_analeptic, keep_weapon =  false, false
			-- Own tag holds the granted skill name; QVariant::toBool reads absent as false.
			local wansha = self.player:getTag("JilveWansha")
			if wansha ~= nil and type(wansha) ~= "string" then ai_unsupported("owner JilveWansha is unknown","JilveWansha") end
			local keep_slash = wansha ~= nil and wansha ~= "" and wansha ~= "0" and wansha:lower() ~= "false"
			for _, zcard in sgs.qlist(zcards) do
				if self.player:isCardLimited(zcard, sgs.Card_MethodDiscard) then continue end
				if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
					local shouldUse = true
					if isCard("Slash", zcard, self.player)  then
						local dummy_use = self:aiUseCard(zcard, dummy_plan())
						if dummy_use.card then
							if keep_slash then shouldUse = false end
							if dummy_use.to then
								for _, p in sgs.qlist(dummy_use.to) do
									if __htms_value_call(p,"getHp") <= 1 then
										shouldUse = false
										if __htms_value_call(self.player,"distanceTo",p) > 1 then keep_weapon = self.player:getWeapon() end
										break
									end
								end
								if dummy_use.to:length() > 1 then shouldUse = false end
							end
							if not self:isWeak() then shouldUse = false end
						end
					end
					if __htms_value_call(zcard,"getTypeId") == sgs.Card_TypeTrick then
						local dummy_use = self:aiUseCard(zcard, dummy_plan())
						if dummy_use.card then shouldUse = false end
					end
					if __htms_value_call(zcard,"getTypeId") == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
						local dummy_use = self:aiUseCard(zcard, dummy_plan())
						if dummy_use.card then shouldUse = false end
						if keep_weapon and __htms_value_call(zcard,"getEffectiveId") == __htms_value_call(keep_weapon,"getEffectiveId") then shouldUse = false end
					end
					if self.player:hasEquip(zcard) and __htms_value_call(zcard,"isKindOf","Armor") and not self:needToThrowArmor() then shouldUse = false end
					if self.player:hasTreasure("wooden_ox") then shouldUse = false end
					if self.player:hasEquip(zcard) and __htms_value_call(zcard,"isKindOf","DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
					if isCard("Jink", zcard, self.player) and not keep_jink then
						keep_jink = true
						shouldUse = false
					end
					if __htms_value_call(self.player,"getHp") == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
						keep_analeptic = true
						shouldUse = false
					end
					if shouldUse then
						if (table.contains(unpreferedCards, zcard:getId())) then continue end
						table.insert(unpreferedCards, zcard:getId())
					end
					if #unpreferedCards == 2 then
						use.card = policy(self,"#luakuaiqing:" .. table.concat(unpreferedCards, "+")..":")
						return
					end
				end
			end
		end



		if #unpreferedCards < 2 then
			for _, c in ipairs(cards) do
				if not self.player:isCardLimited(c, sgs.Card_MethodDiscard) then
					if table.contains(unpreferedCards, c:getId()) then continue end
					table.insert(unpreferedCards, c:getId())
				end
				if #unpreferedCards == 2 then break end
			end
		end

		if #unpreferedCards == 2 then
			use.card = policy(self,"#luakuaiqing:" .. table.concat(unpreferedCards, "+")..":")
			self:setPriorityValue("#luakuaiqing",0,"htms")
			return
		end
	elseif x == 1 then
		local  keep_jink  =  false
		local keep_weapon
		for _, c in ipairs(cards) do
			if not isCard("Peach", c, self.player) and not isCard("ExNihilo", c, self.player) then
				local shouldUse = true
				if isCard("Slash", c, self.player)  then
					local dummy_use = self:aiUseCard(c, dummy_plan())
					if dummy_use.card then
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if __htms_value_call(p,"getHp") <= 1 then
									shouldUse = false
									if __htms_value_call(self.player,"distanceTo",p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
					end
				end
				if __htms_value_call(c,"getTypeId") == sgs.Card_TypeTrick then
					local dummy_use = self:aiUseCard(c, dummy_plan())
						if dummy_use.card then shouldUse = false end
					end
					if __htms_value_call(c,"getTypeId") == sgs.Card_TypeEquip and not self.player:hasEquip(c) then
						local dummy_use = self:aiUseCard(c, dummy_plan())
						if dummy_use.card then shouldUse = false end
						if keep_weapon and __htms_value_call(c,"getEffectiveId") == __htms_value_call(keep_weapon,"getEffectiveId") then shouldUse = false end
					end
				if isCard("Jink", c, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:hasEquip(c) and __htms_value_call(c,"isKindOf","Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(c) and __htms_value_call(c,"isKindOf","DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if shouldUse then
						if (table.contains(unpreferedCards, c:getId())) then continue end
						table.insert(unpreferedCards, c:getId())
					end
					if #unpreferedCards == x then
						use.card = policy(self,"#luakuaiqing:" .. table.concat(unpreferedCards, "+")..":")
						return
					end
			end
		end
	end
end

sgs.ai_use_priority["#luakuaiqing"] = 3



sgs.ai_fill_skill["luajieao"] = function(self,inclusive,request)
	if self.player:hasUsed("#luajieao") then return nil end

	self.enemies = self:sort(self.enemies, "handcard")
	return policy(self,"#luajieao:.:")
end

sgs.ai_skill_use_func["#luajieao"] = function(card, use, self)

	local max_card = self:getMaxCard()

	if not max_card then return end
	if __htms_value_call(max_card,"isKindOf","Jink") and self:getCardsNum("Jink") <= 1 then return end

	local max_point = __htms_value_call(max_card,"getNumber")

	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self:damageIsEffective(enemy, nil, self.player) and __htms_value_call(self.player,"canPindian",enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local enemy_max_point = enemy_max_card and __htms_value_call(enemy_max_card,"getNumber") or 100
			if (max_point > enemy_max_point) or (max_point > 9) then
				local card_str = string.format("#luajieao:%s:", __htms_value_call(max_card,"getEffectiveId"))
				local acard = policy(self,card_str)
				use.card = acard

				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end
sgs.ai_cardneed.luajieao = sgs.ai_cardneed.bignumber




sgs.ai_skill_invoke.luajinlun = function(self, data)



		if #self.enemies == 0 then
			local lord = self.room:getLord()
			if lord and self:isFriend(lord) and __htms_value_call(lord,"getHandcardNum") < 3 then
				return true
			end
		end

		local AssistTarget = self:AssistTarget()
		if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and __htms_value_call(AssistTarget,"getHandcardNum") < 3 then
			return true
		end

		self.friends = self:sort(self.friends, "handcard")
		for _, target in ipairs(self.friends) do
			if not __htms_value_call(target,"hasSkill","dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
				and (not self:willSkipPlayPhase(target) or __htms_value_call(target,"hasSkill","shensu")) and __htms_value_call(target,"getHandcardNum") < 3  then
				return true
			end
		end

		for _, target in ipairs(self.friends) do
			if __htms_value_call(target,"hasSkill","dawu") and __htms_value_call(target,"getHandcardNum") < 3  then
				local use = true
				for _, p in ipairs(self.friends_noself) do
					if __htms_value_call(p,"getMark","@fog") > 0 then use = false break end
				end
				if use then
					return true
				end
			else
				return true
			end
		end
	return false
end

sgs.ai_skill_playerchosen["luajinlun"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "handcard")
	targets = sgs.reverse(targets)
	if #self.enemies == 0  then
			local lord = self.room:getLord()
			if lord and self:isFriend(lord) and __htms_value_call(lord,"getHandcardNum") < 3 then
				return lord
			end
		end

		local AssistTarget = self:AssistTarget()
		if AssistTarget and __htms_value_call(AssistTarget,"getHandcardNum") < 3  then
			return AssistTarget
		end

		self.friends = self:sort(self.friends, "handcard")
		for _, target in ipairs(self.friends) do
			if not __htms_value_call(target,"hasSkill","dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
				and (not self:willSkipPlayPhase(target) or __htms_value_call(target,"hasSkill","shensu")) and __htms_value_call(target,"getHandcardNum") < 3 then
				return target
			end
		end

		for _, target in ipairs(self.friends) do
			if  __htms_value_call(target,"getHandcardNum") < 3 then
				if __htms_value_call(target,"hasSkill","dawu") then
					local use = true
					for _, p in ipairs(self.friends) do
						if __htms_value_call(p,"getMark","@fog") > 0 then use = false break end
					end
					if use then
						return target
					end
				else
					return target
				end
			end
		end
		return self.player
end


sgs.ai_skill_invoke.empaidui = function(self, data)

	local empaidui_string = sgs.ai_skill_use["@@empaidui"](self, prompt, method)
	if empaidui_string == "." then
		return false
	end
	return true
end
sgs.ai_skill_use["@@empaidui"]=function(self,prompt)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies,"defense")
	local targets = {}
	local slash = clone(self,"slash")
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if #targets < __htms_value_call(self.player,"getLostHp") + 1 then
			if self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and not self:slashProhibit(slash, enemy, self.player) then
				table.insert(targets, enemy:objectName())
			end
		else break end
	end
	if #targets < __htms_value_call(self.player,"getLostHp") + 1 then
		for _, enemy in ipairs(self.enemies) do
			if #targets < __htms_value_call(self.player,"getLostHp") + 1 then
				if self:slashIsEffective(slash, enemy) and not self:slashProhibit(slash, enemy, self.player) and not table.contains(targets, enemy:objectName()) then
					table.insert(targets, enemy:objectName())
				end
			else break end
		end
	end
	if #targets == 0 then return "." end
	return "#empaidui:.:->"..table.concat(targets, "+")
end

sgs.hit_skill = sgs.hit_skill .. "|empaidui"
sgs.ai_cardneed.empaidui = sgs.ai_cardneed.slash


sgs.ai_skill_invoke.yftuji = function(self, data)
	local damage = data:toDamage()
	if #self.enemies > 0 then
		if self:needToLoseHp(self.player, damage.to) then
			return true
		end
		if sgs.ai_can_damagehp.yiji(self,damage.to,nil, self.player) then
			return true
		end
	end
	return false
end

sgs.ai_can_damagehp.zhongerhx = function(self,from,card,to)
	return __htms_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end
sgs.ai_skill_invoke.zhongerhx = function(self)
	return true
end

sgs.ai_skill_askforag.zhongerhx = function(self,card_ids)
	local cards = {}
	for d,id in ipairs(card_ids)do
		local card = printed(self,id)
		if __htms_value_call(card,"isKindOf","Analeptic") and self:getCardsNum("Slash")<1 then continue end  --这里应该判断会不会使用【杀】，偷懒一下
		if card:targetFixed() then table.insert(cards,card)
		else
			d = clone(self,card:objectName())
			d = mutate(self,d,"skill","_zhongerhx")
			if self:aiUseCard(d).card then
				table.insert(cards,card)
			end
		end
	end
	if #cards>0 then
		cards = self:sortByUseValue(cards,false)
		return __htms_value_call(cards[1],"getEffectiveId")
	end
	for _,id in ipairs(card_ids)do
		if printed(self,id):isKindOf("Analeptic") then return id end
	end
	return -1
end
sgs.ai_skill_use["@@zhongerhx"] = function(self,prompt)
	local card = self:getZhongerhxCardEvaluation(__htms_value_call(self.player,"getMark","zhongerhuan") - 1)
	local dummy = self:aiUseCard(card)
	if dummy.card
	and dummy.to
	then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return card:getLegacyStringKey().."->"..table.concat(tos,"+")
	end
	return "."
end

sgs.ai_skill_invoke.hanrenzd = function(self, data)
	local damage = data:toDamage()
	if damage.to then
		if self:isEnemy(damage.to) and (not damage.to:getWeapon() or (damage.to:getWeapon() and self:doDisCard(damage.to, damage.to:getWeapon():getEffectiveId()) )) then
			return true
		end
	end
	return false
end
sgs.ai_cardneed.hanrenzd = sgs.ai_cardneed.slash

sgs.ai_skill_invoke.bingfengzd = function(self, data)
	local damage = data:toDamage()
	if damage.from  then
		if self:isEnemy(damage.from)  then
			return true
		end
	end
	return false
end

sgs.ai_can_damagehp.bingfengzd = function(self,from,card,to)
	if from and __htms_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and self:isWeak(from) and from:getCardCount()>0
	end
end

sgs.ai_skill_choice["hezibz"] = function(self, choices, data)
	local items = choices:split("+")
	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and self:isWeak(lord) then return "hezibz:huif" end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) and self:damageIsEffective(player, sgs.DamageStruct_Normal) then
			if self:isFriend(player) then bad = bad + 1
			else good = good + 1
			end
		end
	end
	if good == 0 then return  "hezibz:huif" end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(__htms_value_call(player,"getHp"), 1)
		if  self:damageIsEffective(player, sgs.DamageStruct_Normal) then
			if getCardsNum("Analeptic", player) > 0 then
				if self:isFriend(player) then good = good + 1.0 / hp
				else bad = bad + 1.0 / hp
				end
			end


				local lost_value = 0
				if self:hasSkills(sgs.masochism_skill, player) then lost_value = __htms_value_call(player,"getHp")/2 end
				local hp = math.max(__htms_value_call(player,"getHp"), 1)
				if self:isFriend(player) then bad = bad + (lost_value + 1) / hp
				else good = good + (lost_value + 1) / hp
				end
		end
	end
	if good > bad then return "hezibz:shangh" end
	return "hezibz:huif"
end

sgs.ai_damage_reason_suppress_intention["hezibz"] = true

sgs.ai_skill_cardask["@duancai"] = function(self, data, pattern, target, target2)
	local use = data:toCardUse()
	local target = use.from
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	usable_cards = self:sortByKeepValue(usable_cards)
	local give_card = {}

	if target and self:isEnemy(target) then
		for _,c in ipairs(usable_cards) do
			if __htms_value_call(c,"getNumber") < 8 and  self:getKeepValue(c)  < 6 and not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and self:canDamage(target,self.player,nil)  then
				table.insert(give_card, c)
			end
		end
		if #give_card > 0 then
			return give_card[1]:toString()
		end
	end
	return "."
end
sgs.ai_skill_cardask["@duancaiex"] = function(self, data, pattern, target, target2)
	local use = data:toCardUse()
	local target = use.from
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	usable_cards = self:sortByKeepValue(usable_cards)
	local give_card = {}

	if target and self:isEnemy(target) then
		for _,c in ipairs(usable_cards) do
			if __htms_value_call(c,"getNumber") > 7 and  self:getKeepValue(c)  < 6 and not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and self:canDamage(target,self.player,nil)  then
				table.insert(give_card, c)
			end
		end
		if #give_card > 0 then
			return give_card[1]:toString()
		end
	end
	return "."
end
sgs.ai_cardneed.duancaiex = sgs.ai_cardneed.bignumber

sgs.ai_skill_invoke.midie = function(self, data)
	if self:getCardsNum("Peach") >= 1 - __htms_value_call(self.player,"getHp") then
		return false
	end
	return true
end

sgs.ai_canNiepan_skill.midie = function(player)
	return __htms_value_call(player,"getMark","@midie") > 0
end

sgs.ai_skill_invoke.tongzhouqg = function(self, data)
	if #self.friends + 1 >= #self.enemies  then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@tongzhouqg"] = function(self, data, pattern, target, target2)
	local target = data:toPlayer()
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	usable_cards = self:sortByKeepValue(usable_cards)

	if target then
		if self:isFriend(target) then
			usable_cards = sgs.reverse(usable_cards)
			return usable_cards[1]:toString()
		else
			return usable_cards[1]:toString()
		end
	end
	return "."
end


sgs.ai_skill_use["@@qgjiesi"] = function(self, prompt)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "defense")
	local targets = {}
	local x = __htms_value_call(self.player,"getMark","qgjiesi")
	for _, enemy in ipairs(self.enemies) do
		if  enemy:canDiscard(enemy, "he") and  self:doDisCard(enemy, "he") then
			if #targets >= x then
				break
			end
			table.insert(targets, enemy:objectName())
		end
	end
		if #targets > 0 then
			return ("#qgjiesi:.:->" .. table.concat(targets, "+"))
		end
	return "."
end


sgs.ai_fill_skill["zjyizhen"] = function(self,inclusive,request)
	if self.player:isNude() then return nil end

	local card_str = "#zjyizhenCard:.:"
	return policy(self,card_str)
end

sgs.ai_skill_use_func["#zjyizhenCard"] = function(card, use, self)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and __htms_value_call(arr1[1],"getHp") < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		local to_use = {}
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		cards = self:sortByKeepValue(cards)
		for _,c in ipairs(cards) do
			if #to_use < __htms_value_call(target,"getLostHp") then
				table.insert(to_use, __htms_value_call(c,"getEffectiveId"))
			end
		end
		if #to_use ==  __htms_value_call(target,"getLostHp") then
			local card_str = string.format("#zjyizhenCard:" .. table.concat(to_use, "+")..":")
			local acard = policy(self,card_str)
			use.card = acard
			if use.to then use.to:append(target) end
			return
		end
	end
	if self:getOverflow() > 0 and #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				local to_use = {}
				local cards = self.player:getCards("he")
				cards = sgs.QList2Table(cards)
				cards = self:sortByKeepValue(cards)
				for _,c in ipairs(cards) do
					if #to_use < __htms_value_call(target,"getLostHp") then
						table.insert(to_use, c)
					end
				end
				if #to_use ==  __htms_value_call(target,"getLostHp") then
					local card_str = string.format("#zjyizhenCard:" .. table.concat(to_use, "+")..":")
					local acard = policy(self,card_str)
					use.card = acard
					if use.to then use.to:append(target) end
					return
				end
			end
		end
	end
end

sgs.ai_use_priority["zjyizhenCard"] = 4.2
sgs.ai_card_intention["zjyizhenCard"] = -100

sgs.dynamic_value.benefit["zjyizhenCard"] = true
sgs.ai_use_revises.zjyizhen = function(self,card,use)
	if __htms_value_call(card,"isKindOf","Slash") and self:isWeak()
	and self:getOverflow()<=0
	then return false end
end


sgs.recover_hp_skill = sgs.recover_hp_skill .. "|zjyizhen"
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .. "|zjyizhen"
function sgs.ai_cardneed.zjyizhen(to,card)
	return not __htms_value_call(card,"isKindOf","Jink")
end

sgs.ai_skill_invoke.zjmoshuxif = function(self, data)
		return true
end
sgs.ai_skill_cardask["@zjmoshuxif"] = function(self, data, pattern, target)
	if self:needToThrowArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
		cards = self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if not __htms_value_call(card,"isKindOf","Peach") then
				return "$" .. __htms_value_call(card,"getEffectiveId")
			end
		end
	return "$" .. __htms_value_call(cards[1],"getEffectiveId")
end
sgs.need_equip_skill = sgs.need_equip_skill .. "|zjmoshuxif"



sgs.ai_skill_invoke.zjruoshi = function(self, data)
		return true
end

sgs.ai_skill_choice["zjruoshi"] = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1,#items)]
end



sgs.ai_skill_choice["zjaojiaol"] = function(self, choices, data)
	if self:isWeak() and __htms_value_call(self.player,"isWounded") then return "zjaojiaol:red" end
	return "zjaojiaol:black"
end
sgs.ai_skill_cardchosen["zjaojiaol"] = function(self, who, flags)
	local card
	local handcards = sgs.QList2Table(complete_hand(self,who))
	handcards = self:sortByKeepValue(handcards)

	if self:isFriend(who) then
		if __htms_value_call(who,"getMark","zjaojiaolred") == 1 then
			for _, card in ipairs(handcards) do
				if card:isRed() then
					return card
				end
			end
		elseif __htms_value_call(who,"getMark","zjaojiaolblack") == 1 then
			for _, card in ipairs(handcards) do
				if card:isBlack() then
					return card
				end
			end
		end
		if not who:isKongcheng() then return handcards[1] end
	else
		handcards = sgs.reverse(handcards)
		 return handcards[1]
	end
	return nil
end


sgs.ai_fill_skill["zjaojiaol"] = function(self,inclusive,request)
	if self.player:hasUsed("#zjaojiaol") then return nil end
	if #self.friends_noself == 0 then return nil end
	if self.player:isKongcheng() then return nil end
	return policy(self,"#zjaojiaol:.:")
end

sgs.ai_skill_use_func["#zjaojiaol"] = function(card, use, self)

	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			local card_str = "#zjaojiaol:.:"
				local acard = policy(self,card_str)
				use.card = acard

				if use.to then use.to:append(friend) end
				return
		end
	end
	local AssistTarget = self:AssistTarget()
	local friend
	if AssistTarget and __htms_value_call(AssistTarget,"isWounded") and not self:needToLoseHp(AssistTarget, nil, nil, nil, true) then
		friend = AssistTarget
	elseif AssistTarget and not hasManjuanEffect(AssistTarget) and not self:needKongcheng(AssistTarget, true) then
		friend = AssistTarget
	else
		friend = self.friends_noself[1]
	end
		if friend then
				local card_str = "#zjaojiaol:.:"
				local acard = policy(self,card_str)
				use.card = acard

				if use.to then use.to:append(friend) end
				return
	end
end

sgs.ai_use_priority["#zjaojiaol"] = 4.2
sgs.ai_card_intention["#zjaojiaol"] = -100

sgs.dynamic_value.benefit["#zjaojiaol"] = true

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|zjaojiaol"

sgs.ai_skill_choice["puzou"] = function(self, choices, data)
	self.friends = self:sort(self.friends, "hp")
	self.enemies = self:sort(self.enemies, "hp")
	local up = 0
	local down = 0

	for _, friend in ipairs(self.friends) do
		down = down - 10
		up = up + (__htms_value_call(friend,"isWounded") and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, friend) then
			down = down - 5
			if __htms_value_call(friend,"isWounded") then up = up + 5 end
		end
		if self:needToLoseHp(friend, nil, nil, true) then down = down + 5 end
		if self:needToLoseHp(friend, nil, nil, true, true) and __htms_value_call(friend,"isWounded") then up = up - 5 end

		if self:isWeak(friend) then
			if __htms_value_call(friend,"isWounded") then up = up + 10 + (__htms_value_call(friend,"isLord") and 20 or 0) end
			down = down - 10 - (__htms_value_call(friend,"isLord") and 40 or 0)
			if __htms_value_call(friend,"getHp") <= 1 and not __htms_value_call(friend,"hasSkill","buqu") or friend:getPile("trauma"):length() > 4 then
				down = down - 20 - (__htms_value_call(friend,"isLord") and 40 or 0)
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		down = down + 10
		up = up - (__htms_value_call(enemy,"isWounded") and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, enemy) then
			down = down + 10
			if __htms_value_call(enemy,"isWounded") then up = up - 10 end
		end
		if self:needToLoseHp(enemy, nil, nil, true) then down = down - 5 end
		if self:needToLoseHp(enemy, nil, nil, true, true) and __htms_value_call(enemy,"isWounded") then up = up - 5 end

		if self:isWeak(enemy) then
			if __htms_value_call(enemy,"isWounded") then up = up - 10 end
			down = down + 10
			if __htms_value_call(enemy,"getHp") <= 1 and not __htms_value_call(enemy,"hasSkill","buqu") then
				down = down + 10 + ((__htms_value_call(enemy,"isLord") and #self.enemies > 1) and 20 or 0)
			end
		end
	end

	if down > 0 then
		return "puzou_losehp"
	elseif up > 0 then
		return "puzou_heal"
	end
	return "cancel"
end

sgs.bad_skills = sgs.bad_skills .."|bieniu"

sgs.ai_skill_choice.htms_weiyi = function(self,choices,data)
	local target = data:toDamage().from
	if self:isEnemy(target) and self:doDisCard(target, "he") and __htms_value_call(self.player,"getMark","@wysh") > 0 then
		return "htms_weiyi:qp"
	end
	if self:isEnemy(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) and not self:cantbeHurt(target) and __htms_value_call(self.player,"getMark","@wyqp") > 0 and self:canDamage(target,self.player,nil) then
		return "htms_weiyi:sh"
	end
	if self:isEnemy(target) and self:doDisCard(target, "he") then
		return "htms_weiyi:qp"
	end
	if self:isFriend(target) and self:doDisCard(target, "he") and __htms_value_call(self.player,"getMark","@wysh") == 0 then
		return "htms_weiyi:qp"
	end
	if self:isFriend(target) and ((self:needToLoseHp(target, self.player, nil) and __htms_value_call(self.player,"getMark","@wyqp") > 0) or __htms_value_call(self.player,"getMark","@wyqp")==0) then
		return "htms_weiyi:sh"
	end
	return "cancel"
end



sgs.ai_skill_cardask["lualushouC"] = function(self, data, pattern, target)
	local use = data:toCardUse()
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end

	local effective = false
	local hit = false
	for _,p in sgs.qlist(use.to) do
		if  self:slashIsEffective(data:toCardUse().card, p)  then effective = true end
		if getCardsNum("Jink", p, self.player) > 0 then hit = true end
		if p:isKongcheng() or self:canLiegong(p, self.player) then hit = true  end

	end

	if  __htms_value_call(self.player,"getHp") >= getBestHp(self.player) then return "." end
	if hit and effective then
		for _, c in ipairs(cards) do
			if __htms_value_call(c,"isKindOf","EquipCard") then
				return "$" .. __htms_value_call(c,"getEffectiveId")
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["lualushouB"] = function(self, data, pattern, target)
	local use = data:toCardUse()
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local should = false
	local available_targets = AIList.new({})
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if (use.to:contains(p) or self.room:isProhibited(self.player, p, use.card)) then continue end
			if (self:cardTargetFilter(use.card,AIList.new({}),p)) then
				available_targets:append(p)
			end
		end
	if sgs.ai_skill_playerchosen.zero_card_as_slash(self, available_targets) ~= nil then
		should = true
	end
	if  should then
		for _, c in ipairs(cards) do
			if __htms_value_call(c,"isKindOf","TrickCard") then
				return "$" .. __htms_value_call(c,"getEffectiveId")
			end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.lualushou = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end
sgs.ai_skill_cardask["lualushouA"] = function(self, data, pattern, target)
	local use = data:toCardUse()
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local effective = false
	local should = false
	for _,p in sgs.qlist(use.to) do
		if  self:slashIsEffective(data:toCardUse().card, p)  then effective = true end
		if getCardsNum("Jink", p, self.player) > 0 and getCardsNum("Jink", p, self.player) < 2 then should = true end
	end

	if should and effective then
		for _, c in ipairs(cards) do
			if __htms_value_call(c,"isKindOf","BasicCard") and not __htms_value_call(c,"isKindOf","Peach") then
				return "$" .. __htms_value_call(c,"getEffectiveId")
			end
		end
	end
	return "."
end
sgs.hit_skill = sgs.hit_skill .. "|lualushou"
sgs.ai_cardneed.lualushou = sgs.ai_cardneed.slash



sgs.ai_skill_invoke.huazang = function(self, data)
	local use = data:toCardUse()
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) and not __htms_value_call(p,"faceUp") then
			return true
		end
		if not self:toTurnOver(p, __htms_value_call(p,"getLostHp"), "huazang") then
			return true
		end
		if self:isEnemy(p) and self:toTurnOver(p, __htms_value_call(p,"getLostHp"), "huazang") then
			return true
		end
	end
	return false
end

sgs.ai_cardneed.huazang = sgs.ai_cardneed.slash





sgs.ai_fill_skill["zchize"] = function(self,inclusive,request)
	self.enemies = self:sort(self.enemies, "handcard")
	if __htms_value_call(self.player,"getHandcardNum") < 2  then return false end
	for _, enemy in ipairs(self.enemies) do
	    if not enemy:isKongcheng() then
			return policy(self,"#zchizeCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#zchizeCard"]=function(card, use, self)
    local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByUseValue(cards,true)
	self.enemies = self:sort(self.enemies, "handcard")
	local target
	for _, enemy in ipairs(self.enemies) do
		if __htms_value_call(self.player,"canPindian",enemy) and not (enemy:getEquips():length() > 0 and enemy:hasSkills(sgs.lose_equip_skill))
		and not (enemy:getJudgingArea():length() > 0 and enemy:getEquips():length() == 0) then
			target = enemy
			break
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if __htms_value_call(self.player,"canPindian",enemy) then
				target = enemy
				break
			end
		end
	end
	cards = self:sortByKeepValue(cards)
	if not target then return end
	for _, card in ipairs(cards) do
		if not __htms_value_call(card,"isKindOf","Peach") and not __htms_value_call(card,"isKindOf","ExNihilo") and not __htms_value_call(card,"isKindOf","Jink") and self:getKeepValue(card) < 6 then
			use.card = policy(self,"#zchizeCard:"..card:getId()..":")
			if use.to and target then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_card_intention["zchizeCard"] = 80




sgs.ai_skill_invoke.gaoling = function(self, data)
	local effect = data:toCardEffect()

		if self:isEnemy(effect.from) or (self:isFriend(effect.from) and self.role == "loyalist" and not __htms_value_call(effect.from,"hasSkill","jueqing") and __htms_value_call(effect.from,"isLord") and __htms_value_call(self.player,"getHp") == 1) then
			if __htms_value_call(effect.card,"isKindOf","AOE") then
				local from = effect.from
				if __htms_value_call(effect.card,"isKindOf","SavageAssault") then
					local menghuo = self.room:findPlayerBySkillName("huoshou")
					if menghuo then from = menghuo end
				end

				if self:hasTrickEffective(effect.card, self.player, from) then
				if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then
				if __htms_value_call(effect.from,"hasSkill","drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then return true end

					if self:isEnemy(from) and __htms_value_call(from,"hasSkill","jueqing") then return true end
					if self:isFriend(from) and self.role == "loyalist" and __htms_value_call(from,"isLord") and __htms_value_call(self.player,"getHp") == 1 and not __htms_value_call(from,"hasSkill","jueqing") then return true end
					if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or __htms_value_call(effect.from,"hasSkill","jueqing"))  then
						return true
					end
					end
				end
			elseif self:isEnemy(effect.from) then
				if __htms_value_call(effect.card,"isKindOf","FireAttack")  then
						if  self:hasTrickEffective(effect.card, self.player) then
					if  self:damageIsEffective(self.player, sgs.DamageStruct_Fire, effect.from) then
					if (self.player:hasArmorEffect("vine") or __htms_value_call(self.player,"getMark","@gale") > 0) and __htms_value_call(effect.from,"getHandcardNum") > 3
						and not (__htms_value_call(effect.from,"hasSkill","hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
						return true
					elseif self.player:isChained() and not self:isGoodChainTarget(self.player, effect.from) then
						return true
					end
					end
					end
				elseif (__htms_value_call(effect.card,"isKindOf","Snatch") or __htms_value_call(effect.card,"isKindOf","Dismantlement"))
						 and not self.player:isKongcheng() then
					if  self:hasTrickEffective(effect.card, self.player) then
					return true
					end
				elseif __htms_value_call(effect.card,"isKindOf","Duel") then
					if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", effect.from, self.player) then
						if self:hasTrickEffective(effect.card, self.player) then
						if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, effect.from) then
						return true
						end
						end
					end
				end
			end
	end
	return false
end
sgs.ai_target_revises.gaoling = function(to,card,self)
	return card:isNDTrick() and __htms_value_call(self.player,"getHandcardNum") <= __htms_value_call(to,"getHandcardNum") and not self:beFriend(to, self.player)
end

sgs.ai_skill_invoke.zhengjiu = function(self, data)
	local use = data:toCardUse()
	if use and use.card then
		return true
	end
	return sgs.ai_skill_playerchosen.zhengjiu(self, self.room:getOtherPlayers(self.player)) ~= nil
end
sgs.ai_skill_playerchosen.zhengjiu = function(self, targets)
	self.friends_noself = self:sort(self.friends_noself, "defense")
	for _,friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			return friend
		end
	end
	for _,friend in ipairs(self.friends_noself) do
		return friend
	end
	return nil
end




sgs.ai_fill_skill["molwf"] = function(self,inclusive,request)
	if self:needBear() then return end
	if not self.player:hasUsed("#molwf")  then
		return policy(self,"#molwf:.:")
	end
end

sgs.ai_skill_use_func["#molwf"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local use_cards
	cards = self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if  card:isRed() and  not __htms_value_call(card,"isKindOf","Slash") 	and not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash  or residue(self,clone(self,"slash")) > 0)
			and not (__htms_value_call(card,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			use_cards = card
			break
		end
	end
	if slashcount > 0 and use_cards  then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = self:aiUseCard(slash, dummy_plan())
		if not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				if not (__htms_value_call(p,"hasSkill","kongcheng") and __htms_value_call(p,"getHandcardNum") == 0) and  (getCardsNum("Peach", p, self.player) == 0  or self:canLiegong(p, self.player))
				and self:canAttack(p, self.player)
				and not self:canLiuli(p, self.friends_noself) and not self:findLeijiTarget(p, 50, self.player) then
					use.card = policy(self,"#molwf:"..__htms_value_call(use_cards,"getEffectiveId")..":")
					return

				end
			end
		end
	end

end

sgs.ai_use_priority["molwf"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_ajustdamage_from.molwf = function(self, from, to, card, nature)
	if card and __htms_value_call(card,"isKindOf","Slash") and __htms_value_call(from,"hasFlag","moli")
	then
		return 1
	end
end
sgs.ai_cardneed.molwf = sgs.ai_cardneed.slash


sgs.ai_fill_skill["html_shisheng"] = function(self,inclusive,request)
	if __htms_value_call(self.player,"getMark","@shisheng") > 0 then
		return policy(self,"#html_shishengCard:.:")
	end
end

sgs.ai_skill_use_func["#html_shishengCard"] = function(card, use, self)
		self.enemies = self:sort(self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and self:canDamage(enemy,self.player,nil) then
				if __htms_value_call(enemy,"getHp") == 1 and getCardsNum("Peach", enemy, self.player) == 0 then
					use.card = policy(self,"#html_shishengCard:.:")
					if use.to then
						use.to:append(enemy)
					end
					return
				end
			end
		end
end

sgs.ai_use_value["#html_shishengCard"] = 2.5
sgs.ai_card_intention["#html_shishengCard"] = 80
sgs.dynamic_value.damage_card["#html_shishengCard"] = true

sgs.straight_damage_skill = sgs.straight_damage_skill .. "|html_shisheng"



sgs.ai_fill_skill["ujyaozhan"] = function(self,inclusive,request)
	if self.player:hasUsed("#ujyaozhanCard") then return end
	return policy(self,"#ujyaozhanCard:.:")
end

sgs.ai_skill_use_func["#ujyaozhanCard"] = function(card, use, self)

	local canleiji
	if self:findLeijiTarget(self.player, 50)
		and ((__htms_value_call(self.player,"hasSkill","leiji") and self:hasSuit("spade", true))
			or (__htms_value_call(self.player,"hasSkill","nosleiji") and self:hasSuit("black", true))) then
		canleiji = true
		self.friends_noself = self:sort(self.friends_noself, "handcard")
		self.friends_noself = sgs.reverse(self.friends_noself)
		for _, friend in ipairs(self.friends_noself) do
			if not friend:isKongcheng() and (self:getCardsNum("Jink") > 0 or (not friend:hasWeapon("qinggang_sword") and not self:isWeak() and self:hasEightDiagramEffect())) then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if  (self:needToLoseHp(self.player, enemy)) then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end

	local second, third, fourth
	local slash = self:getCard("Slash")
	local slash_nosuit = clone(self,"slash")
	slash_nosuit:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if __htms_value_call(enemy,"getHandcardNum") > 0 then
			if not self:slashIsEffective(slash_nosuit, self.player, enemy) and self:getCardsNum("Slash") > getCardsNum("Slash", enemy) and not second then
				second = enemy
			elseif not enemy:hasSkills("wushuang|mengjin|tieji|nostieji")
				and not ((__htms_value_call(enemy,"hasSkill","roulin") or enemy:hasWeapon("double_sword")) and __htms_value_call(enemy,"getGender") ~= __htms_value_call(self.player,"getGender")) then

				if slash and not third and __htms_value_call(self.player,"inMyAttackRange",enemy)
					and (self:hasHeavyDamage(self.player, slash, enemy) or self.player:hasWeapon("guding_blade") and not self:needKongcheng(enemy))
					and (not self:isWeak() or self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0) then
					third = enemy
				elseif self:getCardsNum("Jink") > 0 and self:getCardsNum("Slash") > getCardsNum("Slash", enemy) and not fourth then
					fourth = enemy
				end
			end
		end
	end

	local target
	if canleiji then
		target = fourth and third or second
	else
		target = second or third or fourth
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end

end

sgs.ai_use_priority["ujyaozhanCard"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_cardneed.ujyaozhan = sgs.ai_cardneed.slash
sgs.ai_cardneed.ujzhongshi = sgs.ai_cardneed.slash
sgs.ai_cardneed.ujlianji = sgs.ai_cardneed.slash
sgs.ai_cardneed.ujlianjig = sgs.ai_cardneed.slash




sgs.ai_skill_choice.Sdorica_FuWei = function(self, choices)
local items = choices:split("+")
	if self.room:getCurrent() and self:isFriend(self.room:getCurrent()) and  self.room:getCurrent():getJudgingArea():length() > 0 and not self.room:getCurrent():containsTrick("YanxiaoCard")
	and table.contains(items, "fwdiscard&put") then
		return "fwdiscard&put"
	end
	return "cancel"
end

sgs.ai_skill_discard.Sdorica_FuWei = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards, true)
	local stealer
	for _, ap in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if ap:hasSkills("tuxi|nostuxi") and self:isEnemy(ap) then stealer = ap end
	end
	local card
	for i=1, #cards, 1 do
		local isPeach = cards[i]:isKindOf("Peach")
		if isPeach then
			if stealer and self:isEnemy(stealer) and __htms_value_call(self.player,"getHandcardNum")<=2 and __htms_value_call(self.player,"getHp") > 2
			and (not stealer:containsTrick("supply_shortage") or stealer:containsTrick("YanxiaoCard")) then
				card = cards[i]
				break
			end
			local to_discard_peach = true
			for _,fd in ipairs(self.friends) do
				if __htms_value_call(fd,"getHp")<=2 and not __htms_value_call(fd,"hasSkill","niepan") then
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
	table.insert(to_discard, __htms_value_call(card,"getEffectiveId"))
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		if not current:containsTrick("YanxiaoCard") then
			if (current:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies))
				or (current:containsTrick("lightning") and #self.friends > #self.enemies) then
				return to_discard
			elseif current:containsTrick("supply_shortage") then
				if __htms_value_call(self.player,"getHp") > __htms_value_call(self.player,"getHandcardNum") then return to_discard end
			elseif current:containsTrick("indulgence") then
				if __htms_value_call(self.player,"getHandcardNum") > 3 or __htms_value_call(self.player,"getHandcardNum") > __htms_value_call(self.player,"getHp") - 1 then return to_discard end
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


sgs.ai_fill_skill["Sdorica_MiLing"] = function(self,inclusive,request)
	if self.player:hasUsed("#Sdorica_MiLingCard") then return nil end
	if self.player:isKongcheng() then return nil end
	return policy(self,"#Sdorica_MiLingCard:.:")
end

sgs.ai_skill_use_func["#Sdorica_MiLingCard"] = function(card, use, self)

	for _, friend in ipairs(self.friends) do
		if self:isWeak(friend) and __htms_value_call(friend,"getMark","@Immunity") == 0 then
			local card_str = "#Sdorica_MiLingCard:.:"
				local acard = policy(self,card_str)
				use.card = acard

				if use.to then use.to:append(friend) end
				return
		end
	end
	local AssistTarget = self:AssistTarget()
	local friend
	if AssistTarget and __htms_value_call(AssistTarget,"getMark","@Immunity") == 0  then
		friend = AssistTarget
	else
		friend = self.friends_noself[1]
	end
		if friend then
				local card_str = "#Sdorica_MiLingCard:.:"
				local acard = policy(self,card_str)
				use.card = acard

				if use.to then use.to:append(friend) end
				return
	end
end

sgs.ai_use_priority["#Sdorica_MiLingCard"] = 4.2
sgs.ai_card_intention["#Sdorica_MiLingCard"] = -100

sgs.dynamic_value.benefit["#Sdorica_MiLingCard"] = true

sgs.ai_fill_skill["void"] = function(self,inclusive,request)
	if __htms_value_call(self.player,"getMark","voidcanuse")- __htms_value_call(self.player,"getMark","voidused") >= 0 then
		return policy(self,"#void:.:")
	end
end

sgs.ai_skill_use_func["#void"] = function(card, use, self)
	local names = fact(self,"voidtarget"):split("+")
	self.friends_noself = self:sort(self.friends_noself, "handcard")
	self.enemies = self:sort(self.enemies, "handcard")
	local targets = {}
	local voidfriend, voidenemey = 0,0
		for i=1, #names, 1 do
			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:objectName()==names[i] then
					table.insert(targets, p)
					if self:isFriend(p) then
						voidfriend = voidfriend + 1
					end
					if self:isEnemy(p) then
						voidenemey = voidenemey + 1
					end
				end
			end
		end
	if (voidenemey >= voidfriend) then
		for _, friend in ipairs(self.friends_noself) do
			if not friend:isKongcheng() and not table.contains(targets, friend) then
				local card_str = "#void:.:"
					local acard = policy(self,card_str)
					use.card = acard

					if use.to then use.to:append(friend) end
					return
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and not table.contains(targets, enemy) then
				local card_str = "#void:.:"
					local acard = policy(self,card_str)
					use.card = acard

					if use.to then use.to:append(enemy) end
					return
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and not table.contains(targets, enemy) then
				local card_str = "#void:.:"
					local acard = policy(self,card_str)
					use.card = acard

					if use.to then use.to:append(enemy) end
					return
			end
		end
	end
end

sgs.ai_use_priority["void"] = 7

sgs.ai_card_priority.void = function(self,card)
	if card and __htms_value_call(card,"hasFlag","void-Clear") then
		local idlist = fact(self,"voidid"):split("+")
		local names = fact(self,"voidtarget"):split("+")
		for i=1, #idlist, 1 do
			local target
			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:objectName()==names[i] then target = p end
			end
			if target and visible(self,tonumber(idlist[i])) == card then
				if self:isFriend(target) then
                    return -5
                else
                    return 10
                end
			end
		end
		return 0
	end
end

sgs.ai_skill_choice.wangguo = function(self, choices)
local items = choices:split("+")
local current = self.room:getCurrent()
	if current then
		if self:isFriend(current) and table.contains(items, "oumashu_recover") then
			return "oumashu_recover"
		elseif  table.contains(items, "oumashu_lose") then
			return "oumashu_lose"
		end
	end
	return items[math.random(1,#items)]
end

sgs.ai_skill_invoke.lsqd = function(self, data)
	return true
end

sgs.ai_skill_choice.lsqd = function(self, choices)
local items = choices:split("+")
		if not self.player:getWeapon() and table.contains(items, "lsqd:qp") then
			local list=AIList.new({})
			for _,id in sgs.qlist(self.room:getDiscardPile()) do
				if  visible(self,id):isKindOf("Weapon") then
					list:append(id)
				end
			end
		   if list:length()>0 then
			return "lsqd:qp"
			end
		end
		if  self.player:getWeapon() and table.contains(items, "lsqd:kd") then
			return "lsqd:kd"
		end
	return "lsqd:kd"
end
sgs.ai_skill_cardask["@lsqd"] = function(self,data)
	local id,cards = nil,{}
	if self:needToThrowArmor() and self.player:canDiscard(self.player,self.player:getArmor():getEffectiveId()) then
		id = self.player:getArmor():getEffectiveId()
	else
		for _,c in sgs.qlist(self.player:getCards("he"))do
			if self.player:canDiscard(self.player,__htms_value_call(c,"getEffectiveId")) then
				table.insert(cards,c)
			end
		end
		if #cards<=0 then return "." end
		cards = self:sortByKeepValue(cards)
		id = __htms_value_call(cards[1],"getEffectiveId")
	end

	if not id then return "." end
end


sgs.ai_skill_playerchosen.tscg = function(self, targets)
	return sgs.ai_skill_playerchosen.damage(self, targets)
end

sgs.ai_fill_skill["wzgz"] = function(self,inclusive,request)
	if not self.player:hasUsed("#wzgzcard") then
		return policy(self,"#wzgzcard:.:")
	end
end

sgs.ai_skill_use_func["#wzgzcard"] = function(card, use, self)

		self.enemies = self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if  self:doDisCard(enemy, "e") and enemy:getWeapon() then

					use.card = policy(self,"#wzgzcard:.:")
					if use.to then
						use.to:append(enemy)
					end
					return

			end
		end
		for _, enemy in ipairs(self.enemies) do
			if   self:doDisCard(enemy, "e") and enemy:getEquips():length() > 0 then

					use.card = policy(self,"#wzgzcard:.:")
					if use.to then
						use.to:append(enemy)
					end
					return

			end
		end
		for _, friend in ipairs(self.friends) do
			if self:isFriend(friend) and ((friend:hasSkills(sgs.lose_equip_skill) and friend:getEquips():length() > 0) or self:needToThrowArmor(friend)) then
					use.card = policy(self,"#wzgzcard:.:")
					if use.to then
						use.to:append(friend)
					end
					return end
		end
end

sgs.ai_use_value["#wzgzcard"] = 2.5
sgs.ai_card_intention["#wzgzcard"] = 80




sgs.ai_ajustdamage_from.tcmfs = function(self, from, to, card, nature)
	if card and __htms_value_call(card,"isKindOf","TrickCard") and card:isRed() and __htms_value_call(from,"getMark","@tcmfs") == 1 and not self:beFriend(to, from)
	then
		return 1
	end
end

sgs.ai_skill_discard.tcmfs = function(self,max, min,optional,include_equip)
	local damage = room_tag(self,"tcmfs","Damage")
	if not damage.to or __htms_value_call(damage.to,"isDead") or not self:isEnemy(damage.to) or self:cantDamageMore(self.player,damage.to) then return {} end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	local compare_func = function(a,b)
		return self:getKeepValue(a)<self:getKeepValue(b)
	end
	table.sort(cards,compare_func)
	for _,card in sgs.list(cards)do
		if #to_discard>=min then break end
		table.insert(to_discard,card:getId())
	end
	return to_discard
end

sgs.ai_cardneed.blmf = function(to,card,self)
	return __htms_value_call(card,"isKindOf","BasicCard") and card:isRed()
end
sgs.ai_cardneed.tcmfs = function(to,card,self)
	return __htms_value_call(card,"isKindOf","TrickCard") and card:isRed() and __htms_value_call(card,"isDamageCard")
end


sgs.ai_fill_skill["blmf"] = function(self,inclusive,request)
   if #self.enemies < 1 then return end
	self.enemies = self:sort(self.enemies, "hp")

	local card

	local cards = self.player:getHandcards()
    cards=sgs.QList2Table(cards)
    cards = self:sortByKeepValue(cards)

	for _,acard in ipairs(cards)  do
		if (__htms_value_call(acard,"isKindOf","BasicCard") and not __htms_value_call(acard,"isKindOf","Peach")	 )  then
			card = acard
			break
		end
	end

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if visible(self,id):isKindOf("BasicCard")  and not visible(self,id):isKindOf("Peach")	then
				card = visible(self,id)
			end
		end
	end

	if not card then return nil end

	local suit = __htms_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __htms_value_call(card,"getEffectiveId")
	local card_str = ("fire_attack:blmf[%s:%s]=%d"):format(suit, number, card_id)
	return policy(self,card_str)
end

sgs.ai_ajustdamage_from.blmf = function(self, from, to, card, nature)
	if card and table.contains(card:getSkillNames(), "blmf")
	then
		return 1
	end
end


















sgs.ai_skill_playerchosen.pomiehb = function(self, targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isFriend(target) and not  hasManjuanEffect(target) and self:canDraw(target, self.player) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target)  and self:canDraw(target, self.player) then return target end
	end
	return nil
end
sgs.ai_playerchosen_intention.pomiehb = function(self, from, to)
		self:updateIntention(from, to, -50)
end

sgs.ai_skill_invoke.yiban = function(self, data)
	local yiban_string = sgs.ai_skill_use["@@yiban"](self, prompt, method)
	if yiban_string == "." then
		return false
	end
	return true
end

function SmartAIView:shouldUseYiban()
	if (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0) and self:getCardsNum("Slash") > 0 then
		self.enemies = self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			local inAttackRange = __htms_value_call(self.player,"distanceTo",enemy) == 1 or __htms_value_call(self.player,"distanceTo",enemy) == 2
									and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse()
			if inAttackRange and self:isGoodTarget(enemy, self.enemies, nil) then
				local slashs = self:getCards("Slash")
				local slash_count = 0
				for _, slash in ipairs(slashs) do
					if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) then
						slash_count = slash_count + 1
					end
				end
				if slash_count >= __htms_value_call(enemy,"getHp") then return false end
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:canSlash(self.player) and not self:slashProhibit(nil, self.player, enemy) then
			if enemy:hasWeapon("guding_blade") and __htms_value_call(self.player,"getHandcardNum") == 1 and getCardsNum("Slash", enemy) >= 1 then
				return false
			elseif self:hasCrossbowEffect(enemy) and getCardsNum("Slash", enemy) > 1 and self:getOverflow() <= 0 then
				return false
			end
		end
	end
	for _, player in ipairs(self.friends_noself) do
		if (__htms_value_call(player,"hasSkill","haoshi") and not player:containsTrick("supply_shortage")) or __htms_value_call(player,"hasSkill","jijiu") then
			return true
		end
	end
	local keepNum = 1

	if __htms_value_call(self.player,"hasSkill","kongcheng") then
		keepNum = 0
	end
	if self:getOverflow() > 0 then
		return true
	end
	if __htms_value_call(self.player,"getHandcardNum") > keepNum  then
		return true
	end
end

sgs.ai_skill_use["@@yiban"]=function(self,prompt)

	if self:getOverflow() <= 0 then return "." end

	if self:shouldUseYiban() then
		local cards = sgs.QList2Table(self.player:getHandcards())
		cards = self:sortByUseValue(cards, true)

		local notFound
		for i = 1, #cards do
			local card, friend = self:getCardNeedPlayer(cards)
			if card and friend then
				cards = self:resetCards(cards, card)
			else
				notFound = true
				break
			end

			if friend:objectName() == self.player:objectName() or not self.player:getHandcards():contains(card) then continue end
			if __htms_value_call(card,"isAvailable",self.player) and ((__htms_value_call(card,"isKindOf","Slash")) or __htms_value_call(card,"isKindOf","Duel") or __htms_value_call(card,"isKindOf","Snatch") or __htms_value_call(card,"isKindOf","Dismantlement")) then
				local dummy_use = self:aiUseCard(card, dummy_plan())
				if dummy_use.card and dummy_use.to:length() > 0 then
					if __htms_value_call(card,"isKindOf","Slash") or __htms_value_call(card,"isKindOf","Duel") then
						local t1 = dummy_use.to:first()
						if dummy_use.to:length() > 1 then continue
						elseif __htms_value_call(t1,"getHp") == 1 or getCardsNum("Jink", t1, self.player) < 1
								or t1:isCardLimited(clone(self,"jink"), sgs.Card_MethodResponse) then continue
						end
					elseif (__htms_value_call(card,"isKindOf","Snatch") or __htms_value_call(card,"isKindOf","Dismantlement")) and self:getEnemyNumBySeat(self.player, friend) > 0 then
						local hasDelayedTrick
						for _, p in sgs.qlist(dummy_use.to) do
							if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p)) then hasDelayedTrick = true break end
						end
						if hasDelayedTrick then continue end
					end
				end
			elseif __htms_value_call(card,"isAvailable",self.player) and self:getEnemyNumBySeat(self.player, friend) > 0 and (__htms_value_call(card,"isKindOf","Indulgence") or __htms_value_call(card,"isKindOf","SupplyShortage")) then
				local dummy_use = self:aiUseCard(card, dummy_plan())
				if dummy_use.card then continue end
			end

			if  #cards >= 1  then
				return  "#yiban:" .. card:getId() .. "+" .. cards[1]:getId()..":->".. friend:objectName()
			else
				return "#yiban:" .. card:getId()..":->".. friend:objectName()
			end
		end

	end
	return "."
end
sgs.ai_card_intention["#yiban"] = function(self,card, from, tos)
	local to = tos[1]
	local intention = -70
	if hasManjuanEffect(to) then
		intention = 0
	elseif __htms_value_call(to,"hasSkill","kongcheng") and to:isKongcheng() then
		intention = 30
	end
	self:updateIntention(from, to, intention)
end





sgs.ai_skill_playerchosen.tonghh = function(self, targets)
	if viewer_role(self,self.player) == "loyalist" then
		return self.room:getLord()
	end
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if viewer_role(self,self.player) == "lord" and viewer_role(self,p) == "loyalist" then
			return p
		end
	end
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if viewer_role(self,self.player) == viewer_role(self,p) then
			return p
		end
	end
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		return p
	end
	targets = sgs.QList2Table(targets)
	return targets[1]
end
sgs.ai_card_priority.zhumyb = function(self,card,v)
	if __htms_value_call(card,"getNumber") > __htms_value_call(self.player,"getMark","mengyb") and not __htms_value_call(self.player,"hasFlag","zhumyb1")
	then return 10 end
end


sgs.ai_skill_playerchosen.luashouhuo = function(self, targets)
	local friends = {}
	for _, player in ipairs(self.friends) do
		if player:isAlive() and not hasManjuanEffect(player) then
			table.insert(friends, player)
		end
	end
	friends = self:sort(friends)

	local max_x = 0
	local target
	local Shenfen_user
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if __htms_value_call(player,"hasFlag","ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	if Shenfen_user then
		local y, weak_friend = 3
		for _, friend in ipairs(friends) do
			local x = __htms_value_call(friend,"getMaxCards") - __htms_value_call(friend,"getHandcardNum")
			if hasManjuanEffect(friend) and x > 0 then x = x + 1 end
			if x > max_x and friend:isAlive() then
				max_x = x
				target = friend
			end

			if self:playerGetRound(friend, Shenfen_user) > self:playerGetRound(self.player, Shenfen_user) and x >= y
				and __htms_value_call(friend,"getHp") == 1 and getCardsNum("Peach", friend, self.player) < 1 then
				y = x
				weak_friend = friend
			end
		end

		if weak_friend and ((getCardsNum("Peach", Shenfen_user, self.player) < 1) or (math.min(__htms_value_call(Shenfen_user,"getMaxHp"), 5) - __htms_value_call(Shenfen_user,"getHandcardNum") <= 1)) then
			return weak_friend
		end
		if self:isFriend(Shenfen_user) and math.min(__htms_value_call(Shenfen_user,"getMaxHp"), 5) > __htms_value_call(Shenfen_user,"getHandcardNum") then
			return Shenfen_user
		end
		if target then return target end
	end

	local CP = self.room:getCurrent()
	local max_x = 0
	local AssistTarget = self:AssistTarget()
	for _, friend in ipairs(friends) do
		local x = __htms_value_call(friend,"getMaxCards") - __htms_value_call(friend,"getHandcardNum")
		if hasManjuanEffect(friend) then x = x + 1 end
		if self:hasCrossbowEffect(CP) then x = x + 1 end
		if AssistTarget and friend:objectName() == AssistTarget:objectName() then x = x + 0.5 end

		if x > max_x and friend:isAlive() then
			max_x = x
			target = friend
		end
	end
	if max_x > 1 then
	return target
	end
	return nil
end

sgs.ai_playerchosen_intention.luashouhuo = function(self, from, to)
	if __htms_value_call(to,"getHandcardNum") < __htms_value_call(to,"getMaxCards") then
		self:updateIntention(from, to, -80)
	end
end





sgs.ai_skill_playerchosen.luahongyu = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _,target in sgs.list(targets)do
		if target:isAlive() and not self:isFriend(target) and self:canDraw(target, self.player) then
			return target
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention.luahongyu = function(self, from, to)
	if not hasManjuanEffect(to) then
		self:updateIntention(from, to, -80)
	end
end

sgs.ai_skill_invoke.pinkdevil = function(self, data)
	local targets=AIList.new({})
	local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if not self.player:isProhibited(p,slash) and self.player:canSlash(p,slash, false)  then
			targets:append(p)
        end
    end
	if targets:length()==0 then return false end

	local pinkdevil = sgs.ai_skill_playerchosen.pinkdevil(self, targets)
	if pinkdevil == nil then
		return false
	end
	return true
end
sgs.ai_skill_playerchosen.pinkdevil = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end
sgs.ai_ajustdamage_from.khztbuff = function(self, from, to, card, nature)
	if card and (__htms_value_call(card,"isKindOf","Slash") or __htms_value_call(card,"isKindOf","Duel")) and (__htms_value_call(from,"getLostHp") >  0) and  (from:getEquips():length() > 0)
	then
		return 1
	end
end

sgs.ai_cardneed.khztbuff = sgs.ai_cardneed.slash



sgs.ai_skill_playerchosen.gxzhiliao = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and __htms_value_call(arr1[1],"getHp") < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return	target
	end
	if  #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				return friend
			end
		end
	end
	for _, friend in ipairs(self.friends) do
		if __htms_value_call(friend,"getMark","@hurt") > 0  then
			return friend
		end
	end

	return nil
end

sgs.ai_playerchosen_intention.gxzhiliao = function(self, from, to)
	if __htms_value_call(to,"getHp") < getBestHp(to) then
		self:updateIntention(from, to, -80)
	end
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|gxzhiliao"

sgs.ai_skill_playerchosen.shenpan = function(self, targets)
	local target = self:findPlayerToDamage(1, self.player, "N", targets, 5)[1]
	return target
end

sgs.ai_skill_invoke.shenpan = function(self, data)
	local n = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		n = math.max(n, __htms_value_call(p,"getHp"))
	end
	local targets = AIList.new({})
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if __htms_value_call(p,"getHp") == n then
			targets:append(p)
		end
	end
	if targets:isEmpty() then return false end
	local target = self:findPlayerToDamage(1, self.player, "N", targets, 5)[1]
	if target then return true end
	return false
end
sgs.straight_damage_skill = sgs.straight_damage_skill .. "|shenpan"

sgs.ai_skill_invoke.nxlieren = function(self, data)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local shouldUse, range_fix = 0, 0
	local hasCrossbow, slashTo = false, false
	for _, card in ipairs(cards) do
		if __htms_value_call(card,"isKindOf","TrickCard") and self:getUseValue(card) > 3.69 then
			local dummy_use = self:aiUseCard(card, dummy_plan())
			if dummy_use.card then shouldUse = shouldUse + (__htms_value_call(card,"isKindOf","ExNihilo") and 2 or 1) end
		end
		if __htms_value_call(card,"isKindOf","Weapon") then
			local new_range = sgs.weapon_range[__htms_value_call(card,"getClassName")] or 0
			local current_range = __htms_value_call(self.player,"getAttackRange")
			range_fix = math.min(current_range - new_range, 0)
		end
		if __htms_value_call(card,"isKindOf","OffensiveHorse") and not self.player:getOffensiveHorse() then range_fix = range_fix - 1 end
		if __htms_value_call(card,"isKindOf","DefensiveHorse") or __htms_value_call(card,"isKindOf","Armor") and not self:getSameEquip(card) and (self:isWeak() or self:getCardsNum("Jink") == 0) then shouldUse = shouldUse + 1 end
		if __htms_value_call(card,"isKindOf","Crossbow") or self:hasCrossbowEffect() then hasCrossbow = true end
	end

	local slashs = self:getCards("Slash")
	for _, enemy in ipairs(self.enemies) do
		for _, slash in ipairs(slashs) do
			if hasCrossbow and self:getCardsNum("Slash") > 1 and self:slashIsEffective(slash, enemy)
				and self.player:canSlash(enemy, slash, true, range_fix) then
				shouldUse = shouldUse + 2
				hasCrossbow = false
				break
			elseif not slashTo and self:slashIsAvailable() and self:slashIsEffective(slash, enemy)
				and self.player:canSlash(enemy, slash, true, range_fix) and getCardsNum("Jink", enemy) < 1 then
				shouldUse = shouldUse + 1
				slashTo = true
			end
		end
	end
	if shouldUse >= 2 then return false end


	return true
end
sgs.ai_skill_invoke.nxlieren_damage = function(self, data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) and not self:cantbeHurt(target) and self:canDamage(target,self.player,nil) and self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) then
		return true
	end

	return false
end


sgs.ai_skill_choice.nxlieren = function(self, choices)
	if __htms_value_call(self.player,"getMark","slash") == 0 then
		return "slash"
		else
			if __htms_value_call(self.player,"getMark","jink") == 0 then
				return "jink"
			else
				if __htms_value_call(self.player,"getMark","peach") == 0 then
					return "peach"
				else
					if __htms_value_call(self.player,"getMark","analeptic") == 0 then
						return "analeptic"
					end
				end
			end
	end
	return "slash"
end

sgs.ai_skill_invoke.zhanshubuju = function(self, data)
	local dest
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if __htms_value_call(aplayer,"hasFlag","zhanshubuju_Target") then dest = aplayer break end
	end
	if not self:isFriend(dest) then return false end
	local isUse = data:toStringList()[3] == "use"
	local use
	if isUse then
		if data:toStringList()[4] then
			use = history_use(self,data:toStringList()[4])
		end
	end

	if dest and __htms_value_call(dest,"hasFlag","dahe") then return false  end
	if isUse then
		if use.card and __htms_value_call(use.card,"hasFlag","NosJiefanUsed") then return false  end
		if not use.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,use.from)
		or __htms_value_call(use.card,"isKindOf","NatureSlash") and dest:isChained() and self:isGoodChainTarget(dest,use.card,use.from)
		or self:needToLoseHp(dest,use.from,use.card) and self:ajustDamage(use.from,dest,1,use.card)==1 then return false end
	end
	if self:needToLoseHp(dest, nil, nil, true) then return false end
	if self:getCardsNum("Jink") == 0 then return true end
	if self:ajustDamage(nil,dest,1,nil)>1 then return true end
	return true
end


sgs.ai_choicemade_filter.skillInvoke.zhanshubuju = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if __htms_value_call(p,"hasFlag","zhanshubuju_Target") then
			target = p
			break
		end
	end
	if target then
		local intention = 60
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(player, target, -intention)
		end
	end
end

local function getzhachangUseValueOfHECards(self, to)
	local value = 0
	local value_h = 0
	local hcard = __htms_value_call(to,"getHandcardNum")
	if __htms_value_call(to,"hasSkill","lianying") then
		hcard = hcard - 0.9
	elseif to:hasSkills("shangshi|nosshangshi") then
		hcard = hcard - 0.9 * __htms_value_call(to,"getLostHp")
	else
		local jwfy = self.room:findPlayerBySkillName("shoucheng")
		if jwfy and self:isFriend(jwfy, to) and (not self:isWeak(jwfy) or __htms_value_call(jwfy,"getHp") > 1) then hcard = hcard - 0.9 end
	end
	value_h = (hcard > 4) and 16 / hcard or hcard
	if hasTuntianEffect(to, true) then value = value * 0.95 end
	if (__htms_value_call(to,"hasSkill","kongcheng") or (__htms_value_call(to,"hasSkill","zhiji") and __htms_value_call(to,"getHp") > 2 and __htms_value_call(to,"getMark","zhiji") == 0)) and not to:isKongcheng() then value_h = value_h * 0.7 end
	if to:hasSkills("jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|new_longhun|xuanfeng|tianxiang|ol_tianxiang|noslijian|lijian") then value_h = value_h * 0.95 end
	value = value + value_h

	local value_e = 0
	local equip_num = to:getEquips():length()
	if to:hasArmorEffect("silver_lion") and __htms_value_call(to,"isWounded") then equip_num = equip_num - 1.1 end
	value_e = equip_num * 1.1
	if to:hasSkills("kofxiaoji|xiaoji") then value_e = value_e * 0.7 end
	if __htms_value_call(to,"hasSkill","nosxuanfeng") then value_e = value_e * 0.85 end
	if to:hasSkills("bazhen|yizhong") and to:getArmor() then value_e = value_e - 1 end
	value = value + value_e

	return value
end
sgs.ai_fill_skill["zhachang"] = function(self,inclusive,request)
	local list=AIList.new({})
	for _,id in sgs.qlist(private_draw(self)) do
		if  visible(self,id):isKindOf("Jink") and list:length() ~= 1 then
			list:append(id)
		end
	end
	if list:length() == 0 then
		return policy(self,"#zhachang:.:")
	end
end

sgs.ai_skill_use_func["#zhachang"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
		cards = self:sortByKeepValue(cards)
		local willUse
		for _, card in ipairs(cards) do
			if __htms_value_call(card,"isKindOf","Slash") then
			 willUse = card
			 break
			end
		end
		local benefit = 0
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) then benefit = benefit - getzhachangUseValueOfHECards(self, player) end
			if self:isEnemy(player) then benefit = benefit + getzhachangUseValueOfHECards(self, player) end
		end
		if willUse and benefit > 0 then
			use.card = policy(self,"#zhachang:" .. __htms_value_call(willUse,"getEffectiveId")..":")

		end
end


sgs.ai_use_priority["#zhachang"] = sgs.ai_use_priority.Slash + 0.1


sgs.ai_skill_invoke.hongshui = function(self, data)
local benefit = 0
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) then benefit = benefit - getzhachangUseValueOfHECards(self, player) end
			if self:isEnemy(player) then benefit = benefit + getzhachangUseValueOfHECards(self, player) end
		end
		if  benefit > 0 then
			return true

		end
	return false
end

sgs.ai_fill_skill["zhufu"] = function(self,inclusive,request)

	if __htms_value_call(self.player,"getMark","@zfu") > 0 then
		return policy(self,"#zhufu:.:")
	end
end

sgs.ai_skill_use_func["#zhufu"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
		cards = self:sortByKeepValue(cards)
		local benefit = 0
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) and __htms_value_call(player,"isWounded") and player:getEquips():length() > 0 then benefit = benefit + 1 end
			if self:isEnemy(player) and __htms_value_call(player,"isWounded") and player:getEquips():length() > 0 then benefit = benefit - 1 end
		end
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) and self:isWeak(player) and player:getEquips():length() > 0 then benefit = benefit + 2 end
			if self:isEnemy(player) and self:isWeak(player) and player:getEquips():length() > 0  then benefit = benefit - 2 end
		end
		if benefit > 0 then
			use.card = policy(self,"#zhufu:.:")

		end
end



sgs.ai_skill_invoke.afuhuo = function(self, data)
	local dying = data:toDying()
	local lord = self.room:getLord()
	if self:isFriend(dying.who) and dying.who:objectName() ~= self.player:objectName() then
		if dying.who:objectName() == lord:objectName() then return true end
		if self:isFriend(lord) and not self:canNiepan(lord) and __htms_value_call(lord,"getHp") == 1 then return end
		if viewer_role(self,self.player) == "renegade" and #self.friends >= #self.enemies then return end
		return true
	end
	if __htms_value_call(dying.who,"hasSkill","wuhun") and self:TheWuhun(dying.who, true) == -2  then return true end
	if self.player:objectName() == dying.who:objectName() then return true end
	return false
end

sgs.ai_canNiepan_skill.afuhuo = function(player)
	return __htms_value_call(player,"getMark","@fuhuo") > 0
end

sgs.ai_skill_choice.afuhuo = function(self, choices)
	local items = choices:split("+")

				if table.contains(items, "fuhuo_j") then
					return "fuhuo_j"
				end
		if table.contains(items, "fuhuo_e") then
					return "fuhuo_e"
				end
				if table.contains(items, "fuhuo_h") then
					return "fuhuo_h"
				end
	return items[1]
end


sgs.ai_skill_invoke.tonghua = function(self, data)
	 return true
end

sgs.ai_skill_playerchosen.tonghua = function(self, targets)
	return self.player
end
sgs.ai_playerchosen_intention.tonghua = function(self, from, to)
		self:updateIntention(from, to, -50)
end






sgs.ai_skill_playerchosen.lingbo = function(self, targets)
local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and __htms_value_call(arr1[1],"getHp") < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return	target
	end
	if  #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				return	friend
			end
		end
	end


	return nil
end
sgs.ai_playerchosen_intention.lingbo = function(self, from, to)
		self:updateIntention(from, to, -50)
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|lingbo"

function sgs.ai_cardneed.lingbo(to, card, self)
	return __htms_value_call(to,"getHandcardNum") < 3 and __htms_value_call(card,"getSuit") == sgs.Card_Heart
end

sgs.ai_cardneed.chaogz = sgs.ai_cardneed.slash
sgs.double_slash_skill = sgs.double_slash_skill .. "|chaogz"
sgs.ai_ajustdamage_from.chaogz = function(self, from, to, card, nature)
	if from and __htms_value_call(from,"getMark","chaogz") > 0 and card and __htms_value_call(card,"isKindOf","Slash")
	then
		return 1
	end
end

sgs.ai_cardneed.shengqiang = sgs.ai_cardneed.slash
sgs.hit_skill = sgs.hit_skill .. "|shengqiang"
sgs.double_slash_skill = sgs.double_slash_skill .. "|shengqiang"

function SmartAIView:UseAoeSkillValue_paojixj(element, players, card)
	element = element or sgs.DamageStruct_Normal
	local friends = {}
	local enemies = {}
	local good = 0

	players = players or sgs.QList2Table(self.room:getOtherPlayers(self.player))

	for _, ap in ipairs(players) do
		if self:isFriend(ap) then table.insert(friends, ap)
		else table.insert(enemies, ap) end
	end

	good = (#enemies - #friends) * 2
	if #enemies == 0 then return -100 end
	if element == sgs.DamageStruct_Thunder then
		for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
			if __htms_value_call(ap,"hasSkill","TH_yuyiruokong") then
				if self:isFriend(ap) then good = good + ap:getCardCount(true)
				else good = good - ap:getCardCount(true)
				end
			end
		end
	end
	if element == sgs.DamageStruct_Fire then
		for _,ap in sgs.qlist(self.room:getAlivePlayers()) do
			if __htms_value_call(ap,"hasSkill","TH_Meltdown") then
				for _, friend in ipairs(friends) do
					if __htms_value_call(friend,"getHandcardNum") > 0 then good = good - 0.5 end
				end
				for _, enemy in ipairs(enemies) do
					if __htms_value_call(enemy,"getHandcardNum") > 0 then good = good + 0.5 end
				end
			end
		end
	end




	if __htms_value_call(self.player,"hasSkill","TH_hongsehuanxiangxiang") then good = good + 1 end

	if viewer_role(self,self.player) == "renegade" then good = good + 0.5 end
	if viewer_role(self,self.player) == "rebel" then good = good + 0.8 end

	local who
	for _, player in ipairs(players) do
		if player:isChained() and self:damageIsEffective(player, element) and not who then who = player end
		local value = 0
		if viewer_role(self,player) == "lord" then value = value - 0.5 end
		if not self:damageIsEffective(player, element) then
			value = value + 1
			if self:isEnemy(player) and #enemies == 1 or self:isFriend(player) and #friends == 1 then value = value + 100 end
		end
		if __htms_value_call(player,"getHp") == 1 and self:getAllPeachNum() == 0 then
			if viewer_role(self,player) == "lord" then value = value - 100 else value = value - 2 end
		end
		if self:needToLoseHp(player, self.player, card) then value = value + 0.5 end
		if self:canNiepan(player) then value = value + 0.5 end
		if self:hasSkills(sgs.save_skill ,player) then value = value + 0.5 end

		if self:isFriend(player) then good = good + value else good = good - value end
	end





	return good
end

sgs.ai_fill_skill["paojixj"] = function(self,inclusive,request)
	if not self.player:hasUsed("#paojixj") and (__htms_value_call(self.player,"getMark","@xjpaoj") > 0 ) then
		if __htms_value_call(self.player,"getHandcardNum") >= 4 then
		local spade, club, heart, diamond
		local suit = 0
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if __htms_value_call(card,"getSuit") == sgs.Card_Spade then spade = true
			elseif __htms_value_call(card,"getSuit") == sgs.Card_Club then club = true
			elseif __htms_value_call(card,"getSuit") == sgs.Card_Heart then heart = true
			elseif __htms_value_call(card,"getSuit") == sgs.Card_Diamond then diamond = true
			end
		end
		if spade then
			suit = suit + 1
		end
		if club then
			suit = suit + 1
		end
		if heart then
			suit = suit + 1
		end
		if diamond then
			suit = suit + 1
		end
		if suit > 0 then
			local slash = clone(self,"slash",sgs.Card_NoSuit,0)
			slash:deleteLater()
			self.enemies = self:sort(self.enemies, "hp")
			local target_num = 0
			for _, enemy in ipairs(self.enemies) do
				if self:slashIsEffective(slash, enemy) and not self:slashProhibit(slash, enemy)
				and self:isGoodTarget(enemy, self.enemies, slash) then
					target_num = target_num + 1
				end
			end

			if target_num >= 1 then
				return policy(self,"#paojixj:.:")
			end
		end
	end
	end
end
sgs.ai_skill_use_func["#paojixj"] = function(card, use, self)--凤翼天翔
	local jiu
	if not self.player:hasUsed("Analeptic") and self:getCard("Analeptic") then
		jiu = self:getCard("Analeptic")
	end
	local s = self:getCard("Slash")
	if self:UseAoeSkillValue_paojixj(sgs.DamageStruct_Normal, nil, s) > 0 then
		if jiu and not use.isDummy then use.card = jiu return end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		cards = self:sortByUseValue(cards, true)
		local need_cards = {}
		local spade, club, heart, diamond
		for _, card in ipairs(cards) do
			if __htms_value_call(card,"getSuit") == sgs.Card_Spade and not spade then spade = true table.insert(need_cards, card:getId())
			elseif __htms_value_call(card,"getSuit") == sgs.Card_Club and not club then club = true table.insert(need_cards, card:getId())
			elseif __htms_value_call(card,"getSuit") == sgs.Card_Heart and not heart then heart = true table.insert(need_cards, card:getId())
			elseif __htms_value_call(card,"getSuit") == sgs.Card_Diamond and not diamond then diamond = true table.insert(need_cards, card:getId())
			end
		end
		local paojixj = policy(self,"#paojixj:" .. table.concat(need_cards, "+")..":")
		use.card = paojixj
		if use.to then
			local slash = clone(self,"slash",sgs.Card_NoSuit,0)
			slash:deleteLater()
			self.enemies = self:sort(self.enemies, "hp")
			local target_num = 0
			for _, enemy in ipairs(self.enemies) do
				if self:slashIsEffective(slash, enemy) and not self:slashProhibit(slash, enemy)
				and self:isGoodTarget(enemy,self.enemies, slash) and target_num < #need_cards then
					target_num = target_num + 1
					use.to:append(enemy)
				end
			end
		end
		return
	end
end

sgs.ai_use_priority["paojixj"] = 3

sgs.drawpeach_skill = sgs.drawpeach_skill .. "|dqjt"

sgs.ai_skill_invoke.dqjt = function(self,data)
	local change = data:toPhaseChange()
	if change.to==sgs.Player_Draw and not self.player:isSkipped(sgs.Player_Draw) and not self.player:hasSkills("tuxi|nostuxi") then
		local cardstr = sgs.ai_skill_use["@@nostuxi"](self,"@nostuxi")
		if cardstr:match("->") then
			local targetstr = cardstr:split("->")[2]
			local targets = targetstr:split("+")
			if #targets>0 then
				return true
			end
		end
		return false
	elseif change.to==sgs.Player_Play then
		local cards = sgs.QList2Table(self.player:getHandcards())
		local shouldUse,range_fix = 0,0
		local hasCrossbow,slashTo = false,false
		for _,card in ipairs(cards)do
			if __htms_value_call(card,"isKindOf","TrickCard") and self:getUseValue(card)>3.69 then
				local dummy_use = self:aiUseCard(card, dummy_plan())
				if dummy_use.card then shouldUse = shouldUse+(__htms_value_call(card,"isKindOf","ExNihilo") and 2 or 1) end
			end
			if __htms_value_call(card,"isKindOf","Weapon") then
				local new_range = sgs.weapon_range[__htms_value_call(card,"getClassName")] or 0
				local current_range = __htms_value_call(self.player,"getAttackRange")
				range_fix = math.min(current_range-new_range,0)
			end
			if __htms_value_call(card,"isKindOf","OffensiveHorse") and not self.player:getOffensiveHorse() then range_fix = range_fix-1 end
			if __htms_value_call(card,"isKindOf","DefensiveHorse") or __htms_value_call(card,"isKindOf","Armor") and not self:getSameEquip(card) and (self:isWeak() or self:getCardsNum("Jink")==0) then shouldUse = shouldUse+1 end
			if __htms_value_call(card,"isKindOf","Crossbow") or self:hasCrossbowEffect() then hasCrossbow = true end
		end

		local slashs = self:getCards("Slash")
		for _,enemy in ipairs(self.enemies)do
			for _,slash in ipairs(slashs)do
				if hasCrossbow and self:getCardsNum("Slash")>1 and self:slashIsEffective(slash,enemy)
					and self.player:canSlash(enemy,slash,true,range_fix) then
					shouldUse = shouldUse+2
					hasCrossbow = false
					break
				elseif not slashTo and self:slashIsAvailable() and self:slashIsEffective(slash,enemy)
					and self.player:canSlash(enemy,slash,true,range_fix) and getCardsNum("Jink",enemy)<1 then
					shouldUse = shouldUse+1
					slashTo = true
				end
			end
		end
		if shouldUse>=2 then return false end
		return true
	end

end
sgs.ai_skill_playerchosen.dqjt = function(self,targets)
	if __htms_value_call(self.player,"hasFlag","dqjt") then
		local cardstr = sgs.ai_skill_use["@@nostuxi"](self,"@nostuxi")
		if cardstr:match("->") then
			local targetstr = cardstr:split("->")[2]
			local targets = targetstr:split("+")

			if #targets>0 then
				local to = self.room:findPlayerByObjectName(targets[1])
				if to then return to end
			end
		end
		for _,target in sgs.list(targets)do
			if self:doDisCard(target, "he") then return target end
		end
	else
		targets = sgs.QList2Table(targets)
		targets = self:sort(targets,"defense")
		for _,target in sgs.list(targets)do
			if self:isFriend(target) and self:canDraw(target, self.player) then return target end
		end
	end
	return self.player
end

sgs.ai_skill_invoke.lianxie = function(self, data)
	 return true
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|lianxie"
sgs.ai_cardneed.lianxie = sgs.ai_cardneed.paoxiao

sgs.ai_skill_invoke.huanzhaung = function(self, data)
	 return true
end

sgs.ai_skill_cardchosen["huanzhaung"] = function(self, who, flags)
	local card
	local cards = sgs.QList2Table(who:getEquips())
	local handcards = sgs.QList2Table(complete_hand(self,who))
	if self:isFriend(who) then
		if self:needToThrowArmor(who) then
			return who:getArmor()
		end
		if who:hasSkills(sgs.lose_equip_skill) then
			for _, card in ipairs(cards) do
				if __htms_value_call(card,"isKindOf","Weapon") then
					if __htms_value_call(card,"isKindOf","Crossbow") or __htms_value_call(card,"isKindOf","Blade") then continue end
					if __htms_value_call(card,"isKindOf","Axe") or __htms_value_call(card,"isKindOf","GudingBlade") then continue end
				elseif __htms_value_call(card,"isKindOf","Armor") then
					if not self:hasSkills("bazhen|yizhong|linglong") and self:isWeak(who) then
						continue
					end
				elseif __htms_value_call(card,"isKindOf","DefensiveHorse") then
					if self:isWeak(who) then continue end
				end
				return card
			end
		end
		if not who:isKongcheng() then return handcards[1] end
		return cards[1]
	end
	return nil
end


sgs.ai_skill_invoke.xinshengll = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_fill_skill["xinshengll"] = function(self,inclusive,request)
	if #self.enemies < 1 then return end
	local source = self.player
	if source:hasUsed("#xinshengll") then return end
	return policy(self,"#xinshengll:.:")
end

sgs.ai_skill_use_func["#xinshengll"] = function(card,use,self)
	local target
    self.friends_noself = self:sort(self.friends_noself, "handcard")
	for _,friend in ipairs(self.friends_noself) do
		if __htms_value_call(friend,"getHandcardNum") > 0  then
			target = friend
			break
		end
	end
	if target  then
		use.card = policy(self,"#xinshengll:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_askforag["xinshengll"] = function(self, card_ids)
    local cards = {}
	self:writeCurrentSourceTarget("geassTarget",nil)
    for _, card_id in ipairs(card_ids) do
        table.insert(cards, visible(self,card_id))
    end
	cards = self:sortByUseValue(cards)
	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if __htms_value_call(p,"getMark","geass_touse") > 0 then
			target = p
		end
	end
    for _, card in ipairs(cards) do
        if __htms_value_call(card,"isKindOf","Slash") then
			for _,enemy in ipairs(self.enemies) do
				local def = self:getDefenseSlash(enemy)
				local eff = self:slashIsEffective(card, enemy) and self:isGoodTarget(enemy, self.enemies, card)

				if target:canSlash(enemy, slash, true) and not self:slashProhibit(card, enemy, target) and eff then
				self:writeCurrentSourceTarget("geassTarget",enemy)
				return __htms_value_call(card,"getEffectiveId")
				end
			end
		end
		if __htms_value_call(card,"isKindOf","Analeptic") then
				return __htms_value_call(card,"getEffectiveId")
		end
		if __htms_value_call(card,"isKindOf","Duel") or __htms_value_call(card,"isKindOf","Snatch") or __htms_value_call(card,"isKindOf","Dismantlement")  or __htms_value_call(card,"isKindOf","SupplyShortage") or __htms_value_call(card,"isKindOf","Indulgence")  then
			local dummy_use = self:aiUseCard(card, dummy_plan())
					local targets = {}
					if not dummy_use.to:isEmpty() then
						self:writeCurrentSourceTarget("geassTarget",dummy_use.to:first())
						return __htms_value_call(card,"getEffectiveId")
					end
		end

		if  __htms_value_call(card,"isKindOf","SavageAssault") or __htms_value_call(card,"isKindOf","ArcheryAttack") or __htms_value_call(card,"isKindOf","GodSalvation") then
			local dummy_use = self:aiUseCard(card, dummy_plan())
					if  dummy_use.card then
						return __htms_value_call(card,"getEffectiveId")
					end
		end
		if __htms_value_call(card,"isKindOf","EquipCard") and not self:hasSkills(sgs.lose_equip_skill, target) then
			if __htms_value_call(card,"isKindOf","Weapon")  and target:getWeapon() and self:evaluateWeapon(card) < self:evaluateWeapon(target:getWeapon()) then return __htms_value_call(card,"getEffectiveId")
			elseif __htms_value_call(card,"isKindOf","Armor") and target:getArmor() and self:evaluateArmor(card) < self:evaluateArmor(target:getArmor()) then return __htms_value_call(card,"getEffectiveId")
			end
		end
    end
    return -1
end



sgs.ai_skill_invoke.llpj = function(self, data)
local benefit = 0
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) then benefit = benefit - __htms_value_call(player,"getHp") end
			if self:isEnemy(player) then benefit = benefit + __htms_value_call(player,"getHp") end
		end
		if  benefit > 0 then
			return true

		end
	return false
end


sgs.ai_fill_skill["shejiao"] = function(self,inclusive,request)
	if #self.friends_noself < 1 then return end
	local source = self.player
	if source:hasUsed("#shejiao") then return end
	return policy(self,"#shejiao:.:")
end

sgs.ai_skill_use_func["#shejiao"] = function(card,use,self)
	local target
    self.friends_noself = self:sort(self.friends_noself, "hp")

	sgs.reverse(self.friends_noself)
	for _,friend in ipairs(self.friends_noself) do
		if friend:isFemale() and __htms_value_call(friend,"isWounded") then
			target = friend
			break
		end
		if __htms_value_call(friend,"getHandcardNum") > 0 and __htms_value_call(friend,"isMale") and __htms_value_call(friend,"isWounded") then
			target = friend
			break
		end
	end
	if target  then
		use.card = policy(self,"#shejiao:.:")
		if use.to then use.to:append(target) end
		return
	end
	self.enemies = self:sort(self.enemies, "hp")
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and enemy:isFemale() and not hasZhaxiangEffect(enemy) and __htms_value_call(self.player,"getMark","@hurt") > 0 and __htms_value_call(self.player,"getHp")>__htms_value_call(enemy,"getHp") and __htms_value_call(self.player,"getHp")>1 then
			use.card = policy(self,"#shejiao:.:")
			if use.to then use.to:append(target) end
			return
		end
	end
end

sgs.ai_skill_choice.shejiao = function(self, choices, data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if table.contains(items, "shejiao_hf") and self:isFriend(target) then
		return "shejiao_hf"
	end
	if table.contains(items, "shejiao_sq") and self:isEnemy(target) and not hasZhaxiangEffect(target) then
		return "shejiao_sq"
	end

	return items[1]
end

sgs.ai_skill_use["@@shejiaofuka"]=function(self,prompt)
	self:updatePlayers()
	local current = self.room:getCurrent()
	local to_give = {}
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	for _,c in ipairs(handcards) do
		if not __htms_value_call(c,"isKindOf","Peach") and not __htms_value_call(c,"isKindOf","Analeptic") and not __htms_value_call(c,"isKindOf","Jink") and not __htms_value_call(c,"isKindOf","Nullification") then
			table.insert(to_give, __htms_value_call(c,"getEffectiveId"))
		end
	end

	if #to_give == 0 then return end

	return "#shejiaofuka:"..table.concat(to_give, "+")..":->"..current:objectName()
end

sgs.ai_skill_invoke.wanxian = function(self, data)
	return true
end
sgs.ai_skill_playerchosen.wanxian = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and __htms_value_call(arr1[1],"getHp") < getBestHp(arr1[1]) then target = arr1[1] end
	if target and target:getEquips():length() < self.player:getEquips():length() then
		return	target
	end
	if  #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun")  and friend:getEquips():length() < self.player:getEquips():length() then
				return	friend
			end
		end
	end

	for _,enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) and enemy:getEquips():length() >  self.player:getEquips():length()  then
			return	enemy
		end
	end


	return self.player
end

sgs.ai_skill_invoke.liantan = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.liantan = function(self, targets)
local target
    self.friends_noself = self:sort(self.friends_noself, "handcard")
	for _,friend in ipairs(self.friends_noself) do
		if __htms_value_call(friend,"getHandcardNum") > 0  then
			target = friend
			break
		end
	end
	if target then
		return target
	end

	return nil
end
sgs.ai_playerchosen_intention.liantan = function(self, from, to)
		self:updateIntention(from, to, -50)
end


sgs.ai_skill_choice.liantan = function(self, choices)
	local items = choices:split("+")

	if table.contains(items, "liantan_hd") then
					return "liantan_hd"
				end
	return items[1]
end



function sgs.ai_cardneed.s_yanyu(to,card)
	return __htms_value_call(to,"getHandcardNum") < __htms_value_call(to,"getHp")
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|s_yanyu"
sgs.ai_can_damagehp.s_yanyu = function(self,from,card,to)
	return (__htms_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)and math.min(__htms_value_call(to,"getHandcardNum"), __htms_value_call(to,"getMaxHp"))-__htms_value_call(to,"getHp")>2)
end
sgs.ai_fill_skill["s_yanmojianglin"] = function(self,inclusive,request)
	if #self.enemies < 1 then return end
	local source = self.player
	if source:hasUsed("#s_yanmojianglin") or __htms_value_call(source,"getHandcardNum") < 3 then return end
	return policy(self,"#s_yanmojianglin:.:")
end

sgs.ai_skill_use_func["#s_yanmojianglin"] = function(card,use,self)
	local target
	local allcard = {}
	local benefit = 0
	local players = self.room:getOtherPlayers(self.player)
		local max_distance = 0
		local min_distance = 999
		for _, q in sgs.qlist(players) do
			max_distance = math.max(max_distance, __htms_value_call(self.player,"distanceTo",q))
			min_distance = math.min(min_distance, __htms_value_call(self.player,"distanceTo",q))
		end
		for _,p in sgs.qlist(players) do
			if p:isAlive() then
				if __htms_value_call(self.player,"distanceTo",p) == max_distance then
					if self:isFriend(p) then
						benefit = benefit - 1
					else
						benefit = benefit + 1
					end
				end
				if __htms_value_call(self.player,"distanceTo",p) == min_distance then
					if self:isFriend(p) then
						benefit = benefit - 1
					else
						benefit = benefit + 1
					end
				end
			end
		end
		for _, card in ipairs(sgs.QList2Table(self.player:getHandcards())) do
		table.insert(allcard, card:getId())
	end
	if benefit > 0 and __htms_value_call(self.player,"getHandcardNum") < 5  then
		use.card = policy(self,"#s_yanmojianglin:".. table.concat(allcard, "+") .. ":")
		return
	end
end


sgs.ai_skill_choice.s_yanmojianglin = function(self, choices)
	local items = choices:split("+")
	local current = self.room:getCurrent()
	if self:willSkipPlayPhase() and table.contains(items, "s_yanmojianglin_skipplay") then
		return "s_yanmojianglin_skipplay"
	end
	if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, current)
			and  self:needToLoseHp(self.player, current) and table.contains(items, "s_yanmojianglin_damage") then
					return "s_yanmojianglin_damage"
	end
	if ((not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, current)) or
	not self:isWeak())
	and table.contains(items, "s_yanmojianglin_damage") then
					return "s_yanmojianglin_damage"
	end
	if __htms_value_call(self.player,"getHandcardNum") <= 3 and  table.contains(items, "s_yanmojianglin_throwcard") then
					return "s_yanmojianglin_throwcard"
				end
	return items[1]
end




sgs.ai_fill_skill["s_lianjie"] = function(self,inclusive,request)
	if not self.player:hasUsed("#s_lianjie") then
		return policy(self,"#s_lianjie:.:")
	end
end

sgs.ai_skill_use_func["#s_lianjie"] = function(card, use, self)

	self.friends_noself = self:sort(self.friends_noself, "handcard")
	self.enemies = self:sort(self.enemies, "handcard")
	local targets = {}
	local voidfriend, voidenemey = 0,0

			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				if __htms_value_call(p,"hasSkill","s_lianjie") then
					table.insert(targets, p:objectName())
					if self:isFriend(p) then
						voidfriend = voidfriend + 1
					end
					if self:isEnemy(p) then
						voidenemey = voidenemey + 1
					end
				end
			end

	if (voidfriend <= #self.friends_noself) then
		for _, friend in ipairs(self.friends_noself) do
			if  not table.contains(targets, friend:objectName()) and self:canDraw(friend, self.player) then
				local card_str = "#s_lianjie:.:"
					local acard = policy(self,card_str)
					use.card = acard

					if use.to then use.to:append(friend) end
					return
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if not table.contains(targets, enemy:objectName()) then
				local card_str = "#s_lianjie:.:"
					local acard = policy(self,card_str)
					use.card = acard

					if use.to then use.to:append(enemy) end
					return
			end
		end
	end
end

sgs.ai_fill_skill["s_polie"] = function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if not self.player:hasUsed("#s_polie") then
		return policy(self,"#s_polie:.:")
	end
end

sgs.ai_skill_use_func["#s_polie"] = function(card, use, self)

	self.friends_noself = self:sort(self.friends_noself, "handcard")
	self.enemies = self:sort(self.enemies, "handcard")
	local targets = {}
	local voidfriend, voidenemey = 0,0

			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if __htms_value_call(p,"hasSkill","s_lianjie") then
					table.insert(targets, p)
					if self:isFriend(p) then
						voidfriend = voidfriend + 1
					end
					if self:isEnemy(p) then
						voidenemey = voidenemey + 1
					end
				end
			end

	if (voidenemey + voidfriend >= 3 or voidenemey + voidfriend == self.room:getAlivePlayers():length()) and voidenemey > 0 then

				local card_str = "#s_polie:.:"
					local acard = policy(self,card_str)
					use.card = acard
					if use.to then
						for i = 1, #targets, 1 do
							use.to:append(targets[i])
						end
					end
					return
	end
end



sgs.ai_skill_playerchosen.s_polie = function(self, targets)
	local targetlist=sgs.QList2Table(targets)
	local enemieslist = {}
	for _, enemy in ipairs(targetlist) do
		if self:isEnemy(enemy) and not enemy:hasArmorEffect("silver_lion") and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) then
			table.insert(enemieslist, enemy)
		end
	end
    local getCmpValue = function(enemy)
        local value = 0
        if self:damageIsEffective(enemy) then
            local dmg = enemy:hasArmorEffect("silver_lion") and 1 or 2
            if __htms_value_call(enemy,"getHp") <= dmg then value = 5 else value = value + __htms_value_call(enemy,"getHp") / (__htms_value_call(enemy,"getHp") - dmg) end
            if not self:isGoodTarget(enemy, self.enemies, nil) then value = value - 2 end
            if self:cantbeHurt(enemy, self.player, dmg) then value = value - 5 end
            if __htms_value_call(enemy,"isLord") then value = value + 2 end
            if enemy:hasArmorEffect("silver_lion") then value = value - 1.5 end
            if self:hasSkills(sgs.exclusive_skill, enemy) then value = value - 1 end
            if self:hasSkills(sgs.masochism_skill, enemy) then value = value - 0.5 end
        end
        if not enemy:getEquips():isEmpty() then
            local len = enemy:getEquips():length()
            if enemy:hasSkills(sgs.lose_equip_skill) then value = value - 0.6 * len end
            if enemy:getArmor() and self:needToThrowArmor() then value = value - 1.5 end
            if enemy:hasArmorEffect("silver_lion") then value = value - 0.5 end

            if enemy:getWeapon() then value = value + 0.8 end
            if enemy:getArmor() then value = value + 1 end
            if enemy:getDefensiveHorse() then value = value + 0.9 end
            if enemy:getOffensiveHorse() then value = value + 0.7 end
            if self:getDangerousCard(enemy) then value = value + 0.3 end
            if self:getValuableCard(enemy) then value = value + 0.15 end
        end
        return value
    end

    local cmp = function(a, b)
        return getCmpValue(a) > getCmpValue(b)
    end
    table.sort(enemieslist, cmp)
    return enemieslist[1]
end


sgs.ai_skill_choice.s_shuimian = function(self, choices)
	local items = choices:split("+")

	if self:isWeak() and not self:getOverflow() > 2 and table.contains(items, "s_shuimian_recover") then
		return "s_shuimian_recover"
	end
	if self:getOverflow() > 0 and table.contains(items, "s_shuimian_skipdiscard") then
		return "s_shuimian_skipdiscard"
	end
	if __htms_value_call(self.player,"isWounded") and table.contains(items, "s_shuimian_recover") then
		return "s_shuimian_recover"
	end

	return items[1]
end

sgs.ai_skill_playerchosen.s_jieshu = function(self, targets)

	local max_card = self:getMaxCard(self.player)
	local max_point = __htms_value_call(max_card,"getNumber")

	if __htms_value_call(self.player,"hasSkill","kongcheng") and __htms_value_call(self.player,"getHandcardNum") == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and __htms_value_call(self.player,"canPindian",enemy) then
				return enemy
			end
		end
	end

		for _, enemy in ipairs(self.enemies) do
			if not (__htms_value_call(enemy,"hasSkill","kongcheng") and __htms_value_call(enemy,"getHandcardNum") == 1 and __htms_value_call(enemy,"getHp") > __htms_value_call(self.player,"getHp"))
				and not enemy:isKongcheng() and self.player:canSlash(enemy, nil, true) and __htms_value_call(self.player,"canPindian",enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local allknown = 0
				if self:getKnownNum(enemy) == __htms_value_call(enemy,"getHandcardNum") then
					allknown = allknown + 1
				end
				if (enemy_max_card and max_point > __htms_value_call(enemy_max_card,"getNumber") and allknown > 0)
					or (enemy_max_card and max_point > __htms_value_call(enemy_max_card,"getNumber") and allknown < 1 and max_point > 10)
					or (not enemy_max_card and max_point > 10) then
					return enemy
				end
			end

		end

	for _, friend in ipairs(self.friends_noself) do
		if not __htms_value_call(friend,"hasSkill","s_fudao") then
			if not self:willSkipPlayPhase(friend) then
				return friend
			end
		end
	end
    return nil
end
sgs.ai_skill_choice.s_jieshu = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target and self:isFriend(target) and table.contains(items, "s_jieshu_skill") then
		return "s_jieshu_skill"
	end
	if target and self:isEnemy(target) and table.contains(items, "s_jieshu_pindian") then
		return "s_jieshu_pindian"
	end

	return items[1]
end
sgs.ai_cardneed.s_jieshu = sgs.ai_cardneed.bignumber

sgs.ai_skill_choice.s_fudao = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target and self:isFriend(target) and table.contains(items, "s_fudao_play") then
		return "s_fudao_play"
	end
	if target and self:isEnemy(target) and table.contains(items, "s_fudao_discard") then
		return "s_fudao_discard"
	end

	return items[1]
end

sgs.ai_fill_skill["s_fudao"] = function(self,inclusive,request)

if not self.player:hasUsed("#s_fudao") then
	local target
	local players =  self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(players) do
		if (string.find(p:getGeneralName(), "htms_bifang") or string.find(p:getGeneral2Name(), "htms_bifang")) then
			target = p
			break
		end
	end
	if target then
		return policy(self,"#s_fudao:.:")
		end
	end
end


sgs.ai_skill_use_func["#s_fudao"] = function(card,use,self)
	local target
	local players = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(players) do
		if (string.find(p:getGeneralName(), "htms_bifang") or string.find(p:getGeneral2Name(), "htms_bifang")) and
		(self:isFriend(p) or (self:isEnemy(p) and self:doDisCard(p, "he") ))
		then

			target = p
			break
		end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_invoke.s_douM = function(self, data)
	return true
end





sgs.ai_skill_choice.s_kongyi = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items, "s_kongyi_damage") then
		if self:damageIsEffective(self.player, sgs.DamageStruct_Normal) and
		self:needToLoseHp(self.player, target) then
		return "s_kongyi_damage"
		end
		if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal) then
			return  "s_kongyi_damage"
		end
	end
	if table.contains(items, "s_kongyi_movefield") then
		local targetc
		local judges = self.player:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if not __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (__htms_value_call(enemy,"hasSkill","hongyan") or __htms_value_call(judge,"isKindOf","Lightning")) then
							targetc = enemy
							break
						end
					end
					if targetc then
						return true
					end
				end
			end
		end



		local equips = self.player:getCards("e")
		local weak
		if not targetc and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, self.player)  then
			for _, equip in sgs.qlist(equips) do
				if __htms_value_call(equip,"isKindOf","OffensiveHorse") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","Weapon") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(self.player) then
					card = equip
					break
				elseif __htms_value_call(equip,"isKindOf","Armor") and (not self:isWeak(self.player) or self:needToThrowArmor(self.player)) then
					card = equip
					break
				end
			end

			if card then
				if __htms_value_call(card,"isKindOf","Armor") or __htms_value_call(card,"isKindOf","DefensiveHorse") then
					self.friends = self:sort(self.friends, "defense")
				else
					self.friends = self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
							targetc = friend
							break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName() then
						targetc = friend
						break
					end
				end
				if targetc then
						return "s_kongyi_movefield"
					end
				end
			end
	end
	if table.contains(items, "s_kongyi_handcard") then
		if __htms_value_call(self.player,"getMark","s_kongyi_num") <= 2 then
			return "s_kongyi_handcard"
		end
	end

	return "s_kongyi_damage"
end

sgs.ai_skill_cardchosen.s_kongyi = function(self, who, flags)
local card
local target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if not __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (__htms_value_call(enemy,"hasSkill","hongyan") or __htms_value_call(judge,"isKindOf","Lightning")) then
							target = enemy
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
	if self:isEnemy(who) then
	local judges = who:getJudgingArea()
		if who:containsTrick("YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					card = visible(self,__htms_value_call(judge,"getEffectiveId"))
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
					if target then
						return card
						end
				end
			end
		end
	end
	if self:isEnemy(who) then
		if  who:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, who) then
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(visible(self,card_id)) then card = visible(self,card_id) end

			if card then
				if __htms_value_call(card,"isKindOf","Armor") or __htms_value_call(card,"isKindOf","DefensiveHorse") then
					self.friends = self:sort(self.friends, "defense")
				else
					self.friends = self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and self:hasSkills(sgs.lose_equip_skill .. "|shensu" , friend) then
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
	if self:isFriend(who) then
		local equips = who:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, who) then
			for _, equip in sgs.qlist(equips) do
				if __htms_value_call(equip,"isKindOf","OffensiveHorse") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","Weapon") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif __htms_value_call(equip,"isKindOf","Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if __htms_value_call(card,"isKindOf","Armor") or __htms_value_call(card,"isKindOf","DefensiveHorse") then
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


sgs.ai_skill_playerchosen.s_kongyi_getfield = function(self, targets)
	local who = room_tag(self,"s_kongyiTarget","Player")
local card
local target
	if who then
		if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if not __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (__htms_value_call(enemy,"hasSkill","hongyan") or __htms_value_call(judge,"isKindOf","Lightning")) then
							target = enemy
							break
						end
					end
					if target then
						return target
					end
				end
			end
		end
	end
	if self:isEnemy(who) then
	local judges = who:getJudgingArea()
		if who:containsTrick("YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					card = visible(self,__htms_value_call(judge,"getEffectiveId"))
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
					if target then
						return target
						end
				end
			end
		end
	end
	if self:isEnemy(who) then
		if  who:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, who) then
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(visible(self,card_id)) then card = visible(self,card_id) end

			if card then
				if __htms_value_call(card,"isKindOf","Armor") or __htms_value_call(card,"isKindOf","DefensiveHorse") then
					self.friends = self:sort(self.friends, "defense")
				else
					self.friends = self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and self:hasSkills(sgs.lose_equip_skill .. "|shensu" , friend) then
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
						return target
					end
					end
			end
		end
	if self:isFriend(who) then
		local equips = who:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, who) then
			for _, equip in sgs.qlist(equips) do
				if __htms_value_call(equip,"isKindOf","OffensiveHorse") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","Weapon") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif __htms_value_call(equip,"isKindOf","Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if __htms_value_call(card,"isKindOf","Armor") or __htms_value_call(card,"isKindOf","DefensiveHorse") then
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
						return target
					end
			end
		end
	end
	end

end

sgs.ai_fill_skill["s_kongyi"] = function(self,inclusive,request)
	if not self.player:isNude() and not self.player:hasUsed("#s_kongyi") then
        return policy(self,"#s_kongyi:.:")
    end
end

sgs.ai_skill_use_func["#s_kongyi"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself, "handcard")
	local cards=sgs.QList2Table(self.player:getCards("he"))
	local needed = {}
	if __htms_value_call(self.player,"isWounded") then
		for _,acard in ipairs(cards) do
			if #needed < 3 and not __htms_value_call(acard,"isKindOf","Peach") then
				table.insert(needed, __htms_value_call(acard,"getEffectiveId"))
			end
		end
	else
		if (self:getOverflow() > 0) then
			for _,acard in ipairs(cards) do
				if #needed < self:getOverflow() and not __htms_value_call(acard,"isKindOf","Peach") then
					table.insert(needed, __htms_value_call(acard,"getEffectiveId"))
				end
			end
		end
	end
	local target
	local players = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(players) do
		if p and self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal) and not self:cantbeHurt(p) and self:canDamage(p,self.player,nil)
		and not  (self:hasSkills(sgs.lose_equip_skill, p) and p:getEquips():length() > 0)
		then

			target = p
			break
		end
	end

	if #needed > 0 and target then

					use.card = policy(self,"#s_kongyi:"..table.concat(needed,"+")..":")
					if use.to then
						use.to:append(target)
					end
					return
	end
end



sgs.ai_skill_invoke.s_yueqian = function(self, data)
	local source = self.player
	local card
	local target
	local damage = data:toDamage()
	if self:ajustDamage(damage.from,damage.to,damage.damage,damage.card) > 0 and self:needToLoseHp(damage.to, damage.from) then return false end
	if self:ajustDamage(damage.from,damage.to,damage.damage,damage.card) == 0 then
		return false
	end
		local judges = source:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if not __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (__htms_value_call(enemy,"hasSkill","hongyan") or __htms_value_call(judge,"isKindOf","Lightning")) then
							target = enemy
							break
						end
					end
					if target then
						return true
					end
				end
			end
		end



		local equips = source:getCards("e")
		local weak
		if not target and not equips:isEmpty()  then
			for _, equip in sgs.qlist(equips) do
				if __htms_value_call(equip,"isKindOf","OffensiveHorse") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","Weapon") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(source) then
					card = equip
					break
				elseif __htms_value_call(equip,"isKindOf","Armor") and (not self:isWeak(source) or self:needToThrowArmor(source)) then
					card = equip
					break
				end
			end

			if card then
				if __htms_value_call(card,"isKindOf","Armor") or __htms_value_call(card,"isKindOf","DefensiveHorse") then
					self.friends = self:sort(self.friends, "defense")
				else
					self.friends = self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= source:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
							target = friend
							break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= source:objectName() then
						target = friend
						break
					end
				end
				if target then
						return true
					end
			end
		end
	return false
end

sgs.ai_skill_cardchosen.s_yueqian = function(self, who, flags)
local card
local target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if not __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (__htms_value_call(enemy,"hasSkill","hongyan") or __htms_value_call(judge,"isKindOf","Lightning")) then
							target = enemy
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
	if self:isFriend(who) then
		local equips = who:getCards("e")
		local weak
		if not target and not equips:isEmpty() then
			for _, equip in sgs.qlist(equips) do
				if __htms_value_call(equip,"isKindOf","OffensiveHorse") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","Weapon") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif __htms_value_call(equip,"isKindOf","Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if __htms_value_call(card,"isKindOf","Armor") or __htms_value_call(card,"isKindOf","DefensiveHorse") then
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


sgs.ai_skill_playerchosen.s_yueqian = function(self, targets)
		local card
		local target
		if self:isFriend(self.player) then
		local judges = self.player:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,__htms_value_call(judge,"getEffectiveId"))
				if not __htms_value_call(judge,"isKindOf","YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (__htms_value_call(enemy,"hasSkill","hongyan") or __htms_value_call(judge,"isKindOf","Lightning")) then
							target = enemy
							break
						end
					end
					if target then
						return target
					end
				end
			end
		end
	end
	if self:isFriend(self.player) then
		local equips = self.player:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, self.player) then
			for _, equip in sgs.qlist(equips) do
				if __htms_value_call(equip,"isKindOf","OffensiveHorse") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","Weapon") then card = equip break
				elseif __htms_value_call(equip,"isKindOf","DefensiveHorse") and not self:isWeak(self.player) then
					card = equip
					break
				elseif __htms_value_call(equip,"isKindOf","Armor") and (not self:isWeak(self.player) or self:needToThrowArmor(self.player)) then
					card = equip
					break
				end
			end

			if card then
				if __htms_value_call(card,"isKindOf","Armor") or __htms_value_call(card,"isKindOf","DefensiveHorse") then
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

end

sgs.need_equip_skill = sgs.need_equip_skill .. "|s_yueqian"
sgs.use_lion_skill = sgs.use_lion_skill .. "|s_yueqian"


sgs.ai_skill_invoke.s_newtype = function(self, data)
	local target = data:toPlayer()
	if target then
		if self:isFriend(target)  and __htms_value_call(target,"getHandcardNum") < 3  then
			return true
		end
		if self:isEnemy(target) and __htms_value_call(target,"getHandcardNum") > 3 then
			return true
		end
	end
	return false
end

sgs.ai_skill_use["@@s_newtype"] = function(self, prompt, method)
	return "#s_newtype:.:"
end

sgs.ai_skill_choice["s_newtype"] = function(self, choices, data)
	self:updatePlayers()


	local taoluan_vs_card = {}
	local types = {"BasicCard", "TrickCard", "EquipCard"}

	local items = choices:split("+")
	for _,card_name in ipairs(items) do
		if card_name ~= "cancel" then
			local use_card = clone(self,card_name, sgs.Card_NoSuit, -1)
			use_card:deleteLater()
			local _type = types[__htms_value_call(use_card,"getTypeId")]
			if not table.contains(taoluan_vs_card, use_card) then
				table.insert(taoluan_vs_card, use_card)
			end
		end
	end
	self:sortByUsePriority(taoluan_vs_card)
	for _,c in ipairs(taoluan_vs_card) do
		if table.contains(items, c:objectName()) then
			if c:targetFixed() then
				if __htms_value_call(c,"isKindOf","Peach") and __htms_value_call(self.player,"isWounded") and __htms_value_call(self.player,"getHp") <= 2 then
					return c:objectName()
				end
				if __htms_value_call(c,"isKindOf","ExNihilo") and __htms_value_call(self.player,"getHandcardNum") <= 2 then
					return c:objectName()
				end
				if __htms_value_call(c,"isKindOf","SavageAssault") then
					if self:getAoeValue(c) > 0 then
						return c:objectName()
					end
				end
				if __htms_value_call(c,"isKindOf","ArcheryAttack") then
					if self:getAoeValue(c) > 0 then
						return c:objectName()
					end
				end
				if __htms_value_call(c,"isKindOf","AmazingGrace") then
					local low_handcard_friend = false
					for _, friend in ipairs(self.friends_noself) do
						if __htms_value_call(friend,"getHandcardNum") <= 4 then
							low_handcard_friend = true
						end
					end
					if low_handcard_friend then
						return c:objectName()
					end
				end
				if __htms_value_call(c,"isKindOf","GodSalvation") then
					if self:willUseGodSalvation(c) then
						return c:objectName()
					end
				end
				if __htms_value_call(c,"isKindOf","Analeptic") then
					for _, slash in ipairs(self:getCards("Slash")) do
						if __htms_value_call(slash,"isKindOf","NatureSlash") and __htms_value_call(slash,"isAvailable",self.player) then
							local dummy_use = self:aiUseCard(slash, dummy_plan())
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
				if __htms_value_call(c,"isKindOf","NatureSlash") and self:getCardsNum("NatureSlash") == 0 then
					if __htms_value_call(c,"isKindOf","FireSlash") or __htms_value_call(c,"isKindOf","ThunderSlash") then
						local dummy_use = self:aiUseCard(c, dummy_plan())
						local targets = {}
						if not dummy_use.to:isEmpty() then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:isChained() then
									set_observation(self,"ai_taoluan_card_name",c:objectName())

									return c:objectName()
								end
							end
						end
					end
				end
				if __htms_value_call(c,"isKindOf","TrickCard") and not __htms_value_call(c,"isKindOf","Collateral") then
					local dummy_use = self:aiUseCard(c, dummy_plan())
					local targets = {}
					if not dummy_use.to:isEmpty() then
						for _, p in sgs.qlist(dummy_use.to) do
							if __htms_value_call(p,"getHp") <= 2 and p:getCards("he"):length() <= 2 and __htms_value_call(p,"getHandcardNum") <= 1 then
								set_observation(self,"ai_taoluan_card_name",c:objectName())

								return c:objectName()
							end
						end
					end
				end
			end
		end
	end
	return "cancel"
end

sgs.ai_skill_use["@@s_newtypeOther"] = function(self, prompt, method)
	local card
	for _, amuro in sgs.qlist(self.room:findPlayersBySkillName("s_newtype")) do
		if __htms_value_call(self.player,"getMark","s_newtype"..amuro:objectName().."-Clear") > 0 then
			card = foreign_property(self,amuro,"s_newtype")
		end
	end
	if not card then
        return "."
    end


	local use_card = clone(self,card, sgs.Card_NoSuit, -1)
	use_card = mutate(self,use_card,"skill","s_newtype")


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
	return "."
end

sgs.ai_skill_invoke.htms_diwu = true

sgs.ai_skill_use["@@htms_nisheng"]=function(self,prompt)
	self:updatePlayers()
	local tos = {}
	local x = math.max(1, __htms_value_call(self.player,"getMark","htms_sanqi"))
	for _,enemy in sgs.list(self.enemies)do
		if self:damageIsEffective(enemy) and not self:cantbeHurt(enemy) then
			table.insert(tos,enemy:objectName())
			if #tos >= x then
				break
			end
		end
	end
	local to_give = {}
	local handcards = sgs.QList2Table(self.player:getCards("eh"))
	for _,c in ipairs(handcards) do
		table.insert(to_give, __htms_value_call(c,"getEffectiveId"))
		if #to_give >= #tos then
			break
		end
	end
	if #tos== 0 or #to_give == 0 then return end
	if #tos > #to_give then
		table.removeOne(tos, tos[#tos])
	end
	if #tos > #to_give then
		table.removeOne(tos, tos[#tos])
	end
	return "#htms_nishengCard:"..table.concat(to_give, "+")..":->"..table.concat(tos, "+")
end

sgs.ai_skill_choice.htms_sanqi = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "equip") then
		return "equip"
	end
	if table.contains(items, "trick") then
		return "trick"
	end
	if table.contains(items, "basic") then
		return "basic"
	end

	return items[1]
end
sgs.ai_skill_invoke.htms_ranxin = function(self, data)
	if self.player:getPile("htms_mo"):length() < 2 then return true end
	if self:isWeak(self.player) and self:getAllPeachNum() <= 1 then return true end
	if not __htms_value_call(self.player,"hasSkill","htms_chiyi") then return true end
	if math.random(1, 2) == 1 then
		return true
	end
	return false
end
sgs.ai_cardneed.htms_ranxin = sgs.ai_cardneed.slash

sgs.ai_target_revises.htms_coffee = function(to,card)
	if __htms_value_call(card,"getSuit") == sgs.Card_Spade or (__htms_value_call(card,"getSuit") == sgs.Card_Heart and __htms_value_call(to,"hasSkill","htms_godot"))
	then return true end
end

sgs.ai_canNiepan_skill.htms_beihai = function(player)
	return __htms_value_call(player,"getMark","htms_beihai") == 0
end

sgs.ai_skill_discard.htms_lunbian = function(self,max,min,optional,equiped)
	local use = room_tag(self,"htms_lunbian","CardUse")
	if use.from and self:isFriend(use.from) then return {} end
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local color = false
	local type = false
	for _,c in sgs.list(cards)do
		if (c:sameColorWith(use.card) and not color) or (c:getType() == use.card:getType() and not type) then
			if c:sameColorWith(use.card) and not color then
				color = true
			end
			if c:getType() == use.card:getType() and not type then
				type = true
			end
			table.insert(to_cards,__htms_value_call(c,"getEffectiveId"))
		end
	end
	if color and type and #to_cards > 0 then
		for _, p in sgs.qlist(use.to) do
			if self:isFriend(p) and self:isWeak(p) then
				return to_cards
			end
		end
		for _, p in sgs.qlist(use.to) do
			if self:isEnemy(p) then
				return {}
			end
		end
		return to_cards
	end
	return {}
end


sgs.ai_skill_playerchosen.htms_godot = function(self, targets)
	for _, p in sgs.qlist(targets) do
		if self:isFriend(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player)
			and self:needToLoseHp(p,self.player,nil) then
			return p
		end
	end
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then table.insert(enemies, t) end
	end
	if #enemies == 0 then return end
	enemies = self:sort(enemies, "hp")
	for _, enemy in ipairs(enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player)
			and not self:needToLoseHp(enemy,self.player,nil) then
			return enemy
		end
	end


	for _, enemy in ipairs(enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
			return enemy
		end
	end

	for _, enemy in ipairs(enemies) do
		return enemy
	end
	return targets:first()
end

local function wrap(f,key,kind)
 return function(...)
  local args=table.pack(...);local self
  for i=1,args.n do local v=args[i];if type(v)=="table"and v.player and v.world and v.request then self=v;break end end
  if not self then return f(...)end
  local outer=not self._htms_callback_depth;local previous=self._htms_callback_key
  self._htms_callback_depth=(self._htms_callback_depth or 0)+1;self._htms_callback_key=key
  if outer then load_state(self)end
  if kind=="ai_skill_use_func"and classes[key]and args[1]and not recipes[args[1]]then recipes[args[1]]={prototype=key,skill=classes[key],subcards=copy(__htms_value_call(args[1],"getSubcards")),user=__htms_value_call(args[1],"getUserString")}end
  local result=table.pack(pcall(f,table.unpack(args,1,args.n)))
  local saved=outer and table.pack(pcall(save_state,self))or{true}
  self._htms_callback_depth=self._htms_callback_depth-1;if self._htms_callback_depth==0 then self._htms_callback_depth=nil end;self._htms_callback_key=previous
  if not result[1]then error(result[2],0)end
  if not saved[1]then error(saved[2],0)end
  if outer and kind=="ai_skill_use_func"and args[2]and args[2].card and recipes[args[2].card]and not recipes[args[2].card].prototype then
   local c=args[2].card;local row=copy(recipes[c]);row.source_key=nil;local mapped=self:evaluateTurnConversion(row.skill,c:getClassName(),row,nil);self:inheritLegacyCardIdentity(mapped,c);args[2].card=mapped
  elseif outer and kind=="ai_skill_use"then
   if key=="@@zhongerhx"then result[2]=self:zhongerhxSourceResult(result[2])else result[2]=response(self,result[2])end
  elseif outer and(kind=="ai_cardsview"or kind=="ai_cardsview_valuable"or kind=="ai_guhuo_card")then result[2]=proposal(result[2])
  elseif outer and kind=="ai_fill_skill"and result[2]and recipes[result[2]]and not recipes[result[2]].prototype then
   local c=result[2];local row=copy(recipes[c]);row.source_key=nil
   local mapped=self:evaluateTurnConversion(row.skill,c:getClassName(),row,args[3]);self:inheritLegacyCardIdentity(mapped,c);result[2]=mapped
  end
  return table.unpack(result,2,result.n)
 end
end
sgs.ai_skill_invoke['zhuisha']=wrap(sgs.ai_skill_invoke['zhuisha'],'zhuisha','ai_skill_invoke')
sgs.ai_skill_cardask['@zhuisha_ask']=wrap(sgs.ai_skill_cardask['@zhuisha_ask'],'@zhuisha_ask','ai_skill_cardask')
sgs.ai_ajustdamage_from['zhuisha']=wrap(sgs.ai_ajustdamage_from['zhuisha'],'zhuisha','ai_ajustdamage_from')
sgs.ai_ajustdamage_from['htms_zangsong']=wrap(sgs.ai_ajustdamage_from['htms_zangsong'],'htms_zangsong','ai_ajustdamage_from')
sgs.ai_fill_skill['htms_zangsong']=wrap(sgs.ai_fill_skill['htms_zangsong'],'htms_zangsong','ai_fill_skill')
sgs.ai_skill_use_func['#htms_zangsongCard']=wrap(sgs.ai_skill_use_func['#htms_zangsongCard'],'#htms_zangsongCard','ai_skill_use_func')
sgs.ai_skill_invoke['shilian']=wrap(sgs.ai_skill_invoke['shilian'],'shilian','ai_skill_invoke')
sgs.ai_skill_invoke['shilianEX']=wrap(sgs.ai_skill_invoke['shilianEX'],'shilianEX','ai_skill_invoke')
sgs.ai_skill_invoke['xianxuefeiteng']=wrap(sgs.ai_skill_invoke['xianxuefeiteng'],'xianxuefeiteng','ai_skill_invoke')
sgs.ai_skill_choice['fengwang']=wrap(sgs.ai_skill_choice['fengwang'],'fengwang','ai_skill_choice')
sgs.ai_skill_cardask['@fengwang_askforequip']=wrap(sgs.ai_skill_cardask['@fengwang_askforequip'],'@fengwang_askforequip','ai_skill_cardask')
sgs.ai_fill_skill['fengwang']=wrap(sgs.ai_fill_skill['fengwang'],'fengwang','ai_fill_skill')
sgs.ai_skill_use_func['#fengwang']=wrap(sgs.ai_skill_use_func['#fengwang'],'#fengwang','ai_skill_use_func')
sgs.ai_skill_choice['newfengwang']=wrap(sgs.ai_skill_choice['newfengwang'],'newfengwang','ai_skill_choice')
sgs.ai_fill_skill['newfengwang']=wrap(sgs.ai_fill_skill['newfengwang'],'newfengwang','ai_fill_skill')
sgs.ai_skill_use_func['#newfengwang']=wrap(sgs.ai_skill_use_func['#newfengwang'],'#newfengwang','ai_skill_use_func')
sgs.ai_fill_skill['wangzhe']=wrap(sgs.ai_fill_skill['wangzhe'],'wangzhe','ai_fill_skill')
sgs.ai_skill_use_func['#wangzhe']=wrap(sgs.ai_skill_use_func['#wangzhe'],'#wangzhe','ai_skill_use_func')
sgs.ai_skill_invoke['doubleslash']=wrap(sgs.ai_skill_invoke['doubleslash'],'doubleslash','ai_skill_invoke')
sgs.ai_skill_cardask['@doubleslash']=wrap(sgs.ai_skill_cardask['@doubleslash'],'@doubleslash','ai_skill_cardask')
sgs.ai_armor_value['doubleslash']=wrap(sgs.ai_armor_value['doubleslash'],'doubleslash','ai_armor_value')
sgs.ai_skill_askforag['betacheater']=wrap(sgs.ai_skill_askforag['betacheater'],'betacheater','ai_skill_askforag')
sgs.ai_fill_skill['handsonic']=wrap(sgs.ai_fill_skill['handsonic'],'handsonic','ai_fill_skill')
sgs.ai_skill_use_func['#handsonicCard']=wrap(sgs.ai_skill_use_func['#handsonicCard'],'#handsonicCard','ai_skill_use_func')
sgs.ai_skill_discard['handsonic']=wrap(sgs.ai_skill_discard['handsonic'],'handsonic','ai_skill_discard')
sgs.ai_skill_cardask['@defencefieldask']=wrap(sgs.ai_skill_cardask['@defencefieldask'],'@defencefieldask','ai_skill_cardask')
sgs.ai_cardneed['defencefield']=wrap(sgs.ai_cardneed['defencefield'],'defencefield','ai_cardneed')
sgs.ai_fill_skill['frozenpuppet']=wrap(sgs.ai_fill_skill['frozenpuppet'],'frozenpuppet','ai_fill_skill')
sgs.ai_skill_use_func['#frozenpuppetCard']=wrap(sgs.ai_skill_use_func['#frozenpuppetCard'],'#frozenpuppetCard','ai_skill_use_func')
sgs.ai_target_revises['@frozenpuppettarg']=wrap(sgs.ai_target_revises['@frozenpuppettarg'],'@frozenpuppettarg','ai_target_revises')
sgs.ai_skill_discard['chuszy']=wrap(sgs.ai_skill_discard['chuszy'],'chuszy','ai_skill_discard')
sgs.ai_slash_prohibit['htms_xiaoshi']=wrap(sgs.ai_slash_prohibit['htms_xiaoshi'],'htms_xiaoshi','ai_slash_prohibit')
sgs.ai_fill_skill['mie']=wrap(sgs.ai_fill_skill['mie'],'mie','ai_fill_skill')
sgs.ai_skill_use_func['#mie']=wrap(sgs.ai_skill_use_func['#mie'],'#mie','ai_skill_use_func')
sgs.ai_fill_skill['diancp']=wrap(sgs.ai_fill_skill['diancp'],'diancp','ai_fill_skill')
sgs.ai_skill_use_func['#diancp']=wrap(sgs.ai_skill_use_func['#diancp'],'#diancp','ai_skill_use_func')
sgs.ai_ajustdamage_to['leij']=wrap(sgs.ai_ajustdamage_to['leij'],'leij','ai_ajustdamage_to')
sgs.ai_skill_cardask['@emeng']=wrap(sgs.ai_skill_cardask['@emeng'],'@emeng','ai_skill_cardask')
sgs.ai_ajustdamage_from['Luayezhan']=wrap(sgs.ai_ajustdamage_from['Luayezhan'],'Luayezhan','ai_ajustdamage_from')
sgs.ai_skill_use['@@jiasugaobai']=wrap(sgs.ai_skill_use['@@jiasugaobai'],'@@jiasugaobai','ai_skill_use')
sgs.ai_skill_invoke['juedoujiasu']=wrap(sgs.ai_skill_invoke['juedoujiasu'],'juedoujiasu','ai_skill_invoke')
sgs.ai_cardneed['juedoujiasu']=wrap(sgs.ai_cardneed['juedoujiasu'],'juedoujiasu','ai_cardneed')
sgs.ai_skill_invoke['jiasuduijue']=wrap(sgs.ai_skill_invoke['jiasuduijue'],'jiasuduijue','ai_skill_invoke')
do local f=sgs.ai_view_as['xiangy'];sgs.ai_view_as['xiangy']=function(...)return proposal(f(...))end end
sgs.ai_skill_playerchosen['xiangy']=wrap(sgs.ai_skill_playerchosen['xiangy'],'xiangy','ai_skill_playerchosen')
sgs.ai_skill_choice['xiangy']=wrap(sgs.ai_skill_choice['xiangy'],'xiangy','ai_skill_choice')
sgs.ai_fill_skill['jiujideqiyuan']=wrap(sgs.ai_fill_skill['jiujideqiyuan'],'jiujideqiyuan','ai_fill_skill')
sgs.ai_skill_use_func['#jiujideqiyuan']=wrap(sgs.ai_skill_use_func['#jiujideqiyuan'],'#jiujideqiyuan','ai_skill_use_func')
sgs.ai_use_revises['jiujideqiyuan']=wrap(sgs.ai_use_revises['jiujideqiyuan'],'jiujideqiyuan','ai_use_revises')
sgs.ai_skill_choice['fazededizao']=wrap(sgs.ai_skill_choice['fazededizao'],'fazededizao','ai_skill_choice')
sgs.ai_skill_invoke['gonglzs']=wrap(sgs.ai_skill_invoke['gonglzs'],'gonglzs','ai_skill_invoke')
sgs.ai_skill_cardchosen['gonglzs']=wrap(sgs.ai_skill_cardchosen['gonglzs'],'gonglzs','ai_skill_cardchosen')
sgs.ai_skill_invoke['shens']=wrap(sgs.ai_skill_invoke['shens'],'shens','ai_skill_invoke')
sgs.ai_skill_playerchosen['hunq']=wrap(sgs.ai_skill_playerchosen['hunq'],'hunq','ai_skill_playerchosen')
sgs.ai_fill_skill['pojgj']=wrap(sgs.ai_fill_skill['pojgj'],'pojgj','ai_fill_skill')
sgs.ai_skill_use_func['#pojgjCard']=wrap(sgs.ai_skill_use_func['#pojgjCard'],'#pojgjCard','ai_skill_use_func')
sgs.ai_fill_skill['LuamuguanVS']=wrap(sgs.ai_fill_skill['LuamuguanVS'],'LuamuguanVS','ai_fill_skill')
sgs.ai_skill_use_func['#LuamuguanCard']=wrap(sgs.ai_skill_use_func['#LuamuguanCard'],'#LuamuguanCard','ai_skill_use_func')
sgs.ai_ajustdamage_from['Luamuguan']=wrap(sgs.ai_ajustdamage_from['Luamuguan'],'Luamuguan','ai_ajustdamage_from')
sgs.ai_ajustdamage_to['Luamuguan']=wrap(sgs.ai_ajustdamage_to['Luamuguan'],'Luamuguan','ai_ajustdamage_to')
do local f=sgs.ai_view_as['soulfire'];sgs.ai_view_as['soulfire']=function(...)return proposal(f(...))end end
sgs.ai_skill_invoke['soulfire']=wrap(sgs.ai_skill_invoke['soulfire'],'soulfire','ai_skill_invoke')
sgs.ai_fill_skill['soulfire']=wrap(sgs.ai_fill_skill['soulfire'],'soulfire','ai_fill_skill')
sgs.ai_fill_skill['jfxl']=wrap(sgs.ai_fill_skill['jfxl'],'jfxl','ai_fill_skill')
sgs.ai_skill_use_func['#jfxl']=wrap(sgs.ai_skill_use_func['#jfxl'],'#jfxl','ai_skill_use_func')
do local f=sgs.ai_view_as['zhenhong'];sgs.ai_view_as['zhenhong']=function(...)return proposal(f(...))end end
sgs.ai_skill_invoke['tprs']=wrap(sgs.ai_skill_invoke['tprs'],'tprs','ai_skill_invoke')
sgs.ai_ajustdamage_from['tprs']=wrap(sgs.ai_ajustdamage_from['tprs'],'tprs','ai_ajustdamage_from')
sgs.ai_skill_invoke['duanzui']=wrap(sgs.ai_skill_invoke['duanzui'],'duanzui','ai_skill_invoke')
sgs.ai_skill_invoke['meihuomoyan']=wrap(sgs.ai_skill_invoke['meihuomoyan'],'meihuomoyan','ai_skill_invoke')
sgs.ai_skill_playerchosen['meihuomoyan']=wrap(sgs.ai_skill_playerchosen['meihuomoyan'],'meihuomoyan','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['kaleidoscope']=wrap(sgs.ai_skill_playerchosen['kaleidoscope'],'kaleidoscope','ai_skill_playerchosen')
sgs.ai_skill_cardask['@haniel']=wrap(sgs.ai_skill_cardask['@haniel'],'@haniel','ai_skill_cardask')
sgs.ai_fill_skill['guancha']=wrap(sgs.ai_fill_skill['guancha'],'guancha','ai_fill_skill')
sgs.ai_skill_use_func['#guancha']=wrap(sgs.ai_skill_use_func['#guancha'],'#guancha','ai_skill_use_func')
sgs.ai_skill_invoke['jiyi']=wrap(sgs.ai_skill_invoke['jiyi'],'jiyi','ai_skill_invoke')
sgs.ai_skill_use['@@jiyi']=wrap(sgs.ai_skill_use['@@jiyi'],'@@jiyi','ai_skill_use')
sgs.ai_skill_choice['jiyi']=wrap(sgs.ai_skill_choice['jiyi'],'jiyi','ai_skill_choice')
sgs.ai_can_damagehp['jiyi']=wrap(sgs.ai_can_damagehp['jiyi'],'jiyi','ai_can_damagehp')
sgs.ai_skill_invoke['Luachicheng']=wrap(sgs.ai_skill_invoke['Luachicheng'],'Luachicheng','ai_skill_invoke')
sgs.ai_ajustdamage_from['lianjiqudong']=wrap(sgs.ai_ajustdamage_from['lianjiqudong'],'lianjiqudong','ai_ajustdamage_from')
sgs.ai_skill_invoke['lunhui1']=wrap(sgs.ai_skill_invoke['lunhui1'],'lunhui1','ai_skill_invoke')
sgs.ai_skill_use['@@lunhui']=wrap(sgs.ai_skill_use['@@lunhui'],'@@lunhui','ai_skill_use')
sgs.ai_hasTuntianEffect_skill['lunhui']=wrap(sgs.ai_hasTuntianEffect_skill['lunhui'],'lunhui','ai_hasTuntianEffect_skill')
sgs.ai_fill_skill['pocdsf']=wrap(sgs.ai_fill_skill['pocdsf'],'pocdsf','ai_fill_skill')
sgs.ai_skill_use_func['#pocdsf']=wrap(sgs.ai_skill_use_func['#pocdsf'],'#pocdsf','ai_skill_use_func')
sgs.ai_can_damagehp['moxing']=wrap(sgs.ai_can_damagehp['moxing'],'moxing','ai_can_damagehp')
sgs.ai_skill_invoke['xiangrui']=wrap(sgs.ai_skill_invoke['xiangrui'],'xiangrui','ai_skill_invoke')
sgs.ai_skill_use['@@xiangrui']=wrap(sgs.ai_skill_use['@@xiangrui'],'@@xiangrui','ai_skill_use')
sgs.ai_can_damagehp['xiangrui']=wrap(sgs.ai_can_damagehp['xiangrui'],'xiangrui','ai_can_damagehp')
sgs.ai_ajustdamage_to['wnlz']=wrap(sgs.ai_ajustdamage_to['wnlz'],'wnlz','ai_ajustdamage_to')
sgs.ai_fill_skill['hxss']=wrap(sgs.ai_fill_skill['hxss'],'hxss','ai_fill_skill')
sgs.ai_fill_skill['Luachuyi']=wrap(sgs.ai_fill_skill['Luachuyi'],'Luachuyi','ai_fill_skill')
do local f=sgs.ai_view_as['Luachuyi'];sgs.ai_view_as['Luachuyi']=function(...)return proposal(f(...))end end
sgs.ai_cardneed['Luachuyi']=wrap(sgs.ai_cardneed['Luachuyi'],'Luachuyi','ai_cardneed')
sgs.ai_skill_invoke['Lualianji']=wrap(sgs.ai_skill_invoke['Lualianji'],'Lualianji','ai_skill_invoke')
sgs.ai_fill_skill['geass']=wrap(sgs.ai_fill_skill['geass'],'geass','ai_fill_skill')
sgs.ai_skill_use_func['#geasstarget']=wrap(sgs.ai_skill_use_func['#geasstarget'],'#geasstarget','ai_skill_use_func')
sgs.ai_skill_askforag['geass']=wrap(sgs.ai_skill_askforag['geass'],'geass','ai_skill_askforag')
sgs.ai_skill_use['@@geass']=wrap(sgs.ai_skill_use['@@geass'],'@@geass','ai_skill_use')
sgs.ai_skill_invoke['znai']=wrap(sgs.ai_skill_invoke['znai'],'znai','ai_skill_invoke')
sgs.ai_skill_choice['znai']=wrap(sgs.ai_skill_choice['znai'],'znai','ai_skill_choice')
sgs.ai_skill_use['@@znai']=wrap(sgs.ai_skill_use['@@znai'],'@@znai','ai_skill_use')
sgs.ai_skill_invoke['changedfate']=wrap(sgs.ai_skill_invoke['changedfate'],'changedfate','ai_skill_invoke')
sgs.ai_skill_invoke['tmsp']=wrap(sgs.ai_skill_invoke['tmsp'],'tmsp','ai_skill_invoke')
sgs.ai_skill_invoke['wangzbk']=wrap(sgs.ai_skill_invoke['wangzbk'],'wangzbk','ai_skill_invoke')
sgs.ai_skill_cardask['@bings-increase']=wrap(sgs.ai_skill_cardask['@bings-increase'],'@bings-increase','ai_skill_cardask')
sgs.ai_skill_cardask['@bings-decrease']=wrap(sgs.ai_skill_cardask['@bings-decrease'],'@bings-decrease','ai_skill_cardask')
sgs.ai_ajustdamage_to['bings']=wrap(sgs.ai_ajustdamage_to['bings'],'bings','ai_ajustdamage_to')
sgs.ai_ajustdamage_from['bings']=wrap(sgs.ai_ajustdamage_from['bings'],'bings','ai_ajustdamage_from')
sgs.ai_skill_choice['guailj']=wrap(sgs.ai_skill_choice['guailj'],'guailj','ai_skill_choice')
sgs.ai_fill_skill['guailj']=wrap(sgs.ai_fill_skill['guailj'],'guailj','ai_fill_skill')
sgs.ai_skill_use_func['#guailj']=wrap(sgs.ai_skill_use_func['#guailj'],'#guailj','ai_skill_use_func')
sgs.ai_skill_invoke['guichan']=wrap(sgs.ai_skill_invoke['guichan'],'guichan','ai_skill_invoke')
sgs.ai_skill_invoke['dafan']=wrap(sgs.ai_skill_invoke['dafan'],'dafan','ai_skill_invoke')
sgs.ai_skill_cardask['@dafanuj-give']=wrap(sgs.ai_skill_cardask['@dafanuj-give'],'@dafanuj-give','ai_skill_cardask')
sgs.ai_skill_choice['juejian']=wrap(sgs.ai_skill_choice['juejian'],'juejian','ai_skill_choice')
sgs.ai_skill_cardask['@smsy']=wrap(sgs.ai_skill_cardask['@smsy'],'@smsy','ai_skill_cardask')
sgs.ai_ajustdamage_from['smsy']=wrap(sgs.ai_ajustdamage_from['smsy'],'smsy','ai_ajustdamage_from')
sgs.ai_fill_skill['jiewq']=wrap(sgs.ai_fill_skill['jiewq'],'jiewq','ai_fill_skill')
sgs.ai_skill_use_func['#jiewq']=wrap(sgs.ai_skill_use_func['#jiewq'],'#jiewq','ai_skill_use_func')
sgs.ai_skill_choice['jiewq']=wrap(sgs.ai_skill_choice['jiewq'],'jiewq','ai_skill_choice')
sgs.ai_ajustdamage_from['jiewq']=wrap(sgs.ai_ajustdamage_from['jiewq'],'jiewq','ai_ajustdamage_from')
sgs.ai_can_damagehp['saiya']=wrap(sgs.ai_can_damagehp['saiya'],'saiya','ai_can_damagehp')
sgs.ai_skill_cardask['@muou']=wrap(sgs.ai_skill_cardask['@muou'],'@muou','ai_skill_cardask')
sgs.ai_skill_playerchosen['mozy']=wrap(sgs.ai_skill_playerchosen['mozy'],'mozy','ai_skill_playerchosen')
sgs.ai_skill_invoke['zsmy']=wrap(sgs.ai_skill_invoke['zsmy'],'zsmy','ai_skill_invoke')
sgs.ai_fill_skill['qsas']=wrap(sgs.ai_fill_skill['qsas'],'qsas','ai_fill_skill')
sgs.ai_skill_use_func['#qsas']=wrap(sgs.ai_skill_use_func['#qsas'],'#qsas','ai_skill_use_func')
sgs.ai_ajustdamage_from['nirendao']=wrap(sgs.ai_ajustdamage_from['nirendao'],'nirendao','ai_ajustdamage_from')
sgs.ai_fill_skill['nidaoren']=wrap(sgs.ai_fill_skill['nidaoren'],'nidaoren','ai_fill_skill')
sgs.ai_skill_use_func['#nidaorenCard']=wrap(sgs.ai_skill_use_func['#nidaorenCard'],'#nidaorenCard','ai_skill_use_func')
sgs.ai_skill_choice['nidaorendraw']=wrap(sgs.ai_skill_choice['nidaorendraw'],'nidaorendraw','ai_skill_choice')
sgs.ai_fill_skill['badaozhai']=wrap(sgs.ai_fill_skill['badaozhai'],'badaozhai','ai_fill_skill')
sgs.ai_skill_use_func['#badaozhaiCard']=wrap(sgs.ai_skill_use_func['#badaozhaiCard'],'#badaozhaiCard','ai_skill_use_func')
sgs.ai_fill_skill['feils2']=wrap(sgs.ai_fill_skill['feils2'],'feils2','ai_fill_skill')
sgs.ai_skill_use_func['#feils2']=wrap(sgs.ai_skill_use_func['#feils2'],'#feils2','ai_skill_use_func')
sgs.ai_skill_invoke['jiushu']=wrap(sgs.ai_skill_invoke['jiushu'],'jiushu','ai_skill_invoke')
sgs.ai_skill_use['@@jiushu']=wrap(sgs.ai_skill_use['@@jiushu'],'@@jiushu','ai_skill_use')
sgs.ai_skill_invoke['xieheng']=wrap(sgs.ai_skill_invoke['xieheng'],'xieheng','ai_skill_invoke')
sgs.ai_skill_playerchosen['xieheng']=wrap(sgs.ai_skill_playerchosen['xieheng'],'xieheng','ai_skill_playerchosen')
sgs.ai_skill_cardask['@xieheng']=wrap(sgs.ai_skill_cardask['@xieheng'],'@xieheng','ai_skill_cardask')
sgs.ai_skill_invoke['tjdzf']=wrap(sgs.ai_skill_invoke['tjdzf'],'tjdzf','ai_skill_invoke')
sgs.ai_skill_invoke['qrdag']=wrap(sgs.ai_skill_invoke['qrdag'],'qrdag','ai_skill_invoke')
sgs.ai_skill_choice['qrdag']=wrap(sgs.ai_skill_choice['qrdag'],'qrdag','ai_skill_choice')
sgs.ai_skill_invoke['fenmao']=wrap(sgs.ai_skill_invoke['fenmao'],'fenmao','ai_skill_invoke')
sgs.ai_skill_cardask['@fenmao-qp']=wrap(sgs.ai_skill_cardask['@fenmao-qp'],'@fenmao-qp','ai_skill_cardask')
sgs.ai_fill_skill['changgui']=wrap(sgs.ai_fill_skill['changgui'],'changgui','ai_fill_skill')
sgs.ai_skill_use_func['#changgui']=wrap(sgs.ai_skill_use_func['#changgui'],'#changgui','ai_skill_use_func')
sgs.ai_fill_skill['heihua']=wrap(sgs.ai_fill_skill['heihua'],'heihua','ai_fill_skill')
sgs.ai_skill_use_func['#heihua']=wrap(sgs.ai_skill_use_func['#heihua'],'#heihua','ai_skill_use_func')
sgs.ai_skill_use['@@maware']=wrap(sgs.ai_skill_use['@@maware'],'@@maware','ai_skill_use')
sgs.ai_skill_choice['samsara']=wrap(sgs.ai_skill_choice['samsara'],'samsara','ai_skill_choice')
sgs.ai_skill_use['@@kuixin']=wrap(sgs.ai_skill_use['@@kuixin'],'@@kuixin','ai_skill_use')
sgs.ai_skill_invoke['slash_defence']=wrap(sgs.ai_skill_invoke['slash_defence'],'slash_defence','ai_skill_invoke')
sgs.ai_skill_invoke['zhanxianfanyu']=wrap(sgs.ai_skill_invoke['zhanxianfanyu'],'zhanxianfanyu','ai_skill_invoke')
sgs.ai_skill_playerchosen['zhanxianfanyu']=wrap(sgs.ai_skill_playerchosen['zhanxianfanyu'],'zhanxianfanyu','ai_skill_playerchosen')
sgs.ai_skill_invoke['jixieshen']=wrap(sgs.ai_skill_invoke['jixieshen'],'jixieshen','ai_skill_invoke')
sgs.ai_skill_choice['jixieshen']=wrap(sgs.ai_skill_choice['jixieshen'],'jixieshen','ai_skill_choice')
sgs.ai_skill_playerchosen['jixieshen']=wrap(sgs.ai_skill_playerchosen['jixieshen'],'jixieshen','ai_skill_playerchosen')
sgs.ai_skill_invoke['jixieshen:fixmachine']=wrap(sgs.ai_skill_invoke['jixieshen:fixmachine'],'jixieshen:fixmachine','ai_skill_invoke')
sgs.ai_skill_choice['jixieshenfixmachine']=wrap(sgs.ai_skill_choice['jixieshenfixmachine'],'jixieshenfixmachine','ai_skill_choice')
sgs.ai_fill_skill['jixieshenchain']=wrap(sgs.ai_fill_skill['jixieshenchain'],'jixieshenchain','ai_fill_skill')
do local f=sgs.ai_view_as['jixieshenchain'];sgs.ai_view_as['jixieshenchain']=function(...)return proposal(f(...))end end
sgs.ai_ajustdamage_to['jixieshendefense']=wrap(sgs.ai_ajustdamage_to['jixieshendefense'],'jixieshendefense','ai_ajustdamage_to')
sgs.ai_skill_invoke['jixieshenslash']=wrap(sgs.ai_skill_invoke['jixieshenslash'],'jixieshenslash','ai_skill_invoke')
sgs.ai_skill_playerchosen['loyal_inu']=wrap(sgs.ai_skill_playerchosen['loyal_inu'],'loyal_inu','ai_skill_playerchosen')
sgs.ai_skill_choice['kikann']=wrap(sgs.ai_skill_choice['kikann'],'kikann','ai_skill_choice')
sgs.ai_skill_choice['jueduiyazhi']=wrap(sgs.ai_skill_choice['jueduiyazhi'],'jueduiyazhi','ai_skill_choice')
sgs.ai_fill_skill['jueduiyazhi']=wrap(sgs.ai_fill_skill['jueduiyazhi'],'jueduiyazhi','ai_fill_skill')
sgs.ai_skill_use_func['#jueduiyazhiCard']=wrap(sgs.ai_skill_use_func['#jueduiyazhiCard'],'#jueduiyazhiCard','ai_skill_use_func')
sgs.ai_fill_skill['guangzijupao']=wrap(sgs.ai_fill_skill['guangzijupao'],'guangzijupao','ai_fill_skill')
sgs.ai_skill_use_func['#guangzijupaoCard']=wrap(sgs.ai_skill_use_func['#guangzijupaoCard'],'#guangzijupaoCard','ai_skill_use_func')
sgs.ai_skill_invoke['Luayanhu']=wrap(sgs.ai_skill_invoke['Luayanhu'],'Luayanhu','ai_skill_invoke')
sgs.ai_skill_invoke['xinsuo']=wrap(sgs.ai_skill_invoke['xinsuo'],'xinsuo','ai_skill_invoke')
sgs.ai_skill_choice['xinsuo']=wrap(sgs.ai_skill_choice['xinsuo'],'xinsuo','ai_skill_choice')
sgs.ai_skill_cardask['@fengfu-discard']=wrap(sgs.ai_skill_cardask['@fengfu-discard'],'@fengfu-discard','ai_skill_cardask')
sgs.ai_fill_skill['yohane']=wrap(sgs.ai_fill_skill['yohane'],'yohane','ai_fill_skill')
sgs.ai_skill_use_func['#yohane']=wrap(sgs.ai_skill_use_func['#yohane'],'#yohane','ai_skill_use_func')
sgs.ai_skill_cardask['#yohane-distribute']=wrap(sgs.ai_skill_cardask['#yohane-distribute'],'#yohane-distribute','ai_skill_cardask')
sgs.ai_skill_playerchosen['yohane']=wrap(sgs.ai_skill_playerchosen['yohane'],'yohane','ai_skill_playerchosen')
sgs.ai_skill_choice['yohane']=wrap(sgs.ai_skill_choice['yohane'],'yohane','ai_skill_choice')
sgs.ai_skill_choice['fanyi']=wrap(sgs.ai_skill_choice['fanyi'],'fanyi','ai_skill_choice')
sgs.ai_skill_invoke['jihang']=wrap(sgs.ai_skill_invoke['jihang'],'jihang','ai_skill_invoke')
sgs.ai_skill_playerchosen['jihang']=wrap(sgs.ai_skill_playerchosen['jihang'],'jihang','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['anni']=wrap(sgs.ai_skill_playerchosen['anni'],'anni','ai_skill_playerchosen')
sgs.ai_skill_choice['anni']=wrap(sgs.ai_skill_choice['anni'],'anni','ai_skill_choice')
sgs.ai_skill_choice['jiaoxing']=wrap(sgs.ai_skill_choice['jiaoxing'],'jiaoxing','ai_skill_choice')
sgs.ai_skill_use['@@jiaoxing']=wrap(sgs.ai_skill_use['@@jiaoxing'],'@@jiaoxing','ai_skill_use')
sgs.ai_skill_choice['sandun']=wrap(sgs.ai_skill_choice['sandun'],'sandun','ai_skill_choice')
sgs.ai_fill_skill['xieyan']=wrap(sgs.ai_fill_skill['xieyan'],'xieyan','ai_fill_skill')
sgs.ai_skill_use_func['#xieyancard']=wrap(sgs.ai_skill_use_func['#xieyancard'],'#xieyancard','ai_skill_use_func')
sgs.ai_skill_invoke['sugong']=wrap(sgs.ai_skill_invoke['sugong'],'sugong','ai_skill_invoke')
sgs.ai_skill_choice['sugong']=wrap(sgs.ai_skill_choice['sugong'],'sugong','ai_skill_choice')
sgs.ai_skill_invoke['fuzou']=wrap(sgs.ai_skill_invoke['fuzou'],'fuzou','ai_skill_invoke')
sgs.ai_skill_playerchosen['fuzou']=wrap(sgs.ai_skill_playerchosen['fuzou'],'fuzou','ai_skill_playerchosen')
sgs.ai_card_priority['haiyin']=wrap(sgs.ai_card_priority['haiyin'],'haiyin','ai_card_priority')
sgs.ai_skill_invoke['tianqu']=wrap(sgs.ai_skill_invoke['tianqu'],'tianqu','ai_skill_invoke')
sgs.ai_skill_playerchosen['tianqu_from']=wrap(sgs.ai_skill_playerchosen['tianqu_from'],'tianqu_from','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['tianqu_to']=wrap(sgs.ai_skill_playerchosen['tianqu_to'],'tianqu_to','ai_skill_playerchosen')
sgs.ai_can_damagehp['tianqu']=wrap(sgs.ai_can_damagehp['tianqu'],'tianqu','ai_can_damagehp')
sgs.ai_skill_invoke['htms_wanlan']=wrap(sgs.ai_skill_invoke['htms_wanlan'],'htms_wanlan','ai_skill_invoke')
sgs.ai_skill_playerchosen['htms_wanlan']=wrap(sgs.ai_skill_playerchosen['htms_wanlan'],'htms_wanlan','ai_skill_playerchosen')
sgs.ai_skill_discard['htms_wanlan']=wrap(sgs.ai_skill_discard['htms_wanlan'],'htms_wanlan','ai_skill_discard')
sgs.ai_skill_choice['htms_wanlan']=wrap(sgs.ai_skill_choice['htms_wanlan'],'htms_wanlan','ai_skill_choice')
sgs.ai_skill_playerchosen['huanggui']=wrap(sgs.ai_skill_playerchosen['huanggui'],'huanggui','ai_skill_playerchosen')
sgs.ai_skill_invoke['fuqian']=wrap(sgs.ai_skill_invoke['fuqian'],'fuqian','ai_skill_invoke')
sgs.ai_fill_skill['zangsong']=wrap(sgs.ai_fill_skill['zangsong'],'zangsong','ai_fill_skill')
sgs.ai_skill_use_func['#zangsongCard']=wrap(sgs.ai_skill_use_func['#zangsongCard'],'#zangsongCard','ai_skill_use_func')
sgs.ai_skill_invoke['jianwushu']=wrap(sgs.ai_skill_invoke['jianwushu'],'jianwushu','ai_skill_invoke')
sgs.ai_skill_invoke['huoliquankai']=wrap(sgs.ai_skill_invoke['huoliquankai'],'huoliquankai','ai_skill_invoke')
sgs.ai_skill_playerchosen['huoliquankai']=wrap(sgs.ai_skill_playerchosen['huoliquankai'],'huoliquankai','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['juexingmoshen']=wrap(sgs.ai_skill_playerchosen['juexingmoshen'],'juexingmoshen','ai_skill_playerchosen')
sgs.ai_skill_invoke['wujinzhishu']=wrap(sgs.ai_skill_invoke['wujinzhishu'],'wujinzhishu','ai_skill_invoke')
sgs.ai_fill_skill['chunrijilu']=wrap(sgs.ai_fill_skill['chunrijilu'],'chunrijilu','ai_fill_skill')
sgs.ai_skill_use_func['#chunrijilu']=wrap(sgs.ai_skill_use_func['#chunrijilu'],'#chunrijilu','ai_skill_use_func')
sgs.ai_skill_use['@@chunrijilu!']=wrap(sgs.ai_skill_use['@@chunrijilu!'],'@@chunrijilu!','ai_skill_use')
sgs.ai_skill_use['@@haite']=wrap(sgs.ai_skill_use['@@haite'],'@@haite','ai_skill_use')
sgs.ai_fill_skill['yueying']=wrap(sgs.ai_fill_skill['yueying'],'yueying','ai_fill_skill')
sgs.ai_skill_use_func['#yueying']=wrap(sgs.ai_skill_use_func['#yueying'],'#yueying','ai_skill_use_func')
sgs.ai_cardneed['yueying']=wrap(sgs.ai_cardneed['yueying'],'yueying','ai_cardneed')
sgs.ai_ajustdamage_to['hmrleiji']=wrap(sgs.ai_ajustdamage_to['hmrleiji'],'hmrleiji','ai_ajustdamage_to')
sgs.ai_skill_invoke['jiyidiejia']=wrap(sgs.ai_skill_invoke['jiyidiejia'],'jiyidiejia','ai_skill_invoke')
sgs.ai_skill_invoke['dushe']=wrap(sgs.ai_skill_invoke['dushe'],'dushe','ai_skill_invoke')
sgs.ai_fill_skill['zuzhou']=wrap(sgs.ai_fill_skill['zuzhou'],'zuzhou','ai_fill_skill')
sgs.ai_skill_use_func['#zuzhouCard']=wrap(sgs.ai_skill_use_func['#zuzhouCard'],'#zuzhouCard','ai_skill_use_func')
sgs.ai_skill_use['@@xiangyangshi']=wrap(sgs.ai_skill_use['@@xiangyangshi'],'@@xiangyangshi','ai_skill_use')
sgs.ai_cardneed['xiangyangshi']=wrap(sgs.ai_cardneed['xiangyangshi'],'xiangyangshi','ai_cardneed')
sgs.ai_fill_skill['shengdanny']=wrap(sgs.ai_fill_skill['shengdanny'],'shengdanny','ai_fill_skill')
sgs.ai_skill_use_func['#shengdanny']=wrap(sgs.ai_skill_use_func['#shengdanny'],'#shengdanny','ai_skill_use_func')
sgs.ai_cardneed['shengdanny']=wrap(sgs.ai_cardneed['shengdanny'],'shengdanny','ai_cardneed')
sgs.ai_skill_invoke['leijijingyan']=wrap(sgs.ai_skill_invoke['leijijingyan'],'leijijingyan','ai_skill_invoke')
sgs.ai_cardneed['leijijingyan']=wrap(sgs.ai_cardneed['leijijingyan'],'leijijingyan','ai_cardneed')
sgs.ai_skill_invoke['suoersiman']=wrap(sgs.ai_skill_invoke['suoersiman'],'suoersiman','ai_skill_invoke')
sgs.ai_skill_playerchosen['suoersiman']=wrap(sgs.ai_skill_playerchosen['suoersiman'],'suoersiman','ai_skill_playerchosen')
sgs.ai_skill_invoke['yinbiman']=wrap(sgs.ai_skill_invoke['yinbiman'],'yinbiman','ai_skill_invoke')
sgs.ai_skill_invoke['jujiman']=wrap(sgs.ai_skill_invoke['jujiman'],'jujiman','ai_skill_invoke')
sgs.ai_skill_playerchosen['jujiman']=wrap(sgs.ai_skill_playerchosen['jujiman'],'jujiman','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['mingduan_put']=wrap(sgs.ai_skill_playerchosen['mingduan_put'],'mingduan_put','ai_skill_playerchosen')
sgs.ai_skill_cardask['@mingduanqiuh']=wrap(sgs.ai_skill_cardask['@mingduanqiuh'],'@mingduanqiuh','ai_skill_cardask')
sgs.ai_fill_skill['yushicp']=wrap(sgs.ai_fill_skill['yushicp'],'yushicp','ai_fill_skill')
sgs.ai_skill_use_func['#yushicp']=wrap(sgs.ai_skill_use_func['#yushicp'],'#yushicp','ai_skill_use_func')
sgs.ai_guhuo_card['yushicp']=wrap(sgs.ai_guhuo_card['yushicp'],'yushicp','ai_guhuo_card')
sgs.ai_skill_invoke['wushitexing']=wrap(sgs.ai_skill_invoke['wushitexing'],'wushitexing','ai_skill_invoke')
sgs.ai_skill_invoke['shanyao']=wrap(sgs.ai_skill_invoke['shanyao'],'shanyao','ai_skill_invoke')
sgs.ai_card_priority['shanyao']=wrap(sgs.ai_card_priority['shanyao'],'shanyao','ai_card_priority')
sgs.ai_skill_playerchosen['jiansu']=wrap(sgs.ai_skill_playerchosen['jiansu'],'jiansu','ai_skill_playerchosen')
sgs.ai_fill_skill['yugao']=wrap(sgs.ai_fill_skill['yugao'],'yugao','ai_fill_skill')
sgs.ai_skill_use_func['#yugao']=wrap(sgs.ai_skill_use_func['#yugao'],'#yugao','ai_skill_use_func')
sgs.ai_skill_use['@@yugao']=wrap(sgs.ai_skill_use['@@yugao'],'@@yugao','ai_skill_use')
sgs.ai_skill_invoke['yugao']=wrap(sgs.ai_skill_invoke['yugao'],'yugao','ai_skill_invoke')
sgs.ai_skill_askforag['yugao']=wrap(sgs.ai_skill_askforag['yugao'],'yugao','ai_skill_askforag')
sgs.ai_card_priority['guaidao']=wrap(sgs.ai_card_priority['guaidao'],'guaidao','ai_card_priority')
sgs.ai_skill_invoke['weituo']=wrap(sgs.ai_skill_invoke['weituo'],'weituo','ai_skill_invoke')
sgs.ai_skill_invoke['weituo11']=wrap(sgs.ai_skill_invoke['weituo11'],'weituo11','ai_skill_invoke')
sgs.ai_skill_playerchosen['zhihouz']=wrap(sgs.ai_skill_playerchosen['zhihouz'],'zhihouz','ai_skill_playerchosen')
sgs.ai_skill_invoke['zhengdao']=wrap(sgs.ai_skill_invoke['zhengdao'],'zhengdao','ai_skill_invoke')
sgs.ai_skill_playerchosen['zhengdao']=wrap(sgs.ai_skill_playerchosen['zhengdao'],'zhengdao','ai_skill_playerchosen')
sgs.ai_skill_invoke['jiqiangs']=wrap(sgs.ai_skill_invoke['jiqiangs'],'jiqiangs','ai_skill_invoke')
sgs.ai_cardneed['lanyushanbi']=wrap(sgs.ai_cardneed['lanyushanbi'],'lanyushanbi','ai_cardneed')
sgs.ai_fill_skill['jibanvs']=wrap(sgs.ai_fill_skill['jibanvs'],'jibanvs','ai_fill_skill')
sgs.ai_skill_use_func['#jibanhyCard']=wrap(sgs.ai_skill_use_func['#jibanhyCard'],'#jibanhyCard','ai_skill_use_func')
sgs.ai_skill_playerchosen['weixiaojn']=wrap(sgs.ai_skill_playerchosen['weixiaojn'],'weixiaojn','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['nvzidao']=wrap(sgs.ai_skill_playerchosen['nvzidao'],'nvzidao','ai_skill_playerchosen')
sgs.ai_skill_use['@@nvzidao']=wrap(sgs.ai_skill_use['@@nvzidao'],'@@nvzidao','ai_skill_use')
sgs.ai_skill_cardchosen['nvzidaoCard']=wrap(sgs.ai_skill_cardchosen['nvzidaoCard'],'nvzidaoCard','ai_skill_cardchosen')
sgs.ai_skill_playerchosen['nvzidaoCard']=wrap(sgs.ai_skill_playerchosen['nvzidaoCard'],'nvzidaoCard','ai_skill_playerchosen')
sgs.ai_card_priority['nvzidao']=wrap(sgs.ai_card_priority['nvzidao'],'nvzidao','ai_card_priority')
sgs.ai_card_priority['weixiaojn']=wrap(sgs.ai_card_priority['weixiaojn'],'weixiaojn','ai_card_priority')
sgs.ai_skill_invoke['chuanxiao']=wrap(sgs.ai_skill_invoke['chuanxiao'],'chuanxiao','ai_skill_invoke')
sgs.ai_fill_skill['duandai']=wrap(sgs.ai_fill_skill['duandai'],'duandai','ai_fill_skill')
sgs.ai_skill_use_func['#duandai']=wrap(sgs.ai_skill_use_func['#duandai'],'#duandai','ai_skill_use_func')
sgs.ai_skill_cardask['@duandai']=wrap(sgs.ai_skill_cardask['@duandai'],'@duandai','ai_skill_cardask')
sgs.ai_skill_choice['duandai']=wrap(sgs.ai_skill_choice['duandai'],'duandai','ai_skill_choice')
sgs.ai_skill_cardchosen['duandai']=wrap(sgs.ai_skill_cardchosen['duandai'],'duandai','ai_skill_cardchosen')
do local f=sgs.ai_view_as['tucao'];sgs.ai_view_as['tucao']=function(...)return proposal(f(...))end end
sgs.ai_skill_playerchosen['tucao']=wrap(sgs.ai_skill_playerchosen['tucao'],'tucao','ai_skill_playerchosen')
sgs.ai_skill_choice['#tucaoxx']=wrap(sgs.ai_skill_choice['#tucaoxx'],'#tucaoxx','ai_skill_choice')
sgs.ai_cardneed['tucao']=wrap(sgs.ai_cardneed['tucao'],'tucao','ai_cardneed')
sgs.ai_fill_skill['wangwei']=wrap(sgs.ai_fill_skill['wangwei'],'wangwei','ai_fill_skill')
sgs.ai_skill_use_func['#wangwei']=wrap(sgs.ai_skill_use_func['#wangwei'],'#wangwei','ai_skill_use_func')
sgs.ai_skill_choice['qidao']=wrap(sgs.ai_skill_choice['qidao'],'qidao','ai_skill_choice')
sgs.ai_skill_playerchosen['qiyuan']=wrap(sgs.ai_skill_playerchosen['qiyuan'],'qiyuan','ai_skill_playerchosen')
sgs.ai_fill_skill['qiyuan']=wrap(sgs.ai_fill_skill['qiyuan'],'qiyuan','ai_fill_skill')
sgs.ai_skill_use_func['#qiyuan']=wrap(sgs.ai_skill_use_func['#qiyuan'],'#qiyuan','ai_skill_use_func')
do local f=sgs.ai_view_as['LuaLeishi'];sgs.ai_view_as['LuaLeishi']=function(...)return proposal(f(...))end end
sgs.ai_fill_skill['LuaLeishi']=wrap(sgs.ai_fill_skill['LuaLeishi'],'LuaLeishi','ai_fill_skill')
sgs.ai_skill_invoke['Luayuanxing']=wrap(sgs.ai_skill_invoke['Luayuanxing'],'Luayuanxing','ai_skill_invoke')
sgs.ai_skill_use['@@Luayuanling']=wrap(sgs.ai_skill_use['@@Luayuanling'],'@@Luayuanling','ai_skill_use')
sgs.ai_skill_invoke['Luashenyi']=wrap(sgs.ai_skill_invoke['Luashenyi'],'Luashenyi','ai_skill_invoke')
sgs.ai_skill_playerchosen['Luashenyi']=wrap(sgs.ai_skill_playerchosen['Luashenyi'],'Luashenyi','ai_skill_playerchosen')
sgs.ai_skill_invoke['luajiejie']=wrap(sgs.ai_skill_invoke['luajiejie'],'luajiejie','ai_skill_invoke')
sgs.ai_fill_skill['luakuaiqing']=wrap(sgs.ai_fill_skill['luakuaiqing'],'luakuaiqing','ai_fill_skill')
sgs.ai_skill_use_func['#luakuaiqing']=wrap(sgs.ai_skill_use_func['#luakuaiqing'],'#luakuaiqing','ai_skill_use_func')
sgs.ai_fill_skill['luajieao']=wrap(sgs.ai_fill_skill['luajieao'],'luajieao','ai_fill_skill')
sgs.ai_skill_use_func['#luajieao']=wrap(sgs.ai_skill_use_func['#luajieao'],'#luajieao','ai_skill_use_func')
sgs.ai_skill_invoke['luajinlun']=wrap(sgs.ai_skill_invoke['luajinlun'],'luajinlun','ai_skill_invoke')
sgs.ai_skill_playerchosen['luajinlun']=wrap(sgs.ai_skill_playerchosen['luajinlun'],'luajinlun','ai_skill_playerchosen')
sgs.ai_skill_invoke['empaidui']=wrap(sgs.ai_skill_invoke['empaidui'],'empaidui','ai_skill_invoke')
sgs.ai_skill_use['@@empaidui']=wrap(sgs.ai_skill_use['@@empaidui'],'@@empaidui','ai_skill_use')
sgs.ai_skill_invoke['yftuji']=wrap(sgs.ai_skill_invoke['yftuji'],'yftuji','ai_skill_invoke')
sgs.ai_can_damagehp['zhongerhx']=wrap(sgs.ai_can_damagehp['zhongerhx'],'zhongerhx','ai_can_damagehp')
sgs.ai_skill_invoke['zhongerhx']=wrap(sgs.ai_skill_invoke['zhongerhx'],'zhongerhx','ai_skill_invoke')
sgs.ai_skill_askforag['zhongerhx']=wrap(sgs.ai_skill_askforag['zhongerhx'],'zhongerhx','ai_skill_askforag')
sgs.ai_skill_use['@@zhongerhx']=wrap(sgs.ai_skill_use['@@zhongerhx'],'@@zhongerhx','ai_skill_use')
sgs.ai_skill_invoke['hanrenzd']=wrap(sgs.ai_skill_invoke['hanrenzd'],'hanrenzd','ai_skill_invoke')
sgs.ai_skill_invoke['bingfengzd']=wrap(sgs.ai_skill_invoke['bingfengzd'],'bingfengzd','ai_skill_invoke')
sgs.ai_can_damagehp['bingfengzd']=wrap(sgs.ai_can_damagehp['bingfengzd'],'bingfengzd','ai_can_damagehp')
sgs.ai_skill_choice['hezibz']=wrap(sgs.ai_skill_choice['hezibz'],'hezibz','ai_skill_choice')
sgs.ai_skill_cardask['@duancai']=wrap(sgs.ai_skill_cardask['@duancai'],'@duancai','ai_skill_cardask')
sgs.ai_skill_cardask['@duancaiex']=wrap(sgs.ai_skill_cardask['@duancaiex'],'@duancaiex','ai_skill_cardask')
sgs.ai_skill_invoke['midie']=wrap(sgs.ai_skill_invoke['midie'],'midie','ai_skill_invoke')
sgs.ai_canNiepan_skill['midie']=wrap(sgs.ai_canNiepan_skill['midie'],'midie','ai_canNiepan_skill')
sgs.ai_skill_invoke['tongzhouqg']=wrap(sgs.ai_skill_invoke['tongzhouqg'],'tongzhouqg','ai_skill_invoke')
sgs.ai_skill_cardask['@tongzhouqg']=wrap(sgs.ai_skill_cardask['@tongzhouqg'],'@tongzhouqg','ai_skill_cardask')
sgs.ai_skill_use['@@qgjiesi']=wrap(sgs.ai_skill_use['@@qgjiesi'],'@@qgjiesi','ai_skill_use')
sgs.ai_fill_skill['zjyizhen']=wrap(sgs.ai_fill_skill['zjyizhen'],'zjyizhen','ai_fill_skill')
sgs.ai_skill_use_func['#zjyizhenCard']=wrap(sgs.ai_skill_use_func['#zjyizhenCard'],'#zjyizhenCard','ai_skill_use_func')
sgs.ai_use_revises['zjyizhen']=wrap(sgs.ai_use_revises['zjyizhen'],'zjyizhen','ai_use_revises')
sgs.ai_cardneed['zjyizhen']=wrap(sgs.ai_cardneed['zjyizhen'],'zjyizhen','ai_cardneed')
sgs.ai_skill_invoke['zjmoshuxif']=wrap(sgs.ai_skill_invoke['zjmoshuxif'],'zjmoshuxif','ai_skill_invoke')
sgs.ai_skill_cardask['@zjmoshuxif']=wrap(sgs.ai_skill_cardask['@zjmoshuxif'],'@zjmoshuxif','ai_skill_cardask')
sgs.ai_skill_invoke['zjruoshi']=wrap(sgs.ai_skill_invoke['zjruoshi'],'zjruoshi','ai_skill_invoke')
sgs.ai_skill_choice['zjruoshi']=wrap(sgs.ai_skill_choice['zjruoshi'],'zjruoshi','ai_skill_choice')
sgs.ai_skill_choice['zjaojiaol']=wrap(sgs.ai_skill_choice['zjaojiaol'],'zjaojiaol','ai_skill_choice')
sgs.ai_skill_cardchosen['zjaojiaol']=wrap(sgs.ai_skill_cardchosen['zjaojiaol'],'zjaojiaol','ai_skill_cardchosen')
sgs.ai_fill_skill['zjaojiaol']=wrap(sgs.ai_fill_skill['zjaojiaol'],'zjaojiaol','ai_fill_skill')
sgs.ai_skill_use_func['#zjaojiaol']=wrap(sgs.ai_skill_use_func['#zjaojiaol'],'#zjaojiaol','ai_skill_use_func')
sgs.ai_skill_choice['puzou']=wrap(sgs.ai_skill_choice['puzou'],'puzou','ai_skill_choice')
sgs.ai_skill_choice['htms_weiyi']=wrap(sgs.ai_skill_choice['htms_weiyi'],'htms_weiyi','ai_skill_choice')
sgs.ai_skill_cardask['lualushouC']=wrap(sgs.ai_skill_cardask['lualushouC'],'lualushouC','ai_skill_cardask')
sgs.ai_skill_cardask['lualushouB']=wrap(sgs.ai_skill_cardask['lualushouB'],'lualushouB','ai_skill_cardask')
sgs.ai_skill_playerchosen['lualushou']=wrap(sgs.ai_skill_playerchosen['lualushou'],'lualushou','ai_skill_playerchosen')
sgs.ai_skill_cardask['lualushouA']=wrap(sgs.ai_skill_cardask['lualushouA'],'lualushouA','ai_skill_cardask')
sgs.ai_skill_invoke['huazang']=wrap(sgs.ai_skill_invoke['huazang'],'huazang','ai_skill_invoke')
sgs.ai_fill_skill['zchize']=wrap(sgs.ai_fill_skill['zchize'],'zchize','ai_fill_skill')
sgs.ai_skill_use_func['#zchizeCard']=wrap(sgs.ai_skill_use_func['#zchizeCard'],'#zchizeCard','ai_skill_use_func')
sgs.ai_skill_invoke['gaoling']=wrap(sgs.ai_skill_invoke['gaoling'],'gaoling','ai_skill_invoke')
sgs.ai_target_revises['gaoling']=wrap(sgs.ai_target_revises['gaoling'],'gaoling','ai_target_revises')
sgs.ai_skill_invoke['zhengjiu']=wrap(sgs.ai_skill_invoke['zhengjiu'],'zhengjiu','ai_skill_invoke')
sgs.ai_skill_playerchosen['zhengjiu']=wrap(sgs.ai_skill_playerchosen['zhengjiu'],'zhengjiu','ai_skill_playerchosen')
sgs.ai_fill_skill['molwf']=wrap(sgs.ai_fill_skill['molwf'],'molwf','ai_fill_skill')
sgs.ai_skill_use_func['#molwf']=wrap(sgs.ai_skill_use_func['#molwf'],'#molwf','ai_skill_use_func')
sgs.ai_ajustdamage_from['molwf']=wrap(sgs.ai_ajustdamage_from['molwf'],'molwf','ai_ajustdamage_from')
sgs.ai_fill_skill['html_shisheng']=wrap(sgs.ai_fill_skill['html_shisheng'],'html_shisheng','ai_fill_skill')
sgs.ai_skill_use_func['#html_shishengCard']=wrap(sgs.ai_skill_use_func['#html_shishengCard'],'#html_shishengCard','ai_skill_use_func')
sgs.ai_fill_skill['ujyaozhan']=wrap(sgs.ai_fill_skill['ujyaozhan'],'ujyaozhan','ai_fill_skill')
sgs.ai_skill_use_func['#ujyaozhanCard']=wrap(sgs.ai_skill_use_func['#ujyaozhanCard'],'#ujyaozhanCard','ai_skill_use_func')
sgs.ai_skill_choice['Sdorica_FuWei']=wrap(sgs.ai_skill_choice['Sdorica_FuWei'],'Sdorica_FuWei','ai_skill_choice')
sgs.ai_skill_discard['Sdorica_FuWei']=wrap(sgs.ai_skill_discard['Sdorica_FuWei'],'Sdorica_FuWei','ai_skill_discard')
sgs.ai_fill_skill['Sdorica_MiLing']=wrap(sgs.ai_fill_skill['Sdorica_MiLing'],'Sdorica_MiLing','ai_fill_skill')
sgs.ai_skill_use_func['#Sdorica_MiLingCard']=wrap(sgs.ai_skill_use_func['#Sdorica_MiLingCard'],'#Sdorica_MiLingCard','ai_skill_use_func')
sgs.ai_fill_skill['void']=wrap(sgs.ai_fill_skill['void'],'void','ai_fill_skill')
sgs.ai_skill_use_func['#void']=wrap(sgs.ai_skill_use_func['#void'],'#void','ai_skill_use_func')
sgs.ai_card_priority['void']=wrap(sgs.ai_card_priority['void'],'void','ai_card_priority')
sgs.ai_skill_choice['wangguo']=wrap(sgs.ai_skill_choice['wangguo'],'wangguo','ai_skill_choice')
sgs.ai_skill_invoke['lsqd']=wrap(sgs.ai_skill_invoke['lsqd'],'lsqd','ai_skill_invoke')
sgs.ai_skill_choice['lsqd']=wrap(sgs.ai_skill_choice['lsqd'],'lsqd','ai_skill_choice')
sgs.ai_skill_cardask['@lsqd']=wrap(sgs.ai_skill_cardask['@lsqd'],'@lsqd','ai_skill_cardask')
sgs.ai_skill_playerchosen['tscg']=wrap(sgs.ai_skill_playerchosen['tscg'],'tscg','ai_skill_playerchosen')
sgs.ai_fill_skill['wzgz']=wrap(sgs.ai_fill_skill['wzgz'],'wzgz','ai_fill_skill')
sgs.ai_skill_use_func['#wzgzcard']=wrap(sgs.ai_skill_use_func['#wzgzcard'],'#wzgzcard','ai_skill_use_func')
sgs.ai_ajustdamage_from['tcmfs']=wrap(sgs.ai_ajustdamage_from['tcmfs'],'tcmfs','ai_ajustdamage_from')
sgs.ai_skill_discard['tcmfs']=wrap(sgs.ai_skill_discard['tcmfs'],'tcmfs','ai_skill_discard')
sgs.ai_cardneed['blmf']=wrap(sgs.ai_cardneed['blmf'],'blmf','ai_cardneed')
sgs.ai_cardneed['tcmfs']=wrap(sgs.ai_cardneed['tcmfs'],'tcmfs','ai_cardneed')
sgs.ai_fill_skill['blmf']=wrap(sgs.ai_fill_skill['blmf'],'blmf','ai_fill_skill')
sgs.ai_ajustdamage_from['blmf']=wrap(sgs.ai_ajustdamage_from['blmf'],'blmf','ai_ajustdamage_from')
sgs.ai_skill_playerchosen['pomiehb']=wrap(sgs.ai_skill_playerchosen['pomiehb'],'pomiehb','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['pomiehb']=wrap(sgs.ai_playerchosen_intention['pomiehb'],'pomiehb','ai_playerchosen_intention')
sgs.ai_skill_invoke['yiban']=wrap(sgs.ai_skill_invoke['yiban'],'yiban','ai_skill_invoke')
sgs.ai_skill_use['@@yiban']=wrap(sgs.ai_skill_use['@@yiban'],'@@yiban','ai_skill_use')
sgs.ai_card_intention['#yiban']=wrap(sgs.ai_card_intention['#yiban'],'#yiban','ai_card_intention')
sgs.ai_skill_playerchosen['tonghh']=wrap(sgs.ai_skill_playerchosen['tonghh'],'tonghh','ai_skill_playerchosen')
sgs.ai_card_priority['zhumyb']=wrap(sgs.ai_card_priority['zhumyb'],'zhumyb','ai_card_priority')
sgs.ai_skill_playerchosen['luashouhuo']=wrap(sgs.ai_skill_playerchosen['luashouhuo'],'luashouhuo','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['luashouhuo']=wrap(sgs.ai_playerchosen_intention['luashouhuo'],'luashouhuo','ai_playerchosen_intention')
sgs.ai_skill_playerchosen['luahongyu']=wrap(sgs.ai_skill_playerchosen['luahongyu'],'luahongyu','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['luahongyu']=wrap(sgs.ai_playerchosen_intention['luahongyu'],'luahongyu','ai_playerchosen_intention')
sgs.ai_skill_invoke['pinkdevil']=wrap(sgs.ai_skill_invoke['pinkdevil'],'pinkdevil','ai_skill_invoke')
sgs.ai_skill_playerchosen['pinkdevil']=wrap(sgs.ai_skill_playerchosen['pinkdevil'],'pinkdevil','ai_skill_playerchosen')
sgs.ai_ajustdamage_from['khztbuff']=wrap(sgs.ai_ajustdamage_from['khztbuff'],'khztbuff','ai_ajustdamage_from')
sgs.ai_skill_playerchosen['gxzhiliao']=wrap(sgs.ai_skill_playerchosen['gxzhiliao'],'gxzhiliao','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['gxzhiliao']=wrap(sgs.ai_playerchosen_intention['gxzhiliao'],'gxzhiliao','ai_playerchosen_intention')
sgs.ai_skill_playerchosen['shenpan']=wrap(sgs.ai_skill_playerchosen['shenpan'],'shenpan','ai_skill_playerchosen')
sgs.ai_skill_invoke['shenpan']=wrap(sgs.ai_skill_invoke['shenpan'],'shenpan','ai_skill_invoke')
sgs.ai_skill_invoke['nxlieren']=wrap(sgs.ai_skill_invoke['nxlieren'],'nxlieren','ai_skill_invoke')
sgs.ai_skill_invoke['nxlieren_damage']=wrap(sgs.ai_skill_invoke['nxlieren_damage'],'nxlieren_damage','ai_skill_invoke')
sgs.ai_skill_choice['nxlieren']=wrap(sgs.ai_skill_choice['nxlieren'],'nxlieren','ai_skill_choice')
sgs.ai_skill_invoke['zhanshubuju']=wrap(sgs.ai_skill_invoke['zhanshubuju'],'zhanshubuju','ai_skill_invoke')
sgs.ai_fill_skill['zhachang']=wrap(sgs.ai_fill_skill['zhachang'],'zhachang','ai_fill_skill')
sgs.ai_skill_use_func['#zhachang']=wrap(sgs.ai_skill_use_func['#zhachang'],'#zhachang','ai_skill_use_func')
sgs.ai_skill_invoke['hongshui']=wrap(sgs.ai_skill_invoke['hongshui'],'hongshui','ai_skill_invoke')
sgs.ai_fill_skill['zhufu']=wrap(sgs.ai_fill_skill['zhufu'],'zhufu','ai_fill_skill')
sgs.ai_skill_use_func['#zhufu']=wrap(sgs.ai_skill_use_func['#zhufu'],'#zhufu','ai_skill_use_func')
sgs.ai_skill_invoke['afuhuo']=wrap(sgs.ai_skill_invoke['afuhuo'],'afuhuo','ai_skill_invoke')
sgs.ai_canNiepan_skill['afuhuo']=wrap(sgs.ai_canNiepan_skill['afuhuo'],'afuhuo','ai_canNiepan_skill')
sgs.ai_skill_choice['afuhuo']=wrap(sgs.ai_skill_choice['afuhuo'],'afuhuo','ai_skill_choice')
sgs.ai_skill_invoke['tonghua']=wrap(sgs.ai_skill_invoke['tonghua'],'tonghua','ai_skill_invoke')
sgs.ai_skill_playerchosen['tonghua']=wrap(sgs.ai_skill_playerchosen['tonghua'],'tonghua','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['tonghua']=wrap(sgs.ai_playerchosen_intention['tonghua'],'tonghua','ai_playerchosen_intention')
sgs.ai_skill_playerchosen['lingbo']=wrap(sgs.ai_skill_playerchosen['lingbo'],'lingbo','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['lingbo']=wrap(sgs.ai_playerchosen_intention['lingbo'],'lingbo','ai_playerchosen_intention')
sgs.ai_cardneed['lingbo']=wrap(sgs.ai_cardneed['lingbo'],'lingbo','ai_cardneed')
sgs.ai_ajustdamage_from['chaogz']=wrap(sgs.ai_ajustdamage_from['chaogz'],'chaogz','ai_ajustdamage_from')
sgs.ai_fill_skill['paojixj']=wrap(sgs.ai_fill_skill['paojixj'],'paojixj','ai_fill_skill')
sgs.ai_skill_use_func['#paojixj']=wrap(sgs.ai_skill_use_func['#paojixj'],'#paojixj','ai_skill_use_func')
sgs.ai_skill_invoke['dqjt']=wrap(sgs.ai_skill_invoke['dqjt'],'dqjt','ai_skill_invoke')
sgs.ai_skill_playerchosen['dqjt']=wrap(sgs.ai_skill_playerchosen['dqjt'],'dqjt','ai_skill_playerchosen')
sgs.ai_skill_invoke['lianxie']=wrap(sgs.ai_skill_invoke['lianxie'],'lianxie','ai_skill_invoke')
sgs.ai_skill_invoke['huanzhaung']=wrap(sgs.ai_skill_invoke['huanzhaung'],'huanzhaung','ai_skill_invoke')
sgs.ai_skill_cardchosen['huanzhaung']=wrap(sgs.ai_skill_cardchosen['huanzhaung'],'huanzhaung','ai_skill_cardchosen')
sgs.ai_skill_invoke['xinshengll']=wrap(sgs.ai_skill_invoke['xinshengll'],'xinshengll','ai_skill_invoke')
sgs.ai_fill_skill['xinshengll']=wrap(sgs.ai_fill_skill['xinshengll'],'xinshengll','ai_fill_skill')
sgs.ai_skill_use_func['#xinshengll']=wrap(sgs.ai_skill_use_func['#xinshengll'],'#xinshengll','ai_skill_use_func')
sgs.ai_skill_askforag['xinshengll']=wrap(sgs.ai_skill_askforag['xinshengll'],'xinshengll','ai_skill_askforag')
sgs.ai_skill_invoke['llpj']=wrap(sgs.ai_skill_invoke['llpj'],'llpj','ai_skill_invoke')
sgs.ai_fill_skill['shejiao']=wrap(sgs.ai_fill_skill['shejiao'],'shejiao','ai_fill_skill')
sgs.ai_skill_use_func['#shejiao']=wrap(sgs.ai_skill_use_func['#shejiao'],'#shejiao','ai_skill_use_func')
sgs.ai_skill_choice['shejiao']=wrap(sgs.ai_skill_choice['shejiao'],'shejiao','ai_skill_choice')
sgs.ai_skill_use['@@shejiaofuka']=wrap(sgs.ai_skill_use['@@shejiaofuka'],'@@shejiaofuka','ai_skill_use')
sgs.ai_skill_invoke['wanxian']=wrap(sgs.ai_skill_invoke['wanxian'],'wanxian','ai_skill_invoke')
sgs.ai_skill_playerchosen['wanxian']=wrap(sgs.ai_skill_playerchosen['wanxian'],'wanxian','ai_skill_playerchosen')
sgs.ai_skill_invoke['liantan']=wrap(sgs.ai_skill_invoke['liantan'],'liantan','ai_skill_invoke')
sgs.ai_skill_playerchosen['liantan']=wrap(sgs.ai_skill_playerchosen['liantan'],'liantan','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['liantan']=wrap(sgs.ai_playerchosen_intention['liantan'],'liantan','ai_playerchosen_intention')
sgs.ai_skill_choice['liantan']=wrap(sgs.ai_skill_choice['liantan'],'liantan','ai_skill_choice')
sgs.ai_cardneed['s_yanyu']=wrap(sgs.ai_cardneed['s_yanyu'],'s_yanyu','ai_cardneed')
sgs.ai_can_damagehp['s_yanyu']=wrap(sgs.ai_can_damagehp['s_yanyu'],'s_yanyu','ai_can_damagehp')
sgs.ai_fill_skill['s_yanmojianglin']=wrap(sgs.ai_fill_skill['s_yanmojianglin'],'s_yanmojianglin','ai_fill_skill')
sgs.ai_skill_use_func['#s_yanmojianglin']=wrap(sgs.ai_skill_use_func['#s_yanmojianglin'],'#s_yanmojianglin','ai_skill_use_func')
sgs.ai_skill_choice['s_yanmojianglin']=wrap(sgs.ai_skill_choice['s_yanmojianglin'],'s_yanmojianglin','ai_skill_choice')
sgs.ai_fill_skill['s_lianjie']=wrap(sgs.ai_fill_skill['s_lianjie'],'s_lianjie','ai_fill_skill')
sgs.ai_skill_use_func['#s_lianjie']=wrap(sgs.ai_skill_use_func['#s_lianjie'],'#s_lianjie','ai_skill_use_func')
sgs.ai_fill_skill['s_polie']=wrap(sgs.ai_fill_skill['s_polie'],'s_polie','ai_fill_skill')
sgs.ai_skill_use_func['#s_polie']=wrap(sgs.ai_skill_use_func['#s_polie'],'#s_polie','ai_skill_use_func')
sgs.ai_skill_playerchosen['s_polie']=wrap(sgs.ai_skill_playerchosen['s_polie'],'s_polie','ai_skill_playerchosen')
sgs.ai_skill_choice['s_shuimian']=wrap(sgs.ai_skill_choice['s_shuimian'],'s_shuimian','ai_skill_choice')
sgs.ai_skill_playerchosen['s_jieshu']=wrap(sgs.ai_skill_playerchosen['s_jieshu'],'s_jieshu','ai_skill_playerchosen')
sgs.ai_skill_choice['s_jieshu']=wrap(sgs.ai_skill_choice['s_jieshu'],'s_jieshu','ai_skill_choice')
sgs.ai_skill_choice['s_fudao']=wrap(sgs.ai_skill_choice['s_fudao'],'s_fudao','ai_skill_choice')
sgs.ai_fill_skill['s_fudao']=wrap(sgs.ai_fill_skill['s_fudao'],'s_fudao','ai_fill_skill')
sgs.ai_skill_use_func['#s_fudao']=wrap(sgs.ai_skill_use_func['#s_fudao'],'#s_fudao','ai_skill_use_func')
sgs.ai_skill_invoke['s_douM']=wrap(sgs.ai_skill_invoke['s_douM'],'s_douM','ai_skill_invoke')
sgs.ai_skill_choice['s_kongyi']=wrap(sgs.ai_skill_choice['s_kongyi'],'s_kongyi','ai_skill_choice')
sgs.ai_skill_cardchosen['s_kongyi']=wrap(sgs.ai_skill_cardchosen['s_kongyi'],'s_kongyi','ai_skill_cardchosen')
sgs.ai_skill_playerchosen['s_kongyi_getfield']=wrap(sgs.ai_skill_playerchosen['s_kongyi_getfield'],'s_kongyi_getfield','ai_skill_playerchosen')
sgs.ai_fill_skill['s_kongyi']=wrap(sgs.ai_fill_skill['s_kongyi'],'s_kongyi','ai_fill_skill')
sgs.ai_skill_use_func['#s_kongyi']=wrap(sgs.ai_skill_use_func['#s_kongyi'],'#s_kongyi','ai_skill_use_func')
sgs.ai_skill_invoke['s_yueqian']=wrap(sgs.ai_skill_invoke['s_yueqian'],'s_yueqian','ai_skill_invoke')
sgs.ai_skill_cardchosen['s_yueqian']=wrap(sgs.ai_skill_cardchosen['s_yueqian'],'s_yueqian','ai_skill_cardchosen')
sgs.ai_skill_playerchosen['s_yueqian']=wrap(sgs.ai_skill_playerchosen['s_yueqian'],'s_yueqian','ai_skill_playerchosen')
sgs.ai_skill_invoke['s_newtype']=wrap(sgs.ai_skill_invoke['s_newtype'],'s_newtype','ai_skill_invoke')
sgs.ai_skill_use['@@s_newtype']=wrap(sgs.ai_skill_use['@@s_newtype'],'@@s_newtype','ai_skill_use')
sgs.ai_skill_choice['s_newtype']=wrap(sgs.ai_skill_choice['s_newtype'],'s_newtype','ai_skill_choice')
sgs.ai_skill_use['@@s_newtypeOther']=wrap(sgs.ai_skill_use['@@s_newtypeOther'],'@@s_newtypeOther','ai_skill_use')
sgs.ai_skill_use['@@htms_nisheng']=wrap(sgs.ai_skill_use['@@htms_nisheng'],'@@htms_nisheng','ai_skill_use')
sgs.ai_skill_choice['htms_sanqi']=wrap(sgs.ai_skill_choice['htms_sanqi'],'htms_sanqi','ai_skill_choice')
sgs.ai_skill_invoke['htms_ranxin']=wrap(sgs.ai_skill_invoke['htms_ranxin'],'htms_ranxin','ai_skill_invoke')
sgs.ai_target_revises['htms_coffee']=wrap(sgs.ai_target_revises['htms_coffee'],'htms_coffee','ai_target_revises')
sgs.ai_canNiepan_skill['htms_beihai']=wrap(sgs.ai_canNiepan_skill['htms_beihai'],'htms_beihai','ai_canNiepan_skill')
sgs.ai_skill_discard['htms_lunbian']=wrap(sgs.ai_skill_discard['htms_lunbian'],'htms_lunbian','ai_skill_discard')
sgs.ai_skill_playerchosen['htms_godot']=wrap(sgs.ai_skill_playerchosen['htms_godot'],'htms_godot','ai_skill_playerchosen')
