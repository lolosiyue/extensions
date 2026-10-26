-- Source: b6025acc ai/keguibao-ai.lua.
local known = AIValue.requireKnown

local function visible(self,id)
 local c=self:getKnownCardById(id);if not c and type(self.getChoiceCard)=='function'then c=self:getChoiceCard(id)end
 return known(c,'keguibao disclosed physical card')
end
local function copy(t) local r={} for k,v in pairs(t)do r[k]=type(v)=='table' and copy(v) or v end;return r end
local dummy_plan = AIUsePlan.dummy
local classes={['#keguixianjiCard']='keguixianjiVS',['#kejieguixianjiCard']='kejieguixianjiVS',['#keguitiqiCard']='keguitiqi',['#keguishouyeCard']='keguishouye',['#keguijiehuoCard']='keguijiehuo',['#kejieguishouyeCard']='kejieguishouye',['#kejieguijiehuoCard']='kejieguijiehuo',['#kejieguizhashiCard']='kejieguizhashi'}
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
 request=request or self._keguibao_request
 local row=printed_spec(text)
 if row then local base=known(self:getEvaluationCard(row.name),'printed prototype');local c=self:evaluateTurnConversion(row.skill,base:getClassName(),row,request);recipes[c]=row;return c end
 local cl,sk,cs,u=decode(text);local c=self:evaluateTurnSkillCard(sk,cl,cs,request,u);recipes[c]={prototype=cl,skill=sk,subcards=cs,user=u};return c
end
local function clone(self,name,suit,number,skill)
 local spec={source_key=self._keguibao_key or 'keguibao',name=name or 'slash',skill=skill or '',suit=suit or sgs.Card_NoSuit,number=number or 0,subcards={}}
 local c;if spec.skill=='' and spec.suit==sgs.Card_NoSuit and spec.number==0 then c=self:getEvaluationCard(spec.name) else c=self:evaluateOwnerViewAsCard(spec) end
 if c then recipes[c]=spec end;return c
end
local function mutate(self,c,k,v)
 local spec=copy(known(recipes[c],'source readonly constructor'));if k=='add' then spec.subcards[#spec.subcards+1]=type(v)=='number' and v or v:getKnownEffectiveId() else spec[k]=v end
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
 role=self:getRoleEstimate(p);if role==nil or role=='neutral'or role=='unknown'then ai_unsupported('private role is not resolved for this viewer','keguibao.role')end
 return self:useKnowledgeEstimate({value=role,status='estimate',basis='viewer_role_inference_replaces_private_role',viewer=self.player:objectName(),target=p:objectName()},'keguibao.role')
end
local function observed_hand(self,p)
 if p:objectName()==self.player:objectName()then return known(p:getHandcards(),'owner hand')end
 return known(p:getKnownCards(),'observer disclosed hand')
end
local function data_fact(self,key)
 local ctx=self:getDecisionContext();return known(known(ctx.round25_choice,'Round25 scoped context')[key],key)
end
local function source_damage(self)
 local row=data_fact(self,'current_damage');if row==false then return{}end
 return{from=row.from and row.from~=false and self.room:findPlayerByObjectName(row.from,true)or nil,to=row.to and self.room:findPlayerByObjectName(row.to,true),damage=row.amount,nature=row.nature,card=row.card and CardView.new(row.card)or nil}
end
local function source_use(self)
 local row=data_fact(self,'current_use');if row==false then return{to=AIList.new({})}end
 local tos=AIList.new({});for _,n in ipairs(row.to)do tos:append(known(self.room:findPlayerByObjectName(n,true),'use target'))end
 return{from=row.from and row.from~=false and self.room:findPlayerByObjectName(row.from,true)or nil,to=tos,card=row.card and CardView.new(row.card)or nil}
end
local function can_to(self,c,from,to)if from:objectName()~=self.player:objectName()then ai_unsupported('foreign targetFilter is not an owner query','keguibao')end;return self:cardTargetFilter(c,{},to)end
local function extra_targets(self,c)return known(self:getEvaluationCandidate(c):getExtraTargetCount(),'extra target modifier')end
local function same_player(a,b)return a and b and a:objectName()==b:objectName()end

local function selected_response(self,text)
 local spec=type(text)=='string'and printed_spec(text);if not spec then return text end
 local base=known(self:getEvaluationCard(spec.name),'selected printed response')
 local policy=known(self:getConversionPolicy(base:getClassName()),'selected response catalog');local source
 for _,row in ipairs(policy.skills or{})do if row.skill_name==spec.skill then source=row;break end end
 return known(self:resolveResponseConversion(spec,known(source,'exact selected response source')),'selected response receipt')
end
local function nested_kuangfeng(self,prompt)
	local friendly_fire
	for _,friend in sgs.list(self.friends_noself)do
                if friend:getStrategyMark("&kuangfeng")==0 and self:damageIsEffective(friend,sgs.DamageStruct_Fire) and friend:faceUp() and not self:willSkipPlayPhase(friend)
			and (friend:hasSkill("huoji") or friend:hasWeapon("Fan") or (friend:hasSkill("yeyan") and friend:getStrategyMark("@flame")>0)) then
			friendly_fire = true
			break
		end
	end

	local is_chained = 0
	local target = {}
	for _,enemy in sgs.list(self.enemies)do
                if enemy:getStrategyMark("&kuangfeng")==0 and self:damageIsEffective(enemy,sgs.DamageStruct_Fire) then
			if enemy:isChained() then
				is_chained = is_chained+1
				table.insert(target,enemy)
			elseif enemy:hasArmorEffect("Vine") then
				table.insert(target,1,enemy)
				break
			end
		end
	end
	local usecard=false
	if friendly_fire and is_chained>1 then usecard=true end
	self.friends = self:sort(self.friends,"hp")
	if target[1] and not self:isWeak(self.friends[1]) then
		if target[1]:hasArmorEffect("Vine") and friendly_fire then usecard = true end
	end
	if usecard then
		if not target[1] then table.insert(target,self.enemies[1]) end
		if target[1] then return "@KuangfengCard="..self.player:getPile("stars"):first().."->"..target[1]:objectName() else return "." end
	else
		return "."
	end
end


local function nested_dawu(self,prompt)
	self.friends_noself = self:sort(self.friends_noself,"hp")
	local targets = {}
	local lord = self.room:getLord()
	self.friends_noself = self:sort(self.friends_noself,"defense")
        if lord and lord:getStrategyMark("&dawu")==0 and self:isFriend(lord) and not sgs.isLordHealthy() and not self.player:isLord() and not lord:hasSkill("buqu")
		and not (lord:hasSkill("hunzi") and lord:getStrategyMark("hunzi")==0 and lord:getHp()>1) then
			table.insert(targets,lord:objectName())
	else
		for _,friend in sgs.list(self.friends_noself)do
                        if friend:getStrategyMark("&dawu")==0 and self:isWeak(friend) and not friend:hasSkill("buqu")
				and not (friend:hasSkill("hunzi") and friend:getStrategyMark("hunzi")==0 and friend:getHp()>1) then
					table.insert(targets,friend:objectName())
					break
			end
		end
	end
	if self.player:getPile("stars"):length()>#targets and self:isWeak() then table.insert(targets,self.player:objectName()) end
	if #targets>0 then
		local s = sgs.QList2Table(self.player:getPile("stars"))
		local length = #targets
		for i = 1,#s-length do
			table.remove(s,#s)
		end
		return "@DawuCard="..table.concat(s,"+").."->"..table.concat(targets,"+")
	end
	return "."
end


--换英雄

ai_skill_invoke.guichangetupo = function(self, options, request)

	local data = request and self:getDecisionData(request) or nil
	return (false) or false
end

--鬼曹操
ai_skill_invoke.keguiduoyi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return ((#(sgs.ai_skill_playerschosen.keguiduoyi(self, data:toCardUse().to, 99, 0)) > 0)) or false
end


sgs.ai_skill_playerschosen.keguiduoyi = function(self,targets,max_num,min_num)
	local tos = {}
	for i,p in sgs.list(targets)do
		if #tos>=max_num then break end
		if self:isEnemy(p)
		then table.insert(tos,p) end
	end
	return tos
end


ai_fill_skill["keguixianjiVS"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyFlag("Forbidkeguixianji") then return false end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("TrickCard") then
			return policy(self,"#keguixianjiCard:" .. acard:getKnownEffectiveId()..":")
		end
	end
end

ai_card_use["#keguixianjiCard"] = function(self, card, use, request)
	if self:needBear() then
		return "."
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("keguixianji") then
			if not friend:getStrategyFlag("keguixianjiInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		targets = self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	end
end

sgs.ai_card_intention["keguixianjiCard"] = function(self, card, from, tos)
	self:updateIntention(from, tos[1], -80)
end

sgs.ai_use_value["keguixianjiCard"] = 8.5

function sgs.ai_cardneed.keguihuxiao(to, card, self)
	local cards = observed_hand(self,to)
	local slash_num = 0
	for _, c in sgs.list(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:getStrategyFlag("visible") or c:getStrategyFlag(flag) then
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end
	return card:isRed() and ( card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic")))
end

function sgs.ai_cardneed.keguilongyin(to, card, self)
	local cards = observed_hand(self,to)
	local slash_num = 0
	for _, c in sgs.list(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:getStrategyFlag("visible") or c:getStrategyFlag(flag) then
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end
	return card:isBlack() and ( card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic")))
end

--鬼关羽
ai_skill_invoke.keguiwumo = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_playerchosen.keguituodao = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getHp() < qq:getHp()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:append(qq)
			end
		end
	end
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end

function sgs.ai_cardneed.keguisheji(to, card, self)
	local cards = observed_hand(self,to)
	local slash_num = 0
	for _, c in sgs.list(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:getStrategyFlag("visible") or c:getStrategyFlag(flag) then
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end
	return  ( card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic")))
end

sgs.ai_canliegong_skill.keguisheji = function(self, from, to)
	return from:getPhase() == sgs.Player_Play and from:inMyAttackRange(to, 0, true) and to:inMyAttackRange(from, 0, true)
end

sgs.ai_cardneed.keguijueluone = function(to,card,self)
	return isCard("Slash",card,to) and getKnownCard(to,self.player,"Slash",true)==0
end


--鬼华雄
sgs.ai_can_damagehp.keguixiaoshou = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return from:getEquips():length() > 0 and self:doDisCard(from, "he", true)
	end
end
ai_skill_invoke.keguixiaoshou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	if damage.from then
		return (self:doDisCard(damage.from, "he", true)) or false
	end
	return (true) or false
end

ai_skill_choice.keguixiaoshou = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result(("move"), options)
end


ai_skill_choice.keguixiaoshou_equip = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = data:toPlayer()
	choices = choices:split("+")
	if target then
		if self:isFriend(target) and self:needToThrowArmor(target) and table.contains(choices, "1") then
			return ai_choice_result(("1"), options)
		end
	end
	local x = math.floor(math.random(0, #choices))
	return ai_choice_result((choices[x]), options)
end

sgs.ai_skill_playerchosen.keguixiaoshou = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, friend in ipairs(self.friends_noself) do
		if self:loseEquipEffect(friend) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.need_equip_skill, friend) then
			return friend
		end
	end
	return self.player
end

--鬼诸葛亮
ai_skill_invoke.keguizhuangshen = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_playerchosen.keguizhuangshen = function(self, targets)
	targets = sgs.QList2Table(targets)
	return targets[math.random(1, #targets)]
end

ai_skill_choice.keguizhuangshen = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local player = data:toPlayer()
	local skills = choices:split("+")


	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player,true) then
			return ai_choice_result((sk), options)
		end
	end

	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player) then
			return ai_choice_result((sk), options)
		end
	end

	local not_bad_skills = {}
	for _,sk in sgs.list(skills)do
		if string.find(sgs.bad_skills,sk) then continue end
		table.insert(not_bad_skills,sk)
	end
	if #not_bad_skills>0 then
		return ai_choice_result((not_bad_skills[math.random(1,#not_bad_skills)]), options)
	end

	return ai_choice_result((skills[math.random(1,#skills)]), options)
end


--鬼曹节
ai_fill_skill["keguitiqi"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:canDiscard(self.player, "he") then return end
	if #self.enemies > 0 then return policy(self,"#keguitiqiCard:.:") end
	return
end
ai_card_use["#keguitiqiCard"] = function(self, card, use, request)
	local targets = AIList.new({})
	local cards = self.player:getCards("he")

	local use_card = {}
	cards = sgs.QList2Table(cards)
	if #cards == 0 then return end
	cards = self:sortByKeepValue(cards)
	if self:needToThrowArmor() then
		table.insert(use_cards, self.player:getArmor():getEffectiveId())
	end

	for _, card in ipairs(cards) do
		if not table.contains(use_card, card:getKnownEffectiveId()) then
			table.insert(use_card, card:getId())
		end
	end
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		and self.player:getHp()>enemy:getHp() and self.player:getHp()>1
		then
			targets:append(enemy)
			if targets:length() >= #use_card then
				break
			end
		end
	end

	if targets:length() < #use_card  then
		for i = 1, #use_card - targets:length(), 1 do
			table.removeOne(use_card, use_card[#use_card])
		end

	end
	if targets:length()> 0 then
		if #use_card == 1 then
		use.card = policy(self,"#keguitiqiCard:"..use_card[1] ..":")
		else
		use.card = policy(self,"#keguitiqiCard:".. table.concat(use_card, "+")..":")
		end
		if use.to then use.to = targets end
		return
	end
end


sgs.ai_use_value.keguitiqiCard = 2.5
sgs.ai_card_intention.keguitiqiCard = 80
sgs.dynamic_value.damage_card.keguitiqiCard = true


--司马徽

ai_fill_skill["keguishouye"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:hasUsed("keguishouyeCard") then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local to_throw = AIList.new({})
	for _, acard in ipairs(cards) do
		to_throw:append(acard:getKnownEffectiveId())
	end
	card_id = to_throw:at(0)
	if not card_id then
		return nil
	else
		return policy(self,"#keguishouyeCard:"..card_id..":")
	end
end


ai_card_use["#keguishouyeCard"] = function(self, card, use, request)
	if not self.player:hasUsed("#keguishouyeCard") then
		if self.player:getStrategyMark("@guijiehuo") > 0  then
			local deathplayer = {}
			for _,p in sgs.qlist(self.room:getPlayers()) do
				if p:isDead() and ((source_role(self,p) == source_role(self,self.player))
				or (source_role(self,p) == "loyalist" and self.player:isLord())) then
					table.insert(deathplayer,p:getKnownGeneralName())
				end
			end
			if #deathplayer>0 then
			use.card = card
			if use.to then use.to:append(self.player) end
			return
			end
		end
		for _, friend in ipairs(self.friends) do
			if self:hasSkills(sgs.cardneed_skill, friend) and self:canDraw(friend, self.player) then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
        self.friends = self:sort(self.friends)
		for _, friend in ipairs(self.friends) do
			if self:isWeak(friend)  and self:canDraw(friend, self.player) then
			use.card = card
			if use.to then use.to:append(friend) end
			return
			end
	end
		for _, friend in ipairs(self.friends) do
				use.card = card
				if use.to then use.to:append(friend) end
				return
		end
	end
end

sgs.ai_use_value.keguishouyeCard = 8.5
sgs.ai_use_priority.keguishouyeCard = 9.5
sgs.ai_card_intention.keguishouyeCard = -80

ai_fill_skill["keguijiehuo"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyMark("@guijiehuo") == 0 then return end
	local deathplayer = {}
	for _,p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() and ((source_role(self,p) == source_role(self,self.player))
		 or (source_role(self,p) == "loyalist" and self.player:isLord())) then
			table.insert(deathplayer,p:getKnownGeneralName())
		end
	end
	if #deathplayer==0 then return end
	if self.player:getHandcardNum()>=4 then
		local spade,club,heart,diamond
		for _,card in sgs.list(self.player:getHandcards())do
			if card:getSuit()==sgs.Card_Spade then spade = true
			elseif card:getSuit()==sgs.Card_Club then club = true
			elseif card:getSuit()==sgs.Card_Heart then heart = true
			elseif card:getSuit()==sgs.Card_Diamond then diamond = true
			end
		end
		if spade and club and diamond and heart then
			return policy(self,"#keguijiehuoCard:.:")
		end
	end
end

ai_card_use["#keguijiehuoCard"] = function(self, card, use, request)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards,true)
	local need_cards = {}
	local spade,club,heart,diamond
	for _,card in sgs.list(cards)do
		if card:getSuit()==sgs.Card_Spade and not spade then spade = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Club and not club then club = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Heart and not heart then heart = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Diamond and not diamond then diamond = true table.insert(need_cards,card:getId())
		end
	end
	if #need_cards<4 then return end
	local greatyeyan = policy(self,"#keguijiehuoCard:"..table.concat(need_cards,"+")..":")
	assert(greatyeyan)
	use.card = greatyeyan
end

sgs.ai_use_value["#keguijiehuoCard"] = 8
sgs.ai_use_priority["#keguijiehuoCard"] = 9.5
sgs.ai_use_priority.keguijiehuoCard = 9.5

ai_skill_choice["kexianjishi-ask"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	for _, p_name in ipairs(items) do
		for _,p in sgs.qlist(self.room:getPlayers()) do
			if p:getKnownGeneralName() == p_name and ((source_role(self,p) == source_role(self,self.player))
			 or (source_role(self,p) == "loyalist" and self.player:isLord())) then
				return ai_choice_result((p_name), options)
			end
		end
	end
	return ai_choice_result((items[math.random(1, #items)]), options)
end


--沙摩柯

ai_skill_invoke.keguiqinwang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	local damage = source_damage(self)
	if not self:isFriend(target) or (damage.from and self:isFriend(damage.from)) then return (false) or false end
	if self:needToLoseHp(target, damage.from, damage.card) then return (false) or false end
	if self.player:getHandcardNum() + self.player:getEquips():length() < 2 and not self:isWeak(target) then return (false) or false end


	if self:isWeak(target) and not self:isWeak() then return (true) or false end

	return (false) or false
end


sgs.ai_ajustdamage_from.keguiqinwang = function(self, from, to, card, nature)
    if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) and from:getPhase() == sgs.Player_Play then
        return from:getStrategyMark("@guiqinwang")
    end
end



--界鬼曹操
ai_skill_invoke.kejieguiduoyi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return ((#(sgs.ai_skill_playerschosen.kejieguiduoyi(self, data:toCardUse().to, 99, 0)) > 0)) or false
end


sgs.ai_skill_playerschosen.kejieguiduoyi = function(self,targets,max_num,min_num)
	local tos = {}
	for i,p in sgs.list(targets)do
		if #tos>=max_num then break end
		if self:isEnemy(p)
		then table.insert(tos,p) end
	end
	return tos
end


ai_fill_skill["kejieguixianjiVS"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("TrickCard") then
			return policy(self,"#kejieguixianjiCard:" .. acard:getKnownEffectiveId()..":")
		end
	end
end

ai_card_use["#kejieguixianjiCard"] = function(self, card, use, request)
	if self:needBear() then
		return "."
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("kejieguixianji") then
			if not friend:getStrategyFlag("kejieguixianjiInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		targets = self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	end
end

sgs.ai_card_intention["#kejieguixianjiCard"] = function(self, card, from, tos)
	self:updateIntention(from, tos[1], -80)
end

sgs.ai_use_priority["kejieguixianjiCard"] = 10
sgs.ai_use_value["kejieguixianjiCard"] = 8.5


--界鬼诸葛亮
ai_skill_invoke.kejieguizhuangshen = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_playerchosen.kejieguizhuangshen = function(self, targets)
	targets = sgs.QList2Table(targets)
	return targets[math.random(1, #targets)]
end

ai_skill_choice.kejieguizhuangshen = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local player = data:toPlayer()
	local skills = choices:split("+")


	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player,true) then
			return ai_choice_result((sk), options)
		end
	end

	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player) then
			return ai_choice_result((sk), options)
		end
	end

	local not_bad_skills = {}
	for _,sk in sgs.list(skills)do
		if string.find(sgs.bad_skills,sk) then continue end
		table.insert(not_bad_skills,sk)
	end
	if #not_bad_skills>0 then
		return ai_choice_result((not_bad_skills[math.random(1,#not_bad_skills)]), options)
	end

	return ai_choice_result((skills[math.random(1,#skills)]), options)
end

sgs.ai_skill_playerchosen.kejieguizhuangshenbuff = function(self, targets)
	local cardstr = nested_dawu(self, "@dawu")
	if cardstr:match("->") then
		local targetstr = cardstr:split("->")[2]:split("+")
		if #targetstr > 0 then
			local target = self.room:findPlayerByObjectName(targetstr[1])
			return target
		end
	end
	local cardstr = nested_kuangfeng(self, "@kuangfeng")
	if cardstr:match("->") then
		local targetstr = cardstr:split("->")[2]:split("+")
		if #targetstr > 0 then
			local target = self.room:findPlayerByObjectName(targetstr[1])
			return target
		end
	end
	return self.player
end

ai_skill_choice.kejieguizhuangshenbuff = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local player = data:toPlayer()
	if self:isFriend(player) then
		return ai_choice_result(("guidawu"), options)
	else
		return ai_choice_result(("guikuangfeng"), options)
	end

	return ai_choice_result(("guikuangfeng"), options)
end

--second

ai_skill_invoke.kejieguiqideng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDying().damage
	return (self:getAllPeachNum() < self.player:getHp() or (damage and damage.card and damage.card:getStrategyFlag("zhashicardflag"))) or false
end

ai_fill_skill["kejieguizhashi"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:hasUsed("kejieguizhashiCard") then return end
	return policy(self,"#kejieguizhashiCard:.:")
end

ai_card_use["#kejieguizhashiCard"] = function(self, card, use, request)
    if not self.player:hasUsed("#kejieguizhashiCard") then
        self.enemies = self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local targets = {}
		local distance = use.DefHorse and 1 or 0
	for _,enemy in ipairs(self.enemies)do
		if enemy:distanceTo(self.player, distance)<=enemy:getAttackRange() and self:isTiaoxinTarget(enemy)
		and self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player)
		then
			table.insert(targets,enemy)
		end
	end

	if #targets==0 then return end

	self:setPriorityValue("#kejieguizhashiCard",8,"keguibao")
	if not self.player:getArmor() and not self.player:isKongcheng() then
		for _,card in sgs.qlist(self.player:getCards("h"))do
			if card:isKindOf("Armor") and self:evaluateArmor(card)>3 then
				self:setPriorityValue("#kejieguizhashiCard",5.9,"keguibao")
				break
			end
		end
	end

	if use.to then
		targets = self:sort(targets,"defenseSlash")
		use.to:append(targets[1])
	end
	use.card = policy(self,"#kejieguizhashiCard:.:")
	end
end

sgs.ai_use_value["kejieguizhashiCard"] = 8.5
sgs.ai_use_priority["kejieguizhashiCard"] = 9.5
sgs.ai_card_intention["kejieguizhashiCard"] = 80


--鬼张飞

ai_skill_invoke.kejieguilongyin = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (sgs.ai_skill_playerchosen.kejieguilongyin(self, self.room:getAlivePlayers()) ~= nil) or false
end

sgs.ai_skill_playerchosen.kejieguilongyin = function(self, targets)
	targets = sgs.QList2Table(targets)
	if source_role(self,self.player) == "loyalist" and self:isWeak(self.room:getLord()) then return  self.room:getLord() end
	local theweak = AIList.new({})
	local theweaktwo = AIList.new({})
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getHp() < qq:getHp()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:append(qq)
			end
		end
	end
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end

ai_skill_invoke.jueqiaogainslash = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end


sgs.ai_ajustdamage_from.kejieguixiaoyin = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:isRed()
	then
		return 1
	end
end
function sgs.ai_cardneed.kejieguixiaoyin(to, card, self)
	local cards = observed_hand(self,to)
	local slash_num = 0
	for _, c in sgs.list(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:getStrategyFlag("visible") or c:getStrategyFlag(flag) then
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end
	return ( card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic")))
end





--界鬼关羽

ai_skill_invoke.kejieguiwumo = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end
sgs.ai_cardneed.kejieguiwumo = function(to,card,self)
	return (isCard("Slash",card,to) and card:isRed())
end
sgs.ai_card_priority.kejieguiwumo = function(self,card)
	if card:isKindOf("Slash") and card:isRed()
	then return 0.05 end
end

ai_skill_choice.kejieguituodao = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	if self:getEnemyNumBySeat(self.room:getCurrent(),self.player,self.player,true)>self.room:getAlivePlayers():length()/2 and self.player:getStrategyMark("&jieguiwumozhuangbei-SelfClear") == 0 then
		return ai_choice_result(("dao"), options)
	end
	local players = AIList.new({})
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:canSlash(p, nil, false) then
			players:append(p)
		end
	end
	if players:length() > 0 and sgs.ai_skill_playerchosen.zero_card_as_slash(self, players) then
		return ai_choice_result(("sha"), options)
	else
		return ai_choice_result(("dao"), options)
	end

    return ai_choice_result(nil, options)
end

sgs.ai_skill_playerchosen.kejieguituodao = sgs.ai_skill_playerchosen.zero_card_as_slash


--界鬼吕布

ai_skill_invoke.kejieguisheji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = source_use(self)
	local target = data:toPlayer()
	local slash = use.card
	local from = use.from
	if from and self:isFriend(from) then return (false) or false end
	local willSave = false
	local friend
	if self:isFriend(target) and self:slashIsEffective(slash, target, from) then
		return (true) or false
	end
	if self:isEnemy(from) and self:damageIsEffective(from, sgs.DamageStruct_Normal, self.player) and not self:cantbeHurt(from) then
		return (true) or false
	end

	return (false) or false
end
sgs.ai_cardneed.kejieguisheji = sgs.ai_cardneed.bignumber

function sgs.ai_skill_pindian.kejieguisheji(minusecard,self,requestor,maxcard)
	local req
	local target
	local target_name=data_fact(self,'sheji_pindian_target')
 if target_name~=false then target=known(self.room:findPlayerByObjectName(target_name,true),'sheji target')end
	if self.player:objectName()==requestor:objectName() then
		req = source_use(self).from
	else
		req = requestor
	end
	local cards,maxcard = sgs.QList2Table(self.player:getHandcards()),nil
	local max_value = 0
	cards = self:sortByKeepValue(cards)
	max_value = self:getKeepValue(cards[#cards])
	local function compare_func1(a,b)
		return a:getNumber()>b:getNumber()
	end
	local function compare_func2(a,b)
		return a:getNumber()<b:getNumber()
	end
	if target and self:isFriend(target) and self:isWeak(target) and self.player:objectName() ~= req:objectName() then
		table.sort(cards,compare_func2)
	else
		table.sort(cards,compare_func1)
	end
	for _,card in sgs.list(cards)do
		if max_value>7 or self:getKeepValue(card)<7 or card:isKindOf("EquipCard") then maxcard = card break end
	end
	return maxcard or cards[1]
end

sgs.ai_cardneed.kejieguijuelu = sgs.ai_cardneed.slash


--界鬼华雄

sgs.ai_can_damagehp.kejieguixiaoshou = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return from:getEquips():length() > 0 and self:doDisCard(from, "e", true)
	end
end
ai_skill_invoke.kejieguixiaoshou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	if damage.from and damage.to:objectName() == self.player:objectName() then
		return (self:doDisCard(damage.from, "e", true)) or false
	elseif damage.from and damage.from:objectName() == self.player:objectName() then
		return (self:doDisCard(damage.to, "e", true)) or false
	end
	return (true) or false
end

ai_skill_choice.kejieguixiaoshou = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result(("move"), options)
end


ai_skill_choice.kejieguixiaoshou_equip = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = data:toPlayer()
	choices = choices:split("+")
	if target then
		if self:isFriend(target) and self:needToThrowArmor(target) and table.contains(choices, "1") then
			return ai_choice_result(("1"), options)
		end
	end
	return ai_choice_result((choices[1]), options)
end

sgs.ai_skill_playerchosen.kejieguixiaoshou = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, friend in ipairs(self.friends_noself) do
		if self:loseEquipEffect(friend) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.need_equip_skill, friend) then
			return friend
		end
	end
	return self.player
end

sgs.ai_can_damagehp.kejieguifuwang = function(self, from, card, to)
	return to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to) and self.room:getLord():isMale() and from and from:isFemale()
end






ai_fill_skill["kejieguishouye"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:hasUsed("kejieguishouyeCard") then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local to_throw = AIList.new({})
	for _, acard in ipairs(cards) do
		to_throw:append(acard:getKnownEffectiveId())
	end
	card_id = to_throw:at(0)
	if not card_id then
		return nil
	else
		return policy(self,"#kejieguishouyeCard:"..card_id..":")
	end
end


ai_card_use["#kejieguishouyeCard"] = function(self, card, use, request)
	if not self.player:hasUsed("#kejieguishouyeCard") then
		if self.player:getStrategyMark("&kejieguijiehuo") < 4 and self.player:hasSkill("kejieguijiehuo")  then
			local deathplayer = {}
			for _,p in sgs.qlist(self.room:getPlayers()) do
				if p:isDead() and ((source_role(self,p) == source_role(self,self.player))
				or (source_role(self,p) == "loyalist" and self.player:isLord())) then
					table.insert(deathplayer,p:getKnownGeneralName())
				end
			end
			if #deathplayer>0 then
			use.card = card
			if use.to then use.to:append(self.player) end
			return
			end
		end
		for _, friend in ipairs(self.friends) do
			if self:hasSkills(sgs.cardneed_skill, friend) and self:canDraw(friend, self.player) then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
        self.friends = self:sort(self.friends)
		for _, friend in ipairs(self.friends) do
			if self:isWeak(friend)  and self:canDraw(friend, self.player) then
			use.card = card
			if use.to then use.to:append(friend) end
			return
			end
		end
		for _, friend in ipairs(self.friends) do
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
end

sgs.ai_use_value.kejieguishouyeCard = 8.5
sgs.ai_use_priority.kejieguishouyeCard = 9.5
sgs.ai_card_intention.kejieguishouyeCard = -80

ai_fill_skill["kejieguijiehuo"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyMark("&kejieguijiehuo") >= 4 then return end
	local deathplayer = {}
	for _,p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() and ((source_role(self,p) == source_role(self,self.player))
		 or (source_role(self,p) == "loyalist" and self.player:isLord())) then
			table.insert(deathplayer,p:getKnownGeneralName())
		end
	end
	if #deathplayer==0 then return end
	if self.player:getHandcardNum()>=3 then
		local spade,club,heart,diamond
		for _,card in sgs.list(self.player:getHandcards())do
			if card:getSuit()==sgs.Card_Spade then spade = true
			elseif card:getSuit()==sgs.Card_Club then club = true
			elseif card:getSuit()==sgs.Card_Heart then heart = true
			elseif card:getSuit()==sgs.Card_Diamond then diamond = true
			end
		end
		local suit = 0
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
		if suit >= 3 then
			return policy(self,"#kejieguijiehuoCard:.:")
		end
	end
end

ai_card_use["#kejieguijiehuoCard"] = function(self, card, use, request)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards,true)
	local need_cards = {}
	local spade,club,heart,diamond
	for _,card in sgs.list(cards)do
		if card:getSuit()==sgs.Card_Spade and not spade and #need_cards < 3 then spade = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Club and not club and #need_cards < 3 then club = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Heart and not heart and #need_cards < 3 then heart = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Diamond and not diamond and #need_cards < 3 then diamond = true table.insert(need_cards,card:getId())
		end
	end
	if #need_cards<3 then return end
	local greatyeyan = policy(self,"#kejieguijiehuoCard:"..table.concat(need_cards,"+")..":")
	assert(greatyeyan)
	use.card = greatyeyan
end

sgs.ai_use_value["#kejieguijiehuoCard"] = 8
sgs.ai_use_priority["#kejieguijiehuoCard"] = 9.5
sgs.ai_use_priority.kejieguijiehuoCard = 9.5








local function wrap(f,key,kind)
 return function(...)
  local a=table.pack(...);local self
  for i=1,a.n do if type(a[i])=='table' and a[i].player and a[i].world and a[i].request then self=a[i];break end end
  if not self then return f(...)end
  local prior,request=self._keguibao_key,self._keguibao_request;self._keguibao_key=key
  if kind=='ai_fill_skill'then self._keguibao_request=a[3]end
  local r=table.pack(pcall(f,table.unpack(a,1,a.n)));self._keguibao_key=prior;self._keguibao_request=request
  if not r[1]then error(r[2],0)end
  if kind=='ai_skill_use'then r[2]=response(self,r[2])end
  return table.unpack(r,2,r.n)
 end
end
ai_skill_invoke['guichangetupo']=wrap(ai_skill_invoke['guichangetupo'],'guichangetupo','ai_skill_invoke')
ai_skill_invoke['keguiduoyi']=wrap(ai_skill_invoke['keguiduoyi'],'keguiduoyi','ai_skill_invoke')
sgs.ai_skill_playerschosen['keguiduoyi']=wrap(sgs.ai_skill_playerschosen['keguiduoyi'],'keguiduoyi','ai_skill_playerschosen')
ai_fill_skill['keguixianjiVS']=wrap(ai_fill_skill['keguixianjiVS'],'keguixianjiVS','ai_fill_skill')
ai_card_use['#keguixianjiCard']=wrap(ai_card_use['#keguixianjiCard'],'#keguixianjiCard','ai_card_use')
sgs.ai_card_intention['keguixianjiCard']=wrap(sgs.ai_card_intention['keguixianjiCard'],'keguixianjiCard','ai_card_intention')
sgs.ai_cardneed['keguihuxiao']=wrap(sgs.ai_cardneed['keguihuxiao'],'keguihuxiao','ai_cardneed')
sgs.ai_cardneed['keguilongyin']=wrap(sgs.ai_cardneed['keguilongyin'],'keguilongyin','ai_cardneed')
ai_skill_invoke['keguiwumo']=wrap(ai_skill_invoke['keguiwumo'],'keguiwumo','ai_skill_invoke')
sgs.ai_skill_playerchosen['keguituodao']=wrap(sgs.ai_skill_playerchosen['keguituodao'],'keguituodao','ai_skill_playerchosen')
sgs.ai_cardneed['keguisheji']=wrap(sgs.ai_cardneed['keguisheji'],'keguisheji','ai_cardneed')
sgs.ai_canliegong_skill['keguisheji']=wrap(sgs.ai_canliegong_skill['keguisheji'],'keguisheji','ai_canliegong_skill')
sgs.ai_cardneed['keguijueluone']=wrap(sgs.ai_cardneed['keguijueluone'],'keguijueluone','ai_cardneed')
sgs.ai_can_damagehp['keguixiaoshou']=wrap(sgs.ai_can_damagehp['keguixiaoshou'],'keguixiaoshou','ai_can_damagehp')
ai_skill_invoke['keguixiaoshou']=wrap(ai_skill_invoke['keguixiaoshou'],'keguixiaoshou','ai_skill_invoke')
ai_skill_choice['keguixiaoshou']=wrap(ai_skill_choice['keguixiaoshou'],'keguixiaoshou','ai_skill_choice')
ai_skill_choice['keguixiaoshou_equip']=wrap(ai_skill_choice['keguixiaoshou_equip'],'keguixiaoshou_equip','ai_skill_choice')
sgs.ai_skill_playerchosen['keguixiaoshou']=wrap(sgs.ai_skill_playerchosen['keguixiaoshou'],'keguixiaoshou','ai_skill_playerchosen')
ai_skill_invoke['keguizhuangshen']=wrap(ai_skill_invoke['keguizhuangshen'],'keguizhuangshen','ai_skill_invoke')
sgs.ai_skill_playerchosen['keguizhuangshen']=wrap(sgs.ai_skill_playerchosen['keguizhuangshen'],'keguizhuangshen','ai_skill_playerchosen')
ai_skill_choice['keguizhuangshen']=wrap(ai_skill_choice['keguizhuangshen'],'keguizhuangshen','ai_skill_choice')
ai_fill_skill['keguitiqi']=wrap(ai_fill_skill['keguitiqi'],'keguitiqi','ai_fill_skill')
ai_card_use['#keguitiqiCard']=wrap(ai_card_use['#keguitiqiCard'],'#keguitiqiCard','ai_card_use')
ai_fill_skill['keguishouye']=wrap(ai_fill_skill['keguishouye'],'keguishouye','ai_fill_skill')
ai_card_use['#keguishouyeCard']=wrap(ai_card_use['#keguishouyeCard'],'#keguishouyeCard','ai_card_use')
ai_fill_skill['keguijiehuo']=wrap(ai_fill_skill['keguijiehuo'],'keguijiehuo','ai_fill_skill')
ai_card_use['#keguijiehuoCard']=wrap(ai_card_use['#keguijiehuoCard'],'#keguijiehuoCard','ai_card_use')
ai_skill_choice['kexianjishi-ask']=wrap(ai_skill_choice['kexianjishi-ask'],'kexianjishi-ask','ai_skill_choice')
ai_skill_invoke['keguiqinwang']=wrap(ai_skill_invoke['keguiqinwang'],'keguiqinwang','ai_skill_invoke')
sgs.ai_ajustdamage_from['keguiqinwang']=wrap(sgs.ai_ajustdamage_from['keguiqinwang'],'keguiqinwang','ai_ajustdamage_from')
ai_skill_invoke['kejieguiduoyi']=wrap(ai_skill_invoke['kejieguiduoyi'],'kejieguiduoyi','ai_skill_invoke')
sgs.ai_skill_playerschosen['kejieguiduoyi']=wrap(sgs.ai_skill_playerschosen['kejieguiduoyi'],'kejieguiduoyi','ai_skill_playerschosen')
ai_fill_skill['kejieguixianjiVS']=wrap(ai_fill_skill['kejieguixianjiVS'],'kejieguixianjiVS','ai_fill_skill')
ai_card_use['#kejieguixianjiCard']=wrap(ai_card_use['#kejieguixianjiCard'],'#kejieguixianjiCard','ai_card_use')
sgs.ai_card_intention['#kejieguixianjiCard']=wrap(sgs.ai_card_intention['#kejieguixianjiCard'],'#kejieguixianjiCard','ai_card_intention')
ai_skill_invoke['kejieguizhuangshen']=wrap(ai_skill_invoke['kejieguizhuangshen'],'kejieguizhuangshen','ai_skill_invoke')
sgs.ai_skill_playerchosen['kejieguizhuangshen']=wrap(sgs.ai_skill_playerchosen['kejieguizhuangshen'],'kejieguizhuangshen','ai_skill_playerchosen')
ai_skill_choice['kejieguizhuangshen']=wrap(ai_skill_choice['kejieguizhuangshen'],'kejieguizhuangshen','ai_skill_choice')
sgs.ai_skill_playerchosen['kejieguizhuangshenbuff']=wrap(sgs.ai_skill_playerchosen['kejieguizhuangshenbuff'],'kejieguizhuangshenbuff','ai_skill_playerchosen')
ai_skill_choice['kejieguizhuangshenbuff']=wrap(ai_skill_choice['kejieguizhuangshenbuff'],'kejieguizhuangshenbuff','ai_skill_choice')
ai_skill_invoke['kejieguiqideng']=wrap(ai_skill_invoke['kejieguiqideng'],'kejieguiqideng','ai_skill_invoke')
ai_fill_skill['kejieguizhashi']=wrap(ai_fill_skill['kejieguizhashi'],'kejieguizhashi','ai_fill_skill')
ai_card_use['#kejieguizhashiCard']=wrap(ai_card_use['#kejieguizhashiCard'],'#kejieguizhashiCard','ai_card_use')
ai_skill_invoke['kejieguilongyin']=wrap(ai_skill_invoke['kejieguilongyin'],'kejieguilongyin','ai_skill_invoke')
sgs.ai_skill_playerchosen['kejieguilongyin']=wrap(sgs.ai_skill_playerchosen['kejieguilongyin'],'kejieguilongyin','ai_skill_playerchosen')
ai_skill_invoke['jueqiaogainslash']=wrap(ai_skill_invoke['jueqiaogainslash'],'jueqiaogainslash','ai_skill_invoke')
sgs.ai_ajustdamage_from['kejieguixiaoyin']=wrap(sgs.ai_ajustdamage_from['kejieguixiaoyin'],'kejieguixiaoyin','ai_ajustdamage_from')
sgs.ai_cardneed['kejieguixiaoyin']=wrap(sgs.ai_cardneed['kejieguixiaoyin'],'kejieguixiaoyin','ai_cardneed')
ai_skill_invoke['kejieguiwumo']=wrap(ai_skill_invoke['kejieguiwumo'],'kejieguiwumo','ai_skill_invoke')
sgs.ai_cardneed['kejieguiwumo']=wrap(sgs.ai_cardneed['kejieguiwumo'],'kejieguiwumo','ai_cardneed')
sgs.ai_card_priority['kejieguiwumo']=wrap(sgs.ai_card_priority['kejieguiwumo'],'kejieguiwumo','ai_card_priority')
ai_skill_choice['kejieguituodao']=wrap(ai_skill_choice['kejieguituodao'],'kejieguituodao','ai_skill_choice')
ai_skill_invoke['kejieguisheji']=wrap(ai_skill_invoke['kejieguisheji'],'kejieguisheji','ai_skill_invoke')
sgs.ai_skill_pindian['kejieguisheji']=wrap(sgs.ai_skill_pindian['kejieguisheji'],'kejieguisheji','ai_skill_pindian')
sgs.ai_can_damagehp['kejieguixiaoshou']=wrap(sgs.ai_can_damagehp['kejieguixiaoshou'],'kejieguixiaoshou','ai_can_damagehp')
ai_skill_invoke['kejieguixiaoshou']=wrap(ai_skill_invoke['kejieguixiaoshou'],'kejieguixiaoshou','ai_skill_invoke')
ai_skill_choice['kejieguixiaoshou']=wrap(ai_skill_choice['kejieguixiaoshou'],'kejieguixiaoshou','ai_skill_choice')
ai_skill_choice['kejieguixiaoshou_equip']=wrap(ai_skill_choice['kejieguixiaoshou_equip'],'kejieguixiaoshou_equip','ai_skill_choice')
sgs.ai_skill_playerchosen['kejieguixiaoshou']=wrap(sgs.ai_skill_playerchosen['kejieguixiaoshou'],'kejieguixiaoshou','ai_skill_playerchosen')
sgs.ai_can_damagehp['kejieguifuwang']=wrap(sgs.ai_can_damagehp['kejieguifuwang'],'kejieguifuwang','ai_can_damagehp')
ai_fill_skill['kejieguishouye']=wrap(ai_fill_skill['kejieguishouye'],'kejieguishouye','ai_fill_skill')
ai_card_use['#kejieguishouyeCard']=wrap(ai_card_use['#kejieguishouyeCard'],'#kejieguishouyeCard','ai_card_use')
ai_fill_skill['kejieguijiehuo']=wrap(ai_fill_skill['kejieguijiehuo'],'kejieguijiehuo','ai_fill_skill')
ai_card_use['#kejieguijiehuoCard']=wrap(ai_card_use['#kejieguijiehuoCard'],'#kejieguijiehuoCard','ai_card_use')

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, player, value, defense_query, siblings, context)
        for _, sibling in ipairs(siblings) do
            if defense_query(sibling, "hasSkill", "keguiqinwang") and defense_query(sibling, "getPhase") == sgs.Player_NotActive
                and defense_query(self, "beFriend", sibling, player) then value = value + (defense_query(sibling, "getHandcardNum") + defense_query(sibling, "getHp")) * 0.5 break end
        end
        return value
    end
    local previous_1 = sgs.ai_skill_defense["keguiqinwang"]
    sgs.ai_skill_defense["keguiqinwang"] = function(self, player, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "after_health" and context.rule == "keguiqinwang" then
                return policy_1(self, player, context.value, context.query, context.extra[1], context)
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, player) end
        return previous_1
    end
    sgs.declareValueHookStages("ai_skill_defense", "keguiqinwang", {
        {phase="after_health", rule="keguiqinwang", order=8300},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["keguijingmu"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if from and damage_call(self,"isFriend",to, from) and damage_call(from,"getMark","keguijingmumark") > 0 then
        		return nil, true
        	end
        return value
    end
    sgs.ai_need_damaged["keguijingmu"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_after_legacy" and context.rule == "keguijingmumark" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "keguijingmu", {
        {phase="need_hp_after_legacy", order=13, rule="keguijingmumark"},
    })
end)()
end
