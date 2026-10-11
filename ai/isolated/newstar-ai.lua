-- Fixed donor newstar-ai.lua, b6025acc983331337614289d8cac79b078c003af.
-- Source ordering is retained. Native authority is bound only after cost selection.
local function known(value, label)
    if AIUnsupported and AIUnsupported.is and AIUnsupported.is(value) then error(value,0) end
    if value == nil then ai_unsupported("newstar requires "..label,"newstar") end
    return value
end
local function q(object, method, ...)
    if not object or type(object[method])~="function" then ai_unsupported("newstar requires "..method,"newstar") end
    return known(object[method](object,...),method)
end
local function visible_card(self,id)
    return known(self:getKnownCardById(id),"lawfully disclosed card "..tostring(id))
end
local function proposal(name,skill,card)
    return {name=name,skill=skill,suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={q(card,"getEffectiveId")}}
end
local function convert(self,skill,class,name,card,request)
    return q(self,"bindTurnConversion",skill,class,proposal(name,skill,card),request)
end
local function skill_answer(self,skill,class,id)
    local use=AIUsePlan.new()
    use.card=q(self,"bindSkillCard",skill,{id},nil,nil,class)
    return use:toAnswer()
end
local function context_damage(self,key)
    local context=self.request and self.request.options and self.request.options.context
    local row=context and context.newstar and context.newstar[key]
    if type(row)~="table" then ai_unsupported("request-scoped damage participants missing",key) end
    local result={}
    for _,field in ipairs(key=="juece_damage" and {"from","to"} or {"to"}) do
        local name=row[field]
        if name~=false then
            if type(name)~="string" then ai_unsupported("damage participant missing",key.."."..field) end
            result[field]=known(self.room:findPlayerByObjectName(name),"damage participant")
        end
    end
    return result
end
-- The donor reads all hands but only consumes one globally visible hand card.
-- Public hand count plus the legal known-card view gives the same branch without
-- disclosing the other hands or treating viewer-specific visibility as global.
local function visible_single_hand(self,player)
    local cards={}
    if q(player,"getHandcardNum")==1 then
        for _,card in ipairs(q(self,"getKnownCards",player,self.player,"h")) do
            if q(card,"hasFlag","visible") then cards[1]=card;break end
        end
    end
    return cards
end
local function nengchen_preview(self,material)
    if type(ai_evaluate_nengchen_preview)~="function" then ai_unsupported("Nengchen native preview missing","LuaNengchen") end
    local row=ai_evaluate_nengchen_preview(q(material,"getEffectiveId"))
    if type(row)~="table" or row.error then ai_unsupported(type(row)=="table" and row.error or "invalid Nengchen preview","LuaNengchen") end
    for _,key in ipairs({"name","class_name","is_iron_chain","limited_use_hand","available_checked","estimated"}) do known(row[key],"Nengchen "..key) end
    if row.available_checked~=not row.limited_use_hand then
        ai_unsupported("Nengchen availability query did not preserve the limitation short circuit","LuaNengchen")
    end
    if row.available_checked then known(row.available,"Nengchen availability") end
    if row.estimated then
        self:useKnowledgeEstimate({value=row.name,status="estimate",basis="newstar.nengchen_last_public_declaration_hidden_current_face"},"LuaNengchen")
    end
    return row
end
-- LuaSkillCard::toString omits m_skillName. Preserve both its exact policy
-- printing and strategy identity while changing the one source-mutated field.
local function fanjian_skill(self,card)
    local authority=q(card,"getAuthorityCard")
    if authority==card or type(rawget(card,"toCardSpec"))~="function" then
        ai_unsupported("Fanjian mutation requires a separate policy wrapper","LuaFanjian")
    end
    local row=known(rawget(card,"_view"),"Fanjian policy descriptor")
    if row==rawget(authority,"_view") then ai_unsupported("Fanjian policy aliases authority storage","LuaFanjian") end
    local names={}
    for i,name in ipairs(q(card,"getSkillNames")) do names[i]=name end
    names[math.max(1,#names)]="LuaFanjian"
    -- This is the policy factory's detached descriptor. Its toCardSpec closure
    -- still delegates to the untouched authority descriptor, including costs.
    row.skill_name,row.skill_names="LuaFanjian",names
    return card
end

--星曹操
sgs.ai_skill_choice["LuaJianxiong"] = function(self, choices, data)
	local obtain = getChoice(choices, "LuaJianxiongobtain")
	local draw = getChoice(choices, "LuaJianxiongdraw")
	local damage = data:toDamage()
	if not damage.card then return draw end
	if q(damage.card,"isKindOf","Slash") and not self:hasCrossbowEffect() and self:getCardsNum("Slash") > 0 then return draw end
	if self:isWeak() and (self:getCardsNum("Slash") > 0 or not q(damage.card,"isKindOf","Slash") or q(self.player,"getHandcardNum") <= q(self.player,"getHp")) then
		return
			draw
	end
	if damage.card and q(damage.card,"isKindOf","AOE") and obtain then
		return obtain
	end
	if q(self.player,"getLostHp") > 1 then
		return draw
	end
	if obtain then
		return obtain
	end
	return "cancel"
end

sgs.ai_target_revises.LuaJianxiong = function(to, card, self)
	if q(card,"isDamageCard")
		and not self:isFriend(to)
		and q(card,"subcardsLength") > 0
	then
		for _, id in sgs.list(card:getSubcards()) do
			if isCard("Peach,Analeptic", visible_card(self,id), to)
			then
				return true
			end
		end
	end
end

sgs.ai_can_damagehp.LuaJianxiong = function(self, from, card, to)
	if from and q(to,"getHp") + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return (card and (q(card,"isKindOf","Duel") or q(card,"isKindOf","AOE"))) or q(to,"getLostHp") > 2
	end
end

sgs.ai_fill_skill.LuaNengchen = function(self, inclusive, request)
	if not q(self.player,"getStrategyFlag","jx") then return end
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(usable_cards, visible_card(self,id))
		end
	end
	self:sortByUseValue(usable_cards, true)
	local cards = {}
	for _, c in ipairs(usable_cards) do
        local preview=nengchen_preview(self,c)
        if not preview.limited_use_hand and preview.available and not q(c,"isKindOf","Peach") and not (q(c,"isKindOf","Jink") and self:getCardsNum("Jink") < 3) and not preview.is_iron_chain then
            return convert(self,"LuaNengchen",preview.class_name,preview.name,c,request)
        end
	end
end

--星郭嘉
sgs.ai_skill_invoke.LuaXinyiji = function(self, data)
	return true
end


sgs.ai_skill_use["@@LuaXinyiji"] = function(self, prompt)
	self:updatePlayers()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local suit = {}
	for _, card_id in sgs.qlist(self.player:getPile("ji")) do
		local card = visible_card(self,card_id)
		if not table.contains(suit, q(card,"getSuitString")) then
			table.insert(suit, q(card,"getSuitString"))
		end
	end
	for _, c in ipairs(cards) do
		if not table.contains(suit, q(c,"getSuitString")) then
			return skill_answer(self,"LuaXinyiji","#LuaXinyiji",q(c,"getEffectiveId"))
		end
	end

	return "."
end

sgs.ai_need_damaged.LuaXinyiji = function(self, attacker, player)
	if not q(player,"hasSkill","LuaXinyiji") then return end

	local friends = {}
	for _, ap in sgs.list(self.room:getAlivePlayers()) do
		if self:isFriend(ap, player) then
			table.insert(friends, ap)
		end
	end
	self:sort(friends, "hp")

	if #friends > 0 and q(friends[1],"objectName") == q(player,"objectName") and self:isWeak(player) and getCardsNum("Peach", player, (attacker or self.player)) == 0 then return false end

	return q(player,"getHp") > 2 and q(self.room,"getTurnCount") > 2 and not self:isWeak(player) and q(player,"getHandcardNum") >= 2
end

sgs.ai_can_damagehp.LuaXinyiji = function(self, from, card, to)
	return q(to,"getHp") + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|LuaXinyiji"

sgs.ai_skill_use["@@LuaJuece"] = function(self, prompt)
	local damage = context_damage(self,"juece_damage")
	self:updatePlayers()
	local cards = {}
	if self.player:getPile("ji"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("ji")) do
			table.insert(cards, visible_card(self,id))
		end
	end
	for _, c in ipairs(cards) do
		if damage.to and self:isFriend(damage.to) and self:doDisCard(damage.from,"he") and self:canDraw(damage.to, self.player) then
			if q(c,"getSuit") == sgs.Card_Club then
				return skill_answer(self,"LuaJuece","#LuaJuece",q(c,"getEffectiveId"))
			end
		end
		if damage.from and self:isEnemy(damage.from) then
			if self:objectiveLevel(damage.from) > 3 and not self:cantbeHurt(damage.from) and self:damageIsEffective(damage.from) then
				if q(c,"getSuit") == sgs.Card_Heart then
					return skill_answer(self,"LuaJuece","#LuaJuece",q(c,"getEffectiveId"))
				end
			end
			if self:toTurnOver(damage.from, q(damage.from,"getLostHp") + 1, "LuaJuece") then
				if q(c,"getSuit") == sgs.Card_Diamond then
					return skill_answer(self,"LuaJuece","#LuaJuece",q(c,"getEffectiveId"))
				end
			end
			if self:isEnemy(damage.from) then
				if self:doDisCard(damage.from,"he", true)  then
					if q(c,"getSuit") == sgs.Card_Spade then
						return skill_answer(self,"LuaJuece","#LuaJuece",q(c,"getEffectiveId"))
					end
				end
			end
		end
		if damage.to and self:isFriend(damage.to) and self:needToLoseHp(damage.to, self.player) then
			if q(c,"getSuit") == sgs.Card_Heart then
				return skill_answer(self,"LuaJuece","#LuaJuece",q(c,"getEffectiveId"))
			end
		end
	end

	return "."
end

--星司马懿
sgs.ai_skill_cardask["@LuaGuizha-card"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return "." end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not q(card,"hasFlag","using") then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			self:sortByUseValue(cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "$" .. q(cards[1],"getId")
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(visible_card(self,card_id)) then
		local card = visible_card(self,card_id)
		return "$" .. card_id
	end

	return "."
end

function sgs.ai_cardneed.LuaGuizha(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if q(player,"containsTrick","lightning") and not q(player,"containsTrick","YanxiaoCard") then
				return q(card,"getSuit") == sgs.Card_Spade and q(card,"getNumber") >= 2 and q(card,"getNumber") <= 9 and
					not q(self,"hasSkills","hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return q(card,"getSuit") == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return q(card,"getSuit") == sgs.Card_Heart
			end
		end
	end
end

sgs.LuaGuizha_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|LuaGuizha"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .."|LuaGuizha"

sgs.ai_skill_invoke.LuaQuanbian = function(self, data)
	local target = data:toPlayer()
	local damage = context_damage(self,"current_damage")
	if sgs.ai_need_damaged.LuaQuanbian(self, target) then return true end

	if self:isFriend(target) then
		if self:getOverflow(target) > 2 then return true end
		return q(self.player,"objectName") == q(damage.to,"objectName") and self:doDisCard(target,"he", true) or self:doDisCard(target,"e", true)
	end
	if self:isEnemy(target) then
		return q(self.player,"objectName") == q(damage.to,"objectName") and self:doDisCard(target,"he", true) or self:doDisCard(target,"e", true)
	end
	return true
end
sgs.ai_skill_cardchosen.LuaQuanbian = function(self, who, flags)
	local suit = sgs.ai_need_damaged.LuaQuanbian(self, who)
	if not suit then return nil end

	local cards = sgs.QList2Table(who:getEquips())
	local handcards = visible_single_hand(self,who)
	if #handcards == 1 and q(handcards[1],"hasFlag","visible") then table.insert(cards, handcards[1]) end

	for i = 1, #cards, 1 do
		if (q(cards[i],"getSuit") == suit and suit ~= sgs.Card_Spade) or
			(q(cards[i],"getSuit") == suit and suit == sgs.Card_Spade and q(cards[i],"getNumber") >= 2 and q(cards[i],"getNumber") <= 9) then
			return cards[i]
		end
	end
	return nil
end

sgs.ai_can_damagehp.LuaQuanbian = function(self, from, card, to)
	if from and q(to,"getHp") + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from) and self:isWeak(from) and q(from,"getCardCount") > 0
	end
end

sgs.ai_need_damaged.LuaQuanbian = function(self, attacker)
	if not q(self.player,"hasSkill","LuaGuizha") then return false end
	local need_retrial = function(player)
		local alive_num = self.room:alivePlayerCount()
		return alive_num + q(player,"getSeat") % alive_num > self.room:getCurrent():getSeat()
			and q(player,"getSeat") < alive_num + q(self.player,"getSeat") % alive_num
	end
	local retrial_card = { ["spade"] = nil, ["heart"] = nil, ["club"] = nil }
	local attacker_card = { ["spade"] = nil, ["heart"] = nil, ["club"] = nil }

	local handcards = sgs.QList2Table(self.player:getHandcards())
	for i = 1, #handcards, 1 do
		if q(handcards[i],"getSuit") == sgs.Card_Spade and q(handcards[i],"getNumber") >= 2 and q(handcards[i],"getNumber") <= 9 then
			retrial_card.spade = true
		end
		if q(handcards[i],"getSuit") == sgs.Card_Heart then
			retrial_card.heart = true
		end
		if q(handcards[i],"getSuit") == sgs.Card_Club then
			retrial_card.club = true
		end
	end

	local cards = sgs.QList2Table(attacker:getEquips())
	local handcards = visible_single_hand(self,attacker)
	if #handcards == 1 and q(handcards[1],"hasFlag","visible") then table.insert(cards, handcards[1]) end

	for i = 1, #cards, 1 do
		if q(cards[i],"getSuit") == sgs.Card_Spade and q(cards[i],"getNumber") >= 2 and q(cards[i],"getNumber") <= 9 then
			attacker_card.spade = sgs.Card_Spade
		end
		if q(cards[i],"getSuit") == sgs.Card_Heart then
			attacker_card.heart = sgs.Card_Heart
		end
		if q(cards[i],"getSuit") == sgs.Card_Club then
			attacker_card.club = sgs.Card_Club
		end
	end

	local players = self.room:getOtherPlayers(self.player)
	for _, player in sgs.qlist(players) do
		if q(player,"containsTrick","lightning") and self:getFinalRetrial(player) == 1 and need_retrial(player) then
			if not retrial_card.spade and attacker_card.spade then return attacker_card.spade end
		end

		if self:isFriend(player) and not q(player,"containsTrick","YanxiaoCard") and not q(player,"hasSkill","qiaobian") then
			if q(player,"containsTrick","indulgence") and self:getFinalRetrial(player) == 1 and need_retrial(player) and q(player,"getHandcardNum") >= q(player,"getHp") then
				if not retrial_card.heart and attacker_card.heart then return attacker_card.heart end
			end

			if q(player,"containsTrick","supply_shortage") and self:getFinalRetrial(player) == 1 and need_retrial(player) and q(self,"hasSkills","yongshi", player) then
				if not retrial_card.club and attacker_card.club then return attacker_card.club end
			end
		end
	end
	return false
end


--星诸葛亮
sgs.ai_view_as.LuaDongcha = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if q(card,"getSuit") == sgs.Card_Spade then
		return proposal("nullification","LuaDongcha",card)
	end
end

sgs.ai_cardneed.LuaDongcha = function(to, card, self)
	if q(card,"getSuit") == sgs.Card_Spade then
		return card
	end
end

sgs.LuaDongcha_suit_value = {
	spade = 3.9
}

sgs.ai_skill_invoke.LuaNixing = function(self, data)
	return true
end

sgs.ai_use_revises.LuaDongcha = function(self, card, use)
	if q(card,"isKindOf","EquipCard")
		and q(card,"getSuit") == sgs.Card_Spade
	then
		local same = self:getSameEquip(card)
		if same and q(same,"getSuit") == sgs.Card_Spade
		then
			return false
		end
	end
end


--星赵云
sgs.ai_fill_skill.LuaLongzhen = function(self, inclusive, request)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local jink_card

	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if q(card,"isKindOf","Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = q(jink_card,"getSuitString")
	local number = q(jink_card,"getNumberString")
	local card_id = q(jink_card,"getEffectiveId")
	return convert(self,"LuaLongzhen","Slash","slash",jink_card,request)
end

sgs.ai_view_as.LuaLongzhen = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place ~= sgs.Player_PlaceEquip then
		if q(card,"isKindOf","Jink") then
			return proposal("slash","LuaLongzhen",card)
		elseif q(card,"isKindOf","Slash") then
			return proposal("jink","LuaLongzhen",card)
		end
	end
end

sgs.ai_use_priority.LuaLongzhen = 9

sgs.LuaLongzhen_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.8,
	FireSlash = 5.7,
	Slash = 5.9,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}

sgs.ai_skill_invoke["#LuaChongzhen"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if hasManjuanEffect(self.player) then return false end
		if self:needKongcheng(target) and q(target,"getHandcardNum") == 1 then return true end
		if self:getOverflow(target) > 2 then return true end
		return false
	else
		return not (self:needKongcheng(target) and q(target,"getHandcardNum") == 1)
	end
end

sgs.ai_choicemade_filter.skillInvoke.LuaLongzhen = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if q(p,"getStrategyFlag","LuaChongzhenTarget") then
			target = p
			break
		end
	end
	if target then
		local intention = 60
		if promptlist[3] == "yes" then
			if not self:hasLoseHandcardEffective(target) or (self:needKongcheng(target) and q(target,"getHandcardNum") == 1) then
				intention = 0
			end
			if self:getOverflow(target) > 2 then intention = 0 end
			sgs.updateIntention(player, target, intention)
		else
			if self:needKongcheng(target) and q(target,"getHandcardNum") == 1 then intention = 0 end
			sgs.updateIntention(player, target, -intention)
		end
	end
end

sgs.ai_slash_prohibit.LuaLongzhen = function(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if q(from,"hasSkill","tieji") or self:canLiegong(to, from) then
		return false
	end
	if q(to,"hasSkill","LuaLongzhen") and q(to,"getHandcardNum") >= 3 and q(from,"getHandcardNum") > 1 then return true end
	return false
end









--星周瑜
sgs.ai_skill_invoke.LuaYingcai = function(self, data)
	return true
end

sgs.ai_fill_skill.LuaFanjian = function(self, inclusive, request)
	if q(self.player,"isKongcheng") then return nil end
	if q(self.player,"hasUsed","#LuaFanjianCard") then return nil end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	return q(self,"bindSkillCard","LuaFanjian",{q(cards[1],"getId")},request,nil,"#LuaFanjianCard")
end


sgs.ai_skill_use_func["#LuaFanjianCard"] = function(card, use, self)
	local room = self.player:getRoom()
	card = fanjian_skill(self,card)
	self:sort(self.enemies, "defense")
	local target
	local n = 0
	local y = 0
	for _, enemy in ipairs(self.enemies) do
		if self:canAttack(enemy) then
			if n <= enemy:getEquips():length() then
				n = enemy:getEquips():length()
				target = enemy
			end
			if (q(self.player,"getHandcardNum") - 1) < (q(enemy,"getHandcardNum") + 1) then
				if y < q(enemy,"getHandcardNum") then
					y = q(enemy,"getHandcardNum")
					target = enemy
					break
				end
			end
		end
	end
	if target then
		if use.to then
			use.to:append(target)
		end
		use.card = card
		return
	end
end

-- Audited alias #LuaFanjianCard -> FanjianCard is registered by event-intention.
sgs.dynamic_value.damage_card["#LuaFanjianCard"] = true


function sgs.ai_skill_suit.LuaFanjian(self)
	local map = { 0, 0, 1, 2, 2, 3, 3, 3 }
	local suit = map[math.random(1, 8)]
	if q(self.player,"hasSkill","hongyan") and suit == sgs.Card_Spade then return sgs.Card_Heart else return suit end
end

sgs.ai_getLeastHandcardNum_skill.LuaXiongcai = function(self, player, least)
	if q(player,"getPhase") ~= sgs.Player_Discard and least < 3 then
		return 3
	end
end

--星吕布
sgs.ai_view_as.LuaGuishen = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place ~= sgs.Player_PlaceEquip and not q(card,"isKindOf","Peach") and not q(card,"hasFlag","using") then
		return proposal("slash","LuaGuishen",card)
	end
end

sgs.ai_fill_skill.LuaGuishen = function(self, inclusive, request)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local red_card
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if not q(card,"isKindOf","Slash") and not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not isCard("Analeptic", card, self.player) then
			red_card = card
			break
		end
	end

	if red_card then
		local suit = q(red_card,"getSuitString")
		local number = q(red_card,"getNumberString")
		local card_id = q(red_card,"getEffectiveId")
		return convert(self,"LuaGuishen","Slash","slash",red_card,request)
	end
end

function sgs.ai_cardneed.LuaGuishen(to, card)
	return q(to,"getHandcardNum") < 3
end

sgs.hit_skill = sgs.hit_skill .."|LuaGuishen"

sgs.ai_skill_invoke["#LuaXDuojian"] = function(self, data)
	return true
end

sgs.ai_skill_invoke.LuaShenyong = function(self, data)
	local effect = data:toCardEffect()
	if effect.to and self:isEnemy(effect.to) and self:doDisCard(effect.to, "he") and self:isTiaoxinTarget(effect.to) then
		return true
	end
end

sgs.ai_skill_invoke.LuaJuejing = function(self, data)
	return true
end


sgs.ai_card_priority.LuaLongzhen_o = function(self, card)
	if table.contains(card:getSkillNames(), "LuaLongzhen_o")
	then
		return 2
	end
end

sgs.ai_skill_invoke.LuaLongzhen_o = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if hasManjuanEffect(self.player) then return false end
		if self:needKongcheng(target) and q(target,"getHandcardNum") == 1 then return true end
		if self:getOverflow(target) > 2 then return true end
		return false
	else
		return not (self:needKongcheng(target) and q(target,"getHandcardNum") == 1)
	end
	return true
end


-- Audited cardChosen LuaLongzhen_o -> snatch is registered by event-intention.




sgs.ai_fill_skill.LuaLongzhen_o = function(self, inclusive, request)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, visible_card(self,id))
		end
	end

	local jink_card

	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if q(card,"isKindOf","Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = q(jink_card,"getSuitString")
	local number = q(jink_card,"getNumberString")
	local card_id = q(jink_card,"getEffectiveId")
	return convert(self,"LuaLongzhen_o","Slash","slash",jink_card,request)
end

sgs.ai_view_as.LuaLongzhen_o = function(card, player, card_place)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		if q(card,"isKindOf","Jink") then
			return proposal("slash","LuaLongzhen_o",card)
		elseif q(card,"isKindOf","Slash") then
			return proposal("jink","LuaLongzhen_o",card)
		end
	end
end

sgs.LuaLongzhen_o_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.7,
	Slash = 5.6,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}


sgs.ai_skill_invoke.LuaLongwei = function(self)
	if q(self.player,"getStrategyFlag","DimengTarget") then
		local another
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if q(player,"getStrategyFlag","DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_askforag.LuaLongwei = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end

sgs.ai_getBestHp_skill.LuaBaonu = function(owner)
	if q(owner,"hasSkills","LuaHuaji+LuaBaonu") and q(owner,"getStrategyMark","LuaBaonu") == 0 then
		return q(owner,"getMaxHp") - 1
	end
end

sgs.hit_skill = sgs.hit_skill .. "|os_chitu"

-- newstar's literal alias captures whichever audited slash body has already
-- loaded. Use that immutable source identity, never the later canonical key.
sgs.ai_cardneed.os_chitu = function(to,card,self)
    local facts=self.world and self.world.strategy_facts
    local aliases=facts and facts.audited_aliases
    local row=aliases and aliases.entries and aliases.entries["ai_cardneed.os_chitu"]
    if not aliases or aliases.captured~=true or type(row)~="table"
        or row.alias_known~=true or row.present~=true or row.alias_type~="function"
        or row.alias_source_matches~=true then
        ai_unsupported("os_chitu captured source body is not proven","os_chitu")
    end
    local original=row.alias_variant=="smart_ai" and row.alias_source=="@lua/ai/smart-ai.lua" and row.alias_line==4110
    local sijyu=row.alias_variant=="sijyu" and row.alias_source=="@lua/ai/sijyu-ai.lua" and row.alias_line==1
    if not original and not sijyu then
        ai_unsupported("os_chitu captured source variant is not proven","os_chitu")
    end
    if not self:willSkipPlayPhase(to) then
        if original then
            return isCard("Slash",card,to) and getKnownCard(to,self.player,"Slash",true)==0
        end
        -- Preserve sijyu-ai.lua:1's three arguments. The ordinary donor helper
        -- returns 0 for its boolean class argument; do not repair that source call.
        return isCard("Slash",card,to) and getKnownCard(to,"Slash",true)==0
    end
end

sgs.ai_skill_invoke.LuaHuaji = function(self, data)
	local current = self.room:getCurrent()
	local juece_effect = (current and q(current,"isAlive") and q(current,"getPhase") ~= sgs.Player_NotActive and self:isEnemy(current) and q(current,"hasSkill","juece"))
	local manjuan_effect = hasManjuanEffect(self.player)
	if q(self.player,"isKongcheng") then
		if manjuan_effect or juece_effect then return false end
	elseif q(self.player,"getHandcardNum") == 1 then
		if manjuan_effect and juece_effect then return false end
	end
	return true
end

sgs.ai_skill_discard.LuaHuaji = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)

	table.insert(to_discard, known(cards[1]:getEffectiveId(),"Huaji discard ID"))

	return to_discard
end

sgs.ai_can_damagehp.LuaHuaji = function(self, from, card, to)
	return q(to,"getHp") + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 1
		and self:canLoseHp(from, card, to)
end

sgs.ai_getBestHp_skill.xingLuashenji = function(owner)
	if q(owner,"hasSkills","LuaHuaji+xingLuashenji") and q(owner,"getStrategyMark","xingLuashenji") == 0 then
		return q(owner,"getMaxHp") - 1
	end
end

