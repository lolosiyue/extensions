-- Fixed YCZH2016 source policies. Native receipts alone authorize card costs.
sgs.ai_choicemade_filter.skillInvoke=sgs.ai_choicemade_filter.skillInvoke or {}
sgs.ai_choicemade_filter.cardChosen=sgs.ai_choicemade_filter.cardChosen or {}
local known = AIValue.requireKnown
local function skill(self,player,names)
    local value=player:hasSkills(names)
    local row=rawget(player,"_view")
    if value==true or value~=nil and (not row or row.skills_complete==true) then return value end
    if player:objectName()==self.player:objectName() then ai_unsupported("owner skills are incomplete","yczh2016.skills") end
    return self:useKnowledgeEstimate({status="estimate",value=false,basis="yczh2016.undisclosed_skills_use_visible_roster",target=player:objectName()},"yczh2016.skills")
end
local function flag(self,player,name)
    local value=player:getStrategyFlag(name)
    if value~=nil then return value end
    return self:useKnowledgeEstimate({status="estimate",value=false,basis="yczh2016.unknown_foreign_flag_uses_public_state",target=player:objectName(),flag=name},"yczh2016.flag")
end
local function reversed(cards)
    local result={};for i=#cards,1,-1 do result[#result+1]=cards[i]end;return AIList.new(result)
end
local function current_damage(self)
    -- The room's CurrentDamageStruct reaches the VM only as the ask's context damage.
    local options=self.request.options
    local raw=known(type(options)=="table" and type(options.context)=="table" and options.context.damage or nil,"yczh2016.current_damage")
    local result={};for k,v in pairs(raw)do result[k]=v end
    for _,key in ipairs({"from","to"}) do
        local name=result[key];result[key]=name and name~="" and self.room:findPlayerByObjectName(name,true) or nil
    end
    result.damage=result.amount
    if result.card then result.card=CardView.new(result.card)end
    return result
end
local function material(self,id)
    local card=self:getKnownCardById(id) or self:getChoiceCard(id)
    local rows=self:getDecisionContext().huisheng_cards
    if not card and rows and rows[tostring(id)]then card=CardView.new(rows[tostring(id)])end
    return known(card,"yczh2016.disclosed_material")
end
local function own_pile(self,name)
    local result={};for _,id in ipairs(known(self.player:getPile(name),"yczh2016.owner_pile"))do result[#result+1]=material(self,id)end
    return AIList.new(result)
end
local function policy_card(self,skill_name,class,costs,request,user_string)
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room)end
    local authority=self:bindSkillCard(skill_name,costs,request,user_string)
    local suit,number=sgs.Card_NoSuit,0
    if #costs==1 then local c=material(self,costs[1]);suit,number=c:getSuit(),c:getNumber()
    elseif #costs>1 then
        local red,black=true,true
        for _,id in ipairs(costs)do local c=material(self,id);red=red and known(c:isRed(),"yczh2016.material_color");black=black and known(c:isBlack(),"yczh2016.material_color")end
        suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
    end
    local suits={[sgs.Card_Spade]="spade",[sgs.Card_Club]="club",[sgs.Card_Heart]="heart",[sgs.Card_Diamond]="diamond",[sgs.Card_NoSuitBlack]="no_suit_black",[sgs.Card_NoSuitRed]="no_suit_red",[sgs.Card_NoSuit]="no_suit"}
    local rank=number>13 and "JOKER" or ({[1]="A",[11]="J",[12]="Q",[13]="K"})[number] or tostring(number)
    local key="@"..class.."["..known(suits[suit],"yczh2016.policy_suit")..":"..rank.."]="..(#costs>0 and table.concat(costs,"+")or".")
    if user_string then key=key..":"..user_string end
    local keeps=class=="JiaozhaoCard" or class=="HuishengCard" or class=="TaoluanCard" or class=="TenyearTaoluanCard"
    local policy={name="",class_name=class,type_id=0,kind_of={class,"SkillCard","Card"},suit=suit,number=number,
        subcards=costs,red=suit==sgs.Card_Heart or suit==sgs.Card_Diamond or suit==sgs.Card_NoSuitRed,
        black=suit==sgs.Card_Spade or suit==sgs.Card_Club or suit==sgs.Card_NoSuitBlack,
        damage_card=false,can_recast=false,handling_method=(class=="TaoluanCard" or class=="TenyearTaoluanCard") and sgs.Card_MethodUse or keeps and sgs.Card_MethodNone or sgs.Card_MethodDiscard,
        will_throw=not keeps,legacy_string_key=key,legacy_sort_key=key}
    if #costs>0 then policy.effective_id=costs[1]end
    return self:legacyPolicyCard(authority,policy)
end
local function action(self,skill_name,costs,targets,request,user_string)
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room)end
    local use=AIUsePlan.new();use.card=self:bindSkillCard(skill_name,costs,request,user_string);use.to=AIList.new(targets or{})
    return known(use:toAnswer(),"yczh2016.action")
end

local function remove_one(list,value)
 for i,item in ipairs(list)do if item==value then table.remove(list,i);return true end end
 return false
end
local dummy = AIUsePlan.dummy
local classes={JiaozhaoCard="jiaozhao",JiyuCard="jiyu",DuliangCard="duliang",QinqingCard="qinqing",HuishengCard="huisheng",KuangbiCard="kuangbi",JisheDrawCard="jishe",JisheCard="jishe",ZhigeCard="zhige",TaoluanCard="taoluan",TenyearTaoluanCard="tenyeartaoluan"}
local function parse_source_costs(text)
 local costs={};if text~="." then for id in text:gmatch("[^+]+")do costs[#costs+1]=known(tonumber(id),"yczh2016.authored_cost")end end;return costs
end
local function source_card(self,text,request)
 local class,ids,user=text:match("^@(%w+)=([^:]+):?(.*)$")
 return policy_card(self,known(classes[class],"yczh2016.authored_class"),class,parse_source_costs(known(ids,"yczh2016.authored_costs")),request,user~="" and user or nil)
end
local function source_action(self,text,request)
 if text=="." or text==nil then return text end
 local class,ids,names=text:match("^@(%w+)=(.-)%->(.*)$")
 if not class then class,ids=text:match("^@(%w+)=(.+)$")end
 local targets={};for name in (names or ""):gmatch("[^+]+")do targets[#targets+1]=known(self.room:findPlayerByObjectName(name),"yczh2016.authored_target")end
 return action(self,known(classes[class],"yczh2016.authored_class"),parse_source_costs(known(ids,"yczh2016.authored_costs")),targets,request)
end
local function disclosed_hand(self,player)
 return known(self:getKnownCards(player,self.player,"h"),"yczh2016.visible_hand")
end
local function remembered_player(self,key)
 local name=self:getStrategyMemory("yczh2016."..key)
 return name and self.room:findPlayerByObjectName(name) or nil
end


local function level(self,player)
 -- jiaozhaoSetLevel mirrors the jiaozhao_level property into this public mark.
 return known(player:getMark("&jiaozhao_level"),"jiaozhao.public_level")
end
local function printed(self,id)
 local own=self:getPrintedCardById(id)
 if own then return own end
 local ctx=self:getDecisionContext();local row=ctx.yczh2016_printed_cards and ctx.yczh2016_printed_cards[tostring(id)]
 return CardView.new(known(row,"yczh2016.authorized_printed_card"))
end
local function consume_hint(self,key)
 -- Hints staged by another viewer's AI are not projected.
 ai_unsupported("cross-viewer AI hints are not projected","yczh2016.hint_reader")
end
local function stage_hint(self,key,target,use)
 if use and use.isDummy then return end -- speculative donor tag writes do not cross viewer boundaries
 local effect={kind="ai_player_hint",source=self.player:objectName(),player=target:objectName(),name=key}
 if rawget(self,"_event_effect_sink") then return self:emitStrategyEffect(effect)end
 self._strategy_effects=self._strategy_effects or {};assert(#self._strategy_effects<64,"too many player hints")
 effect.after_delta=0;self._strategy_effects[#self._strategy_effects+1]=effect
end
local function limited(self,target,card)
 local value=target:isCardLimited(card,sgs.Card_MethodUse)
 if value~=nil then return value end
 if target:objectName()==self.player:objectName()then ai_unsupported("owner limitation is unknown","yczh2016.owner_limit")end
 return self:useKnowledgeEstimate({status="estimate",value=false,basis="yczh2016.foreign_limit_uses_public_unrestricted_prior",target=target:objectName()},"yczh2016.foreign_limit")
end
local function damage(self)
 return known(self:getDecisionContext().damage,"huisheng.damage")
end
local function general(self,player)
 local catalog=self:getDecisionContext().general_catalog
 local row=known(catalog and catalog[player:getGeneralName()],"cenhun.public_lord_general")
 if row.exists==false then return nil end
 return {getSkillDescription=function()return known(row.skill_description,"cenhun.public_lord_description")end}
end


local function mark(self,player,name)
 local value=player:getStrategyMark(name)
 if value~=nil then return value end
 if player:objectName()==self.player:objectName()then ai_unsupported("owner mark is unavailable","yczh2016.owner_mark")end
 return self:useKnowledgeEstimate({status="estimate",value=0,basis="yczh2016.foreign_mark_uses_public_absence",target=player:objectName(),mark=name},"yczh2016.foreign_mark")
end
local function originally_visible(self,player,card)
 local a=card:hasFlag("visible");local b=card:hasFlag("visible_"..self.player:objectName().."_"..player:objectName())
 if a==true or b==true then return true end
 if a~=nil and b~=nil then return false end
 if player:objectName()==self.player:objectName()then ai_unsupported("owner visibility flags are not projected","jiyu.owner_visibility")end
 return self:useKnowledgeEstimate({status="estimate",value=true,basis="jiyu.disclosed_hand_original_visibility_flags_unknown",target=player:objectName()},"jiyu.visibility")
end
local function declared_card(self,skill_name,name,costs,request)
 local evaluation=self:evaluateSkillCard(skill_name,name,costs)
 local receipt=self:bindSkillCard(skill_name,costs,request,name)
 local policy={}
 for _,key in ipairs({"name","class_name","type_id","kind_of","suit","number","damage_card","can_recast","handling_method","red","black"})do policy[key]=rawget(evaluation,"_view")[key]end
 policy.subcards=costs;policy.effective_id=costs[1];policy.skill_name=skill_name;policy.skill_names={skill_name}
 return self:legacyPolicyCard(receipt,policy,evaluation)
end
local function jiaozhao_evaluation(self,source,id,showid)
 local template=printed(self,id)
 if source:objectName()==self.player:objectName()then return self:evaluateSkillCard("jiaozhao",template:objectName(),{showid})end
 -- Only a new policy descriptor made from already disclosed faces, never a
 -- foreign native rule query or conversion ticket.
 local cost=material(self,showid);local row={}
 for k,v in pairs(rawget(template,"_view"))do row[k]=v end
 row.id=-1;row.effective_id=showid;row.virtual_card=true;row.subcards={showid};row.suit=cost:getSuit();row.number=cost:getNumber()
 row.red=cost:isRed();row.black=cost:isBlack();row.skill_name="jiaozhao";row.skill_names={"jiaozhao"};row.skill_names_complete=true
 local rank=row.number>13 and "JOKER"or({[1]="A",[11]="J",[12]="Q",[13]="K"})[row.number]or tostring(row.number)
 row.legacy_string_key=row.name..":jiaozhao["..known(cost:getSuitString(),"jiaozhao.material_suit")..":"..rank.."]="..showid
 row.legacy_sort_key=row.legacy_string_key
 row.using=false;row.flags={};row.flags_complete=true;row.known_flags={};row.evaluation_only=true
 return CardView.new(row)
end
local function jiaozhao_can_use(self,source,card)
 if source:objectName()==self.player:objectName()then return known(source:canUse(card),"jiaozhao.owner_can_use")end
 local value=not limited(self,source,card)
 -- The public Jiaozhao prohibition excludes its holder as a target. Other
 -- hidden callback inputs remain a named unrestricted-public-target prior.
 if card:isKindOf("Peach")then value=false end
 return self:useKnowledgeEstimate({status="estimate",value=value,basis="jiaozhao.foreign_can_use_public_target_prior",target=source:objectName()},"jiaozhao.foreign_can_use")
end
local function remember_targets(self,key,use)
 local names={};for _,player in ipairs(use.to or{})do names[#names+1]=player:objectName()end
 self:setStrategyMemory("yczh2016."..key,names)
end
local function restore_targets(self,key)
 local targets=AIList.new({})
 for _,name in ipairs(known(self:getStrategyMemory("yczh2016."..key),"yczh2016.prior_plan"))do targets:append(known(self.room:findPlayerByObjectName(name),"yczh2016.planned_target"))end
 return targets
end

--矫诏
ai_fill_skill.jiaozhao = function(self, options, request)
    local inclusive = options and options.inclusive

	local id = self.player:getMark("jiaozhao_id-Clear")-1
	if not self.player:isKongcheng()
	and id<0
	then
		self:setStrategyMemory("yczh2016.jiaozhao_target",nil)
		local level = level(self,self.player)
		if level>1 then
			self:setStrategyMemory("yczh2016.jiaozhao_target",self.player:objectName())
			return self:legacySkillSeed("jiaozhao","JiaozhaoCard",request)
		else
			local distance = self.player:distanceTo(self.player:getNextAlive())
			for _,p in ipairs(self.room:getOtherPlayers(self.player))do
				if self.player:distanceTo(p)<distance then
					distance = self.player:distanceTo(p)
				end
			end
			for _,p in ipairs(self.friends_noself)do
				if self.player:distanceTo(p)==distance
				then
					self:setStrategyMemory("yczh2016.jiaozhao_target",p:objectName())
					return self:legacySkillSeed("jiaozhao","JiaozhaoCard",request)
				end
			end
		end
	end
	
	local showid = self.player:getMark("jiaozhao_showid-Clear")-1
	if id>=0 and showid>=0
	and (self.player:hasCard(showid) or self.player:getHandPile():contains(showid))
	then
		local name = printed(self,id):objectName()
        local use_card = self:getEvaluationCard(name)
        if use_card then
            use_card=self:evaluateSkillCard("jiaozhao",name,{showid})
			if self.player:canUse(use_card)
			then
				return declared_card(self,"jiaozhao",name,{showid},request)
			end
		end
	end
end

ai_card_use.JiaozhaoCard = function(self, card, use, request)
	local cards = AIList.new(self.player:getCards("h"))
	cards = self:sortByUseValue(cards,true)
	use.card = source_card(self,"@JiaozhaoCard="..cards[1]:getEffectiveId(),request)
end

sgs.ai_view_as.jiaozhao = function(card,player,card_place)
 local self=known(rawget(player,"_room") and rawget(player,"_room")._ai,"jiaozhao.viewer")
	local id = mark(self,player,"jiaozhao_id-Clear")-1
	local showid = mark(self,player,"jiaozhao_showid-Clear")-1
	if id>=0 and showid>=0 and card:getEffectiveId()==showid
	then
		local c = printed(self,id)
		local cost=material(self,showid);return {name=c:objectName(),skill="jiaozhao",suit=cost:getSuit(),number=cost:getNumber(),subcards={showid}}
	end
end

sgs.ai_skill_askforag.jiaozhao = function(self,ids)
	local source = consume_hint(self,"jiaozhaoAI")
	
	if not source then return ids[1] end
	
	local card_ids = {}
	for _,id in ipairs(ids)do
		if (source:getState()=="robot" or source:getState()=="trust")
		and printed(self,id):canRecast()
		then continue end --ai会重铸铁索，故而移去
		table.insert(card_ids,id)
	end
	if #card_ids<1 then return ids[1] end
	
	local showid = mark(self,source,"jiaozhao_showid-Clear")-1
	if showid<0 then return card_ids[1] end
	
	local can_use,not_use = {},{}
	for _,id in ipairs(card_ids)do
		local card = jiaozhao_evaluation(self,source,id,showid)
		if jiaozhao_can_use(self,source,card) then table.insert(can_use,card)
		else table.insert(not_use,id) end
	end
	if self:isEnemy(source) then
		return not_use[1]
	end
	if #can_use==0 then return card_ids[1] end
	can_use = self:sortByUseValue(can_use)
	return can_use[1]:getEffectiveId()
end

sgs.ai_skill_playerchosen.jiaozhao = function(self,targets)
	
	local remembered=remembered_player(self,"jiaozhao_target")
	if remembered then
		stage_hint(self,"jiaozhaoAI",remembered)
		return remembered
	end
	for _,p in ipairs(targets)do
		if self:isFriend(p) then
			stage_hint(self,"jiaozhaoAI",p)
			return p
		end
	end
	stage_hint(self,"jiaozhaoAI",targets:first())
	return targets:first()
end

sgs.ai_use_priority.JiaozhaoCard = 10

--殚心
ai_skill_invoke.danxin = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local level = level(self,self.player)
	if level>1 then
		if not self:canDraw(self.player) then return (false) or false end
	end
	return (true) or false
end

ai_skill_choice.danxin = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	if not skill(self,self.player,"jiaozhao") then return ai_choice_result(("draw"), options) end
	local items = choices:split("+")
	if self:isWeak() and self.player:getHp()<2 and not self:canDraw(self.player) then return ai_choice_result(("up"), options) end
	if self:isWeak() and self.player:getHp()<2 then return ai_choice_result(("draw"), options) end
	if table.contains(items,"up") then return ai_choice_result(("up"), options) end
	return ai_choice_result(("draw"), options)
end

sgs.ai_need_damaged.danxin = function(self,attacker,player)
	if not skill(self,player,"danxin") or not skill(self,player,"jiaozhao") then return false end
	if self:isWeak() then return false end
	return level(self,player)<=1
end

--瑰藻
ai_skill_invoke.guizao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getLostHp()<=0 and not self:canDraw(self.player) then return (false) or false end
	return (true) or false
end

ai_skill_choice.guizao = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local items = choices:split("+")
	if table.contains(items,"recover") and self.player:getLostHp()>0 and self:isWeak() then 
		return ai_choice_result(("recover"), options)
	end
	if table.contains(items,"draw") and self:needBear() then 
		return ai_choice_result(("draw"), options)
	end
	if table.contains(items,"recover") and self.player:getLostHp()>0 then 
		return ai_choice_result(("recover"), options)
	end
	return ai_choice_result(("draw"), options)
end

--讥谀
ai_fill_skill.jiyu = function(self, options, request)
    local inclusive = options and options.inclusive

	for _,card in ipairs(self.player:getHandcards())do
		if card:isAvailable(self.player) then
			return self:legacySkillSeed("jiyu","JiyuCard",request)
		end
	end
end

ai_card_use.JiyuCard = function(self, card, use, request)
	self:sortInPlace(self.friends, "handcard")
	self.friends = reversed(self.friends)
	self:sortInPlace(self.enemies, "handcard")
	if self.player:isKongcheng() then return end
	
	
	
	for _,enemy in ipairs(self.enemies)do
		if mark(self,enemy,"jiyu-PlayClear")==0 and not enemy:isKongcheng() and not self:needToThrowCard(enemy,"h") 
		and not (self:needKongcheng(enemy) and enemy:getHandcardNum()==1)
		and not (self:needToLoseHp(enemy,self.player) and not (self:isWeak(enemy) or enemy:getHp()==1))
		then
			use.card = source_card(self,"@JiyuCard=.",request)
			use.to:append(enemy) stage_hint(self,"jiyuAI",enemy,use) 
			return	
		end	
	end
	
	for _,friend in ipairs(self.friends)do
		if friend:isKongcheng() then continue end
		if mark(self,friend,"jiyu-PlayClear")==0 then
			local handcards = disclosed_hand(self,friend)
			local hasspade = false
			local hasother = false
			for _,c in ipairs(handcards)do
				local flag = string.format("%s_%s_%s","visible",self.player:objectName(),friend:objectName())
				if originally_visible(self,friend,c) then
					if c:getSuit()==sgs.Card_Spade then
						hasspade = true
					else
						hasother = true
					end
					if hasspade and hasother then break end
				end
			end
			if not self.player:faceUp() and hasspade and self:needToLoseHp(friend) then
				
			elseif hasother then
				if (self:needKongcheng(friend) and friend:getHandcardNum()==1) or self:needToThrowCard(friend,"h") then
					
				else
					continue 
				end
			else
				continue 
			end
			use.card = source_card(self,"@JiyuCard=.",request)
			use.to:append(friend) stage_hint(self,"jiyuAI",friend,use)
			return	
		end
	end

	if self.player:getHp()>=2 and not self.player:faceUp() and self.player:getMark("jiyu-PlayClear")==0 then
		local handcards = AIList.new(self.player:getHandcards())
		local hasspade = false
		for _,c in ipairs(handcards)do
			if c:getSuit()==sgs.Card_Spade then
				hasspade = true
				break
			end
		end
		if hasspade then 
			use.card = source_card(self,"@JiyuCard=.",request)
			use.to:append(self.player) stage_hint(self,"jiyuAI",self.player,use)
			return
		end
	end
end

sgs.ai_skill_discard.jiyu = function(self,discard_num,min_num,optional,include_equip)
	local cards = AIList.new(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	
	local target = consume_hint(self,"jiyuAI")
	
	if not target then return cards[1]:getEffectiveId() end
	
	if self:isFriend(target) then
		for _,card in ipairs(cards)do
			if not target:faceUp() and self.player:getHp()>1 then
				if card:getSuit()==sgs.Card_Spade then
					return card:getEffectiveId()
				end
			end
		end
		
		for _,card in ipairs(cards)do
			if limited(self,target,card) then
				return card:getEffectiveId()
			end
		end
	else
		for _,card in ipairs(cards)do
			if not target:faceUp() then
				if card:getSuit()==sgs.Card_Spade then continue end
				if limited(self,target,card) then continue end
				return card:getEffectiveId()
			else
				if limited(self,self.player,card) then continue end
				return card:getEffectiveId()
			end
		end
	end
	
	return cards[1]:getEffectiveId()
end

sgs.ai_use_value.JiyuCard = 1
sgs.ai_use_priority.JiyuCard = 2

sgs.ai_card_intention.jiyu = function(self,card,from,tos)
	if self:needToThrowCard(tos[1],"h",true) or not from:faceUp() then return end
	sgs.updateIntention(from,tos[1],50)
end

--督粮
ai_fill_skill.duliang = function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("duliang","DuliangCard",request)
end

ai_card_use.DuliangCard = function(self, card, use, request)
	local friends,enemies,others = {},{},{}
	for _,player in ipairs(self.room:getOtherPlayers(self.player))do		
		if not player:isKongcheng() and self:isFriend(player) then
			table.insert(friends,player)
		elseif self:isEnemy(player) and self:doDisCard(player,"h") then
			table.insert(enemies,player)
		elseif not player:isKongcheng() then
			table.insert(others,player)
		end
	end
	
	if #friends==0 and #enemies==0 and #others==0 then return end
	local target
	self:sortInPlace(friends, "handcard")
	friends = reversed(friends)
	
	for _,friend in ipairs(friends)do
		if self:needToThrowCard(friend,"h") or skill(self,friend,"tuxi") then
			target = friend
			break
		end
	end
	
	if not target then
		self:sortInPlace(enemies, "defense")
		for _,enemy in ipairs(enemies)do
			if self:hasManjuanEffect(enemy) then
				target = enemy
				break
			end
		end
	end
	
	if not target then
		for _,enemy in ipairs(enemies)do
			if skill(self,enemy,sgs.dont_kongcheng_skill) then
				target = enemy
				break
			end
		end
	end
	
	for _,enemy in ipairs(enemies)do
		if skill(self,enemy,sgs.notActive_cardneed_skill) or self:isWeak(enemy) then
			target = enemy
			break
		end
	end
	
	if not target then
		for _,enemy in ipairs(enemies)do
			target = enemy
			break
		end
	end
	
	if not target then
		for _,other in ipairs(others)do
			target = other
			break
		end
	end
	
	if not target then
		for _,friend in ipairs(friends)do
			target = friend
			break
		end
	end
	self:setStrategyMemory("yczh2016.duliang",nil)
	if not target then return end
	use.card = source_card(self,"@DuliangCard=.",request)
	use.to:append(target)
	self:setStrategyMemory("yczh2016.duliang",target:objectName())
end

ai_skill_choice.duliang = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local target = remembered_player(self,"duliang")
	if target and self:isFriend(target) then
		if self:hasManjuanEffect(target) or skill(self,target,"tuxi") or self:needKongcheng(target) then return ai_choice_result(("draw"), options) end
		if self:isWeak() or self:isWeak(target) then return ai_choice_result(("watch"), options) end
	end
	if target and not self:isFriend(target) then
		if self:hasManjuanEffect(target) or skill(self,target,"tuxi") or self:needKongcheng(target) then return ai_choice_result(("watch"), options) end
		if skill(self,target,sgs.notActive_cardneed_skill) then return ai_choice_result(("draw"), options) end
		if skill(self,target,"nostuxi|biluan|shuangxiong|nosfuhun|mobileshuangxiong") then return ai_choice_result(("draw"), options) end
		if self:isWeak(target) then return ai_choice_result(("draw"), options) end
	end
    return ai_choice_result(("draw"), options)
end

sgs.ai_use_priority.DuliangCard = 7

--寝情
local function policy___qinqing(self,prompt)
	local lord = self.room:getLord()
	if not lord then return "." end
	local targets = {}
	for _,target in ipairs(self.room:getAlivePlayers())do
		if not target:inMyAttackRange(lord) then continue end
		if self:isEnemy(target) then
			if self:hasManjuanEffect(target) then
				table.insert(targets,target:objectName())
			elseif target:hasEquip() and self:doDisCard(target,"e") and
				(self:getDangerousCard(target) or self:getValuableCard(target) or not skill(self,target,sgs.notActive_cardneed_skill)) then
				table.insert(targets,target:objectName())
			elseif target:getHandcardNum()>=lord:getHandcardNum() and self:doDisCard(target,"h") then
				table.insert(targets,target:objectName())
			end
		elseif self:isFriend(target) then
			if not self:hasManjuanEffect(target) then
				if self:needToThrowCard(target,"he",false,false,true) then
					table.insert(targets,target:objectName())
				elseif target:getHandcardNum()>lord:getHandcardNum() then
					table.insert(targets,target:objectName())
				elseif self:isWeak(target) and not skill(self,target,sgs.need_equip_skill) and
					((target:getWeapon() and self.player:canDiscard(target,target:getWeapon():getId())) or
					(target:getOffensiveHorse() and self.player:canDiscard(target,target:getOffensiveHorse():getId()))) then
					table.insert(targets,target:objectName())
				elseif target:isNude() or not self.player:canDiscard(target,"he") then
					table.insert(targets,target:objectName())
				end
			end
		else
			if target:getHandcardNum()>=lord:getHandcardNum() and not target:isNude() then
				table.insert(targets,target:objectName())
			end
		end
	end
	if #targets==0 then return "." end
	return "@QinqingCard=.->"..table.concat(targets,"+")
end

--贿生
local function policy___huisheng(self,prompt)
	local cards = AIList.new(self.player:getCards("he"))
	local to_discard = {}
	cards = self:sortByKeepValue(cards)
	
	local damage = damage(self)
	local from = damage.from
	if not from or from:isDead() then return "." end
	if from:isNude() then
		if not cards[1]:isKindOf("Peach") and (not cards[1]:isKindOf("ExNihilo") or self:isWeak()) then
			table.insert(to_discard,cards[1]:getEffectiveId())
			return to_discard
		end
	end
	local to = self.player
	local n = damage.damage
	local nature = damage.nature
	local isSlash = false
	if damage.card and damage.card:isKindOf("Slash") then 
		isSlash = true
	end
	if self:needToLoseHp(to,from,damage.card) or not self:damageIsEffective(to,nature,from) then return "." end
	if self:isFriend(from) then
		for _,card in ipairs(cards)do
			table.insert(to_discard,card:getEffectiveId())
		end
		return "@HuishengCard="..table.concat(to_discard,"+")
	else
		if n>1 or self:hasHeavyDamage(from,damage.card,to) or self:needToThrowCard(from) or self.player:getHp()<=1 then
			for _,card in ipairs(cards)do
				if #to_discard>from:getCardCount(true) then break end
				if not card:isKindOf("Peach") then
					table.insert(to_discard,card:getEffectiveId())
				end
			end
			return "@HuishengCard="..table.concat(to_discard,"+")
		else
			local m
			if self:isWeak() then
				m = math.min(from:getCardCount(true),2)
			else
				m = 1
			end
			for _,card in ipairs(cards)do
				if #to_discard>m then break end
				if not self:keepCard(card) then
					table.insert(to_discard,card:getEffectiveId())
				end
			end
			return "@HuishengCard="..table.concat(to_discard,"+")
		end
	end
	return "."
end

sgs.ai_skill_discard.huisheng = function(self,discard_num,min_num,optional,include_equip)
	local to_dis = {}
	local cards = {}
	local ids = AIList.new(known(self:getDecisionContext().huisheng_ag_ids,"huisheng.disclosed_ids"))
	for _,id in ipairs(ids)do
		table.insert(cards,material(self,id))
	end
	cards = self:sortByUseValue(cards)
	for _,card in ipairs(cards)do
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") or card:isKindOf("ExNihilo") then return {} end
	end
	local damage = damage(self)
	local n = ids:length()
	if not self:isEnemy(damage.to) then return {} end
	local hcards = self.player:getCards("he")
	hcards = AIList.new(hcards)
	hcards = self:sortByKeepValue(hcards)
	if n==1 then
		if self:needToThrowCard() then return self:askForDiscard("dummy",1,1,true,include_equip) end
		for _,card in ipairs(hcards)do
			if (not self:keepCard(card) and not self:isValuableCard(card)) or (damage.to:getHp()<=1 and not self:hasBuquEffect(damage.to)) then
				table.insert(to_dis,card:getEffectiveId())
				return to_dis
			end
		end
	end
	
	for _,card in ipairs(hcards)do
		for _,card in ipairs(to_dis)do
			if not self:keepCard(card) and #to_dis<min_num then
				table.insert(to_dis,card:getEffectiveId())
				return to_dis
			end
		end
	end
	return to_dis
end

--匡弼
ai_fill_skill.kuangbi = function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("kuangbi","KuangbiCard",request)
end

ai_card_use.KuangbiCard = function(self, card, use, request)
	local friends,enemies,others = {},{},{}
	for _,player in ipairs(self.room:getOtherPlayers(self.player))do		
		if not player:isNude() and self:isFriend(player) and not self:hasManjuanEffect(player) then
			table.insert(friends,player)
		elseif not player:isNude() and self:isEnemy(player) and not self:needToThrowCard(player) then
			table.insert(enemies,player)
		elseif not player:isNude() then
			table.insert(others,player)
		end
	end
	
	if #friends==0 and #enemies==0 and #others==0 then return end
	local target
	self:sortInPlace(friends, "handcard")
	friends = reversed(friends)
	
	for _,friend in ipairs(friends)do
		if self:needToThrowCard(friend) or (self:needKongcheng(friend) and not friend:isKongcheng()) then
			target = friend
			break
		end
	end
	
	if not target then
		self:sortInPlace(enemies, "handcard")
		for _,enemy in ipairs(enemies)do
			if self:hasManjuanEffect(enemy) then
				target = enemy
				break
			end
		end
	end
	
	if not target then
		for _,enemy in ipairs(enemies)do
			if skill(self,enemy,sgs.dont_kongcheng_skill) then
				target = enemy
				break
			end
		end
	end
	
	if not target then
		for _,enemy in ipairs(enemies)do
			if skill(self,enemy,sgs.notActive_cardneed_skill) or self:isWeak(enemy) then
				target = enemy
				break
			end
		end
	end
	
	if not target then
		for _,enemy in ipairs(enemies)do
			target = enemy
			break
		end
	end
	
	if not target then
		for _,friend in ipairs(friends)do
			if not self:isWeak(friend) then
				target = friend
				break
			end
		end
	end
	
	if not target then
		for _,other in ipairs(others)do
			target = other
			break
		end
	end
	
	if not target then return end
	use.card = source_card(self,"@KuangbiCard=.",request)
	use.to:append(target)
	
	stage_hint(self,"kuangbiAI",target,use)
end

sgs.ai_skill_discard.kuangbi = function(self,discard_num,min_num,optional,include_equip)
	local cards = AIList.new(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local source = consume_hint(self,"kuangbiAI")
	
	if not source then return self:askForDiscard("dummy",1,1,false,include_equip) end
	
	local to_discard = {}
	
	if self:needToThrowArmor() then
		table.insert(to_discard,self.player:getArmor():getEffectiveId())
	end
	if self:needKongcheng() and not self.player:isKongcheng() then
		for _,card in ipairs(cards)do
			if #to_discard>=discard_num then break end
			table.insert(to_discard,card:getId())
		end
	end
	
	if self:isFriend(source) or skill(self,self.player,sgs.lose_equip_skill) then
		for _,card in ipairs(self.player:getCards("e"))do
			local equip_index = known(card:getEquipSlot(),"kuangbi.equip_slot")
			if not skill(self,self.player,sgs.lose_equip_skill) and source:getEquip(equip_index)~=nil then continue end
			if self:keepCard(card) then continue end
			if card:isKindOf("Weapon") then
				if card:isKindOf("Crossbow") then
					if not self:hasCrossbowEffect() and self:getCardsNum("Slash")>1 then continue end
				end
				if card:isKindOf("Axe") and self:ajustDamage(self.player,nil,1,known(self:getEvaluationCard("slash"),"yczh2016.slash"))>1 then continue end
			elseif card:isKindOf("Armor") then
				if self:isWeak() then
					if not self:needToThrowArmor() then continue end
				end
			elseif card:isKindOf("DefensiveHorse") then
				if self:isWeak() then continue end
			end
			if not table.contains(to_discard,card:getEffectiveId()) and (#to_discard<1 or skill(self,self.player,"xiaoji|kofxiaoji")) then
				table.insert(to_discard,card:getEffectiveId())
			end
			if #to_discard>=discard_num then break end
		end
	end
	
	if self:isFriend(source) then
		local Max = math.min(discard_num,self.player:getHandcardNum()-self.player:getMaxCards())
		if Max>#to_discard then
			for _,card in ipairs(cards)do
				if #to_discard>=Max then break end
				if not table.contains(to_discard,card:getEffectiveId()) then
					table.insert(to_discard,card:getEffectiveId())
				end
			end
		end
	end
	
	for _,card in ipairs(cards)do
		if #to_discard>=discard_num then break end
		if (card:isKindOf("Disaster") or card:isKindOf("AmazingGrace")) and not self:isValuableCard(card) 
		and not skill(self,self.player,sgs.notActive_cardneed_skill) and not table.contains(to_discard,card:getEffectiveId()) then
			table.insert(to_discard,card:getEffectiveId())
		end
	end
	
	if #to_discard<1 then return self:askForDiscard("dummy",1,1,false,true) end
	return to_discard
end

sgs.ai_use_priority.KuangbiCard = 7

--极奢
ai_fill_skill.jishe = function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("jishe","JisheDrawCard",request)
end

ai_card_use.JisheDrawCard = function(self, card, use, request)
	if self.player:getHandcardNum()<self.player:getMaxCards() then use.card = policy_card(self,"jishe","JisheDrawCard",{},request) end
	self:sortInPlace(self.enemies, "defense")
	local num = 0
	for _,enemy in ipairs(self.enemies)do
		if not enemy:isChained() and not skill(self,enemy,"qianjie|jieying") then
			num = num+1
		end
	end
	if num>1 and self.player:getHp()>1 then
		if self.player:getRole()~="renegade" and self.player:getRole()~="lord" then use.card = policy_card(self,"jishe","JisheDrawCard",{},request) end
		if self.player:getMaxCards()==1 then use.card = policy_card(self,"jishe","JisheDrawCard",{},request) end
	end
end

local function policy___jishe(self,prompt)
	self:sortInPlace(self.enemies, "defense")
	local targets = {}
	local n = 0
	for _,enemy in ipairs(self.enemies)do
		if enemy:isChained() then
			n = n+1
		elseif #targets<self.player:getHp() then
			if not enemy:isChained() and not skill(self,enemy,"qianjie|jieying") and not hasYinshiEffect(enemy) then
				table.insert(targets,enemy:objectName())
			end
		end	
		if n>0 and #targets==self.player:getHp() then break end
	end
	if (n>0 or #targets>0) and #targets<self.player:getHp() and self.player:getRole()~="renegade" and self.player:getRole()~="lord" and skill(self,self.player,"lianhuo") and not self.player:isChained() then
		table.insert(targets,self.player:objectName())
	end
	if #targets<self.player:getHp() then
		for _,friend in ipairs(self.friends)do
			if not friend:isChained() and hasYinshiEffect(friend) then
				table.insert(targets,friend:objectName())
			end	
			if #targets==self.player:getHp() then break end
		end
	end
	return "@JisheCard=.->"..table.concat(targets,"+")
end

sgs.ai_card_intention.JisheCard = function(self,card,from,tos)
	for _,to in ipairs(tos)do
		if hasYinshiEffect(to)
--		or self:needHurt(to,from)
		then continue end
		sgs.updateIntention(from,to,10)
	end
end

sgs.ai_use_priority.JisheDrawCard = 9
sgs.ai_use_value.JisheDrawCard = 1

--止戈
ai_fill_skill.zhige = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getHandcardNum()<=self.player:getHp() then return end
	return self:legacySkillSeed("zhige","ZhigeCard",request)
end

ai_card_use.ZhigeCard = function(self, card, use, request)
	local targets = {}
	local best_enemy = nil
	for _,friend in ipairs(self.friends_noself)do
		if not friend:inMyAttackRange(self.player) then continue end
		local best_target,target
		if getCardsNum("Slash",friend,self.player)>=1 then
			for _,enemy in ipairs(self.enemies)do
				local slash = known(self:getEvaluationCard("slash"),"yczh2016.slash")
				if friend:canSlash(enemy) and not self:slashProhibit(nil,friend,enemy) and friend:inMyAttackRange(enemy)
				and self:slashIsEffective(slash,friend,enemy) and self:isGoodTarget(enemy,self.enemies,slash) then
					if enemy:getHp()==1 and getCardsNum("Jink",enemy)==0 then best_target = enemy break end
					if self:getDefense(enemy)<6 then best_target = enemy break end
				end
			end
		end
		if getCardsNum("Slash",friend,self.player)>1 then
			for _,enemy in ipairs(self.enemies)do
				local slash = known(self:getEvaluationCard("slash"),"yczh2016.slash")
				if friend:canSlash(enemy) and not self:slashProhibit(nil,friend,enemy) and friend:inMyAttackRange(enemy)
				and self:slashIsEffective(slash,friend,enemy) and self:isGoodTarget(enemy,self.enemies,slash) then
					target = enemy
					break
				end
			end
		end
		
		if best_target or target or self:needToThrowCard(friend,"e") then 
			table.insert(targets,friend)
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if enemy:getCards("e"):isEmpty() or self:needToThrowCard(enemy,"e") then continue end
		if not enemy:inMyAttackRange(self.player) then continue end
		local add_enemy = false
		if enemy:isKongcheng() and getCardsNum("Slash",enemy,self.player)<1 then add_enemy = true end
		if not add_enemy then
			for _,friend in ipairs(self.friends)do
				local slash = known(self:getEvaluationCard("slash"),"yczh2016.slash")
				if enemy:canSlash(friend) and not self:slashProhibit(nil,enemy,friend) and enemy:inMyAttackRange(friend)
				and self:slashIsEffective(slash,enemy,friend) and self:isGoodTarget(friend,self.friends,slash) then
					if getCardsNum("Slash",enemy,self.player)>1 then break end
					add_enemy = true
				end
			end
		end
		if add_enemy then table.insert(targets,enemy) end
	end
	if #targets==0 then return end
	for _,target in ipairs(targets)do
		if self:isFriend(target) then continue end
		if getCardsNum("Slash",target,self.player)<1 then
			if target:getDefensiveHorse() and not self.player:getDefensiveHorse() then
			elseif target:getOffensiveHorse() and not self.player:getOffensiveHorse() then
			elseif target:getArmor() then
				if self.player:getArmor() and self:evaluateArmor(target:getArmor())>=self:evaluateArmor(self.player:getArmor()) then
				elseif not self.player:getArmor() then
					if skill(self,self.player,"bazhen|yizhong|linglong|fuyin") or hasYinshiEffect(self.player) then return end
				else return end
			elseif target:getWeapon() then
				if self.player:getWeapon() and self:evaluateArmor(target:getWeapon())>=self:evaluateArmor(self.player:getWeapon()) then
				elseif not self.player:getWeapon() then
				else return end
			elseif target:getTreasure() and target:getPile("wooden_ox"):length()>0 then
			else continue end
			best_enemy = target
			break
		end
	end
	use.card = policy_card(self,"zhige","ZhigeCard",{},request)
	if best_enemy then
		use.to:append(best_enemy)
	else
		self:sortInPlace(targets, "defenseSlash")
		use.to:append(targets[1])
	end
end

ai_skill_use["zhige-slash"] = function()
 ai_unsupported("fixed donor forwards undefined prompt to slash:split", "zhige-slash.donor_nil_prompt")
end

sgs.ai_skill_cardask["zhige-give"] = function(self,data,pattern,target)
	local id = self:disEquip()
	if id then return "$"..id end
	local cards = AIList.new(self.player:getCards("e"))
	cards = self:sortByKeepValue(cards)
	return "$"..cards[1]:getEffectiveId()
end

sgs.ai_use_value.ZhigeCard = 2
sgs.ai_use_priority.ZhigeCard = 9.2

-- 武将自身的选将策略

-- 岑昏：内奸推荐；忠臣在火焰体系主公下推荐
sgs.ai_general_choice["cenhun"] = function(ai, lord, role)
	if role == "renegade" then
		return 1
	end

	if role == "loyalist" and lord then
		local lord_general = general(ai,lord)
		if lord_general then
			local skill_desc = lord_general:getSkillDescription(true) or ""
			if string.find(skill_desc, "火焰") or string.find(skill_desc, "火攻")
				or string.find(skill_desc, "火计") or string.find(skill_desc, "火属性") then
				return 1
			end
		end
	end

	return 0
end


ai_skill_use["@@qinqing"]=function(self,prompt,request)
 local result=policy___qinqing(self,prompt)
 if type(result)=="table"then ai_unsupported("fixed donor returns an ID table where use protocol requires a string","huisheng.donor_list_answer")end
 return source_action(self,result,request)
end

ai_skill_use["@@huisheng"]=function(self,prompt,request)
 local result=policy___huisheng(self,prompt)
 if type(result)=="table"then ai_unsupported("fixed donor returns an ID table where use protocol requires a string","huisheng.donor_list_answer")end
 return source_action(self,result,request)
end

ai_skill_use["@@jishe"]=function(self,prompt,request)
 local result=policy___jishe(self,prompt)
 if type(result)=="table"then ai_unsupported("fixed donor returns an ID table where use protocol requires a string","huisheng.donor_list_answer")end
 return source_action(self,result,request)
end

ai_fill_skill.taoluan = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards)
	if #cards<2 then return end
	self:sortInPlace(self.friends_noself, "card", true)
    for _,name in ipairs(known(AICardCatalog.patternNames(),"yczh2016.patterns"))do
        local card = self:getEvaluationCard(name)
        if card and self.player:getMark("taoluan_"..name)<1
		and (card:isKindOf("BasicCard") or card:isNDTrick())
		and self:getCardsNum(card:getClassName())<1 and #self.friends_noself>0
		and self.friends_noself[1]:getHandcardNum()>1 then
            card=self:evaluateSkillCard("taoluan",name,{cards[1]:getEffectiveId()})
			if card:isAvailable(self.player) then
				local dummy = self:aiUseCard(card)
				if dummy.card then
					remember_targets(self,"taoluan_targets",dummy)
					if card:canRecast() and dummy.to:length()<1 then continue end
					return policy_card(self,"taoluan","TaoluanCard",{cards[1]:getEffectiveId()},request,name)
				end
			end
		end
	end
	self:sortInPlace(self.enemies, "hp")
    for _,name in ipairs(known(AICardCatalog.patternNames(),"yczh2016.patterns"))do
        local card = self:getEvaluationCard(name)
        if card and self.player:getMark("taoluan_"..name)<1
		and (card:isKindOf("BasicCard") or card:isNDTrick())
		and card:isDamageCard() and #self.enemies>0 and self:isWeak(self.enemies[1])
		and self:getCardsNum(card:getClassName())<1 then
            card=self:evaluateSkillCard("taoluan",name,{cards[1]:getEffectiveId()})
			if card:isAvailable(self.player) then
				local dummy = self:aiUseCard(card)
				if dummy.card then
					remember_targets(self,"taoluan_targets",dummy)
					return policy_card(self,"taoluan","TaoluanCard",{cards[1]:getEffectiveId()},request,name)
				end
			end
		end
	end
end

ai_card_use.TaoluanCard = function(self, card, use, request)
	use.card = card
	use.to = restore_targets(self,"taoluan_targets")
end

sgs.ai_skill_playerchosen.taoluan = function(self,players)
	local destlist = players
    destlist = AIList.new(destlist) -- 将列表转换为表
	self:sortInPlace(destlist, "card", true)
    for _,target in ipairs(destlist)do
    	if self:isFriend(target)
		and not target:isNude()
		then return target end
	end
    for _,target in ipairs(destlist)do
    	if not self:isEnemy(target)
		and not target:isNude()
		then return target end
	end
    return destlist[1]
end

sgs.ai_guhuo_card.taoluan = function(self,toname,class_name)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards)
	if #cards>0 and self.player:getMark("taoluan_"..toname)<1
	and self.player:getMark("TaoluanInvalid-Clear")<1
	and (#self.friends_noself>0 or not self:isWeak())
	and self.request.reason==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	then
        local num = self:getCardsNum(class_name,"he")
       	if num<1
     	then
           	local material=cards[1];return {name=toname,skill="taoluan",user_string=toname,suit=material:getSuit(),number=material:getNumber(),subcards={material:getEffectiveId()}}
       	end
	end
end

sgs.ai_skill_cardask["@taoluan-give"] = function(self,data,pattern,prompt)
    local use = data:toCardUse()
    if self:isFriend(use.from)
	then return true end
	return "."
end


ai_fill_skill.tenyeartaoluan = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards)
	local cid
	for _,c in ipairs(cards)do
		if self.player:getMark("tenyeartaoluan_"..c:getSuitString().."-Clear")<1
		then cid = c:getEffectiveId() break end
	end
	if cid==nil then return end
	self:sortInPlace(self.enemies, "hp")
	self:sortInPlace(self.friends_noself, "card", true)
    for _,name in ipairs(known(AICardCatalog.patternNames(),"yczh2016.patterns"))do
        local card = self:getEvaluationCard(name)
        if card and card:isAvailable(self.player)
		and self.player:getMark("tenyeartaoluan_"..name)<1
		and (card:isKindOf("BasicCard") or card:isNDTrick())
		then
            card=self:evaluateSkillCard("tenyeartaoluan",name,{cid})
         	local dummy = self:aiUseCard(card)
			remember_targets(self,"tenyeartaoluan_targets",dummy)
            local num = self:getCardsNum(card:getClassName(),"he")
			if dummy.card and dummy.to
			and num<1 and #self.friends_noself>0
        	and self.friends_noself[1]:getHandcardNum()>1
			then
	           	if card:canRecast()
				and dummy.to:length()<1
				then continue end
				return policy_card(self,"tenyeartaoluan","TenyearTaoluanCard",{cid},request,name)
			end
		end
	end
    for _,name in ipairs(known(AICardCatalog.patternNames(),"yczh2016.patterns"))do
        local card = self:getEvaluationCard(name)
        if card and card:isAvailable(self.player)
		and self.player:getMark("tenyeartaoluan_"..name)<1
		and (card:isKindOf("BasicCard") or card:isNDTrick())
		then
            card=self:evaluateSkillCard("tenyeartaoluan",name,{cid})
         	local dummy = self:aiUseCard(card)
			remember_targets(self,"tenyeartaoluan_targets",dummy)
            local num = self:getCardsNum(card:getClassName(),"he")
			if dummy.card and dummy.to
			and num<1 and #self.enemies>0
			and self:isWeak(self.enemies[1])
        	and card:isDamageCard()
			then
				return policy_card(self,"tenyeartaoluan","TenyearTaoluanCard",{cid},request,name)
			end
		end
	end
end

ai_card_use.TenyearTaoluanCard = function(self, card, use, request)
	use.card = card
	use.to = restore_targets(self,"tenyeartaoluan_targets")
end

sgs.ai_skill_playerchosen.tenyeartaoluan = function(self,players)
	local destlist = players
    destlist = AIList.new(destlist) -- 将列表转换为表
	self:sortInPlace(destlist, "card", true)
    for _,target in ipairs(destlist)do
    	if self:isFriend(target)
		and not target:isNude()
		then return target end
	end
    for _,target in ipairs(destlist)do
    	if not self:isEnemy(target)
		and not target:isNude()
		then return target end
	end
    return destlist[1]
end

sgs.ai_guhuo_card.tenyeartaoluan = function(self,toname,class_name)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards)
	local cid
	for _,c in ipairs(cards)do
		if self.player:getMark("tenyeartaoluan_"..c:getSuitString().."-Clear")<1
		then cid = c:getEffectiveId() break end
	end
	if cid
	and self.player:getMark("tenyeartaoluan_"..toname)<1
	and (#self.friends_noself>0 or not self:isWeak())
	and self.player:getMark("TenyearTaoluanInvalid-Clear")<1
	and self.request.reason==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	then
        local num = self:getCardsNum(class_name,"he")
       	if num<1
     	then
           	local cost=material(self,cid);return {name=toname,skill="tenyeartaoluan",user_string=toname,suit=cost:getSuit(),number=cost:getNumber(),subcards={cid}}
       	end
	end
end


-- Public activation dispatch uses the same source callbacks without changing their original keys.
for class,name in pairs(classes)do if sgs.ai_card_intention[class]~=nil then sgs.ai_card_intention[name]=sgs.ai_card_intention[class]end end
