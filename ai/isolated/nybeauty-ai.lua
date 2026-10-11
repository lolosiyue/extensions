-- nybeauty fixed b6025acc: original policy order, pure public/owner inputs.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported('nybeauty input unknown',k)end;return v end
local nullable={toPlayer=true,getArmor=true,getMaxCard=true,getMinCard=true,useBasicCard=true,useTrickCard=true,useEquipCard=true,useSkillCard=true,useCardByClassName=true,updateIntention=true,setStrategyMemory=true,getStrategyMemory=true}
local function q(o,k,...)
 if not o or type(o[k])~='function'then ai_unsupported('nybeauty helper unavailable',k)end
 local method=k;if k=='getMark'and AIValue.isPlayer(o)then method='getStrategyMark'end
 local r=table.pack(o[method](o,...));if AIUnsupported.is(r[1])then error(r[1],0)end
 if k=='sort'or k=='sortByKeepValue'or k=='sortByUseValue'or k=='sortByCardNeed'then local t=(...);known(r[1],k);for i,x in ipairs(r[1])do t[i]=x end;return t end
 if k=='hasSkill'or k=='hasSkills'then local p=AIValue.isPlayer(o)and o or select(2,...)or o.player;local row=type(p)=='table'and rawget(p,'_view');if r[1]==false and row and row.skills_complete~=true then ai_unsupported('nybeauty foreign skill absence unknown',(...))end end
 if not nullable[k]then known(r[1],k)end;return table.unpack(r,1,r.n)
end
local function facts(self)return known(self.world.strategy_facts and self.world.strategy_facts.nybeauty,'nybeauty')end
local function prop(self,key)return known(facts(self).properties and facts(self).properties[key],key)end
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
 local context=q(self,'getDecisionContext').nybeauty
 if type(context)~='table'or context.known_tags==nil or context.known_tags[key]~=true then ai_unsupported('nybeauty source tag not observed',key)end
 return hydrate(self,context[key],context.tag_kinds and context.tag_kinds[key])
end
local function face(self,id)return q(self,'getKnownCardById',id)end
local function complete_hand(self,p)
 local cards=q(p,'getHandcards');if #cards~=q(p,'getHandcardNum')then ai_unsupported('source requires complete lawful foreign hand','nybeauty.foreign_hand')end;return cards
end
local function draw_count(self)return known(facts(self).draw_count,'draw_count')end
local function draw_id(self,index)
 local rows=facts(self).observed_draw_ids
 return known(rows and rows[tostring(index)],'nybeauty.observed_draw_index:'..tostring(index))
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
 if #ids==0 then return q(self,'legacySkillSeed',providers[key]or key,'#'..key,self.request)end
 return q(self,'evaluateTurnSkillCard',providers[key]or key,'#'..key,ids,self.request)
end
local function respond(self,wire)
 local key,ids,targets=decode(wire)
 local card=q(self,'bindSkillCard',providers[key]or key,ids,self.request,nil,'#'..key)
 return{kind='use_card',card_spec=q(card,'toCardSpec'),targets=targets}
end
local function eval(self,skill,name,ids)return q(self,'evaluateSkillCard',skill,name,ids or{})end
local function answer(self,card,targets)
 local names={};for _,p in ipairs(targets or{})do names[#names+1]=type(p)=='string'and p or q(p,'objectName')end
 if q(card,'isEvaluationOnly')then
  local skill=q(card,'getSkillName',false)
  local provider=skill=='_ny_zhenge'and'ny_zhenge'or skill
  if provider~='nytongli'and provider~='ny_zhenge'then ai_unsupported('unmapped selected declared source card',skill)end
  local receipt=q(self,'bindSkillCard',provider,q(card,'getSubcards'),self.request,q(card,'objectName'))
  for _,key in ipairs{'objectName','getSuit','getNumber','getSkillName'}do local a,b;if key=='getSkillName'then a,b=q(receipt,key,false),q(card,key,false)else a,b=q(receipt,key),q(card,key)end;if a~=b then ai_unsupported('declared receipt changed source card',key)end end
  local a,b=q(receipt,'getSubcards'),q(card,'getSubcards');if #a~=#b then ai_unsupported('declared receipt changed costs',provider)end;for i,id in ipairs(a)do if b[i]~=id then ai_unsupported('declared receipt reordered costs',provider)end end
  card=receipt
 end
 if AIValue.isConversion(card)then return{kind='use_card',card_spec=q(card,'toCardSpec'),targets=names}end
 if q(card,'isVirtualCard')then ai_unsupported('virtual source card has no authority','nybeauty.response')end
 return{kind='use_card',card_ids={q(card,'getEffectiveId')},targets=names}
end
local function save_targets(self,key,players)
 local value=false;if players then value={};for _,p in ipairs(players)do value[#value+1]=q(p,'objectName')end end
 q(self,'setStrategyMemory','nybeauty.'..key,value)
end
local function load_targets(self,key)
 local row,present=q(self,'getStrategyMemory','nybeauty.'..key);if not present or row==false then return nil end
 local result=AIList.new({});for _,name in ipairs(row)do result:append(known(self.room:findPlayerByObjectName(name),'saved target'))end;return result
end



sgs.ai_skill_invoke.nyshanshen = function(self, data)
    local target = nil
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"hasFlag","nyshanshentarget") then
            target = p
            break
        end
    end
    if q(self,"isFriend",target) then return true end
    return false
end


sgs.ai_fill_skill.nyyuqi=function(self,inclusive,request)
    if q(self.player,"getMark","nyyuqicant-PlayClear") > 0 then return end
    if q(self.player,"getMark","nyyuqi-PlayClear") >= q(self.player,"getMaxHp") then return end
	return parse(self,"#nyyuqi:.:")
end

sgs.ai_skill_use_func["#nyyuqi"] = function(card, use, self)
    use.card = card
end

sgs.ai_skill_use["@@nyyuqi"] = function(self, prompt)
    local card_ids = known(tag(self,"nyyuqiuse"),"nyyuqiuse")
    local canuse = {}
    for _,id in sgs.qlist(card_ids) do
        local card = face(self,id)
        if q(card,"isAvailable",self.player) then
            table.insert(canuse, card)
        end
    end
    if #canuse == 0 then return "." end
    q(self,"sortByCardNeed",canuse, true, true)
    for _,card in ipairs(canuse) do
        local use = q(self,"aiUseCard",card)
        if use.card then
            if use.to and use.to:length() > 0 then
                local tos = {}
                for _,p in sgs.qlist(use.to) do
                    table.insert(tos, q(p,"objectName"))
                end
                return answer(self,card,tos)
            end
        end
    end
    return "."
end


sgs.ai_skill_invoke.nyxianjing = true


sgs.ai_fill_skill.nymiaojian=function(self,inclusive,request)
    if q(self.player,"hasUsed","#nymiaojian") then return end
	return parse(self,"#nymiaojian:.:")
end

sgs.ai_skill_use_func["#nymiaojian"] = function(card, use, self)
	q(self,"sort",self.enemies, "defense")
	local targets = {}
    local qtargets = sgs.PlayerList()
    local players = sgs.SPlayerList()
	local usecard = eval(self,"nymiaojian","_stabs_slash",{})
    
	for _, enemy in ipairs(self.enemies) do
		local player = self.player
		if q(usecard,"targetFilter",qtargets, enemy, player) and (not q(player,"isProhibited",enemy, usecard, qtargets)) 
        and (not q(enemy,"hasArmorEffect","vine")) then
			table.insert(targets, q(enemy,"objectName"))
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
	local cards = sgs.QList2Table(q(self.player,"getCards","h"))
	q(self,"sortByKeepValue",cards)
	local dis = {}
	if #cards >= 1 then
		table.insert(dis, cards[1]:getEffectiveId())
	end
	return dis
end


sgs.ai_skill_invoke.nylianhua = function(self, data)
    local n = 1- q(self.player,"getHp")
    local peachs = q(self,"getCardsNum","Analeptic") + q(self,"getCardsNum","Peach")
    if n > peachs then return true end
    return false
end
sgs.ai_ajustdamage_to.nylianhua = function(self, from, to, card, nature)
	if q(to,"getMark","nylianhua_lun") > 0
	then
		return 1
	end
end


sgs.ai_card_intention.nyguose = function(self, card, from, tos)
    for _,to in ipairs(tos) do
        if q(to,"getJudgingArea"):length() == 0 then
		    q(self,"updateIntention",from, to, 20)
        end
	end
end

sgs.ai_fill_skill.nyguose=function(self,inclusive,request)
    if not q(self.player,"canPindian") then return end
    if q(self.player,"getHandcardNum") < 2 then return end
    if q(self.player,"getHandcardNum") <= q(self.player,"getMaxCards") - 1 then return end
	return parse(self,"#nyguose:.:")
end

sgs.ai_skill_use_func["#nyguose"] = function(card, use, self)
    local target = nil
	for _,friend in ipairs(self.friends) do
        if q(friend,"getJudgingArea"):length() > 0 and q(self.player,"objectName") ~= q(friend,"objectName") and (not q(self.player,"isPindianProhibited",friend)) and q(friend,"getHandcardNum") > 0 
        and (q(friend,"getMark","nyguosefrom"..self.player:objectName().."-PlayClear") == 0) then
            local min = 14
            for _,mcard in sgs.qlist(complete_hand(self,friend)) do
                if q(mcard,"getNumber") < min then min = q(mcard,"getNumber") end
            end
            if q(self,"getMaxCard"):getNumber() > min then target = friend end
        end
        if target then break end
    end

    if not target then
        q(self,"sort",self.enemies, "handcard")
	    self.enemies = sgs.reverse(self.enemies)
	    for _,p in ipairs(self.enemies) do
		    if q(p,"hasJudgeArea") and (not q(p,"containsTrick","indulgence")) and (not q(self.player,"isPindianProhibited",p)) and q(p,"getHandcardNum") > 0 
            and q(p,"getMark","nyguosefrom"..self.player:objectName().."-PlayClear") == 0 then
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
    local maxcard = q(self,"getMaxCard")
    if q(self,"isFriend",requestor) then 
        return q(self,"getMinCard") 
    else
        if q(maxcard,"getNumber") < 6 then
            return minusecard or q(self,"getMaxCard")
        else
            return q(self,"getMaxCard")
        end
    end
end

sgs.ai_skill_choice["nyguose"] = function(self, choices, data)
    local target = nil
    choices = choices:split("+")
    if #choices == 1 then return choices[1] end
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"hasFlag","nyguosetarget") then
            target = p
            break
        end
    end
    if target and q(self,"isFriend",target) then
        for _,choice in ipairs(choices) do
            if string.find(choice, "get") then
                return choice
            end
        end
    elseif target and q(self,"isEnemy",target) then
        for _,choice in ipairs(choices) do
            if string.find(choice, "give") then
                return choice
            end
        end
    end
    return choices[math.random(1, #choices)]
end

sgs.ai_use_priority.nyguose = sgs.ai_use_priority.Slash - 0.1
-- audited alias ai_cardneed.nyguose
sgs.ai_skill_invoke.nyliuli = true

sgs.ai_skill_choice["nyliuli"] = function(self, choices, data)
    local target = nil
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"hasFlag","nyliulitarget") then
            target = p
            break
        end
    end
    if not q(self,"isFriend",target) then return "cancel" end
    local will = false
    choices = choices:split("+")
    if q(self.player,"getHp") > q(target,"getHp") then will = true end
    if q(self.player,"getHp") < q(target,"getHp") and q(target,"isWounded") and q(self.player,"getHandcardNum") >= q(target,"getHandcardNum") then
        if q(target,"hasFlag","nyliulislash") and q(self,"getCardsNum","Jink") > 0 then will = true end
        if q(target,"hasFlag","nyliuliduel") and q(self,"getCardsNum","Slash") > 1 then will = true end
    end
    if q(self.player,"getHp") == q(target,"getHp") then
        if q(target,"hasFlag","nyliulislash") and q(self,"getCardsNum","Jink") > 0 then will = true end
        if q(target,"hasFlag","nyliuliduel") and q(self,"getCardsNum","Slash") > 1 then will = true end
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


sgs.ai_skill_invoke.nyshezhang = true


sgs.ai_skill_use["@@nytongli"] = function(self, prompt)
    if q(self.player,"getMark","nytonglitimes") > 8 then return "." end
    local suit = prop(self,"nytonglisuit")
    local can = {}
    for _,card in sgs.qlist(q(self.player,"getHandcards")) do
        if q(card,"getSuitString") == suit then
            table.insert(can, card)
        end
        if #can >= 5 then break end
    end
    if #can == 0 then return "." end

    local pattern = prop(self,"nytonglipattern")
    local card = eval(self,"nytongli",pattern,{})
    
    local find = false
    local findcard = nil
    q(self,"sortByCardNeed",can)

    local origin = known(tag(self,"nytongliorigin"),"nytongliorigin")

    for _,c in ipairs(can) do
        if q(self,"getUseValue",c) <= q(self,"getUseValue",origin) then
            card=eval(self,"nytongli",pattern,{q(c,"getEffectiveId")})
            findcard = c
            find = true
            break
        end
    end
    if not find then return "." end

    local use = q(self,"aiUseCard",card)
    if use.card then
        if use.to and use.to:length() > 0 then
            local tos = {}
            for _,p in sgs.qlist(use.to) do
                table.insert(tos, q(p,"objectName"))
            end
            return answer(self,card,tos)
        end
    end
    return "."
end


sgs.ai_fill_skill.nylijian=function(self,inclusive,request)
    if q(self.player,"usedTimes","#nylijian") >= 2 then return end
	return parse(self,"#nylijian:.:")
end

sgs.ai_skill_use_func["#nylijian"] = function(card, use, self)
    local targets = {}
    local to = sgs.SPlayerList()
    q(self,"sort",self.enemies, "defense")
    for _, p in ipairs(self.enemies) do
        if #targets < 2 then
            table.insert(targets, q(p,"objectName"))
            to:append(p)
        end
    end
    if #targets < 2 then
        local others = {}
        for _,p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
            if (not table.contains(targets, q(p,"objectName"))) and (not q(self,"isFriend",p)) then
                table.insert(others, p)
            end
        end
        q(self,"sort",others, "defense")
        for _, p in ipairs(others) do
            if #targets < 2 then
                table.insert(targets, q(p,"objectName"))
                to:append(p)
            end
        end
    end
    if #targets < 2 and #targets == 1 then
        q(self,"sort",self.friends, "handcard",true)
        for _, p in ipairs(self.friends) do
            if #targets < 2 and (not table.contains(targets, q(p,"objectName"))) then
                table.insert(targets, q(p,"objectName"))
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
		if q(self,"isFriend",target) or q(target,"objectName") == q(self.player,"objectName") then
			return target
		end
	end
    local can = {}
    for _,target in sgs.qlist(targets) do
		table.insert(can, target)
	end
    q(self,"sort",can, "defense")
    return can[#can]
end

sgs.ai_skill_choice["nylijian"] = function(self, choices, data)
    choices = choices:split("+")
    local from
    local to
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"getMark","nylijian") == 1 then
            from = p
        elseif q(p,"getMark","nylijian") == 2 then
            to = p
        end
    end
    if q(self,"isFriend",from) then
        if q(to,"hasArmorEffect","vine") then
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
    if (not q(self,"isFriend",from)) and (q(self.player,"usedTimes","#nylijian") >= 2) then
        if table.contains(choices, "duel") then
            return "duel"
        end
    end
    if q(to,"hasArmorEffect","vine") then
        for _,choice in ipairs(choices) do
            if string.find(choice, "fire_slash") then
                return choice
            end
        end
    end
    if q(to,"isChained") or (q(self.player,"usedTimes","#nylijian") < 2) then
        if table.contains(choices, "slash") then
            return "slash"
        end
    end
    return choices[math.random(1, #choices)]
end

sgs.ai_card_intention.nylijian = function(self, card, from, tos)
    for _,to in ipairs(tos) do
		q(self,"updateIntention",from, to, 60)
	end
end

sgs.ai_playerchosen_intention.nylijian = function(self, from, to)
	q(self,"updateIntention",from, to, -30)
end


sgs.ai_use_priority.nylijian = sgs.ai_use_priority.Slash + 0.1
sgs.ai_suppress_intention["nylijian"] = true


sgs.ai_skill_invoke.nyduoren = function(self, data)
    if q(self.player,"getMaxHp") <= 3 then return false end
    return true
end


sgs.ai_fill_skill.nyxuechang=function(self,inclusive,request)
    if not q(self.player,"canPindian") then return end
    if q(self.player,"getMark","nyxuechangfailed-PlayClear") > 0 then return end
    if q(self.player,"getHandcardNum") < 2 then return end
    if q(self.player,"getHandcardNum") <= q(self.player,"getMaxCards") - 1 then return end
	return parse(self,"#nyxuechang:.:")
end

sgs.ai_skill_use_func["#nyxuechang"] = function(card, use, self)
    local target = nil
    q(self,"sort",self.enemies, "defense")
	for _,p in ipairs(self.enemies) do
		if q(self.player,"canPindian",p) and q(p,"getMark","nyxuechangfrom"..self.player:objectName().."-PlayClear") == 0 then
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
	if q(to,"getMark","nyxuechangtarget"..from:objectName()) > 0
	then
		return 1
	end
end

-- audited alias ai_cardneed.nyxuechang
sgs.ai_skill_use["@@nybeifen"] = function(self, prompt)
    local target = nil
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"hasFlag","nybeifentarget") then
            target = p
            break
        end
    end
    if target and (not q(self,"isFriend",target)) then return "." end

    local usecard = {}
    local cards = {}
    local card_ids = q(self.player,"getPile","nyhujia")
    for _,id in sgs.qlist(card_ids) do
        local card = face(self,id)
        table.insert(cards, card)
    end
    q(self,"sortByCardNeed",cards)
    usecard = cards[#cards]

    if not target then
        q(self,"sort",self.friends, "defense")
        target = self.friends[1]
    end

    if target then
        local card_str = string.format("#nybeifen:%s:->%s", q(usecard,"getEffectiveId"), q(target,"objectName"))
        return respond(self,card_str)
    end
    return "."
end

sgs.ai_card_intention.nybeifen = function(self, card, from, tos)
    for _,to in ipairs(tos) do
		q(self,"updateIntention",from, to, -80)
	end
end


sgs.ai_card_priority.nybeifen = function(self,card,v)
	if q(card,"hasFlag","nybeifen")
	then return 10 end
end


sgs.ai_fill_skill.nyyuanyu=function(self,inclusive,request)
	if not q(self.player,"hasUsed","#nyyuanyu") then
		return parse(self,"#nyyuanyu:.:")
	end
end

sgs.ai_skill_use_func["#nyyuanyu"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_playerchosen.nyyuanyu = function(self, targets)
    for _,target in sgs.qlist(targets) do
		if q(self,"isFriend",target) and q(target,"getMark","nyyuanyufrom"..self.player:objectName()) > 0 then
			return target
		end
	end
    for _,target in sgs.qlist(targets) do
		if q(self,"isEnemy",target) and q(target,"getMark","nyyuanyufrom"..self.player:objectName()) == 0 then
			return target
		end
	end
    return nil
end

sgs.ai_use_priority.nyyuanyu = 10

sgs.ai_playerchosen_intention.nyyuanyu = function(self, from, to)
    if q(to,"getMark","nyyuanyufrom"..from:objectName()) > 0 then
	    q(self,"updateIntention",from, to, -40)
    else
        q(self,"updateIntention",from, to, 80)
    end
end


sgs.ai_skill_use["@@nyxiyan"] = function(self, prompt)
    local card_ids = q(self.player,"getPile","nyyuan")
    local spade = {}
    local diamond = {}
    local heart = {}
    local club = {}
    local all = {}
    for _,id in sgs.qlist(card_ids) do
        local c = face(self,id)
        if q(c,"getSuit") == sgs.Card_Spade then
            table.insert(spade, c)
        elseif q(c,"getSuit") == sgs.Card_Heart then
            table.insert(heart, c)
        elseif q(c,"getSuit") == sgs.Card_Club then
            table.insert(club, c)
        elseif q(c,"getSuit") == sgs.Card_Diamond then
            table.insert(diamond, c)
        end
        table.insert(all, c)
    end
    if #spade < 2 or #diamond < 2 or #heart < 2 or #club < 2 then return "." end
    local get = {}
    local suits = {}
    q(self,"sortByCardNeed",all)
    for _,card in ipairs(all) do
        if not table.contains(suits, q(card,"getSuitString")) then
            table.insert(get, q(card,"getEffectiveId"))
            table.insert(suits, q(card,"getSuitString"))
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
		if q(self,"isFriend",target) then
			return target
		end
	end
    for _,target in sgs.qlist(targets) do
        if not q(self,"isEnemy",target) then
            return target
        end
    end
    targets = sgs.QList2Table(targets)
    return targets[math.random(1,#targets)]
end

sgs.ai_playerchosen_intention.nykangge = function(self, from, to)
	q(self,"updateIntention",from, to, -80)
end

sgs.ai_skill_invoke.nykangge = function(self, data)
    local target
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"hasFlag","nykanggetarget") then
            target = p
            break
        end
    end
    return q(self,"isFriend",target)
end


sgs.ai_skill_playerchosen.nyjielie = function(self, targets)
    local target
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"hasFlag","nyjielietarget") then
            target = p
            break
        end
    end
    if not q(self,"isFriend",target) then return nil end
    if q(target,"objectName") ~= q(self.player,"objectName") and q(self.player,"getHp") == 1 and (q(self,"getCardsNum","Analeptic") + q(self,"getCardsNum","Peach") <= 0) then
        return nil
    end
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"getMark","nykanggefrom"..self.player:objectName()) > 0 and q(self,"isFriend",p) then
            return p
        end
    end
    q(self,"sort",self.friends, "defense")
    return self.friends[1]
end

sgs.ai_playerchosen_intention.nyjielie = function(self, from, to)
	q(self,"updateIntention",from, to, -40)
end


sgs.ai_skill_invoke.nyqirang = true

sgs.ai_use_revises.nyqirang = function(self,card,use)
	if q(card,"isKindOf","EquipCard") and q(self,"evaluateArmor",card)>-5
	then use.card = card return true end
end
sgs.ai_card_priority.nyqirang = function(self,card,v)
	if self.useValue
	and q(card,"isKindOf","TrickCard")
	then v = v+3 end
end


function sgs.ai_cardneed.nyqirang(to,card)
	return q(card,"getTypeId")==sgs.Card_TypeTrick or q(card,"getTypeId")==sgs.Card_TypeEquip
end


sgs.ai_skill_choice["nyjinghong"] = function(self, choices, data)
    if q(self.player,"getHandcardNum") <= 4 then return "draw" end
    if q(self,"getCardsNum","Slash") == 0 then return "draw" end
    local use = 0
    for _,card in sgs.qlist(q(self.player,"getHandcards")) do
        if q(card,"isAvailable",self.player) then
            local will = q(self,"aiUseCard",card)
            if will.to then use = use + 1 end
            if use >= 4 then return "play" end
        end
    end
    return "draw"
end


sgs.ai_skill_invoke.nymansi = function(self, data)
    local savage_assault = eval(self,"nymansi","savage_assault",{})
    
    

    return q(self,"getAoeValue",savage_assault) > 0
end

sgs.ai_card_priority.nymansi = function(self,card,v)
	if q(card,"isKindOf","SavageAssault")
	then return 6 end
end

sgs.ai_target_revises.nymansi = function(to,card)
	if q(card,"isKindOf","SavageAssault")
	then return true end
end


sgs.ai_skill_invoke.nyshouying = function(self, data)
    local prompt = q(data,"toString")
    if string.find(prompt, "get") then return true end
    local neednts = {"savage_assault","god_salvation","amazing_grace","peach","ex_nihilo"}
    for _,neednt in ipairs(neednts) do
        if string.find(prompt, neednt) then return false end
    end
    if string.find(prompt, "iron_chain") and q(self.player,"isChained") then return false end
    if string.find(prompt, "nullified") then
        for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
            if q(p,"hasFlag","nyshouying") then
                return q(self,"isEnemy",p)
            end
        end
    end
    return false 
end


sgs.ai_skill_playerchosen.nyzhanyuan = function(self, targets)
    if q(self.player,"getHp") == 1 or q(self.player,"getHandcardNum") > 4 then return nil end
    for _,target in sgs.qlist(targets) do
		if q(self,"isFriend",target) and q(target,"getHp") > 2 then
			return target
		end
	end
    return nil
end

sgs.ai_playerchosen_intention.nyzhanyuan = function(self, from, to)
	q(self,"updateIntention",from, to, -200)
end


sgs.ai_skill_invoke.nyxili = function(self, data)
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"hasFlag","nyxili") then
            return q(self,"isFriend",p)
        end
    end
end


sgs.ai_fill_skill.nywuniang=function(self,inclusive,request)
    if q(self.player,"getPhase") ~= sgs.Player_NotActive then
        if q(self,"getCardsNum","Slash") > 0 then
            if q(self.player,"getJudgingArea"):length() == 0 then return end
        end
    end
    local card = eval(self,"nywuniang","slash",{})
    
    local d = q(self,"aiUseCard",card)
    save_targets(self,"nywuniang_to",d.to)
	if d.card and d.to
	and q(card,"isAvailable",self.player) 
	then return parse(self,"#nywuniang:.:") end
end

sgs.ai_skill_use_func["#nywuniang"] = function(card,use,self)
	if load_targets(self,"nywuniang_to")
	then
		use.card = card
		if use.to then use.to = load_targets(self,"nywuniang_to") end
	end
end

sgs.ai_skill_playerchosen.nywuniang = function(self, targets)
    targets = sgs.QList2Table(targets)
    q(self,"sort",targets, "defense")
    local get = false
    if q(self.player,"hasFlag","nywuniangget") then get = true end
    if not get then
        if q(self.player,"getJudgingArea"):length() > 0 and table.contains(targets, self.player) then return self.player end
        for _,target in ipairs(targets) do
            if q(self,"isEnemy",target) then return target end
        end
        return targets[math.random(1, #targets)]
    end
    for _,target in ipairs(targets) do
        if q(self,"isFriend",target) and q(target,"getJudgingArea"):length() > 0 then return target end
    end
    for _,target in ipairs(targets) do
        if q(self,"isEnemy",target) and q(target,"getEquips"):length() > 0  then return target end
    end
    for _,target in ipairs(targets) do
        if q(self,"isEnemy",target) and (not q(target,"isKongcheng")) then return target end
    end
    for _,target in ipairs(targets) do
        if not q(self,"isFriend",target) and (q(target,"getEquips"):length() > 0 or (not q(target,"isKongcheng"))) then return target end
    end
    return targets[math.random(1, #targets)]
end

sgs.ai_playerchosen_intention.nywuniang = function(self, from, to)
    if q(from,"hasFlag","nywuniangget") then
	    q(self,"updateIntention",from, to, 0)
    else
        q(self,"updateIntention",from, to, 60)
    end
end

sgs.ai_guhuo_card.nywuniang = function(self,toname,class_name)
	local player = self.player
	if class_name ~= "Slash" then return end
	local can = false
    if q(self.player,"getCards","ej"):length() > 0 then can = true end
    if q(self.player,"getPhase") == sgs.Player_NotActive then
        for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
            if q(p,"getPhase") ~= sgs.Player_NotActive then
                if q(p,"getCards","ej"):length() > 0 then can = true end
            end
        end
    end
    if can then
        return {skill="nywuniang",legacy_class="#nywuniang",subcards={}}
    end
end
 
sgs.ai_use_priority.nywuniang = sgs.ai_use_priority.Slash + 0.1


sgs.ai_skill_invoke.nyxushen = true

sgs.ai_skill_playerchosen.nyxushen = function(self, targets)
    targets = sgs.QList2Table(targets)
    q(self,"sort",targets, "defense")
    for _,target in ipairs(targets) do
        if q(self,"isFriend",target) then return target end
    end
    return nil
end

sgs.ai_playerchosen_intention.nyxushen = function(self, from, to)
    q(self,"updateIntention",from, to, -300)
end


sgs.ai_skill_playerchosen.nyzhennan = function(self, targets)
    targets = sgs.QList2Table(targets)
    if not q(self.player,"hasFlag","nyzhennan_more") then
        q(self,"sort",targets, "hp")
        for _,target in ipairs(targets) do
            if q(self,"isEnemy",target) and q(target,"getMark","&nyzhennan_damage") < q(target,"getHp") and q(target,"objectName") ~= q(self.player,"objectName") then
                return target
            end
        end
        local last = {}
        for _,target in ipairs(targets) do
            if q(self,"isEnemy",target) and q(target,"objectName") ~= q(self.player,"objectName") then
                table.insert(last, target)
            end
        end
        if #last > 0 then return last[math.random(1, #last)] end
        return nil
    else
        local card = known(tag(self,"nyzhennan_card"),"nyzhennan_card")
        if q(card,"isDamageCard") then
            q(self,"sort",targets, "defense")
            for _,target in ipairs(targets) do
                if q(self,"isEnemy",target) then
                    return target
                end
            end
            return nil
        elseif q(card,"objectName") == "peach" or q(card,"objectName") == "ex_nihilo" or q(card,"objectName") == "analeptic" then
            if q(card,"objectName") == "peach" then
                q(self,"sort",targets, "hp")
            else
                q(self,"sort",targets, "defense")
            end
            for _,target in ipairs(targets) do
                if q(self,"isFriend",target) then
                    return target
                end
            end
            return nil
        elseif q(card,"objectName") == "snatch" or q(card,"objectName") =="dismantlement" then
            q(self,"sort",targets, "defense")
            for _,target in ipairs(targets) do
                if q(self,"isFriend",target) and q(target,"getJudgingArea"):length() > 0 then
                    return target
                end
            end
            for _,target in ipairs(targets) do
                if q(self,"isEnemy",target) then
                    return target
                end
            end
        end
        local last = {}
        for _,target in ipairs(targets) do
            if q(self,"isEnemy",target) then
                table.insert(last, target)
            end
        end
        if #last > 0 then return last[math.random(1, #last)] end
        return nil
    end
end

sgs.ai_playerchosen_intention.nyzhennan = function(self, from, to)
    if not q(from,"hasFlag","nyzhennan_more") then
        q(self,"updateIntention",from, to, 60)
    else
        q(self,"updateIntention",from, to, 0)
    end
end


sgs.ai_skill_playerchosen.ny_channi = function(self, targets)
    local user
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"getPhase") == sgs.Player_Play then
            user = p
            break
        end
    end
    if not user then return nil end

    if q(self,"isFriend",user) and q(self,"isWeak",user) then return nil end
    if q(self,"isEnemy",user) then
        if q(self.player,"getHandcardNum") > 2 
        and user:getHandcardNum() < user:getHp() then return nil end
    end

    local enemys = {}
    for _,target in sgs.qlist(targets) do
        if q(self,"isEnemy",target) then
            table.insert(enemys, target)
        end
    end

    if #enemys == 0 then return nil end
    q(self,"sort",enemys, "defense")
    return enemys[1]
end

sgs.ai_skill_discard.ny_channi = function(self,max,min)
    local cards = sgs.QList2Table(q(self.player,"getCards","h"))
    q(self,"sortByCardNeed",cards)
    local user
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"getPhase") == sgs.Player_Play then
            user = p
            break
        end
    end

    local give = {}
    if user and q(self,"isFriend",user) then
        for _,card in ipairs(cards) do
            table.insert(give, q(card,"getEffectiveId"))
        end
        return give
    end
    local need = min
    for _,card in ipairs(cards) do
        table.insert(give, q(card,"getEffectiveId"))
        need = need - 1
        if need <= 0 then break end
    end
    return give
end
sgs.ai_suppress_intention["ny_channi"] = true


sgs.ai_skill_invoke.ny_xinghan = true


sgs.ai_skill_playerchosen.ny_zhenge = function(self, targets)
    local min = 999
    local target 
    for _,p in sgs.qlist(targets) do
        if q(self,"isFriend",p) and q(p,"getMark","&ny_zhenge") < min then
            min = q(p,"getMark","&ny_zhenge")
            target = p
        end
    end
    if min >= 3 then
        q(self,"sort",self.friends, "handcard")
        return self.friends[1]
    else
        return target
    end
end

sgs.ai_skill_use["@@ny_zhenge"] = function(self, prompt)
    local slash = eval(self,"ny_zhenge","slash",{})
    

    local usec = {isDummy=true,to=sgs.SPlayerList()}
    q(self,"useCardByClassName",slash, usec)
    if usec.card then
        local tos = {}
        for _,to in sgs.qlist(usec.to) do
            table.insert(tos, q(to,"objectName"))
        end
        return answer(self,slash,tos)
    end
    return "."
end


sgs.ai_skill_invoke.ny_qiaoshi = function(self, data)
    local damage = known(tag(self,"ny_qiaoshi"),"ny_qiaoshi")
    if damage.damage > 1 then return true end
    if damage.from and q(self,"isFriend",damage.from) then return true end
    return q(self,"isWeak")
end

sgs.ai_skill_use["@@ny_qiaoshi"] = function(self, prompt)
    if q(self.player,"hasFlag","ny_qiaoshi_get") then
        local ids = known(tag(self,"ny_qiaoshi_cards"),"ny_qiaoshi_cards")
        local cards = {}
        for _,id in sgs.qlist(ids) do
            local card = face(self,id)
            table.insert(cards, card)
        end
        q(self,"sortByCardNeed",cards, true)
        local get = {}
        for _,card in ipairs(cards) do
            table.insert(get, q(card,"getEffectiveId"))
            if #get >= 2 then break end
        end
        if #get > 0 then
            return respond(self,string.format("#ny_qiaoshi:%s:",table.concat(get,"+")))
        end
        return "."
    else
        for _,card in sgs.qlist(q(self.player,"getHandcards")) do
            if q(card,"hasFlag","ny_qiaoshi") and q(card,"isAvailable",self.player) then
                local use = q(self,"aiUseCard",card)
                if use.card then
                    local tos = {}
                    for _,p in sgs.qlist(use.to) do
                        table.insert(tos, q(p,"objectName"))
                    end
                    return answer(self,card,tos)
                end
            end
        end
        return "."
    end
end


sgs.ai_fill_skill.ny_yanyu=function(self,inclusive,request)
    for _,card in sgs.qlist(q(self.player,"getHandcards")) do
        if q(card,"isKindOf","Slash") then
            local card_str = "#ny_yanyu:"..card:getEffectiveId()..":"
            return parse(self,card_str)
        end
    end
end

sgs.ai_skill_use_func["#ny_yanyu"] = function(card,use,self)
	use.card = card
    if #self.friends_noself > 0 then
        q(self,"sort",self.friends_noself, "defense")
        if use.to then use.to:append(self.friends_noself[1]) end
    end
end


sgs.ai_skill_invoke.ny_aichen = true

sgs.ai_skill_discard.ny_aichen = function(self,max,min)
    if (q(self.player,"getMark","ny_aichen-Clear") == 0) or (q(self.player,"getHandcardNum") > q(self.player,"getMaxCards")) then
        local cards = sgs.QList2Table(q(self.player,"getHandcards"))
        if #cards > 0 then
            q(self,"sortByKeepValue",cards)
            return {cards[1]:getEffectiveId()}
        end
    end
    return {}
end


sgs.ai_skill_invoke.ny_luochong = true

local function ny_luochong_judge(player)
    if q(player,"isDead") then return false end
    if not q(player,"isAllNude") then return true end
    for _,p in sgs.qlist(q(player,"getAliveSiblings")) do
        if not q(p,"isAllNude") then return true end
    end
    return false
end

sgs.ai_fill_skill.ny_luochong=function(self,inclusive,request)
    if q(self.player,"hasUsed","#ny_luochong") then return end
    if (not ny_luochong_judge(self.player)) then return end
    return parse(self,"#ny_luochong:.:")
end

sgs.ai_skill_use_func["#ny_luochong"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.ny_luochong = 6

sgs.ai_skill_playerchosen.ny_luochong = function(self, targets)
    if #self.friends > 0 then
        q(self,"sort",self.friends, "defense")
        for _,friend in ipairs (self.friends) do
            if (not q(friend,"getJudgingArea"):isEmpty()) then return friend end
        end
    end

    local now = q(self.room,"getCurrent")
    if q(self,"isEnemy",now) and (not q(now,"isNude")) and (math.random(1,2) == 1) then return now end

    local enemys = {}
    for _,target in sgs.qlist(targets) do
        if not q(self,"isFriend",target) then
            table.insert(enemys, target)
        end
    end
    if #enemys > 0 then
        q(self,"sort",enemys, "defense")
        for _,enemy in ipairs(enemys) do
            if not q(enemy,"isNude") then return enemy end
        end
    end

    if q(self.player,"hasSkill","ny_aichen") and q(self.player,"getMark","ny_aichen-Clear") == 0
    and (not q(self.player,"isAllNude")) then return self.player end
    
    return nil
end


sgs.ai_skill_invoke.nyarz_guili = true

sgs.ai_skill_playerchosen.nyarz_guili = function(self, targets)
    if #self.friends_noself <= 0 then return nil end
    q(self,"sort",self.friends_noself, "handcard", true)
    for _,friend in ipairs(self.friends_noself) do
        if (not q(friend,"containsTrick","indulgence")) then return friend end
    end
    return self.friends_noself[#self.friends_noself]
end


sgs.ai_skill_use["@@nyarz_caiyi"] = function(self, prompt)
    local suits = {}
    for _,card in sgs.qlist(q(self.player,"getHandcards")) do
        local suit = q(card,"getSuitString")
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
        if (q(self.player,"getHandcardNum") - i) < (2 * i) then
            value = (2 * i) - (q(self.player,"getHandcardNum") - i) - i
        elseif  (q(self.player,"getHandcardNum") - i) > (2 * i) then
            value = 0 - (q(self.player,"getHandcardNum") - 2*i) + (2 * i)
            for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
                if q(self,"isEnemy",p) and (q(p,"getCardCount") < 2 * i) and (q(p,"getHp") <= i) and (value > -2) then
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
    local cards = sgs.QList2Table(q(self.player,"getHandcards"))
    q(self,"sortByKeepValue",cards)
    for _,card in ipairs(cards) do
        local suit = q(card,"getSuitString")
        if not table.contains(suits, suit) then
            table.insert(suits, suit)
            table.insert(need, q(card,"getEffectiveId"))
            dis = dis - 1
        end
        if dis <= 0 then break end
    end
    if #need <= 0 then return "." end
    return respond(self,string.format("#nyarz_caiyi:%s:", table.concat(need, "+")))
end

sgs.ai_skill_playerchosen.nyarz_caiyi = function(self, targets)
    local all = sgs.QList2Table(q(self.room,"getAlivePlayers"))
    q(self,"sort",all, "denfense")
    local num = q(self.player,"getMark","nyarz_caiyi_ai-Clear")
    for _,p in ipairs(all) do
        if q(self,"isEnemy",p) and (q(p,"getCardCount") < 2 * num) and (q(p,"getHp") <= 2 * num) then return p end
    end
    for _,p in ipairs(all) do
        if q(self,"isFriend",p) and q(self,"isWeak",p) then return p end
    end
    return all[1]
end

sgs.ai_skill_choice["nyarz_caiyi"] = function(self, choices, data)
    local items = choices:split("+")
    if string.find(choices, "good") then
        local target = q(data,"toPlayer")
        if q(self,"isFriend",target) then
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
        if not q(self.player,"isWounded") then
            for _,item in ipairs(items) do
                if string.find(item, "draw") then
                    return item
                end
            end
        else
            if q(self.player,"getHp") == 1 then
                for _,item in ipairs(items) do
                    if string.find(item, "recover") then
                        return item
                    end
                end
            end
            local re = math.min(q(self.player,"getLostHp"),q(self.player,"getMark","nyarz_caiyi_ai-Clear"))
            re = re * 2
            if re >= q(self.player,"getMark","nyarz_caiyi_ai-Clear") * 2 then
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


sgs.ai_skill_invoke.nyarz_xiaoyong = function(self, data)
    local prompt = q(data,"toString")
    local num = tonumber(prompt:split(":")[2])
    if q(self.player,"getPhase") ~= sgs.Player_Play then return true end
    return num > 1
end


sgs.ai_fill_skill.nyarz_guangu=function(self,inclusive,request)
    if q(self.player,"getMark","&nyarz_guangu") > 0 then return end
    return parse(self,"#nyarz_guangu:.:")
end

sgs.ai_skill_use_func["#nyarz_guangu"] = function(card,use,self)
    local all = sgs.QList2Table(q(self.room,"getOtherPlayers",self.player))
    q(self,"sort",all, "defense")
    local touse = {"useBasicCard","useTrickCard","useEquipCard"}
    for _,p in ipairs(all) do
        if (not q(self,"isFriend",p)) and (not q(p,"isKongcheng")) then
            local cards = sgs.QList2Table(complete_hand(self,p))
            q(self,"sortByUseValue",cards)
            local max = q(p,"getHandcardNum")
            for _,cc in ipairs(cards) do
                local num = q(cc,"nameLength")
                if q(cc,"isKindOf","Slash") then num = 1 end
                if num > 4 or num > max then continue end

                local usec = {isDummy=true,to=sgs.SPlayerList()}
			    q(self,touse[q(cc,"getTypeId")],cc,usec)
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
            local num = q(cc,"nameLength")
            if q(cc,"isKindOf","Slash") then num = 1 end
            if num == i then
                table.insert(cards, cc)
            end
        end
        if #cards > 0 then
            q(self,"sortByUseValue",cards)
            for _,cc in ipairs(cards) do
                local usec = {isDummy=true,to=sgs.SPlayerList()}
			    q(self,touse[q(cc,"getTypeId")],cc,usec)
                if usec.card then
                    use.card = card
                    return 
                end
            end
        end
    end

    if q(self.player,"getPhase") ~= sgs.Player_Play then return end

    for _,cc in sgs.qlist(q(self.player,"getHandcards")) do
        local num = q(cc,"nameLength")
        if q(cc,"isKindOf","Slash") then num = 1 end
        if num > 4 then continue end

        local usec = {isDummy=true,to=sgs.SPlayerList()}
        q(self,touse[q(cc,"getTypeId")],cc,usec)
        if usec.card then
            use.card = card
            return 
        end
    end
end

sgs.ai_use_priority.nyarz_guangu = 8
sgs.ai_use_value.nyarz_guangu = 8

sgs.ai_skill_choice.nyarz_guangu = function(self, choices)
    local target=tag(self,"nyarz_guangu")
    local tag=true
    local touse = {"useBasicCard","useTrickCard","useEquipCard"}
    if (not tag) or (not target) then
        if q(self.player,"getHp") == 1 and q(self.player,"isWounded")
        and q(self.player,"getPhase") ~= sgs.Player_Play then
            local card = face(self,draw_id(self,0))
            if q(card,"isKindOf","Peach") then return tostring(1) end
            return tostring(4)
        end
        local max = math.min(4, draw_count(self))
        if max <= 0 then return end
    
        for i = 1, max, 1 do
            local cards = {}
            for j = 0, i - 1, 1 do
                local cc = face(self,draw_id(self,j))
                local num = q(cc,"nameLength")
                if q(cc,"isKindOf","Slash") then num = 1 end
                if num == i then
                    table.insert(cards, cc)
                end
            end
            if #cards > 0 then
                q(self,"sortByUseValue",cards)
                for _,cc in ipairs(cards) do
                    local usec = {isDummy=true,to=sgs.SPlayerList()}
                    q(self,touse[q(cc,"getTypeId")],cc,usec)
                    if usec.card then
                        return tostring(i)
                    end
                end
            end
        end
    else
        if q(self.player,"getHp") == 1 and q(self.player,"isWounded")
        and q(self.player,"getPhase") ~= sgs.Player_Play then
            for _,card in sgs.qlist(complete_hand(self,target)) do
                if q(card,"isKindOf","Peach") then return tostring(1) end
            end
        end

        local cards = sgs.QList2Table(complete_hand(self,target))
        q(self,"sortByUseValue",cards)
        local max = q(target,"getHandcardNum")
        for _,cc in ipairs(cards) do
            local num = q(cc,"nameLength")
            if q(cc,"isKindOf","Slash") then num = 1 end
            if num > 4 or num > max then continue end

            local usec = {isDummy=true,to=sgs.SPlayerList()}
            q(self,touse[q(cc,"getTypeId")],cc,usec)
            if usec.card then
                return tostring(num)
            end
        end
    end
    if q(self.player,"getPhase") ~= sgs.Player_Play then return "1" end
    local items = choices:split("+")
    local max = #items

    for _,cc in sgs.qlist(q(self.player,"getHandcards")) do
        local num = q(cc,"nameLength")
        if q(cc,"isKindOf","Slash") then num = 1 end
        if num > 4 then continue end

        local usec = {isDummy=true,to=sgs.SPlayerList()}
        q(self,touse[q(cc,"getTypeId")],cc,usec)
        if usec.card and num <= max then
            return tostring(num)
        end
    end
    return tostring(max)
end

sgs.ai_skill_use["@@nyarz_guangu"] = function(self, prompt)
    local touse = {"useBasicCard","useTrickCard","useEquipCard"}
    if (not q(self.player,"hasFlag","nyarz_guangu")) then
        if q(self.player,"getPhase") ~= sgs.Player_Play
        and q(self.player,"getHp") == 1 and q(self.player,"isWounded") then
            for _,p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
                if (not q(self,"isFriend",p)) and (not q(p,"isKongcheng")) then
                    for _,card in sgs.qlist(complete_hand(self,p)) do
                        if q(card,"isKindOf","Peach") then
                            return respond(self,"#nyarz_guangu:.:->"..p:objectName())
                        end
                    end
                end
            end
            for _,p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
                if (q(self,"isFriend",p)) and (not q(p,"isKongcheng")) and (not q(self,"isWeak",p)) then
                    for _,card in sgs.qlist(complete_hand(self,p)) do
                        if q(card,"isKindOf","Peach") then
                            return respond(self,"#nyarz_guangu:.:->"..p:objectName())
                        end
                    end
                end
            end
            local max = 4
            for _,id in draw_top(self,max) do
                local card = face(self,id)
                if q(card,"isKindOf","Peach") then 
                    return respond(self,"#nyarz_guangu:.:") 
                end
                max = max - 1
                if max <= 0 then break end
            end
        end

        local card = parse(self,"#nyarz_guangu:.:")
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        q(self,"useSkillCard",card,usec)
        if usec.card then
            if usec.to and (not usec.to:isEmpty()) then 
                return respond(self,"#nyarz_guangu:.:->"..usec.to:at(0):objectName()) 
            end
            return respond(self,"#nyarz_guangu:.:")
        end
    else
        local target=tag(self,"nyarz_guangu")
        local tag=true
        local num = q(self.player,"getMark","&nyarz_guangu")
        if (not tag) or (not target) then
            if q(self.player,"getPhase") ~= sgs.Player_Play
            and q(self.player,"getHp") == 1 and q(self.player,"isWounded") then
                local max = num
                for _,id in draw_top(self,max) do
                    local card = face(self,id)
                    if q(card,"isKindOf","Peach") then
                        return respond(self,"#nyarz_guangu_use:"..card:getEffectiveId()..":")
                    end
                    max = max - 1
                    if max <= 0 then break end
                end
            end
            local max = num
            for _,id in draw_top(self,max) do
                local cc = face(self,id)
                local namenum = q(cc,"nameLength")
                if q(cc,"isKindOf","Slash") then namenum = 1 end
                if namenum == num then
                    local usec = {isDummy=true,to=sgs.SPlayerList()}
                    q(self,touse[q(cc,"getTypeId")],cc,usec)
                    if usec.card then
                        if q(cc,"targetFixed") then 
                            return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":") 
                        end
                        local tos = {}
                        for _,to in sgs.qlist(usec.to) do
                            table.insert(tos, q(to,"objectName"))
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
            q(self,"sortByUseValue",cards)
            for _,cc in ipairs(cards) do
                local usec = {isDummy=true,to=sgs.SPlayerList()}
                q(self,touse[q(cc,"getTypeId")],cc,usec)
                if usec.card then
                    if q(cc,"targetFixed") then 
                        return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":") 
                    end
                    local tos = {}
                    for _,to in sgs.qlist(usec.to) do
                        table.insert(tos, q(to,"objectName"))
                    end
                    return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":->"..table.concat(tos, "+"))
                end
            end
        else
            if q(self.player,"getPhase") ~= sgs.Player_Play
            and q(self.player,"getHp") == 1 and q(self.player,"isWounded") then
                for _,card in sgs.qlist(complete_hand(self,target)) do
                    if q(card,"isKindOf","Peach") then
                        return respond(self,"#nyarz_guangu_use:"..card:getEffectiveId()..":")
                    end
                end
            end
            local cards = sgs.QList2Table(complete_hand(self,target))
            q(self,"sortByUseValue",cards)
            for _,cc in ipairs(cards) do
                local namenum = q(cc,"nameLength")
                if q(cc,"isKindOf","Slash") then namenum = 1 end
                if namenum == num then
                    local usec = {isDummy=true,to=sgs.SPlayerList()}
                    q(self,touse[q(cc,"getTypeId")],cc,usec)
                    if usec.card then
                        if q(cc,"targetFixed") then 
                            return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":") 
                        end
                        local tos = {}
                        for _,to in sgs.qlist(usec.to) do
                            table.insert(tos, q(to,"objectName"))
                        end
                        return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":->"..table.concat(tos, "+"))
                    end
                end
            end
            for _,cc in ipairs(cards) do
                local usec = {isDummy=true,to=sgs.SPlayerList()}
                q(self,touse[q(cc,"getTypeId")],cc,usec)
                if usec.card then
                    if q(cc,"targetFixed") then 
                        return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":") 
                    end
                    local tos = {}
                    for _,to in sgs.qlist(usec.to) do
                        table.insert(tos, q(to,"objectName"))
                    end
                    return respond(self,"#nyarz_guangu_use:"..cc:getEffectiveId()..":->"..table.concat(tos, "+"))
                end
            end
        end
    end
end


sgs.ai_skill_playerchosen.nyarz_lingren = function(self, targets)
    local all = sgs.QList2Table(targets)
    q(self,"sort",all, "defense")
    for _,to in ipairs(all) do
        if (not q(self,"isFriend",to)) then return to end
    end
    return nil
end

sgs.ai_ajustdamage_from.nyarz_lingren = function(self, from, to, card, nature)
	if card and q(card,"hasFlag","nyarz_lingren+"..to:objectName())
	then
		return 1
	end
end


sgs.ai_skill_playerchosen.nyarz_lingxi = function(self, targets)
    if #self.enemies == 0 then return nil end
    q(self,"sort",self.enemies, "defense")
    return self.enemies[1]
end

sgs.ai_playerchosen_intention.nyarz_lingxi = 40

sgs.ai_skill_invoke.nyarz_lingxi = function(self, data)
    local use = known(tag(self,"nyarz_lingxi_use"),"nyarz_lingxi_use")
    if use.card:isKindOf("EquipCard") then return false end
    local all = sgs.IntList()
    for _,id in sgs.qlist(q(self.player,"getPile","nyarz_lingxi_yi")) do
        all:append(id)
    end
    if (use.card:getSkillName() ~= "") then
        for _,id in sgs.qlist(use.card:getSubcards()) do
            if q(self.room,"getCardPlace",id) ~= sgs.Player_PlaceHand then
                all:append(id)
            end
        end
    else
        if q(self.room,"getCardPlace",use.card:getEffectiveId()) ~= sgs.Player_PlaceHand then
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
    return ((2*(#suits)) + 2) >= q(self.player,"getHandcardNum")
end


sgs.ai_cardsview_valuable.nyarz_zhifou = function(self, class_name, player)
	if q(self.player,"isKongcheng") or (q(self.player,"getMark","nyarz_zhifou-Clear") > 0) then return end
	if class_name ~= "Peach" then return end
    for _,card in sgs.qlist(q(self.player,"getHandcards")) do
        if q(card,"isKindOf",class_name) and (q(self.player,"getHandcardNum") > 1) then return end
    end
	return {skill="nyarz_zhifou",legacy_class="#nyarz_zhifou",subcards={}}
end

sgs.ai_fill_skill.nyarz_zhifou=function(self,inclusive,request)
    if q(self.player,"isKongcheng") or (q(self.player,"getMark","nyarz_zhifou-Clear") > 0) then return end
    local pattern = "peach"
    if q(self.player,"getHandcardNum") > 1 then
        for _,card in sgs.qlist(q(self.player,"getHandcards")) do
            if q(card,"objectName") == pattern then return end
        end
    end
    local card = eval(self,"nyarz_zhifou",pattern,{})
    
    if (not q(card,"isAvailable",self.player)) then return end

    local use = {isDummy=true,to=sgs.SPlayerList()}

    q(self,"useBasicCard",card,use)
    if use.card then
        save_targets(self,"nyarz_zhifou_to",use.to)
        return parse(self,"#nyarz_zhifou:.:")
    end
end

sgs.ai_skill_use_func["#nyarz_zhifou"] = function(card, use, self)
    use.card = card
    if use.to then use.to = load_targets(self,"nyarz_zhifou_to") end
end

-- audited alias ai_use_priority.nyarz_zhifou
sgs.ai_skill_invoke.nyarz_zhifou = function(self, data)
    local target = q(data,"toPlayer")
    return target and q(self,"isFriend",target)
end


sgs.ai_skill_invoke.nyarz_xialei = true

sgs.ai_hasTuntianEffect_skill.nyarz_xialei = function(to, need_zaoxian)
	return q(to,"getMark","nyarz_xialei-Clear") == 0
end


sgs.ai_fill_skill.nyarz_anzhi=function(self,inclusive,request)
    if q(self.player,"getMark","nyarz_anzhi_disable-Clear") > 0 then return end
    return parse(self,"#nyarz_anzhi:.:")
end

sgs.ai_skill_use_func["#nyarz_anzhi"] = function(card, use, self)
    use.card = card
end

sgs.ai_skill_use["@@nyarz_anzhi"] = function(self, prompt)
    if q(self.player,"getMark","nyarz_anzhi") == 0 then return respond(self,"#nyarz_anzhi:.:") end
    if q(self.player,"getMark","nyarz_anzhi") == 1 then
        local dis = {}
        local min = math.max(0, draw_count(self) - 3)
        local need = true
        for i = min, draw_count(self) - 1, 1 do
            local id = draw_id(self,i)
            local card = face(self,id)
            local mark = string.format("@nyarz_anzhi_%s-Clear", q(card,"getSuitString"))
            if q(self.player,"getMark",mark) > 0 then
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
    if q(self.player,"getMark","nyarz_anzhi") == 2 then
        local ids = tag(self,"nyarz_anzhi")
        if (not ids) or (ids:isEmpty()) then return end
        local cards = {}
        for _,id in sgs.qlist(ids) do
            if q(self.room,"getCardPlace",id) == sgs.Player_DiscardPile then
                table.insert(cards, face(self,id))
            end
        end
        if #cards <= 0 then return end
        if q(self.player,"getPhase") == sgs.Player_Play then
            q(self,"sortByUseValue",cards)
            for i = 1, #cards, 1 do
                if (not cards[i]:isKindOf("EquipCard")) then
                    return respond(self,"#nyarz_anzhi_give:"..cards[i]:getEffectiveId()..":->"..self.player:objectName())
                end
            end
            return respond(self,"#nyarz_anzhi_give:"..cards[1]:getEffectiveId()..":->"..self.player:objectName())
        else
            q(self,"sortByKeepValue",cards)
            q(self,"sort",self.friends, "defense")
            return respond(self,"#nyarz_anzhi_give:"..cards[1]:getEffectiveId()..":->"..self.friends[1]:objectName())
        end
    end
end


sgs.ai_skill_invoke.nyarz_fuxve = true


sgs.ai_skill_use["@@nyarz_yaoyi"] = function(self, prompt)
    if q(self.player,"isKongcheng") then return end
    local cards = sgs.QList2Table(q(self.player,"getHandcards"))
    q(self,"sortByUseValue",cards)
    local types = {"BasicCard","TrickCard","EquipCard"}
    for _,card in ipairs(cards) do
        if q(card,"isAvailable",self.player) then
            local dummy = {isDummy=true,to=sgs.SPlayerList()}
			q(self,"use"..types[q(card,"getTypeId")],card,dummy)
            if dummy.card and dummy.to then
                local tos = {}
                for _,to in sgs.qlist(dummy.to) do
                    table.insert(tos, q(to,"objectName"))
                end
                return answer(self,card,tos)
            end
        end
    end
end

sgs.ai_skill_playerchosen.nyarz_yaoyi = function(self, targets)
    if #self.friends_noself == 0 then
        local tos = sgs.QList2Table(targets)
        q(self,"sort",tos, "handcard")
        return tos[1]
    end
    q(self,"sort",self.friends_noself, "handcard", true)
    if math.random(1,3) == 1 then
        for _,to in ipairs(self.friends_noself) do
            for _,hand in sgs.qlist(complete_hand(self,to)) do
                if q(hand,"isAvailable",to) then return to end
            end
        end
    end
    return self.friends_noself[1]
end

sgs.ai_fill_skill.nyarz_yaoyi=function(self,inclusive,request)
    if q(self.player,"getMark","nyarz_yaoyi_failed-PlayClear") == 0 then 
        return parse(self,"#nyarz_yaoyi:.:")
    else
        local cards = sgs.QList2Table(q(self.player,"getHandcards"))
        q(self,"sortByUseValue",cards)
        local types = {"BasicCard","TrickCard","EquipCard"}
        for _,card in ipairs(cards) do
            if q(card,"isAvailable",self.player) then
                local dummy = {isDummy=true,to=sgs.SPlayerList()}
                q(self,"use"..types[q(card,"getTypeId")],card,dummy)
                if dummy.card and dummy.to then
                    return parse(self,"#nyarz_yaoyi:.:")
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

ai_audited_aliases.register({id="ai_cardneed.nyguose",registry="ai_cardneed",path={"nyguose"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.nyxuechang",registry="ai_cardneed",path={"nyxuechang"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_use_priority.nyarz_zhifou",registry="ai_use_priority",path={"nyarz_zhifou"},canonical_registry="ai_use_priority",canonical_path={"Peach"},self_index=3,defer_canonical=true})
