-- Source: b6025acc ai/new-ai.lua.
local known = AIValue.requireKnown
local nullable={getLord=true,getCurrent=true,getSameEquip=true,getMaxCard=true,getArmor=true,getTreasure=true,getCard=true,findLeijiTarget=true,findPlayerBySkillName=true,findPlayerToDraw=true,updatePlayers=true,updateIntention=true,setStrategyPlayerFlag=true}

-- Whether a legacy LuaSkillCard prototype parses is an engine query that is not projected.
local function old_parse(self,name,costs)
 ai_unsupported("legacy prototype presence is not projected",name)
end
local function terminal(self,wire)
 if wire=="."then return wire end
 ai_unsupported("legacy prototype presence is not projected","#luajiejiang")
end
-- sgs.ai_AOE_data has a writer only in the original-hegemony overrides.
local function aoe_truth(self)
 local h=AIHegemony.facts(self.world)
 if type(h)~="table"or type(h.original_overrides_loaded)~="boolean"then ai_unsupported("original override domain unknown","ai_AOE_data")end
 if not h.original_overrides_loaded then return false end
 ai_unsupported("legacy ai_AOE_data stack is not projected","ai_AOE_data")
end
local function complete_he(self,p)
 local cards=p:getCards("he")
 if #cards~=p:getHandcardNum()+#p:getEquips()then ai_unsupported("luafan requires complete legal foreign Spade inventory","luafan.foreign_cards")end
 return cards
end
local function first_hand(self,player,cards)
 if #cards~=player:getHandcardNum()then ai_unsupported("source first foreign hand card is undisclosed","luajiejiang2_main.first_hand")end
 return cards[1]
end
local function pile_card(player,id)
 local ai=player._room and player._room._ai
 if not ai or player~=ai.player then ai_unsupported("luaqiyi pile face is not viewer-owned","luaqiyi")end
 return ai:getKnownCardById(id)
end
local function qiyi_spec(cards)
 local red,black=true,true;local ids={}
 for _,c in ipairs(cards)do ids[#ids+1]=c:getKnownEffectiveId();red=red and c:isRed();black=black and c:isBlack()end
 return{name="jink",skill="luaqiyi",suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit,number=0,subcards=ids}
end
local function invoke_registered_callback(reg,key,...)
 local f=(reg == "ai_skill_use" and ai_skill_use or (reg == "ai_card_use" and ai_card_use or (reg == "ai_skill_invoke" and ai_skill_invoke or (reg == "ai_fill_skill" and ai_fill_skill or (reg == "ai_skill_choice" and ai_skill_choice or sgs[reg])))))and (reg == "ai_skill_use" and ai_skill_use or (reg == "ai_card_use" and ai_card_use or (reg == "ai_skill_invoke" and ai_skill_invoke or (reg == "ai_fill_skill" and ai_fill_skill or (reg == "ai_skill_choice" and ai_skill_choice or sgs[reg])))))[key];if type(f)~="function"then ai_unsupported("new shared callback unavailable",reg.."."..key)end
 local result=f(...);if AIUnsupported.is(result)then error(result,0)end;return result
end
local function global_call(name,...)
 local f=_G[name];if type(f)~="function"then ai_unsupported("new source helper unavailable",name)end
 return known(f(...),name)
end
local function source_friend(self,to,from)
 if not from or not to then return false end
 if from:objectName()==to:objectName()then return true end
 local function role(p)return p==self.player and p:getKnownRole()or self:getRoleEstimate(p)end
 local fr=role(from)
 if fr=="lord"or fr=="loyalist"then
  if known(self.world.turn_count,"turncount")<=1 and role(to)=="renegade"and from:aliveCount()>7
   or role(to)=="lord"or role(to)=="loyalist"then return true end
 end
 if fr=="rebel"and role(to)=="rebel"then return true end
 if fr=="renegade"then
  if known(self.world.turn_count,"turncount")<=1 and role(to)=="loyalist"and from:aliveCount()>7
   or role(to)=="lord"and from:aliveCount()>2 then return true end
 end
 return false
end
local luajiejiang_policy

ai_skill_choice.luajuemou = function(self, options, request)
    local choice = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	if self.player:getHp() < self.player:getMaxHp() - 1 then return ai_choice_result(("luajuemouHp"), options) end
	return ai_choice_result(("luajuemouCd"), options)
end

sgs.ai_can_damagehp.luajuemou = function(self, from, card, to)
	return not (to:isWounded() or to:getStrategyMark("luajuemou") > 0)
		and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0 and self:canLoseHp(from, card, to)
end

sgs.ai_skill_playerchosen.lualilian = function(self, targets)
	self:updatePlayers()
	self:sortInPlace(self.friends_noself, "handcard")
	local target = nil
	local n = 0
	for _, friend in ipairs(self.friends_noself) do
		if not friend:faceUp() then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not self:toTurnOver(friend, n, "lualilian") then
				target = friend
				break
			end
		end
	end
	if not target then
		if n >= 3 then
			target = self:findPlayerToDraw(false, n)
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "lualilian") and self:hasManjuanEffect(enemy) then
						target = enemy
						break
					end
				end
			end
		else
			self:sortInPlace(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if self:toTurnOver(enemy, n, "lualilian") and self:hasManjuanEffect(enemy) then
					target = enemy
					break
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "lualilian") and self:hasSkills(sgs.priority_skill, enemy) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "lualilian") then
						target = enemy
						break
					end
				end
			end
		end
	end
	return target
end

sgs.ai_playerchosen_intention.lualilian = function(self, from, to)
	local intention = 80
	if not self:toTurnOver(to, 0, "lualilian") then intention = -intention end
	self:updateIntention(from, to, intention)
end

sgs.ai_need_damaged.lualilian = function(self, attacker, player)
	if not player:hasSkill("lualilian") then return false end
	local enemies = self:getEnemies(player)
	if #enemies < 1 then return false end
	self:sortInPlace(enemies, "defense")
	for _, enemy in ipairs(enemies) do
		if player:getLostHp() < 1 and self:toTurnOver(enemy, 0, "lualilian") then
			return true
		end
	end
	local friends = self:getFriends(player, true)
	self:sortInPlace(friends, "defense")
	for _, friend in ipairs(friends) do
		if not self:toTurnOver(friend, 0, "lualilian") then return true end
	end
	return false
end

ai_skill_choice.lualilian = function(self, options, request)
    local choice = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local targets = self.room:getOtherPlayers(self.player)
	if targets:length() == 0 then return ai_choice_result((false), options) end
	if invoke_registered_callback("ai_skill_playerchosen", "lualilian", self, targets) ~= nil then
		return ai_choice_result(("luayihengturn"), options)
	end
	return ai_choice_result(("luayihengmopai"), options)
end


ai_fill_skill.lualveji_vs = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#lualveji") then return end
	if #self.enemies == 0 then return end

	if self.player:hasSkill("luawu_trs") and (self.player:getStrategyMark("@luawu_mark") > 0) then
		local good, bad = 0, 0
		local lord = self.room:getLord()
		if lord and self.player:getKnownRole() ~= "rebel" and self:isWeak(lord) then return end
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
			if global_call("getCardsNum","Analeptic", player) > 0 then
				if self:isFriend(player) then
					good = good + 1.0 / hp
				else
					bad = bad + 1.0 / hp
				end
			end
			if self:isFriend(player) then
				good = good + math.max(global_call("getCardsNum","Peach", player), 1)
			else
				bad = bad + math.max(global_call("getCardsNum","Peach", player), 1)
			end

			local lost_value = 0
			local hp = math.max(player:getHp(), 1)
			if self:isFriend(player) then
				bad = bad + (lost_value + 1) / hp
			else
				good = good + (lost_value + 1) / hp
			end
		end

		if good > bad then
			self:setStrategyPlayerFlag(self.player, "should_luawu", true)
		end
	end



	if (self.player:getHp() > 3 and self.player:getHandcardNum() > self.player:getHp())
		or (self.player:getHp() - self.player:getHandcardNum() >= 2)
		or (self.player:getHp() > 1 and self.player:getKnownRole() == "loyalist")
	then
		return old_parse(self,"#lualveji",{})
	end

	local function can_kurou_with_cb(self)
		if self.player:getHp() > 1 then return true end
		local has_save = false
		local huatuo = self.room:findPlayerBySkillName("jijiu")
		if huatuo and self:isFriend(huatuo) then
			for _, equip in sgs.qlist(huatuo:getEquips()) do
				if equip:isRed() then
					has_save = true
					break
				end
			end
			if not has_save then has_save = (huatuo:getHandcardNum() > 3) end
		end
		if has_save then return true end
		local handang = self.room:findPlayerBySkillName("nosjiefan")
		if handang and self:isFriend(handang) and global_call("getCardsNum","Slash", handang, self.player) >= 1 then return true end
		return false
	end

	local slash = self:getEvaluationCard("slash")
	
	if (self.player:hasWeapon("crossbow") or self:getCardsNum("Crossbow") > 0) or self:getCardsNum("Slash") > 1 then
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and self:slashIsEffective(slash, enemy)
				and self:isGoodTarget(enemy, self.enemies) and not self:slashProhibit(slash, enemy) and can_kurou_with_cb(self) then
				return old_parse(self,"#lualveji",{})
			end
		end
	end

	if self.player:getHp() <= 1 and self:getCardsNum("Analeptic") + self:getCardsNum("Peach") > 1 then
		return old_parse(self,"#lualveji",{})
	end
end

ai_card_use["#lualveji"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_priority["lualveji"] = 6.7


sgs.ai_skill_askforag["lualveji"] = function(self, card_ids)
	if #card_ids == 1 then return card_ids[1] end
	local cards = {}
	local x = 0
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, self:getKnownCardById(card_id))
		if (self:getKnownCardById(card_id)):isBlack() then
			x = x + 1
		end
	end
	if x >= 2 then
		self:setStrategyPlayerFlag(self.player, "AI_doInvoke_luawu", true)
	end
	if #card_ids > 0 then return self:askForAG(card_ids, false, "dummyreason") end
	return card_ids[1]
end

ai_skill_choice.lualveji = function(self, options, request)
    local choice = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	if self.player:hasFlag("should_luawu") then
		if self.player:hasFlag("lualveji_vsblack") and self.player:hasFlag("AI_doInvoke_luawu") then
			return ai_choice_result(("lualvejiFZ"), options)
		end
	end
	return ai_choice_result(("lualvejiQZ"), options)
end




ai_fill_skill.luawu_trs = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyMark("@luawu_mark") <= 0 then return end
	if self.room:getMode() == "_mini_13" then return old_parse(self,"#luawu",{}) end
	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.player:getKnownRole() ~= "rebel" and self:isWeak(lord) then return end
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
		if global_call("getCardsNum","Analeptic", player) > 0 then
			if self:isFriend(player) then
				good = good + 1.0 / hp
			else
				bad = bad + 1.0 / hp
			end
		end
		if self:isFriend(player) then
			good = good + math.max(global_call("getCardsNum","Peach", player), 1)
		else
			bad = bad + math.max(global_call("getCardsNum","Peach", player), 1)
		end

		local lost_value = 0
		local hp = math.max(player:getHp(), 1)
		if self:isFriend(player) then
			bad = bad + (lost_value + 1) / hp
		else
			good = good + (lost_value + 1) / hp
		end
	end

	if (good > bad) and ((self.player:hasFlag("should_luawu") and self.player:hasFlag("AI_doInvoke_luawu")) or (not self.player:hasSkill("lualveji_vs"))) then
		return old_parse(self,"#luawu",{})
	end
end

ai_card_use["#luawu"] = function(self, card, use, request)
	use.card = card
end

sgs.dynamic_value.damage_card["#luawu"] = true


sgs.ai_use_priority["luawu"] = 6.8


sgs.ai_skill_playerchosen.luafan = function(self, targets)
	local mode = self.room:getMode()
	if mode:find("_mini_17") or mode:find("_mini_19") or mode:find("_mini_20") or mode:find("_mini_26") then
		local players = self.room:getAllPlayers()
		for _, aplayer in sgs.qlist(players) do
			if aplayer:getState() ~= "robot" then
				return aplayer
			end
		end
	end

	self:updatePlayers()
	return self:findLeijiTarget(self.player, 100, nil, -1)
end

-- shared immutable alias ai_playerchosen_intention.luafan -> ai_playerchosen_intention.leiji
function SmartAIView:SlashCanIgnoreJink(from, to, slash)
	from = from or self.room:getCurrent()
	to = to or self.player
	slash = slash or self:getEvaluationCard("slash")
	return not known(sgs.isJinkAvailable(from,to,slash),"isJinkAvailable") or from:hasSkill("wanglie")
end

function sgs.ai_slash_prohibit.luafan(self, from, to, card)
	local has_black_card = false
	for _, c in ipairs(sgs.QList2Table(complete_he(self,to))) do
		if c:getSuit() == sgs.Card_Spade then
			has_black_card = true
		end
	end

	if self:isFriend(to, from) and has_black_card then return false end
	if to:hasFlag("QianxiTarget") and (not self:hasEightDiagramEffect(to) or self.player:hasWeapon("qinggang_sword")) then return false end
	if from:hasSkill("tieji") then return false end
	local hcard = to:getHandcardNum()
	if from:hasSkill("liegong") and (hcard >= from:getHp() or hcard <= from:getAttackRange()) then return false end
	if from:hasSkill("kofliegong") and hcard >= from:getHp() then return false end
	if self:SlashCanIgnoreJink(from, to) then return false end

	if not self:getCardId("Jink", to) then
		if self:hasEightDiagramEffect(to) then
			if self:ignoreArmor(from, to) then
				return false
			else
				return true
			end
		else
			return false
		end
	else
		return true
	end

	if from:getKnownRole() == "rebel" and to:isLord() then
		local other_rebel
		for _, player in sgs.qlist(self.room:getOtherPlayers(from)) do
			if self:getRoleEstimate(player)== "rebel" or sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				other_rebel = player
				break
			end
		end
		if not other_rebel and ((from:getHp() >= 4 and (global_call("getCardsNum","Peach", from, self.player) > 0 or from:hasSkills("nosganglie|vsnosganglie"))) or from:hasSkill("hongyan")) then
			return false
		end
	end
	if self:getKnownCard(to, from, "Jink", true) >= 1 or (self:hasSuit("spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if self:hasEightDiagramEffect(to) and not self:ignoreArmor(from, to) then return true end
	if to:getTreasure() and to:getPile("wooden_ox"):length() > 1 then return true end
end

-- shared immutable alias ai_cardneed.luafan -> ai_cardneed.leiji
sgs.ai_use_revises.luafan = function(self, card, use)
	if card:isKindOf("EquipCard")
		and card:getSuit() == sgs.Card_Spade and card:getNumber() <= 9 and card:getNumber() >= 2 and self:hasSkills(sgs.wizard_skill, self.player)
	then
		local same = self:getSameEquip(card)
		if same and same:getSuit() == sgs.Card_Spade and same:getNumber() <= 9 and same:getNumber() >= 2
		then
			return false
		end
	end
end

sgs.ai_need_damaged.luaxumou = function(self, attacker, player)
	if not player:hasSkill("chanyuan") and player:hasSkill("luaxumou") and player:getStrategyMark("luaxumou") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() > 2 or player:getHp() == 2 and (player:faceUp() or player:hasSkill("guixin") or player:hasSkill("toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end

function sgs.ai_slash_prohibit.luaxumou(self, from, to, card)
	if known(self.world.turn_count,"turncount") <= 1 and to:isLord() and to:getHp() >= 2 and not self:isFriend(to, from) then return true end
end

sgs.ai_view_as.luaqiyi = function(card, player, card_place)
	local usable_cards = sgs.QList2Table(player:getCards("h"))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(usable_cards, pile_card(player,id))
		end
	end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()

	local two_cards,materials = {},{}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == card:getSuit() and #two_cards < 2 then
			
			table.insert(two_cards, c:getKnownEffectiveId());materials[#materials+1]=c

		end
	end


	if #two_cards == 2 and not card:isKindOf("Jink") then
		return qiyi_spec(materials)
	end
end



sgs.ai_skill_cardask["@luaguidao"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			all_cards:prepend(self:getKnownCardById(id))
		end
	end

	if all_cards:isEmpty() then return "." end

	local needTokeep = judge.card:getSuit() ~= sgs.Card_Spade and
		((not self.player:hasSkill("leiji") and not self.player:hasSkill("olleiji")) or judge.card:getSuit() ~= sgs.Card_Club)
		and aoe_truth(self) and self:playerGetRound(judge.who) < self:playerGetRound(self.player) and
		self:findLeijiTarget(self.player, 50)
		and (self:getCardsNum("Jink") > 0 or self:hasEightDiagramEffect()) and self:getFinalRetrial() == 1

	if not needTokeep then
		local who = judge.who
		if who:getPhase() == sgs.Player_Judge and not who:getJudgingArea():isEmpty() and who:containsTrick("lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if self.player:hasSkill("nosleiji") then keptspade = 2 end
		if self.player:hasSkill("luafan") then keptspade = 2 end
		if self.player:hasSkill("leiji") then keptblack = 2 end
		if self.player:hasSkill("olleiji") then keptblack = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not card:hasFlag("using") then
			if card:getSuit() == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptblack == 1 and not self.player:hasSkill("olleiji") then return "." end
	if keptspade == 1 and not self.player:hasSkill("leiji") then return "." end
	if keptspade == 1 and not self.player:hasSkill("luafan") then return "." end

	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			self:sortByUseValueInPlace(cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "$" .. cards[1]:getKnownId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(self:getKnownCardById(card_id)) then
		local card = self:getKnownCardById(card_id)
		return "$" .. card_id
	end

	return "."
end
function sgs.ai_cardneed.luaguidao(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and
					not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club and self:hasSuit("club", true, to)
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart and self:hasSuit("heart", true, to)
			end
		end
	end
	if self:getFinalRetrial(to) == 1 then
		if to:hasSkill("nosleiji") then
			return card:getSuit() == sgs.Card_Spade
		end
		if to:hasSkill("leiji") then
			return card:isBlack()
		end
		if to:hasSkill("olleiji") then
			return card:isBlack()
		end
		if to:hasSkill("luafan") then
			return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9
		end
	end
end

sgs.ai_useto_revises.luaguidao = function(self, card, use, p)
	if card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")
	then
		if self:isFriend(p) and p:getCardCount() > 2
		then
			use.card = card
			return
		end
		return false
	end
end
sgs.wizard_harm_skill =  sgs.wizard_harm_skill .. "|luaguidao"
sgs.wizard_skill =  sgs.wizard_skill .. "|luaguidao"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|luaguidao"


ai_skill_invoke.luajiejiang = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if #self.enemies == 0 then
		return (false) or false
	end
	local targets = self.room:getOtherPlayers(self.player)
	local cardstr = luajiejiang_policy(self, "@luajiejiang")
	if (invoke_registered_callback("ai_skill_playerchosen", "luajiejiang", self, targets) ~= nil) or (cardstr:match("->")) then
		return (true) or false
	end
	return (false) or false
end

sgs.ai_skill_playerchosen.luajiejiang = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	self:updatePlayers()
	self:sortInPlace(self.friends_noself, "handcard")
	local target = nil
	local n = 0

	self:sortInPlace(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if self:toTurnOver(enemy, n, "luajiejiang") and self:hasManjuanEffect(enemy) then
			target = enemy
			break
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if self:toTurnOver(enemy, n, "luajiejiang") and self:hasSkills(sgs.priority_skill, enemy) then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if self:toTurnOver(enemy, n, "luajiejiang") then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not friend:faceUp() then
				target = friend
				break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not self:toTurnOver(friend, n, "luajiejiang") then
				target = friend
				break
			end
		end
	end

	return nil
end

luajiejiang_policy = function(self, prompt)
	self:sortInPlace(self.enemies, "handcard_defense")
	local tuxi_mark = 2
	local targets = {}

	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	local luxun = self.room:findPlayerBySkillName("lianying") or self.room:findPlayerBySkillName("noslianying")
	local dengai = self.room:findPlayerBySkillName("tuntian")
	local jiangwei = self.room:findPlayerBySkillName("zhiji")
	local zhijiangwei = self.room:findPlayerBySkillName("beifa")

	local add_player = function(player, isfriend)
		if player:getHandcardNum() == 0 or player:objectName() == self.player:objectName() then return #targets end
		if self:objectiveLevel(player) == 0 and player:isLord() and known(self:getRoleCounts().rebel,"rebel count") > 1 then
			return #
				targets
		end

		local f = false
		for _, c in ipairs(targets) do
			if c == player:objectName() then
				f = true
				break
			end
		end

		if not f then table.insert(targets, player:objectName()) end

		if isfriend and isfriend == 1 then
			self:setStrategyPlayerFlag(self.player, "luajiejiang_isfriend_" .. player:objectName(), true)
		end
		return #targets
	end

	local parseTuxiCard = function()
		if #targets == 0 then return "." end
		local s = table.concat(targets, "+")
		return "#luajiejiang:.:->" .. s
	end

	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and known(self.world.turn_count,"turncount") <= 1 and not lord:isNude() then
		if add_player(lord) == tuxi_mark then return parseTuxiCard() end
	end

	for _, friend in ipairs(self.friends) do
		if friend:getJudgingArea():length() > 0 then
			local judges = friend:getJudgingArea()
			for _, judge in sgs.qlist(judges) do
				local card = self:getKnownCardById(judge:getKnownEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					if add_player(friend, 1) == tuxi_mark then return parseTuxiCard() end
				end
			end
		end
	end

	if jiangwei and self:isFriend(jiangwei) and jiangwei:getStrategyMark("zhiji") == 0 and jiangwei:getHandcardNum() == 1
		and self:getEnemyNumBySeat(self.player, jiangwei) <= (jiangwei:getHp() >= 3 and 1 or 0) then
		if add_player(jiangwei, 1) == tuxi_mark then return parseTuxiCard() end
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player, dengai) == 0)
		and dengai:hasSkill("zaoxian") and dengai:getStrategyMark("zaoxian") == 0 and dengai:getPile("field"):length() == 2 and add_player(dengai, 1) == tuxi_mark then
		return parseTuxiCard()
	end

	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, zhugeliang) > 0 then
		if zhugeliang:getHp() <= 2 then
			if add_player(zhugeliang, 1) == tuxi_mark then return parseTuxiCard() end
		else
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), zhugeliang:objectName())
			local cards = sgs.QList2Table(zhugeliang:getHandcards())
			if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
				if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
					if add_player(zhugeliang, 1) == tuxi_mark then return parseTuxiCard() end
				end
			end
		end
	end

	if luxun and self:isFriend(luxun) and luxun:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, luxun) > 0 then
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), luxun:objectName())
		local cards = sgs.QList2Table(luxun:getHandcards())
		if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
			if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
				if add_player(luxun, 1) == tuxi_mark then return parseTuxiCard() end
			end
		end
	end

	if zhijiangwei and self:isFriend(zhijiangwei) and zhijiangwei:getHandcardNum() == 1 and
		self:getEnemyNumBySeat(self.player, zhijiangwei) <= (zhijiangwei:getHp() >= 3 and 1 or 0) then
		local isGood
		for _, enemy in ipairs(self.enemies) do
			local def = self:getDefenseSlash(enemy)
			local slash = self:getEvaluationCard("slash")
			
			local eff = self:slashIsEffective(slash, enemy, zhijiangwei) and
				self:isGoodTarget(enemy, self.enemies, slash)
			if zhijiangwei:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy, zhijiangwei) and eff and def < 4 then
				isGood = true
			end
		end
		if isGood and add_player(zhijiangwei, 1) == tuxi_mark then return parseTuxiCard() end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local cards = sgs.QList2Table(p:getHandcards())
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), p:objectName())
		for _, card in ipairs(cards) do
			if (card:hasFlag("visible") or card:hasFlag(flag)) and (card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic")) then
				if add_player(p) == tuxi_mark then return parseTuxiCard() end
			end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		if p:hasSkills("jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
			if add_player(p) == tuxi_mark then return parseTuxiCard() end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local x = p:getHandcardNum()
		local good_target = true
		if x == 1 and self:needKongcheng(p) then good_target = false end
		if x >= 2 and self:hasTuntianEffect(p, true) then good_target = false end
		if good_target and add_player(p) == tuxi_mark then return parseTuxiCard() end
	end


	if luxun and add_player(luxun, (self:isFriend(luxun) and 1 or nil)) == tuxi_mark then
		return parseTuxiCard()
	end

	if dengai and self:isFriend(dengai) and dengai:hasSkill("zaoxian") and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player, dengai) == 0) and add_player(dengai, 1) == tuxi_mark then
		return parseTuxiCard()
	end

	local others = self.room:getOtherPlayers(self.player)
	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not (self:hasTuntianEffect(other, true)) and add_player(other) == tuxi_mark then
			return parseTuxiCard()
		end
	end

	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not (self:hasTuntianEffect(other, true)) and math.random(0, 5) <= 1 and not self:hasSkills("qiaobian") then
			add_player(other)
		end
	end

	return parseTuxiCard()
end

sgs.drawpeach_skill = sgs.drawpeach_skill .. "|luajiejiang"

sgs.ai_skill_cardchosen["luajiejiang2_main"] = function(self, who, flags)
	local equipments = sgs.QList2Table(who:getEquips())
	equipments = sgs.reverse(equipments)
	local handcards = sgs.QList2Table(who:getHandcards())
	if self:isFriend(who) then

		if flags:match("j") and not who:containsTrick("YanxiaoCard") and not (who:hasSkill("qiaobian") and who:getHandcardNum() > 0) then
			local tricks = who:getCards("j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") then
					lightning = trick:getKnownEffectiveId()
				elseif trick:isKindOf("Indulgence") then
					indulgence = trick:getKnownEffectiveId()
				elseif not trick:isKindOf("Disaster") then
					supply_shortage = trick:getKnownEffectiveId()
				end
			end

			if self:hasWizard(self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if who:getHp() < who:getHandcardNum() then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end

		if who:getPile("wooden_ox"):length() > 0 then
			for _, e in ipairs(equipments) do
				if e:isKindOf("WoodenOx") then
					table.removeOne(equipments, e)
				end
			end
		end

		if who:hasArmorEffect("silver_lion") and who:isWounded() then
			return who:getArmor()
		end
		if who:getEquips():length() > 0 then
			if who:getHandcardNum() > 2 or (who:getHandcardNum() > 0 and who:getPile("wooden_ox"):length() > 0) then
				return first_hand(self,who,handcards)
			else
				return equipments[1]
			end
		end
	end
	return nil
end



ai_fill_skill.luamouce = function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#luamouce") then
		return old_parse(self,"#luamouce",{})
	end
end

ai_card_use["#luamouce"] = function(self, card, use, request)
	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	local target = nil
	for _, enemy in ipairs(self.enemies) do
		if enemy:isWounded() and self.player:canDiscard(enemy, "hej") and self:doDisCard(enemy, "hej") and not self:hasZhaxiangEffect(enemy) then
			target = enemy
			break
		end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority["luamouce"] = 7
sgs.ai_use_value["luamouce"] = 7
sgs.ai_card_intention["luamouce"] = 80



ai_skill_invoke.luaJC = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:isLord() then return (false) or false end
	if self:getCardsNum("Peach") > 0 then
		return (false) or false
	end
	for _, friend in ipairs(self.friends_noself) do
		if global_call("getCardsNum","Peach", friend) > 0 then
			return (false) or false
		end
	end
	return (true) or false
end




sgs.ai_skill_playerchosen["ask_1"] = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target     = self:findPlayerToDraw(false, 2)
	if target then
		return target
	end
	return targetlist[1]
end

sgs.ai_skill_playerchosen["ask_2"] = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local lord       = self.room:getLord()
	if lord and self:isEnemy(lord) then
		return lord
	end
	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")

	if #self.enemies > 0 then
		return self.enemies[1]
	end
	return targetlist[1]
end
function sgs.ai_cardneed.luaqinglong(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return card:isKindOf("Blade") or (isCard("Slash", card, to) and self:getKnownCard(to, "Slash", true) == 0)
	end
end


function sgs.ai_armor_value.luaqinglong(player, self, card)
	if card and card:isKindOf("Blade") then return 4 end
end

sgs.ai_use_revises.luaqinglong = function(self, card, use)
	if card and card:isKindOf("Weapon")
	then
		local same = self:getSameEquip(card)
		if same and same:isKindOf("Blade")
		then
			return false
		end
	end
end


ai_skill_invoke["@luaqibing"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	local card = use.card
	if card:isKindOf("EquipCard") then
		return (false) or false
	end
	return (true) or false
end

ai_skill_invoke["luaqibing"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return (".") or false end
	if target:hasArmorEffect("silver_lion") then return (".") or false end


	return (true) or false
end

sgs.ai_ajustdamage_from.luaqibing = function(self, from, to, card, nature)
	if from:getPile("luaqibingcards"):length() > 0 and not source_friend(self,to,from) and card and card:isKindOf("Slash")
	then
		return 1
	end
end
-- shared immutable alias ai_cardneed.luaqibing -> ai_cardneed.slash
ai_skill_invoke["luazhenshe"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return (".") or false end
	if target:hasArmorEffect("silver_lion") then return (".") or false end

	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local enemy_max_card = self:getMaxCard(target)
	local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
	if (max_point > enemy_max_point) or target:isKongcheng() then
		return (true) or false
	end
	if self.player:getLostHp() + 1 >= 2 or not self.player:faceUp() then
		return (true) or false
	end
	return (false) or false
end

-- shared immutable alias ai_cardneed.luazhenshe -> ai_cardneed.bignumber
-- shared immutable alias ai_need_damaged.luajilue -> ai_need_damaged.fangzhu
-- shared immutable alias ai_can_damagehp.luajilue -> ai_can_damagehp.jieming
ai_skill_choice.luajilue = function(self, options, request)
    local choice = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local context=self:getDecisionContext()
	local targets = self.room:getOtherPlayers(self.player)
	if (invoke_registered_callback("ai_skill_playerchosen", "fangzhu", self, targets) ~= nil) then
		return ai_choice_result(("c3"), options)
	end
	if (invoke_registered_callback("ai_skill_playerchosen", "jieming", self, targets) ~= nil) then
		return ai_choice_result(("c2"), options)
	end

	local damage=known(context.damage,"CurrentDamageStruct")
	if (invoke_registered_callback("ai_skill_invoke", "fankui", self, self:inquiryInput("skill_invoke","fankui",{player=damage.from}))) then
		return ai_choice_result(("c1"), options)
	end
	return ai_choice_result(("c4"), options)
end



ai_fill_skill.luahuntian = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luahuntian") then return end
	if #self.enemies < 1 then return end
	return old_parse(self,"#luahuntian",{})
end

ai_card_use["#luahuntian"] = function(self, card, use, request)
	local targets = sgs.SPlayerList()
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			targets:append(enemy)
		end
	end
	local needed = {}
	for _, acard in ipairs(cards) do
		if acard:getSuit() == sgs.Card_Spade and #needed < 5 then
			table.insert(needed, acard:getKnownEffectiveId())
			if #needed == 5 then
				break
			end
		end
	end
	if targets and needed and #needed == 5 then
		use.card = old_parse(self,"#luahuntian",needed)
		use.to = targets
		return
	end
end

sgs.ai_use_value["luahuntian"]       = 10
sgs.ai_use_priority["luahuntian"]    = 9
sgs.ai_card_intention["luahuntian"]  = 60


ai_skill_invoke["luajiaodi"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

ai_fill_skill.luafentian = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyHasUsed("#luafentian") then return end
	if #self.enemies < 1 then return end
	if self.player:getStrategyMark("@fentian_mark") == 0 then return end
	return old_parse(self,"#luafentian",{})
end

ai_card_use["#luafentian"] = function(self, card, use, request)
	local targets = sgs.SPlayerList()
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			targets:append(enemy)
		end
	end
	local needed = {}
	for _, acard in ipairs(cards) do
		if acard:getSuit() == sgs.Card_Spade and #needed < 1 then
			table.insert(needed, acard:getKnownEffectiveId())
			if #needed == 1 then
				break
			end
		end
	end
	if targets and needed and #needed == 1 then
		use.card = old_parse(self,"#luafentian",needed)
		use.to = targets
		return
	end
end

sgs.ai_use_value["luafentian"]       = 10
sgs.ai_use_priority["luafentian"]    = 9
sgs.ai_card_intention["luafentian"]  = 60


sgs.ai_skill_playerchosen["@luageipai2"] = function(self, targets)
	return self.player
end


ai_fill_skill.luajice = function(self, options, request)
    local inclusive = options and options.inclusive

	if not self.player:getStrategyHasUsed("#luajice") and not self.player:getPile("Plianji"):isEmpty() then
		return old_parse(self,"#luajice",{})
	end
end

ai_card_use["#luajice"] = function(self, card, use, request)
	self:updatePlayers()
	self:sortInPlace(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	local target = nil
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:doDisCard(enemy, "h", true) then
			target = enemy
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and self:doDisCard(enemy, "h", true)  then
				target = enemy
			end
		end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority["luajice"] = 7
sgs.ai_use_value["luajice"] = 7
sgs.ai_card_intention["luajice"] = 80

ai_skill_invoke["lualianji"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

ai_skill_use["@@luajiejiang"]=function(self, prompt, request)return terminal(self,luajiejiang_policy(self,prompt))end

-- Same-closure aliases are admitted only by the native immutable identity snapshot.
if ai_audited_aliases then
 for _,row in ipairs{
  {"ai_playerchosen_intention","luafan","leiji",1},
  {"ai_cardneed","luafan","leiji",3},
  {"ai_cardneed","luaqibing","slash",3},
  {"ai_cardneed","luazhenshe","bignumber",3},
  {"ai_need_damaged","luajilue","fangzhu",1},
  {"ai_can_damagehp","luajilue","jieming",1},
 }do ai_audited_aliases.register{id=row[1].."."..row[2],registry=row[1],path={row[2]},canonical_registry=row[1],canonical_path={row[3]},self_index=row[4],defer_canonical=true}end
end
