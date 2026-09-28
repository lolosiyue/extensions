--==《三国 杀神附体——妖》==--
extension = sgs.Package("keyaobao", sgs.Package_GeneralPack)
local skills = sgs.SkillList()

-- TriggerSkillV2 can_trigger 的格式二回傳輔助：
-- 回傳 "name|name|..." 與 "owner|owner|..." 兩平行列表。
-- alive_only=false 時連已死亡持有者一併列出（findPlayersBySkillName 只搜活人，
-- 舊版憑標記結算的效果在持有者死亡後仍應結算）。
local function v2_owner_names(skill, room, alive_only)
	local skills_list, owners = {}, {}
	if alive_only then
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			owners[#owners + 1] = p:objectName()
		end
	else
		for _, p in sgs.qlist(room:getAllPlayers(true)) do
			if p:hasSkill(skill:objectName()) then owners[#owners + 1] = p:objectName() end
		end
	end
	for i = 1, #owners do
		skills_list[i] = skill:objectName()
	end
	if #owners == 0 then return false end
	return table.concat(skills_list, "|"), table.concat(owners, "|")
end



yaochangetupo = sgs.CreateTriggerSkill {
	name = "yaochangetupo",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:hasSkill("keyaotaiping")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaozhangjiao", false, true, player:getGeneral2Name()=="keyaozhangjiao", false)
			end
		end
		if (player:hasSkill("keyaobuhui")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaozhoutai", false, true, player:getGeneral2Name()=="keyaozhoutai", false)
			end
		end
		if (player:hasSkill("keyaozhabing")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaosimayi", false, true, player:getGeneral2Name()=="keyaosimayi", false)
			end
		end
		if (player:hasSkill("keyaoquwu")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaoxiaoqiao", false, true, player:getGeneral2Name()=="keyaoxiaoqiao", false)
			end
		end
		if (player:hasSkill("keyaoshidu")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaojiping", false, true, player:getGeneral2Name()=="keyaojiping", false)
			end
		end
		if (player:hasSkill("keyaoxieqin")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieyaochengyu", false, true, player:getGeneral2Name()=="keyaochengyu", false)
			end
		end
	end,
	priority = 5,
}
if not sgs.Sanguosha:getSkill("yaochangetupo") then skills:append(yaochangetupo) end




keyaozhangjiao = sgs.General(extension, "keyaozhangjiao$", "keyao", 3, true)

keyaotaiping = sgs.CreateViewAsSkillV2 {
	name = "keyaotaiping",
	n = 2,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player ~= nil
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasFlag("useyaotaiping")
	end,
	can_select_card = function(skill, request, to_select)
		local selected = request:getSelectedCardIds()
		for _, id in sgs.qlist(selected) do
			if sgs.Sanguosha:getCard(id):getSuit() ~= to_select:getSuit() then return false end
		end
		if selected:isEmpty() then
			return not to_select:isEquipped()
		elseif selected:length() == 1 then
			local card = sgs.Sanguosha:getCard(selected:first())
			if to_select:getSuit() == card:getSuit() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 2
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() == 2 then
			local cardA = sgs.Sanguosha:getCard(ids:at(0))
			local cardB = sgs.Sanguosha:getCard(ids:at(1))
			local suit = cardA:getSuit()
			if suit == sgs.Card_Heart then
				local aa = sgs.Sanguosha:cloneCard("archery_attack", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Spade then
				local aa = sgs.Sanguosha:cloneCard("savage_assault", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Diamond then
				local aa = sgs.Sanguosha:cloneCard("god_salvation", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Club then
				local aa = sgs.Sanguosha:cloneCard("amazing_grace", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
		end
	end,
}
keyaozhangjiao:addSkill(keyaotaiping)

keyaotaipingex = sgs.CreateTriggerSkillV2 {
	name = "#keyaotaipingex",
	events = { sgs.CardFinished },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.from and use.from:hasSkill("keyaotaiping")
			and table.contains(use.card:getSkillNames(), "keyaotaiping") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		room:setPlayerFlag(use.from, "useyaotaiping")
		return false
	end
}
keyaozhangjiao:addSkill(keyaotaipingex)

keyaotaipingextwo = sgs.CreateTriggerSkillV2 {
	name = "#keyaotaipingextwo",
	events = { sgs.EventPhaseEnd },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player:hasSkill("keyaotaiping") and player:getPhase() == sgs.Player_Play
			and player:hasFlag("useyaotaiping") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:setPlayerFlag(player, "-useyaotaiping")
		return false
	end
}
keyaozhangjiao:addSkill(keyaotaipingextwo)
extension:insertRelatedSkills("keyaotaiping", "#keyaotaipingex")
extension:insertRelatedSkills("keyaotaiping", "#keyaotaipingextwo")



keyaojiazi = sgs.CreateTriggerSkillV2 {
	name = "keyaojiazi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive and player:getHandcardNum() < player:getHp() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName())
	end,
	on_pay = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local cha = player:getHp() - player:getHandcardNum()
		player:drawCards(cha)
		return false
	end,
}
keyaozhangjiao:addSkill(keyaojiazi)

keyaotuzhong = sgs.CreatePhaseChangeSkill {
	name = "keyaotuzhong$",
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			if player:hasLordSkill(self:objectName()) and player:askForSkillInvoke(self:objectName()) then
				local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "yaotuzhong-ask",
					true, true)
				if target then
					local recover = sgs.RecoverStruct()
					recover.who = target
					room:recover(target, recover)
				end
				return true
			end
		end
		return false
	end
}
keyaozhangjiao:addSkill(keyaotuzhong)







keyaosimayi = sgs.General(extension, "keyaosimayi", "keyao", 3, true)

keyaozhabing = sgs.CreateTriggerSkillV2 {
	name = "keyaozhabing",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging, sgs.DamageInflicted },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart or change.to == sgs.Player_Finish then
				return skill:objectName()
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.to and damage.to:getMark("&keyaozhabing") > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging
			and ctx.original_data:toPhaseChange().to == sgs.Player_Finish then
			return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
		end
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		if event == sgs.DamageInflicted
			or (event == sgs.EventPhaseChanging
				and ctx.original_data:toPhaseChange().to == sgs.Player_Finish) then
			room:broadcastSkillInvoke(skill:objectName())
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				room:setPlayerMark(player, "&keyaozhabing", 0)
			elseif change.to == sgs.Player_Finish then
				room:loseHp(player, 1, true, player, skill:objectName())
				room:addPlayerMark(player, "&keyaozhabing")
			end
		elseif event == sgs.DamageInflicted then
			return true
		end
		return false
	end,
}
keyaosimayi:addSkill(keyaozhabing)



keyaoguimou = sgs.CreateTriggerSkillV2 {
	name = "keyaoguimou",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards },
	can_trigger = function(skill, event, room, player, data)
		local draw = data:toDraw()
		if draw.reason == "draw_phase" then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if player:getLostHp() > 0 then
			return player:askForSkillInvoke(skill:objectName())
		end
		return false
	end,
	on_pay = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local draw = ctx.original_data:toDraw()
		draw.num = draw.num + player:getLostHp()
		ctx.original_data:setValue(draw)
		return false
	end,
}
keyaosimayi:addSkill(keyaoguimou)


keyaozhoutai = sgs.General(extension, "keyaozhoutai", "keyao", 4, true)

keyaobuhui = sgs.CreateProhibitSkill {
	name = "keyaobuhui",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Slash"))
	end
}
keyaozhoutai:addSkill(keyaobuhui)





keyaoxiaoqiao = sgs.General(extension, "keyaoxiaoqiao", "keyao", 3, false)

keyaoquwuCard = sgs.CreateSkillCard {
	name = "keyaoquwuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return (#targets == 0) and (to_select:objectName() ~= player:objectName()) and
			(player:inMyAttackRange(to_select))
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:addPlayerMark(target, "&keyaoquwu")
		room:addPlayerMark(player, "useyaoquwu")
	end
}
--主技能
keyaoquwuVS = sgs.CreateViewAsSkillV2 {
	name = "keyaoquwu",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player ~= nil
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("#keyaoquwuCard")
	end,
	create_card = function(skill, request)
		return keyaoquwuCard:clone()
	end,
}

keyaoquwu = sgs.CreateTriggerSkillV2 {
	name = "keyaoquwu",
	events = { sgs.DrawNCards },
	frequency = sgs.Skill_Compulsory,
	view_as_skill = keyaoquwuVS,
	can_trigger = function(skill, event, room, player, data)
		if player:getMark("&keyaoquwu") <= 0 then return false end
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		return v2_owner_names(skill, room, false)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local victim = ctx.invoker
		local draw = ctx.original_data:toDraw()
		local los = victim:getMark("&keyaoquwu")
		for _, xq in sgs.qlist(room:getAllPlayers()) do
			if xq:getMark("useyaoquwu") > 0 then
				local num = xq:getMark("useyaoquwu")
				xq:drawCards(num)
				room:setPlayerMark(xq, "useyaoquwu", 0)
			end
		end
		draw.num = draw.num - los
		ctx.original_data:setValue(draw)
		room:setPlayerMark(victim, "&keyaoquwu", 0)
		return false
	end,
}
keyaoxiaoqiao:addSkill(keyaoquwu)


keyaotongque = sgs.CreateTriggerSkillV2 {
	name = "keyaotongque",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirming },
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.to:contains(player)
			and (use.card:isKindOf("Analeptic") or use.card:isKindOf("IronChain")) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local nullified_list = use.nullified_list
		table.insert(nullified_list, player:objectName())
		use.nullified_list = nullified_list
		ctx.original_data:setValue(use)
		return false
	end,
}
keyaoxiaoqiao:addSkill(keyaotongque)


keyaozhongshang = sgs.CreateTriggerSkillV2 {
	name = "keyaozhongshang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.BuryVictim },
	can_trigger = function(skill, event, room, player, data)
		return v2_owner_names(skill, room, true)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:addMaxCards(player, 1, false)
		return false
	end,
}
keyaoxiaoqiao:addSkill(keyaozhongshang)





keyaobianshi = sgs.General(extension, "keyaobianshi", "keyao", 3, false)


keyaojiahuo = sgs.CreateViewAsSkillV2 {
	name = "keyaojiahuo",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player ~= nil
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasFlag("usedyaojiahuo")
	end,
	can_select_card = function(skill, request, to_select)
		return request:getSelectedCardIds():isEmpty()
			and to_select:isBlack()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = sgs.Sanguosha:getCard(ids:first())
		local acard = sgs.Sanguosha:cloneCard("collateral", card:getSuit(), card:getNumber())
		acard:addSubcard(card:getId())
		acard:setSkillName(skill:objectName())
		return acard
	end,
}

keyaobianshi:addSkill(keyaojiahuo)

keyaojiahuoex = sgs.CreateTriggerSkillV2 {
	name = "#keyaojiahuoex",
	events = { sgs.CardFinished, },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.from and use.from:hasSkill("keyaojiahuo")
			and table.contains(use.card:getSkillNames(), "keyaojiahuo") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		room:setPlayerFlag(use.from, "usedyaojiahuo")
		return false
	end
}
keyaobianshi:addSkill(keyaojiahuoex)

keyaojiahuoextwo = sgs.CreateTriggerSkillV2 {
	name = "#keyaojiahuoextwo",
	events = { sgs.EventPhaseEnd },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player:hasSkill("keyaojiahuo") and player:getPhase() == sgs.Player_Play
			and player:hasFlag("usedyaojiahuo") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:setPlayerFlag(player, "-usedyaojiahuo")
		return false
	end
}
keyaobianshi:addSkill(keyaojiahuoextwo)



keyaoleimu = sgs.CreateTriggerSkillV2 {
	name = "keyaoleimu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.ConfirmDamage },
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.from and damage.from:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:sendCompulsoryTriggerLog(player, skill:objectName(), true)
		damage.nature = sgs.DamageStruct_Thunder
		ctx.original_data:setValue(damage)
		return false
	end,
}
keyaobianshi:addSkill(keyaoleimu)

keyaoyaohou = sgs.CreateTriggerSkillV2 {
	name = "keyaoyaohou",
	events = { sgs.Damaged },
	--global = true,
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		local from = damage.from
		if from and (from:getRole() == "lord") and (from:getGender() == sgs.General_Male) then
			return v2_owner_names(skill, room, true)
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local eny = ctx.invoker
		local choicelist = "mopai"
		if eny and eny:getCardCount(true) > 0 then
			choicelist = string.format("%s+%s", choicelist, "huode")
		end
		choicelist = string.format("%s+%s", choicelist, "cancel")
		local choice = room:askForChoice(player, skill:objectName(), choicelist, ctx.original_data)
		if choice == "cancel" then return false end
		ctx.choice = choice
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local eny = ctx.invoker
		if ctx.choice == "huode" and eny then
			local card_id = room:askForCardChosen(player, eny, "he", skill:objectName())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
			room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason,
				room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
		elseif ctx.choice == "mopai" then
			player:drawCards(1)
		end
		return false
	end,
}
keyaobianshi:addSkill(keyaoyaohou)


keyaojiping = sgs.General(extension, "keyaojiping", "keyao", 3)

keyaoshiduCard = sgs.CreateSkillCard {
	name = "keyaoshiduCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		if (#targets ~= 0) then return false end
		return (to_select:objectName() ~= player:objectName()) and
			(to_select:getMark("keyaoshidu" .. player:objectName()) == 0)
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:addPlayerMark(target, "keyaoshidu" .. player:objectName())
		room:addPlayerMark(target, "&keyaoshidu")
	end
}

keyaoshiduVS = sgs.CreateViewAsSkillV2 {
	name = "keyaoshidu",
	n = 1,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, to_select)
		--return not sgs.Self:isJilei(to_select)
		return request:getSelectedCardIds():isEmpty()
			and (to_select:getSuit() == sgs.Card_Spade)
			and (to_select:isKindOf("BasicCard") or to_select:isKindOf("EquipCard"))
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = keyaoshiduCard:clone()
		card:addSubcard(ids:first())
		return card
	end,
}

keyaoshidu = sgs.CreatePhaseChangeSkill {
	name = "keyaoshidu",
	view_as_skill = keyaoshiduVS,
	on_phasechange = function()
	end
}
keyaojiping:addSkill(keyaoshidu)

keyaoshidubuff = sgs.CreateTriggerSkillV2 {
	name = "#keyaoshidubuff",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Start then return false end
		if player:getMark("&keyaoshidu") <= 0 then return false end
		return v2_owner_names(skill, room, false)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local victim = ctx.invoker
		local x = victim:getMark("&keyaoshidu")
		for i = 0, x - 1, 1 do
			room:removePlayerMark(victim, "&keyaoshidu")
			local target
			local jipings = room:findPlayersBySkillName("keyaoshidu")
			for _, jiping in sgs.qlist(jipings) do
				if victim:getMark("keyaoshidu" .. jiping:objectName()) > 0 then
					target = jiping
					room:removePlayerMark(victim, "keyaoshidu" .. jiping:objectName())
					break
				end
			end
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|black"
			judge.good = true
			judge.play_animation = false
			judge.who = victim
			judge.reason = skill:objectName()
			room:judge(judge)
			if judge:isGood() then
				local log = sgs.LogMessage()
				log.type = "$keyaoshidulog"
				log.from = victim

				local damage = sgs.DamageStruct()

				damage.to = victim
				damage.damage = 1
				if target then
					log.from = target
					damage.from = target
				end
				room:sendLog(log)
				room:damage(damage)
			end
		end
		return false
	end,
}
keyaojiping:addSkill(keyaoshidubuff)
extension:insertRelatedSkills("keyaoshidu", "#keyaoshidubuff")


keyaogongdu = sgs.CreateViewAsSkillV2 {
	name = "keyaogongdu",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return false
		end
		if player:getPhase() == sgs.Player_NotActive then
			return string.find(request:getPattern() or "", "peach") ~= nil
		end
		return false
	end,
	can_select_card = function(skill, request, to_select)
		if request:getSelectedCardIds():isEmpty() then
			return to_select:isBlack() and not to_select:isEquipped()
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = sgs.Sanguosha:getCard(ids:first())
		local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
		peach:setSkillName(skill:objectName())
		peach:addSubcard(card:getId())
		return peach
	end,
}
keyaojiping:addSkill(keyaogongdu)

keyaoliandu = sgs.CreateTriggerSkillV2 {
	name = "keyaoliandu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.damage > 1 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		damage.damage = 1
		local log = sgs.LogMessage()
		log.type = "$yaojiping_damage"
		log.from = player
		room:sendLog(log)
		ctx.original_data:setValue(damage)
		return false
	end,
}
keyaojiping:addSkill(keyaoliandu)




keyaolingtong = sgs.General(extension, "keyaolingtong", "wu", 4)

keyaozhongyi = sgs.CreateTriggerSkillV2 {
	name = "keyaozhongyi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName()
			and move.from_places:contains(sgs.Player_PlaceHand)
			and move.is_last_handcard then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_pay = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:drawCards(player:getHp(), skill:objectName())
		return false
	end
}
keyaolingtong:addSkill(keyaozhongyi)


keyaochengyu = sgs.General(extension, "keyaochengyu", "wei", 3)

keyaoxieqin = sgs.CreateTriggerSkillV2 {
	name = "keyaoxieqin",
	events = { sgs.Damage },
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName()
			and player:getMark("canuseyaoxieqin_lun") == 0 then
			for _, p in sgs.qlist(room:getOtherPlayers(damage.to)) do
				if player:canDiscard(p, "he") then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(damage.to)) do
			if player:canDiscard(p, "he") then
				players:append(p)
			end
		end
		if players:isEmpty() then return false end
		local ano = room:askForPlayerChosen(player, players, skill:objectName(), "yaoxieqin-ask", true, true)
		if not ano then return false end
		ctx.extra_data:setValue(ano)
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		room:addPlayerMark(player, "keyaoxieqin_lun")
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local ano = ctx.extra_data:toPlayer()
		if ano and player:canDiscard(ano, "he") then
			local to_throw = room:askForCardChosen(player, ano, "he", skill:objectName())
			local card = sgs.Sanguosha:getCard(to_throw)
			room:throwCard(card, ano, player)
		end
		return false
	end,
}
keyaochengyu:addSkill(keyaoxieqin)

keyaoshiwei = sgs.CreateTriggerSkillV2 {
	name = "keyaoshiwei",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.StartJudge, sgs.FinishJudge },
	can_trigger = function(skill, event, room, player, data)
		return v2_owner_names(skill, room, true)
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.StartJudge then
			if not room:askForSkillInvoke(player, skill:objectName(), ctx.original_data) then
				return false
			end
			ctx.choice = room:askForChoice(player, skill:objectName(), "black+red")
			return true
		end
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		if event == sgs.StartJudge then
			room:broadcastSkillInvoke(skill:objectName())
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.StartJudge then
			if ctx.choice == "black" then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweiblacklog"
				log.from = player
				room:sendLog(log)
				room:setPlayerMark(player, "yaoshiweiblack", 1)
			elseif ctx.choice == "red" then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweiredlog"
				log.from = player
				room:sendLog(log)
				room:setPlayerMark(player, "yaoshiweired", 1)
			end
		elseif event == sgs.FinishJudge then
			local judge = ctx.original_data:toJudge()
			if (judge.card:isRed()) and (player:getMark("yaoshiweired") > 0) then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweiredyeslog"
				log.from = player
				room:sendLog(log)
				player:drawCards(1, skill:objectName())
			end
			if (judge.card:isBlack()) and (player:getMark("yaoshiweiblack") > 0) then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweiblackyeslog"
				log.from = player
				room:sendLog(log)
				player:drawCards(1, skill:objectName())
			end
			if (judge.card:isRed()) and (player:getMark("yaoshiweiblack") > 0) then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweiblacknolog"
				log.from = player
				room:sendLog(log)
			end
			if (judge.card:isBlack()) and (player:getMark("yaoshiweired") > 0) then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweirednolog"
				log.from = player
				room:sendLog(log)
			end
			room:setPlayerMark(player, "yaoshiweired", 0)
			room:setPlayerMark(player, "yaoshiweiblack", 0)
		end
		return false
	end,
}
keyaochengyu:addSkill(keyaoshiwei)




--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\-
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



kejieyaozhangjiao = sgs.General(extension, "kejieyaozhangjiao$", "keyao", 3, true)

kejieyaotaiping = sgs.CreateViewAsSkillV2 {
	name = "kejieyaotaiping",
	n = 2,
	response_or_use = true,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, to_select)
		local selected = request:getSelectedCardIds()
		for _, id in sgs.qlist(selected) do
			if sgs.Sanguosha:getCard(id):getSuit() ~= to_select:getSuit() then return false end
		end
		if selected:isEmpty() then
			return not to_select:isEquipped()
		elseif selected:length() == 1 then
			local card = sgs.Sanguosha:getCard(selected:first())
			if to_select:getSuit() == card:getSuit() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 2
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() == 2 then
			local cardA = sgs.Sanguosha:getCard(ids:at(0))
			local cardB = sgs.Sanguosha:getCard(ids:at(1))
			local suit = cardA:getSuit()
			if suit == sgs.Card_Heart then
				local aa = sgs.Sanguosha:cloneCard("archery_attack", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Spade then
				local aa = sgs.Sanguosha:cloneCard("savage_assault", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Diamond then
				local aa = sgs.Sanguosha:cloneCard("god_salvation", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
			if suit == sgs.Card_Club then
				local aa = sgs.Sanguosha:cloneCard("amazing_grace", suit, 0);
				aa:addSubcard(cardA)
				aa:addSubcard(cardB)
				aa:setSkillName("keyaotaiping")
				return aa
			end
		end
	end,
}
kejieyaozhangjiao:addSkill(kejieyaotaiping)


kejieyaojiazi = sgs.CreateTriggerSkillV2 {
	name = "kejieyaojiazi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive
			and player:getHandcardNum() < player:getMaxHp() then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local cha = player:getMaxHp() - player:getHandcardNum()
		if cha > 0 then
			room:broadcastSkillInvoke(skill:objectName())
		end
		player:drawCards(cha)
		return false
	end,
}
kejieyaozhangjiao:addSkill(kejieyaojiazi)


--[[kejieyaotuzhong = sgs.CreateTriggerSkill{
	name = "kejieyaotuzhong$" ,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.DrawNCards then
			local invoked = false
			if player:isSkipped(sgs.Player_Draw) then return false end
			invoked = player:askForSkillInvoke(self:objectName())
			if invoked then
				player:skip(sgs.Player_Draw)
				local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "yaotuzhong-ask", true, true)
				if target then
					room:recover(target, sgs.RecoverStruct())
					target:drawCards(1)
				end
			end			
		end
		return false
	end
}]]


kejieyaotuzhong = sgs.CreatePhaseChangeSkill {
	name = "kejieyaotuzhong$",
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			local invoked = false
			if player:hasLordSkill(self:objectName()) then
				invoked = player:askForSkillInvoke(self:objectName())
				if invoked then
					local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(),
						"yaotuzhong-ask", true, true)
					if target then
						room:recover(target, sgs.RecoverStruct())
						target:drawCards(1)
					end
					return true
				end
			end
		end
		return false
	end
}
kejieyaozhangjiao:addSkill(kejieyaotuzhong)




kejieyaosimayi = sgs.General(extension, "kejieyaosimayi", "keyao", 3, true)

kejieyaozhabing = sgs.CreateTriggerSkillV2 {
	name = "kejieyaozhabing",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging --[[,sgs.DamageInflicted]] },
	can_trigger = function(skill, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_RoundStart or change.to == sgs.Player_Finish then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if ctx.original_data:toPhaseChange().to == sgs.Player_Finish then
			return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
		end
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		if ctx.original_data:toPhaseChange().to == sgs.Player_Finish then
			room:broadcastSkillInvoke(skill:objectName())
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local change = ctx.original_data:toPhaseChange()
		if change.to == sgs.Player_RoundStart then
			room:setPlayerMark(player, "&keyaozhabing", 0)
		elseif change.to == sgs.Player_Finish then
			room:loseHp(player, 1, true, player, skill:objectName())
			room:addPlayerMark(player, "&keyaozhabing")
		end
		return false
	end,
}
kejieyaosimayi:addSkill(kejieyaozhabing)

kejieyaozhabingexjl = sgs.CreateDistanceSkillV2 {
	name = "kejieyaozhabingexjl",
	global = true,
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local to = ctx:getSecondary()
		if to and to:hasSkill("kejieyaozhabing") and (to:getMark("&keyaozhabing") > 0) then
			return to:getLostHp()
		else
			return false
		end
	end
}
if not sgs.Sanguosha:getSkill("kejieyaozhabingexjl") then skills:append(kejieyaozhabingexjl) end

kejieyaozhabingex = sgs.CreateProhibitSkill {
	name = "kejieyaozhabingex",
	global = true,
	is_prohibited = function(self, from, to, card)
		return (to:getMark("&keyaozhabing") > 0) and (card:isDamageCard())
	end
}
if not sgs.Sanguosha:getSkill("kejieyaozhabingex") then skills:append(kejieyaozhabingex) end



kejieyaoguimou = sgs.CreateTriggerSkillV2 {
	name = "kejieyaoguimou",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DrawNCards },
	can_trigger = function(skill, event, room, player, data)
		local draw = data:toDraw()
		if draw.reason == "draw_phase" then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local draw = ctx.original_data:toDraw()
		draw.num = draw.num + player:getLostHp()
		if player:isWounded() then
			room:broadcastSkillInvoke(skill:objectName())
			for _, id in sgs.qlist(room:getDrawPile()) do
				if (sgs.Sanguosha:getCard(id):isKindOf("TrickCard")) then
					room:obtainCard(player, id, true)
					break
				end
			end
		end
		ctx.original_data:setValue(draw)
		return false
	end,
}
kejieyaosimayi:addSkill(kejieyaoguimou)

kejieyaozhoutai = sgs.General(extension, "kejieyaozhoutai", "keyao", 5, true)

kejieyaobuhui = sgs.CreateProhibitSkill {
	name = "kejieyaobuhui",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Slash") or card:isKindOf("Peach"))
	end
}
kejieyaozhoutai:addSkill(kejieyaobuhui)

kejieyaofenwei = sgs.CreateTriggerSkillV2 {
	name = "kejieyaofenwei",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging, sgs.EventAcquireSkill },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if not player:hasSkill(skill:objectName()) then return false end
			if change.to == sgs.Player_NotActive then
				return skill:objectName()
			end
			if change.to == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&kejieyaofenwei") > 0 then
						return skill:objectName()
					end
				end
			end
			return false
		end
		if event == sgs.EventAcquireSkill
			and data:toSkillChange().skillName == "kejieyaobuhui" then
			return v2_owner_names(skill, room, true)
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local one = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(),
					"kejieyaofenwei-ask", true, true)
				if not one then return false end
				ctx.extra_data:setValue(one)
				return true
			end
			if change.to == sgs.Player_RoundStart then
				return room:askForSkillInvoke(player, "kejieyaofenwei_shouhui", ctx.original_data)
			end
			return false
		end
		if event == sgs.EventAcquireSkill then
			local dest = sgs.QVariant()
			dest:setValue(ctx.invoker)
			return room:askForSkillInvoke(player, "kejieyaofenwei_mopai", dest)
		end
		return false
	end,
	on_pay = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging
			and ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
			room:broadcastSkillInvoke(skill:objectName())
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local one = ctx.extra_data:toPlayer()
				room:handleAcquireDetachSkills(player, "-kejieyaobuhui")
				if one and not one:hasSkill("kejieyaobuhui") then
					room:handleAcquireDetachSkills(one, "kejieyaobuhui")
					room:addPlayerMark(one, "&kejieyaofenwei", 1)
				end
			elseif change.to == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&kejieyaofenwei") > 0 then
						room:removePlayerMark(p, "&kejieyaofenwei", 1)
						if p:hasSkill("kejieyaobuhui") then
							room:handleAcquireDetachSkills(p, "-kejieyaobuhui")
						end
						if not player:hasSkill("kejieyaobuhui") then
							room:handleAcquireDetachSkills(player, "kejieyaobuhui")
						end
					end
				end
			end
		elseif event == sgs.EventAcquireSkill then
			ctx.invoker:drawCards(1)
		end
		return false
	end,
}
kejieyaozhoutai:addSkill(kejieyaofenwei)



--界妖小乔

kejieyaoxiaoqiao = sgs.General(extension, "kejieyaoxiaoqiao", "keyao", 3, false)

kejieyaoquwuCard = sgs.CreateSkillCard {
	name = "kejieyaoquwuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return (#targets == 0) and (to_select:objectName() ~= player:objectName()) and
			(to_select:getMark("&kejieyaoquwu") == 0)
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:addPlayerMark(target, "&kejieyaoquwu")
		room:addPlayerMark(player, "usejieyaoquwu")
		room:removePlayerMark(player, "canusequwucishu", 1)
	end
}
--主技能
kejieyaoquwuVS = sgs.CreateViewAsSkillV2 {
	name = "kejieyaoquwu",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player ~= nil
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("canusequwucishu") > 0
	end,
	create_card = function(skill, request)
		return kejieyaoquwuCard:clone()
	end,
}


kejieyaoquwu = sgs.CreateTriggerSkillV2 {
	name = "kejieyaoquwu",
	events = { sgs.DrawNCards },
	frequency = sgs.Skill_Compulsory,
	view_as_skill = kejieyaoquwuVS,
	can_trigger = function(skill, event, room, player, data)
		if player:getMark("&kejieyaoquwu") <= 0 then return false end
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		return v2_owner_names(skill, room, false)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local victim = ctx.invoker
		local draw = ctx.original_data:toDraw()
		local los = victim:getMark("&kejieyaoquwu")
		for _, xq in sgs.qlist(room:getAllPlayers()) do
			if xq:getMark("usejieyaoquwu") > 0 then
				xq:drawCards(1)
				room:removePlayerMark(xq, "usejieyaoquwu", 1)
			end
		end
		draw.num = draw.num - los
		ctx.original_data:setValue(draw)
		room:setPlayerMark(victim, "&kejieyaoquwu", 0)
		return false
	end,
}
kejieyaoxiaoqiao:addSkill(kejieyaoquwu)


kejieyaotongque = sgs.CreateTriggerSkillV2 {
	name = "kejieyaotongque",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirming, sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.to:contains(player)
				and (use.card:isKindOf("Analeptic") or use.card:isKindOf("IronChain")) then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_Play then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.TargetConfirming then
			local use = ctx.original_data:toCardUse()
			if use.card:isKindOf("Analeptic") then
				room:addPlayerMark(player, "&jieyaoquwunum", 1)
				if player:getPhase() == sgs.Player_Play then
					room:addPlayerMark(player, "canusequwucishu", 1)
				end
			end
			local nullified_list = use.nullified_list
			table.insert(nullified_list, player:objectName())
			use.nullified_list = nullified_list
			ctx.original_data:setValue(use)
		elseif event == sgs.EventPhaseChanging then
			local num = player:getMark("&jieyaoquwunum") + 1
			room:setPlayerMark(player, "canusequwucishu", num)
		end
		return false
	end,
}
kejieyaoxiaoqiao:addSkill(kejieyaotongque)


kejieyaozhongshang = sgs.CreateTriggerSkillV2 {
	name = "kejieyaozhongshang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.BuryVictim },
	can_trigger = function(skill, event, room, player, data)
		return v2_owner_names(skill, room, true)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:addMaxCards(player, 1, false)
		room:recover(player, sgs.RecoverStruct())
		room:addPlayerMark(player, "&" .. skill:objectName())
		return false
	end,
}
kejieyaoxiaoqiao:addSkill(kejieyaozhongshang)



kejieyaoxiaoqiaotwo = sgs.General(extension, "kejieyaoxiaoqiaotwo", "keyao", 3, false)

kejieyaoquwutwo = sgs.CreateTriggerSkillV2 {
	name = "kejieyaoquwutwo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging, sgs.EventPhaseEnd },
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				room:setPlayerMark(player, "&quwutlcount", player:getHp())
				room:setPlayerMark(player, "&quwuspcount", player:getHandcardNum())
			elseif change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "&quwutlcount", 0)
				room:setPlayerMark(player, "&quwuspcount", 0)
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseEnd then return false end
		if player:getPhase() ~= sgs.Player_Play then return false end
		local tl = player:getHp()
		local sp = player:getHandcardNum()
		if tl == player:getMark("&quwutlcount") and sp == player:getMark("&quwuspcount") then
			return false
		end
		return v2_owner_names(skill, room, true)
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_pay = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local invoker = ctx.invoker
		player:drawCards(1)
		if invoker then
			local mz = 0
			if invoker:getHp() ~= invoker:getMark("&quwutlcount") then mz = mz + 1 end
			if invoker:getHandcardNum() ~= invoker:getMark("&quwuspcount") then mz = mz + 1 end
			if mz > 1 and not invoker:isChained() then
				room:setPlayerChained(invoker)
			end
		end
		return false
	end,
}
kejieyaoxiaoqiaotwo:addSkill(kejieyaoquwutwo)

kejieyaotongquetwo = sgs.CreateTriggerSkillV2 {
	name = "kejieyaotongquetwo",
	events = { sgs.DamageInflicted },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if ((damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("drank"))
			or damage.chain) and not player:isKongcheng() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if not room:askForSkillInvoke(player, skill:objectName(), ctx.original_data) then
			return false
		end
		return room:askForDiscard(player, skill:objectName(), 1, 1, true, false, "kejieyaotongquetwo-dis")
	end,
	on_pay = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke("kejieyaoquwutwo")
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:setPlayerProperty(player, "chained", sgs.QVariant(false))
		local death = sgs.DeathStruct()
		death.who = player
		death.damage = damage
		local _data = sgs.QVariant()
		_data:setValue(death)
		room:getThread():delay(500)
		room:getThread():trigger(sgs.QuitDying, room, player, _data)
		local hurt = damage.damage
		if hurt == 1 then
			return true
		end
		if hurt > 1 then
			damage.damage = hurt - 1
			ctx.original_data:setValue(damage)
		end
		return false
	end
}
kejieyaoxiaoqiaotwo:addSkill(kejieyaotongquetwo)

kejieyaozhongshangtwo = sgs.CreateTriggerSkillV2 {
	name = "kejieyaozhongshangtwo",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.QuitDying },
	can_trigger = function(skill, event, room, player, data)
		return v2_owner_names(skill, room, true)
	end,
	on_cost = function(skill, event, room, player, ctx)
		ctx.choice = room:askForChoice(player, skill:objectName(), "maxhp+handmax")
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if ctx.choice == "maxhp" then
			room:recover(player, sgs.RecoverStruct())
		elseif ctx.choice == "handmax" then
			room:addPlayerMark(player, "&kejieyaozhongshangtwo")
		end
		return false
	end,
}
kejieyaoxiaoqiaotwo:addSkill(kejieyaozhongshangtwo)

kejieyaozhongshangtwokeep = sgs.CreateMaxCardsSkillV2 {
	name = "kejieyaozhongshangtwokeep",
	frequency = sgs.Skill_Compulsory,
	global = true,
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local target = ctx:getPrimary()
		if target and target:getMark("&kejieyaozhongshangtwo") > 0 then
			return target:getMark("&kejieyaozhongshangtwo")
		else
			return false
		end
	end
}
if not sgs.Sanguosha:getSkill("kejieyaozhongshangtwokeep") then skills:append(kejieyaozhongshangtwokeep) end





--界妖吉平

kejieyaojiping = sgs.General(extension, "kejieyaojiping", "keyao", 3)

kejieyaoshiduCard = sgs.CreateSkillCard {
	name = "kejieyaoshiduCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		if (#targets ~= 0) then return false end
		return (to_select:objectName() ~= player:objectName()) and (to_select:getMark("&keyaoshidu") == 0)
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:addPlayerMark(target, "&kejieyaoshidu")
		room:addPlayerMark(target, "kejieyaoshidu" .. player:objectName())
	end
}

kejieyaoshiduVS = sgs.CreateViewAsSkillV2 {
	name = "kejieyaoshidu",
	n = 1,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, to_select)
		return request:getSelectedCardIds():isEmpty()
			and (to_select:isKindOf("BasicCard") or to_select:isKindOf("EquipCard"))
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = kejieyaoshiduCard:clone()
		card:addSubcard(ids:first())
		return card
	end,
}


kejieyaoshidu = sgs.CreateTriggerSkillV2 {
	name = "kejieyaoshidu",
	frequency = sgs.Skill_Compulsory,
	view_as_skill = kejieyaoshiduVS,
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Start then return false end
		if player:getMark("&kejieyaoshidu") <= 0 then return false end
		return v2_owner_names(skill, room, false)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local victim = ctx.invoker
		for _, mark in sgs.list(victim:getMarkNames()) do
			if string.find(mark, "kejieyaoshidu") and victim:getMark(mark) > 0 then
				local target
				room:removePlayerMark(victim, mark)
				local jipings = room:findPlayersBySkillName("kejieyaoshidu")
				for _, jiping in sgs.qlist(jipings) do
					if string.find(mark, jiping:objectName()) then
						target = jiping
						break
					end
				end
				if target then
					room:sendCompulsoryTriggerLog(target, skill:objectName())
				else
					room:sendCompulsoryTriggerLog(victim, skill:objectName())
				end

				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.play_animation = false
				judge.who = victim
				judge.reason = skill:objectName()
				room:judge(judge)
				local suit = judge.card:getSuit()
				local damage = sgs.DamageStruct()
				damage.from = nil
				damage.to = victim
				if target then
					damage.from = target
				end
				if (suit == sgs.Card_Club) or (suit == sgs.Card_Diamond) then
					damage.damage = 1
				elseif suit == sgs.Card_Spade then
					damage.damage = 2
				end
				local log = sgs.LogMessage()
				log.type = "$keyaoshidulog"
				log.from = target
				room:sendLog(log)
				if suit == sgs.Card_Heart then
					if target then target:drawCards(1) end
				else
					room:damage(damage)
				end
			end
		end
		room:setPlayerMark(victim, "&kejieyaoshidu", 0)
		return false
	end,
}
kejieyaojiping:addSkill(kejieyaoshidu)

kejieyaogongdu = sgs.CreateViewAsSkillV2 {
	name = "kejieyaogongdu",
	n = 1,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return true
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return string.find(request:getPattern() or "", "peach") ~= nil
		end
		return false
	end,
	can_select_card = function(skill, request, to_select)
		if request:getSelectedCardIds():isEmpty() then
			return to_select:isBlack()
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = sgs.Sanguosha:getCard(ids:first())
		local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
		peach:setSkillName(skill:objectName())
		peach:addSubcard(card:getId())
		return peach
	end,
}
kejieyaojiping:addSkill(kejieyaogongdu)

kejieyaoliandu = sgs.CreateTriggerSkillV2 {
	name = "kejieyaoliandu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.damage > 1 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		damage.damage = 1
		local log = sgs.LogMessage()
		log.type = "$yaojiping_damage"
		log.from = player
		room:sendLog(log)
		ctx.original_data:setValue(damage)
		return false
	end,
}
kejieyaojiping:addSkill(kejieyaoliandu)


--界程昱

kejieyaochengyu = sgs.General(extension, "kejieyaochengyu", "wei", 3)


kejieyaoxieqin = sgs.CreateTriggerSkillV2 {
	name = "kejieyaoxieqin",
	events = { sgs.Damage, sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		local holder
		if event == sgs.Damage then
			holder = damage.from
		elseif event == sgs.Damaged then
			holder = damage.to
		end
		if not holder or holder:objectName() ~= player:objectName() then return false end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:objectName() ~= damage.to:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:objectName() ~= damage.to:objectName() then
				players:append(p)
			end
		end
		if players:isEmpty() then return false end
		if not room:askForSkillInvoke(player, skill:objectName(), ctx.original_data) then
			return false
		end
		local ano = room:askForPlayerChosen(player, players, skill:objectName(), "yaoxieqin-ask", true, true)
		if not ano then return false end
		ctx.extra_data:setValue(ano)
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local ano = ctx.extra_data:toPlayer()
		if ano and player:canDiscard(ano, "he") then
			local to_throw = room:askForCardChosen(player, ano, "he", skill:objectName())
			local card = sgs.Sanguosha:getCard(to_throw)
			room:throwCard(card, ano, player)
		end
		return false
	end,
}
kejieyaochengyu:addSkill(kejieyaoxieqin)

kejieyaoshiwei = sgs.CreateTriggerSkillV2 {
	name = "kejieyaoshiwei",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.StartJudge, sgs.FinishJudge },
	can_trigger = function(skill, event, room, player, data)
		return v2_owner_names(skill, room, true)
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.StartJudge then
			if not room:askForSkillInvoke(player, skill:objectName(), ctx.original_data) then
				return false
			end
			ctx.choice = room:askForChoice(player, skill:objectName(), "black+red")
			return true
		end
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		if event == sgs.StartJudge then
			room:broadcastSkillInvoke(skill:objectName())
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.StartJudge then
			if ctx.choice == "black" then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweiblacklog"
				log.from = player
				room:sendLog(log)
				room:setPlayerMark(player, "yaoshiweiblack", 1)
			elseif ctx.choice == "red" then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweiredlog"
				log.from = player
				room:sendLog(log)
				room:setPlayerMark(player, "yaoshiweired", 1)
			end
		elseif event == sgs.FinishJudge then
			local judge = ctx.original_data:toJudge()
			if (judge.card:isRed()) and (player:getMark("yaoshiweired") > 0) then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweiredyeslog"
				log.from = player
				room:sendLog(log)
				player:drawCards(2, skill:objectName())
			end
			if (judge.card:isBlack()) and (player:getMark("yaoshiweiblack") > 0) then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweiblackyeslog"
				log.from = player
				room:sendLog(log)
				player:drawCards(2, skill:objectName())
			end
			if (judge.card:isRed()) and (player:getMark("yaoshiweiblack") > 0) then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweiblacknolog"
				log.from = player
				room:sendLog(log)
				player:drawCards(1, skill:objectName())
			end
			if (judge.card:isBlack()) and (player:getMark("yaoshiweired") > 0) then
				local log = sgs.LogMessage()
				log.type = "$keyaoshiweirednolog"
				log.from = player
				room:sendLog(log)
				player:drawCards(1, skill:objectName())
			end
			room:setPlayerMark(player, "yaoshiweired", 0)
			room:setPlayerMark(player, "yaoshiweiblack", 0)
		end
		return false
	end,
}
kejieyaochengyu:addSkill(kejieyaoshiwei)







sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable {
	["keyaobao"] = "妖包",

	["yaochangetupo"] = "将武将更换为界限突破版本",


	--妖司马懿

	["keyaosimayi"] = "妖司马懿",
	["&keyaosimayi"] = "妖司马懿",
	["#keyaosimayi"] = "冢虎",
	["designer:keyaosimayi"] = "杀神附体",
	["cv:keyaosimayi"] = "官方",
	["illustrator:keyaosimayi"] = "三国无双",

	["keyaozhabing"] = "诈病",
	[":keyaozhabing"] = "<font color='green'><b>结束阶段开始时，</b></font>你可以失去1点体力，若如此做，直到你下回合开始，防止你受到的伤害。",

	["keyaoguimou"] = "鬼谋",
	[":keyaoguimou"] = "<font color='green'><b>摸牌阶段，</b></font>你可以多摸X张牌（X为你已损失的体力值）。",

	["$keyaozhabing1"] = "下次注意点！",
	["$keyaozhabing2"] = "出来混，早晚要还的！",
	["$keyaoguimou1"] = "天命，哈哈哈哈！",
	["$keyaoguimou2"] = "吾乃天命之子！",

	["~keyaosimayi"] = "难道真是，天命难违？",

	--妖张角

	["keyaozhangjiao"] = "妖张角",
	["&keyaozhangjiao"] = "妖张角",
	["#keyaozhangjiao"] = "大贤良师",
	["designer:keyaozhangjiao"] = "杀神附体",
	["cv:keyaozhangjiao"] = "官方",
	["illustrator:keyaozhangjiao"] = "三国无双",

	["keyaotaiping"] = "太平",
	[":keyaotaiping"] = "出牌阶段限一次，你可以将两张：\
	♠牌当【南蛮入侵】使用；\
	♥牌当【万箭齐发】使用；\
	♣牌当【五谷丰登】使用；\
	♦牌当【桃园结义】使用。",

	["keyaojiazi"] = "甲子",
	[":keyaojiazi"] = "<font color='green'><b>回合结束时，</b></font>你可以将手牌摸至体力值。",

	["keyaotuzhong"] = "徒众",
	["yaotuzhong-ask"] = "请选择发动“徒众”的角色",
	[":keyaotuzhong"] = "主公技，你可以跳过你的摸牌阶段，若如此做，你可以令一名角色回复1点体力。",

	["$keyaotaiping1"] = "苍天已死，黄天当立！",
	["$keyaotaiping2"] = "岁在甲子，天下大吉！",
	["$keyaojiazi1"] = "哼哼哼...",
	["$keyaojiazi2"] = "天下大势，为我所控。",

	["~keyaozhangjiao"] = "黄天，也死了...",

	--妖周泰

	["keyaozhoutai"] = "妖周泰",
	["&keyaozhoutai"] = "妖周泰",
	["#keyaozhoutai"] = "肤如刻画",
	["designer:keyaozhoutai"] = "杀神附体",
	["cv:keyaozhoutai"] = "官方",
	["illustrator:keyaozhoutai"] = "三国无双",

	["keyaobuhui"] = "不悔",
	[":keyaobuhui"] = "锁定技，你不能成为【杀】的目标。",

	["~keyaozhoutai"] = "已经，尽力了。",


	--界妖周泰

	["kejieyaozhoutai"] = "界妖周泰",
	["&kejieyaozhoutai"] = "界妖周泰",
	["#kejieyaozhoutai"] = "肤如刻画",
	["designer:kejieyaozhoutai"] = "杀神附体",
	["cv:kejieyaozhoutai"] = "官方",
	["illustrator:kejieyaozhoutai"] = "三国无双",

	["kejieyaobuhui"] = "不悔",
	[":kejieyaobuhui"] = "锁定技，你不能成为【杀】和【桃】的目标。",

	["kejieyaofenwei"] = "奋卫",
	["kejieyaofenwei-mopai:kejieyaobuhui"] = "奋卫：令其摸一张牌",
	["kejieyaofenwei_mopai"] = "奋卫：令其摸一张牌",
	["kejieyaofenwei_shouhui"] = "奋卫：收回“不悔”",
	["kejieyaofenwei-ask"] = "请选择发动“奋卫”的角色",
	[":kejieyaofenwei"] = "回合结束时，若你有技能“不悔”，你可以失去技能“不悔”并选择一名其他角色，该角色获得技能“不悔”，若如此做，你的下一个回合开始时，你可以令其失去技能“不悔”且你获得技能“不悔”。\
	○当一名角色获得技能“不悔”时，你可以令其摸一张牌。",

	["$kejieyaofenwei1"] = "还不够！",
	["$kejieyaofenwei2"] = "我绝不会倒下！",

	["~kejieyaozhoutai"] = "已经，尽力了。",

	--妖小乔

	["keyaoxiaoqiao"] = "妖小乔",
	["&keyaoxiaoqiao"] = "妖小乔",
	["#keyaoxiaoqiao"] = "铜雀春深",
	["designer:keyaoxiaoqiao"] = "杀神附体",
	["cv:keyaoxiaoqiao"] = "官方",
	["illustrator:keyaoxiaoqiao"] = "三国无双",

	["keyaoquwu"] = "曲误",
	[":keyaoquwu"] = "出牌阶段限一次，你可以选择攻击范围内的一名其他角色，你令该角色的下一个摸牌阶段少摸一张牌且你摸一张牌。",

	["keyaotongque"] = "铜雀",
	[":keyaotongque"] = "锁定技，【酒】和【铁索连环】对你无效。",

	["keyaozhongshang"] = "冢殇",
	[":keyaozhongshang"] = "锁定技，每当一名角色死亡后，你的手牌上限+1。",

	["$keyaoquwu1"] = "盈盈一笑，娇花照水。",
	["$keyaoquwu2"] = "玉容花貌，难自弃。",

	["~keyaoxiaoqiao"] = "公瑾，我先走一步。",

	--妖卞氏

	["keyaobianshi"] = "妖卞氏",
	["&keyaobianshi"] = "妖卞氏",
	["#keyaobianshi"] = "黄巾女将",
	["designer:keyaobianshi"] = "杀神附体",
	["cv:keyaobianshi"] = "官方",
	["illustrator:keyaobianshi"] = "三国无双",

	["keyaojiahuo"] = "嫁祸",
	[":keyaojiahuo"] = "出牌阶段限一次，你可以将一张黑色牌当【借刀杀人】使用。",

	["keyaoleimu"] = "电母",
	[":keyaoleimu"] = "锁定技，你造成的非雷电伤害改为雷电伤害。",

	["keyaoyaohou"] = "妖后",
	[":keyaoyaohou"] = "<font color='#CC00FF'><b>皇后技，</b></font>当一名角色受到主公造成伤害后，若主公为男性，你可以选择一项：获得受到伤害的角色的一张牌，或摸一张牌。",

	["keyaoyaohou:huode"] = "获得受伤角色的一张牌",
	["keyaoyaohou:mopai"] = "摸一张牌",
	["keyaoyaohou:cancel"] = "取消",

	--妖吉平

	["keyaojiping"] = "妖吉平",
	["&keyaojiping"] = "妖吉平",
	["#keyaojiping"] = "汉之太医",
	["designer:keyaojiping"] = "杀神附体",
	["cv:keyaojiping"] = "官方",
	["illustrator:keyaojiping"] = "三国无双",

	["keyaoshidu"] = "施毒",
	["keyaoshiduCard"] = "施毒",
	["#keyaoshidubuff"] = "施毒",
	[":keyaoshidu"] = "<font color='green'><b>出牌阶段，</b></font>你可以弃置一张♠基本牌或装备牌并选择一名其他角色，该角色下一个回合开始时进行判定：若结果为黑色，你对其造成1点伤害。",

	["keyaogongdu"] = "攻毒",
	[":keyaogongdu"] = "<font color='green'><b>在你的回合外，</b></font>你可以将一张黑色手牌当【桃】使用。",

	["keyaoliandu"] = "炼毒",
	[":keyaoliandu"] = "锁定技，当你受到大于1点的伤害时，你将伤害值改为1点。",
	["$yaojiping_damage"] = "%from 的<font color='yellow'><b>“炼毒”</b></font>效果触发，伤害改为1点！",


	["$keyaoshidulog"] = "<font color='yellow'><b>施毒</b></font> 效果被触发！",

	["$keyaoshidu1"] = "嚼指为誓，誓杀国贼！",
	["$keyaoshidu2"] = "心怀汉恩，断指相随！",
	["$keyaogongdu1"] = "君有疾在身，不治将恐深。",
	["$keyaogongdu2"] = "汝身患重疾，当以虎狼之药去之。",

	["~keyaojiping"] = "今事不成，唯死而已！",

	--妖凌统

	["keyaolingtong"] = "凌统",
	["&keyaolingtong"] = "凌统",
	["#keyaolingtong"] = "国士之风",
	["designer:keyaolingtong"] = "杀神附体",
	["cv:keyaolingtong"] = "官方",
	["illustrator:keyaolingtong"] = "三国无双",

	["keyaozhongyi"] = "重义",
	[":keyaozhongyi"] = "每当你失去最后的手牌后，你可以摸等同于你体力值的牌。",

	["$keyaozhongyi1"] = "伤敌于千里之外！",
	["$keyaozhongyi2"] = "索命于须臾之间！",

	["~keyaolingtong"] = "大丈夫，不惧死亡！",

	--妖程昱

	["keyaochengyu"] = "程昱",
	["&keyaochengyu"] = "程昱",
	["#keyaochengyu"] = "世之奇士",
	["designer:keyaochengyu"] = "杀神附体",
	["cv:keyaochengyu"] = "官方",
	["illustrator:keyaochengyu"] = "三国无双",

	["keyaoxieqin"] = "挟亲",
	[":keyaoxieqin"] = "每轮限一次，当你对一名角色造成伤害后，你可以弃置另一名角色的一张牌。",
	["yaoxieqin-ask"] = "请选择弃置牌的角色",

	["keyaoshiwei"] = "识伪",
	[":keyaoshiwei"] = "<font color='green'><b>每当判定开始时，</b></font>你可以声明一种颜色，然后若你声明的颜色与本次判定结果相同，你摸一张牌。",

	["$keyaoshiweiblacklog"] = "%from 猜测并声明本次判定结果为“黑色”！",
	["$keyaoshiweiredlog"] = "%from 猜测并声明本次判定结果为“红色”！",
	["$keyaoshiweiredyeslog"] = "%from 猜测正确！本次判定结果为“红色”！",
	["$keyaoshiweiblackyeslog"] = "%from 猜测正确！本次判定结果为“黑色”！",
	["$keyaoshiweiblacknolog"] = "%from 猜测错误！本次判定结果为“红色”！",
	["$keyaoshiweirednolog"] = "%from 猜测错误！本次判定结果为“黑色”！",


	["$keyaoxieqin1"] = "天下大乱，群雄并起，必有命事。",
	["$keyaoxieqin2"] = "曹公智略乃上天所授。",
	["$keyaoshiwei1"] = "圈套已设，埋伏乙烷，只等敌军进来。",
	["$keyaoshiwei2"] = "如此天网，量你插翅也难逃。",

	["~keyaochengyu"] = "此诚报效国家之时，吾却休矣。",





	--界妖张角

	["kejieyaozhangjiao"] = "界妖张角",
	["&kejieyaozhangjiao"] = "界妖张角",
	["#kejieyaozhangjiao"] = "大贤统帅",
	["designer:kejieyaozhangjiao"] = "杀神附体",
	["cv:kejieyaozhangjiao"] = "官方",
	["illustrator:kejieyaozhangjiao"] = "三国无双",

	["kejieyaotaiping"] = "太平",
	[":kejieyaotaiping"] = "<font color='green'><b>出牌阶段，</b></font>你可以将两张：\
	♠牌当【南蛮入侵】使用；\
	♥牌当【万箭齐发】使用；\
	♣牌当【五谷丰登】使用；\
	♦牌当【桃园结义】使用。",

	["kejieyaojiazi"] = "甲子",
	[":kejieyaojiazi"] = "<font color='green'><b>回合结束时，</b></font>你可以将手牌摸至体力上限。",

	["kejieyaotuzhong"] = "徒众",
	[":kejieyaotuzhong"] = "主公技，你可以跳过你的摸牌阶段，若如此做，你可以令一名角色回复1点体力并摸一张牌。",

	["$kejieyaotaiping1"] = "苍天已死，黄天当立！",
	["$kejieyaotaiping2"] = "岁在甲子，天下大吉！",
	["$kejieyaojiazi1"] = "哼哼哼...",
	["$kejieyaojiazi2"] = "天下大势，为我所控。",
	["~kejieyaozhangjiao"] = "黄天，也死了...",

	--界妖司马懿

	["kejieyaosimayi"] = "界妖司马懿",
	["&kejieyaosimayi"] = "界妖司马懿",
	["#kejieyaosimayi"] = "家虎",
	["designer:kejieyaosimayi"] = "杀神附体",
	["cv:kejieyaosimayi"] = "官方",
	["illustrator:kejieyaosimayi"] = "三国无双",

	["kejieyaozhabing"] = "诈病",
	[":kejieyaozhabing"] = "<font color='green'><b>结束阶段开始时，</b></font>你可以失去1点体力，若如此做，直到你下回合开始，你不能成为伤害类牌的目标，且其他角色与你的距离+X（X为你已损失的体力值）。",

	["kejieyaozhabingex"] = "诈病",
	["kejieyaoguimou"] = "鬼谋",
	[":kejieyaoguimou"] = "<font color='green'><b>摸牌阶段，</b></font>若你已受伤，你从牌堆获得一张锦囊牌，且你多摸X张牌。",

	["$kejieyaozhabing1"] = "下次注意点！",
	["$kejieyaozhabing2"] = "出来混，早晚要还的！",
	["$kejieyaoguimou1"] = "天命，哈哈哈哈！",
	["$kejieyaoguimou2"] = "吾乃天命之子！",

	["~kejieyaosimayi"] = "难道真是，天命难违？",

	--界妖小乔

	["kejieyaoxiaoqiao"] = "界妖小乔",
	["&kejieyaoxiaoqiao"] = "界妖小乔",
	["#kejieyaoxiaoqiao"] = "铜雀叶煤",
	["designer:kejieyaoxiaoqiao"] = "杀神附体",
	["cv:kejieyaoxiaoqiao"] = "官方",
	["illustrator:kejieyaoxiaoqiao"] = "三国无双",

	["kejieyaoquwu"] = "曲误",
	["jieyaoquwunum"] = "铜雀酒",
	[":kejieyaoquwu"] = "出牌阶段限一次，你可以选择一名其他角色，你令该角色的下一个摸牌阶段少摸一张牌且你摸一张牌。",

	["kejieyaotongque"] = "铜雀",
	[":kejieyaotongque"] = "锁定技，【酒】和【铁索连环】对你无效，每当你成为【酒】的目标时，你本局游戏出牌阶段发动“曲误”的次数限制+1。",

	["kejieyaozhongshang"] = "冢殇",
	[":kejieyaozhongshang"] = "锁定技，每当一名角色死亡后，你回复1点体力且你的手牌上限+1。",

	["$kejieyaoquwu1"] = "盈盈一笑，娇花照水。",
	["$kejieyaoquwu2"] = "玉容花貌，难自弃。",

	["~kejieyaoxiaoqiao"] = "公瑾，我先走一步。",




	--界妖小乔-第二版

	["kejieyaoxiaoqiaotwo"] = "界妖小乔-第二版",
	["&kejieyaoxiaoqiaotwo"] = "界妖小乔",
	["#kejieyaoxiaoqiaotwo"] = "铜雀春深",
	["designer:kejieyaoxiaoqiaotwo"] = "杀神附体",
	["cv:kejieyaoxiaoqiaotwo"] = "官方",
	["illustrator:kejieyaoxiaoqiaotwo"] = "三国无双",

	["kejieyaoquwutwo"] = "曲误",
	["quwutlcount"] = "曲误：体力值",
	["quwuspcount"] = "曲误：手牌数",
	[":kejieyaoquwutwo"] = "当一名角色的出牌阶段结束时，若该角色的手牌数或体力值与其回合开始时的数值不同，你可以摸一张牌，然后若满足两项，你横置其武将牌。",

	["kejieyaotongquetwo"] = "铜雀",
	["kejieyaotongquetwo-dis"] = "请弃置一张手牌发动“铜雀”",
	[":kejieyaotongquetwo"] = "当你受到【酒】【杀】或因“连环状态”传导的伤害时，你可以弃置一张手牌并重置武将牌，若如此做，视为你脱离了因此伤害进入的濒死状态，然后此伤害-1。",

	["kejieyaozhongshangtwo"] = "抚殇",
	[":kejieyaozhongshangtwo"] = "锁定技，一名角色脱离濒死状态时，你回复1点体力或令手牌上限+1。",

	["kejieyaozhongshangtwo:maxhp"] = "回复1点体力",
	["kejieyaozhongshangtwo:handmax"] = "手牌上限+1",

	["$kejieyaoquwutwo1"] = "盈盈一笑，娇花照水。",
	["$kejieyaoquwutwo2"] = "玉容花貌，难自弃。",

	["~kejieyaoxiaoqiaotwo"] = "公瑾，我先走一步。",


	--界妖吉平

	["kejieyaojiping"] = "界妖吉平",
	["&kejieyaojiping"] = "界妖吉平",
	["#kejieyaojiping"] = "太医令",
	["designer:kejieyaojiping"] = "杀神附体",
	["cv:kejieyaojiping"] = "官方",
	["illustrator:kejieyaojiping"] = "三国无双",

	["kejieyaoshidu"] = "施毒",
	["kejieyaoshiduCard"] = "施毒",
	["#kejieyaoshidubuff"] = "施毒",
	[":kejieyaoshidu"] = "<font color='green'><b>出牌阶段，</b></font>你可以弃置一张基本牌或装备牌并选择一名其他角色，该角色下一个回合开始时进行判定：若结果为♠，你对其造成2点伤害；若结果为♣或♦，你对其造成1点伤害；若结果为♥，你摸一张牌。",

	["kejieyaogongdu"] = "攻毒",
	[":kejieyaogongdu"] = "你可以将一张黑色牌当【桃】使用。",

	["kejieyaoliandu"] = "炼毒",
	[":kejieyaoliandu"] = "锁定技，当你受到大于1点的伤害时，你将伤害值改为1点。",

	["$kejieyaoshidu1"] = "嚼指为誓，誓杀国贼！",
	["$kejieyaoshidu2"] = "心怀汉恩，断指相随！",
	["$kejieyaogongdu1"] = "君有疾在身，不治将恐深。",
	["$kejieyaogongdu2"] = "汝身患重疾，当以虎狼之药去之。",

	["~kejieyaojiping"] = "今事不成，唯死而已！",

	--界妖程昱

	["kejieyaochengyu"] = "界程昱",
	["&kejieyaochengyu"] = "界程昱",
	["#kejieyaochengyu"] = "世之奇士",
	["designer:kejieyaochengyu"] = "杀神附体",
	["cv:kejieyaochengyu"] = "官方",
	["illustrator:kejieyaochengyu"] = "三国无双",

	["kejieyaoxieqin"] = "挟亲",
	[":kejieyaoxieqin"] = "<font color='green'><b>当你受到或造成伤害后，</b></font>你可以弃置不是受伤角色的一名角色的一张牌。",
	["yaoxieqin-ask"] = "请选择弃置牌的角色",

	["kejieyaoshiwei"] = "识伪",
	[":kejieyaoshiwei"] = "<font color='green'><b>每当判定开始时，</b></font>你可以声明一种颜色，然后若你声明的颜色与本次判定结果相同，你摸两张牌，否则你摸一张牌。",

	["$kejieyaoxieqin1"] = "天下大乱，群雄并起，必有命事。",
	["$kejieyaoxieqin2"] = "曹公智略乃上天所授。",
	["$kejieyaoshiwei1"] = "圈套已设，埋伏乙烷，只等敌军进来。",
	["$kejieyaoshiwei2"] = "如此天网，量你插翅也难逃。",

	["~kejieyaochengyu"] = "此诚报效国家之时，吾却休矣。",



}
return { extension }
