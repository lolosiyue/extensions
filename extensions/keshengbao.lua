--==《三国 杀神附体——圣》==--
extension = sgs.Package("keshengbao", sgs.Package_GeneralPack)
local skills = sgs.SkillList()


shengchangetupo = sgs.CreateTriggerSkill {
	name = "shengchangetupo",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		if (player:hasSkill("keshengrongxian")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieshengsunquan", false, true, player:getGeneral2Name()=="keshengsunquan", false)
			end
		end

		if (player:hasSkill("keshenghuju")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieshengsunce", false, true, player:getGeneral2Name()=="keshengsunce", false)
			end
		end

		if (player:hasSkill("keshengliufeng")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieshengzhenji", false, true, player:getGeneral2Name()=="keshengzhenji", false)
			end
		end
		if (player:hasSkill("keshengzhuihun")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieshengzhaoyun", false, true, player:getGeneral2Name()=="keshengzhaoyun", false)
			end
		end

		if (player:hasSkill("keshengqizuo")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieshengguojia", false, true, player:getGeneral2Name()=="keshengguojia", false)
			end
		end
		if (player:hasSkill("keshengtonggui")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieshengchengpu", false, true, player:getGeneral2Name()=="keshengchengpu", false)
			end
		end
		if (player:hasSkill("keshengyuma")) then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:changeHero(player, "kejieshenggongsunzan", false, true, player:getGeneral2Name()=="keshenggongsunzan", false)
			end
		end
	end,
	priority = 5,
}
if not sgs.Sanguosha:getSkill("shengchangetupo") then skills:append(shengchangetupo) end




keshengsunquan = sgs.General(extension, "keshengsunquan$", "kesheng", 4)
keshengrongxian = sgs.CreateMaxCardsSkill {
	name = "keshengrongxian",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getLostHp()
		else
			return 0
		end
	end
}
keshengsunquan:addSkill(keshengrongxian)

keshengxionglve = sgs.CreateTriggerSkill {
	name = "keshengxionglve",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if (player:getPhase() == sgs.Player_Finish) then
				local num = player:getLostHp()
				if num > 0 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil,
							"keshengxionglve", nil)
						player:drawCards(num)
						for i = 0, num - 1, 1 do
							if not player:isKongcheng() then
								local card_id = room:askForCardChosen(player, player, "h", "shengxionglve-choose")
								room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, nil, sgs.Player_DrawPile, reason,
									true)
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasSkill(self:objectName())
	end,
}
keshengsunquan:addSkill(keshengxionglve)


keshengganen = sgs.CreateTriggerSkill {
	name = "keshengganen$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		for _, sunquan in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if sunquan and (draw.num > 0) and (sunquan:hasLordSkill(self:objectName())) and (player:objectName() ~= sunquan:objectName()) then
				local dest = sgs.QVariant()
				dest:setValue(sunquan)
				if player:askForSkillInvoke(self:objectName(), dest) then
					draw.num = draw.num - 1
					data:setValue(draw)
					sunquan:drawCards(1)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
keshengsunquan:addSkill(keshengganen)



keshengsunce = sgs.General(extension, "keshengsunce", "kesheng", 4, true)
--[[
keshenghuju = sgs.CreateTriggerSkill {
	name = "keshenghuju",
	events = { sgs.SlashMissed, sgs.ConfirmDamage },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			if effect.to:isAlive() and effect.from:hasSkill(self:objectName()) then
				if player:askForSkillInvoke(self:objectName(), data) then
					local slash = room:askForCard(effect.from, "slash", "shenghuju-slash", data, sgs.Card_MethodResponse)
					if slash then
						room:broadcastSkillInvoke(self:objectName())
						room:setCardFlag(effect.slash, "keshenghuju")
						room:slashResult(effect, nil)
					end
				end
			end
		end
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("keshenghuju") then
				local hurt = damage.damage
				damage.damage = hurt + 1
				data:setValue(damage)
				room:writeToConsole("t1")
			end
		end
	end,
}]]
keshenghuju = sgs.CreateTriggerSkill {
	name = "keshenghuju",
	events = { sgs.CardOffset, sgs.ConfirmDamage },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and effect.to:isAlive() and effect.from:hasSkill(self:objectName()) then
				if player:askForSkillInvoke(self:objectName(), data) then
					local slash = room:askForCard(effect.from, "slash", "shenghuju-slash", data, sgs.Card_MethodResponse)
					if slash then
						room:broadcastSkillInvoke(self:objectName())
						room:setCardFlag(effect.card, "keshenghuju")
						return true
					end
				end
			end
		end
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("keshenghuju") then
				local hurt = damage.damage
				damage.damage = hurt + 1
				data:setValue(damage)
				room:writeToConsole("t1")
			end
		end
	end,
}
keshengsunce:addSkill(keshenghuju)

keshengzhenji = sgs.General(extension, "keshengzhenji", "kesheng", 3, false)

keshengliufeng = sgs.CreateTriggerSkill {
	name = "keshengliufeng",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and (move.from:objectName() == player:objectName())
					and (move.from_places:contains(sgs.Player_PlaceHand)
						or move.from_places:contains(sgs.Player_PlaceEquip)))
				and not (move.to and (move.to:objectName() == player:objectName()
					and (move.to_place == sgs.Player_PlaceHand
						or move.to_place == sgs.Player_PlaceEquip))) then
				for i = 0, move.card_ids:length() - 1, 1 do
					if not player:askForSkillInvoke(self:objectName(), data) then return end
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and
			target:getPhase() == sgs.Player_NotActive
	end
}
keshengzhenji:addSkill(keshengliufeng)


keshenghuixueCard = sgs.CreateSkillCard {
	name = "keshenghuixueCard",
	target_fixed = false,
	will_throw = false,
	--mute = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:getGender() == sgs.General_Male)
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:setPlayerFlag(target, "keshenghuixueTarget")
		local result = room:askForChoice(player, "keshenghuixue", "huixue+shanghai")
		room:setPlayerFlag(target, "-keshenghuixueTarget")
		if result == "huixue" then
			if not (player:isKongcheng()) then
				if not room:askForDiscard(player, self:objectName(), 1, 1, false, false, "shenghuixue-discard") then
					local cards = player:getCards("h")
					local c = cards:at(math.random(0, cards:length() - 1))
					room:throwCard(c, player)
				end
			end
			if not (target:isKongcheng()) then
				if not room:askForDiscard(target, self:objectName(), 1, 1, false, false, "shenghuixue-discard") then
					local cards = target:getCards("h")
					local c = cards:at(math.random(0, cards:length() - 1))
					room:throwCard(c, target)
				end
			end
			room:broadcastSkillInvoke(self:objectName())
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
			room:recover(target, recover)
		end
		if result == "shanghai" then
			room:broadcastSkillInvoke(self:objectName())
			room:loseHp(player, 1, true)
			if player:isAlive() then
				room:damage(sgs.DamageStruct(self:objectName(), player, target))
			else
				room:damage(sgs.DamageStruct(self:objectName(), nil, target))
			end
			if player:isAlive() then
				player:drawCards(1)
			end
			if target:isAlive() then
				target:drawCards(1)
			end
		end
		room:setPlayerFlag(player, "-huixuehuixue")
	end
}


keshenghuixue = sgs.CreateViewAsSkill {
	name = "keshenghuixue",
	n = 0,
	view_as = function(self, cards)
		return keshenghuixueCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not (player:hasUsed("#keshenghuixueCard"))
	end,
}
keshengzhenji:addSkill(keshenghuixue)



keshengzhaoyun = sgs.General(extension, "keshengzhaoyun", "kesheng", 4)

keshengzhuihunCard = sgs.CreateSkillCard {
	name = "keshengzhuihunCard",
	target_fixed = true,
	will_throw = true,
	mute = true,
	on_use = function(self, room, source, targets)
		if source:isAlive() then
			room:writeToConsole("zhuihun")
			room:broadcastSkillInvoke("keshengzhuihun")
			room:addPlayerMark(source, "&keshengzhuihun", self:subcardsLength())
			room:addPlayerMark(source, "keshengzhuihun", 2)
		end
	end
}
keshengzhuihunVS = sgs.CreateViewAsSkill {
	name = "keshengzhuihun",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not (sgs.Self:isJilei(to_select) or (to_select:isEquipped()))
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local zhuihun_card = keshengzhuihunCard:clone()
		for _, card in pairs(cards) do
			zhuihun_card:addSubcard(card)
		end
		zhuihun_card:setSkillName(self:objectName())
		return zhuihun_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#keshengzhuihunCard") and (player:canDiscard(player, "h")) and
			(player:getMark("keshengzhuihun") == 0)
	end,
}

keshengzhuihun = sgs.CreateTriggerSkill {
	name = "keshengzhuihun",
	view_as_skill = keshengzhuihunVS,
	events = { sgs.ConfirmDamage, sgs.EventPhaseStart, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		if (event == sgs.ConfirmDamage) then
			local room = player:getRoom()
			local damage = data:toDamage()
			if player:hasSkill(self:objectName()) and damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel"))
				and (damage.from:objectName() == player:objectName()) and (player:getPhase() == sgs.Player_Play) and (not damage.to:isKongcheng()) then
				local hurt = damage.damage
				damage.damage = hurt + player:getMark("&keshengzhuihun")
				data:setValue(damage)
			end
		end
		if (event == sgs.EventPhaseEnd) then
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Play then
				if player:getMark("keshengzhuihun") > 0 then
					room:removePlayerMark(player, "keshengzhuihun", 1)
				end
				if player:getMark("&keshengzhuihun") > 0 then
					room:setPlayerMark(player, "&keshengzhuihun", 0)
				end
			end
		end
	end
}
keshengzhaoyun:addSkill(keshengzhuihun)


keshengqinggang = sgs.CreateTriggerSkill {
	name = "keshengqinggang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (player:hasSkill(self:objectName())) then
			room:setCardFlag(use.card, "SlashIgnoreArmor")
		end
	end
}
keshengzhaoyun:addSkill(keshengqinggang)
--[[
keshengjiuzhuCard = sgs.CreateSkillCard{
	name = "keshengjiuzhuCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local who = room:getCurrentDyingPlayer()
		if who then
			room:removePlayerMark(source,"@shengjiuzhu")
			local recover = sgs.RecoverStruct()
			recover.who = who
			recover.recover = 3
			room:recover(who, recover)
		end
	end
}
keshengjiuzhu = sgs.CreateZeroCardViewAsSkill{
	name = "keshengjiuzhu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@shengjiuzhu",
	view_as = function(self)
		return keshengjiuzhuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "peach") and (player:getMark("@shengjiuzhu")>0)
	end
}
keshengzhaoyun:addSkill(keshengjiuzhu)]]

keshengjiuzhu = sgs.CreateTriggerSkill {
	name = "keshengjiuzhu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@shengjiuzhu",
	events = { sgs.EnterDying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getMark("@shengjiuzhu") == 0) then return false end
		local dying = data:toDying()
		local to_data = sgs.QVariant()
		to_data:setValue(dying.who)
		if room:askForSkillInvoke(player, self:objectName(), to_data) then
			room:removePlayerMark(player, "@shengjiuzhu")
			local recover = sgs.RecoverStruct()
			recover.who = dying.who
			recover.recover = 3
			room:recover(dying.who, recover)
		end
	end
}
keshengzhaoyun:addSkill(keshengjiuzhu)


keshengguojia = sgs.General(extension, "keshengguojia", "kesheng", 3)

keshengqizuo = sgs.CreateTriggerSkill {
	name = "keshengqizuo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local from = damage.from
		local room = player:getRoom()
		for i = 0, damage.damage - 1, 1 do
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if judge.card:isBlack() then
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
						"shengqizuo-ask", true, true)
					if target then
						if target:getMark("&keshengqizuo") == 0 then
							room:addPlayerMark(target, "@skill_invalidity")
							room:addPlayerMark(target, "&keshengqizuo")
						end
					end
				end
				if judge.card:isRed() then
					player:obtainCard(judge.card)
				end
			end
		end
	end
}
keshengguojia:addSkill(keshengqizuo)

keshengqizuoclear = sgs.CreateTriggerSkill {
	name = "keshengqizuoclear",
	events = { sgs.EventPhaseStart },
	global = true,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			if (player:getPhase() == sgs.Player_Start) and (player:getMark("&keshengqizuo") > 0) then
				local room = player:getRoom()
				if player:getMark("&keshengqizuo") > 0 then
					room:removePlayerMark(player, "@skill_invalidity")
					room:removePlayerMark(player, "&keshengqizuo")
				end
			end
			if (player:getPhase() == sgs.Player_Start) and (player:getMark("&kejieshengqizuo") > 0) then
				local room = player:getRoom()
				if player:getMark("&kejieshengqizuo") > 0 then
					room:removePlayerMark(player, "@skill_invalidity")
					room:removePlayerMark(player, "&kejieshengqizuo")
					room:removePlayerCardLimitation(player, "use,response", "BasicCard")
				end
			end
		end
	end,
}
if not sgs.Sanguosha:getSkill("keshengqizuoclear") then skills:append(keshengqizuoclear) end




function keshenggetCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end

keshengxiangzhi = sgs.CreateTriggerSkill {
	name = "keshengxiangzhi",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw and player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			local card_ids = room:getNCards(3)
			room:fillAG(card_ids)
			local to_get = sgs.IntList()
			local to_throw = sgs.IntList()
			while not card_ids:isEmpty() do
				local card_id = room:askForAG(player, card_ids, false, self:objectName(), "keshengxiangzhi-choice")
				card_ids:removeOne(card_id)
				to_get:append(card_id)
				local card = sgs.Sanguosha:getCard(card_id)
				--判断自己选的颜色
				if card:isBlack() then
					room:takeAG(player, card_id, false)
					local _card_ids = card_ids
					for i = 0, 150 do
						for _, id in sgs.qlist(_card_ids) do
							local c = sgs.Sanguosha:getCard(id)
							card_ids:removeOne(id)
							if c:isRed() then --红色牌就要给别人了							
								room:takeAG(nil, id, false)
								to_throw:append(id)
							end
							if c:isBlack() then
								room:takeAG(nil, id, false)
								to_get:append(id)
							end
						end
					end
				end
				if card:isRed() then
					room:takeAG(player, card_id, false)
					local _card_ids = card_ids
					for i = 0, 150 do
						for _, id in sgs.qlist(_card_ids) do
							local c = sgs.Sanguosha:getCard(id)
							card_ids:removeOne(id)
							if c:isBlack() then --黑色牌就要给别人了							
								room:takeAG(nil, id, false)
								to_throw:append(id)
							end
							if c:isRed() then
								room:takeAG(nil, id, false)
								to_get:append(id)
							end
						end
					end
				end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if not to_get:isEmpty() then
				dummy:addSubcards(keshenggetCardList(to_get))
				player:obtainCard(dummy)
			end
			dummy:clearSubcards()
			--进入手牌预览
			local move = sgs.CardsMoveStruct(to_throw, player, sgs.Player_PlaceHand,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), ""))
			room:moveCardsAtomic(move, false)
			--遗计
			if not to_throw:isEmpty() then
				while room:askForYiji(player, to_throw, self:objectName(), true, true, true, -1, room:getOtherPlayers(player), sgs.CardMoveReason(), "shengxiangzhi-distribute", true) do
					if not player:isAlive() then return end
				end
			end
			if not to_throw:isEmpty() then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist(to_throw) do
					dummy:addSubcard(id)
				end
				room:throwCard(dummy, reason, nil)
			end
			dummy:deleteLater()
			room:clearAG()
			return true
		end
	end
}
keshengguojia:addSkill(keshengxiangzhi)


keshengchengpu = sgs.General(extension, "keshengchengpu", "wu", 4)

keshengtonggui = sgs.CreateTriggerSkill {
	name = "keshengtonggui",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.EventPhaseChanging },
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getPhase() == sgs.Player_Discard and move.from and move.from:objectName() == player:objectName() and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				player:addMark("&keshengtonggui", move.card_ids:length())
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard and player:getMark("&keshengtonggui") > 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
					"keshengtonggui-ask", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					local num = player:getMark("&keshengtonggui")
					local all = target:getCardCount()
					local qz = math.min(all, num)
					room:askForDiscard(target, self:objectName(), qz, qz, false, true, "keshengtonggui-discard")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			player:setMark("&keshengtonggui", 0)
		end
		return false
	end
}
keshengchengpu:addSkill(keshengtonggui)



keshengfuchou = sgs.CreateMasochismSkill {
	name = "keshengfuchou",
	on_damaged = function(self, player, damage)
		local from = damage.from
		local room = player:getRoom()
		local data = sgs.QVariant()
		data:setValue(damage)
		local to_data = sgs.QVariant()
		to_data:setValue(damage.from)
		local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
		if will_use then
			room:broadcastSkillInvoke(self:objectName())
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if (not from) or from:isDead() then return end
			if judge:isGood() then
				--[[if (from:getHandcardNum() > from:getHp()) then
					local cha = from:getHandcardNum()-from:getHp()
					room:askForDiscard(from, self:objectName(), cha, cha, false,true)
				end]]
				if from:getPhase() == sgs.Player_Play then
					from:endPlayPhase()
				end
			end
		end
	end
}
keshengchengpu:addSkill(keshengfuchou)


keshenggongsunzan = sgs.General(extension, "keshenggongsunzan", "qun", 4)

keshengyuma = sgs.CreateTriggerSkill {
	name = "keshengyuma",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards, sgs.EventPhaseChanging, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if player:getOffensiveHorse() ~= nil then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					draw.num = draw.num + 1
					data:setValue(draw)
				end
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_Finish) and (player:getDefensiveHorse() ~= nil) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1)
				end
			end
		end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and (move.from:objectName() == player:objectName())
					and (move.from_places:contains(sgs.Player_PlaceEquip)))
				or
				(move.to and (move.to:objectName() == player:objectName()) and (move.to_place == sgs.Player_PlaceEquip))
			then
				local mnum = 0
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse") or sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse") then
						mnum = mnum + 1
					end
				end
				if mnum > 0 then
					for i = 0, mnum - 1, 1 do
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(1)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
}
keshenggongsunzan:addSkill(keshengyuma)




























kejieshengsunquan = sgs.General(extension, "kejieshengsunquan$", "kesheng", 4)

kejieshengrongxian = sgs.CreateMaxCardsSkill {
	name = "kejieshengrongxian",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getLostHp() + target:getLostHp()
		else
			return 0
		end
	end
}
kejieshengsunquan:addSkill(kejieshengrongxian)

kejieshengxionglve = sgs.CreateTriggerSkill {
	name = "kejieshengxionglve",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if (player:getPhase() == sgs.Player_Play) then
				local los = player:getLostHp()
				if los > 0 then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local card_ids = room:getNCards(player:getMaxHp())
						room:fillAG(card_ids)
						local to_get = sgs.IntList()
						local to_putback = sgs.IntList()
						for i = 0, los - 1, 1 do
							if not card_ids:isEmpty() then
								local card_id = room:askForAG(player, card_ids, false, self:objectName(),
									"kejieshengxionglve-choice")
								card_ids:removeOne(card_id)
								to_get:append(card_id)
								room:takeAG(player, card_id, false)
							end
						end
						local _card_ids = card_ids
						for _, id in sgs.qlist(_card_ids) do
							to_putback:append(id)
						end
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						if not to_get:isEmpty() then
							dummy:addSubcards(keshenggetCardList(to_get))
							player:obtainCard(dummy)
						end
						dummy:clearSubcards()
						if not to_putback:isEmpty() then
							local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							for _, id in sgs.qlist(to_putback) do
								dummy:addSubcard(id)
							end
							room:moveCardsInToDrawpile(player, to_putback, self:objectName(), 0, false)
						end
						dummy:deleteLater()
						room:clearAG()
					end
				end
			end
		end
	end,
}
kejieshengsunquan:addSkill(kejieshengxionglve)


kejieshengganen = sgs.CreateTriggerSkill {
	name = "kejieshengganen$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		for _, sunquan in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if sunquan and (draw.num > 0) and (sunquan:hasLordSkill(self:objectName())) and (player:objectName() ~= sunquan:objectName()) then
				local dest = sgs.QVariant()
				dest:setValue(sunquan)
				if player:askForSkillInvoke(self:objectName(), dest) then
					room:broadcastSkillInvoke(self:objectName())
					draw.num = draw.num - 1
					data:setValue(draw)
					local result = room:askForChoice(sunquan, self:objectName(), "huixue+mopai")
					if result == "huixue" then
						room:recover(sunquan, sgs.RecoverStruct())
					end
					if result == "mopai" then
						sunquan:drawCards(2)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kejieshengsunquan:addSkill(kejieshengganen)






kejieshengsunce = sgs.General(extension, "kejieshengsunce", "kesheng", 4, true)

kejieshenghuju = sgs.CreateTriggerSkill {
	name = "kejieshenghuju",
	events = { sgs.CardOffset, sgs.ConfirmDamage },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and effect.to:isAlive() and effect.from:hasSkill(self:objectName()) then
				if player:askForSkillInvoke(self:objectName(), data) then
					local askforcardpattern = ".."
					local slash = room:askForCard(effect.from, askforcardpattern, "jieshenghuju-slash", data,
						sgs.Card_MethodDiscard)
					if slash then
						room:broadcastSkillInvoke(self:objectName())
						if slash:isRed() then
							player:drawCards(2)
						end
						if slash:isKindOf("Slash") then
							room:setCardFlag(effect.card, "kejieshenghuju")
						end
						return true
					end
				end
			end
		end
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("kejieshenghuju") then
				local hurt = damage.damage
				damage.damage = hurt + 1
				room:setPlayerFlag(player, "-kejieshenghuju")
				data:setValue(damage)
			end
		end
	end,
}
kejieshengsunce:addSkill(kejieshenghuju)


kejieshengsuncetwo = sgs.General(extension, "kejieshengsuncetwo", "kesheng", 4, true)


kejieshenghujutwo = sgs.CreateTriggerSkill {
	name = "kejieshenghujutwo",
	events = { sgs.TargetSpecified, sgs.ConfirmDamage },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				if player:askForSkillInvoke(self:objectName(), data) then
					local askforcardpattern = "."
					local slash = room:askForCard(player, askforcardpattern, "jieshenghujutwo-slash", data,
						sgs.Card_MethodDiscard)

					if slash then
						room:broadcastSkillInvoke(self:objectName())
						local no_respond_list = use.no_respond_list
						for _, eny in sgs.qlist(use.to) do
							table.insert(no_respond_list, eny:objectName())
						end
						use.no_respond_list = no_respond_list
						data:setValue(use)
						if slash:isRed() then
							player:drawCards(2)
						end
						if slash:isKindOf("Slash") then
							room:setCardFlag(use.card, self:objectName())
						end
					end
				end
			end
		end
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and (damage.card:hasFlag("kejieshenghujutwo")) then
				local hurt = damage.damage
				damage.damage = hurt + 1
				data:setValue(damage)
			end
		end
	end,
}
kejieshengsuncetwo:addSkill(kejieshenghujutwo)



--界圣甄姬

kejieshengzhenji = sgs.General(extension, "kejieshengzhenji", "kesheng", 3, false)

kejieshengliufeng = sgs.CreateTriggerSkill {
	name = "kejieshengliufeng",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime, sgs.HpChanged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime and (player:getPhase() == sgs.Player_NotActive) then
			local move = data:toMoveOneTime()
			if (move.from and (move.from:objectName() == player:objectName())
					and (move.from_places:contains(sgs.Player_PlaceHand)
						or move.from_places:contains(sgs.Player_PlaceEquip)))
				and not (move.to and (move.to:objectName() == player:objectName()
					and (move.to_place == sgs.Player_PlaceHand
						or move.to_place == sgs.Player_PlaceEquip))) then
				for i = 0, move.card_ids:length() - 1, 1 do
					if not player:askForSkillInvoke("kejieshengliufeng", data) then return end
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1)
				end
			end
		end
		if event == sgs.HpChanged and (player:getPhase() == sgs.Player_NotActive) then
			if not player:askForSkillInvoke("kejieshengliufeng", data) then return end
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(1)
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName())
	end
}
kejieshengzhenji:addSkill(kejieshengliufeng)


kejieshenghuixueCard = sgs.CreateSkillCard {
	name = "kejieshenghuixueCard",
	target_fixed = false,
	will_throw = false,
	--mute = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local choicelist = ""
		if player:getMark("&useshenghuixue") == 0 then
			choicelist = string.format("%s+%s", choicelist, "shenghuixue_recover=" .. target:objectName())
		end
		if player:getMark("&useshengshanghai") == 0 then
			choicelist = string.format("%s+%s", choicelist, "shenghuixue_damage=" .. target:objectName())
		end
		if choicelist == "" then return end
		local data = sgs.QVariant()
		data:setValue(target)
		local choice = room:askForChoice(player, "kejieshenghuixue", choicelist, data)
		if choice:startsWith("shenghuixue_recover") then
			room:setPlayerMark(player, "&useshenghuixue", 1)
			if player:canDiscard(player, "h") then
				if not room:askForDiscard(player, self:objectName(), 1, 1, false, false, "shenghuixue-discard") then
					local cards = player:getCards("h")
					local c = cards:at(math.random(0, cards:length() - 1))
					room:throwCard(c, player)
				end
			end
			if target:canDiscard(target, "h") then
				if not room:askForDiscard(target, self:objectName(), 1, 1, false, false, "shenghuixue-discard") then
					local cards = target:getCards("h")
					local c = cards:at(math.random(0, cards:length() - 1))
					room:throwCard(c, target)
				end
			end
			room:broadcastSkillInvoke(self:objectName())
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
			room:recover(target, recover)
		elseif choice:startsWith("shenghuixue_damage") then
			room:setPlayerMark(player, "&useshengshanghai", 1)
			room:setPlayerFlag(player, "useshenghuixue")
			room:broadcastSkillInvoke(self:objectName())
			room:loseHp(player, 1, true)
			room:damage(sgs.DamageStruct(self:objectName(), player, target))
			player:drawCards(1)
			target:drawCards(1)
		end
	end
}

kejieshenghuixueVS = sgs.CreateViewAsSkill {
	name = "kejieshenghuixue",
	n = 0,
	view_as = function(self, cards)
		return kejieshenghuixueCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not ((player:getMark("&useshengshanghai") > 0) and (player:getMark("&useshenghuixue") > 0))
	end,
}

kejieshenghuixue = sgs.CreateTriggerSkill {
	name = "kejieshenghuixue",
	events = { sgs.EventPhaseEnd },
	view_as_skill = kejieshenghuixueVS,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseEnd then
			if (player:getPhase() == sgs.Player_Play) and (player:hasSkill("kejieshenghuixue")) then
				local room = player:getRoom()
				room:setPlayerMark(player, "&useshengshanghai", 0)
				room:setPlayerMark(player, "&useshenghuixue", 0)
			end
		end
	end,
}
kejieshengzhenji:addSkill(kejieshenghuixue)


--界圣赵云

kejieshengzhaoyun = sgs.General(extension, "kejieshengzhaoyun", "kesheng", 4)

kejieshengzhuihunCard = sgs.CreateSkillCard {
	name = "kejieshengzhuihunCard",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		if source:isAlive() then
			room:broadcastSkillInvoke("kejieshengzhuihun")
			--	local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, id in sgs.qlist(self:getSubcards()) do
				if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
					room:setPlayerMark(source, "&kejieshengzhuihun", 1)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
					source:drawCards(2)
				end
				if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
					room:addSlashJuli(source, 999, true)
				end
			end
		end
	end
}
kejieshengzhuihunVS = sgs.CreateViewAsSkill {
	name = "kejieshengzhuihun",
	n = 999,
	view_filter = function(self, selected, to_select)
		if sgs.Self:isJilei(to_select) then
			return false
		end
		for _, ca in sgs.list(selected) do
			if (ca:isKindOf("BasicCard") and to_select:isKindOf("BasicCard"))
				or (ca:isKindOf("TrickCard") and to_select:isKindOf("TrickCard"))
				or (ca:isKindOf("EquipCard") and to_select:isKindOf("EquipCard")) then
				return false
			end
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local zhuihun_card = kejieshengzhuihunCard:clone()
		for _, card in pairs(cards) do
			zhuihun_card:addSubcard(card)
		end
		zhuihun_card:setSkillName(self:objectName())
		return zhuihun_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kejieshengzhuihunCard") and (player:canDiscard(player, "he"))
	end,
}

kejieshengzhuihun = sgs.CreateTriggerSkill {
	name = "kejieshengzhuihun",
	view_as_skill = kejieshengzhuihunVS,
	events = { sgs.ConfirmDamage, sgs.EventPhaseStart, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		if (event == sgs.ConfirmDamage) then
			local room = player:getRoom()
			local damage = data:toDamage()
			if player:hasSkill(self:objectName()) and (damage.from:objectName() == player:objectName()) then
				local hurt = damage.damage
				damage.damage = hurt + player:getMark("&kejieshengzhuihun")
				data:setValue(damage)
			end
		end
		if (event == sgs.EventPhaseEnd) then
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Play then
				if player:getMark("&kejieshengzhuihun") > 0 then
					room:setPlayerMark(player, "&kejieshengzhuihun", 0)
				end
			end
		end
	end
}
kejieshengzhaoyun:addSkill(kejieshengzhuihun)


kejieshengqinggang = sgs.CreateTriggerSkill {
	name = "kejieshengqinggang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (player:hasSkill(self:objectName())) then
			room:setCardFlag(use.card, "SlashIgnoreArmor")
			for _, p in sgs.qlist(use.to) do
				if use.card:isKindOf("Slash") and (p:getHp() >= player:getHp()) and (use.from:hasSkill("kejieshengqinggang")) then
					if player:canDiscard(p, "he") then
						local to_data = sgs.QVariant()
						to_data:setValue(p)
						local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
						if will_use then
							local id = room:askForCardChosen(player, p, "he", self:objectName(), false,
								sgs.Card_MethodDiscard)
							room:throwCard(id, p, player)
						end
					end
				end
			end
		end
	end
}
kejieshengzhaoyun:addSkill(kejieshengqinggang)

--[[kejieshengqinggangex = sgs.CreateTriggerSkill{
	name = "kejieshengqinggangex",
	events = {sgs.TargetSpecified},
	global = true,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetSpecified  then
			for _, p in sgs.qlist(use.to) do
				if use.card:isKindOf("Slash") and (p:getHp() >= player:getHp()) and (use.from:hasSkill("kejieshengqinggang"))then
					if player:canDiscard(p, "he") then
						local to_data = sgs.QVariant()
						to_data:setValue(p)
						local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
						if will_use then
							local id = room:askForCardChosen(player, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)
							room:throwCard(id, p, player)
						end
					end
				end
			end
			
		end
		return false
	end,
	can_trigger = function(self, player)
		return player:hasSkill("kejieshengqinggang")
	end,
}
if not sgs.Sanguosha:getSkill("kejieshengqinggangex") then skills:append(kejieshengqinggangex) end]]

--[[
kejieshengjiuzhuCard = sgs.CreateSkillCard{
	name = "kejieshengjiuzhuCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local who = room:getCurrentDyingPlayer()
		if who then
			room:removePlayerMark(source,"@shengjiuzhu")
			local hp = who:getMaxHp()
			room:setPlayerProperty(who, "hp", sgs.QVariant(hp))
			room:loseMaxHp(source, 1)
			room:handleAcquireDetachSkills(source, "newlonghun")
		end
	end
}
kejieshengjiuzhu = sgs.CreateZeroCardViewAsSkill{
	name = "kejieshengjiuzhu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@shengjiuzhu",
	view_as = function(self)
		return kejieshengjiuzhuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "peach") and (player:getMark("@shengjiuzhu")>0)
	end
}
kejieshengzhaoyun:addSkill(kejieshengjiuzhu)
]]
kejieshengjiuzhu = sgs.CreateTriggerSkill {
	name = "kejieshengjiuzhu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@shengjiuzhu",
	events = { sgs.EnterDying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getMark("@shengjiuzhu") == 0) then return false end
		local dying = data:toDying()
		local to_data = sgs.QVariant()
		to_data:setValue(dying.who)
		local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
		if will_use then
			room:removePlayerMark(player, "@shengjiuzhu")
			local recover = sgs.RecoverStruct()
			recover.who = dying.who
			recover.recover = (dying.who:getMaxHp() - dying.who:getHp())
			room:recover(dying.who, recover)
			--[[local hp = dying.who:getMaxHp()
			room:setPlayerProperty(dying.who, "hp", sgs.QVariant(hp))]]
			room:loseMaxHp(player, 1)
			--room:handleAcquireDetachSkills(player, "newlonghun")
		end
	end
}
kejieshengzhaoyun:addSkill(kejieshengjiuzhu)




--界圣郭嘉

kejieshengguojia = sgs.General(extension, "kejieshengguojia", "kesheng", 3)

kejieshengqizuo = sgs.CreateTriggerSkill {
	name = "kejieshengqizuo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local from = damage.from
		local room = player:getRoom()
		for i = 0, damage.damage - 1, 1 do
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				player:obtainCard(judge.card)
				if judge.card:isBlack() then
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
						"shengqizuo-ask", true, true)
					if target then
						if target:getMark("&kejieshengqizuo") == 0 then
							room:addPlayerMark(target, "@skill_invalidity")
							room:addPlayerMark(target, "&kejieshengqizuo")
							room:setPlayerCardLimitation(target, "use,response", "BasicCard", false)
						end
					end
				end
				if judge.card:isRed() then
					local one = room:askForPlayerChosen(player, room:getAllPlayers(), "kejieshengqizuo_get",
						"shengqizuoxuanpai-ask", true, true)
					if one and one:getCardCount() > 0 then
						local card_id = room:askForCardChosen(player, one, "he", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason,
							room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					end
				end
			end
		end
	end
}
kejieshengguojia:addSkill(kejieshengqizuo)

--[[kejieshengqizuoclear = sgs.CreateTriggerSkill{
	name = "kejieshengqizuoclear",
	events = {sgs.EventPhaseStart} ,
	global = true,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			if (player:getPhase() == sgs.Player_RoundStart) and (player:getMark("&kejieshengqizuo")>0) then
				local room = player:getRoom()
				if player:getMark("&kejieshengqizuo")>0 then
					room:removePlayerMark(player,"@skill_invalidity")
					room:removePlayerMark(player,"&kejieshengqizuo")
					room:removePlayerCardLimitation(player, "use,response", "BasicCard")
				end
			end
		end
	end,
}
if not sgs.Sanguosha:getSkill("kejieshengqizuoclear") then skills:append(kejieshengqizuoclear) end]]



kejieshengxiangzhi = sgs.CreateTriggerSkill {
	name = "kejieshengxiangzhi",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Draw then
			return false
		end
		local room = player:getRoom()
		if not player:askForSkillInvoke(self:objectName()) then
			return false
		end
		room:broadcastSkillInvoke(self:objectName())
		local nnn = player:getLostHp() + 3
		local card_ids = room:getNCards(nnn)
		room:fillAG(card_ids)
		local to_get = sgs.IntList()
		local to_throw = sgs.IntList()
		while not card_ids:isEmpty() do
			local card_id = room:askForAG(player, card_ids, false, self:objectName(), "keshengxiangzhi-choice")
			card_ids:removeOne(card_id)
			to_get:append(card_id)
			local card = sgs.Sanguosha:getCard(card_id)
			--判断自己选的颜色
			if card:isBlack() then
				room:takeAG(player, card_id, false)
				local _card_ids = card_ids
				for _, id in sgs.qlist(_card_ids) do
					local c = sgs.Sanguosha:getCard(id)
					card_ids:removeOne(id)
					if c:isRed() then --红色牌就要给别人了							
						room:takeAG(nil, id, false)
						to_throw:append(id)
					end
					if c:isBlack() then
						room:takeAG(nil, id, false)
						to_get:append(id)
					end
				end
			end
			if card:isRed() then
				room:takeAG(player, card_id, false)
				local _card_ids = card_ids
				for _, id in sgs.qlist(_card_ids) do
					local c = sgs.Sanguosha:getCard(id)
					card_ids:removeOne(id)
					if c:isBlack() then --黑色牌就要给别人了							
						room:takeAG(nil, id, false)
						to_throw:append(id)
					end
					if c:isRed() then
						room:takeAG(nil, id, false)
						to_get:append(id)
					end
				end
			end
		end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		if not to_get:isEmpty() then
			dummy:addSubcards(keshenggetCardList(to_get))
			--dummy:addSubcards(keshenggetCardList(to_throw))
			player:obtainCard(dummy)
		end
		dummy:clearSubcards()
		--进入手牌预览
		local move = sgs.CardsMoveStruct(to_throw, player, sgs.Player_PlaceHand,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), ""))
		room:moveCardsAtomic(move, false)
		--遗计
		if not to_throw:isEmpty() then
			while room:askForYiji(player, to_throw, self:objectName(), true, true, true, -1, room:getOtherPlayers(player), sgs.CardMoveReason(), "shengxiangzhi-distribute", true) do
				if not player:isAlive() then return end
			end
		end
		if not to_throw:isEmpty() then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, id in sgs.qlist(to_throw) do
				dummy:addSubcard(id)
			end
			room:throwCard(dummy, reason, nil)
		end
		dummy:deleteLater()
		room:clearAG()
		return true
	end
}
kejieshengguojia:addSkill(kejieshengxiangzhi)




--界程普

kejieshengchengpu = sgs.General(extension, "kejieshengchengpu", "wu", 4)

kejieshengtonggui = sgs.CreateTriggerSkill {
	name = "kejieshengtonggui",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.EventPhaseChanging },
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getPhase() == sgs.Player_Discard and move.from and move.from:objectName() == player:objectName() and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				player:addMark("&kejieshengtonggui", move.card_ids:length())
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
					"kejieshengtonggui-ask", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					local num = player:getMark("&kejieshengtonggui")
					local all = target:getCardCount()
					local qz = math.min(all, num)
					local nqz = 1 + qz
					room:askForDiscard(target, self:objectName(), nqz, nqz, false, true, "kejieshengtonggui-discard")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			player:setMark("&kejieshengtonggui", 0)
		end
		return false
	end
}
kejieshengchengpu:addSkill(kejieshengtonggui)



kejieshengfuchou = sgs.CreateMasochismSkill {
	name = "kejieshengfuchou",
	on_damaged = function(self, player, damage)
		local from = damage.from
		local room = player:getRoom()
		local data = sgs.QVariant()
		data:setValue(damage)
		local to_data = sgs.QVariant()
		to_data:setValue(damage.from)
		local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
		if will_use then
			room:broadcastSkillInvoke(self:objectName())
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if (not from) or from:isDead() then return end
			if judge:isGood() then
				if (from:getHandcardNum() > from:getHp()) then
					local cha = from:getHandcardNum() - from:getHp()
					room:askForDiscard(from, self:objectName(), cha, cha, false, true)
				end
				if from:getPhase() == sgs.Player_Play then
					from:endPlayPhase()
				end
			end
			if judge.card:getSuit() == sgs.Card_Heart then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			end
		end
	end
}
kejieshengchengpu:addSkill(kejieshengfuchou)



kejieshenggongsunzan = sgs.General(extension, "kejieshenggongsunzan", "qun", 4)

kejieshengyuma = sgs.CreateTriggerSkill {
	name = "kejieshengyuma",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards, sgs.EventPhaseChanging, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if player:getOffensiveHorse() ~= nil then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					draw.num = draw.num + 1
					data:setValue(draw)
				end
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_Finish) and (player:getDefensiveHorse() ~= nil) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local mp = 1
					if (player:getDefensiveHorse():objectName() == "zhuahuangfeidian") or (player:getDefensiveHorse():objectName() == "dilu") then
						mp = mp + 1
					end
					player:drawCards(mp)
				end
			end
		end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and (move.from:objectName() == player:objectName())
					and (move.from_places:contains(sgs.Player_PlaceEquip)))
				or
				(move.to and (move.to:objectName() == player:objectName()) and (move.to_place == sgs.Player_PlaceEquip))
			then
				local mnum = 0
				local doublemp = 0
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse") or sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse") then
						if (sgs.Sanguosha:getCard(id):objectName() == "zhuahuangfeidian") or (sgs.Sanguosha:getCard(id):objectName() == "dilu") then
							doublemp = doublemp + 1
						else
							mnum = mnum + 1
						end
					end
				end
				if mnum > 0 then
					for i = 0, mnum - 1, 1 do
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(1)
						end
					end
				end
				if doublemp > 0 then
					for i = 0, doublemp - 1, 1 do
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(2)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill(self:objectName())
	end,
}
kejieshenggongsunzan:addSkill(kejieshengyuma)

kejieshengliema = sgs.CreateTriggerSkill {
	name = "kejieshengliema",
	events = { sgs.Damaged, sgs.BeforeCardsMove },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and player:canDiscard(damage.from, "he") and (damage.from:objectName() ~= player:objectName()) then
				if not player:askForSkillInvoke(self:objectName(), data) then return false end
				room:setPlayerFlag(damage.from, "beliema")
				local card_id = room:askForCardChosen(player, damage.from, "he", self:objectName(), false,
					sgs.Card_MethodDiscard)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(),
					damage.from:objectName(), self:objectName(), "")
				room:throwCard(sgs.Sanguosha:getCard(card_id), reason, damage.from, player)
				room:broadcastSkillInvoke(self:objectName())
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from and not move.to and move.to_place == sgs.Player_DiscardPile then
				if move.reason.m_skillName == "kejieshengliema" and sgs.Sanguosha:getCard(move.card_ids:first()):isKindOf("Horse") then
					local yes = 0
					if (sgs.Sanguosha:getCard(move.card_ids:first()):objectName() ~= "dilu") and (sgs.Sanguosha:getCard(move.card_ids:first()):objectName() ~= "zhuahuangfeidian") then
						yes = 1
					end
					room:obtainCard(player, move.card_ids:first())
					move.card_ids:removeAt(0)
					move.from_places:removeAt(0)
					data:setValue(move)
					if (yes == 1) then
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if p:hasFlag("beliema") then
								room:damage(sgs.DamageStruct(self:objectName(), player, p))
							end
						end
					end
					for _, pp in sgs.qlist(room:getAllPlayers()) do
						if pp:hasFlag("beliema") then
							room:setPlayerFlag(pp, "-beliema")
						end
					end
				end
			end
		end
		return false
	end
}
kejieshenggongsunzan:addSkill(kejieshengliema)





sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable {
	["keshengbao"] = "圣包",
	["shengchangetupo"] = "将武将更换为界限突破版本",

	--圣孙策
	["keshengsunce"] = "圣孙策",
	["&keshengsunce"] = "圣孙策",
	["#keshengsunce"] = "小霸王",
	["designer:keshengsunce"] = "杀神附体",
	["cv:keshengsunce"] = "官方",
	["illustrator:keshengsunce"] = "杀神附体",

	["keshenghuju"] = "虎踞",
	["shenghuju-slash"] = "你可以打出一张【杀】发动“虎踞”",
	[":keshenghuju"] = "当你使用的【杀】被抵消时，你可以打出一张【杀】，若如此做，你使用的【杀】依然造成伤害且伤害+1。",

	["$keshenghuju1"] = "江东子弟，何惧于天下？！",
	["$keshenghuju2"] = "吾乃江东小霸王，孙伯符！",
	["~keshengsunce"] = "内事不决问张昭，外事不决问周瑜。",

	--圣甄姬
	["keshengzhenji"] = "圣甄姬",
	["&keshengzhenji"] = "圣甄姬",
	["#keshengzhenji"] = "洛水之神",
	["designer:keshengzhenji"] = "杀神附体",
	["cv:keshengzhenji"] = "官方",
	["illustrator:keshengzhenji"] = "杀神附体",


	["keshengliufeng"] = "流风",
	[":keshengliufeng"] = "每当你于回合外失去一张牌后，你可以摸一张牌。",

	["keshenghuixue"] = "回雪",
	["keshenghuixueCard"] = "回雪",
	["keshenghuixue:huixue"] = "各弃一张牌，各回复1点体力",
	["shenghuixue-discard"] = "请弃置一张手牌",

	["keshenghuixue:shanghai"] = "你失去1点体力对其造成1点伤害，各摸一张牌",
	[":keshenghuixue"] = "出牌阶段限一次，你可以选择一名男性角色并选择一项：1.你与其各弃置一张手牌，然后各回复1点体力；2.你失去1点体力并对其造成1点伤害，然后你与其各摸一张牌。",

	["$keshenghuixue1"] = "飘飖兮若流风之回雪。",
	["$keshenghuixue2"] = "仿佛兮若轻云之蔽月。",
	["$keshengliufeng1"] = "凌波微步，罗袜生尘。",
	["$keshengliufeng2"] = "体迅飞凫，飘忽若神。",

	["~keshengzhenji"] = "悼良会之永绝兮，哀一逝而异乡。",

	--圣赵云
	["keshengzhaoyun"] = "圣赵云",
	["&keshengzhaoyun"] = "圣赵云",
	["#keshengzhaoyun"] = "一身是胆",
	["designer:keshengzhaoyun"] = "杀神附体",
	["cv:keshengzhaoyun"] = "官方",
	["illustrator:keshengzhaoyun"] = "杀神附体",


	["keshengzhuihun"] = "追魂",
	[":keshengzhuihun"] = "出牌阶段限一次，你可以弃置任意数量的手牌，若如此做，本阶段你使用【杀】或【决斗】对有手牌的角色造成的伤害+X（X为你本次弃置的牌数），且你下个出牌阶段不能再发动“追魂”。",

	["$keshengzhuihun1"] = "能进能退，乃真正法器！",
	["$keshengzhuihun2"] = "吾乃常山赵子龙也！",

	["keshengqinggang"] = "青釭",
	[":keshengqinggang"] = "锁定技，你使用的【杀】无视防具。",

	["keshengjiuzhu"] = "救主",
	[":keshengjiuzhu"] = "限定技，当一名角色进入濒死状态时，你可以令其回复3点体力。",

	["~keshengzhaoyun"] = "这，就是失败的滋味吗？",

	--圣郭嘉
	["keshengguojia"] = "圣郭嘉",
	["&keshengguojia"] = "圣郭嘉",
	["#keshengguojia"] = "天妒英才",
	["designer:keshengguojia"] = "杀神附体",
	["cv:keshengguojia"] = "官方",
	["illustrator:keshengguojia"] = "杀神附体",


	["keshengqizuo"] = "奇佐",
	["shengqizuo-ask"] = "请选择发动“奇佐”的角色",
	[":keshengqizuo"] = "<font color='green'><b>当你受到1点伤害后，</b></font>你可以进行判定，若结果为黑色，你令一名其他角色的非锁定技失效直到其下个回合开始；若结果为红色，你获得此判定牌。",

	["keshengxiangzhi"] = "相知",
	["keshengxiangzhi-choice"] = "请选择一种颜色的牌获得",
	["shengxiangzhi-distribute"] = "你可以将另一种颜色的牌分配给其他角色或弃置之",
	[":keshengxiangzhi"] = "<font color='green'><b>摸牌阶段，</b></font>你可以改为亮出牌堆顶的三张牌，你获得其中一种颜色的所有牌，然后将另一种颜色的牌交给任意名其他角色或弃置之。",

	["$keshengqizuo1"] = "也好。",
	["$keshengqizuo2"] = "罢了。",
	["$keshengxiangzhi1"] = "哦？",
	["$keshengxiangzhi2"] = "就这样吧。",

	["~keshengguojia"] = "咳咳咳...",

	--程普
	["keshengchengpu"] = "程普",
	["&keshengchengpu"] = "程普",
	["#keshengchengpu"] = "荡寇将军",
	["designer:keshengchengpu"] = "杀神附体",
	["cv:keshengchengpu"] = "官方",
	["illustrator:keshengchengpu"] = "杀神附体",


	["keshengtonggui"] = "同归",
	["keshengtonggui-ask"] = "请选择发动“同归”弃牌的角色",
	["keshengtonggui-discard"] = "请选择弃置的牌",
	[":keshengtonggui"] = "<font color='green'><b>弃牌阶段结束时，</b></font>你可以令一名其他角色弃置X张牌（X为此阶段你弃置的牌数）。",

	["keshengfuchou"] = "复仇",
	[":keshengfuchou"] = "<font color='green'><b>每当你受到伤害后，</b></font>你可以进行判定，若结果不为♥且此时为伤害来源的出牌阶段，其结束此阶段。",

	["$keshengtonggui1"] = "将士们，引火对敌！",
	["$keshengtonggui2"] = "和我同归于尽吧！",
	["$keshengfuchou1"] = "唉，帐中不可无酒啊！",
	["$keshengfuchou2"] = "无碍，且饮一杯。",

	["~keshengchengpu"] = "没，没有酒了。",

	--公孙瓒
	["keshenggongsunzan"] = "公孙瓒",
	["&keshenggongsunzan"] = "公孙瓒",
	["#keshenggongsunzan"] = "白马义从",
	["designer:keshenggongsunzan"] = "杀神附体",
	["cv:keshenggongsunzan"] = "官方",
	["illustrator:keshenggongsunzan"] = "杀神附体",


	["keshengyuma"] = "驭马",
	[":keshengyuma"] = "<font color='green'><b>摸牌阶段，</b></font>若你的装备区有进攻马牌，你可以多摸一张牌。<font color='green'><b>结束阶段开始时，</b></font>若你的装备区有防御马牌，你可以摸一张牌。每当一张坐骑牌置入或离开你的装备区后，你可以摸一张牌。",

	["$keshengyuma1"] = "冲啊！",
	["$keshengyuma2"] = "众将听令，摆好阵势，御敌！",

	["~keshenggongsunzan"] = "我军将败，我已无颜苟活于世！",

	--圣孙权
	["keshengsunquan"] = "圣孙权",
	["&keshengsunquan"] = "圣孙权",
	["#keshengsunquan"] = "少年大志/东吴大帝",
	["designer:keshengsunquan"] = "杀神附体",
	["cv:keshengsunquan"] = "官方",
	["illustrator:keshengsunquan"] = "杀神附体",


	["keshengrongxian"] = "容贤",
	[":keshengrongxian"] = "锁定技，你的手牌上限为你的体力上限。",

	["keshengxionglve"] = "雄略",
	["shengxionglve-choose"] = "请选择手牌置于牌堆顶",
	[":keshengxionglve"] = "<font color='green'><b>结束阶段开始时，</b></font>你可以摸X张牌（X为你已损失的体力值），然后依次将等量的手牌置于牌堆顶。",

	["keshengganen"] = "感恩",
	[":keshengganen"] = "主公技，其他角色于其摸牌阶段可以少摸一张牌并令你摸一张牌。",

	["$keshengxionglve1"] = "容我三思。",
	["$keshengxionglve2"] = "且慢！",
	["$keshengganen1"] = "有汝辅佐，甚好！",
	["$keshengganen2"] = "好舒服啊。",

	["~keshengsunquan"] = "父亲，大哥，仲谋愧矣。",

	--界圣孙权
	["kejieshengsunquan"] = "界圣孙权",
	["&kejieshengsunquan"] = "界圣孙权",
	["#kejieshengsunquan"] = "帝王之威",
	["designer:kejieshengsunquan"] = "杀神附体",
	["cv:kejieshengsunquan"] = "官方",
	["illustrator:kejieshengsunquan"] = "杀神附体",


	["kejieshengrongxian"] = "容贤",
	[":kejieshengrongxian"] = "锁定技，你的手牌上限+2X（X为你已损失的体力值）。",

	["kejieshengxionglve"] = "雄略",
	--["shengxionglve-choose"] = "请选择手牌置于牌堆顶",
	["kejieshengxionglve-choice"] = "请选择获得的牌",
	[":kejieshengxionglve"] = "<font color='green'><b>出牌阶段结束时，</b></font>你可以亮出牌堆顶的等同于你体力上限的牌并获得其中X张，然后将其余的牌放回牌堆顶。（X为你已损失的体力值）",

	["kejieshengganen"] = "感恩",
	[":kejieshengganen"] = "主公技，其他角色于其摸牌阶段可以少摸一张牌并令你选择一项：回复1点体力，或摸两张牌。",


	["kejieshengganen:huixue"] = "回复1点体力",
	["kejieshengganen:mopai"] = "摸两张牌",

	["$kejieshengxionglve1"] = "容我三思。",
	["$kejieshengxionglve2"] = "且慢！",
	["$kejieshengganen1"] = "有汝辅佐，甚好！",
	["$kejieshengganen2"] = "好舒服啊。",

	["~kejieshengsunquan"] = "父亲，大哥，仲谋愧矣。",

	--界圣孙策
	["kejieshengsunce"] = "界圣孙策",
	["&kejieshengsunce"] = "界圣孙策",
	["#kejieshengsunce"] = "江东小霸王",
	["designer:kejieshengsunce"] = "杀神附体",
	["cv:kejieshengsunce"] = "官方",
	["illustrator:kejieshengsunce"] = "杀神附体",

	["kejieshenghuju"] = "虎踞",
	["jieshenghuju-slash"] = "你可以弃置一张牌发动“虎踞”",
	["jieshenghujutwo-slash"] = "你可以弃置一张牌发动“虎踞”",
	[":kejieshenghuju"] = "当你使用的【杀】被抵消时，你可以弃置一张牌令此【杀】依然造成伤害，若你弃置的牌为红色，你摸两张牌，若你弃置的牌为【杀】，此伤害+1。",

	["$kejieshenghuju1"] = "江东子弟，何惧于天下？！",
	["$kejieshenghuju2"] = "吾乃江东小霸王，孙伯符！",
	["~kejieshengsunce"] = "内事不决问张昭，外事不决问周瑜。",


	--界圣甄姬
	["kejieshengzhenji"] = "界圣甄姬",
	["&kejieshengzhenji"] = "界圣甄姬",
	["#kejieshengzhenji"] = "轻云蔽月",
	["designer:kejieshengzhenji"] = "杀神附体",
	["cv:kejieshengzhenji"] = "官方",
	["illustrator:kejieshengzhenji"] = "杀神附体",


	["useshenghuixue"] = "回雪：已选回复",
	["useshengshanghai"] = "回雪：已选伤害",

	["kejieshengliufeng"] = "流风",
	[":kejieshengliufeng"] = "每当你于回合外体力值变化后或失去一张牌后，你可以摸一张牌。",

	["kejieshenghuixue"] = "回雪",
	["kejieshenghuixueCard"] = "回雪",
	["shenghuixue_recover"] = "你与 %src 各弃一张手牌，各回复1点体力",
	["shenghuixue_damage"] = "你失去1点体力并对 %src 造成1点伤害，然后你与 %src 各摸一张牌",
	["kejieshenghuixue:huixue"] = "各弃一张手牌，各回复1点体力",

	["kejieshenghuixue:shanghai"] = "你失去1点体力对其造成1点伤害，各摸一张牌",
	[":kejieshenghuixue"] = "<font color='green'><b>出牌阶段每项限一次，</b></font>你可以选择一名其他角色并选择一项：1.你与其各弃置一张手牌，然后各回复1点体力；2.你失去1点体力并对其造成1点伤害，然后你与其各摸一张牌。",

	["$kejieshenghuixue1"] = "飘飖兮若流风之回雪。",
	["$kejieshenghuixue2"] = "仿佛兮若轻云之蔽月。",
	["$kejieshengliufeng1"] = "凌波微步，罗袜生尘。",
	["$kejieshengliufeng2"] = "体迅飞凫，飘忽若神。",

	["~kejieshengzhenji"] = "悼良会之永绝兮，哀一逝而异乡。",





	--界圣郭嘉
	["kejieshengguojia"] = "界圣郭嘉",
	["&kejieshengguojia"] = "界圣郭嘉",
	["#kejieshengguojia"] = "夜谋纳袋",
	["designer:kejieshengguojia"] = "杀神附体",
	["cv:kejieshengguojia"] = "官方",
	["illustrator:kejieshengguojia"] = "杀神附体",


	["kejieshengqizuo"] = "奇佐",
	["kejieshengqizuo_get"] = "奇佐",
	["shengqizuoxuanpai-ask"] = "请选择一名角色获得其一张牌",

	[":kejieshengqizuo"] = "<font color='green'><b>当你受到1点伤害后，</b></font>你可以进行判定，你获得此判定牌，然后若结果为黑色，你令一名其他角色的非锁定技失效且不能使用基本牌直到其下个回合开始；若结果为红色，你获得一名角色的一张牌。",

	["kejieshengxiangzhi"] = "相知",
	["kejieshengxiangzhi-choice"] = "请选择一种颜色的牌获得",

	[":kejieshengxiangzhi"] = "<font color='green'><b>摸牌阶段，</b></font>你可以改为亮出牌堆顶的3+X张牌（X为你已损失的体力值），你获得其中一种颜色的所有牌，然后将另一种颜色的牌交给任意名其他角色或弃置之。",

	["$kejieshengqizuo1"] = "也好。",
	["$kejieshengqizuo2"] = "罢了。",
	["$kejieshengxiangzhi1"] = "哦？",
	["$kejieshengxiangzhi2"] = "就这样吧。",

	["~kejieshengguojia"] = "咳咳咳...",



	--界程普
	["kejieshengchengpu"] = "界程普",
	["&kejieshengchengpu"] = "界程普",
	["#kejieshengchengpu"] = "厉火燃战",
	["designer:kejieshengchengpu"] = "杀神附体",
	["cv:kejieshengchengpu"] = "官方",
	["illustrator:kejieshengchengpu"] = "杀神附体",


	["kejieshengtonggui"] = "同归",
	["kejieshengtonggui-ask"] = "请选择发动“同归”弃牌的角色",
	[":kejieshengtonggui"] = "<font color='green'><b>弃牌阶段结束时，</b></font>你可以令一名其他角色弃置1+X张牌（X为此阶段你弃置的牌数）。",

	["kejieshengfuchou"] = "复仇",
	["kejieshengtonggui-discard"] = "请选择弃置的牌",
	[":kejieshengfuchou"] = "<font color='green'><b>每当你受到伤害后，</b></font>你可以进行判定，若结果不为♥，伤害来源将手牌弃至其体力值，然后若此时为其出牌阶段，其结束此阶段；若结果为♥，你回复1点体力。",

	["$kejieshengtonggui1"] = "将士们，引火对敌！",
	["$kejieshengtonggui2"] = "和我同归于尽吧！",
	["$kejieshengfuchou1"] = "唉，帐中不可无酒啊！",
	["$kejieshengfuchou2"] = "无碍，且饮一杯。",

	["~kejieshengchengpu"] = "没，没有酒了。",

	--界公孙瓒
	["kejieshenggongsunzan"] = "界公孙瓒",
	["&kejieshenggongsunzan"] = "界公孙瓒",
	["#kejieshenggongsunzan"] = "白色俊逸",
	["designer:kejieshenggongsunzan"] = "杀神附体",
	["cv:kejieshenggongsunzan"] = "官方",
	["illustrator:kejieshenggongsunzan"] = "杀神附体",


	["kejieshengyuma"] = "驭马",
	[":kejieshengyuma"] = "<font color='green'><b>摸牌阶段，</b></font>若你的装备区有进攻马牌，你可以多摸【1】张牌。<font color='green'><b>结束阶段开始时，</b></font>若你的装备区有防御马牌，你可以摸【1】张牌。每当一张坐骑牌置入或离开你的装备区后，你可以摸【1】张牌。\
	○若对应坐骑牌为<b>浅色马种</b>，【】内的数值+1。",

	["$kejieshengyuma1"] = "冲啊！",
	["$kejieshengyuma2"] = "众将听令，摆好阵势，御敌！",

	["kejieshengliema"] = "猎马",
	[":kejieshengliema"] = "当你受到一名其他角色造成的伤害后，你可以弃置其一张牌，若此牌为坐骑牌，你获得之，然后若此坐骑牌为<b>深色马种</b>，你对该角色造成1点伤害。",


	["~kejieshenggongsunzan"] = "我军将败，我已无颜苟活于世！",

	--界圣赵云
	["kejieshengzhaoyun"] = "界圣赵云",
	["&kejieshengzhaoyun"] = "界圣赵云",
	["#kejieshengzhaoyun"] = "战无不胜",
	["designer:kejieshengzhaoyun"] = "杀神附体",
	["cv:kejieshengzhaoyun"] = "官方",
	["illustrator:kejieshengzhaoyun"] = "杀神附体",


	["kejieshengzhuihun"] = "追魂",
	[":kejieshengzhuihun"] = "出牌阶段限一次，你可以弃置不同类型的牌各至多一张，若你弃置了：基本牌，你本阶段造成的伤害+1；锦囊牌，你摸两张牌；装备牌，本回合你使用【杀】无距离限制。",

	["$kejieshengzhuihun1"] = "能进能退，乃真正法器！",
	["$kejieshengzhuihun2"] = "吾乃常山赵子龙也！",

	["kejieshengqinggang"] = "青釭",
	["kejieshengqinggangex"] = "青釭",
	[":kejieshengqinggang"] = "锁定技，你使用的【杀】无视防具。当你使用【杀】指定一名体力值不小于你的角色为目标后，你可以弃置其一张牌。",

	["kejieshengjiuzhu"] = "救主",
	[":kejieshengjiuzhu"] = "限定技，当一名角色进入濒死状态时，你可以令其回复所有体力，若如此做，你失去1点体力上限。",

	["~kejieshengzhaoyun"] = "这，就是失败的滋味吗？",


	--界圣孙策第二版
	["kejieshengsuncetwo"] = "界圣孙策-第二版",
	["&kejieshengsuncetwo"] = "界圣孙策",
	["#kejieshengsuncetwo"] = "江东小霸王",
	["designer:kejieshengsuncetwo"] = "杀神附体",
	["cv:kejieshengsuncetwo"] = "官方",
	["illustrator:kejieshengsuncetwo"] = "杀神附体",

	["kejieshenghujutwo"] = "虎踞",
	[":kejieshenghujutwo"] = "当你使用【杀】指定目标后，你可以弃置一张牌令此【杀】不能被响应，若你弃置的牌为红色，你摸两张牌，若你弃置的牌为【杀】，此牌造成的伤害+1。",

	["$kejieshenghujutwo1"] = "江东子弟，何惧于天下？！",
	["$kejieshenghujutwo2"] = "吾乃江东小霸王，孙伯符！",

	["~kejieshengsuncetwo"] = "内事不决问张昭，外事不决问周瑜。",



}
return { extension }
