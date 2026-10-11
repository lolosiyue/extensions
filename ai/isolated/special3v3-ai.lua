-- Fixed b6025acc package policy; all selection uses pure views and native-issued receipts.
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("package helper unavailable",method) end
    local value=object[method](object,...)
    if AIUnsupported.is(value) then error(value,0) end
    return value
end
local function q(object,method,...)
    local value=call(object,method,...)
    if value==nil then ai_unsupported("package input is unknown",method) end
    return value
end
local function paid(self,skill,selector,request,old)
    local card=q(self,"bindSkillCard",skill,{},request,nil,selector)
    if old then card=q(self,"inheritLegacyCardIdentity",card,old) end
    return card
end
local function answer(self,skill,class,ids,names,request)
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room) end
    local use=AIUsePlan.new();use.card=q(self,"bindSkillCard",skill,ids,request,nil,class);use.to=AIList.new({})
    for _,name in ipairs(names)do call(use.to,"append",q(self.room,"findPlayerByObjectName",name))end
    return q(use,"toAnswer")
end
local function role(self,player)
    local r=call(player,"getRole");if r~=nil then return r end
    return q(self,"useKnowledgeEstimate",{value=q(self,"getRoleEstimate",player),status="estimate",basis="special3v3.unrevealed_role_viewer_estimate",target=q(player,"objectName")},"special3v3.role")
end
local function find_huanshi(self)
    for _,p in ipairs(q(self.room,"getAlivePlayers"))do if q(p,"hasSkill","huanshi")then return p end end
end
local function ganglie_effect(self)
    local value,known=self:getStrategyMemory("ai_ganglie_effect")
    if known then return value end
    return q(self,"useKnowledgeEstimate",{value=false,status="estimate",basis="special3v3.ganglie_effect_unobserved_viewer_history"},"vsganglie.intention")
end
sgs.ai_skill_choice["3v3_direction"] = function(self,choices,data)
	local card = call(data,"toCard")
	local aggressive = (card and q(card,"isKindOf","AOE"))
	if q(self,"isFriend",q(self.player,"getNextAlive"))==aggressive then return "cw" else return "ccw" end
end

sgs.ai_skill_cardask["@huanshi-card"] = function(self,data)
	local judge = q(data,"toJudge")

	if q(self,"needRetrial",judge) then
		local cards = sgs.QList2Table(q(self.player,"getCards","he"))
		for _,id in sgs.list(q(self.player,"getPile","wooden_ox"))do
			ai_unsupported("donor_error: Huanshi plain Lua array has no prepend method","huanshi.wooden_ox")
		end
		local card_id = q(self,"getRetrialCardId",cards,judge)
		if card_id~=-1 then
			return "$"..card_id
		end
	end

	return "."
end

sgs.ai_skill_invoke.huanshi = function(self,data)
	local judge = q(data,"toJudge")

	if q(self,"needRetrial",judge) then
		local cards = sgs.QList2Table(q(self.player,"getCards","he"))
		if q(self,"isFriend",judge.who) then
			local card_id = q(self,"getRetrialCardId",cards,judge)
			if card_id~=-1 then return true end
		elseif q(self,"isEnemy",judge.who) then
			for _,card in sgs.list(cards)do
				if q(judge,"isGood",card) or q(self,"isValuableCard",card) then return false end
			end
			return true
		end
	end
	return false
end

sgs.ai_skill_askforag.huanshi = function(self,card_ids)
	local cards = {}
	for _,id in sgs.list(card_ids)do
		table.insert(cards,q(self,"getChoiceCard",id))
	end
	local judge = q(self,"getJudge")
	local zhugejin = find_huanshi(self)

	local cmp = function(a,b)
		local a_keep_value,b_keep_value = sgs.ai_keep_value[q(a,"getClassName")] or 0,sgs.ai_keep_value[q(b,"getClassName")] or 0
		a_keep_value = a_keep_value+q(a,"getNumber")/100
		b_keep_value = b_keep_value+q(b,"getNumber")/100
		if zhugejin and q(zhugejin,"hasSkill","mingzhe") then
			if q(a,"isRed") then a_keep_value = a_keep_value-0.3 end
			if q(b,"isRed") then b_keep_value = b_keep_value-0.3 end
		end
		return a_keep_value<b_keep_value
	end

	local card_id = q(self,"getRetrialCardId",cards,judge,false)
	if card_id~=-1 then return card_id end
	if zhugejin and not q(self,"isEnemy",zhugejin) then
		local valueless = {}
		for _,card in sgs.list(cards)do
			if not q(self,"isValuableCard",card,zhugejin) then table.insert(valueless,card) end
		end
		if #valueless==0 then valueless = cards end
		table.sort(valueless,cmp)
		return valueless[1]:getEffectiveId()
	else
		for _,card in sgs.list(cards)do
			if q(judge,"isGood",card) then return q(card,"getEffectiveId") end
		end
		local valuable = {}
		for _,card in sgs.list(cards)do
			if q(self,"isValuableCard",card,zhugejin) then table.insert(valuable,card) end
		end
		if #valuable==0 then valuable = cards end
		table.sort(valuable,cmp)
		return valuable[#valuable]:getEffectiveId()
	end
	return -1
end

function sgs.ai_cardneed.huanshi(to,card,self)
	for _,player in sgs.list(self.friends)do
		if q(self,"getFinalRetrial",to)==1 then
			if q(self,"willSkipDrawPhase",player) then
				return q(card,"getSuit")==sgs.Card_Club and not q(self,"hasSuit","club",true,to)
			end
			if q(self,"willSkipPlayPhase",player) then
				return q(card,"getSuit")==sgs.Card_Heart and not q(self,"hasSuit","heart",true,to)
			end
		end
	end
end

sgs.ai_skill_invoke.hongyuan = function(self,data)
	local count = 0
	for i = 1,#self.friends_noself do
		if q(self,"needKongcheng",self.friends_noself[i],true) or q(self.friends_noself[i],"hasSkill","manjuan") then
		else
			count = count+1
		end
		if count==2 then return true end
	end
	return false
end

function sgs.ai_cardneed.mingzhe(to,card,self)
	return q(card,"isRed") and getKnownCard(to,self.player,"red",false)<2
end

ai_skill_use["@@hongyuan"] = function(self,prompt,request)
	call(self,"sort",self.friends_noself,"handcard")
	local first_index,second_index
	for i = 1,#self.friends_noself do
		if q(self,"needKongcheng",self.friends_noself[i]) and q(self.friends_noself[i],"getHandcardNum")==0
			or q(self.friends_noself[i],"hasSkill","manjuan") then
		else
			if not first_index then
				first_index = i
			else
				second_index = i
			end
		end
		if second_index then break end
	end

	if first_index and not second_index then
		local others = q(self.room,"getOtherPlayers",self.player)
		for _,other in sgs.list(others)do
			if (not q(self,"isFriend",other) and (q(self,"needKongcheng",other) and q(other,"getHandcardNum")==0 or q(other,"hasSkill","manjuan"))) and
				q(self.friends_noself[first_index],"objectName")~=q(other,"objectName") then
				return answer(self,"hongyuan","HongyuanCard",{}, {q(self.friends_noself[first_index],"objectName"),q(other,"objectName")},request)
			end
		end
	end

	if not second_index then return "." end

	local first = q(self.friends_noself[first_index],"objectName")
	local second = q(self.friends_noself[second_index],"objectName")
	return answer(self,"hongyuan","HongyuanCard",{},{first,second},request)
end

sgs.ai_card_intention.HongyuanCard = -70

sgs.ai_suit_priority.mingzhe=function(self)
	return q(self.player,"getPhase")==sgs.Player_NotActive
	and "diamond|heart|club|spade"
end

sgs.huanshi_suit_value = {
	heart = 3.9,
	diamond = 3.4,
	club = 3.9,
	spade = 3.5
}

sgs.mingzhe_suit_value = {
	heart = 4.0,
	diamond = 4.0
}

sgs.ai_skill_playerchosen.vsganglie = function(self,targets)
	call(self,"sort",self.enemies)
	local prior_enemies = {}
	for _,enemy in sgs.list(self.enemies)do
		if q(enemy,"getHandcardNum")<2 then table.insert(prior_enemies,enemy) end
	end
	for _,enemy in sgs.list(prior_enemies)do
		if call(self,"canAttack",enemy) then return enemy end
	end
	for _,enemy in sgs.list(self.enemies)do
		if call(self,"canAttack",enemy) or q(enemy,"getHandcardNum")>3 then return enemy end
	end
	if q(self.room,"getMode")=="06_3v3" or q(self.room,"getMode")=="06_XMode" then return nil end
	for _,friend in sgs.list(self.friends_noself)do
		if q(self,"damageIsEffective",friend,sgs.DamageStruct_Normal,friend) and not q(self,"cantbeHurt",friend) and q(self,"needToLoseHp",friend,self.player) then
			call(self,"setStrategyMemory","ai_ganglie_effect",string.format("%s_%s_%d",q(self.player,"objectName"),q(friend,"objectName"),q(self.room,"getTurnCount")))
			return friend
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.vsganglie = function(self,from,to)
	local effect=ganglie_effect(self)
	if effect and effect==string.format("%s_%s_%d",q(from,"objectName"),q(to,"objectName"),q(self.room,"getTurnCount")) then
		call(self,"updateIntention",from,to,-10)
	elseif q(from,"getState")=="online" then
		if not q(from,"hasSkill","jueqing") and q(self,"needToLoseHp",to,from) then return end
		call(self,"updateIntention",from,to,40)
	else
		call(self,"updateIntention",from,to,80)
	end
end

sgs.ai_need_damaged.vsganglie = function(self,attacker,player)
	for _,enemy in sgs.list(self.enemies)do
		if q(self,"isEnemy",enemy,player) and q(enemy,"getHp")+q(enemy,"getHandcardNum")<=3
		and not (q(enemy,"hasSkills",sgs.need_kongcheng) and not hasBuquEffect(enemy) and q(enemy,"getHandcardNum")>1) then
			return true
		end
	end
	return false
end

sgs.ai_skill_discard.vsganglie = function(self,discard_num,min_num,optional,include_equip)
	return nosganglie_discard(self,discard_num,min_num,optional,include_equip,"vsganglie")
end

function sgs.ai_slash_prohibit.vsganglie(self,from,to)
	if q(self,"isFriend",from,to) then return false end
	if q(from,"hasSkill","jueqing") or (q(from,"hasSkill","nosqianxi") and q(from,"distanceTo",to)==1) then return false end
	if q(from,"getStrategyFlag","NosJiefanUsed") then return false end
	if #(q(self,"getEnemies",from))>1 then
		for _,p in sgs.list(q(self,"getFriends",from))do
			if q(p,"getHandcardNum")+q(p,"getHp")<4 then return true end
		end
	end
	return false
end

sgs.ai_fill_skill.zhongyi = function(self,inclusive,request)
	if q(self.player,"isKongcheng") or q(self.room,"getTurnCount")<=1 then return end

	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	local red_card
	call(self,"sortByUseValue",cards,true)
	for _,card in sgs.list(cards)do
		if q(card,"isRed") and not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) then
			red_card = card
			break
		end
	end

	if not red_card then return end

	local value = 0
	local friends = {}
	if q(self.room,"getMode")=="06_3v3" then
		for _,friend in sgs.list(self.friends)do
			if not q(friend,"getStrategyFlag","actioned") then table.insert(friends,friend) end
		end
	else
		friends = self.friends
	end
	call(self,"sort",self.enemies)
	local slash = q(self,"getEvaluationCard","slash")
	for _,friend in sgs.list(friends)do
		local local_value = 0
		for _,enemy in sgs.list(self.enemies)do
			if q(friend,"canSlash",enemy) and not q(self,"slashProhibit",slash,enemy) and q(self,"slashIsEffective",slash,enemy) and q(self,"isGoodTarget",enemy,self.enemies,slash) then
				local_value = local_value+0.8
				if getCardsNum("Jink",enemy)<1 then local_value = local_value+0.5 end
				if q(friend,"hasSkill","tieji")
					or (q(friend,"hasSkill","liegong") and (q(enemy,"getHandcardNum")<=q(friend,"getAttackRange") or q(enemy,"getHandcardNum")>=q(friend,"getHp")))
					or (q(friend,"hasSkill","kofliegong") and q(enemy,"getHandcardNum")>=q(friend,"getHp")) then
					local_value = local_value+0.5
				end
				break
			end
		end
		if getCardsNum("Slash",friend)<1 then local_value = local_value*0.3
		elseif q(self,"hasCrossbowEffect",friend) then local_value = local_value*getCardsNum("Slash",friend) end
		if q(friend,"hasSkill","shensu") and not q(self,"isWeak",friend) then local_value = local_value*1.2
		elseif q(self,"willSkipPlayPhase",friend) then local_value = local_value*0.2 end
		value = value+local_value
	end
	local ratio = value/#self.enemies
	if ratio>0.85 then return q(self,"evaluateTurnSkillCard","zhongyi","ZhongyiCard",{q(red_card,"getEffectiveId")},request) end
end

sgs.ai_skill_use_func.ZhongyiCard = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.ZhongyiCard = 10

sgs.ai_skill_invoke.zhongyi = function(self,data)
	local damage = q(data,"toDamage")
	return q(self,"isEnemy",damage.to)
end

function sgs.ai_cardsview.jiuzhu(self,class_name,player)
	if class_name=="Peach" and q(player,"getHp")>1 and not q(player,"isNude")
	then
		local dying = call(self.room,"getCurrentDyingPlayer")
		if not dying then return nil end
		if (q(self.room,"getMode")=="06_3v3" or q(self.room,"getMode")=="06_XMode") and not q(self,"isFriend",dying) then return nil end
		local must_save = false
		if q(self.room,"getMode")=="06_3v3" then
			if role(self,dying)=="renegade" or role(self,dying)=="lord" then must_save = true end
		elseif q(dying,"isLord") and (q(self.player,"getRole")=="loyalist" or (q(self.player,"getRole")=="renegade" and q(self.room,"alivePlayerCount")>2)) then
			must_save = true
		end
		if not must_save and q(self,"isWeak",player) and not q(player,"hasArmorEffect","SilverLion") then return nil end
		local to_discard = q(self,"askForDiscard",player,"dummyreason",1,1,false,true)
		if #to_discard==1 then return q(self,"bindSkillCard","jiuzhu",to_discard,nil,nil,"JiuzhuCard") end
	end
end

sgs.ai_card_intention.JiuzhuCard = sgs.ai_card_intention.Peach

sgs.ai_skill_invoke.zhanshen = function(self,data)
	local obj = q(data,"toString"):split(":")[2]
	local lvbu = q(self.room,"findPlayerByObjectName",obj)
	return q(self,"isFriend",lvbu)
end

ai_skill_use["@@zhenwei"] = function(self,prompt,request)
	local total = math.floor(q(self.room,"getModePlayerCount")/2)-1
	if total==0 then return "." end
	local targets = {}
	if #self.friends_noself>0 then
		call(self,"sort",self.friends_noself,"defense")
		for _,friend in sgs.list(self.friends_noself)do
			table.insert(targets,q(friend,"objectName"))
			if #targets==total then break end
		end
	elseif #self.enemies>0 and q(self.room,"getTurnCount")>=2 then
		call(self,"sort",self.enemies,"defense")
		for _,enemy in sgs.list(self.enemies)do
			table.insert(targets,q(enemy,"objectName"))
			if #targets==total then break end
		end
	end
	if #targets==0 then return "."
	else return answer(self,"zhenwei","ZhenweiCard",{},targets,request)
	end
end

sgs.ai_card_intention.ZhenweiCard = function(self,card,from,tos)
	if #q(self,"getFriends",from,true)>0 then
		for _,to in sgs.list(tos)do
			call(self,"updateIntention",from,to,-50)
		end
	end
end

sgs.weapon_range.VSCrossbow = sgs.weapon_range.Crossbow
sgs.ai_use_priority.VSCrossbow = sgs.ai_use_priority.Crossbow
