-- Existing source default; the package may replace it below.
if sgs.ai_ajustdamage_from.bu_s2_benxi == nil then
    sgs.ai_ajustdamage_from.bu_s2_benxi = function(self,from,to,card,nature)
        local damage_call, helpers = self:getDamageValueContext()
        return damage_call(to,"getMark","&bu_s2_benxi+#"..from:objectName().."-Clear")
    end
end

-- Source: b6025acc ai/olddiy-ai.lua.
local known = AIValue.requireKnown

local function visible(self,id)
 local c=self:getKnownCardById(id);if not c and type(self.getChoiceCard)=='function'then c=self:getChoiceCard(id)end
 return known(c,'olddiy disclosed physical card')
end
local function copy(t) local r={} for k,v in pairs(t)do r[k]=type(v)=='table' and copy(v) or v end;return r end
local dummy_plan = AIUsePlan.dummy
local classes={['#luajuaocard']='luajuao',['#zfduanhe']='zfduanhe',['#lyduji']='lyduji',['#lyxiance']='lyxiance',['#LuaFangxianCard']='LuaFangxian',['#dangqianCard']='dangqian',['#bu_s2_benxi']='bu_s2_benxi'}
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
 request=request or self._olddiy_request
 local row=printed_spec(text)
 if row then local base=known(self:getEvaluationCard(row.name),'printed prototype');local c=self:evaluateTurnConversion(row.skill,base:getClassName(),row,request);recipes[c]=row;return c end
 local cl,sk,cs,u=decode(text);local c=self:evaluateTurnSkillCard(sk,cl,cs,request,u);recipes[c]={prototype=cl,skill=sk,subcards=cs,user=u};return c
end
local function clone(self,name,suit,number,skill)
 local spec={source_key=self._olddiy_key or 'olddiy',name=name or 'slash',skill=skill or '',suit=suit or sgs.Card_NoSuit,number=number or 0,subcards={}}
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
 role=self:getRoleEstimate(p);if role==nil or role=='neutral'or role=='unknown'then ai_unsupported('private role is not resolved for this viewer','olddiy.role')end
 return self:useKnowledgeEstimate({value=role,status='estimate',basis='viewer_role_inference_replaces_private_role',viewer=self.player:objectName(),target=p:objectName()},'olddiy.role')
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
local function can_to(self,c,from,to)if from:objectName()~=self.player:objectName()then ai_unsupported('foreign targetFilter is not an owner query','olddiy')end;return self:cardTargetFilter(c,{},to)end
local function extra_targets(self,c)return known(self:getEvaluationCandidate(c):getExtraTargetCount(),'extra target modifier')end
local function same_player(a,b)return a and b and a:objectName()==b:objectName()end

local function selected_response(self,text)
 local spec=type(text)=='string'and printed_spec(text);if not spec then return text end
 local base=known(self:getEvaluationCard(spec.name),'selected printed response')
 local policy=known(self:getConversionPolicy(base:getClassName()),'selected response catalog');local source
 for _,row in ipairs(policy.skills or{})do if row.skill_name==spec.skill then source=row;break end end
 return known(self:resolveResponseConversion(spec,known(source,'exact selected response source')),'selected response receipt')
end

local function public_damage(self)
 -- Its only reader is a ChoiceMade filter; the live room tag is not projected there.
 ai_unsupported('Room CurrentDamageStruct is not projected','CurrentDamageStruct')
end
local function guicai_card(self)
 return self:getGuicaiCardEvaluation(self.player:getStrategyMark('bu_stwo_guicai'))
end
ai_fill_skill["luajuao"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:hasUsed("#luajuaocard") and not self.player:isKongcheng() then return policy(self,
		"#luajuaocard:.:") end
end

ai_card_use["#luajuaocard"] = function(self, card, use, request)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local use_card = nil
	handcards = self:sortByCardNeed(handcards, true)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local target = nil
	for _, c in ipairs(handcards) do
		if c:isKindOf("Slash") then
			use_card = c
		end
	end
	if use_card == nil then return end
	local red = 0
	for _, c in ipairs(handcards) do
		if c:isAvailable(self.player) then
			if c:isRed() and not c:isKindOf("Slash") then
				red = red + 1
			end
		end
	end
	local duel = clone(self,"duel", sgs.Card_NoSuit, 0)
	for _, enemy in ipairs(self.enemies) do
		if self:hasTrickEffective(duel, enemy, self.player) then
			if self.player:getHp() <= enemy:getHp() then
				red = red + 0.5
			end
			if self:getCardsNum("Slash") + red > getCardsNum("Slash", enemy) then
				target = enemy
			end
			if self.player:getHp() <= enemy:getHp() then
				red = red - 0.5
			end
		end
	end
	if target == nil then return end
	local card_str = string.format("#luajuaocard:%s:", use_card:getKnownEffectiveId())
	local acard = policy(self,card_str)
	use.card = acard
	do end
	if use.to then use.to:append(target) end
end
sgs.ai_use_priority.luajuaocard = sgs.ai_use_priority.XiechanCard
sgs.ai_use_value.luajuaocard = sgs.ai_use_value.XiechanCard
sgs.ai_card_intention.luajuaocard = sgs.ai_card_intention.XiechanCard

sgs.ai_cardneed.luajuao = function(to, card, self)
	return isCard("Slash", card, to) and getKnownCard(to, self.player, "Slash", true) == 0
end

ai_fill_skill["zfduanhe"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self:needBear() then return end
	if not self.player:hasUsed("#zfduanhe") then return policy(self,"#zfduanhe:.:") end
end

ai_card_use["#zfduanhe"] = function(self, card, use, request)
	self:updatePlayers()
	self.enemies = self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if #targets < 2 and self.player:canSlash(enemy, nil, true) and enemy:getStrategyMark("@zfduanhe-Clear") == 0 then
			table.insert(targets, enemy)
		else
			break
		end
	end
	if #targets < 2 then
		for _, enemy in ipairs(self.enemies) do
			if #targets < 2 and not table.contains(targets, enemy) and enemy:getStrategyMark("@zfduanhe-Clear") == 0 then
				table.insert(targets, enemy)
			else
				break
			end
		end
	end
	local slashcount = self:getCardsNum("Slash")
	if #targets > 0 and slashcount > 0 then
		use.card = policy(self,"#zfduanhe:.:")
		if use.to then
			for i = 1, #targets, 1 do
				use.to:append(targets[i])
			end
		end
		return
	end
end
sgs.ai_use_priority["zfduanhe"] = 7
sgs.ai_use_value["zfduanhe"] = 7
sgs.ai_card_intention["zfduanhe"] = 80

sgs.ai_cardneed.zfduanhe = sgs.ai_cardneed.slash


sgs.ai_cardneed.spwushen = function(to,card,self)
	return isCard("BasicCard",card,to) or card:getSuit() == sgs.Card_Heart
end

sgs.ai_skill_playerchosen["spwushen"] = function(self, targets)
    targets = sgs.QList2Table(targets)
	targets = self:sort(targets, "defense")
	local card=clone(self,"fire_slash",sgs.Card_Heart,0)
    do end
    card = mutate(self,card,"skill","spwushen")
    local dummy_use = self:aiUseCard(card, dummy_plan())
    if dummy_use.card and not dummy_use.to:isEmpty() then
        for _, p in sgs.qlist(dummy_use.to) do
            if table.contains(targets, p) then
                return p
            end
        end
    end
    local targetlist = sgs.QList2Table(targets)
	local arrBestHp,canAvoidSlash,forbidden = {},{},{}
	targetlist = self:sort(targetlist,"defenseSlash")
	for _,target in sgs.list(targetlist)do
		if self:isEnemy(target)
		and not self:slashProhibit(card,target)
		and self:isGoodTarget(target,targetlist) then
			if self:slashIsEffective(card,target) then
				if self:needToLoseHp(target,self.player,card)
				or self:needLeiji(target,self.player)
				then table.insert(forbidden,target)
				elseif self:needToLoseHp(target,self.player,card,true)
				then table.insert(arrBestHp,target)
				else return target end
			else
				table.insert(canAvoidSlash,target)
			end
		end
	end
	targetlist = sgs.reverse(targetlist)
	for _,target in sgs.list(targetlist)do
		if not self:slashProhibit(card,target) then
			if self:slashIsEffective(card,target) then
				if self:isFriend(target)
				and (self:needToLoseHp(target,self.player,card,true) or self:needLeiji(target,self.player))
				then return target end
			else
				table.insert(canAvoidSlash,target)
			end
		end
	end
	if #canAvoidSlash>0 then return canAvoidSlash[1] end
	if #arrBestHp>0 then return arrBestHp[1] end
	for _,target in sgs.list(targetlist)do
		if target:objectName()~=self.player:objectName()
		and not self:isFriend(target) and not table.contains(forbidden,target)
		then return target end
	end
	return nil
end

sgs.exclusive_skill = sgs.exclusive_skill .."|spwuhun"
sgs.ai_skill_playerchosen.spwuhun = function(self,targets)
	local targetlist=self:sort(targets,"hp")
	local target
	local lord
	for _,player in sgs.list(targetlist)do
		if player:isLord() then lord = player end
		if self:isEnemy(player) and (not target or target:getHp()<player:getHp()) then
			target = player
		end
	end
	if self.role=="rebel" and lord then return lord end
	if target then return target end

	if source_role(self,self.player)=="loyalist" and targetlist[1]:isLord() then return targetlist[2] end
	return targetlist[1]
end

-- getSpWuhunRevengeTargets is the existing common source method.
function sgs.ai_slash_prohibit.spwuhun(self,from,to)
	if from:hasSkill("jueqing") then return false end
	if from:getStrategyFlag("NosJiefanUsed") then return false end
	local damageNum = self:ajustDamage(from,to,1,clone(self))

	local maxfriendmark = 0
	local maxenemymark = 0
	for _,friend in sgs.list(self:getFriends(from))do
		local friendmark = friend:getStrategyMark("@spnightmare")
		if friendmark>maxfriendmark then maxfriendmark = friendmark end
	end
	for _,enemy in sgs.list(self:getEnemies(from))do
		local enemymark = enemy:getStrategyMark("@spnightmare")
		if enemymark>maxenemymark and enemy:objectName()~=to:objectName() then maxenemymark = enemymark end
	end
	if self:isEnemy(to,from) and not (to:isLord() and source_role(self,from)=="rebel") then
		if (maxfriendmark+damageNum>=maxenemymark) and not (#(self:getEnemies(from))==1 and #(self:getFriends(from))+#(self:getEnemies(from))==self.room:alivePlayerCount()) then
			if not (from:getStrategyMark("@spnightmare")==maxfriendmark and source_role(self,from)=="loyalist") then
				return true
			end
		end
	end
end




function sgs.ai_cardneed.lyduji(to, card)
	return card:getSuit() == sgs.Card_Spade
end

ai_fill_skill["lyduji"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local can_use = false
	self.enemies = self:sort(self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if a:canPindian(b) then can_use = true end
		end
	end
	if can_use
	then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		cards = self:sortByKeepValue(cards)
		for _,c in sgs.list(cards)do
			if not c:getSuit() == sgs.Card_Spade then continue end
			return policy(self,"#lyduji:"..c:getKnownEffectiveId()..":")
		end
	end
end

ai_card_use["#lyduji"] = function(self, card, use, request)
	self.enemies = self:sort(self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if a:canPindian(b)
			then
				use.card = card
				use.to:append(a)
				--use.to:append(b)
                self:setStrategyMemory("olddiy.lydujiTarget",b:objectName())
				return
			end
		end
	end
end
sgs.ai_skill_playerchosen.lyduji = function(self,targets)
	local enemies = self:sort(targets,"hp")
	local remembered,present=self:getStrategyMemory("olddiy.lydujiTarget")
    if present then return known(self.room:findPlayerByObjectName(remembered,true),"lyduji target") end
	for i,p in sgs.list(enemies)do
		if not self:isFriend(p)
		then return p end
	end
	return enemies[1]
end

sgs.ai_use_priority["lyduji"] = 2
sgs.ai_use_value["lyduji"] = 2.5
sgs.ai_card_intention["lyduji"] = 80

ai_fill_skill["lyxiance"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.friends_noself == 0 then return end
    if source_role(self,self.player) == "lord" then return end
	if not self.player:isKongcheng() and self:getOverflow() > 0 then
		return policy(self,"#lyxiance:.:")
	end
end

ai_card_use["#lyxiance"] = function(self, card, use, request)
    local lord = self.room:getLord()
    if lord and self:isFriend(lord) and self:canDraw(lord, self.player) then
        local use_card = false
        local cards = sgs.QList2Table(self.player:getHandcards())
        for _, acard in ipairs(cards) do
            if acard:isKindOf("TrickCard") then
                use_card = acard
                break
            end
        end
        if use_card then
            use.card = policy(self,"#lyxiance:".. use_card:getKnownEffectiveId()..":")
            if use.to then use.to:append(lord) end
            return
        end
	end
end

sgs.ai_card_intention["lyxiance"] = -80


sgs.ai_can_damagehp.lybeixi = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and card and card:isKindOf("Slash")
	then
		return self:isEnemy(from) and self:toTurnOver(from,from:getLostHp(),"lybeixi")
	end
end
ai_skill_invoke.lybeixi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toDamage().from
	if self:toTurnOver(target,target:getLostHp(),"lybeixi") then
        return (true) or false
    end
	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.lybeixi = function(self, player, promptlist)
	local damage = public_damage(self)
	if damage.from and promptlist[3]=="yes" then
		local intention = 80/math.max(player:getLostHp(),1)
        if not self:toTurnOver(damage.from,player:getLostHp()) then intention = -intention end
        if damage.from:getLostHp()<3 then
            self:updateIntention(player,damage.from,intention)
        else
            self:updateIntention(player,damage.from,math.min(intention,-30))
        end
	end
end


sgs.ai_getBestHp_skill.dj = function(owner)
	return owner:getMaxHp() - 1
end

sgs.ai_getBestHp_skill.pj = function(owner)
	return owner:getMaxHp() - 1
end

ai_skill_invoke.fjsp_youlong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	local slash = clone(self,"slash", sgs.Card_NoSuit, 0)
	do end
	if not self.player:faceUp() then
		if self.player:canSlash(damage.from, slash, false) then
			if self:isEnemy(damage.from) and self:isGoodTarget(damage.from, self.enemies, slash) and self:slashIsEffective(slash, damage.from, self.player) then
				return (true) or false
			end
		end
		if self.player:canSlash(damage.to, slash, false) then
			if self:isEnemy(damage.to) and self:isGoodTarget(damage.to, self.enemies, slash) and self:slashIsEffective(slash, damage.to, self.player) then
				return (true) or false
			end
		end
	else
		if self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player, true) >= 2 then
			if self.player:canSlash(damage.from, slash, false) then
				if self:isEnemy(damage.from) and self:isGoodTarget(damage.from, self.enemies, slash) and self:slashIsEffective(slash, damage.from, self.player) then
					return (true) or false
				end
			end
		end
		if self.player:canSlash(damage.to, slash, false) then
			if self:isEnemy(damage.to) and self:isGoodTarget(damage.to, self.enemies, slash) and self:slashIsEffective(slash, damage.to, self.player) then
				return (true) or false
			end
		end
	end
	return (false) or false
end

sgs.ai_skill_playerchosen.fjsp_youlong = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|fjsp_youlong"

ai_skill_use["@@dangqian"] = function(self, prompt, request)
	self.enemies = self:sort(self.enemies)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he") then
			table.insert(targets, enemy:objectName())
		end
		if #targets == self.player:getHp() then break end
	end

	if #targets < self.player:getHp() then
		for _, friend in ipairs(self.friends) do
			if self:doDisCard(friend, "he") then
				table.insert(targets, friend:objectName())
			end
			if #targets == self.player:getHp() then break end
		end
	end

	if #targets > 0 then
		return "#dangqianCard:.:->" .. table.concat(targets, "+")
	end
	return "."
end

sgs.ai_card_priority.dangqian = function(self, card)
	if table.contains(card:getSkillNames(), "longdan")
	then
		return 1
	end
end


ai_skill_invoke.LuaJuecaiA = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return  (not self:needKongcheng(self.player, true) and not hasManjuanEffect(self.player)) or false
end
ai_skill_invoke.LuaJuecaiB = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local dest = data:toPlayer()
	return (self:doDisCard(dest, "he")) or false
end

ai_skill_invoke.cuoyong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:hasSkill("haoshi") then
		local num = self.player:getHandcardNum()
		local skills = self.player:getVisibleSkillList(true)
		local count = self:ImitateResult_DrawNCards(self.player, skills)
		if num + count > 5 then
			local others = self.room:getOtherPlayers(self.player)
			local least = 999
			local target = nil
			for _,p in sgs.qlist(others) do
				local handcardnum = p:getHandcardNum()
				if handcardnum < least then
					least = handcardnum
					target = p
				end
			end
			if target then
				if self:isFriend(target) then
					return (not target:hasSkill("manjuan")) or false
				end
			end
		end
	end
	return (true) or false
end


ai_fill_skill["LuaFangxian"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:hasUsed("#LuaFangxianCard") or self.player:isKongcheng() then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local card = cards[1]
	for _,c in ipairs(cards) do if c:getSuit() == sgs.Card_Diamond then card = c end end
	for _,c in ipairs(cards) do if c:getSuit() == sgs.Card_Heart then card = c end end
	return policy(self,"#LuaFangxianCard:"..card:getKnownEffectiveId()..":")
end

ai_card_use["#LuaFangxianCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_skill_askforag["LuaFangxian"] = function(self, card_ids)
	local card_id = -1
	local re_id
	local re_n = 0
	local jink_id, peach_id, analeptic_id, ex_nihilo_id, nullification_id
	for _, id in ipairs(card_ids) do
		local target = self.room:getCardOwner(id)
		local card = visible(self,id)
		if self:isFriend(target) then
			local n = target:getHandcardNum() - target:getHp()
			if target:getHp() > 1 and n > 2 and card:isKindOf("Jink") then
				if re_n > n then re_n = n re_id = id end
			end
			continue
		end
		card_id = id
		if card:isKindOf("Jink") then jink_id = id end
		if card:isKindOf("Analeptic") then analeptic_id = id end
		if card:isKindOf("ExNihilo") then ex_nihilo_id = id end
		if card:isKindOf("Nullification") then nullification_id = id end
		if card:isKindOf("Peach") then peach_id = id end
	end
	if jink_id then card_id = jink_id end
	if analeptic_id then card_id = analeptic_id end
	if ex_nihilo_id then card_id = ex_nihilo_id end
	if nullification_id then card_id = nullification_id end
	if peach_id then card_id = peach_id end
	if card_id == -1 and re_id and self:getCardsNum("Jink") < 1 and self.player:getHp() < 2 then card_id = re_id end
	return card_id
end

sgs.ai_use_value["LuaFangxianCard"] = 9
sgs.ai_use_priority["LuaFangxianCard"] = 9.2

sgs.ai_skill_playerchosen["LuaGaobi"] = function(self, targets)
	if #self.friends_noself < 1 then return self.player end
	local keepsNum = self:getCardsNum("Jink") + self:getCardsNum("Nullification") + self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self:getCardsNum("Slash")
	if self:getCardsNum("Slash") > 0 and known(data_fact(self,'slash_available'),'Slash::IsAvailable') then keepsNum = keepsNum -1 end
	if self:getCardsNum("Peach") > 0 and self.player:isWounded() then keepsNum = keepsNum -1 end
	if self.player:getMaxCards() < keepsNum then return self.player end
	local target
	local t_num = - 10086
	for _, friend in ipairs(self.friends_noself) do
		local n = friend:getHandcardNum() - friend:getMaxCards()
		if n > t_num then
			t_num = n
			target = friend
		end
		if n > 0 and friend:getHp() < 2 then return friend end
	end
	return target or self.player
end

function sgs.ai_cardneed.LuaChuanyun(to, card, self)
	local cards = observed_hand(self,to)
	local has_weapon = to:getWeapon() and not to:getWeapon():isKindOf("Crossbow")
	local slash_num = 0
	for _, c in sgs.qlist(cards) do
		local flag=string.format("%s_%s_%s","visible",self.room:getCurrent():objectName(),to:objectName())
		if c:getStrategyFlag("visible") or c:getStrategyFlag(flag) then
			if c:isKindOf("Weapon") and not c:isKindOf("Crossbow") then
				has_weapon=true
			end
			if c:isKindOf("Slash") then slash_num = slash_num +1 end
		end
	end

	if not has_weapon then
		return card:isKindOf("Weapon") and not card:isKindOf("Crossbow")
	else
		return to:hasWeapon("spear") or card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic"))
	end
end

sgs.LuaChuanyun_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.6,
	Slash = 5.4,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}

function sgs.ai_cardneed.LuaPaoxiaoC(to, card, self)
	local cards = observed_hand(self,to)
	local has_weapon = to:getWeapon() and not to:getWeapon():isKindOf("Crossbow")
	local slash_num = 0
	for _, c in sgs.qlist(cards) do
		local flag=string.format("%s_%s_%s","visible",self.room:getCurrent():objectName(),to:objectName())
		if c:getStrategyFlag("visible") or c:getStrategyFlag(flag) then
			if c:isKindOf("Weapon") and not c:isKindOf("Crossbow") then
				has_weapon=true
			end
			if c:isKindOf("Slash") then slash_num = slash_num +1 end
		end
	end

	if not has_weapon then
		return card:isKindOf("Weapon") and not card:isKindOf("Crossbow")
	else
		return to:hasWeapon("spear") or card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic"))
	end
end

sgs.LuaPaoxiaoC_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.6,
	Slash = 5.4,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}





ai_skill_invoke.LuaLongya = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	local target = damage.to
	if self:isEnemy(target) then
		if self.player:getStrategyMark("&zhican") < 6 then return (false) or false end
		if self:isWeak(target) then return (false) or false end
		if hasZhaxiangEffect(target) then return (false) or false end
		return (true) or false
	end
	return (false) or false
end


ai_skill_invoke["#LuaLongyaT"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if self:isEnemy(target) then
		if self.player:getStrategyMark("&zhican") < 6 then return (false) or false end
		if self:isWeak(target) then return (false) or false end
		if hasZhaxiangEffect(target) then return (false) or false end
		return (true) or false
	end
	return (false) or false
end




ai_fill_skill["krskitgjiamian"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local jink_card

	cards = self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getKnownEffectiveId()
	local card_str = ("slash:krskitgjiamian[%s:%s]=%d"):format(suit, number, card_id)
	local slash = policy(self,card_str)
	assert(slash)

	return slash
end

sgs.ai_view_as.krskitgjiamian = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place ~= sgs.Player_PlaceEquip then
		if card:isKindOf("Jink") then
			return ("slash:krskitgjiamian[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:krskitgjiamian[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end


sgs.krskitgjiamian_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.8,
	FireSlash = 5.7,
	Slash = 5.9,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}

sgs.ai_card_priority.krskitgjiamian = function(self,card)
	if table.contains(card:getSkillNames(), "krskitgjiamian") and self.player:getHandcardNum() <= 1
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

ai_skill_invoke.krskitgjiamian = true
sgs.ai_skill_playerchosen.krskitgjiamian = function(self, targets)
	targets = self:sort(targets, "handcard")
	for _, enemy in ipairs(targets) do
		if not self:isFriend(enemy) and self:doDisCard(enemy, "h", true) then
			return enemy
		end
	end
end
sgs.ai_playerchosen_intention.krskitgjiamian = function(self, from, to)
 -- Preserve the fixed donor's wrong-arity ordinary failure at the actual event ABI.
 sgs.ai_doNotUpdateIntenion=nil
 error("attempt to call a nil value (method 'objectName')",0)
end


ai_skill_invoke.qingyue = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	local target = damage.to
	if target  then
		if self:isFriend(target) then
			if(target:hasSkill("kongcheng") or target:hasSkill("lianying") or target:hasSkill("tuntian")) and target:getHandcardNum() == 1 then
			return (true) or false
			end
		else
	return (not target:hasSkill("kongcheng")) or false
		end
	end
	return (false) or false
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|xhjtangqiang"

sgs.ai_ajustdamage_from.bu_s2_jiashe = function(self,from,to,slash,nature)
	if to:getStrategyMark("&bu_s2_jiashe+#"..from:objectName()) > 0 then
		return -99
	end
end
sgs.ai_ajustdamage_from.bu_s2_benxi = function(self,from,to,slash,nature)
	return to:getStrategyMark("&bu_s2_benxi+#"..from:objectName().."-Clear")
end


ai_fill_skill["bu_s2_benxi"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:canDiscard(self.player,"he") then return end
	return policy(self,"#bu_s2_benxi:.:")
end

ai_card_use["#bu_s2_benxi"] = function(self, card, use, request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self.enemies = self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	cards = self:sortByUseValue(cards,true)
	if slashcount > 0  then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = self:aiUseCardWithOwnerFlag(slash,dummy_plan(true),"InfinityAttackRange","bu_s2_benxi")
		if dummy_use.card and dummy_use.to:length() > 0 then
			local target
			for _,p in sgs.list(dummy_use.to)do
				if not self.player:inMyAttackRange(p) or self:doDisCard(p, "he", true) then
					target = p
				end
			end
			if target then
			use.card = policy(self,"#bu_s2_benxi:.:")
					if use.to then use.to:append(target) end
					return
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if self:doDisCard(enemy, "he", true) then
				use.card = policy(self,"#bu_s2_benxi:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_card_intention["bu_s2_benxi"] = 70


sgs.ai_use_value["bu_s2_benxi"] = 9.2
sgs.ai_use_priority["bu_s2_benxi"] = sgs.ai_use_priority.Slash + 0.1

ai_skill_invoke.bu_stwo_guicai = true
sgs.ai_skill_discard.bu_stwo_guicai = function(self, discard_num, min_num, optional, include_equip)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		if not current:containsTrick("YanxiaoCard") then
			if (current:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies))
				or (current:containsTrick("lightning") and #self.friends > #self.enemies) then
				return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
			elseif current:containsTrick("supply_shortage") then
				return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
			elseif current:containsTrick("indulgence") then
				if self.player:getHandcardNum() > 3 or self.player:getHandcardNum() > self.player:getHp() - 1 then return self:askForDiscard("dummyreason", discard_num, min_num, false, true) end
				for _, friend in ipairs(self.friends_noself) do
					if not friend:containsTrick("YanxiaoCard") and (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
						return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
					end
				end
			end
		end
	elseif current and self:isEnemy(current) then
		return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
	end
	return false
end
ai_skill_choice.bu_stwo_guicai = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		return ai_choice_result(("skip"), options)
	end
	return ai_choice_result(("effect"), options)
end

sgs.ai_choicemade_filter.skillChoice["bu_stwo_guicai"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local current = self.room:getCurrent()
	if choice == "effect" then
		self:updateIntention(player, current, 60)
	else
		self:updateIntention(player, current, -60)
	end
end

ai_skill_use["@@bu_stwo_guicai"] = function(self, prompt, request)
	local method = request and request.handling_method
	local card = guicai_card(self)
	-- The scoped readonly descriptor carries the source skill, without changing a live physical card.

	local dummy_use = self:aiUseCard(card)
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return card:getLegacyStringKey() .. "->" .. table.concat(targets, "+")
		end
	end
	return "."
end
sgs.ai_can_damagehp.bu_stwo_guicai = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and #self.enemies > 0
end


local function wrap(f,key,kind)
 return function(...)
  local a=table.pack(...);local self
  for i=1,a.n do if type(a[i])=='table' and a[i].player and a[i].world and a[i].request then self=a[i];break end end
  if not self then return f(...)end
  local prior,request=self._olddiy_key,self._olddiy_request;self._olddiy_key=key
  if kind=='ai_fill_skill'then self._olddiy_request=a[3]end
  local r=table.pack(pcall(f,table.unpack(a,1,a.n)));self._olddiy_key=prior;self._olddiy_request=request
  if not r[1]then error(r[2],0)end
  if kind=='ai_skill_use'then
   if key=='@@bu_stwo_guicai'then r[2]=self:guicaiSourceResult(r[2])else r[2]=response(self,r[2])end
  end
  return table.unpack(r,2,r.n)
 end
end
ai_fill_skill['luajuao']=wrap(ai_fill_skill['luajuao'],'luajuao','ai_fill_skill')
ai_card_use['#luajuaocard']=wrap(ai_card_use['#luajuaocard'],'#luajuaocard','ai_card_use')
sgs.ai_cardneed['luajuao']=wrap(sgs.ai_cardneed['luajuao'],'luajuao','ai_cardneed')
ai_fill_skill['zfduanhe']=wrap(ai_fill_skill['zfduanhe'],'zfduanhe','ai_fill_skill')
ai_card_use['#zfduanhe']=wrap(ai_card_use['#zfduanhe'],'#zfduanhe','ai_card_use')
sgs.ai_cardneed['spwushen']=wrap(sgs.ai_cardneed['spwushen'],'spwushen','ai_cardneed')
sgs.ai_skill_playerchosen['spwushen']=wrap(sgs.ai_skill_playerchosen['spwushen'],'spwushen','ai_skill_playerchosen')
sgs.ai_skill_playerchosen['spwuhun']=wrap(sgs.ai_skill_playerchosen['spwuhun'],'spwuhun','ai_skill_playerchosen')
sgs.ai_slash_prohibit['spwuhun']=wrap(sgs.ai_slash_prohibit['spwuhun'],'spwuhun','ai_slash_prohibit')
sgs.ai_cardneed['lyduji']=wrap(sgs.ai_cardneed['lyduji'],'lyduji','ai_cardneed')
ai_fill_skill['lyduji']=wrap(ai_fill_skill['lyduji'],'lyduji','ai_fill_skill')
ai_card_use['#lyduji']=wrap(ai_card_use['#lyduji'],'#lyduji','ai_card_use')
sgs.ai_skill_playerchosen['lyduji']=wrap(sgs.ai_skill_playerchosen['lyduji'],'lyduji','ai_skill_playerchosen')
ai_fill_skill['lyxiance']=wrap(ai_fill_skill['lyxiance'],'lyxiance','ai_fill_skill')
ai_card_use['#lyxiance']=wrap(ai_card_use['#lyxiance'],'#lyxiance','ai_card_use')
sgs.ai_can_damagehp['lybeixi']=wrap(sgs.ai_can_damagehp['lybeixi'],'lybeixi','ai_can_damagehp')
ai_skill_invoke['lybeixi']=wrap(ai_skill_invoke['lybeixi'],'lybeixi','ai_skill_invoke')
sgs.ai_getBestHp_skill['dj']=wrap(sgs.ai_getBestHp_skill['dj'],'dj','ai_getBestHp_skill')
sgs.ai_getBestHp_skill['pj']=wrap(sgs.ai_getBestHp_skill['pj'],'pj','ai_getBestHp_skill')
ai_skill_invoke['fjsp_youlong']=wrap(ai_skill_invoke['fjsp_youlong'],'fjsp_youlong','ai_skill_invoke')
ai_skill_use['@@dangqian']=wrap(ai_skill_use['@@dangqian'],'@@dangqian','ai_skill_use')
sgs.ai_card_priority['dangqian']=wrap(sgs.ai_card_priority['dangqian'],'dangqian','ai_card_priority')
ai_skill_invoke['LuaJuecaiA']=wrap(ai_skill_invoke['LuaJuecaiA'],'LuaJuecaiA','ai_skill_invoke')
ai_skill_invoke['LuaJuecaiB']=wrap(ai_skill_invoke['LuaJuecaiB'],'LuaJuecaiB','ai_skill_invoke')
ai_skill_invoke['cuoyong']=wrap(ai_skill_invoke['cuoyong'],'cuoyong','ai_skill_invoke')
ai_fill_skill['LuaFangxian']=wrap(ai_fill_skill['LuaFangxian'],'LuaFangxian','ai_fill_skill')
ai_card_use['#LuaFangxianCard']=wrap(ai_card_use['#LuaFangxianCard'],'#LuaFangxianCard','ai_card_use')
sgs.ai_skill_askforag['LuaFangxian']=wrap(sgs.ai_skill_askforag['LuaFangxian'],'LuaFangxian','ai_skill_askforag')
sgs.ai_skill_playerchosen['LuaGaobi']=wrap(sgs.ai_skill_playerchosen['LuaGaobi'],'LuaGaobi','ai_skill_playerchosen')
sgs.ai_cardneed['LuaChuanyun']=wrap(sgs.ai_cardneed['LuaChuanyun'],'LuaChuanyun','ai_cardneed')
sgs.ai_cardneed['LuaPaoxiaoC']=wrap(sgs.ai_cardneed['LuaPaoxiaoC'],'LuaPaoxiaoC','ai_cardneed')
ai_skill_invoke['LuaLongya']=wrap(ai_skill_invoke['LuaLongya'],'LuaLongya','ai_skill_invoke')
ai_skill_invoke['#LuaLongyaT']=wrap(ai_skill_invoke['#LuaLongyaT'],'#LuaLongyaT','ai_skill_invoke')
ai_fill_skill['krskitgjiamian']=wrap(ai_fill_skill['krskitgjiamian'],'krskitgjiamian','ai_fill_skill')
do local f=sgs.ai_view_as['krskitgjiamian'];sgs.ai_view_as['krskitgjiamian']=function(...)return proposal(f(...))end end
sgs.ai_card_priority['krskitgjiamian']=wrap(sgs.ai_card_priority['krskitgjiamian'],'krskitgjiamian','ai_card_priority')
sgs.ai_skill_playerchosen['krskitgjiamian']=wrap(sgs.ai_skill_playerchosen['krskitgjiamian'],'krskitgjiamian','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['krskitgjiamian']=wrap(sgs.ai_playerchosen_intention['krskitgjiamian'],'krskitgjiamian','ai_playerchosen_intention')
ai_skill_invoke['qingyue']=wrap(ai_skill_invoke['qingyue'],'qingyue','ai_skill_invoke')
sgs.ai_ajustdamage_from['bu_s2_jiashe']=wrap(sgs.ai_ajustdamage_from['bu_s2_jiashe'],'bu_s2_jiashe','ai_ajustdamage_from')
sgs.ai_ajustdamage_from['bu_s2_benxi']=wrap(sgs.ai_ajustdamage_from['bu_s2_benxi'],'bu_s2_benxi','ai_ajustdamage_from')
ai_fill_skill['bu_s2_benxi']=wrap(ai_fill_skill['bu_s2_benxi'],'bu_s2_benxi','ai_fill_skill')
ai_card_use['#bu_s2_benxi']=wrap(ai_card_use['#bu_s2_benxi'],'#bu_s2_benxi','ai_card_use')
sgs.ai_skill_discard['bu_stwo_guicai']=wrap(sgs.ai_skill_discard['bu_stwo_guicai'],'bu_stwo_guicai','ai_skill_discard')
ai_skill_choice['bu_stwo_guicai']=wrap(ai_skill_choice['bu_stwo_guicai'],'bu_stwo_guicai','ai_skill_choice')
ai_skill_use['@@bu_stwo_guicai']=wrap(ai_skill_use['@@bu_stwo_guicai'],'@@bu_stwo_guicai','ai_skill_use')
sgs.ai_can_damagehp['bu_stwo_guicai']=wrap(sgs.ai_can_damagehp['bu_stwo_guicai'],'bu_stwo_guicai','ai_can_damagehp')

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["qingyue"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(from,"hasSkill","qingyue") and card and damage_call(card,"isKindOf","Slash") and damage_call(to,"isMale") then
        		return nil, true
        	end
        return value
    end
    sgs.ai_need_damaged["qingyue"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_before_damage" and context.rule == "qingyue" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "qingyue", {
        {phase="need_hp_before_damage", order=7, rule="qingyue"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_need_damaged["spmengyan"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(from,"hasSkill","spmengyan") and damage_call(from,"hasSkill","spwuhun") then
        		return nil, true
        	end
        return value
    end
    sgs.ai_need_damaged["spmengyan"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_before_damage" and context.rule == "spmengyan" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "spmengyan", {
        {phase="need_hp_before_damage", order=15, rule="spmengyan"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_need_damaged["bu_s2_jiashe"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(from,"hasSkill","bu_s2_jiashe") and damage_call(self,"ajustDamage",from,to,1,card)>damage_call(to,"getHp") then
        		return nil, true
        	end
        return value
    end
    sgs.ai_need_damaged["bu_s2_jiashe"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_before_damage" and context.rule == "bu_s2_jiashe" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "bu_s2_jiashe", {
        {phase="need_hp_before_damage", order=19, rule="bu_s2_jiashe"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_skill_defense["retaliation.wuhun"]
    local policy = function(self, to, context)
        local value, core_query = context.value, context.query
        local from, damageNum, role = context.extra[1], context.extra[2], context.extra[3]
        if (core_query(to,"hasSkill","wuhun") or core_query(to,"hasSkills","spwuhun") or core_query(to,"hasSkills","sgkgodsuohun")) and not core_query(to,"isLord") and #core_query(self,"getFriends",to,true)>0 then
        		local maxfriendmark,maxenemymark = 0,0
        		for friendmark,friend in sgs.list(core_query(self,"getFriends",from))do
                    friendmark = core_query(friend,"getMark","&nightmare+#"..core_query(to,"objectName"))
        			if friendmark>maxfriendmark then maxfriendmark = friendmark end
        		end
        		for enemymark,enemy in sgs.list(core_query(self,"getEnemies",from))do
                    enemymark = core_query(enemy,"getMark","&nightmare+#"..core_query(to,"objectName"))
        			if enemymark>maxenemymark and enemy~=to
        			then maxenemymark = enemymark end
        		end
        		if core_query(self,"isEnemy",to,from) then
        			if maxfriendmark+damageNum-core_query(to,"getHp")/2>=maxenemymark
        			and not (#core_query(self,"getEnemies",from)==1 and #core_query(self,"getFriends",from)+#core_query(self,"getEnemies",from)==core_query(self.room,"alivePlayerCount"))
                    and not (core_query(from,"getMark","&nightmare+#"..core_query(to,"objectName"))==maxfriendmark and role(self,from)=="loyalist")
        			then return true, true end
        		elseif maxfriendmark+damageNum-core_query(to,"getHp")/2>maxenemymark
        		then return true, true end
        	end
        return value
    end
    sgs.ai_skill_defense["retaliation.wuhun"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "retaliation" and context.rule == "wuhun" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
        return previous
    end
    sgs.declareValueHookStages("ai_skill_defense", "retaliation.wuhun", {
        {phase="retaliation", order=1, rule="wuhun"},
    })
end)()
end
