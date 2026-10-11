-- Fixed YJCM source policies. Native receipts alone authorize card costs.
sgs.ai_choicemade_filter.skillInvoke=sgs.ai_choicemade_filter.skillInvoke or {}
sgs.ai_choicemade_filter.cardChosen=sgs.ai_choicemade_filter.cardChosen or {}
local function known(value,key)
    if value==nil then ai_unsupported("YJCM input is not projected",key) end
    return value
end
local function skill(self,player,names)
    local value=player:hasSkills(names)
    local row=rawget(player,"_view")
    if value==true or value~=nil and (not row or row.skills_complete==true) then return value end
    if player:objectName()==self.player:objectName() then ai_unsupported("owner skills are incomplete","yjcm.skills") end
    return self:useKnowledgeEstimate({status="estimate",value=false,basis="yjcm.undisclosed_skills_use_visible_roster",target=player:objectName()},"yjcm.skills")
end
local function flag(self,player,name)
    -- Fixed engine/extensions have no writer for this obsolete AI-only flag.
    if name=="EnyuanDrawTarget" then return false end
    if name=="DimengTarget" or name=="MingceTarget" then
        local key=name=="DimengTarget" and "dimeng_targets" or "mingce_targets"
        for _,target in ipairs(known(self:getDecisionContext()[key],"yjcm."..key)) do
            if target==player:objectName() then return true end
        end
        return false
    end
    local value=player:getStrategyFlag(name)
    if value~=nil then return value end
    return self:useKnowledgeEstimate({status="estimate",value=false,basis="yjcm.unknown_foreign_flag_uses_public_state",target=player:objectName(),flag=name},"yjcm.flag")
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
    local raw=known(self.world.strategy_facts and self.world.strategy_facts.standard and self.world.strategy_facts.standard.current_damage,"yjcm.current_damage")
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
    return known(self:getKnownCardById(id) or self:getChoiceCard(id),"yjcm.disclosed_material")
end
local function own_pile(self,name)
    local result={};for _,id in ipairs(known(self.player:getPile(name),"yjcm.owner_pile"))do result[#result+1]=material(self,id)end
    return AIList.new(result)
end
local function policy_card(self,skill_name,class,costs,request)
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room)end
    local authority=self:bindSkillCard(skill_name,costs,request)
    local suit,number=sgs.Card_NoSuit,0
    if #costs==1 then local c=material(self,costs[1]);suit,number=c:getSuit(),c:getNumber()
    elseif #costs>1 then
        local red,black=true,true
        for _,id in ipairs(costs)do local c=material(self,id);red=red and known(c:isRed(),"yjcm.material_color");black=black and known(c:isBlack(),"yjcm.material_color")end
        suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
    end
    local suits={[sgs.Card_Spade]="spade",[sgs.Card_Club]="club",[sgs.Card_Heart]="heart",[sgs.Card_Diamond]="diamond",[sgs.Card_NoSuitBlack]="no_suit_black",[sgs.Card_NoSuitRed]="no_suit_red",[sgs.Card_NoSuit]="no_suit"}
    local rank=number>13 and "JOKER" or ({[1]="A",[11]="J",[12]="Q",[13]="K"})[number] or tostring(number)
    local key="@"..class.."["..known(suits[suit],"yjcm.policy_suit")..":"..rank.."]="..(#costs>0 and table.concat(costs,"+")or".")
    local keeps=class=="MingceCard" or class=="PaiyiCard" or class=="NosYexinCard" or class=="NosPaiyiCard"
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
    return known(use:toAnswer(),"yjcm.action")
end
sgs.ai_cardsview.jiushi=function(self,class_name,player)
    return {name="analeptic",skill="jiushi",suit=sgs.Card_NoSuit,number=0,subcards={}}
end
function sgs.ai_skill_invoke.jiushi(self,data)
	return not self.player:faceUp()
end

sgs.ai_skill_invoke.luoying = function(self)
	if flag(self,self.player,"DimengTarget") then
		local another
		for _,player in ipairs(self.room:getOtherPlayers(self.player))do
			if flag(self,player,"DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return not self:needKongcheng(self.player,true)
end

sgs.ai_skill_askforag.luoying = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		if #self:poisonCards({material(self,id)})<1 then
			return id
		end
	end
	return -1
end

sgs.ai_skill_invoke.olluoying = function(self,data)
	local move = data:toMoveOneTime()
	local cards={};for _,id in ipairs(known(move.card_ids,"olluoying.move_cards"))do cards[#cards+1]=material(self,id)end
	if #self:poisonCards(cards)>move.card_ids:length()/2 then
		return false
	end
	return not self:needKongcheng(self.player,true)
end



sgs.ai_skill_choice.jujian = function(self,choices)
	if not self.player:faceUp() then return "reset" end
	if self.player:hasArmorEffect("Vine") and self.player:isChained() and not self:isGoodChainPartner() then
		return "reset"
	end
	if self:isWeak() and self.player:isWounded() then return "recover" end
	if skill(self,self.player,"manjuan") then
		if self.player:isWounded() then return "recover" end
		if self.player:isChained() then return "reset" end
	end
	return "draw"
end

sgs.ai_card_intention.JujianCard = -100
sgs.ai_use_priority.JujianCard = 4.5

sgs.jujian_keep_value = {
	Peach = 6,
	Jink = 5,
	EquipCard = 5,
	Duel = 5,
	FireAttack = 5,
	ArcheryAttack = 5,
	SavageAssault = 5
}

function sgs.ai_armor_value.yizhong(p,s,card)
	if not card then return 4 end
end



function sgs.ai_slash_prohibit.huilei(self,from,to)
	if skill(self,from,"jueqing") or (skill(self,from,"nosqianxi") and from:distanceTo(to)==1) then return false end
	if flag(self,from,"NosJiefanUsed") then return false end
	if self:isFriend(to,from) and self:isWeak(to) then return true end
	return #(self:getEnemies(from))>1 and self:isWeak(to) and from:getHandcardNum()>3
end





sgs.ai_skill_invoke.enyuan = function(self,data)
	local move = data:toMoveOneTime()
	if move and move.from and known(move.card_count or move.card_ids and #move.card_ids,"enyuan.move_count")>0 then
		local from = self.room:findPlayerByObjectName(move.from:objectName())
		if from then return self:isFriend(from) and not self:needKongcheng(from,true) end
	end
	local damage = data:toDamage()
	if damage.from and damage.from:isAlive() then
		if self:isFriend(damage.from) then
			if self:getOverflow(damage.from)>2 then return true end
			if self:needToLoseHp(damage.from,self.player,damage.card,true) and not self:hasSkills(sgs.masochism_skill,damage.from) then return true end
			if not self:hasLoseHandcardEffective(damage.from) and not damage.from:isKongcheng() then return true end
			return false
		else
			return true
		end
	end
	return
end

sgs.ai_choicemade_filter.skillInvoke.enyuan = function(self,player,promptlist)
	local invoked = (promptlist[3]=="yes")
	local intention = 0

	local EnyuanDrawTarget
	for _,p in ipairs(self.room:getOtherPlayers(player))do
		if flag(self,p,"EnyuanDrawTarget") then EnyuanDrawTarget = p break end
	end

	if EnyuanDrawTarget then
		if not invoked and not self:needKongcheng(EnyuanDrawTarget,true) then
			intention = 10
		elseif not self:needKongcheng(from,true) then
			intention = -10
		end
		sgs.updateIntention(player,EnyuanDrawTarget,intention)
	else
		local damage = current_damage(self)
		if damage.from then
			if not invoked then
				intention = -10
			elseif self:needToLoseHp(damage.from,player,damage.card,true) then
				intention = 0
			elseif not self:hasLoseHandcardEffective(damage.from) and not damage.from:isKongcheng() then
				intention = 0
			elseif self:getOverflow(damage.from)<=2 then
				intention = 10
			end
			sgs.updateIntention(player,damage.from,intention)
		end
	end

end

sgs.ai_skill_discard.enyuan = function(self,discard_num,min_num,optional,include_equip)
	if self:hasZhaxiangEffect(self.player) and (self.player:getHp()>1 or hasBuquEffect(self.player) or self:getSaveNum(true)>=1) then return {} end

	local damage = self:getDecisionContext().damage
	if not damage then return {} end
	local fazheng = damage.to
    if not fazheng then return {} end
    local to_discard = {}
	local cards = self.player:getHandcards()
	cards = AIList.new(cards)
	if self:needToLoseHp(self.player,fazheng,damage.card,true) and not self:hasSkills(sgs.masochism_skill) then return {} end
	if self:isFriend(fazheng) then
		for _,card in ipairs(cards)do
			if isCard("Peach",card,fazheng) and ((not self:isWeak() and self:getCardsNum("Peach")>0) or self:getCardsNum("Peach")>1) then
				table.insert(to_discard,card:getEffectiveId())
				return to_discard
			end
			if isCard("Analeptic",card,fazheng) and self:getCardsNum("Analeptic")>1 then
				table.insert(to_discard,card:getEffectiveId())
				return to_discard
			end
			if isCard("Jink",card,fazheng) and self:getCardsNum("Jink")>1 then
				table.insert(to_discard,card:getEffectiveId())
				return to_discard
			end
		end
	end

	if self:needToLoseHp() and not self:hasSkills(sgs.masochism_skill) then return {} end
	cards = self:sortByKeepValue(cards)
	for _,card in ipairs(cards)do
		if not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) then
			table.insert(to_discard,card:getEffectiveId())
			return to_discard
		end
	end

	return {}
end

function sgs.ai_slash_prohibit.enyuan(self,from,to)
	if self:isFriend(to,from) then return false end
	if skill(self,from,"jueqing") then return false end
	if skill(self,from,"nosqianxi") and from:distanceTo(to)==1 then return false end
	if flag(self,from,"nosjiefanUsed") then return false end
	if self:needToLoseHp(from) and not self:hasSkills(sgs.masochism_skill,from) then return false end
	local num = from:getHandcardNum()
	if num>=3 or skill(self,from,"lianying|noslianying|shangshi|nosshangshi") or (self:needKongcheng(from,true) and num==2) then return false end
	local role = from:objectName()==self.player:objectName() and from:getRole() or self:getRoleEstimate(from)
	if (role=="loyalist" or role=="lord") and known(self:getRoleCounts().rebel,"yjcm.roles")+known(self:getRoleCounts().renegade,"yjcm.roles")==1
		and to:getHp()==1 and getCardsNum("Peach",to,from)<1 and getCardsNum("Analeptic",to,from)<1
		and (from:getHp()>1 or getCardsNum("Peach",from,from)>=1 and getCardsNum("Analeptic",from,from)>=1) then
		return false
	end
	if role=="rebel" and isLord(to) and self:getAllPeachNum(player)<1 and to:getHp()==1
		and (from:getHp()>1 or getCardsNum("Peach",from,from)>=1 and getCardsNum("Analeptic",from,from)>=1) then
		return false
	end
	if role=="renegade" and from:aliveCount()==2 and to:getHp()==1 and getCardsNum("Peach",to,from)<1 and getCardsNum("Analeptic",to,from)<1
		and (from:getHp()>1 or getCardsNum("Peach",from,from)>=1 and getCardsNum("Analeptic",from,from)>=1) then
		return false
	end
	return #self.enemies>1
end

sgs.ai_need_damaged.enyuan = function (self,attacker,player)
	if not skill(self,player,"enyuan") then return false end
	if not attacker then return end
	if self:isEnemy(attacker,player) and self:isWeak(attacker) and attacker:getHandcardNum()<3
	  and not self:hasSkills("lianying|noslianying|shangshi|nosshangshi",attacker)
	  and not (skill(self,attacker,"kongcheng") and attacker:getHandcardNum()>0)
	  and not skill(self,attacker,sgs.masochism_skill) then
		return not self:isWeak(player)
	end
end

function sgs.ai_cardneed.enyuan(to,card,self)
	return getKnownCard(to,self.player,"Card",false)<2
end



sgs.ai_skill_playerchosen.xuanhuo = function(self,targets)
	local lord = self.room:getLord()
	sort_in_place(self,self.enemies,"defense")
	if lord and self:isEnemy(lord) then  --killloyal
		for _,enemy in ipairs(self.enemies)do
			if (self:getDangerousCard(lord) or self:getValuableCard(lord))
				and not self:hasSkills(sgs.lose_equip_skill,enemy) and not self:hasTuntianEffect(enemy, true)
				and lord:canSlash(enemy) and (enemy:getHp()<2 and not hasBuquEffect(enemy))
				and self:getDefense(enemy)<2 then

				return lord
			end
		end
	end

	for _,enemy in ipairs(self.enemies)do --robequip
		for _,enemy2 in ipairs(self.enemies)do
			if enemy:canSlash(enemy2) and (self:getDangerousCard(enemy) or self:getValuableCard(enemy))
			and not self:hasSkills(sgs.lose_equip_skill,enemy) and not self:hasTuntianEffect(enemy, true)
			and not self:needLeiji(enemy2,enemy) and not self:needToLoseHp(enemy2,enemy,nil,true)
			or (skill(self,enemy,"manjuan") and enemy:getCards("he"):length()>1 and getCardsNum("Slash",enemy)==0)
			then return enemy end
		end
	end

	if #self.friends_noself==0 then return nil end
	sort_in_place(self,self.friends_noself,"defense")

	for _,friend in ipairs(self.friends_noself)do
		if self:hasSkills(sgs.lose_equip_skill,friend) and not friend:getEquips():isEmpty() and not skill(self,friend,"manjuan") then
			return friend
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if self:hasTuntianEffect(friend, true) and not skill(self,friend,"manjuan") then
			return friend
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		for _,enemy in ipairs(self.enemies)do
			if friend:canSlash(enemy) and (enemy:getHp()<2 and not hasBuquEffect(enemy))
				and self:getDefense(enemy)<2 and not skill(self,friend,"manjuan") then
				return friend
			end
		end
	end
	if not skill(self,self.player,"enyuan") then return nil end
	for _,friend in ipairs(self.friends_noself)do
		if not skill(self,friend,"manjuan") then
			return friend
		end
	end
	return nil
end

sgs.ai_skill_playerchosen.xuanhuo_slash = sgs.ai_skill_playerchosen.zero_card_as_slash
sgs.ai_playerchosen_intention.xuanhuo_slash = 80

sgs.ai_skill_cardask["xuanhuo-slash"] = function(self,data,pattern,t1,t2,prompt)
	if type(prompt)~="string"then ai_unsupported("fixed donor receives no sixth prompt component","xuanhuo-slash.donor_prompt")end
	local parsedPrompt = prompt:split(":")
	local fazheng,victim
	for _,p in ipairs(self.room:getAlivePlayers())do
		if p:objectName()==parsedPrompt[2] then fazheng = p end
		if p:objectName()==parsedPrompt[3] then victim = p end
	end
	if not fazheng or not victim then return "." end
	if fazheng and victim then
		for _,slash in ipairs(self:getCards("Slash"))do
			if self:isFriend(victim) and self:slashIsEffective(slash,victim) then
				if self:needLeiji(victim,self.player) then return slash end
				if self:needToLoseHp(victim,self.player) then return slash end
				if not self:isFriend(fazheng) and self:needToLoseHp(victim,self.player) then return slash end
			end

			if self:isFriend(victim) and not self:isFriend(fazheng) and not self:slashIsEffective(slash,victim) then
				return slash
			end

			if self:isEnemy(victim) and self:slashIsEffective(slash,victim)
			and not self:needToLoseHp(victim,self.player,slash) and not self:needLeiji(victim,self.player)
			then return slash end
		end

		if self:hasSkills(sgs.lose_equip_skill) and not self.player:getEquips():isEmpty() and not skill(self,self.player,"manjuan") then return "." end

		for _,slash in ipairs(self:getCards("Slash"))do
			if self:isFriend(victim) and not self:isFriend(fazheng) then
				if (victim:getHp()>3 or not self:canHit(victim,self.player,self:ajustDamage(self.player,victim,1,slash)>1))
				and not victim:isLord()
				then
					return slash
				end
				if self:needToLoseHp(victim,self.player,slash) then return slash end
			end

			if not self:isFriend(victim) and not self:isFriend(fazheng) then
				if not self:needLeiji(victim,self.player) then return slash end
				if not self:slashIsEffective(slash,victim) then return slash end
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.xuanfeng = function(self,data)
	for _,enemy in ipairs(self.enemies)do
		if (self:doDisCard(enemy,"he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() and
		not (skill(self,enemy,"guzheng") and self.room:getCurrent():getPhase()==sgs.Player_Discard) then
			return true
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if(self:hasSkills(sgs.lose_equip_skill,friend) and not friend:getEquips():isEmpty())
		or (self:needToThrowArmor(friend) and friend:getArmor()) or self:doDisCard(friend,"he") then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.xuanfeng = function(self,targets)
	targets = AIList.new(targets)
	sort_in_place(self,targets,"defense")
	for _,enemy in ipairs(self.enemies)do
		if (self:doDisCard(enemy,"he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() and
		not (skill(self,enemy,"guzheng") and self.room:getCurrent():getPhase()==sgs.Player_Discard) then
			return enemy
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if(self:hasSkills(sgs.lose_equip_skill,friend) and not friend:getEquips():isEmpty())
		or (self:needToThrowArmor(friend) and friend:getArmor()) or self:doDisCard(friend,"he") then
			return friend
		end
	end
end



sgs.xuanfeng_keep_value = sgs.xiaoji_keep_value

sgs.ai_cardneed.xuanfeng = sgs.ai_cardneed.equip

sgs.ai_skill_invoke.pojun = function(self,data)
	local damage = data:toDamage()

	if not damage.to:faceUp() then
		return self:isFriend(damage.to)
	end

	local good = damage.to:getHp()>2
	if self:isFriend(damage.to) then
		return good
	elseif self:isEnemy(damage.to) then
		return not good
	end
end

sgs.ai_choicemade_filter.skillInvoke.pojun = function(self,player,promptlist)
	local intention = 60
	local index = promptlist[#promptlist]=="yes" and 1 or -1
	local damage = current_damage(self)
	if damage.from and damage.to then
		if not damage.to:faceUp() then
			intention = index*intention
		elseif damage.to:getHp()>2 then
			intention = -index/2*intention
		elseif index==-1 then
			intention = -20
		end
		sgs.updateIntention(damage.from,damage.to,intention)
	end
end



sgs.ai_skill_invoke.shangshi = function(self,data)
	if self.player:getLostHp()==1 then return sgs.ai_skill_invoke.noslianying(self,data) end
	return true
end

sgs.ai_skill_invoke.quanji = function(self,data)
	local current = self.room:getCurrent()
	local juece_effect = (current and current:isAlive() and current:getPhase()~=sgs.Player_NotActive and self:isEnemy(current) and skill(self,current,"juece"))
	local manjuan_effect = self:hasManjuanEffect(self.player)
	if self.player:isKongcheng() then
		if manjuan_effect or juece_effect then return false end
	elseif self.player:getHandcardNum()==1 then
		if manjuan_effect and juece_effect then return false end
	end
	return true
end

sgs.ai_skill_discard.quanji = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = AIList.new(cards)
	cards = self:sortByKeepValue(cards)

	table.insert(to_discard,cards[1]:getEffectiveId())

	return to_discard
end

sgs.ai_can_damagehp.quanji = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
	and self:canLoseHp(from,card,to)
end

sgs.ai_skill_choice.zili = function(self,choice)
	if self.player:getHp()<self.player:getMaxHp()-1 then return "recover" end
	return "draw"
end



sgs.ai_skill_invoke.noszhenggong = function(self,data)
	local from = data:toPlayer()
	return self:doDisCard(from,"e",true)
end

sgs.ai_skill_invoke.nosquanji = function(self,data)
	local to = data:toPlayer()
	return self:doDisCard(to,"j",true)
	or self:isEnemy(to) and to:getHandcardNum()<self.player:getHandcardNum()
end

sgs.ai_skill_invoke.nosyexin = function(self,data)
	return #self.enemies>0
end


sgs.ai_fill_skill.xinzhan=function(self,inclusive,request)
 if self.player:getHandcardNum()>self.player:getMaxHp() then return self:legacySkillSeed("xinzhan","XinzhanCard",request)end
end
sgs.ai_skill_use_func.XinzhanCard=function(card,use,self,request)use.card=policy_card(self,"xinzhan","XinzhanCard",{},request)end
sgs.ai_use_value.XinzhanCard=4.4
sgs.ai_use_priority.XinzhanCard=9.4
sgs.ai_fill_skill.ganlu=function(self,inclusive,request)return self:legacySkillSeed("ganlu","GanluCard",request)end
sgs.ai_fill_skill.xianzhen=function(self,inclusive,request)return self:legacySkillSeed("xianzhen","XianzhenCard",request)end
sgs.ai_skill_use_func.GanluCard = function(card,use,self,request)
	local target,min_friend,max_enemy

	local compare_func = function(a,b)
		return a:getEquips():length()>b:getEquips():length()
	end
	table.sort(self.enemies,compare_func)
	table.sort(self.friends,compare_func)

	self.friends = reversed(self.friends)

	for _,friend in ipairs(self.friends)do
		for _,enemy in ipairs(self.enemies)do
			if not self:hasSkills(sgs.lose_equip_skill,enemy) and not self:hasTuntianEffect(enemy,true) then
				local ee = enemy:getEquips():length()
				local fe = friend:getEquips():length()
				local value = self:evaluateArmor(enemy:getArmor(),friend)-self:evaluateArmor(friend:getArmor(),enemy)
					- self:evaluateArmor(friend:getArmor(),friend)+self:evaluateArmor(enemy:getArmor(),enemy)
				if math.abs(ee-fe)<=self.player:getLostHp() and ee>0 and (ee>fe or ee==fe and value>0) then
					if self:hasSkills(sgs.lose_equip_skill,friend) then
						use.card = policy_card(self,"ganlu","GanluCard",{},request)
						use.to:append(friend)
						use.to:append(enemy)
						return
					elseif not min_friend and not max_enemy then
						min_friend = friend
						max_enemy = enemy
						break
					end
				end
			end
		end
	end
	if min_friend and max_enemy then
		use.card = policy_card(self,"ganlu","GanluCard",{},request)
		use.to:append(min_friend)
		use.to:append(max_enemy)
		return
	end

	for _,friend in ipairs(self.friends)do
		if self:needToThrowArmor(friend)
		or (friend:hasEquip() and (self:hasSkills(sgs.lose_equip_skill,friend) or self:hasTuntianEffect(friend,true)))
		then target = friend break end
	end
	if not target then return end
	for _,friend in ipairs(self.friends)do
		if friend:objectName()~=target:objectName()
		and math.abs(friend:getEquips():length()-target:getEquips():length())<=self.player:getLostHp() then
			use.card = policy_card(self,"ganlu","GanluCard",{},request)
			use.to:append(friend)
			use.to:append(target)
			return
		end
	end
end

sgs.ai_use_priority.GanluCard = (sgs.ai_use_priority.Dismantlement or 4.4)+0.1
sgs.dynamic_value.control_card.GanluCard = true

sgs.ai_card_intention.GanluCard = function(self,card,from,to)
	local compare_func = function(a,b)
		return a:getEquips():length()<b:getEquips():length()
	end
	table.sort(to,compare_func)
	for i = 1,2,1 do
		if to[i]:hasArmorEffect("SilverLion") then
			sgs.updateIntention(from,to[i],-20)
			break
		end
	end
	if to[1]:getEquips():length()<to[2]:getEquips():length() then
		sgs.updateIntention(from,to[1],-80)
	end
end

sgs.ai_fill_skill.mingce=function(self,inclusive,request)
	local card
	if self:needToThrowArmor() then
		card = self.player:getArmor()
	end
	if not card then
		local hcards = self.player:getCards("h")
		hcards = AIList.new(hcards)
		hcards = self:sortByUseValue(hcards,true)

		for _,hcard in ipairs(hcards)do
			if hcard:isKindOf("Slash") then
				if self:getCardsNum("Slash")>1
				then
					card = hcard
					break
				else
					local dummy_use = {isDummy=true,to=AIList.new({})}
					self:useBasicCard(hcard,dummy_use)
					if dummy_use and dummy_use.to and (dummy_use.to:length()==0
					or dummy_use.to:length()==1 and self:ajustDamage(self.player,dummy_use.to:first(),1,hcard)<2)
					then
						card = hcard
						break
					end
				end
			elseif hcard:isKindOf("EquipCard")
			then
				card = hcard
				break
			end
		end
	end
	if not card then
		local ecards = self.player:getCards("e")
		ecards = AIList.new(ecards)

		for _,ecard in ipairs(ecards)do
			if ecard:isKindOf("Weapon") or ecard:isKindOf("OffensiveHorse") then
				card = ecard
				break
			end
		end
	end
	if card then
		return policy_card(self,"mingce","MingceCard",{card:getEffectiveId()},request)
	end
end

sgs.ai_skill_use_func.MingceCard = function(card,use,self)
	local target
	local friends = self.friends_noself
	local slash = self:classProbe("Slash")
	self.MingceTarget = nil;self:setStrategyMemory("yjcm.mingce_target",nil)

	local canMingceTo = function(player)
		local canGive = not self:needKongcheng(player,true)
		return canGive or (not canGive and self:getEnemyNumBySeat(self.player,player)==0)
	end

	sort_in_place(self,self.enemies,"defense")
	for _,friend in ipairs(friends)do
		if canMingceTo(friend) then
			for _,enemy in ipairs(self.enemies)do
				if friend:canSlash(enemy) and not self:slashProhibit(slash,enemy) and self:getDefenseSlash(enemy)<=2
				and self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash)
				and enemy:objectName()~=self.player:objectName() then
					target = friend
					self.MingceTarget = enemy;self:setStrategyMemory("yjcm.mingce_target",enemy:objectName())
					break
				end
			end
		end
		if target then break end
	end

	if not target then
		sort_in_place(self,friends,"defense")
		for _,friend in ipairs(friends)do
			if canMingceTo(friend) then
				target = friend
				break
			end
		end
	end

	if target then
		use.card = card
		use.to:append(target)
	end
end

sgs.ai_skill_choice.mingce = function(self,choices)
	local chengong = self.room:getCurrent()
	if not self:isFriend(chengong) then return "draw" end
	for _,player in ipairs(self.room:getAlivePlayers())do
		if flag(self,player,"MingceTarget") and not self:isFriend(player) then
			local slash = self:classProbe("Slash")
			if not self:slashProhibit(slash,player) then return "use" end
		end
	end
	return "draw"
end

sgs.ai_skill_playerchosen.mingce = function(self,targets)
	local name=self:getStrategyMemory("yjcm.mingce_target")
	if name then return self.room:findPlayerByObjectName(name,true)end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self,targets)
end

-- sgs.ai_playerchosen_intention.mingce = 80

sgs.ai_use_value.MingceCard = 5.9
sgs.ai_use_priority.MingceCard = 4

sgs.ai_card_intention.MingceCard = -70

sgs.ai_cardneed.mingce = sgs.ai_cardneed.equip

sgs.ai_skill_use_func.XianzhenCard = function(card,use,self,request)
	sort_in_place(self,self.enemies,"handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount-1 end

	if slashcount>0  then
		for _,enemy in ipairs(self.enemies)do
			if flag(self,enemy,"AI_HuangtianPindian") and enemy:getHandcardNum()==1 and self.player:canPindian(enemy) then
				self.xianzhen_card = max_card:getId();self:remember("xianzhen_card",self.xianzhen_card)
				use.card = policy_card(self,"xianzhen","XianzhenCard",{},request)
				use.to:append(enemy)
				self:setStrategyPlayerFlag(enemy,"AI_HuangtianPindian",false)
				return
			end
		end

		--[[local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = dummy()
		self:useBasicCard(slash,dummy_use)--]]

		for _,enemy in ipairs(self.enemies)do
			if not (skill(self,enemy,"kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and self:canAttack(enemy,self.player)
				and not self:canLiuli(enemy,self.friends_noself) and not self:findLeijiTarget(enemy,50,self.player) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point =enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point>enemy_max_point then
					self.xianzhen_card = max_card:getId();self:remember("xianzhen_card",self.xianzhen_card)
					use.card = policy_card(self,"xianzhen","XianzhenCard",{},request)
					use.to:append(enemy)
					return
				end
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if not (skill(self,enemy,"kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and self:canAttack(enemy,self.player)
				and not self:canLiuli(enemy,self.friends_noself) and not self:findLeijiTarget(enemy,50,self.player) then
				if max_point>=10 then
					self.xianzhen_card = max_card:getId();self:remember("xianzhen_card",self.xianzhen_card)
					use.card = policy_card(self,"xianzhen","XianzhenCard",{},request)
					use.to:append(enemy)
					return
				end
			end
		end
	end
	local cards = AIList.new(self.player:getHandcards())
	cards = self:sortByUseValue(cards,true)
	if (self:getUseValue(cards[1])<6 and self:getKeepValue(cards[1])<6) or self:getOverflow()>0 then
		for _,enemy in ipairs(self.enemies)do
			if not (skill(self,enemy,"kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and not self:hasTuntianEffect(enemy, true) then
				self.xianzhen_card = cards[1]:getId();self:remember("xianzhen_card",self.xianzhen_card)
				use.card = policy_card(self,"xianzhen","XianzhenCard",{},request)
				use.to:append(enemy)
				return
			end
		end
	end
end

function sgs.ai_skill_pindian.xianzhen(minusecard,self,requestor)
	if requestor:getHandcardNum()==1 then
		local cards = AIList.new(self.player:getHandcards())
		cards = self:sortByKeepValue(cards)
		return cards[1]
	end
	if requestor:getHandcardNum()<=2 then return minusecard end
end

sgs.ai_card_intention.XianzhenCard = 70

sgs.dynamic_value.control_card.XianzhenCard = true

sgs.ai_use_value.XianzhenCard = 9.2
sgs.ai_use_priority.XianzhenCard = 9.2

sgs.ai_fill_skill.paiyi=function(self,inclusive,request)
	if self.player:getPile("power"):length()>0 then
		return policy_card(self,"paiyi","PaiyiCard",{self.player:getPile("power")[1]},request)
	end
end

sgs.ai_skill_use_func.PaiyiCard = function(card,use,self,request)
	local target
	sort_in_place(self,self.friends_noself,"defense")
	for _,friend in ipairs(self.friends_noself)do
		if friend:getHandcardNum()<2 and friend:getHandcardNum()+1<self.player:getHandcardNum()
		  and not self:needKongcheng(friend,true) and not skill(self,friend,"manjuan") then
			target = friend
		end
		if target then break end
	end
	if not target then
		if self.player:getHandcardNum()<self.player:getHp()+self.player:getPile("power"):length()-1 then
			target = self.player
		end
	end
	sort_in_place(self,self.friends_noself,"hp")
	self.friends_noself = reversed(self.friends_noself)
	if not target then
		for _,friend in ipairs(self.friends_noself)do
			if friend:getHandcardNum()+2>self.player:getHandcardNum()
			and self:needToLoseHp(friend,self.player,nil,true)
			and not skill(self,friend,"manjuan") then
				target = friend
			end
			if target then break end
		end
	end
	sort_in_place(self,self.enemies,"defense")
	if not target then
		for _,enemy in ipairs(self.enemies)do
			if skill(self,enemy,"manjuan")
			and not (self:hasSkills(sgs.masochism_skill,enemy) and not skill(self,self.player,"jueqing"))
			and self:damageIsEffective(enemy,sgs.DamageStruct_Normal,self.player)
			and not self:needToLoseHp(enemy)
			and enemy:getHandcardNum()>self.player:getHandcardNum() 
			then target = enemy end
			if target then break end
		end
		if not target then
			for _,enemy in ipairs(self.enemies)do
				if not (self:hasSkills(sgs.masochism_skill,enemy) and not skill(self,self.player,"jueqing"))
				and not skill(self,enemy,sgs.cardneed_skill.."|jijiu|tianxiang|buyi")
				and self:damageIsEffective(enemy,sgs.DamageStruct_Normal,self.player) and not self:cantbeHurt(enemy)
				and not self:needToLoseHp(enemy)
				and enemy:getHandcardNum()+2>self.player:getHandcardNum()
				and not skill(self,enemy,"manjuan") 
				then target = enemy end
				if target then break end
			end
		end
	end

	if target then
		use.card = policy_card(self,"paiyi","PaiyiCard",{self.player:getPile("power")[1]},request)
		use.to:append(target)
	end
end

sgs.ai_skill_askforag.paiyi = function(self,card_ids)
	return card_ids[math.random(1,#card_ids)]
end

sgs.ai_card_intention.PaiyiCard = function(self,card,from,tos)
	local to = tos[1]
	if to:objectName()==from:objectName() then return end
	if not skill(self,to,"manjuan")
	and ((to:getHandcardNum()<2 and to:getHandcardNum()+1<from:getHandcardNum() and not self:needKongcheng(to,true))
	or (to:getHandcardNum()+2>from:getHandcardNum() and self:needToLoseHp(to,from)))
	then
	else
		sgs.updateIntention(from,to,60)
	end
end

sgs.ai_skill_defense.paiyi = 1.5

sgs.ai_fill_skill.nosyexin=function(self,inclusive,request)
	local hs = self.player:getHandcards()
	hs = AIList.new(hs)
	hs = self:sortByKeepValue(hs)
	local cards = {}
	for _,id in ipairs(self.player:getPile("nospower"))do
		table.insert(cards,material(self,id))
	end
	local ids = {}
	for _,h in ipairs(hs)do
		for _,c in ipairs(cards)do
			if table.contains(ids,c:getId()) then continue end
			if self:getKeepValue(h)<self:getKeepValue(c) and self:aiUseCard(c).card then
				table.insert(ids,h:getId())
				table.insert(ids,c:getId())
			end
		end
	end
	if #ids>1 then
		return policy_card(self,"nosyexin","NosYexinCard",ids,request)
	end
end

sgs.ai_skill_use_func.NosYexinCard = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.NosYexinCard = 9.2

ai_skill_use["@@jujian"]=function(self,prompt,request)
 local method=known(request and (request.handling_method or request.getHandlingMethod and request:getHandlingMethod()) or self.request.handling_method,"jujian.handling_method")
	local needfriend = 0
	local nobasiccard = -1
	local cards = self.player:getCards("he")
	cards = AIList.new(cards)
	if self:needToThrowArmor() and not self.player:isCardLimited(self.player:getArmor(),method) then
		nobasiccard = self.player:getArmor():getId()
	else
		cards = self:sortByKeepValue(cards)
		for _,card in ipairs(cards)do
			if card:getTypeId()~=sgs.Card_TypeBasic and not self.player:isCardLimited(card,method) then nobasiccard = card:getEffectiveId() end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if self:isWeak(friend) or friend:getHandcardNum()<2 or not friend:faceUp() or self:getOverflow()>0
		or (friend:getArmor() and friend:getArmor():objectName()=="Vine" and (friend:isChained() and not self:isGoodChainPartner(friend))) then
			needfriend = needfriend+1
		end
	end
	if nobasiccard<0 or needfriend<1 then return "." end
	sort_in_place(self,self.friends_noself,"defense")
	for _,friend in ipairs(self.friends_noself)do
		if not friend:faceUp() then
			return action(self,"jujian",{nobasiccard},{friend},request)
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if friend:getArmor() and friend:getArmor():objectName()=="Vine" and (friend:isChained() and not self:isGoodChainPartner(friend)) then
			return action(self,"jujian",{nobasiccard},{friend},request)
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if self:isWeak(friend) then
			return action(self,"jujian",{nobasiccard},{friend},request)
		end
	end

	local AssistTarget = self:AssistTarget()
	local friend
	if AssistTarget and AssistTarget:isWounded() and not self:needToLoseHp(AssistTarget,nil,nil,nil,true) then
		friend = AssistTarget
	elseif AssistTarget and not skill(self,AssistTarget,"manjuan") and not self:needKongcheng(AssistTarget,true) then
		friend = AssistTarget
	else
		friend = self.friends_noself[1]
	end
	return action(self,"jujian",{nobasiccard},{friend},request)
end


sgs.ai_cardneed.xianzhen=function(to,card,self)
 local observer=self.room:getCurrent() or self.player
 local cards=self:getKnownCards(to,observer,"h")
 if not cards then
  self:useKnowledgeEstimate({status="estimate",value=true,basis="yjcm.other_current_visibility_uses_viewer_hand",target=to:objectName()},"xianzhen.cardneed")
  cards=self:getKnownCards(to,self.player,"h")
 end
 for _,c in ipairs(known(cards,"xianzhen.visible_cards"))do
  local visible=true
  if to:objectName()==self.player:objectName()then
   local globally=known(c:hasFlag("visible"),"xianzhen.owner_visibility_flag")
   visible=globally or known(c:hasFlag("visible_"..observer:objectName().."_"..to:objectName()),"xianzhen.owner_visibility_flag")
  end
  if visible and c:getNumber()>10 then return card:isKindOf("Slash") or card:isKindOf("Analeptic")end
 end
 return card:getNumber()>10
end
for skill_name,class in pairs({jujian="JujianCard",ganlu="GanluCard",mingce="MingceCard",xianzhen="XianzhenCard",paiyi="PaiyiCard"})do
 sgs.ai_card_intention[skill_name]=sgs.ai_card_intention[class]
end

-- Known hand membership is viewer scoped. A different observer's private
-- visibility flags use the explicitly marked common knowledge estimate.
local function visible_hand(self,target,observer)
 local cards=self:getKnownCards(target,observer,"h")
 if cards==nil then
  self:useKnowledgeEstimate({status="estimate",value=true,basis="yjcm.other_observer_hand_uses_viewer_knowledge",target=target:objectName()},"buyi.visible_hand")
  cards=self:getKnownCards(target,self.player,"h")
 end
 return known(cards,"buyi.visible_hand")
end
sgs.ai_skill_invoke.buyi=function(self,data)
 local dying=known(data:toDying(),"buyi.dying");local who=known(dying.who,"buyi.who")
 if who:isKongcheng()then return false end
 local friend=not self:isEnemy(who)
 if not known(self.world.enable_hegemony,"buyi.hegemony") and self.role=="renegade" then
  if self.room:getMode()=="couple" then
  elseif not(who:isLord()or who:objectName()==self.player:objectName())then
   local roles=self:getRoleCounts()
   if known(roles.loyalist,"buyi.loyalists")+1==known(roles.rebel,"buyi.rebels")
    or roles.loyalist==roles.rebel or self.room:getCurrent():objectName()==self.player:objectName()then friend=false end
  end
 end
 local all_basic=true;local cards=visible_hand(self,who,self.player)
 for _,card in ipairs(cards)do if card:getTypeId()~=sgs.Card_TypeBasic then all_basic=false end end
 if #cards<who:getHandcardNum()then all_basic=false end
 return friend and not all_basic
end
sgs.ai_choicemade_filter.skillInvoke.buyi=function(self,player,promptlist)
 local dying=self.room:getCurrentDyingPlayer()
 if promptlist[#promptlist]=="yes"then
  if dying and dying:objectName()~=self.player:objectName()then sgs.updateIntention(player,dying,-80)end
 elseif promptlist[#promptlist]=="no"then
  if not dying or dying:isKongcheng()or dying:objectName()==self.player:objectName()then return end
  local all_basic=true;local cards=visible_hand(self,dying,player)
  for _,card in ipairs(cards)do if card:getTypeId()~=sgs.Card_TypeBasic then all_basic=false end end
  if #cards<dying:getHandcardNum()then all_basic=false end
  if not all_basic then sgs.updateIntention(player,dying,80)end
 end
end
sgs.ai_cardshow.buyi=function(self,requestor)
 assert(self.player:objectName()==requestor:objectName())
 for _,card in ipairs(known(self.player:getHandcards(),"buyi.owner_hand"))do
  if card:getTypeId()~=sgs.Card_TypeBasic then return card end
 end
 if self.player:isKongcheng()then return nil end
 -- Native Player RNG is a separate stream from Lua math.random.
 return self.player:getRandomHandCard()
end
sgs.ai_skill_cardchosen.xuanfeng=function(self,who,flags)
 local equips=known(who:getEquips(),"xuanfeng.equips")
 if #equips>0 then return equips[1]:getId()end
 local count=who:getHandcardNum()
 if count==0 then return -1 end
 if who:isHandVisible()==true then
  local cards=known(who:getKnownCards(),"xuanfeng.visible_hand")
  if #cards~=count then ai_unsupported("visible hand order is incomplete","xuanfeng.visible_hand")end
  if count<3 or known(cards[1]:hasFlag("visible"),"xuanfeng.first_visible")then return cards[1]:getId()end
  return -1
 end
 if count>=3 then
  -- Native hand order is hidden. Do not query its first face/visibility bit.
  self:useKnowledgeEstimate({status="estimate",value=false,basis="yjcm.xuanfeng_hidden_first_global_visibility_uses_unknown",target=who:objectName()},"xuanfeng.first_visible")
  return -1
 end
 if self.disabled_ids and #self.disabled_ids>0 then ai_unsupported("hidden original first may require donor disabled-card fallback","xuanfeng.hidden_disabled")end
 local context=self:getDecisionContext()
 local row=known(context.random_card_choices and context.random_card_choices.xuanfeng_first_hand,"xuanfeng.opaque_hand")
 if row.count~=count or row.source_first~=true then ai_unsupported("original first hand ordinal is not authorized","xuanfeng.first_hand")end
 return {kind="answer",random_card_choice={token=row.token,index=1,avoid_wounded_enemy_silver_lion=false}}
end
sgs.ai_choicemade_filter.cardChosen.xuanfeng=sgs.ai_choicemade_filter.cardChosen.dismantlement
ai_skill_use["@@nospaiyi"]=function(self,prompt,request)
	local valid,to = {},nil
	local cards = {}
	for _,id in ipairs(self.player:getPile("nospower"))do
		table.insert(cards,material(self,id))
	end
	local c,p = self:getCardNeedPlayer(cards,true)
	if c and p then
		self:setStrategyMemory("choice_override:nospaiyi","hand_area")
		return action(self,"nospaiyi",{c:getId()},{p},request)
	end
	local players = self.room:getAlivePlayers()
    players = self:sort(players)
    for _,p in ipairs(players)do
      	if self:isEnemy(p) then
			for _,c in ipairs(cards)do
				if c:isKindOf("DelayedTrick") then
					ai_unsupported("fixed donor dereferences undefined seif before prohibition","nospaiyi.donor_undefined_seif")
					self:setStrategyMemory("choice_override:nospaiyi","judge_area")
					return action(self,"nospaiyi",{c:getId()},{p},request)
				elseif c:isKindOf("EquipCard") then
					if #self:poisonCards({c},p)<1 then continue end
					ai_unsupported("fixed donor dereferences undefined seif before prohibition","nospaiyi.donor_undefined_seif")
					local n = c:getRealCard():toEquipCard():location()
					if p:hasEquip(n) then continue end
					self:setStrategyMemory("choice_override:nospaiyi","equip_area")
					return action(self,"nospaiyi",{c:getId()},{p},request)
				end
			end
		elseif self:isFriend(p) then
			for _,c in ipairs(cards)do
				if c:isKindOf("EquipCard") then
					if #self:poisonCards({c},p)>0 then continue end
					ai_unsupported("fixed donor dereferences undefined seif before prohibition","nospaiyi.donor_undefined_seif")
					local n = c:getRealCard():toEquipCard():location()
					if p:hasEquip(n) then continue end
					self:setStrategyMemory("choice_override:nospaiyi","equip_area")
					return action(self,"nospaiyi",{c:getId()},{p},request)
				end
			end
			for _,c in ipairs(cards)do
				if self:canDraw(p) then
					if #self:poisonCards({c},p)>0 then continue end
					self:setStrategyMemory("choice_override:nospaiyi","hand_area")
					return action(self,"nospaiyi",{c:getId()},{p},request)
				end
			end
		end
	end
end

-- Audited literal invoke aliases from sp-ai and special1v1; native identity gates each request.
if ai_audited_aliases then
    ai_audited_aliases.register{id="ai_skill_invoke.shenxian",registry="ai_skill_invoke",path={"shenxian"},canonical_registry="ai_skill_invoke",canonical_path={"luoying"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_skill_invoke.yinli",registry="ai_skill_invoke",path={"yinli"},canonical_registry="ai_skill_invoke",canonical_path={"luoying"},self_index=1,defer_canonical=true}
end
