-- Source: b6025acc ai/nybeauty-ai.lua.
local known = AIValue.requireKnown
local nullable={toPlayer=true,getArmor=true,getMaxCard=true,getMinCard=true,useBasicCard=true,useTrickCard=true,useEquipCard=true,useSkillCard=true,useCardByClassName=true,updateIntention=true,setStrategyMemory=true,getStrategyMemory=true}

local function prop(self,key)local v=self.player:getPropertyValue(key);if v==nil then return''end;return v end
local function hydrate(self,value,kind)
 if value==nil then return nil end
 if kind=='Player'then if AIValue.isPlayer(value)then return value end;return known(self.room:findPlayerByObjectName(value),'tag player')end
 if kind=='Card'then if AIValue.isCard(value)or AIValue.isConversion(value)then return value end;return CardView.new(value)end
 if kind=='IntList'then return AIList.new(value)end
 if kind=='CardUse'or kind=='Damage'then
  local row={};for k,v in pairs(value)do row[k]=v end
  for _,k in ipairs{'from','who'}do if row[k]then row[k]=hydrate(self,row[k],'Player')end end
  if kind=='Damage'then if row.to then row.to=hydrate(self,row.to,'Player')end
  else row.to=AIList.new({});for _,n in ipairs(value.to or{})do row.to:append(hydrate(self,n,'Player'))end end
  if row.card then row.card=hydrate(self,row.card,'Card')end;return row
 end
 return value
end
local function tag(self,key)
 local context=self:getDecisionContext().nybeauty
 if type(context)~='table'or context.known_tags==nil or context.known_tags[key]~=true then ai_unsupported('nybeauty source tag not observed',key)end
 return hydrate(self,context[key],context.tag_kinds and context.tag_kinds[key])
end
local function face(self,id)return self:getKnownCardById(id)end
local function complete_hand(self,p)
 local cards=p:getHandcards();if #cards~=p:getHandcardNum()then ai_unsupported('source requires complete lawful foreign hand','nybeauty.foreign_hand')end;return cards
end
local function draw_count(self)return known(self.world.draw_pile_count,'draw_count')end
-- The draw pile size is public; its card order is not projected.
local function draw_id(self,index)
 ai_unsupported('draw pile contents are not projected','nybeauty.observed_draw_index:'..tostring(index))
end
local function draw_top(self,n)
 local index,count=-1,math.min(math.max(1,n),draw_count(self))
 return function()index=index+1;if index<count then return index+1,draw_id(self,index)end end
end
local selectors={nyyuqi=true,nymiaojian=true,nyguose=true,nylijian=true,nyxuechang=true,nybeifen=true,nyyuanyu=true,nyxiyan=true,nywuniang=true,ny_qiaoshi=true,ny_yanyu=true,ny_luochong=true,nyarz_caiyi=true,nyarz_guangu=true,nyarz_guangu_use=true,nyarz_zhifou=true,nyarz_anzhi=true,nyarz_anzhi_dis=true,nyarz_anzhi_give=true,nyarz_yaoyi=true}
local function decode(wire)
 local key,raw,rest=wire:match('^#([%w_]+):([^:]*):(.*)$')
 if not key or not selectors[key]then ai_unsupported('unclassified nybeauty source selector',wire)end
 local ids={};if raw~='.'and raw~=''then for id in raw:gmatch('[^+]+')do local n=tonumber(id);if not n or n<0 or n%1~=0 then ai_unsupported('invalid source cost',wire)end;ids[#ids+1]=n end end
 local targets={};local names=rest:match('^%-%>(.*)$');if names and names~=''then for name in names:gmatch('[^+]+')do targets[#targets+1]=name end end
 if rest~=''and not names then ai_unsupported('unexpected source selector payload',wire)end
 return key,ids,targets
end
local providers={nyarz_guangu_use="nyarz_guangu",nyarz_anzhi_dis="nyarz_anzhi",nyarz_anzhi_give="nyarz_anzhi"}
local function parse(self,wire)
 local key,ids=decode(wire)
 if #ids==0 then return self:legacySkillSeed(providers[key]or key, '#'..key, self.request)end
 return self:evaluateTurnSkillCard(providers[key]or key, '#'..key, ids, self.request)
end
local function respond(self,wire)
 local key,ids,targets=decode(wire)
 local card=self:bindSkillCard(providers[key]or key, ids, self.request, nil, '#'..key)
 return{kind='use_card',card_spec=card:toCardSpec(),targets=targets}
end
local function eval(self,skill,name,ids)return self:evaluateSkillCard(skill, name, ids or{})end
local function answer(self,card,targets)
 local names={};for _,p in ipairs(targets or{})do names[#names+1]=type(p)=='string'and p or p:objectName()end
 if card:isEvaluationOnly()then
  local skill=card:getKnownSkillName(false)
  local provider=skill=='_ny_zhenge'and'ny_zhenge'or skill
  if provider~='nytongli'and provider~='ny_zhenge'then ai_unsupported('unmapped selected declared source card',skill)end
  local receipt=self:bindSkillCard(provider, card:getSubcards(), self.request, card:objectName())
  for _,key in ipairs{'objectName','getSuit','getNumber','getSkillName'}do local a,b;if key=='getSkillName'then a,b=AIValue.callKnown(receipt, key, false),AIValue.callKnown(card, key, false)else a,b=AIValue.callKnown(receipt, key),AIValue.callKnown(card, key)end;if a~=b then ai_unsupported('declared receipt changed source card',key)end end
  local a,b=receipt:getSubcards(),card:getSubcards();if #a~=#b then ai_unsupported('declared receipt changed costs',provider)end;for i,id in ipairs(a)do if b[i]~=id then ai_unsupported('declared receipt reordered costs',provider)end end
  card=receipt
 end
 if AIValue.isConversion(card)then return{kind='use_card',card_spec=card:toCardSpec(),targets=names}end
 if card:isVirtualCard()then ai_unsupported('virtual source card has no authority','nybeauty.response')end
 return{kind='use_card',card_ids={card:getKnownEffectiveId()},targets=names}
end
local function save_targets(self,key,players)
 local value=false;if players then value={};for _,p in ipairs(players)do value[#value+1]=p:objectName()end end
 self:setStrategyMemory('nybeauty.'..key, value)
end
local function load_targets(self,key)
 local row,present=self:getStrategyMemory('nybeauty.'..key);if not present or row==false then return nil end
 local result=AIList.new({});for _,name in ipairs(row)do result:append(known(self.room:findPlayerByObjectName(name),'saved target'))end;return result
end



ai_skill_invoke.nyshanshen = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = nil
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nyshanshentarget") then
            target = p
            break
        end
    end
    if self:isFriend(target) then return (true) or false end
    return (false) or false
end


ai_fill_skill.nyyuqi=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyMark("nyyuqicant-PlayClear") > 0 then return end
    if self.player:getStrategyMark("nyyuqi-PlayClear") >= self.player:getMaxHp() then return end
	return parse(self,"#nyyuqi:.:")
end

ai_card_use["#nyyuqi"] = function(self, card, use, request)
    use.card = card
end

ai_skill_use["@@nyyuqi"] = function(self, prompt, request)
    local card_ids = known(tag(self,"nyyuqiuse"),"nyyuqiuse")
    local canuse = {}
    for _,id in sgs.qlist(card_ids) do
        local card = face(self,id)
        if card:isAvailable(self.player) then
            table.insert(canuse, card)
        end
    end
    if #canuse == 0 then return "." end
    self:sortByCardNeedInPlace(canuse, true, true)
    for _,card in ipairs(canuse) do
        local use = self:aiUseCard(card)
        if use.card then
            if use.to and use.to:length() > 0 then
                local tos = {}
                for _,p in sgs.qlist(use.to) do
                    table.insert(tos, p:objectName())
                end
                return answer(self,card,tos)
            end
        end
    end
    return "."
end


ai_skill_invoke.nyxianjing = true


ai_fill_skill.nymiaojian=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyHasUsed("#nymiaojian") then return end
	return parse(self,"#nymiaojian:.:")
end

ai_card_use["#nymiaojian"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "defense")
	local targets = {}
    local qtargets = sgs.PlayerList()
    local players = sgs.SPlayerList()
	local usecard = eval(self,"nymiaojian","_stabs_slash",{})
    
	for _, enemy in ipairs(self.enemies) do
		local player = self.player
		if usecard:targetFilter(qtargets, enemy, player) and (not player:isProhibited(enemy, usecard, qtargets))
        and (not enemy:hasArmorEffect("vine")) then
			table.insert(targets, enemy:objectName())
            qtargets:append(enemy)
            players:append(enemy)
		end
	end
	
	if #targets > 0 then
		local card_str = string.format("#nymiaojian:.:->%s", table.concat(targets, "+"))
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to = players
		end
	end
end

sgs.ai_use_priority.nymiaojian = sgs.ai_use_priority.Slash-0.1


sgs.ai_skill_discard._stabs_slash = function(self,max,min)
	local player = self.player
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValueInPlace(cards)
	local dis = {}
	if #cards >= 1 then
		table.insert(dis, cards[1]:getEffectiveId())
	end
	return dis
end


ai_skill_invoke.nylianhua = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local n = 1- self.player:getHp()
    local peachs = self:getCardsNum("Analeptic") + self:getCardsNum("Peach")
    if n > peachs then return (true) or false end
    return (false) or false
end
sgs.ai_ajustdamage_to.nylianhua = function(self, from, to, card, nature)
	if to:getStrategyMark("nylianhua_lun") > 0
	then
		return 1
	end
end


sgs.ai_card_intention.nyguose = function(self, card, from, tos)
    for _,to in ipairs(tos) do
        if to:getJudgingArea():length() == 0 then
		    self:updateIntention(from, to, 20)
        end
	end
end

ai_fill_skill.nyguose=function(self, options, request)
    local inclusive = options and options.inclusive

    if not self.player:canPindian() then return end
    if self.player:getHandcardNum() < 2 then return end
    if self.player:getHandcardNum() <= self.player:getMaxCards() - 1 then return end
	return parse(self,"#nyguose:.:")
end

ai_card_use["#nyguose"] = function(self, card, use, request)
    local target = nil
	for _,friend in ipairs(self.friends) do
        if friend:getJudgingArea():length() > 0 and self.player:objectName() ~= friend:objectName() and (not self.player:isPindianProhibited(friend)) and friend:getHandcardNum() > 0
        and (friend:getStrategyMark("nyguosefrom"..self.player:objectName().."-PlayClear") == 0) then
            local min = 14
            for _,mcard in sgs.qlist(complete_hand(self,friend)) do
                if mcard:getNumber() < min then min = mcard:getNumber() end
            end
            if self:getMaxCard():getNumber() > min then target = friend end
        end
        if target then break end
    end

    if not target then
        self:sortInPlace(self.enemies, "handcard")
	    self.enemies = sgs.reverse(self.enemies)
	    for _,p in ipairs(self.enemies) do
		    if p:hasJudgeArea() and (not p:containsTrick("indulgence")) and (not self.player:isPindianProhibited(p)) and p:getHandcardNum() > 0
            and p:getStrategyMark("nyguosefrom"..self.player:objectName().."-PlayClear") == 0 then
                target = p
                break
            end
            if target then break end
	    end
    end
    if not target then return end
    if target then
		local card_str = "#nyguose:.:->"..target:objectName()
		local acard = parse(self,card_str)
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

ai_skill_choice["nyguose"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local target = nil
    choices = choices:split("+")
    if #choices == 1 then return ai_choice_result((choices[1]), options) end
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nyguosetarget") then
            target = p
            break
        end
    end
    if target and self:isFriend(target) then
        for _,choice in ipairs(choices) do
            if string.find(choice, "get") then
                return ai_choice_result((choice), options)
            end
        end
    elseif target and self:isEnemy(target) then
        for _,choice in ipairs(choices) do
            if string.find(choice, "give") then
                return ai_choice_result((choice), options)
            end
        end
    end
    return ai_choice_result((choices[math.random(1, #choices)]), options)
end

sgs.ai_use_priority.nyguose = sgs.ai_use_priority.Slash - 0.1
-- audited alias ai_cardneed.nyguose
ai_skill_invoke.nyliuli = true

ai_skill_choice["nyliuli"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local target = nil
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nyliulitarget") then
            target = p
            break
        end
    end
    if not self:isFriend(target) then return ai_choice_result(("cancel"), options) end
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
                return ai_choice_result((choice), options)
            end
        end
    end
    return ai_choice_result(("cancel"), options)
end


ai_skill_invoke.nyshezhang = true


ai_skill_use["@@nytongli"] = function(self, prompt, request)
    if self.player:getStrategyMark("nytonglitimes") > 8 then return "." end
    local suit = prop(self,"nytonglisuit")
    local can = {}
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:getSuitString() == suit then
            table.insert(can, card)
        end
        if #can >= 5 then break end
    end
    if #can == 0 then return "." end

    local pattern = prop(self,"nytonglipattern")
    local card = eval(self,"nytongli",pattern,{})
    
    local find = false
    local findcard = nil
    self:sortByCardNeedInPlace(can)

    local origin = known(tag(self,"nytongliorigin"),"nytongliorigin")

    for _,c in ipairs(can) do
        if self:getUseValue(c) <= self:getUseValue(origin) then
            card=eval(self,"nytongli",pattern,{c:getKnownEffectiveId()})
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
            return answer(self,card,tos)
        end
    end
    return "."
end


ai_fill_skill.nylijian=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:usedTimes("#nylijian") >= 2 then return end
	return parse(self,"#nylijian:.:")
end

ai_card_use["#nylijian"] = function(self, card, use, request)
    local targets = {}
    local to = sgs.SPlayerList()
    self:sortInPlace(self.enemies, "defense")
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
        self:sortInPlace(others, "defense")
        for _, p in ipairs(others) do
            if #targets < 2 then
                table.insert(targets, p:objectName())
                to:append(p)
            end
        end
    end
    if #targets < 2 and #targets == 1 then
        self:sortInPlace(self.friends, "handcard", true)
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
		local acard = parse(self,card_str)
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
    self:sortInPlace(can, "defense")
    return can[#can]
end

ai_skill_choice["nylijian"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    choices = choices:split("+")
    local from
    local to
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:getStrategyMark("nylijian") == 1 then
            from = p
        elseif p:getStrategyMark("nylijian") == 2 then
            to = p
        end
    end
    if self:isFriend(from) then
        if to:hasArmorEffect("vine") then
            for _,choice in ipairs(choices) do
                if string.find(choice, "fire_slash") then
                    return ai_choice_result((choice), options)
                end
            end
        end
        for _,choice in ipairs(choices) do
            if string.find(choice, "slash") then
                return ai_choice_result((choice), options)
            end
        end
    end
    if (not self:isFriend(from)) and (self.player:usedTimes("#nylijian") >= 2) then
        if table.contains(choices, "duel") then
            return ai_choice_result(("duel"), options)
        end
    end
    if to:hasArmorEffect("vine") then
        for _,choice in ipairs(choices) do
            if string.find(choice, "fire_slash") then
                return ai_choice_result((choice), options)
            end
        end
    end
    if to:isChained() or (self.player:usedTimes("#nylijian") < 2) then
        if table.contains(choices, "slash") then
            return ai_choice_result(("slash"), options)
        end
    end
    return ai_choice_result((choices[math.random(1, #choices)]), options)
end

sgs.ai_card_intention.nylijian = function(self, card, from, tos)
    for _,to in ipairs(tos) do
		self:updateIntention(from, to, 60)
	end
end

sgs.ai_playerchosen_intention.nylijian = function(self, from, to)
	self:updateIntention(from, to, -30)
end


sgs.ai_use_priority.nylijian = sgs.ai_use_priority.Slash + 0.1
sgs.ai_suppress_intention["nylijian"] = true


ai_skill_invoke.nyduoren = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    if self.player:getMaxHp() <= 3 then return (false) or false end
    return (true) or false
end


ai_fill_skill.nyxuechang=function(self, options, request)
    local inclusive = options and options.inclusive

    if not self.player:canPindian() then return end
    if self.player:getStrategyMark("nyxuechangfailed-PlayClear") > 0 then return end
    if self.player:getHandcardNum() < 2 then return end
    if self.player:getHandcardNum() <= self.player:getMaxCards() - 1 then return end
	return parse(self,"#nyxuechang:.:")
end

ai_card_use["#nyxuechang"] = function(self, card, use, request)
    local target = nil
    self:sortInPlace(self.enemies, "defense")
	for _,p in ipairs(self.enemies) do
		if self.player:canPindian(p) and p:getStrategyMark("nyxuechangfrom"..self.player:objectName().."-PlayClear") == 0 then
            target = p
            break
        end
	end
    if not target then return end
    if target then
		local card_str = "#nyxuechang:.:->"..target:objectName()
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.nyxuechang = sgs.ai_use_priority.Slash + 0.1

sgs.ai_ajustdamage_from.nyxuechang = function(self, from, to, card, nature)
	if to:getStrategyMark("nyxuechangtarget"..from:objectName()) > 0
	then
		return 1
	end
end

-- audited alias ai_cardneed.nyxuechang
ai_skill_use["@@nybeifen"] = function(self, prompt, request)
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
        local card = face(self,id)
        table.insert(cards, card)
    end
    self:sortByCardNeedInPlace(cards)
    usecard = cards[#cards]

    if not target then
        self:sortInPlace(self.friends, "defense")
        target = self.friends[1]
    end

    if target then
        local card_str = string.format("#nybeifen:%s:->%s", usecard:getKnownEffectiveId(), target:objectName())
        return respond(self,card_str)
    end
    return "."
end

sgs.ai_card_intention.nybeifen = function(self, card, from, tos)
    for _,to in ipairs(tos) do
		self:updateIntention(from, to, -80)
	end
end


sgs.ai_card_priority.nybeifen = function(self,card,v)
	if card:hasFlag("nybeifen")
	then return 10 end
end


ai_fill_skill.nyyuanyu=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#nyyuanyu") then
		return parse(self,"#nyyuanyu:.:")
	end
end

ai_card_use["#nyyuanyu"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_skill_playerchosen.nyyuanyu = function(self, targets)
    for _,target in sgs.qlist(targets) do
		if self:isFriend(target) and target:getStrategyMark("nyyuanyufrom"..self.player:objectName()) > 0 then
			return target
		end
	end
    for _,target in sgs.qlist(targets) do
		if self:isEnemy(target) and target:getStrategyMark("nyyuanyufrom"..self.player:objectName()) == 0 then
			return target
		end
	end
    return nil
end

sgs.ai_use_priority.nyyuanyu = 10

sgs.ai_playerchosen_intention.nyyuanyu = function(self, from, to)
    if to:getStrategyMark("nyyuanyufrom"..from:objectName()) > 0 then
	    self:updateIntention(from, to, -40)
    else
        self:updateIntention(from, to, 80)
    end
end


ai_skill_use["@@nyxiyan"] = function(self, prompt, request)
    local card_ids = self.player:getPile("nyyuan")
    local spade = {}
    local diamond = {}
    local heart = {}
    local club = {}
    local all = {}
    for _,id in sgs.qlist(card_ids) do
        local c = face(self,id)
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
    self:sortByCardNeedInPlace(all)
    for _,card in ipairs(all) do
        if not table.contains(suits, card:getSuitString()) then
            table.insert(get, card:getKnownEffectiveId())
            table.insert(suits, card:getSuitString())
        end
    end
    if #suits >= 4 then
        local card_str = string.format("#nyxiyan:%s:", table.concat(get, "+"))
        return respond(self,card_str)
    end
    return "."
end


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
	self:updateIntention(from, to, -80)
end

ai_skill_invoke.nykangge = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nykanggetarget") then
            target = p
            break
        end
    end
    return (self:isFriend(target)) or false
end


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
        if p:getStrategyMark("nykanggefrom"..self.player:objectName()) > 0 and self:isFriend(p) then
            return p
        end
    end
    self:sortInPlace(self.friends, "defense")
    return self.friends[1]
end

sgs.ai_playerchosen_intention.nyjielie = function(self, from, to)
	self:updateIntention(from, to, -40)
end


ai_skill_invoke.nyqirang = true

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


ai_skill_choice["nyjinghong"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    if self.player:getHandcardNum() <= 4 then return ai_choice_result(("draw"), options) end
    if self:getCardsNum("Slash") == 0 then return ai_choice_result(("draw"), options) end
    local use = 0
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isAvailable(self.player) then
            local will = self:aiUseCard(card)
            if will.to then use = use + 1 end
            if use >= 4 then return ai_choice_result(("play"), options) end
        end
    end
    return ai_choice_result(("draw"), options)
end


ai_skill_invoke.nymansi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local savage_assault = eval(self,"nymansi","savage_assault",{})
    
    

    return (self:getAoeValue(savage_assault) > 0) or false
end

sgs.ai_card_priority.nymansi = function(self,card,v)
	if card:isKindOf("SavageAssault")
	then return 6 end
end

sgs.ai_target_revises.nymansi = function(to,card)
	if card:isKindOf("SavageAssault")
	then return true end
end


ai_skill_invoke.nyshouying = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local prompt = data:toString()
    if string.find(prompt, "get") then return (true) or false end
    local neednts = {"savage_assault","god_salvation","amazing_grace","peach","ex_nihilo"}
    for _,neednt in ipairs(neednts) do
        if string.find(prompt, neednt) then return (false) or false end
    end
    if string.find(prompt, "iron_chain") and self.player:isChained() then return (false) or false end
    if string.find(prompt, "nullified") then
        for _,p in sgs.qlist(self.room:getAlivePlayers()) do
            if p:hasFlag("nyshouying") then
                return (self:isEnemy(p)) or false
            end
        end
    end
    return (false) or false 
end


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
	self:updateIntention(from, to, -200)
end


ai_skill_invoke.nyxili = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("nyxili") then
            return (self:isFriend(p)) or false
        end
    end
    return false

end


ai_fill_skill.nywuniang=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getPhase() ~= sgs.Player_NotActive then
        if self:getCardsNum("Slash") > 0 then
            if self.player:getJudgingArea():length() == 0 then return end
        end
    end
    local card = eval(self,"nywuniang","slash",{})
    
    local d = self:aiUseCard(card)
    save_targets(self,"nywuniang_to",d.to)
	if d.card and d.to
	and card:isAvailable(self.player)
	then return parse(self,"#nywuniang:.:") end
end

ai_card_use["#nywuniang"] = function(self, card, use, request)
	if load_targets(self,"nywuniang_to")
	then
		use.card = card
		if use.to then use.to = load_targets(self,"nywuniang_to") end
	end
end

sgs.ai_skill_playerchosen.nywuniang = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sortInPlace(targets, "defense")
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
	    self:updateIntention(from, to, 0)
    else
        self:updateIntention(from, to, 60)
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
        return {skill="nywuniang",legacy_class="#nywuniang",subcards={}}
    end
end
 
sgs.ai_use_priority.nywuniang = sgs.ai_use_priority.Slash + 0.1


ai_skill_invoke.nyxushen = true

sgs.ai_skill_playerchosen.nyxushen = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sortInPlace(targets, "defense")
    for _,target in ipairs(targets) do
        if self:isFriend(target) then return target end
    end
    return nil
end

sgs.ai_playerchosen_intention.nyxushen = function(self, from, to)
    self:updateIntention(from, to, -300)
end


sgs.ai_skill_playerchosen.nyzhennan = function(self, targets)
    targets = sgs.QList2Table(targets)
    if not self.player:hasFlag("nyzhennan_more") then
        self:sortInPlace(targets, "hp")
        for _,target in ipairs(targets) do
            if self:isEnemy(target) and target:getStrategyMark("&nyzhennan_damage") < target:getHp() and target:objectName() ~= self.player:objectName() then
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
        local card = known(tag(self,"nyzhennan_card"),"nyzhennan_card")
        if card:isDamageCard() then
            self:sortInPlace(targets, "defense")
            for _,target in ipairs(targets) do
                if self:isEnemy(target) then
                    return target
                end
            end
            return nil
        elseif card:objectName() == "peach" or card:objectName() == "ex_nihilo" or card:objectName() == "analeptic" then
            if card:objectName() == "peach" then
                self:sortInPlace(targets, "hp")
            else
                self:sortInPlace(targets, "defense")
            end
            for _,target in ipairs(targets) do
                if self:isFriend(target) then
                    return target
                end
            end
            return nil
        elseif card:objectName() == "snatch" or card:objectName() =="dismantlement" then
            self:sortInPlace(targets, "defense")
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
        self:updateIntention(from, to, 60)
    else
        self:updateIntention(from, to, 0)
    end
end


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
    self:sortInPlace(enemys, "defense")
    return enemys[1]
end

sgs.ai_skill_discard.ny_channi = function(self,max,min)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByCardNeedInPlace(cards)
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
            table.insert(give, card:getKnownEffectiveId())
        end
        return give
    end
    local need = min
    for _,card in ipairs(cards) do
        table.insert(give, card:getKnownEffectiveId())
        need = need - 1
        if need <= 0 then break end
    end
    return give
end
sgs.ai_suppress_intention["ny_channi"] = true


ai_skill_invoke.ny_xinghan = true


sgs.ai_skill_playerchosen.ny_zhenge = function(self, targets)
    local min = 999
    local target 
    for _,p in sgs.qlist(targets) do
        if self:isFriend(p) and p:getStrategyMark("&ny_zhenge") < min then
            min = p:getStrategyMark("&ny_zhenge")
            target = p
        end
    end
    if min >= 3 then
        self:sortInPlace(self.friends, "handcard")
        return self.friends[1]
    else
        return target
    end
end

ai_skill_use["@@ny_zhenge"] = function(self, prompt, request)
    local slash = eval(self,"ny_zhenge","slash",{})
    

    local usec = {isDummy=true,to=sgs.SPlayerList()}
    self:useCardByClassName(slash, usec)
    if usec.card then
        local tos = {}
        for _,to in sgs.qlist(usec.to) do
            table.insert(tos, to:objectName())
        end
        return answer(self,slash,tos)
    end
    return "."
end


ai_skill_invoke.ny_qiaoshi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local damage = known(tag(self,"ny_qiaoshi"),"ny_qiaoshi")
    if damage.damage > 1 then return (true) or false end
    if damage.from and self:isFriend(damage.from) then return (true) or false end
    return (self:isWeak()) or false
end

ai_skill_use["@@ny_qiaoshi"] = function(self, prompt, request)
    if self.player:hasFlag("ny_qiaoshi_get") then
        local ids = known(tag(self,"ny_qiaoshi_cards"),"ny_qiaoshi_cards")
        local cards = {}
        for _,id in sgs.qlist(ids) do
            local card = face(self,id)
            table.insert(cards, card)
        end
        self:sortByCardNeedInPlace(cards, true)
        local get = {}
        for _,card in ipairs(cards) do
            table.insert(get, card:getKnownEffectiveId())
            if #get >= 2 then break end
        end
        if #get > 0 then
            return respond(self,string.format("#ny_qiaoshi:%s:",table.concat(get,"+")))
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
                    return answer(self,card,tos)
                end
            end
        end
        return "."
    end
end


ai_fill_skill.ny_yanyu=function(self, options, request)
    local inclusive = options and options.inclusive

    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf("Slash") then
            local card_str = "#ny_yanyu:"..card:getEffectiveId()..":"
            return parse(self,card_str)
        end
    end
end

ai_card_use["#ny_yanyu"] = function(self, card, use, request)
	use.card = card
    if #self.friends_noself > 0 then
        self:sortInPlace(self.friends_noself, "defense")
        if use.to then use.to:append(self.friends_noself[1]) end
    end
end


ai_skill_invoke.ny_aichen = true

sgs.ai_skill_discard.ny_aichen = function(self,max,min)
    if (self.player:getStrategyMark("ny_aichen-Clear") == 0) or (self.player:getHandcardNum() > self.player:getMaxCards()) then
        local cards = sgs.QList2Table(self.player:getHandcards())
        if #cards > 0 then
            self:sortByKeepValueInPlace(cards)
            return {cards[1]:getEffectiveId()}
        end
    end
    return {}
end


ai_skill_invoke.ny_luochong = true

local function ny_luochong_judge(player)
    if player:isDead() then return false end
    if not player:isAllNude() then return true end
    for _,p in sgs.qlist(player:getAliveSiblings()) do
        if not p:isAllNude() then return true end
    end
    return false
end

ai_fill_skill.ny_luochong=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyHasUsed("#ny_luochong") then return end
    if (not ny_luochong_judge(self.player)) then return end
    return parse(self,"#ny_luochong:.:")
end

ai_card_use["#ny_luochong"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_priority.ny_luochong = 6

sgs.ai_skill_playerchosen.ny_luochong = function(self, targets)
    if #self.friends > 0 then
        self:sortInPlace(self.friends, "defense")
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
        self:sortInPlace(enemys, "defense")
        for _,enemy in ipairs(enemys) do
            if not enemy:isNude() then return enemy end
        end
    end

    if self.player:hasSkill("ny_aichen") and self.player:getStrategyMark("ny_aichen-Clear") == 0
    and (not self.player:isAllNude()) then return self.player end
    
    return nil
end


ai_skill_invoke.nyarz_guili = true

sgs.ai_skill_playerchosen.nyarz_guili = function(self, targets)
    if #self.friends_noself <= 0 then return nil end
    self:sortInPlace(self.friends_noself, "handcard", true)
    for _,friend in ipairs(self.friends_noself) do
        if (not friend:containsTrick("indulgence")) then return friend end
    end
    return self.friends_noself[#self.friends_noself]
end


ai_skill_use["@@nyarz_caiyi"] = function(self, prompt, request)
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
    self:sortByKeepValueInPlace(cards)
    for _,card in ipairs(cards) do
        local suit = card:getSuitString()
        if not table.contains(suits, suit) then
            table.insert(suits, suit)
            table.insert(need, card:getKnownEffectiveId())
            dis = dis - 1
        end
        if dis <= 0 then break end
    end
    if #need <= 0 then return "." end
    return respond(self,string.format("#nyarz_caiyi:%s:", table.concat(need, "+")))
end

sgs.ai_skill_playerchosen.nyarz_caiyi = function(self, targets)
    local all = sgs.QList2Table(self.room:getAlivePlayers())
    self:sortInPlace(all, "denfense")
    local num = self.player:getStrategyMark("nyarz_caiyi_ai-Clear")
    for _,p in ipairs(all) do
        if self:isEnemy(p) and (p:getCardCount() < 2 * num) and (p:getHp() <= 2 * num) then return p end
    end
    for _,p in ipairs(all) do
        if self:isFriend(p) and self:isWeak(p) then return p end
    end
    return all[1]
end

ai_skill_choice["nyarz_caiyi"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    if string.find(choices, "good") then
        local target = data:toPlayer()
        if self:isFriend(target) then
            for _,item in ipairs(items) do
                if string.find(item, "good") then
                    return ai_choice_result((item), options)
                end
            end
        else
            for _,item in ipairs(items) do
                if string.find(item, "bad") then
                    return ai_choice_result((item), options)
                end
            end
        end
    elseif string.find(choices, "draw") then
        if not self.player:isWounded() then
            for _,item in ipairs(items) do
                if string.find(item, "draw") then
                    return ai_choice_result((item), options)
                end
            end
        else
            if self.player:getHp() == 1 then
                for _,item in ipairs(items) do
                    if string.find(item, "recover") then
                        return ai_choice_result((item), options)
                    end
                end
            end
            local re = math.min(self.player:getLostHp(),self.player:getStrategyMark("nyarz_caiyi_ai-Clear"))
            re = re * 2
            if re >= self.player:getStrategyMark("nyarz_caiyi_ai-Clear") * 2 then
                for _,item in ipairs(items) do
                    if string.find(item, "recover") then
                        return ai_choice_result((item), options)
                    end
                end
            else
                for _,item in ipairs(items) do
                    if string.find(item, "recover") then
                        return ai_choice_result((item), options)
                    end
                end
            end
        end
    elseif string.find(choices, "damage") then
        for _,item in ipairs(items) do
            if string.find(item, "discard") then
                return ai_choice_result((item), options)
            end
        end
    end
    return ai_choice_result((items[math.random(1,#items)]), options)
end


ai_skill_invoke.nyarz_xiaoyong = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local prompt = data:toString()
    local num = tonumber(prompt:split(":")[2])
    if self.player:getPhase() ~= sgs.Player_Play then return (true) or false end
    return (num > 1) or false
end


ai_fill_skill.nyarz_guangu=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyMark("&nyarz_guangu") > 0 then return end
    return parse(self,"#nyarz_guangu:.:")
end

ai_card_use["#nyarz_guangu"] = function(self, card, use, request)
    local all = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    self:sortInPlace(all, "defense")
    local touse = {"useBasicCard","useTrickCard","useEquipCard"}
    for _,p in ipairs(all) do
        if (not self:isFriend(p)) and (not p:isKongcheng()) then
            local cards = sgs.QList2Table(complete_hand(self,p))
            self:sortByUseValueInPlace(cards)
            local max = p:getHandcardNum()
            for _,cc in ipairs(cards) do
                local num = cc:nameLength()
                if cc:isKindOf("Slash") then num = 1 end
                if num > 4 or num > max then continue end

                local usec = {isDummy=true,to=sgs.SPlayerList()}
			    AIValue.callKnown(self, touse[cc:getTypeId()], cc, usec)
                if usec.card then
                    use.card = card
                    if use.to then use.to:append(p) end
                    return 
                end
            end
        end
    end

    local max = math.min(4, draw_count(self))
    if max <= 0 then return end

    for i = 1, max, 1 do
        local cards = {}
        for j = 0, i - 1, 1 do
            local cc = face(self,draw_id(self,j))
            local num = cc:nameLength()
            if cc:isKindOf("Slash") then num = 1 end
            if num == i then
                table.insert(cards, cc)
            end
        end
        if #cards > 0 then
            self:sortByUseValueInPlace(cards)
            for _,cc in ipairs(cards) do
                local usec = {isDummy=true,to=sgs.SPlayerList()}
			    AIValue.callKnown(self, touse[cc:getTypeId()], cc, usec)
                if usec.card then
                    use.card = card
                    return 
                end
            end
        end
    end

    if self.player:getPhase() ~= sgs.Player_Play then return end

    for _,cc in sgs.qlist(self.player:getHandcards()) do
        local num = cc:nameLength()
        if cc:isKindOf("Slash") then num = 1 end
        if num > 4 then continue end

        local usec = {isDummy=true,to=sgs.SPlayerList()}
        AIValue.callKnown(self, touse[cc:getTypeId()], cc, usec)
        if usec.card then
            use.card = card
            return 
        end
    end
end

sgs.ai_use_priority.nyarz_guangu = 8
sgs.ai_use_value.nyarz_guangu = 8

ai_skill_choice.nyarz_guangu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    local target=tag(self,"nyarz_guangu")
    local tag=true
    local touse = {"useBasicCard","useTrickCard","useEquipCard"}
    if (not tag) or (not target) then
        if self.player:getHp() == 1 and self.player:isWounded()
        and self.player:getPhase() ~= sgs.Player_Play then
            local card = face(self,draw_id(self,0))
            if card:isKindOf("Peach") then return ai_choice_result((tostring(1)), options) end
            return ai_choice_result((tostring(4)), options)
        end
        local max = math.min(4, draw_count(self))
        if max <= 0 then return ai_choice_result(nil, options) end
    
        for i = 1, max, 1 do
            local cards = {}
            for j = 0, i - 1, 1 do
                local cc = face(self,draw_id(self,j))
                local num = cc:nameLength()
                if cc:isKindOf("Slash") then num = 1 end
                if num == i then
                    table.insert(cards, cc)
                end
            end
            if #cards > 0 then
                self:sortByUseValueInPlace(cards)
                for _,cc in ipairs(cards) do
                    local usec = {isDummy=true,to=sgs.SPlayerList()}
                    AIValue.callKnown(self, touse[cc:getTypeId()], cc, usec)
                    if usec.card then
                        return ai_choice_result((tostring(i)), options)
                    end
                end
            end
        end
    else
        if self.player:getHp() == 1 and self.player:isWounded()
        and self.player:getPhase() ~= sgs.Player_Play then
            for _,card in sgs.qlist(complete_hand(self,target)) do
                if card:isKindOf("Peach") then return ai_choice_result((tostring(1)), options) end
            end
        end

        local cards = sgs.QList2Table(complete_hand(self,target))
        self:sortByUseValueInPlace(cards)
        local max = target:getHandcardNum()
        for _,cc in ipairs(cards) do
            local num = cc:nameLength()
            if cc:isKindOf("Slash") then num = 1 end
            if num > 4 or num > max then continue end

            local usec = {isDummy=true,to=sgs.SPlayerList()}
            AIValue.callKnown(self, touse[cc:getTypeId()], cc, usec)
            if usec.card then
                return ai_choice_result((tostring(num)), options)
            end
        end
    end
    if self.player:getPhase() ~= sgs.Player_Play then return ai_choice_result(("1"), options) end
    local items = choices:split("+")
    local max = #items

    for _,cc in sgs.qlist(self.player:getHandcards()) do
        local num = cc:nameLength()
        if cc:isKindOf("Slash") then num = 1 end
        if num > 4 then continue end

        local usec = {isDummy=true,to=sgs.SPlayerList()}
        AIValue.callKnown(self, touse[cc:getTypeId()], cc, usec)
        if usec.card and num <= max then
            return ai_choice_result((tostring(num)), options)
        end
    end
    return ai_choice_result((tostring(max)), options)
end

ai_skill_use["@@nyarz_guangu"] = function(self, prompt, request)
    local touse = {"useBasicCard","useTrickCard","useEquipCard"}
    if (not self.player:hasFlag("nyarz_guangu")) then
        if self.player:getPhase() ~= sgs.Player_Play
        and self.player:getHp() == 1 and self.player:isWounded() then
            for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                if (not self:isFriend(p)) and (not p:isKongcheng()) then
                    for _,card in sgs.qlist(complete_hand(self,p)) do
                        if card:isKindOf("Peach") then
                            return respond(self,"#nyarz_guangu:.:->"..p:objectName())
                        end
                    end
                end
            end
            for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                if (self:isFriend(p)) and (not p:isKongcheng()) and (not self:isWeak(p)) then
                    for _,card in sgs.qlist(complete_hand(self,p)) do
                        if card:isKindOf("Peach") then
                            return respond(self,"#nyarz_guangu:.:->"..p:objectName())
                        end
                    end
                end
            end
            local max = 4
            for _,id in draw_top(self,max) do
                local card = face(self,id)
                if card:isKindOf("Peach") then
                    return respond(self,"#nyarz_guangu:.:") 
                end
                max = max - 1
                if max <= 0 then break end
            end
        end

        local card = parse(self,"#nyarz_guangu:.:")
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        self:useSkillCard(card, usec)
        if usec.card then
            if usec.to and (not usec.to:isEmpty()) then 
                return respond(self,"#nyarz_guangu:.:->"..usec.to:at(0):objectName()) 
            end
            return respond(self,"#nyarz_guangu:.:")
        end
    else
        local target=tag(self,"nyarz_guangu")
        local tag=true
        local num = self.player:getStrategyMark("&nyarz_guangu")
        if (not tag) or (not target) then
            if self.player:getPhase() ~= sgs.Player_Play
            and self.player:getHp() == 1 and self.player:isWounded() then
                local max = num
                for _,id in draw_top(self,max) do
                    local card = face(self,id)
                    if card:isKindOf("Peach") then
                        return respond(self,"#nyarz_guangu_use:"..card:getEffectiveId()..":")
                    end
                    max = max - 1
                    if max <= 0 then break end
                end
            end
            local max = num
            for _,id in draw_top(self,max) do
                local cc = face(self,id)
                local namenum = cc:nameLength()
                if cc:isKindOf("Slash") then namenum = 1 end
                if namenum == num then
                    local usec = {isDummy=true,to=sgs.SPlayerList()}
                    AIValue.callKnown(self, touse[cc:getTypeId()], cc, usec)
                    if usec.card then
                        if cc:targetFixed() then
                            return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":") 
                        end
                        local tos = {}
                        for _,to in sgs.qlist(usec.to) do
                            table.insert(tos, to:objectName())
                        end
                        return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":->"..table.concat(tos, "+"))
                    end
                end
                max = max - 1
                if max <= 0 then break end
            end
            max = num
            local cards = {}
            for _,id in draw_top(self,max) do
                table.insert(cards, face(self,id))
                max = max - 1
                if max <= 0 then break end
            end
            self:sortByUseValueInPlace(cards)
            for _,cc in ipairs(cards) do
                local usec = {isDummy=true,to=sgs.SPlayerList()}
                AIValue.callKnown(self, touse[cc:getTypeId()], cc, usec)
                if usec.card then
                    if cc:targetFixed() then
                        return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":") 
                    end
                    local tos = {}
                    for _,to in sgs.qlist(usec.to) do
                        table.insert(tos, to:objectName())
                    end
                    return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":->"..table.concat(tos, "+"))
                end
            end
        else
            if self.player:getPhase() ~= sgs.Player_Play
            and self.player:getHp() == 1 and self.player:isWounded() then
                for _,card in sgs.qlist(complete_hand(self,target)) do
                    if card:isKindOf("Peach") then
                        return respond(self,"#nyarz_guangu_use:"..card:getEffectiveId()..":")
                    end
                end
            end
            local cards = sgs.QList2Table(complete_hand(self,target))
            self:sortByUseValueInPlace(cards)
            for _,cc in ipairs(cards) do
                local namenum = cc:nameLength()
                if cc:isKindOf("Slash") then namenum = 1 end
                if namenum == num then
                    local usec = {isDummy=true,to=sgs.SPlayerList()}
                    AIValue.callKnown(self, touse[cc:getTypeId()], cc, usec)
                    if usec.card then
                        if cc:targetFixed() then
                            return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":") 
                        end
                        local tos = {}
                        for _,to in sgs.qlist(usec.to) do
                            table.insert(tos, to:objectName())
                        end
                        return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":->"..table.concat(tos, "+"))
                    end
                end
            end
            for _,cc in ipairs(cards) do
                local usec = {isDummy=true,to=sgs.SPlayerList()}
                AIValue.callKnown(self, touse[cc:getTypeId()], cc, usec)
                if usec.card then
                    if cc:targetFixed() then
                        return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":") 
                    end
                    local tos = {}
                    for _,to in sgs.qlist(usec.to) do
                        table.insert(tos, to:objectName())
                    end
                    return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":->"..table.concat(tos, "+"))
                end
            end
        end
    end
end


sgs.ai_skill_playerchosen.nyarz_lingren = function(self, targets)
    local all = sgs.QList2Table(targets)
    self:sortInPlace(all, "defense")
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


sgs.ai_skill_playerchosen.nyarz_lingxi = function(self, targets)
    if #self.enemies == 0 then return nil end
    self:sortInPlace(self.enemies, "defense")
    return self.enemies[1]
end

sgs.ai_playerchosen_intention.nyarz_lingxi = 40

ai_skill_invoke.nyarz_lingxi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = known(tag(self,"nyarz_lingxi_use"),"nyarz_lingxi_use")
    if use.card:isKindOf("EquipCard") then return (false) or false end
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
        local suit = face(self,id):getSuitString()
        if (not table.contains(suits, suit)) then
            table.insert(suits, suit)
        end
    end
    return (((2*(#suits)) + 2) >= self.player:getHandcardNum()) or false
end


sgs.ai_cardsview_valuable.nyarz_zhifou = function(self, class_name, player)
	if self.player:isKongcheng() or (self.player:getStrategyMark("nyarz_zhifou-Clear") > 0) then return end
	if class_name ~= "Peach" then return end
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf(class_name) and (self.player:getHandcardNum() > 1) then return end
    end
	return {skill="nyarz_zhifou",legacy_class="#nyarz_zhifou",subcards={}}
end

ai_fill_skill.nyarz_zhifou=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:isKongcheng() or (self.player:getStrategyMark("nyarz_zhifou-Clear") > 0) then return end
    local pattern = "peach"
    if self.player:getHandcardNum() > 1 then
        for _,card in sgs.qlist(self.player:getHandcards()) do
            if card:objectName() == pattern then return end
        end
    end
    local card = eval(self,"nyarz_zhifou",pattern,{})
    
    if (not card:isAvailable(self.player)) then return end

    local use = {isDummy=true,to=sgs.SPlayerList()}

    self:useBasicCard(card, use)
    if use.card then
        save_targets(self,"nyarz_zhifou_to",use.to)
        return parse(self,"#nyarz_zhifou:.:")
    end
end

ai_card_use["#nyarz_zhifou"] = function(self, card, use, request)
    use.card = card
    if use.to then use.to = load_targets(self,"nyarz_zhifou_to") end
end

-- audited alias ai_use_priority.nyarz_zhifou
ai_skill_invoke.nyarz_zhifou = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    return (target and self:isFriend(target)) or false
end


ai_skill_invoke.nyarz_xialei = true

sgs.ai_hasTuntianEffect_skill.nyarz_xialei = function(to, need_zaoxian)
	return to:getStrategyMark("nyarz_xialei-Clear") == 0
end


ai_fill_skill.nyarz_anzhi=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyMark("nyarz_anzhi_disable-Clear") > 0 then return end
    return parse(self,"#nyarz_anzhi:.:")
end

ai_card_use["#nyarz_anzhi"] = function(self, card, use, request)
    use.card = card
end

ai_skill_use["@@nyarz_anzhi"] = function(self, prompt, request)
    if self.player:getStrategyMark("nyarz_anzhi") == 0 then return respond(self,"#nyarz_anzhi:.:") end
    if self.player:getStrategyMark("nyarz_anzhi") == 1 then
        local dis = {}
        local min = math.max(0, draw_count(self) - 3)
        local need = true
        for i = min, draw_count(self) - 1, 1 do
            local id = draw_id(self,i)
            local card = face(self,id)
            local mark = string.format("@nyarz_anzhi_%s-Clear", card:getSuitString())
            if self.player:getStrategyMark(mark) > 0 then
                table.insert(dis, id)
            else
                if need then
                    need = false
                    table.insert(dis, id)
                end
            end
        end
        return respond(self,"#nyarz_anzhi_dis:"..table.concat(dis, "+")..":")
    end
    if self.player:getStrategyMark("nyarz_anzhi") == 2 then
        local ids = tag(self,"nyarz_anzhi")
        if (not ids) or (ids:isEmpty()) then return end
        local cards = {}
        for _,id in sgs.qlist(ids) do
            if self.room:getCardPlace(id) == sgs.Player_DiscardPile then
                table.insert(cards, face(self,id))
            end
        end
        if #cards <= 0 then return end
        if self.player:getPhase() == sgs.Player_Play then
            self:sortByUseValueInPlace(cards)
            for i = 1, #cards, 1 do
                if (not cards[i]:isKindOf("EquipCard")) then
                    return respond(self,"#nyarz_anzhi_give:"..cards[i]:getEffectiveId()..":->"..self.player:objectName())
                end
            end
            return respond(self,"#nyarz_anzhi_give:"..cards[1]:getEffectiveId()..":->"..self.player:objectName())
        else
            self:sortByKeepValueInPlace(cards)
            self:sortInPlace(self.friends, "defense")
            return respond(self,"#nyarz_anzhi_give:"..cards[1]:getEffectiveId()..":->"..self.friends[1]:objectName())
        end
    end
end


ai_skill_invoke.nyarz_fuxve = true


ai_skill_use["@@nyarz_yaoyi"] = function(self, prompt, request)
    if self.player:isKongcheng() then return end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValueInPlace(cards)
    local types = {"BasicCard","TrickCard","EquipCard"}
    for _,card in ipairs(cards) do
        if card:isAvailable(self.player) then
            local dummy = {isDummy=true,to=sgs.SPlayerList()}
			AIValue.callKnown(self, "use"..types[card:getTypeId()], card, dummy)
            if dummy.card and dummy.to then
                local tos = {}
                for _,to in sgs.qlist(dummy.to) do
                    table.insert(tos, to:objectName())
                end
                return answer(self,card,tos)
            end
        end
    end
end

sgs.ai_skill_playerchosen.nyarz_yaoyi = function(self, targets)
    if #self.friends_noself == 0 then
        local tos = sgs.QList2Table(targets)
        self:sortInPlace(tos, "handcard")
        return tos[1]
    end
    self:sortInPlace(self.friends_noself, "handcard", true)
    if math.random(1,3) == 1 then
        for _,to in ipairs(self.friends_noself) do
            for _,hand in sgs.qlist(complete_hand(self,to)) do
                if hand:isAvailable(to) then return to end
            end
        end
    end
    return self.friends_noself[1]
end

ai_fill_skill.nyarz_yaoyi=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyMark("nyarz_yaoyi_failed-PlayClear") == 0 then
        return parse(self,"#nyarz_yaoyi:.:")
    else
        local cards = sgs.QList2Table(self.player:getHandcards())
        self:sortByUseValueInPlace(cards)
        local types = {"BasicCard","TrickCard","EquipCard"}
        for _,card in ipairs(cards) do
            if card:isAvailable(self.player) then
                local dummy = {isDummy=true,to=sgs.SPlayerList()}
                AIValue.callKnown(self, "use"..types[card:getTypeId()], card, dummy)
                if dummy.card and dummy.to then
                    return parse(self,"#nyarz_yaoyi:.:")
                end
            end
        end
    end
end

ai_card_use["#nyarz_yaoyi"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_playerchosen_intention.nyarz_yaoyi = -20
sgs.ai_use_priority.nyarz_yaoyi = 7.8

ai_audited_aliases.register({id="ai_cardneed.nyguose",registry="ai_cardneed",path={"nyguose"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.nyxuechang",registry="ai_cardneed",path={"nyxuechang"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_use_priority.nyarz_zhifou",registry="ai_use_priority",path={"nyarz_zhifou"},canonical_registry="ai_use_priority",canonical_path={"Peach"},self_index=3,defer_canonical=true})
