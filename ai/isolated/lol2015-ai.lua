-- Fixed lol2015-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local known = AIValue.requireKnown


local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return self:legacySkillSeed(skill, class, action_request(self,request)) end
local skill_cards={['#lol_ayjm_rCard']='lol_ayjm_r',['#lol_bjfh_eCard']='lol_bjfh_e',['#lol_bjfh_qCard']='lol_bjfh_q',['#lol_bjfh_rCard']='lol_bjfh_r',['#lol_bzll_eCard']='lol_bzll_e',['#lol_hbss_eCard']='lol_hbss_e',['#lol_hbss_qCard']='lol_hbss_q',['#lol_jwyh_eCard']='lol_jwyh_e',['#lol_jwyh_qCard']='lol_jwyh_q',['#lol_jwyh_rCard']='lol_jwyh_r',['#lol_jwyh_wCard']='lol_jwyh_w',['#lol_mzzw_qCard']='lol_mzzw_q',['#lol_mzzw_rCard']='lol_mzzw_r',['#lol_mzzw_wCard']='lol_mzzw_w',['#lol_smss_eCard']='lol_smss_e',['#lol_smss_qCard']='lol_smss_q',['#lol_smss_rCard']='lol_smss_r',['#lol_smss_wCard']='lol_smss_w',['#lol_sxls_eCard']='lol_sxls_e',['#lol_sxls_rCard']='lol_sxls_r',['#lol_sxls_wCard']='lol_sxls_w',['#lol_tqz_eCard']='lol_tqz_e',['#lol_tqz_rCard']='lol_tqz_r',['#lol_tqz_wCard']='lol_tqz_w',['#lol_xlnw_eCard']='lol_xlnw_e',['#lol_xlnw_rCard']='lol_xlnw_r',['#lol_xlnw_wCard']='lol_xlnw_w'}
local function disclosed(self,id)return known(self:getKnownCardById(id)or self:getChoiceCard(id),'lol2015 source card '..tostring(id))end
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
 if #cards~=player:getHandcardNum()then ai_unsupported('lol2015 source requires full foreign hand sorting','lol2015.whole_hand')end
 return cards
end
local function is_pet(self,player)
 local name=player:getGeneral2Name()
 if name=='lol_xlnw_pks'then return true end
 if player:getMark('@lol_xlnw_t')>0 then return true end
 if name==nil then ai_unsupported('pet general is not disclosed','lol_xlnw_e.general2')end
 return false
end
local function find_general(self,player)
 local name=player:getKnownGeneralName();local names=name:split('+')
 for _,p in ipairs(self.room:getAlivePlayers())do
  if table.contains(names,p:getKnownGeneralName())then return p end
 end
 return nil
end
local function empty_state(self)
 -- Turn flag clears reset the remembered flag. The source's explicit "-lol_jwyh_w_empty"
 -- at the end of the once-per-phase effect has no witness; no later read happens in that turn.
 local name=self.player:objectName()
 local epoch=known(known(AIWorldLifecycle.epochs(self.world,'flag'),'strategy_flag_clear_epochs')[name],'owner flag clear epoch')
 local prior=self:getStrategyMemory('lol2015.w_empty')
 if prior and prior.epoch==epoch then return prior.value,epoch end
 return self.player:hasFlag('lol_jwyh_w_empty'),epoch
end
local function get_empty(self)local value=empty_state(self);return value end
local function set_empty(self,value)local _,epoch=empty_state(self);self:setStrategyMemory('lol2015.w_empty',{epoch=epoch,value=value})end
local lol_jwyh_q_skill = {}
lol_jwyh_q_skill.name = "lol_jwyh_q"
table.insert(package_skills, lol_jwyh_q_skill)
lol_jwyh_q_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:isKongcheng() then return end
	if not self.player:getStrategyHasUsed("#lol_jwyh_qCard") then
		return parse(self,request,"#lol_jwyh_qCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_jwyh_qCard"] = function(card,use,self,request)
	self:updatePlayers()
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortInPlace(self.enemies, "handcard")
	self:sortByCardNeed(handcards, true)
	local targets = {}
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") and c:isRed() then
			use_card = c
		end
	end
	if use_card == nil then return end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() >= self.player:getHandcardNum() and enemy:hasFlag("lol_jwyh_e") and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:doDisCard(enemy, "h", true)   then
			table.insert(targets, enemy)
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() >= self.player:getHandcardNum() and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:doDisCard(enemy, "h", true)   then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then return end
	
	local card_str =   string.format("#lol_jwyh_qCard:%s:", use_card:getKnownEffectiveId())
	local acard=final_parse(self,request,card_str)
	use.card = acard
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_priority["lol_jwyh_qCard"] = 7
sgs.ai_use_value["lol_jwyh_qCard"] = 7
sgs.ai_card_intention["lol_jwyh_qCard"] = 30

sgs.ai_skill_invoke["lol_jwyh_q"] = function(self, data)
	local target = data:toPlayer()
	if self:isEnemy(target) and not self:cantbeHurt(target) and self:damageIsEffective(target) then
		return true
	end
	return false
end

sgs.ai_skill_cardchosen["lol_jwyh_qCard"] = function(self, who, flags)
	self:updatePlayers()
	local handcards = AIList.new(whole_hand(self,who))
	self:sortByUseValueInPlace(handcards)
	if self:isEnemy(who) then
		if who:hasFlag("lol_jwyh_e") then
			for _,c in ipairs(handcards) do
				if c:isRed() then
					return c:getKnownEffectiveId()
				end
			end
		end
	end
	return handcards[1]
end

local lol_jwyh_w_skill = {}
lol_jwyh_w_skill.name = "lol_jwyh_w"
table.insert(package_skills, lol_jwyh_w_skill)
lol_jwyh_w_skill.getTurnUseCard=function(self,inclusive,request)
	if not self.player:getStrategyHasUsed("#lol_jwyh_wCard") then
		return parse(self,request,"#lol_jwyh_wCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_jwyh_wCard"] = function(card,use,self,request)
	self:updatePlayers()
	local tos = AIList.new({})
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			    if self.player:distanceTo(p) <= 1 and p:objectName() ~= self.player:objectName()  and self:damageIsEffective(p, sgs.DamageStruct_Fire) and not self:cantbeHurt(p) and self:isEnemy(p) then tos:append(p) end
            end
	if tos:isEmpty() then
	set_empty(self,true)
	end
	if self:isWeak() or not tos:isEmpty() then
		local card_str =   "#lol_jwyh_wCard:.:"
		local acard=final_parse(self,request,card_str)
		use.card = acard
	end
end

sgs.ai_use_priority["lol_jwyh_wCard"] = 0
sgs.ai_use_value["lol_jwyh_wCard"] = 4

sgs.ai_skill_cardask["@lol_jwyh_w_discard"] =function(self, data, pattern, target, target2)
	local num = data:toInt()
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local overflow = self:getOverflow()
		if self.player:hasSkill("lol_jwyh_t") and self.player:getMark("@lol_jwyh_t") < 8 - overflow  and self:isWeak() then
			local use_card = nil
			for _,c in ipairs(handcards) do
				if not c:isKindOf("Peach") then
					use_card = c
				end
			end
			if use_card == nil then return "." end
			return "$" .. use_card:getKnownEffectiveId()
		end
		if not (self.player:hasFlag("lol_jwyh_wR") and self.player:hasFlag("lol_jwyh_wB")) and not get_empty(self)  then
			local use_card = nil
			if self.player:hasFlag("lol_jwyh_wR") then
				for _,c in ipairs(handcards) do
					if not c:isKindOf("Peach") and c:isRed() then
						use_card = c
					end
				end
				if use_card == nil then return "." end
				return "$" .. use_card:getKnownEffectiveId()
			end
			if self.player:hasFlag("lol_jwyh_wR") then
				for _,c in ipairs(handcards) do
					if c:isBlack() then
						use_card = c
					end
				end
				if use_card == nil then return "." end
				return "$" .. use_card:getKnownEffectiveId()
			end
		end
	return "."
end

sgs.ai_skill_playerchosen["lol_jwyh_wCard"] = function(self, targets)
	local target
	targets = AIList.new(targets)
	self:sortInPlace(self.enemies, "defense")
	for _,enemy in ipairs(targets) do
		if enemy and self:isEnemy(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) and not self:cantbeHurt(enemy)  then
			target= enemy
			break
		end
	end
	if target then return target end
	return false
end


local lol_jwyh_e_skill = {}
lol_jwyh_e_skill.name = "lol_jwyh_e"
table.insert(package_skills, lol_jwyh_e_skill)
lol_jwyh_e_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:isKongcheng() then return end
	if self:getOverflow() < 2 then return end
	if not self.player:getStrategyHasUsed("#lol_jwyh_eCard") then
		return parse(self,request,"#lol_jwyh_eCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_jwyh_eCard"] = function(card,use,self,request)
	self:updatePlayers()
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortInPlace(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	self:sortByCardNeed(handcards, true)
	local targets = {}
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") and c:isRed() then
			use_card = c
		end
	end
	if use_card == nil then return end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() >= self.player:getHandcardNum() then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then return end
	local card_str =   string.format("#lol_jwyh_eCard:%s:", use_card:getKnownEffectiveId())
	local acard=final_parse(self,request,card_str)
	use.card = acard
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_priority["lol_jwyh_eCard"] = 8
sgs.ai_use_value["lol_jwyh_eCard"] = 3
sgs.ai_card_intention["lol_jwyh_eCard"] = 10

sgs.ai_skill_use["@@lol_jwyh_r"] = function(self, prompt)
    local all_cards = AIList.new(self.player:getCards("h"))
	self:sortByKeepValueInPlace(all_cards)
	local use_card
	local spade = 0
	for _, c in ipairs(all_cards) do
		if c:getSuit() == sgs.Card_Spade then
			spade = spade + 1
			use_card = c
		end
	end
	local mark = self.player:getMark("lol_jwyh_r123")
	if (mark + spade >= 3 or self:isWeak()) and use_card then
    return string.format("#lol_jwyh_rCard:%s:", use_card:getKnownEffectiveId())
	end
	return "."
end



sgs.ai_ajustdamage_from.lol_hbss_t = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and from and from:getMark("@lol_hbss_t_Mark") == 100
	then
		return 1
	end
end

local lol_hbss_q_skill = {}
lol_hbss_q_skill.name = "lol_hbss_q"
table.insert(package_skills, lol_hbss_q_skill)
lol_hbss_q_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:isKongcheng() then return end
	if self.player:hasFlag("lol_hbss_q") then return end
	if self:getOverflow() < 1 then return end
	if self:getCardsNum("Slash") < 1 then return end
	if not self.player:getStrategyHasUsed("#lol_hbss_qCard") then
		return parse(self,request,"#lol_hbss_qCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_hbss_qCard"] = function(card,use,self,request)
	self:updatePlayers()
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local can_invoke = false
	local targets = {}
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach")  then
			use_card = c
		end
	end
	if use_card == nil then return end
	for _, slash in ipairs(self:getCards("Slash")) do
		if  slash:isAvailable(self.player) and slash:getKnownEffectiveId() ~= use_card then
			local dummy = self:aiUseCard(slash)
			if dummy.card and not dummy.to:isEmpty() then
				can_invoke = true
			end
		end
	end
	
	if not can_invoke then return end 
	local card_str =   string.format("#lol_hbss_qCard:%s:", use_card:getKnownEffectiveId())
	local acard=final_parse(self,request,card_str)
	use.card = acard
end

sgs.ai_use_priority["lol_hbss_qCard"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_use_value["lol_hbss_qCard"] = 1


local lol_hbss_w_skill = {}
lol_hbss_w_skill.name = "lol_hbss_w"
table.insert(package_skills, lol_hbss_w_skill)
lol_hbss_w_skill.getTurnUseCard=function(self,inclusive,request)
	local archery = self:getEvaluationCard("archery_attack")
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() + self.player:getPile("wooden_ox"):length() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = AIList.new(cards)
		
		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards ,disclosed(self,id))
			end
		end
		
		self:sortByKeepValueInPlace(cards)
		local useAll = false
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 and not enemy:hasArmorEffect("vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player)
				and self:isWeak(enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
			end
		end
		for _, fcard in ipairs(cards) do
			local fvalueCard = (self:isCard("Peach", fcard, self.player) or self:isCard("ExNihilo", fcard, self.player) or self:isCard("ArcheryAttack", fcard, self.player))
			if useAll then fvalueCard = self:isCard("ArcheryAttack", fcard, self.player) end
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (self:isCard("Peach", scard, self.player) or self:isCard("ExNihilo", scard, self.player) or self:isCard("ArcheryAttack", scard, self.player))
					if useAll then svalueCard = (self:isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard			and not svalueCard then

						local card_str = ("archery_attack:lol_hbss_w[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getKnownId(), scard:getKnownId())
						local archeryattack = parse(self,request,card_str)

						assert(archeryattack)
						
						local dummy = self:aiUseCard(archeryattack)
						if dummy.card then
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

	if first_found and second_found and not self.player:hasFlag("lol_hbss_w") then
		local first_id = first_card:getKnownId()
		local second_id = second_card:getKnownId()
		local card_str = ("archery_attack:lol_hbss_w[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = parse(self,request,card_str)
		assert(archeryattack)
		return archeryattack
	end
end


local lol_hbss_e_skill = {}
lol_hbss_e_skill.name = "lol_hbss_e"
table.insert(package_skills, lol_hbss_e_skill)
lol_hbss_e_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:isKongcheng() then return end
	if self:getOverflow() < 3 then return end
	if not self.player:getStrategyHasUsed("#lol_hbss_eCard") then
		return parse(self,request,"#lol_hbss_eCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_hbss_eCard"] = function(card,use,self,request)
	self:updatePlayers()
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	self:sortInPlace(self.enemies, "handcard")
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach")  then
			use_card = c
		end
	end
	if use_card == nil then return end
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then return end
	
	local card_str =   string.format("#lol_hbss_eCard:%s:", use_card:getKnownEffectiveId())
	local acard=final_parse(self,request,card_str)
	use.card = acard
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_priority["lol_hbss_eCard"] = 3
sgs.ai_use_value["lol_hbss_eCard"] = 1

lol_hbss_r_skill={}
lol_hbss_r_skill.name="lol_hbss_r"
table.insert(package_skills,lol_hbss_r_skill)
lol_hbss_r_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 then return end
	self:sortInPlace(self.enemies, "hp")
	if self.player:getMark("@lol_hbss_r") < 1 then return end

	local cards = AIList.new(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	if #cards == 0 then return end
	local cardToUse = cards[1]
	if not cardToUse then
		return
	end
	if cardToUse:isKindOf("Peach") then return end
	if not(self.enemies[1]:getHandcardNum() == 0 or self:canLiegong(self.enemies[1], self.player) ) or not self:slashIsEffective(self:getEvaluationCard("slash"), self.enemies[1]) then return end
	local suit = cardToUse:getSuitString()
	local number = cardToUse:getNumberString()
	local card_id = cardToUse:getKnownEffectiveId()
	local card_str = ("slash:lol_hbss_r[%s:%s]=%d"):format(suit, number, card_id)
	return parse(self,request,card_str)
end


local lol_mzzw_q_skill = {}
lol_mzzw_q_skill.name = "lol_mzzw_q"
table.insert(package_skills, lol_mzzw_q_skill)
lol_mzzw_q_skill.getTurnUseCard=function(self,inclusive,request)
	if not self:isWeak() then return end
	if  self.player:getMark("@lol_mzzw_t") < 50 then return end
	if self.player:getMark("lol_mzzw_r_damage") == 1 then return end
	if not self.player:getStrategyHasUsed("#lol_mzzw_qCard") then
		return parse(self,request,"#lol_mzzw_qCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_mzzw_qCard"] = function(card,use,self,request)
	self:updatePlayers()


	local acard=final_parse(self,request,"#lol_mzzw_qCard:.:")
	use.card = acard
end

sgs.ai_use_priority["lol_mzzw_qCard"] = sgs.ai_use_priority.Slash - 0.1
sgs.ai_use_value["lol_mzzw_qCard"] = 1


local lol_mzzw_w_skill = {}
lol_mzzw_w_skill.name = "lol_mzzw_w"
table.insert(package_skills, lol_mzzw_w_skill)
lol_mzzw_w_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 then return end 
	local x = 0
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			x = x + 1
		end
	end
	if not self.player:getStrategyHasUsed("#lol_mzzw_wCard") and x > 0 then
		return parse(self,request,"#lol_mzzw_wCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_mzzw_wCard"] = function(card,use,self,request)
	self:updatePlayers()
	self:sortInPlace(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			if use.to then use.to:append(enemy) end
		end
	end
	use.card=final_parse(self,request,"#lol_mzzw_wCard:.:")
	if use.to and use.to:length() > 0 then
	
	return end
end

sgs.ai_use_priority["lol_mzzw_wCard"] = 7
sgs.ai_use_value["lol_mzzw_wCard"] = 4


sgs.ai_skill_cardchosen.lol_mzzw_w = function(self, who, flags)
	local cards = AIList.new(whole_hand(self,who))
		for _, card in ipairs(cards) do
			if not card:isKindOf("Jink") and not card:isKindOf("Slash") then
				 return card 
			end
		end
	for _, card in ipairs(cards) do
			if  not card:isKindOf("Slash") then
				 return card 
			end
		end
	return cards[1]
end

























	


















































local lol_mzzw_r_skill = {}
lol_mzzw_r_skill.name = "lol_mzzw_r"
table.insert(package_skills, lol_mzzw_r_skill)
lol_mzzw_r_skill.getTurnUseCard=function(self,inclusive,request)
	if not self:isWeak() then return end
	if  self.player:getMark("@lol_mzzw_r") < 1 then return end
	if not self.player:getStrategyHasUsed("#lol_mzzw_rCard") then
		return parse(self,request,"#lol_mzzw_rCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_mzzw_rCard"] = function(card,use,self,request)
	self:updatePlayers()


	local acard=final_parse(self,request,"#lol_mzzw_rCard:.:")
	use.card = acard
end

sgs.ai_use_priority["lol_mzzw_rCard"] = sgs.ai_use_priority["lol_mzzw_qCard"] - 0.1
sgs.ai_use_value["lol_mzzw_rCard"] = 1

sgs.ai_hasBuquEffect_skill.lol_mzzw_r = function(player)
	return player:getMark("lol_mzzw_r_damage") > 0
end



lol_tqz_q_skill={}
lol_tqz_q_skill.name="lol_tqz_q"
table.insert(package_skills,lol_tqz_q_skill)
lol_tqz_q_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 then return end
	self:sortInPlace(self.enemies, "hp")
	
	local cards = AIList.new(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	if #cards == 0 then return end
	local cardToUse = cards[1]
	if not cardToUse then
		return
	end
	if cardToUse:isKindOf("Peach") or  not cardToUse:isRed() then return end
	if self.player:getMark("@lol_tqz_r") > 0 then
		self:setPriorityValue("lol_tqz_rCard", self:getPriorityValue("FireAttack")+0.1)
	end
	local suit = cardToUse:getSuitString()
	local number = cardToUse:getNumberString()
	local card_id = cardToUse:getKnownEffectiveId()
	local card_str = ("fire_attack:lol_tqz_q[%s:%s]=%d"):format(suit, number, card_id)
	return parse(self,request,card_str)
end


sgs.ai_skill_choice["lol_tqz_q"] = function(self, choices, data)
	local items = choices:split("+")
	 if table.contains(items, "lol_tqz_q_draw") then
		return "lol_tqz_q_draw"
   end
   if table.contains(items, "lol_tqz_q_damage") and self.player:getHandcardNum() > 2 then
	return "lol_tqz_q_damage"
   end
   
   return items[1]
end



local lol_tqz_w_skill = {}
lol_tqz_w_skill.name = "lol_tqz_w"
table.insert(package_skills, lol_tqz_w_skill)
lol_tqz_w_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:isKongcheng() then return end
	if self:getOverflow() < 1 then return end
		if not self.player:getStrategyHasUsed("#lol_tqz_wCard") then
			if self.player:getMark("@lol_tqz_r") > 0 then
				self:setPriorityValue("lol_tqz_rCard", self:getPriorityValue("lol_tqz_eCard")+0.1)
			end
			return parse(self,request,"#lol_tqz_wCard:.:")
		end
end

sgs.ai_skill_use_func["#lol_tqz_wCard"] = function(card,use,self,request)
	self:updatePlayers()
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	self:sortInPlace(self.enemies, "handcard")
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach")  then
			use_card = c
		end
	end
	if use_card == nil then return end

	local target
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			target = enemy
			break
		end
	end
	if target then
		local card_str =   string.format("#lol_tqz_wCard:%s:", use_card:getKnownEffectiveId())
		local acard=final_parse(self,request,card_str)
		use.card = acard
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_priority["lol_tqz_wCard"] = 3
sgs.ai_use_value["lol_tqz_wCard"] = 1

sgs.ai_skill_choice["lol_tqz_wCard"] = function(self, choices, data)
	local items = choices:split("+")
	 if table.contains(items, "lol_tqz_w_hp") and self.player:isWounded() then
		return "lol_tqz_w_hp"
   end
   if table.contains(items, "lol_tqz_w_throw")  then
	return "lol_tqz_w_throw"
   end
   
   return items[1]
end

local lol_tqz_e_skill = {}
lol_tqz_e_skill.name = "lol_tqz_e"
table.insert(package_skills, lol_tqz_e_skill)
lol_tqz_e_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:isKongcheng() then return end
	if self.player:getMark("@lol_tqz_r") > 0 then
		self:setPriorityValue("lol_tqz_rCard", self:getPriorityValue("lol_tqz_eCard")+0.1)
	end
	if not self.player:getStrategyHasUsed("#lol_tqz_eCard") then
		return parse(self,request,"#lol_tqz_eCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_tqz_eCard"] = function(card,use,self,request)
	self:updatePlayers()
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	self:sortInPlace(self.friends, "handcard")
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") and c:getSuit() == sgs.Card_Diamond  then
			use_card = c
		end
	end
	if use_card == nil then return end

	local target
	for _, friend in ipairs(self.friends) do
		if  self:isWeak(friend) then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends) do
			if not self:needToLoseHp(friend) then
				target = friend
				break
			end
		end
	end
	if target then
		local card_str =   string.format("#lol_tqz_eCard:%s:", use_card:getKnownEffectiveId())
		local acard=final_parse(self,request,card_str)
		use.card = acard
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_priority["lol_tqz_eCard"] = 3
sgs.ai_use_value["lol_tqz_eCard"] = 1

sgs.ai_skill_choice["lol_tqz_eCard"] = function(self, choices, data)
	local items = choices:split("+")
	 if table.contains(items, "lol_tqz_e_hudun") then
		return "lol_tqz_e_hudun"
   end
   if table.contains(items, "lol_tqz_e_draw")  then
	return "lol_tqz_e_draw"
   end
   
   return items[1]
end






local lol_tqz_r_skill = {}
lol_tqz_r_skill.name = "lol_tqz_r"
table.insert(package_skills, lol_tqz_r_skill)
lol_tqz_r_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 then return end
	
	if  self.player:getMark("@lol_tqz_r") < 1 then return end
	if not self.player:getStrategyHasUsed("#lol_tqz_rCard") then
		return parse(self,request,"#lol_tqz_rCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_tqz_rCard"] = function(card,use,self,request)
	self:updatePlayers()


	local acard=final_parse(self,request,"#lol_tqz_rCard:.:")
	use.card = acard
end

sgs.ai_use_value["lol_tqz_rCard"] = 1




sgs.ai_card_priority["lol_xlnw_q"] = function(self, card)
	if card and card:isKindOf("Slash") and table.contains(card:getSkillNames(), "lol_xlnw_q")
	then
		return 0.1
	end
end

local lol_xlnw_q_skill={}
lol_xlnw_q_skill.name="lol_xlnw_q"
table.insert(package_skills,lol_xlnw_q_skill)
lol_xlnw_q_skill.getTurnUseCard=function(self,inclusive,request)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasFlag("lol_xlnw_q") then return nil end
    local cards = self.player:getHandcards()
    cards=AIList.new(cards)
    self:sortByKeepValueInPlace(cards)
	local card

	self:sortByUseValueInPlace(cards, true)

	for _,acard in ipairs(cards)  do
		if (acard:getSuit() == sgs.Card_Club)  then
			card = acard
			break
		end
	end
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if disclosed(self,id):getSuit() == sgs.Card_Club		then
				card = disclosed(self,id)
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	local card_str = ("slash:lol_xlnw_q[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = parse(self,request,card_str)

	assert(skillcard)

	return skillcard
end


local lol_xlnw_w_skill = {}
lol_xlnw_w_skill.name = "lol_xlnw_w"
table.insert(package_skills, lol_xlnw_w_skill)
lol_xlnw_w_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#lol_xlnw_wCard") then return end

	local card
	if not card then
		local hcards = self.player:getCards("h")
		hcards = AIList.new(hcards)
		self:sortByUseValueInPlace(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:getSuit() == sgs.Card_Heart then
				card = hcard
				break
			end
		end
	end
	if card then
		card = parse(self,request,"#lol_xlnw_wCard:" .. card:getKnownEffectiveId()..":")
		return card
	end

	return nil
end

sgs.ai_skill_use_func["#lol_xlnw_wCard"] = function(card,use,self,request)
	local target
	local friends = self.friends_noself
	
	self:sortInPlace(friends, "handcard", true)
	
	for _, friend in ipairs(friends) do
		if  not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and friend:getPileCount("lol_jiasu") == 0 then
					target = friend
				end
		if target then break end
	end

	if not target then
		self:sortInPlace(friends, "defense")
		for _, friend in ipairs(friends) do
			if  not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				target = friend
				break
			end
		end
	end

	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end
sgs.ai_use_priority["lol_xlnw_wCard"] = 7
sgs.ai_use_value["lol_xlnw_wCard"] = 3


sgs.ai_skill_invoke.lol_xlnw_e = function(self, data)
	local target = data:toPlayer()
	if not self:isEnemy(target) then return false end
	local pks
	for _,pet in sgs.qlist(self.room:getAlivePlayers()) do
		if is_pet(self,pet) then pks = pet end
	end
	if pks then
		if self:doDisCard(pks, "h") then return true end
		if self:isWeak(pks) then
			return false
		end
	end
	if not self:isEnemy(target) then return false end
	return true
end

local lol_xlnw_e_skill = {}
lol_xlnw_e_skill.name = "lol_xlnw_e"
table.insert(package_skills, lol_xlnw_e_skill)
lol_xlnw_e_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#lol_xlnw_eCard") then return end
	if #self.friends_noself < 1 then return end
	local card = parse(self,request,"#lol_xlnw_eCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_xlnw_eCard"] = function(card,use,self,request)
	local target
	self:sortInPlace(self.friends_noself, "handcard", true)

	
	for _, friend in ipairs(self.friends_noself) do
		if self:hasHeavyDamage(friend, nil, nil) then
					target = friend
				end
		if target then break end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
						target = friend
			if target then break end
		end
	end
	
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority["lol_xlnw_eCard"] = sgs.ai_use_priority.Slash  + 0.35
sgs.ai_use_value["lol_xlnw_eCard"] = 3
sgs.ai_card_intention["lol_xlnw_eCard"] = -40

local lol_xlnw_r_skill = {}
lol_xlnw_r_skill.name = "lol_xlnw_r"
table.insert(package_skills, lol_xlnw_r_skill)
lol_xlnw_r_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#lol_xlnw_rCard") then return end
	if self.player:getMark("@lol_xlnw_r") < 1 then return end
	if #self.friends_noself < 1 then return end
	local card = parse(self,request,"#lol_xlnw_rCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_xlnw_rCard"] = function(card,use,self,request)
	local target
	self:sortInPlace(self.friends, "hp")

	
	for _, friend in ipairs(self.friends) do
		if self:isWeak(friend) then
					target = friend
				end
		if target then break end
	end
	if not target then return end 
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	self:sortInPlace(self.friends, "handcard")
	local use_card = {}
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") and #use_card < target:getHp()  then
			table.insert(use_card, c:getKnownEffectiveId())
		end
	end
	if #use_card ~= target:getHp() then return end
	
	if target then
		local card_str = string.format("#lol_xlnw_rCard:%s:", table.concat(use_card, "+"))
		local acard=final_parse(self,request,card_str)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end




sgs.ai_ajustdamage_from.lol_smss_q = function(self, from, to, card, nature)
	if (card and (card:isKindOf("Slash"))) and from:hasFlag("lol_smss_q")
	then
		return from:getMark("@lol_smss_q")
	end
end

sgs.ai_used_revises.lol_smss_q = function(self, use)
	if use.card:isKindOf("Slash")
		and not self.player:hasFlag("lol_smss_q")
		and not use.isDummy
		and not self.player:getStrategyHasUsed("#lol_smss_qCard")
	then
		for _, to in sgs.list(use.to) do
			if self:isEnemy(to) and to:getHp() < 2
				and getCardsNum("Jink", to, self.player) < 1 
			then
				local handcards = AIList.new(self.player:getCards("h"))
				local card_str = string.format("#lol_smss_qCard:%s:", handcards[1]:getEffectiveId())
				local acard=final_parse(self,request,card_str)
				use.card = acard
				use.to = AIList.new({})
				return false
			end
		end
	end
end

local lol_smss_q_skill = {}
lol_smss_q_skill.name = "lol_smss_q"
table.insert(package_skills, lol_smss_q_skill)
lol_smss_q_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#lol_smss_qCard") then return end
	local card = parse(self,request,"#lol_smss_qCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_smss_qCard"] = function(card,use,self,request)
	if self:isWeak() then
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local invoke = false
	local use_card = {}
	for _,c in ipairs(handcards) do
		if c:isKindOf("Slash") then
			self:sortInPlace(self.enemies, "defense")
			for _, enemy in ipairs(self.enemies) do
				if  self.player:getMark("@lol_smss_q") > 0 and self:slashIsEffective(c, enemy) then
					invoke = true
					break
				end
			end
		end
	end
	
	if invoke then
		local card_str = string.format("#lol_smss_qCard:%s:", handcards[1]:getEffectiveId())
		local acard=final_parse(self,request,card_str)
		use.card = acard
		end
	end
end
sgs.ai_use_priority["lol_smss_qCard"] = sgs.ai_use_priority.Slash + 8


local lol_smss_w_skill = {}
lol_smss_w_skill.name = "lol_smss_w"
table.insert(package_skills, lol_smss_w_skill)
lol_smss_w_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#lol_smss_wCard") then return end

	local card
	if not card then
		local hcards = self.player:getCards("h")
		hcards = AIList.new(hcards)
		self:sortByUseValueInPlace(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:getSuit() == sgs.Card_Spade then
				card = hcard
				break
			end
		end
	end
	if card then
		card = parse(self,request,"#lol_smss_wCard:" .. card:getKnownEffectiveId()..":")
		return card
	end

	return nil
end

sgs.ai_skill_use_func["#lol_smss_wCard"] = function(card,use,self,request)
	local target
	
	

	if not target then
		self:sortInPlace(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if  self:isWeak(enemy) and enemy:getPileCount("lol_jiansu") == 0 then
				target = enemy
				break
			end
		end
	end
	if not target then
		self:sortInPlace(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if  self:getOverflow() > 0 and enemy:getPileCount("lol_jiansu") == 0 then
				target = enemy
				break
			end
		end
	end

	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority["lol_smss_wCard"] = 8
sgs.ai_use_value["lol_smss_wCard"] = 3
sgs.ai_card_intention["lol_smss_wCard"] = 50



local lol_smss_e_skill = {}
lol_smss_e_skill.name= "lol_smss_e"
table.insert(package_skills,lol_smss_e_skill)
lol_smss_e_skill.getTurnUseCard=function(self,inclusive,request)
	if not self.player:getStrategyHasUsed("#lol_smss_eCard") then
		return parse(self,request,"#lol_smss_eCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_smss_eCard"] = function(card,use,self,request)
		local use_card
		local  cards
		local target
		cards = self.player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Heart and not card:isKindOf("Peach") then
				use_card = card
				break
			end
		end
		self:sortInPlace(self.enemies)
		local max= 0
		for _, enemy in ipairs(self.enemies) do
			local x = 0
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				for _, p in sgs.qlist(self.room:getAlivePlayers()) do
					if enemy:distanceTo(p) <= 1 then
						x = x + 1
					end
				end
				if 3 - x > max then
					max = 3 - x
					target = enemy 
					break
				end
			end
		end
		
				if use_card and target  then
					use.card=final_parse(self,request,"#lol_smss_eCard:" .. use_card:getKnownId()..":")
					if use.to then
						use.to:append(target)
					end
	end
end

sgs.ai_use_priority["lol_smss_eCard"] = 7
sgs.ai_use_value["lol_smss_eCard"] = 3
sgs.ai_card_intention["lol_smss_eCard"] = 50


local lol_smss_r_skill = {}
lol_smss_r_skill.name = "lol_smss_r"
table.insert(package_skills, lol_smss_r_skill)
lol_smss_r_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#lol_smss_rCard") then return end
	if self.player:getMark("@lol_smss_r") < 1 then return end
	local card = parse(self,request,"#lol_smss_rCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_smss_rCard"] = function(card,use,self,request)
	if self:isWeak() then
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local use_card = {}
	for _,c in ipairs(handcards) do
		if c:isBlack() and #use_card < self.player:getHp()  then
			table.insert(use_card, c:getKnownEffectiveId())
		end
	end
	if #use_card ~= self.player:getHp() then return end
	
	
		local card_str = string.format("#lol_smss_rCard:%s:", table.concat(use_card, "+"))
		local acard=final_parse(self,request,card_str)
		use.card = acard
	end
end






sgs.ai_canNiepan_skill.lol_ayjm_t = function(player)
	return player:getMark("@lol_ayjm_t") > 0
end

local lol_ayjm_q_skill={}
lol_ayjm_q_skill.name="lol_ayjm_q"
table.insert(package_skills,lol_ayjm_q_skill)
lol_ayjm_q_skill.getTurnUseCard=function(self,inclusive,request)
	if self:isWeak() then return nil end
	 if self.player:getHp() <= 1 then return nil end
    
    if self.player:hasFlag("lol_ayjm_q") then return nil end
   


	local card_str = ("slash:lol_ayjm_q[%s:%s]=."):format(sgs.Card_NoSuit, 0)
	local skillcard = parse(self,request,card_str)

	assert(skillcard)

	return skillcard
end



sgs.ai_skill_choice["lol_ayjm_w"] = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toDamage().to
	if #items == 1 then
		return items[1]
	end
	if target and self:isEnemy(target) and ((self:getCardsNum("Peach") + self.player:getHp() >= 2) or self:getOverflow() == 0) and  table.contains(items, "lol_ayjm_w_damage")  then
		return "lol_ayjm_w_damage"
	end
	if  target and (self:isFriend(target) or self:isWeak()) and  table.contains(items, "lol_ayjm_w_hp")  then
		return "lol_ayjm_w_hp"
	end
	return "cancel"
end





local lol_ayjm_e_skill={}
lol_ayjm_e_skill.name="lol_ayjm_e"
table.insert(package_skills,lol_ayjm_e_skill)
lol_ayjm_e_skill.getTurnUseCard=function(self,inclusive,request)
	if self:isWeak() then return nil end
    if self.player:hasFlag("lol_ayjm_e") then return nil end
    if self.player:getHp() <= 1 then return nil end
    
	local card_str = ("slash:lol_ayjm_e[%s:%s]=."):format(sgs.Card_NoSuit, 0)
	local skillcard = parse(self,request,card_str)

	assert(skillcard)

	return skillcard
end








local lol_ayjm_r_skill = {}
lol_ayjm_r_skill.name = "lol_ayjm_r"
table.insert(package_skills, lol_ayjm_r_skill)
lol_ayjm_r_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#lol_ayjm_rCard") then return end
	if self.player:getMark("@lol_ayjm_r") < 1 then return end
	local card = parse(self,request,"#lol_ayjm_rCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_ayjm_rCard"] = function(card,use,self,request)
	if self:isWeak() then
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local invoke = false
	local use_card = {}
	for _,c in ipairs(handcards) do
		if c:isKindOf("Slash") then
			self:sortInPlace(self.enemies, "defense")
			for _, enemy in ipairs(self.enemies) do
				if  self:isWeak(enemy) and self:slashIsEffective(c, enemy) then
					invoke = true
					break
				end
			end
		end
	end
	
	if invoke then
		use.card = card
		end
	end
end
sgs.ai_use_priority["lol_ayjm_rCard"] = sgs.ai_use_priority.Slash - 0.1


sgs.ai_canNiepan_skill.lol_bjfh_t = function(player)
	return true
end

local lol_bjfh_q_skill = {}
lol_bjfh_q_skill.name= "lol_bjfh_q"
table.insert(package_skills,lol_bjfh_q_skill)
lol_bjfh_q_skill.getTurnUseCard=function(self,inclusive,request)
	return parse(self,request,"#lol_bjfh_qCard:.:")
end

sgs.ai_skill_use_func["#lol_bjfh_qCard"] = function(card,use,self,request)
	
	local use_card,cards
	cards = self.player:getHandcards()
	for _,card in sgs.qlist(cards)do
		if card:isRed() then
			use_card = card
			break
		end
	end
	self:sortInPlace(self.enemies)
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		then
			if use_card then
				use.card=final_parse(self,request,"#lol_bjfh_qCard:"..use_card:getKnownId()..":")
				if use.to then use.to:append(enemy) end
				break
			end
		end
	end
end

sgs.ai_use_value["#lol_bjfh_qCard"] = 2.5
sgs.ai_card_intention["#lol_bjfh_qCard"] = 80
sgs.dynamic_value.damage_card["#lol_bjfh_qCard"] = true



sgs.ai_skill_cardask["@lol_bjfh_q-card"]=function(self,data)
	local judge = data:toJudge()
	local all_cards = self:addHandPile("h")
	if #all_cards<1 then return "." end
	local cards = {}
	for _,card in sgs.list(all_cards)do
		if card:isRed() and not card:hasFlag("using") then
			table.insert(cards,card)
		end
	end
	if #cards<1 then return "." end
	local card_id = self:getRetrialCardId(cards, judge, nil, true)
	if card_id>=0 and self:needRetrial(judge)
	or self:getUseValue(judge.card)>self:getUseValue(disclosed(self,card_id))
	then return "$"..card_id end
	return "."
end

local lol_bjfh_e_skill = {}
lol_bjfh_e_skill.name= "lol_bjfh_e"
table.insert(package_skills,lol_bjfh_e_skill)
lol_bjfh_e_skill.getTurnUseCard=function(self,inclusive,request)
	return parse(self,request,"#lol_bjfh_eCard:.:")
end

sgs.ai_skill_use_func["#lol_bjfh_eCard"] = function(card,use,self,request)
	
	local use_card,cards
	cards = self.player:getHandcards()
	for _,card in sgs.qlist(cards)do
		use_card = card
		break
	end
	self:sortInPlace(self.enemies)
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and enemy:getPileCount("lol_jiansu")>0
		then
			if use_card then
				use.card=final_parse(self,request,"#lol_bjfh_eCard:"..use_card:getKnownId()..":")
				if use.to then use.to:append(enemy) end
				return
				
			end
		end
	end
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		then
			if use_card then
				use.card=final_parse(self,request,"#lol_bjfh_eCard:"..use_card:getKnownId()..":")
				if use.to then use.to:append(enemy) end
				return
				
			end
		end
	end
end

sgs.ai_use_value["#lol_bjfh_eCard"] = 2.5
sgs.ai_card_intention["#lol_bjfh_eCard"] = 80
sgs.dynamic_value.damage_card["#lol_bjfh_eCard"] = true

local lol_bjfh_r_skill = {}
lol_bjfh_r_skill.name= "lol_bjfh_r"
table.insert(package_skills,lol_bjfh_r_skill)
lol_bjfh_r_skill.getTurnUseCard=function(self,inclusive,request)
	if self.room:getTurnCount()<=1 then return end
	if self.player:getMark("@lol_bjfh_r") == 0 then return end
	return parse(self,request,"#lol_bjfh_rCard:.:")
end

sgs.ai_skill_use_func["#lol_bjfh_rCard"] = function(card,use,self,request)
	
	local use_card,cards
	cards = self.player:getHandcards()
	for _,card in sgs.qlist(cards)do
		use_card = card
		break
	end
	local targets = {}
	self:sortInPlace(self.enemies)
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		then
			table.insert(targets, enemy)
		end
	end
	if #targets > 0 then
		if use_card then
			use.card=final_parse(self,request,"#lol_bjfh_rCard:"..use_card:getKnownId()..":")
			
			if use.to then 
				for _,enemy in sgs.list(targets)do 
					use.to:append(enemy)
					end 
				end
			return
			
		end
	end
end

sgs.ai_use_value["#lol_bjfh_rCard"] = 2.5
sgs.ai_card_intention["#lol_bjfh_rCard"] = 80
sgs.dynamic_value.damage_card["#lol_bjfh_rCard"] = true



















local lol_sxls_q_skill={}
lol_sxls_q_skill.name="lol_sxls_q"
table.insert(package_skills,lol_sxls_q_skill)
lol_sxls_q_skill.getTurnUseCard=function(self,inclusive,request)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasFlag("lol_sxls_q") then return nil end
    local cards = self.player:getHandcards()
    cards=AIList.new(cards)
    self:sortByKeepValueInPlace(cards)
	local card

	self:sortByUseValueInPlace(cards, true)

	for _,acard in ipairs(cards)  do
		if (acard:getSuit() == sgs.Card_Heart)  then
			card = acard
			break
		end
	end
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if disclosed(self,id):getSuit() == sgs.Card_Heart		then
				card = disclosed(self,id)
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	local card_str = ("slash:lol_sxls_q[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = parse(self,request,card_str)

	assert(skillcard)

	return skillcard
end







local lol_sxls_w_skill = {}
lol_sxls_w_skill.name = "lol_sxls_w"
table.insert(package_skills, lol_sxls_w_skill)
lol_sxls_w_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#lol_sxls_wCard") then return end

	local card = parse(self,request,"#lol_sxls_wCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_sxls_wCard"] = function(card,use,self,request)

	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local invoke = false
	local use_card = {}
	local slashes = self:getCards("Slash")
	for _,e in sgs.list(self.player:getEquips())do
		for _,slash in sgs.list(AIList.new(slashes))do
			if slash:getKnownEffectiveId()==e:getKnownId()
			or table.contains(slash:getSkillNames(), e:objectName())
			or not slash:isAvailable(self.player)
			then table.removeOne(slashes,slash) end
		end
	end
	if #slashes<1 then return end
	for _,enemy in sgs.list(self.enemies)do
		for _,slash in sgs.list(slashes)do
			local d = self:aiUseCard(slash)
			if d.card and d.to:contains(enemy)
			and not(self:hasEightDiagramEffect(enemy)) then
			invoke = true
			break
			end
		end
	end
	for _,c in ipairs(handcards) do
		if (#use_card < 1) and not (#self:getCards("Slash") <= 1 and c:isKindOf("Slash")) then
			table.insert(use_card, c:getKnownEffectiveId())
		end
	end
	if #use_card ~= 1 then return end
	
	if invoke then
		local card_str = string.format("#lol_sxls_wCard:%s:", table.concat(use_card, "+"))
		local acard=final_parse(self,request,card_str)
		use.card = acard
		end
end
sgs.ai_use_priority["lol_sxls_wCard"] = sgs.ai_use_priority.Slash - 0.1



local lol_sxls_e_skill = {}
lol_sxls_e_skill.name = "lol_sxls_e"
table.insert(package_skills, lol_sxls_e_skill)
lol_sxls_e_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#lol_sxls_eCard") then return end
	if self.player:getMark("@lol_sxls_e") == 1 then return end
	local card = parse(self,request,"#lol_sxls_eCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_sxls_eCard"] = function(card,use,self,request)
		use.card = card
end
sgs.ai_use_priority["lol_sxls_eCard"] = sgs.ai_use_priority.Slash + 5.1


local lol_sxls_r_skill = {}
lol_sxls_r_skill.name = "lol_sxls_r"
table.insert(package_skills,lol_sxls_r_skill)
lol_sxls_r_skill.getTurnUseCard=function(self,inclusive,request)
	return parse(self,request,"#lol_sxls_rCard:.:")
end

sgs.ai_skill_use_func["#lol_sxls_rCard"] = function(card,use,self,request)
	local slashes = self:getCards("Slash")
	for _,e in sgs.list(self.player:getEquips())do
		for _,slash in sgs.list(AIList.new(slashes))do
			if slash:getKnownEffectiveId()==e:getKnownId()
			or table.contains(slash:getSkillNames(), e:objectName())
			or not slash:isAvailable(self.player)
			then table.removeOne(slashes,slash) end
		end
	end
	if #slashes<1 then return end
	self:sortInPlace(self.enemies, "hp")
	local cards = AIList.new(self.player:getCards("h"))
	self:sortByKeepValueInPlace(cards)
	local use_card
	for _, card in ipairs(cards) do
		if not card:isKindOf("Slash") then
			use_card = card
		end
	end
	if not use_card	 then return end
	for _,enemy in sgs.list(self.enemies)do
		local n = 0
		for _,slash in sgs.list(slashes)do
			local d = self:aiUseCard(slash)
			if d.card and d.to:contains(enemy)
			and not(self:hasEightDiagramEffect(enemy)) then
				n = n+1
				if n>=enemy:getHp() then
					use.card=final_parse(self,request,"#lol_sxls_rCard:.:")
					use.to:append(enemy)
					return
				end
			end
		end
	end
end

sgs.ai_use_priority["lol_sxls_rCard"] = sgs.ai_use_priority.Slash+0.5
sgs.ai_use_value["lol_sxls_rCard"] = 3


sgs.ai_card_priority["lol_bzll_w_skill"] = function(self, card)
	if card and card:isKindOf("Slash") and table.contains(card:getSkillNames(), "lol_bzll_w")
	then
		return 0.1
	end
end




local lol_bzll_w_skill={}
lol_bzll_w_skill.name="lol_bzll_w"
table.insert(package_skills,lol_bzll_w_skill)
lol_bzll_w_skill.getTurnUseCard=function(self,inclusive,request)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasFlag("lol_bzll_w") then return nil end
    if self.player:getMark("lol_bzll_q") == 0 then return nil end
    local cards = self.player:getHandcards()
    cards=AIList.new(cards)
    self:sortByKeepValueInPlace(cards)
	local card

	self:sortByUseValueInPlace(cards, true)

	for _,acard in ipairs(cards)  do
		if (acard:getNumber() > self.player:getMark("lol_bzll_q") )  then
			card = acard
			break
		end
	end
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if disclosed(self,id):getNumber() > self.player:getMark("lol_bzll_q") 		then
				card = disclosed(self,id)
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	local card_str = ("slash:lol_bzll_w[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = parse(self,request,card_str)

	assert(skillcard)

	return skillcard
end


local lol_bzll_e_skill = {}
lol_bzll_e_skill.name = "lol_bzll_e"
table.insert(package_skills, lol_bzll_e_skill)
lol_bzll_e_skill.getTurnUseCard=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#lol_bzll_eCard") then return end
	if self.player:getMark("@lol_bzll_e") ~= 0 then return end
	local card = parse(self,request,"#lol_bzll_eCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_bzll_eCard"] = function(card,use,self,request)
	local handcards = AIList.new(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local use_card = {}
	
	for _,c in ipairs(handcards) do
		if #use_card < 1  then
			table.insert(use_card, c:getKnownEffectiveId())
		end
	end
	if #use_card ~= 1 then return end
	
	if #use_card > 0 then
		local card_str = string.format("#lol_bzll_eCard:%s:", table.concat(use_card, "+"))
		local acard=final_parse(self,request,card_str)
		use.card = acard
		end
end


sgs.ai_skill_invoke.lol_bzll_e = function(self, data)
	local move = data:toMoveOneTime()
	local dest
	if move.from:objectName() == self.player:objectName() then dest = self.room:getCurrent()
	else dest = find_general(self,move.from)
	end
	if dest and self:isEnemy(dest) then
		return true
	end
	return false
end




local lol_bzll_r_skill={}
lol_bzll_r_skill.name="lol_bzll_r"
table.insert(package_skills,lol_bzll_r_skill)
lol_bzll_r_skill.getTurnUseCard=function(self,inclusive,request)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:getMark("lol_bzll_q") == 0 then return nil end
    if self.player:getMark("@lol_bzll_r") == 0 then return nil end
    local cards = self.player:getHandcards()
    cards=AIList.new(cards)
    self:sortByKeepValueInPlace(cards)
	local card

	self:sortByUseValueInPlace(cards, true)

	for _,acard in ipairs(cards)  do
		if (acard:getNumber() == self.player:getMark("lol_bzll_q") )  then
			card = acard
			break
		end
	end
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if disclosed(self,id):getNumber() == self.player:getMark("lol_bzll_q") 		then
				card = disclosed(self,id)
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	local card_str = ("slash:lol_bzll_r[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = parse(self,request,card_str)

	assert(skillcard)

	return skillcard
end
sgs.ai_ajustdamage_from.lol_bzll_r = function(self, from, to, card, nature)
	if card and table.contains(card:getSkillNames(), "lol_bzll_r") and to and to:distanceTo(from) >= 2
	then
		return 1
	end
end























for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
do local source=sgs.ai_skill_use['@@lol_jwyh_r'];sgs.ai_skill_use['@@lol_jwyh_r']=function(self,...)
 local wire=source(self,...);if wire==nil or wire=='.'then return wire end
 local use=AIUsePlan.new();use.card=final_parse(self,nil,wire);return use:toAnswer()
end end
