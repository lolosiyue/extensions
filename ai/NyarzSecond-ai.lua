local function findPlayerByFlag(room, flag)
    for _,player in sgs.qlist(room:getAlivePlayers()) do
        if player:hasFlag(flag) then return player end
    end
    return nil
end


--厚禄

sgs.ai_skill_invoke.jxhoulu = function(self, data)
    local target = data:toPlayer()
    if not self:isFriend(target) then return false end
    if target:getHp() == 1 then return false end
    if target:containsTrick("indulgence") then return false end
    if target:objectName() == self.player:objectName() then 
        return self.player:getHp() > 1 or self:getCardsNum("Peach") > 1 or self:getCardsNum("Analeptic") > 1
    end
    return target:getHp() >= 3 and target:getHandcardNum() <= 8
end
sgs.ai_card_priority.jxhoulu = function(self,card,v)
	if self.player:getMark("jxhoulunum-Clear") >= 1 and self.player:getMark("jxhouludamage-Clear") == 0 and card:isDamageCard() then return 10 end
end

--拒降

sgs.ai_skill_invoke.jxjuxiang = function(self, data)
    local target = nil
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("jxjuxiangtarget") then
            target = p
            break
        end
    end
    if not target then return false end
    return self:isEnemy(target)
end

--佯解

sgs.ai_skill_use["@@jxyangjie"] = function(self, prompt)
    local targets = {}
    local qtargets = sgs.PlayerList()
    local all = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(all, "defense")
    local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
    slash:setSkillName("jxyangjie")
    slash:deleteLater()

    for _,p in ipairs(all) do
        if self:isFriend(p) and p:getHp() == 1 then
            if slash:targetFilter(qtargets, p, self.player) and (not self.player:isProhibited(p, slash, qtargets)) then
                table.insert(targets, p:objectName())
                qtargets:append(p)      
            end
        end
    end

    if #targets == 0 then
        local use = self:aiUseCard(slash, dummy())
        if use.to then
            for _,p in sgs.qlist(use.to) do
                table.insert(targets, p:objectName())
            end
        end
    end

    if #targets > 0 then
        local card_str = string.format("#jxyangjie:.:->%s", table.concat(targets, "+"))
        return card_str
    end
    return "."
end

sgs.ai_skill_choice["jxyangjie"] = function(self, choices, data)
	local target = self.player:getTag("jxyangjieto"):toPlayer()
    choices = choices:split("+")
    if self:isFriend(target) then
        for _,p in ipairs(choices) do
            if string.find(p, "recover") then return p end
        end
    end
    for _,p in ipairs(choices) do
        if string.find(p, "damage") then return p end
    end
    return choices[math.random(1, #choices)]
end

--急进

local jjjijin_skill = {}
jjjijin_skill.name = "jjjijin"
table.insert(sgs.ai_skills, jjjijin_skill)
jjjijin_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("jjjijinused-Clear") > 0 then return end
    local patterns = {"nullification", "snatch", "duel", "dismantlement", "fire_attack", "amazing_grace", "savage_assault", "archery_attack", "ex_nihilo", "god_salvation", "iron_chain"}
    for _,p in ipairs(patterns) do
        if self.player:getMark("jjjijin_juguan_remove_"..p) == 0 then
            local card = sgs.Sanguosha:cloneCard(p, sgs.Card_SuitToBeDecided, -1)
            card:setSkillName("jjjijin")
            card:deleteLater()
            local d = self:aiUseCard(card)
            sgs.ai_use_priority.jjjijin = sgs.ai_use_priority[card:getClassName()]
            self.jjjijin_to = d.to
			if d.card and d.to
			and card:isAvailable(self.player) and self:getCardsNum(card:getClassName()) == 0
			then return sgs.Card_Parse("#jjjijin:.:"..p) end
        end
    end
end

sgs.ai_skill_use_func["#jjjijin"] = function(card,use,self)
	if self.jjjijin_to
	then
		use.card = card
		if use.to then use.to = self.jjjijin_to end
	end
end

sgs.ai_use_priority.jjjijin = 3.8

sgs.ai_skill_playerchosen.jjjijin = function(self, targets)
    self:sort(self.friends, "handcard")
    for _,p in ipairs(self.friends) do
        if self.player:objectName() ~= p:objectName() then return p end
    end
    return nil
end

sgs.ai_playerchosen_intention.jjjijin = function(self, from, to)
	sgs.updateIntention(from, to, -80)
end
sgs.ai_target_revises.jjjijin = function(to,card)
	if card:isKindOf("TrickCard") and to:getMark("jjjijin_juguan_remove_"..card:objectName()) > 0
	then return true end
end

--肃然

sgs.ai_skill_playerschosen.basuran = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    self:sort(self.friends, "handcard")
    selected:append(self.friends[#self.friends])
    self:sort(self.friends, "defense")

    for _,p in ipairs(self.friends) do
        if p:getJudgingArea():length() > 0 and (not selected:contains(p)) then
            selected:append(p)
            break
        end
    end

    if selected:length() < 2 then
        for _,p in ipairs(self.friends) do
            if (not selected:contains(p)) then
                selected:append(p)
                break
            end
        end
    end

    if #self.enemies  == 0 then return selected end

    self:sort(self.enemies, "handcard")
    if not selected:contains(self.enemies[#self.enemies]) then
        selected:append(self.enemies[#self.enemies])
    end
    for _,p in ipairs(self.enemies) do
        if not selected:contains(p) then
            selected:append(p)
            break
        end
    end
    return selected
end

sgs.ai_skill_choice["basuran"] = function(self, choices, data)
    local target = nil
    choices = choices:split("+")
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("basuran") then 
            target = p
            break
        end
    end
    if self:isFriend(target) then
        self:sort(self.friends, "handcard")
        if target:objectName() == self.friends[#self.friends]:objectName() then
            for _,p in ipairs(choices) do
                if string.find(p, "discard") then
                    return p
                end
            end
        end
        if target:getJudgingArea():length() > 0 then
            for _,p in ipairs(choices) do
                if string.find(p, "judge") then
                    return p
                end
            end
        end
        for _,p in ipairs(choices) do
            if string.find(p, "judge") or string.find(p, "discard") then
                return p
            end
        end
    end

    if self:isEnemy(target) then
        if #self.enemies ~= 0 then 
            self:sort(self.enemies, "handcard")
            if target:objectName() == self.enemies[#self.enemies]:objectName() then
                for _,p in ipairs(choices) do
                    if string.find(p, "play") then
                        return p
                    end
                end
            end
        end
        for _,p in ipairs(choices) do
            if string.find(p, "draw") or string.find(p, "play") then
                return p
            end
        end
    end
    return choices[math.random(1, #choices)]
end

--举尉

sgs.ai_skill_playerchosen.bajuwei = function(self, targets)
    for _,p in sgs.qlist(targets) do
        if self:isFriend(p) then
            return p
        end
    end
    return nil
end

sgs.ai_playerchosen_intention.bajuwei = function(self, from, to)
	sgs.updateIntention(from, to, -80)
end

--影附

sgs.ai_skill_choice["dianyingfu"] = function(self, choices, data)
    choices = choices:split("+")
    local n = self.player:getMark("dianyingfucards")
    local target = data:toPlayer()
    if not self:isFriend(target) then
        if n <= 1 then
            for _,p in ipairs(choices) do
                if string.find(p, "all") then
                    return p
                end
            end
        else
            for _,p in ipairs(choices) do
                if string.find(p, "give") then
                    return p
                end
            end
        end
    end
    if self:isFriend(target) then
        if math.random(1, 3) == 1 then
            for _,p in ipairs(choices) do
                if string.find(p, "all") then
                    return p
                end
            end
        else
            for _,p in ipairs(choices) do
                if string.find(p, "give") then
                    return p
                end
            end
        end
    end
    return choices[math.random(1, #choices)]
end

--封烧

sgs.ai_skill_playerchosen.dianfengshao = function(self, targets)
    for _,p in sgs.qlist(targets) do
        if self:isFriend(p) and (not p:faceUp()) then
            return p
        end
        if self:isFriend(p) and p:getMark("dianfengshaofrom"..self.player:objectName().."-Clear") > 0 then
            return p
        end
    end
    if not self.player:faceUp() then return self.player end
    local enemies = {}
    local unknown = {}
    for _,p in sgs.qlist(targets) do
        if self:isEnemy(p) then
            table.insert(enemies, p)
        elseif (not self:isFriend(p)) and (not self:isEnemy(p)) then
            table.insert(unknown, p)
        end
    end
    if #enemies > 0 then
        self:sort(enemies, "hp")
        for _,p in ipairs(enemies) do
            if p:getMark("dianfengshaofrom"..self.player:objectName().."-Clear") == 0 then
                return p
            end
        end
        for _,p in ipairs(enemies) do
            if p:getMark("dianfengshaofrom"..self.player:objectName().."-Clear") > 0 and ((not p:isWounded()) or (p:faceUp())) then
                return p
            end
        end
    end
    if #unknown > 0 then
        self:sort(unknown, "defense")
        for _,p in ipairs(enemies) do
            if p:getMark("dianfengshaofrom"..self.player:objectName().."-Clear") == 0 then
                return p
            end
        end
        for _,p in ipairs(enemies) do
            if p:getMark("dianfengshaofrom"..self.player:objectName().."-Clear") > 0 and ((not p:isWounded()) or (p:faceUp())) then
                return p
            end
        end
    end
    if self.player:getMark("dianfengshaofrom"..self.player:objectName().."-Clear") == 0 and (self.player:getHp() > 1) then
        return self.player
    elseif self.player:getMark("dianfengshaofrom"..self.player:objectName().."-Clear") > 0 then
        return self.player
    end
    for _,p in sgs.qlist(targets) do
        if p:getMark("dianfengshaofrom"..self.player:objectName().."-Clear") == 0 and ((not self:isFriend(p)) or (self:isFriend(p) and p:getHp() > 1 and self.player:getHp() == 1)) then
            return p
        end
    end

    return self.player
end

sgs.ai_playerchosen_intention.dianfengshao = function(self, from, to)
    if to:getMark("dianfengshaofrom"..self.player:objectName().."-Clear") > 0 then
	    sgs.updateIntention(from, to, -20)
    else
        sgs.updateIntention(from, to, 80)
    end
end

sgs.ai_skill_choice["dianfengshao"] = function(self, choices, data)
    choices = choices:split("+")
    local target = data:toPlayer()
    if self:isFriend(target) then
        if not target:faceUp() then
            for _,choice in ipairs(choices) do
                if string.find(choice, "renew") or string.find(choice, "turn") then
                    return choice
                end
            end
        end
        if target:getHp() > 1 then
            for _,choice in ipairs(choices) do
                if string.find(choice, "damage")  then
                    return choice
                end
            end
        else 
            for _,choice in ipairs(choices) do
                if string.find(choice, "turn")  then
                    return choice
                end
            end
        end
        if target:isWounded() then
            for _,choice in ipairs(choices) do
                if string.find(choice, "recover")  then
                    return choice
                end
            end
        end
    end
    if not self:isFriend(target) then
        for _,choice in ipairs(choices) do
            if string.find(choice, "damage")  then
                return choice
            end
        end
        if target:faceUp() then
            for _,choice in ipairs(choices) do
                if string.find(choice, "turn") or string.find(choice, "renew") then
                    return choice
                end
            end
        end
        if not target:isWounded() then
            for _,choice in ipairs(choices) do
                if string.find(choice, "recover")  then
                    return choice
                end
            end
        end
    end
    return choices[math.random(1, #choices)]       
end

--梦解

sgs.ai_skill_playerschosen.mjmengjie = function(self, targets, max, min)
    return nil
end

--统观

sgs.ai_skill_invoke.mjtongguan = true

sgs.ai_skill_playerchosen.mjtongguan = function(self, targets)
    if #self.enemies > 0 then
        self:sort(self.enemies, "defense")
        for _,p in ipairs(self.enemies) do
            if p:getHandcardNum() > 0 then
                return p
            end
        end
    end
    for _,p in sgs.qlist(targets) do
        if not self:isFriend(p) then return p end
    end
    for _,p in sgs.qlist(targets) do
        return p
    end
    return nil
end

sgs.ai_playerchosen_intention.mjtongguan = function(self, from, to)
	sgs.updateIntention(from, to, 40)
end

sgs.ai_card_intention.mjtongguan = function(self, card, from, tos)
    for _,to in ipairs(tos) do
		sgs.updateIntention(from, to, -60)
	end
end

sgs.ai_skill_use["@@mjtongguan"] = function(self, prompt)
    local card_ids = self.player:getTag("mjtongguancards"):toIntList()
    local cards = {}
    for _,id in sgs.qlist(card_ids) do
        table.insert(cards, sgs.Sanguosha:getCard(id))
    end
    --self:sortByCardNeed(cards)
    self:sortByKeepValue(cards)
    local get = cards[#cards]:getEffectiveId()
    local target = nil
    if math.random(1,3) == 1 then
        self:sort(self.friends, "defense")
        for _,p in ipairs(self.friends) do
            if not p:hasFlag("mjtongguantarget") then
                target = p
                break
            end
        end
    elseif (not self.player:hasFlag("mjtongguantarget")) then
        target = self.player
    end
    if get and target then
        local card_str = string.format("#mjtongguan:%s:->%s", get, target:objectName())
        return card_str
    end
    return "."
end

sgs.ai_skill_choice["#mjtongguan"] = function(self, choices, data)
    choices = choices:split("+")
    for _,p in ipairs(choices) do
        if string.find(p, "equip") then
            return p
        end
    end
    for _,p in ipairs(choices) do
        if string.find(p, "hand") then
            return p
        end
    end
    return choices[math.random(1, #choices)]
end

--鼓舌

sgs.ai_skill_discard.gsgushe = function(self,max,min)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	local dis = {}
    if #cards == 0 then return dis end
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("gsgushetarget") then
            if self:isFriend(p) then return dis end
            break
        end
    end
	table.insert(dis,cards[1]:getEffectiveId())
	return dis
end

local gsgushe_skill={}
gsgushe_skill.name="gsgushe"
table.insert(sgs.ai_skills,gsgushe_skill)
gsgushe_skill.getTurnUseCard=function(self,inclusive)
	local card = self:getMaxCard()
	if not card then return end
	if card:getNumber() + self.player:getMark("&gsgushe")*2 <= 11  and self.player:getHp() == 1 then return end
	if card:getNumber() + self.player:getMark("&gsgushe")*2 <= 6 then return end
	for _,enemy in ipairs(self.enemies)do
		if self.player:canPindian(enemy) then
			return sgs.Card_Parse("#gsgushe:.:")
		end
	end
end

sgs.ai_skill_use_func["#gsgushe"] = function(card, use, self)
	local max_card = self:getMaxCard()
	if not max_card then return end
	self.gsgushe_card = max_card:getEffectiveId()
	self:sort(self.enemies,"handcard")
	local tos = sgs.SPlayerList()
	for _,enemy in ipairs(self.enemies)do
		if self.player:canPindian(enemy) --[[and not self:doNotDiscard(enemy,"h")]] then
			if tos:length() < 3 then
				tos:append(enemy)
			end
		end
	end
	if tos:isEmpty() then return end
	use.card = card
	if use.to then use.to = tos end
end

sgs.ai_card_intention.gsgushe = function(self, card, from, tos)
    for _,to in ipairs(tos) do
		sgs.updateIntention(from, to, 80)
	end
end

sgs.ai_use_priority.gsgushe = 7.8
sgs.ai_use_value.gsgushe = sgs.ai_use_value.ExNihilo-0.1

function sgs.ai_skill_pindian.gsgushe(minusecard,self,requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber()<6 and  minusecard or maxcard )
end

--激词

local gsjici_skill={}
gsjici_skill.name="gsjici"
table.insert(sgs.ai_skills,gsjici_skill)
gsjici_skill.getTurnUseCard=function(self,inclusive)
	if self.player:getMark("&countjici_usedtimes-Clear") > 4 then return end
        local patterns = {"nullification", "snatch", "duel", "dismantlement", "fire_attack", "amazing_grace", "savage_assault", "archery_attack", "ex_nihilo", "god_salvation", "iron_chain"}
	for _,name in sgs.list(patterns)do
        local c = sgs.Sanguosha:cloneCard(name)
		if c and c:isAvailable(self.player)
		and self:getCardsNum(c:getClassName())<1
		and c:isNDTrick() 
        and self.player:getMark("gsjici_juguan_remove_"..name) == 0
		then
         	local dummy = self:aiUseCard(c)
    		if dummy.card
	    	and dummy.to
	     	then
	           	if c:canRecast()
				and dummy.to:length()<1
				then continue end
				self.gsjici_to = dummy.to
				sgs.ai_use_priority["#gsjici"] = sgs.ai_use_priority[c:getClassName()]
                return sgs.Card_Parse("#gsjici:.:"..name)
			end
		end
		if c then c:deleteLater() end
	end
end

sgs.ai_skill_use_func["#gsjici"] = function(card, use, self)
	use.card = card
	if use.to then use.to = self.gsjici_to end
end

sgs.ai_guhuo_card.gsjici = function(self,toname,class_name)
	if self.player:getMark("&countjici_usedtimes-Clear") >= self.player:getMark("&gsjici") then return end
    if self.player:getMark("gsjici_juguan_remove_"..toname) > 0 then return end
	local c = sgs.Sanguosha:cloneCard(toname)
	if c then c:deleteLater() end
	if c and c:isNDTrick()
	and self:getCardsNum(class_name)<1
	then
        return "#gsjici:.:"..toname
	end
end

sgs.ai_use_priority["#gsjici"] = 7.8
sgs.ai_use_value["#gsjici"] = 7.8

--崩坏

sgs.ai_skill_choice["bnbenghuai"] = function(self, choices, data)
    if self.player:getHp() >= 6 and self.player:getHandcardNum() <= 3 then return "all" end
    if self.player:getLostHp() >= 3 and self.player:getHp() > 1 then return "max" end
    if self.player:getHp() == 1 then
        if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then return "hp" end
        for _,card in sgs.qlist(self.player:getHandcards()) do
            if card:getSuit() == sgs.Card_Spade then return "hp" end
        end
        for _,card in sgs.qlist(self.player:getEquips()) do
            if card:getSuit() == sgs.Card_Spade then return "hp" end
        end
        if self.player:getMaxHp() > 1 then return "max" end
    end
    return "hp"
end
sgs.ai_damage_reason_suppress_intention["bnbaonve"] = true

--横征

sgs.ai_skill_invoke.bnhengzheng = function(self, data)
    if self.player:getHp() == 1 then
        if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= 0 then return false end
        local ends = true
        for _,card in sgs.qlist(self.player:getHandcards()) do
            if card:getSuit() == sgs.Card_Spade then ends = false break end
        end
        for _,card in sgs.qlist(self.player:getEquips()) do
            if card:getSuit() == sgs.Card_Spade then ends = false break end
        end
        if ends then return false end
    end
    local friend,enemy = 0, 0
    for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if not p:isNude() then
            if self:isFriend(p) then 
                friend = friend + 1 
            else
                enemy = enemy + 1
            end
        end
    end
    return ((friend < enemy) or (self.player:getHandcardNum() <=3 and friend <= enemy + 1)) and enemy > 1
end

--酒池

local bnjiuchi_skill={}
bnjiuchi_skill.name = "bnjiuchi"
table.insert(sgs.ai_skills,bnjiuchi_skill)
bnjiuchi_skill.getTurnUseCard=function(self,inclusive)
	local cards = self:addHandPile()
	local card
	self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)  do
		if acard:getSuit()==sgs.Card_Spade then
			card = acard
			break
		end
	end
	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local analeptic = sgs.Card_Parse(("analeptic:bnjiuchi[spade:%s]=%d"):format(number,card_id))
	assert(analeptic)
	if sgs.Analeptic_IsAvailable(self.player,analeptic) then
		return analeptic
	end
end

sgs.ai_view_as.bnjiuchi = function(card,player,card_place)
	local str = sgs.ai_view_as.jiuchi(card,player,card_place)
	if not str or str=="" or str==nil then return end
	return string.gsub(str,"jiuchi","bnjiuchi")
end

function sgs.ai_cardneed.bnjiuchi(to,card,self)
	return sgs.ai_cardneed.jiuchi(to,card,self)
end

sgs.ai_use_priority.bnjiuchi = sgs.ai_use_priority.Analeptic

sgs.ai_card_priority.bnjiuchi = function(self,card)
	if table.contains(card:getSkillNames(), "bnjiuchi")
	then
		if self.useValue
		then return 5 end
		return 0.08
	end
end


--据守

sgs.ai_skill_invoke.jsjushou = true

--解围

sgs.ai_skill_playerchosen.jsjiewei = function(self, targets)
    local target = nil
    local min = 0
    for _,p in sgs.qlist(targets) do
        if self:isFriend(p) then
            if (not target) or p:getHandcardNum() < min then
                target = p
                min = p:getHandcardNum()
            end
        end
    end
    return target
end

sgs.ai_playerchosen_intention.jsjiewei = function(self, from, to)
    sgs.updateIntention(from, to, -80)
end

--行殇

sgs.ai_skill_invoke.xsxingshang = true

sgs.ai_skill_playerchosen.xsxingshang = function(self, targets)
    self:sort(self.enemies, "hp")
    for _,enemy in ipairs(self.enemies) do
        if enemy:getHp() == 1 then return enemy end
    end
    for _,enemy in ipairs(self.enemies) do
        if enemy:getMark("xsxingshangfrom"..self.player:objectName()) == 0 then return enemy end
    end
    if #self.enemies > 0 then return self.enemies[1] end
    return nil
end

sgs.ai_playerchosen_intention.xsxingshang = function(self, from, to)
    sgs.updateIntention(from, to, 80)
end

--放逐

sgs.ai_need_damaged.xsfangzu = function (self,attacker,player)
	if not player:hasSkill("xsfangzu") then return false end
	local enemies = self:getEnemies(player)
	if #enemies<1 then return false end
	self:sort(enemies,"defense")
	for _,enemy in ipairs(enemies)do
		if player:getLostHp()<1 and self:toTurnOver(enemy,player:getLostHp()+1) then
			return true
		end
	end
	local friends = self:getFriends(player, true)
	self:sort(friends,"defense")
	for _,friend in ipairs(friends)do
		if not self:toTurnOver(friend,player:getLostHp()+1) then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.xsfangzu = function(self,targets)
	return sgs.ai_skill_playerchosen.fangzhu(self,targets)
end

sgs.ai_playerchosen_intention.xsfangzu = function(self,from,to)
	return sgs.ai_playerchosen_intention.fangzhu(self,from,to)
end

sgs.ai_skill_choice["xsfangzu"] = function(self, choices, data)
	local target = data:toPlayer()
    choices = choices:split("+")
    if self:isFriend(target) 
    or (target:faceUp() and target:getHp() > 1 and target:getHandcardNum() >= self.player:getLostHp())then
        for _,p in ipairs(choices) do
            if string.find(p, "turn") then return p end
        end
    end
    if not self:toTurnOver(self.player,target:getLostHp()+1) then 
        for _,p in ipairs(choices) do
            if string.find(p, "turn") then return p end
        end
    end
   
    for _,p in ipairs(choices) do
        if string.find(p, "discard") then return p end
    end
end

--颂威

sgs.ai_skill_invoke.xssongwei = true

--险进

sgs.ai_skill_choice["ty_xianjin"] = function(self, choices, data)
    local items = choices:split("+")
    if table.contains(items, "ty_tuoyu_fengtian") and self.player:getLostHp() > 2 and self:getCardsNum("Peach") > 1 then return "ty_tuoyu_fengtian" end
    if table.contains(items, "ty_tuoyu_qingqu") and self:getCardsNum("Slash") >= 3 then return "ty_tuoyu_qingqu" end
    if table.contains(items, "ty_tuoyu_junshan") then return "ty_tuoyu_junshan" end
    if table.contains(items, "ty_tuoyu_fengtian") then return "ty_tuoyu_fengtian" end
    return items[math.random(1, #choices)]
end

--拓域

sgs.ai_skill_choice["ty_tuoyu"] = function(self, choices, data)
    local items = choices:split("+")
    if #items == 1 then return items[1] end
    local card = data:toCard()
    if table.contains(items, "ty_tuoyu_fengtian") then 
        if card:isKindOf("Peach") or card:isKindOf("god_salvation") then return "ty_tuoyu_fengtian" end
        if card:isKindOf("Analeptic") then
            if self.player:getHp() <= 0 or self:getCardsNum("Analeptic") == 0 then return "ty_tuoyu_fengtian" end
        end
        if not card:isDamageCard() then table.removeOne(items, "ty_tuoyu_fengtian") end
    end
    if #items == 1 then return items[1] end
    if table.contains(items, "ty_tuoyu_qingqu") then
        if card:isKindOf("Slash") and self:getCardsNum("Slash") > 0 then return "ty_tuoyu_qingqu" end
        if card:isKindOf("Analeptic") and self:getCardsNum("Analeptic") > 0 then return "ty_tuoyu_qingqu" end
        table.removeOne(items, "ty_tuoyu_qingqu")
    end
    if #items == 1 then return items[1] end
    return items[math.random(1, #choices)]
end

--奇径

sgs.ai_skill_playerchosen.tyqijin = function(self, targets)
    for _,p in sgs.list(targets)do
		local n = 0
		for i=1,#self.friends_noself do
			i = p:getNextAlive(i)
			if self:isFriend(i)
			and i~=self.player
			then n = n+1
			else break end
		end
		if #self.friends_noself-n<2
		and not self:isFriend(p)
		then
			return p
		end
	end
    return nil
end

--摧心

sgs.ai_skill_invoke.tycuixin = function(self,data)
    return self:isEnemy(data:toPlayer())
end
--捐甲
sgs.ai_ajustdamage_from.jjjuanjia = function(self, from, to, card, nature)
	if (card and (card:isKindOf("Slash") )) and table.contains(card:getSkillNames(), "jjjuanjia")
	then
		return 1
	end
end

--挈挟

sgs.ai_skill_choice["jjqiexie"] = function(self, choices, data)
    local items = choices:split("+")
    table.removeOne(items, "cancel")
    return items[math.random(1,#items)]
end

--摧决

sgs.ai_skill_choice["jjcuijue"] = function(self, choices, data)
    local items = choices:split("+")
    local avoid = {"jjcuijue", "jjqiexie"}
    for _,choice in ipairs(avoid) do
        if table.contains(items, choice) then table.removeOne(items, choice) end
    end
    if #items == 0 then return "jjcuijue" end
    return items[math.random(1,#items)]
end

local jjcuijue_skill = {}
jjcuijue_skill.name = "jjcuijue"
table.insert(sgs.ai_skills, jjcuijue_skill)
jjcuijue_skill.getTurnUseCard = function(self, inclusive)
	local skills = self.player:getVisibleSkillList()
    local choices = {}
    local avoid = {"jjcuijue", "jjqiexie"}
    for _,skill in sgs.qlist(skills) do
        if (not skill:isAttachedLordSkill()) and (not table.contains(avoid, skill:objectName())) then
            table.insert(choices, skill:objectName())
            break
        end
    end
    if #choices == 0 then return end
    if math.random(1,4) == 1 and #choices < 2 then return end
	return sgs.Card_Parse("#jjcuijue:.:")
end

sgs.ai_skill_use_func["#jjcuijue"] = function(card, use, self)
	self:updatePlayers()
	if #self.enemies <= 0 then return end
	local target = nil
	self:sort(self.enemies, "hp")
	for _,p in ipairs(self.enemies) do
        if self.player:inMyAttackRange(p) and p:getMark("jjcuijue_"..self.player:objectName().."-Clear") == 0 then 
            target = p 
            break
        end
    end
	if not target then return end
	if target then
		local card_str = "#jjcuijue:.:->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

--勤王

sgs.ai_skill_playerschosen.ny_qingwang_diy = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local n = max
    if self.player:getHp() > 1 then
        self:sort(self.enemies, "defense")
        for _,enemy in ipairs(self.enemies) do
            if (not enemy:isNude()) then
                selected:append(enemy)
                n = n - 1
            end
            if n <= 0 then return selected end
        end

        self:sort(self.friends, "defense", true)
        for _,friend in ipairs(self.friends) do
            for _,card in sgs.qlist(friend:getHandcards()) do
                if selected:contains(friend) then break end
                if card:isKindOf("Slash") then
                    selected:append(friend)
                    n = n - 1
                    break
                end
            end
            if n <= 0 then return selected end
        end
    else
        self:sort(self.friends, "defense", true)
        for _,friend in ipairs(self.friends) do
            for _,card in sgs.qlist(friend:getHandcards()) do
                if card:isKindOf("Slash") then
                    selected:append(friend)
                    n = n - 1
                    break
                end
            end
            if n <= 0 then return selected end
        end

        self:sort(self.enemies, "defense")
        for _,enemy in ipairs(self.enemies) do
            if (not enemy:isNude()) and (not selected:contains(enemy)) then
                selected:append(enemy)
                n = n - 1
            end
            if n <= 0 then return selected end
        end
    end
    return selected
end

sgs.ai_skill_discard.ny_qingwang_diy = function(self,max,min)
    local target = self.room:getTag("ny_qingwang_target"):toPlayer()
    local discard = {}
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    if self:isFriend(target) then
        for _,card in ipairs(cards) do
            if card:isKindOf("Slash") then
                table.insert(discard, card:getEffectiveId())
                return discard
            end
        end
    end
    if #cards > 0 then
        table.insert(discard, cards[1]:getEffectiveId())
    end
    return discard
end

sgs.ai_skill_invoke.ny_qingwang_diy = function(self, data)
    local n = 0
    for _,target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if target:getMark("ny_qingwang_diy_slashto_"..self.player:objectName().."-Clear") > 0 then
            if self:isEnemy(target) then
                n = n - 1
            else
                n = n + 1.2
            end
        end
    end
    return n > 0
end

--战绝

local ny_zhanjue_diy_skill = {}
ny_zhanjue_diy_skill.name = "ny_zhanjue_diy"
table.insert(sgs.ai_skills, ny_zhanjue_diy_skill)
ny_zhanjue_diy_skill.getTurnUseCard = function(self, inclusive)
    local value = 1.5
	value = value + math.max(1, self.player:getLostHp())
    if self.player:getHp() == 1 then value = value - 4 end

    if self.player:hasSkill("ny_qingwang_diy") and self.player:getMark("ny_qingwang_diy-Clear") == 0 then
        local n = self.player:getHandcardNum()
        for _,target in ipairs(self.enemies) do
            if (not target:isNude()) then
                n = n - 1
                value = value + 1.5
            end
            if n <= 0 then break end
        end
    end

    if value < 0 then return end

    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
    duel:deleteLater()
    local dummy_use = self:aiUseCard(duel, dummy())
    if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
        return sgs.Card_Parse("#ny_zhanjue_diy:.:")
    end
end

sgs.ai_skill_use_func["#ny_zhanjue_diy"] = function(card,use,self)
    local usec = {isDummy=true,to=sgs.SPlayerList()}
    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
    duel:deleteLater()
    local dummy_use = self:aiUseCard(duel, dummy())
    if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        local card_str = string.format("#ny_zhanjue_diy:.:->%s", table.concat(tos, "+"))
        local acard = sgs.Card_Parse(card_str)
        use.card = acard
        if use.to then use.to = dummy_use.to end
    end
end

sgs.ai_skill_use["@@ny_zhanjue_diy"] = function(self, prompt)
    local value = 1.5
	value = value + math.max(1, self.player:getLostHp())
    local n = self.player:getHandcardNum()
    if self.player:getHp() == 1 then 
        value = value - 4
        if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then return end
    end

    if self.player:hasSkill("ny_qingwang_diy") and self.player:getMark("ny_qingwang_diy-Clear") == 0 then
        for _,target in ipairs(self.enemies) do
            if (not target:isNude()) then
                n = n - 1
                value = value + 1.5
            end
            if n <= 0 then break end
        end
    end

    if value < 0 then return "." end

    local usec = {isDummy=true,to=sgs.SPlayerList()}
    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
    duel:deleteLater()
    self:useCardByClassName(duel, usec)
    if usec.to and usec.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(usec.to) do
            table.insert(tos, to:objectName())
        end
        local card_str = string.format("#ny_zhanjue_diy:.:->%s", table.concat(tos, "+"))
        return card_str
    end
    return "."
end

sgs.ai_use_priority.ny_zhanjue_diy = 2.9

--定措

sgs.ai_skill_invoke.ny_second_dingcuo = function(self, data)
    local n = self.player:getMark("&ny_second_dingcuo-Clear")
    if (n + 1) < self.player:getMaxHp() then return true end
    if self.player:getHandcardNum() <= self.player:getMaxHp() then return true end
    local first
    local second
    local count = 0
    for _,id in sgs.qlist(self.room:getDrawPile()) do
        if count == 0 then
            first = sgs.Sanguosha:getCard(id)
        elseif count == 1 then
            second = sgs.Sanguosha:getCard(id)
        end
        count = count + 1
        if count >= 2 then break end
    end
    if first and second and first:sameColorWith(second) then return true end
    return false 
end

--狷狭

sgs.ai_skill_invoke.ny_second_juanxia = function(self, data)
    local target = nil
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("ny_second_juanxia_target") then
            target = p
            break
        end
    end
    if not target then return true end
    if self:isEnemy(target) then return true end
    return false
end

sgs.ai_skill_choice["ny_second_juanxia"] = function(self, choices, data)
    local n = 0
    for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        n = n + p:getMark("ny_second_juanxia"..self.player:objectName().."-SelfClear")
    end
    local items = choices:split("+")
    table.removeOne(items, "cancel")
    for _,item in ipairs(items) do
        local card = sgs.Sanguosha:cloneCard(item, sgs.Card_SuitToBeDecided, -1)
        card:deleteLater()
        --local use = self:aiUseCard(card)
        local use = {isDummy=true,to=sgs.SPlayerList()}
        self:useCardByClassName(card, use)
        if use.to and use.card then
            if card:canRecast()
            and use.to:length()<1
            then continue end
            local add = 0
            for _,p in sgs.qlist(use.to) do
                if self:isEnemy(p) then
                    add = add + 1
                end
            end
            if add == 0 then return item end
            if add + n <= self.player:getHp() then return item end
        end
    end
    return "cancel"
end

sgs.ai_skill_use["@@ny_second_juanxia"] = function(self, prompt)
    local pattern = self.player:property("ny_second_juanxia_card"):toString()
    local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
    card:deleteLater()

    --local use = self:aiUseCard(card)
    local use = {isDummy=true,to=sgs.SPlayerList()}
    self:useCardByClassName(card, use)
    if use.to then
        local tos = {}
        for _,to in sgs.qlist(use.to) do
            table.insert(tos, to:objectName())
        end
        return string.format("#ny_second_juanxia:.:->%s", table.concat(tos, "+"))
    end
    return "."
end

--恂恂

sgs.ai_skill_invoke.nyarz_xunxun = true

--忘隙

sgs.ai_skill_invoke.nyarz_wangxi = function(self, data)
    if self.player:getPhase() ~= sgs.Player_NotActive then return true end
    local target
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nyarz_wangxi_target") then
            target = p
        end
    end
    if not target then return true end
    if target and self:isFriend(target) then return true end
    if self.player:getLostHp() > 1 then return true end
end

--伪诚

sgs.ai_skill_invoke.nyarz_weicheng = true

--盗书

local nyarz_daoshu_skill = {}
nyarz_daoshu_skill.name = "nyarz_daoshu"
table.insert(sgs.ai_skills, nyarz_daoshu_skill)
nyarz_daoshu_skill.getTurnUseCard = function(self, inclusive)
    return sgs.Card_Parse("#nyarz_daoshu:.:")
end

sgs.ai_skill_use_func["#nyarz_daoshu"] = function(card,use,self)
    self:sort(self.enemies, "handcard")

    for _,enemy in ipairs(self.enemies) do
        --if enemy:isNude() then continue end
        if enemy:getMark("couldnt_nyarz_daoshu_from"..self.player:objectName()) == 0 and (not enemy:isNude()) then
            local names = enemy:getMarkNames()
            local mark = nil
            for _,name in ipairs(names) do
                if enemy:getMark(name) > 0 and name:startsWith("&nyarz_daoshu") then
                    mark = name
                    break
                end
            end

            if not mark then 
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
            if mark then
                for _,cc in sgs.qlist(enemy:getCards("he")) do
                    if string.find(mark, cc:getSuitString()) then
                    else
                        if math.random(1,2) == 1 and self.player:getKingdom() ~= enemy:getKingdom() then break end
                        use.card = card
                        if use.to then use.to:append(enemy) end
                        return
                    end
                end
            end
        end
    end
end

sgs.ai_skill_playerchosen.nyarz_daoshu = function(self, targets)
    local all = sgs.QList2Table(targets)
    self:sort(all, "defense")
    for _,a in ipairs(all) do
        if self:isFriend(a) and self.player:objectName() ~= a:objectName() then
            return a
        end
    end
    return self.player
end

sgs.ai_skill_cardchosen.nyarz_daoshu = function(self, who,flags,reason,method)
    local enemy = who
    local names = enemy:getMarkNames()
    local mark = nil
    for _,name in ipairs(names) do
        if enemy:getMark(name) > 0 and name:startsWith("&nyarz_daoshu") then
            mark = name
            break
        end
    end

    local cards = sgs.QList2Table(who:getCards("he"))
    self:sortByKeepValue(cards, true)
    if not mark then return cards[1]:getEffectiveId() end
    for _,card in ipairs(cards) do
        if string.find(mark, card:getSuitString()) then
        else
            return card:getEffectiveId()
        end
    end
    return cards[1]:getEffectiveId()
end
    

sgs.ai_use_priority.nyarz_daoshu = 8.8

--流转

sgs.ai_skill_invoke.nyarz_liuzhuan = function(self, data)
    local target
    for _,player in sgs.qlist(self.room:getAlivePlayers()) do
        if player:hasFlag("nyarz_liuzhuan_target") then
            target = player
            break
        end
    end
    if not target then return false end
    if target then
        if self:isEnemy(target) then
            if target:getPhase() == sgs.Player_NotActive then return false end
            if target:getPhase() == sgs.Player_Start then return true end
            if target:getPhase() == sgs.Player_Play then
                local names = {"snatch","ex_nihilo","iron_chain","amazing_grace"}
                for _,card in sgs.qlist(target:getHandcards()) do
                    if table.contains(names, card:objectName()) then return true end
                end
                for _,skill in sgs.qlist(target:getVisibleSkillList()) do
                    if not skill:isAttachedLordSkill() then
                        local translation = sgs.Sanguosha:translate(":"..skill:objectName())
                        if string.find(translation, "摸") then
                            return true
                        end
                    end
                end
            end
        end
        if self:isFriend(target) then
            if target:getPhase() == sgs.Player_NotActive then return true end
            if target:getPhase() == sgs.Player_Start then return false end
            if target:getPhase() == sgs.Player_Play then
                local names = {"snatch","ex_nihilo","iron_chain","amazing_grace"}
                for _,card in sgs.qlist(target:getHandcards()) do
                    if table.contains(names, card:objectName()) then return false end
                end
            end
            return true
        end
    end
    return false 
end

--铸币

sgs.ai_skill_invoke.nyarz_zhubi = function(self, data)
    local target
    for _,player in sgs.qlist(self.room:getAlivePlayers()) do
        if player:getPhase() == sgs.Player_Start then
            target = player
            break
        end
    end
    if target and self:isEnemy(target) then
        if target:getJudgingArea():isEmpty() then 
            return false
        else
            local cards = sgs.QList2Table(target:getJudgingArea())
            if cards[#cards]:objectName() == "supply_shortage" then
                return true
            end
            return false 
        end
    end
    if target and self:isFriend(target) then
        if target:getJudgingArea():isEmpty() then 
            return true
        else
            local cards = sgs.QList2Table(target:getJudgingArea())
            if cards[#cards]:objectName() == "supply_shortage" then
                return false
            end
            return true
        end
    end
    return false
end

sgs.ai_skill_discard.nyarz_zhubi = function(self,max,min)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
    local dis = {}
    if #cards == 0 then return dis end
    if (cards[1]:objectName() == "peach" or cards[1]:objectName() == "analeptic") and self.player:isWounded() then return dis end
    table.insert(dis, cards[1]:getEffectiveId())
    return dis
end

--破军

sgs.ai_skill_invoke.nyarz_pojun = function(self, data)
    local target
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nyarz_pojun_target") then
            target = p
            break
        end
    end
    return target and self:isEnemy(target)
end

sgs.ai_skill_choice["nyarz_pojun"] = function(self, choices, data)
	local items = choices:split("+")
    return items[#items]
end

sgs.ai_skill_use["@@nyarz_pojun"] = function(self, prompt)
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
    slash:setSkillName("nyarz_pojun")
    slash:deleteLater()

    local dummy_use = self:aiUseCard(slash)
    if dummy_use.card then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return slash:toString().."->"..table.concat(tos, "+")
    end
    return "."
end
sgs.hit_skill = sgs.hit_skill .. "|nyarz_pojun"

--绝策

sgs.ai_skill_invoke.nyarz_juece = function(self, data)
    local target = findPlayerByFlag(self.room, "nyarz_juece_target")
    if not target then return false end
    if self:isFriend(target) and self:needToLoseHp(target, self.player, nil) and self:damageIsEffective(target) then return true end
    if not self:isEnemy(target) then return false end
    if not self:cantbeHurt(target) and self:damageIsEffective(target) and self:canDamage(target,self.player,nil) then return true end
    if self.player:getPhase() ~= sgs.Player_NotActive then return true end
    if self.player:isNude() then return true end
    if self.player:getHandcardNum() <= 1 and (not target:isKongcheng()) and target:getHp() > 2 then return false end
    return true
end

sgs.ai_skill_choice["nyarz_juece"] = function(self, choices, data)
    local target = data:toPlayer()
    if not target or self:isFriend(target) then return "draw" end
    if self:isEnemy(target) and target:getHp() == 2 then return "damage" end
    if self.player:getHandcardNum() <= 2 then return "draw" end
    if self.player:getLostHp() > 1 then return "draw" end
    if target:getHp() == 1 then return "draw" end
    return "damage"
end

--灭计

local nyarz_mieji_skill = {}
nyarz_mieji_skill.name = "nyarz_mieji"
table.insert(sgs.ai_skills, nyarz_mieji_skill)
nyarz_mieji_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#nyarz_mieji") then return end
    return sgs.Card_Parse("#nyarz_mieji:.:")
end

sgs.ai_skill_use_func["#nyarz_mieji"] = function(card,use,self)
    local target = nil
    self:sort(self.enemies, "handcard")
    for _,enemy in ipairs(self.enemies) do
        if not enemy:isKongcheng() then
            target = enemy
            break
        end
    end
    if not target then return "." end
    local max = target:getHandcardNum()
    local cards = self.player:getHandcards()
    local show = {}
    for _,card in sgs.qlist(cards) do
        if card:isNDTrick() and card:objectName() ~= "nullification" then
            table.insert(show, card:getEffectiveId())
            max = max - 1
        end
        if max <= 0 then break end
    end
    if #show == 0 then return end
    local card_str = string.format("#nyarz_mieji:%s:", table.concat(show, "+"))
    use.card = sgs.Card_Parse(card_str)
    if use.to then use.to:append(target) end
end

sgs.ai_use_priority.nyarz_mieji = 8.7


function sgs.ai_cardneed.nyarz_mieji(to,card)
	return card:isNDTrick()
end



--焚城

local nyarz_fencheng_skill = {}
nyarz_fencheng_skill.name = "nyarz_fencheng"
table.insert(sgs.ai_skills, nyarz_fencheng_skill)
nyarz_fencheng_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("@nyarz_fencheng_mark") == 0 then return end
    local value = 0
    for _,target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if self:isFriend(target) then
            value = value - 1.1
            if target:getHp() == 1 then value = value - 1.1 end
            if not target:getEquips():isEmpty() then
                value = value - 0.21*target:getEquips():length()
            end
        else
            value = value +1
            if target:getHp() == 1 then value = value + 1 end
            if not target:getEquips():isEmpty() then
                value = value + 0.2*target:getEquips():length()
            end
        end
    end
    if value < 0 then return end
    return sgs.Card_Parse("#nyarz_fencheng:.:")
end

sgs.ai_skill_use_func["#nyarz_fencheng"] = function(card,use,self)
    use.card = card
end

sgs.ai_use_priority.nyarz_mieji = 7.7

--彰才

sgs.ai_skill_invoke.nyarz_zhangcai_wu = true

--儒贤

local nyarz_ruxian_wu_skill = {}
nyarz_ruxian_wu_skill.name = "nyarz_ruxian_wu"
table.insert(sgs.ai_skills, nyarz_ruxian_wu_skill)
nyarz_ruxian_wu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@nyarz_ruxian_wu_mark") > 0 then
		return sgs.Card_Parse("#nyarz_ruxian_wu:.:")
	end
end

sgs.ai_skill_use_func["#nyarz_ruxian_wu"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_priority.nyarz_ruxian_wu = 10

--旋风

sgs.ai_skill_playerchosen.nyarz_xuanfeng = function(self, targets)
    local enemy = {}
    for _,target in sgs.qlist(targets) do
        if self:isEnemy(target) and self:doDisCard(target, "he") then
            table.insert(enemy, target)
        end
    end
    if #enemy == 0 then return nil end
    self:sort(enemy, "defense")
    return enemy[1]
end

sgs.ai_skill_playerchosen.nyarz_xuanfeng_damageto = function(self, targets)
    local enemy = {}
    for _,target in sgs.qlist(targets) do
        if self:isEnemy(target) and not self:cantbeHurt(target) and self:damageIsEffective(target) and self:canDamage(target,self.player,nil) then
            table.insert(enemy, target)
        end
    end
    if #enemy == 0 then return nil end
    self:sort(enemy, "hp")
    return enemy[1]
end

sgs.lose_equip_skill = sgs.lose_equip_skill .. "|nyarz_xuanfeng"

--勇进

local nyarz_yongjin_skill = {}
nyarz_yongjin_skill.name = "nyarz_yongjin"
table.insert(sgs.ai_skills, nyarz_yongjin_skill)
nyarz_yongjin_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#nyarz_yongjin") then return end
    local need = {}
    local card = nyarz_yongjinCard:clone()

    local cards = sgs.QList2Table(self.player:getCards("he"))
    if #cards > 1 then table.insert(need, "recast") end

    if self.room:canMoveField("ej") then
        local from, card, to = self:moveField()
        if from and card and to then table.insert(need, "move") end
    end

    if #need == 1 then
        card:setUserString(need[1])
        if need[1] == "recast" then
            --self:sortByCardNeed(cards)
            self:sortByKeepValue(cards)
            card:addSubcard(cards[1])
            card:addSubcard(cards[2])
            return sgs.Card_Parse(card:toString())
        else
            return sgs.Card_Parse(card:toString())
        end
    elseif #need > 1 and (not self:isWeak()) then
        card:setUserString("all")
        --self:sortByCardNeed(cards)
        self:sortByKeepValue(cards)
        card:addSubcard(cards[1])
        card:addSubcard(cards[2])
        return sgs.Card_Parse(card:toString())
    elseif #need > 1 and self:isWeak() then
        table.removeOne(need, need[math.random(1,#need)])
        card:setUserString(need[1])
        if need[1] == "recast" then
            --self:sortByCardNeed(cards)
            self:sortByKeepValue(cards)
            card:addSubcard(cards[1])
            card:addSubcard(cards[2])
            return sgs.Card_Parse(card:toString())
        else
            return sgs.Card_Parse(card:toString())
        end
    end
    return 
end

sgs.ai_skill_use_func["#nyarz_yongjin"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_priority.nyarz_yongjin = 5.5

sgs.lose_equip_skill = sgs.lose_equip_skill.."|nyarz_xuanfeng"

--激峭

sgs.ai_skill_invoke.nyarz_jiqiao = function(self, data)
    if self.player:getLostHp() < 2 or self.player:getHp() > 3 then return true end
    local colors = {}
    for _,cc in sgs.qlist(self.player:getHandcards()) do
        local color = cc:getColorString()
        if (not table.contains(colors, color)) then
            table.insert(colors, color)
        end
    end
    local i = 2
    for _,id in sgs.qlist(self.room:getDrawPile()) do
        local card = sgs.Sanguosha:getCard(id)
        local color = card:getColorString()
        if (not table.contains(colors, color)) then
            table.insert(colors, color)
        end
        i = i - 1
        if i <= 0 then break end
    end
    if #colors <= 1 then return true end

    local red = 0
    local black = 0
    local other = 0
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isRed() then red = red + 1
        elseif card:isBlack() then black = black + 1
        else other = other + 1 end
    end
    local i = 3
    for _,id in sgs.qlist(self.room:getDrawPile()) do
        local card = sgs.Sanguosha:getCard(id)
        if card:isRed() then red = red + 1
        elseif card:isBlack() then black = black + 1
        else other = other + 1 end
        i = i - 1
        if i <= 0 then break end
    end
    if (red == 0) or (black == 0) or (other == 0) then
        return (red == 1) or (black == 1) or (other == 1)
    end
    return false
end

sgs.ai_skill_discard.nyarz_jiqiao = function(self,max,min)
    local dis = {}
    local cards = sgs.QList2Table(self.player:getHandcards())
    --self:sortByCardNeed(cards)
    self:sortByKeepValue(cards)
    local red = 0
    local black = 0
    local other = 0
    for _,card in ipairs(cards) do
        if card:isRed() then red = red + 1
        elseif card:isBlack() then black = black + 1
        else other = other + 1 end
    end

    for _,card in ipairs(cards) do
        if card:isRed() then
            if red == 1 then
                table.insert(dis, card:getEffectiveId())
                break
            end
        elseif  card:isBlack() then
            if black == 1 then
                table.insert(dis, card:getEffectiveId())
                break
            end
        else
            if other == 1 then
                table.insert(dis, card:getEffectiveId())
                break
            end
        end
    end
    return dis
end

--仁望

sgs.ai_skill_invoke.nyarz_renwang = function(self, data)
    local damage = self.room:getTag("nyarz_renwang"):toDamage()
    return self:isFriend(damage.to)
end
sgs.ai_can_damagehp.nyarz_renwang = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isFriend(from) and from:getMark("nyarz_renwang-Clear") == 0
	end
end

--仁德

sgs.ai_skill_invoke.nyarz_rende = function(self, data)
    if self.player:getPhase() ~= sgs.Player_Finish then return true end
    if self.player:getMark("nyarz_rende_draw-Clear") >= 3 then return true end
    if self.player:getMark("&nyarz_rende") <= 0 then return false end
    if self.player:getHandcardNum() <= 1 then return true end
    if self.player:getMark("&nyarz_rende") <= 1 then return false end
    return true
end

local nyarz_rende_skill = {}
nyarz_rende_skill.name = "nyarz_rende"
table.insert(sgs.ai_skills, nyarz_rende_skill)
nyarz_rende_skill.getTurnUseCard = function(self, inclusive)
	if #self.friends_noself == 0 then return end
    local min = math.min(3, self.player:getMaxCards())
    if self.player:getHandcardNum() <= min then return end
    return sgs.Card_Parse("#nyarz_rende:.:")
end

sgs.ai_skill_use_func["#nyarz_rende"] = function(card, use, self)
    self:sort(self.friends_noself, "defense")
    local need = {}
    for _,p in ipairs(self.friends_noself) do
        if p:getMark("nyarz_rende_give-PlayClear") == 0 then
            table.insert(need, p)
        end
    end

    local give = 0 
    if #need == 0 then return end
    if #need == 1 then give = math.max(2, self.player:getHandcardNum() - self.player:getMaxCards()) end
    if #need > 1 then give = 2 end

    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
    local usecards = {}
    for _,cc in ipairs(cards) do
        table.insert(usecards, cc:getEffectiveId())
        give = give - 1
        if give <= 0 then break end
    end
    if give > 0 then return end
    local card_str = string.format("#nyarz_rende:%s:->%s", table.concat(usecards,"+"), need[1]:objectName())
    use.card = sgs.Card_Parse(card_str)
    if use.to then use.to:append(need[1]) end
end

sgs.ai_guhuo_card.nyarz_rendebasic = function(self,toname,class_name)
    if self.player:getMark("&nyarz_rende") <= 0 then return end
    if self.player:getMark("nyarz_rende_used2_lun") >= 4 then return end
    if class_name and self:getCardsNum(class_name) > 0 then return end

	local card = sgs.Sanguosha:cloneCard(toname, sgs.Card_SuitToBeDecided, -1)
    card:deleteLater()
    if (not card) or (not card:isKindOf("BasicCard")) then return end

    return "#nyarz_rendebasic:.:"..toname
end

local nyarz_rendebasic_skill = {}
nyarz_rendebasic_skill.name = "nyarz_rendebasic"
table.insert(sgs.ai_skills, nyarz_rendebasic_skill)
nyarz_rendebasic_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("&nyarz_rende") <= 0 then return end
    if self.player:getMark("nyarz_rende_used2_lun") >= 4 then return end

    local basics = {"peach", "analeptic", "thunder_slash", "slash", "fire_slash"}
    for _,name in ipairs(basics) do
        local card = sgs.Sanguosha:cloneCard(name, sgs.Card_SuitToBeDecided, -1)
        card:deleteLater()
        if card and card:isAvailable(self.player) then
            --local dummy = self:aiUseCard(card)
            local dummy = {isDummy=true,to=sgs.SPlayerList()}
            self:useCardByClassName(card, dummy)
            local num = self:getCardsNum(card:getClassName(),"he")
			if dummy.card and dummy.to and ((num < 1) or (self.player:getMark("&nyarz_rende") >= 3)) then
                self.nyarz_rendebasicto = dummy.to
                return sgs.Card_Parse("#nyarz_rendebasic:.:"..name)
            end
        end
	end
end

sgs.ai_skill_use_func["#nyarz_rendebasic"] = function(card, use, self)
    use.card = card
	if use.to
	then
		use.to = self.nyarz_rendebasicto
	end
end

--章武

sgs.ai_skill_invoke.nyarz_zhangwu = function(self, data)
    if self.player:getMark("&nyarz_rende") >= 2 then return false end
    if #self.friends_noself == 0 then return true end
    if self:isWeak() then return true end
    return false
end

--龙怒

local nyarz_longnu_skill = {}
nyarz_longnu_skill.name = "nyarz_longnu"
table.insert(sgs.ai_skills, nyarz_longnu_skill)
nyarz_longnu_skill.getTurnUseCard = function(self, inclusive)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local red = {}
    local tricks = {}
    for _,card in ipairs(cards) do
        if card:isRed() then table.insert(red, card) end
        if card:isKindOf("TrickCard") then table.insert(tricks, card) end
    end
    self:sortByKeepValue(red)
    self:sortByKeepValue(tricks)
    if #red > 0 then
        local slashs = {"thunder_slash", "slash", "fire_slash"}
        for _,name in ipairs(slashs) do
            local card = sgs.Sanguosha:cloneCard(name, sgs.Card_SuitToBeDecided, -1)
            card:addSubcard(red[1])
            card:deleteLater()
            if card and card:isAvailable(self.player) then
                local dummy_use = self:aiUseCard(card)
                local num = self:getCardsNum(card:getClassName(),"he")
			    if dummy_use.card and dummy_use.to and num < 1 then
                    self.nyarz_longnuto = dummy_use.to
                    return sgs.Card_Parse("#nyarz_longnu:"..red[1]:getEffectiveId()..":")
                end
            end
	    end
    end
    if #tricks > 0 then
        self.nyarz_longnuto = sgs.SPlayerList()
        return sgs.Card_Parse("#nyarz_longnu:"..tricks[1]:getEffectiveId()..":")
    end
end

sgs.ai_skill_use_func["#nyarz_longnu"] = function(card, use, self)
    use.card = card
	if use.to
	then
		use.to = self.nyarz_longnuto
	end
end

sgs.ai_skill_choice["nyarz_longnu"] = function(self, choices, data)
    if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return "slash" end
    local slashs = {"thunder_slash", "slash", "fire_slash"}
    for _,name in ipairs(slashs) do
        local card = sgs.Sanguosha:cloneCard(name, sgs.Card_SuitToBeDecided, -1)
        card:deleteLater()
        if card and card:isAvailable(self.player) then
            --local dummy = self:aiUseCard(card)
            local dummy = {isDummy=true,to=sgs.SPlayerList()}
            self:useCardByClassName(card, dummy)
			if dummy.card and dummy.to then
                return name
            end
        end
	end
    return "slash"
end

sgs.ai_view_as.nyarz_longnu = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isRed() then
		return ("slash:nyarz_longnu[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_ajustdamage_to.nyarz_shibei = function(self,from,to,card,nature)
	if getKnownCard(from,self.player,"TrickCard")>1
	or getKnownCard(from,self.player,"Slash")>1 and (getKnownCard(from,self.player,"Crossbow")>0 or from:hasSkills(sgs.double_slash_skill))
	or from:hasSkills(sgs.straight_damage_skill)
	or self:getOverflow(from)>0 then
	else
		return to:getMark("nyarz_shibei-Clear")<1
	end
end
--渐营

sgs.ai_skill_invoke.nyarz_jianying = true

local nyarz_jianying_skill = {}
nyarz_jianying_skill.name = "nyarz_jianying"
table.insert(sgs.ai_skills, nyarz_jianying_skill)
nyarz_jianying_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getHandcardNum() <= self.player:getMaxCards() then return end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    if #cards < 2 then return end
    --self:sortByCardNeed(cards)
    self:sortByKeepValue(cards)

    local card_str = string.format("#nyarz_jianying:%s+%s:",cards[1]:getEffectiveId(),cards[2]:getEffectiveId())
    return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#nyarz_jianying"] = function(card, use, self)
    use.card = card
end

sgs.ai_card_priority.nyarz_jianying = function(self,card)
    local mark = string.format("&nyarz_jianying+%s_char",card:getSuitString())
	if (self.player:getMark(mark) > 0) or (self.player:getMark("nyarz_jianying_number") == card:getNumber())
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end
--融火
sgs.ai_ajustdamage_from.nyarz_ronghuo_mou = function(self, from, to, card, nature)
	if nature == sgs.DamageStruct_Fire then
        local kingdoms = {}
        for _,p in sgs.qlist(self.room:getAlivePlayers()) do
            if not table.contains(kingdoms, p:getKingdom()) then
                table.insert(kingdoms, p:getKingdom())
            end
        end
        local n = #kingdoms 
        return n
    end
end

--英谋

sgs.ai_skill_invoke.nyarz_yingmou_mou = true

sgs.ai_skill_choice["nyarz_yingmou_mou"] = function(self, choices, data)
    local items = choices:split("+")
    for _,item in ipairs(items) do
        if item == "draw" then
            local use = data:toCardUse()
            for _,p in sgs.qlist(use.to) do
                if p:getHandcardNum() > self.player:getHandcardNum() then return item end
            end
            local card = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_SuitToBeDecided, -1)
            card:deleteLater()
            local usec = self:aiUseCard(card, dummy())
            if usec.card then return item end
        end
        if item == "show" then
            local use = data:toCardUse()
            local targets = {}
            for _,p in sgs.qlist(self.room:getAlivePlayers()) do
                if p:isAlive() and (not p:isKongcheng()) and (not use.to:contains(p)) 
                and (self:isEnemy(p) or (self.player:objectName() == p:objectName())) then 
                    table.insert(targets, p)
                end
            end
            self:sort(targets, "handcard", true)
            for _,p in ipairs(targets) do
                if p:objectName() ~= self.player:objectName() then
                    if (self.player:getHandcardNum() < p:getHandcardNum()) or (p:getHandcardNum() > 5) then
                        return item
                    end
                else
                    local n = 0
                    for _,card in sgs.qlist(self.player:getHandcards()) do
                        local use = self:aiUseCard(card, dummy())
                        if card:isDamageCard() and (use.card) then
                            n = n + 1
                        end
                        if n >= 2 then return item end
                    end
                end
            end
        end
        if string.find(item,"discard") then
            local target = data:toPlayer()
            if self:isEnemy(target) and self.player:getHandcardNum() < target:getHandcardNum() then
                local n = 0
                for _,card in sgs.qlist(target:getHandcards()) do
                    local use = self:aiUseCard(card, dummy())
                    if card:isDamageCard() and (use.card) then
                        n = n + 1
                    end
                end
                if n == 0 then return item end
                if (n + n) < (target:getHandcardNum() - self.player:getHandcardNum()) then return item end
            end
        end
        if string.find(item, "use") then
            local target = data:toPlayer()
            for _,card in sgs.qlist(target:getHandcards()) do
                local use = self:aiUseCard(card, dummy())
                if card:isDamageCard() and (use.card) then
                    return item
                end
            end
        end
    end
    return "cancel"
end

sgs.ai_skill_use["@@nyarz_yingmou_mou"] = function(self, prompt)
    if (not self.player:hasFlag("nyarz_yingmou_mou")) then
        local card = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("_nyarz_yingmou_mou")
        card:deleteLater()

        --local use = self:aiUseCard(card)
        local use = {isDummy=true,to=sgs.SPlayerList()}
        self:useCardByClassName(card, use)
        if use.card then
            if use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(use.to) do
                table.insert(tos, to:objectName())
            end
            return card:toString().."->"..table.concat(tos, "+")
            else
                return card:toString()
            end
        end
        return "."
    else
        local card_ids = self.player:getTag("nyarz_yingmou_mou_card_ids"):toIntList()
        if (not card_ids) or (card_ids:isEmpty()) then return "." end

        local cards = {}
        for _,id in sgs.qlist(card_ids) do
            table.insert(cards, sgs.Sanguosha:getCard(id))
        end
        self:sortByUseValue(cards, true)

        for _,card in ipairs(cards) do
            --local use = self:aiUseCard(card)
            local use = {isDummy=true,to=sgs.SPlayerList()}
            self:useCardByClassName(card, use)
            if use.card then
                if (not use.to:isEmpty()) then 
                local tos = {}
                for _,to in sgs.qlist(use.to) do
                    table.insert(tos, to:objectName())
                end
                return string.format("#nyarz_yingmou_mou:%s:->%s",card:getEffectiveId(),table.concat(tos, "+"))
                else
                    return string.format("#nyarz_yingmou_mou:%s:",card:getEffectiveId())
                end
            end
        end
        return "."
    end
end

sgs.ai_skill_playerchosen.nyarz_yingmou_mou = function(self, targets)
    if self.player:hasFlag("nyarz_yingmou_mou_draw") then
        local max = -1
        local target
        for _,p in sgs.qlist(targets) do
            if p:getHandcardNum() > max then
                max = p:getHandcardNum()
                target = p
            end
        end
        return target
    else
        local newtargets = {}
        for _,p in sgs.qlist(targets) do
            if  (self:isEnemy(p) or (self.player:objectName() == p:objectName())) then 
                table.insert(newtargets, p)
            end
        end
        if #newtargets == 0 then return nil end
        self:sort(newtargets, "handcard", true)
        return newtargets[1]
    end
end

--盟谋

sgs.ai_skill_invoke.nyarz_mengmou_mou = true

sgs.ai_skill_choice["nyarz_mengmou_mou"] = function(self, choices, data)
    local target = data:toPlayer()
    if self:isFriend(target) then
        return string.format("recover=%s", target:getGeneralName())
    else
        return string.format("lose=%s", target:getGeneralName())
    end
end

--明势

sgs.ai_skill_invoke.nyarz_mingshi_mou = true

sgs.ai_skill_use["@@nyarz_mingshi_mou!"] = function(self, prompt)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    if #self.friends_noself == 0 then
        self:sortByKeepValue(cards)
        local show = {}
        for i = 1, 3, 1 do
            table.insert(show, cards[i]:getEffectiveId())
        end
        local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
        self:sort(targets, "defense")
        return string.format("#nyarz_mingshi_mou:%s:->%s", table.concat(show, "+"), targets[1]:objectName())
    else
        self:sortByKeepValue(cards, true)
        local show = {}
        for i = 1, 3, 1 do
            table.insert(show, cards[i]:getEffectiveId())
        end
        self:sort(self.friends_noself, "defense")
        return string.format("#nyarz_mingshi_mou:%s:->%s", table.concat(show, "+"), self.friends_noself[1]:objectName())
    end
end

--缓释

sgs.ai_skill_discard.nyarz_huanshi = function(self,max,min)
    local judge = self.room:getTag("nyarz_huanshi"):toJudge()
    if judge:isGood() and self:isFriend(judge.who) then return {} end
    if judge:isBad() and (not self:isFriend(judge.who)) then return {} end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    --self:sortByCardNeed(cards)
    self:sortByKeepValue(cards)
    if self:isFriend(judge.who) then
        local show = {}
        local needmatch 
        if judge.good then needmatch = true
        else needmatch = false end
        local find = false
        for _,card in ipairs(cards) do
            if needmatch and (sgs.Sanguosha:matchExpPattern(judge.pattern, nil, card)) then
                find = true
                table.insert(show, card:getEffectiveId())
                break
            elseif (not needmatch) and (not sgs.Sanguosha:matchExpPattern(judge.pattern, nil, card)) then
                find = true
                table.insert(show, card:getEffectiveId())
                break
            end
        end
        if not find then return {} end
        local other = 2
        if self:isWeak() then other = 1 end
        for _,card in ipairs(cards) do
            if not table.contains(show, card:getEffectiveId()) then
                table.insert(show, card:getEffectiveId())
                other = other - 1
            end
            if other <= 0 then break end
        end
        if #show >= 2 then return show end
    elseif self:isEnemy(judge.who) then
        local show = {}
        local needmatch 
        if judge.good then needmatch = false
        else needmatch = true end
        local find = 2
        for _,card in ipairs(cards) do
            if needmatch and (sgs.Sanguosha:matchExpPattern(judge.pattern, nil, card)) then
                find = find - 1
                table.insert(show, card:getEffectiveId())
            elseif (not needmatch) and (not sgs.Sanguosha:matchExpPattern(judge.pattern, nil, card)) then
                find = find - 1
                table.insert(show, card:getEffectiveId())
            end
            if find <= 0 then break end
        end
        if #show >= 2 then return show end
    end
    return {}
end

sgs.ai_skill_askforag["nyarz_huanshi"] = function(self, card_ids)
    local judge = self.room:getTag("nyarz_huanshi"):toJudge()
    local needmatch 
    if judge.good then needmatch = true
    else needmatch = false end
    for _,id in ipairs(card_ids) do
        local card = sgs.Sanguosha:getCard(id)
        if needmatch and (sgs.Sanguosha:matchExpPattern(judge.pattern, nil, card)) then
            return id
        elseif (not needmatch) and (not sgs.Sanguosha:matchExpPattern(judge.pattern, nil, card)) then
            return id
        end
    end
    return card_ids[math.random(1,#card_ids)]
end
sgs.wizard_skill = sgs.wizard_skill .. "|nyarz_huanshi"

--弘援

sgs.ai_skill_invoke.nyarz_hongyuan = function(self, data)
    return #self.friends_noself > 0
end

sgs.ai_skill_use["@@nyarz_hongyuan"] = function(self, prompt)
    if #self.friends_noself <= 0 then return "." end
    if self.player:isNude() then return "." end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    --self:sortByCardNeed(cards, true)
    self:sortByKeepValue(cards, true)
    local target
    self:sort(self.friends_noself, "defense")
    for _,friend in ipairs(self.friends_noself) do
        if friend:getMark("&nyarz_hongyuan_chosen+#"..self.player:objectName()) == 0 then
            target = friend
            break
        end
    end
    if not target then return "." end
    return string.format("#nyarz_hongyuan:%s:->%s", cards[1]:getEffectiveId(), target:objectName())
end

--化身

sgs.ai_skill_invoke.nyarz_huashen = true

sgs.ai_skill_choice["nyarz_huashen"] = function(self, choices, data)
    local items = choices:split("+")
    if table.contains(items, "giveup") then
        table.removeOne(items, "giveup")
    end
    return items[math.random(1, #items)]
end

--新生

local nyarz_xinsheng_skill = {}
nyarz_xinsheng_skill.name = "nyarz_xinsheng"
table.insert(sgs.ai_skills, nyarz_xinsheng_skill)
nyarz_xinsheng_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#nyarz_xinsheng") then return end
    if self.player:getMark("&nyarz_souls") <= 0 then return end

    return sgs.Card_Parse("#nyarz_xinsheng:.:")
end

sgs.ai_skill_use_func["#nyarz_xinsheng"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_priority.nyarz_xinsheng = 5

sgs.ai_skill_playerchosen.nyarz_xinsheng = function(self, targets)
    local friends = {}
    for _,target in sgs.qlist(targets) do
        if self:isFriend(target) then
            table.insert(friends, target)
        end
    end
    if #friends <= 0 then return nil end
    self:sort(friends, "defense")
    return friends[1]
end

--遗计

sgs.ai_skill_playerchosen.nyarz_yiji = function(self, targets)
    local friends = {}
    for _,target in sgs.qlist(targets) do
        if self:isFriend(target) then
            table.insert(friends, target)
        end
    end
    if #friends <= 0 then return nil end
    self:sort(friends, "defense")
    return friends[1]
end

sgs.ai_skill_invoke.nyarz_yiji = true

sgs.ai_skill_use["@@nyarz_yiji"] = function(self,prompt)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    --self:sortByCardNeed(cards)
    self:sortByUseValue(cards)
    local max = self.player:getMark("nyarz_yiji_max")
    max = math.max(2, max)
    if self.player:getMark("nyarz_yiji_give") >= max then return "." end
    for _,card in ipairs(cards) do
        local card_ids = {}
        table.insert(card_ids, card:getEffectiveId())
        local target, id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids)
        if target  and (id > 0) then
            return string.format("#nyarz_yiji:%s:->%s", id, target:objectName())
        end
    end
    return "."
end

sgs.ai_need_damaged.nyarz_yiji = function (self,attacker,player)
    if not self.player:hasSkill("nyarz_yiji") then return end
    
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

sgs.double_slash_skill = sgs.double_slash_skill .. "|nyarz_funing"

sgs.ai_card_priority.nyarz_funing = function(self,card,v)
	if card:isKindOf("Slash") and self.player:getMark("&nyarz_funing-Clear") == 0 then
        local mark = nil
        local suit = card:getSuitString()
        for _,p in ipairs(self.player:getMarkNames()) do
            if (string.find(p,"&nyarz_funing_suit")) and (self.player:getMark(p) > 0) then
                mark = p
                break
            end
        end
        if mark and self.player:getMark(mark) > 0 then 
            if not string.find(mark,suit.."_char") then
                for _,c in sgs.qlist(self.player:getHandcards()) do
                    if c:getSuit() == card:getSuit() and c:getEffectiveId() ~= card:getEffectiveId() then
                        return 10 
                    end
                end
            end
        else
            for _,c in sgs.qlist(self.player:getHandcards()) do
                if c:getSuit() == card:getSuit() and c:getEffectiveId() ~= card:getEffectiveId() then
                    return 10 
                end
            end
        end
    end
end

sgs.ai_cardneed.nyarz_funing = sgs.ai_cardneed.slash

sgs.ai_hasTuntianEffect_skill.nyarz_bingji = function(to, need_zaoxian)
	return true
end

--鸾凤

sgs.ai_skill_invoke.nyarz_luanfeng = function(self, data)
    local target = data:toPlayer()
    return target and self:isFriend(target)
end

local nyarz_luanfeng_skill = {}
nyarz_luanfeng_skill.name = "nyarz_luanfeng"
table.insert(sgs.ai_skills, nyarz_luanfeng_skill)
nyarz_luanfeng_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("nyarz_luanfeng_used_lun") > 0 then return end

    return sgs.Card_Parse("#nyarz_luanfeng:.:")
end

sgs.ai_skill_use_func["#nyarz_luanfeng"] = function(card, use, self)
    local maxvalue = 0
    local target
    self:sort(self.friends, "defense")
    local hp = 3
    if self.player:getMark("&nyarz_luanfeng") > 0 then hp = 1 end
    local hand = 6
    if self.player:getMark("&nyarz_luanfeng") > 0 then hand = 3 end
    for _,friend in ipairs(self.friends) do
        local value = 0
        if friend:isWounded() and friend:getHp() < hp then
            value = value + 2*(hp - friend:getHp())
        end
        if friend:getHandcardNum() < hand then
            value = value + hand - friend:getHandcardNum()
        end
        for i = 0, 4, 1 do
            if not friend:hasEquipArea(i) then
                value = value + 1
            end
        end
        if value > maxvalue then 
            target = friend
            maxvalue = value
        end
    end
    if target and maxvalue >= 5 then
        use.card = card
        if use.to then use.to:append(target) end
    end
end

--游龙

sgs.ai_guhuo_card.nyarz_youlong = function(self,toname,class_name)
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return end
    if not self.player:hasEquipArea() then return end
    if self.player:getChangeSkillState("nyarz_youlong") <= 1 then
	    local c = sgs.Sanguosha:cloneCard(toname)
        local mark = string.format("nyarz_youlong_%s_lun", toname)
	    if c then c:deleteLater() end
	    if c and c:isKindOf("BasicCard")
	    and self:getCardsNum(class_name) < 1
        and self.player:getMark(mark) <= 0
	    then
            return "#nyarz_youlong:.:"..toname
	    end
    else
        local c = sgs.Sanguosha:cloneCard(toname)
        local mark = string.format("nyarz_youlong_%s_lun", toname)
	    if c then c:deleteLater() end
	    if c and c:isNDTrick()
	    and self:getCardsNum(class_name) < 1
        and self.player:getMark(mark) <= 0
	    then
            return "#nyarz_youlong:.:"..toname
	    end
    end
end

local nyarz_youlong_skill={}
nyarz_youlong_skill.name="nyarz_youlong"
table.insert(sgs.ai_skills,nyarz_youlong_skill)
nyarz_youlong_skill.getTurnUseCard=function(self,inclusive)
    if not self.player:hasEquipArea() then return end
	for _,name in sgs.list(patterns())do
        local c = sgs.Sanguosha:cloneCard(name)
        local mark = string.format("nyarz_youlong_%s_lun", name)
		if c and c:isAvailable(self.player)
		and self:getCardsNum(c:getClassName())<1
		and ((c:isNDTrick() and self.player:getChangeSkillState("nyarz_youlong") == 2)
            or (c:isKindOf("BasicCard") and self.player:getChangeSkillState("nyarz_youlong") <= 1))
        and self.player:getMark(mark) == 0
		then
         	local dummy = self:aiUseCard(c, dummy())
            -- local dummy = {isDummy=true,to=sgs.SPlayerList()}
            -- self:useCardByClassName(c, dummy)
    		if dummy.card
	    	and dummy.to
	     	then
	           	if c:canRecast()
				and dummy.to:length()<1
				then continue end
				self.nyarz_youlong_to = dummy.to
				sgs.ai_use_priority["#nyarz_youlong"] = sgs.ai_use_priority[c:getClassName()]
                return sgs.Card_Parse("#nyarz_youlong:.:"..name)
			end
		end
		if c then c:deleteLater() end
	end
end

sgs.ai_skill_use_func["#nyarz_youlong"] = function(card, use, self)
	use.card = card
	if use.to then use.to = self.nyarz_youlong_to end
end

sgs.ai_use_priority.nyarz_youlong = 6

--神愤

local nyarz_shenfen_god_skill={}
nyarz_shenfen_god_skill.name="nyarz_shenfen_god"
table.insert(sgs.ai_skills,nyarz_shenfen_god_skill)
nyarz_shenfen_god_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getMark("&nyarz_baonu_god") < 6 then return end
    if self.player:hasUsed("#nyarz_shenfen_god") then return end
    if (self.role=="loyalist" or self.role=="renegade") and self.room:getLord() and self:isWeak(self.room:getLord()) and not self.player:isLord() then return end
    local value = 0
    for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if self:isFriend(p) then
            value = value - 2
            if p:getHp() == 1 and self:getCardsNum("Peach") <= 0 then
                value = value - 4
            end
            value = value - p:getEquips():length()*1.2
            value = value - math.min(4, p:getHandcardNum())
        else
            value = value + 2
            if p:getHp() == 1  then
                value = value + 3
            end
            value = value + p:getEquips():length()*1.2
            value = value + math.min(4, p:getHandcardNum())
        end
    end
    if value < 0 then return end

    return sgs.Card_Parse("#nyarz_shenfen_god:.:")
end

sgs.ai_skill_use_func["#nyarz_shenfen_god"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_use["@@nyarz_shenfen_god"] = function(self, prompt)
    return "#nyarz_shenfen_god:.:"
end

sgs.ai_use_value.nyarz_shenfen_god = 8
sgs.ai_use_priority.nyarz_shenfen_god = 5.3

--无前

local nyarz_wuqian_god_skill={}
nyarz_wuqian_god_skill.name="nyarz_wuqian_god"
table.insert(sgs.ai_skills,nyarz_wuqian_god_skill)
nyarz_wuqian_god_skill.getTurnUseCard=function(self,inclusive)
    if self:isWeak() or self.player:getHp() <= 2 then return end
    local patterns = {"fire_slash", "thunder_slash", "duel", "slash"}
	for _,name in sgs.list(patterns)do
        local c = sgs.Sanguosha:cloneCard(name)
		if c and c:isAvailable(self.player)
		then
         	local dummy = self:aiUseCard(c)
            -- local dummy = {isDummy=true,to=sgs.SPlayerList()}
            -- self:useCardByClassName(c, dummy)
    		if dummy.card
	    	and dummy.to
	     	then
				self.nyarz_wuqian_god_to = dummy.to
				sgs.ai_use_priority["#nyarz_wuqian_god"] = sgs.ai_use_priority[c:getClassName()]
                return sgs.Card_Parse("#nyarz_wuqian_god:.:"..name)
			end
		end
		if c then c:deleteLater() end
	end
end

sgs.ai_skill_use_func["#nyarz_wuqian_god"] = function(card, use, self)
	use.card = card
	if use.to then use.to = self.nyarz_wuqian_god_to end
end

sgs.ai_use_priority.nyarz_wuqian_god = sgs.ai_use_priority.Slash + 0.1

--无谋

sgs.ai_skill_choice["nyarz_wumou_god"] = function(self, choices, data)
    if self.player:getMark("&nyarz_baonu_god") > 9 then return "dismark" end
    if self.player:getMark("&nyarz_baonu_god") <= 0 then return "damaged" end
    local use = data:toCardUse()
    local value = 0
    for _,p in sgs.qlist(use.to) do
        if self:isFriend(p) then value = value - 1
        else value = value + 1 end
    end
    if value < 0 then return "dismark" end
    if self.player:getHp()+self:getCardsNum("Peach")>3 then return "damaged" end
    return "dismark"
end


--无双

sgs.ai_skill_choice["nyarz_wushuang_god"] = function(self, choices, data)
    local use = data:toCardUse()
    local items = choices:split("+")
    if use.from:objectName() == self.player:objectName() then
        for _,item in ipairs(items) do
            if string.find(item, "no") then
                return item
            end
        end
    end
    if use.card:isKindOf("Slash") then
        if self:getCardsNum("Jink") > 0 then
            for _,item in ipairs(items) do
                if string.find(item, "up") then
                    return item
                end
            end
        else
            for _,item in ipairs(items) do
                if string.find(item, "no") then
                    return item
                end
            end
        end
    end
    for _,item in ipairs(items) do
        if string.find(item, "no") then
            return item
        end
    end
end

--力激

sgs.ai_skill_use["@@nyarz_liji"] = function(self, prompt)
    if #self.enemies <= 0 then return "." end
    local num = self.player:getMark("nyarz_liji")
    if num > 3 then return "." end
    if self:isWeak() then
        if num >= 3 then return "." end
        if num == 2 then
            self:sort(self.enemies, "hp")
            if self.enemies[1]:getHp() == 1 and self:damageIsEffective(self.enemies[1], sgs.DamageStruct_Normal) and not self:cantbeHurt(self.enemies[1]) and self:canDamage(self.enemies[1],self.player,nil) then
                local cards = sgs.QList2Table(self.player:getCards("he"))
                local need = {}
                self:sortByKeepValue(cards)
                for _,card in ipairs(cards) do
                    table.insert(need, card:getEffectiveId())
                    num = num - 1
                    if num <= 0 then break end
                end
                if num <= 0 then
                    local card_str = string.format("#nyarz_liji:%s:->%s",table.concat(need, "+"), self.enemies[1]:objectName())
                    return card_str
                end
            end
            return "."
        end
        self:sort(self.enemies, "defense")
        for _, enemy in ipairs(self.enemies) do
            if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and self:canDamage(enemy,self.player,nil) then
                local cards = sgs.QList2Table(self.player:getCards("he"))
                local need = {}
                self:sortByKeepValue(cards)
                for _,card in ipairs(cards) do
                    table.insert(need, card:getEffectiveId())
                    num = num - 1
                    if num <= 0 then break end
                end
                if num <= 0 then
                    local card_str = string.format("#nyarz_liji:%s:->%s",table.concat(need, "+"), enemy:objectName())
                    return card_str
                end
            end
        end
        return "."
    else
        if num == 3 then
            self:sort(self.enemies, "defense")
            if self.enemies[1]:getHp() == 1 and self:damageIsEffective(self.enemies[1], sgs.DamageStruct_Normal) and not self:cantbeHurt(self.enemies[1]) and self:canDamage(self.enemies[1],self.player,nil) then
                local cards = sgs.QList2Table(self.player:getCards("he"))
                local need = {}
                self:sortByKeepValue(cards)
                for _,card in ipairs(cards) do
                    table.insert(need, card:getEffectiveId())
                    num = num - 1
                    if num <= 0 then break end
                end
                if num <= 0 then
                    local card_str = string.format("#nyarz_liji:%s:->%s",table.concat(need, "+"), self.enemies[1]:objectName())
                    return card_str
                end
            end
            return "."
        end
        self:sort(self.enemies, "defense")
        for _, enemy in ipairs(self.enemies) do
            if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and self:canDamage(enemy,self.player,nil) then
                local cards = sgs.QList2Table(self.player:getCards("he"))
                local need = {}
                self:sortByKeepValue(cards)
                for _,card in ipairs(cards) do
                    table.insert(need, card:getEffectiveId())
                    num = num - 1
                    if num <= 0 then break end
                end
                if num <= 0 then
                    local card_str = string.format("#nyarz_liji:%s:->%s",table.concat(need, "+"), enemy:objectName())
                    return card_str
                end
            end
        end
        return "."
    end
    return "."
end

--剑合

sgs.ai_skill_discard.nyarz_jianhe = function(self,max,min)
    local ctype = "BasicCard"
    if self.player:getMark("nyarz_jianhe_type") == 2 then
        ctype = "TrickCard"
    elseif self.player:getMark("nyarz_jianhe_type") == 3 then
        ctype = "EquipCard"
    end
    local need = self.player:getMark("nyarz_jianhe")
    local cards = sgs.QList2Table(self.player:getCards("he"))
    if self.player:getPhase() == sgs.Player_Play then
        self:sortByUseValue(cards)
    else
        self:sortByKeepValue(cards)
    end
    local dis = {}
    for _,card in ipairs(cards) do
        if card:isKindOf(ctype) then
            table.insert(dis, card:getEffectiveId())
            need = need - 1
        end
        if need <= 0 then break end
    end
    if need <= 0 then return dis end
    return {}
end

local nyarz_jianhe_skill={}
nyarz_jianhe_skill.name="nyarz_jianhe"
table.insert(sgs.ai_skills,nyarz_jianhe_skill)
nyarz_jianhe_skill.getTurnUseCard=function(self,inclusive)
    return sgs.Card_Parse("#nyarz_jianhe:.:")
end

sgs.ai_skill_use_func["#nyarz_jianhe"] = function(card, use, self)
    local recast = {}
    local need = 2
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards)
    for _,card in ipairs(cards) do
        if need >= 2 then
            table.insert(recast, card:getEffectiveId())
            need = need - 1
        else
            if card:getTypeId() == cards[1]:getTypeId() then
                table.insert(recast, card:getEffectiveId())
                need = need - 1
                if self:isWeak() then break end
                if #recast >= math.random(3,5) then break end
            end
        end
    end
    if need > 0 then return end
    local target 

    if #self.enemies > 0 then
        self:sort(self.enemies, "defense")
        for _,enemy in ipairs(self.enemies) do
            local mark = string.format("&nyarz_jianhe_%s+#%s-PlayClear", "skill", self.player:objectName())
            if enemy:getMark(mark) == 0 then 
                target = enemy
                break
            end
        end
    end

    if (not self:isWeak()) and self.player:getHp() > 1 and (not target)
    and self.player:getMark("&nyarz_jianhe_skill+#"..self.player:objectName().."-PlayClear") == 0 
    and ((self.player:getHandcardNum() > 6) or self.player:hasSkill("nyarz_bihun")) then
        target = self.player
    end

    if (not target) then return end

    local card_str = string.format("#nyarz_jianhe:%s:->%s", table.concat(recast, "+"), target:objectName())

	use.card = sgs.Card_Parse(card_str)
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority.nyarz_jianhe = 7

sgs.ai_skill_choice["nyarz_jianhe"] = function(self, choices, data)
    local items = choices:split("+")
    if #items == 1 then return items[1] end
    local target = data:toPlayer()
    if (not target) then
        return items[math.random(1,#items)]
    end
    
    if self:isEnemy(target) and ((not self.player:inMyAttackRange(target)) or (self:getCardsNum("Slash") <= 0)) then
        return "card"
    end

    return "skill"
end

--弼昏

sgs.ai_skill_playerchosen.nyarz_bihun = function(self, targets)
    local players = sgs.QList2Table(targets)
    self:sort(players, "defense")
    for _,player in ipairs(players) do
        if self:isFriend(player) then return player end
    end
    for _,player in ipairs(players) do
        if not self:isEnemy(player) then return player end
    end
    return players[1]
end

--穿屋

sgs.ai_skill_choice["nyarz_chuanwu"] = function(self, choices, data)
    if self.player:getPhase() == sgs.Player_NotActive then
        if string.find(choices, "nyarz_bihun") then return "nyarz_bihun" end
        if string.find(choices, "nyarz_jianhe") then return "nyarz_jianhe" end
        if string.find(choices, "nyarz_chuanwu") then return "nyarz_chuanwu" end
    else
        if string.find(choices, "nyarz_bihun") then return "nyarz_bihun" end
        if string.find(choices, "nyarz_chuanwu") then return "nyarz_chuanwu" end
    end
    local items = choices:split("+")
    return items[math.random(1,#items)]
end

local nyarz_longhun_god_skill = {}
nyarz_longhun_god_skill.name = "nyarz_longhun_god"
table.insert(sgs.ai_skills, nyarz_longhun_god_skill)
nyarz_longhun_god_skill.getTurnUseCard = function(self, inclusive)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    cards = self:sortByUseValue(cards, true)
    local heart, diamond = {}, {}
    for _,card in ipairs(cards) do
        if card:getSuit() == sgs.Card_Heart then
            table.insert(heart, card)
        end
        if card:getSuit() == sgs.Card_Diamond then
            table.insert(diamond, card)
        end
    end
    if #heart >= self.player:getMark("&nyarz_longhun_god-Clear") + 1 then
        local usecard = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, -1)
        usecard:setSkillName("nyarz_longhun_god")
        for _,c in ipairs(heart) do
            usecard:addSubcard(c)
            if usecard:subcardsLength() >= self.player:getMark("&nyarz_longhun_god-Clear") + 2 then
                break
            end
        end
        if usecard:subcardsLength() < self.player:getMark("&nyarz_longhun_god-Clear") + 1 then
            return
        end
        usecard:deleteLater()

        -- local usec = {isDummy=true,to=sgs.SPlayerList()}
        -- self:useCardByClassName(usecard, usec)
        local usec = self:aiUseCard(usecard, dummy())
        if usec.card and self.player:isWounded() then
            self.nyarz_longhun_god_to = usec.to
            local card_str = string.format("#nyarz_longhun_god:%s:%s",card:getEffectiveId(), "peach")
            local acard = sgs.Card_Parse(card_str)
            return acard
        end
    end
    if #diamond >= self.player:getMark("&nyarz_longhun_god-Clear") + 1 then
        local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
        slash:setSkillName("nyarz_longhun_god")
        for _,c in ipairs(diamond) do
            slash:addSubcard(c)
            if slash:subcardsLength() >= self.player:getMark("&nyarz_longhun_god-Clear") + 2 then
                break
            end
        end
        if slash:subcardsLength() < self.player:getMark("&nyarz_longhun_god-Clear") + 1 then
            return
        end
        slash:deleteLater()
        local usec = self:aiUseCard(slash, dummy())
        if usec.card and slash:isAvailable(self.player) then
            self.nyarz_longhun_god_to = usec.to
            local card_str = string.format("#nyarz_longhun_god:%s:%s",card:getEffectiveId(), "fire_slash")
            local acard = sgs.Card_Parse(card_str)
            return acard
        end
    end
end

sgs.ai_skill_use_func["#nyarz_longhun_god"] = function(card, use, self)
    use.card = card
    if use.to then use.to = self.nyarz_longhun_god_to end
end

sgs.ai_use_priority.nyarz_longhun_god = sgs.ai_use_priority.Slash

--连营
sgs.need_kongcheng = sgs.need_kongcheng .. "|nyarz_lianying"
sgs.ai_skill_invoke.nyarz_lianying = true

sgs.ai_getLeastHandcardNum_skill.nyarz_lianying = function(self, player, least)
	if least < player:getMaxCards() + 1 then
		return player:getMaxCards() + 1
	end
end

--度势

sgs.ai_skill_use["@@nyarz_duoshi"] = function(self, prompt)
    if self.player:isNude() then return "." end
    if self:isWeak() and (not self.player:hasSkill("nyarz_lianying")) then return "." end
    --local use = room:getTag("nyarz_duoshi"):toCardUse()
    local cards = sgs.QList2Table(self.player:getHandcards())
    if self.player:getPhase() == sgs.Player_NotActive then
        self:sortByKeepValue(cards)
    else
        self:sortByKeepValue(cards, true)
    end
    local n = 2
    local give = {}
    for _,card in ipairs(cards) do
        table.insert(give, card:getEffectiveId())
        n = n - 1
        if n <= 0 then break end
    end
    if #self.friends_noself == 0 then
        return string.format("#nyarz_duoshi:%s:", table.concat(give, "+"))
    else
        self:sort(self.friends_noself, "defense")
        for _,card in ipairs(give) do
            local cc = sgs.Sanguosha:getCard(card)
            if cc:isKindOf("Jink") or cc:isKindOf("Nullification")
            or (cc:isKindOf("Peach") and not self.player:isWounded())
            or (cc:isKindOf("Analeptic") and self:getCardsNum("Slash") == 0)
            then
                return string.format("#nyarz_duoshi:%s:->%s", table.concat(give, "+"), self.friends_noself[1]:objectName())
            end
        end
        return string.format("#nyarz_duoshi:%s:", table.concat(give, "+"))
    end
    return "."
end

sgs.ai_skill_use["@@nyarz_duoshi_use"] = function(self, prompt)
    local cards = {}
    for _,id in sgs.qlist(self.player:getPile("nyarz_duoshi")) do
        local card = sgs.Sanguosha:getCard(id)
        table.insert(cards, card)
    end
    self:sortByUseValue(cards)
    for _,card in ipairs(cards) do
        if card:isAvailable(self.player) then
            if card:isKindOf("EquipCard") then
                return card:toString()
            end
            
            -- local usec = {isDummy=true,to=sgs.SPlayerList()}
            -- self:useCardByClassName(card, usec)
            local usec = self:aiUseCard(card, dummy())
            if usec.card then
                if usec.to and usec.to:length() > 0 then
                    local tos = {}
                    for _,p in sgs.qlist(usec.to) do
                        table.insert(tos, p:objectName())
                    end
                    return card:toString().."->"..table.concat(tos, "+")
                else
                    return card:toString()
                end
            end
        end
    end
    return "."
end
sgs.ai_use_revises.nyarz_duoshi = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5 and self:hasSkills(sgs.need_kongcheng, self.player)
	then use.card = card return true end
end

--节应

sgs.ai_skill_invoke.nyarz_jieying = function(self, data)
    local target = self.room:getCurrent()
    if target and self:isEnemy(target) then return true end
end

--危迫

sgs.ai_skill_invoke.nyarz_weipo = true

sgs.ai_skill_discard.nyarz_weipo = function(self, max, min)
    local discards = {}
    if self.player:getHandcardNum() < self.player:getMaxHp() then
        local n = self.player:getMaxHp() - self.player:getHandcardNum()
        local cards
        if self:isWeak() then
            cards = sgs.QList2Table(self.player:getCards("he"))
            self:sortByKeepValue(cards)
            for _,card in ipairs(cards) do
                if card:isKindOf("Peach") or card:isKindOf("Analeptic")
                or card:isKindOf("Jink") or card:isKindOf("Nullification")
                or (((card:isKindOf("Armor")) or (card:isKindOf("DefensiveHorse"))) 
                and self.room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceEquip) then
                    table.insert(discards, card:getEffectiveId())
                end
            end
            if #discards <= n then return {} end
            if #discards > n*1.5 or (self.player:getHp() == 1 and #discards > n) then 
                return discards
            else
                return {}
            end
        else
            cards = sgs.QList2Table(self.player:getHandcards())
            self:sortByUseValue(cards, true)
            local need = {["jink"] = 0, ["nullification"] = 0, ["peach"] = 0}
            for _,card in ipairs(cards) do
                if need[card:objectName()] and need[card:objectName()] == 0 then
                    if card:isKindOf("Peach") and (not self.player:isWounded()) then
                        table.insert(discards, card:getEffectiveId())
                    else
                        need[card:objectName()] = 1
                    end
                else
                    if card:isAvailable(self.player) then
                        local usec = self:aiUseCard(card, dummy())
                        -- local usec = {isDummy=true,to=sgs.SPlayerList()}
                        -- self:useCardByClassName(card, usec)
                        if (not usec.card) then table.insert(discards, card:getEffectiveId()) end
                        if (not slash) and card:isKindOf("Slash") then table.insert(discards, card:getEffectiveId()) end
                        if card:isKindOf("Slash") then slash = true end
                    else
                        table.insert(discards, card:getEffectiveId())
                    end
                end
            end
            if #discards <= n then return {} end
            if #discards > n*1.5 then 
                return discards
            end
            return {}
        end
    end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards, true)
    local need = {["jink"] = 0, ["nullification"] = 0, ["peach"] = 0}
    local slash = false
    for _,card in ipairs(cards) do
        if need[card:objectName()] and need[card:objectName()] == 0 then
            if card:isKindOf("Peach") and (not self.player:isWounded()) then
                table.insert(discards, card:getEffectiveId())
            else
                need[card:objectName()] = 1
            end
        else
            if card:isAvailable(self.player) then
                -- local usec = {isDummy=true,to=sgs.SPlayerList()}
                -- self:useCardByClassName(card, usec)
                local usec = self:aiUseCard(card, dummy())
                if (not usec.card) then table.insert(discards, card:getEffectiveId()) end
                if (not slash) and card:isKindOf("Slash") 
                and (not table.contains(discards, card:getEffectiveId())) then 
                    table.insert(discards, card:getEffectiveId()) 
                end
                if card:isKindOf("Slash") then slash = true end
            else
                table.insert(discards, card:getEffectiveId())
            end
        end
    end
    return discards
end

--洗墨

local nyarz_ximo_skill={}
nyarz_ximo_skill.name="nyarz_ximo"
table.insert(sgs.ai_skills,nyarz_ximo_skill)
nyarz_ximo_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getMark("nyarz_ximo-PlayClear") > 0 then return end
    if #self.enemies == 0 then return end
    for _,enemy in ipairs(self.enemies) do
        if not enemy:getEquips():isEmpty() then
            return sgs.Card_Parse("#nyarz_ximo:.:")
        end
    end
    for _,enemy in ipairs(self.enemies) do
        if not enemy:isNude() then
            return sgs.Card_Parse("#nyarz_ximo:.:")
        end
    end
    if (not self:isWeak()) and (not self.player:isKongcheng()) then return sgs.Card_Parse("#nyarz_ximo:.:") end
end

sgs.ai_skill_use_func["#nyarz_ximo"] = function(card, use, self)
    self:sort(self.enemies, "defense")
    for _,enemy in ipairs(self.enemies) do
        if not enemy:getEquips():isEmpty() then
            use.card = card
            if use.to then use.to:append(enemy) end
            return 
        end
    end
    for _,enemy in ipairs(self.enemies) do
        if not enemy:isNude() then
            use.card = card
            if use.to then use.to:append(enemy) end
            return 
        end
    end
    if (not self:isWeak()) and self.player:isKongcheng() then
        use.card = card
        if use.to then use.to:append(self.player) end
    end

end

sgs.ai_use_priority.nyarz_ximo = 5
sgs.ai_card_intention.nyarz_ximo = 20

sgs.ai_skill_playerchosen.nyarz_ximo = function(self, targets)
    self:sort(self.friends, "defense")
    return self.friends[1]
end

sgs.ai_playerchosen_intention.nyarz_ximo = -40

--笔心

sgs.ai_cardsview_valuable.nyarz_bixin = function(self, class_name, player)
	if self.player:isKongcheng() then return end
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
	if not name then return end
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf(class_name) and (self.player:getHandcardNum() > 1) then return end
    end
	return string.format("#nyarz_bixin:.:%s", name)
end

local nyarz_bixin_skill={}
nyarz_bixin_skill.name="nyarz_bixin"
table.insert(sgs.ai_skills,nyarz_bixin_skill)
nyarz_bixin_skill.getTurnUseCard=function(self,inclusive)
    if self.player:isKongcheng() then return end
    local canuse = {"peach", "analeptic", "fire_slash", "thunder_slash", "slash"}
    for _,pattern in ipairs(canuse) do
        local n = 0
        if self.player:getHandcardNum() > 1 then
            for _,card in sgs.qlist(self.player:getHandcards()) do
                if card:objectName() == pattern then
                    n = 1
                    break
                end
            end
            if n > 0 then continue end
        end

        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:deleteLater()
        sgs.ai_use_priority.nyarz_bixin = sgs.ai_use_priority[card:getClassName()]
        if (not card:isAvailable(self.player)) then continue end

        local use = {isDummy=true,to=sgs.SPlayerList()}
        --self:useCardByClassName(card, use)
        self["useBasicCard"](self,card,use)
        if use.card then
            self.nyarz_bixin_to = use.to
            return sgs.Card_Parse("#nyarz_bixin:.:"..pattern)
        end
    end
end

sgs.ai_skill_use_func["#nyarz_bixin"] = function(card, use, self)
    use.card = card
    if use.to then use.to = self.nyarz_bixin_to end
end

sgs.ai_use_priority.nyarz_bixin = 8

sgs.ai_skill_choice.nyarz_bixin = function(self, choices)
    local items = choices:split("+")
    if #items == 1 then return items[1] end
    local num = {}
    for _,item in ipairs(items) do
        num[item] = 0
    end

    for _,card in sgs.qlist(self.player:getHandcards()) do
        for _,item in ipairs(items) do
            if card:isKindOf(item) then
                num[item] = num[item] + 1
            end
        end
    end

    local types = {"BasicCard","TrickCard","EquipCard"}
    local n = 0
    for _,ctype in ipairs(types) do
        if self.player:getMark("nyarz_bixin_"..ctype.."_lun") == 0 then n = n + 1 end
    end

    if n > 0 then
        for _,id in sgs.qlist(self.room:getDrawPile()) do
            local card = sgs.Sanguosha:getCard(id)
            for _,item in ipairs(items) do
                if card:isKindOf(item) then
                    num[item] = num[item] + 1
                end
            end
        end
    end
    local min = 99999
    for _,n in ipairs(num) do
        if n < min then min = n end
    end
    local maxnum = 0
    local result
    for _,item in ipairs(items) do
        if num[item] == min then
            result = item
            maxnum = maxnum + 1
        end
    end
    if maxnum == 1 then return result end
    for _,item in ipairs(items) do
        if num[item] == min and self.player:getMark("nyarz_bixin_"..item.."_lun") > 0 then
            return item
        end
    end
    for _,item in ipairs(items) do
        if num[item] == min then
            return item
        end
    end
    return items[math.random(1,#items)]
end
sgs.ai_ajustdamage_from["nyarz_feibai"]   = function(self, from, to, card, nature)
	if card and not card:isKindOf("SkillCard") and not card:isRed() and not card:isBlack() then
		return 1
	end
end


--义绝

sgs.ai_skill_invoke.nyarz_yijve = function(self, data)
    local dying = self.room:getTag("nyarz_yijve"):toDying()
    local target = dying.who
    if self:isFriend(target) and target:getMark("&nyarz_yijve+#"..self.player:objectName()) == 0 then return true end
    if self:isEnemy(target) and target:getMark("&nyarz_yijve+#"..self.player:objectName()) > 0 then return true end
    if self:isEnemy(target) and target:getMark("&nyarz_yijve+#"..self.player:objectName()) == 0 then
        for _,card in sgs.qlist(target:getHandcards()) do
            if card:isKindOf("Peach") or card:isKindOf("Analeptic") then return true end
        end
        return false
    end
    return false
end

--武圣

sgs.ai_cardsview_valuable.nyarz_wusheng = function(self, class_name, player)
	if self.player:isNude() then return end
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:hasFlag("nyarz_wusheng") then return end
    end
	local classname2objectname = {
		["Slash"] = "slash", ["IceSlash"] = "ice_slash",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
	if not name then return end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    return string.format("#nyarz_wusheng:"..cards[1]:getEffectiveId()..":"..name)
end

local nyarz_wusheng_skill={}
nyarz_wusheng_skill.name="nyarz_wusheng"
table.insert(sgs.ai_skills,nyarz_wusheng_skill)
nyarz_wusheng_skill.getTurnUseCard=function(self,inclusive)
    if self.player:isKongcheng() then return end
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:hasFlag("nyarz_wusheng") then return end
    end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)

    local canuse = {"fire_slash", "thunder_slash", "slash"}
    for _,pattern in ipairs(canuse) do
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:addSubcard(cards[1])
        card:deleteLater()
        sgs.ai_use_priority.nyarz_wusheng = sgs.ai_use_priority[card:getClassName()]
        if (not card:isAvailable(self.player)) then continue end

        local use = {isDummy=true,to=sgs.SPlayerList()}
        --self:useCardByClassName(card, use)
        self["useBasicCard"](self,card,use)
        if use.card then
            self.nyarz_wusheng_to = use.to
            return sgs.Card_Parse("#nyarz_wusheng:"..cards[1]:getEffectiveId()..":"..pattern)
        end
    end
end

sgs.ai_skill_use_func["#nyarz_wusheng"] = function(card, use, self)
    use.card = card
    if use.to then use.to = self.nyarz_wusheng_to end
end

sgs.ai_use_priority.nyarz_wusheng = sgs.ai_use_priority.Slash

sgs.ai_card_priority.nyarz_wusheng = function(self,card)
    if card:hasFlag("nyarz_wusheng")
    then
        if self.useValue
        then return 1 end
        return 0.08
    end
end

--龙胆

sgs.ai_cardsview_valuable.nyarz_longdan = function(self, class_name, player)
    if self.player:getMark("@nyarz_longdan_mark") == 0 then return end
	if self.player:isNude() then return end
	local classname2objectname = {
		["Slash"] = "slash", ["IceSlash"] = "ice_slash",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
        ["Jink"] = "jink"
	}
	local name = classname2objectname[class_name]
	if not name then return end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    --if self:isWeak() or #cards <= 2 then
    if #cards <= 2 then
        return string.format("#nyarz_longdan:"..cards[1]:getEffectiveId()..":"..name)
    else
        if #cards == 1 then
            return string.format("#nyarz_longdan:"..cards[1]:getEffectiveId()..":"..name)
        else
            return string.format("#nyarz_longdan:"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId()..":"..name)
        end
    end
end

local nyarz_longdan_skill={}
nyarz_longdan_skill.name="nyarz_longdan"
table.insert(sgs.ai_skills,nyarz_longdan_skill)
nyarz_longdan_skill.getTurnUseCard=function(self,inclusive)
    if self.player:getMark("@nyarz_longdan_mark") == 0 then return end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards, true)

    local canuse = {"fire_slash", "thunder_slash", "slash"}
    for _,pattern in ipairs(canuse) do
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:addSubcard(cards[1])
        card:deleteLater()
        if (not card:isAvailable(self.player)) then continue end

        local use = {isDummy=true,to=sgs.SPlayerList()}
        --self:useCardByClassName(card, use)
        self["useBasicCard"](self,card,use)
        if use.card then
            self.nyarz_longdan_to = use.to
            if #cards <= 2 then
                return sgs.Card_Parse("#nyarz_longdan:"..cards[1]:getEffectiveId()..":"..pattern)
            else
                local card_str = string.format("#nyarz_longdan:%s+%s:%s",cards[1]:getEffectiveId(), cards[2]:getEffectiveId(), pattern)
                return sgs.Card_Parse(card_str)
            end
        end
    end
end

sgs.ai_skill_use_func["#nyarz_longdan"] = function(card, use, self)
    use.card = card
    if use.to then use.to = self.nyarz_longdan_to end
end

sgs.ai_use_priority.nyarz_longdan = 8

--典财

sgs.ai_skill_invoke.nyarz_diancai = true

sgs.ai_hasTuntianEffect_skill.nyarz_diancai = function(to, need_zaoxian)
	return true
end

--调度
sgs.need_equip_skill = sgs.need_equip_skill .. "|nyarz_diaodu"
sgs.ai_skill_playerchosen.nyarz_diaodu_get = function(self, targets)
    local tos = sgs.QList2Table(targets)
    self:sort(tos, "defense")
    for _,to in ipairs(tos) do
        if self:isFriend(to) and to:getJudgingArea():length() > 0 then return to end
    end
    for _,to in ipairs(tos) do
        if self:isFriend(to) and self:doDisCard(to, "he", true) then return to end
    end
    for _,to in ipairs(tos) do
        if self:isEnemy(to) and self:doDisCard(to, "he", true) then return to end
    end
    return nil
end
sgs.ai_use_revises.nyarz_diaodu = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
	then use.card = card return true end
end


sgs.ai_playerchosen_intention.nyarz_diaodu_get = 80

sgs.ai_skill_playerchosen.nyarz_diaodu_give = function(self, targets)
    local tos = sgs.QList2Table(targets)
    self:sort(tos, "defense")
    for _,to in ipairs(tos) do
        if self:isFriend(to) and self:canDraw(to, self.player)  then return to end
    end
    return tos[math.random(1,#tos)]
end

sgs.ai_playerchosen_intention.nyarz_diaodu_give = -80

sgs.ai_skill_invoke.nyarz_diaodu = function(self, data)
    local target = self.room:getTag("nyarz_diaodu"):toPlayer()
    if target and self:isFriend(target) then return true end
    return false
end

sgs.ai_choicemade_filter.skillInvoke.nyarz_diaodu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:getTag("nyarz_diaodu"):toPlayer()
		if target then sgs.updateIntention(player,target,-50) end
	end
end
--诏讨

sgs.ai_skill_invoke.nyarz_zhaotao = true

sgs.ai_skill_playerchosen.nyarz_zhaotao = function(self, targets)
    local tos = sgs.QList2Table(targets)
    self:sort(tos, "defense")
    for _,to in ipairs(tos) do
        if (self:isEnemy(to)) then return to end
    end
    return nil
end

sgs.ai_playerchosen_intention.nyarz_zhaotao = 80

--三陈
--bug

sgs.ai_skill_invoke.nyarz_sanchen = function(self, data)
    return self.player:getMark("nyarz_sanchen_quip") == 0
end

sgs.ai_skill_playerchosen.nyarz_sanchen = function(self, targets)
    local tos = sgs.QList2Table(targets)
    self:sort(tos, "defense")
    for _,to in ipairs(tos) do
        if self:isFriend(to) then return to end
    end
    return self.player
end

sgs.ai_playerchosen_intention.nyarz_sanchen = -80

--残玺

sgs.ai_cardsview_valuable.nyarz_canxi = function(self, class_name, player)
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:getPhase() ~= sgs.Player_NotActive then
            if self.player:getMark("@nyarz_canxi_"..p:getKingdom()) == 0 then return end
        end
    end
	if class_name ~= "Nullification" then return end
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf(class_name) and (self.player:getHandcardNum() > 1) then return end
    end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    for _,card in ipairs(cards) do
        if (not card:isKindOf("BasicCard")) then
            return string.format("#nyarz_canxi:%s:", card:getEffectiveId())
        end
    end
	return
end

--统围

local nyarz_tongwei_skill = {}
nyarz_tongwei_skill.name = "nyarz_tongwei"
table.insert(sgs.ai_skills,nyarz_tongwei_skill)
nyarz_tongwei_skill.getTurnUseCard = function(self)
    if self.player:hasUsed("#nyarz_tongwei") then return end
	return sgs.Card_Parse("#nyarz_tongwei:.:")
end

--此处引用luas函数内的制衡，不知有无修改，报错直接删除

sgs.ai_skill_use_func["#nyarz_tongwei"] = function(card,use,self)
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
					--local dummy_use = self:aiUseCard(zcard)
                    local dummy_use = {isDummy=true,to=sgs.SPlayerList()}
                    self:useCardByClassName(zcard, dummy_use)

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
                    local dummy_use = {isDummy=true,to=sgs.SPlayerList()}
                    self:useCardByClassName(zcard, dummy_use)

					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId()==sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
                    local dummy_use = {isDummy=true,to=sgs.SPlayerList()}
                    self:useCardByClassName(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
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
                    local dummy_use = {isDummy=true,to=sgs.SPlayerList()}
                    self:useCardByClassName(card, dummy_use)

					if dummy_use.card then
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
                local dummy_use = {isDummy=true,to=sgs.SPlayerList()}
                    self:useCardByClassName(card, dummy_use)
				if not dummy_use.card then table.insert(unpreferedCards,card:getId()) end
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

    local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sort(targets, "defense")
    local target = targets[1]

    if #use_cards>0 then
		local card_str = string.format("#nyarz_tongwei:%s:", table.concat(use_cards,"+"))
		local acard = sgs.Card_Parse(card_str)
        use.card = acard
        if use.to then use.to:append(target) end
	end
end

sgs.ai_use_value.nyarz_tongwei = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority.nyarz_tongwei = sgs.ai_use_priority.ZhihengCard
sgs.dynamic_value.benefit.nyarz_tongwei = sgs.dynamic_value.benefit.ZhihengCard

sgs.ai_skill_choice.nyarz_tongwei = function(self, choices, data)
    local items = choices:split("+")
    if #items == 1 then return items[1] end
    local use = data:toCardUse()
    if use.from then
        if self:isFriend(use.from) then return "Trick" end
        if use.from:hasArmorEffect("eight_diagram") then return "Trick" end
        local Jink = 0
        for _,card in sgs.qlist(use.from:getHandcards()) do
            if card:isKindOf("Jink") then Jink = Jink + 1 end
        end
        if self.player:hasSkill("nyarz_cuguo") then
            if Jink <= 1 - self.player:getMark("nyarz_cuguo-Clear") then return "Slash" end
        else
            if Jink == 0 then return "Slash" end
        end
        return "Trick"
    end
    return items[math.random(1, #items)]
end

sgs.ai_skill_choice.nyarz_tongwei_slash = function(self, choices, data)
    local items = choices:split("+")
    if #items == 1 then return items[1] end
    local use = data:toCardUse()
    if use.from then
        if self:isFriend(use.from) then return "slash" end
        if use.from:hasArmorEffect("vine") 
        and (not (self.player:isChained() and use.from:isChained() and self.player:getHp() <= use.from:getHp())) then
            return "fire_slash"
        end
        if (not (self.player:isChained() and use.from:isChained())) then return "thunder_slash" end
        return "slash"
    end
    return "slash"
end

sgs.ai_skill_choice.nyarz_tongwei_trick = function(self, choices, data)
    local items = choices:split("+")
    if #items == 1 then return items[1] end
    local use = data:toCardUse()
    if use.from then
        if self:isFriend(use.from) then
            if self:isWeak(use.from) and use.from:isWounded()
            and table.contains(items, "god_salvation") then return "god_salvation" end
            if use.from:getJudgingArea():length() > 0 then
                local patterns = {"snatch", "dismantlement"}
                for _,pattern in ipairs(patterns) do
                    if table.contains(items, pattern) then return pattern end
                end
            end
            if table.contains(items, "ex_nihilo") then return "ex_nihilo" end
            if use.from:isChained() and table.contains(items, "iron_chain") then return "iron_chain" end
            if table.contains(items, "amazing_grace") then return "amazing_grace" end
            return items[math.random(1, #items)]
        end
        if (use.from:hasArmorEffect("vine") or self.player:getHandcardNum() + 2 >= use.from:getHandcardNum())
        and (not (self.player:isChained() and use.from:isChained() and self.player:getHp() <= use.from:getHp())) then
            return "fire_attack"
        end
        local SlashSelf = self:getCardsNum("Slash")
        local SlashTarget = 0
        local Jink = 0
        for _,card in sgs.qlist(use.from:getHandcards()) do
            if card:isKindOf("Jink") then Jink = Jink + 1 end
            if card:isKindOf("Slash") then SlashTarget = SlashTarget + 1 end
        end
        if (not (use.from:hasArmorEffect("vine") and use.from:hasArmorEffect("eight_diagram"))) 
        and Jink == 0 and table.contains(items, "archery_attack") then return "archery_attack" end
        if SlashTarget == 0 and (not use.from:hasArmorEffect("vine")) 
        and table.contains(items, "savage_assault") then return "savage_assault" end
        if SlashSelf >= SlashTarget and table.contains(items, "duel") then return "duel" end
        if (not use.from:isNude()) then
            local patterns = {"snatch", "dismantlement"}
            for _,pattern in ipairs(patterns) do
                if table.contains(items, pattern) then return pattern end
            end
        end
    end
    return items[math.random(1, #items)]
end


--乱政

sgs.ai_cardsview_valuable.nyarz_luanzheng = function(self, class_name, player)
	if self.player:isNude() then return end
    if self.player:getMark("nyarz_luanzheng_failed-Clear") > 0 then return end
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
        ["Nullification"] = "nullification"
	}
	local name = classname2objectname[class_name]
	if not name then return end
    local mark = string.format("nyarz_luanzheng_guhuo_remove_%s_lun", name)
    if self.player:getMark(mark) > 0 then return end
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf(class_name) then return end
    end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    return string.format("#nyarz_luanzheng:.:%s", name)
end
    
sgs.ai_skill_discard.nyarz_luanzheng_put = function(self, max, min)
    if self.player:isNude() then return end
    if self.player:getPhase() == sgs.Player_Play then
        if #self.friends_noself == 0 then
            local cards = sgs.QList2Table(self.player:getCards("he"))
            self:sortByKeepValue(cards)
            return {cards[1]:getEffectiveId()}
        else
            self:sort(self.friends_noself, "defense", true)
            for _,friend in ipairs(self.friends_noself) do
                if friend:getHandcardNum() > (self.player:getHandcardNum() + 1) then return {} end
            end
        end
        local cards = sgs.QList2Table(self.player:getCards("he"))
        self:sortByKeepValue(cards)
        return {cards[1]:getEffectiveId()}
    end
    if (not self:isWeak()) then return {} end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    return {cards[1]:getEffectiveId()}
end

local nyarz_luanzheng_skill = {}
nyarz_luanzheng_skill.name = "nyarz_luanzheng"
table.insert(sgs.ai_skills, nyarz_luanzheng_skill)
nyarz_luanzheng_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("nyarz_luanzheng_failed-Clear") > 0 then return end
    local huace_patterns = self.room:getTag("nyarz_luanzheng_cards"):toString():split("+")
    --if not huace_patterns then return end
	for _,pattern in ipairs(huace_patterns) do
        local canuse = false
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("nyarz_luanzheng")
        card:deleteLater()

        local mark = string.format("nyarz_luanzheng_guhuo_remove_%s_lun", pattern)
        if self.player:getMark(mark) == 0 and card:isAvailable(self.player) then
            canuse = true
        end

        if canuse then
            local usec = {isDummy=true,to=sgs.SPlayerList()}
            self:useCardByClassName(card, usec)
            if usec.card and (not (card:canRecast() and usec.to:length() < 1)) then
                self.nyarz_luanzheng_to = usec.to
                local card_str = string.format("#nyarz_luanzheng:.:%s",  pattern)
                return sgs.Card_Parse(card_str)
            end
        end
    end
end

sgs.ai_skill_use_func["#nyarz_luanzheng"] = function(card, use, self)
	use.card = card
    if use.to then use.to = self.nyarz_luanzheng_to end
end

sgs.ai_use_priority.nyarz_luanzheng = 6.8

sgs.ai_skill_discard.nyarz_luanzheng = function(self, max, min)
    local use = self.room:getTag("nyarz_luanzheng"):toCardUse()
    local target = use.from
    if (not target) or (not self:isFriend(target)) then return {} end
    if self:isWeak() or self.player:isNude() then return {} end
    if target:getPhase() == sgs.Player_NotActive and (not self:isWeak(target)) 
    and self.player:getHandcardNum() <= self.player:getHp() then return {} end
    if target:getPhase() == sgs.Player_Play then
        local cards = sgs.QList2Table(self.player:getCards("he"))
        self:sortByUseValue(cards)
        return {cards[1]:getEffectiveId()}
    end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards, true)
    return {cards[1]:getEffectiveId()}
end

sgs.ai_skill_playerchosen.nyarz_luanzheng = function(self, targets)
    local tos = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    if #self.friends_noself == 0 then return tos[1] end
    self:sort(self.friends_noself, "handcard")
    for _,friend in ipairs(self.friends_noself) do
        if (not self:isWeak(friend)) then return friend end
    end
    return self.friends_noself[1]
end

--权倾

sgs.ai_skill_playerschosen.nyarz_quanqing = function(self, targets, max, min)
    local player = self.player
    if player:getPhase() ~= sgs.Player_NotActive then
        if player:getPhase() == sgs.Player_Discard 
        or player:getPhase() == sgs.Player_Finish then
            local tos = sgs.SPlayerList()
            for _,other in sgs.qlist(self.room:getOtherPlayers(player)) do
                if self:isFriend(other) then
                    tos:append(other)
                end
            end
            return tos
        end
        local tos = sgs.SPlayerList()
        for _,other in sgs.qlist(self.room:getOtherPlayers(player)) do
            if self:isFriend(other) then
                tos:append(other)
            end
            if self:isEnemy(other) then
                if other:getMark("&nyarz_quanqing_bad+#"..player:objectName().."-Clear") == 0 then
                    tos:append(other)
                end
            end
        end
        return tos
    end
    local tos = sgs.SPlayerList()
    local now = self.room:getCurrent()
    if now and self:isEnemy(now) and now:getPhase() == sgs.Player_Play
    and now:getMark("&nyarz_quanqing_bad+#"..player:objectName().."-Clear") == 0 then
        tos:append(now)
    end
    for _,other in sgs.qlist(self.room:getOtherPlayers(player)) do
        if self:isFriend(other) and other:getPhase() ~= sgs.Player_Play
        and ((not self:isWeak(other)) or (other:getMark("&nyarz_quanqing_bad+#"..player:objectName().."-Clear") > 0)) then
            tos:append(other)
        end
    end
    return tos
end

--赏誉

sgs.ai_skill_invoke.nyarz_shangyu = function(self, data)
    local target = self.player:getTag("nyarz_shangyu"):toPlayer()
    return target and self:isFriend(target)
end

sgs.ai_skill_playerchosen.nyarz_shangyu = function(self, targets)
    local target = self.player:getTag("nyarz_shangyu"):toPlayer()
    if (not target) or (not self:isEnemy(target)) then return nil end
    local tos = sgs.QList2Table(self.room:getOtherPlayers(target))
    self:sort(tos, "defense")
    for _,to in ipairs(tos) do
        if self:isFriend(to) then return to end
    end
    return nil
end

sgs.ai_playerchosen_intention.nyarz_shangyu = -80

--才瑕

sgs.ai_skill_invoke.nyarz_caixia = function(self, data)
    local card = self.player:getTag("nyarz_caixia"):toCard()
    if (not card) then return false end
    if self.player:getHp() <= 1 then return nil end
    if card:isKindOf("Peach") or card:isKindOf("Analeptic")
    or card:isKindOf("Nullification") or card:isKindOf("Jink") then return false end
    return true
end

--强袭

local nyarz_qiangxi_skill = {}
nyarz_qiangxi_skill.name = "nyarz_qiangxi"
table.insert(sgs.ai_skills, nyarz_qiangxi_skill)
nyarz_qiangxi_skill.getTurnUseCard = function(self, inclusive)
    if self:isWeak() then return end
    if self.player:getHp() <= 2 then return end
    if #self.enemies <= 0 then return end
    return sgs.Card_Parse("#nyarz_qiangxi:.:")
end

sgs.ai_skill_use_func["#nyarz_qiangxi"] = function(card, use, self)
	--local target
    self:sort(self.enemies, "hp")
    for _,enemy in ipairs(self.enemies) do
        if enemy:getMark("nyarz_qiangxi_damaged-PlayClear") == 0 then
            use.card = card
            if use.to then use.to:append(enemy) end
            return
        end
    end
end

sgs.ai_use_priority.nyarz_qiangxi = 7.8

--狞恶

sgs.ai_skill_discard.nyarz_ninge = function(self, max, min)
    local discards = {}
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards, true)
    local need = {["jink"] = 0, ["nullification"] = 0, ["peach"] = 0}
    local slash = false
    for _,card in ipairs(cards) do
        if need[card:objectName()] and need[card:objectName()] == 0 then
            if card:isKindOf("Peach") and (not self.player:isWounded()) then
                table.insert(discards, card:getEffectiveId())
            else
                need[card:objectName()] = 1
            end
        else
            if card:isAvailable(self.player) then
                local usec = {isDummy=true,to=sgs.SPlayerList()}
                self:useCardByClassName(card, usec)
                if (not usec.card) then table.insert(discards, card:getEffectiveId()) end
                if (not slash) and card:isKindOf("Slash") 
                and (not table.contains(discards, card:getEffectiveId())) then 
                    table.insert(discards, card:getEffectiveId()) 
                end
                if card:isKindOf("Slash") then slash = true end
            else
                table.insert(discards, card:getEffectiveId())
            end
        end
    end
    return discards
end

sgs.ai_skill_choice.nyarz_ninge = function(self, choices, data)
    local damage = data:toDamage()
    if damage.to:objectName() == self.player:objectName() then
        if string.find(choices, "nyarz_qiangxi") then return "nyarz_qiangxi" end
        if string.find(choices, "nyarz_ninge") then return "nyarz_ninge" end
    end
    local items = choices:split("+")
    return items[math.random(1, #items)]
end

