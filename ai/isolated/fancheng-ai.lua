-- Fixed b6025acc package policy; all selection uses pure views and native-issued receipts.


local function paid(self,skill,selector,request,old)
    local card=self:bindSkillCard(skill, {}, request, nil, selector)
    if old then card=self:inheritLegacyCardIdentity(card, old) end
    return card
end
local function cost_seed(self,skill,class,request,ids)
    local card=self:evaluateTurnSkillCard(skill, class, ids, request)
    local actual=card:getSubcards()
    if #actual~=#ids then ai_unsupported("cost-bearing source seed unavailable",skill) end
    for i,id in ipairs(ids)do if actual[i]~=id then ai_unsupported("source seed changed ordered costs",skill)end end
    return card
end
local function selected(self,skill,class,card,request)
    local receipt=self:bindSkillCard(skill, card:getSubcards(), request, nil, class)
    return self:inheritLegacyCardIdentity(receipt, card)
end
local function answer(self,skill,class,ids,names,request)
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room) end
    local use=AIUsePlan.new();use.card=self:bindSkillCard(skill, ids, request, nil, class);use.to=AIList.new({})
    for _,name in ipairs(names)do use.to:append(self.room:findPlayerByObjectName(name))end
    return use:toAnswer()
end
local function role(self,player)
    local value=player:getRole()
    if value~=nil then return value end
    return self:useKnowledgeEstimate({value=self:getRoleEstimate(player),status="estimate",basis="fancheng.viewer_role_estimate_for_unrevealed_role",target=player:objectName()}, "fancheng.role")
end
sgs.ai_fill_skill.zhiyuan=function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local basic_card
	self:sortByUseValue(cards, true)

	for _,card in sgs.list(cards)  do
		if card:getTypeId()==sgs.Card_TypeBasic then
			if card:isKindOf("Slash") and (self:getCardsNum("Slash")<=1)then
			elseif card:isKindOf("Jink") and (self:getCardsNum("Jink")<=1)then
			elseif card:isKindOf("Peach") and (self.player:getHp()<=2)then
			else
				basic_card = card
				break
			end
		end
	end

	if basic_card then
		return cost_seed(self,"zhiyuan","ZhiyuanCard",request,{basic_card:getKnownEffectiveId()})
	end
end

sgs.ai_skill_use_func.ZhiyuanCard = function(card,use,self,request)
	if self.player:usedTimes("ZhiyuanCard")>1 then return end
	self:sort(self.friends_noself, "handcard")
	for _,friend in sgs.list(self.friends_noself)do
		if role(self,friend)=="rebel" then
			use.card = card
			use.to:append(friend)
			return
		end

	end
end

sgs.ai_fill_skill.taichen_fight=function(self,inclusive,request)
	return self:legacySkillSeed("taichen_fight", "TaichenFightCard", request)
end

sgs.ai_skill_use_func.TaichenFightCard = function(card,use,self,request)
	if self.player:usedTimes("TaichenFightCard")>0 then return end
	local lord=self.room:getLord()
	if lord and self.player:getHp()>=lord:getHp() then
		if (self:getCardsNum("Slash")+1)*2>getCardsNum("Slash",lord)
		then use.card=selected(self,"taichen_fight","TaichenFightCard",card,request) end
	end
end

sgs.ai_fill_skill.flood=function(self,inclusive,request)
	local cards=self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local blacks={}
	for _,card in sgs.list(cards)do
		if card:isBlack() then
			table.insert(blacks,card:getKnownEffectiveId())
			if #blacks==3 then break end
		end
	end
	if #blacks<3 then return nil end
	return cost_seed(self,"flood","FloodCard",request,blacks)
end

sgs.ai_skill_use_func["FloodCard"]=function(card,use,self,request)

	local eqs=0

	local players=self.room:getOtherPlayers(self.player)
	for _,player in sgs.qlist(players)do
		if role(self,player)=="rebel" then
			eqs=eqs+#self.player:getEquips()
			if (player:getHandcardNum()<=2) or (player:getHp()<2) then
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
	local equips=self.player:getEquips()
	equips=sgs.QList2Table(equips)

	if #equips<2 then return {kind="pass"} end

	return answer(self,"dujiang","DujiangCard",{equips[1]:getKnownEffectiveId(),equips[2]:getKnownEffectiveId()},{},request)
end

sgs.ai_skill_invoke.xiansheng=function(self)
	local players=self.room:getOtherPlayers(self.player)

	local rebel=0
	for _,player in sgs.qlist(players)do
		if self:objectiveLevel(player)>=4 then
			rebel=rebel+1
		end
	end

	if rebel*2+3>(#self.player:getEquips()*2+self.player:getHandcardNum()) then return true end
	if self.player:getHp()==1 and self.player:getHandcardNum()<=1 then return true end
	return false
end

ai_skill_use["@@smalltuxi"] = function(self,prompt,request)
	self:sort(self.enemies, "handcard")

	local first_index
	for i = 1,#self.enemies do
		if self:hasSkills(sgs.need_kongcheng, self.enemies[i]) and self.enemies[i]:getHandcardNum()==1 then
		elseif not self.enemies[i]:isKongcheng() then
			first_index = i
			break
		end
	end

	local first = self.enemies[first_index]:objectName()
	return answer(self,"smalltuxi","SmallTuxiCard",{},{first},request)
end

sgs.ai_card_intention.SmallTuxiCard = 80

sgs.ai_skill_invoke.reselect = function(self)
	return math.random(0,2)==0
end
