-- Fixed fate-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("fate policy input is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("fate policy helper unavailable",method) end
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
local skill_cards={['#fateqiuzhan_card']='fateqiuzhan',['#fateshenjian_card']='fateshenjian',['#fatetiangong_card']='fatetiangong_vs',['#fateloli_card']='fateloli_vs',['#fateheijian_card']='fateheijian',['#fatefanshi_card']='fatefanshi',['#fatexinyin_card']='fatexinyin',['#fatebumo_card']='fatebumo',['#fatechuyi_card']='fatechuyi_vs',['#fateyaoshu']='fateyaoshu',['#fatemoshu_card']='fatemoshu_vs',['#fatejuntuan_card']='fatejuntuan_vs',['#fatesiji_card']='fatesiji_vs',['#fatechongshu_card']='fatechongshu',['#fatewangzhe']='fatewangzhe'}
local names={slash='Slash',jink='Jink',peach='Peach',analeptic='Analeptic',fire_slash='FireSlash',thunder_slash='ThunderSlash',duel='Duel',iron_chain='IronChain'}
local function ids(cards)local out={};for _,card in ipairs(cards)do out[#out+1]=type(card)=='number'and card or q(card,'getEffectiveId')end;return out end
local function own_card(player,id)
 for _,group in ipairs({q(player,'getCards','he'),q(player,'getHandPileCards')})do for _,card in ipairs(group)do if q(card,'getEffectiveId')==id then return card end end end
 ai_unsupported('source card face is not owner-disclosed',tostring(id))
end
local function disclosed(self,id)
 local preview=self:getDecisionContext().retrial_preview
 if type(preview)=='table'and preview.known==true and preview.skill=='fatewangzhe'then
  for _,value in ipairs(preview.ids or{})do
   if value==id then return q(self,'getPreviewCardEvaluation',id)end
  end
 end
 local card=self:getKnownCardById(id)or self:getChoiceCard(id)
 return known(card,'fate disclosed card '..tostring(id))
end
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
local function dummy()local use=AIUsePlan.new();use.isDummy=true;return use end
local function role(self,player)local value=call(player,'getRole');if value~=nil then return value end
 return q(self,'useKnowledgeEstimate',{status='estimate',value=q(self,'getRoleEstimate',player),basis='viewer_role_estimate_private_role',player=q(player,'objectName')},'fate.role')end
local function context_value(self,key)local value=known(q(self,'getDecisionContext')[key],key);if value==false then return nil end;return value end
local function context_player(self,key)local name=context_value(self,key);if name==nil then return nil end;return known(self.room:findPlayerByObjectName(name),key)end
local function context_effect(self,key)
 local row=known(context_value(self,key),key)
 local card=known(row.card,key..'.card')
 if type(card.isKindOf)~='function' then card=CardView.new(card,self.room) end
 local function player(value,field)
  if value==nil or value==false or value==''then return nil end
  if type(value)=='string'then return known(self.room:findPlayerByObjectName(value),key..'.'..field)end
  return value
 end
 return {card=card,from=player(row.from,'from'),to=player(row.to,'to'),offset_num=row.offset_num}
end
local function printed(self,id)return q(self,'getPrintedCardById',id)end
local function player_disclosed(player,id)
 local function find(cards)for _,card in ipairs(cards)do if q(card,'getEffectiveId')==id then return card end end end
 for _,method in ipairs({'getKnownCards','getEquips','getHandPileCards'})do local card=find(q(player,method));if card then return card end end
 local room=q(player,'getRoom');local card=find(q(room,'getDiscardCards'));if card then return card end
 for _,p in ipairs(q(room,'getAlivePlayers'))do
  card=find(q(p,'getEquips'));if card then return card end
  card=find(q(p,'getJudgingArea'));if card then return card end
 end
 ai_unsupported('fatetouying mark does not disclose its referenced face','fatetouying.mark_card')
end
local function he_count(player)return q(player,'getHandcardNum')+#q(player,'getEquips')end
local function donor_undefined_target()error('fixed fatewangzhe donor reads undefined global target',0)end

sgs.ai_skill_invoke.fateyezhan = function(self, data)
	return true
end

ai_audited_aliases.register{id="ai_skill_playerchosen.fateyezhan",registry="ai_skill_playerchosen",path={"fateyezhan"},canonical_registry="ai_skill_playerchosen",canonical_path={"damage"},self_index=1,defer_canonical=true}





local fatetouying_skill = {}
fatetouying_skill.name = "fatetouying"
table.insert(package_skills, fatetouying_skill)
fatetouying_skill.getTurnUseCard=function(self,inclusive,request)
	if not q(self.player,"hasFlag","fatetouyingx")  then return end
	local usable_cards = AIList.new(q(self.player,"getCards","h"))
	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			table.insert(usable_cards, disclosed(self,id))
		end
	end
	sort_use(self,usable_cards, true)
	local cards = {}
	for _,c in ipairs(usable_cards) do
		local cardex=owner_eval(self,"fatetouying",disclosed(self,q(self.player,"getMark","fatetouyingskill")):objectName(),{},q(c,"getSuit"),q(c,"getNumber"))
		
		if not q(self.player,"isCardLimited",cardex, sgs.Card_MethodUse, true) and q(cardex,"isAvailable",self.player) and not q(c,"isKindOf","Peach") and not (q(c,"isKindOf","Jink") and q(self,"getCardsNum","Jink") < 3) then
		local name = disclosed(self,q(self.player,"getMark","fatetouyingskill")):objectName()
		local new_card = parse(self,request,(name..":fatetouying[%s:%s]=%d"):format(q(c,"getSuitString"), q(c,"getNumberString"), q(c,"getEffectiveId")))
			assert(new_card) 
			return new_card
		end
	end
end

sgs.ai_view_as.fatetouying = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand or q(player,"getPile","wooden_ox"):contains(card_id) then
		local name = player_disclosed(player,q(player,"getMark","fatetouyingskill")):objectName()
		if name and q(player,"hasFlag","fatetouyingx") then
			return material(card,name,"fatetouying")
		end
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|fatetouying"

sgs.ai_canNiepan_skill.fatesizhan = function(player)
	return q(player,"getMark","fatesizhan") == 0
end



sgs.ai_skill_invoke.fatewangzhe = function(self, data)
	return true
end

sgs.ai_skill_askforag.fatewangzhe = function(self, card_ids)
	local nextAlive = self.player
	repeat
		nextAlive = q(nextAlive,"getNextAlive")
	until q(nextAlive,"faceUp")

	local peach, ex_nihilo, jink, nullification, slash
	local valuable
	for _, id in ipairs(card_ids) do
		local card = disclosed(self,id)
		if q(card,"isKindOf","Peach") then peach = id end
		if q(card,"isKindOf","ExNihilo") then ex_nihilo = id end
		if q(card,"isKindOf","Jink") then jink = id end
		if q(card,"isKindOf","Nullification") then nullification = id end
		if q(card,"isKindOf","Slash") then slash = id end
	end
	valuable = peach or ex_nihilo or jink or nullification or slash or card_ids[1]
	local card = disclosed(self,valuable)
	if not (q(self,"needKongcheng",self.player) and q(self,"getHandcardNum") <= 2) then
		if q(card,"isKindOf","Peach") then
			return valuable
		end
		if q(card,"isKindOf","TrickCard") or q(card,"isKindOf","Indulgence") or q(card,"isKindOf","SupplyShortage") then
			local dummy_use = { isDummy = true }
			call(self,"useTrickCard",card, dummy_use)
			if dummy_use.card then
				return valuable
			end
		end
		if q(card,"isKindOf","Jink") and q(self,"getCardsNum","Jink") == 0 then
			return valuable
		end
		if q(card,"isKindOf","Nullification") and q(self,"getCardsNum","Nullification") == 0 then
			return valuable
		end
		if q(card,"isKindOf","Slash") and q(self,"slashIsAvailable") then
			local dummy_use = { isDummy = true }
			call(self,"useBasicCard",card, dummy_use)
			if dummy_use.card then
				return valuable
			end
		end
		return valuable
		end
	local hasLightning, hasIndulgence, hasSupplyShortage
	local tricks = q(nextAlive,"getJudgingArea")
	if not q(tricks,"isEmpty") and not q(nextAlive,"containsTrick","YanxiaoCard") then
		local trick = q(tricks,"at",q(tricks,"length") - 1)
		if q(self,"hasTrickEffective",trick, nextAlive) then
			if q(trick,"isKindOf","Lightning") then hasLightning = true
			elseif q(trick,"isKindOf","Indulgence") then hasIndulgence = true
			elseif q(trick,"isKindOf","SupplyShortage") then hasSupplyShortage = true
			end
		end
	end

	if q(self,"isEnemy",nextAlive) and q(nextAlive,"hasSkill","luoshen") and valuable then
		return valuable
	end
	if q(nextAlive,"hasSkill","yinghun") and q(nextAlive,"isWounded") then
		return valuable
	end
	if donor_undefined_target():hasSkill("hongyan") and hasLightning and q(self,"isEnemy",nextAlive) and not (q(nextAlive,"hasSkill","qiaobian") and q(nextAlive,"getHandcardNum") > 0) then
		for _, id in ipairs(card_ids) do
			local card = printed(self,id)
			if q(card,"getSuit") == sgs.Card_Spade and q(card,"getNumber") >= 2 and q(card,"getNumber") <= 9 then
				return id
			end
		end
	end
	if hasIndulgence and q(self,"isFriend",nextAlive) then
		return valuable
	end
	if hasSupplyShortage and q(self,"isEnemy",nextAlive) and not (q(nextAlive,"hasSkill","qiaobian") and q(nextAlive,"getHandcardNum") > 0) then
		local enemy_null = 0
		for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
			if q(self,"isFriend",p) then enemy_null = enemy_null - getCardsNum("Nullification", p) end
			if q(self,"isEnemy",p) then enemy_null = enemy_null + getCardsNum("Nullification", p) end
		end
		enemy_null = enemy_null - q(self,"getCardsNum","Nullification")
		if enemy_null < 0.8 then
			return valuable
		end
	end

	if q(self,"isFriend",nextAlive) and not q(self,"willSkipDrawPhase",nextAlive) and not q(self,"willSkipPlayPhase",nextAlive)
		and not q(nextAlive,"hasSkill","luoshen")
		and not q(nextAlive,"hasSkill","tuxi") and not (q(nextAlive,"hasSkill","qiaobian") and q(nextAlive,"getHandcardNum") > 0) then
		if (peach and valuable == peach) or (ex_nihilo and valuable == ex_nihilo) then
			return valuable
		end
		if jink and valuable == jink and getCardsNum("Jink", nextAlive) < 1 then
			return valuable
		end
		if nullification and valuable == nullification and getCardsNum("Nullification", nextAlive) < 1 then
			return valuable
		end
		if slash and valuable == slash and q(self,"hasCrossbowEffect",nextAlive) then
			return valuable
		end
	end

	local card = disclosed(self,valuable)
	local keep = false
	if q(card,"isKindOf","Slash") or q(card,"isKindOf","Jink")
		or q(card,"isKindOf","EquipCard")
		or q(card,"isKindOf","Disaster") or q(card,"isKindOf","GlobalEffect") or q(card,"isKindOf","Nullification")
		or donor_undefined_target():isLocked(card) then
		keep = true
	end
	return valuable
end


sgs.ai_skill_use["@fatewangzhe"] = function(self, prompt, method)
	local tag=context_value(self,"fate_wangzhe_ids")
	local guanxu_cardsToGet
    if tag then
        guanxu_cardsToGet = tag
    else
        return "."
    end
    local discard_cards = {}
	local drawpile = {}
    for i=1,#guanxu_cardsToGet, 1 do
        local card_data = guanxu_cardsToGet[i]
        if card_data == nil then break end
        if card_data ~= "" then 
            local card_id = tonumber(card_data)
            table.insert(drawpile, disclosed(self,card_id))
        end
    end
    
    sort_use(self,drawpile)
	for _, c in ipairs(drawpile) do
        table.insert(discard_cards, q(c,"getEffectiveId"))
    end
        
		
    if #discard_cards > 0 then
        return string.format("#fatewangzhe:%s:", discard_cards[1])
    end
end






local fateqiuzhan_skill={}
fateqiuzhan_skill.name="fateqiuzhan"
table.insert(package_skills,fateqiuzhan_skill)
fateqiuzhan_skill.getTurnUseCard=function(self,inclusive,request)	
    if not q(self.player,"hasUsed","#fateqiuzhan_card") then
		return parse(self,request,"#fateqiuzhan_card:.:")
	end
end

sgs.ai_skill_use_func["#fateqiuzhan_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
	local duel=owner_eval(self,"fateqiuzhan_card","duel",{},sgs.Card_NoSuit,0)
	
	local dummy_use = q(self,"aiUseCard",duel, dummy())
	if dummy_use.card then
		for _,p in sgs.qlist(dummy_use.to)do
			if q(self,"objectiveLevel",p) > 3 and not q(self,"cantbeHurt",p) and q(self,"isTiaoxinTarget",p) and q(self,"canDamage",p,self.player,nil) then
				use.card=final_parse(self,request,"#fateqiuzhan_card:.:")
				if use.to then
					call(use.to,"append",p)
				end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and  q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) and q(self,"canDamage",enemy,self.player,nil)		then
			use.card=final_parse(self,request,"#fateqiuzhan_card:.:") 
			if use.to then
				call(use.to,"append",enemy)
			end
			return
		end
	end
end




sgs.ai_skill_cardask["@fateqzslash"]=function(self, data, pattern, target)
	target = target or call(self.room,"getCurrent")
	if (q(self,"hasSkill","fatehuyou") and #self.enemies > 0) then
		return "."
	end
	if (q(self,"getCardsNum","Slash")*2 >= q(target,"getHandcardNum")) then
		return "."
	end
end

local fateshenjian_skill={}
fateshenjian_skill.name="fateshenjian"
table.insert(package_skills,fateshenjian_skill)
fateshenjian_skill.getTurnUseCard=function(self,inclusive,request)	
	if (q(self.player,"getMark","@shenjian_mark")== 0) or not q(self.player,"isWounded") then return end
	if q(self.player,"getHp") + q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") <= 2 then
		return parse(self,request,"#fateshenjian_card:.:")
	end
	local x = math.min(q(self.player,"getLostHp"), 2)
	local target_num = 0
	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"inMyAttackRange",enemy) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal)  then
			target_num = target_num + 1
		end
	end
	if target_num > 1 then
		return parse(self,request,"#fateshenjian_card:.:")
	end
		
end

sgs.ai_skill_use_func["#fateshenjian_card"]=function(card,use,self,request)
	local x = math.min(q(self.player,"getLostHp"), 2)
	if q(self.player,"getMark","@shenjian_mark") == 0 then return end
	local targets = AIList.new({})
	sort_players(self,self.enemies, "hp")
	local cards = q(self.player,"getHandcards")
	cards = AIList.new(cards)
	sort_use(self,cards, true)
	local need_cards = {}
	for _, card in ipairs(cards) do
		if not q(card,"isKindOf","Peach")  then 
			table.insert(need_cards, q(card,"getId"))
			if #need_cards >= 2 then
				break
			end
		end
	end
	if #need_cards < 2 then return end
	for _, enemy in ipairs(self.enemies) do
		if  q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) and  q(self.player,"inMyAttackRange",enemy)  and not q(self,"cantbeHurt",enemy) and q(enemy,"getHp") <= x and q(self,"canDamage",enemy,self.player,nil) then
			call(targets,"append",enemy)
			if q(targets,"length") >= 2 then break end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if not q(targets,"contains",enemy) then
			if q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) and  q(self.player,"inMyAttackRange",enemy) then
				call(targets,"append",enemy)
				if q(targets,"length") >= 2 then break end
			end
		end
	end
	if q(targets,"length") > 0 then
		use.card=final_parse(self,request,"#fateshenjian_card:" .. table.concat(need_cards, "+")..":")
		if use.to then use.to = targets end
		
		
		
	end
end






sgs.ai_use_value["#fateqiuzhan_card"] = 8.5
sgs.ai_use_priority["#fateqiuzhan_card"] = 2
sgs.dynamic_value.damage_card["fateqiuzhan_card"] = true
sgs.ai_card_intention["fateqiuzhan_card"] = 60
sgs.double_slash_skill = sgs.double_slash_skill .. "|fateqiuzhan"

sgs.ai_use_value["#fateshenjian_card"] = 8.5
sgs.ai_use_priority["#fateshenjian_card"] = 9
sgs.dynamic_value.damage_card["fateshenjian_card"] = true
sgs.ai_card_intention["fateshenjian_card"] = 100

sgs.straight_damage_skill = sgs.straight_damage_skill .. "|fateshenjian"



local fatetiangong_skill={}
fatetiangong_skill.name="fatetiangong_vs"
table.insert(package_skills,fatetiangong_skill)
fatetiangong_skill.getTurnUseCard=function(self,inclusive,request)
    if q(self.player,"getHandcardNum")<1 then return nil end
    if q(self.player,"hasUsed","#fatetiangong_card") then return nil end
    local cards = q(self.player,"getHandcards")
    cards=AIList.new(cards)
    sort_keep(self,cards)
	local card_str = ("#fatetiangong_card:%d:"):format(cards[1]:getId())
    return parse(self,request,card_str)
end

sgs.ai_skill_use_func["#fatetiangong_card"]=function(card,use,self,request)
	local first
	local slash = q(self,"getEvaluationCard","fire_slash")
	
	sort_players(self,self.enemies, "hp") 
	for _, enemy in ipairs(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self.player,"canSlash",enemy, slash) and not q(self,"slashProhibit",slash, enemy) and q(self,"canDamage",enemy,self.player,slash)
						and q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash) then
			use.card=final_parse(self,request,"#fatetiangong_card:" .. q(card,"getEffectiveId")..":")  
			if use.to then
				call(use.to,"append",enemy)
				first=enemy
				break
			end
		end
	end
	if first and q(self.player,"distanceTo",first) == 1 then 
		for _, enemy2 in ipairs(self.enemies) do
		
			if (q(self.player,"distanceTo",enemy2) == 1) and q(enemy2,"getSeat") ~= q(first,"getSeat") and not q(self,"cantbeHurt",enemy2) and q(self.player,"canSlash",enemy2, slash) and not q(self,"slashProhibit",slash, enemy2) and q(self,"canDamage",enemy2,self.player,nil)
						and q(self,"slashIsEffective",slash, enemy2) and q(self,"isGoodTarget",enemy2, self.enemies, slash) then
				call(use.to,"append",enemy2)
				return
			end
		end
	end
end

sgs.ai_use_value.fatetiangong_card = 7.5
sgs.ai_use_priority.fatetiangong_card = 4
sgs.ai_card_intention.fatetiangong_card = 70

sgs.double_slash_skill = sgs.double_slash_skill .. "|fatetiangong_vs"

sgs.ai_skill_invoke.fatejianzhong = function(self, data)
	return true
end
sgs.ai_target_revises.fatejianzhong = function(to, card)
	if  q(card,"isKindOf","ArcheryAttack")
	then
		return true
	end
end

sgs.ai_skill_cardask["@fatejianzhong1"] = function(self, data, pattern, target)
	local targets = AIList.new({})
	local cards = AIList.new(q(self.player,"getCards","he"))
	for _,p in sgs.qlist(q(self.room,"getOtherPlayers",self.player))do 
		if q(self.player,"canSlash",p,nil, false) then 
			call(targets,"append",p)
		end
	end
	if q(targets,"isEmpty") then return "." end
	if sgs.ai_skill_playerchosen["@fatejianzhong2"](self, targets) == nil then return "." end
	sort_keep(self,cards)
	for _,card in sgs.list(cards)do
		return "$"..q(card,"getEffectiveId")
	end
	return "."
end

ai_audited_aliases.register{id="ai_skill_playerchosen.@fatejianzhong2",registry="ai_skill_playerchosen",path={"@fatejianzhong2"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1,defer_canonical=true}





sgs.ai_skill_cardask["@fatejuli-jink-1"] = function(self, data, pattern, target)
	local isdummy = type(data) == "number"
	local function getJink()
		if (q(self,"getCardsNum","Jink") > 0 and q(self,"getCardsNum","Slash") > 0) then
		return call(self,"getCardId","Slash") or not isdummy and "."
		else
		return "."
		end
	end
	local effect = q(data,"toCardEffect")
	local slash = effect.card
	local cards = AIList.new(q(self.player,"getHandcards"))
	if (not target or q(self,"isFriend",target)) and q(slash,"hasFlag","nosjiefan-slash") then return "." end
	if call(self,"standardNullFilter", data, pattern, target) then return "." end
	
	if not q(self,"slashIsEffective",slash,self.player,effect.from)
		or (q(self,"ajustDamage",effect.from,self.player,1,slash)<2
		and q(self,"needToLoseHp",self.player,effect.from,slash)) then return "." end
		if q(self,"ajustDamage",effect.from,self.player,1,slash) and q(self,"getCardsNum","Peach")>0 then return "." end
	if not target then return getJink() end
	if not q(self,"hasHeavyDamage",target, slash, self.player) and q(self,"needToLoseHp",self.player, target, slash) then return "." end
	
	if q(self,"ajustDamage",target, nil, 1, slash) <= 0 then return "." end

	if q(slash,"isKindOf","NatureSlash") and q(self.player,"isChained") and q(self,"isGoodChainTarget",self.player, target, nil, nil, slash) then return "." end
	if q(self,"isFriend",target) then
		if call(self,"findLeijiTarget",self.player, 50, target) then return getJink() end
		if q(target,"hasSkill","jieyin") and not q(self.player,"isWounded") and q(self.player,"isMale") and not q(self.player,"hasSkills","leiji|nosleiji|olleiji|jieleiji") then return "." end
		if not q(target,"hasSkill","jueqing") then
			if (q(target,"hasSkill","nosrende") or (q(target,"hasSkill","rende") and not q(target,"hasUsed","RendeCard"))) and q(self.player,"hasSkill","jieming") then return "." end
			if q(target,"hasSkill","pojun") and not q(self.player,"faceUp") then return "." end
			
			if q(target,"hasSkill","BurningLove") and q(slash,"isKindOf","FireSlash") then return "." end
		end
	else
		if q(self,"hasHeavyDamage",target, slash, self.player) then return getJink() end

		local current = call(self.room,"getCurrent")
		if current and q(current,"hasSkill","juece") and q(self.player,"getHp") > 0 then
			local use = false
			for _, card in ipairs(q(self,"getCards","Jink")) do
				if not q(self.player,"isLastHandCard",card, true) then
					use = true
					break
				end
			end
			if not use then return not isdummy and "." end
		end
		if q(self.player,"getHandcardNum") == 1 and q(self,"needKongcheng") then return getJink() end
		if not q(self,"hasLoseHandcardEffective") and not q(self.player,"isKongcheng") then return getJink() end
		if q(target,"hasSkill","mengjin") and not (q(target,"hasSkill","nosqianxi") and q(target,"distanceTo",self.player) == 1) then
			if q(self.player,"getCards","he"):length() == 1 and not call(self.player,"getArmor") then return getJink() end
			if q(self.player,"hasSkills","jijiu|qingnang") and q(self.player,"getCards","he"):length() > 1 then return "." end
			if q(self,"canUseJieyuanDecrease",target) then return "." end
			if (q(self,"getCardsNum","Peach") > 0 or (q(self,"getCardsNum","Analeptic") > 0 and q(self,"isWeak")))
				and not hasTuntianEffect(self.player, true) and not q(self,"willSkipPlayPhase") then
				return "."
			end
		end
		if q(self.player,"getHp") > 1 and getKnownCard(target, self.player, "Slash") >= 1 and getKnownCard(target, self.player, "Analeptic") >= 1 and q(self,"getCardsNum","Jink") == 1
			and (q(target,"getPhase") < sgs.Player_Play or q(self,"slashIsAvailable",target) and q(target,"canSlash",self.player)) then
			return "."
		end
		if not (q(target,"hasSkill","nosqianxi") and q(target,"distanceTo",self.player) == 1) then
			if q(target,"hasWeapon","axe") then
				if q(target,"hasSkills",sgs.lose_equip_skill) and q(target,"getEquips"):length() > 1 and q(target,"getCards","he"):length() > 2 then return not isdummy and "." end
				if q(target,"getHandcardNum") - q(target,"getHp") > 2 and not q(self,"isWeak") and not q(self,"getOverflow") then return not isdummy and "." end
			elseif q(target,"hasWeapon","blade") then
				
				local has_weak_chained_friend = false
				for _, friend in ipairs(self.friends_noself) do
					if q(friend,"isChained") and q(self,"isWeak",friend) then
						has_weak_chained_friend = true
					end
				end
				if has_weak_chained_friend and q(slash,"isKindOf","NatureSlash") and q(self.player,"isChained") then
					return getJink()
				end
				
				if q(slash,"isKindOf","NatureSlash") and q(self.player,"hasArmorEffect","vine")
					or q(self.player,"hasArmorEffect","renwang_shield")
					or q(self,"hasEightDiagramEffect")
					or q(self,"hasHeavyDamage",target, slash, self.player)
					or (q(self.player,"getHp") == 1 and #self.friends_noself == 0) then
				elseif (q(self,"getCardsNum","Jink") <= getCardsNum("Slash", target, self.player) or q(self.player,"hasSkill","qingnang")) and q(self.player,"getHp") > 1
					or (q(self.player,"hasSkill","jijiu") and getKnownCard(self.player, self.player, "red") > 0)
					or q(self,"canUseJieyuanDecrease",target)
					then
					return not isdummy and "."
				end
			end
		end
	end
	return getJink()
end

sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|fateshilian"
sgs.hit_skill = sgs.hit_skill .. "|fatejuli"
ai_audited_aliases.register{id="ai_cardneed.fatejuli",registry="ai_cardneed",path={"fatejuli"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}


sgs.ai_skill_cardask["@fatejuli-jink-2"] = function(self, data, pattern, target)
	local isdummy = type(data) == "number"
	local function getJink()
		if target and q(target,"hasSkill","dahe") and q(self.player,"hasFlag","dahe") then
			for _, card in ipairs(q(self,"getCards","Jink")) do
				if q(card,"getSuit") == sgs.Card_Heart then return q(card,"getId") end
			end
			return "."
		end
		return call(self,"getCardId","Jink") or not isdummy and "."
	end

	local slash
	if type(data)=="table" and type(data.toCardEffect)=="function" then
		local effect = q(data,"toCardEffect")
		slash = effect.card
	else
		slash = q(self,"getEvaluationCard","slash")
	end
	local cards = AIList.new(q(self.player,"getHandcards"))
	if (not target or q(self,"isFriend",target)) and q(slash,"hasFlag","nosjiefan-slash") then return "." end
	if call(self,"standardNullFilter", data, pattern, target) then return "." end
	if not target then return getJink() end
	if not q(self,"hasHeavyDamage",target, slash, self.player) and q(self,"needToLoseHp",self.player, target, slash) then return "." end
	
	if q(self,"ajustDamage",target, nil, 1, slash) <= 0 then return "." end

	if q(slash,"isKindOf","NatureSlash") and q(self.player,"isChained") and q(self,"isGoodChainTarget",self.player, target, nil, nil, slash) then return "." end
	if q(self,"isFriend",target) then
		if call(self,"findLeijiTarget",self.player, 50, target) then return getJink() end
		if q(target,"hasSkill","jieyin") and not q(self.player,"isWounded") and q(self.player,"isMale") and not q(self.player,"hasSkills","leiji|nosleiji|olleiji|jieleiji") then return "." end
		if not q(target,"hasSkill","jueqing") then
			if (q(target,"hasSkill","nosrende") or (q(target,"hasSkill","rende") and not q(target,"hasUsed","RendeCard"))) and q(self.player,"hasSkill","jieming") then return "." end
			if q(target,"hasSkill","pojun") and not q(self.player,"faceUp") then return "." end
			
			if q(target,"hasSkill","BurningLove") and q(slash,"isKindOf","FireSlash") then return "." end
		end
	else
		if q(self,"hasHeavyDamage",target, slash, self.player) then return getJink() end

		local current = call(self.room,"getCurrent")
		if current and q(current,"hasSkill","juece") and q(self.player,"getHp") > 0 then
			local use = false
			for _, card in ipairs(q(self,"getCards","Jink")) do
				if not q(self.player,"isLastHandCard",card, true) then
					use = true
					break
				end
			end
			if not use then return not isdummy and "." end
		end
		if q(self.player,"getHandcardNum") == 1 and q(self,"needKongcheng") then return getJink() end
		if not q(self,"hasLoseHandcardEffective") and not q(self.player,"isKongcheng") then return getJink() end
		if q(target,"hasSkill","mengjin") and not (q(target,"hasSkill","nosqianxi") and q(target,"distanceTo",self.player) == 1) then
			if not q(self,"doDisCard",self.player, "he", true) then return getJink() end
			if q(self.player,"getCards","he"):length() == 1 and not call(self.player,"getArmor") then return getJink() end
			if q(self.player,"hasSkills","jijiu|qingnang") and q(self.player,"getCards","he"):length() > 1 then return "." end
			if q(self,"canUseJieyuanDecrease",target) then return "." end
			if (q(self,"getCardsNum","Peach") > 0 or (q(self,"getCardsNum","Analeptic") > 0 and q(self,"isWeak")))
				and not hasTuntianEffect(self.player, true) and not q(self,"willSkipPlayPhase") then
				return "."
			end
		end
		if q(self.player,"getHp") > 1 and getKnownCard(target, self.player, "Slash") >= 1 and getKnownCard(target, self.player, "Analeptic") >= 1 and q(self,"getCardsNum","Jink") == 1
			and (q(target,"getPhase") < sgs.Player_Play or q(self,"slashIsAvailable",target) and q(target,"canSlash",self.player)) then
			return "."
		end
		if not (q(target,"hasSkill","nosqianxi") and q(target,"distanceTo",self.player) == 1) then
			if q(target,"hasWeapon","axe") then
				if q(target,"hasSkills",sgs.lose_equip_skill) and q(target,"getEquips"):length() > 1 and q(target,"getCards","he"):length() > 2 then return not isdummy and "." end
				if q(target,"getHandcardNum") - q(target,"getHp") > 2 and not q(self,"isWeak") and not q(self,"getOverflow") then return not isdummy and "." end
			elseif q(target,"hasWeapon","blade") then
				
				local has_weak_chained_friend = false
				for _, friend in ipairs(self.friends_noself) do
					if q(friend,"isChained") and q(self,"isWeak",friend) then
						has_weak_chained_friend = true
					end
				end
				if has_weak_chained_friend and q(slash,"isKindOf","NatureSlash") and q(self.player,"isChained") then
					return getJink()
				end
				
				if q(slash,"isKindOf","NatureSlash") and q(self.player,"hasArmorEffect","vine")
					or q(self.player,"hasArmorEffect","renwang_shield")
					or q(self,"hasEightDiagramEffect")
					or q(self,"hasHeavyDamage",target, slash, self.player)
					or (q(self.player,"getHp") == 1 and #self.friends_noself == 0) then
				elseif (q(self,"getCardsNum","Jink") <= getCardsNum("Slash", target, self.player) or q(self.player,"hasSkill","qingnang")) and q(self.player,"getHp") > 1
					or (q(self.player,"hasSkill","jijiu") and getKnownCard(self.player, self.player, "red") > 0)
					or q(self,"canUseJieyuanDecrease",target)
					then
					return not isdummy and "."
				end
			end
		end
	end
	return getJink()
end

sgs.ai_skill_invoke.fateshilian = function(self, data)
 	return true
end

sgs.ai_hasBuquEffect_skill.fateshilian = function(player)
	return q(player,"getMaxHp") > 3
end


sgs.ai_skill_invoke.fatemoli = function(self, data)
	local baba = call(self.room,"findPlayerBySkillName","fatejiezhi")
    if baba and q(self,"isEnemy",baba) then
        return false
    else
		return true
	end
end



local fateloli_skill={}
fateloli_skill.name="fateloli_vs"
table.insert(package_skills,fateloli_skill)
fateloli_skill.getTurnUseCard=function(self,inclusive,request)
    if not q(self.player,"hasUsed","#fateloli_card") then
		return parse(self,request,"#fateloli_card:.:")
	end
end


sgs.ai_skill_use_func["#fateloli_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"isKongcheng") then
				use.card=final_parse(self,request,"#fateloli_card:.:") 
				if use.to then
					call(use.to,"append",enemy)
				end
				return
			end
		end
end

sgs.ai_use_priority["fateloli_card"] = 9.2
sgs.ai_card_intention["fateloli_card"] = 50

sgs.ai_skill_askforag["fateloli_vs"] = function(self, card_ids)
	local target = context_player(self,"fate_loli_target")
	if not target or q(self,"isFriend",target) then return -1 end
	local nextAlive = self.player
	repeat
		nextAlive = q(nextAlive,"getNextAlive")
	until q(nextAlive,"faceUp")

	local peach, ex_nihilo, jink, nullification, slash
	local valuable
	for _, id in ipairs(card_ids) do
		local card = disclosed(self,id)
		if q(card,"isKindOf","Peach") then peach = id end
		if q(card,"isKindOf","ExNihilo") then ex_nihilo = id end
		if q(card,"isKindOf","Jink") then jink = id end
		if q(card,"isKindOf","Nullification") then nullification = id end
		if q(card,"isKindOf","Slash") then slash = id end
	end
	valuable = peach or ex_nihilo or jink or nullification or slash or card_ids[1]
	local card = disclosed(self,valuable)
	if q(self,"isEnemy",target) and q(target,"hasSkill","tuntian") and q(card,"getSuit") == sgs.Card_Heart then
		return valuable
	end

	local willUseExNihilo, willRecast
	if q(self,"getCardsNum","ExNihilo") > 0 then
		local ex_nihilo = call(self,"getCard","ExNihilo")
		if ex_nihilo then
			local dummy_use = q(self,"aiUseCard",ex_nihilo, dummy())
			if dummy_use.card then willUseExNihilo = true end
		end
	elseif q(self,"getCardsNum","IronChain") > 0 then
		local iron_chain = call(self,"getCard","IronChain")
		if iron_chain then
			local dummy_use = q(self,"aiUseCard",iron_chain, dummy())
			if dummy_use.card and q(dummy_use.to,"isEmpty") then willRecast = true end
		end
	end
	if willUseExNihilo or willRecast then
		local card = disclosed(self,valuable)
		if q(card,"isKindOf","Peach") then
			return valuable
		end
		if q(card,"isKindOf","TrickCard") or q(card,"isKindOf","Indulgence") or q(card,"isKindOf","SupplyShortage") then
			local dummy_use = q(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return valuable
			end
		end
		if q(card,"isKindOf","Jink") and q(self,"getCardsNum","Jink") == 0 then
			return valuable
		end
		if q(card,"isKindOf","Nullification") and q(self,"getCardsNum","Nullification") == 0 then
			return valuable
		end
		if q(card,"isKindOf","Slash") and q(self,"slashIsAvailable") then
			local dummy_use = q(self,"aiUseCard",card, dummy())
			if dummy_use.card then
				return valuable
			end
		end
		return valuable
	end

	if q(self,"isFriend",nextAlive) and not q(self,"willSkipDrawPhase",nextAlive) and not q(self,"willSkipPlayPhase",nextAlive)
		and not q(nextAlive,"hasSkill","luoshen")
		and not q(nextAlive,"hasSkill","tuxi") and not (q(nextAlive,"hasSkill","qiaobian") and q(nextAlive,"getHandcardNum") > 0) then
		if (peach and valuable == peach) or (ex_nihilo and valuable == ex_nihilo) then
			return valuable
		end
		if jink and valuable == jink and getCardsNum("Jink", nextAlive) < 1 then
			return valuable
		end
		if nullification and valuable == nullification and getCardsNum("Nullification", nextAlive) < 1 then
			return valuable
		end
		if slash and valuable == slash and q(self,"hasCrossbowEffect",nextAlive) then
			return valuable
		end
	end
	return valuable
end

sgs.ai_skill_discard["fateduoluo"] = function(self, discard_num, min_num, optional, include_equip)
	local current = call(self.room,"getCurrent")
	local handcards = AIList.new(q(self.player,"getCards","h"))
	sort_keep(self,handcards)
	local to_discard = {}
	for _,c in ipairs(handcards) do
		if not q(c,"isKindOf","Peach")
		
		and not q(c,"isKindOf","Analeptic")
		then
			if #to_discard < min_num then
				table.insert(to_discard, q(c,"getEffectiveId"))
			end
		end
	end
	if #to_discard == min_num then
		return to_discard
	end
	return {}
end

sgs.need_kongcheng = sgs.need_kongcheng .. "|fatenixi"


sgs.ai_view_as.fateyanfan_vs = function(card, player, card_place)
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    if q(card,"getSuit")== sgs.Card_Diamond and not q(card,"isKindOf","Peach") then
        return material(card,"slash","fateyanfan_vs")
    end
	if q(card,"getSuit")== sgs.Card_Club then
        return material(card,"jink","fateyanfan_vs")
    end
end

local fateyanfan_vs_skill={}
fateyanfan_vs_skill.name="fateyanfan_vs"
table.insert(package_skills,fateyanfan_vs_skill)
fateyanfan_vs_skill.getTurnUseCard=function(self,inclusive,request)
    local cards = q(self.player,"getCards","he")
    cards=AIList.new(cards)
    
    local diamond_card
    
    sort_use(self,cards,true)
    
    for _,card in ipairs(cards) do
        if q(card,"getSuit")== sgs.Card_Diamond and not q(card,"isKindOf","Slash") and not q(card,"isKindOf","Peach") 				
            and ((q(self,"getUseValue",card)<sgs.ai_use_value.Slash) or inclusive) then
            diamond_card = card
            break
        end
    end

    if diamond_card then		
        local suit = q(diamond_card,"getSuitString")
        local number = q(diamond_card,"getNumberString")
        local card_id = q(diamond_card,"getEffectiveId")
        local card_str = ("slash:fateyanfan_vs[%s:%s]=%d"):format(suit, number, card_id)
        local slash = parse(self,request,card_str)
        
        assert(slash)
        
        return slash
    end
end

sgs.Kojirou_suit_value = 
{
    diamond = 3.9,
    club = 4.8
}

sgs.double_slash_skill = sgs.double_slash_skill .. "|fatexunjie"


sgs.ai_skill_invoke.fateshenghai = function(self, data)
	return true
end

sgs.ai_ajustdamage_to.fateshenghai = function(self, from, to, card, nature)
	if q(to,"getMark","&fateshenghai") > 0 
	then
		return -99
	end
end

sgs.ai_can_damagehp.fateshenghai = function(self, from, card, to)
	if from and q(to,"getHp") - q(self,"ajustDamage",from, to, 1, card) == 0
		and q(self,"canLoseHp",from, card, to) and q(self,"getAllPeachNum") > 0
	then
		return q(to,"getPhase") == sgs.Player_NotActive
	end
end

local fateheijian_skill={}
fateheijian_skill.name="fateheijian"
table.insert(package_skills,fateheijian_skill)
fateheijian_skill.getTurnUseCard=function(self,inclusive,request)
	if not q(self.player,"hasUsed","#fateheijian_card") and not q(self.player,"isKongcheng") and (q(self.player,"getPile","fateheijiancards")):length() < 5 then
	    local cards = q(self.player,"getCards","h")
	    cards = AIList.new(cards)
	    sort_keep(self,cards)
	    for _, c in ipairs(cards) do
			if q(c,"isBlack") and not (q(c,"isKindOf","Nullification") and q(self,"getCardsNum","Nullification") == 1 and q(self.player,"getHp") > 1) then 
	    		return parse(self,request,"#fateheijian_card:" .. q(c,"getEffectiveId")..":") 
	    	end
	    end
	end
end

sgs.ai_skill_use_func["#fateheijian_card"]=function(card,use,self,request)
	use.card=card
	if use.to then
		call(use.to,"append",self.player)
	end
end

sgs.ai_skill_invoke["fateheijianDamage"] = function(self, data)
	
	local damage = q(data,"toDamage")
	if q(self,"isFriend",damage.to) then return false end
	if q(damage.to,"getHp")<3 then return true end
	if q(self.player,"getHp") == 1 then return false end

	if ((q(self.player,"getPile","fateheijiancards")):length() < 2)  and (q(self,"getCardsNum","Jink") == 0) then 
		return false
	end
	return true	
end

sgs.ai_skill_invoke["fateheijianDefense"] = function(self, data)
	if q(self,"getCardsNum","Peach") < 2 then 
		return true
	end		
end

function sgs.ai_cardneed.fateheijian(to,card)
	return q(to,"getPile","fateheijiancards"):length() < 2 and q(card,"isBlack")
end

sgs.ai_skill_invoke["fateheijianJianpai"] = function(self, data)
	return true		
end

sgs.Kirei_suit_value = 
{
	spade = 2.7,
	club = 2.7
}



sgs.ai_skill_invoke["fatefanji"] = function(self, data, pattern, target)
	
	if q(self,"getCardsNum","Slash") == 0 then 
		return false
	end
	local cur = call(self.room,"getCurrent") 
	

	
	if q(self,"isFriend",cur) then return false end
	return true
end

local fatefanshi_skill={}
fatefanshi_skill.name="fatefanshi"
table.insert(package_skills,fatefanshi_skill)
fatefanshi_skill.getTurnUseCard=function(self,inclusive,request)
    if not q(self.player,"hasUsed","#fatefanshi_card") then
		return parse(self,request,"#fatefanshi_card:.:")
	end
end

sgs.ai_skill_use_func["#fatefanshi_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
		for _, enemy in ipairs(self.enemies) do
			if q(self,"objectiveLevel",enemy) > 3 and q(self.player,"distanceTo",enemy) <= q(self.player,"getAttackRange") then
				use.card=final_parse(self,request,"#fatefanshi_card:.:") 
				if use.to then
					call(use.to,"append",enemy)
				end
				return
			end
		end
end

sgs.ai_use_priority["#fatefanshi_card"] = 2.2
sgs.ai_card_intention["#fatefanshi_card"] = 100


local fatexinyin_skill={}
fatexinyin_skill.name="fatexinyin"
table.insert(package_skills,fatexinyin_skill)
fatexinyin_skill.getTurnUseCard=function(self,inclusive,request)
    if not q(self.player,"hasUsed","#fatexinyin_card") then
		return parse(self,request,"#fatexinyin_card:.:")
	end
end

sgs.ai_skill_use_func["#fatexinyin_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
		for _, enemy in ipairs(self.enemies) do
			if q(self,"objectiveLevel",enemy) > 3 and q(self.player,"distanceTo",enemy) <= 1 then
				use.card=final_parse(self,request,"#fatexinyin_card:.:") 
				if use.to then
					call(use.to,"append",enemy)
				end
				return
			end
		end
end

sgs.ai_use_priority["#fatexinyi_card"] = 7
sgs.ai_card_intention["#fatexinyi_card"] = 80

sgs.ai_skill_choice.fatexinyin_card=function(self,choices)
	return "xychoice1"
end

sgs.straight_damage_skill = sgs.straight_damage_skill .. "|fatexinyin"


sgs.ai_skill_invoke["fateqingxing"] = function(self, data)
	
	
	
	local cards = q(self.player,"getCards","he")
	local i=0
	cards = AIList.new(cards)
	for _, c in ipairs(cards) do
		if q(c,"getSuit")==sgs.Card_Heart or q(c,"isKindOf","Jink")then 
	    		i=i+1
	    end
	end
	if i==0 then return false end
	local player = call(self.room,"getCurrent")
	if not q(self,"isFriend",player) then return false end
	local judges = q(player,"getJudgingArea") 
	if q(player,"hasSkill","fateqingxing") then 
		if q(player,"isWounded") and q(player,"getMark","@fatebimie")==0 then
			return true
		end
		if not q(judges,"isEmpty") then
			if q(self,"hasWizard",self.enemies) then return true end 
			for _,cd in sgs.qlist(judges) do
				if not q(cd,"isKindOf","Lightning") then return true end 
			end
		else 
			return false 
		end
	end
	if (q(player,"getHp") < 2 and q(player,"isWounded")) and q(player,"getMark","@fatebimie")==0 then return true end
	local cards = q(self.player,"getCards","he")
    cards=AIList.new(cards)
    local card
	local i=0
    sort_use(self,cards,true)
    for _,acard in ipairs(cards)  do
        if (q(acard,"getSuit") == sgs.Card_Heart) then 
			i=i+1
		end
    end
	if (q(player,"getHp") < 3 and q(player,"isWounded") and (q(self,"getCardsNum","Jink")+ i> 1)) then return true end
	return false
end

sgs.ai_skill_cardask["@fateqingxing1"] = function(self, data, pattern, target)
	local cards = q(self.player,"getCards","he")
	local i=0
	cards = AIList.new(cards)
	sort_use(self,cards, true)
	local heart = {}
	for _, c in ipairs(cards) do
		if q(c,"getSuit")==sgs.Card_Heart or q(c,"isKindOf","Jink")then 
	    		i=i+1
				table.insert(heart, q(c,"getEffectiveId"))
	    end
	end
	if i==0 then return "." end
	local player = call(self.room,"getCurrent")
	if not q(self,"isFriend",player) then return "." end
	local judges = q(player,"getJudgingArea") 
	if q(player,"hasSkill","fateqingxing") then 
		if q(player,"isWounded") and q(player,"getMark","@fatebimie")==0 then
			return "$" .. heart[1]
		end
		if not q(judges,"isEmpty") then
			if q(self,"hasWizard",self.enemies) then return "$" .. heart[1] end 
			for _,cd in sgs.qlist(judges) do
				if not q(cd,"isKindOf","Lightning") then return "$" .. heart[1] end 
			end
		else 
			return "." 
		end
	end
	if (q(self,"isWeak",player) and q(player,"isWounded")) and q(player,"getMark","@fatebimie")==0 then return  "$" .. heart[1] end
	local cards = q(self.player,"getCards","he")
    cards=AIList.new(cards)
    local card
	local i=0
    sort_use(self,cards,true)
    for _,acard in ipairs(cards)  do
        if (q(acard,"getSuit") == sgs.Card_Heart) then 
			i=i+1
		end
    end
	if q(self,"needToThrowArmor") and call(self.player,"getArmor"):getSuit() == sgs.Card_Heart then
		return "$" .. call(self.player,"getArmor") 
	end
	if ((not q(judges,"isEmpty") or  q(player,"getHp") < q(self,"getBestHp",player)) and (q(self,"getCardsNum","Jink")+ i> 1)) then return  "$" .. heart[1] end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["@fateqingxing1"] = function(self,player,promptlist)
	if promptlist[#promptlist]~="" then
		local current = call(self.room,"getCurrent")
		if not current then return end
		call(self,"updateIntention",player,current,-80)
	end
end

sgs.ai_armor_value.fatejizhi = function(player,self,card)
	if not card then return 4 end
end
sgs.ai_card_priority.fatejizhi = function(self,card,v)
    if self.useValue
	and q(card,"isKindOf","Armor")
	then v = 2 end
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|fateqingxing"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|fateqingxing"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|fatebumo"

sgs.Rin_suit_value = 
{
	heart = 6
}

sgs.Rin_keep_value = 
{
    Jink = 6.5
}

function sgs.ai_cardneed.fateqingxing(to, card, self)
	return (q(card,"getSuit")==sgs.Card_Heart or q(card,"isKindOf","Jink")) and he_count(to) < 4
end

local fatebumo_skill={}
fatebumo_skill.name="fatebumo"
table.insert(package_skills,fatebumo_skill)
fatebumo_skill.getTurnUseCard=function(self,inclusive,request)
    if (q(self.player,"getMark","@bumo_mark")>0) and (q(self.player,"isWounded") or q(self.player,"getHandcardNum") < q(self.player,"getMaxHp")) then
    	return parse(self,request,"#fatebumo_card:.:")
	end
end

sgs.ai_skill_use_func["#fatebumo_card"]=function(card,use,self,request)
    sort_players(self,self.friends_noself, "hp")
    local lord = call(self.room,"getLord")
    if q(self,"isFriend",lord) and not q(self,"isLordHealthy")  and q(lord,"isMale") and q(lord,"isWounded") then
        use.card=card
        if use.to then call(use.to,"append",lord) end
        return
    end
    for _, friend in ipairs(self.friends_noself) do
        if q(friend,"getGender")~=q(self.player,"getGender") and q(self,"isWeak",friend) and (q(friend,"getSeat") - q(self.player,"getSeat")) % (q(self.room,"alivePlayerCount")) < 3 then 
            use.card=card
            if use.to then call(use.to,"append",friend) end
            return
        end
    end
end



local fatechuyi_vs_skill={}
fatechuyi_vs_skill.name="fatechuyi_vs"
table.insert(package_skills,fatechuyi_vs_skill)
fatechuyi_vs_skill.getTurnUseCard=function(self,inclusive,request)
    if q(self.player,"getHandcardNum")<2 then return nil end
    if q(self.player,"hasUsed","#fatechuyi_card") then return nil end
    
    local cards = q(self.player,"getHandcards")
    cards=AIList.new(cards)
    
    local first, second
    sort_use(self,cards,true)
    for _, card in ipairs(cards) do
        if q(card,"getTypeId") ~= sgs.Card_Equip then
            if not first then first  = cards[1]:getEffectiveId()
            else second = cards[2]:getEffectiveId()
            end
        end
        if second then break end
    end
    
    if not second then return end
    local card_str = ("#fatechuyi_card:%d+%d:"):format(first, second)
    assert(card_str)
    return parse(self,request,card_str)
end

sgs.ai_skill_use_func["#fatechuyi_card"]=function(card,use,self,request)
    sort_players(self,self.friends_noself, "defense")
    local lord = call(self.room,"getLord")
    if q(self,"isFriend",lord) and not q(self,"isLordHealthy") and q(lord,"isWounded") then
        use.card=card
        if use.to then call(use.to,"append",lord) end
        return
    end	
    for _, friend in ipairs(self.friends_noself) do
        if q(friend,"isWounded") and
            not (q(friend,"hasSkill","longhun") and q(self,"getAllPeachNum") > 0) and
            not (q(friend,"hasSkill","hunzi") and q(friend,"getMark","hunzi") == 0 and q(self,"getAllPeachNum") > 1) then
            use.card=card
            if use.to then call(use.to,"append",friend) end
            return
        end
    end
	if q(self,"getOverflow")>0 then 
		sort_players(self,self.friends_noself, "handcard")
		for _, friend in ipairs(self.friends_noself) do 
      		if not (q(friend,"hasSkill","kongcheng") and q(friend,"isKongcheng")) then
        	    use.card=card
        	    if use.to then call(use.to,"append",friend) end
        	    return
        	end
    	end
	end
end

sgs.ai_use_priority.fatechuyi_card = 4.2
sgs.ai_card_intention.fatechuyi_card = -200
sgs.dynamic_value.benefit.fatechuyi_card = true

sgs.ai_skill_invoke["fatexinengloseHP"] = function(self, data)
	local next_player = q(self.player,"getNextAlive")
	if not q(self,"isFriend",next_player) then return true end 
	return false
end





local fateyaoshu_skill={}
fateyaoshu_skill.name="fateyaoshu"
table.insert(package_skills,fateyaoshu_skill)
fateyaoshu_skill.getTurnUseCard=function(self,inclusive,request)
	local first_found, second_found = false, false
	local first_card, second_card
	if q(self.player,"getHandcardNum") >= 2 then
		local cards = q(self.player,"getHandcards")
		local same_suit=false
		cards = AIList.new(cards)
		for _, fcard in ipairs(cards) do
			if not (q(fcard,"isKindOf","Peach") or q(fcard,"isKindOf","ExNihilo")) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and q(scard,"getSuitString") == q(first_card,"getSuitString") and 
						not (q(scard,"isKindOf","Peach") or q(scard,"isKindOf","ExNihilo")) then 
						second_card = scard
						second_found = true
						break
					end
				end
				if second_card then break end
			end
		end
	end
	if first_found and second_found then
		local card_str = "#fateyaoshu:.:"
		assert(card_str)
    	return parse(self,request,card_str)
	end
end

sgs.ai_skill_use_func["#fateyaoshu"]=function(card,use,self,request)
	local first_found, second_found = false, false
	local first_card, second_card
	if q(self.player,"getHandcardNum") >= 2 then
		local cards = q(self.player,"getHandcards")
		local same_suit=false
		cards = AIList.new(cards)
		for _, fcard in ipairs(cards) do
			if not (q(fcard,"isKindOf","Peach") or q(fcard,"isKindOf","ExNihilo")) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and q(scard,"getSuitString") == q(first_card,"getSuitString") and 
						not (q(scard,"isKindOf","Peach") or q(scard,"isKindOf","ExNihilo")) then 
						second_card = scard
						second_found = true
						break
					end
				end
				if second_card then break end
			end
		end
	end
	if first_found and second_found then
		local first_suit, first_id = q(first_card,"getSuit"), q(first_card,"getEffectiveId")
		local second_suit, second_id = q(second_card,"getSuit"), q(second_card,"getEffectiveId")
		local card_str = ("#fateyaoshu:%d+%d:"):format(first_id, second_id)
		if first_suit == sgs.Card_Diamond then 
			use.card=final_parse(self,request,card_str)
			if use.to then call(use.to,"append",self.player) end
			return
		elseif first_suit == sgs.Card_Spade then 
			local target
			for _,friend in ipairs(self.friends)do
				if not q(friend,"faceUp") then
						target = friend
					break
				end
				if not target then
					if not q(self,"toTurnOver",friend,0,"fateyaoshu") then
						target = friend
						break
					end
				end
			end
			sort_players(self,self.enemies)
			for _,enemy in ipairs(self.enemies)do
				if q(self,"toTurnOver",enemy,0,"fateyaoshu") then
					target = enemy
					break
				end
			end
			if not target then
				for _,enemy in ipairs(self.enemies)do
					if q(self,"toTurnOver",enemy,0,"fateyaoshu") and q(self,"hasSkills",sgs.priority_skill,enemy) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _,enemy in ipairs(self.enemies)do
					if q(self,"toTurnOver",enemy,0,"fateyaoshu") then
						target = enemy
						break
					end
				end
			end
			if target then
				use.card=final_parse(self,request,card_str)
				if use.to then call(use.to,"append",target) end
				return
			end
		elseif first_suit == sgs.Card_Heart then 
			local arr1, arr2 = call(self,"getWoundedFriend",false, true)
			local target = nil

			if #arr1 > 0 and (q(self,"isWeak",arr1[1]) or q(self,"getOverflow") >= 1) and arr1[1]:getHp() < q(self,"getBestHp",arr1[1]) then
				target =
					arr1[1]
			end
			if target then
				use.card=final_parse(self,request,card_str)
				if use.to then call(use.to,"append",target) end
				return 
			end
			if q(self,"getOverflow") > 0 and #arr2 > 0 then
				for _, friend in ipairs(arr2) do
					if not q(friend,"hasSkills","hunzi|longhun") then
						use.card=final_parse(self,request,card_str)
						if use.to then call(use.to,"append",friend) end
						return
					end
				end
			end
		elseif first_suit == sgs.Card_Club  then 
			for _,enemy in sgs.list(self.enemies)do
				if q(self,"objectiveLevel",enemy)>3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder) and q(self,"canDamage",enemy,self.player,nil)
				then
					use.card=final_parse(self,request,card_str)
						if use.to then call(use.to,"append",enemy) end
						return
				end
			end
		end
    	return
	end
end

sgs.ai_skill_use_func["#fateyaoshu1"]=function(card,use,self,request)
	
	if q(self.player,"isWounded") then 
        use.card=card
        if use.to then call(use.to,"append",self.player) end
    end
end

sgs.ai_skill_use_func["#fateyaoshu2"]=function(card,use,self,request)
	sort_players(self,self.enemies, "chaofeng") 
		for _, enemy in ipairs(self.enemies) do
			if q(self,"objectiveLevel",enemy) > 3 and q(enemy,"faceUp") then
				use.card = card 
				if use.to then
					call(use.to,"append",enemy)
				end
				return
			end
		end
		for _, friend in ipairs(self.friends) do
        	if not q(friend,"faceUp") then
				use.card = card 
				if use.to then
					call(use.to,"append",friend)
				end
				return
			end
        end
end


sgs.ai_skill_use_func["#fateyaoshu3"]=function(card,use,self,request)
	-- Source diagnostic-only console text t4 omitted; no RNG or game state.
	use.card=card
	if use.to then
		call(use.to,"append",self.player)
	end
end


sgs.ai_skill_use_func["#fateyaoshu4"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
		for _, enemy in ipairs(self.enemies) do
			if q(self,"getOverflow")<1 and q(enemy,"getHp")>1 then return end 
			if q(self,"objectiveLevel",enemy) > 3 then
				use.card = card 
				if use.to then
					call(use.to,"append",enemy)
				end
				return
			end
		end
end

sgs.ai_use_priority.fateyaoshucard1 = 3.2
sgs.ai_use_priority.fateyaoshucard2 = 10.2
sgs.ai_use_priority.fateyaoshucard3 = 3.1
sgs.ai_use_priority.fateyaoshucard4 = 3.0
sgs.ai_card_intention.fateyaoshucard1 = -150
sgs.ai_card_intention.fateyaoshucard3 = 70

sgs.ai_ajustdamage_to.fatefapao = function(self, from, to, card, nature)
	if nature ~= "N"
	then
		return -99
	end
end



local fateluanshe_vs_skill={}
fateluanshe_vs_skill.name="fateluanshe_vs"
table.insert(package_skills,fateluanshe_vs_skill)
fateluanshe_vs_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"usedTimes","ArcheryAttack")>0 then return nil end
    local cards = q(self.player,"getCards","h")
    cards=AIList.new(cards)
    local heart_card
    sort_use(self,cards,true)
    for _,card in ipairs(cards) do
        if q(card,"getSuit")== sgs.Card_Heart then
            heart_card = card
            break
        end
    end
	if heart_card then	
        local suit = q(heart_card,"getSuitString")
        local number = q(heart_card,"getNumberString")
        local card_id = q(heart_card,"getEffectiveId")
        local card_str = ("archery_attack:fateluanshe_vs[%s:%s]=%d"):format(suit, number, card_id)
        local aa = parse(self,request,card_str)
        assert(aa)
        return aa
    end
end

sgs.ai_skill_cardask["@fatechuanxin1"] = function(self, data, pattern, target, target2)
	if #self.enemies == 0 then return "." end
	local card = AIList.new(q(self.player,"getHandcards"))
	if #card == 0 then return "." end
	if sgs.ai_skill_playerchosen.zero_card_as_slash(self, q(self.room,"getOtherPlayers",self.player)) ~= nil then
		sort_keep(self,card)
		return "$"..card[1]:getEffectiveId()
	end
	return "."
end
ai_audited_aliases.register{id="ai_skill_playerchosen.@fatechuanxin2",registry="ai_skill_playerchosen",path={"@fatechuanxin2"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1,defer_canonical=true}
sgs.Gilgamesh_suit_value = 
{
	heart = 7
}

sgs.Gilgamesh_use_value = 
{
	ArcheryAttack = 10
}
sgs.double_slash_skill = sgs.double_slash_skill .. "|fateluanshe_vs"
sgs.double_slash_skill = sgs.double_slash_skill .. "|fatechuanxin_trs"











ai_audited_aliases.register{id="ai_cardneed.fateguangbo",registry="ai_cardneed",path={"fateguangbo"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.ai_skill_invoke.fateguangbo = function(self, data)
	return true
end

sgs.ai_skill_choice.fateguangbo=function(self,choices)
	if q(self,"getCardsNum","Slash") > 1 then return "fateguangbo3" end
	local hasweapon = false
	local weapon = call(self.player,"getWeapon")
	
	if weapon then 
		hasweapon = true
	else 
		local cards = q(self.player,"getHandcards")
		for _, card in sgs.qlist(cards) do
			if q(card,"isKindOf","Weapon") then
				hasweapon = true
				break
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(enemy,"getMark","@fog") < 1 and q(enemy,"getMark","@fateshenghai") < 1
		and q(enemy,"getMark","@fatesakura_mark") < 1 and q(self,"canDamage",enemy,self.player,nil) then
			if (hasweapon or (q(enemy,"getHp")==1 and q(self.player,"getHp")>2)) and q(self.player,"distanceTo",enemy) <=1 then
				return "fateguangbo2"
			end
		end
	end
	
	local cards = q(self.player,"getCards","h")
	local blacknum = 0
	for _, card in sgs.qlist(cards) do
		if q(card,"isBlack") then
			blacknum = blacknum + 1
		end
	end
	if blacknum > 1 then return "fateguangbo4" end
	
	if q(self,"getCardsNum","Slash") > 0 then return "fateguangbo3" end
	
	for _, enemy in ipairs(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(enemy,"getMark","@fog") < 1 and q(enemy,"getMark","@fateshenghai") < 1
		and q(enemy,"getMark","@fatesakura_mark") < 1 and q(self,"canDamage",enemy,self.player,nil) then
			if q(self.player,"distanceTo",enemy) <= q(self.player,"getAttackRange") then
					return "fateguangbo5"
			end
		end
	end
	
	local cards = q(self.player,"getCards","he")
	for _, card in sgs.qlist(cards) do
		if q(card,"isBlack") then
			return "fateguangbo4"
		end
	end
	return "fateguangbo3"
end


sgs.ai_skill_invoke.fatetuji = function(self, data)
	return q(self,"isWeak") or q(self.room,"getTurnCount") > 1
end



sgs.wizard_skill = sgs.wizard_skill .. "|fateshengqi"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|fateshengqi"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|fateshengqi"

function sgs.ai_cardneed.fateshengqi(to,card,self)
	for _,player in sgs.qlist(q(self.room,"getAllPlayers"))do
		if q(self,"getFinalRetrial",to)==1 then
			if q(self,"isFriend",player) and q(self,"willSkipPlayPhase",player) then
				return q(card,"getSuit")==sgs.Card_Heart and q(self,"hasSuit","heart",true,to)
			end
		end
	end
end


sgs.ai_skill_cardask["@fateshengqi-card"]=function(self, data)
	local judge = q(data,"toJudge")
	local all_cards = q(self.player,"getCards","he")
	
	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			call(all_cards,"prepend",disclosed(self,id))
		end
	end
	
	if q(all_cards,"isEmpty") then return "." end

	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if q(card,"isRed") and not q(card,"hasFlag","using") then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end

	local card_id = q(self,"getRetrialCardId",cards, judge)
	if card_id == -1 then
		if q(self,"needRetrial",judge) and judge.reason ~= "beige" then
			if q(self,"needToThrowArmor") and call(self.player,"getArmor"):isRed() then return "$" .. call(self.player,"getArmor"):getEffectiveId() end
			sort_use(self,cards, true)
			if q(self,"getUseValue",judge.card) > q(self,"getUseValue",cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif q(self,"needRetrial",judge) or q(self,"getUseValue",judge.card) > q(self,"getUseValue",disclosed(self,card_id)) then
		local card = disclosed(self,card_id)
		return "$" .. card_id
	end

	return "."
end


sgs.ai_skill_invoke["fatehuyoubad"] = function(self, data)


	



	





	return true
end

sgs.ai_skill_playerchosen["#fatehuyoubad_target"] = function(self, targets) 
	local choices = {}
	for _, target in sgs.qlist(targets) do
		if q(self,"isEnemy",target) then
			table.insert(choices, target)
		end
	end
	if #choices == 0 then
		for _, target in sgs.qlist(targets) do
			if not q(self,"isFriend",target) then
				table.insert(choices, target)
			end
		end
		sort_players(self,choices, "hp", true) 
		return choices[1] 
	end
	sort_players(self,choices, "hp")
	return choices[1]
end

sgs.ai_skill_invoke["fatehuyougood"] = function(self, data)
	for _, friend in ipairs(self.friends_noself) do  
        if q(friend,"getLostHp") > 0 and q(self.player,"getLostHp")==0 then 
            return true
        end
    end
	return false
end

sgs.ai_skill_playerchosen["#fatehuyougood_target"] = function(self, targets)
	local choices = {}
	for _, target in sgs.qlist(targets) do
		if q(self,"isFriend",target) then
			table.insert(choices, target)
		end
	end
	sort_players(self,choices, "hp")
	return choices[1]
end

sgs.ai_skill_playerchosen["fatehuyou"] = function(self, targets) 
	local targets = AIList.new(targets)
	local effect = context_effect(self,"fate_huyou_effect")
	local card = effect.card
	local target
	if q(card,"isKindOf","AmazingGrace") or q(card,"isKindOf","ExNihilo") or q(card,"isKindOf","EXCard_YJJG") then
		for _, friend in ipairs(self.friends) do
			if q(friend,"hasSkills",sgs.cardneed_skill) and not q(self,"needKongcheng",friend, true) and not q(self,"hasManjuanEffect",friend) and q(self,"hasTrickEffective",card, effect.from, friend) 
			and q(self.player,"getHandcardNum") > 	q(friend,"getHandcardNum")	and table.contains(targets, friend)	then
				return friend
			end
		end
		return nil
	elseif  q(card,"isKindOf","EXCard_TJBZ") then
		return nil
	elseif q(card,"isKindOf","EXCard_YYDL")  then
		for _, friend in ipairs(self.friends) do
			if (q(self,"hasSkills",sgs.lose_equip_skill, friend) or q(self,"needToThrowArmor",friend)) and not q(self,"hasManjuanEffect",friend) and q(self,"hasTrickEffective",card, effect.from, friend) and table.contains(targets, friend) 	then
				return friend
			end
		end
		return nil
	elseif q(card,"isKindOf","GodSalvation") then
		local lord = call(self.room,"getLord")
		if q(self,"isWeak",lord) and q(self.player,"getRole") == "loyalist" and q(self,"hasTrickEffective",card, effect.from, lord)  and table.contains(targets, lord) then
			return lord
		end
		sort_players(self,self.friends, "hp")
		if q(self,"isWeak") and q(self,"hasTrickEffective",card, effect.from, self.player)  then
			return nil
		else
			for _, target in ipairs(self.friends) do
				if q(self,"hasTrickEffective",card, effect.from, target) and q(target,"getHp") < q(self,"getBestHp",target)   and table.contains(targets, target) then
					return target
				end
			end
		end
		return nil
	elseif  q(card,"isKindOf","Duel") or q(card,"isKindOf","FireAttack") or q(card,"isKindOf","EXCard_WWJZ") then
		local nature = sgs.DamageStruct_Normal
		if q(card,"isKindOf","FireAttack") then
			nature = sgs.DamageStruct_Fire
		end
		sort_players(self,self.enemies, "hp")
		sort_players(self,self.friends, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"hasSkills",sgs.masochism_skill) and q(self,"hasTrickEffective",card, effect.from, enemy) and not q(self,"cantbeHurt",enemy) and q(self,"canDamage",enemy,effect.from,nil) and q(self,"damageIsEffective",enemy, nature) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"hasSkills",sgs.masochism_skill) and q(self,"hasTrickEffective",card, effect.from, enemy) and not q(self,"cantbeHurt",enemy) and q(self,"canDamage",enemy,effect.from,nil) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
		for _, friend in ipairs(self.friends) do
			if ((q(friend,"hasSkills",sgs.masochism_skill) or q(self,"needToLoseHp",friend, effect.from, card,false)) and not q(self,"isWeak",friend)) or not q(self,"hasTrickEffective",card, effect.from, friend) or not q(self,"damageIsEffective",friend, nature)  and  table.contains(targets, friend) then
				return friend
			end
		end
		return targets[1]
	elseif  q(card,"isKindOf","ArcheryAttack") or q(card,"isKindOf","SavageAssault") then
		local nature = sgs.DamageStruct_Normal
		if q(card,"isKindOf","FireAttack") then
			nature = sgs.DamageStruct_Fire
		end
		sort_players(self,self.enemies, "hp")
		sort_players(self,self.friends, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"hasSkills",sgs.masochism_skill) and q(self,"hasTrickEffective",card, effect.from, enemy) and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, nature) and q(self,"canDamage",enemy,effect.from,nil) and not q(enemy,"hasArmorEffect","vine") and  table.contains(targets, enemy) 	then
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"hasSkills",sgs.masochism_skill) and q(self,"hasTrickEffective",card, effect.from, enemy) and not q(self,"cantbeHurt",enemy)  and not q(enemy,"hasArmorEffect","vine") and q(self,"canDamage",enemy,effect.from,nil)	and  table.contains(targets, enemy) then
				return enemy
			end
		end
		for _, friend in ipairs(self.friends) do
			if (((q(friend,"hasSkills",sgs.masochism_skill) or q(self,"needToLoseHp",friend, effect.from, card,false)) and not q(self,"isWeak",friend)) or not q(self,"hasTrickEffective",card, effect.from, friend) or not q(self,"damageIsEffective",friend, nature) or  q(friend,"hasArmorEffect","vine")) and  table.contains(targets, friend) then
				return friend
			end
		end
		return targets[1]
	elseif q(card,"isKindOf","Collateral") then
		sort_players(self,self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if not (q(self,"hasSkills",sgs.lose_equip_skill, enemy) and call(enemy,"getWeapon")) and q(self,"hasTrickEffective",card, effect.from, enemy) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif q(card,"isKindOf","Dismantlement")  or q(card,"isKindOf","Snatch") then
		if q(self,"isFriend",effect.from) and (q(self.player,"getJudgingArea"):length() > 0 or q(self,"hasSkills",sgs.lose_equip_skill, self.player)) and q(self,"hasTrickEffective",card, effect.from, self.player) then
			return nil
		end
			if q(card,"isKindOf","Dismantlement") then
				sort_players(self,self.enemies, "handcard")
				for _, enemy in ipairs(self.enemies) do
					if q(self,"doDisCard",enemy) and q(self,"hasTrickEffective",card, effect.from, enemy) and  table.contains(targets, enemy)	then
						return enemy
					end
				end
				for _, enemy in ipairs(self.enemies) do
					if  q(self,"hasTrickEffective",card, effect.from, enemy) and  table.contains(targets, enemy)	then
						return enemy
					end
				end
			end
	elseif q(card,"isKindOf","GodFlower") or q(card,"isKindOf","Snatch") then
		sort_players(self,self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if q(self,"isEnemy",effect.from) and q(self,"hasTrickEffective",card, effect.from, enemy) and (q(enemy,"getJudgingArea"):length() < 1 or not q(self,"hasSkills",sgs.lose_equip_skill, enemy)) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif q(card,"isKindOf","IronChain") then
		for _, friend in ipairs(self.friends) do
			if q(self,"hasTrickEffective",card, effect.from, friend) and q(friend,"isChained")  and  table.contains(targets, friend) then
				return friend
			end
		end
		
		for _, enemy in ipairs(self.enemies) do
			if  q(self,"hasTrickEffective",card, effect.from, enemy)  and  table.contains(targets, enemy) and not q(enemy,"isChained")	then
				return enemy
			end
		end
	end
	
	return nil
end

sgs.ai_target_revises.fatehuyou = function(to,card,self)
	if q(self,"isFriend",to,self.player) then return false end
	if #self.friends_noself == 0 then return false end
	for _,friend in ipairs(q(self,"getFriends",self.player, true))do
		if q(to,"canSlash",friend,card) and q(self,"slashIsEffective",card,friend,self.player) then return q(card,"isNDTrick") and self.player~=to end
	end
	return q(card,"isNDTrick") and self.player~=to
end

sgs.Irisviel_suit_value = 
{
	heart = 3.9,
	diamond = 3.8
}



sgs.ai_skill_invoke.fatejiejie = function(self, data)
	local effect = q(data,"toCardEffect")
	if effect.card and q(effect.card,"hasFlag","NosJiefanUsed") then return false  end

	if not effect.from or call(self,"standardNullFilter",data,pattern,effect.from)
		or q(effect.card,"isKindOf","NatureSlash") and q(self.player,"isChained") and q(self,"isGoodChainTarget",self.player,effect.card,effect.from)
		or q(self,"needToLoseHp",self.player,effect.from,effect.card) and q(self,"ajustDamage",effect.from,self.player,1,effect.card)==1 then return false end
	if q(self,"needToLoseHp",self.player, effect.from,effect.card, true, true) then return false end
	if q(self,"getCardsNum","Jink") == 0 then return true end
	
	return true
end

local fatemoshu_skill={}
fatemoshu_skill.name="fatemoshu_vs"
table.insert(package_skills,fatemoshu_skill)
fatemoshu_skill.getTurnUseCard=function(self,inclusive,request)
    if q(self.player,"getHandcardNum")<1 then return nil end
    if q(self.player,"hasUsed","#fatemoshu_card") then return nil end
    local cards = q(self.player,"getHandcards")
    cards=AIList.new(cards)
    sort_keep(self,cards)
	local card_str = ("#fatemoshu_card:%d:"):format(cards[1]:getId())
    return parse(self,request,card_str)
end

sgs.ai_skill_use_func["#fatemoshu_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
	for _, enemy in ipairs(self.enemies) do
		if not q(enemy,"isKongcheng") and not q(enemy,"hasSkill","tiandu") and q(self,"doDisCard",enemy, "he") then
			use.card=final_parse(self,request,"#fatemoshu_card:" .. q(card,"getEffectiveId")..":")  
			if use.to then
				call(use.to,"append",enemy)
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if q(self,"getOverflow")>0 then
			if q(self,"doDisCard",enemy, "he") then
				use.card=final_parse(self,request,"#fatemoshu_card:" .. q(card,"getEffectiveId")..":")  
				if use.to then
					call(use.to,"append",enemy)
					return
				end
			end
		end
	end
end

sgs.ai_use_value["fatemoshu_card"] = 7.5
sgs.ai_use_priority["fatemoshu_card"] = 4
sgs.ai_card_intention["fatemoshu_card"] = 70


local fatejuntuan_skill={}
fatejuntuan_skill.name="fatejuntuan_vs"
table.insert(package_skills,fatejuntuan_skill)
fatejuntuan_skill.getTurnUseCard=function(self,inclusive,request)
    if q(self.player,"getHandcardNum")<1 then return nil end
    if q(self.player,"hasUsed","#fatejuntuan_card") then return nil end
	local cards = q(self.player,"getCards","h")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	for _, c in ipairs(cards) do
		if q(c,"isBlack") then 
	   		return parse(self,request,"#fatejuntuan_card:" .. q(c,"getEffectiveId")..":")
	   	end
	end
end

sgs.ai_skill_use_func["#fatejuntuan_card"]=function(card,use,self,request)
	local first
	sort_players(self,self.enemies, "hp") 
	for _, enemy in ipairs(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"canDamage",enemy,self.player,nil) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal,self.player) and q(self.player,"distanceTo",enemy) < 2
		then
			use.card=final_parse(self,request,"#fatejuntuan_card:" .. q(card,"getEffectiveId")..":")  
			if use.to then
				call(use.to,"append",enemy)
				first=enemy
				break
			end
		end
	end
	if first then 
		for _, enemy2 in ipairs(self.enemies) do
			if q(self,"objectiveLevel",enemy2) > 3 and not q(self,"cantbeHurt",enemy2) and q(self,"canDamage",enemy2,self.player,nil)  and q(self,"damageIsEffective",enemy2, sgs.DamageStruct_Normal,self.player) and q(self.player,"distanceTo",enemy2) < 2 and (q(enemy2,"getSeat")~=q(first,"getSeat"))
			then
				call(use.to,"append",enemy2)
				return
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"canDamage",enemy,self.player,nil) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal,self.player) and q(self.player,"distanceTo",enemy) < 2 then
				use.card=final_parse(self,request,"#fatejuntuan_card:" .. q(card,"getEffectiveId")..":")
				if use.to then
					call(use.to,"append",enemy)
					first=enemy
					break
				end
			end
		end
	end
end

sgs.ai_use_value["fatejuntuan_card"] = 8.5
sgs.ai_use_priority["fatejuntuan_card"] = 3
sgs.ai_card_intention["fatejuntuan_card"] = 70

function sgs.ai_cardneed.fatejuntuan_vs(to, card, self)
	return q(card,"isBlack") and he_count(to) < 4
end


sgs.ai_skill_invoke.fatehuwei = function(self, data)
	if #self.friends_noself > 0 then
		return true
	end
	return false
end


sgs.ai_skill_playerchosen["@fatehuwei"] = function(self, targets)
	local choices = {}
	local card = q(self,"getEvaluationCard","savage_assault")
	
	for _, target in sgs.qlist(targets) do
		local armor = call(target,"getArmor")
		if q(self,"isFriend",target)  and q(self,"hasTrickEffective",card, target, self.player)
		and not (armor and q(armor,"isKindOf","Vine")) 
		then
			table.insert(choices, target)
		end
	end
	sort_players(self,choices, "hp")
	return choices[1]
end

sgs.ai_target_revises.fatehuwei = function(to, card)
	if q(card,"isKindOf","SavageAssault")then
		return true
	end
end



sgs.ai_skill_invoke.fatepomo = function(self, data)
	return true
end

sgs.ai_skill_playerchosen["@fatepomo"] = function(self, targets)
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"hasSkill","beige") and not q(enemy,"isNude") then
			return enemy
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"hasSkill","fateduoluo") and q(enemy,"distanceTo",self.player)< 2 then
			return enemy
		end
	end
	sort_players(self,self.enemies, "hp") 
	
	
	
	
	
	
	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"distanceTo",enemy) <= q(self.player,"getAttackRange") and
		(q(enemy,"hasSkill","fatewangzhe") or q(enemy,"hasSkill","fatemoli") or q(enemy,"hasSkill","fateheijian") or q(enemy,"hasSkill","fateyanfan_vs") or q(enemy,"hasSkill","fatehuyou") or q(enemy,"hasSkill","fatejiejie") or q(enemy,"hasSkill","fateqienuo") 
		or q(enemy,"hasSkill","yiji") or q(enemy,"hasSkill","jianxiong") or q(enemy,"hasSkill","fankui") or q(enemy,"hasSkill","qingguo") or q(enemy,"hasSkill","ganglie")
		or q(enemy,"hasSkill","yizhong") or q(enemy,"hasSkill","kongcheng") or q(enemy,"hasSkill","longdan") or q(enemy,"hasSkill","bazhen") or q(enemy,"hasSkill","kanpo")
		or q(enemy,"hasSkill","wuyan") or q(enemy,"hasSkill","liuli") or q(enemy,"hasSkill","tianxiang") or q(enemy,"hasSkill","leiji") or q(enemy,"hasSkill","guhuo")
		or q(enemy,"hasSkill","fangzhu") or q(enemy,"hasSkill","weimu") or q(enemy,"hasSkill","tuntian") or q(enemy,"hasSkill","xiangle") 
		or q(enemy,"hasSkill","fengying") or q(enemy,"hasSkill","guixin") or q(enemy,"hasSkill","juejing") or q(enemy,"hasSkill","longhun") or q(enemy,"hasSkill","renjie")
		or ((q(enemy,"hasSkill","fateshenghai") or q(enemy,"hasSkill","fateshilian") or q(enemy,"hasSkill","huilei") or q(enemy,"hasSkill","zhuiyi") or q(enemy,"hasSkill","jijiu")
		or q(enemy,"hasSkill","buqu") or q(enemy,"hasSkill","duanchang")) and q(enemy,"getHp")<2))
		or call(enemy,"getArmor")~= nil
		then
			return enemy
		end
	end
	
	
	
	
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"hasSkill","fatejiezhi") or q(enemy,"hasSkill","fateshengqi") or q(enemy,"hasSkill","kanpo") or q(enemy,"hasSkill","guicai") or q(enemy,"hasSkill","guidao") 
		or q(enemy,"hasSkill","jijiu") 
		then
			return enemy
		end
	end
	
	
	
	
	
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"hasSkill","fatewangzhe") or q(enemy,"hasSkill","fatehuyou") or q(enemy,"hasSkill","yiji") or q(enemy,"hasSkill","jieming") or q(enemy,"hasSkill","fangzhu") 
		or q(enemy,"hasSkill","ganlu") or q(enemy,"hasSkill","guixin")
		then
			return enemy
		end
	end

	
	
	
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"hasSkill","fatejianzhong") or q(enemy,"hasSkill","fatehuwei") or q(enemy,"hasSkill","fateheijian") or q(enemy,"hasSkill","juxiang") or q(enemy,"hasSkill","jianxiong") 
		or q(enemy,"hasSkill","huoshou") or q(enemy,"hasSkill","weimu") or q(enemy,"hasSkill","tuntian") 
		then
			return enemy
		end
	end
	
	
	
	
	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"distanceTo",enemy) <= q(self.player,"getAttackRange") and
		(q(enemy,"hasSkill","fatejizhi") or q(enemy,"hasSkill","fatefapao") or q(enemy,"hasSkill","fatexianshen") or q(enemy,"hasSkill","wusheng") or q(enemy,"hasSkill","xiaoji") 
		or q(enemy,"hasSkill","yicong") or q(enemy,"hasSkill","zhichi") or q(enemy,"hasSkill","qianxun") or q(enemy,"hasSkill","kuangbao") or q(enemy,"hasSkill","huashen"))
		then
			return enemy
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"hasSkill","fatewangzhe") or q(enemy,"hasSkill","fatemoli") or q(enemy,"hasSkill","fateheijian") or q(enemy,"hasSkill","fateyanfan") or q(enemy,"hasSkill","fatehuyou") or q(enemy,"hasSkill","fatejiejie")
		or q(enemy,"hasSkill","yiji") or q(enemy,"hasSkill","jianxiong") or q(enemy,"hasSkill","fankui") or q(enemy,"hasSkill","qingguo") or q(enemy,"hasSkill","ganglie")
		or q(enemy,"hasSkill","yizhong") or q(enemy,"hasSkill","kongcheng") or q(enemy,"hasSkill","longdan") or q(enemy,"hasSkill","bazhen") or q(enemy,"hasSkill","kanpo")
		or q(enemy,"hasSkill","wuyan") or q(enemy,"hasSkill","liuli") or q(enemy,"hasSkill","tianxiang") or q(enemy,"hasSkill","leiji") or q(enemy,"hasSkill","guhuo")
		or q(enemy,"hasSkill","fangzhu") or q(enemy,"hasSkill","weimu") or q(enemy,"hasSkill","tuntian") or q(enemy,"hasSkill","xiangle") 
		or q(enemy,"hasSkill","fengying") or q(enemy,"hasSkill","guixin") or q(enemy,"hasSkill","juejing") or q(enemy,"hasSkill","longhun") or q(enemy,"hasSkill","renjie")
		or ((q(enemy,"hasSkill","fateshenghai") or q(enemy,"hasSkill","fateshilian") or q(enemy,"hasSkill","huilei") or q(enemy,"hasSkill","zhuiyi") or q(enemy,"hasSkill","jijiu")
		or q(enemy,"hasSkill","buqu") or q(enemy,"hasSkill","duanchang")) and q(enemy,"getHp")==1)
		then
			return enemy
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		return enemy
	end
	
end

ai_audited_aliases.register{id="ai_cardneed.fatebimie",registry="ai_cardneed",path={"fatebimie"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}


sgs.ai_skill_invoke.fatetuci = function(self, data)
	local use = q(data,"toCardUse")
	if q(self.player,"getHandcardNum")<1 then return nil end
    for _, target in sgs.qlist(use.to) do
		if q(self,"isFriend",target) then return false end
		if q(self,"cantDamageMore",self.player,target) then return false end
    	return true
	end
	return false
end

sgs.ai_ajustdamage_from.fatetuci = function(self,from,to,card,nature)
	if card and q(card,"isKindOf","Slash") and q(from,"getHandcardNum")>0 and not q(self,"beFriend",to,from)
	then return 1 end
end


sgs.ai_skill_cardask["@fatetuci"] = function(self, data, pattern, target)
	local cards = AIList.new(q(self.player,"getCards","h"))
	sort_keep(self,cards)
	for _, card in ipairs(cards) do
		return "$" .. q(card,"getEffectiveId")
	end
	return "."
end

sgs.hit_skill = sgs.hit_skill .. "|fatetuci"

local fatesiji_skill={}
fatesiji_skill.name="fatesiji_vs"
table.insert(package_skills,fatesiji_skill)
fatesiji_skill.getTurnUseCard=function(self,inclusive,request)
    if q(self.player,"getHandcardNum")<1 then return nil end
    if q(self.player,"hasUsed","#fatesiji_card") then return nil end
	if q(self.player,"getLostHp")<2 then return nil end
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	for _, c in ipairs(cards) do
		if q(c,"isKindOf","Weapon") then
	   		return parse(self,request,"#fatesiji_card:" .. q(c,"getEffectiveId")..":")
	   	end
	end
end

sgs.ai_skill_use_func["#fatesiji_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
	for _, enemy in ipairs(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy)  and q(self,"canDamage",enemy,self.player,nil) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) and q(self.player,"distanceTo",enemy) < 3 then
			use.card=final_parse(self,request,"#fatesiji_card:" .. q(card,"getEffectiveId")..":")  
			if use.to then
				call(use.to,"append",enemy)
				return
			end
		end
	end
end

sgs.ai_use_value["fatesiji_card"] = 3.5
sgs.ai_use_priority["fatesiji_card"] = 2.5
sgs.ai_card_intention["fatesiji_card"] = 100

sgs.double_slash_skill = sgs.double_slash_skill .. "|fatesiji_vs"
ai_audited_aliases.register{id="ai_cardneed.fatesiji_vs",registry="ai_cardneed",path={"fatesiji_vs"},canonical_registry="ai_cardneed",canonical_path={"weapon"},self_index=3,defer_canonical=true}


sgs.ai_view_as.fateqienuo = function(card, player, card_place)
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
	if q(card,"isKindOf","BasicCard") then
        return material(card,"jink","fateqienuo")
    end
end

sgs.ai_skill_invoke.fateqiangtui = function(self, data)
	local room = self.room
	local players = q(room,"getOtherPlayers",self.player)
	for _, target in sgs.qlist(players) do
		if q(self,"isEnemy",target) and not q(target,"isKongcheng") and (q(target,"getSeat")==(q(self.player,"getNextAlive")):getSeat() or q(self.player,"getSeat")==(q(target,"getNextAlive")):getSeat()) then
			return true
		end
	end
	for _, target in sgs.qlist(players) do
		if q(self.player,"isWounded") and not q(target,"isKongcheng") and q(target,"isFemale")
		and (q(target,"getSeat")==(q(self.player,"getNextAlive")):getSeat() or q(self.player,"getSeat")==(q(target,"getNextAlive")):getSeat())
		then
			return true
		end
	end
    return false
end

sgs.ai_skill_playerchosen.fateqiangtui = function(self, targets) 
	local choices = {}
	if q(self.player,"getLostHp") > 0 then
		for _, target in sgs.qlist(targets) do
			if q(self,"isEnemy",target) and not q(target,"isKongcheng") and q(target,"isFemale") then
				table.insert(choices, target)
			end
		end
		if #choices ~= 0 then
			sort_players(self,choices, "hp")
			return choices[1]
		else
			for _, target in sgs.qlist(targets) do
				if not q(target,"isKongcheng") and q(target,"isFemale") then
					table.insert(choices, target)
				end
			end
			sort_players(self,choices, "hp", true)
			return choices[1]
		end
	end
	
	for _, target in sgs.qlist(targets) do
		if q(self,"isEnemy",target) and not q(target,"isKongcheng") then
			table.insert(choices, target)
		end
	end
	
	sort_players(self,choices, "hp")
	return choices[1]
end

sgs.drawpeach_skill = sgs.drawpeach_skill .. "|fateqiangtui"


local fatechongshu_skill={}
fatechongshu_skill.name="fatechongshu"
table.insert(package_skills,fatechongshu_skill)
fatechongshu_skill.getTurnUseCard=function(self,inclusive,request)
    if q(self.player,"getHandcardNum")<1 then return nil end
    if q(self.player,"hasUsed","#fatechongshu_card") then return nil end
    local cards = q(self.player,"getHandcards")
    cards=AIList.new(cards)
    sort_keep(self,cards)
	local card_str = ("#fatechongshu_card:%d:"):format(cards[1]:getId())
    return parse(self,request,card_str)
end

sgs.ai_skill_use_func["#fatechongshu_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"getHp")<2 and q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"canDamage",enemy,self.player,nil) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) and q(enemy,"getHandcardNum")<2
		then
			use.card=final_parse(self,request,"#fatechongshu_card:" .. q(card,"getEffectiveId")..":")  
			if use.to then
				call(use.to,"append",enemy)
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if (q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"canDamage",enemy,self.player,nil) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal, self.player) and q(enemy,"getHandcardNum")<2) or (q(enemy,"getHandcardNum")>1 and q(self,"doDisCard",enemy, "h"))
		then
			use.card=final_parse(self,request,"#fatechongshu_card:" .. q(card,"getEffectiveId")..":")  
			if use.to then
				call(use.to,"append",enemy)
				return
			end
		end
	end
end

sgs.ai_use_value["fatechongshu_card"] = 7.5
sgs.ai_use_priority["fatechongshu_card"] = 4
sgs.ai_card_intention["fatechongshu_card"] = 100

sgs.ai_skill_invoke.fatechongshu = function(self, data)
    return true
end

sgs.ai_skill_invoke.fatejiushu = function(self, data)
	if q(self.player,"getMark","@fatejiushu_mark")==0 then return false end
	if q(self.player,"getRole")=="renegade"  then return false end
    return (#self.friends_noself > 0)
end









sgs.ai_skill_playerchosen["@fatejiushu"]= function(self, targets) 
	if q(self.player,"getRole") == "loyalist" and call(self.room,"getLord") then
		return call(self.room,"getLord")
	end
	sort_players(self,self.friends_noself, "chaofeng")
	for _, friend in ipairs(self.friends_noself) do
        if (q(friend,"hasSkill","qingnang") or q(friend,"hasSkill","jieyin") or q(friend,"hasSkill","fateqingxing") or q(friend,"hasSkill","fatechuyi_vs")) and role(self,friend)~="renegade" then
            return friend
        end
    end
	for _, friend in ipairs(self.friends_noself) do
        if q(friend,"hasSkill","dimeng") and q(friend,"hasSkill","haoshi") and role(self,friend)~="renegade" then
            return friend
        end
    end
	for _, friend in ipairs(self.friends_noself) do
        if (q(friend,"hasSkill","fatejiezhi") or q(friend,"hasSkill","lijian") or q(friend,"hasSkill","fatezonghe")) and role(self,friend)~="renegade" then
            return friend
        end
    end
	
    local lord = call(self.room,"getLord")
    if q(self,"isFriend",lord) and not q(self.player,"isLord") then 
        return lord
    end
	
    for _, friend in ipairs(self.friends_noself) do
        if q(friend,"getHp")<2 and role(self,friend)~="renegade" then
			return friend
        end
    end
	for _, friend in ipairs(self.friends_noself) do
        if role(self,friend)~="renegade" and not ((q(friend,"hasSkill","yiji") or q(friend,"hasSkill","jieming") or q(friend,"hasSkill","fangzhu") or q(friend,"hasSkill","guixin")) and q(friend,"getHp")>1) then
			return friend
        end
    end
end

sgs.ai_playerchosen_intention["@fatejiushu"] = -800

sgs.ai_ajustdamage_to["@fatesakura_mark"] = function(self, from, to, card, nature)
	if nature ~= "T" then
		return -99
	end
end

for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
do local source=sgs.ai_skill_use['@fatewangzhe'];sgs.ai_skill_use['@fatewangzhe']=function(self,...)
 local wire=source(self,...);if wire==nil or wire=='.'then return wire end
 local use=AIUsePlan.new();use.card=final_parse(self,nil,wire);return use:toAnswer()
end end
