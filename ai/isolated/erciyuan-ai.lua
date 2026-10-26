-- Source: b6025acc ai/erciyuan-ai.lua.
local package_skills={}
local known = AIValue.requireKnown


local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return self:legacySkillSeed(skill, class, action_request(self,request)) end
local skill_cards={['#LuaChitian']='LuaChitian',['#LuaQisi']='LuaQisi',['#luablackflamecard']='luablackflame',['#luaboxuecard']='luaboxue',['#luagongluecard']='luagonglue',['#luaposhicard']='luaposhi',['#luarenzhacard']='luarenzha',['#luasaoshecard']='luasaoshe',['#luasynchrogazercard']='luasynchrogazer',['#luatiaojiaocard']='luatiaojiao',['#luatouyingcard']='luatouying',['#luayingxiancard']='luayingxian',['#luayuehuangcard']='luayuehuang',['#luayukongcard']='luayukong',['#slyanhuocard']='slyanhuo',['#yanhuoacquirecard']='yanhuoacquire'}
local function disclosed(self,id)return known(self:getKnownCardById(id)or self:getChoiceCard(id),'erciyuan source card '..tostring(id))end
local function parts(wire)
 local class,raw,user=wire:match('^(#[^:]+):([^:]*):(.*)$');if not class then return end
 local costs={};for id in raw:gmatch('%d+')do costs[#costs+1]=tonumber(id)end
 return class,costs,user~=''and user or nil
end
local function parse(self,request,wire)
 local class,costs,user=parts(wire)
 if class then local skill=known(skill_cards[class],class)
  if #costs==0 and user==nil then return seed(self,skill,class,request)end
  return self:evaluateTurnSkillCard(skill, class, costs, action_request(self,request), user)
 end
 local name,skill,raw=wire:match('^([^:]+):([^%[]+)%[[^%]]+%]=(.*)$')
 if not name then ai_unsupported('unrecognized source card grammar',wire)end
 costs={};local cards={};for id in raw:gmatch('%d+')do costs[#costs+1]=tonumber(id);cards[#cards+1]=disclosed(self,tonumber(id))end
 local suit,number=sgs.Card_NoSuit,0
 if #cards==1 then suit,number=cards[1]:getSuit(),cards[1]:getNumber()
 elseif #cards>1 then local red,black=true,true;for _,c in ipairs(cards)do red=red and c:isRed();black=black and c:isBlack()end;suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit end
 return self:evaluateTurnConversion(skill, (self:getEvaluationCard(name)):getClassName(), {name=name,skill=skill,suit=suit,number=number,subcards=costs}, action_request(self,request))
end
local function final_parse(self,request,wire)
 local class,costs,user=parts(wire)
 return self:bindSkillCard(known(skill_cards[class],class), costs, action_request(self,request), user, class)
end
local function whole_hand(self,player)
 if player:objectName()==self.player:objectName()then return player:getHandcards()end
 local cards=player:getKnownCards()
 if #cards~=player:getHandcardNum()then ai_unsupported('erciyuan source requires full foreign hand sorting','erciyuan.whole_hand')end
 return cards
end
local function he_count(player)return player:getHandcardNum()+#player:getEquips()end
local function material(card,name,skill)return{name=name,skill=skill,suit=card:getSuit(),number=card:getNumber(),subcards={card:getKnownEffectiveId()}}end
local function player_disclosed(player,id)
 for _,cards in ipairs({player:getCards('he'),player:getHandPileCards()})do for _,card in ipairs(cards)do if card:getKnownEffectiveId()==id then return card end end end
 ai_unsupported('LuaChitian owner card not disclosed',tostring(id))
end
local function event_value(self,key,standard)
 -- The room's CurrentDamageStruct reaches the VM only as the ask's context damage.
 local context=self:getDecisionContext();local row=known(context[standard and 'damage' or key],key)
 if type(row)~='table'then ai_unsupported('erciyuan current event absent',key)end
 local result={};for k,v in pairs(row)do result[k]=v end
 for _,field in ipairs({'from','to','who'})do local v=result[field];if type(v)=='string'then result[field]=v~=''and known(self.room:findPlayerByObjectName(v),key..'.'..field)or nil elseif v==false then result[field]=nil end end
 if result.card and type(result.card.isKindOf)~='function'then result.card=CardView.new(result.card)end
 if result.amount~=nil then result.damage=result.amount end
 return result
end
local function owner_eval(self,skill,name,suit,number)return self:evaluateOwnerViewAsCard({source_key=skill,skill=skill,name=name,suit=suit,number=number,subcards={}})end
local function get_weixiao(self)local name=self:getStrategyMemory('erciyuan.weixiao');return name and known(self.room:findPlayerByObjectName(name,true),'weixiao remembered player')or nil end
local function set_weixiao(self,p)self:setStrategyMemory('erciyuan.weixiao',p and p:objectName()or nil)end
local function get_weixiao_choice(self)return self:getStrategyMemory('erciyuan.weixiaochoice')end
local function set_weixiao_choice(self,v)self:setStrategyMemory('erciyuan.weixiaochoice',v)end
local function target_flag(self,p,value)
 local name=p:objectName();local epochs=known(AIWorldLifecycle.epochs(self.world,'flag'),'strategy_flag_clear_epochs');local epoch=known(epochs[name],'target clear epoch')
 local key='erciyuan.tiaojiao_target:'..name;local row=self:getStrategyMemory(key)
 if value~=nil then self:setStrategyMemory(key,{epoch=epoch,value=value});return end
 return row~=nil and row.epoch==epoch and row.value==true
end
local function current_visible_hand(self,player)
 local current=self.room:getCurrent()
 if current:objectName()~=self.player:objectName()then ai_unsupported('LuaBimie source visibility is another actor private observation','LuaBimie.current_observer')end
 -- Known cards are exactly the hand cards flagged visible to this viewer (or an open hand).
 return player:getKnownCards()
end
local function source_turn_spear(self,skill_name,request)
 -- Fixed caller passes inclusive as skill_name; do not repair its ignored third arg.
 local selected={};local cards=self:sortByUseValue(self:addHandPile(), nil, true)
 for _,card in ipairs(cards)do
  if self:isCard('Peach',card,self.player)or self:isCard('ExNihilo',card,self.player)and self.player:getPhase()<=sgs.Player_Play then continue end
  selected[#selected+1]=card
 end
 if #selected<2 or #cards<self.player:getHp()and self.player:getHp()<5 and not self:needKongcheng()then return nil end
 local slashes={};local remaining=AIList.new(selected)
 for _,c1 in ipairs(selected)do
  if #slashes>#selected/2 or #slashes>3 then break end
  table.removeOne(remaining,c1)
  for _,c2 in ipairs(remaining)do
   local card=parse(self,request,'slash:'..skill_name..'[no_suit:0]='..c1:getKnownId()..'+'..c2:getKnownId())
   if card:isAvailable(self.player)then slashes[#slashes+1]=card end
  end
 end
 return #slashes>0 and slashes
end
sgs.ai_chaofeng.itomakoto = -2
sgs.ai_chaofeng.ayanami = 3
sgs.ai_chaofeng.keima = 0
sgs.ai_chaofeng.SPkirito = 3
sgs.ai_chaofeng.odanobuna = 3
sgs.ai_chaofeng.yuuta = -2
sgs.ai_chaofeng.tsukushi = -2
sgs.ai_chaofeng.mao_maoyu = 1
sgs.ai_chaofeng.sheryl = 5
sgs.ai_chaofeng.aoitori = 3
sgs.ai_chaofeng.batora = -4
sgs.ai_chaofeng.kyouko = 4
sgs.ai_chaofeng.diarmuid = 6
sgs.ai_chaofeng.ikarishinji = -5
sgs.ai_chaofeng.redarcher = 2
sgs.ai_chaofeng.redo = 2
sgs.ai_chaofeng.runaria = -3
sgs.ai_chaofeng.fuwaaika = 5
sgs.ai_chaofeng.slsty = -2
sgs.ai_chaofeng.rokushikimei = 4
sgs.ai_chaofeng.bernkastel = 5
sgs.ai_chaofeng.hibiki = 4
sgs.ai_chaofeng.kntsubasa = 2
sgs.ai_chaofeng.khntmiku = 5
sgs.ai_chaofeng.yukinechris = 5



local function isEquip(name, player)
	for _, e in sgs.qlist(player:getEquips()) do
		if e:isKindOf(name) then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardchosen.renzha = function(self, who, flags)
	local cards = whole_hand(self,who)
	self:sortByUseValue(cards, true)
	return cards:first()
end

ai_skill_invoke.ak_renzha = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	local x = self.player:getMark("ak_renzha")
	if damage.damage >= 2 and x >= 2 then
		return (true) or false
	end
	if not self.player:faceUp() then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_skill_discard.ak_renzha = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = AIList.new(cards)
	self:sortByKeepValueInPlace(cards)
	table.insert(to_discard, cards[1]:getEffectiveId())
	return to_discard
end

sgs.ai_need_damaged.ak_renzha = function(self, attacker, player)
	if not (player:hasSkill("chanyuan") and player:getHp() == 2) and player:hasSkill("ak_renzha") and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() >= 2 and not player:faceUp()) then
		return true
	end
	return false
end

sgs.ai_can_damagehp.ak_renzha = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to)  and self:getEnemyNumBySeat(self.room:getCurrent(), to, to, true) < to:getHp()
end


local luarenzha_skill = {}
luarenzha_skill.name = "luarenzha"
table.insert(package_skills, luarenzha_skill)
luarenzha_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luarenzhacard") then return end
	if self.player:getPile("zha"):length() == 0 then return end

	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and self:isWeak(lord) then return end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) then
			if self:isFriend(player) then
				bad = bad + 1
			else
				good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(player:getHp(), 1)
		if getCardsNum("Analeptic", player) > 0 then
			if self:isFriend(player) then
				good = good + 1.0 / hp
			else
				bad = bad + 1.0 / hp
			end
		end

		local has_slash = (getCardsNum("Slash", player) > 0)
		local can_slash = false
		if not can_slash then
			for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
				if player:distanceTo(p) <= player:getAttackRange() then
					can_slash = true
					break
				end
			end
		end
		if not has_slash or not can_slash then
			if self:isFriend(player) then
				good = good + math.max(getCardsNum("Peach", player), 1)
			else
				bad = bad + math.max(getCardsNum("Peach", player), 1)
			end
		end

		if getCardsNum("Jink", player) == 0 then
			local lost_value = 0
			if self:hasSkills(sgs.masochism_skill, player) then lost_value = player:getHp() / 2 end
			local hp = math.max(player:getHp(), 1)
			if self:isFriend(player) then
				bad = bad + (lost_value + 1) / hp
			else
				good = good + (lost_value + 1) / hp
			end
		end
	end

	if self.player:isWounded() then
		good = good + math.min(self.player:getPile("zha"):length(), self.player:getLostHp())
	end
	if self.player:faceUp() then
		bad = bad +
			0.5 * self.room:getOtherPlayers(self.player):length() /
			math.min(self.player:getPile("zha"):length(), self.player:getLostHp())
	end
	if good > bad then
		local renzha = disclosed(self,self.player:getPile("zha"):first())
		return parse(self,request,"#luarenzhacard:" .. renzha:getKnownId() .. ":")
	end
end

ai_card_use["#luarenzhacard"] = function(self, card, use, request)
	use.card = card
	return
end

sgs.ai_use_priority["luarenzhacard"]    = 4.2
sgs.ai_card_intention["luarenzhacard"]  = 0


ai_audited_aliases.register{id="ai_cardneed.weixiao",registry="ai_cardneed",path={"weixiao"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
sgs.ai_skill_discard.weixiao            = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = AIList.new(cards)
	if self.player:getHandcardNum() < 2 then return {} end
	local max_number = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		max_number = math.max(max_number, card:getNumber())
	end
	if max_number >= 4 then
		local card_num_max = 0
		local card_n
		local card_num_max2 = 0
		local card_n2
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:getNumber() > card_num_max then
				card_num_max2 = card_num_max
				card_num_max = card:getNumber()
				card_n2 = card_n
				card_n = card
			else
				if card:getNumber() <= card_num_max and card:getNumber() > card_num_max2 then
					card_num_max2 = card:getNumber()
					card_n2 = card
				end
			end
		end
		local x = card_num_max2 / 2
		local n = card_num_max / 2
		set_weixiao(self,nil)
		self:updatePlayers()
		if #self.friends == 1 then
			set_weixiao(self,self.player)
			set_weixiao_choice(self,"a")
			if card_n and card_n2 then
				table.insert(to_discard, card_n:getKnownEffectiveId())
				table.insert(to_discard, card_n2:getKnownEffectiveId())
				return to_discard
			end
		end
		local player = self:AssistTarget()

		if x == 1 then
			set_weixiao(self,self.player)
		elseif #self.friends > 1 then
			self:sortInPlace(self.friends, "chaofeng")
			if not get_weixiao(self) and (self:isWeak(self.player) or self.player:getHandcardNum() <= 4) and not self:needKongcheng(self.player, true) then
				set_weixiao(self,self.player)
			end
			if not get_weixiao(self) and #self.enemies > 0 then
				local wf
				if self.player:isLord() then
					if self:isWeak() and (self.player:getHp() < 2 and self:getCardsNum("Peach") < 1) then
						wf = true
					end
				end
				if not wf then
					for _, friend in ipairs(self.friends) do
						if self:isWeak(friend) then
							wf = true
							break
						end
					end
				end

				if not wf then
					self:sortInPlace(self.enemies, "chaofeng")
					for _, enemy in ipairs(self.enemies) do
						if he_count(enemy) == n
							and self:doDisCard(enemy, "he", false, n) then
							set_weixiao_choice(self,"b")
							set_weixiao(self,enemy)
							if card_n and card_n2 then
								table.insert(to_discard, card_n:getKnownEffectiveId())
								table.insert(to_discard, card_n2:getKnownEffectiveId())
								return to_discard
							end
						end
					end
					for _, enemy in ipairs(self.enemies) do
						if he_count(enemy) >= n
							and self:doDisCard(enemy, "he", false, n)
							and self:hasSkills(sgs.cardneed_skill, enemy) then
							set_weixiao_choice(self,"b")
							set_weixiao(self,enemy)
							if card_n and card_n2 then
								table.insert(to_discard, card_n:getKnownEffectiveId())
								table.insert(to_discard, card_n2:getKnownEffectiveId())
								return to_discard
							end
						end
					end
				end
			end
			if not get_weixiao(self) and player and not hasManjuanEffect(player) and not self:needKongcheng(player, true) then
				set_weixiao(self,player)
			end

			if not get_weixiao(self) then
				set_weixiao(self,self:findPlayerToDraw(true, n))
			end
			if not get_weixiao(self) then
				for _, friend in ipairs(self.friends) do
					if not hasManjuanEffect(friend) then
						set_weixiao(self,friend)
						break
					end
				end
			end
			if get_weixiao(self) then set_weixiao_choice(self,"a") end
		end
		if not get_weixiao(self) and x > 1 and #self.enemies > 0 then
			self:sortInPlace(self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if he_count(enemy) >= n
					and self:doDisCard(enemy, "he", false, n) then
					set_weixiao_choice(self,"b")
					set_weixiao(self,enemy)
					if card_n and card_n2 then
						table.insert(to_discard, card_n:getKnownEffectiveId())
						table.insert(to_discard, card_n2:getKnownEffectiveId())
						return to_discard
					end
				end
			end
			self.enemies = sgs.reverse(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isNude()
					and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
					and not self:needToThrowArmor(enemy)
					and not hasTuntianEffect(enemy) then
					set_weixiao_choice(self,"b")
					set_weixiao(self,enemy)
					if card_n and card_n2 then
						table.insert(to_discard, card_n:getKnownEffectiveId())
						table.insert(to_discard, card_n2:getKnownEffectiveId())
						return to_discard
					end
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isNude()
					and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
					and not self:needToThrowArmor(enemy)
					and not (hasTuntianEffect(enemy) and x < 3 and he_count(enemy) < 2) then
					set_weixiao_choice(self,"b")
					set_weixiao(self,enemy)
					if card_n and card_n2 then
						table.insert(to_discard, card_n:getKnownEffectiveId())
						table.insert(to_discard, card_n2:getKnownEffectiveId())
						return to_discard
					end
				end
			end
		end
		if card_n and card_n2 then
			table.insert(to_discard, card_n:getKnownEffectiveId())
			table.insert(to_discard, card_n2:getKnownEffectiveId())
			return to_discard
		end
	end
	return {}
end
ai_skill_choice.weixiao             = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result((get_weixiao_choice(self)), options)
end


sgs.ai_skill_playerchosen.weixiao = function(self, targets)
	return get_weixiao(self)
end


sgs.ai_playerchosen_intention.weixiao = function(self, from, to)
	local intention = -80
	if hasManjuanEffect(to) then intention = -intention end
	if get_weixiao_choice(self) == "a" then
	elseif get_weixiao_choice(self) == "b" then
		intention = -intention
	end
	self:updateIntention(from, to, intention)
end
sgs.ai_use_revises.weixiao = function(self, card, use)
	if card:isKindOf("EquipCard")

	then
		same = self:getSameEquip(card)
		if same
		then
			return false
		end
	end
end



sgs.ai_cardneed.LuaChanshi = function(to, card)
	return isCard("Slash", card, to)
end
sgs.ai_cardneed.LuaZhuan = function(to, card)
	return (card:isBlack() and isCard("Slash", card, to)) or isCard("Duel", card, to)
end


local luagonglue_skill = {}
luagonglue_skill.name = "luagonglue"
table.insert(package_skills, luagonglue_skill)
luagonglue_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies < 1 or self.player:getStrategyHasUsed("#luagongluecard") then return end
	return parse(self,request,"#luagongluecard:.:")
end


ai_card_use["#luagongluecard"] = function(self, card, use, request)
	local target
	self:sortInPlace(self.enemies, "defense")
	local lord = self.room:getLord()
	if self.player:getKnownRole() == "rebel" then
		if not lord:isKongcheng() then
			target = lord
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				target = enemy
			end
		end
	end
	if target then
		use.card=final_parse(self,request,"#luagongluecard:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["luagongluecard"]       = 8
sgs.ai_use_priority["luagongluecard"]    = 8
sgs.ai_card_intention["luagongluecard"]  = 60



sgs.ai_skill_playerchosen.LuaChigui = function(self, targets)
	if self:isWeak(self.player) then return nil end
	targets = AIList.new(targets)
	self:sortInPlace(targets, "defense")
	local dest
	local temp = 0
	for _, target in ipairs(targets) do
		local count = 0
		if self:isFriend(target) then
			if target:getWeapon() and self:hasSkills(sgs.lose_equip_skill, target) then
				for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
					if target:inMyAttackRange(p) and self:isEnemy(p) then
						count = count + 1
					end
				end
			end
		else
			if not target:getWeapon() or self:hasSkills(sgs.lose_equip_skill, target) then return nil end
			for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
				if target:inMyAttackRange(p) and self:isFriend(p) then
					count = count + 1
				end
			end
		end
		if count > temp then
			temp = count
			dest = target
		end
	end
	if dest and temp > 2 then return dest end
	return nil
end

ai_skill_invoke.LuaBuwu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if not target:faceUp() and self:isFriend(target) then
		return (not self:toTurnOver(target, target:getHp() - 1, "LuaBuwu")) or false
	end

	if self:isEnemy(target) then
		if self:toTurnOver(target, target:getHp() - 1, "LuaBuwu") then
			return (true) or false
		end
	end
	return false

end

sgs.ai_choicemade_filter.skillInvoke.LuaBuwu = function(self, player, promptlist)
	local intention = 60
	local index = promptlist[#promptlist] == "yes" and 1 or -1
	local damage = event_value(self,"current_damage",true)
	if damage.from and damage.to then
		if hasManjuanEffect(damage.to) and index then self:updateIntention(damage.from, damage.to, 80) end
		if not self:toTurnOver(damage.to, damage.to:getHp() - 1) then intention = -intention * index end
		if damage.to:getHp() - 1 < 3 then
			self:updateIntention(damage.from, damage.to, intention * index)
		else
			self:updateIntention(damage.from, damage.to, math.min(intention, -30) * index)
		end
	end
end


ai_skill_invoke.LuaTianmoDefense = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getMark("@tianmo") == 0 then return (false) or false end
	local damage = data:toDamage()
	if not self:needToLoseHp(damage.to, damage.from, damage.card) then
		return (true) or false
	end
	return (false) or false
end



local LuaWangxiang_skill = {}
LuaWangxiang_skill.name = "LuaWangxiang"
table.insert(package_skills, LuaWangxiang_skill)
LuaWangxiang_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local wxhcn = self.player:getHandcardNum()
	local losehp = self.player:getMaxHp() - self.player:getHp()
	if wxhcn > losehp then return end
	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	self:sortByUseValueInPlace(cards, true)
	local card_nd = cards[1]
	return parse(self,request,("ex_nihilo:LuaWangxiang[%s:%s]=%d"):format(card_nd:getSuitString(), card_nd:getNumberString(),
		card_nd:getKnownEffectiveId()))
end

sgs.ai_use_value["LuaWangxiang"]    = 10
sgs.ai_use_priority["LuaWangxiang"] = 9

local luablackflame_skill = {}
luablackflame_skill.name            = "luablackflame"
table.insert(package_skills, luablackflame_skill)
luablackflame_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies < 1 then return end
	local source = self.player
	if source:getStrategyHasUsed("#luablackflamecard") then return end
	if self.player:getHp() <= 2 then return end
	return parse(self,request,"#luablackflamecard:.:")
end

ai_card_use["#luablackflamecard"] = function(self, card, use, request)
	self:sortInPlace(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) then
			if self.player:getHp() > enemy:getHp() and self.player:getHp() > 1 and self:canDamage(enemy, self.player, nil) then
				use.card=final_parse(self,request,"#luablackflamecard:.:")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
end

sgs.ai_use_value["luablackflamecard"]       = 8
sgs.ai_use_priority["luablackflamecard"]    = 10
sgs.ai_card_intention.luablackflamecard     = 90


ai_skill_invoke.LuaGqset                = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("BasicCard") or card:isKindOf("TrickCard") then
			return (true) or false
		end
	end
	return (false) or false
end

sgs.ai_skill_cardchosen.LuaGqset            = function(self, who, flags)
	local cards = self.player:getCards("h")
	cards = AIList.new(cards)
	self:sortByUseValueInPlace(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("BasicCard") then
			return card
		end
		if card:isKindOf("TrickCard") then
			return card
		end
	end
	return cards[1]
end
sgs.ai_skill_discard.LuaGqset               = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = AIList.new(cards)
	self:sortByUseValueInPlace(cards)
	for _, card in ipairs(cards) do
		if card:isKindOf("BasicCard") then
			table.insert(to_discard, card:getKnownEffectiveId())
			return to_discard
		end
		if card:isKindOf("TrickCard") then
			table.insert(to_discard, card:getKnownEffectiveId())
			return to_discard
		end
	end
	return {}
end

function sgs.ai_slash_prohibit.LuaGqset(self, from, to, card)
	if to:hasSkill("LuaGqset") and to:getPile("gang"):length() > 0 and disclosed(self,to:getPile("gang"):first()):getTypeId() == sgs.Card_TypeBasic then return true end
end

sgs.ai_target_revises.LuaGqset = function(to, card, self)
	if to:getPile("gang"):length() > 0 then
		local newcard = disclosed(self,to:getPile("gang"):first())
		return newcard:getTypeId() == card:getTypeId()
	end
end


local luatiaojiao_skill = {}
luatiaojiao_skill.name = "luatiaojiao"
table.insert(package_skills, luatiaojiao_skill)
luatiaojiao_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luatiaojiaocard") then return end
	for _, friend in ipairs(self.friends) do
		if friend:getJudgingArea():length() > 0 then
			return parse(self,request,"#luatiaojiaocard:.:")
		end
	end
	if #self.enemies < 1 then return end
	if #self.enemies == 1 and self.enemies[1]:isNude() then return end
	return parse(self,request,"#luatiaojiaocard:.:")
end

ai_card_use["#luatiaojiaocard"] = function(self, card, use, request)
	for _, friend in ipairs(self.friends_noself) do
		if friend:getJudgingArea():length() > 0
			and not friend:hasSkills("shensu|qingyi|qiaobian")
			and (self:isWeak(friend) or self:getOverflow(friend) > 1)
		then
			for _, c in sgs.list(friend:getJudgingArea()) do
				if not c:isKindOf("YanxiaoCard") then
					use.card=final_parse(self,request,"#luatiaojiaocard:.:")
					if use.to then use.to:append(friend) end
					return
				end
			end
		end
	end
	local dummy_use = { isDummy = true, to = AIList.new({}) }
	local collateral = self:getEvaluationCard("collateral")
	self:useCardCollateral(collateral, dummy_use)
	if dummy_use.card and dummy_use.to:length() == 2 then
		use.card=final_parse(self,request,"#luatiaojiaocard:.:")
		target_flag(self,dummy_use.to:last(),true)
		if use.to then use.to:append(dummy_use.to:first()) end
		return
	end
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isNude() then
			for _, enemy2 in ipairs(self.enemies) do
				if enemy:objectName() ~= enemy2:objectName()
					and enemy:canSlash(enemy2)
					and (self:cantbeHurt(enemy2) or not self:needToLoseHp(enemy2, enemy, nil, true)) and self:canDamage(enemy, self.player, nil) then
					use.card=final_parse(self,request,"#luatiaojiaocard:.:")
					target_flag(self,enemy2,true)
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_value["luatiaojiaocard"]       = 8
sgs.ai_use_priority["luatiaojiaocard"]    = 10
sgs.ai_card_intention.luatiaojiaocard     = 30


sgs.ai_skill_playerchosen.luatiaojiaocard = function(self, targets)
	targets = AIList.new(targets)
	self:sortInPlace(targets, "defense")
	for _, p in ipairs(targets) do
		if target_flag(self,p) then
			target_flag(self,p,false)
			return p
		end
	end
	local target
	for _, p in ipairs(AIList.new(self.room:getAlivePlayers())) do
		if p:hasFlag("luatiaojiaocard") then
			target = p
		end
	end
	local slash = self:getEvaluationCard("slash")
	

	for _, enemy in ipairs(targets) do
		if target:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:getDefenseSlash(enemy) <= 2
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
			and enemy:objectName() ~= target:objectName() then
			return enemy
		end
	end
	return targets[0]
end

sgs.ai_skill_cardask["@TiaojiaoSlash"] = function(self, data, pattern, target)
	if self.player:getJudgingArea():length() > 0
		and not self.player:hasSkills("shensu|qingyi|qiaobian")
		and (self:isWeak(self.player) or self:getOverflow(self.player) > 1)
	then
		for _, c in sgs.list(self.player:getJudgingArea()) do
			if not c:isKindOf("YanxiaoCard") then
				for _, p in ipairs(AIList.new(self.room:getAlivePlayers())) do
					if p:hasFlag("luatiaojiaocard") then
						if self:isFriend(p) then
							return "."
						end
					end
				end
			end
		end
	end
	if target then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:isFriend(target) and self:slashIsEffective(slash, target) then
				if self:needLeiji(target, self.player) then return slash end
				if self:needToLoseHp(target, self.player, nil, true) then return slash end
			end

			if not self:isFriend(target) and self:slashIsEffective(slash, target)
				and not self:needLeiji(target, self.player)
			then
				return slash
			end
		end
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:isFriend(target) then
				if not self:needLeiji(target, self.player) and not self:needToLoseHp(target, self.player, slash) then
					return
						slash
				end
				if not self:slashIsEffective(slash, target) then return slash end
			end
		end
	end
	return "."
end


local luaboxue_skill = {}
luaboxue_skill.name = "luaboxue"
table.insert(package_skills, luaboxue_skill)
luaboxue_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luaboxuecard") then return end
	
	return parse(self,request,"#luaboxuecard:.:")
end

ai_card_use["#luaboxuecard"] = function(self, card, use, request)
	local targets = AIList.new({})
	for _, friend in ipairs(self.friends) do
		if not friend:isNude() then
			targets:append(friend)
		end
	end
	if targets then
		use.card=final_parse(self,request,"#luaboxuecard:.:")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_value["luatiaojiaocard"]    = 8
sgs.ai_use_priority["luatiaojiaocard"] = 10
sgs.ai_card_intention.luatiaojiaocard  = -60

ai_skill_choice.luaboxuecard       = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result(("gx"), options)
end

local LuaYaojing_skill                 = {}
LuaYaojing_skill.name                  = "LuaYaojing"
table.insert(package_skills, LuaYaojing_skill)

LuaYaojing_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getHandcardNum() < 1 then return end
	local can = false
	local cards = AIList.new(self.player:getHandcards())
	local subcards = {}
	self:sortByUseValueInPlace(cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
		if not (isCard("Peach", card, self.player) or isCard("ExNihilo", card, self.player)) then
			table.insert(cardsq,
				card)
		end
	end
	if #cardsq == 0 then return end
	if self:getKeepValue(cardsq[1]) > 18 then return end
	if self:getUseValue(cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getId())
	local card_str = "god_salvation:LuaYaojing[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = parse(self,request,card_str)
	assert(AsCard)
	return AsCard
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|LuaYaojing"

sgs.ai_skill_playerchosen.LuaGongming = function(self, targets)
	targets = AIList.new(targets)
	self:sortInPlace(targets)
	for _, friend in ipairs(targets) do
		if not self:isFriend(friend) then
			table.removeOne(targets, friend)
		end
	end
	local max_x = 0
	local target
	local Shenfen_user
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:hasFlag("ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	if Shenfen_user then
		local y, weak_friend = 3
		for _, friend in ipairs(targets) do
			local x = self.player:getLostHp() + 1
			if hasManjuanEffect(friend) and x > 0 then x = x + 1 end
			if x > max_x and friend:isAlive() then
				max_x = x
				target = friend
			end

			if self:playerGetRound(friend, Shenfen_user) > self:playerGetRound(self.player, Shenfen_user) and x >= y
				and friend:getHp() == 1 and getCardsNum("Peach", friend, self.player) < 1 then
				y = x
				weak_friend = friend
			end
		end

		if weak_friend and ((getCardsNum("Peach", Shenfen_user, self.player) < 1) or (math.min(Shenfen_user:getMaxHp(), 5) - Shenfen_user:getHandcardNum() <= 1)) then
			return weak_friend
		end
		if self:isFriend(Shenfen_user) and math.min(Shenfen_user:getMaxHp(), 5) > Shenfen_user:getHandcardNum() then
			return Shenfen_user
		end
		if target then return target end
	end

	local CP = self.room:getCurrent()
	local max_x = 0
	local AssistTarget = self:AssistTarget()
	for _, friend in ipairs(targets) do
		local x = self.player:getLostHp() + 1
		if hasManjuanEffect(friend) then x = x + 1 end
		if self:hasCrossbowEffect(CP) then x = x + 1 end
		if AssistTarget and friend:objectName() == AssistTarget:objectName() then x = x + 0.5 end

		if x > max_x and friend:isAlive() then
			max_x = x
			target = friend
		end
	end
	if not target then
		target = self.player
	end
	return target
end




ai_audited_aliases.register{id="ai_cardneed.LuaPomo",registry="ai_cardneed",path={"LuaPomo"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
ai_audited_aliases.register{id="ai_cardneed.LuaBimie",registry="ai_cardneed",path={"LuaBimie"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.ai_use_revises.LuaPomo = function(self, card, use)
	if card:isKindOf("Slash")
	then
		self:setStrategyCardFlag(card, "Qinggang", true)
	end
end

ai_skill_invoke.LuaBimie = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	local target = damage.to
	if self:isEnemy(target) then
		return (true) or false
	end
	return (false) or false
end
sgs.ai_choicemade_filter.skillInvoke.LuaBimie = function(self, player, promptlist)
	local intention = 100
	local index = promptlist[#promptlist] == "yes" and 1 or -1
	local damage = event_value(self,"current_damage",true)
	if damage.from and damage.to then
		if index == -1 then
			intention = -20
		end
		self:updateIntention(damage.from, damage.to, intention)
	end
end



function sgs.ai_cardneed.LuaBimie(to, card, self)
	local cards = current_visible_hand(self,to)
	local has_weapon = to:getWeapon()
	local slash_num = 0
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if true then
			if c:isKindOf("Weapon") then
				has_weapon = true
			end
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end

	if not has_weapon then
		return card:isKindOf("Weapon")
	else
		return to:hasWeapon("spear") or card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic"))
	end
end

sgs.ai_skill_defense.LuaBimie = function(self, player)
	return self:isFriend(player) and player:getMaxHp() or -player:getMaxHp()
end


ai_skill_invoke.LuaBaozou = true
sgs.ai_skill_defense.LuaBaozou = 4

sgs.ai_skill_playerchosen["LuaXinbi"] = function(self, targets)
	return self:findPlayerToDiscard("e", true, true, targets, false)[1]
end

function sgs.ai_slash_prohibit.LuaBaozou(self, from, to, card)
	if to:getHp() <= 1 and not self:isFriend(from, to) then
		return (to:getHandcardNum() >= 2 and not self:willSkipDrawPhase(to)) or not self:willSkipPlayPhase(to)
	end
end

sgs.ai_ajustdamage_to.LuaBaozou = function(self, from, to, card, nature)
	if to:hasFlag("BaozouTurn") then
		return -99
	end
end
sgs.ai_can_damagehp.LuaBaozou = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) >= 0 and
		self:canLoseHp(from, card, to) then
		return (to:getHandcardNum() >= 2 and not self:willSkipDrawPhase(to)) or not self:willSkipPlayPhase(to)
	end
end


function sgs.ai_cardneed.LuaBaozou(to, card, self)
	return to:getHandcardNum() < 3
end



local luatouying_skill = {}
luatouying_skill.name = "luatouying"
table.insert(package_skills, luatouying_skill)
luatouying_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luatouyingcard") then return end
	if self.player:getWeapon() then return end
	return parse(self,request,"#luatouyingcard:.:")
end

ai_card_use["#luatouyingcard"] = function(self, card, use, request)
	use.card = card
	return
end

sgs.ai_use_priority["luatouyingcard"]    = 10
sgs.ai_card_intention["luatouyingcard"]  = 0

ai_skill_choice.luatouying           = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	local items = choices:split("+")
	return ai_choice_result((items[math.random(1, #items)]), options)
end


function sgs.ai_cardsview.ZhangbaSkill(self, class_name, player)
	if class_name == "Slash" then
		return cardsView_spear(self, player, "ZhangbaSkill")
	end
end

local ZhangbaSkill_skill = {}
ZhangbaSkill_skill.name = "ZhangbaSkill"
table.insert(package_skills, ZhangbaSkill_skill)
ZhangbaSkill_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	return source_turn_spear(self,inclusive,request)
end

ai_audited_aliases.register{id="ai_skill_invoke.ShemaSkill",registry="ai_skill_invoke",path={"ShemaSkill"},canonical_registry="ai_skill_invoke",canonical_path={"kylin_bow"},self_index=1,defer_canonical=true}



local LuaGongqi_skill = {}
LuaGongqi_skill.name = "LuaGongqi"
table.insert(package_skills, LuaGongqi_skill)
LuaGongqi_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("he")
	cards = AIList.new(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end

	local equip_card
	self:sortByUseValueInPlace(cards, true)

	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive)
			and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			equip_card = card
			break
		end
	end

	if equip_card then
		local suit = equip_card:getSuitString()
		local number = equip_card:getNumberString()
		local card_id = equip_card:getKnownEffectiveId()
		local card_str = ("slash:LuaGongqi[%s:%s]=%d"):format(suit, number, card_id)
		local slash = parse(self,request,card_str)

		assert(slash)

		return slash
	end
end


function sgs.ai_cardneed.LuaGongqi(to, card, self)
	return card:getTypeId() == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", true) == 0
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.LuaJianzhi",registry="ai_choicemade_filter",path={"cardChosen","LuaJianzhi"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}





local luajianyu_skill = {}
luajianyu_skill.name = "luajianyu"
table.insert(package_skills, luajianyu_skill)

luajianyu_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local yong = self.player:getPile("yong")
	local alivenum = self.room:getAlivePlayers():length()
	if yong:length() < alivenum then return end

	local cards = {}
	local subcards = {}

	if self.player:getPile("yong"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("yong")) do
			table.insert(cards, disclosed(self,id))
		end
	end
	self:sortByUseValueInPlace(cards, true)
	if #cards == 0 or ((alivenum > 4) and (alivenum / yong:length()) < 1.5) then return end
	for i = 1, alivenum, 1 do
		table.insert(subcards, cards[i]:getId())
	end
	local card_str = "archery_attack:luajianyu[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = parse(self,request,card_str)
	assert(AsCard)
	return AsCard
end




local LuaChitian_skill = {}
LuaChitian_skill.name = "LuaChitian"
table.insert(package_skills, LuaChitian_skill)
LuaChitian_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")
	local no_have = true
	local cardsq = self.player:getCards("he")
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			cardsq:prepend(disclosed(self,id))
		end
	end
	for _, c in sgs.qlist(cardsq) do
		if c:isKindOf("Slash") then
			no_have = false
			break
		end
	end
	if not no_have then return end

	local cards = {}
	if self.player:getPile("yong"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("yong")) do
			table.insert(cards, disclosed(self,id))
		end
	end
	self:sortByUseValueInPlace(cards, true)
	local use_cards = {}

	if #cards > 0 then
		table.insert(use_cards, cards[1])
	end
	if #use_cards == 0 then return end

	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and self:isGoodTarget(enemy, self.enemies, slash) and self.player:inMyAttackRange(enemy) then
			local slash = self:getEvaluationCard("slash")
			
			if not self:slashProhibit(slash, enemy, self.player) and self:slashIsEffective(slash, enemy, self.player) then
				local card_str = ("slash:LuaChitian[%s:%s]=%d"):format(sgs.Card_NoSuit, 0, use_cards[1]:getEffectiveId())
				local AsCard = parse(self,request,card_str)
				assert(AsCard)
				return AsCard
			end
		end
	end
end

ai_card_use["#LuaChitian"] = function(self, card, use, request)
	local userstring = card:getLegacyStringKey()
	userstring = (userstring:split(":"))[4]
	local yizancard=owner_eval(self,"LuaChitian",userstring,card:getSuit(),card:getNumber())
	
	
	self:useBasicCard(yizancard, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["LuaChitian"] = 3
sgs.ai_use_value["LuaChitian"] = 3

sgs.ai_view_as["LuaChitian"] = function(card, player, card_place, class_name)
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local cards = player:getCards("he")
	local no_have = true
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			cards:prepend(player_disclosed(player,id))
		end
	end
	for _, c in sgs.qlist(cards) do
		if c:isKindOf(class_name) then
			no_have = false
			break
		end
	end
	if not no_have then return end

	local handcards = {}
	if player:getPile("yong"):length() == 0 then return end
	if not player:getPile("yong"):contains(card:getKnownId()) then return end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	return material(card,name,"LuaChitian")
end




ai_skill_invoke.LuaChamberMove = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getMark("@Chamber") == 1 then
		if self.player:getHp() < 2 then
			return (true) or false
		end
	end
	if self.player:getMark("@Chamber") == 0 then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_skill_playerchosen.LuaRedoWake = function(self, targets)
	if #self.enemies > 0 then
		for _, enemy in ipairs(self.enemies) do
			if enemy:isAlive() and self:isGoodTarget(enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player) and not self:cantDamageMore(self.player, enemy) and self:canDamage(enemy, self.player, nil) then
				return enemy
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:isAlive() then
			return enemy
		end
	end
end


sgs.ai_skill_cardask["@jiguang"] = function(self, data, pattern)
	local effect = data:toCardEffect()
	if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
	if not self:slashIsEffective(effect.card, self.player, effect.from)
		or (not self:hasHeavyDamage(effect.from, effect.card, self.player)
			and self:needToLoseHp(self.player, effect.from, nil)) then
		return "."
	end
	if not self:hasHeavyDamage(effect.from, effect.card, self.player) and self:getCardsNum("Peach") > 0 then return "." end
	local equip_index = { 3, 0, 2, 4, 1 }
	if self.player:hasSkills(sgs.lose_equip_skill) then
		for _, i in ipairs(equip_index) do
			if i == 4 then break end
			if self.player:getEquip(i) then return "$" .. self.player:getEquip(i):getEffectiveId() end
		end
	end

	local cards = AIList.new(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	for _, card in ipairs(cards) do
		if (not self:isWeak() and (self:getKeepValue(card) > 8 or self:isValuableCard(card))) then continue end
		if card:isKindOf("BasicCard") then continue end
		return "$" .. card:getKnownEffectiveId()
	end

	for _, i in ipairs(equip_index) do
		if self.player:getEquip(i) then
			if not (i == 1 and self:evaluateArmor() > 3)
				and not (i == 4 and self.player:getTreasure():isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() >= 3) then
				return "$" .. self.player:getEquip(i):getEffectiveId()
			end
		end
	end
end

ai_audited_aliases.register{id="ai_cardneed.LuaJiguangAsk",registry="ai_cardneed",path={"LuaJiguangAsk"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_skill_discard.LuaWenle = function(self)
	local x = math.floor(self.room:alivePlayerCount() / 2)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = AIList.new(cards)
	self:sortByKeepValueInPlace(cards)
	for i = 1, x do
		table.insert(to_discard, cards[i]:getEffectiveId())
	end
	return to_discard
end


local luayukong_skill = {}
luayukong_skill.name = "luayukong"
table.insert(package_skills, luayukong_skill)
luayukong_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luayukongcard") then return end
	if self.player:getPile("si"):length() == 0 then return end
	if self.player:getAttackRange() > 2 then return end
	if #self.enemies <= 1 then return end
	local min_number = 13
	local cardx
	for _, id in sgs.qlist(self.player:getPile("si")) do
		local card = disclosed(self,id)
		local suit = card:getSuitString()
		local number = card:getNumber()
		local card_id = card:getKnownEffectiveId()
		if number < min_number then
			min_number = number
			cardx = card
		end
	end
	if cardx then
		return parse(self,request,"#luayukongcard:" .. cardx:getKnownId() .. ":")
	end
end


ai_card_use["#luayukongcard"] = function(self, card, use, request)
	use.card = card
	local min_number = 13
	local cardx
	for _, id in sgs.qlist(self.player:getPile("si")) do
		local card = disclosed(self,id)
		local suit = card:getSuitString()
		local number = card:getNumber()
		local card_id = card:getKnownEffectiveId()
		if number < min_number then
			min_number = number
			cardx = card
		end
	end
	if cardx then
		return parse(self,request,"#luayukongcard:" .. cardx:getKnownId() .. ":")
	end
end

sgs.ai_use_priority["luayukongcard"]    = 10
sgs.ai_card_intention["luayukongcard"]  = 0


ai_skill_use["@@LuaQisi"] = function(self, prompt, request)
	local method = request and request.handling_method
	local effect=event_value(self,"erciyuan_qisi_effect")
	local source = effect.from
	local itsar = source:getAttackRange()
	local max_number = 0
	local cardx
	for _, id in sgs.qlist(self.player:getPile("si")) do
		local card = disclosed(self,id)
		local suit = card:getSuitString()
		local number = card:getNumber()
		local card_id = card:getKnownEffectiveId()
		if number > max_number then
			max_number = number
			cardx = card
		end
	end
	if max_number / 2 < itsar then return "." end
	if cardx then
		if self.role == "rebel" and self:getRoleEstimate(effect.from) == "rebel" and not effect.from:hasSkill("jueqing")
			and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then
			return "."
		end
		local card_str = "#LuaQisi:" .. cardx:getKnownId() .. ":"
		if self:isEnemy(effect.from) or (self:isFriend(effect.from) and self.role == "loyalist" and not effect.from:hasSkill("jueqing") and effect.from:isLord() and self.player:getHp() == 1) then
			if effect.card:isKindOf("Slash") then
				if self:slashIsEffective(effect.card, self.player, effect.from) and self.player:getPile("si"):length() > 1 then
					return
						card_str
				end
				if self:hasHeavyDamage(effect.from, effect.card, self.player) then return card_str end

				error('fixed LuaQisi passes CardEffect.to Player to getExpectedJinkNum; sgs.qlist requires length',0)
				local jink_num = self:getExpectedJinkNum(effect)
				local hasHeart = false
				for _, card in ipairs(self:getCards("Jink")) do
					if card:getSuit() == sgs.Card_Heart then
						hasHeart = true
						break
					end
				end
				if self:getCardsNum("Jink") == 0
					or jink_num == 0
					or self:getCardsNum("Jink") < jink_num
					or (effect.from:hasSkill("dahe") and self.player:hasFlag("dahe") and not hasHeart) then
					if effect.card:isKindOf("NatureSlash") and self.player:isChained() and not self:isGoodChainTarget(self.player, effect.from, nil, nil, effect.card) then
						return
							card_str
					end
					if effect.from:hasSkill("nosqianxi") and effect.from:distanceTo(self.player) == 1 then
						return
							card_str
					end
					if self:isFriend(effect.from) and self.role == "loyalist" and not effect.from:hasSkill("jueqing") and effect.from:isLord() and self.player:getHp() == 1 then
						return
							card_str
					end
					if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or effect.from:hasSkill("jueqing")) then
						return card_str
					end
				end
			elseif effect.card:isKindOf("AOE") then
				local from = effect.from
				if effect.card:isKindOf("SavageAssault") then
					local menghuo = self.room:findPlayerBySkillName("huoshou")
					if menghuo then from = menghuo end
				end

				local friend_null = 0
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
					if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
				end
				friend_null = friend_null + self:getCardsNum("Nullification")
				local sj_num = self:getCardsNum(effect.card:isKindOf("SavageAssault") and "Slash" or "Jink")

				if not self:hasTrickEffective(effect.card, self.player, from) then return "." end
				if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then return "." end
				if effect.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then
					return
						card_str
				end
				if sj_num == 0 and friend_null <= 0 then
					if self:isEnemy(from) and from:hasSkill("jueqing") then return self:doDisCard(from) end
					if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not from:hasSkill("jueqing") then
						return
							card_str
					end
					if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or effect.from:hasSkill("jueqing")) then
						return card_str
					end
				end
			end
		elseif self:isEnemy(effect.from) then
			if effect.card:isKindOf("FireAttack") and effect.from:getHandcardNum() > 0 then
				if not self:hasTrickEffective(effect.card, self.player) then return "." end
				if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, effect.from) then return "." end
				if (self.player:hasArmorEffect("vine") or self.player:getMark("@gale") > 0) and effect.from:getHandcardNum() > 3
					and not (effect.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
					return card_str
				elseif self.player:isChained() and not self:isGoodChainTarget(self.player, effect.from) then
					return card_str
				end
			elseif (effect.card:isKindOf("Snatch") or effect.card:isKindOf("Dismantlement"))
				and self:getCardsNum("Peach") == self.player:getHandcardNum() and not self.player:isKongcheng() then
				if not self:hasTrickEffective(effect.card, self.player) then return "." end
				return card_str
			elseif effect.card:isKindOf("Duel") then
				if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", effect.from, self.player) then
					if not self:hasTrickEffective(effect.card, self.player) then return "." end
					if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, effect.from) then return "." end
					return card_str
				end
			elseif effect.card:isKindOf("TrickCard") and not effect.card:isKindOf("AmazingGrace") and not effect.card:isKindOf("GodSalvation") and not effect.card:isKindOf("ExNihilo") then
				return card_str
			end
		elseif effect.card:isKindOf("TrickCard") and not effect.card:isKindOf("AmazingGrace") and not effect.card:isKindOf("GodSalvation") and not effect.card:isKindOf("ExNihilo") then
			return card_str
		end
	end
	return "."
end







local function getSlashNum(player)
	local num = 0
	for _, card in sgs.qlist(player:getHandcards()) do
		if card:isKindOf("Slash") then
			num = num + 1
		end
	end
	return num
end

local luaposhi_skill = {}
luaposhi_skill.name = "luaposhi"
table.insert(package_skills, luaposhi_skill)
luaposhi_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luaposhicard") then return end
	if self.player:getMark("&luaposhi") > 0 then return end
	if #self.enemies < 1 then return end
	if getSlashNum(self.player) < 2 then return end
	if self.player:getHp() < 2 and self:getCardsNum("Peach") == 0 then return end
	if getSlashNum(self.player) < 3 and (self.player:getHp() < 3 and self:getCardsNum("Peach") == 0) then return end
	return parse(self,request,"#luaposhicard:.:")
end

ai_card_use["#luaposhicard"] = function(self, card, use, request)
	use.card=final_parse(self,request,"#luaposhicard:.:")
	return
end

sgs.ai_use_value["luaposhicard"] = 7
sgs.ai_use_priority["luaposhicard"] = 9

sgs.double_slash_skill = sgs.double_slash_skill .. "|luaposhi"
ai_audited_aliases.register{id="ai_cardneed.luaposhi",registry="ai_cardneed",path={"luaposhi"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

ai_skill_invoke.LuaLiansuo = true
ai_skill_invoke.LuaYinguo = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:isMale() and self:isFriend(p) then
			return (true) or false
		end
	end
	return (false) or false
end

sgs.ai_skill_playerchosen.LuaYinguo = function(self, targets)
	local min_card_num = 100
	local target
	for _, p in sgs.qlist(targets) do
		if p:isMale() and self:isFriend(p) then
			if p:getHandcardNum() < min_card_num then
				target = p
				min_card_num = p:getHandcardNum()
			end
		end
	end
	if target then return target end
	return targets:first()
end


local yanhuoacquire_skill = {}
yanhuoacquire_skill.name = "yanhuoacquire"
table.insert(package_skills, yanhuoacquire_skill)
yanhuoacquire_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if not self:isWeak() and not self.player:getStrategyHasUsed("#yanhuoacquirecard") then
		local target
		local players = self.room:getOtherPlayers(self.player)
		for _, p in sgs.qlist(players) do
			
			if p:getPileCount("confuse") > 0 and self:isEnemy(p) then
				target = p
				break
			end
		end
		if target then
			return parse(self,request,"#yanhuoacquirecard:.:")
		end
	end
end


ai_card_use["#yanhuoacquirecard"] = function(self, card, use, request)
	if not self:isWeak() then
		local target
		local players = self.room:getOtherPlayers(self.player)
		for _, p in sgs.qlist(players) do
			if p:getPileCount("confuse") > 0 and self:isEnemy(p) then
				target = p
				break
			end
		end
		if target then
			use.card = card
			if use.to then use.to:append(target) end
			return
		end
	end
end


ai_skill_invoke.slyanhuo = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	if self.player:getPileCount("confuse") > 0 then
		for _, id in sgs.qlist(self.player:getPile("confuse")) do
			local card = disclosed(self,id)
			if card:getSuit() == sgs.Card_Spade and self:isFriend(damage.from) and self:isWeak(damage.from) then
				return (true) or false
			elseif card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Diamond then
				if self:isEnemy(damage.from) then
					return (true) or false
				end
			end
		end
	end
	
	return (false) or false
end


sgs.ai_skill_askforag["slyanhuo"] = function(self, card_ids)
	local damage=event_value(self,"erciyuan_slyanhuo_damage")
	local cards = {}
	local spade = {}
	local heart = {}
	local club = {}
	local diamond = {}
	for _, id in ipairs(card_ids) do
		local card = disclosed(self,id)
		if card:getSuit() == sgs.Card_Spade then
			table.insert(spade, card)
		elseif card:getSuit() == sgs.Card_Heart then
			table.insert(heart, card)
		elseif card:getSuit() == sgs.Card_Club then
			table.insert(club, card)
		elseif card:getSuit() == sgs.Card_Diamond then
			table.insert(diamond, card)
		end
		table.insert(cards, card)
	end
	if self:isFriend(damage.from) then
		if self:isWeak(damage.from) and #spade > 0 then
			self:sortByUseValueInPlace(spade)
			return spade[1]:getId()
		elseif #club > 0 then
			self:sortByUseValueInPlace(club)
			return club[1]:getId()
		end
	else
		if #heart > 0 then
			self:sortByUseValueInPlace(heart)
			return heart[1]:getId()
		end
		if #diamond > 0 then
			self:sortByUseValueInPlace(diamond)
			return diamond[1]:getId()
		end
	end
	self:sortByUseValueInPlace(cards)
	return cards[1]:getId()
end

local yanhuovs_skill = {}
yanhuovs_skill.name = "slyanhuo"
table.insert(package_skills, yanhuovs_skill)
yanhuovs_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getPileCount("confuse") < 5 and self.player:getHandcardNum() > 0 and self.player:getPileCount("confuse") < self.room:getAlivePlayers():length() then
		return parse(self,request,"#slyanhuocard:.:")
	end
end

ai_card_use["#slyanhuocard"] = function(self, card, use, request)
	local cards = AIList.new(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	if cards[1]:isKindOf("Peach") or cards[1]:isKindOf("Nullification") or cards[1]:isKindOf("Analeptic") then return end
	use.card=final_parse(self,request,"#slyanhuocard:" .. cards[1]:getEffectiveId() .. ":")
	return
end
sgs.ai_use_priority["slyanhuo"]        = sgs.ai_use_priority.ExNihilo - 0.1

ai_skill_invoke.LuaHeartlead       = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	local source = use.from
	local target = use.to:first()
	local card = use.card
	if card:isKindOf("Peach") and self:isEnemy(target) then return (true) or false end
	if self:isEnemy(source) and self:isFriend(target) and self.player:getHp() > 1 then return (true) or false end
	if self:isEnemy(source) and self:isFriend(target) and target:getHp() == 1 then return (true) or false end
	return (false) or false
end

ai_skill_choice["LuaHeartlead"]    = "chained"

sgs.ai_skill_playerchosen.LuaHeartlead = function(self, targets)
	local positive = true
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHp() <= 0 and self:isEnemy(p) then
			positive = false
		end
	end
	if positive then
		for _, p in sgs.qlist(targets) do
			if p:isEnemy() then return p end
		end
	else
		for _, p in sgs.qlist(targets) do
			if p:isFriend() and p:getHp() < p:getMaxHp() then return p end
		end
	end
	return targets:first()
end

ai_skill_invoke.LuaHeartlead       = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getHp() == 1 and self.player:getHandcardNum() < 3 then return (true) or false end
	return (false) or false
end


ai_skill_invoke["erciyuan_qiji"]            = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local dying = data:toDying()
	if self:isFriend(dying.who) then return (true) or false end
	return (false) or false
end
ai_skill_invoke["suipian"]         = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local judge = data:toJudge()
	if self:needRetrial(judge) and (judge.pattern ~= ".") then return (true) or false end
	return (false) or false
end

sgs.ai_ajustdamage_from.LuaGungnir     = function(self, from, to, card, nature)
	if to:getHp() > from:getHp() then
		return 1
	end
end
sgs.ai_used_revises.LuaGungnir         = function(self, use)
	if use.card:isKindOf("Slash")
		and not self.player:getWeapon()
		and not use.isDummy
	then
		local use_card
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Weapon") then
				use_card = card
			end
		end
		if use_card then
			use.card = use_card

			use.to = AIList.new({})
			return false
		end
	end
end
sgs.hit_skill = sgs.hit_skill .. "|LuaGungnir"
ai_audited_aliases.register{id="ai_cardneed.LuaGungnir",registry="ai_cardneed",path={"LuaGungnir"},canonical_registry="ai_cardneed",canonical_path={"weapon"},self_index=3,defer_canonical=true}

sgs.ai_canliegong_skill.LuaGungnir = function(self, from, to)
	return from:getWeapon() ~= nil and from:hasWeapon(from:getWeapon():objectName())
end

ai_audited_aliases.register{id="ai_cardneed.luasynchrogazer",registry="ai_cardneed",path={"luasynchrogazer"},canonical_registry="ai_cardneed",canonical_path={"weapon"},self_index=3,defer_canonical=true}
sgs.double_slash_skill = sgs.double_slash_skill .. "|luasynchrogazer"

ai_audited_aliases.register{id="ai_cardneed.LuaCangshan",registry="ai_cardneed",path={"LuaCangshan"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}


ai_skill_invoke["moesenskill"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local p = data:toPlayer()
	if self:isFriend(p) then return (true) or false end
	return (false) or false
end


local luasynchrogazer_skill = {}
luasynchrogazer_skill.name = "luasynchrogazer"
table.insert(package_skills, luasynchrogazer_skill)
luasynchrogazer_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luasynchrogazercard") then return end
	if #self.enemies < 1 then return end
	return parse(self,request,"#luasynchrogazercard:.:")
end

ai_card_use["#luasynchrogazercard"] = function(self, card, use, request)
	use.card=final_parse(self,request,"#luasynchrogazercard:.:")
	return
end


sgs.ai_skill_playerchosen["luasynchrogazer_Target"] = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end




sgs.ai_skill_playerchosen["luasynchrogazer_Friend"] = function(self, targets)
	local drawnum = 1
	local friends = {}
	local player_list = AIList.new({})
	for _, player in ipairs(targets) do
		if self:isFriend(player) and not hasManjuanEffect(player) and not self:needKongcheng(player, true)
			and not (player:hasSkill("kongcheng") and player:isKongcheng() and drawnum <= 2) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return targets:first() end

	self:sortInPlace(friends, "defense")
	for _, friend in ipairs(friends) do
		if friend:getHandcardNum() < 2 and not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and (AssistTarget:getHandcardNum() < AssistTarget:getMaxCards() * 2 or AssistTarget:getHandcardNum() < self.player:getHandcardNum()) then
		for _, friend in ipairs(friends) do
			if friend:objectName() == AssistTarget:objectName() and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
				return friend
			end
		end
	end

	for _, friend in ipairs(friends) do
		if self:hasSkills(sgs.cardneed_skill, friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	self:sortInPlace(friends, "handcard")
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end
	return targets:first()
end



sgs.ai_use_value["luasynchrogazercard"] = 7
sgs.ai_use_priority["luasynchrogazercard"] = sgs.ai_use_priority.Slash + 0.1





sgs.ai_view_as.LuaCangshan = function(card, player, card_place, class_name)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
		and card:getTypeId() == sgs.Card_TypeEquip and not card:hasFlag("using")
		and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		local viewing_ai=known(player:getRoom()._ai,'LuaCangshan viewing AI')
	local pattern=known(viewing_ai.request and viewing_ai.request.pattern,'LuaCangshan current request pattern')
		if pattern == "Jink" then
			return material(card,"Jink","LuaCangshan")
		elseif pattern == "Slash" then
			return material(card,"slash","LuaCangshan")
		end
	end
end

local LuaCangshan_skill = {}
LuaCangshan_skill.name = "LuaCangshan"
table.insert(package_skills, LuaCangshan_skill)
LuaCangshan_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("he")
	cards = AIList.new(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end

	local equip_card
	self:sortByUseValueInPlace(cards, true)

	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive)
			and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			equip_card = card
			break
		end
	end

	if equip_card then
		local suit = equip_card:getSuitString()
		local number = equip_card:getNumberString()
		local card_id = equip_card:getKnownEffectiveId()
		local card_str = ("slash:LuaCangshan[%s:%s]=%d"):format(suit, number, card_id)
		local slash = parse(self,request,card_str)

		assert(slash)

		return slash
	end
end


local luayuehuang_skill = {}
luayuehuang_skill.name = "luayuehuang"
table.insert(package_skills, luayuehuang_skill)
luayuehuang_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luayuehuangcard") then return end
	
	return parse(self,request,"#luayuehuangcard:.:")
end

ai_card_use["#luayuehuangcard"] = function(self, card, use, request)
	use.card=final_parse(self,request,"#luayuehuangcard:.:")
	return
end

sgs.ai_use_value["luayuehuangcard"] = 7
sgs.ai_use_priority["luayuehuangcard"] = 9
sgs.double_slash_skill = sgs.double_slash_skill .. "|luayuehuang"
ai_audited_aliases.register{id="ai_cardneed.luayuehuang",registry="ai_cardneed",path={"luayuehuang"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}





ai_skill_choice["LuaJingming"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local target
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("noslash_jm") == 1 then
			target = p
		end
	end
	if not target then return ai_choice_result(("cancel"), options) end
	if self:isEnemy(target) then
		return ai_choice_result(("cancel"), options)
	else
		if target:getMaxHp() - target:getHp() > 0 and target:getHandcardNum() >= 1 then return ai_choice_result(("recover"), options) end
		return ai_choice_result(("eachdraw"), options)
	end
	return ai_choice_result(("cancel"), options)
end

sgs.ai_choicemade_filter.skillChoice["LuaJingming"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local target
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("noslash_jm") == 1 then
			target = p
		end
	end
	if target then
		if choice ~= "cancel" then
			self:updateIntention(player, target, -40)
		end
	end
end

sgs.ai_skill_cardask["@jmdiscard"] = function(self, data, pattern, target, target2)
	local p = data:toPlayer()
	if self.player:getHandcardNum() > 1 then
		local card_id
		local hcards = self.player:getCards("h")
		hcards = AIList.new(hcards)
		self:sortByKeepValueInPlace(hcards)
		if self:isFriend(p) then
			if isEquip("Crossbow", p) then return "." end
			if p:getHp() + p:getHandcardNum() >= 4 then return "." end
			if p:getHandcardNum() + 3 >= p:getHp() then return "." end
			card_id = hcards[1]:getEffectiveId()
			return hcards[1]
		elseif self:isEnemy(p) then
			if p:getHandcardNum() <= 3 then return "." end
			if not isEquip("Crossbow", p) then return "." end
			card_id = hcards[1]:getEffectiveId()
			if self:isWeak(self.player) and p:inMyAttackRange(self.player) then
				if card_id then
					return hcards[1]
				end
			end
		end
		if card_id then
			return hcards[1]
		end
	end
	return "."
end



local luayingxian_skill = {}
luayingxian_skill.name = "luayingxian"
table.insert(package_skills, luayingxian_skill)
luayingxian_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luayingxiancard") then return end
	
	return parse(self,request,"#luayingxiancard:.:")
end

ai_card_use["#luayingxiancard"] = function(self, card, use, request)
	use.card=final_parse(self,request,"#luayingxiancard:.:")
	return
end

sgs.ai_use_value["luayingxiancard"] = 7
sgs.ai_use_priority["luayingxiancard"] = 9

sgs.ai_cardshow.luayingxiancard = function(self, requestor)
	local max = 0
	local result
	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:getNumber() > max then
			max = card:getNumber()
			result = card
		end
	end


	return result 
end


local luasaoshe_skill = {}
luasaoshe_skill.name = "luasaoshe"
table.insert(package_skills, luasaoshe_skill)
luasaoshe_skill.getTurnUseCard=function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies < 1 then return end
	if self.player:isKongcheng() then return end
	local cards = AIList.new(self.player:getHandcards())
	local card_OK = false
	for _, acard in ipairs(cards) do
		if not acard:isKindOf("Jink") and not acard:isKindOf("Peach") and not acard:isKindOf("Analeptic") then
			card_OK = true
		end
	end
	if not card_OK then return end
	local selfSub = self.player:getHp() - self.player:getHandcardNum()
	local selfDef = self:getDefense(self.player)

	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = self:getEvaluationCard("slash")
		
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(nil, enemy) and def < 6 and eff and enemy:getMark("SaosheX") < 2 then
			return parse(self,request,"#luasaoshecard:.:")
		end
	end
end

ai_card_use["#luasaoshecard"] = function(self, card, use, request)
	local cards = AIList.new(self.player:getHandcards())
	local target
	local card
	for _, acard in ipairs(cards) do
		if not acard:isKindOf("Jink") and not acard:isKindOf("Peach") and not acard:isKindOf("Analeptic") then
			card = acard
		end
	end
	local selfSub = self.player:getHp() - self.player:getHandcardNum()
	local selfDef = self:getDefense(self.player)

	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = self:getEvaluationCard("slash")
		
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, nil)

		if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(nil, enemy) and def < 6 and eff and enemy:getMark("SaosheX") < 2 then
			target = enemy
			break
		end
	end
	if target and card then
		use.card=final_parse(self,request,"#luasaoshecard:" .. card:getKnownEffectiveId() .. ":")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["luasaoshecard"]       = 9
sgs.ai_use_priority["luasaoshecard"]    = 3.2
sgs.ai_card_intention["luasaoshecard"]  = 80

ai_skill_invoke.LuaDikai            = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	if damage.from and self:isEnemy(damage.from) then
		if self:doDisCard(damage.from) then
			return (true) or false
		end
	end
	if self:isFriend(damage.from) then
		return (self:needToThrowArmor(damage.from) or self:doDisCard(damage.from)) or false
	end
	return (not damage.from or not self:isFriend(damage.from)) or false
end

sgs.ai_can_damagehp.LuaDikai = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from) and self:isWeak(from) and from:getCardCount()>0
	end
end

sgs.ai_skill_cardask["@dikai"]          = function(self, data, pattern, target)
	if self:isFriend(target) then
		local weapon, armor, def_horse, off_horse = {}, {}, {}, {}
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Weapon") then
				table.insert(weapon, card)
			elseif card:isKindOf("Armor") then
				table.insert(armor, card)
			elseif card:isKindOf("DefensiveHorse") then
				table.insert(def_horse, card)
			elseif card:isKindOf("OffensiveHorse") then
				table.insert(off_horse, card)
			end
		end
		if #armor > 0 then
			for _, card in ipairs(armor) do
				if ((not target:getArmor() and not target:hasSkills("bazhen|yizhong"))
						or (target:getArmor() and self:evaluateArmor(card, target) >= self:evaluateArmor(target:getArmor(), target)))
					and not (card:isKindOf("Vine") and use.card:isKindOf("FireSlash") and self:slashIsEffective(use.card, target, use.from)) then
					return "$" .. card:getKnownEffectiveId()
				end
			end
		end
		if self:needToThrowArmor()
			and ((not target:getArmor() and not target:hasSkills("bazhen|yizhong"))
				or (target:getArmor() and self:evaluateArmor(self.player:getArmor(), target) >= self:evaluateArmor(target:getArmor(), target)))
			and not (self.player:getArmor():isKindOf("Vine") and use.card:isKindOf("FireSlash") and self:slashIsEffective(use.card, target, use.from)) then
			return "$" .. self.player:getArmor():getEffectiveId()
		end
		if #def_horse > 0 then return "$" .. def_horse[1]:getEffectiveId() end
		if #weapon > 0 then
			for _, card in ipairs(weapon) do
				if not target:getWeapon()
					or (self:evaluateArmor(card, target) >= self:evaluateArmor(target:getWeapon(), target)) then
					return "$" .. card:getKnownEffectiveId()
				end
			end
		end
		if self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon()) < 5
			and (not target:getArmor()
				or (self:evaluateArmor(self.player:getWeapon(), target) >= self:evaluateArmor(target:getWeapon(), target))) then
			return "$" .. self.player:getWeapon():getEffectiveId()
		end
		if #off_horse > 0 then return "$" .. off_horse[1]:getEffectiveId() end
		if self.player:getOffensiveHorse()
			and ((self.player:getWeapon() and not self.player:getWeapon():isKindOf("Crossbow")) or self.player:hasSkills("mashu|tuntian")) then
			return "$" .. self.player:getOffensiveHorse():getEffectiveId()
		end
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if not self:isValuableCard(card) then return "$" .. card:getKnownEffectiveId() end
		end
	end
end


sgs.ai_skill_playerchosen["LuaLuowang"] = function(self, targets)
	targets = AIList.new(targets)
	if self.player:hasFlag("luoDraw") then
		return self:findPlayerToDraw(true)
	else
		local target = self:findPlayerToDiscard("he", true)[1]
		if target then
			return target
		end
		for _, enemy in ipairs(self.enemies) do
            if self:doDisCard(enemy, "he") then
				return enemy
            end
        end
	end
	return targets[1]
end

for _,skill in ipairs(package_skills)do ai_fill_skill[skill.name]=skill.getTurnUseCard end
do local source=ai_skill_use['@@LuaQisi'];ai_skill_use['@@LuaQisi']=function(self, prompt, request)
 local wire=source(self,prompt, request);if wire==nil or wire=='.'or type(wire)~='string'then return wire end
 local use=AIUsePlan.new();use.card=final_parse(self,nil,wire);return use:toAnswer()
end end

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["LuaBimie"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(from,"hasSkill","LuaBimie") and card and damage_call(card,"isKindOf","Slash") then
        		return nil, true
        	end
        return value
    end
    sgs.ai_need_damaged["LuaBimie"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_before_damage" and context.rule == "LuaBimie" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "LuaBimie", {
        {phase="need_hp_before_damage", order=4, rule="LuaBimie"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_need_damaged["LuaGaokang"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(self,"isFriend",to, from) and damage_call(to,"hasSkill","LuaGaokang") and damage_call(to,"canDiscard",to, "he")
        	then
        		if card and sgs.card_damage_nature[damage_call(card,"getClassName")] == sgs.DamageStruct_Normal then
        			return nil, true
        		end
        	end
        return value
    end
    sgs.ai_need_damaged["LuaGaokang"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_after_legacy" and context.rule == "LuaGaokang" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "LuaGaokang", {
        {phase="need_hp_after_legacy", order=1, rule="LuaGaokang"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["good_after_slash.bimie"]
    local policy = function(self, to, context)
        local value, good_query = context.value, context.query
        local card, damageNum, apn, value_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4]
        if good_query(to, "hasSkill", "LuaBimie") or good_query(to, "hasSkill", "fatebimie") then return true, true end
        return value
    end
    sgs.ai_target_damage["good_after_slash.bimie"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "good_after_slash" and context.rule == "bimie" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "good_after_slash.bimie", {
        {phase="good_after_slash", order=2, rule="bimie"},
    })
end)()
end
