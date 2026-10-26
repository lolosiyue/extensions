-- Source: b6025acc ai/leo-ai.lua.
local package_skills={}
local known = AIValue.requireKnown


local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return self:legacySkillSeed(skill, class, action_request(self,request)) end
local skill_cards={['#luajuesii']='luajuesii',['#luatuxiex_card']='luatuxiex',['#luaqingqi_card']='luaqingqi',['#luayuanlue']='luayuanlue',['#luazhuixi']='luazhuixi',['#luayonglue']='luayonglue',['#luafuweicard']='luafuwei',['#luajieyicard']='luajieyi',['#luashanquan']='luashanquan',['#luafanfu']='luafanfu',['#luazhiyong']='luazhiyong'}
local names={slash='Slash',jink='Jink',peach='Peach',analeptic='Analeptic',fire_slash='FireSlash',thunder_slash='ThunderSlash',duel='Duel',iron_chain='IronChain'}
local function ids(cards)local out={};for _,card in ipairs(cards)do out[#out+1]=type(card)=='number'and card or card:getKnownEffectiveId()end;return out end
local function own_card(player,id)
 for _,group in ipairs({player:getCards('he'),player:getHandPileCards()})do for _,card in ipairs(group)do if card:getKnownEffectiveId()==id then return card end end end
 ai_unsupported('source card face is not owner-disclosed',tostring(id))
end
local function disclosed(self,id)return known(self:getKnownCardById(id)or self:getChoiceCard(id),'leo source card '..tostring(id))end
local function material(card,name,skill)return{name=name,skill=skill,suit=card:getSuit(),number=card:getNumber(),subcards={card:getKnownEffectiveId()}}end
local function aggregate(cards)
 local suit,number=sgs.Card_NoSuit,0
 if #cards==1 then return cards[1]:getSuit(),cards[1]:getNumber()end
 if #cards>1 then local red,black=true,true;for _,card in ipairs(cards)do red=red and card:isRed();black=black and card:isBlack()end;suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit end
 return suit,number
end
local function normal_spec(self,skill,name,costs)
 local cards={};for _,id in ipairs(ids(costs))do cards[#cards+1]=disclosed(self,id)end
 local suit,number=aggregate(cards);return{name=name,skill=skill,suit=suit,number=number,subcards=ids(cards)}
end
local function turn_normal(self,skill,name,costs,request)
 return self:evaluateTurnConversion(skill, names[name]or (self:getEvaluationCard(name)):getClassName(), normal_spec(self,skill,name,costs), action_request(self,request))
end
local function owner_eval(self,skill,name,costs,suit,number)
 return self:evaluateOwnerViewAsCard({source_key=skill,skill=skill,name=name,suit=suit,number=number,subcards=costs})
end
local function wire_parts(wire)
 local class,raw,user=wire:match('^(#[^:]+):([^:]*):(.*)$');if not class then return end
 local costs={};for id in raw:gmatch('%d+')do costs[#costs+1]=tonumber(id)end
 return class,costs,user~=''and user or nil
end
local function parse(self,request,wire)
 local class,costs,user=wire_parts(wire)
 if class then local skill=known(skill_cards[class],class)
  if #costs==0 and user==nil then return seed(self,skill,class,request)end
  return self:evaluateTurnSkillCard(skill, class, costs, action_request(self,request), user)
 end
 local name,skill,id=wire:match('^([^:]+):([^%[]+)%[[^%]]+%]=(%d+)$')
 if not name then ai_unsupported('unrecognized source card grammar',wire)end
 return self:evaluateTurnConversion(skill, names[name]or (self:getEvaluationCard(name)):getClassName(), material(disclosed(self,tonumber(id)),name,skill), action_request(self,request))
end
local function final_parse(self,request,wire)
 local class,costs,user=wire_parts(wire)
 return self:bindSkillCard(known(skill_cards[class],class), costs, action_request(self,request), user, class)
end
local function response_wire(self,wire)
 if wire==nil or wire=='.'then return wire end
 local source,targetwire=wire:match('^(.-)%->(.*)$');if not source then ai_unsupported('source response has no target separator',wire)end
 local use=AIUsePlan.new();use.card=final_parse(self,nil,source);use.to=AIList.new{}
 for name in targetwire:gmatch('[^+]+')do use.to:append(known(self.room:findPlayerByObjectName(name),'source target'))end
 return use:toAnswer()
end
local function response_spec(self,skill,class,cards)
 local name=({Slash='slash',Jink='jink'})[class];return normal_spec(self,skill,known(name,class),ids(cards))
end
local function normal_response(self,card,skill,targets)
 local spec={name=card:objectName(),skill='luaspbazhen',suit=card:getSuit(),number=card:getNumber(),subcards={}}
 local use=AIUsePlan.new();use.card=self:bindOriginalSelectedConversion(spec, card:getClassName(), skill);use.to=AIList.new{}
 for _,name in ipairs(targets)do use.to:append(known(self.room:findPlayerByObjectName(name),'response target'))end
 return use:toAnswer()
end
local dummy = AIUsePlan.dummy
local function no_distance_use(self,slash,source)return self:withOwnerRange('slashNoDistanceLimit', source, function()return self:aiUseCard(slash)end)end
local function role_count(self,name)local policy=self.world.mode_policy;return known(policy and policy.role_counts and policy.role_counts[name],'role count '..name)end
local function role(self,player)
 local value=player:getRole();if value~=nil then return value end
 return self:useKnowledgeEstimate({status='estimate',value=self:getRoleEstimate(player),basis='viewer_role_estimate_private_role',player=player:objectName()}, 'leo.role')
end
local function context_value(self,key)local context=self:getDecisionContext();local value=known(context[key],key);if value==false then return nil end;return value end
local function context_player(self,key)local name=context_value(self,key);if name==nil then return nil end;return known(self.room:findPlayerByObjectName(name),key)end
local function public_flag(self,player,name)
 -- Player flags are broadcast and projected for every player.
 return player:hasFlag(name)
end
local function source_visible_hand(self,player)
 -- Known hand cards that carry a visibility flag toward this viewer, in hand order.
 local flag=string.format("visible_%s_%s",self.player:objectName(),player:objectName());local cards={}
 for _,c in ipairs(player:getKnownCards())do
  if c:hasFlag('visible') or c:hasFlag(flag) then cards[#cards+1]=c end
 end
 return cards
end
local function first_hand(self,player)
 if player:objectName()==self.player:objectName()then return player:getHandcards()[1]end
 if player:isHandVisible()==true then local cards=player:getKnownCards();if #cards==player:getHandcardNum()then return cards[1]end end
 ai_unsupported('luaqingqi original first-hand selection requires a scoped opaque card choice','luaqingqi.first_hand')
end
local function set_mark(self,name,value)self:setStrategyMemory('leo.mark:'..name, value)end
local function get_mark(self,name)local value,known_memory=self:getStrategyMemory('leo.mark:'..name);if known_memory then return known(value,name)end;return self.player:getMark(name)end
local function kingdoms(player)
 local result={[player:getKnownKingdom()]=true};for _,other in ipairs((player:getRoom()):getOtherPlayers(player))do result[other:getKnownKingdom()]=true end
 local n=0;for _ in pairs(result)do n=n+1 end;return n
end
local luajuesii_skill = {}
luajuesii_skill.name = "luajuesii"
table.insert(package_skills, luajuesii_skill)
luajuesii_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local target
	local duel = self:getEvaluationCard("duel")
	
	local dummy = self:aiUseCard(duel)
	if dummy.card and dummy.to
		then
		for _,enemy in sgs.list(dummy.to)do
			target = enemy
			break
		end
	end
		
	if not self.player:isWounded() then return end

	local losthp = isLord(self.player) and 0 or 1
	if ((self.player:getHp() > 3 and self.player:getLostHp() <= losthp)
			or (self.player:getHp() - self.player:getHandcardNum() >= 2)) and target and not (isLord(self.player) and self.room:getTurnCount() <= 1) then
		return parse(self,request,"#luajuesii:.:")
	end
	if self.player:getHp() == 1 and self:getCardsNum("Analeptic") >= 1 then
		return parse(self,request,"#luajuesii:.:")
	end

	--Suicide by NosKurou
	local nextplayer = self.player:getNextAlive()
	if self.player:getHp() == 1 and self.player:getKnownRole() ~= "lord" and self.player:getKnownRole() ~= "renegade" then
		local to_death = false
		if self:isFriend(nextplayer) then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasSkill("xiaoguo") and not self:isFriend(p) and not p:isKongcheng()
					and self.role == "rebel" and self.player:getEquips():isEmpty() then
					to_death = true
					break
				end
			end
			if not to_death and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkill("jieyin") and self.player:isMale() then return end
				if nextplayer:hasSkill("qingnang") then return end
			end
		end
		if self.player:getKnownRole() == "rebel" and not self:isFriend(nextplayer) then
			if not self:willSkipPlayPhase(nextplayer) or nextplayer:hasSkill("shensu") then
				to_death = true
			end
		end
		local lord = self.room:getLord()
		if self.player:getKnownRole() == "loyalist" then
			if lord and lord:getCards("he"):isEmpty() then return end
			if self:isEnemy(nextplayer) and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkills("noslijian|lijian") and self.player:isMale() and lord and lord:isMale() then
					to_death = true
				elseif nextplayer:hasSkill("quhu") and lord and lord:getHp() > nextplayer:getHp() and not lord:isKongcheng()
					and lord:inMyAttackRange(self.player) then
					to_death = true
				end
			end
		end
		if to_death then
			local caopi = self.room:findPlayerBySkillName("xingshang")
			if caopi and self:isEnemy(caopi) then
				if self.player:getKnownRole() == "rebel" and self.player:getHandcardNum() > 3 then to_death = false end
				if self.player:getKnownRole() == "loyalist" and lord and lord:getCardCount(true) + 2 <= self.player:getHandcardNum() then
					to_death = false
				end
			end
			if #self.friends == 1 and #self.enemies == 1 and self.player:aliveCount() == 2 then to_death = false end
		end
		if to_death then
			self:setStrategyPlayerFlag(self.player, "NosKurou_toDie", true)
			return parse(self,request,"#luajuesii:.:")
		end
		self:setStrategyPlayerFlag(self.player, "NosKurou_toDie", false)
	end
end

ai_card_use["#luajuesii"] = function(self, card, use, request)
	local target
	local duel = self:getEvaluationCard("duel")
	
	local dummy = self:aiUseCard(duel)
	if dummy.card and dummy.to
		then
		for _,enemy in sgs.list(dummy.to)do
			target = enemy
			break
		end
	end

	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end



ai_skill_choice.luajuesii = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	if self:hasZhaxiangEffect(self.player) and self:getAllPeachNum() + self.player:getHp() > 0 then return ai_choice_result(("luajuesii2"), options) end
	for _, friend in ipairs(self.friends) do
		if friend:hasSkills("tianxiang|ol_tianxiang") and (self.player:getHp() >= 3 or (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 and self.player:getHp() > 1)) then
			return ai_choice_result(("luajuesii2"), options)
		end
	end
	if self.player:getMaxHp() >= self.player:getHp() + 2 then
		if self.player:getMaxHp() > 5 and (self.player:hasSkills("nosmiji|yinghun|juejing|zaiqi|nosshangshi") or self.player:hasSkill("miji") and self:findPlayerToDraw(false) or self.player:hasSkills(sgs.need_maxhp_skill)) then
			local enemy_num = 0
			for _, p in ipairs(self.enemies) do
				if p:inMyAttackRange(self.player) and not self:willSkipPlayPhase(p) then enemy_num = enemy_num + 1 end
			end
			local ls = self:getStrategyMemory("fangquan_effect") and self.room:findPlayerBySkillName("fangquan")
			if ls then
				self:setStrategyMemory("fangquan_effect", false)
				enemy_num = self:getEnemyNumBySeat(ls, self.player, self.player)
			end
			local least_hp = isLord(self.player) and math.max(2, enemy_num - 1) or 1
			if (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self.player:getHp() > least_hp) then
				return
				ai_choice_result(("luajuesii2"), options)
			end
		end
		return ai_choice_result(("luajuesii1"), options)
	else
		return ai_choice_result(("luajuesii2"), options)
	end

    return ai_choice_result(nil, options)
end



sgs.ai_use_priority["luajuesii"] = 6.8



local function select_tuxi(self,prompt)
	self:sortInPlace(self.enemies, "handcard_defense")
	local tuxi_mark = 1
	local targets = {}

	local add_player = function(player, isfriend)
		if player:getHandcardNum() == 0 or player:objectName() == self.player:objectName() then return #targets end
		if self:objectiveLevel(player) == 0 and player:isLord() and role_count(self,"rebel") > 1 then return #targets end

		local f = false
		for _, c in ipairs(targets) do
			if c == player:objectName() then
				f = true
				break
			end
		end

		if not f then table.insert(targets, player:objectName()) end

		if isfriend and isfriend == 1 then
			self:setStrategyPlayerFlag(self.player, "tuxi_isfriend_"..player:objectName(), true)
		end
		return #targets
	end

	local parseTuxiCard = function()
		if #targets == 0 then return "." end
		local s = table.concat(targets, "+")
		return "#luatuxiex_card:.:->" .. s
	end

	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and self.room:getTurnCount() <= 1 and not lord:isKongcheng() then
		if add_player(lord) == tuxi_mark then return parseTuxiCard() end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local cards = source_visible_hand(self,p)
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), p:objectName())
		for _, card in ipairs(cards) do
			if true and (card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic")) then
				if add_player(p) == tuxi_mark then return parseTuxiCard() end
			end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		if p:hasSkills("jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
			if add_player(p) == tuxi_mark then return parseTuxiCard() end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local x = p:getHandcardNum()
		local good_target = true
		if x == 1 and self:needKongcheng(p) then good_target = false end
		if x >= 2 and self:hasTuntianEffect(p, true) then good_target = false end
		if good_target and add_player(p) == tuxi_mark then return parseTuxiCard() end
	end


	local others = self.room:getOtherPlayers(self.player)
	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not (self:hasTuntianEffect(other, true)) and add_player(other) == tuxi_mark then
			return parseTuxiCard()
		end
	end

	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not (self:hasTuntianEffect(other, true)) and math.random(0, 5) <= 1 and not self:hasSkills("qiaobian") then
			add_player(other)
		end
	end

	return parseTuxiCard()
end

ai_skill_invoke.luatuxiex=function(self, options, request)local data = request and self:getDecisionData(request) or nil; local wire=select_tuxi(self,"@luatuxiex");return (wire:match("->")~=nil) or false end
ai_skill_use["@@luatuxiex"]=function(self, prompt, request)return response_wire(self,select_tuxi(self,prompt))end
sgs.ai_card_intention["luatuxiex"] = function(self, card, from, tos)
	local lord = self.room:getLord()
	local tuxi_lord = false
	if self:getRoleEstimate(from) == "neutral" and self:getRoleEstimate(tos[1]) == "neutral" and
		(not tos[2] or self:getRoleEstimate(tos[2]) == "neutral") and lord and not lord:isKongcheng() and
		not (self:needKongcheng(lord) and lord:getHandcardNum() == 1) and
		self:hasLoseHandcardEffective(lord) and not (self:hasTuntianEffect(lord, true)) and from:aliveCount() >= 4 then
		self:updateIntention(from, lord, -80)
		return
	end
	if from:getState() == "online" then
		for _, to in ipairs(tos) do
			if self:needKongcheng(to)
				or (self:hasTuntianEffect(to, true)) then
			else
				self:updateIntention(from, to, 80)
			end
		end
	else
		for _, to in ipairs(tos) do
			if lord and to:objectName() == lord:objectName() then tuxi_lord = true end
			local intention = self:hasStrategyPlayerFlag(from, "tuxi_isfriend_"..to:objectName()) and -5 or 80
			self:updateIntention(from, to, intention)
		end
		if self.room:getTurnCount() == 1 and not tuxi_lord and lord and not lord:isKongcheng() and from:getRoom():alivePlayerCount() > 2 then
			self:updateIntention(from, lord, -80)
		end
	end
end
sgs.drawpeach_skill = sgs.drawpeach_skill .. "|luatuxiex"




ai_skill_choice["luaqingqi"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local target = data:toPlayer()
	if target then
		local slash = self:getEvaluationCard("slash")
		
		if self:isFriend(target) then
			local judges = target:getJudgingArea()
			if not judges:isEmpty() then
				for _, judge in sgs.qlist(judges) do
					if not judge:isKindOf("YanxiaoCard") then
						return ai_choice_result(("luaqingqi2"), options)
					end
				end
			else
				if self.player:canSlash(target, slash) and not self:slashProhibit(slash, target)
					and self:slashIsEffective(slash, target) and self:needToLoseHp(target, self.player, slash) then
					return ai_choice_result(("luaqingqi1"), options)
				end
			end
		else
			if self.player:canSlash(target, slash) and not self:slashProhibit(slash, target)
				and self:slashIsEffective(slash, target) and self:isGoodTarget(target, self.enemies, slash) then
				return ai_choice_result(("luaqingqi1"), options)
			else
				return ai_choice_result(("luaqingqi2"), options)
			end
		end
	end
	return ai_choice_result(("cancel"), options)
end

ai_skill_use["@@luaqingqi"] = function(self, prompt, request)
	self:sortInPlace(self.enemies, "handcard_defense")
	local targets = {}
	local slash = self:getEvaluationCard("slash")

	
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) then
			if self:slashIsEffective(slash, enemy) and not self:slashProhibit(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
				return "#luaqingqi_card:.:->" .. enemy:objectName()
			end
		end
	end
	for _, friend in ipairs(self.friends) do
		local judges = friend:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				if not judge:isKindOf("YanxiaoCard") then
					return "#luaqingqi_card:.:->" .. friend:objectName()
				end
			end
		end
	end
end




sgs.ai_skill_cardchosen["luaqingqi"] = function(self, who, flags)
	local equipments = AIList.new(who:getEquips())
	equipments = sgs.reverse(equipments)
	-- Source first-hand is resolved only if the branch consumes it.
	if self:isFriend(who) then
		--SmartAI:askForCardChosen的判定區檢測
		if flags:match("j") and not who:containsTrick("YanxiaoCard") and not (who:hasSkill("qiaobian") and who:getHandcardNum() > 0) then
			local tricks = who:getCards("j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") then
					lightning = trick:getKnownEffectiveId()
				elseif trick:isKindOf("Indulgence") then
					indulgence = trick:getKnownEffectiveId()
				elseif not trick:isKindOf("Disaster") then
					supply_shortage = trick:getKnownEffectiveId()
				end
			end

			if self:hasWizard(self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if who:getHp() < who:getHandcardNum() then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end

		if who:getPile("wooden_ox"):length() > 0 then
			for _, e in ipairs(equipments) do
				if e:isKindOf("WoodenOx") then
					table.removeOne(equipments, e)
				end
			end
		end

		if who:hasArmorEffect("silver_lion") and who:isWounded() then
			return who:getArmor()
		end
		if who:getEquips():length() > 0 then
			if who:getHandcardNum() > 2 or (who:getHandcardNum() > 0 and who:getPile("wooden_ox"):length() > 0) then
				return first_hand(self,who)
			else
				return equipments[1]
			end
		end
	end
	return nil
end





ai_skill_invoke.feijiangts = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if not target then
		return (true) or false
	end
	if self:isFriend(target) then
		if self:needKongcheng(target) and target:getHandcardNum() == 1 then return (true) or false end
		if self:getOverflow(target) > 2 then return (true) or false end
		return (false) or false
	else
		return (not (self:needKongcheng(target) and target:getHandcardNum() == 1)) or false
	end
	return false

end

sgs.ai_choicemade_filter.skillInvoke.feijiangts = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if public_flag(self,p,"feijiangtsTarget") then
			target = p
			break
		end
	end
	if target then
		local intention = 60
		if promptlist[#promptlist] == "yes" then
			if not self:hasLoseHandcardEffective(target) or (self:needKongcheng(target) and target:getHandcardNum() == 1) then
				intention = 0
			end
			if self:getOverflow(target) > 2 then intention = 0 end
			self:updateIntention(player, target, intention)
		else
			if self:needKongcheng(target) and target:getHandcardNum() == 1 then intention = 0 end
			self:updateIntention(player, target, -intention)
		end
	end
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.feijiangts",registry="ai_choicemade_filter",path={"cardChosen","feijiangts"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}

sgs.double_slash_skill = sgs.double_slash_skill .."|xinwushuang"
xinwushuang_skill = { name = "xinwushuang" }
table.insert(package_skills, xinwushuang_skill)
xinwushuang_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	self:updatePlayers()
	local has_weak_enemy = false
	for _, enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) then
			has_weak_enemy = true
		end
	end
	if (self.player:isKongcheng()) then return end
	if (self.player:getMark("xinwushuang-SelfPlayClear") > 0 ) then return end
	local cards = self.player:getCards("h")
	cards = AIList.new(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end
	local use_cards = {}
	local x = 0
	local duel = self:getEvaluationCard("duel")
	for _, enemy in ipairs(self.enemies) do
		if self:hasTrickEffective(duel, enemy, self.player) and self:canAttack(enemy, self.player) and
			self:damageIsEffective(self.player, sgs.DamageStruct_Normal, enemy) then
			x = x + 1
		end
	end

	if self.player:getHandcardNum() > 1 then
		self:sortByUseValueInPlace(cards, true)
		for _, acard in ipairs(cards) do
			if not (acard:isKindOf("Peach")) and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.Duel) and (x > #use_cards) then
				table.insert(use_cards, acard)
			end
		end
	end
	if #use_cards == 0 then return end
	local duel=turn_normal(self,"xinwushuang","duel",use_cards,request)
	return duel
end
sgs.ai_use_priority.xinwushuang_skill = sgs.ai_use_priority.ExNihilo - 0.1



sgs.ai_skill_cardask["@xinwushuang-slash"] = function(self, data, pattern, target)
	local duel = data:toCardEffect().card
	if self.player:getPhase() == sgs.Player_Play then return self:getCardId("Slash") end

	if self:standardNullFilter(data, pattern, target) then return "." end

	--有大傷害全部殺都丟出去
	if self:hasHeavyDamage(target, duel, self.player) then return self:getCardId("Slash") end

	if self.player:hasFlag("AIGlobal_NeedToWake") and self.player:getHp() > 1 then return "." end
	if (target:hasSkill("wuyan") or self.player:hasSkill("wuyan")) and not target:hasSkill("jueqing") then return "." end
	if self.player:getMark("@fenyong") > 0 and self.player:hasSkill("fenyong") and not target:hasSkill("jueqing") then
		return
		"."
	end
	if self.player:hasSkill("wuhun") and self:isEnemy(target) and target:isLord() and #self.friends_noself > 0 then
		return
		"."
	end

	--排除司馬徽隱士技能，AI司馬徽被打
	if target and self.player:hasSkill("yinshi") and not target:hasSkill("jueqing") and self.player:getMark("@dragon") + self.player:getMark("@phoenix") == 0 and not self.player:getArmor() then
		return
		"."
	end
	--排除TW馬良白眉，TW馬良被打
	if target and self.player:hasSkill("twyj_baimei") and not target:hasSkill("jueqing") and self.player:isKongcheng() then
		return
		"."
	end


	if self:cantbeHurt(target) then return "." end

	if self:isFriend(target) and target:hasSkill("rende") and self.player:hasSkill("jieming") then return "." end
	if self:isEnemy(target) and not self:isWeak() and self:cantbeHurt(target) then return "." end

	if self:isFriend(target) then
		if self:needToLoseHp(self.player, target) then return "." end
		if self:needToLoseHp(target, self.player) then
			return self:getCardId("Slash")
		else
			if target:isLord() and not self:isLordInDanger() and not self:isGoodHp(self.player) then
				return self:getCardId("Slash")
			end
			if self.player:isLord() and self:isLordInDanger() then return self:getCardId("Slash") end
			return "."
		end
	end
	local x = ((data:toCardEffect().card):getSubcards()):length()
	if (not self:isFriend(target) and (self:getCardsNum("Slash") >= ((known(getCardsNum("Slash",target,self.player),"xinwushuang observed Slash count") + 1) * (x - self.player:getMark("AI_xinwushuang-Clear")))) and x < 3)
		or (target:getHp() > 2 and self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and not self.player:hasSkill("buqu"))

		--薛綜復難技能有殺能出就出
		or (self.player:hasSkill("funan") and self.player:getMark("@funan") > 0)
	then
		return self:getCardId("Slash")
	else
		return "."
	end
end






local luayuanlue_skill = {
	name = "luayuanlue",
	getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

		if self.player:getStrategyHasUsed("#luayuanlue") then return end
		return parse(self,request,"#luayuanlue:.:")
	end,
}
table.insert(package_skills, luayuanlue_skill) --加入AI可用技能表
ai_card_use["#luayuanlue"] = function(self, card, use, request)
	self:updatePlayers()

	local acard = final_parse(self,request,"#luayuanlue:.:") --根据卡牌构成字符串产生实际将使用的卡牌
	assert(acard)

	local max = 0
	local min = 999
	local target

	self:sortInPlace(self.friends, "handcard")
	for _, friend in ipairs(self.friends) do
		local x = 0
		if friend:getHandcardNum() > friend:getHp() then
			x = friend:getHandcardNum() - friend:getHp()
		end
		if (x > min) and x <= 2 and (self:getBestHp(friend) < friend:getHp()) then
			min = x
			target = friend
		end
	end
	if not target then
		for _, friend in ipairs(self.friends) do
			local x = 0
			if friend:getHandcardNum() < friend:getHp() then
				x = friend:getHp() - friend:getHandcardNum()
			end
			if (x > max) and x > 3 and not self:hasManjuanEffect(friend) and self:canDraw(friend, self.player) then
				max = x
				target = friend
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			local x = 0
			if enemy:getHandcardNum() < enemy:getHp() then
				x = enemy:getHp() - enemy:getHandcardNum()
			end
			if (x < min) and (x < 2 or self:hasManjuanEffect(enemy)) and x > 0 and not self:hasZhaxiangEffect(enemy) then
				min = x
				target = enemy
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			local x = 0
			if enemy:getHandcardNum() > enemy:getHp() then
				x = enemy:getHandcardNum() - enemy:getHp()
			end
			if (x > max) and (x > 3) then
				max = x
				target = enemy
			end
		end
	end
	if target then
		use.card = acard
		if use.to then
			use.to:append(target) --填充卡牌使用结构体（to部分）
		end
		return
	end
end

sgs.ai_use_priority["luayuanlue"] = 3
sgs.ai_use_value["luayuanlue"] = 3

ai_audited_aliases.register{id="ai_cardneed.luajiezhi",registry="ai_cardneed",path={"luajiezhi"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.double_slash_skill = sgs.double_slash_skill .."|luajiezhi"

local luajiezhi_skill = {}
luajiezhi_skill.name = "luajiezhi"
table.insert(package_skills, luajiezhi_skill)
luajiezhi_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:hasFlag("luajiezhix") then return end
	local usable_cards = AIList.new(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(usable_cards, disclosed(self,id))
		end
	end
	self:sortByUseValueInPlace(usable_cards, true)
	local cards = {}
	for _, c in ipairs(usable_cards) do
		local cardex=owner_eval(self,"luajiezhi",disclosed(self,self.player:getMark("luajiezhiskill")):objectName(),{},c:getSuit(),c:getNumber())
		
		if not self.player:isCardLimited(cardex, sgs.Card_MethodUse, true) and cardex:isAvailable(self.player) and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink") < 3) and not cardex:isKindOf("IronChain") then
			local name = disclosed(self,self.player:getMark("luajiezhiskill")):objectName()
			local new_card = parse(self,request,(name .. ":luajiezhi[%s:%s]=%d"):format(c:getSuitString(),
				c:getNumberString(), c:getKnownEffectiveId()))
			assert(new_card)
			return new_card
		end
	end
end


ai_audited_aliases.register{id="ai_cardneed.luafeiqi",registry="ai_cardneed",path={"luafeiqi"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

ai_skill_invoke.luafeiqi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if not target then
		return (true) or false
	end
	return (self:doDisCard(target, "h")) or false
end




ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.luafeiqi",registry="ai_choicemade_filter",path={"cardChosen","luafeiqi"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}




ai_skill_use["@@luazhuixi"] = function(self, prompt, request)
	local cards = AIList.new(self.player:getCards("he"))
	self:sortInPlace(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	self:sortByUseValueInPlace(cards, true)
	if slashcount > 0 then
		for _, card in ipairs(cards) do
			if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0 then
				local slash = self:getCard("Slash")
				assert(slash)
				local target
				local dummy=no_distance_use(self,slash,"@@luazhuixi")
				if dummy.card and dummy.to then
					if not dummy.to:isEmpty() then
						for _, p in sgs.qlist(dummy.to) do
							if not self.player:inMyAttackRange(p) then
								target = p
							end
						end
					end
				end
				if target then
					return "#luazhuixi:" .. card:getKnownEffectiveId() .. ":->" .. target:objectName()
				end
			end
		end
	end
end


sgs.ai_skill_discard.luaqingzhan = function(self)
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = AIList.new(cards)
	self:sortByKeepValueInPlace(cards)

	for _, acard in ipairs(cards) do
		if not (acard:isKindOf("Peach")) and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.Slash) and #to_discard == 0 then
			table.insert(to_discard, acard:getKnownEffectiveId())
			break
		end
	end
	if #to_discard == 0 then return end

	return to_discard
end






ai_skill_use["@@luayonglue"] = function(self, prompt, request)
	local cards = AIList.new(self.player:getCards("he"))
	self:sortInPlace(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	self:sortByUseValueInPlace(cards, true)


	if self:needBear() then return "." end


	for _, enemy in ipairs(self.enemies) do
		if (self:doDisCard(enemy, "he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and self.player:canDiscard(enemy, "he") then
			return "#luayonglue:.:->" .. enemy:objectName()
		end
	end
	for _, friend in ipairs(self.friends) do
		if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
			or (self:needToThrowArmor(friend) and friend:getArmor()) or self:doDisCard(friend, "he") then
			return "#luayonglue:.:->" .. friend:objectName()
		end
	end




	if slashcount > 0 then
		for _, card in ipairs(cards) do
			if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0 then
				local slash = self:getCard("Slash")
				assert(slash)
				local target
				local dummy=no_distance_use(self,slash,"@@luayonglue")
				if dummy.card and dummy.to then
					if not dummy.to:isEmpty() then
						for _, p in sgs.qlist(dummy.to) do
							if not self.player:inMyAttackRange(p) then
								target = p
							end
						end
					end
				end
				if target then
					return "#luayonglue:.:->" .. target:objectName()
				end
			end
		end
	end
end


sgs.ai_card_intention["#luayonglue"] = 80


sgs.ai_choicemade_filter.cardChosen.luayonglue = sgs.ai_choicemade_filter.cardChosen.snatch


ai_skill_invoke.luamengxi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toDamage().to
	if not self:isEnemy(target) then return (false) or false end
	if target:hasArmorEffect("silver_lion") then return (false) or false end
	if self:cantDamageMore(self.player, target) then return (false) or false end

	return (true) or false
end

sgs.ai_ajustdamage_from.luamengxi = function(self, from, to, card, nature)
	if from:getMark("&luasizhanjl") and not self:beFriend(to, from)
	then
		return 1
	end
end
sgs.ai_playerchosen_intention.luazhonghun = -80

sgs.ai_skill_playerchosen.luazhonghun = function(self, targets)
	if self.player:getKnownRole() == "loyalist" then
		return self.room:getLord()
	end

	self:sortInPlace(self.friends_noself, "hp")
	for _, p in ipairs(self.friends_noself) do
		if self:isWeak(p) then
			return p
		end
	end
end

sgs.ai_ajustdamage_to["&luazhonghun"] = function(self, from, to, card, nature)
	for _, p in sgs.list(self.room:getOtherPlayers(to)) do
		if to:getMark("&luazhonghun+to+#" .. p:objectName()) > 0
		then
			return self:ajustDamage(from, p, 0, card, nature)
		end
	end
end

sgs.ai_need_damaged["&luazhonghun"] = function(self, attacker, player)
	local victim
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if player:getMark("&luazhonghun+to+#" .. p:objectName()) > 0 then
			victim = p
			break
		end
	end
	if victim ~= nil then
		local role
		if self:isRolePredictable() and self:getRoleEstimate(player) == "rebel" or self:compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
			role = "rebel"
		end
		local need_damage = false
		if (self:getRoleEstimate(player) == "loyalist" or player:isLord()) and role == "rebel" then need_damage = true end
		if self:getRoleEstimate(player) == "rebel" and role ~= "rebel" then need_damage = true end
		if self:getRoleEstimate(player) == "renegade" then need_damage = true end
		if victim:isAlive() and need_damage then
			return victim:hasSkill("wuhun") and 2 or 1
		end
	end

	return false
end



ai_skill_invoke.luajuesheng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if self:isFriend(target) and self:canDraw(target, self.player) then return (true) or false end

	return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.luajuesheng = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if public_flag(self,p,"luajueshengTarget") then
			target = p
			break
		end
	end
	if target then
		if promptlist[#promptlist] == "yes" then
			self:updateIntention(player, target, -40)
		end
	end
end



sgs.ai_skill_askforag["luaweiwo"] = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, disclosed(self,card_id))
	end
	self:sortByKeepValueInPlace(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end

ai_skill_use["@@luafuwei"] = function(self, prompt, request)
	local cards = AIList.new(self.player:getCards("h"))

	self:sortByUseValueInPlace(cards, true)

	for _, friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() <= self.player:getHandcardNum() then
			for _, card in ipairs(cards) do
				return "#luafuweicard:" .. card:getKnownEffectiveId() .. ":->" .. friend:objectName()
			end
		end
	end
	local players = AIList.new(self.room:getOtherPlayers(self.player))

	for _, player in ipairs(players) do
		if player:getHandcardNum() <= self.player:getHandcardNum() then
			for _, card in ipairs(cards) do
				return "#luafuweicard:" .. card:getKnownEffectiveId() .. ":->" .. player:objectName()
			end
		end
	end
end




sgs.ai_card_intention["#luafuweicard"] = -20


sgs.ai_getLeastHandcardNum_skill.luahuju = function(self, player, least)
	local x = math.min(kingdoms(player), 3)
	if x > 0 and least < x then
		return x
	end
end

local luajieyi_skill = {}
luajieyi_skill.name = "luajieyi"
table.insert(package_skills, luajieyi_skill)
luajieyi_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luajieyicard") then return end
	local hurtF = 0

	for _, p in ipairs(self.friends_noself) do
		if not p:isKongcheng() then hurtF = hurtF + 1 end
	end

	for _, p in ipairs(self.friends_noself) do
		if p:getHp() < self:getBestHp(p) and not p:isKongcheng() then hurtF = hurtF + 1 end
	end

	if hurtF > 0 then return parse(self,request,"#luajieyicard:.:") end
	return
end

ai_card_use["#luajieyicard"] = function(self, card, use, request)
	local targets = AIList.new({})

	for _, p in ipairs(self.friends_noself) do
		if p:getHp() < self:getBestHp(p) and not p:isKongcheng() and targets:length() < 2 and not targets:contains(p) then
			targets:append(p)
		end
	end

	for _, p in ipairs(self.friends_noself) do
		if not p:isKongcheng() and targets:length() < 2 and not targets:contains(p) then targets:append(p) end
	end

	if targets:length() == 0 then return end

	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeedInPlace(handcards, true)
	local use_card = nil
	for _, c in ipairs(handcards) do
		use_card = c
	end

	if (targets:length() > 0) and not (use_card == nil) then
		use.card = final_parse(self,request,"#luajieyicard:" .. use_card:getKnownEffectiveId() .. ":")
		if use.to then use.to = targets end
		return
	end
end





local luashanquan_skill = {}
luashanquan_skill.name = "luashanquan"
table.insert(package_skills, luashanquan_skill)
luashanquan_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luashanquan") or self.player:isKongcheng() then return end
	return parse(self,request,"#luashanquan:.:")
end
ai_card_use["#luashanquan"] = function(self, card, use, request)
	local targets = {}
	local target
	self:sortInPlace(self.enemies, "defense")
	self:sortInPlace(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if not self:hasManjuanEffect(friend) then
			if self:hasTuntianEffect(friend) and not friend:isKongcheng() then
				target = friend
				break
			end
			if friend:hasSkill("enyuan") and not friend:isKongcheng() then
				target = friend
				break
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:hasManjuanEffect(enemy) and not enemy:isKongcheng() then
			target = enemy
			break
		end
		if not self:hasTuntianEffect(enemy) and not enemy:isKongcheng() then
			target = enemy
			break
		end
	end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_discard["luashanquan"] = function(self, discard_num, optional, include_equip)
	local cards = AIList.new(self.player:getCards("he"))
	local to_discard = {}
	local compare_func = function(a, b)
		return self:getKeepValue(a) < self:getKeepValue(b)
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if #to_discard >= discard_num then break end
		table.insert(to_discard, card:getKnownId())
	end

	return to_discard
end

sgs.ai_getBestHp_skill.luajiye = function(owner)
	if owner:getMark("luajiye") == 0 then
		return owner:getMaxHp() - 1
	end
end

sgs.ai_target_revises.luaxiaomeng = function(to, card, self)
	if card:isKindOf("Slash")
	then
		return self.player:distanceTo(to) < 2
	end
end

sgs.ai_canliegong_skill.luaxiaomeng = function(self, from, to)
    if from:distanceTo(to) <= 1 then return true end
end

sgs.ai_getBestHp_skill.luatuwei = function(owner)
	if owner:getMark("luatuwei") == 0 then
		return owner:getMaxHp() - 1
	end
end

--fail


sgs.ai_view_as.luagudan = function(card, player, card_place, class_name)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place == sgs.Player_PlaceEquip and card:getTypeId() == sgs.Card_TypeEquip and not card:hasFlag("using") then
		if class_name == "Jink" then
			return material(card,"jink","luagudan")
		elseif class_name == "Slash" then
			return material(card,"slash","luagudan_dis")
		end
	end
end

function sgs.ai_cardsview_valuable.luagudan(self, class_name, player)
	if player:getPhase() ~= sgs.Player_NotActive then return end
	if class_name == "Slash"then
		local slashs = {}
		for _, c in sgs.qlist(player:getCards("h")) do
			if c:isKindOf("Slash") then
				table.insert(slashs, c)
			end
		end
		if #slashs == 0 then
			return response_spec(self,"luagudan_ex",class_name,player:getHandcards())
		end
	elseif class_name == "Jink" then
		local jinks = {}
		for _, c in sgs.qlist(player:getCards("h")) do
			if c:isKindOf("Jink") then
				table.insert(jinks, c)
			end
		end
		if #jinks == 0 then
			return response_spec(self,"luagudan_ex",class_name,player:getHandcards())
		end
	end
end


local SelfUseCard = function(self, card)
	local dummy = { isDummy = true, to = AIList.new({}), current_targets = {} }
	if card:isKindOf("BasicCard")
	then
		self:useBasicCard(card, dummy)
	elseif card:isKindOf("TrickCard")
	then
		self:useTrickCard(card, dummy)
	elseif card:isKindOf("EquipCard")
	then
		self:useEquipCard(card, dummy)
	end
	if dummy.card
	then
		return dummy
	end
	self:useCardByClassName(card, dummy)
	return dummy
end

sgs.ai_use_revises.luagudan = function(self, card, use)
	if card:isKindOf("EquipCard")
	then
		local same = self:getSameEquip(card)
		if same then
			return false
		end
	end
end

local luagudan_skill = {}
luagudan_skill.name = "luagudan"
table.insert(package_skills, luagudan_skill)
luagudan_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile("e")
	local equip_card
	self:sortByUseValueInPlace(cards, true)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive) then
			equip_card = card
			break
		end
	end
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("Slash") then
			equip_card = nil
		end
	end
	if equip_card then
		local suit = equip_card:getSuitString()
		local number = equip_card:getNumberString()
		local card_id = equip_card:getKnownEffectiveId()
		local card_str = ("slash:luagudan_dis[%s:%s]=%d"):format(suit, number, card_id)
		local slash = parse(self,request,card_str)
		assert(slash)
		return slash
	end

	if self.player:getHandcardNum() > 1 then
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if not c:isKindOf("Analeptic") then
				local dummy = self:aiUseCard(c)
				if dummy.card then
					return
				end
			end
		end
	end

	local slash=turn_normal(self,"luagudan_ex","slash",ids(self.player:getHandcards()),request)
	local dummy = self:aiUseCard(slash)
	if dummy.card and dummy.to then
		return slash
	end
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .."|luagudan"

function sgs.ai_cardneed.luagudan(to, card, self)
	return card:getTypeId() == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", true) == 0
end

ai_skill_invoke.luachunl = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	if damage.to and damage.to:hasSkill("luachunl") then
		if self:needToLoseHp(damage.to, damage.from, damage.card) then
			return (false) or false
		end
		return (true) or false
	elseif damage.from and damage.from:hasSkill("luachunl") then
		if self:isFriend(damage.to) then
			if self:needToLoseHp(damage.to, damage.from, damage.card) then
				return (false) or false
			end
			return (true) or false
		else
			if self:hasHeavyDamage(self.player, damage.card, damage.to) then return (false) or false end
			if self:isWeak(damage.to) then return (false) or false end
			if self:needToLoseHp(damage.to, damage.from, damage.card) then return (true) or false end
			if self:getDangerousCard(damage.to) then return (true) or false end
			return (false) or false
		end
	end
	return false

end


sgs.ai_skill_askforag["leo_luaboxue"] = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, disclosed(self,card_id))
	end
	self:sortByKeepValueInPlace(to_obtain)
	set_mark(self, "AI_leo_luaboxue1", 0)
	set_mark(self, "AI_leo_luaboxue2", 0)
	set_mark(self, "AI_leo_luaboxue3", 0)
	set_mark(self, "AI_leo_luaboxue" .. tostring(to_obtain[1]:getTypeId()), 1)
	return to_obtain[1]:getEffectiveId()
end

sgs.ai_card_priority.leo_luaboxue = function(self, card, v)
	if get_mark(self,"AI_leo_luaboxue"..tostring(card:getTypeId())) == 1
	then
		return 10
	end
end

sgs.ai_getBestHp_skill.luashenweiex1 = function(owner)
	return owner:getMaxHp() - 1
end



ai_skill_use["@@luafanfu"] = function(self, prompt, request)
	local cards = AIList.new(self.player:getCards("he"))

	self:sortByUseValueInPlace(cards)

	local players = AIList.new(self.room:getOtherPlayers(self.player))

	for _, player in ipairs(players) do
		if player:getKnownKingdom() == self.player:getKnownKingdom() then
			local slash = self:getEvaluationCard("slash")
			
			if self:isEnemy(player) and self:slashIsEffective(slash, player) and not self:slashProhibit(slash, player)
				and self:isGoodTarget(player, self.enemies, slash) then
				for _, card in ipairs(cards) do
					if not card:isKindOf("Peach") then
						return "#luafanfu:" .. card:getKnownEffectiveId() .. ":->" .. player:objectName()
					end
				end
			end
		end
	end
	for _, player in ipairs(players) do
		if player:getKnownKingdom() ~= self.player:getKnownKingdom() then
			if self:isFriend(player) and self:canDraw(player, self.player) then
				for _, card in ipairs(cards) do
					if not card:isKindOf("Peach") then
						return "#luafanfu:" .. card:getKnownEffectiveId() .. ":->" .. player:objectName()
					end
				end
			end
			local slash = self:getEvaluationCard("slash")
			
			if #self.friends_noself == 0 and self:isEnemy(player) and self:slashIsEffective(slash, player) and not self:slashProhibit(slash, player) then
				for _, card in ipairs(cards) do
					return "#luafanfu:" .. card:getKnownEffectiveId() .. ":->" .. player:objectName()
				end
			end
		end
	end
end

ai_skill_choice.luafanfu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local players = AIList.new(self.room:getOtherPlayers(self.player))
	local items = choices:split("+")
	for _, player in ipairs(players) do
		local slash = self:getEvaluationCard("slash")
		
		if self:isEnemy(player) and self:slashIsEffective(slash, player) and not self:slashProhibit(slash, player)
			and self:isGoodTarget(player, self.enemies, slash) and table.contains(items, player:getKnownKingdom()) then
			return ai_choice_result((player:getKnownKingdom()), options)
		end
	end
	return ai_choice_result((items[1]), options)
end

sgs.ai_ajustdamage_to.luataohui = function(self, from, to, card, nature)
	if from and from:getHp() > to:getHp() and nature == sgs.DamageStruct_Normal
	then
		return -99
	end
end




sgs.ai_skill_playerchosen["@luadushi1"] = function(self, targets)
	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and not lord:isKongcheng() then
		return lord
	end

	self:sortInPlace(self.enemies, "handcard")

	for _, p in ipairs(self.enemies) do
		if self:isWeak(p) and not p:isKongcheng() then
			return p
		end
	end
	for _, p in ipairs(self.enemies) do
		if not p:isKongcheng() then
			return p
		end
	end
end

sgs.ai_playerchosen_intention["@luadushi1"] = function(self, from, to)
	self:updateIntention(from, to, 50)
end

ai_skill_choice.luadushi = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local items = choices:split("+")
	local target = context_player(self,"leo_luadushi")
	if target and (self:getDangerousCard(target) or self:isFriend(target)) and table.contains(items, "luadushi1") then
		return ai_choice_result(("luadushi1"), options)
	end

	return ai_choice_result(("luadushi2"), options)
end




ai_skill_invoke["luayijue_xianfu"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getKnownRole() == "loyalist" then
		return (true) or false
	end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:getKnownRole() == role(self,p) then
			return (true) or false
		end
	end
	return (false) or false
end



sgs.ai_skill_playerchosen.luayijue = function(self, targets)
	if self.player:getKnownRole() == "loyalist" or self.player:getKnownRole() == "renegade" then
		return self.room:getLord()
	end

	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:getKnownRole() == role(self,p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.luayijue = function(self, from, to)
	self:updateIntention(from, to, -80)
end



ai_skill_invoke["luayijue"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local pattern = data:toStringList()[1]
	local tied
	if pattern == "jink" then
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:getMark("luayijue_use") > 0 then
				tied = player
				break
			end
		end
		if self:hasEightDiagramEffect(tied) then return (true) or false end
		return (self:getCardsNum("Jink") == 0) or false
	elseif pattern == "slash" then
		local asked = data:toStringList()
		local prompt = asked[2]
		if self:askForCard("slash", prompt, 1) == "." then return (false) or false end
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:getMark("luayijue_use") > 0 then
				tied = player
				break
			end
		end
		if tied and tied:getPhase() ~= sgs.Player_NotActive
			and self:isFriend(tied) and self:getOverflow(tied) > 2 and not self:hasCrossbowEffect(tied) then
			return (true) or false
		end

		local cards = self.player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if self:isCard("Slash", card, self.player) then
				return (false) or false
			end
		end
		return (tied and self:isFriend(tied)) or false
	end
	return false

end

sgs.ai_skill_cardask["luayijuejink"] = function(self)
	local players = self.room:getOtherPlayers(self.player)
	local target
	for _, p in sgs.qlist(players) do
		if p:getMark("@luayijue") > 0 then
			target = p
			break
		end
	end
	if not self:isFriend(target) then return "." end
	return self:getCardId("Jink") or "."
end


sgs.ai_skill_cardask["luayijueslash"] = function(self)
	local players = self.room:getOtherPlayers(self.player)
	local target
	for _, p in sgs.qlist(players) do
		if p:getMark("@luayijue") > 0 then
			target = p
			break
		end
	end
	if not self:isFriend(target) then return "." end
	return self:getCardId("Slash") or "."
end



sgs.ai_skill_cardask["luayijuepeach"] = function(self)
	local players = self.room:getOtherPlayers(self.player)
	local target
	for _, p in sgs.qlist(players) do
		if p:getMark("@luayijue") > 0 then
			target = p
			break
		end
	end
	if not self:isFriend(target) then return "." end
	return self:getCardId("Peach") or "."
end

sgs.ai_cardneed.luazhiyong = function(to, card, self)
	return card and card:getSuit() == sgs.Card_Heart
end

sgs.luazhiyong_suit_value = {
	heart = 6,
}

sgs.ai_card_priority.luazhiyong = function(self,card)
	if table.contains(card:getSkillNames(), "luazhiyong")
	then
		if self.player:getPhase() ==sgs.Player_NotActive
		then return 1 end
		return 0.08
	end
end

sgs.ai_use_revises.luazhiyong = function(self,card,use)
	if card:isKindOf("EquipCard")
	and card:getSuit() == sgs.Card_Heart
	then
		local same = self:getSameEquip(card)
		if same and same:getSuit() == sgs.Card_Heart
		then return false end
	end
end

local luazhiyong_skill = {}
luazhiyong_skill.name = "luazhiyong"
table.insert(package_skills, luazhiyong_skill)
luazhiyong_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")
	local handcards = AIList.new(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(handcards, disclosed(self,id))
		end
	end
	self:sortByUseValueInPlace(handcards, true)
	local equipments = AIList.new(self.player:getCards("e"))
	self:sortByUseValueInPlace(equipments, true)
	local basic_cards = {}
	local basic_cards_count = 0
	local use_cards = {}



	for _, c in ipairs(handcards) do
		if not c:isKindOf("Peach") then
			if c:getSuit() == sgs.Card_Heart then
				basic_cards_count = basic_cards_count + 1
				table.insert(basic_cards, c:getKnownEffectiveId())
			end
		end
	end

	if self:getOverflow() <= 0 then return end


	if #basic_cards > 0 then
		table.insert(use_cards, basic_cards[1])
	end
	if #use_cards == 0 then return end


	if self.player:isWounded() then
		return parse(self,request,"#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "peach")
	end

	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and self:isGoodTarget(enemy, self.enemies) and self.player:inMyAttackRange(enemy) then
			local thunder_slash = self:getEvaluationCard("thunder_slash")
			
			local fire_slash = self:getEvaluationCard("fire_slash")
			
			local slash = self:getEvaluationCard("slash")
			
			if not self:slashProhibit(fire_slash, enemy, self.player) and self:slashIsEffective(fire_slash, enemy, self.player) then
				return parse(self,request,"#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "fire_slash")
			end
			if not self:slashProhibit(thunder_slash, enemy, self.player) and self:slashIsEffective(thunder_slash, enemy, self.player) then
				return parse(self,request,"#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "thunder_slash")
			end
			if not self:slashProhibit(slash, enemy, self.player) and self:slashIsEffective(slash, enemy, self.player) then
				return parse(self,request,"#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "slash")
			end
		end
	end
end

ai_card_use["#luazhiyong"] = function(self, card, use, request)
	local userstring=card:getLegacyStringKey():split(":")[4]
	local xin_zhayi_jibencard=owner_eval(self,"luazhiyong",userstring,{},card:getSuit(),card:getNumber())
	self:useBasicCard(xin_zhayi_jibencard, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["luazhiyong"] = 3
sgs.ai_use_value["luazhiyong"] = 3

sgs.ai_view_as["luazhiyong"] = function(card, player, card_place, class_name)
	local classname2objectname = {
		["Slash"] = "slash",
		["Jink"] = "jink",
		["Peach"] = "peach",
		["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash",
		["ThunderSlash"] = "thunder_slash"
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local no_have = true
	if not player then return end
	local cards = player:getCards("h")
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			cards:prepend(own_card(player,id))
		end
	end
	for _, c in sgs.qlist(cards) do
		if c:isKindOf(class_name) then
			no_have = false
			break
		end
	end
	if not no_have then return end

	local handcards = AIList.new(player:getCards("h"))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(handcards, own_card(player,id))
		end
	end
	local basic_cards = {}
	local use_cards = {}


	for _, c in ipairs(handcards) do
		if not c:isKindOf("Peach") then
			if c:getSuit() == sgs.Card_Heart then
				table.insert(basic_cards, c:getKnownEffectiveId())
			end
		end
	end


	if #basic_cards > 0 then
		table.insert(use_cards, basic_cards[1])
	end
	if #use_cards == 0 then return end
	return material(own_card(player,use_cards[1]),name,"luazhiyong")
end

function sgs.ai_cardsview_valuable.luayijuedest(self, class_name, player)
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
	if not name then return end
	if player:getPhase() ~= sgs.Player_NotActive then return end
	if class_name == "Peach" and known(self.request.reason,"request reason") ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	if player:hasFlag("Global_luayijueFailed") then return end
	if player:hasFlag("Global_luayijueFailed_AI") then return end
	local guanyu = self.room:findPlayerBySkillName("luayijue")
	if guanyu then return {skill="luayijuedest&",legacy_class="#luayijuedestCard",subcards={},user_string=name} end
end

sgs.ai_skill_cardask["@@luayijue"] = function(self, data, pattern)
    local target = data:toPlayer()
    if target and self:isFriend(target) then
        local cards = self.player:getCards("he")
        cards = AIList.new(cards)
        self:sortByKeepValueInPlace(cards)
        for _,h in sgs.list(cards)do
            if self:matchesDiscardPattern(h, pattern)
            then return h:getKnownEffectiveId() end
            if h:isKindOf(pattern)
            then return h:getKnownEffectiveId() end
        end
        return self:getCardId(pattern)
    end
    return "."
end



sgs.ai_skill_askforag["luaweiwo1"] = function(self,card_ids)
	local cards={};for _,id in ipairs(card_ids)do cards[#cards+1]=disclosed(self,id)end
	self:sortByUseValueInPlace(cards, true)
	return cards[1]:getId()
end
sgs.ai_skill_playerchosen["@luaspbazhen1"] = function(self, targets)
    targets = AIList.new(targets)
	self:sortInPlace(targets, "defense")
    for _,target in ipairs(targets) do
        if self:doDisCard(target, "he", true) then
            return target
        end
    end
    return targets[1]
end

ai_skill_use["@@luaspbazhen"] = function(self, prompt, request)
	local method = request and request.handling_method
	local use_card=owner_eval(self,"luaspbazhen","IronChain",{},sgs.Card_NoSuit,-1)
	local dummy_use = self:aiUseCard(use_card, dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return normal_response(self,use_card,"luabazhen_viewas",targets)
		end
	end
	return "."
end



sgs.ai_skill_playerchosen["@luaspbazhen3"] = function(self, targets)
    return self.player
end


sgs.ai_skill_playerchosen["@luaspbazhen4"] = function(self, targets)
    targets = AIList.new(targets)
	self:sortInPlace(targets, "defense")
	local fire_attack=owner_eval(self,"luaspbazhen","fire_attack",{},sgs.Card_NoSuit,0)
    
    local dummy_use = self:aiUseCard(fire_attack, dummy())
    if dummy_use.card and not dummy_use.to:isEmpty() then
        for _, p in sgs.qlist(dummy_use.to) do
            if table.contains(targets, p) then
                return p
            end
        end
    end
	return targets[1]
end

sgs.ai_hasTuntianEffect_skill.luaspbazhen = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive
end

sgs.ai_skill_askforag["newluaweiwo"] = function(self, card_ids)
	local judge = context_value(self,"leo_newluaweiwo_judge")
    if judge then
        local copy={};for k,v in pairs(judge)do copy[k]=v end
        copy.who=known(self.room:findPlayerByObjectName(judge.who,true),'newluaweiwo judge owner')
        copy.card=type(judge.card)=='table'and next(judge.card)~=nil and CardView.new(judge.card)or nil
        judge=copy
    end
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, disclosed(self,card_id))
	end
	
	if judge then
		local x = math.min(self.player:getHp(), 3) - self.player:getMark("newluaweiwo")
		if x > 0 then
			self:sortByKeepValueInPlace(to_obtain, true)
			return to_obtain[1]:getEffectiveId()
		else
			local card_id = self:getRetrialCardId(to_obtain, judge)
			if card_id ~= -1 then
				return "$" .. card_id
			end
		end
	end
	self:sortByKeepValueInPlace(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end
sgs.ai_skill_playerchosen["luajincui"] = function(self, targets)
	return self.player
end
sgs.ai_playerchosen_intention.luajincui = -50


ai_skill_choice.luajincui = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	for _,friend in ipairs(self.friends)do
		if friend:hasSkill("tianxiang") and (self.player:getHp()>=3 or (self:getCardsNum("Peach")+self:getCardsNum("Analeptic")>0 and self.player:getHp()>1)) then
			return ai_choice_result(("luajincui1"), options)
		end
	end
	if self.player:getMaxHp()>=self.player:getHp()+2 then
		if self.player:getMaxHp()>5 and (self.player:hasSkills("nosmiji|yinghun|juejing|zaiqi|nosshangshi") or self.player:hasSkill("miji") and self:findPlayerToDraw(false)) then
			local enemy_num = 0
			for _,p in ipairs(self.enemies)do
				if p:inMyAttackRange(self.player) and not self:willSkipPlayPhase(p) then enemy_num = enemy_num+1 end
			end
			local ls = self:getStrategyMemory("fangquan_effect") and self.room:findPlayerBySkillName("fangquan")
			if ls then
				self:setStrategyMemory("fangquan_effect", false)
				enemy_num = self:getEnemyNumBySeat(ls, self.player, self.player)
			end
			local least_hp = isLord(self.player) and math.max(2,enemy_num-1) or 1
			if (self:getCardsNum("Peach")+self:getCardsNum("Analeptic")+self.player:getHp()>least_hp) then return ai_choice_result(("luajincui1"), options) end
		end
		return ai_choice_result(("luajincui2"), options)
	else
		return ai_choice_result(("luajincui1"), options)
	end

    return ai_choice_result(nil, options)
end

sgs.ai_canNiepan_skill.luatianming = function(player)
	return player:getMark("@RX") >= 7 and player:getMark("luatianming") == 0
end



do local source=ai_skill_use["@@luaqingqi"];ai_skill_use["@@luaqingqi"]=function(self, prompt, request)return response_wire(self,source(self,prompt, request))end end

do local source=ai_skill_use["@@luazhuixi"];ai_skill_use["@@luazhuixi"]=function(self, prompt, request)return response_wire(self,source(self,prompt, request))end end

do local source=ai_skill_use["@@luayonglue"];ai_skill_use["@@luayonglue"]=function(self, prompt, request)return response_wire(self,source(self,prompt, request))end end

do local source=ai_skill_use["@@luafuwei"];ai_skill_use["@@luafuwei"]=function(self, prompt, request)return response_wire(self,source(self,prompt, request))end end

do local source=ai_skill_use["@@luafanfu"];ai_skill_use["@@luafanfu"]=function(self, prompt, request)return response_wire(self,source(self,prompt, request))end end

for _,skill in ipairs(package_skills)do ai_fill_skill[skill.name]=skill.getTurnUseCard end
