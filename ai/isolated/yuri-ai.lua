-- Fixed yuri b6025acc source policy. Readonly proposals never grant payment authority.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("yuri fact unknown",k)end;return v end
local function __yuri_value_call(o,k,...)if o==nil then error("attempt to index a nil value",0)end;if k=="getMark"and AIValue.isPlayer(o)then k="getStrategyMark"elseif k=="hasFlag"and AIValue.isPlayer(o)then k="getStrategyFlag"end;if type(o[k])~="function"then ai_unsupported("yuri method unavailable",k)end;return known(o[k](o,...),k)end
local function fact(self,k)ai_unsupported("yuri fact is not projected",k)end
local function visible(self,id)return known(self:getKnownCardById(id),"disclosed card")end
-- The viewer's own property; the reader uses toString, so absent reads as "".
local function property(self,k)local v=self.player:getPropertyValue(k);if v==nil then return""end;return v end
local function tag(self,k,kind)
 -- Only the viewer's own tags are projected; nil is an absent tag, whose QVariant
 -- conversion is the default struct. Room tags are not projected.
 if k=="SlashMissed"and kind=="SlashEffect"then
  if self.player:getTag(k)~=nil then ai_unsupported("SlashEffectStruct tags are not projected",k)end
  return{jink_num=1,drank=0,nature=sgs.DamageStruct_Normal}
 end
 if k~="owner_flexible"or kind~="CardUse"then ai_unsupported("Yuri tag is not projected",k)end
 local r=self.player:getTag("flexible")
 if type(r)~="table"or type(r.to)~="table"then return{to=AIList.new({})}end
 local function player(n)if n==nil or n==""then return nil end;return known(self.room:findPlayerByObjectName(n,true),k)end
 local to=AIList.new({});for _,n in ipairs(r.to)do to:append(player(n))end
 return{from=player(r.from),to=to,card=type(r.card)=="table"and next(r.card)~=nil and CardView.new(r.card)or nil}
end
local function dummy_plan(value,extra,current)local u=AIUsePlan.new();u.isDummy=value~=false;u.extra_target=extra or 0;u.current_targets=current or {};return u end
local recipes=setmetatable({},{__mode="k"})
local function copy(t)local r={}for k,v in pairs(t)do if type(v)=="table"then r[k]=copy(v)else r[k]=v end end;return r end
local function clone(self,name,suit,number,skill)
 if type(suit)=="string"then skill=suit;suit=sgs.Card_NoSuit end
 name=name or"slash";suit=suit or sgs.Card_NoSuit;number=number or 0
 local spec={source_key=self._yuri_callback_key or "yuri",name=name,skill=skill or"",suit=suit,number=number,subcards={}}
 local c
 if spec.skill==""and suit==sgs.Card_NoSuit and number==0 then c=self:getEvaluationCard(name)
 else c=self:evaluateOwnerViewAsCard(spec)end
 if c then recipes[c]=spec end;return c
end
local function mutate(self,c,field,v)
 local spec=recipes[c];if not spec then ai_unsupported("source mutates card outside its owned readonly clone","yuri.clone")end
 spec=copy(spec)
 if field=="clear"then spec.subcards={}elseif field=="can_recast"then ai_unsupported("readonly clone recast mutation requires scoped native contract",self._yuri_callback_key)elseif field=="add"then spec.subcards[#spec.subcards+1]=type(v)=="number"and v or __yuri_value_call(v,"getEffectiveId")else spec[field]=v end
 local next
 if spec.prototype then next=self:evaluateTurnSkillCard(spec.skill,spec.prototype,spec.subcards,nil,spec.user)else next=self:evaluateOwnerViewAsCard(spec)end;self:inheritLegacyCardIdentity(next,c);recipes[next]=spec;return next
end
local function ids(raw)local out={};if raw~="."and raw~=""then for n in raw:gmatch("[^+]+")do out[#out+1]=tonumber(n)or 0 end end;return out end
local function printed_spec(text)
 local name,skill,suit,n,raw=text:match("^([%w_]+):([%w_]+)%[([^:]+):([^%]]+)%]=(.*)$");if not name then return nil end
 local suits={spade=sgs.Card_Spade,club=sgs.Card_Club,heart=sgs.Card_Heart,diamond=sgs.Card_Diamond,no_suit=sgs.Card_NoSuit,no_suit_red=sgs.Card_NoSuitRed,no_suit_black=sgs.Card_NoSuitBlack};local nums={A=1,J=11,Q=12,K=13}
 return{name=name,skill=skill,suit=suits[suit]or sgs.Card_NoSuit,number=known(tonumber(n)or nums[n],"number"),subcards=ids(raw)}
end
local classes={['wannawinCard']='wannawin',['#clearthemeridians']='clearthemeridians',['#phantom']='phantom',['#goodatwep']='goodatwep',['#helptheweak']='helptheweak',['#changesexual']='changesexual',['#tobenature']='tobenature',['#heapridge']='heapridge',['#wannawin']='wannawin',['#turned']='turned',['#fightingclimax']='fightingclimax',['#witty']='witty',['#thedolls']='thedolls',['#yuri_xueji']='yuri_xueji',['#ys_jueyan']='ys_jueyan',['#ys_xionchi']='ys_xionchi',['#ys_xiongluan']='ys_xiongluan',['#ys_congjian']='ys_congjian',['#yuri_kongsheng']='yuri_kongsheng',['#married']='married',['#weareidle']='weareidle',['#hononozouki']='hononozouki',['#yomi']='yomi',['#kanchi']='kanchi',['#barakurosaku']='barakurosaku',['#unlock']='unlock',['#peeking']='peeking',['#zurunoonkaeshi']='zurunoonkaeshi',['#haigu']='haigu',['#gopugu']='gopugu',['#new_againstdis']='new_againstdis',['#hunnshin']='hunnshin',['#yurimi']='yurimi',['#kurashinfurashu']='kurashinfurashu',['#keishoukaki']='keishoukaki',['#gomaoku']='gomaoku',['#franklyCard']='frankly',['#flexible']='flexible',['#ov_jichoucard']='ov_jichou',['#genshunoYURICard']='genshunoYURI',['#clever']='clever',['#SubetewonomikonmuCard']='Subetewonomikonmu',['#actingcard']='acting',['#liketoplaycard']='liketoplay',['#endingchoiceCard']='endingchoice',['#dressing']='dressing'}
local function decode(text)
 local cl,raw=text:match("^@([%w_]+)=(.*)$");local user
 if cl then local costs,u=raw:match("^(.-):(.*)$");raw=costs or raw;user=u
 else cl,raw,user=text:match("^#([%w_]+):([^:]*):(.*)$");if cl then cl="#"..cl end end
 local sk=cl and classes[cl];if not sk then ai_unsupported("source prototype wire outside authored catalog","yuri")end
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
 if __yuri_value_call(c,"isVirtualCard")then ai_unsupported("selected physical response has no issued authority","yuri")end
 return{kind="use_card",card_id=__yuri_value_call(c,"getEffectiveId"),targets=tos and tos:split("+")or{}}
end
local function proposal(v)
 if type(v)~="string"or v=="."or v==""then return v end
 local row=printed_spec(v);if row then return row end
 local cl,sk,cs,u=decode(v);return{legacy_class=cl,skill=sk,subcards=cs,user_string=u}
end
local function can_to(self,c,from,to,targets)
 if from:objectName()~=self.player:objectName()then ai_unsupported("foreign hypothetical targetFilter lacks public rule contract","yuri")end
 return self:cardTargetFilter(c,targets or{},to)
end
local function pending_tag(self,name,value)ai_unsupported("temporary yb_zhuzhan2 input requires pure callback adapter",name)end
local function private_draw(self)ai_unsupported("source inspects undisclosed draw-pile faces","zhachang")end
local function source_description(self,name)ai_unsupported("public card descriptions are not projected",name)end
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
  if type(v.isEvaluationOnly)=="function"and v:isEvaluationOnly()then ai_unsupported("untracked readonly card cannot persist across snapshots","yuri state")end
  return{type="card",id=__yuri_value_call(v,"getEffectiveId")}
 end
 if type(v)~="table"then return{type="scalar",value=v}end
 local t={type="table",value={}};for k,x in pairs(v)do if type(x)~="function"then t.value[k]=state_encode(self,x)end end;return t
end
local function state_decode(self,v)
 if v.type=="nil"then return nil elseif v.type=="scalar"then return v.value elseif v.type=="player"then return known(self.room:findPlayerByObjectName(v.name,true),"cached target")elseif v.type=="card"then return visible(self,v.id)
 elseif v.type=="recipe"then local r=v.value;if r.prototype then return policy(self,(r.prototype:sub(1,1)=="#"and(r.prototype..":"..(#r.subcards>0 and table.concat(r.subcards,"+")or".")..":"..(r.user or""))or("@"..r.prototype.."="..(#r.subcards>0 and table.concat(r.subcards,"+")or".")..(r.user and":"..r.user or""))))end
 local c=self:evaluateOwnerViewAsCard(r);recipes[c]=copy(r);return c
 elseif v.type=="table"then local t={};for k,x in pairs(v.value)do t[k]=state_decode(self,x)end;if#t>0 then return AIList.new(t)end;return t end
 ai_unsupported("invalid source observation cache","yuri")
end
local state_fields={} -- Wannawin card/pindian state exists only in commented donor code.
local function load_state(self)
 if self._yuri_state_loaded then return end;self._yuri_state_loaded=true
 for _,k in ipairs(state_fields)do local r,ok=self:getStrategyMemory("yuri."..k);if ok then self[k]=state_decode(self,r)end end

end
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~="table"then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function save_state(self)
 for _,k in ipairs(state_fields)do local prior,present=self:getStrategyMemory("yuri."..k);local v=self[k]
  if present or v~=nil then local encoded=state_encode(self,v);if not present or not same(prior,encoded)then self:setStrategyMemory("yuri."..k,encoded)end end
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

local function observation_mark(self,key)
 return self:sourceImmediateEffect("heapridge","read",self.player,key)
end
local function pattern_card(self,name)
 ai_unsupported("public PatternsCard sampling is not projected",name)
end

local function printed(self,id)return known(self:getPrintedCardById(id),"lawful printed card descriptor")end
local function set_observation(self,k,v)self:setStrategyMemory("yuri.observation:"..k,v)end
local function room_tag(self,k,kind)
 if k:sub(1,3)=="ai_"or k=="goodatwep"then
  local v,ok=self:getStrategyMemory("yuri.observation:"..k)
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
 local cards=known(p:getKnownCards(),"known hand");if #cards~=__yuri_value_call(p,"getHandcardNum")then ai_unsupported("source branch requires full foreign hand identity","yuri.hand")end;return cards
end
local function viewer_role(self,p)
 local exact=p:getRole();if exact~=nil and exact~="unknown"and exact~="neutral"then return exact end
 local role=self:getRoleEstimate(p);if role==nil or role=="neutral"or role=="unknown"then ai_unsupported("source role unavailable from viewer knowledge","yuri.role")end
 return self:useKnowledgeEstimate({value=role,status="estimate",basis="viewer_role_inference_replaces_private_role",viewer=self.player:objectName(),target=p:objectName()},"yuri.role")
end
local function forbidden_foreign_ai(self)ai_unsupported("other AI private state is not available","yuri")end
local function role_event(self,p,kind,role)
 -- Callers check the public skill/mark condition on p before reaching here.
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
 local row=known(self:getDecisionContext().yuri_pattern_matches,"source ExpPattern facts")
 if row.pattern~=pattern then ai_unsupported("source ExpPattern context mismatch","yuri")end
 local result=known(row.by_id,"source pattern results")[tostring(card:getEffectiveId())]
 if type(result)~="boolean"then ai_unsupported("source ExpPattern match unknown","yuri")end;return result
end
local function stage_delay(self,ms)self:stageSpeechDelay(ms,"yuri:arkora")end
local function clear_source_mark(self,player,mark)
 ai_unsupported("source mark-clear writer/admission requires explicit event witness",mark)
end

-- These three source marks have no gameplay readers/writers; store only this viewer's visible-card observations.
local function public_count(self,p,k)
 local value,present=self:getStrategyMemory("yuri.count:"..p:objectName()..":"..k)
 if present then return value end
 return __yuri_value_call(p,"getMark",k)
end
local function set_public_count(self,p,k,v)self:setStrategyMemory("yuri.count:"..p:objectName()..":"..k,v)end
sgs.ai_event_callback[sgs.AfterDrawNCards]=sgs.ai_event_callback[sgs.AfterDrawNCards]or{}
local function Q_goodToThrow(who, card, havej)
	if havej and who:getCards("j"):length() > 0 then
		if __yuri_value_call(card,"isKindOf","DelayedTrick") and not __yuri_value_call(card,"isKindOf","YanxiaoCard") then
			return true
		end
	else
		if __yuri_value_call(card,"getClassName") == "SilverLion" and __yuri_value_call(who,"isWounded") then
			return true
		end
		if __yuri_value_call(card,"getClassName") == "GaleShell" then
			return true
		end
		if __yuri_value_call(card,"getClassName") == "Tianjitu" and __yuri_value_call(who,"getHandcardNum") < 4 then
			return true
		end
	end

	return false
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|LuaZhenlie"
function sgs.ai_skill_invoke.LuaZhenlie(self,data)
	if sgs.ai_skill_invoke.zhenlie(self, data) then return true end
	local target = data:toCardUse().from
	if target and self:doDisCard(target, "he") then return true end
	return false
end

sgs.ai_ajustdamage_to.LuaZhenlie   = function(self, from, to, card, nature)
	if __yuri_value_call(to,"getMark","LuaZhenlie-Clear") > 0 then
		return -99
	end
end
sgs.ai_skill_choice.LuaZhenlie = function(self, choices, data)
    local items = choices:split("+")
	local use = data:toCardUse()
	if table.contains(items, "losehp") then
		if __yuri_value_call(self.player,"getHp")+self:getAllPeachNum()-1 <= 0 then return "no" end
		if sgs.ai_skill_invoke.zhenlie(self, data) then return "losehp" end
		local slash = clone(self,"fire_slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		slash = mutate(self,slash,"skill","LuaZhenlie")
		if use.from and self:isEnemy(use.from) and not self:cantbeHurt(use.from) and self:damageIsEffective(use.from, slash, self.player) then
			return "losehp"
		end
		if self:needToLoseHp(self.player) then
			return "losehp"
		end
	end
	return "no"
end

sgs.ai_skill_choice.LuaRevenge = function(self, choices, data)
    local items = choices:split("+")
	local damage = data:toDamage()
	if damage.from and damage.from:objectName() == self.player:objectName() then
		return "itsmine"
	else
		return "giveyou"
	end
end

sgs.ai_goddess_judgestring = {
	indulgence = "heart",
	diamond = "heart",
	supply_shortage = "club",
	gdancer = "red",
	yusha = "red",
	foxnature = "black",
	yuri_hagaku = "black",
	migonoinori = "spade",
	hononozouki = "heart",
	chikuwasama = "red",
	yueguang = "black",
}
function sgs.ai_cardneed.goddess_new(to, card, self)
	local hc = self.player:getCards("he")
	local have_spade = false
	local have_heart = false
	local have_club = false
	local have_red = false
	local have_black = false

	if hc:length() > 0 then
		for _ ,c in sgs.qlist(hc) do
			if c:isBlack() then have_black = true end
			if c:isRed() then have_red = true end
			if __yuri_value_call(c,"getSuit") == sgs.Card_Spade and __yuri_value_call(c,"getNumber") >= 2 and __yuri_value_call(c,"getNumber") <= 9 then have_spade = true end
			if __yuri_value_call(c,"getSuit") == sgs.Card_Heart then have_heart = true end
			if __yuri_value_call(c,"getSuit") == sgs.Card_Club then have_club = true end
		end
	end
	for _, p in sgs.qlist(self.room:getAllPlayers()) do
		if self:isFriend(p) then
			if not p:containsTrick("YanxiaoCard") then
				if p:containsTrick("indulgence") and not have_heart then
					return __yuri_value_call(card,"getSuit") == sgs.Card_Heart
				end
				if p:containsTrick("supply_shortage") and not have_club then
					return __yuri_value_call(card,"getSuit") == sgs.Card_Club
				end
				if p:containsTrick("lightning") and not (have_red and have_club) then
					return (__yuri_value_call(card,"getSuitString") ~= "spade" or (__yuri_value_call(card,"getSuitString") == "spade" and (__yuri_value_call(card,"getNumber") < 2 and __yuri_value_call(card,"getNumber") > 9)))
				end
			end
		end
		if self:isEnemy(p) then
			if p:containsTrick("lightning") and not p:containsTrick("YanxiaoCard") and not have_spade then
				return __yuri_value_call(card,"getSuit") == sgs.Card_Spade and __yuri_value_call(card,"getNumber") >= 2 and __yuri_value_call(card,"getNumber") <= 9 and not p:hasSkills("hongyan|wuyan")
			end
		end
	end
end


sgs.ai_skill_cardask["@goddess-put"] = function(self,data,pattern)
	local player = self.player
	local target = self.room:getCurrent()
	local judge = data:toJudge()
    local needs = {}
	local cards = player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	if not player:isNude() and judge.reason then
		for _,card in ipairs(cards) do
			if self:isFriend(target) then
				if judge.reason == "lightning" and (__yuri_value_call(card,"getSuitString") ~= "spade" or (__yuri_value_call(card,"getSuitString") == "spade" and (__yuri_value_call(card,"getNumber") < 2 and __yuri_value_call(card,"getNumber") > 9))) then return "$" .. __yuri_value_call(card,"getEffectiveId") end
				if sgs.ai_goddess_judgestring[judge.reason] ~= nil and sgs.ai_goddess_judgestring[judge.reason] ~= "" then
					if __yuri_value_call(card,"getSuitString") == sgs.ai_goddess_judgestring[judge.reason] or card:getColorString() == sgs.ai_goddess_judgestring[judge.reason] then
						return "$" .. __yuri_value_call(card,"getEffectiveId")
					end
				end
			elseif self:isEnemy(target) then
				if judge.reason == "lightning" and (__yuri_value_call(card,"getSuitString") == "spade" and (__yuri_value_call(card,"getNumber") > 1 and __yuri_value_call(card,"getNumber") < 10)) then return "$" .. __yuri_value_call(card,"getEffectiveId") end
				if sgs.ai_goddess_judgestring[judge.reason] ~= nil and sgs.ai_goddess_judgestring[judge.reason] ~= "" then
					if __yuri_value_call(card,"getSuitString") ~= sgs.ai_goddess_judgestring[judge.reason] and card:getColorString() ~= sgs.ai_goddess_judgestring[judge.reason] then
						return "$" .. __yuri_value_call(card,"getEffectiveId")
					end
				end
			end
			if judge.reason == "miyadokyo" then
				if self:sourceImmediateEffect("maji","read",player,"majiBad") and card:isRed() then
					self:sourceImmediateEffect("maji","write",player,"majiBad",{card})
					return "$" .. __yuri_value_call(card,"getEffectiveId")
				end
				if self:sourceImmediateEffect("maji","read",player,"majiGood") and card:isBlack() then
					self:sourceImmediateEffect("maji","write",player,"majiGood",{card})
					return "$" .. __yuri_value_call(card,"getEffectiveId")
				end
				if self:sourceImmediateEffect("maji","read",player,"majiHeal") and __yuri_value_call(player,"getLostHp") > 1 and card:isBlack() then
					self:sourceImmediateEffect("maji","write",player,"majiHeal",{card})
					return "$" .. __yuri_value_call(card,"getEffectiveId")
				end
			end
		end
		local cards = self:addHandPile("he")
		local card_id = self:getRetrialCardId(cards,judge)
		if card_id~=-1 then return "$"..card_id end
		for _,card in ipairs(cards) do
			if Q_goodToThrow(self.player, card, false) then
				table.insert(needs, card)
			end
		end
		if #needs > 0 then return "$" .. __yuri_value_call(needs[1],"getEffectiveId") end
	end
    return "."
end

sgs.ai_skill_askforag["clearthemeridians"] = function(self, list)
	local cards = {}
	local ecards = {}
	for _, id in ipairs(list) do
		if visible(self,id):isKindOf("EquipCard") then
			table.insert(ecards, visible(self,id))
		else
			table.insert(cards, visible(self,id))
		end
	end
	cards = self:sortByKeepValue(cards, true)
	ecards = self:sortByUseValue(ecards)
	if #ecards > 0 then
		return __yuri_value_call(ecards[1],"getEffectiveId")
	else
		return __yuri_value_call(cards[1],"getEffectiveId")
	end
end

sgs.ai_fill_skill["clearthemeridians"] = function(self,inclusive,request)
	if self.player:getPile("pulsepile"):length() > 2 then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if __yuri_value_call(c,"isKindOf","EquipCard") then
			if __yuri_value_call(c,"isKindOf","SilverLion") and self.player:getArmor() and self.player:getArmor():isKindOf("SilverLion") and __yuri_value_call(self.player,"isWounded") then
				return policy(self,"#clearthemeridians:" .. c:getId().. ":")
			elseif not __yuri_value_call(c,"isKindOf","SilverLion") then
				if not (self:isWeak(self.player) and self.player:getArmor() == nil and (__yuri_value_call(c,"isKindOf","RenwangShield") or __yuri_value_call(c,"isKindOf","EightDiagram") or __yuri_value_call(c,"isKindOf","Vine"))) then
					return policy(self,"#clearthemeridians:" .. c:getId().. ":")
				end
			end
		end
	end
	return
end

sgs.ai_skill_use_func["#clearthemeridians"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.clearthemeridians = sgs.ai_use_priority.Slash + 1
sgs.ai_use_value["clearthemeridians"] = 4

sgs.ai_view_as.clearthemeridians = function(card, player, card_place)
	if player:getPile("pulsepile"):isEmpty() then return false end
	local suit = __yuri_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __yuri_value_call(card,"getEffectiveId")
	local pattern = known(self:getCurrentCardUsePattern(),"current card use pattern")
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "pulsepile" then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if dying then return ("analeptic:clearthemeridians[%s:%s]=%d"):format(suit, number, card_id) end
		if pattern == "jink" then
			return ("jink:clearthemeridians[%s:%s]=%d"):format(suit, number, card_id)
		elseif pattern == "slash" then
			return ("slash:clearthemeridians[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_card_priority.clearthemeridians = function(self,card)
	if table.contains(card:getSkillNames(), "clearthemeridians")
	then
		return 1
	end
end

sgs.ai_skill_choice.clearthemeridians = function(self, choices) --照抄ol_render
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	else
		if self:isWeak() and __yuri_value_call(self.player,"isWounded") and table.contains(items, "peach") then return "peach" end
		local slash = clone(self,"slash")
		slash:deleteLater()
		if self:getCardsNum("Slash") > 1 and not __yuri_value_call(slash,"isAvailable",self.player) and table.contains(items, "analeptic") then
			for _, enemy in ipairs(self.enemies) do
				if ((__yuri_value_call(enemy,"getHp") < 3 and __yuri_value_call(enemy,"getHandcardNum") < 3) or (__yuri_value_call(enemy,"getHandcardNum") < 2)) and self.player:canSlash(enemy) and not self:slashProhibit(slash, enemy, self.player)
					and self:slashIsEffective(slash, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, slash) then
					return "analeptic"
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
				local thunder_slash = clone(self,"thunder_slash")
				thunder_slash:deleteLater()
				local fire_slash = clone(self,"fire_slash")
				fire_slash:deleteLater()
				if table.contains(items, "fire_slash") and not self:slashProhibit(fire_slash, enemy, self.player)
				and self:slashIsEffective(fire_slash, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, fire_slash) then	--yun
					return "fire_slash"
				end
				if table.contains(items, "thunder_slash") and not self:slashProhibit(thunder_slash, enemy, self.player)
				and self:slashIsEffective(thunder_slash, enemy, self.player) and self:isGoodTarget(enemy, self.enemies,thunder_slash) then	--yun
					return "thunder_slash"
				end
				if table.contains(items, "slash") and not self:slashProhibit(slash, enemy, self.player)
				and self:slashIsEffective(slash, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, slash) then	--yun
					return "slash"
				end
			end
		end
		if __yuri_value_call(self.player,"isWounded") and table.contains(items, "peach") then return "peach" end
	end
	if __yuri_value_call(self.player,"isWounded") and table.contains(items, "peach") then return "peach" end
	if table.contains(items, "analeptic") then return "analeptic" else return "cancel" end
end

sgs.ai_skill_use["@@clearthemeridians_fc"]=function(self,prompt)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies,"defense")
	local class_name = property(self,"clearthemeridians_fc")
	local use_card = clone(self,class_name, sgs.Card_NoSuit, 0)
	use_card:deleteLater()
	use_card = mutate(self,use_card,"skill","clearthemeridians_fc")
	if (use_card:targetFixed()) then
		return use_card:getLegacyStringKey()
	else
		if string.find(class_name, "slash")then
			for _,enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, use_card, false) and not self:slashProhibit(nil, enemy)
				and self:slashIsEffective(use_card, enemy) and self:isGoodTarget(enemy, self.enemies, use_card) then	--yun
					return use_card:getLegacyStringKey() .. "->" .. enemy:objectName()
				end
			end
		end
	end
end


sgs.ai_skill_invoke.semeruki = function(self, data)
	local effect = data:toCardEffect()
	if self:isFriend(effect.to) and (effect.to:getArmor() and (effect.to:getArmor():isKindOf("GaleShell") or (__yuri_value_call(effect.to,"isWounded") and effect.to:getArmor():isKindOf("SilverLion")))) then
		return true
	end
	if self:isEnemy(effect.to) then return true end
	return false
end

sgs.ai_skill_cardchosen["semeruki"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("e")) do
			if (__yuri_value_call(card,"isKindOf","SilverLion") and __yuri_value_call(who,"isWounded")) or __yuri_value_call(card,"isKindOf","GaleShell") then
				return card
			end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("e")) do
			if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"isKindOf","SilverLion") then
				table.insert(goodchice, card)
			end
			if __yuri_value_call(card,"isKindOf","Weapon") or __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_choicemade_filter.skillInvoke.semeruki = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target and not (__yuri_value_call(target,"isWounded") and target:getArmor() and target:getArmor():isKindOf("SilverLion")) then self:updateIntention(player, target, 50) end
	end
end

sgs.ai_skill_playerchosen.reedship = function(self, targets)
	self:updatePlayers()
	local targets = {}
	local good_targets = {}
	local best_target = nil
	self.friends = self:sort(self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		table.insert(targets, friend)
		if self:isWeak(friend) then table.insert(good_targets, friend) end
		if (__yuri_value_call(friend,"getHandcardNum")+friend:getEquips():length()) <= 1 and __yuri_value_call(friend,"getHp") == 1 then best_target = friend end
	end
	if best_target then return best_target end
	if #good_targets > 0 then return good_targets[1] end
	return targets[1]
end
sgs.ai_skill_invoke.reedship = function(self, data)
	local use = data:toCardUse()
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local hasblackcard = false
	for _,card in ipairs(cards) do
		if card:isBlack() then
			hasblackcard = true
			break
		end
	end
	if hasblackcard and self:isEnemy(use.from) then
		self.enemies = self:sort(self.enemies, "defenseSlash")
		local slash = clone(self,"slash", sgs.Card_NoSuitBlack, 0)
		slash:deleteLater()
		for _,enemy in ipairs(self.enemies) do
			if not self:slashProhibit(slash, enemy) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_use["@@reedship"] = function(self, prompt)
    self:updatePlayers()
	self.enemies = self:sort(self.enemies, "defenseSlash")
	local target
	local slash = clone(self,"slash", sgs.Card_NoSuitBlack, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if not self:slashProhibit(slash, enemy) then
			target = enemy
			break
		end
	end
	if target then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		cards = self:sortByUseValue(cards, true)
		for _,card in ipairs(cards) do
			if self:getCard("SilverLion") and __yuri_value_call(self.player,"isWounded") then
				if __yuri_value_call(card,"isKindOf","SilverLion") then
					return ("slash:reedship[%s:%s]=%d->%s"):format(__yuri_value_call(card,"getSuitString"), card:getNumberString(), __yuri_value_call(card,"getEffectiveId"), target:objectName())
				end
			else
				if card:isBlack() and not (__yuri_value_call(self.player,"getHp") == 1 and __yuri_value_call(card,"isKindOf","Analeptic")) then
					return ("slash:reedship[%s:%s]=%d->%s"):format(__yuri_value_call(card,"getSuitString"), card:getNumberString(), __yuri_value_call(card,"getEffectiveId"), target:objectName())
				end
			end
		end
	else
		return "."
	end
	return "."
end

sgs.reedship_suit_value = {
	spade = 4,
	club = 3
}
sgs.ai_playerchosen_intention["reedship"] = function(self, from, to)
	self:updateIntention(from, to, -20)
end

sgs.ai_fill_skill["phantom"] = function(self,inclusive,request)
	self:updatePlayers()
	local var = 0
	for _, enemy in ipairs(self.enemies) do
		if __yuri_value_call(enemy,"getMark","@meiying") > 0 then
			var = var + 1
		end
	end
	if var == 0 then return false end
	if (not self.player:hasUsed("#phantom")) then
		return policy(self,"#phantom:.:")
	end
end

sgs.ai_skill_use_func["#phantom"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "handcard")
	local targets = {}
	local good_targets = {}
	local best_target = nil
	if __yuri_value_call(self.player,"getMark","@waked") > 0 then
		for _, enemy in ipairs(self.enemies) do
			local cards = known(enemy:getKnownCards(),"known enemy hand")
			local hasdiamond = false
			for _, card in sgs.qlist(cards) do -- 查找敵人已知手牌的方塊牌，如果是閃或桃，那就逼他丟
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
				if __yuri_value_call(card,"hasFlag","visible") or __yuri_value_call(card,"hasFlag",flag) then
					if __yuri_value_call(card,"getSuit") == sgs.Card_Diamond and not (__yuri_value_call(card,"isKindOf","Jink") or __yuri_value_call(card,"isKindOf","Peach")) then
						hasdiamond = true
					end
					if hasdiamond then break end
				end
			end
			if self:objectiveLevel(enemy) > 3 and __yuri_value_call(enemy,"getMark","@meiying") > 0 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then
				if __yuri_value_call(enemy,"getHp") < 3 and __yuri_value_call(enemy,"getHandcardNum") <= 3 and not hasdiamond then -- 如果他的血少牌又少，加上可視牌無方塊，那是個好目標
					table.insert(good_targets, enemy)
				else
					table.insert(targets, enemy)
				end
				if __yuri_value_call(enemy,"getHp") == 1 and enemy:getEquips():length() > 1 and __yuri_value_call(enemy,"getMark","@meiying") > 0 and __yuri_value_call(enemy,"getHandcardNum") <= 2 and not hasdiamond then
					best_target = enemy
					break
				end
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			local cards = known(enemy:getKnownCards(),"known enemy hand")
			local hasdiamond = false
			local unknowcards = __yuri_value_call(enemy,"getHandcardNum")-#cards
			for _, card in sgs.qlist(cards) do -- 查找敵人已知手牌的方塊牌，如果是閃或桃，那就逼他丟
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
				if __yuri_value_call(card,"hasFlag","visible") or __yuri_value_call(card,"hasFlag",flag) then
					if __yuri_value_call(card,"getSuit") == sgs.Card_Diamond and not (__yuri_value_call(card,"isKindOf","Jink") or __yuri_value_call(card,"isKindOf","Peach")) then
						hasdiamond = true
					end
					if hasdiamond then break end
				else
					unknowcards = unknowcards + 1
				end
			end
			if __yuri_value_call(enemy,"getMark","@meiying") > 0 then
				if __yuri_value_call(enemy,"getHp") < 3 and not (hasdiamond or unknowcards > 1) then
					best_target = enemy
					break
				else
					table.insert(targets, enemy)
				end
			end
		end
	end
	use.card = policy(self,"#phantom:.:")
	if use.to then
		if best_target then
			use.to:append(best_target)
		elseif #good_targets > 0 then
			use.to:append(good_targets[1])
		else
			use.to:append(targets[1])
		end
		return
	end
end

sgs.ai_use_value["phantom"] = 3.5
sgs.ai_use_priority["phantom"] = sgs.ai_use_priority.Slash + 1
sgs.dynamic_value.damage_card["phantom"] = true

sgs.ai_card_intention["phantom"] = 60
sgs.ai_skill_cardask["@phantomask"] = function(self, data, pattern, target, target2)

	if not self:damageIsEffective(self.player,sgs.DamageStruct_Normal,target) then
		return "."
	end
	if self:needToLoseHp(self.player,target) then
		return "."
	end
	local card_id
	for _,card in sgs.qlist(self.player:getCards("h"))do
		if __yuri_value_call(card,"getSuit") == sgs.Card_Diamond then
			card_id = __yuri_value_call(card,"getEffectiveId")
			break
		end
	end
	if not card_id then return "." else return "$"..card_id end
	return "."
end

sgs.ai_fill_skill["goodatwep"] = function(self,inclusive,request)
	return policy(self,"#goodatwep:.:")
end

sgs.ai_skill_use_func["#goodatwep"] = function(card, use, self)
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if __yuri_value_call(self.player,"inMyAttackRange",p) and __yuri_value_call(p,"getMark","GoodatwepMark") == 0 then
			if self.player:objectName() ~= p:objectName() and self:isFriend(p) and (p:getCards("j"):length() > 0 or (p:getArmor() and (p:getArmor():getClassName() == "GaleShell" or (__yuri_value_call(p,"isWounded") and p:getArmor():getClassName() == "SilverLion"))) or (p:getTreasure() and __yuri_value_call(p,"getHandcardNum") < 4 and p:getTreasure():isKindOf("Tianjitu")))then
				use.card = policy(self,"#goodatwep:.:")
				if use.to then use.to:append(p) end
				return
			elseif not p:isNude() and not self:isFriend(p) then
				use.card = policy(self,"#goodatwep:.:")
				self:goodatwepRoomTag("write",p)
				if use.to then use.to:append(p) end
				return
			end
		end
	end
end
sgs.ai_skill_cardchosen["goodatwep"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"getClassName") == "SilverLion" then
				table.insert(goodchice, card)
			end
			if __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_skill_choice.goodatwep = function(self, choices, data)
	local name = self:goodatwepRoomTag("read")
	if name == "" then return "cancel" end
	local target = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:objectName() == name then
			target = p
			break
		end
	end
	if self:isFriend(target) then return "cancel" end
	if not self:isWeak(self.player) then return "gogetit" end
	return "cancel"
end
sgs.ai_use_value["goodatwep"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["goodatwep"] = sgs.ai_use_priority.Slash + 1

sgs.ai_card_intention["goodatwep"] = function(self,card,from,tos)
	for _,to in ipairs(tos) do
		if to:getCards("j"):length() > 0
		or (to:getArmor() and (to:getArmor():getClassName() == "GaleShell" or (__yuri_value_call(to,"isWounded") and to:getArmor():getClassName() == "SilverLion")))
		or (to:getTreasure() and __yuri_value_call(to,"getHandcardNum") < 5 and to:getTreasure():getClassName() == "Tianjitu") then
			self:updateIntention(from, to, 0)
		else
			self:updateIntention(from, to, 15)
		end
	end
end

sgs.ai_fill_skill["helptheweak"] = function(self,inclusive,request)
	local someonehurt = false
	for _, friend in ipairs(self.friends) do
		if __yuri_value_call(friend,"isWounded") and __yuri_value_call(friend,"getHandcardNum") <= __yuri_value_call(self.player,"getHandcardNum") and __yuri_value_call(self.player,"getHp") >= __yuri_value_call(friend,"getHp") then
			someonehurt = true
			break
		end
	end
	if someonehurt and __yuri_value_call(self.player,"getHandcardNum") >= 2 then
		return policy(self,"#helptheweak:.:")
	end
	return false
end

sgs.ai_skill_use_func["#helptheweak"] = function(card, use, self)
	local first_found, second_found = false, false
	local first_card, second_card
	local colors = nil
	local target
	self.friends = self:sort(self.friends, "chaofeng")
	if __yuri_value_call(self.player,"getHandcardNum") >= 2 then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		cards = self:sortByKeepValue(cards)
		if self:isWeak(self.player) and __yuri_value_call(self.player,"isLord") then
			target = self.player
		else
			for _, friend in ipairs(self.friends) do
				local exclude = true
				if __yuri_value_call(friend,"getHandcardNum") <= __yuri_value_call(self.player,"getHandcardNum") and __yuri_value_call(self.player,"getHp") >= __yuri_value_call(friend,"getHp") then
					if __yuri_value_call(friend,"isLord") and self:isWeak(friend) and self:getEnemyNumBySeat(self.player, friend) >= 1 then
						exclude = false
					elseif __yuri_value_call(self.player,"getHp") == 1 and __yuri_value_call(self.player,"getHandcardNum") >= 2 and self.player:objectName() == friend:objectName() then
						exclude = false
					elseif self:isWeak(friend) and __yuri_value_call(friend,"getHandcardNum") < 2 then
						exclude = false
					elseif __yuri_value_call(friend,"isWounded") and self.player:objectName() == friend:objectName() then
						exclude = false
					elseif __yuri_value_call(self.player,"getHandcardNum") >= 4 and __yuri_value_call(friend,"isWounded") then
						exclude = false
					end
				end
				if self:needKongcheng(friend, true) and __yuri_value_call(friend,"getHp") > 1 then
					exclude = true
				end
				if not exclude and not hasManjuanEffect(friend) and __yuri_value_call(friend,"isWounded") then
					target = friend
				end
			end
		end
		if not target then return false end
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player))
			if not fvalueCard and not __yuri_value_call(self.player,"hasFlag",__yuri_value_call(fcard,"getSuitString")) then
				first_card = fcard
				first_found = true
				if fcard:isRed() then colors = "red" end
				if fcard:isBlack() then colors = "black" end
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player))
					if colors == "red" then
						if first_card ~= scard and scard:isBlack() and not svalueCard then
							second_card = scard
							second_found = true
						end
					else
						if first_card ~= scard and scard:isRed() and not svalueCard then
							second_card = scard
							second_found = true
						end
					end
				end
				if second_found then break end
			end
		end
	end

	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local to_use = {first_id, second_id}
		local card_str = string.format("#helptheweak:%s:", table.concat(to_use, "+"))
		local acard = policy(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value["helptheweak"] = sgs.ai_use_value.Peach - 0.1
sgs.ai_use_priority["helptheweak"] = sgs.ai_use_priority.Peach - 0.1
sgs.ai_card_intention["helptheweak"] = -60
sgs.dynamic_value.benefit["helptheweak"] = true

sgs.ai_fill_skill["changesexual"] = function(self,inclusive,request)
	if self.player:isNude() or __yuri_value_call(self.player,"hasFlag","AI_dont_changesexual") then return false end
	self.enemies = self:sort(self.enemies, "defenseSlash")
	local girlpoint = 0
	local boypoint = 0
	local endgirlpoint = 0
	local endboypoint = 0
	local hasslash = false
	local needjink = true
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local cl = (__yuri_value_call(self.player,"getHandcardNum")+self.player:getEquips():length())
	cards = self:sortByUseValue(cards,true)
	for _, card in ipairs(cards) do
		if __yuri_value_call(card,"isKindOf","Slash") then
			endgirlpoint = endgirlpoint + 1
			hasslash = true
		end
		if __yuri_value_call(card,"isKindOf","Jink") then
			needjink = false
			endboypoint = endboypoint + 1
		end
		if card:isBlack() and not __yuri_value_call(card,"isKindOf","Slash") then
			endboypoint = endboypoint + 1
		end
		if card:isRed() and not __yuri_value_call(card,"isKindOf","Jink") then
			endgirlpoint = endgirlpoint + 1
		end
	end
	for _,enemy in ipairs(self.enemies) do
		local skills = enemy:getVisibleSkillList()
		local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
		if (not self:slashProhibit(slash, enemy, self.player)) and self:slashIsAvailable() then
			if __yuri_value_call(self.player,"inMyAttackRange",enemy) and (self.player:canSlash(enemy, slash) or ((not hasslash) and endboypoint > 0)) and (skills:length() > 0 or (enemy:getArmor() and enemy:getArmor():getClassName() ~= "GaleShell")) then
				boypoint = boypoint + 2
			end
			if hasslash and not __yuri_value_call(self.player,"inMyAttackRange",enemy) then
				girlpoint = girlpoint + 1
				if self:isWeak(enemy) then
					girlpoint = girlpoint + 2
				end
			end
		end
	end
	local current = self.room:getCurrent()
	for _,p in sgs.qlist(self.room:getOtherPlayers(current)) do
		local card = clone(self,"snatch")
		if current:isCardLimited(card, sgs.Card_MethodUse, true) then break end
		if self.room:isProhibited(current, p, card) or __yuri_value_call(current,"distanceTo",p)>1 then continue end
		if self:isFriend(p) and (p:containsTrick("indulgence") or p:containsTrick("supply_shortage")) and not p:containsTrick("YanxiaoCard") then
		elseif self:isEnemy(p) and not p:isNude() then
		else continue end
		if self:getCardsNum("Snatch") == 0 then break end
		if __yuri_value_call(self.player,"isMale") then
			self:setStrategyPlayerFlag(self.player,'AI_dont_changesexual',true)
			local card_str = ("#changesexual:%d:")
			return policy(self,card_str)
		else
			return false
		end
	end

	if girlpoint >= boypoint and __yuri_value_call(self.player,"isMale") and girlpoint > 0 and cl > 1 then
		self:setStrategyPlayerFlag(self.player,'AI_dont_changesexual',true)
		local card_str = ("#changesexual:%d:")
		return policy(self,card_str)
	end
	if girlpoint < boypoint and self.player:isFemale() and boypoint > 0 and cl > 1 then
		self:setStrategyPlayerFlag(self.player,'AI_dont_changesexual',true)
		local card_str = ("#changesexual:%d:")
		return policy(self,card_str)
	end
	if (endgirlpoint >= endboypoint or needjink) and __yuri_value_call(self.player,"isMale") and cl <= 2 then
		self:setStrategyPlayerFlag(self.player,'AI_dont_changesexual',true)
		local card_str = ("#changesexual:%d:")
		return policy(self,card_str)
	end
	if endgirlpoint < endboypoint and self.player:isFemale() and cl <= 2 and not needjink then
		self:setStrategyPlayerFlag(self.player,'AI_dont_changesexual',true)
		local card_str = ("#changesexual:%d:")
		return policy(self,card_str)
	end
	return false

end

sgs.ai_skill_use_func["#changesexual"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["changesexual"] = sgs.ai_use_value.ExNihilo
sgs.ai_use_priority["changesexual"] = sgs.ai_use_priority.ExNihilo - 0.1
sgs.dynamic_value.benefit["changesexual"] = true


sgs.ai_fill_skill["sexualadvantage"] = function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			local idc = visible(self,id)
			if idc:isBlack() and __yuri_value_call(self.player,"isMale") and self:slashIsAvailable() and not __yuri_value_call(idc,"isKindOf","Slash") then
				table.insert(cards, idc)
			end
		end
	end
	cards = self:sortByUseValue(cards,true)
	for _, card in ipairs(cards) do
		if card:isBlack() and __yuri_value_call(self.player,"isMale") and self:slashIsAvailable() and not __yuri_value_call(card,"isKindOf","Slash") then
			return policy(self,("slash:sexualadvantage[%s:%s]=%d"):format(__yuri_value_call(card,"getSuitString"), card:getNumberString(), card:getId()))
		end
	end
end
sgs.ai_view_as.sexualadvantage = function(card, player, card_place)
	local suit = __yuri_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __yuri_value_call(card,"getEffectiveId")

	if __yuri_value_call(player,"isMale") and __yuri_value_call(card,"isKindOf","EquipCard") then
		return ("slash:sexualadvantage[%s:%s]=%d"):format(suit, number, card_id)
	elseif player:isFemale() and card:isRed() and not __yuri_value_call(card,"isKindOf","Jink") then
		return ("jink:sexualadvantage[%s:%s]=%d"):format(suit, number, card_id)
	end
end
function sgs.ai_cardneed.sexualadvantage(to, card, self)
	if to:getCardCount() > 3 then return false end
	if to:isNude() then return card:isRed() end
	return card:isRed()
end
sgs.ai_use_value["sexualadvantage"] = sgs.ai_use_value.Slash + 1


sgs.ai_skill_invoke.tomowodaji = function(self, data)
    local damage = data:toDamage()
	if not self:damageStruct(damage) then return false end
	local block_worth = 0
	if damage.damage > 0 and damage.to and self:isFriend(damage.to) and damage.to:objectName() ~= self.player:objectName() then
		if __yuri_value_call(damage.to,"getHp") <= damage.damage and (__yuri_value_call(damage.to,"isLord") or self:getCardsNum("Peach") > 0 or __yuri_value_call(self.player,"getHp") > 1) then
			block_worth = block_worth + 1
		end
		if self:getCardsNum("Slash") > 0 and damage.from and self:isEnemy(damage.from) and (__yuri_value_call(self.player,"getHp") > 3 or (self:isWeak(damage.from) and (self:getCardsNum("Peach") > 0 or __yuri_value_call(self.player,"getHp") > 1))) then
			block_worth = block_worth + 1
		end
		if __yuri_value_call(self.player,"getHp") >= 4 and __yuri_value_call(damage.to,"getHp") < 4 then
			block_worth = block_worth + 1
		end
	end
	if damage.to:objectName() == self.player:objectName() then
		if self:ajustDamage(damage.from,damage.to,damage.damage,damage.card,damage.nature)>1 then
			return true
		end
		local slashcount = self:getCardsNum("Slash")
		if slashcount > 0 then
			local slash = self:getCard("Slash")
			assert(slash)
			if damage.from and damage.from:objectName() ~= self.player:objectName() then
				local dummy_use = self:aiUseCard(slash, dummy_plan(true, 0, self.room:getOtherPlayers(damage.from)))
				if dummy_use.card and dummy_use.to:length() > 0 and dummy_use.to:contains(damage.from) then
					return true
				end
			end
		end
	end
	return block_worth > 0
end

sgs.ai_choicemade_filter.skillInvoke["tomowodaji"] = function(self, player, promptlist)
	local damage = room_tag(self,"tomowodaji","Damage")
	if promptlist[#promptlist] == "yes" then
		self:updateIntention(self.player, damage.to, -60)
	end
end

sgs.ai_ajustdamage_from.japenknifejile = function(self, from, to, card, nature)
    if from and card and __yuri_value_call(card,"isKindOf","Slash") and not self:beFriend(to, from)
    then
        return __yuri_value_call(from,"getMark","@defensive_distance_test")
    end
end

sgs.ai_skill_invoke.japenknifejile = function(self, data)
	local damage = data:toDamage()
	if self:cantDamageMore(damage.from, damage.to) then return false end
	if self:isWeak(self.player) then
		return false
	else
		return self:isEnemy(damage.to)
	end
end

sgs.japenknifejile_suit_value = {
	spade = 3.9,
	club = 3.9
}

sgs.japenknifejile_keep_value =
{
	Axe				= -2,
	Blade			= -1,
	Crossbow 		= -1,
	IceSword 		= -1,
	GudingBlade     = -1,
	YxSword    		= -1,
	YitianSword    	= -1,
	QinggangSword 	= -1,
	Spear 			= -1,
	Fan				= -2,
	KylinBow		= -2,
	Halberd			= -2,
	MoonSpear		= -2,
	SpMoonspear 	= -1,
}
sgs.japenknifejile_use_value =
{
	Axe				= -10,
	Blade			= -10,
	Crossbow 		= -10,
	IceSword 		= -10,
	GudingBlade     = -10,
	YxSword    		= -10,
	YitianSword    	= -10,
	QinggangSword 	= -10,
	Spear 			= -10,
	Fan				= -10,
	KylinBow		= -10,
	Halberd			= -10,
	MoonSpear		= -10,
	SpMoonspear 	= -10,
}
sgs.ai_choicemade_filter.skillInvoke["japenknifejile"] = function(self, player, promptlist)
	local damage = room_tag(self,"japenknifejile","Damage")
	if promptlist[#promptlist] == "yes" then
		self:updateIntention(self.player, damage.to, 50)
	end
end

sgs.ai_skill_invoke.skeleton = function(self, data)
	local effect = data:toCardUse()
	self:updatePlayers()
	local needpeach = false
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			needpeach = true
			break
		end
	end
	if self:isEnemy(effect.from) and not self.player:isKongcheng() then
		local count = 13 - (__yuri_value_call(effect.from,"getHandcardNum")+effect.from:getEquips():length())
		if count <= 0 then count = 1 end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		cards = self:sortByKeepValue(cards, true)
		for _, card in ipairs(cards) do
			if __yuri_value_call(card,"getNumber") >= count then
				if (self:isWeak(self.player) and __yuri_value_call(effect.card,"isKindOf","Slash") and __yuri_value_call(card,"isKindOf","Jink")) or ((self:isWeak(self.player) or needpeach) and self:getCardsNum("Peach") < 2 and __yuri_value_call(card,"isKindOf","Peach")) then
					return false
				else
					if __yuri_value_call(effect.from,"hasSkill","zhixi") then
						local ecards = known(effect.from:getKnownCards(),"known source hand")
						local hasspade = false
						for _, card in sgs.qlist(ecards) do -- 查找敵人已知手牌的黑桃牌
							local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), effect.from:objectName())
							if __yuri_value_call(card,"hasFlag","visible") or __yuri_value_call(card,"hasFlag",flag) then
								if __yuri_value_call(card,"getSuit") == sgs.Card_Spade then
									hasspade = true
								end
								if hasspade then break end
							end
						end
						if (hasspade and __yuri_value_call(effect.from,"faceUp")) or ((not hasspade) and not __yuri_value_call(effect.from,"faceUp")) then
							if self:isWeak(self.player) then
								return true
							else
								return false
							end
						else
							return true
						end
					else
						if __yuri_value_call(effect.from,"faceUp") then
							return true
						else
							return false
						end
					end
				end
			end
		end
	end
	if self:isFriend(effect.from) and not __yuri_value_call(effect.from,"faceUp") and not self.player:isKongcheng() and not __yuri_value_call(effect.from,"hasSkill","zhixi") then
		local count = 13 - (__yuri_value_call(effect.from,"getHandcardNum")+effect.from:getEquips():length())
		if count <= 0 then count = 1 end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _, card in ipairs(cards) do
			if __yuri_value_call(card,"getNumber") >= count then
				return true
			end
		end
	end
	if self:isFriend(effect.from) and not self.player:isKongcheng() and __yuri_value_call(effect.from,"hasSkill","zhixi") then
		local count = 13 - (__yuri_value_call(effect.from,"getHandcardNum")+effect.from:getEquips():length())
		local caninvoke = false
		if count <= 0 then count = 1 end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _, card in ipairs(cards) do
			if __yuri_value_call(card,"getNumber") >= count then
				caninvoke = true
			end
			if caninvoke then break end
		end
		if not caninvoke then return false end
		local fcards = known(effect.from:getKnownCards(),"known source hand")
		local hasspade = false
		for _, card in sgs.qlist(fcards) do -- 查找已知手牌的黑桃牌
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), effect.from:objectName())
			if __yuri_value_call(card,"hasFlag","visible") or __yuri_value_call(card,"hasFlag",flag) then
				if __yuri_value_call(card,"getSuit") == sgs.Card_Spade then
					hasspade = true
				end
				if hasspade then break end
			end
		end
		if (hasspade and __yuri_value_call(effect.from,"faceUp")) or ((not hasspade) and not __yuri_value_call(effect.from,"faceUp")) then
			return true
		else
			return false
		end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["skeleton"] = function(self, player, promptlist)
	local effect = room_tag(self,"skeleton","CardUse")
		if promptlist[#promptlist] == "yes" and effect.from and __yuri_value_call(effect.from,"faceUp") then
			self:updateIntention(self.player, effect.from, -15)
		end
		if promptlist[#promptlist] == "yes" and effect.from and not __yuri_value_call(effect.from,"faceUp") then
			self:updateIntention(self.player, effect.from, 0)
		end
end

sgs.ai_skill_cardask["@skeleton"] = function(self, data, pattern, target, target2)
	if target and self:isFriend(target) and not self:toTurnOver(target,0,"skeleton") then return "." end
	if target and not self:toTurnOver(target,0,"skeleton") and __yuri_value_call(self.player,"faceUp") then return "." end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if matches_source_pattern(self,pattern,h)
		then return __yuri_value_call(h,"getEffectiveId") end
	end
	return "."
end

sgs.ai_target_revises.skeleton = function(to,card)
	if not __yuri_value_call(to,"faceUp") and (__yuri_value_call(card,"isKindOf","Slash") or card:isNDTrick())
	then return true end
end

sgs.ai_skill_invoke.strangeguy = function(self, data)
	local feedback = 0
	self.enemies = self:sort(self.enemies, "defenseSlash")
	if self.player:getCards("j"):length() > 0 then
		local maji = false
		for _,friend in ipairs(self.friends) do
			if __yuri_value_call(friend,"hasSkill","goddess_new") then
				maji = true
				break
			end
		end
		if not maji then
			feedback = feedback + 20
		end
		if self:hasWizard(self.friends) and not maji then
			feedback = feedback - 15
		end
		if self:hasWizard(self.enemies) and not maji then
			return true
		end
	end
	local weaponcount = 0
	local armorcount = 0
	local dhorsecount = 0
	local ohorsecount = 0
	local needweapon = false
	local cards = self.player:getHandcards()
	for _, c in sgs.qlist(cards) do
		if __yuri_value_call(c,"isKindOf","Armor") then
			armorcount = armorcount + 1
		end
		if __yuri_value_call(c,"isKindOf","Weapon") then
			weaponcount = weaponcount + 1
		end
		if __yuri_value_call(c,"isKindOf","DefensiveHorse") then
			dhorsecount = dhorsecount + 1
		end
		if __yuri_value_call(c,"isKindOf","OffensiveHorse") then
			ohorsecount = ohorsecount + 1
		end
	end
	if weaponcount > 0 or ohorsecount > 0 then
		if not self.player:getWeapon() or (self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow")) then
			needweapon = true
			if __yuri_value_call(self.player,"getHp") > 2 then feedback = feedback - 1 end
		end
		if not self.player:getOffensiveHorse() then
			needweapon = true
			if __yuri_value_call(self.player,"getHp") > 2 then feedback = feedback - 1 end
		end
	end
	if armorcount > 0 then
		if self.player:getArmor() and self.player:getArmor():getClassName() == "GaleShell" then
			feedback = feedback - 3
		end
		if not (armorcount == 1 and self:getCardsNum("GaleShell") == 1) then
			if self.player:getArmor() == nil then
				feedback = feedback - 1
			end
			if __yuri_value_call(self.player,"isWounded") and self.player:getArmor() and self.player:getArmor():getClassName() == "SilverLion" then
				return false
			end
		end
	end
	if dhorsecount > 0 and not self.player:getDefensiveHorse() then
		feedback = feedback - 1
	end
	for _,enemy in ipairs(self.enemies) do
		if self:getCardsNum("Slash") > 0 and (not self:slashProhibit(slash, enemy, self.player)) and (needweapon or (__yuri_value_call(self.player,"inMyAttackRange",enemy) and self.player:canSlash(enemy, slash))) then
			feedback = feedback - 1
			if self:isWeak(enemy) then
				feedback = feedback - 1
				if enemy:isNude() then
					feedback = feedback - 5
				end
			end
		end
		if __yuri_value_call(enemy,"inMyAttackRange",self.player) then
			if __yuri_value_call(self.player,"getHandcardNum") <= __yuri_value_call(self.player,"getHp") then
				feedback = feedback + 1
				if self:isWeak(self.player) and self:getCardsNum("Peach") < 2 then
					feedback = feedback + 1
				end
			end
			if __yuri_value_call(self.player,"getHandcardNum") > __yuri_value_call(self.player,"getHp") and self:isWeak(self.player) then
				feedback = feedback + 1
				if self:getCardsNum("Peach") == 0 then
					feedback = feedback + 1
				end
				if self:getCardsNum("Peach") > 1 then
					feedback = feedback - 1
				end
			end
		end
	end
	return feedback > 0
end

sgs.ai_fill_skill["tobenature"] = function(self,inclusive,request)
	local canuse = false
	for _, enemy in ipairs(self.enemies) do
		if __yuri_value_call(enemy,"getHandcardNum") > __yuri_value_call(self.player,"getHandcardNum") then
			canuse = true
			break
		end
		if __yuri_value_call(enemy,"getHandcardNum") < __yuri_value_call(self.player,"getHandcardNum") and (__yuri_value_call(self.player,"getHandcardNum") - __yuri_value_call(enemy,"getHandcardNum")) < 3 and __yuri_value_call(enemy,"hasSkill","kongcheng") then
			canuse = true
			break
		end
	end
	for _, friend in ipairs(self.friends) do
		if canuse then break end
		if __yuri_value_call(friend,"getHandcardNum") < __yuri_value_call(self.player,"getHandcardNum") and not ((__yuri_value_call(friend,"hasSkill","kongcheng") and __yuri_value_call(friend,"getHandcardNum") == 0) or __yuri_value_call(friend,"hasSkill","manjuan")) then
			canuse = true
			break
		end
		if __yuri_value_call(friend,"getHandcardNum") > __yuri_value_call(self.player,"getHandcardNum") and __yuri_value_call(friend,"hasSkill","hunzi") and __yuri_value_call(friend,"getMark","hunzi") == 0
		  and friend:objectName() == self.player:getNextAlive():objectName() and __yuri_value_call(friend,"getHp") == (__yuri_value_call(friend,"getHandcardNum") - __yuri_value_call(self.player,"getHandcardNum") + 1) then
			canuse = true
			break
		end
	end
	if canuse and (not self.player:hasUsed("#tobenature")) then
		return policy(self,"#tobenature:.:")
	end
end

sgs.ai_skill_use_func["#tobenature"] = function(card, use, self)
    self:updatePlayers()
	self.enemies = self:sort(self.enemies, "handcard")
	if __yuri_value_call(self.player,"getMark","Intheforest") == 0 then
		local goodtargets = {}
		local normal = {}
		for _, enemy in ipairs(self.enemies) do
			if __yuri_value_call(enemy,"getHandcardNum") > __yuri_value_call(self.player,"getHandcardNum") then
				table.insert(normal, enemy)
				if __yuri_value_call(enemy,"getHp") <= (__yuri_value_call(enemy,"getHandcardNum") - __yuri_value_call(self.player,"getHandcardNum")) then
					table.insert(goodtargets, enemy)
				end
			end
			if __yuri_value_call(enemy,"getHandcardNum") < __yuri_value_call(self.player,"getHandcardNum") and __yuri_value_call(enemy,"getHandcardNum") == 0 and __yuri_value_call(self.player,"getHandcardNum") < 3 and __yuri_value_call(enemy,"hasSkill","kongcheng") then
				table.insert(goodtargets, enemy)
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if __yuri_value_call(friend,"getHandcardNum") < __yuri_value_call(self.player,"getHandcardNum") and not ((__yuri_value_call(friend,"hasSkill","kongcheng") and __yuri_value_call(friend,"getHandcardNum") == 0) or __yuri_value_call(friend,"hasSkill","manjuan")) then
				table.insert(normal, friend)
				if self:isWeak(friend) then
					table.insert(goodtargets, friend)
				end
			end
			if __yuri_value_call(friend,"getHandcardNum") > __yuri_value_call(self.player,"getHandcardNum") and __yuri_value_call(friend,"hasSkill","hunzi") and __yuri_value_call(friend,"getMark","hunzi") == 0
			  and friend:objectName() == self.player:getNextAlive():objectName() and __yuri_value_call(friend,"getHp") == (__yuri_value_call(friend,"getHandcardNum") - __yuri_value_call(self.player,"getHandcardNum") + 1) then
				use.card = policy(self,"#tobenature:.:")
				if use.to then use.to:append(friend) end
				return
			end
		end
		use.card = policy(self,"#tobenature:.:")
		if use.to then
			if #goodtargets > 0 then
				use.to:append(goodtargets[1])
				return
			end
			if #normal > 0 then use.to:append(normal[1]) end
		end
		return
	else
		use.card = policy(self,"#tobenature:.:")
		if use.to then
			for _, enemy in ipairs(self.enemies) do
				if __yuri_value_call(enemy,"getHandcardNum") > __yuri_value_call(self.player,"getHandcardNum") then
					use.to:append(enemy)
				end
			end
			for _, friend in ipairs(self.friends_noself) do
				if __yuri_value_call(friend,"getHandcardNum") < __yuri_value_call(self.player,"getHandcardNum") then
					use.to:append(friend)
				end
			end
			assert(use.to:length() > 0)
		end
	end
end
sgs.ai_card_intention.tobenature = function(self, card, from, tos)
	for _,to in ipairs(tos) do

		local intention = 60
		if __yuri_value_call(to,"getHandcardNum") < __yuri_value_call(from,"getHandcardNum") and not (__yuri_value_call(to,"hasSkill","kongcheng") and __yuri_value_call(to,"getHandcardNum") == 0) then
			intention = -80
		end
		self:updateIntention(from, to, intention)
	end
end
sgs.ai_use_value["tobenature"] = 4
sgs.ai_use_priority["tobenature"] = sgs.ai_use_priority.Peach - 0.1


sgs.ai_skill_cardask["@tobenatureAsk"] = function(self, data, pattern, target, target2)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if matches_source_pattern(self,pattern,h)
		then return __yuri_value_call(h,"getEffectiveId") end
		if __yuri_value_call(h,"isKindOf",pattern)
		then return __yuri_value_call(h,"getEffectiveId") end
	end
	return self:getCardId(pattern)
end

sgs.ai_skill_invoke.zerodifference = function(self, data)
	return true
end
sgs.ai_skill_use["@@heapridge"] = function(self, prompt)
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		cards = self:sortByUseValue(cards, true)
		local diamonds = {}
		local hearts = {}
		local spades = {}
		local clubs = {}
		local needpeach = false
		local wconter = observation_mark(self,"AI_has_clubs") + observation_mark(self,"AI_has_spades") + observation_mark(self,"AI_has_diamonds") + observation_mark(self,"AI_has_hearts")
		if self:isWeak(self.player) then needpeach = true end
		for _, friend in ipairs(self.friends_noself) do
			if self:isWeak(friend) then
				needpeach = true
			end
		end
		for _, c in ipairs(cards) do
			if not __yuri_value_call(c,"isKindOf","ExNihilo") or (needpeach and not __yuri_value_call(c,"isKindOf","Peach")) then
				if __yuri_value_call(c,"getSuit") == sgs.Card_Club and #clubs < 4 then
					if wconter >= 3 or not (observation_mark(self,"AI_has_clubs") > 0 and (self:getKeepValue(c) > 5 or self:getUseValue(c) >= 6)) then
						table.insert(clubs, c:getId())
					end
				elseif __yuri_value_call(c,"getSuit") == sgs.Card_Heart and #hearts < 4 then
					if wconter >= 3 or not (observation_mark(self,"AI_has_hearts") > 0 and (self:getKeepValue(c) > 5 or self:getUseValue(c) >= 6)) then
						table.insert(hearts, c:getId())
					end
				elseif __yuri_value_call(c,"getSuit") == sgs.Card_Spade and #spades < 4 then
					if wconter >= 3 or not (observation_mark(self,"AI_has_spades") > 0 and (self:getKeepValue(c) > 5 or self:getUseValue(c) >= 6)) then
						table.insert(spades, c:getId())
					end
				elseif __yuri_value_call(c,"getSuit") == sgs.Card_Diamond and #diamonds < 4 then
					if wconter >= 3 or not (observation_mark(self,"AI_has_diamonds") > 0 and (self:getKeepValue(c) > 5 or self:getUseValue(c) >= 6)) then
						table.insert(diamonds, c:getId())
					end
				end
			end
		end
		if #diamonds >= 4 or #clubs >= 4 or #hearts >= 4 or #spades >= 4 then
			if #clubs >= 4 then
				self:sourceImmediateEffect("heapridge","write",self.player,"AI_has_clubs",clubs)
				return "#heapridge:"..table.concat(clubs, "+")..":"
			end
			if #spades >= 4 then
				self:sourceImmediateEffect("heapridge","write",self.player,"AI_has_spades",spades)
				return "#heapridge:"..table.concat(spades, "+")..":"
			end
			if #diamonds >= 4 then
				self:sourceImmediateEffect("heapridge","write",self.player,"AI_has_diamonds",diamonds)
				return "#heapridge:"..table.concat(diamonds, "+")..":"
			end
			if #hearts >= 4 then
				self:sourceImmediateEffect("heapridge","write",self.player,"AI_has_hearts",hearts)
				return "#heapridge:"..table.concat(hearts, "+")..":"
			end
		end
	return "."
end


sgs.ai_event_callback[sgs.AfterDrawNCards].lovesong = function(self, player, data)
	local draw = event_draw(data)
	if draw.reason ~= "InitialHandCards" then return false end
	for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
		if __yuri_value_call(sb,"hasSkill","lovesong") and __yuri_value_call(sb,"getMark","lovesong") > 0 then
			role_event(self,sb,"lovesong",viewer_role(self,sb))
			self:updatePlayers()
		end
	end
end

sgs.ai_ajustdamage_from.lovesong = function(self,from,to,slash,nature)
	if string.find(to:getGeneralName(), "ronomiyokaruta") or string.find(to:getGeneral2Name(), "ronomiyokaruta") then
		if viewer_role(self,to) ~= "renegade" and (viewer_role(self,from) == viewer_role(self,to) or (__yuri_value_call(to,"isLord") and viewer_role(self,from) == "loyalist") or (__yuri_value_call(from,"isLord") and viewer_role(self,to) == "loyalist")) then
			return -1
		end
	end
end


sgs.ai_skill_invoke.loyalm = function(self, data)
    local damage = data:toDamage()
	if damage.from:isNude() then
		return true
	end
	if self:isFriend(damage.from) and damage.from:objectName() ~= self.player:objectName() and (damage.from:getArmor() and (damage.from:getArmor():isKindOf("GaleShell") or (__yuri_value_call(damage.from,"isWounded") and damage.from:getArmor():isKindOf("SilverLion")))) then
		return true
	end
	if self:isEnemy(damage.from) then
		return true
	end
	return false
end
sgs.ai_skill_cardchosen["loyalm"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("e")) do
			if (__yuri_value_call(card,"isKindOf","SilverLion") and __yuri_value_call(who,"isWounded")) or __yuri_value_call(card,"isKindOf","GaleShell") then
				return card
			end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"isKindOf","SilverLion") then
				table.insert(goodchice, card)
			end
			if __yuri_value_call(card,"isKindOf","Weapon") or __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_skill_playerchosen.loyalm = function(self, targets)
	self:updatePlayers()
	local targets = {}
	local good_targets = {}
	local best_target = nil
	self.friends = self:sort(self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		table.insert(targets, friend)
		if self:isWeak(friend) then table.insert(good_targets, friend) end
		if ((__yuri_value_call(friend,"getHandcardNum")+friend:getEquips():length()) <= 1 and __yuri_value_call(friend,"getHp") == 1) or (self:isWeak(friend) and __yuri_value_call(friend,"isLord")) then
			best_target = friend
			break
		end
	end
	if best_target then return best_target end
	if #good_targets > 0 then return good_targets[1] end
	return targets[1]
end
sgs.ai_choicemade_filter.skillInvoke["loyalm"] = function(self, player, promptlist)
	local damage = room_tag(self,"loyalm","Damage")
	if promptlist[#promptlist] == "yes" then
		self:updateIntention(self.player, damage.to, 10)
	else
		self:updateIntention(self.player, damage.to, -10)
	end
end
sgs.ai_playerchosen_intention["loyalm"] = function(self, from, to)
	self:updateIntention(from, to, -30)
end

sgs.ai_can_damagehp.loyalm = function(self,from,card,to)
	return __yuri_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and from and (self:doDisCard(from, "he") or from:isNude())
end

sgs.ai_getLeastHandcardNum_skill.scoopthemoonup = function(self, player, least)
	if least < 3 and self.room:getDiscardPile():length() > 0 then
		return 3
	end
end

sgs.ai_skill_invoke.deterrence = function(self, data)
	local current = self.room:getCurrent()
	return self:isEnemy(current)
end
sgs.ai_choicemade_filter.skillInvoke["deterrence"] = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then self:updateIntention(player, target, 50) end
	end
end

sgs.ai_skill_invoke.wannawin = function(self, data)
	local target = data:toPlayer()
	if not target or self:isFriend(target) or (self:isEnemy(target) and __yuri_value_call(target,"getHandcardNum") == 1 and target:getEquips():length() == 0 and target:getCards("j"):length() > 0) then self:writeCurrentSourceSlot("wannawin",nil) return false end
	local invoke = self:doDisCard(target, "h")
	return invoke
end
sgs.ai_fill_skill["wannawin"] = function(self,inclusive,request)
	if not self.player:isKongcheng() then return policy(self,"#wannawin:.:") end
end
sgs.ai_skill_use_func["#wannawin"] = function(card, use, self)
	if self.player:isKongcheng() then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	self.enemies = self:sort(self.enemies, "defense")
	local max_card = self:getMaxCard()
	local max_point = __yuri_value_call(max_card,"getNumber")
	local needpeach = false
	for _, friend in ipairs(self.friends) do
		if self:isWeak(friend) then
			needpeach = true
			break
		end
	end
	if needpeach then
		max_point = 0
		for _, c in ipairs(cards) do
			if not __yuri_value_call(c,"isKindOf","Peach") then
				if __yuri_value_call(c,"getNumber") > max_point then
					max_point = __yuri_value_call(c,"getNumber")
					max_card = c
				end
			end
		end
	end
	if (self:needKongcheng() and __yuri_value_call(self.player,"getHandcardNum") == 1) or not self:hasLoseHandcardEffective() then
		for _, enemy in ipairs(self.enemies) do
			if self:doDisCard(enemy, "h", true) and __yuri_value_call(enemy,"getMark","Wannawinmark") == 0 and __yuri_value_call(self.player,"canPindian",enemy) then
				use.card = policy(self,"#wannawin:"..max_card:getId()..":")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if __yuri_value_call(enemy,"getMark","Wannawinmark") == 0 and self:doDisCard(enemy, "h", true) and __yuri_value_call(self.player,"canPindian",enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy) == __yuri_value_call(enemy,"getHandcardNum") then
				allknown = allknown + 1
			end
			if (enemy_max_card and max_point > __yuri_value_call(enemy_max_card,"getNumber") and allknown > 0)
				or (enemy_max_card and max_point > __yuri_value_call(enemy_max_card,"getNumber") and allknown < 1 and max_point > 10)
				or (not enemy_max_card and max_point > 10) then
				use.card = policy(self,"#wannawin:"..max_card:getId()..":")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	for _, friend in ipairs(self.friends) do
		if self.player:objectName() ~= friend:objectName() and not friend:isKongcheng() and __yuri_value_call(friend,"getMark","Wannawinmark") == 0 and __yuri_value_call(self.player,"canPindian",friend)
		and (friend:getCards("j"):length() > 0 or (friend:getArmor() and (friend:getArmor():getClassName() == "GaleShell" or (__yuri_value_call(friend,"isWounded") and friend:getArmor():getClassName() == "SilverLion")))) then
			use.card = policy(self,"#wannawin:"..max_card:getId()..":")
			if use.to then use.to:append(friend) end
			return
		end
	end
	if self:getOverflow() > 0 then
		for _, enemy in ipairs(self.enemies) do
			if __yuri_value_call(enemy,"getMark","Wannawinmark") == 0 and self:doDisCard(enemy, "h", true) and __yuri_value_call(self.player,"canPindian",enemy) then
				use.card = policy(self,"#wannawin:"..max_card:getId()..":")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	return
end
sgs.ai_skill_cardchosen["wannawin"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"getClassName") == "SilverLion" then
				table.insert(goodchice, card)
			end
			if __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_use_priority.wannawin = 3.4

sgs.ai_card_intention.wannawin = function(self, card, from, tos)
	local intention = 15
	local to = tos[1]
	if self:needKongcheng(to) and __yuri_value_call(to,"getHandcardNum") == 1 then
		intention = 0
	end
	if to:getCards("j"):length() > 0 or (to:getArmor() and (to:getArmor():getClassName() == "GaleShell" or (__yuri_value_call(to,"isWounded") and to:getArmor():getClassName() == "SilverLion"))) then
		intention = 0
	end
	self:updateIntention(from, tos[1], intention)
end

sgs.ai_cardneed.wannawin = sgs.ai_cardneed.bignumber
sgs.dynamic_value.control_card.wannawin = true

sgs.ai_card_priority.theace = function(self,card,v)
	if (__yuri_value_call(card,"getNumber") == 1 or __yuri_value_call(card,"getNumber") == 13)
	then return 10 end
end




sgs.ai_skill_invoke.hotfight = function(self, data)
	local current = data:toPlayer()
	if __yuri_value_call(self.player,"getMark","@hotfightmark") > 0 and ((self:isEnemy(current) and not (__yuri_value_call(self.player,"getMark","@hotfightmark") <= 2 and self:isWeak(self.player))) or self.player:objectName() == current:objectName()) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["hotfight"] = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if promptlist[#promptlist] == "yes" then
		self:updateIntention(self.player, current, 40)
	else
		self:updateIntention(self.player, current, 0)
	end
end
sgs.ai_fill_skill["hotfight"] = function(self,inclusive,request)
	if __yuri_value_call(self.player,"getMark","@hotfightmark") > 0 and __yuri_value_call(self.player,"hasSkill","hotfight") and not (__yuri_value_call(self.player,"getMark","@hotfightmark") <= 2 and self:isWeak(self.player)) then
		local card_str = ("fire_slash:hotfight[no_suit:0]=.")
		local card = policy(self,card_str)
		return card
	end
end
function sgs.ai_cardsview.hotfight(self, class_name, player)
	for _,card in sgs.qlist(self.player:getHandcards()) do
        if __yuri_value_call(card,"isKindOf",class_name) then return end
    end
	if class_name == "Slash" then
		if __yuri_value_call(player,"getMark","@hotfightmark") > 0 then
			return ("fire_slash:hotfight[no_suit:0]=.")
		end
	end
	if class_name == "Jink" then
		if __yuri_value_call(player,"getMark","@hotfightmark") > 0 then
			return ("jink:hotfight[no_suit:0]=.")
		end
	end
end

sgs.ai_use_value["hotfight"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["hotfight"] = sgs.ai_use_priority.Slash - 0.1


sgs.ai_playerchosen_intention["iris"] = function(self, from, to)
	self:updateIntention(from, to, 40)
end

sgs.ai_choicemade_filter.skillInvoke["iris"] = function(self, player, promptlist)
	local current = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if __yuri_value_call(p,"getMark","AI_iris") > 0 then
			clear_source_mark(self,p,"AI_iris")
			current = p
			break
		end
	end

	if promptlist[#promptlist] == "yes" then
		self:updateIntention(self.player, current, 40)
	else
		self:updateIntention(self.player, current, 0)
	end
end

sgs.ai_card_intention.dressing = function(self, card, from, tos)
	local intention = 20
	local to = tos[1]
	if (to:getArmor() and (to:getArmor():getClassName() == "GaleShell" or (__yuri_value_call(to,"isWounded") and to:getArmor():getClassName() == "SilverLion"))) then
		intention = 0
	end
	self:updateIntention(from, tos[1], intention)
end
sgs.ai_playerchosen_intention["dressing"] = function(self, from, to)
	self:updateIntention(from, to, -5)
end


sgs.ai_skill_cardask["@zhixi"] = function(self, data, pattern, target, target2)
	local damage = data:toDamage()
	if not self:damageStruct(damage) then
		return "."
	end
	if self:needToLoseHp(self.player,target, damage.card) then
		return "."
	end
	local card_id
	for _,card in sgs.qlist(self.player:getCards("he"))do
		if card:isBlack() then
			card_id = __yuri_value_call(card,"getEffectiveId")
			break
		end
	end
	if not card_id then return "." else return "$"..card_id end
	return "."
end


sgs.ai_skill_playerchosen.zhixi = function(self, targets)
	self:updatePlayers()
	local targets = {}
	local good_targets = {}
	local best_target = nil
	local enemytars = {}
	local best_etarget = nil
	self.friends_noself = self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		table.insert(targets, friend)
		if self:isWeak(friend) then table.insert(good_targets, friend) end
		if not __yuri_value_call(friend,"faceUp") then
			if (__yuri_value_call(friend,"getHandcardNum")+friend:getEquips():length()) <= 1 and __yuri_value_call(friend,"getHp") == 1 then best_target = friend end
		end
	end
	self.enemies = self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		table.insert(targets, enemy)
		if (self:isWeak(enemy) and enemy:isKongcheng()) or __yuri_value_call(enemy,"getHandcardNum") > 4 then table.insert(enemytars, enemy) end
		if __yuri_value_call(enemy,"getHandcardNum") > 6 then best_etarget = enemy end
	end
	if best_target then return best_target end
	if best_etarget then return best_etarget end
	if #good_targets > 0 then return good_targets[1] end
	if #enemytars > 0 then return enemytars[1] end
	return targets[1]
end

sgs.ai_skill_choice.zhixi = function(self,choices,data)
	local target = data:toPlayer()
	if self:isEnemy(target) and self:doDisCard(target, "he") then return "discard" end
	return "draw"
end

sgs.ai_choicemade_filter.skillChoice["zhixi"] = function(self, player, promptlist)
	local target = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if __yuri_value_call(p,"getMark","AI_zhixi") > 0 then
			target = p
			break
		end
	end
	if not target then return end
	if promptlist[#promptlist] == "draw" then
		self:updateIntention(self.player, target, -30)
	else
		self:updateIntention(self.player, target, 30)
	end
end
sgs.ai_suit_priority.zhixi= "club|diamond|heart|spade"
function sgs.ai_cardneed.zhixi(to, card, self)
	return __yuri_value_call(card,"getSuit") == sgs.Card_Spade and not self:hasSuit("spade", true, to)
end
sgs.zhixi_suit_value =
{
	spade = 4.9
}
sgs.ai_can_damagehp.zhixi = function(self,from,card,to)
	local has_black = false
	for _, card in sgs.qlist(complete_hand(self,to)) do
		if card:isBlack() then
			has_black = true
			break
		end
	end
	return __yuri_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and has_black
end

sgs.ai_skill_invoke.yuejian = function(self)
	local current = self.room:getCurrent()
	if current and self.player:isAlive() then
		if self:isFriend(current) and not self:needBear(current) then return true end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["yuejian"] = function(self, player, promptlist)	--yun
	local current = self.room:getCurrent()
	if not current then return end
	if self:needBear(current) or known(self:getRoleEstimate(current),"current player role inference") == "neutral" or self:getOverflow(current) <= 0 then return end
	local erzhang = self.room:findPlayerBySkillName("guzheng")
	if erzhang then return end
	if promptlist[#promptlist] == "yes" then self:updateIntention(player, current, -10) end
	if promptlist[#promptlist] ~= "yes" then self:updateIntention(player, current, 10) end
end

sgs.ai_fill_skill["turned"] = function(self,inclusive,request)
	return policy(self,"#turned:.:")
end

sgs.ai_skill_use_func["#turned"] = function(card, use, self)
	local targets = {}
	self.enemies = self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if (self:getCardsNum("Peach") < getCardsNum("Peach", enemy))
		  and __yuri_value_call(self.player,"getHandcardNum") > 0 and __yuri_value_call(enemy,"getHandcardNum") > 0 and self:doDisCard(enemy, "h") then
			table.insert(targets, enemy)
		end
	end

	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	self.enemies = self:sort(self.enemies, "handcard")
	self.friends_noself = self:sort(self.friends_noself, "handcard")
	for _, friend in ipairs(self.friends_noself) do
		if ((self:needKongcheng(friend) and not __yuri_value_call(friend,"hasSkill","kongcheng") and __yuri_value_call(friend,"getHandcardNum") < 3) or __yuri_value_call(friend,"hasSkill","tuntian"))
			and __yuri_value_call(friend,"getHandcardNum") > 0 and not hasManjuanEffect(friend) then
				table.insert(targets, friend)
		end
	end

	if __yuri_value_call(self.player,"getHandcardNum") > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not isCard("Peach", cards[1], enemy) and not isCard("Nullification", cards[1], enemy) and not isCard("Analeptic", cards[1], enemy)
			  and __yuri_value_call(enemy,"getHandcardNum") > 0 and (self:doDisCard(enemy, "h") or hasManjuanEffect(enemy)) then
				table.insert(targets, enemy)
			end
		end
	end

	if #targets == 0 then return end
	if use.to then
		self:sourceImmediateEffect("turned","write",targets[1],"turned_target")
		use.to:append(targets[1])
	end
	use.card = card
end

sgs.ai_skill_invoke.bffeedingpoisoning = function(self, data) -- 不知為啥，判斷式裡存在數字條件時，效果不會出來，雖然技能依然有效。也有可能是我腦袋混亂，天知道。
	local damage = data:toDamage()
	local invoke = false
	local count = 0
		self.enemies = self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			count = damage.damage - __yuri_value_call(damage.to,"getHp") - getCardsNum("Peach", enemy)
		end
		if count < 0 then count = -1 end
		if count >= 0 then invoke = true end
		if self:isFriend(damage.to) and (__yuri_value_call(self.player,"isWounded") or self:needToLoseHp(damage.to) or damage.to:hasSkills("yiji|quhu|huituo")) then return false end
		if self:isFriend(damage.to) and not __yuri_value_call(self.player,"isWounded") then return true end
		if viewer_role(self,damage.to) == "rebel" then
			if self:isEnemy(damage.to) and invoke then return false else return true end
		end
		if self:isEnemy(damage.to) and (__yuri_value_call(self.player,"isWounded") or self:needToLoseHp(damage.to) or damage.to:hasSkills("yiji|quhu|huituo")) then return true end
	return true
end

sgs.ai_choicemade_filter.skillInvoke["bffeedingpoisoning"] = function(self, player, promptlist)
	local damage = room_tag(self,"bffeedingpoisoning","Damage")
	if __yuri_value_call(self.player,"isWounded") then
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(self.player, damage.to, 40)
		end
	end
	if damage.to:hasSkills("yiji|quhu|huituo") then
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(self.player, damage.to, 15)
		else
			self:updateIntention(self.player, damage.to, -15)
		end
	end
end

sgs.ai_use_priority.turned = 0

sgs.ai_can_damagehp.newmember = function(self,from,card,to)
	return __yuri_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end

sgs.ai_playerchosen_intention.newmember = function(self, from, to)
	local intention = 0
	if __yuri_value_call(from,"getMark","discard") > 0 then
		clear_source_mark(self,from,"discard")
		intention = 15
		if (to:getArmor() and (to:getArmor():getClassName() == "GaleShell" or (__yuri_value_call(to,"isWounded") and to:getArmor():getClassName() == "SilverLion"))) then
			intention = 0
		end
		if to:getCards("j"):length() > 0 and not to:containsTrick("YanxiaoCard") then
			intention = 0
		end
	end
	if __yuri_value_call(from,"getMark","draw") > 0 then
		clear_source_mark(self,from,"draw")
		intention = -40
		if self:needKongcheng(to) then intention = 10 end
	end
	if __yuri_value_call(from,"getMark","getk") > 0 then
		clear_source_mark(self,from,"getk")
		intention = 20
		if to:isChained() then intention = -10 end
	end
	self:updateIntention(from, to, intention)
end

sgs.ai_choicemade_filter.skillInvoke["songforatsu"] = function(self, player, promptlist)
	local dying = room_tag(self,"songforatsu","Dying")
	local who = dying.who
	if promptlist[#promptlist] == "yes" then
		self:updateIntention(self.player, who, 40)
	else
		self:updateIntention(self.player, who, -15)
	end
end

sgs.ai_skill_invoke.introvert = function(self, data)
	local use = data:toCardUse()
	if self:isFriend(use.from) and (__yuri_value_call(use.card,"isKindOf","Dismantlement") or __yuri_value_call(use.card,"isKindOf","Snatch")) then
		return false
	end
	if self:isEnemy(use.from) and not __yuri_value_call(use.card,"isKindOf","Slash") then
		local gotslash = false
		local gotanaleptic = false
		local sn = 0
		local cards = complete_hand(self,use.from)
		for _, card in sgs.qlist(cards) do -- 查找敵人已知手牌的酒和殺
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), use.from:objectName())
			if __yuri_value_call(card,"hasFlag","visible") or __yuri_value_call(card,"hasFlag",flag) then
				if __yuri_value_call(card,"isKindOf","Analeptic") then
					gotanaleptic = true
				end
				if __yuri_value_call(card,"isKindOf","Slash") then
					gotslash = true
					sn = sn + 1
				end
			end
		end
		local ssc = __yuri_value_call(use.from,"getHandcardNum")/3
		if self:isWeak() and __yuri_value_call(use.card,"isKindOf","Duel") and (self:getCardsNum("Slash") <= sn or self:getCardsNum("Slash") < ssc) then return true end
		if self:isWeak() and __yuri_value_call(use.card,"isKindOf","SavageAssault") and self:getCardsNum("Slash") == 0 then return true end
		if self:isWeak() and __yuri_value_call(use.card,"isKindOf","ArcheryAttack") and self:getCardsNum("Jink") == 0 then return true end
		if gotslash and gotanaleptic and use.from:canSlash(self.player) and (self:getCardsNum("Jink") < 1 or (use.from:getWeapon() and use.from:getWeapon():getClassName() == "Axe" and (__yuri_value_call(use.from,"getHandcardNum")+use.from:getEquips():length()) > 3)) then
			return false
		else
			if (__yuri_value_call(use.card,"isKindOf","Dismantlement") or __yuri_value_call(use.card,"isKindOf","Snatch")) and (self.player:getArmor() and self.player:getArmor():getClassName() ~= "GaleShell") or self.player:getDefensiveHorse() or self.player:getOffensiveHorse() or self.player:getWeapon() or (__yuri_value_call(self.player,"getHandcardNum") == 1 and self:isWeak()) then
				return true
			end
			if __yuri_value_call(use.card,"isKindOf","Duel") and (self:getCardsNum("Slash") <= sn or self:getCardsNum("Slash") < ssc) then return true end
			if __yuri_value_call(use.card,"isKindOf","SavageAssault") and self:getCardsNum("Slash") == 0 then return true end
			if __yuri_value_call(use.card,"isKindOf","ArcheryAttack") and self:getCardsNum("Jink") == 0 then return true end
		end
	end
	if __yuri_value_call(use.card,"isKindOf","Slash") or __yuri_value_call(use.card,"isKindOf","DelayedTrick") then
		return true
	end
	return false

end

sgs.ai_skill_invoke.yuriganglie = function(self, data)
    local damage = data:toDamage()
	if self:isEnemy(damage.from) then
		return true
	end
	return false
end
sgs.ai_skill_cardchosen["yuriganglie"] = function(self, who, flags)
	local goodchice = {}
	local normal = {}
	for _,card in sgs.qlist(who:getCards("e")) do
		if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"isKindOf","SilverLion") then
			table.insert(goodchice, card)
		end
		if __yuri_value_call(card,"isKindOf","Weapon") or __yuri_value_call(card,"isKindOf","DefensiveHorse") or __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
			table.insert(goodchice, card)
		end
		table.insert(normal, card)
	end
	if #goodchice > 0 then return goodchice[1] end
	if #normal > 0 then return normal[1] end
	return nil
end

sgs.ai_need_damaged.fightingexper = function(self, attacker, player)
	return player:getPile("fc"):length() < 5 and __yuri_value_call(player,"hasSkill","fightingexper") and not __yuri_value_call(self.player,"isWounded")
end
sgs.ai_need_damaged.yuriganglie = function(self, attacker, player)
	if not attacker then return end
	if self:isEnemy(attacker) and attacker:getCards("e"):length() < 1
		and not (self:hasSkills(sgs.need_kongcheng .. "|buqu", attacker) and __yuri_value_call(attacker,"getHandcardNum") > 1) and self:isGoodTarget(attacker, self:getEnemies(attacker), nil) then
		return not self:isWeak()
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.yuriganglie = function(self, player, promptlist)
	local damage = room_tag(self,"yuriganglie","Damage")
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(damage.to, damage.from, 40)
		else
			self:updateIntention(damage.to, damage.from, -40)
		end
	end
end

sgs.ai_fill_skill["fightingclimax"] = function(self,inclusive,request)
	if self.player:getPile("fc"):length() >= 5 then
		local card_str = ("#fightingclimax:%d:")
		return policy(self,card_str)
	end
end
sgs.ai_skill_use_func["#fightingclimax"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["fightingclimax"] = 2.5
sgs.ai_use_priority["fightingclimax"] = sgs.ai_use_value.ExNihilo + 1
sgs.dynamic_value.damage_card["fightingclimax"] = true



sgs.ai_fill_skill["witty"] = function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByUseValue(cards,true)
	for _,card in ipairs(cards) do
		if __yuri_value_call(card,"isKindOf","DelayedTrick") or __yuri_value_call(card,"isKindOf","AmazingGrace") or __yuri_value_call(card,"isKindOf","ArcheryAttack") or __yuri_value_call(card,"isKindOf","SavageAssault") or __yuri_value_call(card,"isKindOf","GodSalvation") then
			local card_str = ("#witty:"..card:getId()..":")
			return policy(self,card_str)
		end
	end
end

sgs.ai_skill_use_func["#witty"] = function(card, use, self)
    self:updatePlayers()
	use.card = card
	if use.to then
		for _, friend in ipairs(self.friends) do
			use.to:append(friend)
		end
		assert(use.to:length() > 0)
	end
end
sgs.ai_card_intention["witty"]= function(self, card, from, tos)
	local room = from:getRoom()
	for _,to in ipairs(tos) do
		self:updateIntention(from, to, -30)
	end
end
sgs.ai_use_value["witty"] = 6
sgs.ai_use_priority["witty"] = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_playerchosen_intention["witty"] = function(self, from, to)
	self:updateIntention(from, to, 40)
end

sgs.ai_skill_playerchosen.witty = function(self, targets)
	self:updatePlayers()
	local best_etarget = nil
	local enemytars = {}
	self.enemies = self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		table.insert(enemytars, enemy)
		if (self:isWeak(enemy) and enemy:isNude()) then best_etarget = enemy end
	end
	if best_etarget then return best_etarget end
	return enemytars[1]
end





sgs.ai_event_callback[sgs.AfterDrawNCards].yuriforever = function(self, player, data)
	local draw = event_draw(data)
	if draw.reason ~= "InitialHandCards" then return false end
	for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
		if __yuri_value_call(sb,"getMark","yuriforever") > 0 then
			role_event(self,sb,"yuriforever",viewer_role(self,sb))
			self:updatePlayers()
		end
	end
end

sgs.ai_skill_invoke.LuaJTieji = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end

sgs.ai_skill_cardask["@luajtieji-discard"] = function(self, data, pattern)
	local suit = pattern:split("|")[2]
	local use = data:toCardUse()
	if self:needToThrowArmor() and self.player:getArmor():getSuitString() == suit then return "$" .. self.player:getArmor():getEffectiveId() end
	if not self:slashIsEffective(use.card, self.player, use.from)
		or (not self:hasHeavyDamage(use.from, use.card, self.player)
			and (self:needToLoseHp(self.player, use.from, use.card)) and not __yuri_value_call(self.player,"getHp") <= 1) then return "." end
	if self:getCardsNum("Jink") == 0 or sgs.isJinkAvailable(use.from, self.player, use.card) then return "." end

	local jiangqin = self.room:findPlayerBySkillName("niaoxiang")
	local need_double_jink = __yuri_value_call(use.from,"hasSkill","wushuang")
							or (__yuri_value_call(use.from,"hasSkill","roulin") and self.player:isFemale())
							or (__yuri_value_call(self.player,"hasSkill","roulin") and use.from:isFemale())
							or (jiangqin and jiangqin:isAdjacentTo(self.player) and use.from:isAdjacentTo(self.player) and self:isEnemy(jiangqin))
	local jink = 0
	local need = need_double_jink and 2 or 1
	local hcards = self.player:getCards("h")
	for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
		hcards:prepend(visible(self,id))
	end
	hcards = sgs.QList2Table(hcards)
	for _, card in ipairs(hcards) do
		if __yuri_value_call(card,"isKindOf","Jink") then jink = jink + 1 end
	end

	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if __yuri_value_call(card,"getSuitString") ~= suit then continue end
		if __yuri_value_call(card,"isKindOf","Analeptic") or __yuri_value_call(card,"isKindOf","Peach") then continue end
		if not self:isWeak() and (self:getKeepValue(card) > 8 or self:isValuableCard(card)) then continue end
		if __yuri_value_call(card,"isKindOf","Jink") and jink - 1 < need then continue end
		if self.player:getArmor() and self:evaluateArmor() > 3 and __yuri_value_call(card,"getEffectiveId") == self.player:getArmor():getEffectiveId() then continue end
		if __yuri_value_call(card,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length() > 0 then continue end
		return "$" .. __yuri_value_call(card,"getEffectiveId")
	end
	return "."
end

sgs.ai_choicemade_filter.skillInvoke.LuaJTieji = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then self:updateIntention(player, target, 50) end
	end
end

sgs.ai_skill_use["@@thedolls"] = function(self, prompt)
    self:updatePlayers(true)
    local targets = {}
	self.friends = self:sort(self.friends, "chaofeng")
	self.enemies = self:sort(self.enemies, "defense")
    for _, f in ipairs(self.friends) do
		if (not f:isAllNude()) and __yuri_value_call(f,"getMark","@thedollsmark") > 0 then
			if self:isFriend(f) and (f:getCards("j"):length() > 0 or (f:getArmor() and (f:getArmor():getClassName() == "GaleShell" or (__yuri_value_call(f,"isWounded") and f:getArmor():getClassName() == "SilverLion"))))then
				table.insert(targets, f:objectName())
			end
		end
		if #targets >= 3 then break end
    end
	if #targets < 3 then
		for _, p in ipairs(self.enemies) do
			if (not p:isAllNude()) and __yuri_value_call(p,"getMark","@thedollsmark") > 0 then
				if p:getEquips():length() > 0 and not (p:getEquips():length() == 1 and p:getArmor() and (p:getArmor():getClassName() == "GaleShell")) then
					table.insert(targets, p:objectName())
				end
			end
			if #targets >= 3 then break end
		end
	end
	if #targets == 0 then return nil end
    return "#thedolls:.:->"..table.concat(targets, "+")
end

sgs.ai_skill_cardchosen["thedolls"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
			for _,card in sgs.qlist(who:getCards("he")) do
				if self:isWeak(self.player) and not __yuri_value_call(card,"isKindOf","EquipCard") then
					table.insert(goodchice, card)
				end
				if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"getClassName") == "SilverLion" then
					table.insert(goodchice, card)
				end
				if __yuri_value_call(card,"isKindOf","Weapon") or __yuri_value_call(card,"isKindOf","DefensiveHorse") or __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
					table.insert(goodchice, card)
				end
				table.insert(normal, card)
			end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end

sgs.ai_card_intention["thedolls"] = function(self,card,from,tos)
	for _,to in ipairs(tos) do
		if to:getCards("j"):length() > 0 or (to:getArmor() and (to:getArmor():getClassName() == "GaleShell" or (__yuri_value_call(to,"isWounded") and to:getArmor():getClassName() == "SilverLion"))) then
			self:updateIntention(from, to, 0)
		else
			self:updateIntention(from, to, 15)
		end
	end
end
sgs.ai_choicemade_filter.cardChosen.thedolls = sgs.ai_choicemade_filter.cardChosen.snatch
sgs.ai_cardneed.yuri_xueji = function(to, card)
	return __yuri_value_call(to,"getHandcardNum") < 3 and card:isRed()
end

local function can_be_selected_as_target_olxueji(self, who)
	if self:isEnemy(who) and not who:isChained() then
		return true
	elseif self:isFriend(who) then
		return who:isChained()
	end
	return false
end

sgs.ai_fill_skill.yuri_xueji=function(self,inclusive,request)
		if self.player:hasUsed("#yuri_xueji") then return end
		return policy(self,"#yuri_xueji:.:")
end
sgs.ai_skill_use_func["#yuri_xueji"] = function(card, use, self)
	local cards = self.player:getCards("he")
	local slashs = {}
	for _,c in sgs.qlist(cards) do
		if c:isBlack() and not (__yuri_value_call(card,"isKindOf","IronChain") and __yuri_value_call(self.player,"getLostHp") < 2) then
			if self.player:canDiscard(self.player, __yuri_value_call(c,"getEffectiveId")) then
				table.insert(slashs, c)
			end
		end
	end
	if #slashs == 0 then return end
	local to_use = false
	for _, enemy in ipairs(self.enemies) do
		if can_be_selected_as_target_olxueji(self, enemy) then
			to_use = true
			break
		end
	end
	if not to_use then
		for _, friend in ipairs(self.friends) do
			if can_be_selected_as_target_olxueji(self, friend) then
				to_use = true
				break
			end
		end
	end
	if not to_use then return end

	slashs = self:sortByUseValue(slashs, true)
	local n = math.max(__yuri_value_call(self.player,"getLostHp")+1, 2)

	self.enemies = self:sort(self.enemies, "hp")

	use.card = policy(self,"#yuri_xueji:"..slashs[1]:getId()..":")
	local tos = {}
	 for _, friend in ipairs(self.friends) do --把最後一段搬上來
		 if not table.contains(tos, friend) and can_be_selected_as_target_olxueji(self, friend) then
			if use.to and use.to:length() < n then use.to:append(friend) table.insert(tos, friend) end
		end
	end
	for _, enemy in ipairs(self.enemies) do
	    if can_be_selected_as_target_olxueji(self, enemy) and (enemy:hasArmorEffect("vine") or __yuri_value_call(enemy,"hasSkill","lianhuo")) then
			if use.to and use.to:length() < n then use.to:append(enemy) table.insert(tos, enemy) end
		end
	end
	for _, enemy in ipairs(self.enemies) do
	    if not table.contains(tos, enemy) and can_be_selected_as_target_olxueji(self, enemy) and not enemy:isChained() and not enemy:hasSkills("qianjie|marriedg") then
			if use.to and use.to:length() < n then use.to:append(enemy) table.insert(tos, enemy) end
		end
	end


	for _, enemy in ipairs(self.enemies) do
	    if not table.contains(tos, enemy) and can_be_selected_as_target_olxueji(self, enemy) then
			if use.to and use.to:length() < n then use.to:append(enemy) table.insert(tos, enemy) end
		end
	end
end

sgs.ai_card_intention.yuri_xueji = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		local intention = 10
		if self:needToLoseHp(to) then continue end
		if to:isChained() then intention = -10 end
		if __yuri_value_call(to,"hasSkill","hunzi") and __yuri_value_call(to,"getMark","hunzi") == 0 then
			if to:objectName() == from:getNextAlive():objectName() and __yuri_value_call(to,"getHp") == 2 then
				intention = -10
			end
		end
		self:updateIntention(from, to, intention)
	end
end

sgs.ai_use_value.yuri_xuejiCard = 4
sgs.ai_use_priority.yuri_xueji = sgs.ai_use_priority.IronChain + 0.2

sgs.ai_view_as.yuri_wuji = function(card, player, card_place)
	local suit = __yuri_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __yuri_value_call(card,"getEffectiveId")
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
	and card:isRed() and not __yuri_value_call(card,"isKindOf","Peach") and not __yuri_value_call(card,"hasFlag","using") and not (__yuri_value_call(card,"isKindOf","WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("fire_slash:yuri_wuji[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_fill_skill["yuri_wuji"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
		cards:prepend(visible(self,id))
	end
	cards = sgs.QList2Table(cards)
	local red_card
	cards = self:sortByUseValue(cards, true)

	local useAll = false
	local kill = false

	self.enemies = self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:hasArmorEffect("eight_diagram") and __yuri_value_call(self.player,"distanceTo",enemy) <= __yuri_value_call(self.player,"getAttackRange")
			and self:isGoodTarget(enemy, self.enemies, nil) then
				kill = true
				if __yuri_value_call(enemy,"getHp") <= 1 and self:isWeak(enemy)
				and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
					useAll = true
					break
				end
		end
	end
	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or __yuri_value_call(self.player,"hasSkill","paoxiao") then disCrossbow = true end

	if self:hasCrossbowEffect() and kill then
		for _, card in ipairs(cards) do
			if card:isRed() and (not isCard("Crossbow", card, self.player) or disCrossbow) and not (__yuri_value_call(card,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
				red_card = card
				break
			end
		end
	end

	if not red_card then
		if __yuri_value_call(self.player,"hasSkill","nuzhan") and kill then
			for _, card in ipairs(cards) do
				if card:isRed() and __yuri_value_call(card,"isKindOf","TrickCard") then
					red_card = card
					break
				end
			end

			if not red_card then
				local nuzhan = false
				for _, enemy in ipairs(self.enemies) do
					if not enemy:hasArmorEffect("eight_diagram") and not enemy:hasArmorEffect("silver_lion") and __yuri_value_call(self.player,"distanceTo",enemy) <= __yuri_value_call(self.player,"getAttackRange")
					and getCardsNum("Jink", enemy) < 1 and self:isGoodTarget(enemy, self.enemies, nil) then
						nuzhan = true
						break
					end
				end
				if nuzhan then
					for _, card in ipairs(cards) do
						if card:isRed() and __yuri_value_call(card,"isKindOf","EquipCard") and (not __yuri_value_call(card,"isKindOf","Crossbow") or disCrossbow) and not (__yuri_value_call(card,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
							red_card = card
							break
						end
					end
				end
			end
		end

		if not red_card then
			for _, card in ipairs(cards) do
				if card:isRed() and (not isCard("Peach", card, self.player) or useAll) and not (__yuri_value_call(card,"isKindOf","WoodenOx") and self.player:getPile("wooden_ox"):length() > 0)
					and (not isCard("Crossbow", card, self.player) or disCrossbow)
					and (self:getUseValue(card) < sgs.ai_use_value.FireSlash or inclusive or self:getOverflow() > 0
						or residue(self,clone(self,"fire_slash")) > 0) then
					red_card = card
					break
				end
			end
		end
	end
	if red_card then
		local suit = __yuri_value_call(red_card,"getSuitString")
		local number = red_card:getNumberString()
		local card_id = __yuri_value_call(red_card,"getEffectiveId")
		local card_str = ("fire_slash:yuri_wuji[%s:%s]=%d"):format(suit, number, card_id)
		local slash = policy(self,card_str)

		assert(slash)
		return slash
	end
end

sgs.ai_skill_playerchosen.ys_huairou = function(self, targets)
	self.friends_noself = self:sort(self.friends_noself, "defense")
	for _, target in ipairs(self.friends_noself) do
		if self:isFriend(target) and not (target:hasSkills("manjuan|zishu") or self:needKongcheng(target)) and target:hasSkills("enyuan|hongde") then
			return target
		end
	end
	for _, target in ipairs(self.friends_noself) do
		if self:isFriend(target) and not target:hasSkills("manjuan|zishu") then
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.ys_huairou = function(self, from, to)
	if to:hasSkills("manjuan|zishu") then self:updateIntention(from, to, 0) end
	self:updateIntention(from, to, -40)
end

sgs.ai_fill_skill["ys_jueyan"] = function(self,inclusive,request)
	if __yuri_value_call(self.player,"getMark","@ys_jueyan") == 0 then return end
	return policy(self,"#ys_jueyan:.:")
end

sgs.ai_skill_use_func["#ys_jueyan"] = function(card, use, self)
	if __yuri_value_call(self.player,"getMark","@ys_jueyan") <= 0 then return end

	local target
	if not self:isWeak() then
		for _, enemy in ipairs(self.enemies) do
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) then
				target = enemy
				break
			end
		end
	end
	if not target and self:isWeak() then
		for _, enemy in ipairs(self.enemies) do
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player)
			and not (self:needToLoseHp(enemy, self.player, nil, true)) then
				target = enemy
				break
			end
		end
	end
	if not target then return end
	use.card = policy(self,"#ys_jueyan:.:")
	if use.to then use.to:append(target) end
	return
end


sgs.ai_use_value["ys_jueyan"] = 5
sgs.ai_use_priority.ys_jueyan = sgs.ai_use_priority.ExNihilo - 0.1
sgs.ai_card_intention["ys_jueyan"] = 60







sgs.ai_skill_invoke.likebooks = true

sgs.ai_skill_discard["likebooks"] = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	cards = self:sortByKeepValue(cards)
	local jink = 0
	local ana = 0
	for _, card in ipairs(cards) do
		if __yuri_value_call(card,"isKindOf","Slash") or __yuri_value_call(card,"isKindOf","Disaster") or __yuri_value_call(card,"isKindOf","AmazingGrace") then
			table.insert(to_discard, card:getId())
		elseif __yuri_value_call(card,"isKindOf","Jink") then
			if jink > 0 then table.insert(to_discard, card:getId()) end
			jink = jink + 1
		elseif __yuri_value_call(card,"isKindOf","Analeptic") then
			if ana > 0 then table.insert(to_discard, card:getId()) end
			ana = ana + 1
		elseif __yuri_value_call(card,"isKindOf","TrickCard") and not __yuri_value_call(card,"isKindOf","ExNihilo") and not __yuri_value_call(card,"isKindOf","Nullification") then
			local dummyuse = { isDummy = true, to = AIList.new({}) }
			self:useTrickCard(card, dummyuse)
			if dummyuse.to:isEmpty() then
				table.insert(to_discard, card:getId())
			end
		else
			if not self:hasSkills(sgs.lose_equip_skill) then
				if __yuri_value_call(card,"isKindOf","OffensiveHorse") and self.player:getOffensiveHorse() then
					table.insert(to_discard, card:getId())
				elseif __yuri_value_call(card,"isKindOf","DefensiveHorse") and self.player:getDefensiveHorse() then
					table.insert(to_discard, card:getId())
				elseif __yuri_value_call(card,"isKindOf","Armor") and self:evaluateArmor(card) <= self:evaluateArmor() then
					table.insert(to_discard, card:getId())
				elseif __yuri_value_call(card,"isKindOf","Weapon") and self:evaluateWeapon(card) <= self:evaluateWeapon(self.player:getWeapon()) then
					table.insert(to_discard, card:getId())
				end
			end
		end
	end
	if #to_discard < 1 then return self:askForDiscard("dummyreason", 1, 1, false, false) end
	return to_discard[1]
end

sgs.ai_skill_choice.likebooks = function(self, choices, data)
	if self.player:hasArmorEffect("vine") and self.player:isChained() and not self:isGoodChainPartner() then
		return "reset"
	end
	if self:isWeak() and __yuri_value_call(self.player,"isWounded") then return "recover" end
	if self.player:hasSkills("manjuan|zishu") then
		if __yuri_value_call(self.player,"isWounded") then return "recover" end
		if self.player:isChained() then return "reset" end
	end
	return "recover"
end

sgs.ai_skill_invoke.happinesstoeveryone = function(self, data)
	local target = self.room:getCurrent()
	local count = __yuri_value_call(target,"getHandcardNum") - __yuri_value_call(target,"getMaxHp")
	if target and self:isFriend(target) and (target:isChained() or not __yuri_value_call(target,"faceUp")) then return true end
	if target and self:isFriend(target) and ((count < -1 and not self:needKongcheng(target, true)) or self:isWeak(target)) and target then
		return true
	end

	return false
end

sgs.ai_choicemade_filter.skillInvoke.happinesstoeveryone = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if not current then return end
	if promptlist[#promptlist] == "yes" then self:updateIntention(player, current, -20) end
end

sgs.ai_ajustdamage_to.bloody   = function(self, from, to, card, nature)
	if __yuri_value_call(to,"getMark","@struggle") > 1  then
		return -99
	end
end


sgs.ai_skill_invoke.blooddry = function(self,data)
	local use = data:toCardUse()
	for _ ,to in sgs.qlist(use.to) do
		if self:isEnemy(to) then return true end
	end
	return false
end


sgs.ai_canliegong_skill.blooddry = function(self, from, to)
	return __yuri_value_call(from,"distanceTo",to) <= 1
end

sgs.ai_fill_skill["suckblood"] = function(self,inclusive,request)
	local n = 0
	local getpeach = false
    for _,enemy in ipairs(self.enemies) do
		local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		if (not self:slashProhibit(slash, enemy, self.player)) and self.player:canSlash(enemy, slash) and self:slashIsEffective(slash, enemy) and __yuri_value_call(self.player,"getHp") < __yuri_value_call(enemy,"getHandcardNum") and (__yuri_value_call(self.player,"distanceTo",enemy) <= 1 or self:isWeak(enemy)) then
			n = n + 1
		end
	end
	for _,friend in ipairs(self.friends) do
		if getCardsNum("Peach", friend) > 0 then getpeach = true break end
	end
	if n > 0 and (getpeach or not self:isWeak(self.player)) then
		local card_str = ("slash:suckblood[no_suit:0]=.")
		local card = policy(self,card_str)
		return card
	end
end
function sgs.ai_cardsview.suckblood(self, class_name, player)
	if class_name == "Slash" then
		if __yuri_value_call(player,"getHp") > 0 then
			return ("slash:suckblood[no_suit:0]=.")
		end
	end
end
sgs.ai_skill_invoke.suckblood = function(self,data)
	local damage = data:toDamage()
	if not self:isFriend(damage.to) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["suckblood"] = function(self, player, promptlist)
	local damage = room_tag(self,"suckblood","Damage")
	if promptlist[#promptlist] == "yes" then
		self:updateIntention(self.player, damage.to, 30)
	end
end
sgs.ai_use_value["suckblood"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["suckblood"] = sgs.ai_use_priority.Slash - 0.1


sgs.ai_skill_invoke.yuri_jianchu = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) and self:doDisCard(target, "he") then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.yuri_jianchu = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then self:updateIntention(player, target, 50) end
	end
end

sgs.ai_skill_playerchosen["yuri_liangyin"] = function(self, targets)
	local targets = sgs.QList2Table(targets)
	targets = self:sort(targets)
	for _,p in ipairs(targets) do
		if (__yuri_value_call(p,"getHandcardNum") < __yuri_value_call(self.player,"getHandcardNum") or __yuri_value_call(p,"getHp") < __yuri_value_call(self.player,"getHp")) and self:isFriend(p) and __yuri_value_call(self.player,"getMark","yl_draw") > 0 then --room:setPlayerMark(player, "yl_draw", 1)
			return p
		elseif (__yuri_value_call(p,"getHandcardNum") > __yuri_value_call(self.player,"getHandcardNum") or __yuri_value_call(p,"getHp") > __yuri_value_call(self.player,"getHp")) and (not p:isNude()) and __yuri_value_call(self.player,"getMark","yl_draw") == 0 then
			if self:isEnemy(p) and not self:needToThrowCard(p) then return p end
			if self:isFriend(p) and self:needToThrowCard(p) then return p end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.yuri_liangyin = function(self, from, to)
	if (__yuri_value_call(to,"getHandcardNum") < __yuri_value_call(from,"getHandcardNum") or __yuri_value_call(to,"getHp") < __yuri_value_call(from,"getHp")) and __yuri_value_call(self.player,"getMark","yl_draw") > 0 then self:updateIntention(from, to, -10) end
	if ((__yuri_value_call(to,"getHandcardNum") > __yuri_value_call(from,"getHandcardNum")) or (__yuri_value_call(to,"getHp") > __yuri_value_call(from,"getHp"))) and (__yuri_value_call(self.player,"getMark","yl_draw") == 0) and not self:needToThrowCard(to) then self:updateIntention(from, to, 10) end
end

sgs.ai_skill_use["@yuri_kongsheng"] = function(self, prompt, method)	--yun
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	cards = self:sortByKeepValue(cards)
	if (self:needKongcheng() and not self.player:isKongcheng()) or self.player:containsTrick("indulgence") then
		for _, card in ipairs(cards) do
			table.insert(to_discard, card:getId())
		end
	end
	local useSlash = false
	local slash, ana, peach = 0, 0, 0
	for _, card in ipairs(cards) do
		if __yuri_value_call(card,"isKindOf","Jink") then
			table.insert(to_discard, card:getId())
		elseif __yuri_value_call(card,"isKindOf","Slash") then
			local dummy_use = self:aiUseCard(card, dummy_plan())
			if dummy_use.card then
				useSlash = true
				slash = slash + 1
			else
				table.insert(to_discard, card:getId())
			end
			if slash > 1 and not self:hasCrossbowEffect() and not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
		elseif __yuri_value_call(card,"isKindOf","Analeptic") then
			if not useSlash or ana > 0 then table.insert(to_discard, card:getId()) end
			ana = ana + 1
		elseif __yuri_value_call(card,"isKindOf","TrickCard") and not __yuri_value_call(card,"isKindOf","ExNihilo") and not __yuri_value_call(card,"isKindOf","Nullification") then
			local dummy_use = self:aiUseCard(card, dummy_plan())
			if dummy_use.to:isEmpty() then
				table.insert(to_discard, card:getId())
			end
		elseif __yuri_value_call(card,"isKindOf","OffensiveHorse") and self.player:getOffensiveHorse() then
			table.insert(to_discard, card:getId())
		elseif __yuri_value_call(card,"isKindOf","Peach") then
			local dummy_use = self:aiUseCard(card, dummy_plan())
			if dummy_use.card then
				peach = peach + 1
			else
				table.insert(to_discard, card:getId())
			end
			if peach > 1 and not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
		end
	end
	if self:needToThrowArmor() then table.insert(to_discard, self.player:getArmor():getId()) end
	if self.player:getDefensiveHorse() then table.insert(to_discard, self.player:getDefensiveHorse():getId()) end
	if #to_discard == 0 then return "." end
	if #to_discard > 1 then
		local to_use = {to_discard[1], to_discard[2]}
		return string.format("#yuri_kongsheng:%s:", table.concat(to_use, "+"))
	else
		return string.format("#yuri_kongsheng:%s:", to_discard[1])
	end
end
sgs.ai_skill_playerchosen.yuri_kongsheng = function(self, targets)
	self:updatePlayers()
	local guys={}
	for _,target  in sgs.qlist(targets) do
		if self:isFriend(target) then
		 table.insert(guys, target)
		end
	end
	if #guys == 0 then return nil end
	guys = self:sort(guys, "chaofeng")
	local tars={}
	local badtars={}
	for _, t in ipairs(guys) do
		if t:hasSkills("keji|conghui") then
			table.insert(badtars, t)
		else
			table.insert(tars, t)
		end
		if not t:hasSkills("keji|conghui") and (__yuri_value_call(t,"getHp") == 1 or self:getOverflow(t) > 2) then best_etarget = t end
	end
	if best_etarget then return best_etarget end
	if tars[1] then return tars[1] end
	if badtars[1] then return badtars[1] end
	return nil
end

sgs.ai_skill_invoke.protectdestroy = function(self,data)
	local target = data:toPlayer()
	if self:isFriend(target) then return false end
	return true
end
sgs.ai_choicemade_filter.skillInvoke.protectdestroy = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then self:updateIntention(player, target, 50) end
	end
end

sgs.ai_fill_skill["married"] = function(self,inclusive,request)
	if self.player:isNude() or self.player:hasUsed("#married") then return nil end
	return policy(self,"#married:.:")
end
sgs.ai_skill_use_func["#married"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local equipments = sgs.QList2Table(self.player:getCards("e"))
	local use_card = nil
	handcards = self:sortByCardNeed(handcards, true)
	equipments = self:sortByCardNeed(equipments, true)
	self.friends_noself = self:sort(self.friends_noself, "hp")
	local target = nil

	for _,c in ipairs(handcards) do
		if not __yuri_value_call(c,"isKindOf","Peach") then
			use_card = c
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if __yuri_value_call(friend,"getHp") ~= __yuri_value_call(self.player,"getHp") or (__yuri_value_call(friend,"getHp") == __yuri_value_call(self.player,"getHp") and __yuri_value_call(self.player,"isWounded")) then
			target = friend
			break	--yun
		end
	end

	if self.player:getEquips():length() > 0 then
		for _,e in ipairs(equipments) do
			if not __yuri_value_call(e,"isKindOf","WoodenOx") then
				local equip_index = known(e:getEquipSlot(),"equipment slot")
				for _, friend in ipairs(self.friends_noself) do
					if (__yuri_value_call(friend,"getHp") ~= __yuri_value_call(self.player,"getHp") or (__yuri_value_call(friend,"getHp") == __yuri_value_call(self.player,"getHp") and __yuri_value_call(self.player,"isWounded"))) and friend:getEquip(equip_index) == nil then
						use_card = e
						target = friend
						break	--yun
					end
				end
			end
		end
	end
	if target == nil or use_card == nil then return end
	use.card = policy(self,"#married:"..use_card:getId()..":")
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority["married"] = 2.8

sgs.ai_card_intention["married"] = function(self, card, from, tos)
		self:updateIntention(from, tos[1], -80)
end



sgs.ai_fill_skill["meleemaster"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local trickcard

	cards = self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if __yuri_value_call(card,"isKindOf","TrickCard") then
			trickcard = card
			break
		end
	end

	if not trickcard then return nil end
	local suit = __yuri_value_call(trickcard,"getSuitString")
	local number = trickcard:getNumberString()
	local card_id = __yuri_value_call(trickcard,"getEffectiveId")
	local card_str = ("slash:meleemaster[%s:%s]=%d"):format(suit, number, card_id)
	local slash = policy(self,card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.meleemaster = function(card, player, card_place)
 local self=known(known(player:getRoom(),"view-as room")._ai,"view-as AI context")
	local suit = __yuri_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __yuri_value_call(card,"getEffectiveId")
	local pattern = known(self:getCurrentCardUsePattern(),"current card use pattern")
	if card_place == sgs.Player_PlaceHand then
		if __yuri_value_call(card,"isKindOf","TrickCard") and pattern == "jink" then
			return ("jink:meleemaster[%s:%s]=%d"):format(suit, number, card_id)
		elseif __yuri_value_call(card,"isKindOf","TrickCard") and pattern == "slash" then
			return ("slash:meleemaster[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.meleemaster_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 3.8,
	FireSlash = 4.5,
	Slash = 3.8,
	ThunderSlash = 4.5,
	ExNihilo = 4.7,
	Nullification	= 5,
	Snatch 			= 5,
	Dismantlement 	= 5,
	Duel			= 5,
	ArcheryAttack 	= 4,
	FireAttack 		= 4,
	SavageAssault 	= 3.9,
	IronChain 		= 4,
	GodSalvation 	= 4,

	Indulgence 		= 5,
	SupplyShortage 	= 5,
	Lightning 		= 3.9
}

sgs.ai_can_damagehp.tacitunderstanding = function(self,from,card,to)
	return __yuri_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end


sgs.ai_fill_skill["weareidle"] = function(self,inclusive,request)
	if not self.player:hasUsed("#weareidle") then
		return policy(self,"#weareidle:.:")
	end
	return false
end
sgs.ai_skill_use_func["#weareidle"] = function(card, use, self)
	local first_found, second_found = false, false
	local first_card, second_card
	if __yuri_value_call(self.player,"getHandcardNum") >= 2 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)
		cards = self:sortByKeepValue(cards)

		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("Dismantlement", fcard, self.player))
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("Dismantlement", scard, self.player))
					if first_card ~= scard and __yuri_value_call(scard,"getSuit") == __yuri_value_call(first_card,"getSuit") and not svalueCard then
						second_card = scard
						second_found = true
						break
					end
				end
				if second_card then break end
			end
		end
	end

	local targetA
	local targetB

	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:objectName() ~= p:objectName() and self:isFriend(p) and (p:getCards("j"):length() > 0 or (p:getArmor() and (p:getArmor():getClassName() == "GaleShell" or (__yuri_value_call(p,"isWounded") and p:getArmor():getClassName() == "SilverLion"))))then
			if not targetA then
				targetA = p
			elseif not targetB then
				targetB = p
			else
				break
			end
		elseif not p:isNude() and not self:isFriend(p) then
			if not targetA then
				targetA = p
			elseif not targetB then
				targetB = p
			else
				break
			end
		end
	end

	if first_found and second_found and (targetA or targetB) then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local to_use = {first_id, second_id}
		local card_str = string.format("#weareidle:%s:", table.concat(to_use, "+"))
		local acard = policy(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(targetA)
			if targetB then use.to:append(targetB) end

		end
	end
end
sgs.ai_skill_cardchosen["weareidle"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"getClassName") == "SilverLion" then
				table.insert(goodchice, card)
			end
			if __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_choicemade_filter.cardChosen.weareidle = sgs.ai_choicemade_filter.cardChosen.dismantlement
sgs.ai_use_value["weareidle"] = sgs.ai_use_value.Dismantlement
sgs.ai_use_priority["weareidle"] = sgs.ai_use_priority.Snatch
sgs.ai_card_intention["weareidle"] = sgs.ai_card_intention.Snatch

sgs.ai_skill_invoke.solidarity = function(self, data)
	return true
end

sgs.ai_skill_discard.listentonature = function(self, discard_num, min_num, optional, include_equip)
	local card_id = __yuri_value_call(self.player,"getMark","ltn_mark")
    local card = visible(self,card_id)
	local cards = {}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:isRed() and not (__yuri_value_call(c,"isKindOf","Peach") or (__yuri_value_call(self.player,"getHp") == 1 and __yuri_value_call(c,"isKindOf","Analeptic"))) then
			table.insert(cards, c)
		end
	end
	if #cards > 0 then
		cards = self:sortByKeepValue(cards)
	else
		return {}
	end

	local cd = cards[1]
	local id = __yuri_value_call(cd,"getEffectiveId")

	for _, skill in sgs.qlist(self.player:getVisibleSkillList()) do
		local callback = sgs.ai_cardneed[skill:objectName()]
		if type(callback) == "function" and callback(self.player, cd, self) then
			return {}
		end
		if type(callback) == "function" and callback(self.player, card, self) then
			return id
		end
	end

	if self:isValuableCard(cd, self.player) then return {} end
	if self:isValuableCard(card, self.player) then return id end

	return {}
end

sgs.ai_skill_invoke.migonoinori = function(self, data)
	return true
end

sgs.ai_skill_invoke.imwatching = function(self, data)
	local current = data:toPlayer()
	if __yuri_value_call(current,"getHp") > 1 and self:isEnemy(current) then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		local hasblackcard = false
		for _,card in ipairs(cards) do
			if card:isBlack() then
				hasblackcard = true
				break
			end
		end
		return hasblackcard
	elseif __yuri_value_call(current,"getHp") <= 1 then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@imwatching"] = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByUseValue(cards,true)
	local choice
	for _,card in ipairs(cards)  do
		if not choice and card:isBlack() and not (self:isWeak(self.player) and __yuri_value_call(self.player,"isLord") and __yuri_value_call(card,"isKindOf","Analeptic")) then
			choice = card
		end
		if __yuri_value_call(self.player,"isWounded") and self.player:getArmor():getClassName() == "SilverLion" and __yuri_value_call(card,"isKindOf","SilverLion") then
			choice = card
			break
		end
	end
	return __yuri_value_call(choice,"getEffectiveId")
end

sgs.ai_choicemade_filter.skillInvoke.imwatching = function(self, player, promptlist)
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if __yuri_value_call(p,"getHp") > 1 and __yuri_value_call(p,"hasFlag","Imw_target") then
			self:setStrategyPlayerFlag(p,'Imw_target',false)
			if promptlist[#promptlist] == "yes" then
				self:updateIntention(self.player, p, 20)
			else
				self:updateIntention(self.player, p, 0)
			end
		end
	end
end






sgs.ai_skill_cardask["@bougairensha"] = function(self, data)
	local use = data:toCardUse()
	local from = use.from
	if self:isFriend(from) then return "." end
	local needprotect = false
	for _, p in sgs.qlist(use.to) do
		if (self:isFriend(p) or p:objectName() == self.player:objectName()) and self:isEnemy(from) then
			needprotect = true
		end
		if self:isEnemy(from) and self:isEnemy(p) then
			needprotect = true
		end
	end
	if not needprotect then return "." end

	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByUseValue(cards,true)
	local choice
	for _,card in ipairs(cards)  do
		if not choice and card:isBlack() and not (self:isWeak(self.player) and __yuri_value_call(self.player,"isLord") and __yuri_value_call(card,"isKindOf","Analeptic")) then
			choice = card
		end
		if __yuri_value_call(self.player,"isWounded") and self.player:getArmor() and self.player:getArmor():getClassName() == "SilverLion" and __yuri_value_call(card,"isKindOf","SilverLion") then
			choice = card
			break
		end
	end
	if choice then
		return __yuri_value_call(choice,"getEffectiveId")
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@bougairensha"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local use = room_tag(self,"bougairensha","CardUse")
		if not use.from then return end
		self:updateIntention(player, use.from, 80)
	end
end


sgs.ai_cardneed.bougairensha = function(to, card, self)
	return card:isBlack()
end

sgs.ai_skill_invoke.sizukana = function(self, data)
	local firends = AIList.new({})
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p) then
			firends:append(p)
		end
	end
	if firends:length() > 0 then return true end
	return false
end

sgs.ai_skill_playerchosen["sizukana"] = function(self, targets)
	local targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "defense")
	local good_tar = {}
	local normal_tar
	if __yuri_value_call(self.player,"getMark","@sizukana_mark") < 1 then return self.player end
	for _,p in ipairs(targets) do
		if self:isFriend(p) then
			if (self:isWeak(p) or __yuri_value_call(p,"getHp") == 1) and __yuri_value_call(p,"isLord") and __yuri_value_call(p,"getMark","@sizukana_mark") < 1 then return p end
			if self:isWeak(p) and __yuri_value_call(p,"getMark","@sizukana_mark") < 1 then table.insert(good_tar, p) end
			if __yuri_value_call(p,"getMark","@sizukana_mark") < 1 then normal_tar = p end
		end
	end
	if #good_tar > 0 then
		return good_tar[1]
	elseif normal_tar then
		return normal_tar
	end
	return self.player
end
sgs.ai_playerchosen_intention.sizukana = function(self, from, to)
	self:updateIntention(from, to, -20)
end

sgs.ai_fill_skill["hononozouki"] = function(self,inclusive,request)
	return policy(self,"#hononozouki:.:")
end

sgs.ai_skill_use_func["#hononozouki"] = function(card, use, self)
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if __yuri_value_call(p,"getMark","hononozouki_used") == 0 then
			if self.player:objectName() ~= p:objectName() and self:isFriend(p) then
				use.card = policy(self,"#hononozouki:.:")
				if use.to then use.to:append(p) end
				return
			end
		end
	end
end

sgs.ai_card_intention["hononozouki"] = -20

sgs.ai_skill_invoke.hononochikara = function(self,data)
	local use = data:toCardUse() -- 經測試use.from抓對角色
	local aoeatk = false
	local letgo = 0
	if __yuri_value_call(use.card,"isKindOf","ExNihilo") then return false end
	if __yuri_value_call(use.card,"isKindOf","AOE") or __yuri_value_call(use.card,"isKindOf","GlobalEffect") then aoeatk = true end
	for _, p in sgs.qlist(use.to) do
		if not aoeatk and self:isFriend(p) then return false end
		if self:isEnemy(p) and not (__yuri_value_call(p,"hasSkill","shixin") or __yuri_value_call(p,"hasSkill","moekogoro") or self:hasEightDiagramEffect(p)) then
			letgo = letgo + 1
			if self:isWeak(p) and getCardsNum("Jink", p, self.player) == 0 then
				letgo = letgo + 1
			end
		end
		if self:isFriend(p) and not (__yuri_value_call(p,"hasSkill","shixin") or __yuri_value_call(p,"hasSkill","moekogoro") or self:hasEightDiagramEffect(p)) and getCardsNum("Jink", p, self.player) == 0 then
			letgo = letgo - 1
			if p:hasArmorEffect("Vine") then letgo = letgo - 2 end
			if self:isWeak(p) and getCardsNum("Peach", p, self.player) + getCardsNum("Analeptic", p, self.player) == 0 then
				letgo = letgo - 1
			end
		end
	end
	if letgo > 0 then
		return true
	else
		return false
	end

end


sgs.ai_can_damagehp.moekogoro = function(self,from,card,to)
	if card and sgs.card_damage_nature[__yuri_value_call(card,"getClassName")] == sgs.DamageStruct_Fire then
		return true
	end
end
sgs.ai_ajustdamage_to.moekogoro = function(self,from,to,card,nature)
	if nature=="F"
	then return -99 end
end

sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|wisdom_s"
sgs.ai_skill_cardask["@wisdom-card"]=function(self, data)
	local judge = data:toJudge()
	if self.room:getMode():find("_mini_46") and not judge:isGood() then return "$" .. self.player:handCards():first() end
	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end
	return "."
end

function sgs.ai_cardneed.wisdom_s(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return __yuri_value_call(card,"getSuit") == sgs.Card_Spade and __yuri_value_call(card,"getNumber") >= 2 and __yuri_value_call(card,"getNumber") <= 9 and not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return __yuri_value_call(card,"getSuit") == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return __yuri_value_call(card,"getSuit") == sgs.Card_Heart
			end
		end
	end
end

sgs.wisdom_s_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}

sgs.ai_target_revises.yochi = function(to,card)
	if __yuri_value_call(card,"isKindOf","Slash") and to:canDiscard(to, "he")
	then return true end
end

sgs.ai_fill_skill["yomi"] = function(self,inclusive,request)
	self:updatePlayers()
	local active = false
	for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() and not __yuri_value_call(p,"hasFlag","yomi_AI") then
			active = true
			break
        end
    end
	if active then
		return policy(self,"#yomi:.:")
	end
end
sgs.ai_skill_use_func["#yomi"] = function(card, use, self)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "handcard")
    for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() and not __yuri_value_call(p,"hasFlag","yomi_AI") then
            use.card = policy(self,"#yomi:.:")
            if use.to then use.to:append(p) end
            return
        end
    end
end

sgs.ai_use_priority["yomi"] = sgs.ai_use_priority.Dismantlement + 1.2

sgs.ai_fill_skill["kanchi"] = function(self,inclusive,request)
	if self.player:hasUsed("#kanchi") then return false end
	return policy(self,"#kanchi:.:")
end
sgs.ai_skill_use_func["#kanchi"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "defense")
    for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() then
			local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
			slash:deleteLater()
			if self:isWeak(p) and self.player:canSlash(p, slash) and self:getCardsNum("Slash") > 0 then
				use.card = policy(self,"#kanchi:.:")
				if use.to then
					use.to:append(p)
				end
			end
			if getCardsNum("Nullification", p, self.player) > 0 or __yuri_value_call(p,"hasSkill","kanpo") then
				use.card = policy(self,"#kanchi:.:")
				if use.to then
					use.to:append(p)
				end
			end
			if getCardsNum("Peach", p, self.player) + getCardsNum("Analeptic", p, self.player) > 0 then
				use.card = policy(self,"#kanchi:.:")
				if use.to then
					use.to:append(p)
				end
			end
        end
    end
	 for _, p in ipairs(self.enemies) do
        if not p:isKongcheng() then
			use.card = policy(self,"#kanchi:.:")
			if use.to then
				use.to:append(p)
			end
		end
	end
	return
end

sgs.ai_use_value["kanchi"] = 3.5
sgs.ai_use_priority["kanchi"] = sgs.ai_use_priority.Dismantlement + 1

sgs.ai_card_intention["kanchi"] = 30

sgs.ai_skill_invoke.yuri_guixin = function(self, data)
	return true
end
sgs.ai_skill_choice["yuri_guixin"] = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) and not self:needKongcheng(target, true) then
		return "yg_dis"
	else
		return "yg_obtain"
	end
end
sgs.ai_need_damaged.yuri_guixin = sgs.ai_need_damaged.guixin

sgs.ai_skill_cardchosen["yuri_guixin"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"getClassName") == "SilverLion" then
				table.insert(goodchice, card)
			end
			if __yuri_value_call(card,"isKindOf","Weapon") or __yuri_value_call(card,"isKindOf","DefensiveHorse") or __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end

sgs.ai_choicemade_filter.skillChoice.yuri_guixin = function(self, player, promptlist)
	local to
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if __yuri_value_call(p,"hasFlag","yuri_guixinUsing") then
			to = p
			self:setStrategyPlayerFlag(p,'yuri_guixinUsing',false)
			break
		end
	end
	local choice = promptlist[#promptlist]
	if choice == "yg_obtain" and not self:needKongcheng(to, true) then
		self:updateIntention(player, to, 80)
	elseif choice == "yg_dis" then
		self:updateIntention(player, to, -60)
	end
end

sgs.ai_fill_skill["barakurosaku"] = function(self,inclusive,request)
	if self.player:isNude() or self.player:usedTimes("#barakurosaku") >= 3 + __yuri_value_call(self.player,"getMark","okanemochi_maxh") then return end
	if __yuri_value_call(self.player,"getMark","@ChangeSkill3") > 0 and __yuri_value_call(self.player,"getHp") < 2 and self:damageIsEffective(self.player, nil, self.player) and (self:getCardsNum("Peach") < 1 or self:getCardsNum("Analeptic") < 1) then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	if __yuri_value_call(cards[1],"isKindOf","Peach") then return end
	return policy(self,"#barakurosaku:" .. cards[1]:getId().. ":")
end
sgs.ai_skill_use_func["#barakurosaku"] = function(card, use, self)
	local target
	if __yuri_value_call(self.player,"getMark","@ChangeSkill3") > 0 then
		use.card = card
		if use.to then use.to:append(self.player) end
		return
	end
	if __yuri_value_call(self.player,"getMark","@ChangeSkill1") > 0 then
		for _, friend in ipairs(self.friends_noself) do
			if __yuri_value_call(friend,"getHp") > 2 and ((__yuri_value_call(friend,"hasSkill","weareidle") or self:needToLoseHp(friend, self.player)) or not self:damageIsEffective(friend, nil, self.player)) then
				target = friend
				break
			end
		end
		if not target then
			self.enemies = self:sort(self.enemies, "hp")
			for _, enemy in ipairs(self.enemies) do
				if self:isWeak(enemy) and __yuri_value_call(enemy,"getHp") < 2 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) and not (self:needToLoseHp(enemy, self.player, nil, true)) then
					target = enemy
					break
				end
			end
		end
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player)
				and not (self:needToLoseHp(enemy, self.player, nil, true)) then
					target = enemy
					break
				end
			end
		end


		if not target then
			for _, enemy in ipairs(self.enemies) do
				if __yuri_value_call(enemy,"getHp") < 3 and not self:cantbeHurt(enemy) then
					target = enemy
					break
				end
			end
		end

		if not target then return end
		use.card = card
		if use.to then use.to:append(target) end
		return
	elseif __yuri_value_call(self.player,"getMark","@ChangeSkill2") > 0 then
		for _, friend in ipairs(self.friends) do
			if __yuri_value_call(friend,"isWounded") and ((__yuri_value_call(friend,"getHandcardNum")+friend:getEquips():length()) < 2 or friend:hasSkills("kongcheng|lianying|noslianying|tuntian") or (__yuri_value_call(friend,"hasSkill","xiaoji") and friend:getCards("e"):length() > 0)) then
				target = friend
				break
			end
		end
		if not target then
			for _, friend in ipairs(self.friends) do
				if __yuri_value_call(friend,"isWounded") or __yuri_value_call(friend,"hasSkill","tuntian") or (__yuri_value_call(friend,"hasSkill","kongcheng") and __yuri_value_call(friend,"getHandcardNum") > 0) or (__yuri_value_call(friend,"hasSkill","xiaoji") and friend:getCards("e"):length() > 0)
				and not (friend:objectName() == self.player:objectName() and (__yuri_value_call(self.player,"getHandcardNum")+self.player:getEquips():length()) <= 3 and self:getCardsNum("Peach") > 1) then
					target = friend
					break
				end
			end
		end

		if not target then
			for _, enemy in ipairs(self.enemies) do
				if not __yuri_value_call(enemy,"isWounded") and not (enemy:hasSkills("kongcheng|lianying|noslianying|tuntian") or (__yuri_value_call(enemy,"hasSkill","xiaoji") and enemy:getCards("e"):length() > 0)) then
					target = enemy
					break
				end
			end
		end

		if not target then return end
		use.card = card
		if use.to then use.to:append(target) end
		return

	end
end

sgs.ai_use_priority.barakurosaku = sgs.ai_use_priority.Slash + 1

sgs.ai_card_intention.barakurosaku = function(self,card,from,tos)
	for _,to in ipairs(tos) do
		if __yuri_value_call(from,"getMark","@ChangeSkill1") > 0 and __yuri_value_call(to,"getHp") > 2 and (self:needToLoseHp(to, from, nil, true) or __yuri_value_call(to,"hasSkill","weareidle")) then
			self:updateIntention(from, to, -30)
		elseif __yuri_value_call(from,"getMark","@ChangeSkill2") > 0 then
			if __yuri_value_call(to,"isWounded") then
				self:updateIntention(from, to, -40)
			elseif not (to:hasSkills("kongcheng|lianying|noslianying|tuntian") or (__yuri_value_call(to,"hasSkill","xiaoji") and to:getCards("e"):length() > 0)) then
				self:updateIntention(from, to, 20)
			end
		end
	end
end


sgs.ai_skill_invoke.kanshi = function(self, data)
	local useto = data:toPlayer()
	if self:isFriend(useto) then
		if self:needKongcheng(useto, false) then return false end
		return true
	else
		if self:isEnemy(useto) and self:needKongcheng(useto, false) and __yuri_value_call(useto,"getHandcardNum") == 0 then return true end
		return false
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.kanshi = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target and not self:needKongcheng(target, false) then self:updateIntention(player, target, -40) end
	end
end

sgs.ai_skill_invoke.kanshi_dis = function(self, data)
	local useto = data:toPlayer()
	if self:isFriend(useto) then
		if self:needKongcheng(useto, false) and __yuri_value_call(useto,"getHandcardNum") == 1 then return true end
		if useto:getCards("j"):length() > 0 or (useto:getArmor() and (useto:getArmor():getClassName() == "GaleShell" or (__yuri_value_call(useto,"isWounded") and useto:getArmor():getClassName() == "SilverLion"))) then return true end
		return false
	else
		if self:isEnemy(useto) and self:needKongcheng(useto, false) and (__yuri_value_call(useto,"getHandcardNum")+useto:getEquips():length()) == 1 and __yuri_value_call(useto,"getHandcardNum") == 1 then return false end
		return true
	end
	return false
end

sgs.ai_skill_cardchosen["kanshi"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			if Q_goodToThrow(who, card, true) then return card end
		end
		for _,card in sgs.qlist(complete_hand(self,who)) do
			if self:needKongcheng(who, false) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"getClassName") == "SilverLion" then
				table.insert(goodchice, card)
			end
			if __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_choicemade_filter.cardChosen.kanshi = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_playerchosen.genjutsu = function(self, targets)
	local card = visible(self,self.player:getPile("gensou"):first())
	local slash = clone(self,"slash", __yuri_value_call(card,"getSuit"), __yuri_value_call(card,"getNumber"))
	slash = mutate(self,slash,"add",card)
	slash = mutate(self,slash,"skill","genjutsuslash")
	slash:deleteLater()
	targets = sgs.QList2Table(targets)
	local dummy_use = self:aiUseCard(slash, dummy_plan())
	if dummy_use.card and dummy_use and dummy_use.to then
		for _,p in sgs.list(dummy_use.to)do
			if table.contains(targets, p) then
				return p
			end
		end
	end
	return nil
end
sgs.ai_use_revises.genjutsu = function(self,card,use)
	if __yuri_value_call(card,"isKindOf","Slash") and table.contains(card:getSkillNames(), "genjutsuslash") then
		self:setStrategyCardFlag(card,'Qinggang',true)
	end
end

sgs.ai_playerchosen_intention["tsuyoiishiki"] = function(self, from, to)
	self:updateIntention(from, to, -30)
end


sgs.ai_skill_playerchosen.tsuyoiishiki = function(self, targets)
	self:updatePlayers()
	local best_target = nil
	local friendtars = {}
	self.friends = self:sort(self.friends, "defense")
	for _, f in ipairs(self.friends) do
		table.insert(friendtars, f)
		if (self:isWeak(f) and f:isNude()) and not f:hasSkills(sgs.need_kongcheng) then best_target = f end
	end
	if best_target then return best_target end
	return friendtars[1]
end

sgs.ai_view_as.countertrick = function(card, player, card_place)
	local suit = __yuri_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __yuri_value_call(card,"getEffectiveId")
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
	and not (__yuri_value_call(card,"isKindOf","BasicCard") or __yuri_value_call(card,"isKindOf","Nullification")) and not __yuri_value_call(card,"hasFlag","using") and not (__yuri_value_call(card,"isKindOf","WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("nullification:countertrick[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_card_priority.countertrick = function(self,card)
	if table.contains(card:getSkillNames(), "countertrick")
	then
		return 1
	end
end

sgs.ai_fill_skill["unlock"] = function(self,inclusive,request)
	self:updatePlayers()
	local var = 0
	if __yuri_value_call(self.player,"getMark","@kiyoi_coin") < 3 then
		for _, enemy in ipairs(self.enemies) do
			if __yuri_value_call(enemy,"getHandcardNum") > 2 then
				var = var + 1
			end
			if __yuri_value_call(enemy,"getHandcardNum") > 4 then
				var = var + 1
			end
		end
		if var < 2 then return false end
	end
	if (not self.player:hasUsed("#unlock")) then
		return policy(self,"#unlock:.:")
	end
end

sgs.ai_skill_use_func["#unlock"]=function(card, use, self)
	use.card = card
end

sgs.ai_use_value["unlock"] = 3.5
sgs.ai_use_priority["unlock"] = sgs.ai_use_priority.Slash + 1

sgs.ai_fill_skill["peeking"] = function(self,inclusive,request)
	self:updatePlayers()
	local tars = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not p:isKongcheng() then
			if not (self:isFriend(p) and __yuri_value_call(p,"getHandcardNum") > 3) then
				tars = tars + 1
			end
		end
	end
	if tars == 0 then return false end
	if (not self.player:hasUsed("#peeking")) then
		return policy(self,"#peeking:.:")
	end
end

sgs.ai_skill_use_func["#peeking"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "handcard")
	local targets = {}
	local good_targets = {}
	local best_target = nil
	local basic_count = 0
	local trick_count = 0
	local equip_count = 0

	for _, enemy in ipairs(self.enemies) do
		local cards = known(enemy:getKnownCards(),"known enemy hand")
		if __yuri_value_call(enemy,"getHandcardNum") > 6 then best_target = enemy break end
		if not enemy:isKongcheng() then
			for _, card in sgs.qlist(cards) do -- 查找敵人已知手牌
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
				if __yuri_value_call(card,"hasFlag","visible") or __yuri_value_call(card,"hasFlag",flag) then
					if __yuri_value_call(card,"isKindOf","BasicCard") then
						basic_count = basic_count+1
					end
					if __yuri_value_call(card,"isKindOf","TrickCard") then
						trick_count = trick_count+1
					end
					if __yuri_value_call(card,"isKindOf","EquipCard") then
						equip_count = equip_count+1
					end
				end
			end
			set_public_count(self,enemy,"basic_count_pm",0) --就算只有一個敵人也會運行兩次，只好這麼寫
			set_public_count(self,enemy,"trick_count_pm",0)
			set_public_count(self,enemy,"equip_count_pm",0)
			if basic_count > 0 and public_count(self,enemy,"basic_count_pm") == 0 then set_public_count(self,enemy,"basic_count_pm",basic_count) end
			if trick_count > 0 and public_count(self,enemy,"trick_count_pm") == 0 then set_public_count(self,enemy,"trick_count_pm",trick_count) end
			if equip_count > 0 and public_count(self,enemy,"equip_count_pm") == 0 then set_public_count(self,enemy,"equip_count_pm",equip_count) end
			if basic_count > 3 or trick_count > 3 or equip_count > 3 then best_target = enemy break end --直接讓他失去技能
			if basic_count > 2 or trick_count > 1 or equip_count > 0 or __yuri_value_call(enemy,"getHandcardNum") > 3 then table.insert(good_targets, enemy) end

			table.insert(targets, enemy)
			basic_count = 0
			trick_count = 0
			equip_count = 0
		end
	end
	if not best_target and #good_targets == 0 and #targets == 0 then
		for _, friend in ipairs(self.friends_noself) do
			if not friend:isKongcheng() then
				if __yuri_value_call(friend,"getHandcardNum") < 4 then
					table.insert(targets, friend)
				end
			end
		end
	end
	use.card = policy(self,"#peeking:.:")
	if use.to then
		if best_target then
			use.to:append(best_target)
		elseif #good_targets > 0 then
			use.to:append(good_targets[1])
		elseif #targets > 0 then
			use.to:append(targets[1])
		end
	end
	return
end

sgs.ai_use_value["peeking"] = 4
sgs.ai_use_priority["peeking"] = sgs.ai_use_priority.Dismantlement + 1

sgs.ai_skill_choice.peeking = function(self, choices, data)
	local target = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if __yuri_value_call(p,"getMark","peeking_AI") > 0 then
			target = p
			break
		end
	end
	if self:isFriend(target) then return "BasicCard" end
	if self:isEnemy(target) then
		if public_count(self,target,"basic_count_pm") > 3 then return "BasicCard" end
		if public_count(self,target,"trick_count_pm") > 3 then return "TrickCard" end
		if public_count(self,target,"equip_count_pm") > 3 then return "EquipCard" end

		if public_count(self,target,"basic_count_pm") > 2 then return "BasicCard" end
		if public_count(self,target,"trick_count_pm") > 0 then return "TrickCard" end
		if public_count(self,target,"equip_count_pm") > 0 then return "EquipCard" end

		return "BasicCard"
	end
	return false
end

sgs.ai_skill_cardchosen["peeking"] = function(self, who, flags)
	if not self:isEnemy(who) then
		for _,card in sgs.qlist(who:getCards("e")) do
			return card
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("e")) do
			if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"isKindOf","SilverLion") then
				table.insert(goodchice, card)
			end
			if __yuri_value_call(card,"isKindOf","Weapon") or __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end

sgs.ai_choicemade_filter.skillChoice.peeking = function(self, player, promptlist)
	local to
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if __yuri_value_call(p,"hasFlag","peekingUsing") then
			to = p
			self:setStrategyPlayerFlag(p,'peekingUsing',false)
			break
		end
	end
	local choice = promptlist[#promptlist]
	if choice == "BasicCard" then
		local int = 0
		if public_count(self,to,"basic_count_pm") > 2 then int = int + 30 end
		if __yuri_value_call(to,"getHandcardNum") > 5 then int = int + 30 end
		self:updateIntention(player, to, int)
	else
		self:updateIntention(player, to, 60)
	end
end


sgs.ai_skill_invoke.songforatsu = function(self, data)
	local dying = data:toDying()
	local who = dying.who
	if self:isFriend(who) then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.songforatsu = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		self:updateIntention(player, target, -50)
	end
end

sgs.ai_skill_invoke.lovetoevo = function(self, data)
	if known(self.world.turn_count,"turn count") <= 1 and self.role ~= "rebel" and sgs.playerRoles.rebel == 0 then return false end	--yun
	if self:getCardsNum("Peach") > 0 then return false end
	return true
end

sgs.ai_fill_skill["buuzetsu"] = function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByUseValue(cards,true)
	for _, card in ipairs(cards) do
		if self:slashIsAvailable() then
			if card:isRed() then
				return policy(self,("fire_slash:buuzetsu[%s:%s]=%d"):format(__yuri_value_call(card,"getSuitString"), card:getNumberString(), card:getId()))
			else
				return policy(self,("thunder_slash:buuzetsu[%s:%s]=%d"):format(__yuri_value_call(card,"getSuitString"), card:getNumberString(), card:getId()))
			end
		end
	end
end
sgs.ai_view_as.buuzetsu = function(card, player, card_place)
	local suit = __yuri_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __yuri_value_call(card,"getEffectiveId")
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
	and not __yuri_value_call(card,"isKindOf","Peach") and not __yuri_value_call(card,"hasFlag","using") and not (__yuri_value_call(card,"isKindOf","WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		if card:isRed() then
			return ("fire_slash:buuzetsu[%s:%s]=%d"):format(suit, number, card_id)
		else
			return ("thunder_slash:buuzetsu[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_ajustdamage_to.buuzetsu = function(self,from,to,card,nature)
	if (card and __yuri_value_call(card,"isKindOf","TrickCard")) or not from then
		return -99
	end
	if __yuri_value_call(to,"getMark","@SuperLimitBreak") > 0 and to:isKongcheng() then
		return -1
	end
end


sgs.ai_fill_skill["zurunoonkaeshi"] = function(self,inclusive,request)
	if self.player:hasUsed("#zurunoonkaeshi") then return end
	local no_need = true
	for _, friend in ipairs(self.friends) do
		if __yuri_value_call(friend,"isWounded") then
			no_need = false
			break
		end
	end
	if self.player:hasSkills(sgs.bad_skills) then return policy(self,"#zurunoonkaeshi:.:") end
	if self.player:isNude() or no_need then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	if __yuri_value_call(cards[1],"isKindOf","Peach") then return end
	return policy(self,"#zurunoonkaeshi:" .. cards[1]:getId().. ":")
end
sgs.ai_skill_use_func["#zurunoonkaeshi"] = function(card, use, self)
	self.friends = self:sort(self.friends, "hp")
	local tar
	for _, friend in ipairs(self.friends) do
		if __yuri_value_call(friend,"isWounded") then
			tar = friend
			break
		end
	end
	if tar then
	if card then
		use.card = card
	else
		use.card = policy(self,"#zurunoonkaeshi:.:")
	end
	if use.to and tar then use.to:append(tar) end
	end
	return
end

sgs.ai_skill_choice.zurunoonkaeshi = function(self, choices, data)
	choices = choices:split("+")
	for _, name in ipairs(choices) do
		if string.find(sgs.bad_skills, name) then
			return name
		end
	end
	return false
end

sgs.ai_use_priority.zurunoonkaeshi = sgs.ai_use_priority.Peach - 1
sgs.ai_card_intention["zurunoonkaeshi"] = -60

sgs.ai_skill_invoke.haigu = function(self, data)
	return true
end

sgs.ai_skill_use["@@haigu"] = function(self, prompt)
    self:updatePlayers()
	self.friends = self:sort(self.friends, "defense")
	local selectset = {}
	for _,f in ipairs(self.friends) do
		table.insert(selectset, f:objectName())
		if #selectset > 4 then break end
	end
	if #selectset > 0 then
		return "#haigu:.:->"..table.concat(selectset, "+")
	else
		return "."
	end
    return "."
end

sgs.ai_card_intention["haigu"] = -40

sgs.ai_skill_playerchosen["haigu"] = function(self, targets)
	local tar
	local count = 0
	for _,target in sgs.qlist(targets) do
		count = 0
		if self.player:getPile("haigu_pile"):length() > 3 then break end
		if self:isFriend(target) then
			if target:getCards("j"):length() > 0 then
				for _,jc in sgs.qlist(target:getCards("j")) do
					if not __yuri_value_call(jc,"isKindOf","YanxiaoCard") then
						count = count + 1
					end
				end
			end
			if __yuri_value_call(target,"isWounded") and target:getArmor() and target:getArmor():getClassName() == "SilverLion" then count = count + 2 end

			if self.player:getPile("haigu_pile"):length() <= count then tar = target end
		end
	end
	if not tar then
		local findmax = 0
		local curtar
		for _,target in sgs.qlist(targets) do
			if not self:isFriend(target) then
				if (__yuri_value_call(target,"getHandcardNum")+target:getEquips():length()) > findmax then
					findmax = (__yuri_value_call(target,"getHandcardNum")+target:getEquips():length())
					curtar = target
				end
			end
		end
		tar = curtar
	end
	if tar then
		return tar
	else
		return nil
	end
end

sgs.ai_skill_cardchosen["haigu"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("ej")) do
			if Q_goodToThrow(who, card, true) then return card end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"getClassName") == "SilverLion" then
				table.insert(goodchice, card)
			end
			if __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end
sgs.ai_choicemade_filter.cardChosen.haigu = sgs.ai_choicemade_filter.cardChosen.dismantlement


sgs.ai_skill_invoke.kirisou = function(self, data)
	local current = data:toPlayer()
	if self:isEnemy(current) or (self:isFriend(current) and ((current:getArmor() and (current:getArmor():getClassName() == "GaleShell" or (__yuri_value_call(current,"isWounded") and current:getArmor():getClassName() == "SilverLion"))) or (current:getTreasure() and __yuri_value_call(current,"getHandcardNum") < 4 and current:getTreasure():isKindOf("Tianjitu")))) then
		return true
	end
	return false
end

sgs.ai_skill_cardchosen["kirisou"] = function(self, who, flags)
	if self:isFriend(who) then
		for _,card in sgs.qlist(who:getCards("e")) do
			if __yuri_value_call(card,"getClassName") == "SilverLion" and __yuri_value_call(who,"isWounded") and who:getCards("j"):length() == 0 then
				return card
			end
			if __yuri_value_call(card,"getClassName") == "GaleShell" and who:getCards("j"):length() == 0 then
				return card
			end
			if __yuri_value_call(card,"getClassName") == "Tianjitu" and __yuri_value_call(who,"getHandcardNum") < 4 then
				return card
			end
		end
	else
		local goodchice = {}
		local normal = {}
		for _,card in sgs.qlist(who:getCards("he")) do
			if not __yuri_value_call(who,"isWounded") and __yuri_value_call(card,"getClassName") == "SilverLion" then
				table.insert(goodchice, card)
			end
			if __yuri_value_call(card,"getClassName") == "EightDiagram" or __yuri_value_call(card,"getClassName") == "Vine" or __yuri_value_call(card,"getClassName") == "RenwangShield" or __yuri_value_call(card,"getClassName") == "WoodenOx" then
				table.insert(goodchice, card)
			end
			table.insert(normal, card)
		end
		if #goodchice > 0 then return goodchice[1] end
		if #normal > 0 then return normal[1] end
	end
	return nil
end

sgs.ai_skill_choice.kirisou = function(self, choices, data)
	local target = data:toPlayer()
	if self:isEnemy(target)  then
		local use = room_tag(self,"kirisou","CardUse")
		local dummy_use = self:aiUseCard(use.card, dummy_plan(true, 0, self.room:getOtherPlayers(target)))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
			if math.random() < 0.5 or __yuri_value_call(self.player,"getHandcardNum") < 2 then
				return "kirisou_ea"
			end
			return "kirisou_e2"
		end
	end
	return "kirisou_e1"
end

sgs.ai_fill_skill["gopugu"] = function(self,inclusive,request)
    if not self.player:isNude() then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local ecards = sgs.QList2Table(self.player:getCards("e"))
		cards = self:sortByUseValue(cards,true)
		for _,card in ipairs(ecards) do
			local card_str = ("#gopugu:"..card:getId()..":")
			if __yuri_value_call(self.player,"isWounded") and __yuri_value_call(card,"getClassName") == "SilverLion" then return policy(self,card_str) end
			if __yuri_value_call(self.player,"getHandcardNum") < 4 and __yuri_value_call(card,"getClassName") == "Tianjitu" then return policy(self,card_str) end
		end
		for _,card in ipairs(cards) do
			local card_str = ("#gopugu:"..card:getId()..":")
			if __yuri_value_call(card,"isKindOf","TrickCard") then
				local dummy_use = self:aiUseCard(card, dummy_plan())
    			if dummy_use.card and dummy_use and dummy_use.to then
					continue
				end
				return policy(self,card_str)
			end
			if __yuri_value_call(card,"isKindOf","Weapon") and self.player:getWeapon() then return policy(self,card_str) end
			if __yuri_value_call(card,"isKindOf","Armor") and self.player:getArmor() then return policy(self,card_str) end
			if __yuri_value_call(card,"isKindOf","OffensiveHorse") and self.player:getOffensiveHorse() then return policy(self,card_str) end
			if __yuri_value_call(card,"isKindOf","DefensiveHorse") and self.player:getDefensiveHorse() then return policy(self,card_str) end
			if __yuri_value_call(card,"isKindOf","Treasure") and self.player:getTreasure() then return policy(self,card_str) end
		end
	end
end

sgs.ai_skill_use_func["#gopugu"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["gopugu"] = 4
sgs.ai_use_priority["gopugu"] = 8

sgs.ai_skill_discard.kirisou_umaretuski = function(self)
	local to_cards = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	local effect = tag(self,"SlashMissed","SlashEffect")
	local to = effect.to
	if #cards < 3 or self:isFriend(to) then return true end
	return false
end

sgs.ai_view_as.yuri_hagaku = function(card, player, card_place)
	local suit = __yuri_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __yuri_value_call(card,"getEffectiveId")
	if card:isBlack() and (card_place == sgs.Player_PlaceHand or card_place == sgs.Player_PlaceEquip) then
		return ("nullification:yuri_hagaku[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_cardneed.yuri_hagaku = function(to, card, self)
	return card:isBlack()
end

sgs.ai_skill_invoke.yuri_hagaku = function(self, data)
	return true
end

sgs.ai_fill_skill["new_againstdis"] = function(self,inclusive,request)
	local DiscardPile = self.room:getDiscardPile()
	if (not self.player:hasUsed("#new_againstdis")) and DiscardPile:length() > 1 then
		local card_str = ("#new_againstdis:%d:")
		return policy(self,card_str)
	end
	return false
end

sgs.ai_skill_use_func["#new_againstdis"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["new_againstdis"] = sgs.ai_use_value.ExNihilo
sgs.ai_use_priority["new_againstdis"] = sgs.ai_use_priority.ExNihilo - 1

sgs.ai_target_revises.helmet = function(to,card,self)
	if __yuri_value_call(card,"isKindOf","Slash") and not (__yuri_value_call(card,"isKindOf","ThunderSlash") or __yuri_value_call(card,"isKindOf","FireSlash"))
	then return true end
end

sgs.ai_skill_use["@@hunnshin"] = function(self, prompt)
    self:updatePlayers(true)
	local card_to_use = {}
	local needpeach = false
	local needachol = false
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards, true)
	if self:isWeak(self.player) then
		needpeach = true
		needachol = true
	end
	if not needpeach then
		for _, friend in ipairs(self.friends_noself) do
			if self:isWeak(friend) then
				needpeach = true
			end
		end
	end
		for _, c in ipairs(cards) do
			if (needpeach and not __yuri_value_call(c,"isKindOf","Peach")) or (needachol and not __yuri_value_call(c,"isKindOf","Analeptic")) or (not needpeach and not needachol) then
				table.insert(card_to_use, c:getId())
			end
			if #card_to_use >= 2 then break end
		end
    local targets = {}
	self.friends = self:sort(self.friends, "chaofeng")
	local fs = {}
	for _,f in ipairs(self.friends) do
		if f:getPile("MWCreate"):isEmpty() then
			table.insert(fs, f:objectName())
		end
    end
    for _,f in ipairs(self.friends) do
		if f:getPile("MWCreate"):isEmpty() and (f:hasSkills(sgs.need_equip_skill .. "|clearthemeridians|hunnshin|witty")) then
			table.insert(targets, f:objectName())
			table.removeOne(fs, f:objectName())
		end
		if #targets >= #card_to_use then break end
    end
	if #targets < #card_to_use and #fs > 0 then
		local formax = #fs
		for n = 1, formax do
			table.insert(targets, fs[n])
			if #targets >= #card_to_use then break end
		end
	end
	if #targets == 0 then return nil end
	return "#hunnshin:"..table.concat(card_to_use, "+")..":->"..table.concat(targets, "+")
end

sgs.ai_card_intention.hunnshin = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		local intention = -25
		self:updateIntention(from, to, intention)
	end
end

sgs.ai_skill_choice.tennsainohojyou = function(self, choices, data)
	local jcn = self.player:getCards("j"):length()
	local ecn = self.player:getCards("e"):length()
	local hcn = self.player:getCards("h"):length()

	local n = jcn
	if ecn > 0 then
		if self.player:getArmor() and self.player:getArmor():getClassName() == "GaleShell" then n=n+1 end
		if __yuri_value_call(self.player,"isWounded") and self.player:getArmor() and self.player:getArmor():getClassName() == "SilverLion" then n=n+1 end
		if self.player:getTreasure() and self.player:getTreasure():getClassName() == "Tianjitu" and __yuri_value_call(self.player,"getHandcardNum") < 4 then n=n+1 end
	end
	if hcn > 0 then
		local needpeach = false
		local needachol = false
		if self:isWeak(self.player) then
			needpeach = true
			needachol = true
		end
		if not needpeach then
			for _, friend in ipairs(self.friends_noself) do
				if self:isWeak(friend) then
					needpeach = true
				end
			end
		end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _ ,c in ipairs(cards) do
			if (needpeach and not __yuri_value_call(c,"isKindOf","Peach")) or (needachol and not __yuri_value_call(c,"isKindOf","Analeptic")) or (not needpeach and not needachol and not __yuri_value_call(c,"isKindOf","nullification")) then n=n+1 end
		end
	end
	n = math.min(3, n)
	if n > 0 then return n end
	return "cancel"
end
sgs.ai_skill_cardchosen["tennsainohojyou"] = function(self, who, flags)
		for _,card in sgs.qlist(who:getCards("ej")) do
			if Q_goodToThrow(who, card, true) then return card end
		end
		local cards = self.player:getCards("he")
		local tothrow
		cards = sgs.QList2Table(cards)
		cards = self:sortByUseValue(cards, true)
		local needpeach = false
		local needachol = false
		if self:isWeak(self.player) then
			needpeach = true
			needachol = true
		end
		if not needpeach then
			for _, friend in ipairs(self.friends_noself) do
				if self:isWeak(friend) then
					needpeach = true
				end
			end
		end
		for _,c in ipairs(cards) do
			if (needpeach and not __yuri_value_call(c,"isKindOf","Peach")) or (needachol and not __yuri_value_call(c,"isKindOf","Analeptic")) or (not needpeach and not needachol and not __yuri_value_call(c,"isKindOf","nullification")) then
				tothrow = c
				break
			end
		end
		if tothrow then return tothrow end
	return nil
end

sgs.ai_skill_invoke.jiyuunokuni = function(self,data)
	local target = data:toPlayer()
	local n = 0
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local lcard = self.player:getHandcards():first()
	if self:isFriend(target) then
		if self:isWeak(self.player) and not self:isWeak(target) then
			if self:needKongcheng(self.player) and __yuri_value_call(self.player,"getHandcardNum") == 1 and not (self:isWeak(self.player) and __yuri_value_call(lcard,"isKindOf","Analeptic")) then
				return true
			end
			for _,c in ipairs(cards) do
				if __yuri_value_call(c,"isKindOf","Peach") or __yuri_value_call(c,"isKindOf","Analeptic") then n=n+1 end
			end
			if n == 1 and __yuri_value_call(self.player,"getHandcardNum") < 2 then
				return false
			end
		end
	else
		if self:needKongcheng(self.player) and __yuri_value_call(self.player,"getHandcardNum") == 1 and not (__yuri_value_call(lcard,"isKindOf","Peach") or (self:isWeak(self.player) and __yuri_value_call(lcard,"isKindOf","Analeptic"))) then
			return true
		end
		for _,c in ipairs(cards) do
			if __yuri_value_call(c,"isKindOf","Peach") or (self:isWeak(self.player) and __yuri_value_call(c,"isKindOf","Analeptic")) then n=n+1 end
			if (not self:isWeak(self.player)) and __yuri_value_call(c,"isKindOf","TrickCard") and not __yuri_value_call(c,"isKindOf","Lightning") then n=n+1 end
			if (not self:isWeak(self.player)) and (__yuri_value_call(c,"isKindOf","Weapon") or __yuri_value_call(c,"isKindOf","Armor")) then n=n+1 end
		end
		if n == __yuri_value_call(self.player,"getHandcardNum") then
			return false
		end
	end
	return true
end

sgs.ai_skill_invoke.yuryounowaku = function(self,data)
	local target = data:toPlayer()
	local cards = self.player:getCards("jhe")
	cards = sgs.QList2Table(cards)
	if self:isFriend(target) then
		if target:getTreasure() and target:getTreasure():getClassName() == "WoodenOx" and target:getPile("wooden_ox"):length() > 0 then return false end
		for _,card in sgs.qlist(target:getCards("je")) do
			if Q_goodToThrow(target, card, true) then return true end
		end
		if (self:isWeak(target) and self:getCardsNum("Peach") > 0 and getCardsNum("Peach", target) < self:getCardsNum("Peach")) or target:isKongcheng() then return true end
		if (getCardsNum("Peach", target) > 0 and __yuri_value_call(target,"isWounded")) or target:getCards("e"):length() > 2 or __yuri_value_call(target,"getHandcardNum") > __yuri_value_call(self.player,"getHandcardNum")+1
		or self.player:isKongcheng() then return false end
		for _,c in ipairs(cards) do
			if __yuri_value_call(c,"isAvailable",target) then return true end
		end
	else
		if (__yuri_value_call(target,"isWounded") and self:getCardsNum("Peach") > 0) or target:isKongcheng() then return false end
		if target:getTreasure() and target:getTreasure():getClassName() == "WoodenOx" and target:getPile("wooden_ox"):length() > 1 then return true end
		for _,card in sgs.qlist(target:getCards("je")) do
			if Q_goodToThrow(target, card, true) then return false end
		end
		if (getCardsNum("Peach", target) > 0 and __yuri_value_call(target,"isWounded")) or target:getCards("e"):length() > 1 or __yuri_value_call(target,"getHandcardNum") > __yuri_value_call(self.player,"getHandcardNum")+1
		or self.player:isKongcheng() then return true end
		for _,c in ipairs(cards) do
			if __yuri_value_call(c,"isAvailable",target) then return false end
		end
	end
	return false
end

sgs.ai_skill_discard.yurimi = function(self, discard_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	local compare_func = function(a, b)
		return self:getKeepValue(a) < self:getKeepValue(b)
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if #to_discard >= discard_num then break end
		table.insert(to_discard, card:getId())
	end

	return to_discard
end
sgs.ai_skill_use["@@yurimi"] = function(self, prompt)
	local pile = self.player:getPile("yurimipile")
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if pile:isEmpty() or (#cards == 0) then
		return "."
	end
	local max_num = pile:length()
	local n = 0
	for _, card_id in sgs.qlist(pile) do
		table.insert(cards, visible(self,card_id))
	end
	local exchange_to_pile = {}
	cards = self:sortByCardNeed(cards, false)

	for _,card in ipairs(cards) do
		if Q_goodToThrow(self.player, card, false) then
			table.insert(exchange_to_pile, card)
			n = n+1
			if n >= max_num then break end
		end
	end

	if n < max_num then
		for _,card in ipairs(cards) do
			table.insert(exchange_to_pile, card)
			n = n+1
			if n >= max_num then break end
		end
	end

	if #exchange_to_pile == 0 then return "." end
	local exchange = {}

	for _, c in ipairs(exchange_to_pile) do
		table.insert(exchange, c:getId())
	end
	return "#yurimi:"..table.concat(exchange, "+")..":"
end
sgs.ai_skill_invoke.yurimi = function(self,data)
	local target = data:toPlayer()
	if self:isFriend(target) and not (self:needKongcheng(target) and target:isKongcheng()) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.yurimi = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then self:updateIntention(player, target, -30) end
	end
end

sgs.ai_skill_playerchosen.yuri_hengjiang = function(self, targets)
	self:updatePlayers()
	local targets = {}
	local good_targets = {}
	local best_target = nil
	self.enemies = self:sort(self.enemies, "defense")
	self.friends_noself = self:sort(self.friends_noself, "defense")
	for _, e in ipairs(self.enemies) do
		if __yuri_value_call(e,"getMark","@yuri_hengjiang") == 0 then
			table.insert(targets, e)
			if (not self:needKongcheng(e)) or (self:needKongcheng(e) and getCardsNum("Peach", e, self.player) > 0 and __yuri_value_call(e,"getHp") == 1) then
				if self:isWeak(e) then table.insert(good_targets, e) end
				if __yuri_value_call(e,"getHp") == 1 then best_target = e end
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if __yuri_value_call(friend,"getMark","@yuri_hengjiang") < 2 then
			if self:needKongcheng(friend) and getCardsNum("Peach", friend, self.player) < 1 then table.insert(good_targets, friend) end
		end
	end
	for _, e in ipairs(self.enemies) do
		if __yuri_value_call(e,"getMark","@yuri_hengjiang") > 0 then
			table.insert(targets, e)
		end
	end
	if best_target then return best_target end
	if #good_targets > 0 then return good_targets[1] end
	if #targets > 0 then return targets[1] end
	return nil
end
sgs.ai_playerchosen_intention["yuri_hengjiang"] = function(self, from, to)
	if not self:needKongcheng(to) then
		self:updateIntention(from, to, 40)
	end
end



sgs.ai_fill_skill["kurashinfurashu"] = function(self,inclusive,request)
	local var = 0
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			var = var + 1
		end
	end
	if var == 0 then return false end
	if (not self.player:hasUsed("#kurashinfurashu")) then
		return policy(self,"#kurashinfurashu:.:")
	end
end

sgs.ai_skill_use_func["#kurashinfurashu"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "handcard")
	local targets = {}
	local good_targets = {}
	local best_target = nil
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			if self:isWeak(enemy) and __yuri_value_call(enemy,"getHandcardNum") == 1 and not self:needKongcheng(enemy) then
				best_target = enemy
				break
			end
			if self:isWeak(enemy) and (getCardsNum("Peach", enemy, self.player) > 0 or getCardsNum("Analeptic", enemy, self.player) > 0) then
				table.insert(good_targets, enemy)
			else
				table.insert(targets, enemy)
			end
		end
	end
	use.card = policy(self,"#kurashinfurashu:.:")
	if use.to then
		if best_target then
			use.to:append(best_target)
		elseif #good_targets > 0 then
			use.to:append(good_targets[1])
		elseif #targets > 0 then
			use.to:append(targets[1])
		end
		return
	end
end

sgs.ai_use_value["kurashinfurashu"] = 3.5
sgs.ai_use_priority["kurashinfurashu"] = sgs.ai_use_value.Slash - 0.1
sgs.dynamic_value.damage_card["kurashinfurashu"] = true
sgs.ai_card_intention["kurashinfurashu"] = 50

sgs.ai_skill_playerchosen.kurashinfurashu = function(self, targets)
	self:updatePlayers()
	local ispeach = false
	if __yuri_value_call(self.player,"getMark","kurashu_ai_p") == 1 then ispeach = true end
	local targets = {}
	local good_targets = {}
	local best_target = nil
	self.friends = self:sort(self.friends, "hp")
	if ispeach then
		for _, friend in ipairs(self.friends) do
			if __yuri_value_call(friend,"isWounded") then
				table.insert(targets, friend)
				if self:isWeak(friend) and friend:objectName() ~= self.player:objectName() then table.insert(good_targets, friend) end
				if ((__yuri_value_call(friend,"getHandcardNum")+friend:getEquips():length()) <= 1 and __yuri_value_call(friend,"getHp") == 1) or (self:isWeak(friend) and __yuri_value_call(friend,"isLord")) then best_target = friend end
			end
		end
		if best_target then return best_target end
		if #good_targets > 0 then return good_targets[1] end
		if #targets > 0 then return targets[1] end
	end
	return self.player
end
sgs.ai_playerchosen_intention["kurashinfurashu"] = function(self, from, to)
	self:updateIntention(from, to, -40)
end


sgs.ai_skill_invoke.arkora = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.arkora = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then self:updateIntention(player, target, 50) end
	end
end


sgs.ai_skill_cardask["@arkoraask"] = function(self,data,pattern,target)
	local n = self:ajustDamage(target,nil,1,nil)
	if n==1 and self:needToLoseHp(self.player,target,nil)
	then return "." end
	local function getarkoraJink()
		if known(self:getResponsePolicy().humanized,"humanized policy") then
			stage_delay(self,math.random(self:getSpeechDelay()*0.3,self:getSpeechDelay()*1.3))
		end
		local js = self:getCard("Jink",true)
		for _,c in sgs.list(js)do
			if __yuri_value_call(self.player,"hasFlag","dahe") and __yuri_value_call(c,"getSuit")~=sgs.Card_Heart then continue end
			return c:getLegacyStringKey()
		end
		if known(self:getResponsePolicy().humanized,"humanized policy") and math.random()<0.5 and #self.friends_noself>0
		and self:getCardsNum("Peach,Analeptic")<1 and __yuri_value_call(self.player,"getHp")<=math.abs(n) then
			self:speak("noJink")
			stage_delay(self,math.random(self:getSpeechDelay()*0.5,self:getSpeechDelay()*1.5))
		end
		return "."
	end
	if self:isFriend(target) then
		if self:findLeijiTarget(self.player,50,target) then return getarkoraJink() end
		if __yuri_value_call(self.player,"getLostHp")==0 and __yuri_value_call(self.player,"isMale") and __yuri_value_call(target,"hasSkill","jieyin") then return "." end
		if not self:hasJueqingEffect(target,self.player) then
			if (__yuri_value_call(target,"hasSkill","nosrende") or __yuri_value_call(target,"hasSkill","rende") and not target:hasUsed("RendeCard")) and __yuri_value_call(self.player,"hasSkill","jieming")
			or __yuri_value_call(target,"hasSkill","pojun") and not __yuri_value_call(self.player,"faceUp")
			then return "." end
		end
	else
		if n>1 or n>=__yuri_value_call(self.player,"getHp") then return getarkoraJink() end
		local current = self.room:getCurrent()
		if current and __yuri_value_call(current,"hasSkill","juece") and __yuri_value_call(self.player,"getHp")>0 then
			for _,c in sgs.list(self:getCards("Jink"))do
				if self.player:isLastHandCard(c,true)
				then return "." end
			end
		end
		if __yuri_value_call(self.player,"getHandcardNum")==1 and self:needKongcheng()
		or not(self:hasLoseHandcardEffective() or self.player:isKongcheng()) then return getarkoraJink() end
		if __yuri_value_call(self.player,"getHp")>1 and getKnownCard(target,self.player,"Slash")>0
		and getKnownCard(target,self.player,"Analeptic")>0 and self:getCardsNum("Jink")<2
		and (__yuri_value_call(target,"getPhase")<=sgs.Player_Play or self:slashIsAvailable(target) and target:canSlash(self.player))
		then return "." end
	end
	return getarkoraJink()
end

sgs.ai_fill_skill["warlike"] = function(self,inclusive,request)
	if __yuri_value_call(self.player,"hasSkill","bloodfight") then return nil end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards,true)

	local card
	for _,c in ipairs(cards) do
		if __yuri_value_call(c,"isKindOf","TrickCard") then
			card = c
			break
		end
	end

	if not card then return nil end
	local suit = __yuri_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __yuri_value_call(card,"getEffectiveId")
	local card_str = ("duel:warlike[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = policy(self,card_str)
	assert(skillcard)
	return skillcard
end



sgs.ai_target_revises.optimistic = function(to,card)
	if __yuri_value_call(card,"isKindOf","IronChain")
	then return true end
	if to:getEquips():length() + __yuri_value_call(to,"getHandcardNum") > __yuri_value_call(to,"getHp") and __yuri_value_call(to,"getHp") == 1 then
		if not (__yuri_value_call(card,"isKindOf","SkillCard") or __yuri_value_call(card,"isKindOf","Peach") or __yuri_value_call(card,"isKindOf","AmazingGrace") or __yuri_value_call(card,"isKindOf","GodSalvation") or __yuri_value_call(card,"isKindOf","Dismantlement") or __yuri_value_call(card,"isKindOf","Snatch") or __yuri_value_call(card,"isKindOf","IronChain") or __yuri_value_call(card,"isKindOf","Zhujinqiyuan")) then
			return true
		end
	end
end

sgs.ai_ajustdamage_to.optimistic   = function(self, from, to, card, nature)
	if to:getEquips():length() + __yuri_value_call(to,"getHandcardNum") > __yuri_value_call(to,"getHp") and __yuri_value_call(to,"getHp") == 1 then
		return -99
	end
end

sgs.ai_fill_skill["keishoukaki"] = function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByCardNeed(cards, true)
	local chosen = {}
	local getPeach = 0
	local num = 0
	local num_max = 10 - __yuri_value_call(self.player,"getMark","taiheikei_hiddenmark")
	if num_max == 0 or (self:getOverflow() == 0 and self.player:hasUsed("#keishoukaki")) then return end
	for _, c in ipairs(cards) do
		if (__yuri_value_call(c,"isKindOf","Peach") and self:getCardsNum("Peach") > getPeach+2) then
			getPeach = getPeach+1
			num = num+1
			table.insert(chosen, c:getId())
		end
		if not __yuri_value_call(c,"isKindOf","Peach") and not (__yuri_value_call(c,"isKindOf","Analeptic") and self:isWeak(self.player)) then
			num = num+1
			table.insert(chosen, c:getId())
		end
		if num >= self:getOverflow() or num == num_max then
			break
		end
	end
	if #chosen > 0 then
		local parse = policy(self,"#keishoukaki:"..table.concat(chosen,"+")..":")
		assert(parse)
		return parse
	end
	return
end

sgs.ai_skill_use_func["#keishoukaki"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.keishoukaki = sgs.ai_use_priority.Slash - 0.1
sgs.ai_use_value["keishoukaki"] = 4


sgs.ai_skill_choice["keishoukaki"] = function(self, choices, data)
	if __yuri_value_call(self.player,"hasFlag","KeishoukakiZokusei") then
		self:setStrategyPlayerFlag(self.player,'KeishoukakiZokusei',false)
		local weak_friend, weak_enemy = 0, 0
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isWeak(player) then
				if self:isEnemy(player) then
					weak_enemy = weak_enemy + 1
					if __yuri_value_call(player,"isLord") then weak_enemy = weak_enemy + 1 end
				elseif self:isFriend(player) then
					weak_friend = weak_friend + 1
					if __yuri_value_call(player,"isLord") then weak_friend = weak_friend + 1 end
				end
			end
		end
		local n = 0
		local e_dn = 0
		local f_dn = 0
		local ehasvine = false
		local frecnum = 0
		local erecnum = 0
		local e_cardneed = 0
		local f_cardneed = 0
		local e_manyhc = 0
		local f_manyhc = 0
		local e_haveCross = false
		local need_kana = false
		local f_haveCross = false
		local e_can_use = 0
		local f_can_use = 0
		for _,enemy in ipairs(self.enemies) do
			if enemy:hasWeapon("crossbow") or enemy:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao") then
				if __yuri_value_call(enemy,"getHandcardNum") > 2 then
					e_haveCross = true
				end
				if __yuri_value_call(enemy,"getHandcardNum") > 4 then
					need_kana = true
				end
			end
			if __yuri_value_call(enemy,"getHandcardNum") > 5 then e_manyhc = e_manyhc + 1 end
			if enemy:hasArmorEffect("vine") then e_dn=e_dn+1 ehasvine = true end
			if enemy:hasSkills(sgs.recover_hp_skill) or enemy:hasSkills("helptheweak|goldentear|weareidle|married|barakurosaku|zurunoonkaeshi") then erecnum = erecnum+1 end
			if __yuri_value_call(enemy,"getHandcardNum") < 2 or (__yuri_value_call(enemy,"getHandcardNum") < 3 and (enemy:hasSkills(sgs.cardneed_skill) or
			enemy:hasSkills("genshunoYURI|weareidle|yurimi|yochi|wisdom_s|bougairensha|imwatching|eatforlike|yuri_hagaku|fakebody|heapridge|japenknifejile|zhixi|frankly|clever|optimistic|countertrick|helptheweak"))) then e_cardneed = e_cardneed+1 end
			for _, c in sgs.qlist(known(enemy:getKnownCards(),"known enemy hand")) do
				if __yuri_value_call(c,"hasFlag","visible") and __yuri_value_call(c,"isDamageCard") and __yuri_value_call(c,"isKindOf","TrickCard") then e_dn=e_dn+1 end
				if __yuri_value_call(c,"hasFlag","visible") and (__yuri_value_call(c,"isKindOf","TrickCard") or __yuri_value_call(c,"isKindOf","EquipCard")) then n = n+1 end
				if __yuri_value_call(c,"hasFlag","visible") and (__yuri_value_call(c,"isKindOf","Peach") or __yuri_value_call(c,"isKindOf","Analeptic")) then erecnum = erecnum+1 end
			end
			if e_can_use < n then e_can_use = n end
		end
		n = 0
		for _,friend in ipairs(self.friends) do
			if __yuri_value_call(friend,"getHandcardNum") > 2 and (friend:hasWeapon("crossbow") or friend:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao")) then f_haveCross = true end
			if __yuri_value_call(friend,"getHandcardNum") > 5 then f_manyhc = f_manyhc + 1 end
			if friend:hasSkills(sgs.recover_hp_skill) or friend:hasSkills("helptheweak|goldentear|weareidle|married|barakurosaku|zurunoonkaeshi") then frecnum = frecnum+1 end
			if __yuri_value_call(friend,"getHandcardNum") < 2 or (__yuri_value_call(friend,"getHandcardNum") < 3 and (friend:hasSkills(sgs.cardneed_skill) or
			friend:hasSkills("genshunoYURI|weareidle|yurimi|yochi|wisdom_s|bougairensha|imwatching|eatforlike|yuri_hagaku|fakebody|heapridge|japenknifejile|zhixi|frankly|clever|optimistic|countertrick|helptheweak"))) then f_cardneed = f_cardneed+1 end
			for _, c in sgs.qlist(known(friend:getKnownCards(),"known friend hand")) do
				if __yuri_value_call(c,"hasFlag","visible") and __yuri_value_call(c,"isDamageCard") and __yuri_value_call(c,"isKindOf","TrickCard") then f_dn=f_dn+1 end
				if __yuri_value_call(c,"hasFlag","visible") and (__yuri_value_call(c,"isKindOf","TrickCard") or __yuri_value_call(c,"isKindOf","EquipCard")) then n=n+1 end
				if __yuri_value_call(c,"hasFlag","visible") and (__yuri_value_call(c,"isKindOf","Peach") or __yuri_value_call(c,"isKindOf","Analeptic")) then frecnum = frecnum+1 end
			end
			if f_can_use < n then f_can_use = n end
		end
		if choices:match("mizu") then
			if weak_friend > 0 and weak_friend >= weak_enemy and frecnum >= erecnum then return "mizu" end
		end
		if choices:match("kana") then
			if not f_haveCross and e_haveCross then return "kana" end
			if f_manyhc < e_manyhc or (f_can_use < e_can_use and e_can_use > 1) then return "kana" end
			if need_kana then return "kana" end
		end
		if choices:match("moku") then
			if f_cardneed >= e_cardneed then return "moku" end
		end
		if choices:match("daiji") then
			if ((e_dn > 1 and weak_friend > 0) or e_dn > 2) and f_dn <= e_dn then return "daiji" end
		end
		if choices:match("hono") then
			if ehasvine then return "hono" end
			if #(self:getChainedFriends()) < #(self:getChainedEnemies()) and
				#(self:getChainedFriends()) + #(self:getChainedEnemies()) > 1 then return "hono" end
		end
		local choices_table = choices:split("+")
		return choices_table[math.random(1, #choices_table)]
	else
		if self.player:getPile("taiheikei"):isEmpty() then return "cancel" end
		if __yuri_value_call(self.player,"getMark","&kana") > 0 then
			local target = data:toPlayer()
			if self:isFriend(target) and self:getOverflow(target) > 2 then
				return "cancel_effect"
			else
				return "cancel"
			end
		end
		if __yuri_value_call(self.player,"getMark","&moku") > 0 then
			local target = data:toPlayer()
			if self:isFriend(target) and __yuri_value_call(target,"getHandcardNum") < 2 then
				return "active_effect"
			else
				return "cancel"
			end
		end
		if __yuri_value_call(self.player,"getMark","&mizu") > 0 then
			local target = data:toPlayer()
			if self:isFriend(target) and __yuri_value_call(target,"getHandcardNum") < 2 and __yuri_value_call(target,"getLostHp") > 1 then
				return "active_effect"
			elseif self:isEnemy(target) and __yuri_value_call(target,"getHandcardNum") > 1 and __yuri_value_call(target,"getLostHp") > 1 then
				return "cancel_effect"
			else
				return "cancel"
			end
		end
		if __yuri_value_call(self.player,"getMark","&hono") > 0 then
			local damage = data:toDamage()
			if self:isEnemy(damage.to) then
				return "active_effect"
			elseif self:isFriend(damage.to) and self:isEnemy(damage.from) and __yuri_value_call(damage.from,"getHandcardNum") > 1 then
				return "cancel_effect"
			else
				return "cancel"
			end
		end
		if __yuri_value_call(self.player,"getMark","&daiji") > 0 then
			local damage = data:toDamage()
			if self:isFriend(damage.to) and __yuri_value_call(damage.to,"getHandcardNum") < 3 then
				return "active_effect"
			elseif self:isEnemy(damage.to) and __yuri_value_call(damage.to,"getHandcardNum") > 2 then
				return "cancel_effect"
			else
				return "cancel"
			end
		end
	end
end

sgs.ai_choicemade_filter.skillChoice.keishoukaki = function(self, player, promptlist)
	local to
	local type_str
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if __yuri_value_call(p,"hasFlag","kana_AI") then
			to = p
			self:setStrategyPlayerFlag(p,'kana_AI',false)
			type_str = "kana"
			break
		elseif __yuri_value_call(p,"hasFlag","moku_AI") then
			to = p
			self:setStrategyPlayerFlag(p,'moku_AI',false)
			type_str = "moku"
			break
		elseif __yuri_value_call(p,"hasFlag","mizu_AI") then
			to = p
			self:setStrategyPlayerFlag(p,'mizu_AI',false)
			type_str = "mizu"
			break
		elseif __yuri_value_call(p,"hasFlag","hono_AI") then
			to = p
			self:setStrategyPlayerFlag(p,'hono_AI',false)
			type_str = "hono"
			break
		elseif __yuri_value_call(p,"hasFlag","daiji_AI") then
			to = p
			self:setStrategyPlayerFlag(p,'daiji_AI',false)
			type_str = "daiji"
			break
		end
	end
	if not type_str then return false end
	local choice = promptlist[#promptlist]
	if type_str == "kana" then
		if choice == "cancel_effect" then
			self:updateIntention(player, to, -40)
		end
	end
	if type_str == "moku" or type_str == "mizu" or type_str == "daiji" then
		if choice == "active_effect" then
			self:updateIntention(player, to, -40)
		end
		if choice == "cancel_effect" then
			self:updateIntention(player, to, 40)
		end
	end
	if type_str == "hono" then
		if choice == "active_effect" then
			self:updateIntention(player, to, 40)
		end
		if choice == "cancel_effect" then
			self:updateIntention(player, to, -40)
		end
	end
end
sgs.ai_skill_cardask["@moku_draw_ask"] = function(self,data,pattern)
	local target = data:toPlayer()
	if target:isKongcheng() then return "." end
    local needs = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards, true)
	for _,card in ipairs(cards) do
		if not (__yuri_value_call(card,"isKindOf","Peach") or __yuri_value_call(card,"isKindOf","Nullification") or (self:isWeak(target) and __yuri_value_call(card,"isKindOf","Analeptic")) or (__yuri_value_call(target,"getHandcardNum") == 1 and __yuri_value_call(card,"isKindOf","Jink"))) then
			table.insert(needs, card)
		end
	end
	if #needs > 0 then return "$" .. __yuri_value_call(needs[1],"getEffectiveId") end
    return "."
end
sgs.ai_skill_cardask["@mizu_recover_ask"] = function(self,data,pattern)
	local target = data:toPlayer()
	if (not __yuri_value_call(target,"isWounded")) or __yuri_value_call(target,"getLostHp") < 2 or target:isKongcheng() then return "." end
    local needs = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards, true)
	for _,card in ipairs(cards) do
		if card:isRed() then
			if not (__yuri_value_call(card,"isKindOf","Peach") or __yuri_value_call(card,"isKindOf","ExNihilo") or __yuri_value_call(card,"isKindOf","Dongzhuxianji")) then
				table.insert(needs, card)
			end
		end
	end
	if #needs > 0 then return "$" .. __yuri_value_call(needs[1],"getEffectiveId") end
    return "."
end
sgs.ai_skill_cardask["@hono_damage_ask"] = function(self,data,pattern)
	local damage = data:toDamage()
	local from = damage.from
	local to = damage.to
	if from:isKongcheng() or self:isFriend(to) then return "." end
    local needs = {}
	local cards = complete_hand(self,from)
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards, true)
	for _,card in ipairs(cards) do
		if __yuri_value_call(card,"getSuit") == sgs.Card_Spade then
			table.insert(needs, card)
		end
	end
	if #needs > 0 then return "$" .. __yuri_value_call(needs[1],"getEffectiveId") end
    return "."
end
sgs.ai_skill_cardask["@daiji_damage_ask"] = function(self,data,pattern)
	local damage = data:toDamage()
	local to = damage.to
	if to:isKongcheng() then return "." end
    local needs = {}
	local cards = complete_hand(self,to)
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards, true)
	for _,card in ipairs(cards) do
		if card:isBlack() then
			table.insert(needs, card)
		end
	end
	if #needs > 0 then return "$" .. __yuri_value_call(needs[1],"getEffectiveId") end
    return "."
end

sgs.ai_skill_choice.taigyokunoyousei = function(self, choices, data)
	local current = data:toPlayer()
	local e_wounded = 0
	local f_wounded = 0
	if (__yuri_value_call(current,"getMark","&gomaoku_red") == 1 and __yuri_value_call(self.player,"getMark","&gomaoku_black") == 1) or (__yuri_value_call(current,"getMark","&gomaoku_black") == 1 and __yuri_value_call(self.player,"getMark","&gomaoku_red") == 1) then
		for _, friend in ipairs(self.friends) do
			if __yuri_value_call(friend,"isWounded") then f_wounded = f_wounded+1 end
		end
		for _, enemy in ipairs(self.enemies) do
			if __yuri_value_call(enemy,"isWounded") then e_wounded = e_wounded+1 end
		end
		for _ ,c in sgs.qlist(complete_hand(self,current)) do
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), current:objectName())
			if __yuri_value_call(c,"hasFlag","visible") or __yuri_value_call(c,"hasFlag",flag) then
				if self:isFriend(current) then
					if ((__yuri_value_call(c,"isKindOf","AOE") and #self.friends < #self.enemies) or (__yuri_value_call(c,"isKindOf","AmazingGrace") and #self.friends >= #self.enemies) or (__yuri_value_call(c,"isKindOf","GodSalvation") and f_wounded >= e_wounded)) and
					__yuri_value_call(c,"isAvailable",current) then
						return "change_goma"
					end
				elseif self:isEnemy(current) then
					if ((__yuri_value_call(c,"isKindOf","AOE") and #self.friends >= #self.enemies) or (__yuri_value_call(c,"isKindOf","AmazingGrace") and #self.friends < #self.enemies) or (__yuri_value_call(c,"isKindOf","GodSalvation") and f_wounded <= e_wounded)) and
					__yuri_value_call(c,"isAvailable",current) then
						return "change_goma"
					end
					if (__yuri_value_call(c,"isKindOf","Indulgence") and self:getOverflow() > 1) or ((__yuri_value_call(c,"isKindOf","SupplyShortage") or __yuri_value_call(c,"isKindOf","Snatch")) and __yuri_value_call(current,"distanceTo",self.player) == 1) or
					(__yuri_value_call(c,"isKindOf","Slash") and __yuri_value_call(current,"inMyAttackRange",self.player) and self:slashIsAvailable(current)) or ((__yuri_value_call(c,"isKindOf","Drowning") or __yuri_value_call(c,"isKindOf","Dismantlement")) and self.player:getCards("e"):length() > 0) or
					(__yuri_value_call(c,"isKindOf","FireAttack") and not self.player:isKongcheng() and self:isWeak(self.player)) then
						return "change_goma"
					end
				end

			end
		end
	end
	return "draw"
end

sgs.ai_fill_skill["gomaoku"] = function(self,inclusive,request)
	if self.player:hasUsed("#gomaoku") or __yuri_value_call(self.player,"getHandcardNum") < 2 then return end
	local enemy_same = 0
	local may_need_change = false
	local dont_change = true
	local f_same = 0
	local e_wounded = 0
	local f_wounded = 0
	if __yuri_value_call(self.player,"isWounded") then f_wounded = 1 end
	for _, enemy in ipairs(self.enemies) do
		if __yuri_value_call(enemy,"isWounded") then e_wounded = e_wounded+1 end
		if (__yuri_value_call(enemy,"getMark","&gomaoku_black") == 1 and __yuri_value_call(self.player,"getMark","&gomaoku_black") == 1) or (__yuri_value_call(enemy,"getMark","&gomaoku_red") == 1 and __yuri_value_call(self.player,"getMark","&gomaoku_red") == 1) then
			enemy_same = enemy_same+1
		end
		if (__yuri_value_call(enemy,"getMark","&gomaoku_red") == 1 and __yuri_value_call(self.player,"getMark","&gomaoku_black") == 1) or (__yuri_value_call(enemy,"getMark","&gomaoku_black") == 1 and __yuri_value_call(self.player,"getMark","&gomaoku_red") == 1) then
			if (__yuri_value_call(self.player,"inMyAttackRange",enemy) and self:getCardId("Slash") and self:slashIsAvailable(self.player)) or (self:getCardId("Snatch") and __yuri_value_call(self.player,"distanceTo",enemy) == 1) or
			(self:getCardId("Dismantlement") and (enemy:getArmor() or enemy:getWeapon() or enemy:getDefensiveHorse() or enemy:getOffensiveHorse())) then
				may_need_change = true
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if __yuri_value_call(friend,"isWounded") then f_wounded = f_wounded+1 end
		if (__yuri_value_call(friend,"getMark","&gomaoku_black") == 1 and __yuri_value_call(self.player,"getMark","&gomaoku_black") == 1) or (__yuri_value_call(friend,"getMark","&gomaoku_red") == 1 and __yuri_value_call(self.player,"getMark","&gomaoku_red") == 1) then
			f_same = f_same+1
		end
	end
	local n = 0
	for _ ,c in sgs.qlist(self.player:getHandcards()) do
        if ((__yuri_value_call(c,"isKindOf","AOE") and #self.friends_noself < #self.enemies) or (__yuri_value_call(c,"isKindOf","AmazingGrace") and #self.friends >= #self.enemies) or (__yuri_value_call(c,"isKindOf","GodSalvation") and f_wounded >= e_wounded)) and
		__yuri_value_call(c,"isAvailable",self.player) then
			n=n+1
		end
    end
    for _, id in sgs.qlist(self.player:getHandPile()) do
        local c = visible(self,id)
        if ((__yuri_value_call(c,"isKindOf","AOE") and #self.friends_noself < #self.enemies) or (__yuri_value_call(c,"isKindOf","AmazingGrace") and #self.friends >= #self.enemies) or (__yuri_value_call(c,"isKindOf","GodSalvation") and f_wounded >= e_wounded)) and
		__yuri_value_call(c,"isAvailable",self.player) then
			n=n+1
		end
    end
	if __yuri_value_call(self.player,"getHandcardNum") > 2 and n >= 2 and enemy_same >= f_same then return end
	if (enemy_same < f_same and __yuri_value_call(self.player,"getHandcardNum") > 2) or (__yuri_value_call(self.player,"getHandcardNum") > 1 and may_need_change) then
		local cards = sgs.QList2Table(self.player:getHandcards())
		if __yuri_value_call(self.player,"getPhase") == sgs.Player_NotActive then
			cards = self:sortByKeepValue(cards)
		else
			cards = self:sortByUseValue(cards)
		end
		local use_card
		for _,card in ipairs(cards) do
			if (card:isBlack() and __yuri_value_call(self.player,"getMark","&gomaoku_red") == 1) or (card:isRed() and __yuri_value_call(self.player,"getMark","&gomaoku_black") == 1) then
				use_card = card
				break
			end
		end
		if not use_card or __yuri_value_call(use_card,"isKindOf","Peach") then return end
		return policy(self,"#gomaoku:" .. use_card:getId().. ":")
	end
	return
end
sgs.ai_skill_use_func["#gomaoku"] = function(card, use, self)
	if card then
		use.card = card
	end
	return
end
sgs.ai_use_priority.gomaoku = sgs.ai_use_priority.ExNihilo + 1

local flyaway_skill = {} --借用火包園紹AI
sgs.ai_fill_skill["flyaway"] = function(self,inclusive,request)
	local first_found, second_found = false, false
	local first_card, second_card
	if __yuri_value_call(self.player,"getHandcardNum") >= 2 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)
		cards = self:sortByKeepValue(cards)

		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("Dongzhuxianji", fcard, self.player) or isCard("AmazingGrace", fcard, self.player) or isCard("GodSalvation", fcard, self.player))
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("Dongzhuxianji", scard, self.player) or isCard("AmazingGrace", fcard, self.player) or isCard("GodSalvation", fcard, self.player))
					if first_card ~= scard and scard:getColor() == first_card:getColor() and not svalueCard then
						local card_str
						if first_card:isBlack() then
							card_str = ("amazing_grace:flyaway[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						elseif first_card:isRed() then
							card_str = ("god_salvation:flyaway[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						end
						local aoe_card = policy(self,card_str)

						assert(aoe_card)

						local dummy_use = { isDummy = true }
						self:useTrickCard(aoe_card, dummy_use)
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
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str
		if first_card:isBlack() then
			card_str = ("amazing_grace:flyaway[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		elseif first_card:isRed() then
			card_str = ("god_salvation:flyaway[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		end
		local aoe_card = policy(self,card_str)
		assert(aoe_card)
		return aoe_card
	end
end
sgs.ai_use_priority["flyaway"] = sgs.ai_use_priority.AmazingGrace


sgs.ai_fill_skill["frankly"] = function(self,inclusive,request)
	self:updatePlayers()
	local tars = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not p:isKongcheng() then
			if not (self:isFriend(p) and __yuri_value_call(p,"getHandcardNum") > 3) then
				tars = tars + 1
			end
		end
	end
	if tars == 0 then return false end
	if (not self.player:hasUsed("#franklyCard")) then
		return policy(self,"#franklyCard:.:")
	end
end

sgs.ai_skill_use_func["#franklyCard"] = function(card, use, self)
	self.enemies = self:sort(self.enemies, "handcard")
	local targets = {}
	local best_target = nil

	for _, enemy in ipairs(self.enemies) do
		if not self:doDisCard(enemy, "hej") then continue end
		if __yuri_value_call(enemy,"getHandcardNum") > 6 then best_target = enemy break end
		table.insert(targets, enemy)
	end
	if not best_target and #targets == 0 then
		for _, friend in ipairs(self.friends_noself) do
			if self:doDisCard(friend, "hej") then
				table.insert(targets, friend)
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if self:canDraw(friend, self.player) then
				table.insert(targets, friend)
			end
		end
	end
	if best_target then
		use.card = policy(self,"#franklyCard:.:")
		if use.to then
			use.to:append(best_target)
		end
	elseif #targets > 0 then
		use.card = policy(self,"#franklyCard:.:")
		if use.to then
			use.to:append(targets[1])
		end
	end
	return
end

sgs.ai_use_value["franklyCard"] = 4
sgs.ai_use_priority["franklyCard"] = sgs.ai_use_priority.Dismantlement + 1


sgs.ai_skill_choice["frankly"] = function(self, choices, data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		return "discard"
	end
	if target and self:isFriend(target) then
		if self:doDisCard(target, "hej") then return "discard" end
		return "draw"
	end

	return "discard"
end

sgs.ai_skill_suit.frankly = function(self)
	local sus = {}
	for s,h in sgs.list(self.player:getHandcards())do
		s = __yuri_value_call(h,"getSuit")
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

local function need_flexible(self,who)
	local use = tag(self,"owner_flexible","CardUse")
	local card,from = use.card,use.from
	if self:isEnemy(who) then
		if __yuri_value_call(card,"isKindOf","GodSalvation") and __yuri_value_call(who,"isWounded") and __yuri_value_call(who,"getHp")<getBestHp(who) and self:hasTrickEffective(card,who,from) then
			return true
		end
		if __yuri_value_call(card,"isKindOf","ExNihilo") then return true end
		if __yuri_value_call(card,"isKindOf","Peach") then return true end
		return false
	elseif self:isFriend(who) then
		if __yuri_value_call(who,"hasSkill","noswuyan") and from:objectName()~=who:objectName() then return true end
		if __yuri_value_call(card,"isKindOf","GodSalvation") and not __yuri_value_call(who,"isWounded") then
			if hasManjuanEffect(who) then return false end
			if self:needKongcheng(who,true) then return false end
			return true
		end
		if __yuri_value_call(card,"isKindOf","GodSalvation") and __yuri_value_call(who,"isWounded") and self:hasTrickEffective(card,who,from) then
			if __yuri_value_call(who,"getHp")>getBestHp(who) and not self:needKongcheng(who,true) then return true end
			return false
		end
		if __yuri_value_call(card,"isKindOf","IronChain") and (self:needKongcheng(who,true) or (who:isChained() and self:hasTrickEffective(card,who,from))) then
			return false
		end
		if __yuri_value_call(card,"isKindOf","AmazingGrace") then return not self:hasTrickEffective(card,who,from) end
		if __yuri_value_call(card,"isKindOf","ExNihilo") then return false end
		if __yuri_value_call(card,"isKindOf","Peach") then return false end
		return true
	end
end
sgs.ai_skill_use["@@flexible"] = function(self, prompt)
    self:updatePlayers(true)
    local targets = {}
	self.enemies = self:sort(self.enemies, "defense")
	if __yuri_value_call(self.player,"hasSkill","flexible") then
		local use = room_tag(self,"flexible","CardUse")
		if __yuri_value_call(self.player,"getMark","friendlyTime") > 0 then
			local target_table = {}
			local use = tag(self,"owner_flexible","CardUse")
			for _,player in sgs.list(self.room:getAllPlayers())do
				if use.to:contains(player) and need_flexible(self,player) then
					table.insert(target_table,player:objectName())
					if #target_table==__yuri_value_call(self.player,"getMark","@defensive_distance_test") then break end
				end
			end
			if #target_table==0 then return "." end
			return "#flexible:.:->"..table.concat(target_table, "+")
		else
			local dummy_use = self:aiUseCard(use.card, dummy_plan(true, __yuri_value_call(self.player,"getMark","@defensive_distance_test"), use.to))
			if dummy_use and dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
				local tos = {}
				for _,p in sgs.list(dummy_use.to)do
					table.insert(tos,p:objectName())
				end
				return "#flexible:.:->"..table.concat(tos,"+")
			end
		end
	else
		if __yuri_value_call(self.player,"getMark","fake_flexible") == 0 then return nil end
		for _, p in ipairs(self.enemies) do
			table.insert(targets, p:objectName())
			if #targets >= __yuri_value_call(self.player,"getMark","fake_flexible") then break end
		end
		if #targets == 0 then return nil end
		return "#flexible:.:->"..table.concat(targets, "+")
	end
end

sgs.ai_skill_playerchosen.hb_konoyaiba_uketemiyo = function(self, targets)
	self:updatePlayers()
	local targets = {}
	local good_targets = {}
	self.enemies = self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if (__yuri_value_call(self.player,"inMyAttackRange",enemy) or (__yuri_value_call(self.player,"distanceTo",enemy) <= __yuri_value_call(self.player,"getHp") and not self.player:getWeapon())) and __yuri_value_call(self.player,"getHp") <= __yuri_value_call(enemy,"getHp") then
			if self:isWeak(enemy) then
				table.insert(good_targets, enemy)
			else
				table.insert(targets, enemy)
			end
		end
	end
	if #good_targets > 0 then return good_targets[1] end
	if #targets > 0 then return targets[1] end
	return nil
end
sgs.ai_playerchosen_intention["hb_konoyaiba_uketemiyo"] = function(self, from, to)
	self:updateIntention(from, to, 60)
end


sgs.ai_skill_invoke.nikuhei_k = function(self,data)
	local target = data:toPlayer()
	if self:isFriend(target) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.nikuhei_k = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
		if target then self:updateIntention(player, target, -50) end
	end
end













sgs.ai_skill_invoke.yuriKansen = function(self,data)
	local use = data:toCardUse()
	local dummy_use = self:aiUseCard(use.card, dummy_plan())
	if use.from and self:isFriend(use.from) and __yuri_value_call(use.card,"isKindOf","EquipCard") then return false end
	if dummy_use.card and dummy_use and dummy_use.to then
		return true
	end
	return false
end

sgs.ai_can_damagehp.yuriKansen = function(self,from,card,to)
	if from and __yuri_value_call(to,"getHp")+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) then
		return self:isEnemy(from) and __yuri_value_call(from,"getMark","&yuriKansen") == 0
	end
end

sgs.ai_guhuo_card.ov_jichou = function(self,toname,class_name)
	if __yuri_value_call(self.player,"getMark","ov_jichou_"..toname)<1
	and __yuri_value_call(self.player,"getMark","ov_jichou-Clear")<1 then
        local c = clone(self,toname)
		if c and c:isNDTrick() and self:getCardsNum(class_name)<1
	    then return "#ov_jichoucard:.:"..toname end
	end
end

sgs.ai_fill_skill.genshunoYURI = function(self)
    return policy(self,"#genshunoYURICard:.:")
end

sgs.ai_skill_use_func["#genshunoYURICard"] = function(card,use,self)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for c,h in sgs.list(cards)do
		for _,p in sgs.list(RandomList(copy(source_patterns(self))))do
			local dc = clone(self,p)
			if dc and (dc:isNDTrick() or __yuri_value_call(dc,"isKindOf","BasicCard")) and self:getCardsNum(__yuri_value_call(dc,"getClassName"))<1 then
				dc = mutate(self,dc,"skill","genshunoYURI")
				if __yuri_value_call(dc,"isAvailable",self.player) then
					local d = self:aiUseCard(dc)
					if d.card then
						use.card = policy(self,"#genshunoYURICard:".. __yuri_value_call(h,"getEffectiveId") ..":"..p)
						use.to = d.to
						self:copyNamedSourcePriority("genshunoYURICard",dc,__yuri_value_call(dc,"getClassName"))
                        self:readNamedSourcePriority("genshunoYURICard")
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_value.genshunoYURICard = 3.4
sgs.ai_use_priority.genshunoYURICard = 3.2

sgs.ai_guhuo_card.genshunoYURI = function(self,toname,class_name)
	local current = self.room:getCurrent()
	if ((known(self.request.reason,"response reason")==sgs.CardUseStruct_CARD_USE_REASON_PLAY or known(self.request.reason,"response reason")==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
	and current and __yuri_value_call(self.player,"getMark","genshunoYURI-".. __yuri_value_call(current,"getPhase").."Clear") == 0) or known(self.request.reason,"response reason")==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
	then
		local card = clone(self,toname)
		if card and (card:isNDTrick() or __yuri_value_call(card,"isKindOf","BasicCard")) and self:getCardsNum(class_name)<1  then
			local cards = self:addHandPile("he")
			cards = self:sortByKeepValue(cards,nil,true)
			return "#genshunoYURICard:"..__yuri_value_call(cards[1],"getEffectiveId")..":"..toname
		end
	end
end

sgs.ai_skill_invoke.machiko = function(self, data)
	local damage = data:toDamage()
    if self:damageIsEffective(damage.to,damage.card,damage.from) and not self:needToLoseHp(damage.to, damage.from, damage.card) then return true end
	return false
end


sgs.ai_fill_skill["clever"] = function(self,inclusive,request)
	if self.player:getPile("clevercards"):length() > 0 then
		local cardid = self.player:getPile("clevercards"):first()
		local cardname = visible(self,cardid):objectName()
		local cards = self:addHandPile("he")
		cards = self:sortByUseValue(cards,true)
		local use_card
		for _,card in ipairs(cards)  do
			if (self:getUseValue(card)<self:getUseValue(visible(self,cardid))) and self:getCardsNum(cardname)<1 then
				use_card = card
				break
			end
		end
		if use_card then
			local suit = __yuri_value_call(use_card,"getSuitString")
			local number = use_card:getNumberString()
			local card_id = __yuri_value_call(use_card,"getEffectiveId")
			local card_str = (cardname..":clever[%s:%s]=%d"):format(suit,number,card_id)
			local new_card = policy(self,card_str)
			assert(new_card)
			return new_card
		end
	else
	return policy(self,"#clever:.:")
	end
end


sgs.ai_skill_use_func["#clever"] = function(card, use, self)
	for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
		if (__yuri_value_call(c,"isKindOf","EquipCard") or __yuri_value_call(c,"isKindOf","Analeptic") or __yuri_value_call(c,"isKindOf","IronChain") or __yuri_value_call(c,"isKindOf","ExNihilo") or __yuri_value_call(c,"isKindOf","AmazingGrace") or __yuri_value_call(c,"isKindOf","Dongzhuxianji")) then continue end
		if table.contains(self:getPriorTurnUseCards(),c) or __yuri_value_call(c,"isKindOf","Peach") then
			use.card = policy(self,"#clever:" .. __yuri_value_call(c,"getEffectiveId") .. ":")
			return
		end
	end
end
sgs.ai_use_priority.clever = 10


sgs.ai_view_as.clever = function(card, player, card_place)
	local suit = __yuri_value_call(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = __yuri_value_call(card,"getEffectiveId")
	if player:getPile("clevercards"):isEmpty() then return nil end
	if __yuri_value_call(player,"getMark","@cleverkon") > 0 then return nil end
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		local cardid = player:getPile("clevercards"):first()
		local cardname = visible(self,cardid):objectName()
		if cardname then
			return (cardname..":clever[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end


sgs.ai_skill_cardask["@magicat"] = function(self,data)
	local currentplayer = self.room:getCurrent()
	local cards = self.player:getCards("h")
	cards = self:sortByUseValue(cards, true)
	for i,c in sgs.list(cards)do
		if self:doDisCard(currentplayer, "he") or (self:isFriend(currentplayer) and self:canDraw(currentplayer, self.player)) then
			return "$"..__yuri_value_call(c,"getEffectiveId")
		end
	end
	return "."
end

sgs.ai_skill_choice["magicat"] = function(self, choices, data)
	local items = choices:split("+")
	local currentplayer = data:toPlayer()
	if (self:isFriend(currentplayer) and self:canDraw(currentplayer, self.player)) then
		return "draw"
	end
	return "discard"
end
sgs.ai_choicemade_filter.skillChoice["magicat"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local currentplayer = self.room:getCurrent()
	if currentplayer then
		if choice == "discard" then
			self:updateIntention(player, currentplayer, 80)
		else
			self:updateIntention(player, currentplayer, -80)
		end
	end
end


sgs.ai_skill_invoke.magicat = function(self,data)
	local currentplayer = self.room:getCurrent()
	if self:isEnemy(currentplayer) then
		if self:doDisCard(currentplayer, "he", true) then
			return true
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.magicat = function(self,player,promptlist)
	local current = self.room:getCurrent()
	if current then
		local intention = 60
		if promptlist[3]=="yes" then
			if self:hasSkills(sgs.lose_equip_skill,current) and current:getCards("e"):length()>0 then intention = 0 end
			if self:needToThrowArmor(current) then return end
			if not self:hasLoseHandcardEffective(current)
			or (self:needToLoseHp(current))
			then intention = 0 end
			self:updateIntention(player,current,intention)
		end
	end
end

sgs.ai_fill_skill["Subetewonomikonmu"] = function(self,inclusive,request)
	if __yuri_value_call(self.player,"getMark","@wrath") < 7 then return nil end
	return policy(self,"#SubetewonomikonmuCard:.:")
end

function SmartAIView:canSaveSelf(player)
	if hasBuquEffect(player) then return true end
	if getCardsNum("Analeptic",player,self.player)>0 then return true end
	if player:hasSkills("jiushi|mobilejiushi") and __yuri_value_call(player,"faceUp") then return true end
	if player:hasSkills("jiuchi|mobilejiuchi|oljiuchi") then
		for _,c in sgs.list(complete_hand(self,player))do
			if __yuri_value_call(c,"getSuit")==sgs.Card_Spade then return true end
		end
	end
	return false
end

local function getSubetewonomikonmuUseValueOfHECards(self,to)
	local value = 0
	local value_h = 0
	local hcard = __yuri_value_call(to,"getHandcardNum")
	if __yuri_value_call(to,"hasSkill","lianying") then
		hcard = hcard-0.9
	elseif to:hasSkills("shangshi|nosshangshi") then
		hcard = hcard-0.9*__yuri_value_call(to,"getLostHp")
	else
		local jwfy = self.room:findPlayerBySkillName("shoucheng")
		if jwfy and self:isFriend(jwfy,to) and (not self:isWeak(jwfy) or __yuri_value_call(jwfy,"getHp")>1) then hcard = hcard-0.9 end
	end
	value_h = (hcard>4) and 16/hcard or hcard
	if hasTuntianEffect(to, true) then value = value*0.95 end
	if (__yuri_value_call(to,"hasSkill","kongcheng") or (__yuri_value_call(to,"hasSkill","zhiji") and __yuri_value_call(to,"getHp")>2 and __yuri_value_call(to,"getMark","zhiji")==0)) and not to:isKongcheng() then value_h = value_h*0.7 end
	if to:hasSkills("jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then value_h = value_h*0.95 end
	value = value+value_h

	local value_e = 0
	local equip_num = to:getEquips():length()
	if to:hasArmorEffect("SilverLion") and __yuri_value_call(to,"isWounded") then equip_num = equip_num-1.1 end
	value_e = equip_num*1.1
	if to:hasSkills("kofxiaoji|xiaoji") then value_e = value_e*0.7 end
	if __yuri_value_call(to,"hasSkill","nosxuanfeng") then value_e = value_e*0.85 end
	if to:hasSkills("bazhen|yizhong") and to:getArmor() then value_e = value_e-1 end
	value = value+value_e

	return value
end

local function getDangerousShenGuanYu(self)
	local most = -100
	local target
	for _,player in sgs.list(self.room:getAllPlayers())do
                local nm_mark = __yuri_value_call(player,"getMark","&nightmare")
		if player:objectName()==self.player:objectName() then nm_mark = nm_mark+1 end
		if nm_mark>0 and nm_mark>most or (nm_mark==most and self:isEnemy(player)) then
			most = nm_mark
			target = player
		end
	end
	if target and self:isEnemy(target) then return true end
	return false
end

sgs.ai_skill_use_func.SubetewonomikonmuCard = function(card,use,self)
	if (self.role=="loyalist" or self.role=="renegade") and self.room:getLord() and self:isWeak(self.room:getLord()) and not __yuri_value_call(self.player,"isLord") then return end
	local benefit = 0
	for _,player in sgs.list(self.room:getOtherPlayers(self.player))do
		if self:isFriend(player) then benefit = benefit-getSubetewonomikonmuUseValueOfHECards(self,player) end
		if self:isFriend(player) then benefit = benefit+getSubetewonomikonmuUseValueOfHECards(self,player) end
	end
	local friend_save_num = self:getSaveNum(true)
	local enemy_save_num = self:getSaveNum(false)
	local others = 0
	for _,player in sgs.list(self.room:getOtherPlayers(self.player))do
		if self:damageIsEffective(player,sgs.DamageStruct_Normal) then
			others = others+1
			local value_d = 3.5/math.max(__yuri_value_call(player,"getHp"),1)
			if __yuri_value_call(player,"getHp")<=1 then
				if __yuri_value_call(player,"hasSkill","wuhun") then
					local can_use = getDangerousShenGuanYu(self)
					if not can_use then return else value_d = value_d*0.1 end
				end
				if self:canSaveSelf(player) then
					value_d = value_d*0.9
				elseif self:isFriend(player) and friend_save_num>0 then
					friend_save_num = friend_save_num-1
					value_d = value_d*0.9
				elseif self:isEnemy(player) and enemy_save_num>0 then
					enemy_save_num = enemy_save_num-1
					value_d = value_d*0.9
				end
			end
			if __yuri_value_call(player,"hasSkill","fankui") then value_d = value_d*0.8 end
			if __yuri_value_call(player,"hasSkill","guixin") then
				if not __yuri_value_call(player,"faceUp") then
					value_d = value_d*0.4
				else
					value_d = value_d*0.8*(1.05-self.room:alivePlayerCount()/15)
				end
			end
			if self:needToLoseHp(player,self.player) or getBestHp(player)==__yuri_value_call(player,"getHp")-1 then value_d = value_d*0.8 end
			if self:isFriend(player) then benefit = benefit-value_d end
			if self:isEnemy(player) then benefit = benefit+value_d end
		end
	end
	if not __yuri_value_call(self.player,"faceUp") or self.player:hasSkills("jushou|nosjushou|neojushou|kuiwei") then
		benefit = benefit+1
	else
		local help_friend = false
		for _,friend in sgs.list(self.friends_noself)do
			if self:hasSkills("fangzhu|jilve",friend) then
				help_friend = true
				benefit = benefit+1
				break
			end
		end
		if not help_friend then benefit = benefit-0.5 end
	end
	if __yuri_value_call(self.player,"getKingdom")=="qun" then
		for _,player in sgs.list(self.room:getOtherPlayers(self.player))do
			if __yuri_value_call(player,"hasLordSkill","baonue") and self:isFriend(player) then
				benefit = benefit+0.2*self.room:alivePlayerCount()
				break
			end
		end
	end
	benefit = benefit+(others-7)*0.05
	if benefit>0 then
		use.card = card
	end
end

sgs.ai_use_value.SubetewonomikonmuCard = 8
sgs.ai_use_priority.SubetewonomikonmuCard = 5.3

sgs.dynamic_value.damage_card.SubetewonomikonmuCard = true
sgs.dynamic_value.control_card.SubetewonomikonmuCard = true

sgs.ai_fill_skill.acting = function(self)
    return policy(self,"#actingcard:.:")
end

sgs.ai_skill_use_func["#actingcard"] = function(card,use,self)

	use.card = card
	if use.to then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if math.random() < 0.5 then
				use.to:append(p)
				return
			end
		end
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if math.random() < 0.3 then
				use.to:append(p)
				return
			end
		end
	end
end

sgs.ai_use_value.actingcard = 3.4
sgs.ai_use_priority.actingcard = 10


sgs.ai_fill_skill.liketoplay = function(self)
    return policy(self,"#liketoplaycard:.:")
end

sgs.ai_skill_use_func["#liketoplaycard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.liketoplaycard = 3.4
sgs.ai_use_priority.liketoplaycard = 6


sgs.ai_card_priority.proficient = function(self,card,v)
	if self.useValue
	and __yuri_value_call(card,"isKindOf","TrickCard")
	then v = v+3 end
end


sgs.ai_fill_skill.endingchoice = function(self)
    return policy(self,"#endingchoiceCard:.:")
end

sgs.ai_skill_use_func["#endingchoiceCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.endingchoiceCard = 3.4
sgs.ai_use_priority.endingchoiceCard = 6

sgs.ai_skill_choice["sweetsis"] = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1,#items)]
end

sgs.ai_view_as.angel = function(card,player,card_place)
	if card_place~=sgs.Player_PlaceSpecial and __yuri_value_call(card,"getSuit") == sgs.Card_Heart then
		return ("peach:angel[%s:%s]=%d"):format(__yuri_value_call(card,"getSuitString"),card:getNumberString(),__yuri_value_call(card,"getEffectiveId"))
	end
end

sgs.angel_suit_value = {
	heart = 6,
	diamond = 6
}

sgs.ai_cardneed.angel = function(to,card)
	return card:isRed()
end

sgs.ai_fill_skill["angel"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards,true)
	for _,c in ipairs(cards)do
		if __yuri_value_call(c,"getSuit") == sgs.Card_Heart then
			return policy(self,"peach:angel[no_suit:0]="..__yuri_value_call(c,"getEffectiveId"))
		end
	end
end
sgs.ai_fill_skill["hidethepath"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards,true)
	for _,c in ipairs(cards)do
		if __yuri_value_call(c,"getSuit") == sgs.Card_Diamond then
			return policy(self,"snatch:hidethepath[no_suit:0]="..__yuri_value_call(c,"getEffectiveId"))
		end
	end
end

sgs.ai_fill_skill.dressing = function(self)
	if not self.player:canDiscard(self.player, "h") then return nil end
    return policy(self,"#dressing:.:")
end

sgs.ai_skill_use_func["#dressing"] = function(card,use,self)
	local hcards = self.player:getCards("h")
	hcards = sgs.QList2Table(hcards)
	hcards = self:sortByUseValue(hcards, true)
	sgs.ai_skill_invoke.peiqi(self)
    for _,target in sgs.list(self.room:getAlivePlayers())do
		if AIValue.sameLegacyIdentity(target,self:readPeiqiSourceField("from")) and target:getJudgingArea():length() <= 0 then
			use.card = policy(self,"#dressing:" .. hcards[1]:getId() .. ":")
			use.to:append(target)
			return
		end
	end
end

sgs.ai_skill_cardchosen.dressing = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		local id = __yuri_value_call(e,"getEffectiveId")
		if id==self:readPeiqiSourceField("cid")
		then return id end
	end
end

sgs.ai_skill_playerchosen.dressing = function(self,players)
    for _,target in sgs.list(players)do
		if AIValue.sameLegacyIdentity(target,self:readPeiqiSourceField("to"))
		then return target end
	end
    for _,target in sgs.list(players)do
        return target
    end
end

sgs.ai_use_value.dressing = 3.4
sgs.ai_use_priority.dressing = 2
local function wrap(f,key,kind)
 return function(...)
  local args=table.pack(...);local self
  for i=1,args.n do local v=args[i];if type(v)=="table"and v.player and v.world and v.request then self=v;break end end
  if not self then return f(...)end
  local outer=not self._yuri_callback_depth;local previous=self._yuri_callback_key
  self._yuri_callback_depth=(self._yuri_callback_depth or 0)+1;self._yuri_callback_key=key
  if outer then load_state(self)end
  if kind=="ai_skill_use_func"and classes[key]and args[1]and not recipes[args[1]]then recipes[args[1]]={prototype=key,skill=classes[key],subcards=copy(__yuri_value_call(args[1],"getSubcards")),user=__yuri_value_call(args[1],"getUserString")}end
  local result=table.pack(pcall(f,table.unpack(args,1,args.n)))
  local saved=outer and table.pack(pcall(save_state,self))or{true}
  self._yuri_callback_depth=self._yuri_callback_depth-1;if self._yuri_callback_depth==0 then self._yuri_callback_depth=nil end;self._yuri_callback_key=previous
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
sgs.ai_skill_invoke['LuaZhenlie']=wrap(sgs.ai_skill_invoke['LuaZhenlie'],'LuaZhenlie','ai_skill_invoke')
sgs.ai_ajustdamage_to['LuaZhenlie']=wrap(sgs.ai_ajustdamage_to['LuaZhenlie'],'LuaZhenlie','ai_ajustdamage_to')
sgs.ai_skill_choice['LuaZhenlie']=wrap(sgs.ai_skill_choice['LuaZhenlie'],'LuaZhenlie','ai_skill_choice')
sgs.ai_skill_choice['LuaRevenge']=wrap(sgs.ai_skill_choice['LuaRevenge'],'LuaRevenge','ai_skill_choice')
sgs.ai_cardneed['goddess_new']=wrap(sgs.ai_cardneed['goddess_new'],'goddess_new','ai_cardneed')
sgs.ai_skill_cardask['@goddess-put']=wrap(sgs.ai_skill_cardask['@goddess-put'],'@goddess-put','ai_skill_cardask')
sgs.ai_skill_askforag['clearthemeridians']=wrap(sgs.ai_skill_askforag['clearthemeridians'],'clearthemeridians','ai_skill_askforag')
sgs.ai_fill_skill['clearthemeridians']=wrap(sgs.ai_fill_skill['clearthemeridians'],'clearthemeridians','ai_fill_skill')
sgs.ai_skill_use_func['#clearthemeridians']=wrap(sgs.ai_skill_use_func['#clearthemeridians'],'#clearthemeridians','ai_skill_use_func')
do local f=sgs.ai_view_as['clearthemeridians'];sgs.ai_view_as['clearthemeridians']=function(...)return proposal(f(...))end end
sgs.ai_card_priority['clearthemeridians']=wrap(sgs.ai_card_priority['clearthemeridians'],'clearthemeridians','ai_card_priority')
sgs.ai_skill_choice['clearthemeridians']=wrap(sgs.ai_skill_choice['clearthemeridians'],'clearthemeridians','ai_skill_choice')
sgs.ai_skill_use['@@clearthemeridians_fc']=wrap(sgs.ai_skill_use['@@clearthemeridians_fc'],'@@clearthemeridians_fc','ai_skill_use')
sgs.ai_skill_invoke['semeruki']=wrap(sgs.ai_skill_invoke['semeruki'],'semeruki','ai_skill_invoke')
sgs.ai_skill_cardchosen['semeruki']=wrap(sgs.ai_skill_cardchosen['semeruki'],'semeruki','ai_skill_cardchosen')
sgs.ai_skill_playerchosen['reedship']=wrap(sgs.ai_skill_playerchosen['reedship'],'reedship','ai_skill_playerchosen')
sgs.ai_skill_invoke['reedship']=wrap(sgs.ai_skill_invoke['reedship'],'reedship','ai_skill_invoke')
sgs.ai_skill_use['@@reedship']=wrap(sgs.ai_skill_use['@@reedship'],'@@reedship','ai_skill_use')
sgs.ai_playerchosen_intention['reedship']=wrap(sgs.ai_playerchosen_intention['reedship'],'reedship','ai_playerchosen_intention')
sgs.ai_fill_skill['phantom']=wrap(sgs.ai_fill_skill['phantom'],'phantom','ai_fill_skill')
sgs.ai_skill_use_func['#phantom']=wrap(sgs.ai_skill_use_func['#phantom'],'#phantom','ai_skill_use_func')
sgs.ai_skill_cardask['@phantomask']=wrap(sgs.ai_skill_cardask['@phantomask'],'@phantomask','ai_skill_cardask')
sgs.ai_fill_skill['goodatwep']=wrap(sgs.ai_fill_skill['goodatwep'],'goodatwep','ai_fill_skill')
sgs.ai_skill_use_func['#goodatwep']=wrap(sgs.ai_skill_use_func['#goodatwep'],'#goodatwep','ai_skill_use_func')
sgs.ai_skill_cardchosen['goodatwep']=wrap(sgs.ai_skill_cardchosen['goodatwep'],'goodatwep','ai_skill_cardchosen')
sgs.ai_skill_choice['goodatwep']=wrap(sgs.ai_skill_choice['goodatwep'],'goodatwep','ai_skill_choice')
sgs.ai_card_intention['goodatwep']=wrap(sgs.ai_card_intention['goodatwep'],'goodatwep','ai_card_intention')
sgs.ai_fill_skill['helptheweak']=wrap(sgs.ai_fill_skill['helptheweak'],'helptheweak','ai_fill_skill')
sgs.ai_skill_use_func['#helptheweak']=wrap(sgs.ai_skill_use_func['#helptheweak'],'#helptheweak','ai_skill_use_func')
sgs.ai_fill_skill['changesexual']=wrap(sgs.ai_fill_skill['changesexual'],'changesexual','ai_fill_skill')
sgs.ai_skill_use_func['#changesexual']=wrap(sgs.ai_skill_use_func['#changesexual'],'#changesexual','ai_skill_use_func')
sgs.ai_fill_skill['sexualadvantage']=wrap(sgs.ai_fill_skill['sexualadvantage'],'sexualadvantage','ai_fill_skill')
do local f=sgs.ai_view_as['sexualadvantage'];sgs.ai_view_as['sexualadvantage']=function(...)return proposal(f(...))end end
sgs.ai_cardneed['sexualadvantage']=wrap(sgs.ai_cardneed['sexualadvantage'],'sexualadvantage','ai_cardneed')
sgs.ai_skill_invoke['tomowodaji']=wrap(sgs.ai_skill_invoke['tomowodaji'],'tomowodaji','ai_skill_invoke')
sgs.ai_ajustdamage_from['japenknifejile']=wrap(sgs.ai_ajustdamage_from['japenknifejile'],'japenknifejile','ai_ajustdamage_from')
sgs.ai_skill_invoke['japenknifejile']=wrap(sgs.ai_skill_invoke['japenknifejile'],'japenknifejile','ai_skill_invoke')
sgs.ai_skill_invoke['skeleton']=wrap(sgs.ai_skill_invoke['skeleton'],'skeleton','ai_skill_invoke')
sgs.ai_skill_cardask['@skeleton']=wrap(sgs.ai_skill_cardask['@skeleton'],'@skeleton','ai_skill_cardask')
sgs.ai_target_revises['skeleton']=wrap(sgs.ai_target_revises['skeleton'],'skeleton','ai_target_revises')
sgs.ai_skill_invoke['strangeguy']=wrap(sgs.ai_skill_invoke['strangeguy'],'strangeguy','ai_skill_invoke')
sgs.ai_fill_skill['tobenature']=wrap(sgs.ai_fill_skill['tobenature'],'tobenature','ai_fill_skill')
sgs.ai_skill_use_func['#tobenature']=wrap(sgs.ai_skill_use_func['#tobenature'],'#tobenature','ai_skill_use_func')
sgs.ai_card_intention['tobenature']=wrap(sgs.ai_card_intention['tobenature'],'tobenature','ai_card_intention')
sgs.ai_skill_cardask['@tobenatureAsk']=wrap(sgs.ai_skill_cardask['@tobenatureAsk'],'@tobenatureAsk','ai_skill_cardask')
sgs.ai_skill_invoke['zerodifference']=wrap(sgs.ai_skill_invoke['zerodifference'],'zerodifference','ai_skill_invoke')
sgs.ai_skill_use['@@heapridge']=wrap(sgs.ai_skill_use['@@heapridge'],'@@heapridge','ai_skill_use')
sgs.ai_ajustdamage_from['lovesong']=wrap(sgs.ai_ajustdamage_from['lovesong'],'lovesong','ai_ajustdamage_from')
sgs.ai_skill_invoke['loyalm']=wrap(sgs.ai_skill_invoke['loyalm'],'loyalm','ai_skill_invoke')
sgs.ai_skill_cardchosen['loyalm']=wrap(sgs.ai_skill_cardchosen['loyalm'],'loyalm','ai_skill_cardchosen')
sgs.ai_skill_playerchosen['loyalm']=wrap(sgs.ai_skill_playerchosen['loyalm'],'loyalm','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['loyalm']=wrap(sgs.ai_playerchosen_intention['loyalm'],'loyalm','ai_playerchosen_intention')
sgs.ai_can_damagehp['loyalm']=wrap(sgs.ai_can_damagehp['loyalm'],'loyalm','ai_can_damagehp')
sgs.ai_getLeastHandcardNum_skill['scoopthemoonup']=wrap(sgs.ai_getLeastHandcardNum_skill['scoopthemoonup'],'scoopthemoonup','ai_getLeastHandcardNum_skill')
sgs.ai_skill_invoke['deterrence']=wrap(sgs.ai_skill_invoke['deterrence'],'deterrence','ai_skill_invoke')
sgs.ai_skill_invoke['wannawin']=wrap(sgs.ai_skill_invoke['wannawin'],'wannawin','ai_skill_invoke')
sgs.ai_fill_skill['wannawin']=wrap(sgs.ai_fill_skill['wannawin'],'wannawin','ai_fill_skill')
sgs.ai_skill_use_func['#wannawin']=wrap(sgs.ai_skill_use_func['#wannawin'],'#wannawin','ai_skill_use_func')
sgs.ai_skill_cardchosen['wannawin']=wrap(sgs.ai_skill_cardchosen['wannawin'],'wannawin','ai_skill_cardchosen')
sgs.ai_card_intention['wannawin']=wrap(sgs.ai_card_intention['wannawin'],'wannawin','ai_card_intention')
sgs.ai_card_priority['theace']=wrap(sgs.ai_card_priority['theace'],'theace','ai_card_priority')
sgs.ai_skill_invoke['hotfight']=wrap(sgs.ai_skill_invoke['hotfight'],'hotfight','ai_skill_invoke')
sgs.ai_fill_skill['hotfight']=wrap(sgs.ai_fill_skill['hotfight'],'hotfight','ai_fill_skill')
sgs.ai_cardsview['hotfight']=wrap(sgs.ai_cardsview['hotfight'],'hotfight','ai_cardsview')
sgs.ai_playerchosen_intention['iris']=wrap(sgs.ai_playerchosen_intention['iris'],'iris','ai_playerchosen_intention')
sgs.ai_card_intention['dressing']=wrap(sgs.ai_card_intention['dressing'],'dressing','ai_card_intention')
sgs.ai_playerchosen_intention['dressing']=wrap(sgs.ai_playerchosen_intention['dressing'],'dressing','ai_playerchosen_intention')
sgs.ai_skill_cardask['@zhixi']=wrap(sgs.ai_skill_cardask['@zhixi'],'@zhixi','ai_skill_cardask')
sgs.ai_skill_playerchosen['zhixi']=wrap(sgs.ai_skill_playerchosen['zhixi'],'zhixi','ai_skill_playerchosen')
sgs.ai_skill_choice['zhixi']=wrap(sgs.ai_skill_choice['zhixi'],'zhixi','ai_skill_choice')
sgs.ai_cardneed['zhixi']=wrap(sgs.ai_cardneed['zhixi'],'zhixi','ai_cardneed')
sgs.ai_can_damagehp['zhixi']=wrap(sgs.ai_can_damagehp['zhixi'],'zhixi','ai_can_damagehp')
sgs.ai_skill_invoke['yuejian']=wrap(sgs.ai_skill_invoke['yuejian'],'yuejian','ai_skill_invoke')
sgs.ai_fill_skill['turned']=wrap(sgs.ai_fill_skill['turned'],'turned','ai_fill_skill')
sgs.ai_skill_use_func['#turned']=wrap(sgs.ai_skill_use_func['#turned'],'#turned','ai_skill_use_func')
sgs.ai_skill_invoke['bffeedingpoisoning']=wrap(sgs.ai_skill_invoke['bffeedingpoisoning'],'bffeedingpoisoning','ai_skill_invoke')
sgs.ai_can_damagehp['newmember']=wrap(sgs.ai_can_damagehp['newmember'],'newmember','ai_can_damagehp')
sgs.ai_playerchosen_intention['newmember']=wrap(sgs.ai_playerchosen_intention['newmember'],'newmember','ai_playerchosen_intention')
sgs.ai_skill_invoke['introvert']=wrap(sgs.ai_skill_invoke['introvert'],'introvert','ai_skill_invoke')
sgs.ai_skill_invoke['yuriganglie']=wrap(sgs.ai_skill_invoke['yuriganglie'],'yuriganglie','ai_skill_invoke')
sgs.ai_skill_cardchosen['yuriganglie']=wrap(sgs.ai_skill_cardchosen['yuriganglie'],'yuriganglie','ai_skill_cardchosen')
sgs.ai_need_damaged['fightingexper']=wrap(sgs.ai_need_damaged['fightingexper'],'fightingexper','ai_need_damaged')
sgs.ai_need_damaged['yuriganglie']=wrap(sgs.ai_need_damaged['yuriganglie'],'yuriganglie','ai_need_damaged')
sgs.ai_fill_skill['fightingclimax']=wrap(sgs.ai_fill_skill['fightingclimax'],'fightingclimax','ai_fill_skill')
sgs.ai_skill_use_func['#fightingclimax']=wrap(sgs.ai_skill_use_func['#fightingclimax'],'#fightingclimax','ai_skill_use_func')
sgs.ai_fill_skill['witty']=wrap(sgs.ai_fill_skill['witty'],'witty','ai_fill_skill')
sgs.ai_skill_use_func['#witty']=wrap(sgs.ai_skill_use_func['#witty'],'#witty','ai_skill_use_func')
sgs.ai_card_intention['witty']=wrap(sgs.ai_card_intention['witty'],'witty','ai_card_intention')
sgs.ai_playerchosen_intention['witty']=wrap(sgs.ai_playerchosen_intention['witty'],'witty','ai_playerchosen_intention')
sgs.ai_skill_playerchosen['witty']=wrap(sgs.ai_skill_playerchosen['witty'],'witty','ai_skill_playerchosen')
sgs.ai_skill_invoke['LuaJTieji']=wrap(sgs.ai_skill_invoke['LuaJTieji'],'LuaJTieji','ai_skill_invoke')
sgs.ai_skill_cardask['@luajtieji-discard']=wrap(sgs.ai_skill_cardask['@luajtieji-discard'],'@luajtieji-discard','ai_skill_cardask')
sgs.ai_skill_use['@@thedolls']=wrap(sgs.ai_skill_use['@@thedolls'],'@@thedolls','ai_skill_use')
sgs.ai_skill_cardchosen['thedolls']=wrap(sgs.ai_skill_cardchosen['thedolls'],'thedolls','ai_skill_cardchosen')
sgs.ai_card_intention['thedolls']=wrap(sgs.ai_card_intention['thedolls'],'thedolls','ai_card_intention')
sgs.ai_cardneed['yuri_xueji']=wrap(sgs.ai_cardneed['yuri_xueji'],'yuri_xueji','ai_cardneed')
sgs.ai_fill_skill['yuri_xueji']=wrap(sgs.ai_fill_skill['yuri_xueji'],'yuri_xueji','ai_fill_skill')
sgs.ai_skill_use_func['#yuri_xueji']=wrap(sgs.ai_skill_use_func['#yuri_xueji'],'#yuri_xueji','ai_skill_use_func')
sgs.ai_card_intention['yuri_xueji']=wrap(sgs.ai_card_intention['yuri_xueji'],'yuri_xueji','ai_card_intention')
do local f=sgs.ai_view_as['yuri_wuji'];sgs.ai_view_as['yuri_wuji']=function(...)return proposal(f(...))end end
sgs.ai_fill_skill['yuri_wuji']=wrap(sgs.ai_fill_skill['yuri_wuji'],'yuri_wuji','ai_fill_skill')
sgs.ai_skill_playerchosen['ys_huairou']=wrap(sgs.ai_skill_playerchosen['ys_huairou'],'ys_huairou','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['ys_huairou']=wrap(sgs.ai_playerchosen_intention['ys_huairou'],'ys_huairou','ai_playerchosen_intention')
sgs.ai_fill_skill['ys_jueyan']=wrap(sgs.ai_fill_skill['ys_jueyan'],'ys_jueyan','ai_fill_skill')
sgs.ai_skill_use_func['#ys_jueyan']=wrap(sgs.ai_skill_use_func['#ys_jueyan'],'#ys_jueyan','ai_skill_use_func')
sgs.ai_skill_discard['likebooks']=wrap(sgs.ai_skill_discard['likebooks'],'likebooks','ai_skill_discard')
sgs.ai_skill_choice['likebooks']=wrap(sgs.ai_skill_choice['likebooks'],'likebooks','ai_skill_choice')
sgs.ai_skill_invoke['happinesstoeveryone']=wrap(sgs.ai_skill_invoke['happinesstoeveryone'],'happinesstoeveryone','ai_skill_invoke')
sgs.ai_ajustdamage_to['bloody']=wrap(sgs.ai_ajustdamage_to['bloody'],'bloody','ai_ajustdamage_to')
sgs.ai_skill_invoke['blooddry']=wrap(sgs.ai_skill_invoke['blooddry'],'blooddry','ai_skill_invoke')
sgs.ai_canliegong_skill['blooddry']=wrap(sgs.ai_canliegong_skill['blooddry'],'blooddry','ai_canliegong_skill')
sgs.ai_fill_skill['suckblood']=wrap(sgs.ai_fill_skill['suckblood'],'suckblood','ai_fill_skill')
sgs.ai_cardsview['suckblood']=wrap(sgs.ai_cardsview['suckblood'],'suckblood','ai_cardsview')
sgs.ai_skill_invoke['suckblood']=wrap(sgs.ai_skill_invoke['suckblood'],'suckblood','ai_skill_invoke')
sgs.ai_skill_invoke['yuri_jianchu']=wrap(sgs.ai_skill_invoke['yuri_jianchu'],'yuri_jianchu','ai_skill_invoke')
sgs.ai_skill_playerchosen['yuri_liangyin']=wrap(sgs.ai_skill_playerchosen['yuri_liangyin'],'yuri_liangyin','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['yuri_liangyin']=wrap(sgs.ai_playerchosen_intention['yuri_liangyin'],'yuri_liangyin','ai_playerchosen_intention')
sgs.ai_skill_use['@yuri_kongsheng']=wrap(sgs.ai_skill_use['@yuri_kongsheng'],'@yuri_kongsheng','ai_skill_use')
sgs.ai_skill_playerchosen['yuri_kongsheng']=wrap(sgs.ai_skill_playerchosen['yuri_kongsheng'],'yuri_kongsheng','ai_skill_playerchosen')
sgs.ai_skill_invoke['protectdestroy']=wrap(sgs.ai_skill_invoke['protectdestroy'],'protectdestroy','ai_skill_invoke')
sgs.ai_fill_skill['married']=wrap(sgs.ai_fill_skill['married'],'married','ai_fill_skill')
sgs.ai_skill_use_func['#married']=wrap(sgs.ai_skill_use_func['#married'],'#married','ai_skill_use_func')
sgs.ai_card_intention['married']=wrap(sgs.ai_card_intention['married'],'married','ai_card_intention')
sgs.ai_fill_skill['meleemaster']=wrap(sgs.ai_fill_skill['meleemaster'],'meleemaster','ai_fill_skill')
do local f=sgs.ai_view_as['meleemaster'];sgs.ai_view_as['meleemaster']=function(...)return proposal(f(...))end end
sgs.ai_can_damagehp['tacitunderstanding']=wrap(sgs.ai_can_damagehp['tacitunderstanding'],'tacitunderstanding','ai_can_damagehp')
sgs.ai_fill_skill['weareidle']=wrap(sgs.ai_fill_skill['weareidle'],'weareidle','ai_fill_skill')
sgs.ai_skill_use_func['#weareidle']=wrap(sgs.ai_skill_use_func['#weareidle'],'#weareidle','ai_skill_use_func')
sgs.ai_skill_cardchosen['weareidle']=wrap(sgs.ai_skill_cardchosen['weareidle'],'weareidle','ai_skill_cardchosen')
sgs.ai_skill_invoke['solidarity']=wrap(sgs.ai_skill_invoke['solidarity'],'solidarity','ai_skill_invoke')
sgs.ai_skill_discard['listentonature']=wrap(sgs.ai_skill_discard['listentonature'],'listentonature','ai_skill_discard')
sgs.ai_skill_invoke['migonoinori']=wrap(sgs.ai_skill_invoke['migonoinori'],'migonoinori','ai_skill_invoke')
sgs.ai_skill_invoke['imwatching']=wrap(sgs.ai_skill_invoke['imwatching'],'imwatching','ai_skill_invoke')
sgs.ai_skill_cardask['@imwatching']=wrap(sgs.ai_skill_cardask['@imwatching'],'@imwatching','ai_skill_cardask')
sgs.ai_skill_cardask['@bougairensha']=wrap(sgs.ai_skill_cardask['@bougairensha'],'@bougairensha','ai_skill_cardask')
sgs.ai_cardneed['bougairensha']=wrap(sgs.ai_cardneed['bougairensha'],'bougairensha','ai_cardneed')
sgs.ai_skill_invoke['sizukana']=wrap(sgs.ai_skill_invoke['sizukana'],'sizukana','ai_skill_invoke')
sgs.ai_skill_playerchosen['sizukana']=wrap(sgs.ai_skill_playerchosen['sizukana'],'sizukana','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['sizukana']=wrap(sgs.ai_playerchosen_intention['sizukana'],'sizukana','ai_playerchosen_intention')
sgs.ai_fill_skill['hononozouki']=wrap(sgs.ai_fill_skill['hononozouki'],'hononozouki','ai_fill_skill')
sgs.ai_skill_use_func['#hononozouki']=wrap(sgs.ai_skill_use_func['#hononozouki'],'#hononozouki','ai_skill_use_func')
sgs.ai_skill_invoke['hononochikara']=wrap(sgs.ai_skill_invoke['hononochikara'],'hononochikara','ai_skill_invoke')
sgs.ai_can_damagehp['moekogoro']=wrap(sgs.ai_can_damagehp['moekogoro'],'moekogoro','ai_can_damagehp')
sgs.ai_ajustdamage_to['moekogoro']=wrap(sgs.ai_ajustdamage_to['moekogoro'],'moekogoro','ai_ajustdamage_to')
sgs.ai_skill_cardask['@wisdom-card']=wrap(sgs.ai_skill_cardask['@wisdom-card'],'@wisdom-card','ai_skill_cardask')
sgs.ai_cardneed['wisdom_s']=wrap(sgs.ai_cardneed['wisdom_s'],'wisdom_s','ai_cardneed')
sgs.ai_target_revises['yochi']=wrap(sgs.ai_target_revises['yochi'],'yochi','ai_target_revises')
sgs.ai_fill_skill['yomi']=wrap(sgs.ai_fill_skill['yomi'],'yomi','ai_fill_skill')
sgs.ai_skill_use_func['#yomi']=wrap(sgs.ai_skill_use_func['#yomi'],'#yomi','ai_skill_use_func')
sgs.ai_fill_skill['kanchi']=wrap(sgs.ai_fill_skill['kanchi'],'kanchi','ai_fill_skill')
sgs.ai_skill_use_func['#kanchi']=wrap(sgs.ai_skill_use_func['#kanchi'],'#kanchi','ai_skill_use_func')
sgs.ai_skill_invoke['yuri_guixin']=wrap(sgs.ai_skill_invoke['yuri_guixin'],'yuri_guixin','ai_skill_invoke')
sgs.ai_skill_choice['yuri_guixin']=wrap(sgs.ai_skill_choice['yuri_guixin'],'yuri_guixin','ai_skill_choice')
sgs.ai_skill_cardchosen['yuri_guixin']=wrap(sgs.ai_skill_cardchosen['yuri_guixin'],'yuri_guixin','ai_skill_cardchosen')
sgs.ai_fill_skill['barakurosaku']=wrap(sgs.ai_fill_skill['barakurosaku'],'barakurosaku','ai_fill_skill')
sgs.ai_skill_use_func['#barakurosaku']=wrap(sgs.ai_skill_use_func['#barakurosaku'],'#barakurosaku','ai_skill_use_func')
sgs.ai_card_intention['barakurosaku']=wrap(sgs.ai_card_intention['barakurosaku'],'barakurosaku','ai_card_intention')
sgs.ai_skill_invoke['kanshi']=wrap(sgs.ai_skill_invoke['kanshi'],'kanshi','ai_skill_invoke')
sgs.ai_skill_invoke['kanshi_dis']=wrap(sgs.ai_skill_invoke['kanshi_dis'],'kanshi_dis','ai_skill_invoke')
sgs.ai_skill_cardchosen['kanshi']=wrap(sgs.ai_skill_cardchosen['kanshi'],'kanshi','ai_skill_cardchosen')
sgs.ai_skill_playerchosen['genjutsu']=wrap(sgs.ai_skill_playerchosen['genjutsu'],'genjutsu','ai_skill_playerchosen')
sgs.ai_use_revises['genjutsu']=wrap(sgs.ai_use_revises['genjutsu'],'genjutsu','ai_use_revises')
sgs.ai_playerchosen_intention['tsuyoiishiki']=wrap(sgs.ai_playerchosen_intention['tsuyoiishiki'],'tsuyoiishiki','ai_playerchosen_intention')
sgs.ai_skill_playerchosen['tsuyoiishiki']=wrap(sgs.ai_skill_playerchosen['tsuyoiishiki'],'tsuyoiishiki','ai_skill_playerchosen')
do local f=sgs.ai_view_as['countertrick'];sgs.ai_view_as['countertrick']=function(...)return proposal(f(...))end end
sgs.ai_card_priority['countertrick']=wrap(sgs.ai_card_priority['countertrick'],'countertrick','ai_card_priority')
sgs.ai_fill_skill['unlock']=wrap(sgs.ai_fill_skill['unlock'],'unlock','ai_fill_skill')
sgs.ai_skill_use_func['#unlock']=wrap(sgs.ai_skill_use_func['#unlock'],'#unlock','ai_skill_use_func')
sgs.ai_fill_skill['peeking']=wrap(sgs.ai_fill_skill['peeking'],'peeking','ai_fill_skill')
sgs.ai_skill_use_func['#peeking']=wrap(sgs.ai_skill_use_func['#peeking'],'#peeking','ai_skill_use_func')
sgs.ai_skill_choice['peeking']=wrap(sgs.ai_skill_choice['peeking'],'peeking','ai_skill_choice')
sgs.ai_skill_cardchosen['peeking']=wrap(sgs.ai_skill_cardchosen['peeking'],'peeking','ai_skill_cardchosen')
sgs.ai_skill_invoke['songforatsu']=wrap(sgs.ai_skill_invoke['songforatsu'],'songforatsu','ai_skill_invoke')
sgs.ai_skill_invoke['lovetoevo']=wrap(sgs.ai_skill_invoke['lovetoevo'],'lovetoevo','ai_skill_invoke')
sgs.ai_fill_skill['buuzetsu']=wrap(sgs.ai_fill_skill['buuzetsu'],'buuzetsu','ai_fill_skill')
do local f=sgs.ai_view_as['buuzetsu'];sgs.ai_view_as['buuzetsu']=function(...)return proposal(f(...))end end
sgs.ai_ajustdamage_to['buuzetsu']=wrap(sgs.ai_ajustdamage_to['buuzetsu'],'buuzetsu','ai_ajustdamage_to')
sgs.ai_fill_skill['zurunoonkaeshi']=wrap(sgs.ai_fill_skill['zurunoonkaeshi'],'zurunoonkaeshi','ai_fill_skill')
sgs.ai_skill_use_func['#zurunoonkaeshi']=wrap(sgs.ai_skill_use_func['#zurunoonkaeshi'],'#zurunoonkaeshi','ai_skill_use_func')
sgs.ai_skill_choice['zurunoonkaeshi']=wrap(sgs.ai_skill_choice['zurunoonkaeshi'],'zurunoonkaeshi','ai_skill_choice')
sgs.ai_skill_invoke['haigu']=wrap(sgs.ai_skill_invoke['haigu'],'haigu','ai_skill_invoke')
sgs.ai_skill_use['@@haigu']=wrap(sgs.ai_skill_use['@@haigu'],'@@haigu','ai_skill_use')
sgs.ai_skill_playerchosen['haigu']=wrap(sgs.ai_skill_playerchosen['haigu'],'haigu','ai_skill_playerchosen')
sgs.ai_skill_cardchosen['haigu']=wrap(sgs.ai_skill_cardchosen['haigu'],'haigu','ai_skill_cardchosen')
sgs.ai_skill_invoke['kirisou']=wrap(sgs.ai_skill_invoke['kirisou'],'kirisou','ai_skill_invoke')
sgs.ai_skill_cardchosen['kirisou']=wrap(sgs.ai_skill_cardchosen['kirisou'],'kirisou','ai_skill_cardchosen')
sgs.ai_skill_choice['kirisou']=wrap(sgs.ai_skill_choice['kirisou'],'kirisou','ai_skill_choice')
sgs.ai_fill_skill['gopugu']=wrap(sgs.ai_fill_skill['gopugu'],'gopugu','ai_fill_skill')
sgs.ai_skill_use_func['#gopugu']=wrap(sgs.ai_skill_use_func['#gopugu'],'#gopugu','ai_skill_use_func')
sgs.ai_skill_discard['kirisou_umaretuski']=wrap(sgs.ai_skill_discard['kirisou_umaretuski'],'kirisou_umaretuski','ai_skill_discard')
do local f=sgs.ai_view_as['yuri_hagaku'];sgs.ai_view_as['yuri_hagaku']=function(...)return proposal(f(...))end end
sgs.ai_cardneed['yuri_hagaku']=wrap(sgs.ai_cardneed['yuri_hagaku'],'yuri_hagaku','ai_cardneed')
sgs.ai_skill_invoke['yuri_hagaku']=wrap(sgs.ai_skill_invoke['yuri_hagaku'],'yuri_hagaku','ai_skill_invoke')
sgs.ai_fill_skill['new_againstdis']=wrap(sgs.ai_fill_skill['new_againstdis'],'new_againstdis','ai_fill_skill')
sgs.ai_skill_use_func['#new_againstdis']=wrap(sgs.ai_skill_use_func['#new_againstdis'],'#new_againstdis','ai_skill_use_func')
sgs.ai_target_revises['helmet']=wrap(sgs.ai_target_revises['helmet'],'helmet','ai_target_revises')
sgs.ai_skill_use['@@hunnshin']=wrap(sgs.ai_skill_use['@@hunnshin'],'@@hunnshin','ai_skill_use')
sgs.ai_card_intention['hunnshin']=wrap(sgs.ai_card_intention['hunnshin'],'hunnshin','ai_card_intention')
sgs.ai_skill_choice['tennsainohojyou']=wrap(sgs.ai_skill_choice['tennsainohojyou'],'tennsainohojyou','ai_skill_choice')
sgs.ai_skill_cardchosen['tennsainohojyou']=wrap(sgs.ai_skill_cardchosen['tennsainohojyou'],'tennsainohojyou','ai_skill_cardchosen')
sgs.ai_skill_invoke['jiyuunokuni']=wrap(sgs.ai_skill_invoke['jiyuunokuni'],'jiyuunokuni','ai_skill_invoke')
sgs.ai_skill_invoke['yuryounowaku']=wrap(sgs.ai_skill_invoke['yuryounowaku'],'yuryounowaku','ai_skill_invoke')
sgs.ai_skill_discard['yurimi']=wrap(sgs.ai_skill_discard['yurimi'],'yurimi','ai_skill_discard')
sgs.ai_skill_use['@@yurimi']=wrap(sgs.ai_skill_use['@@yurimi'],'@@yurimi','ai_skill_use')
sgs.ai_skill_invoke['yurimi']=wrap(sgs.ai_skill_invoke['yurimi'],'yurimi','ai_skill_invoke')
sgs.ai_skill_playerchosen['yuri_hengjiang']=wrap(sgs.ai_skill_playerchosen['yuri_hengjiang'],'yuri_hengjiang','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['yuri_hengjiang']=wrap(sgs.ai_playerchosen_intention['yuri_hengjiang'],'yuri_hengjiang','ai_playerchosen_intention')
sgs.ai_fill_skill['kurashinfurashu']=wrap(sgs.ai_fill_skill['kurashinfurashu'],'kurashinfurashu','ai_fill_skill')
sgs.ai_skill_use_func['#kurashinfurashu']=wrap(sgs.ai_skill_use_func['#kurashinfurashu'],'#kurashinfurashu','ai_skill_use_func')
sgs.ai_skill_playerchosen['kurashinfurashu']=wrap(sgs.ai_skill_playerchosen['kurashinfurashu'],'kurashinfurashu','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['kurashinfurashu']=wrap(sgs.ai_playerchosen_intention['kurashinfurashu'],'kurashinfurashu','ai_playerchosen_intention')
sgs.ai_skill_invoke['arkora']=wrap(sgs.ai_skill_invoke['arkora'],'arkora','ai_skill_invoke')
sgs.ai_skill_cardask['@arkoraask']=wrap(sgs.ai_skill_cardask['@arkoraask'],'@arkoraask','ai_skill_cardask')
sgs.ai_fill_skill['warlike']=wrap(sgs.ai_fill_skill['warlike'],'warlike','ai_fill_skill')
sgs.ai_target_revises['optimistic']=wrap(sgs.ai_target_revises['optimistic'],'optimistic','ai_target_revises')
sgs.ai_ajustdamage_to['optimistic']=wrap(sgs.ai_ajustdamage_to['optimistic'],'optimistic','ai_ajustdamage_to')
sgs.ai_fill_skill['keishoukaki']=wrap(sgs.ai_fill_skill['keishoukaki'],'keishoukaki','ai_fill_skill')
sgs.ai_skill_use_func['#keishoukaki']=wrap(sgs.ai_skill_use_func['#keishoukaki'],'#keishoukaki','ai_skill_use_func')
sgs.ai_skill_choice['keishoukaki']=wrap(sgs.ai_skill_choice['keishoukaki'],'keishoukaki','ai_skill_choice')
sgs.ai_skill_cardask['@moku_draw_ask']=wrap(sgs.ai_skill_cardask['@moku_draw_ask'],'@moku_draw_ask','ai_skill_cardask')
sgs.ai_skill_cardask['@mizu_recover_ask']=wrap(sgs.ai_skill_cardask['@mizu_recover_ask'],'@mizu_recover_ask','ai_skill_cardask')
sgs.ai_skill_cardask['@hono_damage_ask']=wrap(sgs.ai_skill_cardask['@hono_damage_ask'],'@hono_damage_ask','ai_skill_cardask')
sgs.ai_skill_cardask['@daiji_damage_ask']=wrap(sgs.ai_skill_cardask['@daiji_damage_ask'],'@daiji_damage_ask','ai_skill_cardask')
sgs.ai_skill_choice['taigyokunoyousei']=wrap(sgs.ai_skill_choice['taigyokunoyousei'],'taigyokunoyousei','ai_skill_choice')
sgs.ai_fill_skill['gomaoku']=wrap(sgs.ai_fill_skill['gomaoku'],'gomaoku','ai_fill_skill')
sgs.ai_skill_use_func['#gomaoku']=wrap(sgs.ai_skill_use_func['#gomaoku'],'#gomaoku','ai_skill_use_func')
sgs.ai_fill_skill['flyaway']=wrap(sgs.ai_fill_skill['flyaway'],'flyaway','ai_fill_skill')
sgs.ai_fill_skill['frankly']=wrap(sgs.ai_fill_skill['frankly'],'frankly','ai_fill_skill')
sgs.ai_skill_use_func['#franklyCard']=wrap(sgs.ai_skill_use_func['#franklyCard'],'#franklyCard','ai_skill_use_func')
sgs.ai_skill_choice['frankly']=wrap(sgs.ai_skill_choice['frankly'],'frankly','ai_skill_choice')
sgs.ai_skill_suit['frankly']=wrap(sgs.ai_skill_suit['frankly'],'frankly','ai_skill_suit')
sgs.ai_skill_use['@@flexible']=wrap(sgs.ai_skill_use['@@flexible'],'@@flexible','ai_skill_use')
sgs.ai_skill_playerchosen['hb_konoyaiba_uketemiyo']=wrap(sgs.ai_skill_playerchosen['hb_konoyaiba_uketemiyo'],'hb_konoyaiba_uketemiyo','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['hb_konoyaiba_uketemiyo']=wrap(sgs.ai_playerchosen_intention['hb_konoyaiba_uketemiyo'],'hb_konoyaiba_uketemiyo','ai_playerchosen_intention')
sgs.ai_skill_invoke['nikuhei_k']=wrap(sgs.ai_skill_invoke['nikuhei_k'],'nikuhei_k','ai_skill_invoke')
sgs.ai_skill_invoke['yuriKansen']=wrap(sgs.ai_skill_invoke['yuriKansen'],'yuriKansen','ai_skill_invoke')
sgs.ai_can_damagehp['yuriKansen']=wrap(sgs.ai_can_damagehp['yuriKansen'],'yuriKansen','ai_can_damagehp')
sgs.ai_guhuo_card['ov_jichou']=wrap(sgs.ai_guhuo_card['ov_jichou'],'ov_jichou','ai_guhuo_card')
sgs.ai_fill_skill['genshunoYURI']=wrap(sgs.ai_fill_skill['genshunoYURI'],'genshunoYURI','ai_fill_skill')
sgs.ai_skill_use_func['#genshunoYURICard']=wrap(sgs.ai_skill_use_func['#genshunoYURICard'],'#genshunoYURICard','ai_skill_use_func')
sgs.ai_guhuo_card['genshunoYURI']=wrap(sgs.ai_guhuo_card['genshunoYURI'],'genshunoYURI','ai_guhuo_card')
sgs.ai_skill_invoke['machiko']=wrap(sgs.ai_skill_invoke['machiko'],'machiko','ai_skill_invoke')
sgs.ai_fill_skill['clever']=wrap(sgs.ai_fill_skill['clever'],'clever','ai_fill_skill')
sgs.ai_skill_use_func['#clever']=wrap(sgs.ai_skill_use_func['#clever'],'#clever','ai_skill_use_func')
do local f=sgs.ai_view_as['clever'];sgs.ai_view_as['clever']=function(...)return proposal(f(...))end end
sgs.ai_skill_cardask['@magicat']=wrap(sgs.ai_skill_cardask['@magicat'],'@magicat','ai_skill_cardask')
sgs.ai_skill_choice['magicat']=wrap(sgs.ai_skill_choice['magicat'],'magicat','ai_skill_choice')
sgs.ai_skill_invoke['magicat']=wrap(sgs.ai_skill_invoke['magicat'],'magicat','ai_skill_invoke')
sgs.ai_fill_skill['Subetewonomikonmu']=wrap(sgs.ai_fill_skill['Subetewonomikonmu'],'Subetewonomikonmu','ai_fill_skill')
sgs.ai_skill_use_func['SubetewonomikonmuCard']=wrap(sgs.ai_skill_use_func['SubetewonomikonmuCard'],'SubetewonomikonmuCard','ai_skill_use_func')
sgs.ai_fill_skill['acting']=wrap(sgs.ai_fill_skill['acting'],'acting','ai_fill_skill')
sgs.ai_skill_use_func['#actingcard']=wrap(sgs.ai_skill_use_func['#actingcard'],'#actingcard','ai_skill_use_func')
sgs.ai_fill_skill['liketoplay']=wrap(sgs.ai_fill_skill['liketoplay'],'liketoplay','ai_fill_skill')
sgs.ai_skill_use_func['#liketoplaycard']=wrap(sgs.ai_skill_use_func['#liketoplaycard'],'#liketoplaycard','ai_skill_use_func')
sgs.ai_card_priority['proficient']=wrap(sgs.ai_card_priority['proficient'],'proficient','ai_card_priority')
sgs.ai_fill_skill['endingchoice']=wrap(sgs.ai_fill_skill['endingchoice'],'endingchoice','ai_fill_skill')
sgs.ai_skill_use_func['#endingchoiceCard']=wrap(sgs.ai_skill_use_func['#endingchoiceCard'],'#endingchoiceCard','ai_skill_use_func')
sgs.ai_skill_choice['sweetsis']=wrap(sgs.ai_skill_choice['sweetsis'],'sweetsis','ai_skill_choice')
do local f=sgs.ai_view_as['angel'];sgs.ai_view_as['angel']=function(...)return proposal(f(...))end end
sgs.ai_cardneed['angel']=wrap(sgs.ai_cardneed['angel'],'angel','ai_cardneed')
sgs.ai_fill_skill['angel']=wrap(sgs.ai_fill_skill['angel'],'angel','ai_fill_skill')
sgs.ai_fill_skill['hidethepath']=wrap(sgs.ai_fill_skill['hidethepath'],'hidethepath','ai_fill_skill')
sgs.ai_fill_skill['dressing']=wrap(sgs.ai_fill_skill['dressing'],'dressing','ai_fill_skill')
sgs.ai_skill_use_func['#dressing']=wrap(sgs.ai_skill_use_func['#dressing'],'#dressing','ai_skill_use_func')
sgs.ai_skill_cardchosen['dressing']=wrap(sgs.ai_skill_cardchosen['dressing'],'dressing','ai_skill_cardchosen')
sgs.ai_skill_playerchosen['dressing']=wrap(sgs.ai_skill_playerchosen['dressing'],'dressing','ai_skill_playerchosen')
