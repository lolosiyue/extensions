
local Dragon_rende_skill = {}
Dragon_rende_skill.name = "Dragon_rende"
table.insert(sgs.ai_skills,Dragon_rende_skill)
Dragon_rende_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	--if self:shouldUseRende() then
		return sgs.Card_Parse("#Dragon_rendeCard:.:")
	--end
end

sgs.ai_skill_use_func["#Dragon_rendeCard"] = function(card,use,self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	local notFound = false
	for i = 1,self.player:getHandcardNum() do
		local h,friend = self:getCardNeedPlayer(cards)
		if h and friend then cards = self:resetCards(cards,h)
		else notFound = true break end
		if friend==self.player or not self.player:handCards():contains(h:getEffectiveId()) then continue end
		local canJijiang = self.player:hasLordSkill("jijiang") and friend:getKingdom()=="shu"
		if h:isAvailable(self.player)
		and (h:isKindOf("Slash") and not canJijiang or h:isKindOf("Duel") or h:isKindOf("Snatch") or h:isKindOf("Dismantlement")) then
			local dummy_use = self:aiUseCard(h)
			if dummy_use.card then
				if h:isKindOf("Slash") or h:isKindOf("Duel") then
					local t1 = dummy_use.to:first()
					if dummy_use.to:length()>1 then continue
					elseif t1:getHp()<2 or getCardsNum("Jink", t1, self.player) < 1
					or t1:isCardLimited(dummyCard("jink"),sgs.Card_MethodResponse)
					then continue end
				elseif self:getEnemyNumBySeat(self.player,friend)>0 then
					local hasDelayedTrick
					for _,p in sgs.qlist(dummy_use.to)do
						if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p))
						then hasDelayedTrick = true break end
					end
					if hasDelayedTrick then continue end
				end
			end
		elseif h:isAvailable(self.player)
		and (h:isKindOf("Indulgence") or h:isKindOf("SupplyShortage"))
		and self:getEnemyNumBySeat(self.player,friend)>0
		and self:aiUseCard(h).card then continue end
		if #cards>1 and friend:hasSkill("enyuan")
		and not(self.room:getMode()=="04_1v3" and self.player:getMark("Dragon_rende")==1)
		then use.card = sgs.Card_Parse("#Dragon_rendeCard:"..h:getId().."+"..cards[1]:getId()..":")
		else use.card = sgs.Card_Parse("#Dragon_rendeCard:"..h:getId()..":") end
		use.to:append(friend)
		return
	end
	if notFound and self.player:isWounded()
	 and self.player:getMark("Dragon_rende")<2 then
		cards = self:sortByUseValue(self.player:getHandcards(),true)
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if not self:isFriend(p) and hasManjuanEffect(p) then
				local to_give = {}
				for _,h in ipairs(cards)do
					if not isCard("Peach,ExNihilo",h,self.player)
					then table.insert(to_give,h:getId()) end
					if #to_give>=2-self.player:getMark("Dragon_rende")
					then break end
				end
				if #to_give>0 then
					use.card = sgs.Card_Parse("#Dragon_rendeCard:"..table.concat(to_give,"+")..":")
					use.to:append(p)
					return
				end
			end
		end
	end
end

sgs.ai_use_value["Dragon_rendeCard"] = sgs.ai_use_value.RendeCard
sgs.ai_use_priority["Dragon_rendeCard"] = sgs.ai_use_priority.RendeCard

sgs.ai_card_intention["Dragon_rendeCard"] = sgs.ai_card_intention.RendeCard

sgs.dynamic_value.benefit["Dragon_rendeCard"] = true

sgs.ai_use_revises.Dragon_rende = function(self,card,use)
	if self.player:getLostHp()>1 and self:findFriendsByType(sgs.Friend_Draw)
	and self.player:getMark("Dragon_rende")<2
	and #self.friends_noself>0
	then
		if card:getTypeId()==1
		or card:getTypeId()==3 and self:getSameEquip(card)
		or card:getTypeId()==2 and not (card:targetFixed() and card:isDamageCard())
		then return false end
	end
	local xy = self:hasSkills("jieming|oljieming",self.friends_noself)
	if xy and card:isDamageCard() and self:getOverflow()<0
	and self:hasTrickEffective(card,xy,nil,use.to)
	and self:getAllPeachNum()>1
	then
		use.card = card
		use.to:append(xy)
	end
end




sgs.ai_view_as.Dragon_wusheng = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("slash:Dragon_wusheng[%s:%s]=%d"):format(suit,number,card_id)
	end
end

local Dragon_wusheng_skill = {}
Dragon_wusheng_skill.name = "Dragon_wusheng"
table.insert(sgs.ai_skills,Dragon_wusheng_skill)
Dragon_wusheng_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("he")
	cards = self:sortByUseValue(cards,true)
	local red_card = {}
	local useAll = false
	self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<2 and not enemy:hasArmorEffect("EightDiagram")
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end
	self:sort(self.enemies,"defense")

	for _,card in ipairs(cards)do
		if card:isRed() and not card:isKindOf("Slash") 	and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,dummyCard())>0)
		then table.insert(red_card,card) end
	end


	for _,card in ipairs(red_card)do
		local slash = dummyCard("slash")
		slash:addSubcard(card)
		slash:setSkillName("Dragon_wusheng")
		if slash:isAvailable(self.player)
		then return slash end
	end
end

function sgs.ai_cardneed.Dragon_wusheng(to,card)
	return to:getHandcardNum()<3 and card:isRed()
end

sgs.ai_cardneed.Dragon_feijiang = sgs.ai_cardneed.paoxiao
sgs.double_slash_skill = sgs.double_slash_skill .. "|Dragon_feijiang"
sgs.ai_use_revises.Dragon_feijiang = function(self,card,use)
	if card:isKindOf("Crossbow")
	then return false end
end

local Dragon_feijiang_skill = {}
Dragon_feijiang_skill.name = "Dragon_feijiang"
table.insert(sgs.ai_skills,Dragon_feijiang_skill)
Dragon_feijiang_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
        if self:getCardsNum("Slash") == 0 then return false end
        if #self.enemies == 0 then return false end
        if self.player:getMark("Dragon_feijiangFailed-PlayClear") > 0 then return false end
	return sgs.Card_Parse("#Dragon_feijiangCard:.:")
end

sgs.ai_skill_use_func["#Dragon_feijiangCard"] = function(card,use,self)
    use.card = card
end
sgs.need_kongcheng = sgs.need_kongcheng .. "|Dragon_kongcheng"

sgs.ai_target_revises.Dragon_kongcheng = function(to,card)
	if card:isKindOf("Slash") and to:isKongcheng()
	then return true end
end


function sgs.ai_cardneed.Dragon_jizhi(to,card)
	return card:isKindOf("TrickCard")
end

sgs.Dragon_jizhi_keep_value = sgs.jizhi_keep_value

sgs.ai_card_priority.Dragon_jizhi = function(self,card,v)
	if self.useValue
	and card:isKindOf("TrickCard")
	then v = v+3 end
end

sgs.ai_skill_discard.Dragon_zhiheng = function(self)
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
        if self:getKeepValue(card)<5 then
		    table.insert(to_discard, card:getEffectiveId())
        end
	end
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end


local Dragon_fuyuanVS_skill = {}
Dragon_fuyuanVS_skill.name = "Dragon_fuyuanVS"
table.insert(sgs.ai_skills, Dragon_fuyuanVS_skill)
Dragon_fuyuanVS_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("Dragon_fuyuan") then return nil end
	if self.player:getKingdom() ~= "wu" then return nil end

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
        card = acard
        break
	end
	if not card then return nil end

	local card_id = card:getEffectiveId()
	local card_str = "#Dragon_fuyuanCard:" .. card_id .. ":"
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)
	return skillcard
end

sgs.ai_skill_use_func["#Dragon_fuyuanCard"] = function(card, use, self)
	if self:needBear() or self:getCardsNum("Jink", "h") <= 1 then
		return
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("Dragon_fuyuan") then
			if not friend:hasFlag("Dragon_fuyuanInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	elseif self:getCardsNum("Slash", "he") >= 2 then --黄天对方
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasLordSkill("Dragon_fuyuan") then
				if not enemy:hasFlag("Dragon_fuyuanInvoked") then
					if not hasManjuanEffect(enemy) then
						if enemy:isKongcheng() and not enemy:hasSkill("kongcheng") and not hasTuntianEffect(enemy, true) then --必须保证对方空城，以保证天义/陷阵的拼点成功
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if self.player:hasSkill("tianyi") and not self.player:hasUsed("TianyiCard") then
				flag = true
			elseif self.player:hasSkill("xianzhen") and not self.player:hasUsed("XianzhenCard") then
				flag = true
			end
			if flag then
				local maxCard = self:getMaxCard(self.player) --最大点数的手牌
				if maxCard:getNumber() > card:getNumber() then --可以保证拼点成功
					self:sort(targets, "defense", true)
					for _, enemy in ipairs(targets) do
						if self.player:canSlash(enemy, nil, false, 0) then --可以发动天义或陷阵
							use.card = card
							enemy:setFlags("AI_HuangtianPindian")
							if use.to then
								use.to:append(enemy)
							end
							break
						end
					end
				end
			end
		end
	end
end

sgs.ai_card_intention["Dragon_fuyuanCard"] = function(self, card, from, tos)
	if tos[1]:isKongcheng() and ((from:hasSkill("tianyi") and not from:hasUsed("TianyiCard"))
			or (from:hasSkill("xianzhen") and not from:hasUsed("XianzhenCard"))) then
	else
		sgs.updateIntention(from, tos[1], -80)
	end
end

sgs.ai_use_priority["Dragon_fuyuanCard"] = 10
sgs.ai_use_value["Dragon_fuyuanCard"] = 8.5

local tongling_skill={}
tongling_skill.name="tongling"
table.insert(sgs.ai_skills,tongling_skill)
tongling_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getMark("@bell") == 0 then return end
    return sgs.Card_Parse("#tonglingCard:.:")
end

sgs.ai_skill_use_func["#tonglingCard"]=function(card,use,self)
	use.card=card
end
sgs.ai_event_callback[sgs.CardFinished].tonglingCard = function(self, player, data)
	local use = data:toCardUse()
	if use.card and use.card:objectName() == "tonglingCard" then
        sgs.roleValue[player:objectName()]["renegade"] = 0
        sgs.roleValue[player:objectName()]["loyalist"] = 0
        sgs.roleValue[player:objectName()][player:getRole()] = 1000
        sgs.ai_role[player:objectName()] = player:getRole()
    end
end


sgs.ai_use_revises.Dragon_keji = function(self,card,use)
	if card:isKindOf("Slash") and not self:hasCrossbowEffect()
	and (#self.enemies>1 or #self.friends>1) and self:getOverflow()>1
	then return false end
end


local Dragon_kurou_skill={}
Dragon_kurou_skill.name="Dragon_kurou"
table.insert(sgs.ai_skills,Dragon_kurou_skill)
Dragon_kurou_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getHp()==1 then return end
	--特殊场景
	local func = Tactic("Dragon_kurou",self,nil)
	if func then return func(self,nil) end
	--一般场景
	sgs.ai_use_priority.Dragon_kurouCard = 6.8
	local losthp = isLord(self.player) and 0 or 1
	if ((self.player:getHp()>3 and self.player:getLostHp()<=losthp and self.player:getHandcardNum()>self.player:getHp())
		or (self.player:getHp()-self.player:getHandcardNum()>=2)) and not (isLord(self.player) and sgs.turncount<=1) then
		return sgs.Card_Parse("#Dragon_kurouCard:.:")
	end
	local slash = dummyCard()
	if self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow")
	or self.player:hasSkill("paoxiao") then
		for _,enemy in ipairs(self.enemies)do
			if self.player:canSlash(enemy,slash,true) and self:slashIsEffective(slash,enemy)
				and not (enemy:hasSkill("kongcheng") and enemy:isKongcheng())
				and not (enemy:hasSkills("Dragon_fankui|guixin") and not self.player:hasSkill("paoxiao"))
				and not enemy:hasSkills("fenyong|jilei|zhichi")
				and self:isGoodTarget(enemy,self.enemies,slash) and not self:slashProhibit(slash,enemy) and self.player:getHp()>1 then
				return sgs.Card_Parse("#Dragon_kurouCard:.:")
			end
		end
	end
	if self.player:getHp()==1 and self:getCardsNum("Analeptic")>=1 then
		return sgs.Card_Parse("#Dragon_kurouCard:.:")
	end

	--Suicide by Dragon_kurou
	local nextplayer = self.player:getNextAlive()
	if self.player:getHp()==1 and self.player:getRole()~="lord" and self.player:getRole()~="renegade" then
		local to_death = false
		if self:isFriend(nextplayer) then
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
				if p:hasSkill("xiaoguo") and not self:isFriend(p) and not p:isKongcheng()
					and self.role=="rebel" and self.player:getEquips():isEmpty() then
					to_death = true
					break
				end
			end
			if not to_death and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkill("jieyin") and self.player:isMale() then return end
				if nextplayer:hasSkill("qingnang") then return end
			end
		end
		if self.player:getRole()=="rebel" and not self:isFriend(nextplayer) then
			if not self:willSkipPlayPhase(nextplayer) or nextplayer:hasSkill("shensu") then
				to_death = true
			end
		end
		local lord = getLord(self.player)
		if self.player:getRole()=="loyalist" then
			if lord and lord:getCards("he"):isEmpty() then return end
			if self:isEnemy(nextplayer) and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkills("noslijian|lijian") and self.player:isMale() and lord and lord:isMale() then
					to_death = true
				elseif nextplayer:hasSkill("quhu") and lord and lord:getHp()>nextplayer:getHp() and not lord:isKongcheng()
					and lord:inMyAttackRange(self.player) then
					to_death = true
				end
			end
		end
		if to_death then
			local caopi = self.room:findPlayerBySkillName("xingshang")
			if caopi and self:isEnemy(caopi) then
				if self.player:getRole()=="rebel" and self.player:getHandcardNum()>3 then to_death = false end
				if self.player:getRole()=="loyalist" and lord and lord:getCardCount(true)+2<=self.player:getHandcardNum() then
					to_death = false
				end
			end
			if #self.friends==1 and #self.enemies==1 and self.player:aliveCount()==2 then to_death = false end
		end
		if to_death then
			self.player:setFlags("kurou_toDie")
			sgs.ai_use_priority.Dragon_kurouCard = 0
			return sgs.Card_Parse("#Dragon_kurouCard:.:")
		end
		self.player:setFlags("-kurou_toDie")
	end
end

sgs.ai_skill_use_func["#Dragon_kurouCard"]=function(card,use,self)
	if not use.isDummy then self:speak("kurou") end
	use.card=card
end

sgs.ai_use_priority["Dragon_kurouCard"] = 6.8




Dragon_jiedao_skill = {}
Dragon_jiedao_skill.name = "Dragon_jiedao"
table.insert(sgs.ai_skills, Dragon_jiedao_skill)
Dragon_jiedao_skill.getTurnUseCard          = function(self, inclusive)
	if self.player:hasUsed("#Dragon_jiedaoCard") then return end
	return sgs.Card_Parse("#Dragon_jiedaoCard:.:")
end

sgs.ai_skill_use_func["#Dragon_jiedaoCard"] = function(card, use, self)
	self:sort(self.friends_noself, "defense")
	for _, p in ipairs(self.friends_noself) do
		if self:hasSkill(sgs.lose_equip_skill, p) and p:getWeapon() then
            use.card = card
            if use.to then use.to:append(p) end
            return
		end
	end
	self:sort(self.enemies, "defense")
	for _, p in ipairs(self.enemies) do
		if not self:hasSkill(sgs.lose_equip_skill, p) and p:getWeapon() then
            use.card = card
            if use.to then use.to:append(p) end
            return
		end
	end
    for _, p in ipairs(self.friends_noself) do
		if p:getWeapon() then
            use.card = card
            if use.to then use.to:append(p) end
            return
		end
	end
end

sgs.ai_use_value["Dragon_jiedaoCard"]       = 8
sgs.ai_use_priority["Dragon_jiedaoCard"]    = 8
sgs.ai_card_intention["Dragon_jiedaoCard"]  = function(self,card,from,tos)
	local to = tos[1]
	if self:hasSkill(sgs.lose_equip_skill, to) then
		sgs.updateIntention(from,to,-80)
	else
		sgs.updateIntention(from,to,20)
	end
end

local Dragon_guose_skill={}
Dragon_guose_skill.name="Dragon_guose"
table.insert(sgs.ai_skills,Dragon_guose_skill)
Dragon_guose_skill.getTurnUseCard=function(self,inclusive)
	local cards = self:addHandPile("he")
	local card
	self:sortByUseValue(cards,true)
	local has_weapon,has_armor = false,false
	for _,acard in ipairs(cards)  do
		if acard:isKindOf("Weapon") and not (acard:getSuit()==sgs.Card_Diamond) then has_weapon=true end
	end
	for _,acard in ipairs(cards)  do
		if acard:isKindOf("Armor") and not (acard:getSuit()==sgs.Card_Diamond) then has_armor=true end
	end
	for _,acard in ipairs(cards)  do
		if (acard:getSuit()==sgs.Card_Diamond) and ((self:getUseValue(acard)<sgs.ai_use_value.Indulgence) or inclusive) then
			local shouldUse=true
			if acard:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(acard) and not has_armor and self:evaluateArmor()>0 then shouldUse = false
				end
			end
			if acard:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self.player:hasEquip(acard) and not has_weapon then shouldUse = false
				end
			end
			if shouldUse then
				card = acard
				break
			end
		end
	end
	if not card then return nil end
	return sgs.Card_Parse("Dragon_indulgence:Dragon_guose[no_suit:0]="..card:getEffectiveId())
end

function sgs.ai_cardneed.Dragon_guose(to,card)
	return card:getSuit()==sgs.Card_Diamond
end


sgs.ai_skill_invoke.Dragon_fankui = function(self,data)
	local target = data:toPlayer()
	if sgs.ai_need_damaged.Dragon_fankui(self,target,self.player) then return true end
	return self:doDisCard(target,"h", true)
end

sgs.ai_choicemade_filter.cardChosen.Dragon_fankui = function(self,player,promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from then
		local intention = 10
		local card = sgs.Sanguosha:getCard(promptlist[3])
		if not self:doDisCard(damage.from,"h") then intention = -intention
		elseif sgs.ai_need_damaged.Dragon_fankui(self,damage.from,player)
		or self:getOverflow(damage.from)>2
		then intention = 0 end
		sgs.updateIntention(player,damage.from,intention)
	end
end

sgs.ai_skill_cardchosen.Dragon_fankui = function(self,who,flags)
	local suit = sgs.ai_need_damaged.Dragon_fankui(self,who,self.player)
	if not suit then return -1 end

	local cards = {}
	local handcards = sgs.QList2Table(who:getHandcards())
	if #handcards==1 and handcards[1]:hasFlag("visible") then table.insert(cards,handcards[1]) end

	for i=1,#cards,1 do
		if (cards[i]:getSuit()==suit and suit~=sgs.Card_Spade) or
			(cards[i]:getSuit()==suit and suit==sgs.Card_Spade and cards[i]:getNumber()>=2 and cards[i]:getNumber()<=9) then
			return cards[i]:getId()
		end
	end
	return -1
end

sgs.ai_can_damagehp.Dragon_fankui = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and self:isWeak(from) and not from:isKongcheng()
	end
end

sgs.ai_need_damaged.Dragon_fankui = function (self,attacker,player)
	if not player:hasSkills("guicai+Dragon_fankui") then return false end
	if not attacker then return end
	local need_retrial = function(target)
		local alive_num = self.room:alivePlayerCount()
		return alive_num+target:getSeat() % alive_num>self.room:getCurrent():getSeat()
				and target:getSeat()<alive_num+player:getSeat() % alive_num
	end
	local retrial_card ={["spade"]=nil,["heart"]=nil,["club"]=nil}
	local attacker_card ={["spade"]=nil,["heart"]=nil,["club"]=nil}

	local handcards = sgs.QList2Table(player:getHandcards())
	for i=1,#handcards,1 do
		if handcards[i]:getSuit()==sgs.Card_Spade and handcards[i]:getNumber()>=2 and handcards[i]:getNumber()<=9 then
			retrial_card.spade = true
		end
		if handcards[i]:getSuit()==sgs.Card_Heart then
			retrial_card.heart = true
		end
		if handcards[i]:getSuit()==sgs.Card_Club then
			retrial_card.club = true
		end
	end

	local cards = {}
	local handcards = sgs.QList2Table(attacker:getHandcards())
	if #handcards==1 and handcards[1]:hasFlag("visible") then table.insert(cards,handcards[1]) end

	for i=1,#cards,1 do
		if cards[i]:getSuit()==sgs.Card_Spade and cards[i]:getNumber()>=2 and cards[i]:getNumber()<=9 then
			attacker_card.spade = sgs.Card_Spade
		end
		if cards[i]:getSuit()==sgs.Card_Heart then
			attacker_card.heart = sgs.Card_Heart
		end
		if cards[i]:getSuit()==sgs.Card_Club then
			attacker_card.club = sgs.Card_Club
		end
	end

	local players = self.room:getOtherPlayers(player)
	for _,aplayer in sgs.list(players)do
		if aplayer:containsTrick("lightning") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) then
			if not retrial_card.spade and attacker_card.spade then return attacker_card.spade end
		end

		if self:isFriend(aplayer,player) and not aplayer:containsTrick("YanxiaoCard") and not aplayer:hasSkill("qiaobian") then
			if aplayer:containsTrick("indulgence") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) and aplayer:getHandcardNum()>=aplayer:getHp() then
				if not retrial_card.heart and attacker_card.heart then return attacker_card.heart end
			end
			if aplayer:containsTrick("supply_shortage") and self:getFinalRetrial(aplayer)==1 and need_retrial(aplayer) and self:hasSkills("yongshi",aplayer) then
				if not retrial_card.club and attacker_card.club then return attacker_card.club end
			end
		end
	end
	return false
end




sgs.ai_skill_invoke.Dragon_ganglie = function(self,data)
	local mode = self.room:getMode()
	if mode:find("_mini_41") or mode:find("_mini_46") then return true end
	local damage = data:toDamage()
	if not damage.from then
		local zhangjiao = self.room:findPlayerBySkillName("guidao")
		return zhangjiao and self:isFriend(zhangjiao) and not zhangjiao:isNude()
	end
	if self:needToLoseHp(damage.from,self.player,damage.card) then
		if self:isFriend(damage.from) then
			return true
		end
		return false
	end
	return not self:isFriend(damage.from) and self:canAttack(damage.from)
end

-- sgs.ai_need_damaged.Dragon_ganglie = function(self,attacker,player)
-- 	if not attacker then return end
-- 	if self:needToLoseHp(attacker,player) and not attacker:hasSkill("Dragon_ganglie") then return self:isFriend(attacker,player) end
-- 	if self:isEnemy(attacker) and attacker:getHp()+attacker:getHandcardNum()<=3
-- 	and not (self:hasSkills(sgs.need_kongcheng.."|buqu",attacker) and attacker:getHandcardNum()>1) and self:isGoodTarget(attacker,self:getEnemies(attacker)) 
-- 	then
-- 		return true
-- 	end
-- 	return false
-- end

sgs.ai_skill_discard.Dragon_ganglie = function(self,discard_num,min_num,optional,include_equip)
	return nosganglie_discard(self,discard_num,min_num,optional,include_equip,"Dragon_ganglie")
end

function sgs.ai_slash_prohibit.Dragon_ganglie(self,from,to)
	if self:isFriend(from,to) then return false end
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to)==1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	return from:getHandcardNum()+from:getHp()<4
end

sgs.ai_choicemade_filter.skillInvoke.Dragon_ganglie = function(self,player,promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if promptlist[#promptlist]=="yes" then
			if not self:needToLoseHp(damage.from,player,damage.card) then
				sgs.updateIntention(damage.to,damage.from,40)
			end
		elseif self:canAttack(damage.from) then
			sgs.updateIntention(damage.to,damage.from,-40)
		end
	end
end

sgs.ai_cardneed.Dragon_luoyi = sgs.ai_cardneed.slash
sgs.ai_ajustdamage_from.Dragon_luoyi = function(self,from,to,card,nature)
	if not from:getWeapon() and card and card:isKindOf("Slash")
	then return 1 end
end

sgs.ai_view_as.Dragon_qingguo = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceHand then
		return ("jink:Dragon_qingguo[%s:%s]=%d"):format(suit,number,card_id)
	end
end

function sgs.ai_cardneed.Dragon_qingguo(to,card)
	return to:getCards("h"):length()<2 
end



local Dragon_qingnang_skill = {}
Dragon_qingnang_skill.name = "Dragon_qingnang"
table.insert(sgs.ai_skills,Dragon_qingnang_skill)
Dragon_qingnang_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum()<1 then return nil end
    if not self.player:isWounded() then return nil end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	local compare_func = function(a,b)
		local v1 = self:getKeepValue(a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
		return v1<v2
	end
	table.sort(cards,compare_func)

	return sgs.Card_Parse("#Dragon_qingnangCard:"..cards[1]:getId()..":")
end

sgs.ai_skill_use_func["#Dragon_qingnangCard"] = function(card,use,self)

	if self.player:getHp()<getBestHp(self.player) then 
        use.card = card
        return end
end

sgs.ai_use_priority["Dragon_qingnangCard"] = 4.2
sgs.ai_card_intention["Dragon_qingnangCard"] = -100

sgs.dynamic_value.benefit["Dragon_qingnangCard"] = true


sgs.ai_skill_cardask["@Dragon_jijiu"] = function(self,data,pattern)
	local dmg = data:toDamage()
	local invoke
	if self:isFriend(dmg.to) then
		if self:damageStruct(dmg) and not self:needToLoseHp(dmg.to,dmg.from,dmg.card)
		then invoke = true end
	end
	if invoke then
		local equipCards = {}
		for _,c in sgs.qlist(self.player:getCards("h"))do
			if c:isRed() and self.player:canDiscard(self.player,c:getEffectiveId()) then
				table.insert(equipCards,c)
			end
		end
		if #equipCards>0 then
			self:sortByKeepValue(equipCards)
			return equipCards[1]:getEffectiveId()
		end
	end
	return "."
end


sgs.hit_skill = sgs.hit_skill .. "|Dragon_wushuang"
sgs.ai_cardneed.Dragon_wushuang = sgs.ai_cardneed.slash

sgs.ai_skill_discard.Dragon_wushuang = function(self,x,n,o,e,p)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_cards = {}
	local cp = self.room:getCurrent()
   	for i,c in sgs.list(cards)do
		if ((not self:isEnemy(cp) and not self:needToLoseHp(self.player)) or self:isWeak()) and not c:isKindOf("Peach") then
			table.insert(to_cards,c:getEffectiveId())
			break
		end
	end
	return to_cards
end

sgs.ai_use_revises.Dragon_qiankun = function(self,card,use)
	if card:isKindOf("Slash") or card:isNDTrick() then
		card:setFlags("Qinggang")
	end
end
sgs.weapon_range.Dragon_double_sword = 2
sgs.weapon_range.Dragon_blade = 3
sgs.weapon_range.Dragon_spear = 3
sgs.weapon_range.Dragon_axe = 3
sgs.weapon_range.Dragon_kylin_bow = 5

sgs.ai_view_as.Dragon_spear = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and not card:isKindOf("Peach") and not card:hasFlag("using") and player:getMark("Equips_Nullified_to_Yourself") == 0 and player:getHp() > 2 and player:hasFlag("Dragon_spear") then
		return ("slash:Dragon_spear[%s:%s]=%d"):format(suit,number,card_id)
	end
end

sgs.ai_skill_invoke.Dragon_kylin_bowSkill = function(self,data)
	local damage = data:toDamage()
	if damage.from:hasSkill("kuangfu") and damage.to:getCards("e"):length()==1 then return false end
	if self:hasSkills(sgs.lose_equip_skill,damage.to) then
		return self:isFriend(damage.to)
	end
	return self:isEnemy(damage.to)
end


sgs.ai_skill_invoke.Promote_tieji = sgs.ai_skill_invoke.nostieji
sgs.hit_skill = sgs.hit_skill .. "|Promote_tieji"
sgs.ai_cardneed.Promote_tieji = sgs.ai_cardneed.slash


function sgs.ai_cardneed.Promote_jizhi(to,card)
	return card:isKindOf("TrickCard")
end

sgs.Promote_jizhi_keep_value = sgs.jizhi_keep_value

sgs.ai_card_priority.Promote_jizhi = function(self,card,v)
	if self.useValue
	and card:isKindOf("TrickCard")
	then v = v+3 end
end


local Promote_zhiheng_skill = {}
Promote_zhiheng_skill.name = "Promote_zhiheng"
table.insert(sgs.ai_skills,Promote_zhiheng_skill)
Promote_zhiheng_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#Promote_zhihengCard:.:")
end

sgs.ai_skill_use_func["#Promote_zhihengCard"] = function(card,use,self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self.player:getHp()<3 then
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _,zcard in sgs.list(self.player:getCards("he"))do
			if not isCard("Peach",zcard,self.player)
			then
				local shouldUse = true
				if isCard("Slash",zcard,self.player)
				and not use_slash
				then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.list(dummy_use.to)do
								if p:getHp()<=1 then
									shouldUse = false
									if self.player:distanceTo(p)>1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length()>1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId()==sgs.Card_TypeTrick then
					if self:aiUseCard(zcard).card then shouldUse = false end
				end
				if zcard:getTypeId()==sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					if self:aiUseCard(zcard).card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId()==keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp()<2 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards,zcard:getId()) end
			end
		end
	end

	if #unpreferedCards<1 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards)do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,card)
				then
					if self:aiUseCard(card).card then
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
			if card:isKindOf("Weapon") and self.player:getHandcardNum()<3
			or self:getSameEquip(card,self.player)
			or card:isKindOf("OffensiveHorse")
			or card:isKindOf("AmazingGrace")
			then table.insert(unpreferedCards,card:getId())
			elseif card:getTypeId()==sgs.Card_TypeTrick then
				if not self:aiUseCard(card).card then table.insert(unpreferedCards,card:getId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum()<3 then
			table.insert(unpreferedCards,self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards,self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards,self.player:getOffensiveHorse():getId())
		end
	end

	for i = #unpreferedCards,1,-1 do
		if sgs.Sanguosha:getCard(unpreferedCards[i]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then
			table.removeOne(unpreferedCards,unpreferedCards[i])
		end
	end

	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		if self.room:getMode()=="02_1v1" and sgs.GetConfig("1v1/Rule","Classical")~="Classical" then
			local use_cards_kof = {use_cards[1]}
			if #use_cards>1 then table.insert(use_cards_kof,use_cards[2]) end
			use.card = sgs.Card_Parse("#Promote_zhihengCard:"..table.concat(use_cards_kof,"+")..":")
		else
			use.card = sgs.Card_Parse("#Promote_zhihengCard:"..table.concat(use_cards,"+")..":")
		end
	end
end

sgs.ai_use_value["Promote_zhihengCard"] = 9
sgs.ai_use_priority["Promote_zhihengCard"] = 2.61
sgs.dynamic_value.benefit["Promote_zhihengCard"] = true


function sgs.ai_cardneed.Promote_zhiheng(to,card)
	return not card:isKindOf("Jink")
end

local Promote_jiuyuanVS_skill = {}
Promote_jiuyuanVS_skill.name = "Promote_jiuyuanVS"
table.insert(sgs.ai_skills, Promote_jiuyuanVS_skill)
Promote_jiuyuanVS_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getKingdom() ~= "wu" then return nil end

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Peach") then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = card:getEffectiveId()
	local card_str = "#Promote_jiuyuanCard:" .. card_id .. ":"
	local skillcard = sgs.Card_Parse(card_str)

	-- assert(skillcard)
	return skillcard
end
sgs.ai_skill_use_func["#Promote_jiuyuanCard"]=function(card,use,self)
    local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
    peach:deleteLater()
    for _,friend in ipairs(self.friends_noself)do
        if friend and friend:hasLordSkill("Promote_jiuyuan") then
            if peach:isAvailable(friend) and not self.player:isProhibited(friend, peach) then
                use.card = card
                use.to:append(friend)
                return
            end
        end
    end
end


local Promote_fanjian_skill = {}
Promote_fanjian_skill.name = "Promote_fanjian"
table.insert(sgs.ai_skills,Promote_fanjian_skill)
Promote_fanjian_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return nil end
	return sgs.Card_Parse("#Promote_fanjianCard:.:")
end

sgs.ai_skill_use_func["#Promote_fanjianCard"]=function(card,use,self)

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	if #cards==1 and cards[1]:getSuit()==sgs.Card_Diamond then return end
	if #cards<=4 and (self:getCardsNum("Peach")>0 or self:getCardsNum("Analeptic")>0) then return end
	self:sort(self.enemies,"hp")

	local suits = {}
	local suits_num = 0
	for _,c in ipairs(cards)do
		if not suits[c:getSuitString()] then
			suits[c:getSuitString()] = true
			suits_num = suits_num+1
		end
	end

	local wgt = self.room:findPlayerBySkillName("buyi")
	if wgt and self:isFriend(wgt) then wgt = nil end

	for _,enemy in ipairs(self.enemies)do
		local visible = 0
		for _,card in ipairs(cards)do
			local flag = string.format("%s_%s_%s","visible",enemy:objectName(),self.player:objectName())
			if card:hasFlag("visible") or card:hasFlag(flag) then visible = visible+1 end
		end
		if visible>0 and (#cards<=2 or suits_num<=2) then continue end
		if self:canAttack(enemy) and not enemy:hasSkills("qingnang|jijiu|tianxiang")
		and not (wgt and card:getTypeId()~=sgs.Card_Basic and (enemy:isKongcheng() or enemy:objectName()==wgt:objectName()))
		and self:damageIsEffective(enemy,card)
		then
			use.card = sgs.Card_Parse("#Promote_fanjianCard:.:")
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_card_intention["Promote_fanjianCard"] = 70

function sgs.ai_skill_suit.Promote_fanjian(self)
	local map = {0,0,1,2,2,3,3,3}
	local suit = map[math.random(1,8)]
	local tg = self.room:getCurrent()
	local suits = {}
	local maxnum,maxsuit = 0,nil
	for _,c in sgs.qlist(tg:getHandcards())do
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),tg:objectName())
		if c:hasFlag(flag) or c:hasFlag("visible") then
			if not suits[c:getSuitString()] then suits[c:getSuitString()] = 1 else suits[c:getSuitString()] = suits[c:getSuitString()]+1 end
			if suits[c:getSuitString()]>maxnum then
				maxnum = suits[c:getSuitString()]
				maxsuit = c:getSuit()
			end
		end
	end
	if self.player:hasSkill("hongyan") and (maxsuit==sgs.Card_Spade or suit==sgs.Card_Spade) then
		return sgs.Card_Heart
	end
	if maxsuit then
		if self.player:hasSkill("hongyan") and maxsuit==sgs.Card_Spade then return sgs.Card_Heart end
		return maxsuit
	else
		if self.player:hasSkill("hongyan") and suit==sgs.Card_Spade then return sgs.Card_Heart end
		return suit
	end
end

sgs.dynamic_value.damage_card.Promote_fanjianCard = true








sgs.ai_choicemade_filter.skillInvoke.Promote_ganglie = sgs.ai_choicemade_filter.skillInvoke.Dragon_ganglie

sgs.ai_slash_prohibit.Promote_ganglie = sgs.ai_slash_prohibit.Dragon_ganglie
sgs.ai_skill_discard.Promote_ganglie = sgs.ai_skill_discard.Dragon_ganglie 
sgs.ai_skill_invoke.Promote_ganglie = sgs.ai_skill_invoke.Dragon_ganglie

sgs.ai_ajustdamage_from.Promote_luoyi = function(self,from,to,card,nature)
	if from and from:hasFlag("Promote_luoyi") and card and (card:isKindOf("Slash") or card:isKindOf("Duel"))
	then return 1 end
end


sgs.ai_skill_invoke.Promote_luoyi = sgs.ai_skill_invoke.nosluoyi


sgs.ai_cardneed.Promote_luoyi = sgs.ai_cardneed.nosluoyi

sgs.Promote_luoyi_keep_value = sgs.nosluoyi_keep_value



local Promote_qingnang_skill = {}
Promote_qingnang_skill.name = "Promote_qingnang"
table.insert(sgs.ai_skills,Promote_qingnang_skill)
Promote_qingnang_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum()<1 then return nil end
    if not self.player:isWounded() then return nil end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	local compare_func = function(a,b)
		local v1 = self:getKeepValue(a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
		return v1<v2
	end
	table.sort(cards,compare_func)

	return sgs.Card_Parse("#Promote_qingnangCard:"..cards[1]:getId()..":")
end

sgs.ai_skill_use_func["#Promote_qingnangCard"] = function(card,use,self)

	if self.player:getHp()<getBestHp(self.player) then 
        use.card = card
        return end
end

sgs.ai_use_priority["Promote_qingnangCard"] = 4.2
sgs.ai_card_intention["Promote_qingnangCard"] = -100

sgs.dynamic_value.benefit["Promote_qingnangCard"] = true

sgs.ai_skill_playerchosen.Promote_luohan = function(self, targets)
	local lord = self.room:getLord()
	return lord
end

sgs.ai_skill_invoke.Promote_luohan = function(self,data)
	local dmg = data:toDamage()
	return self:damageStruct(dmg) and not self:needToLoseHp(dmg.to,dmg.from,dmg.card)
end

sgs.ai_skill_playerchosen.Promote_xuanwu = function(self, targets)
	self:sort(self.friends_noself, "hp")
	for _, friend in ipairs(self.friends_noself) do
		return friend
	end
	return targets[1]
end
sgs.ai_skill_invoke.Promote_xuanwu = function(self,data)
	if math.random(1, 5) > 3 then return true else return false end
end
sgs.ai_skill_playerchosen.Promote_zhuyou = function(self, targets)
	self:sort(self.friends_noself, "hp")
	for _, friend in ipairs(self.friends_noself) do
		return friend
	end
	return targets[1]
end
sgs.ai_skill_invoke.Promote_zhuyou = function(self,data)
	if math.random(1, 5) > 3 then return true else return false end
end

function SmartAI:useCardDragonPeach(card,use)
	for _,enemy in sgs.list(self.enemies)do
		if self.player:getHandcardNum()<3 and enemy:hasSkills(sgs.drawpeach_skill
		or getCardsNum("Dismantlement",enemy)>0
		or enemy:hasSkill("jixi") and enemy:distanceTo(self.player)<2
		or enemy:hasSkill("qixi") and getKnownCard(enemy,self.player,"black",nil,"he")>0
		or getCardsNum("Snatch",enemy)>0 and enemy:distanceTo(self.player)==1
		or enemy:hasSkill("tiaoxin") and (self.player:inMyAttackRange(enemy) and self:getCardsNum("Slash")<1 or not self.player:canSlash(enemy)))
		then use.card = card use.to:append(self.player) return end
	end
	local arr1,arr2 = self:getWoundedFriend(false,true)
	local target = nil

	if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and arr1[1]:getHp()<getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		use.card = card
		use.to:append(target)
		return
	end
	for _,friend in ipairs(arr2)do
		if not friend:hasSkills("hunzi|longhun") then
			use.card = card
			use.to:append(friend)
			return
		end
	end
	local lord = getLord(self.player)
	if not(lord and self:isFriend(lord) and self:isWeak(lord)) and self.player:getHp()<2
	or self.player:getLostHp()>=2 and hasWulingEffect("@water")
	or self:getCardsNum("DragonPeach","h")>self.player:getHp()
	or not self.player:hasCard(card)
	then use.card = card use.to:append(self.player) return end
	local of = self:getOverflow()
	if of<1 and #self.friends_noself>0
	or self:needToLoseHp(self.player,nil,card,nil,true)
	then return end
	if lord and lord:getHp()<=2 and self:isFriend(lord)
	and self:isWeak(lord) then
		if self.player==lord
		or self:getCardsNum("DragonPeach")>1 and self:getCardsNum("DragonPeach,Jink")>self.player:getMaxCards()
		then use.card = card use.to:append(self.player) end
		return
	end
	self:sort(self.friends,"hp")
	if #self.friends>0 and self.friends[1]==self.player
	or self.player:getHp()<2 then use.card = card return end
	if #self.friends>1 and (not hasBuquEffect(self.friends[2]) and self.friends[2]:getHp()<3 and of<2
	or not hasBuquEffect(self.friends[1]) and self.friends[1]:getHp()<2 and self:getCardsNum("DragonPeach","h")<=1 and of<3)
	then return end
	use.card = card
	use.to:append(self.player)
end

sgs.ai_card_intention.DragonPeach = function(self,card,from,tos)
	for _,to in sgs.list(tos)do
		if to:hasSkill("wuhun") then continue end
		if not isRolePredictable() and from:objectName()~=to:objectName()
		and sgs.playerRoles["renegade"]>0 and sgs.ai_role[to:objectName()]=="rebel"
		and (sgs.ai_role[from:objectName()]=="loyalist" or sgs.ai_role[from:objectName()]=="renegade") then
			outputRoleValues(from,100)
			sgs.roleValue[from:objectName()]["renegade"] = sgs.roleValue[from:objectName()]["renegade"]+100
			outputRoleValues(from,100)
		end
		sgs.updateIntention(from,to,-120)
	end
end

sgs.ai_use_value.DragonPeach = 6
sgs.ai_keep_value.DragonPeach = 7
sgs.ai_use_priority.DragonPeach = 0.9

function SmartAI:useCardDragonCollateral(card,use)
	local fromList = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	local cmps = {}
	for _,p in ipairs(fromList)do
		cmps[p:objectName()] = self:objectiveLevel(p)
	end
	local cmp = function(a,b)
		local al = cmps[a:objectName()]
		local bl = cmps[b:objectName()]
		if al~=bl then return al>bl end
		return a:getHandcardNum()<b:getHandcardNum()
	end
	table.sort(fromList,cmp)
	function useToCard(to)
		return to:getWeapon()
		and not(use.to:contains(to) or isCurrent(use,to)
		or self.player:isProhibited(to,card))
	end
	local extraTarget = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	
	if not self:hasCrossbowEffect() and self:getCardsNum("Slash")>2 then
		for _,from in ipairs(sgs.reverse(fromList))do
			if from:hasWeapon("Crossbow")
			and useToCard(from) then
				use.card = card
				use.to:append(from)
				if use.to:length()>extraTarget
				then return end
			end
		end
	end
	
	for _,enemy in ipairs(fromList)do
		if useToCard(enemy) and self:objectiveLevel(enemy)>=0
		and not(self:loseEquipEffect(enemy) or enemy:hasSkill("tuntian+zaoxian")) then
			use.card = card
			use.to:append(enemy)
			if use.to:length()>extraTarget
			then return end
		end
	end
	for _,friend in ipairs(fromList)do
		if useToCard(friend) and self:objectiveLevel(friend)<0 then
			use.card = card
			use.to:append(friend)
			if use.to:length()>extraTarget
			then return end	
		end
	end
	for _,friend in ipairs(fromList)do
		if useToCard(friend) and self:objectiveLevel(friend)<0
		and self:loseEquipEffect(friend) then
			use.card = card
			use.to:append(friend)
			if use.to:length()>extraTarget
			then return end
		end
	end
end



sgs.ai_use_value.DragonCollateral = 5.8
sgs.ai_use_priority.DragonCollateral = 2.75
sgs.ai_keep_value.DragonCollateral = 3.40

sgs.dynamic_value.control_card.DragonCollateral = true

sgs.ai_judgestring.Dragon_indulgence = ".|heart"
sgs.ai_nullification.Dragon_indulgence = sgs.ai_nullification.indulgence