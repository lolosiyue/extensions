addAiSkills("f_henjue").getTurnUseCard = function(self)
	return sgs.Card_Parse("#f_henjueCard:.:")
end

sgs.ai_skill_use_func["#f_henjueCard"] = function(card,use,self)
	self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
		if p:hasEquip() and p:hasEquipArea() and self:loseEquipEffect(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
    for _,p in sgs.list(self.enemies)do
		if p:hasEquip() and p:hasEquipArea() then
			use.card = card
			use.to:append(p)
			return
		end
	end
    for _,p in sgs.list(self.enemies)do
		if p:hasEquipArea() and self:loseEquipEffect(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.f_henjueCard = 1.4
sgs.ai_use_priority.f_henjueCard = 5.8
sgs.ai_card_intention.f_henjueCard = 50

sgs.ai_ajustdamage_from.f_pingpan = function(self, from, to, card, nature)
    local e = 0
    for i = 0, 4 do
        if not to:hasEquipArea(i) then
            e = e + 1
        end
    end
    return e
end


f_sandaoEX_skill = {}
f_sandaoEX_skill.name = "f_sandaoEX"
table.insert(sgs.ai_skills, f_sandaoEX_skill)
f_sandaoEX_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies < 1 or self.player:isKongcheng() then return end
	local too_weak = true
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    slash:deleteLater()
	for _, player in ipairs(self.enemies) do
		if player:getHp() <= 3 and self:slashIsEffective(slash, player) then
			too_weak = false
		end
	end
	if too_weak then return end
	return sgs.Card_Parse("#f_sandaoEXCard:.:")
end

sgs.ai_skill_use_func["#f_sandaoEXCard"] = function(card, use, self)
	local target
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if self:isEnemy(enemy) and not self:slashProhibit(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and self:slashIsEffective(slash, enemy) and enemy:getHp() <= 3 then
			target = enemy
            break
		end
	end
	if target then
		use.card = sgs.Card_Parse("#f_sandaoEXCard:.:")
		return
	end
end

sgs.ai_use_value["f_sandaoEXCard"]       = 8
sgs.ai_use_priority["f_sandaoEXCard"]    = 2
sgs.ai_card_intention.f_sandaoEXCard     = 108

sgs.ai_skill_use["@@f_sandaoEXSlash"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:setSkillName("_f_sandaoEXSlash")
	slash:deleteLater()
	local dummy_use = self:aiUseCard(slash, dummy())
	if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return "#f_sandaoEXSlashCard:.:->"..table.concat(tos, "+")
    end
	return "."
end



--神董卓
  --“凶宴”AI
sgs.ai_skill_invoke.f_xiongyan = true

sgs.ai_skill_choice.f_xiongyan = function(self, choices, data)
	if self.player:getHandcardNum() + self.player:getEquips():length() < 2 then return "1" end
	if self.player:getHp() <= 1 then return "2" end
	for _, friend in ipairs(self.friends) do
		if friend:hasFlag("f_shendongzhuo") then return "2" end
	end
	--return "1"
	return "2"
end

sgs.ai_skill_discard.f_xiongyan = function(self) --限制电脑只能给两张，否则一旦牌多了就变成遛狗了
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	table.insert(to_discard, cards[1]:getEffectiveId())
	table.insert(to_discard, cards[2]:getEffectiveId())
	return to_discard
end

sgs.ai_skill_invoke["@f_xiongyanDraw"] = function(self, data)
	--[[local targets = sgs.QList2Table(targets)
	self:sort(self.friends_noself)
	for _, p in pairs(self.friends_noself) do
		if p:hasFlag("f_sdzForE") and self:isFriend(p) then
			return true
		end
	end
	return false]]
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasFlag("f_sdzForE") and self:objectiveLevel(enemy) > 0 then --直接反向思考，若是敌人就不给，否则就给（学会了仁德的董太师）
		    return false
		end
	end
	return true
end
sgs.ai_skill_choice.f_qiandu = function(self, choices, data)
	return "1"
end

sgs.ai_skill_playerchosen.f_qiandu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target,"ej")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"ej")
		then return target end
	end
	return nil
end

sgs.ai_skill_use["@@f_qiandu"] = function(self, prompt, method)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local values,range = {},self.player:getAttackRange()
	local nplayer = self.player
	for i = 1,self.player:aliveCount()do
		local fediff,add,isfriend = 0,0,nil
		local np = nplayer
		for value = #self.friends_noself,1,-1 do
			np = np:getNextAlive()
			if np:objectName()==self.player:objectName() then
				if self:isFriend(nplayer) then fediff = fediff+value
				else fediff = fediff-value
				end
			else
				if self:isFriend(np) then
					fediff = fediff+value
					if isfriend then add = add+1
					else isfriend = true end
				elseif self:isEnemy(np) then
					fediff = fediff-value
					isfriend = false
				end
			end
		end
		values[nplayer:objectName()] = fediff+add
		nplayer = nplayer:getNextAlive()
	end
	local function get_value(a)
		local ret = 0
		for _,enemy in ipairs(self.enemies)do
			if a:objectName()~=enemy:objectName() and a:distanceTo(enemy)<=range then ret = ret+1 end
		end
		return ret
	end
	local function compare_func(a,b)
		if values[a:objectName()]~=values[b:objectName()] then
			return values[a:objectName()]>values[b:objectName()]
		else
			return get_value(a)>get_value(b)
		end
	end
	local players = sgs.QList2Table(self.room:getAlivePlayers())
	table.sort(players,compare_func)
	if values[players[1]:objectName()]>0 and players[1]:objectName()~=self.player:objectName() then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:doDisCard(p,"ej") then
				return "#f_qianduCard:.:->"..players[1]:objectName()
			end
		end
	end
	return "."
end


sgs.ai_skill_invoke.f_yanyi = true

addAiSkills("f_yanyi").getTurnUseCard = function(self)
    return sgs.Card_Parse("#f_yanyiCard:.:")
end

sgs.ai_skill_use_func["#f_yanyiCard"] = function(card,use,self)
	use.card = card
end

addAiSkills("f_yishi").getTurnUseCard = function(self)
	local sks = self.player:getTag("f_yishi"):toString():split("+")
	if #sks > 0 and sgs.ai_skill_choice.f_yishi(self, "2+3") ~= "cancel"  then
    	return sgs.Card_Parse("#f_yishiCard:.:")
	end
	if sgs.ai_skill_choice.f_yishi(self, "1") ~= "cancel" and self.player:getHandcardNum() >= self.player:getHp() and self.player:getEquips():length() > 0 and self.player:canDiscard(self.player, "he") then
    	return sgs.Card_Parse("#f_yishiCard:.:")
	end
end

sgs.ai_skill_use_func["#f_yishiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_skill_choice.f_yishi = function(self, choices)
    local items = choices:split("+")
    if self:isWeak() and table.contains(items, "3") then
		return "3"
	end
	local acquire = getChoice(choices, "1")
	if acquire then
		return acquire
	end

	if table.contains(items, "2") then
		return "2"
	end
    return "cancel"
end


--神刘禅
  --“无忧”AI
sgs.ai_skill_invoke.f_leji = function(self,data)
	local target = data:toCardUse().to:first()
	if self:isFriend(target) and not (target:getPhase() ~= sgs.Player_NotActive and  (target:hasSkill("Dlimu") or target:hasSkill("limu"))) then
		return true
	end
	if self:isEnemy(target) and (target:getPhase() ~= sgs.Player_NotActive and (target:hasSkill("Dlimu") or target:hasSkill("limu"))) then
		return true
	end
    return false
end

sgs.ai_choicemade_filter.skillInvoke.f_leji = function(self, player, promptlist)
   	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
		if p:hasFlag("f_leji") then target = p break end
	end
	if target and not (target:getPhase() ~= sgs.Player_NotActive and  (target:hasSkill("Dlimu") or target:hasSkill("limu"))) then
		if promptlist[#promptlist]=="yes" then
        	sgs.updateIntention(player, target, -80)
		end
    end
end


sgs.ai_skill_playerchosen.f_leji = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
    for _, target in ipairs(targets) do
        if self:isFriend(target) then
            return target
        end
    end
    return nil
end
sgs.ai_playerchosen_intention.f_leji = -80


sgs.ai_skill_discard.f_leji = function(self,discard_num,min_num,optional,include_equip)
	local targets = sgs.SPlayerList()
	for _, cjl in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if cjl:containsTrick("indulgence") then 
			targets:append(cjl)
		end
	end
	if sgs.ai_skill_playerchosen.f_leji(self, targets) ~= nil then
		return {}
	end
	if self:isWeak() or math.random() < 0.5 then
		local to_discard = {}
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		table.insert(to_discard, cards[1]:getEffectiveId())
		if #to_discard > 0 then
			return to_discard
		end
	end

	return {}
end
sgs.ai_skill_invoke.f_wuyou = true
sgs.ai_skill_playerchosen.f_wuyou = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isFriend(p) then
		    return p
		end
	end
	return self.player
end

sgs.ai_skill_choice.f_wuyou = function(self, choices, data)
	if self.player:hasJudgeArea() then
		local n = self.player:getJudgingArea():length()
		if self.player:getHp() < 2 then return "2" end --回血保命为先
		if n > 0 and #self.friends_noself <= 0 then return "2" end
		if n == 0 then return "1="..n+1 end
	end
	return "cancel"
end


  --“单杀”AI

sgs.ai_skill_playerchosen.f_dansha = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) then
		    return p
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.f_dansha = 80
--



--神曹仁
  --“奇阵”AI
sgs.ai_skill_invoke.f_qizhen = function(self, data)
	local use = data:toCardUse()
	return not self:isFriend(use.from)
end

  --“励军”AI
sgs.ai_skill_invoke.f_lijun = true
sgs.ai_skill_invoke["@f_lijunGHJ"] = function(self, data)
	local target = data:toPlayer()
	return self:isFriend(target)
end

sgs.ai_choicemade_filter.skillInvoke["@f_lijunGHJ"] = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end

sgs.ai_skill_choice.f_lijun = function(self, choices, data)
	local target = data:toPlayer()
	if self:isEnemy(target) then --评估场上是否有手牌溢出较严重的敌方，这样才有选2选项的价值
		return "2"
	end
	return "1"
end

sgs.ai_skill_playerchosen.f_lijun = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(self.friends_noself)
	for _, p in ipairs(self.friends_noself) do --先找没手牌的队友
		if self:isFriend(p) and p:getHandcardNum() == 0 and not p:hasSkill("kongcheng") and self:canDraw(p, self.player) then
			return p
		end
	end
	for _, p in ipairs(self.friends_noself) do --再找手牌低于其体力值的队友
		if self:isFriend(p) and p:getHandcardNum() < p:getHp() and self:canDraw(p, self.player) then
			return p
		end
	end

	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and p:getHandcardNum() - p:getHp() >= 3 then
			return p
		end
	end
		for _, p in ipairs(self.friends_noself) do --然后还是优先找队友
		if self:isFriend(p) then
			return p
		end
	end
	return self.player --若没有队友，就给自己用
end


addAiSkills("f_yonghun").getTurnUseCard = function(self)
    return sgs.Card_Parse("#f_yonghunCard:.:")
end

sgs.ai_skill_use_func["#f_yonghunCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.f_yonghunCard = 5.4
sgs.ai_use_priority.f_yonghunCard = 2.8

sgs.ai_skill_invoke.f_yonghun = function(self, data)
	local card = data:toCard()
	if card:isKindOf("Analeptic") then
		if self:getCardsNum("Slash")>0 then
			local slash = self:getCard("Slash")
			if slash then
				assert(slash)
				local dummy_use = self:aiUseCard(slash, dummy())
				if dummy_use.card and dummy_use.to then
					if not dummy_use.to:isEmpty() then
						return true
					end
				end
			end
		end
	end
	if card:isKindOf("Jink") then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.f_yonghun = function(self,targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getHp() < getBestHp(p) then
			return p
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.f_yonghun = -40


sgs.ai_skill_use["@@f_yonghunSlash"] = function(self, prompt)
	local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if h:hasFlag("f_yonghun") and h:isKindOf("Slash") then
			self.player:setFlags("InfinityAttackRange")
			h:setFlags("Qinggang")
			local dummy_use = self:aiUseCard(h, dummy())
			h:setFlags("-Qinggang")
			self.player:setFlags("-InfinityAttackRange")
			if dummy_use.to and dummy_use.to:length() > 0 then
				local tos = {}
				for _,to in sgs.qlist(dummy_use.to) do
					table.insert(tos, to:objectName())
				end
				return "#f_yonghunSlashCard:"..h:getEffectiveId()..":->"..table.concat(tos, "+")
			end
		end
	end
    return "."
end

sgs.ai_skill_invoke.f_jianyuanadd = function(self, data)
	local str = data:toString()
	if string.startsWith(str, "JianYuanLu")  then
		return true
	end
end
sgs.ai_skill_invoke.f_jianyuan = function(self, data)
	if self.player:getHandcardNum() > self.player:getMark("&f_jianyuanX") + 4 + 2 then
		local JianYuanLu = self.player:property("SkillDescriptionRecord_f_jianyuan"):toString():split("+")
		if math.random() < 0.3 and #JianYuanLu > 0 then
			return false
		end
	end
	return true
end
sgs.ai_can_damagehp.f_jianyuan = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)-1>0
	and self:canLoseHp(from,card,to) and from and from:isMale()
end

sgs.ai_skill_choice.f_jianyuan = function(self, choices, data)
	if self.player:getMark("&f_jianyuanY") + 3 < 4 +self.player:getMark("&f_jianyuanX") then
		return "y"
	end
	return "x"
end

sgs.ai_skill_use["@@f_jianyuangive"] = function(self, prompt)
	local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	for _,h in sgs.list(cards)do
		if h:hasFlag("f_jianyuan") then
			for _, p in ipairs(self.friends_noself) do
				if p:hasFlag("f_JYuan") and p:getWeapon() ~= nil then
					return "#f_jianyuangiveCard:"..h:getEffectiveId()..":->"..p:objectName()
				end
			end
			for _, p in ipairs(self.friends_noself) do
				if p:hasFlag("f_JYuan") then
					local JianYuanLu = self.player:property("SkillDescriptionRecord_f_jianyuan"):toString():split("+")
					if not table.contains(JianYuanLu, p:getGeneralName()) then
						return "#f_jianyuangiveCard:"..h:getEffectiveId()..":->"..p:objectName()
					end
				end
			end
			for _, p in ipairs(self.friends_noself) do
				if p:hasFlag("f_JYuan") and self:canDraw(p, self.player) then
					return "#f_jianyuangiveCard:"..h:getEffectiveId()..":->"..p:objectName()
				end
			end
			for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
				if p:hasFlag("f_JYuan") and not p:hasFlag("f_JYuan_real") then
					local JianYuanLu = self.player:property("SkillDescriptionRecord_f_jianyuan"):toString():split("+")
					if not table.contains(JianYuanLu, p:getGeneralName()) then
						return "#f_jianyuangiveCard:"..h:getEffectiveId()..":->"..p:objectName()
					end
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_use["@@f_jianyuanthrow!"] = function(self, prompt)
	local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	for _,h in sgs.list(cards)do
		if h:hasFlag("f_jianyuan") then
			return "#f_jianyuanthrowCard:"..h:getEffectiveId()..":"
		end
	end
end

sgs.ai_skill_choice.f_gongli = function(self, choices, data)
	local items = choices:split("+")
	local current = self.room:getCurrent()
	if current and (self:isFriend(current) or (not self:isFriend(current) and current:getHp() >= getBestHp(current))) then
		if table.contains(items, "ue") then
			if self:loseEquipEffect(self.player) or math.random() < 0.5 or (self.player:hasSkill("f_jianyuan") and self.player:getWeapon() == nil) then
				return "ue"
			end
		end
		return "dc"
	end
	return "cancel"
end


--神于吉
  --“回生”AI
sgs.ai_skill_invoke.f_huisheng = function(self, data)
	--[[if self.player:getCardsNum("Peach") > 0 or self.player:getCardsNum("Analeptic") > 0 then return false end
	return true]]
	local dying = data:toDying()
	local peaches = 1 - dying.who:getHp()
	return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
end

  --“妙道”AI
sgs.ai_skill_invoke.f_miaodao = function(self, data)
	if self.player:getPile("f_syjDao"):length() >= 4 or self.player:getHandcardNum() <= 2 then return false end
	return true
end
sgs.ai_skill_invoke.f_yifa = function(self, data)
	if sgs.ai_skill_invoke.peiqi(self,ToData())
	then
		return true
	end
	local current = self.room:getCurrent()
	if current then
		return self:doDisCard(current, "ej", true)
	end
	if current and self:isEnemy(current) then
		return self:doDisCard(current, "hej", true)
	end
	return false
end


sgs.ai_skill_playerchosen.f_yifa_from = function(self,players)
	sgs.ai_skill_invoke.peiqi(self)
    for _,target in sgs.list(players)do
		if target==self.peiqiData.from
		then return target end
	end
    for _,target in sgs.list(players)do
        return target
    end
end

sgs.ai_skill_cardchosen.f_yifa = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		local id = e:getEffectiveId()
		if id==self.peiqiData.cid
		then return id end
	end
end

sgs.ai_skill_playerchosen.f_yifa_to = function(self,players)
    for _,target in sgs.list(players)do
		if target==self.peiqiData.to
		then return target end
	end
    for _,target in sgs.list(players)do
        return target
    end
end

sgs.ai_skill_choice.f_yifa = function(self, choices, data)
	if sgs.ai_skill_invoke.peiqi(self,ToData())
	then
		return "move"
	end
	return "get"
end

sgs.ai_skill_use["@@f_yifa!"] = function(self, prompt)
	for _,id in sgs.qlist(self.player:getPile("f_syjDao"))do
		return "#f_yifaCard:"..id..":"
	end
	return "."
end



--神庞统
  --“凤雏”AI
sgs.ai_skill_choice.f_fengchu = function(self, choices, data)
	if self.player:isWounded() then return "2"
	else return "1" end --受伤回复，满血加槽
	return "3" or "4" --为求稳必选这两个选项，摸牌收益高（不考虑被乐了、左慈等）、封印“落凤”保证不发生意外
end

addAiSkills("f_shenpan").getTurnUseCard = function(self)
    return sgs.Card_Parse("#f_shenpanCard:.:")
end

sgs.ai_skill_use_func["#f_shenpanCard"] = function(card,use,self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
		if self:getUseValue(acard) < 6 then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = card:getEffectiveId()
	for _,enemy in sgs.list(self.enemies)do
		if enemy:getMark("f_shenpan-PlayClear") == 0 then
			for _, m in sgs.list(enemy:getMarkNames()) do
            	if m:startsWith("f_shenpan") and enemy:getMark(m) > 0 then
					use.card = sgs.Card_Parse("#f_shenpanCard:" .. card_id .. ":")
					use.to:append(enemy)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.f_shenpanCard = 5.4
sgs.ai_use_priority.f_shenpanCard = 2
sgs.ai_card_intention.f_shenpanCard = 80

addAiSkills("f_qigong").getTurnUseCard = function(self)
	if self.player:getEquips():length() > 0 and not (self.player:getMark("&fJuJiang") > 0 and self.player:getPile("spy_shenbingku"):isEmpty()) then
		 return sgs.Card_Parse("#pro_f_qigongCard:.:")
	end
    return sgs.Card_Parse("#mini_f_qigongCard:.:")
end

sgs.ai_skill_use_func["#pro_f_qigongCard"] = function(card,use,self)
	local cards = sgs.QList2Table(self.player:getCards("e"))
	local to_use = {}
	for _, c in ipairs(cards) do
		table.insert(to_use, c:getEffectiveId())
	end
	if #to_use == 0 then return nil end

	use.card = sgs.Card_Parse("#pro_f_qigongCard:"..table.concat(to_use, "+") ..":")
	return 
end
sgs.ai_skill_use_func["#mini_f_qigongCard"] = function(card,use,self)
	use.card = card
	return
end
sgs.ai_skill_playerchosen.f_qigong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:loseEquipEffect(target)
		then return target end
	end
	local card = self.room:getTag("f_qigong"):toCard()
	for _, friend in ipairs(self.friends_noself) do
		local equip_index = card:getRealCard():toEquipCard():location()
		if not self:getSameEquip(card, friend) and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) and friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
			return friend
		end

		local equip_index = card:getRealCard():toEquipCard():location()
		if not self:getSameEquip(card, friend) and friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
			return friend
		end
		
	end
	return self.player
end

sgs.ai_playerchosen_intention.f_qigong = -40



local f_lingqi_skill = {}
f_lingqi_skill.name = "f_lingqi"
table.insert(sgs.ai_skills,f_lingqi_skill)
f_lingqi_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("he")
	local equip_card
	self:sortByUseValue(cards,true)
	for _,card in ipairs(cards)do
		if card:getTypeId()==sgs.Card_TypeEquip and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive) then
			equip_card = card
			break
		end
	end
	if equip_card then
		local suit = equip_card:getSuitString()
		local number = equip_card:getNumberString()
		local card_id = equip_card:getEffectiveId()
		if self.player:getMark("&fXiaJiang") > 0 then
			if suit == "heart" then
				return sgs.Card_Parse(("fire_slash:f_lingqi[%s:%s]=%d"):format(suit,number,card_id))
			elseif suit == "diamond" then
				return sgs.Card_Parse(("thunder_slash:f_lingqi[%s:%s]=%d"):format(suit,number,card_id))
			elseif suit == "club" then
				return sgs.Card_Parse(("ice_slash:f_lingqi[%s:%s]=%d"):format(suit,number,card_id))
			elseif suit == "spade" then
				return sgs.Card_Parse(("slash:f_lingqix_poison[%s:%s]=%d"):format(suit,number,card_id))
			end
		end
		return sgs.Card_Parse(("slash:f_lingqij[%s:%s]=%d"):format(suit,number,card_id))
	end
end

sgs.ai_card_priority.f_lingqi = function(self,card)
	if table.contains(card:getSkillNames(), "f_lingqi") or table.contains(card:getSkillNames(), "f_lingqij") or table.contains(card:getSkillNames(), "f_lingqix_poison")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end




sgs.ai_use_revises.f_lingqi = function(self,card,use)
	if card:isKindOf("Slash") and table.contains(card:getSkillNames(), "f_lingqij") then
		card:setFlags("Qinggang")
	end
end

addAiSkills("f_shenjiang").getTurnUseCard = function(self)
	if self.player:getMark("&fJuJiang") > 0 and self.player:getPile("spy_shenbingku"):isEmpty() then return end
    return sgs.Card_Parse("#f_shenjiangCard:.:")
end
sgs.ai_skill_use_func["#f_shenjiangCard"] = function(card,use,self)
	local cards = sgs.QList2Table(self.player:getPile("f_YT"))
	local to_use = {}
	for _, id in ipairs(cards) do
		table.insert(to_use, id)
		if #to_use >= 4 then break end
	end
	if #to_use ~= 4 then return end
	self:sort(self.friends, "defense", true)
	for _,friend in ipairs(self.friends) do
		use.card = sgs.Card_Parse("#f_shenjiangCard:".. table.concat(to_use, "+") ..":")
		use.to:append(friend)
		return
	end
end
sgs.ai_skill_cardask["@f_shenjiangRecast"] = function(self, data, pattern, target, target2)	
	return true
end
sgs.ai_card_intention.f_shenjiangCard = -80

sgs.ai_skill_use["@@f_shenjiangSBK!"] = function(self, prompt)
	local target
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("f_shenjiangTarget") then
            target = p
            break
        end
    end
	local card_ids = RandomList(self.player:getPile("spy_shenbingku"))
	for _,id in sgs.qlist(card_ids)do
		if not self:getSameEquip(sgs.Sanguosha:getCard(id),target) then
			return "#f_shenjiangSBKCard:"..id..":"
		end
	end
	for _,id in sgs.qlist(card_ids)do
		return "#f_shenjiangSBKCard:"..id..":"
	end
	return "."
end



addAiSkills("f_jishen").getTurnUseCard = function(self)
    return sgs.Card_Parse("#f_jishenCard:.:")
end
sgs.ai_skill_use_func["#f_jishenCard"] = function(card,use,self)
	self:sort(self.friends, "defense", true)
	for _,friend in ipairs(self.friends) do
		use.card = sgs.Card_Parse("#f_jishenCard:.:")
		use.to:append(friend)
		return
	end
end

sgs.ai_card_intention.f_jishenCard = -80

  --“征灭(正式版)”AI
sgs.ai_skill_playerchosen.f_zhengmie_f = function(self,targets)
	local target
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("f_zhengmie_fTarget") then
			target = p
			break
		end
	end
	local dc = dummyCard()
	dc:setSkillName("f_zhengmie_f")
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) and self:isGoodTarget(p,self.enemies, dc) and not self:needToLoseHp(p, target, dc) and  self:slashIsEffective(dc, p) then
			return p
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) and self:isGoodTarget(p,self.enemies, dc) and  self:slashIsEffective(dc, p) then
			return p
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and self:needToLoseHp(p, target, dc) then
			return p
		end
	end
	return nil
end


sgs.ai_playerchosen_intention.f_zhengmie_f = 50

  --“奢靡”AI
sgs.ai_skill_choice.dy_shemi = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "1") then
		return "1"
	end
	if table.contains(items, "2") then
		return "2"
	end
	return "cancel"
end



--神刘协
  --“天子”AI（代替出【闪】的部分）

sgs.ai_skill_invoke.f_skysson = function(self, data)
	return sgs.ai_skill_playerchosen.f_skysson(self, self.room:getAllPlayers()) ~= self.player
end

sgs.ai_skill_playerchosen.f_skysson = function(self, targets)
	local targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:doDisCard(p, "hej", true) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and self:doDisCard(p, "hej", true) then
			return p
		end
	end
	return self.player
end
sgs.ai_skill_playerchosen.f_skysson_slash = function(self, targets)
	local targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and getKnownCard(p, self.player, "Slash") > 0 then
			return p
		end
	end
	local dc = dummyCard()
	dc:setSkillName("f_skysson")
	for _, p in ipairs(targets) do
		if self:slashIsEffective(dc,p,self.player) then
			return p
		end
	end
	return targets[1]
end

addAiSkills("f_skysson").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		return sgs.Card_Parse("#f_skyssonCard:"..c:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#f_skyssonCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	local dc = dummyCard()
	dc:setSkillName("f_skysson")
	for _,ep in sgs.list(self.enemies)do
		for _,fp in sgs.list(self.friends_noself)do
			if CanToCard(dc,fp,ep)
			and CanToCard(dc,self.player,ep) and getKnownCard(fp, self.player, "Slash") > 0
			then
				use.card = card
				use.to:append(fp)
				use.to:append(ep)
				return
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		for _,fp in sgs.list(self.friends_noself)do
			if CanToCard(dc,fp,ep) and getKnownCard(fp, self.player, "Slash") > 0
			then
				use.card = card
				use.to:append(fp)
				use.to:append(ep)
				return
			end
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		for _,fp in sgs.list(self.friends_noself)do
			if CanToCard(dc,fp,ep) 
			and not self:isFriend(ep) and getKnownCard(fp, self.player, "Slash") > 0
			then
				use.card = card
				use.to:append(fp)
				use.to:append(ep)
				return
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		for _,ep2 in sgs.list(self.enemies)do
			if CanToCard(dc,ep2,ep)
			and CanToCard(dc,self.player,ep) then
				use.card = card
				use.to:append(ep)
				use.to:append(ep2)
				return
			end
		end
	end
end

sgs.ai_use_value.f_skyssonCard = 3.4
sgs.ai_use_priority.f_skyssonCard = 3.8

sgs.ai_skill_playerchosen.f_skysson = function(self,targets)
	local enemies = self:sort(targets,"hp")
  	for i,p in sgs.list(enemies)do
		sgs.mingce_to = p
		if self:isEnemy(p)
		then return p end
	end
  	for i,p in sgs.list(enemies)do
		sgs.mingce_to = p
		if not self:isFriend(p)
		then return p end
	end
	sgs.mingce_to = enemies[1]
	return enemies[1]
end


sgs.ai_skill_cardask["@f_skysson-jink"] = function(self, data, pattern, target, target2)	
	local target = data:toPlayer()
	if self:isFriend(target) then
		return true
	end
	return "."
end


  --“傀儡”AI
sgs.ai_skill_invoke.f_kuilei = true


sgs.ai_skill_playerchosen.f_kuilei = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(self.friends_noself, "handcard")
	for _, p in ipairs(self.friends_noself) do
		if self:isFriend(p) and getKnownCard(p, self.player, "Peach") > 0 then --先找靠谱的队友
			return p
		end
	end
	for _, p in ipairs(targets) do --没得救就坑对手
		if self:isEnemy(p) and self:doDisCard(p, "he") then
			return p
		end
	end
end

sgs.ai_skill_cardask["@f_kuilei-peach"]=function(self,data)
	local dying = data:toDying()
	if dying.who then
		if self:isFriend(dying.who) then
			return true
		end
		if self:isEnemy(dying.who) then
			if dying.who:isLord() then return "." end
			if math.random() < 0.5 then return true end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.f_dansha_new = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) then
		    return p
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.f_dansha_new = 80



--神-曹丕&甄姬
  --“洛殇”AI
sgs.ai_skill_invoke.diy_k_luoshang = true
sgs.ai_skill_invoke.diy_k_luoshang_judge = sgs.ai_skill_invoke.noszhenlie


addAiSkills("diy_k_luoshang").getTurnUseCard = function(self)
	return sgs.Card_Parse("#diy_k_luoshang:.:")
end

sgs.ai_skill_use_func["diy_k_luoshang"] = function(card,use,self)
	use.card = card
end



sgs.ai_ajustdamage_from.f_mingwang = function(self, from, to, card, nature)
    if to:getMark("&f_ysS")==0
    then
        return 1
    end
end


--神袁绍
  --“名望”AI
sgs.ai_skill_choice.f_mingwang = function(self, choices, data)
	return "1"
end

  --“非势”AI（“势”角色的抉择）
sgs.ai_skill_invoke.f_feishi = function(self, data)
	local str = data:toString():split(":")[2]
	local target = self.room:findPlayerByObjectName(str)
	return target and not self:isFriend(target)
end

--神袁绍-江山如梦
  --“利剑”AI
sgs.ai_skill_choice.f_lijian = function(self, choices, data)
	local target = data:toPlayer()
	if self:isWeak() and self:canHit(self.player,target,true) then
		return "1"
	end
	return "2"
end
sgs.ai_skill_cardask["@f_lijian-SlashShow"]=function(self,data)
	local use = data:toCardUse()
	if use.from and self:isEnemy(use.from) then
		return true
	end
	return "."
end

sgs.ai_ajustdamage_from.f_lijian = function(self, from, to, card, nature)
    if card and card:hasFlag("f_lijian_slash_dmg")
    then
        return 1
    end
end
sgs.ai_ajustdamage_from.f_luanji = function(self, from, to, card, nature)
    if card and table.contains(card:getSkillNames(), "f_luanji") and card:subcardsLength() >= 3
    then
        return 1
    end
end

  --“乱击”AI（仅限于两牌）

local f_luanji_skill = {}
f_luanji_skill.name = "f_luanji"
table.insert(sgs.ai_skills, f_luanji_skill)
f_luanji_skill.getTurnUseCard = function(self)
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getCards("he"):length() >= 2 and self.player:getMark("f_luanji_used-PlayClear") == 0 then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local useAll = false
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 and not enemy:hasArmorEffect("Vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player)
				and self:isWeak(enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
			end
		end
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
			if useAll then fvalueCard = isCard("ArcheryAttack", fcard, self.player) end
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard and scard:getColor() == fcard:getColor() and not svalueCard then
						local card_str = ("archery_attack:f_luanji[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)
						assert(archeryattack)
						local dummy_use = { isDummy = true }
						self:useTrickCard(archeryattack, dummy_use)
						if dummy_use.card then
							second_card = scard
							second_found = true
							break
						end
					end
				end
				if second_card then break end
			end
		end
	end
	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("archery_attack:f_luanji[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
end

  --“会盟”AI
local f_huimeng_skill = {}
f_huimeng_skill.name = "f_huimeng"
table.insert(sgs.ai_skills, f_huimeng_skill)
f_huimeng_skill.getTurnUseCard = function(self)
	if (self.player:getEquips():length() == 0 and self.player:getHandcardNum() <= self.player:getHp()) or self.player:getMark("&fUnited") >= 18 then return end
	local card_id
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")
	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	if not card_id then
		for _, acard in ipairs(cards) do
			if acard:isKindOf("BasicCard") and not acard:isKindOf("Peach") and not acard:isKindOf("Analeptic") then
				card_id = acard:getEffectiveId()
				break
			end
		end
	end
	if not card_id then
	    if self.player:getLostHp() > self:getCardsNum("Peach") then
			return nil
		else
			return sgs.Card_Parse("#lcd_f_huimengCard:.:")
		end
	else
	    return sgs.Card_Parse("#lcd_f_huimengCard:"..card_id..":")
	end
end

    --1牌会盟
sgs.ai_skill_use_func["#lcd_f_huimengCard"] = function(card, use, self)
	use.card = card
	return
end
sgs.ai_use_value.lcd_f_huimengCard = 1.8
sgs.ai_use_priority.lcd_f_huimengCard = 1.8

sgs.ai_skill_invoke["@f_huimeng-crzw"] = function(self, data)
	local dying = data:toDying()
	return not self:isFriend(dying.who) and self.player:getMark("&fUnited") / 3 <= dying.who:getCards("he"):length()
end

sgs.ai_skill_invoke["@f_huimeng-myzd"] = function(self, data)
	local damage = data:toDamage()
	return self.player:getHp() + self.player:getHujia() + self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= damage.damage
end



--==天才包专属神武将AI==--
--神祝融
  --“烈锋 势破万敌”AI
sgs.ai_target_revises.tc_juxiang_stsh = function(to,card)
	if card:isKindOf("SavageAssault")
	then return true end
end

sgs.ai_skill_invoke.tc_liefeng_spwd = function(self, data)
	local use = data:toCardUse()
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) then return false end
	end
	return true
end

sgs.ai_skill_playerchosen.tc_liefeng_spwd = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and p:getHp() <= 1 and not p:hasSkill("newjuejing") and not p:hasSkill("mrds_juejing")
		and not p:hasSkill("zjjuejing") and not p:hasSkill("szsjuejing") then
		    return p
		end
	end
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) then
		    return p
		end
	end
	return nil
end


addAiSkills("tc_changbiao_sqrh").getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
	if #cards<1 then return end
	local ids = {}
   	local fs = dummyCard()
	fs:setSkillName("tc_changbiao_sqrh")
  	for _,c in sgs.list(cards)do
		if self:getKeepValue(c)>3
		or #ids>=#cards/2 then continue end
		table.insert(ids,c:getEffectiveId())
		fs:addSubcard(c)
	end
	if #ids<1 and #cards>1
	then
		table.insert(ids,cards[1]:getEffectiveId())
		fs:addSubcard(cards[1])
	end
	local dummy = self:aiUseCard(fs, dummy(true, 99))
	if fs:isAvailable(self.player)
	and dummy.card
	and dummy.to
	and #ids>0
  	then
		self.olcb_to = dummy.to
		ids = #ids>0 and table.concat(ids,"+") or "."
		return sgs.Card_Parse("#tc_changbiao_sqrh:"..ids..":")
	end
end

sgs.ai_skill_use_func["#tc_changbiao_sqrh"] = function(card,use,self)
	use.card = card
	use.to = self.olcb_to
end

sgs.ai_use_value.tc_changbiao_sqrh = 9.4
sgs.ai_use_priority.tc_changbiao_sqrh = 2.8


--

--神貂蝉
  --“魅魂”AI
local diy_k_meihun_skill = {}
diy_k_meihun_skill.name = "diy_k_meihun"
table.insert(sgs.ai_skills, diy_k_meihun_skill)
diy_k_meihun_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#diy_k_meihun") >= 1 or self.player:isNude() or #self.enemies == 0 then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")
	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not acard:isKindOf("Peach") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				  and not acard:isKindOf("Peach") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#diy_k_meihun:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#diy_k_meihun"] = function(card, use, self)
    if self.player:usedTimes("#diy_k_meihun") < 1 then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if self:objectiveLevel(enemy) > 0 then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value["diy_k_meihun"] = 8.5
sgs.ai_use_priority["diy_k_meihun"] = 9.5
sgs.ai_card_intention["diy_k_meihun"] = 80

sgs.ai_skill_cardask["@diy_k_huoxin"] = function(self,data,pattern,prompt)
	local current = self.room:getCurrent()
	if current and not self:isEnemy(current) then
		return true
	end
	return "."
end


--神马超
  --“横骛”AI
sgs.ai_skill_invoke.diy_k_hengwu = true




addAiSkills("diy_k_shouli").getTurnUseCard = function(self)
	
	local target
	if self.player:getMark("diy_k_shouli-Self-Clear") == 0 and self.player:canDiscard(self.player, "he") then
		target = self.player
	end
	if self.player:getMark("diy_k_shouli-noSelf-Clear") == 0 then
		for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
			if self:doDisCard(p, "he", true) then
				target = p
				break
			end
		end
	end
	if target then
		local dc = dummyCard()
		dc:setSkillName("diy_k_shouli")
		local d = self:aiUseCard(dc)
		if d.card and d.to
		and dc:isAvailable(self.player)
		then
			self.diy_k_shouli_to = d.to
			sgs.ai_use_priority.diy_k_shouli = sgs.ai_use_priority.Slash+0.6
			return sgs.Card_Parse("#diy_k_shouli:.:slash")
		end
	end
end

sgs.ai_skill_use_func["#diy_k_shouli"] = function(card,use,self)
	if self.diy_k_shouli_to
	then
		use.card = card
		use.to = self.diy_k_shouli_to
	end
end

sgs.ai_use_value.diy_k_shouli = 5.4
sgs.ai_use_priority.diy_k_shouli = 2.8


sgs.ai_card_priority.diy_k_shouli = function(self,card)
	if table.contains(card:getSkillNames(), "diy_k_shouli")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_skill_playerchosen.diy_k_shouli = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and self:doDisCard(p, "he", true) then
		    return p
		end
	end
	for _, p in ipairs(targets) do
	    if self:doDisCard(p, "he", true) then
		    return p
		end
	end
	return self.player
end

sgs.ai_guhuo_card.diy_k_shouli = function(self,toname,class_name)
	if class_name=="Slash" or class_name=="Jink" then
		if self.player:getMark("diy_k_shouli-noSelf-Clear") == 0 then
			for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
				if self:doDisCard(p, "he", true) then
					return "#diy_k_shouli:.:"..toname
				end
			end
		end
		if self.player:getMark("diy_k_shouli-Self-Clear") == 0 then
			if self.player:canDiscard(self.player, "he") then
				return "#diy_k_shouli:.:"..toname
			end
		end
	end
end


sgs.ai_card_priority.tc_zhitu = function(self,card,v)
	if self.player:getMark("&tc_zhitu") % card:getNumber() == 0 or card:getNumber() % self.player:getMark("&tc_zhitu") == 0
	then return 10 end
end


local tc_liuti_skill = {}
tc_liuti_skill.name = "tc_liuti"
table.insert(sgs.ai_skills,tc_liuti_skill)
tc_liuti_skill.getTurnUseCard = function(self)
	sgs.ai_use_priority.tc_liutiCard = 3
	if self.player:getCardCount(true)<2 then return false end
	if self:getOverflow()<=0 then return false end
	if self:isWeak() and self:getOverflow()<=1 then return false end
	return sgs.Card_Parse("#tc_liutiCard:.:")
end
sgs.ai_skill_use_func["#tc_liutiCard"] = function(card,use,self)
	local num = self.player:getMark("&tc_zhitu")
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)

	for _,c1 in ipairs(cards)do
		local temp = 0
		temp = temp + c1:getNumber()
		for _,c in ipairs(cards)do
			if c1 ~= c then
				if not self.player:isCardLimited(c,sgs.Card_MethodDiscard) and not self.player:isCardLimited(c1,sgs.Card_MethodDiscard) then
					if table.contains(unpreferedCards,c:getId()) then continue end
					if (((temp + c:getNumber()) % num) == num) or (((temp + c:getNumber()) % num) % num == 0 and temp + c:getNumber() ~= num and (temp + c:getNumber()) % num ~= 0) then
						temp = temp + c:getNumber()
						table.insert(unpreferedCards,c:getId())
						table.insert(unpreferedCards,c1:getId())
						break
					end
					
				end
				if #unpreferedCards==2 then break end
			end
		end
		if #unpreferedCards==2 then break end
	end

	if #unpreferedCards==2 then
		use.card = sgs.Card_Parse("#tc_liutiCard:"..table.concat(unpreferedCards,"+")..":")
		sgs.ai_use_priority.tc_liutiCard = 0
		return
	end

end

sgs.ai_use_priority.tc_liutiCard = 3





--神吕布
  --“神愤”AI（会是个纯屑AI，自己虚弱了就开）
local tc_shenfen_skill = {}
tc_shenfen_skill.name = "tc_shenfen"
table.insert(sgs.ai_skills, tc_shenfen_skill)
tc_shenfen_skill.getTurnUseCard = function(self)
	if (self.player:getMark("@wrath") < 6 and self.player:getMark("&wrath") < 6) or self.player:hasUsed("#tc_shenfen") then return end
	return sgs.Card_Parse("#tc_shenfen:.:")
end

sgs.ai_skill_use_func["#tc_shenfen"] = function(card, use, self)
	local card = sgs.Card_Parse("@ShenfenCard=.")
	local dummy_use = dummy()
	self:useSkillCard(card,dummy_use)
	if dummy_use.card then return sgs.Card_Parse("#tc_shenfen:.:") end
end

sgs.ai_use_value["tc_shenfen"] = 8.7
sgs.ai_use_priority["tc_shenfen"] = 9.6
sgs.ai_card_intention["tc_shenfen"] = 66

sgs.ai_skill_invoke.tc_wumou = function(self, data)
	local use = data:toCardUse()
	for _,to in sgs.list(use.to)do
		if self:isFriend(to) then return false end
	end
	if self.player:getMark("&wrath") < 6 then
		local dummy_use = dummy()
		local card = sgs.Card_Parse("@ShenfenCard=.")
		self:useSkillCard(card,dummy_use)
		if dummy_use.card then 
		 	return false 
		end
	end
	return true
end
sgs.ai_skill_invoke.tc_wumou_damage = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if not target then return end
	if self:isFriend(target) then
		if self:needToLoseHp(target,self.player) then return false end
		return false
	else
		if self:isWeak(target) then return false end
		return self:needToLoseHp(target,self.player)
	end
end


--神左慈
  --“化身”AI
local tc_huashen_skill = {}
tc_huashen_skill.name = "tc_huashen"
table.insert(sgs.ai_skills, tc_huashen_skill)
tc_huashen_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#tc_huashen") >= 1 + self.player:getMark("tc_huashen-Clear") then return end
	return sgs.Card_Parse("#tc_huashen:.:")
end

sgs.ai_skill_use_func["#tc_huashen"] = function(card, use, self)
    if self.player:usedTimes("#tc_huashen") < 1 + self.player:getMark("tc_huashen-Clear") then
        use.card = card
	return end
end

sgs.ai_use_value["tc_huashen"] = 8.5
sgs.ai_use_priority["tc_huashen"] = 9.5
sgs.ai_card_intention["tc_huashen"] = -80

sgs.ai_skill_use["@@tc_huashen"] = function(self, prompt)
	return "#tc_huashen:.:"
end
sgs.ai_skill_choice["@tc_huashen"] = function(self, choices, data)
	return "yes"
end




--神郭嘉
  --“慧识”AI
local tc_huishi_skill = {}
tc_huishi_skill.name = "tc_huishi"
table.insert(sgs.ai_skills, tc_huishi_skill)
tc_huishi_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#tc_huishi") >= 1 then return end
	return sgs.Card_Parse("#tc_huishi:.:")
end

sgs.ai_skill_use_func["#tc_huishi"] = function(card, use, self)
    if self.player:usedTimes("#tc_huishi") < 1 then
        use.card = card
	    return
	end
end

sgs.ai_skill_invoke.tc_huishi = true

    --“慧识”给牌
sgs.ai_skill_playerchosen.tc_huishi = function(self, targets)
    local targets = sgs.QList2Table(targets)
	self:sort(self.friends_noself)
	for _, p in ipairs(self.friends_noself) do --如果自己手牌足够又有队友手牌不够，给队友
		if self:isFriend(p) and p:getHandcardNum() < 3 and self.player:getHandcardNum() >= self.player:getMaxHp() and self:canDraw(p, self.player) then
			return p
		end
	end
    return self.player
end
    --“慧识”给技能
sgs.ai_skill_playerchosen["tc_huishizx"] = function(self, targets)
    local targets = sgs.QList2Table(targets)
	self:sort(self.friends_noself)
	for _, p in ipairs(self.friends_noself) do --优先给玩家队友，毕竟“佐幸”是没写技能AI的
		if self:isFriend(p) and p:getState() == "online" then
			return p
		end
	end
    return nil --反正不给也是自己获得
end

sgs.ai_use_value["tc_huishi"] = 8.5
sgs.ai_use_priority["tc_huishi"] = 9.5
sgs.ai_card_intention["tc_huishi"] = -80


addAiSkills("tc_zuoxing").getTurnUseCard = function(self)
	for _,name in sgs.list(patterns())do
		local poi = dummyCard(name)
		if poi==nil then continue end
		poi:setSkillName("tc_zuoxing")
		if poi:isAvailable(self.player)
		and poi:isNDTrick() and poi:isDamageCard()
		then
			local dummy = self:aiUseCard(poi)
			if dummy.card and dummy.to
			then
				self.zx_to = dummy.to
				sgs.ai_use_priority.tc_zuoxing = sgs.ai_use_priority[poi:getClassName()]
				if poi:canRecast() and dummy.to:length()<1 then continue end
				return sgs.Card_Parse("#tc_zuoxing:.:"..name)
			end
		end
	end
	for _,name in sgs.list(patterns())do
		local poi = dummyCard(name)
		if poi==nil then continue end
		poi:setSkillName("tc_zuoxing")
		if poi:isAvailable(self.player)
		and poi:isNDTrick()
		and name~="amazing_grace"
		and name~="collateral"
		then
			local dummy = self:aiUseCard(poi)
			if dummy.card and dummy.to
			then
				self.zx_to = dummy.to
				sgs.ai_use_priority.tc_zuoxing = sgs.ai_use_priority[poi:getClassName()]
				if poi:canRecast() and dummy.to:length()<1 then continue end
				return sgs.Card_Parse("#tc_zuoxing:.:"..name)
			end
		end
	end
end

sgs.ai_skill_use_func["#tc_zuoxing"] = function(card,use,self)
	use.card = card
	use.to = self.zx_to
end

sgs.ai_use_value.tc_zuoxing = 8.4
sgs.ai_use_priority.tc_zuoxing = 8.4






--

--神鲁肃
addAiSkills("tc_dingzhou").getTurnUseCard = function(self)
	return sgs.Card_Parse("#tc_dingzhou:.:")
end

sgs.ai_skill_use_func["#tc_dingzhou"] = function(card,use,self)
	local target
	for _,friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "ej", true) and self.player:getEquips():length() + self.player:getJudgingArea():length() > 0 then
			target = friend
			break
		end
	end
	if target then
		use.card = card
		use.to:append(target)
	end
end


  --“智盟”AI
sgs.ai_skill_playerchosen.tc_zhimeng = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and self:doDisCard(p, "he", true) then --同阵营之间换牌总归是不亏的
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) then --同阵营之间换牌总归是不亏的
			return p
		end
	end
	return nil
end


--







