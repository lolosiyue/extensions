addAiSkills("MR_huishi").getTurnUseCard = function(self)
	if not self:isWeak() then return end
    return sgs.Card_Parse("#MR_huishi:.:")
end

sgs.ai_skill_use_func["#MR_huishi"] = function(card,use,self)
    self:sort(self.friends,"handcard")
    for _,target in sgs.list(self.friends)do
    	if self:isFriend(target) and self:canDraw(target, self.player)
		then
            use.card = card
            use.to:append(target)
            return
		end
	end
end

sgs.ai_use_value["MR_huishi"] = 8.4
sgs.ai_use_priority["MR_huishi"] = 8.4


sgs.ai_need_damaged.MR_yiji = function (self,attacker,player)
	if not player:hasSkill("MR_yiji") then return end

	local friends = {}
	for _,ap in sgs.list(self.room:getAlivePlayers())do
		if self:isFriend(ap,player) then
			table.insert(friends,ap)
		end
	end
	self:sort(friends,"hp")

	if #friends>0 and friends[1]:objectName()==player:objectName() and self:isWeak(player) and getCardsNum("Peach",player,(attacker or self.player))==0 then return false end

	return player:getHp()>2 and sgs.turncount>2 and #friends>1 and not self:isWeak(player) and player:getHandcardNum()>=2
end

sgs.ai_can_damagehp.MR_yiji = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end
sgs.ai_skill_use["@@MR_yiji"] = function(self,prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		targets:append(p)
	end
	if targets:length() == 0 then return "." end
	local c,to = self:getCardNeedPlayer(cards, false, targets)
	if c and to then return "#MR_yiji:"..c:getEffectiveId()..":->"..to:objectName() end
	return "."
end


sgs.ai_skill_use["@mobilemouzhiheng"]=function(self,prompt)
	local card = sgs.Card_Parse("@MobileMouZhihengCard=.")
	local dummy_use = dummy()
	self:useSkillCard(card,dummy_use)
	if dummy_use.card then return (dummy_use.card):toString() .. "->." end
	return "."
end
local MR_jilve_skill = {}
MR_jilve_skill.name = "MR_jilve"
table.insert(sgs.ai_skills,MR_jilve_skill)
MR_jilve_skill.getTurnUseCard = function(self)
	if not(self.player:hasFlag("MR_jilveWansha") or self.player:hasSkills("wansha|olwansha"))
	then
		for _,enemy in sgs.list(self.enemies)do
			if self.player:canSlash(enemy) and self:isWeak(enemy)
			and self:damageMinusHp(enemy,1)>0 and #self.enemies>1
			then
				sgs.ai_use_priority["MR_jilve"] = 8
				sgs.ai_skill_choice.MR_jilve = sgs.Sanguosha:getSkill("olwansha") and "MR_jilve_olwansha" or "wansha"
				return sgs.Card_Parse("#MR_jilve:.:")
			end
		end
	end
	if not self.player:hasFlag("MR_jilveZhiheng")
	then
		sgs.ai_skill_choice.MR_jilve = "zhiheng"
		sgs.ai_use_priority["MR_jilve"] = sgs.ai_use_priority.TenyearZhihengCard
		local card = sgs.Card_Parse("@TenyearZhihengCard=.")
		local dummy_use = dummy()
		self:useSkillCard(card,dummy_use)
		if dummy_use.card then return sgs.Card_Parse("#MR_jilve:.:") end
	end
end

sgs.ai_skill_use_func["#MR_jilve"]=function(card,use,self)
	use.card = card
end


local MR_lianhuan_skill={}
MR_lianhuan_skill.name="MR_lianhuan"
table.insert(sgs.ai_skills,MR_lianhuan_skill)
MR_lianhuan_skill.getTurnUseCard = function(self)
	local cards = self:addHandPile()
	self:sortByUseValue(cards,true)
	local card
	local slash = self:getCard("FireSlash") or self:getCard("ThunderSlash") or self:getCard("Slash")
	if slash then
		local dummy_use = dummy()
		self:useBasicCard(slash,dummy_use)
		if not dummy_use.card then slash = nil end
	end

	for _,acard in sgs.list(cards)do
		if not acard:isKindOf("BasicCard") then
			local shouldUse = true
			if self:getUseValue(acard)>sgs.ai_use_value.IronChain and acard:getTypeId()==sgs.Card_TypeTrick then
				local dummy_use = dummy()
				self:useTrickCard(acard,dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if acard:getTypeId()==sgs.Card_TypeEquip then
				local dummy_use = dummy()
				self:useEquipCard(acard,dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse and (not slash or slash:getEffectiveId()~=acard:getEffectiveId()) then
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("iron_chain:MR_lianhuan[club:%s]=%d"):format(number,card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_skill_use["@@MR_niepan"] = function(self, prompt)
	local peaches = 1-self.player:getHp()
	if self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<peaches then
		return "#MR_niepan:.:"
	end
	return "."
end

sgs.ai_canNiepan_skill.MR_niepan = function(player)
	return player:getMark("MR_niepan") < 1
end

sgs.ai_ajustdamage_from["&MR_luofeng"] = function(self,from,to,card,nature)
	if card and (card:isKindOf("SkillCard") or (card:isVirtualCard() and card:subcardsLength() > 0))
	then return 1 end
end




local MR_xuanhuo_skill={}
MR_xuanhuo_skill.name="MR_xuanhuo"
table.insert(sgs.ai_skills,MR_xuanhuo_skill)
MR_xuanhuo_skill.getTurnUseCard = function(self)
	if self:isWeak() or self.player:isKongcheng() then return end
	if self.player:usedTimes("#MR_xuanhuo") >= 1 then return end
	return sgs.Card_Parse("#MR_xuanhuo:.:")
end

sgs.ai_skill_use_func["#MR_xuanhuo"] = function(card,use,self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	use.card = sgs.Card_Parse("#MR_xuanhuo:"..cards[1]:getEffectiveId()..":")
	return
end

sgs.ai_use_value.MR_xuanhuo = 4.4
sgs.ai_use_priority.MR_xuanhuo = 5.2

sgs.ai_need_damaged.MR_enyuan = function (self,attacker,player)
	if not player:hasSkill("MR_enyuan") then return false end
	if not attacker then return end
	if self:isEnemy(attacker,player) and self:isWeak(attacker) and attacker:getHandcardNum()<3
	  and not self:hasSkills("lianying|noslianying|shangshi|nosshangshi",attacker)
	  and not (attacker:hasSkill("kongcheng") and attacker:getHandcardNum()>0)
	  and not attacker:hasSkills(sgs.masochism_skill) then
		return not self:isWeak(player)
	end
end



local MR_fanjian_skill = {}
MR_fanjian_skill.name = "MR_fanjian"
table.insert(sgs.ai_skills,MR_fanjian_skill)
MR_fanjian_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return nil end
	return sgs.Card_Parse("#MR_fanjian:.:")
end

sgs.ai_skill_use_func["#MR_fanjian"]= function(card,use,self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	self:sort(self.enemies,"defense")

	if self:getCardsNum("Slash")>0 then
		local slash = self:getCard("Slash")
		local dummy_use = dummy()
		self:useCardSlash(slash,dummy_use)
		if dummy_use.card and dummy_use.to:length()>0 then
			sgs.ai_use_priority["MR_fanjian"]= sgs.ai_use_priority.Slash+0.15
			local target = dummy_use.to:first()
			if self:isEnemy(target) and getCardsNum("Jink",target,self.player)>=1 and target:getMark("yijue")==0
				and not target:isKongcheng() and (self:getOverflow()>0 or target:getHandcardNum()>2)
				and not (self.player:hasSkill("liegong") and (target:getHandcardNum()>=self.player:getHp() or target:getHandcardNum()<=self.player:getAttackRange()))
				and not (self.player:hasSkill("kofliegong") and target:getHandcardNum()>=self.player:getHp()) then
				if target:hasSkill("qingguo") then
					for _,card in ipairs(cards)do
						if self:getUseValue(card)<6 and card:isBlack() then
							use.card = sgs.Card_Parse("#MR_fanjian:"..card:getEffectiveId()..":")
							use.to:append(target)
							return
						end
					end
				end
				for _,card in ipairs(cards)do
					if self:getUseValue(card)<6 and card:getSuit()==sgs.Card_Diamond then
						use.card = sgs.Card_Parse("#MR_fanjian:"..card:getEffectiveId()..":")
						use.to:append(target)
						return
					end
				end
			end
		end
	end

	if self:getOverflow()<=0 then return end
	sgs.ai_use_priority["MR_fanjian"]= 0.2
	local suit_table = { "spade","club","heart","diamond" }
	local equip_val_table = { 1.2,1.5,0.5,1,1.3 }
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHandcardNum()>2 then
			local max_suit_num,max_suit = 0,{}
			for i = 0,3,1 do
				local suit_num = getKnownCard(enemy,self.player,suit_table[i+1])
				for j = 0,4,1 do
					if enemy:getEquip(j) and enemy:getEquip(j):getSuit()==i then
						local val = equip_val_table[j+1]
						if j==1 and self:needToThrowArmor(enemy) then val = -0.5
						else
							if enemy:hasSkills(sgs.lose_equip_skill) then val = val/8 end
							if enemy:getEquip(j):getEffectiveId()==self:getValuableCard(enemy) then val = val*1.1 end
							if enemy:getEquip(j):getEffectiveId()==self:getDangerousCard(enemy) then val = val*1.1 end
						end
						suit_num = suit_num+j
					end
				end
				if suit_num>max_suit_num then
					max_suit_num = suit_num
					max_suit = { i }
				elseif suit_num==max_suit_num then
					table.insert(max_suit,i)
				end
			end
			if max_suit_num==0 then
				max_suit = {}
				local suit_value = { 1,1,1.3,1.5 }
				for _,skill in ipairs(sgs.getPlayerSkillList(enemy))do
					if sgs[skill:objectName().."_suit_value"] then
						for i = 1,4,1 do
							local v = sgs[skill:objectName().."_suit_value"][suit_table[i]]
							if v then suit_value[i] = suit_value[i]+v end
						end
					end
				end
				local max_suit_val = 0
				for i = 0,3,1 do
					local suit_val = suit_value[i+1]
					if suit_val>max_suit_val then
						max_suit_val = suit_val
						max_suit = { i }
					elseif suit_val==max_suit_val then
						table.insert(max_suit,i)
					end
				end
			end
			for _,card in ipairs(cards)do
				if self:getUseValue(card)<6 and table.contains(max_suit,card:getSuit()) then
					use.card = sgs.Card_Parse("#MR_fanjian:"..card:getEffectiveId()..":")
					use.to:append(enemy)
					return
				end
			end
			if getCardsNum("Peach",enemy,self.player)<2 then
				for _,card in ipairs(cards)do
					if self:getUseValue(card)<6 and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("#MR_fanjian:"..card:getEffectiveId()..":")
						use.to:append(enemy)
						return
					end
				end
			end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if friend:hasSkill("hongyan") then
			for _,card in ipairs(cards)do
				if self:getUseValue(card)<6 and card:getSuit()==sgs.Card_Spade then
					use.card = sgs.Card_Parse("#MR_fanjian:"..card:getEffectiveId()..":")
					use.to:append(friend)
					return
				end
			end
		end
		if friend:hasSkill("zhaxiang") and not self:isWeak(friend) and not (friend:getHp()==2 and friend:hasSkill("chanyuan")) then
			for _,card in ipairs(cards)do
				if self:getUseValue(card)<6 then
					use.card = sgs.Card_Parse("#MR_fanjian:"..card:getEffectiveId()..":")
					use.to:append(friend)
					return
				end
			end
		end
	end
end

sgs.ai_use_priority["MR_fanjian"] = 0.2

sgs.ai_skill_invoke.MR_haoshi = function(self,data)
	local num = self.room:getOtherPlayers(self.player):first():getHandcardNum()
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		num = math.min(num,p:getHandcardNum())
	end
	
	local crossbow = false
	for _,c in sgs.qlist(self.player:getCards("h"))do
		if c:isKindOf("Crossbow") and self.player:canUse(c) then
			crossbow = true
			break
		end
	end
	
	local use,slash,analeptic = 0,false,0
	for _,c in sgs.qlist(self.player:getCards("h"))do
		if not self:willUse(self.player,c) then continue end
		if c:isKindOf("Slash") and not slash then
			slash = true
			use = use+1
		elseif c:isKindOf("Slash") and slash then
			if self.player:canSlashWithoutCrossbow() or self.player:hasWeapon("crossbow") or crossbow then
				use = use+1
			end
		elseif c:isKindOf("Analeptic") then
			analeptic = analeptic+1
			if analeptic<=1+sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,c,self.player) then
				use = use+1
			end
		else
			use = use+1
		end
	end
	return self.player:getHandcardNum()+2-use<=num
end

sgs.ai_skill_playerchosen.MR_haoshi = function(self,targets)
	local selfhand,targethand = self.player:getHandcardNum(),targets:first():getHandcardNum()
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense")
	for _,p in ipairs(targets)do
		if not self:isFriend(p) then continue end
		if self:doDisCard(p,"h") then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if not self:isFriend(p) then continue end
		return p
	end
	for _,p in ipairs(targets)do
		if not self:isEnemy(p) and self:doDisCard(p,"h") then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if not self:isEnemy(p) then
			return p
		end
	end
	return targets[math.random(1,#targets)]
end




sgs.ai_skill_playerchosen.MR_jieming = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	local function func(a,b)
		return a:getMaxHp()-a:getHandcardNum()>b:getMaxHp()-b:getHandcardNum()
	end
	table.sort(destlist,func)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:getHandcardNum()<5
		and target:getHandcardNum()<target:getMaxHp()
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:getHandcardNum()<6
		and target:getHandcardNum()<=target:getMaxHp()
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getHandcardNum()>target:getMaxHp()*(math.random()+1)
		then return target end
	end
end

sgs.ai_can_damagehp.MR_jieming = function(self,from,card,to)
	if self:isFriend(to)
	and self:canLoseHp(from,card,to)
	and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	then
		for _,fp in sgs.list(self.friends)do
			if fp:getHandcardNum()<5
			and fp:getHandcardNum()<fp:getMaxHp()
			then return true end
		end
	end
end

local MR_quhu_skill = {}
MR_quhu_skill.name = "MR_quhu"
table.insert(sgs.ai_skills,MR_quhu_skill)
MR_quhu_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#MR_quhu:.:")
end

sgs.ai_skill_use_func["#MR_quhu"] = function(card,use,self)
	if #self.enemies==0 then return end
	self:sort(self.enemies,"handcard")

	for _,enemy in sgs.list(self.enemies)do
		if self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy)==enemy:getHandcardNum() then
				allknown = allknown+1
			end
			for _,enemy2 in sgs.list(self.enemies)do
				if (enemy:objectName()~=enemy2:objectName())
					and enemy:canPindian(enemy2) then
					use.card = sgs.Card_Parse("#MR_quhu:.:")
					use.to:append(enemy)
					use.to:append(enemy2)
					return
				end
			end
		end
	end
end

sgs.ai_choicemade_filter.cardUsed["MR_quhu"] = function(self,player,carduse)
	sgs.ai_quhu_effect = true
end

sgs.ai_skill_invoke.MR_zhian = function(self,data)
	local target = data:toCardUse().to:first()
	if target
	then
		return not self:isFriend(target)
	end
end
sgs.ai_skill_discard["MR_lingfa"] = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return {} end
	self:sortByKeepValue(cards)
	local use = self.room:getTag("MR_lingfa"):toCardUse()
	for _, p in sgs.qlist(use.to) do
		if p and self:isFriend(p) and p:hasSkill("MR_lingfa") then
			return {}
		end
	end 
	local to_discard = {}
	for _, c in ipairs(cards) do
		if #to_discard < discard_num then
			table.insert(to_discard, c:getEffectiveId())
		end
	end
	if #to_discard == discard_num then
		return to_discard
	end
	return {}
end

sgs.ai_skill_choice.MR_zhian = function(self,choices,data)
	local use = data:toCardUse()
	local items = choices:split("+")
	if self:isEnemy(use.from)
	then
		if self:isWeak(use.from)
		then return items[#items]
		elseif use.card:isKindOf("DelayedTrick")
		and self:isFriend(use.to:at(0))
		and self.player:getHandcardNum()>2
		then return items[2]
		elseif use.card:isKindOf("EquipCard")
		and self.player:getHandcardNum()>2
		then return items[2] end
	elseif not self:isFriend(use.from)
	and use.card:isKindOf("DelayedTrick")
	and self:isFriend(use.to:at(0))
	then return items[2] end
	return items[1]
end



local MR_gongxin_skill={}
MR_gongxin_skill.name="MR_gongxin"
table.insert(sgs.ai_skills,MR_gongxin_skill)
MR_gongxin_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#MR_gongxin:.:")
end

sgs.ai_skill_use_func["#MR_gongxin"]=function(card,use,self)
	self:sort(self.enemies,"handcard")
	self.enemies = sgs.reverse(self.enemies)

	for _,enemy in sgs.list(self.enemies)do
		if not enemy:isKongcheng() and self:objectiveLevel(enemy)>0
			and (self:hasSuit("spade",false,enemy) or self:hasSuit("diamond",false,enemy) or self:hasSuit("heart",false,enemy) or self:getKnownNum(enemy)~=enemy:getHandcardNum()) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_skill_askforag.MR_gongxin = function(self,card_ids)
	self.MR_gongxinchoice = nil
	local target = self.player:getTag("MR_gongxin"):toPlayer()
	if not target or self:isFriend(target) then return -1 end
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
	until nextAlive:faceUp()

	local peach,ex_nihilo,jink,nullification,slash
	local valuable
	for _,id in sgs.list(card_ids)do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Peach") then peach = id end
		if card:isKindOf("ExNihilo") then ex_nihilo = id end
		if card:isKindOf("Jink") then jink = id end
		if card:isKindOf("Nullification") then nullification = id end
		if card:isKindOf("Slash") then slash = id end
	end
	valuable = peach or ex_nihilo or jink or nullification or slash or card_ids[1]
	local card = sgs.Sanguosha:getCard(valuable)
	if self:isEnemy(target) then
		self.MR_gongxinchoice = "obtain"
		return valuable
	end

	local willUseExNihilo,willRecast
	if self:getCardsNum("ExNihilo")>0 then
		local ex_nihilo = self:getCard("ExNihilo")
		if ex_nihilo then
			local dummy_use = dummy()
			self:useTrickCard(ex_nihilo,dummy_use)
			if dummy_use.card then willUseExNihilo = true end
		end
	elseif self:getCardsNum("IronChain")>0 then
		local iron_chain = self:getCard("IronChain")
		if iron_chain then
			local dummy_use = dummy()
			self:useTrickCard(iron_chain,dummy_use)
			if dummy_use.card and dummy_use.to:isEmpty() then willRecast = true end
		end
	end
	if willUseExNihilo or willRecast then
		local card = sgs.Sanguosha:getCard(valuable)
		if card:isKindOf("Peach") then
			self.MR_gongxinchoice = "put"
			return valuable
		end
		if card:isKindOf("TrickCard") or card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage") then
			local dummy_use = dummy()
			self:useTrickCard(card,dummy_use)
			if dummy_use.card then
				self.MR_gongxinchoice = "put"
				return valuable
			end
		end
		if card:isKindOf("Jink") and self:getCardsNum("Jink")==0 then
			self.MR_gongxinchoice = "put"
			return valuable
		end
		if card:isKindOf("Nullification") and self:getCardsNum("Nullification")==0 then
			self.MR_gongxinchoice = "put"
			return valuable
		end
		if card:isKindOf("Slash") and self:slashIsAvailable() then
			local dummy_use = dummy()
			self:useBasicCard(card,dummy_use)
			if dummy_use.card then
				self.MR_gongxinchoice = "put"
				return valuable
			end
		end
		self.MR_gongxinchoice = "discard"
		return valuable
	end

	local hasLightning,hasIndulgence,hasSupplyShortage
	local tricks = nextAlive:getJudgingArea()
	if not tricks:isEmpty() and not nextAlive:containsTrick("YanxiaoCard") then
		local trick = tricks:at(tricks:length()-1)
		if self:hasTrickEffective(trick,nextAlive) then
			if trick:isKindOf("Lightning") then hasLightning = true
			elseif trick:isKindOf("Indulgence") then hasIndulgence = true
			elseif trick:isKindOf("SupplyShortage") then hasSupplyShortage = true
			end
		end
	end

	if self:isEnemy(nextAlive) and nextAlive:hasSkill("luoshen") and valuable then
		self.MR_gongxinchoice = "put"
		return valuable
	end
	if nextAlive:hasSkill("yinghun") and nextAlive:isWounded() then
		self.MR_gongxinchoice = self:isFriend(nextAlive) and "put" or "discard"
		return valuable
	end
	if target:hasSkill("hongyan") and hasLightning and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum()>0) then
		for _,id in sgs.list(card_ids)do
			local card = sgs.Sanguosha:getEngineCard(id)
			if card:getSuit()==sgs.Card_Spade and card:getNumber()>=2 and card:getNumber()<=9 then
				self.MR_gongxinchoice = "put"
				return id
			end
		end
	end
	if hasIndulgence and self:isFriend(nextAlive) then
		self.MR_gongxinchoice = "put"
		return valuable
	end
	if hasSupplyShortage and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum()>0) then
		local enemy_null = 0
		for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
			if self:isFriend(p) then enemy_null = enemy_null-getCardsNum("Nullification",p) end
			if self:isEnemy(p) then enemy_null = enemy_null+getCardsNum("Nullification",p) end
		end
		enemy_null = enemy_null-self:getCardsNum("Nullification")
		if enemy_null<0.8 then
			self.MR_gongxinchoice = "put"
			return valuable
		end
	end

	if self:isFriend(nextAlive) and not self:willSkipDrawPhase(nextAlive) and not self:willSkipPlayPhase(nextAlive)
		and not nextAlive:hasSkill("luoshen")
		and not nextAlive:hasSkill("tuxi") and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum()>0) then
		if (peach and valuable==peach) or (ex_nihilo and valuable==ex_nihilo) then
			self.MR_gongxinchoice = "put"
			return valuable
		end
		if jink and valuable==jink and getCardsNum("Jink",nextAlive)<1 then
			self.MR_gongxinchoice = "put"
			return valuable
		end
		if nullification and valuable==nullification and getCardsNum("Nullification",nextAlive)<1 then
			self.MR_gongxinchoice = "put"
			return valuable
		end
		if slash and valuable==slash and self:hasCrossbowEffect(nextAlive) then
			self.MR_gongxinchoice = "put"
			return valuable
		end
	end

	local card = sgs.Sanguosha:getCard(valuable)
	local keep = false
	if card:isKindOf("Slash") or card:isKindOf("Jink")
		or card:isKindOf("EquipCard")
		or card:isKindOf("Disaster") or card:isKindOf("GlobalEffect") or card:isKindOf("Nullification")
		or target:isLocked(card) then
		keep = true
	end
	self.MR_gongxinchoice = "obtain"
	return valuable
end

sgs.ai_skill_choice.MR_gongxin = function(self,choices)
	return self.MR_gongxinchoice or "discard"
end

sgs.ai_use_value.MR_gongxin = 8.5
sgs.ai_use_priority.MR_gongxin = 9.5
sgs.ai_card_intention.MR_gongxin = 80


sgs.ai_skill_choice.MR_qingshi = function(self,choices,data)
	local items = choices:split("+")
	local use = data:toCardUse()
	if table.contains(items,"2")
	and #self.toUse>3 then 
		local good = 0
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if not use.to:contains(p) and self:canDraw(p, self.player) then 
				if self:isFriend(p) then 
					good = good + 1
				else
					good = good - 1
				end 
			end
		end
		if good > 0 then
			return "2" 
		end
	end
	if table.contains(items,"1") and use.card:isDamageCard() then
		for _, p in sgs.qlist(use.to) do
			if self:isFriend(p) or self:cantDamageMore(use.from, p) then
				break
			else
				return "1"
			end
		end
	end
	for _,c in sgs.list(items)do
		if c:startsWith("3")
		then return c 
		end
	end
	return items[1]
end

sgs.ai_ajustdamage_from.MR_qingshi = function(self, from, to, card, nature)
	if card and card:hasFlag("mrqingshi") then
		return 1
	end
end


local MR_zhizhe_skill = {}
MR_zhizhe_skill.name = "MR_zhizhe"
table.insert(sgs.ai_skills, MR_zhizhe_skill)
MR_zhizhe_skill.getTurnUseCard = function(self, inclusive)
	self:updatePlayers()
	if self.player:isNude() then return end

	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(handcards, true)
	for _,c in ipairs(handcards) do
		--local poi = sgs.Sanguosha:cloneCard(c, sgs.Card_NoSuit, -1)
		if c:isAvailable(self.player) and (c:isKindOf("BasicCard") or c:isNDTrick()) and self.player:getMark(c:objectName().."+MR_zhizhe-Clear") < 1 then
			local dummy_use = self:aiUseCard(c, dummy())
			if dummy_use.card and not (c:canRecast() and dummy_use.to:isEmpty()) then 
				return sgs.Card_Parse(c:objectName()..":MR_zhizhe[no_suit:0]=.")
			end
		end
	end
end