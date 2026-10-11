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
local function q(object,key,...)
    if not object or type(object[key])~="function" then ai_unsupported("dmpkancolle helper unavailable",key) end
    local method=key
    if key=="getMark" and AIValue.isPlayer(object) then method="getStrategyMark" end
    local value=object[method](object,...)
    if AIUnsupported.is(value)then error(value,0)end
    if sorted[key]then
        local original=(...);known(value,key)
        for i,entry in ipairs(value)do original[i]=entry end
        return original
    end
    if key=="hasSkill"or key=="hasSkills"then
        local target=AIValue.isPlayer(object) and object or (key=="hasSkills" and (select(2,...) or object.player))
        local view=target and rawget(target,"_view")
        if value==false and view and view.skills_complete~=true then
            ai_unsupported("dmpkancolle foreign skill absence is unknown",(...))
        end
    end
    if nullable[key]then return value end
    return known(value,key)
end
local function facts(self)
    return known(self.world.strategy_facts and self.world.strategy_facts.dmpkancolle,"dmpkancolle")
end
local function seed(self,skill,selector,request)
    return q(self,"legacySkillSeed",skill,selector,request or self.request)
end
local function paid(self,skill,selector,costs,request)
    return q(self,"bindSkillCard",skill,costs,request or self.request,nil,selector)
end
local function response(self,skill,selector,costs,target,request)
    local card=paid(self,skill,selector,costs,request)
    return {kind="use_card",card_spec=q(card,"toCardSpec"),targets=target and {q(target,"objectName")}or{}}
end
local function fanqian_parse(self,id)
    -- LuaSkillCard::Parse rejects #fanqian:<id> before prototype lookup:
    -- both accepted wire regexes require a second colon. Preserve source nil.
    return nil
end
local function fanqian_target(self)
    local value,present=self:getStrategyMemory("dmpkancolle.fanqian_target")
    if not present then ai_unsupported("source Room fanqian_target has no viewer-local observation","fanqian_target")end
    return q(self.room,"findPlayerByObjectName",value,true)
end
local function context(self,key)
    local c=q(self,"getDecisionContext")
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
    return q(self.room,"findPlayerByObjectName",known(row.player,"se_zhikong player"),true)
end
local function huibi_use(self,index)
    local row=context(self,"huibi_use")
    if row.history_index~=index then ai_unsupported("UseHistory scope differs from source inquiry","se_huibi_jink")end
    if row.present==false then return {} end -- QVariant.toCardUse of absent tag has null card/from.
    local use=known(row.use,"public UseHistory")
    local result={}
    if use.card then result.card=CardView.new(use.card) end
    if use.from then result.from=q(self.room,"findPlayerByObjectName",use.from,true)end
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
    local standard=self.world.strategy_facts and self.world.strategy_facts.standard
    local row=known(standard and standard.current_damage,"CurrentDamageStruct")
    if row==false then return{}end
    if type(row)~="table"then ai_unsupported("malformed current damage","CurrentDamageStruct")end
    local damage={}
    if row.to and row.to~=""then damage.to=q(self.room,"findPlayerByObjectName",row.to,true)end
    return damage -- the fixed callback reads only damage.to
end
local function evaluation(self,key,material)
    if key=="slash"then return q(self,"cloneEvaluationCard","slash")end
    local spec={source_key=key=="hongzha_slash"and"se_hongzha"or"nuequ",
        name=key=="hongzha_slash"and"slash"or"fire_slash",
        skill=key=="hongzha_slash"and"se_hongzha"or"",
        suit=key=="hongzha_slash"and sgs.Card_NoSuit or q(material,"getSuit"),
        number=key=="hongzha_slash"and 0 or q(material,"getNumber"),subcards={}}
    return q(self,"evaluateOwnerViewAsCard",spec)
end
local function turncount(self) return known(self.world.turn_count,"source turncount") end
local function fire_intention(self,card,from,tos)
    local f=sgs.ai_card_intention.FireSlash
    if type(f)~="function"then ai_unsupported("effective FireSlash intention callback unavailable","#nuequ")end
    local result=f(self,card,from,tos);if AIUnsupported.is(result)then error(result,0)end;return result
end
sgs.ai_fill_skill.se_chicheng = function(self, inclusive, request)
	local source = self.player
	if not (q(source,"getHandcardNum") >= 2 or q(source,"getHandcardNum") > q(source,"getHp")) then return end

	if q(source,"hasUsed","#se_chichengcard") then return end
	return seed(self,"se_chicheng","#se_chichengcard",request)
end

sgs.ai_skill_use_func["#se_chichengcard"] = function(card, use, self, request)
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByUseValue",cards, true)
	local needed = {}
	local num = 2
	if not q(self.player,"isWounded") and q(self,"getOverflow") <= 0 then num = 1 end
	if q(self.player,"getHandcardNum") - q(self.player,"getHp") > 2 then
		num = q(self.player,"getHandcardNum") -
			q(self.player,"getHp")
	end
	for _, acard in ipairs(cards) do
		if #needed < num then
			table.insert(needed, q(acard,"getEffectiveId"))
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
	if q(card,"isKindOf","Weapon")
	and not q(card,"isKindOf","Crossbow")
	and q(self,"getSameEquip",card)
	and not q(self.player,"hasUsed","#se_chichengcard")
	then return false end
end

sgs.ai_skill_invoke.se_zhikong            = function(self, data)
	local pname = q(data,"toPlayer"):objectName()
	local p
	for _, r in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(r,"objectName") == pname then p = r end
	end
	if not p then return false end
	if q(self,"isFriend",p) and q(self.player,"getPile","akagi_lv"):length() > 1 and not q(p,"hasSkills","SE_Pasheng|se_wushi") then return true end
	if q(self,"isFriend",p) and q(p,"getKingdom") == "kancolle" then return true end
	if q(p,"objectName") == q(self.player,"objectName") then return true end
	return false
end

ai_skill_use["@@akagi_lv"]            = function(self, prompt, request)
	local source = zhikong_source(self)
	if q(self,"isEnemy",source) then return "." end
	if q(self.player,"getPile","akagi_lv"):length() > 0 then
		local cardx = q(self,"getKnownCardById",q(self.player,"getPile","akagi_lv"):first())
		local card_str = "#se_zhikong:" .. q(cardx,"getId") .. ":"

		if q(self,"isFriend",source) and q(source,"getKingdom") == "kancolle" then return response(self,"se_zhikong","#se_zhikong",{q(cardx,"getId")},nil,request) end
		if q(source,"objectName") == q(self.player,"objectName") then return response(self,"se_zhikong","#se_zhikong",{q(cardx,"getId")},nil,request) end
		if q(self,"isFriend",source) then
			for _, enemy in ipairs(self.enemies) do
				if q(self,"canAttack",enemy, source) and not q(self,"canLiuli",enemy, self.friends_noself) and not q(self,"findLeijiTarget",enemy, 50, source) then
					return response(self,"se_zhikong","#se_zhikong",{q(cardx,"getId")},nil,request)
				end
			end
		end
	end

	return "."
end
sgs.ai_ajustdamage_from["&se_zhikong"]    = function(self, from, to, card, nature)
	if (card and q(card,"isKindOf","Slash")) then
		return 1
	end
end



sgs.ai_skill_invoke.se_leimu = function(self, data)
	if #self.enemies > 0 then
		return sgs.ai_skill_playerchosen.se_leimu(self, q(self.room,"getOtherPlayers",self.player)) ~= nil
	end
	return false
end


sgs.ai_skill_playerchosen.se_leimu = function(self, targets)
	return q(self,"findBestDamageTarget",1, "T", 0, nil)
end

sgs.ai_cardneed.se_yezhan         = function(to, card, self)
	return q(card,"isKindOf","FireSlash") or q(card,"isKindOf","ThunderSlash") or q(card,"isKindOf","FireAttack")
end

sgs.ai_ajustdamage_from.se_yezhan = function(self, from, to, card, nature)
	if q(from,"getMark","@turn_of_kita") > 0 and math.floor(q(from,"getMark","@turn_of_kita") / 2) * 2 == q(from,"getMark","@turn_of_kita")
		and nature ~= sgs.DamageStruct_Normal then
		return 1
	end
end

sgs.ai_skill_invoke.se_mowang = function(self, data)
	local dying = q(data,"toDying")
	local peaches = 1 - q(dying.who,"getHp")

	return q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") < peaches
end

sgs.ai_canNiepan_skill.se_mowang = function(player)
	return q(player,"getMaxHp") > 2
end


function sgs.ai_cardneed.se_kuangquan(to, card, self)
	return result(isCard("Slash", card, to)) and known(getKnownCard(to, self.player, "Slash", true),"known Slash") == 0
end

sgs.ai_skill_invoke.se_kuangquan = function(self, data)
	local damage = q(data,"toDamage")
	if q(self,"isEnemy",damage.to) then return true end
	return false
end

sgs.ai_skill_invoke.se_chongzhuang = function(self, data)
	if #self.enemies > 0 then return true end
	return false
end

-- se_chongzhuang immutable alias is shared-owned.

sgs.ai_need_damaged.se_emeng = function(self, attacker, player)
	if q(player,"hasSkill","se_emeng") and q(player,"getMark","se_emeng") == 0 and q(self,"getEnemyNumBySeat",q(self.room,"getCurrent"), player, player, true) < q(player,"getHp")
		and (q(player,"getHp") > 2 or q(player,"getHp") == 2 and (q(player,"faceUp") or q(player,"hasSkill","guixin") or q(player,"hasSkill","toudu") and not q(player,"isKongcheng"))) then
		return true
	end
	return false
end

function sgs.ai_slash_prohibit.se_emeng(self, from, to, card)
	if turncount(self) <= 1 and q(to,"isLord") and q(to,"getHp") >= 2 and not q(self,"isFriend",to, from) then return true end
end

function sgs.ai_cardneed.poi_paoxiao(to, card, self)
	local cards = q(to,"getHandcards")
    local current=q(self.room,"getCurrent")
    if q(current,"objectName")~=q(self.player,"objectName") and #cards<q(to,"getHandcardNum") then
        ai_unsupported("source current-player visibility inventory is not disclosed to this viewer","poi_paoxiao")
    end
	local has_weapon = q(to,"getWeapon") and not q(to,"getWeapon"):isKindOf("Crossbow")
	local slash_num = 0
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", q(self.room,"getCurrent"):objectName(), q(to,"objectName"))
		if q(c,"hasFlag","visible") or q(c,"hasFlag",flag) then
			if q(c,"isKindOf","Weapon") and not q(c,"isKindOf","Crossbow") then
				has_weapon = true
			end
			if q(c,"isKindOf","Slash") then slash_num = slash_num + 1 end
		end
	end

	if not has_weapon then
		return q(card,"isKindOf","Weapon") and not q(card,"isKindOf","Crossbow")
	else
		return q(to,"hasWeapon","spear") or q(card,"isKindOf","Slash") or (slash_num > 1 and q(card,"isKindOf","Analeptic"))
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
	if q(q(self.room,"getCurrent"),"getNextAlive") ~= self.player then return true end
	return false
end

sgs.ai_skill_invoke.se_huibi_jink = function(self, data)
	local isUse = q(data,"toStringList")[3] == "use"
	local use 
	if isUse then
		if q(data,"toStringList")[4] then 
			use = huibi_use(self,q(data,"toStringList")[4])
		end
	end
	if isUse then
		if use.card and q(use.card,"hasFlag","NosJiefanUsed") then return false  end
		if not use.from or nullfilter(self,data,nil,use.from)
		or q(use.card,"isKindOf","NatureSlash") and q(self.player,"isChained") and q(self,"isGoodChainTarget",self.player,use.card,use.from)
		or q(self,"needToLoseHp",self.player,use.from,use.card) and q(self,"ajustDamage",use.from,self.player,1,use.card)==1 then return false end
	end
	if q(self,"needToLoseHp",self.player, nil, nil, true) then return false  end
	if q(self,"getCardsNum","Jink") == 0 then return true end
	if q(self,"ajustDamage",nil,self.player,1,nil)>1 then return true end
	return true
end

function sgs.ai_slash_prohibit.se_huibi(self, from, to, card)
	if q(to,"getMark","@shimakaze_speed") > 4 and not q(self,"isFriend",to, from) and not q(self,"canLiegong",to, from) then return true end
end

sgs.ai_skill_choice["se_huibi"] = function(self, data)
	if q(self.player,"getMark","@shimakaze_speed") > 4 then return "se_huibi_move" end
	return "se_huibi_plus"
end

sgs.ai_skill_invoke.se_qianlei = function(self, data)
	local dying_data = q(data,"toDying")
	local damage = dying_data.damage
	local der = dying_data.who
	return q(self,"isEnemy",der) or q(self,"isEnemy",damage.from)
end

sgs.ai_skill_choice["se_qianlei"] = function(self, choices, data)
	local dying_data = q(data,"toDying")
	local damage = dying_data.damage
	local der = dying_data.who
	local slash = evaluation(self,"slash")
	
	local items = choices:split("+")
	local choice2 = getChoice(choices, "se_qianlei_second")
	local choice1 = getChoice(choices, "se_qianlei_first")
	if q(self,"isEnemy",der) and choice2 then return choice2 end
	if damage.from and q(self,"isEnemy",damage.from)
		and q(self,"slashIsEffective",slash, der) and choice1
		and q(self,"isGoodTarget",der, self.enemies, slash)

	then
		return choice1
	end
	if not damage.from and q(self,"isFriend",der) and choice1 then
		return choice1
	end
	return "cancel"
end
sgs.ai_choicemade_filter.skillChoice["se_qianlei"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local dest = q(self.room,"getCurrentDyingPlayer")
	if not dest then return end
	if choice == "se_qianlei_first" then
		q(self,"updateIntention",player, dest, 40)
	elseif choice == "se_qianlei_second" then
		q(self,"updateIntention",player, dest, -50)
	end
end

sgs.ai_skill_cardchosen["se_qianlei"] = function(self, who, flags)
	local dest = q(self.room,"getCurrentDyingPlayer")
	local allcards = q(who,"getCards",flags)
	allcards = sgs.QList2Table(allcards)
	q(self,"sortByKeepValue",allcards)
	if dest and q(self,"isFriend",dest) then
		for _, c in ipairs(allcards) do
			if q(c,"isKindOf","Analeptic") then
				return q(c,"getEffectiveId")
			end
		end
		q(self,"sortByKeepValue",allcards, true)
		for _, c in ipairs(allcards) do
			return q(c,"getEffectiveId")
		end
	end
	return allcards[1]:getEffectiveId()
end


sgs.ai_skill_invoke.se_shuacun = true







sgs.ai_fill_skill.se_hongzha = function(self, inclusive, request)
	if q(self.player,"getCards","he"):length() < 1 then return nil end
	if q(self.player,"hasUsed","#se_hongzha") then return nil end
	if q(self.player,"getPile","Kansaiki"):isEmpty() then return nil end
	if #self.enemies == 0 then return nil end
	local card
	if not card then
		local hcards = q(self.player,"getCards","he")
		hcards = sgs.QList2Table(hcards)
		q(self,"sortByUseValue",hcards, true)

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
	q(self,"sort",self.enemies, "defense")
	local targets = {}
	local slash = evaluation(self,"hongzha_slash")
	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"canSlash",enemy, slash) and not q(self,"slashProhibit",slash, enemy)
			and q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash)
			and q(enemy,"objectName") ~= q(self.player,"objectName") then
			if #targets < q(self.player,"getPile","Kansaiki"):length() then
				table.insert(targets, enemy)
			else
				break
			end
		end
	end
	local card
	if not card then
		local hcards = q(self.player,"getCards","he")
		hcards = sgs.QList2Table(hcards)
		q(self,"sortByUseValue",hcards, true)

		for _, hcard in ipairs(hcards) do
			card = hcard
			break
		end
	end
	if card then
		if #targets > 0 then
			use.card = paid(self,"se_hongzha","#se_hongzha",{q(card,"getId")},request)
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
	q(self,"updatePlayers")
	q(self,"sort",self.friends, "defense")
	local target


	for _, friend in ipairs(self.friends) do
		if #q(friend,"getPileNames") > 0 and (q(self,"isWeak",friend) or (q(friend,"getHp") < q(self,"getBestHp",friend))) then
			target = friend
		end
	end
	if not target then
		target = self.player
	end
	if (not (q(self,"getOverflow") <= 0)) or (q(target,"isWounded")) or (q(target,"objectName") == q(self.player,"objectName") and q(self.player,"getPile","Kansaiki"):length() < 2) then
		local hcards = q(self.player,"getCards","h")
		hcards = sgs.QList2Table(hcards)
		q(self,"sortByUseValue",hcards, true)
		local card = hcards[1]
		return response(self,"se_weishi","#se_weishi",{q(card,"getEffectiveId")},target,request)
	end
end
sgs.ai_card_intention.se_weishi = -50

sgs.ai_fill_skill.fanqian = function(self, inclusive, request)
	if q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Jink") + q(self,"getCardsNum","Analeptic") + q(self,"getCardsNum","Nullification") >= q(self.player,"getHandcardNum") then return end
	return seed(self,"fanqian","#fanqian",request)
end

sgs.ai_skill_use_func.FanqianCard = function(card, use, self, request)
	local card

	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByUsePriority",cards)

	local equips = {}
	for _, card in sgs.list(q(self.player,"getHandcards")) do
		if q(card,"isKindOf","Armor") or q(card,"isKindOf","Weapon") then
			if not q(self,"getSameEquip",card) then
			elseif q(card,"isKindOf","GudingBlade") and q(self,"getCardsNum","Slash") > 0 then
				local HeavyDamage
				local slash = q(self,"getCard","Slash")
				for _, enemy in ipairs(self.enemies) do
					if q(self.player,"canSlash",enemy, slash, true) and not q(self,"slashProhibit",slash, enemy) and
						q(self,"slashIsEffective",slash, enemy) and not q(self.player,"hasSkill","jueqing") and q(enemy,"isKongcheng") then
						HeavyDamage = true
						break
					end
				end
				if not HeavyDamage then table.insert(equips, card) end
			else
				table.insert(equips, card)
			end
		elseif q(card,"getTypeId") == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end

	if #equips > 0 then
		local select_equip, target
		for _, friend in ipairs(self.friends) do
			for _, equip in ipairs(equips) do
				if not q(self,"getSameEquip",equip, friend) and q(self,"hasSkills",sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
					target = friend
					select_equip = equip
					break
				end
			end
			if target then break end
			for _, equip in ipairs(equips) do
				if not q(self,"getSameEquip",equip, friend) then
					target = friend
					select_equip = equip
					break
				end
			end
			if target then break end
		end


		if target then
			use.card = fanqian_parse(self,q(select_equip,"getEffectiveId"))
			q(self,"setStrategyMemory","dmpkancolle.fanqian_target",q(target,"objectName"))
			return
		end
	end

	for _, c in ipairs(cards) do
		if not q(c,"isKindOf","Collateral") then
			if q(c,"isKindOf","Slash") or q(c,"isKindOf","SingleTargetTrick") or q(c,"isKindOf","Lightning") or q(c,"isKindOf","AOE") then
				card = c
				break
			end
		end
	end

	if card then
		local target

		for _, p in sgs.list(q(self.room,"getAlivePlayers")) do
			if q(p,"getMark","@Buyu") > 0 then target = p end
		end
		if not target then target = self.enemies[1] end

		if target then
			use.card = fanqian_parse(self,q(card,"getEffectiveId"))
			q(self,"setStrategyMemory","dmpkancolle.fanqian_target",q(target,"objectName"))
			return
		end
	else

		for _, c in ipairs(cards) do
			if q(c,"isKindOf","Peach") or q(c,"isKindOf","GodSalvation") then
				card = c
				break
			end
		end

		if card then
			local target
			local minHp = 100
			for _, friend in ipairs(self.friends) do
				local hp = q(friend,"getHp")
				if q(friend,"getHp") == q(friend,"getMaxHp") then
					hp = 1000
				end
				if q(self,"hasSkills",sgs.masochism_skill, friend) then
					hp = hp - 1
				end
				if q(friend,"isLord") then
					hp = hp - 1
				end
				if hp < minHp then
					minHp = hp
					target = friend
				end
			end
			for _, friend in ipairs(self.friends) do
				if q(friend,"objectName") == "SE_Kirito" and q(friend,"getHp") == 1 then
					target = friend
				end
			end
			if target then
				use.card = fanqian_parse(self,q(card,"getEffectiveId"))
				q(self,"setStrategyMemory","dmpkancolle.fanqian_target",q(target,"objectName"))
				return
			end
		else
			for _, c in ipairs(cards) do
				if q(c,"isKindOf","ExNihilo") or q(c,"isKindOf","AmazingGrace") then
					card = c
					break
				end
			end

			if card then
				local target = q(self,"findPlayerToDraw",true, 2)
				if target then
					use.card = fanqian_parse(self,q(card,"getEffectiveId"))
					q(self,"setStrategyMemory","dmpkancolle.fanqian_target",q(target,"objectName"))
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
	for _, c in sgs.list(q(self.player,"getHandcards")) do
		if (q(c,"isKindOf","Slash") or q(c,"isKindOf","SingleTargetTrick") or q(c,"isKindOf","Lightning") or q(c,"isKindOf","AOE")) and not q(c,"isKindOf","Collateral") then
			num = num + 1
		elseif not q(c,"isKindOf","Analeptic") and not q(c,"isKindOf","Jink") then
			other = other + 1
		end
	end

	if num >= other then return true end
	return false
end

sgs.ai_skill_playerchosen.Buyu   = function(self, targets)
	return q(self,"getPriorTarget")
end

sgs.ai_fill_skill.eryu = function(self, inclusive, request)
	if q(self.player,"hasUsed","#eryu") then return end
	if q(self.player,"getMark","@EryuMark") == 1 then return end
	for _, p in sgs.list(q(self.room,"getOtherPlayers",self.player)) do
		if q(self,"isFriend",p) and q(p,"isFemale") then return seed(self,"eryu","#eryu",request) end
	end
end

sgs.ai_skill_use_func["#eryu"] = function(card, use, self, request)
	local target
	local lord = q(self.room,"getLord")
	if lord and q(self.player,"getRole") == "loyalist" and q(self,"isFriend",lord) and q(lord,"isFemale") then
		use.card = paid(self,"eryu","#eryu",{},request)
		if use.to then use.to:append(lord) end
		return
	end
	for _, p in sgs.list(q(self.room,"getOtherPlayers",self.player)) do
		if q(self,"isFriend",p) and q(p,"isFemale") then
			if not target then
				target = p
			else
				if q(target,"getHp") < q(p,"getHp") then
					target = p
				end
			end
			if q(p,"hasSkills",sgs.cardneed_skill) and q(p,"getHp") > 2 then
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
		if q(p,"inMyAttackRange",self.player) then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.youdiz     = function(self, targets)
	for _, p in sgs.list(targets) do
		if q(self,"isEnemy",p) then return p end
	end
	return nil
end

sgs.ai_skill_playerchosen.youdi_draw = function(self, targets)
	return q(self,"findPlayerToDraw",false, 1)
end
sgs.ai_ajustdamage_from["&youdiz"]   = function(self, from, to, card, nature)
	if q(from,"getMark","@Youdi") > 0 and q(from,"getMark","&youdiz+to+#" .. q(to,"objectName")) == 0 then
		return -99
	end
end

sgs.ai_fill_skill.nuequ = function(self, inclusive, request)
	if q(self.player,"hasUsed","#nuequ") then return end
	if q(self.player,"isNude") then return end
	local targets = {}
	local min = 100
	for _, p in sgs.list(q(self.room,"getAlivePlayers")) do
		if q(p,"getHp") < min then
			targets = {}
			min = q(p,"getHp")
		end
		if q(p,"getHp") <= min then table.insert(targets, p) end
	end
	if min == 0 then
		if #targets == 1 and q(targets[1],"hasSkill","lingti") then return end
	end
	return seed(self,"nuequ","#nuequ",request)
end

sgs.ai_skill_use_func["#nuequ"]    = function(card, use, self, request)
	local target

	local cards = sgs.QList2Table(q(self.player,"getCards","h"))
	q(self,"sortByKeepValue",cards)
	if q(self.player,"getHandcardNum") == 0 then return end
	local dummyslash = evaluation(self,"nuequ",cards[1])
	local minhptargets = {}
	local min = 100
	for _, p in sgs.list(q(self.room,"getAlivePlayers")) do
		if q(p,"getHp") < min then
			min = q(p,"getHp")
		end
	end
	for _, p in sgs.list(q(self.room,"getOtherPlayers",self.player)) do
		if q(p,"getHp") <= min then table.insert(minhptargets, p) end
	end

	for _, t in ipairs(minhptargets) do
		if q(self,"isEnemy",t) and q(self,"isGoodTarget",t, self.enemies, dummyslash) and q(self,"slashIsEffective",dummyslash, t) and not q(self,"slashProhibit",dummyslash, t) then
			target = t
		end
	end

	if not target then
		for _, t in ipairs(minhptargets) do
			if q(self,"isFriend",t) and q(self,"isWeak",t) and q(self,"slashIsEffective",dummyslash, t) and not q(self,"slashProhibit",dummyslash, t) then
				target = t
			end
		end
	end

	if not target then
		for _, t in ipairs(minhptargets) do
			if q(self,"isEnemy",t) and q(t,"getHandcardNum") <= 1 and q(self,"slashIsEffective",dummyslash, t) and not q(self,"slashProhibit",dummyslash, t) then
				target = t
			end
		end
	end

	if not target then
		for _, t in ipairs(minhptargets) do
			if q(self,"isEnemy",t) and q(self,"slashIsEffective",dummyslash, t) and q(self,"isGoodTarget",t, self.enemies, dummyslash) and not q(self,"slashProhibit",dummyslash, t) then
				target = t
			end
		end
	end

	if not target then
		for _, t in ipairs(minhptargets) do
			if q(self,"isFriend",t) and q(t,"isWounded") and q(self,"slashIsEffective",dummyslash, t) and not q(self,"slashProhibit",dummyslash, t) then
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
	if q(from,"hasSkill","BurningLove") then
		return 0
	end
	return fire_intention(self,card,from,tos)
end

sgs.ai_skill_invoke["BurningLove"] = function(self, data)
	local damage = q(data,"toDamage")
	return q(self,"isFriend",damage.to) and
		not q(self,"needToLoseHp",damage.to, damage.from, nil, true)
end


sgs.ai_choicemade_filter.skillInvoke.BurningLove = function(self, player, promptlist)
	local damage = current_damage(self)
	if damage and damage.to then
		if promptlist[3] == "yes" then
			q(self,"updateIntention",player, damage.to, -50)
		elseif promptlist[3] == "no" then
			q(self,"updateIntention",player, damage.to, 50)
		end
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|nuequ"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|nuequ"
function sgs.ai_cardneed.BurningLove(to,card,self)
	if not q(self,"willSkipPlayPhase",to) then
		return (result(isCard("FireSlash", card, to)) and known(getKnownCard(to, "FireSlash", true),"source malformed known FireSlash") == 0)
	end
end
sgs.ai_skill_invoke.fanghuo = function(self, data)
	local damage = q(data,"toDamage")
	if not q(self,"isFriend",damage.to) then return true end
	return false
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|jianhun"
sgs.ai_fill_skill.jianhun = function(self, inclusive, request)
	if #self.enemies < 1 then return end
	local num = q(self.player,"getLostHp")
	for _, p in sgs.list(q(self.player,"getSiblings")) do
		if q(p,"getGeneralName") == "Mogami" or q(p,"getGeneral2Name") == "Mogami" or q(p,"getGeneralName") == "Shigure" or q(p,"getGeneral2Name") == "Shigure" then
			num =
				num + q(p,"getLostHp")
		end
	end

	if num < 2 and q(self.player,"getMark","@FireCaused") < 1 then return end

	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByKeepValue",cards)
	if #cards == 0 then return end
	local cardToUse = cards[1]
	if not cardToUse then
		return
	end
	if q(cardToUse,"isKindOf","Peach") then return end

	local suit = q(cardToUse,"getSuitString")
	local number = q(cardToUse,"getNumberString")
	local card_id = q(cardToUse,"getEffectiveId")
	local card_str = ("slash:jianhun[%s:%s]=%d"):format(suit, number, card_id)
	return q(self,"evaluateTurnConversion","jianhun","Slash",{name="slash",skill="jianhun",suit=q(cardToUse,"getSuit"),number=q(cardToUse,"getNumber"),subcards={card_id}},request or self.request)
end
