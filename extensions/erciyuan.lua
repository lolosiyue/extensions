module("extensions.erciyuan", package.seeall)
extension = sgs.Package("erciyuan")
------------------------------------------------------------------------武将登陆区
yj = sgs.General(extension, "yj", "Erciyuan", 9, true, true, true)             --完全隐藏武将
itomakoto = sgs.General(extension, "itomakoto", "real", 3, true, false)        --伊藤誠
ayanami = sgs.General(extension, "ayanami", "science", 3, false, false)        --綾波レイ
keima = sgs.General(extension, "keima", "real", 3, true, false)                --桂馬
SPkirito = sgs.General(extension, "SPkirito", "science", 4, true, false)       --キリト
odanobuna = sgs.General(extension, "odanobuna", "magic", 3, false, false)      --織田信奈
yuuta = sgs.General(extension, "yuuta", "real", 4, true, false)                --勇太
tsukushi = sgs.General(extension, "tsukushi", "real", 3, false, false)         --筑紫
batora = sgs.General(extension, "batora", "magic", 3, true, true)              --バトラ
mao_maoyu = sgs.General(extension, "mao_maoyu", "magic", 4, false, false)      --まお
sheryl = sgs.General(extension, "sheryl", "science", 3, false, false)          --シェリル
aoitori = sgs.General(extension, "aoitori", "magic", 4, true, false)           --葵‘トリ
kyouko = sgs.General(extension, "kyouko", "magic", 4, false, false)            --きょうこ
diarmuid = sgs.General(extension, "diarmuid", "magic", 4, true, false)         --迪卢木多
ikarishinji = sgs.General(extension, "ikarishinji", "science", 3, true, false) --碇シンジ
runaria = sgs.General(extension, "runaria", "magic", 3, false, false)          --ルナリア
redarcher = sgs.General(extension, "redarcher", "magic", 4, true, false)       --红Archer
redo = sgs.General(extension, "redo", "science", 3, true, false)               --レド
fuwaaika = sgs.General(extension, "fuwaaika", "magic", 3, false, false)        --不破愛花
slsty = sgs.General(extension, "slsty", "real", 3, false, false)               --塞蕾丝缇雅
rokushikimei = sgs.General(extension, "rokushikimei", "real", 3, true, true)   --六識命
bernkastel = sgs.General(extension, "bernkastel", "magic", 3, false, true)     --贝伦卡斯泰露
hibiki = sgs.General(extension, "hibiki", "magic", 3, false, false)            --立花響
kntsubasa = sgs.General(extension, "kntsubasa", "magic", 4, false, false)      --風鳴翼
khntmiku = sgs.General(extension, "khntmiku", "magic", 3, false, false)        --小日向未来
yukinechris = sgs.General(extension, "yukinechris", "magic", 3, false, false)  --雪音クリス
------------------------------------------------------------------------特殊代码区
getmoesenlist = function(room, player, taipu)                                  --OmnisReen --作用：萌战技通用、得出参战角色list
	local ResPlayers = sgs.SPlayerList()
	local targets = room:getAlivePlayers()
	local newdata = sgs.QVariant()
	newdata:setValue(player)
	ResPlayers:append(player)
	for _, p in sgs.qlist(room:getOtherPlayers(player)) do
		if p:getMark(taipu) > 0 then
			if p:askForSkillInvoke("moesenskill", newdata) then
				ResPlayers:append(p)
				targets:removeOne(p)
			end
		end
	end
	targets:removeOne(player)
	return ResPlayers, targets
end

player2serverplayer = function(room, player) --啦啦SLG (OTZ--ORZ--Orz) --作用：将currentplayer转换成serverplayer
	local players = room:getPlayers()
	for _, p in sgs.qlist(players) do
		if p:objectName() == player:objectName() then
			return p
		end
	end
end
qstring2serverplayer = function(room, qstring) --改编版本 --作用：将qstring类型转换成serverplayer
	local players = room:getPlayers()
	for _, p in sgs.qlist(players) do
		if p:objectName() == qstring then
			return p
		end
	end
end
------------------------------------------------------------------------武器技能区 By独孤安河（OTZ--ORZ--orz）
GuanchuanDummyCard = sgs.CreateSkillCard {
	name = "GuanchuanDummyCard",
}
GuanchuanVS = sgs.CreateViewAsSkill {
	name = "#GuanchuanVS",
	n = 2,
	view_filter = function(self, selected, to_select)
		return #select < 2
	end,
	view_as = function(self, cards)
		return GuanchuanDummyCard:clone()
	end,
	enabled_at_play = function(self, target)
		return false
	end,
	enabled_at_response = function(self, target, pattern)
		return pattern == "@Axe"
	end
}
GuanchuanSkill = sgs.CreateTriggerSkill {
	name = "GuanchuanSkill",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.SlashMissed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
		local dest = effect.to
		if dest:isAlive() then
			local prompt = string.format("@axe:%s", dest:objectName())
			local card = room:askForCard(player, "@Axe", prompt, data, sgs.CardDiscarded)
			if card then
				room:setEmotion(dest, "weapon/axe")
				local msg = sgs.LogMessage()
				msg.type = "#AxeSkill"
				msg.from = player
				msg.to:append(dest)
				msg.arg = self:objectName()
				room:sendLog(msg)
				room:slashResult(effect, nil)
			end
		end
		return false
	end
}
ZhuishaSkill = sgs.CreateTriggerSkill {
	name = "ZhuishaSkill",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.SlashMissed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
		local dest = effect.to
		if dest:isAlive() then
			if effect.from:canSlash(dest, nil, false) then
				local prompt = string.format("blade-slash:%s", dest:objectName())
				if room:askForUseSlashTo(player, dest, prompt) then
					room:setEmotion(player, "weapon/blade")
				end
			end
		end
		return false
	end,
	priority = -1
}
CixiongSkill = sgs.CreateTriggerSkill {
	name = "CixiongSkill",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local source = use.from
		if source:objectName() == player:objectName() then
			local targets = use.to
			for _, target in sgs.qlist(targets) do
				if source:isMale() ~= target:isMale() then
					if not target:isSexLess() then
						if use.card:isKindOf("Slash") then
							if source:askForSkillInvoke("double_sword") then
								room:setEmotion(source, "weapon/double_sword")
								local draw_card = false
								if target:isKongcheng() then
									draw_card = true
								else
									local prompt = string.format("double-sword-card:%s", source:getGeneralName())
									local card = room:askForCard(target, ".", prompt, sgs.QVariant(), sgs.CardDiscarded)
									if not card then
										draw_card = true
									end
								end
								if draw_card then
									source:drawCards(1)
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				return not target:isSexLess()
			end
		end
		return false
	end
}
HuoshanSkill = sgs.CreateTriggerSkill {
	name = "HuoshanSkill",
	events = { sgs.CardUsed },
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			if not card:isKindOf("Slash") or card:isKindOf("ThunderSlash") or card:isKindOf("FireSlash") then return false end
			if not room:askForSkillInvoke(player, self:objectName()) then return end
			local newslash = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
			newslash:addSubcard(card:getId())
			newslash:setSkillName("HuoshanSkill")
			use.card = newslash
			room:useCard(use, true)
			return true
		end
	end,
}
BaojiSkill = sgs.CreateTriggerSkill {
	name = "BaojiSkill",
	frequency = sgs.Skill_Compuslory,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local slash = damage.card
		local dest = damage.to
		if slash then
			if slash:isKindOf("Slash") then
				if dest:isKongcheng() then
					if not damage.chain then
						if not damage.transfer then
							room:setEmotion(dest, "weapon/guding_blade")
							local msg = sgs.LogMessage()
							msg.type = "#GudingBladeEffect"
							msg.from = player
							msg.to:append(dest)
							local point = damage.damage
							msg.arg = string.format("%d", point)
							point = point + 1
							msg.arg2 = string.format("%d", point)
							room:sendLog(msg)
							damage.damage = point
							data:setValue(damage)
						end
					end
				end
			end
		end
		return false
	end
}
ZhangbaSkill = sgs.CreateViewAsSkill {
	name = "ZhangbaSkill",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected < 2 then
			return not to_select:isEquipped()
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local cardA = cards[1]
			local cardB = cards[2]
			local suit = sgs.Card_NoSuit
			if cardA:isBlack() and cardB:isBlack() then
				suit = sgs.Card_Club
			end
			if cardA:isRed() and cardB:isRed() then
				suit = sgs.Card_Diamond
			end
			local slash = sgs.Sanguosha:cloneCard("slash", suit, 0)
			slash:setSkillName(self:objectName())
			slash:addSubcard(cardA)
			slash:addSubcard(cardB)
			return slash
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
ShemaSkill = sgs.CreateTriggerSkill {
	name = "ShemaSkill",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local slash = damage.card
		local dest = damage.to
		local source = damage.from
		if slash then
			if slash:isKindOf("Slash") then
				if not damage.chain then
					if not damage.transfer then
						local DefHorse = dest:getDefensiveHorse()
						local OffHorse = dest:getOffensiveHorse()
						if DefHorse or OffHorse then
							if player:askForSkillInvoke(self:objectName(), data) then
								room:setEmotion(player, "weapon/kylin_bow")
								local horse_type
								if DefHorse then
									if OffHorse then
										horse_type = room:askForChoice(player, self:objectName(), "dhorse+ohorse")
									else
										horse_type = "dhorse"
									end
								else
									horse_type = "ohorse"
								end
								if horse_type == "dhorse" then
									room:throwCard(DefHorse, dest, source)
								elseif horse_type == "ohorse" then
									room:throwCard(OffHorse, dest, source)
								end
							end
						end
					end
				end
			end
		end
		return false
	end
}
HanbingSkill = sgs.CreateTriggerSkill {
	name = "HanbingSkill",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local slash = damage.card
		local dest = damage.to
		if slash then
			if slash:isKindOf("Slash") then
				if player:canDiscard(dest, "he") then
					if not damage.chain then
						if not damage.transfer then
							if player:askForSkillInvoke("ice_sword", data) then
								room:setEmotion(player, "weapon/ice_sword")
								local id = room:askForCardChosen(player, dest, "he", "ice_sword")
								local card = sgs.Sanguosha:getCard(id)
								room:throwCard(card, dest, player)
								if player:canDiscard(dest, "he") then
									id = room:askForCardChosen(player, dest, "he", "ice_sword")
									card = sgs.Sanguosha:getCard(id)
									room:throwCard(card, dest, player)
								end
								return true
							end
						end
					end
				end
			end
		end
		return false
	end
}
HuajiSkill = sgs.CreateTargetModSkill {

	name = "HuajiSkill",
	pattern = "Slash",
	extra_target_func = function(self, from, card)
		if from:hasSkill("HuajiSkill") and from:isLastHandCard(card) then
			return 2
		else
			return 0
		end
	end,
}
------------------------------------------------------------------------技能引用区 By DGAH.Github （OTZ--ORZ--orz）
LuaXiuluo = sgs.CreateTriggerSkill { --修罗
	name = "LuaXiuluo",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local once_success = false
		repeat
			once_success = false
			if not player:askForSkillInvoke(self:objectName()) then return false end
			local card_id = room:askForCardChosen(player, player, "j", self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			local suit_str = card:getSuitString()
			local pattern = string.format(".|%s|.|.|.", suit_str)
			if room:askForCard(player, pattern, "@LuaXiuluoprompt", data, sgs.CardDiscarded) then
				room:throwCard(card, nil, player)
				once_success = true
			end
		until (not (player:getCards("j"):length() ~= 0 and once_success))
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start then
					if not target:isKongcheng() then
						local ja = target:getJudgingArea()
						return ja:length() > 0
					end
				end
			end
		end
		return false
	end
}
LuaPaoxiao = sgs.CreateTargetModSkill { --咆哮
	name = "LuaPaoxiao",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		end
	end,
}
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
LuaWushuang = sgs.CreateTriggerSkill { --wushuang
	name = "LuaWushuang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed, sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local can_invoke = false
			if use.card:isKindOf("Slash") and (player and player:isAlive() and player:hasSkill(self:objectName())) and (use.from:objectName() == player:objectName()) then
				can_invoke = true
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_table[i + 1] == 1 then
						jink_table[i + 1] = 2 --只要设置出两张闪就可以了，不用两次askForCard
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Duel") then
				if effect.from and effect.from:isAlive() and effect.from:hasSkill(self:objectName()) then
					can_invoke = true
				end
				if effect.to and effect.to:isAlive() and effect.to:hasSkill(self:objectName()) then
					can_invoke = true
				end
			end
			if not can_invoke then return false end
			if effect.card:isKindOf("Duel") then
				if room:isCanceled(effect) then
					effect.to:setFlags("Global_NonSkillNullify")
					return true;
				end
				if effect.to:isAlive() then
					local second = effect.from
					local first = effect.to
					room:setEmotion(first, "duel");
					room:setEmotion(second, "duel")
					while true do
						if not first:isAlive() then
							break
						end
						local slash
						if second:hasSkill(self:objectName()) then
							slash = room:askForCard(first, "slash", "@Luawushuang-slash-1:" .. second:objectName(), data,
								sgs.Card_MethodResponse, second);
							if slash == nil then
								break
							end
							slash = room:askForCard(first, "slash", "@Luawushuang-slash-2:" .. second:objectName(), data,
								sgs.Card_MethodResponse, second);
							if slash == nil then
								break
							end
						else
							slash = room:askForCard(first, "slash", "duel-slash:" .. second:objectName(), data,
								sgs.Card_MethodResponse, second)
							if slash == nil then
								break
							end
						end
						local temp = first
						first = second
						second = temp
					end
					local daamgeSource = function() if second:isAlive() then return second else return nil end end
					local damage = sgs.DamageStruct(effect.card, daamgeSource(), first)
					if second:objectName() ~= effect.from:objectName() then
						damage.by_user = false;
					end
					room:damage(damage)
				end
				room:setTag("SkipGameRule", sgs.QVariant(tonumber(event)))
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 1,
}
LuaKuanggu = sgs.CreateTriggerSkill { --狂骨
	name = "LuaKuanggu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damage, sgs.PreDamageDone },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if (event == sgs.PreDamageDone) and damage.from and damage.from:hasSkill(self:objectName()) and damage.from:isAlive() then
			local weiyan = damage.from
			weiyan:setTag("invokeLuaKuanggu", sgs.QVariant((weiyan:distanceTo(damage.to) <= 1)))
		elseif (event == sgs.Damage) and player:hasSkill(self:objectName()) and player:isAlive() then
			local invoke = player:getTag("invokeLuaKuanggu"):toBool()
			player:setTag("invokeLuaKuanggu", sgs.QVariant(false))
			if invoke and player:isWounded() then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = damage.damage
				room:recover(player, recover)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
------------------------------------------------------------------------技能区
--------------------------------------------------------------人渣@itomakoto
ak_renzha = sgs.CreateTriggerSkill {
	name = "ak_renzha",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local x = damage.damage
		if x >= 2 then
			room:setPlayerMark(player, "ak_renzha", x)
		end
		for i = 0, x - 1, 1 do
			room:drawCards(player, 2, self:objectName())
			if not player:isKongcheng() then
				local card_id
				if player:getHandcardNum() == 1 then
					card_id = player:handCards():first()
				else
					card_id = room:askForExchange(player, self:objectName(), 1, 1, false, "ak_renzhaPush"):getSubcards()
						:first()
				end
				player:addToPile("zha", card_id)
			end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke("ak_renzha")
				player:turnOver()
				room:drawCards(player, 1, self:objectName())
			end
			room:setPlayerMark(player, "ak_renzha", x - 1)
		end
	end,
}
--------------------------------------------------------------好船@itomakoto

luarenzhacard = sgs.CreateSkillCard {
	name = "luarenzhacard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		--room:broadcastSkillInvoke("luarenzha")
		room:throwCard(self,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", source:objectName(), self:objectName(),
				""), nil)
		room:doLightbox("luarenzha$", 2000)
		if (source:getPile("zha")):length() > 1 then
			local zrecover = sgs.RecoverStruct()
			zrecover.recover = (source:getPile("zha")):length()
			zrecover.who = source
			room:recover(source, zrecover)
		end
		source:turnOver()
		local players = room:getOtherPlayers(source)
		for _, p in sgs.qlist(players) do
			if p:isAlive() then
				room:cardEffect(self, source, p)
			end
		end
	end,
	on_effect = function(self, effect)
		local dest = effect.to
		local room = dest:getRoom()
		local players = room:getOtherPlayers(dest)
		local nearest = 1000
		local distance_list = sgs.IntList()
		for _, player in sgs.qlist(players) do
			local dist = dest:distanceTo(player)
			distance_list:append(dist)
			if dist < nearest then
				nearest = dist
			end
		end
		local luanwu_targets = sgs.SPlayerList()
		local count = distance_list:length()
		for i = 0, count, 1 do
			local dist = distance_list:at(i)
			if dist == nearest then
				local player = players:at(i)
				if dest:canSlash(player) then
					luanwu_targets:append(player)
				end
			end
		end
		if luanwu_targets:length() > 0 then
			if not room:askForUseSlashTo(dest, luanwu_targets, "@luanwu-slash") then
				room:loseHp(dest)
			end
		else
			room:loseHp(dest)
		end
	end
}
luarenzha = sgs.CreateOneCardViewAsSkill {
	name = "luarenzha",
	filter_pattern = ".|.|.|zha",
	expand_pile = "zha",
	view_as = function(self, originalCard)
		local snatch = luarenzhacard:clone()
		snatch:addSubcard(originalCard:getId())
		snatch:setSkillName(self:objectName())
		return snatch
	end,
	enabled_at_play = function(self, player)
		return not player:getPile("zha"):isEmpty() and
			not player:hasUsed("#luarenzhacard")
	end
}

--------------------------------------------------------------微笑@ayanami
weixiao = sgs.CreateTriggerSkill {
	name = "weixiao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		local room = player:getRoom()
		local handnum = player:getHandcardNum()
		if handnum > 1 then
			if phase == sgs.Player_Finish then
				local card_id = room:askForExchange(player, self:objectName(), 2, 2, false, "weixiaoPush", true)
				if card_id then
					room:throwCard(card_id, player, nil)
					local anum = sgs.Sanguosha:getCard(card_id:getSubcards():first()):getNumber()
					local bnum = sgs.Sanguosha:getCard(card_id:getSubcards():last()):getNumber()
					local choice = room:askForChoice(player, self:objectName(), "a+b")
					local list = room:getAlivePlayers()
					if choice == "a" then
						local n = math.min(anum, bnum)
						local dest1 = room:askForPlayerChosen(player, list, "weixiao")
						local count = n / 2
						room:drawCards(dest1, count, "weixiao")
						room:broadcastSkillInvoke("weixiao")
						room:doLightbox("weixiao$", 2000)
					end
					if choice == "b" then
						local n = math.max(anum, bnum)
						local dest2 = room:askForPlayerChosen(player, list, "weixiao_dis")
						local count = (n + 1) / 2
						room:askForDiscard(dest2, "weixiao_dis", count, count, false, true)
						room:broadcastSkillInvoke("weixiao")
						room:doLightbox("weixiao$", 2000)
					end
				end
			end
		end
	end
}
--------------------------------------------------------------女神@ayanami
nvshen = sgs.CreateMaxCardsSkill {
	name = "nvshen",
	extra_func = function(self, target)
		if target:hasSkill("nvshen") then
			local hanumax = target:getMaxHp()
			return hanumax
		end
	end
}
--------------------------------------------------------------神知@keima
LuaShenzhi = sgs.CreateTriggerSkill {
	name = "LuaShenzhi",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local count = room:alivePlayerCount()
				if count > 4 then
					count = 4
				end
				room:broadcastSkillInvoke("LuaShenzhi")
				room:doLightbox("LuaShenzhi$", 1000)
				room:askForGuanxing(player, room:getNCards(count, false))
			end
		end
	end
}
--------------------------------------------------------------攻略@keima
luagongluecard = sgs.CreateSkillCard {
	name = "luagongluecard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if not target:isKongcheng() then
			local room = target:getRoom()
			local list = target:handCards()
			room:fillAG(list, source)
			--room:broadcastSkillInvoke("luagonglue")
			local card_id = room:askForAG(source, list, false, self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			room:obtainCard(source, card, false)
			room:clearAG(source)
		end
	end
}
luagonglue = sgs.CreateViewAsSkill {
	name = "luagonglue",
	n = 0,
	view_as = function(self, cards)
		local card = luagongluecard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luagongluecard")
	end
}
--------------------------------------------------------------阐释@kirito
LuaChanshi = sgs.CreateTargetModSkill {
	name = "LuaChanshi",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}
--------------------------------------------------------------逐暗@kirito
LuaZhuan = sgs.CreateTriggerSkill {
	name = "LuaZhuan",
	frequency = sgs.Skill_Frequent,
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local source = use.from
		if source and source:objectName() == player:objectName() then
			local card = use.card
			local room = player:getRoom()
			if card:isKindOf("Duel") then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					player:drawCards(2)
				end
			end
			if (card:isKindOf("Slash") and card:isBlack()) then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					player:drawCards(1)
				end
			end
		end
	end
}
--------------------------------------------------------------赤鬼@odanobuna
LuaChigui = sgs.CreateTriggerSkill {
	name = "LuaChigui",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			local others = room:getOtherPlayers(player)
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(others) do
				local weapon = p:getWeapon()
				if weapon then
					targets:append(p)
				end
			end
			while player:isAlive() and not targets:isEmpty() do
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "LuaChigui-invoke", true, true)
				if target then
					room:broadcastSkillInvoke("LuaChigui")
					room:loseHp(player)
					if not player:isAlive() then break end
					local weapon2 = target:getWeapon()
					player:obtainCard(weapon2)
					room:drawCards(player, player:getHp(), self:objectName())
					targets:removeOne(target)
				else
					break
				end
			end
		end
		return false
	end
}
--------------------------------------------------------------布武@odanobuna
LuaBuwu = sgs.CreateTriggerSkill {
	name = "LuaBuwu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local dest = damage.to
		if not dest:isDead() then
			if not damage.chain then
				if not damage.transfer then
					local room = player:getRoom()
					local victim = sgs.QVariant()
					victim:setValue(damage.to)
					if room:askForSkillInvoke(player, self:objectName(), victim) then
						local hp = dest:getHp()
						dest:drawCards(hp - 1)
						dest:turnOver()
						room:broadcastSkillInvoke("LuaBuwu")
						room:doLightbox("LuaBuwu$", 1000)
					end
				end
			end
		end
		return false
	end
}
--------------------------------------------------------------天魔@odanobuna
LuaTianmo = sgs.CreateTriggerSkill {
	name = "#LuaTianmo",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardOffset },
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		local room = player:getRoom()
		if effect.card and effect.card:isKindOf("Slash") then
			player:gainMark("@tianmo", 1)
			return false
		end
	end
}
LuaTianmoDefense = sgs.CreateTriggerSkill {
	name = "LuaTianmoDefense",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageDone, sgs.PreHpLost },
	on_trigger = function(self, event, player, data)
		local tm = player:getMark("@tianmo")
		if tm > 0 then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				player:loseMark("@tianmo")
				local msg = sgs.LogMessage()
				msg.type = "#TianmoDefense"
				msg.from = player
				room:sendLog(msg)
				room:broadcastSkillInvoke("LuaTianmoDefense")
				local damage = data:toDamage()
				damage.prevented = true
				data:setValue(damage)
				return true
			end
		end
	end,
	priority = 8
}
--------------------------------------------------------------妄想@yuuta
LuaWangxiang = sgs.CreateViewAsSkill {
	name = "LuaWangxiang",
	n = 1,
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return true
		end
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		elseif #cards == 1 then
			local card = cards[1]
			local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", card:getSuit(), card:getNumber())
			ex_nihilo:addSubcard(card:getId())
			ex_nihilo:setSkillName(self:objectName())
			return ex_nihilo
		end
	end,
	enabled_at_play = function(self, player)
		local wxhcn = player:getHandcardNum()
		local hp = player:getHp()
		local losehp = player:getMaxHp() - hp
		return (wxhcn <= losehp)
	end,
}
--------------------------------------------------------------黑焰@yuuta
luablackflamecard = sgs.CreateSkillCard {
	name = "luablackflamecard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local room = target:getRoom()
		local flame = sgs.DamageStruct()
		flame.from = source
		flame.to = target
		flame.damage = 1
		flame.nature = sgs.DamageStruct_Fire
		room:loseHp(source)
		--room:broadcastSkillInvoke("luablackflame")
		room:doLightbox("luablackflame$", 1000)
		room:damage(flame)
	end
}
luablackflame = sgs.CreateViewAsSkill {
	name = "luablackflame",
	n = 0,
	view_as = function(self, cards)
		local card = luablackflamecard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luablackflamecard")
	end
}
--------------------------------------------------------------钢躯@tsukushi
LuaGqset = sgs.CreateTriggerSkill {
	name = "LuaGqset",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if not player:isKongcheng() then
				local gang = player:getPile("gang")
				local gangnum = gang:length()
				if gangnum == 0 then
					local card = room:askForExchange(player, self:objectName(), 1, 1, false, "QuanjiPush", true)
					if card then
						local card_id = card:getSubcards():first()
						player:addToPile("gang", card_id)
					end
				end
			end
		end
		if player:getPhase() == sgs.Player_Start then
			local gang = player:getPile("gang")
			local gangnum = gang:length()
			local idx = -1
			if gangnum > 0 then
				idx = gang:first()
				room:throwCard(idx, player)
				gangnum = gang:length()
			end
		end
	end,
}
LuaGqef = sgs.CreateTriggerSkill {
	name = "#LuaGqef",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local gang = player:getPile("gang")
		local gangnum = gang:length()
		if gangnum > 0 then
			local effect = data:toCardEffect()
			local target = effect.to
			local card = effect.card
			local card_type = card:getTypeId()
			local gangcardid = gang:first()
			local gangcard = sgs.Sanguosha:getCard(gangcardid)
			local gangcard_type = gangcard:getTypeId()
			if target:objectName() == player:objectName() then
				if card_type == gangcard_type then
					room:broadcastSkillInvoke("LuaGqset")
					room:doLightbox("LuaGqset$", 800)
					room:sendCompulsoryTriggerLog(player, "LuaGqset", true)
					return true
				end
			end
		end
	end,
}
--------------------------------------------------------------调教@tsukushi
luatiaojiaocard = sgs.CreateSkillCard {
	name = "luatiaojiaocard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		local room = source:getRoom()
		local list = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(dest)) do
			if dest:canSlash(p) then
				list:append(p)
			end
		end
		if not list:isEmpty() then
			room:setPlayerFlag(dest, self:objectName())
			local dead = room:askForPlayerChosen(source, list, self:objectName())
			room:setPlayerFlag(dest, "-" .. self:objectName())
			local prompt = string.format("@TiaojiaoSlash:%s:%s:%s", source:getGeneralName(), dest:getGeneralName(),
				dead:getGeneralName())
			--room:broadcastSkillInvoke("luatiaojiao")
			local log = sgs.LogMessage()
			log.type = "#CollateralSlash"
			log.from = source
			log.to:append(dead)
			room:sendLog(log)
			room:setPlayerFlag(source, self:objectName())
			if not room:askForUseSlashTo(dest, dead, prompt) then
				if not dest:isNude() then
					local cardn = room:askForCardChosen(source, dest, "hej", self:objectName())
					room:obtainCard(source, cardn, false)
				end
			end
			room:setPlayerFlag(source, "-" .. self:objectName())
		else
			if not dest:isNude() then
				local cardn = room:askForCardChosen(source, dest, "hej", self:objectName())
				room:obtainCard(source, cardn, false)
			end
		end
	end
}
luatiaojiao = sgs.CreateViewAsSkill {
	name = "luatiaojiao",
	n = 0,
	view_as = function(self, cards)
		return luatiaojiaocard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luatiaojiaocard")
	end
}
--------------------------------------------------------------布棋@Batora
LuaBuqi = sgs.CreateTriggerSkill {
	name = "LuaBuqi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameStart, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local getcard = false
		local targets = room:getOtherPlayers(player)
		local givingcard = false
		local yourcardnum = 0
		for _, p in sgs.qlist(targets) do
			if not p:isKongcheng() then
				getcard = true
				break
			end
		end
		if getcard then
			if player:askForSkillInvoke(self:objectName()) then
				local targets = room:getOtherPlayers(player)
				for _, p in sgs.qlist(targets) do
					if not p:isKongcheng() then
						local yourcardnum = p:getHandcardNum()
						room:setPlayerMark(p, "chest", yourcardnum)
						local allcard = p:wholeHandCards()
						room:obtainCard(player, allcard, false)
					end
				end
				getcard = false
				yourcardnum = 0
				local mycdnum = player:getHandcardNum()
				if mycdnum > 0 then
					givingcard = true
				end
			end
		end
		if givingcard then
			local targets = room:getOtherPlayers(player)
			local targetnum = targets:length()
			local mycardnum = player:getHandcardNum()
			for _, p in sgs.qlist(targets) do
				if not player:isKongcheng() then
					local givingcardnum = p:getMark("chest")
					local prompt = string.format("@Buqigiving:%s:%s:%s", player:getGeneralName(), p:getGeneralName(),
						givingcardnum)
					local givecard = room:askForExchange(player, self:objectName(), givingcardnum, false, prompt, false)
					room:obtainCard(p, givecard, false)
					room:setPlayerMark(p, "chest", 0)
				end
			end
			givingcard = false
		end
	end,
	priority = -2
}
--------------------------------------------------------------博学@mao_maoyu BUGGGGGGG dont know why will copy card
luaboxuecard = sgs.CreateSkillCard {
	name = "luaboxuecard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		local num = sgs.Self:aliveCount()
		return #targets <= num and not to_select:isNude()
	end,
	on_use = function(self, room, source, targets)
		local num = #targets
		local cards = room:getNCards(num)
		local drawx = math.ceil(num / 2)
		local canexchange = false
		local urexcard
		source:drawCards(drawx)
		--room:broadcastSkillInvoke("luaboxue")
		room:doLightbox("luaboxue$", 1200)
		--[[	for _,cs in sgs.qlist(cards) do
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,source:objectName(), "luaboxue", "")
			room:moveCardTo(sgs.Sanguosha:getCard(cs), source, sgs.Player_PlaceTable, reason, true)
		end]]
		for _, target in ipairs(targets) do
			room:fillAG(cards)
			local iwantcard = room:askForAG(target, cards, false, self:objectName())
			room:obtainCard(target, iwantcard, true)
			room:getThread():delay(500)
			room:clearAG()
			room:clearAG(target)
			if not target:isNude() then
				canexchange = true
				urexcard = room:askForCardChosen(target, target, "he", self:objectName())
			end
			cards:removeOne(iwantcard)
			if canexchange then
				cards:append(urexcard)
				room:obtainCard(source, urexcard, true)
				--local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,source:objectName(), "luaboxue", "")
				--room:moveCardTo(sgs.Sanguosha:getCard(urexcard),target, sgs.Player_PlaceTable, reason, true)
			end
			room:fillAG(cards)
			room:getThread():delay(500)
			room:clearAG()
			canexchange = false
		end
		--	local choice=room:askForChoice(source,self:objectName(),"throw+gx")
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:deleteLater()
		for _, c in sgs.qlist(cards) do
			dummy:addSubcard(c)
		end
		--	if choice =="throw" then
		--room:throwCard(dummy,nil,source)
		room:moveCardTo(dummy, nil, nil, sgs.Player_DiscardPile,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, source:objectName(), "luaboxue", ""), false)
		--	end
		--	if choice =="gx" then
		--		room:moveCardTo(dummy, nil, nil,sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "luaboxue", ""), false)
		--		room:askForGuanxing(source,cards, sgs.Room_GuanxingUpOnly)
		--	end
	end,
}
luaboxue = sgs.CreateViewAsSkill {
	name = "luaboxue",
	n = 0,
	view_as = function(self, cards)
		return luaboxuecard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luaboxuecard")
	end
}
--------------------------------------------------------------妖精@sheryl
LuaYaojing = sgs.CreateViewAsSkill {
	name = "LuaYaojing",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		elseif #cards == 1 then
			local card = cards[1]
			local god_salvation = sgs.Sanguosha:cloneCard("god_salvation", card:getSuit(), card:getNumber())
			god_salvation:addSubcard(card:getId())
			god_salvation:setSkillName(self:objectName())
			return god_salvation
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaYaojing")
	end,
}
LuaYaojingSound = sgs.CreateTriggerSkill {
	name = "#LuaYaojingSound",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.card:getSkillName() == "LuaYaojing" then
			room:broadcastSkillInvoke("LuaYaojing")
			room:doLightbox("LuaYaojing$", 1500)
		end
	end,
}
--------------------------------------------------------------共鸣@sheryl
LuaGongming = sgs.CreateTriggerSkill {
	name = "LuaGongming",
	frequency = sgs.Skill_Frequent,
	events = { sgs.HpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpRecover then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getPhase() ~= sgs.Player_NotActive then
					local targets = sgs.SPlayerList()
					targets:append(player)
					if player:objectName() ~= p:objectName() then
						targets:append(p)
					end
					local dest = room:askForPlayerChosen(p, targets, self:objectName(), "@LuaGongming-to", true,
						true)
					if dest then
						dest:drawCards(p:getLostHp() + 1)
					end
					room:broadcastSkillInvoke("LuaGongming")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return (target ~= nil)
	end,
}
--------------------------------------------------------------裸王@aoitori
LuaLuowang = sgs.CreateTriggerSkill {
	name = "LuaLuowang",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		local room = player:getRoom()
		if phase == sgs.Player_Draw then
			if room:askForSkillInvoke(player, self:objectName()) then
				room:broadcastSkillInvoke("LuaLuowang")
				room:doLightbox("LuaLuowang$", 1200)
				room:showAllCards(player)
				local showlist = player:getHandcards()
				for _, c in sgs.qlist(showlist) do
					if c:getSuit() == sgs.Card_Heart then
						room:setPlayerMark(player, "Heart", 1)
					elseif c:getSuit() == sgs.Card_Diamond then
						room:setPlayerMark(player, "Diamond", 1)
					elseif c:getSuit() == sgs.Card_Club then
						room:setPlayerMark(player, "Club", 1)
					elseif c:getSuit() == sgs.Card_Spade then
						room:setPlayerMark(player, "Spade", 1)
					end
				end
				for i = 0, player:getMark("Heart") + player:getMark("Diamond") - 1, 1 do
					local all = room:getAlivePlayers()
					local prompt = string.format("@LuoDraw")
					room:setPlayerFlag(player, "luoDraw")
					local drawdest = room:askForPlayerChosen(player, all, self:objectName(), prompt)
					room:setPlayerFlag(player, "-luoDraw")
					room:drawCards(drawdest, 1, self:objectName())
				end
				for i = 0, player:getMark("Club") + player:getMark("Spade") - 1, 1 do
					local all = room:getAlivePlayers()
					local prompt = string.format("@LuoDis")
					local discarddest = room:askForPlayerChosen(player, all, self:objectName(), prompt)
					if discarddest:isNude() then return false end
					local dis_card = room:askForCardChosen(player, discarddest, "he", self:objectName())
					room:throwCard(dis_card, nil)
				end
				room:setPlayerMark(player, "Spade", 0)
				room:setPlayerMark(player, "Heart", 0)
				room:setPlayerMark(player, "Diamond", 0)
				room:setPlayerMark(player, "Club", 0)
			end
		end
	end,
}
--------------------------------------------------------------强气@kyouko
LuaLuoshen = sgs.CreateTriggerSkill {
	name = "LuaLuoshen",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.FinishJudge },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				while player:askForSkillInvoke(self:objectName()) do
					local judge = sgs.JudgeStruct()
					judge.pattern = "Slash"
					judge.who = player
					judge.good = false
					judge.play_animation = false
					judge.time_consuming = true
					judge.reason = self:objectName()
					room:judge(judge)
					room:broadcastSkillInvoke("LuaLuoshen")
					if judge:isBad() then
						break
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				player:obtainCard(card)
				return true
			end
		end
		return false
	end
}
--------------------------------------------------------------破魔@diarmuid
LuaPomo = sgs.CreateTriggerSkill {
	name = "LuaPomo",
	events = { sgs.TargetSpecified },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.from and use.from:hasSkill(self:objectName()) then
				if use.card:isKindOf("Slash") then
					if use.from:objectName() == player:objectName() then
						room:broadcastSkillInvoke("LuaPomo")
						for _, p in sgs.qlist(use.to) do
							if (p:getMark("Equips_of_Others_Nullified_to_You") == 0) then
								p:addQinggangTag(use.card)
							end
						end
						room:setEmotion(use.from, "weapon/qinggang_sword")
						room:sendCompulsoryTriggerLog(use.from, "LuaPomo", true)
					end
				end
			end
			return false
		end
	end,
}
--------------------------------------------------------------必灭@diarmuid
LuaBimie = sgs.CreateTriggerSkill {
	name = "LuaBimie",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local target = damage.to
		local source = damage.from
		local slash = damage.card
		local room = player:getRoom()
		if slash then
			if slash:isKindOf("Slash") then
				if source:objectName() == player:objectName() then
					if target:getMark("@zhou") == 0 then
						if target:isAlive() then
							--room:setTag("CurrentDamageStruct", data)
							if room:askForSkillInvoke(player, self:objectName(), data) then
								room:broadcastSkillInvoke("LuaBimie")
								room:doLightbox("LuaBimie$", 1500)
								target:gainMark("@zhou", 1)
								room:addPlayerMark(target, "&LuaBimie+to+#" .. player:objectName())
							end
							--room:removeTag("CurrentDamageStruct")
						end
					end
				end
			end
		end
	end,
}
LuaBimieHprcvForbidden = sgs.CreateTriggerSkill {
	name = "#LuaBimieHprcvForbidden",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.PreHpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		if player:getMark("@zhou") > 0 then
			for _, p in sgs.qlist(room:findPlayersBySkillName("LuaBimie")) do
				if player:getMark("&LuaBimie+to+#" .. p:objectName()) > 0 then
					player:getRoom():sendCompulsoryTriggerLog(p, "LuaBimie", true)

					return true
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
LuaBimieLost = sgs.CreateTriggerSkill {
	name = "#LuaBimieLost",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Death },
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local victim = death.who
		local room = player:getRoom()
		local list = room:getAlivePlayers()
		if victim:objectName() == player:objectName() then
			for _, p in sgs.qlist(list) do
				if p:getMark("&LuaBimie+to+#" .. player:objectName()) > 0 then
					room:setPlayerMark(p, "&LuaBimie+to+#" .. player:objectName(), 0)
					local can_remove = true
					for _, mark in sgs.list(p:getMarkNames()) do
						if string.find(mark, "LuaBimie") and p:getMark(mark) > 0 then
							can_remove = false
						end
					end
					if can_remove then
						room:setPlayerMark(p, "@zhou", 0)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			return target:hasSkill(self:objectName())
		end
		return false
	end
}
--------------------------------------------------------------暴走@ikarishinji
LuaBaozou = sgs.CreateTriggerSkill {
	name = "LuaBaozou",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AskForPeachesDone, sgs.EventPhaseEnd, sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForPeachesDone then
			if player:hasFlag("BaozouTurn") then return end
			if not room:askForSkillInvoke(player, self:objectName()) then return end
			if not player:hasSkill("paoxiao") then
				room:handleAcquireDetachSkills(player, "paoxiao", true)
			end
			if not player:hasSkill("LuaKuangshi") then
				room:handleAcquireDetachSkills(player, "LuaKuangshi", true)
			end
			if not player:hasSkill("LuaYinbao") then
				room:handleAcquireDetachSkills(player, "LuaYinbao", true)
			end
			if not player:hasSkill("kuanggu") then
				room:handleAcquireDetachSkills(player, "kuanggu", true)
			end
			if not player:hasSkill("wushuang") then
				room:handleAcquireDetachSkills(player, "wushuang", true)
			end
			if not player:hasSkill("xiuluo") then
				room:handleAcquireDetachSkills(player, "xiuluo", true)
			end
			room:setPlayerFlag(player, "BaozouTurn")
			room:addPlayerMark(player, "&LuaBaozou+-Clear")
			room:broadcastSkillInvoke("LuaBaozou")
			player:gainAnExtraTurn()
		elseif event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				if player:hasSkill("paoxiao") then
					room:detachSkillFromPlayer(player, "paoxiao")
				end
				if player:hasSkill("LuaKuangshi") then
					room:detachSkillFromPlayer(player, "LuaKuangshi")
				end
				if player:hasSkill("LuaYinbao") then
					room:detachSkillFromPlayer(player, "LuaYinbao")
				end
				if player:hasSkill("kuanggu") then
					room:detachSkillFromPlayer(player, "kuanggu")
				end
				if player:hasSkill("wushuang") then
					room:detachSkillFromPlayer(player, "wushuang")
				end
				if player:hasSkill("xiuluo") then
					room:detachSkillFromPlayer(player, "xiuluo")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.from:hasSkill(self:objectName()) and damage.from:isAlive() and damage.from:getHp() > 1 and damage.from:hasFlag("BaozouTurn") then
				room:setPlayerCardLimitation(damage.from, "use,response", "BasicCard", true)
				room:setPlayerCardLimitation(damage.from, "use,response", "TrickCard", true)
			end
		end
	end,
	priority = 1,

}
--------------------------------------------------------------狂噬Sound@ikarishinji
LuaBaozouSound = sgs.CreateTriggerSkill {
	name = "#LuaBaozouSound",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if use.card:getSkillName() == "LuaKuangshi" then
			room:broadcastSkillInvoke("LuaKuangshi")
		end
	end,
}
--------------------------------------------------------------狂噬@ikarishinji
LuaKuangshi = sgs.CreateFilterSkill {
	name = "LuaKuangshi",
	view_filter = function(self, to_select)
		return to_select:isKindOf("BasicCard") or to_select:isKindOf("TrickCard")
	end,
	view_as = function(self, card)
		local KScard
		if card:isKindOf("TrickCard") then
			KScard = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
		elseif card:isKindOf("BasicCard") then
			KScard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		end
		local acard = sgs.Sanguosha:getWrappedCard(card:getId())
		acard:takeOver(KScard)
		acard:setSkillName(self:objectName())
		return acard
	end,
}
--------------------------------------------------------------音爆@ikarishinji
LuaYinbao = sgs.CreateDistanceSkill {
	name = "LuaYinbao",
	correct_func = function(self, from, to)
		if from:hasSkill("LuaYinbao") then
			return -1000
		end
	end,
}
--------------------------------------------------------------不死@ikarishinji
LuaBaozouDying = sgs.CreateTriggerSkill {
	name = "#LuaBaozouDying",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.HpChanged, sgs.AskForPeachesDone },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpChanged and ((data:toDamage() and data:toDamage().to) or data:toInt() > 0) and player:getHp() < 1 then
			if player:hasFlag("BaozouTurn") then
				return true
			end
		elseif event == sgs.AskForPeachesDone then
			if player:hasFlag("BaozouTurn") then
				room:setPlayerFlag(player, "-Global_Dying")
				return true
			end
		end
		return false
	end,
}
--------------------------------------------------------------心壁@ikarishinji
LuaXinbi = sgs.CreateTriggerSkill {
	name = "LuaXinbi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				if player:hasFlag("BaozouTurn") then return end
				local targets = sgs.SPlayerList()
				local all = room:getAlivePlayers()
				for _, p in sgs.qlist(all) do
					if player:canDiscard(p, "e") then
						targets:append(p)
					end
				end
				room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				if not targets:isEmpty() then
					local target = room:askForPlayerChosen(player, targets, self:objectName(), "LuaXinbi-invoke", true,
						true)
					if not target then
						room:loseHp(player, 1)
					else
						local id = room:askForCardChosen(player, target, "e", self:objectName())
						room:throwCard(id, target, player)
					end
				else
					room:loseHp(player, 1)
				end
				room:broadcastSkillInvoke("LuaXinbi")
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local dest = move.to
			local hand = move.to_place
			local fromplace = move.from_places
			local cards = move.card_ids
			local reason = move.reason
			local count = cards:length()
			if dest then
				if not room:getTag("FirstRound"):toBool() then
					if dest:objectName() == player:objectName() and dest:getPhase() ~= sgs.Player_Draw then
						if count > 2 then
							local all = room:getAlivePlayers()
							--	local skillwhoid = move.reason.m_playerId
							--	local who = qstring2serverplayer(room,skillwhoid)
							local who = room:getCurrent()
							local x = count / 2
							if who and not player:hasFlag("BaozouTurn") then
								room:sendCompulsoryTriggerLog(player, self:objectName(), true)
								for i = 0, x - 1, 1 do
									room:loseHp(player, 1)
									room:drawCards(who, 1, self:objectName())
								end
							end
							room:broadcastSkillInvoke("LuaXinbi")
						end
					end
				end
			end
		end
	end,
}
--------------------------------------------------------------投影@redarcher
luatouyingClear = sgs.CreateTriggerSkill {
	name = "#luatouyingClear",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseEnd, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				local lose = player:property("weaponskilltoget"):toString()
				if lose ~= "" then
					room:setPlayerProperty(player, "weaponskilltoget", sgs.QVariant())
					room:setPlayerMark(player, "&luatouying+" .. lose, 0)
					--room:detachSkillFromPlayer(player, lose)
				end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local lose = player:property("weaponskilltoget"):toString()
				if lose ~= "" then
					room:setPlayerProperty(player, "weaponskilltoget", sgs.QVariant())
					room:setPlayerMark(player, "&luatouying+" .. lose, 0)
					--room:detachSkillFromPlayer(player, lose)
				end
			end
		end
	end,
}
luatouyingcard = sgs.CreateSkillCard {
	name = "luatouyingcard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local choices = {}
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if card:isKindOf("Weapon") and not table.contains(choices, card:objectName()) then
				table.insert(choices, card:objectName())
			end
		end
		table.insert(choices, "cancel")
		local choice = room:askForChoice(source, "luatouying", table.concat(choices, "+"))
		if choice ~= "cancel" then
			local old = source:property("weaponskilltoget"):toString()
			room:setPlayerMark(source, "&luatouying+" .. old, 0)
			room:setPlayerProperty(source, "weaponskilltoget", sgs.QVariant(choice))
			room:setPlayerMark(source, "&luatouying+" .. choice, 1)
		end

		room:broadcastSkillInvoke("luatouying")
	end,
}
luatouying = sgs.CreateViewAsSkill {
	name = "luatouying",
	n = 0,
	view_as = function(self, cards)
		return luatouyingcard:clone()
	end,
	enabled_at_play = function(self, player)
		local weapon = player:getWeapon()
		if weapon == nil then
			return not player:hasUsed("#luatouyingcard")
		end
		return false
	end
}
luatouying_equip = sgs.CreateViewAsEquipSkill {
	name = "#luatouying_equip",
	view_as_equip = function(self, player)
		return "" .. player:property("weaponskilltoget"):toString()
	end,
}
--------------------------------------------------------------崩坏@redarcher
LuaGongqi = sgs.CreateViewAsSkill {
	name = "LuaGongqi",
	n = 1,
	view_filter = function(self, selected, to_select)
		local weapon = sgs.Self:getWeapon()
		if weapon and to_select:objectName() == weapon:objectName() and to_select:objectName() == "Crossbow" then
			return sgs.Self:canSlashWithoutCrossbow()
		end
		return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
			slash:addSubcard(id)
			slash:setSkillName(self:objectName())
			return slash
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
LuaGongqiTargetMod = sgs.CreateTargetModSkill {
	name = "#LuaGongqi-target",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("LuaGongqi") and card:getSkillName() == "LuaGongqi" then
			return 1000
		else
			return 0
		end
	end
}
--------------------------------------------------------------剑咏@redarcher
LuaJianyong = sgs.CreateTriggerSkill {
	name = "LuaJianyong",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Discard then
				if not player:askForSkillInvoke(self:objectName()) then return end
				room:drawCards(player, 1)
				if not player:isKongcheng() then
					local card_id
					if player:getHandcardNum() == 1 then
						card_id = player:handCards():first()
					else
						card_id = room:askForExchange(player, self:objectName(), 1, 1, false, "QuanjiPush"):getSubcards():first()
					end
					player:addToPile("yong", card_id)
					room:broadcastSkillInvoke("LuaJianyong")
				end
			end
		end
	end,
}

--------------------------------------------------------------剑制@redarcher
LuaJianzhi = sgs.CreateTriggerSkill {
	name = "LuaJianzhi",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
			room:doLightbox("LuaJianzhi$", 2500)
			room:broadcastSkillInvoke("LuaJianzhi")
			room:handleAcquireDetachSkills(player, "luajianyu")
			room:handleAcquireDetachSkills(player, "LuaChitian")
			room:addPlayerMark(player, "LuaJianzhi")
			local targets = room:getOtherPlayers(player)
			for _, t in sgs.qlist(targets) do
				if not t:isKongcheng() then
					local id = room:askForCardChosen(player, t, "h", "LuaJianzhi")
					player:addToPile("yong", id)
				end
			end
			local playerdata = sgs.QVariant()
			playerdata:setValue(player)
			room:setTag("LuaJianzhiTarget", playerdata)
		end
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Finish or player:getMark(self:objectName()) > 0 then
			return false
		end
		if player:canWake(self:objectName()) then
			return true
		end
		if player:getPile("yong"):length() >= 2 then
			return true
		end
		return false
	end,

}
LuaJianzhiGive = sgs.CreateTriggerSkill {
	name = "#LuaJianzhiGive",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("LuaJianzhiTarget") then
			local target = room:getTag("LuaJianzhiTarget"):toPlayer()
			room:removeTag("LuaJianzhiTarget")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end,
	priority = 1
}
--------------------------------------------------------------剑雨@redarcher
luajianyu = sgs.CreateViewAsSkill {
	name = "luajianyu",
	n = 999,
	expand_pile = "yong",
	view_as = function(self, cards)
		local alivenum = sgs.Self:aliveCount()
		if #cards == alivenum then
			local card = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_SuitToBeDecided, -1)
			for i = 1, #cards, 1 do
				card:addSubcard(cards[i])
			end
			card:setSkillName(self:objectName())
			return card
		end
	end,
	view_filter = function(self, selected, to_select)
		local alivenum = sgs.Self:aliveCount()
		return sgs.Self:getPile("yong"):contains(to_select:getId()) and #selected < alivenum
	end,
	enabled_at_play = function(self, player)
		local yong = player:getPile("yong")
		local alivenum = player:aliveCount()
		return yong:length() >= alivenum
	end
}
--------------------------------------------------------------炽天@redarcher

sgs.LuaChitianPattern = { "pattern" }
LuaChitian = sgs.CreateViewAsSkill {
	name = "LuaChitian",
	n = 1,
	expand_pile = "yong",
	view_filter = function(self, selected, to_select)
		if (#selected >= 1) or to_select:hasFlag("using") then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Slash_IsAvailable(sgs.Self) then
				return sgs.Self:getPile("yong"):contains(to_select:getId())
			else
				return false
			end
		elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
			or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "jink" or pattern == "slash" then
				return sgs.Self:getPile("yong"):contains(to_select:getId())
			end
			return false
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = cards[1]
		local new_card = nil
		local pattern = sgs.LuaChitianPattern[1]
		if pattern == "slash" then
			new_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		elseif pattern == "jink" then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
		end
		if new_card then
			new_card:setSkillName(self:objectName())
			for _, c in ipairs(cards) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end,
	enabled_at_play = function(self, player)
		sgs.LuaChitianPattern = { "slash" }
		local yong = player:getPile("yong")
		return sgs.Slash_IsAvailable(player) and yong:length() > 0
	end,
	enabled_at_response = function(self, player, pattern)
		sgs.LuaChitianPattern = { pattern }
		local yong = player:getPile("yong")
		return yong:length() > 0 and (pattern == "slash")
			or (pattern == "jink")
	end,
}
--------------------------------------------------------------去死吧,铁皮混蛋！@redo
LuaRedoWake = sgs.CreateTriggerSkill {
	name = "LuaRedoWake",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		player:gainMark("@waked")
		player:loseAllMarks("@Chamber")
		room:addPlayerMark(player, "LuaRedoWake")
		local wakercv = sgs.RecoverStruct()
		wakercv.recover = 1
		wakercv.who = player
		room:recover(player, wakercv)
		local targets = room:getOtherPlayers(player)
		local dest = room:askForPlayerChosen(player, targets, self:objectName())
		local qbd = sgs.DamageStruct()
		qbd.from = player
		qbd.to = dest
		qbd.damage = 3
		qbd.nature = sgs.DamageStruct_Thunder
		room:broadcastSkillInvoke("LuaRedoWake")
		room:doLightbox("$LuaRedoWake", 3600)
		room:damage(qbd)
		if player:hasSkill("LuaGaoxiao") then
			room:detachSkillFromPlayer(player, "LuaGaoxiao")
		end
		if player:hasSkill("LuaGaokang") then
			room:detachSkillFromPlayer(player, "LuaGaokang")
		end
		if player:hasSkill("LuaJiguangAsk") then
			room:detachSkillFromPlayer(player, "LuaJiguangAsk")
		end
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_Play or player:getMark(self:objectName()) > 0 then
			return false
		end
		if player:canWake(self:objectName()) then
			return true
		end
		if player:getHp() == 1 then
			return true
		end
		return false
	end
}
--------------------------------------------------------------钱伯@redo
LuaChamberStart = sgs.CreateTriggerSkill {
	name = "#LuaChamberStart",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.GameStart, sgs.AfterDrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			player:loseAllMarks("@Chamber")
			player:gainMark("@Chamber", 1)
			if not player:hasSkill("LuaGaoxiao") then
				room:handleAcquireDetachSkills(player, "LuaGaoxiao")
			end
			if not player:hasSkill("LuaGaokang") then
				room:handleAcquireDetachSkills(player, "LuaGaokang")
			end
			if not player:hasSkill("LuaJiguangAsk") then
				room:handleAcquireDetachSkills(player, "LuaJiguangAsk")
			end
		elseif event == sgs.AfterDrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "InitialHandCards" then return false end
			room:askForDiscard(player, "LuaChamberMove", 2, 2, false, true)
		end
	end
}
LuaChamberMove = sgs.CreateTriggerSkill {
	name = "LuaChamberMove",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("@Chamber") == 0 then
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			player:gainMark("@Chamber", 1)
			if not player:hasSkill("LuaGaoxiao") then
				room:handleAcquireDetachSkills(player, "LuaGaoxiao")
			end
			if not player:hasSkill("LuaJiguangAsk") then
				room:handleAcquireDetachSkills(player, "LuaJiguangAsk")
			end
			if not player:hasSkill("LuaGaokang") then
				room:handleAcquireDetachSkills(player, "LuaGaokang")
			end
			room:broadcastSkillInvoke("LuaChamberMove")
		elseif player:getMark("@Chamber") == 1 then
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			player:loseAllMarks("@Chamber")
			if player:hasSkill("LuaGaoxiao") then
				room:detachSkillFromPlayer(player, "LuaGaoxiao")
			end
			if player:hasSkill("LuaJiguangAsk") then
				room:detachSkillFromPlayer(player, "LuaJiguangAsk")
			end
			if player:hasSkill("LuaGaokang") then
				room:detachSkillFromPlayer(player, "LuaGaokang")
			end
			room:broadcastSkillInvoke("LuaChamberMove")
		end
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getMark("LuaRedoWake") == 0 then
					if target:getPhase() == sgs.Player_Start then
						return true
					end
				end
			end
		end
		return false
	end
}
--------------------------------------------------------------高效@redo
LuaGaoxiao = sgs.CreateTriggerSkill {
	name = "LuaGaoxiao",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if room:askForSkillInvoke(player, "LuaGaoxiao", data) then
			draw.num = draw.num + 1
			room:notifySkillInvoked(player, self:objectName())
			room:broadcastSkillInvoke("LuaGaoxiao")
			data:setValue(draw)
		end
	end
}
--------------------------------------------------------------高抗@redo
LuaGaokang = sgs.CreateTriggerSkill {
	name = "LuaGaokang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		if player:canDiscard(player, "he") then
			if damage.nature == sgs.DamageStruct_Normal then
				room:askForDiscard(player, "LuaGaokang", 1, 1, false, true)
				room:notifySkillInvoked(player, self:objectName())
				damage.damage = damage.damage - 1
				room:broadcastSkillInvoke("LuaGaokang")
				data:setValue(damage)
				if damage.damage == 0 then
					damage.prevented = true
					data:setValue(damage)
					return true
				end
			end
		end
		return false
	end,
}
--------------------------------------------------------------激光@redo
LuaJiguangMod = sgs.CreateTargetModSkill {
	name = "#LuaJiguangMod",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill("LuaJiguangAsk") then
			return 1000
		end
	end,
}

LuaJiguangAsk = sgs.CreateTriggerSkill {
	name = "LuaJiguangAsk",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		local dest = effect.to
		local source = effect.from
		if effect.card and effect.card:isKindOf("Slash") and source:hasSkill(self:objectName()) then
			room:notifySkillInvoked(source, self:objectName())
			local prompt = string.format("@jiguang:%s:%s", source:getGeneralName(), dest:getGeneralName())
			local card = room:askForCard(dest, "TrickCard,EquipCard|.|.", prompt, data, sgs.CardDiscarded)
			effect.to:setFlags("Global_NonSkillNullify")
			if card then
				effect.offset_card = card
				data:setValue(effect)
				if not room:getThread():trigger(sgs.CardOffset,room,effect.from,data) then
					return true
				end
			else
				room:broadcastSkillInvoke("LuaJiguangAsk")
				effect.offset_card = nil
				data:setValue(effect)
				room:getThread():trigger(sgs.CardOnEffect,room,effect.to,data)
				room:damage(sgs.DamageStruct(effect.card, effect.from, effect.to, 1))
				return true
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--------------------------------------------------------------无杀@redo
LuaRedoNoSlash = sgs.CreateProhibitSkill {
	name = "#LuaRedoNoSlash",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("LuaChamberMove") and card:isKindOf("Slash") and to:getMark("@Chamber") == 0
	end
}
--------------------------------------------------------------文乐@runaria
LuaWenle = sgs.CreateTriggerSkill {
	name = "LuaWenle",
	events = { sgs.DrawNCards, sgs.EventPhaseEnd, sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = math.floor(room:alivePlayerCount() / 2)
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			draw.num = draw.num + x
			room:broadcastSkillInvoke("LuaWenle")
			data:setValue(draw)
		elseif event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Draw then
				if player:getHandcardNum() < x then
					player:addToPile("si", player:getHandcards(), false)
				else
					local card_id = room:askForExchange(player, self:objectName(), x, x, false,
						string.format("LuaWenlePush:%s", x)):getSubcards()
					player:addToPile("si", card_id, false)
				end
			end
		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				local si = player:getPile("si")
				local x = si:length()
				player:clearOnePrivatePile("si")
				player:drawCards(x)
				room:broadcastSkillInvoke("LuaWenle")
			end
		end
	end,
}
--------------------------------------------------------------御空@runaria
luayukongcard = sgs.CreateSkillCard {
	name = "luayukongcard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			room:setFixedDistance(source, p, 1)
		end
		--room:throwCard( sgs.Sanguosha:getCard(self:getSubcards():first()), nil, nil)
		room:throwCard(self,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", source:objectName(), self:objectName(),
				""), nil)
		room:addPlayerMark(source, "&luayukong-Clear")
	end,
}
luayukongVS = sgs.CreateOneCardViewAsSkill {
	name = "luayukong",
	filter_pattern = ".|.|.|si",
	expand_pile = "si",
	view_as = function(self, originalCard)
		local card = luayukongcard:clone()
		card:addSubcard(originalCard:getId())
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		local si = player:getPile("si")
		if si:length() > 0 then
			return not player:hasUsed("#luayukongcard")
		end
		return false
	end
}
luayukong = sgs.CreateTriggerSkill {
	name = "luayukong",
	events = { sgs.EventPhaseChanging },
	view_as_skill = luayukongVS,
	on_trigger = function(self, event, player, data)
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		end
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			room:removeFixedDistance(player, p, 1)
		end
		return false;
	end,
}
--------------------------------------------------------------绮丝@runaria
LuaQisicard = sgs.CreateSkillCard {
	name = "LuaQisi",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		--room:throwCard( sgs.Sanguosha:getCard(self:getSubcards():first()), nil, nil)
		room:throwCard(self,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", source:objectName(), self:objectName(),
				""), nil)
	end,
}
LuaQisiVS = sgs.CreateOneCardViewAsSkill {
	name = "LuaQisi",
	filter_pattern = ".|.|.|si",
	expand_pile = "si",
	view_as = function(self, originalCard)
		local card = LuaQisicard:clone()
		card:addSubcard(originalCard:getId())
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern == "@@LuaQisi" then
			return (player:getPile("si"):length() > 0)
		end
	end,

}
LuaQisi = sgs.CreateTriggerSkill {
	name = "LuaQisi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardEffected },
	view_as_skill = LuaQisiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local si = player:getPile("si")
		local sinum = si:length()
		if sinum > 0 then
			local effect = data:toCardEffect()
			local target = effect.to
			local source = effect.from
			local card = effect.card
			if card then
				if card:isKindOf("Slash") or (card:isNDTrick()) then
					if (target:objectName() == player:objectName()) then
						room:setPlayerMark(player, "LuaQisi_attackR", source:getAttackRange())
						room:setTag("LuaQisiData", data)
						local cardq = room:askForUseCard(player, "@@LuaQisi", "@LuaQisi-card")
						if cardq then
							local cardx = sgs.Sanguosha:getCard(cardq:getSubcards():first())
							local num = (cardx:getNumber()) / 2
							local itsar = source:getMark("LuaQisi_attackR")
							if num > itsar then
								room:broadcastSkillInvoke("LuaQisi")
								room:setPlayerFlag(player, "-LuaQisi_sucess")
								room:setPlayerMark(player, "LuaQisi_attackR", 0)
								return true
							end
						end
					end
				end
			end
		end
	end,
}
--------------------------------------------------------------破始@fuwaaika
luaposhicard = sgs.CreateSkillCard {
	name = "luaposhicard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:loseHp(source, 1)
		--room:broadcastSkillInvoke("luaposhi")
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			room:addPlayerMark(p, "Armor_Nullified")
			room:setFixedDistance(source, p, 1);
		end
		room:addPlayerMark(source, "&luaposhi")
	end,
}
luaposhi = sgs.CreateViewAsSkill {
	name = "luaposhi",
	n = 0,
	view_as = function(self, cards)
		local card = luaposhicard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luaposhicard")
	end,
}
luaposhiTMS = sgs.CreateTargetModSkill {
	name = "#luaposhiTMS",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasUsed("#luaposhicard") then
			return 1000
		end
	end,
}
luaposhi_Clear = sgs.CreateTriggerSkill {
	name = "#luaposhi_Clear",
	events = { sgs.EventPhaseChanging, sgs.Death },
	on_trigger = function(self, event, gaoshun, data)
		--if not gaoshun:hasUsed("#luaposhicard") then return false end
		if gaoshun:getMark("&luaposhi") == 0 then return false end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		end
		local room = gaoshun:getRoom()
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:objectName() ~= gaoshun:objectName() then
				room:removeFixedDistance(gaoshun, death.who, 1)
				return false;
			end
		end
		for _, p in sgs.qlist(room:getOtherPlayers(gaoshun)) do
			room:removeFixedDistance(gaoshun, p, 1)
			room:removePlayerMark(p, "Armor_Nullified");
		end
		room:setPlayerMark(gaoshun, "&luaposhi", 0)
		return false;
	end,
}

--------------------------------------------------------------连锁@fuwaaika
LuaLiansuo = sgs.CreateTriggerSkill {
	name = "LuaLiansuo",
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			local topc = move.to_place
			if source == nil then return end
			if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_DISCARD then return end
			if topc ~= sgs.Player_DiscardPile then return end
			if not (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then return end
			for _, aika in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if aika:getPhase() == sgs.Player_NotActive
					and aika:objectName() == player:objectName()
					and source:objectName() ~= aika:objectName() then
					for _, id in sgs.qlist(move.card_ids) do
						if aika:getMark("&LuaLiansuo") < 2 then
							if aika:askForSkillInvoke(self:objectName()) then
								aika:drawCards(1)
								if aika:getMark("&LuaLiansuo") == 0 then
									room:broadcastSkillInvoke("LuaLiansuo")
								end
								room:addPlayerMark(aika, "&LuaLiansuo", 1)
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				for _, aika in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:setPlayerMark(aika, "&LuaLiansuo", 0)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
--------------------------------------------------------------因果@fuwaaika
LuaYinguo = sgs.CreateTriggerSkill {
	name = "LuaYinguo",
	events = { sgs.Death },
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local males = sgs.SPlayerList()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:isMale() then
				males:append(p)
			end
		end
		local death = data:toDeath()
		--local selfplayer = room:findPlayerBySkillName(self:objectName())
		if death.who:objectName() ~= player:objectName() then return false end
		if males:isEmpty() then return end
		if not player:isKongcheng() then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke("LuaYinguo")
				local ids = player:handCards()
				local prompt = string.format("@yinguo")
				local man = room:askForPlayerChosen(player, males, self:objectName(), prompt, true, true)
				room:setPlayerMark(man, "todraw", man:getHandcardNum())
				local prompt2 = string.format("@yinguo2")
				local man2 = room:askForPlayerChosen(player, males, self:objectName(), prompt2, true, true)
				room:setPlayerMark(man2, "todraw", man2:getHandcardNum())
				if man ~= nil then
					targets:append(man)
				end
				if man2 ~= nil then
					if man2:objectName() ~= man:objectName() then
						targets:append(man2)
					end
				end
				if man:objectName() ~= man2:objectName() then
					while room:askForYiji(player, ids, self:objectName(), false, false, false, -1, targets) do end
				else
					local hc = player:wholeHandCards()
					room:obtainCard(man, hc, false)
				end
				if man2:objectName() == man:objectName() then
					man:drawCards(man:getHandcardNum() - man:getMark("todraw"))
				else
					man2:drawCards(man2:getHandcardNum() - man2:getMark("todraw"))
					man:drawCards(man:getHandcardNum() - man:getMark("todraw"))
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return target:hasSkill(self:objectName())
		end
		return false
	end,
	priority = 4,
}
--------------------------------------------------------------言惑@slsty
function takeyanhuocard(source, player, id)
	local room = player:getRoom()
	local card = sgs.Sanguosha:getCard(id)
	local suit = card:getSuit()
	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, source:objectName(), player:objectName(),
		"slyanhuo", "")
	room:moveCardTo(card, nil, sgs.Player_PlaceTable, reason, true)
	room:broadcastSkillInvoke("slyanhuo")
	if source:hasSkill("zhahu") then
		local log = sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = source
		log.arg = "zhahu"
		room:sendLog(log)
		if suit == sgs.Card_Spade then
			local recov = sgs.RecoverStruct()
			recov.who = source
			recov.recover = 1
			room:recover(player, recov)
		elseif suit == sgs.Card_Heart then
			room:loseHp(player)
		elseif suit == sgs.Card_Club then
			player:drawCards(2)
		elseif suit == sgs.Card_Diamond and source:canDiscard(player, "he") then
			local choice = room:askForCardChosen(source, player, "he", "zhahu")
			room:throwCard(choice, player, source)
		end
	end
	room:throwCard(card, nil)
	room:getThread():delay()
end

yanhuoacquirecard = sgs.CreateSkillCard
	{
		name = "yanhuoacquirecard",
		filter = function(self, selected, to_select)
			return #selected == 0 and to_select:hasSkill("slyanhuo") and not to_select:getPile("confuse"):isEmpty() and
				to_select:objectName() ~= sgs.Self:objectName()
		end,
		on_effect = function(self, effect)
			local room = effect.from:getRoom()
			if not effect.to:hasSkill("slyanhuo") or effect.to:getPile("confuse"):isEmpty() then
				return
			end
			local id = effect.to:getPile("confuse"):last()
			takeyanhuocard(effect.to, effect.from, id)
		end
	}

yanhuoacquire = sgs.CreateViewAsSkill
	{
		name = "yanhuoacquire&",
		n = 0,
		view_as = function(self, cards)
			return yanhuoacquirecard:clone()
		end,
		enabled_at_play = function(self, player)
			local others = player:getSiblings()
			local can_use = false
			for _, p in sgs.qlist(others) do
				if p:hasSkill("slyanhuo") and not p:getPile("confuse"):isEmpty() then
					can_use = true
					break
				end
			end
			return can_use and not player:hasUsed("#yanhuoacquirecard")
		end
	}

if not sgs.Sanguosha:getSkill("yanhuoacquire") then
	local skillList = sgs.SkillList()
	skillList:append(yanhuoacquire)
	sgs.Sanguosha:addSkills(skillList)
end

yanhuocard = sgs.CreateSkillCard
	{
		name = "slyanhuocard",
		target_fixed = true,
		will_throw = false,
		on_use = function(self, room, player, targets)
			player:addToPile("confuse", self, false)
			player:drawCards(1)
		end
	}

yanhuovs = sgs.CreateViewAsSkill
	{
		name = "slyanhuo",
		n = 1,
		view_filter = function(self, selected, to_select)
			return not to_select:isEquipped()
		end,
		view_as = function(self, cards)
			if #cards < 1 then return nil end
			local card = yanhuocard:clone()
			card:addSubcard(cards[1])
			return card
		end,
		enabled_at_play = function(self, player)
			return player:getPile("confuse"):length() < 5 and
				(player:getPile("confuse"):length() < player:getAliveSiblings():length() + 1)
		end
	}

slyanhuo = sgs.CreateTriggerSkill
	{
		name = "slyanhuo",
		view_as_skill = yanhuovs,
		frequency = sgs.Skill_NotFrequent,
		events = { sgs.GameStart, sgs.EventAcquireSkill, sgs.Damaged },
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:hasSkill("yanhuoacquire") then
						room:attachSkillToPlayer(p, "yanhuoacquire")
					end
				end
			elseif event == sgs.Damaged then
				local damage = data:toDamage()
				local card_ids = player:getPile("confuse")
				if not damage.from or damage.from:isDead() or card_ids:isEmpty()
					or not room:askForSkillInvoke(player, self:objectName(), data) then
					return false
				end
				room:setTag("slyanhuoData", data)
				room:fillAG(card_ids, player)
				local id = room:askForAG(player, card_ids, true, self:objectName())
				room:clearAG(player)
				takeyanhuocard(player, damage.from, id)
			end
			return false
		end
	}
--------------------------------------------------------------诈唬@slsty
zhahu = sgs.CreateTriggerSkill
	{
		name = "zhahu",
		frequency = sgs.Skill_Compulsory,
		events = sgs.EventPhaseStart,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local card_ids = player:getPile("confuse")
			if player:getPhase() ~= sgs.Player_Start or card_ids:isEmpty() then
				return false
			end
			room:broadcastSkillInvoke("zhahu")
			for i = 1, card_ids:length() do
				takeyanhuocard(player, player, card_ids:at(card_ids:length() - i))
			end
			return false
		end
	}
--------------------------------------------------------------心灵诱导@rokushikimei
LuaHeartlead = sgs.CreateTriggerSkill {
	name = "LuaHeartlead",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirming },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
		local use = data:toCardUse()
		local card = use.card
		local source = use.from
		local targets = use.to
		if targets:length() ~= 1 then return end
		if source:objectName() == selfplayer:objectName() then return end
		if card:isKindOf("BasicCard") or (card:isNDTrick()) then
			if not room:askForSkillInvoke(selfplayer, self:objectName(), data) then return end
			if selfplayer:isChained() then
				if not selfplayer:faceUp() then
					return
				end
			end
			if not selfplayer:faceUp() then
				if selfplayer:isChained() then
					selfplayer:turnOver()
				end
			end
			if selfplayer:isChained() then
				selfplayer:turnOver()
			else
				local choice = room:askForChoice(selfplayer, self:objectName(), "chained+turnoverself", data)
				if choice == "chained" then
					room:setPlayerProperty(selfplayer, "chained", sgs.QVariant(true))
				elseif choice == "turnoverself" then
					selfplayer:turnOver()
				end
			end
			local tosecplayers = room:getAlivePlayers()
			for _, t in sgs.qlist(targets) do
				tosecplayers:removeOne(t)
			end
			local emptylist = sgs.PlayerList()
			local newtargetstosec = sgs.SPlayerList()
			for _, p in sgs.qlist(tosecplayers) do
				if card:targetFilter(emptylist, p, source) then
					if not source:isProhibited(p, card) then
						newtargetstosec:append(p)
					end
				end
			end
			local target = room:askForPlayerChosen(source, newtargetstosec, self:objectName())
			local confirmedtarget = sgs.SPlayerList()
			confirmedtarget:append(target)
			if target ~= nil then
				use.from = source
				use.to = confirmedtarget
				use.card = card
				data:setValue(use)
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--------------------------------------------------------------藏位转移@rokushikimei
LuaPositionMove = sgs.CreateTriggerSkill {
	name = "LuaPositionMove",
	frequency = sgs.Skill_Compulsory,
	events = sgs.DamageForseen,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:isChained() or (player:faceUp() == false) then
			if player:objectName() == damage.to:objectName() then
				if player:getCards("he"):length() < 2 then return end
				if player:getCards("he"):length() == 2 then
					player:throwAllHandCardsAndEquips()
				elseif player:getCards("he"):length() > 2 then
					room:askForDiscard(player, self:objectName(), 2, 2, false, true)
				end
				if player:isChained() then
					room:setPlayerProperty(player, "chained", sgs.QVariant(false))
				end
				if not player:faceUp() then
					player:turnOver()
				end
			end
			return true
		end
	end,
}
--------------------------------------------------------------语言牢笼@rokushikimei
LuaSpkprison = sgs.CreateTriggerSkill {
	name = "LuaSpkprison",
	frequency = sgs.Skill_Limited,
	events = { sgs.GameStart, sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			local selfplayer = room:findPlayerBySkillName(self:objectName())
			if selfplayer:getMark("@Spkprison") == 0 then
				selfplayer:gainMark("@Spkprison")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Start then return end
			local selfplayer = room:findPlayerBySkillName(self:objectName())
			if selfplayer:getMark("@Spkprison") == 0 then return end
			if player:objectName() == selfplayer:objectName() then return end
			if player:hasSkill(self:objectName()) then return end
			if not room:askForSkillInvoke(selfplayer, self:objectName(), data) then return end
			selfplayer:loseMark("@Spkprison")
			player:drawCards(3)
			local prompt = string.format("@rokugive:%s:%s:%s", player:getGeneralName(), selfplayer:getGeneralName(),
				self:objectName())
			local excards = room:askForExchange(player, self:objectName(), 4, true, prompt, false)
			selfplayer:obtainCard(excards, false)
			return false
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--------------------------------------------------------------奇迹宣言@bernkastel
erciyuan_qiji = sgs.CreateTriggerSkill
	{
		name = "erciyuan_qiji",
		events = sgs.Dying,
		frequency = sgs.Skill_NotFrequent,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local dying = data:toDying()
			if not dying.damage or not dying.damage.from or dying.damage.from:objectName() == dying.who:objectName()
				or dying.who:getMark("@miracle") > 0
				or not room:askForSkillInvoke(player, self:objectName(), data) then
				return false
			end
			dying.who:gainMark("@miracle")
			room:broadcastSkillInvoke("erciyuan_qiji")
			local judge = sgs.JudgeStruct()
			judge.negative = true
			judge.play_animation = false
			judge.who = dying.who
			judge.pattern = "."
			judge.good = false
			judge.reason = self:objectName()
			judge.time_consuming = true
			room:judge(judge)
			local tjudge = sgs.JudgeStruct()
			tjudge.negative = false
			tjudge.play_animation = true
			tjudge.who = dying.damage.from
			tjudge.pattern = ".|.|" .. judge.card:getNumber()
			tjudge.good = true
			tjudge.reason = self:objectName()
			tjudge.time_consuming = true
			room:judge(tjudge)
			if tjudge:isGood() then
				local recov = sgs.RecoverStruct()
				recov.who = player
				recov.recover = dying.who:getMaxHp() - dying.who:property("hp"):toInt()
				room:recover(dying.who, recov)
				room:loseHp(dying.damage.from, math.max(dying.damage.from:property("hp"):toInt(), 0))
			end
			return false
		end
	}
--------------------------------------------------------------碎片筛选@bernkastel
suipian = sgs.CreateTriggerSkill
	{
		name = "suipian",
		events = sgs.AskForRetrial,
		frequency = sgs.Skill_NotFrequent,
		priority = 3,
		on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local judge = data:toJudge()
			local invoked = false
			local x = 0
			while room:askForSkillInvoke(player, self:objectName(), data) do
				room:broadcastSkillInvoke("suipian")
				invoked = true
				local card = sgs.Sanguosha:getCard(room:drawCard())
				room:retrial(card, player, judge, self:objectName())
				x = x + 1
				if x > 50 then
					break
				end
			end
			return invoked
		end
	}
--------------------------------------------------------------圣枪@hibiki
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
LuaGungnir = sgs.CreateTriggerSkill {
	name = "LuaGungnir",
	events = { sgs.TargetSpecified, sgs.ConfirmDamage, sgs.CardUsed, sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			if player:hasSkill(self:objectName()) and player:getWeapon() then
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				room:broadcastSkillInvoke("LuaGungnir", math.random(1, 2))
				local index = 1
				for _, p in sgs.qlist(use.to) do
					jink_table[index] = 0
					local log = sgs.LogMessage()
					log.type = "#skill_cant_jink"
					log.from = player
					log.to:append(p)
					log.arg = self:objectName()
					room:sendLog(log)
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from:hasSkill(self:objectName()) then
				--	room:setPlayerMark(damage.from,"GungnirSlash",damage.from:getMark("GungnirSlash")+1)
				if damage.to:getHp() > damage.from:getHp() then
					damage.damage = damage.damage + 1
					local log = sgs.LogMessage()
					log.type = "#skill_add_damage"
					log.from = damage.from
					log.to:append(damage.to)
					log.arg  = self:objectName()
					log.arg2 = damage.damage
					room:sendLog(log)
					data:setValue(damage)
				elseif damage.to:getHp() <= damage.from:getHp() then
					if damage.from:isWounded() then
						local rcv = sgs.RecoverStruct()
						rcv.recover = 1
						rcv.who = damage.from
						room:recover(damage.from, rcv)
						room:sendCompulsoryTriggerLog(damage.from, self:objectName(), true)
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				if player:hasSkill(self:objectName()) then
					--	if player:getMark("GungnirSlash") == 0 then return end
					if player:getMark("damage_point_round") == 0 then return end
					room:broadcastSkillInvoke("LuaGungnir", 3)
					room:sendCompulsoryTriggerLog(player, self:objectName(), true)
					local log = sgs.LogMessage()
					log.from = player
					log.arg = player:getMark("damage_point_round")
					log.type = "#LuaGungnir_num"
					room:sendLog(log)
					room:askForDiscard(player, self:objectName(), player:getMark("damage_point_round"),
						player:getMark("damage_point_round"), false, true)
					--		room:setPlayerMark(player,"GungnirSlash",0)
				end
			end
		end
	end,
}
--------------------------------------------------------------同步@hibiki
luasynchrogazer = sgs.CreateViewAsSkill {
	name = "luasynchrogazer",
	n = 0,
	view_as = function(self, cards)
		return luasynchrogazercard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luasynchrogazercard")
	end
}
luasynchrogazercard = sgs.CreateSkillCard {
	name = "luasynchrogazercard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		--room:broadcastSkillInvoke("luasynchrogazer",1)
		room:broadcastSkillInvoke("luasynchrogazer", 2)
		::lab::
		ResPlayers, targets = getmoesenlist(room, source, "@zessho")
		room:setPlayerFlag(source, "SucSyn")
		if ResPlayers:length() > 3 or (targets:length() < 1) or (ResPlayers:length() == 0) then
			local msg = sgs.LogMessage()
			msg.type = "#moesenFailure"
			msg.from = source
			msg.arg = ResPlayers:length()
			room:sendLog(msg)
			return
		end
		local useslash = false
		local target = room:askForPlayerChosen(source, targets, "luasynchrogazer_Target")
		for _, p in sgs.qlist(ResPlayers) do
			local prompt = string.format("@SynSlash:%s:%s", source:objectName(), target:objectName())
			if room:askForUseSlashTo(p, target, prompt, false, false, false) then
				useslash = true
				local drawp = room:askForPlayerChosen(source, ResPlayers, "luasynchrogazer_Friend")
				drawp:drawCards(1)
			else
				useslash = false
				break
			end
		end
		if useslash then
			goto lab
		end
	end
}
--------------------------------------------------------------绝唱@战姬绝唱——系列人物
LuaZessho = sgs.CreateTriggerSkill {
	name = "#LuaZessho",
	events = { sgs.GameStart },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "@zessho", 1)
	end,
	priority = 3
}
--------------------------------------------------------------苍闪@kntsubasa
LuaCangshan = sgs.CreateViewAsSkill {
	name = "LuaCangshan",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		local weapon = sgs.Self:getWeapon()
		if (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY) and sgs.Self:getWeapon()
			and (to_select:getEffectiveId() == sgs.Self:getWeapon():getId()) and to_select:isKindOf("Crossbow") then
			return sgs.Self:canSlashWithoutCrossbow()
		else
			return to_select:isKindOf("EquipCard")
		end
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local originalCard = cards[1]
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		local reason = sgs.Sanguosha:getCurrentCardUseReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			slash:addSubcard(originalCard:getId())
			slash:setSkillName(self:objectName())
			return slash
		elseif (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local rescard = sgs.Sanguosha:cloneCard(pattern, originalCard:getSuit(), originalCard:getNumber())
			rescard:addSubcard(originalCard:getId())
			rescard:setSkillName(self:objectName())
			return rescard
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash") or (pattern == "jink")
	end,
}
LuaCangshanTMS = sgs.CreateTargetModSkill {
	name = "#LuaCangshanTMS",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("LuaCangshan") then
			if card:getSkillName() == "LuaCangshan" then
				return 1000
			end
		end
	end
}
LuaCangshanTrig = sgs.CreateTriggerSkill {
	name = "#LuaCangshanTrig",
	Frequency = sgs.Skill_Compulsory,
	events = { sgs.CardResponded, sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = nil
		if event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		elseif event == sgs.CardUsed then
			card = data:toCardUse().card
		end
		if card:getSkillName() == "LuaCangshan" then
			player:drawCards(1)
		end
	end,
}
--------------------------------------------------------------月煌@kntsubasa
luayuehuang = sgs.CreateViewAsSkill {
	name = "luayuehuang",
	n = 0,
	view_as = function(self, cards)
		return luayuehuangcard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luayuehuangcard")
	end
}
luayuehuangcard = sgs.CreateSkillCard {
	name = "luayuehuangcard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		--room:broadcastSkillInvoke("luayuehuang",math.random(1,2))
		ResPlayers, targets = getmoesenlist(room, source, "@zessho")
		room:setPlayerFlag(source, "SucYh")
		if ResPlayers:length() > 3 then
			local msg = sgs.LogMessage()
			msg.type = "#moesenFailure"
			msg.from = source
			msg.arg = ResPlayers:length()
			room:sendLog(msg)
			return
		end
		ResPlayers:removeOne(source)
		room:setPlayerMark(source, "@yuehuang", source:getMark("@yuehuang") + 1)
		for _, p in sgs.qlist(ResPlayers) do
			local prompt = string.format("@YuehuangGive:%s:%s", p:objectName(), source:objectName())
			local card = room:askForCard(p, "EquipCard|.|.", prompt, sgs.QVariant(), sgs.Card_MethodResponse)
			if card then
				room:obtainCard(source, card)
				room:setPlayerMark(source, "@yuehuang", source:getMark("@yuehuang") + 1)
			end
		end
		ResPlayers:append(source)
		for _, p in sgs.qlist(ResPlayers) do
			p:drawCards(source:getMark("@yuehuang"))
		end
	end
}
luayuehuangSlash = sgs.CreateTargetModSkill {
	name = "#luayuehuangSlash",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			if player:hasUsed("#luayuehuangcard") then
				return player:getMark("@yuehuang")
			end
		end
	end,
}
luayuehuangClear = sgs.CreateTriggerSkill {
	name = "#luayuehuangClear",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				if player:hasSkill(self:objectName()) then
					room:setPlayerMark(player, "@yuehuang", 0)
				end
			end
		end
	end,
}
--------------------------------------------------------------镜鸣@khntmiku
LuaJingming = sgs.CreateTriggerSkill {
	name = "LuaJingming",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		for _, miku in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if change.to == sgs.Player_Start then
				if player:objectName() ~= miku:objectName() then
					if miku:canDiscard(miku, "he") then
						local newdata = sgs.QVariant()
						newdata:setValue(player)
						local prompt = string.format("@jmdiscard:%s:%s", miku:objectName(), player:objectName())
						if room:askForCard(miku, "..", prompt, newdata, self:objectName()) then
							room:broadcastSkillInvoke("LuaJingming", 1)
							room:setPlayerMark(player, "noslash_jm", 1)
							room:setPlayerCardLimitation(player, "use", "Slash", true)
							room:addPlayerMark(player, "&LuaJingming+to+#" + miku:objectName())
						end
					end
				end
			elseif change.from == sgs.Player_Finish then
				if player:getMark("noslash_jm") == 0 then return end
				if player:objectName() ~= miku:objectName() and player:getMark("&LuaJingming+to+#" .. miku:objectName()) > 0 then
					local choice
					room:broadcastSkillInvoke("LuaJingming", 2)
					if player:isWounded() then
						choice = room:askForChoice(miku, self:objectName(), "recover+eachdraw+cancel")
					else
						choice = room:askForChoice(miku, self:objectName(), "eachdraw+cancel")
					end
					room:setPlayerMark(player, "noslash_jm", 0)
					room:setPlayerMark(player, "&LuaJingming+to+#" .. miku:objectName(), 0)

					if choice == "recover" then
						local rcv = sgs.RecoverStruct()
						rcv.recover = 1
						rcv.who = player
						room:recover(player, rcv)
					elseif choice == "eachdraw" then
						player:drawCards(2)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			return not target:hasSkill(self:objectName())
		end
		return false
	end,
}
--------------------------------------------------------------映现@khntmiku
luayingxian = sgs.CreateViewAsSkill {
	name = "luayingxian",
	n = 0,
	view_as = function(self, cards)
		return luayingxiancard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luayingxiancard")
	end
}
luayingxiancard = sgs.CreateSkillCard {
	name = "luayingxiancard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		--room:broadcastSkillInvoke("luayingxian",math.random(1,2))
		ResPlayers, targets = getmoesenlist(room, source, "@zessho")
		room:setPlayerFlag(source, "Sucyx")
		if ResPlayers:length() > 3 or (ResPlayers:length() == 0) then
			local msg = sgs.LogMessage()
			msg.type = "#moesenFailure"
			msg.from = source
			msg.arg = ResPlayers:length()
			room:sendLog(msg)
			return
		end
		local yxnum = 0
		for _, p in sgs.qlist(ResPlayers) do
			if p:getHandcardNum() > 0 then
				local card = room:askForCardShow(p, source, self:objectName())
				room:showCard(p, card:getEffectiveId())
				local point = card:getNumber()
				yxnum = yxnum + point
			end
		end
		local x = math.ceil(math.pow(yxnum, 0.5))
		local cards = room:getNCards(x)
		local move = sgs.CardsMoveStruct()
		move.card_ids = cards
		move.to = source
		move.to_place = sgs.Player_PlaceHand
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SHOW, source:objectName(), self:objectName(), nil)
		room:moveCardsAtomic(move, false)

		while room:askForYiji(source, cards, self:objectName(), false, false, false, -1, ResPlayers) do end
	end
}
--------------------------------------------------------------扫射@yukinechris
luasaoshecard = sgs.CreateSkillCard {
	name = "luasaoshecard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets < 1 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				local noneslash = sgs.Sanguosha:cloneCard("Slash")
				if to_select:isCardLimited(noneslash, sgs.Card_MethodUse) then return false end
				if to_select:isProhibited(sgs.Self, noneslash, sgs.Self:getSiblings()) then return false end
				if to_select:getMark("SaosheX") > 1 then return false end
				return sgs.Self:distanceTo(to_select) <= sgs.Self:getAttackRange()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:setPlayerMark(target, "SaosheX", target:getMark("SaosheX") + 1)
		room:obtainCard(target, self, false)
		local subcards = self:getSubcards()
		local old_value = source:getMark("Saoshe")
		local new_value = old_value + subcards:length()
		room:setPlayerMark(source, "Saoshe", new_value)
		if old_value < 2 then
			if new_value >= 2 then
				--room:broadcastSkillInvoke("luasaoshe",1)
				if source:isWounded() then
					if room:askForChoice(source, self:objectName(), "recover+draw") == "recover" then
						local recover = sgs.RecoverStruct()
						recover.who = source
						room:recover(source, recover)
					else
						room:drawCards(source, 2)
					end
				else
					room:drawCards(source, 2)
				end
			end
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("luasaoshe")
		slash:deleteLater()
		room:useCard(sgs.CardUseStruct(slash, source, target))
		room:addPlayerHistory(source, slash:getClassName(), -1)
	end
}
luasaosheVS = sgs.CreateViewAsSkill {
	name = "luasaoshe",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local Saoshe_card = luasaoshecard:clone()
			local id = cards[1]:getId()
			Saoshe_card:addSubcard(id)
			return Saoshe_card
		end
	end
}
luasaoshe = sgs.CreateTriggerSkill {
	name = "luasaoshe",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = luasaosheVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "Saoshe", 0)
		room:setPlayerMark(player, "SaosheX", 0)
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() then
				if target:getPhase() == sgs.Player_Play then
					return true
				end
			end
		end
		return false
	end
}
--------------------------------------------------------------敌忾@yukinechris
LuaDikai = sgs.CreateTriggerSkill {
	name = "LuaDikai",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		for _, yukine in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if room:askForSkillInvoke(yukine, self:objectName(), data) then
				room:broadcastSkillInvoke("LuaJingming", math.random(1, 2))
				room:drawCards(yukine, 1)
				if damage.from and yukine:canDiscard(damage.from, "he") then
					local card_id = room:askForCardChosen(yukine, damage.from, "he", self:objectName())
					room:throwCard(card_id, damage.from, yukine)
				end
				if yukine:objectName() ~= player:objectName() then
					local prompt = string.format("@dikai:%s:%s", yukine:getGeneralName(), player:objectName())
					local card = room:askForCard(yukine, "EquipCard,Slash|.|.", prompt, data, self:objectName())
					player:obtainCard(card, true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() then
				if target:getMark("@zessho") > 0 then
					return target
				end
			end
		end
		return false
	end,
}
------------------------------------------------------------------------翻译添加区
yj:addSkill(GuanchuanSkill)
yj:addSkill(ZhuishaSkill)
yj:addSkill(CixiongSkill)
yj:addSkill(HuoshanSkill)
yj:addSkill(BaojiSkill)
yj:addSkill(HanbingSkill)
yj:addSkill(ShemaSkill)
yj:addSkill(ZhangbaSkill)
yj:addSkill(HuajiSkill)
yj:addSkill(LuaChitian)
yj:addSkill(luajianyu)
yj:addSkill(LuaJiguangAsk)
yj:addSkill(LuaGaokang)
yj:addSkill(LuaGaoxiao)
yj:addSkill(LuaYinbao)
yj:addSkill(LuaKuanggu)
yj:addSkill(LuaWushuang)
yj:addSkill(LuaPaoxiao)
yj:addSkill(LuaKuangshi)
yj:addSkill(LuaXiuluo)
itomakoto:addSkill(luarenzha)
itomakoto:addSkill(ak_renzha)
ayanami:addSkill(weixiao)
ayanami:addSkill(nvshen)
keima:addSkill(LuaShenzhi)
keima:addSkill(luagonglue)
SPkirito:addSkill(LuaChanshi)
SPkirito:addSkill(LuaZhuan)
odanobuna:addSkill(LuaChigui)
odanobuna:addSkill(LuaBuwu)
odanobuna:addSkill(LuaTianmo)
odanobuna:addSkill(LuaTianmoDefense)
extension:insertRelatedSkills("LuaTianmoDefense", "#LuaTianmo")
yuuta:addSkill(LuaWangxiang)
yuuta:addSkill(luablackflame)
tsukushi:addSkill(LuaGqset)
tsukushi:addSkill(LuaGqef)
extension:insertRelatedSkills("LuaGqset", "#LuaGqef")
tsukushi:addSkill(luatiaojiao)
batora:addSkill(LuaBuqi)
mao_maoyu:addSkill(luaboxue)
sheryl:addSkill(LuaYaojing)
sheryl:addSkill(LuaGongming)
sheryl:addSkill(LuaYaojingSound)
extension:insertRelatedSkills("LuaYaojing", "#LuaYaojingSound")
aoitori:addSkill(LuaLuowang)
kyouko:addSkill(LuaLuoshen)
diarmuid:addSkill(LuaPomo)
diarmuid:addSkill(LuaBimie)
diarmuid:addSkill(LuaBimieHprcvForbidden)
diarmuid:addSkill(LuaBimieLost)
extension:insertRelatedSkills("LuaBimie", "#LuaBimieHprcvForbidden")
extension:insertRelatedSkills("LuaBimie", "#LuaBimieLost")
ikarishinji:addSkill(LuaBaozou)
ikarishinji:addSkill(LuaXinbi)
ikarishinji:addSkill(LuaBaozouDying)
ikarishinji:addSkill(LuaBaozouSound)
extension:insertRelatedSkills("LuaBaozou", "#LuaBaozouDying")
extension:insertRelatedSkills("LuaKuangshi", "#LuaBaozouSound")
ikarishinji:addRelateSkill("xiuluo")
ikarishinji:addRelateSkill("wushuang")
ikarishinji:addRelateSkill("kuanggu")
ikarishinji:addRelateSkill("LuaYinbao")
ikarishinji:addRelateSkill("LuaKuangshi")
ikarishinji:addRelateSkill("paoxiao")
redarcher:addSkill(luatouying)
redarcher:addSkill(LuaGongqi)
redarcher:addSkill(LuaGongqiTargetMod)
extension:insertRelatedSkills("LuaGongqi", "#LuaGongqi-target")
redarcher:addSkill(luatouyingClear)
extension:insertRelatedSkills("luatouying", "#luatouyingClear")
redarcher:addSkill(luatouying_equip)
extension:insertRelatedSkills("luatouying", "#luatouying_equip")
redarcher:addSkill(LuaJianyong)
redarcher:addSkill(LuaJianzhi)
redarcher:addSkill(LuaJianzhiGive)
extension:insertRelatedSkills("LuaJianzhi", "#LuaJianzhiGive")
redarcher:addRelateSkill("luajianyu")
redarcher:addRelateSkill("LuaChitian")
redo:addSkill(LuaRedoWake)
redo:addSkill(LuaChamberStart)
redo:addSkill(LuaChamberMove)
extension:insertRelatedSkills("LuaChamberMove", "#LuaChamberStart")
redo:addSkill(LuaJiguangMod)
extension:insertRelatedSkills("LuaJiguangAsk", "#LuaJiguangMod")
redo:addSkill(LuaRedoNoSlash)
extension:insertRelatedSkills("LuaChamberMove", "#LuaRedoNoSlash")
redo:addRelateSkill("LuaJiguangAsk")
redo:addRelateSkill("LuaGaoxiao")
redo:addRelateSkill("LuaGaokang")
runaria:addSkill(luayukong)
runaria:addSkill(LuaWenle)
runaria:addSkill(LuaQisi)
fuwaaika:addSkill(luaposhi)
fuwaaika:addSkill(luaposhi_Clear)
fuwaaika:addSkill(luaposhiTMS)
extension:insertRelatedSkills("luaposhi", "#luaposhiTMS")
extension:insertRelatedSkills("luaposhi", "#luaposhi_Clear")
fuwaaika:addSkill(LuaLiansuo)
fuwaaika:addSkill(LuaYinguo)
slsty:addSkill(slyanhuo)
slsty:addSkill(zhahu)
rokushikimei:addSkill(LuaHeartlead)
rokushikimei:addSkill(LuaPositionMove)
rokushikimei:addSkill(LuaSpkprison)
bernkastel:addSkill(erciyuan_qiji)
bernkastel:addSkill(suipian)
hibiki:addSkill(luasynchrogazer)
hibiki:addSkill(LuaZessho)
hibiki:addSkill(LuaGungnir)
kntsubasa:addSkill(LuaCangshan)
kntsubasa:addSkill(LuaCangshanTrig)
kntsubasa:addSkill(LuaCangshanTMS)
extension:insertRelatedSkills("LuaCangshan", "#LuaCangshanTrig")
extension:insertRelatedSkills("LuaCangshan", "#LuaCangshanTMS")
kntsubasa:addSkill(luayuehuang)
kntsubasa:addSkill(luayuehuangSlash)
kntsubasa:addSkill(luayuehuangClear)
extension:insertRelatedSkills("luayuehuang", "#luayuehuangSlash")
extension:insertRelatedSkills("luayuehuang", "#luayuehuangClear")
kntsubasa:addSkill(LuaZessho)
khntmiku:addSkill(LuaZessho)
khntmiku:addSkill(LuaJingming)
khntmiku:addSkill(luayingxian)
yukinechris:addSkill(LuaZessho)
yukinechris:addSkill(luasaoshe)
yukinechris:addSkill(LuaDikai)
------------------------------------------------------------------------翻译表区
------------------------------------------------------------------------杂项区
sgs.LoadTranslationTable {
	["HuajiSkill"] = "方天画戟",
	["ShemaSkill"] = "麒麟弓",
	["HanbingSkill"] = "寒冰剑",
	["ZhangbaSkill"] = "丈八蛇矛",
	["CixiongSkill"] = "雌雄双股剑",
	["ZhuishaSkill"] = "青龙偃月刀",
	["GuanchuanSkill"] = "贯石斧",
	["BaojiSkill"] = "古锭刀",
	["HuoshanSkill"] = "朱雀羽扇",
	["@axe"] = "弃置两张牌以发动贯石斧效果",
	["LuaKuanggu"] = "狂骨",
	["LuaXiuluo"] = "修罗",
	["LuaPaoxiao"] = "咆哮",
	["LuaWushuang"] = "无双",
	["@wushuang-jink-1"] = "%src 发动技能【无双】要求你使用第一张闪",
	["@wushuang-jink-2"] = "%src 发动技能【无双】要求你使用第二张闪",
	["LuaChigui-invoke"] = "你可发动技能【赤鬼】",
	["LuaXinbi-invoke"] = "“心壁”被觸發<br/> <b>操作提示</b>: 选择场上有装备牌的一名角色→点击确定<br/>",
	[":LuaKuanggu"] = "每当你对距离1以内的一名角色造成1点伤害后，你回复1点体力",
	[":LuaXiuluo"] = "准备阶段开始时，你可以弃置一张与判定区内延时类锦囊牌花色相同的手牌，然后弃置该延时类锦囊牌",
	[":LuaPaoxiao"] = "你在出牌阶段内使用【杀】时无次数限制。",
	[":LuaWushuang"] = "当你使用【杀】指定一名角色为目标后，该角色需连续使用两张【闪】才能抵消；与你进行【决斗】的角色每次需连续打出两张【杀】。",
	["LuaWenlePush"] = "请将 %src 张手牌置于武将牌上",
	["zha"] = "渣",
	["gang"] = "钢",
	["yong"] = "咏",
	["si"] = "丝",
	["@tianmo"] = "天魔",
	["@zhou"] = "咒",
	["@Chamber"] = "钱伯",
	["@miracle"] = "奇迹",
	["@zessho"] = "絶唱",
	["moesenskill"] = "萌战技",
	["luatiaojiaocard"] = "调教 ",
	["luablackflamecard"] = "黑焰",
	["luagongluecard"] = "攻略",
	["luaboxuecard"] = "博学",
	["luayuehuangcard"] = "月煌",
	["luaboxue"] = "博学",
	["luajianyu"] = "剑雨",
	["luarenzha"] = "好船",
	["luagonglue"] = "攻略",
	["luagongqi"] = "崩坏",
	["luablackflame"] = "黑焰",
	["luatiaojiao"] = "调教",
	["luatouying"] = "投影",
	["luayukong"] = "御空",
	["luasynchrogazer"] = "同步",
	["#luasynchrogazercard"] = "同步",
	["luasynchrogazercard"] = "同步",
	["luasynchrogazer_Target"] = "请指定【杀】的目标。",
	["luasynchrogazer_Friend"] = "请指定摸牌的目标。",
	["#luayuehuangcard"] = "月煌",
	["luayuehuang"] = "月煌",
	["luayingxian"] = "映现",
	["@LuoDraw"] = "选择一名角色并令其摸一张牌",
	["@LuoDis"] = "选择一名角色并弃置其一张牌",
	["@yinguo"] = "请选择一名男性角色",
	["@yinguo2"] = "请选择一名男性角色（若只分给一名角色，则选之前所选的角色。）",
	["@Buqigiving"] = "【布棋】要求你( %src)交给%dest共%arg张手牌。",
	["@rokugive"] = "【语言牢笼】要求你(%src)交给%dest共4张牌（包括装备牌）",
	["@TiaojiaoSlash"] = " %src 发动技能【调教】，要求你( %dest )对 %arg 使用1张杀。",
	["@LuoBaozouKill"] = "选择一名角色令其进入濒死求桃",
	["@jiguang"] = "%src 技能【激光】生效，你须弃置一张非基本牌才能抵消其杀。",
	["@SynSlash"] = "%src  发动技能【同步】让你对 %dest 使用一张杀。",
	["@YuehuangGive"] = "%dest发动技能【月煌】让你（%src）交给 %dest 一张装备牌 ",
	["@dikai"] = "你（%src） 发动技能【敌忾】，可交给 %dest 一张【杀】或一张装备牌。",
	["@jmdiscard"] = "你（%src） 可弃置一张牌以发动技能【镜鸣】，使 %dest 不能使用【杀】直到回合结束。",
	["a"] = "令一名角色摸牌",
	["b"] = "令一名角色弃牌",
	["recover"] = "回复1点体力",
	["eachdraw"] = "该角色摸两张牌",
	["draw"] = "摸两张牌",
	["throw"] = "弃置",
	["gx"] = "以任意顺序置于牌堆顶",
	["youdraw"] = "你摸X张牌",
	["hedraws"] = "令其摸X张牌",
	["throwtableequip"] = "弃置场上一张装备牌",
	["loseonehp"] = "失去1点体力",
	["turnoverself"] = "翻面",
	["chained"] = "横置",
	["#TianmoDefense"] = "%from 失去1个’天魔‘标记，防止了此次扣减体力。 ",
	["erciyuan"] = "动漫包-AK",

	["@LuaGongming-to"] = "你可以发动“共鸣”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",

	["#moesenFailure"] = "%from 的<font color=\"Sky Blue\"><b>萌战技</b></font>发动失敗，参战角色為 %arg 人。",
	["#LuaGungnir_num"] = "本回合 %from 的伤害量為 %arg ",
	["@LuaQisi-card"] = "你可以弃置一张“丝”，若该角色的攻击范围小于“丝”点数的一半（向下取整），取消之。",
	["~LuaQisi"] = "选择一张“丝”→点击确定<br/>",
}
------------------------------------------------------------------------武将描述区
sgs.LoadTranslationTable {
	["keima"] = "桂木桂马",
	["#keima"] = "神大人",
	["#luagongluecard"] = "攻略",
	["luagonglue"] = "攻略",
	["LuaShenzhi"] = "神知",
	["#ayanami"] = "女神",
	["ayanami"] = "绫波丽",
	["weixiao"] = "微笑",
	["weixiao_dis"] = "微笑",
	["nvshen"] = "女神",
	["#itomakoto"] = "好船人渣",
	["itomakoto"] = "伊藤诚",
	["ak_renzha"] = "人渣",
	["luarenzha"] = "好船",
	["SPkirito"] = "SP桐人",
	["#SPkirito"] = "黑色剑士",
	["LuaChanshi"] = "阐释",
	["LuaZhuan"] = "逐暗",
	["odanobuna"] = "织田信奈",
	["#odanobuna"] = "第六天魔王",
	["LuaBuwu"] = "布武",
	["LuaChigui"] = "赤鬼",
	["LuaTianmoDefense"] = "天魔",
	["yuuta"] = "富樫勇太",
	["#yuuta"] = "漆黑烈焰使",
	["LuaWangxiang"] = "妄想",
	["luablackflame"] = "黑焰",
	["tsukushi"] = "筒隐筑紫",
	["#tsukushi"] = "钢铁之王",
	["LuaGqset"] = "钢躯",
	["luatiaojiao"] = "调教",
	["batora"] = "魔·右代宫战人",
	["#batora"] = "无限黄金魔术师",
	["LuaBuqi"] = "布棋",
	["mao_maoyu"] = "魔王",
	["#mao_maoyu"] = "红玉之瞳",
	["luaboxue"] = "博学",
	["sheryl"] = "雪莉露·诺姆",
	["#sheryl"] = "银河的妖精",
	["LuaGongming"] = "共鸣",
	["LuaYaojing"] = "妖精",
	["aoitori"] = "葵·托利",
	["#aoitori"] = "不可能之男",
	["LuaLuowang"] = "裸王",
	["kyouko"] = "佐仓杏子",
	["#kyouko"] = "红色幽灵",
	["LuaLuoshen"] = "强气",
	["diarmuid"] = "迪卢木多",
	["#diarmuid"] = "光辉之貌",
	["LuaPomo"] = "破魔",
	["LuaBimie"] = "必灭",
	["ikarishinji"] = "碇シンジ",
	["#ikarishinji"] = "中二少年",
	["LuaKuangshi"] = "狂噬",
	["LuaBaozou"] = "暴走",
	["LuaXinbi"] = "心壁",
	["LuaYinbao"] = "音爆",
	["redarcher"] = "英灵卫宫",
	["#redarcher"] = "冶炼的英雄",
	["luatouying"] = "投影",
	["LuaGongqi"] = "崩坏",
	["LuaJianyong"] = "剑咏",
	["luajianyu"] = "剑雨",
	["LuaJianzhi"] = "剑制",
	["LuaChitian"] = "炽天",
	["redo"] = "雷德",
	["#redo"] = "翠星的探索者",
	["LuaRedoWake"] = "去死吧，铁皮混蛋！",
	["LuaChamberMove"] = "钱伯",
	["LuaGaoxiao"] = "高效",
	["LuaGaokang"] = "高抗",
	["LuaJiguangAsk"] = "激光",
	["runaria"] = "露娜莉亚",
	["#runaria"] = "月长石",
	["LuaWenle"] = "文乐",
	["LuaQisi"] = "绮丝",
	["luaqisi"] = "绮丝",
	["luayukong"] = "御空",
	["fuwaaika"] = "不破爱花",
	["#fuwaaika"] = "绝园的魔法使",
	["luaposhi"] = "破始",
	["LuaLiansuo"] = "连锁",
	["LuaYinguo"] = "因果",
	["slsty"] = "塞蕾丝缇雅",
	["#slsty"] = "超高校级的赌徒",
	["slyanhuo"] = "言惑",
	["confuse"] = "言惑",
	["yanhuoacquire"] = "言惑翻牌",
	["zhahu"] = "诈唬",
	["rokushikimei"] = "六识命",
	["#rokushikimei"] = "心灵梦魇",
	["LuaHeartlead"] = "心灵诱导",
	["LuaPositionMove"] = "藏位转移",
	["LuaSpkprison"] = "语言牢笼",
	["bernkastel"] = "贝伦卡斯泰露",
	["#bernkastel"] = "奇迹之魔女",
	["erciyuan_qiji"] = "奇迹宣言",
	["suipian"] = "碎片筛选",
	["hibiki"] = "立花響",
	["#hibiki"] = "永恒之枪",
	["luasynchrogazer"] = "同步",
	["LuaGungnir"] = "圣枪",
	["kntsubasa"] = "風鳴翼",
	["#kntsubasa"] = "天羽羽斩",
	["LuaCangshan"] = "苍闪",
	["luayuehuang"] = "月煌",
	["khntmiku"] = "小日向未来",
	["#khntmiku"] = "神兽镜",
	["LuaJingming"] = "镜鸣",
	["luayingxian"] = "映现",
	["yukinechris"] = "雪音クリス",
	["#yukinechris"] = "魔弓",
	["luasaoshe"] = "扫射",
	["LuaDikai"] = "敌忾",
}
------------------------------------------------------------------------技能描述区
sgs.LoadTranslationTable {
	[":luatiaojiao"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名角色选择一项：对一名你指定的其他角色使用一张【杀】，或令你获得其区域内的一张牌。",
	[":LuaWangxiang"] = "当你的手牌数不多于你已损失的体力值时，你可以将一张手牌当【无中生有】使用。",
	[":LuaGqset"] = "结束阶段开始时，你可以将一张手牌置于你的武将牌上，称为“钢”，然后同类型的牌对你无效直至你下一回合的准备阶段。你的准备阶段开始时，若你的武将牌上有“钢”，须将“钢”弃置。（“钢”至多存在1张）",
	[":luablackflame"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可失去1点体力，然后对一名角色造成1点火焰伤害。",
	[":LuaBuwu"] = "每当你造成一次伤害后，你可令受到伤害的角色将其武将牌翻面，然后该角色摸等同于其体力值-1张牌。",
	[":LuaChigui"] = "结束阶段开始时，你可失去1点体力，获得1名其他角色装备区内的武器牌，然后摸X张牌，直到场上没有武器牌。（X为你的血量）",
	[":LuaTianmoDefense"] = "当你使用的【杀】被【闪】抵消时，你获得1枚“天魔”标记。当扣减你的体力时，你可弃置1枚“天魔”标记，防止此次扣减体力。",
	[":LuaChanshi"] = "你的【杀】可以额外指定1个目标。",
	[":LuaZhuan"] = "你每使用一张黑【杀】，可以摸一张牌，每使用一张【决斗】，可以摸两张牌",
	[":luarenzha"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张“渣”,然后恢复X点体力并将你的武将牌翻面，视作你发动了一次技能“乱武”。（X为“渣”的数量）",
	["ak_renzhaPush"] = "请将一张手牌置于武将牌上",
	[":ak_renzha"] = "每当你受到1点伤害后，你摸两张牌并将一张手牌置于你的武将牌上，称为“渣”，然后你可将武将牌翻面并摸一张牌。",
	["weixiaoPush"] = "你可选择弃置两张牌然后发动“微笑”",
	[":weixiao"] = "结束阶段开始时，你可选择弃置两张牌然后选择一项；令一名角色摸X张牌，或令一名角色弃置Y张牌（X为弃牌中较小点数的一半，向下取整；Y为弃牌中较大点数的一半，向上取整）",
	[":LuaShenzhi"] = "准备阶段或结束阶段开始时，你可以观看牌堆顶的X张牌，然后将任意数量的牌以任意顺序置于牌堆顶，将其余的牌以任意顺序置于牌堆底。（X为存活角色数且至多为4。)",
	[":luagonglue"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可观看一名角色的手牌，然后选择其中一张牌并获得之。",
	[":nvshen"] = "<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限+X（X为你的体力上限）。",
	[":LuaBuqi"] = "游戏开始时或你受到一次伤害后，你可获得所有其他角色手牌，并由当前回合角色开始，依次交给每名其他角色等同于其原有手牌张数的手牌。",
	[":luaboxue"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可指定X名角色并亮出牌堆顶X张牌，然后你摸X/2(向上取整)张牌，指定角色依次与之交换一张牌（包括装备牌），然后你将其余的牌弃置。", --或以任意顺序置于牌堆顶。",
	[":LuaYaojing"] = "出牌阶段，你可将一张手牌当【桃园结义】使用。",
	[":LuaGongming"] = "你的回合内，每有一名角色回复体力，你可以令其摸X张牌，或你摸X张牌。（X为你已损失体力值+ 1）。",
	[":LuaLuowang"] = "摸牌阶段结束时，你可以展示所有手牌。其中每有一种红色花色，你可令一名角色摸一张牌。然后每有一种黑色花色，你可弃置一名角色的一张牌。",
	[":LuaLuoshen"] = "准备阶段开始时，你可以进行一次判定，然后你获得生效后的判定牌且你可以重复此流程，直到判定结果为【杀】。",
	[":LuaPomo"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用【杀】时，无视目标角色的防具。",
	[":LuaBimie"] = "每当你使用的【杀】造成伤害后，你可令受到伤害的角色获得1枚“咒”标记，拥有该标记的角色回复体力时，取消之。你死亡时，弃置场上所有的”咒“标记。",
	[":LuaBaozou"] = " 你在“暴走”回合外的濒死状态结算后，你可以暂停一切结算，发动以下效果且防止进入濒死状态直到该效果结束，然后继续暂停的结算：你进行一个额外的回合并于此回合内获得以下技能：“无双”、“咆哮”、“狂骨”、“猛噬”（锁定技，你的基本牌均视为【杀】，你的锦囊牌均视为【决斗】）“音爆”（锁定技，你计算与其他角色的距离始终为1）。以此法获得的回合内造成伤害后，若你的血量超过1，你本回合不能使用基本牌或锦囊牌。",
	[":LuaKuangshi"] = "<font color=\"blue\"><b>锁定技，</b></font>你的基本牌均视为【杀】，你的锦囊牌均视为【决斗】。",
	[":LuaXinbi"] = "<font color=\"blue\"><b>锁定技，</b></font>你因“暴走”外的方式执行的回合的结束阶段开始时，你弃置场上一张装备牌或失去1点体力；<font color=\"blue\"><b>锁定技，</b></font>当你于摸牌阶段外获得三张或更多牌时，若你於“暴走”外的回合，每获得两张，你失去1点体力，当前回合角色摸一张牌。",
	[":LuaYinbao"] = "<font color=\"blue\"><b>锁定技，</b></font>你计算的与其他角色距离为1。",
	[":luatouying"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>若你的装备区没有武器，你可以声明一种武器，获得其特效直到回合结束。",
	[":LuaGongqi"] = "你可以将一张装备牌当无距离限制的【杀】使用。",
	[":LuaJianyong"] = "弃牌阶段开始时，你可以摸一张牌并将一张手牌置于武将牌上，称为”咏“。",
	[":luajianyu"] = "你可以将等同于存活角色数的”咏“当一张【万箭齐发】使用。",
	[":LuaChitian"] = "你可以将一张”咏“当作【杀】或【闪】使用或打出。",
	[":LuaJianzhi"] = "<font color=\"purple\"><b>觉醒技，</b></font>结束阶段开始时，若你的”咏“的数量达到两张或更多时，你减1点体力上限，获得每名其他角色各一张手牌并置于你的武将牌上，然后获得技能”剑雨“和”炽天“，此回合结束后进行一个额外的回合，",
	[":LuaRedoWake"] = "<font color=\"purple\"><b>觉醒技，</b></font>出牌阶段开始时，若你的体力值为1，你失去“钱伯”标记，回复1点体力，然后对一名其他角色造成3点雷电伤害。",
	[":LuaChamberMove"] = "游戏开始时，你弃置两张牌并获得标记“钱伯”，你可以于准备阶段开始时获得标记“钱伯”，或将其移出游戏：若你拥有“钱伯”标记，你拥有以下技能“激光”“高效”“高抗”；若你没有，你不能成为【杀】的目标。",
	[":LuaGaoxiao"] = "摸牌阶段摸牌时，你可以额外摸一张牌。",
	[":LuaJiguangAsk"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用【杀】时无距离限制，且目标角色须弃置一张非基本牌以抵消之",
	[":LuaGaokang"] = "<font color=\"blue\"><b>锁定技，</b></font>若你有牌，你受到的非属性伤害-1且你弃置一张牌。",
	[":LuaWenle"] = "<font color=\"blue\"><b>锁定技，</b></font>摸牌阶段摸牌时，你额外摸X张牌，然后摸牌阶段结束时将X张牌背面朝上置于武将牌上称为“丝”（X为存活角色数的一半，向下取整）。准备阶段开始时，你须弃置所有的“丝”，然后摸等量的牌。",
	[":LuaQisi"] = "【杀】或非延时类锦囊对你生效前，你可以弃置一张“丝”，若该角色的攻击范围小于“丝”点数的一半（向下取整），取消之。",
	[":luayukong"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张“丝”，然后你计算和其他角色的距离为1，直到回合结束。",
	[":luaposhi"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可失去1点体力，然后你无视与其他角色的距离和其他角色的防具；且你使用杀时无使用次数限制，直到回合结束。",
	[":LuaLiansuo"] = "每名其他角色的回合限两次，其他角色的牌因弃置而置入弃牌堆时，你可以摸一张牌",
	[":LuaYinguo"] = "<font color=\"red\"><b>限定技，</b></font>你死亡后，可以将所有手牌交给至多两名男性角色，然后指定的角色再摸等同于交给其手牌张数的牌。",
	[":slyanhuo"] = "出牌阶段，你可以将一张手牌背面朝上置于武将牌上，称为“惑”（惑最多为当前场上人数且最多为5），然后你摸一张牌。其他角色的出牌阶段限一次，可以翻开一张你的“惑”。你受到伤害后，可令伤害来源翻开你指定的一张“惑”。",
	[":zhahu"] = "<font color=\"blue\"><b>锁定技，</b></font>翻开“惑”的角色须执行以下效果并弃置“惑”，黑桃，回复1点体力，红桃，失去1点体力，梅花，摸两张牌，方块，你弃置其一张牌；准备阶段开始时，你须翻开你所有的“惑”。",
	[":LuaHeartlead"] = "其他角色的基本牌或非延时类锦囊牌指定一名角色为目标时，你可以将武将牌翻面或横置，然后该角色指定另一名角色为此牌的唯一目标。",
	[":LuaPositionMove"] = "<font color=\"blue\"><b>锁定技，</b></font>你受到的伤害结算开始时，若你有两张或更多手牌且你的武将牌横置或背面朝上，你弃置两张牌并防止此伤害，然后将你的武将牌翻至正面并重置。",
	[":LuaSpkprison"] = "<font color=\"red\"><b>限定技，</b></font>一名其他角色的准备阶段开始时，你可以令其摸三张牌，然后该角色须交给你四张牌。",
	[":erciyuan_qiji"] = "当一名角色受到其他角色伤害而进入濒死状态时，你可令该角色和伤害来源各进行一次判定；若判定点数相同，则该角色体力恢复至其体力上限，伤害来源失去全部体力。（该技能对一名角色一局游戏只能使用一次）",
	[":suipian"] = "在一名角色的判定牌生效前，你可用牌堆顶牌代替判定牌且你可重复此流程。",
	[":LuaGungnir"] = "<font color=\"blue\"><b>锁定技，</b></font>若你装备有武器，你的【杀】不能被【闪】响应。你对体力值比你多的角色造成的伤害+1；你对体力值不多于你的角色造成伤害时，回复1点体力。回合内你每造成一次伤害，结束阶段开始时便须弃置一张牌。",
	[":luasynchrogazer"] = "<font color=\"Sky Blue\"><b>萌战技,绝唱,3,出牌阶段限一次;</b></font>令参战角色依次对一名其他角色使用一张【杀】，直到一名参战角色不如此做。每以此法使用一张【杀】，你可令一名参战角色摸一张牌。（不计入出牌阶段使用杀次数）",
	[":LuaCangshan"] = "你可将装备牌当【杀】或【闪】使用或打出。以此法使用的【杀】无视距离，每以此法使用或打出一张牌时，你摸一张牌。",
	[":luayuehuang"] = "<font color=\"Sky Blue\"><b>萌战技,绝唱,3,出牌阶段限一次;</b></font>令其他参战角色各交给你一张装备牌，然后参战角色各摸X张牌。若如此做，该阶段内你可额外使用X张【杀】（X为以此法交给你的装备牌的数量+1）",
	[":LuaJingming"] = "其他角色的回合开始时，你可弃置一张牌，然后令其不能使用【杀】直到其回合结束；若如此做，回合结束时，你可令其回复1点体力，或其摸两张牌。",
	[":luayingxian"] = "<font color=\"Sky Blue\"><b>萌战技,绝唱,3,出牌阶段限一次;</b></font>参战角色各展示一张手牌，然后你将牌堆顶X张牌以任意方式交给参战角色。（X为所有展示手牌的点数和的算术平方根，向上取整）",
	[":luasaoshe"] = "出牌阶段对每名角色限两次，你可指定一名你攻击范围内的其他角色，然后交给其一张牌并视为你对其使用一张【杀】（不计入出牌阶段使用【杀】次数。）当你于出牌阶段内以此法交给其他角色的手牌首次达到两张或更多时，你回复1点体力，或摸两张牌。",
	[":LuaDikai"] = "<font color=\"Sky Blue\"><b>萌战技,绝唱,1,绝唱角色受到伤害后;</b></font>若其参战，你可摸一张牌，然后弃置伤害来源的一张牌并可交给参战角色一张【杀】或装备牌。",
}
------------------------------------------------------------------------武将信息区
sgs.LoadTranslationTable {
	["designer:tsukushi"] = "OmnisReen",
	["designer:SPkirito"] = "OmnisReen",
	["designer:itomakoto"] = "OmnisReen",
	["designer:yuuta"] = "OmnisReen",
	["designer:odanobuna"] = "OmnisReen",
	["designer:keima"] = "OmnisReen",
	["designer:ayanami"] = "OmnisReen",
	["designer:batora"] = "OmnisReen",
	["designer:sheryl"] = "昂翼天使; OmnisReen",
	["designer:mao_maoyu"] = "昂翼天使; OmnisReen",
	["designer:aoitori"] = "OmnisReen",
	["designer:kyouko"] = "昂翼天使",
	["designer:diarmuid"] = "银龙幽影",
	["designer:ikarishinji"] = "OmnisReen ; 起个ID好烦",
	["designer:redarcher"] = "昂翼天使",
	["designer:redo"] = "起个ID好烦",
	["designer:runaria"] = "昂翼天使",
	["designer:fuwaaika"] = "昂翼天使",
	["designer:slsty"] = "昂翼天使",
	["designer:rokushikimei"] = "起个ID好烦",
	["designer:bernkastel"] = "海猫鸣泣之时吧&果然萝卜斩",
	["designer:hibiki"] = "OmnisReen",
	["designer:kntsubasa"] = "OmnisReen",
	["designer:khntmiku"] = "OmnisReen",
	["designer:yukinechris"] = "OmnisReen",
	["cv:tsukushi"] = "田村ゆかり",
	["cv:SPkirito"] = "松冈祯丞",
	["cv:itomakoto"] = "平川大辅",
	["cv:yuuta"] = "福山潤",
	["cv:odanobuna"] = "伊藤 かな恵",
	["cv:keima"] = "下野紘",
	["cv:ayanami"] = "林原 めぐみ",
	["cv:batora"] = "小野大辅",
	["cv:sheryl"] = "远藤绫 & May'n",
	["cv:mao_maoyu"] = "小清水亜美",
	["cv:aoitori"] = "福山潤",
	["cv:kyouko"] = "野中藍",
	["cv:diarmuid"] = "緑川光",
	["cv:ikarishinji"] = "緒方 恵美",
	["cv:redarcher"] = "諏訪部 順一",
	["cv:redo"] = "石川 界人",
	["cv:runaria"] = "红野ミア",
	["cv:fuwaaika"] = "花澤 香菜",
	["cv:slsty"] = "椎名　へきる",
	["cv:rokushikimei"] = "無",
	["cv:bernkastel"] = "田村ゆかり",
	["cv:hibiki"] = "悠木碧",
	["cv:khntmiku"] = "井口裕香",
	["cv:kntsubasa"] = "水樹奈々",
	["cv:yukinechris"] = "高垣彩陽",
	["illustrator:tsukushi"] = "J.C.Staff",
	["illustrator:SPkirito"] = "A1 Pictures",
	["illustrator:itomakoto"] = "TNK",
	["illustrator:yuuta"] = "Kyoto Animation",
	["illustrator:odanobuna"] = "Studio 五组 X MADHOUSE",
	["illustrator:keima"] = "manglobe",
	["illustrator:ayanami"] = "Khara",
	["illustrator:batora"] = "水野英多",
	["illustrator:sheryl"] = "BigWest",
	["illustrator:mao_maoyu"] = "Arms",
	["illustrator:aoitori"] = "Sunrise",
	["illustrator:kyouko"] = "SHAFT",
	["illustrator:diarmuid"] = "TYPE-MOON",
	["illustrator:ikarishinji"] = "GAINAX",
	["illustrator:redarcher"] = "Type Moon",
	["illustrator:redo"] = "Production I.G.",
	["illustrator:runaria"] = "Nitro+",
	["illustrator:fuwaaika"] = "Bones",
	["illustrator:slsty"] = "Spike",
	["illustrator:rokushikimei"] = "Innocent Grey",
	["illustrator:bernkastel"] = "ひさｎ(@Pixiv)",
	["illustrator:hibiki"] = "うなぎ海鮮（@Pixiv）",
	["illustrator:kntsubasa"] = "サブ(@Pixiv）",
	["illustrator:yukinechris"] = "mototenn(@Pixiv）",
	["illustrator:khntmiku"] = "双葉はる(@Pixiv）",
}
------------------------------------------------------------------------武将配音区
sgs.LoadTranslationTable {
	["$luatiaojiao1"] = "啊！！！“绷”~~~",
	["$luatiaojiao2"] = "现在就把你赶出去！再也不让你踏进这个家门半步了！",
	["$LuaGqset1"] = "真有种啊！",
	["$LuaGqset2"] = "（你这！） 砰！",
	["$LuaShenzhi1"] = "我已经看到结局了",
	["$luagonglue1"] = "还没穿短裤！",
	["$luagonglue2"] = "欢迎~迷途羔羊们。。。",
	["$luablackflame1"] = "鉴于你这次的努力和功绩，本漆黑烈焰使在此聚集漆黑之力，为你生成一条独一无二的暗号。识别暗号-刻印！",
	["$weixiao1"] = "你为什么而哭呢？",
	["$weixiao2"] = "对不起，我不知道该做什么表情好。",
	["$LuaTianmoDefense1"] = "谢谢你，猴子。我又被你救了呢~~",
	["$LuaBuwu1"] = "我一定要创造一个不会再发生这样战争的世界~对吧！",
	["$LuaBuwu2"] = "我眼中所见，是整个世界！",
	["$LuaChigui1"] = "得美浓者的天下~",
	["$LuaChigui2"] = "这种规矩，就由我来打破！",
	["$renzha1"] = "我这边很麻烦的啦~",
	["$luarenzha1"] = "啊~~~ 可恶！",
	["$ak_renzha1"] = "才不是",
	["$ak_renzha2"] = "世界？",
	["$LuaGongming1"] = "与神明相恋之时，从未想过这样的离别会降临 ",
	["$LuaGongming2"] = "与你相逢 群星闪耀 赐我新生 去爱了才会… 拥有爱才会… ",
	["$LuaYaojing1"] = "（啪！）来 听我的歌吧！",
	["$LuaYaojing2"] = "曾经伫立在世界中心，星球因我而旋转 无意中的喷嚏，便惊起林中蝴蝶乱舞 ",
	["$luaboxue1"] = "战争的彼端 未曾见过的世界",
	["$luaboxue2"] = "你好（勇者）",
	["$LuaBimie1"] = "如果不是这样的话，你就能挡下【必灭的黄蔷薇】了",
	["$LuaBimie2"] = "飞舞吧，Gae·Buidhe！",
	["$LuaBimie3"] = "别怪我，互相都有决不能输的理由。",
	["$LuaPomo1"] = "哗~哗~哗~哗~",
	["$LuaPomo2"] = "鲜红地，舞动吧。",
	["$LuaPomo3"] = "盛开吧，Gae·Dearg！",
	["$LuaPomo4"] = "玫瑰啊，散落吧。",
	["$LuaLuoshen1"] = "超烦~超烦人~~",
	["$LuaLuoshen2"] = "真可笑呢~",
	["$LuaLuowang1"] = "如同偷窥围裙里的胖次 难以表达（直视= =）",
	["$LuaLuowang2"] = "赫~赫~~赫莱森！！！",
	["$LuaKuangshi1"] = "砰！啊~~啊！！！啊！！！！",
	["$LuaKuangshi2"] = "唔啊！！！！！！！！",
	["$LuaBaozou1"] = "我变成什么样无所谓 世界变成什么样无所谓。但是绫波。。。 一定要救出来！",
	["$LuaBaozou2"] = "把绫波 还我！",
	["$LuaXinbi1"] = "救救我。。。救救我。明日香。",
	["$LuaXinbi2"] = "(不需要。) 所以请温柔一点对我啊。。",
	["$LuaGongqi1"] = "螺旋剑！",
	["$LuaGongqi2"] = "只有在确认一击必杀的时候，才会拿起剑。",
	["$LuaGongqi3"] = "你只是沉浸在自己正义里的伪善者而已，如果这都发现不了的话就没办法了。",
	["$LuaGongqi4"] = "正义的伙伴什么的，笑死人了。",
	["$luatouying1"] = "Trace......on!",
	["$LuaJianyong1"] = "I am the bone of my sword.",
	["$LuaJianyong2"] = "Steel is my body,and fire is my blood",
	["$LuaJianyong3"] = "I have created over a thousand blades",
	["$LuaJianyong4"] = "Unknown to Death. Nor known to life",
	["$LuaJianyong5"] = "Have withstood pain to create many weapons",
	["$LuaJianyong6"] = "Yet, those hands will never hold anything",
	["$luajianyu1"] = "Yet, those hands will never hold anything. ",
	["$LuaJianzhi1"] = "So as I pray, unlimited blade works.  ",
	["$LuaChamberMove1"] = "干翻他！钱伯。",
	["$LuaRedoWake1"] = "去死吧！铁皮魂淡！",
	["$LuaJiguangAsk1"] = "哗~哗~~哗~~~",
	["$LuaGaoxiao1"] = "全面同意",
	["$LuaGaokang1"] = "可以观测他们想对本机造成伤害，但苦于没有手段，推测他们的文明低下。",
	["$LuaWenle1"] = "哪都行，请带我离开这里",
	["$luayukong1"] = "那样的话，就算被我代替了也没啥怨言吧",
	["$LuaQisi1"] = "真狼狈呢",
	["$luaposhi1"] = "一切都是你的罪过",
	["$LuaLiansuo1"] = "天地之间有许多事情是你的睿智无法想象的",
	["$LuaYinguo1"] = "这是怎样一个被诅咒的因果啊",
	["$slyanhuo1"] = "能够存活下来的人不是强者也不是智者，而是能够接受并适应变化的人",
	["$zhahu1"] = "自作自受",
	["$suipian1"] = "这样一边倒的游戏 真无聊",
	["$suipian2"] = "又怎样？",
	["$erciyuan_qiji1"] = "你可真是记仇呢",
	["$erciyuan_qiji2"] = "你爱怎么样就怎么样吧，既然如此那我就认真了。",
	["$LuaGungnir1"] = "Balwisyall Nescell gungnir tron",
	["$LuaGungnir2"] = "届け！",
	["$LuaGungnir3"] = "我明白了。。。",
	["$luasynchrogazer1"] = "开始吧！S2CA TRIBURST!",
	["$luasynchrogazer2"] = "Gatrandis babel ziggurat edenal Emustrolronzen fine el baral zizzl Gatrandis babel ziggurat edenal Emustrolronzen fine el zizzl",
	["$LuaCangshan1"] = "那我这边也来真的吧！",
	["$LuaCangshan2"] = "（划破声）",
	["$luayuehuang1"] = "利刃风急千花绽",
	["$luayuehuang2"] = "（圣咏）",
	["$LuaDikai1"] = "接下来就是我的活儿了！",
	["$luasaoshe1"] = "二话不说甩起加特林 死亡派对将你送往垃圾箱。",
	["$luasaoshe2"] = "Combination Arts！",
	["$LuaJingming1"] = "我不想让你再战斗下去了。",
	["$LuaJingming2"] = "据说这件Gear放出的光芒，能照亮新的世界。",
	["$luayingxian1"] = "闪光…创始的世界　漆黑…终结的世界",
	["$luayingxian2"] = "（圣咏）",
	["$LuaDikai2"] = "（圣咏）",
	["~tsukushi"] = "不要。。我不会再放开了。。。",
	["~keima"] = "就一步，为现实妥协。。。",
	["~yuuta"] = "啊~~~砰！",
	["~ayanami"] = "为什么~~",
	["~odanobuna"] = "还会。。。再会的吧。",
	["~itomakoto"] = "嘘~~~~~~~~~~",
	["~sheryl"] = "但是，我的工作已经结束了。",
	["~mao_maoyu"] = "真为这样的自己感到难过。",
	["~kyouko"] = "拜托了 神啊 都已经是这样的人生了，至少让我做一次幸福的梦吧。",
	["~aoitori"] = "（哦哦哦哦哦哦~~~）",
	["~diarmuid"] = "我诅咒圣杯，诅咒你们的愿望成为灾祸。等你们堕入地狱火海之时，就会想起我迪卢木多的愤怒！",
	["~ikarishinji"] = "我最差劲了。。",
	["~redo"] = "贵官将得到 自由睡眠权 自由饮食权 还能获得 自由生殖权",
	["~redarcher"] = "是我的，败北。",
	["~runaria"] = "即使世上所有的人都离开了你，我也会和你在一起",
	["~fuwaaika"] = "啊，这是多么惊人的事件，我既是被害者，又是侦探，同时还是犯人",
	["~slsty"] = "那么就此别过，来世再见",
	["~bernkastel"] = "这个游戏永远都不会完结，只是暂时把棋盘盖起来而已。",
	["~hibiki"] = "不要！我不要再放开你。",
	["~khntmiku"] = "不对，我希望的，才不是这种事情！才不是这种事情！！",
	["~kntsubasa"] = "是吧，奏？",
	["~yukinechris"] = "永别了",
}
------------------------------------------------------------------------技能动画区
sgs.LoadTranslationTable {
	["luaboxue$"] = "image=image/animate/luaboxue.png",
	["LuaYaojing$"] = "image=image/animate/LuaYaojing.png",
	["luarenzha$"] = "image=image/animate/luarenzha.png",
	["LuaBuwu$"] = "image=image/animate/LuaBuwu.png",
	["weixiao$"] = "image=image/animate/weixiao.png",
	["LuaGqset$"] = "image=image/animate/LuaGqset.png",
	["LuaShenzhi$"] = "image=image/animate/LuaShenzhi.png",
	["luablackflame$"] = "image=image/animate/luablackflame.png",
	["LuaLuowang$"] = "image=image/animate/LuaLuowang.png",
	["LuaBimie$"] = "image=image/animate/LuaBimie.png",
	["LuaJianzhi$"] = "image=image/animate/LuaJianzhi.png",
	["$LuaRedoWake"] = "anim=skill/LuaRedoWake",
}
----------------------------------------------------------------------------------------------------------
