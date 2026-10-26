-- Source: b6025acc ai/standard_cards-ai.lua.
local known = AIValue.requireKnown
local query = AIValue.bindQuery {
    missing = function(method) ai_unsupported("standard equipment method is unavailable", method) end,
    known_nil = SmartAIView.isKnownNilStrategyResult,
    known = known,
}

local dummy = AIUsePlan.dummy
local function visible_card(self, id)
    local card = self:getChoiceCard(id)
    if card then return card end
    for _, player in ipairs(query(self.room,"getAllPlayers")) do
        for _, method in ipairs({"getKnownCards","getEquips","getJudgingArea"}) do
            for _, candidate in ipairs(query(player,method)) do
                if query(candidate,"getEffectiveId")==id then return candidate end
            end
        end
    end
    for _, candidate in ipairs(query(self.room,"getDiscardCards")) do
        if query(candidate,"getEffectiveId")==id then return candidate end
    end
    ai_unsupported("standard policy card identity is not disclosed",tostring(id))
end
local function extra_slash(self)
    -- AI_ExtraTargetSlash has no writer, so SmartAI always uses a fresh Slash.
    return query(self,"getEvaluationCard","slash")
end
-- Other ally-response sources retain their existing viewer-local caches.
local function response_source(self,key)
    local name, present = self:getStrategyMemory("response_source:"..key)
    if not present then return nil end
    if name==false or name==nil then return nil end
    if type(name)~="string" then ai_unsupported("invalid ally response source",key) end
    return known(self.room:findPlayerByObjectName(name,true),key)
end

local function spear_spec(skill, cards, count, name)
    local ids={};local red,black=true,true
    for i=1,count do
        local card=cards[i]
        ids[i]=query(card,"getEffectiveId")
        red=red and query(card,"isRed")
        black=black and query(card,"isBlack")
    end
    local suit=count==1 and query(cards[1],"getSuit") or count==0 and sgs.Card_NoSuit
        or red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
    return {name=name or "slash",skill=skill,suit=known(suit,"combined suit"),number=count==1 and query(cards[1],"getNumber") or 0,subcards=ids}
end

function cardsView_spear(self, player, skill, count, name)
    if player:objectName()~=self.player:objectName() then
        ai_unsupported("Spear cost selection requires its owning viewer","cardsView_spear")
    end
    local selected={}
    for _,card in ipairs(query(self,"addHandPile")) do
        if isCard("ExNihilo",card,player) and query(player,"getPhase")<=sgs.Player_Play
            or isCard("Peach",card,player) then continue end
        if isCard("Slash",card,player) then return nil end
        selected[#selected+1]=card
    end
    count=count or 2
    selected=query(self,"sortByKeepValue",selected,nil,true)
    if #selected>=count then return spear_spec(skill,selected,count,name) end
end

sgs.ai_cardsview.spear=function(self,class_name,player)
    if class_name=="Slash" then return cardsView_spear(self,player,"spear") end
end

function turnUse_spear(self,skill,request)
    local selected={}
    local cards=query(self,"sortByUseValue",query(self,"addHandPile"),nil,true)
    for _,card in ipairs(cards) do
        if isCard("Peach",card,self.player)
            or isCard("ExNihilo",card,self.player) and query(self.player,"getPhase")<=sgs.Player_Play then continue end
        selected[#selected+1]=card
    end
    if #selected<2 or #cards<query(self.player,"getHp") and query(self.player,"getHp")<5
        and not query(self,"needKongcheng") then return nil end
    local slashes,remaining={},{}
    for i,card in ipairs(selected) do remaining[i]=card end
    for _,first in ipairs(selected) do
        if #slashes>#selected/2 or #slashes>3 then break end
        for i,card in ipairs(remaining) do if card==first then table.remove(remaining,i);break end end
        for _,second in ipairs(remaining) do
            local spec=spear_spec(skill,{first,second},2)
            local slash
            if skill=="DIT_duoshi" then slash=self:evaluateTurnConversion(skill,"Slash",spec,request)
            else slash=self:bindTurnConversion(skill,"Slash",spec,request) end
            if query(slash,"isAvailable",self.player) then slashes[#slashes+1]=slash end
        end
    end
    return #slashes>0 and slashes or false
end

ai_fill_skill.spear=function(self, options, request)
    local inclusive = options and options.inclusive
 return turnUse_spear(self,"spear",request) end
sgs.ai_weapon_value.spear=function(self,enemy,player)
    if enemy and getCardsNum("Slash",player,self.player)==0 then
        if query(self,"getOverflow",player)>0 then return 2
        elseif query(player,"getHandcardNum")>2 then return 1 end
    end
    return 0
end
sgs.ai_slash_weaponfilter.fan=function(self,to,player)
    return query(player,"distanceTo",to)<=math.max(sgs.weapon_range.fan,query(player,"getAttackRange"))
        and query(to,"hasArmorEffect","Vine")
end
sgs.weapon_range.spear=3
sgs.ai_use_priority.spear=2.66

-- Standard card policy registrations; family planners remain in decision-core.
sgs.ai_target_revises.yizhong = function(to,card,self)
	if not to:getArmor() and query(card,"isBlack") and query(card,"isKindOf","Slash")
	then return true end
end


sgs.ai_target_revises.xiemu = function(to,card,self)
	if query(card,"isBlack") and query(card,"getTypeId")>0
	and query(to,"getStrategyMark","@xiemu_"..query(self.player,"getKingdom"))>0
	then return math.random()<0.7 end
end


sgs.ai_target_revises.renwang_shield = function(to,card,self)
	if query(card,"isBlack") and query(card,"isKindOf","Slash")
	then return true end
end


sgs.ai_target_revises.jianxiong = function(to,card,self)
	if query(card,"isDamageCard")
	and not query(self,"isFriend",to)
	and query(card,"subcardsLength")>0
	then
		for _,id in sgs.list(query(card,"getSubcards"))do
			if isCard("Peach,Analeptic",visible_card(self,id),to)
			then return true end
		end
	end
end


sgs.ai_target_revises.liuli = function(to,card,self,use)
	if query(card,"isKindOf","Slash")
	then
		for _,friend in sgs.list(self.friends_noself)do
			if query(self,"canLiuli",to,friend)
			and use.to:length()<2 and query(friend,"getHp")<3
			then return true end
		end
	end
end


sgs.ai_target_revises.xiangle = function(to,card,self,use)
	if query(card,"isKindOf","Slash")
	and query(self,"getCardsNum","BasicCard")-query(self,"getCardsNum","Peach")<2
	then return true end
end


sgs.ai_use_revises.qingnang = function(self,card,use)
	if query(card,"isKindOf","Slash") and query(self,"isWeak")
	and query(self,"getOverflow")<=0
	then return false end
end


sgs.ai_use_revises.keji = function(self,card,use)
	if query(card,"isKindOf","Slash") and not query(self,"hasCrossbowEffect")
	and (#self.enemies>1 or #self.friends>1) and query(self,"getOverflow")>1
	then return false end
end


sgs.ai_use_revises.yongsi = function(self,card,use)
	if query(card,"isKindOf","Peach")
	and query(self,"getCardsNum","Peach")>query(self,"getOverflow",nil,true)
	then use.card = card end
end


sgs.ai_use_revises.longhun = function(self,card,use)
	if query(card,"isKindOf","Peach") and not query(self.player,"isLord")
	and math.min(query(self.player,"getMaxCards"),query(self.player,"getHandcardNum"))+query(self.player,"getEquips"):length()>3
	then return false end
end


sgs.ai_use_revises.hunzi = function(self,card,use)
	if query(card,"isKindOf","Peach") and query(self.player,"isLord") and query(self.player,"getStrategyMark","hunzi")<1
	and query(self,"getCardsNum","Peach","h")<query(self.player,"getHp") and query(self.player,"getHp")<4
	then return false end
end


sgs.ai_use_revises.silver_lion = function(self,card,use)
	if query(card,"isKindOf","Peach")
	then
		for _,h in sgs.list(query(self.player,"getHandcards"))do
			if query(h,"isKindOf","Armor") and query(self,"evaluateArmor",h)>0
			then
				use.card = h
				return
			end
		end
	end
end


sgs.ai_use_revises.nosbuqu = function(self,card,use)
	if query(card,"isKindOf","Peach")
	and query(self.player,"getHp")<1 and query(self.player,"getMaxCards")<1
	then use.card = card end
end


sgs.ai_use_revises.kuanggu = function(self,card,use)
	if query(card,"isKindOf","Peach")
	and not self:hasJueqingEffect(self.player)
	and self.player:getOffensiveHorse()
	and query(self.player,"getLostHp")==1
	and query(self,"getOverflow")<1
	then return false end
end


sgs.ai_use_revises.jieyin = function(self,card,use)
	if query(card,"isKindOf","Peach")
	and query(self,"getOverflow")>0
	then
		for _,friend in sgs.list(self.friends)do
			if query(friend,"isWounded") and query(friend,"isMale")
			then return false end
		end
	end
end


function sgs.ai_slash_weaponfilter.double_sword(self,to,player)
	return query(player,"distanceTo",to)<=math.max(sgs.weapon_range.DoubleSword,query(player,"getAttackRange")) and query(player,"getGender")~=query(to,"getGender")
end


function sgs.ai_slash_weaponfilter.qinggang_sword(self,enemy,player)
	if query(player,"distanceTo",enemy)>math.max(sgs.weapon_range.QinggangSword,query(player,"getAttackRange")) then return end
	if query(enemy,"hasArmorEffect",nil)
	and getCardsNum("Jink",enemy,self.player)<1 then return true end
end


function sgs.ai_slash_weaponfilter.guding_blade(self,to)
	return query(to,"isKongcheng") and not query(to,"hasArmorEffect","SilverLion")
end


function sgs.ai_slash_weaponfilter.axe(self,to,player)
	return query(player,"distanceTo",to)<=math.max(sgs.weapon_range.Axe,query(player,"getAttackRange")) and query(self,"getOverflow",player)>0
end


function sgs.ai_slash_weaponfilter.kylin_bow(self,to,player)
	return query(player,"distanceTo",to)<=math.max(sgs.weapon_range.KylinBow,query(player,"getAttackRange"))
		and (to:getDefensiveHorse() or to:getOffensiveHorse())
end


function sgs.ai_weapon_value.double_sword(self,enemy,player)
	if enemy and query(enemy,"isMale")~=query(player,"isMale") then return 4 end
end


function sgs.ai_weapon_value.qinggang_sword(self,enemy)
	if enemy and query(enemy,"hasArmorEffect",nil) then return 3 end
end


function sgs.ai_weapon_value.guding_blade(self,enemy)
	if not enemy then return end
	local value = 2
	if query(enemy,"getHandcardNum")<1 and not query(enemy,"hasArmorEffect","SilverLion") then value = 4 end
	return value
end


function sgs.ai_weapon_value.axe(self,enemy,player)
	if query(player,"hasSkills","jiushi|jiuchi|luoyi|pojun") then return 6 end
	if enemy and query(self,"getOverflow")>0 then return 3.1 end
	if enemy and query(enemy,"getHp")<3 then return 3-query(enemy,"getHp") end
end


function sgs.ai_weapon_value.blade(self,enemy)
	if not enemy and not query(self.player,"hasWeapon","Axe") then return math.min(query(self,"getCardsNum","Slash"),3) end
end


function sgs.ai_weapon_value.kylin_bow(self,enemy)
	if enemy and (enemy:getOffensiveHorse() or enemy:getDefensiveHorse()) then return 1 end
end


function sgs.ai_armor_value.eight_diagram(player,self)
	if query(self,"hasSkills","guidao",query(self,"getEnemies",player)) then return 2 end
	if query(player,"hasSkills","tiandu|leiji|nosleiji|noszhenlie|gushou")
	then return 6 end
	if self.role=="loyalist" and query(self.player,"getKingdom")=="wei"
	and getLord(self.player):hasLordSkill("hujia")
	and not query(self.player,"hasSkill","bazhen")
	then return 5 end
	return 4
end


function sgs.ai_armor_value.renwang_shield(player,self)
	if query(player,"hasSkill","yizhong") then return 0 end
	if query(player,"hasSkill","bazhen") then return 0 end
	if query(player,"hasSkills","leiji|nosleiji")
	and getKnownCard(player,self.player,"Jink",true)>1 and query(player,"hasSkill","guidao")
	and getKnownCard(player,self.player,"black",false,"he")>0
	then return 0 end
	return 4.5
end


function sgs.ai_armor_value.silver_lion(player,self)
	if query(self,"hasWizard",query(self,"getEnemies",player),true) then
		for _,p in sgs.list(query(self.room,"getAlivePlayers"))do
			if p:containsTrick("lightning") then return 5 end
		end
	end
	if query(player,"isWounded") and not player:getArmor() then return 9 end
	if query(player,"isWounded") and getKnownCard(player,self.player,"Armor",false,"h")>1
	and not query(player,"hasArmorEffect","SilverLion") then return 8 end
	return 1
end


ai_skill_invoke.double_sword = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (not query(self,"needKongcheng",self.player,true)) or false
end


ai_skill_invoke.ice_sword = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = known(data:toDamage(), "decision damage")
	local target = damage.to
	if query(self,"isFriend",target) then
		if query(self,"needToLoseHp",target,self.player,damage.card) then return (false) or false
		elseif target:isChained() and query(self,"isGoodChainTarget",target,damage.card) then return (false) or false
		elseif query(self,"isWeak",target) or damage.damage>1 then return (true) or false
		elseif query(target,"getLostHp")<1 then return (false) or false end
		return (true) or false
	else
		if query(self,"isWeak",target) then return (false) or false end
		if damage.damage>1 or query(self,"ajustDamage",self.player,target,1,damage.card)>1 then return (false) or false end
		if query(target,"hasSkill","lirang") and #query(self,"getFriends",target,true)>0 then return (false) or false end
		if target:getArmor() and query(self,"evaluateArmor",target:getArmor(),target)>3 and not (query(target,"hasArmorEffect","SilverLion") and query(target,"isWounded")) then return (true) or false end
		local num = query(target,"getHandcardNum")
		if query(self.player,"hasSkill","tieji") or query(self,"canLiegong",target,self.player) then return (false) or false end
		if hasTuntianEffect(target, true) and query(target,"getPhase")==sgs.Player_NotActive then return (false) or false end
		if query(self,"hasSkills",sgs.need_kongcheng,target) then return (false) or false end
		if (query(target,"getHandcardNum")+query(target,"getEquips"):length())<4 and (query(target,"getHandcardNum")+query(target,"getEquips"):length())>1 then return (true) or false end
		return (false) or false
	end
	return false

end


ai_skill_invoke.kylin_bow = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = known(data:toDamage(), "decision damage")
	if query(damage.from,"hasSkill","kuangfu") and query(damage.to,"getCards","e"):length()==1 then return (false) or false end
	if query(self,"hasSkills",sgs.lose_equip_skill,damage.to) then
		return (query(self,"isFriend",damage.to)) or false
	end
	return (query(self,"isEnemy",damage.to)) or false
end


function sgs.isJinkAvailable(from,to,slash,judge_considered)
	return not judge_considered and query(from,"hasSkills","tieji|nostieji")
	or query(from,"hasSkill","liegong") and query(from,"getPhase")==sgs.Player_Play and (query(to,"getHandcardNum")<=query(from,"getAttackRange") or query(to,"getHandcardNum")>=query(from,"getHp"))
	or query(from,"hasSkill","kofliegong") and query(from,"getPhase")==sgs.Player_Play and query(to,"getHandcardNum")>=query(from,"getHp")
	or query(from,"getStrategyFlag","ZhaxiangInvoked") and slash and query(slash,"isRed")
end


function SmartAIView:findWeaponToUse(enemy)
	local wv,w = {},self.player:getWeapon()
	for _,c in sgs.list(self:addHandPile())do
		if query(c,"isKindOf","Weapon") and self:aiUseCard(c).card
		then wv[c] = query(self,"evaluateWeapon",c,self.player,enemy) end
	end
	if #wv<1 then return end
	if w then wv[w] = query(self,"evaluateWeapon",w,self.player,enemy) end
	local max_value,max_card = -100,nil
	for c,v in pairs(wv)do
		if v>max_value then max_card = c max_value = v end
	end
	if w and query(w,"getId")==query(max_card,"getId")
	then else return max_card end
end


function SmartAIView:needToThrowAll(player)
	player = player or self.player
	if query(player,"hasSkill","conghui") then return false end
	if not query(player,"hasSkill","yongsi") then return false end
	if query(player,"getPhase")==sgs.Player_NotActive or query(player,"getPhase")==sgs.Player_Finish then return false end
	local zhanglu = self.room:findPlayerBySkillName("xiliang")
	if zhanglu and query(self,"isFriend",zhanglu,player) then return false end
	local erzhang = self.room:findPlayerBySkillName("guzheng")
	if erzhang and not zhanglu and query(self,"isFriend",erzhang,player) then return false end
	self.yongsi_discard = nil
	local index = 0
	local kingdom_num = 0
	local kingdoms = {}
	for _,ap in sgs.list(query(self.room,"getAlivePlayers"))do
		if not kingdoms[query(ap,"getKingdom")] then
			kingdoms[query(ap,"getKingdom")] = true
			kingdom_num = kingdom_num+1
		end
	end
	local cards = query(self.player,"getCards","he")
	local Discards = {}
	for _,card in sgs.list(cards)do
		local shouldDiscard = true
		if query(card,"isKindOf","Axe") then shouldDiscard = false end
		if isCard("Peach",card,player) or isCard("Slash",card,player) then
			local dummy_use = dummy()
			self:useBasicCard(card,dummy_use)
			if dummy_use.card then shouldDiscard = false end
		end
		if query(card,"getTypeId")==sgs.Card_TypeTrick then
			local dummy_use = dummy()
			self:useTrickCard(card,dummy_use)
			if dummy_use.card then shouldDiscard = false end
		end
		if shouldDiscard then
			if #Discards<2 then table.insert(Discards,query(card,"getEffectiveId")) end
			index = index+1
		end
	end
	if #Discards==2 and index<kingdom_num then
		self.yongsi_discard = Discards
		return true
	end
	return false
end


sgs.ai_skill_playerchosen.collateral = function(self,players)
	local destlist = self:sort(players)
    for _,target in sgs.list(destlist)do
		if query(self,"isEnemy",target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not query(self,"isFriend",target)
		then return target end
	end
	return destlist[#destlist]
end


sgs.ai_card_intention.GodSalvation = function(self,card,from,tos)
	local can,first
	for _,to in sgs.list(tos)do
		if query(to,"isWounded") and not first then first = to can = true
		elseif first and query(to,"isWounded") and not query(self,"isFriend",first,to)
		then can = false break end
	end
	if can then
		sgs.updateIntention(from,first,-10)
	end
end


sgs.dynamic_value.damage_card.Slash = true
sgs.ai_use_value.Slash = 4.5
sgs.ai_keep_value.Slash = 3.6
sgs.ai_use_priority.Slash = 2.6
sgs.ai_use_value.Peach = 6
sgs.ai_keep_value.Peach = 7
sgs.ai_use_priority.Peach = 0.9
sgs.ai_use_value.Jink = 8.9
sgs.ai_keep_value.Jink = 5.2
sgs.dynamic_value.benefit.Peach = true
sgs.ai_keep_value.Weapon = 2.08
sgs.ai_keep_value.Armor = 2.06
sgs.ai_keep_value.Horse = 2.04
sgs.weapon_range.Weapon = 1
sgs.weapon_range.Crossbow = 1
sgs.weapon_range.DoubleSword = 2
sgs.weapon_range.QinggangSword = 2
sgs.weapon_range.IceSword = 2
sgs.weapon_range.GudingBlade = 2
sgs.weapon_range.Axe = 3
sgs.weapon_range.Blade = 3
sgs.weapon_range.spear = 3
sgs.weapon_range.Halberd = 4
sgs.weapon_range.KylinBow = 5
sgs.ai_use_priority.OffensiveHorse = 2.69
sgs.ai_use_priority.Axe = 2.688
sgs.ai_use_priority.Halberd = 2.685
sgs.ai_use_priority.KylinBow = 2.68
sgs.ai_use_priority.Blade = 2.675
sgs.ai_use_priority.GudingBlade = 2.67
sgs.ai_use_priority.DoubleSword =2.665
sgs.ai_use_priority.spear = 2.66
sgs.ai_use_priority.IceSword = 2.65
sgs.ai_use_priority.QinggangSword = 2.645
sgs.ai_use_priority.Crossbow = 2.63
sgs.ai_use_priority.SilverLion = 1.0
sgs.ai_use_priority.EightDiagram = 0.8
sgs.ai_use_priority.RenwangShield = 0.85
sgs.ai_use_priority.DefensiveHorse = 2.75
sgs.dynamic_value.damage_card.ArcheryAttack = true
sgs.dynamic_value.damage_card.SavageAssault = true
sgs.ai_use_value.ArcheryAttack = 3.8
sgs.ai_use_priority.ArcheryAttack = 3.5
sgs.ai_keep_value.ArcheryAttack = 3.38
sgs.ai_use_value.SavageAssault = 3.9
sgs.ai_use_priority.SavageAssault = 3.5
sgs.ai_keep_value.SavageAssault = 3.36
sgs.ai_keep_value.Nullification = 3.8
sgs.ai_use_value.Nullification = 8
sgs.ai_use_value.AmazingGrace = 3
sgs.ai_keep_value.AmazingGrace = -1
sgs.ai_use_priority.AmazingGrace = 1.2
sgs.dynamic_value.benefit.AmazingGrace = true
sgs.ai_use_priority.GodSalvation = 4.1
sgs.ai_keep_value.GodSalvation = 3.32
sgs.dynamic_value.benefit.GodSalvation = true
sgs.ai_use_value.Duel = 3.7
sgs.ai_use_priority.Duel = 2.9
sgs.ai_keep_value.Duel = 3.42
sgs.dynamic_value.damage_card.Duel = true
sgs.ai_card_intention.ExNihilo = -80
sgs.ai_keep_value.ExNihilo = 3.9
sgs.ai_use_value.ExNihilo = 9
sgs.ai_use_priority.ExNihilo = 9.3
sgs.dynamic_value.benefit.ExNihilo = true
sgs.ai_use_value.Snatch = 9
sgs.ai_use_priority.Snatch = 9.3
sgs.ai_keep_value.Snatch = 3.46
sgs.dynamic_value.control_card.Snatch = true
sgs.ai_use_value.Dismantlement = 5.6
sgs.ai_use_priority.Dismantlement = 9.4
sgs.ai_keep_value.Dismantlement = 3.44
sgs.dynamic_value.control_card.Dismantlement = true
sgs.ai_use_value.Collateral = 5.8
sgs.ai_use_priority.Collateral = 2.75
sgs.ai_keep_value.Collateral = 3.40
sgs.dynamic_value.control_card.Collateral = true
sgs.ai_use_value.Indulgence = 8
sgs.ai_use_priority.Indulgence = 0.5
sgs.ai_card_intention.Indulgence = 120
sgs.ai_keep_value.Indulgence = 3.5
sgs.dynamic_value.control_usecard.Indulgence = true
sgs.ai_use_priority.Lightning = 0
sgs.dynamic_value.lucky_chance.Lightning = true
sgs.ai_keep_value.Lightning = -1
sgs.ai_playerchosen_intention.wooden_ox = -22
sgs.ai_use_priority.WoodenOxCard = 0


sgs.ai_skill_cardask["double-sword-card"] = function(self,data,pattern,target)
	if query(self.player,"isKongcheng") then return "." end
	local use = known(data:toCardUse(),"decision use")
	local jink_num = query(self,"getExpectedJinkNum",use)
	if jink_num>1 and query(self,"getCardsNum","Jink")==jink_num then return "." end

	if query(self,"needKongcheng",self.player,true) and query(self.player,"getHandcardNum")<=2 then
		if query(self.player,"getHandcardNum")==1 then
			local card = query(self.player,"getHandcards"):first()
			return (jink_num>0 and isCard("Jink",card,self.player)) and "." or ("$"..query(card,"getEffectiveId"))
		end
		if query(self.player,"getHandcardNum")==2 then
			local first = query(self.player,"getHandcards"):first()
			local last = query(self.player,"getHandcards"):last()
			local jink = isCard("Jink",first,self.player) and first or (isCard("Jink",last,self.player) and last)
			if jink then
				return query(first,"getEffectiveId")==query(jink,"getEffectiveId") and ("$"..query(last,"getEffectiveId")) or ("$"..query(first,"getEffectiveId"))
			end
		end
	end
	if target and query(self,"isFriend",target) then return "." end
	if query(self,"needBear") then return "." end
	if target and query(self,"needKongcheng",target,true) then return "." end
	local cards = query(self.player,"getHandcards")
	for _,card in sgs.list(cards)do
		if (query(card,"isKindOf","Slash") and query(self,"getCardsNum","Slash")>1)
			or (query(card,"isKindOf","Jink") and query(self,"getCardsNum","Jink")>2)
			or query(card,"isKindOf","Disaster")
			or (query(card,"isKindOf","EquipCard") and not query(self,"hasSkills",sgs.lose_equip_skill))
			or (not query(self.player,"hasSkills","nosjizhi|jizhi") and (query(card,"isKindOf","Collateral") or query(card,"isKindOf","GodSalvation")
			or query(card,"isKindOf","FireAttack") or query(card,"isKindOf","IronChain") or query(card,"isKindOf","AmazingGrace"))) then
			return "$"..query(card,"getEffectiveId")
		end
	end
	return "."
end


sgs.ai_skill_cardask["blade-slash"] = function(self,data,pattern,target)
	if target and query(self,"isFriend",target)
	and not self:findLeijiTarget(target,50,self.player)
	then return "." end
	for _,slash in sgs.list(query(self,"getCards","Slash"))do
		if query(self,"slashIsEffective",slash,target) and (query(self,"isWeak",target) or query(self,"getOverflow")>0)
		then return slash end
	end
	return "."
end


sgs.ai_skill_cardask.aoe = function(self,data,pattern,target,name)
	if query(self.room,"getMode"):find("_mini_35") and query(self.player,"getLostHp")==1 and name=="archery_attack"
	or self:standardNullFilter(data,pattern,target)=="."
	then return "." end
    local aoe = query(self,"getEvaluationCard",name)
    -- Legacy QVariant userdata becomes a typed data proxy; numeric Aocai data
    -- is not a CardEffect and must retain the freshly cloned dummy AOE.
    if (type(data)=="table"or type(data)=="userdata")and type(data.toCardEffect)=="function"then
        aoe = data:toCardEffect().card
    end
	local menghuo = self.room:findPlayerBySkillName("huoshou")
	if menghuo and query(aoe,"isKindOf","SavageAssault") then target = menghuo end
	if query(self,"ajustDamage",target,self.player,1,aoe)==0
	or query(self.player,"hasSkill","wuyan") and not query(target,"hasSkill","jueqing")
	or query(target,"hasSkill","wuyan") and not query(target,"hasSkill","jueqing")
	or query(self.player,"getStrategyMark","@fenyong")>0 and not query(target,"hasSkill","jueqing")
	or query(self,"needToLoseHp",self.player,target,aoe)
	then return "." end
	if not query(target,"hasSkill","jueqing") and query(self.player,"hasSkill","jianxiong")
	and not query(self,"isWeak") and not query(self,"needKongcheng",self.player,true)
	and not query(self,"willSkipPlayPhase") then
		if query(self,"getAoeValue",aoe)>-10 then return "." end
		if query(aoe,"isVirtualCard") then
			if query(aoe,"subcardsLength")>2 then self.jianxiong = true self:setStrategyMemory("jianxiong",true) return "." end
			for _,id in sgs.list(query(aoe,"getSubcards"))do
				if isCard("Peach",visible_card(self,id),self.player)
				then return "." end
			end
		end
	end
	local current = self.room:getCurrent()
	if current and query(current,"hasSkill","juece")
	and query(self,"isEnemy",current) and query(self.player,"getHp")>0 then
		for _,c in sgs.list(query(self,"getCards",name=="savage_assault" and "Slash" or "Jink"))do
			if query(self.player,"isLastHandCard",c,true) then continue end
			return
		end
		return "."
	end
end


sgs.ai_skill_cardask["savage-assault-slash"] = function(self,data,pattern,target)
	return sgs.ai_skill_cardask.aoe(self,data,pattern,target,"savage_assault")
end


sgs.ai_skill_cardask["archery-attack-jink"] = function(self,data,pattern,target)
	return sgs.ai_skill_cardask.aoe(self,data,pattern,target,"archery_attack")
end


function SmartAIView:selectDuelSlash(options, request, target, card)
    if not target then ai_unsupported("Duel response source is unknown", "duel-slash") end
	local function no_damage()
		local effect = self:getDecisionContext().effect
		local duel = known(card or effect and effect.card, "current Duel response card")
		return query(self,"ajustDamage",target,self.player,1,duel) == 0
	end
	local function relation(expected)
		local value = known(self:relationTo(target), "Duel source relation")
		if value == "unknown" then ai_unsupported("Duel source relation is unknown", "duel-slash") end
		return value == expected
	end
	local function has_other_friend()
		for _, friend in ipairs(query(self,"getFriends")) do if friend ~= self.player then return true end end
		return false
	end
	if query(self.player,"getStrategyFlag","AIGlobal_NeedToWake") and query(self.player,"getHp")>1
	or no_damage()
	or query(self.player,"hasSkill","wuhun") and relation("enemy") and query(target,"isLord") and has_other_friend()
	or query(target,"hasSkill","wushuang") and not query(self.player,"getStrategyFlag","wushuangSlash") and query(self,"getCardsNum","Slash")<2
	or query(target,"hasSkill","mobilemouwushuang") and not query(self.player,"getStrategyFlag","mobilemouwushuangSlash") and query(self,"getCardsNum","Slash")<2
	or query(target,"hasSkill","sfofl_wushuang") and not query(self.player,"getStrategyFlag","sfofl_wushuangSlash") and query(self,"getCardsNum","Slash")<2
	or query(target,"hasSkill","rushB_wushuang") and not query(self.player,"getStrategyFlag","rushB_wushuangSlash") and query(self,"getCardsNum","Slash")<2
	or query(target,"hasSkill","tc_wuqian") and not query(self.player,"getStrategyFlag","tc_wuqianSlash") and query(self,"getCardsNum","Slash")<2
	or relation("friend") and query(target,"hasSkill","rende") and query(self.player,"hasSkill","jieming")
	or relation("enemy") and not query(self,"isWeak") and query(self,"needToLoseHp",self.player,target)
	or query(self.player,"getStrategyMark","@fenyong")>0 and not query(self,"hasJueqingEffect",target,self.player)
	or self:shouldDeclineCardResponse(options, request)
	or query(self,"cantbeHurt",target)
	then return "." end

	if relation("friend") then
		if target:objectName()==self.player:objectName()
		or query(self,"needToLoseHp",self.player,target)
		then return "." end
		if query(self,"needToLoseHp",target,self.player)
		or query(target,"isLord") and not query(self,"isLordInDanger") and not query(self,"isGoodHp")
		or query(self.player,"isLord") and query(self,"isLordInDanger")
		then return self:getCard("Slash") end
	elseif query(self,"getCardsNum","Slash")>=getCardsNum("Slash",target,self.player)
	or query(self,"isWeak") then return self:getCard("Slash") end
	return "."
end

ai_skill_cardask["duel-slash"] = function(self, options, request)
    local effect = options.context and options.context.effect
    local opponent = (request.prompt or ""):match("^duel%-slash:([^:]+)")
    if type(effect) ~= "table" or not opponent then
        ai_unsupported("current Duel effect or opponent is not projected", "duel-slash")
    end
    -- Duel alternates responders; effect.from remains the original initiator.
    local target = self.room:findPlayerByObjectName(opponent, true)
    return self:cardResponseAnswer(self:selectDuelSlash(options, request, target), options)
end

-- Other packages still call this positional hook directly; the native Duel
-- inquiry above always enters the pure-value registry.
sgs.ai_skill_cardask["duel-slash"] = function(self, data, pattern, target)
    local effect = data and data:toCardEffect()
    return self:selectDuelSlash(self.request.options or {}, self.request, target, effect and effect.card)
end


function SmartAIView:getHujiaRequester(data)
    if not data then return nil end
    local asked=data:toStringList()
    if not AIValue.isList(asked) then ai_unsupported("CardAsked fields are unavailable","getHujiaRequester") end
    if asked[1]~="jink" or type(asked[2])~="string" then return nil end
    local name=asked[2]:match("^@hujia%-jink:([^:]+)")
    -- Resolve only this request's public player name; never retain it in memory.
    return name and self.room:findPlayerByObjectName(name,false) or nil
end

ai_skill_invoke.eight_diagram = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local lianlisource,SevenJiujia,tongpaoJink,tongpao = response_source(self,"lianlisource"),response_source(self,"SevenJiujia"),response_source(self,"tongpaoJink"),response_source(self,"tongpao")
	local dying = 0
	local handang = self.room:findPlayerBySkillName("nosjiefan")
	for _,aplayer in sgs.list(query(self.room,"getAlivePlayers"))do
		if query(aplayer,"getHp")<1 and not query(aplayer,"hasSkill","nosbuqu") then dying = 1 break end
	end
	if handang and query(self,"isFriend",handang) and dying>0 then return (false) or false end

	local heart_jink = false
	for _,card in sgs.list(query(self.player,"getCards","he"))do
		if query(card,"getSuit")==sgs.Card_Heart and isCard("Jink",card,self.player) then
			heart_jink = true
			break
		end
	end

	local hujia_requester=self:getHujiaRequester(data)
	if query(self,"hasSkills","tiandu|leiji|nosleiji|gushou") then
		if query(self.player,"getStrategyFlag","dahe") and not heart_jink then return (true) or false end
		if hujia_requester and not query(self,"isFriend",hujia_requester) and (query(hujia_requester,"getStrategyFlag","dahe") or query(self.player,"getStrategyFlag","dahe")) then return (true) or false end
		if lianlisource and not query(self,"isFriend",lianlisource) and (query(lianlisource,"getStrategyFlag","dahe") or query(self.player,"getStrategyFlag","dahe")) then return (true) or false end
		if query(self.player,"getStrategyFlag","dahe") and handang and query(self,"isFriend",handang) and dying>0 then return (true) or false end
	end
	if query(self.player,"getHandcardNum")==1 and query(self,"getCardsNum","Jink")==1 and query(self.player,"hasSkills","zhiji|beifa") and query(self,"needKongcheng") then
		local enemy_num = query(self,"getEnemyNumBySeat",self.room:getCurrent(),self.player,self.player)
		if query(self.player,"getHp")>enemy_num and enemy_num<=1 then return (false) or false end
	end
	if handang and query(self,"isFriend",handang) and dying>0 then return (false) or false end
	if query(self.player,"getStrategyFlag","dahe") then return (false) or false end
	if hujia_requester and (not query(self,"isFriend",hujia_requester) or query(hujia_requester,"getStrategyFlag","dahe")) then return (false) or false end
	if lianlisource and (not query(self,"isFriend",lianlisource) or query(lianlisource,"getStrategyFlag","dahe")) then return (false) or false end
	if SevenJiujia and (not query(self,"isFriend",SevenJiujia) or query(SevenJiujia,"getStrategyFlag","dahe")) then return (false) or false end
	if tongpaoJink and (not query(self,"isFriend",tongpaoJink) or query(tongpaoJink,"getStrategyFlag","dahe")) then return (false) or false end
	if tongpao and (not query(self,"isFriend",tongpao) or query(tongpao,"getStrategyFlag","dahe")) then return (false) or false end
	if query(self,"needToLoseHp",self.player,nil,query(self,"getEvaluationCard","slash"),true) then return (false) or false end
	if query(self,"getCardsNum","Jink")==0 then return (true) or false end
	local zhangjiao = self.room:findPlayerBySkillName("guidao")
	if zhangjiao and query(self,"isEnemy",zhangjiao) then
		if getKnownCard(zhangjiao,self.player,"black",false,"he")>1 then return (false) or false end
		if query(self,"getCardsNum","Jink")>1 and getKnownCard(zhangjiao,self.player,"black",false,"he")>0 then return (false) or false end
	end
	if query(self,"getCardsNum","Jink")>0 and query(self.player,"getPile","incantation"):length()>0 then return (false) or false end
	return (true) or false
end


sgs.ai_skill_playerchosen.slash_extra_targets = function(self,targets)
	local slash = extra_slash(self)
	targets = sgs.QList2Table(targets)
	targets = query(self,"sort",targets,"defenseSlash")
	for _,target in sgs.list(targets)do
		if query(self,"isEnemy",target)
		and not query(self,"slashProhibit",slash,target)
		and query(self,"isGoodTarget",target,targets,slash)
		and query(self,"slashIsEffective",slash,target)
		then return target end
	end
	return nil
end


sgs.ai_skill_playerschosen.slash_extra_targets = function(self,targets,x,n)
	local slash = extra_slash(self)
	targets = sgs.QList2Table(targets)
	targets = query(self,"sort",targets,"defenseSlash")
	local tos = {}
	for _,target in sgs.list(targets)do
		if #tos<x and query(self,"isEnemy",target)
		and not query(self,"slashProhibit",slash,target)
		and query(self,"isGoodTarget",target,targets,slash)
		and query(self,"slashIsEffective",slash,target)
		then table.insert(tos,target) end
	end
	return tos
end


sgs.ai_skill_playerchosen.zero_card_as_slash = function(self,targets)
	local slash = extra_slash(self)
	local targetlist = sgs.QList2Table(targets)
	local function finalChecking(player)
		local use = dummy()
		use.card = query(self,"getEvaluationCard","slash")
		use.to:append(player)
		self:targetRevises(use)
		if use.card and not use.isDummy then
			return player
		end
		return false
	end


	local arrBestHp,canAvoidSlash,forbidden = {},{},{}
	targetlist = query(self,"sort",targetlist,"defenseSlash")
	for _,target in sgs.list(targetlist)do
		if query(self,"isEnemy",target)
		and not query(self,"slashProhibit",slash,target)
		and query(self,"isGoodTarget",target,targetlist,slash) then
			if query(self,"slashIsEffective",slash,target) then
				if query(self,"needToLoseHp",target,self.player,slash)
				or query(self,"needLeiji",target,self.player)
				then table.insert(forbidden,target)
				elseif query(self,"needToLoseHp",target,self.player,slash,true)
				then table.insert(arrBestHp,target)
				else if finalChecking(target) then return target end end
			else
				table.insert(canAvoidSlash,target)
			end
		end
	end
	targetlist = sgs.reverse(targetlist)
	for _,target in sgs.list(targetlist)do
		if not query(self,"slashProhibit",slash,target) then
			if query(self,"slashIsEffective",slash,target) then
				if query(self,"isFriend",target)
				and (query(self,"needToLoseHp",target,self.player,slash,true) or query(self,"needLeiji",target,self.player))
				then if finalChecking(target) then return target end end
			else
				table.insert(canAvoidSlash,target)
			end
		end
	end
	if #canAvoidSlash>0 then return canAvoidSlash[1] end
	if #arrBestHp>0 then if finalChecking(arrBestHp[1]) then return arrBestHp[1] end end
	for _,target in sgs.list(targetlist)do
		if target:objectName()~=self.player:objectName()
		and not query(self,"isFriend",target) and not table.contains(forbidden,target)
		then if finalChecking(target) then return target end end
	end
	return targetlist[1]
end


local function standard_skill_card(self,skill,class,costs,request)
    local authority=query(self,"bindSkillCard",skill,costs,request)
    local suit,number=sgs.Card_NoSuit,0
    if #costs==1 then
        local card=visible_card(self,costs[1])
        suit,number=query(card,"getSuit"),query(card,"getNumber")
    elseif #costs>1 then
        local red,black=true,true
        for _,id in ipairs(costs) do
            local card=visible_card(self,id)
            red,black=red and query(card,"isRed"),black and query(card,"isBlack")
        end
        suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
    end
    local suits={[sgs.Card_Spade]="spade",[sgs.Card_Club]="club",[sgs.Card_Heart]="heart",
        [sgs.Card_Diamond]="diamond",[sgs.Card_NoSuitBlack]="no_suit_black",[sgs.Card_NoSuitRed]="no_suit_red",[sgs.Card_NoSuit]="no_suit"}
    local rank=number>13 and "JOKER" or ({[1]="A",[11]="J",[12]="Q",[13]="K"})[number] or tostring(number)
    local serialized="@"..class.."["..known(suits[suit],"skill-card suit")..":"..rank.."]="..(#costs>0 and table.concat(costs,"+") or ".")
    return query(self,"legacyPolicyCard",authority,{name="",class_name=class,type_id=0,
        kind_of={class,"SkillCard","Card"},legacy_string_key=serialized,subcards=costs,suit=suit,number=number,
        effective_id=costs[1],damage_card=false,can_recast=false,
        handling_method=class=="WoodenOxCard" and sgs.Card_MethodNone or sgs.Card_MethodDiscard,
        will_throw=class~="WoodenOxCard"})
end

sgs.ai_used_revises.jilve = function(self,use)
    if query(use.card,"isKindOf","Slash") and query(self.player,"getStrategyMark","&bear")>0
        and not query(self.player,"getStrategyFlag","JilveWansha") and not use.isDummy then
        for _,to in ipairs(use.to) do
            if query(self,"isEnemy",to) and query(to,"getHp")<2 and not query(self.player,"hasSkill","wansha")
                and getCardsNum("Jink",to,self.player)<1 then
                use.card=standard_skill_card(self,"jilve","JilveCard",{})
                self:setStrategyMemory("choice_override:jilve","wansha")
                use.to=AIList.new({})
                return false
            end
        end
    end
end
sgs.ai_used_revises.duyi = function(self,use)
    if query(use.card,"isDamageCard") and known(self.world.draw_pile_count,"draw pile count")>0
        and not query(self.player,"hasUsed","DuyiCard") and not use.isDummy then
        for _,to in ipairs(use.to) do
            if query(self,"isEnemy",to) and (query(to,"getHp")<=2 or query(self,"ajustDamage",self.player,to,1,use.card)>1) then
                -- The donor caches the secret top ID, but does not inspect it
                -- before choosing Duyi. Preserve this decision and remember only
                -- the public target. Its revealed card belongs to the later ask.
                self:setStrategyMemory("duyi_target",to:objectName())
                use.card=standard_skill_card(self,"duyi","DuyiCard",{})
                use.to=AIList.new({})
                return false
            end
        end
    end
end
sgs.ai_used_revises.wuqian = function(self,use)
    if query(use.card,"isKindOf","Slash") and query(self.player,"getStrategyMark","&wrath")>2 and not use.isDummy then
        for _,to in ipairs(use.to) do
            if query(self,"isEnemy",to) and query(self,"isWeak",to) and query(to,"getStrategyMark","Armor_Nullified")<1 then
                use.card=standard_skill_card(self,"wuqian","WuqianCard",{})
                use.to=AIList.new({to})
                return false
            end
        end
    end
end
sgs.ai_use_revises.ganlu=function(self,card,use)
    if query(card,"isKindOf","Peach") and not query(self.player,"hasUsed","GanluCard")
        and query(self,"aiUseCard",standard_skill_card(self,"ganlu","GanluCard",{})).card then return false end
end

ai_fill_skill.wooden_ox=function(self, options, request)
    local inclusive = options and options.inclusive

    self.wooden_ox_assist=nil
    self:setStrategyMemory("wooden_ox_assist",nil)
    local cards=query(self,"sortByUseValue",query(self.player,"getHandcards"),true)
    local card,friend=self:getCardNeedPlayer(cards,false)
    if card and friend and (query(self,"getOverflow")>0 or query(self,"isWeak",friend)) then
        self.wooden_ox_assist=not query(self,"isEnemy",friend) and friend
        self:setStrategyMemory("wooden_ox_assist",self.wooden_ox_assist and friend:objectName() or false)
        return standard_skill_card(self,"wooden_ox","WoodenOxCard",{query(card,"getEffectiveId")},request)
    end
    if #cards>0 and (query(self,"getOverflow")>0 or query(self,"needKongcheng") and #cards<2) then
        cards=query(self,"sortByKeepValue",cards)
        card=cards[math.max(1,math.min(query(self.player,"getMaxCards"),#cards))]
        return standard_skill_card(self,"wooden_ox","WoodenOxCard",{query(card,"getEffectiveId")},request)
    end
end
ai_card_use.WoodenOxCard=function(self, card, use, request) use.card=card end
sgs.ai_skill_playerchosen.wooden_ox=function(self,targets)
    local name,known_memory=self:getStrategyMemory("wooden_ox_assist")
    if known_memory and name then return self.room:findPlayerByObjectName(name,true) end
    return self.wooden_ox_assist
end
-- TargetSpecified already owns this public Collateral cache. Register the
-- original callback too for direct card-intention dispatches, without globals.
sgs.ai_card_intention.Collateral=function(self,card,from,tos)
    if rawget(self,"_event_state") then self:setEventMemory("ai_collateral",true)
    else self:setStrategyMemory("ai_collateral",true) end
end

sgs.ai_skill_cardask["@axe"] = function(self,data,pattern)
	local effect = known(data:toCardEffect(),"Axe card effect")
	if query(self,"isFriend",effect.to) then return "." end
	if query(self.player,"getCardCount")-3>=query(self.player,"getHp")
	or query(self,"needKongcheng") and query(self.player,"getHandcardNum")>0
	or query(self.player,"hasSkill","kuanggu") and query(self.player,"isWounded") and query(self.player,"distanceTo",effect.to)==1
	or query(self,"hasSkills",sgs.lose_equip_skill,self.player) and query(self.player,"getEquips"):length()>1 and query(self.player,"getHandcardNum")<2
	or query(effect.to,"getHp")<2 and not hasBuquEffect(effect.to)
	or self:needToThrowAll()
	then
		if self.yongsi_discard then return "$"..table.concat(self.yongsi_discard,"+") end
		local hcards = {}
		for _,c in sgs.list(query(self.player,"getHandcards"))do
			if not (isCard("Slash",c,self.player) and query(self,"hasCrossbowEffect")) then table.insert(hcards,c) end
		end
		local cards = {}
		hcards = query(self,"sortByKeepValue",hcards)
		local ec = self.player:getArmor()
		if ec and query(self,"needToThrowArmor") then
			table.insert(cards,query(ec,"getEffectiveId"))
		end
		if (query(self,"hasSkills",sgs.need_kongcheng) or not query(self,"hasLoseHandcardEffective"))
		and #hcards>0
		then
			for _,card in sgs.list(hcards)do
				if #cards>1 then break end
				table.insert(cards,query(card,"getEffectiveId"))
			end
		end
		if #cards<2
		and query(self,"hasSkills",sgs.lose_equip_skill,self.player)
		then
			ec = self.player:getOffensiveHorse()
			if ec then table.insert(cards,query(ec,"getEffectiveId")) end
			ec = self.player:getArmor()
			if #cards<2 and ec and not table.contains(cards,query(ec,"getEffectiveId"))
			then table.insert(cards,query(ec,"getEffectiveId")) end
			ec = self.player:getDefensiveHorse()
			if #cards<2 and ec then table.insert(cards,query(ec,"getEffectiveId")) end
		end
		for _,card in sgs.list(hcards)do
			if #cards>1 then break end
			if table.contains(cards,query(card,"getEffectiveId")) then continue end
			table.insert(cards,query(card,"getEffectiveId"))
		end
		ec = self.player:getOffensiveHorse()
		if #cards<2 and ec and not table.contains(cards,query(ec,"getEffectiveId"))
		then table.insert(cards,query(ec,"getEffectiveId")) end
		for _,card in sgs.list(hcards)do
			if #cards>1 then break end
			if table.contains(cards,query(card,"getEffectiveId")) then continue end
			table.insert(cards,query(card,"getEffectiveId"))
		end
		ec = self.player:getArmor()
		if #cards<2 and ec and not table.contains(cards,query(ec,"getEffectiveId"))
		then table.insert(cards,query(ec,"getEffectiveId")) end
		ec = self.player:getDefensiveHorse()
		if #cards<2 and ec and not table.contains(cards,query(ec,"getEffectiveId"))
		then table.insert(cards,query(ec,"getEffectiveId")) end
		if #cards>1
		then
			local num = 0
			for _,id in sgs.list(cards)do
				if self.player:hasEquip(visible_card(self,id)) then num = num+1 end
			end
			self.equipsToDec = num
			if query(self,"ajustDamage",self.player,effect.to,1,effect.card)~=0
			then return "$"..table.concat(cards,"+") end
		end
	end
	return "."
end



-- askForUseCard's lower-case Slash policy. Target traversal and the two-pass
-- fixed-target callback plan follow the donor; only the submitted action uses a
-- native receipt. Planning descriptors never become payment authority.
local function slash_answer(card,targets)
    local result={kind="use_card",targets={}}
    if AIValue.isConversion(card) then result.card_spec=card:toCardSpec()
    else result.card_id=query(card,"getEffectiveId") end
    for _,target in ipairs(targets) do result.targets[#result.targets+1]=target:objectName() end
    return result
end
local function slash_callback_card(self,value)
    if AIValue.isCard(value) or AIValue.isConversion(value) then return value end
    if type(value)=="number" then return visible_card(self,value) end
    if type(value)=="string" and value:match("^%$?%d+$") then
        return visible_card(self,tonumber((value:gsub("^%$",""))))
    end
    ai_unsupported("Slash cardask did not return a typed authorized card","slash")
end
local function source_slash_plan_card(self,slash)
    if not query(slash,"isKindOf","SkillCard") then return slash end
    -- Native response_planning is the declared ordinary card, with the same
    -- printed suit/number and exact subcards as this SkillCard receipt.
    local card=known(slash:getSlashWrapperPlanning(),"Slash wrapper planning descriptor")
    if query(card,"getSuit")~=query(slash,"getSuit") or query(card,"getNumber")~=query(slash,"getNumber") then
        ai_unsupported("Slash wrapper planning identity differs from the donor clone","slash")
    end
    local costs=query(slash,"getSubcards")
    local planned=query(card,"getSubcards")
    if #costs~=#planned then ai_unsupported("Slash wrapper planning costs differ","slash") end
    for index,id in ipairs(costs) do if planned[index]~=id then ai_unsupported("Slash wrapper reordered planning costs","slash") end end
    return card
end
local function xiansi_answer(self,target,prompt_key)
    if prompt_key=="@niluan-slash" or not query(target,"hasSkills","xiansi|tenyearxiansi") then return nil end
    local pile=query(target,"getPile","counter")
    if #pile<2 then return nil end
    local probe=known(nil,"Xiansi Slash probe") -- The Xiansi target probe is not projected.
    local candidate=known(CandidateView.new(probe.candidate),"Xiansi target-filter probe")
    if query(candidate,"canTargetWithEmptyPrefix",target) then
        -- Source always names XiansiSlashCard, even for tenyearxiansi. The native
        -- skill factory decides whether that exact attached source is usable.
        local card=query(self,"bindSkillCard","xiansi_slash",{pile[1],pile[2]})
        return slash_answer(card,{target})
    end
end
ai_skill_use.slash=function(self,prompt,request)
    local parsed={}
    for piece in ((prompt or "")..":"):gmatch("(.-):") do parsed[#parsed+1]=piece end
    local target
    if query(self.player,"getStrategyFlag","slashTargetFixToOne") then
        for _,player in ipairs(query(self.room,"getOtherPlayers",self.player)) do
            if query(player,"getStrategyFlag","SlashAssignee") then target=player break end
        end
        if not target then return {kind="pass"} end
        local callback=sgs.ai_skill_cardask[parsed[1]]
        if type(callback)=="function" then
            local special=xiansi_answer(self,target,parsed[1])
            if special then return special end
            local target2=parsed[3] and self.room:findPlayerByObjectName(parsed[3],true)
            local data={toPlayer=function()return target end}
            local selected=callback(self,data,"Slash",target,target2,prompt)
            if selected=="." or type(selected)=="table" and selected.kind=="pass" then return {kind="pass"} end
            selected=slash_callback_card(self,selected)
            local authority=type(selected.getAuthorityCard)=="function" and selected:getAuthorityCard() or selected
            local candidate=query(self,"getCardCandidate",query(authority,"getEffectiveId"))
            if query(candidate,"canTargetWithEmptyPrefix",target) then
                -- Deliberately absent isDummy matches the source callback path.
                local use=AIUsePlan.new()
                use.current_targets=query(self.room,"getOtherPlayers",target)
                self:useCardSlash(selected,use)
                if use.to:contains(target) then
                    use.card=nil
                    use.current_targets={target}
                    self:useCardSlash(selected,use)
                    return slash_answer(selected,use.to)
                end
            end
        end
    else
        for _,player in ipairs(query(self.room,"getOtherPlayers",self.player)) do
            local special=xiansi_answer(self,player,parsed[1])
            if special then return special end
        end
    end
    for _,slash in ipairs(query(self,"getCard","Slash",true)) do
        local card=source_slash_plan_card(self,slash)
        local use
        if target then
            local plan=dummy(true,0,query(self.room,"getOtherPlayers",target))
            if type(card.isEvaluationOnly)=="function" and card:isEvaluationOnly() then use=self:evaluateCard(card,plan)
            else use=self:aiUseCard(card,plan) end
        else use=self:aiUseCard(card) end
        if use.card and (not target or use.to:contains(target)) then return slash_answer(slash,use.to) end
    end
    return {kind="pass"}
end

-- Preserve the donor's direct method entry points as aliases of the already
-- migrated family policies. Generic class dispatch and package calls therefore
-- execute the very same policy body; no second planner or fallback is installed.
for _, class in ipairs({"AmazingGrace", "Dismantlement", "Duel", "ExNihilo", "GodSalvation", "Snatch"}) do
    SmartAIView["useCard" .. class] = function(self, card, use)
        return ai_card_use[class](self, card, use)
    end
end

-- Audited literal source aliases; optional package presence is decided by the
-- immutable native load-time identity snapshot, never by this registration.
if ai_audited_aliases then
 ai_audited_aliases.register{id="ai_target_revises.FourJianxiong",registry="ai_target_revises",path={"FourJianxiong"},canonical_registry="ai_target_revises",canonical_path={"jianxiong"},self_index=3}
 ai_audited_aliases.register{id="ai_target_revises.PlusWulve",registry="ai_target_revises",path={"PlusWulve"},canonical_registry="ai_target_revises",canonical_path={"jianxiong"},self_index=3}
 ai_audited_aliases.register{id="ai_target_revises.qhstandardjianxiong",registry="ai_target_revises",path={"qhstandardjianxiong"},canonical_registry="ai_target_revises",canonical_path={"jianxiong"},self_index=3}
 ai_audited_aliases.register{id="ai_target_revises.sfofl_xiongtu",registry="ai_target_revises",path={"sfofl_xiongtu"},canonical_registry="ai_target_revises",canonical_path={"jianxiong"},self_index=3}
 ai_audited_aliases.register{id="ai_target_revises.sfofl_lezong",registry="ai_target_revises",path={"sfofl_lezong"},canonical_registry="ai_target_revises",canonical_path={"xiangle"},self_index=3}
 ai_audited_aliases.register{id="ai_skill_playerchosen.@fatechuanxin2",registry="ai_skill_playerchosen",path={"@fatechuanxin2"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.@fatejianzhong2",registry="ai_skill_playerchosen",path={"@fatejianzhong2"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.fjsp_youlong",registry="ai_skill_playerchosen",path={"fjsp_youlong"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.heg_fangyuan",registry="ai_skill_playerchosen",path={"heg_fangyuan"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.jgfengxing",registry="ai_skill_playerchosen",path={"jgfengxing"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.kexiajue",registry="ai_skill_playerchosen",path={"kexiajue"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.manheng",registry="ai_skill_playerchosen",path={"manheng"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.s2_jizhan",registry="ai_skill_playerchosen",path={"s2_jizhan"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.sandun",registry="ai_skill_playerchosen",path={"sandun"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.se_chongzhuang",registry="ai_skill_playerchosen",path={"se_chongzhuang"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.sfofl_shuangren",registry="ai_skill_playerchosen",path={"sfofl_shuangren"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.sgszhenhua",registry="ai_skill_playerchosen",path={"sgszhenhua"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_playerchosen.sr_wuwei",registry="ai_skill_playerchosen",path={"sr_wuwei"},canonical_registry="ai_skill_playerchosen",canonical_path={"zero_card_as_slash"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_invoke.ShemaSkill",registry="ai_skill_invoke",path={"ShemaSkill"},canonical_registry="ai_skill_invoke",canonical_path={"kylin_bow"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_invoke.kenewbazhen",registry="ai_skill_invoke",path={"kenewbazhen"},canonical_registry="ai_skill_invoke",canonical_path={"eight_diagram"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_invoke.sfofl_young_eight_diagram",registry="ai_skill_invoke",path={"sfofl_young_eight_diagram"},canonical_registry="ai_skill_invoke",canonical_path={"eight_diagram"},self_index=1}
 ai_audited_aliases.register{id="ai_skill_cardask.shoot-jink",registry="ai_skill_cardask",path={"shoot-jink"},canonical_registry="ai_skill_cardask",canonical_path={"archery-attack-jink"},self_index=1}
end

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, to, value, damage_call, from, helpers, context)
        if damage_call(to,"getMark","@silver_lion") > 0 and not damage_call(self,"ignoreArmor",from,to) then return true, true end
        return value
    end
    local previous_1 = sgs.ai_ajustdamage_to["@silver_lion"]
    sgs.ai_ajustdamage_to["@silver_lion"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "cap" and context.rule == "silver_lion_mark" then
                return policy_1(self, to, context.value, context.query, from, context.extra[3], context)
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_to", "@silver_lion", {
        {phase="cap", rule="silver_lion_mark", order=3700},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_defense_slash["EightDiagram"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        state.diagram = not state.ignore and call(to, "hasArmorEffect", "EightDiagram")
        if state.diagram then defense = defense + 1.3 end
        return defense
    end
    sgs.ai_defense_slash["EightDiagram"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "base" and context.rule == "slash_defense.diagram" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "EightDiagram", {
        {phase="base", order=10, rule="slash_defense.diagram"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_defense_slash["slash_defense.known_tuntian"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        if state.knownJink > 0 then
            if call(self, "hasTuntianEffect", to, true) then defense = defense + 1.5 end
        end
        return defense
    end
    sgs.ai_defense_slash["slash_defense.known_tuntian"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "known_jink" and context.rule == "slash_defense.known_tuntian" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "slash_defense.known_tuntian", {
        {phase="known_jink", order=12, rule="slash_defense.known_tuntian"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_defense_slash["slash_defense.liegong"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        if call(self, "canLiegong", to) then defense = 0 end
        return defense
    end
    sgs.ai_defense_slash["slash_defense.liegong"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "special_1" and context.rule == "slash_defense.liegong" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "slash_defense.liegong", {
        {phase="special_1", order=20, rule="slash_defense.liegong"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_defense_slash["slash_defense.masochism"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        local strategy_known = state.strategy_known
        if state.masochismEligible then
            local names = strategy_known(sgs.masochism_skill, "masochism_skill")
            for name in names:gmatch("[^|]+") do
                if call(to, "hasSkill", name) and call(self, "isGoodHp", to) then defense = defense + 1 end
            end
        end
        return defense
    end
    sgs.ai_defense_slash["slash_defense.masochism"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "health" and context.rule == "slash_defense.masochism" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "slash_defense.masochism", {
        {phase="health", order=20, rule="slash_defense.masochism"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_defense_slash["Indulgence"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        if call(to, "containsTrick", "indulgence") and not call(to, "containsTrick", "YanxiaoCard") then defense = defense - .15 end
        return defense
    end
    sgs.ai_defense_slash["Indulgence"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "final" and context.rule == "slash_defense.indulgence" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "Indulgence", {
        {phase="final", order=44, rule="slash_defense.indulgence"},
    })
end)()
end
