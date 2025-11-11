--==《新武将》==--
extension = sgs.Package("kearnews", sgs.Package_GeneralPack)
local skills = sgs.SkillList()

--buff集中
kenewslashmore = sgs.CreateTargetModSkill {
	name = "kenewslashmore",
	pattern = ".",
	--[[residue_func = function(self, from, card, to)
		local n = 0
		return n
	end,]]
	distance_limit_func = function(self, from, card, to)
		local n = 0
		if (card:getSkillName() == "kerongchang") then
			n = n + 1000
		end
		return n
	end
}
if not sgs.Sanguosha:getSkill("kenewslashmore") then skills:append(kenewslashmore) end


function KeToData(self)
	local data = sgs.QVariant()
	if type(self) == "string"
		or type(self) == "boolean"
		or type(self) == "number"
	then
		data = sgs.QVariant(self)
	elseif self ~= nil then
		data:setValue(self)
	end
	return data
end

kenewcaocao = sgs.General(extension, "kenewcaocao$", "wei", 4)

--要不是为了ai,这个视为技可以不用写
kejianxiongVS = sgs.CreateZeroCardViewAsSkill {
	name = "kejianxiong",
	response_pattern = "@@kejianxiong",
	enabled_at_play = function(self, player)
		return false
	end,
	view_as = function()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if (pattern == "@@kejianxiong") then
			local id = sgs.Self:getMark("kejianxiong-PlayClear") - 1
			if id < 0 then return nil end
			local card = sgs.Sanguosha:getEngineCard(id)
			return card
		end
	end
}

kejianxiong = sgs.CreateTriggerSkill {
	name = "kejianxiong",
	view_as_skill = kejianxiongVS,
	--frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged, sgs.CardUsed, sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:hasFlag("aizhuangzhicard") then
				room:setPlayerFlag(use.from, "-aizhuangzhi")
				room:setCardFlag(use.card, "-zhuangzhicard")
			end
		end
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if (use.from:hasFlag("zhuangzhicard")) then
				room:setPlayerFlag(use.from, "-zhuangzhicard")
				local log = sgs.LogMessage()
				log.type = "$kejianxionglog"
				log.from = player
				for _, p in sgs.qlist(use.to) do
					log.to:append(p)
				end
				room:sendLog(log)
				local no_respond_list = use.no_respond_list
				for _, szm in sgs.qlist(use.to) do
					table.insert(no_respond_list, szm:objectName())
				end
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local card = damage.card
			if card then
				local ids = sgs.IntList()
				if card:isVirtualCard() then
					ids = card:getSubcards()
				else
					ids:append(card:getEffectiveId())
				end
				if ids:isEmpty() then return end
				for _, id in sgs.qlist(ids) do
					if room:getCardPlace(id) ~= sgs.Player_PlaceTable then return end
				end
				for _, cc in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if cc and (cc:getMark("kejianxiong-Clear") <= 0) then
						if room:askForSkillInvoke(cc, self:objectName(), data) then
							if (damage.to == cc) then
								local yy = math.random(1, 2)
								if yy == 1 then
									room:broadcastSkillInvoke(self:objectName())
								else
									room:broadcastSkillInvoke("newhujiaa")
								end
							else
								local yy = math.random(1, 3)
								if yy ~= 3 then
									room:broadcastSkillInvoke(self:objectName())
								else
									room:broadcastSkillInvoke("newhujiaa", 1)
								end
							end
							room:setPlayerMark(cc, "kejianxiong-Clear", 1)
							room:setPlayerMark(cc, "&kejianxiong-Clear", 1)
							cc:obtainCard(card)
							if ((damage.to == cc) or (damage.from == cc)) and (not card:isVirtualCard()) then
								--cc:drawCards(1)
								local id = card:getEffectiveId()
								room:setCardFlag(card, "zhuangzhicard")
								room:setPlayerFlag(cc, "zhuangzhicard")
								room:addPlayerMark(cc, "kejianxiong-PlayClear", id + 1)
								local yes = room:askForUseCard(cc, "" .. id, "zhuangzhiuse-ask", -1, sgs.Card_MethodUse,
									false, cc, nil, "zhuangzhicard")
								room:addPlayerMark(cc, "kejianxiong-PlayClear", 0)
								room:setPlayerFlag(cc, "-zhuangzhicard")
								if yes then
									if (damage.to == cc) then
										local yy = math.random(1, 2)
										if yy == 1 then
											room:broadcastSkillInvoke(self:objectName())
										else
											room:broadcastSkillInvoke("newhujiaa")
										end
									else
										local yy = math.random(1, 3)
										if yy ~= 3 then
											room:broadcastSkillInvoke(self:objectName())
										else
											room:broadcastSkillInvoke("newhujiaa", 1)
										end
									end
								end
							end
							break
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
kenewcaocao:addSkill(kejianxiong)

--for ai
--[[kejianxiongai = sgs.CreateProhibitSkill{
	name = "kejianxiongai",
	is_prohibited = function(self, from, to, card)
		return (from:hasSkill("kejianxiong") and from:hasFlag("aizhuangzhi") and (not card:hasFlag("zhuangzhicard")))
	end
}
if not sgs.Sanguosha:getSkill("kejianxiongai") then skills:append(kejianxiongai) end]]

kejianxiongjl = sgs.CreateTargetModSkill {
	name = "kejianxiongjl",
	distance_limit_func = function(self, from, card)
		if card:hasFlag("zhuangzhicard") or from:hasFlag("zhuangzhicard") then
			return 1000
		else
			return 0
		end
	end,
}
if not sgs.Sanguosha:getSkill("kejianxiongjl") then skills:append(kejianxiongjl) end


newhujiaaCard = sgs.CreateSkillCard {
	name = "newhujiaaCard",
	filter = function(self, selected, to_select)
		return #selected == 0 and to_select:getKingdom() == "wei" and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local damage = effect.from:getTag("newhujiaaDamage"):toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			effect.from:removeQinggangTag(damage.card)
		end
		damage.to = effect.to
		damage.transfer = true
		room:damage(damage)
		room:addPlayerMark(effect.from, "newhujiaa")
		room:addPlayerMark(effect.from, "&newhujiaa_lun")
	end,
}
newhujiaaVS = sgs.CreateZeroCardViewAsSkill {
	name = "newhujiaa",
	view_as = function()
		return newhujiaaCard:clone()
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@newhujiaa"
	end,
}
newhujiaa = sgs.CreateTriggerSkill {
	name = "newhujiaa$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageInflicted, sgs.TurnStart },
	view_as_skill = newhujiaaVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			if player:hasLordSkill(self:objectName()) and player:getMark(self:objectName()) == 0 then
				player:setTag("newhujiaaDamage", data)
				if room:askForUseCard(player, "@@newhujiaa", "@newhujiaa-card") then
					return true
				end
			end
		elseif event == sgs.TurnStart then
			room:setPlayerMark(player, self:objectName(), 0)
		end
	end,
}
kenewcaocao:addSkill(newhujiaa)

kenewsunquan = sgs.General(extension, "kenewsunquan$", "wu", 4, true)

kechazhengCard = sgs.CreateSkillCard {
	name = "kechazhengCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:throwCard(self, source)
		local num = target:getHandcardNum()
		local show = self:subcardsLength()
		if (num <= show) then
			room:showAllCards(target)
		else
			if (target:getHandcardNum() > 0) then
				local to_all = sgs.IntList()
				local to_show = sgs.IntList()
				local keyi = 0
				for _, c in sgs.qlist(target:getCards("h")) do
					to_all:append(c:getEffectiveId())
				end
				--循环随机里面的一张牌装到to_show里面，直到to_show装满
				repeat
					keyi = 0
					local rr = math.random(0, to_all:length() - 1)
					if not to_show:contains(to_all:at(rr)) then
						to_show:append(to_all:at(rr))
					end
					if to_show:length() == show then
						keyi = 1
					end
				until (keyi == 1)
				room:showCard(target, to_show)
			end
		end
	end
}
kechazheng = sgs.CreateViewAsSkill {
	name = "kechazheng",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = kechazhengCard:clone()
			for _, c in pairs(cards) do
				card:addSubcard(c)
			end
			return card
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kechazhengCard") and player:canDiscard(player, "he")
	end,
}
kenewsunquan:addSkill(kechazheng)

kezhiheng = sgs.CreateTriggerSkill {
	name = "kezhiheng",
	events = { sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from
				and (move.from:getMark("banlunkezhiheng_lun") == 0)
				and (move.from:objectName() == player:objectName())
				and (move.from:getMark("&banturnkezhiheng-Clear") == 0)
				and (not move.from_places:contains(sgs.Player_PlaceJudge))
				and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
				local num = move.card_ids:length()
				local result = room:askForChoice(player, "kezhiheng", "xiaomo+damo+cancel")
				if result == "xiaomo" then
					room:broadcastSkillInvoke(self:objectName())
					local log = sgs.LogMessage()
					log.type = "$kezhihenglog"
					log.from = player
					room:sendLog(log)
					player:drawCards(num)
					room:setPlayerMark(player, "&banturnkezhiheng-Clear", 1)
				end
				if result == "damo" then
					room:broadcastSkillInvoke(self:objectName())
					local log = sgs.LogMessage()
					log.type = "$kezhihenglogtwo"
					log.from = player
					room:sendLog(log)
					player:drawCards(num)
					player:drawCards(1)
					room:setPlayerMark(player, "banlunkezhiheng_lun", 1)
					room:setPlayerMark(player, "&kezhihengfail_lun", 1)
					room:setPlayerMark(player, "&banturnkezhiheng-Clear", 1)
				end
			end
		end
	end,
}
kenewsunquan:addSkill(kezhiheng)

kejiuyuan = sgs.CreateTriggerSkill {
	name = "kejiuyuan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed, sgs.PreHpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Peach") and (not use.card:hasFlag("kenewjiuyuan"))
				and (use.from:objectName() ~= use.to:at(0):objectName())
				and (use.from:hasSkill(self:objectName()) or use.to:at(0):hasSkill(self:objectName())) then
				room:setCardFlag(use.card, "kenewjiuyuan")
				room:broadcastSkillInvoke(self:objectName())
				use.from:drawCards(1)
				use.to:at(0):drawCards(1)
				--[[for _, p in sgs.qlist(use.to) do
					if not ((not p:hasSkill(self:objectName())) and (not use.from:hasSkill(self:objectName())))
					and (p:objectName() ~= use.from:objectName()) then
					    p:drawCards(1)
					end
				end]]
			end
		elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and rec.card:hasFlag("kenewjiuyuan") then
				rec.recover = rec.recover + 1
				data:setValue(rec)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
kenewsunquan:addSkill(kejiuyuan)

kenewliubei = sgs.General(extension, "kenewliubei", "qun", 4, true)

kenewgonghuan = sgs.CreateTriggerSkill {
	name = "kenewgonghuan",
	events = { sgs.TargetConfirming, sgs.Damaged, sgs.CardEffected },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetConfirming) then
			local use = data:toCardUse()
			if (use.to:length() == 1) then
				if (use.card:isKindOf("Slash") or (use.card:isNDTrick()) and use.card:isDamageCard()) then
					local canuse = 1
					local lbs = room:findPlayersBySkillName(self:objectName())
					local fri = use.to:at(0)
					for _, lb in sgs.qlist(lbs) do
						if use.from:inMyAttackRange(lb) and (lb:objectName() ~= use.from:objectName()) and (lb:objectName() ~= use.to:at(0):objectName()) and (lb:getMark("nogonghuan+"..fri:objectName().."_lun") == 0) then
							if (canuse == 1) then
								local will_use = room:askForSkillInvoke(lb, self:objectName(), data)
								if will_use then
									room:broadcastSkillInvoke(self:objectName())
									canuse = 0
									room:setCardFlag(use.card, "gonghuancard")
									room:setPlayerFlag(lb, "gonghuanliubei")
									room:setPlayerFlag(fri, "gonghuanfri")
									use.to:removeOne(fri)
									use.to:append(lb)
									use.to:append(fri)
									data:setValue(use)
								end
							end
						end
					end
				end
			end
		end
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("gonghuancard") and damage.to:hasFlag("gonghuanliubei") then
				--damage.to:drawCards(1)
				local fri = player
				local can_invoke = false
				for _, f in sgs.qlist(room:getAllPlayers()) do
					if f:hasFlag("gonghuanfri") then
						fri = f
						can_invoke =true
						break
					end
				end
				if (can_invoke) then
					room:setPlayerFlag(fri, "begonghuanprotect")
					local dest = sgs.QVariant()
					dest:setValue(fri)
					local result = room:askForChoice(damage.to, self:objectName(), "recover+mopai", dest)
					if result == "recover" then
						room:recover(fri, sgs.RecoverStruct())
					end
					if result == "mopai" then
						fri:drawCards(2)
					end
					room:setPlayerMark(fri, "nogonghuan+"..damage.to:objectName().."_lun", 1)
					local players = sgs.SPlayerList()
					players:append(damage.to)
					room:addPlayerMark(fri, "&kenewgonghuan+to+#"..damage.to:objectName().."_lun", 1, players)
				end
			end
		end
		if (event == sgs.CardEffected) then
			local effect = data:toCardEffect()
			if effect.card and effect.card:hasFlag("gonghuancard") then --and effect.to:hasFlag("begonghuanprotect") then
				local lb = player
				local can_invoke = false
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasFlag("gonghuanliubei") then
						lb = p
						can_invoke = true
						break
					end
				end
				--刘备闪避了
				if lb and (effect.to:objectName() ~= lb:objectName()) then
					if not effect.to:hasFlag("begonghuanprotect") then
						if not effect.from:isNude() then
							local card_id = room:askForCardChosen(lb, effect.from, "he", self:objectName())
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, lb:objectName())
							room:obtainCard(lb, sgs.Sanguosha:getCard(card_id), reason,
								room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
						end
						--room:setPlayerFlag(effect.to,"-begonghuanprotect")
						room:setPlayerFlag(effect.to, "-gonghuanfri")
						room:setPlayerFlag(lb, "-gonghuanliubei")
					end
					if effect.to:hasFlag("begonghuanprotect") then
						room:setPlayerFlag(effect.to, "-begonghuanprotect")
						room:setPlayerFlag(effect.to, "-gonghuanfri")
						room:setPlayerFlag(lb, "-gonghuanliubei")
						return true
					end
				end
				return false
			end
		end
	end
}
kenewliubei:addSkill(kenewgonghuan)


kenewsangzhiCard = sgs.CreateSkillCard {
	name = "kenewsangzhiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:getMark("beselectsangzhi") <= 0)
			and
			(((to_select:getHp() > sgs.Self:getHp()) and (sgs.Self:isWounded())) or (to_select:getHandcardNum() > sgs.Self:getHandcardNum()))
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:setPlayerMark(target, "beselectsangzhi", 1)
		local choices = {}
		if (target:getHp() > player:getHp()) and player:isWounded() then
			table.insert(choices, "tili")
		end
		if target:getHandcardNum() > player:getHandcardNum() then
			table.insert(choices, "shoupai")
		end
		local choice = room:askForChoice(player, "kenewsangzhi", table.concat(choices, "+"))
		if choice == "tili" then
			local cha = target:getHp() - player:getHp()
			if cha > 0 then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = cha
				room:recover(player, recover)
			end
		end
		if choice == "shoupai" then
			local cha = target:getHandcardNum() - player:getHandcardNum()
			if cha > 0 then
				player:drawCards(cha)
			end
		end
		local players = sgs.SPlayerList()
		players:append(player)
		room:addPlayerMark(target, "&kenewsangzhi+to+#"..player:objectName(), 1, players)
	end
}


kenewsangzhiVS = sgs.CreateViewAsSkill {
	name = "kenewsangzhi",
	n = 0,
	view_as = function(self, cards)
		return kenewsangzhiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("bansangzhi-PlayClear") < 1)
	end,
}


kenewsangzhi = sgs.CreateTriggerSkill {
	name = "kenewsangzhi",
	events = { sgs.EventPhaseStart },
	view_as_skill = kenewsangzhiVS,
	on_trigger = function(self, event, player, data)
		if (player:getPhase() == sgs.Player_Play) then
			local room = player:getRoom()
			local yes = 1
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if (p:getMark("beselectsangzhi") == 0) then
					yes = 0
				end
			end
			if yes == 1 then
				player:gainMark("@kecaoxie")
				room:setPlayerMark(player, "bansangzhi-PlayClear", 1)
			end
		end
	end
}
kenewliubei:addSkill(kenewsangzhi)




kenewzahuoCard = sgs.CreateSkillCard {
	name = "kenewzahuoCard",
	target_fixed = true,
	will_throw = true,
	mute = true,
	on_use = function(self, room, player, targets)
		local room = player:getRoom()
		room:broadcastSkillInvoke("kenewzahuo", math.random(2, 3))
		local class = room:askForChoice(player, "goodsclass", "basiccard+effect+equip")
		--基本牌
		if class == "basiccard" then
			local bc = room:askForChoice(player, "liubeijibenpai", "slash+jink+wine+peach+cancel")
			if bc == "slash" then
				local have = 0
				local nm = 0
				for _, id in sgs.qlist(room:getDrawPile()) do
					if (sgs.Sanguosha:getCard(id):isKindOf("Slash")) then
						--没有足够金币
						if (player:getMark("@kecaoxie") < 3) then
							room:broadcastSkillInvoke("kenewzahuo", 1)
							local log = sgs.LogMessage()
							log.type = "$keliubeinomoney"
							log.from = player
							room:sendLog(log)
							room:doLightbox("$keliubeinomoney")
							nm = 1
							break
						end
						--有足够的金币
						if (player:getMark("@kecaoxie") >= 3) then
							room:removePlayerMark(player, "@kecaoxie", 3)
							room:obtainCard(player, id, true)
							local log = sgs.LogMessage()
							log.type = "$keliubeibuy"
							log.from = player
							room:sendLog(log)
							room:setPlayerFlag(player, "alreadybuy")
							room:broadcastSkillInvoke("bensos")
							room:doLightbox("$keliubeibuy")
							have = 1
							break
						end
					end
				end
				if have == 0 and nm == 0 then
					local log = sgs.LogMessage()
					log.type = "$keliubeinogood"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinogood")
				end
			end
			if bc == "jink" then
				local have = 0
				local nm = 0
				for _, id in sgs.qlist(room:getDrawPile()) do
					if (sgs.Sanguosha:getCard(id):isKindOf("Jink")) then
						--没有足够金币
						if (player:getMark("@kecaoxie") < 3) then
							room:broadcastSkillInvoke("kenewzahuo", 1)
							local log = sgs.LogMessage()
							log.type = "$keliubeinomoney"
							log.from = player
							room:sendLog(log)
							room:doLightbox("$keliubeinomoney")
							nm = 1
							break
						end
						--有足够的金币
						if (player:getMark("@kecaoxie") >= 3) then
							room:removePlayerMark(player, "@kecaoxie", 3)
							room:obtainCard(player, id, true)
							local log = sgs.LogMessage()
							log.type = "$keliubeibuy"
							log.from = player
							room:sendLog(log)
							room:broadcastSkillInvoke("bensos")
							room:doLightbox("$keliubeibuy")
							room:setPlayerFlag(player, "alreadybuy")
							have = 1
							break
						end
					end
				end
				if have == 0 and nm == 0 then
					local log = sgs.LogMessage()
					log.type = "$keliubeinogood"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinogood")
				end
			end
			if bc == "wine" then
				local have = 0
				local nm = 0
				for _, id in sgs.qlist(room:getDrawPile()) do
					if (sgs.Sanguosha:getCard(id):isKindOf("Analeptic")) then
						--没有足够金币
						if (player:getMark("@kecaoxie") < 5) then
							room:broadcastSkillInvoke("kenewzahuo", 1)
							local log = sgs.LogMessage()
							log.type = "$keliubeinomoney"
							log.from = player
							room:sendLog(log)
							room:doLightbox("$keliubeinomoney")
							nm = 1
							break
						end
						--有足够的金币
						if (player:getMark("@kecaoxie") >= 5) then
							room:removePlayerMark(player, "@kecaoxie", 5)
							room:obtainCard(player, id, true)
							local log = sgs.LogMessage()
							log.type = "$keliubeibuy"
							log.from = player
							room:sendLog(log)
							room:broadcastSkillInvoke("bensos")
							room:doLightbox("$keliubeibuy")
							room:setPlayerFlag(player, "alreadybuy")
							have = 1
							break
						end
					end
				end
				if have == 0 and nm == 0 then
					local log = sgs.LogMessage()
					log.type = "$keliubeinogood"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinogood")
				end
			end
			if bc == "peach" then
				local have = 0
				local nm = 0
				for _, id in sgs.qlist(room:getDrawPile()) do
					if (sgs.Sanguosha:getCard(id):isKindOf("Peach")) then
						--没有足够金币
						if (player:getMark("@kecaoxie") < 5) then
							room:broadcastSkillInvoke("kenewzahuo", 1)
							local log = sgs.LogMessage()
							log.type = "$keliubeinomoney"
							log.from = player
							room:sendLog(log)
							room:doLightbox("$keliubeinomoney")
							nm = 1
							break
						end
						--有足够的金币
						if (player:getMark("@kecaoxie") >= 5) then
							room:removePlayerMark(player, "@kecaoxie", 5)
							room:obtainCard(player, id, true)
							local log = sgs.LogMessage()
							log.type = "$keliubeibuy"
							log.from = player
							room:sendLog(log)
							room:broadcastSkillInvoke("bensos")
							room:doLightbox("$keliubeibuy")
							room:setPlayerFlag(player, "alreadybuy")
							have = 1
							break
						end
					end
				end
				if have == 0 and nm == 0 then
					local log = sgs.LogMessage()
					log.type = "$keliubeinogood"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinogood")
				end
			end
		end
		--装备
		if class == "equip" then
			local bc = room:askForChoice(player, "liubeizhuangbei", "weapon+armor+addone+minusone+cancel")
			if bc == "weapon" then
				local have = 0
				local nm = 0
				for _, id in sgs.qlist(room:getDrawPile()) do
					if (sgs.Sanguosha:getCard(id):isKindOf("Weapon")) then
						--没有足够金币
						if (player:getMark("@kecaoxie") < 4) then
							room:broadcastSkillInvoke("kenewzahuo", 1)
							local log = sgs.LogMessage()
							log.type = "$keliubeinomoney"
							log.from = player
							room:sendLog(log)
							room:doLightbox("$keliubeinomoney")
							nm = 1
							break
						end
						--有足够的金币
						if (player:getMark("@kecaoxie") >= 4) then
							room:removePlayerMark(player, "@kecaoxie", 4)
							room:obtainCard(player, id, true)
							local log = sgs.LogMessage()
							log.type = "$keliubeibuy"
							log.from = player
							room:sendLog(log)
							room:broadcastSkillInvoke("bensos")
							room:doLightbox("$keliubeibuy")
							room:setPlayerFlag(player, "alreadybuy")
							have = 1
							break
						end
					end
				end
				if have == 0 and nm == 0 then
					local log = sgs.LogMessage()
					log.type = "$keliubeinogood"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinogood")
				end
			end
			if bc == "armor" then
				local have = 0
				local nm = 0
				for _, id in sgs.qlist(room:getDrawPile()) do
					if (sgs.Sanguosha:getCard(id):isKindOf("Armor")) then
						--没有足够金币
						if (player:getMark("@kecaoxie") < 4) then
							room:broadcastSkillInvoke("kenewzahuo", 1)
							local log = sgs.LogMessage()
							log.type = "$keliubeinomoney"
							log.from = player
							room:sendLog(log)
							room:doLightbox("$keliubeinomoney")
							nm = 1
							break
						end
						--有足够的金币
						if (player:getMark("@kecaoxie") >= 4) then
							room:removePlayerMark(player, "@kecaoxie", 4)
							room:obtainCard(player, id, true)
							local log = sgs.LogMessage()
							log.type = "$keliubeibuy"
							log.from = player
							room:sendLog(log)
							room:broadcastSkillInvoke("bensos")
							room:doLightbox("$keliubeibuy")
							room:setPlayerFlag(player, "alreadybuy")
							have = 1
							break
						end
					end
				end
				if have == 0 and nm == 0 then
					local log = sgs.LogMessage()
					log.type = "$keliubeinogood"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinogood")
				end
			end
			if bc == "addone" then
				local have = 0
				local nm = 0
				for _, id in sgs.qlist(room:getDrawPile()) do
					if (sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse")) then
						--没有足够金币
						if (player:getMark("@kecaoxie") < 4) then
							room:broadcastSkillInvoke("kenewzahuo", 1)
							local log = sgs.LogMessage()
							log.type = "$keliubeinomoney"
							log.from = player
							room:sendLog(log)
							room:doLightbox("$keliubeinomoney")
							nm = 1
							break
						end
						--有足够的金币
						if (player:getMark("@kecaoxie") >= 4) then
							room:removePlayerMark(player, "@kecaoxie", 4)
							room:obtainCard(player, id, true)
							local log = sgs.LogMessage()
							log.type = "$keliubeibuy"
							log.from = player
							room:sendLog(log)
							room:broadcastSkillInvoke("bensos")
							room:doLightbox("$keliubeibuy")
							room:setPlayerFlag(player, "alreadybuy")
							have = 1
							break
						end
					end
				end
				if have == 0 and nm == 0 then
					local log = sgs.LogMessage()
					log.type = "$keliubeinogood"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinogood")
				end
			end
			if bc == "minusone" then
				local have = 0
				local nm = 0
				for _, id in sgs.qlist(room:getDrawPile()) do
					if (sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse")) then
						--没有足够金币
						if (player:getMark("@kecaoxie") < 4) then
							room:broadcastSkillInvoke("kenewzahuo", 1)
							local log = sgs.LogMessage()
							log.type = "$keliubeinomoney"
							log.from = player
							room:sendLog(log)
							room:doLightbox("$keliubeinomoney")
							nm = 1
							break
						end
						--有足够的金币
						if (player:getMark("@kecaoxie") >= 4) then
							room:removePlayerMark(player, "@kecaoxie", 4)
							room:obtainCard(player, id, true)
							local log = sgs.LogMessage()
							log.type = "$keliubeibuy"
							log.from = player
							room:sendLog(log)
							room:broadcastSkillInvoke("bensos")
							room:doLightbox("$keliubeibuy")
							room:setPlayerFlag(player, "alreadybuy")
							have = 1
							break
						end
					end
				end
				if have == 0 and nm == 0 then
					local log = sgs.LogMessage()
					log.type = "$keliubeinogood"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinogood")
				end
			end
		end
		if class == "effect" then
			local bc = room:askForChoice(player, "liubeitexiao", "judge+maxhand+msg+addslash+cancel")
			if bc == "addslash" then
				if (player:getMark("@kecaoxie") < 4) then
					room:broadcastSkillInvoke("kenewzahuo", 1)
					local log = sgs.LogMessage()
					log.type = "$keliubeinomoney"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinomoney")
				end
				if (player:getMark("@kecaoxie") >= 4) then
					room:removePlayerMark(player, "@kecaoxie", 4)
					room:addSlashCishu(player, 1, false)
					room:addPlayerMark(player, "@liubeisha")
					local log = sgs.LogMessage()
					log.type = "$keliubeibuy"
					log.from = player
					room:sendLog(log)
					room:broadcastSkillInvoke("bensos")
					room:doLightbox("$keliubeibuy")
					room:setPlayerFlag(player, "alreadybuy")
				end
			end
			if bc == "judge" then
				if (player:getMark("@kecaoxie") < 3) then
					room:broadcastSkillInvoke("kenewzahuo", 1)
					local log = sgs.LogMessage()
					log.type = "$keliubeinomoney"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinomoney")
				end
				if (player:getMark("@kecaoxie") >= 3) then
					room:removePlayerMark(player, "@kecaoxie", 3)
					player:throwJudgeArea()
					local log = sgs.LogMessage()
					log.type = "$keliubeibuy"
					log.from = player
					room:sendLog(log)
					room:broadcastSkillInvoke("bensos")
					room:doLightbox("$keliubeibuy")
					room:setPlayerFlag(player, "alreadybuy")
				end
			end
			if bc == "maxhand" then
				if (player:getMark("@kecaoxie") < 3) then
					room:broadcastSkillInvoke("kenewzahuo", 1)
					local log = sgs.LogMessage()
					log.type = "$keliubeinomoney"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinomoney")
				end
				if (player:getMark("@kecaoxie") >= 3) then
					room:removePlayerMark(player, "@kecaoxie", 3)
					room:addMaxCards(player, 1, false)
					room:addPlayerMark(player, "@liubeishoupai")
					local log = sgs.LogMessage()
					log.type = "$keliubeibuy"
					log.from = player
					room:sendLog(log)
					room:broadcastSkillInvoke("bensos")
					room:doLightbox("$keliubeibuy")
					room:setPlayerFlag(player, "alreadybuy")
				end
			end
			if bc == "msg" then
				if (player:getMark("@kecaoxie") < 1) then
					room:broadcastSkillInvoke("kenewzahuo", 1)
					local log = sgs.LogMessage()
					log.type = "$keliubeinomoney"
					log.from = player
					room:sendLog(log)
					room:doLightbox("$keliubeinomoney")
				end
				if (player:getMark("@kecaoxie") >= 1) then
					room:removePlayerMark(player, "@kecaoxie", 1)
					local eny = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
						"liubeimsg-ask")
					if eny then
						room:showAllCards(eny, player)
					end
					local log = sgs.LogMessage()
					log.type = "$keliubeibuy"
					log.from = player
					room:sendLog(log)
					room:broadcastSkillInvoke("bensos")
					room:doLightbox("$keliubeibuy")
					room:setPlayerFlag(player, "alreadybuy")
				end
			end
		end
	end
}


--主技能
kenewzahuoVS = sgs.CreateViewAsSkill {
	name = "kenewzahuo",
	n = 0,
	view_as = function(self, cards)
		return kenewzahuoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasFlag("alreadybuy"))
	end,
}

kenewzahuo = sgs.CreateTriggerSkill {
	name = "kenewzahuo&",
	view_as_skill = kenewzahuoVS,
	events = { sgs.Damaged, sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isAlive() then
			local damage = data:toDamage()
			for i = 0, damage.damage - 1, 1 do
				if player:getMark("@kecaoxie") < 10 then
					player:gainMark("@kecaoxie")
				end
			end
		end
	end
}
kenewliubei:addSkill(kenewzahuo)





xiafcchengtiandi = sgs.General(extension, "xiafcchengtiandi", "kexian", 4, true, true, true)

xiatiananex = sgs.CreateTargetModSkill {
	name = "xiatiananex",
	distance_limit_func = function(self, from, card)
		if (card:isKindOf("BasicCard")) and from:hasSkill("xiatianan") then
			return 999
		end
	end
}
if not sgs.Sanguosha:getSkill("xiatiananex") then skills:append(xiatiananex) end

xiatiananextwo = sgs.CreateTargetModSkill {
	name = "xiatiananextwo",
	pattern = "TrickCard",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("xiatianan") then
			return 1000
		else
			return 0
		end
	end,
}
if not sgs.Sanguosha:getSkill("xiatiananextwo") then skills:append(xiatiananextwo) end

xiatianan = sgs.CreateTriggerSkill {
	name = "xiatianan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged, sgs.Damage },
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isAlive() then
			local damage = data:toDamage()
			if (damage.nature ~= sgs.DamageStruct_Normal) then
				local judge = sgs.JudgeStruct()
				if damage.card and damage.card:isRed() then
					judge.pattern = ".|red"
				elseif damage.card and damage.card:isBlack() then
					judge.pattern = ".|black"
				end
				judge.good = true
				judge.play_animation = true
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				if damage.card then
					if (judge.card:getColor() == damage.card:getColor()) then
						local result = room:askForChoice(player, self:objectName(), "pandingpai+mopai")
						if result == "pandingpai" then
							player:obtainCard(judge.card)
						end
						if result == "mopai" then
							player:drawCards(1)
						end
					else
						local ran = math.random(1, 2)
						if ran == 1 then
							player:obtainCard(judge.card)
						else
							player:drawCards(1)
						end
					end
				else
					local ran = math.random(1, 2)
					if ran == 1 then
						player:obtainCard(judge.card)
					else
						player:drawCards(1)
					end
				end
			end
		end
		return false
	end
}
xiafcchengtiandi:addSkill(xiatianan)

xiaxingmie = sgs.CreateTriggerSkill {
	name = "xiaxingmie",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseChanging, sgs.TurnStart, sgs.CardUsed, sgs.StartJudge, sgs.Damage, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_RoundStart) then
				--回合开始时判断符合几项
				if player:hasSkill("xiaxingmieslash") then
					room:handleAcquireDetachSkills(player, "-xiaxingmieslash")
				end
				local num = player:getMark("xmmzgs")
				player:drawCards(num)
				room:addMaxCards(player, num, true)
				if (num >= 1) then
					if not player:hasSkill("xiaxingmieslash") then
						room:handleAcquireDetachSkills(player, "xiaxingmieslash")
					end
					if player:hasSkill("xiaxingmieslash") then
						room:addPlayerMark(player, "canusexiaxingmieslash")
					end
				end
				if (num >= 3) then
					local slashs = {}
					for _, id in sgs.qlist(room:getDiscardPile()) do
						local ran_card = sgs.Sanguosha:getCard(id)
						if ran_card:isKindOf("FireSlash") then
							table.insert(slashs, ran_card)
						end
					end
					local ran = slashs[math.random(1, #slashs)]
					if ran then room:obtainCard(player, ran) end
				end
				if (num >= 5) then
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:canSlash(p, nil, false) then
							players:append(p)
						end
					end
					if not players:isEmpty() then
						local eny = room:askForPlayerChosen(player, players, self:objectName(), "fcslash-ask", true, true)
						if eny then
							local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
							slash:setSkillName(self:objectName())
							local card_use = sgs.CardUseStruct()
							card_use.from = player
							card_use.to:append(eny)
							card_use.card = slash
							room:useCard(card_use, false)
							slash:deleteLater()
						end
					end
				end
				if (num >= 7) then
					local yz = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
						"fcseven-ask", true, true)
					if yz then
						local hurt = 1
						if yz:isKongcheng() then hurt = hurt + 1 end
						if (yz:getEquips():length() == 0) then hurt = hurt + 1 end
						if (yz:getJudgingArea():length() == 0) then hurt = hurt + 1 end
						room:damage(sgs.DamageStruct(self:objectName(), player, yz, hurt, sgs.DamageStruct_Fire))
					end
				end
				--用完就清除统计
				room:setPlayerMark(player, "xmmzgs", 0)
			end
		end
		if (event == sgs.TurnStart) then
			--先提前统计好满足的数量，传递给下一个时机
			local gs = player:getMark("&xmslash") + player:getMark("&xmdrank") + player:getMark("&xmpeach") +
				player:getMark("&xmweapon") + player:getMark("&xmjudge") + player:getMark("&xmfire") +
				player:getMark("&xmwuxie")
			room:setPlayerMark(player, "xmmzgs", gs)
			room:setPlayerMark(player, "&xmslash", 0)
			room:setPlayerMark(player, "&xmdrank", 0)
			room:setPlayerMark(player, "&xmpeach", 0)
			room:setPlayerMark(player, "&xmweapon", 0)
			room:setPlayerMark(player, "&xmjudge", 0)
			room:setPlayerMark(player, "&xmfire", 0)
			room:setPlayerMark(player, "&xmwuxie", 0)
		end
		--分别判断满足七项条件：
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				if not use.card:isVirtualCard() then
					room:setPlayerMark(player, "&xmslash", 1)
				end
			end
			if use.card:isKindOf("Peach") then
				for _, p in sgs.qlist(use.to) do
					if (p:getHp() <= 0) then
						room:setPlayerMark(player, "&xmpeach", 1)
					end
				end
			end
			if use.card:isKindOf("Weapon") then
				room:setPlayerMark(player, "&xmweapon", 1)
			end
			if use.card:isKindOf("Nullification") then
				room:setPlayerMark(player, "&xmwuxie", 1)
			end
		end
		if (event == sgs.StartJudge) then
			local judge = data:toJudge()
			if judge.who == player then
				room:setPlayerMark(player, "&xmjudge", 1)
			end
		end
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if (damage.nature == sgs.DamageStruct_Fire) then
				room:setPlayerMark(player, "&xmfire", 1)
			end
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("drank") then
				room:setPlayerMark(player, "&xmdrank", 1)
			end
		end
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:isKindOf("Jink") then
				room:setPlayerMark(player, "&xmwuxie", 1)
			end
			if (use.card:getSkillName() == "xiaxingmieslash") then
				--每轮限一次
				room:setPlayerMark(player, "xiaxingmieslash_lun", 1)
			end
		end
	end,
}
xiafcchengtiandi:addSkill(xiaxingmie)

xiaxingmieslash = sgs.CreateOneCardViewAsSkill {
	name = "xiaxingmieslash&",
	response_or_use = true,
	view_filter = function(self, card)
		if (card:getSuit() ~= sgs.Card_Heart) then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and (player:getMark("xiaxingmieslash_lun") < 1)
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash") and (player:getMark("xiaxingmieslash_lun") < 1)
	end
}
if not sgs.Sanguosha:getSkill("xiaxingmieslash") then skills:append(xiaxingmieslash) end

kenewcaoren = sgs.General(extension, "kenewcaoren", "wei", 4, true, false, false, 3, 2)

function kenewgetCardList(intlist)
	local ids = sgs.CardList()
	for _, id in sgs.qlist(intlist) do
		ids:append(sgs.Sanguosha:getCard(id))
	end
	return ids
end

--[[
keyugongCard = sgs.CreateSkillCard{
	name = "keyugongCard",
	target_fixed = true,
	on_use = function(self, room, source, target)
		local cg = 0
		--room:broadcastSkillInvoke("")
		if (source:getChangeSkillState("keyugong") == 1) then
			cg = 1
			room:setChangeSkillState(source, "keyugong", 2)
			source:drawCards(1)
			local to_all = sgs.IntList()
			for _,c in sgs.qlist(source:getCards("h")) do
				if not c:isDamageCard() then
					to_all:append(c:getId())
				end
			end
			if not to_all:isEmpty() then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if not to_all:isEmpty() then
					dummy:addSubcards(kenewgetCardList(to_all))
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, source:objectName(), self:objectName(),"")
					room:throwCard(dummy, reason, nil)
				end
				dummy:deleteLater()
			end
			local num = to_all:length()
			if (num > 0) then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local damagecards = sgs.IntList()
				local getnum = 0
				for _, id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isDamageCard() then
						damagecards:append(id)
						getnum = getnum + 1
						if (getnum == num) then
							break
						end
					end
				end
				dummy:addSubcards(kenewgetCardList(damagecards))
				source:obtainCard(dummy)
				room:addPlayerMark(source,"&keyugongslashcishu-Clear",1)
			end
			room:addSlashCishu(source,1, true)
		end
		if (source:getChangeSkillState("keyugong") == 2) and (cg == 0)then
			room:setChangeSkillState(source, "keyugong", 1)
			source:drawCards(1)
			local to_all = sgs.IntList()
			for _,c in sgs.qlist(source:getCards("h")) do
				if  c:isDamageCard() then
					to_all:append(c:getId())
				end
			end
			if not to_all:isEmpty() then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if not to_all:isEmpty() then
					dummy:addSubcards(kenewgetCardList(to_all))
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, source:objectName(), self:objectName(),"")
					room:throwCard(dummy, reason, nil)
				end
				dummy:deleteLater()
			end
			local num = to_all:length()
			if (num > 0) then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local nodamagecards = sgs.IntList()
				local getnum = 0
				for _, id in sgs.qlist(room:getDrawPile()) do
					if not sgs.Sanguosha:getCard(id):isDamageCard() then
						nodamagecards:append(id)
						getnum = getnum + 1
						if (getnum == num) then
							break
						end
					end
				end
				dummy:addSubcards(kenewgetCardList(nodamagecards))
				source:obtainCard(dummy)
				room:addPlayerMark(source,"&keyugongmax-Clear",1)
			end
			source:gainHujia(1)
			room:addMaxCards(source, 1, true)
		end
	end
}
]]
keyugongCard = sgs.CreateSkillCard {
	name = "keyugongCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, target)
		local cg = 0
		--room:broadcastSkillInvoke("")
		if (source:getChangeSkillState("keyugong") == 1) then
			cg = 1
			room:setChangeSkillState(source, "keyugong", 2)
			local damagecards = sgs.IntList()
			local getdamagecards = sgs.IntList()
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isDamageCard() then
					damagecards:append(id)
				end
			end
			local ran = 0
			for i = 0, 1, 1 do
				if not damagecards:isEmpty() then
					if (damagecards:length() >= 2) then
						ran = math.random(0, damagecards:length() - 1)
						getdamagecards:append(damagecards:at(ran))
						damagecards:removeOne(damagecards:at(ran))
					else
						getdamagecards:append(damagecards:at(ran))
						damagecards:removeOne(damagecards:at(ran))
					end
				end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:addSubcards(kenewgetCardList(getdamagecards))
			source:obtainCard(dummy)
			dummy:deleteLater()
			room:addPlayerMark(source, "&keyugongslashcishu-Clear", 1)
			room:addSlashCishu(source, 1, true)
		end
		if (source:getChangeSkillState("keyugong") == 2) and (cg == 0) then
			room:setChangeSkillState(source, "keyugong", 1)
			local notdamagecards = sgs.IntList()
			local getnotdamagecards = sgs.IntList()
			for _, id in sgs.qlist(room:getDrawPile()) do
				if not sgs.Sanguosha:getCard(id):isDamageCard() then
					notdamagecards:append(id)
				end
			end
			local ran = 0
			for i = 0, 1, 1 do
				if not notdamagecards:isEmpty() then
					if (notdamagecards:length() >= 2) then
						ran = math.random(0, notdamagecards:length() - 1)
						getnotdamagecards:append(notdamagecards:at(ran))
						notdamagecards:removeOne(notdamagecards:at(ran))
					else
						getnotdamagecards:append(notdamagecards:at(ran))
						notdamagecards:removeOne(notdamagecards:at(ran))
					end
				end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:addSubcards(kenewgetCardList(getnotdamagecards))
			source:obtainCard(dummy)
			dummy:deleteLater()
			room:addPlayerMark(source, "&keyugongmax-Clear", 1)
			source:gainHujia(1)
			room:addMaxCards(source, 1, true)
		end
	end
}
keyugongVS = sgs.CreateViewAsSkill {
	name = "keyugong",
	n = 1,
	view_filter = function(self, selected, to_select)
		return ((not to_select:isDamageCard()) and (sgs.Self:getChangeSkillState("keyugong") == 1))
			or (to_select:isDamageCard() and (sgs.Self:getChangeSkillState("keyugong") == 2))
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = keyugongCard:clone()
			card:addSubcard(cards[1])
			return card
		else
			return nil
		end
		--return keyugongCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#keyugongCard")
	end
}
keyugong = sgs.CreatePhaseChangeSkill {
	name = "keyugong",
	change_skill = true,
	view_as_skill = keyugongVS,
	on_phasechange = function(self, player)

	end
}
kenewcaoren:addSkill(keyugong)

keyanzhengVS = sgs.CreateViewAsSkill {
	name = "keyanzheng",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		local c = sgs.Sanguosha:cloneCard("nullification")
		c:setSkillName("keyanzheng")
		for _, ic in sgs.list(cards) do
			c:addSubcard(ic)
		end
		return #cards > 0 and c
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return (player:getMark("cankeyanzheng") > 0)
	end,
	enabled_at_nullification = function(self, player)
		return (player:getMark("cankeyanzheng") > 0)
	end
}

keyanzheng = sgs.CreateTriggerSkill {
	name = "keyanzheng",
	view_as_skill = keyanzhengVS,
	events = { sgs.CardEffected, sgs.PostCardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardEffected) then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("TrickCard") then
				room:setPlayerMark(player, "cankeyanzheng", 1)
			end
		elseif (event == sgs.PostCardEffected) then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("TrickCard") then
				room:setPlayerMark(player, "cankeyanzheng", 0)
			end
		end
	end,
}
kenewcaoren:addSkill(keyanzheng)


kenewdengai = sgs.General(extension, "kenewdengai", "wei", 4)

kepihuang = sgs.CreateTriggerSkill {
	name = "kepihuang",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardUsed, sgs.CardResponded, sgs.CardsMoveOneTime, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Start) then
			local room = player:getRoom()
			room:setPlayerMark(player, "&keppihuangbozhong", 0)
			room:setPlayerMark(player, "&keppihuangfengshou", 0)
			room:broadcastSkillInvoke(self:objectName())
			local result = room:askForChoice(player, "kepihuang", "bozhong+fengshou")
			if result == "bozhong" then
				if player:getMark("&ketian") < 5 then
					--[[if player:getMark("&ketian") < 4 then
					    room:broadcastSkillInvoke(self:objectName())
					end]]
					player:gainMark("&ketian")
				end
				room:setPlayerMark(player, "&keppihuangbozhong", 1)
			end
			if result == "fengshou" then
				player:drawCards(1)
				room:setPlayerMark(player, "&keppihuangfengshou", 1)
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if (use.card:isBlack()) and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) and (player:getMark("&keppihuangfengshou") > 0) then
				if (player:getMark("&ketian") > 0) then
					player:loseMark("&ketian")
				end
			end
			if use.card:isKindOf("EquipCard") and (player:getMark("&keppihuangbozhong") > 0) then
				if player:getMark("&ketian") < 5 then
					player:gainMark("&ketian")
				end
			end
		end
		if (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			if response.m_card:isKindOf("Jink") and response.m_card:isBlack() and (player:getMark("&keppihuangfengshou") > 0) then
				if player:getMark("&ketian") < 5 then
					player:gainMark("&ketian")
				end
			end
		end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and (move.from:objectName() == player:objectName())
				and (move.from_places:contains(sgs.Player_PlaceHand))
			then
				local canuse = 0
				for _, id in sgs.qlist(move.card_ids) do
					canuse = 0
					local card = sgs.Sanguosha:getCard(id)
					if (player:getMark("&keppihuangbozhong") > 0) and ((card:isRed() and card:isKindOf("BasicCard"))) then
						canuse = 1
					end
					if canuse == 1 then
						if player:getMark("&ketian") < 5 then
							player:gainMark("&ketian")
						end
					end
				end
			end
		end
	end
}
kenewdengai:addSkill(kepihuang)

kezaoxian = sgs.CreatePhaseChangeSkill {
	name = "kezaoxian",
	frequency = sgs.Skill_Wake,
	waked_skills = "kezhuxian",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		room:notifySkillInvoked(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("kenewdengai", "kezaoxian")
		room:setPlayerMark(player, self:objectName(), 1)
		if room:changeMaxHpForAwakenSkill(player) then
			if player:isWounded() and room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
				room:recover(player, sgs.RecoverStruct(player))
			else
				room:drawCards(player, 2)
			end
			if (player:getMark(self:objectName()) == 1) then
				room:acquireSkill(player, "kezhuxian")
			end
		end
		return false
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("&ketian") < 5 then
			return false
		end
		return true
	end,
}
kenewdengai:addSkill(kezaoxian)

kezhuxian = sgs.CreateTriggerSkill {
	name = "kezhuxian",
	frequency = sgs.Skill_Frequent,
	events = { sgs.MarkChanged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.MarkChanged) then
			local mark = data:toMark()
			if mark.name == "&ketian" then
				if (mark.gain < 0) then
					local num = 0 - mark.gain
					for i = 0, num - 1, 1 do
						room:broadcastSkillInvoke(self:objectName())
						local players = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if (p:objectName() ~= player:objectName()) and not p:isNude() then
								players:append(p)
							end
						end
						local eny = room:askForPlayerChosen(player, players, self:objectName(), "kezhuxianget-ask", true,
							true)
						if eny then
							local card_id = room:askForCardChosen(player, eny, "he", self:objectName())
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
							room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason,
								room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
						end
					end
				elseif (mark.gain > 0) then
					local num = mark.gain
					for i = 0, num - 1, 1 do
						if room:askForSkillInvoke(player, self:objectName(), data) then
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(1)
						end
					end
				end
			end
		end
	end,
}
if not sgs.Sanguosha:getSkill("kezhuxian") then skills:append(kezhuxian) end




kenewjiangwei = sgs.General(extension, "kenewjiangwei", "shu", 4, true)

ketiaoxinCard = sgs.CreateSkillCard {
	name = "ketiaoxinCard",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and
			(to_select:getCardCount(true, true) > 0)
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()

		room:setPlayerFlag(effect.from, "kezhijibagua")
		local use_slash = false
		if effect.from:canDiscard(effect.to, "hej") then
			room:throwCard(
				room:askForCardChosen(effect.from, effect.to, "hej", "ketiaoxin", false, sgs.Card_MethodDiscard),
				effect.to,
				effect.from)
		end
		if effect.to:canSlash(effect.from, nil, false) then
			use_slash = room:askForUseSlashTo(effect.to, effect.from, "ketiaoxin-slash", false, false, true, nil, nil,
				"ketiaoxinsha")
		end
		while effect.from:hasFlag("kejixutiaoxin") do
			room:setPlayerFlag(effect.from, "extiaoxining")
			room:setPlayerFlag(effect.from, "-kejixutiaoxin")
			--room:setPlayerFlag(effect.from,"-ketiaoxinhit")
			local use_slash = false
			local players = sgs.SPlayerList()
			players:append(effect.to)
			local eny = room:askForPlayerChosen(effect.from, players, "ketiaoxin", "ketiaoxinjixu-ask", true, true)
			if eny then
				--room:broadcastSkillInvoke("kezhiji",math.random(3,8))
				room:broadcastSkillInvoke("ketiaoxin")
				if effect.from:canDiscard(effect.to, "he") then
					room:throwCard(
						room:askForCardChosen(effect.from, effect.to, "hej", "ketiaoxin", false, sgs.Card_MethodDiscard),
						effect.to, effect.from)
				end
				if effect.to:canSlash(effect.from, nil, false) then
					use_slash = room:askForUseSlashTo(effect.to, effect.from, "ketiaoxin-slash", false, false, true, nil,
						nil, "ketiaoxinsha")
				end
				if not use_slash then
					--room:broadcastSkillInvoke("ketiaoxin")
					effect.from:drawCards(1)
				end
			end
		end
		if (not use_slash) and (not effect.from:hasFlag("extiaoxining")) then
			--room:broadcastSkillInvoke("ketiaoxin")
			effect.from:drawCards(1)
		end
		room:setPlayerFlag(effect.from, "-extiaoxining")
		room:setPlayerFlag(effect.from, "-kejixutiaoxin")
		room:setPlayerFlag(effect.from, "-kezhijibagua")
	end
}
ketiaoxinVS = sgs.CreateViewAsSkill {
	name = "ketiaoxin",
	n = 0,
	view_as = function()
		return ketiaoxinCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ketiaoxinCard")
	end
}

ketiaoxin = sgs.CreateTriggerSkill {
	name = "ketiaoxin",
	view_as_skill = ketiaoxinVS,
	events = { sgs.CardFinished, sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card:hasFlag("ketiaoxinsha") then
				room:setCardFlag(damage.card, "-ketiaoxinsha")
				--room:setPlayerFlag(jw,"ketiaoxinhit")
			end
		end
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:isDamageCard() and use.card:hasFlag("ketiaoxinsha") then
				local jw = use.to:at(0)
				room:setPlayerFlag(jw, "kejixutiaoxin")
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kenewjiangwei:addSkill(ketiaoxin)

kezhiji = sgs.CreateTriggerSkill {
	name = "kezhiji",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Wake,
	waked_skills = "kejwkuitian",
	on_trigger = function(self, event, player, data, room)
		room:notifySkillInvoked(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		room:doSuperLightbox("kenewjiangwei", "kezhiji")
		room:setPlayerMark(player, self:objectName(), 1)
		if room:changeMaxHpForAwakenSkill(player) then
			if player:isWounded() and room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
				room:recover(player, sgs.RecoverStruct(player))
			else
				room:drawCards(player, 2)
			end
			if player:getMark(self:objectName()) == 1 then
				room:acquireSkill(player, "kejwkuitian")
				if not player:hasSkill("kezhijiex") then
					room:acquireSkill(player, "kezhijiex")
				end
			end
		end
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getHandcardNum() <= 1  then return true end
		return false
	end,
}
kenewjiangwei:addSkill(kezhiji)
kezhijiexex = sgs.CreateTriggerSkill {
	name = "#kezhijiexex",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.CardResponded) then
			local use = data:toCardResponse()
			local room = player:getRoom()
			if use.m_toCard:hasFlag("ketiaoxinsha") then
				room:broadcastSkillInvoke("kezhiji", math.random(3, 8))
			end
		end
	end
}
kezhijiex = sgs.CreateViewAsEquipSkill {
	name = "#kezhijiex",
	view_as_equip = function(self, player)
		if player:hasFlag("kezhijibagua") then
			return "eight_diagram"
		end
	end
}
--if not sgs.Sanguosha:getSkill("kezhijiex") then skills:append(kezhijiex) end
kenewjiangwei:addSkill(kezhijiex)
kenewjiangwei:addSkill(kezhijiexex)
extension:insertRelatedSkills("kezhiji", "#kezhijiex")
extension:insertRelatedSkills("kezhiji", "#kezhijiexex")

kejwkuitian = sgs.CreateTriggerSkill {
	name = "kejwkuitian",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				local room = player:getRoom()
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if not p:isKongcheng() then
							players:append(p)
						end
					end
					local count = 1
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if ((player:getRole() == "rebel") and (p:getRole() == "rebel"))
							or ((player:getRole() == "lord") and ((p:getRole() == "loyalist") or (p:getRole() == "lord")))
							or ((player:getRole() == "loyalist") and ((p:getRole() == "loyalist") or (p:getRole() == "lord"))) then
							count = count + 1
						end
					end
					local fcard_ids = room:getNCards(count)
					local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "kejwkuitian",
						"kejwkuitian-ask", true, true)
					if target then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, c in sgs.qlist(target:getCards("h")) do
							--room:moveCardTo(c, p, sgs.Player_DrawPile)
							room:addPlayerMark(target, "jwkuitianmove")
							fcard_ids:append(c:getId())
							dummy:addSubcard(c:getId())
						end
						room:moveCardTo(dummy, target, sgs.Player_DrawPile)
						dummy:deleteLater()
						room:broadcastSkillInvoke(self:objectName())
						room:askForGuanxing(player, fcard_ids)
						local result = room:askForChoice(player, self:objectName(), "fromup+fromass")
						if result == "fromup" then
							target:drawCards(target:getMark("jwkuitianmove"), self:objectName())
						end
						if result == "fromass" then
							target:drawCards(target:getMark("jwkuitianmove"), self:objectName(), false)
						end
						room:setPlayerMark(target, "jwkuitianmove", 0)
					end
				end
			end
		end
	end
}
if not sgs.Sanguosha:getSkill("kejwkuitian") then skills:append(kejwkuitian) end


kenewcaozhi = sgs.General(extension, "kenewcaozhi", "wei", 3, true)
kenewcaozhiylqh = sgs.General(extension, "kenewcaozhiylqh", "wei", 3, true, true, true)


local function kechsize(tmp)
	if not tmp then
		return 0
	elseif tmp > 240 then
		return 4
	elseif tmp > 225 then
		return 3
	elseif tmp > 192 then
		return 2
	else
		return 1
	end
end

local function keutf8len(str)
	local length = 0
	local currentIndex = 1
	while currentIndex <= #str do
		local tmp    = string.byte(str, currentIndex)
		currentIndex = currentIndex + kechsize(tmp)
		length       = length + 1
	end
	return length
end

kenewcaozhichange = sgs.CreateTriggerSkill {
	name = "#kenewcaozhichange",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameReady },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:hasSkill(self:objectName())) then
			local result = room:askForChoice(player, "kenewcaozhichange", "qbjz+ylqh")
			if result == "qbjz" then
				room:setPlayerMark(player, "czqbjz", 1)
			end
			if result == "ylqh" then
				room:changeHero(player, "kenewcaozhiylqh", false, true, player:getGeneral2Name()=="kenewcaozhi", false)
				room:setPlayerMark(player, "czylqh", 1)
			end
		end
	end,
	priority = 5,
}
kenewcaozhi:addSkill(kenewcaozhichange)


kemingding = sgs.CreateTriggerSkill {
	name = "kemingding",
	events = { sgs.CardUsed, sgs.CardResponded },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		if event == sgs.CardUsed then
			local room = player:getRoom()
			local use = data:toCardUse()
			room:addPlayerMark(player, "&kemingding-Clear")
			if (player:getMark("&kemingding-Clear") == keutf8len(sgs.Sanguosha:translate(use.card:objectName()))) then
				if (player:getMark("czqbjz") == 1) then
					local num = math.random(1, 2)
					if (num == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					else
						room:broadcastSkillInvoke("kejueyin", math.random(1, 2))
					end
				elseif (player:getMark("czylqh") == 1) then
					local num = math.random(1, 2)
					if (num == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
					else
						room:broadcastSkillInvoke("kejueyin", math.random(3, 4))
					end
				end
				--if (player:getPhase() ~= sgs.Player_NotActive) then
				player:drawCards(1)
				--else
				--	player:drawCards(2)
				--end
			end
		end
		if (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			local room = player:getRoom()
			room:addPlayerMark(player, "&kemingding-Clear")
			if (player:getMark("&kemingding-Clear") == keutf8len(sgs.Sanguosha:translate(response.m_card:objectName()))) then
				if (player:getMark("czqbjz") == 1) then
					local num = math.random(1, 2)
					if (num == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					else
						room:broadcastSkillInvoke("kejueyin", math.random(1, 2))
					end
				elseif (player:getMark("czylqh") == 1) then
					local num = math.random(1, 2)
					if (num == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
					else
						room:broadcastSkillInvoke("kejueyin", math.random(3, 4))
					end
				end
				--if (player:getPhase() ~= sgs.Player_NotActive) then
				player:drawCards(1)
				--else
				--	player:drawCards(2)
				--end
			end
		end
	end,
}
kenewcaozhi:addSkill(kemingding)
kenewcaozhiylqh:addSkill(kemingding)


kejueyin = sgs.CreateTriggerSkill {
	name = "kejueyin",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kejueyinmark",
	events = { sgs.AskForPeachesDone, sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.AskForPeachesDone) then
			local death = data:toDeath()
			if (player:getHp() < 1) and (player:getMark("@kejueyinmark") > 0) then
				room:removePlayerMark(player, "@kejueyinmark")
				if (player:getMark("czqbjz") == 1) then
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					room:doSuperLightbox("kenewcaozhi", "kejueyin")
				elseif (player:getMark("czylqh") == 1) then
					room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
					room:doSuperLightbox("kenewcaozhiylqh", "kejueyin")
				end
				local cha = 7 - player:getHandcardNum()
				if cha > 0 then
					player:drawCards(cha)
				end
				local pattern = {}
				local num = 0
				while true do
					pattern = {}
					for _, c in sgs.qlist(player:getCards("h")) do
						if (not player:isJilei(c)) and (c:isAvailable(player)) then
							table.insert(pattern, c:getEffectiveId())
						end
					end
					local to_use = sgs.IntList()
					for _, c in sgs.qlist(player:getCards("h")) do
						if (not player:isJilei(c)) and (c:isAvailable(player)) then
							to_use:append(c:getId())
						end
					end
					if not to_use:isEmpty() then
						if not room:askForUseCard(player, table.concat(pattern, ","), "kemingjianuse-ask") then
							break
						end
						num = num + 1
						if (num == 7) then
							break
						end
					else
						break
					end
				end
			end
		end
	end,
}
kenewcaozhi:addSkill(kejueyin)
kenewcaozhiylqh:addSkill(kejueyin)


kenewliuchen = sgs.General(extension, "kenewliuchen$", "shu", 4, true)

kenewwenxiangCard = sgs.CreateSkillCard {
	name = "kenewwenxiangCard",
	will_throw = false,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:getMark("usedkenewwenxiang-PlayClear") == 0)
	end,
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local msg = sgs.LogMessage()
		msg.type = "$kenewwenxianglog"
		msg.from = source
		msg.arg = card:objectName()
		msg.arg2 = source:getGeneralName()
		room:sendLog(msg)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName())
		room:moveCardTo(card, source, sgs.Player_DiscardPile, reason)
		source:drawCards(1)

		local target = targets[1]
		room:setPlayerMark(target, "usedkenewwenxiang-PlayClear", 1)
		room:damage(sgs.DamageStruct("kenewwenxiang", source, target))
		local result = room:askForChoice(target, "kenewwenxiang", "get+noget")
		if result == "get" then
			if target:isAlive() then
				target:obtainCard(self)
			end
			local blas = sgs.IntList()
			for _, id in sgs.qlist(room:getDrawPile()) do
				if (sgs.Sanguosha:getCard(id):isBlack()) then
					blas:append(id)
					if (blas:length() == 2) then
						break
					end
				end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, id in sgs.qlist(blas) do
				dummy:addSubcard(id)
			end
			source:obtainCard(dummy)
			dummy:deleteLater()
		else
			room:setPlayerMark(source, "&bankenewwenxiang-PlayClear", 1)
		end
		if source:objectName() == target:objectName() then
			room:setPlayerMark(source, "&bankenewwenxiang-PlayClear", 1)
		end
	end,
}

kenewwenxiang = sgs.CreateViewAsSkill {
	name = "kenewwenxiang",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = kenewwenxiangCard:clone()
			card:addSubcard(cards[1])
			return card
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("&bankenewwenxiang-PlayClear") == 0
	end,
}
kenewliuchen:addSkill(kenewwenxiang)

kenewlixing = sgs.CreateTriggerSkill {
	name = "kenewlixing$",
	events = { sgs.BuryVictim },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.BuryVictim) then
			local room = player:getRoom()
			local death = data:toDeath()
			local damage = death.damage
			if damage then
				local killer = damage.from
				local lcs = room:findPlayersBySkillName(self:objectName())
				for _, lc in sgs.qlist(lcs) do
					if lc:hasLordSkill(self:objectName()) then
						if killer then
							if killer:isAlive() and (killer == lc) and (death.who:getRole() == "loyalist") then
								room:broadcastSkillInvoke(self:objectName())
								room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
								player:bury()
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
kenewliuchen:addSkill(kenewlixing)

kenewlixingex = sgs.CreateTriggerSkill {
	name = "kenewlixingex",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.BuryVictim },
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local reason = death.damage
		if reason then
			local killer = reason.from
			if killer and killer:hasLordSkill("kenewlixing") then
				local room = player:getRoom()
				room:setTag("SkipNormalDeathProcess", sgs.QVariant(false))
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = -1,
}
if not sgs.Sanguosha:getSkill("kenewlixingex") then skills:append(kenewlixingex) end

kenewxiahouzie = sgs.General(extension, "kenewxiahouzie", "qun", 3, false)

kenewqingran = sgs.CreateTriggerSkill {
	name = "kenewqingran",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damage, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseEnd) then
			if (player:getPhase() == sgs.Player_Play) then
				if sgs.Slash_IsAvailable(player) then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					local cards = player:drawCardsList(2, self:objectName())
					room:ignoreCards(player, cards)
				end
			end
		end
		if (event == sgs.Damage) and (player:getPhase() == sgs.Player_Play) then
			--room:broadcastSkillInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:addPlayerMark(player, "&kenewqingran-Clear")
			--[[if (player:getHandcardNum() < 3) then
				 player:drawCards(3-player:getHandcardNum())
			 end]]
			room:addSlashCishu(player, 1, true)
		end
	end,
}
kenewxiahouzie:addSkill(kenewqingran)


kenewlvefeng = sgs.CreateTriggerSkill {
	name = "kenewlvefeng",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() then
				local ids = sgs.IntList()
				for _, card in sgs.qlist(damage.from:getHandcards()) do
					ids:append(card:getEffectiveId())
				end
				if (ids:length() == 0) then return false end
				local to_data = sgs.QVariant()
				to_data:setValue(damage.from)
				local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
				if will_use then
					room:broadcastSkillInvoke(self:objectName())
					local card_id = room:doGongxin(player, damage.from, ids)
					if sgs.Sanguosha:getCard(card_id):isDamageCard() then
						local players = sgs.SPlayerList()
						players:append(damage.from)
						room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(card_id), player, players))
					end
					if (card_id == -1) then return end
					if not (sgs.Sanguosha:getCard(card_id):isDamageCard()) then
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), nil,
							"kenewlvefeng", nil)
						room:throwCard(sgs.Sanguosha:getCard(card_id), reason, damage.from, player)
						player:drawCards(1)
					end
				end
			end
		end
	end,
}
kenewxiahouzie:addSkill(kenewlvefeng)

kenewwangyi = sgs.General(extension, "kenewwangyi", "wei", 4, false)

kenewzhenlie = sgs.CreateTriggerSkill {
	name = "kenewzhenlie",
	events = { sgs.TargetConfirmed, sgs.TargetSpecified },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetConfirmed) then
			local use = data:toCardUse()
			if use.to:contains(player) and (use.from:objectName() ~= player:objectName()) then
				if use.card:isKindOf("Slash") or use.card:isNDTrick() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						room:loseHp(player)
						if player:isAlive() then
							local nullified_list = use.nullified_list
							table.insert(nullified_list, player:objectName())
							use.nullified_list = nullified_list
							data:setValue(use)
							if player:canDiscard(use.from, "he") then
								local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false,
									sgs.Card_MethodDiscard)
								room:throwCard(id, use.from, player)
							end
						end
					end
				end
			end
		end
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.card:isDamageCard() then
				if room:askForSkillInvoke(player, "kenewzhenlietwo", data) then
					room:broadcastSkillInvoke(self:objectName())
					room:loseHp(player)
					local no_respond_list = use.no_respond_list
					for _, szm in sgs.qlist(use.to) do
						table.insert(no_respond_list, szm:objectName())
					end
					use.no_respond_list = no_respond_list
					data:setValue(use)
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(use.to) do
						if player:canDiscard(p, "he") then
							players:append(p)
						end
					end
					if not players:isEmpty() then
						local qpr = room:askForPlayerChosen(player, players, self:objectName(), "kenewzhenlie-qipai",
							true, true)
						if qpr then
							local id = room:askForCardChosen(player, qpr, "he", self:objectName(), false,
								sgs.Card_MethodDiscard)
							room:throwCard(id, qpr, player)
						end
					end
				end
			end
		end
	end
}
kenewwangyi:addSkill(kenewzhenlie)


--秘计
kenewmiji = sgs.CreateTriggerSkill {
	name = "kenewmiji",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getPhase() == sgs.Player_Finish) and player:isWounded() then
			if player:askForSkillInvoke(self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				local num = player:getLostHp()
				player:drawCards(math.min(3, num), self:objectName())
				local players = sgs.SPlayerList()
				local allplayers = room:getOtherPlayers(player)
				for _, p in sgs.qlist(allplayers) do
					players:append(p)
				end
				local depai = room:askForPlayerChosen(player, players, self:objectName(), "kenewmiji-ask", true, true)
				if depai then
					local card = room:askForExchange(player, self:objectName(), 100, math.min(1, player:getHandcardNum()),
						false, "kenewmijichoose")
					if card then
						room:obtainCard(depai, card,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), player:objectName(),
								self:objectName(), ""), false)
					end
				end
			end
		end
		return false
	end
}
kenewwangyi:addSkill(kenewmiji)


kenewwolong = sgs.General(extension, "kenewwolong", "shu", 3, true)

kenewbazhen = sgs.CreateTriggerSkill {
	name = "kenewbazhen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardAsked },
	on_trigger = function(self, event, wolong, data)
		local room = wolong:getRoom()
		local pattern = data:toStringList()[1]
		if pattern ~= "jink" then return false end
		if wolong:askForSkillInvoke("kenewbazhen") then
			room:broadcastSkillInvoke(self:objectName())
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red"
			judge.good = true
			judge.reason = "kenewbazhen"
			judge.who = wolong
			judge.play_animation = true
			room:judge(judge)
			if judge:isGood() then
				room:setEmotion(wolong, "armor/EightDiagram");
				local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
				--jink:setSkillName(self:objectName())
				room:provide(jink)
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName())
	end
}
kenewwolong:addSkill(kenewbazhen)


kenewhuojiVS = sgs.CreateOneCardViewAsSkill {
	name = "kenewhuoji",
	filter_pattern = ".|red|.|.",
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local id = card:getId()
		local fireattack = sgs.Sanguosha:cloneCard("FireAttack", suit, point)
		fireattack:setSkillName("kenewhuoji")
		fireattack:addSubcard(id)
		return fireattack
	end
}

kenewhuoji = sgs.CreateTriggerSkill {
	name = "kenewhuoji",
	view_as_skill = kenewhuojiVS,
	priority = 4,
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.card:isKindOf("FireAttack") and effect.to:objectName() == player:objectName() then
			local wl = effect.from
			if not wl:hasSkill(self:objectName()) then return false end
			if room:isCanceled(effect) then
				player:setFlags("Global_NonSkillNullify")
				return true
			end
			if wl:canDiscard(player, "h") then
				local to_throw = room:askForCardChosen(wl, player, "h", "kenewhuoji-dis")
				local hjdiscard = sgs.Sanguosha:getCard(to_throw)
				room:throwCard(hjdiscard, player, wl)
				local to_int
				local todis = room:askForExchange(wl, "kenewhuoji", 1, 1, false, "kenewhuoji-show", true,
						".|"..hjdiscard:getSuitString().."|.|.")
				if todis then
					room:showCard(wl, todis:getSubcards():first())
					room:getThread():delay(300)
					room:damage(sgs.DamageStruct(self:objectName(), wl, player, 1, sgs.DamageStruct_Fire))
				end
			end
			room:setTag("SkipGameRule", sgs.QVariant(tonumber(event)))
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kenewwolong:addSkill(kenewhuoji)


kenewkanpoVS = sgs.CreateOneCardViewAsSkill {
	name = "kenewkanpo",
	filter_pattern = ".|black|.|.",
	response_pattern = "nullification",
	view_as = function(self, first)
		local ncard = sgs.Sanguosha:cloneCard("nullification", first:getSuit(), first:getNumber())
		ncard:addSubcard(first)
		ncard:setSkillName("kenewkanpo")
		return ncard
	end,
	enabled_at_nullification = function(self, player)
		for _, card in sgs.qlist(player:getCards("he")) do
			if card:isBlack() then return true end
		end
		return false
	end
}

kenewkanpo = sgs.CreateTriggerSkill {
	name = "kenewkanpo",
	view_as_skill = kenewkanpoVS,
	events = { sgs.CardUsed, sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("Nullification") and use.from and use.from:hasSkill(self:objectName()) then
				if not use.whocard:isKindOf("Nullification") then
					local no_offset_list = use.no_offset_list
					table.insert(no_offset_list, "_ALL_TARGETS")
					use.no_offset_list = no_offset_list
					data:setValue(use)
					local fris = room:askForPlayersChosen(use.from, room:getAllPlayers(), self:objectName(), 0, 99,
						"kenewkanpo-ask", false, true)
					if (fris:length() > 0) then
						room:setCardFlag(use.whocard, self:objectName())
						for _, fri in sgs.qlist(fris) do
							local msg = sgs.LogMessage()
							msg.type = "#kenewkanpo_Avoid"
							msg.from = fri
							msg.arg = self:objectName()
							msg.card_str = use.whocard:toString()
							room:sendLog(msg)
							room:setPlayerMark(fri, "kenewkanpo"..use.whocard:getEffectiveId(), 1)
						end
					end
				end
			end
		elseif (event == sgs.CardEffected) then
			local effect = data:toCardEffect()
			if effect.card:hasFlag(self:objectName()) and effect.to and effect.to:getMark("kenewkanpo"..effect.card:getEffectiveId()) > 0 then
				room:setPlayerMark(effect.to, "kenewkanpo"..effect.card:getEffectiveId(), 0)
				return true
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
	priority = 4,
}
kenewwolong:addSkill(kenewkanpo)

kenewcangzhuo = sgs.CreateTriggerSkill {
	name = "kenewcangzhuo",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Discard) then
				local ids = sgs.IntList()
				if (player:getMark("kecangzhuojb-Clear") == 0) then
					for _, c in sgs.qlist(player:getCards("h")) do
						if (c:isKindOf("BasicCard")) then
							ids:append(c:getId())
						end
					end
				end
				if (player:getMark("kecangzhuojn-Clear") == 0) then
					for _, c in sgs.qlist(player:getCards("h")) do
						if (c:isKindOf("TrickCard")) then
							ids:append(c:getId())
						end
					end
				end
				if (player:getMark("kecangzhuozb-Clear") == 0) then
					for _, c in sgs.qlist(player:getCards("h")) do
						if (c:isKindOf("EquipCard")) then
							ids:append(c:getId())
						end
					end
				end
				if (ids:length() > 0) then
					room:broadcastSkillInvoke(self:objectName())
					room:ignoreCards(player, ids)
				end
			end
		end
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("BasicCard") and (player:getPhase() ~= sgs.Player_NotActive) then
				room:setPlayerMark(player, "kecangzhuojb-Clear", 1)
			end
			if use.card:isKindOf("TrickCard") and (player:getPhase() ~= sgs.Player_NotActive) then
				room:setPlayerMark(player, "kecangzhuojn-Clear", 1)
			end
			if use.card:isKindOf("EquipCard") and (player:getPhase() ~= sgs.Player_NotActive) then
				room:setPlayerMark(player, "kecangzhuozb-Clear", 1)
			end
		end
	end,
}
kenewwolong:addSkill(kenewcangzhuo)

kenewzhugeliang = sgs.General(extension, "kenewzhugeliang", "shu", 6, true, true, true, 3)
kekuitian = sgs.CreateTriggerSkill {
	name = "kekuitian",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		if (event == sgs.EventPhaseChanging) then
			local room = player:getRoom()
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_RoundStart) then
				local cxs = room:findPlayersBySkillName("kekuitian")
				for _, cx in sgs.qlist(cxs) do
					room:broadcastSkillInvoke(self:objectName())
					local cards = room:getNCards(3)
					room:askForGuanxing(cx, cards)
					local yes = room:askForSkillInvoke(cx, "ktgive", data)
					if yes then
						player:drawCards(1)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
kenewzhugeliang:addSkill(kekuitian)

kebeifaex = sgs.CreateTriggerSkill {
	name = "#kebeifaex",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseChanging then
			local room = player:getRoom()
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&kebeifa") > 0 then
						room:removeFixedDistance(player, p, 1)
						room:setPlayerMark(p, "&kebeifa", 0)
					end
				end
			end
		end
	end
}
kenewzhugeliang:addSkill(kebeifaex)


kebeifaCard = sgs.CreateSkillCard {
	name = "kebeifaCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, player, targets)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:loseMaxHp(player, 1)
		player:drawCards(player:getLostHp())
		local wei = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "kebeifa-ask", true,
			true)
		if wei then
			room:setFixedDistance(player, wei, 1)
			room:addPlayerMark(player, "&kebeifacishu", 1)
			room:setPlayerMark(wei, "&kebeifa", 1)
		end
		local liannus = sgs.IntList()
		for _, id in sgs.qlist(room:getDrawPile()) do
			if (sgs.Sanguosha:getCard(id):isKindOf("Crossbow")) then
				liannus:append(id)
			end
		end
		if not liannus:isEmpty() then
			local numone = math.random(0, liannus:length() - 1)
			player:obtainCard(sgs.Sanguosha:getCard(liannus:at(numone)))
		else
			for _, id in sgs.qlist(room:getDiscardPile()) do
				if (sgs.Sanguosha:getCard(id):isKindOf("Crossbow")) then
					liannus:append(id)
				end
			end
			if not liannus:isEmpty() then
				local numone = math.random(0, liannus:length() - 1)
				player:obtainCard(sgs.Sanguosha:getCard(liannus:at(numone)))
			end
		end
	end
}

kebeifa = sgs.CreateViewAsSkill {
	name = "kebeifa",
	n = 0,
	view_as = function(self, cards)
		return kebeifaCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kebeifaCard")
	end,
}
kenewzhugeliang:addSkill(kebeifa)




kenewsunjian = sgs.General(extension, "kenewsunjian$", "wu", 5, true, false, false, 4)

kewulie = sgs.CreateTriggerSkill {
	name = "kewulie",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.ConfirmDamage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			if (damage.from:getMark("&kewulie") > 0) and (damage.to:isKongcheng()) and (damage.to ~= damage.from) then
				local hurt = damage.damage
				damage.damage = hurt + 1
				room:sendCompulsoryTriggerLog(player, "kewulie")
				room:broadcastSkillInvoke(self:objectName())
				data:setValue(damage)
			end
		end
		if event == sgs.EventPhaseStart then
			if (player:getPhase() == sgs.Player_Start) then
				room:setPlayerMark(player, "&kewulie", 0)
				local los = player:getLostHp() + player:getMark("wulielordadd")
				if (los > 0) then
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAllPlayers()) do
						players:append(p)
					end
					local eny = room:askForPlayersChosen(player, players, self:objectName(), 0, los, "kewulie-ask",
						false, true)
					if (eny:length() > 0) then
						local log = sgs.LogMessage()
						log.type = "$usekewulie"
						log.from = player
						room:sendLog(log)
					end
					local num = eny:length()
					room:setPlayerMark(player, "wulielordadd", 0)
					if not eny:isEmpty() then
						room:broadcastSkillInvoke(self:objectName())
					end
					if num < los then
						room:setPlayerMark(player, "&kewulie", 1)
					end
					for _, p in sgs.qlist(eny) do
						if p:canDiscard(p, "hej") then
							local to_throw = room:askForCardChosen(player, p, "hej", self:objectName())
							local card = sgs.Sanguosha:getCard(to_throw)
							room:throwCard(card, p, player)
						end
					end
				end
			end
		end
	end,
}
kenewsunjian:addSkill(kewulie)

kexihuoCard = sgs.CreateSkillCard {
	name = "kexihuoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0)
	end,
	on_use = function(self, room, player, targets)
		local room = player:getRoom()
		local target = targets[1]
		if (target:getMark("@kexihuo") == 0) then
			room:setPlayerMark(target, "@kexihuo", 1)
			room:setPlayerMark(player, "@kexihuo", 0)
			room:gainMaxHp(target)
			room:gainMaxHp(player)
		end
	end
}


kexihuo = sgs.CreateViewAsSkill {
	name = "kexihuo",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kexihuo",
	n = 0,
	view_as = function(self, cards)
		return kexihuoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kexihuoCard")) and (player:getMark("@kexihuo") > 0)
	end,
}
kenewsunjian:addSkill(kexihuo)


kexihuoKeep = sgs.CreateMaxCardsSkill {
	name = "kexihuoKeep",
	extra_func = function(self, target)
		if (target:getMark("@kexihuo") > 0) then
			return 2
		else
			return 0
		end
	end
}
if not sgs.Sanguosha:getSkill("kexihuoKeep") then skills:append(kexihuoKeep) end

kewulielord = sgs.CreateTriggerSkill {
	name = "kewulielord$",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:hasLordSkill(self:objectName()) then
			if event == sgs.EventPhaseStart then
				if (player:getPhase() == sgs.Player_Start) then
					local num = 0
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getKingdom() == "wu" then
							num = num + 1
						end
					end
					room:setPlayerMark(player, "wulielordadd", num)
				end
			end
		end
	end,
	priority = 99,
}
kenewsunjian:addSkill(kewulielord)



kenewzhaoyun = sgs.General(extension, "kenewzhaoyun", "shu", 4)

keliezhenCard = sgs.CreateSkillCard {
	name = "keliezhenCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, player, targets)
		local room = player:getRoom()
		room:broadcastSkillInvoke("keliezhen", math.random(1, 9))
		room:broadcastSkillInvoke("keliezhen", math.random(10, 13))
		local target = targets[1]
		local players = sgs.SPlayerList()
		local playerstwo = sgs.SPlayerList()
		local extraplayers = sgs.SPlayerList()
		local alwaysplayers = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if player:inMyAttackRange(p) then
				players:append(p)
			end
		end
		room:swapSeat(target, player)
		room:setPlayerMark(target, "liezhenswap", 1)
		room:setPlayerMark(player, "useliezhen", 1)
		for _, pp in sgs.qlist(room:getAllPlayers()) do
			if player:inMyAttackRange(pp) then
				playerstwo:append(pp)
			end
		end
		local newplayersnum = 0
		for _, ppp in sgs.qlist(playerstwo) do
			if not players:contains(ppp) then
				extraplayers:append(ppp)
			end
		end
		for _, pppp in sgs.qlist(playerstwo) do
			if players:contains(pppp) then
				alwaysplayers:append(pppp)
			end
		end
		for _, q in sgs.qlist(extraplayers) do
			room:setPlayerMark(q, "&keliezhen", 1)
			room:setPlayerCardLimitation(q, "use,response", ".|.|.|hand", false)
			room:setEmotion(q, "Arcane/dianxing")
		end
		local eny = room:askForPlayersChosen(player, alwaysplayers, self:objectName(), 0, 99, "keliezhen-ask", false,
			true)
		if not eny:isEmpty() then
			for _, qq in sgs.qlist(eny) do
				if not qq:isNude() then
					local ran = math.random(0, qq:getCards("he"):length() - 1)
					if qq:getCardCount() == 1 then
						ran = 0
					end
					local card = qq:getCards("he"):at(ran)
					room:throwCard(card, qq, player)
					room:addPlayerMark(qq, "@skill_invalidity")
					room:addPlayerMark(qq, "keliezhenskill", 1)
				end
			end
		end
	end
}
--主技能
keliezhenVS = sgs.CreateViewAsSkill {
	name = "keliezhen",
	n = 0,
	view_as = function(self, cards)
		return keliezhenCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#keliezhenCard")) --or (player:getMark("extraliezhen")>0)
	end,
}

keliezhen = sgs.CreateTriggerSkill {
	name = "keliezhen",
	view_as_skill = keliezhenVS,
	--frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseEnd, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("liezhenswap") > 0 then
						if (player:getMark("useliezhen") > 0) then
							room:swapSeat(p, player)
							room:setPlayerMark(p, "liezhenswap", 0)
						end
					end
				end
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&keliezhen") > 0 then
						room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand")
						room:setPlayerMark(p, "&keliezhen", 0)
					end
					if (p:getMark("keliezhenskill") > 0) then
						room:removePlayerMark(p, "@skill_invalidity")
					end
				end
				room:setPlayerMark(player, "useliezhen", 0)
			end
		end
	end,
	can_trigger = function(self, player)
		return player:hasSkill("keliezhen")
	end,
}
--if not sgs.Sanguosha:getSkill("keliezhenex") then skills:append(keliezhenex) end
kenewzhaoyun:addSkill(keliezhen)

kexianglong = sgs.CreateOneCardViewAsSkill {
	name = "kexianglong",
	response_or_use = true,
	enabled_at_play = function(self, target)
		return target:isWounded() or sgs.Slash_IsAvailable(target) or sgs.Analeptic_IsAvailable(target)
	end,
	enabled_at_response = function(self, target, pattern)
		return string.find(pattern, "slash")
			or string.find(pattern, "jink")
			or (string.find(pattern, "peach") and (target:getMark("Global_PreventPeach") == 0))
			or string.find(pattern, "analeptic")
	end,
	view_filter = function(self, card)
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if (sgs.Slash_IsAvailable(sgs.Self) and sgs.Analeptic_IsAvailable(sgs.Self) and sgs.Self:isWounded()) then
				return card:isKindOf("Jink") or card:isKindOf("Peach") or card:isKindOf("Analeptic")
			end
			if (sgs.Slash_IsAvailable(sgs.Self) and sgs.Analeptic_IsAvailable(sgs.Self)) then
				return card:isKindOf("Jink") or card:isKindOf("Peach")
			end
			if (sgs.Slash_IsAvailable(sgs.Self) and sgs.Self:isWounded()) then
				return card:isKindOf("Jink") or card:isKindOf("Analeptic")
			end
			if (sgs.Analeptic_IsAvailable(sgs.Self) and sgs.Self:isWounded()) then
				return card:isKindOf("Peach") or card:isKindOf("Analeptic")
			end
			if sgs.Analeptic_IsAvailable(sgs.Self) then
				return card:isKindOf("Peach")
			end
			if sgs.Slash_IsAvailable(sgs.Self) then
				return card:isKindOf("Jink")
			end
			if (sgs.Self:isWounded()) then
				return card:isKindOf("Analeptic")
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if string.find(pattern, "slash") then
				return card:isKindOf("Jink")
			elseif (pattern == "peach+analeptic") then
				if (sgs.Self:getMark("Global_PreventPeach") > 0) then
					return card:isKindOf("Peach")
				end
				return card:isKindOf("Peach") or card:isKindOf("Analeptic")
			elseif (pattern == "peach") then
				if (sgs.Self:getMark("Global_PreventPeach") == 0) then
					return card:isKindOf("Analeptic")
				end
			elseif (pattern == "analeptic") then
				return card:isKindOf("Peach")
			elseif (pattern == "jink") then
				return card:isKindOf("Slash")
			end
		end
	end,
	view_as = function(self, card)
		if (card:isKindOf("Slash")) then
			local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			jink:addSubcard(card)
			jink:setSkillName(self:objectName())
			return jink;
		elseif card:isKindOf("Jink") then
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:addSubcard(card)
			slash:setSkillName(self:objectName())
			return slash
		elseif (card:isKindOf("Peach")) then
			local ana = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
			ana:addSubcard(card)
			ana:setSkillName(self:objectName())
			return ana
		elseif (card:isKindOf("Analeptic")) then
			local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
			peach:addSubcard(card)
			peach:setSkillName(self:objectName())
			return peach
		else
			return nil
		end
	end,
}
kenewzhaoyun:addSkill(kexianglong)

kexianglongcs = sgs.CreateTriggerSkill {
	name = "kexianglongcs",
	events = { sgs.CardUsed },
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getSkillName() == "kexianglong" then
			if use.m_addHistory then
				room:addPlayerHistory(player, use.card:getClassName(), -1)
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		if use.card:getSkillName() == "kerongchang" then
			if use.m_addHistory then
				room:addPlayerHistory(player, use.card:getClassName(), -1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill("kexianglong") or target:hasSkill("kerongchang")
	end
}
if not sgs.Sanguosha:getSkill("kexianglongcs") then skills:append(kexianglongcs) end


kelongxiang = sgs.CreateTriggerSkill {
	name = "kelongxiang",
	events = { sgs.Damage, sgs.EventPhaseChanging },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			for i = 0, damage.damage - 1, 1 do
				room:addPlayerMark(player, "&kelongxiang-Clear")
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
				if (player:getMark("&kelongxiang-Clear") > 0) then
					local num = player:getMark("&kelongxiang-Clear")
					if num >= 1 then
						local basiccards = sgs.IntList()
						for _, id in sgs.qlist(room:getDrawPile()) do
							if (sgs.Sanguosha:getCard(id):isKindOf("BasicCard")) then
								basiccards:append(id)
							end
						end
						if not basiccards:isEmpty() then
							local numone = math.random(0, basiccards:length() - 1)
							room:obtainCard(player, sgs.Sanguosha:getCard(basiccards:at(numone)), true)
						end
					end
					if num >= 2 then
						local players = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if (p:getHujia() == 0) then
								players:append(p)
							end
						end
						local one = room:askForPlayerChosen(player, players, self:objectName(), "kexianglong-ask", true, true)
						if one then
							one:gainHujia()
						end
					end
					if num >= 3 then
						room:acquireNextTurnSkills(player, self:objectName(), "olyajiao")
					end
				end
			end
		end
	end,
}
kenewzhaoyun:addSkill(kelongxiang)





kenewzhangfei = sgs.General(extension, "kenewzhangfei", "shu", 4)




kechenniangVS = sgs.CreateViewAsSkill {
	name = "kechenniang",
	n = 1,
	mute = true,
	view_filter = function(self, selected, to_select)
		return (to_select:isKindOf("Jink")) or (to_select:isKindOf("EquipCard"))
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local analeptic = sgs.Sanguosha:cloneCard("analeptic", cards[1]:getSuit(), cards[1]:getNumber())
			analeptic:setSkillName(self:objectName())
			analeptic:addSubcard(cards[1])
			return analeptic
		end
	end,
	enabled_at_play = function(self, player)
		local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then return false end
		return player:usedTimes("Analeptic") <=
			sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newanal)
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic")
	end
}

kechenniang = sgs.CreateTriggerSkill {
	name = "kechenniang",
	frequency = sgs.Skill_Compulsory,
	view_as_skill = kechenniangVS,
	events = { sgs.CardEffected, sgs.DamageForseen, sgs.CardFinished, sgs.CardUsed, sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Analeptic") and (effect.to:objectName() == player:objectName()) then
				local zf = effect.to
				if not zf:hasSkill("kechenniang") then return false end
				if (zf:getHp() <= 0) then
					room:setEmotion(zf, "Analeptic")
					local recover = sgs.RecoverStruct()
					recover.who = zf
					recover.recover = 2
					room:recover(zf, recover)
					room:setTag("SkipGameRule", sgs.QVariant(tonumber(event)))
				else
					room:setPlayerMark(zf, "&kechenniang-Clear", 2)
					if not effect.card:isVirtualCard() then
						room:broadcastSkillInvoke("kechenniang")
					end
					room:setEmotion(zf, "Analeptic")
					room:setTag("SkipGameRule", sgs.QVariant(tonumber(event)))
				end
			end
		end
		if event == sgs.DamageForseen then
			local damage = data:toDamage()
			if damage.card and damage.from and (damage.from:getMark("&kechenniang-Clear") > 0) and (not damage.chain) then
				local hurt = damage.damage
				damage.damage = hurt + 1
				data:setValue(damage)
			end
		end
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("kenewpaoxiaocard") then
				room:setCardFlag(damage.card, "-kenewpaoxiaocard")
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isDamageCard() and (use.from:getMark("&kechenniang-Clear") > 0) then
				room:removePlayerMark(use.from, "&kechenniang-Clear", 1)
			end
			if use.card:isDamageCard() and use.card:hasFlag("kenewpaoxiaocard") then
				if use.from:hasSkill("kenewpaoxiao") then
					use.from:drawCards(use.to:length())
				end
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from:hasSkill("kenewpaoxiao") and use.card:isDamageCard() then
				room:setCardFlag(use.card, "kenewpaoxiaocard")
			end
			if use.card:isKindOf("Slash") and (player:getPhase() == sgs.Player_Play) and player:hasSkill("kenewpaoxiao") then
				if not player:hasFlag("kenewpaoxiaoSlashUsed") then
					room:setPlayerFlag(player, "kenewpaoxiaoSlashUsed")
				else
					room:broadcastSkillInvoke("kenewpaoxiao")
				end
			end
		end
	end,
}
kenewzhangfei:addSkill(kechenniang)

kenewpaoxiao = sgs.CreateTargetModSkill {
	name = "kenewpaoxiao",
	residue_func = function(self, player, card)
		if player:hasSkill(self:objectName()) and card:isKindOf("Slash") then
			return 1000
		else
			return 0
		end
	end,
}
kenewzhangfei:addSkill(kenewpaoxiao)

kenewpaoxiaojl = sgs.CreateTargetModSkill {
	name = "kenewpaoxiaojl",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("kenewpaoxiao") and card:isKindOf("Slash") then
			return 1000
		else
			return 0
		end
	end,
}
if not sgs.Sanguosha:getSkill("kenewpaoxiaojl") then skills:append(kenewpaoxiaojl) end



kenewsunshangxiang = sgs.General(extension, "kenewsunshangxiang", "wu", 3, false)

kerongchangjl = sgs.CreateTargetModSkill {
	name = "#kerongchangjl",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("kerongchang") and (card:getSkillName() == "kerongchang") then
			return 1000
		else
			return 0
		end
	end
}
if not sgs.Sanguosha:getSkill("kerongchangjl") then skills:append(kerongchangjl) end

kerongchangVS = sgs.CreateZeroCardViewAsSkill {
	name = "kerongchang",
	response_pattern = "@@kerongchang",
	view_as = function()
		local sha = sgs.Sanguosha:cloneCard("Slash", sgs.Card_NoSuit, 0)
		sha:setSkillName("kerongchang")
		return sha
	end,
	enabled_at_play = function()
		return false
	end,
}
--不计入次数在kexianglongcs那里

kerongchang = sgs.CreateTriggerSkill {
	name = "kerongchang",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = kerongchangVS,
	events = { sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.to and (move.to:objectName() == player:objectName()) and (move.to_place == sgs.Player_PlaceEquip)) then
				room:broadcastSkillInvoke(self:objectName())
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("Weapon") then
						room:askForUseCard(player, "@@kerongchang", "kerongchang-ask")
					end
					if sgs.Sanguosha:getCard(id):isKindOf("Armor") then
						player:gainHujia()
					end
					if sgs.Sanguosha:getCard(id):isKindOf("Treasure") then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
					end
					if sgs.Sanguosha:getCard(id):isKindOf("OffensiveHorse") or sgs.Sanguosha:getCard(id):isKindOf("DefensiveHorse") then
						local players = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if player:canDiscard(p, "he") then
								players:append(p)
							end
						end
						local eny = room:askForPlayerChosen(player, players, self:objectName(), "kerongchangh-ask", true,
							true)
						if eny then
							if not room:askForDiscard(eny, self:objectName(), 1, 1, false, true, "@kerongchang-discard") then
								local cards = eny:getCards("he")
								local c = cards:at(math.random(0, cards:length() - 1))
								room:throwCard(c, eny)
							end
						end
					end
				end
			end
			if (move.from and (move.from:objectName() == player:objectName())
					and (move.from_places:contains(sgs.Player_PlaceEquip))) then
				room:sendCompulsoryTriggerLog(player, "kerongchang")
				if player:getPhase() ~= sgs.Player_Play then
					room:broadcastSkillInvoke(self:objectName())
				end
				player:drawCards(1)
			end
		end
	end,
}
kenewsunshangxiang:addSkill(kerongchang)

kexiaoji = sgs.CreateTriggerSkill {
	name = "kexiaoji",
	events = { sgs.EventPhaseEnd },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if (player:getPhase() ~= sgs.Player_Play) then return false end
			local lb = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "kexiaoji-ask",
				true, true)
			if lb then
				room:broadcastSkillInvoke(self:objectName())
				local dest = sgs.QVariant()
				dest:setValue(lb)
				local result = room:askForChoice(player, self:objectName(), "huixue+shouhui", dest)
				if result == "huixue" then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(lb, recover)
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if not p:isNude() then
							players:append(p)
						end
					end
					local eny = room:askForPlayerChosen(player, players, "kexiaojiobtain", "kexiaojidmdzj-ask", false,
						false)
					if eny then
						local to_all = sgs.IntList()
						for _, c in sgs.qlist(eny:getCards("he")) do
							if (c:isKindOf("EquipCard")) then
								to_all:append(c:getId())
							end
						end
						if not to_all:isEmpty() then
							local rr = math.random(0, to_all:length() - 1)
							player:obtainCard(sgs.Sanguosha:getCard(to_all:at(rr)))
						end
					end
				end
				if result == "shouhui" then
					--lb:addToPile("kexiaoji", lb:getEquipsId())
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if not p:isNude() then
							players:append(p)
						end
					end
					local eny = room:askForPlayerChosen(player, players, "kexiaojiobtain", "kexiaojidmdfj-ask", false,
						false)
					if eny then
						local to_all = sgs.IntList()
						for _, c in sgs.qlist(eny:getCards("he")) do
							if (c:isKindOf("EquipCard")) then
								to_all:append(c:getId())
							end
						end
						if not to_all:isEmpty() then
							local rr = math.random(0, to_all:length() - 1)
							lb:obtainCard(sgs.Sanguosha:getCard(to_all:at(rr)))
						end
					end
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player, recover)
				end
			end
		end
	end,
}
kenewsunshangxiang:addSkill(kexiaoji)



kenewcaoying = sgs.General(extension, "kenewcaoying", "wei", 3, false)

ketwopaomu = sgs.CreateTriggerSkill {
	name = "ketwopaomu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged, sgs.BuryVictim },
	on_trigger = function(self, event, player, data)
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			local room = player:getRoom()
			local cys = room:findPlayersBySkillName(self:objectName())
			if not cys:isEmpty() then
				for _, cy in sgs.qlist(cys) do
					if (not cy:isNude()) and damage.from and (damage.from ~= cy) and (damage.from ~= damage.to) and (cy:getMark("&usepaomu_lun") == 0) and (damage.to:isAlive() or damage.from:isAlive()) then
						if (damage.to:objectName() ~= cy:objectName()) then
							if room:askForDiscard(cy, "ketwopaomu", 1, 1, true, true, "ketwopaomuliangren:" .. damage.from:objectName() .. ":" .. damage.to:objectName()) then
								local log = sgs.LogMessage()
								log.type = "$usekepaomu"
								log.from = cy
								room:sendLog(log)
								room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
								room:getThread():delay(200)
								room:setPlayerMark(cy, "&usepaomu_lun", 1)
								if damage.from:isAlive() then
									room:doAnimate(1, cy:objectName(), damage.from:objectName())
									room:getThread():delay(300)
									room:setEmotion(damage.from, "Arcane/jinxmark")
									room:broadcastSkillInvoke(self:objectName(), 3)
									room:damage(sgs.DamageStruct(self:objectName(), cy, damage.from, 1,
										sgs.DamageStruct_Fire))
								end
								if damage.to:isAlive() and not (damage.to == cy) then
									room:doAnimate(1, cy:objectName(), damage.to:objectName())
									room:getThread():delay(300)
									room:setEmotion(damage.to, "Arcane/jinxmark")
									room:broadcastSkillInvoke(self:objectName(), 3)
									room:damage(sgs.DamageStruct(self:objectName(), cy, damage.to, 1,
										sgs.DamageStruct_Fire))
								end
							end
						else
							if room:askForDiscard(cy, "ketwopaomu", 1, 1, true, true, "ketwopaomuyiren:" .. damage.from:objectName() .. ":" .. damage.to:objectName()) then
								local log = sgs.LogMessage()
								log.type = "$usekepaomu"
								log.from = cy
								room:sendLog(log)
								room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
								room:getThread():delay(200)
								room:setPlayerMark(cy, "&usepaomu_lun", 1)
								if damage.from:isAlive() then
									room:doAnimate(1, cy:objectName(), damage.from:objectName())
									room:getThread():delay(300)
									room:setEmotion(damage.from, "Arcane/jinxmark")
									room:broadcastSkillInvoke(self:objectName(), 3)
									room:damage(sgs.DamageStruct(self:objectName(), cy, damage.from, 1,
										sgs.DamageStruct_Fire))
								end
								if damage.to:isAlive() and not (damage.to == cy) then
									room:doAnimate(1, cy:objectName(), damage.to:objectName())
									room:getThread():delay(300)
									room:setEmotion(damage.to, "Arcane/jinxmark")
									room:broadcastSkillInvoke(self:objectName(), 3)
									room:damage(sgs.DamageStruct(self:objectName(), cy, damage.to, 1,
										sgs.DamageStruct_Fire))
								end
							end
						end
					end
				end
			end
		end
		if (event == sgs.BuryVictim) then
			local room = player:getRoom()
			local death = data:toDeath()
			local damage = death.damage
			if damage then
				local killer = damage.from
				if killer then
					if killer:isAlive() and killer:hasSkill(self:objectName()) then
						room:broadcastSkillInvoke(self:objectName(), 4)
						killer:drawCards(3)
						room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
						player:bury()
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return true
	end
}
kenewcaoying:addSkill(ketwopaomu)


kequshangCard = sgs.CreateSkillCard {
	name = "kequshangCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return ((#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName()))
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:showAllCards(target, player)
		local num = 0
		--local rec = 0
		local tri = 0
		for _, c in sgs.qlist(target:getCards("h")) do
			if c:isDamageCard() then
				--rec = rec + 1
				tri = 1
			end
		end
		room:setPlayerMark(target, "&kequshang", 1)
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if (p:getKingdom() == target:getKingdom()) and (p ~= player) then
				num = num + 1
				--room:setPlayerMark(p,"&kequshang",1)
			end
		end
		room:setPlayerMark(target, "&kequshang", num)
		room:ignoreCards(player, player:drawCardsList(num))
	end
}
--主技能
kequshangVS = sgs.CreateViewAsSkill {
	name = "kequshang",
	n = 0,
	view_as = function(self, cards)
		return kequshangCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kequshangCard"))
	end,
}


kequshang = sgs.CreateTriggerSkill {
	name = "kequshang",
	view_as_skill = kequshangVS,
	events = { sgs.EventPhaseChanging, sgs.Death, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.to and (move.to:objectName() == player:objectName())
				and player:hasSkill(self:objectName())
				and (move.to_place == sgs.Player_PlaceHand) and (player:getPhase() ~= sgs.Player_Draw) then
				room:ignoreCards(player, move.card_ids)
				for _,id in sgs.qlist(move.card_ids) do
					
						room:setCardTip(id, "kequshang")
				end
			end
		end
		if (event == sgs.EventPhaseChanging) and (player:hasSkill(self:objectName())) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_Start) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("&kequshang") > 0 then
						room:setPlayerMark(p, "&kequshang", 0)
					end
				end
			end
		end
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:hasSkill(self:objectName()) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&kequshang") > 0 then
						room:setPlayerMark(p, "&kequshang", 0)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
kenewcaoying:addSkill(kequshang)

kequshangKeep = sgs.CreateMaxCardsSkill {
	name = "kequshangKeep",
	frequency = sgs.Skill_Frequent,
	extra_func = function(self, target)
		if (target:getMark("&kequshang") > 0) then
			return -1
		else
			return 0
		end
	end
}
if not sgs.Sanguosha:getSkill("kequshangKeep") then skills:append(kequshangKeep) end

kenewfengming = sgs.CreateTriggerSkill {
	name = "kenewfengming",
	events = { sgs.CardResponded, sgs.CardUsed },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.whocard then
				player:drawCards(1)
				if use.whocard:isVirtualCard() and not use.who:isNude() then
					if player:askForSkillInvoke(self, ToData("kenewfengming-ask:" .. use.who:objectName())) then
						room:broadcastSkillInvoke("ketwopaomu", math.random(1, 2))
						local card_id = room:askForCardChosen(player, use.who, "he", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason,
							room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					end
				end
			end
		end
		if (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			local restocard = response.m_toCard
			if restocard then
				local resto = room:getCardUser(response.m_toCard)
				player:drawCards(1)
				if resto and restocard:isVirtualCard() and not resto:isNude() then
					if player:askForSkillInvoke(self, ToData("kenewfengming-ask:" .. resto:objectName())) then
						room:broadcastSkillInvoke("ketwopaomu", math.random(1, 2))
						local card_id = room:askForCardChosen(player, resto, "he", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason,
							room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					end
				end
			end
		end
	end,
}
kenewcaoying:addSkill(kenewfengming)




kenewxushu = sgs.General(extension, "kenewxushu", "shu", 4)

kexiajue = sgs.CreateTriggerSkill {
	name = "kexiajue",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if (player:getPhase() == sgs.Player_Play) and player:hasSkill(self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				local eny = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
					"kexiajue-ask", false, true)
				if eny then
					room:setEmotion(player, "Duel")
					room:setEmotion(eny, "Duel")
					room:getThread():delay(500)
					--if player:getHujia() == 0 then
					--player:gainHujia(1)
					--end
					for i = 0, 2, 1 do
						if not (eny:isAlive() and player:isAlive()) then
							break
						end
						if eny:isAlive() and player:isAlive() then
							local judge = sgs.JudgeStruct()
							judge.pattern = ".|red"
							judge.good = true
							judge.play_animation = true
							judge.who = player
							judge.reason = self:objectName()
							room:judge(judge)
							local suit = judge.card:getSuit()
							if judge.card:isBlack() then
								player:obtainCard(judge.card)
								--player:drawCards(1)
								local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								slash:setSkillName("xiajueskill")
								local card_use = sgs.CardUseStruct()
								card_use.from = eny
								card_use.to:append(player)
								card_use.card = slash
								room:useCard(card_use, false)
								slash:deleteLater()
							end
							if judge.card:isRed() then
								room:broadcastSkillInvoke(self:objectName())
								local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								slash:setSkillName("xiajueskill")
								local card_use = sgs.CardUseStruct()
								card_use.from = player
								card_use.to:append(eny)
								card_use.card = slash
								room:useCard(card_use, false)
								slash:deleteLater()
							end
						end
					end
				end
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:getSkillName() == "xiajueskill" then
				room:setCardFlag(use.card, "SlashIgnoreArmor")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
kenewxushu:addSkill(kexiajue)

kepingpiao = sgs.CreateTriggerSkill {
	name = "kepingpiao",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Wake,
	waked_skills = "kedianzhen",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox("kenewxushu", "kepingpiao")
		room:addPlayerMark(player, "kepingpiao")
		if room:changeMaxHpForAwakenSkill(player, -1) then
			--if player:isWounded() and room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
			local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = 1
			room:recover(player, recover)
			room:drawCards(player, 2)
			room:handleAcquireDetachSkills(player, "kedianzhen")
			room:detachSkillFromPlayer(player, "kexiajue", true)
			room:handleAcquireDetachSkills(player, "kexiajuetwo")
		end
	end,
	can_wake = function(self, event, player, data, room)
		if player:getMark(self:objectName()) > 0 then return false end
		if player:getPhase() == sgs.Player_Finish or (player:getPhase() == sgs.Player_Start) then
			if player:canWake(self:objectName()) then return true end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getHp() > p:getHp() then
					return false
				end
			end
			return true
		end
		return false
	end,
}
kenewxushu:addSkill(kepingpiao)

kexiajuetwoCard = sgs.CreateSkillCard {
	name = "kexiajuetwoCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return #targets < 1
			and (to_select:objectName() ~= sgs.Self:objectName())
			and (sgs.Self:canSlash(to_select, nil, false)) and (to_select:canSlash(sgs.Self, nil, false))
	end,
	on_use = function(self, room, player, targets)
		room:broadcastSkillInvoke("kexiajue")
		local eny = targets[1]
		room:setEmotion(player, "Duel")
		room:setEmotion(eny, "Duel")
		room:getThread():delay(500)
		--if player:getHujia() == 0 then
		player:gainHujia(1)
		--end
		for i = 0, 2, 1 do
			if not (eny:isAlive() and player:isAlive()) then
				break
			end
			if eny:isAlive() and player:isAlive() then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = true
				judge.play_animation = true
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				local suit = judge.card:getSuit()
				if judge.card:isBlack() then
					player:obtainCard(judge.card)
					--player:drawCards(1)
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("xiajueskill")
					local card_use = sgs.CardUseStruct()
					card_use.from = eny
					card_use.to:append(player)
					card_use.card = slash
					room:useCard(card_use, false)
					slash:deleteLater()
				end
				if judge.card:isRed() then
					room:broadcastSkillInvoke("kexiajue")
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("xiajueskill")
					local card_use = sgs.CardUseStruct()
					card_use.from = player
					card_use.to:append(eny)
					card_use.card = slash
					room:useCard(card_use, false)
					slash:deleteLater()
				end
			end
		end
	end
}


kexiajuetwo = sgs.CreateViewAsSkill {
	name = "kexiajuetwo",
	n = 0,
	view_as = function(self, cards)
		return kexiajuetwoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kexiajuetwoCard"))
	end,
}
if not sgs.Sanguosha:getSkill("kexiajuetwo") then skills:append(kexiajuetwo) end


kedianzhen = sgs.CreateTriggerSkill {
	name = "kedianzhen",
	frequency = sgs.Skill_Frequent,
	events = { sgs.TargetSpecified, sgs.EventPhaseStart },
	priority = -1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		
		if (event == sgs.EventPhaseStart) and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				for _,m in ipairs(p:getMarkNames()) do
					if (string.find(m,"&kedianzhen")) and (p:getMark(m) > 0) then
						room:setPlayerMark(p, m, 0)
						local suit = m:split("+")[3]:split("_")[1]
						local pattern = ".|"..suit.."|.|hand"
						room:removePlayerCardLimitation(p, "use,response", pattern)
					end
				end
			end
		end
		if (event == sgs.EventPhaseStart) and player:hasSkill(self:objectName()) then
			if (player:getPhase() == sgs.Player_Start) then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if not p:isNude() then
						players:append(p)
					end
				end
				if not players:isEmpty() then
					local eny = room:askForPlayerChosen(player, players, self:objectName(), "kedianzhen-ask", true, true)
					if eny then
						room:broadcastSkillInvoke(self:objectName())
						local to_throw = room:askForCardChosen(player, eny, "he", self:objectName())
						local card = sgs.Sanguosha:getCard(to_throw)
						room:throwCard(card, eny, player)
						room:setPlayerMark(eny, "&kedianzhen+:+"..card:getSuitString().."_char", 1)
						local pattern = ".|"..card:getSuitString().."|.|hand"
						room:setPlayerCardLimitation(eny, "use,response", pattern, false)
					end
				end
			end
		end
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			local logplayers = sgs.SPlayerList()
			local no_respond_list = use.no_respond_list
			for _, p in sgs.qlist(use.to) do
				if (p:getMark("&kedianzhen+:+"..use.card:getSuitString().."_char") > 0) then
					table.insert(no_respond_list, p:objectName())
					logplayers:append(p)
					room:broadcastSkillInvoke(self:objectName())
				end
			end
			local log = sgs.LogMessage()
			log.type = "$kexushumsg"
			for _, p in sgs.qlist(logplayers) do
				log.to:append(p)
			end
			if not log.to:isEmpty() then
				room:sendLog(log)
				room:getThread():delay(500)
			end
			use.no_respond_list = no_respond_list
			data:setValue(use)
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
if not sgs.Sanguosha:getSkill("kedianzhen") then skills:append(kedianzhen) end
--kenewxushu:addSkill(kedianzhen)



kenewdaqiao = sgs.General(extension, "kenewdaqiao", "wu", 3, false)


keliuli = sgs.CreateTriggerSkill {
	name = "keliuli",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.RoundStart, sgs.TargetConfirmed, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				room:setPlayerMark(player, "&liulispsx", 0)
			end
		end
		if (event == sgs.TargetConfirmed) then
			local use = data:toCardUse()
			if use.to:contains(player) and use.card:isDamageCard() then
				if player:hasSkill(self:objectName()) and (use.from:getHp() >= player:getHp()) and player:canDiscard(use.from, "he") then
					--and ( (not (use.from:isAdjacentTo(player)))
					--or ((use.from:getGender() == sgs.General_Male)) and (use.from:getHp() >= player:getHp()) ) then
					if room:askForSkillInvoke(player, "keliuliqp", data) then
						room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
						if player:canDiscard(use.from, "he") then
							local to_throw = room:askForCardChosen(player, use.from, "he", "keliuli-choice")
							local card = sgs.Sanguosha:getCard(to_throw)
							room:throwCard(card, use.from, player)
						end
					end
				end
			end
		end
		if event == sgs.RoundStart then
			local others = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				others:append(p)
			end
			local num = others:length()
			local ran = math.random(1, num)
			room:doAnimate(1, player:objectName(), others:at(ran - 1):objectName())
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			local log = sgs.LogMessage()
			log.type = "$keliulilog"
			log.from = player
			log.to:append(others:at(ran - 1))
			room:sendLog(log)
			room:getThread():delay(1000)
			room:setEmotion(player, "Arcane/vismoke")
			room:setEmotion(others:at(ran - 1), "Arcane/vismoke")
			room:swapSeat(player, others:at(ran - 1))

			--判断座次距离
			local dqnum = 1
			local othernum = 1
			local dqyes = 0
			local otheryes = 0
			--当前角色为theplayer
			local theplayer = player
			while (dqyes == 0)
			do
				if (theplayer:getNextAlive() == others:at(ran - 1)) then
					dqyes = 1
				else
					dqnum = dqnum + 1
					theplayer = theplayer:getNextAlive()
				end
			end
			local theplayertwo = others:at(ran - 1)
			while (otheryes == 0)
			do
				if (theplayertwo:getNextAlive() == player) then
					otheryes = 1
				else
					othernum = othernum + 1
					theplayertwo = theplayertwo:getNextAlive()
				end
			end
			local numm = math.min(dqnum, othernum)
			room:addPlayerMark(player, "&liulispsx", numm)
			player:drawCards(numm)
			room:addMaxCards(player, numm, true)
		end
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}
kenewdaqiao:addSkill(keliuli)


keguoseCard = sgs.CreateSkillCard {
	name = "keguoseCard",
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return ((#targets < 1) and (self:subcardsLength() == 1) and (sgs.Self:getMark("useliulilbss-Clear") == 0) and (to_select:objectName() ~= sgs.Self:objectName())
				and not ((to_select:containsTrick("Indulgence"))))
			or
			((#targets < 1) and (self:subcardsLength() == 0) and (sgs.Self:getMark("useliuliqzpdq-Clear") == 0) and (to_select:objectName() ~= sgs.Self:objectName()))
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if (self:subcardsLength() == 0) then
			room:broadcastSkillInvoke("keguose")
			room:setPlayerMark(source, "useliuliqzpdq-Clear", 1)
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, c in sgs.qlist(target:getCards("j")) do
				dummy:addSubcard(c:getId())
				--room:throwCard(c, target,source)
			end
			room:throwCard(dummy, nil, source)
			dummy:deleteLater()
			target:drawCards(1)
		end
		if (self:subcardsLength() == 1) then
			room:setPlayerMark(source, "useliulilbss-Clear", 1)
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			local indulgence = sgs.Sanguosha:cloneCard("indulgence", card:getSuit(), card:getNumber())
			indulgence:setSkillName("keguose") --防止乱播报语音
			indulgence:addSubcard(card)
			if not source:isProhibited(target, indulgence) then
				room:useCard(sgs.CardUseStruct(indulgence, source, target))
				room:addMaxCards(target, -1, true)
			else
				indulgence:deleteLater()
			end
		end
	end,
}

keguose = sgs.CreateViewAsSkill {
	name = "keguose",
	n = 1,
	view_filter = function(self, selected, to_select)
		return (to_select:getSuit() == sgs.Card_Diamond)
		--return to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return keguoseCard:clone()
		elseif #cards == 1 then
			local card = keguoseCard:clone()
			card:addSubcard(cards[1])
			return card
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		return not ((player:getMark("useliulilbss-Clear") > 0) and (player:getMark("useliuliqzpdq-Clear") > 0))
	end,
}
kenewdaqiao:addSkill(keguose)

kenewguohuai = sgs.General(extension, "kenewguohuai", "wei", 3) --, true, false, false, 2)

keqinji = sgs.CreateTriggerSkill {
	name = "keqinji",
	events = { sgs.DamageInflicted, sgs.Damage, sgs.EventPhaseChanging },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if player:hasSkill(self:objectName()) then
				room:broadcastSkillInvoke("kekaojun")
				player:drawCards(1)
				player:gainMark("@keqinji")
				return true
			end
		end
		if event == sgs.Damage then
			local damage = data:toDamage()
			if player:hasSkill(self:objectName()) then
				player:loseMark("@keqinji")
			end
		end
		if (event == sgs.EventPhaseChanging) and (player:getMark("@keqinji") > 0) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				local lose = player:getMark("@keqinji")
				room:broadcastSkillInvoke(self:objectName())
				player:loseAllMarks("@keqinji")
				room:loseHp(player, lose)
			end
		end
	end,
}
kenewguohuai:addSkill(keqinji)

kekaojun = sgs.CreateTriggerSkill {
	name = "kekaojun",
	events = { sgs.CardResponded, sgs.CardsMoveOneTime, sgs.RoundStart, sgs.RoundEnd, sgs.Damage, sgs.TargetSpecified, sgs.CardFinished, sgs.Damaged, sgs.CardUsed, sgs.MarkChanged },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			if response.m_isUse then
				if response.m_card:isKindOf("BasicCard") then
					room:setPlayerMark(player, "kaojunb", 1)
				end
				if response.m_card:isKindOf("TrickCard") then
					room:setPlayerMark(player, "kaojunt", 1)
				end
			end
		end
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from and (move.from:objectName() == player:objectName()) and (player:getPhase() ~= sgs.Player_Discard) and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				room:setPlayerMark(player, "kekaojuntwo", 1)
			end
		end
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.from:hasSkill(self:objectName()) then
				if use.card:isKindOf("BasicCard") then
					room:setPlayerMark(use.from, "kaojunb", 1)
				end
				if use.card:isKindOf("EquipCard") then
					room:setPlayerMark(use.from, "kaojune", 1)
				end
				if use.card:isKindOf("TrickCard") then
					room:setPlayerMark(use.from, "kaojunt", 1)
				end
			end
		end
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if use.card:isDamageCard() then
				room:setCardFlag(use.card, "kaojuncard")
				for _, p in sgs.qlist(use.to) do
					room:setPlayerMark(p, "kaojuntarget", 1)
				end
			end
		end
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("kaojuncard") then
				room:setPlayerMark(damage.to, "kaojunbehit", 1)
			end
		end
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:hasFlag("kaojuncard") then
				for _, p in sgs.qlist(use.to) do
					if (p:getMark("kaojuntarget") > 0) and (p:getMark("kaojunbehit") == 0) then
						room:setPlayerMark(p, "kekaojunthree", 1)
					end
				end
				for _, pp in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerMark(pp, "kaojuntarget", 0)
					room:setPlayerMark(pp, "kaojunbehit", 0)
				end
			end
		end
		if (event == sgs.RoundEnd) then
			local room = player:getRoom()
			local ghs = room:findPlayersBySkillName(self:objectName())
			for _, gh in sgs.qlist(ghs) do
				if (gh:getMark("canuseyuzhang") > 0) then
					room:setPlayerMark(gh, "canuseyuzhang", 0)
					local players = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if (p:getMark("kekaojunthree") > 0) or (p:getMark("kekaojuntwo") > 0) or (p:isWounded()) then
							if p:isWounded() then
								room:setPlayerMark(p, "&kekaojunmp",
									p:getMark("kekaojunthree") + p:getMark("kekaojuntwo") + 1)
							else
								room:setPlayerMark(p, "&kekaojunmp", p:getMark("kekaojunthree") +
									p:getMark("kekaojuntwo"))
							end
							players:append(p)
						end
					end
					local num = (gh:getMark("kaojunb") + gh:getMark("kaojune") + gh:getMark("kaojunt"))
					local fris = room:askForPlayersChosen(gh, players, self:objectName(), 0, num, "kekaojun-ask",
						false, true)
					if not fris:isEmpty() then
						local log = sgs.LogMessage()
						log.type = "$usekekaojun"
						log.from = gh
						room:sendLog(log)
						room:broadcastSkillInvoke(self:objectName())
						room:sortByActionOrder(fris)
						for _, pp in sgs.qlist(fris) do
							pp:drawCards(pp:getMark("&kekaojunmp"))
						end
					end
					for _, q in sgs.qlist(room:getAllPlayers()) do
						room:setPlayerMark(q, "&kekaojunmp", 0)
					end
				end
			end
		end
		if (event == sgs.RoundStart) then
			local room = player:getRoom()
			local ghs = room:findPlayersBySkillName(self:objectName())
			for _, gh in sgs.qlist(ghs) do
				room:setPlayerMark(gh, "canuseyuzhang", 1)
			end
			for _, q in sgs.qlist(room:getAllPlayers()) do
				room:setPlayerMark(q, "kekaojunthree", 0)
				room:setPlayerMark(q, "kaojunb", 0)
				room:setPlayerMark(q, "kaojune", 0)
				room:setPlayerMark(q, "kaojunt", 0)
				room:setPlayerMark(q, "kekaojuntwo", 0)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kenewguohuai:addSkill(kekaojun)

kenewwangji = sgs.General(extension, "kenewwangji", "wei", 3, true)

kenewqizhi = sgs.CreateTriggerSkill {
	name = "kenewqizhi",
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if (use.card:isKindOf("TrickCard") or use.card:isKindOf("BasicCard")) and not use.card:isKindOf("SkillCard") then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if not use.to:contains(p) then
					targets:append(p)
				end
			end
			--普通版
			if (player:getMark("@keqizhi") > 0) then
				local target = room:askForPlayerChosen(player, room:getAllPlayers(), self:objectName(), "qizhi-invoke",
					true, true)
				if target then
					room:addPlayerMark(player, "&keqizhiallnum-Clear")
					room:broadcastSkillInvoke(self:objectName())
					if player:canDiscard(target, "hej") then
						local id = room:askForCardChosen(player, target, "hej", "qizhitishi", false,
							sgs.Card_MethodDiscard, sgs.IntList(), true)
						if id < 0 then
							room:broadcastSkillInvoke(self:objectName())
							room:damage(sgs.DamageStruct(self:objectName(), player, target))
							if target:isAlive() then
								room:recover(target, sgs.RecoverStruct())
							end
						else
							room:throwCard(id, target, player)
							if (player:getMark("@keqizhi") == 0) then
								target:drawCards(1, self:objectName())
							end
							if (target:objectName() ~= player:objectName()) and player:hasSkill("kenewjinqu") and (player:getMark("@keqizhi") > 0) and player:askForSkillInvoke(self:objectName(), sgs.QVariant("nomopaiother:"..target:objectName())) then
								target:drawCards(1, self:objectName())
							end
							if (target:objectName() == player:objectName()) and player:hasSkill("kenewjinqu") and (player:getMark("@keqizhi") > 0) and player:askForSkillInvoke(self:objectName(), sgs.QVariant("nomopaiself:"..target:objectName())) then
								target:drawCards(1, self:objectName())
							end
						end
					else
						room:damage(sgs.DamageStruct(self:objectName(), player, target))
						if target:isAlive() then
							room:recover(target, sgs.RecoverStruct())
						end
					end
					local translate = sgs.Sanguosha:translate(":kenewqizhiback")
					room:changeTranslation(player, "kenewqizhi", translate)
					room:setPlayerMark(player, "@keqizhi", 0)
					if player:hasSkill("kenewjinqu") then
						if (player:getMark("kenewqizhi") < 3) then
							room:addPlayerMark(player, "kenewqizhi")
						end
						if (player:getMark("kenewqizhi") == 2) then
							room:broadcastSkillInvoke("kenewjinqu", 13)
							--player:drawCards(1)
							room:setPlayerMark(player, "@keqizhi", 1)
							local translate = sgs.Sanguosha:translate(":kenewqizhiqh")
							room:changeTranslation(player, "kenewqizhi", translate)
						end
						if (player:getMark("kenewqizhi") >= 3) then
							room:setPlayerMark(player, "kenewqizhi", 0)
						end
					end
				end
			else
				--强化版
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "qizhi-invoke", true, true)
				if target then
					room:addPlayerMark(player, "&keqizhiallnum-Clear")
					room:broadcastSkillInvoke(self:objectName())
					if player:canDiscard(target, "hej") then
						local id = room:askForCardChosen(player, target, "hej", "qizhitishi", false,
							sgs.Card_MethodDiscard, sgs.IntList(), true)
						if id < 0 then
							room:broadcastSkillInvoke(self:objectName())
							room:damage(sgs.DamageStruct(self:objectName(), player, target))
							if target:isAlive() then
								if (player:getMark("@keqizhi") == 0) then
									room:recover(target, sgs.RecoverStruct())
								end
							end
						else
							room:throwCard(id, target, player)
							if (player:getMark("@keqizhi") == 0) then
								target:drawCards(1, self:objectName())
							end
							if (target:objectName() ~= player:objectName()) and player:hasSkill("kenewjinqu") and (player:getMark("@keqizhi") > 0) and player:askForSkillInvoke(self:objectName(), sgs.QVariant("nomopaiother:"..target:objectName())) then
								target:drawCards(1, self:objectName())
							end
							if (target:objectName() == player:objectName()) and player:hasSkill("kenewjinqu") and (player:getMark("@keqizhi") > 0) and player:askForSkillInvoke(self:objectName(), sgs.QVariant("nomopaiself:"..target:objectName())) then
								target:drawCards(1, self:objectName())
							end
						end
					else
						room:damage(sgs.DamageStruct(self:objectName(), player, target))
						if target:isAlive() then
							if (player:getMark("@keqizhi") == 0) then
								room:recover(target, sgs.RecoverStruct())
							end
						end
					end
					local translate = sgs.Sanguosha:translate(":kenewqizhiback")
					room:changeTranslation(player, "kenewqizhi", translate)
					room:setPlayerMark(player, "@keqizhi", 0)
					if player:hasSkill("kenewjinqu") then
						if (player:getMark("kenewqizhi") < 3) then
							room:addPlayerMark(player, "kenewqizhi")
						end
						if (player:getMark("kenewqizhi") == 2) then
							room:broadcastSkillInvoke("kenewjinqu", 13)
							--player:drawCards(1)
							room:setPlayerMark(player, "@keqizhi", 1)
							local translate = sgs.Sanguosha:translate(":kenewqizhiqh")
							room:changeTranslation(player, "kenewqizhi", translate)
						end
						if (player:getMark("kenewqizhi") >= 3) then
							room:setPlayerMark(player, "kenewqizhi", 0)
						end
					end
				end
			end
		end
	end
}
kenewwangji:addSkill(kenewqizhi)


kenewjinqu = sgs.CreateTriggerSkill {
	name = "kenewjinqu",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if (player:getPhase() == sgs.Player_Finish) then
				if (math.min(player:getMark("&keqizhiallnum-Clear"), 2) > 0) then
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 12))
					player:drawCards(math.min(player:getMark("&keqizhiallnum-Clear"), 2))
				end
			end
		end
	end,
}
kenewwangji:addSkill(kenewjinqu)

kenewsunxiu = sgs.General(extension, "kenewsunxiu$", "wu", 3, true)

keyanzhuCard = sgs.CreateSkillCard {
	name = "keyanzhuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets < math.max(1, sgs.Self:getLostHp())) and
			(to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, player, targets)
		for _, p in ipairs(targets) do
			p:drawCards(1)
			if player:getMark("changekexingxue") == 0 then
				if player:canDiscard(p,"he") then
					local id = room:askForCardChosen(player, p, "he", "keyanzhutishi", false, sgs.Card_MethodNone,
						sgs.IntList(), true)
					if id < 0 then
						room:damage(sgs.DamageStruct("keyanzhu", player, p))
					else
						room:obtainCard(player, id)
					end
				end
			else
				if player:canDiscard(p,"he") then
					local card_id = room:askForCardChosen(player, p, "he", self:objectName())
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
					room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason,
						room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
				end
			end
		end
	end
}

keyanzhuVS = sgs.CreateZeroCardViewAsSkill {
	name = "keyanzhu",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#keyanzhuCard")
	end,
	view_as = function()
		return keyanzhuCard:clone()
	end
}

keyanzhu = sgs.CreateTriggerSkill {
	name = "keyanzhu",
	view_as_skill = keyanzhuVS,
	events = { sgs.EnterDying},
	can_trigger = function(self, player)
		return player
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EnterDying then
			local dying = data:toDying()
			local damage = dying.damage
			if damage and damage.from:isAlive() and (dying.damage:getReason() == "keyanzhu")
				and (damage.from:getMark("changekexingxue") == 0) then
				room:setPlayerMark(damage.from, "changekexingxue", 1)
				local translate = sgs.Sanguosha:translate(":kexingxuetwo")
				room:changeTranslation(damage.from, "kexingxue", translate)
				local translatetwo = sgs.Sanguosha:translate(":keyanzhutwo")
				room:changeTranslation(damage.from, "keyanzhu", translatetwo)
			end
		end
	end,
}
kenewsunxiu:addSkill(keyanzhu)


kezhaofuCard = sgs.CreateSkillCard {
	name = "kezhaofuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, player, targets)
		room:removePlayerMark(player, "@kezhaofu")
		room:doSuperLightbox("kenewsunxiu", "kezhaofu")
		local target = targets[1]
		room:setPlayerMark(player, "meusingzhaofu", 1)
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if (p:objectName() ~= target:objectName()) then
				players:append(p)
			end
		end
		for _, p in sgs.qlist(players) do
			room:askForUseSlashTo(p, target, "zhaofu-ask:" .. target:objectName(), false, false, false, nil, nil,
				"kezhaofucard")
		end
		room:setPlayerMark(player, "meusingzhaofu", 0)
	end
}

kezhaofuVS = sgs.CreateZeroCardViewAsSkill {
	name = "kezhaofu",
	enabled_at_play = function(self, player)
		return (player:getMark("@kezhaofu") > 0)
	end,
	view_as = function()
		return kezhaofuCard:clone()
	end
}
kezhaofu = sgs.CreateTriggerSkill {
	name = "kezhaofu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kezhaofu",
	view_as_skill = kezhaofuVS,
	events = { sgs.Damage },
	can_trigger = function(self, player)
		return player
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("kezhaofucard") then
				if not damage.to:isNude() then
					local card_id = room:askForCardChosen(damage.from, damage.to, "he", self:objectName())
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, damage.from:objectName())
					room:obtainCard(damage.from, sgs.Sanguosha:getCard(card_id), reason,
						room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
				end
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if (p:getMark("meusingzhaofu") == 1) then
						room:recover(p, sgs.RecoverStruct())
						break
					end
				end
			end
		end
	end,
}
kenewsunxiu:addSkill(kezhaofu)



kexingxue = sgs.CreatePhaseChangeSkill {
	name = "kexingxue",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self, player)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			local x = player:getMaxHp()
			if (player:getMark("changekexingxue") == 0) then
				x = player:getMaxHp()
			end
			--未修改之前
			local fris = room:askForPlayersChosen(player, room:getAllPlayers(), self:objectName(), 0, x,
					"kexingxue-ask", false, true)
			if not fris:isEmpty() then
				local log = sgs.LogMessage()
				log.type = "$usekexingxue"
				log.from = player
				log.to = fris
				room:sendLog(log)
				room:broadcastSkillInvoke(self:objectName())
				for _, fri in sgs.qlist(fris) do
					for _, c in sgs.qlist(fri:getCards("h")) do
						if (c:getSuit() == sgs.Card_Spade) then room:setPlayerMark(fri, "kexingxuespade", 1) end
						if (c:getSuit() == sgs.Card_Club) then room:setPlayerMark(fri, "kexingxueclub", 1) end
						if (c:getSuit() == sgs.Card_Heart) then room:setPlayerMark(fri, "kexingxueheart", 1) end
						if (c:getSuit() == sgs.Card_Diamond) then room:setPlayerMark(fri, "kexingxuediamond", 1) end
					end
					local num = 4 -
						(fri:getMark("kexingxuespade") + fri:getMark("kexingxueclub") + fri:getMark("kexingxueheart") + fri:getMark("kexingxuediamond"))
					if (num > 0) then
						fri:drawCards(math.max(1, num))
					end
					room:setPlayerMark(fri, "kexingxuespade", 0)
					room:setPlayerMark(fri, "kexingxueclub", 0)
					room:setPlayerMark(fri, "kexingxueheart", 0)
					room:setPlayerMark(fri, "kexingxuediamond", 0)
					if not room:askForDiscard(fri, self:objectName(), 1, 1, false, true, "kexingxue-discard") then
						local cards = fri:getCards("he")
						local c = cards:at(math.random(0, cards:length() - 1))
						room:throwCard(c, fri)
					end
				end
			end
			
		end
	end
}
kenewsunxiu:addSkill(kexingxue)

kenewzhonghui = sgs.General(extension, "kenewzhonghui", "wei", 4)
kenewzhonghuizg = sgs.General(extension, "kenewzhonghuizg", "wei", 4, true, true, true)
kenewzhonghuitj = sgs.General(extension, "kenewzhonghuitj", "wei", 4, true, true, true)



kenewzhonghuichange = sgs.CreateTriggerSkill {
	name = "#kenewzhonghuichange",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameReady },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:hasSkill(self:objectName())) then
			local result = room:askForChoice(player, "kenewzhonghuichange", "pynt+zgxp+tjbb")
			if result == "pynt" then
				room:setPlayerMark(player, "zhpynt", 1)
			end
			if result == "tjbb" then
				room:changeHero(player, "kenewzhonghuitj", false, true, player:getGeneral2Name()=="kenewzhonghui", false)
				room:setPlayerMark(player, "zhtjbb", 1)
			end
			if result == "zgxp" then
				room:changeHero(player, "kenewzhonghuizg", false, true, player:getGeneral2Name()=="kenewzhonghui", false)
				room:setPlayerMark(player, "zhzgxp", 1)
			end
		end
	end,
	priority = 5,
}
kenewzhonghui:addSkill(kenewzhonghuichange)

kezhenggong = sgs.CreateTriggerSkill {
	name = "kezhenggong",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage, sgs.EventPhaseChanging, sgs.DamageComplete, sgs.MarkChanged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.MarkChanged then
			local mark = data:toMark()
			if (mark.name == "&kegong") and (mark.gain > 0) and mark.who:hasSkill(self:objectName()) then
				if (mark.who:getMark("zhpynt") > 0) then
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				end
				if (mark.who:getMark("zhtjbb") > 0) then
					room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
				end
				if (mark.who:getMark("zhzgxp") > 0) then
					room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
				end
			end
		end

		if event == sgs.DamageComplete then
			local damage = data:toDamage()
			if damage.from:hasSkill(self:objectName()) then
				if (damage.from:getMark("&kegong") < 5) then
					damage.from:gainMark("&kegong")
				end
			end
		end
		if event == sgs.Damage then
			local damage = data:toDamage()
			for _, zh in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local mp = 0
				for _, p in sgs.qlist(room:getOtherPlayers(zh)) do
					if (p:getHandcardNum() >= zh:getHandcardNum()) then
						mp = 1
						break
					end
				end
				if (mp == 1) and (zh:getMark("&usekezhenggong") == 0) and (zh:distanceTo(damage.to) <= 1) then
					local _data = sgs.QVariant()
					_data:setValue(damage.from)
					if room:askForSkillInvoke(zh, self:objectName(), _data) then
						room:setPlayerMark(zh, "&usekezhenggong", 1)
						zh:drawCards(1)
						damage.from = zh
						data:setValue(damage)
						if (zh:getMark("&kegong") == 5) then
							if (zh:getMark("zhpynt") > 0) then
								room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
							end
							if (zh:getMark("zhtjbb") > 0) then
								room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
							end
							if (zh:getMark("zhzgxp") > 0) then
								room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
							end
						end
					end
				end
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local zhs = room:findPlayersBySkillName(self:objectName())
				for _, p in sgs.qlist(zhs) do
					if p:getMark("&usekezhenggong") > 0 then
						room:setPlayerMark(p, "&usekezhenggong", 0)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 9,
}
kenewzhonghui:addSkill(kezhenggong)
kenewzhonghuizg:addSkill("kezhenggong")
kenewzhonghuitj:addSkill("kezhenggong")


kezhenggongKeep = sgs.CreateMaxCardsSkill {
	name = "kezhenggongKeep",
	frequency = sgs.Skill_Frequent,
	extra_func = function(self, target)
		if (target:hasSkill("kezhenggong")) then
			return target:getMark("&kegong")
		else
			return 0
		end
	end
}
if not sgs.Sanguosha:getSkill("kezhenggongKeep") then skills:append(kezhenggongKeep) end

kezili = sgs.CreatePhaseChangeSkill {
	name = "kezili",
	frequency = sgs.Skill_Wake,
	waked_skills = "kesuni",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		room:notifySkillInvoked(player, self:objectName())
		if (player:getMark("zhpynt") > 0) then
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			room:doSuperLightbox("kenewzhonghui", "kezili")
		end
		if (player:getMark("zhtjbb") > 0) then
			room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
			room:doSuperLightbox("kenewzhonghuitj", "kezili")
		end
		if (player:getMark("zhzgxp") > 0) then
			room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
			room:doSuperLightbox("kenewzhonghuizg", "kezili")
		end
		room:setPlayerMark(player, self:objectName(), 1)
		if room:changeMaxHpForAwakenSkill(player) then
			if player:isWounded() and room:askForChoice(player, self:objectName(), "recover+draw") == "recover" then
				room:recover(player, sgs.RecoverStruct(player))
			else
				room:drawCards(player, 2)
			end
			if player:getMark(self:objectName()) == 1 then
				room:acquireSkill(player, "kesuni")
			end
		end
		return false
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:getMark("&kegong") >= 3 then
			return true
		end
		return false
	end,
}
kenewzhonghui:addSkill(kezili)
kenewzhonghuizg:addSkill("kezili")
kenewzhonghuitj:addSkill("kezili")



kesuniCard = sgs.CreateSkillCard {
	name = "kesuniCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return (#targets < 1) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, player, targets)
		if (player:getMark("zhpynt") > 0) then
			room:broadcastSkillInvoke("kesuni", math.random(1, 2))
		end
		if (player:getMark("zhtjbb") > 0) then
			room:broadcastSkillInvoke("kesuni", math.random(3, 4))
		end
		if (player:getMark("zhzgxp") > 0) then
			room:broadcastSkillInvoke("kesuni", math.random(5, 6))
		end
		local num = #targets
		--room:removePlayerMark(player,"&kegong",2)
		player:loseMark("&kegong", num)
		for _, p in ipairs(targets) do
			--ps为这个人的总牌数
			local ps = p:getCardCount()
			--没牌就给个标记，准备挨打
			if (ps == 0) then
				room:setPlayerMark(p, "willsunida", 1)
			end
			--随机一个弃置的具体牌数
			if (ps ~= 0) then
				--qz为随机弃置的牌的数量
				local qz = math.random(0, ps)
				if (qz ~= 0) then
					--用to_all先装下这个人的全部牌
					local to_all = sgs.IntList()
					local to_throw = sgs.IntList()
					for _, c in sgs.qlist(p:getCards("he")) do
						to_all:append(c:getEffectiveId())
					end
					--循环随机里面的一张牌装到to_throw里面，直到to_throw装满
					repeat
						keyi = 0
						local rr = math.random(0, to_all:length() - 1)
						if not to_throw:contains(to_all:at(rr)) then
							to_throw:append(to_all:at(rr))
						end
						if to_throw:length() == qz then
							keyi = 1
						end
					until (keyi == 1)
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _, id in sgs.qlist(to_throw) do
						dummy:addSubcard(id)
					end
					room:throwCard(dummy, reason, p)
					dummy:deleteLater()
				end
				--随机到0也准备挨打
				if (qz == 0) then
					room:setPlayerMark(p, "willsunida", 1)
				end
			end
		end
		for _, p in ipairs(targets) do
			if (p:getMark("willsunida") > 0) then
				room:loseHp(p, 1, true, player)
				room:setPlayerMark(p, "willsunida", 0)
			end
		end
	end
}
--主技能
kesuni = sgs.CreateViewAsSkill {
	name = "kesuni",
	n = 0,
	view_as = function(self, cards)
		return kesuniCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kesuniCard")) and (player:getMark("&kegong") >= 1)
	end,
}
if not sgs.Sanguosha:getSkill("kesuni") then skills:append(kesuni) end






kenewcaochong = sgs.General(extension, "kenewcaochong", "wei", 3)
kenewcaochongcc = sgs.General(extension, "kenewcaochongcc", "wei", 3, true, true, true)
kenewcaochongfh = sgs.General(extension, "kenewcaochongfh", "wei", 3, true, true, true)
kenewcaochongzn = sgs.General(extension, "kenewcaochongzn", "wei", 3, true, true, true)
kenewcaochongzy = sgs.General(extension, "kenewcaochongzy", "wei", 3, true, true, true)

kenewcaochongchange = sgs.CreateTriggerSkill {
	name = "#kenewcaochongchange",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameReady },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:hasSkill(self:objectName())) then
			local result = room:askForChoice(player, "kenewcaochongchange", "wlys+ccqy+fhyx+zncj+zyst")
			if result == "wlys" then
				room:setPlayerMark(player, "ccwlys", 1)
			end
			if result == "ccqy" then
				room:changeHero(player, "kenewcaochongcc", false, true, player:getGeneral2Name()=="kenewcaochong", false)
				room:setPlayerMark(player, "ccccqy", 1)
			end
			if result == "fhyx" then
				room:changeHero(player, "kenewcaochongfh", false, true, player:getGeneral2Name()=="kenewcaochong", false)
				room:setPlayerMark(player, "ccfhyx", 1)
			end
			if result == "zncj" then
				room:changeHero(player, "kenewcaochongzn", false, true, player:getGeneral2Name()=="kenewcaochong", false)
				room:setPlayerMark(player, "cczncj", 1)
			end
			if result == "zyst" then
				room:changeHero(player, "kenewcaochongzy", false, true, player:getGeneral2Name()=="kenewcaochong", false)
				room:setPlayerMark(player, "cczyst", 1)
			end
		end
	end,
	priority = 5,
}
kenewcaochong:addSkill(kenewcaochongchange)

kenewchengxiangCard = sgs.CreateSkillCard {
	name = "kenewchengxiangCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return #targets < 99
			and (to_select:objectName() ~= sgs.Self:objectName())
			and ((to_select:getHp() >= sgs.Self:getHp()) or (to_select:getHandcardNum() >= sgs.Self:getHandcardNum()))
			and not to_select:isKongcheng()
	end,
	on_use = function(self, room, player, targets)
		local fcard_ids = sgs.IntList()
		for _, p in ipairs(targets) do
			local card = p:getRandomHandCard()
			fcard_ids:append(card:getEffectiveId())
		end
		if fcard_ids:length() < 5 then
			local cha = (5 - fcard_ids:length())
			if (cha > 0) then
				local pdcard_ids = room:getNCards(cha)
				for _, id in sgs.qlist(pdcard_ids) do
					fcard_ids:append(id)
				end
			end
		end
		room:broadcastSkillInvoke("kenewchengxiang")

		--混合
		local card_ids = sgs.IntList()
		while true do
			if fcard_ids:isEmpty() then break end
			if not fcard_ids:isEmpty() then
				if (fcard_ids:length() == 1) then
					for _, c in sgs.qlist(fcard_ids) do
						card_ids:append(c)
						fcard_ids:removeOne(c)
					end
				end
				if (fcard_ids:length() > 1) then
					local rr = math.random(0, fcard_ids:length() - 1)
					card_ids:append(fcard_ids:at(rr))
					fcard_ids:removeOne(fcard_ids:at(rr))
				end
			end
		end

		room:fillAG(card_ids)
		local to_get = sgs.IntList()
		local to_throw = sgs.IntList()

		while true do
			local sum = 0
			for _, id in sgs.qlist(to_get) do
				sum = sum + sgs.Sanguosha:getCard(id):getNumber()
			end
			if sum > 12 then break end
			for _, id in sgs.qlist(card_ids) do
				if sum + sgs.Sanguosha:getCard(id):getNumber() > 13 then
					room:takeAG(nil, id, false)
					to_throw:append(id)
				end
			end
			for _, id in sgs.qlist(card_ids) do
				if to_throw:contains(id) then
					card_ids:removeOne(id)
				end
			end
			if to_throw:length() + to_get:length() == 5 then break end
			local card_id = room:askForAG(player, card_ids, true, self:objectName())
			if card_id == -1 then break end
			card_ids:removeOne(card_id)
			to_get:append(card_id)
			room:takeAG(player, card_id, false)
			if card_ids:isEmpty() then break end
		end
		if not to_get:isEmpty() then
			local dianshuhe = 0
			for _, id in sgs.qlist(to_get) do
				dianshuhe = dianshuhe + sgs.Sanguosha:getCard(id):getNumber()
				room:obtainCard(player, id)
			end
			if dianshuhe == 13 then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover)
			end
		end
		room:clearAG()
		return false
	end
}


kenewchengxiang = sgs.CreateViewAsSkill {
	name = "kenewchengxiang",
	n = 0,
	view_as = function(self, cards)
		return kenewchengxiangCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kenewchengxiangCard"))
	end,
}

kenewcaochong:addSkill(kenewchengxiang)
kenewcaochongcc:addSkill("kenewchengxiang")
kenewcaochongfh:addSkill("kenewchengxiang")
kenewcaochongzn:addSkill("kenewchengxiang")
kenewcaochongzy:addSkill("kenewchengxiang")

--[[kehuairen = sgs.CreateTriggerSkill{
	name = "kehuairen",
	events = {sgs.TargetConfirmed,sgs.CardFinished,sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	    if (event == sgs.TargetConfirmed) then
			local use = data:toCardUse()
			if use.to:contains(player) and not (use.card:isKindOf("SkillCard") ) then
				if player:hasSkill(self:objectName()) then
					room:addPlayerMark(player,"&kehuairen")
					if (player:getMark("&kehuairen") >= player:getHp())and (player:getMark("playhuairenyy") == 0) then
						room:setPlayerMark(player,"playhuairenyy",1)
						room:broadcastSkillInvoke("keceyin")
					end
				end
			end
			
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerMark(p,"&kehuairen",0)
					room:setPlayerMark(p,"playhuairenyy",0)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
kenewcaochong:addSkill(kehuairen)
kenewcaochongcc:addSkill("kehuairen")
kenewcaochongfh:addSkill("kehuairen")
kenewcaochongzn:addSkill("kehuairen")
kenewcaochongzy:addSkill("kehuairen")

kehuairenex = sgs.CreateProhibitSkill{
	name = "kehuairenex",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("kehuairen") and (to:getMark("&kehuairen") >= to:getHp()) and (from ~= to) and (not card:isKindOf("SkillCard"))
	end
}
if not sgs.Sanguosha:getSkill("kehuairenex") then skills:append(kehuairenex) end
]]

keceyinCard = sgs.CreateSkillCard {
	name = "keceyinCard",
	target_fixed = true,
	will_throw = true,
	mute = true,
	on_use = function(self, room, source, targets)
		--[[if (source:getMark("ccwlys") > 0) then
			room:broadcastSkillInvoke("keceyin",math.random(1,2))
		end
		if (source:getMark("ccccqy") > 0) then
			room:broadcastSkillInvoke("keceyin",math.random(3,4))
		end
		if (source:getMark("ccfhyx") > 0) then
			room:broadcastSkillInvoke("keceyin",math.random(5,6))
		end]]
		room:broadcastSkillInvoke("keceyin")
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if (p:getMark("theoneceyin") > 0) then
				room:setPlayerMark(source, "&usedceyin_lun", 1)
				room:setPlayerMark(p, "theoneceyin", 0)
				--room:setPlayerMark(p,"&usedceyin",1)
				if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("EquipCard") then
					--room:recover(p, sgs.RecoverStruct())
					source:drawCards(1)
					p:drawCards(1)
				end
				room:setPlayerMark(source, "usingceyin", 1)
			end
		end
	end
}

keceyinVS = sgs.CreateViewAsSkill {
	name = "keceyin",
	n = 1,
	response_pattern = "@@keceyin",
	view_filter = function(self, cards, to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = keceyinCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@keceyin"
	end
}



--[[keceyin = sgs.CreateTriggerSkill{
	name = "keceyin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EnterDying},
	view_as_skill = keceyinVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:getMark("&usedceyin") == 0) then
			local ccs = room:findPlayersBySkillName(self:objectName())
			for _, cc in sgs.qlist(ccs) do
				if (player:getMark("&usedceyin") == 0) then
					room:askForUseCard(cc, "@@keceyin", "keceyin-ask")
					
					if (cc:getMark("usingceyin") > 0) and room:getCurrentDyingPlayer() and (room:getCurrentDyingPlayer() == player) then
						room:setPlayerMark(cc,"usingceyin",0)
						room:setPlayerFlag(player,"-Global_Dying")
						return true
					end
					--[[if room:askForDiscard(cc, self:objectName(), 1, 1, true,true,"ceyin-ask") then
						room:setPlayerMark(player,"&usedceyin",1)
						player:drawCards(2)
						if room:getCurrentDyingPlayer() and (room:getCurrentDyingPlayer() == player) then
							room:setPlayerFlag(player,"-Global_Dying")
							return true
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}]]

keceyin = sgs.CreateTriggerSkill {
	name = "keceyin",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageInflicted },
	view_as_skill = keceyinVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if (player:getMark("&usedceyin") == 0) and (damage.damage >= player:getHp()) then
			local ccs = room:findPlayersBySkillName(self:objectName())
			for _, cc in sgs.qlist(ccs) do
				if (cc:getMark("&usedceyin_lun") == 0) then
					local to_data = sgs.QVariant()
					to_data:setValue(player)
					room:setTag("keceyin", data)
					local will_use = room:askForSkillInvoke(cc, self:objectName(), to_data)
					room:removeTag("keceyin")
					if will_use then
						room:setPlayerMark(player, "theoneceyin", 1)
						--if cc:getState() ~= "online" then
						local todis = room:askForExchange(cc, self:objectName(), 1, 1, true, "keceyin-ask")
						if todis then
							room:throwCard(sgs.Sanguosha:getCard(todis:getSubcards():first()), cc)
							room:broadcastSkillInvoke(self:objectName())
							for _, p in sgs.qlist(room:getAllPlayers()) do
								if (p:getMark("theoneceyin") > 0) then
									room:setPlayerMark(cc, "&usedceyin_lun", 1)
									room:setPlayerMark(p, "theoneceyin", 0)
									if sgs.Sanguosha:getCard(todis:getSubcards():first()):isKindOf("EquipCard") then
										cc:drawCards(1)
										p:drawCards(1)
									end
									room:setPlayerMark(cc, "usingceyin", 1)
								end
							end
						end
						--else
						--	room:askForUseCard(cc, "@@keceyin", "keceyin-ask")
						--end
						if (cc:getMark("usingceyin") > 0) then
							room:setPlayerMark(cc, "usingceyin", 0)
							damage.prevented = true
							data:setValue(damage)
							return true
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
kenewcaochong:addSkill(keceyin)
kenewcaochongcc:addSkill("keceyin")
kenewcaochongfh:addSkill("keceyin")
kenewcaochongzn:addSkill("keceyin")
kenewcaochongzy:addSkill("keceyin")




kenewcaorui = sgs.General(extension, "kenewcaorui$", "wei", 3)
kenewcaoruimjcg = sgs.General(extension, "kenewcaoruimjcg$", "wei", 3, true, true, true)

kenewcaoruichange = sgs.CreateTriggerSkill {
	name = "#kenewcaoruichange",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameReady },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:hasSkill(self:objectName())) then
			local result = room:askForChoice(player, "kenewcaoruichange", "yqmm+mjcg")
			if result == "yqmm" then
				room:setPlayerMark(player, "cryqmm", 1)
			end
			if result == "mjcg" then
				room:changeHero(player, "kenewcaoruimjcg", false, true, player:getGeneral2Name()=="kenewcaorui", false)
				room:setPlayerMark(player, "crmjcg", 1)
			end
		end
	end,
	priority = 5,
}
kenewcaorui:addSkill(kenewcaoruichange)


kehuituo = sgs.CreateTriggerSkill {
	name = "kehuituo",
	events = { sgs.Damaged },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local jay = damage.to
			local lucky = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "kehuituo-ask", true,
				true)
			if lucky then
				if (player:getMark("cryqmm") == 1) then
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				elseif (player:getMark("crmjcg") == 1) then
					room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
				end
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.play_animation = true
				judge.who = lucky
				judge.reason = self:objectName()
				room:judge(judge)
				if judge.card:isRed() then
					local recover = sgs.RecoverStruct()
					recover.who = lucky
					recover.recover = 1
					room:recover(lucky, recover)
				end
				if judge.card:isBlack() then
					lucky:drawCards(damage.damage)
				end
				if lucky:isWounded() then
					player:drawCards(1)
				end
			end
		end
	end,
}
kenewcaorui:addSkill(kehuituo)
kenewcaoruimjcg:addSkill("kehuituo")

kemingjianusevs = sgs.CreateZeroCardViewAsSkill {
	name = "kemingjianusevs",
	response_pattern = "@@kemingjianusevs",
	enabled_at_play = function(self, player)
		return false
	end,
	view_as = function()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if (pattern == "@@kemingjianusevs") then
			local id = sgs.Self:getMark("kemingjianusevs-PlayClear") - 1
			if id < 0 then return nil end
			local card = sgs.Sanguosha:getEngineCard(id)
			return card
		end
	end
}
if not sgs.Sanguosha:getSkill("kemingjianusevs") then skills:append(kemingjianusevs) end

kemingjianCard = sgs.CreateSkillCard {
	name = "kemingjianCard",
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, source, targets)
		if (source:getMark("cryqmm") == 1) then
			local yy = math.random(1, 2)
			if yy == 1 then
				room:broadcastSkillInvoke("kemingjian", math.random(1, 2))
			else
				room:broadcastSkillInvoke("kexingshuai", math.random(1, 2))
			end
		elseif (source:getMark("crmjcg") == 1) then
			room:broadcastSkillInvoke("kemingjian", math.random(3, 4))
		end
		local target = targets[1]
		target:obtainCard(self)
		source:drawCards(1)
		if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("BasicCard") then
			room:setPlayerMark(source, "mingjianjbp-Clear", 1)
		end
		if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("EquipCard") then
			room:setPlayerMark(source, "mingjianzbp-Clear", 1)
		end
		if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("TrickCard") then
			room:setPlayerMark(source, "mingjianjnp-Clear", 1)
		end
		room:setPlayerFlag(target, "themingjianto")
		room:setPlayerFlag(source, "themingjianfrom")
		--[[local pattern = {}
		for _,c in sgs.qlist(target:getCards("h")) do
			if (not target:isJilei(c)) and (c:isAvailable(target)) then
				table.insert(pattern,c:getEffectiveId())
			end
		end]]
		local id = self:getSubcards():first()
		room:setCardFlag(sgs.Sanguosha:getCard(id), "donottocaorui")
		room:addPlayerMark(target, "kemingjianusevs-PlayClear", id + 1)
		if target:getState() ~= "online" then
			if not room:askForUseCard(target, "@@kemingjianusevs", "zhuangzhiuse-ask", -1) then
				--if not room:askForUseCard(target, table.concat(pattern, ",") , "kemingjianuse-ask") then
				room:setPlayerMark(source, "mingjianxxx-Clear", 1)
				room:setPlayerMark(target, "kemingjianusevs-PlayClear", 0)
				local result = room:askForChoice(source, "kemingjianCard_choice", "huode+no")
				if result == "huode" then
					if not target:isNude() then
						local card_id = room:askForCardChosen(source, target, "he", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
						room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason,
							room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					end
				end
			end
		else
			if not room:askForUseCard(target, "" .. id, "zhuangzhiuse-ask") then
				room:setPlayerMark(source, "mingjianxxx-Clear", 1)
				local result = room:askForChoice(source, "kemingjianCard_choice", "huode+no")
				if result == "huode" then
					if not target:isNude() then
						local card_id = room:askForCardChosen(source, target, "he", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
						room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason,
							room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
					end
				end
			end
		end
		room:setPlayerMark(target, "kemingjianusevs-PlayClear", 0)
		room:setPlayerFlag(target, "-themingjianto")
		room:setPlayerFlag(source, "-themingjianfrom")
	end,
}

kemingjian = sgs.CreateViewAsSkill {
	name = "kemingjian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return ((sgs.Self:getMark("mingjianjbp-Clear") == 0) and (to_select:isKindOf("BasicCard")))
			or ((sgs.Self:getMark("mingjianzbp-Clear") == 0) and (to_select:isKindOf("EquipCard")))
			or ((sgs.Self:getMark("mingjianjnp-Clear") == 0) and (to_select:isKindOf("TrickCard")))
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local mingjiancard = kemingjianCard:clone()
		mingjiancard:addSubcard(cards[1])
		return mingjiancard
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("mingjianxxx-Clear") == 0)
			and
			(not ((player:getMark("mingjianjbp-Clear") > 0) and (player:getMark("mingjianzbp-Clear") > 0) and (player:getMark("mingjianjnp-Clear") > 0)))
	end
}
kenewcaorui:addSkill(kemingjian)
kenewcaoruimjcg:addSkill("kemingjian")

kemingjianpro = sgs.CreateProhibitSkill {
	name = "kemingjianpro",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("kemingjian") and (to:hasFlag("themingjianfrom")) and from:hasFlag("themingjianto")
	end
}
if not sgs.Sanguosha:getSkill("kemingjianpro") then skills:append(kemingjianpro) end


kexingshuai = sgs.CreateTriggerSkill {
	name = "kexingshuai",
	frequency = sgs.Skill_Limited,
	limit_mark = "@xingshuaiMark",
	events = { sgs.Dying, sgs.RoundStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Dying then
			local one = room:getCurrentDyingPlayer()
			if (one == player) and (player:getMark("@xingshuaiMark") > 0) then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					players:append(p)
					if p:isYourFriend(player) then
						room:setPlayerFlag(p, "helpcaorui")
					end
				end
				local anum = room:alivePlayerCount()
				if not players:isEmpty() then
					if room:askForSkillInvoke(player, self:objectName(), data) then
						if (player:getMark("cryqmm") == 1) then
							room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
							room:doSuperLightbox("kenewcaorui", "kexingshuai")
						elseif (player:getMark("crmjcg") == 1) then
							room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
							room:doSuperLightbox("kenewcaoruimjcg", "kexingshuai")
						end
						room:removePlayerMark(player, "@xingshuaiMark")
						for _, p in sgs.qlist(players) do
							if (p:getState() == "online") then
								local result = room:askForChoice(p, "xingshuai_choice", "huifu+no")
								if result == "huifu" then
									--weis:append(p)
									p:drawCards(1)
									local recover = sgs.RecoverStruct()
									recover.who = player
									room:recover(player, recover)
								end
							end
							if (p:getState() ~= "online") then --p:isYourFriend(player) or player:isYourFriend(p)
								if p:isYourFriend(player) or ((player:getRole() == "rebel") and (p:getRole() == "rebel")) or ((player:getRole() == "lord") and (p:getRole() == "loyalist")) or ((player:getRole() == "lord") and (p:getRole() == "renegade") and (anum ~= 2)) then
									--weis:append(p)
									p:drawCards(1)
									local recover = sgs.RecoverStruct()
									recover.who = player
									room:recover(player, recover)
								end
							end
						end
						--[[for _, p in sgs.qlist(weis) do
							room:damage(sgs.DamageStruct(self:objectName(), nil, p))
						end]]
					end
				end
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:setPlayerFlag(p, "-helpcaorui")
				end
			end
		end
	end,
}
kenewcaorui:addSkill(kexingshuai)
kenewcaoruimjcg:addSkill("kexingshuai")



kenewsunluyu = sgs.General(extension, "kenewsunluyu", "wu", 3, false)

keraoxi = sgs.CreateTriggerSkill {
	name = "keraoxi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			local room = player:getRoom()
			if (player:getPhase() == sgs.Player_RoundStart) then
				local sxhs = room:findPlayersBySkillName(self:objectName())
				for _, sxh in sgs.qlist(sxhs) do
					local _data = sgs.QVariant()
					_data:setValue(player)
					
					if (sxh:objectName() ~= player:objectName()) and player:inMyAttackRange(sxh)
						and (sxh:getMark("useraoxi_lun") == 0) and room:askForSkillInvoke(sxh, self:objectName(), _data) then
						if sxh:getMark("useraoxi_lun") > 0 and not (room:askForDiscard(sxh, self:objectName(), sxh:getMark("useraoxi_lun"), sxh:getMark("useraoxi_lun"), true, true, "raoxi-ask:" .. player:objectName() .. ":" .. sxh:getMark("useraoxi_lun"))) then
							continue
						end
						local result = room:askForChoice(sxh, self:objectName(), "skipmp+skipcp", _data)
						if result == "skipmp" then
							local log = sgs.LogMessage()
							log.type = "$raoximc"
							log.from = sxh
							log.to:append(player)
							room:sendLog(log)
							room:addPlayerMark(sxh, "useraoxi_lun", 1)
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerMark(player, "&raoximp-Clear", 1)
						end
						if result == "skipcp" then
							local log = sgs.LogMessage()
							log.type = "$raoxicq"
							log.from = sxh
							log.to:append(player)
							room:sendLog(log)
							room:addPlayerMark(sxh, "useraoxi_lun", 1)
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerMark(player, "&raoxicp-Clear", 1)
						end
					end
				end
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			--出牌摸牌交换
			if (player:getMark("&raoximp-Clear") > 0) then
				if change.to == sgs.Player_Draw then
					if not player:isSkipped(sgs.Player_Play) then
						change.to = sgs.Player_Play
						data:setValue(change)
					else
						player:skip(sgs.Player_Draw)
					end
				elseif change.to == sgs.Player_Play then
					if not player:isSkipped(sgs.Player_Draw) then
						change.to = sgs.Player_Draw
						data:setValue(change)
					else
						player:skip(sgs.Player_Play)
					end
				end
			end
			--出牌弃牌交换
			if (player:getMark("&raoxicp-Clear") > 0) then
				if change.to == sgs.Player_Play then
					if not player:isSkipped(sgs.Player_Discard) then
						change.to = sgs.Player_Discard
						data:setValue(change)
					else
						player:skip(sgs.Player_Play)
					end
				elseif change.to == sgs.Player_Discard then
					if not player:isSkipped(sgs.Player_Play) then
						change.to = sgs.Player_Play
						data:setValue(change)
					else
						player:skip(sgs.Player_Discard)
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end
}
kenewsunluyu:addSkill(keraoxi)

kemumuCard = sgs.CreateSkillCard {
	name = "kemumuCard",
	will_throw = false,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:getCardCount(true, true) ~= 0)
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local to_throw = room:askForCardChosen(source, target, "hej", "kemumu")
		local card = sgs.Sanguosha:getCard(to_throw)
		room:throwCard(card, target, source)
		local num = 0
		if not target:isKongcheng() then
			num = num + 1
		end
		if (target:getEquips():length() ~= 0) then
			num = num + 1
		end
		--[[if (target:getJudgingArea():length() ~= 0) then
			num = num + 1
		end]]
		source:drawCards(num)
	end,
}

kemumu = sgs.CreateViewAsSkill {
	name = "kemumu",
	n = 0,
	view_as = function(self, cards)
		return kemumuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kemumuCard")
	end,
}
kenewsunluyu:addSkill(kemumu)


kenewzhangxingcai = sgs.General(extension, "kenewzhangxingcai", "shu", 3, false)
kenewzhangxingcaiznzq = sgs.General(extension, "kenewzhangxingcaiznzq", "shu", 3, false, true, true)
kenewzhangxingcaifzyx = sgs.General(extension, "kenewzhangxingcaifzyx", "shu", 3, false, true, true)
kenewzhangxingcaijghw = sgs.General(extension, "kenewzhangxingcaijghw", "shu", 3, false, true, true)
kenewzhangxingcaijzyy = sgs.General(extension, "kenewzhangxingcaijzyy", "shu", 3, false, true, true)

kenewzhangxingcaichange = sgs.CreateTriggerSkill {
	name = "#kenewzhangxingcaichange",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameReady },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (player:hasSkill(self:objectName())) then
			local result = room:askForChoice(player, "kenewzhangxingcaichange", "xchf+znzq+fzyx+jghw+jzyy")
			if result == "xchf" then
				room:setPlayerMark(player, "zxcxchf", 1)
			end
			if result == "znzq" then
				room:changeHero(player, "kenewzhangxingcaiznzq", false, true, player:getGeneral2Name()=="kenewzhangxingcai", false)
				room:setPlayerMark(player, "zxcznzq", 1)
			end
			if result == "fzyx" then
				room:changeHero(player, "kenewzhangxingcaifzyx", false, true, player:getGeneral2Name()=="kenewzhangxingcai", false)
				room:setPlayerMark(player, "zxcfzyx", 1)
			end
			if result == "jghw" then
				room:changeHero(player, "kenewzhangxingcaijghw", false, true, player:getGeneral2Name()=="kenewzhangxingcai", false)
				room:setPlayerMark(player, "zxcjghw", 1)
			end
			if result == "jzyy" then
				room:changeHero(player, "kenewzhangxingcaijzyy", false, true, player:getGeneral2Name()=="kenewzhangxingcai", false)
				room:setPlayerMark(player, "zxcjzyy", 1)
			end
		end
	end,
	priority = 5,
}
kenewzhangxingcai:addSkill(kenewzhangxingcaichange)

kexianjie = sgs.CreateTriggerSkill {
	name = "kexianjie",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardFinished, sgs.Damage, sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:hasFlag("xianjiecard") then
				local zxcs = room:findPlayersBySkillName(self:objectName())
				for _, zxc in sgs.qlist(zxcs) do
					if (zxc:getMark("usedxianjie-Clear") < 1) and not use.from:hasFlag("beusedxianjie") then
						if zxc:askForSkillInvoke(self, ToData("kexianjie-ask:" .. use.from:objectName() .. ":" .. use.card:objectName())) then
							room:setPlayerMark(zxc, "usedxianjie-Clear", 1)
							if (zxc:getMark("zxcxchf") == 1) then
								room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
							elseif (zxc:getMark("zxcznzq") == 1) then
								room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
							elseif (zxc:getMark("zxcfzyx") == 1) then
								room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
							elseif (zxc:getMark("zxcjghw") == 1) then
								room:broadcastSkillInvoke(self:objectName(), math.random(7, 8))
							elseif (zxc:getMark("zxcjzyy") == 1) then
								room:broadcastSkillInvoke(self:objectName(), math.random(9, 10))
							end
							use.from:obtainCard(use.card)
							room:addSlashCishu(zxc, 1, true)
							room:addPlayerMark(zxc, "&kexianjiecs-SelfClear")
							room:setPlayerFlag(use.from, "beusedxianjie")
						end
					end
				end
				room:setPlayerFlag(use.from, "-beusedxianjie")
			end
		end
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("xianjiecard") then
				room:setCardFlag(damage.card, "-xianjiecard")
			end
		end
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") or (use.card:isNDTrick() and use.card:isDamageCard()) then
				room:setCardFlag(use.card, "xianjiecard")
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kenewzhangxingcai:addSkill(kexianjie)
kenewzhangxingcaiznzq:addSkill("kexianjie")
kenewzhangxingcaifzyx:addSkill("kexianjie")
kenewzhangxingcaijghw:addSkill("kexianjie")
kenewzhangxingcaijzyy:addSkill("kexianjie")

keqiangwuCard = sgs.CreateSkillCard {
	name = "keqiangwuCard",
	target_fixed = true,
	will_throw = false,
	mute = true,
	on_use = function(self, room, source, targets)
		--local target = targets[1]
		if (source:getMark("zxcxchf") == 1) then
			room:broadcastSkillInvoke("keqiangwu", math.random(1, 2))
		elseif (source:getMark("zxcznzq") == 1) then
			room:broadcastSkillInvoke("keqiangwu", math.random(3, 4))
		elseif (source:getMark("zxcfzyx") == 1) then
			room:broadcastSkillInvoke("keqiangwu", math.random(5, 6))
		elseif (source:getMark("zxcjghw") == 1) then
			room:broadcastSkillInvoke("keqiangwu", math.random(7, 8))
		elseif (source:getMark("zxcjzyy") == 1) then
			room:broadcastSkillInvoke("keqiangwu", math.random(9, 10))
		end
		--[[for _,c in sgs.qlist(source:getCards("h")) do
			if (c:getSuit() == sgs.Card_Spade) then
				room:setPlayerMark(source,"qiangwuspade",1)
			end
			if (c:getSuit() == sgs.Card_Club) then
				room:setPlayerMark(source,"qiangwuclub",1)
			end
			if (c:getSuit() == sgs.Card_Heart) then
				room:setPlayerMark(source,"qiangwuheart",1)
			end
			if (c:getSuit() == sgs.Card_Diamond) then
				room:setPlayerMark(source,"qiangwudiamond",1)
			end
		end
		local num = 4 - (source:getMark("qiangwuspade") + source:getMark("qiangwuclub") + source:getMark("qiangwuheart") + source:getMark("qiangwudiamond"))
		if (num > 0) then
			target:drawCards(num)
		end]]
		source:drawCards(1)
		room:setPlayerMark(source, "qiangwuspade", 0)
		room:setPlayerMark(source, "qiangwuheart", 0)
		room:setPlayerMark(source, "qiangwuclub", 0)
		room:setPlayerMark(source, "qiangwudiamond", 0)
		local judge = sgs.JudgeStruct()
		judge.who = source
		judge.reason = "keqiangwu"
		judge.play_animation = true
		room:judge(judge)
	end
}
keqiangwuVS = sgs.CreateZeroCardViewAsSkill {
	name = "keqiangwu",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#keqiangwuCard")
	end,
	view_as = function()
		return keqiangwuCard:clone()
	end
}

keqiangwu = sgs.CreateTriggerSkill {
	name = "keqiangwu",
	view_as_skill = keqiangwuVS,
	events = { sgs.FinishJudge, sgs.EventPhaseStart, sgs.CardUsed },
	--[[can_trigger = function(self, player)
		return player:hasSkill("keqiangwu")
	end,]]
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == "keqiangwu" then
				--提示标记
				room:setPlayerMark(player,
					"&keqiangwu+:+" ..
					judge.card:objectName() ..
					"+" .. judge.card:getSuitString() .. "_char+" .. judge.card:getNumberString() .. "+-PlayClear", 1)
				--点数
				room:setPlayerMark(player, "keqiangwu-PlayClear", judge.card:getEffectiveId())
				--类型
			end
		end
		--执行效果
		if (event == sgs.CardUsed) and (player:getMark("keqiangwu-PlayClear") > 0) then
			local judgecard = sgs.Sanguosha:getCard(player:getMark("keqiangwu-PlayClear"))
			if not judgecard then return end
			local use = data:toCardUse()
			--类型
			if use.card:getTypeId() == judgecard:getTypeId() and (player:getMark("keqiangwudraw-PlayClear") < 2) then
				if (player:getMark("zxcxchf") == 1) then
					room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
				elseif (player:getMark("zxcznzq") == 1) then
					room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
				elseif (player:getMark("zxcfzyx") == 1) then
					room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
				elseif (player:getMark("zxcjghw") == 1) then
					room:broadcastSkillInvoke(self:objectName(), math.random(7, 8))
				elseif (player:getMark("zxcjzyy") == 1) then
					room:broadcastSkillInvoke(self:objectName(), math.random(9, 10))
				end
				room:addPlayerMark(player, "keqiangwudraw-PlayClear")
				player:drawCards(1)
			end
			--花色
			if (use.card:getSuit() == judgecard:getSuit()) then
				room:setPlayerFlag(player, "keqiangwu_throw")
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
					"keqiangwuqphht-ask", true, true)
					room:setPlayerFlag(player, "-keqiangwu_throw")
				if target then
					local result = room:askForChoice(player, "qiangwusuitchoice", "spade+club+heart+diamond")
					if result == "spade" then room:setPlayerFlag(target, "qiangwuthrow_spade") end
					if result == "club" then room:setPlayerFlag(target, "qiangwuthrow_club") end
					if result == "heart" then room:setPlayerFlag(target, "qiangwuthrow_heart") end
					if result == "diamond" then room:setPlayerFlag(target, "qiangwuthrow_diamond") end
					if (player:getMark("zxcxchf") == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					elseif (player:getMark("zxcznzq") == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
					elseif (player:getMark("zxcfzyx") == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
					elseif (player:getMark("zxcjghw") == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(7, 8))
					elseif (player:getMark("zxcjzyy") == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(9, 10))
					end
					local to_throw = sgs.IntList()
					for _, c in sgs.qlist(target:getCards("he")) do
						if (c:getSuit() == sgs.Card_Spade) and target:hasFlag("qiangwuthrow_spade") then
							to_throw:append(
								c:getId())
						end
						if (c:getSuit() == sgs.Card_Club) and target:hasFlag("qiangwuthrow_club") then
							to_throw:append(c
								:getId())
						end
						if (c:getSuit() == sgs.Card_Heart) and target:hasFlag("qiangwuthrow_heart") then
							to_throw:append(
								c:getId())
						end
						if (c:getSuit() == sgs.Card_Diamond) and target:hasFlag("qiangwuthrow_diamond") then
							to_throw
								:append(c:getId())
						end
					end
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					if not to_throw:isEmpty() then
						for _, id in sgs.qlist(to_throw) do
							dummy:addSubcard(id)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, target:objectName(),
							self:objectName(), nil)
						room:throwCard(dummy, reason, target)
						dummy:deleteLater()
					end
					room:setPlayerFlag(target, "-qiangwuthrow_spade")
					room:setPlayerFlag(target, "-qiangwuthrow_club")
					room:setPlayerFlag(target, "-qiangwuthrow_heart")
					room:setPlayerFlag(target, "-qiangwuthrow_diamond")
				end
			end
			--点数
			if (use.card:getNumber() == judgecard:getNumber()) then
				local eny = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
					"keqiangwuda-ask", true, true)
				if eny then
					if (player:getMark("zxcxchf") == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
					elseif (player:getMark("zxcznzq") == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
					elseif (player:getMark("zxcfzyx") == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
					elseif (player:getMark("zxcjghw") == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(7, 8))
					elseif (player:getMark("zxcjzyy") == 1) then
						room:broadcastSkillInvoke(self:objectName(), math.random(9, 10))
					end
					room:damage(sgs.DamageStruct(self:objectName(), player, eny))
				end
			end
		end
		return false
	end,
}
kenewzhangxingcai:addSkill(keqiangwu)
kenewzhangxingcaiznzq:addSkill("keqiangwu")
kenewzhangxingcaifzyx:addSkill("keqiangwu")
kenewzhangxingcaijghw:addSkill("keqiangwu")
kenewzhangxingcaijzyy:addSkill("keqiangwu")


kenewshichangshi = sgs.General(extension, "kenewshichangshi", "qun", 1, true)

kenewqingfu = sgs.CreateTriggerSkill {
	name = "kenewqingfu",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = { sgs.AskForPeachesDone, sgs.EnterDying, sgs.EventPhaseChanging, sgs.MarkChanged, sgs.GameStart, sgs.GameOver },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.GameOver) then
			local winner = data:toString():split("+")
			for s, p in sgs.list(room:getAllPlayers()) do
				if (table.contains(winner, p:objectName())
						or table.contains(winner, p:getRole()))
					and (p:getMark("kenewshichangshibenti") > 0) then
					room:changeHero(p, "kenewshichangshi", true, false, false, false)
					room:broadcastSkillInvoke(self:objectName(), 3)
					--room:broadcastSkillInvoke(self:objectName(),3)
					--[[s = "audio/skill/kenewqingfu3.ogg"
					sgs.Sanguosha:playAudioEffect(s)
					if p:getGeneral2() then
						s = "audio/skill/kenewqingfu3.ogg"
						sgs.Sanguosha:playAudioEffect(s)
					end]]
				end
			end
		end
		if (event == sgs.GameStart) then
			if player:hasSkill(self:objectName()) then
				room:setPlayerMark(player, "kenewshichangshibenti", 1)
				local choices = {}
				if (player:getMark("kescsgs") == 0) then table.insert(choices, "kescsgs") end
				if (player:getMark("kescsxy") == 0) then table.insert(choices, "kescsxy") end
				if (player:getMark("kescsdg") == 0) then table.insert(choices, "kescsdg") end
				if (player:getMark("kescszz") == 0) then table.insert(choices, "kescszz") end
				if (player:getMark("kescsls") == 0) then table.insert(choices, "kescsls") end
				if (player:getMark("kescszr") == 0) then table.insert(choices, "kescszr") end
				if (player:getMark("kescssz") == 0) then table.insert(choices, "kescssz") end
				if (player:getMark("kescshl") == 0) then table.insert(choices, "kescshl") end
				if (player:getMark("kescsgw") == 0) then table.insert(choices, "kescsgw") end
				if (player:getMark("kescsbl") == 0) then table.insert(choices, "kescsbl") end
				--移除只剩四个
				while (#choices > 4) do
					table.removeOne(choices, choices[math.random(1, #choices)])
				end
				local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
				room:addPlayerMark(player, "kenewscscount")
				if choice == "kescsgs" then
					room:changeHero(player, "kenewguosheng", true, true, false, false)
					room:setPlayerMark(player, "kescsgs", 1)
				end
				if choice == "kescsxy" then
					room:changeHero(player, "kenewxiayun", true, true, false, false)
					room:setPlayerMark(player, "kescsxy", 1)
				end
				if choice == "kescsdg" then
					room:changeHero(player, "kenewduangui", true, true, false, false)
					room:setPlayerMark(player, "kescsdg", 1)
				end
				if choice == "kescszz" then
					room:changeHero(player, "kenewzhaozhong", true, true, false, false)
					room:setPlayerMark(player, "kescszz", 1)
				end
				if choice == "kescsls" then
					room:changeHero(player, "kenewlisong", true, true, false, false)
					room:setPlayerMark(player, "kescsls", 1)
				end
				if choice == "kescszr" then
					room:changeHero(player, "kenewzhangrang", true, true, false, false)
					room:setPlayerMark(player, "kescszr", 1)
					room:addPlayerMark(player, "kenewzhangrangshow")
				end
				if choice == "kescssz" then
					room:changeHero(player, "kenewsunzhang", true, true, false, false)
					room:setPlayerMark(player, "kescssz", 1)
				end
				if choice == "kescshl" then
					room:changeHero(player, "kenewhanli", true, true, false, false)
					room:setPlayerMark(player, "kescshl", 1)
				end
				if choice == "kescsgw" then
					room:changeHero(player, "kenewgaowang", true, true, false, false)
					room:setPlayerMark(player, "kescsgw", 1)
				end
				if choice == "kescsbl" then
					room:changeHero(player, "kenewbilan", true, true, false, false)
					room:setPlayerMark(player, "kescsbl", 1)
				end
			end
			if (player:getGeneralName() == "kenewhanli" or player:getGeneral2Name() == "kenewhanli") then
				room:broadcastSkillInvoke("kenewhuiji", 1)
				player:drawCards(2)
			end
		end

		if (event == sgs.MarkChanged) then
			local mark = data:toMark()
			if (mark.name == "kenewshichangshiTimeToChange")
				and (mark.who:objectName() == player:objectName()) and (mark.gain > 0) then
				--先检查是否还有阴可用，否则换人
				if (player:getGeneralName() == "kenewxiayun") or (player:getGeneral2Name() == "kenewxiayun") then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setEmotion(player, "Arcane/vismoke")
					player:drawCards(1)
					room:changeHero(player, "kenewxiayunex", true, true, false, false)
					room:getThread():delay(1000)
				elseif (player:getGeneralName() == "kenewguosheng") or (player:getGeneral2Name() == "kenewguosheng") then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setEmotion(player, "Arcane/vismoke")
					player:drawCards(1)
					room:changeHero(player, "kenewguoshengex", true, true, false, false)
					room:getThread():delay(1000)
				elseif (player:getGeneralName() == "kenewduangui") or (player:getGeneral2Name() == "kenewduangui") then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setEmotion(player, "Arcane/vismoke")
					player:drawCards(1)
					room:changeHero(player, "kenewduanguiex", true, true, false, false)
					room:getThread():delay(1000)
				elseif (player:getGeneralName() == "kenewzhaozhong") or (player:getGeneral2Name() == "kenewzhaozhong") then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setEmotion(player, "Arcane/vismoke")
					player:drawCards(1)
					room:changeHero(player, "kenewzhaozhongex", true, true, false, false)
					room:getThread():delay(1000)
				elseif (player:getGeneralName() == "kenewlisong") or (player:getGeneral2Name() == "kenewlisong") then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setEmotion(player, "Arcane/vismoke")
					player:drawCards(1)
					room:changeHero(player, "kenewlisongex", true, true, false, false)
					room:getThread():delay(1000)
				elseif (player:getGeneralName() == "kenewzhangrang") or (player:getGeneral2Name() == "kenewzhangrang") then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setEmotion(player, "Arcane/vismoke")
					player:drawCards(1)
					room:changeHero(player, "kenewzhangrangex", true, true, false, false)
					room:getThread():delay(1000)
				elseif (player:getGeneralName() == "kenewsunzhang") or (player:getGeneral2Name() == "kenewsunzhang") then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setEmotion(player, "Arcane/vismoke")
					player:drawCards(1)
					room:changeHero(player, "kenewsunzhangex", true, true, false, false)
					room:getThread():delay(1000)
				elseif (player:getGeneralName() == "kenewhanli") or (player:getGeneral2Name() == "kenewhanli") then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setEmotion(player, "Arcane/vismoke")
					player:drawCards(1)
					room:changeHero(player, "kenewhanliex", true, true, false, false)
					room:getThread():delay(1000)
				elseif (player:getGeneralName() == "kenewgaowang") or (player:getGeneral2Name() == "kenewgaowang") then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setEmotion(player, "Arcane/vismoke")
					player:drawCards(1)
					room:changeHero(player, "kenewgaowangex", true, true, false, false)
					room:getThread():delay(1000)
				elseif (player:getGeneralName() == "kenewbilan") or (player:getGeneral2Name() == "kenewbilan") then
					room:broadcastSkillInvoke(self:objectName(), 2)
					room:setEmotion(player, "Arcane/vismoke")
					player:drawCards(1)
					room:changeHero(player, "kenewbilanex", true, true, false, false)
					room:getThread():delay(1000)
				else
					local choices = {}
					if (player:getMark("kescsgs") == 0) then table.insert(choices, "kescsgs") end
					if (player:getMark("kescsxy") == 0) then table.insert(choices, "kescsxy") end
					if (player:getMark("kescsdg") == 0) then table.insert(choices, "kescsdg") end
					if (player:getMark("kescszz") == 0) then table.insert(choices, "kescszz") end
					if (player:getMark("kescsls") == 0) then table.insert(choices, "kescsls") end
					if (player:getMark("kescszr") == 0) then table.insert(choices, "kescszr") end
					if (player:getMark("kescssz") == 0) then table.insert(choices, "kescssz") end
					if (player:getMark("kescshl") == 0) then table.insert(choices, "kescshl") end
					if (player:getMark("kescsgw") == 0) then table.insert(choices, "kescsgw") end
					if (player:getMark("kescsbl") == 0) then table.insert(choices, "kescsbl") end
					while (#choices > 4) do
						table.removeOne(choices, choices[math.random(1, #choices)])
					end
					if #choices == 0 then
						room:changeHero(player, "kenewshichangshi", true, true, false, false)
						room:broadcastSkillInvoke(self:objectName(), 1)
						room:killPlayer(player)
					else
						if (player:getGeneralName() ~= "kenewhanli") and (player:getGeneral2Name() ~= "kenewhanli") and (player:getGeneralName() ~= "kenewhanliex") and (player:getGeneral2Name() ~= "kenewhanliex") then
							player:throwAllHandCardsAndEquips()
						else
							--if (player:getGeneralName() == "kenewhanli") or (player:getGeneral2Name() == "kenewhanli") then
							--	room:broadcastSkillInvoke("kenewhuiji",1)
							--elseif (player:getGeneralName() == "kenewhanliex") or (player:getGeneral2Name() == "kenewhanliex") then
							room:broadcastSkillInvoke("kenewhuiji", 2)
							--end
						end
						room:broadcastSkillInvoke(self:objectName(), 1)
						local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
						player:drawCards(2)
						room:addPlayerMark(player, "kenewscscount")
						if choice == "kescsbl" then
							room:changeHero(player, "kenewbilan", true, true, false, false)
							room:setPlayerMark(player, "kescsbl", 1)
						end
						if choice == "kescsgw" then
							room:changeHero(player, "kenewgaowang", true, true, false, false)
							room:setPlayerMark(player, "kescsgw", 1)
						end
						if choice == "kescshl" then
							room:changeHero(player, "kenewhanli", true, true, false, false)
							room:setPlayerMark(player, "kescshl", 1)
							room:broadcastSkillInvoke("kenewhuiji")
							player:drawCards(2)
						end
						if choice == "kescssz" then
							room:changeHero(player, "kenewsunzhang", true, true, false, false)
							room:setPlayerMark(player, "kescssz", 1)
						end
						if choice == "kescsgs" then
							room:changeHero(player, "kenewguosheng", true, true, false, false)
							room:setPlayerMark(player, "kescsgs", 1)
						end
						if choice == "kescsxy" then
							room:changeHero(player, "kenewxiayun", true, true, false, false)
							room:setPlayerMark(player, "kescsxy", 1)
						end
						if choice == "kescsdg" then
							room:changeHero(player, "kenewduangui", true, true, false, false)
							room:setPlayerMark(player, "kescsdg", 1)
						end
						if choice == "kescszz" then
							room:changeHero(player, "kenewzhaozhong", true, true, false, false)
							room:setPlayerMark(player, "kescszz", 1)
						end
						if choice == "kescsls" then
							room:changeHero(player, "kenewlisong", true, true, false, false)
							room:setPlayerMark(player, "kescsls", 1)
						end
						if choice == "kescszr" then
							room:changeHero(player, "kenewzhangrang", true, true, false, false)
							room:setPlayerMark(player, "kescszr", 1)
							room:addPlayerMark(player, "kenewzhangrangshow")
						end
						if not player:hasSkill("kenewsiji") then room:setPlayerMark(player, "@kenewhuiji", 0) end
					end
				end
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) and (player:getMark("kenewshichangshibenti") > 0)
				and ((player:getGeneralName() == "kenewxiayun" or player:getGeneral2Name() == "kenewxiayun" or player:getGeneralName() == "kenewxiayunex" or player:getGeneral2Name() == "kenewxiayunex")
					or (player:getGeneralName() == "kenewguosheng" or player:getGeneral2Name() == "kenewguosheng" or player:getGeneralName() == "kenewguoshengex" or player:getGeneral2Name() == "kenewguoshengex")
					or (player:getGeneralName() == "kenewduangui" or player:getGeneral2Name() == "kenewduangui" or player:getGeneralName() == "kenewduanguiex" or player:getGeneral2Name() == "kenewduanguiex")
					or (player:getGeneralName() == "kenewzhaozhong" or player:getGeneral2Name() == "kenewzhaozhong" or player:getGeneralName() == "kenewzhaozhongex" or player:getGeneral2Name() == "kenewzhaozhongex")
					or (player:getGeneralName() == "kenewlisong" or player:getGeneral2Name() == "kenewlisong" or player:getGeneralName() == "kenewlisongex" or player:getGeneral2Name() == "kenewlisongex")
					or (player:getGeneralName() == "kenewsunzhang" or player:getGeneral2Name() == "kenewsunzhang" or player:getGeneralName() == "kenewsunzhangex" or player:getGeneral2Name() == "kenewsunzhangex")
					or (player:getGeneralName() == "kenewzhangrang" or player:getGeneral2Name() == "kenewzhangrang" or player:getGeneralName() == "kenewzhangrangex" or player:getGeneral2Name() == "kenewzhangrangex")
					or (player:getGeneralName() == "kenewhanli" or player:getGeneral2Name() == "kenewhanli" or player:getGeneralName() == "kenewhanliex" or player:getGeneral2Name() == "kenewhanliex")
					or (player:getGeneralName() == "kenewgaowang" or player:getGeneral2Name() == "kenewgaowang" or player:getGeneralName() == "kenewgaowangex" or player:getGeneral2Name() == "kenewgaowangex")
					or (player:getGeneralName() == "kenewbilan" or player:getGeneral2Name() == "kenewbilan" or player:getGeneralName() == "kenewbilanex" or player:getGeneral2Name() == "kenewbilanex")
				)
			then
				room:loseHp(player, player:getHp())
			end
		end
		--阴间状态直接切换，不能被救活
		if (event == sgs.EnterDying) then
			local dying_data = data:toDying()
			local source = dying_data.who
			if (source:objectName() == player:objectName()) and (player:getMark("kenewshichangshibenti") > 0) then
				--[[and ( (player:getGeneralName() == "kenewxiayunex") or (player:getGeneral2Name() == "kenewxiayunex")
			or (player:getGeneralName() == "kenewguoshengex") or (player:getGeneral2Name() == "kenewguoshengex")
			or (player:getGeneralName() == "kenewduanguiex") or (player:getGeneral2Name() == "kenewduanguiex")
			or (player:getGeneralName() == "kenewzhaozhongex") or (player:getGeneral2Name() == "kenewzhaozhongex")
			or (player:getGeneralName() == "kenewlisongex") or (player:getGeneral2Name() == "kenewlisongex"))then]]
				room:addPlayerMark(player, "kenewshichangshiTimeToChange", 1)
				if player:getHp() > 0 then
					room:setPlayerFlag(player, "-Global_Dying")
					local currentdying = room:getTag("CurrentDying"):toStringList()
					table.removeOne(currentdying,player:objectName())
					room:setTag("CurrentDying", sgs.QVariant(table.concat(currentdying, "|")))
				end
			end
		end
		--[[阳间状态可以先救
		if (event == sgs.AskForPeachesDone) then
			local dying_data = data:toDying()
			local source = dying_data.who
			if (source:objectName() == player:objectName()) and (player:getMark("kenewshichangshibenti")>0)
			and ((room:getCurrentDyingPlayer() ~= nil) and (room:getCurrentDyingPlayer():objectName() == player:objectName()))
			and ( (player:getGeneralName() == "kenewxiayun") or (player:getGeneral2Name() == "kenewxiayun")
			or (player:getGeneralName() == "kenewguosheng") or (player:getGeneral2Name() == "kenewguosheng")
			or (player:getGeneralName() == "kenewduangui") or (player:getGeneral2Name() == "kenewduangui")
			or (player:getGeneralName() == "kenewzhaozhong") or (player:getGeneral2Name() == "kenewzhaozhong")
			or (player:getGeneralName() == "kenewlisong") or (player:getGeneral2Name() == "kenewlisong"))then
				room:addPlayerMark(player,"kenewshichangshiTimeToChange",1)
			end
		end]]
	end,
}
kenewshichangshi:addSkill(kenewqingfu)

kenewzhangrang = sgs.General(extension, "kenewzhangrang", "qun", 1, true, true)
kenewzhangrangex = sgs.General(extension, "kenewzhangrangex", "qun", 1, true, true, true)

kenewwangmiuCard = sgs.CreateSkillCard {
	name = "kenewwangmiuCard",
	will_throw = false,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:showCard(source, self:getSubcards())
		target:obtainCard(self)
		local precard = sgs.Sanguosha:getCard(self:getSubcards():first())
		if source:canUse(precard, room:getAllPlayers()) then
			local viewcard = sgs.Sanguosha:cloneCard(precard:objectName(), precard:getSuit(), precard:getNumber())
			viewcard:setSkillName("kenewwangmiuCard")
			local card_use = sgs.CardUseStruct()
			card_use.from = source
			local choosenum = keutf8len(sgs.Sanguosha:translate(precard:objectName()))
			room:setPlayerMark(source, "kenewwangmiu", precard:getEffectiveId())
			card_use.to = room:askForPlayersChosen(source, room:getAllPlayers(), "kenewwangmiu", 0, choosenum,
					"kenewwangmiu-ask:" .. precard:objectName(), false, true)
			room:setPlayerMark(source, "kenewwangmiu", 0)
			card_use.card = viewcard
			room:useCard(card_use, false)
			viewcard:deleteLater()
		end
	end,
}

kenewwangmiu = sgs.CreateViewAsSkill {
	name = "kenewwangmiu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("BasicCard") or to_select:isNDTrick()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = kenewwangmiuCard:clone()
			card:addSubcard(cards[1])
			return card
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kenewwangmiuCard")
	end,
}

kenewzhangrang:addSkill(kenewwangmiu)
kenewzhangrangex:addSkill("kenewwangmiu")

kenewzhaozhong = sgs.General(extension, "kenewzhaozhong", "qun", 1, true, true)
kenewzhaozhongex = sgs.General(extension, "kenewzhaozhongex", "qun", 1, true, true, true)

kenewshiren = sgs.CreateTriggerSkill {
	name = "kenewshiren",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging, sgs.CardUsed, sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if (damage.from:objectName() == player:objectName()) and (player:getPhase() ~= sgs.Player_NotActive) then
				--room:setPlayerFlag(player,"kenewshirenflag")
				room:setPlayerMark(player, "kenewshiren-Clear", 1)
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) and (player:getMark("kenewshiren-Clear") == 0) then
				local zzs = room:findPlayersBySkillName(self:objectName())
				for _, zz in sgs.qlist(zzs) do
					if (zz:objectName() ~= player:objectName()) then
						local _data = sgs.QVariant()
						_data:setValue(player)
						if room:askForSkillInvoke(zz, self:objectName(), _data) then
							if (zz:getGeneralName() == "kenewzhaozhong" or zz:getGeneral2Name() == "kenewzhaozhong") then
								room:broadcastSkillInvoke(self:objectName(), 1)
							elseif (zz:getGeneralName() == "kenewzhaozhongex" or zz:getGeneral2Name() == "kenewzhaozhongex") then
								room:broadcastSkillInvoke(self:objectName(), 2)
							end
							local judge = sgs.JudgeStruct()
							judge.pattern = "."
							judge.good = true
							judge.play_animation = true
							judge.reason = self:objectName()
							judge.who = zz
							room:judge(judge)
							if judge.card:isRed() then
								if not player:isNude() then
									local card_id = room:askForCardChosen(zz, player, "he", self:objectName())
									local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,
										zz:objectName())
									room:obtainCard(zz, sgs.Sanguosha:getCard(card_id), reason,
										room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
								end
							elseif judge.card:isBlack() then
								room:damage(sgs.DamageStruct(self:objectName(), zz, player))
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kenewzhaozhong:addSkill(kenewshiren)
kenewzhaozhongex:addSkill("kenewshiren")

kenewsunzhang = sgs.General(extension, "kenewsunzhang", "qun", 1, true, true)
kenewsunzhangex = sgs.General(extension, "kenewsunzhangex", "qun", 1, true, true, true)

kenewqieshuiCard = sgs.CreateSkillCard {
	name = "kenewqieshuiCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getMark("sunzhanglunci")
			and (to_select:objectName() ~= sgs.Self:objectName())
			--and ((to_select:getHp() >= sgs.Self:getHp()) or (to_select:getHandcardNum() >= sgs.Self:getHandcardNum()))
			and not to_select:isNude()
	end,
	on_use = function(self, room, player, targets)
		if (player:getGeneralName() == "kenewsunzhang" or player:getGeneral2Name() == "kenewsunzhang") then
			room:broadcastSkillInvoke("kenewqieshui", 1)
		elseif (player:getGeneralName() == "kenewsunzhangex" or player:getGeneral2Name() == "kenewsunzhangex") then
			room:broadcastSkillInvoke("kenewqieshui", 2)
		end
		local dis_ids = sgs.IntList()
		for _, p in ipairs(targets) do
			local todis = room:askForExchange(p, self:objectName(), 1, 1, true, "kenewqieshui-show", false)
			if todis then
				room:showCard(p, todis:getSubcards():first())
				dis_ids:append(todis:getSubcards():first())
			end
		end
		if dis_ids:isEmpty() then return false end
		room:fillAG(dis_ids)
		local to_throw = sgs.IntList()
		local card_id = room:askForAG(player, dis_ids, true, self:objectName())
		if card_id ~= -1 then
			dis_ids:removeOne(card_id)
			room:takeAG(player, card_id, false)
			player:obtainCard(sgs.Sanguosha:getCard(card_id))
			room:clearAG()
			for _, id in sgs.qlist(dis_ids) do
				to_throw:append(id)
			end
			local move = sgs.CardsMoveStruct(to_throw, player, sgs.Player_PlaceHand,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), ""))
			room:moveCardsAtomic(move, false)
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
				dummy:deleteLater()
			end
		else
			for _, id in sgs.qlist(dis_ids) do
				to_throw:append(id)
			end
			local move = sgs.CardsMoveStruct(to_throw, player, sgs.Player_PlaceHand,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), ""))
			room:moveCardsAtomic(move, false)
			if not to_throw:isEmpty() then
				while room:askForYiji(player, to_throw, "kenewqieshui", true, true, true, -1, room:getOtherPlayers(player), sgs.CardMoveReason(), "kenewqieshui-distribute", true) do
					if not player:isAlive() then return end
				end
			end
			if not to_throw:isEmpty() then
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				for _, id in sgs.qlist(to_throw) do
					dummy:addSubcard(id)
				end
				room:throwCard(dummy, reason, nil)
				dummy:deleteLater()
			end
			room:clearAG()
		end
	end
}

kenewqieshuiVS = sgs.CreateViewAsSkill {
	name = "kenewqieshui",
	n = 0,
	view_as = function(self, cards)
		return kenewqieshuiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kenewqieshuiCard"))
	end,
}

kenewqieshui = sgs.CreateTriggerSkill {
	name = "kenewqieshui",
	view_as_skill = kenewqieshuiVS,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			room:setPlayerMark(player, "sunzhanglunci", room:getTag("TurnLengthCount"):toInt())
		end
	end,
}
kenewsunzhang:addSkill(kenewqieshui)
kenewsunzhangex:addSkill("kenewqieshui")

kenewbilan = sgs.General(extension, "kenewbilan", "qun", 1, true, true)
kenewbilanex = sgs.General(extension, "kenewbilanex", "qun", 1, true, true, true)

kenewrongyuan = sgs.CreateTriggerSkill {
	name = "kenewrongyuan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.MarkChanged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Start) then
			local deadnum = player:getMark("kenewscscount")
			local alivenum = 10 - deadnum
			local result = room:askForChoice(player, self:objectName(), "dis+mopai+cancel")
			if result == "mopai" then
				room:setPlayerFlag(player, "kenewrongyuan_draw")
				local fris = room:askForPlayersChosen(player, room:getAllPlayers(), self:objectName(), 0, alivenum,
						"kenewrongyuanmp-ask", true, true)
				room:setPlayerFlag(player, "-kenewrongyuan_draw")
				if fris:length() > 0 then
					if (player:getGeneralName() == "kenewbilan" or player:getGeneral2Name() == "kenewbilan") then
						room:broadcastSkillInvoke(self:objectName(), 1)
					elseif (player:getGeneralName() == "kenewbilanex" or player:getGeneral2Name() == "kenewbilanex") then
						room:broadcastSkillInvoke(self:objectName(), 2)
					end
				end
				for _, fri in sgs.qlist(fris) do
					fri:drawCards(1)
				end
			end
			if result == "dis" then
				local enys = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 0, deadnum,
						"kenewrongyuandis-ask", true, true)
				if enys:length() > 0 then
					if (player:getGeneralName() == "kenewbilan" or player:getGeneral2Name() == "kenewbilan") then
						room:broadcastSkillInvoke(self:objectName(), 1)
					elseif (player:getGeneralName() == "kenewbilanex" or player:getGeneral2Name() == "kenewbilanex") then
						room:broadcastSkillInvoke(self:objectName(), 2)
					end
				end
				for _, p in sgs.qlist(enys) do
					if not room:askForDiscard(p, self:objectName(), 1, 1, false, true, "@kerongchang-discard") then
						local cards = p:getCards("he")
						local c = cards:at(math.random(0, cards:length() - 1))
						room:throwCard(c, p)
					end
				end
			end
		end
	end,
}
kenewbilan:addSkill(kenewrongyuan)
kenewbilanex:addSkill("kenewrongyuan")

kenewxiayun = sgs.General(extension, "kenewxiayun", "qun", 1, true, true)
kenewxiayunex = sgs.General(extension, "kenewxiayunex", "qun", 1, true, true, true)

kenewbiting = sgs.CreateTriggerSkill {
	name = "kenewbiting",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if (player:getPhase() == sgs.Player_Draw) then
				local xys = room:findPlayersBySkillName(self:objectName())
				for _, xy in sgs.qlist(xys) do
					if (xy:getMark("kebitingtime_lun") < 2) and (xy:objectName() ~= player:objectName()) then
						if room:askForSkillInvoke(xy, self:objectName(), data) then
							if (xy:getGeneralName() == "kenewxiayun" or xy:getGeneral2Name() == "kenewxiayun") then
								room:broadcastSkillInvoke(self:objectName(), 1)
							elseif (xy:getGeneralName() == "kenewxiayunex" or xy:getGeneral2Name() == "kenewxiayunex") then
								room:broadcastSkillInvoke(self:objectName(), 2)
							end
							room:addPlayerMark(xy, "kebitingtime_lun", 1)
							xy:drawCards(2)
							local card = room:askForExchange(xy, self:objectName(), 99, math.min(1, xy:getCardCount()),
								true, "kenewbitingask:" .. player:getGeneralName())
							if card then
								room:obtainCard(player, card,
									sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
										xy:objectName(), self:objectName(), ""), false)
							end
							return true
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kenewxiayun:addSkill(kenewbiting)
kenewxiayunex:addSkill("kenewbiting")

kenewhanli = sgs.General(extension, "kenewhanli", "qun", 2, true, true)
kenewhanliex = sgs.General(extension, "kenewhanliex", "qun", 2, true, true, true)

kenewhuiji = sgs.CreateTriggerSkill {
	name = "kenewhuiji",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function(self, event, player, data)

	end,
}
kenewhanli:addSkill(kenewhuiji)
kenewhanliex:addSkill("kenewhuiji")

kenewlisong = sgs.General(extension, "kenewlisong", "qun", 1, true, true)
kenewlisongex = sgs.General(extension, "kenewlisongex", "qun", 1, true, true, true)

kenewmieyao = sgs.CreateTriggerSkill {
	name = "kenewmieyao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetSpecifying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetSpecifying) then
			local use = data:toCardUse()
			--if (use.to:length() ~= 1) or use.to:contains(use.from) then return false end
			local yes = 1
			local zzs = room:findPlayersBySkillName(self:objectName())
			room:setTag("kenewmieyao", data)
			for _, zz in sgs.qlist(zzs) do
				
				if (zz:objectName() ~= use.from:objectName()) and (yes == 1) and (use.card:isRed() and (use.card:isKindOf("BasicCard") or use.card:isNDTrick())) and (zz:getMark("usemieyao-Clear") == 0)
					and zz:askForSkillInvoke(self, ToData("kenewmieyao-ask:" .. use.from:objectName() .. ":" .. use.to:at(0):objectName() .. ":" .. use.card:objectName())) then
					yes = 0
					room:setPlayerMark(zz, "usemieyao-Clear", 1)
					if (zz:getGeneralName() == "kenewlisong" or zz:getGeneral2Name() == "kenewlisong") then
						room:broadcastSkillInvoke(self:objectName(), 1)
					elseif (zz:getGeneralName() == "kenewlisongex" or zz:getGeneral2Name() == "kenewlisongex") then
						room:broadcastSkillInvoke(self:objectName(), 2)
					end
					local num = math.random(1, 3)
					if (num == 1) then
						local numtwo = math.random(1, 4)
						if (numtwo == 1) then
							local log = sgs.LogMessage()
							log.type = "$kenewmieyaosha"
							log.from = zz
							room:sendLog(log)
							local slash = sgs.Sanguosha:cloneCard("slash", use.card:getSuit(), use.card:getNumber())
							use.card = slash
							room:setCardFlag(use.card, self:objectName())
							data:setValue(use)
							slash:deleteLater()
						elseif (numtwo == 2) then
							local log = sgs.LogMessage()
							log.type = "$kenewmieyaohuosha"
							log.from = zz
							room:sendLog(log)
							local slash = sgs.Sanguosha:cloneCard("fire_slash", use.card:getSuit(), use.card:getNumber())
							use.card = slash
							room:setCardFlag(use.card, self:objectName())
							data:setValue(use)
							slash:deleteLater()
						elseif (numtwo == 3) then
							local log = sgs.LogMessage()
							log.type = "$kenewmieyaoleisha"
							log.from = zz
							room:sendLog(log)
							local slash = sgs.Sanguosha:cloneCard("thunder_slash", use.card:getSuit(),
								use.card:getNumber())
							use.card = slash
							room:setCardFlag(use.card, self:objectName())
							data:setValue(use)
							slash:deleteLater()
						elseif (numtwo == 4) then
							local log = sgs.LogMessage()
							log.type = "$kenewmieyaobingsha"
							log.from = zz
							room:sendLog(log)
							local slash = sgs.Sanguosha:cloneCard("ice_slash", use.card:getSuit(), use.card:getNumber())
							use.card = slash
							room:setCardFlag(use.card, self:objectName())
							data:setValue(use)
							slash:deleteLater()
						end
					elseif (num == 2) then
						local log = sgs.LogMessage()
						log.type = "$kenewmieyaojiu"
						log.from = zz
						room:sendLog(log)
						local slash = sgs.Sanguosha:cloneCard("analeptic", use.card:getSuit(), use.card:getNumber())
						use.card = slash
						room:setCardFlag(use.card, self:objectName())
						data:setValue(use)
						slash:deleteLater()
					elseif (num == 3) then
						local log = sgs.LogMessage()
						log.type = "$kenewmieyaotao"
						log.from = zz
						room:sendLog(log)
						local slash = sgs.Sanguosha:cloneCard("peach", use.card:getSuit(), use.card:getNumber())
						use.card = slash
						room:setCardFlag(use.card, self:objectName())
						data:setValue(use)
						slash:deleteLater()
					end
				end
			end
			room:removeTag("kenewmieyao")
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kenewlisong:addSkill(kenewmieyao)
kenewlisongex:addSkill("kenewmieyao")

kenewduangui = sgs.General(extension, "kenewduangui", "qun", 1, true, true)
kenewduanguiex = sgs.General(extension, "kenewduanguiex", "qun", 1, true, true, true)

kenewjueling = sgs.CreateTriggerSkill {
	name = "kenewjueling",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused, sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(use.to) do
				if (p:objectName() ~= player:objectName()) and (p:getHandcardNum() <= player:getHandcardNum()) then
					players:append(p)
				end
			end
			if players:length() > 0 then
				local log = sgs.LogMessage()
				log.type = "$kenewjuelinglog"
				log.from = player
				for _, p in sgs.qlist(use.to) do
					log.to:append(p)
				end
				room:sendLog(log)
				if (player:getGeneralName() == "kenewduangui" or player:getGeneral2Name() == "kenewduangui") then
					room:broadcastSkillInvoke(self:objectName(), 1)
				elseif (player:getGeneralName() == "kenewduanguiex" or player:getGeneral2Name() == "kenewduanguiex") then
					room:broadcastSkillInvoke(self:objectName(), 2)
				end
				room:setPlayerFlag(player, "duanguiyuyin")
				local no_respond_list = use.no_respond_list
				for _, szm in sgs.qlist(players) do
					table.insert(no_respond_list, szm:objectName())
				end
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		end
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if (damage.from:objectName() == player:objectName())
				and (damage.to:isKongcheng() or (damage.to:getEquips():length() == 0) or (damage.to:getJudgingArea():length() > 0))
				and (damage.from:getMark("juelingadd-Clear") == 0) then
				room:setPlayerMark(damage.from, "juelingadd-Clear", 1)
				if not player:hasFlag("duanguiyuyin") then
					if (player:getGeneralName() == "kenewduangui" or player:getGeneral2Name() == "kenewduangui") then
						room:broadcastSkillInvoke(self:objectName(), 1)
					elseif (player:getGeneralName() == "kenewduanguiex" or player:getGeneral2Name() == "kenewduanguiex") then
						room:broadcastSkillInvoke(self:objectName(), 2)
					end
				else
					room:setPlayerFlag(player, "-duanguiyuyin")
				end
				local hurt = damage.damage
				damage.damage = hurt + 1
				room:sendCompulsoryTriggerLog(player, self:objectName())
				data:setValue(damage)
			end
		end
	end,
}
kenewduangui:addSkill(kenewjueling)
kenewduanguiex:addSkill("kenewjueling")

kenewguosheng = sgs.General(extension, "kenewguosheng", "qun", 1, true, true)
kenewguoshengex = sgs.General(extension, "kenewguoshengex", "qun", 1, true, true, true)
--kenewguosheng:setGender(sgs.General_Sexless)
--kenewguoshengex:setGender(sgs.General_Sexless)

kenewyuanli = sgs.CreateTriggerSkill {
	name = "kenewyuanli",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageInflicted, sgs.PreHpLost },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreHpLost then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canSlash(p, nil, false) then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local eny = room:askForPlayerChosen(player, players, self:objectName(), "yuanliask", true, true)
				if eny then
					local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
					slash:setSkillName(self:objectName())
					local card_use = sgs.CardUseStruct()
					card_use.from = player
					card_use.to:append(eny)
					card_use.card = slash
					room:useCard(card_use, false)
					slash:deleteLater()
				end
			end
		end
	end,
}
kenewguosheng:addSkill(kenewyuanli)
kenewguoshengex:addSkill("kenewyuanli")


kenewgaowang = sgs.General(extension, "kenewgaowang", "qun", 1, true, true)
kenewgaowangex = sgs.General(extension, "kenewgaowangex", "qun", 1, true, true, true)

kenewsiji = sgs.CreateTriggerSkill {
	name = "kenewsiji",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kenewsiji",
	events = { sgs.PreHpRecover, sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.PreHpRecover) then
			local recover = data:toRecover()
			local gws = room:findPlayersBySkillName(self:objectName())
			for _, gw in sgs.qlist(gws) do
				if (gw:objectName() ~= recover.who:objectName()) and (gw:getMark("@kenewsiji") > 0) and (gw:getMark("usekenewsiji") == 0) then
					if gw:askForSkillInvoke(self, ToData("kenewsiji-ask:" .. recover.who:objectName() .. ":" .. recover.recover)) then
						if (gw:getGeneralName() == "kenewgaowang" or gw:getGeneral2Name() == "kenewgaowang") then
							room:broadcastSkillInvoke(self:objectName(), 1)
						elseif (gw:getGeneralName() == "kenewgaowangex" or gw:getGeneral2Name() == "kenewgaowangex") then
							room:broadcastSkillInvoke(self:objectName(), 2)
						end
						room:addPlayerMark(gw, "usekenewsiji", 1)
						room:removePlayerMark(gw, "@kenewsiji", 1)
						room:loseHp(recover.who, recover.recover)
						return true
					end
				end
			end
		end
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			local gws = room:findPlayersBySkillName(self:objectName())
			for _, gw in sgs.qlist(gws) do
				if (gw:objectName() ~= damage.to:objectName()) and (gw:getMark("@kenewsiji") > 0) and (gw:getMark("usekenewsiji") == 0) then
					room:setPlayerFlag(gw, "kenewsiji_damage")
					if gw:askForSkillInvoke(self, ToData("kenewsijida-ask:" .. damage.to:objectName() .. ":" .. damage.damage)) then
						room:setPlayerFlag(gw, "-kenewsiji_damage")
						if (gw:getGeneralName() == "kenewgaowang" or gw:getGeneral2Name() == "kenewgaowang") then
							room:broadcastSkillInvoke(self:objectName(), 1)
						elseif (gw:getGeneralName() == "kenewgaowangex" or gw:getGeneral2Name() == "kenewgaowangex") then
							room:broadcastSkillInvoke(self:objectName(), 2)
						end
						room:addPlayerMark(gw, "usekenewsiji", 1)
						room:removePlayerMark(gw, "@kenewsiji", 1)
						local recover = sgs.RecoverStruct()
						recover.who = damage.to
						recover.recover = damage.damage
						room:recover(damage.to, recover)
						return true
					end
					room:setPlayerFlag(gw, "-kenewsiji_damage")
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
kenewgaowang:addSkill(kenewsiji)
kenewgaowangex:addSkill("kenewsiji")


xiaxiaoke = sgs.General(extension, "xiaxiaoke", "god", 3, true)

xiajianxinCard = sgs.CreateSkillCard {
	name = "xiajianxinCard",
	target_fixed = true,
	will_throw = false,
	mute = true,
	on_use = function(self, room, source, targets)
		if source:isAlive() then
			room:setPlayerFlag(source, "canjxred")
			if not sgs.Sanguosha:getCard(self:getSubcards():first()):isDamageCard() then
				room:setPlayerFlag(source, "yesequip")
			end
			local idd = self:getSubcards():first()
			local cardd = room:askForUseCard(source, "" .. idd, "xiajianxin-ask")
			if cardd and source:hasFlag("yesequip") then
				room:setPlayerFlag(source, "usingcixu")
			end
			room:setPlayerFlag(source, "-canjxred")
			room:setPlayerFlag(source, "-yesequip")
		end
	end
}

xiajianxinVS = sgs.CreateViewAsSkill {
	name = "xiajianxin",
	n = 1,
	view_filter = function(self, cards, to_select)
		return (not sgs.Self:isJilei(to_select)) and (to_select:isAvailable(sgs.Self)) and (not to_select:isEquipped())
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = xiajianxinCard:clone()
		card:addSubcard(cards[1])
		card:setSkillName("xiajianxin")
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@xiajianxin"
	end
}


xiajianxin = sgs.CreateTriggerSkill {
	name = "xiajianxin",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.DamageCaused, sgs.CardFinished, sgs.JinkEffect, sgs.NullificationEffect },
	view_as_skill = xiajianxinVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if (not use.card:isKindOf("EquipCard")) and (use.card:getSuit() == sgs.Card_Heart)
				and (not use.card:isKindOf("SkillCard")) then
				local xk = room:findPlayerBySkillName(self:objectName())
				if xk and (not xk:hasFlag("jxsource")) then
					room:setCardFlag(use.card, "orijianxincard")
					xk:drawCards(1)
					room:setPlayerFlag(use.from, "jxuser")
					room:setPlayerFlag(xk, "jxsource")
					if (use.from ~= xk) then
						room:getThread():delay(500)
						room:broadcastSkillInvoke(self:objectName(), math.random(1, 4))
						--local used = room:askForUseCard(xk, "@@xiajianxin", "usejxcard-ask")
						local pattern = {}
						for _, c in sgs.qlist(xk:getCards("h")) do
							if (not xk:isJilei(c)) and (c:isAvailable(xk)) then
								table.insert(pattern, c:getEffectiveId())
							end
						end
						room:setPlayerFlag(xk, "canjxred")
						--,-1,sgs.Card_MethodUse,true,xk,nil,"thecixucard"
						if (#pattern > 0) then
							--if not sgs.Sanguosha:getCard(room:askForUseCard(xk, table.concat(pattern, ",") , "xiajianxin-ask"):getSubcards():first()):isDamageCard() then
							local theid = room:askForUseCard(xk, table.concat(pattern, ","), "xiajianxin-ask")
								:getSubcards():first()
							local thecard = sgs.Sanguosha:getCard(theid)
							if not thecard:isDamageCard() then
								if xk:hasSkill("xiaqiqiaocixu") and xk:askForSkillInvoke(self, KeToData("jianxin-cixu:" .. use.from:objectName())) then --xk:askForSkillInvoke(self,_data )then
									local log = sgs.LogMessage()
									log.type = "$xiacixulog"
									log.from = xk
									room:sendLog(log)
									if xk:canDiscard(use.from, "he") then
										room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
										local to_throw = room:askForCardChosen(xk, use.from, "he", "xiaqiqiaocixu")
										local card = sgs.Sanguosha:getCard(to_throw)
										room:throwCard(card, use.from, xk)
									end
								end
								room:setPlayerFlag(xk, "-usingcixu")
							end
							room:setPlayerFlag(xk, "-canjxred")

							if xk:hasFlag("jianxinhit") and xk:hasSkill("xiaqiqiaosuifeng") then
								if xk:askForSkillInvoke(self, KeToData("jianxin-cancelalltarget:" .. use.from:objectName() .. ":" .. use.card:objectName())) then
									room:broadcastSkillInvoke(self:objectName(), math.random(7, 8))
									if not (use.card:isKindOf("Jink") or use.card:isKindOf("Nullification")) then
										local log = sgs.LogMessage()
										log.type = "$xiajianxinlog"
										log.from = xk
										log.card_str = use.card:toString()
										room:sendLog(log)
										local nullified_list = use.nullified_list
										for _, p in sgs.qlist(use.to) do
											table.insert(nullified_list, p:objectName())
										end
										table.insert(nullified_list, player:objectName())
										use.nullified_list = nullified_list
										data:setValue(use)
									end
									if use.card:isKindOf("Nullification") then
										room:setPlayerFlag(use.from, "jianxinnowx")
									end
								end
							end
						end
					end
				end
			end
		end
		if event == sgs.PreCardResponded then
			local res = data:toCardResponse()
			if res.m_card:isKindOf("Jink") then
				local xk = room:findPlayerBySkillName(self:objectName())
				if xk and (not xk:hasFlag("jxsource")) then
					room:setCardFlag(res.m_card, "orijianxincard")
					xk:drawCards(1)
					room:setPlayerFlag(res.m_who, "jxuser")
					room:setPlayerFlag(xk, "jxsource")
					if (res.m_who ~= xk) then
						room:broadcastSkillInvoke(self:objectName(), math.random(1, 4))
						local pattern = {}
						for _, c in sgs.qlist(xk:getCards("h")) do
							if (not xk:isJilei(c)) and (c:isAvailable(xk)) then
								table.insert(pattern, c:getEffectiveId())
							end
						end
						room:setPlayerFlag(xk, "canjxred")
						local to_use = sgs.IntList()
						for _, c in sgs.qlist(xk:getCards("h")) do
							if (not xk:isJilei(c)) and (c:isAvailable(xk)) then
								to_use:append(c:getId())
							end
						end
						if not to_use:isEmpty() then
							local theid = room:askForUseCard(xk, table.concat(pattern, ","), "xiajianxin-ask")
								:getSubcards():first()
							local thecard = sgs.Sanguosha:getCard(theid)
							if not thecard:isDamageCard() then
								if xk:hasSkill("xiaqiqiaocixu") and xk:askForSkillInvoke(self, KeToData("jianxin-cixu:" .. use.from:objectName())) then
									local log = sgs.LogMessage()
									log.type = "$xiacixulog"
									log.from = xk
									room:sendLog(log)
									if xk:canDiscard(use.from, "he") then
										room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
										local to_throw = room:askForCardChosen(xk, use.from, "he", "xiaqiqiaocixu")
										local card = sgs.Sanguosha:getCard(to_throw)
										room:throwCard(card, use.from, xk)
									end
								end
							end
							room:setPlayerFlag(xk, "-canjxred")

							if xk:hasFlag("jianxinhit") and xk:hasSkill("xiaqiqiaosuifeng") then
								if xk:askForSkillInvoke(self, KeToData("jianxin-cancelalltarget:" .. res.m_card:objectName())) then
									room:broadcastSkillInvoke(self:objectName(), math.random(7, 8))
									if res.m_card:isKindOf("Jink") then
										room:setPlayerFlag(res.m_who, "jianxinnojink")
									end
								end
							end
						end
					end
				end
			end
		end

		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.from:hasFlag("jxsource") and damage.to:hasFlag("jxuser") then
				room:setPlayerFlag(damage.from, "jianxinhit")
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("orijianxincard") then
				for _, ev in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerFlag(ev, "-jxsource")
					room:setPlayerFlag(ev, "-jianxinhit")
				end
			end
			if use.card:hasFlag("thecixucard") then

			end
		end
		if event == sgs.JinkEffect then
			if player:hasFlag("jianxinnojink") then
				room:setPlayerFlag(player, "-jianxinnojink")
				return true
			end
		end
		if event == sgs.NullificationEffect then
			if player:hasFlag("jianxinnowx") then
				room:setPlayerFlag(player, "-jianxinnowx")
				return true
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
xiaxiaoke:addSkill(xiajianxin)

xiajianxinex = sgs.CreateTriggerSkill {
	name = "xiajianxinex",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetSpecified) and (player:hasSkill("xiajianxin")) then
			local use = data:toCardUse()
			local room = player:getRoom()
			if use.card:isRed() and player:hasSkill("xiaqiqiaojianshan") and player:hasFlag("jxsource") and player:hasFlag("canjxred") then
				room:sendCompulsoryTriggerLog(player, "xiaqiqiaojianshan")
				if not ((use.to:length() == 1) and (use.to:contains(player))) then
					room:broadcastSkillInvoke("xiajianxin", math.random(9, 12))
				end
				local players = sgs.SPlayerList()
				for _, pp in sgs.qlist(use.to) do
					players:append(pp)
				end
				if players:contains(player) then
					players:removeOne(player)
				end
				local daomeidan = room:askForPlayersChosen(player, players, self:objectName(), 0, 99,
					"jianshanchosen-ask", false, true)
				if not daomeidan:isEmpty() then
					for _, p in sgs.qlist(daomeidan) do
						room:addPlayerMark(p, "@skill_invalidity")
						room:addPlayerMark(p, "jianxinsuo")
					end
				end
			end
			if use.card:isBlack() and player:hasSkill("xiaqiqiaojianshan") and player:hasFlag("jxsource") then
				room:sendCompulsoryTriggerLog(player, "xiaqiqiaojianshan")
				room:broadcastSkillInvoke("xiajianxin", math.random(9, 12))
				local no_respond_list = use.no_respond_list
				for _, p in sgs.qlist(use.to) do
					table.insert(no_respond_list, p:objectName())
				end
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if (p:getMark("jianxinsuo") > 0) then
						local num = p:getMark("jianxinsuo")
						room:removePlayerMark(p, "@skill_invalidity", num)
						room:removePlayerMark(p, "jianxinsuo", num)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target:isAlive()
	end
}
if not sgs.Sanguosha:getSkill("xiajianxinex") then skills:append(xiajianxinex) end


xiajianxinjl = sgs.CreateTargetModSkill {
	name = "xiajianxinjl",
	distance_limit_func = function(self, from, card)
		if from:hasFlag("jxsource") and (card:isKindOf("BasicCard")) and from:hasSkill("xiaqiqiaozhuxing") then
			return 999
		end
	end
}
if not sgs.Sanguosha:getSkill("xiajianxinjl") then skills:append(xiajianxinjl) end

xiajianxinjlex = sgs.CreateTargetModSkill {
	name = "xiajianxinjlex",
	pattern = "TrickCard",
	distance_limit_func = function(self, from, card)
		if from:hasFlag("jxsource") and from:hasSkill("xiaqiqiaozhuxing") then
			return 1000
		else
			return 0
		end
	end,
}
if not sgs.Sanguosha:getSkill("xiajianxinjlex") then skills:append(xiajianxinjlex) end

xiaqiqiao = sgs.CreateTriggerSkill {
	name = "xiaqiqiao",
	events = { sgs.GameStart, sgs.RoundStart },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.RoundStart) then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			if player:hasSkill("xiajianxin") then
				if not ((player:hasSkill("xiaqiqiaosuifeng")) and (player:hasSkill("xiaqiqiaojianshan")) and (player:hasSkill("xiaqiqiaozhuxing")) and (player:hasSkill("xiaqiqiaocixu"))) then
					room:broadcastSkillInvoke(self:objectName())
					local choices = {}
					if not player:hasSkill("xiaqiqiaosuifeng") then
						table.insert(choices, "qqsf")
					end
					if not player:hasSkill("xiaqiqiaojianshan") then
						table.insert(choices, "qqjs")
					end
					if not player:hasSkill("xiaqiqiaozhuxing") then
						table.insert(choices, "qqzx")
					end
					if not player:hasSkill("xiaqiqiaocixu") then
						table.insert(choices, "qqcx")
					end
					local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
					if choice == "qqsf" then
						room:attachSkillToPlayer(player, "xiaqiqiaosuifeng")
						room:setPlayerMark(player, "xiaqiqiaosuifengmark", 1)
						player:drawCards(1)
					end
					if choice == "qqjs" then
						room:attachSkillToPlayer(player, "xiaqiqiaojianshan")
						room:setPlayerMark(player, "xiaqiqiaojianshanmark", 1)
						player:drawCards(1)
					end
					if choice == "qqzx" then
						room:attachSkillToPlayer(player, "xiaqiqiaozhuxing")
						room:setPlayerMark(player, "xiaqiqiaozhuxingmark", 1)
						player:drawCards(1)
					end
					if choice == "qqcx" then
						room:attachSkillToPlayer(player, "xiaqiqiaocixu")
						room:setPlayerMark(player, "xiaqiqiaocixumark", 1)
						player:drawCards(1)
					end
					--确保技能
					if (player:getMark("xiaqiqiaosuifengmark") > 0) and not player:hasSkill("xiaqiqiaosuifeng") then
						room:attachSkillToPlayer(player, "xiaqiqiaosuifeng")
					end
					if (player:getMark("xiaqiqiaojianshanmark") > 0) and not player:hasSkill("xiaqiqiaojianshan") then
						room:attachSkillToPlayer(player, "xiaqiqiaojianshan")
					end
					if (player:getMark("xiaqiqiaozhuxingmark") > 0) and not player:hasSkill("xiaqiqiaozhuxing") then
						room:attachSkillToPlayer(player, "xiaqiqiaozhuxing")
					end
					if (player:getMark("xiaqiqiaocixumark") > 0) and not player:hasSkill("xiaqiqiaocixu") then
						room:attachSkillToPlayer(player, "xiaqiqiaocixu")
					end
				end
			end
		end
	end,
}
xiaxiaoke:addSkill(xiaqiqiao)

xiaqiqiaosuifeng = sgs.CreateTriggerSkill {
	name = "xiaqiqiaosuifeng&",
	on_trigger = function(self, event, player, data)
	end,
}
if not sgs.Sanguosha:getSkill("xiaqiqiaosuifeng") then skills:append(xiaqiqiaosuifeng) end

xiaqiqiaojianshan = sgs.CreateTriggerSkill {
	name = "xiaqiqiaojianshan&",
	on_trigger = function(self, event, player, data)
	end,
}
if not sgs.Sanguosha:getSkill("xiaqiqiaojianshan") then skills:append(xiaqiqiaojianshan) end

xiaqiqiaozhuxing = sgs.CreateTriggerSkill {
	name = "xiaqiqiaozhuxing&",
	on_trigger = function(self, event, player, data)
	end,
}
if not sgs.Sanguosha:getSkill("xiaqiqiaozhuxing") then skills:append(xiaqiqiaozhuxing) end

xiaqiqiaocixu = sgs.CreateTriggerSkill {
	name = "xiaqiqiaocixu&",
	on_trigger = function(self, event, player, data)
	end,
}
if not sgs.Sanguosha:getSkill("xiaqiqiaocixu") then skills:append(xiaqiqiaocixu) end







sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable {
	["kearnews"] = "新创包",


	--小珂
	["kidxiaoke"] = "小珂",
	["&kidxiaoke"] = "小珂",
	["#kidxiaoke"] = "昔日旧趣",
	["designer:kidxiaoke"] = "小珂酱",
	["cv:kidxiaoke"] = "官方",
	["illustrator:kidxiaoke"] = "官方",

	["kewanqu"] = "玩趣",
	[":kewanqu"] = "锁定技，你的起始手牌数-3，当你接下来三次受到其他角色造成的伤害时，你分别：1.获得伤害来源的一张牌；2.对伤害来源造成1点伤害；3.回复1点体力，然后获得“嬉闹”。",

	["kedaoluan"] = "捣乱",
	[":kedaoluan"] = "摸牌阶段，若你的手牌数不大于体力值，你可以多摸三张牌，若如此做，你跳过本回合的出牌阶段和弃牌阶段，且直到你下回合开始，每当一名其他角色使用♥牌时，你可以使用一张牌。你于回合外使用的牌不能被响应。",

	["kexinao"] = "嬉闹",
	[":kexinao"] = "每回合限一次，当其他角色非因【杀】对你造成伤害后，你可以弃置一张牌，若此牌颜色为：黑色，视为你对伤害来源使用一张随机花色的【屎】；红色，该角色弃置你选择的一种颜色的所有牌。",

	["xiaokedaoluan-ask"] = "你可以使用一张牌",
	["kexinao-dis"] = "你可以弃置一张牌发动“嬉闹”",


	--侠小珂
	["xiaxiaoke"] = "南宫珂",
	["&xiaxiaoke"] = "南宫珂",
	["#xiaxiaoke"] = "昔日旧趣",
	["designer:xiaxiaoke"] = "小珂酱",
	["cv:xiaxiaoke"] = "酒井苍",
	["illustrator:xiaxiaoke"] = "-",

	["xiajianxin"] = "剑心",
	["xiajianxinex"] = "剑心",
	["xiajianxin:jianxin-cancelalltarget"] = "你可以发动“碎玉”令 %src 使用的 【%dest】 无效",
	[":xiajianxin"] = "当一名角色使用♥非装备牌时，你摸一张牌，若使用者不是你，你可以使用一张牌（无次数限制）。（此♥牌结算完毕之前不能再发动“剑心”）",
	["xiajianxin-ask"] = "你可以使用一张牌",
	["usejxcard-ask"] = "你可以发动“剑心”选择一张牌用于使用",

	["$xiajianxinlog"] = "%from 发动了“<font color='yellow'><b>碎玉</b></font>” ，%card无效！",
	["$xiacixulog"] = "%from 发动了“<font color='yellow'><b>刺虚</b></font>” ",

	["xiaqiqiao"] = "启鞘",
	[":xiaqiqiao"] = "每轮开始时，若你拥有技能“剑心”，你升级一项“剑心”并摸一张牌：\
	<font color='#3366FF'><b>碎玉</b></font>：若你发动“剑心”使用的牌对该♥牌的使用者造成了伤害，你可以令该♥牌无效；\
    <font color='#3366FF'><b>剑闪</b></font>：你发动“剑心”使用的黑色牌不能被响应；红色牌指定目标后，你可以令其中任意名其他角色的非锁定技无效直到当前回合结束；\
    <font color='#3366FF'><b>逐星</b></font>：你发动“剑心”时使用牌无距离限制；\
    <font color='#3366FF'><b>刺虚</b></font>：当你发动“剑心”使用非伤害类牌时，你可以弃置该♥牌使用者的一张牌。",

	["xiaqiqiao:qqsf"] = "碎玉：若你因“剑心”使用的牌对该♥牌的使用者造成了伤害，你可以令该♥牌无效",
	["xiaqiqiao:qqjs"] = "剑闪：你发动“剑心”使用的黑色牌不能被响应；红色牌指定目标后，你可以令其中任意名其他角色的非锁定技无效直到当前回合结束",
	["xiaqiqiao:qqzx"] = "逐星：你发动“剑心”时使用牌无距离限制",
	["xiaqiqiao:qqcx"] = "刺虚：当你发动“剑心”使用非伤害类牌时，你可以弃置该♥牌使用者的一张牌",

	["jianshanchosen-ask"] = "你可以令任意名目标角色非锁定技无效直到当前回合结束",

	["xiaqiqiaojianshan"] = "剑闪",
	["xiaqiqiaosuifeng"] = "碎玉",
	["xiaqiqiaozhuxing"] = "逐星",
	["xiaqiqiaocixu"] = "刺虚",
	["xiajianxin:jianxin-cixu"] = "你可以发动“刺虚”弃置 %src 的一张牌",
	--["jianxin-cixu"] = "刺虚：弃置该♥牌使用者的一张牌",

	[":xiaqiqiaosuifeng"] = "若你因“剑心”使用的牌对该♥牌的使用者造成了伤害，你可以令该♥牌无效",
	[":xiaqiqiaojianshan"] = "你发动“剑心”使用的黑色牌不能被响应；红色牌指定目标后，你可以令其中任意名其他角色的非锁定技无效直到当前回合结束",
	[":xiaqiqiaozhuxing"] = "你发动“剑心”时使用牌无距离限制",
	[":xiaqiqiaocixu"] = "当你发动“剑心”使用非伤害类牌时，你可以弃置该♥牌使用者的一张牌",

	["$xiajianxin1"] = "谁有不平事？",
	["$xiajianxin2"] = "此地禁止胡来。",
	["$xiajianxin3"] = "哈哈。",
	["$xiajianxin4"] = "又是谁在闹事？",
	["$xiajianxin5"] = "穿林打叶！",
	["$xiajianxin6"] = "长锋三尺，可凌云霄。",
	["$xiajianxin7"] = "不准伤人！",
	["$xiajianxin8"] = "恃险若平地，长剑凌清秋。",
	["$xiajianxin9"] = "鼠雀之辈，岂堪一击？",
	["$xiajianxin10"] = "提剑荡千山！",
	["$xiajianxin11"] = "破鞘！",
	["$xiajianxin12"] = "吴钩霜雪明！",

	["$xiaqiqiao1"] = "锋芒既出，尔等宵小安敢不退？",
	["$xiaqiqiao2"] = "师傅说了，打不过就找他。",
	["$xiaqiqiao3"] = "师祖的孤本里，也藏着“天黯”的秘密吗？",
	["$xiaqiqiao4"] = "启鞘拭锋，斩尽宵小！",

	["~xiaxiaoke"] = "剑身虽陨，此心不负。",


	--fc
	["xiafcchengtiandi"] = "FC-橙天帝",
	["&xiafcchengtiandi"] = "橙天帝",
	["#xiafcchengtiandi"] = "时光流逝",
	["designer:xiafcchengtiandi"] = "时光流逝FC",
	["cv:xiafcchengtiandi"] = "官方",
	["illustrator:xiafcchengtiandi"] = "官方",

	["xiatianan"] = "天黯",
	["xiatianan:pandingpai"] = "获得此判定牌",
	["xiatianan:mopai"] = "摸一张牌",
	[":xiatianan"] = "锁定技，你使用牌无距离限制。每当你造成或受到属性伤害后，你进行判定，若有造成此伤害的牌且结果与其颜色相同，你获得此判定牌或摸一张牌，否则你随机执行一项。",

	["xiaxingmie"] = "星灭",
	["xiaxingmieslash"] = "星灭杀",

	[":xiaxingmie"] = "回合开始时，你摸X张牌且你本回合手牌上限+X（X为你从上回合开始前满足的项数，若此时是你的第一个回合，X改为你从游戏开始时满足的项数）。\
	○使用过非转化非虚拟的【杀】；\
	○进行过判定；\
	○使用过装备牌；\
	○使用【酒】【杀】造成过伤害；\
	○造成过火焰伤害；\
	○使用过【无懈可击】，或使用或打出过【闪】；\
	○对一名处于濒死状态的角色使用过【桃】；\
	然后若X：不小于1，本轮限一次，你可以将一张♥牌当火【杀】使用或打出；不小于3，你从弃牌堆随机获得一张火【杀】；不小于5，你可以视为对一名角色使用一张不计入次数的火【杀】；不小于7，你可以对一名其他角色造成Y点火焰伤害（Y为该角色空置的区域数+1）。",

	["xmslash"] = "星灭：杀",
	["xmdrank"] = "星灭：酒杀",
	["xmpeach"] = "星灭：桃",
	["xmweapon"] = "星灭：武器",
	["xmjudge"] = "星灭：判定",
	["xmfire"] = "星灭：火",
	["xmwuxie"] = "星灭：闪&无",

	["fcslash-ask"] = "你可以视为对一名其他角色使用一张无距离限制且不计次的火【杀】",
	--["fcseven-ask"] = "【毁天灭地】你可以对一名其他角色造成%src点火焰伤害",
	["fcseven-ask"] = "<font color='red'><b>【</b></font><font color='orange'><b>毁天灭地</b></font><font color='red'><b>】</b></font>你可以对一名其他角色造成 <font color='yellow'><b>1+其空置的区域数</b></font> 的火焰伤害",

	--新曹操
	["kenewcaocao"] = "新曹操",
	["&kenewcaocao"] = "新曹操",
	["#kenewcaocao"] = "不惧权贵",
	["designer:kenewcaocao"] = "小珂酱",
	["cv:kenewcaocao"] = "官方",
	["illustrator:kenewcaocao"] = "官方",

	["zhuangzhiuse-ask"] = "你可以使用这张牌",
	["kejianxiong"] = "壮志",
	["$kejianxionglog"] = "%from 的<font color='yellow'><b>“壮志”</b></font>效果被触发，此牌不能被 %to 响应。",
	[":kejianxiong"] = "每个回合限一次，当一名角色受到伤害后，你可以获得造成此伤害的牌，然后若该角色是你或你是此牌的使用者且此牌为非转化牌，你可以使用之（无距离和次数限制、不可响应且不计入次数）。",

	["newhujiaa"] = "护驾",
	[":newhujiaa"] = "主公技，每轮限一次，当你受到伤害时，你可以将此伤害转移给一名其他魏势力角色。",
	["@newhujiaa-card"] = "你可以将伤害转移给一名魏势力其他角色",

	["$kejianxiong1"] = "大智若愚，大忠似奸。",
	["$kejianxiong2"] = "非常人，当行非常事！",


	["$newhujiaa1"] = "何人助我？",
	["$newhujiaa2"] = "休要伤我！",

	["~kenewcaocao"] = "壮志难酬啊！",


	--新诸葛亮
	["kenewzhugeliang"] = "新诸葛亮",
	["&kenewzhugeliang"] = "新诸葛亮",
	["#kenewzhugeliang"] = "千古一相",
	["designer:kenewzhugeliang"] = "小珂酱",
	["cv:kenewzhugeliang"] = "官方",
	["illustrator:kenewzhugeliang"] = "官方",

	["kekuitian"] = "窥天",
	[":kekuitian"] = "你或与你邻近的角色回合开始时，你观看牌堆顶的X+3张牌且可以将其中任意张置于牌堆底（X为你已损失的体力值），然后你可以令该角色摸一张牌。",

	["kebeifacishu"] = "发动北伐",
	["ktgive"] = "令其摸一张牌",
	["kebeifa"] = "北伐",

	["kebeifa-ask"] = "请选择发动“北伐”的角色",
	[":kebeifa"] = "出牌阶段限一次，你可以失去1点体力上限并摸X张牌，若如此做，你可以选择一名其他角色，你本回合与其距离视为1，然后你随机获得一张牌堆或弃牌堆中的【诸葛连弩】。",

	["kekongcheng"] = "空城",
	[":kekongcheng"] = "锁定技，当你成为一张【杀】或【决斗】的目标后，此牌有Y/6的概率对你无效（Y为你本局游戏发动“北伐”的次数）。",

	["$kekuitian1"] = "观星定中原，毕其功于一役。",
	["$kekuitian2"] = "璀璨星河，照不亮我胸中阴郁。",
	["$kekuitian3"] = "天有不测风云，谨慎为妙。",
	["$kekuitian4"] = "星象凶险，须谨慎再三，方有一线生机。",
	["$kekuitian5"] = "明月皓星，可否照亮前路？",
	["$kekuitian6"] = "请再帮我一次，延续大汉的国运吧！",

	["$kebeifa1"] = "半生韶华付社稷，一枕清梦压星河。",
	["$kebeifa2"] = "繁星四百八十万，颗颗鉴照老臣心。",
	["$kebeifa3"] = "一琴一曲一城，一人一诺一生。",
	["$kebeifa4"] = "老夫独守此城，何惧万马千军？",
	["$kebeifa5"] = "事已至此，只能险中求胜了。",

	["$kekongcheng1"] = "一曲高山流水，还请诸位静听。",
	["$kekongcheng2"] = "我城中并无一兵一卒。",
	["$kekongcheng3"] = "玩得就是心跳。",
	["$kekongcheng4"] = "心疑，则难进。",
	["$kekongcheng5"] = "真是险中用险啊。",

	["~kenewzhugeliang"] = "独木难支益州地，上方雨落万事空。",

	--新孙坚
	["kenewsunjian"] = "新孙坚",
	["&kenewsunjian"] = "新孙坚",
	["#kenewsunjian"] = "魂佑江东",
	["designer:kenewsunjian"] = "小珂酱",
	["cv:kenewsunjian"] = "官方",
	["illustrator:kenewsunjian"] = "官方",

	["kewulie"] = "英魂",
	[":kewulie"] = "准备阶段，你可以弃置至多X名角色区域内的各一张牌（X为你已损失的体力值），若这些角色数量小于X，你对没有手牌的其他角色造成的伤害+1直到你下回合开始。",
	["kewulie-ask"] = "请选择发动“武烈”弃牌的角色",

	["kexihuo"] = "立业",
	[":kexihuo"] = "限定技，游戏开始时，你获得1枚“玉玺”标记。出牌阶段，你可以将“玉玺”标记交给一名其他角色并与其各增加1点体力上限。拥有“玉玺”标记的角色手牌上限+2。",

	["kewulielord"] = "武烈",
	[":kewulielord"] = "主公技，当你发动“英魂”时，每有一名其他吴势力角色存活，你令该技能描述中的X+1。",
	["$usekewulie"] = "%from 发动了技能<font color='yellow'><b>“英魂”</s></font>",

	["$kewulie1"] = "宝剑出鞘，踏平贼营！",
	["$kewulie2"] = "乱世清君侧，挥师复江山！",
	["$kewulie3"] = "泉台舞戈斗阎罗，且招旧部为鬼雄！",
	["$kewulie4"] = "谁道死去万事空？英魂依旧守江东！",
	["$kewulie5"] = "虎臣北奔，克敌摧城！",
	["$kewulie6"] = "西凉乱政，忠义之士焉能坐视？",

	["$kexihuo1"] = "止戈为武，平尽天下不平事！",
	["$kexihuo2"] = "捐躯成烈，无愧世间有愧人！",

	["~kenewsunjian"] = "生江东，死江北，一生无愧！",


	--新赵云
	["kenewzhaoyun"] = "新赵云",
	["&kenewzhaoyun"] = "新赵云",
	["#kenewzhaoyun"] = "龙威虎胆",
	["designer:kenewzhaoyun"] = "小珂酱",
	["cv:kenewzhaoyun"] = "官方",
	["illustrator:kenewzhaoyun"] = "官方",

	["keliezhen"] = "裂阵",
	["keliezhen:mopai"] = "摸两张牌",
	["keliezhen:huixue"] = "回复1点体力",
	[":keliezhen"] = "出牌阶段限一次，你可以与一名角色交换座次，若如此做，你攻击范围内新包含的角色本阶段不能使用或打出手牌，然后你可以随机弃置任意名仍包含在攻击范围的角色各一张牌并令其此阶段非锁定技失效。此阶段结束时，你再次与其交换座次。",
	["liezhenkill"] = "裂阵杀敌",
	["kexianglong"] = "龙胆",
	[":kexianglong"] = "你可以将一张【杀】当【闪】、【闪】当【杀】、【酒】当【桃】、【桃】当【酒】使用或打出，你以此法使用的【杀】不计入次数。",
	["keliezhen-ask"] = "请选择弃牌的角色",


	["kelongxiang"] = "翔龙",
	["kexianglong-ask"] = "你可以令一名角色获得1点护甲",
	[":kelongxiang"] = "回合结束时，若你本回合造成的伤害数：不小于1点，你从牌堆获得一张基本牌；不小于2点，你可以令一名没有护甲的角色获得1点护甲；不小于3点，你拥有“涯角”直到下回合开始。",




	["$keliezhen1"] = "哼，有胆就先接我两招！",
	["$keliezhen2"] = "凭此八门金锁，何以阻我？",
	["$keliezhen3"] = "天崩可寻路，海角誓相随！",
	["$keliezhen4"] = "照夜破长空，涯角定乾坤！",
	["$keliezhen5"] = "万军取敌首级，涯角助我！",
	["$keliezhen6"] = "涯角之利，锐不可当！",
	["$keliezhen7"] = "七进七出，涯角皆在其侧！",
	["$keliezhen8"] = "枪挑四海，咫尺天涯！",
	["$keliezhen9"] = "横枪勒马，舍我其谁？",
	["$keliezhen10"] = "（音效）",
	["$keliezhen11"] = "（音效）",
	["$keliezhen12"] = "（音效）",
	["$keliezhen13"] = "（音效）",

	["$kexianglong1"] = "龙游沙场，胆战群雄！",
	["$kexianglong2"] = "以死搏生，无敌不克！",
	["$kexianglong3"] = "一枪在手，贼军何足道哉！",
	["$kexianglong4"] = "龙鳞佑我，无伤分毫。",
	["$kexianglong5"] = "待敌须有略，孤勇岂可为？",
	["$kexianglong6"] = "满腔热血，浑身是胆！",
	["$kexianglong7"] = "攻防一体，无懈可击！",
	["$kexianglong8"] = "纵横沙场，不惧刀光剑影！",
	["$kexianglong9"] = "一身一胆，只为吾主。",
	["$kexianglong10"] = "平战乱，享太平。",
	["$kexianglong11"] = "破阵御敌，傲然屹立！",

	["~kenewzhaoyun"] = "后主大梦未醒，北伐久战无功。",



	--新张飞
	["kenewzhangfei"] = "新张飞",
	["&kenewzhangfei"] = "新张飞",
	["#kenewzhangfei"] = "万夫不敌",
	["designer:kenewzhangfei"] = "小珂酱",
	["cv:kenewzhangfei"] = "官方",
	["illustrator:kenewzhangfei"] = "官方",

	["kechenniang"] = "醉酿",
	[":kechenniang"] = "你可以将一张【闪】或装备牌当【酒】使用；你使用【酒】的效果改为：出牌阶段令你本回合使用的下两张伤害类牌伤害+1，或令处于濒死状态的你回复2点体力。",

	["kenewpaoxiao"] = "咆哮",
	[":kenewpaoxiao"] = "锁定技，你使用【杀】无距离和次数限制；当你使用的未造成伤害的伤害类牌结算完毕后，你摸等同于此牌目标数的牌。",

	["$kenewpaoxiao1"] = "哇呀呀呀呀呀！",
	["$kenewpaoxiao2"] = "着！",
	["$kenewpaoxiao3"] = "竖子休走，张飞在此！",
	["$kenewpaoxiao4"] = "此声一震，桥断水停！",
	["$kenewpaoxiao5"] = "连杀数刀，汝命危矣！",
	["$kenewpaoxiao6"] = "有我无敌！",
	["$kenewpaoxiao7"] = "看我取汝首级！",
	["$kenewpaoxiao8"] = "虎牢硝烟起，长坂水逆流！",
	["$kenewpaoxiao9"] = "万钧勇力，斩将拔旗！",


	["$kechenniang1"] = "我燕人自有妙计！",
	["$kechenniang2"] = "偃旗息鼓，蓄势待发！",
	["$kechenniang3"] = "三更月下伏兵起，七分醉里斩蛟龙！",
	["$kechenniang4"] = "沙场红袍醉绿蚁，且壮豪气干云天！",
	["$kechenniang5"] = "力大欺理，勇大欺谋。",

	["~kenewzhangfei"] = "贪杯误事，败有余辜。",



	--新孙尚香
	["kenewsunshangxiang"] = "新孙尚香",
	["&kenewsunshangxiang"] = "新孙尚香",
	["#kenewsunshangxiang"] = "才捷箭利",
	["designer:kenewsunshangxiang"] = "小珂酱",
	["cv:kenewsunshangxiang"] = "官方",
	["illustrator:kenewsunshangxiang"] = "官方",

	["kerongchang"] = "戎裳",
	["kerongchangCard"] = "戎裳",
	["bekerongchang"] = "戎裳目标",
	["@kerongchang-discard"] = "请弃置一张牌",
	[":kerongchang"] = "当一张牌置入你的装备区后，若此牌为：武器牌，你可以视为使用一张无距离限制且不计入次数的【杀】；防具牌，你获得1点“护甲”；坐骑牌，你可以令一名其他角色弃置一张牌；宝物牌，你回复1点体力。当牌离开你的装备区后，你摸一张牌。",

	["kexiaoji"] = "倩影",
	["kexiaoji:huixue"] = "令其回复1点体力",
	["kexiaoji:shouhui"] = "令其获得一张装备牌",
	[":kexiaoji"] = "<font color='green'><b>出牌阶段结束时，</b></font>你可以令一名其他角色回复1点体力，或随机获得一名角色区域内的一张装备牌，若如此做，你执行另一项。",

	["kexiaoji-ask"] = "你可以选择发动“枭姬”的角色",
	["kerongchangh-ask"] = "你可以令一名角色弃置一张牌",
	["kexiaojidmdzj-ask"] = "请选择一名角色，你随机获得其区域内的一张装备牌",
	["kexiaojidmdfj-ask"] = "请选择被获得装备牌的角色",
	["kerongchang-ask"] = "你可以使用一张无目标数限制的【杀】（不计次）",

	["$kerongchang1"] = "箭利弓疾，你可打不过我！",
	["$kerongchang2"] = "我会的武器可多着呢！",
	["$kerongchang3"] = "林间箭飞速，倩影枝头走。",
	["$kerongchang4"] = "轻弓俏丽，花剑武美。",
	["$kerongchang5"] = "花暖照心花，月白知有意。",
	["$kerongchang6"] = "小女就爱这舞刀弄枪。",
	["$kerongchang7"] = "才捷刚猛，桀骜不驯。",
	["$kerongchang8"] = "小看我，你可是要吃亏的。",
	["$kerongchang9"] = "横冲直撞，不让须眉。",
	["$kerongchang10"] = "以柔克刚，绣腿擅弓。",
	["$kerongchang11"] = "提弓上马，助夫君一战！",
	["$kerongchang12"] = "刀行厚重，剑走轻灵，本小姐皆可用之。",
	["$kerongchang13"] = "配干将莫邪之利器，善龙泉秋水之佳铭。",
	["$kerongchang14"] = "大喜之日，待妾身剑舞一曲！",
	["$kerongchang15"] = "男子上阵杀敌，女子有何不可？",
	["$kerongchang16"] = "花箭妖弓，你可要小心啦！",
	["$kerongchang17"] = "边月随弓影，胡霜拂剑花。",
	["$kerongchang18"] = "嫁衣着我身，山崩不改，海覆不退！",
	["$kerongchang19"] = "这套剑舞，耍的如何？",
	["$kerongchang20"] = "剑舞如风，一展孙家勇烈！",
	["$kerongchang21"] = "舞三尺之盈盈，云间闪电，掌上生风。",
	["$kerongchang22"] = "本小姐有清歌妙舞，不妨与裳甲一齐献上。",
	["$kerongchang23"] = "众侍婢，随本小姐剑舞迎新！",
	["$kerongchang24"] = "看吾一展武艺，以助夫君！",
	["$kerongchang25"] = "枭姬英黛颜，弓腰巧弄武。",
	["$kerongchang26"] = "清夜心间过，刀剑光影略。",
	["$kerongchang27"] = "情咒相思物，汝欲摧之，吾必杀之。",



	["$kexiaoji1"] = "得遇夫君，妾身福分。",
	["$kexiaoji2"] = "随夫嫁娶，宜室宜家。",
	["$kexiaoji3"] = "展翅同心鸟，同行双飞燕。",
	["$kexiaoji4"] = "凤凰于飞，和鸣锵锵",
	["$kexiaoji5"] = "居愿双膝坐，行愿携手牵。",
	["$kexiaoji6"] = "姻缘天定，喜结连理。",
	["$kexiaoji7"] = "借问春江水，君情与妾心。",
	["$kexiaoji8"] = "日暮归乡迟，道长且艰辛。",
	["$kexiaoji9"] = "与君离别意，兄命自难违。",
	["$kexiaoji10"] = "鸾凤和鸣，情投意合！",
	["$kexiaoji11"] = "愿与夫君永结同心。",
	["$kexiaoji12"] = "爱似鸳鸯戏水，情比蝴蝶双飞。",
	["$kexiaoji13"] = "愿做比翼鸟，与君相鹤鸣。",
	["$kexiaoji14"] = "新年新喜，金诚佳礼。",
	["$kexiaoji15"] = "似梦明眸剪秋水，有志丈夫立人魁。",
	["$kexiaoji16"] = "秦晋绸缪好，百年嬿婉欢。",
	["$kexiaoji17"] = "风铃花摇幽香沁，美心欢喜遇郎君。",
	["$kexiaoji18"] = "十万情丝骚一线，君心我心系两端。",
	["$kexiaoji19"] = "双剑同鸣，双心灵犀！",
	["$kexiaoji20"] = "还望玄德大人珍重妾身。",
	["$kexiaoji21"] = "明眸柔柔情切切，此缘深深莫匆匆。",
	["$kexiaoji22"] = "心之燕耳，白首永携。",
	["$kexiaoji23"] = "情色之欢，乐极永年。",
	["$kexiaoji24"] = "六里已成，莫夫良时。",
	["$kexiaoji25"] = "武共双剑鸣，饮共连理杯。",
	["$kexiaoji26"] = "同声若鼓瑟，合韵似鸣琴。",
	["$kexiaoji27"] = "愿携九天银鱼花，与君白首不分离！",


	["~kenewsunshangxiang"] = "下次比武，我可不会输给哥哥.......",



	--新曹婴
	["kenewcaoying"] = "新曹婴",
	["&kenewcaoying"] = "新曹婴",
	["#kenewcaoying"] = "龙城凤鸣",
	["designer:kenewcaoying"] = "小珂酱",
	["cv:kenewcaoying"] = "官方",
	["illustrator:kenewcaoying"] = "官方",

	["ketwopaomu"] = "砲幕",
	[":ketwopaomu"] = "<font color='green'><b>每轮限一次，</b></font>当一名其他角色对另一名角色造成伤害后，你可以弃置一张牌对这两名角色（除你外）各造成1点火焰伤害；当你杀死角色时，你不执行奖惩并摸三张牌。",
	["usepaomu"] = "已使用砲幕",
	["ketwopaomuliangren"] = "你可以弃置一张牌发动“砲幕”对 %src 和 %dest 各造成1点火焰伤害",
	["ketwopaomuyiren"] = "你可以弃置一张手牌发动“砲幕”对 %src 造成1点火焰伤害",
	["$usekepaomu"] = "%from 发动了技能<font color='yellow'><b>“砲幕”</s></font>",

	["kequshang"] = "曲殇",
	["kequshangCard"] = "曲殇",
	["$kecaoyingmsg"] = "%from 的<font color='yellow'><b>“曲殇”</b></font>效果被触发，此牌不能被 %to 响应。",
	[":kequshang"] = "你于摸牌阶段外获得的牌不计入手牌上限；出牌阶段限一次，你可以观看一名其他角色的手牌并摸X张牌（X为其所在势力的其他角色数），然后其手牌上限-X直到你下回合开始。",

	["kenewfengming"] = "凤鸣",
	[":kenewfengming"] = "当你响应一名角色使用的牌时，你摸一张牌，然后若此牌为虚拟牌或转化牌，你可以获得其一张牌。",

	["kenewfengming:kenewfengming-ask"] = "你可以发动“凤鸣”获得 %src 的一张牌",

	["$ketwopaomu1"] = "大军压境，问汝降是不降？",
	["$ketwopaomu2"] = "将军一副好骨，不如留于此山！",
	["$ketwopaomu3"] = "（爆炸声）",
	["$ketwopaomu4"] = "战役于我为赢，手段品级不论。",

	["$kequshang1"] = "若非耳目齐备，何以手眼通天？",
	["$kequshang2"] = "欲晓敌之态势，无所不用其极。",

	["~kenewcaoying"] = "咳咳，父子可代夫出征，吾自可为国而战！",

	--新钟会
	["kenewzhonghui"] = "新钟会",
	["&kenewzhonghui"] = "新钟会",
	["#kenewzhonghui"] = "童趣六一",
	["designer:kenewzhonghui"] = "小珂酱",
	["cv:kenewzhonghui"] = "官方",
	["illustrator:kenewzhonghui"] = "官方",

	["kenewzhonghuizg"] = "新钟会",
	["&kenewzhonghuizg"] = "新钟会",
	["#kenewzhonghuizg"] = "童趣六一",
	["designer:kenewzhonghuizg"] = "小珂酱",
	["cv:kenewzhonghuizg"] = "官方",
	["illustrator:kenewzhonghuizg"] = "官方",

	["kenewzhonghuitj"] = "新钟会",
	["&kenewzhonghuitj"] = "新钟会",
	["#kenewzhonghuitj"] = "童趣六一",
	["designer:kenewzhonghuitj"] = "小珂酱",
	["cv:kenewzhonghuitj"] = "官方",
	["illustrator:kenewzhonghuitj"] = "官方",


	["kezhenggong"] = "争功",
	["kegong"] = "功",
	["usekezhenggong"] = "已使用争功",
	[":kezhenggong"] = "当你造成的伤害结算完毕后，你获得1枚“功”标记（至多5枚）；每个回合限一次，当一名角色对你距离1以内的角色造成伤害后，若你的手牌数不为全场唯一最多，你可以摸一张牌并成为伤害来源；你的手牌上限+X（X为你“功”标记的数量）。",

	["@usezhenggong"] = "<font color=\"#00FF00\"><b>%src </b></font>将造成伤害，你可以发动“争功”",

	["kenewzhonghuichange"] = "可爱捏：选择皮肤",
	["kenewzhonghuichange:pynt"] = "蒲月念兔",
	["kenewzhonghuichange:zgxp"] = "钟桂香蒲",
	["kenewzhonghuichange:tjbb"] = "偷酒不拜",
	[":kenewzhonghuichange"] = "<font color='#01A5AF'>游戏开始时，你从“蒲月念兔”、“钟桂香蒲”和“偷酒不拜”选择一个皮肤。</font>",

	["kezili"] = "自立",
	["kezili:recover"] = "回复1点体力",
	["kezili:draw"] = "摸两张牌",
	[":kezili"] = "觉醒技，准备阶段，若你有至少3枚“功”标记，你失去1点体力上限，回复1点体力或摸两张牌，然后获得技能“肃逆”。",

	["kesuni"] = "肃逆",
	[":kesuni"] = "出牌阶段限一次，你可以弃置1枚“功”标记并令一名其他角色随机弃置0~X随机张牌（X为其牌数），若该角色没有弃置牌，其失去1点体力。",


	["$kezhenggong1"] = "广设权计，有备无患。",
	["$kezhenggong2"] = "明于权计，审于形势，则力少功大。",
	["$kezhenggong3"] = "缓急不在一时，吾等慢慢来过。",
	["$kezhenggong4"] = "善算轻重，权审其宜。",
	["$kezhenggong5"] = "福祸轮转，暂且退让。",
	["$kezhenggong6"] = "月缺潜水中，月满照星河。",

	["$kezili1"] = "丈夫志在自立，岂可仰仗于他人！",
	["$kezili2"] = "非据一方，吾已自立。",
	["$kezili3"] = "吾功名盖世，岂可复为人下？",
	["$kezili4"] = "天赐良机，不取何为？",
	["$kezili5"] = "独立身，划分界！",
	["$kezili6"] = "自立为主，闯荡一番。",

	["$kesuni1"] = "诛除异己，此乃当务之急！",
	["$kesuni2"] = "异己不排，吾命忧矣。",
	["$kesuni3"] = "攻讦此子，祸咎已除！",
	["$kesuni4"] = "坏吾大计者，罪死不赦！",
	["$kesuni5"] = "哼，你才不是我的伙伴！",
	["$kesuni6"] = "云泥之别，高下立判。",

	["~kenewzhonghui"] = "这就是失策的代价吗......",



	--新曹冲
	["kenewcaochong"] = "新曹冲",
	["&kenewcaochong"] = "新曹冲",
	["#kenewcaochong"] = "童趣六一",
	["designer:kenewcaochong"] = "小珂酱",
	["cv:kenewcaochong"] = "官方",
	["illustrator:kenewcaochong"] = "官方",

	["kenewcaochongcc"] = "新曹冲",
	["&kenewcaochongcc"] = "新曹冲",
	["#kenewcaochongcc"] = "童趣六一",
	["designer:kenewcaochongcc"] = "小珂酱",
	["cv:kenewcaochongcc"] = "官方",
	["illustrator:kenewcaochongcc"] = "官方",

	["kenewcaochongfh"] = "新曹冲",
	["&kenewcaochongfh"] = "新曹冲",
	["#kenewcaochongfh"] = "童趣六一",
	["designer:kenewcaochongfh"] = "小珂酱",
	["cv:kenewcaochongfh"] = "官方",
	["illustrator:kenewcaochongfh"] = "官方",

	["kenewcaochongzn"] = "新曹冲",
	["&kenewcaochongzn"] = "新曹冲",
	["#kenewcaochongzn"] = "童趣六一",
	["designer:kenewcaochongzn"] = "小珂酱",
	["cv:kenewcaochongzn"] = "官方",
	["illustrator:kenewcaochongzn"] = "官方",

	["kenewcaochongzy"] = "新曹冲",
	["&kenewcaochongzy"] = "新曹冲",
	["#kenewcaochongzy"] = "童趣六一",
	["designer:kenewcaochongzy"] = "小珂酱",
	["cv:kenewcaochongzy"] = "官方",
	["illustrator:kenewcaochongzy"] = "官方",

	["kenewcaochongchange"] = "可爱捏：选择皮肤",
	["kenewcaochongchange:wlys"] = "五陵英少",
	["kenewcaochongchange:ccqy"] = "聪察岐嶷",
	["kenewcaochongchange:fhyx"] = "飞虹云象",
	["kenewcaochongchange:zncj"] = "猪年春节",
	["kenewcaochongchange:zyst"] = "资优神童",

	["kehuairen"] = "怀仁",
	["kehuairenex"] = "怀仁",
	[":kehuairen"] = "锁定技，若你于一个回合内成为牌的目标的次数不小于你的体力值，你不能成为其他角色使用牌的目标。",

	["kenewchengxiang"] = "称象",
	["kenewchengxiangCard"] = "称象",
	[":kenewchengxiang"] = "出牌阶段限一次，你可以将任意名体力值或手牌数不小于你的其他角色的各一张手牌与牌堆顶的共计至少五张牌混合后展示，你获得其中任意张点数之和不大于13的牌，若你获得的牌点数和为13，你回复1点体力。",

	["keceyin"] = "恻隐",
	["keceyin-ask"] = "你可以弃置一张牌发动“恻隐”",
	[":keceyin"] = "每轮限一次，当一名角色受到不小于其体力值的伤害时，你可以弃置一张牌防止此伤害，然后若你弃置的牌为装备牌，你与其各摸一张牌。",


	["usedceyin"] = "已使用恻隐",

	["$kenewchengxiang1"] = "容我来算上一算。",
	["$kenewchengxiang2"] = "物以载之，校可知矣。",
	["$kenewchengxiang3"] = "谁言只可称象而得？换之等重之物亦可。",
	["$kenewchengxiang4"] = "称石以载至水痕，自可知象之斤重。",
	["$kenewchengxiang5"] = "若以冲所言行事，则此象之重可称也。",
	["$kenewchengxiang6"] = "以船载象，以石易象，称石则可得象斤重。",

	["$keceyin1"] = "施仁心，怜众生。",
	["$keceyin2"] = "我身虽小，亦有仁心。",
	["$keceyin3"] = "吾闻圣贤以仁治世，父亲，何不宽宥于人？",
	["$keceyin4"] = "人非圣贤，孰能无过？宽而宥之，其心亦睹。",
	["$keceyin5"] = "冲愿以此仁心消弭杀机，保将军周全。",
	["$keceyin6"] = " 阁下罪不至死，冲愿施以援手相救。",



	["~kenewcaochong"] = "这道题，冲儿解不出来！",




	--新曹叡
	["kenewcaorui"] = "新曹叡",
	["&kenewcaorui"] = "新曹叡",
	["#kenewcaorui"] = "童趣六一",
	["designer:kenewcaorui"] = "小珂酱",
	["cv:kenewcaorui"] = "官方",
	["illustrator:kenewcaorui"] = "官方",

	["kenewcaoruimjcg"] = "新曹叡",
	["&kenewcaoruimjcg"] = "新曹叡",
	["#kenewcaoruimjcg"] = "童趣六一",
	["designer:kenewcaoruimjcg"] = "小珂酱",
	["cv:kenewcaoruimjcg"] = "官方",
	["illustrator:kenewcaoruimjcg"] = "官方",


	["kenewcaoruichange"] = "可爱捏：选择皮肤",
	["kenewcaoruichange:yqmm"] = "月情满满",
	["kenewcaoruichange:mjcg"] = "明鉴朝纲",



	["kehuituo"] = "恢拓",
	["kehuituo-ask"] = "你可以选择发动“恢拓”的角色",
	[":kehuituo"] = "当你受到伤害后，你可以令一名角色进行判定，若结果为：红色，其回复1点体力；黑色，其摸X张牌（X为伤害值），然后若这名角色已受伤，你摸一张牌。",

	["kemingjian"] = "明鉴",
	["kemingjianex"] = "明鉴",
	["kemingjianCard"] = "明鉴",
	[":kemingjian"] = "<font color='green'><b>出牌阶段每种类型限一次，</b></font>你可以交给一名其他角色一张牌并摸一张牌，然后该角色选择一项：对除你外的角色使用此牌，或令本回合“明鉴”失效且你可以获得其一张牌。",

	["kexingshuai"] = "兴衰",
	[":kexingshuai"] = "<font color='#01A5AF'><s>主公技</s></font>，限定技，当你进入濒死状态时，你可以令其他<font color='#01A5AF'><s>魏势力</s></font>角色依次选择是否摸一张牌且令你回复1点体力。",

	["kemingjianCard_choice"] = "明鉴",
	["kemingjianCard_choice:huode"] = "【夺权】：获得其一张牌",
	["kemingjianCard_choice:no"] = "【宽恕】：取消",

	["kemingjianuse-ask"] = "你可以使用一张牌",

	["xingshuai_choice"] = "兴衰",
	["xingshuai_choice:huifu"] = "令其回复1点体力",
	["xingshuai_choice:no"] = "取消",


	["$kehuituo1"] = "大邦维屏，大宗维翰。",
	["$kehuituo2"] = "国之将兴，与民开拓。",
	["$kehuituo3"] = "百姓若得人间之福，朕何辞地狱之苦。",
	["$kehuituo4"] = "力拔高楼平地起，大庇英豪俱欢颜。",


	["$kemingjian1"] = "明辨鉴贤，汝为良士。",
	["$kemingjian2"] = "这一仗，还要仰望将军。",
	["$kemingjian3"] = "戡平六合，舍君其谁？",
	["$kemingjian4"] = "志士弼国，山河相付。",

	["$kexingshuai1"] = "大魏兴衰，望将军与我共进。",
	["$kexingshuai2"] = "国家兴衰存亡之危难，汝等岂可坐视不理？",
	["$kexingshuai3"] = "兴衰由人，人定胜天！",
	["$kexingshuai4"] = "国难当头，岂能坐视！",

	["~kenewcaorui"] = "曹魏霸业，谁可托付？",







	--新徐庶
	["kenewxushu"] = "新徐庶",
	["&kenewxushu"] = "新徐庶",
	["#kenewxushu"] = "侠之大者",
	["designer:kenewxushu"] = "小珂酱",
	["cv:kenewxushu"] = "官方",
	["illustrator:kenewxushu"] = "官方",

	["kexiajue"] = "侠决",
	[":kexiajue"] = "锁定技，出牌阶段开始时，你选择一名其他角色并进行三次判定直到你或该角色死亡，每当判定结果为：红色/黑色，你/其视为对其/你使用一张【杀】且你获得其中的黑色判定牌。因“侠决”使用的【杀】无视防具且不计入次数。",

	["kepingpiao"] = "萍飘",
	[":kepingpiao"] = "觉醒技，回合开始或结束时，若你的体力值为全场最少，你失去1点体力上限，回复1点体力并摸两张牌，然后获得技能“点阵”并将“侠决”的标签修改为“<font color='green'><b>出牌阶段限一次</b></font>”且你发动“侠决”时获得1点“护甲”。", --然后你可以令一名其他角色将武将牌更换为“界刘备”，该角色从各区域内、牌堆或弃牌堆中获得“的卢”和“雌雄双股剑”并使用之。",

	["kexiajuetwo"] = "侠决·升级",
	["kexiajuetwoCard"] = "侠决·升级",
	["xiajueskill"] = "侠决",
	[":kexiajuetwo"] = "出牌阶段限一次，你可以并选择一名其他角色并获得1点“护甲”，你进行三次判定直到你或该角色死亡，每当判定结果为：红色/黑色，你/其视为对其/你使用一张【杀】且你获得其中的黑色判定牌。因“侠决”使用的【杀】无视防具且不计入次数。",

	["kedianzhen"] = "点阵",
	["dianzhenspade"] = "点阵♠",
	["dianzhenclub"] = "点阵♣",
	["dianzhenheart"] = "点阵♥",
	["dianzhendiamond"] = "点阵♦",
	[":kedianzhen"] = "<font color='green'><b>准备阶段，</b></font>你可以弃置一名其他角色的一张牌，该角色不能使用、打出或响应与此牌花色相同的牌直到你下回合开始。",

	["kedianzhen-ask"] = "你可以发动“点阵”弃置一名其他角色的一张牌",
	["kepingpiao-ask"] = "你可以令一名角色获得并使用“的卢”",
	["kexiajue-ask"] = "请选择发动“侠决”的角色",

	["$kexushumsg"] = "<font color='yellow'><b>“点阵”</b></font>效果被触发，此牌不能被 %to 响应。",


	["$kexiajue1"] = "侠剑行义，诛灭恶贼！",
	["$kexiajue2"] = "行侠客之道，帮可帮之人。",
	["$kexiajue3"] = "一己之力，难救天下苍生！",
	["$kexiajue4"] = "诛暴讨逆，非一人之力可为！",
	["$kexiajue5"] = "双刃出鞘，诛恶方还！",
	["$kexiajue6"] = "心有不平，拔剑相向！",
	["$kexiajue7"] = "诛奸邪，除恶害！",
	["$kexiajue8"] = "天复无见，当诛是害！",
	["$kexiajue9"] = "今日，当要替天行道！",
	["$kexiajue10"] = "我容得你，天不容你！",
	["$kexiajue11"] = "纵剑为舞，击缶而歌！",
	["$kexiajue12"] = "辞亲历山野，仗剑唱大风！",

	["$kepingpiao1"] = "此卧龙先生，将军应亲自去请。",
	["$kepingpiao2"] = "洞察先机，知天地之运转。",
	["$kepingpiao3"] = "大军将至，望能早做准备！",
	["$kepingpiao4"] = "得此良臣，如有神助！",
	["$kepingpiao5"] = "此人之才，胜吾十倍！",
	["$kepingpiao6"] = "先生大才，请受此礼。",
	["$kepingpiao7"] = "如得此人，将军天下可图！",
	["$kepingpiao8"] = "妙计良策，闻于世也。",
	["$kepingpiao9"] = "吾有良策，退敌解围。",
	["$kepingpiao10"] = "依某之计，万无一失。",
	["$kepingpiao11"] = "天下兴亡，侠者当为之己任。",
	["$kepingpiao12"] = "隐居江湖之远，敢争天下之先！",

	["$kedianzhen1"] = "侠客可救数人，谋臣可救天下苍生！",
	["$kedianzhen2"] = "佐王论道，匡扶社稷！",
	["$kedianzhen3"] = "弃戈从学，以佐明主！",
	["$kedianzhen4"] = "摒除戾气，潜心向儒。",
	["$kedianzhen5"] = "弃剑执笔，修习韬略。",
	["$kedianzhen6"] = "休武兴文，专研筹划。",
	["$kedianzhen7"] = "修心成才，通文晓武。",
	["$kedianzhen8"] = "弃少年之意气，向儒以求解！",
	["$kedianzhen9"] = "愿凭所学，救民于水火。",
	["$kedianzhen10"] = "侠之大者，为国为民。",

	["~kenewxushu"] = "本欲助君，奈何忠孝不两全。",



	--新大乔
	["kenewdaqiao"] = "新大乔",
	["&kenewdaqiao"] = "新大乔",
	["#kenewdaqiao"] = "矜持之花",
	["designer:kenewdaqiao"] = "小珂酱",
	["cv:kenewdaqiao"] = "官方",
	["illustrator:kenewdaqiao"] = "官方",

	["keliuli"] = "流离",
	["keliuliqp"] = "流离：弃置此牌使用者的一张牌",
	["liulispsx"] = "流离",
	["keliuli-choice"] = "请选择弃置的牌",
	[":keliuli"] = "锁定技，每轮开始时，你随机与一名角色交换座次并摸X张牌且你本回合手牌上限+X（X为你与其座次的距离）；当你成为伤害类牌的目标后，若使用者体力值不小于你，你可以弃置其一张牌。",

	["keguose"] = "国色",
	[":keguose"] = "<font color='green'><b>出牌阶段各限一次，</b></font>你可以将一张♦牌当【乐不思蜀】对一名其他角色使用并令其下回合手牌上限-1；你可以弃置一名其他角色判定区内的所有牌并令其摸一张牌。",

	["$keliulilog"] = "%from 的<font color='yellow'><b>“流离”</b></font>效果被触发，与 %to 交换座次。",

	["$keliuli1"] = "此生逢伯符，足以慰平生。",
	["$keliuli2"] = "所幸遇郎君，流离得良人。",
	["$keliuli3"] = "吾夫君在此，汝胆敢如此放肆！",
	["$keliuli4"] = "邪佞诈妄之人，断无可容之处！",


	["$keguose1"] = "溪边坐流水，与君共清欢。",
	["$keguose2"] = "衣带逐水去，绿川盼君留。",


	["~kenewdaqiao"] = "忆君如流水，日夜无歇时。",



	--新郭淮
	["kenewguohuai"] = "新郭淮",
	["&kenewguohuai"] = "新郭淮",
	["#kenewguohuai"] = "垂问秦雍",
	["designer:kenewguohuai"] = "小珂酱",
	["cv:kenewguohuai"] = "官方",
	["illustrator:kenewguohuai"] = "官方",
	--[[
	["kejingce"] = "精策",
	[":kejingce"] = "当你/其他角色使用或打出牌响应其他角色/你使用的牌后，你的手牌上限+1直到你回合结束，然后你可以弃置其一张牌或摸一张牌，若此时为你的出牌阶段，你改为可以执行两项。",

	["kejingcepchose"] = "请选择弃置的牌",
	["kejingcechose"] = "你可以弃置其一张牌，或点击“取消”摸一张牌",
	["kejingcechosecp"] = "你可以弃置其一张牌并摸一张牌",
	["kejingcemp"] = "精策：摸一张牌",

	["keyuzhang"] = "御障",
	["keyuzhangex"] = "御障",
	[":keyuzhang"] = "锁定技，若你于一个回合内成为其他角色使用牌的目标的次数不小于你的体力值，你不能成为其他角色使用牌的目标。",
]]

	["kekaojun"] = "御障",
	["kekaojuntwo"] = "御障弃置",
	["kekaojunthree"] = "御障伤害牌",
	["kekaojunmp"] = "御障可摸牌",
	["kekaojun-ask"] = "你可以选择发动“御障”的角色",
	[":kekaojun"] = "<font color='green'><b>每轮结束时，</b></font>你可以选择至多X名角色（X为你本轮使用过牌的类型数），这些角色分别摸Y张牌（Y为其满足的条件数：已受伤、本轮于弃牌阶段外弃置过牌、本轮成为过一张伤害类牌的目标而未受到其造成的伤害）。",

	["keqinji"] = "寝疾",
	["@keqinji"] = "寝疾",
	[":keqinji"] = "锁定技，每当你受到伤害时，你摸一张牌并获得1枚“疾”标记，然后防止此伤害；你造成伤害后弃置1枚“疾”标记；回合结束时，你弃置所有“疾”标记并失去等量的体力。",

	["kaojunshanghai"] = "御障伤害",
	["kekaojunchose"] = "你可以选择发动“御障”的角色",
	["kekaojun-distribute"] = "你可以分配这些牌",

	["$usekekaojun"] = "%from 发动了技能<font color='yellow'><b>“御障”</s></font>",
	--[[
	["$kejingce1"] = "精细入微，策敌制胜。",
	["$kejingce2"] = "妙策如神，精兵强将，安有不胜之理？",
	["$kejingce3"] = "夺敌所爱，抢占要敌！",
	["$kejingce4"] = "上将之道，料敌制胜！",
	["$kejingce5"] = "吾已料敌布防，蜀军休想进犯。",
	["$kejingce6"] = "诸君依策行事，定保魏境无虞。",
	["$kejingce7"] = "方策精详，有备无患。",
	["$kejingce8"] = "精兵据敌，策守如山。",
]]
	["$kekaojun1"] = "精细入微，策敌制胜。",
	["$kekaojun2"] = "妙策如神，精兵强将，安有不胜之理？",
	["$kekaojun3"] = "夺敌所爱，抢占要敌！",
	["$kekaojun4"] = "上将之道，料敌制胜！",
	["$kekaojun5"] = "吾已料敌布防，蜀军休想进犯。",
	["$kekaojun6"] = "诸君依策行事，定保魏境无虞。",
	["$kekaojun7"] = "方策精详，有备无患。",
	["$kekaojun8"] = "精兵据敌，策守如山。",

	["$keqinji1"] = "穷寇莫追...",
	["$keqinji2"] = "岂料姜维空手接箭。",
	["$keqinji3"] = "姜维小儿，竟然...",
	["$keqinji4"] = "是我轻敌了...",

	["~kenewguohuai"] = "岂料姜维空手接箭。",


	--新王基
	["kenewwangji"] = "新王基",
	["&kenewwangji"] = "新王基",
	["#kenewwangji"] = "经行合一",
	["designer:kenewwangji"] = "小珂酱",
	["cv:kenewwangji"] = "官方",
	["illustrator:kenewwangji"] = "官方",

	["kenewqizhi"] = "奇制",
	["keqizhiallnum"] = "奇制",
	["qianghuakeqizhi"] = "强化奇制",
	["@keqizhi"] = "奇制",
	["kenewqizhi:norecoverother"] = "你可以令该角色回复1点体力",
	["kenewqizhi:norecoverself"] = "你可以回复1点体力",
	["kenewqizhi:nomopaiself"] = "你可以摸一张牌",
	["kenewqizhi:nomopaiother"] = "你可以令其摸一张牌",
	["beueskeqizhi"] = "奇制",
	["qizhitishi"] = "提示：点击“取消”执行选项2",
	["qizhi-invoke"] = "你可以选择发动“奇制”的角色",
	["kenewqizhi:qipai"] = "弃置其一张牌，然后其摸一张牌",
	["kenewqizhi:shanghai"] = "对其造成1点伤害，然后其回复1点体力",
	--[[
	[":kenewqizhi"] = "每当你使用基本牌或锦囊牌指定目标后，你可以选择一项：1.弃置不是此牌目标的一名角色区域内的一张牌，然后<font color='#0099CC'><b>你令</b></font>其摸一张牌。2.对不是此牌目标的一名角色造成1点伤害，然后<font color='#0099CC'><b>你令</b></font>其回复1点体力。",
	[":kenewqizhiqh"] = "每当你使用基本牌或锦囊牌指定目标后，你可以选择一项：1.弃置不是此牌目标的一名角色区域内的一张牌，然后<font color='#0099CC'><b>你可以令</b></font>其摸一张牌。2.对不是此牌目标的一名角色造成1点伤害，然后<font color='#0099CC'><b>你可以令</b></font>其回复1点体力。",
	[":kenewqizhiback"] = "每当你使用基本牌或锦囊牌指定目标后，你可以选择一项：1.弃置不是此牌目标的一名角色区域内的一张牌，然后<font color='#0099CC'><b>你令</b></font>其摸一张牌。2.对不是此牌目标的一名角色造成1点伤害，然后<font color='#0099CC'><b>你令</b></font>其回复1点体力。",
	
]]
	[":kenewqizhi"] = "每当你使用基本牌或锦囊牌指定目标后，你可以选择一项：1.弃置不是此牌目标的一名角色区域内的一张牌，然后其摸一张牌；2.对不是此牌目标的一名角色造成1点伤害，然后其回复1点体力。",
	[":kenewqizhiqh"] = "每当你使用基本牌或锦囊牌指定目标后，你可以选择一项：1.弃置<font color='#01A5AF'><s>不是此牌目标的</s></font>一名角色区域内的一张牌，然后<font color='#0099CC'><b>你可以令</b></font>其摸一张牌；2.对<font color='#01A5AF'><s>不是此牌目标的</s></font>一名角色造成1点伤害，然后其回复1点体力。",
	[":kenewqizhiback"] = "每当你使用基本牌或锦囊牌指定目标后，你可以选择一项：1.弃置不是此牌目标的一名角色区域内的一张牌，然后其摸一张牌；2.对不是此牌目标的一名角色造成1点伤害，然后其回复1点体力。",

	["kenewjinqu"] = "进趋",
	["kenewjinqu:zero"] = "不摸牌",
	["kenewjinqu:one"] = "摸一张牌",
	["kenewjinqu:two"] = "摸两张牌",

	["kenewjinqu:huifu"] = "回复1点体力",
	["kenewjinqu:mopai"] = "摸两张牌",
	[":kenewjinqu"] = "每当你第三次发动“奇制”时可以选择任意一名角色，以及是否执行“其摸一张牌”。<font color='green'><b>结束阶段，</s></font>你摸X张牌（X为你本回合发动“奇制”的次数且至多为2）。",


	["$kenewqizhi1"] = "声东击西，敌寇一网成擒。",
	["$kenewqizhi2"] = "吾意不在此地，已遣别部出发。",
	["$kenewqizhi3"] = "兵动而无功，威名折于外。",
	["$kenewqizhi4"] = "虽积兵江内，无必渡之势。",
	["$kenewqizhi5"] = "迂回袭敌，击其薄弱。",
	["$kenewqizhi6"] = "战机稍纵即逝，岂能枯等军令？",
	["$kenewqizhi7"] = "将贵专谋，兵以奇胜。",
	["$kenewqizhi8"] = "奇正变通，虚实惑敌。",
	["$kenewqizhi9"] = "奇兵百出，敌军自溃。",
	["$kenewqizhi10"] = "用兵，当以奇为先。",
	["$kenewqizhi11"] = "斗奇而争，以妙取胜。",
	["$kenewqizhi12"] = "用计奇略，制敌服心。",

	["$kenewjinqu1"] = "建上昶水城，以逼夏口。",
	["$kenewjinqu2"] = "通川聚粮，伐吴之业，当步步为营。",
	["$kenewjinqu3"] = "和远在身，定众在心。",
	["$kenewjinqu4"] = "亲用忠良，远近协服。",
	["$kenewjinqu5"] = "先为不可胜，以待敌之可胜。",
	["$kenewjinqu6"] = "以蚕食之计，吞顽抗之敌。",
	["$kenewjinqu7"] = "意欲伐吴，必有水战之备。",
	["$kenewjinqu8"] = "先人有夺人之心，此平贼之要。",
	["$kenewjinqu9"] = "此时不战，更待何时？",
	["$kenewjinqu10"] = "万不可贻误战机！",
	["$kenewjinqu11"] = "拒天诛者意沮，而向王化者益固。",
	["$kenewjinqu12"] = "志正则众邪不生，心静则众事不躁。",
	["$kenewjinqu13"] = "（强化奇制）",

	["~kenewwangji"] = "天下之势，必归大魏。可恨，未能得见哪！",



	--新孙鲁育
	["kenewsunluyu"] = "新孙鲁育",
	["&kenewsunluyu"] = "新孙鲁育",
	["#kenewsunluyu"] = "童趣六一",
	["designer:kenewsunluyu"] = "小珂酱&CG",
	["cv:kenewsunluyu"] = "官方",
	["illustrator:kenewsunluyu"] = "官方",

	["keraoxi"] = "扰息",
	--[":keraoxi"] = "其他角色的回合开始时，若你在其攻击范围内，你可以弃置X张牌并选择一项：1.跳过摸牌阶段，在出牌阶段结束时执行一个摸牌阶段；2.跳过出牌阶段，在弃牌阶段结束时执行一个出牌阶段。（X为此前你本轮发动过“扰息”的次数）\
	--<font color='red'><b>若对应阶段已经被跳过，则不会再执行之</b></font>",

	[":keraoxi"] = "其他角色的回合开始时，若你在其攻击范围内，你可以弃置X张牌并选择一项：1.交换其摸牌阶段和出牌阶段的次序；2.交换其出牌阶段和弃牌阶段的次序。（X为此前你本轮发动过“扰息”的次数）",

	["raoximp"] = "扰息出摸弃",
	["raoxicp"] = "扰息摸弃出",
	["raoxi-ask"] = "你可以弃置 %dest 张牌对 %src 发动“扰息”",

	["$raoximc"] = "%to 将交换 <font color='yellow'><b>摸牌阶段</b></font> 和 <font color='yellow'><b>出牌阶段</b></font>",
	["$raoxicq"] = "%to 将交换 <font color='yellow'><b>出牌阶段</b></font> 和 <font color='yellow'><b>弃牌阶段</b></font>",

	["kemumu"] = "穆穆",
	[":kemumu"] = "出牌阶段限一次，你可以弃置一名角色区域内的一张牌，然后你摸X张牌（X为其手牌区和装备区未空置的数量）。",


	["keraoxi:skipmp"] = "令其：出牌->摸牌->弃牌",
	["keraoxi:skipcp"] = "令其：摸牌->弃牌->出牌",


	["$keraoxi1"] = "看在我的份上，请你收手吧。",
	["$keraoxi2"] = "愿一切纷争就此终止。",
	["$keraoxi3"] = "喜乐安康，吾之所愿。",
	["$keraoxi4"] = "纷乱争斗，不是我想见到的。",
	["$keraoxi5"] = "姐妹之情，当真今日了断？",
	["$keraoxi6"] = "上下和睦，姐妹同心。",
	["$keraoxi7"] = "储位争斗，与后宫有何瓜葛？",
	["$keraoxi8"] = "权斗崇魅,需及时止损。",

	["$kemumu1"] = "淡然处之，不问国事。",
	["$kemumu2"] = "姐姐，这不是我们应该管的事。",
	["$kemumu3"] = "姐姐，此事不可参与啊！",
	["$kemumu4"] = "国事政论，我们不便多言。",
	["$kemumu5"] = "素性贞淑，穆穆春山。",
	["$kemumu6"] = "雍穆融治，吾之所愿。",
	["$kemumu7"] = "姐妹敦睦，家国和睦。",
	["$kemumu8"] = "慕清兴荣，太平祥和。",

	["~kenewsunluyu"] = "姐姐，我们回不到从前了。",



	--新张星彩
	["kenewzhangxingcai"] = "新张星彩",
	["&kenewzhangxingcai"] = "新张星彩",
	["#kenewzhangxingcai"] = "童趣六一",
	["designer:kenewzhangxingcai"] = "小珂酱",
	["cv:kenewzhangxingcai"] = "官方",
	["illustrator:kenewzhangxingcai"] = "官方",
	--猪年中秋34
	["kenewzhangxingcaiznzq"] = "新张星彩",
	["&kenewzhangxingcaiznzq"] = "新张星彩",
	["#kenewzhangxingcaiznzq"] = "童趣六一",
	["designer:kenewzhangxingcaiznzq"] = "小珂酱",
	["cv:kenewzhangxingcaiznzq"] = "官方",
	["illustrator:kenewzhangxingcaiznzq"] = "官方",
	--父志耀星56
	["kenewzhangxingcaifzyx"] = "新张星彩",
	["&kenewzhangxingcaifzyx"] = "新张星彩",
	["#kenewzhangxingcaifzyx"] = "童趣六一",
	["designer:kenewzhangxingcaifzyx"] = "小珂酱",
	["cv:kenewzhangxingcaifzyx"] = "官方",
	["illustrator:kenewzhangxingcaifzyx"] = "官方",
	--巾帼花武78
	["kenewzhangxingcaijghw"] = "新张星彩",
	["&kenewzhangxingcaijghw"] = "新张星彩",
	["#kenewzhangxingcaijghw"] = "童趣六一",
	["designer:kenewzhangxingcaijghw"] = "小珂酱",
	["cv:kenewzhangxingcaijghw"] = "官方",
	["illustrator:kenewzhangxingcaijghw"] = "官方",
	--金枝玉叶910
	["kenewzhangxingcaijzyy"] = "新张星彩",
	["&kenewzhangxingcaijzyy"] = "新张星彩",
	["#kenewzhangxingcaijzyy"] = "童趣六一",
	["designer:kenewzhangxingcaijzyy"] = "小珂酱",
	["cv:kenewzhangxingcaijzyy"] = "官方",
	["illustrator:kenewzhangxingcaijzyy"] = "官方",

	["kenewzhangxingcaichange"] = "可爱捏：选择皮肤",
	["kenewzhangxingcaichange:xchf"] = "星春侯福",
	["kenewzhangxingcaichange:znzq"] = "猪年中秋",
	["kenewzhangxingcaichange:fzyx"] = "父志耀星",
	["kenewzhangxingcaichange:jghw"] = "巾帼花武",
	["kenewzhangxingcaichange:jzyy"] = "金枝玉叶",


	["kexianjie"] = "贤节",
	["kexianjiecs"] = "贤节杀",
	[":kexianjie"] = "每个回合限一次，当一名角色使用的【杀】或伤害类普通锦囊牌结算完毕后，若此牌没有造成伤害，你可以令该角色获得之，若如此做，你使用【杀】的次数限制+1直到你的回合结束。",

	["keqiangwu"] = "枪舞",
	[":keqiangwu"] = "出牌阶段限一次，你可以摸一张牌并进行判定，若如此做，当你本阶段使用牌时，若此牌与该判定牌：\
	○类型相同：你摸一张牌；（限两次）\
	○花色相同：你可以令一名其他角色弃置一种花色的所有牌；\
	○点数相同，你可以对一名其他角色造成1点伤害。",
	["keqiangwuda-ask"] = "你可以发动“枪舞”对一名其他角色造成1点伤害",

	["qiangwusuitchoice"] = "请选择弃置的花色",
	["qiangwusuitchoice:spade"] = "弃置所有 ♠ 牌",
	["qiangwusuitchoice:club"] = "弃置所有 ♣ 牌",
	["qiangwusuitchoice:heart"] = "弃置所有 ♥ 牌",
	["qiangwusuitchoice:diamond"] = "弃置所有 ♦ 牌",
	["qiangwusuitchoice:cancel"] = "取消",


	["keqiangwuqphht-ask"] = "你可以发动“枪舞”令一名其他角色弃置一种花色的所有牌",
	["keqiangwuqpht-ask"] = "你可以发动“枪舞”令一名其他角色弃置一种花色的所有牌",
	["keqiangwuqpmh-ask"] = "你可以发动“枪舞”令一名其他角色弃置一种花色的所有牌",
	["keqiangwuqpfp-ask"] = "你可以发动“枪舞”令一名其他角色弃置一种花色的所有牌",
	--[[
	["keqiangwuqphht-ask"] = "你可以发动“枪舞”令一名其他角色弃置所有 ♠ 牌",
	["keqiangwuqpht-ask"] = "你可以发动“枪舞”令一名其他角色弃置所有 ♥ 牌",
	["keqiangwuqpmh-ask"] = "你可以发动“枪舞”令一名其他角色弃置所有 ♣ 牌",
	["keqiangwuqpfp-ask"] = "你可以发动“枪舞”令一名其他角色弃置所有 ♦ 牌",]]

	["kexianjie:kexianjie-ask"] = "你可以发动“贤节”令 %src 获得该【%dest】",

	["$kexianjie1"] = "助君再兴大业，乃臣妾之本。",
	["$kexianjie2"] = "国力如此，妾身惟愿重振朝纲。",
	["$kexianjie3"] = "母亲教我的，我都明白了。",
	["$kexianjie4"] = "要做一个知书达理的好孩子，呵。",
	["$kexianjie5"] = "夫君无断，妾身亲为！",
	["$kexianjie6"] = "助君大业，立德唯心。",
	["$kexianjie7"] = "淑德贤惠，良才兼备。",
	["$kexianjie8"] = "贤能清雅，常备不懈。",
	["$kexianjie9"] = "国事不定，妾身定再战沙场！",
	["$kexianjie10"] = "武艺万千，仪态贤淑。",

	["$keqiangwu1"] = "披肝沥胆，枪舞迎花。",
	["$keqiangwu2"] = "长坂英魂犹在，提枪誓退逆贼！",
	["$keqiangwu3"] = "父亲教我的武艺，你们看如何啊。",
	["$keqiangwu4"] = "父亲，我练习的怎么样呀？",
	["$keqiangwu5"] = "国仇家恨，今日一并算清！",
	["$keqiangwu6"] = "卫境捍土，凭我长枪！",
	["$keqiangwu7"] = "挥枪平乱世，彩心战九霄！",
	["$keqiangwu8"] = "溢彩耀星，枪出花海！",
	["$keqiangwu9"] = "承父志向，战场除敌！",
	["$keqiangwu10"] = "枪舞花飞，斩敌无踪！",

	["~kenewzhangxingcai"] = "荡平乱世，终非一日之功。",


	--新孙休
	["kenewsunxiu"] = "新孙休",
	["&kenewsunxiu"] = "新孙休",
	["#kenewsunxiu"] = "君临即位",
	["designer:kenewsunxiu"] = "小珂酱",
	["cv:kenewsunxiu"] = "官方",
	["illustrator:kenewsunxiu"] = "官方",

	["keyanzhu"] = "宴诛",
	["keyanzhuCard"] = "宴诛",
	[":keyanzhu"] = "出牌阶段限一次，你可以选择至多X名角色（X为你已损失的体力值且至少为1），这些角色各摸一张牌，然后你分别选择一项：1.获得其一张牌；2.对其造成1点伤害，若此伤害使其进入了濒死状态，你移除此选项并修改“兴学”（“体力值”改为“体力上限”）。",
	[":keyanzhutwo"] = "出牌阶段限一次，你可以选择至多X名角色（X为你已损失的体力值且至少为1），这些角色各摸一张牌，然后你分别获得其一张牌。",

	["kezhaofu"] = "诏缚",
	[":kezhaofu"] = "<font color='#01A5AF'><s>主公技</s></font>，限定技，出牌阶段，你可以选择一名其他角色，若如此做，其余所有<font color='#01A5AF'><s>吴势力</s></font>角色可以选择是否对其使用一张【杀】（无距离限制），当此【杀】造成伤害后，伤害来源获得其一张牌且你回复1点体力。",
	["zhaofu-ask"] = "你可以对 %src 使用一张【杀】",

	["kexingxue"] = "兴学",
	[":kexingxue"] = "<font color='green'><b>结束阶段，</s></font>你可以令不超过你体力值数量的角色各摸X张牌然后弃置一张牌（X为其手牌中缺少的花色数且至少为1）。",
	[":kexingxuetwo"] = "<font color='green'><b>结束阶段，</s></font>你可以令不超过你<b>体力上限</b>数量的角色各摸X张牌然后弃置一张牌（X为其手牌中缺少的花色数且至少为1）。",
	["$usekexingxue"] = "%from 发动了技能<font color='yellow'><b>“兴学”</s></font>，目标是 %to ",

	["keyanzhutishi"] = "提示：点击“取消”执行选项2",
	["kexingxue-ask"] = "你可以选择发动“兴学”的角色",
	["kexingxue-discard"] = "兴学：请弃置一张牌",

	["$keyanzhu1"] = "既来之，你何不安之？",
	["$keyanzhu2"] = "喝完这一杯，就动手吧！",
	["$keyanzhu3"] = "设宴安其心，怀策毙其命。",
	["$keyanzhu4"] = "推杯换盏之际，正是诛灭逆臣之时！",

	["$kezhaofu1"] = "宣至尊之旨，命忠勇之士，讨叛逆之贼！",
	["$kezhaofu2"] = "书天子之诏，筹宴请之谋，缚乱政之臣！",
	["$kezhaofu3"] = "天兵已至，逆贼休得猖狂！",
	["$kezhaofu4"] = "卫士何在，给朕拿下此人！",

	["$kexingxue1"] = "才子之乡，怎可就此荒废？",
	["$kexingxue2"] = "兴学重教，人为根本。",
	["$kexingxue3"] = "息战事，明文教，兴仁政之道。",
	["$kexingxue4"] = "兴王道之教化，学厚积而薄发。",

	["~kenewsunxiu"] = "外有强贼，内有权臣，这皇帝还怎么当！",


	--新曹仁
	["kenewcaoren"] = "新曹仁",
	["&kenewcaoren"] = "新曹仁",
	["#kenewcaoren"] = "大魏壁垒",
	["designer:kenewcaoren"] = "小珂酱",
	["cv:kenewcaoren"] = "官方",
	["illustrator:kenewcaoren"] = "官方",

	["keyugong"] = "御攻",
	["keyugongCard"] = "御攻",
	[":keyugong"] = "转换技，出牌阶段限一次，你可以\
	①弃置一张非伤害类牌并从牌堆获得两张伤害类牌，然后你本回合可以多使用一张【杀】；\
	②弃置一张伤害类牌并从牌堆获得两张非伤害类牌，然后你获得1点“护甲”且本回合手牌上限+1。",
	[":keyugong1"] = "转换技，出牌阶段限一次，你可以\
	①弃置一张非伤害类牌并从牌堆获得两张伤害类牌，然后你本回合可以多使用一张【杀】；\
	<font color='#01A5AF'><s>②弃置一张伤害类牌并从牌堆获得两张非伤害类牌，然后你获得1点“护甲”且本回合手牌上限+1。</s></font>",
	[":keyugong2"] = "转换技，出牌阶段限一次，你可以\
	<font color='#01A5AF'><s>①弃置一张非伤害类牌并从牌堆获得两张伤害类牌，然后你本回合可以多使用一张【杀】；</s></font>\
	②弃置一张伤害类牌并从牌堆获得两张非伤害类牌，然后你获得1点“护甲”且本回合手牌上限+1。",

	["keyanzheng"] = "严整",
	[":keyanzheng"] = "在一张锦囊牌对你生效前，你可以将一张牌当【无懈可击】使用。",

	["keyugongslashcishu"] = "御攻杀",
	["keyugongmax"] = "御攻手牌上限",
	--[[
	["$keyugong1"] = "坚持住，援兵即刻就到。",
	["$keyugong2"] = "困局即刻得解，稍安勿躁。",
	["$keyugong3"] = "尔等莫慌，吾来也！",
	["$keyugong4"] = "上马，出城！",
	["$keyugong5"] = "以不变应万变。",
	["$keyugong6"] = "吾自有办法！",
	["$keyugong7"] = "吾等守城，无人可破！",
	["$keyugong8"] = "守城是我长项，哈哈哈哈！",

	["~kenewcaoren"] = "命中如此啊。",
]]
	["$keyugong1"] = "骑兵列队，准备突围！",
	["$keyugong2"] = "修整片刻，且随我杀出一条血路。",

	["$keyanzheng1"] = "敌军围困万千重，我自岿然不动。",
	["$keyanzheng2"] = "行伍严整，百战不殆！",

	["~kenewcaoren"] = "城在人在，城破人亡。",


	--新邓艾
	["kenewdengai"] = "新邓艾",
	["&kenewdengai"] = "新邓艾",
	["#kenewdengai"] = "摧山凿险",
	["designer:kenewdengai"] = "小珂酱",
	["cv:kenewdengai"] = "官方",
	["illustrator:kenewdengai"] = "官方",

	["kepihuang"] = "辟荒",
	["kepihuangex"] = "凿险",
	["kepihuang:bozhong"] = "[播种]",
	["kepihuang:fengshou"] = "[丰收]",
	["kepihuangex:bozhong"] = "切换为[播种]",
	["kepihuangex:fengshou"] = "切换为[丰收]",
	[":kepihuang"] = "<font color='green'><b>准备阶段，</s></font>你选择一项：\
	<font color='#3366FF'><b>[播种]</b></font>获得1枚“田”标记，直到下个准备阶段，你使用装备牌或失去红色基本牌时获得1枚“田”标记（至多5枚）；\
	<font color='#3366FF'><b>[丰收]</b></font>摸一张牌，直到下个准备阶段，你使用黑色非装备牌时弃置1枚“田”标记。",
	--<font color='green'><b>每轮结束时，</s></font>你将手牌摸至X张（X为“田”标记的数量）。",

	["kezaoxian"] = "凿险",
	["kezaoxian:recover"] = "回复1点体力",
	["kezaoxian:draw"] = "摸两张牌",
	[":kezaoxian"] = "觉醒技，<font color='green'><b>回合开始时，</s></font>若你有至少5枚“田”标记，你减1点体力上限并获得“逐远”。",

	["kezhuxian"] = "逐远",
	["kezhuxianget-ask"] = "你可以发动“逐远”获得一名其他角色的一张牌",
	[":kezhuxian"] = "每当你获得/失去1枚“田”标记后，你可以摸一张牌/获得一名其他角色的一张牌。",


	["ketian"] = "田",
	["keppihuangbozhong"] = "辟荒:播种",
	["keppihuangfengshou"] = "辟荒:丰收",

	["$kepihuang1"] = "积蓄粮草，准备应战。",
	["$kepihuang2"] = "兵精粮足，决胜千里。",
	["$kepihuang3"] = "战者，粮草为先。",
	["$kepihuang4"] = "静待时机，一鸣惊人。",
	["$kepihuang5"] = "文为事范，行为事则",
	["$kepihuang6"] = "兴修水利，垦辟荒野，军民并丰，乃国之大事矣。",

	["$kezaoxian1"] = "险路已过，全力冲锋！",
	["$kezaoxian2"] = "不入虎穴，焉得虎子？",
	["$kezaoxian3"] = "事在人为，天险又如何？",
	["$kezaoxian4"] = "就势取利，扭转乾坤！",
	["$kezaoxian5"] = "克服山险，奇袭敌后！",
	["$kezaoxian6"] = "瞒天过海，乘虚而入。",

	["$kezhuxian1"] = "敌军败象已露，冲啊！",
	["$kezhuxian2"] = "千里奔袭，毕其功于一役！",
	["$kezhuxian3"] = "以快打慢，袭敌不备。",
	["$kezhuxian4"] = "时机一到，先发制人！",
	["$kezhuxian5"] = "轻甲疾行，随我破敌！",
	["$kezhuxian6"] = "神兵突现，防不胜防。",

	["~kenewdengai"] = "何故杀我？",




	--新姜维
	["kenewjiangwei"] = "新姜维",
	["&kenewjiangwei"] = "新姜维",
	["#kenewjiangwei"] = "大志不渝",
	["designer:kenewjiangwei"] = "小珂酱",
	["cv:kenewjiangwei"] = "官方",
	["illustrator:kenewjiangwei"] = "官方",

	["ketiaoxin"] = "挑衅",
	[":ketiaoxin"] = "出牌阶段限一次，你可以弃置一名其他角色区域内的一张牌，然后其选择一项：1.令你摸一张牌；2.对你使用一张【杀】（无距离限制），若此【杀】没有造成伤害，你可以对其重复此流程。",

	["ketiaoxin-slash"] = "你可以对其使用一张【杀】（点击“取消”令其摸一张牌）",
	["ketiaoxinjixu-ask"] = "你可以对其继续发动“挑衅”",

	["kezhiji"] = "志继",
	["kezhiji:recover"] = "回复1点体力",
	["kezhiji:draw"] = "摸两张牌",
	["kezhijiex"] = "志继八卦阵",
	[":kezhiji"] = "觉醒技，回合开始时，若你的手牌数不大于1，你减1点体力上限，回复1点体力或摸两张牌，然后获得技能“窥天”且你发动“挑衅”时视为装备“八卦阵”。",

	["kejwkuitian"] = "窥天",
	["kejwkuitian:fromup"] = "令其从牌堆顶摸牌",
	["kejwkuitian:fromass"] = "令其从牌堆底摸牌",
	[":kejwkuitian"] = "<font color='green'><b>准备阶段，</s></font>你可以观看一名其他角色的所有手牌与牌堆顶的X张牌（X为你所在阵营存活角色数）并将这些牌以任意顺序置于牌堆顶或牌堆底，然后令其从牌堆的一侧摸等同于其此前手牌数的牌。",
	["kejwkuitian-ask"] = "请选择发动“窥天”的角色",


	["$ketiaoxin1"] = "既知我师尊大名，又如何敢与我对阵？",
	["$ketiaoxin2"] = "来者可是缩头将军？",
	["$ketiaoxin3"] = "你也不过是个贪生怕死之辈。",
	["$ketiaoxin4"] = "我谅你也不敢出来迎战。",
	["$ketiaoxin5"] = "我的儿，莫非被吓破了胆？",
	["$ketiaoxin6"] = "英雄，就不该缩头缩脑。",

	["$kezhiji1"] = "恩师遗志，维没齿难忘。",
	["$kezhiji2"] = "丞相未竟之业，就是我此生夙愿。",
	["$kezhiji3"] = "丞相传我此等阵法，坚守不破！",
	["$kezhiji4"] = "武侯八阵，铭记于心！",
	["$kezhiji5"] = "你也敢在我面前用计？",
	["$kezhiji6"] = "班门弄斧，愚蠢之至！",
	["$kezhiji7"] = "思虑周备，万无一失！",
	["$kezhiji8"] = "看我将计就计！",


	["$kejwkuitian1"] = "复我汉统，此志不渝！",
	["$kejwkuitian2"] = "大汉之光微微，我也要尽力而为！",
	["$kejwkuitian3"] = "大汉之安危，皆在此一举！",
	["$kejwkuitian4"] = "北伐大计，不可废也！",



	["~kenewjiangwei"] = "大厦将倾，维独木难支......",



	--新刘备
	["kenewliubei"] = "新刘备",
	["&kenewliubei"] = "新刘备",
	["#kenewliubei"] = "桑荫之志",
	["designer:kenewliubei"] = "小珂酱",
	["cv:kenewliubei"] = "竹风衾",
	["illustrator:kenewliubei"] = "官方",

	["kenewgonghuan"] = "共患",
	[":kenewgonghuan"] = "当其他角色成为【杀】或伤害类普通锦囊牌的唯一目标时，若你在使用者的攻击范围内，你可以成为此牌的额外目标并优先结算，若此牌没有对你造成伤害，你获得使用者的一张牌，否则此牌对该角色无效且你令其回复1点体力或摸两张牌，本轮你不能再对其发动“共患”。",
	["kenewgonghuan:recover"] = "令其回复1点体力",
	["kenewgonghuan:mopai"] = "令其摸两张牌",

	["kenewsangzhi"] = "桑志",
	[":kenewsangzhi"] = "<font color='green'><b>每名角色限一次，</s></font>出牌阶段，你可以将手牌摸至或将体力回复至与一名其他角色相同；<font color='green'><b>出牌阶段开始时，</s></font>若其他角色均被以此法选择过，你获得1枚“草鞋”标记。",
	["kenewsangzhi:tili"] = "将体力回复至与其相同",
	["kenewsangzhi:shoupai"] = "将手牌摸至与其相同",


	--杂货铺
	["kenewzahuo"] = "织履",
	["@kecaoxie"] = "草鞋",
	[":kenewzahuo"] = "每当你受到或造成1点伤害后，你获得1枚“草鞋”标记（至多10枚）；出牌阶段限一次，你可以<font color='#996600'><b><i>出售“草鞋”标记，</i></b></font>并从牌堆获得对应牌或执行对应效果。",
	["$keliubeibuy"] = "交易愉快，欢迎客官下次光临！",
	["$keliubeinomoney"] = "臭小子，没钱来这找打吗？",
	["$keliubeinogood"] = "本店没货了。",


	["goodsclass"] = "选择商品类别",
	["goodsclass:basiccard"] = "-$基本牌$-",
	["goodsclass:equip"] = "-$装备牌$-",
	["goodsclass:effect"] = "-$特殊效果$-",

	["liubeijibenpai"] = "选择基本牌",
	["liubeijibenpai:slash"] = "-$ 杀 $-——3双",
	["liubeijibenpai:jink"] = "-$ 闪 $-——3双",
	["liubeijibenpai:wine"] = "-$ 酒 $-——5双",
	["liubeijibenpai:peach"] = "-$ 桃 $-——5双",

	["liubeizhuangbei"] = "选择装备牌",
	["liubeizhuangbei:weapon"] = "-$ 武器牌 $-——4双",
	["liubeizhuangbei:armor"] = "-$ 防具牌 $-——4双",
	["liubeizhuangbei:addone"] = "-$ 防御坐骑 $-——4双",
	["liubeizhuangbei:minusone"] = "-$ 进攻坐骑 $-——4双",

	["liubeitexiao"] = "选择特殊效果",
	["liubeitexiao:addslash"] = "-$ 【杀】次数限制永久+1 $-——4双",
	["liubeitexiao:judge"] = "-$ 废除判定区 $-——3双",
	["liubeitexiao:maxhand"] = "-$ 手牌上限永久+1 $-——3双",
	["liubeitexiao:msg"] = "-$ 打探消息 $-——1双",
	["liubeimsg-ask"] = "请选择观看手牌的角色",

	["$kenewgonghuan1"] = "若有得罪之处，冲我来便是。",
	["$kenewgonghuan2"] = "君若蒙难，备自与君同赴。",

	["$kenewsangzhi1"] = "苍天朗朗，草木葱葱！",
	["$kenewsangzhi2"] = "日后，我定当乘此羽盖车。",

	["$kenewzahuo1"] = "（尴尬而不失礼貌地笑）",
	["$kenewzahuo2"] = "这可是涿县最好的草鞋！",
	["$kenewzahuo3"] = "着我此鞋，跋山涉水亦如履平地！",


	["~kenewliubei"] = "只恨韶华匆匆，少年仍有一梦。",



	--新孙权
	["kenewsunquan"] = "新孙权",
	["&kenewsunquan"] = "新孙权",
	["#kenewsunquan"] = "年轻的贤君",
	["designer:kenewsunquan"] = "小珂酱",
	["cv:kenewsunquan"] = "官方",
	["illustrator:kenewsunquan"] = "官方",

	["kechazheng"] = "察政",
	[":kechazheng"] = "出牌阶段限一次，你可以弃置任意数量的牌并令一名其他角色随机展示等量的手牌。",

	["kezhiheng"] = "制衡",
	[":kezhiheng"] = "每个回合限一次，当你的牌被弃置后，你可以选择一项：\
	1.摸等量的牌；\
	2.摸等量的牌，然后摸一张牌，本轮“制衡”失效。",

	["kezhiheng:xiaomo"] = "摸等量的牌",
	["kezhiheng:damo"] = "摸等量+1张牌，“制衡”本轮失效",
	["$kezhihenglog"] = "%from 发动了<font color='yellow'><b>“制衡”</s></font>",
	["$kezhihenglogtwo"] = "%from 发动了<font color='yellow'><b>“制衡”</s></font>，本轮<font color='yellow'><b>“制衡”</s></font>失效",
	["banturnkezhiheng"] = "已使用制衡",
	["kezhihengfail"] = "“制衡”失效",

	["kejiuyuan"] = "救援",
	[":kejiuyuan"] = "<font color='#01A5AF'><s>主公技</s></font>，锁定技，当你/其他<font color='#01A5AF'><s>吴势力</s></font>角色使用【桃】指定其他<font color='#01A5AF'><s>吴势力</s></font>角色/你为唯一目标时，你与其各摸一张牌且此牌的回复值+1。",

	["$kezhiheng1"] = "群雄环伺，而地势匡佑，先通江海而后率三军。",
	["$kezhiheng2"] = "人心相异，而天道有常，经纬之道在御而非攻。",
	["$kezhiheng3"] = "制衡之道，惟舍而得之。",
	["$kezhiheng4"] = "君可制衡，则国祚延绵。",
	["$kezhiheng5"] = "不偏不倚，制而取衡。",
	["$kezhiheng6"] = "治国之策，无外乎民皆有所得。",

	["$kejiuyuan1"] = "诸君皆为股肱，岂可视而不管？",
	["$kejiuyuan2"] = "子民遇难者，当救援之。",
	["$kejiuyuan3"] = "若有失救援，余心怏怏不安。",
	["$kejiuyuan4"] = "驰援以救栋梁，君之责也。",
	["$kejiuyuan5"] = "父兄三代营江东，人心相向乾坤定。",
	["$kejiuyuan6"] = "每思赤壁、西陵、逍遥之役，皆感诸君而涕零。",



	["~kenewsunquan"] = "江东地方皆我父兄所创，权恨未扩疆半尺。",



	--新曹植
	["kenewcaozhi"] = "新曹植",
	["&kenewcaozhi"] = "新曹植",
	["#kenewcaozhi"] = "七步绝章",
	["designer:kenewcaozhi"] = "小珂酱",
	["cv:kenewcaozhi"] = "官方",
	["illustrator:kenewcaozhi"] = "官方",

	["kenewcaozhiylqh"] = "新曹植",
	["&kenewcaozhiylqh"] = "新曹植",
	["#kenewcaozhiylqh"] = "七步绝章",
	["designer:kenewcaozhiylqh"] = "小珂酱",
	["cv:kenewcaozhiylqh"] = "官方",
	["illustrator:kenewcaozhiylqh"] = "官方",

	["kemingding"] = "章华",
	[":kemingding"] = "当你使用或打出牌时，若此牌是你当前回合使用或打出的第X张牌（X为此牌牌名字数），你可以摸一张牌。",

	["kejueyin"] = "绝吟",
	[":kejueyin"] = "限定技，当你的濒死响应结束时，若你体力值不大于0，你可以将手牌摸至七张且可以依次使用至多七张牌（无次数限制）。",


	["kenewcaozhichange"] = "选择皮肤",
	["kenewcaozhichange:qbjz"] = "七步绝章",
	["kenewcaozhichange:ylqh"] = "玉露清辉",

	["$kemingding1"] = "落英何处去，随我诉衷肠。",
	["$kemingding2"] = "梅花尽落人尽散。",
	["$kemingding3"] = "借问谁家子，幽并游侠儿。",
	["$kemingding4"] = "浮沉各异势，会合何时谐。",

	["$kejueyin1"] = "疑有暗香来，几度梅花开。",
	["$kejueyin2"] = "借君一壶酒，七步亦成诗。",
	["$kejueyin3"] = "献酬交错，宴笑无方。",
	["$kejueyin4"] = "醴而辞楚，爵而轻身。",


	["~kenewcaozhi"] = "一醉不醒，吟古恨。",


	--新刘谌
	["kenewliuchen"] = "新刘谌",
	["&kenewliuchen"] = "新刘谌",
	["#kenewliuchen"] = "舍生取义",
	["designer:kenewliuchen"] = "小珂酱",
	["cv:kenewliuchen"] = "官方",
	["illustrator:kenewliuchen"] = "官方",


	["kenewwenxiang"] = "刎项",
	[":kenewwenxiang"] = "<font color='green'><b>出牌阶段每名角色限一次，</s></font>你可以重铸一张红色牌并对一名角色造成1点伤害，然后其选择是否获得此牌并令你获得牌堆的前两张黑色牌。若其选择否或这名角色是你，本阶段“刎项”失效。",

	["bankenewwenxiang"] = "刎项失效",
	["kenewwenxiang:get"] = "获得弃置的牌，并令其获得牌堆的前两张红色牌",
	["kenewwenxiang:noget"] = "取消",
	["$kenewwenxianglog"] = "%arg2 重铸了【%arg】",

	["kenewlixing"] = "励行",
	[":kenewlixing"] = "主公技，锁定技，你杀死忠臣不执行惩罚。",
	["kenewlixing:uselixing"] = "你可以令 %src 的 %dest 判定结果反转",

	["$kenewwenxiang1"] = "既抱必死之心，何存偷生之意！",
	["$kenewwenxiang2"] = "宁在雨中高歌死，绝不寄人篱下活！",
	["$kenewlixing1"] = "关张赵黄马，义魂归来兮！",
	["$kenewlixing2"] = "狼烟起，大汉危，请公发兵来援！",
	["~kenewliuchen"] = "羞见基业弃于他人。",


	--新卧龙
	["kenewwolong"] = "新诸葛亮",
	["&kenewwolong"] = "新诸葛亮",
	["#kenewwolong"] = "卧龙",
	["designer:kenewwolong"] = "时光流逝FC",
	["cv:kenewwolong"] = "官方",
	["illustrator:kenewwolong"] = "官方",

	["kenewbazhen"] = "八阵",
	[":kenewbazhen"] = "当你需要使用或打出一张【闪】时，你可以进行判定，若结果为红色，视为你使用或打出之。",

	["kenewhuoji"] = "火计",
	[":kenewhuoji"] = "你可以将一张红色牌当【火攻】使用；你使用的【火攻】效果改为：出牌阶段，对一名有手牌的角色使用，你弃置目标角色的一张手牌，然后你可以展示一张与所弃置的牌花色相同的手牌，则你对其造成1点火焰伤害。",
	["kenewhuoji-dis"] = "火计",
	["kenewhuoji-show"] = "火计：你可以展示一张同花色的牌对其造成1点火焰伤害",

	["kenewkanpo"] = "看破",
	[":kenewkanpo"] = "你可以将一张黑色牌当【无懈可击】使用，你使用的【无懈可击】不能被响应且效果改为：令锦囊牌对任意名角色无效，直到该锦囊牌结算完毕；或抵消另一张【无懈可击】的效果。",
	["kenewkanpo-ask"] = "你可以选择令锦囊牌对任意名角色无效",
	["#kenewkanpo_Avoid"] = "%from 受到【%arg】的影响，%card 对其无效",
	["kenewcangzhuo"] = "藏拙",
	[":kenewcangzhuo"] = "锁定技，你本回合没有使用过的类型的牌不计入手牌上限。",


	["$kenewbazhen1"] = "因势而动，变生于阵之间。",
	["$kenewbazhen2"] = "兵之用者，其状不定见也。",
	["$kenewhuoji1"] = "炽焰飚发，焚轻舟，坠敌身。",
	["$kenewhuoji2"] = "以火焚敌，乱其行阵。",
	["$kenewkanpo1"] = "区区雕虫小技，微不足道矣。",
	["$kenewkanpo2"] = "识众寡之用者，胜之。",
	["$kenewcangzhuo1"] = "藏巧于拙，可败中取胜。",
	["$kenewcangzhuo2"] = "大巧若拙，大直若屈。",
	["~kenewwolong"] = "气运俱尽矣。",


	--新十常侍
	["kenewshichangshi"] = "新十常侍",
	["&kenewshichangshi"] = "新十常侍",
	["#kenewshichangshi"] = "祸乱纲常",
	["designer:kenewshichangshi"] = "小珂酱",
	["cv:kenewshichangshi"] = "官方",
	["illustrator:kenewshichangshi"] = "官方",

	["kenewqingfu"] = "倾覆",
	[":kenewqingfu"] = "锁定技，<font color='green'><b>游戏开始时，</b></font>你从四位常侍中选择一位常侍登场；<font color='green'><b>回合结束时，</b></font>你失去所有体力；你进入濒死状态时，若你处于“阳间”状态，你摸一张牌并切换为“阴间”状态，否则你弃置所有牌，然后从至多四位常侍中更换一位未选择过的常侍登场并摸两张牌，若没有未选择过的常侍，你死亡。",

	["kenewqingfu:kescsgs"] = "郭胜",
	["kenewqingfu:kescsxy"] = "夏恽",
	["kenewqingfu:kescsdg"] = "段珪",
	["kenewqingfu:kescszz"] = "赵忠",
	["kenewqingfu:kescsls"] = "栗嵩",
	["kenewqingfu:kescszr"] = "张让",
	["kenewqingfu:kescssz"] = "孙璋",
	["kenewqingfu:kescshl"] = "韩悝",
	["kenewqingfu:kescsgw"] = "高望",
	["kenewqingfu:kescsbl"] = "毕岚",

	[":kescshl"] = "贿极：<font color='blue'><b>锁定技，</b></font>你登场时摸两张牌；你执行“倾覆”时不执行“弃置所有牌”。",
	[":kescszr"] = "妄谬：<font color='green'><b>出牌阶段限一次，</b></font>你可以展示一张基本牌或普通锦囊牌并交给一名角色，然后你可以视为对至多X名角色使用之（X为此牌牌名字数）。",
	[":kescsgs"] = "怨疠：当你失去体力时，你可以视为对一名角色使用一张火【杀】。",
	[":kescsxy"] = "蔽听：<font color='green'><b>每轮限两次，</b></font>其他角色的摸牌阶段，你可以改为你摸两张牌，然后交给其至少一张牌。",
	[":kescsdg"] = "绝凌：<font color='blue'><b>锁定技，</b></font>手牌数不大于你的角色不能响应你使用的牌，你对没有手牌，或装备区没有牌，或判定区有牌的角色造成的伤害+1。",
	[":kescsls"] = "蔑谣：<font color='green'><b>每个回合限一次，</b></font>当其他角色使用基本牌或普通锦囊牌指定目标时，若此牌为红色，你可以令此牌改为一张合法的随机基本牌结算。",
	[":kescszz"] = "弑仁：其他角色的<font color='green'><b>回合结束时，</b></font>若在你登场后该角色此回合没有造成过伤害，你可以判定，若结果为：红色，你获得其一张牌；黑色，你对其造成1点伤害。",
	[":kescssz"] = "窃税：<font color='green'><b>出牌阶段限一次，</b></font>你可以令至多X名其他角色各展示一张牌（X为游戏轮数），你获得其中一张牌，然后你可以将其余牌交给任意名其他角色或弃置之。",
	[":kescsgw"] = "司疾：<font color='red'><b>限定技，</b></font>当一名其他角色回复体力时/受到伤害时，你可以改为令其失去等量的体力/回复等量的体力。",
	[":kescsbl"] = "冗垣：<font color='green'><b>准备阶段，</b></font>你可以令至多X名角色各摸一张牌或令至多Y名其他角色各弃置一张牌（X为未选择过的常侍数，Y为登场过的常侍数）。",
	["$kenewqingfu1"] = "（切换常侍）",
	["$kenewqingfu2"] = "（切换阴间）",
	["$kenewqingfu3"] = "（胜利）十常侍威势更甚，再无人可掣肘。",

	--新郭胜
	["kenewguosheng"] = "新郭胜",
	["&kenewguosheng"] = "新郭胜",
	["kenewguoshengex"] = "新郭胜",
	["&kenewguoshengex"] = "新郭胜",
	["#kenewguosheng"] = "",
	["designer:kenewguosheng"] = "小珂酱",
	["cv:kenewguosheng"] = "官方",
	["illustrator:kenewguosheng"] = "官方",

	["kenewyuanli"] = "怨疠",
	[":kenewyuanli"] = "当你失去体力时，你可以视为对一名其他角色使用一张火【杀】。",
	["yuanliask"] = "你可以发动“怨戾”视为对一名角色使用一张火【杀】",

	["$kenewyuanli1"] = "离心离德，为吾等所不容。",
	["$kenewyuanli2"] = "此昏聩之徒，吾羞与为伍。",

	--新夏恽
	["kenewxiayun"] = "新夏恽",
	["&kenewxiayun"] = "新夏恽",
	["kenewxiayunex"] = "新夏恽",
	["&kenewxiayunex"] = "新夏恽",
	["#kenewxiayun"] = "",
	["designer:kenewxiayun"] = "小珂酱",
	["cv:kenewxiayun"] = "官方",
	["illustrator:kenewxiayun"] = "官方",

	["kenewbiting"] = "蔽听",
	[":kenewbiting"] = "<font color='green'><b>每轮限两次，</b></font>其他角色的摸牌阶段，你可以改为你摸两张牌，然后交给其至少一张牌。",

	["$kenewbiting1"] = "上蔽天听，下诓朝野。",
	["$kenewbiting2"] = "贪财好贿，其罪尚小，不敬不逊，却为大逆。",

	["kenewbitingask"] = "请交给其至少一张牌",

	--新段珪
	["kenewduangui"] = "新段珪",
	["&kenewduangui"] = "新段珪",
	["kenewduanguiex"] = "新段珪",
	["&kenewduanguiex"] = "新段珪",
	["#kenewduangui"] = "",
	["designer:kenewduangui"] = "小珂酱",
	["cv:kenewduangui"] = "官方",
	["illustrator:kenewduangui"] = "官方",

	["kenewjueling"] = "绝凌",
	[":kenewjueling"] = "锁定技，手牌数不大于你的角色不能响应你使用的牌，你每回合首次对没有手牌，或装备区没有牌，或判定区有牌的角色造成的伤害+1。",

	["$kenewjueling1"] = "想见圣上，呵呵呵呵呵呵，你怕是没这个福分了！",
	["$kenewjueling2"] = "哼，不过襟裾牛马，衣冠狗彘耳！",

	["$kenewjuelinglog"] = "%from 的<font color='yellow'><b>“绝凌”</b></font>效果被触发，此牌不能被 %to 响应。",

	--新栗嵩
	["kenewlisong"] = "新栗嵩",
	["&kenewlisong"] = "新栗嵩",
	["kenewlisongex"] = "新栗嵩",
	["&kenewlisongex"] = "新栗嵩",
	["#kenewlisong"] = "",
	["designer:kenewlisong"] = "小珂酱",
	["cv:kenewlisong"] = "官方",
	["illustrator:kenewlisong"] = "官方",

	["kenewmieyao"] = "蔑谣",
	[":kenewmieyao"] = "每个回合限一次，当其他角色使用基本牌或普通锦囊牌指定目标时，若此牌为红色，你可以令此牌改为一张合法的随机基本牌结算。",

	["$kenewmieyaosha"] = "由于“蔑谣”效果，此牌被当做【杀】结算！",
	["$kenewmieyaohuosha"] = "由于“蔑谣”效果，此牌被当做火【杀】结算！",
	["$kenewmieyaoleisha"] = "由于“蔑谣”效果，此牌被当做雷【杀】结算！",
	["$kenewmieyaobingsha"] = "由于“蔑谣”效果，此牌被当做冰【杀】结算！",
	["$kenewmieyaojiu"] = "由于“蔑谣”效果，此牌被当做【酒】结算！",
	["$kenewmieyaotao"] = "由于“蔑谣”效果，此牌被当做【桃】结算！",

	["$kenewmieyao1"] = "同道者为忠，殊途者为奸。",
	["$kenewmieyao2"] = "区区不才可为帝之耳目，试问汝有何能？",

	["kenewmieyao:kenewmieyao-ask"] = "你可以发动“蔑谣”将 %src 对 %dest 使用的 %arg 改为一张随机基本牌结算",

	--新赵忠
	["kenewzhaozhong"] = "新赵忠",
	["&kenewzhaozhong"] = "新赵忠",
	["kenewzhaozhongex"] = "新赵忠",
	["&kenewzhaozhongex"] = "新赵忠",
	["#kenewzhaozhong"] = "",
	["designer:kenewzhaozhong"] = "小珂酱",
	["cv:kenewzhaozhong"] = "官方",
	["illustrator:kenewzhaozhong"] = "官方",

	["kenewshiren"] = "弑仁",

	[":kenewshiren"] = "其他角色的<font color='green'><b>回合结束时，</b></font>若在你登场后该角色此回合没有造成过伤害，你可以判定，若结果为：红色，你获得其一张牌；黑色，你对其造成1点伤害。",
	["kenewshirenask"] = "你可以发动“弑仁”将一张手牌当无视防具的【杀】对其使用",

	["$kenewshiren1"] = "逆臣乱党，都要受这啄心之刑。",
	["$kenewshiren2"] = "数此等语，何不以溺自照？",

	--新张让
	["kenewzhangrang"] = "新张让",
	["&kenewzhangrang"] = "新张让",
	["kenewzhangrangex"] = "新张让",
	["&kenewzhangrangex"] = "新张让",
	["#kenewzhangrang"] = "",
	["designer:kenewzhangrang"] = "小珂酱",
	["cv:kenewzhangrang"] = "官方",
	["illustrator:kenewzhangrang"] = "官方",

	["kenewwangmiu"] = "妄谬",
	["kenewwangmiuCard"] = "妄谬",

	[":kenewwangmiu"] = "出牌阶段限一次，你可以展示一张基本牌或普通锦囊牌并交给一名角色，然后你可以视为对至多X名角色使用之（X为此牌牌名字数）。",

	["kenewwangmiu-ask"] = "你可以选择视为使用此 【%src】 的目标",

	["$kenewwangmiu1"] = "罗绮珠紫，皆若吾等手中傀儡。",
	["$kenewwangmiu2"] = "吾乃当今帝父，汝岂配与我同列？",

	--新孙璋
	["kenewsunzhang"] = "新孙璋",
	["&kenewsunzhang"] = "新孙璋",
	["kenewsunzhangex"] = "新孙璋",
	["&kenewsunzhangex"] = "新孙璋",
	["#kenewsunzhang"] = "",
	["designer:kenewsunzhang"] = "小珂酱",
	["cv:kenewsunzhang"] = "官方",
	["illustrator:kenewsunzhang"] = "官方",

	["kenewqieshui"] = "窃税",
	[":kenewqieshui"] = "出牌阶段限一次，你可以令至多X名其他角色各展示一张牌（X为游戏轮数），你获得其中一张牌，然后你可以将其余牌交给任意名其他角色或弃置之。",

	["kenewqieshui-show"] = "窃税：请选择展示的牌",
	["kenewqieshui-distribute"] = "你可以将这些牌交给其他角色",

	["$kenewqieshui1"] = "在宫里当差，还不是为这“利”字。",
	["$kenewqieshui2"] = "闻谤而怒，见誉而喜，汝万万不能啊。",


	--新韩悝
	["kenewhanli"] = "新韩悝",
	["&kenewhanli"] = "新韩悝",
	["kenewhanliex"] = "新韩悝",
	["&kenewhanliex"] = "新韩悝",
	["#kenewhanli"] = "",
	["designer:kenewhanli"] = "小珂酱",
	["cv:kenewhanli"] = "官方",
	["illustrator:kenewhanli"] = "官方",

	["kenewhuiji"] = "贿极",
	[":kenewhuiji"] = "锁定技，你登场时摸两张牌；你执行“倾覆”时不执行“弃置所有牌”。",

	["$kenewhuiji1"] = "咱家上下打点，自是要费些银子。",
	["$kenewhuiji2"] = "切，宁享短福，莫为汝等庸奴。",


	--新高望
	["kenewgaowang"] = "新高望",
	["&kenewgaowang"] = "新高望",
	["kenewgaowangex"] = "新高望",
	["&kenewgaowangex"] = "新高望",
	["#kenewgaowang"] = "",
	["designer:kenewgaowang"] = "小珂酱",
	["cv:kenewgaowang"] = "官方",
	["illustrator:kenewgaowang"] = "官方",

	["kenewsiji"] = "司疾",
	[":kenewsiji"] = "限定技，当一名其他角色回复体力时/受到伤害时，你可以改为令其失去等量的体力/回复等量的体力。",
	["kenewsiji:kenewsiji-ask"] = "%src 将回复 %dest 点体力，你可以发动“司疾”令其改为失去等量体力",
	["kenewsiji:kenewsijida-ask"] = "%src 将受到 %dest 点伤害，你可以发动“司疾”令其改为回复等量体力",

	["$kenewsiji1"] = "小伤无碍，安心休养便可。",
	["$kenewsiji2"] = "若非吾之相助，汝安有今日？",


	--新毕岚
	["kenewbilan"] = "新毕岚",
	["&kenewbilan"] = "新毕岚",
	["kenewbilanex"] = "新毕岚",
	["&kenewbilanex"] = "新毕岚",
	["#kenewbilan"] = "",
	["designer:kenewbilan"] = "小珂酱",
	["cv:kenewbilan"] = "官方",
	["illustrator:kenewbilan"] = "官方",

	["kenewrongyuan"] = "冗垣",
	[":kenewrongyuan"] = "<font color='green'><b>准备阶段，</b></font>你可以令至多X名角色各摸一张牌或令至多Y名其他角色各弃置一张牌（X为未选择过的常侍数，Y为登场过的常侍数）。",

	["kenewrongyuan:dis"] = "选择弃置牌的角色",
	["kenewrongyuan:mopai"] = "选择摸牌的角色",
	["kenewrongyuan:cancel"] = "取消",

	["kenewqingyemp"] = "冗垣",
	["kenewqingyeqp"] = "冗垣",
	["kenewrongyuanmp-ask"] = "你可以选择“冗垣”摸牌的角色",
	["kenewrongyuandis-ask"] = "你可以选择“冗垣”弃置牌的角色",

	["$kenewrongyuan1"] = "修得广厦千万，可庇汉室不倾。",
	["$kenewrongyuan2"] = "吾虽鄙夫，亦远胜尔等狂叟。",


	--新夏侯紫萼
	["kenewxiahouzie"] = "新夏侯紫萼",
	["&kenewxiahouzie"] = "新夏侯紫萼",
	["#kenewxiahouzie"] = "孤草飘零",
	["designer:kenewxiahouzie"] = "小珂酱",
	["cv:kenewxiahouzie"] = "官方",
	["illustrator:kenewxiahouzie"] = "官方",

	["kenewqingran"] = "清燃",
	[":kenewqingran"] = "出牌阶段，当你造成伤害后，你本回合可以多使用一张【杀】；<font color='green'><b>出牌阶段结束时，</b></font>若你使用【杀】的剩余次数不为0，你摸两张牌且不计入手牌上限。",

	["kenewlvefeng"] = "掠锋",
	[":kenewlvefeng"] = "当你受到伤害后，你可以观看伤害来源的手牌并选择其中一张，若你选择的牌为伤害类牌，你对其使用之，否则其弃置此牌，你摸一张牌。",


	["$kenewqingran1"] = "风尘难掩忠魂血，杀尽宦祸不得偿！",
	["$kenewqingran2"] = "霜刃绚练，血舞婆娑！",

	["$kenewlvefeng1"] = "便以汝血，封汝之刀！",
	["$kenewlvefeng2"] = "血婆娑之剑，从不会沾无辜之血。",

	["~kenewxiahouzie"] = "祖父，紫萼不能为您昭雪了。",

	--新王异
	["kenewwangyi"] = "新王异",
	["&kenewwangyi"] = "新王异",
	["#kenewwangyi"] = "决意的巾帼",
	["designer:kenewwangyi"] = "小珂酱",
	["cv:kenewwangyi"] = "官方",
	["illustrator:kenewwangyi"] = "官方",

	["kenewzhenlie"] = "贞烈",
	["kenewzhenlietwo"] = "贞烈",
	[":kenewzhenlie"] = "当你成为其他角色使用的【杀】或普通锦囊牌的目标后，你可以失去1点体力令此牌对你无效，然后你弃置其一张牌；当你使用【杀】或伤害类普通锦囊牌指定目标后，你可以失去1点体力令此牌不可被响应，然后你可以弃置一名目标角色的一张牌。",

	["kenewmiji"] = "秘计",
	[":kenewmiji"] = "<font color='green'><b>结束阶段，</b></font>若你已受伤，你可以摸X张牌（X为你已损失的体力值且至多为3），然后你可以交给一名其他角色任意张手牌。",

	["kenewzhenlie-qipai"] = "你可以选择弃置牌的角色",
	["kenewmiji-ask"] = "你可以交给一名角色任意张牌",
	["kenewmijichoose"] = "请选择给出的牌",

	["$kenewzhenlie1"] = "既未雪家国之耻，何惜此身陨灭？",
	["$kenewzhenlie2"] = "大丈夫以忠义立身，岂可因妻女所累？",

	["$kenewmiji1"] = "防线不可厚此薄彼，宜分兵以为犄角。",
	["$kenewmiji2"] = "援兵不日便至，我军需稳固阵势，以伺反制。",

	["~kenewwangyi"] = "君慎毋失节，妾身先行一步。",











}
return { extension }
