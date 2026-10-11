local PACKAGE="kearjsrgqi"
local SELECTORS={["#keqipingtaoCard"]="keqipingtao",["#keqilianzhuCard"]="keqilianzhu",["#keqishenchongCard"]="keqishenchong",["#keqitongjueCard"]="keqitongjue",["#keqishelunCard"]="keqishelun",["#keqipingjianCard"]="keqipingjian",["#keqiyizhengCard"]="keqiyizheng",["#kechengduxingCard"]="kechengduxing",["#kechenglunshiCard"]="kechenglunshi",["#kechengqingjiaoCard"]="kechengqingjiao",["#kechengqingxiCard"]="kechengqingxi",["#kechengjinmieCard"]="kechengjinmie",["#kechengzhengbingCard"]="kechengzhengbing",["#kechengzhangdengCard"]="kechengzhangdengex",["#kechengchengxianCard"]="kechengchengxian",["#kezhuanzhenfengCard"]="kezhuanzhenfeng",["#kezhuanxushiCard"]="kezhuanxushi",["#kezhuanguijiCard"]="kezhuanguiji",["#kezhuanjiaohaoCard"]="kezhuanjiaohaoex",["#kezhuancuifengCard"]="kezhuancuifeng",["#kezhuandengnanCard"]="kezhuandengnan",["#kezhuanhuozhongCard"]="kezhuanhuozhongex",["#kezhuanyangmingCard"]="kezhuanyangming",["#kezhuanmanjuanCard"]="kezhuanmanjuan",["#kehefushaCard"]="kehefusha",["#kehechushiCard"]="kehechushi",["#kehefuhaiCard"]="kehefuhai",["#kehejinfaCard"]="kehejinfa",["#kehejingjuCard"]="kehejingju",["#kehedailaoCard"]="kehedailao",["#kehechiyingCard"]="kehechiying",["#keshuaiyanggeCard"]="keshuaiyanggeex",["#keshuaisaojianCard"]="keshuaisaojian",["#keshuaidaorenCard"]="keshuaidaoren",["#keshuaiqiluanCard"]="keshuaiqiluan",["#xingqiantunCard"]="xingqiantun",["#xingweisiCard"]="xingweisi",["#xingfennanCard"]="xingfennan",["#xingshanzhengCard"]="xingshanzheng",["#xingpiqiCard"]="xingpiqi",["#xingzhuweiCard"]="xingzhuwei",["#keshuaizhuniCard"]="keshuaizhuni",["#keqiguanhuoCard"]="keqiguanhuo",["#kechengqongtuCard"]="kechengqongtu",["#kechengnianenCard"]="kechengnianen",["#kechengjixiangCard"]="kechengjixiang",["#kezhuanfenjianCard"]="kezhuanfenjian",["#kezhuanmanjuanVsCard"]="kezhuanmanjuanVs",["#kezhuanniluanCard"]="kezhuanniluan",["#keshuaijingleiCard"]="keshuaijinglei",["#xingxunjiCard"]="xingxunji",["#MizhaoCard"]="mizhao"}
local package_skills={}
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
 local f=self.world and self.world.strategy_facts;local a=f and f.pattern_names
 if not AIValue.isList(a)then unsupported('pattern_names')end;return a
end
local function source_fact(self,key,kind)
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
 if kind=='toDamage'then local d={};for k,x in pairs(v)do d[k]=x end;for _,k in ipairs({'from','to'})do if d[k]then d[k]=package_known(self.room,'findPlayerByObjectName',d[k],true)end end;if d.card then d.card=CardView.new(d.card)end;return d end
 unsupported(key..'.'..kind)
end
-- Three keqiwendao questions read only their admitted native V2 frame.
-- Direct JudgeStruct predicates are deliberately separate from retrial filters.
local function wendao_judge(self)
 local c=package_known(self,'getDecisionContext').keqiwendao_judge
 if type(c)~='table' or c.known~=true then unsupported('keqiwendao.current_judge')end
 local r=self.request
 if not r or c.viewer~=package_known(self.player,'objectName')
  or c.decision_id~=tostring(r.decision_id) or c.state_revision~=tostring(r.state_revision)
  or c.kind~=r.kind or c.reason~='keqiwendao' or not r.options or r.options.reason~='keqiwendao'
 then unsupported('keqiwendao.scope')end
 if c.present==false then return nil end
 if c.present~=true or type(c.good)~='boolean' or type(c.outcomes)~='table'
 then unsupported('keqiwendao.judge_schema')end
 local j={who=package_known(self.room,'findPlayerByObjectName',c.who,true)}
 function j:isGood(card)
  if card==nil then return c.good end
  local id=package_known(card,'getEffectiveId');local row=c.outcomes[tostring(id)]
  if type(row)~='table' or row.card_id~=id or row.name~=package_known(card,'objectName')
   or row.class_name~=package_known(card,'getClassName') or row.suit~=package_known(card,'getSuit')
   or row.number~=package_known(card,'getNumber') or type(row.good)~='boolean'
  then unsupported('keqiwendao.direct_judge_outcome')end
  return row.good
 end
 return j
end
local function wendao_known_cards(self,p)
 local cards=getKnownCards(p,self.player,'he')
 if AIUnsupported.is(cards)then error(cards,0)end
 if cards==nil then unsupported('keqiwendao.known_he_cards')end
 return cards
end
local function wendao_ag_card(self,id)
 local card=package_call(self,'getChoiceCard',id)
 if card==nil then unsupported('keqiwendao.offered_card')end
 return card
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

local function clone_native(self,name,suit,number)return clone(self,name,nil,suit,number)end
local function memory(self,key)local v,known=package_call(self,"getStrategyMemory",PACKAGE.."."..key);if not known then unsupported("memory."..key)end;return v end
local function unobserved_global(self,name)return fact(self,"global_"..name)end
local function owner_reason(self)local f=self.world and self.world.strategy_facts;local n=f and f.owner_current_card_use_reason;if type(n)~="number"then unsupported("owner_current_card_use_reason")end;return n end
local function source_card_count(self)return fact(self,"source_card_count")end
local function candidate_skills(self,key)unsupported(key)end
local function skill_meta(self,s,key)unsupported("candidate_skill."..key)end
local function source_targets(self,card)unsupported("exact_card_targets")end
local function skill_proposal(selector,costs,user)local skill=SELECTORS[selector];if not skill then unsupported("response_selector."..selector)end;return{name=selector:sub(2),skill=skill,subcards=costs,suit=sgs.Card_NoSuit,number=0,user_string=user}end
local function peiqi(self)
 local f=sgs.ai_skill_invoke.peiqi;if type(f)~="function"then unsupported("peiqi")end
 local v=f(self);if AIUnsupported.is(v)then error(v,0)end
 if self.peiqiData then local d=self.peiqiData;package_call(self,"setStrategyMemory",PACKAGE..".peiqi",{from=d.from and package_known(d.from,"objectName"),to=d.to and package_known(d.to,"objectName"),cid=d.cid})end;return v
end
local function peiqi_state(self)
 if self.peiqiData then return self.peiqiData end
 local d=memory(self,"peiqi");return{from=d.from and package_known(self.room,"findPlayerByObjectName",d.from,true),to=d.to and package_known(self.room,"findPlayerByObjectName",d.to,true),cid=d.cid}
end

sgs.ai_skill_invoke.keqizhenglue = function(self, data)
	return true
end
sgs.ai_skill_invoke.keqizhengluegaincard = function(self, data)
	return true
end

sgs.ai_skill_playerschosen.keqizhenglue = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local n = max
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")

    for _,target in ipairs(can_choose) do
        if package_known(self,"isEnemy",target) and not package_known(selected,"contains",target) then
            package_call(selected,"append",target)
            n = n - 1
        end
        if n <= 0 then break end
    end

	if (n > 0) then
		for _,target in ipairs(can_choose) do
			if not package_known(selected,"contains",target) then
				package_call(selected,"append",target)
				n = n - 1
			end
			if n <= 0 then break end
		end
	end
    return selected
end

sgs.ai_skill_playerchosen.keqizhenglue = function(self, targets)
	targets = sgs.QList2Table(targets)
	local num = 1
	for _, p in ipairs(targets) do
		if not (package_known(p,"objectName") == package_known(self.player,"objectName")) then
			num = 0
			return p
		end
	end
	if num == 1 then
		return self
	end
	return nil
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|keqizhenglue"











sgs.ai_skill_playerchosen.keqipingrong = function(self, targets)
	for _, p in ipairs(sgs.QList2Table(targets)) do
		if package_known(self,"isFriend",p) then
			return p
		end
	end
	for _, p in ipairs(sgs.QList2Table(targets)) do
		if not package_known(self,"isEnemy",p) then
			return p
		end
	end
end



sgs.recover_hp_skill = sgs.recover_hp_skill .. "|keqijishan"
sgs.ai_skill_playerchosen.keqijishan = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets, "defense")
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) and package_known(p,"getHp") < getBestHp(p) then
			return p
		end
	end
	return nil
end

table.insert(sgs.ai_voluntary_give_skills,"_kecheng_tuixinzhifu")


sgs.ai_skill_invoke.keqijishan = function(self, data)
	local damage = package_known(data,"toDamage")

	if (package_known(damage.to,"objectName") == package_known(self.player,"objectName")) then
		return true
	elseif package_known(self,"isFriend",damage.to) and (not package_known(self,"isWeak") or (package_known(damage.to,"isLord") and package_known(self,"isWeak",damage.to))) then
		return not package_known(self,"needToLoseHp",damage.to, damage.from, damage.card)
	end
end

sgs.ai_choicemade_filter.skillInvoke.keqijishan = function(self,player,promptlist)
	local damage = source_fact(self,"keqijishan","toDamage")
	if damage.to and promptlist[3]=="yes" then
		sgs.updateIntention(player,damage.to,-80)
	end
end

sgs.ai_use_revises.keqizhenqiao = function(self,card,use)
	if package_known(card,"isKindOf","Weapon") then
		for _, p in ipairs(self.enemies)do
			if package_known(self.player,"inMyAttackRange",p) then
				return false
			end
		end
		if #self.enemies<1 then
			return false
		end
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|keqizhenqiao"



sgs.ai_skill_discard.keqijuelietwo = function(self, discard_num, min_num, optional, include_equip)
	local slashone = source_fact(self,"keqijuelietwoFrom","toPlayer")
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards, true)
	if package_known(self,"isEnemy",slashone) and (package_known(self.player,"getCardCount") > 0) then
		local min = 999
		for _,p in sgs.qlist(package_known(self.room,"getAllPlayers")) do
			if (package_known(p,"getHandcardNum") < 999) then
				min = package_known(p,"getHandcardNum")
			end
		end
		local x = package_known(self.player,"getHandcardNum") - min


			for i = 1, x do
				table.insert(to_discard, package_known(cards[i],"getEffectiveId"))
			end







		return to_discard
	else
	    return package_known(self,"askForDiscard","dummyreason", discard_num, discard_num, true, true)
	end
end
sgs.hit_skill = sgs.hit_skill .. "|keqijuelietwo"

sgs.ai_skill_discard.keqipingtao = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local room = package_known(self.player,"getRoom")
	local sj = source_fact(self,"keqipingtaoFrom","toPlayer")
	if package_known(self,"isFriend",sj) then
	    table.insert(to_discard, package_known(cards[#cards],"getEffectiveId"))
		return to_discard
	elseif package_known(self,"isWeak")
	and (package_known(self.player,"getCardCount") > 0)
	and (package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") == 0) then
	    table.insert(to_discard, package_known(cards[1],"getEffectiveId"))
		return to_discard
	else
		return package_known(self,"askForDiscard","dummyreason", discard_num, discard_num, true, true)
	end
end

local keqipingtao_skill = {}
keqipingtao_skill.name = "keqipingtao"
table.insert(package_skills, keqipingtao_skill)
keqipingtao_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","keqipingtaoCard") then return end
	return source_skill(self,"#keqipingtaoCard:.:")
end

sgs.ai_skill_use_func["#keqipingtaoCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies)
	local enys = sgs.SPlayerList()
	for _, enemy in ipairs(sgs.reverse(self.enemies)) do
		if package_known(enys,"isEmpty") then
			package_call(enys,"append",enemy)
		else
			local yes = 1
			for _,p in sgs.qlist(enys) do
				if (package_known(enemy,"getHp")+package_known(enemy,"getHp")+package_known(enemy,"getHandcardNum")) >= (package_known(p,"getHp")+package_known(p,"getHp")+package_known(p,"getHandcardNum")) then
					yes = 0
				end
			end
			if (yes == 1) then
				package_known(enys,"removeOne",package_known(enys,"at",0))
				package_call(enys,"append",enemy)
			end
		end
	end
	for _,enemy in sgs.qlist(enys) do
		if package_known(self,"objectiveLevel",enemy) > 0 then
			use.card = card
			if use.to then package_call(use.to,"append",enemy) end
			return
		end
	end
end

sgs.ai_use_value.keqipingtaoCard = 8.5
sgs.ai_use_priority.keqipingtaoCard = 9.5
sgs.ai_card_intention.keqipingtaoCard = 80
sgs.double_slash_skill = sgs.double_slash_skill.."|keqipingtao"


sgs.ai_skill_invoke.keqishichong = function(self, data)
	local to = package_call(data,"toPlayer")
	return package_known(self,"doDisCard",to, "h", true)
end

sgs.ai_skill_discard.keqishichong = function(self, discard_num, min_num, optional, include_equip)
	local db = source_fact(self,"keqishichongFrom","toPlayer")
	local to_discard = {}
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	if package_known(self,"isFriend",db) and (package_known(self.player,"getCardCount") > 0) then
	    table.insert(to_discard, package_known(cards[1],"getEffectiveId"))
		sgs.updateIntention(self.player,db ,-20)
		return to_discard
	else
	    return package_known(self,"askForDiscard","dummyreason", discard_num, discard_num, true, true)
	end
end
sgs.drawpeach_skill = sgs.drawpeach_skill .."|keqishichong"


local keqilianzhu = {}
keqilianzhu.name = "keqilianzhu"
table.insert(package_skills, keqilianzhu)
keqilianzhu.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","#keqilianzhuCard") then return end
	return source_skill(self,"#keqilianzhuCard:.:")
end

sgs.ai_skill_use_func["#keqilianzhuCard"] = function(card,use,self,request)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	if #cards<2 then return end
	package_call(self,"sortByKeepValue",cards)
	package_call(self,"sort",self.enemies,nil,true)
	local ks = {}
	local dismantlement = clone_native(self,"dismantlement")
	package_call(dismantlement,"setSkillName","_keqilianzhu")
	package_call(dismantlement,"deleteLater")
	for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(self,"isEnemy",p) and package_known(p,"getCardCount")>0 and package_known(self,"hasTrickEffective",dismantlement,p,self.player) then
			ks[package_known(p,"getKingdom")] = (ks[package_known(p,"getKingdom")] or 0)+1
		end
	end
	local x = 0
	for k,n in pairs(ks)do
		if n>x then x = n end
	end
	for k,n in pairs(ks)do
		if n>=x then
			for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
				if package_known(p,"getKingdom") == k and package_known(self,"isFriend",p) and hasTuntianEffect(p) then
					use.card = source_skill(self,"#keqilianzhuCard:"..package_known(cards[1],"getId")..":")
					package_call(use.to,"append",p)
					return
				end
			end
			for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
				if package_known(p,"getKingdom") == k and package_known(self,"isFriend",p) and  package_known(self,"doDisCard",p, "hej") then
					use.card = source_skill(self,"#keqilianzhuCard:"..package_known(cards[1],"getId")..":")
					package_call(use.to,"append",p)
					return
				end
			end
			for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
				if package_known(p,"getKingdom") == k and package_known(self,"isFriend",p) and package_known(p,"getCardCount")>0 then
					use.card = source_skill(self,"#keqilianzhuCard:"..package_known(cards[1],"getId")..":")
					package_call(use.to,"append",p)
					return
				end
			end
			for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
				if package_known(p,"getKingdom") == k and not package_known(self,"isEnemy",p) and package_known(p,"getCardCount")>0 then
					use.card = source_skill(self,"#keqilianzhuCard:"..package_known(cards[1],"getId")..":")
					package_call(use.to,"append",p)
					return
				end
			end
		end
	end
	for k, n in pairs(ks) do
		if n>=x then
			for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
				if package_known(p,"getKingdom") == k then
					use.card = source_skill(self,"#keqilianzhuCard:"..package_known(cards[1],"getId")..":")
					package_call(use.to,"append",p)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.keqilianzhuCard = 8.5
sgs.ai_use_priority.keqilianzhuCard = 6.5





sgs.ai_skill_playerschosen.keqizhaobing = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local n = max
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")

    for _,target in ipairs(can_choose) do
        if package_known(self,"isEnemy",target) and not package_known(selected,"contains",target) and not hasZhaxiangEffect(target) then
            package_call(selected,"append",target)
            n = n - 1
        end
        if n <= 0 then break end
    end
    return selected
end

sgs.ai_skill_discard.keqizhaobing = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local room = package_known(self.player,"getRoom")
	local hj = package_call(room,"getCurrent")
	local cards = package_known(self.player,"getCards","he")
	for _,c in sgs.qlist(cards) do
		if  package_known(c,"isKindOf","Slash") then
			table.insert(to_discard, package_known(c,"getEffectiveId"))
			break
		end
	end
	if (package_known(self,"isFriend",hj) or package_known(self,"isWeak")) and (#to_discard > 0) then
		return to_discard
	else
	    return package_known(self,"askForDiscard","dummyreason", discard_num, discard_num, true, true)
	end
end



sgs.ai_skill_invoke.keqizhaobing = function(self, data)
	if package_known(self.player,"getHandcardNum") < 3 then
	    return not sgs.ai_skill_playerschosen.keqizhaobing(self,  package_known(self.room,"getOtherPlayers",self.player), package_known(self.player,"getHandcardNum"), 0):isEmpty()
	end
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill.."|keqizhaobing"

sgs.ai_skill_invoke.keqizhuhuan = function(self, data)
	return sgs.ai_skill_playerchosen.keqizhuhuan(self, package_known(self.room,"getOtherPlayers",self.player)) ~= nil
end

sgs.ai_skill_playerchosen.keqizhuhuan = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets)
	local x = package_known(self.player,"getStrategyMark","keqizhuhuan")
	for _, p in ipairs(targets) do
		if package_known(self,"isWeak") and package_known(self,"isFriend",p) then
			return p
		elseif package_known(self,"isEnemy",p) and package_known(self,"canDamage",p, self.player) and package_known(self,"doDisCard",p,"he", false, x) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_choice.keqizhuhuan = function(self, choices, data)
	local items = package_known(choices,"split","+")
	local hj = package_call(self.room,"getCurrent")
	if (package_known(self,"isWeak") or package_known(self,"isFriend",hj)) or (package_known(self,"isEnemy",hj) and not package_known(hj,"isWounded")) then
		return items[2]
	else
		return items[1]
	end
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill.."|keqizhuhuan"

sgs.recover_hp_skill = sgs.recover_hp_skill.."|keqizhuhuan"


local keqiguanhuo_skill = {}
keqiguanhuo_skill.name = "keqiguanhuo"
table.insert(package_skills, keqiguanhuo_skill)
keqiguanhuo_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","keqiguanhuoCard") and (package_known(self.player,"getStrategyMark","aiguanhuo-PlayClear") == 0) then return end
	local fa = clone_native(self,"fire_attack")
	package_call(fa,"setSkillName","keqiguanhuo")
	package_call(fa,"setFlags","keqiguanhuo")
	package_call(fa,"deleteLater")
	if package_known(self.player,"getStrategyMark","usekeqiguanhuo-PlayClear")>0 then
		local d = package_known(self,"aiUseCard",fa)
		if d.card then
			local cards = package_known(self.player,"getCards","h")
			for _,p in sgs.qlist(d.to) do
				local n = 0
				for _,c in sgs.list(cards) do
					if #getKnownCards(p,self.player,"h",package_known(c,"getSuit"))>0 then
						n = n+1
					end
				end
				if n>package_known(cards,"length")/2 then
					return fa
				end
			end
		end
	else
		return fa
	end

end

















sgs.ai_skill_use_func["#keqiguanhuoCard"] = function(card,use,self,request)
    if (not package_known(self.player,"hasUsed","#keqiguanhuoCard")) or (package_known(self.player,"getStrategyMark","aiguanhuo-PlayClear") > 0) then
        package_call(self,"sort",self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if not package_known(enemy,"isKongcheng") then
				if package_known(enys,"isEmpty") then
					package_call(enys,"append",enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(enys) do
						if (package_known(enemy,"getHp")+package_known(enemy,"getHp")+package_known(enemy,"getHandcardNum")) >= (package_known(p,"getHp")+package_known(p,"getHp")+package_known(p,"getHandcardNum")) then
							yes = 0
						end
					end
					if (yes == 1) then
						package_known(enys,"removeOne",package_known(enys,"at",0))
						package_call(enys,"append",enemy)
					end
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			if package_known(self,"objectiveLevel",enemy) > 0 then
			    use.card = card
			    if use.to then package_call(use.to,"append",enemy) end
		        return
			end
		end
	end
end
sgs.ai_use_value.keqiguanhuoCard = 8.5
sgs.ai_use_priority.keqiguanhuoCard = 9.5
sgs.ai_card_intention.keqiguanhuoCard = 80

sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .. "|keqiguanhuo"
sgs.ai_ajustdamage_from.keqiguanhuo = function(self,from,to,card,nature)
	if card and package_known(card,"isKindOf","FireAttack") and package_known(from,"getStrategyMark","&usekeqiguanhuoda-PlayClear")>0
	then return 1 end
end

sgs.ai_skill_invoke.keqijuxia = function(self, data)
	local to = package_call(data,"toPlayer")
	local use = source_fact(self,"keqijuxiaData","toCardUse")
	return package_known(self,"isFriend",to) and (package_known(use.card,"isDamageCard") or package_known(use.to,"length")>1)
end
sgs.ai_choicemade_filter.skillInvoke.keqijuxia = function(self,player,promptlist)
	local target = package_known(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
	if not target then return end
	if promptlist[#promptlist]=="yes" then
		sgs.updateIntention(player,target, -10)
	end
end



sgs.ai_skill_invoke.keqimingshi = function(self, data)




	local dmg = package_known(data,"toDamage")
	if dmg.to and not package_known(self,"isFriend",dmg.to) then return false end
	if package_known(self.player,"isChained") and dmg.nature~=sgs.DamageStruct_Normal
	and not package_known(self,"isGoodChainTarget",self.player,dmg.card or dmg.nature,dmg.from,dmg.damage)
	then
	elseif package_known(self.player,"getHp")>=2 and dmg.damage<2
	and (package_known(self.player,"hasSkills",sgs.recover_skill)
		or package_known(self,"needToLoseHp",self.player, dmg.from, dmg.card)
		or (package_known(self.player,"getHandcardNum")<3 and (package_known(self.player,"hasSkill","nosrende") or (package_known(self.player,"hasSkill","rende") and not package_known(self.player,"hasUsed","RendeCard")))))
	then return true
	elseif dmg.card and package_known(dmg.card,"getTypeId")==sgs.Card_TypeTrick
	and package_known(self.player,"hasSkill","wuyan")
	then return true
	elseif hasBuquEffect(self.player)
	then return true end
	if package_known(self,"isWeak",dmg.to) then return true end
	return false
end

sgs.ai_skill_invoke.keqilirang_use = function(self, data)
	if package_known(self.player,"getStrategyFlag","aiuselirang") then
	    return true
	end
end
sgs.ai_skill_discard.keqilirang = function(self)
	local to = source_fact(self,"keqilirangTo","toPlayer")
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	if (package_known(self,"isFriend",to) or not package_known(self,"isEnemy",to) and #self.friends<#self.enemies)
	and (not package_known(self,"isWeak") or #cards>3) then
		package_call(self,"sortByKeepValue",cards)
		for _, c in sgs.list(cards) do
			if package_known(c,"isAvailable",to) then
				table.insert(to_discard, package_known(c,"getEffectiveId"))
				if #to_discard>1 then break end
			end
		end
		for _, c in sgs.list(cards) do
			if #to_discard>1 then break end
			if #to_discard>0 and not table.contains(to_discard, package_known(c,"getEffectiveId")) then
				table.insert(to_discard, package_known(c,"getEffectiveId"))
			end
		end
	end
	return to_discard
end
sgs.ai_skill_invoke.keqilirang_get = function(self, data)
	return true
end
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|keqilirang"


sgs.ai_skill_invoke.keqichaozheng = function(self, data)
	for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(self,"isFriend",p) then
			return true
		end
	end
	return false
end


local keqishenchong_skill = {}
keqishenchong_skill.name = "keqishenchong"
table.insert(package_skills, keqishenchong_skill)
keqishenchong_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@keqishenchong") == 0 then return end
	return source_skill(self,"#keqishenchongCard:.:")
end

sgs.ai_skill_use_func["#keqishenchongCard"] = function(card,use,self,request)
	package_call(self,"sort",self.friends,"defense",true)
	local player = package_known(self,"AssistTarget")
	if player then
		use.card = card
		if use.to then package_call(use.to,"append",player) end
		return
	end
	for _, fri in ipairs(self.friends) do
		if (package_known(fri,"objectName") ~= package_known(self.player,"objectName")) then
			use.card = card
			if use.to then package_call(use.to,"append",fri) end
			return
		end
	end
end

sgs.ai_use_value["#keqishenchongCard"] = 8.5
sgs.ai_use_priority["#keqishenchongCard"] = 9.5
sgs.ai_card_intention["#keqishenchongCard"] = -80












sgs.ai_skill_discard.keqichaozheng = function(self)
	local to_discard = {}
	local from = package_call(self.room,"getCurrent")
	local n = 0
	for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",from)) do
		if package_known(p,"isWounded") then
			n = n+1
			if not package_known(self,"isEnemy") then
				n = n+1
			end
		else
			n = n-1
		end
	end
	for _,c in sgs.qlist(package_known(self.player,"getCards","h")) do
		if n >1 and package_known(c,"isRed") then
			table.insert(to_discard, package_known(c,"getEffectiveId"))
			break
		end
	end
	for _,c in sgs.qlist(package_known(self.player,"getCards","h")) do
		if #to_discard<1 and not package_known(c,"isRed") then
			table.insert(to_discard, package_known(c,"getEffectiveId"))
			break
		end
	end
	if #to_discard<1 then
		for i,c in sgs.qlist(package_known(self.player,"getCards","h")) do
			table.insert(to_discard, package_known(c,"getEffectiveId"))
			break
		end
	end
	return to_discard
end


local keqitongjue = {}
keqitongjue.name = "keqitongjue"
table.insert(package_skills, keqitongjue)
keqitongjue.getTurnUseCard = function(self,inclusive,request)
	for i,uc in ipairs(self.toUse)do do
		if i>1 then
			if package_known(uc,"isKindOf","AOE") or package_known(uc,"isKindOf","GlobalEffect") then
				local ids = {}
				for _, c in sgs.qlist(package_known(self.player,"getCards","h")) do
					if package_known(c,"isKindOf","BasicCard")
					and package_known(c,"getEffectiveId")~=package_known(uc,"getEffectiveId") then
						table.insert(ids, package_known(c,"getEffectiveId"))
					end
				end
				if #ids<1 then goto package_continue_1 end
				return source_skill(self,"#keqitongjueCard:"..table.concat(ids,"+")..":")
			else
				local d = package_known(self,"aiUseCard",uc)
				if d.card and package_known(d.to,"length")>1 then
					local ids = {}
					for _, c in sgs.qlist(package_known(self.player,"getCards","h")) do
						if package_known(c,"isKindOf","BasicCard")
						and package_known(c,"getEffectiveId")~=package_known(uc,"getEffectiveId") then
							table.insert(ids, package_known(c,"getEffectiveId"))
						end
					end
					if #ids<1 then goto package_continue_1 end
					return source_skill(self,"#keqitongjueCard:"..table.concat(ids,"+")..":")
				end
			end
		end
	end ::package_continue_1:: end
end

sgs.ai_skill_use_func["#keqitongjueCard"] = function(card,use,self,request)
	package_call(self,"sort",self.friends_noself,"defense")
	for _, fri in ipairs(self.friends_noself) do
		if package_known(fri,"getKingdom")=="qun" then
			use.card = card
			if use.to then package_call(use.to,"append",fri) end
			break
		end
	end
end

sgs.ai_use_value.keqitongjueCard = 8.5
sgs.ai_use_priority.keqitongjueCard = 9.5
sgs.ai_card_intention.keqitongjueCard = -80












sgs.ai_skill_discard.keqichaozheng = function(self)
	local to_discard = {}
	local from = package_call(self.room,"getCurrent")
	local n = 0
	for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",from)) do
		if package_known(p,"isWounded") then
			n = n+1
			if not package_known(self,"isEnemy",p) then
				n = n+1
			end
		else
			n = n-1
		end
	end
	for _,c in sgs.qlist(package_known(self.player,"getCards","h")) do
		if n >1 and package_known(c,"isRed") then
			table.insert(to_discard, package_known(c,"getEffectiveId"))
			break
		end
	end
	for _,c in sgs.qlist(package_known(self.player,"getCards","h")) do
		if #to_discard<1 and not package_known(c,"isRed") then
			table.insert(to_discard, package_known(c,"getEffectiveId"))
			break
		end
	end
	if #to_discard<1 then
		for i,c in sgs.qlist(package_known(self.player,"getCards","h")) do
			table.insert(to_discard, package_known(c,"getEffectiveId"))
			break
		end
	end
	return to_discard
end

sgs.ai_skill_invoke.keqijulian = function(self,data)
    return true
end

sgs.ai_skill_invoke.keqitushe = function(self,data)
	for _, c in sgs.qlist(package_known(self.player,"getCards","h")) do
		if package_known(c,"isKindOf","BasicCard") then return false end
	end
    return true
end


sgs.ai_armor_value._keqi_taipingyaoshu = 6
sgs.ai_ajustdamage_to._keqi_taipingyaoshu = function(self,from,to,card,nature)
	if nature~="N" then return -99 end
end

sgs.ai_skill_playerchosen.keqishoushu = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if (package_known(self.player,"objectName") == package_known(p,"objectName")) then
		    return p
		end
	end
	return nil
end

sgs.ai_skill_playerchosen.keqishoushutwo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if (package_known(self.player,"objectName") == package_known(p,"objectName")) then
		    return p
		end
	end
	return nil
end

sgs.ai_skill_playerschosen.keqiwendao = function(self, targets,x,n)
	targets = sgs.QList2Table(targets)
	targets = package_known(self,"sort",targets,"defense",true)
	local tos = {}
	local judge = wendao_judge(self)
	if not judge:isGood() then
		for _, p in ipairs(targets) do
			if package_known(self,"isFriend",p) and #tos<1 then
				for _, c in ipairs(wendao_known_cards(self,p)) do do
					if package_known(p,"isJilei",c) then goto package_continue_2 end
					if judge:isGood(c) then
						table.insert(tos, p)
						break
					end
				end ::package_continue_2:: end
			end
		end
		for _, p in ipairs(targets) do
			if #tos==1 and package_known(self,"isEnemy",p) then
				table.insert(tos, p)
			end
		end
		for _, p in ipairs(targets) do
			if #tos==1 and not package_known(self,"isFriend",p) then
				table.insert(tos, p)
			end
		end
		for _, p in ipairs(targets) do
			if #tos==1 and tos[1]~=p then
				table.insert(tos, p)
			end
		end
	end
	return tos
end

sgs.ai_skill_discard.keqiwendao = function(self)
	local judge = wendao_judge(self)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	cards = package_known(self,"sortByKeepValue",cards)
	if package_known(self,"isFriend",judge.who) then
		for _, c in ipairs(cards) do do
			if package_known(self.player,"isJilei",c) then goto package_continue_3 end
			if judge:isGood(c) then
				return {package_known(c,"getEffectiveId")}
			end
		end ::package_continue_3:: end
	else
		for _, c in ipairs(cards) do do
			if package_known(self.player,"isJilei",c) then goto package_continue_4 end
			return {package_known(c,"getEffectiveId")}
		end ::package_continue_4:: end
	end
end

sgs.ai_skill_askforag.keqiwendao = function(self,card_ids)
	local judge = wendao_judge(self)
	for _,id in sgs.list(card_ids) do
		if judge:isGood(wendao_ag_card(self,id)) then
			return id
		end
	end
end

sgs.ai_skill_invoke.keqixuanhua = function(self,data)
	if package_known(self.player,"getPhase") == sgs.Player_Start then
		return not package_known(self,"damageIsEffective",self.player,"T")
		or package_known(self,"getFinalRetrial",nil,"lightning")<2
	end
	return (not package_known(self,"damageIsEffective",self.player,"T") or package_known(self,"getFinalRetrial",nil,"lightning")==1)
	and #self.enemies>0
end

sgs.ai_skill_playerchosen.keqixuanhua = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if package_known(self.player,"getPhase") == sgs.Player_Start and package_known(self,"isFriend",p) and package_known(p,"isWounded") then
		    return p
		end
	end
	for _, p in ipairs(targets) do
		if package_known(self.player,"getPhase") == sgs.Player_Finish and package_known(self,"isEnemy",p) then
		    return p
		end
	end
end



function sgs.ai_cardneed.keqijuezhi(to,card,self)
	for i=0,4 do
		if (package_known(to,"hasEquipArea",i) and not package_call(to,"getEquip",i)) then
			return package_known(card,"isKindOf","EquipCard") and package_known(card,"getEquipSlot") == i
		end
	end
end
sgs.ai_skill_invoke.keqijuezhi_wq = function(self,data)
    return true
end
sgs.ai_skill_invoke.keqijuezhi_fj = function(self,data)
    return true
end
sgs.ai_skill_invoke.keqijuezhi_fy = function(self,data)
    return true
end
sgs.ai_skill_invoke.keqijuezhi_jg = function(self,data)
    return true
end
sgs.ai_skill_invoke.keqijuezhi_bw = function(self,data)
    return true
end

sgs.ai_ajustdamage_from.keqijuezhi = function(self, from, to, card, nature)
	if (card) and package_known(from,"getStrategyMark","canusekeqijuezhi")>0 then
		local x = 0
		for i,e in sgs.list(package_known(to,"getEquips")) do
			local index = package_known(e,"getEquipSlot")
			if not package_known(from,"hasEquipArea",index) then x = x+1 end
		end
		return x
	end
end

sgs.ai_skill_invoke.keqijuezhi = function(self,data)
    return true
end
sgs.ai_skill_playerchosen.keqijizhao = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets,nil,true)
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) and package_known(p,"getJudgingArea"):length() > 0 then
		    return p
		end
	end
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) and package_known(p,"getHandcardNum")>2 then
		    return p
		end
	end
	sgs.ai_skill_invoke.peiqi(self,ToData())
	for _, p in ipairs(targets) do
		if package_known(p,"getHandcardNum") < 3 and package_known(self,"doDisCard",p,"hej",true) and peiqi_state(self).from==p then
		    return p
		end
	end
	for _, p in ipairs(targets) do
		if package_known(p,"getHandcardNum") < 3 and package_known(self,"doDisCard",p,"hej",true) then
		    return p
		end
	end
	return nil
end
sgs.ai_skill_playerchosen.keqijizhao_from = function(self, targets)
	peiqi(self)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if peiqi_state(self).from==p then
		    return p
		end
	end
	return targets[1]
end
sgs.ai_skill_playerchosen.keqijizhao_to = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if peiqi_state(self).to==p then
		    return p
		end
	end
end
sgs.ai_skill_cardchosen.keqijizhao = function(self,who,flags,method)
	for _,e in sgs.list(package_known(who,"getCards",flags))do
		local id = package_known(e,"getEffectiveId")
		if id==peiqi_state(self).cid
		then return id end
	end
end





local keqishelun_skill = {}
keqishelun_skill.name = "keqishelun"
table.insert(package_skills, keqishelun_skill)
keqishelun_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","keqishelunCard") then return end
	return source_skill(self,"#keqishelunCard:.:")
end

sgs.ai_skill_use_func["#keqishelunCard"] = function(card,use,self,request)
    if not package_known(self.player,"hasUsed","#keqishelunCard") then
        package_call(self,"sort",self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if package_known(self.player,"inMyAttackRange",enemy) then
				if package_known(enys,"isEmpty") then
					package_call(enys,"append",enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(enys) do
						if (package_known(enemy,"getHp")+package_known(enemy,"getHp")+package_known(enemy,"getHandcardNum")) >= (package_known(p,"getHp")+package_known(p,"getHp")+package_known(p,"getHandcardNum")) then
							yes = 0
						end
					end
					if (yes == 1) then
						package_known(enys,"removeOne",package_known(enys,"at",0))
						package_call(enys,"append",enemy)
					end
				end
			end
		end
		if (package_known(enys,"length") > 0) then
			for _,enemy in sgs.qlist(enys) do
				if package_known(self,"objectiveLevel",enemy) > 0 then
				use.card = card
				if use.to then package_call(use.to,"append",enemy) end
				return
			end
		end
	end
end
end

sgs.ai_use_value.keqishelunCard = 8.5
sgs.ai_use_priority.keqishelunCard = 9.5
sgs.ai_card_intention.keqishelunCard = 80

sgs.ai_skill_playerchosen.keqifayi = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_discard.keqishelun = function(self)
	local to = source_fact(self,"keqishelunTo","toPlayer")
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	if package_known(self,"isFriend",to) or not package_known(self,"isEnemy",to) and #self.enemies>#self.friends then
		for _,c in sgs.list(cards) do
			if package_known(c,"isRed") then
				return {package_known(c,"getEffectiveId")}
			end
		end
	elseif package_known(self,"isEnemy",to) and package_known(self,"canDamage",to, self.player) then
		for _,c in sgs.list(cards) do
			if package_known(c,"isBlack") then
				return {package_known(c,"getEffectiveId")}
			end
		end
	end
	return {package_known(cards[1],"getEffectiveId")}
end


local keqipingjian = {}
keqipingjian.name = "keqipingjian"
table.insert(package_skills, keqipingjian)
keqipingjian.getTurnUseCard = function(self,ex)
	for _,s in sgs.list(candidate_skills(self,"qiPingSkills"))do do
		if package_known(s,"inherits","FilterSkill") then goto package_continue_5 end
		if package_known(s,"inherits","ViewAsSkill")
		and skill_meta(self,s,"view_as"):isEnabledAtPlay(self.player) then
			local sk = sgs.ai_fill_skill[package_known(s,"objectName")]
			if sk then
				sk = sk(self,ex)
				if sk then
					local d = package_known(self,"aiUseCard",sk)
					if d.card then
						save_plan(self,"keqipingjianUse",d)
						package_call(self,"setStrategyMemory","kearjsrgqi.choice.keqipingjian",package_known(s,"objectName"))
						package_call(self,"setPriorityValue","keqipingjianCard",package_known(self,"getPriorityValue",package_known(sk,"getClassName")))
						return source_skill(self,"#keqipingjianCard:.:")
					end
				end
			end
		elseif package_known(s,"inherits","TriggerSkill") then
			local ts = skill_meta(self,s,"trigger")
			ts = package_known(ts,"getViewAsSkill")
			if ts and package_known(ts,"isEnabledAtPlay",self.player) then
				local sk = sgs.ai_fill_skill[package_known(ts,"objectName")]
				if sk then
					sk = sk(self,ex)
					if sk then
						local d = package_known(self,"aiUseCard",sk)
						if d.card then
							save_plan(self,"keqipingjianUse",d)
							package_call(self,"setStrategyMemory","kearjsrgqi.choice.keqipingjian",package_known(ts,"objectName"))
							package_call(self,"setPriorityValue","keqipingjianCard",package_known(self,"getPriorityValue",package_known(sk,"getClassName")))
							return source_skill(self,"#keqipingjianCard:.:")
						end
					end
				end
			end
		end
	end ::package_continue_5:: end
end

sgs.ai_skill_use_func["#keqipingjianCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value.keqipingjianCard = 8.5
sgs.ai_use_priority.keqipingjianCard = 9.5

ai_skill_use["@@keqipingjian"]=function(self,prompt,request)
    local dummy=load_plan(self,"keqipingjianUse")
   	if dummy.card then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,package_known(p,"objectName"))
       	end
       	return selected(self,dummy.card,tos)
    end
end


local keqiyizheng_skill = {}
keqiyizheng_skill.name = "keqiyizheng"
table.insert(package_skills, keqiyizheng_skill)
keqiyizheng_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","keqiyizhengCard") then return end
	return source_skill(self,"#keqiyizhengCard:.:")
end

sgs.ai_skill_use_func["#keqiyizhengCard"] = function(card,use,self,request)
    package_call(self,"sort",self.enemies,nil,true)
	local mc = package_call(self,"getMaxCard")
	if not mc or package_known(mc,"getNumber")<11 then return end
	for _, enemy in ipairs(self.enemies) do do
		if not package_known(self.player,"canPindian",enemy) or not package_known(self,"doDisCard",enemy,"h") then goto package_continue_6 end
		if package_known(self.player,"getHandcardNum")<package_known(enemy,"getHandcardNum") then
			local maxcard = package_call(self,"getMaxCard",enemy)
			if maxcard then
				local number = package_known(maxcard,"getNumber")
				if package_known(enemy,"hasSkill","tianbian") and package_known(maxcard,"getSuit")==sgs.Card_Heart then number = 13 end
				if number<package_known(mc,"getNumber") then
					use.card = card
					package_call(self,"setStrategyMemory","kearjsrgqi.keqiyizheng_card",package_known(mc,"getEffectiveId"))
					package_call(use.to,"append",enemy)
					return
				end
			end
		end
	end ::package_continue_6:: end
end

sgs.ai_use_value.keqiyizhengCard = 8.5
sgs.ai_use_priority.keqiyizhengCard = 3.5
sgs.ai_card_intention.keqiyizhengCard = 80

sgs.ai_skill_choice.keqiyizheng = function(self,choices,data)
	local from = package_call(data,"toPlayer")
	local items = package_known(choices,"split","+")
	if package_known(self,"isFriend",from) then
		if package_known(self,"isWeak",from) then
			return items[1]
		end
	elseif package_known(self,"isEnemy",from) then
		if package_known(self,"isWeak",from) then
			return items[3]
		end
	end
	return items[2]
end
sgs.ai_cardneed.keqiyizheng = sgs.ai_cardneed.bignumber

sgs.ai_can_damagehp.keqirangjie = function(self,from,card,to)
	return not(package_known(self,"isWeak",to) or (package_known(to,"hasSkill","keqizhaohan") and source_fact(self,"keqizhaohan","toInt") ~= 1))
	and package_known(self,"ajustDamage",from,to,1,card)>0 and package_known(self,"canLoseHp",from,card,to)
end

sgs.ai_skill_invoke.keqirangjie = function(self,data)
    return sgs.ai_skill_invoke.peiqi(self,data)
end

sgs.ai_skill_playerchosen["keqirangjie_from"] = function(self,players)
	for _,target in sgs.list(players)do
		if package_known(target,"objectName")==peiqi_state(self).package_known(from,"objectName")
		then return target end
	end
end

sgs.ai_skill_playerchosen["keqirangjie_to"] = function(self,players)
	for _,target in sgs.list(players)do
		if package_known(target,"objectName")==peiqi_state(self).package_known(to,"objectName")
		then return target end
	end
end

sgs.ai_skill_cardchosen.keqirangjie = function(self,who,flags,method)
	for _,e in sgs.list(package_known(who,"getCards",flags))do
		local id = package_known(e,"getEffectiveId")
		if id==peiqi_state(self).cid
		then return id end
	end
end


sgs.ai_skill_invoke.keqifendi = function(self,data)
    local target = package_call(data,"toPlayer")
	if not package_known(self,"isFriend",target) then return true end
	return false
end

sgs.ai_skill_invoke.keqijuxiang = function(self,data)
	local cp = package_call(self.room,"getCurrent")
	local move = package_known(data,"toMoveOneTime")
    if package_known(self,"isFriend",cp) and package_known(cp,"getPhase")<=sgs.Player_Play and getCardsNum("Slash",cp,self.player)>0
	and not package_known(self.player,"getStrategyFlag","keqijuxiang") and package_known(move.card_ids,"length")<=2 then
		package_call(self,"setStrategyPlayerFlag",self.player,"keqijuxiang",true)
		return #self.enemies>0
	end
end

sgs.ai_skill_cardchosen.keqifendi = function(self,who,flags,method)
	if package_known(self.disabled_ids,"length")>=package_known(who,"getHandcardNum")/2
	or package_known(self.disabled_ids,"length")>=math.random(1,package_known(who,"getHandcardNum"))
	then return -1 end
end
sgs.ai_cardneed.keqifendi = sgs.ai_cardneed.paoxiao
sgs.hit_skill = sgs.hit_skill .. "|keqifendi"


sgs.ai_skill_invoke.keqijizhanw = function(self,data)
    return true
end

sgs.ai_skill_choice.keqijizhanw = function(self,choices,data)
	local n = package_known(data,"toInt")
	local player = self.player
	local items = package_known(choices,"split","+")
	if n>6 then return items[2] end
	if n<7 then return items[1] end
	return items[2]
end


sgs.ai_skill_playerchosen.keqifusong = function(self,players)
	local player = self.player
	players = package_call(self,"sort",players,"card",true)
    for _,target in sgs.list(players)do
		if package_known(self,"isFriend",target)
		then return target end
	end
    for _,target in sgs.list(players)do
		if not package_known(self,"isEnemy",target)
		then return target end
	end
end









local kechengduxing_skill = {}
kechengduxing_skill.name = "kechengduxing"
table.insert(package_skills, kechengduxing_skill)
kechengduxing_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","kechengduxingCard") then return end
	return source_skill(self,"#kechengduxingCard:.:")
end

sgs.ai_skill_use_func["#kechengduxingCard"] = function(card,use,self,request)
	local dc = clone(self,"duel")
	package_call(dc,"setSkillName","kechengduxing")
	local d = package_known(self,"aiUseCard",dc,dummy(false,99))
	if d.card then
		local n = package_known(self,"getCardsNum","Slash")
		for _, p in sgs.list(d.to) do
			if n>=package_known(p,"getHandcardNum") or package_known(p,"isKongcheng") then
				n = n-package_known(p,"getHandcardNum")
				use.card = card
				if use.to then
					package_call(use.to,"append",p)
				end
			end
		end
	end
end

sgs.ai_use_value.kechengduxingCard = 8.5
sgs.ai_use_priority.kechengduxingCard = 4.5
sgs.ai_card_intention.kechengduxingCard = 66

sgs.ai_skill_invoke.kechengzhasi = function(self, data)
	return true
end

sgs.ai_canNiepan_skill.kechengzhasi = function(player)
	return package_known(player,"getStrategyMark","@kechengzhasi")>0
end

sgs.ai_skill_invoke.kechengbashi = function(self, data)
	return #self.friends_noself>0
end

sgs.ai_skill_cardask["kechengbashi_ask"] = function(self,data,pattern)
	local from = package_call(data,"toPlayer")
	local ct = "."
	if package_known(self,"isFriend",from) then
		if pattern=="jink" then
			ct = package_known(self,"getCardId","Jink")
		else
			ct = package_known(self,"getCardId","Slash")
		end
	end
    return ct or "."
end


local kechenglunshi_skill = {}
kechenglunshi_skill.name = "kechenglunshi"
table.insert(package_skills, kechenglunshi_skill)
kechenglunshi_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","kechenglunshiCard") then return end
	return source_skill(self,"#kechenglunshiCard:.:")
end

sgs.ai_skill_use_func["#kechenglunshiCard"] = function(card,use,self,request)
	local mp = 0
	local qp = 0
	for _,one in sgs.qlist(package_known(self.room,"getAllPlayers")) do
		mp = 0
		qp = 0
		for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",one)) do
			if package_known(one,"inMyAttackRange",p) then
				mp = mp + 1
			end
		end
		for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",one)) do
			if package_known(p,"inMyAttackRange",one) then
				qp = qp + 1
			end
		end
		if (package_known(one,"getHandcardNum") >= 5) then mp = 0 end
		if (package_known(one,"getHandcardNum") < 5) then mp = math.min(5-package_known(one,"getHandcardNum"),mp) end
		if (package_known(self,"isFriend",one) and (mp>=qp)) or (package_known(self,"isEnemy",one) and (mp<qp)) then
			use.card = card
			if use.to then package_call(use.to,"append",one) end
			break
		end
	end
end

sgs.ai_use_value.kechenglunshiCard = 8.5
sgs.ai_use_priority.kechenglunshiCard = 9.5
sgs.ai_card_intention.kechenglunshiCard = 80

sgs.ai_skill_playerschosen.kechengguitu = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets)
	local tos = {}
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) and package_known(p,"isWounded") then
			local pw = package_call(p,"getWeapon"):getRealCard():toWeapon():getRange()
			for _, p2 in ipairs(targets) do
				if not package_known(self,"isFriend",p2) then
					local p2w = package_call(p2,"getWeapon"):getRealCard():toWeapon():getRange()
					if p2w>pw then
						table.insert(tos, p)
						table.insert(tos, p2)
						return tos
					end
				end
			end
		end
	end
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) and package_known(p,"isWounded") then
			local pw = package_call(p,"getWeapon"):getRealCard():toWeapon():getRange()
			for _, p2 in ipairs(targets) do
				local p2w = package_call(p2,"getWeapon"):getRealCard():toWeapon():getRange()
				if p2w>pw then
					table.insert(tos, p)
					table.insert(tos, p2)
					return tos
				end
			end
		end
	end
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) then
			local w = package_call(p,"getWeapon")
			for _, p2 in ipairs(targets) do
				if not package_known(self,"isFriend",p2) and not package_known(p2,"isWounded") then
					local w2 = package_call(p2,"getWeapon")
					if package_known(self,"evaluateWeapon",w,p)<package_known(self,"evaluateWeapon",w2,p) then
						table.insert(tos, p)
						table.insert(tos, p2)
						return tos
					end
				end
			end
		end
	end
	return tos
end


sgs.ai_skill_playerchosen.kechengyechou = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if package_known(self,"isEnemy",p) then
		    return p
		end
	end
	return nil
end

sgs.ai_skill_playerschosen.kechengbiaozhao = function(self, targets)
	targets = sgs.QList2Table(targets)
	local tos = {}
	package_call(self,"sort",targets)
	for _, p in ipairs(targets) do
		if package_known(self,"isEnemy",p) then
			for _, p2 in ipairs(sgs.reverse(targets)) do
				if package_known(self,"isFriend",p2) then
					table.insert(tos, p2)
					table.insert(tos, p)
					return tos
				end
			end
		end
	end
	return tos
end



local kechengqingjiao_skill = {}
kechengqingjiao_skill.name = "kechengqingjiao"
table.insert(package_skills, kechengqingjiao_skill)
kechengqingjiao_skill.getTurnUseCard = function(self,inclusive,request)
	if ((package_known(self.player,"getStrategyMark","&useqingjiaochdj-Clear")>0) and (package_known(self.player,"getStrategyMark","&useqingjiaotxzf-Clear")>0))

	or package_known(self.player,"isNude")
	or #self.enemies == 0
	or (package_known(self.player,"getKingdom") ~= "qun")  then return end
	local card_id
	local cards = package_known(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local lightning = package_call(self,"getCard","Lightning")
	if package_known(self,"needToThrowArmor") then
		card_id = package_call(self.player,"getArmor"):getId()
	elseif package_known(self.player,"getHandcardNum") > package_known(self.player,"getHp") then
		if lightning and not package_known(self,"willUseLightning",lightning) then
			card_id = package_known(lightning,"getEffectiveId")
		else
			for _, acard in ipairs(cards) do
				if (package_known(acard,"isKindOf","BasicCard") or package_known(acard,"isKindOf","EquipCard") or package_known(acard,"isKindOf","AmazingGrace"))
					and not package_known(acard,"isKindOf","Peach") then
					card_id = package_known(acard,"getEffectiveId")
					break
				end
			end
		end
	elseif not package_known(self.player,"getEquips"):isEmpty() then
		local player = self.player
		if package_call(player,"getWeapon") then card_id = package_call(player,"getWeapon"):getId()
		elseif package_known(player,"getOffensiveHorse") then card_id = package_known(player,"getOffensiveHorse"):getId()
		elseif package_known(player,"getDefensiveHorse") then card_id = package_known(player,"getDefensiveHorse"):getId()
		elseif package_call(player,"getArmor") and package_known(player,"getHandcardNum") <= 1 then card_id = package_call(player,"getArmor"):getId()
		end
	end
	if not card_id then
		if lightning and not package_known(self,"willUseLightning",lightning) then
			card_id = package_known(lightning,"getEffectiveId")
		else
			for _, acard in ipairs(cards) do
				if (package_known(acard,"isKindOf","BasicCard") or package_known(acard,"isKindOf","EquipCard") or package_known(acard,"isKindOf","AmazingGrace"))
				  and not package_known(acard,"isKindOf","Peach") then
					card_id = package_known(acard,"getEffectiveId")
					break
				end
			end
		end
	end
	if not card_id then
	    return nil
	else
	    return source_skill(self,"#kechengqingjiaoCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#kechengqingjiaoCard"] = function(card,use,self,request)
    if (package_known(self.player,"getKingdom") == "qun") then
		if package_known(self.player,"getStrategyMark","&useqingjiaochdj-Clear")<1 then
			local room = self.room
			local all = package_known(room,"getOtherPlayers",self.player)
			local enys = sgs.SPlayerList()
			for _, p in sgs.qlist(all) do
				if package_known(self,"isEnemy",p) then
					if (package_known(p,"getHandcardNum") < package_known(self.player,"getHandcardNum"))
					and (package_known(self.player,"getStrategyMark","&useqingjiaochdj-Clear")<1) then
						package_call(enys,"append",p)
					end
				end
			end

			local pre = sgs.SPlayerList()
			local chdj = clone_native(self,"yj_chenhuodajie")
			package_call(chdj,"setSkillName","kechengqingjiao")
			package_call(chdj,"addSubcard",package_known(card,"getEffectiveId"))
			package_call(chdj,"deleteLater")
			for _, enemy in sgs.qlist(enys) do do
				if package_known(self.player,"isProhibited",enemy,chdj) then goto package_continue_7 end
				if package_known(pre,"isEmpty") then
					package_call(pre,"append",enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(pre) do
						if (package_known(enemy,"getHp")+package_known(enemy,"getHp")+package_known(enemy,"getHandcardNum")) >= (package_known(p,"getHp")+package_known(p,"getHp")+package_known(p,"getHandcardNum")) then
							yes = 0
						end
					end
					if (yes == 1) then
						package_known(pre,"removeOne",package_known(pre,"at",0))
						package_call(pre,"append",enemy)
					end
				end
			end ::package_continue_7:: end
			for _, p in sgs.qlist(pre) do
				use.card = card
				if use.to then
					package_call(use.to,"append",p)
				end
				return
			end
		end
		if package_known(self.player,"getStrategyMark","&useqingjiaotxzf-Clear")<1 then
			local all = package_known(self.room,"getOtherPlayers",self.player)
			local enys = sgs.SPlayerList()
			for _, p in sgs.qlist(all) do
				if package_known(self,"isEnemy",p) then
					if (package_known(p,"getHandcardNum") > package_known(self.player,"getHandcardNum"))
					and (package_known(self.player,"distanceTo",p)<=1)
					and (package_known(self.player,"getStrategyMark","&useqingjiaotxzf-Clear")<1) then
						package_call(enys,"append",p)
					end
				end
			end

			local pre = sgs.SPlayerList()
			local txzf = clone_native(self,"yj_tuixinzhifu")
			package_call(txzf,"setSkillName","kechengqingjiao")
			package_call(txzf,"addSubcard",package_known(card,"getEffectiveId"))
			package_call(txzf,"deleteLater")
			for _, enemy in sgs.qlist(enys) do do
				if not package_known(self.player,"canUse",txzf,enemy) then goto package_continue_8 end
				if package_known(pre,"isEmpty") then
					package_call(pre,"append",enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(pre) do
						if (package_known(enemy,"getHp")+package_known(enemy,"getHp")+package_known(enemy,"getHandcardNum")) < (package_known(p,"getHp")+package_known(p,"getHp")+package_known(p,"getHandcardNum")) then
							yes = 0
						end
					end
					if (yes == 1) then
						package_known(pre,"removeOne",package_known(pre,"at",0))
						package_call(pre,"append",enemy)
					end
				end
			end ::package_continue_8:: end
			for _, p in sgs.qlist(pre) do
				use.card = card
				if use.to then
					package_call(use.to,"append",p)
				end
				return
			end
		end
	end
end

sgs.ai_use_value.kechengqingjiaoCard = 8.5
sgs.ai_use_priority.kechengqingjiaoCard = 9.5
sgs.ai_card_intention.kechengqingjiaoCard = 80

sgs.ai_skill_cardask["_kecheng_chenhuodajie0"] = function(self,data,pattern,prompt)
	local c = package_known(self,"getKnownCardById",pattern)
	if c then
		if package_known(self,"isWeak") and package_known(c,"isKindOf","Analeptic")
		or package_known(self,"getKeepValue",c)>5.3
		then return "." end
		return package_known(c,"getEffectiveId")
	end
end

sgs.ai_cardneed.kechengqingjiao = function(to, card, self)
	return true
end








sgs.ai_skill_choice.kechenglipan = function(self, choices)
	local items = package_known(choices,"split","+")
	local ks = {}
	for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		ks[package_known(p,"getKingdom")] = (ks[package_known(p,"getKingdom")] or 0)+1
	end
	local x = 0
	for k, n in pairs(ks) do
		if n>x then x = n end
	end
	for k, n in pairs(ks) do
		if n>=x and table.contains(items, k) and package_known(self.player,"getKingdom") ~= k then
			if k=="qun" or k == "wei" then
				return k
			end
		end
	end
	for k, n in pairs(ks) do
		if n>=x and table.contains(items, k) and package_known(self.player,"getKingdom") ~= k then
			return k
		end
	end
	if package_known(self.player,"getKingdom") ~= "qun" then
	    return "qun"
	elseif package_known(self.player,"getKingdom") ~= "wei" then
	    return "wei"
	end
end

sgs.ai_skill_invoke.lipanuseduel = function(self, data)
	return (package_known(self.player,"getStrategyMark","wantuselipan-Clear") > 0)
end

sgs.ai_skill_invoke.kechenglipan = function(self, data)
	return true
end

sgs.ai_skill_discard.kechenglipan = function(self)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local from = package_call(self.room,"getCurrent")
	if package_known(self,"isEnemy",from) then
		return {package_known(cards[1],"getEffectiveId")}
	end
	return to_discard
end

local kechengqingxi_skill = {}
kechengqingxi_skill.name = "kechengqingxi"
table.insert(package_skills, kechengqingxi_skill)
kechengqingxi_skill.getTurnUseCard = function(self,inclusive,request)
	return source_skill(self,"#kechengqingxiCard:.:")
end

sgs.ai_skill_use_func["#kechengqingxiCard"] = function(card,use,self,request)
	local enys = sgs.SPlayerList()
	for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(p,"getStrategyMark","beusekechengqingxi-PlayClear")>0
		then package_call(enys,"append",p) end
	end
	local dc = clone(self,"yj_stabs_slash")
	package_call(dc,"setSkillName","kechengqingxi")
	local d = package_known(self,"aiUseCard",dc,dummy(nil,99,enys))
	if d.card then
		local cards = package_known(self.player,"getHandcards")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards,nil,"j")
		for _,p in sgs.qlist(d.to) do
			local n = package_known(self.player,"getHandcardNum")-package_known(p,"getHandcardNum")
			if n>0 and #cards>=n then
				enys = {}
				for _,c in sgs.list(cards) do
					table.insert(enys, package_known(c,"getId"))
					if #cards>=n then break end
				end
				use.card = source_skill(self,"#kechengqingxiCard:"..table.concat(enys,"+")..":")
				package_call(use.to,"append",p)
				break
			end
		end
	end
end

sgs.ai_use_value.kechengqingxiCard = 8.5
sgs.ai_use_priority.kechengqingxiCard = 2.5
sgs.ai_card_intention.kechengqingxiCard = 66


local kechengjinmie_skill = {}
kechengjinmie_skill.name = "kechengjinmie"
table.insert(package_skills, kechengjinmie_skill)
kechengjinmie_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","kechengjinmieCard") then return end
	return source_skill(self,"#kechengjinmieCard:.:")
end

sgs.ai_skill_use_func["#kechengjinmieCard"] = function(card,use,self,request)
    if (not package_known(self.player,"hasUsed","#kechengjinmieCard")) and (package_known(self.player,"getKingdom") == "wei") then
        package_call(self,"sort",self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if (package_known(enemy,"getHandcardNum") > package_known(self.player,"getHandcardNum")) then
				if package_known(self,"isEnemy",enemy) then
					package_call(enys,"append",enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(enys) do
						if (package_known(enemy,"getHp")+package_known(enemy,"getHp")+package_known(enemy,"getHandcardNum")) >= (package_known(p,"getHp")+package_known(p,"getHp")+package_known(p,"getHandcardNum")) then
							yes = 0
						end
					end
					if (yes == 1) then
						package_known(enys,"removeOne",package_known(enys,"at",0))
						package_call(enys,"append",enemy)
					end
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			if package_known(self,"objectiveLevel",enemy) > 0 then
				use.card = card
				if use.to then package_call(use.to,"append",enemy) end
				break
			end
		end
	end
end

sgs.ai_use_value.kechengjinmieCard = 8.5
sgs.ai_use_priority.kechengjinmieCard = 2.5
sgs.ai_card_intention.kechengjinmieCard = 80



sgs.ai_guhuo_card.kechengqongtu = function(self,cname,class_name)
    if package_known(self,"getCardsNum",class_name)>0 then return end
	local handcards = package_known(self.player,"getCards","he")
    handcards = package_call(self,"sortByKeepValue",handcards)
	for _, h in ipairs(handcards) do
    	if package_known(h,"getTypeId")~=1 then
			return skill_proposal("#kechengqongtuCard",{package_known(handcards[1],"getEffectiveId")},cname)
		end
	end
end

sgs.ai_skill_choice.kechengzhanghe_ChooseKingdom = function(self, choices)
	local items = package_known(choices,"split","+")
	return "wei"
end

sgs.ai_view_as.kechengxianzhu = function(card, player, card_place)
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if card_place ~= sgs.Player_PlaceSpecial and (package_known(player,"getKingdom") == "wei") and package_known(card,"isNDTrick") and not package_known(card,"hasFlag","using") then
		return {name="slash",skill="kechengxianzhu",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
	end
end

local kechengxianzhu_skill = {}
kechengxianzhu_skill.name = "kechengxianzhu"
table.insert(package_skills, kechengxianzhu_skill)
kechengxianzhu_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getKingdom") == "wei" then
		local cards = package_known(self.player,"getCards","h")
		cards = sgs.QList2Table(cards)
		local red_card
		package_call(self,"sortByUseValue",cards, true)

		local useAll = false
		package_call(self,"sort",self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if package_known(enemy,"getHp") == 1 and not package_known(enemy,"hasArmorEffect","EightDiagram") and package_known(self.player,"distanceTo",enemy) <= package_known(self.player,"getAttackRange") and package_known(self,"isWeak",enemy)
				and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
				break
			end
		end

		local disCrossbow = false
		if package_known(self,"getCardsNum","Slash") < 2 or package_known(self.player,"hasSkills","paoxiao|tenyearpaoxiao|olpaoxiao") then
			disCrossbow = true
		end

		local nuzhan_equip = false
		local nuzhan_equip_e = false
		package_call(self,"sort",self.enemies, "defense")
		if package_known(self.player,"hasSkill","nuzhan") then
			for _, enemy in ipairs(self.enemies) do
				if  not package_known(enemy,"hasArmorEffect","EightDiagram") and package_known(self.player,"distanceTo",enemy) <= package_known(self.player,"getAttackRange")
				and getCardsNum("Jink", enemy) < 1 then
					nuzhan_equip_e = true
					break
				end
			end
			for _, card in ipairs(cards) do
				if package_known(card,"isNDTrick") and nuzhan_equip_e then
					nuzhan_equip = true
					break
				end
			end
		end

		local nuzhan_trick = false
		local nuzhan_trick_e = false
		package_call(self,"sort",self.enemies, "defense")
		if package_known(self.player,"hasSkill","nuzhan") and not package_known(self.player,"getStrategyFlag","hasUsedSlash") and package_known(self,"getCardsNum","Slash") > 1 then
			for _, enemy in ipairs(self.enemies) do
				if  not package_known(enemy,"hasArmorEffect","EightDiagram") and package_known(self.player,"distanceTo",enemy) <= package_known(self.player,"getAttackRange") then
					nuzhan_trick_e = true
					break
				end
			end
			for _, card in ipairs(cards) do
				if package_known(card,"isNDTrick") and nuzhan_trick_e then
					nuzhan_trick = true
					break
				end
			end
		end

		for _, card in ipairs(cards) do
			if package_known(card,"isNDTrick") and not (nuzhan_equip or nuzhan_trick)
				and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
				and (not isCard("Crossbow", card, self.player) or disCrossbow)
				and (package_known(self,"getUseValue",card) < sgs.ai_use_value.Slash or inclusive or package_known(package_known(self,"getEvaluationCard","slash"),"getTargetModResidue",self.player) > 0) then
				red_card = card
				break
			end
		end

		if nuzhan_equip then
			for _, card in ipairs(cards) do
				if package_known(card,"isNDTrick") and package_known(card,"isKindOf","EquipCard") then
					red_card = card
					break
				end
			end
		end

		if nuzhan_trick then
			for _, card in ipairs(cards) do
				if package_known(card,"isNDTrick") and package_known(card,"isKindOf","TrickCard")then
					red_card = card
					break
				end
			end
		end

		if red_card then
			local suit = package_known(red_card,"getSuitString")
			local number = package_known(red_card,"getNumberString")
			local card_id = package_known(red_card,"getEffectiveId")
			local card_str = ("slash:kechengxianzhu[%s:%s]=%d"):format(suit, number, card_id)
			local slash=clone(self,"slash","kechengxianzhu",package_known(red_card,"getSuit"),package_known(red_card,"getNumber"));package_call(slash,"addSubcard",red_card)

			assert(slash)
			return slash
		end
	end
end

function sgs.ai_cardneed.kechengxianzhu(to, card)
	return package_known(card,"isNDTrick")
end

sgs.ai_use_priority["kechengxianzhu"] = 9



local kechengnianen_skill = {}
kechengnianen_skill.name = "kechengnianen"
table.insert(package_skills, kechengnianen_skill)
kechengnianen_skill.getTurnUseCard = function(self,inclusive,request)
	local handcards = package_known(self,"addHandPile","he")
	package_call(self,"sortByKeepValue",handcards)
	local dc = clone(self)
	if dc and package_known(dc,"isKindOf","BasicCard") then
		package_call(dc,"setSkillName","kechengnianen")
		for _, h in ipairs(handcards)do do
			if not package_known(h,"isRed") then goto package_continue_9 end
			package_call(dc,"addSubcard",h)
			if package_known(dc,"isAvailable",self.player) then
				local d = package_known(self,"aiUseCard",dc)
				if d.card then
					return dc
				end
			end
			package_call(dc,"clearSubcards")
		end ::package_continue_9:: end
	end
	for _,pn in ipairs(patterns_for(self))do
		local dc = clone(self,pn)
		if dc and package_known(dc,"isKindOf","BasicCard") then
			package_call(dc,"setSkillName","kechengnianen")
			for _, h in ipairs(handcards)do
				package_call(dc,"addSubcard",h)
				if package_known(dc,"isAvailable",self.player) then
					local d = package_known(self,"aiUseCard",dc)
					if d.card then
						return dc
					end
				end
				package_call(dc,"clearSubcards")
			end
		end
	end
end

sgs.ai_skill_use_func["#kechengnianenCard"] = function(card,use,self,request)
	if (package_known(self.player,"getStrategyMark","&bannianen-Clear") == 0) then
		local userstring = package_known(card,"toString")
		userstring = (package_known(userstring,"split",":"))[4]
		local kechengnianencard = clone_native(self,userstring, package_known(card,"getSuit"), package_known(card,"getNumber"))
		package_call(kechengnianencard,"setSkillName","kechengnianen")
		package_call(self,"useBasicCard",kechengnianencard, use)
		if not use.card then return end
		use.card = card
	end
end

sgs.ai_use_priority["kechengnianenCard"] = 9
sgs.ai_use_value["kechengnianenCard"] = 9

sgs.ai_cardsview["kechengnianen"] = function(self,class_name,player)
	local handcards = package_known(self,"addHandPile","he")
	for _, c in sgs.list(handcards) do
		if package_known(c,"isKindOf",class_name)
		then return end
	end
	package_call(self,"sortByKeepValue",handcards)
	if class_name=="Slash" then
		for _, c in ipairs(handcards) do
			if package_known(c,"isRed") then
				local dc = clone(self)
				package_call(dc,"setSkillName","kechengnianen")
				package_call(dc,"addSubcard",c)
				if not package_known(player,"isLocked",dc) then
					return proposal(self,dc)
				end
			end
		end
	end
	local cn = patterns_for(self,class_name)
	for _, c in ipairs(handcards) do
		local dc = clone(self,cn)
		package_call(dc,"setSkillName","kechengnianen")
		package_call(dc,"addSubcard",c)
		if not package_known(player,"isLocked",dc) then
			return proposal(self,dc)
		end
	end
end

function sgs.ai_cardneed.kechengnianen(to, card, self)
	if (package_known(to,"getStrategyMark","&bannianen-Clear") > 0) then return false end
	return true
end



local kechengzhengbing_skill = {}
kechengzhengbing_skill.name = "kechengzhengbing"
table.insert(package_skills, kechengzhengbing_skill)
kechengzhengbing_skill.getTurnUseCard = function(self,inclusive,request)
	if (package_known(self.player,"getStrategyMark","kechengzhengbing-Clear") >= 3) or (package_known(self.player,"getKingdom") ~= "qun") or (package_known(self.player,"isKongcheng")) then return end
	local card_id
	local cards = package_known(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	if (package_known(self.player,"getStrategyMark","kechengzhengbing-Clear") <= 1) then
		local yes = 0
		local to_throw = sgs.IntList()
		for _, acard in ipairs(cards) do
			if package_known(acard,"isKindOf","Jink") then
				card_id = package_known(acard,"getEffectiveId")
				yes = 1
				break
			end
		end
		if yes == 0 then
			for _, acard in ipairs(cards) do
				package_call(to_throw,"append",package_known(acard,"getEffectiveId"))
			end
			card_id = package_known(to_throw,"at",0)
		end
		if not card_id then
			return nil
		else
			return source_skill(self,"#kechengzhengbingCard:"..card_id..":")
		end
	else
		local to_throw = sgs.IntList()
		for _, acard in ipairs(cards) do
			package_call(to_throw,"append",package_known(acard,"getEffectiveId"))
		end
		card_id = package_known(to_throw,"at",0)
		if not card_id then
			return nil
		else
			return source_skill(self,"#kechengzhengbingCard:"..card_id..":")
		end
	end
end

sgs.ai_skill_use_func["#kechengzhengbingCard"] = function(card,use,self,request)
    if (package_known(self.player,"getStrategyMark","kechengzhengbing-Clear") < 3) then
        use.card = card
	    return
	end
end

function sgs.ai_cardneed.kechengzhengbing(to, card, self)
	if (package_known(self.player,"getStrategyMark","kechengzhengbing-Clear") >= 3) then return false end
	return true
end

sgs.ai_use_value.kechengzhengbingCard = 8.5
sgs.ai_use_priority.kechengzhengbingCard = 9.5
sgs.ai_card_intention.kechengzhengbingCard = -80

sgs.ai_skill_playerschosen.kechengtuwei = function(self, targets)
	targets = sgs.QList2Table(targets)
	local tos = {}
	package_call(self,"sort",targets)
	for _, p in ipairs(targets) do
		if package_known(self,"doDisCard",p,"he",true) then
			table.insert(tos, p)
		end
	end
	return tos
end



sgs.ai_skill_invoke.kechengguyin = function(self, data)
	return math.random(0,package_known(self.player,"getStrategyMark","&kechengguyinmale"))>1
	or package_known(self,"isWeak")
end

sgs.ai_skill_invoke.kechengguyinturnover = function(self, data)
	return math.random(0,1)>0 and package_known(self.player,"getHandcardNum")<3
	or package_known(self,"isWeak")
end

local kechengzhangdengex = {}
kechengzhangdengex.name = "kechengzhangdengex"
table.insert(package_skills, kechengzhangdengex)
kechengzhangdengex.getTurnUseCard = function(self,inclusive,request)
	local dc = clone(self,"analeptic")
	package_call(dc,"setSkillName","_kechengzhangdeng")
	local d = package_known(self,"aiUseCard",dc)
	if d.card then
		return source_skill(self,"#kechengzhangdengCard:.:")
	end
end

sgs.ai_skill_use_func["#kechengzhangdengCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.kechengzhangdengCard = 8.5
sgs.ai_use_priority.kechengzhangdengCard = sgs.ai_use_priority.Analeptic

sgs.ai_cardsview.kechengzhangdengex = function(self,class_name,player)
	return skill_proposal("#kechengzhangdengCard",{})
end


sgs.ai_skill_invoke.kechengyirang = function(self, data)
	for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(self,"isFriend",p) and package_known(p,"getMaxHp")>package_known(self.player,"getMaxHp") then
			return true
		end
	end
	for _,p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if not package_known(self,"isEnemy",p) and package_known(p,"getMaxHp")>=package_known(self.player,"getMaxHp") and package_known(self,"isWeak") then
			return true
		end
	end
end

sgs.ai_skill_playerchosen.kechengyirang = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets,"maxhp",true)
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) and package_known(p,"getMaxHp")>=package_known(self.player,"getMaxHp") then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if not package_known(self,"isEnemy",p) and package_known(p,"getMaxHp")>=package_known(self.player,"getMaxHp") then
			return p
		end
	end
end


sgs.ai_skill_discard.kechengjixiang = function(self)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local to = source_fact(self,"kechengjixiangTo","toPlayer")
	if package_known(self,"isFriend",to) then
		return {package_known(cards[1],"getEffectiveId")}
	end
	return to_discard
end

sgs.ai_cardsview["kechengjixiangex"] = function(self,class_name,player)
	local cp = package_call(self.room,"getCurrent")
	local pn = patterns_for(self,class_name)
	if not package_known(self,"isEnemy",cp) and package_known(cp,"getStrategyMark",pn.."kechengjixiang-Clear")<1 then
		return skill_proposal("#kechengjixiangCard",{},pn)
	end
end

local kechengchengxian = {}
kechengchengxian.name = "kechengchengxian"
table.insert(package_skills, kechengchengxian)
kechengchengxian.getTurnUseCard = function(self,inclusive,request)
	local cans = {}
	for _,h in sgs.qlist(package_known(self.player,"getHandcards")) do
		if package_known(h,"isAvailable",self.player) then
			table.insert(cans, h)
		end
	end
	package_call(self,"sortByKeepValue",cans)
	for _, h in ipairs(cans) do do
		local trannum = source_targets(self,h):length()
		if package_known(h,"isKindOf","AOE") or package_known(h,"isKindOf","GlobalEffect") then
		elseif package_known(h,"targetFixed") then trannum = 1 end
		if trannum<1 then goto package_continue_10 end
	for _, pn in ipairs(patterns_for(self)) do do
		local dc = clone(self,pn)
		if dc and package_known(self.player,"getStrategyMark",pn.."kechengchengxian-Clear")<1 and package_known(dc,"isNDTrick")
		and package_known(dc,"isDamageCard") and package_known(self,"getCardsNum",package_known(dc,"getClassName"))<1 then
			package_call(dc,"setSkillName","kechengchengxian")
				package_call(dc,"addSubcard",h)
					local orinum = source_targets(self,dc):length()
					if package_known(dc,"isKindOf","AOE") or package_known(dc,"isKindOf","GlobalEffect") then
					elseif package_known(dc,"targetFixed") then orinum = 1 end
				if trannum==orinum and package_known(dc,"isAvailable",self.player) then
						local d = package_known(self,"aiUseCard",dc)
						if d.card then
							save_plan(self,"kechengchengxianUse",d)
							package_call(self,"setStrategyMemory","kearjsrgqi.choice.kechengchengxian",pn)
							if package_known(dc,"canRecast") and package_known(d.to,"isEmpty") then goto package_continue_11 end
							package_call(self,"setPriorityValue","kechengchengxianCard",package_known(self,"getPriorityValue",package_known(dc,"getClassName")))
							return source_skill(self,"#kechengchengxianCard:"..package_known(h,"getId")..":")
						end
					end
				end
	end ::package_continue_11:: end
	for _, pn in ipairs(patterns_for(self)) do do
		local dc = clone(self,pn)
		if dc and package_known(self.player,"getStrategyMark",pn.."kechengchengxian-Clear")<1
		and package_known(dc,"isNDTrick") and package_known(self,"getCardsNum",package_known(dc,"getClassName"))<1 then
			package_call(dc,"setSkillName","kechengchengxian")
				package_call(dc,"addSubcard",h)
					local orinum = source_targets(self,dc):length()
					if package_known(dc,"isKindOf","AOE") or package_known(dc,"isKindOf","GlobalEffect") then
					elseif package_known(dc,"targetFixed") then orinum = 1 end
				if trannum==orinum and package_known(dc,"isAvailable",self.player) then
						local d = package_known(self,"aiUseCard",dc)
						if d.card then
							save_plan(self,"kechengchengxianUse",d)
							package_call(self,"setStrategyMemory","kearjsrgqi.choice.kechengchengxian",pn)
							if package_known(dc,"canRecast") and package_known(d.to,"isEmpty") then goto package_continue_12 end
							package_call(self,"setPriorityValue","kechengchengxianCard",package_known(self,"getPriorityValue",package_known(dc,"getClassName")))
							return source_skill(self,"#kechengchengxianCard:"..package_known(h,"getId")..":")
						end
					end
				end
		end ::package_continue_12:: end
	end ::package_continue_10:: end
end

sgs.ai_skill_use_func["#kechengchengxianCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.kechengchengxianCard = 8.5
sgs.ai_use_priority.kechengchengxianCard = 6.6

ai_skill_use["@@kechengchengxian"]=function(self,prompt,request)
    local dummy=load_plan(self,"kechengchengxianUse")
   	if dummy.card and dummy.to then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,package_known(p,"objectName"))
       	end
       	return selected(self,dummy.card,tos)
    end
end



sgs.ai_skill_invoke.kechengneifa = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kechengneifa = function(self, targets)
	targets = sgs.QList2Table(targets)
	local data = package_known(self.room,"getTag","kechengneifa")
	if sgs.ai_skill_choice.sheyan(self,"remove", data) == "remove" then
		if self.sheyan_remove_target then
			return self.sheyan_remove_target
		end
	end
	return nil
end

sgs.ai_skill_discard.kechengneifa = function(self)
	local to_discard = {}
	local slashnum = 0
	local ndnum = 0
	for _,c in sgs.qlist(package_known(self.player,"getCards","h")) do
		if package_known(c,"isKindOf","Slash") then
			slashnum = slashnum + 1
		elseif package_known(c,"isNDTrick") then
			ndnum = ndnum + 1
		end
	end
	if (slashnum > ndnum) then
		for _,c in sgs.qlist(package_known(self.player,"getCards","h")) do
			if package_known(c,"isKindOf","Slash") then
				if (#to_discard == 0) then
				    table.insert(to_discard, package_known(c,"getEffectiveId"))
				end
			end
		end
	elseif (slashnum < ndnum) then
		for _,c in sgs.qlist(package_known(self.player,"getCards","h")) do
			if package_known(c,"isNDTrick") then
				if (#to_discard == 0) then
				    table.insert(to_discard, package_known(c,"getEffectiveId"))
				end
			end
		end
	end
	if (#to_discard == 0) then
		for _,c in sgs.qlist(package_known(self.player,"getCards","h")) do
			if (#to_discard == 0) then
			    table.insert(to_discard, package_known(c,"getEffectiveId"))
			end
		end
	end
	return to_discard
end


sgs.ai_skill_playerschosen.kechengcangchu = function(self, targets,x,n)
	targets = sgs.QList2Table(targets)
	local tos = {}
	package_call(self,"sort",targets)
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) and #tos<x then
			table.insert(tos, p)
		end
	end
	return tos
end


sgs.ai_use_revises.kechengshishou = function(self,card,use)
	if package_known(card,"isKindOf","Analeptic") and package_known(self.player,"getPhase")==sgs.Player_Play then
		return #self.toUse<2
	end
end


ai_card_use.KCTuixinzhifu=function(self,card,use)
	package_call(self,"sort",self.friends_noself,"hp")
	local extraTarget = package_known(card,"getTargetModExtraTarget",self.player)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.friends_noself)do do
		if isCurrent(use,ep) then goto package_continue_13 end
		if CanToCard(card,self.player,ep)
		and package_known(self,"doDisCard",ep,"ej")
		then
	    	use.card = card
			package_call(use.to,"append",ep)
	    	if package_known(use.to,"length")>extraTarget
			then return end
		end
	end ::package_continue_13:: end
	package_call(self,"sort",self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do do
		if isCurrent(use,ep) then goto package_continue_14 end
		if CanToCard(card,self.player,ep)
		and package_known(self,"doDisCard",ep,"ej")
		then
	    	use.card = card
			package_call(use.to,"append",ep)
	    	if package_known(use.to,"length")>extraTarget
			then return end
		end
	end ::package_continue_14:: end
	for _,ep in sgs.list(self.enemies)do do
		if isCurrent(use,ep) then goto package_continue_15 end
		if CanToCard(card,self.player,ep)
		and package_known(self,"doDisCard",ep,"hej")
		then
	    	use.card = card
			package_call(use.to,"append",ep)
	    	if package_known(use.to,"length")>extraTarget
			then return end
		end
	end ::package_continue_15:: end
	local tos = package_known(self.room,"getAlivePlayers")
	tos = package_call(self,"sort",tos,"card",true)
	for _,ep in sgs.list(tos)do do
		if isCurrent(use,ep) then goto package_continue_16 end
		if CanToCard(card,self.player,ep)
		and package_known(ep,"getCardCount")>1
		then
	    	use.card = card
			package_call(use.to,"append",ep)
	    	if package_known(use.to,"length")>extraTarget
			then return end
		end
	end ::package_continue_16:: end
end
sgs.ai_use_priority.KCTuixinzhifu = 5.4
sgs.ai_keep_value.KCTuixinzhifu = 2.2
sgs.ai_use_value.KCTuixinzhifu = 4.7

sgs.ai_skill_cardchosen._kecheng_tuixinzhifu = function(self,who)
	for i,c in sgs.list(package_known(who,"getCards","ej"))do
		i = package_known(c,"getEffectiveId")
		if package_known(self,"doDisCard",who,i,true)
		then return i end
	end
	for i=1,package_known(who,"getHandcardNum")do do
		i = package_known(who,"getRandomHandCardId")
		if package_known(self.disabled_ids,"contains",i)
		then goto package_continue_17 end
		return i
	end ::package_continue_17:: end
	for i=1,99 do
		i = package_known(self,"getCardRandomly",who,"hej")
		if package_known(self,"doDisCard",who,i,true)
		then return i end
	end
	return -1
end

sgs.ai_skill_discard._kecheng_tuixinzhifu = function(self,x,n)
	local to_cards = {}
	local target = source_fact(self,"_kecheng_tuixinzhifu","toPlayer")
	local cards = package_known(self.player,"getHandcards")
	cards = package_call(self,"sortByKeepValue",cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=n then return to_cards end
		if table.contains(package_known(self,"poisonCards"),h) and not package_known(self,"isFriend",target)
		then table.insert(to_cards,package_known(h,"getEffectiveId")) end
	end
   	for i,h in sgs.list(cards)do do
   		if #to_cards>=n then return to_cards end
		if table.contains(to_cards,package_known(h,"getEffectiveId")) then goto package_continue_18 end
		if i>=#cards/2 and package_known(self,"isFriend",target)
		then table.insert(to_cards,package_known(h,"getEffectiveId")) end
	end ::package_continue_18:: end
   	for _,h in sgs.list(cards)do do
   		if #to_cards>=n then return to_cards end
		if table.contains(to_cards,package_known(h,"getEffectiveId")) then goto package_continue_19 end
       	table.insert(to_cards,package_known(h,"getEffectiveId"))
	end ::package_continue_19:: end
end

sgs.ai_nullification.KCTuixinzhifu = function(self,trick,from,to,positive)
    local n = package_known(self,"getCardsNum","Nullification")
	if n>1
	and (package_known(to,"hasEquip") or package_known(to,"getJudgingArea"):length()>0)
	then
		if positive
		then
			return package_known(self,"isFriend",to)
			and package_known(self,"isEnemy",from)
		else
			return package_known(self,"isEnemy",to)
			and package_known(self,"isEnemy",from)
		end
	elseif package_known(to,"getCardCount",true,true)>0
	and (package_call(to,"getArmor") or package_known(to,"getDefensiveHorse") or package_known(to,"getHandcardNum")<2 or package_known(to,"getJudgingArea"):length()>0)
	then
		if positive
		then
			return package_known(self,"isFriend",to)
			and package_known(self,"isEnemy",from)
		else
			return package_known(self,"isEnemy",to)
			and package_known(self,"isEnemy",from)
		end
	end
end






sgs.ai_skill_playerschosen.kezhuanqingzi = function(self, targets)
	targets = sgs.QList2Table(targets)
	local tos = {}
	for _, p in ipairs(targets) do
		if package_known(self,"doDisCard",p,"e") then
			table.insert(tos,p)
		end
	end
	return tos
end

sgs.ai_skill_invoke.kezhuandingce = function(self, data)
	local from = package_call(data,"toPlayer")
	if from==self.player then
		return package_known(from,"getHandcardNum") >= 4
	elseif package_known(self,"isFriend",from) then
		return package_known(from,"getHandcardNum")>package_known(from,"getHp")
	else
		return true
	end
end

sgs.ai_skill_cardchosen.kezhuandingce = function(self,who)
	local player = self.player
	if package_known(who,"hasFlag","bestdingcered") then
		for _,c in sgs.qlist(package_known(who,"getCards","h")) do
			if package_known(c,"isRed") then
				return package_known(c,"getId")
			end
		end
	else
		for _,c in sgs.qlist(package_known(who,"getCards","h")) do
			if package_known(c,"isBlack") then
				return package_known(c,"getId")
			end
		end
	end
	return -1
end

local kezhuanzhenfeng={}
kezhuanzhenfeng.name="kezhuanzhenfeng"
table.insert(package_skills,kezhuanzhenfeng)
kezhuanzhenfeng.getTurnUseCard = function(self,inclusive,request)
	for _,p in sgs.list(fact(self,"zhuanJfNames"))do do
		local dc = clone(self,p)
		package_call(dc,"setSkillName","kezhuanzhenfeng")
		if package_known(dc,"isKindOf","Dongzhuxianji") and package_known(self.player,"hasSkill","kezhuandingce",true)
		and package_known(self,"isWeak") or not package_known(dc,"isAvailable",self.player) then goto package_continue_20 end
		local dummy = package_known(self,"aiUseCard",dc)
		if dummy.card and dummy.to then
			save_plan(self,"kezhuanzhenfengData",dummy)
			package_call(self,"setStrategyMemory","kearjsrgqi.choice.kezhuanzhenfeng",unobserved_global(self,"choice"))
			if (package_known(dummy.to,"isEmpty") and package_known(dc,"canRecast"))  then goto package_continue_20 end
			package_call(self,"setPriorityValue","kezhuancuifengCard",package_known(self,"getPriorityValue",package_known(dc,"getClassName")))
			return source_skill(self,"#kezhuanzhenfengCard:.:")
		end
	end ::package_continue_20:: end
end

sgs.ai_skill_use_func["#kezhuanzhenfengCard"] = function(card,use,self,request)
   	use.card = card
end

sgs.ai_use_value.kezhuanzhenfengCard = 6.4
sgs.ai_use_priority.kezhuanzhenfengCard = 6.4

ai_skill_use["@@kezhuanzhenfeng"]=function(self,prompt,request)
	local dummy=load_plan(self,"kezhuanzhenfengData")
	if dummy.card and dummy.to then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,package_known(p,"objectName"))
		end
		return selected(self,dummy.card,tos)
	end
end



sgs.ai_skill_askforyiji.kezhuanfuni = function(self,card_ids,tos)
	local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to and id then return to,id end
	for _,p in sgs.list(tos)do
		if not package_known(self,"isFriend",p)
		and not package_known(p,"getStrategyFlag","kezhuanfuniAi") then
			package_call(self,"setStrategyPlayerFlag",p,"kezhuanfuniAi",true)
			return p,card_ids[1]
		end
	end
	return package_known(tos,"first"),card_ids[1]
end

ai_skill_use["@@kezhuanchuanxin"]=function(self,prompt,request)
    local cards = package_known(self.player,"getCards","he")
    cards = sgs.QList2Table(cards)
    package_call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do do
    	local c = clone(self)
		package_call(c,"setSkillName","kezhuanchuanxin")
		package_call(c,"addSubcard",h)
		if package_known(self.player,"isLocked",c) then goto package_continue_21 end
		local dummy = package_known(self,"aiUseCard",c)
		if dummy.card then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,package_known(p,"objectName"))
			end
			return selected(self,c,tos)

		end
	end ::package_continue_21:: end
end



sgs.ai_skill_invoke.kezhuanzhuiming = function(self, data)
	local to = package_call(data,"toPlayer")
	return package_known(self,"isEnemy",to)
	or not package_known(self,"isFriend",to) and #self.enemies>0
end

sgs.ai_skill_choice.kezhuanzhuiming = function(self, choices, data)
	local items = package_known(choices,"split","+")
	local to = package_call(data,"toPlayer")
	package_call(self,"setStrategyMemory","kearjsrgqi.zhuimingColor",items[1])
	for _,h in sgs.list(getKnownCards(to,self.player,"he"))do
		if package_known(choices,"contains",package_known(h,"getColorString")) then
			package_call(self,"setStrategyMemory","kearjsrgqi.zhuimingColor",package_known(h,"getColorString"))
			return package_known(h,"getColorString")
		end
	end
	return items[1]
end


sgs.ai_skill_cardchosen.kezhuanzhuiming = function(self,who)
	for _,h in sgs.list(getKnownCards(who,self.player,"he"))do
		if package_known(h,"getColorString")==memory(self,"zhuimingColor") then
			return package_known(h,"getId")
		end
	end
end

sgs.ai_skill_discard.kezhuanzhuiming = function(self)
	local to_discard = {}
	if package_known(self.player,"getHp")+package_known(self,"getCardsNum","Peach,Analeptic")<3 then
		local from = source_fact(self,"kezhuanzhuimingFrom","toPlayer")
		for _,h in sgs.list(getKnownCards(self.player,from,"he"))do
			if package_known(h,"getColorString")==memory(self,"zhuimingColor") then
				table.insert(to_discard, package_known(h,"getEffectiveId"))
			end
		end
	end
	return to_discard
end



sgs.ai_skill_discard.kezhuanbaohe = function(self)
	local to_discard = {}
	local who = source_fact(self,"kezhuanbaoheWho","toPlayer")
	local slash = clone_native(self,"slash")
	package_call(slash,"setSkillName","kezhuanbaohe")
	package_call(slash,"deleteLater")
	local x = 0
	for _, pp in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(pp,"inMyAttackRange",who) and package_known(self.player,"canSlash",pp,slash,false) then
			if package_known(self,"isFriend",pp) then
				x = x-1
				if package_known(self,"isWeak",pp) then
					x = x-1
				end
			else
				x = x+1
				if package_known(self,"isEnemy",pp) and package_known(self,"isWeak",pp) then
					x = x+1
				end
			end
		end
	end
	if x>1 then
		local cards = package_known(self.player,"getCards","he")
		cards = sgs.QList2Table(cards)
		package_call(self,"sortByKeepValue",cards,nil,"j")
		if #cards<2 then return to_discard end
		table.insert(to_discard, package_known(cards[1],"getEffectiveId"))
		table.insert(to_discard, package_known(cards[2],"getEffectiveId"))
	end
	return to_discard
end

local kezhuanxushi_skill = {}
kezhuanxushi_skill.name = "kezhuanxushi"
table.insert(package_skills, kezhuanxushi_skill)
kezhuanxushi_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","kezhuanxushiCard") then return end
	return source_skill(self,"#kezhuanxushiCard:.:")
end

sgs.ai_skill_use_func["#kezhuanxushiCard"] = function(card,use,self,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, c in ipairs(self.toUse) do
		table.removeOne(cards, c)
	end
	local ids = {}
	for _,c in ipairs(package_known(self,"poisonCards",cards))do
		if package_known(c,"getTypeId")>2 then
			for _,p in ipairs(self.friends_noself)do do
				if package_known(use.to,"contains",p) then goto package_continue_22 end
				table.insert(ids, package_known(c,"getId"))
				package_call(use.to,"append",p)
				break
			end ::package_continue_22:: end
		else
			for _,p in ipairs(self.enemies)do do
				if package_known(use.to,"contains",p) then goto package_continue_23 end
				table.insert(ids, package_known(c,"getId"))
				package_call(use.to,"append",p)
				break
			end ::package_continue_23:: end
		end
	end
	if #ids<#self.friends_noself then
		for _,c in ipairs(cards)do
			for _,p in ipairs(self.friends_noself)do do
				if package_known(use.to,"contains",p) or #ids>#cards/2 or table.contains(ids, package_known(c,"getId")) then goto package_continue_24 end
				table.insert(ids, package_known(c,"getId"))
				package_call(use.to,"append",p)
				break
			end ::package_continue_24:: end
		end
	end
	if #ids>0 then
		use.card = source_skill(self,"#kezhuanxushiCard:"..table.concat(ids,"+")..":")
	end
end



sgs.ai_skill_invoke.kezhuanfenjian = function(self, data)
	local to = package_call(data,"toPlayer")
	return package_known(self,"isFriend",to)
end

local kezhuanfenjian_skill = {}
kezhuanfenjian_skill.name = "kezhuanfenjian"
table.insert(package_skills, kezhuanfenjian_skill)
kezhuanfenjian_skill.getTurnUseCard = function(self,inclusive,request)

	local duel = clone_native(self,"duel")
	package_call(duel,"setSkillName","kezhuanfenjian")
	package_call(duel,"deleteLater")
	return duel
end

sgs.ai_skill_use_func["#kezhuanfenjianCard"] = function(card,use,self,request)
    if not package_known(self.player,"hasUsed","#kezhuanfenjianCard") then
        package_call(self,"sort",self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if package_known(enys,"isEmpty") then
				package_call(enys,"append",enemy)
			else
				local yes = 1
				for _,p in sgs.qlist(enys) do
					if (package_known(enemy,"getHp")+package_known(enemy,"getHp")+package_known(enemy,"getHandcardNum")) >= (package_known(p,"getHp")+package_known(p,"getHp")+package_known(p,"getHandcardNum")) then
						yes = 0
					end
				end
				if (yes == 1) then
					package_known(enys,"removeOne",package_known(enys,"at",0))
					package_call(enys,"append",enemy)
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			local yes = 1
			if (package_known(self.player,"getHp") <= 2) and (package_known(self.player,"getHandcardNum") < 2)
			and (package_known(enemy,"getHp") > 1) and (package_known(enemy,"getHandcardNum") > 2) then
				yes = 0
			end
			if (package_known(self,"objectiveLevel",enemy) > 0) and (yes == 1) then
			    use.card = card
			    if use.to then package_call(use.to,"append",enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.kezhuanfenjianCard = 8.5
sgs.ai_use_priority.kezhuanfenjianCard = 9.5
sgs.ai_card_intention.kezhuanfenjianCard = 80


local kezhuanguiji_skill = {}
kezhuanguiji_skill.name = "kezhuanguiji"
table.insert(package_skills, kezhuanguiji_skill)
kezhuanguiji_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","#kezhuanguijiCard") or package_known(self.player,"getStrategyMark","usekezhuanguiji") > 0 then return end
	return source_skill(self,"#kezhuanguijiCard:.:")
end

sgs.ai_skill_use_func["#kezhuanguijiCard"] = function(card,use,self,request)
    package_call(self,"sort",self.friends_noself,nil,true)
	local x = package_known(self,"getCardsNum","Ying")
	for _, p in ipairs(self.friends_noself) do
		if package_known(p,"getHandcardNum")<package_known(self.player,"getHandcardNum")
		and package_known(p,"getHandcardNum")<=package_known(self.player,"getHandcardNum")-x and package_known(p,"getHandcardNum")>1 then
			use.card = card
			package_call(use.to,"append",p)
			return
		end
	end
	for _, p in ipairs(self.friends_noself) do
		if package_known(p,"getHandcardNum")<package_known(self.player,"getHandcardNum") and package_known(p,"getHandcardNum")>1 then
			use.card = card
			package_call(use.to,"append",p)
			return
		end
	end
	package_call(self,"sort",self.enemies,nil,true)
	for _, p in ipairs(self.enemies) do
		if package_known(p,"getHandcardNum")<package_known(self.player,"getHandcardNum") and package_known(p,"getHandcardNum")>=x then
			use.card = card
			package_call(use.to,"append",p)
			return
		end
	end
end

sgs.ai_skill_invoke.kezhuanguiji = function(self, data)
	local to = package_call(data,"toPlayer")
	return package_known(to,"getHandcardNum")>package_known(self.player,"getHandcardNum")
	or package_known(self,"isFriend",to) and package_known(self,"isWeak",to)
end

local kezhuanjiaohaoex = {}
kezhuanjiaohaoex.name = "kezhuanjiaohaoex"
table.insert(package_skills, kezhuanjiaohaoex)
kezhuanjiaohaoex.getTurnUseCard = function(self,inclusive,request)
	return source_skill(self,"#kezhuanjiaohaoCard:.:")
end

sgs.ai_skill_use_func["#kezhuanjiaohaoCard"] = function(card,use,self,request)
    package_call(self,"sort",self.friends_noself)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, p in ipairs(self.friends_noself) do
		if (#cards>package_known(self.player,"getHp") or package_known(self,"isWeak",p)) and package_known(p,"hasSkill","kezhuanjiaohao") then
			for _, h in ipairs(cards) do do
				if package_known(h,"getTypeId")<3 or #package_known(self,"poisonCards",{h},p)>0 then
					goto package_continue_25
				end
				local equip = package_known(h,"getRealCard"):toEquipCard()
				local equip_index = package_known(equip,"location")
				if package_call(p,"getEquip",equip_index) == nil then
					use.card = source_skill(self,"#kezhuanjiaohaoCard:"..package_known(h,"getId")..":")
					package_call(use.to,"append",p)
					return
				end
			end ::package_continue_25:: end
		end
	end
	for _, p in ipairs(self.enemies) do
		if (#cards>=package_known(self.player,"getHp") or package_known(self,"isWeak",p)) and package_known(p,"hasSkill","kezhuanjiaohao") then
			for _, h in ipairs(cards) do do
				if package_known(h,"getTypeId")<3 or #package_known(self,"poisonCards",{h},p)<1 then
					goto package_continue_26
				end
				local equip = package_known(h,"getRealCard"):toEquipCard()
				local equip_index = package_known(equip,"location")
				if package_call(p,"getEquip",equip_index) == nil then
					use.card = source_skill(self,"#kezhuanjiaohaoCard:"..package_known(h,"getId")..":")
					package_call(use.to,"append",p)
					return
				end
			end ::package_continue_26:: end
		end
	end
end





























































































































local kezhuancuifeng={}
kezhuancuifeng.name="kezhuancuifeng"
table.insert(package_skills,kezhuancuifeng)
kezhuancuifeng.getTurnUseCard = function(self,inclusive,request)
	local ss = {}
	for _,c in sgs.qlist(package_known(self.player,"getCards","h")) do do
		if table.contains(ss,package_known(c,"getSuit")) then goto package_continue_27 end
		table.insert(ss,package_known(c,"getSuit"))
	end ::package_continue_27:: end
	if #ss>2 then
		local dc = clone(self,"fire_attack")
		package_call(dc,"setSkillName","kezhuancuifeng")
		local d = package_known(self,"aiUseCard",dc)
		if d.card and package_known(dc,"isAvailable",self.player) then
			for _,to in sgs.list(d.to)do
				if package_known(to,"isChained") then
					save_plan(self,"kezhuancuifengData",d)
					package_call(self,"setStrategyMemory","kearjsrgqi.choice.kezhuancuifeng","fire_attack")
					package_call(self,"setPriorityValue","kezhuancuifengCard",package_known(self,"getPriorityValue",package_known(dc,"getClassName")))
					return source_skill(self,"#kezhuancuifengCard:.:")
				end
			end
		end
	end
	for _,pn in sgs.list(patterns_for(self))do
		local dc = clone(self,pn)
		if package_known(dc,"isDamageCard") and package_known(dc,"isSingleTargetCard")
		and package_known(self,"getCardsNum",package_known(dc,"getClassName"))<1 then
			package_call(dc,"setSkillName","kezhuancuifeng")
			if package_known(dc,"isAvailable",self.player) then
				local d = package_known(self,"aiUseCard",dc)
				if d.card then
					for _,to in sgs.list(d.to)do
						if package_known(self,"ajustDamage",self.player,to,1,dc)>1 then
							save_plan(self,"kezhuancuifengData",d)
							package_call(self,"setStrategyMemory","kearjsrgqi.choice.kezhuancuifeng",pn)
							package_call(self,"setPriorityValue","kezhuancuifengCard",package_known(self,"getPriorityValue",package_known(dc,"getClassName")))
							return source_skill(self,"#kezhuancuifengCard:.:")
						end
					end
				end
			end
		end
	end
	for _,pn in sgs.list(patterns_for(self))do
		local dc = clone(self,pn)
		if package_known(dc,"isDamageCard") and package_known(dc,"isSingleTargetCard")
		and package_known(self,"getCardsNum",package_known(dc,"getClassName"))<1 then
			package_call(dc,"setSkillName","kezhuancuifeng")
			if package_known(dc,"isAvailable",self.player) then
				local d = package_known(self,"aiUseCard",dc)
				if d.card then
					for _,to in sgs.list(d.to)do
						if package_known(to,"getHp")<2 and package_known(self,"isWeak",to) then
							save_plan(self,"kezhuancuifengData",d)
							package_call(self,"setStrategyMemory","kearjsrgqi.choice.kezhuancuifeng",pn)
							package_call(self,"setPriorityValue","kezhuancuifengCard",package_known(self,"getPriorityValue",package_known(dc,"getClassName")))
							return source_skill(self,"#kezhuancuifengCard:.:")
						end
					end
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#kezhuancuifengCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value.kezhuancuifengCard = 6.4
sgs.ai_use_priority.kezhuancuifengCard = 6.4

ai_skill_use["@@kezhuancuifeng"]=function(self,prompt,request)
	local dummy=load_plan(self,"kezhuancuifengData")
	if dummy.card and dummy.to then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,package_known(p,"objectName"))
		end
		return selected(self,dummy.card,tos)
	end
end

local kezhuandengnan={}
kezhuandengnan.name="kezhuandengnan"
table.insert(package_skills,kezhuandengnan)
kezhuandengnan.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"getStrategyMark","@kezhuancuifeng")>0 and #self.enemies>1 then
		local dc = clone(self,"iron_chain")
		package_call(dc,"setSkillName","kezhuandengnan")
		local d = package_known(self,"aiUseCard",dc)
		if d.card and package_known(dc,"isAvailable",self.player) then
			local x = 0
			for _,to in sgs.list(d.to)do
				if not package_known(to,"isChained")
				then x = x+1 end
			end
			if x>1 then
				save_plan(self,"kezhuandengnanData",d)
				package_call(self,"setStrategyMemory","kearjsrgqi.choice.kezhuandengnan","iron_chain")
				package_call(self,"setPriorityValue","kezhuandengnanCard",package_known(self,"getPriorityValue",package_known(dc,"getClassName")))
				return source_skill(self,"#kezhuandengnanCard:.:")
			end
		end
	end
	local choices = {}
	for _,pn in sgs.list(patterns_for(self)) do
		local dc = clone(self,pn)
		if not package_known(dc,"isDamageCard") and package_known(dc,"isNDTrick")
		and package_known(self,"getCardsNum",package_known(dc,"getClassName"))<1 then
			package_call(dc,"setSkillName","kezhuandengnan")
			if package_known(dc,"isAvailable",self.player) then
				table.insert(choices,dc)
			end
		end
	end
	if #choices<1 then return end
	package_known(self,"getUseValue",choices)
	for _,dc in sgs.list(choices)do
		local dummy = package_known(self,"aiUseCard",dc)
		if dummy.card then
			local can = package_known(dummy.to,"length")>0
			for _,to in sgs.list(dummy.to)do
				if package_known(to,"getStrategyMark","&kezhuandengnanda")<1 then
					can = false
					break
				end
			end
			if can then
				save_plan(self,"kezhuandengnanData",dummy)
				package_call(self,"setStrategyMemory","kearjsrgqi.choice.kezhuandengnan",package_known(dc,"objectName"))
				package_call(self,"setPriorityValue","kezhuancuifengCard",package_known(self,"getPriorityValue",package_known(dc,"getClassName")))
				return source_skill(self,"#kezhuandengnanCard:.:")
			end
		end
	end
	if package_known(self,"isWeak") then
		for _,dc in sgs.list(choices)do do
			local dummy = package_known(self,"aiUseCard",dc)
			if dummy.card then
				save_plan(self,"kezhuandengnanData",dummy)
				package_call(self,"setStrategyMemory","kearjsrgqi.choice.kezhuandengnan",package_known(dc,"objectName"))
				if package_known(dummy.to,"isEmpty") and package_known(dc,"canRecast") then goto package_continue_28 end
				package_call(self,"setPriorityValue","kezhuancuifengCard",package_known(self,"getPriorityValue",package_known(dc,"getClassName")))
				return source_skill(self,"#kezhuandengnanCard:.:")
			end
		end ::package_continue_28:: end
	end
end

sgs.ai_skill_use_func["#kezhuandengnanCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value.kezhuandengnanCard = 6.4
sgs.ai_use_priority.kezhuandengnanCard = 6.4

ai_skill_use["@@kezhuandengnan"]=function(self,prompt,request)
	local dummy=load_plan(self,"kezhuandengnanData")
	if dummy.card then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,package_known(p,"objectName"))
		end
		return selected(self,dummy.card,tos)
	end
end






sgs.ai_skill_playerchosen.kezhuanshacheng = function(self, targets)
	targets = sgs.QList2Table(targets)
    package_call(self,"sort",targets)
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) and package_known(p,"getStrategyMark","kezhuanshachenglose-Clear")>1 then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) and package_known(p,"getStrategyMark","kezhuanshachenglose-Clear")>0 and package_known(self,"isWeak",p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.kezhuanshacheng = function(self, data)
	if package_known(self.player,"getStrategyFlag","wantuseshacheng") then
		return true
	end
end

sgs.ai_skill_invoke.kezhuanninghan = function(self, data)
	return true
end


local kezhuanhuozhong={}
kezhuanhuozhong.name="kezhuanhuozhong"
table.insert(package_skills,kezhuanhuozhong)
kezhuanhuozhong.getTurnUseCard = function(self,inclusive,request)
	return source_skill(self,"#kezhuanhuozhongCard:.:")
end
local kezhuanhuozhongex={}
kezhuanhuozhongex.name="kezhuanhuozhongex"
table.insert(package_skills,kezhuanhuozhongex)
kezhuanhuozhongex.getTurnUseCard = function(self,inclusive,request)
	return source_skill(self,"#kezhuanhuozhongCard:.:")
end

sgs.ai_skill_use_func["#kezhuanhuozhongCard"] = function(card,use,self,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _,c in ipairs(self.toUse)do
		table.removeOne(cards,c)
	end
	for _,c in ipairs(cards)do do
		if not package_known(c,"isBlack") or package_known(c,"getTypeId")==2 then goto package_continue_29 end
		local dc = clone(self,"supply_shortage")
		package_call(dc,"setSkillName","kezhuanhuozhong")
		package_call(dc,"addSubcard",c)
		if not package_known(self.player,"containsTrick","supply_shortage") and package_known(self.player,"hasJudgeArea")
		and not package_known(self.player,"isProhibited",self.player, dc) then
			for _,p in sgs.list(package_known(self.room,"findPlayersBySkillName","kezhuanhuozhong"))do
				if package_known(self,"isFriend",p) and (package_known(self,"isWeak",p) or #cards>3) then
					use.card = source_skill(self,"#kezhuanhuozhongCard:"..package_known(c,"getId")..":")
					package_call(use.to,"append",self.player)
					return
				end
			end
		end
	end ::package_continue_29:: end
end

sgs.ai_use_value.kezhuanhuozhongCard = 6.4
sgs.ai_use_priority.kezhuanhuozhongCard = 4.4

sgs.ai_skill_playerchosen.kezhuanhuozhong = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.kezhuanrihui = function(self, data)
	local n = 0
	for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(p,"getJudgingArea"):length()>0 then
			if package_known(self,"isEnemy",p) then
				n = n-1
			else
				n = n+1
			end
		end
	end
	return n>0
end



sgs.ai_skill_invoke.kezhuanhujian = function(self, data)
	return true
end

local kezhuanshili_skill={}
kezhuanshili_skill.name="kezhuanshili"
table.insert(package_skills,kezhuanshili_skill)
kezhuanshili_skill.getTurnUseCard=function(self,inclusive,request)
	if (package_known(self.player,"getStrategyMark","usekezhuanshili-PlayClear") > 0)
	or (package_known(self.player,"getStrategyFlag","usekezhuanshili")) then return nil end
	local cards = package_known(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards,true)

	local card
	for _,acard in ipairs(cards)  do
		if (package_known(acard,"isKindOf","EquipCard")) then
			card = acard
			break
		end
	end

	if not card then return nil end
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	local card_str = ("duel:kezhuanshili[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard=clone(self,"duel","kezhuanshili",package_known(card,"getSuit"),package_known(card,"getNumber"));package_call(skillcard,"addSubcard",card)
	assert(skillcard)
	return skillcard
end

sgs.weapon_range.Kezhuan_chixueqingfeng = 2
sgs.ai_use_priority.Kezhuan_chixueqingfeng = 3




local kezhuanyangming_skill = {}
kezhuanyangming_skill.name = "kezhuanyangming"
table.insert(package_skills, kezhuanyangming_skill)
kezhuanyangming_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","kezhuanyangmingCard") or (not package_known(self.player,"canPindian")) then return end
	return source_skill(self,"#kezhuanyangmingCard:.:")
end

sgs.ai_skill_use_func["#kezhuanyangmingCard"] = function(card,use,self,request)
    if (not package_known(self.player,"hasUsed","#kezhuanyangmingCard"))
	and (not package_known(self.player,"isKongcheng")) then
        package_call(self,"sort",self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if (package_known(self.player,"canPindian",enemy, true)) then
				if package_known(enys,"isEmpty") then
					package_call(enys,"append",enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(enys) do
						if (package_known(enemy,"getHp")+package_known(enemy,"getHp")+package_known(enemy,"getHandcardNum")) >= (package_known(p,"getHp")+package_known(p,"getHp")+package_known(p,"getHandcardNum")) then
							yes = 0
						end
					end
					if (yes == 1) then
						package_known(enys,"removeOne",package_known(enys,"at",0))
						package_call(enys,"append",enemy)
					end
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			if (package_known(self,"objectiveLevel",enemy) > 0) then
			    use.card = card
			    if use.to then package_call(use.to,"append",enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.kezhuanyangmingCard = 8.5
sgs.ai_use_priority.kezhuanyangmingCard = 9.5
sgs.ai_card_intention.kezhuanyangmingCard = 80

sgs.ai_skill_invoke.kezhuanyangming = function(self, data)
	return true
end

-- The fixed producer passes its newly-created plain list to getUseValue.
-- Both effective fixed providers fail before planning or saved-state writes.
-- Preserve the ordinary provider's reached native recursion-flag prefix, rather
-- than turning its missing list method into a facade unknown or sorting it.
local manjuan_ordinary_value=SmartAIView.getUseValue
local function manjuan_list_value(self,choices)
 if type(manjuan_ordinary_value)=="function" and self.getUseValue==manjuan_ordinary_value then
  local flag=package_known(self,"getUseValueRecursionFlag")
  package_call(self,"setUseValueRecursionFlag",not flag)
  return choices:getClassName() -- exact missing method: ordinary source error
 elseif type(SmartAIView.originalHegemonyGetUseValue)=="function" and self.getUseValue==SmartAIView.originalHegemonyGetUseValue then
  return choices:isKindOf("LuaSkillCard") -- Original fails before any flag write
 end
 unsupported("kezhuanmanjuan.getUseValue_provider")
end

local kezhuanmanjuan={}
kezhuanmanjuan.name="kezhuanmanjuan"
table.insert(package_skills,kezhuanmanjuan)
kezhuanmanjuan.getTurnUseCard = function(self,inclusive,request)
	local choices = {}
	for i=0,package_known(self,"manjuanPrintedCount")-1 do
		local c = package_call(self,"manjuanPrintedStep",i)
		if package_known(self.player,"getStrategyMark",i.."manjuanPile-Clear")>0
		and package_known(self.player,"getStrategyMark",c:getNumber().."manjuanNumber-Clear")<1
		and c:isAvailable(self.player)
		then table.insert(choices,c) end
	end
	if #choices<1 then return end
	manjuan_list_value(self,choices)
	for _,dc in sgs.list(choices)do do
		local dummy = package_known(self,"aiUseCard",dc)
		if dummy.card then
			save_plan(self,"kezhuanmanjuanData",dummy)
			if package_known(dummy.to,"isEmpty") and package_known(dc,"canRecast") then goto package_continue_30 end
			package_call(self,"setPriorityValue","kezhuanmanjuanCard",package_known(self,"getPriorityValue",package_known(dc,"getClassName")))
			return source_skill(self,"#kezhuanmanjuanCard:.:")
		end
	end ::package_continue_30:: end
end

sgs.ai_skill_use_func["#kezhuanmanjuanCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value.kezhuanmanjuanCard = 6.4
sgs.ai_use_priority.kezhuanmanjuanCard = 6.4

ai_skill_use["@@kezhuanmanjuan"]=function(self,prompt,request)
	local dummy=load_plan(self,"kezhuanmanjuanData")
	if dummy.card then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,package_known(p,"objectName"))
		end
		return response_skill(self,"#kezhuanmanjuanVsCard",{},tos,request,"@@kezhuanmanjuan")
	end
end

function sgs.ai_cardsview.kezhuanmanjuan(self,class_name,player)
	if package_known(self.player,"isKongcheng") then
		for i=0,package_known(self,"manjuanSourceCount")-1 do
			local c = package_call(self,"manjuanSourceStep",i)
			if package_known(player,"getStrategyMark",i.."manjuanPile-Clear")>0
			and package_known(player,"getStrategyMark",c:getNumber().."manjuanNumber-Clear")<1
			and not package_known(self,"manjuanSourceLocked",c,player) and c:isKindOf(class_name)
			then return "#kezhuanmanjuanVsCard:.:"..c:objectName() end
		end
	end
end

sgs.ai_skill_askforag.kezhuanmanjuan = function(self,card_ids)
	for _,id in sgs.list(card_ids) do
		if id==package_call(self,"readManjuanSourceId") then
			return id
		end
	end
end



sgs.ai_skill_discard.kezhuanfushan = function(self, discard_num, min_num, optional, include_equip)
	if not (package_known(self.player,"getStrategyFlag","wantusefushan")) then
		return package_known(self,"askForDiscard","dummyreason", discard_num, discard_num, true, true)
	else
		local to_discard = {}
		local yes = 0
		for _,c in sgs.qlist(package_known(self.player,"getCards","h")) do
			if (package_known(c,"isKindOf","Slash")) then
				table.insert(to_discard, package_known(c,"getEffectiveId"))
				yes = 1
				break
			end
		end
		if yes == 1 then
			return to_discard
		else
			return package_known(self,"askForDiscard","dummyreason", discard_num, discard_num, true, true)
		end
	end
end

ai_skill_use["@@kezhuanniluan"]=function(self,prompt,request)
	package_call(self,"sort",self.enemies)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards,nil,"j")
	for _,p in sgs.list(self.enemies)do
		if #cards>0 and package_known(p,"getStrategyMark","kezhuanniluan"..package_known(self.player,"objectName"))<1 and package_known(self,"isWeak",p) then
			return response_skill(self,"#kezhuanniluanCard",{package_known(cards[1],"getId")},{package_known(p,"objectName")},request)
		end
	end
	package_call(self,"sort",self.friends)
	for _,p in sgs.list(self.friends)do
		if package_known(p,"getStrategyMark","kezhuanniluan"..package_known(self.player,"objectName"))>0 and package_known(self,"isWeak",p) then
			return response_skill(self,"#kezhuanniluanCard",{},{package_known(p,"objectName")},request)
		end
	end
	for _,p in sgs.list(self.friends)do
		if package_known(p,"getStrategyMark","kezhuanniluan"..package_known(self.player,"objectName"))>0 then
			return response_skill(self,"#kezhuanniluanCard",{},{package_known(p,"objectName")},request)
		end
	end
	for _,p in sgs.list(self.friends)do
		if #cards>1 and package_known(p,"getStrategyMark","kezhuanniluan"..package_known(self.player,"objectName"))<1 and not package_known(self,"isWeak",p) then
			return response_skill(self,"#kezhuanniluanCard",{package_known(cards[1],"getId")},{package_known(p,"objectName")},request)
		end
	end
end





ai_skill_use["@@kehexumouuse"]=function(self,prompt,request)
	local id = source_fact(self,"kehexumouForAI","toIntList"):first()
	local card = package_known(self,"getPrintedCardById",id)
	local d = package_known(self,"aiUseCard",card)
	if d.card then
		local targets = {}
		for _, p in sgs.qlist(d.to)do
			table.insert(targets, package_known(p,"objectName"))
		end
		if package_known(card,"canRecast") and #targets<1 then return "." end
		return selected(self,package_known(self,"getKnownCardById",id),targets)
	end
	return "."
end



sgs.ai_skill_choice.keheeqian = function(self, choices, data)
	return "add"
end

sgs.ai_skill_invoke.keheeqian = function(self, data)
	local to = package_call(data,"toPlayer")
	return package_known(self,"isEnemy",to) or not package_known(self,"isFriend",to) and #self.enemies<1
end

sgs.ai_skill_discard.keheeqian = function(self)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local cns = {}
	for _,c in sgs.qlist(package_known(self.player,"getCards","j"))do
		if string.find(package_known(c,"objectName"),"kehexumou")
		then table.insert(cns, package_known(self,"getPrintedCardById",package_known(c,"getEffectiveId")):objectName()) end
	end
	for _, c in ipairs(cards)do
		if not table.contains(cns, package_known(c,"objectName")) and package_known(c,"isAvailable",self.player) then
			return {package_known(c,"getEffectiveId")}
		end
	end
	if #cns>0 then return {} end
	return package_known(self,"askForDiscard","dummyreason", 1, 1, true, true)
end

local kehefusha_skill = {}
kehefusha_skill.name = "kehefusha"
table.insert(package_skills, kehefusha_skill)
kehefusha_skill.getTurnUseCard = function(self,inclusive,request)
	if (package_known(self.player,"getStrategyMark","@kehefusha") <= 0) then return end
	return source_skill(self,"#kehefushaCard:.:")
end

sgs.ai_skill_use_func["#kehefushaCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies)
	local n = math.min(package_known(self.player,"getAttackRange"),package_known(self.room,"getPlayers"):length())
	for _, enemy in ipairs(self.enemies) do
		if package_known(self.player,"inMyAttackRange",enemy) and package_known(enemy,"getHp")<=n and (#self.enemies<2 or package_known(enemy,"getHp")>1)
		and package_known(self,"damageIsEffective",enemy,"N",self.player) then
			use.card = card
			package_call(use.to,"append",enemy)
			break
		end
	end
end

sgs.ai_use_value.kehefushaCard = 8.5
sgs.ai_use_priority.kehefushaCard = 3.5
sgs.ai_card_intention.kehefushaCard = 80





sgs.ai_skill_invoke.kehewentian = function(self, data)
	if package_known(self.player,"getStrategyMark","@usekehewentian")<2 and #self.friends_noself<1
	then return end
	if package_known(self.player,"getPhase")==sgs.Player_Judge then
		return package_known(self.player,"getJudgingArea"):length()>0
	end
	return package_known(self.player,"getPhase")>=sgs.Player_Play
	and #self.friends_noself>0
end

sgs.ai_skill_playerchosen.kehewentian = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = sgs.SPlayerList()
	local theweaktwo = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) then
			package_call(theweak,"append",p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if (package_known(qq,"getRole") == "lord") then
			for _,oo in sgs.qlist(theweak) do
				package_known(theweaktwo,"removeOne",oo)
			end
			package_call(theweaktwo,"append",qq)
			break
		end
		if package_known(theweaktwo,"isEmpty") then
			package_call(theweaktwo,"append",qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (package_known(pp,"getHp") < package_known(qq,"getHp")) then
					inin = 0
				end
			end
			if (inin == 1) then
				package_call(theweaktwo,"append",qq)
			end
		end
	end





	if package_known(theweaktwo,"length") > 0 then
	    return package_known(theweaktwo,"at",0)
	end
	return nil
end


local kehewentian_skill={}
kehewentian_skill.name="kehewentian"
table.insert(package_skills,kehewentian_skill)
kehewentian_skill.getTurnUseCard=function(self,inclusive,request)
	local id = package_known(self.player,"getStrategyMark","kehewentianId")
	local dc = clone(self,"fire_attack")
	package_call(dc,"addSubcard",id)
	package_call(dc,"setSkillName","kehewentian")
	if not package_known(dc,"isAvailable",self.player) then return end
	if package_known(self.player,"getStrategyMark","usedkehewentian-Clear")>0 and package_known(self,"getKnownCardById",id):isRed() then
		return dc
	end
	local d = package_known(self,"aiUseCard",dc)
	if d.card then
		for _,p in sgs.qlist(d.to) do
			if (package_known(self,"isEnemy",p) or package_known(p,"isChained")) and package_known(self,"isWeak",p)  then
				return dc
			end
		end
	end
end











function sgs.ai_cardsview.kehewentian(self, class_name, player)
	if class_name == "Nullification" then
		local id = package_known(player,"getStrategyMark","kehewentianId")
		local dc = clone(self,"nullification")
		package_call(dc,"addSubcard",id)
		package_call(dc,"setSkillName","kehewentian")
		if package_known(self.player,"getStrategyMark","usedkehewentian-Clear")>0 then
			return package_known(self,"getKnownCardById",id):isBlack() and proposal(self,dc)
		end
		return proposal(self,dc)
	end
end

sgs.ai_skill_discard.keheyinlue = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	local to = source_fact(self,"keheyinlueTo","toPlayer")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	if package_known(self,"isFriend",to) then
	    table.insert(to_discard, package_known(cards[1],"getEffectiveId"))
		return to_discard
	elseif not package_known(self,"isEnemy",to) then
	    return package_known(self,"askForDiscard","dummyreason", 1, 1, true, true)
	end
	return {}
end

local kehechushi_skill = {}
kehechushi_skill.name = "kehechushi"
table.insert(package_skills, kehechushi_skill)
kehechushi_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","kehechushiCard") then return end
	return source_skill(self,"#kehechushiCard:.:")
end

sgs.ai_skill_use_func["#kehechushiCard"] = function(card,use,self,request)
    if not package_known(self.player,"hasUsed","#kehechushiCard") then
        use.card = card
	    return
	end
end

sgs.ai_skill_invoke.keheyinlue = function(self, data)
	if package_known(self.player,"getStrategyFlag","wantuseyinlue") then
	    return true
	end
end

sgs.ai_skill_discard.kehechushi = function(self)
	local to_discard = {}
	table.insert(to_discard, package_known(self.player,"getCards","h"):last():getId())
	return to_discard
end

sgs.ai_use_value.kehechushiCard = 8.5
sgs.ai_use_priority.kehechushiCard = 7.5



sgs.ai_skill_invoke.kehedaimou = function(self, data)
	return true
end

sgs.ai_skill_invoke.kehefangjie = function(self, data)
	local hasxm,nouse,cns = 0,0,{}
	for _,c in sgs.qlist(package_known(self.player,"getJudgingArea")) do
		if string.find(package_known(c,"objectName"),"kehexumou") then
			local ec = package_known(self,"getPrintedCardById",package_known(c,"getEffectiveId"))
			if table.contains(cns, package_known(ec,"objectName")) then nouse = nouse+1 break end
			table.insert(cns, package_known(ec,"objectName"))
			if package_known(ec,"isAvailable",self.player) then
				local d = package_known(self,"aiUseCard",ec)
				if d.card then
					hasxm = hasxm+1
				else
					nouse = nouse+1
				end
			else
				nouse = nouse+1
			end
		end
	end
	return hasxm>nouse and nouse>1
end

sgs.ai_skill_cardchosen.kehefangjie = function(self,who,flags,method)
	local cns = {}
	for _,c in sgs.qlist(package_known(self.player,"getJudgingArea")) do do
		if string.find(package_known(c,"objectName"),"kehexumou") then
			local id = package_known(c,"getEffectiveId")
			if package_known(self.disabled_ids,"contains",id) then goto package_continue_31 end
			local ec = package_known(self,"getPrintedCardById",id)
			if table.contains(cns, package_known(ec,"objectName")) then return id end
			table.insert(cns, package_known(ec,"objectName"))
			if package_known(ec,"isAvailable",self.player) then
				local d = package_known(self,"aiUseCard",ec)
				if d.card then

				else
					return id
				end
			else
				return id
			end
		end
	end ::package_continue_31:: end
end



local kehefuhai_skill = {}
kehefuhai_skill.name = "kehefuhai"
table.insert(package_skills, kehefuhai_skill)
kehefuhai_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","kehefuhaiCard") then return end
	return source_skill(self,"#kehefuhaiCard:.:")
end

sgs.ai_skill_use_func["#kehefuhaiCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.kehefuhaiCard = 8.5
sgs.ai_use_priority.kehefuhaiCard = 9.5
sgs.ai_card_intention.kehefuhaiCard = 33



sgs.ai_skill_invoke.kehepianchong = function(self, data)
	return true
end



local kehejinfa_skill = {}
kehejinfa_skill.name = "kehejinfa"
table.insert(package_skills, kehejinfa_skill)
kehejinfa_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","kehejinfaCard") then return end
	local cards = package_known(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	if #cards>0 then
		return source_skill(self,"#kehejinfaCard:"..package_known(cards[1],"getId")..":")
	end
end

sgs.ai_skill_use_func["#kehejinfaCard"] = function(card,use,self,request)
    use.card = card
	package_call(self,"setStrategyMemory","kearjsrgqi.jinfaColor",package_known(card,"getColor"))
end

function sgs.ai_cardneed.kehejinfaCard(to, card, self)
	if package_known(self.player,"hasUsed","#kehejinfaCard") then return false end
	return true
end

sgs.ai_use_value.kehejinfaCard = 8.5
sgs.ai_use_priority.kehejinfaCard = 9.5
sgs.ai_card_intention.kehejinfaCard = 80

sgs.ai_skill_playerschosen.kehejinfa = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if package_known(self,"isFriend",target) then
            package_call(selected,"append",target)
			if package_known(selected,"length")>=max then break end
        end
    end
    return selected
end

sgs.ai_skill_choice.kehejinfa = function(self, choices)
	local items = package_known(choices,"split","+")



		return "shu"

end

sgs.ai_skill_discard.kehejinfa = function(self)
	local from = source_fact(self,"kehejinfaFrom","toPlayer")
	if package_known(self,"isFriend",from) then
		for _,c in sgs.qlist(package_known(self.player,"getCards","h")) do
			if (package_known(c,"getColor")==memory(self,"jinfaColor")) then
				return {package_known(c,"getId")}
			end
		end
	end
	local cards = package_known(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	return {package_known(cards[1],"getId")}
end

ai_skill_use["@@kehefumou"]=function(self,prompt,request)
    local cards = package_known(self.player,"getCards","he")
    cards = sgs.QList2Table(cards)
    package_call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do do
    	local c = clone(self,"chuqibuyi")
		package_call(c,"setSkillName","kehefumou")
		package_call(c,"addSubcard",h)
		if package_known(self.player,"isLocked",c) or not package_known(c,"isKindOf","Ying") then goto package_continue_32 end
		local dummy = package_known(self,"aiUseCard",c)
		if dummy.card then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,package_known(p,"objectName"))
			end
			return selected(self,c,tos)
		end
	end ::package_continue_32:: end
end

sgs.ai_view_as.kehexuanfeng = function(card, player, card_place)
	if (package_known(player,"getKingdom") == "shu") and card_place ~= sgs.Player_PlaceSpecial and package_known(card,"isKindOf","Ying") then
		local suit = package_known(card,"getSuitString")
		local number = package_known(card,"getNumberString")
		local card_id = package_known(card,"getEffectiveId")
		return {name="yj_stabs_slash",skill="kehexuanfeng",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
	end
end

local kehexuanfeng_skill = {}
kehexuanfeng_skill.name = "kehexuanfeng"
table.insert(package_skills, kehexuanfeng_skill)
kehexuanfeng_skill.getTurnUseCard = function(self,inclusive,request)
	if (package_known(self.player,"getKingdom") ~= "shu") then return end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	for _, card in ipairs(cards) do
		if package_known(card,"isKindOf","Ying") then
			local dc = clone(self,"yj_stabs_slash")
			package_call(dc,"setSkillName","kehexuanfeng")
			package_call(dc,"addSubcard",card)
			return dc
		end
	end
end

function sgs.ai_cardneed.kehexuanfeng(to, card)
	return package_known(card,"isKindOf","Ying")
end



sgs.ai_skill_invoke.kehelonglinjuedou = function(self, data)
	local from = package_call(data,"toPlayer")
	return package_known(self,"isEnemy",from)
end

sgs.ai_skill_discard.kehelonglin = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards,nil,"j")
	local use = source_fact(self,"kehelonglinData","toCardUse")
	if package_known(self,"isFriend",package_known(use.to,"first")) then
	    if not package_known(self,"isFriend",use.from) then
			table.insert(to_discard, package_known(cards[1],"getEffectiveId"))
		end
	elseif not package_known(self,"isEnemy",package_known(use.to,"first")) then
	    to_discard = package_known(self,"askForDiscard","dummyreason", 1, 1, true, true)
	end
	return to_discard
end

local kehezhendan_skill = {}
kehezhendan_skill.name = "kehezhendan"
table.insert(package_skills, kehezhendan_skill)
kehezhendan_skill.getTurnUseCard = function(self,inclusive,request)
	local handcards = package_known(self,"addHandPile","h")
	package_call(self,"sortByUseValue",handcards, true)
	for _, pn in ipairs(patterns_for(self))do
		local dc = clone(self,pn)
		package_call(dc,"setSkillName","kehezhendan")
		if package_known(dc,"getTypeId")==1 then
			for _, h in ipairs(handcards)do
				if package_known(h,"getTypeId")>1 and package_known(self,"getUseValue",h)<package_known(self,"getUseValue",dc) then
					package_call(dc,"addSubcard",h)
					if package_known(dc,"isAvailable",self.player) then
						local d = package_known(self,"aiUseCard",dc)
						if d.card then
							return dc
						end
					end
					package_call(dc,"clearSubcards")
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#kehezhendan"] = function(card,use,self,request)
	local userstring = package_known(card,"toString")
	userstring = (package_known(userstring,"split",":"))[4]
	local kehezhendancard = clone_native(self,userstring, package_known(card,"getSuit"), package_known(card,"getNumber"))
	package_call(kehezhendancard,"setSkillName","kehezhendan")
	package_call(self,"useBasicCard",kehezhendancard, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["kehezhendan"] = 3
sgs.ai_use_value["kehezhendan"] = 3

function sgs.ai_cardsview.kehezhendan(self,class_name,player)
	local handcards = package_known(self,"addHandPile","h")
	package_call(self,"sortByKeepValue",handcards)
	for _, h in ipairs(handcards)do
		if package_known(h,"getTypeId")>1 then
			local dc = clone(self,class_name)
			package_call(dc,"setSkillName","kehezhendan")
			package_call(dc,"addSubcard",h)
			return proposal(self,dc)
		end
	end
end

function sgs.ai_cardneed.kehezhendan(to, card, self)
	return (not package_known(card,"isKindOf","BasicCard")) and (not package_known(card,"isEquipped"))
end




sgs.ai_skill_invoke.keheyingshi = function(self, data)
	return true
end

sgs.ai_skill_invoke.kehetuigu = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kehetuigu = function(self, targets)
	if package_known(self,"isWeak") and (package_known(self.player,"getEquipsId"):length() > 0) then
		return self.player
	end
	targets = sgs.QList2Table(targets)
	local theweak = sgs.SPlayerList()
	local theweaktwo = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if package_known(self,"isEnemy",p) then
			package_call(theweak,"append",p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if package_known(theweaktwo,"isEmpty") then
			package_call(theweaktwo,"append",qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (package_known(pp,"getEquips"):length() > package_known(qq,"getEquips"):length()) then
					inin = 0
				end
			end
			if (inin == 1) then
				package_known(theweaktwo,"removeOne",package_known(theweaktwo,"at",0))
				package_call(theweaktwo,"append",qq)
			end
		end
	end
	if package_known(theweaktwo,"length") > 0 then
	    return package_known(theweaktwo,"at",0)
	end
	return nil
end

ai_skill_use["@@kehetuigu"]=function(self,prompt,request)
	local dc = clone(self,"zl_jiejiaguitian")
	package_call(dc,"setSkillName","kehetuigu")
	if package_known(dc,"isAvailable",self.player) then
		local dummy = package_known(self,"aiUseCard",dc)
		if dummy.card and dummy.to then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,package_known(p,"objectName"))
			end
			return selected(self,dc,tos)
		end
	end
end



local kehezhaotu_skill={}
kehezhaotu_skill.name="kehezhaotu"
table.insert(package_skills,kehezhaotu_skill)
kehezhaotu_skill.getTurnUseCard=function(self,inclusive,request)
	if (package_known(self.player,"getStrategyMark","kehezhaotuuse_lun") ~= 0) then return end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)

	package_call(self,"sortByUseValue",cards,true)

	local has_weapon, has_armor = false, false

	for _,acard in ipairs(cards)  do
		if package_known(acard,"isKindOf","Armor") then has_armor=true end
		if package_known(acard,"isKindOf","Weapon") then has_weapon=true end
	end

	for _,acard in ipairs(cards)  do do
		if package_known(acard,"isRed") and package_known(acard,"getTypeId")~=2 and (inclusive or package_known(self,"getUseValue",acard)<sgs.ai_use_value.Indulgence) then
			if package_known(acard,"isKindOf","Armor") then
				if not package_call(self.player,"getArmor") then goto package_continue_33
				elseif package_known(self.player,"hasEquip",acard) and not has_armor and package_known(self,"evaluateArmor")>0
				then goto package_continue_33 end
			end
			if package_known(acard,"isKindOf","Weapon") then
				if not package_call(self.player,"getWeapon") then goto package_continue_33
				elseif package_known(self.player,"hasEquip",acard) and not has_weapon
				then goto package_continue_33 end
			end
			local dc = clone(self,"indulgence")
			package_call(dc,"setSkillName","kehezhaotu")
			package_call(dc,"addSubcard",acard)
			return dc
		end
	end ::package_continue_33:: end
end

function sgs.ai_cardneed.kehezhaotu(to, card)
	return package_known(card,"isRed") and (not package_known(card,"isKindOf","TrickCard"))
end

local kehejingju_skill={}
kehejingju_skill.name="kehejingju"
table.insert(package_skills,kehejingju_skill)
kehejingju_skill.getTurnUseCard = function(self,inclusive,request)
	for _,p in sgs.list(package_known(self.player,"getAliveSiblings"))do
		for _,j in sgs.list(package_known(p,"getJudgingArea"))do do
			if package_known(self.player,"containsTrick",package_known(j,"objectName"))
			or package_known(self,"isEnemy",p) then goto package_continue_34 end
			return source_skill(self,"#kehejingjuCard:.:")
		end ::package_continue_34:: end
	end
end

sgs.ai_skill_use_func["#kehejingjuCard"] = function(card,use,self,request)
	for _,p in sgs.list(patterns_for(self))do do
		local dc = clone(self,p)
		if dc and package_known(dc,"getTypeId")==1 then
			if package_known(self,"getCardsNum",package_known(dc,"getClassName"))>0 then goto package_continue_35 end
			package_call(dc,"setSkillName","kehejingju")
			if package_known(dc,"isAvailable",self.player) then
				local dummy = package_known(self,"aiUseCard",dc)
				if dummy.card then
					use.card = source_skill(self,"#kehejingjuCard:.:"..package_known(dc,"objectName"))
					if use.to then use.to = dummy.to end
					break
				end
			end
		end
	end ::package_continue_35:: end
end

sgs.ai_use_value.kehejingjuCard = 4.4
sgs.ai_use_priority.kehejingjuCard = 3

function sgs.ai_cardsview.kehejingju(self,class_name,player)
	if owner_reason(self)~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	then return end
	for _,h in sgs.list(package_known(player,"getHandcards"))do
		if package_known(h,"isKindOf",class_name) then
			return
		end
	end
	local dc = clone(self,class_name)
	if dc and package_known(dc,"getTypeId")==1 then
		for _,p in sgs.list(package_known(player,"getAliveSiblings"))do
			for _,j in sgs.list(package_known(p,"getJudgingArea"))do do
				if package_known(player,"containsTrick",package_known(j,"objectName")) then goto package_continue_36 end
				return skill_proposal("#kehejingjuCard",{},package_known(dc,"objectName"))
			end ::package_continue_36:: end
		end
	end
end

sgs.ai_skill_playerchosen.kehejingju = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,"card")
    for _,target in sgs.list(destlist)do
		if package_known(self,"isFriend",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not package_known(self,"isEnemy",target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_discard.keheweizhui = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local from = source_fact(self,"keheweizhuiFrom","toPlayer")
	if package_known(self,"doDisCard",from,"hej") then
		if package_known(cards[1],"isBlack") then
			table.insert(to_discard, package_known(cards[1],"getEffectiveId"))
			return to_discard
		end
	end
	return package_known(self,"askForDiscard","dummyreason", 1, 1, true, true)
end



sgs.ai_skill_playerchosen.keheyoujin = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets)
	for _, p in ipairs(targets) do
		if package_known(self,"isEnemy",p) and package_known(p,"getHandcardNum")<package_known(self.player,"getHandcardNum") then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if package_known(self,"isEnemy",p) and package_known(self,"isWeak",p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if package_known(self,"isEnemy",p) and not package_known(self,"isWeak") then
			return p
		end
	end
end


local kehedailao_skill = {}
kehedailao_skill.name = "kehedailao"
table.insert(package_skills, kehedailao_skill)
kehedailao_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","kehedailaoCard") then return end
	for _,c in sgs.qlist(package_known(self.player,"getHandcards")) do
		if package_known(c,"isAvailable",self.player) then
			return
		end
	end
	return source_skill(self,"#kehedailaoCard:.:")
end

sgs.ai_skill_use_func["#kehedailaoCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value.kehedailaoCard = 8.5
sgs.ai_use_priority.kehedailaoCard = 9.5
sgs.ai_card_intention.kehedailaoCard = 80



sgs.ai_skill_invoke.keheyaoyan = function(self, data)
	return true
end

sgs.ai_skill_choice.keheyaoyan = function(self, choices, data)
	local sj = package_call(self.room,"getCurrent")
	if (self.player == sj) then
		return "join"
	else
		if package_known(self,"isFriend",sj) then
			if math.random(0,5) > 1 then
				return "join"
			end
		else
			if math.random(0,2)>1 then
				return "join"
			end
		end
	end
	return "notjoin"
end

sgs.ai_skill_playerschosen.keheyaoyan = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    package_call(self,"sort",can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if package_known(self,"isEnemy",target)
		or package_known(self,"getOverflow",target) > 1 then
            package_call(selected,"append",target)
            if package_known(selected,"length")>=max then break end
        end
    end
    return selected
end

sgs.ai_skill_playerchosen.keheyaoyan = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = sgs.SPlayerList()
	local theweaktwo = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if package_known(self,"isEnemy",p) then
			package_call(theweak,"append",p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if package_known(theweaktwo,"isEmpty") then
			package_call(theweaktwo,"append",qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (package_known(pp,"getHp") < package_known(qq,"getHp")) then
					inin = 0
				end
			end
			if (inin == 1) then
				package_call(theweaktwo,"append",qq)
			end
		end
	end
	if package_known(theweaktwo,"length") > 0 then
	    return package_known(theweaktwo,"at",0)
	end
	return nil
end

local kehechiying_skill = {}
kehechiying_skill.name = "kehechiying"
table.insert(package_skills, kehechiying_skill)
kehechiying_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","kehechiyingCard") then return end
	return source_skill(self,"#kehechiyingCard:.:")
end

sgs.ai_skill_use_func["#kehechiyingCard"] = function(card,use,self,request)
	package_call(self,"sort",self.friends)
	for _, friend in ipairs(self.friends) do
		use.card = card
		if use.to then package_call(use.to,"append",friend) end
		break
	end
end

sgs.ai_use_value.kehechiyingCard = 8.5
sgs.ai_use_priority.kehechiyingCard = 9.5
sgs.ai_card_intention.kehechiyingCard = 80













































local kehedanxin = {}
kehedanxin.name = "kehedanxin"
table.insert(package_skills, kehedanxin)
kehedanxin.getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)

	package_call(self,"sortByUseValue",cards,true)
	if #cards<1 then return end
	local acard = clone_native(self,"yj_tuixinzhifu")
	package_call(acard,"setSkillName","kehedanxin")
	package_call(acard,"addSubcard",cards[1])
	package_call(acard,"deleteLater")
	return acard
end

sgs.ai_skill_playerchosen.kehefengxiang = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets)
	for _, p in ipairs(targets) do
		if package_known(self,"isEnemy",p) and package_known(p,"getEquips"):length()>=package_known(self.player,"getEquips"):length() then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if package_known(self,"isFriend",p) and package_known(p,"getEquips"):length()>0 and package_known(self.player,"getEquips"):length()>0 then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if package_known(p,"getEquips"):length()>0 then
			return p
		end
	end
end








sgs.ai_skill_invoke.keshuaizhimeng = function(self,data)
	return true
end

sgs.ai_skill_invoke.keshuaitianyu = function(self,data)
	return true
end

sgs.ai_fill_skill.keshuaizhuni = function(self,inclusive,request)
    return source_skill(self,"#keshuaizhuniCard:.:")
end

sgs.ai_skill_use_func["#keshuaizhuniCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value.keshuaizhuniCard = 3.4
sgs.ai_use_priority.keshuaizhuniCard = 8.2

sgs.ai_skill_playerchosen.keshuaizhuni = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,target in sgs.list(destlist)do
		if package_known(self,"isEnemy",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not package_known(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_discard.keshuaixiangru = function(self,max,min,optional)
	local to_cards = {}
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
   	for _,hcard in sgs.list(cards)do
   		if #to_cards>=min then break end
     	table.insert(to_cards,package_known(hcard,"getEffectiveId"))
	end
	local to = source_fact(self,"keshuaixiangruTo","toPlayer")
	if package_known(self,"isFriend",to) then return to_cards end
	return {}
end

sgs.ai_skill_playerchosen.keshuaijinglei = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if package_known(self,"isEnemy",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not package_known(self,"isFriend",target)
		and #self.enemies<1
		then return target end
	end
end

ai_skill_use["@@keshuaijinglei"]=function(self,prompt,request)
	local valid = {}
	local destlist = package_known(self.room,"getAlivePlayers")
    destlist = package_call(self,"sort",destlist,"handcard")
	local n = 0
	for _,to in sgs.list(destlist)do
		if n+package_known(to,"getHandcardNum")<package_known(self.player,"getStrategyMark","keshuaijinglei") then
			table.insert(valid,package_known(to,"objectName"))
			n = n+package_known(to,"getHandcardNum")
		end
	end
	if #valid>1 then
    	return response_skill(self,"#keshuaijingleiCard",{},valid,request)
	end
end

sgs.ai_skill_playerschosen.keshuaiyansha = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(self,"isWeak",p)
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) and not package_known(self,"isWeak",p) and #destlist/2>#tos
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and #self.friends>1
		and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

ai_skill_use["@@keshuaiyansha"]=function(self,prompt,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
   	for _,c in sgs.list(cards)do do
		if package_known(c,"getTypeId")<3 then goto package_continue_37 end
		local dc = clone(self)
		package_call(dc,"setSkillName","_keshuaiyansha")
		package_call(dc,"addSubcard",c)
		if not package_known(dc,"isAvailable",self.player) then goto package_continue_37 end
		local dummy = package_known(self,"aiUseCard",dc)
		if dummy.card and dummy.to then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,package_known(p,"objectName"))
			end
			return selected(self,dc,tos)
		end
	end ::package_continue_37:: end
end

sgs.ai_skill_playerchosen.keshuaizhushou = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p)
		and #self.enemies<1
		then return p end
	end
end

local keshuaiyanggeex={}
keshuaiyanggeex.name="keshuaiyanggeex"
table.insert(package_skills,keshuaiyanggeex)
keshuaiyanggeex.getTurnUseCard = function(self,inclusive,request)
    return source_skill(self,"#keshuaiyanggeCard:.:")
end

sgs.ai_skill_use_func["#keshuaiyanggeCard"] = function(card,use,self,request)
	local dc = source_skill(self,"#MizhaoCard:.:")
	local d = package_known(self,"aiUseCard",dc)
	if d.card then
		for _,p in sgs.list(d.to)do
			if package_known(p,"hasSkill","keshuaiyangge") then
				use.card = card
				package_call(use.to,"append",p)
				return
			end
		end
	end
	if #self.toUse<2 then
		for _,p in sgs.list(self.friends_noself)do do
			if not package_known(p,"hasSkill","keshuaiyangge") then goto package_continue_38 end
			for _,e in sgs.list(self.enemies)do
				if package_known(self,"slashIsEffective",clone(self),e,p) then
					use.card = card
					package_call(use.to,"append",p)
					return
				end
			end
		end ::package_continue_38:: end
		if package_known(self.player,"getHandcardNum")/2<=#package_known(self,"poisonCards","h") then
			for _,p in sgs.list(self.enemies)do do
				if not package_known(p,"hasSkill","keshuaiyangge") then goto package_continue_39 end
				for _,e in sgs.list(self.enemies)do
					if p~=e and package_known(self,"slashIsEffective",clone(self),e,p) then
						use.card = card
						package_call(use.to,"append",p)
						return
					end
				end
			end ::package_continue_39:: end
		end
		if package_known(self.player,"getHandcardNum")<2 then
			for _,p in sgs.list(self.enemies)do do
				if not package_known(p,"hasSkill","keshuaiyangge") then goto package_continue_40 end
				for _,e in sgs.list(self.enemies)do
					if p~=e and package_known(self,"slashIsEffective",clone(self),e,p) then
						use.card = card
						package_call(use.to,"append",p)
						return
					end
				end
			end ::package_continue_40:: end
		end
	end
end

sgs.ai_use_value.keshuaiyanggeCard = 6.4
sgs.ai_use_priority.keshuaiyanggeCard = 1.4

local keshuaisaojian={}
keshuaisaojian.name="keshuaisaojian"
table.insert(package_skills,keshuaisaojian)
keshuaisaojian.getTurnUseCard = function(self,inclusive,request)
	return source_skill(self,"#keshuaisaojianCard:.:")
end

sgs.ai_skill_use_func["#keshuaisaojianCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies,"handcard",true)
	for _,to in sgs.list(self.enemies)do
     	if package_known(to,"getHandcardNum")>0 then
			use.card = card
			package_call(use.to,"append",to)
			break
		end
   	end
end

sgs.ai_use_value.keshuaisaojianCard = 6.4
sgs.ai_use_priority.keshuaisaojianCard = 8.4

local keshuaiguanshi={}
keshuaiguanshi.name="keshuaiguanshi"
table.insert(package_skills,keshuaiguanshi)
keshuaiguanshi.getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
   	for _,h in sgs.list(cards)do
   		if package_known(h,"isKindOf","Slash") then
			local dc = clone(self,"FireAttack")
			package_call(dc,"setSkillName","keshuaiguanshi")
			package_call(dc,"addSubcard",h)
			if package_known(dc,"isAvailable",self.player) then
				return dc
			end
		end
	end
end

sgs.ai_skill_invoke.keshuaicangxiong = function(self,data)
	local id = source_fact(self,"keshuaicangxiongId","toInt")
	local to = package_known(self.room,"getCardOwner",id)
	return not(to and package_known(self,"isFriend",to))
	and (not package_known(self.player,"hasSkill","keshuaibaowei",true) or package_known(self,"getKnownCardById",id):isAvailable(self.player))
end

sgs.ai_use_revises.keshuaibaowei = function(self,card,use)
	local n = 0
	local to = nil
	for _, dmd in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(dmd,"getStrategyMark","&keshuaibaowei-Clear")>0 then
			n = n+1
			to = dmd
		end
	end
	if n==1 and package_known(self,"isEnemy",to) then
		if package_known(card,"getTypeId")==3 or package_known(card,"getTypeId")==0
		then return end
		if package_known(card,"getTypeId")==1 and package_known(card,"targetFixed")
		then return end
		return false
	end
end

sgs.ai_skill_playerschosen.keshuairuzong = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) or not package_known(self,"isEnemy",p) and #self.enemies>0
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_invoke.keshuairuzong = function(self,data)
	return true
end

local keshuaidaoren={}
keshuaidaoren.name="keshuaidaoren"
table.insert(package_skills,keshuaidaoren)
keshuaidaoren.getTurnUseCard = function(self,inclusive,request)
    local cards = package_known(self.player,"getCards","h")
    cards = sgs.QList2Table(cards)
    package_call(self,"sortByKeepValue",cards)
	if #cards<2 then return end
	for _,h in sgs.list(cards)do
		return source_skill(self,"#keshuaidaorenCard:"..package_known(h,"getId")..":")
	end
end

sgs.ai_skill_use_func["#keshuaidaorenCard"] = function(card,use,self,request)
	local destlist = sgs.QList2Table(package_known(self.room,"getOtherPlayers",self.player))
	package_call(self,"sort",destlist)
	for _,p in sgs.list(self.friends_noself)do
		for _,to in sgs.list(destlist)do
			if package_known(self.player,"inMyAttackRange",to) and package_known(p,"inMyAttackRange",to) and package_known(self,"isEnemy",to) then
				package_call(use.to,"append",p)
				use.card = card
				return
			end
		end
	end
	for _,p in sgs.list(destlist)do do
     	if package_known(self,"isEnemy",unobserved_global(self,"to")) then goto package_continue_41 end
		for _,to in sgs.list(destlist)do
			if package_known(self.player,"inMyAttackRange",to) and package_known(p,"inMyAttackRange",to) and package_known(self,"isEnemy",to) then
				package_call(use.to,"append",p)
				use.card = card
				return
			end
		end
   	end ::package_continue_41:: end
	for _,p in sgs.list(destlist)do
		for _,to in sgs.list(destlist)do
			if package_known(self.player,"inMyAttackRange",to) and package_known(p,"inMyAttackRange",to) and package_known(self,"isEnemy",to) and package_known(self,"isWeak",to) then
				package_call(use.to,"append",p)
				use.card = card
				return
			end
		end
   	end
end

sgs.ai_use_value.keshuaidaorenCard = 3.4
sgs.ai_use_priority.keshuaidaorenCard = 2.4

sgs.ai_skill_invoke.keshuaixuchong = function(self,data)
	return true
end

sgs.ai_skill_choice.keshuaixuchong = function(self,choices)
	local items = package_known(choices,"split","+")
	local to = package_call(self.room,"getCurrent")
	if to==self.player then
		if package_known(self,"getOverflow")>1 then
			return items[2]
		end
	elseif package_known(self,"isFriend",to) and package_known(self,"isWeak",to) then
		if package_known(self,"getOverflow")>0 then
			return items[2]
		end
	end
	return items[1]
end

sgs.ai_skill_invoke.keshuaigangfen = function(self,data)
	local str = package_known(data,"toString")
	local use = source_fact(self,"keshuaigangfenData","toCardUse")
	if package_known(str,"contains","ask2") then
		if package_known(self,"isFriend",package_known(use.to,"at",0)) then
			return true
		end
	else
		if package_known(self,"isEnemy",use.from) and package_known(self,"isFriend",package_known(use.to,"at",0)) then
			return #self.friends>package_known(use.from,"getHandcardNum")/2
		end
	end
end

sgs.ai_skill_invoke.keshuaidangren = function(self,data)
	return true
end


local keshuaidangren={}
keshuaidangren.name="keshuaidangren"
table.insert(package_skills,keshuaidangren)
keshuaidangren.getTurnUseCard = function(self,inclusive,request)
	local dc = clone(self,"Peach")
	package_call(dc,"setSkillName","keshuaidangren")
	return dc
end

local keshuaiqiluan={}
keshuaiqiluan.name="keshuaiqiluan"
table.insert(package_skills,keshuaiqiluan)
keshuaiqiluan.getTurnUseCard = function(self,inclusive,request)
    local dc = clone(self)
	package_call(dc,"setSkillName","keshuaiqiluan")
	local d = package_known(self,"aiUseCard",dc)
	if d.card then
		local cards = package_known(self.player,"getCards","he")
		cards = sgs.QList2Table(cards)
		local tos = sgs.ai_skill_playerschosen.keshuaiqiluan(self,package_known(self.room,"getOtherPlayers",self.player),#cards,1)
		package_call(self,"sortByKeepValue",cards)
		local ids = {}
		for _,c1 in sgs.list(cards)do
			if #ids>=#tos then break end
			table.insert(ids,package_known(c1,"getId"))
		end
		if #ids<1 then return end
		save_plan(self,"keshuaiqiluanTo",d)
		return source_skill(self,"#keshuaiqiluanCard:"..table.concat(ids,"+")..":slash")
	end
end

sgs.ai_skill_use_func["#keshuaiqiluanCard"] = function(card,use,self,request)
	use.card = card
	use.to=load_plan(self,"keshuaiqiluanTo").to
end

sgs.ai_use_value.keshuaiqiluanCard = 6.4
sgs.ai_use_priority.keshuaiqiluanCard = 2.4

sgs.ai_skill_playerschosen.keshuaiqiluan = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,"handcard",true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and package_known(self,"isFriend",p) then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do do
		if table.contains(tos,p) then goto package_continue_42 end
		if #tos<=x/2 and not package_known(self,"isEnemy",p) then table.insert(tos,p) end
	end ::package_continue_42:: end
    return tos
end

sgs.ai_guhuo_card.keshuaiqiluan = function(self,toname,class_name)
	if package_known(self,"getCardsNum",class_name)>0 then return end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	local tos = sgs.ai_skill_playerschosen.keshuaiqiluan(self,package_known(self.room,"getOtherPlayers",self.player),#cards,1)
	package_call(self,"sortByKeepValue",cards)
	local ids = {}
	for _,c1 in sgs.list(cards)do
		if #ids>=#tos then break end
		table.insert(ids,package_known(c1,"getId"))
	end
	if #ids<1 then return end
	return skill_proposal("#keshuaiqiluanCard",ids,toname)
end

sgs.ai_skill_cardask.keshuaiqiluan = function(self,data,pattern,prompt)
    local parsed = package_call(data,"toPlayer")
    if package_known(self,"isFriend",parsed)
	then return true end
	return "."
end

local keshuaixiangjia={}
keshuaixiangjia.name="keshuaixiangjia"
table.insert(package_skills,keshuaixiangjia)
keshuaixiangjia.getTurnUseCard = function(self,inclusive,request)
	local dc = clone(self,"Collateral")
	package_call(dc,"setSkillName","keshuaixiangjia")
	return dc
end

sgs.ai_skill_invoke.keshuaixiangjia = function(self,data)
	return true
end

sgs.ai_skill_invoke.keshuaijueyin = function(self,data)
	return true
end

sgs.ai_skill_invoke.keshuaizonghai = function(self,data)
	local to = package_call(data,"toPlayer")
	return package_known(self,"isEnemy",to) or not package_known(self,"isFriend",to) and #self.enemies<1
end

sgs.ai_skill_playerschosen.keshuaizonghai = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and package_known(self,"isFriend",p) and getCardsNum("Peach",p,self.player)>0
		and package_known(p,"getHp")>1 then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and package_known(self,"isEnemy",p) and package_known(p,"getHp")<2
		then table.insert(tos,p) end
	end
	return tos
end


sgs.ai_skill_discard.keshuaisaojian = function(self,max,min,optional)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	return {cards[math.random(1,#cards)]}
end





local xingqiantun={}
xingqiantun.name="xingqiantun"
table.insert(package_skills,xingqiantun)
xingqiantun.getTurnUseCard = function(self,inclusive,request)
    return source_skill(self,"#xingqiantunCard:.:")
end

sgs.ai_skill_use_func["#xingqiantunCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies)
    for _,p in sgs.list(self.enemies)do
		if package_known(self.player,"canPindian",p)
		and package_known(self.player,"inMyAttackRange",p) then
			use.card = card
			package_call(use.to,"append",p)
			return
		end
	end
    for _,p in sgs.list(self.enemies)do
		if package_known(self.player,"canPindian",p) then
			use.card = card
			package_call(use.to,"append",p)
			return
		end
	end
end

sgs.ai_use_value.xingqiantunCard = 3.4
sgs.ai_use_priority.xingqiantunCard = 6.4

sgs.ai_skill_discard.xingqiantun = function(self,max,min,optional)
	local ids = {}
	local mc = package_call(self,"getMaxCard")
	if mc then table.insert(ids,package_known(mc,"getId")) end
	local xc = package_call(self,"getMinCard")
	if xc and xc~=mc then table.insert(ids,package_known(xc,"getId")) end
	return ids
end

sgs.ai_skill_discard.xingqiantun_pd = function(self,max,min,optional)
	local dc = sgs.QList2Table(source_fact(self,"xingqiantunIds","toIntList"))
	return {dc[math.random(1,#dc)]}
end

sgs.ai_skill_playerschosen.xingxiezheng = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and package_known(self,"isFriend",p) and getCardsNum("Slash",p,self.player)>0
		and package_known(p,"getHp")>1 then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and not package_known(self,"isFriend",p)
		and package_known(p,"getHandcardNum")>0
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(self.player,"canUse",clone(self,"_ov_binglinchengxia"),p)
		then return tos end
	end
	return {}
end

sgs.ai_skill_discard.xingxiezheng = function(self,max,min,optional)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	if package_known(self,"isFriend",package_call(self.room,"getCurrent")) then
		for _,c in sgs.list(cards)do
			if package_known(c,"isKindOf","Slash") then return {c} end
		end
	end
	return {cards[1]}
end

ai_skill_use["@@xingxiezheng!"]=function(self,prompt,request)
	local dc = clone(self,"_ov_binglinchengxia")
	package_call(dc,"setSkillName","_xingxiezheng")
	if package_known(dc,"isAvailable",self.player) then
		local dummy = package_known(self,"aiUseCard",dc)
		if dummy.card and dummy.to then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,package_known(p,"objectName"))
			end
			return selected(self,dc,tos)
		end
	end
end

sgs.ai_skill_invoke.xingzhaoxiong = function(self,data)
	return package_known(self.player,"getLostHp")>#self.enemies/2
end

local xingweisi={}
xingweisi.name="xingweisi"
table.insert(package_skills,xingweisi)
xingweisi.getTurnUseCard = function(self,inclusive,request)
    return source_skill(self,"#xingweisiCard:.:")
end

sgs.ai_skill_use_func["#xingweisiCard"] = function(card,use,self,request)
	local dc = clone(self,"duel")
	local d = package_known(self,"aiUseCard",dc)
    for _,p in sgs.list(d.to)do
		if package_known(self,"isEnemy",p) and package_known(self.player,"canUse",dc,p) then
			use.card = card
			package_call(use.to,"append",p)
			return
		end
	end
end

sgs.ai_use_value.xingweisiCard = 2.4
sgs.ai_use_priority.xingweisiCard = 2.4

sgs.ai_skill_discard.xingweisi = function(self,max,min,optional)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local ids = {}
	local has = true
	for _,c in sgs.list(cards)do do
		if package_known(c,"isKindOf","Slash") or package_known(c,"isKindOf","Nullification") then goto package_continue_43 end
		if package_known(c,"isKindOf","Jink") and has and #ids>0 and clone(self):isAvailable(package_call(self.room,"getCurrent"))
		and package_call(self.room,"getCurrent"):inMyAttackRange(self.player) then
			has = false
			goto package_continue_43
		end
		table.insert(ids,c)
	end ::package_continue_43:: end
	return ids
end

sgs.ai_skill_invoke.xingdangyi = function(self,data)
	local srt = package_known(data,"toString"):split(":")
	for _,p in sgs.list(self.enemies)do
		if package_known(p,"objectName")==srt[2] then
			return package_known(self,"isWeak") or package_known(self,"isWeak",p)
		end
	end
end

sgs.ai_target_revises.xingsheju = function(to,card,self,use)
    if package_known(card,"isKindOf","Slash") and package_known(use.to,"length")==1 then
		for _,h in sgs.list(package_known(self.player,"getHandcards"))do
			if not package_known(h,"isBlack") and package_known(card,"getEffectiveId")~=package_known(h,"getEffectiveId")
			then return end
		end
		return true
	end
end

sgs.ai_skill_playerchosen.xingchengliu = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(self,"damageIsEffective",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies<1
		and package_known(self,"damageIsEffective",p)
		then return p end
	end
end

sgs.ai_skill_cardask.xingchengliu1 = function(self,data,pattern,prompt)
	for _, p in sgs.list(self.enemies) do
		if package_known(p,"getStrategyMark","xingchengliuTo-Clear")<1 and package_known(self,"damageIsEffective",p)
		and package_known(self.player,"getEquips"):length()-package_known(p,"getEquips"):length()>1
		and (package_known(self,"isWeak",p) or not package_known(self,"isWeak")) then
			return true
		end
	end
	return "."
end

sgs.ai_skill_cardask.xingjianchuan0 = function(self,data,pattern,prompt)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _, id in sgs.list(package_known(data,"toIntList")) do
		local c = package_known(self,"getKnownCardById",id)
		local k = package_known(self,"getUseValue",c)
		for _, h in sgs.list(cards) do
			if k>package_known(self,"getUseValue",h) then
				return package_known(h,"getEffectiveId")
			end
		end
	end
	return "."
end

local xingfennan={}
xingfennan.name="xingfennan"
table.insert(package_skills,xingfennan)
xingfennan.getTurnUseCard = function(self,inclusive,request)
    return source_skill(self,"#xingfennanCard:.:")
end

sgs.ai_skill_use_func["#xingfennanCard"] = function(card,use,self,request)
	if package_known(self.player,"faceUp") then
		package_call(self,"sort",self.enemies,nil,true)
		for _,p in sgs.list(self.enemies)do
			if package_known(p,"getCardCount")>0 then
				use.card = card
				package_call(use.to,"append",p)
				return
			end
		end
	else
		package_call(self,"sort",self.friends,nil,true)
		for _,p in sgs.list(self.friends)do
			if #package_known(self,"poisonCards","ej",p)>0 then
				use.card = card
				package_call(use.to,"append",p)
				return
			end
		end
		for _,p in sgs.list(self.friends)do
			if package_known(p,"getCardCount")>0 then
				use.card = card
				package_call(use.to,"append",p)
				return
			end
		end
	end
end

sgs.ai_use_value.xingfennanCard = 2.4
sgs.ai_use_priority.xingfennanCard = 2.4

sgs.ai_skill_choice.xingfennan = function(self,choices,data)
	local items = package_known(choices,"split","+")
	local to = package_call(data,"toPlayer")
	if package_known(self,"isFriend",to) then
		if not package_known(to,"faceUp") or #package_known(self,"poisonCards","ej")>0 then
			return items[1]
		end
		return items[2]
	else
		if package_known(self,"getOverflow")>0 then
			return items[2]
		end
	end
	return items[1]
end

ai_skill_use["@@xingxunji"]=function(self,prompt,request)
	local valid = {}
	local destlist = package_known(self.room,"getAlivePlayers")
    destlist = package_call(self,"sort",destlist)
	local ids = {}
	local cards = {}
	for _,id in sgs.list(source_fact(self,"xingxunjiForAI","toIntList"))do
		table.insert(cards,package_known(self,"getKnownCardById",id))
	end
	for i=0,9 do
		local c,p = package_call(self,"getCardNeedPlayer",cards,nil,destlist)
		if c and p then
			table.insert(ids,package_known(c,"getId"))
			table.insert(valid,package_known(p,"objectName"))
			table.removeOne(cards,c)
			table.removeOne(destlist,p)
			if #cards<1 or #destlist<1 then break end
		end
	end
	if #valid>0 then
    	return response_skill(self,"#xingxunjiCard",ids,valid,request)
	end
end

local xingshanzheng={}
xingshanzheng.name="xingshanzheng"
table.insert(package_skills,xingshanzheng)
xingshanzheng.getTurnUseCard = function(self,inclusive,request)
    return source_skill(self,"#xingshanzhengCard:.:")
end

sgs.ai_skill_use_func["#xingshanzhengCard"] = function(card,use,self,request)
	package_call(self,"sort",self.friends_noself)
	for i,p in sgs.list(self.friends_noself)do
		if i<#self.friends_noself and package_known(p,"getHandcardNum")>0 then
			use.card = card
			package_call(use.to,"append",p)
		end
	end
	package_call(self,"sort",self.enemies)
	for i,p in sgs.list(self.enemies)do
		if i<#self.enemies and package_known(p,"getHandcardNum")>0 then
			use.card = card
			package_call(use.to,"append",p)
		end
	end
end

sgs.ai_use_value.xingshanzhengCard = 3.4
sgs.ai_use_priority.xingshanzhengCard = 6.4

sgs.ai_skill_invoke.xingxiongbao = function(self,data)
	return #self.enemies>=#self.friends_noself
end

sgs.ai_skill_invoke.xingfuran = function(self,data)
	return package_known(self.player,"getLostHp")>0
end

sgs.ai_skill_discard.xingqinrao = function(self,max,min,optional,equiped,pattern)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local ids = package_known(pattern,"split",",")
	local has = true
	for _,c in sgs.list(cards)do
		if table.contains(ids,package_known(c,"toString")) then
			local dc = clone(self,"duel")
			package_call(dc,"addSubcard",c)
			local d = package_known(self,"aiUseCard",dc,dummy(nil,99))
			if package_known(d.to,"contains",package_call(self.room,"getCurrent")) then
				return {package_known(c,"getId")}
			end
		end
	end
	return {}
end

local xingciying={}
xingciying.name="xingciying"
table.insert(package_skills,xingciying)
xingciying.getTurnUseCard = function(self,inclusive,request)
	local n = 4
	for _,m in ipairs(package_known(self.player,"getMarkNames")) do
		if package_known(m,"startsWith","&xingciying+") and package_known(self.player,"getStrategyMark",m)>0 then
			n = 1+n-#package_known(m,"split","+")
			break
		end
	end
	n = math.max(1,n)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _,pn in sgs.list(patterns_for(self))do
		local dc = clone(self,pn)
		if dc and package_known(dc,"isKindOf","BasicCard") then
			package_call(dc,"setSkillName","xingciying")
			local ids = sgs.IntList()
			for _,c in ipairs(cards) do
				package_call(dc,"addSubcards",ids)
				package_call(dc,"addSubcard",c)
				if package_known(dc,"isAvailable",self.player) then
					if package_known(dc,"subcardsLength")>=n and package_known(self,"aiUseCard",dc).card then
						return dc
					end
					package_call(ids,"append",package_known(c,"getId"))
				end
				package_call(dc,"clearSubcards")
			end
		end
	end
end

function sgs.ai_cardsview.xingciying(self,class_name,player)
   	local cards = sgs.QList2Table(package_known(player,"getCards","he"))
    package_call(self,"sortByKeepValue",cards)
	local dc = clone(self,class_name)
	package_call(dc,"setSkillName","xingciying")
	local n = 4
	for _,m in ipairs(package_known(player,"getMarkNames")) do
		if package_known(m,"startsWith","&xingciying+") and package_known(player,"getStrategyMark",m)>0 then
			n = 1+n-#package_known(m,"split","+")
			break
		end
	end
	n = math.max(1,n)
	local ids = sgs.IntList()
	for _,c in ipairs(cards) do
		package_call(dc,"addSubcards",ids)
		package_call(dc,"addSubcard",c)
		if not package_known(player,"isLocked",dc) then
			if package_known(dc,"subcardsLength")>=n then
				return proposal(self,dc)
			end
			package_call(ids,"append",package_known(c,"getId"))
		end
		package_call(dc,"clearSubcards")
	end
end

sgs.ai_skill_askforyiji.xingchendu = function(self,card_ids,tos)
    local p,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if p and id then return p,id end
	for _,p in sgs.list(tos)do
		if package_known(self,"isFriend",p) and package_known(self,"canDraw",p) then
			return p,card_ids[1]
		end
	end
	for _,p in sgs.list(tos)do
		if package_known(self,"isFriend",p) then
			return p,card_ids[1]
		end
	end
	return package_known(tos,"first"),card_ids[1]
end

local xingpiqi={}
xingpiqi.name="xingpiqi"
table.insert(package_skills,xingpiqi)
xingpiqi.getTurnUseCard = function(self,inclusive,request)
    return source_skill(self,"#xingpiqiCard:.:")
end

sgs.ai_skill_use_func["#xingpiqiCard"] = function(card,use,self,request)
	local dc = clone(self,"snatch")
	package_call(dc,"setSkillName","kehexuanfeng")
	for _,p in sgs.list(package_known(self,"aiUseCard",dc,dummy(nil,99)).to)do
		if package_known(p,"getStrategyMark","&xingpiqiUse-PlayClear")<1 then
			use.card = card
			package_call(use.to,"append",p)
			break
		end
	end
end

sgs.ai_use_value.xingpiqiCard = 4.4
sgs.ai_use_priority.xingpiqiCard = 9.4

function sgs.ai_cardsview.xingpiqivs(self,class_name,player)
   	local cards = sgs.QList2Table(package_known(player,"getCards","he"))
    package_call(self,"sortByKeepValue",cards)
	local dc = clone(self,"nullification")
	package_call(dc,"setSkillName","_xingpiqi")
	for _,c in ipairs(cards) do do
		if package_known(c,"isKindOf","Jink") then
			package_call(dc,"addSubcard",c)
			if package_known(self.player,"isLocked",dc) then
				package_call(dc,"clearSubcards")
				goto package_continue_44
			end
			return proposal(self,dc)
		end
	end ::package_continue_44:: end
end

sgs.ai_skill_playerschosen.xingzuodan = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and package_known(self,"isFriend",p)
		and package_known(p,"getHp")>1 then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and not package_known(self,"isEnemy",p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_playerchosen.xingzuodan = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) and package_known(self,"canDraw",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isEnemy",p) and #self.enemies<1
		and package_known(self,"canDraw",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p)
		then return p end
	end
end

sgs.ai_skill_playerchosen.xingcuibing = function(self,players)
	local destlist = sgs.QList2Table(players)
	package_call(self,"sort",destlist,nil,true)
	local n = package_known(self.player,"getStrategyMark","xingcuibing0")
    for _,p in sgs.list(destlist)do
		if package_known(self,"doDisCard",p,"he",n)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if package_known(self,"doDisCard",p,"he")
		then return p end
	end
end

sgs.ai_skill_playerschosen.xingfuzhen = function(self,players,x,n)
	if package_known(self.player,"getHp")<2 then return {} end
	local tos = {}
    local dc = clone(self,"thunder_slash")
	package_call(dc,"setSkillName","kehexuanfeng")
	local d = package_known(self,"aiUseCard",dc,dummy(nil,2))
	for _,p in sgs.list(players)do
		if #tos<x and package_known(d.to,"contains",p) then table.insert(tos,p) end
	end
	return tos
end

local xingzhuwei={}
xingzhuwei.name="xingzhuwei"
table.insert(package_skills,xingzhuwei)
xingzhuwei.getTurnUseCard = function(self,inclusive,request)
    return source_skill(self,"#xingzhuweiCard:.:")
end

sgs.ai_skill_use_func["#xingzhuweiCard"] = function(card,use,self,request)
	peiqi(self)
	for _,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
		if p==peiqi_state(self).from then
			use.card = card
			package_call(use.to,"append",p)
			break
		end
	end
end

sgs.ai_use_value.xingzhuweiCard = 4.4
sgs.ai_use_priority.xingzhuweiCard = 9.4

sgs.ai_skill_playerchosen["xingzhuwei"] = function(self,players)
	for _,p in sgs.list(players)do
		if p==peiqi_state(self).to
		then return p end
	end
end

sgs.ai_skill_cardchosen.xingzhuwei = function(self,who,flags,method)
	for _,e in sgs.list(package_known(who,"getCards",flags))do
		local id = package_known(e,"getEffectiveId")
		if id==peiqi_state(self).cid
		then return id end
	end
end

sgs.ai_skill_playerchosen.xingzhuwei1 = function(self,players)
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

local xingkuangjian={}
xingkuangjian.name="xingkuangjian"
table.insert(package_skills,xingkuangjian)
xingkuangjian.getTurnUseCard = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	for _,pn in sgs.list(patterns_for(self))do
		local dc = clone(self,pn)
		if dc and package_known(dc,"isKindOf","BasicCard") then
			package_call(dc,"setSkillName","xingkuangjian")
			for _,c in ipairs(cards) do
				if package_known(c,"isKindOf","EquipCard") then
					package_call(dc,"addSubcard",c)
					if package_known(dc,"isAvailable",self.player) then
						if package_known(self,"aiUseCard",dc).card then
							return dc
						end
					else
						package_call(dc,"clearSubcards")
					end
				end
			end
		end
	end
end

function sgs.ai_cardsview.xingkuangjian(self,class_name,player)
   	local cards = sgs.QList2Table(package_known(player,"getCards","he"))
    package_call(self,"sortByKeepValue",cards)
	local dc = clone(self,class_name)
	package_call(dc,"setSkillName","xingkuangjian")
	for _,c in ipairs(cards) do
		if package_known(c,"isKindOf","EquipCard") then
			package_call(dc,"addSubcard",c)
			if package_known(self.player,"isLocked",dc) then
				package_call(dc,"clearSubcards")
			else
				return proposal(self,dc)
			end
		end
	end
end






for _,skill in ipairs(package_skills)do local fn=skill.getTurnUseCard;sgs.ai_fill_skill[skill.name]=function(self,inclusive,request)local old=active_requests[self];active_requests[self]=request;local ok,v=pcall(fn,self,inclusive,request);active_requests[self]=old;if not ok then error(v,0)end;return finish_turn(self,v,request)end end
for selector in pairs(SELECTORS)do local fn=sgs.ai_skill_use_func[selector];if type(fn)=="function"then sgs.ai_skill_use_func[selector]=function(card,use,self,request)local old=active_requests[self];active_requests[self]=request;local r=table.pack(pcall(fn,card,use,self,request));active_requests[self]=old;if not r[1]then error(r[2],0)end;return table.unpack(r,2,r.n)end end end
sgs.ai_skill_choice.keqipingjian=function(self)return memory(self,"choice.keqipingjian")end
sgs.ai_skill_choice.kechengchengxian=function(self)return memory(self,"choice.kechengchengxian")end
sgs.ai_skill_choice.kezhuanzhenfeng=function(self)return memory(self,"choice.kezhuanzhenfeng")end
sgs.ai_skill_choice.kezhuancuifeng=function(self)return memory(self,"choice.kezhuancuifeng")end
sgs.ai_skill_choice.kezhuandengnan=function(self)return memory(self,"choice.kezhuandengnan")end
