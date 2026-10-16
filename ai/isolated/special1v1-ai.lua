-- Fixed b6025acc source bodies; request-scoped readonly planning and selected payment.
local function known(v,k) if AIUnsupported.is(v) then error(v,0) end;if v==nil then ai_unsupported('special1v1 value is not observed',k) end;return v end

local function visible(self,id)
 local c=self:getKnownCardById(id);if not c and type(self.getChoiceCard)=='function'then c=self:getChoiceCard(id)end
 return known(c,'special1v1 disclosed physical card')
end
local function copy(t) local r={} for k,v in pairs(t)do r[k]=type(v)=='table' and copy(v) or v end;return r end
local function dummy_plan(v,extra,current) local u=AIUsePlan.new();u.isDummy=v~=false;u.extra_target=extra or 0;u.current_targets=current or {};return u end
local classes={['XiechanCard']='xiechan',['MouzhuCard']='mouzhu',['PujiCard']='puji',['CangjiCard']='cangji'}
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
 request=request or self._special1v1_request
 local row=printed_spec(text)
 if row then local base=known(self:getEvaluationCard(row.name),'printed prototype');local c=self:evaluateTurnConversion(row.skill,base:getClassName(),row,request);recipes[c]=row;return c end
 local cl,sk,cs,u=decode(text);local c=self:evaluateTurnSkillCard(sk,cl,cs,request,u);recipes[c]={prototype=cl,skill=sk,subcards=cs,user=u};return c
end
local function clone(self,name,suit,number,skill)
 local spec={source_key=self._special1v1_key or 'special1v1',name=name or 'slash',skill=skill or '',suit=suit or sgs.Card_NoSuit,number=number or 0,subcards={}}
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
 role=self:getRoleEstimate(p);if role==nil or role=='neutral'or role=='unknown'then ai_unsupported('private role is not resolved for this viewer','special1v1.role')end
 return self:useKnowledgeEstimate({value=role,status='estimate',basis='viewer_role_inference_replaces_private_role',viewer=self.player:objectName(),target=p:objectName()},'special1v1.role')
end
local function observed_hand(self,p)
 if p:objectName()==self.player:objectName()then return known(p:getHandcards(),'owner hand')end
 -- These source loops themselves filter visible/visible_observer flags. No hidden face is inspected.
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
local function can_to(self,c,from,to)if from:objectName()~=self.player:objectName()then ai_unsupported('foreign targetFilter is not an owner query','special1v1')end;return self:cardTargetFilter(c,{},to)end
local function extra_targets(self,c)return known(self:getEvaluationCandidate(c):getExtraTargetCount(),'extra target modifier')end
local function same_player(a,b)return a and b and a:objectName()==b:objectName()end

local function selected_response(self,text)
 local spec=type(text)=='string'and printed_spec(text);if not spec then return text end
 local base=known(self:getEvaluationCard(spec.name),'selected printed response')
 local policy=known(self:getConversionPolicy(base:getClassName()),'selected response catalog');local source
 for _,row in ipairs(policy.skills or{})do if row.skill_name==spec.skill then source=row;break end end
 return known(self:resolveResponseConversion(spec,known(source,'exact selected response source')),'selected response receipt')
end
function SmartAIView:useCardDrowning(card,use)
	self.enemies = self:sort(self.enemies)
	local equip_enemy = {}
	local extraTarget = extra_targets(self,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,enemy in sgs.list(self.enemies)do
		if isCurrent(use,enemy) then continue end
		if self:isGoodTarget(enemy,self.enemies,card)
		then
			if enemy:isChained()
			then
				if self:isGoodChainTarget(enemy,card)
				then else continue end
			end
			if enemy:hasEquip() then table.insert(equip_enemy,enemy)
			elseif can_to(self,card,self.player,enemy)
			then
				use.card = card
				use.to:append(enemy)
				if use.to:length()>extraTarget
				then return end
			end
		end
	end
	if #equip_enemy>0
	then
		equip_enemy = self:sort(equip_enemy,"equip",true)
		for _,enemy in sgs.list(equip_enemy)do
			if #self:poisonCards("e",enemy)<enemy:getEquips():length()/2
			and can_to(self,card,self.player,enemy)
			and self:isGoodTarget(enemy,self.enemies,card)
			then
				use.card = card
				use.to:append(enemy)
				if use.to:length()>extraTarget
				then return end
			end
		end
	end
	for _,friend in sgs.list(self.friends_noself)do
		if isCurrent(use,friend) then continue end
		local n = 0
		for _,e in sgs.list(friend:getEquips())do
			if self:doDisCard(friend,e:getKnownEffectiveId())
			then n = n+1 else n = n-1 end
		end
		if friend:isChained()
		then
			if self:isGoodChainTarget(friend,card)
			and self:damageIsEffective(friend,card,self.player)
			then else continue end
		elseif n<1 then continue end
		if can_to(self,card,self.player,friend)
		then
			use.card = card
			use.to:append(friend)
			if use.to:length()>extraTarget
			then return end
		end
	end
end

sgs.ai_card_intention.Drowning = function(self,card,from,tos)
	for _,to in sgs.list(tos)do
		if not self:hasTrickEffective(card,to,from) or self:needToThrowArmor(to) then
		else self:updateIntention(from,to,80) end
	end
end

sgs.ai_use_value.Drowning = 5
sgs.ai_use_priority.Drowning = 7

sgs.card_damage_nature.Drowning = "T"

sgs.ai_skill_choice.drowning = function(self,choices,data)
	local effect = data:toCardEffect()
	if not self:damageIsEffective(self.player,sgs.DamageStruct_Thunder,effect.from)
	or self:needToLoseHp(self.player,effect.from,effect.card)
	then return "damage" end
	if self:isWeak() and not self:needDeath() then return "throw" end
	local value = 0
	if self.player:isChained()
	and self:isGoodChainTarget(self.player,effect.card,effect.from)
	then
		if self:isFriend(effect.from) then value = 99
		else value = -7 end
	end
	for _,equip in sgs.list(self.player:getEquips())do
		value = value+self:evaluateArmor(equip)
		if equip:isKindOf("Weapon") then value = value+self:evaluateWeapon(equip)
		elseif equip:isKindOf("OffensiveHorse") then value = value+2.5
		elseif equip:isKindOf("DefensiveHorse") then value = value+5 end
	end
	if value<8 then return "throw" else return "damage" end
end

sgs.ai_skill_playerchosen.koftuxi = function(self,targets)
 local selected=self:selectNosTuxiTargets('@nostuxi')
 return selected[1]
end

sgs.ai_playerchosen_intention.koftuxi = function(self,from,to)
	local lord = self.room:getLord()
	if self:getRoleEstimate(from)=="neutral" and self:getRoleEstimate(to)=="neutral"
		and lord and not lord:isKongcheng()
		and self:doDisCard(lord,"h",true) and #self.room:getAlivePlayers()>=4 then
		self:updateIntention(from,lord,-35)
		return
	end
	if from:getState()=="online" then
		if (to:hasSkills("kongcheng|zhiji|noslianying") and to:getHandcardNum()==1) or hasTuntianEffect(to, true) then
		else
			self:updateIntention(from,to,80)
		end
	else
		local intention = from:getStrategyFlag("tuxi_isfriend_"..to:objectName()) and -5 or 80
		self:updateIntention(from,to,intention)
	end
end

sgs.ai_nullification.Drowning = function(self,trick,from,to,positive,null_num)
	if self:needToThrowArmor(to)
	then return false
	elseif positive
	then
        if null_num>1
		then
			return self:isFriend(to) and (to:getEquips():length()>1 or to:getEquips():length()<1)
			or to:objectName()==self.player:objectName()
		else
			return self:isFriend(to) and self:isWeak(to)
			and (to:getEquips():length()>1 or to:getEquips():length()<1)
			or to:objectName()==self.player:objectName()
		end
	else
        if null_num>1
		then
			return self:isEnemy(to)
			and (to:getEquips():length()>1 or to:getEquips():length()<1)
		else
			return self:isEnemy(to)
			and (to:getEquips():length()>1 or to:getEquips():length()<1)
			and self:isWeak(to)
		end
	end
end


sgs.ai_fill_skill["xiechan"] = function(self,inclusive,request)
	self.enemies = self:sort(self.enemies,"handcard")
	if self.player:hasSkill("nosluoyi") and not self.player:getStrategyFlag("nosluoyi") then return end
	return policy(self,"@XiechanCard=.")
end

sgs.ai_skill_use_func.XiechanCard = function(card,use,self)
	self:setStrategyPlayerFlag(self.player,"AI_XiechanUsing",true)
	local max_card = self:getMaxCard()
	self:setStrategyPlayerFlag(self.player,"AI_XiechanUsing",false)
	if max_card:isKindOf("Slash") and self:getCardsNum("Slash")<=2 then return end
	local max_point = max_card:getNumber()

	local dummy_use = dummy_plan()
	dummy_use.xiechan = true
	local duel = clone(self,"Duel")
	self:useCardDuel(duel,dummy_use)
	if not dummy_use.card or not dummy_use.card:isKindOf("Duel") then return end
	for _,enemy in sgs.list(dummy_use.to)do
		if self.player:canPindian(enemy) and not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) then
			local enemy_max_card = self:getMaxCard(enemy)
			local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
			if max_point>enemy_max_point then
				self:remember("xiechan_card",max_card:getId())
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
end

sgs.ai_view_as.kofqingguo = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place==sgs.Player_PlaceEquip then
		return ("jink:kofqingguo[%s:%s]=%d"):format(suit,number,card_id)
	end
end

function sgs.ai_cardneed.kofqingguo(to,card)
	if card:isKindOf("Weapon") then return not to:getWeapon()
	elseif card:isKindOf("Armor") then return not to:getArmor()
	elseif card:isKindOf("OffensiveHorse") then return not to:getOffensiveHorse()
	elseif card:isKindOf("DefensiveHorse") then return not to:getDefensiveHorse()
	end
	return false
end


sgs.ai_skill_invoke.kofliegong = sgs.ai_skill_invoke.liegong

function sgs.ai_cardneed.kofliegong(to,card,self)
	return isCard("Slash",card,to) and getKnownCard(to,self.player,"Slash",true)==0
end

sgs.ai_skill_invoke.yinli = sgs.ai_skill_invoke.luoying

sgs.ai_skill_askforag.yinli = function(self,card_ids)
	if self:needKongcheng(self.player,true) then return card_ids[1] else return -1 end
end

sgs.ai_skill_choice.kofxiaoji = function(self,choices)
	if choices:match("recover") then return "recover" else return "draw" end
end

sgs.kofxiaoji_keep_value = sgs.xiaoji_keep_value

sgs.ai_cardneed.kofxiaoji = sgs.ai_cardneed.equip

sgs.ai_skill_invoke.suzi = true
sgs.ai_skill_invoke.cangji = true

sgs.ai_skill_use["@@cangji"] = function(self,prompt)
	for i = 0,3,1 do
		local equip = self.player:getEquip(i)
		if type(equip)=="number" then equip=visible(self,equip) end
		if not equip then continue end
		self.friends_noself = self:sort(self.friends_noself)
		if i==0 then
			if equip:isKindOf("Crossbow") or equip:isKindOf("Blade") then
				for _,friend in sgs.list(self.friends_noself)do
					if not self:getSameEquip(equip) and not self:hasCrossbowEffect(friend) and getCardsNum("Slash",friend,self.player)>1 then
						return "@CangjiCard="..equip:getKnownEffectiveId().."->"..friend:objectName()
					end
				end
			elseif equip:isKindOf("Axe") then
				for _,friend in sgs.list(self.friends_noself)do
					if not self:getSameEquip(equip)
						and (friend:getCardCount()>=4
							or (friend:getCardCount()>=2 and self:ajustDamage(friend,nil,1,clone(self)))>1) then
						return "@CangjiCard="..equip:getKnownEffectiveId().."->"..friend:objectName()
					end
				end
			end
		end
		for _,friend in sgs.list(self.friends_noself)do
			if not self:getSameEquip(equip,friend) and not (i==1 and (self:evaluateArmor(equip,friend)<=0 or friend:hasSkills("bazhen|yizhong"))) then
				return "@CangjiCard="..equip:getKnownEffectiveId().."->"..friend:objectName()
			end
		end
		if equip:isKindOf("SilverLion") then
			for _,enemy in sgs.list(self.enemies)do
				if not enemy:getArmor() and enemy:hasSkills("bazhen|yizhong") then
					return "@CangjiCard="..equip:getKnownEffectiveId().."->"..enemy:objectName()
				end
			end
		end
	end
	return "."
end

sgs.ai_card_intention.CangjiCard = function(self,card,from,tos)
	local to = tos[1]
	local equip = visible(self,card:getKnownEffectiveId())
	if equip:isKindOf("SilverLion") and to:hasSkills("bazhen|yizhong") then
		self:updateIntention(from,to,40)
	else
		self:updateIntention(from,to,-40)
	end
end

sgs.ai_skill_invoke.huwei = function(self,data)
	local drowning = clone(self,"drowning")
	local dummy_use = dummy_plan()
	self:useTrickCard(drowning,dummy_use)
	return (dummy_use.card~=nil)
end

sgs.ai_skill_invoke.xiaoxi = function(self,data)
	local slash = clone(self,"slash")
	local dummy_use = dummy_plan()
	self:useBasicCard(slash,dummy_use)
	return (dummy_use.card~=nil)
end

sgs.ai_skill_invoke.manyi = function(self,data)
	local sa = clone(self,"savage_assault")
	local dummy_use = dummy_plan()
	self:useTrickCard(sa,dummy_use)
	return (dummy_use.card~=nil)
end

sgs.ai_fill_skill["mouzhu"] = function(self,inclusive,request)
	return policy(self,"@MouzhuCard=.")
end

sgs.ai_skill_use_func.MouzhuCard = function(card,use,self)
	local canleiji
	if self:findLeijiTarget(self.player,50)
		and ((self.player:hasSkill("leiji") and self:hasSuit("spade",true))
			or (self.player:hasSkill("nosleiji") and self:hasSuit("black",true))) then
		canleiji = true
		self.friends_noself = self:sort(self.friends_noself,"handcard")
		self.friends_noself = sgs.reverse(self.friends_noself)
		for _,friend in sgs.list(self.friends_noself)do
			if not friend:isKongcheng() and friend:getHandcardNum()<self.player:getHandcardNum()+2
				and (self:getCardsNum("Jink")>0 or (not friend:hasWeapon("QinggangSword") and not self:isWeak() and self:hasEightDiagramEffect())) then
				use.card = card
				use.to:append(friend)
				return
			end
		end
	end

	for _,enemy in sgs.list(self.enemies)do
		if enemy:getHandcardNum()>0 and  self:needToLoseHp(self.player,enemy,card) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end

	local first,second,third,fourth
	local slash = self:getCard("Slash")
	local slash_nosuit = clone(self,"slash")
	for _,enemy in sgs.list(self.enemies)do
		if enemy:getHandcardNum()>=self.player:getHandcardNum()+2 then
			first = enemy
			break
		elseif enemy:getHandcardNum()>0 then
			if not self:slashIsEffective(slash_nosuit,self.player,nil,enemy) and self:getCardsNum("Slash")>getCardsNum("Slash",enemy) and not second then
				second = enemy
			elseif not enemy:hasSkills("wushuang|mengjin|tieji|nostieji")
				and not ((enemy:hasSkill("roulin") or enemy:hasWeapon("DoubleSword")) and enemy:getGender()~=self.player:getGender()) then

				if enemy:getHandcardNum()==1 and slash and not third and self.player:inMyAttackRange(enemy)
				and (self:ajustDamage(self.player,enemy,1,slash)>1 or self.player:hasWeapon("GudingBlade") and not self:needKongcheng(enemy))
				and (not self:isWeak() or self:getCardsNum("Peach")+self:getCardsNum("Analeptic")>0)
				then
					third = enemy
				elseif self:getCardsNum("Jink")>0 and self:getCardsNum("Slash")>getCardsNum("Slash",enemy) and not fourth then
					fourth = enemy
				end
			end
		end
	end

	local target
	if canleiji then
		target = fourth and third or first or second
	else
		target = first or second or third or fourth
	end
	if target then
		use.card = card
		use.to:append(target)
		return
	end

end

sgs.ai_skill_cardask["@mouzhu-give"] = function(self,data)
	local target = self.room:getCurrent()
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	if self:isFriend(target) then
		if target:hasSkill("nosleiji") then
			local jink,spade
			for _,c in sgs.list(cards)do
				if isCard("Jink",c,target) then jink = c:getKnownEffectiveId() end
				if c:getSuit()==sgs.Card_Spade then spade = c:getKnownEffectiveId() end
			end
			if self:hasSuit("spade",true,target) and jink then return jink
			elseif not self:hasEightDiagramEffect(target) and jink then return jink
			elseif spade or jink then return spade or jink
			end
		elseif target:hasSkill("leiji") then
			local jink,black
			for _,c in sgs.list(cards)do
				if isCard("Jink",c,target) then jink = c:getKnownEffectiveId() end
				if c:isBlack() then black = c:getKnownEffectiveId() end
			end
			if self:hasSuit("black",true,target) and jink then return jink
			elseif not self:hasEightDiagramEffect(target) and jink then return jink
			elseif black or jink then return black or jink
			end
		end
	else
		if target:hasSkill("nosleiji") then
			for _,c in sgs.list(cards)do
				if not c:isKindOf("Peach") and not c:isKindOf("Jink") and c:getSuit()~=sgs.Card_Spade then
					return c:getKnownEffectiveId()
				end
			end
		elseif target:hasSkill("leiji") then
			for _,c in sgs.list(cards)do
				if not c:isKindOf("Peach") and not c:isKindOf("Jink") and not c:isBlack() then
					return c:getKnownEffectiveId()
				end
			end
		end
		for _,c in sgs.list(cards)do
			if not c:isKindOf("Peach") then return c:getKnownEffectiveId() end
		end
	end

	return cards[1]:getKnownEffectiveId()
end

sgs.ai_skill_choice.mouzhu = function(self,choices)
	local target = self.room:getCurrent()
	local slash = clone(self,"slash")
	if target:hasSkills("leiji|nosleiji") then
		if self:isFriend(target) then
			if choices:match("slash") then return "slash" end
		else
			if choices:match("duel") then return "duel" end
		end
	end

	if self:isFriend(target) then
		if (target:hasSkills("leiji|nosleiji") or not self:slashIsEffective(slash,target)) and choices:match("slash") then return "slash" end
		if self:needToLoseHp(self.player,target) and getCardsNum("Slash",target,self.player)>=1 and choices:match("duel") then return "duel" end
	else
		if target:hasSkills("leiji|nosleiji") and choices:match("duel") then return "duel" end
		if self:getCardsNum("Slash")>getCardsNum("Slash",target,self.player) and choices:match("duel") then return "duel" end
	end

	if choices:match("slash") then return "slash" else return "duel" end
	return "slash"
end

sgs.ai_use_priority.MouzhuCard = 5.5

sgs.ai_card_intention.MouzhuCard = function(self,card,from,tos)
	if not self.player:hasSkills("leiji|nosleiji") then self:updateIntention(from,tos[1],30) end
end

sgs.ai_skill_invoke.yanhuo = function(self,data)
	local opponent = self.room:getOtherPlayers(self.player,true):first()
	return opponent:isAlive() and self:doDisCard(opponent,"he")
end

sgs.ai_skill_playerchosen.yanhuo = function(self,targets)
	local target = self:findPlayerToDiscard(nil,nil,true,targets)[1]
	if target and target:objectName()~=self.player:objectName() then return target end
end

sgs.ai_skill_invoke.kofkuanggu = function(self,data)
	local zhangbao = self.room:findPlayerBySkillName("yingbing")
	if zhangbao and self:isEnemy(zhangbao)
		and self.player:getPile("incantation"):length()>0 and visible(self,self.player:getPile("incantation"):first()):isRed()
		and not self:hasWizard(self.friends) then return false end
	if self.player:isWounded() then return true end
	local zhangjiao = self.room:findPlayerBySkillName("guidao")
	return zhangjiao and self:isFriend(zhangjiao) and not zhangjiao:isNude()
end

sgs.ai_skill_defense.kofkuanggu = function(self, player)
	if player:getHp()>1 then
		return 1
	end
	return 0
end

sgs.ai_fill_skill["puji"] = function(self,inclusive,request)

	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards,true)
	if self:needToThrowArmor() then return policy(self,"@PujiCard="..self.player:getArmor():getEffectiveId()) end
	for _,card in sgs.list(cards)do
		if not self:isValuableCard(card) then
			if card:getSuit()==sgs.Card_Spade then return policy(self,"@PujiCard="..card:getKnownEffectiveId()) end
		end
	end
	for _,card in sgs.list(cards)do
		if not self:isValuableCard(card) and not (self.player:hasSkill("jijiu") and card:isRed() and self:getOverflow()<2) then
			if card:getSuit()==sgs.Card_Spade then return policy(self,"@PujiCard="..card:getKnownEffectiveId()) end
		end
	end
end

sgs.ai_skill_use_func.PujiCard = function(card,use,self)
	self:setStrategyMemory("special1v1.puji_id_choice",false)
	local players = self:findPlayerToDiscard("he",false,true)
	for _,p in sgs.list(players)do
		local recommendation=self:recommendCardChosen(p,"he","dummyreason",sgs.Card_MethodDiscard)
		local id=recommendation.id
		local chosen_card
		if id then chosen_card = visible(self,id) end
		if recommendation.zone~="none" and (self:isFriend(p) or recommendation.zone~="e" or visible(self,id):getSuit()~=sgs.Card_Spade) then
			self:setStrategyMemory("special1v1.puji_id_choice",{id=id,zone=recommendation.zone})
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.PujiCard = 5
sgs.ai_use_priority.PujiCard = 4.6

sgs.ai_card_intention.PujiCard = function(self,card,from,tos)
 local cached,present=self:getStrategyMemory('special1v1.puji_id_choice');if not present or not cached then return end
 local player=nil
	local to=self.room:findPlayerByObjectName(tos[1]:objectName())
	if to then
		local intention = 70
		if hasTuntianEffect(to, true) and to:getPile("field")==2 and to:getStrategyMark("zaoxian")<1
		then intention = 0 end
		local id=known(cached.id,'Puji cached hidden identity is not disclosed');local card=visible(self,id)
		local place = known(self.room:getCardPlace(id),"Puji current card place")
		if place==sgs.Player_PlaceDelayedTrick then
			if not card:isKindOf("Disaster") or card:isKindOf("YanxiaoCard")
			then intention = -intention else intention = 0 end
		elseif place==sgs.Player_PlaceEquip then
			if card:isKindOf("Armor") and self:evaluateArmor(card,to)<=-2
			then intention = 0
			elseif card:isKindOf("SilverLion") then
				if to:getLostHp()>1 then
					if to:hasSkills(sgs.use_lion_skill)
					then intention = self:willSkipPlayPhase(to) and -intention or 0
					else intention = self:isWeak(to) and -intention or 0 end
				else intention = 0 end
			elseif to:hasSkills(sgs.lose_equip_skill) then
				if self:isWeak(to) and (card:isKindOf("DefensiveHorse") or card:isKindOf("Armor"))
				then intention = math.abs(intention) else intention = 0 end
			end
			if false and self:isFriend(to,player)
			and (card:isKindOf("OffensiveHorse") or card:isKindOf("Weapon")) then
				local canAttack
				for _,p in sgs.list(self.room:getOtherPlayers(player))do
					if player:inMyAttackRange(p) and self:isEnemy(p,player)
					then canAttack = true break end
				end
				if not canAttack then intention = 0 end
			end
		elseif place==sgs.Player_PlaceHand then
			if self:needKongcheng(to,true) and to:getHandcardNum()==1
			then intention = 0 end
		end
		-- Source updateIntention(nil,to,intention) returns before RNG or mutation.
	end
end

sgs.ai_skill_defense.wanrong = function(self, player)
	if not hasManjuanEffect(player) then
		return 0.5
	end
	return 0
end

sgs.ai_skill_use["@@niluan"] = function(self,prompt)
	return sgs.ai_skill_use.slash(self,prompt)
end

sgs.ai_skill_cardask["@niluan-slash"] = function(self,data,pattern,target,target2)
	if target and self:isFriend(target) and not self:findLeijiTarget(target,50,self.player) then
		return "."
	end
	if not self.player:canSlash(target,false) then return "." end

	local black_card
	if not target:hasSkill("yizhong") and not target:hasArmorEffect("renwang_shield") and not target:hasArmorEffect("Vine") then
		local cards = sgs.QList2Table(self.player:getHandcards())
		cards = self:sortByKeepValue(cards)
		local slash = clone(self,"slash")
		for _,card in sgs.list(cards)do
			if card:isBlack() and self:getKeepValue(card,cards)<=self:getKeepValue(slash,cards) then
				local black_slash = clone(self,"slash",sgs.Card_SuitToBeDecided,-1)
				black_slash = mutate(self,black_slash,"add",card)
				if self:slashIsEffective(black_slash,target) then
					black_card = card
					break
				end
			end
		end
		if not black_card then
			local offensive_horse = self.player:getOffensiveHorse()
			if offensive_horse and offensive_horse:isBlack() then
				local black_slash = clone(self,"slash",sgs.Card_SuitToBeDecided,-1)
				black_slash = mutate(self,black_slash,"add",offensive_horse)
				if self:slashIsEffective(black_slash,target) then
					black_card = offensive_horse
				end
			end
		end
	end
	if self:needToThrowArmor() and self.player:getArmor():isBlack() then black_card = self.player:getArmor()
	elseif self:needKongcheng(self.player,true) and self.player:getHandcardNum()==1 and self.player:getHandcards():first():isBlack() then
		black_card = self.player:getHandcards():first()
	end
	if black_card then
		local black_slash = clone(self,"slash",sgs.Card_SuitToBeDecided,-1)
		black_slash = mutate(self,black_slash,"skill","niluan")
		black_slash = mutate(self,black_slash,"add",black_card)
		return black_slash:getLegacyStringKey()
	end
	return "."
end

sgs.ai_skill_invoke.renwang = function(self,data)
	local use = data:toCardUse()
	if self:isFriend(use.from) then
		local id = self:recommendCardChosen(use.from,"he","dummy",sgs.Card_MethodDiscard).id
		return self:needToThrowArmor(use.from) and id==use.from:getArmor():getEffectiveId()
	elseif self:doDisCard(use.from,"he") then
		return true
	end
	return
end

local function wrap(f,key,kind)
 return function(...)
  local a=table.pack(...);local self
  for i=1,a.n do if type(a[i])=='table' and a[i].player and a[i].world and a[i].request then self=a[i];break end end
  if not self then return f(...)end
  local prior,request=self._special1v1_key,self._special1v1_request;self._special1v1_key=key
  if kind=='ai_fill_skill'then self._special1v1_request=a[3]end
  local r=table.pack(pcall(f,table.unpack(a,1,a.n)));self._special1v1_key=prior;self._special1v1_request=request
  if not r[1]then error(r[2],0)end
  if kind=='ai_skill_use'then r[2]=response(self,r[2])
  elseif kind=='ai_skill_cardask' and type(a[2])~='number'then r[2]=selected_response(self,r[2])end
  return table.unpack(r,2,r.n)
 end
end
sgs.ai_card_intention['Drowning']=wrap(sgs.ai_card_intention['Drowning'],'Drowning','ai_card_intention')
sgs.ai_skill_choice['drowning']=wrap(sgs.ai_skill_choice['drowning'],'drowning','ai_skill_choice')
sgs.ai_skill_playerchosen['koftuxi']=wrap(sgs.ai_skill_playerchosen['koftuxi'],'koftuxi','ai_skill_playerchosen')
sgs.ai_playerchosen_intention['koftuxi']=wrap(sgs.ai_playerchosen_intention['koftuxi'],'koftuxi','ai_playerchosen_intention')
sgs.ai_nullification['Drowning']=wrap(sgs.ai_nullification['Drowning'],'Drowning','ai_nullification')
sgs.ai_fill_skill['xiechan']=wrap(sgs.ai_fill_skill['xiechan'],'xiechan','ai_fill_skill')
sgs.ai_skill_use_func['XiechanCard']=wrap(sgs.ai_skill_use_func['XiechanCard'],'XiechanCard','ai_skill_use_func')
do local f=sgs.ai_view_as['kofqingguo'];sgs.ai_view_as['kofqingguo']=function(...)return proposal(f(...))end end
sgs.ai_cardneed['kofqingguo']=wrap(sgs.ai_cardneed['kofqingguo'],'kofqingguo','ai_cardneed')
sgs.ai_cardneed['kofliegong']=wrap(sgs.ai_cardneed['kofliegong'],'kofliegong','ai_cardneed')
sgs.ai_skill_askforag['yinli']=wrap(sgs.ai_skill_askforag['yinli'],'yinli','ai_skill_askforag')
sgs.ai_skill_choice['kofxiaoji']=wrap(sgs.ai_skill_choice['kofxiaoji'],'kofxiaoji','ai_skill_choice')
sgs.ai_skill_use['@@cangji']=wrap(sgs.ai_skill_use['@@cangji'],'@@cangji','ai_skill_use')
sgs.ai_card_intention['CangjiCard']=wrap(sgs.ai_card_intention['CangjiCard'],'CangjiCard','ai_card_intention')
sgs.ai_skill_invoke['huwei']=wrap(sgs.ai_skill_invoke['huwei'],'huwei','ai_skill_invoke')
sgs.ai_skill_invoke['xiaoxi']=wrap(sgs.ai_skill_invoke['xiaoxi'],'xiaoxi','ai_skill_invoke')
sgs.ai_skill_invoke['manyi']=wrap(sgs.ai_skill_invoke['manyi'],'manyi','ai_skill_invoke')
sgs.ai_fill_skill['mouzhu']=wrap(sgs.ai_fill_skill['mouzhu'],'mouzhu','ai_fill_skill')
sgs.ai_skill_use_func['MouzhuCard']=wrap(sgs.ai_skill_use_func['MouzhuCard'],'MouzhuCard','ai_skill_use_func')
sgs.ai_skill_cardask['@mouzhu-give']=wrap(sgs.ai_skill_cardask['@mouzhu-give'],'@mouzhu-give','ai_skill_cardask')
sgs.ai_skill_choice['mouzhu']=wrap(sgs.ai_skill_choice['mouzhu'],'mouzhu','ai_skill_choice')
sgs.ai_card_intention['MouzhuCard']=wrap(sgs.ai_card_intention['MouzhuCard'],'MouzhuCard','ai_card_intention')
sgs.ai_skill_invoke['yanhuo']=wrap(sgs.ai_skill_invoke['yanhuo'],'yanhuo','ai_skill_invoke')
sgs.ai_skill_playerchosen['yanhuo']=wrap(sgs.ai_skill_playerchosen['yanhuo'],'yanhuo','ai_skill_playerchosen')
sgs.ai_skill_invoke['kofkuanggu']=wrap(sgs.ai_skill_invoke['kofkuanggu'],'kofkuanggu','ai_skill_invoke')
sgs.ai_skill_defense['kofkuanggu']=wrap(sgs.ai_skill_defense['kofkuanggu'],'kofkuanggu','ai_skill_defense')
sgs.ai_fill_skill['puji']=wrap(sgs.ai_fill_skill['puji'],'puji','ai_fill_skill')
sgs.ai_skill_use_func['PujiCard']=wrap(sgs.ai_skill_use_func['PujiCard'],'PujiCard','ai_skill_use_func')
sgs.ai_card_intention['PujiCard']=wrap(sgs.ai_card_intention['PujiCard'],'PujiCard','ai_card_intention')
sgs.ai_skill_defense['wanrong']=wrap(sgs.ai_skill_defense['wanrong'],'wanrong','ai_skill_defense')
sgs.ai_skill_use['@@niluan']=wrap(sgs.ai_skill_use['@@niluan'],'@@niluan','ai_skill_use')
sgs.ai_skill_cardask['@niluan-slash']=wrap(sgs.ai_skill_cardask['@niluan-slash'],'@niluan-slash','ai_skill_cardask')
sgs.ai_skill_invoke['renwang']=wrap(sgs.ai_skill_invoke['renwang'],'renwang','ai_skill_invoke')
