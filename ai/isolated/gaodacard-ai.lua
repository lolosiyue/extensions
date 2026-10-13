-- Fixed gaodacard donor; native authority stays in the ordinary cardask pipeline.
local function known(v,key)
 if AIUnsupported.is(v)then error(v,0)end
 if v==nil then ai_unsupported("Gaoda requires "..key,"gaodacard")end;return v
end
local function q(o,m,...)
 if AIValue.isPlayer(o)and m=="getMark"then m="getStrategyMark"end
 if not o or type(o[m])~="function"then ai_unsupported("Gaoda getter missing: "..m,"gaodacard")end
 return known(o[m](o,...),m)
end
local function context(self)
 local c=q(self,"getDecisionContext").gaodacard
 if type(c)~="table"then ai_unsupported("Guard scoped owner facts missing","gaodacard")end;return c
end
local function real_horse(self,horse)
 local rows=context(self).real_horses
 local row=type(rows)=="table"and rows[tostring(q(horse,"getEffectiveId"))]
 if type(row)~="table"then ai_unsupported("Guard exact real horse face missing","gaodacard")end
 return CardView.new(row)
end
-- The donor reads its own "ronghe" property: card ids joined by "+".
local function ronghe_cards(self)
 local value=self.player:getPropertyValue("ronghe")
 local result={}
 if value==nil or value==""then return result end
 if type(value)~="string"then ai_unsupported("Guard ronghe property is not a string","gaodacard")end
 for _,id in ipairs(value:split("+"))do
  local card=self:getKnownCardById(tonumber(id))
  if not card then ai_unsupported("Guard ronghe card face is unknown","gaodacard")end
  result[#result+1]=card
 end
 return result
end
if not sgs.ai_nullification then
	sgs.ai_nullification = {}
end

function SmartAIView:useCardShoot(card, use)
	if #self.enemies == 0 then return false end
	if q(self.player,"usedTimes","Shoot") >= 1 + q(card,"getTargetModResidue",self.player) then return false end
	use.card = card
	if use.to then
		-- Defense heuristics can randomize; freeze keys for a consistent sort order.
		local ranges, defenses = {}, {}
		for _, enemy in ipairs(self.enemies) do
			local name = q(enemy,"objectName")
			ranges[name] = q(self.player,"inMyAttackRange",enemy)
			defenses[name] = q(self,"getDefenseSlash",enemy)
		end
		local f = function(a, b)
			local a_name, b_name = q(a,"objectName"), q(b,"objectName")
			if ranges[a_name] == ranges[b_name] then
				return defenses[a_name] < defenses[b_name]
			else
				return ranges[a_name]
			end
		end
		table.sort(self.enemies, f)
		local tar = 1
		if q(card,"objectName") == "spread_shoot" then
			tar = 2
		end
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"getMark","@duilieB") > 0 and (q(card,"getNumber") % 2) == 0 and q(card,"getNumber") > 0 then continue end
			if q(self,"ajustDamage",self.player, enemy, 1, card) < 1 then continue end
			use.to:append(enemy)
			if use.to:length() >= tar + q(card,"getTargetModExtra",self.player) then return end
		end
		--如果没有有效目标，则不空发射击
		if use.to:isEmpty() then
			use.card = nil
		end
	end
end

sgs.ai_use_value.Shoot = sgs.ai_use_value.Slash
sgs.ai_keep_value.Shoot = sgs.ai_keep_value.Slash
sgs.ai_use_priority.Shoot = sgs.ai_use_priority.Slash + 0.1

function SmartAIView:useCardPierceShoot(card, use)
	self:useCardShoot(card, use)
end

sgs.ai_use_value.PierceShoot = sgs.ai_use_value.Slash + 0.1
sgs.ai_keep_value.PierceShoot = sgs.ai_keep_value.Slash + 0.1
sgs.ai_use_priority.PierceShoot = sgs.ai_use_priority.Slash + 0.1

function SmartAIView:useCardSpreadShoot(card, use)
	self:useCardShoot(card, use)
end

sgs.ai_use_value.SpreadShoot = sgs.ai_use_value.Slash + 0.1
sgs.ai_keep_value.SpreadShoot = sgs.ai_keep_value.Slash + 0.1
sgs.ai_use_priority.SpreadShoot = sgs.ai_use_priority.Slash + 0.1

ai_audited_aliases.register{
 id="ai_skill_cardask.shoot-jink",registry="ai_skill_cardask",path={"shoot-jink"},
 canonical_registry="ai_skill_cardask",canonical_path={"archery-attack-jink"},self_index=1
}

sgs.ai_skill_cardask["@multi-shoot-jink-start"] = function(self, data, pattern, target, target2, arg)
	local rest_num = tonumber(arg)
	if rest_num == 1 then return sgs.ai_skill_cardask["shoot-jink"](self, data, pattern, target) end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	
	if sgs.ai_skill_cardask["shoot-jink"](self, data, pattern, target) == "." then return "." end
	
	if q(self,"getCardsNum","Jink") < rest_num and q(self,"hasLoseHandcardEffective") then return "." end
end

sgs.ai_skill_cardask["@multi-shoot-jink"] = sgs.ai_skill_cardask["@multi-shoot-jink-start"]

sgs.ai_skill_cardask["@Guard"] = function(self, data, pattern)
	--强武
	if q(self.player,"hasSkill","luaqiangwu") and q(self.player,"getMark","luaqiangwub") > 0 then
		local cards = q(self.player,"getCards","he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _, card in ipairs (cards) do
			if q(card,"getSuit") == sgs.Card_Spade then
				local suit = q(card,"getSuitString")
				local number = q(card,"getNumberString")
				local card_id = q(card,"getEffectiveId")
				local name = "Guard"
				if q(card,"isKindOf","Slash") then
					name = "counter_guard"
				end
				return ("%s:luaqiangwu[%s:%s]=%d"):format(name, suit, number, card_id)
			end
		end
	end
	
	--覆盾
	if q(self.player,"hasSkill","fudun") then
		local card = self.player:getOffensiveHorse() or self.player:getDefensiveHorse()
		if card then
			card = real_horse(self,card)
			local suit = q(card,"getSuitString")
			local number = q(card,"getNumberString")
			local card_id = q(card,"getEffectiveId")
			return ("Guard:fuduncard[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
	
	--亮剑
	if q(self.player,"hasSkill","liangjian") then
		local can_invoke = true
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not q(self.player,"inMyAttackRange",p) then
				can_invoke = false
				break
			end
		end
		if can_invoke then
			local cards = q(self.player,"getCards","h")
			cards = sgs.QList2Table(cards)
			self:sortByKeepValue(cards)
			for _, card in ipairs (cards) do
				if (q(card,"getNumber") == 1 or q(card,"getNumber") == 7 or q(card,"getNumber") == 13)  then
					local suit = q(card,"getSuitString")
					local number = q(card,"getNumberString")
					local card_id = q(card,"getEffectiveId")
					return ("counter_guard:liangjian[%s:%s]=%d"):format(suit, number, card_id)
				end
			end
		end
	end
	
	for _,id in sgs.qlist(q(self.player,"getHandPile")) do
		local card = q(self,"getKnownCardById",id)
		if q(card,"getClassName"):endsWith("Guard") then
			return q(card,"getEffectiveId")
		end
	end
	
	--融合
	for _,card in pairs(ronghe_cards(self)) do
        if q(card,"getClassName"):endsWith("Guard") then return q(card,"getEffectiveId") end
    end

	--一般情况
	return self:askForCard(pattern, "@Guard-AI", data, sgs.Card_MethodUse, data:toDamage().from)
end

sgs.ai_skill_cardask["@Guard-AI"] = function(self, data, pattern)
	local damage = data:toDamage()
	if q(self,"needToLoseHp",self.player, damage.from, damage.card) then return "." end
	local cards = q(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) -- 按保留值排序
		for _,c in sgs.list(cards)do
		if q(self,"matchesDiscardPattern",pattern,c)
		then return q(c,"getEffectiveId") end
	end
	return "."
end

sgs.ai_use_value.Guard = sgs.ai_use_value.Jink
sgs.ai_keep_value.Guard = sgs.ai_keep_value.Jink - 0.05

sgs.ai_use_value.CounterGuard = sgs.ai_use_value.Jink + 0.1
sgs.ai_keep_value.CounterGuard = sgs.ai_keep_value.Jink + 0.1

function SmartAIView:useCardTacticalCombo(card, use)
	if q(self.player,"getMark","@duilieB") > 0 and (q(card,"getNumber") % 2) == 0 and q(card,"getNumber") > 0 then return end
	use.card = card
	if use.to then
		for _,friend in ipairs(self.friends) do
			use.to:append(friend)
			if use.to:length() >= 2 + q(card,"getTargetModExtra",self.player) then return end
		end
		--如果没有有效目标，则不空发射击
		if use.to:isEmpty() then
			use.card = nil
		end
		-- local targets = self.friends
		-- for i = 1, 2, 1 do
		-- 	local n = math.random(#targets)
		-- 	use.to:append(targets[n])
		-- 	table.removeOne(targets, targets[n])
		-- 	if #targets == 0 then break end
		-- end
		-- return
	end
end

sgs.ai_use_priority.TacticalCombo = sgs.ai_use_priority.Slash - 1
sgs.ai_use_value.TacticalCombo = 4
sgs.ai_keep_value.TacticalCombo = 1
sgs.dynamic_value.benefit.TacticalCombo = true

sgs.ai_nullification.TacticalCombo = function(self, card, from, to, positive)
	if positive then
		if q(self,"isEnemy",to) and q(to,"getHandcardNum") >= 3 then
			return true
		end
	else
		if q(self,"isFriend",to) and q(to,"getHandcardNum") >= 3 then
			return true
		end
	end
	return
end

sgs.ai_use_priority.LaplaceBox = 0.8

--高达杀乱入卡
function SmartAIView:useCardFinalVent(card, use)
	if #self.enemies == 0 then return false end
	use.card = card
	if use.to then
		self:sort(self.enemies, "hp")
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"getMark","@duilieB") > 0 and (q(card,"getNumber") % 2) == 0 and q(card,"getNumber") > 0 then continue end
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_use_priority.FinalVent = sgs.ai_use_priority.FireAttack + 0.1
sgs.ai_use_value.FinalVent = sgs.ai_use_value.FireAttack + 0.1
sgs.ai_keep_value.FinalVent = sgs.ai_keep_value.FireAttack + 0.1

sgs.ai_nullification.FinalVent = function(self, card, from, to, positive)
	if not positive then
		if q(self,"isEnemy",to) then
			return true
		end
	else
		if q(self,"isFriend",to) then
			return true
		end
	end
	return
end

function SmartAIView:useCardDecade(card, use)
	if #self.enemies == 0 then return false end
	use.card = card
	if use.to then
		self:sort(self.enemies, "hp")
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"getMark","@duilieB") > 0 and (q(card,"getNumber") % 2) == 0 and q(card,"getNumber") > 0 then continue end
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_use_priority.Decade = sgs.ai_use_priority.FireAttack + 0.1
sgs.ai_use_value.Decade = sgs.ai_use_value.FireAttack + 0.1
sgs.ai_keep_value.Decade = sgs.ai_keep_value.FireAttack + 0.1

sgs.ai_nullification.Decade = function(self, card, from, to, positive)
	if not positive then
		if q(self,"isEnemy",to) then
			return true
		end
	else
		if q(self,"isFriend",to) then
			return true
		end
	end
	return
end
