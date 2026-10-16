-- Fixed b6025acc inovation-ai.lua:1119-1186 necessary dependency slice.
-- No other Inovation callback is claimed. The source free global `to_use`
-- has no writer (the seven other assignments are lexically local).
local to_use = nil
local known = AIValue.requireKnown
local function analeptic_available(self)
    local card=known(self:getEvaluationCard("analeptic"),"analeptic")
    local v=card._view and card._view.source_analeptic_available
    if type(v)~="boolean" then ai_unsupported("source Analeptic::IsAvailable is missing","inovation_fengzhu") end
    return v
end
sgs.ai_cardsview_valuable.inovation_fengzhu = function(self, class_name, player)
    local pattern = nil
    if class_name == "Slash" and not known(player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") then
        pattern = "slash"
    elseif class_name == "Jink" and not known(player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") then
        pattern = "jink"
    elseif class_name == "Peach" and not known(player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") then
        pattern = "peach"
    elseif class_name == "Analeptic" and not known(player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") then
        pattern = "analeptic"
    end
    if pattern then
	    local card_str = "@InovationFengzhuCard=.:"..pattern
	    return {skill="inovation_fengzhu", legacy_class="InovationFengzhuCard", subcards={}, user_string=pattern}
	end
end

sgs.ai_fill_skill.inovation_fengzhu = function(self, inclusive, request)
	if self.player:isKongcheng() then
		return
	end
    if not known(self.player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") and self.player:getLostHp() > 0 then
        return self:evaluateTurnSkillCard("inovation_fengzhu", "InovationFengzhuCard", {}, request, "peach")
    elseif not known(self.player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") and self:getCardsNum("Slash") > 0 and analeptic_available(self) then
        return self:evaluateTurnSkillCard("inovation_fengzhu", "InovationFengzhuCard", {}, request, "analeptic")
    elseif not known(self.player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") and self:slashIsAvailable() and self:getCardsNum("Slash") == 0 then
        return self:evaluateTurnSkillCard("inovation_fengzhu", "InovationFengzhuCard", {}, request, "slash")
    elseif not known(self.player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") then
        return self:evaluateTurnSkillCard("inovation_fengzhu", "InovationFengzhuCard", {}, request, "tacos")
    end
end

sgs.ai_skill_use_func.InovationFengzhuCard = function(card, use, self)

    local pattern = nil

    if not known(self.player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") then
        if self.player:getLostHp() > 0 and self:isWeak() then
             pattern = "peach"
        end
    end

    if not pattern and not known(self.player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") then
        if analeptic_available(self) and self:getCardsNum("Slash") > 0 then
            pattern = "analeptic"
        end
    end

    if not to_use and not known(self.player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") then
        if self:slashIsAvailable() and self:getCardsNum("Slash") == 0 then
            pattern = "slash"
        end
    end

    if not to_use and not known(self.player:getStrategyFlag("inovation_fengzhu_used"), "inovation_fengzhu_used") then
        pattern = "tacos"
    end

    if to_use and pattern then
        local card_str = "@InovationFengzhuCard=.:"..pattern
        local acard = self:evaluateTurnSkillCard("inovation_fengzhu", "InovationFengzhuCard", {}, nil, pattern)
        use.card = acard
    end
end
sgs.ai_use_value["InovationFengzhuCard"] = 6
sgs.ai_use_priority["InovationFengzhuCard"] = 3.5


-- R43 complete fixed Baonu/Jizhanshiz strategy family.
do


sgs.ai_skill_invoke.baonu = function(self, data)
	if #self.enemies == 0 then return false end
	if self.player:getHp() == 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 then return false end
	if self.player:getLostHp() == 0 and self.player:getHandcardNum() > 4 then return false end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self.player:inMyAttackRange(p) and not p:isNude() then return true end
	end
	return false
end


sgs.ai_fill_skill.jizhanshiz = function(self, inclusive, request)
	if self.player:hasUsed("JizhanCard") then return end
	if self.player:getMark("@Baonu") == 0 then return end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self.player:inMyAttackRange(p) and not p:isNude() then
			return self:evaluateTurnSkillCard("jizhanshiz","JizhanCard",{},request)
		end
	end
end

sgs.ai_skill_use_func.JizhanCard = function(card,use,self)
	local target
	if #self.enemies > 1 then
		for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
			if self.player:inMyAttackRange(p) and not p:isNude() and self:isEnemy(p) then
				target = p
				if #p:getEquips() > 0 then break end
			end
		end
		if not target then
			for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
				if self.player:inMyAttackRange(p) and not p:isNude()  then
					target = p
					break
				end
			end
		end
	else
		for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
			if self.player:inMyAttackRange(p) and not p:isNude() and not self:isEnemy(p) then
				target = p
				if #p:getEquips() > 0 then break end
			end
		end
	end
	if target then
		use.card = card
		self:recordSourceWarning("here???","inovation.jizhanshiz")
		use.to = AIList.new({})
		use.to:append(target)
		return
	end
end



sgs.ai_skill_playerchosen.jizhanshiz = function(self, targets)
	return self:getMostWeakEnemyToDamage(self,targets)
end

sgs.ai_use_value["JizhanCard"] = 5
sgs.ai_use_priority["JizhanCard"]  = 5
sgs.ai_card_intention["JizhanCard"] = 0


end

-- R45 complete fixed Inovation stateless policies; native/current-view facts only.
do


local function general2(self,p)
 local name=p:getGeneral2Name()
 if type(name)~="string"then ai_unsupported("public deputy slot unknown","inovation.general2")end
 return name~="" and true or nil
end
-- Akarin membership lives in a Room tag that is not projected.
local function akarin(self,p,observer)
 ai_unsupported("Akarin visibility is not projected","inovation.akarin")
end
local function death(self)
 local context=self:getDecisionContext();local row=context and context.inovation_kuisi
 if type(row)~="table"or row.known~=true or type(row.has_damage)~="boolean"then ai_unsupported("Kuisi current native Death cast unavailable","inovation.kuisi")end
 local out={}
 if row.has_damage then
  if row.from~=false and type(row.from)~="string"then ai_unsupported("Kuisi damage source unknown","inovation.kuisi")end
  out.damage={}
  if row.from~=false then out.damage.from=self.room:findPlayerByObjectName(row.from,true)end
 end
 return out
end
local function draw_count(self)
 local v=self.world and self.world.draw_pile_count
 if type(v)~="number"or v<0 or v%1~=0 then ai_unsupported("public draw pile size unknown","draw_pile_count")end
 return v
end
-- Fixed inovation-ai.lua:136-151
SmartAIView.useCardKeyTrick = function(self, card, use)
	for _,v in ipairs(self.friends) do
		if v:getLostHp() > 0 and not v:containsTrick("key_trick") and not (self.player:isProhibited(v,card) or akarin(self,v,self.player)) then
			use.card = card
			if use.to then use.to:append(v) end
			return
		end
	end
	for _,v in ipairs(self.friends) do
		if not v:containsTrick("key_trick") and not (self.player:isProhibited(v,card) or akarin(self,v,self.player)) then
			use.card = card
			if use.to then use.to:append(v) end
			return
		end
	end
end

-- Fixed inovation-ai.lua:87-128
SmartAIView.useCardMapoTofu = function(self, card, use) --need help 这个锦囊太复杂了。。。。。
	local targets = {}
	for _,p in sgs.list(self.room:getAlivePlayers()) do
		if self.player:distanceTo(p) <= 1 then table.insert(targets, p) end
	end
	if #targets == 0 then return end
	local f_target
	for _,target in ipairs(targets) do
		if self:isFriend(target) then
			if target:hasSkills(sgs.masochism_by_self_skill) then f_target = target end
			if target:hasSkills("inovation_Tianhuo") and target:getLostHp() > 0 then return target end
			local touma = self.room:findPlayerBySkillName("Huansha")
			local shirayuki = self.room:findPlayerBySkillName("SE_Zhandan")
			if ((touma and self:isFriend(touma)) or (shirayuki and self:isFriend(shirayuki))) and target:getLostHp() > 0 then return target end
		else
			if self.player:hasSkills(sgs.weak_killer_skill) and target:getLostHp() == 0 then f_target = target end
		end
	end
	if not f_target then
		for _,target in ipairs(targets) do
			if self:isFriend(target) and target:getLostHp() > 0 then
				f_target = target
			end
		end
	end
	if self.player:hasSkill("se_shouren") then
		for _,target in ipairs(targets) do
			if self:isEnemy(target) then
				f_target = target
			end
		end
	end
	if f_target then
		for _,v in ipairs(self.enemies) do
			if v:objectName() ~= f_target:objectName() then
				use.card = card
				if use.to and not (self.player:isProhibited(v,card) or akarin(self,v,self.player)) then use.to:append(v) end
				return
			end
		end
	end
end

-- Fixed inovation-ai.lua:472-474
sgs.ai_card_priority.touzhi = function(self,card,v)
	if card:isKindOf("Slash") then return 8-v end
end

-- Fixed inovation-ai.lua:349-351
sgs.ai_need_damaged.inovation_SE_Maoqun = function (self, attacker)
	return self.player:getHp()>10
end

-- Fixed inovation-ai.lua:76-82
sgs.ai_skill_choice["dingxin"] = function(self, choices, data)
	if self:getCardsNum("Peach") == 0 then return "dingxin_recover" end
	for _,p in sgs.list(self.room:getPlayers()) do
		if (p:getKnownGeneralName() == "inovation_Nagisa" or p:getGeneral2Name() == "inovation_Nagisa") and (self.player:getKnownRole() == p:getKnownRole() or (self.player:getKnownRole() == "lord" and p:getKnownRole() == "loyalist")) then return "dingxin_revive" end
	end
	return "dingxin_recover"
end

-- Fixed inovation-ai.lua:1217-1220
sgs.ai_skill_choice["jicheng"] = function(self, choices, data)
	if self:isWeak() and self:getCardsNum("Peach") == 0 and self.player:getHp() == 1 then return "jicheng_recover" end
	return "jicheng_draw"
end

-- Fixed inovation-ai.lua:951-955
sgs.ai_skill_choice.nangua = function(self, choices, data)
	if self.player:faceUp() then return "nangua_recover" end
	if self.player:getHp() < 1 then return "nangua_recover" end
	return "nangua_turnover"
end

-- Fixed inovation-ai.lua:1054-1064
sgs.ai_skill_choice["paoji"] = function(self, choices, data)
	local target = self:getPriorTarget()
	for _,p in ipairs(self.friends) do
		if p:hasSkills("guicai|se_qidian") then return "4" end
	end
	if target and self:isWeak(target) then return "1" end
	for _,p in ipairs(self.enemies) do
		if p:hasSkills("guicai|se_qidian") then return "1" end
	end
	return "4"
end

-- Fixed inovation-ai.lua:870-878
sgs.ai_skill_choice["xingjian"] = function(self, choices, data)
	local ranka = self.room:findPlayerBySkillName("xingjian")
	if not self:isEnemy(ranka) then return "xingjian_skip" end
	if self.player:hasSkills(sgs.need_equip_skill) then return "xingjian_skip" end
	if self.player:hasSkills(sgs.lose_equip_skill) then return "xingjian_throw" end
	if self.player:hasSkills(sgs.cardneed_skill) then return "xingjian_throw" end
	if self:getCardsNum("Slash") == 0 then return "xingjian_throw" end
	return "xingjian_skip"
end

-- Fixed inovation-ai.lua:521-524
sgs.ai_skill_invoke.FukurouzaTobi = function(self, data)
	if self:isEnemy(self.room:getCurrent()) and not self.room:getCurrent():hasSkills(sgs.immune_skill) then return true end
	return false
end

-- Fixed inovation-ai.lua:498-503
sgs.ai_skill_invoke.Takamakuri = function(self, data)
	local damage = data:toDamage()
	if not damage or not damage.to then return false end
	if self:isEnemy(damage.to) and not damage.to:hasSkills(sgs.lose_equip_skill) then return true end
	return false
end

-- Fixed inovation-ai.lua:505-512
sgs.ai_skill_invoke.Tobiugachi = function(self, data)
	if self:isFriend(self.room:getCurrent()) then
		if self.player:getHandcardNum() - self.player:getHp() + 1 <= 3 and (self:isWeak() or self:getCardsNum("Jink") == 0) then return true end
		return false
	end
	if self.player:getHandcardNum() - self.player:getHp() + 1 <= 5 then return true end
	return false
end

-- Fixed inovation-ai.lua:316-319
sgs.ai_skill_invoke.diangongDamage = function(self, data)
	local damage = data:toDamage()
	return self:isFriend(damage.to)
end

-- Fixed inovation-ai.lua:22-37
sgs.ai_skill_invoke.fushang = function(self, data)
	local damage = data:toDamage()
	if not damage or not damage.to then return false end
	if self:isFriend(damage.to) then
		local num = damage.to:getMark("@fushang")
		local last = damage.to:getMark("@fushang_time")
		if last == 1 then
			if self:isWeak(damage.to) and self:getCardsNum("Peach") == 0 then return false end
			if num >= damage.to:getLostHp() - 1 then return false end
			return true
		else
			return true
		end
	end
	return false
end

-- Fixed inovation-ai.lua:56-59
sgs.ai_skill_invoke.guangyu = function(self, data)
	if self:isFriend(self.room:getCurrent()) then return true end
	return false
end

-- Fixed inovation-ai.lua:413-417
sgs.ai_skill_invoke.inovation_SE_Zhixing = function(self, data)
	local source = data:toPlayer()
	if self:isFriend(source) then return true end
	return false
end

-- Fixed inovation-ai.lua:1066-1069
sgs.ai_skill_invoke.inovation_dianci = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

-- Fixed inovation-ai.lua:335-342
sgs.ai_skill_invoke.inovation_haixing = function(self, data)
	local dying_data = data:toDying()
	local source = dying_data.who
	if self:isFriend(source) then
		return true
	end
	return false
end

-- Fixed inovation-ai.lua:306-311
sgs.ai_skill_invoke.inovation_huanxing = function(self, data)
	local use = data:toCardUse()
	if not use or not use.from then return false end
	if self:isEnemy(use.from) then return true end
	return false
end

-- Fixed inovation-ai.lua:930-945
sgs.ai_skill_invoke.inovation_jixian = function(self, data)
	if #self.enemies == 0 then return false end
	if self.player:getLostHp() == 1 then return true end
	if self.player:getLostHp() > 1 then
		if self.player:getKnownRole() == "rebel" and self:isWeak(self.room:getLord()) then return true end
		if self.room:getAlivePlayers():length() == 2 then return true end
		if self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 then return true end
	end
	for _,p in ipairs(self.friends) do
		if p:hasSkills("SE_Shuanglang|SE_Mengfeng")then return true end
	end
	for _,p in ipairs(self.enemies) do
		if p:getHp() == 1 and self:isWeak(p) and p:getKnownRole() == "rebel" then return true end
	end
	return false
end

-- Fixed inovation-ai.lua:206-208
sgs.ai_skill_invoke.inovation_zhuren = function(self, data)
	return true
end

-- Fixed inovation-ai.lua:713-730
sgs.ai_skill_invoke.jianjin = function(self, data)
	local damage = data:toDamage()

	if not self:isFriend(damage.from) and not self:isFriend(damage.to) then return false end
	local current = self.room:getCurrent()
	if current:objectName() == self.player:objectName() or current:getNextAlive():objectName() == self.player:objectName() then
		if self.player:getMark("@Jianjin_damage_recovery") > 2 then return true end
		if self.player:getLostHp() > 0 and self:getCardsNum("Peach") > 0 then return false end
		if self.player:hasWeapon("crossbow") and self:getCardsNum("Slash") > 0 then return false end
		return true
	else
		if self.player:getMark("@Jianjin_damage_recovery") > 2 then return true end
		if self.player:getMark("@Jianjin_damage_recovery") == 2 then
			if self:isFriend(damage.from) and self:isWeak(damage.from) then return true end
			if self:isFriend(damage.to) and self:isWeak(damage.to) then return true end
		end
	end
end

-- Fixed inovation-ai.lua:1017-1032
sgs.ai_skill_invoke.jiguan = function(self, data)
	if #self.enemies == 0 then return false end
	local use = data:toCardUse()
	if use.from:objectName() == self.player:objectName() then return true end
	if self:isEnemy(use.from) then
		if use.from:getHp() == 1 then return true end
		local num = 0
		for _, id in sgs.list(self.player:getPile("jiguan")) do
			if sgs.Sanguosha:getCard(id):getNumber() == use.card:getNumber() then
				num = num + 1
			end
		end
		if num > 1 then return true end
	end
	return false
end

-- Fixed inovation-ai.lua:636-641
sgs.ai_skill_invoke.kangfen = function(self, data)
	if #self.enemies == 0 then return false end
	if self.player:getHp() == 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 then return false end
	if self.player:getEquips():length() == 0 and self.player:getHp() <= 3 then return false end
	return true
end

-- Fixed inovation-ai.lua:529-533
sgs.ai_skill_invoke.kongdi = function(self, data)
	local move = data:toMoveOneTime()
	if move.to and not self:isFriend(move.to) then return true end
	return false
end

-- Fixed inovation-ai.lua:536-540
sgs.ai_skill_invoke.kuisi = function(self, data)
	local death = death(self)
	if self:isEnemy(death.damage.from) then return true end
	return false
end

-- Fixed inovation-ai.lua:975-995
sgs.ai_skill_invoke.lunpo = function(self, data)
	local use = data:toCardUse()
	if self:isEnemy(use.from) then
		if use.card:isKindOf("SingleTargetTrick") and use.to:length() > 0 and self:isFriend(use.to:at(0)) then
			if use.card:isKindOf("Snatch") or use.card:isKindOf("Duel") then return true end
			--if q(use.card,"isKindOf","Dismantlement") and q(use.to,"at",0):getEquips():length() > 0 then return true end
			if use.card:isKindOf("DelayedTrick") and not use.card:isKindOf("KeyTrick") then return true end
		end
		if use.card:isKindOf("Slash") and self:isWeak(use.to:at(0)) and self:isFriend(use.to:at(0)) then return true end
		if use.card:isKindOf("Jink") or use.card:isKindOf("Peach") then return true end
		if use.card:isKindOf("AOE") or use.card:isKindOf("GlobalEffect") then
			for _,p in ipairs(self.friends) do
				if self:isWeak(p) then
					return true
				end
			end
		end
	end

	return false
end

-- Fixed inovation-ai.lua:958-973
sgs.ai_skill_invoke.lunpo_inturn = function(self, data)
	if #self.enemies == 0 then return false end
	local min = 100
	for _,p in sgs.list(self.room:getAlivePlayers()) do
		if p:getHp() < min then min = p:getHp() end
	end
	local num = self.player:getPile("Yandan"):length()
	if min == 1 and num >= 3 then return true end
	if min <= 2 then
		local toFight = self:getPriorTarget()
		if toFight:getHp() <= 1 then return true end
		if toFight:hasSkills(sgs.masochism_skill) then return true end
		if toFight:hasSkill("Lichang") then return true end
	end
	return false
end

-- Fixed inovation-ai.lua:909-927
sgs.ai_skill_invoke.qiyue = function(self, data)
	local dying = data:toDying()
	if not self:isFriend(dying.who) then return false end

	if self.player:objectName() == dying.who:objectName() then return true end
	local aggregate_num = 0
	for i=1, self.player:getMaxHp() do
		aggregate_num = aggregate_num + (5 - i) * self.room:getAlivePlayers():length()
	end
	if aggregate_num >= draw_count(self) then return true end

	if dying.who:isLord() then return true end

	if self.player:getMaxHp() >= 3 then return true end
	if self:getCardsNum("Jink") > 0 or self:getCardsNum("Analeptic") > 0 and self.player:getMaxHp() >= 2 then return true end


	return false
end

-- Fixed inovation-ai.lua:344-346
sgs.ai_skill_invoke.tanyan = function(self, data)
	return self:isFriend(self.room:getCurrent())
end

-- Fixed inovation-ai.lua:62-65
sgs.ai_skill_invoke.xiyuan = function(self, data)
	if #self.friends_noself == 0 then return false end
	return true
end

-- Fixed inovation-ai.lua:542-551
sgs.ai_skill_invoke.youer = function(self, data)
	local dying = data:toDying()
	if self:isEnemy(dying.damage.from) then
		if self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0 then
			return false
		end
		return true
	end
	return false
end

-- Fixed inovation-ai.lua:514-518
sgs.ai_skill_playerchosen.Tobiugachi = function(self, targets)
	local target = self:findPlayerToDiscard()
	if target then return target end
	return self.enemies[1]
end

-- Fixed inovation-ai.lua:321-332
sgs.ai_skill_playerchosen.diangong = function(self, targets)
	local hp_min = 100
	local target
	for _, ap in sgs.qlist(targets) do
		if self:isFriend(ap) and ap:getHp() < hp_min then
			target = ap
			hp_min = ap:getHp()
		end
	end
	if target then return target end
	return targets:first()
end

-- Fixed inovation-ai.lua:419-436
sgs.ai_skill_playerchosen.inovation_SE_Zhixing = function(self, targets)
	for _,p in ipairs(self.friends) do
		if p:getJudgingArea():length() > 0 then
			return p
		end
	end
	for _,p in ipairs(self.enemies) do
		if p:getEquips():length() > 0 then
			return p
		end
	end
	for _,p in ipairs(self.enemies) do
		if not p:isNude() then
			return p
		end
	end
	return self.enemies[1]
end

-- Fixed inovation-ai.lua:1071-1082
sgs.ai_skill_playerchosen.inovation_dianci = function(self, targets)
	if self:getPriorTarget() and not self:getPriorTarget():isChained() then return self:getPriorTarget() end
	if #self.enemies > 0 then
		for _,p in ipairs(self.enemies) do
			if not p:isChained() and self:isWeak(p) then return p end
		end
		return self.enemies[1]
	end
	for _,p in sgs.list(self.room:getAlivePlayers()) do
		if not self:isFriend(p) then return p end
	end
end

-- Fixed inovation-ai.lua:947-949
sgs.ai_skill_playerchosen.inovation_jixian = function(self, targets)
	return self:getPriorTarget()
end

-- Fixed inovation-ai.lua:732-738
sgs.ai_skill_playerchosen.jianjin = function(self, targets)

	for _,p in sgs.list(targets) do
		if self:isFriend(p) then return p end
	end
	return targets:first()
end

-- Fixed inovation-ai.lua:897-907
sgs.ai_skill_playerchosen.jianshi = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() == 0 then return friend end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() <=2 and friend:isLord() then return friend end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then return friend end
	end
end

-- Fixed inovation-ai.lua:1034-1036
sgs.ai_skill_playerchosen.jiguan = function(self, targets)
	return self:getPriorTarget()
end

-- Fixed inovation-ai.lua:1040-1052
sgs.ai_skill_playerchosen.paoji = function(self, targets)
	local target = self:getPriorTarget()
	if target and not target:hasSkill("se_nitian") then return target end
	if #self.enemies > 0 then
		for _,p in ipairs(self.enemies) do
			if p:isChained() and self:isWeak(p) and not target:hasSkill("se_nitian") then return p end
		end
		return self.enemies[1]
	end
	for _,p in sgs.list(self.room:getAlivePlayers()) do
		if not self:isFriend(p) then return p end
	end
end

-- Fixed inovation-ai.lua:67-73
sgs.ai_skill_playerchosen.xiyuan = function(self, targets)
	for _,p in ipairs(self.friends_noself) do
		if not general2(self,p) and self:isWeak(p) then return p end
		if p:hasSkill("se_diangong") then return p end
	end
	return self.friends_noself[1]
end

-- Fixed inovation-ai.lua:631-633
sgs.ai_skill_playerchosen.yuzhai = function(self, targets)
	return self:findPlayerToDiscard("he",false,true)
end

sgs.ai_use_priority.MapoTofu = 10
sgs.ai_use_value.MapoTofu = 8
sgs.ai_keep_value.MapoTofu = 1.0
sgs.ai_card_intention.MapoTofu = 0
sgs.ai_use_priority.KeyTrick = 3
sgs.ai_use_value.KeyTrick = 2
sgs.ai_keep_value.KeyTrick = 2
sgs.ai_card_intention.KeyTrick = -50
sgs.ai_use_value.InovationZhurenCard = 4
sgs.ai_use_priority.InovationZhurenCard  = 2.4
sgs.ai_card_intention.InovationZhurenCard  = -60
sgs.ai_use_value.DiangongCard = 8
sgs.ai_use_priority.DiangongCard = 2.5
sgs.ai_use_value.ZhilingCard = 9
sgs.ai_use_priority.ZhilingCard = 9.8
sgs.ai_card_intention.ZhilingCard  = 50
sgs.ai_skill_invoke.FukurouzaTaka = true
sgs.ai_skill_invoke.yuzhai = true
sgs.ai_use_value["TaxianCard"] = 8
sgs.ai_use_priority["TaxianCard"]  = 1
sgs.ai_card_intention["TaxianCard"] = 100
sgs.ai_use_value["NingjuCard"] = 8
sgs.ai_use_priority["NingjuCard"]  = 2
sgs.ai_card_intention["NingjuCard"] = 100
sgs.ai_skill_invoke.xingjian = true
sgs.ai_use_value["JiguanCard"] = 5
sgs.ai_use_priority["JiguanCard"]  = 8
sgs.ai_card_intention["JiguanCard"] = 0
sgs.ai_skill_choice["jiguan"] = "jiguan_put"
sgs.ai_skill_invoke.paoji = true
sgs.ai_skill_invoke.xinyang = true
sgs.inovation_SE_Maoqun_keep_value = {Peach=9,Analeptic=8,Jink=9}
end

-- R45 NEXT SLICE: six complete source SkillCard planner families.
do


local function seed(self,skill,class,costs,request)
 return self:evaluateTurnSkillCard(skill,class,costs,request)
end
local function ningju_slash(self)
 return self:evaluateOwnerViewAsCard({source_key="inovation.ningju",name="slash",skill="",suit=sgs.Card_NoSuit,number=0,subcards={}})
end
-- Fixed inovation-ai.lua:266-277
sgs.ai_fill_skill.diangong=function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	for _,enemy in ipairs(self.enemies) do
		if enemy:hasSkills("se_qidian|guangyu") then return end
	end
	for _,acard in ipairs(cards) do
		if self:getKeepValue(acard)<5 and acard:isBlack() then
			return seed(self,"diangong","DiangongCard",{},request)
		end
	end
end

-- Fixed inovation-ai.lua:161-167
sgs.ai_fill_skill.inovation_zhuren=function(self,inclusive,request)
	if #self.friends <= 1 then return end
	local source = self.player
	if source:isKongcheng() then return end
	if source:hasUsed("InovationZhurenCard") then return end
	return seed(self,"inovation_zhuren","InovationZhurenCard",{},request)
end

-- Fixed inovation-ai.lua:1001-1004
sgs.ai_fill_skill.jiguan=function(self,inclusive,request)
	if self.player:hasUsed("JiguanCard") then return end
	 return seed(self,"jiguan","JiguanCard",{},request)
end

-- Fixed inovation-ai.lua:778-786
sgs.ai_fill_skill.ningju=function(self,inclusive,request)
	if self.player:usedTimes("NingjuCard") >= 3 then return end
	if #self.enemies == 0 then return end
	local card = ningju_slash(self)
	for _,p in ipairs(self.enemies) do
		if not self:slashProhibit(card,p) and self:slashIsEffective(card,p) and self:damageIsEffective(p,sgs.DamageStruct_Normal,self.player) then return seed(self,"ningju","NingjuCard",{},request) end
	end
	return seed(self,"ningju","NingjuCard",{},request)
end

-- Fixed inovation-ai.lua:673-682
sgs.ai_fill_skill.taxian=function(self,inclusive,request)
	if self.player:hasUsed("TaxianCard") then return end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and self.player:inMyAttackRange(p) and not p:inMyAttackRange(self.player) then return seed(self,"taxian","TaxianCard",{},request) end
	end
	if self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 then return end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and self.player:inMyAttackRange(p) then return seed(self,"taxian","TaxianCard",{},request) end
	end
end

-- Fixed inovation-ai.lua:365-387
sgs.ai_fill_skill.zhiling=function(self,inclusive,request)
	if #self.enemies == 0 then return end
	if self.player:getPile("Neko"):length() == 0 then return end
	local can = false
	for _,enemy in ipairs(self.enemies) do
		if (enemy:getMark("@Neko_S") == 0 or enemy:getMark("@Neko_C") == 0 or (enemy:getMark("@Neko_D") == 0 and not enemy:hasSkill("Huansha")) or enemy:getMark("@Neko_H") == 0) and not enemy:hasFlag("Can_not") then
			can = true
		end
	end
	if self.player:getRole() =="renegade" then
		if #self.enemies - #self.friends <= 0 then
			can = false
		end
		if  self.player:getPile("Neko"):length() <=8 and #self.enemies - #self.friends <= 1 then
			can = false
		end
		if  self.player:getPile("Neko"):length() <=3 and #self.enemies - #self.friends <= 2 then
			can = false
		end
	end
	if not can then return end
	return seed(self,"zhiling","ZhilingCard",{},request)
end

-- Fixed inovation-ai.lua:279-304
sgs.ai_skill_use_func.DiangongCard = function(card,use,self)
	local target
	for _,enemy in sgs.list(self.room:getAlivePlayers()) do
		local pl = false
		for _,card in sgs.list(enemy:getJudgingArea()) do
			if card:isKindOf("Lightning") then
				pl = true
			end
		end
		if pl then
			target = enemy
		end
	end
	local needed
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _,acard in ipairs(cards) do
		if self:getKeepValue(acard)<5 and acard:isBlack() then
			needed = acard
		end
	end
	if target and needed then
		use.card = seed(self,"diangong","DiangongCard",{needed:getEffectiveId()})
		if use.to then use.to:append(target) end
		return
	end
end

-- Fixed inovation-ai.lua:169-200
sgs.ai_skill_use_func.InovationZhurenCard = function(card,use,self)
	local target
	local source = self.player
	local keys = 0
	for _,card in sgs.qlist(source:getJudgingArea()) do
		if card:isKindOf("KeyTrick") then
			keys = keys + 1
		end
	end
	local max_num = source:getMaxHp() - source:getHp() + keys
	local max_x = 0
	for _,friend in ipairs(self.friends) do
		local x = 5 - friend:getHandcardNum()

		if x > max_x and friend:objectName() ~= source:objectName() then
			max_x = x
			target = friend
		end
	end
	local cards=sgs.QList2Table(self.player:getHandcards())
	local needed = {}
	for _,acard in ipairs(cards) do
		if #needed < max_num then
			table.insert(needed, acard:getEffectiveId())
		end
	end
	if target and needed then
		use.card = seed(self,"inovation_zhuren","InovationZhurenCard",needed)
		if use.to then use.to:append(target) end
		return
	end
end

-- Fixed inovation-ai.lua:1006-1009
sgs.ai_skill_use_func.JiguanCard = function(card,use,self)
	use.card = card
	return
end

-- Fixed inovation-ai.lua:788-829
sgs.ai_skill_use_func.NingjuCard = function(card,use,self)
	local target
	if self.player:getMark("@waked") == 1 then
		for _,p in ipairs(self.enemies) do
			if not self:slashProhibit(card,p) and self:slashIsEffective(card,p) and self:damageIsEffective(p,sgs.DamageStruct_Normal,self.player) then
				target = p
				if self:isWeak(p) then
					break
				end
			end
		end
	else

		local max_effect_num = -200
		for _,p in ipairs(self.enemies) do
			if not self:slashProhibit(card,p) and self:slashIsEffective(card,p) and self:damageIsEffective(p,sgs.DamageStruct_Normal,self.player) then
				local effective_num = 0
				local ava_num = 0
				for _, q in sgs.list(self.room:getAlivePlayers()) do
					if q:inMyAttackRange(p) then

						if self:isFriend(q) then effective_num = effective_num + 1 end
						if self:isEnemy(q) then effective_num = effective_num - 3 end
						-- more?
						ava_num = ava_num + 1
					end
				end
				if ava_num == 1 then effective_num = 2.8 end
				if max_effect_num < effective_num then
					max_effect_num = effective_num
					target = p
				end
			end
		end
	end

	if target then
		use.card = seed(self,"ningju","NingjuCard",{})
		if use.to then use.to:append(target) end
		return
	end
end

-- Fixed inovation-ai.lua:684-706
sgs.ai_skill_use_func.TaxianCard = function(card,use,self)
	local targets = AIList.new({})
	for _,p in ipairs(self.enemies) do
		if self.player:inMyAttackRange(p) then
			--TODO if friend need maixie
			if not p:inMyAttackRange(self.player) then
				targets:append(p)
			elseif p:getHandcardNum() < 2 then
				targets:append(p)
			elseif self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0 then
				targets:append(p)
			elseif #targets == 2 then
				targets:append(p)
			end
		end
	end

	if targets:length() > 0 then
		use.card = seed(self,"taxian","TaxianCard",{})
		use.to = targets
		return
	end
end

-- Fixed inovation-ai.lua:389-407
sgs.ai_skill_use_func.ZhilingCard = function(card,use,self)
	local target
	local lord = self.room:getLord()
	for _,enemy in ipairs(self.enemies) do
		if (enemy:getMark("@Neko_S") == 0 or enemy:getMark("@Neko_C") == 0 or (enemy:getMark("@Neko_D") == 0 and not enemy:hasSkill("Huansha")) or enemy:getMark("@Neko_H") == 0) and not enemy:hasFlag("Can_not") then
			target = enemy
		end
	end
	if self.player:getRole() =="rebel" then
		if (lord and (lord:getMark("@Neko_S") == 0 or lord:getMark("@Neko_C") == 0 or (lord:getMark("@Neko_D") == 0 and not lord:hasSkill("Huansha")) or lord:getMark("@Neko_H") == 0) and not lord:hasFlag("Can_not")) then
			target = lord
		end
	end
	if target then
		use.card = seed(self,"zhiling","ZhilingCard",{})
		if use.to then use.to:append(target) end
		return
	end
end

end

-- R45 effective Inovation SmartAI bodies.
do
local providers={}


local function scalar(v,key)if v==nil then ai_unsupported("Inovation source fact unavailable",key)end return v end
local function turns(self)return scalar(self.world.turn_count,"turn_count")end
local function role(self,p)return self:getRoleEstimate(p)end
local function counts(self)return self:getRoleCounts()end
local function lord_healthy(self)
 local players=self:getCachedAlivePlayers()
 for _,p in ipairs(players)do
  if p:isLord()then
   local hp=p:getHp();if hp>4 and p:hasSkill("benghuai")then hp=4 end
   return hp>3 or hp>2 and self:getDefense(p)>3
  end
 end
 return true
end
local function clone_source_face(self,name,suit,number)
 return self:evaluateOwnerViewAsCard({source_key="inovation.skip_phase",name=name,skill="",suit=suit,number=number,subcards={}})
end
-- The donor's console-only diagnostics carry no decision input; this VM has no console sink.
local function diagnostic(self,key)end
-- Whether the Room VM defines the free global getPriorFriendsOfLiyu is not projected.
local function prior_friends(self)
 ai_unsupported("Room-VM global presence is not projected","getPriorFriendsOfLiyu")
end
local function source_hand(self,p)
 if p==self.player then return p:getHandcards()end
 local cards=p:getKnownCards()
 self:useKnowledgeEstimate({value=#cards,status="estimate",basis="inovation_jieyuan_visible_hand_only",viewer=self.player:objectName()},"canUseJieyuanDecrease")
 return cards
end
local function source_visible(self,card,p,flag)
 -- Reached only after the source computed its current-observer flag. The
 -- lawful viewer-known subset is explicit; no foreign hidden flag is queried.
 if p~=self.player then return true end
 return card:hasFlag("visible") or card:hasFlag(flag)
end
-- Fixed inovation-ai.lua:2035-2047
providers.canUseJieyuanDecrease = function(self, damage_from, player)
	if not damage_from then return false end
	local player = player or self.player
	if player:hasSkill("jieyuan") and damage_from:getHp() >= player:getHp() then
		for _, card in sgs.qlist(source_hand(self,player)) do
			local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), player:objectName())
			if player:objectName() == self.player:objectName() or source_visible(self,card,player,flag) then
				if card:isRed() and not isCard("Peach", card, player) then return true end
			end
		end
	end
	return false
end

-- Fixed inovation-ai.lua:1775-2033
providers.findLijianTarget = function(self, card_name, use)
	local lord = self.room:getLord()
	local duel = self:cloneEvaluationCard("duel")

	local findFriend_maxSlash = function(self, first)
		diagnostic(self,"lijian_looking")
		local maxSlash = 0
		local friend_maxSlash
		local nos_fazheng, fazheng
		for _, friend in ipairs(self.friends_noself) do
			if friend:isMale() and self:hasTrickEffective(duel,first,friend) then
				if friend:hasSkill("nosenyuan") and friend:getHp() > 1 then nos_fazheng = friend end
				if friend:hasSkill("enyuan") and friend:getHp() > 1 then fazheng = friend end
				if (getCardsNum("Slash", friend) > maxSlash) then
					maxSlash = getCardsNum("Slash", friend)
					friend_maxSlash = friend
				end
			end
		end

		if friend_maxSlash then
			local safe = false
			if self:hasSkills("neoganglie|vsganglie|fankui|enyuan|ganglie|nosenyuan",first) and not self:hasSkills("wuyan|noswuyan",first) then
				if (first:getHp() <= 1 and first:getHandcardNum() == 0) then safe = true end
			elseif (getCardsNum("Slash", friend_maxSlash) >= getCardsNum("Slash", first)) then safe = true end
			if safe then return friend_maxSlash end
		else diagnostic(self,"lijian_unfound")
		end
		if nos_fazheng or fazheng then  return nos_fazheng or fazheng end       --备用友方，各种恶心的法正
		return nil
	end

	if self.role == "rebel" or (self.role == "renegade" and counts(self)["loyalist"] + 1 > counts(self)["rebel"]) then

		if lord and lord:isMale() and not lord:isNude() and lord:objectName() ~= self.player:objectName() then      -- 优先离间1血忠和主
			self:sort(self.enemies,"handcard")
			local e_peaches = 0
			local loyalist

			for _, enemy in ipairs(self.enemies) do
				e_peaches = e_peaches + getCardsNum("Peach", enemy)
				if enemy:getHp() == 1 and self:hasTrickEffective(duel,enemy,lord) and enemy:objectName() ~= lord:objectName()
				and enemy:isMale() and not loyalist then
					loyalist = enemy
					break
				end
			end

			if loyalist and e_peaches < 1 then return loyalist, lord end
		end

		if #self.friends_noself >= 2 and self:getAllPeachNum() < 1 then     --收友方反
			local nextplayerIsEnemy
			local nextp = self.player:getNextAlive()
			for i = 1, self.room:alivePlayerCount() do
				if not self:willSkipPlayPhase(nextp) then
					if not self:isFriend(nextp) then nextplayerIsEnemy = true end
					break
				else
					nextp = nextp:getNextAlive()
				end
			end
			if nextplayerIsEnemy then
				local round = 50
				local to_die, nextfriend
				self:sort(self.enemies,"hp")

				for _, a_friend in ipairs(self.friends_noself) do   -- 目标1：寻找1血友方
					if a_friend:getHp() == 1 and a_friend:isKongcheng() and not self:hasSkills("kongcheng|yuwen",a_friend) and a_friend:isMale() then
						for _, b_friend in ipairs(self.friends_noself) do       --目标2：寻找位于我之后，离我最近的友方
							if b_friend:objectName() ~= a_friend:objectName() and b_friend:isMale() and self:playerGetRound(b_friend) < round
							and self:hasTrickEffective(duel,a_friend,b_friend) then

								round = self:playerGetRound(b_friend)
								to_die = a_friend
								nextfriend = b_friend

							end
						end
						if to_die and nextfriend then break end
					end
				end

				if to_die and nextfriend then return to_die, nextfriend end
			end
		end
	end

	if lord and self:isFriend(lord) and lord:hasSkill("hunzi") and lord:getHp() == 2 and lord:getMark("hunzi") == 0 and lord:objectName() ~= self.player:objectName() then
		local enemycount = self:getEnemyNumBySeat(self.player,lord)
		local peaches = self:getAllPeachNum()
		if peaches >= enemycount then
			local f_target, e_target
			for _, ap in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if ap:objectName() ~= lord:objectName() and ap:isMale() and self:hasTrickEffective(duel,lord,ap) then
					if self:hasSkills("jiang|nosjizhi|jizhi",ap) and self:isFriend(ap) and not ap:isLocked(duel) then
						if not use.isDummy then lord:setFlags("AIGlobal_NeedToWake") end
						return lord, ap
					elseif self:isFriend(ap) then
						f_target = ap
					else
						e_target = ap
					end
				end
			end
			if f_target or e_target then
				local target
				if f_target and not f_target:isLocked(duel) then
					target = f_target
				elseif e_target and not e_target:isLocked(duel) then
					target = e_target
				end
				if target then
					if not use.isDummy then lord:setFlags("AIGlobal_NeedToWake") end
					return lord, target
				end
			end
		end
	end

	local shenguanyu = self.room:findPlayerBySkillName("wuhun")
	if shenguanyu and shenguanyu:isMale() and shenguanyu:objectName() ~= self.player:objectName() then
		if self.role == "rebel" and lord and lord:isMale() and lord:objectName() ~= self.player:objectName() and not lord:hasSkill("jueqing") and self:hasTrickEffective(duel,shenguanyu,lord) then
			return shenguanyu, lord
		elseif self:isEnemy(shenguanyu) and #self.enemies >= 2 then
			for _, enemy in ipairs(self.enemies) do
				if enemy:objectName() ~= shenguanyu:objectName() and enemy:isMale() and not enemy:isLocked(duel)
					and self:hasTrickEffective(duel,shenguanyu,enemy) then
					return shenguanyu, enemy
				end
			end
		end
	end

	if not self.player:getStrategyHasUsed(card_name) then
		self:sort(self.enemies,"defense")
		local males, others = {}, {}
		local first, second
		local zhugeliang_kongcheng, xunyu

		for _, enemy in ipairs(self.enemies) do
			if enemy:isMale() and not enemy:hasSkills("wuyan|noswuyan") then
				if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then zhugeliang_kongcheng = enemy
				elseif enemy:hasSkill("jieming") then xunyu = enemy
				else
					for _, anotherenemy in ipairs(self.enemies) do
						if anotherenemy:isMale() and anotherenemy:objectName() ~= enemy:objectName() then
							if #males == 0 and self:hasTrickEffective(duel,enemy,anotherenemy) then
								if not (enemy:hasSkill("hunzi") and enemy:getMark("hunzi") < 1 and enemy:getHp() == 2) then
									table.insert(males, enemy)
								else
									table.insert(others, enemy)
								end
							end
							if #males == 1 and self:hasTrickEffective(duel,males[1],anotherenemy) then
								if not anotherenemy:hasSkills("nosjizhi|jizhi|jiang") then
									table.insert(males, anotherenemy)
								else
									table.insert(others, anotherenemy)
								end
								if #males >= 2 then break end
							end
						end
					end
				end
				if #males >= 2 then break end
			end
		end

		if #males >= 1 and role(self,males[1]) == "rebel" and males[1]:getHp() == 1 then
			if lord and self:isFriend(lord) and lord:isMale() and lord:objectName() ~= males[1]:objectName() and self:hasTrickEffective(duel,males[1],lord)
				and not lord:isLocked(duel) and lord:objectName() ~= self.player:objectName() and lord:isAlive()
				and (getCardsNum("Slash", males[1]) < 1
					or getCardsNum("Slash", males[1]) < getCardsNum("Slash", lord)
					or self:getKnownNum(males[1]) == males[1]:getHandcardNum() and getKnownCard(males[1], self.player, "Slash", true, "he") == 0)
				then
				return males[1], lord
			end

			local afriend = findFriend_maxSlash(self, males[1])
			if afriend and afriend:objectName() ~= males[1]:objectName() then
				return males[1], afriend
			end
		end

		if #males == 1 then
			if isLord(males[1]) and turns(self) <= 1 and self.role == "rebel" and self.player:aliveCount() >= 3 then
				local p_slash, max_p, max_pp = 0
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if p:isMale() and not self:isFriend(p) and p:objectName() ~= males[1]:objectName() and self:hasTrickEffective(duel,males[1],p) and not p:isLocked(duel)
						and p_slash < getCardsNum("Slash", p) then
						if p:getKnownKingdom() == males[1]:getKingdom() then
							max_p = p
							break
						elseif not max_pp then
							max_pp = p
						end
					end
				end
				if max_p then table.insert(males, max_p) end
				if max_pp and #males == 1 then table.insert(males, max_pp) end
			end
		end

		if #males == 1 then
			if #others >= 1 and not others[1]:isLocked(duel) then
				table.insert(males, others[1])
			elseif xunyu and not xunyu:isLocked(duel) then
				if getCardsNum("Slash", males[1]) < 1 then
					table.insert(males, xunyu)
				else
					local drawcards = 0
					for _, enemy in ipairs(self.enemies) do
						local x = enemy:getMaxHp() > enemy:getHandcardNum() and math.min(5, enemy:getMaxHp() - enemy:getHandcardNum()) or 0
						if x > drawcards then drawcards = x end
					end
					if drawcards <= 2 then
						table.insert(males, xunyu)
					end
				end
			end
		end

		if #males == 1 and #self.friends_noself > 0 then
			self:log("Only 1")
			first = males[1]
			if zhugeliang_kongcheng and self:hasTrickEffective(duel,first,zhugeliang_kongcheng) then
				table.insert(males, zhugeliang_kongcheng)
			else
				local friend_maxSlash = findFriend_maxSlash(self, first)
				if friend_maxSlash then table.insert(males, friend_maxSlash) end
			end
		end

		if #males >= 2 then
			first = males[1]
			second = males[2]
			if lord and first:getHp() <= 1 then
				if self.player:isLord() or self:isRolePredictable() then
					local friend_maxSlash = findFriend_maxSlash(self, first)
					if friend_maxSlash then second = friend_maxSlash end
				elseif lord:isMale() and not self:hasSkills("wuyan|noswuyan",lord) then
					if self.role=="rebel" and not first:isLord() and self:hasTrickEffective(duel,first,lord) then
						second = lord
					else
						if ( (self.role == "loyalist" or self.role == "renegade") and not self:hasSkills("ganglie|enyuan|neoganglie|nosenyuan",first) )
							and ( getCardsNum("Slash", first) <= getCardsNum("Slash", second) ) then
							second = lord
						end
					end
				end
			end

			if first and second and first:objectName() ~= second:objectName() and not second:isLocked(duel) then
				return first, second
			end
		end
	end
end

-- Fixed inovation-ai.lua:1585-1595
providers.getJijiangSlashNum = function(self, player)
	if not player then diagnostic(self,"jijiang_traceback") return 0 end
	if not player:hasLordSkill("jijiang") then return 0 end
	local slashs = 0
	for _, p in sgs.qlist(self.room:getLieges("shu",player)) do
		if (turns(self) <= 1 and role(self,p) == "neutral") or self:isFriend(player,p) then
			slashs = slashs + getCardsNum("Slash", p, self.player)
		end
	end
	return slashs
end

-- Fixed inovation-ai.lua:1730-1773
providers.getLijianCard = function(self)
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")

	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getKnownEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not acard:isKindOf("Peach") then
					card_id = acard:getKnownEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getKnownEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				  and not acard:isKindOf("Peach") then
					card_id = acard:getKnownEffectiveId()
					break
				end
			end
		end
	end
	return card_id
end

-- Fixed inovation-ai.lua:1614-1672
providers.getWoundedFriend = function(self, maleOnly, include_self)
	local friends = include_self and self.friends or self.friends_noself
	self:sort(friends,"hp")
	local list1 = {}    -- need help
	local list2 = {}    -- do not need help
	local addToList = function(p,index)
		if ( (not maleOnly) or (maleOnly and p:isMale()) ) and p:isWounded() then
			table.insert(index ==1 and list1 or list2, p)
		end
	end

	local getCmpHp = function(p)
		local hp = p:getHp()
		if p:isLord() and self:isWeak(p) then hp = hp - 10 end
		if p:objectName() == self.player:objectName() and self:isWeak(p) and p:hasSkill("qingnang") then hp = hp - 5 end
		if p:hasSkill("buqu") and p:getPile("buqu"):length() > 0 then hp = hp + math.max(0, 5 - p:getPile("buqu"):length()) end
		if p:hasSkill("nosbuqu") and p:getPile("nosbuqu"):length() > 0 then hp = hp + math.max(0, 5 - p:getPile("nosbuqu"):length()) end
		if p:hasSkills("nosrende|rende|kuanggu|kofkuanggu|zaiqi") and p:getHp() >= 2 then hp = hp + 5 end
		return hp
	end


	local cmp = function (a, b)
		if getCmpHp(a) == getCmpHp(b) then
			return self:getDefenseSlash(a) < self:getDefenseSlash(b)
		else
			return getCmpHp(a) < getCmpHp(b)
		end
	end

	for _, friend in ipairs(friends) do
		if friend:isLord() then
			if friend:getMark("hunzi") == 0 and friend:hasSkill("hunzi")
					and self:getEnemyNumBySeat(self.player,friend) <= (friend:getHp()>= 2 and 1 or 0) then
				addToList(friend, 2)
			elseif self:needToLoseHp(friend,nil,nil,true,true) then
				addToList(friend, 2)
			elseif not lord_healthy(self) then
				addToList(friend, 1)
			end
		else
			if self:needToLoseHp(friend,nil,nil,nil,true) or (self:hasSkills("rende|kuanggu|zaiqi",friend) and friend:getHp() >= 2) then
				addToList(friend, 2)
			else
				addToList(friend, 1)
			end
		end
	end
	if #list2 > 0 then
		for _, p in ipairs(list2) do
			if table.contains(list1, p) then
				table.removeOne(list2, p)
			end
		end
	end
	table.sort(list1, cmp)
	table.sort(list2, cmp)
	return list1, list2
end

-- Fixed inovation-ai.lua:1674-1728
providers.hasLiyuEffect = function(self, target, slash)
	local upperlimit = tonumber(self.player:hasSkill("wushuang") and 2 or 1)
	if #self.friends_noself == 0 or self.player:hasSkill("jueqing") then return false end
	if not self:slashIsEffective(slash,target,self.player) then return false end

	local targets = { target }
	if not self.player:hasSkill("jueqing") and target:isChained() and slash:isKindOf("NatureSlash") then
		for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
			if p:isChained() and p:objectName() ~= self.player:objectName() then table.insert(targets, p) end
		end
	end
	local unsafe = false
	for _, p in ipairs(targets) do
		if self:isEnemy(target) and not target:isNude() then
			unsafe = true
			break
		end
	end
	if not unsafe then return false end

	local duel = self:cloneEvaluationCard("duel")
	if self.player:isLocked(duel) then return false end

	local enemy_null = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) then enemy_null = enemy_null - getCardsNum("Nullification", p, self.player) end
		if self:isEnemy(p) then enemy_null = enemy_null + getCardsNum("Nullification", p, self.player) end
	end
	enemy_null = enemy_null - self:getCardsNum("Nullification")
	if enemy_null <= -1 then return false end

	local prior_friends = prior_friends(self)
	if #prior_friends == 0 then return false end
	for _, friend in ipairs(prior_friends) do
		if self:hasTrickEffective(duel,friend,self.player) and self:isWeak(friend) and (getCardsNum("Slash", friend, self.player) < upperlimit or self:isWeak()) then
			return true
		end
	end

	if sgs.isJinkAvailable(self.player, target, slash) and getCardsNum("Jink", target, self.player) >= upperlimit
		and not self:needToLoseHp(target,self.player,true) and not self:getDamagedEffects(target,self.player,true) then return false end
	if slash:hasFlag("AIGlobal_KillOff") or (target:getHp() == 1 and self:isWeak(target) and self:getSaveNum() < 1) then return false end

	if self.player:hasSkill("wumou") and self.player:getMark("@wrath") == 0 and (self:isWeak() or not self.player:hasSkill("zhaxiang")) then return true end
	if self.player:hasSkills("jizhi|nosjizhi") or (self.player:hasSkill("jilve") and self.player:getMark("@bear") > 0) then return false end
	if not string.startsWith(self.room:getMode(), "06_") and not sgs.GetConfig("EnableHegemony", false) and self.role ~= "rebel" then
		for _, friend in ipairs(self.friends_noself) do
			if self:hasTrickEffective(duel,friend,self.player) and self:isWeak(friend) and (getCardsNum("Slash", friend, self.player) < upperlimit or self:isWeak())
				and self:getSaveNum(true) < 1 then
				return true
			end
		end
	end
	return false
end

-- Fixed inovation-ai.lua:1598-1612
providers.isValuableCard = function(self, card, player)
	player = player or self.player
	if (isCard("Peach", card, player) and getCardsNum("Peach", player, self.player) <= 2)
		or (self:isWeak(player) and isCard("Analeptic", card, player))
		or (player:getPhase() ~= sgs.Player_Play
			and ((isCard("Nullification", card, player) and getCardsNum("Nullification", player, self.player) < 2 and player:hasSkills("jizhi|nosjizhi|jilve"))
				or (isCard("Jink", card, player) and getCardsNum("Jink", player, self.player) < 2)))
		or (player:getPhase() == sgs.Player_Play and isCard("ExNihilo", card, player) and not player:isLocked(card)) then
		return true
	end
	local dangerous = self:getDangerousCard(player)
	if dangerous and card:getKnownEffectiveId() == dangerous then return true end
	local valuable = self:getValuableCard(player)
	if valuable and card:getKnownEffectiveId() == valuable then return true end
end

-- Fixed inovation-ai.lua:1515-1523
providers.resetCards = function(self, cards, except)
	local result = {}
	for _, c in ipairs(cards) do
		if c:getKnownEffectiveId() ~= except:getKnownEffectiveId() then
			table.insert(result, c)
		end
	end
	return result
end

-- Fixed inovation-ai.lua:1525-1583
providers.shouldUseRende = function(self)
	if (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0) and self:getCardsNum("Slash") > 0 then
		self:sort(self.enemies,"defense")
		for _, enemy in ipairs(self.enemies) do
			local inAttackRange = self.player:distanceTo(enemy) == 1 or self.player:distanceTo(enemy) == 2
									and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse()
			if inAttackRange and self:isGoodTarget(enemy,self.enemies) then
				local slashs = self:getCards("Slash")
				local slash_count = 0
				for _, slash in ipairs(slashs) do
					if not self:slashProhibit(slash,enemy) and self:slashIsEffective(slash,enemy) then
						slash_count = slash_count + 1
					end
				end
				if slash_count >= enemy:getHp() then return false end
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:canSlash(self.player) and not self:slashProhibit(nil,self.player,enemy) then
			if enemy:hasWeapon("guding_blade") and self.player:getHandcardNum() == 1 and getCardsNum("Slash", enemy) >= 1 then
				return
			elseif self:hasCrossbowEffect(enemy) and getCardsNum("Slash", enemy) > 1 and self:getOverflow() <= 0 then
				return
			end
		end
	end
	for _, player in ipairs(self.friends_noself) do
		if (player:hasSkill("haoshi") and not player:containsTrick("supply_shortage")) or player:hasSkill("jijiu") then
			return true
		end
	end
	local keepNum = 1
	if self.player:getMark("rende") == 0 and self:getNosRendeGiven() == 0 then
		if self.player:getHandcardNum() == 3 then
			keepNum = 0
		end
		if self.player:getHandcardNum() > 3 then
			keepNum = 3
		end
	end
	if self.player:hasSkill("kongcheng") then
		keepNum = 0
	end
	if self:getOverflow() > 0  then
		return true
	end
	if self.player:getHandcardNum() > keepNum  then
		return true
	end
	if self.player:getMark("rende") ~= 0 and self.player:getMark("rende") < 2
		and (2 - self.player:getMark("rende")) >=  (self.player:getHandcardNum() - keepNum) then
		return true
	end
	if self:getNosRendeGiven() ~= 0 and self:getNosRendeGiven() < 2
		and (2 - self:getNosRendeGiven()) >=  (self.player:getHandcardNum() - keepNum) then
		return true
	end
end

-- Fixed inovation-ai.lua:1488-1513
providers.willSkipDrawPhase = function(self, player, NotContains_Null)
	local player = player or self.player
	local friend_null = 0
	local friend_snatch_dismantlement = 0
	local cp = self.room:getCurrent()
	if not NotContains_Null then
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if self:isFriend(p,player) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
			if self:isEnemy(p,player) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
		end
	end
	if cp and self.player:objectName() == cp:objectName() and self.player:objectName() ~= player:objectName() and self:isFriend(player) then
		for _, hcard in sgs.qlist(self.player:getCards("he")) do
			if (isCard("Snatch", hcard, self.player) and self.player:distanceTo(player) == 1) or isCard("Dismantlement", hcard, self.player) then
				local trick = clone_source_face(self,hcard:objectName(),hcard:getSuit(),hcard:getNumber())
				if self:hasTrickEffective(trick,player) then friend_snatch_dismantlement = friend_snatch_dismantlement + 1 end
			end
		end
	end
	if player:containsTrick("supply_shortage") then
		if player:containsTrick("YanxiaoCard") or self:hasSkills("shensu|jisu",player) or (player:hasSkill("qiaobian") and not player:isKongcheng()) then return false end
		if friend_null + friend_snatch_dismantlement > 1 then return false end
		return true
	end
	return false
end

-- Fixed inovation-ai.lua:1450-1486
providers.willSkipPlayPhase = function(self, player, NotContains_Null)
	local player = player or self.player

	if player:isSkipped(sgs.Player_Play) then return true end

	local fuhuanghou = self.room:findPlayerBySkillName("noszhuikong")
	if fuhuanghou and fuhuanghou:objectName() ~= player:objectName() and self:isEnemy(player,fuhuanghou)
		and fuhuanghou:isWounded() and fuhuanghou:getHandcardNum() > 1 and not player:isKongcheng() and not self:isWeak(fuhuanghou) then
		local max_card = self:getMaxCard(fuhuanghou)
		local player_max_card = self:getMaxCard(player)
		if (max_card and player_max_card and max_card:getNumber() > player_max_card:getNumber()) or (max_card and max_card:getNumber() >= 12) then return true end
	end

	local friend_null = 0
	local friend_snatch_dismantlement = 0
	local cp = self.room:getCurrent()
	if cp and self.player:objectName() == cp:objectName() and self.player:objectName() ~= player:objectName() and self:isFriend(player) then
		for _, hcard in sgs.qlist(self.player:getCards("he")) do
			if (isCard("Snatch", hcard, self.player) and self.player:distanceTo(player) == 1) or isCard("Dismantlement", hcard, self.player) then
				local trick = clone_source_face(self,hcard:objectName(),hcard:getSuit(),hcard:getNumber())
				if self:hasTrickEffective(trick,player) then friend_snatch_dismantlement = friend_snatch_dismantlement + 1 end
			end
		end
	end
	if not NotContains_Null then
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if self:isFriend(p,player) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
			if self:isEnemy(p,player) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
		end
	end
	if player:containsTrick("Indulgence") then
		if player:containsTrick("YanxiaoCard") or self:hasSkills("keji|conghui",player) or (player:hasSkill("qiaobian") and not player:isKongcheng()) then return false end
		if friend_null + friend_snatch_dismantlement > 1 then return false end
		return true
	end
	return false
end

-- Exact callable identities remain available to the central known-nil guard.
for name,provider in pairs(providers)do SmartAIView["inovation_"..name]=provider end
-- The donor file replaced these SmartAI methods when it loaded; this file loads in
-- the same package order, so a later package that redefines one still wins.
for name,provider in pairs(providers)do SmartAIView[name]=provider end
end

-- R45 Inovation current-question callbacks using existing lawful DTOs.
do


local function visible_card(self,id)
 local c=self:getKnownCardById(id)
 if not c then ai_unsupported("Faka moved-card face is not lawfully disclosed","inovation.faka.face")end
 return c
end
-- Fixed inovation-ai.lua:210-237
sgs.ai_skill_choice.inovation_Daolu = function(self, choices, data)
	local lord = self.room:getLord()
	if self.player:getKnownRole() == "lord" then
		for _,friend in ipairs(self.friends) do
			if self:isWeak(friend) and friend:objectName() ~= self.player:objectName() then
				return "Fuko_summoner"
			end
		end
		return "inovation_Nagisa_Protector"
	elseif self.player:getKnownRole() == "loyalist" then
		return "Tomoyo_Couple"
	elseif self.player:getKnownRole() == "rebel" then
		for _,friend in ipairs(self.friends) do
			if self:isWeak(friend) and self.player:getHp() > 2 and friend:objectName() ~= self.player:objectName() then
				if #self.friends > #self.enemies then
					return "Fuko_summoner"
				end
			end
			--TODO
		end
		return "inovation_Nagisa_Protector"
	elseif self.player:getKnownRole() == "renegade" then
		if lord and lord:getHp() <= 2 then
			return "Fuko_summoner"
		end
		return "inovation_Nagisa_Protector"
	end
end

-- Fixed inovation-ai.lua:740-760
sgs.ai_skill_invoke.faka = function(self, data)
	local move = data:toMoveOneTime()
	local value = move.card_ids:length()
	if move.from then
		if not self:isEnemy(self.room:getCurrent()) and not self:isEnemy(move.from) then return false end
	else
		if not self:isEnemy(self.room:getCurrent()) then return false end
	end


	for _,id in sgs.list(move.card_ids) do
		if (visible_card(self,id)):isKindOf("Peach") then
			value = value - 2
		end
		if (visible_card(self,id)):isKindOf("Analeptic") then
			value = value - 1.5
		end
	end
	if value >= 1 then return true end
	return false
end

-- Fixed inovation-ai.lua:762-771
sgs.ai_skill_playerchosen.faka = function(self, targets)

	for _,p in sgs.list(targets) do
		if self:isEnemy(p) then return p end
	end
	for _,p in sgs.list(targets) do
		if not self:isFriend(p) then return p end
	end
	return targets:first()
end

-- Fixed inovation-ai.lua:1223-1226
sgs.ai_skill_invoke.shoushi = function(self, data)
	local use = data:toCardUse()
	return not use.card:isKindOf("ExNihilo") and not use.card:isKindOf("AmazingGrace") and not use.card:isKindOf("GodSalvation")
end

end

-- R45 complete fixed Inovation owner-material constructor policies.
do


local suits={spade=sgs.Card_Spade,club=sgs.Card_Club,heart=sgs.Card_Heart,diamond=sgs.Card_Diamond,no_suit=sgs.Card_NoSuit,no_suit_red=sgs.Card_NoSuitRed,no_suit_black=sgs.Card_NoSuitBlack}
local function spec(name,skill,suit,number,id)
 -- Fixed Card::Parse759–778: its only rank strings here come from native
 -- getNumberString. JOKER parses as zero; one-subcard getNumber then inherits.
 local ranks={A=1,J=11,Q=12,K=13,JOKER=0}
 local n=ranks[number]or tonumber(number)
 if suits[suit]==nil or n==nil or type(id)~='number'or id%1~=0 or id<0 then ai_unsupported('Inovation source printing is incomplete',skill)end
 return{name=name,skill=skill,suit=suits[suit],number=n,subcards={id}}
end
local function allowed(card)
 return card:isKindOf('TrickCard')and not card:isKindOf('AOE')and not card:isKindOf('GodSalvation')and not card:isKindOf('AmazingGrace')and not card:isKindOf('Collateral')
end
sgs.ai_view_as.touzhi=function(card,player,card_place)
 local suit=card:getSuitString();local number=card:getNumberString();local id=card:getKnownEffectiveId()
 if player:getPhase()~=sgs.Player_Play then return end
 if allowed(card)then return('slash:touzhi[%s:%s]=%d'):format(suit,number,id)end
end
sgs.ai_fill_skill.touzhi=function(self,inclusive,request)
 if #self.enemies<1 then return end
 local material
 for _,card in sgs.list(self.player:getHandcards())do if allowed(card)then material=card end end
 if not material then return end
 local suit=material:getSuitString();local number=material:getNumberString();local id=material:getKnownEffectiveId()
 return self:evaluateTurnConversion('touzhi','Slash',spec('slash','touzhi',suit,number,id),request)
end
local function readonly(self,s)
 local native={source_key=s.skill,name=s.name,skill=s.skill,suit=s.suit,number=s.number,subcards={s.subcards[1]}}
 return self:evaluateOwnerViewAsCard(native)
end
local function selected(self,card,s,target)
 -- A named @@ native skill inquiry is an activation, not a printed-card
 -- response expression. Use its exact six-field action scope only when the
 -- complete source simulation has selected this original material and target.
 local request=self:getSkillAction()
 if request:getActivationSkillName()~=s.skill then ai_unsupported('Inovation selected native question differs from source',s.skill)end
 local paid=self:bindSkillCard(s.skill,s.subcards,request)
 if paid:objectName()~=s.name or paid:getClassName()~='KeyTrick'
  or paid:getSuit()~=card:getSuit()or paid:getNumber()~=card:getNumber()
  or paid:getKnownSkillName(false)~=s.skill then ai_unsupported('Inovation selected native product changed source identity',s.skill)end
 local exact=paid:toCardSpec()
 if not AIValue.isList(exact.subcards)or #exact.subcards~=#s.subcards then ai_unsupported('Inovation selected native costs changed',s.skill)end
 for i,id in ipairs(s.subcards)do if exact.subcards[i]~=id then ai_unsupported('Inovation selected native cost order changed',s.skill)end end
 return{kind='use_card',card_spec=exact,targets={target}}
end
sgs.ai_skill_use['@@youjiao']=function(self,prompt,method)
 local material
 for _,card in sgs.list(self.player:getHandcards())do if card:isKindOf('BasicCard')and not card:isKindOf('Peach')then material=card end end
 if material then
  local suit=material:getSuitString();local number=material:getNumberString();local id=material:getKnownEffectiveId()
  local s=spec('key_trick','youjiao',suit,number,id);local card=readonly(self,s)
  local use={isDummy=true,to=AIList.new({})};self:useCardKeyTrick(card,use)
  if use.card and not use.to:isEmpty()then return selected(self,card,s,use.to:first():objectName())end
 end
end
sgs.ai_skill_use['@@guangyu']=function(self)
 local ctx=self:getDecisionContext();local row=ctx.inovation_guangyu
 if type(row)~='table'or row.known~=true or type(row.ids)~='table'then ai_unsupported('Guangyu exact current owner property is unavailable','guangyu')end
 for _,id in ipairs(row.ids)do
  local material=self:getKnownCardById(id)
  if not material then ai_unsupported('Guangyu source material face is not disclosed','guangyu')end
  if not self.player:isCardLimited(material,sgs.Card_MethodUse)then
   local suit=material:getSuitString();local number=material:getNumberString()
   local s=spec('key_trick','guangyu',suit,number,id);local card=readonly(self,s)
   local use={isDummy=true,to=AIList.new({})};self:useCardKeyTrick(card,use)
   if use.card and not use.to:isEmpty()then return selected(self,card,s,use.to:first():objectName())end
  end
 end
 return'.'
end
end

-- R45 NEXT SLICE: actual source Xinyang Room-tag writes, not plan substitution.
do

-- The donor passes its pick through the AI-only xinyang_judge_card Room tag;
-- the same owner answers both questions, so this viewer's memory carries it.
local function tag(self,op,id)
 if op=='write' then self:remember('inovation.xinyang_judge_card',id) return end
 local value=self:recall('inovation.xinyang_judge_card')
 if type(value)~='number'then ai_unsupported('Xinyang pick was not remembered','xinyang.tag')end
 self:remember('inovation.xinyang_judge_card',-1)
 return value
end
sgs.ai_skill_invoke.xinyang_judge = function(self,data)
 local judge=data:toJudge()
 if self:needRetrial(judge)then
  if self.player:getPile('xinyang'):length()==0 then return false end
  local cards_ids=sgs.QList2Table(self.player:getPile('xinyang'))
  local newList={}
  for _,id in ipairs(cards_ids)do newList[#newList+1]=self:getKnownCardById(id)end
  local id=self:getRetrialCardId(newList,judge)
  if id~=-1 then tag(self,'write',id);return true end
 end
 return false
end
sgs.ai_skill_askforag.xinyang=function(self,card_ids)
 local id=tag(self,'take',-1) -- read followed immediately by setTag(-1).
 if id~=-1 then return id end
 for _,value in sgs.list(card_ids)do if id==value then return id end end
 return card_ids[1]
end
end

-- R45 complete Shoushi choice/playerchosen source bodies; finite host state only.
do


local function manjuan(p)
 if type(hasManjuanEffect)~='function'then ai_unsupported('Shoushi global helper unavailable','hasManjuanEffect')end
 local v=hasManjuanEffect(p);if AIUnsupported.is(v)then error(v,0)end
 if v==nil then ai_unsupported('Shoushi global helper input unknown','hasManjuanEffect')end
 return v
end
-- The donor keeps both target slots on its SmartAI object; this viewer's memory
-- holds them (false = cleared slot).
local function save(self,slot,p)
 local row=self:recall('inovation.shoushi')
 if type(row)~='table'then row={}end
 row[slot]=p and p:objectName()or false
 self:remember('inovation.shoushi',row)
end
local function clone(self,card)
 -- Source has no intervening operation between cloneCard and setSkillName.
 local name=card:objectName();local suit=card:getSuit();local number=card:getNumber()
 return self:evaluateOwnerViewAsCard({source_key='shoushi',name=name,skill='shoushi',suit=suit,number=number,subcards={}})
end
local function dummy(use)
 local r={isDummy=true,to=AIList.new({}),current_targets={}}
 for _,p in sgs.list(use.to)do r.current_targets[#r.current_targets+1]=p:objectName()end
 return r
end
sgs.ai_skill_choice.shoushi=function(self,choices,data)
 local use=data:toCardUse()
 if use.card:isKindOf('ExNihilo')then
  local friend=self:findPlayerToDraw(false,2)
  if friend then save(self,'extra',friend);return'add'end
 elseif use.card:isKindOf('GodSalvation')then
  self:sort(self.enemies,'hp')
  for _,enemy in ipairs(self.enemies)do
   if enemy:isWounded()and self:hasTrickEffective(use.card,enemy,self.player)then save(self,'remove',enemy);return'remove'end
  end
 elseif use.card:isKindOf('AmazingGrace')then
  self:sort(self.enemies)
  for _,enemy in ipairs(self.enemies)do
   if self:hasTrickEffective(use.card,enemy,self.player)and not manjuan(enemy)and not self:needKongcheng(enemy,true)then save(self,'remove',enemy);return'remove'end
  end
 elseif use.card:isKindOf('AOE')then
  self:sort(self.friends_noself)
  local lord=self.room:getLord()
  if lord and lord:objectName()~=self.player:objectName()and self:isFriend(lord)and self:isWeak(lord)then save(self,'remove',lord);return'remove'end
  for _,friend in ipairs(self.friends_noself)do
   if self:hasTrickEffective(use.card,friend,self.player)then save(self,'remove',friend);return'remove'end
  end
 elseif use.card:isKindOf('Snatch')or use.card:isKindOf('Dismantlement')then
  local trick=clone(self,use.card);local d=dummy(use);self:useCardSnatchOrDismantlement(trick,d)
  if d.card and d.to:length()>0 then save(self,'extra',d.to:first());return'add'end
 elseif use.card:isKindOf('Slash')then
  local slash=clone(self,use.card);local d=dummy(use);self:useCardSlash(slash,d)
  if d.card and d.to:length()>0 then save(self,'extra',d.to:first());return'add'end
 else
  local d=dummy(use);self:useCardByClassName(use.card,d)
  if d.card and d.to:length()>0 then save(self,'extra',d.to:first());return'add'end
 end
 save(self,'extra',nil);save(self,'remove',nil);return'cancel'
end
sgs.ai_skill_playerchosen.shoushi=function(self,targets)
 local row=self:recall('inovation.shoushi')
 if type(row)~='table'then ai_unsupported('Shoushi choice was not remembered','shoushi.state')end
 -- Both slots empty: the donor only logs a console error and returns nil.
 local name=row.extra or row.remove
 if not name then return nil end
 return self.room:findPlayerByObjectName(name,true)
end
end

-- R45 Goutong: full source invoke, actual game-VM global move assignment prefix.
do

-- The ask's CardsMoveOneTimeStruct data is not projected into the decision context.
local function host(op)
 ai_unsupported('Goutong move data is not projected','goutong.move')
end
local function endpoint(self,key)
 local row=host('read')
 if row.source_nil==true then error('attempt to index a nil value',0)end
 local name=row[key];if name==false then return nil end
 if type(name)~='string'or name==''then ai_unsupported('Goutong public endpoint unknown',key)end
 return self.room:findPlayerByObjectName(name,true)
end
sgs.ai_skill_invoke.goutong=function(self,data)
 host('write') -- actual data:toMoveOneTime() copy and global source assignment
 if self.player:objectName()==(endpoint(self,'to')):objectName()then
  if endpoint(self,'from')and not self:isEnemy(endpoint(self,'from'))then return true end
  if endpoint(self,'from')then
   if self:isWeak(self.player)and not self:isWeak(endpoint(self,'from'))and (endpoint(self,'from')):getLostHp()==0 then return true end
  end
 else
  if endpoint(self,'to')and not self:isEnemy(endpoint(self,'to'))then return true end
  if endpoint(self,'to')then
   if self:isWeak(self.player)and not self:isWeak(endpoint(self,'to'))and (endpoint(self,'to')):getLostHp()==0 then return true end
  end
 end
 return false
end
end

-- R46 reachable fixed Inovation consumers. No alias for obsolete Discard questions.
do


local function sort_source(self,key,cards)
 local ordered=self[key](self,cards)
 if ordered~=nil and ordered~=cards then
  if not AIValue.isList(ordered)then ai_unsupported('Inovation sorted-copy result malformed',key)end
  for i=#cards,1,-1 do cards[i]=nil end
  for i,card in ipairs(ordered)do cards[i]=card end
 end
end
-- Not projected: the ningju_color Room tag, the donor VM's sgs.kaiqi_ag_type, and
-- the kaiqi Room player flags the donor's own discard callback reads (the isolated
-- AI cannot write them). Ningju's console diagnostics carry no decision input.
local function host(op,name)
 ai_unsupported('Inovation source state is not projected',op)
end
sgs.ai_skill_cardchosen.ningju=function(self,who,flags)
 local status=host('ningju_tag').value
 if type(status)~='string'then ai_unsupported('Ningju tag string unknown','ningju_color')end
 if not status then return nil end
 local need='Red'
 if status=='None'or status=='Mix'then return nil end
 -- RoomRoster::findFirstBySkill scans alive players in current-player order.
 -- A missing public skill fact is unknown, never a fabricated absent holder.
 local chiaki
 for _,player in ipairs(self.room:getAllPlayers(false))do
  if player:hasSkill('ningju')then chiaki=player;break end
  if player:areSkillsComplete()~=true then ai_unsupported('Ningju preceding holder skills incomplete','ningju.holder')end
 end
 if not chiaki then return nil end
 if (self:isEnemy(chiaki)and status=='Red')or(not self:isEnemy(chiaki)and status=='Black')then need='Black'end
 local cards=self.player:getHandcards()
 for _,card in sgs.list(self.player:getEquips())do cards:append(card)end
 cards=sgs.QList2Table(cards)
 sort_source(self,'sortByKeepValue',cards)
 if need=='Red'then
  host('ningju_red')
  for _,card in ipairs(cards)do if card:isRed()then return card:getKnownEffectiveId()end end
 else
  host('ningju_black')
  for _,card in ipairs(cards)do if card:isBlack()then return card:getKnownEffectiveId()end end
 end
 return nil
end
sgs.ai_skill_playerchosen.kaiqi=function(self,targets)
 if not self.player:hasFlag('kaiqi_self_used')then
  host('kaiqi_set_self')
  return self.player
 end
 for _,target in sgs.list(targets)do
  if self:isFriend(target)and not self:isWeak(target)then
   host('kaiqi_set_target',target:objectName());return target
  end
 end
 for _,target in sgs.list(targets)do
  if self:isFriend(target)then host('kaiqi_set_target',target:objectName());return target end
 end
end
sgs.ai_skill_askforag.kaiqi=function(self,card_ids)
 local selected={}
 for _,id in sgs.list(card_ids)do
  local card=self:getKnownCardById(id)
  local suit=card:getSuitString()
  local value=host('kaiqi_ag_scalar').value
  if type(value)~='string'then ai_unsupported('Kaiqi source scalar unknown','kaiqi_ag_type')end
  if suit==value then
   if card:isKindOf('ExNihilo')then return id end
   table.insert(selected,card)
  end
 end
 sort_source(self,'sortByUseValue',selected)
 if #selected>0 then return (selected[1]):getKnownId()end
 return card_ids[1]
end
end

-- R47 Xiedou: source Duel policy, selected native V2 authority.
do


 sgs.ai_fill_skill.xiedou=function(self,inclusive,request)
  if type(self.enemies)~='table'then ai_unsupported('Xiedou enemy list unknown','xiedou')end
  if #self.enemies<1 then return end
  if #self.player:getEquips()==0 then return end
  if self.player:hasFlag('XiedouUsed')then return end
  local needNum=self.player:getHandcardNum()-#self.player:getEquips()
  if needNum<=0 then return end
  local cards=sgs.QList2Table(self.player:getHandcards())
  local sorted=self:sortByUseValue(cards)
  if sorted~=nil and sorted~=cards then
   if not AIValue.isList(sorted)then ai_unsupported('Xiedou sorter result unknown','sortByUseValue')end
   for i=#cards,1,-1 do cards[i]=nil end
   for i,card in ipairs(sorted)do cards[i]=card end
  end
  local selected={table.unpack(cards,1,needNum)}
  local suit=(selected[1]):getSuitString()
  local number=(selected[1]):getNumberString()
  local suits={spade=sgs.Card_Spade,club=sgs.Card_Club,heart=sgs.Card_Heart,diamond=sgs.Card_Diamond,
   no_suit=sgs.Card_NoSuit,no_suit_red=sgs.Card_NoSuitRed,no_suit_black=sgs.Card_NoSuitBlack}
  local numbers={A=1,J=11,Q=12,K=13,JOKER=0}
  local ids={};for _,card in ipairs(selected)do ids[#ids+1]=card:getKnownEffectiveId()end
  -- Card::Parse uses toInt for JOKER; the clone may then derive its effective
  -- number from its sole subcard. Native projection preserves that distinction.
  return self:evaluateTurnConversion('xiedou','Duel',{
   name='duel',skill='xiedou',suit=suits[suit] or sgs.Card_NoSuit,
   number=numbers[number] or tonumber(number) or 0,subcards=ids},request)
 end
end
