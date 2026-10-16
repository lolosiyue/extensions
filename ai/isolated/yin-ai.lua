-- Fixed b6025acc yin effective bodies, with per-viewer primitive state.
local known = AIValue.requireKnown

local player_fields={feijun_target=true,shenshi_from=true}
local function write(self,key,value)
    if player_fields[key]and value~=nil then value=value:objectName()end
    self:setStrategyMemory("yin."..key,value==nil and false or value)
end
local function read(self,key)
    local value,present=self:getStrategyMemory("yin."..key)
    if not present or value==false then return nil end
    if player_fields[key]then return known(self.room:findPlayerByObjectName(value,true),key)end
    return value
end
local function same_card_in(self,cards,card)
    for _,other in ipairs(cards)do if self:sameLegacyCard(card,other)then return true end end
    return false
end
local function kuizhu_response(self,names)
    local card=self:bindSkillCard("kuizhu",{},nil,nil,"KuizhuCard")
    return {kind="use_card",card_spec=card:toCardSpec(),targets=names}
end
local function visible_count(self,player,class)
    if AIValue.sameLegacyIdentity(player,self.player)then
        local n=0;for _,card in ipairs(player:getCards("h"))do if card:isKindOf(class)then n=n+1 end end
        return n
    end
    local estimate=self:estimateKnownCards(player,class,self.player,false,"h")
    return self:useKnowledgeEstimate(estimate,"yin.cuike.public_hand_count")
end

--拒战
sgs.ai_skill_invoke.juzhan = function(self,data)
	local target = data:toPlayer()
	if self.player:getChangeSkillState("juzhan")==2 then
		if self:isFriend(target) then return false end
		if self:isEnemy(target) and not self:doDisCard(target,"he") then return false end
	end
	return true
end

--飞军
local function has_value(self,who)
	local equips = sgs.QList2Table(who:getEquips())
	for _,equip in ipairs(equips)do
		if not self:isValuableCard(equip) then return false end
	end
	return true
end

local function can_find_feijun_target(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	write(self,"feijun_id",cards[1]:getKnownEffectiveId())
	write(self,"feijun_target",nil)
	write(self,"feijun","givehand")

	local hand,equip = 0,0
	if self.room:getCardPlace(read(self,"feijun_id"))==sgs.Player_PlaceHand then
		hand = hand+1
	else
		equip = equip+1
	end

	self.enemies = self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getEquips():length()>self.player:getEquips():length()-equip and self:getDangerousCard(enemy) and not self:needToThrowCard(enemy,"e")
		and has_value(self,enemy) and enemy:getStrategyMark("feijun_hasused_"..self.player:objectName())<1 then
			write(self,"feijun_target",enemy)
		end
	end

	for _,enemy in ipairs(self.enemies)do
		if enemy:getEquips():length()>self.player:getEquips():length() -equip and self:getValuableCard(enemy) and not self:needToThrowCard(enemy,"e")
			and has_value(self,enemy) and enemy:getStrategyMark("feijun_hasused_"..self.player:objectName())<1 then
				write(self,"feijun","discardequip")
				write(self,"feijun_target",enemy)
		end
	end
	self.friends_noself = self:sort(self.friends_noself,"handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,friend in ipairs(self.friends_noself)do
		if friend:getEquips():length()>self.player:getEquips():length()-equip and self:needToThrowCard(friend,"e") and
			friend:getStrategyMark("feijun_hasused_"..self.player:objectName())<1 then
				write(self,"feijun","discardequip")
				write(self,"feijun_target",friend)
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHandcardNum()>self.player:getHandcardNum()-hand and not self:needToThrowCard(enemy,"h") and
			not (self:needKongcheng(enemy) and enemy:getHandcardNum()==1) and enemy:getStrategyMark("feijun_hasused_"..self.player:objectName())<1 then
				write(self,"feijun_target",enemy)
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if friend:getHandcardNum()>self.player:getHandcardNum()-hand and (self:needToThrowCard(friend,"h")
			or (self:needKongcheng(friend) and friend:getHandcardNum()==1) or self:getOverflow(friend)>2) and friend:getStrategyMark("feijun_hasused_"..self.player:objectName())<1 then
				write(self,"feijun_target",friend)
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if enemy:getEquips():length()>self.player:getEquips():length()-equip and (self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and
			not self:needToThrowCard(enemy,"e") then
			write(self,"feijun","discardequip")
			write(self,"feijun_target",enemy)
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if friend:getEquips():length()>self.player:getEquips():length()-equip and self:needToThrowCard(friend,"e") then
			write(self,"feijun","discardequip")
			write(self,"feijun_target",friend)
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHandcardNum()>self.player:getHandcardNum()-hand and not self:needToThrowCard(enemy,"h") and
			not (self:needKongcheng(enemy) and enemy:getHandcardNum()==1) then
			write(self,"feijun_target",enemy)
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if friend:getHandcardNum()>self.player:getHandcardNum()-hand and (self:needToThrowCard(friend,"h")
			or (self:needKongcheng(friend) and friend:getHandcardNum()==1)) then
			write(self,"feijun_target",friend)
		end
	end
	if read(self,"feijun_target") then return true end
	return false
end

sgs.ai_fill_skill.feijun = function(self,inclusive,request)
	if not can_find_feijun_target(self) then return end
	return self:legacySkillSeed("feijun","FeijunCard",request)
end

sgs.ai_skill_use_func.FeijunCard = function(card,use,self)
	use.card = self:bindSkillCard("feijun",{read(self,"feijun_id")},nil,nil,"FeijunCard")
end

sgs.ai_skill_choice.feijun = function(self,choices)
	return read(self,"feijun")
end

sgs.ai_skill_playerchosen.feijun = function(self,targets)
	return read(self,"feijun_target")
end

sgs.ai_skill_discard.feijun = function(self,discard_num,min_num,optional,include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local to_discard = {}
	table.insert(to_discard,cards[1]:getKnownEffectiveId())
	return to_discard
end

sgs.ai_skill_discard.feijun_discardequip = function(self,discard_num,min_num,optional,include_equip)
	local cards = sgs.QList2Table(self.player:getCards("e"))
	cards = self:sortByKeepValue(cards)
	local to_discard = {}
	table.insert(to_discard,cards[1]:getKnownEffectiveId())
	return to_discard
end

sgs.ai_use_priority.FeijunCard = 7

--遗礼
sgs.ai_skill_playerchosen.weili = function(self,targets)
	if self.player:getStrategyMark("&orange")<2 and self:getCardsNum("Peach")<=self.player:getLostHp() then return nil end
	for _,who in ipairs(self.friends_noself)do
		if who:getStrategyMark("&orange")<1 and not self:hasSkills("shelie", who) then
			if known(self:getResponsePolicy().turn_count,"turn count")>2 and #self.enemies<2 then return who end
			if not self:hasSkills("nostuxi|qiaobian", who) then return who end
		end
	end
	return nil
end

sgs.ai_skill_choice.weili = function(self,choices)
	if self:getCardsNum("Peach")>self.player:getLostHp() or (not self:isWeak() and hasZhaxiangEffect(self.player)) then return "losehp" end
	return "losemark"
end

sgs.ai_playerchosen_intention.weili = -80

--整论
sgs.ai_skill_invoke.zhenglun = function(self)
	if self.player:isSkipped(sgs.Player_Play) then return true end
	for _,enemy in ipairs(self.enemies)do
		local slash = known(self:getEvaluationCard("slash"),"Slash")
		if self.player:canSlash(enemy) and self:slashIsEffective(slash,enemy,self.player)
			and self:isGoodTarget(enemy,self.enemies,slash) and self:getCardsNum("Slash")<1 then
			return false
		end
	end
	if self.player:getHandcardNum()>1 or self.player:getHandcardNum()+1>self.player:getHp() then return true end
	return false
end

--溃诛
sgs.ai_skill_use["@@kuizhu"] = function(self,prompt)
	local n = self.player:getStrategyMark("kuizhu-Clear")
	local dmg
	local dmg2,dmg3,dmg4,draw = {},{},{},{}
	self.enemies = self:sort(self.enemies,"hp")
	write(self,"kuizhu",nil)

	if #self.enemies>0 then
		for _,enemy1 in ipairs(self.enemies)do
			if enemy1:getHp()>n then break end
			if not self:canDamage(enemy1,self.player) then continue end
			if not dmg and enemy1:getHp()==n then dmg = enemy1 break end
			if enemy1:getHp()<n and #self.enemies>1 then
				for __,enemy2 in ipairs(self.enemies)do
					if enemy1:objectName()==enemy2:objectName() then continue end
					if not self:canDamage(enemy2,self.player) then continue end
					if enemy1:getHp()+enemy2:getHp()>n then break
					elseif enemy1:getHp()+enemy2:getHp()==n and #dmg2<1 then
						table.insert(dmg2,enemy1:objectName())
						table.insert(dmg2,enemy2:objectName())
					elseif #self.enemies>2 then
						for __,enemy3 in ipairs(self.enemies)do
							if enemy1:objectName()==enemy3:objectName() or enemy2:objectName()==enemy3:objectName() then continue end
							if not self:canDamage(enemy3,self.player) then continue end
							if enemy1:getHp()+enemy2:getHp()+enemy3:getHp()>n then break
							elseif enemy1:getHp()+enemy2:getHp()+enemy3:getHp()==n and #dmg3<1 then
								table.insert(dmg3,enemy1:objectName())
								table.insert(dmg3,enemy2:objectName())
								table.insert(dmg3,enemy3:objectName())
							elseif #self.enemies>3 then
								for __,enemy4 in ipairs(self.enemies)do
									if enemy1:objectName()==enemy4:objectName() or enemy2:objectName()==enemy4:objectName() or enemy3:objectName()==enemy4:objectName() then continue end
									if not self:canDamage(enemy4,self.player) then break end
									if enemy1:getHp()+enemy2:getHp()+enemy3:getHp()+enemy4:getHp()>n then break
									elseif enemy1:getHp()+enemy2:getHp()+enemy3:getHp()+enemy4:getHp()==n and #dmg4<1 then
										table.insert(dmg4,enemy1:objectName())
										table.insert(dmg4,enemy2:objectName())
										table.insert(dmg4,enemy3:objectName())
										table.insert(dmg4,enemy4:objectName())
									end
								end
							end
						end
					end
				end
			end
		end
	end

	local tos = self:findPlayerToDraw(true,1,true)
	for _,friend in ipairs(tos)do
		if self:canDraw(friend) then
			table.insert(draw,friend:objectName())
			if #draw==n then break end
		end
	end

	if self:isWeak() and self.player:getHp()<2 then
		if #draw>2 then
			write(self,"kuizhu","draw")
			return kuizhu_response(self,draw)
		end
		if dmg then
			write(self,"kuizhu","damage")
			return kuizhu_response(self,{dmg:objectName()})
		end
		if #draw>0 then
			write(self,"kuizhu","draw")
			return kuizhu_response(self,draw)
		end
		return "."
	end

	if #dmg4>0 then
		write(self,"kuizhu","damage")
		return kuizhu_response(self,dmg4)
	end
	if #dmg3>0 then
		write(self,"kuizhu","damage")
		return kuizhu_response(self,dmg3)
	end
	if #dmg2>0 then
		if #draw>2 then
			write(self,"kuizhu","draw")
			return kuizhu_response(self,draw)
		end
		write(self,"kuizhu","damage")
		return kuizhu_response(self,dmg2)
	end
	if dmg then
		if #draw>2 then
			write(self,"kuizhu","draw")
			return kuizhu_response(self,draw)
		end
		write(self,"kuizhu","damage")
		return kuizhu_response(self,{dmg:objectName()})
	end
	if #draw>0 then
		write(self,"kuizhu","draw")
		if #draw==1 and #draw<n then self:noChoice(self.room:getOtherPlayers(self.player)) end
		return kuizhu_response(self,draw)
	end
	return "."
end

sgs.ai_skill_choice.kuizhu = function(self,choices)
	return read(self,"kuizhu")
end

--掣政
sgs.ai_skill_playerchosen.chezheng = function(self,targets)
	local to = self:findPlayerToDiscard("he",false,false,targets)[1]
	if to then return to end
	for _,to in sgs.qlist(targets)do
		if not self:isFriend(to) and self:doDisCard(to,"he") then return to end
	end
	return targets[1]
end

--立军
sgs.ai_skill_playerchosen.lijun = function(self,targets)
	local targets = sgs.QList2Table(targets)
	targets = self:sort(targets,"handcard")
	for _,p in ipairs(targets)do
		if self:isFriend(p) and not self:needKongcheng(p,true) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_invoke.lijun = function(self,data)
	local target = data:toPlayer()
	if not target then return false end
	return self:isFriend(target) and not self:needKongcheng(friend,true)
end

sgs.ai_skill_playerchosen.ollijun = function(self,targets)
	local targets = sgs.QList2Table(targets)
	targets = self:sort(targets,"handcard")
	for _,p in ipairs(targets)do
		if self:isFriend(p) and not self:needKongcheng(p,true) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_invoke.ollijun = function(self,data)
	local target = data:toPlayer()
	if not target then return false end
	return self:isFriend(target) and not self:needKongcheng(friend,true)
end

--奇制
sgs.ai_skill_playerchosen.qizhi = function(self,targets)
	local targets = sgs.QList2Table(targets)
	for _,target in ipairs(targets)do
		if self:isEnemy(target) and hasManjuanEffect(target) and not target:isNude() then
			return target
		end
	end
	for _,target in ipairs(targets)do
		if self:isFriend(target) and not hasManjuanEffect(target) and self:needToThrowCard(target,"he",false,false,true) then
			return target
		end
	end
	for _,target in ipairs(targets)do
		if self:isEnemy(target) and (self:getDangerousCard(target) or self:keepWoodenOx(target)) then return target end
		if self:isEnemy(target) and self:getValuableCard(target) and self:doDisCard(target,"e")
		and not target:hasSkills(sgs.notActive_cardneed_skill) then
			return target
		end
	end
	for _,target in ipairs(targets)do
		if target:objectName()==self.player:objectName() then
			local cards = sgs.QList2Table(self.player:getCards("he"))
			for _,c in ipairs(cards)do
				if not self:keepCard(c,self.player) then return target end
			end
		end
	end
	return nil
end

--进趋
sgs.ai_skill_invoke.jinqu = function(self)
	if self.player:getStrategyMark("&qizhi-Clear")>=self.player:getHandcardNum() then return true end
	return false
end

--荐降
sgs.ai_skill_playerchosen.jianxiang = function(self,targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets,"handcard")
	for _,p in ipairs(targets)do
		if self:canDraw(p) and self:isFriend(p) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if self:needKongcheng(p,true) and not self:isFriend(p) then return p end
	end
	self:noChoice(targets)
	return nil
end

--审时
sgs.ai_fill_skill.shenshi = function(self,inclusive,request)
	if self.player:isNude() then return end
	return self:legacySkillSeed("shenshi","ShenshiCard",request)
end

sgs.ai_skill_use_func.ShenshiCard = function(card,use,self)
	local max_card_num = self.room:getOtherPlayers(self.player):first():getHandcardNum()
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		max_card_num = math.max(max_card_num,p:getHandcardNum())
	end
	local target
	self.enemies = self:sort(self.enemies,"hp")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHandcardNum()==max_card_num and self:canDamage(enemy) then
			target = enemy
			break
		end
	end
	if not target then
		for _,friend in ipairs(self.friends_noself)do
			if friend:getHandcardNum()==max_card_num and self:canDamage(friend) then
				target = friend
				break
			end
		end
	end
	if not target then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByUseValue(cards,true)
	local card
	if self:needToThrowArmor() then card = self.player:getArmor() end
	if not card then
		if self:isFriend(target) then
			for _,c in ipairs(cards)do
				if not self:keepCard(c,self.player,true) then
					card = c
					break
				end
			end
		else
			for _,c in ipairs(cards)do
				if c:isKindOf("Disaster") or c:isKindOf("GodSalvation") or c:isKindOf("AmazingGrace") or c:isKindOf("FireAttack") or c:isKindOf("Slash") or c:isKindOf("Jink") then
					card = c
					break
				end
			end
		end
	end
	if not card then return end
	use.card = self:bindSkillCard("shenshi",{card:getKnownEffectiveId()},nil,nil,"ShenshiCard")
	use.to:append(target)
end

sgs.ai_use_priority.ShenshiCard = 3
sgs.ai_use_value.ShenshiCard = 3

sgs.ai_skill_invoke.shenshi = function(self,data)
	if self:needToThrowArmor() then return true end
	local from = data:toPlayer()
	write(self,"shenshi_from",from)
	if self:isFriend(from) then
		return true
	end
	if self:isEnemy(from) then
		if self:getCardsNum("Jink")>0 or self:getCardsNum("Nullification")>0 then
			return true
		end
		if self:getCardsNum("Slash")>0 and not (self:hasCrossbowEffect(from) or (from:inMyAttackRange(self.player) and from:canSlashWithoutCrossbow())) then
			return true
		end
	end
	return false
end

sgs.ai_skill_discard.shenshi = function(self,discard_num,min_num,optional,include_equip)
    local source_from=read(self,"shenshi_from")
	local dis = {}
	if self:needToThrowArmor() then
		table.insert(dis,self.player:getArmor():getEffectiveId())
		return dis
	end
	if self:isEnemy(read(self,"shenshi_from")) then
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		for _,c in ipairs(handcards)do
			if c:isKindOf("Slash") and not (self:hasCrossbowEffect(read(self,"shenshi_from")) or (source_from:inMyAttackRange(self.player) and source_from:canSlashWithoutCrossbow())) then
				table.insert(dis,c:getKnownEffectiveId())
				return dis
			end
			if c:isKindOf("Jink") or c:isKindOf("Nullification") then
				table.insert(dis,c:getKnownEffectiveId())
				return dis
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	table.insert(dis,cards[1]:getKnownEffectiveId())
	return dis
end

--成略
sgs.ai_fill_skill.chenglve = function(self,inclusive,request)
	return self:legacySkillSeed("chenglve","ChenglveCard",request)
end

sgs.ai_skill_use_func.ChenglveCard = function(card,use,self)
	use.card = self:bindSkillCard("chenglve",{},nil,nil,"ChenglveCard")
end

sgs.ai_use_priority.ChenglveCard = 3
sgs.ai_use_value.ChenglveCard = 7

sgs.ai_skill_discard.chenglve = function(self,discard_num,min_num,optional,include_equip)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local slashs = self:getCards("Slash")
	if #slashs>0 then handcards=self:sortByUseValue(handcards,true)
	else handcards=self:sortByKeepValue(handcards) end
	local to_discard = {}
	local suits = {}
	for s,sl in ipairs(slashs)do
		s = sl:getSuitString()
		if suits[s] then suits[s] = suits[s]+1
		else suits[s] = 1 end
	end
	local func = function(a,b)
		return a>b
	end
	table.sort(suits,func)
	for i,c in ipairs(handcards)do
		i = c:getKnownEffectiveId()
		if same_card_in(self,slashs,c)
		or #to_discard>=discard_num
		or #self.enemies<1
		then continue end
		if suits[c:getSuitString()]
		and suits[c:getSuitString()]>0
		then table.insert(to_discard,i) end
	end
	for i,c in ipairs(handcards)do
		i = c:getKnownEffectiveId()
		if table.contains(to_discard,i)
		or #to_discard>=discard_num
		then continue end
		table.insert(to_discard,i)
	end
	return to_discard
end

sgs.ai_card_priority.chenglve = function(self,card)
	if self.player:getStrategyMark("chenglve_"..card:getSuitString().."-Clear")>0
	and card:getTypeId()>0
	then return -1 end
end

--恃才
sgs.ai_skill_invoke.yinshicai = function(self,data)
	return true
end

--明任
sgs.ai_skill_discard.mingren = function(self,discard_num,min_num,optional,include_equip)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	handcards = self:sortByKeepValue(handcards)
	if not optional then
		local red_cards = {}
		local black_cards = {}
		for _,c in ipairs(handcards)do
			if c:isRed() then
				table.insert(red_cards,c:getKnownEffectiveId())
			else
				table.insert(black_cards,c:getKnownEffectiveId())
			end
		end
		if #red_cards>#black_cards then
			return red_cards[1]
		elseif #black_cards>#red_cards then
			return black_cards[1]
		elseif self.player:getPile("mrren"):isEmpty() then
			for _,c in ipairs(handcards)do
				return c:getKnownEffectiveId()
			end
		end
	else
		local ren = known(self:getKnownCardById(self.player:getPile("mrren"):first()),"mrren")
		for _,c in ipairs(handcards)do
			if self:getCardsNum("Nullification")>0 and c:isKindOf("TrickCard") then
				if ren:isKindOf("TrickCard") then
					if not c:isKindOf("Nullification") and self:cardNeed(ren)>self:cardNeed(c) then return c:getKnownEffectiveId() end
				else
					if not c:isKindOf("Nullification") or self:getCardsNum("Nullification")>1 then return c:getKnownEffectiveId() end
				end
			end
			if c:isKindOf("BasicCard") then
				if ren:isKindOf("BasicCard") then
					if self:cardNeed(ren)>self:cardNeed(c) then return c:getKnownEffectiveId() end
				else
					if c:isKindOf("Slash") then return c:getKnownEffectiveId() end
					if c:isKindOf("Jink") and self:getCardsNum("Jink")>1 then return c:getKnownEffectiveId() end
					if c:isKindOf("Analeptic") and self:getCardsNum("Analeptic")>1 then return c:getKnownEffectiveId() end
					if c:isKindOf("Peach") and self:getCardsNum("Peach")>1 then return c:getKnownEffectiveId() end
				end
			end
		end
		if self:cardNeed(ren)>self:cardNeed(handcards[1]) then return handcards[1]:getKnownEffectiveId() end
		return {}
	end
	return {}
end

--贞良
sgs.ai_fill_skill.zhenliang = function(self,inclusive,request)
	if self.player:getPile("mrren"):length()>0 then
		return self:legacySkillSeed("zhenliang","ZhenliangCard",request)
	end
end

sgs.ai_skill_use_func.ZhenliangCard = function(card,use,self)
	self.enemies = self:sort(self.enemies,"hp")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByUseValue(cards,true)
	local target = nil
	local use_card_num = 0
	local use_card = {}
	for _,enemy in ipairs(self.enemies)do
		use_card_num = math.max(1,math.abs(enemy:getHp()-self.player:getHp()))
		if use_card_num>2 then continue end
		use_card = {}
		if self.player:inMyAttackRange(enemy) and self:canDamage(enemy,self.player) then
			for _,c in ipairs(cards)do
				if c:sameColorWith(known(self:getKnownCardById(self.player:getPile("mrren"):first()),"mrren")) and not c:isKindOf("Peach") then
					table.insert(use_card,c:getKnownEffectiveId())
					if #use_card==use_card_num then target = enemy break end
				end
			end
			if target then break end
		end
	end
	if #use_card==0 or target==nil or #use_card<use_card_num then return end
	use.card = self:bindSkillCard("zhenliang",use_card,nil,nil,"ZhenliangCard")
	use.to:append(target)
end

sgs.ai_use_priority.ZhenliangCard = sgs.ai_use_priority.Snatch-0.1
sgs.ai_use_value.ZhenliangCard = 7

sgs.ai_skill_playerchosen.zhenliang = function(self,targets)
	return self:findPlayerToDraw(true,1)
end

--OL明任
sgs.ai_skill_discard.olmingren = function(self,discard_num,min_num,optional,include_equip)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	handcards = self:sortByKeepValue(handcards)
	if not optional then
		local red_cards = {}
		local black_cards = {}
		for _,c in ipairs(handcards)do
			if c:isRed() then
				table.insert(red_cards,c:getKnownEffectiveId())
			else
				table.insert(black_cards,c:getKnownEffectiveId())
			end
		end
		if #red_cards>#black_cards then
			return red_cards[1]
		elseif #black_cards>#red_cards then
			return black_cards[1]
		elseif self.player:getPile("mrren"):isEmpty() then
			for _,c in ipairs(handcards)do
				return c:getKnownEffectiveId()
			end
		end
	else
		local ren = known(self:getKnownCardById(self.player:getPile("mrren"):first()),"mrren")
		for _,c in ipairs(handcards)do
			if self:cardNeed(ren)>self:cardNeed(c) then
				return c:getKnownEffectiveId()
			end
		end
	end
	return {}
end

--OL贞良
sgs.ai_fill_skill.olzhenliang = function(self,inclusive,request)
	if self.player:getPile("mrren"):length()>0 then
		return self:legacySkillSeed("olzhenliang","OLZhenliangCard",request)
	end
end

sgs.ai_skill_use_func.OLZhenliangCard = function(card,use,self)
	if #self.enemies==0 then return end
	self.enemies = self:sort(self.enemies,"hp")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByUseValue(cards,true)
	local color_cards = {}
	local card = known(self:getKnownCardById(self.player:getPile("mrren"):first()),"mrren")
	for _,c in ipairs(cards)do
		if c:sameColorWith(card) then
			table.insert(color_cards,c)
		end
	end
	if #color_cards==0 then return end
	use.card = self:bindSkillCard("olzhenliang",{color_cards[1]:getKnownEffectiveId()},nil,nil,"OLZhenliangCard")
	use.to:append(self.enemies[1])
end

sgs.ai_use_priority.OLZhenliangCard = sgs.ai_use_priority.Snatch-0.1
sgs.ai_use_value.OLZhenliangCard = 7

sgs.ai_skill_playerchosen.olzhenliang = function(self,targets)
	return sgs.ai_skill_playerchosen.zhenliang(self,targets)
end



--结营
sgs.ai_skill_playerchosen.jieying = function(self,targets)
	self.enemies = self:sort(self.enemies,"defense")
	for _,enemy in sgs.list(self.enemies)do
		if not enemy:isChained() and enemy:hasSkill("lianhuo") then return enemy end
	end
	for _,enemy in sgs.list(self.enemies)do
		if not enemy:isChained() then return enemy end
	end
	targets = sgs.QList2Table(targets)
	for _,enemy in sgs.list(targets)do
		if not self:isFriend(enemy) and not enemy:isChained() then return enemy end
	end
	return targets[1]
end

sgs.ai_target_revises.jieying = function(to,card,self,use)
    if card:isKindOf("IronChain") then return true end
end

--摧克
sgs.ai_skill_playerchosen.cuike = function(self,targets)
	local mark = self.player:getStrategyMark("&junlve")
	if mark % 2==1 then
		local target = self:findPlayerToDamage(1,self.player,"N",targets)[1]
		if target then return target end
		self.enemies = self:sort(self.enemies,"hp")
		for _,enemy in sgs.list(self.enemies)do
			if self:canDamage(enemy) then return enemy end
		end
		for _,friend in sgs.list(self.friends)do
			if self:canDamage(friend) then return friend end
		end
	else
		self.enemies = self:sort(self.enemies,"defense")
		for _,friend in sgs.list(self.friends_noself)do
			if self:needToThrowCard(friend,"j") then
				return friend
			end
		end
		for _,enemy in sgs.list(self.enemies)do
			if self:doDisCard(enemy) and not enemy:isChained() and not enemy:hasSkills("qianjie|jieying") then
				return enemy
			end
		end
		for _,enemy in sgs.list(self.enemies)do
			if self:doDisCard(enemy) then
				return enemy
			end
		end
		for _,friend in sgs.list(self.friends_noself)do
			if self:needToThrowCard(friend,"hej",true) and friend:isChained() then
				return friend
			end
		end
	end
	return nil
end

sgs.ai_skill_invoke.cuike = function(self,data)
	self.friends_noself = self:sort(self.friends_noself,"hp")

	local has_weak_friend = false
	for _,friend in sgs.list(self.friends_noself)do
		if self:isWeak(friend) then
			has_weak_friend = true
		end
	end

	if self.player:getKnownRole()=="renegade" then return not self:isWeak(self.room:getLord()) end
	if self.player:getKnownRole()=="loyalist" or self.player:isLord() then return not has_weak_friend end
	if self.player:getKnownRole()=="rebel" then
		if has_weak_friend then
			local friend_peach_num = 0
			local one_hp_friend_analeptic_num = 0
			local one_hp_friend_num = 0
			local has_analeptic_friend = {}
            for _,friend in sgs.list(self.friends)do
                friend_peach_num=friend_peach_num+visible_count(self,friend,"Peach")
            end
            for _,friend in sgs.list(self.friends_noself)do
                if friend:getHp()==1 then
                    one_hp_friend_num=one_hp_friend_num+1
                    if visible_count(self,friend,"Analeptic")>=1 then table.insert(has_analeptic_friend,friend)end
                end
            end
			if friend_peach_num<one_hp_friend_num and #has_analeptic_friend<one_hp_friend_num then return true end
			return false
		end
	end
	return true
end

--绽火
sgs.ai_fill_skill.zhanhuo = function(self,inclusive,request)
	for _,friend in sgs.list(self.friends)do
		if self:isWeak(friend) and friend:isChained()
		and self:damageIsEffective(friend,sgs.DamageStruct_Fire,self.player)
		then return end
	end
	return self:legacySkillSeed("zhanhuo","ZhanhuoCard",request)
end

sgs.ai_skill_use_func.ZhanhuoCard = function(card,use,self)
	local can_zhanhuo = false
	self.enemies = self:sort(self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if enemy:isChained() and self:canDamage(enemy,self.player,false,sgs.DamageStruct_Fire) then
			if enemy:getHp()<2 and self:isWeak(enemy) then
				can_zhanhuo = true
				break
			elseif self:isWeak() then
				can_zhanhuo = true
				break
			end
		end
	end
	if not can_zhanhuo then return end
	local targets = {}
	for _,enemy in sgs.list(self.enemies)do
		if #targets<self.player:getStrategyMark("&junlve") and enemy:isChained() and self:doDisCard(enemy,"e") and
			self:canDamage(enemy,self.player,false,sgs.DamageStruct_Fire) then
			table.insert(targets,enemy)
		end
	end
	for _,friend in sgs.list(self.friends)do
		if #targets<self.player:getStrategyMark("&junlve") and friend:isChained() and not self:keepWoodenOx(friend)
		and self:needToThrowCard(friend,"e") then
			table.insert(targets,friend)
		end
	end
	if #targets==0 then return end
	use.card = self:bindSkillCard("zhanhuo",{},nil,nil,"ZhanhuoCard")
	for i = 1,#targets,1 do
		use.to:append(targets[i])
	end
end

sgs.ai_skill_playerchosen.zhanhuo = function(self,targets)
	local target = self:findPlayerToDamage(1,self.player,"F",targets)[1]
	if target then return target end
	return target:first()
end

sgs.ai_use_priority.ZhanhuoCard = 3
sgs.ai_use_value.ZhanhuoCard = 3
