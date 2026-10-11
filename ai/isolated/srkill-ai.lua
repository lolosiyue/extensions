-- Fixed b6025acc source bodies; request-scoped readonly planning and selected payment.
local function known(v,k) if AIUnsupported.is(v) then error(v,0) end;if v==nil then ai_unsupported('srkill value is not observed',k) end;return v end
local function sget(o,k,...) if o==nil then error('attempt to index a nil value',0) end;if AIValue.isPlayer(o) then if k=='getMark' then k='getStrategyMark' elseif k=='hasFlag' then k='getStrategyFlag' end end;if type(o[k])~='function' then ai_unsupported('srkill method missing',k) end;return known(o[k](o,...),k) end
local function visible(self,id)
 local c=self:getKnownCardById(id);if not c and type(self.getChoiceCard)=='function'then c=self:getChoiceCard(id)end
 local ctx=self:getDecisionContext();local row=ctx.round26_choice;local face=row and row.ag_faces and row.ag_faces[tostring(id)];if not c and face then c=CardView.new(face)end;return known(c,'srkill disclosed physical card')
end
local function copy(t) local r={} for k,v in pairs(t)do r[k]=type(v)=='table' and copy(v) or v end;return r end
local function dummy_plan(v,extra,current) local u=AIUsePlan.new();u.isDummy=v~=false;u.extra_target=extra or 0;u.current_targets=current or {};return u end
local classes={['#sr_chouxicard']='sr_chouxi',['#sr_shoujicard']='sr_shouji',['#sr_yaozhancard']='sr_yaozhan',['#sr_wenjiucard']='sr_wenjiu',['#sr_sanfencard']='sr_sanfen',['#sr_quanhengCard']='sr_quanheng',['#sr_xionglvecard']='sr_xionglve',['#sr_dailaocard']='sr_dailao',['#sr_weibaocard']='sr_weibao',['#sr_choulvecard']='sr_choulve',['#sr_jiexicard']='sr_jiexi',['#sr_youxiacard']='sr_youxia',['#sr_zhouyancard']='sr_zhouyan',['#sr_zhaxiangcard']='sr_zhaxiang',['#sr_fangxincard']='sr_fangxin',['#sr_yinmengcard']='sr_yinmeng',['#sr_jueliecard']='sr_juelie',['#sr_zhishicard']='sr_zhishi',['#sr_aozhanCard']='sr_aozhan',['#sr_liuyuncard']='sr_liuyun',['#sr_qingchengcard']='sr_qingcheng',['#sr_xiahoucard']='sr_xiahou',['#sr_lijiancard']='sr_lijian',['#sr_manwucard']='sr_manwu',['#sr_xingyicard']='sr_xingyi',['#sr_jiwucard']='sr_jiwu',['#sr_quanheng_slashCard']='sr_quanheng_slash',['#sr_quanheng_ex_nihiloCard']='sr_quanheng_ex_nihilo',['#sr_shuixicard']='sr_shuixi',['#sr_fuzhengcard']='sr_fuzheng',['#sr_youdicard']='sr_youdi',['#jiwu_extarget']='jiwu_extarget'}
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
 if text==""then return nil end -- Card::Parse empty is nil; source assert remains ordinary.
 request=request or self._srkill_request
 local row=printed_spec(text)
 if row then local base=known(self:getEvaluationCard(row.name),'printed prototype');local c=self:evaluateTurnConversion(row.skill,base:getClassName(),row,request);recipes[c]=row;return c end
 local cl,sk,cs,u=decode(text);local c=self:evaluateTurnSkillCard(sk,cl,cs,request,u);recipes[c]={prototype=cl,skill=sk,subcards=cs,user=u};return c
end
local function clone(self,name,suit,number,skill)
 local spec={source_key=self._srkill_key or 'srkill',name=name or 'slash',skill=skill or '',suit=suit or sgs.Card_NoSuit,number=number or 0,subcards={}}
 local c;if spec.skill=='' and spec.suit==sgs.Card_NoSuit and spec.number==0 then c=self:getEvaluationCard(spec.name) else c=self:evaluateOwnerViewAsCard(spec) end
 if c then recipes[c]=spec end;return c
end
local function mutate(self,c,k,v)
 local spec=copy(known(recipes[c],'source readonly constructor'));if k=='add' then spec.subcards[#spec.subcards+1]=type(v)=='number' and v or sget(v,'getEffectiveId') else spec[k]=v end
 local n=self:evaluateOwnerViewAsCard(spec);self:inheritLegacyCardIdentity(n,c);recipes[n]=spec;return n
end
local function proposal(text)if type(text)~='string'or text=='.'then return text end;return printed_spec(text)or text end
local function response(self,text)
 if type(text)~='string'or text=='.'or text==''then return text end
 local wire,targets=text:match('^(.-)%->(.*)$');wire=wire or text
 if wire:match('^%d+$')then return{kind='use_card',card_ids={tonumber(wire)},targets=targets and targets:split('+')or{}}end
 local cl,sk,cs,u=decode(wire);local c=self:bindSkillCard(sk,cs,nil,u,cl)
 return{kind='use_card',card_spec=c:toCardSpec(),targets=targets and targets:split('+')or{}}
end
local function source_role(self,p)
 local role=p:getRole();if role~=nil and role~='unknown'and role~='neutral'then return role end
 role=self:getRoleEstimate(p);if role==nil or role=='neutral'or role=='unknown'then ai_unsupported('private role is not resolved for this viewer','srkill.role')end
 return self:useKnowledgeEstimate({value=role,status='estimate',basis='viewer_role_inference_replaces_private_role',viewer=self.player:objectName(),target=p:objectName()},'srkill.role')
end
local function observed_hand(self,p)
 if p:objectName()==self.player:objectName()then return known(p:getHandcards(),'owner hand')end
 -- These source loops themselves filter visible/visible_observer flags. No hidden face is inspected.
 return known(p:getKnownCards(),'observer disclosed hand')
end
local function can_to(self,c,from,to)if from:objectName()~=self.player:objectName()then ai_unsupported('foreign targetFilter is not an owner query','srkill')end;return self:cardTargetFilter(c,{},to)end
local function extra_targets(self,c)return known(self:getEvaluationCandidate(c):getExtraTargetCount(),'extra target modifier')end
local function same_player(a,b)return a and b and a:objectName()==b:objectName()end

local function selected_response(self,text)
 local spec=type(text)=='string'and printed_spec(text);if not spec then return text end
 local base=known(self:getEvaluationCard(spec.name),'selected printed response')
 local policy=known(self:getConversionPolicy(base:getClassName()),'selected response catalog');local source
 for _,row in ipairs(policy.skills or{})do if row.skill_name==spec.skill then source=row;break end end
 return known(self:resolveResponseConversion(spec,known(source,'exact selected response source')),'selected response receipt')
end

local function equip(self,p,slot) local c=p:getEquip(slot);return type(c)=='number'and visible(self,c)or c end
local function fact(self,key)return known(known(self:getDecisionContext().round26_choice,'srkill scoped context')[key],key)end
local function fact_player(self,key)local n=fact(self,key);return n~=false and known(self.room:findPlayerByObjectName(n,true),key)or nil end
local function remembered_player(self,key)local n,present=self:getStrategyMemory('srkill.'..key);if not present then return nil end;return n~=false and known(self.room:findPlayerByObjectName(n,true),key)or nil end
local function remembered_id(self,key)local n,present=self:getStrategyMemory('srkill.'..key);return present and n or 0 end
local function fact_use(self,key)
 local row=fact(self,key);local targets=AIList.new({})
 for _,name in ipairs(known(row.to,key..'.to'))do targets:append(known(self.room:findPlayerByObjectName(name,true),'use target'))end
 return{from=known(self.room:findPlayerByObjectName(row.from,true),'use source'),card=CardView.new(known(row.card,'use card')),to=targets}
end
sgs.ai_skill_choice["lose_a_sk"] = function(self, choices, data)
	local choices1 = choices:split("+")
	return choices1[math.random(1, #choices1)]
end

sgs.ai_skill_invoke.sr_rende = function(self,data)
	local current = self.room:getCurrent()
	return self:isFriend(current)
end
sgs.ai_choicemade_filter.skillInvoke.sr_rende = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if current then
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(player, current, -20)
		end
	end
end


sgs.ai_skill_askforyiji.sr_rende = function(self, card_ids)
	local current = self.room:getCurrent()
	if not current or not self:isFriend(current) or sget(current,"isDead") then
		return nil,-1
	end
	if self:isWeak(self.player) or self.player:isKongcheng() or
		self.player:objectName() == current:objectName() then
		return current,-1
	end
	local slash,peach = {},{}
	for _,id in ipairs(card_ids) do
		local card = visible(self,id)
		if sget(card,"isKindOf","Slash") then
			table.insert(slash,id)
		elseif sget(card,"isKindOf","Peach") or sget(card,"isKindOf","Analeptic") or sget(card,"isKindOf","Jink") then
			table.insert(peach,id)
		end
	end
	if #slash~= 0 then
		return current,slash[1]
	end
	if (self:isWeak(current) or sget(current,"getHp")<=2 )and #peach ~= 0 then
		return current,peach[1]
	end
	return current,-1
end
sgs.ai_fill_skill["sr_chouxi"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_chouxicard") or self.player:isKongcheng() or #self.enemies == 0 then
		return nil end
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	return policy(self,"#sr_chouxicard:"..cards[1]:getId()..":")
end

sgs.ai_skill_use_func["#sr_chouxicard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["sr_chouxicard"] = 8

sgs.ai_skill_playerchosen["sr_chouxi"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	enemies = self:sort(enemies,"defense")
	return enemies[1]
end
sgs.ai_playerchosen_intention.sr_chouxi = 10

sgs.ai_skill_cardask["@srchouxi-discard"] = function(self, data, pattern, target, target2)
	if self.player:isKongcheng() then return "." end
	local types = pattern:split("|")[1]:split(",")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByUseValue(cards)
	local cando = false
	local todiscard = {}
	for _, card in ipairs(cards) do
		if not self:isValuableCard(card) then
			for _, classname in ipairs(types) do
				if sget(card,"isKindOf",classname) then
					table.insert(todiscard,card)
				end
			end
		end
	end
	if #todiscard > 0 then cando = true end
	local tag = fact(self,"agcards")
	for _,id in ipairs(tag) do
		local cd = visible(self,tonumber(id))
		if sget(cd,"isKindOf","Peach") or sget(cd,"isKindOf","ExNihilo") and not self:isWeak() then
			cando = false
			break
		end
	end

	if cando then
		return "$"..sget(todiscard[1],"getEffectiveId")
	else
		return "."
	end
end
sgs.ai_skill_playerchosen["sr_yongbing"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end
	end
	if #friends == 0 then return nil end
	friends = self:sort(friends,"defense")
	return friends[1]
end
sgs.ai_playerchosen_intention.sr_yongbing = -50
sgs.ai_fill_skill["sr_shouji"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_shoujicard") then return nil end
	if self.player:isKongcheng() then return nil end
	if #self.enemies==0 and #self.friends == 0 then return nil end
	return policy(self,"#sr_shoujicard:.:")
end

sgs.ai_skill_use_func["#sr_shoujicard"] = function(card, use, self)
	self.friends = self:sort(self.friends,"defense",false)
	self.enemies = self:sort(self.enemies,"defense")
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByUseValue(cards)
	local card = cards[1]
	if sget(card,"getSuit") == sgs.Card_Spade then
		local duel = clone(self,"duel",sgs.Card_NoSuit,0)
		do end
		for _,p in ipairs(self.friends) do
			for _,q in ipairs(self.enemies) do
				if not p:isProhibited(q, duel) then
					use.card = policy(self,"#sr_shoujicard:"..sget(card,"getEffectiveId")..":")
					if use.card and use.to then
						use.to:append(p)
						use.to:append(q)
					end
					return
				end
			end
		end
	elseif sget(card,"getSuit") == sgs.Card_Heart then
		local snatch = clone(self,"snatch",sgs.Card_NoSuit,0)
		do end
		for _,p in ipairs(self.friends) do
			for _,q in ipairs(self.enemies) do
				if not p:isProhibited(q, snatch) and sget(p,"distanceTo",q) == 1 and not q:isAllNude() then
					use.card = policy(self,"#sr_shoujicard:"..sget(card,"getEffectiveId")..":")
					if use.card and use.to then
						use.to:append(p)
						use.to:append(q)
					end
					return
				end
			end
		end
	elseif sget(card,"getSuit") == sgs.Card_Club then
		local co = clone(self,"collateral",sgs.Card_NoSuit,0)
		do end
		for _,p in ipairs(self.friends) do
			for _,q in ipairs(self.enemies) do
				if not p:isProhibited(q, co) and q:getWeapon() ~=nil then
					use.card = policy(self,"#sr_shoujicard:"..sget(card,"getEffectiveId")..":")
					if use.card and use.to then
						use.to:append(p)
						use.to:append(q)
					end
					return
				end
			end
		end
	elseif sget(card,"getSuit") == sgs.Card_Diamond then
		local fireattact = clone(self,"fire_attack",sgs.Card_NoSuit,0)
		do end
		for _,p in ipairs(self.friends) do
			for _,q in ipairs(self.enemies) do
				if not p:isProhibited(q, fireattact) and not q:isKongcheng() and not p:isKongcheng() and
					not (p:objectName() == self.player:objectName() and sget(self.player,"getHandcardNum") ==1) then
					use.card = policy(self,"#sr_shoujicard:"..sget(card,"getEffectiveId")..":")
					if use.card and use.to then
						use.to:append(p)
						use.to:append(q)
					end
					return
				end
			end
		end
	end
	return
end

sgs.ai_use_value["sr_shoujicard"] = 2.3

sgs.ai_skill_playerchosen["sr_shouji"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	enemies = self:sort(enemies,"defense")
	return enemies[1]
end

sgs.ai_skill_cardask["@sr_hemou"] = function(self, data, pattern, target, target2)
	local current = self.room:getCurrent()
	if not current or not self:isFriend(current) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	return "$"..sget(cards[1],"getEffectiveId")
end
sgs.ai_choicemade_filter.cardResponded["@sr_hemou"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		self:updateIntention(player, current, -50)
	end
end

sgs.ai_fill_skill["sr_hemouvs"] = function(self,inclusive,request)
	local n = sget(self.player,"getMark","hemousuit")
	if n<=0 then return nil end
	local cards = {}
	for _,p in sgs.qlist(self.player:getHandcards()) do
		if sget(p,"getSuit") == n-1 then
			table.insert(cards,p)
		end
	end
	if #cards == 0 then return nil end
	cards = self:sortByKeepValue(cards)
	local suit = sget(cards[1],"getSuitString")
	local number = cards[1]:getNumberString()
	local card_id = sget(cards[1],"getEffectiveId")
	local card_str = ""
	if n == 1 then
		card_str = ("duel:sr_hemouvs[%s:%s]=%d"):format(suit, number, card_id)
	elseif n == 2 then
		card_str = ("collateral:sr_hemouvs[%s:%s]=%d"):format(suit, number, card_id)
	elseif n == 3 then
		card_str = ("snatch:sr_hemouvs[%s:%s]=%d"):format(suit, number, card_id)
	elseif n == 4 then
		card_str = ("fire_attack:sr_hemouvs[%s:%s]=%d"):format(suit, number, card_id)
	end
	local hemoucard = policy(self,card_str)

	assert(hemoucard)

	return hemoucard
end

sgs.ai_skill_cardask["@srbenxi-discard"] = function(self, data, pattern, target, target2)
	if self.player:isKongcheng() then return "." end
	local use = data:toCardUse()
	local card = use.card
	local hasjink ,equip= false,{}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if sget(c,"isKindOf","EquipCard")  and not (equip(self,self.player,1) and
			equip(self,self.player,1):objectName() ==c:objectName()
			and not sget(c,"isKindOf","SilverLion")) then
			table.insert(equip,c)
		end
	end
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if sget(c,"isKindOf","Jink") then
			hasjink = true
			break
		end
		if not use.from:hasWeapon("QinggangSword") and sget(self.player,"getMark","Armor_Nullified") ==0 then
			if equip(self,self.player,1) then
				if equip(self,self.player,1):isKindOf("EightDiagram") then
					hasjink = true
					break
				end
				if equip(self,self.player,1):isKindOf("RenwangShield") and card:isBlack()
					and sget(card,"isKindOf","Slash") then
					hasjink = true
					break
				end
				if equip(self,self.player,1):isKindOf("Vine") and sget(card,"isKindOf","NormalSlash") then
					hasjink = true
					break
				end
			end
		end
	end
	if #equip == 0 or not hasjink then return "." end
	if self:needToLoseHp(self.player, use.from, use.card) then return "." end
	equip = self:sortByKeepValue(equip)
	return "$"..sget(equip[1],"getEffectiveId")
end
sgs.hit_skill = sgs.hit_skill .. "|sr_benxi"
sgs.ai_cardneed.sr_benxi = sgs.ai_cardneed.slash
sgs.ai_fill_skill["sr_yaozhan"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_yaozhancard") then return nil end
	if self.player:isKongcheng() then return nil end
	if #self.enemies==0 then return nil end
	local cando = false
	for _,p in ipairs(self.enemies) do
		if not p:isKongcheng() and sget(p,"getHandcardNum") <=3 and sget(self.player,"canPindian",p) then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return policy(self,"#sr_yaozhancard:.:")
end

sgs.ai_skill_use_func["#sr_yaozhancard"] = function(card, use, self)
	local maxcard = self.player:getHandcards():first()
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if sget(c,"getNumber") > sget(maxcard,"getNumber") then
			maxcard =c
		end
	end
	if sget(maxcard,"getNumber") <=6 then return end
	local enemies = {}
	local slash = clone(self,"slash")
	slash = mutate(self,slash,"skill","_sr_yaozhan")
	do end
	for _,p in ipairs(self.enemies) do
		if not p:isKongcheng() and sget(p,"getHandcardNum") <=3 and sget(self.player,"canPindian",p) and not self:slashProhibit(slash, p) and self:isGoodTarget(p, self.enemies, slash) and self:slashIsEffective(slash, p) then
			table.insert(enemies,p)
		end
	end
	enemies = self:sort(enemies,"defense")
	use.card = policy(self,"#sr_yaozhancard:"..sget(maxcard,"getEffectiveId")..":")
	if use.card and use.to then
		use.to:append(enemies[1])
	end
end
sgs.ai_use_priority["sr_yaozhancard"] =sgs.ai_use_priority.Slash - 0.1

sgs.ai_cardneed.sr_yaozhan = sgs.ai_cardneed.bignumber
sgs.ai_cardneed.sr_wenjiu = sgs.ai_cardneed.slash
sgs.ai_fill_skill["sr_wenjiu"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_wenjiucard") then return nil end
	if self.player:isKongcheng() then return nil end
	if self.player:getPile("@srjiu"):length() >=2 and sget(self.player,"getHandcardNum") <= sget(self.player,"getHp")  then
		return nil end
	local black = {}
	for _,p in sgs.qlist(self.player:getHandcards()) do
		if p:isBlack() then
			table.insert(black,p)
		end
	end
	if #black == 0 then return nil end
	black = self:sortByUseValue(black)
	return policy(self,"#sr_wenjiucard:"..sget(black[1],"getEffectiveId")..":")
end

sgs.ai_skill_use_func["#sr_wenjiucard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["sr_wenjiucard"] = 7
sgs.ai_use_priority["sr_wenjiucard"] = 3.5

sgs.ai_skill_invoke["sr_wenjiu"] = function(self,data)
	local use = data:toCardUse()
	for _,p in ipairs(self.friends) do
		if use.to:contains(p) then
			return false
		end
	end
	return true
end
sgs.ai_ajustdamage_from.sr_wenjiu = function(self, from, to, card, nature)
	if (card and (sget(card,"isKindOf","Slash") )) and sget(from,"getMark","wenjiuslash") > 0
	then
		return 1
	end
end


sgs.ai_skill_use["@@sr_shuixi"] = function(self, prompt)
	if self.player:isKongcheng() then return "." end
	local enemy = nil
	self.enemies = self:sort(self.enemies,"defense")
	for _,p in ipairs(self.enemies) do
		if not p:isKongcheng() then
			enemy = p
			break
		end
	end
	if not enemy then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	return "#sr_shuixicard:"..sget(cards[1],"getEffectiveId")..":->"..enemy:objectName()
end

sgs.ai_skill_cardask["@srshuixithrow"] = function(self, data, pattern, target, target2)
	local card = {}
	local suit = data:toString()
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if sget(c,"getSuitString") == suit then
			table.insert(card,c)
		end
	end
	if #card == 0 then return "." end
	local current = self.room:getCurrent()
	if current and self:isEnemy(current) then
		card = self:sortByKeepValue(card)
		return "$"..sget(card[1],"getEffectiveId")
	end
	return "."
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|sr_shuixi"
sgs.ai_card_intention["sr_shuixicard"] = 70

sgs.ai_fill_skill["sr_sanfen"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_sanfencard") then return nil end
	if #self.enemies==0 then return nil end
	return policy(self,"#sr_sanfencard:.:")
end

sgs.ai_skill_use_func["#sr_sanfencard"] = function(card, use, self)
	self.friends = self:sort(self.friends,"defense",false)
	self.enemies = self:sort(self.enemies,"defense")
	for _,p in ipairs(self.enemies) do
		for _,q in ipairs(self.enemies) do
			if q:objectName() ~=p:objectName() and not q:isNude() and not p:isNude() and p:canSlash(q,false)
				and q:canSlash(self.player,false) then
				use.card = policy(self,"#sr_sanfencard:.:")
				if use.card and use.to then
					use.to:append(p)
					use.to:append(q)
				end
				return
			end
		end
	end
	local allplayers = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	allplayers = self:sort(allplayers,"defense",false)
	for _,p in ipairs(allplayers) do
		for _,q in ipairs(self.enemies) do
			if q:objectName() ~=p:objectName() and not q:isKongcheng() and not p:isKongcheng()
				and p:canSlash(q,false)
				and q:canSlash(self.player,false) then
				use.card = policy(self,"#sr_sanfencard:.:")
				if use.card and use.to then
					use.to:append(p)
					use.to:append(q)
				end
				return
			end
		end
	end
	return
end


sgs.ai_ajustdamage_to.sr_weiwo = function(self, from, to, card, nature)
	if (nature ~= "N" and not to:isKongcheng()) or (nature == "N" and to:isKongcheng())
	then
		return -99
	end
end

sgs.ai_skill_invoke["sr_xujin"] = function(self,data)
	return sget(self.player,"getHandcardNum") >= 2
end
sgs.ai_skill_playerchosen["sr_xujin"] = function(self, targets)
	return self.player
end
sgs.ai_cardneed.sr_xujin = sgs.ai_cardneed.slash
sgs.ai_skill_invoke["sr_paoxiao"] = function(self,data)
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if sget(c,"isKindOf","Slash") then
			return true
		end
	end
	return sget(self.player,"getHandcardNum") >=2
end
sgs.ai_cardneed.sr_paoxiao = sgs.ai_cardneed.slash
sgs.double_slash_skill = sgs.double_slash_skill .. "|sr_paoxiao"
sgs.ai_skill_cardask["@sr_jiuzhu"] = function(self, data, pattern, target, target2)
	if self.player:isNude() then return "." end
	local suit = data:toString()
	local candis = {}
	local current = self.room:getCurrent()
	for _,p in sgs.qlist(self.player:getCards("he")) do
		if not sget(p,"isKindOf","Jink") then
			table.insert(candis,p)
		end
	end
	if  #candis == 0 then return "." end
	local slash = clone(self,"slash",sgs.Card_NoSuit,0)
	do end
	if not current or self:isFriend(current) or self.player:isProhibited(current,slash) then
		for _,p in sgs.qlist(self.player:getCards("he")) do
			if sget(p,"isKindOf","Jink") then
				return "."
			end
		end
	end
	candis = self:sortByKeepValue(candis)
	return "$"..sget(candis[1],"getEffectiveId")
end

sgs.ai_skill_invoke["sr_jiuzhu"] = function(self,data)
	local current = self.room:getCurrent()
	local slash = clone(self,"slash",sgs.Card_NoSuit,0)
	slash = mutate(self,slash,"skill","_sr_jiuzhu")
	do end
	return current and self:isEnemy(current) and not self:slashProhibit(slash, current) and self:slashIsEffective(slash, current) and self:isGoodTarget(current, self.enemies, slash)
end

local function hasOnlySilverLionEffect(self,p)
	if not p or not p:isAlive() or not sget(p,"isWounded") then return false end
	if not p:isKongcheng() then return false end
	if not equip(self,p,1) or equip(self,p,0) or equip(self,p,2) or equip(self,p,3) then return false end
	return equip(self,p,1):isKindOf("SilverLion")
end
local function hasSilverLionEffect(self,p)
	if not sget(p,"isWounded") then return false end
	if not equip(self,p,1) then return false end
	return equip(self,p,1):isKindOf("SilverLion")
end

sgs.ai_skill_cardask["@sr_tuwei"] = function(self, data, pattern, target, target2)
	local tos = data:toString():split("+")
	local cando = false
	for _,to in ipairs(tos) do
		local p = self.room:findPlayerByObjectName(to)
		if self:isEnemy(p) and not p:isNude() and not hasOnlySilverLionEffect(self,p) and
			self.player:canDiscard(p,"he") then
			cando = true
			break
		end
		if self:isFriend(p) and hasOnlySilverLionEffect(self,p) and self.player:canDiscard(p,"he") then
			cando = true
			break
		end
	end
	if not cando then return "." end
	local pattern = "Slash,FireAttack,Duel,SavageAssault,ArcheryAttack,Drowning"
	local candis = {}
	for _, pat in ipairs(pattern:split(",")) do
		for _,c in sgs.qlist(self.player:getCards("he")) do
			if sget(c,"isKindOf",pat) then
				table.insert(candis,c)
			end
		end
	end
	if #candis == 0 then return "." end
	candis = self:sortByKeepValue(candis)
	return "$"..sget(candis[1],"getEffectiveId")
end



local function hasNoJinkEffect(who)
	return sget(who,"hasSkill","wushuang") or sget(who,"hasSkill","sy_wushuang") or sget(who,"hasSkill","sy_shisha") or sget(who,"hasSkill","sr_benxi") or sget(who,"hasSkill","liegong")
	or sget(who,"hasSkill","ol_liegong") or sget(who,"hasSkill","tieqi")
end
sgs.ai_fill_skill["sr_quanheng"] = function(self,inclusive,request)
	if self.player:isKongcheng() then return nil end
	if sget(self.player,"hasFlag","quanheng_used") then return nil end
	return policy(self,"#sr_quanhengCard:.:")
end

sgs.ai_skill_use_func["#sr_quanhengCard"] = function(card, use, self)
	local E = 0
	for _, enemy in ipairs(self.enemies) do
		if sget(self.player,"inMyAttackRange",enemy) then E = E + 1 end
	end
	if E == 0 or #self.enemies == 0 or self:isWeak() then
		self:setPriorityValue("sr_quanhengCard",sgs.ai_use_priority.ExNihilo,"srkill")
	else
		self:setPriorityValue("sr_quanhengCard",sgs.ai_use_priority.Slash,"srkill")
	end
	use.card = card
end

sgs.ai_skill_use["@@sr_quanheng_slash"] = function(self, prompt)
	local need_ids = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	if not hasNoJinkEffect(self.player) then
		for _, c in ipairs(cards) do
			if not sget(c,"isKindOf","Peach") then table.insert(need_ids, sget(c,"getEffectiveId")) end
			if #need_ids == math.min(2, #cards) then break end
		end
	else
		for _, c in ipairs(cards) do
			if not sget(c,"isKindOf","Peach") then table.insert(need_ids, sget(c,"getEffectiveId")) end
			if #need_ids == 1 then break end
		end
	end
	local quanheng_slash = clone(self,"slash")
	quanheng_slash = mutate(self,quanheng_slash,"skill","sr_quanheng")
	do end
	local dummy_use = self:aiUseCard(quanheng_slash, dummy_plan())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		targets = self:sort(targets, "defense")
		return "#sr_quanheng_slashCard:" .. table.concat(need_ids, "+") .. ":->" .. table.concat(targets, "+")
	end
end

sgs.ai_skill_use["@@sr_quanheng_ex_nihilo"] = function(self, prompt)
	local need_ids = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	if #self.enemies > 0 then
		for _, c in ipairs(cards) do
			if not sget(c,"isKindOf","Peach") then table.insert(need_ids, sget(c,"getEffectiveId")) end
			if #need_ids == math.min(2, #cards) then break end
		end
	else
		for _, c in ipairs(cards) do
			if not sget(c,"isKindOf","Peach") then table.insert(need_ids, sget(c,"getEffectiveId")) end
			if #need_ids == 1 then break end
		end
	end
	if #need_ids > 0 then
		return string.format("#sr_quanheng_ex_nihiloCard:%s:", table.concat(need_ids, "+"))
	else
		return nil
	end
end

sgs.ai_skill_choice["sr_quanheng"] = function(self, choices, data)
	if #self.enemies == 0 or self:isWeak() then return "quanheng_vs_exnihilo" end
	local E = 0
	for _, enemy in ipairs(self.enemies) do
		if sget(self.player,"inMyAttackRange",enemy) then E = E + 1 end
	end
	if E == 0 then return "quanheng_vs_exnihilo" end
	local quanheng = choices:split("+")
	return quanheng[math.random(1, #quanheng)]
end

sgs.ai_use_value["sr_quanhengCard"] = 4


sgs.ai_fill_skill["sr_xionglve"] = function(self,inclusive,request)
	if self.player:getPile("@srlve"):isEmpty() then return nil end
	if sget(self.player,"hasFlag","xionglveused") then return nil end
	if #self.enemies == 0 and #self.friends_noself == 0 then return nil end
	local Analeptic = clone(self,"analeptic",sgs.Card_NoSuit,0)
	if not sget(self.player,"isWounded") and not fact(self,"slash_available") and
		not sget(Analeptic,"isAvailable",self.player) then
		return nil
	end
	return policy(self,"#sr_xionglvecard:.:")
end

sgs.ai_skill_use_func["#sr_xionglvecard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["sr_xionglvecard"] = sgs.ai_use_value.Analeptic

local function shouldUseSlash(player,enemies)
	for _,p in ipairs(enemies) do
		if player:canSlash(p,true) then
			return true
		end
	end
	return false
end

sgs.ai_skill_askforag["sr_xionglvecard"] = function(self,card_ids)
	if sget(self.player,"isWounded") or fact(self,"slash_available") and
		shouldUseSlash(self.player,self.enemies) then
		for _,id in ipairs(card_ids) do
			local card = visible(self,id)
			if sget(card,"isKindOf","BasicCard") then
				return id
			end
		end
	else
	 	for _,id in ipairs(card_ids) do
			local card = visible(self,id)
			if sget(card,"isKindOf","TrickCard") then
				return id
			end
		end
		for _,id in ipairs(card_ids) do
			local card = visible(self,id)
			if sget(card,"isKindOf","EquipCard") then
				return id
			end
		end
	end
end

sgs.ai_skill_choice["sr_xionglvebasic"] = function(self, choices, data)
	if sget(self.player,"isWounded") then return "srcanpeach" end
	if fact(self,"slash_available") then
		if shouldUseSlash(self.player,self.enemies) then
			local Analeptic = clone(self,"analeptic",sgs.Card_NoSuit,0)
			if self:getCardsNum("Slash") > 0 and sget(Analeptic,"isAvailable",self.player) then
				return "srcananaleptic"
			else
				return "srcanslash"
			end
		else
			self:recordSrkillChoiceFlag("xionglveused",self.player,true)
			return "cancel"
		end
	end
	self:recordSrkillChoiceFlag("xionglveused",self.player,true)
	return "cancel"
end
sgs.ai_skill_playerchosen["sr_xionglveslash"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	enemies = self:sort(enemies,"defense")
	return enemies[1]
end


sgs.ai_skill_choice["sr_xionglvetrick"] = function(self,choices,data)
	local f,e = 0,0
	for _,p in sgs.qlist(self.room:getAllPlayers()) do
		if self:isFriend(p) then
			if self:isWeak(p) then
				f = f+1
			else
				if p:getJudgingArea():length()>0 then
					if sget(self.player,"distanceTo",p) == 1 then
						return "srcanshunshou"
					else
						return "srcanguohe"
					end
				end
			end
		else
			if self:isWeak(p) then
				e = e + 1
			end
		end
	end
	if f>e and f >=2 then return "srcantaoyuan" end
	if sget(self.player,"getHandcardNum") < sget(self.player,"getHp") then return "srcanwuzhong" end
	for _,p in ipairs(self.friends) do
		if p:isChained() then
			return "srcantiesuo"
		end
	end
	local canaoe = true
	for _,p in ipairs(self.friends) do
		if self:isWeak(p) then
			canaoe = false
			break
		end

	end
	if canaoe then
		if source_role(self,self.player) == "rebel" then
			return "srcanwanjian"
		else
			return "srcannanman"
		end
	end

	for _,p in ipairs(self.enemies) do
		local duel = clone(self,"duel",sgs.Card_NoSuit,0)
		if sget(p,"getHandcardNum")<=1 and not self.player:isProhibited(p,duel) then
			return "srcanjuedou"
		end
		if not p:isKongcheng() and sget(self.player,"getHandcardNum") >=3 then
			return "srcanhuogong"
		end
		if equip(self,p,0) then
			for _,q in ipairs(self.enemies) do
				if p:canSlash(q,true) and p:objectName() ~= q:objectName() then
					return "srcanjiedao"
				end
			end
		end
	end
	return choices[math.random(1, #choices)]
end

sgs.ai_skill_playerchosen["sr_xionglvetiesuo"] = function(self, targets)
	local friends = {}
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:isChained() then
			table.insert(friends,p)
		end
		if self:isEnemy(p) and not p:isChained() then
			table.insert(enemies,p)
		end
	end
	if #friends == 0 and #enemies == 0 then return nil end
	if #friends == 0 then return enemies[1] end
	return friends[1]
end

sgs.ai_skill_playerchosen["sr_xionglvejiedao"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	enemies = self:sort(enemies,"defense")
	return enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglvejiedao1"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	enemies = self:sort(enemies,"defense")
	return enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglvehuogong"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
			if equip(self,p,1) and equip(self,p,1):isKindOf("Vine") then return p end
		end
	end
	if #enemies == 0 then return nil end
	enemies = self:sort(enemies,"defense")
	return enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglveshunshou"] = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and (p:getJudgingArea():length()>0 or hasOnlySilverLionEffect(self,p))then
			return p
		end
		if self:isEnemy(p) and not hasOnlySilverLionEffect(self,p) then
			return p
		end
	end
	self.enemies = self:sort(self.enemies,"defense")
	return self.enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglveguohe"] = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and (p:getJudgingArea():length()>0 or hasOnlySilverLionEffect(self,p))then
			return p
		end
		if self:isEnemy(p) and not hasOnlySilverLionEffect(self,p) then
			return p
		end
	end
	self.enemies = self:sort(self.enemies,"defense")
	return self.enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglvejuedou"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	enemies = self:sort(enemies,"defense")
	return enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglveequip"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end
	end
	if #friends == 0 then return nil end
	self.friends = self:sort(self.friends,"defense")
	return friends[1]
end

sgs.ai_skill_invoke["sr_xionglve"] = function(self,data)
	return self.player:getPile("@srlve"):length()<=3 and not self.player:isKongcheng()
end

sgs.ai_skill_askforag["sr_xionglve"] =function(self, card_ids)
	local card1 = visible(self,card_ids[1])
	if sget(self.player,"isWounded") then
		if sget(card1,"isKindOf","BasicCard") then
			return card_ids[2]
		else
			return card_ids[1]
		end
	else
		if sget(card1,"isKindOf","TrickCard") then
			return card_ids[2]
		else
			return card_ids[1]
		end
	end
end
sgs.ai_skill_use["@@sr_fuzheng"] = function(self, prompt)
	self.friends_noself = self:sort(self.friends_noself,"defense")
	local first,second = nil,nil
	for _,p in ipairs(self.friends_noself) do
		if not p:isKongcheng() and sget(p,"getKingdom") == "wu" then
			if not first then
				first = p
			else
				second = p
				break
			end
		end
	end
	if not first and not second then return "." end
	if not second then
		return "#sr_fuzhengcard:.:->"..first:objectName()
	else
		return "#sr_fuzhengcard:.:->"..first:objectName().."+"..second:objectName()
	end
end

local function suitCards(player,suits,include_equip)--返回角色的某种花色的所有牌，不同花色用逗号相隔
	local hearts = {}
	local flag = "h"
	if include_equip then
		flag = flag.."e"
	end
	for _,c in sgs.qlist(player:getCards(flag)) do
		for _,suit in ipairs(suits:split(",")) do
			if sget(c,"getSuitString") == suit then
				table.insert(hearts,c)
			end
		end
	end
	return hearts
end

local function reverse(tables)
	local new_table = {}
	for i = #tables,1,-1 do
		table.insert(new_table,tables[i])
	end
end

sgs.ai_skill_discard["sr_fuzheng1"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		local delay = sgs.QList2Table(current:getJudgingArea())
		reverse(delay)
		if #delay>0 then
			if fact(self,"fuzheng_num") == 2 then
				table.removeOne(delay,delay[1])
			end
			for _, c in ipairs(delay) do
				if sget(c,"isKindOf","Indulgence") then
					local cards = suitCards(self.player,"heart",false)
					if #cards > 0 then
						cards = self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				elseif sget(c,"isKindOf","SupplyShortage") then
					local cards = suitCards(self.player,"club",false)
					if #cards > 0 then
						cards = self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				elseif sget(c,"isKindOf","Lightning") then
					for _,c in sgs.qlist(self.player:getHandcards()) do
						local cards ={}
						if not (sget(c,"getNumber")>=2 and sget(c,"getNumber")<=9 and sget(c,"getSuit") == sgs.Card_Spade) then
							table.insert(cards,c)
						end
					end
					if #cards > 0 then
						cards = self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				end
			end
		end
		if self:isWeak(current) then
			for _,c in sgs.qlist(self.player:getHandcards()) do
				if sget(c,"isKindOf","Peach") then
					table.insert(to_discard,c:getId())
					return to_discard
				end
			end
		end
		local handcards = sgs.QList2Table(self.player:getHandcards())
		handcards = self:sortByKeepValue(handcards)
		table.insert(to_discard,handcards[1]:getId())
		return to_discard
	end
	local handcards = sgs.QList2Table(self.player:getHandcards())
	handcards = self:sortByKeepValue(handcards)
	table.insert(to_discard,handcards[1]:getId())
	return to_discard
end

sgs.ai_skill_discard["sr_fuzheng2"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		local delay = sgs.QList2Table(current:getJudgingArea())
		reverse(delay)
		if #delay>0 then
			for _, c in ipairs(delay) do
				if sget(c,"isKindOf","Indulgence") then
					local cards = suitCards(self.player,"heart",false)
					if #cards > 0 then
						cards = self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				elseif sget(c,"isKindOf","SupplyShortage") then
					local cards = suitCards(self.player,"club",false)
					if #cards > 0 then
						cards = self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				elseif sget(c,"isKindOf","Lightning") then
					for _,c in sgs.qlist(self.player:getHandcards()) do
						local cards ={}
						if not (sget(c,"getNumber")>=2 and sget(c,"getNumber")<=9 and sget(c,"getSuit") == sgs.Card_Spade) then
							table.insert(cards,c)
						end
					end
					if #cards > 0 then
						cards = self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				end
			end
		end
		if self:isWeak(current) then
			for _,c in sgs.qlist(self.player:getHandcards()) do
				if sget(c,"isKindOf","Peach") then
					table.insert(to_discard,c:getId())
					return to_discard
				end
			end
		end
	end
	local handcards = sgs.QList2Table(self.player:getHandcards())
	handcards = self:sortByKeepValue(handcards)
	table.insert(to_discard,handcards[1]:getId())
	return to_discard
end


sgs.ai_fill_skill["sr_dailao"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_dailaocard") then return nil end
	local cando = false
	for _,p in sgs.qlist(self.room:getAllPlayers()) do
		if sget(p,"faceUp") and self:isEnemy(p) then
			cando = true
			break
		elseif not sget(p,"faceUp") and self:isFriend(p) then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return policy(self,"#sr_dailaocard:.:")
end

sgs.ai_skill_use_func["#sr_dailaocard"] = function(card, use, self)
	for _,p in ipairs(self.friends_noself) do
		if not sget(p,"faceUp") then
			use.card = card
			if use.card and use.to then
				use.to:append(p)
				return
			end
		end
	end
	for _,p in ipairs(self.enemies) do
		if sget(p,"faceUp") then
			use.card = card
			if use.card and use.to then
				use.to:append(p)
				return
			end
		end
	end
	return
end

sgs.ai_skill_choice["sr_dailao"] = function(self,choices,data)
	local per=fact_player(self,"dailao_target")
 if per then self:recordSrkillChoiceFlag("dailao_target",per,false)end
	if self:isFriend(per) then
		if hasSilverLionEffect(self,per) then
			return "srdiscard"
		else
			return "srdraw"
		end
	else
		if hasSilverLionEffect(self,per) then
			return "srdraw"
		else
			return "srdiscard"
		end
	end
end

sgs.ai_skill_invoke["sr_youdi"] = function(self,data)
	return true
end
sgs.ai_skill_use["@@sr_youdi"] = function(self, prompt)
	if self.player:isKongcheng() then return "." end
	local per=fact_player(self,"youdisource")
	if self:isFriend(per) and not hasSilverLionEffect(self,per) then return "." end
	if self:isEnemy(per) and hasSilverLionEffect(self,per) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	if self:isFriend(per) then
		return "#sr_youdicard:"..sget(cards[1],"getEffectiveId")..":"
	else
		local num = sget(per,"getHandcardNum")
		local discard = {}
		if num >= #cards then
			for _,c in sgs.qlist(self.player:getHandcards()) do
				table.insert(discard,sget(c,"getEffectiveId"))
			end
		else
			for i = 1,num,1 do
				table.insert(discard,cards[i]:getEffectiveId())
			end
		end
		return "#sr_youdicard:"..table.concat(discard,"+")..":"
	end
	return "."
end
sgs.ai_skill_invoke["sr_ruya"] = function(self,data)
	if sget(self.player,"hasSkill","sr_youdi") then return true end
	if self:isWeak() then return true end
	if sget(self.player,"getPhase") == sgs.Player_Play and sget(self.player,"hasSkill","sr_dailao")
		and not self.player:hasUsed("#sr_dailaocard") then return true end
	return false
end

local function sortHandcards(self,typename,smallToBig)
	local cards = sgs.QList2Table(self.player:getHandcards())
	if smallToBig then
		if typename == "keep" then
			cards = self:sortByKeepValue(cards)
		elseif typename == "use" then
			cards = self:sortByUseValue(cards)
		elseif typename == "number" then
			local final = {}
			while #final < sget(self.player,"getHandcardNum") do
				local min = cards[1]
				for _,c in ipairs(cards) do
					if sget(c,"getNumber") < sget(min,"getNumber") then
						min = c
					end
				end
				table.insert(final,min)
				table.removeOne(cards,min)
			end
			return final
		end
	else
		if typename == "keep" then
			cards = self:sortByKeepValue(cards,false)
		elseif typename == "use" then
			cards = self:sortByUseValue(cards,false)
		elseif typename == "number" then
			local final = {}
			while #final < sget(self.player,"getHandcardNum") do
				local max = cards[1]
				for _,c in ipairs(cards) do
					if sget(c,"getNumber") > sget(max,"getNumber") then
						max = c
					end
				end
				table.insert(final,max)
				table.removeOne(cards,max)
			end
			return final
		end
	end
	return cards
end

local function getPeachNum(player)
	if player:isKongcheng() then return 0 end
	local peach = 0
	for _, c in sgs.qlist(player:getHandcards()) do
		if sget(c,"isKindOf","Peach") or sget(c,"isKindOf","Analeptic") then
			peach = peach + 1
		end
	end
	return peach
end

sgs.ai_fill_skill["sr_weibao"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_weibaocard") then return nil end
	if self.player:isKongcheng() then return nil end
	if #self.enemies == 0 then return nil end
	if getPeachNum(self.player) == sget(self.player,"getHandcardNum") then return nil end
	local cards = sortHandcards(self,"keep",true)
	return policy(self,"#sr_weibaocard:"..sget(cards[1],"getEffectiveId")..":")
end

sgs.ai_skill_use_func["#sr_weibaocard"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_playerchosen["sr_weibao"] = function(self,targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	enemies = self:sort(enemies,"defense")
	return enemies[1]
end
sgs.ai_fill_skill["sr_choulve"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_choulvecard") then return nil end
	if sget(self.player,"getHandcardNum")<2 then return nil end
	if #self.enemies + #self.friends_noself <2 then return nil end
	if self.room:getOtherPlayers(self.player):length()<2 then return nil end
	if getPeachNum(self.player) +2 >= sget(self.player,"getHandcardNum") then return nil end
	return policy(self,"#sr_choulvecard:.:")
end

sgs.ai_skill_use_func["#sr_choulvecard"] = function(card, use, self)
	self.enemies = self:sort(self.enemies,"defense")
	if #self.friends_noself == 0 then
		if sget(self.player,"getHandcardNum") <= sget(self.player,"getHp") + 1 then return end
		use.card =	card
		if use.to then
			use.to:append(self.enemies[1])
			use.to:append(self.enemies[2])
			return
		end
	else
		self.friends_noself = self:sort(self.friends_noself,"defense")
		use.card = card
		if use.to then
			use.to:append(self.friends_noself[1])
			use.to:append(self.enemies[1])
			return
		end
	end
	return
end
sgs.ai_skill_discard["sr_choulve1"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local current = self.room:getCurrent()
		local cards = sortHandcards(self,"number",false)
		table.insert(to_discard,cards[1]:getId())
		return to_discard
end
sgs.ai_skill_discard["sr_choulve2"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local current = self.room:getCurrent()
		local cards = sortHandcards(self,"number",true)
		table.insert(to_discard,cards[1]:getId())
		return to_discard
end

sgs.ai_skill_invoke["sr_shixue"] = function(self,data)
	return true
end
sgs.ai_cardneed.sr_shixue = sgs.ai_cardneed.slash


sgs.ai_skill_invoke["sr_guoshibegin"] = function(self,data)
	return true
end
sgs.ai_skill_invoke["sr_guoshiend"] = function(self,data)
	local current = self.room:getCurrent()
	if current and current:isAlive() and self:isFriend(current) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["sr_guoshiend"] = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if current then
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(player, current, -20)
		end
	end
end

local function hasOnlyOneHandcardAndHasDelayTrick(player)
	return sget(player,"getHandcardNum") == 1 and player:getCards("e"):isEmpty() and player:getCards("j"):length()>0
end

sgs.ai_fill_skill["sr_jiexi"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_jiexicard") or self.player:isKongcheng() or #self.enemies == 0 then return nil end
	local cando = false
	for _,p in ipairs(self.enemies) do
		if not hasOnlyOneHandcardAndHasDelayTrick(p) and not p:isKongcheng() and sget(self.player,"canPindian",p) then
			cando = true
			break
		end
	end
	if not cando then return nil end
	local cards = sortHandcards(self,"number",false)
	return policy(self,"#sr_jiexicard:"..cards[1]:getId()..":")
end

sgs.ai_skill_use_func["#sr_jiexicard"] = function(card, use, self)
	local enemies = {}
	for _,p in ipairs(self.enemies) do
		if not hasOnlyOneHandcardAndHasDelayTrick(p) and not p:isKongcheng() and sget(self.player,"canPindian",p) then
			table.insert(enemies,p)
		end
	end
	enemies = self:sort(enemies,"defense")
	use.card = card
	if use.to then
		use.to:append(enemies[1])
	end
	return
end

sgs.ai_use_value["sr_jiexicard"] = 5
sgs.ai_cardneed.sr_jiexi = sgs.ai_cardneed.bignumber

sgs.ai_skill_invoke["sr_jiexi"] = function(self,data)
	local target = data:toPlayer()
	return not hasOnlyOneHandcardAndHasDelayTrick(target) and self:isEnemy(target) and not target:isKongcheng()
end
sgs.ai_fill_skill["sr_youxia"] = function(self,inclusive,request)
	if not sget(self.player,"faceUp") then return nil end
	local cando = false
	for _,p in ipairs(self.enemies) do
		if not p:isNude() then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return policy(self,"#sr_youxiacard:.:")
end

sgs.ai_skill_use_func["#sr_youxiacard"] = function(card, use, self)
	local enemies = {}
	for _,p in ipairs(self.enemies) do
		if not p:isNude() then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return end
	if #enemies==1 and #self.friends_noself==0 then return end
	enemies = self:sort(enemies,"defense")
	if #enemies==1 then
		use.card = card
		if use.to then
			use.to:append(enemies[1])
		end
		return
	else
		use.card = card
		if use.to then
			use.to:append(enemies[1])
			use.to:append(enemies[2])
		end
		return
	end
	return
end

sgs.ai_use_priority["sr_youxiacard"] = 6
sgs.ai_use_value["sr_youxiacard"] = 9

sgs.ai_fill_skill["sr_zhouyan"] = function(self,inclusive,request)
	if sget(self.player,"hasFlag","srzhouyannotdo") then return nil end
	if sget(self.player,"getHandcardNum")<=2 then return nil end
	local cando = false
	for _,p in ipairs(self.enemies) do
		if sget(p,"getHandcardNum")<=2 then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return policy(self,"#sr_zhouyancard:.:")
end

sgs.ai_skill_use_func["#sr_zhouyancard"] = function(card, use, self)
	local enemies = {}
	for _,p in ipairs(self.enemies) do
		if sget(p,"getHandcardNum")<=2 then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return end
	enemies = self:sort(enemies,"hp")
	use.card = card
	if use.to then
		use.to:append(enemies[1])
	end
	return
end

sgs.ai_use_value["sr_zhouyancard"] = 5

sgs.ai_skill_invoke["sr_zhouyan_draw"] = function(self,data)
	return true
end
sgs.ai_skill_invoke["sr_zhouyan"] = function(self,data)
	local damage= data:toDamage()
	return sget(damage.to,"getHandcardNum")<=2
end
sgs.ai_fill_skill["sr_zhaxiang"] = function(self,inclusive,request)
	if self.player:isKongcheng() then return nil end
	return policy(self,"#sr_zhaxiangcard:.:")
end

sgs.ai_skill_use_func["#sr_zhaxiangcard"] = function(card, use, self)
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if sget(c,"isKindOf","Slash") then
			if #self.enemies>0 then
				self.enemies = self:sort(self.enemies,"defense")
				use.card = policy(self,"#sr_zhaxiangcard:"..sget(c,"getEffectiveId")..":")
				return
			end
		end
	end
	if #self.friends_noself>0 then
		self.friends_noself = self:sort(self.friends_noself,"defense")
		local cards = sortHandcards(self,"keep",false)
		use.card = policy(self,"#sr_zhaxiangcard:"..sget(cards[1],"getEffectiveId")..":")
		return
	end
	return
end

sgs.ai_use_value["sr_zhaxiangcard"] = 5
sgs.ai_skill_playerchosen["sr_zhaxiang"] = function(self, targets)
	local tag = fact(self,"zhaxiang")
	if tag == "slash" or tag == "Slash" then
		local enemies = {}
		for _,p in sgs.qlist(targets) do
			if not self:isFriend(p) then
				table.insert(enemies,p)
			end
		end
		if #enemies == 0 then return nil end
		enemies = self:sort(enemies,"defense")
		return enemies[1]
	else
		local friends = {}
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) then
				table.insert(friends,p)
			end
		end
		if #friends == 0 then return nil end
		friends = self:sort(friends,"defense")
		return friends[1]
	end
end

sgs.ai_skill_choice["sr_zhaxiang"] = function(self, choices, data)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		return "srshow"
	else
		if not self:isWeak() then
			return "srshow"
		end
	end
	return "srgive"
end

sgs.ai_skill_discard["sr_zhaxiang"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	if self.player:getCards("e"):length()>0 then
		table.insert(to_discard,self.player:getCards("e"):first():getId())
	else
		local cards = sortHandcards(self,"keep",true)
		table.insert(to_discard,cards[1]:getId())
	end
	return to_discard
end

sgs.ai_fill_skill["sr_fangxin"] = function(self,inclusive,request)
	if not sget(self.player,"isWounded") then return nil end
	local indulgence = clone(self,"indulgence",sgs.Card_Diamond,0)
	do end
	local supply_shortage = clone(self,"supply_shortage",sgs.Card_Club,0)
	do end
	if  (self.player:isProhibited(self.player,indulgence) or self.player:containsTrick("indulgence")) and
	(self.player:isProhibited(self.player,supply_shortage) or self.player:containsTrick("supply_shortage")) then
		return nil
	elseif  (self.player:isProhibited(self.player,supply_shortage) or
		self.player:containsTrick("supply_shortage")) then
		local cards = suitCards(self.player,"diamond",true)
		if #cards == 0 then return nil end
		cards = self:sortByKeepValue(cards)
		return policy(self,"#sr_fangxincard:"..sget(cards[1],"getEffectiveId")..":")
	elseif  (self.player:isProhibited(self.player,indulgence) or self.player:containsTrick("indulgence")) then
		local cards = suitCards(self.player,"club",true)
		if #cards == 0 then return nil end
		cards = self:sortByKeepValue(cards)
		return policy(self,"#sr_fangxincard:"..sget(cards[1],"getEffectiveId")..":")
	else
		local cards = suitCards(self.player,"club,diamond",true)
		if #cards == 0 then return nil end
		cards = self:sortByKeepValue(cards)
		return policy(self,"#sr_fangxincard:"..sget(cards[1],"getEffectiveId")..":")
	end
	return nil
end

sgs.ai_skill_use_func["#sr_fangxincard"] = function(card, use, self)
	use.card = card
end

sgs.ai_cardsview_valuable["sr_fangxin"] = function(self, class_name,player)
	if class_name ~= "Peach" or not sget(player,"hasSkill","sr_fangxin") then return end
	local dying = self.room:getCurrentDyingPlayer()
	if not dying then return  end
	if sget(player,"hasFlag","Global_PreventPeach") then return end
	local indulgence = clone(self,"indulgence",sgs.Card_Diamond,0)
	do end
	local supply_shortage = clone(self,"supply_shortage",sgs.Card_Club,0)
	do end
	if  (player:isProhibited(player,indulgence) or player:containsTrick("indulgence")) and
	(player:isProhibited(player,supply_shortage) or player:containsTrick("supply_shortage")) then
		return
	elseif  (player:isProhibited(player,supply_shortage) or player:containsTrick("supply_shortage")) then
		local cards = suitCards(player,"diamond",true)
		if #cards == 0 then return end
		cards = self:sortByKeepValue(cards)
		return "#sr_fangxincard:"..sget(cards[1],"getEffectiveId")..":"
	elseif  (player:isProhibited(player,indulgence) or player:containsTrick("indulgence")) then
		local cards = suitCards(player,"club",true)
		if #cards == 0 then return end
		cards = self:sortByKeepValue(cards)
		return "#sr_fangxincard:"..sget(cards[1],"getEffectiveId")..":"
	else
		local cards = suitCards(player,"club,diamond",true)
		if #cards == 0 then return end
		cards = self:sortByKeepValue(cards)
		return "#sr_fangxincard:"..sget(cards[1],"getEffectiveId")..":"
	end
	return
end

sgs.ai_card_intention["#sr_fangxincard"] = sgs.ai_card_intention.Peach

sgs.ai_use_priority["#sr_fangxincard"] = sgs.ai_use_priority.Peach

sgs.ai_skill_invoke["sr_xiyu"] = function(self,data)
	for _,p in sgs.qlist(self.room:getAllPlayers()) do
		if self:isFriend(p) and sget(p,"getHandcardNum")>=3 then
			return true
		end
		if self:isEnemy(p) and sget(p,"getHandcardNum")<=2 then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen["sr_xiyu"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and sget(p,"getHandcardNum") >=3 then
			table.insert(friends,p)
		end
	end
	if #friends > 0 then
		friends = self:sort(friends,"defense")
		return friends[1]
	end
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) and sget(p,"getHandcardNum")<=2 then
			table.insert(enemies,p)
		end
	end
	if #enemies>0 then
		enemies = self:sort(enemies,"defense")
		return enemies[1]
	end
	return targets:first()
end


sgs.ai_skill_invoke["sr_wanrou"] = true

sgs.ai_skill_playerchosen["sr_wanrou"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end
	end
	if #friends > 0 then
		friends = self:sort(friends,"defense")
		return friends[1]
	end
end

sgs.ai_playerchosen_intention.sr_wanrou = -50
sgs.ai_fill_skill["sr_yinmeng"] = function(self,inclusive,request)
	if self.player:usedTimes("#sr_yinmengcard") >= math.max(sget(self.player,"getLostHp"),1)
		or self.player:isKongcheng() then return nil end
	local cando = false
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if sget(p,"isMale") and not p:isKongcheng() then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return policy(self,"#sr_yinmengcard:.:")
end

sgs.ai_skill_use_func["#sr_yinmengcard"] = function(card, use, self)
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if sget(p,"isMale") and not p:isKongcheng() then
			if self:isFriend(p) then
				if sget(self.player,"getHandcardNum")>=3 then
					use.card = card
					if use.to then
						use.to:append(p)
						return
					end
				end
			else
				use.card = card
				if use.to then
					use.to:append(p)
					return
				end
			end
		end
	end
	return
end

sgs.ai_cardshow.sr_yinmeng=function(self,requestor)
    local cards=sget(self.player,"getCards","h")
    local row=sget(self,"getDecisionContext").sr_yinmeng
    if type(row)~="table"or row.known~=true or type(row.card_type)~="number"
        or type(row.target)~="string" then ai_unsupported("sr_yinmeng shown-card question context absent","sr_yinmeng.context")end
    local target
    if row.target~=""then target=sget(self.room,"findPlayerByObjectName",row.target)end
    for _,card in sgs.qlist(cards)do
        if sget(self,"isFriend",target)then
            if sget(card,"getTypeId")==row.card_type then return card end
        else
            if sget(card,"getTypeId")~=row.card_type then return card end
        end
    end
    return cards:first()
end

sgs.ai_cardneed.sr_xiwu = sgs.ai_cardneed.slash

sgs.ai_fill_skill["sr_juelie"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_jueliecard") then return nil end
	local cando = false
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if sget(p,"getHandcardNum") ~= sget(self.player,"getHandcardNum") then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return policy(self,"#sr_jueliecard:.:")
end

sgs.ai_skill_use_func["#sr_jueliecard"] = function(card, use, self)
	local friends = {}
	local enemies = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if sget(p,"getHandcardNum") < sget(self.player,"getHandcardNum") then
			if self:isFriend(p) then
				table.insert(friends,p)
			end
		end
		if sget(p,"getHandcardNum") > sget(self.player,"getHandcardNum") then
			if self:isEnemy(p) then
				table.insert(enemies,p)
			end
		end
	end
	if #friends>0 then
		friends = self:sort(friends,"defense")
		use.card = card
		if use.to then
			use.to:append(friends[1])
		end
		return
	end
	if #enemies>0 then
		enemies = self:sort(enemies,"defense")
		use.card = card
		if use.to then
			use.to:append(enemies[1])
		end
		return
	end
	return
end

sgs.ai_skill_choice["sr_juelie"] = function(self, choices, data)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		return "srkeepsame"
	else
		if not self:isWeak() then
			return "srslash"
		end
	end
	return "srkeepsame"
end

sgs.ai_use_priority["sr_jueliecard"] = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_skill_invoke["sr_zhaoxiang"] = function(self,data)
	local use = data:toCardUse()
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardask["srzhaoxiangdiscard"] = function(self, data, pattern, target, target2)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return "." end
	cards = self:sortByKeepValue(cards)
	return "$"..sget(cards[1],"getEffectiveId")
end

sgs.ai_skill_choice["sr_zhaoxiang"] = function(self, choices, data)
	local use = data:toCardUse()
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			return "srzhaoxiangslashnullified"
		else
			return "srzhaoxianggetcard"
		end
	end
end
local function needDamaged(self,player)
	local need = false
	if sget(player,"getHp") > getBestHp(player) then need = true end
	if not need and not self:isGoodTarget(player, self.friends, nil) then need = true end
	if not need then
		for _, skill in sgs.qlist(player:getVisibleSkillList()) do
			local callback = sgs.ai_need_damaged[skill:objectName()]
			if type(callback) == "function" and callback(self, nil, player) then
				need = true
				break
			end
		end
	end
	return need
end
sgs.ai_fill_skill["sr_zhishi"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_zhishicard") then return nil end
	local cando = false
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) and self:needToLoseHp(p, self.player) then
			cando = true
			break
		end
		if self:isEnemy(p) and sget(p,"getHp")<=1 and not (sget(p,"hasSkill","buqu") or sget(p,"hasSkill","nosbuqu"))
			and p:isKongcheng() then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return policy(self,"#sr_zhishicard:.:")
end

sgs.ai_skill_use_func["#sr_zhishicard"] = function(card, use, self)
	local friends = {}
	local enemies = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and sget(p,"getHp")<=1 and not (sget(p,"hasSkill","buqu") or sget(p,"hasSkill","nosbuqu"))
			and p:isKongcheng() then
			table.insert(enemies,p)
		end
		if self:isFriend(p) and needDamaged(self,p) then
			table.insert(friends,p)
		end
	end
	if #enemies>0 then
		enemies = self:sort(enemies,"defense")
		use.card = card
		if use.to then
			use.to:append(enemies[1])
		end
		return
	end
	if #friends>0 then
		friends = self:sort(friends,"defense",false)
		use.card = card
		if use.to then
			use.to:append(friends[1])
		end
		return
	end
	return
end
sgs.ai_skill_cardask["#srbasic"] = function(self, data, pattern, target, target2)
	if needDamaged(self,self.player) then return "." end
	local cards = {}
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if sget(c,"isKindOf","BasicCard") then
			table.insert(cards,c)
		end
	end
	if #cards == 0 then return "." end
	cards = self:sortByKeepValue(cards)
	return "$"..sget(cards[1],"getEffectiveId")
end
sgs.ai_skill_playerchosen["sr_jianxiong"] = function(self, targets)
	if self:isWeak() then return nil end
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end
	end
	if #friends == 0 then return nil end
	friends = self:sort(friends,"defense")
	return friends[1]
end
sgs.ai_playerchosen_intention.sr_jianxiong = -50

sgs.ai_skill_invoke["sr_tianshang"] = function(self,data)
	if #self.friends_noself > 0 then return true end
	return false
end
sgs.ai_skill_playerchosen["sr_tianshang"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end
	end
	if #friends == 0 then return nil end
	friends = self:sort(friends,"defense")
	return friends[1]
end
sgs.ai_skill_choice["sr_tianshang"] = function(self, choices, data)
	local choices1 = choices:split("+")
	return choices1[math.random(1, #choices1 - 1)]
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|sr_tianshang"
sgs.ai_skill_invoke.sr_yiji = function(self)
	local Shenfen_user
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if sget(player,"hasFlag","ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	if sget(self.player,"getHandcardNum") < 2 then return true end
	local invoke
	for _, friend in ipairs(self.friends) do
		if not (sget(friend,"hasSkill","manjuan") and sget(friend,"getPhase") == sgs.Player_NotActive) and
			not self:needKongcheng(friend, true) and not self:isLihunTarget(friend) and
			(not Shenfen_user or Shenfen_user:objectName() == friend:objectName() or
				sget(friend,"getHandcardNum") >= 4) then
				invoke = true
			break
		end
	end
	return invoke
end

sgs.ai_skill_askforyiji.sr_yiji = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, visible(self,card_id))
	end

	local Shenfen_user
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if sget(player,"hasFlag","ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end

	if Shenfen_user then
		if self:isFriend(Shenfen_user) then
			if Shenfen_user:objectName() ~= self.player:objectName() then
				for _, id in ipairs(card_ids) do
					return Shenfen_user, id
				end
			else
				return nil, -1
			end
		else
			if sget(self.player,"getHandcardNum") < self:getOverflow(false, true) then
				return nil, -1
			end
			local card, friend = self:getCardNeedPlayer(cards)
			if card and friend and sget(friend,"getHandcardNum") >= 4 then
				return friend, card:getId()
			end
		end
	end

	if sget(self.player,"getHandcardNum") <= 2 and not Shenfen_user then
		return nil, -1
	end

	local new_friends = {}
	local CanKeep
	for _, friend in ipairs(self.friends) do
		if not (sget(friend,"hasSkill","manjuan") and sget(friend,"getPhase") == sgs.Player_NotActive) and
		not self:needKongcheng(friend, true) and not self:isLihunTarget(friend) and
		(not Shenfen_user or friend:objectName() == Shenfen_user:objectName() or sget(friend,"getHandcardNum") >= 4) then
			if friend:objectName() == self.player:objectName() then CanKeep = true
			else
				table.insert(new_friends, friend)
			end
		end
	end

	if #new_friends > 0 then
		local card, target = self:getCardNeedPlayer(cards)
		if card and target then
			for _, friend in ipairs(new_friends) do
				if target:objectName() == friend:objectName() then
					return friend, sget(card,"getEffectiveId")
				end
			end
		end
		if Shenfen_user and self:isFriend(Shenfen_user) then
			return Shenfen_user, sget(cards[1],"getEffectiveId")
		end
		new_friends = self:sort(new_friends, "defense")
		cards = self:sortByKeepValue(cards, true)
		return new_friends[1], sget(cards[1],"getEffectiveId")
	elseif CanKeep then
		return nil, -1
	else
		local other = {}
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not (self:isLihunTarget(player) and self:isFriend(player)) and (self:isFriend(player) or
				not sget(player,"hasSkill","lihun")) then
				table.insert(other, player)
			end
		end
		return other[math.random(1, #other)], card_ids[math.random(1, #card_ids)]
	end

end

sgs.ai_need_damaged.sr_yiji = function (self, attacker, player)
	if not sget(player,"hasSkill","sr_yiji") then return end
	local need_card = false
	local current = self.room:getCurrent()
	if self:hasCrossbowEffect(current) or sget(current,"hasSkill","paoxiao") or sget(current,"hasFlag","shuangxiong") then
		need_card = true
	end
	if self:hasSkills("jieyin|jijiu",current) and self:getOverflow(current) <= 0 then need_card = true end
	if self:isFriend(current, player) and need_card then return true end

	local friends = {}
	for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(ap, player) then
			table.insert(friends, ap)
		end
	end
	friends = self:sort(friends, "hp")
	if #friends > 0 and friends[1]:objectName() == player:objectName() and self:isWeak(player) and
	getCardsNum("Peach", player, (attacker or self.player)) == 0 then return false end
	if #friends > 1 and self:isWeak(friends[2]) then return true end

	return sget(player,"getHp") > 2 and known(self.world.turn_count,"turn count") > 2 and #friends > 1
end

sgs.ai_chaofeng.sr_guojia = -4
sgs.ai_skill_invoke["sr_huiqu"] = function(self,data)
	return sget(self.player,"getHandcardNum")>=2
end
sgs.ai_skill_playerchosen["sr_huiqudamage"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	enemies = self:sort(enemies,"defense")
	return enemies[1]
end
local function card_for_qiaobian(self, who, return_prompt)
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = visible(self,sget(judge,"getEffectiveId"))
				if not sget(judge,"isKindOf","YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) then
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
				if sget(equip,"isKindOf","OffensiveHorse") then card = equip break
				elseif sget(equip,"isKindOf","Weapon") then card = equip break
				elseif sget(equip,"isKindOf","DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif sget(equip,"isKindOf","Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if sget(card,"isKindOf","Armor") or sget(card,"isKindOf","DefensiveHorse") then
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
				if sget(judge,"isKindOf","YanxiaoCard") then
					card = visible(self,sget(judge,"getEffectiveId"))
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and
						not self.room:isProhibited(self.player, friend, judge)
							and not friend:getJudgingArea():isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and
						not self.room:isProhibited(self.player, friend, judge) then
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
			local recommended=self:recommendCardChosen(who,"e","snatch")
 local card_id=recommended and recommended.id or -1
			if card_id >= 0 and who:hasEquip(visible(self,card_id)) then
				card = visible(self,card_id) end

			if card then
				if sget(card,"isKindOf","Armor") or sget(card,"isKindOf","DefensiveHorse") then
					self.friends = self:sort(self.friends, "defense")
				else
					self.friends = self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and
					self:hasSkills(sgs.lose_equip_skill .. "|shensu" , friend) then
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

sgs.ai_skill_cardchosen["sr_huiqu"] = function(self, who, flags)
	if flags == "ej" then
		return card_for_qiaobian(self, who, "card")
	end
end

sgs.ai_skill_playerchosen["sr_huiqufirst"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end
	end
	enemies = self:sort(enemies, "defense")
	for _, friend in ipairs(friends) do
		if not friend:getCards("j"):isEmpty() and not friend:containsTrick("YanxiaoCard") and
		card_for_qiaobian(self, friend, ".") then
			return friend
		end
	end

	for _, enemy in ipairs(enemies) do
		if not enemy:getCards("j"):isEmpty() and enemy:containsTrick("YanxiaoCard") and
			card_for_qiaobian(self, enemy, ".") then
			return enemy
		end
	end

	for _, friend in ipairs(friends) do
		if not friend:getCards("e"):isEmpty() and self:hasSkills(sgs.lose_equip_skill, friend) and
		card_for_qiaobian(self, friend, ".") then
			return friend
		end
	end

	local targets = {}
	for _, enemy in ipairs(enemies) do
		if card_for_qiaobian(self, enemy, ".") then
			table.insert(targets, enemy)
		end
	end

	if #targets > 0 then
		targets = self:sort(targets, "defense")
		return targets[#targets]
	end
end

sgs.ai_skill_playerchosen["sr_huiqu"] = function(self, targets)
	local who = fact_player(self,"huiqu_target")
	if who then
		if not card_for_qiaobian(self, who, "target") then self:log("NULL") end
		return card_for_qiaobian(self, who, "target")
	end
end

sgs.ai_fill_skill["sr_aozhan"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_aozhanCard") then return nil end
	if self.player:getPile("@srzhan"):length() == 0 then return nil end
	if sget(self.player,"getHandcardNum")>(sget(self.player,"getHp")+2) then return nil end
	local card = policy(self,"#sr_aozhanCard:.:")
	if not card then return nil end
	return card
end

sgs.ai_skill_use_func["#sr_aozhanCard"] = function(card, use, self)
	use.card = card
end


sgs.ai_use_value.sr_aozhanCard = 7

sgs.ai_skill_invoke.sr_aozhan = function(self,data)
	return true
end

sgs.ai_skill_choice["sr_aozhan"] = function(self, choices, data)
	local ids = self.player:getPile("@srzhan")
	for _,id in sgs.qlist(ids) do
		local card = visible(self,id)
		if sget(card,"isKindOf","ExNihilo") or (sget(card,"isKindOf","Peach") and sget(self.player,"isWounded")) then
			return "sraozhanget"
		end
	end
	return "sraozhandraw"
end
sgs.ai_cardneed.sr_aozhan = sgs.ai_cardneed.luoyi

sgs.ai_skill_invoke["sr_huxiao"] = function(self,data)
	local damage = data:toDamage()
	return self:isEnemy(damage.to) and not (self:isWeak() and sget(self.player,"faceUp"))
end
sgs.ai_ajustdamage_from.sr_huxiao = function(self, from, to, card, nature)
	if (card and sget(card,"isKindOf","Slash")) and not self:beFriend(to, from) and sget(from,"getPhase") == sgs.Player_Play and sget(from,"faceUp")
	then
		return 1
	end
end
sgs.ai_cardneed.sr_huxiao = sgs.ai_cardneed.slash

sgs.ai_skill_invoke["sr_guicai"] = function(self,data)
	local judge = data:toJudge()
	if judge:isGood() and self:isEnemy(judge.who) then return true end
	if judge:isBad() and self:isFriend(judge.who) then return true end
	return false
end
sgs.ai_skill_choice["sr_guicai"] = function(self, choices, data)
	local judge = data:toJudge()
	local who = judge.who
	local reason = judge.reason
	local card = judge.card
	if reason == "indulgence" and self:isFriend(who) and sget(card,"getSuit") ~= sgs.Card_Heart then
		local cards = suitCards(self.player,"heart",false)
		if #cards>0 then return "srguicaidachu" end
	end
	if reason == "supply_shortage" and self:isFriend(who) and sget(card,"getSuit") ~= sgs.Card_Club then
		local cards = suitCards(self.player,"club",false)
		if #cards>0 then return "srguicaidachu" end
	end
	if reason == "lightning" and self:isFriend(who) and sget(card,"getNumber")>=2 and sget(card,"getNumber")<=9
		and sget(card,"getSuit")==sgs.Card_Spade then
		for _,c in sgs.qlist(self.player:getHandcards()) do
			if not(sget(card,"getNumber")>=2 and sget(card,"getNumber")<=9 and sget(card,"getSuit")==sgs.Card_Spade) then
				return "srguicaidachu"
			end
		end
	end
	return "srguicailiangchu"
end
sgs.ai_skill_cardask["@guicai-card"]=function(self, data)
	local judge = data:toJudge()

	if self.room:getMode():find("_mini_46") and not judge:isGood() then
		return "$" .. self.player:handCards():first() end
	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getHandcards())
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end

	return "."
end
sgs.wizard_skill = sgs.wizard_skill .. "|sr_guicai"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|sr_guicai"
sgs.ai_skill_invoke["sr_langgu"] = function(self,data)
	local damage = data:toDamage()
	if damage.to:objectName() == self.player:objectName() then
		return self:isEnemy(damage.from)
	end
	if damage.from:objectName() == self.player:objectName() then
		return self:isEnemy(damage.to)
	end
	return true
end
sgs.ai_skill_invoke["sr_zhuizun"] = function(self,data)
	local peaches = 1 - sget(self.player,"getHp")
	return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
end

sgs.ai_canNiepan_skill.sr_zhuizun = function(player)
	return sget(player,"getMark","@zhuizun") > 0
end

sgs.ai_fill_skill["sr_liuyun"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_liuyuncard") then return nil end
	if self.player:isChained() then return nil end
	local cards = suitCards(self.player,"spade,club",true)
	if #cards == 0 then return nil end
	cards = self:sortByKeepValue(cards)
	return policy(self,"#sr_liuyuncard:"..sget(cards[1],"getEffectiveId")..":")
end

sgs.ai_skill_use_func["#sr_liuyuncard"] = function(card, use, self)
	self.friends = self:sort(self.friends,"defense")
	use.card = card
	if use.to then
		use.to:append(self.friends[1])
	end
	return
end
sgs.ai_card_intention["sr_liuyuncard"] = -80

sgs.ai_skill_choice["sr_liuyun"] = function(self,choices,data)
	if sget(self.player,"isWounded") then
		local hp = sget(self.player,"getHp")
		local count = sget(self.player,"getHandcardNum")
		if hp >= count + 2 then
			return "srliuyundrawcard"
		else
			return "srliuyunrecover"
		end
	end
	return "srliuyundrawcard"
end
local function enemyChainedWithUs(self,enemy)
	if enemy:isChained() then
		for _,p in ipairs(self.friends) do
			return p:isChained()
		end
	end
	return false
end
sgs.ai_skill_invoke["sr_lingbo"] = function(self,data)
	local current = self.room:getCurrent()
	if not current or sget(current,"isDead") then return false end
	if self:isFriend(current) then
		local delay = sgs.QList2Table(current:getJudgingArea())
		if #delay > 0 then
			reverse(delay)
			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				if not p:getCards("ej"):isEmpty() then
					for _,c in sgs.qlist(p:getCards("ej")) do
						if sget(delay[1],"isKindOf","Indulgence") and sget(c,"getSuit") == sgs.Card_Heart then
							self:setStrategyMemory("srkill.lingbocard",c:getId())
 self:setStrategyMemory("srkill.lingboperson",p:objectName())
							return true
						end
						if sget(delay[1],"isKindOf","SupplyShortage") and sget(c,"getSuit") == sgs.Card_Club then
							self:setStrategyMemory("srkill.lingbocard",c:getId())
 self:setStrategyMemory("srkill.lingboperson",p:objectName())
							return true
						end
						if sget(delay[1],"isKindOf","Lightning") and not (sget(c,"getSuit") == sgs.Card_Spade and
							sget(c,"getNumber")<=9 and sget(c,"getNumber") >=2) then
							self:setStrategyMemory("srkill.lingbocard",c:getId())
 self:setStrategyMemory("srkill.lingboperson",p:objectName())
							return true
						end
					end
				end
			end
		end
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) and not p:getCards("j"):isEmpty() then
				for _,c in sgs.qlist(p:getCards("j")) do
					self:setStrategyMemory("srkill.lingbocard",c:getId())
 self:setStrategyMemory("srkill.lingboperson",p:objectName())
					return true
				end
			end
		end
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) and not p:getCards("e"):isEmpty() and self:doDisCard(p, "e") then
				for _,c in sgs.qlist(p:getCards("e")) do
					self:setStrategyMemory("srkill.lingbocard",c:getId())
 self:setStrategyMemory("srkill.lingboperson",p:objectName())
					return true
				end
			end
		end
	else
		local delay = sgs.QList2Table(current:getJudgingArea())
		if #delay > 0 then
			reverse(delay)
			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				if not p:getCards("ej"):isEmpty() then
					for _,c in sgs.qlist(p:getCards("ej")) do
						if sget(delay[1],"isKindOf","Indulgence") and sget(c,"getSuit") ~= sgs.Card_Heart and not AIValue.sameLegacyIdentity(delay[1],c) then
							self:setStrategyMemory("srkill.lingbocard",c:getId())
 self:setStrategyMemory("srkill.lingboperson",p:objectName())
							return true
						end
						if sget(delay[1],"isKindOf","SupplyShortage") and sget(c,"getSuit") ~= sgs.Card_Club  and not AIValue.sameLegacyIdentity(delay[1],c)  then
							self:setStrategyMemory("srkill.lingbocard",c:getId())
 self:setStrategyMemory("srkill.lingboperson",p:objectName())
							return true
						end
						if sget(delay[1],"isKindOf","Lightning") and (sget(c,"getSuit") == sgs.Card_Spade and not AIValue.sameLegacyIdentity(delay[1],c)  and
							sget(c,"getNumber")<=9 and sget(c,"getNumber") >=2) and not enemyChainedWithUs(self,p) then
							self:setStrategyMemory("srkill.lingbocard",c:getId())
 self:setStrategyMemory("srkill.lingboperson",p:objectName())
							return true
						end
					end
				end
			end
		end
	end
	return false
end

sgs.ai_skill_playerchosen["sr_lingbo"] = function(self,targets)
	local per = remembered_player(self,"lingboperson")
	if per then	return per end
	return targets:first()
end
sgs.ai_skill_cardchosen["sr_lingbo"] = function(self,who,flags)
	local id = remembered_id(self,"lingbocard")
	if flags == "ej" then
		for _,c in sgs.qlist(who:getCards(flags)) do
			if c:getId() == id then
				return c
			end
		end
	end
	return who:getCards(flags):first()
end
sgs.ai_fill_skill["sr_qingcheng"] = function(self,inclusive,request)
	if self.player:isChained() then return nil end
	if not fact(self,"slash_available") then return nil end
	return policy(self,"#sr_qingchengcard:.:")
end

sgs.ai_skill_use_func["#sr_qingchengcard"] = function(card, use, self)
	if self.player:isChained() then return end
	local slash = clone(self,"slash",sgs.Card_NoSuit,0)
	do end
	local enemies = {}
	for _, p in ipairs(self.enemies) do
		if self.player:canSlash(p,slash,true) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return end
	use.card = card
	enemies = self:sort(enemies,"defense")
	if use.to then
		use.to:append(enemies[1])
	else
		return
	end
end

sgs.ai_cardsview_valuable["sr_qingcheng"] = function(self, class_name,player)
	if not sget(player,"hasSkill","sr_qingcheng") then return end
	if class_name == "Slash" and not player:isChained() then
		return "#sr_qingchengcard:.:"
	elseif class_name == "Jink" and player:isChained() then
		return "#sr_qingchengcard:.:"
	end
	return
end

sgs.ai_card_intention["#sr_qingchengcard"] = sgs.ai_card_intention.Slash

sgs.ai_use_priority["#sr_qingchengcard"] = sgs.ai_use_priority.Slash

sgs.ai_skill_choice["sr_xiahouhelp"] = function(self,choices,data)
	if self:isWeak() then return "srcancel" end
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then return "srlosehp" end
	return "srcancel"
end

sgs.ai_fill_skill["sr_xiahou"] = function(self,inclusive,request)
	if sget(self.player,"getPhase") ~= sgs.Player_Play then return nil end
	if sget(self.player,"hasFlag","xiahouused") then return nil end
	local Analeptic = clone(self,"analeptic",sgs.Card_NoSuit,0)
	do end
	if not sget(self.player,"isWounded") and not fact(self,"slash_available") and
		not sget(Analeptic,"isAvailable",self.player) then
		return nil
	end
	local xiahou = self.room:findPlayerBySkillName("sr_zhonghou")
	if not xiahou then return nil end
	if self:isFriend(xiahou) and self:isWeak(xiahou) then return nil end
	return policy(self,"#sr_xiahoucard:.:")
end

sgs.ai_skill_use_func["#sr_xiahoucard"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_choice["sr_xiahou"] = function(self,choices,data)
	if self:isWeak() then return "peach" end
	local Analeptic = clone(self,"analeptic",sgs.Card_NoSuit,0)
	do end
	if fact(self,"slash_available") then
		for _,p in ipairs(self.enemies) do
			if self.player:canSlash(p,true) then
				if sget(p,"getMark","@gale")>0 or equip(self,p,1) and equip(self,p,1):isKindOf("Vine") then
					if string.find(choices,"fire_slash") then
						return "fire_slash"
					end
				end
				if sget(p,"getMark","@fog")>0 then
					if string.find(choices,"thunder_slash") then
						return "thunder_slash"
					end
				end
				if self:getCardsNum("Slash") > 0 and sget(Analeptic,"isAvailable",self.player) then
					if string.find(choices,"analeptic") then
						return "analeptic"
					end
				end
				for _,c in ipairs(choices:split("+")) do
					if string.find(c,"slash") then
						return c
					end
				end
			end
		end
	elseif sget(self.player,"isWounded") then
		return "peach"
	end
end

sgs.ai_skill_choice["sr_xiahouresponse"] = function(self,choices,data)
	local choices1 = choices:split("+")
	return choices1[math.random(1, #choices1)]
end

sgs.ai_skill_choice["sr_xiahousave"] = function(self,choices,data)
	local choices1 = choices:split("+")
	return choices1[math.random(1, #choices1)]
end

sgs.ai_cardsview_valuable["sr_xiahou"] = function(self, class_name,player)
	if not sget(player,"hasSkill","sr_xiahou") then return end
	if sget(player,"getPhase") ~= sgs.Player_Play then return end
	if sget(player,"hasFlag","xiahouused") then return nil end
	if class_name == "Slash" then
		return "#sr_xiahoucard:.:"
	elseif class_name == "Jink" then
		return "#sr_xiahoucard:.:"
	elseif class_name == "Peach" or class_name == "Analeptic" then
		if not sget(player,"hasFlag","Global_PreventPeach") then
			return "#sr_xiahoucard:.:"
		end
	end
	return
end

sgs.ai_skill_playerchosen["sr_xiahou"] = function(self,targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies==0 then return nil end
	enemies = self:sort(enemies,"defense")
	return enemies[1]
end

sgs.ai_card_intention["sr_xiahoucard"] = sgs.ai_card_intention.Slash

sgs.ai_use_priority["sr_xiahoucard"] = sgs.ai_use_priority.Slash



sgs.ai_skill_invoke["sr_ganglie"] = function(self,data)
	if not self:isWeak() and sget(self.player,"getHandcardNum") >=2 then
		for _,c in sgs.qlist(self.player:getHandcards()) do
			if sget(c,"isKindOf","Slash") then
				for _, p in ipairs(self.enemies) do
					if self.player:canSlash(p,true) then
						if self:isWeak(p) or (p:isKongcheng() and not p:getArmor()) then
							return true
						end
					end
				end
			elseif sget(c,"isKindOf","SavageAssault") or sget(c,"isKindOf","ArcheryAttack") then
				local nextplayer = self.player:getNextAlive()
				return (self:isFriend(nextplayer) and not self:isWeak(nextplayer))
				   or  (self:isEnemy(nextplayer) and self:isWeak(nextplayer))
			elseif sget(c,"isKindOf","Duel") then
				for _, p in ipairs(self.enemies) do
					if not self.player:isProhibited(p,c) then
						if self:isWeak(p) or p:isKongcheng() then
							return true
						end
					end
				end
			elseif sget(c,"isKindOf","FireAttack") then
				for _, p in ipairs(self.enemies) do
					if not self.player:isProhibited(p,c) then
						if (self:isWeak(p) or p:getArmor() and p:getArmor():isKindOf("Vine"))
							and not p:isKongcheng() and sget(self.player,"getHandcardNum"):length()>=4 then
							return true
						end
					end
				end
			end
		end
	end
	return false
end
sgs.ai_ajustdamage_from.sr_ganglie   = function(self, from, to, card, nature)
	if from and not sget(from,"hasFlag","damageincreased") and sget(from,"hasFlag","srganglieinvoked") then
		return 1
	end
end
sgs.ai_skill_playerchosen["sr_wuwei"] = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_skill_invoke["sr_yansha"] = function(self,data)
	if sget(self.player,"hasFlag","yansha_draw") then
		return (not self:isWeak()) and (sget(self.player,"getHandcardNum") >= 2)
	end
	local use = data:toCardUse()
	local from = use.from
	return self:isEnemy(from) and sget(from,"getHandcardNum")>=2
end
sgs.ai_skill_cardask["#sr_yansha"] = function(self, data, pattern, target, target2)
	if self.player:isKongcheng() then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	if #cards==1 and (sget(cards[1],"isKindOf","Peach") or sget(cards[1],"isKindOf","Analeptic")) then return "." end
	cards = self:sortByKeepValue(cards)
	return "$"..sget(cards[1],"getEffectiveId")
end


local function getLijianCard(self)
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")

	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif sget(self.player,"getHandcardNum") > sget(self.player,"getHp") then
		if lightning and not self:willUseLightning(lightning) then
			card_id = sget(lightning,"getEffectiveId")
		else
			for _, acard in ipairs(cards) do
				if (sget(acard,"isKindOf","BasicCard") or sget(acard,"isKindOf","EquipCard") or sget(acard,"isKindOf","AmazingGrace"))
					and not sget(acard,"isKindOf","Peach") then
					card_id = sget(acard,"getEffectiveId")
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and sget(player,"getHandcardNum") <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = sget(lightning,"getEffectiveId")
		else
			for _, acard in ipairs(cards) do
				if (sget(acard,"isKindOf","BasicCard") or sget(acard,"isKindOf","EquipCard") or sget(acard,"isKindOf","AmazingGrace"))
				  and not sget(acard,"isKindOf","Peach") then
					card_id = sget(acard,"getEffectiveId")
					break
				end
			end
		end
	end
	return card_id
end

local function findLijianTarget(self,card_name, use)
	local lord = self.room:getLord()
	local duel = clone(self,"duel")

	local findFriend_maxSlash = function(self, first)
		self:log("Looking for the friend!")
		local maxSlash = 0
		local friend_maxSlash
		local nos_fazheng, fazheng
		for _, friend in ipairs(self.friends_noself) do
			if sget(friend,"isMale") and self:hasTrickEffective(duel, first, friend) then
				if sget(friend,"hasSkill","nosenyuan") and sget(friend,"getHp") > 1 then nos_fazheng = friend end
				if sget(friend,"hasSkill","enyuan") and sget(friend,"getHp") > 1 then fazheng = friend end
				if (getCardsNum("Slash", friend) > maxSlash) then
					maxSlash = getCardsNum("Slash", friend)
					friend_maxSlash = friend
				end
			end
		end

		if friend_maxSlash then
			local safe = false
			if self:hasSkills("neoganglie|vsganglie|fankui|enyuan|ganglie|nosenyuan", first) and not
				self:hasSkills("wuyan|noswuyan", first) then
				if (sget(first,"getHp") <= 1 and sget(first,"getHandcardNum") == 0) then safe = true end
			elseif (getCardsNum("Slash", friend_maxSlash) >= getCardsNum("Slash", first)) then safe = true end
			if safe then return friend_maxSlash end
		else self:log("unfound")
		end
		if nos_fazheng or fazheng then	return nos_fazheng or fazheng end		--备用友方，各种恶心的法正
		return nil
	end

	if self.role == "rebel" or (self.role == "renegade" and
		known(self:getRoleCounts().loyalist,"loyalist count")  + 1 > known(self:getRoleCounts().rebel,"rebel count")) then

		if lord and sget(lord,"isMale") and not lord:isNude() and lord:objectName() ~= self.player:objectName() then		-- 优先离间1血忠和主
			self.enemies = self:sort(self.enemies, "handcard")
			local e_peaches = 0
			local loyalist

			for _, enemy in ipairs(self.enemies) do
				e_peaches = e_peaches + getCardsNum("Peach", enemy)
				if sget(enemy,"getHp") == 1 and self:hasTrickEffective(duel, enemy, lord) and
					enemy:objectName() ~= lord:objectName()
				and sget(enemy,"isMale") and not loyalist then
					loyalist = enemy
					break
				end
			end

			if loyalist and e_peaches < 1 then return loyalist, lord end
		end

		if #self.friends_noself >= 2 and self:getAllPeachNum() < 1 then		--收友方反
			local nextplayerIsEnemy
			local nextp = self.player:getNextAlive()
			for i = 1, self.room:alivePlayerCount() do
				if not self:willSkipPlayPhase(nextp) then
					if not self:isFriend(nextp) then nextplayerIsEnemy = true end
					break
				else
					nextp = nextp:getNextAlive()
				end
			end
			if nextplayerIsEnemy then
				local round = 50
				local to_die, nextfriend
				self.enemies = self:sort(self.enemies, "hp")
				for _, a_friend in ipairs(self.friends_noself) do	-- 目标1：寻找1血友方
					if sget(a_friend,"getHp") == 1 and a_friend:isKongcheng() and not
					self:hasSkills("kongcheng|yuwen", a_friend) and sget(a_friend,"isMale") then
						for _, b_friend in ipairs(self.friends_noself) do
							if b_friend:objectName() ~= a_friend:objectName() and sget(b_friend,"isMale") and
							 self:playerGetRound(b_friend) < round
							and self:hasTrickEffective(duel, a_friend, b_friend) then

								round = self:playerGetRound(b_friend)
								to_die = a_friend
								nextfriend = b_friend

							end
						end
						if to_die and nextfriend then break end
					end
				end

				if to_die and nextfriend then return to_die, nextfriend end
			end
		end
	end

	if lord and self:isFriend(lord) and sget(lord,"hasSkill","hunzi") and sget(lord,"getHp") == 2 and
	sget(lord,"getMark","hunzi") == 0	and lord:objectName() ~= self.player:objectName() then
		local enemycount = self:getEnemyNumBySeat(self.player, lord)
		local peaches = self:getAllPeachNum()
		if peaches >= enemycount then
			local f_target, e_target
			for _, ap in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if ap:objectName() ~= lord:objectName() and sget(ap,"isMale") and
					self:hasTrickEffective(duel, lord, ap) then
					if self:hasSkills("jiang|nosjizhi|jizhi", ap) and self:isFriend(ap) and
					not ap:isLocked(duel) then
						if not use.isDummy then self:setStrategyPlayerFlag(lord,"AIGlobal_NeedToWake",true) end
						return lord, ap
					elseif self:isFriend(ap) then
						f_target = ap
					else
						e_target = ap
					end
				end
			end
			if f_target or e_target then
				local target
				if f_target and not f_target:isLocked(duel) then
					target = f_target
				elseif e_target and not e_target:isLocked(duel) then
					target = e_target
				end
				if target then
					if not use.isDummy then self:setStrategyPlayerFlag(lord,"AIGlobal_NeedToWake",true) end
					return lord, target
				end
			end
		end
	end

	local shenguanyu = self.room:findPlayerBySkillName("wuhun")
	if shenguanyu and sget(shenguanyu,"isMale") and shenguanyu:objectName() ~= self.player:objectName() then
		if self.role == "rebel" and lord and sget(lord,"isMale") and lord:objectName() ~= self.player:objectName()
			and not sget(lord,"hasSkill","jueqing") and self:hasTrickEffective(duel, shenguanyu, lord) then
			return shenguanyu, lord
		elseif self:isEnemy(shenguanyu) and #self.enemies >= 2 then
			for _, enemy in ipairs(self.enemies) do
				if enemy:objectName() ~= shenguanyu:objectName() and sget(enemy,"isMale") and not enemy:isLocked(duel)
					and self:hasTrickEffective(duel, shenguanyu, enemy) then
					return shenguanyu, enemy
				end
			end
		end
	end

	if not self.player:hasUsed(card_name) then
		self.enemies = self:sort(self.enemies, "defense")
		local males, others = {}, {}
		local first, second
		local zhugeliang_kongcheng, xunyu

		for _, enemy in ipairs(self.enemies) do
			if sget(enemy,"isMale") and not self:hasSkills("wuyan|noswuyan", enemy) then
				if sget(enemy,"hasSkill","kongcheng") and enemy:isKongcheng() then zhugeliang_kongcheng = enemy
				elseif sget(enemy,"hasSkill","jieming") then xunyu = enemy
				else
					for _, anotherenemy in ipairs(self.enemies) do
						if sget(anotherenemy,"isMale") and anotherenemy:objectName() ~= enemy:objectName() then
							if #males == 0 and self:hasTrickEffective(duel, enemy, anotherenemy) then
								if not (sget(enemy,"hasSkill","hunzi") and sget(enemy,"getMark","hunzi") < 1 and
									sget(enemy,"getHp") == 2) then
									table.insert(males, enemy)
								else
									table.insert(others, enemy)
								end
							end
							if #males == 1 and self:hasTrickEffective(duel, males[1], anotherenemy) then
								if not anotherenemy:hasSkills("nosjizhi|jizhi|jiang") then
									table.insert(males, anotherenemy)
								else
									table.insert(others, anotherenemy)
								end
								if #males >= 2 then break end
							end
						end
					end
				end
				if #males >= 2 then break end
			end
		end

		if #males >= 1 and self:getRoleEstimate(males[1]) == "rebel" and sget(males[1],"getHp") == 1 then
			if lord and self:isFriend(lord) and sget(lord,"isMale") and lord:objectName() ~= males[1]:objectName() and
			self:hasTrickEffective(duel, males[1], lord)
				and not lord:isLocked(duel) and lord:objectName() ~= self.player:objectName() and lord:isAlive()
				and (getCardsNum("Slash", males[1]) < 1
					or getCardsNum("Slash", males[1]) < getCardsNum("Slash", lord)
					or self:getKnownNum(males[1]) == sget(males[1],"getHandcardNum") and
					getKnownCard(males[1], "Slash", true, "he") == 0)
				then
				return males[1], lord
			end

			local afriend = findFriend_maxSlash(self, males[1])
			if afriend and afriend:objectName() ~= males[1]:objectName() then
				return males[1], afriend
			end
		end

		if #males == 1 then
			if isLord(males[1]) and known(self.world.turn_count,"turn count") <= 1 and self.role == "rebel" and
				self.player:aliveCount() >= 3 then
				local p_slash, max_p, max_pp = 0
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if sget(p,"isMale") and not self:isFriend(p) and p:objectName() ~= males[1]:objectName()
					and self:hasTrickEffective(duel, males[1], p) and not p:isLocked(duel)
						and p_slash < getCardsNum("Slash", p) then
						if sget(p,"getKingdom") == sget(males[1],"getKingdom") then
							max_p = p
							break
						elseif not max_pp then
							max_pp = p
						end
					end
				end
				if max_p then table.insert(males, max_p) end
				if max_pp and #males == 1 then table.insert(males, max_pp) end
			end
		end

		if #males == 1 then
			if #others >= 1 and not others[1]:isLocked(duel) then
				table.insert(males, others[1])
			elseif xunyu and not xunyu:isLocked(duel) then
				if getCardsNum("Slash", males[1]) < 1 then
					table.insert(males, xunyu)
				else
					local drawcards = 0
					for _, enemy in ipairs(self.enemies) do
						local x = sget(enemy,"getMaxHp") > sget(enemy,"getHandcardNum") and
						 math.min(5, sget(enemy,"getMaxHp") - sget(enemy,"getHandcardNum")) or 0
						if x > drawcards then drawcards = x end
					end
					if drawcards <= 2 then
						table.insert(males, xunyu)
					end
				end
			end
		end

		if #males == 1 and #self.friends_noself > 0 then
			self:log("Only 1")
			first = males[1]
			if zhugeliang_kongcheng and self:hasTrickEffective(duel, first, zhugeliang_kongcheng) then
				table.insert(males, zhugeliang_kongcheng)
			else
				local friend_maxSlash = findFriend_maxSlash(self, first)
				if friend_maxSlash then table.insert(males, friend_maxSlash) end
			end
		end

		if #males >= 2 then
			first = males[1]
			second = males[2]
			if lord and sget(first,"getHp") <= 1 then
				if sget(self.player,"isLord") or self:isRolePredictable() then
					local friend_maxSlash = findFriend_maxSlash(self, first)
					if friend_maxSlash then second = friend_maxSlash end
				elseif sget(lord,"isMale") and not self:hasSkills("wuyan|noswuyan", lord) then
					if self.role=="rebel" and not sget(first,"isLord") and self:hasTrickEffective(duel, first, lord) then
						second = lord
					else
						if ( (self.role == "loyalist" or self.role == "renegade") and
							not self:hasSkills("ganglie|enyuan|neoganglie|nosenyuan", first) )
							and ( getCardsNum("Slash", first) <= getCardsNum("Slash", second) ) then
							second = lord
						end
					end
				end
			end

			if first and second and first:objectName() ~= second:objectName() and not second:isLocked(duel) then
				return first, second
			end
		end
	end
end

sgs.ai_fill_skill["sr_lijian"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_lijiancard") or self.player:isNude() then
		return
	end
	local card_id = getLijianCard(self)
	if card_id then return policy(self,"#sr_lijiancard:" .. card_id..":") end
end

sgs.ai_skill_use_func["#sr_lijiancard"] = function(card, use, self)
	local first, second = findLijianTarget(self,"#sr_lijiancard", use)
	if first and second then
		use.card = card
		if use.to then
			use.to:append(first)
			use.to:append(second)
		end
	end
end

sgs.ai_use_value["#sr_lijiancard"] = 8.5
sgs.ai_use_priority["#sr_lijiancard"] = 4

local lijian_filter = function(self, player, carduse)
	if sget(carduse.card,"isKindOf","#sr_lijiancard") then
		self:setCommonEventMemory("ai_lijian_effect",true)
	end
end

table.insert(sgs.ai_choicemade_filter.cardUsed, lijian_filter)

sgs.ai_card_intention["#sr_lijiancard"] = function(self, card, from, to)
	if self:getRoleEstimate(to[1]) == self:getRoleEstimate(to[2]) then
		if self:getRoleEstimate(from) == "rebel" and
			self:getRoleEstimate(to[1]) == self:getRoleEstimate(from) and sget(to[1],"getHp") == 1 then
		elseif sget(to[1],"hasSkill","hunzi") and sget(to[1],"getHp") == 2 and sget(to[1],"getMark","hunzi") == 0 then
		else
			self:updateIntentions(from, to, 40)
		end
	elseif self:getRoleEstimate(to[1]) ~= self:getRoleEstimate(to[2]) and not sget(to[1],"hasSkill","wuhun") then
		self:updateIntention(from, to[1], 80)
	end
end

sgs.dynamic_value.damage_card["#sr_lijiancard"] = true

sgs.ai_fill_skill["sr_manwu"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_manwucard") then return nil end
	local cando = false
	for _, p in ipairs(self.enemies) do
		if sget(p,"isMale") and not p:isKongcheng() then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return policy(self,"#sr_manwucard:.:")
end

sgs.ai_skill_use_func["#sr_manwucard"] = function(card, use, self)
	local enemies = {}
	for _, p in ipairs(self.enemies) do
		if sget(p,"isMale") and not p:isKongcheng() then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return end
	enemies = self:sort(enemies,"defense")
	use.card = card
	if use.to then
		use.to:append(enemies[1])
	end
end

sgs.ai_fill_skill["sr_xingyi"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_xingyicard") then return nil end
	local cando = false
	for _, p in ipairs(self.friends_noself) do
		if not p:isKongcheng() and sget(p,"isWounded") then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return policy(self,"#sr_xingyicard:.:")
end

sgs.ai_skill_use_func["#sr_xingyicard"] = function(card, use, self)
	local friends = {}
	for _, p in ipairs(self.friends_noself) do
		if not p:isKongcheng() and sget(p,"isWounded") then
			table.insert(friends,p)
		end
	end
	if #friends > 0 then
		friends = self:sort(friends,"defense")
		use.card = card
		if use.to then
			use.to:append(friends[1])
		end
		return
	end
	return
end
sgs.ai_skill_invoke["sr_guagu"] = function(self,data)
	local dying = data:toDying()
	if self:isFriend(dying.who) then return true end
	if source_role(self,self.player) == "renegade" and sget(dying.who,"isLord") and
		self.room:getAlivePlayers():length()>2 then return true end
	return false
end

sgs.ai_skill_cardask["srwuqindiscard"]=function(self, data, pattern, target, target2)
	local dis = {}
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if sget(c,"isKindOf","BasicCard") then
			table.insert(dis,c)
		end
	end
	if #dis == 0 then return "." end
	if #dis == 1 and (sget(dis[1],"isKindOf","Peach") or sget(dis[1],"isKindOf","Analeptic")) then return "." end
	dis = self:sortByKeepValue(dis)
	return "$"..sget(dis[1],"getEffectiveId")
end
sgs.ai_skill_choice["sr_wuqin"] = function(self,choices,data)
	if self:isWeak() or sget(self.player,"getHandcardNum") <=2 then return "srwuqindraw" end
	return "srwuqinplay"
end

sgs.ai_fill_skill["sr_jiwu"] = function(self,inclusive,request)
	if self.player:hasUsed("#sr_jiwucard") then return nil end
	if not fact(self,"slash_available") and sget(self.player,"getHandcardNum") > 0 then return nil end
	if #self.enemies==0 and sget(self.player,"getHandcardNum") > 0 then return nil end
	return policy(self,"#sr_jiwucard:.:")
end

sgs.ai_skill_use_func["#sr_jiwucard"] = function(card, use, self)
	local can_jiwu = self:getCardsNum("Slash") > 0 or self.player:isKongcheng()
	if not can_jiwu then return nil end
	use.card = card
end

sgs.ai_skill_use["@@jiwu_extarget"] = function(self, prompt, method)
	local use = fact_use(self,"jiwu_use")
	local slash = use.card
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "defenseSlash")
	local targets = {}
	for _, target in ipairs(self.enemies) do
		if (not self:slashProhibit(slash, target)) and self:isGoodTarget(target, self.enemies, nil) and self:slashIsEffective(slash, target) and sget(target,"getMark","jiwu_target") == 0 and sget(target,"getMark","jiwu_nil") == 0 then
			table.insert(targets, target:objectName())
		end
	end
	if #targets > 0 then
		return "#jiwu_extarget:.:->" .. table.concat(targets, "+")
	else
		return "."
	end
end

sgs.ai_skill_discard.sr_jiwu = function(self, discard_num, min_num, optional, include_equip)
	local slash = nil
	local to_discard = {}
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if sget(c,"isKindOf","Slash") and not slash then
			slash = c
		else
			table.insert(to_discard,sget(c,"getEffectiveId"))
			if #to_discard == sget(self.player,"getHandcardNum") - 1 then break end
		end
	end
	return to_discard
end


sgs.ai_use_priority["sr_jiwucard"] = sgs.ai_use_priority.Analeptic - 0.1
sgs.ai_use_value["sr_jiwucard"] = 9
sgs.ai_cardneed.sr_jiwu = sgs.ai_cardneed.slash
sgs.ai_ajustdamage_from.sr_jiwu   = function(self, from, to, card, nature)
	if card and sget(card,"isKindOf","Slash") and sget(from,"getMark","jiwu_slashdamage") > 0 then
		return 1
	end
end
sgs.ai_card_priority.sr_jiwu = function(self,card,v)
	if self.useValue
	and sget(card,"isKindOf","Weapon")
	then v = 2 end
end


sgs.ai_skill_invoke["sr_sheji"] = function(self,data)
	local damage = data:toDamage()
	return self:isEnemy(damage.from)  or hasSilverLionEffect(self,self.player)
end

sgs.ai_fill_skill["sr_sheji"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local equip_card

	cards = self:sortByUseValue(cards,true)
	for _,card in ipairs(cards)  do
		if sget(card,"isKindOf","Crossbow") and self.room:getCardPlace(card:getId()) ==sgs.Player_PlaceEquip then
			if self.player:canSlashWithoutCrossbow() then
				equip_card = card
				break
			end
		else
			if sget(card,"isKindOf","EquipCard") then
				equip_card = card
				break
			end
		end
	end

	if not equip_card then return nil end
	local suit = sget(equip_card,"getSuitString")
	local number = equip_card:getNumberString()
	local card_id = sget(equip_card,"getEffectiveId")
	local card_str = ("slash:sr_sheji[%s:%s]=%d"):format(suit, number, card_id)
	local slash = policy(self,card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as["sr_sheji"] = function(card, player, card_place)
	local suit = sget(card,"getSuitString")
	local number = card:getNumberString()
	local card_id = sget(card,"getEffectiveId")
	if sget(card,"isKindOf","EquipCard") then
		return ("slash:sr_sheji[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.sr_sheji_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.7,
	Slash = 5.6,
	ThunderSlash = 5.5,
	ExNihilo = 4.7,
	EquipCard = 5.9,
}
sgs.hit_skill = sgs.hit_skill .. "|sr_sheji"

sgs.ai_cardneed.sr_sheji = sgs.ai_cardneed.equip

local function wrap(f,key,kind)
 return function(...)
  local a=table.pack(...);local self
  for i=1,a.n do if type(a[i])=='table'and a[i].player and a[i].world and a[i].request then self=a[i];break end end
  if not self then return f(...)end
  local prior,request=self._srkill_key,self._srkill_request;self._srkill_key=key
  if kind=='ai_fill_skill'then self._srkill_request=a[3]end
  local r=table.pack(pcall(f,table.unpack(a,1,a.n)));self._srkill_key=prior;self._srkill_request=request
  if not r[1]then error(r[2],0)end
  if kind=='ai_skill_cardchosen'and key=='sr_lingbo'and self.request.kind=='card_chosen'
   and self.request.options and self.request.options.reason=='sr_lingbo'then
   -- srkill.lua5221..22 clears the two AI-only tags after this actual inquiry.
   self:setStrategyMemory('srkill.lingbocard',0);self:setStrategyMemory('srkill.lingboperson',false)
  end
  if kind=='ai_skill_use'then r[2]=response(self,r[2])
  elseif kind=='ai_cardsview_valuable'and type(r[2])=='string'then
   local cl,sk,cs,u=decode(r[2]);r[2]={skill=sk,legacy_class=cl,subcards=cs};if u then r[2].user_string=u end
  end
  return table.unpack(r,2,r.n)
 end
end
sgs.ai_skill_choice['lose_a_sk']=wrap(sgs.ai_skill_choice['lose_a_sk'],'lose_a_sk','ai_skill_choice')
sgs.ai_skill_invoke['sr_rende']=wrap(sgs.ai_skill_invoke['sr_rende'],'sr_rende','ai_skill_invoke')
sgs.ai_skill_askforyiji['sr_rende']=wrap(sgs.ai_skill_askforyiji['sr_rende'],'sr_rende','ai_skill_askforyiji')
sgs.ai_fill_skill['sr_chouxi']=wrap(sgs.ai_fill_skill['sr_chouxi'],'sr_chouxi','ai_fill_skill')
sgs.ai_skill_use_func['#sr_chouxicard']=wrap(sgs.ai_skill_use_func['#sr_chouxicard'],'#sr_chouxicard','ai_skill_use_func')
sgs.ai_skill_playerchosen['sr_chouxi']=wrap(sgs.ai_skill_playerchosen['sr_chouxi'],'sr_chouxi','ai_skill_playerchosen')
sgs.ai_skill_cardask['@srchouxi-discard']=wrap(sgs.ai_skill_cardask['@srchouxi-discard'],'@srchouxi-discard','ai_skill_cardask')
sgs.ai_skill_playerchosen['sr_yongbing']=wrap(sgs.ai_skill_playerchosen['sr_yongbing'],'sr_yongbing','ai_skill_playerchosen')
sgs.ai_fill_skill['sr_shouji']=wrap(sgs.ai_fill_skill['sr_shouji'],'sr_shouji','ai_fill_skill')
sgs.ai_skill_use_func['#sr_shoujicard']=wrap(sgs.ai_skill_use_func['#sr_shoujicard'],'#sr_shoujicard','ai_skill_use_func')
sgs.ai_skill_playerchosen['sr_shouji']=wrap(sgs.ai_skill_playerchosen['sr_shouji'],'sr_shouji','ai_skill_playerchosen')
sgs.ai_skill_cardask['@sr_hemou']=wrap(sgs.ai_skill_cardask['@sr_hemou'],'@sr_hemou','ai_skill_cardask')
sgs.ai_fill_skill['sr_hemouvs']=wrap(sgs.ai_fill_skill['sr_hemouvs'],'sr_hemouvs','ai_fill_skill')
sgs.ai_skill_cardask['@srbenxi-discard']=wrap(sgs.ai_skill_cardask['@srbenxi-discard'],'@srbenxi-discard','ai_skill_cardask')
sgs.ai_fill_skill['sr_yaozhan']=wrap(sgs.ai_fill_skill['sr_yaozhan'],'sr_yaozhan','ai_fill_skill')
sgs.ai_skill_use_func['#sr_yaozhancard']=wrap(sgs.ai_skill_use_func['#sr_yaozhancard'],'#sr_yaozhancard','ai_skill_use_func')
sgs.ai_fill_skill['sr_wenjiu']=wrap(sgs.ai_fill_skill['sr_wenjiu'],'sr_wenjiu','ai_fill_skill')
sgs.ai_skill_use_func['#sr_wenjiucard']=wrap(sgs.ai_skill_use_func['#sr_wenjiucard'],'#sr_wenjiucard','ai_skill_use_func')
sgs.ai_skill_invoke['sr_wenjiu']=wrap(sgs.ai_skill_invoke['sr_wenjiu'],'sr_wenjiu','ai_skill_invoke')
sgs.ai_ajustdamage_from['sr_wenjiu']=wrap(sgs.ai_ajustdamage_from['sr_wenjiu'],'sr_wenjiu','ai_ajustdamage_from')
sgs.ai_skill_use['@@sr_shuixi']=wrap(sgs.ai_skill_use['@@sr_shuixi'],'@@sr_shuixi','ai_skill_use')
sgs.ai_skill_cardask['@srshuixithrow']=wrap(sgs.ai_skill_cardask['@srshuixithrow'],'@srshuixithrow','ai_skill_cardask')
sgs.ai_fill_skill['sr_sanfen']=wrap(sgs.ai_fill_skill['sr_sanfen'],'sr_sanfen','ai_fill_skill')
sgs.ai_skill_use_func['#sr_sanfencard']=wrap(sgs.ai_skill_use_func['#sr_sanfencard'],'#sr_sanfencard','ai_skill_use_func')
sgs.ai_ajustdamage_to['sr_weiwo']=wrap(sgs.ai_ajustdamage_to['sr_weiwo'],'sr_weiwo','ai_ajustdamage_to')
sgs.ai_skill_invoke['sr_xujin']=wrap(sgs.ai_skill_invoke['sr_xujin'],'sr_xujin','ai_skill_invoke')
sgs.ai_skill_playerchosen['sr_xujin']=wrap(sgs.ai_skill_playerchosen['sr_xujin'],'sr_xujin','ai_skill_playerchosen')
sgs.ai_skill_invoke['sr_paoxiao']=wrap(sgs.ai_skill_invoke['sr_paoxiao'],'sr_paoxiao','ai_skill_invoke')
sgs.ai_skill_cardask['@sr_jiuzhu']=wrap(sgs.ai_skill_cardask['@sr_jiuzhu'],'@sr_jiuzhu','ai_skill_cardask')
sgs.ai_skill_invoke['sr_jiuzhu']=wrap(sgs.ai_skill_invoke['sr_jiuzhu'],'sr_jiuzhu','ai_skill_invoke')
sgs.ai_skill_cardask['@sr_tuwei']=wrap(sgs.ai_skill_cardask['@sr_tuwei'],'@sr_tuwei','ai_skill_cardask')
sgs.ai_fill_skill['sr_quanheng']=wrap(sgs.ai_fill_skill['sr_quanheng'],'sr_quanheng','ai_fill_skill')
sgs.ai_skill_use_func['#sr_quanhengCard']=wrap(sgs.ai_skill_use_func['#sr_quanhengCard'],'#sr_quanhengCard','ai_skill_use_func')
sgs.ai_skill_use['@@sr_quanheng_slash']=wrap(sgs.ai_skill_use['@@sr_quanheng_slash'],'@@sr_quanheng_slash','ai_skill_use')
sgs.ai_skill_use['@@sr_quanheng_ex_nihilo']=wrap(sgs.ai_skill_use['@@sr_quanheng_ex_nihilo'],'@@sr_quanheng_ex_nihilo','ai_skill_use')
sgs.ai_skill_choice['sr_quanheng']=wrap(sgs.ai_skill_choice['sr_quanheng'],'sr_quanheng','ai_skill_choice')
sgs.ai_fill_skill['sr_xionglve']=wrap(sgs.ai_fill_skill['sr_xionglve'],'sr_xionglve','ai_fill_skill')
sgs.ai_skill_use_func['#sr_xionglvecard']=wrap(sgs.ai_skill_use_func['#sr_xionglvecard'],'#sr_xionglvecard','ai_skill_use_func')
sgs.ai_skill_askforag['sr_xionglvecard']=wrap(sgs.ai_skill_askforag['sr_xionglvecard'],'sr_xionglvecard','ai_skill_askforag')
sgs.ai_skill_choice['sr_xionglvebasic']=wrap(sgs.ai_skill_choice['sr_xionglvebasic'],'sr_xionglvebasic','ai_skill_choice')
sgs.ai_skill_playerchosen['sr_xionglveslash']=wrap(sgs.ai_skill_playerchosen['sr_xionglveslash'],'sr_xionglveslash','ai_skill_playerchosen')
sgs.ai_skill_choice['sr_xionglvetrick']=wrap(sgs.ai_skill_choice['sr_xionglvetrick'],'sr_xionglvetrick','ai_skill_choice')
sgs.ai_skill_playerchosen['sr_xionglvetiesuo']=wrap(sgs.ai_skill_playerchosen['sr_xionglvetiesuo'],'sr_xionglvetiesuo','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['sr_xionglvejiedao']=wrap(sgs.ai_skill_playerchosen['sr_xionglvejiedao'],'sr_xionglvejiedao','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['sr_xionglvejiedao1']=wrap(sgs.ai_skill_playerchosen['sr_xionglvejiedao1'],'sr_xionglvejiedao1','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['sr_xionglvehuogong']=wrap(sgs.ai_skill_playerchosen['sr_xionglvehuogong'],'sr_xionglvehuogong','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['sr_xionglveshunshou']=wrap(sgs.ai_skill_playerchosen['sr_xionglveshunshou'],'sr_xionglveshunshou','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['sr_xionglveguohe']=wrap(sgs.ai_skill_playerchosen['sr_xionglveguohe'],'sr_xionglveguohe','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['sr_xionglvejuedou']=wrap(sgs.ai_skill_playerchosen['sr_xionglvejuedou'],'sr_xionglvejuedou','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['sr_xionglveequip']=wrap(sgs.ai_skill_playerchosen['sr_xionglveequip'],'sr_xionglveequip','ai_skill_playerchosen')
sgs.ai_skill_invoke['sr_xionglve']=wrap(sgs.ai_skill_invoke['sr_xionglve'],'sr_xionglve','ai_skill_invoke')
sgs.ai_skill_askforag['sr_xionglve']=wrap(sgs.ai_skill_askforag['sr_xionglve'],'sr_xionglve','ai_skill_askforag')
sgs.ai_skill_use['@@sr_fuzheng']=wrap(sgs.ai_skill_use['@@sr_fuzheng'],'@@sr_fuzheng','ai_skill_use')
sgs.ai_skill_discard['sr_fuzheng1']=wrap(sgs.ai_skill_discard['sr_fuzheng1'],'sr_fuzheng1','ai_skill_discard')
sgs.ai_skill_discard['sr_fuzheng2']=wrap(sgs.ai_skill_discard['sr_fuzheng2'],'sr_fuzheng2','ai_skill_discard')
sgs.ai_fill_skill['sr_dailao']=wrap(sgs.ai_fill_skill['sr_dailao'],'sr_dailao','ai_fill_skill')
sgs.ai_skill_use_func['#sr_dailaocard']=wrap(sgs.ai_skill_use_func['#sr_dailaocard'],'#sr_dailaocard','ai_skill_use_func')
sgs.ai_skill_choice['sr_dailao']=wrap(sgs.ai_skill_choice['sr_dailao'],'sr_dailao','ai_skill_choice')
sgs.ai_skill_invoke['sr_youdi']=wrap(sgs.ai_skill_invoke['sr_youdi'],'sr_youdi','ai_skill_invoke')
sgs.ai_skill_use['@@sr_youdi']=wrap(sgs.ai_skill_use['@@sr_youdi'],'@@sr_youdi','ai_skill_use')
sgs.ai_skill_invoke['sr_ruya']=wrap(sgs.ai_skill_invoke['sr_ruya'],'sr_ruya','ai_skill_invoke')
sgs.ai_fill_skill['sr_weibao']=wrap(sgs.ai_fill_skill['sr_weibao'],'sr_weibao','ai_fill_skill')
sgs.ai_skill_use_func['#sr_weibaocard']=wrap(sgs.ai_skill_use_func['#sr_weibaocard'],'#sr_weibaocard','ai_skill_use_func')
sgs.ai_skill_playerchosen['sr_weibao']=wrap(sgs.ai_skill_playerchosen['sr_weibao'],'sr_weibao','ai_skill_playerchosen')
sgs.ai_fill_skill['sr_choulve']=wrap(sgs.ai_fill_skill['sr_choulve'],'sr_choulve','ai_fill_skill')
sgs.ai_skill_use_func['#sr_choulvecard']=wrap(sgs.ai_skill_use_func['#sr_choulvecard'],'#sr_choulvecard','ai_skill_use_func')
sgs.ai_skill_discard['sr_choulve1']=wrap(sgs.ai_skill_discard['sr_choulve1'],'sr_choulve1','ai_skill_discard')
sgs.ai_skill_discard['sr_choulve2']=wrap(sgs.ai_skill_discard['sr_choulve2'],'sr_choulve2','ai_skill_discard')
sgs.ai_skill_invoke['sr_shixue']=wrap(sgs.ai_skill_invoke['sr_shixue'],'sr_shixue','ai_skill_invoke')
sgs.ai_skill_invoke['sr_guoshibegin']=wrap(sgs.ai_skill_invoke['sr_guoshibegin'],'sr_guoshibegin','ai_skill_invoke')
sgs.ai_skill_invoke['sr_guoshiend']=wrap(sgs.ai_skill_invoke['sr_guoshiend'],'sr_guoshiend','ai_skill_invoke')
sgs.ai_fill_skill['sr_jiexi']=wrap(sgs.ai_fill_skill['sr_jiexi'],'sr_jiexi','ai_fill_skill')
sgs.ai_skill_use_func['#sr_jiexicard']=wrap(sgs.ai_skill_use_func['#sr_jiexicard'],'#sr_jiexicard','ai_skill_use_func')
sgs.ai_skill_invoke['sr_jiexi']=wrap(sgs.ai_skill_invoke['sr_jiexi'],'sr_jiexi','ai_skill_invoke')
sgs.ai_fill_skill['sr_youxia']=wrap(sgs.ai_fill_skill['sr_youxia'],'sr_youxia','ai_fill_skill')
sgs.ai_skill_use_func['#sr_youxiacard']=wrap(sgs.ai_skill_use_func['#sr_youxiacard'],'#sr_youxiacard','ai_skill_use_func')
sgs.ai_fill_skill['sr_zhouyan']=wrap(sgs.ai_fill_skill['sr_zhouyan'],'sr_zhouyan','ai_fill_skill')
sgs.ai_skill_use_func['#sr_zhouyancard']=wrap(sgs.ai_skill_use_func['#sr_zhouyancard'],'#sr_zhouyancard','ai_skill_use_func')
sgs.ai_skill_invoke['sr_zhouyan_draw']=wrap(sgs.ai_skill_invoke['sr_zhouyan_draw'],'sr_zhouyan_draw','ai_skill_invoke')
sgs.ai_skill_invoke['sr_zhouyan']=wrap(sgs.ai_skill_invoke['sr_zhouyan'],'sr_zhouyan','ai_skill_invoke')
sgs.ai_fill_skill['sr_zhaxiang']=wrap(sgs.ai_fill_skill['sr_zhaxiang'],'sr_zhaxiang','ai_fill_skill')
sgs.ai_skill_use_func['#sr_zhaxiangcard']=wrap(sgs.ai_skill_use_func['#sr_zhaxiangcard'],'#sr_zhaxiangcard','ai_skill_use_func')
sgs.ai_skill_playerchosen['sr_zhaxiang']=wrap(sgs.ai_skill_playerchosen['sr_zhaxiang'],'sr_zhaxiang','ai_skill_playerchosen')
sgs.ai_skill_choice['sr_zhaxiang']=wrap(sgs.ai_skill_choice['sr_zhaxiang'],'sr_zhaxiang','ai_skill_choice')
sgs.ai_skill_discard['sr_zhaxiang']=wrap(sgs.ai_skill_discard['sr_zhaxiang'],'sr_zhaxiang','ai_skill_discard')
sgs.ai_fill_skill['sr_fangxin']=wrap(sgs.ai_fill_skill['sr_fangxin'],'sr_fangxin','ai_fill_skill')
sgs.ai_skill_use_func['#sr_fangxincard']=wrap(sgs.ai_skill_use_func['#sr_fangxincard'],'#sr_fangxincard','ai_skill_use_func')
sgs.ai_cardsview_valuable['sr_fangxin']=wrap(sgs.ai_cardsview_valuable['sr_fangxin'],'sr_fangxin','ai_cardsview_valuable')
sgs.ai_skill_invoke['sr_xiyu']=wrap(sgs.ai_skill_invoke['sr_xiyu'],'sr_xiyu','ai_skill_invoke')
sgs.ai_skill_playerchosen['sr_xiyu']=wrap(sgs.ai_skill_playerchosen['sr_xiyu'],'sr_xiyu','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['sr_wanrou']=wrap(sgs.ai_skill_playerchosen['sr_wanrou'],'sr_wanrou','ai_skill_playerchosen')
sgs.ai_fill_skill['sr_yinmeng']=wrap(sgs.ai_fill_skill['sr_yinmeng'],'sr_yinmeng','ai_fill_skill')
sgs.ai_skill_use_func['#sr_yinmengcard']=wrap(sgs.ai_skill_use_func['#sr_yinmengcard'],'#sr_yinmengcard','ai_skill_use_func')
sgs.ai_cardshow['sr_yinmeng']=wrap(sgs.ai_cardshow['sr_yinmeng'],'sr_yinmeng','ai_cardshow')
sgs.ai_fill_skill['sr_juelie']=wrap(sgs.ai_fill_skill['sr_juelie'],'sr_juelie','ai_fill_skill')
sgs.ai_skill_use_func['#sr_jueliecard']=wrap(sgs.ai_skill_use_func['#sr_jueliecard'],'#sr_jueliecard','ai_skill_use_func')
sgs.ai_skill_choice['sr_juelie']=wrap(sgs.ai_skill_choice['sr_juelie'],'sr_juelie','ai_skill_choice')
sgs.ai_skill_invoke['sr_zhaoxiang']=wrap(sgs.ai_skill_invoke['sr_zhaoxiang'],'sr_zhaoxiang','ai_skill_invoke')
sgs.ai_skill_cardask['srzhaoxiangdiscard']=wrap(sgs.ai_skill_cardask['srzhaoxiangdiscard'],'srzhaoxiangdiscard','ai_skill_cardask')
sgs.ai_skill_choice['sr_zhaoxiang']=wrap(sgs.ai_skill_choice['sr_zhaoxiang'],'sr_zhaoxiang','ai_skill_choice')
sgs.ai_fill_skill['sr_zhishi']=wrap(sgs.ai_fill_skill['sr_zhishi'],'sr_zhishi','ai_fill_skill')
sgs.ai_skill_use_func['#sr_zhishicard']=wrap(sgs.ai_skill_use_func['#sr_zhishicard'],'#sr_zhishicard','ai_skill_use_func')
sgs.ai_skill_cardask['#srbasic']=wrap(sgs.ai_skill_cardask['#srbasic'],'#srbasic','ai_skill_cardask')
sgs.ai_skill_playerchosen['sr_jianxiong']=wrap(sgs.ai_skill_playerchosen['sr_jianxiong'],'sr_jianxiong','ai_skill_playerchosen')
sgs.ai_skill_invoke['sr_tianshang']=wrap(sgs.ai_skill_invoke['sr_tianshang'],'sr_tianshang','ai_skill_invoke')
sgs.ai_skill_playerchosen['sr_tianshang']=wrap(sgs.ai_skill_playerchosen['sr_tianshang'],'sr_tianshang','ai_skill_playerchosen')
sgs.ai_skill_choice['sr_tianshang']=wrap(sgs.ai_skill_choice['sr_tianshang'],'sr_tianshang','ai_skill_choice')
sgs.ai_skill_invoke['sr_yiji']=wrap(sgs.ai_skill_invoke['sr_yiji'],'sr_yiji','ai_skill_invoke')
sgs.ai_skill_askforyiji['sr_yiji']=wrap(sgs.ai_skill_askforyiji['sr_yiji'],'sr_yiji','ai_skill_askforyiji')
sgs.ai_need_damaged['sr_yiji']=wrap(sgs.ai_need_damaged['sr_yiji'],'sr_yiji','ai_need_damaged')
sgs.ai_skill_invoke['sr_huiqu']=wrap(sgs.ai_skill_invoke['sr_huiqu'],'sr_huiqu','ai_skill_invoke')
sgs.ai_skill_playerchosen['sr_huiqudamage']=wrap(sgs.ai_skill_playerchosen['sr_huiqudamage'],'sr_huiqudamage','ai_skill_playerchosen')
sgs.ai_skill_cardchosen['sr_huiqu']=wrap(sgs.ai_skill_cardchosen['sr_huiqu'],'sr_huiqu','ai_skill_cardchosen')
sgs.ai_skill_playerchosen['sr_huiqufirst']=wrap(sgs.ai_skill_playerchosen['sr_huiqufirst'],'sr_huiqufirst','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['sr_huiqu']=wrap(sgs.ai_skill_playerchosen['sr_huiqu'],'sr_huiqu','ai_skill_playerchosen')
sgs.ai_fill_skill['sr_aozhan']=wrap(sgs.ai_fill_skill['sr_aozhan'],'sr_aozhan','ai_fill_skill')
sgs.ai_skill_use_func['#sr_aozhanCard']=wrap(sgs.ai_skill_use_func['#sr_aozhanCard'],'#sr_aozhanCard','ai_skill_use_func')
sgs.ai_skill_invoke['sr_aozhan']=wrap(sgs.ai_skill_invoke['sr_aozhan'],'sr_aozhan','ai_skill_invoke')
sgs.ai_skill_choice['sr_aozhan']=wrap(sgs.ai_skill_choice['sr_aozhan'],'sr_aozhan','ai_skill_choice')
sgs.ai_skill_invoke['sr_huxiao']=wrap(sgs.ai_skill_invoke['sr_huxiao'],'sr_huxiao','ai_skill_invoke')
sgs.ai_ajustdamage_from['sr_huxiao']=wrap(sgs.ai_ajustdamage_from['sr_huxiao'],'sr_huxiao','ai_ajustdamage_from')
sgs.ai_skill_invoke['sr_guicai']=wrap(sgs.ai_skill_invoke['sr_guicai'],'sr_guicai','ai_skill_invoke')
sgs.ai_skill_choice['sr_guicai']=wrap(sgs.ai_skill_choice['sr_guicai'],'sr_guicai','ai_skill_choice')
sgs.ai_skill_cardask['@guicai-card']=wrap(sgs.ai_skill_cardask['@guicai-card'],'@guicai-card','ai_skill_cardask')
sgs.ai_skill_invoke['sr_langgu']=wrap(sgs.ai_skill_invoke['sr_langgu'],'sr_langgu','ai_skill_invoke')
sgs.ai_skill_invoke['sr_zhuizun']=wrap(sgs.ai_skill_invoke['sr_zhuizun'],'sr_zhuizun','ai_skill_invoke')
sgs.ai_canNiepan_skill['sr_zhuizun']=wrap(sgs.ai_canNiepan_skill['sr_zhuizun'],'sr_zhuizun','ai_canNiepan_skill')
sgs.ai_fill_skill['sr_liuyun']=wrap(sgs.ai_fill_skill['sr_liuyun'],'sr_liuyun','ai_fill_skill')
sgs.ai_skill_use_func['#sr_liuyuncard']=wrap(sgs.ai_skill_use_func['#sr_liuyuncard'],'#sr_liuyuncard','ai_skill_use_func')
sgs.ai_skill_choice['sr_liuyun']=wrap(sgs.ai_skill_choice['sr_liuyun'],'sr_liuyun','ai_skill_choice')
sgs.ai_skill_invoke['sr_lingbo']=wrap(sgs.ai_skill_invoke['sr_lingbo'],'sr_lingbo','ai_skill_invoke')
sgs.ai_skill_playerchosen['sr_lingbo']=wrap(sgs.ai_skill_playerchosen['sr_lingbo'],'sr_lingbo','ai_skill_playerchosen')
sgs.ai_skill_cardchosen['sr_lingbo']=wrap(sgs.ai_skill_cardchosen['sr_lingbo'],'sr_lingbo','ai_skill_cardchosen')
sgs.ai_fill_skill['sr_qingcheng']=wrap(sgs.ai_fill_skill['sr_qingcheng'],'sr_qingcheng','ai_fill_skill')
sgs.ai_skill_use_func['#sr_qingchengcard']=wrap(sgs.ai_skill_use_func['#sr_qingchengcard'],'#sr_qingchengcard','ai_skill_use_func')
sgs.ai_cardsview_valuable['sr_qingcheng']=wrap(sgs.ai_cardsview_valuable['sr_qingcheng'],'sr_qingcheng','ai_cardsview_valuable')
sgs.ai_skill_choice['sr_xiahouhelp']=wrap(sgs.ai_skill_choice['sr_xiahouhelp'],'sr_xiahouhelp','ai_skill_choice')
sgs.ai_fill_skill['sr_xiahou']=wrap(sgs.ai_fill_skill['sr_xiahou'],'sr_xiahou','ai_fill_skill')
sgs.ai_skill_use_func['#sr_xiahoucard']=wrap(sgs.ai_skill_use_func['#sr_xiahoucard'],'#sr_xiahoucard','ai_skill_use_func')
sgs.ai_skill_choice['sr_xiahou']=wrap(sgs.ai_skill_choice['sr_xiahou'],'sr_xiahou','ai_skill_choice')
sgs.ai_skill_choice['sr_xiahouresponse']=wrap(sgs.ai_skill_choice['sr_xiahouresponse'],'sr_xiahouresponse','ai_skill_choice')
sgs.ai_skill_choice['sr_xiahousave']=wrap(sgs.ai_skill_choice['sr_xiahousave'],'sr_xiahousave','ai_skill_choice')
sgs.ai_cardsview_valuable['sr_xiahou']=wrap(sgs.ai_cardsview_valuable['sr_xiahou'],'sr_xiahou','ai_cardsview_valuable')
sgs.ai_skill_playerchosen['sr_xiahou']=wrap(sgs.ai_skill_playerchosen['sr_xiahou'],'sr_xiahou','ai_skill_playerchosen')
sgs.ai_skill_invoke['sr_ganglie']=wrap(sgs.ai_skill_invoke['sr_ganglie'],'sr_ganglie','ai_skill_invoke')
sgs.ai_ajustdamage_from['sr_ganglie']=wrap(sgs.ai_ajustdamage_from['sr_ganglie'],'sr_ganglie','ai_ajustdamage_from')
sgs.ai_skill_invoke['sr_yansha']=wrap(sgs.ai_skill_invoke['sr_yansha'],'sr_yansha','ai_skill_invoke')
sgs.ai_skill_cardask['#sr_yansha']=wrap(sgs.ai_skill_cardask['#sr_yansha'],'#sr_yansha','ai_skill_cardask')
sgs.ai_fill_skill['sr_lijian']=wrap(sgs.ai_fill_skill['sr_lijian'],'sr_lijian','ai_fill_skill')
sgs.ai_skill_use_func['#sr_lijiancard']=wrap(sgs.ai_skill_use_func['#sr_lijiancard'],'#sr_lijiancard','ai_skill_use_func')
sgs.ai_card_intention['#sr_lijiancard']=wrap(sgs.ai_card_intention['#sr_lijiancard'],'#sr_lijiancard','ai_card_intention')
sgs.ai_fill_skill['sr_manwu']=wrap(sgs.ai_fill_skill['sr_manwu'],'sr_manwu','ai_fill_skill')
sgs.ai_skill_use_func['#sr_manwucard']=wrap(sgs.ai_skill_use_func['#sr_manwucard'],'#sr_manwucard','ai_skill_use_func')
sgs.ai_fill_skill['sr_xingyi']=wrap(sgs.ai_fill_skill['sr_xingyi'],'sr_xingyi','ai_fill_skill')
sgs.ai_skill_use_func['#sr_xingyicard']=wrap(sgs.ai_skill_use_func['#sr_xingyicard'],'#sr_xingyicard','ai_skill_use_func')
sgs.ai_skill_invoke['sr_guagu']=wrap(sgs.ai_skill_invoke['sr_guagu'],'sr_guagu','ai_skill_invoke')
sgs.ai_skill_cardask['srwuqindiscard']=wrap(sgs.ai_skill_cardask['srwuqindiscard'],'srwuqindiscard','ai_skill_cardask')
sgs.ai_skill_choice['sr_wuqin']=wrap(sgs.ai_skill_choice['sr_wuqin'],'sr_wuqin','ai_skill_choice')
sgs.ai_fill_skill['sr_jiwu']=wrap(sgs.ai_fill_skill['sr_jiwu'],'sr_jiwu','ai_fill_skill')
sgs.ai_skill_use_func['#sr_jiwucard']=wrap(sgs.ai_skill_use_func['#sr_jiwucard'],'#sr_jiwucard','ai_skill_use_func')
sgs.ai_skill_use['@@jiwu_extarget']=wrap(sgs.ai_skill_use['@@jiwu_extarget'],'@@jiwu_extarget','ai_skill_use')
sgs.ai_skill_discard['sr_jiwu']=wrap(sgs.ai_skill_discard['sr_jiwu'],'sr_jiwu','ai_skill_discard')
sgs.ai_ajustdamage_from['sr_jiwu']=wrap(sgs.ai_ajustdamage_from['sr_jiwu'],'sr_jiwu','ai_ajustdamage_from')
sgs.ai_card_priority['sr_jiwu']=wrap(sgs.ai_card_priority['sr_jiwu'],'sr_jiwu','ai_card_priority')
sgs.ai_skill_invoke['sr_sheji']=wrap(sgs.ai_skill_invoke['sr_sheji'],'sr_sheji','ai_skill_invoke')
sgs.ai_fill_skill['sr_sheji']=wrap(sgs.ai_fill_skill['sr_sheji'],'sr_sheji','ai_fill_skill')
do local f=sgs.ai_view_as['sr_sheji'];sgs.ai_view_as['sr_sheji']=function(...)return proposal(f(...))end end
