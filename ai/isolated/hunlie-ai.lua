local PACKAGE="hunlie"
local SELECTORS={["#sgkgodhufuCard"]="sgkgodhufu",["#hujuzhihengCard"]="hujuzhiheng",["#sgkgodmeixinCard"]="sgkgodmeixin",["#sgkgodcuifengCard"]="sgkgodcuifeng",["#sgkgodjizhaoCard"]="sgkgodjizhao",["#sgkgodzhenhunCard"]="sgkgodzhenhun",["#sgkgodtongtianCard"]="sgkgodtongtian",["#tongtian_zhihengCard"]="tongtian_zhiheng",["#sgkgodjilueCard"]="sgkgodjilue",["#sgkgodyanmieCard"]="sgkgodyanmie",["#sgkgodzhijiCard"]="sgkgodzhiji",["#sgkgodgongxinCard"]="sgkgodgongxin",["#sgkgodzhonghunCard"]="sgkgodzhonghun",["#sgkgodshenfenCard"]="sgkgodshenfen",["#sgkgodtianqi"]="sgkgodtianqi",["#sgkgodyeyanCard"]="sgkgodyeyan",["#sgkgodliangyuanCard"]="sgkgodliangyuan",["#sgkgodjiquanCard"]="sgkgodjiquan",["#sgkgodrenzhengCard"]="sgkgodrenzheng",["#nos_sgkgodgongxinCard"]="nos_sgkgodgongxin",["#nos_sgkgodtongtianCard"]="nos_sgkgodtongtian",["#nos_sgkgodjilueCard"]="nos_sgkgodjilue",["#nos_sgkgoddanjingCard"]="nos_sgkgoddanjing",["#jlsgyanlieCard"]="jlsgyanlie",["#jlsgguiyuanCard"]="jlsgguiyuan",["#sgkgoddianjieCard"]="sgkgoddianjie",["#sgkgodqixingCard"]="sgkgodqixing",["#sgkgodkuangfengCard"]="sgkgodkuangfeng",["#sgkgoddawuCard"]="sgkgoddawu",["#sgkgodshenjiCard"]="sgkgodshenji",["#sgkgodfuhaiCard"]="sgkgodfuhai"}
local package_skills={}
-- Package-private source clone state. These plain records are not cards or receipts.
local active_requests=setmetatable({},{__mode="k"})
local clone_states=setmetatable({},{__mode='k'})
local function unsupported(key)ai_unsupported('source capability is not projected',PACKAGE..'.'..key)end

-- Remaining package facts (Analeptic::IsAvailable, the 1v1 rule config) are native
-- answers that are not projected.
local function fact(self,key)unsupported(key)end
local function clone(self,name,skill,suit,number)
 name=name or 'slash';local p=self:cloneEvaluationCard(name)
 if p==false then return nil end;if not p then unsupported('prototype.'..tostring(name))end
 local v={};clone_states[v]={self=self,name=p:objectName(),skill=skill or '',suit=suit==nil and sgs.Card_NoSuit or suit,number=number or 0,costs={},prototype=p,flags={}}
 return v
end
local function materialize(v)
 local s=clone_states[v];if not s then return v end
 if next(s.flags) then unsupported('clone_flags.'..s.skill)end
 local card
 if s.skill=='' and #s.costs==0 and s.suit==sgs.Card_NoSuit and s.number==0 then card=s.prototype
 else card=s.self:evaluateSkillCard(s.skill, s.name, s.costs)end
 if not card then unsupported('clone.'..s.skill..'.'..s.name)end
 -- Current narrow endpoint has no arbitrary face parameters. A mismatched native
 -- clone is unknown, never a substitute with different suit/rank.
 if #s.costs==0 and (card:getSuit()~=s.suit or card:getNumber()~=s.number)then unsupported('clone_face.'..s.skill)end
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
  if k=='setSkillName'then s.skill=args[1];return end
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
-- Own tags read through the donor's QVariant conversions; an absent tag is the
-- conversion's default. HpLost/MaxHp struct tags are not projected, and a projected
-- CardsMoveOneTime tag lacks the from_places and hand-bound ids these consumers read.
local function source_fact(self,key,kind)
 if kind=='toHpLost'or kind=='toMaxHp'or kind=='toMoveOneTime'then unsupported('struct_tag.'..key)end
 local v=self.player:getTag(key)
 local function player(name)return type(name)=='string'and name~=''and package_known(self.room,'findPlayerByObjectName',name,true)or nil end
 local function card(row)return type(row)=='table'and next(row)~=nil and CardView.new(row)or nil end
 if kind=='toPlayer'then if v~=nil and type(v)~='string'then unsupported(key..'.'..kind)end;return player(v)end
 if kind=='toInt'then return tonumber(v)or 0 end
 if kind=='toString'then if v==nil then return''end;if type(v)~='string'then unsupported(key..'.'..kind)end;return v end
 if kind=='toBool'then
  if v==nil then return false end;if type(v)=='boolean'then return v end
  if type(v)=='string'then return v~=''and v~='0'and v:lower()~='false'end
  unsupported(key..'.'..kind)
 end
 if kind=='toIntList'then return AIList.new(v or{})end
 if kind=='toJudge'then if v==nil then return nil end;local j={};for k,x in pairs(v)do j[k]=x end;j.who=j.who and package_known(self.room,'findPlayerByObjectName',j.who,true);j.card=j.card and CardView.new(j.card);function j:isGood(c)if not c then return self.good end;if self.outcomes_complete~=true or type(self.outcome_by_id)~='table'then unsupported('judge_outcomes.'..key)end;local n=self.outcome_by_id[tostring(package_known(c,'getEffectiveId'))];if type(n)~='boolean'then unsupported('judge_outcome.'..key)end;return n end;function j:isBad(c)return not self:isGood(c)end;return j end
 if kind=='toCardUse'then
  if v==nil then return{to=AIList.new({})}end
  local u={card=card(v.card),from=player(v.from),to=AIList.new({})}
  for _,n in ipairs(v.to or{})do u.to:append(package_known(self.room,'findPlayerByObjectName',n,true))end;return u
 end
 if kind=='toDamage'then
  if v==nil then return{damage=1,nature=sgs.DamageStruct_Normal}end -- DamageStruct()
  local d={};for k,x in pairs(v)do d[k]=x end;d.from=player(v.from);d.to=player(v.to);d.card=card(v.card);d.damage=v.amount;return d
 end
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

-- The donor reads its Room-VM free global `natrue`; that VM's globals are not projected.
local function typo_natrue(self)unsupported("global_natrue")end
local function actor_ai(player)local a=player and player._room and player._room._ai;if not a or a.player~=player then unsupported("view_as_owner")end;return a end
-- Engine::translate is not projected.
local function translation(self,name)unsupported("translation")end
local function clone_native(self,name,suit,number)return clone(self,name,nil,suit,number)end
local function conversion_clone(self,name,skill,suit,number,ids)local c=clone(self,name,skill,suit,number);clone_states[c].costs=ids;return c end
local function owner_fact(self,player,key)if player~=self.player then unsupported("foreign_tag."..key)end;return source_fact(self,key,"toString")end
-- Only the viewer's own properties are projected; getPropertyValue rejects others.
local function public_property(self,player,key)local v=player:getPropertyValue(key);if v==nil then return""end;if type(v)~="string"then unsupported("property."..key)end;return v end
local function disclosed_top(self,skill)unsupported("hidden_top."..skill)end
-- Engine::getCurrentCardUseReason is the reason of the card ask being answered.
local function owner_reason(self)local r=self.request;if type(r)~="table"or(r.kind~="activate"and r.kind~="use_card"and r.kind~="respond_card")or type(r.reason)~="number"then unsupported("current_card_use_reason")end;return r.reason end
local function skill_proposal(selector,costs,user)local skill=SELECTORS[selector];if not skill then unsupported("response_selector."..selector)end;return{name=selector:sub(2),skill=skill,subcards=costs,suit=sgs.Card_NoSuit,number=0,user_string=user}end
local function lawful_hand(self,player)
 if player==self.player then return package_known(player,"getHandcards")end
 local cards,known=package_call(self,"getKnownCards",player,self.player,"h")
 if not cards then unsupported("known_hand")end
 if (known or #cards)<package_known(player,"getHandcardNum")then package_known(self,"useKnowledgeEstimate",{value=#cards,status="estimate",basis="hunlie.canSaveSelf visible spade evidence only; unseen spade inactive prior",viewer=package_known(self.player,"objectName"),target=package_known(player,"objectName")},"hunlie.canSaveSelf")end
 return cards
end

sgs.ai_skill_cardask["@sgkgodzhiming"] = function(self, data, pattern, target)
    local current = package_call(self.room,"getCurrent")
	if package_known(self,"isEnemy",current) and not package_known(self.player,"isKongcheng") then
	    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
		package_call(self,"sortByKeepValue",cards)
		return package_known(cards[1],"getId")
	else
		return "."
	end
end

sgs.ai_skill_choice["sgkgodzhiming"] = function(self, choices, data)
	local room = self.room
	local current = package_call(room,"getCurrent")
	if package_known(current,"getHandcardNum") >= package_known(current,"getHp") then
	    return "sgkgodzhimingplay"
	end
	if (package_known(current,"hasSkills","yongsi|haoshi|juejing|yingzi|nosyingzi|tuxi|nostuxi") and package_known(current,"getHandcardNum") <= 2) or package_known(current,"isKongcheng")
	        or package_known(current,"getHp") > package_known(current,"getHandcardNum") then
		return "sgkgodzhimingdraw"
	end
	return "sgkgodzhimingplay"
end



sgs.ai_skill_playerchosen.sgkgodsuyin = function(self, targets)
    local target = {}
	for _, t in sgs.qlist(targets) do
	    if package_known(self,"isEnemy",t) and package_known(t,"faceUp") then
		    table.insert(target, t)
		end
		if package_known(self,"isFriend",t) and (not package_known(t,"faceUp")) then
		    table.insert(target, t)
		end
	end
	if #target > 0 then
	    package_call(self,"sort",target, "defense")
		return target[1]
	end
end

sgs.ai_skill_invoke.sgkgodsuyin = function(self, data)
    local a = 0
	for _, t in ipairs(self.enemies) do
	    if package_known(t,"faceUp") then a = a + 1 end
	end
	for _, p in ipairs(self.friends_noself) do
	    if not package_known(p,"faceUp") then a = a + 1 end
	end
	if a > 0 then return true end
	return false
end



sgs.ai_skill_choice["sgkgodhuju"] = function(self, choices, data)
    local huju = package_known(choices,"split","+")
	if package_known(self,"getCardsNum","Peach") >= package_known(self.player,"getLostHp") or package_known(self.player,"getLostHp") == 1 then
	    return huju[1]
	end
	return huju[2]
end



local sgkgodhufu_skill={}
sgkgodhufu_skill.name="sgkgodhufu"
table.insert(package_skills, sgkgodhufu_skill)
sgkgodhufu_skill.getTurnUseCard=function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#sgkgodhufuCard") then return end
	if #self.enemies <= 0 then return end
	return source_skill(self,"#sgkgodhufuCard:.:")
end

sgs.ai_skill_use_func["#sgkgodhufuCard"] = function(card,use,self,request)
    local targets = {}
	for _, p in ipairs(self.enemies) do
	    if package_known(p,"getEquips"):length() >= 1 then
	        table.insert(targets, p)
		end
	end
	if #targets == 0 then return nil end
	local target = targets[math.random(1, #targets)]
	use.card = card
	if use.to then package_call(use.to,"append",target) end
	return
end

sgs.ai_use_value["sgkgodhufuCard"] = 8
sgs.ai_use_priority["sgkgodhufuCard"] = 8
sgs.ai_card_intention["sgkgodhufuCard"]  = 80



local hujuzhiheng_skill = {}
hujuzhiheng_skill.name = "hujuzhiheng"
table.insert(package_skills, hujuzhiheng_skill)
hujuzhiheng_skill.getTurnUseCard = function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#hujuzhihengCard") then
		return source_skill(self,"#hujuzhihengCard:.:")
	end
end

sgs.ai_skill_use_func["#hujuzhihengCard"] = function(card,use,self,request)
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
				if use_slash_num<=package_known(card,"getTargetModResidue",self.player)
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

		if package_call(self.player,"getWeapon") and package_known(self.player,"getHandcardNum")<3 then
			table.insert(unpreferedCards,package_call(self.player,"getWeapon"):getId())
		end

		if package_known(self,"needToThrowArmor") then
			table.insert(unpreferedCards,package_call(self.player,"getArmor"):getId())
		end

		if package_known(self.player,"getOffensiveHorse") and package_call(self.player,"getWeapon") then
			table.insert(unpreferedCards,package_known(self.player,"getOffensiveHorse"):getId())
		end
	end

	for i = #unpreferedCards,1,-1 do
		if package_known(self,"getKnownCardById",unpreferedCards[i]):isKindOf("WoodenOx") and package_known(self.player,"getPile","wooden_ox"):length()>1 then
			table.removeOne(unpreferedCards,unpreferedCards[i])
		end
	end

	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not package_known(self.player,"isJilei",package_known(self,"getKnownCardById",unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		if package_known(self.room,"getMode")=="02_1v1" and fact(self,"one_v_one_rule")~="Classical" then
			local use_cards_kof = {use_cards[1]}
			if #use_cards>1 then table.insert(use_cards_kof,use_cards[2]) end
			use.card = source_skill(self,"#hujuzhihengCard:"..table.concat(use_cards_kof,"+")..":")
		else
			use.card = source_skill(self,"#hujuzhihengCard:"..table.concat(use_cards,"+")..":")
		end
	end
end

sgs.ai_use_value["hujuzhihengCard"] = 9
sgs.ai_use_priority["hujuzhihengCard"] = 2.61
sgs.dynamic_value.benefit["hujuzhihengCard"] = true


function sgs.ai_cardneed.hujuzhiheng(to, card)
	return not package_known(card,"isKindOf","Jink")
end



local sgkgodmeixin_skill = {}
sgkgodmeixin_skill.name = "sgkgodmeixin"
table.insert(package_skills, sgkgodmeixin_skill)
sgkgodmeixin_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.enemies == 0 then return nil end
	local a = 0
	for _, p in ipairs(self.enemies) do
	    if package_known(p,"isMale") and package_known(p,"getStrategyMark","&sgkgodmeixin") == 0 then a = a+1 end
	end
	if a <= 0 then return nil end
	return source_skill(self,"#sgkgodmeixinCard:.:")
end

sgs.ai_skill_use_func["#sgkgodmeixinCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies, "threat")
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	local need_num = 1
	for _, man in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
		if package_known(man,"getStrategyMark","&sgkgodmeixin") > 0 then need_num = need_num + 1 end
	end
	if package_known(self,"isWeak") and #cards - need_num <= 1 then return nil end
	local meixin_ids = {}
	local target
	for _, enemy in ipairs(self.enemies) do
	    if package_known(enemy,"isMale") and package_known(enemy,"getStrategyMark","&sgkgodmeixin") == 0 then
		    target = enemy
			break
		end
	end
	if not target then return nil end
	if target then
		for _, c in sgs.list(cards) do
			table.insert(meixin_ids, package_known(c,"getEffectiveId"))
			if #meixin_ids == need_num then break end
		end
		if #meixin_ids == need_num then
			use.card = source_skill(self,"#sgkgodmeixinCard:" .. table.concat(meixin_ids, "+") .. ":")
			if use.to then package_call(use.to,"append",target) end
		end
	end
end

sgs.ai_use_value["sgkgodmeixinCard"] = 10
sgs.ai_use_priority["sgkgodmeixinCard"] = 10
sgs.ai_card_intention["sgkgodmeixinCard"]  = 80



sgs.ai_skill_invoke.sgkgoddianjie = function(self, data)
    local a = math.abs(package_known(self.player,"getHandcardNum")-package_known(self.player,"getHp"))
	if #self.enemies == 0 then
	    if package_known(self.player,"hasSkill","sgkgodleihun") and not package_known(self.player,"hasSkill","jueqing") then
	        if not package_known(self.player,"isWounded") then
		        return false
	        else
	            if a <= 2 then return true end
		    end
		end
	else
	    if package_known(self.player,"getHp") <= 1 then return true end
		if a <= 1 then return true end
	end
end

sgs.ai_skill_playerchosen.sgkgoddianjie = function(self, targets)
	local target = nil
	for _, t in sgs.qlist(targets) do
		if package_known(t,"hasSkill","sgkgodleihun") and (not package_known(t,"hasSkill","jueqing")) and package_known(t,"objectName") == package_known(self.player,"objectName") and package_known(self.player,"getHp") <= 1 then
			target = t
			break
		end
	end
	if not target then
		local leihun = {}
		for _, _player in sgs.qlist(targets) do
			if package_known(self,"isEnemy",_player) and package_known(self,"damageIsEffective",_player, sgs.DamageStruct_Thunder, self.player) and package_known(self,"isGoodTarget",_player,targets) then
				table.insert(leihun, _player)
			end
		end
		if #leihun == 0 then return nil end
		package_call(self,"sort",leihun, "hp")
		target = leihun[1]
	end
	return target
end

ai_skill_use["@@sgkgoddianjie"]=function(self,prompt,request)
    if #self.enemies <= 0 then return "." end
    local tos = {}
	for _, enemy in ipairs(self.enemies) do
	    if not package_known(enemy,"isChained") then table.insert(tos, package_known(enemy,"objectName")) end
	end
	if not package_known(self.player,"isChained") and not package_known(self.player,"hasSkill","jueqing") and package_known(self.player,"hasSkill","sgkgodleihun") then table.insert(package_known(self.player,"objectName")) end
	if #tos > 1 then return response_skill(self,"#sgkgoddianjieCard",{},tos,request) else return "." end
end


sgs.ai_skill_invoke.sgkgodshendao = function(self, data)
    local judge = package_known(data,"toJudge")
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
		if package_known(p,"getCards","ej"):length() > 0 then
			package_call(targets,"append",p)
		end
	end
	local judge_fromhandcardmyself = false
	local to = {}
	if package_known(self,"needRetrial",judge) then
	    for _, t in sgs.qlist(targets) do
	        if package_known(self.player,"objectName") == package_known(t,"objectName") and package_known(self,"getRetrialCardId",sgs.QList2Table(package_known(t,"getCards","ej")), judge) ~= -1 then table.insert(to, t) end
		    if package_known(self,"isEnemy",t) then
		        if package_known(self,"getRetrialCardId",sgs.QList2Table(package_known(t,"getCards","e")), judge) ~= -1 then table.insert(to, t) end
		    else
		        if package_known(self,"getRetrialCardId",sgs.QList2Table(package_known(t,"getCards","ej")), judge) ~= -1 then table.insert(to, t) end
			end
		end
		if package_known(self,"getRetrialCardId",sgs.QList2Table(package_known(self.player,"getHandcards")), judge) ~= -1 then judge_fromhandcardmyself = true end
	end
	if judge_fromhandcardmyself or #to > 0 then
	    if package_known(judge,"isGood") and package_known(self,"isEnemy",judge.who) then return true end
	    if package_known(judge,"isBad") and package_known(self,"isFriend",judge.who) then return true end
	end
	return false
end

sgs.ai_skill_choice["sgkgodshendao"] = function(self, choices, data)
	local judge = package_known(data,"toJudge")
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
		if package_known(p,"getCards","ej"):length() > 0 then
			package_call(targets,"append",p)
		end
	end
	local judge_fromhandcardmyself = false
	local to = {}
	if package_known(self,"needRetrial",judge) then
	    for _, t in sgs.qlist(targets) do
	        if package_known(self.player,"objectName") == package_known(t,"objectName") and package_known(self,"getRetrialCardId",sgs.QList2Table(package_known(t,"getCards","ej")), judge) ~= -1 then table.insert(to, t) end
		    if package_known(self,"isEnemy",t) then
		        if package_known(self,"getRetrialCardId",sgs.QList2Table(package_known(t,"getCards","e")), judge) ~= -1 then table.insert(to, t) end
		    else
		        if package_known(self,"getRetrialCardId",sgs.QList2Table(package_known(t,"getCards","ej")), judge) ~= -1 then table.insert(to, t) end
			end
		end
		if package_known(self,"getRetrialCardId",sgs.QList2Table(package_known(self.player,"getHandcards")), judge) ~= -1 then judge_fromhandcardmyself = true end
		if #to > 0 and (not judge_fromhandcardmyself) then return "shendao_wholearea" end
		if #to <= 0 and judge_fromhandcardmyself then return "shendao_selfhandcard" end
		if #to > 0 and judge_fromhandcardmyself then
		    local shendao = package_known(choices,"split","+")
			return shendao[math.random(1, #shendao)]
		end
	end
end

sgs.ai_skill_cardask["@shendao-card"]=function(self, data)
	local judge = package_known(data,"toJudge")
	if package_known(self.room,"getMode"):find("_mini_46") and not package_known(judge,"isGood") then
		return package_known(self.player,"handCards"):first() end
	if package_known(self,"needRetrial",judge) then
		local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
		local card_id = package_known(self,"getRetrialCardId",cards, judge)
		if card_id ~= -1 then
			return card_id
		end
	end
	return "."
end

sgs.ai_skill_cardchosen.sgkgodshendao = function(self, who, flags)
	local cards = {}
	local judge = source_fact(self,"shendao_judge","toJudge")
	local to = judge.who
	local card = judge.card
	local reason = judge.reason
	if package_known(self,"needRetrial",judge) then
		if package_known(self,"isFriend",who) then
		    if package_known(who,"getCards","j"):length() > 0 then
			    cards = sgs.QList2Table(package_known(who,"getCards","j"))
			else
			    cards = sgs.QList2Table(package_known(who,"getCards","ej"))
			end
		elseif package_known(self,"isEnemy",who) then
		    if package_known(who,"getCards","e"):length() > 0 then
			    cards = sgs.QList2Table(package_known(who,"getCards","e"))
			end
			if package_known(who,"hasSkills","guidao|guicai|sr_guicai|hongyan|wuyan|nosguicai|huanshi") then
			    if package_known(who,"getCards","e") > 0 then
				    for _, icard in sgs.qlist(package_known(who,"getCards","e")) do
					    table.insert(cards, icard)
					end
				end
				if package_known(who,"getCards","j") > 0 then
				    for _, c in sgs.qlist(package_known(who,"getCards","j")) do
					    if package_known(c,"isKindOf","Lightning") then table.insert(cards, c) end
					end
				end
			end
		end
		package_call(self,"sortByKeepValue",cards)
		local card_id = package_known(self,"getRetrialCardId",cards, judge)
		if card_id ~= -1 then return card_id end
	end
end

sgs.ai_skill_playerchosen.sgkgodshendao = function(self, targets)
    local judge = source_fact(self,"shendao_judge","toJudge")
	local who = judge.who
	local card = judge.card
	local to = {}
	if package_known(self,"needRetrial",judge) then
	    for _, t in sgs.qlist(targets) do
	        if package_known(self.player,"objectName") == package_known(t,"objectName") then table.insert(to, t) end
		    if package_known(self,"isEnemy",t) then
		        if package_known(self,"getRetrialCardId",sgs.QList2Table(package_known(t,"getCards","e")), judge) ~= -1 then table.insert(to, t) end
		    else
		        if package_known(self,"getRetrialCardId",sgs.QList2Table(package_known(t,"getCards","ej")), judge) ~= -1 then table.insert(to, t) end
			end
		end
		if #to > 0 then
	        package_call(self,"sort",to, "value")
		    return to[1]
	    end
	end
	return
end
sgs.wizard_skill = sgs.wizard_skill .. "|sgkgodshendao"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|sgkgodshendao"


sgs.ai_slash_prohibit.sgkgodleihun = function(self, from, to, card)
	if package_known(to,"hasSkill","sgkgodleihun") and package_known(card,"isKindOf","ThunderSlash") then
	    if not package_known(from,"hasSkill","jueqing") then
		    return true
		else
		    return false
		end
	end
end



local sgkgodcuifeng_skill = {}
sgkgodcuifeng_skill.name = "sgkgodcuifeng"
table.insert(package_skills, sgkgodcuifeng_skill)
sgkgodcuifeng_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#sgkgodcuifengCard") then return nil end
	if #self.enemies == 0 then return nil end
	return source_skill(self,"#sgkgodcuifengCard:.:")
end

sgs.ai_skill_use_func["#sgkgodcuifengCard"] = function(card,use,self,request)
    local target
	package_call(self,"sort",self.friends, "defense")
	for _, friend in ipairs(self.friends) do
	    if package_known(friend,"getStrategyMark","&nizhan") > 0 then
		    target = friend
			break
		end
	end
	if not target then
		package_call(self,"sort",self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if package_known(enemy,"getStrategyMark","&nizhan") > 0 then
				target = enemy
				break
			end
		end
	end
	if target then
	    use.card = card
		if use.to then package_call(use.to,"append",target) end
	end
end

sgs.ai_skill_playerchosen["sgkgodcuifeng"] = function(self, targets)
	local players = {}
	for _, p in sgs.qlist(targets) do
		if package_known(self,"isEnemy",p) then table.insert(players, p) end
	end
	if #players > 0 then
	    package_call(self,"sort",players, "hp")
		return players[1]
	else
	    package_call(self,"sort",self.enemies, "hp")
		return self.enemies[1]
	end
end

sgs.ai_use_value["sgkgodcuifengCard"] = 8
sgs.ai_use_priority["sgkgodcuifengCard"] = 6
sgs.ai_ajustdamage_from.sgkgodweizhen = function(self, from, to, card, nature)
	if package_known(to,"getStrategyMark","&nizhan") >= 3 then
		return 1
	end
end


sgs.ai_skill_cardask["@junwang"] = function(self, data, pattern)
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByKeepValue",cards)
	local liubei = package_call(self.room,"findPlayerBySkillName","sgkgodjunwang")
	local junwangcard
	if package_known(self,"isEnemy",liubei) or (not package_known(self,"isFriend",liubei))then
		if package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") == #cards then
			junwangcard = cards[math.random(1, #cards)]
		else
			local bc
			for _, card in ipairs(cards) do
				if (not package_known(card,"isKindOf","Peach")) and (not package_known(card,"isKindOf","Analeptic")) then
					bc = card
					break
				end
			end
			junwangcard = bc
		end
	else
		if package_known(self,"isFriend",liubei) then
			if (package_known(liubei,"containsTrick","SupplyShortage") or package_known(liubei,"containsTrick","Indulgence")) and package_known(self,"getCardsNum","Nullification") > 0 then
				for _, card in ipairs(cards) do
					if package_known(card,"isKindOf","Nullification") then
						junwangcard = card
						break
					end
				end
			end
			if not junwangcard then
				if package_known(self,"isWeak",liubei) and (package_known(self,"getCardsNum","Peach") > 0 or package_known(self,"getCardsNum","Analeptic") > 0) then
					for _, card in ipairs(cards) do
						if package_known(card,"isKindOf","Peach") or package_known(card,"isKindOf","Analeptic") then
							junwangcard = card
							break
						end
					end
				end
			end
			if not junwangcard then
				if package_known(liubei,"hasSkills","jizhi|nosjizhi") then
					for _, card in ipairs(cards) do
						if package_known(card,"isNDTrick") then
							junwangcard = card
							break
						end
					end
				end
			end
			if not junwangcard then
				if package_known(liubei,"hasSkills","qiangxi|sgkgodzhiji") then
					for _, card in ipairs(cards) do
						if package_known(card,"isKindOf","Weapon") then
							junwangcard = card
							break
						end
					end
				end
			end
			if not junwangcard then
				junwangcard = cards[math.random(1, #cards)]
			end
		end
	end
	if not junwangcard then
		junwangcard = cards[math.random(1, #cards)]
	end
	return package_known(junwangcard,"getEffectiveId")
end



ai_skill_use["@@sgkgodjizhao"]=function(self,prompt,request)
    if package_known(self.player,"isKongcheng") then return "." end
	if #self.enemies <= 0 then return "." end
	if package_known(self.player,"getHandcardNum") - package_known(self,"getCardsNum","Peach") - package_known(self,"getCardsNum","Analeptic") <= 0 then return "." end
	if package_known(self.player,"getHandcardNum") <= 2 and package_known(self.player,"getHp") <= 2 then return "." end
    local cards = package_known(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local jizhao_card
	for _, card in ipairs(cards) do
	    if (not package_known(card,"isKindOf","Peach")) and (not package_known(card,"isKindOf","Analeptic")) then
		    jizhao_card = card
			break
		end
	end
	if not jizhao_card then return "." end
	package_call(self,"sort",self.enemies, "defense")
	return response_skill(self,"#sgkgodjizhaoCard",{package_known(jizhao_card,"getEffectiveId")},{package_known(self.enemies[1],"objectName")},request)
end

sgs.ai_skill_invoke.sgkgodjizhao = function(self, data)
    local enemy_marks, friend_marks = 0, 0
	for _, p in sgs.qlist(package_known(self.room,"getAlivePlayers")) do
	    local n = package_known(p,"getStrategyMark","&zhao")
		if n > 0 then
		    if package_known(self,"isEnemy",p) then enemy_marks = enemy_marks + n
			elseif package_known(self,"isFriend",p) then friend_marks = friend_marks + n end
		end
	end
	return enemy_marks > friend_marks
end

sgs.ai_skill_invoke.sgkgodjizhao_damage = function(self, data)
    local damage = package_known(data,"toDamage")
	if damage and package_known(damage,"getTo") then
	    return package_known(self,"isEnemy",package_known(damage,"getTo"))
	end
	return false
end

sgs.ai_use_value["sgkgodjizhaoCard"] = 9
sgs.ai_use_priority["sgkgodjizhaoCard"] = 3



local sgkgodshayi_skill = {}
sgkgodshayi_skill.name = "sgkgodshayi"
table.insert(package_skills, sgkgodshayi_skill)
sgkgodshayi_skill.getTurnUseCard = function(self,inclusive,request)

	local cards = package_known(self.player,"getCards","he")
	cards=sgs.QList2Table(cards)
	package_call(self,"sortByUseValue",cards, true)
	local shayi_slash
	for _, card in ipairs(cards) do
	    if package_known(card,"hasTip","sgkgodshayi") then
		    shayi_slash = card
			break
		end
	end
	if not shayi_slash then return nil end
	local suit = package_known(shayi_slash,"getSuitString")
	local number = package_known(shayi_slash,"getNumberString")
	local card_id = package_known(shayi_slash,"getEffectiveId")
	local card_str = ("slash:sgkgodshayi[%s:%s]=%d"):format(suit, number, card_id)
	local slash=clone(self,"slash","sgkgodshayi",package_known(shayi_slash,"getSuit"),package_known(shayi_slash,"getNumber"));package_call(slash,"addSubcard",shayi_slash)
	assert(slash)
	return slash
end

sgs.ai_view_as["sgkgodshayi"] = function(card, player, card_place)
 local self=actor_ai(player)
    local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if package_known(card,"hasTip","sgkgodshayi") then
		return {name="slash",skill="sgkgodshayi",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|sgkgodshayi"


local sgkgodzhenhun_skill = {}
sgkgodzhenhun_skill.name = "sgkgodzhenhun"
table.insert(package_skills, sgkgodzhenhun_skill)
sgkgodzhenhun_skill.getTurnUseCard = function(self,inclusive,request)
    if #self.enemies == 0 then return nil end
	if package_known(self.player,"hasUsed","#sgkgodzhenhunCard") then return nil end
	return source_skill(self,"#sgkgodzhenhunCard:.:")
end

sgs.ai_skill_use_func["#sgkgodzhenhunCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value["sgkgodzhenhunCard"] = 10
sgs.ai_use_priority["sgkgodzhenhunCard"] = sgs.ai_use_priority.ExNihilo + 2



sgs.ai_skill_invoke.sgkgodluezhen = function(self, data)
    local use = package_known(data,"toCardUse")
	local ganning = package_call(self.room,"findPlayerBySkillName","sgkgodluezhen")
	if package_known(use.card,"isKindOf","Slash") and package_known(use.from,"objectName") == package_known(ganning,"objectName") and not package_known(use.to,"contains",ganning) then
	    for _, t in sgs.qlist(use.to) do
		    if package_known(self,"isEnemy",t) then
			    return true
			end
		end
	end
	return false
end

sgs.ai_cardneed.sgkgodluezhen = sgs.ai_cardneed.slash

local sgkgodyoulong_skill = {}
sgkgodyoulong_skill.name = "sgkgodyoulong"
table.insert(package_skills, sgkgodyoulong_skill)
sgkgodyoulong_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyMark","youlong") == 0 then return nil end
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards,true)
	local youlong_black
	for _, card in ipairs(cards) do
	    if package_known(card,"isBlack") and ((package_known(self,"getUseValue",card) < sgs.ai_use_value.Snatch) or inclusive) then
		    local shouldUse = true
			if package_known(card,"isKindOf","Slash") then
				local dummy_use = {isDummy = true}
				if package_known(self,"getCardsNum","Slash") == 1 then
					package_call(self,"useBasicCard",card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end
			if package_known(self,"getUseValue",card) > sgs.ai_use_value.Snatch and package_known(card,"isKindOf","TrickCard") then
				local dummy_use = {isDummy = true}
				package_call(self,"useTrickCard",card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse then
				youlong_black = card
				break
			end
		end
	end
	if youlong_black then
		local suit = package_known(youlong_black,"getSuitString")
		local number = package_known(youlong_black,"getNumberString")
		local card_id = package_known(youlong_black,"getEffectiveId")
		local card_str = ("snatch:sgkgodyoulong[%s:%s]=%d"):format(suit, number, card_id)
		local youlong_snatch=clone(self,"snatch","sgkgodyoulong",package_known(youlong_black,"getSuit"),package_known(youlong_black,"getNumber"));package_call(youlong_snatch,"addSubcard",youlong_black)
		assert(youlong_snatch)
		return youlong_snatch
	end
end

sgs.sgkgodyoulong_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.sgkgodyoulong(to, card)
	return package_known(card,"isBlack") and not package_known(card,"isEquipped")
end



local sgkgodtongtian_skill = {}
sgkgodtongtian_skill.name = "sgkgodtongtian"
table.insert(package_skills, sgkgodtongtian_skill)
sgkgodtongtian_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"isKongcheng") then return nil end
	if package_known(self.player,"getStrategyMark","@tian") <= 0 then return nil end
	local suits = {}
	for _, card in sgs.qlist(package_known(self.player,"getCards","he")) do
	    if package_known(card,"getSuit") == sgs.Card_Spade then
		    table.insert(suits, package_known(card,"getSuitString"))
			break
		end
	end
	for _, card in sgs.qlist(package_known(self.player,"getCards","he")) do
	    if package_known(card,"getSuit") == sgs.Card_Heart then
		    table.insert(suits, package_known(card,"getSuitString"))
			break
		end
	end
	for _, card in sgs.qlist(package_known(self.player,"getCards","he")) do
	    if package_known(card,"getSuit") == sgs.Card_Club then
		    table.insert(suits, package_known(card,"getSuitString"))
			break
		end
	end
	for _, card in sgs.qlist(package_known(self.player,"getCards","he")) do
	    if package_known(card,"getSuit") == sgs.Card_Diamond then
		    table.insert(suits, package_known(card,"getSuitString"))
			break
		end
	end
	if #suits >= 3 then
	    return source_skill(self,"#sgkgodtongtianCard:.:")
	end
end

sgs.ai_skill_use_func["#sgkgodtongtianCard"] = function(card,use,self,request)
    use.card = card
end

ai_skill_use["@@sgkgodtongtian!"]=function(self,prompt,request)
	local valid = {}
	local ids = {}
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
    package_call(self,"sortByKeepValue",cards)
   	for _,c in sgs.list(cards)do do
		if table.contains(ids, package_known(c,"getSuit")) then goto package_continue_1 end
		table.insert(valid, package_known(c,"getEffectiveId"))
		table.insert(ids, package_known(c,"getSuit"))
	end ::package_continue_1:: end
	if #valid<1 then return end
   	return response_skill(self,"#sgkgodtongtianCard",valid,{},request)
end

sgs.ai_use_value["sgkgodtongtianCard"] = 10
sgs.ai_use_priority["sgkgodtongtianCard"] = 9



local tongtian_zhiheng_skill = {}
tongtian_zhiheng_skill.name = "tongtian_zhiheng"
table.insert(package_skills, tongtian_zhiheng_skill)
tongtian_zhiheng_skill.getTurnUseCard = function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#tongtian_zhihengCard") then
		return source_skill(self,"#tongtian_zhihengCard:.:")
	end
end

sgs.ai_skill_use_func["#tongtian_zhihengCard"] = function(card,use,self,request)
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
				if use_slash_num<=package_known(card,"getTargetModResidue",self.player)
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

		if package_call(self.player,"getWeapon") and package_known(self.player,"getHandcardNum")<3 then
			table.insert(unpreferedCards,package_call(self.player,"getWeapon"):getId())
		end

		if package_known(self,"needToThrowArmor") then
			table.insert(unpreferedCards,package_call(self.player,"getArmor"):getId())
		end

		if package_known(self.player,"getOffensiveHorse") and package_call(self.player,"getWeapon") then
			table.insert(unpreferedCards,package_known(self.player,"getOffensiveHorse"):getId())
		end
	end

	for i = #unpreferedCards,1,-1 do
		if package_known(self,"getKnownCardById",unpreferedCards[i]):isKindOf("WoodenOx") and package_known(self.player,"getPile","wooden_ox"):length()>1 then
			table.removeOne(unpreferedCards,unpreferedCards[i])
		end
	end

	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not package_known(self.player,"isJilei",package_known(self,"getKnownCardById",unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		if package_known(self.room,"getMode")=="02_1v1" and fact(self,"one_v_one_rule")~="Classical" then
			local use_cards_kof = {use_cards[1]}
			if #use_cards>1 then table.insert(use_cards_kof,use_cards[2]) end
			use.card = source_skill(self,"#tongtian_zhihengCard:"..table.concat(use_cards_kof,"+")..":")
		else
			use.card = source_skill(self,"#tongtian_zhihengCard:"..table.concat(use_cards,"+")..":")
		end
	end
end

sgs.ai_use_value["tongtian_zhihengCard"] = 9
sgs.ai_use_priority["tongtian_zhihengCard"] = 2.61
sgs.dynamic_value.benefit["tongtian_zhihengCard"] = true


function sgs.ai_cardneed.tongtian_zhiheng(to, card)
	return not package_known(card,"isKindOf","Jink")
end



sgs.ai_skill_invoke.tongtian_fankui = function(self, data)
    local damage = package_known(data,"toDamage")
	if package_known(self,"isEnemy",damage.from) then
	    return true
	end
	return false
end



-- Guanxing dependency is already provided by isolated core; no legacy load.



local sgkgodjilue_skill = {}
sgkgodjilue_skill.name = "sgkgodjilue"
table.insert(package_skills, sgkgodjilue_skill)
sgkgodjilue_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyFlag","jiluefailed") then return nil end
	return source_skill(self,"#sgkgodjilueCard:.:")
end

sgs.ai_skill_use_func["#sgkgodjilueCard"] = function(card,use,self,request)
    if package_known(self.player,"getStrategyFlag","jiluefailed") then return nil end
	use.card = card
end

sgs.ai_use_value["sgkgodjilueCard"] = 10
sgs.ai_use_priority["sgkgodjilueCard"] = 8
sgs.dynamic_value.benefit["sgkgodjilueCard"] = true




ai_skill_use["TrickCard+^Nullification,Slash,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Slash,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Slash,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Slash,Analeptic,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,EquipCard,Slash,Peach,Analeptic|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,Analeptic,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,Slash,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,Slash,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,Slash,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,Slash,Analeptic,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Analeptic,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		end
	end
	return "."
end



ai_skill_use["Slash,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Slash,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Slash,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use[" Slash,Analeptic,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Analeptic,EquipCard|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Slash,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Slash,EquipCard|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			package_call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Slash,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Slash,Analeptic,EquipCard|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = { isDummy = true }
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				package_call(self,"useBasicCard",card, dummy_use)
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use[" Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Analeptic,EquipCard|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = { isDummy = true }
				                package_call(self,"useBasicCard",card, dummy_use)
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = { isDummy = true }
			package_call(self,"useEquipCard",card, dummy_use)
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		end
	end
	return "."
end



local sgkgodyanmie_skill = {}
sgkgodyanmie_skill.name = "sgkgodyanmie"
table.insert(package_skills, sgkgodyanmie_skill)
sgkgodyanmie_skill.getTurnUseCard = function(self,inclusive,request)
    if #self.enemies == 0 then return nil end
	if package_known(self.player,"isKongcheng") then return nil end
	return source_skill(self,"#sgkgodyanmieCard:.:")
end

sgs.ai_skill_use_func["#sgkgodyanmieCard"] = function(card,use,self,request)
    if #self.enemies == 0 then return nil end
	if package_known(self.player,"isKongcheng") then return nil end
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards)
	local target
	for _, enemy in ipairs(self.enemies) do
	    if (not package_known(enemy,"hasSkills","manjuan|sgkgodfengying")) and (not package_known(enemy,"isNude")) and package_known(enemy,"getCards","he"):length() - 3*package_known(enemy,"getHp") >= 0 then
		    target = enemy
			break
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if (not package_known(enemy,"hasSkills","manjuan|sgkgodfengying")) and (not package_known(enemy,"isNude")) and package_known(enemy,"getCards","he"):length() > package_known(enemy,"getHp") then
			    target = enemy
				break
			end
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if (not package_known(enemy,"hasSkills","manjuan|sgkgodfengying")) and (not package_known(enemy,"isNude")) and package_known(enemy,"getCards","he"):length() >= 3 then
			    target = enemy
				break
			end
		end
	end
	if not target then return nil end
	if target then
	    local yanmie_use
		for _, _card in ipairs(cards) do
		    if package_known(_card,"getSuit") == sgs.Card_Spade then
			    yanmie_use = _card
				break
			end
		end
		if yanmie_use then
		    use.card = source_skill(self,"#sgkgodyanmieCard:" .. package_known(yanmie_use,"getEffectiveId") .. ":")
			if use.to then package_call(use.to,"append",target) end
		end
	end
end

sgs.sgkgodyanmie_suit_value = {
	spade = 4
}

sgs.ai_skill_choice["sgkgodyanmie"] = function(self, choices, data)
    return "dis-yanmie"
end


sgs.ai_use_value["sgkgodyanmieCard"] = 10
sgs.ai_use_priority["sgkgodyanmieCard"] = 7.5
sgs.ai_card_intention["sgkgodyanmieCard"] = 300



sgs.ai_skill_playerschosen.sgkgodshunshi = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets)
	local tos = {}
	local use = source_fact(self,"shunshi_data","toCardUse")
	if package_known(use.card,"isKindOf","ExNihilo") or package_known(use.card,"isKindOf","Peach") or package_known(use.card,"isKindOf","Analeptic") or package_known(use.card,"isKindOf","Dongzhuxianji") then
		for _, p in ipairs(targets) do
			if package_known(self,"isFriend",p) then table.insert(tos, p) end
			if #tos == 3 then break end
		end
		return tos
	else
		for _, p in ipairs(targets) do
			if package_known(self,"isEnemy",p) then table.insert(tos, p) end
			if #tos == 3 then break end
		end
		return tos
	end
	return {}
end

function sgs.ai_slash_prohibit.sgkgodshunshi(self,from,to,card)
	if package_known(self,"isFriend",to,from) then return false end
	if package_known(from,"getStrategyFlag","NosJiefanUsed") then return false end
	if package_known(to,"isNude") then return false end
	for _,friend in ipairs(package_known(self,"getFriends",from,true))do
		if package_known(to,"canSlash",friend,card) and package_known(self,"slashIsEffective",card,friend,from) then return true end
	end
end



function sgkgodguixinValue(self, player)
	if package_known(player,"isAllNude") then return 0 end
	local card_id = package_known(self,"askForCardChosen",player, "hej", "dummy")
	if package_known(self,"isEnemy",player) then
		for _, card in sgs.qlist(package_known(player,"getJudgingArea")) do
			if package_known(card,"getEffectiveId") == card_id then
				if package_known(card,"isKindOf","YanxiaoCard") then return 0
				elseif package_known(card,"isKindOf","Lightning") then
					if package_known(self,"hasWizard",self.enemies, true) then return 0.8
					elseif package_known(self,"hasWizard",self.friends, true) then return 0.4
					else return 0.5 * (#self.friends) / (#self.friends + #self.enemies) end
				else
					return -0.2
				end
			end
		end
		for i = 0, 3 do
			local card = package_call(player,"getEquip",i)
			if card and package_known(card,"getEffectiveId") == card_id then
				if package_known(card,"isKindOf","Armor") and package_known(self,"needToThrowArmor",player) then return 0 end
				local value = 0
				if package_known(self,"getDangerousCard",player) == card_id then value = 1.5
				elseif package_known(self,"getValuableCard",player) == card_id then value = 1.1
				elseif i == 1 then value = 1
				elseif i == 2 then value = 0.8
				elseif i == 0 then value = 0.7
				elseif i == 3 then value = 0.5
				end
				if package_known(player,"hasSkills",sgs.lose_equip_skill) or not package_known(self,"doDisCard",player, "e", true) then value = value - 0.2 end
				return value
			end
		end
		if package_known(self,"needKongcheng",player) and package_known(player,"getHandcardNum") == 1 then return 0 end
		if not package_known(self,"hasLoseHandcardEffective") then return 0.1
		else
			local index = package_known(player,"hasSkills","jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") and 0.7 or 0.6
			local value = 0.2 + index / (package_known(player,"getHandcardNum") + 1)
			if not package_known(self,"doDisCard",player, "h", true) then value = value - 0.1 end
			return value
		end
	elseif package_known(self,"isFriend",player) then
		for _, card in sgs.qlist(package_known(player,"getJudgingArea")) do
			if package_known(card,"getEffectiveId") == card_id then
				if package_known(card,"isKindOf","YanxiaoCard") then return 0
				elseif package_known(card,"isKindOf","Lightning") then
					if package_known(self,"hasWizard",self.enemies, true) then return 1
					elseif package_known(self,"hasWizard",self.friends, true) then return 0.8
					else return 0.4 * (#self.enemies) / (#self.friends + #self.enemies) end
				else
					return 1.5
				end
			end
		end
		for i = 0, 3 do
			local card = package_call(player,"getEquip",i)
			if card and package_known(card,"getEffectiveId") == card_id then
				if package_known(card,"isKindOf","Armor") and package_known(self,"needToThrowArmor",player) then return 0.9 end
				local value = 0
				if i == 1 then value = 0.1
				elseif i == 2 then value = 0.2
				elseif i == 0 then value = 0.25
				elseif i == 3 then value = 0.25
				end
				if package_known(player,"hasSkills",sgs.lose_equip_skill) then value = value + 0.1 end
				if hasTuntianEffect(player, true) then value = value + 0.1 end
				return value
			end
		end
		if package_known(self,"needKongcheng",player, true) and package_known(player,"getHandcardNum") == 1 then return 0.5
		elseif package_known(self,"needKongcheng",player) and package_known(player,"getHandcardNum") == 1 then return 0.3 end
		if not package_known(self,"hasLoseHandcardEffective") then return 0.2
		else
			local index = package_known(player,"hasSkills","jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") and 0.5 or 0.4
			local value = 0.2 - index / (package_known(player,"getHandcardNum") + 1)
			if hasTuntianEffect(player, true) then value = value + 0.1 end
			return value
		end
	end
	return 0.3
end

sgs.ai_skill_invoke.sgkgodguixin = function(self, data)
	local damage = package_known(data,"toDamage")
	local diaochan = package_call(self.room,"findPlayerBySkillName","lihun")
	local lihun_eff = (diaochan and package_known(self,"isEnemy",diaochan))
	local manjuan_eff = hasManjuanEffect(self.player)
	if lihun_eff and not manjuan_eff then return false end
	local players = package_known(self.room,"getPlayers")
	local t = 0
	for _, _player in sgs.qlist(players) do
	    if package_known(_player,"objectName") ~= package_known(self.player,"objectName") and package_known(_player,"getCards","hej"):length() > 0 then t = t + 1 end
		if package_known(_player,"isDead") then t = t + 1 end
	end
	if not package_known(self.player,"faceUp") then return true
	else
		if manjuan_eff then return false end
		if t >= 3 then return true end
		local value = 0
		for _, player in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
			value = value + sgkgodguixinValue(self, player)
		end
		local left_num = damage.damage - package_known(self.player,"getStrategyMark","guixin_times")
		return value >= 1.3 or left_num > 0
	end
end

sgs.ai_need_damaged.sgkgodguixin = function(self, attacker, player)
	if package_known(self.room,"alivePlayerCount") <= 3 or package_known(player,"hasSkill","manjuan") then return false end
	local diaochan = package_call(self.room,"findPlayerBySkillName","lihun")
	local drawcards = 0
	for _, aplayer in sgs.qlist(package_known(self.room,"getOtherPlayers",player)) do
		if package_known(aplayer,"getCards","hej"):length() > 0 then drawcards = drawcards + 1 end
	end
	for _, aaplayer in sgs.qlist(package_known(self.room,"getPlayers")) do
	    if package_known(aaplayer,"isDead") then drawcards = drawcards + 1 end
	end
	return not package_known(self,"isLihunTarget",player, drawcards)
end



sgs.ai_skill_playerchosen.sgkgodzhitian = function(self, targets)
	local zhitian = {}
	for _, _player in sgs.qlist(targets) do
	    if package_known(self,"isFriend",_player) then table.insert(zhitian, _player) end
	end
	package_call(self,"sort",zhitian, "value")
	if #zhitian > 0 then
	    package_call(self,"sort",zhitian, "value")
	    return zhitian[1]
	end
end
sgs.ai_playerchosen_intention.sgkgodzhitian = -80


local sgkgodzhiji_skill = {}
sgkgodzhiji_skill.name = "sgkgodzhiji"
table.insert(package_skills, sgkgodzhiji_skill)
sgkgodzhiji_skill.getTurnUseCard = function(self,inclusive,request)
    if #self.enemies == 0 then return nil end
	if package_known(self.player,"hasUsed","#sgkgodzhijiCard") then return nil end
	if package_known(self.player,"isNude") then return nil end
	return source_skill(self,"#sgkgodzhijiCard:.:")
end

sgs.ai_skill_use_func["#sgkgodzhijiCard"] = function(card,use,self,request)
    if #self.enemies == 0 then return nil end
	if package_known(self.player,"isNude") then return nil end
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	local zhiji_weapons = {}
	for _, c in ipairs(cards) do
	    if package_known(c,"isKindOf","Weapon") then table.insert(zhiji_weapons, package_known(c,"getEffectiveId")) end
	end
	if #zhiji_weapons > 0 then
		use.card = source_skill(self,"#sgkgodzhijiCard:" .. table.concat(zhiji_weapons, "+") .. ":")
		if use.to then
			for _, enemy in ipairs(self.enemies) do
				if package_known(self,"damageIsEffective",enemy) then
					if #zhiji_weapons > 1 and not package_known(enemy,"hasArmorEffect","silver_lion") then
						package_call(use.to,"append",enemy)
						if package_known(use.to,"length") == #zhiji_weapons then break end
					elseif #zhiji_weapons == 1 then
						package_call(use.to,"append",enemy)
						if package_known(use.to,"length") == #zhiji_weapons then break end
					end
				end
			end
			assert(package_known(use.to,"length") > 0)
		end
	end
end


sgs.ai_use_value["sgkgodzhijiCard"] = 5
sgs.ai_use_priority["sgkgodzhijiCard"] = sgs.ai_use_priority.Slash - 0.1
sgs.ai_card_intention["sgkgodzhijiCard"] = 200
sgs.ai_cardneed.sgkgodzhiji = sgs.ai_cardneed.weapon

sgs.ai_skill_invoke.sgkgodzhiji = true

sgs.sgkgodzhiji_keep_value = {
    weapon = 5.5
}



sgs.ai_skill_choice.sgkgodshelie = function(self, choices)
    local shelie = package_known(choices,"split","+")
	return shelie[math.random(1, #shelie)]
end



local sgkgodgongxin_skill= {}
sgkgodgongxin_skill.name = "sgkgodgongxin"
table.insert(package_skills, sgkgodgongxin_skill)
sgkgodgongxin_skill.getTurnUseCard = function(self,inclusive,request)
    if #self.enemies == 0 then return nil end
	if package_known(self.player,"hasUsed","#sgkgodgongxinCard") then return nil end
	local sgkgodgongxin_card = source_skill(self,"#sgkgodgongxinCard:.:")
	assert(sgkgodgongxin_card)
	return sgkgodgongxin_card
end

sgs.ai_skill_use_func["#sgkgodgongxinCard"] = function(card,use,self,request)
    package_call(self,"sort",self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if not package_known(enemy,"isKongcheng") and package_known(self,"objectiveLevel",enemy) > 0
			and (package_known(self,"hasSuit","heart", false, enemy) or package_known(self,"getKnownNum",eneny) ~= package_known(enemy,"getHandcardNum")) then
			use.card = card
			if use.to then
				package_call(use.to,"append",enemy)
			end
			return
		end
	end
end

sgs.ai_use_value["sgkgodgongxinCard"] = 8.5
sgs.ai_use_priority["sgkgodgongxinCard"] = 9.5
sgs.ai_card_intention["sgkgodgongxinCard"] = 80



sgs.ai_skill_playerchosen["sgkgoddanjing_damage"] = function(self, targets)
    local damage = source_fact(self,"danjing_damage","toDamage")
	local players = {}
	for _, t in sgs.qlist(targets) do
		if package_known(self,"isEnemy",t) and package_known(self,"damageIsEffective",t, damage.nature) then
		    table.insert(players, t)
		end
	end
	if #players > 0 then
		package_call(self,"sort",players, "threat")
		return players[1]
	end
	return nil
end

sgs.ai_skill_playerchosen["sgkgoddanjing_lose"] = function(self, targets)
    local damage = source_fact(self,"danjing_damage","toDamage")
	local players = {}
	for _, t in sgs.qlist(targets) do
		if package_known(self,"isEnemy",t) and package_known(self,"damageIsEffective",t, damage.nature) then
		    table.insert(players, t)
		end
	end
	if #players > 0 then
		package_call(self,"sort",players, "threat")
		return players[1]
	end
	return nil
end

sgs.ai_skill_playerchosen["sgkgoddanjing_lose"] = function(self, targets)
	local players = {}
	for _, t in sgs.qlist(targets) do
		if package_known(self,"isEnemy",t) then
		    table.insert(players, t)
		end
	end
	if #players > 0 then
		package_call(self,"sort",players, "threat")
		return players[1]
	end
	return nil
end

sgs.ai_skill_playerchosen["sgkgoddanjing_discard"] = function(self, targets)
	local players = {}
	for _, t in sgs.qlist(targets) do
		if package_known(self,"isEnemy",t) then
		    table.insert(players, t)
		end
	end
	if #players > 0 then
		package_call(self,"sort",players, "defense")
		players = sgs.reverse(players)
		return players[1]
	end
	return nil
end

sgs.ai_skill_playerchosen["sgkgoddanjing_maxhp"] = function(self, targets)
	local players = {}
	for _, t in sgs.qlist(targets) do
		if package_known(self,"isEnemy",t) then
		    table.insert(players, t)
		end
	end
	if #players > 0 then
		package_call(self,"sort",players, "threat")
		return players[1]
	end
	return nil
end



local sgkgodzhonghun_skill = {}
sgkgodzhonghun_skill.name = "sgkgodzhonghun"
table.insert(package_skills, sgkgodzhonghun_skill)
sgkgodzhonghun_skill.getTurnUseCard = function(self,inclusive,request)
    if #self.friends_noself == 0 then return nil end
	if package_known(self.player,"getStrategyMark","sgkgodzhonghun") > 0 then return nil end
	return source_skill(self,"#sgkgodzhonghunCard:.:")
end

sgs.ai_skill_use_func["#sgkgodzhonghunCard"] = function(card,use,self,request)
	local target
	for _, friend in ipairs(self.friends_noself) do
		if package_known(self.player,"getRole") == "loyalist" and package_known(friend,"isLord") and package_known(friend,"getStrategyMark","&sgkgodzhonghun") == 0 then
			target = friend
			break
		end
	end
	if not target then
		package_call(self,"sort",self.friends_noself, "chaofeng")
		for _, friend in pairs(self.friends_noself) do
			if package_known(friend,"getStrategyMark","&sgkgodzhonghun") == 0 then
				target = friend
				break
			end
		end
	end
	if target then
		use.card = card
		if use.to then package_call(use.to,"append",target) end
	end
end

ai_skill_use["@@sgkgodzhonghun"]=function(self,prompt,request)
	if #self.friends_noself == 0 then return "." end
	if package_known(self.player,"getStrategyMark","sgkgodzhonghun") > 0 then return "." end
	local target
	for _, friend in ipairs(self.friends_noself) do
		if package_known(self.player,"getRole") == "loyalist" and package_known(friend,"isLord") and package_known(friend,"getStrategyMark","&sgkgodzhonghun") == 0 then
			target = friend
			break
		end
	end
	if not target then
		package_call(self,"sort",self.friends_noself, "chaofeng")
		for _, friend in pairs(self.friends_noself) do
			if package_known(friend,"getStrategyMark","&sgkgodzhonghun") == 0 then
				target = friend
				break
			end
		end
	end
	if target then return response_skill(self,"#sgkgodzhonghunCard",{},{package_known(target,"objectName")},request) else return "." end
end


sgs.ai_use_value["sgkgodzhonghunCard"] = 10
sgs.ai_use_priority["sgkgodzhonghunCard"] = 10
sgs.ai_card_intention["sgkgodzhonghunCard"]  = -100



local sgkgodlonghun_skill = {}
sgkgodlonghun_skill.name = "sgkgodlonghun"
table.insert(package_skills, sgkgodlonghun_skill)
sgkgodlonghun_skill.getTurnUseCard = function(self,inclusive,request)
    local usable_cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	local equips = sgs.QList2Table(package_known(self.player,"getCards","e"))
	for _,e in ipairs(equips) do
		if package_known(e,"isKindOf","DefensiveHorse") or package_known(e,"isKindOf","OffensiveHorse") then
			table.insert(usable_cards, e)
		end
	end
	if package_known(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(package_known(self.player,"getPile","wooden_ox")) do
			table.insert(usable_cards, package_known(self,"getKnownCardById",id))
		end
	end
	package_call(self,"sortByUseValue",usable_cards, true)
	for _,c in ipairs(usable_cards) do
		if package_known(c,"getSuit") == sgs.Card_Diamond and package_known(self,"slashIsAvailable") and not package_known(c,"isKindOf","Peach") then
			return conversion_clone(self,"fire_slash","sgkgodlonghun",package_known(c,"getSuit"),package_known(c,"getNumber"),{package_known(c,"getEffectiveId")})
		end
	end
end

sgs.ai_view_as["sgkgodlonghun"] = function(card, player, card_place)
 local self=actor_ai(player)
    local usable_cards = sgs.QList2Table(package_known(player,"getCards","he"))
	if package_known(player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(package_known(player,"getPile","wooden_ox")) do
			table.insert(usable_cards, package_known(self,"getKnownCardById",id))
		end
	end
	local two_club_cards = {}
	local two_heart_cards = {}
	local two_diamond_cards = {}
	local two_spade_cards = {}
	local spade_num, club_num, heart_num, diamond_num = 0, 0, 0, 0
	for _,c in ipairs(usable_cards) do
		if package_known(c,"getSuit") == sgs.Card_Club and #two_club_cards < 2 then
			table.insert(two_club_cards, package_known(c,"getEffectiveId"))
		elseif package_known(c,"getSuit") == sgs.Card_Heart and #two_heart_cards < 2 then
			table.insert(two_heart_cards, package_known(c,"getEffectiveId"))
		elseif package_known(c,"getSuit") == sgs.Card_Diamond and #two_diamond_cards < 2 then
			table.insert(two_diamond_cards, package_known(c,"getEffectiveId"))
		elseif package_known(c,"getSuit") == sgs.Card_Spade and #two_spade_cards < 2 then
			table.insert(two_spade_cards, package_known(c,"getEffectiveId"))
		end
	end

	for _,c in ipairs(usable_cards) do
		if package_known(c,"getSuit") == sgs.Card_Club then
			club_num = club_num + 1
		elseif package_known(c,"getSuit") == sgs.Card_Spade then
			spade_num = spade_num + 1
		elseif package_known(c,"getSuit") == sgs.Card_Heart then
			heart_num = heart_num + 1
		elseif package_known(c,"getSuit") == sgs.Card_Diamond then
			diamond_num = diamond_num + 1
		end
	end
	local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if #two_club_cards == 2 and club_num >= 3 then
		return {name="jink",skill="sgkgodlonghun",suit=sgs.Card_NoSuit,number=0,subcards={two_club_cards[1],two_club_cards[2]}}
	else
		if package_known(card,"getSuit") == sgs.Card_Club then
			return {name="jink",skill="sgkgodlonghun",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
		end
	end
	if #two_heart_cards == 2 and package_known(player,"getStrategyMark","Global_PreventPeach") == 0 and heart_num >= 3 and package_known(player,"getMaxHp") <= 5 then
		return {name="peach",skill="sgkgodlonghun",suit=sgs.Card_NoSuit,number=0,subcards={two_heart_cards[1],two_heart_cards[2]}}
	else
		if package_known(card,"getSuit") == sgs.Card_Heart and package_known(player,"getStrategyMark","Global_PreventPeach") == 0 then
			return {name="peach",skill="sgkgodlonghun",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
		end
	end
	if #two_diamond_cards == 2 and diamond_num >= 3 then
		return {name="fire_slash",skill="sgkgodlonghun",suit=sgs.Card_NoSuit,number=0,subcards={two_diamond_cards[1],two_diamond_cards[2]}}
	else
		if package_known(card,"getSuit") == sgs.Card_Diamond and not (package_known(card,"isKindOf","WoodenOx") and package_known(player,"getPile","wooden_ox"):length() > 0) then
			return {name="fire_slash",skill="sgkgodlonghun",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
		end
	end
	if #two_spade_cards == 2 and spade_num >= 3 then
		return {name="nullification",skill="sgkgodlonghun",suit=sgs.Card_NoSuit,number=0,subcards={two_spade_cards[1],two_spade_cards[2]}}
	else
		if package_known(card,"getSuit") == sgs.Card_Spade then
			return {name="nullification",skill="sgkgodlonghun",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
		end
	end
end

sgs.sgkgodlonghun_suit_value = sgs.longhun_suit_value

function sgs.ai_cardneed.sgkgodlonghun(to, card, self)
	if package_known(to,"getCardCount") > 3 then return false end
	if package_known(to,"isNude") then return true end
	return package_known(card,"getSuit") == sgs.Card_Heart or package_known(card,"getSuit") == sgs.Card_Spade
end



ai_skill_use["@@sgkgodqixing"]=function(self,prompt,request)
	local pile = package_known(self.player,"getPile","xing")
	local piles = {}
	local cards = package_known(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	local max_num = math.max(package_known(pile,"length"), #cards)
	if package_known(pile,"isEmpty") or (#cards == 0) then
		return "."
	end
	for _, card_id in sgs.qlist(pile) do
		table.insert(piles, package_known(self,"getKnownCardById",card_id))
	end
	local exchange_to_pile = {}
	local exchange_to_handcard = {}
	package_known(self,"sortByCardNeed",cards)
	package_known(self,"sortByCardNeed",piles)
	for i = 1 , max_num, 1 do
		if package_known(self,"cardNeed",piles[#piles]) > package_known(self,"cardNeed",cards[1]) then
			table.insert(exchange_to_handcard, piles[#piles])
			table.insert(exchange_to_pile, cards[1])
			table.removeOne(piles, piles[#piles])
			table.removeOne(cards, cards[1])
		else
			break
		end
	end
	if #exchange_to_handcard == 0 then return "." end
	local exchange = {}
	for _, id in sgs.qlist(pile) do
		table.insert(exchange, id)
	end

	for _, c in ipairs(exchange_to_handcard) do
		table.removeOne(exchange, package_known(c,"getId"))
	end

	for _, c in ipairs(exchange_to_pile) do
		table.insert(exchange, package_known(c,"getId"))
	end

	return response_skill(self,"#sgkgodqixingCard",exchange,{},request)
end



ai_skill_use["@@sgkgodkuangfeng"]=function(self,prompt,request)
	if #self.enemies == 0 then return "." end
	local friendly_fire
	for _, friend in ipairs(self.friends_noself) do
		if package_known(friend,"getStrategyMark","&gale") == 0 and package_known(self,"damageIsEffective",friend, sgs.DamageStruct_Fire) and package_known(friend,"faceUp") and not package_known(self,"willSkipPlayPhase",friend)
			and (package_known(friend,"hasSkill","huoji") or package_known(friend,"hasWeapon","fan") or (package_known(friend,"hasSkill","yeyan") and package_known(friend,"getStrategyMark","@flame") > 0)) then
			friendly_fire = true
			break
		end
	end
	local is_chained = 0
	local target = {}
	for _, enemy in ipairs(self.enemies) do
		if package_known(enemy,"getStrategyMark","&gale") == 0 and package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Fire) then
			if package_known(enemy,"isChained") then
				is_chained = is_chained + 1
				table.insert(target, enemy)
			elseif package_known(enemy,"hasArmorEffect","vine") then
				table.insert(target, 1, enemy)
				break
			end
		end
		if package_known(self,"isWeak",enemy) or package_known(self,"damageIsEffective",enemy) then table.insert(target, enemy) end
	end
	local usecard = false
	if (friendly_fire and is_chained > 1) or #target > 0 then usecard = true end
	package_call(self,"sort",self.friends, "hp")
	package_call(self,"sort",self.enemies, "defense")
	if usecard then
		if not target[1] then table.insert(target, self.enemies[1]) end
		if target[1] then return response_skill(self,"#sgkgodkuangfengCard",{package_known(self.player,"getPile","xing"):first()},{package_known(target[1],"objectName")},request) else return "." end
	else
		return "."
	end
end


sgs.ai_card_intention["#sgkgodkuangfengCard"] = 120



ai_skill_use["@@sgkgoddawu"]=function(self,prompt,request)
	if #self.friends == 0 then return "." end
	package_call(self,"sort",self.friends_noself, "hp")
	local targets = {}
	local lord = package_call(self.room,"getLord")
	package_call(self,"sort",self.friends_noself, "defense")
	if lord and package_known(lord,"getStrategyMark","&fog") == 0 and package_known(self,"isFriend",lord) and not sgs.isLordHealthy() and not package_known(self.player,"isLord") and not package_known(lord,"hasSkill","buqu")
		and not (package_known(lord,"hasSkill","hunzi") and package_known(lord,"getStrategyMark","hunzi") == 0 and package_known(lord,"getHp") > 1) then
			table.insert(targets, package_known(lord,"objectName"))
	else
		for _, friend in ipairs(self.friends_noself) do
			if package_known(friend,"getStrategyMark","&fog") == 0 and package_known(self,"isWeak",friend) and not package_known(friend,"hasSkill","buqu")
				and not (package_known(friend,"hasSkill","hunzi") and package_known(friend,"getStrategyMark","hunzi") == 0 and package_known(friend,"getHp") > 1) then
					table.insert(targets, package_known(friend,"objectName"))
					break
			end
		end
	end
	if package_known(self.player,"getPile","xing"):length() > #targets and package_known(self,"isWeak") then table.insert(targets, package_known(self.player,"objectName")) end
	if #targets > 0 then
		local s = sgs.QList2Table(package_known(self.player,"getPile","xing"))
		local length = #targets
		for i = 1, #s - length do
			table.remove(s, #s)
		end
		return response_skill(self,"#sgkgoddawuCard",s,targets,request)
	end
	return "."
end


sgs.ai_card_intention["#sgkgoddawuCard"] = -100



sgs.ai_skill_choice.sgkgodwumou = function(self, choices)
	if package_known(self.player,"getStrategyMark","&fierce") > 6 then
	    if package_known(self,"isWeak") then return "loseonemark" else return "getdamaged" end
	end
	if package_known(self.player,"getHp") + package_known(self,"getCardsNum","Peach") > 3 then return "getdamaged" else return "loseonemark" end
	if package_known(self.player,"hasSkill","sgkgodyinshi") and not package_known(self.player,"hasSkill","jueqing") then return "getdamaged" end
end



local sgkgodshenfen_skill = {}
sgkgodshenfen_skill.name = "sgkgodshenfen"
table.insert(package_skills, sgkgodshenfen_skill)
sgkgodshenfen_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.enemies == 0 then return nil end
	if package_known(self.player,"hasUsed","#sgkgodshenfenCard") or package_known(self.player,"getStrategyMark","&fierce") < 6 then return nil end
	return source_skill(self,"#sgkgodshenfenCard:.:")
end

local function hunlie_getSaveNum(self,isFriend)
	local num = 0
	for _, player in sgs.qlist(package_known(self.room,"getAllPlayers")) do
		if (isFriend and package_known(self,"isFriend",player)) or (not isFriend and package_known(self,"isEnemy",player)) then
			if not package_known(self.player,"hasSkill","wansha") or package_known(player,"objectName") == package_known(self.player,"objectName") then
				if package_known(player,"hasSkill","jijiu") then
					num = num + package_known(self,"getSuitNum","heart", true, player)
					num = num + package_known(self,"getSuitNum","diamond", true, player)
					num = num + package_known(player,"getHandcardNum") * 0.4
				end
				if package_known(player,"hasSkill","nosjiefan") and getCardsNum("Slash", player, self.player) > 0 then
					if package_known(self,"isFriend",player) or package_known(self,"getCardsNum","Jink") == 0 then num = num + getCardsNum("Slash", player, self.player) end
				end
				num = num + getCardsNum("Peach", player, self.player)
			end
			if package_known(player,"hasSkill","buyi") and not package_known(player,"isKongcheng") then num = num + 0.3 end
			if package_known(player,"hasSkill","chunlao") and not package_known(player,"getPile","wine"):isEmpty() then num = num + package_known(player,"getPile","wine"):length() end
			if package_known(player,"hasSkill","jiuzhu") and package_known(player,"getHp") > 1 and not package_known(player,"isNude") then
				num = num + 0.9 * math.max(0, math.min(package_known(player,"getHp") - 1, package_known(player,"getCardCount")))
			end
			if package_known(player,"hasSkill","renxin") and package_known(player,"objectName") ~= package_known(self.player,"objectName") and not package_known(player,"isKongcheng") then num = num + 1 end
		end
	end
	return num
end

local function hunlie_canSaveSelf(self,player)
	if hasBuquEffect(player) then return true end
	if getCardsNum("Analeptic", player, self.player) > 0 then return true end
	if package_known(player,"hasSkill","jiushi") and package_known(player,"faceUp") then return true end
	if package_known(player,"hasSkill","jiuchi") then
		for _, c in sgs.qlist(lawful_hand(self,player)) do
			if package_known(c,"getSuit") == sgs.Card_Spade then return true end
		end
	end
	return false
end

local function getShenfenUseValueOfHECards(self, to)
	local value = 0

	local value_h = 0
	local hcard = package_known(to,"getHandcardNum")
	if package_known(to,"hasSkill","lianying") then
		hcard = hcard - 0.9
	elseif package_known(to,"hasSkills","shangshi|nosshangshi") then
		hcard = hcard - 0.9 * package_known(to,"getLostHp")
	else
		local jwfy = package_call(self.room,"findPlayerBySkillName","shoucheng")
		if jwfy and package_known(self,"isFriend",jwfy, to) and (not package_known(self,"isWeak",jwfy) or package_known(jwfy,"getHp") > 1) then hcard = hcard - 0.9 end
	end
	value_h = (hcard > 4) and 16 / hcard or hcard
	if hasTuntianEffect(to, true) then value = value * 0.95 end
	if (package_known(to,"hasSkill","kongcheng") or (package_known(to,"hasSkill","zhiji") and package_known(to,"getHp") > 2 and package_known(to,"getStrategyMark","zhiji") == 0)) and not package_known(to,"isKongcheng") then value_h = value_h * 0.7 end
	if package_known(to,"hasSkills","jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then value_h = value_h * 0.95 end
	value = value + value_h


	local value_e = 0
	local equip_num = package_known(to,"getEquips"):length()
	if package_known(to,"hasArmorEffect","silver_lion") and package_known(to,"isWounded") then equip_num = equip_num - 1.1 end
	value_e = equip_num * 1.1
	if package_known(to,"hasSkills","kofxiaoji|xiaoji") then value_e = value_e * 0.7 end
	if package_known(to,"hasSkill","nosxuanfeng") then value_e = value_e * 0.85 end
	if package_known(to,"hasSkills","bazhen|yizhong") and package_call(to,"getArmor") then value_e = value_e - 1 end
	value = value + value_e

	return value
end

local function getDangerousShenGuanYu(self)
	local most = -100
	local target
	for _, player in sgs.qlist(package_known(self.room,"getAllPlayers")) do
		local nm_mark = package_known(player,"getStrategyMark","&nightmare")
		if package_known(player,"objectName") == package_known(self.player,"objectName") then nm_mark = nm_mark + 1 end
		if nm_mark > 0 and nm_mark > most or (nm_mark == most and package_known(self,"isEnemy",player)) then
			most = nm_mark
			target = player
		end
	end
	if target and package_known(self,"isEnemy",target) then return true end
	return false
end

sgs.ai_skill_use_func["#sgkgodshenfenCard"] = function(card,use,self,request)
	if (self.role == "loyalist" or self.role == "renegade") and package_call(self.room,"getLord") and package_known(self,"isWeak",package_call(self.room,"getLord")) and not package_known(self.player,"isLord") then return end
	local benefit = 0
	for _, player in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(self,"isFriend",player) then benefit = benefit - getShenfenUseValueOfHECards(self, player) end
		if package_known(self,"isFriend",player) then benefit = benefit + getShenfenUseValueOfHECards(self, player) end
	end
	local friend_save_num = package_known(self,"getSaveNum",true)
	local enemy_save_num = package_known(self,"getSaveNum",false)
	local others = 0
	for _, player in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(self,"damageIsEffective",player, sgs.DamageStruct_Normal) then
			others = others + 1
			local value_d = 3.5 / math.max(package_known(player,"getHp"), 1)
			if package_known(player,"getHp") <= 1 then
				if package_known(player,"hasSkill","wuhun") then
					local can_use = getDangerousShenGuanYu(self)
					if not can_use then return else value_d = value_d * 0.1 end
				end
				if package_known(self,"canSaveSelf",player) then
					value_d = value_d * 0.9
				elseif package_known(self,"isFriend",player) and friend_save_num > 0 then
					friend_save_num = friend_save_num - 1
					value_d = value_d * 0.9
				elseif package_known(self,"isEnemy",player) and enemy_save_num > 0 then
					enemy_save_num = enemy_save_num - 1
					value_d = value_d * 0.9
				end
			end
			if package_known(player,"hasSkill","fankui") then value_d = value_d * 0.8 end
			if package_known(player,"hasSkill","guixin") then
				if not package_known(player,"faceUp") then
					value_d = value_d * 0.4
				else
					value_d = value_d * 0.8 * (1.05 - package_known(self.room,"alivePlayerCount") / 15)
				end
			end
			if getBestHp(player) == package_known(player,"getHp") - 1 then value_d = value_d * 0.8 end
			if package_known(self,"isFriend",player) then benefit = benefit - value_d end
			if package_known(self,"isEnemy",player) then benefit = benefit + value_d end
		end
	end
	if not package_known(self.player,"faceUp") or package_known(self.player,"hasSkills","jushou|nosjushou|neojushou|kuiwei") then
		benefit = benefit + 1
	else
		local help_friend = false
		for _, friend in ipairs(self.friends_noself) do
			if package_known(self,"hasSkills","fangzhu|jilve", friend) then
				help_friend = true
				benefit = benefit + 1
				break
			end
		end
		if not help_friend then benefit = benefit - 0.5 end
	end
	if package_known(self.player,"getKingdom") == "qun" then
		for _, player in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
			if package_known(player,"hasLordSkill","baonue") and package_known(self,"isFriend",player) then
				benefit = benefit + 0.2 * package_known(self.room,"alivePlayerCount")
				break
			end
		end
	end
	benefit = benefit + (others - 7) * 0.05
	if benefit > 0 then
		use.card = card
	end
end

sgs.ai_use_value["sgkgodshenfenCard"] = 8
sgs.ai_use_priority["sgkgodshenfenCard"] = 5.3

sgs.dynamic_value.damage_card["sgkgodshenfenCard"] = true
sgs.dynamic_value.control_card["sgkgodshenfenCard"] = true

sgs.ai_ajustdamage_from.sgkgodwushen = function(self, from, to, card, nature)
	if from and string.find(translation(self,package_known(to,"objectName")), "神") or string.find(translation(self,package_known(to,"objectName")), "SP神") or string.find(translation(self,package_known(to,"objectName")), "魔") then
		return 1
	end
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|sgkgodsuohun"
function sgs.ai_slash_prohibit.sgkgodsuohun(self,from,to)
	if package_known(from,"hasSkill","jueqing") then return false end
	if package_known(from,"getStrategyFlag","NosJiefanUsed") then return false end
	local damageNum = package_known(self,"ajustDamage",from,to,1,clone(self))

	local maxfriendmark = 0
	local maxenemymark = 0
	for _,friend in sgs.list(package_known(self,"getFriends",from))do
		local friendmark = package_known(friend,"getStrategyMark","&sk_soul")
		if friendmark>maxfriendmark then maxfriendmark = friendmark end
	end
	for _,enemy in sgs.list(package_known(self,"getEnemies",from))do
		local enemymark = package_known(enemy,"getStrategyMark","&sk_soul")
		if enemymark>maxenemymark and enemy~=to then maxenemymark = enemymark end
	end
	if package_known(self,"isEnemy",to,from) and not (package_known(to,"isLord") and package_known(from,"getRole")=="rebel") then
		if (maxfriendmark+damageNum>=maxenemymark) and not (#(package_known(self,"getEnemies",from))==1 and #(package_known(self,"getFriends",from))+#(package_known(self,"getEnemies",from))==package_known(self.room,"alivePlayerCount")) then
			if not(package_known(from,"getStrategyMark","&sk_soul")==maxfriendmark and package_known(from,"getRole")=="loyalist")
			then return true end
		end
	end
end



sgs.ai_skill_invoke.sgkgodjieyan = function(self, data)
    local use = package_known(data,"toCardUse")
	if package_known(use.to,"length") ~= 1 then return false end
	local to = package_known(use.to,"at",0)
	if package_known(self,"isFriend",to) then return false end
	if package_known(self.player,"isKongcheng") then return false end
	if use.card and package_known(use.card,"isRed") and (package_known(use.card,"isKindOf","Slash") or package_known(use.card,"isNDTrick")) then
	    if package_known(self,"damageIsEffective",to, sgs.DamageStruct_Fire) and package_known(self,"objectiveLevel",to) >= 3 then return true else return false end
	end
	return false
end

sgs.ai_skill_cardask["@sgkgodjieyan"] = function(self, data, pattern)
    local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	package_call(self,"sortByKeepValue",cards)
	local c
	for _, card in ipairs(cards) do
	    if not package_known(card,"isKindOf","Peach") then
		    c = card
			break
		end
	end
	if c then
	    return package_known(c,"getEffectiveId")
	else
	    return package_known(cards[math.random(1,#cards)],"getEffectiveId")
	end
end



sgs.ai_skill_invoke.sgkgodfenying = function(self, data)
    return (not package_known(self,"needKongcheng",self.player))
end

sgs.ai_skill_discard.sgkgodfenying = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
	local x = package_known(self.player,"getStrategyMark","&sgkgodfenying-Clear")
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	local index = 0
	for i = #cards, 1, -1 do
	    local card = cards[i]
		if (not package_known(self.player,"isJilei",card)) then
		    table.insert(to_discard, package_known(card,"getEffectiveId"))
	        table.remove(cards, i)
	        index = index + 1
	        if index == x then break end
	       end
	end
	if #to_discard < x then return {} else return to_discard end
end

sgs.ai_skill_playerchosen.sgkgodfenying = function(self, targets)
    local fenying = {}
	for _, t in sgs.qlist(targets) do
	    if package_known(self,"isEnemy",t) and package_known(self,"damageIsEffective",t, sgs.DamageStruct_Fire) then
		    table.insert(fenying, t)
		end
		if package_known(self,"isEnemy",t) and package_known(t,"hasArmorEffect","vine") or (package_known(t,"getStrategyMark","&kuangfeng") > 0 and package_known(t,"getStrategyMark","&dawu") == 0) or (package_known(t,"isKongcheng") and package_known(t,"hasSkill","chouhai")) then
		    table.insert(fenying, 1, t)
		end
	end
	return fenying[1]
end



sgs.ai_skill_invoke.sgkgodtianji = true



local sgkgodtianqi_skill = {}
sgkgodtianqi_skill.name = "sgkgodtianqi"
table.insert(package_skills, sgkgodtianqi_skill)
sgkgodtianqi_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyFlag","tianqi_used_basic") and package_known(self.player,"getStrategyFlag","tianqi_used_trick") then return nil end
    if package_known(self.player,"getStrategyFlag","Global_Dying") then return nil end
	if not package_known(self.player,"isAlive") then return nil end
	local tianqiTrickCard_str = {}
	local tianqiBasicCard_str = {}
	local top = source_fact(self,"top_card","toString")
	if #self.enemies == 0 then
		if top == "TrickCard" then
			return source_skill(self,"#sgkgodtianqi:.:" .. "dongzhuxianji")
		else
			if package_known(self,"getCardsNum","Peach") > 0 then
				return source_skill(self,"#sgkgodtianqi:.:" .. "dongzhuxianji")
			end
		end
	end
	if package_known(self.player,"isWounded") and package_known(self,"getCardsNum","Peach") == 0 then
		if top == "BasicCard" then
			local card = source_skill(self,"#sgkgodtianqi:.:" .. "peach")
			local peach = clone_native(self,"peach")
			local dummyuse = { isDummy = true }
			package_call(self,"useBasicCard",peach, dummyuse)
			if dummyuse.card then return card end
		end
	end
	local tricks ={"zhujinqiyuan", "amazing_grace", "archery_attack", "savage_assault", "iron_chain", "dongzhuxianji"}
	local names = {}
	if top ~= nil then
		if top == "TrickCard" then
			for _, name in ipairs(tricks) do
				local drawpile = sgs.QList2Table(disclosed_top(self,"tianqi"))
				if #drawpile > 0 then
					local c = package_known(self,"getKnownCardById",drawpile[1])
					local card = clone_native(self,name, package_known(c,"getSuit"), package_known(c,"getNumber"))
					local dummyuse = { isDummy = true }
					package_call(self,"useTrickCard",card, dummyuse)
					if dummyuse.card then
						table.insert(tianqiTrickCard_str, "#sgkgodtianqi:.:" .. package_known(card,"objectName"))
						if not table.contains(names, name) then table.insert(names, name) end
					end
				end
			end
		end
		if top == "BasicCard" then
			if package_known(self.player,"isWounded") then
				local peach_str = "#sgkgodtianqi:.:" .. "peach"
				table.insert(tianqiBasicCard_str, peach_str)
				if not table.contains(names, "peach") then table.insert(names, "peach") end
			end
		end
	end
	local function filter_tianqi(objectName)
		local fakeCard
		local tianqi = "peach|dongzhuxianji|zhujinqiyuan|amazing_grace|archery_attack|savage_assault"
		local ban = table.concat(package_known(self.room,"getBanPackages"), "|")
		if not package_known(ban,"match","maneuvering") then tianqi = tianqi .. "|fire_attack" end
		local tianqis = package_known(tianqi,"split","|")
		for i = 1, #tianqis do
			local forbidden = tianqis[i]
			local forbid = clone_native(self,forbidden)
			if package_known(self.player,"isLocked",forbid) then
				table.remove(tianqis, i)
				i = i - 1
			end
		end
		for i=1, 20 do
			local newtianqi = objectName or tianqis[math.random(1, #tianqis)]
			local tianqicard = clone_native(self,newtianqi)
			if package_known(tianqicard,"isKindOf",top) or top == nil or (not package_known(tianqicard,"isKindOf",top) and (not package_known(self,"isWeak")) and math.random(1, 4) == 1) then
				local dummyuse = {isDummy = true}
				if newtianqi == "peach" then package_call(self,"useBasicCard",tianqicard, dummyuse) else package_call(self,"useTrickCard",tianqicard, dummyuse) end
				if dummyuse.card then
					fakeCard = source_skill(self,"#sgkgodtianqi:.:" .. newtianqi)
					break
				end
			end
		end
		return fakeCard
	end
	if #tianqiTrickCard_str > 0 and not package_known(self,"isWeak") then
		local tianqi_trickstr = tianqiTrickCard_str[math.random(1, #tianqiTrickCard_str)]
		if top and top == "TrickCard" then
			if #self.enemies == 0 then
				local fake_exnihilo = filter_tianqi("dongzhuxianji")
				if fake_exnihilo then return fake_exnihilo end
			end
			return source_skill(self,tianqi_trickstr)
		end
	else
		if #tianqiBasicCard_str > 0 then
			if top == "BasicCard" and package_known(self.player,"isWounded") then
				local card = source_skill(self,"#sgkgodtianqi:.:" .. "peach")
				local peach = clone_native(self,"peach")
				local dummyuse = { isDummy = true }
				package_call(self,"useBasicCard",peach, dummyuse)
				if dummyuse.card then return card end
			end
		end
	end
	if top == nil and package_known(self.player,"isWounded") then
		local card = source_skill(self,"#sgkgodtianqi:.:" .. "peach")
		local peach = clone_native(self,"peach")
		local dummyuse = { isDummy = true }
		package_call(self,"useBasicCard",peach, dummyuse)
		if dummyuse.card then return card end
	end
	local can_slash = (top and top == "BasicCard" and package_known(self,"getCardsNum","Slash") == 0) or
		(not top and package_known(self.player,"getHp") >= 2 and package_known(self,"getCardsNum","Slash") == 0 and math.random(1, 300) <= 108)
	if can_slash and package_known(self,"slashIsAvailable") then
		local card = source_skill(self,"#sgkgodtianqi:.:" .. "slash")
		local slash = clone_native(self,"slash")
		local dummyuse = { isDummy = true }
		package_call(self,"useBasicCard",slash, dummyuse)
		if dummyuse.card then return card end
	end
end

sgs.ai_skill_use_func["#sgkgodtianqi"] = function(card,use,self,request)
    if package_known(self.player,"getStrategyFlag","tianqi_used_basic") and package_known(self.player,"getStrategyFlag","tianqi_used_trick") then return nil end
	if package_known(self.player,"getStrategyFlag","Global_Dying") then return nil end
	if package_known(self.player,"getStrategyMark","Global_Dying") > 0 then return nil end
	local userstring=package_known(card,"toString")
	userstring=(package_known(userstring,"split",":.:"))[2]
	local tianqicard=clone_native(self,userstring)
	package_call(tianqicard,"setSkillName","sgkgodtianqi")
	if package_known(tianqicard,"getTypeId") == sgs.Card_TypeBasic then
		if not use.isDummy and use.card and package_known(tianqicard,"isKindOf","Slash") and ((not use.to) or (package_known(use.to,"isEmpty"))) then return end
		package_call(self,"useBasicCard",tianqicard, use)
	else
		assert(tianqicard)
		package_call(self,"useTrickCard",tianqicard, use)
	end
	if not use.card then return end
	use.card=card
end

function sgs.ai_cardsview_valuable.sgkgodtianqi(self, class_name, player)
	if package_known(player,"getStrategyFlag","Global_Dying") then return end
	if package_known(player,"getStrategyMark","Global_Dying") > 0 then return nil end
	if not package_known(player,"isAlive") then return end
	local top = owner_fact(self,player,"top_card")
	if class_name == "Slash" and top == "BasicCard" and owner_reason(self) == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
		return skill_proposal("#sgkgodtianqi",{},"slash")
	elseif (class_name == "Peach" and package_known(player,"getStrategyMark","Global_PreventPeach") == 0) or class_name == "Analeptic" and top == "BasicCard" then
		local dying = package_known(self.room,"getCurrentDyingPlayer")
		if dying and package_known(dying,"objectName") ~= package_known(player,"objectName") and package_known(player,"getStrategyMark","Global_PreventPeach") == 0 then
			return skill_proposal("#sgkgodtianqi",{},"peach")
		else
			local user_string
			if class_name == "Analeptic" then user_string = "analeptic" else user_string = "peach" end
			return skill_proposal("#sgkgodtianqi",{},user_string)
		end
	end
	if math.random(1, 3) <= 1 and package_known(self,"getCardsNum",class_name) == 0 then return skill_proposal("#sgkgodtianqi",{},class_name) end
end

sgs.ai_use_priority["sgkgodtianqi"] = sgs.ai_use_priority.ExNihilo - 0.1



sgs.ai_skill_choice["sgkgodtianji"] = function(self, choices, data)
    local tianji = package_known(choices,"split","+")
	local ids = disclosed_top(self,"tianji")
	local card = package_known(self,"getKnownCardById",package_known(ids,"first"))
	local canget = source_fact(self,"tianji_canget","toBool")
	if not package_known(self,"needKongcheng",self.player) then return "tianji_obtain" end
	if package_known(card,"isKindOf","Peach") or package_known(card,"isKindOf","ExNihilo") or package_known(card,"isKindOf","Jink") or package_known(card,"isKindOf","Slash") or package_known(card,"isKindOf","Nullification") then
	    if canget then return "tianji_obtain" else return "tianji_exchange" end
	end
	if package_known(card,"isKindOf","Analeptic") then
	    if package_known(self,"isWeak") then
		    if canget then return "tianji_obtain" else return "tianji_exchange" end
		else
		    if canget then return tianji[math.random(1, 2)] else return "tianji_obtain" end
		end
	end
	if canget then return tianji[math.random(1, 2)] end
	return tianji[math.random(1, #tianji)]
end

sgs.ai_skill_cardask["@tianji_exchange"] = function(self, data, pattern)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByKeepValue",cards)
	if package_call(self.room,"getCurrent"):getSeat() == package_known(self.player,"getSeat") then
		if package_known(self,"getCardsNum","Peach") == 0 and package_known(self.player,"isWounded") then
			local card
			for _, c in ipairs(cards) do
				if package_known(c,"isKindOf","BasicCard") then
					card = c
					break
				end
			end
			return package_known(card,"getEffectiveId")
		end
		if #self.enemies == 0 then
			local card
			for _, c in ipairs(cards) do
				if package_known(c,"isKindOf","TrickCard") and not package_known(c,"isKindOf","ExNihilo") then
					card = c
					break
				end
			end
			return package_known(card,"getEffectiveId")
		end
	end
	return package_known(cards[1],"getEffectiveId")
end



sgs.ai_skill_invoke.sgkgodqinyin = function(self, data)
    package_call(self,"sort",self.friends, "hp")
	package_call(self,"sort",self.enemies, "hp")
	local up = 0
	local down = 0
	for _, friend in ipairs(self.friends) do
		down = down - 10
		up = up + (package_known(friend,"isWounded") and 10 or 0)
		if package_known(self,"hasSkills",sgs.masochism_skill, friend) then
			down = down - 5
			if package_known(friend,"isWounded") then up = up + 5 end
		end
		if package_known(self,"needToLoseHp",friend, nil, nil, true) then down = down + 5 end
		if package_known(self,"needToLoseHp",friend, nil, nil, true, true) and package_known(friend,"isWounded") then up = up - 5 end
		if package_known(self,"isWeak",friend) then
			if package_known(friend,"isWounded") then up = up + 10 + (package_known(friend,"isLord") and 20 or 0) end
			down = down - 10 - (package_known(friend,"isLord") and 40 or 0)
			if package_known(friend,"getHp") <= 1 and not package_known(friend,"hasSkill","buqu") or package_known(friend,"getPile","buqu"):length() > 4 then
				down = down - 20 - (package_known(friend,"isLord") and 40 or 0)
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		down = down + 10
		up = up - (package_known(enemy,"isWounded") and 10 or 0)
		if package_known(self,"hasSkills",sgs.masochism_skill, enemy) then
			down = down + 10
			if package_known(enemy,"isWounded") then up = up - 10 end
		end
		if package_known(self,"needToLoseHp",enemy, nil, nil, true) then down = down - 5 end
		if package_known(self,"needToLoseHp",enemy, nil, nil, true, true) and package_known(enemy,"isWounded") then up = up - 5 end

		if package_known(self,"isWeak",enemy) then
			if package_known(enemy,"isWounded") then up = up - 10 end
			down = down + 10
			if package_known(enemy,"getHp") <= 1 and not package_known(enemy,"hasSkill","buqu") then
				down = down + 10 + ((package_known(enemy,"isLord") and #self.enemies > 1) and 20 or 0)
			end
		end
	end
	if package_known(self,"isWeak") and package_known(self.player,"getCards","he"):length() >= 2 then
	    package_call(self,"setStrategyMemory","hunlie.choice.qinyin","qinyin_allrecover")
		return true
	end
	if down > 0 then
		package_call(self,"setStrategyMemory","hunlie.choice.qinyin","qinyin_alllose")
		return true
	elseif up > 0 then
		package_call(self,"setStrategyMemory","hunlie.choice.qinyin","qinyin_allrecover")
		return true
	else
	    if not package_known(self,"isWeak") then
	        package_call(self,"setStrategyMemory","hunlie.choice.qinyin","qinyin_alllose")
		    return true
		end
	end
	return false
end



local sgkgodyeyan_skill = {}
sgkgodyeyan_skill.name = "sgkgodyeyan"
table.insert(package_skills, sgkgodyeyan_skill)
sgkgodyeyan_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"isKongcheng") then return nil end
	if package_known(self.player,"getStrategyMark","@sk_fire") <= 0 then return nil end
	local can_do = false
	for _, card in sgs.qlist(package_known(self.player,"getCards","h")) do
	    if package_known(card,"isRed") then
			can_do = true
			break
		end
	end
	if can_do then
	    return source_skill(self,"#sgkgodyeyanCard:.:")
	end
end

sgs.ai_skill_use_func["#sgkgodyeyanCard"] = function(card,use,self,request)
	local red_cards, black_cards = {}, {}
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards, false, true)
	for _, card in ipairs(cards) do
		if package_known(card,"isRed") then
			table.insert(red_cards, package_known(card,"getId"))
		elseif package_known(card,"isBlack") then
			table.insert(black_cards, package_known(card,"getId"))
		end
	end
	local can_yeyan = {}
	local to_use = false
	for _, enemy in ipairs(self.enemies) do
	    if not package_known(enemy,"hasArmorEffect","silver_lion") and package_known(self,"objectiveLevel",enemy) > 3 and package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Fire)
        and not (package_known(enemy,"hasSkill","tianxiang") and package_known(enemy,"getHandcardNum") > 0) then
		    if package_known(enemy,"isChained") then
                if package_known(enemy,"hasArmorEffect","vine") or package_known(enemy,"getStrategyMark","&kuangfeng") > 0 then
			        table.insert(can_yeyan, enemy)
				end
			else
				if enemy then table.insert(can_yeyan, enemy) end
			end
		end
		if #black_cards <= 1 then
		    if package_known(self,"damageIsEffective",enemy, sgs.DamageStruct_Fire) and not package_known(enemy,"hasSkill","tianxiang") and package_known(self,"objectiveLevel",enemy) > 3 then
			    if package_known(enemy,"getHp") <= math.min(3, #red_cards) then table.insert(can_yeyan, enemy) end
				if package_known(self,"isWeak",enemy) then table.insert(can_yeyan, enemy) end
			end
		end
	end
	if #can_yeyan > 0 then to_use = true end
	package_call(self,"sort",can_yeyan, "hp")
    local need_ids, to_yeyan = {}, {}
	if #black_cards > 0 then
		for i = 1, #black_cards, 1 do
			table.insert(need_ids, black_cards[i])
			if i == math.min(2, #black_cards, #can_yeyan - 1) then break end
		end
	end
	if #can_yeyan > 0 then
		for i = 1, #need_ids + 1, 1 do
			table.insert(to_yeyan, can_yeyan[i])
		end
	end
	for _, id in ipairs(red_cards) do
		table.insert(need_ids, id)
		if #need_ids == 4 then break end
	end
	if to_use then
	    use.card = source_skill(self,"#sgkgodyeyanCard:" .. table.concat(need_ids, "+") .. ":")
		if use.to then
		    for _, enemy in ipairs(to_yeyan) do
			    package_call(use.to,"append",enemy)
			end
			assert(package_known(use.to,"length") > 0)
		end
	end
end


sgs.ai_use_value["sgkgodyeyanCard"] = 8
sgs.ai_use_priority["sgkgodyeyanCard"] = sgs.ai_use_priority.ExNihilo - 0.1
sgs.ai_card_intention["sgkgodyeyanCard"] = 300



sgs.ai_skill_invoke.sgkgodxianzhu = function(self, data)
	local player = package_call(data,"toPlayer")
	return package_known(self,"isFriend",player)
end

sgs.ai_choicemade_filter.skillInvoke.sgkgodxianzhu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = package_call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end

sgs.lose_equip_skill = sgs.lose_equip_skill .. "|sgkgodxianzhu"
sgs.ai_use_revises.sgkgodxianzhu = function(self,card,use)
	if package_known(card,"isKindOf","EquipCard") and package_known(self,"evaluateArmor",card)>-5
	then use.card = card return true end
end
sgs.ai_cardneed.sgkgodxianzhu = sgs.ai_cardneed.equip


local sgkgodliangyuan_skill = {}
sgkgodliangyuan_skill.name = "sgkgodliangyuan"
table.insert(package_skills, sgkgodliangyuan_skill)
sgkgodliangyuan_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"hasUsed","#sgkgodliangyuanCard") then return nil end
	if package_known(self.player,"getStrategyMark","@liangyuan") == 0 then return nil end
	if #self.friends_noself == 0 then return nil end
	local a = 0
	for _, p in ipairs(self.friends_noself) do
	    if package_known(p,"isMale") then a = a+1 end
	end
	if a <= 0 then return nil end
	return source_skill(self,"#sgkgodliangyuanCard:.:")
end

sgs.ai_skill_use_func["#sgkgodliangyuanCard"] = function(card,use,self,request)
    local liangyuan_male

	local lord = package_call(self.room,"getLord")
	if package_known(self.player,"isFemale") and package_known(lord,"isMale") and package_known(self.player,"getRole") == "loyalist" then liangyuan_male = lord end
	if not liangyuan_male then
		package_call(self,"sort",self.friends_noself, "chaofeng")
		for _, target in ipairs(self.friends_noself) do
			if not package_known(target,"hasSkill","dawu") and package_known(target,"hasSkills","yongsi|zhiheng|sgkgodjilue|sk_diezhang|sk_yaoming" .. sgs.priority_skill .. "|shensu")
				and (not package_known(self,"willSkipPlayPhase",target) or package_known(target,"hasSkill","shensu")) and package_known(target,"isMale") then
				liangyuan_male = target
				break
			end
		end
	end
	if not liangyuan_male then
		package_call(self,"sort",self.friends_noself, "chaofeng")
		for _, target in ipairs(self.friends_noself) do
			liangyuan_male = target
			break
		end
	end
	if liangyuan_male then
	    use.card = card
		if use.to then package_call(use.to,"append",liangyuan_male) end
	end
end

sgs.ai_use_value["sgkgodliangyuan"] = 10
sgs.ai_use_priority["sgkgodliangyuan"] = 10
sgs.ai_card_intention["sgkgodliangyuan"]  = -100



sgs.ai_skill_playerchosen.sgkgodwangyue = function(self, targets)
	local move = source_fact(self,"wangyue_draw_AI","toMoveOneTime")
	if move ~= nil then
		local x = package_known(move.card_ids,"length")
		local players = sgs.QList2Table(targets)
		package_call(self,"sort",players, "defense")
		if x >= 2 then
			local target
			if package_known(self,"isWeak") then target = self.player end
			if not target then
				for _, pe in ipairs(players) do
					if package_known(self,"isWeak",target) and package_known(self,"isFriend",target) then
						target = pe
						break
					end
				end
			end
			return target
		end
	end
	local lose = source_fact(self,"wangyue_rec_AI","toHpLost")
	if lose ~= nil then
		local x = lose.lose
		local players = sgs.QList2Table(targets)
		package_call(self,"sort",players, "hp")
		if x > 0 then
			local target
			if package_known(self,"isWeak") and package_known(self.player,"isWounded") then target = self.player end
			for _, pe in ipairs(players) do
				if package_known(pe,"hasSkill","hunzi") and package_known(pe,"getHp") <= 1 and package_known(pe,"getStrategyMark","@waked") == 0 and (not package_known(self,"isWeak")) then
					target = pe
					break
				end
			end
			if not target then
				for _, pe in ipairs(players) do
					if package_known(self,"isWeak",target) and package_known(self,"isFriend",target) then
						target = pe
						break
					end
				end
			end
			return target
		end
	end
	local mhp = source_fact(self,"wangyue_maxhp_AI","toMaxHp")
	if mhp ~= nil and mhp < 0 then
		local x = 0 - mhp.change
		local players = sgs.QList2Table(targets)
		package_call(self,"sort",players)
		local target

		for _, pe in ipairs(targets) do
			if package_known(self,"isFriend",pe) and package_known(pe,"hasSkills","f_pinghe|sgkgodyinyang|quedi|zaiqi|fangzhu|jilve|yinghun|shangshi|weizhong|yizheng|poxi|hunzi|jintairan|yingzi|miji|sgkgodxingyun") then
				target = pe
				break
			end
		end

		if not target then
			for _, pe in ipairs(targets) do
				if package_known(self,"isFriend",pe) and package_known(pe,"getMaxHp") <= 3 then
					target = pe
					break
				end
			end
		end

		if not target then
			for _, pe in ipairs(targets) do
				if package_known(self,"isFriend",pe) and package_known(pe,"getLostHp") <= 2 then
					target = pe
					break
				end
			end
		end

		if not target then
			target = self.player
		end
	end
	return self.player
end
sgs.ai_playerchosen_intention.sgkgodwangyue = -80


function isDangerousCaopi(enemy)
	return (package_known(enemy,"hasSkills","fangzhu|jilve|sy_old_renji|new_jilve")) and package_known(enemy,"getMaxHp") <= 4
end

function canUseMoreCards(target)
	return package_known(target,"hasSkills","fenyin|sgkgodjilue|tyyizhao|jieyingg|dl_quandao|jizhi|nosjizhi|sr_qicai|tenyearzhiheng|zhiheng|f_lingce|pianchong|f_huishi|sgkgodguixin")
end

sgs.ai_skill_invoke.sgkgodluoyan = function(self, data)
	if #self.enemies == 0 then return false end
	if #self.enemies == 1 and package_known(self.room,"getAlivePlayers"):length() > 2 and isDangerousCaopi(self.enemies[1]) then return false end
	return true
end

sgs.ai_skill_playerchosen.sgkgodluoyan = function(self, targets)
	targets = sgs.QList2Table(targets)
	local target

	for _, pe in ipairs(targets) do
		if package_known(self,"isEnemy",pe) and package_known(pe,"getMaxHp") <= 2 then
			target = pe
			break
		end
	end

	if not target then
		for _, pe in ipairs(targets) do
			if package_known(self,"isEnemy",pe) and package_known(pe,"getMaxHp") <= 2 and package_known(pe,"hasSkills","zaoxian|zili|hunzi|zhiji|yizheng") then
				target = pe
				break
			end
		end
	end

	if not target then
		for _, pe in ipairs(targets) do
			if package_known(self,"isEnemy",pe) and (not package_known(pe,"containsTrick","indulgence")) and package_known(pe,"getHandcardNum") >= 2 and (not isDangerousCaopi(pe)) then
				if canUseMoreCards(pe) then
					target = pe
					break
				end
			end
		end
	end

	if not target then
		package_call(self,"sort",targets, "defense")
		for _, pe in ipairs(targets) do
			if package_known(self,"isEnemy",pe) and (not package_known(pe,"containsTrick","indulgence")) and package_known(pe,"getHandcardNum") >= 2 then
				target = pe
				break
			end
		end
	end
	return target
end
sgs.ai_playerchosen_intention.sgkgodluoyan = 80


local sgkgodliegong_skill = {}
sgkgodliegong_skill.name = "sgkgodliegong"
table.insert(package_skills, sgkgodliegong_skill)
sgkgodliegong_skill.getTurnUseCard = function(self,inclusive,request)
	local x = 1
	if package_known(self.player,"isWounded") then x = 2 end
	if package_known(self.player,"getStrategyMark","lg_fire_time") >= x then return end
	if #self.enemies == 0 then return end
	local cards = sgs.QList2Table(package_known(self.player,"getCards","h"))
	package_call(self,"sortByUseValue",cards, true)
	local need_ids = {}
	for _, c in ipairs(cards) do
		if package_known(c,"getSuit") == sgs.Card_Spade and not package_known(c,"isKindOf","Analeptic") then
			table.insert(need_ids, package_known(c,"getEffectiveId"))
			break
		end
	end
	for _, c in ipairs(cards) do
		if package_known(c,"getSuit") == sgs.Card_Heart and not package_known(c,"isKindOf","ExNihilo") then
			table.insert(need_ids, package_known(c,"getEffectiveId"))
			break
		end
	end
	for _, c in ipairs(cards) do
		if package_known(c,"getSuit") == sgs.Card_Club then
			table.insert(need_ids, package_known(c,"getEffectiveId"))
			break
		end
	end
	for _, c in ipairs(cards) do
		if package_known(c,"getSuit") == sgs.Card_Diamond and not package_known(c,"isKindOf","Analeptic") then
			table.insert(need_ids, package_known(c,"getEffectiveId"))
			break
		end
	end
	if #need_ids > 0 then
		if #need_ids == 1 then
			local c = package_known(self,"getKnownCardById",need_ids[1])
			return conversion_clone(self,"fire_slash","sgkgodliegong",package_known(c,"getSuit"),package_known(c,"getNumber"),{package_known(c,"getEffectiveId")})
		end
		if #need_ids == 2 then return conversion_clone(self,"fire_slash","sgkgodliegong",sgs.Card_NoSuit,0,need_ids) end
		if #need_ids == 3 then return conversion_clone(self,"fire_slash","sgkgodliegong",sgs.Card_NoSuit,0,need_ids) end
		if #need_ids == 4 then return conversion_clone(self,"fire_slash","sgkgodliegong",sgs.Card_NoSuit,0,need_ids) end
	end
end

sgs.ai_view_as["sgkgodliegong"] = function(card, player, card_place, class_name)
 local self=actor_ai(player)
	local cards = sgs.QList2Table(package_known(player,"getCards","h"))
	local x = 1
	if package_known(player,"isWounded") then x = 2 end
	if package_known(player,"getStrategyMark","lg_fire_time") >= x then return end
	local need_ids = {}
	for _, c in ipairs(cards) do
		if package_known(c,"getSuit") == sgs.Card_Spade and not package_known(c,"isKindOf","Analeptic") then
			table.insert(need_ids, package_known(c,"getEffectiveId"))
			break
		end
	end
	for _, c in ipairs(cards) do
		if package_known(c,"getSuit") == sgs.Card_Heart and not package_known(c,"isKindOf","ExNihilo") then
			table.insert(need_ids, package_known(c,"getEffectiveId"))
			break
		end
	end
	for _, c in ipairs(cards) do
		if package_known(c,"getSuit") == sgs.Card_Club then
			table.insert(need_ids, package_known(c,"getEffectiveId"))
			break
		end
	end
	for _, c in ipairs(cards) do
		if package_known(c,"getSuit") == sgs.Card_Diamond and not package_known(c,"isKindOf","Analeptic") then
			table.insert(need_ids, package_known(c,"getEffectiveId"))
			break
		end
	end
	if #need_ids >= 2 then
		if #need_ids == 2 then
			return {name="fire_slash",skill="sgkgodliegong",suit=sgs.Card_NoSuit,number=0,subcards=need_ids}
		elseif #need_ids == 3 then
			return {name="fire_slash",skill="sgkgodliegong",suit=sgs.Card_NoSuit,number=0,subcards=need_ids}
		elseif #need_ids == 4 then
			return {name="fire_slash",skill="sgkgodliegong",suit=sgs.Card_NoSuit,number=0,subcards=need_ids}
		end
	else
		local suit = package_known(card,"getSuitString")
		local number = package_known(card,"getNumberString")
		local card_id = package_known(card,"getEffectiveId")
		return {name="fire_slash",skill="sgkgodliegong",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
	end
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|sgkgodliegong"
sgs.ai_ajustdamage_from.sgkgodliegong = function(self, from, to, card, nature)
	if (card and (package_known(card,"isKindOf","Slash") and package_known(card,"subcardsLength") >= 3 )) and table.contains(package_known(card,"getSkillNames"), "sgkgodliegong")
	then
		return 1
	end
end

sgs.ai_skill_playerchosen.sgkgodbamen = function(self, targets)
	local room = self.room
	local tos = {}
	for _, p in sgs.qlist(targets) do
		if package_known(self,"isEnemy",p) then
			if package_known(self,"damageIsEffective",p, sgs.DamageStruct_Thunder) then table.insert(tos, p) end
		end
	end
	if #tos > 0 then
		package_call(self,"sort",tos, "hp")
		return tos[1]
	else
	    return nil
	end
	return nil
end

sgs.ai_target_revises.sgkgodgucheng = function(to,card,self)
	local gc = public_property(self,to,"SkillDescriptionRecord_sgkgodgucheng"):split("+")
	if not table.contains(gc, package_known(card,"objectName")) and package_known(self.player,"objectName") ~= package_known(to,"objectName") then
	return true end
end

sgs.ai_skill_invoke.sgkgodxingwu = function(self, data)
	if package_known(self.player,"getRole") == "rebel" then
		if package_call(self.room,"findPlayerBySkillName","sgkgodluocha") or package_call(self.room,"findPlayerBySkillName","sgkgodguoqu") then return false end
		return true
	end
	if math.random(1, 100) <= 50 then
		return package_known(self.player,"getStrategyMark","&sgkgodxingwu") < 1
	end
	return false
end


sgs.ai_skill_cardask["@xingwu_heart"] = function(self, data, pattern)
	local target = package_call(data,"toPlayer")
	if package_known(self,"isFriend",target) or (package_known(self,"isEnemy",target) and package_known(target,"getStrategyMark","&sgkgodxingwu") > 0) then
		local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
		package_call(self,"sortByKeepValue",cards)
		local h = {}
		for _, c in ipairs(cards) do
			if package_known(c,"getSuit") == sgs.Card_Heart then table.insert(h, c) end
		end
		if #h > 0 then
			package_call(self,"sortByKeepValue",h)
			return package_known(h[1],"getEffectiveId")
		end
	end
	return "."
end

sgs.ai_skill_choice["sgkgodxingwu"] = function(self, choices, data)
	local target = package_call(data,"toPlayer")
	if package_known(self,"isFriend",target) then
		return "addxingwumark"
	elseif package_known(self,"isEnemy",target) then
		return "transferxingwumark"
	end
end

sgs.ai_skill_playerchosen.sgkgodxingwu = function(self, targets)
	local friends = {}
	for _, pe in sgs.qlist(targets) do
		if package_known(self,"isFriend",pe) then table.insert(friends, pe) end
	end
	package_call(self,"sort",friends, "hp")
	return friends[1]
end

sgs.ai_skill_choice["xingwu_zhiheng_skills"] = function(self, choices, data)
	local target = package_call(data,"toPlayer")
	local xingwu_rec = owner_fact(self,target,"xingwu_rec"):split("+")
	local can_do = false
	if package_known(self,"isFriend",target) then
		for _, _sk in ipairs(xingwu_rec) do
			if string.find(sgs.bad_skills, _sk) then
				can_do = true
				break
			end
		end
		if can_do then return "xingwu_exchange_skills" end
	end
	if can_do == false and package_known(target,"objectName") == package_known(self.player,"objectName") then
		if #xingwu_rec <= 4 then
			if math.random(1, 1000) <= 300 then return "xingwu_exchange_skills" else return "cancel" end
		end
	end
	return "cancel"
end



sgs.ai_skill_playerchosen.sgkgodshenfu = function(self, targets)
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if package_known(self,"isEnemy",t) then
			if package_known(self,"damageIsEffective",t, sgs.DamageStruct_Thunder) or package_known(self.player,"hasSkill","jueqing") then
				table.insert(enemies, t)
			end
		end
	end
	package_call(self,"sort",enemies, "hp")
	if #enemies > 0 then
		return enemies[1]
	else
		return nil
	end
end

sgs.ai_getLeastHandcardNum_skill.sgkgodshenfu = function(self, player, least)
	if least < 4 then
		return 4
	end
end



local sgkgodqianqi_skill = {}
sgkgodqianqi_skill.name = "sgkgodqianqi"
table.insert(package_skills, sgkgodqianqi_skill)
sgkgodqianqi_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if package_known(self.player,"getStrategyMark","&sgkgodqianqi") == 0 then return end
	local card_str = string.format("slash:qianqi_slash[%s:%s]=.","no_suit",0)
	local slash=clone(self,"slash","qianqi_slash",sgs.Card_NoSuit,0)
	assert(slash)
	return slash
end

sgs.ai_cardsview_valuable["sgkgodqianqi"] = function(self,class_name,player)
	if class_name == "Slash" and package_known(self.player,"getStrategyMark","&sgkgodqianqi") > 0 then
		return {name="slash",skill="qianqi_slash",suit=sgs.Card_NoSuit,number=0,subcards={}}
	end
end

sgs.ai_card_intention["#sgkgodqianqiCard"] = sgs.ai_card_intention.Slash
sgs.ai_use_priority["#sgkgodqianqiCard"] = sgs.ai_use_priority.Slash - 0.1
sgs.double_slash_skill = sgs.double_slash_skill .. "|sgkgodqianqi"
sgs.ai_cardneed.sgkgodqianqi = sgs.ai_cardneed.slash


sgs.ai_skill_invoke.sgkgodjuechen = function(self, data)
	local to = package_call(data,"toPlayer")
	if package_known(self,"isEnemy",to) then
		if package_known(to,"hasSkills",sgs.masochism_skill.."|"..sgs.recover_skill.."|longhun|buqu|nosbuqu") then return true end
		if package_known(to,"hasSkills","wuhun|sgkgodsuohun|duanchang|sgkgodshenyin|sgkgodguiqu|sgkgodfangu|sgkgodlonghun|sgkgodchenyu") then return true end
		return package_known(to,"getLostHp") <= 1
	elseif package_known(self,"isFriend",to) then
		if package_known(to,"hasSkills","zhaxiang|mouzhaxiang") then return true end
	end
end

sgs.ai_skill_choice.sgkgodjuechen = function(self, choices, data)
	local juechen = package_known(choices,"split","+")
	local target = package_call(data,"toPlayer")
	if package_known(self,"isEnemy",target) then
		if package_known(target,"hasSkills",sgs.masochism_skill.."|"..sgs.recover_skill.."|longhun|buqu|nosbuqu") then return juechen[1] end
		if package_known(target,"hasSkills","wuhun|sgkgodsuohun|duanchang|sgkgodshenyin|sgkgodguiqu|sgkgodfangu|sgkgodlonghun|sgkgodchenyu") then return juechen[1] end
		if package_known(target,"hasSkills","sgkgodyinyang|sgkgodjiyin|sgkgodjiyang|sgkgodxiangsheng|sgkgoddingming") then return juechen[1] end
	elseif package_known(self,"isFriend",target) then
		if package_known(target,"hasSkills","zhaxiang|mouzhaxiang") then return juechen[2] end
	end
	local x = math.random(1, 100)
	if x <= 90 then
		return juechen[1]
	else
		return juechen[2]
	end
end
sgs.ai_cardneed.sgkgodjuechen = sgs.ai_cardneed.slash


local sgkgodhuchi_skill = {}
sgkgodhuchi_skill.name = "sgkgodhuchi"
table.insert(package_skills, sgkgodhuchi_skill)
sgkgodhuchi_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if package_known(self.player,"getStrategyMark","sgkgodhuchi_duel_forbidden-Clear") > 0 then return end
	local card_str = string.format("duel:sgkgodhuchi[%s:%s]=.","no_suit",0)
	local duel=clone(self,"duel","sgkgodhuchi",sgs.Card_NoSuit,0)
	assert(duel)
	return duel
end

sgs.ai_cardsview_valuable["sgkgodhuchi"] = function(self,class_name,player)
	if class_name == "Duel" and package_known(self.player,"getStrategyMark","sgkgodhuchi_duel_forbidden-Clear") == 0 then
		return {name="duel",skill="sgkgodhuchi",suit=sgs.Card_NoSuit,number=0,subcards={}}
	end
end

sgs.ai_card_intention["#sgkgodhuchiCard"] = sgs.ai_card_intention.Duel
sgs.ai_use_priority["#sgkgodhuchiCard"] = sgs.ai_use_priority.Duel

sgs.ai_ajustdamage_from.sgkgodxiejia = function(self, from, to, card, nature)
	if (card and (package_known(card,"isKindOf","Slash") or package_known(card,"isKindOf","Duel"))) and (package_call(from,"getArmor") == nil) and package_known(to,"getSeat") ~= package_known(from,"getSeat")
	then
		return 1 + package_known(from,"getStrategyMark","&sgkgodxiejia")
	end
end


sgs.ai_skill_cardask["@sgkgodchuyuan-black"] = function(self, data, pattern, target)
	local chuyuan, r, b = -1, 0, 0
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	for _, id in sgs.qlist(package_known(self.player,"getPile","sgkgodchu")) do
		local card = package_known(self,"getKnownCardById",id)
		if package_known(card,"isBlack") then
			b = b + 1
		elseif package_known(card,"isRed") then
			r = r + 1
		end
	end
	for _, c in ipairs(cards) do
		if package_known(c,"isBlack") then
			chuyuan = c
			break
		end
	end
	if chuyuan ~= -1 then
		if r + b < 5 then
			if r > b then
				return package_known(chuyuan,"getEffectiveId")
			else

			end
		else
			if (r + b) % 2 == 1 then
				if package_known(self,"isWeak") and math.min(r, b) >= 2 then

				end
			elseif (r + b) % 2 == 0 then
				if r >= b then return package_known(chuyuan,"getEffectiveId") else return "." end
			end
		end
		return package_known(chuyuan,"getEffectiveId")
	else
		return "."
	end
end

sgs.ai_skill_cardask["@sgkgodchuyuan-red"] = function(self, data, pattern, target)
	local chuyuan, r, b = -1, 0, 0
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	for _, id in sgs.qlist(package_known(self.player,"getPile","sgkgodchu")) do
		local card = package_known(self,"getKnownCardById",id)
		if package_known(card,"isBlack") then
			b = b + 1
		elseif package_known(card,"isRed") then
			r = r + 1
		end
	end
	for _, c in ipairs(cards) do
		if package_known(c,"isRed") then
			chuyuan = c
			break
		end
	end
	if chuyuan ~= -1 then
		if r + b < 5 then
			if r < b then
				return package_known(chuyuan,"getEffectiveId")
			else

			end
		else
			if (r + b) % 2 == 1 then
				if package_known(self,"isWeak") and math.min(r, b) >= 2 then

				end
			elseif (r + b) % 2 == 0 then
				if r < b then return package_known(chuyuan,"getEffectiveId") else return "." end
			end
		end
		return package_known(chuyuan,"getEffectiveId")
	else
		return "."
	end

end
sgs.ai_skill_invoke["sgkgodchuyuan"] = true


local sgkgodjiquan_skill = {}
sgkgodjiquan_skill.name = "sgkgodjiquan"
table.insert(package_skills, sgkgodjiquan_skill)
sgkgodjiquan_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","#sgkgodjiquanCard") then return nil end
	if #self.friends_noself == 0 or #self.enemies > 0 then
		return source_skill(self,"#sgkgodjiquanCard:.:")
	end
end

sgs.ai_skill_use_func["#sgkgodjiquanCard"] = function(card,use,self,request)
	local can_jiquan = {}
	local to_use = false
	for _, tar in sgs.list(package_known(self.room,"getOtherPlayers",self.player)) do
		if not package_known(self,"isFriend",tar) and not package_known(tar,"hasSkills",sgs.bad_skills) then
			table.insert(can_jiquan, tar)
		end
	end
	if #can_jiquan > 0 then to_use = true end
	package_call(self,"sort",can_jiquan, "hp")
	if to_use then
	    use.card = card
		if use.to then
		    for _, enemy in ipairs(can_jiquan) do
			    package_call(use.to,"append",enemy)
			end
			assert(package_known(use.to,"length") > 0)
		end
	end
end

sgs.ai_use_value["sgkgodjiquanCard"] = 10
sgs.ai_use_priority["sgkgodjiquanCard"] = 10

sgs.ai_skill_choice.sgkgodjiquan = function(self, choices, data)
	choices = package_known(choices,"split","+")
	local caopi = package_call(data,"toPlayer")
	if package_known(self,"isEnemy",caopi) then
		if package_known(self.player,"hasSkills",sgs.bad_skills) then
			return choices[2]
		else
			if package_known(self,"isWeak") and package_known(self.player,"getStrategyMark","sgkgodjiquan_times") >= 3 and package_known(self.player,"getCards","he"):length() - package_known(self.player,"getStrategyMark","sgkgodjiquan_times") <= 2 then
				return choices[2]
			end
		end
		return choices[1]
	else
		return choices[1]
	end
end



local sgkgodrenzheng_skill = {}
sgkgodrenzheng_skill.name = "sgkgodrenzheng"
table.insert(package_skills, sgkgodrenzheng_skill)
sgkgodrenzheng_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","#sgkgodrenzhengCard") then return nil end
	if #self.friends_noself == 0 then return nil end
	return source_skill(self,"#sgkgodrenzhengCard:.:")
end

sgs.ai_skill_use_func["#sgkgodrenzhengCard"] = function(card,use,self,request)
	local can_renzheng = {}
	local to_use = false
	for _, tar in sgs.list(package_known(self.room,"getOtherPlayers",self.player)) do
		if package_known(self,"isFriend",tar) or (package_known(self,"isEnemy",tar) and package_known(self.player,"hasSkills",sgs.bad_skills)) then
			table.insert(can_renzheng, tar)
		end
	end
	if #can_renzheng > 0 then to_use = true end
	package_call(self,"sort",can_renzheng, "defense")
	if to_use then
		local target = nil
	    use.card = card
		if use.to then
		    if package_known(self.player,"hasSkills",sgs.bad_skills) then
				for _, t in ipairs(can_renzheng) do
					if package_known(self,"isEnemy",t) then
						target = t
						break
					end
				end
			else
				target = can_renzheng[1]
			end
			if target then package_call(use.to,"append",target) end
			return
		end
	end
end

sgs.ai_use_value["sgkgodrenzhengCard"] = 10
sgs.ai_use_priority["sgkgodrenzhengCard"] = sgs.ai_use_priority.ExNihilo - 1

sgs.ai_skill_choice.sgkgodrenzheng = function(self, choices, data)
	choices = package_known(choices,"split","+")
	local to = package_call(data,"toPlayer")
	if package_known(self,"isEnemy",to) then
		if package_known(self.player,"hasSkills",sgs.bad_skills) then
			return choices[2]
		else
			if not package_known(self.player,"isKongcheng") and ((package_known(to,"hasSkill","kongcheng") and package_known(to,"isKongcheng")) or package_known(to,"hasSkill","shangshi") and package_known(to,"getHandcardNum") >= package_known(to,"getLostHp") and package_known(to,"isWounded")) then
				return choices[1]
			end
		end
	else
		return choices[math.random(1, 2)]
	end
end

sgs.ai_skill_choice["renzheng_giveskill"] = function(self, choices, data)
	choices = package_known(choices,"split","+")
	local result = nil
	local to = package_call(data,"toPlayer")
	if package_known(self,"isEnemy",to) then
		for _, name in ipairs(choices) do
			if string.find(sgs.bad_skills, name) then
				result = name
				break
			end
		end
		if not result then
			if table.contains(choices, "cancel") then
				result = "cancel"
			else
				for _, name in ipairs(choices) do
					if string.find(sgs.bad_skills, name) then
						result = name
						break
					end
				end
			end
		end
	elseif package_known(self,"isFriend",to) then
		if package_known(self.player,"getHp") <= 1 and package_known(self,"isWeak") then
			if package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") == 0 then
				if not table.contains(choices, "cancel") then
					result = choices[#choices]
				else
					if #choices == 1 then result = "cancel" end
				end
			end
		else
			if table.contains(choices, "cancel") then
				result = "cancel"
			else
				for _, name in ipairs(choices) do
					if not string.find(sgs.bad_skills, name) then
						if name == "sgkgodchuyuan" or name == "sgkgoddengji" then
							result = name
							break
						else
							if #choices > 2 and name ~= "sgkgodrenzheng" and name ~= "cancel" then
								result = name
								break
							end
						end
					end
				end
				if #choices <= 2 and table.contains(choices, "sgkgodrenzheng") then
					result = choices[math.random(1, #choices)]
				end
			end
		end
	end
	return result or "cancel"
end

sgs.ai_skill_choice["sgkgodrenzheng_buff"] = function(self, choices, data)
	choices = package_known(choices,"split","+")
	local result = nil
	local to = package_call(data,"toPlayer")
	if package_known(self,"isFriend",to) then
		return "yes"
	end
	return "no"
end



sgs.ai_skill_playerchosen.sgkgodlunce = function(self, targets)
	local target
	if #self.enemies > 0 then
		for _, t in sgs.qlist(targets) do
			if package_known(t,"hasSkills","sgkgodtongtian|sy_bolue|sy_old_bolue|sgkgodluocha|sgkgodzhitian|sgkgodzhiti|sgkgodyaozhi|sgkgodjieying|jinghe") then
				target = t
				break
			end
		end
		if not target then
			for _, t in sgs.qlist(targets) do
				if package_known(t,"hasSkills","jinqu|shelie|sgkgodshelie|sgkgodbamen|yongsi|mobilemouyangwei|zishu|sgkgodhuju|hengwu|qingshi|ny_zhangcai|ny_10th_zhangcai|ny_10th_qingbei|ny_10th_sujun") then
					target = t
					break
				end
			end
		end
		if not target then
			for _, t in sgs.qlist(targets) do
				if package_known(t,"hasSkills","ny_tenth_pingliao|sgkgodjilue|lingce|sgkgodhualong|guixin|jianying|sgkgodyingshi|shenwei|shezang|zhouxuanz|mouwusheng|zhaxiang|sgkgodshajue") then
					target = t
					break
				end
			end
		end
		if not target then
			for _, t in sgs.qlist(targets) do
				if package_known(t,"hasSkills","luanji|sgkgodhuchi|sy_mojian|sy_shiao|yingjian|qiangxi|jieyin|qingnang|shushen|jinquanbian|longhun|sgkgodlonghun|sr_shixue") then
					target = t
					break
				end
			end
		end
	end
	if not target then
		for _, t in sgs.qlist(targets) do
			if package_known(self,"isFriend",t) and package_known(self,"isWeak",t) then
				target = t
				break
			end
		end
	end
	if not target then
		target = self.player
	end
	return target
end

sgs.ai_skill_choice.sgkgodlunce = function(self, choices, data)
	local t = package_call(data,"toPlayer")
	local lunce = package_known(choices,"split","+")
	if package_known(self,"isEnemy",t) then
		if string.find(choices, "sgkgodshangce") then
			if package_known(t,"hasSkills","sgkgodtongtian|sy_bolue|sy_old_bolue|sgkgodluocha|sgkgodzhitian|sgkgodzhiti|sgkgodyaozhi|sgkgodjieying|jinghe|zhengnan") then
				return "sgkgodshangce"
			end
			if package_known(t,"hasSkills","jinqu|shelie|sgkgodshelie|sgkgodbamen|yongsi|mobilemouyangwei|zishu|sgkgodhuju|hengwu|qingshi|ny_zhangcai|ny_10th_zhangcai|ny_10th_qingbei|ny_10th_sujun") then
				return "sgkgodshangce"
			end
			if package_known(t,"hasSkills","ny_tenth_pingliao|sgkgodjilue|lingce|sgkgodhualong|guixin|jianying|sgkgodyingshi|shenwei|shezang|zhouxuanz|mouwusheng|zhaxiang|sgkgodshajue") then
				return "sgkgodshangce"
			end
			if package_known(t,"hasSkills","luanji|sgkgodhuchi|sy_mojian|sy_shiao|yingjian|qiangxi|jieyin|qingnang|shushen|jinquanbian|longhun|sgkgodlonghun|sr_shixue") then
				return "sgkgodshangce"
			end
		end
	elseif package_known(self,"isFriend",t) then
		if string.find(choices, "sgkgodshangce") then
			if package_known(t,"hasSkills","sgkgodtongtian|sy_bolue|sy_old_bolue|sgkgodluocha|sgkgodzhitian|sgkgodzhiti|sgkgodyaozhi|sgkgodjieying|jinghe") then
				return "sgkgodshangce"
			end
			if package_known(t,"hasSkills","jinqu|shelie|sgkgodshelie|sgkgodbamen|yongsi|mobilemouyangwei|zishu|sgkgodhuju|hengwu|qingshi|ny_zhangcai|ny_10th_zhangcai|ny_10th_qingbei|ny_10th_sujun") then
				return "sgkgodshangce"
			end
			if package_known(t,"hasSkills","ny_tenth_pingliao|sgkgodjilue|lingce|sgkgodhualong|guixin|jianying|sgkgodyingshi|shenwei|shezang|zhouxuanz|mouwusheng|zhaxiang|sgkgodshajue|xinghan") then
				return "sgkgodshangce"
			end
			if package_known(t,"hasSkills","luanji|sgkgodhuchi|sy_mojian|sy_shiao|yingjian|qiangxi|jieyin|qingnang|shushen|jinquanbian|longhun|sgkgodlonghun|sr_shixue|xingtu") then
				return "sgkgodshangce"
			end
		end
	end
	if package_known(t,"objectName") ~= package_known(self.player,"objectName") then
		for _, lc in ipairs(lunce) do
			if lc ~= "sgkgodshangce" then return lc end
		end
	else
		return lunce[math.random(1, #lunce)]
	end
end

sgs.ai_skill_choice["lunce_condition"] = function(self, choices, data)
	local t = package_call(data,"toPlayer")
	local cd = package_known(choices,"split","+")
	local st = source_fact(self,"st_AI","toString")
	if st == "sgkgodshangce" then
		if package_known(t,"hasSkills","sgkgodshelie|shelie|sgkgodjilue|sgkgodyingshi|yongsi|tenyearzhiheng|sgkgodtianzi|ny_10th_sujun|ny_10th_qingbei|ny_10th_zhangcai|sgkgodluocha|sgkgodhuju") then
			if table.contains(cd, "lunce_shang_suit") then return "lunce_shang_suit" end
			if table.contains(cd, "lunce_shang_type") then return "lunce_shang_type" end
		end
		if package_known(t,"hasSkills","mobilemouyangwei|zishu|hengwu|qingshi|jinqu|lingce|xingtu|sy_longbian|sy_yinzi|shezang|shanjia|olshanjia|xinghan|jianying|sgkgodyingshi") then
			if table.contains(cd, "lunce_shang_suit") then return "lunce_shang_suit" end
			if table.contains(cd, "lunce_shang_type") then return "lunce_shang_type" end
		end
		if package_known(t,"hasSkills","ny_tenth_pingliao|sgkgodjilue|lingce|sgkgodhualong|sgkgodshayi|sgkgodyingshi|shenwei|shezang|zhouxuanz|mouwusheng|zhaxiang|sgkgodshajue|xinghan|sy_shiao") then
			if table.contains(cd, "lunce_shang_causedying") then return "lunce_shang_causedying" end
		end
		if package_known(self,"isWeak",t) or package_known(t,"hasSkills","sgkgodjuejing|newjuejing|zhaohuo|buqu|nosbuqu") then
			if table.contains(cd, "lunce_shang_dying") then return "lunce_shang_dying" end
		end
		if package_known(t,"hasSkills","sgkgodtongtian|sy_bolue|sy_old_bolue|sgkgodluocha|sgkgodzhitian|sgkgodzhiti|sgkgodyaozhi|sgkgodjieying|jinghe|zhengnan") then
			if table.contains(cd, "lunce_shang_acquireskill") then return "lunce_shang_acquireskill" end
		end
		if package_known(t,"hasSkills","sgkgodguiqu|sy_bolue|sy_old_bolue|sgkgodqianyuan") then
			if table.contains(cd, "lunce_shang_loseskill") then return "lunce_shang_loseskill" end
		end
	elseif st == "sgkgodzhongce" then
		if package_known(t,"hasSkills","jiuchi|duanliang|qingguo|kanpo|olkanpo|oljiuchi|longhun|newlonghun|sgkgodlonghun|mouwusheng|sgkgodshajue") then
			if table.contains(cd, "lunce_zhong_2spade") then return "lunce_zhong_2spade" end
		end
		if package_known(t,"hasSkills","wushen|wusheng|mouwusheng|sgkgodshajue|jijiu|nosenyuan|moujizhi|lingce") then
			if table.contains(cd, "lunce_zhong_2heart") then return "lunce_zhong_2heart" end
		end
		if package_known(t,"hasSkills","huoshou|luanji|olluanji|shizhan|sgkgodhuchi|xingxiezheng|chuifeng|quedi|huoji|guanbian|sy_mojian") then
			if table.contains(cd, "lunce_zhong_trick2dmg") then return "lunce_zhong_trick2dmg" end
		end
		if package_known(t,"hasSkills","sgkgodshajue|sgkgodshayi|paixiao|mouliegongg|moupaoxiao|mobilepojun|sgkgodyeyan|shajue|yanru|qingshi|zhangcai|shensu|sy_shiao|sy_shenji|wushuang|jieyingg") then
			if table.contains(cd, "lunce_zhong_slash2dmg") then return "lunce_zhong_slash2dmg" end
		end
	end
	return cd[math.random(1, #cd)]
end

sgs.ai_skill_choice["lunce_effect"] = function(self, choices, data)
	local t = package_call(data,"toPlayer")
	local ef = package_known(choices,"split","+")
	local cd = source_fact(self,"lunce_condition_AI","toString")
	if package_known(cd,"startsWith","lunce_shang_") then
		if package_known(self,"isEnemy",t) then
			if table.contains(ef, "lunce_shang_loserandomskill") then return "lunce_shang_loserandomskill" end
			if table.contains(ef, "lunce_shang_throwallcards") and not package_known(t,"isNude") then return "lunce_shang_throwallcards" end
		elseif package_known(self,"isFriend",t) then
			if table.contains(ef, "lunce_shang_gainsamekingdomskill") then return "lunce_shang_gainsamekingdomskill" end
			if table.contains(ef, "lunce_shang_1maxhp1recover") then return "lunce_shang_1maxhp1recover" end
			if table.contains(ef, "lunce_shang_gainsamekingdomskill") and table.contains(ef, "lunce_shang_1maxhp1recover") then
				return ef[math.random(1, 2)]
			end
		end
	elseif package_known(cd,"startsWith","lunce_zhong_") then
		if package_known(self,"isEnemy",t) then
			if table.contains(ef, "lunce_zhong_turnover") and package_known(t,"faceUp") and (not package_known(t,"hasSkills","jushou|kuiwei|faen|moujushou")) then return "lunce_zhong_turnover" end
			if table.contains(ef, "lunce_zhong_losemaxhp") and not package_known(t,"hasSkill","sgkgodwangyue|sgkgoddanjing") then return "lunce_zhong_losemaxhp" end
		elseif package_known(self,"isFriend",t) then
			if table.contains(ef, "lunce_zhong_drawphase") then return "lunce_zhong_drawphase" end
			if table.contains(ef, "lunce_zhong_slashtime") then return "lunce_zhong_slashtime" end
			if table.contains(ef, "lunce_zhong_drawphase") and table.contains(ef, "lunce_zhong_slashtime") then
				return ef[math.random(1, 2)]
			end
		end
	elseif package_known(cd,"startsWith","lunce_xia_") then
		if package_known(self,"isEnemy",t) then
			if table.contains(ef, "lunce_xia_throw2") and not package_known(t,"isNude") then return "lunce_xia_throw2" end
			if table.contains(ef, "lunce_xia_firedamage") and not package_known(t,"hasSkills","shixin|sr_weiwo|sgkgodyinshi") then return "lunce_xia_firedamage" end
		elseif package_known(self,"isFriend",t) then
			if table.contains(ef, "lunce_xia_draw2") then return "lunce_xia_draw2" end
			if table.contains(ef, "lunce_xia_recover1") and package_known(t,"isWounded") then return "lunce_xia_recover1" end
			if table.contains(ef, "lunce_xia_draw2") and table.contains(ef, "lunce_xia_recover1") and package_known(t,"isWounded") then
				return ef[math.random(1, 2)]
			end
		end
	end
end



sgs.ai_skill_choice.sgkgodhanshuang = function(self, choices, data)
	local t = package_call(data,"toPlayer")
	local hs = package_known(choices,"split","+")
	local damage = source_fact(self,"hanshuang_AI_data","toDamage")
	if #hs == 3 then
		if package_known(self,"isFriend",t) then
			if package_known(self,"isWeak",t) and damage.damage >= package_known(t,"getHp") then return hs[2] end
			if package_known(t,"hasArmorEffect","silver_lion") then
				if package_known(t,"hasSkills",sgs.masochism_skill) and package_known(t,"getHp") >= 2 then return hs[1] end
				if package_known(t,"hasSkill","sy_fangu") and package_known(t,"getHp") >= 2 then return hs[1] end
			end
			if package_known(t,"hasSkill","sgkgodyinshi") and damage.nature and damage.nature ~= sgs.DamageStruct_Thunder then return hs[1] end
			if package_known(t,"hasSkill","sgkgodleihun") and damage.nature and damage.nature == sgs.DamageStruct_Thunder then return hs[1] end
		elseif package_known(self,"isEnemy",t) then
			if package_known(t,"hasSkill","sgkgodleihun") and damage.nature and damage.nature == sgs.DamageStruct_Thunder then return hs[2] end
			if package_known(self.player,"getStrategyMark","sgkgodliluan-Clear") == 0 then
				if not package_known(t,"hasSkills",sgs.masochism_skill) and (not package_known(t,"hasSkill","sgkgodyinshi")) and (not package_known(t,"hasArmorEffect","silver_lion")) then return hs[1] end
			end
			if package_known(t,"getStrategyMark","&sgkgodhanshuang_times_lun") == 0 then
				if not package_known(t,"hasSkills",sgs.masochism_skill) and (not package_known(t,"hasSkill","sgkgodyinshi")) and (not package_known(t,"hasArmorEffect","silver_lion")) then return hs[1] end
			elseif package_known(t,"getStrategyMark","&sgkgodhanshuang_times_lun") >= 1 then
				if (not package_known(t,"hasSkill","sgkgodyinshi")) and (not package_known(t,"hasArmorEffect","silver_lion")) then return hs[1] end
				if not package_known(self,"isWeak",t) then
					if package_known(t,"hasSkills",sgs.masochism_skill) or package_known(t,"hasSkill","sgkgodyinshi") then
						if package_known(t,"getCardCount") >= package_known(t,"getStrategyMark","&sgkgodhanshuang_times_lun") + 1 + damage.damage then
							return hs[2]
						end
					end
				end
			end
		end
		return "cancel"
	elseif #hs == 2 then
		if package_known(self,"isFriend",t) then
			if package_known(t,"hasSkill","sgkgodleihun") and damage.nature and damage.nature == sgs.DamageStruct_Thunder then return "cancel" end
			if package_known(self,"isWeak",t) and damage.damage >= package_known(t,"getHp") then return "cancel" end
			if package_known(t,"hasArmorEffect","silver_lion") then
				if package_known(t,"hasSkills",sgs.masochism_skill) and package_known(t,"getHp") >= 2 then return hs[1] end
				if package_known(t,"hasSkill","sy_fangu") and package_known(t,"getHp") >= 2 then return hs[1] end
			end
			if package_known(t,"hasSkill","sgkgodyinshi") and damage.nature and damage.nature ~= sgs.DamageStruct_Thunder then return hs[1] end
			if package_known(t,"hasSkill","sgkgodleihun") and damage.nature and damage.nature == sgs.DamageStruct_Thunder then return hs[1] end
		elseif package_known(self,"isEnemy",t) then
			if package_known(t,"hasSkill","sgkgodleihun") and damage.nature and damage.nature == sgs.DamageStruct_Thunder then return "cancel" end
			if package_known(self.player,"getStrategyMark","sgkgodliluan-Clear") == 0 then
				if not package_known(t,"hasSkills",sgs.masochism_skill) and (not package_known(t,"hasSkill","sgkgodyinshi")) and (not package_known(t,"hasArmorEffect","silver_lion")) then return hs[1] end
			end
			if package_known(t,"getStrategyMark","&sgkgodhanshuang_times_lun") == 0 then
				if not package_known(t,"hasSkills",sgs.masochism_skill) and (not package_known(t,"hasSkill","sgkgodyinshi")) and (not package_known(t,"hasArmorEffect","silver_lion")) then return hs[1] end
			elseif package_known(t,"getStrategyMark","&sgkgodhanshuang_times_lun") >= 1 then
				if (not package_known(t,"hasSkill","sgkgodyinshi")) and (not package_known(t,"hasArmorEffect","silver_lion")) then return hs[1] end
				if not package_known(self,"isWeak",t) then
					if package_known(t,"hasSkills",sgs.masochism_skill) or package_known(t,"hasSkill","sgkgodyinshi") then
						if package_known(t,"getCardCount") >= package_known(t,"getStrategyMark","&sgkgodhanshuang_times_lun") + 1 + damage.damage then
							return "cancel"
						end
					end
				end
			end
		end
		return "cancel"
	end
end



sgs.ai_skill_invoke.sgkgodliluan = function(self, data)
	local move = source_fact(self,"liluan_AI_movedata","toMoveOneTime")
	local target = package_call(data,"toPlayer")

	if move.to_place == sgs.Player_DiscardPile and (package_known(move.from_places,"contains",sgs.Player_PlaceHand)
	or package_known(move.from_places,"contains",sgs.Player_PlaceEquip)) and not package_known(move.from_places,"contains",sgs.Player_PlaceDelayedTrick) and
	bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
		if package_known(move.card_ids,"length") >= 2 and package_known(self,"isFriend",target) then return true end
	end

	if move.to_place == sgs.Player_PlaceHand and move.to and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DRAW
	or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW) then
		if package_known(move.card_ids,"length") >= 2 and package_known(self,"isEnemy",target) then return true end
	end
end

sgs.ai_ajustdamage_to["sgkgodyinshi"] = function(self,from,to,card,nature)
	if typo_natrue(self)~="T" then return -99 end
end

sgs.ai_ajustdamage_to["sgkgodleihun"] = function(self,from,to,card,nature)
	if typo_natrue(self)=="T" then return -99 end
end


sgs.ai_skill_choice.nos_sgkgodshelie = function(self, choices)
    local shelie = package_known(choices,"split","+")
	return shelie[math.random(1, #shelie)]
end



local nos_sgkgodgongxin_skill= {}
nos_sgkgodgongxin_skill.name = "nos_sgkgodgongxin"
table.insert(package_skills, nos_sgkgodgongxin_skill)
nos_sgkgodgongxin_skill.getTurnUseCard = function(self,inclusive,request)
    if #self.enemies == 0 then return nil end
	if package_known(self.player,"hasUsed","#nos_sgkgodgongxinCard") then return nil end
	local sgkgodgongxin_card = source_skill(self,"#nos_sgkgodgongxinCard:.:")
	assert(sgkgodgongxin_card)
	return sgkgodgongxin_card
end

sgs.ai_skill_use_func["#nos_sgkgodgongxinCard"] = function(card,use,self,request)
    package_call(self,"sort",self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if not package_known(enemy,"isKongcheng") and package_known(self,"objectiveLevel",enemy) > 0
			and (package_known(self,"hasSuit","heart", false, enemy) or package_known(self,"getKnownNum",enemy) ~= package_known(enemy,"getHandcardNum")) then
			use.card = card
			if use.to then
				package_call(use.to,"append",enemy)
			end
			return
		end
	end
end

sgs.ai_use_value["nos_sgkgodgongxinCard"] = 8.5
sgs.ai_use_priority["nos_sgkgodgongxinCard"] = 9.5
sgs.ai_card_intention["nos_sgkgodgongxinCard"] = 80




local nos_sgkgodlonghun_skill = {}
nos_sgkgodlonghun_skill.name = "nos_sgkgodlonghun"
table.insert(package_skills, nos_sgkgodlonghun_skill)
nos_sgkgodlonghun_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getHp")>1 then return end
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByUseValue",cards,true)
	for _, card in ipairs(cards) do
		if package_known(card,"getSuit") == sgs.Card_Diamond and package_known(self,"slashIsAvailable") then
			return conversion_clone(self,"fire_slash","nos_sgkgodlonghun",package_known(card,"getSuit"),package_known(card,"getNumber"),{package_known(card,"getEffectiveId")})
		end
	end
end

sgs.ai_view_as["nos_sgkgodlonghun"] = function(card, player, card_place)
 local self=actor_ai(player)
    local suit = package_known(card,"getSuitString")
	local number = package_known(card,"getNumberString")
	local card_id = package_known(card,"getEffectiveId")
	if package_known(player,"getHp") > 1 or card_place == sgs.Player_PlaceSpecial then return end
	if package_known(card,"getSuit") == sgs.Card_Diamond then
		return {name="fire_slash",skill="nos_sgkgodlonghun",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
	elseif package_known(card,"getSuit") == sgs.Card_Club then
		return {name="jink",skill="nos_sgkgodlonghun",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
	elseif package_known(card,"getSuit") == sgs.Card_Heart and package_known(player,"getStrategyMark","Global_PreventPeach") == 0 then
		return {name="peach",skill="nos_sgkgodlonghun",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
	elseif package_known(card,"getSuit") == sgs.Card_Spade then
		return {name="nullification",skill="nos_sgkgodlonghun",suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards={card_id}}
	end
end

sgs.nos_sgkgodlonghun_suit_value = {
    heart = 6.7,
	spade = 5,
	club = 4.2,
	diamond = 3.9,
}

function sgs.ai_cardneed.nos_sgkgodlonghun(to, card, self)
	if package_known(to,"getCardCount") > 3 then return false end
	if package_known(to,"isNude") then return true end
	return package_known(card,"getSuit") == sgs.Card_Heart or package_known(card,"getSuit") == sgs.Card_Spade
end


sgs.ai_skill_playerchosen.nos_sgkgodnizhan = function(self, targets)
    local to = sgs.QList2Table(targets)
	if package_known(self,"isFriend",to[1]) and package_known(self,"isEnemy",to[2]) then
	    return to[2]
	elseif package_known(self,"isEnemy",to[1]) and package_known(self,"isFriend",to[2]) then
	    return to[1]
	elseif package_known(self,"isEnemy",to[1]) and package_known(self,"isEnemy",to[2]) then
	    return to[math.random(1, 2)]
	end
end

sgs.ai_skill_invoke.nos_sgkgodnizhan = function(self, data)
    local damage = package_known(data,"toDamage")
	if package_known(self,"isFriend",damage.from) and (not package_known(self,"isFriend",damage.to)) then return true end
	if package_known(self,"isFriend",damage.to) and (not package_known(self,"isFriend",damage.from)) then return true end
	if package_known(self,"isEnemy",damage.from) and package_known(self,"isEnemy",damage.to) then return true end
	return false
end



sgs.ai_skill_invoke.nos_sgkgodweizhen = function(self, data)
    local s = 0
	for _, p in sgs.qlist(package_known(self.room,"getOtherPlayers",self.player)) do
	    s = s + package_known(p,"getStrategyMark","@xi")
	end
	return package_known(self.player,"getHp") <= 1 and s >= 2 and package_known(self.player,"getJudgingArea"):length() > 0
end



local nos_sgkgodtongxian_skill = {}
nos_sgkgodtongxian_skill.name = "nos_sgkgodtongtian"
table.insert(package_skills, nos_sgkgodtongxian_skill)
nos_sgkgodtongxian_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"isKongcheng") then return nil end
	if package_known(self.player,"getStrategyMark","@tian") <= 0 then return nil end
	local suits = {}
	for _, card in sgs.qlist(package_known(self.player,"getCards","he")) do
	    if package_known(card,"getSuit") == sgs.Card_Spade then
		    table.insert(suits, package_known(card,"getSuitString"))
			break
		end
	end
	for _, card in sgs.qlist(package_known(self.player,"getCards","he")) do
	    if package_known(card,"getSuit") == sgs.Card_Heart then
		    table.insert(suits, package_known(card,"getSuitString"))
			break
		end
	end
	for _, card in sgs.qlist(package_known(self.player,"getCards","he")) do
	    if package_known(card,"getSuit") == sgs.Card_Club then
		    table.insert(suits, package_known(card,"getSuitString"))
			break
		end
	end
	for _, card in sgs.qlist(package_known(self.player,"getCards","he")) do
	    if package_known(card,"getSuit") == sgs.Card_Diamond then
		    table.insert(suits, package_known(card,"getSuitString"))
			break
		end
	end
	if #suits > 3 then
	    return source_skill(self,"#nos_sgkgodtongtianCard:.:")
	end
end

sgs.ai_skill_use_func["#nos_sgkgodtongtianCard"] = function(card,use,self,request)
    local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	package_call(self,"sortByKeepValue",cards, false, true)
	local need_cards = {}
	local spade, club, heart, diamond
	for _, card in ipairs(cards) do
	    if package_known(card,"getSuit") == sgs.Card_Spade then
		    if (not package_known(self.player,"hasSkills","fankui|nosfankui")) and (not spade) then
			    spade = true
				table.insert(need_cards, package_known(card,"getId"))
			end
		elseif package_known(card,"getSuit") == sgs.Card_Heart then
		    if (not package_known(self.player,"hasSkill","guanxing")) and (not heart) then
			    heart = true
				table.insert(need_cards, package_known(card,"getId"))
			end
		elseif package_known(card,"getSuit") == sgs.Card_Club then
		    if (not package_known(self.player,"hasSkill","wansha")) and (not club) then
			    club = true
				table.insert(need_cards, package_known(card,"getId"))
			end
		elseif package_known(card,"getSuit") == sgs.Card_Diamond then
		    if (not package_known(self.player,"hasSkills","zhiheng|hujuzhiheng")) and (not diamond) then
			    diamond = true
				table.insert(need_cards, package_known(card,"getId"))
			end
		end
	end
	if #need_cards < 4 then return nil end
	local tongtian_cards = source_skill(self,"#nos_sgkgodtongtianCard:" .. table.concat(need_cards, "+") .. ":")
	assert(tongtian_cards)
	use.card = tongtian_cards
end


sgs.ai_use_value["nos_sgkgodtongtianCard"] = 10
sgs.ai_use_priority["nos_sgkgodtongtianCard"] = 9



local tongtian_zhiheng_skill = {}
tongtian_zhiheng_skill.name = "tongtian_zhiheng"
table.insert(package_skills, tongtian_zhiheng_skill)
tongtian_zhiheng_skill.getTurnUseCard = function(self,inclusive,request)
	if not package_known(self.player,"hasUsed","#tongtian_zhihengCard") then
		return source_skill(self,"#tongtian_zhihengCard:.:")
	end
end

sgs.ai_skill_use_func["#tongtian_zhihengCard"] = function(card,use,self,request)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))

	if package_known(self.player,"getHp") < 3 then
		local zcards = package_known(self.player,"getCards","he")
		local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
		local keep_slash = source_fact(self,"JilveWansha","toBool")
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = package_known(self,"aiUseCard",zcard, dummy())
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if package_known(p,"getHp") <= 1 then
									shouldUse = false
									if package_known(self.player,"distanceTo",p) > 1 then keep_weapon = package_call(self.player,"getWeapon") end
									break
								end
							end
							if package_known(dummy_use.to,"length") > 1 then shouldUse = false end
						end
						if not package_known(self,"isWeak") then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if package_known(zcard,"getTypeId") == sgs.Card_TypeTrick then
					local dummy_use = package_known(self,"aiUseCard",zcard, dummy())
					if dummy_use.card then shouldUse = false end
				end
				if package_known(zcard,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"hasEquip",zcard) then
					local dummy_use = package_known(self,"aiUseCard",zcard, dummy())
					if dummy_use.card then shouldUse = false end
					if keep_weapon and package_known(zcard,"getEffectiveId") == package_known(keep_weapon,"getEffectiveId") then shouldUse = false end
				end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","Armor") and not package_known(self,"needToThrowArmor") then shouldUse = false end
				if package_known(self.player,"hasEquip",zcard) and package_known(zcard,"isKindOf","DefensiveHorse") and not package_known(self,"needToThrowArmor") then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if package_known(self.player,"getHp") == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, package_known(zcard,"getId")) end
			end
		end
	end

	if #unpreferedCards == 0 then
		local use_slash_num = 0
		package_call(self,"sortByKeepValue",cards)
		for _, card in ipairs(cards) do
			if package_known(card,"isKindOf","Slash") then
				local will_use = false
				if use_slash_num <= package_known(card,"getTargetModResidue",self.player) then
					local dummy_use = package_known(self,"aiUseCard",card, dummy())
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, package_known(card,"getId")) end
			end
		end

		local num = package_known(self,"getCardsNum","Jink") - 1
		if package_call(self.player,"getArmor") then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if package_known(card,"isKindOf","Jink") and num > 0 then
					table.insert(unpreferedCards, package_known(card,"getId"))
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (package_known(card,"isKindOf","Weapon") and package_known(self.player,"getHandcardNum") < 3) or package_known(card,"isKindOf","OffensiveHorse")
				or package_known(self,"getSameEquip",card, self.player) or package_known(card,"isKindOf","AmazingGrace") then
				table.insert(unpreferedCards, package_known(card,"getId"))
			elseif package_known(card,"getTypeId") == sgs.Card_TypeTrick then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if not dummy_use.card then table.insert(unpreferedCards, package_known(card,"getId")) end
			end
		end

		if package_call(self.player,"getWeapon") and package_known(self.player,"getHandcardNum") < 3 then
			table.insert(unpreferedCards, package_call(self.player,"getWeapon"):getId())
		end

		if package_known(self,"needToThrowArmor") then
			table.insert(unpreferedCards, package_call(self.player,"getArmor"):getId())
		end

		if package_known(self.player,"getOffensiveHorse") and package_call(self.player,"getWeapon") then
			table.insert(unpreferedCards, package_known(self.player,"getOffensiveHorse"):getId())
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not package_known(self.player,"isJilei",package_known(self,"getKnownCardById",unpreferedCards[index])) then table.insert(use_cards, unpreferedCards[index]) end
	end

	if #use_cards > 0 then
		if package_known(self.room,"getMode") == "02_1v1" and sgs.GetConfig("1v1/Rule", "Classical") ~= "Classical" then
			local use_cards_kof = { use_cards[1] }
			if #use_cards > 1 then table.insert(use_cards_kof, use_cards[2]) end
			use.card = source_skill(self,"#tongtian_zhihengCard:" .. table.concat(use_cards_kof, "+") .. ":")
			return
		else
			use.card = source_skill(self,"#tongtian_zhihengCard:" .. table.concat(use_cards, "+") .. ":")
			return
		end
	end
end

sgs.ai_use_value["tongtian_zhihengCard"] = 9
sgs.ai_use_priority["tongtian_zhihengCard"] = 2.61
sgs.dynamic_value.benefit["tongtian_zhihengCard"] = true


function sgs.ai_cardneed.tongtian_zhiheng(to, card)
	return not package_known(card,"isKindOf","Jink")
end



sgs.ai_skill_invoke.tongtian_fankui = function(self, data)
    local damage = package_known(data,"toDamage")
	if package_known(self,"isEnemy",damage.from) then
	    return true
	end
	return false
end


local nos_sgkgodjilue_skill = {}
nos_sgkgodjilue_skill.name = "nos_sgkgodjilue"
table.insert(package_skills, nos_sgkgodjilue_skill)
nos_sgkgodjilue_skill.getTurnUseCard = function(self,inclusive,request)
    if package_known(self.player,"getStrategyFlag","jiluefailed") then return end
	return source_skill(self,"#nos_sgkgodjilueCard:.:")
end

sgs.ai_skill_use_func["#nos_sgkgodjilueCard"] = function(card,use,self,request)
    if package_known(self.player,"getStrategyFlag","jiluefailed") then return end
	use.card = card
end

sgs.ai_use_value["nos_sgkgodjilueCard"] = 10
sgs.ai_use_priority["nos_sgkgodjilueCard"] = 8
sgs.dynamic_value.benefit["nos_sgkgodjilueCard"] = true




ai_skill_use["TrickCard+^Nullification,Slash,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Slash,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Slash,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Slash,Analeptic,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,EquipCard,Slash,Peach,Analeptic|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
							local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,Analeptic,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,Slash,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,Slash,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,Slash,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Peach,Slash,Analeptic,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,Analeptic,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
							local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		end
	end
	return "."
end


ai_skill_use["TrickCard+^Nullification,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		end
	end
	return "."
end



ai_skill_use["Slash,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Slash,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Slash,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use[" Slash,Analeptic,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Slash") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
							local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
							local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Analeptic,EquipCard|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
							local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Slash,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Slash,EquipCard|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeTrick and not package_known(card,"isKindOf","Nullification") and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				if package_known(dummy_use.to,"isEmpty") then
					return selected(self,dummy_use.card,{})
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, package_known(p,"objectName"))
					end
					return selected(self,dummy_use.card,target_objectname)
				end
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
							local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Slash,Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
							local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Peach,Slash,Analeptic,EquipCard|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Peach") then
				local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    return selected(self,dummy_use.card,{})
				end
			elseif package_known(card,"isKindOf","Slash") then
			    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				if dummy_use.card then
				    if not package_known(dummy_use.to,"isEmpty") then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, package_known(p,"objectName"))
					    end
					    return selected(self,dummy_use.card,target_objectname)
					end
				end
			elseif package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
						    local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use[" Analeptic,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
							local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["Analeptic,EquipCard|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		elseif package_known(card,"getTypeId") == sgs.Card_TypeBasic and not package_known(self.player,"isLocked",card) then
		    if package_known(card,"isKindOf","Analeptic") then
			    local ana = clone_native(self,"analeptic", sgs.Card_NoSuit, 0)
				if not package_known(self.player,"isCardLimited",ana, sgs.Card_MethodUse) and not package_known(self.player,"isProhibited",self.player, ana) then
				    if package_known(self.player,"usedTimes","Analeptic") <= package_known(ana,"getTargetModResidue",self.player) then
					    if fact(self,"analeptic_available") then
							local dummy_use = package_known(self,"aiUseCard",card, dummy())
				            if dummy_use.card then
				                return selected(self,dummy_use.card,{})
				            end
						end
					end
				end
			end
		end
	end
	return "."
end


ai_skill_use["EquipCard,|.|.|.|."]=function(self,prompt,request)
    local cards = sgs.QList2Table(package_known(self.player,"getHandcards"))
	package_call(self,"sortByUseValue",cards)
	for _, card in ipairs(cards) do
		if package_known(card,"getTypeId") == sgs.Card_TypeEquip and not package_known(self.player,"isLocked",card) then
			local dummy_use = package_known(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return selected(self,dummy_use.card,{})
			end
		end
	end
	return "."
end



local nos_sgkgoddanjing_skill = {}
nos_sgkgoddanjing_skill.name = "nos_sgkgoddanjing",
table.insert(package_skills, nos_sgkgoddanjing_skill)
nos_sgkgoddanjing_skill.getTurnUseCard = function(self,inclusive,request)
    if #self.enemies == 0 and #self.friends_noself == 0 then return nil end
	if package_known(self.player,"getHp") <= 2 then return nil end
    if package_known(self.player,"hasUsed","#nos_sgkgoddanjingCard") then return nil end
	return source_skill(self,"#nos_sgkgoddanjingCard:.:")
end

sgs.ai_skill_use_func["#nos_sgkgoddanjingCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_skill_playerchosen["nos_sgkgoddanjing"] = function(self, targets)
    local players = {}
	for _, t in sgs.qlist(targets) do
	    if package_known(self,"isFriend",t) then
		    table.insert(players, t)
		else
		    if package_known(self,"isEnemy",t) and package_known(t,"getHandcardNum") >= 1 and (not package_known(t,"hasSkill","kongcheng")) then
			    table.insert(players, t)
			end
		end
	end
	package_call(self,"sort",players, "defense")
	return players[1]
end

sgs.ai_skill_choice["nos_sgkgoddanjing"] = function(self, choices, data)
    local room = self.room
	local target
	for _, t in sgs.qlist(package_known(room,"getOtherPlayers",self.player)) do
	    if package_known(t,"getStrategyMark","danjing_AI") > 0 then
		    target = t
			break
		end
	end
	if package_known(self,"isFriend",target) then
	    return "drawthree"
	else
	    return "throwthree"
	end
end

sgs.ai_use_value["nos_sgkgoddanjingCard"] = 8
sgs.ai_use_priority["nos_sgkgoddanjingCard"] = 8



sgs.ai_skill_playerchosen.nos_sgkgodzhonghun = function(self, targets)
    local zhonghun = {}
	for _, _target in sgs.qlist(targets) do
	    if package_known(self,"isFriend",_target) then
		    table.insert(zhonghun, _target)
		end
	end
	if #zhonghun > 0 then
	    package_call(self,"sort",zhonghun, "threat")
		return zhonghun[1]
	end
end

sgs.ai_skill_invoke["nos_sgkgodzhonghun"] = function(self, data)
    return #self.friends_noself > 0
end

local jlsgyanlie_skill = {}
jlsgyanlie_skill.name = "jlsgyanlie"
table.insert(package_skills,jlsgyanlie_skill)
jlsgyanlie_skill.getTurnUseCard = function(self,inclusive,request)
	return source_skill(self,"#jlsgyanlieCard:.:")
end

sgs.ai_skill_use_func["#jlsgyanlieCard"] = function(card,use,self,request)
	package_call(self,"sort",self.enemies,"hp")
	local targets = {}
	local use_card = {}
	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
	package_call(self,"sortByKeepValue",cards)
	for _,c in ipairs(cards)do
		if not package_known(c,"isKindOf","Peach") and package_known(self.player,"canDiscard",self.player,package_known(c,"getEffectiveId")) and #use_card < #self.enemies then
			table.insert(use_card, package_known(c,"getEffectiveId"))
		end
	end
	if #use_card > 0 then
		local iron_chain = clone_native(self,"iron_chain", sgs.Card_NoSuit, 0)
		package_call(iron_chain,"setSkillName","jlsgyanlie")
		package_call(iron_chain,"deleteLater")
		local dummy_use = package_known(self,"aiUseCard",iron_chain, dummy(true, #use_card))
		if not package_known(dummy_use.to,"isEmpty") then
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets,p)
			end
		end
		if #targets==0 then return end
		if #use_card > 0 then
			if #targets < #use_card then
				for _,enemy in ipairs(self.enemies)do
					if not package_known(enemy,"isChained") and not package_known(enemy,"hasSkill","qianjie") and package_known(self,"isWeak",enemy) and package_known(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire) and not table.contains(targets, enemy) then
						table.insert(targets,enemy)
					end
				end
			end
			if #targets < #use_card then
				for _,enemy in ipairs(self.enemies)do
					if #targets>=#use_card then break end
					if package_known(self,"isWeak",enemy) and package_known(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire) and not table.contains(targets, enemy) then
						table.insert(targets,enemy)
					end
				end
			end
			if #targets < #use_card then
				for _,enemy in ipairs(self.enemies)do
					if #targets>=#use_card then break end
					if package_known(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire) and not package_known(self,"cantbeHurt",enemy) and not package_known(self,"needToLoseHp",enemy) and not table.contains(targets, enemy) then
						table.insert(targets,enemy)
					end
				end
			end
			if #targets < #use_card then
				for i = 1,#use_card - #targets,1 do
					table.removeOne(use_card, use_card[#use_card])
				end
			end
			use.card = source_skill(self,string.format("#jlsgyanlieCard:%s:", table.concat(use_card, "+")))
			for i = 1,#targets,1 do
				package_call(use.to,"append",targets[i])
				if package_known(use.to,"length") >= #use_card then
					break
				end
			end
			return
		end
	end
end

sgs.ai_use_priority.jlsgyanlieCard = 3
sgs.ai_use_value.jlsgyanlieCard = 2.35
sgs.ai_card_intention.jlsgyanlieCard = 20

sgs.ai_skill_playerchosen.jlsgyanlie = function(self,targets)
	local to = package_known(self,"findPlayerToDamage",1,self.player,"F",targets)[1]
	if to then return to end
	targets = sgs.QList2Table(targets)
	package_call(self,"sort",targets,"hp")
	for _,p in ipairs(targets)do do
		if not package_known(self,"isEnemy",p) or not package_known(self,"damageIsEffective",p,sgs.DamageStruct_Fire) then goto package_continue_2 end
		return p
	end ::package_continue_2:: end
	for _,p in ipairs(targets)do do
		if package_known(self,"isFriend",p) or not package_known(self,"damageIsEffective",p,sgs.DamageStruct_Fire) then goto package_continue_3 end
		return p
	end ::package_continue_3:: end
	return targets[math.random(1,#targets)]
end


sgs.ai_target_revises.jlsglianti = function(to,card,self,use)
    if package_known(card,"isKindOf","IronChain") then return true end
end


local jlsgguiyuan_skill = {}
jlsgguiyuan_skill.name = "jlsgguiyuan"
table.insert(package_skills, jlsgguiyuan_skill)
jlsgguiyuan_skill.getTurnUseCard = function(self,inclusive,request)
	if package_known(self.player,"hasUsed","#jlsgguiyuanCard") then return end
	return source_skill(self,"#jlsgguiyuanCard:.:")
end

sgs.ai_skill_use_func["#jlsgguiyuanCard"] = function(card,use,self,request)
    if not package_known(self.player,"hasUsed","#jlsgguiyuanCard") then
		local cansave = 1 - package_known(self.player,"getHp")
		local mark = package_known(self.player,"getStrategyMark","@jlsgchongsheng")
		if package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") + mark >= cansave then
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.jlsgguiyuanCard = 8.5
sgs.ai_use_priority.jlsgguiyuanCard = 9.5
sgs.ai_card_intention.jlsgguiyuanCard = -80


sgs.ai_skill_invoke.jlsgchongsheng = function(self, data)
	local dying = package_known(data,"toDying")
	if package_known(dying.who,"objectName") == package_known(self.player,"objectName") then
		local peaches = 1 - package_known(dying.who,"getHp")
		return package_known(self,"getCardsNum","Peach") + package_known(self,"getCardsNum","Analeptic") < peaches
	else
		if package_known(self.player,"getPile","jlsgyuanhua"):length() < 3 then return false end
		return package_known(self,"isFriend",dying.who)
	end
end

sgs.ai_skill_invoke["@jlsgchongsheng-generalChanged"] = true

sgs.ai_skill_choice["new_sgkgodluezhen"] = function(self, choices, data)
	if string.find(choices or "", "luezhen_getcard") then
		if data then
			local ok, damage = pcall(package_known, data, "toDamage")
			if ok and damage and damage.to then
				local ok2, refuse = pcall(function()
					return package_known(self,"isFriend",damage.to) and not package_known(self,"doDisCard",damage.to, "he", true)
				end)
				if ok2 and refuse then return "cancel" end
			end
		end
		return "luezhen_getcard"
	end
	if string.find(choices or "", "luezhen_endturn") then return "luezhen_endturn" end
end

--神周泰
sgs.ai_skill_playerchosen.sgkgodzhanhun = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self, "sort", targets, "hp")
	for _, p in ipairs(targets) do
		if package_known(self, "isEnemy", p) then return p end
	end
	return nil
end
sgs.ai_playerchosen_intention.sgkgodzhanhun = 120

--神祝融
local sgkgodyanfeng_skill = {}
sgkgodyanfeng_skill.name = "sgkgodyanfeng"
table.insert(package_skills, sgkgodyanfeng_skill)
sgkgodyanfeng_skill.getTurnUseCard = function(self, inclusive, request)
	if #self.enemies == 0 then return nil end
	local cards = sgs.QList2Table(package_known(self.player, "getCards", "he"))
	package_call(self, "sortByUseValue", cards, true)
	for _, c in ipairs(cards) do
		if package_known(c, "isKindOf", "Slash") and package_known(c, "isRed") then
			return conversion_clone(self, "fire_slash", "sgkgodyanfeng", package_known(c, "getSuit"), package_known(c, "getNumber"), {package_known(c, "getEffectiveId")})
		end
	end
	for _, c in ipairs(cards) do
		if package_known(c, "isRed") and not package_known(c, "isKindOf", "Peach") and not package_known(c, "isKindOf", "Analeptic") then
			return conversion_clone(self, "fire_slash", "sgkgodyanfeng", package_known(c, "getSuit"), package_known(c, "getNumber"), {package_known(c, "getEffectiveId")})
		end
	end
	return nil
end

sgs.ai_view_as["sgkgodyanfeng"] = function(card, player, card_place, class_name)
	if class_name ~= "FireSlash" then return nil end
	local self = actor_ai(player)
	local card_id = package_known(card, "getEffectiveId")
	return {name = "fire_slash", skill = "sgkgodyanfeng", suit = package_known(card, "getSuit"), number = package_known(card, "getNumber"), subcards = {card_id}}
end

sgs.ai_ajustdamage_from.sgkgodyanfeng = function(self, from, to, card, nature)
	if card and package_known(card, "isKindOf", "FireSlash") and package_known(card, "isRed") then
		return 1
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|sgkgodyanfeng"

local sgkgodshenji_skill = {}
sgkgodshenji_skill.name = "sgkgodshenji"
table.insert(package_skills, sgkgodshenji_skill)
sgkgodshenji_skill.getTurnUseCard = function(self, inclusive, request)
	if package_known(self.player, "getStrategyMark", "sgkgodshenji_firedmg") <= 0 then return nil end
	if package_known(self.player, "hasUsed", "sgkgodshenji") then return nil end
	if #self.enemies == 0 then return nil end
	return source_skill(self, "#sgkgodshenjiCard:.:")
end

sgs.ai_skill_use_func["#sgkgodshenjiCard"] = function(card, use, self, request)
	use.card = card
end
sgs.ai_use_value.sgkgodshenjiCard = 9
sgs.ai_use_priority.sgkgodshenjiCard = 8
sgs.ai_card_intention.sgkgodshenjiCard = 300

sgs.ai_skill_choice["sgkgodshenji"] = function(self, choices, data)
	local max_keep = package_known(self.player, "getMaxHp") - 1
	local n = math.max(1, math.min(#self.enemies, max_keep))
	return "shenji_num" .. n
end

sgs.ai_skill_playerchosen.sgkgodshenji = function(self, targets)
	targets = sgs.QList2Table(targets)
	package_call(self, "sort", targets, "hp")
	for _, p in ipairs(targets) do
		if package_known(self, "isEnemy", p) then return p end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.sgkgodshenji = 300

--神孙策
local sgkgodfuhai_skill = {}
sgkgodfuhai_skill.name = "sgkgodfuhai"
table.insert(package_skills, sgkgodfuhai_skill)
sgkgodfuhai_skill.getTurnUseCard = function(self, inclusive, request)
	if package_known(self.player, "getStrategyMark", "&charge_num") < 5 then return nil end
	if #self.enemies == 0 then return nil end
	return source_skill(self, "#sgkgodfuhaiCard:.:")
end

for _,skill in ipairs(package_skills)do local fn=skill.getTurnUseCard;sgs.ai_fill_skill[skill.name]=function(self,inclusive,request)local old=active_requests[self];active_requests[self]=request;local ok,v=pcall(fn,self,inclusive,request);active_requests[self]=old;if not ok then error(v,0)end;return finish_turn(self,v,request)end end
for selector in pairs(SELECTORS)do local fn=sgs.ai_skill_use_func[selector];if type(fn)=="function"then sgs.ai_skill_use_func[selector]=function(card,use,self,request)local old=active_requests[self];active_requests[self]=request;local r=table.pack(pcall(fn,card,use,self,request));active_requests[self]=old;if not r[1]then error(r[2],0)end;return table.unpack(r,2,r.n)end end end
sgs.ai_skill_choice.sgkgodqinyin=function(self)local value,known=package_call(self,"getStrategyMemory","hunlie.choice.qinyin");if not known then unsupported("choice.qinyin")end;return value end

--SP神貂蝉
sgs.ai_skill_invoke.sgkgodlihun = function(self, data)
	for _, p in sgs.qlist(package_known(self.room, "getOtherPlayers", self.player)) do
		if package_known(self, "isFriend", p) then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.sgkgodlihun = function(self, targets)
	local best, bestv
	for _, p in sgs.qlist(targets) do
		if package_known(self, "isFriend", p) then
			local v = package_known(p, "getHandcardNum") + package_known(p, "getHp")
			if not best or v > bestv then best, bestv = p, v end
		end
	end
	return best
end
sgs.ai_playerchosen_intention.sgkgodlihun = -80

--神孙策
sgs.ai_skill_invoke.sgkgodfenghe = function(self, data)
	local use = package_known(data, "toCardUse")
	if not use.card then return false end
	local candidates = {}
	if use.from then table.insert(candidates, use.from) end
	for _, t in sgs.qlist(use.to) do table.insert(candidates, t) end
	if #candidates == 0 then return false end
	local min_n = nil
	for _, t in ipairs(candidates) do
		local h = package_known(t, "getHandcardNum")
		if not min_n or h < min_n then min_n = h end
	end
	for _, t in ipairs(candidates) do
		if package_known(t, "getHandcardNum") == min_n and package_known(self, "isEnemy", t) then
			return false
		end
	end
	return true
end

sgs.ai_skill_use_func["#sgkgodfuhaiCard"] = function(card, use, self, request)
	local targets = {}
	for _, p in ipairs(self.enemies) do
		if not package_known(p, "isKongcheng") then table.insert(targets, p) end
	end
	if #targets == 0 then return nil end
	package_call(self, "sort", targets, "handcard")
	targets = sgs.reverse(targets)
	use.card = card
	if use.to then package_call(use.to, "append", targets[1]) end
	return
end
sgs.ai_use_value["sgkgodfuhaiCard"] = 9
sgs.ai_use_priority["sgkgodfuhaiCard"] = 9
sgs.ai_card_intention["sgkgodfuhaiCard"] = 300
