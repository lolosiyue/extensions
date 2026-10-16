-- Fixed mojiang-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local known = AIValue.requireKnown
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return (self:legacySkillSeed(skill,class,action_request(self,request))) end
local function bind(self,skill,class,costs,request) return (self:bindSkillCard(skill,costs,action_request(self,request),nil,class)) end
local function response(self,skill,class,costs,targets)
    local use=AIUsePlan.new();use.card=bind(self,skill,class,costs,nil);use.to=AIList.new(targets)
    return use:toAnswer()
end
local function nil_to_int(value) if value==nil then return 0 end;return value end
local function owner_tag(self,key)
    -- Viewer's own tag; absent reads as the donor's QVariant::toInt() 0.
    local value=self.player:getTag(key)
    if value==nil then return 0 end
    if type(value)~="number" then ai_unsupported("mojiang owner tag malformed","mojiang.owner_tags."..key) end
    return value
end
local function request_context(self) return (self:getDecisionContext()) end
local function quanqing_target(self)
    local name=known(request_context(self).mojiang_quanqing_target,"sy_quanqing.target")
    if name==false then return nil end
    return (self.room:findPlayerByObjectName(name))
end
local function diaoling(self) return known(request_context(self).mojiang_diaoling,"sy_diaoling.context") end
local function diaoling_target(self)
    local name=known(diaoling(self).target,"sy_diaoling.target")
    if name==false then return nil end
    return (self.room:findPlayerByObjectName(name))
end
local function diaoling_count(self) return known(diaoling(self).count,"sy_diaoling.count") end
local function visible_card(self,id) return known(self:getChoiceCard(id) or self:getKnownCardById(id),"sy_quanqing.disclosed_AG_card") end

-- sy_old_shisha is overwritten by mojiangprevious-ai.lua:700 in the fixed effective load.
-- Its final policy is owned by that package; do not resurrect this earlier body.

--魏武
sgs.ai_skill_invoke.sy_weiwu = function(self, data)
	if (self:needKongcheng(self.player,true)) then return false end
	return true
end

sgs.ai_can_damagehp.sy_weiwu = function(self,from,card,to)
	return (to:getHp())+(self:getAllPeachNum())-(self:ajustDamage(from,to,1,card))>0
	and (self:canLoseHp(from,card,to))
end


--龙变
sgs.ai_skill_invoke.sy_longbian = function(self, data)
	local x = 0 --【杀】可用次数
	local y = 0  --摸牌阶段摸牌数
	if (not owner_tag(self,"mcc_phasedraw_count")) or owner_tag(self,"mcc_phasedraw_count") == 0 then
		if nil_to_int(owner_tag(self,"mcc_phasedraw_num")) == 0 then y = y + 2 else y = y + owner_tag(self,"mcc_phasedraw_num") end
	else
		if owner_tag(self,"mcc_phasedraw_count") then y = y + owner_tag(self,"mcc_phasedraw_count") end
	end
	local z = (self.player:getMaxHp())  --体力上限
	if nil_to_int(owner_tag(self,"mcc_defaultslash_num")) == 0 then x = x + 1 else x = x + owner_tag(self,"mcc_defaultslash_num") end
	if math.min(x, y, z) <= 2 then return true end
	if x == y and y == z then return true end
	if math.max(x, y, z) ~= math.min(x, y, z) then return true end
end

sgs.ai_skill_choice["sy_longbian"] = function(self, choices, data)
	local longbian = (choices:split("+"))
	local x = 0 --【杀】可用次数
	local y = 0  --摸牌阶段摸牌数
	if (not owner_tag(self,"mcc_phasedraw_count")) or owner_tag(self,"mcc_phasedraw_count") == 0 then
		if nil_to_int(owner_tag(self,"mcc_phasedraw_num")) == 0 then y = y + 2 else y = y + owner_tag(self,"mcc_phasedraw_num") end
	else
		if owner_tag(self,"mcc_phasedraw_count") then y = y + owner_tag(self,"mcc_phasedraw_count") end
	end
	local z = (self.player:getMaxHp())  --体力上限
	if nil_to_int(owner_tag(self,"mcc_defaultslash_num")) == 0 then x = x + 1 else x = x + owner_tag(self,"mcc_defaultslash_num") end
	if x ~= y and y ~= z and x ~= z then
		if math.min(x, y, z) == x then
			return longbian[1]
		elseif math.min(x, y, z) == y then
			return longbian[2]
		elseif math.min(x, y, z) == z then
			return longbian[3]
		end
	else
		return longbian[math.random(1, #longbian)]
	end
end


--魔舞
sgs.ai_skill_invoke.sy_mowu = function(self, data)
	local use = (data:toCardUse())
	if ((use.card:isDamageCard()) or (use.card:isKindOf("Snatch")) or (use.card:isKindOf("Dismantlement"))) and use.from and (use.from:objectName()) == (self.player:objectName()) then
		local enemies = {}
		for _, pe in sgs.qlist(use.to) do
			if (self:isEnemy(pe)) then table.insert(enemies, pe) end
		end
		if #enemies > 0 and (use.to:length()) - #enemies <= 1 then return true end
	end
	if not (use.card:isDamageCard()) and use.from and (use.from:objectName()) ~= (self.player:objectName()) then
		if (self:isFriend(use.from)) then return true end
		if (self:isEnemy(use.from)) and not (use.to:contains(use.from)) then return true end
	end
	if (use.card:isKindOf("Peach")) and (self.player:isWounded()) then return true end
	if (use.card:isKindOf("Analeptic")) then return true end
	return false
end


--权倾
local sy_quanqing_skill = {}
sy_quanqing_skill.name = "sy_quanqing"
table.insert(package_skills, sy_quanqing_skill)
sy_quanqing_skill.getTurnUseCard = function(self,inclusive,request)
	if (self.player:isKongcheng()) then return end
	local cards = AIList.new((self.player:getCards("h")))
	local to_show = {}
	for _, c in ipairs(cards) do
		local cid = (c:getKnownEffectiveId())
		if (self.player:getMark("sy_quanqing"..cid.."-PlayClear")) == 0 then table.insert(to_show, c) end
	end
	local _max = -999
	if #to_show > 0 then
		for _, c in ipairs(to_show) do
			_max = math.max(_max, (c:getNumber()))
		end
	end
	local max_card
	for _, c in ipairs(to_show) do
		if (c:getNumber()) == _max then
			max_card = c
			break
		end
	end
	if max_card then
		return (self:evaluateTurnSkillCard("sy_quanqing","#sy_quanqingCard",{(max_card:getKnownEffectiveId())},action_request(self,request)))
	else
		return nil
	end
end

sgs.ai_skill_use_func["#sy_quanqingCard"] = function(card,use,self,request)
	local target = nil
	if #self.enemies > 0 then
		self:sortInPlace(self.enemies, "chaofeng")
		for _, enemy in ipairs(self.enemies) do
			if (enemy:getMark("sy_quanqingTarget-PlayClear")) == 0 then
				target = enemy
				break
			end
		end
	else
		if #self.friends_noself > 0 then
			self:sortInPlace(self.friends_noself)
			for _, friend in ipairs(self.friends_noself) do
				if (friend:getMark("sy_quanqingTarget-PlayClear")) == 0 then
					target = friend
					break
				end
			end
		end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
	return
end

sgs.ai_use_value["sy_quanqingCard"] = 10
sgs.ai_use_priority["sy_quanqingCard"] = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_skill_cardask["@sy_quanqing"] = function(self, data, pattern)
	local cards = AIList.new((self.player:getCards("he")))
	self:sortByKeepValueInPlace(cards)
	local num = (data:toInt())
	local sunluban = self.room:findPlayerBySkillName("sy_quanqing")
	local qqcard
	if not (self:isFriend(sunluban)) then
		for _, card in ipairs(cards) do
			if (card:getNumber()) > num then
				qqcard = card
				break
			end
		end
	else
		return "."
	end
	if qqcard then
		return "$" .. (qqcard:getKnownEffectiveId())
	end
	return "."
end

local function canQuanqingSlashHit(slash, from, to)
	if (from:hasWeapon("QinggangSword")) then return true end
	if (slash:isKindOf("NormalSlash")) and to:getArmor() == "vine" then
		if (from:hasWeapon("Fan")) then return true else return false end
	end
	if (slash:isKindOf("FireSlash")) or (slash:isKindOf("ThunderSlash")) or (slash:isKindOf("IceSlash")) then return true end
end

sgs.ai_skill_askforag.sy_quanqing = function(self, card_ids)
	local result_id = -1
	local from = quanqing_target(self)
	if (self:isEnemy(from)) then
		for _,id in sgs.list(card_ids)do
			local qq_card = visible_card(self,id)
			if not (from:isProhibited(self.player,qq_card)) then
				if (qq_card:isKindOf("Duel")) then
					result_id = id
					break
				end
			end
		end
		if result_id == -1 then
			for _,id in sgs.list(card_ids)do
				if qq_card:isKindOf("Slash") then
					if canQuanqingSlashHit(card, from, self.player) then
						result_id = id
						break
					end
				end
			end
		end
	elseif (self:isFriend(from)) then
		for _,id in sgs.list(card_ids)do
			local qq_card = visible_card(self,id)
			if (self:isWeak(from)) then
				if (from:hasSkills("hunzi|mobilehunzi|olhunzi")) then
					if (qq_card:isKindOf("ExNihilo")) then
						result_id = id
						break
					end
				else
					if (from:isWounded()) and (qq_card:isKindOf("Peach")) then
						result_id = id
						break
					end
				end
			else
				local has_sunce = false
				for _, t in sgs.qlist((self.room:getOtherPlayers(from))) do
					if (self:isFriend(t)) and (t:hasSkills("hunzi|mobilehunzi|olhunzi")) and (t:getHp()) <= 2 then
						has_sunce = true
						break
					end
				end
				if has_sunce then
					if (qq_card:isKindOf("ExNihilo")) then
						result_id = id
						break
					end
				else
					if (qq_card:isKindOf("GodSalvation")) then
						result_id = id
						break
					end
				end
			end
		end
	end
	if result_id ~= -1 then return result_id end
end

local function hasDeathSkills(who)
	return (who:hasSkills("wuhun|sgkgodsuohun|duanchang")) and not (who:hasSkills("sy_fangu|sy_guiming"))
end

sgs.ai_skill_playerchosen.sy_quanqing = function(self, targets)
	local qq_from = quanqing_target(self)
	local to = nil
	if (self:isEnemy(qq_from)) then
		for _, t in sgs.qlist(targets) do
			if (self:isEnemy(t)) and hasDeathSkills(t) then
				to = t
				break
			end
		end
		if not to then
			if (self.player:getHp()) >= 2 or (self:getCardsNum("Peach")) + (self:getCardsNum("Analeptic")) > 0 then
				to = self.player
			end
		end
	end
	return to
end

sgs.ai_need_damaged.sy_quanqing = function(self, attacker, player)
	if (self:isEnemy(attacker,player)) then
		if (not (self:isWeak(player))) or (getCardsNum("Peach", player, self.player) + getCardsNum("Analeptic", player, self.player)) > 0 then
			return true
		end
		if (attacker:hasSkill("sgkgodxiejia")) and attacker:getArmor() == nil and player:getArmor() ~= "silver_lion" then return false end
		if (attacker:hasSkill("luoyi")) and (attacker:getMark("&luoyi")) > 0 and player:getArmor() ~= "silver_lion" then return false end
		if (attacker:hasSkill("mobilepojun|mouliegong")) then return false end
	end
	if (self:isEnemy(attacker,player)) and not ((self:needToLoseHp(attacker)) and not (self:hasSkills(sgs.masochism_skill,attacker))) then return true end
	return false
end

--永劫
local function hasResistLoseMaxHpSkill(player)
	return (player:hasSkills("sgkgodyinyang|sgkgodlinglong|sgkgodqianyuan|sgkgoddanjing|sgkgodwangyue|huishi")) or (player:getMaxHp()) >= 8
end

sgs.ai_skill_invoke.sy_yongjie = function(self, data)
	local can_do = false
	local room = (self.player:getRoom())
	for _, t in sgs.qlist((room:getAlivePlayers())) do
		if (t:getMark("sy_yongjie_DamageTimes")) > 0 and (self:isEnemy(t)) then
			can_do = true
			break
		end
	end
	return can_do
end

sgs.ai_skill_playerschosen.sy_yongjie = function(self, targets)
	targets = AIList.new(targets)
	local nuls = {}
	for _, p in ipairs(targets) do
	    if (self:isEnemy(p)) then
		   table.insert(nuls, p)
		end
	end
	return nuls
end

sgs.ai_skill_discard.sy_yongjie = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
	local sunluban
	if self.room:findPlayerBySkillName("sy_yongjie") then sunluban = self.room:findPlayerBySkillName("sy_yongjie") end
	if sunluban and hasResistLoseMaxHpSkill(self.player) then return to_discard end
	local n = math.random(1, 100)
	local x = (self.player:getMark("sy_yongjie_DamageTimes"))
	if n <= 95 then
	    return to_discard
	else
	    local cards = AIList.new((self.player:getCards("he")))
		self:sortByKeepValueInPlace(cards)
		local index = 0
		for i = #cards, 1, -1 do
		    local card = cards[i]
			if (not (self.player:isJilei(card))) then
			    table.insert(to_discard, (card:getKnownEffectiveId()))
		        table.remove(cards, i)
		        index = index + 1
		        if index == x then break end
	        end
		end
		if #to_discard < x then return {} else return to_discard end
	end
end


--凋零
sgs.ai_skill_invoke.sy_diaoling = function(self, data)
	local to = diaoling_target(self)
	local x = diaoling_count(self)
	if (self:isEnemy(to)) then
		if (to:getHp()) - x <= 2 then return true end
		if x <= 1 then
			if (to:getHp()) > 1 and (self:hasZhaxiangEffect(to)) then return false end
		end
		return true
	elseif (self:isFriend(to)) then
		if (self:hasZhaxiangEffect(to)) and (to:getHp()) > 2 and x <= 2 then return true end
	end
end

--扼绝
local sy_ejue_skill = {}
sy_ejue_skill.name = "sy_ejue"
table.insert(package_skills, sy_ejue_skill)
sy_ejue_skill.getTurnUseCard = function(self,inclusive,request)
    if #self.enemies == 0 then return nil end
	return seed(self,"sy_ejue","#sy_ejueCard",request)
end

sgs.ai_skill_use_func["#sy_ejueCard"] = function(card,use,self,request)
    use.card = (self:inheritLegacyCardIdentity(bind(self,"sy_ejue","#sy_ejueCard",{},request),card))
end

sgs.ai_skill_invoke.sy_ejue = function(self, data)
	return #self.enemies > 0
end

sgs.ai_skill_use["@@sy_ejue!"] = function(self, prompt)
    local to_select = {}
	for _, c in sgs.qlist((self.player:getCards("he"))) do
		if (c:hasFlag("sy_ejue_draw")) then table.insert(to_select, c) end
	end
	local _max = 0
	local ejue_id
	for _, c in ipairs(to_select) do
		_max = math.max(_max, (c:getNumber()))
	end
	for _, c in ipairs(to_select) do
		if (c:getNumber()) >= _max then
			if (not (c:isKindOf("Peach"))) and (not (c:isKindOf("Analeptic"))) then
				ejue_id = (c:getKnownEffectiveId())
				break
			end
		end
	end
	if not ejue_id then
		for _, c in ipairs(to_select) do
			if (c:getNumber()) >= _max then
				ejue_id = (c:getKnownEffectiveId())
				break
			end
		end
	end
	if not ejue_id then
		ejue_id = to_select[math.random(1, #to_select)]:getEffectiveId()
	end
	return response(self,"sy_ejue","#sy_ejueCard",{ejue_id},{})
end


--魔貂蝉--（“迷乱”纯礁石棍，容易把顺风送翻盘，不写）
--魅惑（只给一张，就是这么抠（）
local fcmk_jlsg_meihuo_skill = {}
fcmk_jlsg_meihuo_skill.name = "fcmk_jlsg_meihuo"
table.insert(package_skills, fcmk_jlsg_meihuo_skill)
fcmk_jlsg_meihuo_skill.getTurnUseCard = function(self,inclusive,request)
	if (self.player:getStrategyHasUsed("#fcmk_jlsg_meihuoCard")) or (self.player:isKongcheng()) or #self.enemies < 2 then return end
	local card_id
	local cards = (self.player:getHandcards())
	cards = AIList.new(cards)
	self:sortByKeepValueInPlace(cards)
	local lightning = self:getCard("Lightning")
	if lightning and ((lightning:isRed()) or ((lightning:getSuit()) == sgs.Card_Spade and (self.player:hasSkill("mouhongyann"))))
	and not (self:willUseLightning(lightning)) then --优先给最废牌闪电
		card_id = (lightning:getKnownEffectiveId())
	else
		for _, acard in ipairs(cards) do
			if (acard:isKindOf("Slash")) or ((acard:isNDTrick()) and (acard:isDamageCard())) then --先给【杀】和伤害类普通锦囊
				card_id = (acard:getKnownEffectiveId())
				break
			end
		end
	end
	if not card_id then
		for _, acard in ipairs(cards) do
			if (acard:isNDTrick()) and not (acard:isKindOf("GlobalEffect")) and not (acard:isKindOf("ExNihilo")) and not (acard:isKindOf("Dongzhuxianji"))
			and not (acard:isKindOf("Snatch")) and not (acard:isKindOf("TlxyYanhua")) then --再给其他的普通锦囊，但增益类锦囊和【顺手牵羊】这种拉不了敌我牌差的坚决不给
				card_id = (acard:getKnownEffectiveId())
				break
			end
		end
	end
	if not card_id then
	    return nil
	else
	    return (self:evaluateTurnSkillCard("fcmk_jlsg_meihuo","#fcmk_jlsg_meihuoCard",{card_id},action_request(self,request)))
	end
end

sgs.ai_skill_use_func["#fcmk_jlsg_meihuoCard"] = function(card,use,self,request)
    if not (self.player:getStrategyHasUsed("#fcmk_jlsg_meihuoCard")) and not (self.player:isKongcheng()) and #self.enemies >= 2 then
        self:sortInPlace(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if enemy and (enemy:isMale()) and (enemy:getHandcardNum()) > 3 then --先找手牌多的
				use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
	    end
		for _, enemy in ipairs(self.enemies) do
		    if enemy and (enemy:isMale()) then
				use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
	    end
	end
	return nil
end

sgs.ai_use_value.fcmk_jlsg_meihuoCard = 8.5
sgs.ai_use_priority.fcmk_jlsg_meihuoCard = 9.5
sgs.ai_card_intention.fcmk_jlsg_meihuoCard = 80

sgs.ai_skill_playerchosen.fcmk_jlsg_meihuo = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
	    if (self:isEnemy(p)) then
		    return p
		end
	end
	for _, p in ipairs(targets) do
	    if not (self:isFriend(p)) then
		    return p
		end
	end
	return nil
end

sgs.ai_skill_invoke.fcmk_jlsg_miluan = true

--魔策
local mo_moce_skill = {}
mo_moce_skill.name = "mo_moce"
table.insert(package_skills, mo_moce_skill)
mo_moce_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.enemies == 0 then return nil end
	local has_spade = false
	for _, p in sgs.qlist((self.room:getAlivePlayers())) do
		for _, c in sgs.qlist((p:getCards("he"))) do
			if (c:getSuit()) == sgs.Card_Spade then has_spade = true break end
		end
		if has_spade then break end
	end
	if not has_spade then return nil end
	return seed(self,"mo_moce","#mo_moceCard",request)
end

sgs.ai_skill_use_func["#mo_moceCard"] = function(card,use,self,request)
	self:sortInPlace(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if not (enemy:isAllNude()) then
			use.card = (self:inheritLegacyCardIdentity(bind(self,"mo_moce","#mo_moceCard",{},request),card))
			if use.to then use.to:append(enemy) end
			return
		end
	end
	return nil
end

sgs.ai_use_value.mo_moceCard = 8
sgs.ai_use_priority.mo_moceCard = 8.5
sgs.ai_card_intention.mo_moceCard = 80

--焚劫（锁定技，无需AI）
--烬灭
sgs.ai_skill_invoke.mo_jinmie = function(self, data)
	local to = data and data:toPlayer()
	return to ~= nil and (self:isEnemy(to))
end

--僭天
sgs.ai_skill_invoke.mo_jiantian = function(self, data)
	local use = data and data:toCardUse()
	if not (use and use.to) then return false end
	local enemies, others = 0, 0
	for _, t in sgs.qlist(use.to) do
		if (self:isEnemy(t)) then enemies = enemies + 1 else others = others + 1 end
	end
	return enemies > 0 and enemies >= others
end

--冢骨
sgs.ai_skill_invoke.mo_zhonggu = function(self, data)
	return #self.enemies > #self.friends_noself
end

--妄断
local function mo_wangduan_score(self, kindof)
	local v = 0
	for _, e in ipairs(self.enemies) do
		local n = 0
		for _, c in sgs.qlist((e:getCards("h"))) do
			if not (c:isKindOf(kindof)) then n = n + 1 end
		end
		if n > 0 then v = v + n + 1 end
	end
	for _, f in ipairs(self.friends_noself) do
		for _, c in sgs.qlist((f:getCards("h"))) do
			if not (c:isKindOf(kindof)) then v = v - 1 end
		end
	end
	for _, c in sgs.qlist((self.player:getCards("h"))) do
		if not (c:isKindOf(kindof)) then v = v - 1 end
	end
	return v
end

local mo_wangduan_skill = {}
mo_wangduan_skill.name = "mo_wangduan"
table.insert(package_skills, mo_wangduan_skill)
mo_wangduan_skill.getTurnUseCard = function(self,inclusive,request)
	if (self.player:getStrategyHasUsed("#mo_wangduanCard")) then return end
	local best = -9999
	for _, kindof in ipairs({"BasicCard","TrickCard","EquipCard"}) do
		best = math.max(best, mo_wangduan_score(self, kindof))
	end
	if best >= 2 then
		return seed(self,"mo_wangduan","#mo_wangduanCard",request)
	end
end

sgs.ai_skill_use_func["#mo_wangduanCard"] = function(card,use,self,request)
    use.card = (self:inheritLegacyCardIdentity(bind(self,"mo_wangduan","#mo_wangduanCard",{},request),card))
end

sgs.ai_use_value.mo_wangduanCard = 7.5
sgs.ai_use_priority.mo_wangduanCard = 6.5

sgs.ai_skill_choice.mo_wangduan = function(self, choices, data)
	local best_choice, best_v = "basic", -9999
	local kinds = {basic="BasicCard", trick="TrickCard", equip="EquipCard"}
	for name, kindof in pairs(kinds) do
		local v = mo_wangduan_score(self, kindof)
		if v > best_v then best_v = v best_choice = name end
	end
	return best_choice
end

--华宠（兩個效果共用一個技能名：draw 標記 = 摸牌改偷牌；數字 = 傷害值）
sgs.ai_skill_invoke.mo_huachong = function(self, data)
	local s = data and data:toString() or ""
	if s == "draw" then
		for _, e in ipairs(self.enemies) do
			if not (e:isAllNude()) then return true end
		end
		return false
	end
	local n = tonumber(s) or 1
	if (self.player:getHp()) - n <= 0 or (self:isWeak(self.player)) then return true end
	return #self.enemies > #self.friends_noself
end

for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
