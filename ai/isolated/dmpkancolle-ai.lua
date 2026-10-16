-- Fixed b6025acc dmpkancolle policies. Source wire incompatibilities are not repaired.
local function result(value) if AIUnsupported.is(value)then error(value,0)end;return value end
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("dmpkancolle fact is unknown",key) end
    return value
end
local nullable={getSameEquip=true,getWeapon=true,getLord=true,getCurrentDyingPlayer=true,findBestDamageTarget=true,
    findPlayerToDraw=true,getPriorTarget=true,findLeijiTarget=true,updatePlayers=true,setStrategyMemory=true,
    updateIntention=true,getCard=true}
local sorted={sort=true,sortByKeepValue=true,sortByUseValue=true,sortByUsePriority=true}

local function facts(self)
    ai_unsupported("dmpkancolle facts are not projected","dmpkancolle")
end
local function seed(self,skill,selector,request)
    return self:legacySkillSeed(skill, selector, request or self.request)
end
local function paid(self,skill,selector,costs,request)
    return self:bindSkillCard(skill, costs, request or self.request, nil, selector)
end
local function response(self,skill,selector,costs,target,request)
    local card=paid(self,skill,selector,costs,request)
    return {kind="use_card",card_spec=card:toCardSpec(),targets=target and {target:objectName()}or{}}
end
local function fanqian_parse(self,id)
    -- LuaSkillCard::Parse rejects #fanqian:<id> before prototype lookup:
    -- both accepted wire regexes require a second colon. Preserve source nil.
    return nil
end
local function fanqian_target(self)
    local value,present=self:getStrategyMemory("dmpkancolle.fanqian_target")
    if not present then ai_unsupported("source Room fanqian_target has no viewer-local observation","fanqian_target")end
    return self.room:findPlayerByObjectName(value, true)
end
local function context(self,key)
    local c=self:getDecisionContext()
    local row=c.dmpkancolle and c.dmpkancolle[key]
    if type(row)~="table"or row.known~=true then ai_unsupported("dmpkancolle contextual source fact unknown",key)end
    return row
end
local function zhikong_source(self)
    local row=context(self,"zhikong_source")
    if row.present==false then
        local signal=AIUnsupported.new("donor reads an absent se_zhikong Room tag","@@akagi_lv")
        signal.donor_terminal_unavailable=true;error(signal,0)
    end
    return self.room:findPlayerByObjectName(known(row.player,"se_zhikong player"), true)
end
local function huibi_use(self,index)
    local row=context(self,"huibi_use")
    if row.history_index~=index then ai_unsupported("UseHistory scope differs from source inquiry","se_huibi_jink")end
    if row.present==false then return {} end -- QVariant.toCardUse of absent tag has null card/from.
    local use=known(row.use,"public UseHistory")
    local result={}
    if use.card then result.card=CardView.new(use.card) end
    if use.from then result.from=self.room:findPlayerByObjectName(use.from, true)end
    return result
end
local function nullfilter(self,data,pattern,target)
    local method=sgs.ai_skill_cardask.nullfilter
    if type(method)~="function"then ai_unsupported("effective nullfilter is unavailable","se_huibi_jink")end
    local value=method(self,data,pattern,target)
    if AIUnsupported.is(value)then error(value,0)end
    return value
end
local function current_damage(self)
    -- Source ChoiceMade callback reads the *live* Room CurrentDamageStruct,
    -- not an unrelated inquiry/event damage argument or a previous request.
    -- Room tags are not projected into event callbacks.
    ai_unsupported("Room CurrentDamageStruct is not projected","CurrentDamageStruct")
end
local function evaluation(self,key,material)
    if key=="slash"then return self:cloneEvaluationCard("slash")end
    local spec={source_key=key=="hongzha_slash"and"se_hongzha"or"nuequ",
        name=key=="hongzha_slash"and"slash"or"fire_slash",
        skill=key=="hongzha_slash"and"se_hongzha"or"",
        suit=key=="hongzha_slash"and sgs.Card_NoSuit or material:getSuit(),
        number=key=="hongzha_slash"and 0 or material:getNumber(),subcards={}}
    return self:evaluateOwnerViewAsCard(spec)
end
local function turncount(self) return known(self.world.turn_count,"source turncount") end
local function fire_intention(self,card,from,tos)
    local f=sgs.ai_card_intention.FireSlash
    if type(f)~="function"then ai_unsupported("effective FireSlash intention callback unavailable","#nuequ")end
    local result=f(self,card,from,tos);if AIUnsupported.is(result)then error(result,0)end;return result
end
sgs.ai_fill_skill.se_chicheng = function(self, inclusive, request)
	local source = self.player
	if not (source:getHandcardNum() >= 2 or source:getHandcardNum() > source:getHp()) then return end

	if source:getStrategyHasUsed("#se_chichengcard") then return end
	return seed(self,"se_chicheng","#se_chichengcard",request)
end

sgs.ai_skill_use_func["#se_chichengcard"] = function(card, use, self, request)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValueInPlace(cards, true)
	local needed = {}
	local num = 2
	if not self.player:isWounded() and self:getOverflow() <= 0 then num = 1 end
	if self.player:getHandcardNum() - self.player:getHp() > 2 then
		num = self.player:getHandcardNum() -
			self.player:getHp()
	end
	for _, acard in ipairs(cards) do
		if #needed < num then
			table.insert(needed, acard:getKnownEffectiveId())
		end
	end
	if needed then
		use.card = paid(self,"se_chicheng","#se_chichengcard",needed,request)
		return
	end
end

sgs.ai_use_value["se_chichengcard"]       = 2
sgs.ai_use_priority["se_chichengcard"]    = 1.6

sgs.ai_use_revises.se_chicheng = function(self,card,use)
	if card:isKindOf("Weapon")
	and not card:isKindOf("Crossbow")
	and self:getSameEquip(card)
	and not self.player:getStrategyHasUsed("#se_chichengcard")
	then return false end
end

sgs.ai_skill_invoke.se_zhikong            = function(self, data)
	local pname = data:toPlayer():objectName()
	local p
	for _, r in sgs.qlist(self.room:getAlivePlayers()) do
		if r:objectName() == pname then p = r end
	end
	if not p then return false end
	if self:isFriend(p) and self.player:getPile("akagi_lv"):length() > 1 and not p:hasSkills("SE_Pasheng|se_wushi") then return true end
	if self:isFriend(p) and p:getKnownKingdom() == "kancolle" then return true end
	if p:objectName() == self.player:objectName() then return true end
	return false
end

ai_skill_use["@@akagi_lv"]            = function(self, prompt, request)
	local source = zhikong_source(self)
	if self:isEnemy(source) then return "." end
	if self.player:getPile("akagi_lv"):length() > 0 then
		local cardx = self:getKnownCardById(self.player:getPile("akagi_lv"):first())
		local card_str = "#se_zhikong:" .. cardx:getKnownId() .. ":"

		if self:isFriend(source) and source:getKnownKingdom() == "kancolle" then return response(self,"se_zhikong","#se_zhikong",{cardx:getKnownId()},nil,request) end
		if source:objectName() == self.player:objectName() then return response(self,"se_zhikong","#se_zhikong",{cardx:getKnownId()},nil,request) end
		if self:isFriend(source) then
			for _, enemy in ipairs(self.enemies) do
				if self:canAttack(enemy, source) and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, source) then
					return response(self,"se_zhikong","#se_zhikong",{cardx:getKnownId()},nil,request)
				end
			end
		end
	end

	return "."
end
sgs.ai_ajustdamage_from["&se_zhikong"]    = function(self, from, to, card, nature)
	if (card and card:isKindOf("Slash")) then
		return 1
	end
end



sgs.ai_skill_invoke.se_leimu = function(self, data)
	if #self.enemies > 0 then
		return sgs.ai_skill_playerchosen.se_leimu(self, self.room:getOtherPlayers(self.player)) ~= nil
	end
	return false
end


sgs.ai_skill_playerchosen.se_leimu = function(self, targets)
	return self:findBestDamageTarget(1, "T", 0, nil)
end

sgs.ai_cardneed.se_yezhan         = function(to, card, self)
	return card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash") or card:isKindOf("FireAttack")
end

sgs.ai_ajustdamage_from.se_yezhan = function(self, from, to, card, nature)
	if from:getStrategyMark("@turn_of_kita") > 0 and math.floor(from:getStrategyMark("@turn_of_kita") / 2) * 2 == from:getStrategyMark("@turn_of_kita")
		and nature ~= sgs.DamageStruct_Normal then
		return 1
	end
end

sgs.ai_skill_invoke.se_mowang = function(self, data)
	local dying = data:toDying()
	local peaches = 1 - dying.who:getHp()

	return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
end

sgs.ai_canNiepan_skill.se_mowang = function(player)
	return player:getMaxHp() > 2
end


function sgs.ai_cardneed.se_kuangquan(to, card, self)
	return result(isCard("Slash", card, to)) and known(getKnownCard(to, self.player, "Slash", true),"known Slash") == 0
end

sgs.ai_skill_invoke.se_kuangquan = function(self, data)
	local damage = data:toDamage()
	if self:isEnemy(damage.to) then return true end
	return false
end

sgs.ai_skill_invoke.se_chongzhuang = function(self, data)
	if #self.enemies > 0 then return true end
	return false
end

-- se_chongzhuang immutable alias is shared-owned.

sgs.ai_need_damaged.se_emeng = function(self, attacker, player)
	if player:hasSkill("se_emeng") and player:getStrategyMark("se_emeng") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() > 2 or player:getHp() == 2 and (player:faceUp() or player:hasSkill("guixin") or player:hasSkill("toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end

function sgs.ai_slash_prohibit.se_emeng(self, from, to, card)
	if turncount(self) <= 1 and to:isLord() and to:getHp() >= 2 and not self:isFriend(to, from) then return true end
end

function sgs.ai_cardneed.poi_paoxiao(to, card, self)
	local cards = to:getHandcards()
    local current=self.room:getCurrent()
    if current:objectName()~=self.player:objectName() and #cards<to:getHandcardNum() then
        ai_unsupported("source current-player visibility inventory is not disclosed to this viewer","poi_paoxiao")
    end
	local has_weapon = to:getWeapon() and not to:getWeapon():isKindOf("Crossbow")
	local slash_num = 0
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:isKindOf("Weapon") and not c:isKindOf("Crossbow") then
				has_weapon = true
			end
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end

	if not has_weapon then
		return card:isKindOf("Weapon") and not card:isKindOf("Crossbow")
	else
		return to:hasWeapon("spear") or card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic"))
	end
end

sgs.poi_paoxiao_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.6,
	Slash = 5.4,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}


sgs.ai_skill_invoke.se_jifeng = true

sgs.ai_skill_invoke.se_huibi = function(self, data)
	if (self.room:getCurrent()):getNextAlive() ~= self.player then return true end
	return false
end

sgs.ai_skill_invoke.se_huibi_jink = function(self, data)
	local isUse = data:toStringList()[3] == "use"
	local use 
	if isUse then
		if data:toStringList()[4] then
			use = huibi_use(self,data:toStringList()[4])
		end
	end
	if isUse then
		if use.card and use.card:hasFlag("NosJiefanUsed") then return false  end
		if not use.from or nullfilter(self,data,nil,use.from)
		or use.card:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, use.card, use.from)
		or self:needToLoseHp(self.player, use.from, use.card) and self:ajustDamage(use.from, self.player, 1, use.card)==1 then return false end
	end
	if self:needToLoseHp(self.player, nil, nil, true) then return false  end
	if self:getCardsNum("Jink") == 0 then return true end
	if self:ajustDamage(nil, self.player, 1, nil)>1 then return true end
	return true
end

function sgs.ai_slash_prohibit.se_huibi(self, from, to, card)
	if to:getStrategyMark("@shimakaze_speed") > 4 and not self:isFriend(to, from) and not self:canLiegong(to, from) then return true end
end

sgs.ai_skill_choice["se_huibi"] = function(self, data)
	if self.player:getStrategyMark("@shimakaze_speed") > 4 then return "se_huibi_move" end
	return "se_huibi_plus"
end

sgs.ai_skill_invoke.se_qianlei = function(self, data)
	local dying_data = data:toDying()
	local damage = dying_data.damage
	local der = dying_data.who
	return self:isEnemy(der) or self:isEnemy(damage.from)
end

sgs.ai_skill_choice["se_qianlei"] = function(self, choices, data)
	local dying_data = data:toDying()
	local damage = dying_data.damage
	local der = dying_data.who
	local slash = evaluation(self,"slash")
	
	local items = choices:split("+")
	local choice2 = getChoice(choices, "se_qianlei_second")
	local choice1 = getChoice(choices, "se_qianlei_first")
	if self:isEnemy(der) and choice2 then return choice2 end
	if damage.from and self:isEnemy(damage.from)
		and self:slashIsEffective(slash, der) and choice1
		and self:isGoodTarget(der, self.enemies, slash)

	then
		return choice1
	end
	if not damage.from and self:isFriend(der) and choice1 then
		return choice1
	end
	return "cancel"
end
sgs.ai_choicemade_filter.skillChoice["se_qianlei"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local dest = self.room:getCurrentDyingPlayer()
	if not dest then return end
	if choice == "se_qianlei_first" then
		self:updateIntention(player, dest, 40)
	elseif choice == "se_qianlei_second" then
		self:updateIntention(player, dest, -50)
	end
end

sgs.ai_skill_cardchosen["se_qianlei"] = function(self, who, flags)
	local dest = self.room:getCurrentDyingPlayer()
	local allcards = who:getCards(flags)
	allcards = sgs.QList2Table(allcards)
	self:sortByKeepValueInPlace(allcards)
	if dest and self:isFriend(dest) then
		for _, c in ipairs(allcards) do
			if c:isKindOf("Analeptic") then
				return c:getKnownEffectiveId()
			end
		end
		self:sortByKeepValueInPlace(allcards, true)
		for _, c in ipairs(allcards) do
			return c:getKnownEffectiveId()
		end
	end
	return allcards[1]:getEffectiveId()
end


sgs.ai_skill_invoke.se_shuacun = true







sgs.ai_fill_skill.se_hongzha = function(self, inclusive, request)
	if self.player:getCards("he"):length() < 1 then return nil end
	if self.player:getStrategyHasUsed("#se_hongzha") then return nil end
	if self.player:getPile("Kansaiki"):isEmpty() then return nil end
	if #self.enemies == 0 then return nil end
	local card
	if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValueInPlace(hcards, true)

		for _, hcard in ipairs(hcards) do
			card = hcard
			break
		end
	end
	if card then
		return seed(self,"se_hongzha","#se_hongzha",request)
	end
end

sgs.ai_skill_use_func["#se_hongzha"] = function(card, use, self, request)
	self:sortInPlace(self.enemies, "defense")
	local targets = {}
	local slash = evaluation(self,"hongzha_slash")
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
			and enemy:objectName() ~= self.player:objectName() then
			if #targets < self.player:getPile("Kansaiki"):length() then
				table.insert(targets, enemy)
			else
				break
			end
		end
	end
	local card
	if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValueInPlace(hcards, true)

		for _, hcard in ipairs(hcards) do
			card = hcard
			break
		end
	end
	if card then
		if #targets > 0 then
			use.card = paid(self,"se_hongzha","#se_hongzha",{card:getKnownId()},request)
			if use.to then
				for i = 1, #targets, 1 do
					use.to:append(targets[i])
				end
			end
		end
	end
end

sgs.ai_use_value["se_hongzha"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["se_hongzha"] = sgs.ai_use_priority.Slash + 0.2

ai_skill_use["@@se_weishi"] = function(self, prompt, request)
	self:updatePlayers()
	self:sortInPlace(self.friends, "defense")
	local target


	for _, friend in ipairs(self.friends) do
		if #friend:getPileNames() > 0 and (self:isWeak(friend) or (friend:getHp() < self:getBestHp(friend))) then
			target = friend
		end
	end
	if not target then
		target = self.player
	end
	if (not (self:getOverflow() <= 0)) or (target:isWounded()) or (target:objectName() == self.player:objectName() and self.player:getPile("Kansaiki"):length() < 2) then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValueInPlace(hcards, true)
		local card = hcards[1]
		return response(self,"se_weishi","#se_weishi",{card:getKnownEffectiveId()},target,request)
	end
end
sgs.ai_card_intention.se_weishi = -50

sgs.ai_fill_skill.fanqian = function(self, inclusive, request)
	if self:getCardsNum("Peach") + self:getCardsNum("Jink") + self:getCardsNum("Analeptic") + self:getCardsNum("Nullification") >= self.player:getHandcardNum() then return end
	return seed(self,"fanqian","#fanqian",request)
end

sgs.ai_skill_use_func.FanqianCard = function(card, use, self, request)
	local card

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUsePriorityInPlace(cards)

	local equips = {}
	for _, card in sgs.list(self.player:getHandcards()) do
		if card:isKindOf("Armor") or card:isKindOf("Weapon") then
			if not self:getSameEquip(card) then
			elseif card:isKindOf("GudingBlade") and self:getCardsNum("Slash") > 0 then
				local HeavyDamage
				local slash = self:getCard("Slash")
				for _, enemy in ipairs(self.enemies) do
					if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(slash, enemy) and
						self:slashIsEffective(slash, enemy) and not self.player:hasSkill("jueqing") and enemy:isKongcheng() then
						HeavyDamage = true
						break
					end
				end
				if not HeavyDamage then table.insert(equips, card) end
			else
				table.insert(equips, card)
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end

	if #equips > 0 then
		local select_equip, target
		for _, friend in ipairs(self.friends) do
			for _, equip in ipairs(equips) do
				if not self:getSameEquip(equip, friend) and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
					target = friend
					select_equip = equip
					break
				end
			end
			if target then break end
			for _, equip in ipairs(equips) do
				if not self:getSameEquip(equip, friend) then
					target = friend
					select_equip = equip
					break
				end
			end
			if target then break end
		end


		if target then
			use.card = fanqian_parse(self,select_equip:getKnownEffectiveId())
			self:setStrategyMemory("dmpkancolle.fanqian_target", target:objectName())
			return
		end
	end

	for _, c in ipairs(cards) do
		if not c:isKindOf("Collateral") then
			if c:isKindOf("Slash") or c:isKindOf("SingleTargetTrick") or c:isKindOf("Lightning") or c:isKindOf("AOE") then
				card = c
				break
			end
		end
	end

	if card then
		local target

		for _, p in sgs.list(self.room:getAlivePlayers()) do
			if p:getStrategyMark("@Buyu") > 0 then target = p end
		end
		if not target then target = self.enemies[1] end

		if target then
			use.card = fanqian_parse(self,card:getKnownEffectiveId())
			self:setStrategyMemory("dmpkancolle.fanqian_target", target:objectName())
			return
		end
	else

		for _, c in ipairs(cards) do
			if c:isKindOf("Peach") or c:isKindOf("GodSalvation") then
				card = c
				break
			end
		end

		if card then
			local target
			local minHp = 100
			for _, friend in ipairs(self.friends) do
				local hp = friend:getHp()
				if friend:getHp() == friend:getMaxHp() then
					hp = 1000
				end
				if self:hasSkills(sgs.masochism_skill, friend) then
					hp = hp - 1
				end
				if friend:isLord() then
					hp = hp - 1
				end
				if hp < minHp then
					minHp = hp
					target = friend
				end
			end
			for _, friend in ipairs(self.friends) do
				if friend:objectName() == "SE_Kirito" and friend:getHp() == 1 then
					target = friend
				end
			end
			if target then
				use.card = fanqian_parse(self,card:getKnownEffectiveId())
				self:setStrategyMemory("dmpkancolle.fanqian_target", target:objectName())
				return
			end
		else
			for _, c in ipairs(cards) do
				if c:isKindOf("ExNihilo") or c:isKindOf("AmazingGrace") then
					card = c
					break
				end
			end

			if card then
				local target = self:findPlayerToDraw(true, 2)
				if target then
					use.card = fanqian_parse(self,card:getKnownEffectiveId())
					self:setStrategyMemory("dmpkancolle.fanqian_target", target:objectName())
					return
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen["fanqian"] = function(self, targets)
	return fanqian_target(self)
end


sgs.ai_use_value["fanqian"]      = 8
sgs.ai_use_priority["fanqian"]   = 10
sgs.ai_card_intention["fanqian"] = 0

sgs.ai_skill_invoke.Buyu         = function(self, data)
	if #self.enemies == 0 then return false end
	local num = 0
	local other = 0
	for _, c in sgs.list(self.player:getHandcards()) do
		if (c:isKindOf("Slash") or c:isKindOf("SingleTargetTrick") or c:isKindOf("Lightning") or c:isKindOf("AOE")) and not c:isKindOf("Collateral") then
			num = num + 1
		elseif not c:isKindOf("Analeptic") and not c:isKindOf("Jink") then
			other = other + 1
		end
	end

	if num >= other then return true end
	return false
end

sgs.ai_skill_playerchosen.Buyu   = function(self, targets)
	return self:getPriorTarget()
end

sgs.ai_fill_skill.eryu = function(self, inclusive, request)
	if self.player:getStrategyHasUsed("#eryu") then return end
	if self.player:getStrategyMark("@EryuMark") == 1 then return end
	for _, p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) and p:isFemale() then return seed(self,"eryu","#eryu",request) end
	end
end

sgs.ai_skill_use_func["#eryu"] = function(card, use, self, request)
	local target
	local lord = self.room:getLord()
	if lord and self.player:getKnownRole() == "loyalist" and self:isFriend(lord) and lord:isFemale() then
		use.card = paid(self,"eryu","#eryu",{},request)
		if use.to then use.to:append(lord) end
		return
	end
	for _, p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) and p:isFemale() then
			if not target then
				target = p
			else
				if target:getHp() < p:getHp() then
					target = p
				end
			end
			if p:hasSkills(sgs.cardneed_skill) and p:getHp() > 2 then
				target = p
				break
			end
		end
	end


	if target then
		use.card = paid(self,"eryu","#eryu",{},request)
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["eryu"]       = 10
sgs.ai_use_priority["eryu"]    = 10
sgs.ai_card_intention["eryu"]  = -100




sgs.ai_skill_invoke.youdiz           = function(self, data)
	if #self.friends_noself == 0 then return false end
	for _, p in ipairs(self.enemies) do
		if p:inMyAttackRange(self.player) then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.youdiz     = function(self, targets)
	for _, p in sgs.list(targets) do
		if self:isEnemy(p) then return p end
	end
	return nil
end

sgs.ai_skill_playerchosen.youdi_draw = function(self, targets)
	return self:findPlayerToDraw(false, 1)
end
sgs.ai_ajustdamage_from["&youdiz"]   = function(self, from, to, card, nature)
	if from:getStrategyMark("@Youdi") > 0 and from:getStrategyMark("&youdiz+to+#" .. to:objectName()) == 0 then
		return -99
	end
end

sgs.ai_fill_skill.nuequ = function(self, inclusive, request)
	if self.player:getStrategyHasUsed("#nuequ") then return end
	if self.player:isNude() then return end
	local targets = {}
	local min = 100
	for _, p in sgs.list(self.room:getAlivePlayers()) do
		if p:getHp() < min then
			targets = {}
			min = p:getHp()
		end
		if p:getHp() <= min then table.insert(targets, p) end
	end
	if min == 0 then
		if #targets == 1 and targets[1]:hasSkill("lingti") then return end
	end
	return seed(self,"nuequ","#nuequ",request)
end

sgs.ai_skill_use_func["#nuequ"]    = function(card, use, self, request)
	local target

	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValueInPlace(cards)
	if self.player:getHandcardNum() == 0 then return end
	local dummyslash = evaluation(self,"nuequ",cards[1])
	local minhptargets = {}
	local min = 100
	for _, p in sgs.list(self.room:getAlivePlayers()) do
		if p:getHp() < min then
			min = p:getHp()
		end
	end
	for _, p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if p:getHp() <= min then table.insert(minhptargets, p) end
	end

	for _, t in ipairs(minhptargets) do
		if self:isEnemy(t) and self:isGoodTarget(t, self.enemies, dummyslash) and self:slashIsEffective(dummyslash, t) and not self:slashProhibit(dummyslash, t) then
			target = t
		end
	end

	if not target then
		for _, t in ipairs(minhptargets) do
			if self:isFriend(t) and self:isWeak(t) and self:slashIsEffective(dummyslash, t) and not self:slashProhibit(dummyslash, t) then
				target = t
			end
		end
	end

	if not target then
		for _, t in ipairs(minhptargets) do
			if self:isEnemy(t) and t:getHandcardNum() <= 1 and self:slashIsEffective(dummyslash, t) and not self:slashProhibit(dummyslash, t) then
				target = t
			end
		end
	end

	if not target then
		for _, t in ipairs(minhptargets) do
			if self:isEnemy(t) and self:slashIsEffective(dummyslash, t) and self:isGoodTarget(t, self.enemies, dummyslash) and not self:slashProhibit(dummyslash, t) then
				target = t
			end
		end
	end

	if not target then
		for _, t in ipairs(minhptargets) do
			if self:isFriend(t) and t:isWounded() and self:slashIsEffective(dummyslash, t) and not self:slashProhibit(dummyslash, t) then
				target = t
			end
		end
	end




	if target and #cards > 0 then
		use.card = paid(self,"nuequ","#nuequ",{cards[1]:getEffectiveId()},request)
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["nuequ"]          = 5
sgs.ai_use_priority["nuequ"]       = 0
sgs.ai_card_intention["#nuequ"]    = function(self, card, from, tos)
	if from:hasSkill("BurningLove") then
		return 0
	end
	return fire_intention(self,card,from,tos)
end

sgs.ai_skill_invoke["BurningLove"] = function(self, data)
	local damage = data:toDamage()
	return self:isFriend(damage.to) and
		not self:needToLoseHp(damage.to, damage.from, nil, true)
end


sgs.ai_choicemade_filter.skillInvoke.BurningLove = function(self, player, promptlist)
	local damage = current_damage(self)
	if damage and damage.to then
		if promptlist[3] == "yes" then
			self:updateIntention(player, damage.to, -50)
		elseif promptlist[3] == "no" then
			self:updateIntention(player, damage.to, 50)
		end
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|nuequ"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|nuequ"
function sgs.ai_cardneed.BurningLove(to,card,self)
	if not self:willSkipPlayPhase(to) then
		return (result(isCard("FireSlash", card, to)) and known(getKnownCard(to, "FireSlash", true),"source malformed known FireSlash") == 0)
	end
end
sgs.ai_skill_invoke.fanghuo = function(self, data)
	local damage = data:toDamage()
	if not self:isFriend(damage.to) then return true end
	return false
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|jianhun"
sgs.ai_fill_skill.jianhun = function(self, inclusive, request)
	if #self.enemies < 1 then return end
	local num = self.player:getLostHp()
	for _, p in sgs.list(self.player:getSiblings()) do
		if p:getKnownGeneralName() == "Mogami" or p:getGeneral2Name() == "Mogami" or p:getKnownGeneralName() == "Shigure" or p:getGeneral2Name() == "Shigure" then
			num =
				num + p:getLostHp()
		end
	end

	if num < 2 and self.player:getStrategyMark("@FireCaused") < 1 then return end

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	if #cards == 0 then return end
	local cardToUse = cards[1]
	if not cardToUse then
		return
	end
	if cardToUse:isKindOf("Peach") then return end

	local suit = cardToUse:getSuitString()
	local number = cardToUse:getNumberString()
	local card_id = cardToUse:getKnownEffectiveId()
	local card_str = ("slash:jianhun[%s:%s]=%d"):format(suit, number, card_id)
	return self:evaluateTurnConversion("jianhun", "Slash", {name="slash",skill="jianhun",suit=cardToUse:getSuit(),number=cardToUse:getNumber(),subcards={card_id}}, request or self.request)
end
