-- Fixed leo-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("leo policy input is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("leo policy helper unavailable",method) end
    local result=table.pack(object[method](object,...))
    if AIUnsupported.is(result[1]) then error(result[1],0) end
    return table.unpack(result,1,result.n)
end
local function q(object,method,...)
    local value=call(object,method,...)
    if value==false and (method=="hasSkill"or method=="hasSkills"or method=="hasLordSkill")and AIValue.isPlayer(object)then
        local row=rawget(object,"_view")
        if row and row.skills_complete~=true then ai_unsupported("foreign skill absence is unknown",(...))end
    end
    return known(value,method)
end
local function sorted(self,cards,method,...)
    local result=q(self,method,cards,...)
    for i,c in ipairs(result) do cards[i]=c end
    return cards
end
local function sort_players(self,cards,...) return sorted(self,cards,"sort",...) end
local function sort_use(self,cards,...) return sorted(self,cards,"sortByUseValue",...) end
local function sort_keep(self,cards,...) return sorted(self,cards,"sortByKeepValue",...) end
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return q(self,"legacySkillSeed",skill,class,action_request(self,request)) end
local skill_cards={['#luajuesii']='luajuesii',['#luatuxiex_card']='luatuxiex',['#luaqingqi_card']='luaqingqi',['#luayuanlue']='luayuanlue',['#luazhuixi']='luazhuixi',['#luayonglue']='luayonglue',['#luafuweicard']='luafuwei',['#luajieyicard']='luajieyi',['#luashanquan']='luashanquan',['#luafanfu']='luafanfu',['#luazhiyong']='luazhiyong'}
local names={slash='Slash',jink='Jink',peach='Peach',analeptic='Analeptic',fire_slash='FireSlash',thunder_slash='ThunderSlash',duel='Duel',iron_chain='IronChain'}
local function ids(cards)local out={};for _,card in ipairs(cards)do out[#out+1]=type(card)=='number'and card or q(card,'getEffectiveId')end;return out end
local function own_card(player,id)
 for _,group in ipairs({q(player,'getCards','he'),q(player,'getHandPileCards')})do for _,card in ipairs(group)do if q(card,'getEffectiveId')==id then return card end end end
 ai_unsupported('source card face is not owner-disclosed',tostring(id))
end
local function disclosed(self,id)return known(self:getKnownCardById(id)or self:getChoiceCard(id),'leo source card '..tostring(id))end
local function material(card,name,skill)return{name=name,skill=skill,suit=q(card,'getSuit'),number=q(card,'getNumber'),subcards={q(card,'getEffectiveId')}}end
local function aggregate(cards)
 local suit,number=sgs.Card_NoSuit,0
 if #cards==1 then return q(cards[1],'getSuit'),q(cards[1],'getNumber')end
 if #cards>1 then local red,black=true,true;for _,card in ipairs(cards)do red=red and q(card,'isRed');black=black and q(card,'isBlack')end;suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit end
 return suit,number
end
local function normal_spec(self,skill,name,costs)
 local cards={};for _,id in ipairs(ids(costs))do cards[#cards+1]=disclosed(self,id)end
 local suit,number=aggregate(cards);return{name=name,skill=skill,suit=suit,number=number,subcards=ids(cards)}
end
local function turn_normal(self,skill,name,costs,request)
 return q(self,'evaluateTurnConversion',skill,names[name]or q(q(self,'getEvaluationCard',name),'getClassName'),normal_spec(self,skill,name,costs),action_request(self,request))
end
local function owner_eval(self,skill,name,costs,suit,number)
 return q(self,'evaluateOwnerViewAsCard',{source_key=skill,skill=skill,name=name,suit=suit,number=number,subcards=costs})
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
  return q(self,'evaluateTurnSkillCard',skill,class,costs,action_request(self,request),user)
 end
 local name,skill,id=wire:match('^([^:]+):([^%[]+)%[[^%]]+%]=(%d+)$')
 if not name then ai_unsupported('unrecognized source card grammar',wire)end
 return q(self,'evaluateTurnConversion',skill,names[name]or q(q(self,'getEvaluationCard',name),'getClassName'),material(disclosed(self,tonumber(id)),name,skill),action_request(self,request))
end
local function final_parse(self,request,wire)
 local class,costs,user=wire_parts(wire)
 return q(self,'bindSkillCard',known(skill_cards[class],class),costs,action_request(self,request),user,class)
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
 local spec={name=q(card,'objectName'),skill='luaspbazhen',suit=q(card,'getSuit'),number=q(card,'getNumber'),subcards={}}
 local use=AIUsePlan.new();use.card=q(self,'bindOriginalSelectedConversion',spec,q(card,'getClassName'),skill);use.to=AIList.new{}
 for _,name in ipairs(targets)do use.to:append(known(self.room:findPlayerByObjectName(name),'response target'))end
 return use:toAnswer()
end
local function dummy()local use=AIUsePlan.new();use.isDummy=true;return use end
local function no_distance_use(self,slash,source)return q(self,'withOwnerRange','slashNoDistanceLimit',source,function()return q(self,'aiUseCard',slash)end)end
local function role_count(self,name)local policy=self.world.mode_policy;return known(policy and policy.role_counts and policy.role_counts[name],'role count '..name)end
local function role(self,player)
 local value=call(player,'getRole');if value~=nil then return value end
 return q(self,'useKnowledgeEstimate',{status='estimate',value=q(self,'getRoleEstimate',player),basis='viewer_role_estimate_private_role',player=q(player,'objectName')},'leo.role')
end
local function context_value(self,key)local context=q(self,'getDecisionContext');local value=known(context[key],key);if value==false then return nil end;return value end
local function context_player(self,key)local name=context_value(self,key);if name==nil then return nil end;return known(self.room:findPlayerByObjectName(name),key)end
local function public_flag(self,player,name)
 -- Player flags are broadcast and projected for every player.
 return q(player,"hasFlag",name)
end
local function source_visible_hand(self,player)
 -- Known hand cards that carry a visibility flag toward this viewer, in hand order.
 local flag=string.format("visible_%s_%s",q(self.player,'objectName'),q(player,'objectName'));local cards={}
 for _,c in ipairs(q(player,'getKnownCards'))do
  if q(c,'hasFlag','visible') or q(c,'hasFlag',flag) then cards[#cards+1]=c end
 end
 return cards
end
local function first_hand(self,player)
 if q(player,'objectName')==q(self.player,'objectName')then return q(player,'getHandcards')[1]end
 if call(player,'isHandVisible')==true then local cards=q(player,'getKnownCards');if #cards==q(player,'getHandcardNum')then return cards[1]end end
 ai_unsupported('luaqingqi original first-hand selection requires a scoped opaque card choice','luaqingqi.first_hand')
end
local function set_mark(self,name,value)call(self,'setStrategyMemory','leo.mark:'..name,value)end
local function get_mark(self,name)local value,known_memory=self:getStrategyMemory('leo.mark:'..name);if known_memory then return known(value,name)end;return q(self.player,'getMark',name)end
local function kingdoms(player)
 local result={[q(player,'getKingdom')]=true};for _,other in ipairs(q(q(player,'getRoom'),'getOtherPlayers',player))do result[q(other,'getKingdom')]=true end
 local n=0;for _ in pairs(result)do n=n+1 end;return n
end
local function sort_need(self,cards,...)return sorted(self,cards,'sortByCardNeed',...)end
local luajuesii_skill = {}
luajuesii_skill.name = "luajuesii"
table.insert(package_skills, luajuesii_skill)
luajuesii_skill.getTurnUseCard=function(self,inclusive,request)
	local target
	local duel = q(self,"getEvaluationCard","duel")
	
	local dummy = q(self,"aiUseCard",duel)
	if dummy.card and dummy.to
		then
		for _,enemy in sgs.list(dummy.to)do
			target = enemy
			break
		end
	end
		
	if not q(self.player,"isWounded") then return end

	local losthp = isLord(self.player) and 0 or 1
	if ((q(self.player,"getHp") > 3 and q(self.player,"getLostHp") <= losthp)
			or (q(self.player,"getHp") - q(self.player,"getHandcardNum") >= 2)) and target and not (isLord(self.player) and q(self.room,"getTurnCount") <= 1) then
		return parse(self,request,"#luajuesii:.:")
	end
	if q(self.player,"getHp") == 1 and q(self,"getCardsNum","Analeptic") >= 1 then
		return parse(self,request,"#luajuesii:.:")
	end

	--Suicide by NosKurou
	local nextplayer = q(self.player,"getNextAlive")
	if q(self.player,"getHp") == 1 and q(self.player,"getRole") ~= "lord" and q(self.player,"getRole") ~= "renegade" then
		local to_death = false
		if q(self,"isFriend",nextplayer) then
			for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
				if q(p,"hasSkill","xiaoguo") and not q(self,"isFriend",p) and not q(p,"isKongcheng")
					and self.role == "rebel" and q(self.player,"getEquips"):isEmpty() then
					to_death = true
					break
				end
			end
			if not to_death and not q(self,"willSkipPlayPhase",nextplayer) then
				if q(nextplayer,"hasSkill","jieyin") and q(self.player,"isMale") then return end
				if q(nextplayer,"hasSkill","qingnang") then return end
			end
		end
		if q(self.player,"getRole") == "rebel" and not q(self,"isFriend",nextplayer) then
			if not q(self,"willSkipPlayPhase",nextplayer) or q(nextplayer,"hasSkill","shensu") then
				to_death = true
			end
		end
		local lord = call(self.room,"getLord")
		if q(self.player,"getRole") == "loyalist" then
			if lord and q(lord,"getCards","he"):isEmpty() then return end
			if q(self,"isEnemy",nextplayer) and not q(self,"willSkipPlayPhase",nextplayer) then
				if q(nextplayer,"hasSkills","noslijian|lijian") and q(self.player,"isMale") and lord and q(lord,"isMale") then
					to_death = true
				elseif q(nextplayer,"hasSkill","quhu") and lord and q(lord,"getHp") > q(nextplayer,"getHp") and not q(lord,"isKongcheng")
					and q(lord,"inMyAttackRange",self.player) then
					to_death = true
				end
			end
		end
		if to_death then
			local caopi = call(self.room,"findPlayerBySkillName","xingshang")
			if caopi and q(self,"isEnemy",caopi) then
				if q(self.player,"getRole") == "rebel" and q(self.player,"getHandcardNum") > 3 then to_death = false end
				if q(self.player,"getRole") == "loyalist" and lord and q(lord,"getCardCount",true) + 2 <= q(self.player,"getHandcardNum") then
					to_death = false
				end
			end
			if #self.friends == 1 and #self.enemies == 1 and q(self.player,"aliveCount") == 2 then to_death = false end
		end
		if to_death then
			call(self,"setStrategyPlayerFlag",self.player,"NosKurou_toDie",true)
			return parse(self,request,"#luajuesii:.:")
		end
		call(self,"setStrategyPlayerFlag",self.player,"NosKurou_toDie",false)
	end
end

sgs.ai_skill_use_func["#luajuesii"] = function(card,use,self,request)
	local target
	local duel = q(self,"getEvaluationCard","duel")
	
	local dummy = q(self,"aiUseCard",duel)
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
			call(use.to,"append",target)
		end
	end
end



sgs.ai_skill_choice.luajuesii = function(self, choices, data)
	if q(self,"hasZhaxiangEffect",self.player) and q(self,"getAllPeachNum") + q(self.player,"getHp") > 0 then return "luajuesii2" end
	for _, friend in ipairs(self.friends) do
		if q(friend,"hasSkills","tianxiang|ol_tianxiang") and (q(self.player,"getHp") >= 3 or (q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") > 0 and q(self.player,"getHp") > 1)) then
			return "luajuesii2"
		end
	end
	if q(self.player,"getMaxHp") >= q(self.player,"getHp") + 2 then
		if q(self.player,"getMaxHp") > 5 and (q(self.player,"hasSkills","nosmiji|yinghun|juejing|zaiqi|nosshangshi") or q(self.player,"hasSkill","miji") and call(self,"findPlayerToDraw",false) or q(self.player,"hasSkills",sgs.need_maxhp_skill)) then
			local enemy_num = 0
			for _, p in ipairs(self.enemies) do
				if q(p,"inMyAttackRange",self.player) and not q(self,"willSkipPlayPhase",p) then enemy_num = enemy_num + 1 end
			end
			local ls = call(self,"getStrategyMemory","fangquan_effect") and call(self.room,"findPlayerBySkillName","fangquan")
			if ls then
				call(self,"setStrategyMemory","fangquan_effect",false)
				enemy_num = q(self,"getEnemyNumBySeat",ls, self.player, self.player)
			end
			local least_hp = isLord(self.player) and math.max(2, enemy_num - 1) or 1
			if (q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") + q(self.player,"getHp") > least_hp) then
				return
				"luajuesii2"
			end
		end
		return "luajuesii1"
	else
		return "luajuesii2"
	end
end



sgs.ai_use_priority["luajuesii"] = 6.8



local function select_tuxi(self,prompt)
	sort_players(self,self.enemies, "handcard_defense")
	local tuxi_mark = 1
	local targets = {}

	local add_player = function(player, isfriend)
		if q(player,"getHandcardNum") == 0 or q(player,"objectName") == q(self.player,"objectName") then return #targets end
		if q(self,"objectiveLevel",player) == 0 and q(player,"isLord") and role_count(self,"rebel") > 1 then return #targets end

		local f = false
		for _, c in ipairs(targets) do
			if c == q(player,"objectName") then
				f = true
				break
			end
		end

		if not f then table.insert(targets, q(player,"objectName")) end

		if isfriend and isfriend == 1 then
			call(self,"setStrategyPlayerFlag",self.player,"tuxi_isfriend_"..q(player,"objectName"),true)
		end
		return #targets
	end

	local parseTuxiCard = function()
		if #targets == 0 then return "." end
		local s = table.concat(targets, "+")
		return "#luatuxiex_card:.:->" .. s
	end

	local lord = call(self.room,"getLord")
	if lord and q(self,"isEnemy",lord) and q(self.room,"getTurnCount") <= 1 and not q(lord,"isKongcheng") then
		if add_player(lord) == tuxi_mark then return parseTuxiCard() end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local cards = source_visible_hand(self,p)
		local flag = string.format("%s_%s_%s", "visible", q(self.player,"objectName"), q(p,"objectName"))
		for _, card in ipairs(cards) do
			if true and (q(card,"isKindOf","Peach") or q(card,"isKindOf","Nullification") or q(card,"isKindOf","Analeptic")) then
				if add_player(p) == tuxi_mark then return parseTuxiCard() end
			end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		if q(p,"hasSkills","jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
			if add_player(p) == tuxi_mark then return parseTuxiCard() end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local x = q(p,"getHandcardNum")
		local good_target = true
		if x == 1 and q(self,"needKongcheng",p) then good_target = false end
		if x >= 2 and q(self,"hasTuntianEffect",p, true) then good_target = false end
		if good_target and add_player(p) == tuxi_mark then return parseTuxiCard() end
	end


	local others = q(self.room,"getOtherPlayers",self.player)
	for _, other in sgs.qlist(others) do
		if q(self,"objectiveLevel",other) >= 0 and not (q(self,"hasTuntianEffect",other, true)) and add_player(other) == tuxi_mark then
			return parseTuxiCard()
		end
	end

	for _, other in sgs.qlist(others) do
		if q(self,"objectiveLevel",other) >= 0 and not (q(self,"hasTuntianEffect",other, true)) and math.random(0, 5) <= 1 and not q(self,"hasSkills","qiaobian") then
			add_player(other)
		end
	end

	return parseTuxiCard()
end

sgs.ai_skill_invoke.luatuxiex=function(self,data)local wire=select_tuxi(self,"@luatuxiex");return call(wire,"match","->")~=nil end
sgs.ai_skill_use["@@luatuxiex"]=function(self,prompt)return response_wire(self,select_tuxi(self,prompt))end
sgs.ai_card_intention["luatuxiex"] = function(self, card, from, tos)
	local lord = call(self.room,"getLord")
	local tuxi_lord = false
	if q(self,"getRoleEstimate",from) == "neutral" and q(self,"getRoleEstimate",tos[1]) == "neutral" and
		(not tos[2] or q(self,"getRoleEstimate",tos[2]) == "neutral") and lord and not q(lord,"isKongcheng") and
		not (q(self,"needKongcheng",lord) and q(lord,"getHandcardNum") == 1) and
		q(self,"hasLoseHandcardEffective",lord) and not (q(self,"hasTuntianEffect",lord, true)) and q(from,"aliveCount") >= 4 then
		call(self,"updateIntention",from, lord, -80)
		return
	end
	if q(from,"getState") == "online" then
		for _, to in ipairs(tos) do
			if q(self,"needKongcheng",to)
				or (q(self,"hasTuntianEffect",to, true)) then
			else
				call(self,"updateIntention",from, to, 80)
			end
		end
	else
		for _, to in ipairs(tos) do
			if lord and q(to,"objectName") == q(lord,"objectName") then tuxi_lord = true end
			local intention = q(self,"hasStrategyPlayerFlag",from,"tuxi_isfriend_"..q(to,"objectName")) and -5 or 80
			call(self,"updateIntention",from, to, intention)
		end
		if q(self.room,"getTurnCount") == 1 and not tuxi_lord and lord and not q(lord,"isKongcheng") and q(from,"getRoom"):alivePlayerCount() > 2 then
			call(self,"updateIntention",from, lord, -80)
		end
	end
end
sgs.drawpeach_skill = sgs.drawpeach_skill .. "|luatuxiex"




sgs.ai_skill_choice["luaqingqi"] = function(self, choices, data)
	local items = q(choices,"split","+")
	local target = call(data,"toPlayer")
	if target then
		local slash = q(self,"getEvaluationCard","slash")
		
		if q(self,"isFriend",target) then
			local judges = q(target,"getJudgingArea")
			if not q(judges,"isEmpty") then
				for _, judge in sgs.qlist(judges) do
					if not q(judge,"isKindOf","YanxiaoCard") then
						return "luaqingqi2"
					end
				end
			else
				if q(self.player,"canSlash",target, slash) and not q(self,"slashProhibit",slash, target)
					and q(self,"slashIsEffective",slash, target) and q(self,"needToLoseHp",target, self.player, slash) then
					return "luaqingqi1"
				end
			end
		else
			if q(self.player,"canSlash",target, slash) and not q(self,"slashProhibit",slash, target)
				and q(self,"slashIsEffective",slash, target) and q(self,"isGoodTarget",target, self.enemies, slash) then
				return "luaqingqi1"
			else
				return "luaqingqi2"
			end
		end
	end
	return "cancel"
end

sgs.ai_skill_use["@@luaqingqi"] = function(self, prompt)
	sort_players(self,self.enemies, "handcard_defense")
	local targets = {}
	local slash = q(self,"getEvaluationCard","slash")

	
	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"inMyAttackRange",enemy) then
			if q(self,"slashIsEffective",slash, enemy) and not q(self,"slashProhibit",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash) then
				return "#luaqingqi_card:.:->" .. q(enemy,"objectName")
			end
		end
	end
	for _, friend in ipairs(self.friends) do
		local judges = q(friend,"getJudgingArea")
		if not q(judges,"isEmpty") then
			for _, judge in sgs.qlist(judges) do
				if not q(judge,"isKindOf","YanxiaoCard") then
					return "#luaqingqi_card:.:->" .. q(friend,"objectName")
				end
			end
		end
	end
end




sgs.ai_skill_cardchosen["luaqingqi"] = function(self, who, flags)
	local equipments = AIList.new(q(who,"getEquips"))
	equipments = sgs.reverse(equipments)
	-- Source first-hand is resolved only if the branch consumes it.
	if q(self,"isFriend",who) then
		--SmartAI:askForCardChosen的判定區檢測
		if call(flags,"match","j") and not q(who,"containsTrick","YanxiaoCard") and not (q(who,"hasSkill","qiaobian") and q(who,"getHandcardNum") > 0) then
			local tricks = q(who,"getCards","j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if q(trick,"isKindOf","Lightning") then
					lightning = q(trick,"getEffectiveId")
				elseif q(trick,"isKindOf","Indulgence") then
					indulgence = q(trick,"getEffectiveId")
				elseif not q(trick,"isKindOf","Disaster") then
					supply_shortage = q(trick,"getEffectiveId")
				end
			end

			if q(self,"hasWizard",self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if q(who,"getHp") < q(who,"getHandcardNum") then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end

		if q(who,"getPile","wooden_ox"):length() > 0 then
			for _, e in ipairs(equipments) do
				if q(e,"isKindOf","WoodenOx") then
					table.removeOne(equipments, e)
				end
			end
		end

		if q(who,"hasArmorEffect","silver_lion") and q(who,"isWounded") then
			return call(who,"getArmor")
		end
		if q(who,"getEquips"):length() > 0 then
			if q(who,"getHandcardNum") > 2 or (q(who,"getHandcardNum") > 0 and q(who,"getPile","wooden_ox"):length() > 0) then
				return first_hand(self,who)
			else
				return equipments[1]
			end
		end
	end
	return nil
end





sgs.ai_skill_invoke.feijiangts = function(self, data)
	local target = call(data,"toPlayer")
	if not target then
		return true
	end
	if q(self,"isFriend",target) then
		if q(self,"needKongcheng",target) and q(target,"getHandcardNum") == 1 then return true end
		if q(self,"getOverflow",target) > 2 then return true end
		return false
	else
		return not (q(self,"needKongcheng",target) and q(target,"getHandcardNum") == 1)
	end
end

sgs.ai_choicemade_filter.skillInvoke.feijiangts = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",player)) do
		if public_flag(self,p,"feijiangtsTarget") then
			target = p
			break
		end
	end
	if target then
		local intention = 60
		if promptlist[#promptlist] == "yes" then
			if not q(self,"hasLoseHandcardEffective",target) or (q(self,"needKongcheng",target) and q(target,"getHandcardNum") == 1) then
				intention = 0
			end
			if q(self,"getOverflow",target) > 2 then intention = 0 end
			call(self,"updateIntention",player, target, intention)
		else
			if q(self,"needKongcheng",target) and q(target,"getHandcardNum") == 1 then intention = 0 end
			call(self,"updateIntention",player, target, -intention)
		end
	end
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.feijiangts",registry="ai_choicemade_filter",path={"cardChosen","feijiangts"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}

sgs.double_slash_skill = sgs.double_slash_skill .."|xinwushuang"
xinwushuang_skill = { name = "xinwushuang" }
table.insert(package_skills, xinwushuang_skill)
xinwushuang_skill.getTurnUseCard=function(self,inclusive,request)
	call(self,"updatePlayers")
	local has_weak_enemy = false
	for _, enemy in ipairs(self.enemies) do
		if q(self,"isWeak",enemy) then
			has_weak_enemy = true
		end
	end
	if (q(self.player,"isKongcheng")) then return end
	if (q(self.player,"getMark","xinwushuang-SelfPlayClear") > 0 ) then return end
	local cards = q(self.player,"getCards","h")
	cards = AIList.new(cards)

	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end
	local use_cards = {}
	local x = 0
	local duel = q(self,"getEvaluationCard","duel")
	for _, enemy in ipairs(self.enemies) do
		if q(self,"hasTrickEffective",duel, enemy, self.player) and q(self,"canAttack",enemy, self.player) and
			q(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, enemy) then
			x = x + 1
		end
	end

	if q(self.player,"getHandcardNum") > 1 then
		sort_use(self,cards, true)
		for _, acard in ipairs(cards) do
			if not (q(acard,"isKindOf","Peach")) and (q(self,"getDynamicUsePriority",acard) < sgs.ai_use_value.Duel) and (x > #use_cards) then
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
	local duel = q(data,"toCardEffect").card
	if q(self.player,"getPhase") == sgs.Player_Play then return call(self,"getCardId","Slash") end

	if call(self,"standardNullFilter", data, pattern, target) then return "." end

	--有大傷害全部殺都丟出去
	if q(self,"hasHeavyDamage",target, duel, self.player) then return call(self,"getCardId","Slash") end

	if q(self.player,"hasFlag","AIGlobal_NeedToWake") and q(self.player,"getHp") > 1 then return "." end
	if (q(target,"hasSkill","wuyan") or q(self.player,"hasSkill","wuyan")) and not q(target,"hasSkill","jueqing") then return "." end
	if q(self.player,"getMark","@fenyong") > 0 and q(self.player,"hasSkill","fenyong") and not q(target,"hasSkill","jueqing") then
		return
		"."
	end
	if q(self.player,"hasSkill","wuhun") and q(self,"isEnemy",target) and q(target,"isLord") and #self.friends_noself > 0 then
		return
		"."
	end

	--排除司馬徽隱士技能，AI司馬徽被打
	if target and q(self.player,"hasSkill","yinshi") and not q(target,"hasSkill","jueqing") and q(self.player,"getMark","@dragon") + q(self.player,"getMark","@phoenix") == 0 and not call(self.player,"getArmor") then
		return
		"."
	end
	--排除TW馬良白眉，TW馬良被打
	if target and q(self.player,"hasSkill","twyj_baimei") and not q(target,"hasSkill","jueqing") and q(self.player,"isKongcheng") then
		return
		"."
	end


	if q(self,"cantbeHurt",target) then return "." end

	if q(self,"isFriend",target) and q(target,"hasSkill","rende") and q(self.player,"hasSkill","jieming") then return "." end
	if q(self,"isEnemy",target) and not q(self,"isWeak") and q(self,"cantbeHurt",target) then return "." end

	if q(self,"isFriend",target) then
		if q(self,"needToLoseHp",self.player, target) then return "." end
		if q(self,"needToLoseHp",target, self.player) then
			return call(self,"getCardId","Slash")
		else
			if q(target,"isLord") and not q(self,"isLordInDanger") and not q(self,"isGoodHp",self.player) then
				return call(self,"getCardId",
					"Slash")
			end
			if q(self.player,"isLord") and q(self,"isLordInDanger") then return call(self,"getCardId","Slash") end
			return "."
		end
	end
	local x = q(q(q(data,"toCardEffect").card,"getSubcards"),"length")
	if (not q(self,"isFriend",target) and (q(self,"getCardsNum","Slash") >= ((known(getCardsNum("Slash",target,self.player),"xinwushuang observed Slash count") + 1) * (x - q(self.player,"getMark","AI_xinwushuang-Clear")))) and x < 3)
		or (q(target,"getHp") > 2 and q(self.player,"getHp") <= 1 and q(self,"getCardsNum","Peach") == 0 and not q(self.player,"hasSkill","buqu"))

		--薛綜復難技能有殺能出就出
		or (q(self.player,"hasSkill","funan") and q(self.player,"getMark","@funan") > 0)
	then
		return call(self,"getCardId","Slash")
	else
		return "."
	end
end






local luayuanlue_skill = {
	name = "luayuanlue",
	getTurnUseCard=function(self,inclusive,request)
		if q(self.player,"hasUsed","#luayuanlue") then return end
		return parse(self,request,"#luayuanlue:.:")
	end,
}
table.insert(package_skills, luayuanlue_skill) --加入AI可用技能表
sgs.ai_skill_use_func["#luayuanlue"] = function(card,use,self,request)
	call(self,"updatePlayers")

	local acard = final_parse(self,request,"#luayuanlue:.:") --根据卡牌构成字符串产生实际将使用的卡牌
	assert(acard)

	local max = 0
	local min = 999
	local target

	sort_players(self,self.friends, "handcard")
	for _, friend in ipairs(self.friends) do
		local x = 0
		if q(friend,"getHandcardNum") > q(friend,"getHp") then
			x = q(friend,"getHandcardNum") - q(friend,"getHp")
		end
		if (x > min) and x <= 2 and (q(self,"getBestHp",friend) < q(friend,"getHp")) then
			min = x
			target = friend
		end
	end
	if not target then
		for _, friend in ipairs(self.friends) do
			local x = 0
			if q(friend,"getHandcardNum") < q(friend,"getHp") then
				x = q(friend,"getHp") - q(friend,"getHandcardNum")
			end
			if (x > max) and x > 3 and not q(self,"hasManjuanEffect",friend) and q(self,"canDraw",friend, self.player) then
				max = x
				target = friend
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			local x = 0
			if q(enemy,"getHandcardNum") < q(enemy,"getHp") then
				x = q(enemy,"getHp") - q(enemy,"getHandcardNum")
			end
			if (x < min) and (x < 2 or q(self,"hasManjuanEffect",enemy)) and x > 0 and not q(self,"hasZhaxiangEffect",enemy) then
				min = x
				target = enemy
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			local x = 0
			if q(enemy,"getHandcardNum") > q(enemy,"getHp") then
				x = q(enemy,"getHandcardNum") - q(enemy,"getHp")
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
			call(use.to,"append",target) --填充卡牌使用结构体（to部分）
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
luajiezhi_skill.getTurnUseCard=function(self,inclusive,request)
	if not q(self.player,"hasFlag","luajiezhix") then return end
	local usable_cards = AIList.new(q(self.player,"getCards","h"))
	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			table.insert(usable_cards, disclosed(self,id))
		end
	end
	sort_use(self,usable_cards, true)
	local cards = {}
	for _, c in ipairs(usable_cards) do
		local cardex=owner_eval(self,"luajiezhi",disclosed(self,q(self.player,"getMark","luajiezhiskill")):objectName(),{},q(c,"getSuit"),q(c,"getNumber"))
		
		if not q(self.player,"isCardLimited",cardex, sgs.Card_MethodUse, true) and q(cardex,"isAvailable",self.player) and not q(c,"isKindOf","Peach") and not (q(c,"isKindOf","Jink") and q(self,"getCardsNum","Jink") < 3) and not q(cardex,"isKindOf","IronChain") then
			local name = disclosed(self,q(self.player,"getMark","luajiezhiskill")):objectName()
			local new_card = parse(self,request,(name .. ":luajiezhi[%s:%s]=%d"):format(q(c,"getSuitString"),
				q(c,"getNumberString"), q(c,"getEffectiveId")))
			assert(new_card)
			return new_card
		end
	end
end


ai_audited_aliases.register{id="ai_cardneed.luafeiqi",registry="ai_cardneed",path={"luafeiqi"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_skill_invoke.luafeiqi = function(self, data)
	local target = call(data,"toPlayer")
	if not target then
		return true
	end
	return q(self,"doDisCard",target, "h")
end




ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.luafeiqi",registry="ai_choicemade_filter",path={"cardChosen","luafeiqi"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}




sgs.ai_skill_use["@@luazhuixi"] = function(self, prompt)
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_players(self,self.enemies, "handcard")
	local slashcount = q(self,"getCardsNum","Slash")
	sort_use(self,cards, true)
	if slashcount > 0 then
		for _, card in ipairs(cards) do
			if (not q(card,"isKindOf","Peach") and not q(card,"isKindOf","ExNihilo") and not q(card,"isKindOf","Jink")) or q(self,"getOverflow") > 0 then
				local slash = call(self,"getCard","Slash")
				assert(slash)
				local target
				local dummy=no_distance_use(self,slash,"@@luazhuixi")
				if dummy.card and dummy.to then
					if not q(dummy.to,"isEmpty") then
						for _, p in sgs.qlist(dummy.to) do
							if not q(self.player,"inMyAttackRange",p) then
								target = p
							end
						end
					end
				end
				if target then
					return "#luazhuixi:" .. q(card,"getEffectiveId") .. ":->" .. q(target,"objectName")
				end
			end
		end
	end
end


sgs.ai_skill_discard.luaqingzhan = function(self)
	local to_discard = {}
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)
	sort_keep(self,cards)

	for _, acard in ipairs(cards) do
		if not (q(acard,"isKindOf","Peach")) and (q(self,"getDynamicUsePriority",acard) < sgs.ai_use_value.Slash) and #to_discard == 0 then
			table.insert(to_discard, q(acard,"getEffectiveId"))
			break
		end
	end
	if #to_discard == 0 then return end
	--table.insert(to_discard, cards[1]:getEffectiveId())

	return to_discard
end






sgs.ai_skill_use["@@luayonglue"] = function(self, prompt)
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_players(self,self.enemies, "handcard")
	local slashcount = q(self,"getCardsNum","Slash")
	sort_use(self,cards, true)


	if q(self,"needBear") then return "." end


	for _, enemy in ipairs(self.enemies) do
		if (q(self,"doDisCard",enemy, "he") or call(self,"getDangerousCard",enemy) or call(self,"getValuableCard",enemy)) and q(self.player,"canDiscard",enemy, "he") then
			return "#luayonglue:.:->" .. q(enemy,"objectName")
		end
	end
	for _, friend in ipairs(self.friends) do
		if (q(self,"hasSkills",sgs.lose_equip_skill, friend) and not q(friend,"getEquips"):isEmpty())
			or (q(self,"needToThrowArmor",friend) and call(friend,"getArmor")) or q(self,"doDisCard",friend, "he") then
			return "#luayonglue:.:->" .. q(friend,"objectName")
		end
	end




	if slashcount > 0 then
		for _, card in ipairs(cards) do
			if (not q(card,"isKindOf","Peach") and not q(card,"isKindOf","ExNihilo") and not q(card,"isKindOf","Jink")) or q(self,"getOverflow") > 0 then
				local slash = call(self,"getCard","Slash")
				assert(slash)
				local target
				local dummy=no_distance_use(self,slash,"@@luayonglue")
				if dummy.card and dummy.to then
					if not q(dummy.to,"isEmpty") then
						for _, p in sgs.qlist(dummy.to) do
							if not q(self.player,"inMyAttackRange",p) then
								target = p
							end
						end
					end
				end
				if target then
					return "#luayonglue:.:->" .. q(target,"objectName")
				end
			end
		end
	end
end


sgs.ai_card_intention["#luayonglue"] = 80


sgs.ai_choicemade_filter.cardChosen.luayonglue = sgs.ai_choicemade_filter.cardChosen.snatch


sgs.ai_skill_invoke.luamengxi = function(self, data)
	local target = q(data,"toDamage").to
	if not q(self,"isEnemy",target) then return false end
	if q(target,"hasArmorEffect","silver_lion") then return false end
	if q(self,"cantDamageMore",self.player, target) then return false end

	return true
end

sgs.ai_ajustdamage_from.luamengxi = function(self, from, to, card, nature)
	if q(from,"getMark","&luasizhanjl") and not q(self,"beFriend",to,from)
	then
		return 1
	end
end
sgs.ai_playerchosen_intention.luazhonghun = -80

sgs.ai_skill_playerchosen.luazhonghun = function(self, targets)
	if q(self.player,"getRole") == "loyalist" then
		return call(self.room,"getLord")
	end

	sort_players(self,self.friends_noself, "hp")
	for _, p in ipairs(self.friends_noself) do
		if q(self,"isWeak",p) then
			return p
		end
	end
end

sgs.ai_ajustdamage_to["&luazhonghun"] = function(self, from, to, card, nature)
	for _, p in sgs.list(q(self.room,"getOtherPlayers",to)) do
		if q(to,"getMark","&luazhonghun+to+#" .. q(p,"objectName")) > 0
		then
			return q(self,"ajustDamage",from, p, 0, card, nature)
		end
	end
end

sgs.ai_need_damaged["&luazhonghun"] = function(self, attacker, player)
	local victim
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",player)) do
		if q(player,"getMark","&luazhonghun+to+#" .. q(p,"objectName")) > 0 then
			victim = p
			break
		end
	end
	if victim ~= nil then
		local role
		if q(self,"isRolePredictable") and q(self,"getRoleEstimate",player) == "rebel" or q(self,"compareRoleEvaluation",player, "rebel", "loyalist") == "rebel" then
			role = "rebel"
		end
		local need_damage = false
		if (q(self,"getRoleEstimate",player) == "loyalist" or q(player,"isLord")) and role == "rebel" then need_damage = true end
		if q(self,"getRoleEstimate",player) == "rebel" and role ~= "rebel" then need_damage = true end
		if q(self,"getRoleEstimate",player) == "renegade" then need_damage = true end
		if q(victim,"isAlive") and need_damage then
			return q(victim,"hasSkill","wuhun") and 2 or 1
		end
	end

	return false
end



sgs.ai_skill_invoke.luajuesheng = function(self, data)
	local target = call(data,"toPlayer")
	if q(self,"isFriend",target) and q(self,"canDraw",target, self.player) then return true end

	return false
end

sgs.ai_choicemade_filter.skillInvoke.luajuesheng = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(q(self.room,"getOtherPlayers",player)) do
		if public_flag(self,p,"luajueshengTarget") then
			target = p
			break
		end
	end
	if target then
		if promptlist[#promptlist] == "yes" then
			call(self,"updateIntention",player, target, -40)
		end
	end
end



sgs.ai_skill_askforag["luaweiwo"] = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, disclosed(self,card_id))
	end
	sort_keep(self,to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end

sgs.ai_skill_use["@@luafuwei"] = function(self, prompt)
	local cards = AIList.new(q(self.player,"getCards","h"))

	sort_use(self,cards, true)

	for _, friend in ipairs(self.friends_noself) do
		if q(friend,"getHandcardNum") <= q(self.player,"getHandcardNum") then
			for _, card in ipairs(cards) do
				return "#luafuweicard:" .. q(card,"getEffectiveId") .. ":->" .. q(friend,"objectName")
			end
		end
	end
	local players = AIList.new(q(self.room,"getOtherPlayers",self.player))

	for _, player in ipairs(players) do
		if q(player,"getHandcardNum") <= q(self.player,"getHandcardNum") then
			for _, card in ipairs(cards) do
				return "#luafuweicard:" .. q(card,"getEffectiveId") .. ":->" .. q(player,"objectName")
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
luajieyi_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#luajieyicard") then return end
	local hurtF = 0

	for _, p in ipairs(self.friends_noself) do
		if not q(p,"isKongcheng") then hurtF = hurtF + 1 end
	end

	for _, p in ipairs(self.friends_noself) do
		if q(p,"getHp") < q(self,"getBestHp",p) and not q(p,"isKongcheng") then hurtF = hurtF + 1 end
	end

	if hurtF > 0 then return parse(self,request,"#luajieyicard:.:") end
	return
end

sgs.ai_skill_use_func["#luajieyicard"] = function(card,use,self,request)
	local targets = AIList.new({})

	for _, p in ipairs(self.friends_noself) do
		if q(p,"getHp") < q(self,"getBestHp",p) and not q(p,"isKongcheng") and q(targets,"length") < 2 and not q(targets,"contains",p) then
			call(targets,"append",p)
		end
	end

	for _, p in ipairs(self.friends_noself) do
		if not q(p,"isKongcheng") and q(targets,"length") < 2 and not q(targets,"contains",p) then call(targets,"append",p) end
	end

	if q(targets,"length") == 0 then return end

	local handcards = AIList.new(q(self.player,"getCards","h"))
	sort_need(self,handcards, true)
	local use_card = nil
	for _, c in ipairs(handcards) do
		use_card = c
	end

	if (q(targets,"length") > 0) and not (use_card == nil) then
		use.card = final_parse(self,request,"#luajieyicard:" .. q(use_card,"getEffectiveId") .. ":")
		if use.to then use.to = targets end
		return
	end
end





local luashanquan_skill = {}
luashanquan_skill.name = "luashanquan"
table.insert(package_skills, luashanquan_skill)
luashanquan_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#luashanquan") or q(self.player,"isKongcheng") then return end
	return parse(self,request,"#luashanquan:.:")
end
sgs.ai_skill_use_func["#luashanquan"] = function(card,use,self,request)
	local targets = {}
	local target
	sort_players(self,self.enemies, "defense")
	sort_players(self,self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if not q(self,"hasManjuanEffect",friend) then
			if q(self,"hasTuntianEffect",friend) and not q(friend,"isKongcheng") then
				target = friend
				break
			end
			if q(friend,"hasSkill","enyuan") and not q(friend,"isKongcheng") then
				target = friend
				break
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if q(self,"hasManjuanEffect",enemy) and not q(enemy,"isKongcheng") then
			target = enemy
			break
		end
		if not q(self,"hasTuntianEffect",enemy) and not q(enemy,"isKongcheng") then
			target = enemy
			break
		end
	end
	if target then
		use.card = card
		if use.to then
			call(use.to,"append",target)
		end
	end
end

sgs.ai_skill_discard["luashanquan"] = function(self, discard_num, optional, include_equip)
	local cards = AIList.new(q(self.player,"getCards","he"))
	local to_discard = {}
	local compare_func = function(a, b)
		return q(self,"getKeepValue",a) < q(self,"getKeepValue",b)
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if #to_discard >= discard_num then break end
		table.insert(to_discard, q(card,"getId"))
	end

	return to_discard
end

sgs.ai_getBestHp_skill.luajiye = function(owner)
	if q(owner,"getMark","luajiye") == 0 then
		return q(owner,"getMaxHp") - 1
	end
end

sgs.ai_target_revises.luaxiaomeng = function(to, card, self)
	if q(card,"isKindOf","Slash")
	then
		return q(self.player,"distanceTo",to) < 2
	end
end

sgs.ai_canliegong_skill.luaxiaomeng = function(self, from, to)
    if q(from,"distanceTo",to) <= 1 then return true end
end

sgs.ai_getBestHp_skill.luatuwei = function(owner)
	if q(owner,"getMark","luatuwei") == 0 then
		return q(owner,"getMaxHp") - 1
	end
end

--fail


sgs.ai_view_as.luagudan = function(card, player, card_place, class_name)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceEquip and q(card,"getTypeId") == sgs.Card_TypeEquip and not q(card,"hasFlag","using") then
		if class_name == "Jink" then
			return material(card,"jink","luagudan")
		elseif class_name == "Slash" then
			return material(card,"slash","luagudan_dis")
		end
	end
end

function sgs.ai_cardsview_valuable.luagudan(self, class_name, player)
	if q(player,"getPhase") ~= sgs.Player_NotActive then return end
	if class_name == "Slash"then
		local slashs = {}
		for _, c in sgs.qlist(q(player,"getCards","h")) do
			if q(c,"isKindOf","Slash") then
				table.insert(slashs, c)
			end
		end
		if #slashs == 0 then
			return response_spec(self,"luagudan_ex",class_name,q(player,"getHandcards"))
		end
	elseif class_name == "Jink" then
		local jinks = {}
		for _, c in sgs.qlist(q(player,"getCards","h")) do
			if q(c,"isKindOf","Jink") then
				table.insert(jinks, c)
			end
		end
		if #jinks == 0 then
			return response_spec(self,"luagudan_ex",class_name,q(player,"getHandcards"))
		end
	end
end


local SelfUseCard = function(self, card)
	local dummy = { isDummy = true, to = AIList.new({}), current_targets = {} }
	if q(card,"isKindOf","BasicCard")
	then
		call(self,"useBasicCard",card, dummy)
	elseif q(card,"isKindOf","TrickCard")
	then
		call(self,"useTrickCard",card, dummy)
	elseif q(card,"isKindOf","EquipCard")
	then
		call(self,"useEquipCard",card, dummy)
	end
	if dummy.card
	then
		return dummy
	end
	call(self,"useCardByClassName",card, dummy)
	return dummy
end

sgs.ai_use_revises.luagudan = function(self, card, use)
	if q(card,"isKindOf","EquipCard")
	then
		local same = call(self,"getSameEquip",card)
		if same then
			return false
		end
	end
end

local luagudan_skill = {}
luagudan_skill.name = "luagudan"
table.insert(package_skills, luagudan_skill)
luagudan_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = q(self,"addHandPile","e")
	local equip_card
	sort_use(self,cards, true)
	for _, card in ipairs(cards) do
		if q(card,"getTypeId") == sgs.Card_TypeEquip and (q(self,"getUseValue",card) < sgs.ai_use_value.Slash or inclusive) then
			equip_card = card
			break
		end
	end
	for _, c in sgs.qlist(q(self.player,"getHandcards")) do
		if q(c,"isKindOf","Slash") then
			equip_card = nil
		end
	end
	if equip_card then
		local suit = q(equip_card,"getSuitString")
		local number = q(equip_card,"getNumberString")
		local card_id = q(equip_card,"getEffectiveId")
		local card_str = ("slash:luagudan_dis[%s:%s]=%d"):format(suit, number, card_id)
		local slash = parse(self,request,card_str)
		assert(slash)
		return slash
	end

	if q(self.player,"getHandcardNum") > 1 then
		for _, c in sgs.qlist(q(self.player,"getHandcards")) do
			if not q(c,"isKindOf","Analeptic") then
				local dummy = q(self,"aiUseCard",c)
				if dummy.card then
					return
				end
			end
		end
	end

	local slash=turn_normal(self,"luagudan_ex","slash",ids(q(self.player,"getHandcards")),request)
	local dummy = q(self,"aiUseCard",slash)
	if dummy.card and dummy.to then
		return slash
	end
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .."|luagudan"

function sgs.ai_cardneed.luagudan(to, card, self)
	return q(card,"getTypeId") == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", true) == 0
end

sgs.ai_skill_invoke.luachunl = function(self, data)
	local damage = q(data,"toDamage")
	if damage.to and q(damage.to,"hasSkill","luachunl") then
		if q(self,"needToLoseHp",damage.to, damage.from, damage.card) then
			return false
		end
		return true
	elseif damage.from and q(damage.from,"hasSkill","luachunl") then
		if q(self,"isFriend",damage.to) then
			if q(self,"needToLoseHp",damage.to, damage.from, damage.card) then
				return false
			end
			return true
		else
			if q(self,"hasHeavyDamage",self.player, damage.card, damage.to) then return false end
			if q(self,"isWeak",damage.to) then return false end
			if q(self,"needToLoseHp",damage.to, damage.from, damage.card) then return true end
			if call(self,"getDangerousCard",damage.to) then return true end
			return false
		end
	end
end


sgs.ai_skill_askforag["leo_luaboxue"] = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, disclosed(self,card_id))
	end
	sort_keep(self,to_obtain)
	set_mark(self, "AI_leo_luaboxue1", 0)
	set_mark(self, "AI_leo_luaboxue2", 0)
	set_mark(self, "AI_leo_luaboxue3", 0)
	set_mark(self, "AI_leo_luaboxue" .. tostring(to_obtain[1]:getTypeId()), 1)
	return to_obtain[1]:getEffectiveId()
end

sgs.ai_card_priority.leo_luaboxue = function(self, card, v)
	if get_mark(self,"AI_leo_luaboxue"..tostring(q(card,"getTypeId"))) == 1
	then
		return 10
	end
end

sgs.ai_getBestHp_skill.luashenweiex1 = function(owner)
	return q(owner,"getMaxHp") - 1
end



sgs.ai_skill_use["@@luafanfu"] = function(self, prompt)
	local cards = AIList.new(q(self.player,"getCards","he"))

	sort_use(self,cards)

	local players = AIList.new(q(self.room,"getOtherPlayers",self.player))

	for _, player in ipairs(players) do
		if q(player,"getKingdom") == q(self.player,"getKingdom") then
			local slash = q(self,"getEvaluationCard","slash")
			
			if q(self,"isEnemy",player) and q(self,"slashIsEffective",slash, player) and not q(self,"slashProhibit",slash, player)
				and q(self,"isGoodTarget",player, self.enemies, slash) then
				for _, card in ipairs(cards) do
					if not q(card,"isKindOf","Peach") then
						return "#luafanfu:" .. q(card,"getEffectiveId") .. ":->" .. q(player,"objectName")
					end
				end
			end
		end
	end
	for _, player in ipairs(players) do
		if q(player,"getKingdom") ~= q(self.player,"getKingdom") then
			if q(self,"isFriend",player) and q(self,"canDraw",player, self.player) then
				for _, card in ipairs(cards) do
					if not q(card,"isKindOf","Peach") then
						return "#luafanfu:" .. q(card,"getEffectiveId") .. ":->" .. q(player,"objectName")
					end
				end
			end
			local slash = q(self,"getEvaluationCard","slash")
			
			if #self.friends_noself == 0 and q(self,"isEnemy",player) and q(self,"slashIsEffective",slash, player) and not q(self,"slashProhibit",slash, player) then
				for _, card in ipairs(cards) do
					return "#luafanfu:" .. q(card,"getEffectiveId") .. ":->" .. q(player,"objectName")
				end
			end
		end
	end
end

sgs.ai_skill_choice.luafanfu = function(self, choices, data)
	local players = AIList.new(q(self.room,"getOtherPlayers",self.player))
	local items = q(choices,"split","+")
	for _, player in ipairs(players) do
		local slash = q(self,"getEvaluationCard","slash")
		
		if q(self,"isEnemy",player) and q(self,"slashIsEffective",slash, player) and not q(self,"slashProhibit",slash, player)
			and q(self,"isGoodTarget",player, self.enemies, slash) and table.contains(items, q(player,"getKingdom")) then
			return q(player,"getKingdom")
		end
	end
	return items[1]
end

sgs.ai_ajustdamage_to.luataohui = function(self, from, to, card, nature)
	if from and q(from,"getHp") > q(to,"getHp") and nature == sgs.DamageStruct_Normal
	then
		return -99
	end
end




sgs.ai_skill_playerchosen["@luadushi1"] = function(self, targets)
	local lord = call(self.room,"getLord")
	if lord and q(self,"isEnemy",lord) and not q(lord,"isKongcheng") then
		return lord
	end

	sort_players(self,self.enemies, "handcard")

	for _, p in ipairs(self.enemies) do
		if q(self,"isWeak",p) and not q(p,"isKongcheng") then
			return p
		end
	end
	for _, p in ipairs(self.enemies) do
		if not q(p,"isKongcheng") then
			return p
		end
	end
end

sgs.ai_playerchosen_intention["@luadushi1"] = function(self, from, to)
	call(self,"updateIntention",from, to, 50)
end

sgs.ai_skill_choice.luadushi = function(self, choices)
	local items = q(choices,"split","+")
	local target = context_player(self,"leo_luadushi")
	if target and (call(self,"getDangerousCard",target) or q(self,"isFriend",target)) and table.contains(items, "luadushi1") then
		return "luadushi1"
	end

	return "luadushi2"
end




sgs.ai_skill_invoke["luayijue_xianfu"] = function(self, data)
	if q(self.player,"getRole") == "loyalist" then
		return true
	end
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(self.player,"getRole") == role(self,p) then
			return true
		end
	end
	return false
end



sgs.ai_skill_playerchosen.luayijue = function(self, targets)
	if q(self.player,"getRole") == "loyalist" or q(self.player,"getRole") == "renegade" then
		return call(self.room,"getLord")
	end

	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(self.player,"getRole") == role(self,p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.luayijue = function(self, from, to)
	call(self,"updateIntention",from, to, -80)
end



sgs.ai_skill_invoke["luayijue"] = function(self, data)
	local pattern = q(data,"toStringList")[1]
	local tied
	if pattern == "jink" then
		for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if q(player,"getMark","luayijue_use") > 0 then
				tied = player
				break
			end
		end
		if q(self,"hasEightDiagramEffect",tied) then return true end
		return q(self,"getCardsNum","Jink") == 0
	elseif pattern == "slash" then
		local asked = q(data,"toStringList")
		local prompt = asked[2]
		if q(self,"askForCard","slash", prompt, 1) == "." then return false end
		for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if q(player,"getMark","luayijue_use") > 0 then
				tied = player
				break
			end
		end
		if tied and q(tied,"getPhase") ~= sgs.Player_NotActive
			and q(self,"isFriend",tied) and q(self,"getOverflow",tied) > 2 and not q(self,"hasCrossbowEffect",tied) then
			return true
		end

		local cards = q(self.player,"getHandcards")
		for _, card in sgs.qlist(cards) do
			if q(self,"isCard","Slash",card,self.player) then
				return false
			end
		end
		return tied and q(self,"isFriend",tied)
	end
end

sgs.ai_skill_cardask["luayijuejink"] = function(self)
	local players = q(self.room,"getOtherPlayers",self.player)
	local target
	for _, p in sgs.qlist(players) do
		if q(p,"getMark","@luayijue") > 0 then
			target = p
			break
		end
	end
	if not q(self,"isFriend",target) then return "." end
	return call(self,"getCardId","Jink") or "."
end


sgs.ai_skill_cardask["luayijueslash"] = function(self)
	local players = q(self.room,"getOtherPlayers",self.player)
	local target
	for _, p in sgs.qlist(players) do
		if q(p,"getMark","@luayijue") > 0 then
			target = p
			break
		end
	end
	if not q(self,"isFriend",target) then return "." end
	return call(self,"getCardId","Slash") or "."
end



sgs.ai_skill_cardask["luayijuepeach"] = function(self)
	local players = q(self.room,"getOtherPlayers",self.player)
	local target
	for _, p in sgs.qlist(players) do
		if q(p,"getMark","@luayijue") > 0 then
			target = p
			break
		end
	end
	if not q(self,"isFriend",target) then return "." end
	return call(self,"getCardId","Peach") or "."
end

sgs.ai_cardneed.luazhiyong = function(to, card, self)
	return card and q(card,"getSuit") == sgs.Card_Heart
end

sgs.luazhiyong_suit_value = {
	heart = 6,
}

sgs.ai_card_priority.luazhiyong = function(self,card)
	if table.contains(q(card,"getSkillNames"), "luazhiyong")
	then
		if q(self.player,"getPhase") ==sgs.Player_NotActive
		then return 1 end
		return 0.08
	end
end

sgs.ai_use_revises.luazhiyong = function(self,card,use)
	if q(card,"isKindOf","EquipCard")
	and q(card,"getSuit") == sgs.Card_Heart
	then
		local same = call(self,"getSameEquip",card)
		if same and q(same,"getSuit") == sgs.Card_Heart
		then return false end
	end
end

local luazhiyong_skill = {}
luazhiyong_skill.name = "luazhiyong"
table.insert(package_skills, luazhiyong_skill)
luazhiyong_skill.getTurnUseCard=function(self,inclusive,request)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")
	local handcards = AIList.new(q(self.player,"getCards","h"))
	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			table.insert(handcards, disclosed(self,id))
		end
	end
	sort_use(self,handcards, true)
	local equipments = AIList.new(q(self.player,"getCards","e"))
	sort_use(self,equipments, true)
	local basic_cards = {}
	local basic_cards_count = 0
	local use_cards = {}



	for _, c in ipairs(handcards) do
		if not q(c,"isKindOf","Peach") then
			if q(c,"getSuit") == sgs.Card_Heart then
				basic_cards_count = basic_cards_count + 1
				table.insert(basic_cards, q(c,"getEffectiveId"))
			end
		end
	end

	if q(self,"getOverflow") <= 0 then return end


	if #basic_cards > 0 then
		table.insert(use_cards, basic_cards[1])
	end
	if #use_cards == 0 then return end


	if q(self.player,"isWounded") then
		return parse(self,request,"#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "peach")
	end

	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"canSlash",enemy) and q(self,"isGoodTarget",enemy, self.enemies) and q(self.player,"inMyAttackRange",enemy) then
			local thunder_slash = q(self,"getEvaluationCard","thunder_slash")
			
			local fire_slash = q(self,"getEvaluationCard","fire_slash")
			
			local slash = q(self,"getEvaluationCard","slash")
			
			if not q(self,"slashProhibit",fire_slash, enemy, self.player) and q(self,"slashIsEffective",fire_slash, enemy, self.player) then
				return parse(self,request,"#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "fire_slash")
			end
			if not q(self,"slashProhibit",thunder_slash, enemy, self.player) and q(self,"slashIsEffective",thunder_slash, enemy, self.player) then
				return parse(self,request,"#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "thunder_slash")
			end
			if not q(self,"slashProhibit",slash, enemy, self.player) and q(self,"slashIsEffective",slash, enemy, self.player) then
				return parse(self,request,"#luazhiyong:" .. table.concat(use_cards, "+") .. ":" .. "slash")
			end
		end
	end
end

sgs.ai_skill_use_func["#luazhiyong"] = function(card,use,self,request)
	local userstring=q(card,"getLegacyStringKey"):split(":")[4]
	local xin_zhayi_jibencard=owner_eval(self,"luazhiyong",userstring,{},q(card,"getSuit"),q(card,"getNumber"))
	call(self,"useBasicCard",xin_zhayi_jibencard, use)
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
	local cards = q(player,"getCards","h")
	if q(player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(player,"getPile","wooden_ox")) do
			call(cards,"prepend",own_card(player,id))
		end
	end
	for _, c in sgs.qlist(cards) do
		if q(c,"isKindOf",class_name) then
			no_have = false
			break
		end
	end
	if not no_have then return end

	local handcards = AIList.new(q(player,"getCards","h"))
	if q(player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(player,"getPile","wooden_ox")) do
			table.insert(handcards, own_card(player,id))
		end
	end
	local basic_cards = {}
	local use_cards = {}


	for _, c in ipairs(handcards) do
		if not q(c,"isKindOf","Peach") then
			if q(c,"getSuit") == sgs.Card_Heart then
				table.insert(basic_cards, q(c,"getEffectiveId"))
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
	if q(player,"getPhase") ~= sgs.Player_NotActive then return end
	if class_name == "Peach" and known(self.request.reason,"request reason") ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	if q(player,"hasFlag","Global_luayijueFailed") then return end
	if q(player,"hasFlag","Global_luayijueFailed_AI") then return end
	local guanyu = call(self.room,"findPlayerBySkillName","luayijue")
	if guanyu then return {skill="luayijuedest&",legacy_class="#luayijuedestCard",subcards={},user_string=name} end
end

sgs.ai_skill_cardask["@@luayijue"] = function(self, data, pattern)
    local target = call(data,"toPlayer")
    if target and q(self,"isFriend",target) then
        local cards = q(self.player,"getCards","he")
        cards = AIList.new(cards)
        sort_keep(self,cards)
        for _,h in sgs.list(cards)do
            if q(self,"matchesDiscardPattern",h,pattern)
            then return q(h,"getEffectiveId") end
            if q(h,"isKindOf",pattern)
            then return q(h,"getEffectiveId") end
        end
        return call(self,"getCardId",pattern)
    end
    return "."
end



sgs.ai_skill_askforag["luaweiwo1"] = function(self,card_ids)
	local cards={};for _,id in ipairs(card_ids)do cards[#cards+1]=disclosed(self,id)end
	sort_use(self,cards,true)
	return cards[1]:getId()
end
sgs.ai_skill_playerchosen["@luaspbazhen1"] = function(self, targets)
    targets = AIList.new(targets)
	sort_players(self,targets, "defense")
    for _,target in ipairs(targets) do
        if q(self,"doDisCard",target, "he", true) then
            return target
        end
    end
    return targets[1]
end

sgs.ai_skill_use["@@luaspbazhen"] = function(self, prompt, method)
	local use_card=owner_eval(self,"luaspbazhen","IronChain",{},sgs.Card_NoSuit,-1)
	local dummy_use = q(self,"aiUseCard",use_card, dummy())
	local targets = {}
	if not q(dummy_use.to,"isEmpty") then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, q(p,"objectName"))
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
	sort_players(self,targets, "defense")
	local fire_attack=owner_eval(self,"luaspbazhen","fire_attack",{},sgs.Card_NoSuit,0)
    
    local dummy_use = q(self,"aiUseCard",fire_attack, dummy())
    if dummy_use.card and not q(dummy_use.to,"isEmpty") then
        for _, p in sgs.qlist(dummy_use.to) do
            if table.contains(targets, p) then
                return p
            end
        end
    end
	return targets[1]
end

sgs.ai_hasTuntianEffect_skill.luaspbazhen = function(to, need_zaoxian)
	return q(to,"getPhase") == sgs.Player_NotActive
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
		local x = math.min(q(self.player,"getHp"), 3) - q(self.player,"getMark","newluaweiwo")
		if x > 0 then
			sort_keep(self,to_obtain, true)
			return to_obtain[1]:getEffectiveId()
		else
			local card_id = q(self,"getRetrialCardId",to_obtain, judge)
			if card_id ~= -1 then
				return "$" .. card_id
			end
		end
	end
	sort_keep(self,to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end
sgs.ai_skill_playerchosen["luajincui"] = function(self, targets)
	return self.player
end
sgs.ai_playerchosen_intention.luajincui = -50


sgs.ai_skill_choice.luajincui = function(self,choices,data)
	for _,friend in ipairs(self.friends)do
		if q(friend,"hasSkill","tianxiang") and (q(self.player,"getHp")>=3 or (q(self,"getCardsNum","Peach")+q(self,"getCardsNum","Analeptic")>0 and q(self.player,"getHp")>1)) then
			return "luajincui1"
		end
	end
	if q(self.player,"getMaxHp")>=q(self.player,"getHp")+2 then
		if q(self.player,"getMaxHp")>5 and (q(self.player,"hasSkills","nosmiji|yinghun|juejing|zaiqi|nosshangshi") or q(self.player,"hasSkill","miji") and call(self,"findPlayerToDraw",false)) then
			local enemy_num = 0
			for _,p in ipairs(self.enemies)do
				if q(p,"inMyAttackRange",self.player) and not q(self,"willSkipPlayPhase",p) then enemy_num = enemy_num+1 end
			end
			local ls = call(self,"getStrategyMemory","fangquan_effect") and call(self.room,"findPlayerBySkillName","fangquan")
			if ls then
				call(self,"setStrategyMemory","fangquan_effect",false)
				enemy_num = q(self,"getEnemyNumBySeat",ls,self.player,self.player)
			end
			local least_hp = isLord(self.player) and math.max(2,enemy_num-1) or 1
			if (q(self,"getCardsNum","Peach")+q(self,"getCardsNum","Analeptic")+q(self.player,"getHp")>least_hp) then return "luajincui1" end
		end
		return "luajincui2"
	else
		return "luajincui1"
	end
end

sgs.ai_canNiepan_skill.luatianming = function(player)
	return q(player,"getMark","@RX") >= 7 and q(player,"getMark","luatianming") == 0
end



do local source=sgs.ai_skill_use["@@luaqingqi"];sgs.ai_skill_use["@@luaqingqi"]=function(self,...)return response_wire(self,source(self,...))end end

do local source=sgs.ai_skill_use["@@luazhuixi"];sgs.ai_skill_use["@@luazhuixi"]=function(self,...)return response_wire(self,source(self,...))end end

do local source=sgs.ai_skill_use["@@luayonglue"];sgs.ai_skill_use["@@luayonglue"]=function(self,...)return response_wire(self,source(self,...))end end

do local source=sgs.ai_skill_use["@@luafuwei"];sgs.ai_skill_use["@@luafuwei"]=function(self,...)return response_wire(self,source(self,...))end end

do local source=sgs.ai_skill_use["@@luafanfu"];sgs.ai_skill_use["@@luafanfu"]=function(self,...)return response_wire(self,source(self,...))end end

for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
