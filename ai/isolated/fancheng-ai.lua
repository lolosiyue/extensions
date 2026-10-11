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
local function cost_seed(self,skill,class,request,ids)
    local card=q(self,"evaluateTurnSkillCard",skill,class,ids,request)
    local actual=q(card,"getSubcards")
    if #actual~=#ids then ai_unsupported("cost-bearing source seed unavailable",skill) end
    for i,id in ipairs(ids)do if actual[i]~=id then ai_unsupported("source seed changed ordered costs",skill)end end
    return card
end
local function selected(self,skill,class,card,request)
    local receipt=q(self,"bindSkillCard",skill,q(card,"getSubcards"),request,nil,class)
    return q(self,"inheritLegacyCardIdentity",receipt,card)
end
local function answer(self,skill,class,ids,names,request)
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room) end
    local use=AIUsePlan.new();use.card=q(self,"bindSkillCard",skill,ids,request,nil,class);use.to=AIList.new({})
    for _,name in ipairs(names)do call(use.to,"append",q(self.room,"findPlayerByObjectName",name))end
    return q(use,"toAnswer")
end
local function role(self,player)
    local value=call(player,"getRole")
    if value~=nil then return value end
    return q(self,"useKnowledgeEstimate",{value=q(self,"getRoleEstimate",player),status="estimate",basis="fancheng.viewer_role_estimate_for_unrevealed_role",target=q(player,"objectName")},"fancheng.role")
end
sgs.ai_fill_skill.zhiyuan=function(self,inclusive,request)
	local cards = q(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)

	local basic_card
	call(self,"sortByUseValue",cards,true)

	for _,card in sgs.list(cards)  do
		if q(card,"getTypeId")==sgs.Card_TypeBasic then
			if q(card,"isKindOf","Slash") and (q(self,"getCardsNum","Slash")<=1)then
			elseif q(card,"isKindOf","Jink") and (q(self,"getCardsNum","Jink")<=1)then
			elseif q(card,"isKindOf","Peach") and (q(self.player,"getHp")<=2)then
			else
				basic_card = card
				break
			end
		end
	end

	if basic_card then
		return cost_seed(self,"zhiyuan","ZhiyuanCard",request,{q(basic_card,"getEffectiveId")})
	end
end

sgs.ai_skill_use_func.ZhiyuanCard = function(card,use,self,request)
	if q(self.player,"usedTimes","ZhiyuanCard")>1 then return end
	call(self,"sort",self.friends_noself,"handcard")
	for _,friend in sgs.list(self.friends_noself)do
		if role(self,friend)=="rebel" then
			use.card = card
			call(use.to,"append",friend)
			return
		end

	end
end

sgs.ai_fill_skill.taichen_fight=function(self,inclusive,request)
	return q(self,"legacySkillSeed","taichen_fight","TaichenFightCard",request)
end

sgs.ai_skill_use_func.TaichenFightCard = function(card,use,self,request)
	if q(self.player,"usedTimes","TaichenFightCard")>0 then return end
	local lord=call(self.room,"getLord")
	if lord and q(self.player,"getHp")>=q(lord,"getHp") then
		if (q(self,"getCardsNum","Slash")+1)*2>getCardsNum("Slash",lord)
		then use.card=selected(self,"taichen_fight","TaichenFightCard",card,request) end
	end
end

sgs.ai_fill_skill.flood=function(self,inclusive,request)
	local cards=q(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)
	call(self,"sortByUseValue",cards,true)
	local blacks={}
	for _,card in sgs.list(cards)do
		if q(card,"isBlack") then
			table.insert(blacks,q(card,"getEffectiveId"))
			if #blacks==3 then break end
		end
	end
	if #blacks<3 then return nil end
	return cost_seed(self,"flood","FloodCard",request,blacks)
end

sgs.ai_skill_use_func["FloodCard"]=function(card,use,self,request)

	local eqs=0

	local players=q(self.room,"getOtherPlayers",self.player)
	for _,player in sgs.qlist(players)do
		if role(self,player)=="rebel" then
			eqs=eqs+#q(self.player,"getEquips")
			if (q(player,"getHandcardNum")<=2) or (q(player,"getHp")<2) then
				eqs=eqs+2
			end
		end
	end

	if eqs>3 then
		use.card=card
	end
end

sgs.ai_skill_discard.flood = sgs.ai_skill_discard.ganglie
ai_skill_use["@@dujiang"] = function(self,prompt,request)
	local equips=q(self.player,"getEquips")
	equips=sgs.QList2Table(equips)

	if #equips<2 then return {kind="pass"} end

	return answer(self,"dujiang","DujiangCard",{q(equips[1],"getEffectiveId"),q(equips[2],"getEffectiveId")},{},request)
end

sgs.ai_skill_invoke.xiansheng=function(self)
	local players=q(self.room,"getOtherPlayers",self.player)

	local rebel=0
	for _,player in sgs.qlist(players)do
		if q(self,"objectiveLevel",player)>=4 then
			rebel=rebel+1
		end
	end

	if rebel*2+3>(#q(self.player,"getEquips")*2+q(self.player,"getHandcardNum")) then return true end
	if q(self.player,"getHp")==1 and q(self.player,"getHandcardNum")<=1 then return true end
	return false
end

ai_skill_use["@@smalltuxi"] = function(self,prompt,request)
	call(self,"sort",self.enemies,"handcard")

	local first_index
	for i = 1,#self.enemies do
		if q(self,"hasSkills",sgs.need_kongcheng,self.enemies[i]) and q(self.enemies[i],"getHandcardNum")==1 then
		elseif not q(self.enemies[i],"isKongcheng") then
			first_index = i
			break
		end
	end

	local first = q(self.enemies[first_index],"objectName")
	return answer(self,"smalltuxi","SmallTuxiCard",{},{first},request)
end

sgs.ai_card_intention.SmallTuxiCard = 80

sgs.ai_skill_invoke.reselect = function(self)
	return math.random(0,2)==0
end
