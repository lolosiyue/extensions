-- Fixed fate-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("fate policy input is unknown",key) end
    return value
end


local function sorted(self,cards,method,...)
    local result=AIValue.callKnown(self, method, cards, ...)
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
local function seed(self,skill,class,request) return self:legacySkillSeed(skill, class, action_request(self,request)) end
local skill_cards={['#fateqiuzhan_card']='fateqiuzhan',['#fateshenjian_card']='fateshenjian',['#fatetiangong_card']='fatetiangong_vs',['#fateloli_card']='fateloli_vs',['#fateheijian_card']='fateheijian',['#fatefanshi_card']='fatefanshi',['#fatexinyin_card']='fatexinyin',['#fatebumo_card']='fatebumo',['#fatechuyi_card']='fatechuyi_vs',['#fateyaoshu']='fateyaoshu',['#fatemoshu_card']='fatemoshu_vs',['#fatejuntuan_card']='fatejuntuan_vs',['#fatesiji_card']='fatesiji_vs',['#fatechongshu_card']='fatechongshu',['#fatewangzhe']='fatewangzhe'}
local names={slash='Slash',jink='Jink',peach='Peach',analeptic='Analeptic',fire_slash='FireSlash',thunder_slash='ThunderSlash',duel='Duel',iron_chain='IronChain'}
local function ids(cards)local out={};for _,card in ipairs(cards)do out[#out+1]=type(card)=='number'and card or card:getKnownEffectiveId()end;return out end
local function own_card(player,id)
 for _,group in ipairs({player:getCards('he'),player:getHandPileCards()})do for _,card in ipairs(group)do if card:getKnownEffectiveId()==id then return card end end end
 ai_unsupported('source card face is not owner-disclosed',tostring(id))
end
local function disclosed(self,id)
 local preview=self:getDecisionContext().retrial_preview
 if type(preview)=='table'and preview.known==true and preview.skill=='fatewangzhe'then
  for _,value in ipairs(preview.ids or{})do
   if value==id then return self:getPreviewCardEvaluation(id)end
  end
 end
 local card=self:getKnownCardById(id)or self:getChoiceCard(id)
 return known(card,'fate disclosed card '..tostring(id))
end
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
local function dummy()local use=AIUsePlan.new();use.isDummy=true;return use end
local function role(self,player)local value=player:getRole();if value~=nil then return value end
 return self:useKnowledgeEstimate({status='estimate',value=self:getRoleEstimate(player),basis='viewer_role_estimate_private_role',player=player:objectName()}, 'fate.role')end
local function context_value(self,key)local value=known(self:getDecisionContext()[key],key);if value==false then return nil end;return value end
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
local function printed(self,id)return self:getPrintedCardById(id)end
local function player_disclosed(player,id)
 local function find(cards)for _,card in ipairs(cards)do if card:getKnownEffectiveId()==id then return card end end end
 for _,method in ipairs({'getKnownCards','getEquips','getHandPileCards'})do local card=find(AIValue.callKnown(player, method));if card then return card end end
 local room=player:getRoom();local card=find(room:getDiscardCards());if card then return card end
 for _,p in ipairs(room:getAlivePlayers())do
  card=find(p:getEquips());if card then return card end
  card=find(p:getJudgingArea());if card then return card end
 end
 ai_unsupported('fatetouying mark does not disclose its referenced face','fatetouying.mark_card')
end
local function he_count(player)return player:getHandcardNum()+#player:getEquips()end
local function donor_undefined_target()error('fixed fatewangzhe donor reads undefined global target',0)end

sgs.ai_skill_invoke.fateyezhan = function(self, data)
	return true
end

ai_audited_aliases.register{id="ai_skill_playerchosen.fateyezhan",registry="ai_skill_playerchosen",path={"fateyezhan"},canonical_registry="ai_skill_playerchosen",canonical_path={"damage"},self_index=1,defer_canonical=true}





local fatetouying_skill = {}
fatetouying_skill.name = "fatetouying"
table.insert(package_skills, fatetouying_skill)
fatetouying_skill.getTurnUseCard=function(self,inclusive,request)
	if not self.player:hasFlag("fatetouyingx")  then return end
	local usable_cards = AIList.new(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(usable_cards, disclosed(self,id))
		end
	end
	sort_use(self,usable_cards, true)
	local cards = {}
	for _,c in ipairs(usable_cards) do
		local cardex=owner_eval(self,"fatetouying",disclosed(self,self.player:getMark("fatetouyingskill")):objectName(),{},c:getSuit(),c:getNumber())
		
		if not self.player:isCardLimited(cardex, sgs.Card_MethodUse, true) and cardex:isAvailable(self.player) and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink") < 3) then
		local name = disclosed(self,self.player:getMark("fatetouyingskill")):objectName()
		local new_card = parse(self,request,(name..":fatetouying[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getKnownEffectiveId()))
			assert(new_card) 
			return new_card
		end
	end
end

sgs.ai_view_as.fatetouying = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		local name = player_disclosed(player,player:getMark("fatetouyingskill")):objectName()
		if name and player:hasFlag("fatetouyingx") then
			return material(card,name,"fatetouying")
		end
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|fatetouying"

sgs.ai_canNiepan_skill.fatesizhan = function(player)
	return player:getMark("fatesizhan") == 0
end



sgs.ai_skill_invoke.fatewangzhe = function(self, data)
	return true
end

sgs.ai_skill_askforag.fatewangzhe = function(self, card_ids)
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
	until nextAlive:faceUp()

	local peach, ex_nihilo, jink, nullification, slash
	local valuable
	for _, id in ipairs(card_ids) do
		local card = disclosed(self,id)
		if card:isKindOf("Peach") then peach = id end
		if card:isKindOf("ExNihilo") then ex_nihilo = id end
		if card:isKindOf("Jink") then jink = id end
		if card:isKindOf("Nullification") then nullification = id end
		if card:isKindOf("Slash") then slash = id end
	end
	valuable = peach or ex_nihilo or jink or nullification or slash or card_ids[1]
	local card = disclosed(self,valuable)
	if not (self:needKongcheng(self.player) and self:getHandcardNum() <= 2) then
		if card:isKindOf("Peach") then
			return valuable
		end
		if card:isKindOf("TrickCard") or card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage") then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				return valuable
			end
		end
		if card:isKindOf("Jink") and self:getCardsNum("Jink") == 0 then
			return valuable
		end
		if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 0 then
			return valuable
		end
		if card:isKindOf("Slash") and self:slashIsAvailable() then
			local dummy_use = { isDummy = true }
			self:useBasicCard(card, dummy_use)
			if dummy_use.card then
				return valuable
			end
		end
		return valuable
		end
	local hasLightning, hasIndulgence, hasSupplyShortage
	local tricks = nextAlive:getJudgingArea()
	if not tricks:isEmpty() and not nextAlive:containsTrick("YanxiaoCard") then
		local trick = tricks:at(tricks:length() - 1)
		if self:hasTrickEffective(trick, nextAlive) then
			if trick:isKindOf("Lightning") then hasLightning = true
			elseif trick:isKindOf("Indulgence") then hasIndulgence = true
			elseif trick:isKindOf("SupplyShortage") then hasSupplyShortage = true
			end
		end
	end

	if self:isEnemy(nextAlive) and nextAlive:hasSkill("luoshen") and valuable then
		return valuable
	end
	if nextAlive:hasSkill("yinghun") and nextAlive:isWounded() then
		return valuable
	end
	if donor_undefined_target():hasSkill("hongyan") and hasLightning and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		for _, id in ipairs(card_ids) do
			local card = printed(self,id)
			if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
				return id
			end
		end
	end
	if hasIndulgence and self:isFriend(nextAlive) then
		return valuable
	end
	if hasSupplyShortage and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		local enemy_null = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(p) then enemy_null = enemy_null - getCardsNum("Nullification", p) end
			if self:isEnemy(p) then enemy_null = enemy_null + getCardsNum("Nullification", p) end
		end
		enemy_null = enemy_null - self:getCardsNum("Nullification")
		if enemy_null < 0.8 then
			return valuable
		end
	end

	if self:isFriend(nextAlive) and not self:willSkipDrawPhase(nextAlive) and not self:willSkipPlayPhase(nextAlive)
		and not nextAlive:hasSkill("luoshen")
		and not nextAlive:hasSkill("tuxi") and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		if (peach and valuable == peach) or (ex_nihilo and valuable == ex_nihilo) then
			return valuable
		end
		if jink and valuable == jink and getCardsNum("Jink", nextAlive) < 1 then
			return valuable
		end
		if nullification and valuable == nullification and getCardsNum("Nullification", nextAlive) < 1 then
			return valuable
		end
		if slash and valuable == slash and self:hasCrossbowEffect(nextAlive) then
			return valuable
		end
	end

	local card = disclosed(self,valuable)
	local keep = false
	if card:isKindOf("Slash") or card:isKindOf("Jink")
		or card:isKindOf("EquipCard")
		or card:isKindOf("Disaster") or card:isKindOf("GlobalEffect") or card:isKindOf("Nullification")
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
        table.insert(discard_cards, c:getKnownEffectiveId())
    end
        
		
    if #discard_cards > 0 then
        return string.format("#fatewangzhe:%s:", discard_cards[1])
    end
end






local fateqiuzhan_skill={}
fateqiuzhan_skill.name="fateqiuzhan"
table.insert(package_skills,fateqiuzhan_skill)
fateqiuzhan_skill.getTurnUseCard=function(self,inclusive,request)	
    if not self.player:getStrategyHasUsed("#fateqiuzhan_card") then
		return parse(self,request,"#fateqiuzhan_card:.:")
	end
end

sgs.ai_skill_use_func["#fateqiuzhan_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
	local duel=owner_eval(self,"fateqiuzhan_card","duel",{},sgs.Card_NoSuit,0)
	
	local dummy_use = self:aiUseCard(duel, dummy())
	if dummy_use.card then
		for _,p in sgs.qlist(dummy_use.to)do
			if self:objectiveLevel(p) > 3 and not self:cantbeHurt(p) and self:isTiaoxinTarget(p) and self:canDamage(p, self.player, nil) then
				use.card=final_parse(self,request,"#fateqiuzhan_card:.:")
				if use.to then
					use.to:append(p)
				end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and  self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and self:canDamage(enemy, self.player, nil)		then
			use.card=final_parse(self,request,"#fateqiuzhan_card:.:") 
			if use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end




sgs.ai_skill_cardask["@fateqzslash"]=function(self, data, pattern, target)
	target = target or self.room:getCurrent()
	if (self:hasSkill("fatehuyou") and #self.enemies > 0) then
		return "."
	end
	if (self:getCardsNum("Slash")*2 >= target:getHandcardNum()) then
		return "."
	end
end

local fateshenjian_skill={}
fateshenjian_skill.name="fateshenjian"
table.insert(package_skills,fateshenjian_skill)
fateshenjian_skill.getTurnUseCard=function(self,inclusive,request)	
	if (self.player:getMark("@shenjian_mark")== 0) or not self.player:isWounded() then return end
	if self.player:getHp() + self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= 2 then
		return parse(self,request,"#fateshenjian_card:.:")
	end
	local x = math.min(self.player:getLostHp(), 2)
	local target_num = 0
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal)  then
			target_num = target_num + 1
		end
	end
	if target_num > 1 then
		return parse(self,request,"#fateshenjian_card:.:")
	end
		
end

sgs.ai_skill_use_func["#fateshenjian_card"]=function(card,use,self,request)
	local x = math.min(self.player:getLostHp(), 2)
	if self.player:getMark("@shenjian_mark") == 0 then return end
	local targets = AIList.new({})
	sort_players(self,self.enemies, "hp")
	local cards = self.player:getHandcards()
	cards = AIList.new(cards)
	sort_use(self,cards, true)
	local need_cards = {}
	for _, card in ipairs(cards) do
		if not card:isKindOf("Peach")  then
			table.insert(need_cards, card:getKnownId())
			if #need_cards >= 2 then
				break
			end
		end
	end
	if #need_cards < 2 then return end
	for _, enemy in ipairs(self.enemies) do
		if  self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and  self.player:inMyAttackRange(enemy)  and not self:cantbeHurt(enemy) and enemy:getHp() <= x and self:canDamage(enemy, self.player, nil) then
			targets:append(enemy)
			if targets:length() >= 2 then break end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if not targets:contains(enemy) then
			if self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and  self.player:inMyAttackRange(enemy) then
				targets:append(enemy)
				if targets:length() >= 2 then break end
			end
		end
	end
	if targets:length() > 0 then
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
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:getStrategyHasUsed("#fatetiangong_card") then return nil end
    local cards = self.player:getHandcards()
    cards=AIList.new(cards)
    sort_keep(self,cards)
	local card_str = ("#fatetiangong_card:%d:"):format(cards[1]:getId())
    return parse(self,request,card_str)
end

sgs.ai_skill_use_func["#fatetiangong_card"]=function(card,use,self,request)
	local first
	local slash = self:getEvaluationCard("fire_slash")
	
	sort_players(self,self.enemies, "hp") 
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy) and self:canDamage(enemy, self.player, slash)
						and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
			use.card=final_parse(self,request,"#fatetiangong_card:" .. card:getKnownEffectiveId()..":")
			if use.to then
				use.to:append(enemy)
				first=enemy
				break
			end
		end
	end
	if first and self.player:distanceTo(first) == 1 then
		for _, enemy2 in ipairs(self.enemies) do
		
			if (self.player:distanceTo(enemy2) == 1) and enemy2:getSeat() ~= first:getSeat() and not self:cantbeHurt(enemy2) and self.player:canSlash(enemy2, slash) and not self:slashProhibit(slash, enemy2) and self:canDamage(enemy2, self.player, nil)
						and self:slashIsEffective(slash, enemy2) and self:isGoodTarget(enemy2, self.enemies, slash) then
				use.to:append(enemy2)
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
	if  card:isKindOf("ArcheryAttack")
	then
		return true
	end
end

sgs.ai_skill_cardask["@fatejianzhong1"] = function(self, data, pattern, target)
	local targets = AIList.new({})
	local cards = AIList.new(self.player:getCards("he"))
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if self.player:canSlash(p, nil, false) then
			targets:append(p)
		end
	end
	if targets:isEmpty() then return "." end
	if sgs.ai_skill_playerchosen["@fatejianzhong2"](self, targets) == nil then return "." end
	sort_keep(self,cards)
	for _,card in sgs.list(cards)do
		return "$"..card:getKnownEffectiveId()
	end
	return "."
end

ai_audited_aliases.register{id="ai_skill_playerchosen.@fatejianzhong2",registry="ai_skill_playerchosen",path={"@fatejianzhong2"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1,defer_canonical=true}





sgs.ai_skill_cardask["@fatejuli-jink-1"] = function(self, data, pattern, target)
	local isdummy = type(data) == "number"
	local function getJink()
		if (self:getCardsNum("Jink") > 0 and self:getCardsNum("Slash") > 0) then
		return self:getCardId("Slash") or not isdummy and "."
		else
		return "."
		end
	end
	local effect = data:toCardEffect()
	local slash = effect.card
	local cards = AIList.new(self.player:getHandcards())
	if (not target or self:isFriend(target)) and slash:hasFlag("nosjiefan-slash") then return "." end
	if self:standardNullFilter(data, pattern, target) then return "." end
	
	if not self:slashIsEffective(slash, self.player, effect.from)
		or (self:ajustDamage(effect.from, self.player, 1, slash)<2
		and self:needToLoseHp(self.player, effect.from, slash)) then return "." end
		if self:ajustDamage(effect.from, self.player, 1, slash) and self:getCardsNum("Peach")>0 then return "." end
	if not target then return getJink() end
	if not self:hasHeavyDamage(target, slash, self.player) and self:needToLoseHp(self.player, target, slash) then return "." end
	
	if self:ajustDamage(target, nil, 1, slash) <= 0 then return "." end

	if slash:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, target, nil, nil, slash) then return "." end
	if self:isFriend(target) then
		if self:findLeijiTarget(self.player, 50, target) then return getJink() end
		if target:hasSkill("jieyin") and not self.player:isWounded() and self.player:isMale() and not self.player:hasSkills("leiji|nosleiji|olleiji|jieleiji") then return "." end
		if not target:hasSkill("jueqing") then
			if (target:hasSkill("nosrende") or (target:hasSkill("rende") and not target:getStrategyHasUsed("RendeCard"))) and self.player:hasSkill("jieming") then return "." end
			if target:hasSkill("pojun") and not self.player:faceUp() then return "." end
			
			if target:hasSkill("BurningLove") and slash:isKindOf("FireSlash") then return "." end
		end
	else
		if self:hasHeavyDamage(target, slash, self.player) then return getJink() end

		local current = self.room:getCurrent()
		if current and current:hasSkill("juece") and self.player:getHp() > 0 then
			local use = false
			for _, card in ipairs(self:getCards("Jink")) do
				if not self.player:isLastHandCard(card, true) then
					use = true
					break
				end
			end
			if not use then return not isdummy and "." end
		end
		if self.player:getHandcardNum() == 1 and self:needKongcheng() then return getJink() end
		if not self:hasLoseHandcardEffective() and not self.player:isKongcheng() then return getJink() end
		if target:hasSkill("mengjin") and not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if self.player:getCards("he"):length() == 1 and not self.player:getArmor() then return getJink() end
			if self.player:hasSkills("jijiu|qingnang") and self.player:getCards("he"):length() > 1 then return "." end
			if self:canUseJieyuanDecrease(target) then return "." end
			if (self:getCardsNum("Peach") > 0 or (self:getCardsNum("Analeptic") > 0 and self:isWeak()))
				and not hasTuntianEffect(self.player, true) and not self:willSkipPlayPhase() then
				return "."
			end
		end
		if self.player:getHp() > 1 and getKnownCard(target, self.player, "Slash") >= 1 and getKnownCard(target, self.player, "Analeptic") >= 1 and self:getCardsNum("Jink") == 1
			and (target:getPhase() < sgs.Player_Play or self:slashIsAvailable(target) and target:canSlash(self.player)) then
			return "."
		end
		if not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if target:hasWeapon("axe") then
				if target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 1 and target:getCards("he"):length() > 2 then return not isdummy and "." end
				if target:getHandcardNum() - target:getHp() > 2 and not self:isWeak() and not self:getOverflow() then return not isdummy and "." end
			elseif target:hasWeapon("blade") then
				
				local has_weak_chained_friend = false
				for _, friend in ipairs(self.friends_noself) do
					if friend:isChained() and self:isWeak(friend) then
						has_weak_chained_friend = true
					end
				end
				if has_weak_chained_friend and slash:isKindOf("NatureSlash") and self.player:isChained() then
					return getJink()
				end
				
				if slash:isKindOf("NatureSlash") and self.player:hasArmorEffect("vine")
					or self.player:hasArmorEffect("renwang_shield")
					or self:hasEightDiagramEffect()
					or self:hasHeavyDamage(target, slash, self.player)
					or (self.player:getHp() == 1 and #self.friends_noself == 0) then
				elseif (self:getCardsNum("Jink") <= getCardsNum("Slash", target, self.player) or self.player:hasSkill("qingnang")) and self.player:getHp() > 1
					or (self.player:hasSkill("jijiu") and getKnownCard(self.player, self.player, "red") > 0)
					or self:canUseJieyuanDecrease(target)
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
		if target and target:hasSkill("dahe") and self.player:hasFlag("dahe") then
			for _, card in ipairs(self:getCards("Jink")) do
				if card:getSuit() == sgs.Card_Heart then return card:getKnownId() end
			end
			return "."
		end
		return self:getCardId("Jink") or not isdummy and "."
	end

	local slash
	if type(data)=="table" and type(data.toCardEffect)=="function" then
		local effect = data:toCardEffect()
		slash = effect.card
	else
		slash = self:getEvaluationCard("slash")
	end
	local cards = AIList.new(self.player:getHandcards())
	if (not target or self:isFriend(target)) and slash:hasFlag("nosjiefan-slash") then return "." end
	if self:standardNullFilter(data, pattern, target) then return "." end
	if not target then return getJink() end
	if not self:hasHeavyDamage(target, slash, self.player) and self:needToLoseHp(self.player, target, slash) then return "." end
	
	if self:ajustDamage(target, nil, 1, slash) <= 0 then return "." end

	if slash:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, target, nil, nil, slash) then return "." end
	if self:isFriend(target) then
		if self:findLeijiTarget(self.player, 50, target) then return getJink() end
		if target:hasSkill("jieyin") and not self.player:isWounded() and self.player:isMale() and not self.player:hasSkills("leiji|nosleiji|olleiji|jieleiji") then return "." end
		if not target:hasSkill("jueqing") then
			if (target:hasSkill("nosrende") or (target:hasSkill("rende") and not target:getStrategyHasUsed("RendeCard"))) and self.player:hasSkill("jieming") then return "." end
			if target:hasSkill("pojun") and not self.player:faceUp() then return "." end
			
			if target:hasSkill("BurningLove") and slash:isKindOf("FireSlash") then return "." end
		end
	else
		if self:hasHeavyDamage(target, slash, self.player) then return getJink() end

		local current = self.room:getCurrent()
		if current and current:hasSkill("juece") and self.player:getHp() > 0 then
			local use = false
			for _, card in ipairs(self:getCards("Jink")) do
				if not self.player:isLastHandCard(card, true) then
					use = true
					break
				end
			end
			if not use then return not isdummy and "." end
		end
		if self.player:getHandcardNum() == 1 and self:needKongcheng() then return getJink() end
		if not self:hasLoseHandcardEffective() and not self.player:isKongcheng() then return getJink() end
		if target:hasSkill("mengjin") and not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if not self:doDisCard(self.player, "he", true) then return getJink() end
			if self.player:getCards("he"):length() == 1 and not self.player:getArmor() then return getJink() end
			if self.player:hasSkills("jijiu|qingnang") and self.player:getCards("he"):length() > 1 then return "." end
			if self:canUseJieyuanDecrease(target) then return "." end
			if (self:getCardsNum("Peach") > 0 or (self:getCardsNum("Analeptic") > 0 and self:isWeak()))
				and not hasTuntianEffect(self.player, true) and not self:willSkipPlayPhase() then
				return "."
			end
		end
		if self.player:getHp() > 1 and getKnownCard(target, self.player, "Slash") >= 1 and getKnownCard(target, self.player, "Analeptic") >= 1 and self:getCardsNum("Jink") == 1
			and (target:getPhase() < sgs.Player_Play or self:slashIsAvailable(target) and target:canSlash(self.player)) then
			return "."
		end
		if not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if target:hasWeapon("axe") then
				if target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 1 and target:getCards("he"):length() > 2 then return not isdummy and "." end
				if target:getHandcardNum() - target:getHp() > 2 and not self:isWeak() and not self:getOverflow() then return not isdummy and "." end
			elseif target:hasWeapon("blade") then
				
				local has_weak_chained_friend = false
				for _, friend in ipairs(self.friends_noself) do
					if friend:isChained() and self:isWeak(friend) then
						has_weak_chained_friend = true
					end
				end
				if has_weak_chained_friend and slash:isKindOf("NatureSlash") and self.player:isChained() then
					return getJink()
				end
				
				if slash:isKindOf("NatureSlash") and self.player:hasArmorEffect("vine")
					or self.player:hasArmorEffect("renwang_shield")
					or self:hasEightDiagramEffect()
					or self:hasHeavyDamage(target, slash, self.player)
					or (self.player:getHp() == 1 and #self.friends_noself == 0) then
				elseif (self:getCardsNum("Jink") <= getCardsNum("Slash", target, self.player) or self.player:hasSkill("qingnang")) and self.player:getHp() > 1
					or (self.player:hasSkill("jijiu") and getKnownCard(self.player, self.player, "red") > 0)
					or self:canUseJieyuanDecrease(target)
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
	return player:getMaxHp() > 3
end


sgs.ai_skill_invoke.fatemoli = function(self, data)
	local baba = self.room:findPlayerBySkillName("fatejiezhi")
    if baba and self:isEnemy(baba) then
        return false
    else
		return true
	end
end



local fateloli_skill={}
fateloli_skill.name="fateloli_vs"
table.insert(package_skills,fateloli_skill)
fateloli_skill.getTurnUseCard=function(self,inclusive,request)
    if not self.player:getStrategyHasUsed("#fateloli_card") then
		return parse(self,request,"#fateloli_card:.:")
	end
end


sgs.ai_skill_use_func["#fateloli_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				use.card=final_parse(self,request,"#fateloli_card:.:") 
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
end

sgs.ai_use_priority["fateloli_card"] = 9.2
sgs.ai_card_intention["fateloli_card"] = 50

sgs.ai_skill_askforag["fateloli_vs"] = function(self, card_ids)
	local target = context_player(self,"fate_loli_target")
	if not target or self:isFriend(target) then return -1 end
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
	until nextAlive:faceUp()

	local peach, ex_nihilo, jink, nullification, slash
	local valuable
	for _, id in ipairs(card_ids) do
		local card = disclosed(self,id)
		if card:isKindOf("Peach") then peach = id end
		if card:isKindOf("ExNihilo") then ex_nihilo = id end
		if card:isKindOf("Jink") then jink = id end
		if card:isKindOf("Nullification") then nullification = id end
		if card:isKindOf("Slash") then slash = id end
	end
	valuable = peach or ex_nihilo or jink or nullification or slash or card_ids[1]
	local card = disclosed(self,valuable)
	if self:isEnemy(target) and target:hasSkill("tuntian") and card:getSuit() == sgs.Card_Heart then
		return valuable
	end

	local willUseExNihilo, willRecast
	if self:getCardsNum("ExNihilo") > 0 then
		local ex_nihilo = self:getCard("ExNihilo")
		if ex_nihilo then
			local dummy_use = self:aiUseCard(ex_nihilo, dummy())
			if dummy_use.card then willUseExNihilo = true end
		end
	elseif self:getCardsNum("IronChain") > 0 then
		local iron_chain = self:getCard("IronChain")
		if iron_chain then
			local dummy_use = self:aiUseCard(iron_chain, dummy())
			if dummy_use.card and dummy_use.to:isEmpty() then willRecast = true end
		end
	end
	if willUseExNihilo or willRecast then
		local card = disclosed(self,valuable)
		if card:isKindOf("Peach") then
			return valuable
		end
		if card:isKindOf("TrickCard") or card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage") then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return valuable
			end
		end
		if card:isKindOf("Jink") and self:getCardsNum("Jink") == 0 then
			return valuable
		end
		if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 0 then
			return valuable
		end
		if card:isKindOf("Slash") and self:slashIsAvailable() then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return valuable
			end
		end
		return valuable
	end

	if self:isFriend(nextAlive) and not self:willSkipDrawPhase(nextAlive) and not self:willSkipPlayPhase(nextAlive)
		and not nextAlive:hasSkill("luoshen")
		and not nextAlive:hasSkill("tuxi") and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		if (peach and valuable == peach) or (ex_nihilo and valuable == ex_nihilo) then
			return valuable
		end
		if jink and valuable == jink and getCardsNum("Jink", nextAlive) < 1 then
			return valuable
		end
		if nullification and valuable == nullification and getCardsNum("Nullification", nextAlive) < 1 then
			return valuable
		end
		if slash and valuable == slash and self:hasCrossbowEffect(nextAlive) then
			return valuable
		end
	end
	return valuable
end

sgs.ai_skill_discard["fateduoluo"] = function(self, discard_num, min_num, optional, include_equip)
	local current = self.room:getCurrent()
	local handcards = AIList.new(self.player:getCards("h"))
	sort_keep(self,handcards)
	local to_discard = {}
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach")
		
		and not c:isKindOf("Analeptic")
		then
			if #to_discard < min_num then
				table.insert(to_discard, c:getKnownEffectiveId())
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
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getKnownEffectiveId()
    if card:getSuit()== sgs.Card_Diamond and not card:isKindOf("Peach") then
        return material(card,"slash","fateyanfan_vs")
    end
	if card:getSuit()== sgs.Card_Club then
        return material(card,"jink","fateyanfan_vs")
    end
end

local fateyanfan_vs_skill={}
fateyanfan_vs_skill.name="fateyanfan_vs"
table.insert(package_skills,fateyanfan_vs_skill)
fateyanfan_vs_skill.getTurnUseCard=function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards=AIList.new(cards)
    
    local diamond_card
    
    sort_use(self,cards,true)
    
    for _,card in ipairs(cards) do
        if card:getSuit()== sgs.Card_Diamond and not card:isKindOf("Slash") and not card:isKindOf("Peach")
            and ((self:getUseValue(card)<sgs.ai_use_value.Slash) or inclusive) then
            diamond_card = card
            break
        end
    end

    if diamond_card then		
        local suit = diamond_card:getSuitString()
        local number = diamond_card:getNumberString()
        local card_id = diamond_card:getKnownEffectiveId()
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
	if to:getMark("&fateshenghai") > 0
	then
		return -99
	end
end

sgs.ai_can_damagehp.fateshenghai = function(self, from, card, to)
	if from and to:getHp() - self:ajustDamage(from, to, 1, card) == 0
		and self:canLoseHp(from, card, to) and self:getAllPeachNum() > 0
	then
		return to:getPhase() == sgs.Player_NotActive
	end
end

local fateheijian_skill={}
fateheijian_skill.name="fateheijian"
table.insert(package_skills,fateheijian_skill)
fateheijian_skill.getTurnUseCard=function(self,inclusive,request)
	if not self.player:getStrategyHasUsed("#fateheijian_card") and not self.player:isKongcheng() and (self.player:getPile("fateheijiancards")):length() < 5 then
	    local cards = self.player:getCards("h")
	    cards = AIList.new(cards)
	    sort_keep(self,cards)
	    for _, c in ipairs(cards) do
			if c:isBlack() and not (c:isKindOf("Nullification") and self:getCardsNum("Nullification") == 1 and self.player:getHp() > 1) then
                return parse(self,request,"#fateheijian_card:" .. c:getKnownEffectiveId()..":")
	    	end
	    end
	end
end

sgs.ai_skill_use_func["#fateheijian_card"]=function(card,use,self,request)
	use.card=card
	if use.to then
		use.to:append(self.player)
	end
end

sgs.ai_skill_invoke["fateheijianDamage"] = function(self, data)
	
	local damage = data:toDamage()
	if self:isFriend(damage.to) then return false end
	if damage.to:getHp()<3 then return true end
	if self.player:getHp() == 1 then return false end

	if ((self.player:getPile("fateheijiancards")):length() < 2)  and (self:getCardsNum("Jink") == 0) then
		return false
	end
	return true	
end

sgs.ai_skill_invoke["fateheijianDefense"] = function(self, data)
	if self:getCardsNum("Peach") < 2 then
		return true
	end		
end

function sgs.ai_cardneed.fateheijian(to,card)
	return to:getPile("fateheijiancards"):length() < 2 and card:isBlack()
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
	
	if self:getCardsNum("Slash") == 0 then
		return false
	end
	local cur = self.room:getCurrent()
	

	
	if self:isFriend(cur) then return false end
	return true
end

local fatefanshi_skill={}
fatefanshi_skill.name="fatefanshi"
table.insert(package_skills,fatefanshi_skill)
fatefanshi_skill.getTurnUseCard=function(self,inclusive,request)
    if not self.player:getStrategyHasUsed("#fatefanshi_card") then
		return parse(self,request,"#fatefanshi_card:.:")
	end
end

sgs.ai_skill_use_func["#fatefanshi_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and self.player:distanceTo(enemy) <= self.player:getAttackRange() then
				use.card=final_parse(self,request,"#fatefanshi_card:.:") 
				if use.to then
					use.to:append(enemy)
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
    if not self.player:getStrategyHasUsed("#fatexinyin_card") then
		return parse(self,request,"#fatexinyin_card:.:")
	end
end

sgs.ai_skill_use_func["#fatexinyin_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and self.player:distanceTo(enemy) <= 1 then
				use.card=final_parse(self,request,"#fatexinyin_card:.:") 
				if use.to then
					use.to:append(enemy)
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
	
	
	
	local cards = self.player:getCards("he")
	local i=0
	cards = AIList.new(cards)
	for _, c in ipairs(cards) do
		if c:getSuit()==sgs.Card_Heart or c:isKindOf("Jink")then
	    		i=i+1
	    end
	end
	if i==0 then return false end
	local player = self.room:getCurrent()
	if not self:isFriend(player) then return false end
	local judges = player:getJudgingArea()
	if player:hasSkill("fateqingxing") then
		if player:isWounded() and player:getMark("@fatebimie")==0 then
			return true
		end
		if not judges:isEmpty() then
			if self:hasWizard(self.enemies) then return true end
			for _,cd in sgs.qlist(judges) do
				if not cd:isKindOf("Lightning") then return true end
			end
		else 
			return false 
		end
	end
	if (player:getHp() < 2 and player:isWounded()) and player:getMark("@fatebimie")==0 then return true end
	local cards = self.player:getCards("he")
    cards=AIList.new(cards)
    local card
	local i=0
    sort_use(self,cards,true)
    for _,acard in ipairs(cards)  do
        if (acard:getSuit() == sgs.Card_Heart) then
			i=i+1
		end
    end
	if (player:getHp() < 3 and player:isWounded() and (self:getCardsNum("Jink")+ i> 1)) then return true end
	return false
end

sgs.ai_skill_cardask["@fateqingxing1"] = function(self, data, pattern, target)
	local cards = self.player:getCards("he")
	local i=0
	cards = AIList.new(cards)
	sort_use(self,cards, true)
	local heart = {}
	for _, c in ipairs(cards) do
		if c:getSuit()==sgs.Card_Heart or c:isKindOf("Jink")then
	    		i=i+1
				table.insert(heart, c:getKnownEffectiveId())
	    end
	end
	if i==0 then return "." end
	local player = self.room:getCurrent()
	if not self:isFriend(player) then return "." end
	local judges = player:getJudgingArea()
	if player:hasSkill("fateqingxing") then
		if player:isWounded() and player:getMark("@fatebimie")==0 then
			return "$" .. heart[1]
		end
		if not judges:isEmpty() then
			if self:hasWizard(self.enemies) then return "$" .. heart[1] end
			for _,cd in sgs.qlist(judges) do
				if not cd:isKindOf("Lightning") then return "$" .. heart[1] end
			end
		else 
			return "." 
		end
	end
	if (self:isWeak(player) and player:isWounded()) and player:getMark("@fatebimie")==0 then return  "$" .. heart[1] end
	local cards = self.player:getCards("he")
    cards=AIList.new(cards)
    local card
	local i=0
    sort_use(self,cards,true)
    for _,acard in ipairs(cards)  do
        if (acard:getSuit() == sgs.Card_Heart) then
			i=i+1
		end
    end
	if self:needToThrowArmor() and self.player:getArmor():getSuit() == sgs.Card_Heart then
		return "$" .. self.player:getArmor()
	end
	if ((not judges:isEmpty() or  player:getHp() < self:getBestHp(player)) and (self:getCardsNum("Jink")+ i> 1)) then return  "$" .. heart[1] end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["@fateqingxing1"] = function(self,player,promptlist)
	if promptlist[#promptlist]~="" then
		local current = self.room:getCurrent()
		if not current then return end
		self:updateIntention(player, current, -80)
	end
end

sgs.ai_armor_value.fatejizhi = function(player,self,card)
	if not card then return 4 end
end
sgs.ai_card_priority.fatejizhi = function(self,card,v)
    if self.useValue
	and card:isKindOf("Armor")
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
	return (card:getSuit()==sgs.Card_Heart or card:isKindOf("Jink")) and he_count(to) < 4
end

local fatebumo_skill={}
fatebumo_skill.name="fatebumo"
table.insert(package_skills,fatebumo_skill)
fatebumo_skill.getTurnUseCard=function(self,inclusive,request)
    if (self.player:getMark("@bumo_mark")>0) and (self.player:isWounded() or self.player:getHandcardNum() < self.player:getMaxHp()) then
    	return parse(self,request,"#fatebumo_card:.:")
	end
end

sgs.ai_skill_use_func["#fatebumo_card"]=function(card,use,self,request)
    sort_players(self,self.friends_noself, "hp")
    local lord = self.room:getLord()
    if self:isFriend(lord) and not self:isLordHealthy()  and lord:isMale() and lord:isWounded() then
        use.card=card
        if use.to then use.to:append(lord) end
        return
    end
    for _, friend in ipairs(self.friends_noself) do
        if friend:getGender()~=self.player:getGender() and self:isWeak(friend) and (friend:getSeat() - self.player:getSeat()) % (self.room:alivePlayerCount()) < 3 then
            use.card=card
            if use.to then use.to:append(friend) end
            return
        end
    end
end



local fatechuyi_vs_skill={}
fatechuyi_vs_skill.name="fatechuyi_vs"
table.insert(package_skills,fatechuyi_vs_skill)
fatechuyi_vs_skill.getTurnUseCard=function(self,inclusive,request)
    if self.player:getHandcardNum()<2 then return nil end
    if self.player:getStrategyHasUsed("#fatechuyi_card") then return nil end
    
    local cards = self.player:getHandcards()
    cards=AIList.new(cards)
    
    local first, second
    sort_use(self,cards,true)
    for _, card in ipairs(cards) do
        if card:getTypeId() ~= sgs.Card_Equip then
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
    local lord = self.room:getLord()
    if self:isFriend(lord) and not self:isLordHealthy() and lord:isWounded() then
        use.card=card
        if use.to then use.to:append(lord) end
        return
    end	
    for _, friend in ipairs(self.friends_noself) do
        if friend:isWounded() and
            not (friend:hasSkill("longhun") and self:getAllPeachNum() > 0) and
            not (friend:hasSkill("hunzi") and friend:getMark("hunzi") == 0 and self:getAllPeachNum() > 1) then
            use.card=card
            if use.to then use.to:append(friend) end
            return
        end
    end
	if self:getOverflow()>0 then
		sort_players(self,self.friends_noself, "handcard")
		for _, friend in ipairs(self.friends_noself) do 
            if not (friend:hasSkill("kongcheng") and friend:isKongcheng()) then
        	    use.card=card
                if use.to then use.to:append(friend) end
        	    return
        	end
    	end
	end
end

sgs.ai_use_priority.fatechuyi_card = 4.2
sgs.ai_card_intention.fatechuyi_card = -200
sgs.dynamic_value.benefit.fatechuyi_card = true

sgs.ai_skill_invoke["fatexinengloseHP"] = function(self, data)
	local next_player = self.player:getNextAlive()
	if not self:isFriend(next_player) then return true end
	return false
end





local fateyaoshu_skill={}
fateyaoshu_skill.name="fateyaoshu"
table.insert(package_skills,fateyaoshu_skill)
fateyaoshu_skill.getTurnUseCard=function(self,inclusive,request)
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit=false
		cards = AIList.new(cards)
		for _, fcard in ipairs(cards) do
			if not (fcard:isKindOf("Peach") or fcard:isKindOf("ExNihilo")) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and scard:getSuitString() == first_card:getSuitString() and
						not (scard:isKindOf("Peach") or scard:isKindOf("ExNihilo")) then
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
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit=false
		cards = AIList.new(cards)
		for _, fcard in ipairs(cards) do
			if not (fcard:isKindOf("Peach") or fcard:isKindOf("ExNihilo")) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and scard:getSuitString() == first_card:getSuitString() and
						not (scard:isKindOf("Peach") or scard:isKindOf("ExNihilo")) then
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
		local first_suit, first_id = first_card:getSuit(), first_card:getKnownEffectiveId()
		local second_suit, second_id = second_card:getSuit(), second_card:getKnownEffectiveId()
		local card_str = ("#fateyaoshu:%d+%d:"):format(first_id, second_id)
		if first_suit == sgs.Card_Diamond then 
			use.card=final_parse(self,request,card_str)
			if use.to then use.to:append(self.player) end
			return
		elseif first_suit == sgs.Card_Spade then 
			local target
			for _,friend in ipairs(self.friends)do
				if not friend:faceUp() then
						target = friend
					break
				end
				if not target then
					if not self:toTurnOver(friend, 0, "fateyaoshu") then
						target = friend
						break
					end
				end
			end
			sort_players(self,self.enemies)
			for _,enemy in ipairs(self.enemies)do
				if self:toTurnOver(enemy, 0, "fateyaoshu") then
					target = enemy
					break
				end
			end
			if not target then
				for _,enemy in ipairs(self.enemies)do
					if self:toTurnOver(enemy, 0, "fateyaoshu") and self:hasSkills(sgs.priority_skill, enemy) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _,enemy in ipairs(self.enemies)do
					if self:toTurnOver(enemy, 0, "fateyaoshu") then
						target = enemy
						break
					end
				end
			end
			if target then
				use.card=final_parse(self,request,card_str)
				if use.to then use.to:append(target) end
				return
			end
		elseif first_suit == sgs.Card_Heart then 
			local arr1, arr2 = self:getWoundedFriend(false, true)
			local target = nil

			if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < self:getBestHp(arr1[1]) then
				target =
					arr1[1]
			end
			if target then
				use.card=final_parse(self,request,card_str)
				if use.to then use.to:append(target) end
				return 
			end
			if self:getOverflow() > 0 and #arr2 > 0 then
				for _, friend in ipairs(arr2) do
					if not friend:hasSkills("hunzi|longhun") then
						use.card=final_parse(self,request,card_str)
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		elseif first_suit == sgs.Card_Club  then 
			for _,enemy in sgs.list(self.enemies)do
				if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and self:canDamage(enemy, self.player, nil)
				then
					use.card=final_parse(self,request,card_str)
						if use.to then use.to:append(enemy) end
						return
				end
			end
		end
    	return
	end
end

sgs.ai_skill_use_func["#fateyaoshu1"]=function(card,use,self,request)
	
	if self.player:isWounded() then
        use.card=card
        if use.to then use.to:append(self.player) end
    end
end

sgs.ai_skill_use_func["#fateyaoshu2"]=function(card,use,self,request)
	sort_players(self,self.enemies, "chaofeng") 
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and enemy:faceUp() then
				use.card = card 
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
		for _, friend in ipairs(self.friends) do
            if not friend:faceUp() then
				use.card = card 
				if use.to then
					use.to:append(friend)
				end
				return
			end
        end
end


sgs.ai_skill_use_func["#fateyaoshu3"]=function(card,use,self,request)
	-- Source diagnostic-only console text t4 omitted; no RNG or game state.
	use.card=card
	if use.to then
		use.to:append(self.player)
	end
end


sgs.ai_skill_use_func["#fateyaoshu4"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
		for _, enemy in ipairs(self.enemies) do
			if self:getOverflow()<1 and enemy:getHp()>1 then return end
			if self:objectiveLevel(enemy) > 3 then
				use.card = card 
				if use.to then
					use.to:append(enemy)
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
	if self.player:usedTimes("ArcheryAttack")>0 then return nil end
    local cards = self.player:getCards("h")
    cards=AIList.new(cards)
    local heart_card
    sort_use(self,cards,true)
    for _,card in ipairs(cards) do
        if card:getSuit()== sgs.Card_Heart then
            heart_card = card
            break
        end
    end
	if heart_card then	
        local suit = heart_card:getSuitString()
        local number = heart_card:getNumberString()
        local card_id = heart_card:getKnownEffectiveId()
        local card_str = ("archery_attack:fateluanshe_vs[%s:%s]=%d"):format(suit, number, card_id)
        local aa = parse(self,request,card_str)
        assert(aa)
        return aa
    end
end

sgs.ai_skill_cardask["@fatechuanxin1"] = function(self, data, pattern, target, target2)
	if #self.enemies == 0 then return "." end
	local card = AIList.new(self.player:getHandcards())
	if #card == 0 then return "." end
	if sgs.ai_skill_playerchosen.zero_card_as_slash(self, self.room:getOtherPlayers(self.player)) ~= nil then
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
	if self:getCardsNum("Slash") > 1 then return "fateguangbo3" end
	local hasweapon = false
	local weapon = self.player:getWeapon()
	
	if weapon then 
		hasweapon = true
	else 
		local cards = self.player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if card:isKindOf("Weapon") then
				hasweapon = true
				break
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and enemy:getMark("@fog") < 1 and enemy:getMark("@fateshenghai") < 1
		and enemy:getMark("@fatesakura_mark") < 1 and self:canDamage(enemy, self.player, nil) then
			if (hasweapon or (enemy:getHp()==1 and self.player:getHp()>2)) and self.player:distanceTo(enemy) <=1 then
				return "fateguangbo2"
			end
		end
	end
	
	local cards = self.player:getCards("h")
	local blacknum = 0
	for _, card in sgs.qlist(cards) do
		if card:isBlack() then
			blacknum = blacknum + 1
		end
	end
	if blacknum > 1 then return "fateguangbo4" end
	
	if self:getCardsNum("Slash") > 0 then return "fateguangbo3" end
	
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and enemy:getMark("@fog") < 1 and enemy:getMark("@fateshenghai") < 1
		and enemy:getMark("@fatesakura_mark") < 1 and self:canDamage(enemy, self.player, nil) then
			if self.player:distanceTo(enemy) <= self.player:getAttackRange() then
					return "fateguangbo5"
			end
		end
	end
	
	local cards = self.player:getCards("he")
	for _, card in sgs.qlist(cards) do
		if card:isBlack() then
			return "fateguangbo4"
		end
	end
	return "fateguangbo3"
end


sgs.ai_skill_invoke.fatetuji = function(self, data)
	return self:isWeak() or self.room:getTurnCount() > 1
end



sgs.wizard_skill = sgs.wizard_skill .. "|fateshengqi"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|fateshengqi"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|fateshengqi"

function sgs.ai_cardneed.fateshengqi(to,card,self)
	for _,player in sgs.qlist(self.room:getAllPlayers())do
		if self:getFinalRetrial(to)==1 then
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit()==sgs.Card_Heart and self:hasSuit("heart", true, to)
			end
		end
	end
end


sgs.ai_skill_cardask["@fateshengqi-card"]=function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			all_cards:prepend(disclosed(self,id))
		end
	end
	
	if all_cards:isEmpty() then return "." end

	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isRed() and not card:hasFlag("using") then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end

	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() and self.player:getArmor():isRed() then return "$" .. self.player:getArmor():getEffectiveId() end
			sort_use(self,cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(disclosed(self,card_id)) then
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
		if self:isEnemy(target) then
			table.insert(choices, target)
		end
	end
	if #choices == 0 then
		for _, target in sgs.qlist(targets) do
			if not self:isFriend(target) then
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
        if friend:getLostHp() > 0 and self.player:getLostHp()==0 then
            return true
        end
    end
	return false
end

sgs.ai_skill_playerchosen["#fatehuyougood_target"] = function(self, targets)
	local choices = {}
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) then
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
	if card:isKindOf("AmazingGrace") or card:isKindOf("ExNihilo") or card:isKindOf("EXCard_YJJG") then
		for _, friend in ipairs(self.friends) do
			if friend:hasSkills(sgs.cardneed_skill) and not self:needKongcheng(friend, true) and not self:hasManjuanEffect(friend) and self:hasTrickEffective(card, effect.from, friend)
			and self.player:getHandcardNum() > 	friend:getHandcardNum()	and table.contains(targets, friend)	then
				return friend
			end
		end
		return nil
	elseif  card:isKindOf("EXCard_TJBZ") then
		return nil
	elseif card:isKindOf("EXCard_YYDL")  then
		for _, friend in ipairs(self.friends) do
			if (self:hasSkills(sgs.lose_equip_skill, friend) or self:needToThrowArmor(friend)) and not self:hasManjuanEffect(friend) and self:hasTrickEffective(card, effect.from, friend) and table.contains(targets, friend) 	then
				return friend
			end
		end
		return nil
	elseif card:isKindOf("GodSalvation") then
		local lord = self.room:getLord()
		if self:isWeak(lord) and self.player:getKnownRole() == "loyalist" and self:hasTrickEffective(card, effect.from, lord)  and table.contains(targets, lord) then
			return lord
		end
		sort_players(self,self.friends, "hp")
		if self:isWeak() and self:hasTrickEffective(card, effect.from, self.player)  then
			return nil
		else
			for _, target in ipairs(self.friends) do
				if self:hasTrickEffective(card, effect.from, target) and target:getHp() < self:getBestHp(target)   and table.contains(targets, target) then
					return target
				end
			end
		end
		return nil
	elseif  card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("EXCard_WWJZ") then
		local nature = sgs.DamageStruct_Normal
		if card:isKindOf("FireAttack") then
			nature = sgs.DamageStruct_Fire
		end
		sort_players(self,self.enemies, "hp")
		sort_players(self,self.friends, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and self:canDamage(enemy, effect.from, nil) and self:damageIsEffective(enemy, nature) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and self:canDamage(enemy, effect.from, nil) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
		for _, friend in ipairs(self.friends) do
			if ((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, effect.from, card, false)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, effect.from, friend) or not self:damageIsEffective(friend, nature)  and  table.contains(targets, friend) then
				return friend
			end
		end
		return targets[1]
	elseif  card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
		local nature = sgs.DamageStruct_Normal
		if card:isKindOf("FireAttack") then
			nature = sgs.DamageStruct_Fire
		end
		sort_players(self,self.enemies, "hp")
		sort_players(self,self.friends, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nature) and self:canDamage(enemy, effect.from, nil) and not enemy:hasArmorEffect("vine") and  table.contains(targets, enemy) 	then
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy)  and not enemy:hasArmorEffect("vine") and self:canDamage(enemy, effect.from, nil)	and  table.contains(targets, enemy) then
				return enemy
			end
		end
		for _, friend in ipairs(self.friends) do
			if (((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, effect.from, card, false)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, effect.from, friend) or not self:damageIsEffective(friend, nature) or  friend:hasArmorEffect("vine")) and  table.contains(targets, friend) then
				return friend
			end
		end
		return targets[1]
	elseif card:isKindOf("Collateral") then
		sort_players(self,self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getWeapon()) and self:hasTrickEffective(card, effect.from, enemy) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif card:isKindOf("Dismantlement")  or card:isKindOf("Snatch") then
		if self:isFriend(effect.from) and (self.player:getJudgingArea():length() > 0 or self:hasSkills(sgs.lose_equip_skill, self.player)) and self:hasTrickEffective(card, effect.from, self.player) then
			return nil
		end
			if card:isKindOf("Dismantlement") then
				sort_players(self,self.enemies, "handcard")
				for _, enemy in ipairs(self.enemies) do
					if self:doDisCard(enemy) and self:hasTrickEffective(card, effect.from, enemy) and  table.contains(targets, enemy)	then
						return enemy
					end
				end
				for _, enemy in ipairs(self.enemies) do
					if  self:hasTrickEffective(card, effect.from, enemy) and  table.contains(targets, enemy)	then
						return enemy
					end
				end
			end
	elseif card:isKindOf("GodFlower") or card:isKindOf("Snatch") then
		sort_players(self,self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if self:isEnemy(effect.from) and self:hasTrickEffective(card, effect.from, enemy) and (enemy:getJudgingArea():length() < 1 or not self:hasSkills(sgs.lose_equip_skill, enemy)) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif card:isKindOf("IronChain") then
		for _, friend in ipairs(self.friends) do
			if self:hasTrickEffective(card, effect.from, friend) and friend:isChained()  and  table.contains(targets, friend) then
				return friend
			end
		end
		
		for _, enemy in ipairs(self.enemies) do
			if  self:hasTrickEffective(card, effect.from, enemy)  and  table.contains(targets, enemy) and not enemy:isChained()	then
				return enemy
			end
		end
	end
	
	return nil
end

sgs.ai_target_revises.fatehuyou = function(to,card,self)
	if self:isFriend(to, self.player) then return false end
	if #self.friends_noself == 0 then return false end
	for _,friend in ipairs(self:getFriends(self.player, true))do
		if to:canSlash(friend, card) and self:slashIsEffective(card, friend, self.player) then return card:isNDTrick() and self.player~=to end
	end
	return card:isNDTrick() and self.player~=to
end

sgs.Irisviel_suit_value = 
{
	heart = 3.9,
	diamond = 3.8
}



sgs.ai_skill_invoke.fatejiejie = function(self, data)
	local effect = data:toCardEffect()
	if effect.card and effect.card:hasFlag("NosJiefanUsed") then return false  end

	if not effect.from or self:standardNullFilter(data, pattern, effect.from)
		or effect.card:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, effect.card, effect.from)
		or self:needToLoseHp(self.player, effect.from, effect.card) and self:ajustDamage(effect.from, self.player, 1, effect.card)==1 then return false end
	if self:needToLoseHp(self.player, effect.from, effect.card, true, true) then return false end
	if self:getCardsNum("Jink") == 0 then return true end
	
	return true
end

local fatemoshu_skill={}
fatemoshu_skill.name="fatemoshu_vs"
table.insert(package_skills,fatemoshu_skill)
fatemoshu_skill.getTurnUseCard=function(self,inclusive,request)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:getStrategyHasUsed("#fatemoshu_card") then return nil end
    local cards = self.player:getHandcards()
    cards=AIList.new(cards)
    sort_keep(self,cards)
	local card_str = ("#fatemoshu_card:%d:"):format(cards[1]:getId())
    return parse(self,request,card_str)
end

sgs.ai_skill_use_func["#fatemoshu_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and not enemy:hasSkill("tiandu") and self:doDisCard(enemy, "he") then
			use.card=final_parse(self,request,"#fatemoshu_card:" .. card:getKnownEffectiveId()..":")
			if use.to then
				use.to:append(enemy)
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:getOverflow()>0 then
			if self:doDisCard(enemy, "he") then
				use.card=final_parse(self,request,"#fatemoshu_card:" .. card:getKnownEffectiveId()..":")
				if use.to then
					use.to:append(enemy)
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
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:getStrategyHasUsed("#fatejuntuan_card") then return nil end
	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	for _, c in ipairs(cards) do
		if c:isBlack() then
            return parse(self,request,"#fatejuntuan_card:" .. c:getKnownEffectiveId()..":")
	   	end
	end
end

sgs.ai_skill_use_func["#fatejuntuan_card"]=function(card,use,self,request)
	local first
	sort_players(self,self.enemies, "hp") 
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and self.player:distanceTo(enemy) < 2
		then
			use.card=final_parse(self,request,"#fatejuntuan_card:" .. card:getKnownEffectiveId()..":")
			if use.to then
				use.to:append(enemy)
				first=enemy
				break
			end
		end
	end
	if first then 
		for _, enemy2 in ipairs(self.enemies) do
			if self:objectiveLevel(enemy2) > 3 and not self:cantbeHurt(enemy2) and self:canDamage(enemy2, self.player, nil)  and self:damageIsEffective(enemy2, sgs.DamageStruct_Normal, self.player) and self.player:distanceTo(enemy2) < 2 and (enemy2:getSeat()~=first:getSeat())
			then
				use.to:append(enemy2)
				return
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and self.player:distanceTo(enemy) < 2 then
				use.card=final_parse(self,request,"#fatejuntuan_card:" .. card:getKnownEffectiveId()..":")
				if use.to then
					use.to:append(enemy)
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
	return card:isBlack() and he_count(to) < 4
end


sgs.ai_skill_invoke.fatehuwei = function(self, data)
	if #self.friends_noself > 0 then
		return true
	end
	return false
end


sgs.ai_skill_playerchosen["@fatehuwei"] = function(self, targets)
	local choices = {}
	local card = self:getEvaluationCard("savage_assault")
	
	for _, target in sgs.qlist(targets) do
		local armor = target:getArmor()
		if self:isFriend(target)  and self:hasTrickEffective(card, target, self.player)
		and not (armor and armor:isKindOf("Vine"))
		then
			table.insert(choices, target)
		end
	end
	sort_players(self,choices, "hp")
	return choices[1]
end

sgs.ai_target_revises.fatehuwei = function(to, card)
	if card:isKindOf("SavageAssault")then
		return true
	end
end



sgs.ai_skill_invoke.fatepomo = function(self, data)
	return true
end

sgs.ai_skill_playerchosen["@fatepomo"] = function(self, targets)
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("beige") and not enemy:isNude() then
			return enemy
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("fateduoluo") and enemy:distanceTo(self.player)< 2 then
			return enemy
		end
	end
	sort_players(self,self.enemies, "hp") 
	
	
	
	
	
	
	for _, enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) <= self.player:getAttackRange() and
		(enemy:hasSkill("fatewangzhe") or enemy:hasSkill("fatemoli") or enemy:hasSkill("fateheijian") or enemy:hasSkill("fateyanfan_vs") or enemy:hasSkill("fatehuyou") or enemy:hasSkill("fatejiejie") or enemy:hasSkill("fateqienuo")
		or enemy:hasSkill("yiji") or enemy:hasSkill("jianxiong") or enemy:hasSkill("fankui") or enemy:hasSkill("qingguo") or enemy:hasSkill("ganglie")
		or enemy:hasSkill("yizhong") or enemy:hasSkill("kongcheng") or enemy:hasSkill("longdan") or enemy:hasSkill("bazhen") or enemy:hasSkill("kanpo")
		or enemy:hasSkill("wuyan") or enemy:hasSkill("liuli") or enemy:hasSkill("tianxiang") or enemy:hasSkill("leiji") or enemy:hasSkill("guhuo")
		or enemy:hasSkill("fangzhu") or enemy:hasSkill("weimu") or enemy:hasSkill("tuntian") or enemy:hasSkill("xiangle")
		or enemy:hasSkill("fengying") or enemy:hasSkill("guixin") or enemy:hasSkill("juejing") or enemy:hasSkill("longhun") or enemy:hasSkill("renjie")
		or ((enemy:hasSkill("fateshenghai") or enemy:hasSkill("fateshilian") or enemy:hasSkill("huilei") or enemy:hasSkill("zhuiyi") or enemy:hasSkill("jijiu")
		or enemy:hasSkill("buqu") or enemy:hasSkill("duanchang")) and enemy:getHp()<2))
		or enemy:getArmor()~= nil
		then
			return enemy
		end
	end
	
	
	
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("fatejiezhi") or enemy:hasSkill("fateshengqi") or enemy:hasSkill("kanpo") or enemy:hasSkill("guicai") or enemy:hasSkill("guidao")
		or enemy:hasSkill("jijiu")
		then
			return enemy
		end
	end
	
	
	
	
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("fatewangzhe") or enemy:hasSkill("fatehuyou") or enemy:hasSkill("yiji") or enemy:hasSkill("jieming") or enemy:hasSkill("fangzhu")
		or enemy:hasSkill("ganlu") or enemy:hasSkill("guixin")
		then
			return enemy
		end
	end

	
	
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("fatejianzhong") or enemy:hasSkill("fatehuwei") or enemy:hasSkill("fateheijian") or enemy:hasSkill("juxiang") or enemy:hasSkill("jianxiong")
		or enemy:hasSkill("huoshou") or enemy:hasSkill("weimu") or enemy:hasSkill("tuntian")
		then
			return enemy
		end
	end
	
	
	
	
	for _, enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) <= self.player:getAttackRange() and
		(enemy:hasSkill("fatejizhi") or enemy:hasSkill("fatefapao") or enemy:hasSkill("fatexianshen") or enemy:hasSkill("wusheng") or enemy:hasSkill("xiaoji")
		or enemy:hasSkill("yicong") or enemy:hasSkill("zhichi") or enemy:hasSkill("qianxun") or enemy:hasSkill("kuangbao") or enemy:hasSkill("huashen"))
		then
			return enemy
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("fatewangzhe") or enemy:hasSkill("fatemoli") or enemy:hasSkill("fateheijian") or enemy:hasSkill("fateyanfan") or enemy:hasSkill("fatehuyou") or enemy:hasSkill("fatejiejie")
		or enemy:hasSkill("yiji") or enemy:hasSkill("jianxiong") or enemy:hasSkill("fankui") or enemy:hasSkill("qingguo") or enemy:hasSkill("ganglie")
		or enemy:hasSkill("yizhong") or enemy:hasSkill("kongcheng") or enemy:hasSkill("longdan") or enemy:hasSkill("bazhen") or enemy:hasSkill("kanpo")
		or enemy:hasSkill("wuyan") or enemy:hasSkill("liuli") or enemy:hasSkill("tianxiang") or enemy:hasSkill("leiji") or enemy:hasSkill("guhuo")
		or enemy:hasSkill("fangzhu") or enemy:hasSkill("weimu") or enemy:hasSkill("tuntian") or enemy:hasSkill("xiangle")
		or enemy:hasSkill("fengying") or enemy:hasSkill("guixin") or enemy:hasSkill("juejing") or enemy:hasSkill("longhun") or enemy:hasSkill("renjie")
		or ((enemy:hasSkill("fateshenghai") or enemy:hasSkill("fateshilian") or enemy:hasSkill("huilei") or enemy:hasSkill("zhuiyi") or enemy:hasSkill("jijiu")
		or enemy:hasSkill("buqu") or enemy:hasSkill("duanchang")) and enemy:getHp()==1)
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
	local use = data:toCardUse()
	if self.player:getHandcardNum()<1 then return nil end
    for _, target in sgs.qlist(use.to) do
		if self:isFriend(target) then return false end
		if self:cantDamageMore(self.player, target) then return false end
    	return true
	end
	return false
end

sgs.ai_ajustdamage_from.fatetuci = function(self,from,to,card,nature)
	if card and card:isKindOf("Slash") and from:getHandcardNum()>0 and not self:beFriend(to, from)
	then return 1 end
end


sgs.ai_skill_cardask["@fatetuci"] = function(self, data, pattern, target)
	local cards = AIList.new(self.player:getCards("h"))
	sort_keep(self,cards)
	for _, card in ipairs(cards) do
		return "$" .. card:getKnownEffectiveId()
	end
	return "."
end

sgs.hit_skill = sgs.hit_skill .. "|fatetuci"

local fatesiji_skill={}
fatesiji_skill.name="fatesiji_vs"
table.insert(package_skills,fatesiji_skill)
fatesiji_skill.getTurnUseCard=function(self,inclusive,request)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:getStrategyHasUsed("#fatesiji_card") then return nil end
	if self.player:getLostHp()<2 then return nil end
	local cards = self.player:getCards("he")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	for _, c in ipairs(cards) do
		if c:isKindOf("Weapon") then
            return parse(self,request,"#fatesiji_card:" .. c:getKnownEffectiveId()..":")
	   	end
	end
end

sgs.ai_skill_use_func["#fatesiji_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy)  and self:canDamage(enemy, self.player, nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and self.player:distanceTo(enemy) < 3 then
			use.card=final_parse(self,request,"#fatesiji_card:" .. card:getKnownEffectiveId()..":")
			if use.to then
				use.to:append(enemy)
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
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getKnownEffectiveId()
	if card:isKindOf("BasicCard") then
        return material(card,"jink","fateqienuo")
    end
end

sgs.ai_skill_invoke.fateqiangtui = function(self, data)
	local room = self.room
	local players = room:getOtherPlayers(self.player)
	for _, target in sgs.qlist(players) do
		if self:isEnemy(target) and not target:isKongcheng() and (target:getSeat()==(self.player:getNextAlive()):getSeat() or self.player:getSeat()==(target:getNextAlive()):getSeat()) then
			return true
		end
	end
	for _, target in sgs.qlist(players) do
		if self.player:isWounded() and not target:isKongcheng() and target:isFemale()
		and (target:getSeat()==(self.player:getNextAlive()):getSeat() or self.player:getSeat()==(target:getNextAlive()):getSeat())
		then
			return true
		end
	end
    return false
end

sgs.ai_skill_playerchosen.fateqiangtui = function(self, targets) 
	local choices = {}
	if self.player:getLostHp() > 0 then
		for _, target in sgs.qlist(targets) do
			if self:isEnemy(target) and not target:isKongcheng() and target:isFemale() then
				table.insert(choices, target)
			end
		end
		if #choices ~= 0 then
			sort_players(self,choices, "hp")
			return choices[1]
		else
			for _, target in sgs.qlist(targets) do
				if not target:isKongcheng() and target:isFemale() then
					table.insert(choices, target)
				end
			end
			sort_players(self,choices, "hp", true)
			return choices[1]
		end
	end
	
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) and not target:isKongcheng() then
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
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:getStrategyHasUsed("#fatechongshu_card") then return nil end
    local cards = self.player:getHandcards()
    cards=AIList.new(cards)
    sort_keep(self,cards)
	local card_str = ("#fatechongshu_card:%d:"):format(cards[1]:getId())
    return parse(self,request,card_str)
end

sgs.ai_skill_use_func["#fatechongshu_card"]=function(card,use,self,request)
	sort_players(self,self.enemies, "hp") 
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp()<2 and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and enemy:getHandcardNum()<2
		then
			use.card=final_parse(self,request,"#fatechongshu_card:" .. card:getKnownEffectiveId()..":")
			if use.to then
				use.to:append(enemy)
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if (self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and enemy:getHandcardNum()<2) or (enemy:getHandcardNum()>1 and self:doDisCard(enemy, "h"))
		then
			use.card=final_parse(self,request,"#fatechongshu_card:" .. card:getKnownEffectiveId()..":")
			if use.to then
				use.to:append(enemy)
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
	if self.player:getMark("@fatejiushu_mark")==0 then return false end
	if self.player:getKnownRole()=="renegade"  then return false end
    return (#self.friends_noself > 0)
end









sgs.ai_skill_playerchosen["@fatejiushu"]= function(self, targets) 
	if self.player:getKnownRole() == "loyalist" and self.room:getLord() then
		return self.room:getLord()
	end
	sort_players(self,self.friends_noself, "chaofeng")
	for _, friend in ipairs(self.friends_noself) do
        if (friend:hasSkill("qingnang") or friend:hasSkill("jieyin") or friend:hasSkill("fateqingxing") or friend:hasSkill("fatechuyi_vs")) and role(self,friend)~="renegade" then
            return friend
        end
    end
	for _, friend in ipairs(self.friends_noself) do
        if friend:hasSkill("dimeng") and friend:hasSkill("haoshi") and role(self,friend)~="renegade" then
            return friend
        end
    end
	for _, friend in ipairs(self.friends_noself) do
        if (friend:hasSkill("fatejiezhi") or friend:hasSkill("lijian") or friend:hasSkill("fatezonghe")) and role(self,friend)~="renegade" then
            return friend
        end
    end
	
    local lord = self.room:getLord()
    if self:isFriend(lord) and not self.player:isLord() then
        return lord
    end
	
    for _, friend in ipairs(self.friends_noself) do
        if friend:getHp()<2 and role(self,friend)~="renegade" then
			return friend
        end
    end
	for _, friend in ipairs(self.friends_noself) do
        if role(self,friend)~="renegade" and not ((friend:hasSkill("yiji") or friend:hasSkill("jieming") or friend:hasSkill("fangzhu") or friend:hasSkill("guixin")) and friend:getHp()>1) then
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
