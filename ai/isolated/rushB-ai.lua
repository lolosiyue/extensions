-- Source: b6025acc ai/rushB-ai.lua.
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
 return row
end
local nullable={getCard=true,getArmor=true,getWeapon=true,getTreasure=true,findPlayerBySkillName=true,toPlayer=true,useEquipCard=true,useTrickCard=true,useBasicCard=true,setStrategyMemory=true,getStrategyMemory=true,updateIntention=true,setStrategyCardFlag=true}

local function face(self,id)return self:getKnownCardById(id)end
local function engineface(self,id)
 -- The printed face is projected only where the card itself is visible.
 return known(self:getPrintedCardById(id),'public engine printed descriptor '..tostring(id))
end
local function random_catalogue(self)
 -- Engine::getRandomCards order is not projected.
 ai_unsupported('source random catalog is not projected','rushB_xiongsuan')
end
local function draw_count(self)return known(self.world.draw_pile_count,'draw_count')end
-- Draw pile contents are hidden.
local function draw_id(self,index)ai_unsupported('draw pile contents are not projected','draw_index:'..index)end
local function draw_iter(self)local index=-1;return function()index=index+1;if index<draw_count(self)then return index+1,draw_id(self,index)end end end
local function fullhand(p)local cs=p:getHandcards();if #cs~=p:getHandcardNum()then ai_unsupported('rushB source requires complete lawful foreign hand','rushB.foreign_hand')end;return cs end
local function evaluation(self,name)return self:getEvaluationCard(name or'slash')end
local function named(self,skill,name,costs)return self:evaluateSkillCard(skill, name, costs or{})end
local function touch_physical(self,c,skill)
 -- Source mutates the actual physical card's skill name; readonly cloning alone cannot commit it.
 return self:evaluatePhysicalSkillMutation(skill, c)
end
local function sourceuse(self,key)
 local c=self:getDecisionContext();if key=='CurrentDamageStruct'then return known(c.damage,key)end
 local rows=c.rushB;return hydrate_context(self,known(rows and rows[key],key),key=='SlashData'and'CardEffect'or'CardUse')
end
local function own_ai(p)local a=p._room and p._room._ai;if not a or a.player~=p then ai_unsupported('rushB view-as requires owner','rushB.view_as')end;return a end
local function memory(self,key,value,write)
 if write then if value==nil then value=false end;self:setStrategyMemory('rushB.'..key, value);return end
 local value,present=self:getStrategyMemory('rushB.'..key);if present then return value~=false and value or nil end
end
local function save_targets(self,key,ts)local names={};for _,p in ipairs(ts or{})do names[#names+1]=p:objectName()end;memory(self,key,names,true)end
local function targets(self,key)local names=memory(self,key);if not names then return nil end;local out=AIList.new({});for _,n in ipairs(names)do out:append(known(self.room:findPlayerByObjectName(n),n))end;return out end
local selectors={rushB_chenglve=true,rushB_paiyi=true,diy_f_pojun=true,diy_qixi=true,wen_jtweidi=true,rushB_lihun=true,rushB_fanjian=true,rushB_xiongyi=true,diy_f_zhuiji=true,diy_f_xionglie=true,diy_k_qice=true,diy_m_chuifeng=true,diy_zuguangu=true,mjin_xiongzhi=true,rushB_baobian_shensu=true,rushB_baobian=true,rushB_baobian_tiaoxin=true,rushB_dimeng=true,rushB_diaogui=true,mmou_leiji=true,mmou_guidao=true,rushB_huace=true,rushB_pizhuan=true,rushB_tongbo=true,rushB_moutongye=true,rushB_juezhi=true,sgskanxue=true,sgszhenhua=true,DIT_qianxun=true}
local provider={diy_qixi='diy_k_qixi',rushB_baobian_tiaoxin='rushB_baobian',rushB_baobian_shensu='rushB_baobian'}
local function ids(raw)local out={};if raw~='.'and raw~=''then for v in raw:gmatch('[^+]+')do local id=tonumber(v);if not id or id<0 or id%1~=0 then ai_unsupported('invalid rushB source material',raw)end;out[#out+1]=id end end;return out end
local function wireparts(wire)
 local cls,raw,user=wire:match('^#([%w_]+):([^:]*):(.*)$');if not cls or not selectors[cls]then ai_unsupported('unmapped rushB skillcard selector',wire)end
 local to={};local declaration=user;local names=user:match('^%-%>(.*)$');if names then declaration='';for n in names:gmatch('[^+]+')do to[#to+1]=n end end
 return cls,ids(raw),declaration,to
end
local suits={spade=0,club=1,heart=2,diamond=3,no_suit_black=4,no_suit_red=5,no_suit=6,to_be_decided=6}
local function printed(wire,self)
 local name,skill,suit,num,raw=wire:match('^([%w_]+):([%w_]+)%[([^:]+):([^%]]+)%]=([^:]+)$')
 if not name or suits[suit]==nil then ai_unsupported('rushB source CardParse face needs exact native parser witness',wire)end
 local numbers={A=1,J=11,Q=12,K=13,JOKER=0};local number=numbers[num]or tonumber(num);if not number then ai_unsupported('rushB source number is not parsed',wire)end
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
 local cls,costs,user,to=wireparts(wire);local c=self:bindSkillCard(provider[cls]or cls, costs, self.request, user~=''and user or nil, '#'..cls)
 return{kind='use_card',card_spec=c:toCardSpec(),targets=to}
end
local function answer(self,c,to)
 if c:isEvaluationOnly()then local skill=c:getKnownSkillName(false);local provider=skill:gsub('^_','');local receipt=self:bindSkillCard(provider, c:getSubcards(), self.request, c:objectName())
  for _,key in ipairs{'objectName','getSuit','getNumber'}do if AIValue.callKnown(receipt, key)~=AIValue.callKnown(c, key)then ai_unsupported('rushB receipt changed selected source product',key)end end
  if receipt:getKnownSkillName(false)~=skill then ai_unsupported('rushB receipt changed raw skill',skill)end
  local a,b=receipt:getSubcards(),c:getSubcards();if #a~=#b then ai_unsupported('rushB receipt changed costs',skill)end;for i,id in ipairs(a)do if b[i]~=id then ai_unsupported('rushB receipt reordered costs',skill)end end;c=receipt
 end
 if AIValue.isConversion(c)then return{kind='use_card',card_spec=c:toCardSpec(),targets=to or{}}end
 if c:isVirtualCard()then ai_unsupported('rushB selected virtual lacks authority','rushB.answer')end
 return{kind='use_card',card_ids={c:getKnownEffectiveId()},targets=to or{}}
end
local function nested(self,reg,key,...)
 local f=self:getHooks(reg)[key];if type(f)~='function'then ai_unsupported('rushB required shared callback missing',reg..'.'..key)end
 local values=table.pack(f(...));if AIUnsupported.is(values[1])then error(values[1],0)end;return table.unpack(values,1,values.n)
end
local function view(self,wire)return printed(wire,self)end

local function RandomList(items)
 local pending={};for _,v in ipairs(items)do pending[#pending+1]=v end
 while #pending>0 do local v=pending[math.random(1,#pending)];table.removeOne(pending,v);table.removeOne(items,v);items[#items+1]=v end
 return items
end
local function saved_player(self,key)local name=memory(self,key);return name and known(self.room:findPlayerByObjectName(name),key)end


ai_fill_skill.rushB_chenglve=function(self, options, request)
    local inclusive = options and options.inclusive

	return parse(self,"#rushB_chenglve:.:")
end

ai_card_use["#rushB_chenglve"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_priority.rushB_chenglve = 3
sgs.ai_use_value.rushB_chenglve = 7

sgs.ai_skill_discard.rushB_chenglve = function(self,discard_num,min_num,optional,include_equip)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local slashs = self:getCards("Slash")
	if #slashs>0 then self:sortByUseValueInPlace(handcards, true)
	else self:sortByKeepValueInPlace(handcards) end
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
		if table.contains(slashs,c)
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

sgs.ai_card_priority.rushB_chenglve = function(self,card)
	if self.player:getStrategyMark("chenglve"..card:getSuitString().."-Clear")>0
	and card:getTypeId()>0
	then return -1 end
end



sgs.ai_card_priority.rushB_jianying = function(self,card,v)
	if (card:isRed() and self.player:getStrategyMark("&jianyingcolorred") > 0) or
	(card:isBlack() and self.player:getStrategyMark("&jianyingcolorblack") > 0)
	or self.player:getStrategyMark("&jianyingnumber")==card:getNumber()
	then return 10 end
end





ai_fill_skill.rushB_zhiheng=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile()
	self:sortByUseValueInPlace(cards, true)
	local card
	for _,acard in sgs.list(cards)do
		local shouldUse = true
		if self:getUseValue(acard)>sgs.ai_use_value.IronChain then
			local dummy_use = self:aiUseCard(acard, dummy())
			if dummy_use.card and acard:isAvailable(self.player) then shouldUse = false end
		end
		if acard:getTypeId()==sgs.Card_TypeEquip then
			local dummy_use = dummy()
			self:useEquipCard(acard, dummy_use)
			if dummy_use.card then shouldUse = false end
		end
		if shouldUse then
			card = acard
			break
		end
	end
	if self.player:getHandcardNum() == 1 and self.player:getStrategyMark("zhiheng".."-Clear") == 0 then
		card = cards[1]
	end
	if math.random() < 0.7 and ((self:getOverflow()==0 and not self.player:getHandcardNum() == 1) or #self.enemies == 0) then return nil end
	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	local card_str = ("iron_chain:rushB_zhiheng[%s:%s]=%d"):format(number, card:getSuitString(),card_id)
	local skillcard = parse(self,card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_hasTuntianEffect_skill.rushB_tuntian = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive
end

ai_skill_invoke.rushB_jiuyuan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return (true) or false
	end
	return (false) or false
end
sgs.ai_choicemade_filter.skillInvoke.rushB_jiuyuan = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then self:updateIntention(player, target, -50) end
	end
end

sgs.ai_can_damagehp.rushB_quanji = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>1
	and self:canLoseHp(from, card, to)
end


ai_fill_skill.rushB_paiyi=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getPile("power"):length()>0 then
		return parse(self,"#rushB_paiyi:"..self.player:getPile("power"):first()..":")
	end
end

ai_card_use["#rushB_paiyi"] = function(self, card, use, request)
	local target
	self:sortInPlace(self.friends_noself, "defense")
	for _,friend in ipairs(self.friends_noself)do
		if friend:getHandcardNum()<2 and friend:getHandcardNum()+1<self.player:getHandcardNum()
		  and not self:needKongcheng(friend, true) and not friend:hasSkill("manjuan") then
			target = friend
		end
		if target then break end
	end
	if not target then
		if self.player:getHandcardNum()<self.player:getHp()+self.player:getPile("power"):length()-1 then
			target = self.player
		end
	end
	self:sortInPlace(self.friends_noself, "hp")
	self.friends_noself = sgs.reverse(self.friends_noself)
	if not target then
		for _,friend in ipairs(self.friends_noself)do
			if friend:getHandcardNum()+2>self.player:getHandcardNum()
			and self:needToLoseHp(friend, self.player, nil, true)
			and not friend:hasSkill("manjuan") then
				target = friend
			end
			if target then break end
		end
	end
	self:sortInPlace(self.enemies, "defense")
	if not target then
		for _,enemy in ipairs(self.enemies)do
			if self:hasManjuanEffect(enemy)
			and self:canDamage(enemy, self.player)
			and (self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player)
				or self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player)
				or self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player)
				or self:damageIsEffective(enemy, sgs.DamageStruct_Ice, self.player)
				)
			and enemy:getHandcardNum()>self.player:getHandcardNum()
			then target = enemy end
			if target then break end
		end
		if not target then
			for _,enemy in ipairs(self.enemies)do
				if self:canDamage(enemy, self.player)
				and not enemy:hasSkills(sgs.cardneed_skill.."|jijiu|tianxiang|buyi")
				and (self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player)
				or self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player)
				or self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player)
				or self:damageIsEffective(enemy, sgs.DamageStruct_Ice, self.player)
				)
				and not self:cantbeHurt(enemy)
				and not self:needToLoseHp(enemy)
				and enemy:getHandcardNum()+2>self.player:getHandcardNum()
				then target = enemy end
				if target then break end
			end
		end
	end

	if target then
		use.card = parse(self,"#rushB_paiyi:"..self.player:getPile("power"):first()..":")
		use.to:append(target)
	end
end

sgs.ai_skill_askforag.rushB_paiyi = function(self,card_ids)
	return card_ids[math.random(1,#card_ids)]
end

sgs.ai_card_intention.rushB_paiyi = function(self,card,from,tos)
	local to = tos[1]
	if to:objectName()==from:objectName() then return end
	if not to:hasSkill("manjuan")
	and ((to:getHandcardNum()<2 and to:getHandcardNum()+1<from:getHandcardNum() and not self:needKongcheng(to, true))
	or (to:getHandcardNum()+2>from:getHandcardNum() and self:needToLoseHp(to, from)))
	then
	else
		self:updateIntention(from, to, 60)
	end
end

sgs.ai_skill_cardask["@diy_f_pojun"] = function(self, data, pattern, target)
	local target = self.room:getCurrent()
	if self:needBear() then return "." end
	if target and self:isEnemy(target) and self:objectiveLevel(target) > 3 and not self:willSkipPlayPhase(target) then
		return true
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@diy_f_pojun"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		self:updateIntention(player, current, 80)
	end
end


ai_fill_skill.diy_f_pojun=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("he")
	cards = self:sortByKeepValueInPlace(cards)
	for _,c in sgs.list(cards)do
		return parse(self,"#diy_f_pojun:"..c:getEffectiveId()..":")
	end
end

ai_card_use["#diy_f_pojun"] = function(self, card, use, request)
	
	self:sortInPlace(self.enemies, "defense")
	local slashcount = self:getCardsNum("Slash")
	if slashcount > 0 then
		local slash = self:getCard("Slash")
		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use.card and dummy_use.to then
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					if self:doDisCard(p, "he", true) then
						use.card = card
						use.to:append(p)
						return
					end
				end
			end
		end
	end
	for _,p in ipairs(self.enemies)do
		if self:doDisCard(p, "he", true) then
			use.card = parse(self,"#diy_f_pojun:.:")
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_priority.diy_f_pojun = 6
sgs.ai_use_value.diy_f_pojun = 8.5

sgs.ai_ajustdamage_from.diy_f_pojun = function(self,from,to,card,nature)
	local n = 0
	if to:getHandcardNum() <= from:getHandcardNum() then n = n + 1 end
	if to:getEquips():length() <= from:getEquips():length() then n = n + 1 end
	if to:getJudgingArea():length() >= from:getJudgingArea():length() then n = n + 1 end
	return n
end


ai_fill_skill.diy_k_qixi=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile("he")
	local black_card
	local red_card
	self:sortByUseValueInPlace(cards, true)
	local has_weapon = false
	for _,card in ipairs(cards)  do
		if card:isKindOf("Weapon") then has_weapon=true end
	end
	for _,card in ipairs(cards)  do
		if card:isBlack() and ((self:getUseValue(card)<sgs.ai_use_value.Dismantlement) or inclusive or self:getOverflow()>0) then
			local shouldUse = true
			if card:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(card) and not self:needToThrowArmor() then shouldUse = false
				end
			end
			if card:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self.player:hasEquip(card) and not has_weapon then shouldUse = false
				end
			end
			if card:isKindOf("Slash") then
				local dummy_use = dummy()
				if self:getCardsNum("Slash")==1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end
			if self:getUseValue(card)>sgs.ai_use_value.Dismantlement and card:isKindOf("TrickCard") then
				local dummy_use = dummy()
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse then
				black_card = card
				break
			end
		end
	end
	for _,card in ipairs(cards)  do
		if (card:isRed() and card:isKindOf("EquipCard")) and ((self:getUseValue(card)<sgs.ai_use_value.Dismantlement) or inclusive or self:getOverflow()>0) then
			local shouldUse = true
			if card:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(card) and not self:needToThrowArmor() then shouldUse = false
				end
			end
			if card:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self.player:hasEquip(card) and not has_weapon then shouldUse = false
				end
			end
			if card:isKindOf("Slash") then
				local dummy_use = dummy()
				if self:getCardsNum("Slash")==1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end
			if self:getUseValue(card)>sgs.ai_use_value.Dismantlement and card:isKindOf("TrickCard") then
				local dummy_use = dummy()
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse then
				red_card = card
				break
			end
		end
	end
	if red_card then
		return parse(self,"#diy_qixi:"..red_card:getEffectiveId()..":")
	end
	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getKnownEffectiveId()
		local card_str = ("dismantlement:diy_k_qixi[%s:%s]=%d"):format(suit,number,card_id)
		local dismantlement = parse(self,card_str)
		assert(dismantlement)
		return dismantlement
	end
end

ai_card_use["#diy_qixi"]=function(self, card, use, request)
	self:sortInPlace(self.enemies, "handcard", true)
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he", true) then
			use.card=card
			use.to:append(enemy)
			return
		end
	end
end
sgs.ai_use_priority.diy_qixi = sgs.ai_use_priority.Dismantlement + 0.2

ai_skill_use["@@diy_k_qixi"] = function(self, prompt, request)
	local cards = self:addHandPile("he")
	self:sortByUseValueInPlace(cards, true)
	for _,card in ipairs(cards)  do
		if card:isBlack() then
			local dismantlement = named(self,"_diy_k_qixi","dismantlement",{card:getKnownEffectiveId()})
			
			local dummy_use = self:aiUseCard(dismantlement, dummy())
			if dummy_use.to and dummy_use.to:length() > 0 then
				local tos = {}
				for _,to in sgs.qlist(dummy_use.to) do
					table.insert(tos, to:objectName())
				end
				return answer(self,dismantlement,tos)
			end
		end
	end
	for _,card in ipairs(cards)  do
		if (card:isRed() and card:isKindOf("EquipCard")) then
			
			for _,to in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if not to:isNude() and self:doDisCard(to, "he", true) then
					return response(self,"#diy_qixi:"..card:getEffectiveId()..":->"..to:objectName())
				end
			end
		end
	end
	return "."
end

local function getFenweiValue(self,who,card,from)
	if not self:hasTrickEffective(card, who, from) then return 0 end
	if card:isKindOf("AOE") then
		if not self:isFriend(who) then return 0 end
		local value = self:getAoeValueTo(card, who, from)
		if value<0 then return -value/30 end
	elseif card:isKindOf("GodSalvation") then
		if not self:isEnemy(who) or not who:isWounded() or who:getHp()>=getBestHp(who) then return 0 end
		if self:isWeak(who) then return 1.2 end
		if who:hasSkills(sgs.masochism_skill) then return 1.0 end
		return 0.9
	elseif card:isKindOf("AmazingGrace") then
		if not self:isEnemy(who) or self:hasManjuanEffect(who) then return 0 end
		local v = 1.2
		local p = self.room:getCurrent()
		while p:objectName()~=who:objectName()do
			v = v*0.9
			p = p:getNextAlive()
		end
		return v
	end
	return 0
end
sgs.ai_skill_playerschosen.diy_k_fenwei = function(self, targets, max, min)
	local fenwei = nested(self,"ai_skill_use","@@fenwei",self,"")
    local selected = sgs.SPlayerList()
	
	if fenwei ~= "." then
		local targets = fenwei:split(">")[2]:split("+")
		local can_choose = sgs.QList2Table(targets)
		self:sortInPlace(can_choose, "defense")
		for _,target in ipairs(can_choose) do
			if self:isFriend(target) and table.contains(targets, target:objectName()) then
				selected:append(target)
			end
		end
	elseif math.random() < 0.8 then
		local card = sourceuse(self,"fenwei").card
		local from = sourceuse(self,"fenwei").from
		local can_choose = sgs.QList2Table(targets)
		self:sortInPlace(can_choose, "defense")
		for _,target in ipairs(can_choose) do
			local val = getFenweiValue(self,target,card,from)
			if val>0 then
				selected:append(target)
			end
		end
	end
    return selected
end
ai_skill_invoke.wen_jingtian = true


ai_skill_invoke.wen_jtweidi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	return (not self:needToLoseHp(self.player, damage.from, damage.card)) or false
end

ai_skill_invoke.wen_zemin = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	return (damage.to and self:isFriend(damage.to) and not self:needToLoseHp(damage.to, damage.from, damage.card)) or false
end


ai_fill_skill.wen_jtweidi=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = sgs.QList2Table(self.player:getPile("chushibiao"))
  	for _,id in sgs.list(cards)do
		return parse(self,"#wen_jtweidi:"..id..":") 
	end
end

ai_card_use["#wen_jtweidi"] = function(self, card, use, request)
	for _,enemy in ipairs(self.enemies)do
		if self:canDamage(enemy, self.player, nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if self:canDraw(friend, self.player)  then
			use.card = card
			use.to:append(friend)
			return
		end
	end
end

sgs.ai_use_value.wen_jtweidi = 9.4
sgs.ai_use_priority.wen_jtweidi = 4.8

ai_skill_choice["wen_jtweidi"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target) then
		if table.contains(items, "3") then
			return ai_choice_result(("3"), options)
		end
		if table.contains(items, "4") then
			return ai_choice_result(("4"), options)
		end
	end
	if table.contains(items, "1") then
		if self:canDamage(target, self.player, nil) and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) then
			if math.random() < 0.8 then
				return ai_choice_result(("1"), options)
			end
		end
	end
	if table.contains(items, "3") then
		if math.random() < 0.5 then
			return ai_choice_result(("3"), options)
		end
	end
	if table.contains(items, "2") then
		if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, target) then
			return ai_choice_result(("2"), options)
		end
		if math.random() < 0.5 then
			return ai_choice_result(("2"), options)
		end
	end
	if table.contains(items, "4") then
		if math.random() < 0.5 then
			return ai_choice_result(("4"), options)
		end
	end

    return ai_choice_result(nil, options)
end

sgs.ai_can_damagehp.diy_k_zhongzuo = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to) and to:getStrategyMark("damaged_round-Clear") == 0
end
sgs.ai_skill_playerchosen.diy_k_zhongzuo = function(self,targets)
	self:sortInPlace(self.friends_noself, "defense")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) then continue end
		if (friend:getHandcardNum()+(friend:isWounded() and -2 or 1))<(self.player:getHandcardNum()+(self.player:isWounded() and -2 or 0)) then
			return friend
		end
	end
	if self:canDraw(self.player) then return self.player end
	return nil
end
sgs.ai_playerchosen_intention.diy_k_zhongzuo = -40

ai_skill_invoke.diy_k_tongqu = false


sgs.ai_skill_discard.diy_k_wanlan = function(self)
	local damage = sourceuse(self,"CurrentDamageStruct")
	if damage.from and self.player:objectName() == damage.from:objectName() then
		if not self:canDamage(damage.to, self.player, nil) then
			return {}
		end
	elseif damage.from then
		if not self:canDamage(damage.from, self.player, nil) then
			return {}
		end
	end
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValueInPlace(cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, card:getKnownEffectiveId())
		if #to_discard == 2 then
        	break
		end
	end
	if #to_discard == 2 then
		return to_discard
	end
	return {}
end


ai_fill_skill.rushB_lihun=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValueInPlace(cards)
	if #cards<1 then return end
	return parse(self,"#rushB_lihun:"..cards[1]:getId()..":")
end

ai_card_use["#rushB_lihun"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "handcard", true)
	local jwfy = self.room:findPlayerBySkillName("shoucheng")
	for _,enemy in sgs.list(self.enemies)do
		if not enemy:hasSkill("kongcheng")
		then
			if (enemy:hasSkill("lianying") or jwfy and self:isFriend(jwfy, enemy)) and self:damageMinusHp(enemy, 1)>0
			or enemy:getHp()<3 and self:damageMinusHp(enemy, 0)>0 and enemy:getHandcardNum()>0
			or enemy:getHandcardNum()>=enemy:getHp() and enemy:getHp()>2 and self:damageMinusHp(enemy, 0)>=-1
			or enemy:getHandcardNum()-enemy:getHp()>2
			then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
	if not self.player:faceUp()
	then
		for _,enemy in sgs.list(self.enemies)do
			if enemy:getHandcardNum()>=enemy:getHp()
			then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
	if self:hasCrossbowEffect()
	or self:getCardsNum("Crossbow")>0
	then
		local slash = self:getCard("Slash") or evaluation(self)
		for _,enemy in sgs.list(self.enemies)do
			if not enemy:isKongcheng()
			and self:slashIsEffective(slash, enemy)
			and self.player:distanceTo(enemy)==1
			and not enemy:hasSkills("fenyong|zhichi|fankui|vsganglie|ganglie|neoganglie|enyuan|nosenyuan|langgu|guixin|kongcheng")
			and self:getCardsNum("Slash")+getKnownCard(enemy,self.player,"Slash")>=3
			then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
end


sgs.ai_skill_discard.rushB_lihun = function(self,discard_num,min_num,optional,include_equip)
	local to_discard = {}

	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValueInPlace(cards)
	local card_ids = {}
	for _,card in sgs.list(cards)do
		table.insert(card_ids,card:getKnownEffectiveId())
	end

	local temp = table.copyFrom(card_ids)
	for i = 1,#temp,1 do
		local card = face(self,temp[i])
		if self.player:getArmor() and temp[i]==self.player:getArmor():getEffectiveId() and self:needToThrowArmor() then
			table.insert(to_discard,temp[i])
			table.removeOne(card_ids,temp[i])
			if #to_discard==discard_num then
				return to_discard
			end
		end
	end

	temp = table.copyFrom(card_ids)

	for i = 1,#card_ids,1 do
		local card = face(self,card_ids[i])
		table.insert(to_discard,card_ids[i])
		if #to_discard==discard_num then
			return to_discard
		end
	end

	if #to_discard<discard_num then return {} end
end

sgs.ai_use_value.rushB_lihun = 8.5
sgs.ai_use_priority.rushB_lihun = 6
sgs.ai_card_intention.rushB_lihun = 80


ai_fill_skill.rushB_fanjian=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:isKongcheng() then return nil end
	return parse(self,"#rushB_fanjian:.:")
end

ai_card_use["#rushB_fanjian"]=function(self, card, use, request)

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	if #cards==1 and cards[1]:getSuit()==sgs.Card_Diamond then return end
	if #cards<=4 and (self:getCardsNum("Peach")>0 or self:getCardsNum("Analeptic")>0) then return end
	self:sortInPlace(self.enemies, "hp")

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
		and self:damageIsEffective(enemy, card)
		then
			use.card = parse(self,"#rushB_fanjian:.:")
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_card_intention.rushB_fanjian = 70


ai_skill_use["@@rushB_xiongyi"] = function(self, prompt, request)
	self:sortInPlace(self.friends_noself, "defense", true)
	local targets = {}
	local to_use = {}
	for _,friend in ipairs(self.friends_noself) do
		for _,c in sgs.list(self:sortByKeepValueInPlace(self.player:getHandcards()))do
			if not table.contains(to_use, c:getKnownId()) then
				table.insert(to_use, c:getKnownId())
				table.insert(targets, friend:objectName())
				break
			end
		end
	end
	if (#targets == #to_use and #targets > 0) then
		return response(self,"#rushB_xiongyi:".. table.concat(to_use, "+") ..":->".. table.concat(targets, "+"))
	end
	return "."
end
sgs.ai_card_intention.rushB_xiongyi = -70

ai_fill_skill.diy_f_zhuiji=function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies==0 then return nil end	
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValueInPlace(cards)
	if #cards<1 then return end
	return parse(self,"#diy_f_zhuiji:"..cards[1]:getEffectiveId()..":")
end

ai_card_use["#diy_f_zhuiji"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "hp")
	for _,enemy in sgs.list(self.enemies)do
		if self:canDamage(enemy, self.player, nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end

ai_fill_skill.diy_f_xionglie=function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies==0 then return nil end	
	return parse(self,"#diy_f_xionglie:.:")
end

ai_card_use["#diy_f_xionglie"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "hp")
	for _,enemy in sgs.list(self.enemies)do
		if (self:canDamage(self.player, enemy, nil) or not self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player)) and self:doDisCard(enemy, "he", true) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end


-- audited alias ai_skill_playerchosen.diy_k_qizhi
ai_skill_invoke.diy_k_jinqu = function(self, options, request)
	if self.room:getCurrent() and self.room:getCurrent():objectName() ~= self.player:objectName() then return (true) or false end
	if self.player:getStrategyMark("&qizhi-Clear")>=self.player:getHandcardNum() then return (true) or false end
	return (false) or false
end

ai_fill_skill.diy_k_fanghun=function(self, options, request)
    local inclusive = options and options.inclusive

	local handcards = self:addHandPile()
	if #handcards<1 then return end
	handcards = self:sortByUseValueInPlace(handcards, true)
	for _,c in sgs.list(handcards)do
		local slash = named(self,"diy_k_fanghun","slash",{c:getKnownEffectiveId()})
		if c:isKindOf("Jink")
		and slash:isAvailable(self.player)
		then
			return slash
		elseif c:isKindOf("Analeptic") then
			return parse(self,("peach:diy_k_fanghun[%s:%s]=%d"):format(c:getSuitString(),c:getNumberString(),c:getKnownEffectiveId()))
		end
	end
end

function sgs.ai_cardsview.diy_k_fanghun(self,class_name,player)
    local cards = sgs.QList2Table(player:getCards("h"))
    self:sortByKeepValueInPlace(cards)
	for _,c in sgs.list(cards)do
		if class_name=="Slash" and c:isKindOf("Jink")
		then return view(self,("slash:diy_k_fanghun[no_suit:0]="..c:getEffectiveId()))
		elseif class_name=="Jink" and c:isKindOf("Slash")
		then return view(self,("jink:diy_k_fanghun[no_suit:0]="..c:getEffectiveId()) )
		elseif c:isKindOf("Analeptic") then
			return view(self,("peach:diy_k_fanghun[no_suit:0]="..c:getEffectiveId()))
		end
	end
end



ai_skill_invoke.diy_k_fuhan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local meiying = self.player:getStrategyMark("&diy_k_meiying")
	if self.player:getLostHp()>0 then
		return (meiying>self.player:getHp() and self.player:isLowestHpPlayer() and self:getCardsNum("Peach")==0 and self:isWeak()) or false
	else
		return (meiying>self.player:getMaxHp()) or false
	end
	return (false) or false
end



ai_fill_skill.diy_k_qice=function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.toUse>2 then return end
	local ids = self.player:handCards()
	local canCs = {}
	for _,pn in ipairs(known(AICardCatalog.patternNames(),"pattern_names"))do
		local dc = evaluation(self,pn)
		if dc and dc:isNDTrick() then
			dc = named(self,"diy_k_qice",pn,sgs.QList2Table(ids))
			if dc:isAvailable(self.player)
			then table.insert(canCs,dc) end
		end
	end
	ids = sgs.QList2Table(ids)
	self:sortByUseValueInPlace(canCs)
	sgs.ai_use_priority.diy_k_qice = 4-#ids
	if #ids<3 then
		for _,c in ipairs(canCs)do
			if c:isKindOf("AOE") then
				local d = self:aiUseCard(c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if c:targetFixed() and not c:isDamageCard()
			and self:getCardsNum("Jink,Peach")<1 then
				local d = self:aiUseCard(c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
	end
	if #ids==3 then
		for _,c in ipairs(canCs)do
			if c:isKindOf("AOE") then
				local d = self:aiUseCard(c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if c:isKindOf("GlobalEffect")
			and self.player:isWounded() then
				local d = self:aiUseCard(c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if c:targetFixed() and not c:isDamageCard()
			and self:getCardsNum("Jink,Peach,Analeptic,Nullification")<1 then
				local d = self:aiUseCard(c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
	end
	local caocao = self.room:findPlayerBySkillName("jianxiong")
	for _,c in ipairs(canCs)do
		if c:isKindOf("AOE")
		and caocao and caocao:getHp()>1
		and self:getAoeValue(c)>-5 and self:isFriend(caocao) and not self:willSkipPlayPhase(caocao)
		and not self.player:hasSkill("jueqing") and self:aoeIsEffective(c, caocao, self.player) then
			local d = self:aiUseCard(c)
			if d.card then
				save_targets(self,"qice_to",d.to)
				return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
			end
		end
	end
	if #ids<=3
	and self:getCardsNum("Jink,Peach,Analeptic,Nullification")<1 then
		for _,c in ipairs(canCs)do
			if c:isKindOf("GlobalEffect")
			and self.player:isWounded() then
				local d = self:aiUseCard(c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if c:targetFixed() and not c:isDamageCard() then
				local d = self:aiUseCard(c)
				if d.card then
					save_targets(self,"qice_to",d.to)
					return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
	end
	for _,c in ipairs(canCs)do
		local d = self:aiUseCard(c)
		if d.card and c:isDamageCard()
		and self:getUseValue(c)>#ids*2.1 then
			save_targets(self,"qice_to",d.to)
			return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
		end
	end
	for _,c in ipairs(canCs)do
		local d = self:aiUseCard(c)
		if d.card and self:getUseValue(c)>#ids*2.6 then
			save_targets(self,"qice_to",d.to)
			return parse(self,"#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
		end
	end
end

ai_card_use["#diy_k_qice"] = function(self, card, use, request)
	self.qice_to=targets(self,"qice_to");return nested(self,"ai_card_use","QiceCard",card,use,self)
end

-- audited alias ai_use_priority.diy_k_qice
sgs.ai_ajustdamage_to.diy_f_mingshi = function(self,from,to,slash,nature)
	if (from:faceUp() and not to:faceUp()) or (not from:faceUp() and to:faceUp())
	then return -1 end
end



sgs.ai_skill_playerchosen.diy_f_lirang = function(self,targets)
	self:sortInPlace(self.enemies)
	for _,enemy in ipairs(self.enemies)do
		if self:toTurnOver(enemy, 1, "diy_f_lirang") and self:hasManjuanEffect(enemy) then
			return enemy
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if self:toTurnOver(enemy, 1, "diy_f_lirang") and enemy:hasSkills(sgs.priority_skill) then
			return enemy
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if self:toTurnOver(enemy, 1, "diy_f_lirang") then
			return enemy
		end
	end
end
ai_skill_choice["diy_f_lirang"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    return ai_choice_result(("1"), options)
end
ai_skill_choice["@lirangobtain"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    return ai_choice_result(("yes"), options)
end

sgs.ai_playerchosen_intention.diy_f_lirang = function(self,from,to)
	if self:hasManjuanEffect(to) then self:updateIntention(from, to, 80) end
	local intention = 80
	if not self:toTurnOver(to, 1) then intention = -intention end
	self:updateIntention(from, to, intention)
end



sgs.ai_card_priority.diy_k_fenyin = function(self,card,v)
	if ((self.player:getStrategyMark("&".."fenyin".."colorred".."-Clear")> 0 and card:isBlack()) or
	(self.player:getStrategyMark("&".."fenyin".."colorblack".."-Clear")> 0 and card:isRed())
	) or self.player:getStrategyMark("&fenyinnumber-Clear")==card:getNumber()
	then return 10 end
end



ai_fill_skill.diy_m_chuifeng=function(self, options, request)
    local inclusive = options and options.inclusive

	local ts = {"slash","duel", "thunder_slash", "ice_slash", "fire_slash"}
	local cn = ts[math.random(1,2)]
	local dc = named(self,"diy_m_chuifeng",cn,{})
	sgs.ai_use_priority.diy_m_chuifeng = sgs.ai_use_priority[dc:getClassName()]
	local d = self:aiUseCard(dc)
	if d.card and d.to and not self:isWeak() then
		save_targets(self,"cf_to",d.to)
		memory(self,"diy_m_chuifengChoice",cn,true)
		return parse(self,"#diy_m_chuifeng:.:"..cn) 
	end
end

ai_card_use["#diy_m_chuifeng"] = function(self, card, use, request)
	use.card = card
	use.to = targets(self,"cf_to")
end
sgs.ai_use_value.diy_m_chuifeng = 5.4
sgs.ai_use_priority.diy_m_chuifeng = 2.8

ai_skill_choice.diy_m_chuifeng = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result((memory(self,"diy_m_chuifengChoice")), options)
end

sgs.ai_use_revises.diy_m_quedi = function(self,card,use)
	if table.contains(card:getSkillNames(), "diy_m_chuifengg") or table.contains(card:getSkillNames(), "diy_m_chongjian") or table.contains(card:getSkillNames(), "diy_m_choujue") then
		self:setStrategyCardFlag(card, "Qinggang", true)
	end
end

ai_fill_skill.diy_m_chongjian=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile("he")
	self:sortByUseValueInPlace(cards, true)
	for _,card in sgs.list(cards)do
		if card:isKindOf("OffensiveHorse") and self:slashIsAvailable() then
			return parse(self,("fire_slash:diy_m_chongjian[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getKnownId()))
		elseif card:isKindOf("Treasure") and self:slashIsAvailable() then
			return parse(self,("ice_slash:diy_m_chongjian[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getKnownId()))
		elseif card:isKindOf("DefensiveHorse") and self:slashIsAvailable() then
			return parse(self,("thunder_slash:diy_m_chongjian[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getKnownId()))
		elseif card:isKindOf("Weapon") and self:slashIsAvailable() then
			return parse(self,("slash:diy_m_chongjian[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getKnownId()))
		elseif card:isKindOf("Armor") and self:slashIsAvailable() then
			return parse(self,("analeptic:diy_m_chongjian[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getKnownId()))
		end
	end
end
sgs.ai_card_priority.diy_m_chongjian = function(self,card,v)
	if table.contains(card:getSkillNames(), "diy_m_chongjian")
	then return 5 end
end

sgs.ai_view_as.diy_m_chongjian = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place==sgs.Player_PlaceSpecial then return end
	if card:isKindOf("OffensiveHorse") then
		return view(own_ai(player),("fire_slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id))
	elseif card:isKindOf("DefensiveHorse") then
		return view(own_ai(player),("thunder_slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id))
	elseif card:isKindOf("Treasure") then
		return view(own_ai(player),("ice_slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id))
	elseif card:isKindOf("Weapon") then
		return view(own_ai(player),("slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id))
	elseif card:isKindOf("Armor") then
		return view(own_ai(player),("analeptic:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id))
	end
end


ai_fill_skill.diy_m_jichou=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("he")
	cards = self:sortByKeepValueInPlace(cards)
  	for _,c in sgs.list(cards)do
		if self.player:getStrategyMark("diy_m_jichou"..c:objectName().."-Clear")>0 then continue end
		if c and c:isNDTrick() and c:isAvailable(self.player) then
			c = touch_physical(self,c,"diy_m_jichou")
			local d = self:aiUseCard(c)
			if d.card then
				if c:canRecast() and d.to:length()<1 then continue end
				return c:toString()
			end
		end
	end
end
sgs.ai_card_priority.diy_m_jichou = function(self,card,v)
	if table.contains(card:getSkillNames(), "diy_m_jichou")
	then return 5 end
end
sgs.ai_guhuo_card.diy_m_jichou = function(self,toname,class_name)
	if self.player:getStrategyMark("diy_m_jichou"..toname.."-Clear")<1 then
		local cards = self.player:getCards("he")
		cards = self:sortByKeepValueInPlace(cards)
        for _,c in sgs.list(cards)do
			if c and c:isNDTrick() and c:isKindOf(class_name) then
				c = touch_physical(self,c,"diy_m_jichou")
				return c:toString()
			end
		end
	end
end


ai_fill_skill.diy_m_jilun=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("he")
	cards = self:sortByKeepValueInPlace(cards)
  	for _,c in sgs.list(cards)do
		if self.player:getStrategyMark("diy_m_jilun"..c:objectName().."-Clear")>0 then continue end
		if self.player:getStrategyMark("diy_m_jichou"..c:objectName().."-Clear")>0 then
			if c and c:isNDTrick() and c:isAvailable(self.player) then
				c = touch_physical(self,c,"diy_m_jilun")
				local d = self:aiUseCard(c)
				if d.card then
					if c:canRecast() and d.to:length()<1 then continue end
					return c:toString()
				end
			end
		end
	end
end
sgs.ai_card_priority.diy_m_jilun = function(self,card,v)
	if table.contains(card:getSkillNames(), "diy_m_jilun")
	then return 4 end
end

sgs.ai_guhuo_card.diy_m_jilun = function(self,toname,class_name)
	if self.player:getStrategyMark("diy_m_jichou"..toname.."-Clear")>0 and self.player:getStrategyMark("diy_m_jilun"..toname.."-Clear")<1 then
		local cards = self.player:getCards("he")
		cards = self:sortByKeepValueInPlace(cards)
        for _,c in sgs.list(cards)do
			if c and c:isNDTrick() and c:isKindOf(class_name) then
				c = touch_physical(self,c,"diy_m_jilun")
				return c:toString()
			end
		end
	end
end

ai_fill_skill.diy_zuguangu=function(self, options, request)
    local inclusive = options and options.inclusive

    return parse(self,"#diy_zuguangu:.:")
end

ai_card_use["#diy_zuguangu"] = function(self, card, use, request)
	if self.player:getChangeSkillState("diy_zuguangu") == 1 then
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
					if cc:isKindOf("BasicCard") or cc:isNDTrick() then
						local dummy_use = self:aiUseCard(cc, dummy(true))
						if dummy_use.card then
							use.card = card
							return 
						end
					end
				end
			end
		end
	else
		local all = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sortInPlace(all, "defense")
		for _,p in ipairs(all) do
			if (not self:isFriend(p)) and (not p:isKongcheng()) then
				local cards = sgs.QList2Table(fullhand(p))
				self:sortByUseValueInPlace(cards)
				local max = p:getHandcardNum()
				for _,cc in ipairs(cards) do
					local num = cc:nameLength()
					if cc:isKindOf("Slash") then num = 1 end
					if num > 4 or num > max then continue end
					if cc:isKindOf("BasicCard") or cc:isNDTrick() then
						local dummy_use = self:aiUseCard(cc, dummy(true))
						if dummy_use.card then
							use.card = card
							memory(self,"diy_zuguangu",p:objectName(),true)

							return 
						end
					end
				end
			end
		end
	end
end

sgs.ai_use_priority.diy_zuguangu = 8
sgs.ai_use_value.diy_zuguangu = 8


sgs.ai_skill_playerchosen.diy_zuguangu = function(self,targets)
	if saved_player(self,"diy_zuguangu") then return saved_player(self,"diy_zuguangu") end
	targets = sgs.QList2Table(targets)
	for _,p in ipairs(targets) do
		if (not self:isFriend(p)) and (not p:isKongcheng()) then
			local cards = sgs.QList2Table(fullhand(p))
			self:sortByUseValueInPlace(cards)
			local max = p:getHandcardNum()
			for _,cc in ipairs(cards) do
				local num = cc:nameLength()
				if cc:isKindOf("Slash") then num = 1 end
				if num > 4 or num > max then continue end
				if cc:isKindOf("BasicCard") or cc:isNDTrick() then
					local dummy_use = self:aiUseCard(cc, dummy(true))
					if dummy_use.card then
						return p
					end
				end
			end
		end
	end
	for _,p in ipairs(targets) do
		if not p:isKongcheng() and self:isEnemy(p) then
			return p
		end
	end
end

ai_skill_choice.diy_zuguangunum = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    if not saved_player(self,"diy_zuguangu") then
        if self.player:getHp() == 1 and self.player:isWounded() then
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
				if self.player:getStrategyMark("diy_zuxiaoyong-"..num.."-Clear") > 0 then continue end
                if num == i then
                    table.insert(cards, cc)
                end
            end
            if #cards > 0 then
                self:sortByUseValueInPlace(cards)
                for _,cc in ipairs(cards) do
					if cc:isKindOf("BasicCard") or cc:isNDTrick() then
						local dummy_use = self:aiUseCard(cc, dummy(true))
						if dummy_use.card then
							return ai_choice_result((tostring(i)), options)
						end
					end
                end
            end
        end
    else
		local target = saved_player(self,"diy_zuguangu")
        local cards = sgs.QList2Table(fullhand(target))
        self:sortByUseValueInPlace(cards)
        local max = target:getHandcardNum()
        for _,cc in ipairs(cards) do
            local num = cc:nameLength()
            if cc:isKindOf("Slash") then num = 1 end
            if num > 4 or num > max then continue end
            if self.player:getStrategyMark("diy_zuxiaoyong-"..num.."-Clear") > 0 then continue end
			if cc:isKindOf("BasicCard") or cc:isNDTrick() then
				local dummy_use = self:aiUseCard(cc, dummy(true))
				if dummy_use.card then
					return ai_choice_result((tostring(num)), options)
				end
			end
        end
    end
    return ai_choice_result((tostring(4)), options)
end

sgs.ai_skill_askforag.diy_zuguangu = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = face(self,id)
		if card:isKindOf("BasicCard") or card:isNDTrick() then
			local num = card:nameLength()
			if card:isKindOf("Slash") then num = 1 end
			if self.player:getStrategyMark("diy_zuxiaoyong-"..num.."-Clear") == 0 and num == self.player:getStrategyMark("&diy_zuguangu") then
				local dummy_use = self:aiUseCard(card, dummy())
				if card:isAvailable(self.player) and dummy_use.card then
					if card:canRecast() and dummy_use.to:length()<1 then continue end
					return id
				end
			end
		end
	end
	for _,id in ipairs(card_ids)do
		local card = face(self,id)
		if card:isKindOf("BasicCard") or card:isNDTrick() then
			local dummy_use = self:aiUseCard(card, dummy())
			if card:isAvailable(self.player) and dummy_use.card then
				if card:canRecast() and dummy_use.to:length()<1 then continue end
				return id
			end
		end
	end
end

ai_skill_use["@@diy_zuguangu"] = function(self, prompt, request)
	-- Own property; absent reads as the donor's empty toString().
	local pattern = self.player:getPropertyValue("diy_zuguangu") or ""
	local card = named(self,"diy_zuguangu",pattern,{})
    
    local dummy_use = self:aiUseCard(card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, to:objectName())
            end
            return answer(self,card,tos)
        else
            return answer(self,card,{})
        end
    end
end

sgs.ai_card_priority.diy_zuxiaoyong = function(self,card,v)
	local n, m = card:nameLength(), self.player:getStrategyMark("&diy_zuguangu")
	if self.player:getStrategyMark("diy_zuxiaoyong-"..m.."-Clear") < 1 and n == m
	then return 10 end
end

sgs.ai_skill_playerchosen.mjin_buchen = function(self,targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			return p
		end
	end
	return targets:first()
end
sgs.ai_playerchosen_intention.mjin_buchen = -40


ai_fill_skill.mjin_xiongzhi=function(self, options, request)
    local inclusive = options and options.inclusive

	return parse(self,"#mjin_xiongzhi:.:")
end

ai_card_use["#mjin_xiongzhi"] = function(self, card, use, request)
	if self.player:getStrategyMark("&mjin_quanbian-PlayClear") + 1 >= self.player:getMaxHp() then
		sgs.ai_use_priority.mjin_xiongzhi = 10
		use.card = card
	end
	local list = self:getSourceTopCardObservation("mjin_xiongzhi", 1)
	local use_num = 0
	for _,id in sgs.qlist(list)do
		local card = face(self,id)
		if not self.player:canUse(card) then break end
		if self:willUse(self.player, card)
		then use_num = use_num+1
		else break end
	end
	if use_num>0 then
		use.card = card
	end
end

sgs.ai_use_priority.mjin_xiongzhi = 0

sgs.ai_card_priority.mjin_xiongzhi = function(self,card,v)
	if self.player:getStrategyMark("&mjin_quanbian-PlayClear") + 1 >= self.player:getMaxHp() then
		sgs.ai_use_priority.mjin_xiongzhi = 10
		if table.contains(card:getSkillNames(), "mjin_xiongzhi") then
			return 10 
		end
	end
end


ai_skill_use["@@mjin_xiongzhi"] = function(self, prompt, request)
	local method = request and request.handling_method
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, card in ipairs(cards) do
		if card:hasFlag("mjin_xiongzhi") then
			local dummy = self:aiUseCard(card)
			if dummy.card and dummy.to then
				local tos = {}
				for _,p in sgs.qlist(dummy.to)do
					table.insert(tos,p:objectName())
				end
				return answer(self,card,tos)
			end
		end
	end
	return "."
end
ai_skill_invoke.mjin_quanbian = true


local function baobian_shensu(self,index,prompt)
 local plan=self:planShensuResponse(index, prompt)
 if not plan or plan=='.' then return '.' end
 if type(plan)~='table' or type(plan.subcards)~='table' or type(plan.targets)~='table' then
  ai_unsupported('Shensu source selector returned an unknown proposal ABI','rushB_baobian_shensu')
 end
 local costs={};for i,id in ipairs(plan.subcards)do costs[i]=id end
 local source='@ShensuCard='..(#costs==0 and '.' or table.concat(costs,'+'))..'->'..table.concat(plan.targets,'+')
 local wire=string.gsub(source,'@ShensuCard=','#rushB_baobian_shensu:')..':'
 -- Pinned donor leaves the final colon after the target names and has no
 -- registered #rushB_baobian_shensu prototype. Do not silently repair to V2.
 local signal=AIUnsupported.new('rushB donor Shensu rewritten terminal has no native prototype','rushB_baobian_shensu')
 signal.terminal_response_selection=true;signal.donor_terminal_unavailable=true
 signal.source_wire=wire;signal.selected_costs=costs;signal.selected_targets=plan.targets
 error(signal,0)
end
ai_skill_use["@@rushB_baobian_shensu1"]=function(self, prompt, request)
 return baobian_shensu(self,1,prompt)
end
ai_skill_use["@@rushB_baobian_shensu2"]=function(self, prompt, request)
 return baobian_shensu(self,2,prompt)
end

ai_skill_use["@@rushB_baobian_shensu3"] = function(self, prompt, request)
	self:sortInPlace(self.enemies, "defense")
	if self:needBear() then return "." end
	local selfSub = self:getOverflow()
	local selfDef = sgs.getDefense(self.player)
	for _,enemy in ipairs(self.enemies)do
		local def = self:getDefenseSlash(enemy)
		local slash = named(self,"_rushB_baobian_shensu","slash",{})
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif def<6 and eff then return "#rushB_baobian_shensu:.:->"..enemy:objectName()

		elseif selfSub>=2 then return "#rushB_baobian_shensu:.:->"..enemy:objectName()
		elseif selfDef<6 then return "." end
	end

	for _,enemy in ipairs(self.enemies)do
		local def=sgs.getDefense(enemy)
		local slash = named(self,"_rushB_baobian_shensu","slash",{})
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff and def<8 then return "#rushB_baobian_shensu:.:->"..enemy:objectName()
		else return "." end
	end
	return "."
end

ai_card_use["#rushB_baobian_tiaoxin"] = function(self, card, use, request)
	local distance = use.DefHorse and 1 or 0
	local targets = {}
	for _,enemy in ipairs(self.enemies)do
		if self:doDisCard(enemy, "he") and self:isTiaoxinTarget(enemy)
		then table.insert(targets,enemy) end
	end

	if #targets==0 then return end

	sgs.ai_use_priority.rushB_baobian_tiaoxin = 8
	if not self.player:getArmor() and not self.player:isKongcheng() then
		for _,c in sgs.qlist(self.player:getCards("h"))do
			if c:isKindOf("Armor") and self:evaluateArmor(c)>3 then
				sgs.ai_use_priority.rushB_baobian_tiaoxin = 5.9
				break
			end
		end
	end

	self:sortInPlace(targets, "defenseSlash")
	use.to:append(targets[1])
	use.card = card
end

-- audited alias ai_card_intention.rushB_baobian_tiaoxin
-- audited alias ai_use_priority.rushB_baobian_tiaoxin
ai_fill_skill.rushB_baobian=function(self, options, request)
    local inclusive = options and options.inclusive


    if self.player:getHp() > getBestHp(self.player) then
		return parse(self,"#rushB_baobian:.:")
	end
	if self.player:getHp() <= 3 then
		local cards = self.player:getCards("h")
		cards = self:sortByKeepValueInPlace(cards)
		if #cards>0 then
			return parse(self,"#rushB_baobian_tiaoxin:"..cards[1]:getEffectiveId()..":")
		end
	end
end

ai_card_use["#rushB_baobian"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.rushB_baobian = 9.4
sgs.ai_use_priority.rushB_baobian = 0.8

sgs.ai_getBestHp_skill.rushB_baobian = function(owner)
	return math.max(1, owner:getMaxHp() - 3)
end


ai_fill_skill.rushB_dimeng=function(self, options, request)
    local inclusive = options and options.inclusive

	if self:needBear() then return end
	return parse(self,"#rushB_dimeng:.:")
end
function DimengIsWorth(self, friend, enemy, mycards, myequips)
	local e_hand1, e_hand2 = enemy:getHandcardNum(), enemy:getHandcardNum() - self:getLeastHandcardNum(enemy)
	local f_hand1, f_hand2 = friend:getHandcardNum(), friend:getHandcardNum() - self:getLeastHandcardNum(friend)
	local e_peach, f_peach = getCardsNum("Peach", enemy), getCardsNum("Peach", friend)
	if e_hand1 < f_hand1 then
		return false
	elseif e_hand2 <= f_hand2 and e_peach <= f_peach then
		return false
	elseif e_peach < f_peach and e_peach < 1 then
		return false
	elseif e_hand1 == f_hand1 and e_hand1 > 0 then
		return hasTuntianEffect(friend, true)
	end
	local cardNum = #mycards
	local delt = e_hand1 - f_hand1 --assert: delt>0
	if delt > cardNum then
		return false
	end
	local equipNum = #myequips
	if equipNum > 0 then
		if self.player:hasSkills("xuanfeng|xiaoji|nosxuanfeng") then
			return true
		end
	end

	local soKeep = 0
	local soUse = 0
	local marker = math.ceil(delt / 2)
	for i=1, delt, 1 do
		local card = mycards[i]
		local keepValue = self:getKeepValue(card)
		if keepValue > 4 then
			soKeep = soKeep + 1
		end
		local useValue = self:getUseValue(card)
		if useValue >= 6 then
			soUse = soUse + 1
		end
	end
	if soKeep > marker then
		return false
	end
	if soUse > marker then
		return false
	end
	return true
end

local dimeng_discard = function(self, discard_num, mycards)
	local cards = mycards
	local to_discard = {}

	local aux_func = function(card)
		local place = self.room:getCardPlace(card:getKnownEffectiveId())
		if place == sgs.Player_PlaceEquip then
			if card:isKindOf("SilverLion") and self.player:isWounded() then return -2
			elseif card:isKindOf("OffensiveHorse") then return 1
			elseif card:isKindOf("Weapon") then return 2
			elseif card:isKindOf("DefensiveHorse") then return 3
			elseif card:isKindOf("Armor") then return 4
			end
		elseif self:getUseValue(card) >= 6 then return 3
		elseif self:hasSkills(sgs.lose_equip_skill) then return 5
		else return 0
		end
		return 0
	end

	local compare_func = function(a, b)
		if aux_func(a) ~= aux_func(b) then
			return aux_func(a) < aux_func(b)
		end
		return self:getKeepValue(a) < self:getKeepValue(b)
	end

	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if not self.player:isJilei(card) then table.insert(to_discard, card:getKnownId()) end
		if #to_discard >= discard_num then break end
	end
	if #to_discard ~= discard_num then return {} end
	return to_discard
end

ai_card_use["#rushB_dimeng"] = function(self, card, use, request)
	local mycards = {}
	local myequips = {}
	local keepaslash
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if not self.player:isJilei(c) then
			local shouldUse
			if not keepaslash and isCard("Slash", c, self.player) then
				local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
				self:useBasicCard(c, dummy_use)
				if dummy_use.card and not dummy_use.to:isEmpty() and (dummy_use.to:length() > 1 or dummy_use.to:first():getHp() <= 1) then
					shouldUse = true
				end
			end
			if not shouldUse then table.insert(mycards, c) end
		end
	end
	for _, c in sgs.qlist(self.player:getEquips()) do
		if not self.player:isJilei(c) then
			table.insert(mycards, c)
			table.insert(myequips, c)
		end
	end
	if #mycards == 0 then return end
	self:sortByKeepValueInPlace(mycards) --�ҵ�keepValue��5��useValue��6��˳��ǣ���keepValue��1.9��useValue��9

	self:sortInPlace(self.enemies, "handcard")
	local friends = {}
	for _, player in ipairs(self.friends_noself) do
		if not self:hasManjuanEffect(player) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return end

	self:sortInPlace(friends, "defense")
	local function cmp_HandcardNum(a, b)
		local x = a:getHandcardNum() - self:getLeastHandcardNum(a)
		local y = b:getHandcardNum() - self:getLeastHandcardNum(b)
		return x < y
	end
	table.sort(friends, cmp_HandcardNum)

	self:sortInPlace(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if self:hasManjuanEffect(enemy) then
			local e_hand = enemy:getHandcardNum()
			for _, friend in ipairs(friends) do
				local f_peach, f_hand = getCardsNum("Peach", friend), friend:getHandcardNum()
				if (e_hand > f_hand - 1) and (e_hand - f_hand) <= #mycards and (f_hand > 0 or e_hand > 0) and f_peach <= 2 then
					if e_hand == f_hand then
						use.card = card
					else
						local discard_num = e_hand - f_hand
						local discards = dimeng_discard(self, discard_num, mycards)
						if #discards > 0 then use.card = parse(self,"#rushB_dimeng:.:") end
					end
					if use.card and use.to then
						use.to:append(enemy)
						use.to:append(friend)
					end
					return
				end
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		local e_hand = enemy:getHandcardNum()
		for _, friend in ipairs(friends) do
			local f_hand = friend:getHandcardNum()
			if DimengIsWorth(self, friend, enemy, mycards, myequips) and (e_hand > 0 or f_hand > 0) then
				if e_hand == f_hand then
					use.card = card
				else
					local discard_num = math.abs(e_hand - f_hand)
					local discards = dimeng_discard(self, discard_num, mycards)
					if #discards > 0 then use.card = parse(self,"#rushB_dimeng:.:") end
				end
				if use.to then
					use.to:append(enemy)
					use.to:append(friend)
					end
				return
			end
		end
	end
end

sgs.ai_card_intention["#rushB_dimeng"] = function(self,card, from, to)
	local compare_func = function(a, b)
		return a:getHandcardNum() < b:getHandcardNum()
	end
	table.sort(to, compare_func)
	if to[1]:getHandcardNum() < to[2]:getHandcardNum() then
		self:updateIntention(from, to[1], -80)
	end
end

sgs.ai_use_value["#rushB_dimeng"] = 3.5
sgs.ai_use_priority["#rushB_dimeng"] = 2.8

sgs.dynamic_value.control_card["#rushB_dimeng"] = true

ai_fill_skill.rushB_diaogui=function(self, options, request)
    local inclusive = options and options.inclusive


	local cards = self.player:getCards("he")
	cards = self:sortByKeepValueInPlace(cards)
	for _,c in sgs.list(cards)do
		if c:isKindOf("EquipCard") then
			return parse(self,"#rushB_diaogui:"..c:getEffectiveId()..":")
		end
	end
end
ai_card_use["#rushB_diaogui"] = function(self, card, use, request)
	local max_friends = 0
    local best_target = nil

    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        local temp_friends = 0

        local simulated_next = p:getNextAlive()
        local simulated_prev = p:getNextAlive(self.room:alivePlayerCount() - 1)

        if self.player:isYourFriend(simulated_prev) then
            temp_friends = temp_friends + 1
        end

        if self.player:isYourFriend(simulated_next) then
            temp_friends = temp_friends + 1
        end

        if temp_friends > max_friends then
            max_friends = temp_friends
            best_target = p
        end
    end
	if best_target then
		use.card = card
		use.to:append(best_target)
	end
end

sgs.ai_use_priority["#rushB_diaogui"] = 5

ai_fill_skill.mmou_leiji=function(self, options, request)
    local inclusive = options and options.inclusive

	return parse(self,"#mmou_leiji:.:")
end

ai_card_use["#mmou_leiji"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "hp")
	for _,ep in sgs.list(self.enemies)do
		if self:damageIsEffective(ep, sgs.DamageStruct_Thunder, self.player) and self:canDamage(ep, self.player, nil) then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

ai_fill_skill.mmou_guidao=function(self, options, request)
    local inclusive = options and options.inclusive

	return parse(self,"#mmou_guidao:.:")
end

ai_card_use["#mmou_guidao"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_skill_cardask["@rushB_wushuang-slash"] = function(self,data,pattern,target)
	local use = data:toCardUse()
	local effect = {}
	effect.card = use.card
	effect.from = use.from
	effect.to = self.player
	local _data = {toCardEffect=function()return effect end}
	if nested(self,"ai_skill_cardask","duel-slash",self,_data,pattern,use.from) == "." then return "." end
	if self:getCardsNum("Slash")<3 then
		return "."
	end
	return true
end


sgs.ai_skill_cardask["@rushB_wushuang-jink"] = function(self,data,pattern,target)
	local use = data:toCardUse()
	local effect = {}
	effect.card = use.card
	effect.from = use.from
	effect.to = self.player
	local _data = {toCardEffect=function()return effect end}
	local slash = sourceuse(self,"SlashData")
	if slash and slash.offset_num > 1 then
		if nested(self,"ai_skill_cardask","@multi-jink-start",self,data,"jink",data:toCardEffect().from, nil, slash.offset_num) == "." then return "." end
	end
	return nested(self,"ai_skill_cardask","slash-jink",self,data,"jink",data:toCardEffect().from)
end


ai_skill_use["@rushB_huace"] = function(self, prompt, request)
	local c = engineface(self,self.player:getStrategyMark("rushB_huaceName"))
	local card = named(self,"rushB_huace",c:objectName(),{})
    local dummy_use = self:aiUseCard(card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, to:objectName())
            end
            return answer(self,dummy_use.card,tos)
        else
            return answer(self,dummy_use.card,{})
        end
    end
	return "."
end


ai_fill_skill.rushB_huace=function(self, options, request)
    local inclusive = options and options.inclusive

	memory(self,"rushB_huace",nil,true)
	local huaces = {}
	for _, id in sgs.qlist(self.room:getDiscardPile()) do
		local c = engineface(self,id)
		if (c:isKindOf("BasicCard") or c:isNDTrick()) and not (c:isKindOf("Suijiyingbian") or c:isKindOf("Jink") or c:isKindOf("Nullification") or c:isKindOf("FczhizheBasic") or c:isKindOf("FczhizheTrick") or c:isKindOf("KezhuanYing") or c:isKindOf("BigJoker") or c:isKindOf("SmallJoker")) then
			if not table.contains(huaces, c:objectName()) and self.player:getStrategyMark("rushB_huace"..c:objectName().."-PlayClear") < 1 then table.insert(huaces, c:objectName()) end
		end
	end
	if #huaces > 0 then
		for _, pn in sgs.list(RandomList(huaces)) do
			local dc = named(self,"rushB_huace",pn,{})
			local dummy_use = self:aiUseCard(dc, dummy())
			if dc:isAvailable(self.player) and dummy_use.card then
				if dc:canRecast() and dummy_use.to:length()<1 then continue end
				memory(self,"rushB_huace",pn,true)
				sgs.ai_use_priority.rushB_huace = sgs.ai_use_priority[dc:getClassName()]
				local card = parse(self,"#rushB_huace:.:")
				assert(card)
				return card
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local huaces = {}
	for _, id in draw_iter(self) do
		local c = engineface(self,id)
		if (c:isKindOf("BasicCard") or c:isNDTrick()) and not (c:isKindOf("Suijiyingbian") or c:isKindOf("Jink") or c:isKindOf("Nullification") or c:isKindOf("FczhizheBasic") or c:isKindOf("FczhizheTrick") or c:isKindOf("KezhuanYing") or c:isKindOf("BigJoker") or c:isKindOf("SmallJoker")) then
			if not table.contains(huaces, c:objectName()) and self.player:getStrategyMark("rushB_huace"..c:objectName().."-PlayClear") < 1 then table.insert(huaces, c:objectName()) end
		end
	end
	for _,c in sgs.list(cards)do
		for _, pn in sgs.list(RandomList(huaces)) do
			local dc = named(self,"rushB_huace",pn,{c:getKnownEffectiveId()})
			local dummy_use = self:aiUseCard(dc, dummy())
			if dc:isAvailable(self.player) and dummy_use.card then
				if dc:canRecast() and dummy_use.to:length()<1 then continue end
				memory(self,"rushB_huace",pn,true)
				sgs.ai_use_priority.rushB_huace = sgs.ai_use_priority[dc:getClassName()]
				local card = parse(self,"#rushB_huace:"..c:getEffectiveId() ..":")
				assert(card)
				return card
			end
		end
	end
end

ai_card_use["#rushB_huace"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.rushB_huace = 5.4
sgs.ai_use_priority.rushB_huace = 2.8

ai_skill_choice.rushB_huace = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	if memory(self,"rushB_huace") then return ai_choice_result((memory(self,"rushB_huace")), options) end
	local items = choices:split("+")
	for _, pn in sgs.list(RandomList(items)) do
		local dc = named(self,"rushB_huace",pn,{})
		local dummy_use = self:aiUseCard(dc, dummy())
		if dc:isAvailable(self.player) and dummy_use.card then
			if dc:canRecast() and dummy_use.to:length()<1 then continue end
			return ai_choice_result((pn), options)
		end
	end

    return ai_choice_result(nil, options)
end

ai_fill_skill.rushB_pizhuan=function(self, options, request)
    local inclusive = options and options.inclusive

	return parse(self,"#rushB_pizhuan:.:")
end

ai_card_use["#rushB_pizhuan"] = function(self, card, use, request)
	use.card = card
end


ai_skill_use["@@rushB_tongbo"] = function(self, prompt, request)
	local c = engineface(self,self.player:getStrategyMark("rushB_tongboName"))
	local card = named(self,"_rushB_tongbo",c:objectName(),{})

    local dummy_use = self:aiUseCard(card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, to:objectName())
            end
            return answer(self,card,tos)
        else
            return answer(self,card,{})
        end
    end
	return "."
end

ai_skill_choice.rushB_tongbo = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	if memory(self,"rushB_tongbo") then return ai_choice_result((memory(self,"rushB_tongbo")), options) end
	local items = choices:split("+")
	for _, pn in sgs.list(RandomList(items)) do
		local dc = named(self,"rushB_tongbo",pn,{})
		local dummy_use = self:aiUseCard(dc, dummy())
		if dc:isAvailable(self.player) and dummy_use.card then
			if dc:canRecast() and dummy_use.to:length()<1 then continue end
			return ai_choice_result((pn), options)
		end
	end

    return ai_choice_result(nil, options)
end

ai_fill_skill.rushB_tongbo=function(self, options, request)
    local inclusive = options and options.inclusive

	memory(self,"rushB_tongbo",nil,true)
	local to_use = {}
	local suits = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	for _, card in ipairs(cards) do
		if not table.contains(suits, card:getSuitString()) then
			table.insert(to_use, card:getKnownId())
			table.insert(suits, card:getSuitString())
			if #to_use == self.player:getPile("bookpile"):length() then break end
		end
	end
	if #to_use < self.player:getPile("bookpile"):length() then
		return
	end
	local choices = {}
	for _,id in draw_iter(self) do
		    local card = engineface(self,id)
			if card:isNDTrick() or card:isKindOf("BasicCard") then
				if table.contains(choices, card:objectName()) or card:isKindOf("Jink") or card:isKindOf("Nullification") then continue end
				local transcard = named(self,"rushB_tongbo",card:objectName(),{})
				
				if not transcard:isAvailable(self.player) then continue end
				if self.player:getStrategyMark("rushB_tongbo".."+"..card:objectName().."-Clear") < 1 then table.insert(choices, card:objectName()) end
			end
			if not self.player:isWounded() then
				table.removeOne(choices, "peach")
			end
			if not sgs.Slash_IsAvailable(self.player) then
				table.removeOne(choices, "slash")
				table.removeOne(choices, "ice_slash")
				table.removeOne(choices, "thunder_slash")
				table.removeOne(choices, "fire_slash")
			end
			if not sgs.Analeptic_IsAvailable(self.player) then
				table.removeOne(choices, "analeptic")
			end
		end
		for _,id in sgs.qlist(self.room:getDiscardPile()) do
		    local card = engineface(self,id)
			if card:isNDTrick() or card:isKindOf("BasicCard") then
				if table.contains(choices, card:objectName()) or card:isKindOf("Jink") or card:isKindOf("Nullification") then continue end
				local transcard = named(self,"rushB_tongbo",card:objectName(),{})
				
				if not transcard:isAvailable(self.player) then continue end
				if self.player:getStrategyMark("rushB_tongbo".."+"..card:objectName().."-Clear") < 1 then table.insert(choices, card:objectName()) end
			end
			if not self.player:isWounded() then
				table.removeOne(choices, "peach")
			end
			if not sgs.Slash_IsAvailable(self.player) then
				table.removeOne(choices, "slash")
				table.removeOne(choices, "ice_slash")
				table.removeOne(choices, "thunder_slash")
				table.removeOne(choices, "fire_slash")
			end
			if not sgs.Analeptic_IsAvailable(self.player) then
				table.removeOne(choices, "analeptic")
			end
		end
	for _, pn in sgs.list(RandomList(choices)) do
		local dc = named(self,"rushB_tongbo",pn,{self.player:getPile("bookpile"):first()})
		local dummy_use = self:aiUseCard(dc, dummy())
		if dc:isAvailable(self.player) and dummy_use.card then
			if dc:canRecast() and dummy_use.to:length()<1 then continue end
			memory(self,"rushB_tongbo",pn,true)
			sgs.ai_use_priority.rushB_tongbo = sgs.ai_use_priority[dc:getClassName()]
			local card = parse(self,"#rushB_tongbo:".. table.concat(to_use, "+") ..":")
			assert(card)
			return card
		end
	end
	
end

ai_card_use["#rushB_tongbo"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.rushB_tongbo = 5.4
sgs.ai_use_priority.rushB_tongbo = 2.8


ai_skill_use["@@rushB_xiongsuan"] = function(self, prompt, request)
	local c = engineface(self,self.player:getStrategyMark("rushB_xiongsuanName"))
	local card = named(self,"_rushB_xiongsuan",c:objectName(),{})
    local dummy_use = self:aiUseCard(card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, to:objectName())
            end
            return answer(self,card,tos)
        else
            return answer(self,card,{})
        end
    end
	return "."
end
ai_skill_choice.rushB_xiongsuan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local choices = {}
	for _,id in sgs.qlist(random_catalogue(self)) do
		local card = engineface(self,id)
		if card:isKindOf("BasicCard") or card:isNDTrick() then
			if table.contains(choices, card:objectName()) then continue end
			local transcard = named(self,"rushB_xiongsuan",card:objectName(),{})
			if not transcard:isAvailable(self.player) then continue end
			if self.player:getStrategyMark("rushB_xiongsuan+"..card:objectName().."-Clear") < 1 then table.insert(choices, card:objectName()) end
		end
	end
	if nested(self,"ai_skill_choice","rushB_xiongsuanUse",self,{reason="rushB_xiongsuanUse",choices=choices,inquiry_scope="nested"},nil) ~= "cancel" then
		return ai_choice_result(("yes"), options)
	end
	return ai_choice_result(("no"), options)
end
ai_skill_choice.rushB_xiongsuanUse = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	for _, pn in sgs.list(RandomList(items)) do
		local dc = named(self,"_rushB_xiongsuan",pn,{})
		local dummy_use = self:aiUseCard(dc, dummy())
		if dc:isAvailable(self.player) and dummy_use.card then
			if dc:canRecast() and dummy_use.to:length()<1 then continue end
			return ai_choice_result((pn), options)
		end
	end
	return ai_choice_result(("cancel"), options)
end


ai_fill_skill.rushB_moutongye=function(self, options, request)
    local inclusive = options and options.inclusive

	local n = self.player:getChangeSkillState("rushB_moutongye")
	if n == 1 then
		if self:getCardsNum("BasicCard")>self:getCardsNum("TrickCard")+self:getCardsNum("EquipCard") then
			return parse(self,"#rushB_moutongye:.:")
		end
	elseif n == 2 then
		if self:getCardsNum("TrickCard")>self:getCardsNum("EquipCard")+self:getCardsNum("BasicCard") then
			return parse(self,"#rushB_moutongye:.:")
		end
	elseif n == 3 then
		if self:getCardsNum("EquipCard")>self:getCardsNum("TrickCard")+self:getCardsNum("BasicCard") then
			return parse(self,"#rushB_moutongye:.:")
		end
	end
end

ai_card_use["#rushB_moutongye"] = function(self, card, use, request)
	use.card = card
end
sgs.ai_use_priority.rushB_moutongye = 10

sgs.ai_card_priority.rushB_xingtu = function(self,card,v)
	if self.player:getStrategyMark("&rushB_xingtunum") % card:getNumber() == 0 or card:getNumber() % self.player:getStrategyMark("&rushB_xingtunum") == 0
	then return 10 end
end


ai_fill_skill.rushB_juezhi=function(self, options, request)
    local inclusive = options and options.inclusive

	sgs.ai_use_priority.rushB_juezhi = 3
	if self.player:getCardCount(true)<2 then return false end
	if self:getOverflow()<=0 then return false end
	if self:isWeak() and self:getOverflow()<=1 then return false end
	return parse(self,"#rushB_juezhi:.:")
end
ai_card_use["#rushB_juezhi"] = function(self, card, use, request)
	local num = self.player:getStrategyMark("&rushB_xingtunum")
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)

	for _,c1 in ipairs(cards)do
		local temp = 0
		temp = temp + c1:getNumber()
		for _,c in ipairs(cards)do
			if c1 ~= c then
				if not self.player:isCardLimited(c, sgs.Card_MethodDiscard) and not self.player:isCardLimited(c1, sgs.Card_MethodDiscard) and c1:getNumber() % c:getNumber() == 0 then
					if table.contains(unpreferedCards,c:getKnownId()) then continue end
					if (((temp + c:getNumber()) % num) == 0) then
						temp = temp + c:getNumber()
						table.insert(unpreferedCards,c:getKnownId())
						table.insert(unpreferedCards,c1:getKnownId())
						break
					end
					
				end
				if #unpreferedCards==2 then break end
			end
		end
		if #unpreferedCards==2 then break end
	end

	if #unpreferedCards==2 then
		use.card = parse(self,"#rushB_juezhi:"..table.concat(unpreferedCards,"+")..":")
		sgs.ai_use_priority.rushB_juezhi = 0
		return
	end
	for _,c1 in ipairs(cards)do
		for _,c in ipairs(cards)do
			if c1 ~= c then
				if not self.player:isCardLimited(c, sgs.Card_MethodDiscard) and not self.player:isCardLimited(c1, sgs.Card_MethodDiscard) and c1:getNumber() % c:getNumber() == 0 then
					if table.contains(unpreferedCards,c:getKnownId()) then continue end
					table.insert(unpreferedCards,c:getKnownId())
					table.insert(unpreferedCards,c1:getKnownId())
					break
				end
				if #unpreferedCards==2 then break end
			end
		end
		if #unpreferedCards==2 then break end
	end
	use.card = parse(self,"#rushB_juezhi:"..table.concat(unpreferedCards,"+")..":")
	sgs.ai_use_priority.rushB_juezhi = 0
	return
end

sgs.ai_use_priority.rushB_juezhi = 3

ai_fill_skill.sgskanxue=function(self, options, request)
    local inclusive = options and options.inclusive

	return parse(self,"#sgskanxue:.:")
end
ai_card_use["#sgskanxue"] = function(self, card, use, request)
	use.card = card
end
sgs.ai_use_priority.sgskanxue = 10

ai_skill_choice.sgskanxue = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	if table.contains(items, "throwsame") then
		return ai_choice_result(("throwsame"), options)
	end
	return ai_choice_result((items[math.random(1, #items)]), options)
end

ai_fill_skill.sgszhenhua=function(self, options, request)
    local inclusive = options and options.inclusive

	return parse(self,"#sgszhenhua:.:")
end
ai_card_use["#sgszhenhua"] = function(self, card, use, request)
	for _,enemy in ipairs(self.enemies)do
		if self:doDisCard(enemy, "he") and enemy:getStrategyMark("sgszhenhua-Clear") == 0 then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end
-- audited alias ai_use_priority.sgszhenhua
sgs.ai_skill_playerchosen["sgszhenhua"] = sgs.ai_skill_playerchosen.zero_card_as_slash

ai_skill_invoke.rushB_kanxue = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self.player:getHujia() < 5 and self.player:getHp() + self:getAllPeachNum() - 1 > 0) or false
end


sgs.ai_view_as.rushB_kanxue = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return view(own_ai(player),("slash:rushB_kanxue[%s:%s]=%d"):format(suit,number,card_id))
	end
end

ai_fill_skill.rushB_kanxue=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile("he")
	cards = self:sortByUseValueInPlace(cards, true)
	local red_card = {}
	local useAll = false
	self:sortInPlace(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<2 and not enemy:hasArmorEffect("EightDiagram")
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end
	self:sortInPlace(self.enemies, "defense")

	for _,card in ipairs(cards)do
		if card:isRed() and not card:isKindOf("Slash") 	and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or (evaluation(self)):getTargetResidue(self.player)>0)
		then table.insert(red_card,card) end
	end


	for _,card in ipairs(red_card)do
		local slash = named(self,"rushB_kanxue","slash",{card:getKnownEffectiveId()})
		if slash:isAvailable(self.player)
		then return slash end
	end
end

ai_skill_invoke.rushB_kanxue_yuqi = true

ai_skill_use["@@DIT_qianxun!"] = function(self, prompt, request)
	return response(self,"#DIT_qianxun:.:")
end

ai_skill_choice["@DIT_qianxun"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result(("yes"), options)
end


sgs.ai_view_as.DIT_duoshi = function(card, player, card_place)
	local usable_cards = sgs.QList2Table(player:getCards("h"))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(usable_cards, face(self,id))
		end
	end
	local two_cards = {}
	for _, c in ipairs(usable_cards) do
		if #two_cards < 2 then
			table.insert(two_cards, c:getKnownEffectiveId())
		end
	end
	if #two_cards == 2 and not card:isKindOf("Jink") then
		return view(own_ai(player),("jink:DIT_duoshi[%s:%s]=%d+%d"):format("to_be_decided", 0, two_cards[1], two_cards[2]))
	end
	if #two_cards == 2 and not card:isKindOf("Slash") then
		return view(own_ai(player),("slash:DIT_duoshi[%s:%s]=%d+%d"):format("to_be_decided", 0, two_cards[1], two_cards[2]))
	end
end


ai_fill_skill.DIT_duoshi=function(self, options, request)
    local inclusive = options and options.inclusive

	return turnUse_spear(self,"DIT_duoshi",request)
end

ai_fill_skill.DIT_if_mouhuoji=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile("he")
	local card
	self:sortByUseValueInPlace(cards, true)
	for _,acard in ipairs(cards)do
		if acard:isRed() and not acard:isKindOf("Peach") and (self:getDynamicUsePriority(acard)<sgs.ai_use_value.FireAttack or self:getOverflow()>0) then
			if acard:isKindOf("Slash") and self:getCardsNum("Slash")==1 then
				local keep
				local dummy_use = dummy()
				self:useBasicCard(acard, dummy_use)
				if dummy_use.card and dummy_use.to and dummy_use.to:length()>0 then
					for _,p in sgs.list(dummy_use.to)do
						if p:getHp()<=1 then keep = true break end
					end
					if dummy_use.to:length()>1 then keep = true end
				end
				if keep then sgs.ai_use_priority.Slash = sgs.ai_use_priority.FireAttack+0.1
				else
					sgs.ai_use_priority.Slash = 2.6
					card = acard
					break
				end
			else
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	return parse(self,("fire_attack:DIT_if_mouhuoji[%s:%s]=%d"):format(suit,number,card_id))
end

sgs.ai_skill_cardask["@DIT_if_mouhuoji"] = function(self,data,pattern, target, target2)
	local use = data:toCardUse()
	if (not self:isFriend(target2) or target2:isChained())
		and self:damageIsEffective(target2, use.card) then
		return true
	end
    return "."
end

ai_skill_choice.DIT_if_mouhuoji = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result(("1"), options)
end

sgs.ai_skill_askforag.DIT_if_mouhuoji = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = face(self,id)
		if getCardsNum(card:getSuitString(),self.player,self.player)> 0 then
			return id
		end
	end
end
sgs.ai_cardneed.DIT_if_mouhuoji = function(to,card,self)
	return nested(self,"ai_cardneed","huoji",to,card,self)
end

sgs.ai_view_as.DIT_if_moukanpo = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place==sgs.Player_PlaceHand or card_place==sgs.Player_PlaceEquip then
		if card:isBlack() then
			return view(own_ai(player),("nullification:DIT_if_moukanpo[%s:%s]=%d"):format(suit,number,card_id))
		end
	end
end

ai_skill_choice.DIT_if_moukanpo = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result(("1"), options)
end

sgs.ai_cardneed.DIT_if_moukanpo = function(to,card,self)
	return nested(self,"ai_cardneed","kanpo",to,card,self)
end


ai_skill_invoke.mk_danlveYY = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
	if use.card:isKindOf("DelayedTrick") or use.card:isKindOf("EquipCard") then return (false) or false end
    return (true) or false
end
ai_skill_invoke.mk_danlveQG = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
	if use.card:isKindOf("DelayedTrick") or use.card:isKindOf("EquipCard") then return (false) or false end
    return (true) or false
end


ai_fill_skill.mk_danlve_yinyue=function(self, options, request)
    local inclusive = options and options.inclusive

	local cs = {}
	for _,id in sgs.list(self.player:getPile("mk_danlve_yinyue"))do
		local card = face(self,id)
		card = touch_physical(self,card,"mk_danlve_yinyue")
		table.insert(cs,card)
	end
	return cs
end

function sgs.ai_cardsview.mk_danlve_yinyue(self,class_name,player)
	for _,id in sgs.list(player:getPile("mk_danlve_yinyue"))do
		if face(self,id):isKindOf(class_name) then 
			local card = face(self,id)
			card = touch_physical(self,card,"mk_danlve_yinyue")
			return card:toString() 
		end
	end
end
ai_fill_skill.mk_danlve_qinggang=function(self, options, request)
    local inclusive = options and options.inclusive

	local cs = {}
	for _,id in sgs.list(self.player:getPile("mk_danlve_qinggang"))do
		local card = face(self,id)
		card = touch_physical(self,card,"mk_danlve_qinggang")
		table.insert(cs,card)
	end
	return cs
end

function sgs.ai_cardsview.mk_danlve_qinggang(self,class_name,player)
	for _,id in sgs.list(player:getPile("mk_danlve_qinggang"))do
		if face(self,id):isKindOf(class_name) then 
			local card = face(self,id)
			card = touch_physical(self,card,"mk_danlve_qinggang")
			return card:toString() 
		end
	end
end

ai_skill_invoke.mk_kongying = true

sgs.ai_ajustdamage_from.mk_kongying = function(self,from,to,card,nature)
	if card and from:getStrategyMark("mk_kongyingJS") == card:getKnownEffectiveId()
	then return 1 end
end

sgs.ai_card_priority.mk_kongying = function(self,card,v)
	if self.player:getStrategyMark("&mk_kongying")==1
	and table.contains(card:getSkillNames(), "mk_danlve_qinggang")
	then return 10 end
	if self.player:getStrategyMark("&mk_kongying")==0
	and table.contains(card:getSkillNames(), "mk_danlve_yinyue") and self.player:getPile("mk_danlve_qinggang"):length() > 0
	then return 10 end
end


ai_audited_aliases.register({id="ai_skill_playerchosen.diy_k_qizhi",registry="ai_skill_playerchosen",path={"diy_k_qizhi"},canonical_registry="ai_skill_playerchosen",canonical_path={"qizhi"},self_index=1,defer_canonical=true})

ai_audited_aliases.register({id="ai_use_priority.diy_k_qice",registry="ai_use_priority",path={"diy_k_qice"},canonical_registry="ai_use_priority",canonical_path={"QiceCard"},self_index=1,defer_canonical=true})

ai_audited_aliases.register({id="ai_card_intention.rushB_baobian_tiaoxin",registry="ai_card_intention",path={"rushB_baobian_tiaoxin"},canonical_registry="ai_card_intention",canonical_path={"TiaoxinCard"},self_index=1,defer_canonical=true})

ai_audited_aliases.register({id="ai_use_priority.rushB_baobian_tiaoxin",registry="ai_use_priority",path={"rushB_baobian_tiaoxin"},canonical_registry="ai_use_priority",canonical_path={"TiaoxinCard"},self_index=1,defer_canonical=true})

ai_audited_aliases.register({id="ai_use_priority.sgszhenhua",registry="ai_use_priority",path={"sgszhenhua"},canonical_registry="ai_use_priority",canonical_path={"Dismantlement"},self_index=1,defer_canonical=true})
