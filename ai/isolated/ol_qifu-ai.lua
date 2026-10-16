-- ol_qifu, fixed b6025acc. Only effective live registries are installed.
-- Shadow Aocai invoke/AG and Duwu bodies belong to the effective source owner.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported('ol_qifu input unavailable',k)end;return v end
local nullable={recordAocaiSourceDrawIdentity=true,toPlayer=true,getStrategyMemory=true,getCurrentDyingPlayer=true,getCurrent=true,getArmor=true,getWeapon=true,getOffensiveHorse=true,getDefensiveHorse=true,findPlayerBySkillName=true,getCardNeedPlayer=true,aiUseCard=true,updateIntention=true,setStrategyCardFlag=true,setStrategyPlayerFlag=true,setStrategyMemory=true}

-- The viewer's own property and tag, read like the donor's toString()/toIntList() (absent reads empty).
local function property(self,key)local v=self.player:getPropertyValue(key);if v==nil then return''end;return v end
local function tag_ids(self,key)return AIList.new(self.player:getTag(key)or{})end
local function public_flag(self,p,key)
 if key:sub(1,12)=='weapon_done_'then return self:hasStrategyPlayerFlag(p, key)end
 return p:hasFlag(key)
end
local function callback(self,registry,key,...)
 local hooks=self:getHooks(registry);local f=hooks[key]
 if f==nil then ai_unsupported('required shared callback unavailable',registry..'.'..key)end
 local r=table.pack(f(...));if AIUnsupported.is(r[1])then error(r[1],0)end;return table.unpack(r,1,r.n)
end
local function need_callback(self,key)
 if not self:hasSourceCardNeed(key)then return nil end
 local f=self:getHooks('ai_cardneed')[key]
 if type(f)~='function'then ai_unsupported('OlRende cardneed policy not ported',key)end
 return function(...)local v=f(...);if AIUnsupported.is(v)then error(v,0)end;return v end
end
local function evaluation(self,name)return self:getEvaluationCard(name or 'slash')end
local function declared(self,skill,name,costs)
 if skill=='xufa'then return self:evaluateXufaSourceCard(name, costs)end
 return self:evaluateSkillCard(skill, name, costs)
end
local function skill_seed(self,skill,name,costs)
 if skill=="xufa"and name=="XufaCard"then return self:evaluateXufaFirst(costs)end
 if costs then return self:evaluateTurnSkillCard(skill, name, costs, self.request)end
 return self:legacySkillSeed(skill, name, self.request)
end
local function answer(self,card,tos)
 local names={};for _,p in ipairs(tos or{})do names[#names+1]=type(p)=='string'and p or p:objectName()end
 if AIValue.isCard(card) and card:isEvaluationOnly()then
  local skill=card:getKnownSkillName(false)
  if skill~='Omozhi'and skill~='mozhi'and skill~='xufa'then ai_unsupported('unexpected selected readonly provider',skill)end
  local authority=self:bindSkillCard(skill, card:getSubcards(), self.request, card:objectName())
  if authority:objectName()~=card:objectName()or authority:getSuit()~=card:getSuit()or authority:getNumber()~=card:getNumber()or authority:getKnownSkillName(false)~=skill then ai_unsupported('selected declared receipt changes source product',skill)end
  local a,b=authority:getSubcards(),card:getSubcards();if #a~=#b then ai_unsupported('selected declared receipt changes costs',skill)end
  for i,id in ipairs(a)do if id~=b[i]then ai_unsupported('selected declared receipt reorders costs',skill)end end
  card=authority
 end
 if AIValue.isConversion(card)then return{kind='use_card',card_spec=card:toCardSpec(),targets=names}end
 if card:isVirtualCard()then ai_unsupported('selected virtual product has no authority','ol_qifu.response')end
 return{kind='use_card',card_ids={card:getKnownEffectiveId()},targets=names}
end
local function paid(self,skill,cls,ids,tos)
 local c=self:bindSkillCard(skill, ids, self.request, nil, cls)
 return answer(self,c,tos)
end
local function source_choice_continuity(self,op,key,row)
 -- Gameplay-VM registry choices, also written by its SmartAI, are not readable or writable here.
 ai_unsupported('gameplay SmartAI choice registry is not available',key)
end
local function save_xufa(self,d,name)
 self:rememberXufaUse(d) -- source assignment precedes the choice write
 self:setStrategyMemory('xufa.choice', name)
end
local function load_xufa(self)
 -- nil/false is a legal host result but the donor then indexes it: retain that ordinary error.
 return self:getStrategyMemory('xufa.use')
end
local function fengpo_from(self)
 -- The donor reads a free global `from` of the gameplay VM, which is not projected.
 ai_unsupported('source global from is not classified','fengpo.from')
end


sgs.ai_fill_skill.aocai = function(self)
	if not self:aocaiSourceDrawIdentityMatches() then return skill_seed(self,"aocai","AocaiCard") end
end

sgs.ai_skill_use_func["AocaiCard"] = function(card,use,self)
	use.card = card
	self:recordAocaiSourceDrawIdentity()
end

sgs.ai_guhuo_card.aocai = function(self,toname,class_name)
    return {skill="aocai",legacy_class="AocaiCard",subcards={},user_string=toname}
end

sgs.ai_skill_use["@@aocai"] = function(self,prompt)
    local c = self.player:getStrategyMark("aocaiId")
	c = self:getKnownCardById(c)
    local dummy = self:aiUseCard(c)
   	if dummy.card then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
            table.insert(tos,p:objectName())
       	end
       	return answer(self,c,tos)
    end
end

sgs.ai_skill_invoke.olpojun = function(self,data)
	local target = data:toPlayer()
	if target then
		return not self:isFriend(target)
	end
end

sgs.ai_use_revises.olpojun = function(self,card,use)
	if card:isKindOf("Slash") then
		self:setStrategyCardFlag(card, "Qinggang", true)
	end
end

sgs.ai_skill_invoke.lixia = function(self,data)
    return true
end

sgs.ai_skill_invoke.biluan = function(self,data)
    return self.player:getHandcardNum()>3 and #self:getTurnUse()>2
end

sgs.ai_skill_choice.mobilemiji_draw = function(self,choices)
    return ""..self.player:getLostHp()
end

sgs.ai_skill_invoke.mobilemiji = function(self,data)
    if #self.friends==0 then return false end
    for _,friend in ipairs(self.friends)do
        if not friend:hasSkill("manjuan") and not self:isLihunTarget(friend) then return true end
    end
    return false
end

sgs.ai_skill_askforyiji.mobilemiji = function(self,card_ids)
    local available_friends = {}
    for _,friend in ipairs(self.friends)do
        if not friend:hasSkill("manjuan") and not self:isLihunTarget(friend) then table.insert(available_friends,friend) end
    end
    local toGive,allcards = {},{}
    local keep
    for _,id in ipairs(card_ids)do
        local card = self:getKnownCardById(id)
        if not keep and (isCard("Jink",card,self.player) or isCard("Analeptic",card,self.player)) then
            keep = true
        else
            table.insert(toGive,card)
        end
        table.insert(allcards,card)
    end
    local cards = #toGive>0 and toGive or allcards
    self:sortByKeepValueInPlace(cards, true)
    local id = cards[1]:getKnownId()
    local card,friend = self:getCardNeedPlayer(cards, true)
    if card and friend and table.contains(available_friends,friend) then 
        if friend:objectName()==self.player:objectName() then
            return nil,-1
        else
            return friend,card:getKnownId()
        end
    end
    if #available_friends>0 then
        self:sortInPlace(available_friends, "handcard")
        for _,afriend in ipairs(available_friends)do
            if not self:needKongcheng(afriend, true) then
                if afriend:objectName()==self.player:objectName() then
                    return nil,-1
                else
                    return afriend,id
                end
            end
        end
        self:sortInPlace(available_friends, "defense")
        if available_friends[1]:objectName()==self.player:objectName() then
            return nil,-1
        else
            return available_friends[1],id
        end
    end
    return nil,-1
end

sgs.ai_skill_use["@@bushi"] = function(self,prompt,method)
    local zhanglu = self.room:findPlayerBySkillName("bushi")
    if not zhanglu then return "." end
    local ids = zhanglu:getPile("rice")
    if self:isEnemy(zhanglu) and ids:length()==1 and zhanglu:isWounded() then return "." end
    if self:isFriend(zhanglu) then
		local damage = known(self:getDecisionContext().damage,"CurrentDamageStruct")
		if damage.damage<ids:length() and self:getOverflow()>1 or not zhanglu:isWounded() then
			return "."
		end
	end
    local cards = {}
    for _,id in sgs.list(ids)do
        table.insert(cards,self:getKnownCardById(id))
    end
    self:sortByUseValueInPlace(cards, true)
    return paid(self,"bushi","BushiCard",{cards[1]:getKnownEffectiveId()})
end    

sgs.ai_skill_use["@@midao"] = function(self,prompt,method)
    local judge = self:getJudge()
    local ids = self.player:getPile("rice")
    if self.room:getMode():find("_mini_46") and not judge:isGood() then return paid(self,"midao","MidaoCard",{ids:first()}) end
    local cards = {}
    for _,id in sgs.list(ids)do
        table.insert(cards,self:getKnownCardById(id))
    end
    if self:needRetrial(judge) then
        local id = self:getRetrialCardId(cards, judge)
        if id~=-1 then return paid(self,"midao","MidaoCard",{id}) end
    end
	if self:isWeak() and #cards<2
	and self.player:getLostHp()>0
	then
        local id = self:getRetrialCardId(cards, judge, nil, true)
        if id~=-1 then return paid(self,"midao","MidaoCard",{id}) end
	end
    return "."    
end

sgs.ai_skill_defense.yishe = 2

sgs.ai_skill_invoke["olmeibu2"] = function(self,data)
    local target = self.room:getCurrent()
	return self:isEnemy(target)
	and (self:getCardsNum("Jink")>0 or not self:isWeak())
end


sgs.ai_fill_skill.olanxu = function(self,inclusive,request)
 if self.room:alivePlayerCount()>2 then return skill_seed(self,"olanxu","OlAnxuCard") end
end
sgs.ai_skill_use_func["OlAnxuCard"] = function(card,use,self)
    local tos = self.room:getOtherPlayers(self.player)
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if to1:getHandcardNum()<to2:getHandcardNum()
			and self:isFriend(to1) and self:isEnemy(to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if to1:getHandcardNum()<to2:getHandcardNum()
			and self:isFriend(to1) and not self:isFriend(to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if to1:getHandcardNum()<to2:getHandcardNum()
			and not self:isEnemy(to1) and self:isEnemy(to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if to1:getHandcardNum()<to2:getHandcardNum()
			and not self:isEnemy(to1) and not self:isFriend(to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if to1:getHandcardNum()<to2:getHandcardNum()
			and self:isFriend(to1) and self:isFriend(to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if to1:getHandcardNum()<to2:getHandcardNum()
			and not self:isEnemy(to1) and not self:isEnemy(to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
end

sgs.ai_skill_discard["olanxu"] = function(self,discard_num,min_num,optional,include_equip,pattern)
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if public_flag(self,p,"olanxu_target") and self:isFriend(p)
		and not self:hasManjuanEffect(p)
		then
			local handcards = self.player:getHandcards()
			handcards = self:sortByUseValueInPlace(handcards)
			return {handcards[1]:getEffectiveId()}
		end
    end
    return self:askForDiscard("dummy", discard_num, min_num, optional, include_equip, pattern)
end

sgs.ai_skill_choice["olanxu"] = function(self,choices,data)
    local items = choices:split("+")
    if #items==1 then
        return items[1]
    end
    return "recover"
end



sgs.ai_skill_playerchosen["olchenqing"] = function(self,targets)
    local victim = self.room:getCurrentDyingPlayer()
    local help = false
    local careLord = false
    if victim then
        if self:isFriend(victim) then
            help = true
        elseif self.player:getKnownRole()=="renegade" and victim:isLord() and self.room:alivePlayerCount()>2 then
            help = true
            careLord = true
        end
    end
    local friends,enemies = {},{}
    for _,p in sgs.list(targets)do
        if self:isFriend(p) then
            table.insert(friends,p)
        else
            table.insert(enemies,p)
        end
    end
    local compare_func = function(a,b)
        local nA = a:getCardCount(true)
        local nB = b:getCardCount(true)
        if nA==nB then
            return a:getHandcardNum()>b:getHandcardNum()
        else
            return nA>nB
        end
    end
    if help and #friends>0 then
        table.sort(friends,compare_func)
        for _,friend in ipairs(friends)do
            if not self:hasManjuanEffect(friend) then
                return friend
            end
        end
    end
    if careLord and #enemies>0 then
        table.sort(enemies,compare_func)
        for _,enemy in ipairs(enemies)do
            if self:getRoleEstimate(enemy)=="loyalist" then
                return enemy
            end
        end
    end
    if #enemies>0 then
        self:sortInPlace(enemies, "threat")
        for _,enemy in ipairs(enemies)do
            if self:hasManjuanEffect(enemy) then
                return enemy
            end
        end
    end
    if #friends>0 then
        self:sortInPlace(friends, "defense")
        for _,friend in ipairs(friends)do
            if not self:hasManjuanEffect(friend) then
                return friend
            end
        end
    end
end

sgs.ai_skill_discard["olchenqing"] = function(self,discard_num,min_num,optional,include_equip)
    local victim = self.room:getCurrentDyingPlayer()
    local help = false
    if victim
	then
        if self:isFriend(victim)
		then help = true
        elseif self.player:getKnownRole()=="renegade"
		and victim:isLord() and self.room:alivePlayerCount()>2
		then help = true end
    end
    if help
	then
        local peach_num = 0
        local suits,ids = {},{}
		local cards = self.player:getCards("he")
		cards = self:sortByKeepValueInPlace(cards, nil, true)
        for _,c in ipairs(cards)do
            if isCard("Peach",c,self.player)
			then peach_num = peach_num+1
            else
                if table.contains(suits,c:getSuit())
				then continue end
				table.insert(suits,c:getSuit())
				table.insert(ids,c:getKnownEffectiveId())
            end
        end
        if peach_num+victim:getHp()<1
		or #ids>3 then return ids end
    end
    return self:askForDiscard("dummy", discard_num, min_num, optional, include_equip)
end

sgs.ai_skill_playerchosen["chenqing"] = function(self,targets)
	return sgs.ai_skill_playerchosen["olchenqing"](self,targets)
end

sgs.ai_skill_discard["Chenqing"] = function(self,discard_num,min_num,optional,include_equip)
	return sgs.ai_skill_discard["olchenqing"](self,discard_num,min_num,optional,include_equip)
end


sgs.ai_skill_use["@@Omozhi"] = function(self,prompt,method)
    local list = property(self,"allowed_guhuo_dialog_buttons"):split("+")
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValueInPlace(cards, nil, true) -- 按保留值排序
	if #list<1 or #cards<1 then return end
	list = declared(self,"Omozhi",list[1],{cards[1]:getKnownEffectiveId()})
    local dummy = self:aiUseCard(list)
   	if dummy.card and dummy.to
   	then
		if list:canRecast() and dummy.to:length()<1
		and method~=sgs.Card_MethodRecast
		then return end
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
            table.insert(tos,p:objectName())
       	end
       	return answer(self,list,tos)
    end
end

sgs.ai_skill_use["@@mozhi"] = function(self,prompt,method)
    local c = property(self,"mozhi")
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValueInPlace(cards, nil, true) -- 按保留值排序
	local name=c;c=evaluation(self,name)
	if #cards<1 or not c then return end
	c=declared(self,"mozhi",name,{cards[1]:getKnownEffectiveId()})
	local dummy = self:aiUseCard(c)
   	if dummy.card and dummy.to
   	then
		if c:canRecast() and dummy.to:length()<1
		and method~=sgs.Card_MethodRecast
		then return end
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
            table.insert(tos,p:objectName())
       	end
       	return answer(self,c,tos)
    end
end


sgs.ai_skill_discard["olyongsi"] = function(self,discard_num,min_num,optional,include_equip)
    if self:needToLoseHp() or getBestHp(self.player)<=self.player:getHp()
	then return "." end
    return self:askForDiscard("dummy", discard_num, min_num, optional, include_equip)
end


sgs.ai_skill_choice["oljixi"] = function(self,choices,data)
    local items = choices:split("+")
    if #items==1 then
        return items[1]
    end
    return "wangzun"
end

function OlRendeArrange(self,cards,friends,enemies,unknowns,arrange,recover_only)
	recover_only = recover_only or true
    if #enemies>0 then
        self:sortInPlace(enemies, "hp")
        for _,card in ipairs(cards)do
            if card:isKindOf("Shit") then
                return enemies[1],card,"enemy"
            end
        end
    end
    if #friends>0 then
        self:sortInPlace(friends, "defense")
        for _,friend in ipairs(friends)do
            local arranged = arrange[friend:objectName()] or {}
            if self:isWeak(friend) and friend:getHandcardNum()+#arranged<3 then
                for _,card in ipairs(cards)do
                    if card:isKindOf("Shit") then
                    elseif isCard("Peach",card,friend) or isCard("Analeptic",card,friend)
					then return friend,card,"friend"
                    elseif isCard("Jink",card,friend) and self:getEnemyNumBySeat(self.player, friend)>0
					then return friend,card,"friend"
                    end
                end
            end
        end
        for _,friend in ipairs(friends)do
            local arranged = arrange[friend:objectName()] or {}
            if friend:getHp()<=2 and friend:faceUp() then
                for _,card in ipairs(cards)do
                    if card:isKindOf("Armor") then
                        if not friend:getArmor() and not self:hasSkills("yizhong|bazhen|bossmanjia", friend) then
                            local given = false
                            for _,c in ipairs(arranged)do
                                if c:isKindOf("Armor") then
                                    given = true
                                    break
                                end
                            end
                            if not given then
                                return friend,card,"friend"
                            end
                        end
                    elseif card:isKindOf("DefensiveHorse") then
                        if not friend:getDefensiveHorse() then
                            local given = false
                            for _,c in ipairs(arranged)do
                                if c:isKindOf("DefensiveHorse") then
                                    given = true
                                    break
                                end
                            end
                            if not given then
                                return friend,card,"friend"
                            end
                        end
                    end
                end
            end
        end
        for _,friend in ipairs(friends)do
            local arranged = arrange[friend:objectName()] or {}
            if friend:getHandcardNum()+#arranged<4 then
                if friend:hasSkill("jijiu") then
                    for _,card in ipairs(cards)do
                        if card:isRed() then
                            return friend,card,"friend"
                        end
                    end
                end
                if friend:hasSkill("jieyin") then
                    return friend,cards[1],"friend"
                elseif friend:hasSkill("nosrenxin") and friend:isKongcheng() then
                    return friend,cards[1],"friend"
                end
            end
        end
        for _,friend in ipairs(friends)do
            if self:hasSkills("wusheng|longdan|wushen|keji|chixin", friend) then
                local arranged = arrange[friend:objectName()] or {}
                if friend:getHandcardNum()+#arranged>=2 and not self:hasCrossbowEffect(friend) then
                    for _,card in ipairs(cards)do
                        if card:isKindOf("Crossbow") then
                            local given = false
                            for _,c in ipairs(arranged)do
                                if c:isKindOf("Crossbow") then
                                    given = true
                                    break
                                end
                            end
                            if not given then
                                return friend,card,"friend"
                            end
                        end
                    end
                end
            end
        end
        for _,friend in ipairs(friends)do
            local arranged = arrange[friend:objectName()] or {}
            local has_crossbow = self:hasCrossbowEffect(friend)
            if not has_crossbow then
                for _,c in ipairs(arranged)do
                    if c:isKindOf("Crossbow") then
                        has_crossbow = true
                        break
                    end
                end
            end
            if has_crossbow or getKnownCard(friend,self.player,"Crossbow")>0 then
                for _,p in ipairs(self.enemies)do
                    if self:isGoodTarget(p, self.enemies, evaluation(self)) and friend:distanceTo(p)<=1 then
                        for _,card in ipairs(cards)do
                            if isCard("Slash",card,friend) then
                                return friend,card,"friend"
                            end
                        end
                    end
                end
            end
        end
        local compareByAction = function(a,b)
            return a:objectName()~=b:objectName() and self.room:getFront(a, b):objectName()==a:objectName()
        end
        table.sort(friends,compareByAction)
        for _,friend in ipairs(friends)do
            local flag = string.format("weapon_done_%s_%s",self.player:objectName(),friend:objectName())
            if friend:faceUp() and not public_flag(self,friend,flag) then
                local can_slash = false
                local others = self.room:getOtherPlayers(friend)
                for _,p in sgs.list(others)do
                    if self:isEnemy(p) and self:isGoodTarget(p, self.enemies) then
                        if friend:distanceTo(p)<=friend:getAttackRange() then
                            can_slash = true
                            break
                        end
                    end
                end
                if not can_slash then
                    for _,p in sgs.list(others)do
                        if self:isEnemy(p) and self:isGoodTarget(p, self.enemies) then
                            local distance = friend:distanceTo(p)
                            local range = friend:getAttackRange()
                            if distance>range then
                                for _,card in ipairs(cards)do
                                    if card:isKindOf("Weapon") then
                                        if not friend:getWeapon() then
                                            if distance<=range+(sgs.weapon_range[card:getClassName()] or 0) then
                                                self:setStrategyPlayerFlag(friend, flag, true)
                                                return friend,card,"friend"
                                            end
                                        end
                                    elseif card:isKindOf("OffensiveHorse") then
                                        if not friend:getOffensiveHorse() then
                                            if distance<=range+1 then
                                                self:setStrategyPlayerFlag(friend, flag, true)
                                                return friend,card,"friend"
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        local compareByNumber = function(a,b)
            return a:getNumber()>b:getNumber()
        end
        table.sort(cards,compareByNumber)
        for _,friend in ipairs(friends)do
            if friend:faceUp() then
                local skills = friend:getVisibleSkillList(true)
                for _,skill in sgs.list(skills)do
                    local callback = need_callback(self,skill:objectName())
                    if type(callback)=="function" then
                        for _,card in ipairs(cards)do
                            if callback(friend,card,self) then
                                return friend,card,"friend"
                            end
                        end
                    end
                end
            end
        end
        for _,card in ipairs(cards)do
            if card:isKindOf("Shit") then
                for _,friend in ipairs(friends)do
                    if self:isWeak(friend) then
                    elseif friend:hasSkill("jueqing") or card:getSuit()==sgs.Card_Spade then
                        if self:hasZhaxiangEffect(friend) then
                            return friend,card,"friend"
                        end
                    elseif self:hasSkills("guixin|jieming|yiji|nosyiji|chengxiang|noschengxiang|jianxiong", friend) then
                        return friend,card,"friend"
                    end
                end
            end
        end
        if self.player:getKnownRole()=="lord" and self.player:hasLordSkill("jijiang") then
            for _,friend in ipairs(friends)do
                local arranged = arrange[friend:objectName()] or {}
                if friend:getKnownKingdom()=="shu" and friend:getHandcardNum()+#arranged<3 then
                    for _,card in ipairs(cards)do
                        if isCard("Slash",card,friend) then
                            return friend,card,"friend"
                        end
                    end
                end
            end
        end
    end
    if #enemies>0 then
        self:sortInPlace(enemies, "defense")
        for _,enemy in ipairs(enemies)do
            if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then
                if not enemy:hasSkill("manjuan") then
                    for _,card in ipairs(cards)do
                        if isCard("Jink",card,enemy) then
                        elseif card:isKindOf("Disaster") or card:isKindOf("Shit") then
                            return enemy,card,"enemy"
                        elseif card:isKindOf("Collateral") or card:isKindOf("AmazingGrace") then
                            return enemy,card,"enemy"
                        elseif card:isKindOf("OffensiveHorse") or card:isKindOf("Weapon") then
                            return enemy,card,"enemy"
                        end
                    end
                end
            end
        end
    end
    local overflow = self:getOverflow()
    if #friends>0 then
        for _,friend in ipairs(friends)do
            local arranged = arrange[friend:objectName()] or {}
            if self:willSkipPlayPhase(friend) then
            elseif self:hasSkills(sgs.priority_skill, friend) and friend:getHandcardNum()+#arranged<=3 then
                if overflow-#arranged>0 or self.player:getHandcardNum()-#arranged>3 then
                    return friend,cards[1],"friend"
                end
            end
        end
    end
    if overflow>0 and #friends>0 then
        for _,card in ipairs(cards)do
            if not self:aiUseCard(card).card then
                self:sortInPlace(friends, "defense")
                return friends[1],card,"friend"
            end
        end
    end
	
	local slash = evaluation(self)
	local will_use_slash = false
	if self:aiUseCard(slash).card
	then will_use_slash = true end
	if not will_use_slash then
		local fire_slash = evaluation(self,"fire_slash")
		if self:aiUseCard(fire_slash).card
		then will_use_slash = true end
		if not will_use_slash then
			local thunder_slash = evaluation(self,"thunder_slash")
			if self:aiUseCard(thunder_slash).card then
				will_use_slash = true
			end
		end
	end
	
    if arrange["count"]<2 and self.player:getHandcardNum()>=2
	and ((self.player:getLostHp()>0 and self:isWeak()) or (not recover_only and will_use_slash))
	then
        if #friends>0 then
            return friends[1],cards[1],"friend"
        elseif #unknowns>0 then
            self:sortByKeepValueInPlace(cards)
            for _,p in ipairs(unknowns)do
                if p:hasSkill("manjuan") then
                    return p,cards[1],"unknown"
                end
            end
            self:sortInPlace(unknowns, "threat")
            return unknowns[#unknowns],cards[1],"unknown"
        elseif #enemies>0 then
            for _,enemy in ipairs(enemies)do
                if enemy:hasSkill("manjuan") then
                    return enemy,cards[1],"enemy"
                end
            end
        end
    end
end
local function resetPlayers(players,except)
    local result = {}
    for _,p in ipairs(players)do
        if not p:objectName()==except:objectName() then
            table.insert(result,p)
        end
    end
    return result
end



sgs.ai_skill_choice.fengpo = function(self,choices,data)
	local use = data:toCardUse()
	local to,slash = use.to:first(),use.card
 if to:isDead() or not self:isEnemy(to)then return "drawCards" end
 local from=fengpo_from(self)
 if not self:slashIsEffective(slash, to, from)then return "drawCards" end
	local nature = sgs.DamageStruct_Normal
	if slash:isKindOf("FireSlash") then nature = sgs.DamageStruct_Fire
	elseif slash:isKindOf("ThunderSlash") then nature = sgs.DamageStruct_Thunder end
	if not self:damageIsEffective(to, nature, from) then return "drawCards" end
	if getCardsNum("Jink",to,self.player)==0 and not self:cantDamageMore(self.player, to) then return "addDamage" end
	return "drawCards"
end

sgs.ai_skill_discard["olqingjian"] = function(self,discard_num,min_num,optional,include_equip,pattern)
    local qj = tag_ids(self,"olqingjian")
	qj = sgs.QList2Table(qj)
	local n = #qj
	local ids = {}
	for i=1,n do
		local to,id = callback(self,"ai_skill_askforyiji","nosyiji",self,qj)
		if to and id then
			table.insert(ids,id)
			table.removeOne(qj,id)
		end
	end
	return ids
end

sgs.ai_skill_use["@@olqingjian!"] = function(self,prompt,method)
    local qj = self.player:getPile("olqingjian")
	local to,id = callback(self,"ai_skill_askforyiji","nosyiji",self,sgs.QList2Table(qj))
	if to and id then
		return paid(self,"olqingjian","OlQingjianCard",{id},{to})
	end
    local cards = {}
    for _,id in sgs.list(qj)do
        table.insert(cards,self:getKnownCardById(id))
    end
    self:sortByUseValueInPlace(cards, true)
	for _,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) and not self:hasManjuanEffect(p) then
			return paid(self,"olqingjian","OlQingjianCard",{cards[1]:getKnownEffectiveId()},{p})
		end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if not self:isEnemy(p) and not self:hasManjuanEffect(p) then
			return paid(self,"olqingjian","OlQingjianCard",{cards[1]:getKnownEffectiveId()},{p})
		end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		return paid(self,"olqingjian","OlQingjianCard",{cards[1]:getKnownEffectiveId()},{p})
	end
end    



sgs.ai_skill_invoke.liangzhu = function(self,data)
	return true
end

sgs.ai_skill_choice.liangzhu = function(self,choices,data)
	local current = self.room:getCurrent()
	if self:isFriend(current) and (self:isWeak(current) or current:hasSkills(sgs.cardneed_skill))then
		return "letdraw"
	end
	return "draw"
end

sgs.ai_skill_invoke.cihuai = function(self,data)
	local has_slash = false
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	for _,card in ipairs(cards)do
		if card:isKindOf("Slash") then has_slash = true end
	end
	if has_slash then return false end

	self:sortInPlace(self.enemies, "defenseSlash")
	for _,enemy in ipairs(self.enemies)do
		local slash = evaluation(self)
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
		if eff and self.player:canSlash(enemy) and not self:slashProhibit(nil, enemy) then
			return true
		end
	end

return false
end

sgs.ai_fill_skill.cihuai = function(self,inclusive,request)
 return self:evaluateTurnConversion("cihuai", "Slash", {name="slash",skill="_cihuai",suit=sgs.Card_NoSuit,number=0,subcards={}}, request or self.request)
end

sgs.ai_skill_invoke.kunfen = function(self,data)
	if not self:isWeak() and (self:getCardsNum("Peach")+self.player:getHp()>1 or self:hasZhaxiangEffect(self.player)) then
		return true
	end
end

sgs.ai_fill_skill.chixin = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local diamond_card

	self:sortByUseValueInPlace(cards, true)

	local useAll = false
	self:sortInPlace(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()==1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)==0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash")<2 or self.player:hasSkill("paoxiao") then
		disCrossbow = true
	end


	for _,card in ipairs(cards)  do
		if card:getSuit()==sgs.Card_Diamond
		and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (not isCard("Crossbow",card,self.player) and not disCrossbow)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or (evaluation(self,"slash")):getTargetModResidue(self.player)>0) then
			diamond_card = card
			break
		end
	end
	if not diamond_card then return nil end
	local suit = diamond_card:getSuitString()
	local number = diamond_card:getNumberString()
	local card_id = diamond_card:getKnownEffectiveId()
	return self:evaluateTurnConversion("chixin", "Slash", {name="slash",skill="chixin",suit=diamond_card:getSuit(),number=diamond_card:getNumber(),subcards={card_id}}, request or self.request)

end

sgs.ai_view_as.chixin = function(card,player,card_place,class_name)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and card:getSuit()==sgs.Card_Diamond and not card:isKindOf("Peach") and not card:hasFlag("using") then
		if class_name=="Slash" then
			return {name="slash",skill="chixin",suit=card:getSuit(),number=card:getNumber(),subcards={card_id}}
		elseif class_name=="Jink" then
			return {name="jink",skill="chixin",suit=card:getSuit(),number=card:getNumber(),subcards={card_id}}
		end
	end
end

sgs.ai_cardneed.chixin = function(to,card)
	return card:getSuit()==sgs.Card_Diamond
end

sgs.ai_skill_playerchosen.suiren = function(self,targets)
	if self.player:getStrategyMark("@suiren")==0 then return "." end
	if self:isWeak() and (self:getOverflow()<-2 or not self:willSkipPlayPhase()) then return self.player end
	self:sortInPlace(self.friends_noself, "defense")
	for _,friend in ipairs(self.friends)do
		if self:isWeak(friend) and not self:needKongcheng(friend) then
			return friend
		end
	end
	self:sortInPlace(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies)do
		if (self:isWeak(enemy) and enemy:getHp()==1)
			and self.player:getHandcardNum()<2 and not self:willSkipPlayPhase() and self.player:inMyAttackRange(enemy) then
			return self.player
		end
	end
end

sgs.ai_playerchosen_intention.suiren = -60

sgs.ai_skill_use["@@jiqiao"] = function(self,prompt,method,pattern,request)
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValueInPlace(usable_cards, true)
	local use_cards = {}
	for _,c in ipairs(usable_cards)do
		if c:isKindOf("Armor") or c:isKindOf("DefensiveHorse") or c:isKindOf("OffensiveHorse") or (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()==0) then
			table.insert(use_cards,c:getKnownEffectiveId())
		end
	end
	if #use_cards==0 then return end
	if #use_cards>0 then
		return answer(self,self:bindSkillCard("jiqiao", use_cards, request, nil, "JiqiaoCard"))
	end
end


sgs.ai_fill_skill.xufa = function(self)
	local ids = self.player:getPile("xufa")
	local toids = {}
	if ids:length()>0 and self.player:getStrategyMark("xufa2-PlayClear")<1 then
		local xf = {}
		for _,id in sgs.list(ids)do
			table.insert(xf,self:getKnownCardById(id))
		end
		xf = self:sortByUseValueInPlace(xf)
		local cards = self.player:getCards("he")
		cards = self:sortByUseValueInPlace(cards)
		for _,c in sgs.list(xf)do
			if c:isNDTrick() and #cards>0 then
				local costs = {}
				table.insert(toids,c:getKnownId())
				for _,c in sgs.list(sgs.reverse(xf))do
					if not table.contains(toids,c:getKnownId()) and #toids<#xf/2 then
						table.insert(toids,c:getKnownId())
					end
				end
				costs[#costs+1]=cards[#cards]:getKnownEffectiveId()
				local dc=declared(self,"xufa",c:objectName(),costs)
				if dc:isAvailable(self.player) then
					local d = self:aiUseCard(dc)
					if d.card then
						if dc:canRecast() and d.to:length()<1
						then continue end
						save_xufa(self,d,c:objectName())
						return skill_seed(self,"xufa","XufaCard",toids)
					end
				end
				toids = {}
			end
		end
	end
	local cards = self.player:getCards("he")
	if cards:length()>0 and self.player:getStrategyMark("xufa1-PlayClear")<1 then
		cards = self:sortByUseValueInPlace(cards)
		for _,c in sgs.list(cards)do
			if c:isNDTrick() then
				local costs = {}
				table.insert(toids,c:getKnownId())
				for _,c in sgs.list(sgs.reverse(cards))do
					if not table.contains(toids,c:getKnownId()) and #toids<#cards/2 then
						if #costs<1 then
							costs[#costs+1]=c:getKnownEffectiveId()
						else
							table.insert(toids,c:getKnownId())
						end
					end
				end
				local dc=declared(self,"xufa",c:objectName(),costs)
				if dc:isAvailable(self.player) then
					local d = self:aiUseCard(dc)
					if d.card then
						if dc:canRecast() and d.to:length()<1
						then continue end
						save_xufa(self,d,c:objectName())
						return skill_seed(self,"xufa","XufaCard",toids)
					end
				end
				toids = {}
			end
		end
	end
end

sgs.ai_skill_use_func["XufaCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.XufaCard = 4.4
sgs.ai_use_priority.XufaCard = 11.8

sgs.ai_skill_choice.xufa=function(self)
 return self:getStrategyMemory('xufa.choice')
end
sgs.ai_skill_use["@@xufa"]=function(self,prompt,method)
 local d=load_xufa(self)
 if d.card then
  if d.card.can_recast and #d.to<1 and method~=sgs.Card_MethodRecast then return end
  return self:materializeXufaSaved(d.card, d.to)
 end
end
