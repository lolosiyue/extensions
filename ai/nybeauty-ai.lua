--善身

sgs.ai_skill_invoke.nyshanshen = function(self, data)
    local target = nil
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nyshanshentarget") then
            target = p
            break
        end
    end
    if self:isFriend(target) then return true end
    return false
end

--隅泣

local nyyuqi_skill = {}
nyyuqi_skill.name = "nyyuqi"
table.insert(sgs.ai_skills, nyyuqi_skill)
nyyuqi_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("nyyuqicant-PlayClear") > 0 then return end
    if self.player:getMark("nyyuqi-PlayClear") >= self.player:getMaxHp() then return end
	return sgs.Card_Parse("#nyyuqi:.:")
end

sgs.ai_skill_use_func["#nyyuqi"] = function(card, use, self)
    use.card = card
end

sgs.ai_skill_use["@@nyyuqi"] = function(self, prompt)
    local card_ids = self.player:getTag("nyyuqiuse"):toIntList()
    local canuse = {}
    for _,id in sgs.qlist(card_ids) do
        local card = sgs.Sanguosha:getCard(id)
        if card:isAvailable(self.player) then
            table.insert(canuse, card)
        end
    end
    if #canuse == 0 then return "." end
    self:sortByCardNeed(canuse, true, true)
    for _,card in ipairs(canuse) do
        local use = self:aiUseCard(card)
        if use.card then
            if use.to and use.to:length() > 0 then
                local tos = {}
                for _,p in sgs.qlist(use.to) do
                    table.insert(tos, p:objectName())
                end
                return card:toString().."->"..table.concat(tos,"+")
            end
        end
    end
    return "."
end

--娴静

sgs.ai_skill_invoke.nyxianjing = true

--妙剑

local nymiaojian_skill = {}
nymiaojian_skill.name = "nymiaojian"
table.insert(sgs.ai_skills, nymiaojian_skill)
nymiaojian_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#nymiaojian") then return end
	return sgs.Card_Parse("#nymiaojian:.:")
end

sgs.ai_skill_use_func["#nymiaojian"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	local targets = {}
    local qtargets = sgs.PlayerList()
    local players = sgs.SPlayerList()
	local usecard = sgs.Sanguosha:cloneCard("_stabs_slash", sgs.Card_SuitToBeDecided, -1)
    usecard:setSkillName("nymiaojian")
	for _, enemy in ipairs(self.enemies) do
		local player = self.player
		if usecard:targetFilter(qtargets, enemy, player) and (not player:isProhibited(enemy, usecard, qtargets)) 
        and (not enemy:hasArmorEffect("vine")) then
			table.insert(targets, enemy:objectName())
            qtargets:append(enemy)
            players:append(enemy)
		end
	end
	usecard:deleteLater()
	if #targets > 0 then
		local card_str = string.format("#nymiaojian:.:->%s", table.concat(targets, "+"))
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to = players
		end
	end
end

sgs.ai_use_priority.nymiaojian = sgs.ai_use_priority.Slash-0.1

--刺杀

sgs.ai_skill_discard._stabs_slash = function(self,max,min)
	local player = self.player
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	local dis = {}
	if #cards >= 1 then
		table.insert(dis, cards[1]:getEffectiveId())
	end
	return dis
end

--莲华

sgs.ai_skill_invoke.nylianhua = function(self, data)
    local n = 1- self.player:getHp()
    local peachs = self:getCardsNum("Analeptic") + self:getCardsNum("Peach")
    if n > peachs then return true end
    return false
end
sgs.ai_ajustdamage_to.nylianhua = function(self, from, to, card, nature)
	if to:getMark("nylianhua_lun") > 0
	then
		return 1
	end
end


--国色

sgs.ai_card_intention.nyguose = function(self, card, from, tos)
    for _,to in ipairs(tos) do
        if to:getJudgingArea():length() == 0 then
		    sgs.updateIntention(from, to, 20)
        end
	end
end

local nyguose_skill = {}
nyguose_skill.name = "nyguose"
table.insert(sgs.ai_skills, nyguose_skill)
nyguose_skill.getTurnUseCard = function(self, inclusive)
    if not self.player:canPindian() then return end
    if self.player:getHandcardNum() < 2 then return end
    if self.player:getHandcardNum() <= self.player:getMaxCards() - 1 then return end
	return sgs.Card_Parse("#nyguose:.:")
end

sgs.ai_skill_use_func["#nyguose"] = function(card, use, self)
    local target = nil
	for _,friend in ipairs(self.friends) do
        if friend:getJudgingArea():length() > 0 and self.player:objectName() ~= friend:objectName() and (not self.player:isPindianProhibited(friend)) and friend:getHandcardNum() > 0 
        and (friend:getMark("nyguosefrom"..self.player:objectName().."-PlayClear") == 0) then
            local min = 14
            for _,mcard in sgs.qlist(friend:getHandcards()) do
                if mcard:getNumber() < min then min = mcard:getNumber() end
            end
            if self:getMaxCard():getNumber() > min then target = friend end
        end
        if target then break end
    end

    if not target then
        self:sort(self.enemies, "handcard")
	    self.enemies = sgs.reverse(self.enemies)
	    for _,p in ipairs(self.enemies) do
		    if p:hasJudgeArea() and (not p:containsTrick("indulgence")) and (not self.player:isPindianProhibited(p)) and p:getHandcardNum() > 0 
            and p:getMark("nyguosefrom"..self.player:objectName().."-PlayClear") == 0 then
                target = p
                break
            end
            if target then break end
	    end
    end
    if not target then return end
    if target then
		local card_str = "#nyguose:.:->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_pindian.nyguose = function(minusecard, self, requestor)
    local maxcard = self:getMaxCard()
    if self:isFriend(requestor) then 
        return self:getMinCard() 
    else
        if maxcard:getNumber() < 6 then
            return minusecard or self:getMaxCard()
        else
            return self:getMaxCard()
        end
    end
end

sgs.ai_skill_choice["nyguose"] = function(self, choices, data)
    local target = nil
    choices = choices:split("+")
    if #choices == 1 then return choices[1] end
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nyguosetarget") then
            target = p
            break
        end
    end
    if target and self:isFriend(target) then
        for _,choice in ipairs(choices) do
            if string.find(choice, "get") then
                return choice
            end
        end
    elseif target and self:isEnemy(target) then
        for _,choice in ipairs(choices) do
            if string.find(choice, "give") then
                return choice
            end
        end
    end
    return choices[math.random(1, #choices)]
end

sgs.ai_use_priority.nyguose = sgs.ai_use_priority.Slash - 0.1
sgs.ai_cardneed.nyguose = sgs.ai_cardneed.bignumber
--流离

sgs.ai_skill_invoke.nyliuli = true

sgs.ai_skill_choice["nyliuli"] = function(self, choices, data)
    local target = nil
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nyliulitarget") then
            target = p
            break
        end
    end
    if not self:isFriend(target) then return "cancel" end
    local will = false
    choices = choices:split("+")
    if self.player:getHp() > target:getHp() then will = true end
    if self.player:getHp() < target:getHp() and target:isWounded() and self.player:getHandcardNum() >= target:getHandcardNum() then
        if target:hasFlag("nyliulislash") and self:getCardsNum("Jink") > 0 then will = true end
        if target:hasFlag("nyliuliduel") and self:getCardsNum("Slash") > 1 then will = true end
    end
    if self.player:getHp() == target:getHp() then
        if target:hasFlag("nyliulislash") and self:getCardsNum("Jink") > 0 then will = true end
        if target:hasFlag("nyliuliduel") and self:getCardsNum("Slash") > 1 then will = true end
    end
    if will then
        for _,choice in ipairs(choices) do
            if string.find(choice, "replace") then
                return choice
            end
        end
    end
    return "cancel"
end

--奢葬

sgs.ai_skill_invoke.nyshezhang = true

--同礼

sgs.ai_skill_use["@@nytongli"] = function(self, prompt)
    if self.player:getMark("nytonglitimes") > 8 then return "." end
    local suit = self.player:property("nytonglisuit"):toString()
    local can = {}
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:getSuitString() == suit then
            table.insert(can, card)
        end
        if #can >= 5 then break end
    end
    if #can == 0 then return "." end

    local pattern = self.player:property("nytonglipattern"):toString()
    local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
    card:setSkillName("nytongli")
    local find = false
    local findcard = nil
    self:sortByCardNeed(can)

    local origin = self.player:getTag("nytongliorigin"):toCard()

    for _,c in ipairs(can) do
        if self:getUseValue(c) <= self:getUseValue(origin) then
            card:addSubcard(c)
            findcard = c
            find = true
            break
        end
    end
    if not find then return "." end

    local use = self:aiUseCard(card)
    if use.card then
        if use.to and use.to:length() > 0 then
            local tos = {}
            for _,p in sgs.qlist(use.to) do
                table.insert(tos, p:objectName())
            end
            return card:toString().."->"..table.concat(tos,"+")
        end
    end
    return "."
end

--离间

local nylijian_skill = {}
nylijian_skill.name = "nylijian"
table.insert(sgs.ai_skills, nylijian_skill)
nylijian_skill.getTurnUseCard = function(self, inclusive)
    if self.player:usedTimes("#nylijian") >= 2 then return end
	return sgs.Card_Parse("#nylijian:.:")
end

sgs.ai_skill_use_func["#nylijian"] = function(card, use, self)
    local targets = {}
    local to = sgs.SPlayerList()
    self:sort(self.enemies, "defense")
    for _, p in ipairs(self.enemies) do
        if #targets < 2 then
            table.insert(targets, p:objectName())
            to:append(p)
        end
    end
    if #targets < 2 then
        local others = {}
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if (not table.contains(targets, p:objectName())) and (not self:isFriend(p)) then
                table.insert(others, p)
            end
        end
        self:sort(others, "defense")
        for _, p in ipairs(others) do
            if #targets < 2 then
                table.insert(targets, p:objectName())
                to:append(p)
            end
        end
    end
    if #targets < 2 and #targets == 1 then
        self:sort(self.friends, "handcard",true)
        for _, p in ipairs(self.friends) do
            if #targets < 2 and (not table.contains(targets, p:objectName())) then
                table.insert(targets, p:objectName())
                to:append(p)
            end
        end
    end
    if #targets < 2 then
        return "."
    else
        local card_str = string.format("#nylijian:.:->%s", table.concat(targets, "+"))
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to = to
		end
    end
end

sgs.ai_skill_playerchosen.nylijian = function(self, targets)
    for _,target in sgs.qlist(targets) do
		if self:isFriend(target) or target:objectName() == self.player:objectName() then
			return target
		end
	end
    local can = {}
    for _,target in sgs.qlist(targets) do
		table.insert(can, target)
	end
    self:sort(can, "defense")
    return can[#can]
end

sgs.ai_skill_choice["nylijian"] = function(self, choices, data)
    choices = choices:split("+")
    local from
    local to
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:getMark("nylijian") == 1 then
            from = p
        elseif p:getMark("nylijian") == 2 then
            to = p
        end
    end
    if self:isFriend(from) then
        if to:hasArmorEffect("vine") then
            for _,choice in ipairs(choices) do
                if string.find(choice, "fire_slash") then
                    return choice
                end
            end
        end
        for _,choice in ipairs(choices) do
            if string.find(choice, "slash") then
                return choice
            end
        end
    end
    if (not self:isFriend(from)) and (self.player:usedTimes("#nylijian") >= 2) then
        if table.contains(choices, "duel") then
            return "duel"
        end
    end
    if to:hasArmorEffect("vine") then
        for _,choice in ipairs(choices) do
            if string.find(choice, "fire_slash") then
                return choice
            end
        end
    end
    if to:isChained() or (self.player:usedTimes("#nylijian") < 2) then
        if table.contains(choices, "slash") then
            return "slash"
        end
    end
    return choices[math.random(1, #choices)]
end

sgs.ai_card_intention.nylijian = function(self, card, from, tos)
    for _,to in ipairs(tos) do
		sgs.updateIntention(from, to, 60)
	end
end

sgs.ai_playerchosen_intention.nylijian = function(self, from, to)
	sgs.updateIntention(from, to, -30)
end


sgs.ai_use_priority.nylijian = sgs.ai_use_priority.Slash + 0.1

--夺刃

sgs.ai_skill_invoke.nyduoren = function(self, data)
    if self.player:getMaxHp() <= 3 then return false end
    return true
end

--血偿

local nyxuechang_skill = {}
nyxuechang_skill.name = "nyxuechang"
table.insert(sgs.ai_skills, nyxuechang_skill)
nyxuechang_skill.getTurnUseCard = function(self, inclusive)
    if not self.player:canPindian() then return end
    if self.player:getMark("nyxuechangfailed-PlayClear") > 0 then return end
    if self.player:getHandcardNum() < 2 then return end
    if self.player:getHandcardNum() <= self.player:getMaxCards() - 1 then return end
	return sgs.Card_Parse("#nyxuechang:.:")
end

sgs.ai_skill_use_func["#nyxuechang"] = function(card, use, self)
    local target = nil
    self:sort(self.enemies, "defense")
	for _,p in ipairs(self.enemies) do
		if self.player:canPindian(p) and p:getMark("nyxuechangfrom"..self.player:objectName().."-PlayClear") == 0 then
            target = p
            break
        end
	end
    if not target then return end
    if target then
		local card_str = "#nyxuechang:.:->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.nyxuechang = sgs.ai_use_priority.Slash + 0.1

sgs.ai_ajustdamage_from.nyxuechang = function(self, from, to, card, nature)
	if to:getMark("nyxuechangtarget"..from:objectName()) > 0
	then
		return 1
	end
end

sgs.ai_cardneed.nyxuechang = sgs.ai_cardneed.bignumber

--悲愤

sgs.ai_skill_use["@@nybeifen"] = function(self, prompt)
    local target = nil
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nybeifentarget") then
            target = p
            break
        end
    end
    if target and (not self:isFriend(target)) then return "." end

    local usecard = {}
    local cards = {}
    local card_ids = self.player:getPile("nyhujia")
    for _,id in sgs.qlist(card_ids) do
        local card = sgs.Sanguosha:getCard(id)
        table.insert(cards, card)
    end
    self:sortByCardNeed(cards)
    usecard = cards[#cards]

    if not target then
        self:sort(self.friends, "defense")
        target = self.friends[1]
    end

    if target then
        local card_str = string.format("#nybeifen:%s:->%s", usecard:getEffectiveId(), target:objectName())
        return card_str
    end
    return "."
end

sgs.ai_card_intention.nybeifen = function(self, card, from, tos)
    for _,to in ipairs(tos) do
		sgs.updateIntention(from, to, -80)
	end
end


sgs.ai_card_priority.nybeifen = function(self,card,v)
	if card:hasFlag("nybeifen")
	then return 10 end
end

--怨语

local nyyuanyu_skill = {}
nyyuanyu_skill.name = "nyyuanyu"
table.insert(sgs.ai_skills, nyyuanyu_skill)
nyyuanyu_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#nyyuanyu") then
		return sgs.Card_Parse("#nyyuanyu:.:")
	end
end

sgs.ai_skill_use_func["#nyyuanyu"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_playerchosen.nyyuanyu = function(self, targets)
    for _,target in sgs.qlist(targets) do
		if self:isFriend(target) and target:getMark("nyyuanyufrom"..self.player:objectName()) > 0 then
			return target
		end
	end
    for _,target in sgs.qlist(targets) do
		if self:isEnemy(target) and target:getMark("nyyuanyufrom"..self.player:objectName()) == 0 then
			return target
		end
	end
    return nil
end

sgs.ai_use_priority.nyyuanyu = 10

sgs.ai_playerchosen_intention.nyyuanyu = function(self, from, to)
    if to:getMark("nyyuanyufrom"..from:objectName()) > 0 then
	    sgs.updateIntention(from, to, -40)
    else
        sgs.updateIntention(from, to, 80)
    end
end

--夕颜

sgs.ai_skill_use["@@nyxiyan"] = function(self, prompt)
    local card_ids = self.player:getPile("nyyuan")
    local spade = {}
    local diamond = {}
    local heart = {}
    local club = {}
    local all = {}
    for _,id in sgs.qlist(card_ids) do
        local c = sgs.Sanguosha:getCard(id)
        if c:getSuit() == sgs.Card_Spade then
            table.insert(spade, c)
        elseif c:getSuit() == sgs.Card_Heart then
            table.insert(heart, c)
        elseif c:getSuit() == sgs.Card_Club then
            table.insert(club, c)
        elseif c:getSuit() == sgs.Card_Diamond then
            table.insert(diamond, c)
        end
        table.insert(all, c)
    end
    if #spade < 2 or #diamond < 2 or #heart < 2 or #club < 2 then return "." end
    local get = {}
    local suits = {}
    self:sortByCardNeed(all)
    for _,card in ipairs(all) do
        if not table.contains(suits, card:getSuitString()) then
            table.insert(get, card:getEffectiveId())
            table.insert(suits, card:getSuitString())
        end
    end
    if #suits >= 4 then
        local card_str = string.format("#nyxiyan:%s:", table.concat(get, "+"))
        return card_str
    end
    return "."
end

--抗歌

sgs.ai_skill_playerchosen.nykangge = function(self, targets)
    for _,target in sgs.qlist(targets) do
		if self:isFriend(target) then
			return target
		end
	end
    for _,target in sgs.qlist(targets) do
        if not self:isEnemy(target) then
            return target
        end
    end
    targets = sgs.QList2Table(targets)
    return targets[math.random(1,#targets)]
end

sgs.ai_playerchosen_intention.nykangge = function(self, from, to)
	sgs.updateIntention(from, to, -80)
end

sgs.ai_skill_invoke.nykangge = function(self, data)
    local target
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nykanggetarget") then
            target = p
            break
        end
    end
    return self:isFriend(target)
end

--节烈

sgs.ai_skill_playerchosen.nyjielie = function(self, targets)
    local target
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nyjielietarget") then
            target = p
            break
        end
    end
    if not self:isFriend(target) then return nil end
    if target:objectName() ~= self.player:objectName() and self.player:getHp() == 1 and (self:getCardsNum("Analeptic") + self:getCardsNum("Peach") <= 0) then
        return nil
    end
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:getMark("nykanggefrom"..self.player:objectName()) > 0 and self:isFriend(p) then
            return p
        end
    end
    self:sort(self.friends, "defense")
    return self.friends[1]
end

sgs.ai_playerchosen_intention.nyjielie = function(self, from, to)
	sgs.updateIntention(from, to, -40)
end

--祈禳

sgs.ai_skill_invoke.nyqirang = true

sgs.ai_use_revises.nyqirang = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
	then use.card = card return true end
end
sgs.ai_card_priority.nyqirang = function(self,card,v)
	if self.useValue
	and card:isKindOf("TrickCard")
	then v = v+3 end
end


function sgs.ai_cardneed.nyqirang(to,card)
	return card:getTypeId()==sgs.Card_TypeTrick or card:getTypeId()==sgs.Card_TypeEquip
end

--惊鸿

sgs.ai_skill_choice["nyjinghong"] = function(self, choices, data)
    if self.player:getHandcardNum() <= 4 then return "draw" end
    if self:getCardsNum("Slash") == 0 then return "draw" end
    local use = 0
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isAvailable(self.player) then
            local will = self:aiUseCard(card)
            if will.to then use = use + 1 end
            if use >= 4 then return "play" end
        end
    end
    return "draw"
end

--蛮嗣

sgs.ai_skill_invoke.nymansi = function(self, data)
    local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_SuitToBeDecided, -1)
    savage_assault:setSkillName("_nymansi")
    savage_assault:deleteLater()

    return self:getAoeValue(savage_assault) > 0
end

sgs.ai_card_priority.nymansi = function(self,card,v)
	if card:isKindOf("SavageAssault")
	then return 6 end
end

sgs.ai_target_revises.nymansi = function(to,card)
	if card:isKindOf("SavageAssault")
	then return true end
end

--薮影

sgs.ai_skill_invoke.nyshouying = function(self, data)
    local prompt = data:toString()
    if string.find(prompt, "get") then return true end
    local neednts = {"savage_assault","god_salvation","amazing_grace","peach","ex_nihilo"}
    for _,neednt in ipairs(neednts) do
        if string.find(prompt, neednt) then return false end
    end
    if string.find(prompt, "iron_chain") and self.player:isChained() then return false end
    if string.find(prompt, "nullified") then
        for _,p in sgs.qlist(self.room:getAlivePlayers()) do
            if p:hasFlag("nyshouying") then
                return self:isEnemy(p)
            end
        end
    end
    return false 
end

--战缘

sgs.ai_skill_playerchosen.nyzhanyuan = function(self, targets)
    if self.player:getHp() == 1 or self.player:getHandcardNum() > 4 then return nil end
    for _,target in sgs.qlist(targets) do
		if self:isFriend(target) and target:getHp() > 2 then
			return target
		end
	end
    return nil
end

sgs.ai_playerchosen_intention.nyzhanyuan = function(self, from, to)
	sgs.updateIntention(from, to, -200)
end

--系力

sgs.ai_skill_invoke.nyxili = function(self, data)
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nyxili") then
            return self:isFriend(p)
        end
    end
end

--武娘

local nywuniang_skill = {}
nywuniang_skill.name = "nywuniang"
table.insert(sgs.ai_skills, nywuniang_skill)
nywuniang_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getPhase() ~= sgs.Player_NotActive then
        if self:getCardsNum("Slash") > 0 then
            if self.player:getJudgingArea():length() == 0 then return end
        end
    end
    local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
    card:setSkillName("nywuniang")
    card:deleteLater()
    local d = self:aiUseCard(card)
    self.nywuniang_to = d.to
	if d.card and d.to
	and card:isAvailable(self.player) 
	then return sgs.Card_Parse("#nywuniang:.:") end
end

sgs.ai_skill_use_func["#nywuniang"] = function(card,use,self)
	if self.nywuniang_to
	then
		use.card = card
		if use.to then use.to = self.nywuniang_to end
	end
end

sgs.ai_skill_playerchosen.nywuniang = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    local get = false
    if self.player:hasFlag("nywuniangget") then get = true end
    if not get then
        if self.player:getJudgingArea():length() > 0 and table.contains(targets, self.player) then return self.player end
        for _,target in ipairs(targets) do
            if self:isEnemy(target) then return target end
        end
        return targets[math.random(1, #targets)]
    end
    for _,target in ipairs(targets) do
        if self:isFriend(target) and target:getJudgingArea():length() > 0 then return target end
    end
    for _,target in ipairs(targets) do
        if self:isEnemy(target) and target:getEquips():length() > 0  then return target end
    end
    for _,target in ipairs(targets) do
        if self:isEnemy(target) and (not target:isKongcheng()) then return target end
    end
    for _,target in ipairs(targets) do
        if not self:isFriend(target) and (target:getEquips():length() > 0 or (not target:isKongcheng())) then return target end
    end
    return targets[math.random(1, #targets)]
end

sgs.ai_playerchosen_intention.nywuniang = function(self, from, to)
    if from:hasFlag("nywuniangget") then
	    sgs.updateIntention(from, to, 0)
    else
        sgs.updateIntention(from, to, 60)
    end
end

sgs.ai_guhuo_card.nywuniang = function(self,toname,class_name)
	local player = self.player
	if class_name ~= "Slash" then return end
	local can = false
    if self.player:getCards("ej"):length() > 0 then can = true end
    if self.player:getPhase() == sgs.Player_NotActive then
        for _,p in sgs.qlist(self.room:getAlivePlayers()) do
            if p:getPhase() ~= sgs.Player_NotActive then
                if p:getCards("ej"):length() > 0 then can = true end
            end
        end
    end
    if can then
        return "#nywuniang:.:"
    end
end
 
sgs.ai_use_priority.nywuniang = sgs.ai_use_priority.Slash + 0.1

--许身

sgs.ai_skill_invoke.nyxushen = true

sgs.ai_skill_playerchosen.nyxushen = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _,target in ipairs(targets) do
        if self:isFriend(target) then return target end
    end
    return nil
end

sgs.ai_playerchosen_intention.nyxushen = function(self, from, to)
    sgs.updateIntention(from, to, -300)
end

--镇南

sgs.ai_skill_playerchosen.nyzhennan = function(self, targets)
    targets = sgs.QList2Table(targets)
    if not self.player:hasFlag("nyzhennan_more") then
        self:sort(targets, "hp")
        for _,target in ipairs(targets) do
            if self:isEnemy(target) and target:getMark("&nyzhennan_damage") < target:getHp() and target:objectName() ~= self.player:objectName() then
                return target
            end
        end
        local last = {}
        for _,target in ipairs(targets) do
            if self:isEnemy(target) and target:objectName() ~= self.player:objectName() then
                table.insert(last, target)
            end
        end
        if #last > 0 then return last[math.random(1, #last)] end
        return nil
    else
        local card = self.player:getTag("nyzhennan_card"):toCard()
        if card:isDamageCard() then
            self:sort(targets, "defense")
            for _,target in ipairs(targets) do
                if self:isEnemy(target) then
                    return target
                end
            end
            return nil
        elseif card:objectName() == "peach" or card:objectName() == "ex_nihilo" or card:objectName() == "analeptic" then
            if card:objectName() == "peach" then
                self:sort(targets, "hp")
            else
                self:sort(targets, "defense")
            end
            for _,target in ipairs(targets) do
                if self:isFriend(target) then
                    return target
                end
            end
            return nil
        elseif card:objectName() == "snatch" or card:objectName() =="dismantlement" then
            self:sort(targets, "defense")
            for _,target in ipairs(targets) do
                if self:isFriend(target) and target:getJudgingArea():length() > 0 then
                    return target
                end
            end
            for _,target in ipairs(targets) do
                if self:isEnemy(target) then
                    return target
                end
            end
        end
        local last = {}
        for _,target in ipairs(targets) do
            if self:isEnemy(target) then
                table.insert(last, target)
            end
        end
        if #last > 0 then return last[math.random(1, #last)] end
        return nil
    end
end

sgs.ai_playerchosen_intention.nyzhennan = function(self, from, to)
    if not from:hasFlag("nyzhennan_more") then
        sgs.updateIntention(from, to, 60)
    else
        sgs.updateIntention(from, to, 0)
    end
end

--谗逆

sgs.ai_skill_playerchosen.ny_channi = function(self, targets)
    local user
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:getPhase() == sgs.Player_Play then
            user = p
            break
        end
    end
    if not user then return nil end

    if self:isFriend(user) and self:isWeak(user) then return nil end
    if self:isEnemy(user) then
        if self.player:getHandcardNum() > 2 
        and user:getHandcardNum() < user:getHp() then return nil end
    end

    local enemys = {}
    for _,target in sgs.qlist(targets) do
        if self:isEnemy(target) then
            table.insert(enemys, target)
        end
    end

    if #enemys == 0 then return nil end
    self:sort(enemys, "defense")
    return enemys[1]
end

sgs.ai_skill_discard.ny_channi = function(self,max,min)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByCardNeed(cards)
    local user
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:getPhase() == sgs.Player_Play then
            user = p
            break
        end
    end

    local give = {}
    if user and self:isFriend(user) then
        for _,card in ipairs(cards) do
            table.insert(give, card:getEffectiveId())
        end
        return give
    end
    local need = min
    for _,card in ipairs(cards) do
        table.insert(give, card:getEffectiveId())
        need = need - 1
        if need <= 0 then break end
    end
    return give
end

--兴汉

sgs.ai_skill_invoke.ny_xinghan = true

--枕戈

sgs.ai_skill_playerchosen.ny_zhenge = function(self, targets)
    local min = 999
    local target 
    for _,p in sgs.qlist(targets) do
        if self:isFriend(p) and p:getMark("&ny_zhenge") < min then
            min = p:getMark("&ny_zhenge")
            target = p
        end
    end
    if min >= 3 then
        self:sort(self.friends, "handcard")
        return self.friends[1]
    else
        return target
    end
end

sgs.ai_skill_use["@@ny_zhenge"] = function(self, prompt)
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
    slash:setSkillName("_ny_zhenge")
    slash:deleteLater()

    local usec = {isDummy=true,to=sgs.SPlayerList()}
    self:useCardByClassName(slash, usec)
    if usec.card then
        local tos = {}
        for _,to in sgs.qlist(usec.to) do
            table.insert(tos, to:objectName())
        end
        return slash:toString().."->"..table.concat(tos, "+")
    end
    return "."
end

--樵拾

sgs.ai_skill_invoke.ny_qiaoshi = function(self, data)
    local damage = self.player:getTag("ny_qiaoshi"):toDamage()
    if damage.damage > 1 then return true end
    if damage.from and self:isFriend(damage.from) then return true end
    return self:isWeak()
end

sgs.ai_skill_use["@@ny_qiaoshi"] = function(self, prompt)
    if self.player:hasFlag("ny_qiaoshi_get") then
        local ids = self.player:getTag("ny_qiaoshi_cards"):toIntList()
        local cards = {}
        for _,id in sgs.qlist(ids) do
            local card = sgs.Sanguosha:getCard(id)
            table.insert(cards, card)
        end
        self:sortByCardNeed(cards, true)
        local get = {}
        for _,card in ipairs(cards) do
            table.insert(get, card:getEffectiveId())
            if #get >= 2 then break end
        end
        if #get > 0 then
            return string.format("#ny_qiaoshi:%s:",table.concat(get,"+"))
        end
        return "."
    else
        for _,card in sgs.qlist(self.player:getHandcards()) do
            if card:hasFlag("ny_qiaoshi") and card:isAvailable(self.player) then
                local use = self:aiUseCard(card)
                if use.card then
                    local tos = {}
                    for _,p in sgs.qlist(use.to) do
                        table.insert(tos, p:objectName())
                    end
                    return card:toString().."->"..table.concat(tos,"+")
                end
            end
        end
        return "."
    end
end

--燕语

local ny_yanyu_skill = {}
ny_yanyu_skill.name = "ny_yanyu"
table.insert(sgs.ai_skills, ny_yanyu_skill)
ny_yanyu_skill.getTurnUseCard = function(self, inclusive)
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf("Slash") then
            local card_str = "#ny_yanyu:"..card:getEffectiveId()..":"
            return sgs.Card_Parse(card_str)
        end
    end
end

sgs.ai_skill_use_func["#ny_yanyu"] = function(card,use,self)
	use.card = card
    if #self.friends_noself > 0 then
        self:sort(self.friends_noself, "defense")
        if use.to then use.to:append(self.friends_noself[1]) end
    end
end

--哀尘

sgs.ai_skill_invoke.ny_aichen = true

sgs.ai_skill_discard.ny_aichen = function(self,max,min)
    if (self.player:getMark("ny_aichen-Clear") == 0) or (self.player:getHandcardNum() > self.player:getMaxCards()) then
        local cards = sgs.QList2Table(self.player:getHandcards())
        if #cards > 0 then
            self:sortByKeepValue(cards)
            return {cards[1]:getEffectiveId()}
        end
    end
    return {}
end

--落宠

sgs.ai_skill_invoke.ny_luochong = true

local function ny_luochong_judge(player)
    if player:isDead() then return false end
    if not player:isAllNude() then return true end
    for _,p in sgs.qlist(player:getAliveSiblings()) do
        if not p:isAllNude() then return true end
    end
    return false
end

local ny_luochong_skill = {}
ny_luochong_skill.name = "ny_luochong"
table.insert(sgs.ai_skills, ny_luochong_skill)
ny_luochong_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#ny_luochong") then return end
    if (not ny_luochong_judge(self.player)) then return end
    return sgs.Card_Parse("#ny_luochong:.:")
end

sgs.ai_skill_use_func["#ny_luochong"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.ny_luochong = 6

sgs.ai_skill_playerchosen.ny_luochong = function(self, targets)
    if #self.friends > 0 then
        self:sort(self.friends, "defense")
        for _,friend in ipairs (self.friends) do
            if (not friend:getJudgingArea():isEmpty()) then return friend end
        end
    end

    local now = self.room:getCurrent()
    if self:isEnemy(now) and (not now:isNude()) and (math.random(1,2) == 1) then return now end

    local enemys = {}
    for _,target in sgs.qlist(targets) do
        if not self:isFriend(target) then
            table.insert(enemys, target)
        end
    end
    if #enemys > 0 then
        self:sort(enemys, "defense")
        for _,enemy in ipairs(enemys) do
            if not enemy:isNude() then return enemy end
        end
    end

    if self.player:hasSkill("ny_aichen") and self.player:getMark("ny_aichen-Clear") == 0
    and (not self.player:isAllNude()) then return self.player end
    
    return nil
end

--归离

sgs.ai_skill_invoke.nyarz_guili = true

sgs.ai_skill_playerchosen.nyarz_guili = function(self, targets)
    if #self.friends_noself <= 0 then return nil end
    self:sort(self.friends_noself, "handcard", true)
    for _,friend in ipairs(self.friends_noself) do
        if (not friend:containsTrick("indulgence")) then return friend end
    end
    return self.friends_noself[#self.friends_noself]
end

--彩翼

sgs.ai_skill_use["@@nyarz_caiyi"] = function(self, prompt)
    local suits = {}
    for _,card in sgs.qlist(self.player:getHandcards()) do
        local suit = card:getSuitString()
        if not table.contains(suits, suit) then
            table.insert(suits, suit)
        end
    end
    if #suits <= 0 then return "." end
    local maxvalue = -9999
    local dis = 0
    local special = false
    for i = #suits, 1, -1 do
        local value = 0 - i
        if (self.player:getHandcardNum() - i) < (2 * i) then
            value = (2 * i) - (self.player:getHandcardNum() - i) - i
        elseif  (self.player:getHandcardNum() - i) > (2 * i) then
            value = 0 - (self.player:getHandcardNum() - 2*i) + (2 * i)
            for _,p in sgs.qlist(self.room:getAlivePlayers()) do
                if self:isEnemy(p) and (p:getCardCount() < 2 * i) and (p:getHp() <= i) and (value > -2) then
                    maxvalue = value
                    dis = i
                    special = true
                    break
                end
            end
        end
        if special then break end
        if value > maxvalue then
            dis = i
            maxvalue = value
        end
    end
    if (maxvalue <= 0 and (not special)) or dis <= 0 then return "." end
    suits = {}
    local need = {}
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    for _,card in ipairs(cards) do
        local suit = card:getSuitString()
        if not table.contains(suits, suit) then
            table.insert(suits, suit)
            table.insert(need, card:getEffectiveId())
            dis = dis - 1
        end
        if dis <= 0 then break end
    end
    if #need <= 0 then return "." end
    return string.format("#nyarz_caiyi:%s:", table.concat(need, "+"))
end

sgs.ai_skill_playerchosen.nyarz_caiyi = function(self, targets)
    local all = sgs.QList2Table(self.room:getAlivePlayers())
    self:sort(all, "denfense")
    local num = self.player:getMark("nyarz_caiyi_ai-Clear")
    for _,p in ipairs(all) do
        if self:isEnemy(p) and (p:getCardCount() < 2 * num) and (p:getHp() <= 2 * num) then return p end
    end
    for _,p in ipairs(all) do
        if self:isFriend(p) and self:isWeak(p) then return p end
    end
    return all[1]
end

sgs.ai_skill_choice["nyarz_caiyi"] = function(self, choices, data)
    local items = choices:split("+")
    if string.find(choices, "good") then
        local target = data:toPlayer()
        if self:isFriend(target) then
            for _,item in ipairs(items) do
                if string.find(item, "good") then
                    return item
                end
            end
        else
            for _,item in ipairs(items) do
                if string.find(item, "bad") then
                    return item
                end
            end
        end
    elseif string.find(choices, "draw") then
        if not self.player:isWounded() then
            for _,item in ipairs(items) do
                if string.find(item, "draw") then
                    return item
                end
            end
        else
            if self.player:getHp() == 1 then
                for _,item in ipairs(items) do
                    if string.find(item, "recover") then
                        return item
                    end
                end
            end
            local re = math.min(self.player:getLostHp(),self.player:getMark("nyarz_caiyi_ai-Clear"))
            re = re * 2
            if re >= self.player:getMark("nyarz_caiyi_ai-Clear") * 2 then
                for _,item in ipairs(items) do
                    if string.find(item, "recover") then
                        return item
                    end
                end
            else
                for _,item in ipairs(items) do
                    if string.find(item, "recover") then
                        return item
                    end
                end
            end
        end
    elseif string.find(choices, "damage") then
        for _,item in ipairs(items) do
            if string.find(item, "discard") then
                return item
            end
        end
    end
    return items[math.random(1,#items)]
end

--啸咏

sgs.ai_skill_invoke.nyarz_xiaoyong = function(self, data)
    local prompt = data:toString()
    local num = tonumber(prompt:split(":")[2])
    if self.player:getPhase() ~= sgs.Player_Play then return true end
    return num > 1
end

--观骨

local function chsize(tmp)
	if not tmp then
		return 0
    elseif tmp > 240 then
        return 4
    elseif tmp > 225 then
        return 3
    elseif tmp > 192 then
        return 2
    else
        return 1
    end
end

local function utf8len(str)
	local length = 0
	local currentIndex = 1
	while currentIndex <= #str do
		local tmp = string.byte(str, currentIndex)
		currentIndex  = currentIndex + chsize(tmp)
		length = length + 1
	end
	return length
end

local nyarz_guangu_skill = {}
nyarz_guangu_skill.name = "nyarz_guangu"
table.insert(sgs.ai_skills, nyarz_guangu_skill)
nyarz_guangu_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("&nyarz_guangu") > 0 then return end
    return sgs.Card_Parse("#nyarz_guangu:.:")
end

sgs.ai_skill_use_func["#nyarz_guangu"] = function(card,use,self)
    local all = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(all, "defense")
    local touse = {"useBasicCard","useTrickCard","useEquipCard"}
    for _,p in ipairs(all) do
        if (not self:isFriend(p)) and (not p:isKongcheng()) then
            local cards = sgs.QList2Table(p:getHandcards())
            self:sortByUseValue(cards)
            local max = p:getHandcardNum()
            for _,cc in ipairs(cards) do
                local num = utf8len(sgs.Sanguosha:translate(cc:objectName()))
                if cc:isKindOf("Slash") then num = 1 end
                if num > 4 or num > max then continue end

                local usec = {isDummy=true,to=sgs.SPlayerList()}
			    self[touse[cc:getTypeId()]](self,cc,usec)
                if usec.card then
                    use.card = card
                    if use.to then use.to:append(p) end
                    return 
                end
            end
        end
    end

    local max = math.min(4, self.room:getDrawPile():length())
    if max <= 0 then return end

    for i = 1, max, 1 do
        local cards = {}
        for j = 0, i - 1, 1 do
            local cc = sgs.Sanguosha:getCard(self.room:getDrawPile():at(j))
            local num = utf8len(sgs.Sanguosha:translate(cc:objectName()))
            if cc:isKindOf("Slash") then num = 1 end
            if num == i then
                table.insert(cards, cc)
            end
        end
        if #cards > 0 then
            self:sortByUseValue(cards)
            for _,cc in ipairs(cards) do
                local usec = {isDummy=true,to=sgs.SPlayerList()}
			    self[touse[cc:getTypeId()]](self,cc,usec)
                if usec.card then
                    use.card = card
                    return 
                end
            end
        end
    end

    if self.player:getPhase() ~= sgs.Player_Play then return end

    for _,cc in sgs.qlist(self.player:getHandcards()) do
        local num = utf8len(sgs.Sanguosha:translate(cc:objectName()))
        if cc:isKindOf("Slash") then num = 1 end
        if num > 4 then continue end

        local usec = {isDummy=true,to=sgs.SPlayerList()}
        self[touse[cc:getTypeId()]](self,cc,usec)
        if usec.card then
            use.card = card
            return 
        end
    end
end

sgs.ai_use_priority.nyarz_guangu = 8
sgs.ai_use_value.nyarz_guangu = 8

sgs.ai_skill_choice.nyarz_guangu = function(self, choices)
    local tag = self.player:getTag("nyarz_guangu")
    local target = tag:toPlayer()
    local touse = {"useBasicCard","useTrickCard","useEquipCard"}
    if (not tag) or (not target) then
        if self.player:getHp() == 1 and self.player:isWounded()
        and self.player:getPhase() ~= sgs.Player_Play then
            local card = sgs.Sanguosha:getCard(self.room:getDrawPile():at(0))
            if card:isKindOf("Peach") then return tostring(1) end
            return tostring(4)
        end
        local max = math.min(4, self.room:getDrawPile():length())
        if max <= 0 then return end
    
        for i = 1, max, 1 do
            local cards = {}
            for j = 0, i - 1, 1 do
                local cc = sgs.Sanguosha:getCard(self.room:getDrawPile():at(j))
                local num = utf8len(sgs.Sanguosha:translate(cc:objectName()))
                if cc:isKindOf("Slash") then num = 1 end
                if num == i then
                    table.insert(cards, cc)
                end
            end
            if #cards > 0 then
                self:sortByUseValue(cards)
                for _,cc in ipairs(cards) do
                    local usec = {isDummy=true,to=sgs.SPlayerList()}
                    self[touse[cc:getTypeId()]](self,cc,usec)
                    if usec.card then
                        return tostring(i)
                    end
                end
            end
        end
    else
        if self.player:getHp() == 1 and self.player:isWounded()
        and self.player:getPhase() ~= sgs.Player_Play then
            for _,card in sgs.qlist(target:getHandcards()) do
                if card:isKindOf("Peach") then return tostring(1) end
            end
        end

        local cards = sgs.QList2Table(target:getHandcards())
        self:sortByUseValue(cards)
        local max = target:getHandcardNum()
        for _,cc in ipairs(cards) do
            local num = utf8len(sgs.Sanguosha:translate(cc:objectName()))
            if cc:isKindOf("Slash") then num = 1 end
            if num > 4 or num > max then continue end

            local usec = {isDummy=true,to=sgs.SPlayerList()}
            self[touse[cc:getTypeId()]](self,cc,usec)
            if usec.card then
                return tostring(num)
            end
        end
    end
    if self.player:getPhase() ~= sgs.Player_Play then return "1" end
    local items = choices:split("+")
    local max = #items

    for _,cc in sgs.qlist(self.player:getHandcards()) do
        local num = utf8len(sgs.Sanguosha:translate(cc:objectName()))
        if cc:isKindOf("Slash") then num = 1 end
        if num > 4 then continue end

        local usec = {isDummy=true,to=sgs.SPlayerList()}
        self[touse[cc:getTypeId()]](self,cc,usec)
        if usec.card and num <= max then
            return tostring(num)
        end
    end
    return tostring(max)
end

sgs.ai_skill_use["@@nyarz_guangu"] = function(self, prompt)
    local touse = {"useBasicCard","useTrickCard","useEquipCard"}
    if (not self.player:hasFlag("nyarz_guangu")) then
        if self.player:getPhase() ~= sgs.Player_Play
        and self.player:getHp() == 1 and self.player:isWounded() then
            for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                if (not self:isFriend(p)) and (not p:isKongcheng()) then
                    for _,card in sgs.qlist(p:getHandcards()) do
                        if card:isKindOf("Peach") then
                            return "#nyarz_guangu:.:->"..p:objectName()
                        end
                    end
                end
            end
            for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                if (self:isFriend(p)) and (not p:isKongcheng()) and (not self:isWeak(p)) then
                    for _,card in sgs.qlist(p:getHandcards()) do
                        if card:isKindOf("Peach") then
                            return "#nyarz_guangu:.:->"..p:objectName()
                        end
                    end
                end
            end
            local max = 4
            for _,id in sgs.qlist(self.room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:isKindOf("Peach") then 
                    return "#nyarz_guangu:.:" 
                end
                max = max - 1
                if max <= 0 then break end
            end
        end

        local card = nyarz_guanguCard:clone()
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        self["useSkillCard"](self,card,usec)
        if usec.card then
            if usec.to and (not usec.to:isEmpty()) then 
                return "#nyarz_guangu:.:->"..usec.to:at(0):objectName() 
            end
            return "#nyarz_guangu:.:"
        end
    else
        local tag = self.player:getTag("nyarz_guangu")
        local target = tag:toPlayer()
        local num = self.player:getMark("&nyarz_guangu")
        if (not tag) or (not target) then
            if self.player:getPhase() ~= sgs.Player_Play
            and self.player:getHp() == 1 and self.player:isWounded() then
                local max = num
                for _,id in sgs.qlist(self.room:getDrawPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isKindOf("Peach") then
                        return "#nyarz_guangu_use:"..card:getEffectiveId()..":"
                    end
                    max = max - 1
                    if max <= 0 then break end
                end
            end
            local max = num
            for _,id in sgs.qlist(self.room:getDrawPile()) do
                local cc = sgs.Sanguosha:getCard(id)
                local namenum = utf8len(sgs.Sanguosha:translate(cc:objectName()))
                if cc:isKindOf("Slash") then namenum = 1 end
                if namenum == num then
                    local usec = {isDummy=true,to=sgs.SPlayerList()}
                    self[touse[cc:getTypeId()]](self,cc,usec)
                    if usec.card then
                        if cc:targetFixed() then 
                            return "#nyarz_guangu_use:"..cc:getEffectiveId()..":" 
                        end
                        local tos = {}
                        for _,to in sgs.qlist(usec.to) do
                            table.insert(tos, to:objectName())
                        end
                        return "#nyarz_guangu_use:"..cc:getEffectiveId()..":->"..table.concat(tos, "+")
                    end
                end
                max = max - 1
                if max <= 0 then break end
            end
            max = num
            local cards = {}
            for _,id in sgs.qlist(self.room:getDrawPile()) do
                table.insert(cards, sgs.Sanguosha:getCard(id))
                max = max - 1
                if max <= 0 then break end
            end
            self:sortByUseValue(cards)
            for _,cc in ipairs(cards) do
                local usec = {isDummy=true,to=sgs.SPlayerList()}
                self[touse[cc:getTypeId()]](self,cc,usec)
                if usec.card then
                    if cc:targetFixed() then 
                        return "#nyarz_guangu_use:"..cc:getEffectiveId()..":" 
                    end
                    local tos = {}
                    for _,to in sgs.qlist(usec.to) do
                        table.insert(tos, to:objectName())
                    end
                    return "#nyarz_guangu_use:"..cc:getEffectiveId()..":->"..table.concat(tos, "+")
                end
            end
        else
            if self.player:getPhase() ~= sgs.Player_Play
            and self.player:getHp() == 1 and self.player:isWounded() then
                for _,card in sgs.qlist(target:getHandcards()) do
                    if card:isKindOf("Peach") then
                        return "#nyarz_guangu_use:"..card:getEffectiveId()..":"
                    end
                end
            end
            local cards = sgs.QList2Table(target:getHandcards())
            self:sortByUseValue(cards)
            for _,cc in ipairs(cards) do
                local namenum = utf8len(sgs.Sanguosha:translate(cc:objectName()))
                if cc:isKindOf("Slash") then namenum = 1 end
                if namenum == num then
                    local usec = {isDummy=true,to=sgs.SPlayerList()}
                    self[touse[cc:getTypeId()]](self,cc,usec)
                    if usec.card then
                        if cc:targetFixed() then 
                            return "#nyarz_guangu_use:"..cc:getEffectiveId()..":" 
                        end
                        local tos = {}
                        for _,to in sgs.qlist(usec.to) do
                            table.insert(tos, to:objectName())
                        end
                        return "#nyarz_guangu_use:"..cc:getEffectiveId()..":->"..table.concat(tos, "+")
                    end
                end
            end
            for _,cc in ipairs(cards) do
                local usec = {isDummy=true,to=sgs.SPlayerList()}
                self[touse[cc:getTypeId()]](self,cc,usec)
                if usec.card then
                    if cc:targetFixed() then 
                        return "#nyarz_guangu_use:"..cc:getEffectiveId()..":" 
                    end
                    local tos = {}
                    for _,to in sgs.qlist(usec.to) do
                        table.insert(tos, to:objectName())
                    end
                    return "#nyarz_guangu_use:"..cc:getEffectiveId()..":->"..table.concat(tos, "+")
                end
            end
        end
    end
end

--凌人

sgs.ai_skill_playerchosen.nyarz_lingren = function(self, targets)
    local all = sgs.QList2Table(targets)
    self:sort(all, "defense")
    for _,to in ipairs(all) do
        if (not self:isFriend(to)) then return to end
    end
    return nil
end

sgs.ai_ajustdamage_from.nyarz_lingren = function(self, from, to, card, nature)
	if card and card:hasFlag("nyarz_lingren+"..to:objectName())
	then
		return 1
	end
end

--灵犀

sgs.ai_skill_playerchosen.nyarz_lingxi = function(self, targets)
    if #self.enemies == 0 then return nil end
    self:sort(self.enemies, "defense")
    return self.enemies[1]
end

sgs.ai_playerchosen_intention.nyarz_lingxi = 40

sgs.ai_skill_invoke.nyarz_lingxi = function(self, data)
    local use = self.player:getTag("nyarz_lingxi_use"):toCardUse()
    if use.card:isKindOf("EquipCard") then return false end
    local all = sgs.IntList()
    for _,id in sgs.qlist(self.player:getPile("nyarz_lingxi_yi")) do
        all:append(id)
    end
    if (use.card:getSkillName() ~= "") then
        for _,id in sgs.qlist(use.card:getSubcards()) do
            if self.room:getCardPlace(id) ~= sgs.Player_PlaceHand then
                all:append(id)
            end
        end
    else
        if self.room:getCardPlace(use.card:getEffectiveId()) ~= sgs.Player_PlaceHand then
            all:append(use.card:getEffectiveId())
        end
    end
    local new
    if all:length() <= 4 then
        new = all
    else
        new = sgs.IntList()
        for i = all:length() - 4, all:length() - 1, 1 do
            new:append(all:at(i))
        end
    end
    local suits = {}
    for _,id in sgs.qlist(new) do
        local suit = sgs.Sanguosha:getCard(id):getSuitString()
        if (not table.contains(suits, suit)) then
            table.insert(suits, suit)
        end
    end
    return ((2*(#suits)) + 2) >= self.player:getHandcardNum()
end

--知否

sgs.ai_cardsview_valuable.nyarz_zhifou = function(self, class_name, player)
	if self.player:isKongcheng() or (self.player:getMark("nyarz_zhifou-Clear") > 0) then return end
	if class_name ~= "Peach" then return end
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf(class_name) and (self.player:getHandcardNum() > 1) then return end
    end
	return "#nyarz_zhifou:.:"
end

local nyarz_zhifou_skill={}
nyarz_zhifou_skill.name="nyarz_zhifou"
table.insert(sgs.ai_skills,nyarz_zhifou_skill)
nyarz_zhifou_skill.getTurnUseCard=function(self,inclusive)
    if self.player:isKongcheng() or (self.player:getMark("nyarz_zhifou-Clear") > 0) then return end
    local pattern = "peach"
    if self.player:getHandcardNum() > 1 then
        for _,card in sgs.qlist(self.player:getHandcards()) do
            if card:objectName() == pattern then return end
        end
    end
    local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
    card:deleteLater()
    if (not card:isAvailable(self.player)) then return end

    local use = {isDummy=true,to=sgs.SPlayerList()}
    --self:useCardByClassName(card, use)
    self["useBasicCard"](self,card,use)
    if use.card then
        self.nyarz_zhifou_to = use.to
        return sgs.Card_Parse("#nyarz_zhifou:.:")
    end
end

sgs.ai_skill_use_func["#nyarz_zhifou"] = function(card, use, self)
    use.card = card
    if use.to then use.to = self.nyarz_zhifou_to end
end

sgs.ai_use_priority.nyarz_zhifou = sgs.ai_use_priority.Peach

sgs.ai_skill_invoke.nyarz_zhifou = function(self, data)
    local target = data:toPlayer()
    return target and self:isFriend(target)
end

--霞泪

sgs.ai_skill_invoke.nyarz_xialei = true

--暗织

local nyarz_anzhi_skill={}
nyarz_anzhi_skill.name="nyarz_anzhi"
table.insert(sgs.ai_skills,nyarz_anzhi_skill)
nyarz_anzhi_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getMark("nyarz_anzhi_disable-Clear") > 0 then return end
    return sgs.Card_Parse("#nyarz_anzhi:.:")
end

sgs.ai_skill_use_func["#nyarz_anzhi"] = function(card, use, self)
    use.card = card
end

sgs.ai_skill_use["@@nyarz_anzhi"] = function(self, prompt)
    if self.player:getMark("nyarz_anzhi") == 0 then return "#nyarz_anzhi:.:" end
    if self.player:getMark("nyarz_anzhi") == 1 then
        local dis = {}
        local min = math.max(0, self.room:getDrawPile():length() - 3)
        local need = true
        for i = min, self.room:getDrawPile():length() - 1, 1 do
            local id = self.room:getDrawPile():at(i)
            local card = sgs.Sanguosha:getCard(id)
            local mark = string.format("@nyarz_anzhi_%s-Clear", card:getSuitString())
            if self.player:getMark(mark) > 0 then
                table.insert(dis, id)
            else
                if need then
                    need = false
                    table.insert(dis, id)
                end
            end
        end
        return "#nyarz_anzhi_dis:"..table.concat(dis, "+")..":"
    end
    if self.player:getMark("nyarz_anzhi") == 2 then
        local ids = self.room:getTag("nyarz_anzhi"):toIntList()
        if (not ids) or (ids:isEmpty()) then return end
        local cards = {}
        for _,id in sgs.qlist(ids) do
            if self.room:getCardPlace(id) == sgs.Player_DiscardPile then
                table.insert(cards, sgs.Sanguosha:getCard(id))
            end
        end
        if #cards <= 0 then return end
        if self.player:getPhase() == sgs.Player_Play then
            self:sortByUseValue(cards)
            for i = 1, #cards, 1 do
                if (not cards[i]:isKindOf("EquipCard")) then
                    return "#nyarz_anzhi_give:"..cards[i]:getEffectiveId()..":->"..self.player:objectName()
                end
            end
            return "#nyarz_anzhi_give:"..cards[1]:getEffectiveId()..":->"..self.player:objectName()
        else
            self:sortByKeepValue(cards)
            self:sort(self.friends, "defense")
            return "#nyarz_anzhi_give:"..cards[1]:getEffectiveId()..":->"..self.friends[1]:objectName()
        end
    end
end

--复学

sgs.ai_skill_invoke.nyarz_fuxve = true

--邀弈

sgs.ai_skill_use["@@nyarz_yaoyi"] = function(self, prompt)
    if self.player:isKongcheng() then return end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards)
    local types = {"BasicCard","TrickCard","EquipCard"}
    for _,card in ipairs(cards) do
        if card:isAvailable(self.player) then
            local dummy = {isDummy=true,to=sgs.SPlayerList()}
			self["use"..types[card:getTypeId()]](self,card,dummy)
            if dummy.card and dummy.to then
                local tos = {}
                for _,to in sgs.qlist(dummy.to) do
                    table.insert(tos, to:objectName())
                end
                return string.format("%s->%s", card:toString(), table.concat(tos, "+"))
            end
        end
    end
end

sgs.ai_skill_playerchosen.nyarz_yaoyi = function(self, targets)
    if #self.friends_noself == 0 then
        local tos = sgs.QList2Table(targets)
        self:sort(tos, "handcard")
        return tos[1]
    end
    self:sort(self.friends_noself, "handcard", true)
    if math.random(1,3) == 1 then
        for _,to in ipairs(self.friends_noself) do
            for _,hand in sgs.qlist(to:getHandcards()) do
                if hand:isAvailable(to) then return to end
            end
        end
    end
    return self.friends_noself[1]
end

local nyarz_yaoyi_skill={}
nyarz_yaoyi_skill.name="nyarz_yaoyi"
table.insert(sgs.ai_skills,nyarz_yaoyi_skill)
nyarz_yaoyi_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getMark("nyarz_yaoyi_failed-PlayClear") == 0 then 
        return sgs.Card_Parse("#nyarz_yaoyi:.:")
    else
        local cards = sgs.QList2Table(self.player:getHandcards())
        self:sortByUseValue(cards)
        local types = {"BasicCard","TrickCard","EquipCard"}
        for _,card in ipairs(cards) do
            if card:isAvailable(self.player) then
                local dummy = {isDummy=true,to=sgs.SPlayerList()}
                self["use"..types[card:getTypeId()]](self,card,dummy)
                if dummy.card and dummy.to then
                    return sgs.Card_Parse("#nyarz_yaoyi:.:")
                end
            end
        end
    end
end

sgs.ai_skill_use_func["#nyarz_yaoyi"] = function(card, use, self)
    use.card = card
end

sgs.ai_playerchosen_intention.nyarz_yaoyi = -20
sgs.ai_use_priority.nyarz_yaoyi = 7.8