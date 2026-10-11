-- Fixed boss-ai.lua donor b6025acc983331337614289d8cac79b078c003af.
-- Source policy order is preserved; submitted costs require native receipts.
local function known(value,label)
    if value==nil then ai_unsupported("boss requires "..label,"boss") end
    return value
end
local function q(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("boss requires "..method,"boss") end
    if method=="getMark" and type(object.getStrategyMark)=="function" then method="getStrategyMark" end
    if method=="hasFlag" and AIValue.isPlayer(object) and type(object.getStrategyFlag)=="function" then method="getStrategyFlag" end
    return known(object[method](object,...),method)
end
local function current(use,to)
    for _,p in ipairs(use.current_targets or{})do
        if p==q(to,"objectName")or AIValue.isPlayer(p)and AIValue.sameLegacyIdentity(p,to)then return true end
    end
    return false
end
local function can_to(self,card,to,prefix)
    return q(self,"cardTargetFilter",card,prefix or{},to)
end
local function boss_player_fact(self,player,key)
    local facts=self.world.strategy_facts
    local row=facts and facts.boss and facts.boss.players and facts.boss.players[q(player,"objectName")]
    local value=known(row and row[key],key)
    if key=="god_speel_count" and (type(value)~="number" or value<0 or value%1~=0)
        or key=="wanghun_active" and type(value)~="boolean" then ai_unsupported("invalid Boss public tag fact",key)end
    if row.status=="estimate"then
        if type(row.basis)~="string"then ai_unsupported("Boss tag estimate has no basis",key)end
        return self:useKnowledgeEstimate({value=value,status="estimate",basis=row.basis,observer=q(player,"objectName")},"boss."..key)
    end
    if row.status~="exact"then ai_unsupported("Boss tag knowledge status missing",key)end
    return value
end
local function dayuan_memory(self)
    local row,present=self:getStrategyMemory("boss.yl_dayuan")
    if not present or type(row)~="table"then ai_unsupported("Dayuan has no observed suit/number selection","yl_dayuan")end
    return row
end
sgs.ai_skill_playerchosen.bossdidong = function(self,targets)
	self:sort(self.enemies)
	for _,enemy in sgs.list(self.enemies)do
		if q(enemy,"faceUp") then return enemy end
	end
end

sgs.ai_skill_playerchosen.bossluolei = function(self,targets)
	self:sort(self.enemies)
	for _,enemy in sgs.list(self.enemies)do
		if q(self,"canAttack",enemy,self.player,sgs.DamageStruct_Thunder) then
			return enemy
		end
	end
end

sgs.ai_skill_playerchosen.bossguihuo = function(self,targets)
	self:sort(self.enemies)
	for _,enemy in sgs.list(self.enemies)do
		if q(self,"canAttack",enemy,self.player,sgs.DamageStruct_Fire)
        and (q(enemy,"hasArmorEffect","Vine") or q(enemy,"getMark","&kuangfeng")>0)
		then return enemy end
	end
	for _,enemy in sgs.list(self.enemies)do
		if q(self,"canAttack",enemy,self.player,sgs.DamageStruct_Fire)
		then return enemy end
	end
end

sgs.ai_skill_playerchosen.bossxiaoshou = function(self,targets)
	self:sort(self.enemies)
	for _,enemy in sgs.list(self.enemies)do
		if q(enemy,"getHp")>q(self.player,"getHp") and q(self,"canAttack",enemy,self.player) then
			return enemy
		end
	end
end

table.insert(sgs.ai_voluntary_give_skills,"god_edict")

table.insert(sgs.ai_voluntary_give_skills,"god_flower")


sgs.ai_armor_value.bossmanjia = function(player,self,card)
	if not card then return sgs.ai_armor_value.vine(player,self) end
end

sgs.ai_skill_invoke.bosslianyu = function(self,data)
	local value,avail = 0,0
	for _,enemy in sgs.list(self.enemies)do
		if not q(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire,self.player) then continue end
		avail = avail+1
		if q(self,"canAttack",enemy,self.player,sgs.DamageStruct_Fire) then
			value = value+1
			if q(enemy,"hasArmorEffect","Vine") or q(enemy,"getMark","&kuangfeng")>0 then
				value = value+1
			end
		end
	end
	return avail>0 and value/avail>=2/3
end

sgs.ai_skill_invoke.bosssuoming = function(self,data)
	local value = 0
	for _,enemy in sgs.list(self.enemies)do
		if q(self,"isGoodTarget",enemy,self.enemies) then
			value = value+1
		end
	end
	return value/#self.enemies>=2/3
end

sgs.ai_skill_playerchosen.bossxixing = function(self,targets)
	self:sort(self.enemies)
	for _,enemy in sgs.list(self.enemies)do
		if q(enemy,"isChained") and q(self,"canAttack",enemy,self.player,sgs.DamageStruct_Thunder) then
			return enemy
		end
	end
end

sgs.ai_skill_invoke.bossqiangzheng = function(self,data)
	local value = 0
	for _,enemy in sgs.list(self.enemies)do
		if q(enemy,"getHandcardNum")==1 and (q(enemy,"hasSkill","kongcheng") or (q(enemy,"hasSkill","zhiji") and q(enemy,"getMark","zhiji")==0)) then
			value = value+1
		end
	end
	return value/#self.enemies<2/3
end

sgs.ai_skill_invoke.bossqushou = function(self,data)
	local sa = q(self,"getEvaluationCard","savage_assault")
	local dummy_use = AIUsePlan.new();dummy_use.isDummy=true
	self:useTrickCard(sa,dummy_use)
	return (dummy_use.card~=nil)
end

sgs.ai_skill_invoke.bossmojian = function(self,data)
	local aa = q(self,"getEvaluationCard","archery_attack")
	local dummy_use = AIUsePlan.new();dummy_use.isDummy=true
	self:useTrickCard(aa,dummy_use)
	return (dummy_use.card~=nil)
end

sgs.ai_skill_invoke.bossdanshu = function(self,data)
	if not q(self.player,"isWounded") then return false end
	local zj = self.room:findPlayerBySkillName("guidao")
	if q(self.player,"getHp")/q(self.player,"getMaxHp")>=0.5 and zj and q(self,"isEnemy",zj) and self:canRetrial(zj) then return false end
	return true
end

sgs.ai_fill_skill.kuangxi=function(self,inclusive,request)
    if not q(self.player,"hasFlag","KuangxiEnterDying")then
        return q(self,"legacySkillSeed","kuangxi","KuangxiCard",request)
    end
end

sgs.ai_skill_use_func.KuangxiCard = function(card, use, self, request)
	self:sort(self.enemies, "hp")
	local can_invoke = false
	for _, friend in ipairs(self.friends) do
		if q(friend,"hasSkill","baoying") and q(friend,"getMark","@baoying") > 0 then
			can_invoke = true
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy) then
			if q(self.player,"getHp") >= q(enemy,"getHp") and (q(self.player,"getHp") > 1 or can_invoke) then
				use.card = q(self,"bindSkillCard","kuangxi",{},request,nil,"KuangxiCard")
				use.to:append(enemy)
				return
			end
		end
	end
end

sgs.ai_skill_invoke.baoying = function(self, data)
	local dying = q(data,"toDying")
	local peaches = 1 - q(dying.who,"getHp")
	return (peaches > 1  or q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") < peaches) and q(self,"isFriend",dying.who)
end

sgs.ai_use_value.KuangxiCard = 2.5
sgs.ai_card_intention.KuangxiCard = 80
sgs.dynamic_value.damage_card.KuangxiCard = true

sgs.ai_skill_askforyiji.huying = function(self,card_ids)
	return self.room:getLord(),card_ids[1]
end

function SmartAIView:useCardGodNihilo(card, use)
	if can_to(self,card,self.player) then
		local xiahou = self.room:findPlayerBySkillName("yanyu")
		if xiahou and q(self,"isEnemy",xiahou) and q(xiahou,"getMark","YanyuDiscard2") > 0 then return end
		if q(self.player,"getKingdom")=="god" then
		elseif q(self.player,"hasCard",card) then
			if q(self.player,"getHandcardNum")>math.min(5,q(self.player,"getMaxHp"))
			then return end
		elseif q(self.player,"getHandcardNum")>=math.min(5,q(self.player,"getMaxHp"))
		then return end
		use.card = card
		use.to:append(self.player)
		for _,p in sgs.list(self.friends_noself)do
			if can_to(self,card,p,use.to)
			and q(self,"canDraw",p) and q(p,"getHandcardNum")<math.min(5,q(p,"getMaxHp"))
			then use.to:append(p) end
		end
	end
end

sgs.ai_card_intention.GodNihilo = -80

sgs.ai_keep_value.GodNihilo = 5
sgs.ai_use_value.GodNihilo = 10
sgs.ai_use_priority.GodNihilo = 1

sgs.dynamic_value.benefit.GodNihilo = true

function SmartAIView:useCardGodFlower(card,use)
	local extraTarget = q(card,"getTargetModExtra",self.player)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	local function addTarget(to,ft)
		if current(use,to) then return end
		if not use.to:contains(to) and q(self,"doDisCard",to,ft,true,2) then
			use.card = card
			use.to:append(to)
			if use.to:length()>extraTarget then return true end
		end
	end
	local players = self:exclude(self.room:getOtherPlayers(self.player),card)
	local dummy = self:getCard("Slash")
	if dummy and q(dummy,"isAvailable",self.player) then
		dummy = self:aiUseCard(dummy)
		if dummy.card then
			for _,to in sgs.qlist(dummy.to)do
				if table.contains(players,to) and q(to,"getHp")<=2
				and q(to,"getHandcardNum")<=q(to,"getHp")
				and addTarget(to,"h") then return end
			end
		end
	end
	self:sort(players,"defense")
	for _,enemy in ipairs(players)do
		if q(enemy,"hasEquip") and addTarget(enemy,"he")
		then return end
	end
	for _,enemy in ipairs(players)do
		local n = 0
		for _,h in sgs.qlist(q(self,"getKnownCards",enemy,self.player,"h"))do
			if (q(h,"hasFlag","visible") or q(h,"hasFlag","visible_"..q(self.player,"objectName").."_"..q(enemy,"objectName")))
			and isCard("Peach,Analeptic",h,enemy) then
				n = n+1
				if n>=q(enemy,"getHandcardNum")/2 and addTarget(enemy,"h")
				then return end
			end
		end
	end
	for _,enemy in ipairs(players)do
		if q(enemy,"getHandcardNum")>0 and q(enemy,"hasSkills",sgs.cardneed_skill)
		and addTarget(enemy,"h")
		then return end
	end
	for _,enemy in ipairs(players)do
		if q(enemy,"getHandcardNum")>0 and q(self,"isEnemy",enemy)
		and addTarget(enemy,"h") then return end
	end
	for _,enemy in ipairs(players)do
		if q(enemy,"getHandcardNum")>0 and not q(self,"isFriend",enemy)
		and addTarget(enemy,"h") then return end
	end
	for _,enemy in ipairs(players)do
		if q(enemy,"getHandcardNum")>0
		and addTarget(enemy,"h") then return end
	end
end

sgs.ai_use_value.GodFlower = 9
sgs.ai_use_priority.GodFlower = 4.3
sgs.ai_keep_value.GodFlower = 3.46
sgs.dynamic_value.control_card.GodFlower = true

sgs.ai_use_value.GodBlade = 5
sgs.ai_use_priority.GodBlade = 3
sgs.ai_use_value.GodDiagram = 8
sgs.ai_use_priority.GodDiagram = 4
sgs.ai_use_value.GodQin = 2
sgs.ai_use_value.GodPao = 8
sgs.ai_use_priority.GodPao = 5
sgs.ai_use_value.GodHalberd = 8
sgs.ai_use_priority.GodHalberd = 5
sgs.ai_use_value.GodHat = 6
sgs.ai_use_value.GodSword = 9

sgs.ai_skill_invoke.god_double_sword = function(self,data)
	local target = data:toPlayer()
	if target then
		return not q(self,"isFriend",target)
	end
end
sgs.ai_use_value.GodDoubleSword = 4
sgs.ai_use_priority.GodDoubleSword = 3

sgs.ai_skill_playerchosen.god_bow = function(self,players)
    for _,target in sgs.list(players)do
		if q(self,"doDisCard",target,"he",false,2)
		then return target end
	end
end
sgs.ai_use_value.GodBow = 4.4
sgs.ai_use_priority.GodBow = 6.6

sgs.ai_skill_cardask["god_axe0"] = function(self,data)
    local use = q(data,"toCardUse")
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	local to = use.to:first()
	if #cards>2 and q(to,"getMark","god_axeArmorNullified-Clear")<1 and q(use.card,"isDamageCard")
	and (q(to,"getCardCount")>0 and q(self,"isWeak",to) or q(to,"getHandcardNum")>0 or q(to,"hasArmorEffect",nil))
	and q(self,"isEnemy",to) then
		local dc = {}
		for _,c in sgs.list(cards)do
			if q(c,"objectName")~="god_axe"
			then dc[#dc+1]=q(c,"getEffectiveId") end
			if  #dc>1
			then return "$"..table.concat(dc,"+") end
		end
	end
    return "."
end
sgs.ai_use_value.GodAxe = 5.4
sgs.ai_use_priority.GodAxe = 6.6
sgs.ai_use_revises.god_axe = function(self,card,use)
	if q(card,"isDamageCard") and use.to:length()==1 and q(self.player,"getCardCount")>3
	then self:setStrategyCardFlag(card,"Qinggang",true) end
end

sgs.ai_skill_invoke.god_edict = function(self,data)
	local target = data:toPlayer()
	if q(self,"isFriend",target) then
		return #q(self,"poisonCards","he",target)>0 or q(self,"isWeak",target)
	end
	return #q(self,"poisonCards","he",target)<1
end
sgs.ai_use_value.GodEdict = 3
sgs.ai_use_priority.GodEdict = 2

sgs.ai_skill_cardask["god_edict0"] = function(self,data)
	local target = data:toPlayer()
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	if q(self,"isFriend",target) then
		local pc = q(self,"poisonCards","e")
		if #pc>0 then return pc[1]:getId() end
		if #cards>q(target,"getCardCount") then
			for i,c in sgs.list(cards)do
				if i>#cards/2 and q(c,"objectName")~="god_edict"
				then return q(c,"getId") end
			end
		end
	else
		cards = q(self,"poisonCards","h")
		if #cards>0 then return cards[1]:getId() end
	end
    return "."
end

sgs.ai_skill_invoke.god_headdress = function(self,data)
	return q(self,"getOverflow")~=9
end
sgs.ai_use_value.GodEdict = 3
sgs.ai_use_priority.GodEdict = 2

sgs.ai_skill_cardask["god_headdress0"] = function(self,data)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	local n = q(self.player,"getMaxCards")
	if q(self.player,"hasSkill","shenfu")
  	then
		if q(self,"getOverflow")<0
		then
			if #cards%2==0
			then
				if #self.enemies>0
				then return "." end
			end
		elseif n%2==1
		then
			return "."
		else
			return cards[n]:getId()
		end
	end
	if q(self,"getOverflow")>0
	then
		n = n+1
		if q(self,"getKeepValue",cards[n])>6
		then return cards[n]:getId() end
	end
    return "."
end

sgs.ai_skill_invoke.GodDamage = function(self,data)
	local items = data:toString():split(":")
    local target = self.room:findPlayerByObjectName(items[2])
	if target and q(self,"isEnemy",target)
	then
		return q(target,"getLostHp")<1 or not q(self,"isWeak",target)
	end
end

function SmartAIView:useCardGodSpeel(card,use)
	self:sort(self.enemies,"skill",false)
	for _,ep in sgs.list(self.enemies)do
		if current(use,ep) then continue end
		if boss_player_fact(self,ep,"god_speel_count")<1
		and q(ep,"getVisibleSkillList"):length()>0
	   	and can_to(self,card,ep,use.to) then
	    	use.card = card
	    	use.to:append(ep)
		end
	end
end
sgs.ai_use_priority.GodSpeel = 5.4
sgs.ai_keep_value.GodSpeel = 4
sgs.ai_use_value.GodSpeel = 3.7

sgs.ai_nullification.GodSpeel = function(self,trick,from,to,positive)
    return q(self,"isFriend",to) and (q(to,"getHandcardNum")>3 or to==self.player)
	and positive
end

sgs.ai_card_intention.GodSpeel = 80

sgs.ai_ajustdamage_from.god_qin = function(self,from,to,card,nature)
	nature = "F"
end

sgs.ai_ajustdamage_from.god_deer = function(self,from,to,card,nature)
	if nature ~= "N" then
		return 1
	end
end

sgs.ai_target_revises.yl_remen = function(to,card)
    if q(to,"hasEquipArea") and to:getArmor()==nil then
		if q(card,"isKindOf","SavageAssault")
		or q(card,"isKindOf","ArcheryAttack")
		or q(card,"objectName")=="slash"
		then return true end
	end
end


sgs.ai_skill_playerchosen.god_ship = function(self,players)
    for _,target in sgs.list(players)do
		if q(self,"doDisCard",target,"ej",false)
		then return target end
	end
end


sgs.ai_skill_invoke.yl_shiyou = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_skill_invoke.yl_dayuan = function(self,data)
    local judge=q(data,"toJudge")
    local context=self:getDecisionContext()
    local outcomes=context.judge and context.judge.candidate_outcomes
    if type(outcomes)~="table"then ai_unsupported("Dayuan hypothetical judgement outcomes missing","yl_dayuan")end
    for suit=3,0,-1 do
        for number=13,1,-1 do
            self:setStrategyMemory("boss.yl_dayuan",{suit=suit,number=tostring(number)})
            local function good()
                local value=outcomes[tostring(suit)..":"..tostring(number)]
                if type(value)~="boolean"then ai_unsupported("Dayuan hypothetical judgement is unknown","yl_dayuan")end
                return value
            end
            if q(self,"isFriend",judge.who)and good()
                or q(self,"isEnemy",judge.who)and not good()then
                return self:needRetrial(judge)
            end
        end
    end
end
sgs.ai_skill_suit.yl_dayuan=function(self)return known(dayuan_memory(self).suit,"Dayuan saved suit")end
sgs.ai_skill_choice.yl_dayuan=function(self)return known(dayuan_memory(self).number,"Dayuan saved number")end

sgs.ai_fill_skill.yl_diting = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		if q(c,"isKindOf","Horse") and not q(self.player,"isCardLimited",c,sgs.Card_MethodRecast) then
			return q(self,"bindSkillCard","yl_diting",{q(c,"getId")},request,nil,"#yl_ditingCard")
		end
	end
end

sgs.ai_skill_use_func["#yl_ditingCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.yl_ditingCard = 3.4
sgs.ai_use_priority.yl_ditingCard = 9.2

function SmartAIView:useCardHuihun(card,use)
	for _,p in sgs.list(self.friends)do
		if boss_player_fact(self,p,"wanghun_active") then
	    	use.card = card
		end
	end
end
sgs.ai_use_priority.Huihun = 7.4
sgs.ai_keep_value.Huihun = 2
sgs.ai_use_value.Huihun = 3.7

sgs.ai_nullification.Huihun = function(self,trick,from,to,positive)
    return q(self,"isEnemy",to) and positive
end

sgs.ai_card_intention.Huihun = 80







