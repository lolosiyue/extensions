-- Fixed YJCM2013 source policies. Native receipts alone authorize card costs.
sgs.ai_choicemade_filter.skillInvoke=sgs.ai_choicemade_filter.skillInvoke or {}
sgs.ai_choicemade_filter.cardChosen=sgs.ai_choicemade_filter.cardChosen or {}
local function known(value,key)
    if value==nil then ai_unsupported("YJCM2013 input is not projected",key) end
    return value
end
local function skill(self,player,names)
    local value=player:hasSkills(names)
    local row=rawget(player,"_view")
    if value==true or value~=nil and (not row or row.skills_complete==true) then return value end
    if player:objectName()==self.player:objectName() then ai_unsupported("owner skills are incomplete","yjcm2013.skills") end
    return self:useKnowledgeEstimate({status="estimate",value=false,basis="yjcm2013.undisclosed_skills_use_visible_roster",target=player:objectName()},"yjcm2013.skills")
end
local function flag(self,player,name)
    local value=player:getStrategyFlag(name)
    if value~=nil then return value end
    return self:useKnowledgeEstimate({status="estimate",value=false,basis="yjcm2013.unknown_foreign_flag_uses_public_state",target=player:objectName(),flag=name},"yjcm2013.flag")
end
local function sort_in_place(self,players,key,reverse)
    local ordered=self:sort(players,key,reverse)
    for i,player in ipairs(ordered) do players[i]=player end
    return players
end
local function reversed(cards)
    local result={};for i=#cards,1,-1 do result[#result+1]=cards[i]end;return AIList.new(result)
end
local function current_damage(self)
    local raw=known(self.world.strategy_facts and self.world.strategy_facts.standard and self.world.strategy_facts.standard.current_damage,"yjcm2013.current_damage")
    if raw==false then return {} end
    local result={};for k,v in pairs(raw)do result[k]=v end
    for _,key in ipairs({"from","to"}) do
        local name=result[key];result[key]=name and name~="" and self.room:findPlayerByObjectName(name,true) or nil
    end
    result.damage=result.amount
    if result.card then result.card=CardView.new(result.card)end
    return result
end
local function material(self,id)
    return known(self:getKnownCardById(id) or self:getChoiceCard(id),"yjcm2013.disclosed_material")
end
local function own_pile(self,name)
    local result={};for _,id in ipairs(known(self.player:getPile(name),"yjcm2013.owner_pile"))do result[#result+1]=material(self,id)end
    return AIList.new(result)
end
local function policy_card(self,skill_name,class,costs,request)
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room)end
    local authority=self:bindSkillCard(skill_name,costs,request)
    local suit,number=sgs.Card_NoSuit,0
    if #costs==1 then local c=material(self,costs[1]);suit,number=c:getSuit(),c:getNumber()
    elseif #costs>1 then
        local red,black=true,true
        for _,id in ipairs(costs)do local c=material(self,id);red=red and known(c:isRed(),"yjcm2013.material_color");black=black and known(c:isBlack(),"yjcm2013.material_color")end
        suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
    end
    local suits={[sgs.Card_Spade]="spade",[sgs.Card_Club]="club",[sgs.Card_Heart]="heart",[sgs.Card_Diamond]="diamond",[sgs.Card_NoSuitBlack]="no_suit_black",[sgs.Card_NoSuitRed]="no_suit_red",[sgs.Card_NoSuit]="no_suit"}
    local rank=number>13 and "JOKER" or ({[1]="A",[11]="J",[12]="Q",[13]="K"})[number] or tostring(number)
    local key="@"..class.."["..known(suits[suit],"yjcm2013.policy_suit")..":"..rank.."]="..(#costs>0 and table.concat(costs,"+")or".")
    local keeps=class=="MiejiCard" or class=="ZongxuanCard"
    local policy={name="",class_name=class,type_id=0,kind_of={class,"SkillCard","Card"},suit=suit,number=number,
        subcards=costs,red=suit==sgs.Card_Heart or suit==sgs.Card_Diamond or suit==sgs.Card_NoSuitRed,
        black=suit==sgs.Card_Spade or suit==sgs.Card_Club or suit==sgs.Card_NoSuitBlack,
        damage_card=false,can_recast=false,handling_method=keeps and sgs.Card_MethodNone or sgs.Card_MethodDiscard,
        will_throw=not keeps,legacy_string_key=key,legacy_sort_key=key}
    if #costs>0 then policy.effective_id=costs[1]end
    return self:legacyPolicyCard(authority,policy)
end
local function action(self,skill_name,costs,targets,request,user_string)
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room)end
    local use=AIUsePlan.new();use.card=self:bindSkillCard(skill_name,costs,request,user_string);use.to=AIList.new(targets or{})
    return known(use:toAnswer(),"yjcm2013.action")
end

local function remove_one(list,value)
 for i,item in ipairs(list)do if item==value then table.remove(list,i);return true end end
 return false
end
local function dummy(is_dummy,extra,targets)
 return {isDummy=is_dummy~=false,extra_target=extra or 0,current_targets=targets or {},to=AIList.new({})}
end
local classes={JunxingCard="junxing",DanshouCard="danshou",MiejiCard="mieji",FenchengCard="fencheng",XiansiCard="xiansi",XiansiSlashCard="xiansi_slash",QiaoshuiCard="qiaoshui",ExtraCollateralCard="qiaoshui"}
local function parse_source_costs(text)
 local costs={};if text~="." then for id in text:gmatch("[^+]+")do costs[#costs+1]=known(tonumber(id),"yjcm2013.authored_cost")end end;return costs
end
local function source_card(self,text,request)
 local class,ids=text:match("^@(%w+)=(.+)$")
 return policy_card(self,known(classes[class],"yjcm2013.authored_class"),class,parse_source_costs(known(ids,"yjcm2013.authored_costs")),request)
end
local function source_action(self,text,request)
 if text=="." or text==nil then return text end
 local class,ids,names=text:match("^@(%w+)=(.-)%->(.*)$")
 if not class then class,ids=text:match("^@(%w+)=(.+)$")end
 local targets={};for name in (names or ""):gmatch("[^+]+")do targets[#targets+1]=known(self.room:findPlayerByObjectName(name),"yjcm2013.authored_target")end
 return action(self,known(classes[class],"yjcm2013.authored_class"),parse_source_costs(known(ids,"yjcm2013.authored_costs")),targets,request)
end
local function disclosed_hand(self,player)
 return known(self:getKnownCards(player,self.player,"h"),"yjcm2013.visible_hand")
end
local function top_card(self)
 local row=self:getDecisionContext().zhiyan_top_card
 if row==nil then
  self:useKnowledgeEstimate({status="estimate",value=false,basis="yjcm2013.zhiyan_no_disclosed_top_uses_unknown_top"},"yjcm2013.zhiyan_top")
  return nil
 end
 return row~=false and CardView.new(row) or nil
end
local function remembered_player(self,key)
 local name=self:getStrategyMemory("yjcm2013."..key)
 return name and self.room:findPlayerByObjectName(name) or nil
end

sgs.ai_skill_cardask["@renxin-card"] = function(self,data,pattern)
	local dmg = data:toDamage()
	local invoke
	if self:isFriend(dmg.to) then
		if self:damageStruct(dmg) and not self:needToLoseHp(dmg.to,dmg.from,dmg.card)
		or not self:toTurnOver(self.player)
		then invoke = true end
	elseif self:objectiveLevel(dmg.to)==0 and not self:toTurnOver(self.player)
	then invoke = true end
	if invoke then
		local equipCards = {}
		for _,c in ipairs(self.player:getCards("he"))do
			if c:isKindOf("EquipCard") and self.player:canDiscard(self.player,c:getEffectiveId()) then
				table.insert(equipCards,c)
			end
		end
		if #equipCards>0 then
			equipCards = self:sortByKeepValue(equipCards)
			return equipCards[1]:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_skill_invoke.jingce = function(self,data)
	return not self:needKongcheng(self.player,true)
end

sgs.ai_can_damagehp.chengxiang = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end
sgs.ai_skill_defense.chengxiang = 2

sgs.ai_fill_skill.junxing = function(self,inclusive,request)
	if self.player:isKongcheng() then return nil end
	return self:legacySkillSeed("junxing","JunxingCard",request)
end

sgs.ai_skill_use_func.JunxingCard = function(card,use,self,request)
	-- find enough cards
	local unpreferedCards = {}
	local cards = AIList.new(self.player:getHandcards())
	local use_slash_num = 0
	cards = self:sortByKeepValue(cards)
	for _,card in ipairs(cards)do
		if card:isKindOf("Slash") then
			local will_use = false
			if use_slash_num<=known(card:getTargetModResidue(),"junxing.residue") then
				local dummy_use = dummy()
				self:useBasicCard(card,dummy_use)
				if dummy_use.card then
					will_use = true
					use_slash_num = use_slash_num+1
				end
			end
			if not will_use then table.insert(unpreferedCards,card:getId()) end
		end
	end
	local num = self:getCardsNum("Jink")-1
	if self.player:getArmor() then num = num+1 end
	if num>0 then
		for _,card in ipairs(cards)do
			if card:isKindOf("Jink") and num>0 then
				table.insert(unpreferedCards,card:getId())
				num = num-1
			end
		end
	end
	for _,card in ipairs(cards)do
		if card:isKindOf("EquipCard") then
			local dummy_use = dummy()
			self:useEquipCard(card,dummy_use)
			if not dummy_use.card then table.insert(unpreferedCards,card:getId()) end
		end
	end
	for _,card in ipairs(cards)do
		if card:isNDTrick() or card:isKindOf("Lightning") then
			local dummy_use = dummy()
			self:useTrickCard(card,dummy_use)
			if not dummy_use.card then table.insert(unpreferedCards,card:getId()) end
		end
	end
	local use_cards = {}
	for index = #unpreferedCards,1,-1 do
		if not self.player:isJilei(material(self,unpreferedCards[index])) then table.insert(use_cards,unpreferedCards[index]) end
	end
	if #use_cards==0 then return end

	-- to friends
	sort_in_place(self,self.friends_noself,"defense")
	for _,friend in ipairs(self.friends_noself)do
		if not self:toTurnOver(friend,#use_cards) then
			use.card = source_card(self,"@JunxingCard="..table.concat(use_cards,"+"),request)
			use.to:append(friend)
			return
		end
	end
	if #use_cards>3 then
		for _,friend in ipairs(self.friends_noself)do
			if skill(self,friend,sgs.notActive_cardneed_skill) and not skill(self,friend,sgs.Active_cardneed_skill) then
				use.card = source_card(self,"@JunxingCard="..table.concat(use_cards,"+"),request)
				use.to:append(friend)
				return
			end
		end
	end

	-- to enemies
	local basic,trick,equip
	for _,id in ipairs(use_cards)do
		local typeid = known(self:getPrintedCardById(id),"junxing.printed_card"):getTypeId()
		if not basic and typeid==sgs.Card_TypeBasic then basic = id
		elseif not trick and typeid==sgs.Card_TypeTrick then trick = id
		elseif not equip and typeid==sgs.Card_TypeEquip then equip = id
		end
		if basic and trick and equip then break end
	end
	sort_in_place(self,self.enemies,"handcard")
	local other_enemy
	for _,enemy in ipairs(self.enemies)do
		local id = nil
		if self:toTurnOver(enemy,1) then
			if getKnownCard(enemy,self.player,"BasicCard")==0 then id = equip or trick end
			if not id and getKnownCard(enemy,self.player,"TrickCard")==0 then id = equip or basic end
			if not id and getKnownCard(enemy,self.player,"EquipCard")==0 then id = trick or basic end
			if id then
				use.card = source_card(self,"@JunxingCard="..id,request)
				use.to:append(enemy)
				return
			elseif not other_enemy then
				other_enemy = enemy
			end
		end
	end
	if other_enemy then
		use.card = source_card(self,"@JunxingCard="..use_cards[1],request)
		use.to:append(other_enemy)
		return
	end
end

sgs.ai_use_priority.JunxingCard = 1.2
sgs.ai_card_intention.JunxingCard = function(self,card,from,tos)
	local to = tos[1]
	if not to:faceUp() then
		sgs.updateIntention(from,to,-80)
	else
		if to:getHandcardNum()<=1 and card:subcardsLength()>=3 then
			sgs.updateIntention(from,to,-40)
		else
			sgs.updateIntention(from,to,80)
		end
	end
end

sgs.ai_skill_cardask["@junxing-discard"] = function(self,data,pattern)
	local manchong = self.room:findPlayerBySkillName("junxing")
	if manchong and self:isFriend(manchong) then return "." end

	local types = pattern:split("|")[1]:split(",")
	local cards = AIList.new(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	for _,card in ipairs(cards)do
		if not self:isValuableCard(card) then
			for _,classname in ipairs(types)do
				if card:isKindOf(classname) then return "$"..card:getEffectiveId() end
			end
		end
	end
	return "."
end

sgs.ai_skill_cardask["@yuce-show"] = function(self,data)
	local damage = current_damage(self)
	if not damage.from or damage.from:isDead() then return "." end
	if self:isFriend(damage.from) then return "$"..self.player:handCards():first() end
	local flag = string.format("%s_%s_%s","visible",self.player:objectName(),damage.from:objectName())
	local types = { sgs.Card_TypeBasic,sgs.Card_TypeEquip,sgs.Card_TypeTrick }
	for _,card in ipairs(disclosed_hand(self,damage.from))do
		if true then -- viewer-disclosed hand member
			remove_one(types,card:getTypeId())
		end
		if #types==0 then break end
	end
	if #types==0 then types = { sgs.Card_TypeBasic } end
	for _,card in ipairs(self.player:getHandcards())do
		for _,cardtype in ipairs(types)do
			if card:getTypeId()==cardtype then return "$"..card:getEffectiveId() end
		end
	end
	return "$"..self.player:handCards():first()
end

sgs.ai_skill_cardask["@yuce-discard"] = function(self,data,pattern,target)
	if target and self:isFriend(target) then return "." end
	local types = pattern:split("|")[1]:split(",")
	local cards = AIList.new(self.player:getHandcards())
	cards = self:sortByUseValue(cards)
	for _,card in ipairs(cards)do
		if not self:isValuableCard(card) then
			for _,classname in ipairs(types)do
				if card:isKindOf(classname) then return "$"..card:getEffectiveId() end
			end
		end
	end
	return "."
end

local function policy___xiansi(self,prompt)
	local crossbow_effect
	if false then -- donor precedence: (not string) == "xiansi"
		for _,enemy in ipairs(self.enemies)do
			if enemy:inMyAttackRange(self.player) and (self:hasCrossbowEffect(enemy) or getKnownCard(enemy,self.player,"Crossbow")>0) then
				crossbow_effect = true
				break
			end
		end
	end
	local max_num = 999
	if crossbow_effect then max_num = 3
	elseif self:getCardsNum("Jink")<1 or self:isWeak() then max_num = 5 end
	if self.player:getPile("counter"):length()>=max_num then return "." end
	local rest_num = math.min(2,max_num-self.player:getPile("counter"):length())
	local targets = {}

	local add_player = function(player,isfriend)
		if player:getHandcardNum()==0 or player:objectName()==self.player:objectName() then return #targets end
		if self:objectiveLevel(player)==0 and player:isLord() and known(self:getRoleCounts().rebel,"xiansi.roles")>1 then return #targets end
		if #targets==0 then
			table.insert(targets,player:objectName())
		elseif #targets==1 then
			if player:objectName()~=targets[1] then
				table.insert(targets,player:objectName())
			end
		end
		if isfriend and isfriend==1 then
			self:setStrategyPlayerFlag(self.player,"AI_XiansiToFriend_"..player:objectName(),true)
		end
		return #targets
	end

	local player = self:findPlayerToDiscard("he",true,false)[1]
	if player then
		if rest_num==1 then return "@XiansiCard=.->"..player:objectName() end
		add_player(player,self:isFriend(player) and 1 or nil)
		local another = self:findPlayerToDiscard("he",true,false,self.room:getOtherPlayers(player))[1]
		if another then
			add_player(another,self:isFriend(another) and 1 or nil)
			return "@XiansiCard=.->"..table.concat(targets,"+")
		end
	end

	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and known(self.room:getTurnCount(),"xiansi.turn_count")<=1 and not lord:isNude() then
		if add_player(lord)==rest_num then return "@XiansiCard=.->"..table.concat(targets,"+") end
	end

	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	local luxun = self.room:findPlayerBySkillName("lianying") or self.room:findPlayerBySkillName("noslianying")
	local dengai = self.room:findPlayerBySkillName("tuntian")
	local jiangwei = self.room:findPlayerBySkillName("zhiji")

	if jiangwei and self:isFriend(jiangwei) and jiangwei:getMark("zhiji")==0 and jiangwei:getHandcardNum()==1
		and self:getEnemyNumBySeat(self.player,jiangwei)<=(jiangwei:getHp()>=3 and 1 or 0) then
		if add_player(jiangwei,1)==rest_num then return "@XiansiCard=.->"..table.concat(targets,"+") end
	end
	if dengai and skill(self,dengai,"zaoxian") and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai)==0)
		and dengai:getMark("zaoxian")==0 and dengai:getPile("field"):length()==2 and add_player(dengai,1)==rest_num then
		return "@XiansiCard=.->"..table.concat(targets,"+")
	end

	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum()==1 and self:getEnemyNumBySeat(self.player,zhugeliang)>0 then
		if zhugeliang:getHp()<=2 then
			if add_player(zhugeliang,1)==rest_num then return "@XiansiCard=.->"..table.concat(targets,"+") end
		else
			local flag = string.format("%s_%s_%s","visible",self.player:objectName(),zhugeliang:objectName())
			local cards = AIList.new(disclosed_hand(self,zhugeliang))
			if #cards==1 then
				if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
					if add_player(zhugeliang,1)==rest_num then return "@XiansiCard=.->"..table.concat(targets,"+") end
				end
			end
		end
	end

	if luxun and self:isFriend(luxun) and luxun:getHandcardNum()==1 and self:getEnemyNumBySeat(self.player,luxun)>0 then
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),luxun:objectName())
		local cards = AIList.new(disclosed_hand(self,luxun))
		if #cards==1 then
			if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
				if add_player(luxun,1)==rest_num then return "@XiansiCard=.->"..table.concat(targets,"+") end
			end
		end
	end

	if luxun and add_player(luxun,(self:isFriend(luxun) and 1 or nil))==rest_num then
		return "@XiansiCard=.->"..table.concat(targets,"+")
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai)==0) and add_player(dengai,1)==rest_num then
		return "@XiansiCard=.->"..table.concat(targets,"+")
	end

	if #targets==1 then
		local target = self.room:findPlayerByObjectName(targets[1])
		if target then
			local another
			if rest_num>1 then another = self:findPlayerToDiscard("he",true,false,self.room:getOtherPlayers(target))[1] end
			if another then
				add_player(another,self:isFriend(another) and 1 or nil)
				return "@XiansiCard=.->"..table.concat(targets,"+")
			else
				return "@XiansiCard=.->"..targets[1]
			end
		end
	end
	return "."
end

sgs.ai_card_intention.XiansiCard = function(self,card,from,tos)
	local lord = self.room:getLord()
	if self:getRoleEstimate(from)=="neutral" and self:getRoleEstimate(tos[1])=="neutral"
		and (not tos[2] or self:getRoleEstimate(tos[2])=="neutral") and lord and not lord:isNude()
		and self:doDisCard(lord,"he",true) and from:aliveCount()>=4 then
		sgs.updateIntention(from,lord,-35)
		return
	end
	if from:getState()=="online" then
		for _,to in ipairs(tos)do
			if (self:hasSkills("kongcheng|zhiji|lianying|noslianying",to) and to:getHandcardNum()==1) or self:hasTuntianEffect(to, true) then
			else
				sgs.updateIntention(from,to,80)
			end
		end
	else
		for _,to in ipairs(tos)do
			local intention = flag(self,from,"AI_XiansiToFriend_"..to:objectName()) and -5 or 80
			sgs.updateIntention(from,to,intention)
		end
	end
end

local getXiansiCard = function(pile)
	if #pile>1 then return pile[1],pile[2] end
	return nil
end

sgs.ai_fill_skill.xiansi_slash = function(self,inclusive,request)
	local liufeng = self.room:findPlayerBySkillName("xiansi")
	if not liufeng or liufeng:getPile("counter"):length()<=1 or not self.player:canSlash(liufeng) then return end
	local ints = AIList.new(liufeng:getPile("counter"))
	local a,b = getXiansiCard(ints)
	if a and b then
		return source_card(self,"@XiansiSlashCard="..a.."+"..b,request)
	end
end

sgs.ai_skill_use_func.XiansiSlashCard = function(card,use,self,request)
	local liufeng = self.room:findPlayerBySkillName("xiansi")
	if not liufeng or liufeng:getPile("counter"):length()<=1 or not self.player:canSlash(liufeng) then return "." end
	local slash = known(self:getEvaluationCard("slash"),"xiansi_slash.dummy")

	if self:slashIsAvailable() and not self:slashIsEffective(slash,liufeng,self.player) and self:isFriend(liufeng) then
		self:setPriorityValue("XiansiSlashCard",0.1,"xiansi_slash")
		use.card = card
		use.to:append(liufeng)
	else
		self:setPriorityValue("XiansiSlashCard",2.6,"xiansi_slash")
		local dummy_use = dummy()
		self:useCardSlash(slash,dummy_use)
		if dummy_use.card then
			if (dummy_use.card:isKindOf("GodSalvation") or dummy_use.card:isKindOf("Analeptic") or dummy_use.card:isKindOf("Weapon"))
				and self:getCardsNum("Slash")>0 then
				use.card = dummy_use.card
				use.to:append(liufeng)
			else
				if dummy_use.card:isKindOf("Slash") and dummy_use.to:length()>0 then
					local lf
					for _,p in ipairs(dummy_use.to)do
						if p:objectName()==liufeng:objectName() then
							lf = true
							break
						end
					end
					if lf then
						use.card = card
						use.to:append(liufeng)
					end
				end
			end
		end
	end
	if not use.card then
		self:setPriorityValue("XiansiSlashCard",2.0,"xiansi_slash")
		if self:slashIsAvailable() and self:isEnemy(liufeng)
		and not self:slashProhibit(slash,liufeng) 
		and self:slashIsEffective(slash,liufeng) 
		and self:isGoodTarget(liufeng,self.enemies,slash) then
			use.card = card
			use.to:append(liufeng)
		end
	end
end

sgs.ai_card_intention.XiansiSlashCard = function(self,card,from,tos)
	local slash = known(self:getEvaluationCard("slash"),"xiansi_slash.dummy")
	if not self:slashIsEffective(slash,tos[1],from) then
		sgs.updateIntention(from,tos[1],-30)
	else
		return sgs.ai_card_intention.Slash(self,slash,from,tos)
	end
end

sgs.ai_skill_cardask["@longyin"] = function(self,data)
	local function getLeastValueCard(isRed)
		local offhorse_avail,weapon_avail
		for _,enemy in ipairs(self.enemies)do
			if self:canAttack(enemy,self.player) then
				if not offhorse_avail and self.player:getOffensiveHorse() and self.player:distanceTo(enemy,1)<=self.player:getAttackRange() then
					offhorse_avail = true
				end
				if not weapon_avail and self.player:getWeapon() and self.player:distanceTo(enemy)==1 then
					weapon_avail = true
				end
			end
			if offhorse_avail and weapon_avail then break end
		end
		if self:needToThrowArmor() then return "$"..self.player:getArmor():getEffectiveId() end
		if self.player:getPhase()>sgs.Player_Play then
			local cards = AIList.new(self.player:getHandcards())
			cards = self:sortByKeepValue(cards)
			for _,c in ipairs(cards)do
				if self:getKeepValue(c)<8 and not self.player:isJilei(c) and not self:isValuableCard(c) then return "$"..c:getEffectiveId() end
			end
			if offhorse_avail and not self.player:isJilei(self.player:getOffensiveHorse()) then return "$"..self.player:getOffensiveHorse():getEffectiveId() end
			if weapon_avail and not self.player:isJilei(self.player:getWeapon()) and self:evaluateWeapon(self.player:getWeapon())<5 then return "$"..self.player:getWeapon():getEffectiveId() end
		else
			local slashc
			local cards = AIList.new(self.player:getHandcards())
			cards = self:sortByUseValue(cards)
			for _,c in ipairs(cards)do
				if self:getUseValue(c)<6 and not self:isValuableCard(c) and not self.player:isJilei(c) then
					if isCard("Slash",c,self.player) then
						if not slashc then slashc = c end
					else
						return "$"..c:getEffectiveId()
					end
				end
			end
			if offhorse_avail and not self.player:isJilei(self.player:getOffensiveHorse()) then return "$"..self.player:getOffensiveHorse():getEffectiveId() end
			if isRed and slashc then return "$"..slashc:getEffectiveId() end
		end
	end
	local use = data:toCardUse()
	local slash = use.card
	local slash_num = 0
	if use.from:objectName()==self.player:objectName() then slash_num = self:getCardsNum("Slash") else slash_num = getCardsNum("Slash",use.from,self.player) end
	if self:isEnemy(use.from) and known(use.m_addHistory,"longyin.add_history") and not self:hasCrossbowEffect(use.from) and slash_num>0 then return "." end
	if (slash:isRed() and not self:hasManjuanEffect(self.player))
		or (use.m_reason==sgs.CardUseStruct_CARD_USE_REASON_PLAY and known(use.m_addHistory,"longyin.add_history") and self:isFriend(use.from) and slash_num>=1
			and (not self:hasCrossbowEffect(use.from) or slash:isRed())) then
		local str = getLeastValueCard(slash:isRed())
		if str then return str end
	end
	return "."
end

local function policy___qiaoshui(self,prompt)
	local trick_num = 0
	for _,card in ipairs(self.player:getHandcards())do
		if card:isNDTrick() and not card:isKindOf("Nullification") then trick_num = trick_num+1 end
	end
	sort_in_place(self,self.enemies,"handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()

	for _,enemy in ipairs(self.enemies)do
		if not (skill(self,enemy,"kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
			if max_point>enemy_max_point then
				self:remember("qiaoshui_card",max_card:getEffectiveId())
				return "@QiaoshuiCard=.->"..enemy:objectName()
			end
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if not (skill(self,enemy,"kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) then
			if max_point>=10 then
				self:remember("qiaoshui_card",max_card:getEffectiveId())
				return "@QiaoshuiCard=.->"..enemy:objectName()
			end
		end
	end

	sort_in_place(self,self.friends_noself,"handcard")
	for index = #self.friends_noself,1,-1 do
		local friend = self.friends_noself[index]
		if self.player:canPindian(friend) then
			local friend_min_card = self:getMinCard(friend)
			local friend_min_point = friend_min_card and friend_min_card:getNumber() or 100
			if max_point>friend_min_point then
				self:remember("qiaoshui_card",max_card:getEffectiveId())
				return "@QiaoshuiCard=.->"..friend:objectName()
			end
		end
	end

	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum()==1 and zhugeliang:objectName()~=self.player:objectName()
		and self.player:canPindian(zhugeliang) then
		if max_point>=7 then
			self:remember("qiaoshui_card",max_card:getEffectiveId())
			return "@QiaoshuiCard=.->"..zhugeliang:objectName()
		end
	end

	for index = #self.friends_noself,1,-1 do
		local friend = self.friends_noself[index]
		if self.player:canPindian(friend) then
			if max_point>=7 then
				self:remember("qiaoshui_card",max_card:getEffectiveId())
				return "@QiaoshuiCard=.->"..friend:objectName()
			end
		end
	end

	if trick_num==0 or (trick_num<=2 and skill(self,self.player,"zongshih")) and not self:isValuableCard(max_card) then
		for _,enemy in ipairs(self.enemies)do
			if not (skill(self,enemy,"kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and self:hasLoseHandcardEffective(enemy) then
				self:remember("qiaoshui_card",max_card:getEffectiveId())
				return "@QiaoshuiCard=.->"..enemy:objectName()
			end
		end
	end
	return "."
end

sgs.ai_card_intention.QiaoshuiCard = 0

sgs.ai_skill_choice.qiaoshui = function(self,choices,data)
	self:setStrategyMemory("yjcm2013.qiaoshui_target",nil)
	self:setStrategyMemory("yjcm2013.qiaoshui_collateral",nil)
	local use = data:toCardUse()
	local dummy_use = dummy(true,0,use.to)
	if use.card:isKindOf("Collateral") and choices:contains("add") then
		self:useCardCollateral(use.card,dummy_use)
		if dummy_use.card and dummy_use.to:length()==2 then
			local first = dummy_use.to:at(0):objectName()
			local second = dummy_use.to:at(1):objectName()
			self:setStrategyMemory("yjcm2013.qiaoshui_collateral",{first,second})
			return "add"
		end
	elseif use.card:isKindOf("Peach") and choices:contains("add") then
		sort_in_place(self,self.friends_noself,"hp")
		for _,friend in ipairs(self.friends_noself)do
			if friend:isWounded() and friend:getHp()<getBestHp(friend) then
				self:setStrategyMemory("yjcm2013.qiaoshui_target",(friend):objectName())
				return "add"
			end
		end
	elseif use.card:isKindOf("GodSalvation") and choices:contains("remove") then
		sort_in_place(self,self.enemies,"hp")
		for _,enemy in ipairs(self.enemies)do
			if use.to:contains(enemy) and enemy:isWounded()
			and self:hasTrickEffective(use.card,enemy,self.player) then
				self:setStrategyMemory("yjcm2013.qiaoshui_target",(enemy):objectName())
				return "remove"
			end
		end
	elseif use.card:isKindOf("AmazingGrace") and choices:contains("remove") then
		sort_in_place(self,self.enemies)
		for _,enemy in ipairs(self.enemies)do
			if self:hasTrickEffective(use.card,enemy,self.player) and not self:hasManjuanEffect(enemy)
			and not self:needKongcheng(enemy,true) then
				self:setStrategyMemory("yjcm2013.qiaoshui_target",(enemy):objectName())
				return "remove"
			end
		end
	elseif use.card:isKindOf("AOE") and choices:contains("remove") then
		sort_in_place(self,self.friends_noself)
		local lord = self.room:getLord()
		if lord and use.to:contains(lord) and self:isFriend(lord) and self:isWeak(lord) then
			self:setStrategyMemory("yjcm2013.qiaoshui_target",(lord):objectName())
			return "remove"
		end
		for _,friend in ipairs(self.friends_noself)do
			if use.to:contains(friend)
			and self:hasTrickEffective(use.card,friend,self.player) then
				self:setStrategyMemory("yjcm2013.qiaoshui_target",(friend):objectName())
				return "remove"
			end
		end
	elseif use.card:targetFixed() and choices:contains("add") then
		local friends = self:findPlayerToDraw(false,2,#self.friends_noself,true)
		if #friends>0 then
			for _,p in ipairs(friends)do
				if not self:hasTrickEffective(use.card,p,self.player)
				or self.player:isProhibited(p,use.card) then continue end
				self:setStrategyMemory("yjcm2013.qiaoshui_target",(p):objectName())
				return "add"
			end
		end
	elseif choices:contains("add") then
		self:aiUseCard(use.card,dummy_use)
		if dummy_use.card and dummy_use.to:length()>0 then
			self:setStrategyMemory("yjcm2013.qiaoshui_target",(dummy_use.to:first()):objectName())
			return "add"
		end
	end
	return "cancel"
end

sgs.ai_skill_playerchosen.qiaoshui = function(self,targets)
	return remembered_player(self,"qiaoshui_target")
end

local function policy___qiaoshui_(self,prompt) -- extra target for Collateral
	local collateral=known(self:getStrategyMemory("yjcm2013.qiaoshui_collateral"),"qiaoshui.missing_prior_choice")
	return "@ExtraCollateralCard=.->"..collateral[1].."+"..collateral[2]
end

sgs.ai_skill_invoke.zongshih = function(self,data)
	return not self:needKongcheng(self.player,true)
end

sgs.ai_skill_cardask["@duodao-get"] = function(self,data)
	local function getLeastValueCard(from)
		if self:needToThrowArmor() then return "$"..self.player:getArmor():getEffectiveId() end
		local cards = AIList.new(self.player:getHandcards())
		cards = self:sortByKeepValue(cards)
		for _,c in ipairs(cards)do
			if self:getKeepValue(c)<8 and not self.player:isJilei(c) and not self:isValuableCard(c) then return "$"..c:getEffectiveId() end
		end
		local offhorse_avail,weapon_avail
		for _,enemy in ipairs(self.enemies)do
			if self:canAttack(enemy,self.player) then
				if not offhorse_avail and self.player:getOffensiveHorse() and self.player:distanceTo(enemy,1)<=self.player:getAttackRange() then
					offhorse_avail = true
				end
				if not weapon_avail and self.player:getWeapon() and self.player:distanceTo(enemy)==1 then
					weapon_avail = true
				end
			end
			if offhorse_avail and weapon_avail then break end
		end
		if offhorse_avail and not self.player:isJilei(self.player:getOffensiveHorse()) then return "$"..self.player:getOffensiveHorse():getEffectiveId() end
		if weapon_avail and not self.player:isJilei(self.player:getWeapon()) and self:evaluateWeapon(self.player:getWeapon())<self:evaluateWeapon(from:getWeapon()) then
			return "$"..self.player:getWeapon():getEffectiveId()
		end
	end
	local damage = data:toDamage()
	if not damage.from or not damage.from:getWeapon() then
		if self:needToThrowArmor() then
			return "$"..self.player:getArmor():getEffectiveId()
		elseif self.player:getHandcardNum()==1 and (skill(self,self.player,"kongcheng") or (skill(self,self.player,"zhiji") and self.player:getMark("zhiji")==0)) then
			return "$"..self.player:handCards():first()
		end
	else
		if self:isFriend(damage.from) then
			if skill(self,damage.from,"kofxiaoji|xiaoji") and self:isWeak(damage.from) then
				local str = getLeastValueCard(damage.from)
				if str then return str end
			else
				if self:getCardsNum("Slash")==0 or self:willSkipPlayPhase() then return "." end
				local invoke = false
				local range = sgs.weapon_range[damage.from:getWeapon():getClassName()] or 0
				if skill(self,self.player,"anjian|mobileanjian") then
					for _,enemy in ipairs(self.enemies)do
						if not enemy:inMyAttackRange(self.player) and not self.player:inMyAttackRange(enemy) and self.player:distanceTo(enemy)<=range then
							invoke = true
							break
						end
					end
				end
				if not invoke and self:evaluateWeapon(damage.from:getWeapon())>8 then invoke = true end
				if invoke then
					local str = getLeastValueCard(damage.from)
					if str then return str end
				end
			end
		else
			if skill(self,damage.from,"nosxuanfeng") then
				for _,friend in ipairs(self.friends)do
					if self:isWeak(friend) then return "." end
				end
			else
				if self:hasManjuanEffect(self.player) then
					if self:needToThrowArmor() and not self.player:isJilei(self.player:getArmor()) then
						return "$"..self.player:getArmor():getEffectiveId()
					elseif self.player:getHandcardNum()==1
							and (skill(self,self.player,"kongcheng") or (skill(self,self.player,"zhiji") and self.player:getMark("zhiji")==0))
							and not self.player:isJilei(self.player:getHandcards():first()) then
						return "$"..self.player:handCards():first()
					end
				else
					local str = getLeastValueCard(damage.from)
					if str then return str end
				end
			end
		end
	end
	return "."
end

sgs.ai_fill_skill.danshou = function(self,inclusive,request)
	local times = self.player:getMark("danshou")+1
	if times<self.player:getCardCount(true) then
		return self:legacySkillSeed("danshou","DanshouCard",request)
	end
end

sgs.ai_skill_use_func.DanshouCard = function(card,use,self,request)
	local times = self.player:getMark("danshou")+1
	local cards = self.player:getCards("he")
	local jink_num = self:getCardsNum("Jink")
	local to_discard = {}
	for _,id in ipairs(self.player:getPile("wooden_ox"))do
		cards:append(material(self,id))
	end
	cards = AIList.new(cards)
	cards = self:sortByUseValue(cards,true)
	local has_weapon = false
	local DisWeapon = false
	for _,card in ipairs(cards)do
		if card:isKindOf("Weapon") and card:isBlack() then has_weapon = true end
	end
	for _,card in ipairs(cards)do
		if self.player:canDiscard(self.player,card:getEffectiveId()) and ((self:getUseValue(card)<sgs.ai_use_value.Dismantlement+1) or self:getOverflow()>0) then
			local shouldUse = true
			if card:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(card) and not (card:isKindOf("SilverLion") and self.player:isWounded()) then shouldUse = false
				end
			end
			if card:isKindOf("Weapon") and self.player:getHandcardNum()>2 then
				if not self.player:getWeapon() then shouldUse = false
				elseif self.player:hasEquip(card) and not has_weapon then shouldUse = false
				else DisWeapon = true
				end
			end
			if card:isKindOf("Slash") then
				local dummy_use = dummy()
				if self:getCardsNum("Slash")==1 then
					self:useBasicCard(card,dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end
			if self:getUseValue(card)>sgs.ai_use_value.Dismantlement+1 and card:isKindOf("TrickCard") then
				local dummy_use = dummy()
				self:useTrickCard(card,dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if isCard("Peach",card,self.player) then
				if times~=3 then shouldUse = false end
			end
			if isCard("Jink",card,self.player) then
				if jink_num<=1 and times==1 then shouldUse = false
				else jink_num = jink_num-1 end
			end
			if shouldUse then
				table.insert(to_discard,card:getEffectiveId())
				if #to_discard==times then break end
			end
		end
	end

	local range =   self.player:getAttackRange()
	if DisWeapon then range = 1 end
	local target
	for _,p in ipairs(self.room:getAlivePlayers())do
		if self.player:distanceTo(p)<=range then
			if times==1 or times==2 then
				if self.player:canDiscard(p,"he") and not p:isNude() then
					if self:isFriend(p) then
						if(self:hasSkills(sgs.lose_equip_skill,p) and not p:getEquips():isEmpty())
						or (self:needToThrowArmor(p) and p:getArmor()) or self:doDisCard(p,"he") then
							target = p  break end
					elseif self:isEnemy(p) then
						if times==2 and self:needToThrowArmor(p) then continue
						elseif (self:doDisCard(p,"he") or self:getDangerousCard(p) or self:getValuableCard(p)) then
							target = p  break end
					end
				end
			elseif times==3
			then
				if self:isEnemy(p)
				then
					if self:damageIsEffective(p,nil,self.player)
					and not self:needToLoseHp(p,self.player)
					and ((self:isWeak(p) and p:getHp()<3) or self:getOverflow()>3)
					then target = p  break end
				end
			elseif times==4 then
				if self:isFriend(p) and p:isWounded()
				then target = p  break end
			end
		end
	end
	if target and #to_discard==times then
		use.card = source_card(self,"@DanshouCard="..table.concat(to_discard,"+"),request)
		use.to:append(target)
		return
	end
end

sgs.ai_use_priority.DanshouCard = sgs.ai_use_priority.Dismantlement+2
sgs.ai_use_value.DanshouCard = sgs.ai_use_value.Dismantlement+1

sgs.ai_card_intention.DanshouCard = function(self,card,from,tos)
	local num = card:subcardsLength()
	if num==2 or num==3 then
		sgs.updateIntentions(from,tos,10)
	elseif num==4 then
		sgs.updateIntentions(from,tos,-10)
	end
end

sgs.ai_choicemade_filter.cardChosen.danshou = sgs.ai_choicemade_filter.cardChosen.snatch


-- No fixed-source writer for zongxuanForAI: the original QVariant yields an empty list.
ai_skill_use["@@zongxuan"]=function(self,prompt,request)return "." end

sgs.ai_skill_playerchosen.zhiyan = function(self,targets)
	local card = top_card(self)
	if card then -- the projected top descriptor is already authorized visible
		if card:isKindOf("EquipCard") then
			sort_in_place(self,self.friends,"hp")
			for _,friend in ipairs(self.friends)do
				if (not self:getSameEquip(card,friend) or card:isKindOf("DefensiveHorse") or card:isKindOf("OffensiveHorse"))
					and not (card:isKindOf("Armor") and (skill(self,friend,"bazhen|yizhong") or self:evaluateArmor(card,friend)<0)) then
					return friend
				end
			end
			if not (card:isKindOf("Armor") and (skill(self,self.player,"bazhen|yizhong") or self:evaluateArmor(card)<0))
				and not (card:isKindOf("Weapon") and self.player:getWeapon() and self:evaluateWeapon(card)<self:evaluateWeapon(self.player:getWeapon())-1) then
				return self.player
			end
		else
			local card,player = self:getCardNeedPlayer({ card })
			if player then
				return player
			else
				sort_in_place(self,self.friends)
				for _,friend in ipairs(self.friends)do
					if not self:needKongcheng(friend,true) and not self:hasManjuanEffect(friend) then return friend end
				end
			end
		end
	else
		sort_in_place(self,self.friends)
		for _,friend in ipairs(self.friends)do
			if not self:needKongcheng(friend,true) and not self:hasManjuanEffect(friend) then return friend end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.zhiyan = -60

sgs.ai_skill_invoke.zhuikong = function(self,data)
	if self.player:getHandcardNum()<=(self:isWeak() and 2 or 1) then return false end
	local current = self.room:getCurrent()
	if not current or self:isFriend(current) then return false end

	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	if skill(self,self.player,"yingyang") then max_point = math.min(max_point+3,13) end
	if not (skill(self,current,"zhiji") and current:getMark("zhiji")==0 and current:getHandcardNum()==1) then
		local enemy_max_card = self:getMaxCard(current)
		local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
		if enemy_max_card and skill(self,current,"yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
		if max_point>enemy_max_point or max_point>10 then
			self:remember("zhuikong_card",max_card:getEffectiveId())
			return true
		end
	end
	if current:distanceTo(self.player)==1 and not self:isValuableCard(max_card) then
		self:remember("zhuikong_card",max_card:getEffectiveId())
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.qiuyuan = function(self,targets)
	local targetlist = AIList.new(targets)
	sort_in_place(self,targetlist,"handcard")
	local enemy
	for _,p in ipairs(targetlist)do
		local jink = getKnownCard(p,self.player,"Jink",true,"he")
		if self:isEnemy(p) and (jink==0 or (self:isWeak(p) and jink<2)) then
			enemy = p
			break
		end
	end
	if enemy then return enemy end
	targetlist = reversed(targetlist)
	local friend
	for _,p in ipairs(targetlist)do
		local jink = getKnownCard(p,self.player,"Jink",true,"he")
		if self:isFriend(p) then
			if (self:needKongcheng(p) and p:getHandcardNum()==1 and jink==1)
				or (p:getCardCount()>=2 and self:canLiuli(p,self.enemies))
				or self:needLeiji(p) or p:getHandcardNum()>3 or jink>=1 then
				friend = p
				break
			end
		end
	end
	if friend then return friend end
return nil
end

sgs.ai_skill_cardask["@qiuyuan-give"] = function(self,data,pattern,target)
	local give = true
	local huanghou = self.room:findPlayerBySkillName("qiuyuan")
	if self:isEnemy(huanghou) then
		if not (self:needKongcheng() and self.player:getHandcardNum()==1) then
			give = false
		end
	elseif self:isFriend(huanghou) then
		if not self:isWeak(huanghou) and self:hasSkills("leiji|nosleiji") then
			give = false
		end
	end
	if give==true then
		local cards = AIList.new(self.player:getHandcards())
		cards = self:sortByKeepValue(cards)
		for _,card in ipairs(cards)do
			if card:isKindOf("Jink") then
				return "$"..card:getEffectiveId()
			end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.juece = function(self,targetlist)
	local targets = AIList.new(targetlist)
	sort_in_place(self,targets)
	local friends,enemies = {},{}
	for _,target in ipairs(targets)do
		if self:cantbeHurt(target,self.player) or not self:damageIsEffective(target,nil,self.player) then continue end
		if self:isEnemy(target) then table.insert(enemies,target)
		elseif self:isFriend(target) then table.insert(friends,target) end
	end
	for _,enemy in ipairs(enemies)do
		if not self:needToLoseHp(enemy,self.player) then return enemy end
	end
	for _,friend in ipairs(friends)do
		if self:needToLoseHp(friend,self.player) then return friend end
	end
return nil
end

sgs.ai_playerchosen_intention.juece = function(self,from,to)
	if self:damageIsEffective(to,nil,from) and not self:needToLoseHp(nil,self.player) then
		sgs.updateIntention(from,to,10)
	end
end

sgs.ai_fill_skill.fencheng = function(self,inclusive,request)
	return self:legacySkillSeed("fencheng","FenchengCard",request)
end

sgs.ai_skill_use_func.FenchengCard = function(card,use,self,request)
	local value = 0
	local neutral = 0
	local damage = { from = self.player,damage = 2,nature = sgs.DamageStruct_Fire }
	local lastPlayer = self.player
	for i,p in ipairs(self.room:getOtherPlayers(self.player))do
		damage.to = p
		if self:damageStruct(damage) then
			if self:getRoleEstimate(p)=="neutral" then neutral = neutral+1 end
			local v = 4
			if self:needToLoseHp(p,self.player) and getCardsNum("Peach",p,self.player)+p:getHp()>2 then
				v = v-6
			elseif lastPlayer:objectName()~=self.player:objectName() and lastPlayer:getCardCount(true)<p:getCardCount(true) then
				v = v-4
			elseif lastPlayer:objectName()==self.player:objectName() and not p:isNude() then
				v = v-4
			end
			if self:isFriend(p) then
				value = value-v-p:getHp()+2
			elseif self:isEnemy(p) then
				value = value+v+p:getLostHp()-1
			end
			if p:isLord() and p:getHp()<=2
				and (self:isEnemy(p,lastPlayer) and p:getCardCount(true)<=lastPlayer:getCardCount(true)
					or lastPlayer:objectName()==self.player:objectName() and (not p:canDiscard(p,"he") or p:isNude())) then
				if not self:isEnemy(p) then
					if self:getCardsNum("Peach")+getCardsNum("Peach",p,self.player)+p:getHp()<=2 then return end
				else
					use.card = self:inheritLegacyCardIdentity(policy_card(self,"fencheng","FenchengCard",{},request),card)
					return
				end
			end
		end
	end

	if neutral>self.player:aliveCount()/2 then return end
	if value>0 then
		use.card = self:inheritLegacyCardIdentity(policy_card(self,"fencheng","FenchengCard",{},request),card)
	end
end

sgs.ai_use_priority.FenchengCard = 9.1

sgs.ai_skill_discard.fencheng = function(self,discard_num,min_num,optional,include_equip)
	local cards = AIList.new(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local current = self.room:getCurrent()
	local damage = { from = current,damage = 2,nature = sgs.DamageStruct_Fire }
	local to_discard = {}
	local length = min_num
	local peaches = 0

	local nextPlayer = self.player:getNextAlive()
	if self:isEnemy(nextPlayer) and self.player:getCardCount(true)>nextPlayer:getCardCount(true) and self.player:getCardCount(true)>length then
		length = tonumber(nextPlayer:getCardCount(true))
	end

	for _,c in ipairs(cards)do
		if self.player:canDiscard(self.player,c:getEffectiveId()) then
			table.insert(to_discard,c:getEffectiveId())
			if isCard("Peach",c,self.player) then peaches = peaches+1 end
			if #to_discard==length then break end
		end
	end

	if peaches>2 then
		return {}
	elseif peaches==2 and self.player:getHp()>1 and length==min_num then
		for _,friend in ipairs(self.friends_noself)do
			damage.to = friend
			if friend:getHp()<=2 and self:damageStruct(damage) then return {} end
		end
	end

	if nextPlayer:isLord() and self.role~="rebel" and nextPlayer:getHandcardNum()<min_num
	and not self:needToLoseHp(nextPlayer,current) 
	then
		if nextPlayer:getHp()+getCardsNum("Peach",nextPlayer,self.player)+self:getCardsNum("Peach")<=2 then return {} end
		if self.player:getHp()>nextPlayer:getHp() and self.player:getHp()>2 then return {} end
	end
	return to_discard
end

sgs.ai_fill_skill.mieji = function(self,inclusive,request)
	if self.player:isKongcheng() then return end
	return self:legacySkillSeed("mieji","MiejiCard",request)
end

sgs.ai_skill_use_func.MiejiCard = function(card,use,self,request)
	local nextAlive = self.player:getNextAlive()
	local hasLightning,hasIndulgence,hasSupplyShortage
	local tricks = nextAlive:getJudgingArea()
	if not tricks:isEmpty() and not nextAlive:containsTrick("YanxiaoCard") and not skill(self,nextAlive,"qianxi") then
		local trick = tricks:at(tricks:length()-1)
		if self:hasTrickEffective(trick,nextAlive) then
			if trick:isKindOf("Lightning") then hasLightning = true
			elseif trick:isKindOf("Indulgence") then hasIndulgence = true
			elseif trick:isKindOf("SupplyShortage") then hasSupplyShortage = true
			end
		end
	end

	local putcard
	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	cards = self:sortByUseValue(cards,true)
	for _,card in ipairs(cards)do
		if card:isBlack() and card:isKindOf("TrickCard") then
			if hasLightning and card:getSuit()==sgs.Card_Spade and card:getNumber()>=2 and card:getNumber()<=9 then
				if self:isEnemy(nextAlive) then
					putcard = card break
				else continue
				end
			end
			if hasSupplyShortage and card:getSuit()==sgs.Card_Club then
				if self:isFriend(nextAlive) then
					putcard = card break
				else continue
				end
			end
			if not putcard then
				putcard = card break
			end
		end
	end

	local target
	for _,enemy in ipairs(self.enemies)do
		if self:needKongcheng(enemy) and enemy:getHandcardNum()<=2 then continue end
		if not enemy:isNude()  then
			target = enemy break
		end
	end
	if not target then
		for _,friend in ipairs(self.friends_noself)do
			if self:needKongcheng(friend) and friend:getHandcardNum()<2 and not friend:isKongcheng() then
				target = friend break
			end
		end
	end

	if putcard and target then
		use.card = source_card(self,"@MiejiCard="..putcard:getEffectiveId(),request)
		use.to:append(target)
		return
	end

end

sgs.ai_use_priority.MiejiCard = sgs.ai_use_priority.Dismantlement+1

sgs.ai_card_intention.MiejiCard = function(self,card,from,tos)
	for _,to in ipairs(tos)do
		if self:needKongcheng(to) and to:getHandcardNum()<=2 then continue end
		sgs.updateIntention(from,to,10)
	end
end

sgs.ai_skill_cardask["@@miejidiscard!"] = function(self,prompt)
	local cards = self.player:getCards("he")
	cards = AIList.new(cards)
	cards = self:sortByKeepValue(cards)
	local trick = {}
	local nontrick = {}
	local discard = {}
	for _,card in ipairs(cards)do
		if card:isKindOf("TrickCard") then
			table.insert(trick,card)
		else
			table.insert(nontrick,card)
		end
	end
	if #cards<=2 then return "." end
	if self:needToThrowArmor() and #nontrick>=2 then
		table.insert(discard,self.player:getArmor())
		if nontrick[1]~=discard[1] then
			table.insert(discard,nontrick[1])
		else
			table.insert(discard,nontrick[2])
		end
	end
	if #trick==0 then
		for _,card in ipairs(nontrick)do
			table.insert(discard,card)
			if #discard==2 or #discard==#nontrick then
				break
			end
		end
	end
	if #nontrick==0 and #trick>=1 then
		table.insert(discard,trick[1])
	end
	if #discard>0 then
		ai_unsupported("fixed donor calls getEffectiveId on a Lua table","miejidiscard.donor_table_method")
	end
return "."
end

sgs.ai_skill_invoke.oljingce = function(self,data)
	return self:canDraw()
end

ai_skill_use["@@xiansi"]=function(self,prompt,request)return source_action(self,policy___xiansi(self,prompt),request)end

ai_skill_use["@@qiaoshui"]=function(self,prompt,request)return source_action(self,policy___qiaoshui(self,prompt),request)end

ai_skill_use["@@qiaoshui!"]=function(self,prompt,request)return source_action(self,policy___qiaoshui_(self,prompt),request)end

for class,name in pairs(classes)do if sgs.ai_card_intention[class]~=nil then sgs.ai_card_intention[name]=sgs.ai_card_intention[class]end end
