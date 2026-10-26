-- Source: b6025acc ai/NyarzFirst-ai.lua.
local known = AIValue.requireKnown
local function hydrate_context(self,value,kind)
 if value==nil then return nil end
 if kind=='Player' then
  if AIValue.isPlayer(value)then return value end
  return known(self.room:findPlayerByObjectName(value,true),'context.player:'..tostring(value))
 end
 if kind=='Card'then
  if AIValue.isCard(value)or AIValue.isConversion(value)then return value end
  return CardView.new(value,self.room)
 end
 if kind=='Bool'or kind=='String'or kind=='Int'then return value end
 if kind=='IntList'then return AIList.new(value)end
 local row={};for k,v in pairs(value)do row[k]=v end
 for _,k in ipairs{'from','who','m_who'}do if value[k]then row[k]=hydrate_context(self,value[k],'Player')end end
 for _,k in ipairs{'card','whocard','m_card','m_toCard'}do if value[k]then row[k]=hydrate_context(self,value[k],'Card')end end
 if kind=='CardUse'then row.to=AIList.new({});for _,v in ipairs(value.to or{})do row.to:append(hydrate_context(self,v,'Player'))end
 elseif value.to then row.to=hydrate_context(self,value.to,'Player')end
 if kind=='Dying'and value.damage then row.damage=hydrate_context(self,value.damage,'Damage')end
 if kind=='Judge'then
  function row:isGood(c)
   if c==nil then return self.good end
   if self.outcomes_complete~=true then return nil end
   local values=self.outcome_by_id;if type(values)=='table'then return values[tostring(c:getEffectiveId())]end
  end
  function row:isBad(c)local v=self:isGood(c);if type(v)=='boolean'then return not v end end
 end
 return row
end
local nullable={useCardByClassName=true,updatePlayers=true,getCard=true,getArmor=true,getWeapon=true,getTreasure=true,findPlayerBySkillName=true,toPlayer=true,useEquipCard=true,useTrickCard=true,useBasicCard=true,moveField=true,getCurrent=true,getLord=true,getMaxCard=true,setStrategyMemory=true,getStrategyMemory=true,updateIntention=true,setStrategyCardFlag=true}

local function source_type(c)for _,name in ipairs{"BasicCard","TrickCard","EquipCard"}do if c:isKindOf(name)then return name end end end
local function face(self,id)return self:getKnownCardById(id)end
local function fullhand(p)local cs=p:getHandcards();if #cs~=p:getHandcardNum()then ai_unsupported('NyarzFirst source requires complete lawful foreign hand','NyarzFirst.foreign_hand')end;return cs end
local function evaluation(self,name)return self:getEvaluationCard(name or'slash')end
local function named(self,skill,name,costs)return self:evaluateSkillCard(skill, name, costs or{})end
local function own_ai(p)local a=p._room and p._room._ai;if not a or a.player~=p then ai_unsupported('NyarzFirst view-as requires owner','NyarzFirst.view_as')end;return a end
local function memory(self,key,value,write)
 if write then if value==nil then value=false end;self:setStrategyMemory('NyarzFirst.'..key, value);return end
 local value,present=self:getStrategyMemory('NyarzFirst.'..key);if present then return value~=false and value or nil end
end
local function save_targets(self,key,ts)local names={};for _,p in ipairs(ts or{})do names[#names+1]=p:objectName()end;memory(self,key,names,true)end
local function targets(self,key)local names=memory(self,key);if not names then return nil end;local out=AIList.new({});for _,n in ipairs(names)do out:append(known(self.room:findPlayerByObjectName(n),n))end;return out end
local selectors={Godpoxi=true,GodpoxidisCard=true,exchengxiang=true,renchou=true,pingjianex=true,Dlimu=true,gfengying=true,dyuyuan=true,paiyiex=true,DiylijiCard=true,godgongxin=true,godgongxindisCard=true,extuifengCard=true,exqiangwu=true,spyuqi=true,jitongxin=true,jitongxinelse=true,spjiang=true,exfangtongCard=true,spjilve=true,sppingxiang=true,sppingxiangSlash=true,spjiufa=true,dyizheng=true,drangjie=true,dwzhizhe=true,dwqingshi=true,jfjifengdis=true,xrxiaorui=true,xrshanjia=true,yzxieshu=true}
local provider={GodpoxidisCard='Godpoxi',godgongxindisCard='godgongxin',DiylijiCard='Diyliji',extuifengCard='extuifeng',exfangtongCard='exfangtong',sppingxiangSlash='sppingxiang',jfjifengdis='jfjifeng'}
local function ids(raw)local out={};if raw~='.'and raw~=''then for v in raw:gmatch('[^+]+')do local id=tonumber(v);if not id or id<0 or id%1~=0 then ai_unsupported('invalid NyarzFirst source material',raw)end;out[#out+1]=id end end;return out end
local function wireparts(wire)
 local cls,raw,user=wire:match('^#([%w_]+):([^:]*):(.*)$');if not cls or not selectors[cls]then ai_unsupported('unmapped NyarzFirst skillcard selector',wire)end
 local to={};local declaration=user;local names=user:match('^%-%>(.*)$');if names then declaration='';for n in names:gmatch('[^+]+')do to[#to+1]=n end end
 return cls,ids(raw),declaration,to
end
local suits={spade=0,club=1,heart=2,diamond=3,no_suit_black=4,no_suit_red=5,no_suit=6,to_be_decided=6}
local function printed(wire,self)
 local name,skill,suit,num,raw=wire:match('^([%w_]+):([%w_]+)%[([^:]+):([^%]]+)%]=([^:]+)$')
 if not name or suits[suit]==nil then ai_unsupported('NyarzFirst source CardParse face needs exact native parser witness',wire)end
 local numbers={A=1,J=11,Q=12,K=13,JOKER=0};local number=numbers[num]or tonumber(num);if not number then ai_unsupported('NyarzFirst source number is not parsed',wire)end
 local costs=ids(raw);local color=suits[suit]
 if #costs==1 then local c=face(self,costs[1]);if color==6 then color=c:getSuit()end;if number<=0 then number=c:getNumber()end
 elseif #costs>1 and color==6 then local red,black=true,true;for _,id in ipairs(costs)do local c=face(self,id);red=red and c:isRed();black=black and c:isBlack()end;color=red and 5 or black and 4 or 6 end
 return{name=name,skill=skill,suit=color,number=number,subcards=costs}
end
local function parse(self,wire)
 if wire:sub(1,1)~='#'then local spec=printed(wire,self);local c=evaluation(self,spec.name);return self:evaluateTurnConversion(spec.skill, c:getClassName(), spec, self.request)end
 local cls,costs,user=wireparts(wire);local skill=provider[cls]or cls
 if #costs==0 and user==''then return self:legacySkillSeed(skill, '#'..cls, self.request)end
 return self:evaluateTurnSkillCard(skill, '#'..cls, costs, self.request, user~=''and user or nil)
end
local function response(self,wire)
 local cls,costs,user,to=wireparts(wire);local request=self.request
 -- This response callback receives the outer DTO, not an AiLegacyRequestView.
 -- With no explicit skill_action, the existing binder selects the unique
 -- current native source scope; it still rejects missing or ambiguous scopes.
 if cls=='gfengying'then request=AILegacyRequest.new(request,self.room)end
 local c=self:bindSkillCard(provider[cls]or cls, costs, request, user~=''and user or nil, '#'..cls)
 return{kind='use_card',card_spec=c:toCardSpec(),targets=to}
end
local function answer(self,c,to)
 if c:isEvaluationOnly()then local skill=c:getKnownSkillName(false);local provider=skill:gsub('^_','');local receipt=self:bindSkillCard(provider, c:getSubcards(), self.request, c:objectName())
  for _,key in ipairs{'objectName','getSuit','getNumber'}do if AIValue.callKnown(receipt, key)~=AIValue.callKnown(c, key)then ai_unsupported('NyarzFirst receipt changed selected source product',key)end end
  if receipt:getKnownSkillName(false)~=skill then ai_unsupported('NyarzFirst receipt changed raw skill',skill)end
  local a,b=receipt:getSubcards(),c:getSubcards();if #a~=#b then ai_unsupported('NyarzFirst receipt changed costs',skill)end;for i,id in ipairs(a)do if b[i]~=id then ai_unsupported('NyarzFirst receipt reordered costs',skill)end end;c=receipt
 end
 if AIValue.isConversion(c)then return{kind='use_card',card_spec=c:toCardSpec(),targets=to or{}}end
 if c:isVirtualCard()then ai_unsupported('NyarzFirst selected virtual lacks authority','NyarzFirst.answer')end
 return{kind='use_card',card_ids={c:getKnownEffectiveId()},targets=to or{}}
end
local function nested(self,reg,key,...)
 local f=self:getHooks(reg)[key];if type(f)~='function'then ai_unsupported('NyarzFirst required shared callback missing',reg..'.'..key)end
 local v=f(...);if AIUnsupported.is(v)then error(v,0)end;return v
end
local function view(self,wire)return printed(wire,self)end

-- The donor passes its Room-VM free global `inverse`; that VM's globals are not projected.
local function source_inverse(self) ai_unsupported("source global inverse is not projected","NyarzFirst.inverse") end
-- Own property; absent reads as the donor's empty toString().
local function prop(self,key)local v=self.player:getPropertyValue(key);if v==nil then return""end;if type(v)~="string"then ai_unsupported("NyarzFirst owner property is not a string",key)end;return v end
local function context(self)return known(self:getDecisionContext().NyarzFirst,'NyarzFirst.context')end
local function tagplayer(self,owner,key)
 local rows=context(self).player_tags;local row=rows and rows[key]
 if type(row)~='table'or row.owner~=(owner and owner:objectName()or'@room')or row.known~=true then ai_unsupported('NyarzFirst current actor tag unknown',key)end
 if row.present==false then return nil end
 return hydrate_context(self,row.value,'Player')
end
local function tagids(self,key)local rows=context(self).id_tags;return AIList.new(known(rows and rows[key],key))end
local function taguse(self,key)return hydrate_context(self,known(context(self)[key],key),'CardUse')end
local function tagjudge(self,key)return hydrate_context(self,known(context(self)[key],key),'Judge')end
-- Card tags are not projected.
local function cardtag(self,c,key)
 ai_unsupported('card tag is not projected',key)
end
local function role(self,p)if p==self.player then return p:getKnownRole()end;return self:getRoleEstimate(p)end
local function descriptor(c)local ids={};for _,id in ipairs(c:getSubcards())do ids[#ids+1]=id end;return{name=c:objectName(),skill=c:getKnownSkillName(false),suit=c:getSuit(),number=c:getNumber(),subcards=ids}end


sgs.ai_skill_playerchosen.Dqizhi = function(self,targets)
	self:updatePlayers()

	if self.player:getJudgingArea():length() > 0 then return self.player end
	local targets = sgs.QList2Table(targets)
	for _,target in ipairs(targets)do
		if self:isFriend(target) and target:getJudgingArea():length() > 0 then return target end
	end
	return nested(self,"ai_skill_playerchosen","qizhi",self,targets)
end


ai_skill_invoke.Djinqu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local player = self.player
    if (player:getStrategyMark("&Dqizhi-Clear") > 0) and (player:getStrategyMark("&Dqizhi-Clear") >= player:getHandcardNum()) then return (true) or false end
    return (false) or false 
end


ai_skill_invoke.Godjieying = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local player = self.player
    local target = tagplayer(self,player,"jieyingtarget")
    if self:isEnemy(target) then
        return (true) or false
    else
        return (false) or false 
    end
	return false

end

sgs.ai_skill_playerchosen.Godjieying = function(self, targets)
	if self.player:getStrategyMark("&Godying") < 2 then return nil end
	for _,target in sgs.qlist(targets) do
		if self:isFriend(target) then
			return target
		end
	end
	if self.player:getStrategyMark("&Godying") < 3 then return nil end
	for _,target in sgs.qlist(targets) do
		if self:isEnemy(target) then
			return target
		end
	end
	return nil
end


ai_fill_skill.Godpoxi=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#Godpoxi") then
		return parse(self,"#Godpoxi:.:")
	end
end

ai_card_use["#Godpoxi"] = function(self, card, use, request)
	self:updatePlayers()
	if #self.enemies <= 0 then return end
	local target = nil
	self:sortInPlace(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in ipairs(self.enemies) do

		if p:getHandcardNum() == 0 then continue end
		target = p
		break
	end
	if not target then return end
	if target then
		local card_str = "#Godpoxi:.:->"..target:objectName()
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

ai_skill_use["@@Godpoxi"] = function(self, prompt, request)
	local target = tagplayer(self,self.player,"godpoxi")
	if target then
		local target_handcards = sgs.QList2Table(fullhand(target))
		self:sortByUseValueInPlace(target_handcards, source_inverse(self))
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		local discard_cards = {}
		local spade_check = true
		local heart_check = true
		local club_check = true
		local diamond_check = true
		local target_discard_count = 0
		
		for _, c in ipairs(target_handcards) do
			if spade_check and c:getSuit() == sgs.Card_Spade then
				spade_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			elseif heart_check and c:getSuit() == sgs.Card_Heart then
				heart_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			elseif club_check and c:getSuit() == sgs.Card_Club then
				club_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			elseif diamond_check and c:getSuit() == sgs.Card_Diamond then
				diamond_check = false
				table.insert(discard_cards, c:getKnownEffectiveId())
			end
			target_discard_count = #discard_cards
		end
		
		for _, c in ipairs(handcards) do
			if not c:isKindOf("Peach")
			and not c:isKindOf("Duel")
			and not c:isKindOf("Indulgence")
			and not c:isKindOf("SupplyShortage")
			and not (self:getCardsNum("Jink") == 1 and c:isKindOf("Jink"))
			and not (self:getCardsNum("Analeptic") == 1 and c:isKindOf("Analeptic"))
			then
				if spade_check and c:getSuit() == sgs.Card_Spade then
					spade_check = false
					table.insert(discard_cards, c:getKnownEffectiveId())
				elseif heart_check and c:getSuit() == sgs.Card_Heart then
					heart_check = false
					table.insert(discard_cards, c:getKnownEffectiveId())
				elseif club_check and c:getSuit() == sgs.Card_Club then
					club_check = false
					table.insert(discard_cards, c:getKnownEffectiveId())
				elseif diamond_check and c:getSuit() == sgs.Card_Diamond then
					diamond_check = false
					table.insert(discard_cards, c:getKnownEffectiveId())
				end
			end
		end

		if ((4 - target_discard_count) == 0) and self.player:getHandcardNum() > self.player:getMaxCards() then return "." end
		
		if #discard_cards == 4 then
			return response(self,"#GodpoxidisCard:"..table.concat(discard_cards, "+")..":")

		end
	end
	return "."
end

sgs.ai_use_priority.Godpoxi = 3
sgs.ai_use_value.Godpoxi = 3
sgs.ai_card_intention.Godpoxi = 50


ai_skill_invoke.exchengxiang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

sgs.ai_skill_playerchosen.exchengxiang = function(self, targets)
    for _,target in sgs.qlist(targets) do
		if self:isFriend(target) and target:isWounded() then
			return target
		end
	end
    for _,target in sgs.qlist(targets) do
		if self:isFriend(target) then
			return target
		end
	end
    return nil
end

sgs.ai_playerchosen_intention.exchengxiang = function(self, from, to)
	self:updateIntention(from, to, -80)
end

ai_skill_use["@@exchengxiang"] = function(self, prompt, request)
	local card_ids = tagids(self,"chengxiangcards")
	local getcards = {}
	local sum = 0
	for _,id in sgs.qlist(card_ids) do
		local card = face(self,id)
		if card:isKindOf("EquipCard") or (card:objectName() == "peach") or (card:objectName() == "analeptic") then
			if (card:getNumber() + sum) <= 13 then
				table.insert(getcards,id)
				sum = sum + card:getNumber()
			end
		end
	end
	for _,id in sgs.qlist(card_ids) do
		local card = face(self,id)
		if ((card:getNumber() + sum) <= 13) and (not table.contains(getcards,id)) then
			table.insert(getcards,id)
			sum = sum + card:getNumber()
		end
	end
	local card_str = "#exchengxiang:"..table.concat(getcards, "+")..":"
	return response(self,card_str)
end

sgs.ai_can_damagehp.exchengxiang = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to)
end


ai_skill_invoke.exrenxin = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = tagplayer(self,self.player,"renxintarget")
    if self:isFriend(target) then return (true) or false end
    if target:objectName() == self.player:objectName() then return (true) or false end
    return (false) or false
end

 
ai_fill_skill.LuaLonghun=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValueInPlace(cards, true)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Diamond and self:slashIsAvailable() then
			return parse(self,("fire_slash:longhun[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getKnownId()))
		end
	end
end

sgs.ai_view_as.LuaLonghun = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place == sgs.Player_PlaceSpecial then return end
	if card:getSuit() == sgs.Card_Diamond then
		return view(own_ai(player),("fire_slash:longhun[%s:%s]=%d"):format(suit, number, card_id))
	elseif card:getSuit() == sgs.Card_Club then
		return view(own_ai(player),("jink:longhun[%s:%s]=%d"):format(suit, number, card_id))
	elseif card:getSuit() == sgs.Card_Heart and player:getStrategyMark("Global_PreventPeach") == 0 then
		return view(own_ai(player),("peach:longhun[%s:%s]=%d"):format(suit, number, card_id))
	elseif card:getSuit() == sgs.Card_Spade then
		return view(own_ai(player),("nullification:longhun[%s:%s]=%d"):format(suit, number, card_id))
	end
end

sgs.LuaLonghun_suit_value = {
	heart = 6.7,
	spade = 5,
	club = 4.2,
	diamond = 3.9,
}

function sgs.ai_cardneed.LuaLonghun(to, card, self)
	if to:getCardCount() > 3 then return false end
	if to:isNude() then return true end
	return card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Spade
end


ai_skill_invoke.exjueqing = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local player = self.player
    local target = tagplayer(self,player,"exjueqingta")
    if self:isEnemy(target) then
        return (true) or false
    else
        return (false) or false 
    end
	return false

end

sgs.ai_getLeastHandcardNum_skill.exshangshi = function(self, player, least)
	local x = math.max(player:getLostHp(), 1)
	if least < x then
		return x
	end
end


ai_fill_skill.renchou=function(self, options, request)
    local inclusive = options and options.inclusive

	local card = named(self,"renchou_limit","slash",{})
	
	if not self.player:isCardLimited(card, sgs.Card_MethodUse) then
		return self:legacySkillSeed("renchou", "#renchou", request)
	end
end

ai_card_use["#renchou"] = function(self, card, use, request)
	local target = nil
	self:sortInPlace(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	local target = nil
	local card = named(self,"renchou","slash",{})
	for _, enemy in ipairs(self.enemies) do
		if  (((self.player:getHandcardNum() == enemy:getHandcardNum() and self.player:getHp() ~= enemy:getHp())
		or (self.player:getHandcardNum() ~= enemy:getHandcardNum() and self.player:getHp() == enemy:getHp()))) and self:slashIsEffective(card, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, card) then
			use.card = card
			target = enemy
		end
	end
	if target then
		local card_str = "#renchou:.:->"..target:objectName()
		local acard = self:evaluateTurnSkillCard("renchou", "#renchou", {}, request)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end


sgs.ai_skill_playerchosen.dwanggui = function(self, targets)

	if self.player:getStrategyMark("dwangguida") > 0 then
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and not self:cantbeHurt(p) and self:damageIsEffective(p) and self:canDamage(p, self.player, nil) then
				return p
			end
		end
		return nil
	else
		local p = nil
		local hand = 999
		for _,ta in sgs.qlist(targets) do
			if self:isFriend(ta) and (ta:getHandcardNum() < hand) and (ta:objectName() ~= self.player:objectName()) then
				p = ta
				hand = ta:getHandcardNum()
			end
		end
		if p then 
			return p
		else
			return self.player
		end
	end
end


ai_skill_invoke.dxibin = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local player = self.player
    local target = tagplayer(self,player,"dxibinta")
    if self:isEnemy(target) then
		if target:getHandcardNum() >= target:getHp() then
        	return (true) or false
		elseif target:getHandcardNum() < target:getHp() then
			local draw = target:getHp() - target:getHandcardNum()
			if draw >= 3 then return (false) or false end
			return (true) or false
		end
    elseif self:isFriend(target) then
        if (target:getHandcardNum() + 2) < target:getHp() then
			for _,card in sgs.qlist(fullhand(target)) do
				if card:isAvailable(target) then return (false) or false end
			end
			return (true) or false
		end
    end
	return (false) or false
end


ai_fill_skill.pingjianex=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#pingjianex") then
		return parse(self,"#pingjianex:.:")
	end
end

ai_card_use["#pingjianex"] = function(self, card, use, request)
	use.card = card
end

ai_skill_invoke.pingjianex = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end


ai_skill_invoke.Dtushe = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getPhase() == sgs.Player_NotActive then return (true) or false end
	if self.player:getStrategyMark("dtushe") >= 2 then return (true) or false end
	local can = true
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValueInPlace(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("BasicCard") then
			can = false 
			break
		end
	end
	local slash = 0
	local more = 0
	local mm = {"amazing_grace", "savage_assault", "archery_attack", "god_salvation"}
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then
			slash = slash + 1
		end
		if table.contains(mm,card:objectName()) then
			more = more + 1
		end
	end
	if slash == 0 and more == 0 then return (true) or false end
	return (can) or false
end


ai_skill_invoke.Dlimu = true

ai_fill_skill.Dlimu=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValueInPlace(cards, true)
	local slash = 0
	local red = 0
	local black = 0
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then
			slash = slash + 1
		end
		if card:isRed() then
			red = red + 1
		end
		if card:isBlack() then
			black = black + 1
		end
	end
	if (slash >= 2 and (not self.player:containsTrick("supply_shortage")) and black > 0)  then
		return parse(self,"#Dlimu:.:")
	elseif self.player:getHp() == 1 and red > 0 and (not self.player:containsTrick("indulgence"))
	or ((not self.player:containsTrick("indulgence")) and slash >= 4 and red > 0 and (not self.player:containsTrick("supply_shortage"))) then
		return parse(self,"#Dlimu:.:")
	end
end

ai_card_use["#Dlimu"] = function(self, card, use, request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValueInPlace(cards, true)
	local slash = 0
	local red = 0
	local black = 0
	for _, cc in ipairs(cards) do
		if cc:isKindOf("Slash") then
			slash = slash + 1
		end
		if cc:isRed() then
			red = red + 1
		end
		if cc:isBlack() then
			black = black + 1
		end
	end
	local usecard = nil
	if slash >= 2 and (not self.player:containsTrick("supply_shortage")) and black > 0 then
		for _, cc in ipairs(cards) do
			if cc:isBlack() then
				usecard = cc
				break
			end
		end
	elseif (self.player:getHp() == 1 and red > 0 and (not self.player:containsTrick("indulgence")))
	or ((not self.player:containsTrick("indulgence")) and slash >= 4 and red > 0 and (not self.player:containsTrick("supply_shortage")))then
		for _, cc in ipairs(cards) do
			if cc:isRed() then
				usecard = cc
				break
			end
		end
	end
	if usecard then
		local target = self.player
		local card_str = string.format("#Dlimu:%d:->%s", usecard:getKnownId(), target:objectName())
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.Dlimu = 7
sgs.double_slash_skill = sgs.double_slash_skill .. "|Dlimu"

sgs.ai_card_priority.Dlimu = function(self, card, v)
	if card:objectName() == "_xuanjian" then
		return v + 5
	end
	
	if card:objectName() == "spear" then
		return v + 4
	end
	
	if self.player:hasWeapon("_xuanjian") or self.player:hasWeapon("spear") then
		if card:isKindOf("Slash") then
			return v + 3
		end
	end
	
	if (self.player:hasWeapon("_xuanjian") or self.player:hasWeapon("spear"))
	   and (card:isKindOf("Dlimu") or table.contains(card:getSkillNames(), "Dlimu")) then
		return v + 2
	end
	
	return v
end

-- audited alias ai_skill_carduse.Dlimu
sgs.ai_use_revises.Dlimu = function(self,card,use)
	if self.player:hasWeapon("spear")
	and card:isKindOf("Weapon")
	then return false end
	if card:objectName()=="spear"
	then
		use.card = card
		return true
	end
	if self:getCardsNum("BasicCard", "h")<1
	then
		local ge = self:getCard("GlobalEffect") or self:getCard("AOE")
		if ge and ge:isAvailable(self.player)
		then use.card = ge return true end
	end
end


ai_skill_invoke.spduorui = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local ta = tagplayer(self,self.player,"duoruita")
	if self:isEnemy(ta) then return (true) or false end
	return (false) or false
end
sgs.ai_choicemade_filter.skillInvoke.spduorui = function(self,player,promptlist)
	local target = tagplayer(self,player,"duoruita")
	if target then
		if promptlist[#promptlist]=="yes" then
			self:updateIntention(player, target, 80)
		else
			self:updateIntention(player, target, -10)
		end
	end
end


ai_skill_use["@@gfengying"] = function(self, prompt, request)
	if self.player:getHandcardNum() < 2 then return "." end
	local handcards = self.player:getCards("he")
	handcards = sgs.QList2Table(handcards)
	self:sortByKeepValueInPlace(handcards)
	local card = handcards[1] 
	self:sortInPlace(self.enemies, "defense")
	local slash = named(self,"gfengying","thunder_slash",{card:getKnownEffectiveId()})
	
	local target = nil
	for _,enemy in ipairs(self.enemies) do
		if enemy:isAlive() and self:round50CanSlash(slash, enemy) and not self:slashProhibit(slash, enemy)
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
			target = enemy
			break
		end
	end
	if target then
		local card_str = string.format("#gfengying:%d:->%s", card:getKnownId(), target:objectName())
		return response(self,card_str)
	else
		return "."
	end
end

sgs.ai_card_intention.gfengying = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		self:updateIntention(from, to, 40)
	end
end


ai_skill_invoke.xuzun = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getHandcardNum() <= self.player:getMaxHp() then return (true) or false end
	return (false) or false
end


ai_skill_use["@@dyuyuan"] = function(self, prompt, request)
	if self.player:getHandcardNum() <= self.player:getMaxCards() then return "." end
	local handcards = self.player:getCards("h")
	handcards = sgs.QList2Table(handcards)
	if #handcards == 0 then return "." end
	if self.player:getPhase() == sgs.Player_Play then
		self:sortByUseValueInPlace(handcards, true)
		if #handcards == 1 then return "." end
	else
		self:sortByKeepValueInPlace(handcards, true)
	end
	local card = handcards[1] 

	self:sortInPlace(self.friends, "defense")
	local target = nil
	for _,friend in ipairs(self.friends) do
		if friend:isAlive() and friend:getStrategyMark("dyuyuan") == 0 and (self.player:objectName() ~= friend:objectName()) then
			target = friend
			break
		end
	end

	if not target and self.player:getHandcardNum() > 3 and self.player:getPhase() == sgs.Player_Play then
		self:sortInPlace(self.enemies, "defense")
		for _,enemy in ipairs(self.enemies) do
			if enemy:isAlive() and enemy:getStrategyMark("dyuyuan") == 0 and (enemy:getStrategyMark("dyuyuan"..self.player:objectName()) < enemy:getHp()) then
				target = enemy
				break
			end
		end
	end

	if target then
		if self:isEnemy(target) then
			local card_str = string.format("#dyuyuan:%d:->%s", card:getKnownId(), target:objectName())
			return response(self,card_str)
		elseif self:isFriend(target) then
			if (self.player:getHandcardNum() > (self.player:getMaxCards() + 1)) and (#handcards >= 2) then
				local cards = {}
				table.insert(cards, handcards[1]:getEffectiveId())
				table.insert(cards, handcards[2]:getEffectiveId())
				local card_str = string.format("#dyuyuan:%s:->%s", table.concat(cards,"+"), target:objectName())
				return response(self,card_str)
			else
				local card_str = string.format("#dyuyuan:%d:->%s", card:getKnownId(), target:objectName())
				return response(self,card_str)
			end
		end
	else
		return "."
	end
end

sgs.ai_skill_playerchosen.dyuyuan = function(self, targets)
	local max = -1
	local target = nil
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) and p:getStrategyMark("dyuyuan"..self.player:objectName()) > max and self:damageIsEffective(p) and not self:cantDamageMore(self.player, p) and self:canDamage(p, self.player, nil) then
			max = p:getStrategyMark("dyuyuan"..self.player:objectName())
			target = p
		end
	end
	return target
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|dyuyuan"
function sgs.ai_slash_prohibit.dyuyuan(self,from,to)
	if self:hasJueqingEffect(from, to) or (from:hasSkill("nosqianxi") and from:distanceTo(to)==1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:getHp()>1 or #(self:getEnemies(from))==1 then return false end
	if from:getMaxHp()==3 and from:getArmor() and from:getDefensiveHorse() then return false end
	if from:getMaxHp()<=3 or (from:isLord() and self:isWeak(from)) then return true end
	if from:getMaxHp()<=3 or (self.room:getLord() and role(self,from)=="renegade") then return true end
	return false
end


sgs.ai_skill_playerchosen.Gliegong = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then return p end
	end
	return nil
end

sgs.ai_playerchosen_intention.Gliegong = function(self, from, to)
	self:updateIntention(from, to, 200)
end


ai_skill_invoke.Gposhi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local ta = tagplayer(self,self.player,"Gposhi")
	if self:isEnemy(ta) then
		return (true) or false
	else
		return (false) or false
	end
	return false

end
sgs.hit_skill = sgs.hit_skill .. "|Gposhi"
-- audited alias ai_cardneed.Gposhi
ai_skill_invoke.exquanji = true
sgs.ai_can_damagehp.exquanji = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>1
	and self:canLoseHp(from, card, to)
end


ai_skill_choice["ziliex"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	if self.player:getLostHp() > 1 then
		return ai_choice_result(("recover"), options)
	else
		return ai_choice_result(("draw"), options)
	end

    return ai_choice_result(nil, options)
end


ai_skill_invoke.paiyiex = true

ai_fill_skill.paiyiex=function(self, options, request)
    local inclusive = options and options.inclusive

	if (not self.player:getStrategyHasUsed("#paiyiex")) and (self.player:getPile("exquan"):length() > 0 )  then
		return parse(self,"#paiyiex:.:")
	end
end

ai_card_use["#paiyiex"] = function(self, card, use, request)
	local card_ids = self.player:getPile("exquan")
	local usecard = nil
	for _,id in sgs.qlist(card_ids) do
		usecard = face(self,id)
		break
	end

	local target = nil
	if self.player:getPile("exquan"):length() <= 2 then
		self:sortInPlace(self.enemies, "defense")
		self.enemies = sgs.reverse(self.enemies)
		for _,enemy in ipairs(self.enemies) do
			if (enemy:getHandcardNum() + self.player:getPile("exquan"):length() - 1) > self.player:getHandcardNum() then
				target = enemy
				break
			end
		end
	end
	if not target then
		self:sortInPlace(self.friends, "defense")
		self.friends = sgs.reverse(self.friends)
		for _,friend in ipairs(self.friends) do
			if (friend:getHandcardNum() + self.player:getPile("exquan"):length() - 1) <= self.player:getHandcardNum() then
				target = friend
				break
			end
		end
	end
	if not target then target = self.player end
	local card_str = string.format("#paiyiex:%d:->%s", usecard:getKnownId(), target:objectName())
	local acard = parse(self,card_str)
	assert(acard)
	use.card = acard
	if use.to then
		use.to:append(target)
	end
end

sgs.ai_card_intention["#paiyiex"] = function(self, card, from ,tos)
	for _,to in sgs.qlist(tos) do
		if from:getPile("exquan"):length() <= 2 then
			self:updateIntention(from, to, 30)
		else
			self:updateIntention(from, to, -50)
		end
	end
end

sgs.ai_use_priority["#paiyiex"] = 3


ai_fill_skill.Diyliji=function(self, options, request)
    local inclusive = options and options.inclusive

	if (self.player:getStrategyMark("&Diyliji-Clear") > 0) and (self.player:canDiscard(self.player, "he")) then
		return parse(self,"#DiylijiCard:.:")
	end
end

ai_card_use["#DiylijiCard"] = function(self, card, use, request)
	local handcards = self.player:getCards("he")
	handcards = sgs.QList2Table(handcards)
	self:sortByKeepValueInPlace(handcards)
	local usecard = nil
	usecard = handcards[1]
	self:sortInPlace(self.enemies, "defense")
	local target = self.enemies[1]
	if target then
		local card_str = string.format("#DiylijiCard:%d:->%s", usecard:getKnownId(), target:objectName())
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.Diyliji = 5


ai_skill_invoke.godshelie = true

sgs.ai_skill_discard.godshelie = function(self,max,min)
	local player = self.player
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValueInPlace(cards)
	local dis = {}
	if #cards >= 2 then
		table.insert(dis, cards[1]:getEffectiveId())
		table.insert(dis, cards[2]:getEffectiveId())
	end
	return dis
end

ai_skill_choice["godshelie"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	if self.player:getHandcardNum() > 3 then
		return ai_choice_result(("play"), options)
	else
		return ai_choice_result(("draw"), options)
	end

    return ai_choice_result(nil, options)
end


ai_fill_skill.godgongxin=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#godgongxin") then
		return parse(self,"#godgongxin:.:")
	end
end

ai_card_use["#godgongxin"] = function(self, card, use, request)
	self:updatePlayers()
	if #self.enemies <= 0 then return end
	local target = nil
	self:sortInPlace(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in ipairs(self.enemies) do

		target = p
		break
	end
	if not target then return end
	if target then
		local card_str = "#godgongxin:.:->"..target:objectName()
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

ai_skill_use["@@godgongxin"] = function(self, prompt, request)
	local target = tagplayer(self,self.player,"godgongxin")
	if target then
		local target_handcards = sgs.QList2Table(fullhand(target))
		self:sortByUseValueInPlace(target_handcards, source_inverse(self))
		local discard_cards = {}
		local color = nil
		local n = 0
		for _,card in ipairs(target_handcards) do
			if n == 0 then
				table.insert(discard_cards,card:getKnownEffectiveId())
				if card:isRed() then
					color = "red"
				elseif card:isBlack() then
					color = "black"
				end
				n = n + 1
			elseif card:isRed() and color == "red" then
				table.insert(discard_cards,card:getKnownEffectiveId())
				n = n + 1
			elseif card:isBlack() and color == "black" then
				table.insert(discard_cards,card:getKnownEffectiveId())
				n = n + 1
			end
			if n == 2 then break end
		end
		if n > 0 then
			return response(self,"#godgongxindisCard:"..table.concat(discard_cards, "+")..":")
		end
	end
	return "."
end

sgs.ai_use_priority.godgongxin = 3
sgs.ai_use_value.godgongxin = 3
sgs.ai_card_intention.godgongxin = 50


ai_fill_skill.extuifeng=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:canDiscard(self.player, "he") and self.player:getStrategyMark("&extuifeng") > 0 then
		return parse(self,"#extuifengCard:.:")
	end
end

ai_card_use["#extuifengCard"] = function(self, card, use, request)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValueInPlace(cards)
	if #cards > 0 then
		local card_str = string.format("#extuifengCard:%d:", cards[1]:getEffectiveId())
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
	end
end


ai_fill_skill.exqiangwu=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#exqiangwu") then
		return parse(self,"#exqiangwu:.:")
	end
end

ai_card_use["#exqiangwu"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_skill_discard.exqiangwu = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValueInPlace(cards)
	local to_discard = {}
	local min = 13
	local slash = 0
	for _,card in ipairs(cards) do
		if card:isKindOf("Slash") then
			slash = slash + 1
			if card:getNumber() <= 13 then min = card:getNumber() end
		end
	end
	if slash >= 2 then
		for _,card in ipairs(cards) do
			if card:getNumber() <= min then
				table.insert(to_discard,card:getKnownEffectiveId())
				break
			end
		end
	end
	return to_discard
end

sgs.ai_use_priority.exqiangwu = 8


ai_skill_invoke.spyuqi = true

ai_skill_use["@@spyuqi"] = function(self, prompt, request)
	local card_ids = tagids(self,"spyuqicc")
	local getcards = {}
	local choices = {}
	for _,id in sgs.qlist(card_ids) do
		local card = face(self,id)
		table.insert(choices,card)
	end
	self:sortByKeepValueInPlace(choices)
	local target = tagplayer(self,self.player,"spyuqita")
	if (not self:isFriend(target)) then
		table.insert(getcards,choices[1]:getEffectiveId())
	elseif self:isFriend(target) and self.player:objectName() ~= target:objectName() then
		table.insert(getcards,choices[1]:getEffectiveId())
		table.insert(getcards,choices[2]:getEffectiveId())
	elseif self.player:objectName() == target:objectName() then
		for _,card in ipairs(choices) do
			table.insert(getcards,card:getKnownEffectiveId())
		end
	end
	local card_str = "#spyuqi:"..table.concat(getcards, "+")..":"
	return response(self,card_str)
end

sgs.ai_can_damagehp.spyuqi = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to)
end


ai_skill_invoke.spxianjin = true

sgs.ai_skill_playerchosen.spxianjin = function(self, targets)
	local min = 999
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getHandcardNum() < min then
			min = p:getHandcardNum()
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getHandcardNum() == min then
			return p
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.spxianjin = function(self, from, to)
	self:updateIntention(from, to, -40)
end

ai_skill_invoke.spshanshen = true

sgs.ai_skill_playerchosen.spshanshen = function(self, targets)
	local min = 999
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getHandcardNum() < min then
			min = p:getHandcardNum()
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getHandcardNum() == min then
			return p
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.spshanshen = function(self, from, to)
	self:updateIntention(from, to, -40)
end


ai_skill_invoke.shaoyan = true


ai_fill_skill.jitongxin=function(self, options, request)
    local inclusive = options and options.inclusive

	local can = false
	if self.player:getChangeSkillState("jitongxin") <= 1 then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not p:isKongcheng() then
				can = true 
				break
			end
		end
	elseif self.player:getChangeSkillState("jitongxin") == 2 then
		if self.player:getHandcardNum() >= 2 then
			can = true
		end
	end
	if self.player:getStrategyMark("jitongxin-PlayClear") == 0 and can then
		return parse(self,"#jitongxin:.:")
	end
end

ai_card_use["#jitongxin"] = function(self, card, use, request)
	if self.player:getChangeSkillState("jitongxin") <= 1 then
		local target = nil
		self:sortInPlace(self.enemies, "handcard")
		self.enemies = sgs.reverse(self.enemies)
		for _,p in ipairs(self.enemies) do
			if p:getHandcardNum() > 0 then
				target = p
				break
			end
		end
		if not target then
			self:sortInPlace(self.friends, "handcard")
			for _,p in ipairs(self.friends) do
				if p:getHandcardNum() > 0 and p:objectName() ~= self.player:objectName() then
					target = p
					break
				end
			end
		end
		local card_str = string.format("#jitongxin:.:->%s",target:objectName())
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end

	if self.player:getChangeSkillState("jitongxin") == 2 then
		local target = nil
		local usecard = nil
		local handcards = self.player:getCards("h")
		handcards = sgs.QList2Table(handcards)
		self:sortByKeepValueInPlace(handcards)
		local usecard = nil
		for _,card in ipairs(handcards) do
			usecard = card
			break
		end
		self:sortInPlace(self.enemies, "defense")
			for _,p in ipairs(self.enemies) do
				if not self:cantbeHurt(p) and self:damageIsEffective(p) and self:canDamage(p, self.player, nil) then
					target = p
					break
				end
			end
		if not target then
			self:sortInPlace(self.friends, "hp")
			for _,p in ipairs(self.friends) do
				if p:objectName() ~= self.player:objectName() then
					target = p
					break
				end
			end
		end
		if target and usecard then
			local card_str = string.format("#jitongxin:%d:->%s", usecard:getKnownId(), target:objectName())
			local acard = parse(self,card_str)
			assert(acard)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end

ai_skill_use["@@jitongxin"] = function(self, prompt, request)
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("jitongxindraw") and self:isFriend(p) then
			local card_str = "#jitongxinelse:.:"
			return response(self,card_str)
		end
		if p:hasFlag("jitongxinda") and not self:cantbeHurt(p) and self:damageIsEffective(p) and self:canDamage(p, self.player, nil)  then
			local card_str = "#jitongxinelse:.:"
			return response(self,card_str)
		end
	end
	return "."
end

sgs.ai_use_priority.jitongxin = 10


ai_skill_invoke.spjiang = true

ai_fill_skill.spjiang=function(self, options, request)
    local inclusive = options and options.inclusive

	if (self.player:getHandcardNum() > 1) and (not self.player:getStrategyHasUsed("#spjiang")) and ((self.player:getHp() > 1 and self.player:getStrategyMark("sphunzi") > 0) or (self.player:getStrategyMark("sphunzi") ==0)) then
		return parse(self,"#spjiang:.:")
	end
end

ai_card_use["#spjiang"] = function(self, card, use, request)
	local handcards = self.player:getCards("h")
	handcards = sgs.QList2Table(handcards)
	self:sortByKeepValueInPlace(handcards)
	local usecard = {}
	local n = self.player:getHandcardNum()
	local duel
	n = math.ceil(n/2)
	for _,card in ipairs(handcards) do
		table.insert(usecard,card:getKnownEffectiveId())
		
		n = n - 1
		if n <= 0 then break end
	end
	self:sortInPlace(self.enemies, "defense")
	
	
	local target
	duel = named(self,"spjiang","duel",usecard)
	local dummy_use = self:aiUseCard(duel, dummy())
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			target = p
		end
	end

	if target then
		local card_str = string.format("#spjiang:%s:->%s", table.concat(usecard,"+"), target:objectName())
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.spjiang = 4

sgs.ai_canNiepan_skill.sphunzi = function(player)
	return player:hasLordSkill("sphunzi") and player:getStrategyMark("sphunzi") == 0
end


ai_skill_invoke.spyingzi = true


sgs.ai_skill_playerchosen.spyinghun = function(self, targets)
	if self.player:getLostHp() <= 1 then
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and p:getHandcardNum() >= 1 then
				return p
			end
		end
	end
	if self.player:getLostHp() > 1 then
		local n = -1
		local target = nil
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and ((p:getHandcardNum() < n) or n < 0) then
				n = p:getHandcardNum()
				target = p
			end
		end
		if target then return target end
		n = -1
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and ((p:getHandcardNum() < n) or n < 0) then
				n = p:getHandcardNum()
				target = p
			end
		end
		if target then return target end
		return self.player
	end
end

ai_skill_choice["spyinghun"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = tagplayer(self,self.player,"spyinghun")
	choices = choices:split("+")
	if self:isFriend(target) then
		for _,choice in ipairs(choices) do
			if string.find(choice,"draw") then
				return ai_choice_result((choice), options)
			end
		end
	elseif self:isEnemy(target) then
		for _,choice in ipairs(choices) do
			if string.find(choice,"dis") then
				return ai_choice_result((choice), options)
			end
		end
	elseif self.player:objectName() == target:objectName() then
		for _,choice in ipairs(choices) do
			if string.find(choice,"draw") then
				return ai_choice_result((choice), options)
			end
		end
	end

    return ai_choice_result(nil, options)
end


local function fangtongca(self,tasum, card_ids)
	local sum = 0
	local usecards = {}
	if card_ids:length() > 30 then
		for _,id in sgs.qlist(card_ids) do
			local card = face(self,id)
			if (card:getNumber() + sum) <= tasum then
				table.insert(usecards,id)
				sum = sum + card:getNumber()
			end
		end
	else
		local n = card_ids:length()
		local allcards = {}
		for _,id in sgs.qlist(card_ids) do
			table.insert(allcards, id)
		end
		for i = 1, 2^n, 1 do
			sum = 0
			usecards = {}
			for j = 1, n, 1 do
				if (i & (2^j)) ~= 0 then
					table.insert(usecards,allcards[j])
				end
			end
			for _,id in ipairs(usecards) do
				sum = sum + face(self,id):getNumber()
			end
			if sum == tasum then break end
		end
	end

	if sum == tasum then 
		return usecards
	else
		return {}
	end
end

ai_skill_use["@@exfangtong"] = function(self, prompt, request)
	if self.player:isNude() then return "." end
	local card_ids = self.player:getPile("exfang")
	local allcards = {}
	local sum = 0
	local n = 0
	for _,id in sgs.qlist(card_ids) do
		sum = sum + face(self,id):getNumber()
		table.insert(allcards,id)
		n = n + 1
	end
	if sum < 23 then return "." end

	self:sortInPlace(self.enemies, "defense")
	local target = nil
	for _,enemy in ipairs(self.enemies) do
		if enemy:isAlive() and not self:cantDamageMore(self.player, enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil) then
			target = enemy
			break
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if enemy:isAlive() and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil) then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if enemy:isAlive() then
				target = enemy
				break
			end
		end
	end

	if not target then return "." end

	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValueInPlace(cards)
	local usecards = {}
	for _,card in ipairs(cards) do
		sum = 0
		local tem = 36 - card:getNumber()
		usecards = fangtongca(self,tem,card_ids)
		if #usecards > 0 then
			table.insert(usecards,card:getKnownEffectiveId())
		end
		for _,c in ipairs(usecards) do
			sum = sum + face(self,c):getNumber()
		end
		if sum == 36 then break end
	end
	
	if sum ~= 36 then return "." end

	local card_str = "#exfangtongCard:"..table.concat(usecards, "+")..":->"..target:objectName()
	return response(self,card_str)
end


ai_fill_skill.spjilve=function(self, options, request)
    local inclusive = options and options.inclusive

	if (not self.player:getStrategyHasUsed("#spjilve")) and (self.player:getStrategyMark("&spren") > 0) then
		return parse(self,"#spjilve:.:")
	end
end

ai_card_use["#spjilve"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_priority.spjilve = 6
sgs.ai_use_value.spjilve = 6

sgs.ai_skill_playerchosen.spjilve = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and (not p:faceUp()) then
			return p
		end
	end
	self:sortInPlace(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in ipairs(self.enemies) do
		if p:faceUp() then return p end
	end
	return nil
end

sgs.ai_playerchosen_intention.spjilve = function(self, from, to)
	if to:faceUp() then
		self:updateIntention(from, to, 80)
	else
		self:updateIntention(from, to, -80)
	end
end

ai_skill_invoke.spjilve = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getStrategyMark("spjilvejudge") > 0 then
		if self.player:getStrategyMark("&spren") < 3 then return (false) or false end
		local judge = tagjudge(self,"spjilvejudge")
		local can = false
		if judge.reason == "indulgence" then
			if self:isFriend(judge.who) and judge.card:getSuitString() ~= "heart" then
				can = true
			elseif self:isEnemy(judge.who) and judge.card:getSuitString() == "heart" then
				can = true
			end
		elseif judge.reason == "supply_shortage" then
			if self:isFriend(judge.who) and judge.card:getSuitString() ~= "club" then
				can = true
			elseif self:isEnemy(judge.who) and judge.card:getSuitString() == "club" then
				can = true
			end
		elseif judge.reason == "lightning" then
			if self:isFriend(judge.who) and judge.card:getSuitString() == "spade" and judge.card:getNumber() >= 2 and judge.card:getNumber() <= 9 then
				can = true
			elseif self:isEnemy(judge.who) and ((judge.card:getSuitString() ~= "spade") or (judge.card:getSuitString() == "spade" and (judge.card:getNumber() < 2 and judge.card:getNumber() > 9))) then
				can = true
			end
		elseif judge.reason == "eight_diagram" then
			if self:isFriend(judge.who) and judge.card:isBlack() then
				can = true
			elseif self:isEnemy(judge.who) and judge.card:isRed() then
				can = true
			end
		end
		return (can) or false 
	end

	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHp() <= 0 and self:isEnemy(p) then
			return (true) or false
		end
	end
	return (false) or false
end

ai_skill_choice["spjilve"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local judge = tagjudge(self,"spjilvejudge")

	if judge.reason == "indulgence" then
		if self:isFriend(judge.who) and string.find(choices,"heart") then
			return ai_choice_result(("heart"), options)
		elseif self:isEnemy(judge.who) and string.find(choices,"heart") then
			return ai_choice_result(("diamond"), options)
		end
	elseif judge.reason == "supply_shortage" then
		if self:isFriend(judge.who) and string.find(choices,"club") then
			return ai_choice_result(("club"), options)
		elseif self:isEnemy(judge.who) and string.find(choices,"club") then
			return ai_choice_result(("diamond"), options)
		end
	elseif judge.reason == "lightning" then
		if self:isFriend(judge.who) and string.find(choices,"club") then
			return ai_choice_result(("diamond"), options)
		elseif self:isEnemy(judge.who) and string.find(choices,"club") then
			return ai_choice_result(("spade"), options)
		elseif self:isEnemy(judge.who) and string.find(choices,"5") then
			return ai_choice_result(("5"), options)
		end
	elseif judge.reason == "eight_diagram" then
		if self:isFriend(judge.who) and string.find(choices,"diamond") then
			return ai_choice_result(("diamond"), options)
		elseif self:isEnemy(judge.who) and string.find(choices,"club") then
			return ai_choice_result(("club"), options)
		end
	end

	local canchoose = choices:split("+")
	return ai_choice_result((canchoose[1]), options)
end

sgs.ai_need_damaged.spjilve = function (self, attacker, player)
	if not player:hasSkill("spjilve") then return end

	local will = false
	for _, p in ipairs(self.enemies) do
		if p:faceUp() then
			will = true
			break
		end
	end
	for _,p in ipairs(self.friends) do
		if not p:faceUp() then
			will = true
			break
		end
	end
	local n = self.player:getHp() + self:getCardsNum("Analeptic") + self:getCardsNum("Peach")

	return n > 2 and will
end







ai_skill_choice["splianpo"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	if self.player:getHp() == 1 then return ai_choice_result(("redr"), options) end
	local canchoose = choices:split("+")
	return ai_choice_result((canchoose[1]), options)
end


ai_fill_skill.sppingxiang=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyMark("sppingxiang") == 0 and self.player:getMaxHp() >= 10 then
		return parse(self,"#sppingxiang:.:")
	elseif self.player:getMaxHp() > 4 and (not self.player:getStrategyHasUsed("#sppingxiangSlash")) and self.player:getStrategyMark("sppingxiang") > 0 then
		return parse(self,"#sppingxiangSlash:.:")
	end
end

ai_card_use["#sppingxiang"] = function(self, card, use, request)
	use.card = card
end

ai_card_use["#sppingxiangSlash"] = function(self, card, use, request)
	local qtargets = sgs.PlayerList()
    
    local slash = named(self,"sppingxiang","fire_slash",{})

	self:sortInPlace(self.enemies, "defense")
	local target = {}
	for _,enemy in ipairs(self.enemies) do
		if enemy:isAlive() and slash:targetFilter(qtargets, enemy, self.player) and (not self.player:isProhibited(enemy, slash, qtargets)) and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)  then
			qtargets:append(enemy)
			table.insert(target,enemy:objectName())
		end
	end
	
	if #target > 0 then
		local card_str = string.format("#sppingxiangSlash:.:->%s", table.concat(target,"+"))
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to = qtargets
		end
	end
end

ai_skill_use["@@sppingxiang"] = function(self, prompt, request)
	local qtargets = sgs.PlayerList()
    
    local slash = named(self,"sppingxiang","fire_slash",{})

	self:sortInPlace(self.enemies, "defense")
	local target = {}
	for _,enemy in ipairs(self.enemies) do
		if enemy:isAlive() and slash:targetFilter(qtargets, enemy, self.player) and (not self.player:isProhibited(enemy, slash, qtargets)) then
			qtargets:append(enemy)
			table.insert(target,enemy:objectName())
		end
	end
	
	if #target > 0 then
		local card_str = string.format("#sppingxiangSlash:.:->%s", table.concat(target,"+"))
		return response(self,card_str)
	else 
		return "."
	end
end


ai_skill_invoke.spjiufa = true



ai_skill_use["@@spjiufa"] = function(self, prompt, request)
	local card_ids = tagids(self,"spjiufalist")
	local canuse = {}
    for _,id in sgs.qlist(card_ids) do
        local card = face(self,id)
        if card:isAvailable(self.player) then
            table.insert(canuse, card)
        end
    end
    if #canuse == 0 then return "." end

	self:sortByUseValueInPlace(canuse)
    for _,card in ipairs(canuse) do

		local use = {isDummy=true,to=sgs.SPlayerList()}
		self:useCardByClassName(card, use)
        if use.card then
            if use.to and use.to:length() > 0 then
                local tos = {}
                for _,p in sgs.qlist(use.to) do
                    table.insert(tos, p:objectName())
                end

				return response(self,string.format("#spjiufa:%s:->%s", card:getKnownId(), table.concat(tos,"+")))
            end
        end
    end
    return "."
end


sgs.ai_skill_playerchosen.miyund = function(self, targets)
	if self.player:hasFlag("miyunget") then
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) then
				return p
			end
		end
	elseif self.player:hasFlag("miyungive1") then
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) then
				return p
			end
		end
	elseif self.player:hasFlag("miyungive2") then
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) then
				return p
			end
		end
		return nil
	end
	for _,p in sgs.qlist(targets) do
		return p
	end
end

sgs.ai_use_revises.miyund = function(self,card,use)
	if card:hasFlag("miyunsafe") and self.player:getHp() > 1 then
		return false 
	end
end

sgs.ai_cardneed.miyund = function(to,card,self)
	return card:hasFlag("miyunsafe")
end
sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|miyund"

ai_fill_skill.danyind=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyMark("danyind-Clear") > 0 then return end
	local handcards = self.player:getCards("he")
	handcards = self:sortByKeepValueInPlace(handcards)
	if self:getCardsNum("Peach") == 0 then
		for _, h in ipairs(handcards) do
			if h:hasFlag("miyunsafe") then
				local slash = named(self,"danyind","Peach",{})
				if slash:isAvailable(self.player)
				then return slash end
			end
		end
	end
	if self:getCardsNum("Slash") == 0 then
		for _, h in ipairs(handcards) do
			if h:hasFlag("miyunsafe") then
				local slash = named(self,"danyind","Slash",{})
				if slash:isAvailable(self.player)
				then return slash end
			end
		end
	end
end

sgs.ai_guhuo_card.danyind = function(self,toname,class_name)
    if self.player:getStrategyMark("danyind-Clear") > 0 then return end
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
	else
		if class_name and self:getCardsNum(class_name) > 0 then return end
	end
	local card = evaluation(self,toname)
	
	if (not card) or (not card:isKindOf("BasicCard")) then return end
	local handcards = self.player:getCards("he")
	handcards = self:sortByKeepValueInPlace(handcards)
	for _, h in ipairs(handcards) do
		if h:hasFlag("miyunsafe") then
			local slash = named(self,"danyind",toname,{})
			return descriptor(slash)
		end
	end
end

sgs.ai_card_priority.danyind = function(self,card)
	if card:hasFlag("miyunsafe")
	then return -0.05 end
end


ai_skill_invoke.sphaochong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getHandcardNum() == 0 then return (true) or false end
	if self.player:getPhase() ~= sgs.Player_NotActive then return (true) or false end
	local n = 0
	local cards = {"peach", "jink", "analeptic", "nullification"}
	for _,p in sgs.qlist(self.player:getHandcards()) do
		if table.contains(cards, p:objectName()) then
			n = n + 1
		end
	end
	if n < 2 then return (true) or false end
    return (false) or false 
end

ai_skill_invoke.spjinjin = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getHandcardNum() < self.player:getMaxCards() then
		return (true) or false
	elseif self.player:getHandcardNum() > self.player:getMaxCards() then
		local n = self.player:getHandcardNum() - self.player:getMaxCards()
		if n > 2 then return (false) or false end
		return (true) or false
	end
    return (false) or false 
end
ai_skill_choice["spjinjin"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local source = data:toPlayer()
	local items = choices:split("+")
	if #items == 1 then
		return ai_choice_result((items[1]), options)
	else
		if table.contains(items, "recover") and self:isWeak(source) and source:isWounded() and source:getHp() < getBestHp(source) then
			return
			ai_choice_result(("recover"), options)
		end
		local choice1 = getChoice(choices, "damage")
		if choice1 and ((self:isFriend(source) and self:needToLoseHp(source, self.player, nil)) or (self:isEnemy(source) and not self:cantbeHurt(source) and self:damageIsEffective(source, sgs.DamageStruct_Normal) and self:canDamage(source, self.player, nil))) then
			return ai_choice_result((choice1), options)
		end
	end
	return ai_choice_result(("recover"), options)
end

sgs.ai_can_damagehp.spjinjin = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to) and ((self.player:getMaxCards() - self.player:getHandcardNum() > 2) or ((self.player:getHandcardNum() -  self.player:getMaxCards()> 0) and from and self:isEnemy(from) and self:isWeak(from) and self:damageIsEffective(from, sgs.DamageStruct_Normal)))
end


ai_skill_invoke.spjinjin = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getHandcardNum() < self.player:getMaxCards() then return (true) or false end
	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("spjinjintarget") then
			target = p
			break
		end
	end
	local save = self:getCardsNum("Analeptic") + self:getCardsNum("peach")
	local n = self.player:getHandcardNum() - self.player:getMaxCards()
	if self.player:isWounded() then
		if n <= 1 then return (true) or false end
		if self.player:getMaxCards() + 1 >= save then return (true) or false end
		if self.player:containsTrick("indulgence") and self.player:getHp() <= 1 and self:getCardsNum("Nullification") < 1 then return (true) or false end
	end
	if not target then
		return (false) or false 
	elseif target then
		if self:isEnemy(target) and n <= 2 then return (true) or false end
	end
	return (false) or false
end

ai_skill_choice["spjinjin"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("spjinjintarget") then
			target = p
			break
		end
	end
	if target and self:isEnemy(target) and target:getHp() <= 1 and self.player:getLostHp() < 2 then
		for _,choice in ipairs(choices:split("+")) do
			if string.find(choice, "damage") then
				return ai_choice_result((choice), options)
			end
		end
	end
	if (self.player:getLostHp() >= 2) or (not target) then
		for _,choice in ipairs(choices:split("+")) do
			if string.find(choice, "recover") then
				return ai_choice_result((choice), options)
			end
		end
	end
	if target and self:isEnemy(target) then
		for _,choice in ipairs(choices:split("+")) do
			if string.find(choice, "damage") then
				return ai_choice_result((choice), options)
			end
		end
	end
	for _,choice in ipairs(choices:split("+")) do
		return ai_choice_result((choice), options)
	end

    return ai_choice_result(nil, options)
end


ai_fill_skill.hfgushi=function(self, options, request)
    local inclusive = options and options.inclusive

	local card = nil
	if self.player:getStrategyMark("&hfgushi-PlayClear") == 0 then
		card = self:evaluateOwnerViewAsCard({source_key="hfgushi",name="peach",skill="hfgushi",suit=sgs.Card_SuitToBeDecided,number=-1,subcards={}})
	elseif self.player:getStrategyMark("&hfgushi-PlayClear") == 1 then
		card = self:evaluateOwnerViewAsCard({source_key="hfgushi",name="ex_nihilo",skill="hfgushi",suit=sgs.Card_SuitToBeDecided,number=-1,subcards={}})
	elseif self.player:getStrategyMark("&hfgushi-PlayClear") == 2 then
		card = self:evaluateOwnerViewAsCard({source_key="hfgushi",name="duel",skill="hfgushi",suit=sgs.Card_SuitToBeDecided,number=-1,subcards={}})
	end
	if not card then return end
	
	if card and card:isAvailable(self.player) then
		local card_str = nil
		if self.player:getStrategyMark("&hfgushi-PlayClear") == 0 then
			card_str = string.format("peach:hfgushi[%s:%s]=.", "no_suit", 0)
		elseif self.player:getStrategyMark("&hfgushi-PlayClear") == 1 then
			card_str = string.format("ex_nihilo:hfgushi[%s:%s]=.", "no_suit", 0)
		elseif self.player:getStrategyMark("&hfgushi-PlayClear") == 2 then
			card_str = string.format("duel:hfgushi[%s:%s]=.", "no_suit", 0)
		end
		local spec = printed(card_str,self)
        local classes={peach="Peach",ex_nihilo="ExNihilo",duel="Duel"}
        local usec = self:evaluateTurnConversion("hfgushi", classes[spec.name], spec, request)
		return usec
	end
end

sgs.ai_card_priority.hfgushi = function(self,card)
	if table.contains(card:getSkillNames(), "hfgushi")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_use_priority.hfgushi = sgs.ai_use_priority.Peach + 0.1


sgs.ai_skill_askforag["hflanggu"] = function(self, card_ids)
	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("hflanggutarget") then
			target = p
			break
		end
	end
	local can = false
	for _,id in ipairs(card_ids) do
		local card = face(self,id)
		if card:getSuitString() == "spade" and card:getNumber() >= 2 and card:getNumber() <= 9 then
			can = true
		end
	end
	if not can  then
		local choosecards = {}
		for _,id in ipairs(card_ids) do
			local card = face(self,id)
			table.insert(choosecards,card)
		end

		self:sortByKeepValueInPlace(choosecards, true)
    	return choosecards[#choosecards]:getEffectiveId()
	else 
		if self:isEnemy(target) then
			for _,id in ipairs(card_ids) do
				local card = face(self,id)
				if card:getSuitString() == "spade" and card:getNumber() >= 2 and card:getNumber() <= 9 then
				else return id end
			end
		else
			for _,id in ipairs(card_ids) do
				local card = face(self,id)
				if card:getSuitString() == "spade" and card:getNumber() >= 2 and card:getNumber() <= 9 then
					return id 
				end
			end
		end
	end
end


ai_fill_skill.dyizheng=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#dyizheng") then return end
	return parse(self,"#dyizheng:.:")
end

ai_card_use["#dyizheng"] = function(self, card, use, request)
	local max_card = self:getMaxCard()
	if not max_card then return end
	local point = max_card:getNumber()
	if self.player:hasSkill("tianbian") and max_card:getSuit() == sgs.Card_Heart then point = 13 end
	-- Same truth table as the donor: the SwapPile room tag (not projected) only decides below 7.
	if point >= 7 or (self.player:getHp() > 2 and ai_unsupported("SwapPile room tag is not projected","SwapPile")) then
		self:sortInPlace(self.enemies, "handcard")
		for _, p in ipairs(self.enemies) do
			if not self.player:canPindian(p)  then continue end
			local card_str = string.format("#dyizheng:.:->%s",p:objectName())
			local acard = parse(self,card_str)
			assert(acard)
			use.card = acard
			if use.to then
				use.to:append(p)
			end
			return
		end
	end
end

function sgs.ai_skill_pindian.dyizheng(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber() < 6 and  minusecard or maxcard )
end

sgs.ai_use_priority.dyizheng = 6
sgs.ai_use_value.dyizheng = 2
sgs.ai_card_intention["#dyizheng"] = 50


ai_skill_invoke.drangjie = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if not self.room:canMoveField("ej") and not self:canDraw() then return (false) or false end
	if self:canDraw() then return (true) or false end
	local from, card, to = self:moveField()
	if from and card and to then return (true) or false end
	return (false) or false
end

ai_skill_choice.drangjie = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	choices = choices:split("+")
	if table.contains(choices, "move") then
		local from, card, to = self:moveField()
		if from and card and to then return ai_choice_result(("move"), options) end
		return ai_choice_result(("draw"), options)
	else
		return ai_choice_result(("hand"), options)
	end

    return ai_choice_result(nil, options)
end

ai_skill_use["@@drangjie"] = function(self, prompt, request)
	local card_ids = tagids(self,"drangjiecards")
	local cards = {}
	for _,id in sgs.qlist(card_ids) do
		table.insert(cards,face(self,id))
	end

	self:sortByKeepValueInPlace(cards)
	local card_str = "#drangjie:"..cards[#cards]:getEffectiveId()..":"
	return response(self,card_str)
end

sgs.ai_skill_playerchosen.drangjie = function(self, targets)
	self:sortInPlace(self.friends, "defense")
	return self.friends[1]
end

sgs.ai_playerchosen_intention.drangjie = function(self, from, to)
	if from:hasFlag("drangjiejud") then
		self:updateIntention(from, to, 60)
	else
		self:updateIntention(from, to, -60)
	end
end

sgs.ai_can_damagehp.drangjie = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to)
end


ai_fill_skill.dwzhizhe=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyMark("dwzhizheused") == 0 then
		local names = {"peach", "nullification", "archery_attack", "savage_assault", "snatch", "fire_attack", "duel", "dismantlement"}
		if self.player:getHandcardNum() == 0 then return end
		for _,card in sgs.qlist(self.player:getHandcards()) do
			if table.contains(names, card:objectName()) then
				return parse(self,"#dwzhizhe:.:")
			end
		end
		return
	end
	if self.player:getStrategyMark("dwzhizhe-Clear") > 0 then return end
	local pattern = prop(self,"dwzhizheshow")
	local card_str = string.format("%s:dwzhizhe[%s:%s]=.", pattern,"no_suit", 0)
	local usec = parse(self,card_str)
	assert(usec)
	return usec
end

ai_card_use["#dwzhizhe"] = function(self, card, use, request)
	local handcards = self.player:getCards("h")
	handcards = sgs.QList2Table(handcards)
	local usecard
	self:sortByUseValueInPlace(handcards, source_inverse(self))
	local names = {"peach", "nullification", "archery_attack", "savage_assault", "snatch", "fire_attack", "duel", "dismantlement"}
	for _,card in ipairs(handcards) do
		if table.contains(names, card:objectName()) then
			usecard = card
			break
		end
	end

	if usecard then
		local card_str = string.format("#dwzhizhe:%d:", usecard:getKnownId())
		local acard = parse(self,card_str)
		assert(acard)
		use.card = acard
	end
end

sgs.ai_cardsview_valuable.dwzhizhe = function(self, class_name, player)
	if self.player:getStrategyMark("dwzhizhe-Clear") > 0 then return end
	if self.player:getStrategyMark("dwzhizheused") == 0 then return end
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
		["Nullification"] = "nullification",
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local pattern = prop(self,"dwzhizheshow")
	if string.find(pattern, name) or pattern == name or string.find(name, pattern) then
		return view(self,string.format("%s:dwzhizhe[%s:%s]=.", pattern,"no_suit", 0))
	end
	return
end

sgs.ai_use_priority.dwzhizhe = 8

sgs.ai_card_priority.dwzhizhe = function(self,card)
	if table.contains(card:getSkillNames(), "dwzhizhe")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end


ai_skill_invoke.dwqingshi = true

ai_skill_choice["dwqingshi"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	choices = choices:split("+")
	local names = {"slash", "thunder_slash", "fire_slash", "fire_attack", "duel", "archery_attack", "savage_assault"}

	if self.player:getStrategyMark("dwqingshiuseai") > 0 then
		local use = taguse(self,"dwqingshiuseai")
		if not table.contains(names,use.card:objectName()) then
			local canuse = false
			local num = 0
			for _,card in sgs.qlist(self.player:getHandcards()) do
				if not card:isAvailable(self.player) then break end
				canuse = true
				if card:objectName() == use.card:objectName() then num = num + 1 end
			end
			if (#self.friends == 2 and self.player:getHandcardNum() >3)
			or (#self.friends > 2) 
			or (canuse and num > 1) then
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawall") then
						return ai_choice_result((choice), options)
					end
				end
			else
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawself") then
						return ai_choice_result((choice), options)
					end
				end
			end
		else
			local canuse = false
			local num = 0
			for _,card in sgs.qlist(self.player:getHandcards()) do
				if not card:isAvailable(self.player) then break end
				canuse = true
				if card:objectName() == use.card:objectName()
				or (card:isKindOf("Slash") and use.card:isKindOf("Slash"))
				then num = num + 1 end
			end
			local enemynum = 0
			local weakenemy = false
			for _,p in sgs.qlist(use.to) do
				if self:isEnemy(p) then
					enemynum = enemynum + 1
					if p:getHp() <= 2 or p:getHandcardNum() <= 2 then
						weakenemy = true
					end
				end
			end
			if (enemynum > 1) or (canuse and num > 1) or weakenemy then
				for _,choice in ipairs(choices) do
					if string.find(choice, "damage") then
						return ai_choice_result((choice), options)
					end
				end
			end

			if (#self.friends == 2 and self.player:getHandcardNum() >3)
			or (#self.friends > 2) 
			or (canuse and num > 1) then
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawall") then
						return ai_choice_result((choice), options)
					end
				end
			else
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawself") then
						return ai_choice_result((choice), options)
					end
				end
			end
		end
	else
		if (#self.friends == 2 and self.player:getHandcardNum() >3)
			or (#self.friends > 2) then
			for _,choice in ipairs(choices) do
				if string.find(choice, "drawall") then
					return ai_choice_result((choice), options)
				end
			end
		else
			for _,choice in ipairs(choices) do
				if string.find(choice, "drawself") then
					return ai_choice_result((choice), options)
				end
			end
		end
	end
	return ai_choice_result((choices[math.random(1,#choices)]), options)
end

ai_skill_use["@@dwqingshi"] = function(self, prompt, request)
	local targets = {}
	if self.player:hasFlag("dwqingshidrawall") then
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) then
				table.insert(targets,p:objectName())
			end
		end
	elseif self.player:hasFlag("dwqingshidamage") then
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isEnemy(p) and p:hasFlag("dwqingshiupcan") then
				table.insert(targets,p:objectName())
			end
		end
	end
	if #targets > 0 then
		local card_str = string.format("#dwqingshi:.:->%s", table.concat(targets,"+"))
		return response(self,card_str)
	else 
		return "."
	end
end

sgs.ai_card_intention.dwqingshi = function(self, card, from, tos)
	if from:hasFlag("dwqingshidrawall") then
		for _,to in ipairs(tos) do
			self:updateIntention(from, to, -40)
		end
	else
		for _,to in ipairs(tos) do
			self:updateIntention(from, to, 60)
		end
	end
end
sgs.ai_ajustdamage_from.dwqingshi = function(self, from, to, card, nature)
	if card and card:hasFlag("dwqingshidamage") then
		local names = cardtag(self,card,"dwqingshitarget"):split("+")
		if table.contains(names, to:objectName()) then
			return 1
		end
	end
end


ai_skill_invoke.dwjingcui = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHp() <= 0 then
			target = p
			break
		end
	end
	if not self:isFriend(target) then return (false) or false end
	local n = nil
	if target:objectName() ~= self.player:objectName() then
		n = self:getCardsNum("Peach")
		for _,card in sgs.qlist(fullhand(target)) do
			if card:objectName() == "peach" or card:objectName() == "analeptic" then n = n + 1 end
		end
		if self.player:getStrategyMark("dwzhizheused") > 0 then
			if self.player:getStrategyMark("dwzhizhe-Clear") == 0 then
				local pattern = prop(self,"dwzhizheshow")
				if pattern == "peach" then n = n + 1 end
			end
		end
	else
		n = self:getCardsNum("Peach") + self:getCardsNum("Analeptic")
		if self.player:getStrategyMark("dwzhizheused") > 0 then
			if self.player:getStrategyMark("dwzhizhe-Clear") == 0 then
				local pattern = prop(self,"dwzhizheshow")
				if pattern == "peach" or pattern == "analeptic" then n = n + 1 end
			end
		end
	end
	if n >= 1 - target:getHp() then return (false) or false end
	return (true) or false
end


sgs.ai_skill_playerchosen.spzhiheng =  function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self.player:getStrategyMark("spzhihenggood") > 0 then
			if self:isFriend(p) then return p end
		elseif self:isEnemy(p) then return p end
	end
	return nil
end

sgs.ai_playerchosen_intention.spzhiheng = function(self, from, to)
	if from:getStrategyMark("spzhihenggood") > 0 then
		self:updateIntention(from, to, -80)
	else
		self:updateIntention(from, to, 80)
	end
end


ai_skill_invoke.shouchang = true

sgs.ai_skill_discard.shouchang = function(self,max,min)
	local dis = {}
	local red = {}
    local black = {}
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isRed() then
            table.insert(red, card)
        elseif card:isBlack() then
            table.insert(black, card)
        end
    end


	if self.player:getPhase() ~= sgs.Player_NotActive then
		self:sortByUseValueInPlace(red, true)
		self:sortByUseValueInPlace(black, true)
	else
		self:sortByKeepValueInPlace(red)
		self:sortByKeepValueInPlace(black)
	end
	if self.player:getPhase() == sgs.Player_Play and self.player:getHandcardNum() > 10 and #red > 0 then
		table.insert(dis, red[1]:getEffectiveId())
		return dis
	end
	if #red > #black then
		table.insert(dis, red[1]:getEffectiveId())
	elseif #black > #red then
		table.insert(dis, black[1]:getEffectiveId())
	end
	return dis
end


ai_skill_choice["Djianxiong"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	choices = choices:split("+")
	if self.player:getLostHp() <= 2 and self.player:getHandcardNum() <= 2 then
		return ai_choice_result(("draw"), options)
	end
	if table.contains(choices, "recover") then
		return ai_choice_result(("recover"), options)
	end
	return ai_choice_result((choices[1]), options)
end

sgs.ai_can_damagehp.Djianxiong = function(self, from, card, to)
	return  (card and not card:isKindOf("SkillCard"))
		and self:canLoseHp(from, card, to)
end


sgs.ai_skill_playerchosen.dmwumei = function(self,players)
	local destlist = players
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
	self:sortInPlace(destlist, "handcard", true)
	for _,target in sgs.list(destlist)do
		if self:isFriend(target) and target:getHandcardNum() > self.player:getHandcardNum() + 2
		then return target end
	end
	return self.player
end

sgs.ai_playerchosen_intention.dmwumei = function(self, from, to)
	self:updateIntention(from, to, -100)
end


ai_skill_invoke.dmzhanmeng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local allchoices = {"recover", "draw", "discard"}
    local choices = {}
    for _,cc in ipairs(allchoices) do
        if self.player:getStrategyMark("dmzhanmeng"..cc.."-Clear") == 0 then
            table.insert(choices, cc)
        end
    end
	if table.contains(choices, "recover") then
		local wumeiextra = false
		local wounded = false
		local danger = false
		local nofaceup = false
		local chained = false
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getStrategyMark("&dmwumei-SelfClear") > 0 then wumeiextra = true end
			if self:isFriend(p) then
				if p:isWounded() then
					wounded = true
					if p:getHp() == 1 then danger = true end
				end
				if p:isChained() then chained = true end
				if not p:faceUp() then nofaceup = true end
			end
		end
		if nofaceup or ((not wumeiextra) and wounded) or chained or (wumeiextra and danger) then return (true) or false end
	end
	if table.contains(choices, "draw") then return (true) or false end
	if table.contains(choices, "discard") then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isEnemy(p) and p:canDiscard(p, "he")  and self:damageIsEffective(p, sgs.DamageStruct_Fire) and not self:cantbeHurt(p) and self:canDamage(p, self.player, nil) then return (true) or false end
		end
	end
	return (false) or false
end

ai_skill_choice.dmzhanmeng = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")

	local wumeiextra = false
	local wounded = false
	local danger = false
	local nofaceup = false
	local chained = false
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getStrategyMark("&dmwumei-SelfClear") > 0 then wumeiextra = true end
		if self:isFriend(p) then
			if p:isWounded() then
				wounded = true
				if p:getHp() == 1 then danger = true end
			end
			if p:isChained() then chained = true end
			if not p:faceUp() then nofaceup = true end
		end
	end
		
	if table.contains(items, "recover") then
		if nofaceup or danger then return ai_choice_result(("recover"), options) end
	end

	if table.contains(items, "draw") and wumeiextra then return ai_choice_result(("draw"), options) end

	if table.contains(items, "discard") then
		for _,p in ipairs(self.enemies) do
			if p:canDiscard(p, "he") then return ai_choice_result(("discard"), options) end
		end
	end

	if table.contains(items, "recover") then
		if wounded and (not wumeiextra) then return ai_choice_result(("recover"), options) end
	end

	if table.contains(items, "draw") then return ai_choice_result(("draw"), options) end

	if table.contains(items, "recover") then
		if chained then return ai_choice_result(("recover"), options) end
	end

	return ai_choice_result((items[math.random(1, #items)]), options)
end

sgs.ai_playerchosen_intention.dmzhanmeng = function(self, from, to)
	if from:hasFlag("dmzhanmenggood") then
		self:updateIntention(from, to, -80)
	else
		self:updateIntention(from, to, 100)
	end
end

sgs.ai_skill_playerchosen.dmzhanmeng = function(self, targets)
	if self.player:hasFlag("dmzhanmenggood") then
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and (not p:faceUp()) then return p end
		end
		local min = -1
		local target = nil
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and ((min == - 1) or p:getHp() < min) and p:isWounded() then
				target = p
				min = p:getHp()
			end
		end
		if target then return target end
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and p:isChained() then return p end
		end
	else
		self:sortInPlace(self.enemies, "defense")
		for _,p in ipairs(self.enemies) do
			if p:canDiscard(p, "he") then return p end
		end
		for _,p in sgs.qlist(targets) do
			if not self:isFriend(p) then return p end
		end
	end
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|dmshenyou"


ai_fill_skill.godlongnu=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValueInPlace(cards, true)
	for _, card in ipairs(cards) do

		local slash = nil

		if card:isRed() and ((self.player:getStrategyMark("&godlongnu+:+fire_slash-PlayClear") > 0) or (self.player:getStrategyMark("&godlongnuall-PlayClear") > 0) ) then
			slash = self:evaluateTurnConversion("godlongnu", "FireSlash", {name="fire_slash",skill="godlongnu",suit=-1,number=-1,subcards={card:getKnownEffectiveId()}}, request)
			if not slash:isAvailable(self.player) then slash = nil end
		end

		if card:isBlack() and ((self.player:getStrategyMark("&godlongnu+:+thunder_slash-PlayClear") > 0) or (self.player:getStrategyMark("&godlongnuall-PlayClear") > 0) ) then
			slash = self:evaluateTurnConversion("godlongnu", "ThunderSlash", {name="thunder_slash",skill="godlongnu",suit=-1,number=-1,subcards={card:getKnownEffectiveId()}}, request)
			if not slash:isAvailable(self.player) then slash = nil end
		end

		if slash and card:isRed() then
			local spec=printed(("fire_slash:godlongnu[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getKnownId()),self)
			return self:evaluateTurnConversion("godlongnu", "FireSlash", spec, request)
		elseif slash and card:isBlack() then
			local spec=printed(("thunder_slash:godlongnu[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getKnownId()),self)
			return self:evaluateTurnConversion("godlongnu", "ThunderSlash", spec, request)
		end
	end
end

ai_skill_choice["godlongnu"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local n = self.player:getHp() + self:getCardsNum("Peach") + self:getCardsNum("Analeptic")
	if #self.enemies > 0 and n > 1 and self.player:getMaxHp() > 2 then
		self:sortInPlace(self.enemies, "defense")
		for _,p in ipairs(self.enemies) do
			if p:getHp() <= 2 then
				return ai_choice_result(("all"), options)
			elseif p:getHandcardNum() < 2 and p:getHp() <= 3 then
				return ai_choice_result(("all"), options)
			end
		end
		for _,cc in sgs.qlist(self.player:getHandcards()) do
			if cc:objectName() == "crossbow" then return ai_choice_result(("all"), options) end
		end
		for _,cc in sgs.qlist(self.player:getEquips()) do
			if cc:objectName() == "crossbow" then return ai_choice_result(("all"), options) end
		end
	end
	if self.player:getLostHp() < 3 and self.player:getHp() > 1 then return ai_choice_result(("red"), options) end
	if self.player:getLostHp() >= 3 then return ai_choice_result(("black"), options) end
	if self.player:getHp() == 1 and (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0) then return ai_choice_result(("red"), options) end
	if self.player:getHp() == 1 and self.player:isWounded() then return ai_choice_result(("black"), options) end
	if self.player:getMaxHp() == 1 then return ai_choice_result(("red"), options) end
	choices = choices:split("+")
	table.removeOne(choices, "all")
	return  ai_choice_result((choices[math.random(1, #choices)]), options)
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|godlongnu"


sgs.ai_skill_playerchosen.godjieyin = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then return p end
	end
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then return p end
	end
	for _,p in sgs.qlist(targets) do
		return p
	end
end
sgs.ai_target_revises.godjieyin = function(to,card,self,use)
    if card:isKindOf("IronChain") then return true end
end


sgs.ai_playerchosen_intention.godjieyin = function(self, from, to)
	self:updateIntention(from, to, 30)
end

sgs.ai_suppress_intention["xiaoyizi"] = true
sgs.ai_skill_playerchosen.xiaorenfu = function(self, targets)
	if self.player:hasFlag("xiaoyifu") then
		local slash = named(self,"_xiaoyizi","slash",{})
		
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and self:slashIsEffective(slash, p, self.player) and self:isGoodTarget(p, self.enemies, slash) then return p end
		end
		return nil
	end
	local max = -1
	local yifu = nil
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) and (max == -1 or (p:getHandcardNum() + p:getEquips():length() > max)) then
			yifu = p
			max = p:getHandcardNum() + p:getEquips():length()
		end
	end
	if yifu then return yifu end
	for _,p in sgs.qlist(targets) do
		return p
	end
end

sgs.ai_playerchosen_intention.xiaorenfu = function(self, from, to)
	self:updateIntention(from, to, 80)
end

ai_skill_invoke.xiaorenfu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = nil
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("old_yifuta") then
			target = p
			break
		end
	end
	if target and (not self:isFriend(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and not self:cantbeHurt(target) and self:canDamage(target, self.player, nil)) then return (true) or false end
	return (false) or false
end

sgs.ai_ajustdamage_from.xiaorenfu = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and from and to:getStrategyMark("xiaoyifufrom"..from:objectName()) > 0
	then
		return 1
	end
end


ai_skill_invoke.xiaosheji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local from = nil
	local to = nil
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("shejifrom") then
			from = p
		elseif p:hasFlag("shejito") then
			to = p
		end
	end
	local slash = named(self,"xiaosheji","slash",{})
	if (not self:isFriend(from)) and (not self:isEnemy(to) and self:slashIsEffective(slash, from, self.player) and self:isGoodTarget(from, self.enemies, slash)) then return (true) or false end
	return (false) or false
end


sgs.ai_skill_playerchosen.doubleneifa = function(self, targets)
	if self.player:hasSkill("doubleneifa") then
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and p:getJudgingArea():length() > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and p:getEquips():length() > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and p:getStrategyMark("&doubleneifa") > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if not self:isFriend(p) then return p end
		end
		for _,p in sgs.qlist(targets) do
			return p
		end
	else
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and p:getJudgingArea():length() > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if not self:isFriend(p) then return p end
		end
		if self.player:getHandcardNum() > 1 then return self.player end
		return nil
	end
end

sgs.ai_playerchosen_intention.doubleneifa = function(self, from, to)
	if to:getJudgingArea():length() > 0 then
		self:updateIntention(from, to, -40)
	else
		self:updateIntention(from, to, 40)
	end
end


sgs.ai_skill_askforag["wwguixin"] = function(self, card_ids)
	local cards = {}
	for _,id in ipairs(card_ids) do
		local card = face(self,id)
		table.insert(cards, card)
	end

	self:sortByKeepValueInPlace(cards)
    return cards[1]:getEffectiveId()
end


ai_fill_skill.jfjifeng=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyMark("jfjifengfailed-PlayClear") > 0 then return end
	local fire_attack = named(self,"jfjifeng","fire_attack",{})
	if fire_attack and fire_attack:isAvailable(self.player) then
		local card_str = nil
		card_str = string.format("fire_attack:jfjifeng[%s:%s]=.", "no_suit", 0)
		local usec = parse(self,card_str)
		assert(usec)
		return usec
	end
end

ai_skill_use["@@jfjifeng"] = function(self, prompt, request)
	local dis = nil
	local card_ids = tagids(self,"jfjifengai")
	local suit = prop(self,"jfjifengsuit")
	for _,id in sgs.qlist(card_ids) do
		local cc = face(self,id)
		if cc:getSuitString() == suit then
			dis = cc
			break
		end
	end
	if not dis then
		local cards = sgs.QList2Table(self.player:getCards("h"))

		self:sortByKeepValueInPlace(cards)
		for _,cc in ipairs(cards) do
			if cc:getSuitString() == suit then
				dis = cc
				break
			end
		end
	end
	if dis then
		return response(self,"#jfjifengdis:"..dis:getEffectiveId()..":")
	else
		return "."
	end
end

sgs.ai_ajustdamage_to["&jfjifeng"] = function(self, from, to, card, nature)
	if nature == sgs.DamageStruct_Fire
	then
		return 1
	end
end

sgs.ai_ajustdamage_to.jfyueyin = function(self, from, to, card, nature)
	local can_invoke = false
	if (not card) or (card and card:isKindOf("SkillCard")) then can_invoke = true end
	if card and (not card:isKindOf("SkillCard")) then
		local ctype = source_type(card)
		if to:getStrategyMark("jfyueyin"..ctype.."-Clear") > 0 then
			can_invoke = true
		end
	end
	if can_invoke then
		return -999
	end
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|jfqixing"

sgs.ai_skill_playerchosen.jfqixing = function(self, targets)
	if self.player:getKnownRole() == "loyalist" then
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if role(self,p) == "lord" then
				return p
			end
		end
	end
	self:sortInPlace(self.friends, "hp")
	for _,p in ipairs(self.friends) do
		if p:isAlive() then
			return p
		end
	end
	return nil
end


ai_skill_invoke.xrxiaorui = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("xrxiaoruitarget") then
			target = p
			break
		end
	end
	local slash = named(self,"xrxiaorui","slash",{})
	
	if self:isEnemy(target) and self:slashIsEffective(slash, target, self.player) and self:isGoodTarget(target, self.enemies, slash) then return (true) or false end
	return (false) or false
end

ai_skill_use["@@xrxiaorui"] = function(self, prompt, request)
	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("xrxiaoruitarget") then
			target = p
			break
		end
	end
	if not target then return "." end
	local cards = sgs.QList2Table(fullhand(target))
	self:sortByKeepValueInPlace(cards, source_inverse(self))
	if #cards > 0 then
		return response(self,"#xrxiaorui:"..cards[#cards]:getEffectiveId()..":")
	end
	return "."
end


ai_skill_invoke.xrshanjia = true

ai_skill_use["@@xrshanjia"] = function(self, prompt, request)
	local slash = named(self,"xrshanjia","slash",{})
	local targets = {}

	local dummy_use = self:aiUseCard(slash, dummy())
	if dummy_use.card then
        if not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets, p:objectName())
			end
		end
	end
    

	if #targets > 0 then
		local card_str = string.format("#xrshanjia:.:->%s",  table.concat(targets, "+"))
		return response(self,card_str)
	end
	return "."
end
sgs.ai_use_revises.xrshanjia = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
	then use.card = card return true end
end
sgs.need_equip_skill = sgs.need_equip_skill .. "|xrshanjia"
-- audited alias ai_cardneed.xrshanjia
ai_skill_invoke.cqtieji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	return (self:isEnemy(target)) or false
end
sgs.ai_choicemade_filter.skillInvoke.cqtieji = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then self:updateIntention(player, target, 50) end
	end
end
-- audited alias ai_cardneed.cqtieji
sgs.hit_skill = sgs.hit_skill .. "|cqtieji"

sgs.ai_canliegong_skill.cqtieji = function(self, from, to)
	return true
end


sgs.ai_skill_playerchosen.cqchangqu = function(self, targets)
	self:sortInPlace(self.enemies, "defense")
	if #self.enemies == 0 then return nil end
	local slash = named(self,"cqchangqu","slash",{})
	
	for _,p in ipairs(self.enemies) do
		if self.player:inMyAttackRange(p) then
			if not p:inMyAttackRange(self.player) and self:slashIsEffective(slash, p, self.player) and self:isGoodTarget(p, self.enemies, slash) then
				return p
			end
		end
	end
	for _,p in ipairs(self.enemies) do
		if self.player:inMyAttackRange(p) and p:inMyAttackRange(self.player) and self:slashIsEffective(slash, p, self.player) and self:isGoodTarget(p, self.enemies, slash)  then
			return p
		end
	end
	for _,p in ipairs(self.enemies) do
		if self:slashIsEffective(slash, p, self.player) and self:isGoodTarget(p, self.enemies, slash)  then
			return p
		end
	end
	return self.enemies[1]
end

sgs.ai_playerchosen_intention.cqchangqu = function(self, from, to)
	self:updateIntention(from, to, 80)
end


sgs.ai_skill_discard.yzyuzhi = function(self,max,min)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local n = self.player:getHp()
	self:sortByUseValueInPlace(cards)
	local max = -1
	local show = {}
	local special = nil
	for _,card in ipairs(cards) do
		local name_number = card:nameLength()
		if card:isKindOf("Slash") then name_number = 1 end
		if name_number > max and name_number <= self.player:getHp() then
			max = name_number
			special = card
		end
	end
	if special then
		table.insert(show, special:getEffectiveId())
		return show
	end
	for _,card in ipairs(cards) do
		table.insert(show, card:getKnownEffectiveId())
		return show
	end
end


ai_skill_use["@@yzxieshu"] = function(self, prompt, request)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValueInPlace(cards)

	local n = self.player:getStrategyMark("yzxieshu")
	if #cards < n then return "."end
	if (n > self.player:getLostHp() + 1) and self.player:getHp() ~= 1 and self.player:getHandcardNum() < 8 then return "." end
	
	local target = nil
	if self.player:getHp() == 1 and (self:getCardsNum("Analeptic") + self:getCardsNum("Peach") < 1) then
		target = self.player
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and self:canDamage(enemy, self.player, nil) then
				target = enemy
				break
			end
		end
	end

	if not target then
		if #self.enemies == 0 then return "." end
		self:sortInPlace(self.enemies, "hp")
		target = self.enemies[1]
	end

	local usecards = {}
	for _,card in ipairs(cards) do
		if #usecards < n then
			table.insert(usecards, card:getKnownEffectiveId())
		else
			break
		end
	end

	if target then
		local card_str = string.format("#yzxieshu:%s:->%s", table.concat(usecards, "+"), target:objectName())
		return response(self,card_str)
	else
		return "."
	end
end

sgs.ai_card_intention.yzxieshu = 50

sgs.ai_can_damagehp.yzxieshu = function(self,from,card,to)
	if card and not card:isKindOf("SkillCard") then
		local name_number = card:nameLength()
		if card:isKindOf("Slash") then name_number = 1 end
		if to:getStrategyMark("yzxieshu"..name_number.."-Clear") > 0 then return false end

		return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
		and self:canLoseHp(from, card, to) and name_number <= to:getLostHp() + 1 and to:getCards("he"):length() >= name_number
	end
end


ai_skill_invoke.lgliegong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	return (self:isEnemy(target)) or false
end

sgs.ai_skill_discard.lgliegong = function(self,max,min)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValueInPlace(cards)
	local dis = {}
	if #cards == 0 then return dis end
	if self.player:containsTrick("indulgence") and (self.player:getHandcardNum() > (self.player:getMaxCards() - 2)) then
		local n = self.player:getHandcardNum() - self.player:getMaxCards() + 3
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByKeepValueInPlace(handcards)
		for _,card in ipairs(handcards) do
			table.insert(dis, card:getKnownEffectiveId())
			n = n - 1
			if n <= 0 then break end
		end
	elseif self:getCardsNum("Slash") == 0 then
		table.insert(dis, cards[1]:getEffectiveId())
	end
	return dis
end

sgs.ai_ajustdamage_from.lgliegong = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") then else return 0 end
	local n = 0
	if from:getHp() <= to:getHp() then n = n + 1 end
	if from:getHandcardNum() <= to:getHandcardNum() then n = n + 1 end
	if from:getEquips():length() <= to:getEquips():length() then n = n + 1 end
	if n <= 0 then return false end
	return n
end

sgs.ai_choicemade_filter.skillInvoke.lgliegong = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then self:updateIntention(player, target, 50) end
	end
end
-- audited alias ai_cardneed.lgliegong
sgs.hit_skill = sgs.hit_skill .. "|lgliegong"


ai_audited_aliases.register({id="ai_skill_carduse.Dlimu",registry="ai_skill_carduse",path={"Dlimu"},canonical_registry="ai_skill_carduse",canonical_path={"limu"},self_index=1,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.Gposhi",registry="ai_cardneed",path={"Gposhi"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.xrshanjia",registry="ai_cardneed",path={"xrshanjia"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.cqtieji",registry="ai_cardneed",path={"cqtieji"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.lgliegong",registry="ai_cardneed",path={"lgliegong"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if damage_call(to, "hasSkill", "Djianxiong") and dmg > 1 then
                local names = damage_call(to,"getDjianxiongRecord")
                -- A nil card here is an ordinary donor dereference error, not missing
                -- projection. Non-nil cards still require an exact printed identity.
                local name = card and damage_call(card,"objectName") or card:objectName()
                if damage_call(card, "isKindOf", "Slash") then name = "DjianxiongSlash" end
                if table.contains(names, name) then
                    dmg = 1
                end
            end
        return dmg, nature
    end
    local previous_1 = sgs.ai_ajustdamage_to["Djianxiong"]
    sgs.ai_ajustdamage_to["Djianxiong"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "after_to" and context.rule == "Djianxiong" then
                local damage, next_nature, terminal = policy_1(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_to", "Djianxiong", {
        {phase="after_to", rule="Djianxiong", order=7000},
    })
end)()
