-- Fixed yingbian_cards policy: ordered source branches and RNG are retained.
local known = AIValue.requireKnown

local function scope(self)
    local c=self:getDecisionContext().yingbian
    if type(c)~="table"then ai_unsupported("Yingbian question context missing","yingbian_cards")end;return c
end
local function hydrate(self,row)
    if row==false then return {to=AIList.new({})}end
    if type(row)~="table"or type(row.card)~="table"or not AIValue.isList(row.to)then ai_unsupported("Yingbian CardUse projection malformed","yingbian_cards")end
    local c=CardView.new(row.card);if type(row.card.evaluation_candidate)=="table"then c._evaluation_candidate=row.card.evaluation_candidate
    elseif type(row.candidate)=="table"then c._evaluation_candidate=row.candidate end
    local use={card=c,to=AIList.new({}),from=row.from and self.room:findPlayerByObjectName(row.from)}
    for _,name in ipairs(row.to)do use.to:append(known(self.room:findPlayerByObjectName(name),"use target"))end
    return use
end
local function tag_use(self)return hydrate(self,known(scope(self).use,"source CardUse tag"))end
local function ice_data(self)
    local row=known(scope(self).ice_damage,"IceDamageData")
    local damage={};for k,v in pairs(row)do damage[k]=v end
    for _,k in ipairs({"from","to"})do if type(row[k])=="string"and row[k]~=""then damage[k]=known(self.room:findPlayerByObjectName(row[k]),"damage player")end end
    if row.card then damage.card=CardView.new(row.card)end
    return {toDamage=function()return damage end}
end
local function is_current(use,to)
    for _,p in ipairs(use.current_targets or {})do if p==to or p==to:objectName()then return true end end
end
local function can_to(self,card,to)return self:cardTargetFilter(card, {}, to)end
local function pattern_names(self)
    local names=AICardCatalog.patternNames()
    if not AIValue.isList(names)then ai_unsupported("ordered public pattern catalog missing","wuxinghelingshan")end;return names
end
--冰属性伤害效果
sgs.ai_skill_invoke.IceDamagePrevent = function(self,data)
	local damage = ice_data(self)
	return sgs.ai_skill_invoke.ice_sword(self,damage)
end

--冰杀
function SmartAIView:useCardIceSlash(...)
	self:useCardSlash(...)
end

ai_audited_aliases.register{
    id="ai_card_intention.IceSlash",registry="ai_card_intention",path={"IceSlash"},
    canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1
}

sgs.ai_use_value.IceSlash = 4.65
sgs.ai_keep_value.IceSlash = 3.6
sgs.ai_use_priority.IceSlash = 2.7

sgs.card_damage_nature.IceSlash = "I"

--洞烛先机
function SmartAIView:useCardDongzhuxianji(card,use)
	local xiahou = self:hasSkills("yanyu",self.enemies)
	if xiahou and xiahou:getStrategyMark("YanyuDiscard2")>0 then return end
	use.card = card
end

sgs.ai_card_intention.Dongzhuxianji = -80

sgs.ai_keep_value.Dongzhuxianji = 4
sgs.ai_use_value.Dongzhuxianji = 9
sgs.ai_use_priority.Dongzhuxianji = 9.4

sgs.dynamic_value.benefit.Dongzhuxianji = true

sgs.ai_nullification.Dongzhuxianji = function(self,trick,from,to,positive,null_num)
	if positive
	then
        return self:isEnemy(to) and (null_num>1 or to:getHandcardNum()<=2)
	else
        return self:isFriend(to) and to:getHandcardNum()<=2
		or to:objectName()==self.player:objectName()
	end
end

--出其不意
function SmartAIView:useCardChuqibuyi(card,use)
	self:sort(self.enemies)
	local enemies = {}
	for _,enemy in sgs.list(self.enemies)do
		if is_current(use,enemy) then
		elseif can_to(self,card,enemy) and self:isGoodTarget(enemy, self.enemies, card)
		then table.insert(enemies,enemy) end
	end
	if #enemies<1 then return end
	local extraTarget = card:getTargetModExtra(self.player)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	if card:getSuit()>=sgs.Card_NoSuitBlack then
		use.card = card
		for _,enemy in sgs.list(enemies)do
			use.to:append(enemy)
			if use.to:length()>extraTarget
			then return end
		end
	else
		for _,enemy in sgs.list(enemies)do
			local n = getKnownCard(enemy,self.player,card:getSuitString(),false,"h")
			if n>=enemy:getHandcardNum()/2 then continue end
			use.card = card
			use.to:append(enemy)
			if use.to:length()>extraTarget
			then return end
		end
	end
end

sgs.ai_use_value.Chuqibuyi = 4.9
sgs.ai_keep_value.Chuqibuyi = 3.4
sgs.ai_use_priority.Chuqibuyi = sgs.ai_use_priority.Dismantlement+0.2

sgs.dynamic_value.damage_card.Chuqibuyi = true

sgs.ai_card_intention.Chuqibuyi = 80

sgs.ai_nullification.Chuqibuyi = function(self,trick,from,to,positive)
    local null_num = self:getCardsNum("Nullification")
	if positive then
        if to==self.player then
			for _,c in sgs.list(to:getHandcards())do
				if c:getSuit()==trick:getSuit()
				then continue end
				return true
			end
			return false
		end
		return self:isFriend(to) and (null_num>1 or to:getHandcardNum()>1 and self:isWeak(to))
	else
        return self:isEnemy(to) and to:getHandcardNum()>1 and self:isWeak(to)
	end
end

--逐近弃远
function SmartAIView:useCardZhujinqiyuan(card,use)
	local tos = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if can_to(self,card,p) then table.insert(tos,p) end
	end
	if #tos<1 then return end
	local extraTarget = card:getTargetModExtra(self.player)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,p in sgs.list(self:findPlayerToDiscard("hej",false,false,tos,"zhujinqiyuan"))do
		if is_current(use,p) then continue end
		if table.contains(tos,p)
		then
			use.card = card
			use.to:append(p)
			if use.to:length()>extraTarget
			then return end
		end
	end
	for _,p in sgs.list(tos)do
		if is_current(use,p) then continue end
		if self:doDisCard(p,"ej",self.player:distanceTo(p)<2)
		then
			use.card = card
			use.to:append(p)
			if use.to:length()>extraTarget
			then return end
		end
	end
	for _,p in sgs.list(tos)do
		if is_current(use,p) then continue end
		if self:doDisCard(p,"hej",self.player:distanceTo(p)<2)
		then
			use.card = card
			use.to:append(p)
			if use.to:length()>extraTarget
			then return end
		end
	end
end

sgs.ai_use_value.Zhujinqiyuan = 9
sgs.ai_use_priority.Zhujinqiyuan = 9.3
sgs.ai_keep_value.Zhujinqiyuan = 3.46

sgs.dynamic_value.control_card.Zhujinqiyuan = true

sgs.ai_nullification.Zhujinqiyuan = function(self,trick,from,to,positive)
    local null_num = self:getCardsNum("Nullification")
	if positive
	then
        if null_num>1
		then
			return self:isFriend(to) and to:getCardCount()>0 and self:isEnemy(from)
			or to:objectName()==self.player:objectName() and self:isEnemy(from)
		else
			return self:isFriend(to) and to:getCardCount()>0
			and to:getHandcardNum()<2 and self:isEnemy(from) and self:isWeak(to)
			or to:objectName()==self.player:objectName() and self:isEnemy(from)
    	end 
	else
        if null_num>1
		then
			return self:isEnemy(to)
			and to:getCardCount()>0
			and self:isFriend(from)
		else
			return self:isEnemy(to)
			and to:getCardCount()>0
			and to:getHandcardNum()<2
			and self:isFriend(from)
			and self:isWeak(to)
    	end 
	end
end

--护心镜
sgs.ai_skill_invoke.huxinjing = true

sgs.ai_use_priority.Tongque = 7.3
sgs.ai_use_value.Tongque = 6

--太公阴符
sgs.ai_skill_playerchosen.taigongyinfu = function(self,targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	for _,p in sgs.list(targets)do
		if self:isEnemy(p)
		then return p end
	end
	for _,p in sgs.list(targets)do
		if not self:isFriend(p)
		then return p end
	end
end

sgs.ai_skill_cardask["@taigongyinfu-recast"] = function(self,data)
	local hands = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(hands,true)
	local cards = {}
	for _,c in sgs.list(hands)do
		if self.player:isCardLimited(c, sgs.Card_MethodRecast, true) then continue end
		table.insert(cards,c)
	end
	if #cards<1 or self:isValuableCard(cards[1]) then return "." end
	return "$"..cards[1]:getEffectiveId()
end

--天机图
sgs.ai_skill_discard.tianjitu = function(self,discard_num,min_num,optional,include_equip,pattern)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for _,c in sgs.list(cards)do
		local i = c:getKnownEffectiveId()
		if self:matchesDiscardPattern(pattern, c)
		and self.player:canDiscard(self.player, i)
		then return {i} end
	end
	return {}
end

sgs.ai_armor_value.tianjitu = function(player,self,card)
	return card and player:hasEquip(card) and player:getHandcardNum()<5 and player:getHandcardNum()-10 or 1
end

sgs.ai_use_revises.tianjitu = function(self,card,use)
	if card:isKindOf("Treasure")
	and self.player:getHandcardNum()<5
	then use.card = card end
end

--五行鹤翎扇
sgs.ai_fill_skill.wuxinghelingshan = function(self,inclusive,request)
	local cards = self:addHandPile()
	cards = self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
        for _,name in ipairs(pattern_names(self)) do
            local ns=self:getEvaluationCard(name)
            if ns and c:objectName()~=name and ns:isKindOf("NatureSlash") and c:isKindOf("NatureSlash") then
                local preview=self:evaluateSkillCard("wuxinghelingshan", name, {c:getKnownEffectiveId()})
                if preview:isAvailable(self.player) then
                    return self:bindTurnConversion("wuxinghelingshan",preview:getClassName(),
                        {name=name,skill="wuxinghelingshan",suit=preview:getSuit(),number=preview:getNumber(),subcards={c:getKnownEffectiveId()}},request)
                end
            end
        end
	end
end

sgs.weapon_range.Wuxinghelingshan = 4
sgs.weapon_range.Wutiesuolian = 3

sgs.ai_target_revises.heiguangkai = function(to,card,self,use)
	if use.to:length()>1
	then
		if card:isKindOf("GlobalEffect") and #self.friends<2
		and to==self.player then use.card = nil return true
		elseif card:isNDTrick() or card:isKindOf("Slash")
		then return true end
	end
end

--应变效果
--富甲->可使目标-1
sgs.ai_skill_playerchosen.yb_fujia2 = function(self,targets)
	local use = tag_use(self)
	if not use then return nil end
	if use.card:isKindOf("GodSalvation") then
		self:sort(self.enemies,"hp")
		for _,enemy in sgs.list(self.enemies)do
			if enemy:isWounded() and targets:contains(enemy)
			and self:hasTrickEffective(use.card,enemy,self.player)
			then return enemy end
		end
	elseif use.card:isKindOf("AmazingGrace") then
		self:sort(self.enemies)
		for _,enemy in sgs.list(self.enemies)do
			if targets:contains(enemy)
			and self:hasTrickEffective(use.card,enemy,self.player)
			and not self:needKongcheng(enemy,true)
			and not hasManjuanEffect(enemy)
			then return enemy end
		end
	elseif use.card:isKindOf("AOE") then
		self:sort(self.friends_noself)
		local lord = self.room:getLord()
		if lord and self:isFriend(lord) and self:isWeak(lord)
		and targets:contains(lord) then return lord end
		for _,friend in sgs.list(self.friends_noself)do
			if targets:contains(friend)
			and self:hasTrickEffective(use.card,friend,self.player)
			then return friend end
		end
	end
	local destlist = sgs.QList2Table(targets) -- 将列表转换为表
	self:sort(destlist,"hp")
	if use.card:isDamageCard() then
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			and self:hasTrickEffective(use.card,target,self.player)
			then return target end
		end
	elseif use.card:isKindOf("GlobalEffect") then
		for _,target in sgs.list(destlist)do
			if self:isEnemy(target)
			then return target end
		end
	end
	return nil
end

--助战->依次执行所有选项
sgs.ai_skill_discard.yb_zhuzhan1 = function(self,discard_num,min_num,optional,include_equip)
	local use = tag_use(self)
	if use and use.from and self:isFriend(use.from) then
		if use.card:isKindOf("Drowning") and use.to:at(0):getEquips():length()<1
		or use.card:isKindOf("Zhujinqiyuan") and use.to:at(0):getCardCount()<2
		or self:isFriend(use.to:at(0)) then return {} end
		local handcards = self.player:getCards("he")
		handcards = self:sortByKeepValue(handcards,nil,true) -- 按保留值排序
		for _,c in sgs.list(handcards)do
			if c:getTypeId()==use.card:getTypeId()
			then return {c:getKnownEffectiveId()} end
		end
	end
	return {}
end

--助战->目标+1
sgs.ai_skill_discard.yb_zhuzhan2 = function(self,discard_num,min_num,optional,include_equip)
	local use = tag_use(self)
	if use and use.from and self:isFriend(use.from) then
		local ids = {}
		local cards = self.player:getCards("he")
		for _,c in sgs.list(self:sortByKeepValue(cards,nil,true))do
			if c:getTypeId()==use.card:getTypeId()
			then ids = {c:getKnownEffectiveId()} break end
		end
		if #ids<1 then return {} end
		if math.random()<0.6 and #self.enemies>0 then
			cards = {
				"可以+1",
				"可以加个人的",
				"扩展一下目标吧",
				"有敌人可以",
				"都应该拉下水",
				"有难同当哦",
				"该当诛连！！",
				"此贼怀异，必有同党！",
				"吾有余兵，可助君势！",
				"我有牌助战"
				}
			self:emitSpeechLine(self.player,cards[math.random(1,#cards)],"yingbian_cards:yb_zhuzhan2")
		end
		for _,p in sgs.list(self.room:getOtherPlayers(use.from))do
			if use.to:contains(p) then continue end
			if use.from:canUse(use.card, p, true)
			and self:canCanmou(p,use) then
				if use.to:contains(use.from)
				and self:isFriend(p) then return ids
				elseif use.card:isDamageCard()
				and not self:isFriend(use.to:at(0))
				and self:isEnemy(p) then return ids
				elseif not self:isFriend(p) then
					for _,to in sgs.list(use.to)do
						if self:isFriend(to)
						then return {} end
					end
					return ids
				end
			end
		end
	end
	return {}
end

sgs.ai_skill_playerchosen.yb_zhuzhan2 = function(self,targets)
	local use = tag_use(self)
	if not AIValue.isCard(use.card) and not AIValue.isConversion(use.card) then return nil end
	local tos = self:sort(targets,"hp")
	local dummy_use = AIUsePlan.new();dummy_use.isDummy=true;dummy_use.extra_target=0;dummy_use.current_targets=use.to
	if use.card:isKindOf("Peach") then
		for _,friend in sgs.list(tos)do
			if friend:isWounded()
			and self:isFriend(friend)
			and friend:getHp()<getBestHp(friend)
			and self:canCanmou(friend,use)
			then return friend end
		end
	elseif use.card:isKindOf("ExNihilo")
	or use.card:isKindOf("Dongzhuxianji") then
		for _,p in sgs.list(self:findPlayerToDraw(false,2,#self.friends_noself))do
			if targets:contains(p) and self:canCanmou(p,use)
			then return p end
		end
	elseif use.card:isKindOf("Snatch")
	or use.card:isKindOf("Dismantlement")
	or use.card:isKindOf("Slash") then
		self:aiUseCard(use.card,dummy_use)
		if dummy_use.card then
			for _,p in sgs.list(dummy_use.to)do
				if targets:contains(p)
				and self:canCanmou(p,use)
				then return p end
			end
		end
	end
	for _,p in sgs.list(tos)do
		if use.from:canUse(use.card, p, true)
		and self:canCanmou(p,use) then
			if use.to:contains(use.from)
			and self:isFriend(p) then return p
			elseif use.card:isDamageCard()
			and not self:isFriend(use.to:at(0))
			and self:isEnemy(p) then return p
			elseif not self:isFriend(p) then
				for _,to in sgs.list(use.to)do
					if self:isFriend(to)
					then return end
				end
				return p
			end
		end
	end
end

-- Both callbacks delegate using the question's exact original tag projection.
-- No native tag mutation or cross-request cache is needed for that local substitution.
sgs.ai_skill_playerchosen.yb_kongchao3=function(self,targets)
    return sgs.ai_skill_playerchosen.yb_zhuzhan2(self,targets)
end
sgs.ai_skill_playerchosen.yb_canqu2=function(self,targets)
    return sgs.ai_skill_playerchosen.yb_zhuzhan2(self,targets)
end
