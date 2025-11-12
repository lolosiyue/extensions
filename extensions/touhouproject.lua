module("extensions.touhouproject", package.seeall)
extension = sgs.Package("touhouproject")

do
	require "lua.config"
	local th_config = config
	table.insert(th_config.kingdoms,"TH_kingdom_meng")
	table.insert(th_config.kingdoms,"TH_kingdom_baka")
	th_config.kingdom_colors.TH_kingdom_meng = "#FFCB38"
	th_config.kingdom_colors.TH_kingdom_baka = "#66CCFF"
	table.insert(th_config.package_names, "touhouproject")
end


FlandreScarlet_Nos = sgs.General(extension, "FlandreScarlet_Nos", "touhou", 3, false)
FlandreScarlet = sgs.General(extension, "FlandreScarlet", "touhou", 3, false)
RemiliaScarlet =sgs.General(extension, "RemiliaScarlet", "touhou", 3, false)
RemiliaScarlet_Nos =sgs.General(extension, "RemiliaScarlet_Nos", "touhou", 3, false)
IzayoiSakuya = sgs.General(extension, "IzayoiSakuya", "touhou", 3, false)
HakureiReimu = sgs.General(extension, "HakureiReimu", "touhou", 3, false)
KotiyaSanae = sgs.General(extension, "KotiyaSanae", "touhou", 3, false)
SaigyoujiYuyuko = sgs.General(extension, "SaigyoujiYuyuko", "touhou", 3, false)
KonpakuYoumu = sgs.General(extension, "KonpakuYoumu", "touhou", 3, false)
HouraisanKaguya = sgs.General(extension, "HouraisanKaguya", "touhou", 3, false,true, true)
HouraisanKaguya_Nos = sgs.General(extension, "HouraisanKaguya_Nos", "touhou", 3, false)
YagokoroEirin = sgs.General(extension, "YagokoroEirin", "touhou", 3, false)
ReisenUdongeinInaba = sgs.General(extension, "ReisenUdongeinInaba", "touhou", 3, false)
FujiwaranoMokou = sgs.General(extension, "FujiwaranoMokou", "touhou", 3, false)
Shikieiki = sgs.General(extension, "Shikieiki", "touhou", 3, false)
ShameimaruAya = sgs.General(extension, "ShameimaruAya", "touhou", 3, false)
KazamiYuuka = sgs.General(extension, "KazamiYuuka", "touhou", 3, false)
KirisameMarisa = sgs.General(extension, "KirisameMarisa", "touhou", 3, false)
KagiyamaHina = sgs.General(extension, "KagiyamaHina", "touhou", 3, false)
YasakaKanako = sgs.General(extension, "YasakaKanako", "touhou", 3, false)
YakumoYukari = sgs.General(extension, "YakumoYukari", "touhou", 3, false)
Cirno = sgs.General(extension, "Cirno", "touhou", "3",false)
KomeijiSatori = sgs.General(extension, "KomeijiSatori", "touhou", 3, false)
KomeijiKoishi = sgs.General(extension, "KomeijiKoishi", "touhou", 3, false)
HoshigumaYuugi = sgs.General(extension, "HoshigumaYuugi", "touhou", 3, false)
ReiujiUtsuho = sgs.General(extension, "ReiujiUtsuho", "touhou", 3, false)
KaenbyouRin = sgs.General(extension, "KaenbyouRin", "touhou", 3, false)
PatchouliKnowledge = sgs.General(extension, "PatchouliKnowledge", "touhou", 3, false)
HinanawiTenshi = sgs.General(extension, "HinanawiTenshi", "touhou", 5, false)
NagaeIku = sgs.General(extension, "NagaeIku", "touhou", 3, false)
HoujuuNue = sgs.General(extension, "HoujuuNue", "touhou", 3, false)
Nazrin = sgs.General(extension, "Nazrin", "touhou", 3, false)
TataraKogasa = sgs.General(extension, "TataraKogasa", "touhou", 3, false)
HijiriByakuren = sgs.General(extension, "HijiriByakuren", "touhou", 3, false)
IbukiSuika = sgs.General(extension, "IbukiSuika", "touhou", 3, false)
UsamiRenko = sgs.General(extension, "UsamiRenko", "touhou", 3, false)
MaribelHearn = sgs.General(extension, "MaribelHearn", "touhou", 3, false)
ToyosatomiminoMiko = sgs.General(extension, "ToyosatomiminoMiko", "touhou", 3, false)
MagakiReimu = sgs.General(extension, "MagakiReimu", "touhou", 3, false,true)

YakumoRan = sgs.General(extension, "YakumoRan", "touhou", 3, false, true, true)
YakumoChen = sgs.General(extension, "YakumoChen", "touhou", 3, false, true, true)
KaenbyouRin_zabingjia = sgs.General(extension, "KaenbyouRin_zabingjia", "touhou", 1, true, true, true)
KaenbyouRin_zabingyi = sgs.General(extension, "KaenbyouRin_zabingyi", "touhou", 1, true, true, true)
KaenbyouRin_zabingbing = sgs.General(extension, "KaenbyouRin_zabingbing", "touhou", 1, true, true, true)

--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------


local function playerNumber(player,all)
	local room=player:getRoom()
	if all then return room:getPlayers():length() end
	local n = 0
	for _,p in sgs.qlist(room:getPlayers()) do
		n = n + 1
		if p:objectName() == player:objectName() then
			break
		end
	end
	return n
end

local function TH_logmessage(logtype, logfrom, logarg, logto, logarg2, card_str)
	local alog = sgs.LogMessage()
	alog.type = logtype
	alog.from = logfrom
	if logto then alog.to:append(logto) end
	if logarg then alog.arg = logarg end
	if logarg2 then alog.arg2 = logarg2 end
	if card_str then alog.card_str = card_str end
	local room = logfrom and logfrom:getRoom() or logto and logto:getRoom()
	room:sendLog(alog)
end

local function TH_shuffle(atable)
	local count = #atable
	for i = 1, count do
		local j = math.random(1, count)
		atable[j], atable[i] = atable[i], atable[j]
	end
	return atable
end

local function TH_obtainCard(player, cardORid, skillname)
	if type(cardORid) == "number" then
		cardORid = sgs.Sanguosha:getCard(cardORid)
	end
	local room = player:getRoom()
	local reason = sgs.CardMoveReason()
	reason.m_reason = sgs.CardMoveReason_S_REASON_EXTRACTION
	reason.m_playerId = player:objectName()
	if skillname then reason.m_skillName = skillname end
	room:moveCardTo(cardORid, nil, player, sgs.Player_PlaceHand, reason, room:getCardPlace(cardORid:getEffectiveId()) ~= sgs.Player_PlaceHand)
end
--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------Card
TH_Weapon_Laevatein = sgs.CreateWeapon{
	name = "TH_Weapon_Laevatein",
	class_name = "TH_Weapon_Laevatein",
	suit = sgs.Card_Spade,
	number = 12,
	range = 2,
}
TH_Weapon_Laevatein:setParent(extension)
TH_Weapon_Laevatein_skill = sgs.CreateTriggerSkill{
	name = "TH_Weapon_Laevatein",
	events = {sgs.CardUsed, sgs.CardFinished},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:hasWeapon("TH_Weapon_Laevatein")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("SavageAssault") then
				for _, p in sgs.qlist(use.to) do
					if p:objectName() == player:objectName() then continue end
					room:addPlayerMark(p, "Armor_Nullified")
					if p:getArmor() then
						TH_logmessage("#TriggerSkill", player, self:objectName())
						room:throwCard(p:getArmor():getEffectiveId(), p, player)
						local flandre = use.from:getGeneralName() == "FlandreScarlet"
							or use.from:getGeneral2Name() == "FlandreScarlet"
							or use.from:getGeneralName() == "FlandreScarlet_Nos"
							or use.from:getGeneral2Name() == "FlandreScarlet_Nos"
						if flandre then
							room:damage(sgs.DamageStruct(self:objectName(), use.from, p, 1, sgs.DamageStruct_Fire))
						end
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("SavageAssault") then
				for _, p in sgs.qlist(use.to) do
					if p:objectName() == player:objectName() then continue end
					room:removePlayerMark(p, "Armor_Nullified")
				end
			end
		end
	end
}

TH_Weapon_SpearTheGungnir = sgs.CreateWeapon{
	name = "TH_Weapon_SpearTheGungnir",
	class_name = "TH_Weapon_SpearTheGungnir",
	suit = sgs.Card_Diamond,
	number = 11,
	range = 5,
}
TH_Weapon_SpearTheGungnir:setParent(extension)
TH_Weapon_SpearTheGungnir_skill = sgs.CreateTriggerSkill{--神枪
	name = "TH_Weapon_SpearTheGungnir",
	events = { sgs.TargetSpecified, sgs.Damage },
	priority = 15,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:hasWeapon("TH_Weapon_SpearTheGungnir")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			local remilia = use.from:getGeneralName() == "RemiliaScarlet"
							or use.from:getGeneral2Name() == "RemiliaScarlet"
							or use.from:getGeneralName() == "RemiliaScarlet_Nos"
							or use.from:getGeneral2Name() == "RemiliaScarlet_Nos"
			if remilia then room:setPlayerFlag(use.from, "TH_Weapon_SpearTheGungnir_effect_" .. use.card:toString()) end
					local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
					local index = 1
					local range = player:getAttackRange()
					for _, p in sgs.qlist(use.to) do
						jink_table[index] = 0
						index = index + 1
					end
					local jink_data = sgs.QVariant()
					jink_data:setValue(Table2IntList(jink_table))
					player:setTag("Jink_" .. use.card:toString(), jink_data)
					return false
				
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			local remilia = damage.from and (damage.from:getGeneralName() == "RemiliaScarlet"
							or damage.from:getGeneral2Name() == "RemiliaScarlet"
							or damage.from:getGeneralName() == "RemiliaScarlet_Nos"
							or damage.from:getGeneral2Name() == "RemiliaScarlet_Nos")
			if remilia and damage.card and damage.from:hasFlag("TH_Weapon_SpearTheGungnir_effect_" .. damage.card:toString()) then
				room:setPlayerFlag(damage.from, "-TH_Weapon_SpearTheGungnir_effect_" .. damage.card:toString())
				room:askForDiscard(damage.to, "TH_Weapon_SpearTheGungnir", 1, 1, false, false)
			end
		end
	end
}

TH_Weapon_Penglaiyuzhi = sgs.CreateWeapon{
	name = "TH_Weapon_Penglaiyuzhi",
	class_name = "TH_Weapon_Penglaiyuzhi",
	suit = sgs.Card_Club,
	number = 5,
	range = 1,
}
TH_Weapon_Penglaiyuzhi_skill = sgs.CreateTriggerSkill{
	name = "TH_Weapon_Penglaiyuzhi",
	events = { sgs.CardFinished },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:hasWeapon("TH_Weapon_Penglaiyuzhi")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			local kaguya = use.from:getGeneralName() == "HouraisanKaguya"
							or use.from:getGeneral2Name() == "HouraisanKaguya"
							or use.from:getGeneralName() == "HouraisanKaguya_Nos"
							or use.from:getGeneral2Name() == "HouraisanKaguya_Nos"
			use.from:drawCards(kaguya and 2 or 1)
		end
	end
}
TH_Weapon_Penglaiyuzhi:setParent(extension)

TH_Weapon_BailouLouguan = sgs.CreateWeapon{
	name = "TH_Weapon_BailouLouguan",
	class_name = "TH_Weapon_BailouLouguan",
	suit = sgs.Card_Diamond,
	number = 2,
	range = 2,
}
TH_Weapon_BailouLouguan_skill = sgs.CreateTriggerSkill{
	name = "TH_Weapon_BailouLouguan",
	events = { sgs.TargetConfirmed, sgs.CardEffected, sgs.CardUsed },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and (target:hasWeapon("TH_Weapon_BailouLouguan") or target:hasFlag("TH_Weapon_BailouLouguan"))
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardEffected then
			local slash = data:toCardEffect()
			if not slash.card:isKindOf("Slash") then return false end
			if not slash.card:hasFlag("TH_Weapon_BailouLouguan") then return false end
				slash.to:setFlags("Global_NonSkillNullify")
			local jink
			local jink1 = room:askForCard(slash.to, "jink", "TH_Weapon_BailouLouguan_first:" .. slash.from:objectName(), data, sgs.Card_MethodUse, slash.from)
			if jink1 and slash.to:isAlive() then
				room:setTag("TH_Weapon_BailouLouguan_Suit", sgs.QVariant(jink1:getSuit()))
				room:setPlayerFlag(slash.to, "TH_Weapon_BailouLouguan_first")
				local jink2 = room:askForCard(slash.to, "jink", "TH_Weapon_BailouLouguan_second:" .. slash.from:objectName(), data, sgs.Card_MethodUse, slash.from)
				room:setPlayerFlag(slash.to, "-TH_Weapon_BailouLouguan_first")
				room:removeTag("TH_Weapon_BailouLouguan_Suit")
				if jink2 and jink1:getSuit() ~= jink2:getSuit() then
					jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
					jink:addSubcard(jink1)
					jink:addSubcard(jink2)
				end
			end
			if slash.to:isAlive() then
				if jink then
					slash.offset_card = jink
					data:setValue(slash)
					if not room:getThread():trigger(sgs.CardOffset,room,slash.from,data) then
						return true
					end
				else
					local effect = data:toCardEffect()
					effect.offset_card = nil
					data:setValue(effect)
					room:getThread():trigger(sgs.CardOnEffect,room,effect.to,data)
					room:damage(sgs.DamageStruct(effect.card, effect.from, effect.to, 1))
					return true
				end
			end
		elseif event == sgs.CardUsed and player:hasFlag("TH_Weapon_BailouLouguan_first") then
			local use = data:toCardUse()
			if use.card:isKindOf("Jink") then
				local jink = use.card
				local suit1 = room:getTag("TH_Weapon_BailouLouguan_Suit"):toInt()
				local invalid = suit1 == jink:getSuit()
				if invalid then
					if not jink:hasFlag("AI_dummyUse") then
						local log = sgs.LogMessage()
						log.type = "$TH_Weapon_BailouLouguan"
						log.to:append(player)
						log.card_str = jink:toString()
						room:sendLog(log)
					end
					local nullified_list = use.nullified_list
					table.insert(nullified_list, "_ALL_TARGETS")
					use.nullified_list = nullified_list
					data:setValue(use)
				end
			end
		elseif event == sgs.TargetConfirmed and player:hasWeapon("TH_Weapon_BailouLouguan") then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.card:isKindOf("Slash") then
				room:setCardFlag(use.card, "TH_Weapon_BailouLouguan")
				for _, p in sgs.qlist(use.to) do
					room:setPlayerFlag(p, "TH_Weapon_BailouLouguan")
				end
			end
		elseif event == sgs.CardFinished and player:hasWeapon("TH_Weapon_BailouLouguan") then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					room:setPlayerFlag(p, "-TH_Weapon_BailouLouguan")
				end
			end
		end
	end
}
TH_Weapon_BailouLouguan:setParent(extension)
TH_Weapon_BailouLouguanTMS = sgs.CreateTargetModSkill{
	name = "TH_Weapon_BailouLouguanTMS",
	pattern = "Slash,EXCard_ZJZB",
    extra_target_func = function(self, from, card)
		if from:hasWeapon("TH_Weapon_BailouLouguan") and card:isKindOf("Slash") and (from:getGeneralName() == "KonpakuYoumu" or from:getGeneral2Name() == "KonpakuYoumu") then
			return 1
		elseif card:isKindOf("EXCard_ZJZB") then
			return 1
		end
	end,
}


TH_Weapon_Feixiangjian = sgs.CreateWeapon{
	name = "TH_Weapon_Feixiangjian",
	class_name = "TH_Weapon_Feixiangjian",
	suit = sgs.Card_Heart,
	number = 13,
	range = 2,
}
TH_Weapon_Feixiangjian:setParent(extension)
TH_Weapon_Feixiangjian_skill = sgs.CreateTriggerSkill{
	name = "TH_Weapon_Feixiangjian",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetConfirmed, sgs.CardFinished, sgs.CardUsed },
	can_trigger = function(self, target)
		return target and (target:hasWeapon("TH_Weapon_Feixiangjian") or target:hasFlag("TH_Weapon_Feixiangjian_red") or target:hasFlag("TH_Weapon_Feixiangjian_black")
							or target:hasFlag("TH_Weapon_Feixiangjian_nosuit"))
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed and player:hasWeapon("TH_Weapon_Feixiangjian") then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() and use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					room:setPlayerFlag(p, "-TH_Weapon_Feixiangjian_red")
					room:setPlayerFlag(p, "-TH_Weapon_Feixiangjian_black")
					room:setPlayerFlag(p, "-TH_Weapon_Feixiangjian_nosuit")
					if p:getMark("Equips_of_Others_Nullified_to_You") == 0 then
						local new_data = sgs.QVariant()
						new_data:setValue(p)
						local choice = room:askForChoice(player, self:objectName(), "cancel+red+black+nosuit", new_data)
						if choice ~= "cancel" then
							TH_logmessage("#TH_Weapon_Feixiangjian_effect", player, choice)
							room:setPlayerFlag(p, "TH_Weapon_Feixiangjian_" .. choice)
							local tenshi = use.from:getGeneralName() == "HinanawiTenshi"
											or use.from:getGeneral2Name() == "HinanawiTenshi"
							if tenshi then
								for _, to in sgs.qlist(use.to) do
									local cards = {}
									for _, c in sgs.qlist(to:getHandcards()) do
										if c:isKindOf("Jink") and (choice == "red" and c:isRed() or chioce == "black" and c:isBlack()
																	or chioce == "nosuit" and c:getSuit() == sgs.Card_NoSuit) then
											table.insert(cards, c)
										end
									end
									if #cards > 0 then
										local reason = sgs.CardMoveReason()
										reason.m_reason = sgs.CardMoveReason_S_REASON_EXTRACTION
										reason.m_playerId = player:objectName()
										reason.m_skillName = "TH_Weapon_Feixiangjian"
										room:moveCardTo(cards[math.random(1, #cards)], nil, player, sgs.Player_PlaceHand, reason, false)
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardFinished and player:hasWeapon("TH_Weapon_Feixiangjian") then
			local use = data:toCardUse()
			if use.from:objectName() == player:objectName() and use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(use.to) do
					room:setPlayerFlag(p, "-TH_Weapon_Feixiangjian_red")
					room:setPlayerFlag(p, "-TH_Weapon_Feixiangjian_black")
					room:setPlayerFlag(p, "-TH_Weapon_Feixiangjian_nosuit")
				end
			end
		elseif event == sgs.CardUsed and (player:hasFlag("TH_Weapon_Feixiangjian_red") or player:hasFlag("TH_Weapon_Feixiangjian_black")
											or player:hasFlag("TH_Weapon_Feixiangjian_nosuit")) then
			local use = data:toCardUse()
			if use.card:isKindOf("Jink") then
				local jink = use.card
				local colour = "nosuit"
				if player:hasFlag("TH_Weapon_Feixiangjian_red") then colour = "red"
				elseif player:hasFlag("TH_Weapon_Feixiangjian_black") then colour = "black" end
				local invalid
				if jink:isRed() and colour == "red" then invalid = true
				elseif jink:isBlack() and colour == "black" then invalid = true
				elseif jink:getSuit() == sgs.Card_NoSuit and colour == "nosuit" then invalid = true end
				if invalid then
					if not jink:hasFlag("AI_dummyUse") then
						local log = sgs.LogMessage()
						log.type = "$TH_Weapon_Feixiangjian"
						log.to:append(player)
						log.card_str = jink:toString()
						room:sendLog(log)
					end
					local nullified_list = use.nullified_list
					table.insert(nullified_list, "_ALL_TARGETS")
					use.nullified_list = nullified_list
					data:setValue(use)
					--return true
				end
			end
		end
	end
}

local cardsuits = {0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0}
for i = 1, 13 do
	local jinkcard = sgs.Sanguosha:cloneCard("jink", cardsuits[i], i)
	jinkcard:setParent(extension)
end

--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------FlandreScarlet

TH_ForbiddenFruitsVS = sgs.CreateViewAsSkill{--禁忌·禁果
	name = "TH_ForbiddenFruits",
	n = 0,
	view_as = function(self, cards)
		local Hcard = TH_ForbiddenFruitsCARD:clone()
		return Hcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_ForbiddenFruitsCARD")
	end,
}
TH_ForbiddenFruitsCARD = sgs.CreateSkillCard{
	name = "TH_ForbiddenFruitsCARD",
	skill_name = "TH_ForbiddenFruits",
	filter = function(self, targets, to_select)
		return #targets < 3 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isAllNude()
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason()
		reason.m_reason = sgs.CardMoveReason_S_REASON_EXTRACTION
		reason.m_playerId = source:objectName()
		reason.m_skillName = "TH_ForbiddenFruits"
		local isPeach
		for _, p in ipairs(targets) do
			if p:isAllNude() then continue end
			local id = room:askForCardChosen(source, p, "hej", "TH_ForbiddenFruits")
			if sgs.Sanguosha:getCard(id):isKindOf("Peach") then isPeach = true end
			room:moveCardTo(sgs.Sanguosha:getCard(id), nil, source, sgs.Player_PlaceHand, reason, room:getCardPlace(id) ~= sgs.Player_PlaceHand)
		end
		if isPeach then room:loseHp(source) end
	end
}
TH_ForbiddenFruits = sgs.CreateTriggerSkill{
	name = "TH_ForbiddenFruits",
	events = { sgs.NonTrigger },
	frequency = sgs.Skill_Limited,
	view_as_skill = TH_ForbiddenFruitsVS,
	priority = 8,
	on_trigger = function(self, event, player, data)
	end
}
--[[
TH_StarbowBreakVS = sgs.CreateViewAsSkill{-------禁弹·星弧破碎
	name = "TH_StarbowBreak",
	n = 0,
	view_as = function(self, cards)
		local Hcard = TH_StarbowBreakCARD:clone()
		return Hcard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@TH_StarbowBreak"
	end
}
TH_StarbowBreakCARD = sgs.CreateSkillCard{
	name = "TH_StarbowBreakCARD",
	skill_name = "TH_StarbowBreak",
	filter = function(self, targets, to_select)
		return #targets < 2 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:isAdjacentTo(to_select)
	end,
	feasible = function(self, targets)
		return #targets > 0 and #targets <= 2
	end,
	on_use = function(self, room, source, targets)
		for _, t in ipairs(targets) do
			room:setPlayerFlag(t, "TH_StarbowBreak_target_" .. source:objectName())
		end
	end
}
TH_StarbowBreak = sgs.CreateTriggerSkill{
	name = "TH_StarbowBreak",
	events = { sgs.DamageCaused },
	view_as_skill = TH_StarbowBreakVS,
	priority = 8,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		if da.damage <= 1 then return end
		room:setTag("TH_StarbowBreak_DamageStruct", data)
		local prompt = string.format("#TH_StarbowBreak:%s:%s", da.to:objectName(), da.damage - 1)
		local use = room:askForUseCard(player, "@@TH_StarbowBreak", prompt)
		room:removeTag("TH_StarbowBreak_DamageStruct")
		if use then
			for _, ap in sgs.qlist(self.room:getOtherPlayers(player)) do
				if ap:hasFlag("TH_StarbowBreak_target_" .. player:objectName()) then
					room:setPlayerFlag(ap, "-TH_StarbowBreak_target_" .. player:objectName())
					room:damage(sgs.DamageStruct(self:objectName(), da.from, ap, da.damage - 1, da.nature))
				end
			end
			TH_logmessage("#TH_StarbowBreak_reduce", nil, nil, da.to)
			da.damage = 1
			data:setValue(da)
		end
	end
}
]]

TH_StarbowBreak = sgs.CreateTriggerSkill{-------禁弹·星弧破碎
	name = "TH_StarbowBreak",
	events = { sgs.DamageCaused },
	priority = 8,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		if da.damage <= 1 then return end
		room:setTag("TH_StarbowBreak_DamageStruct", data)
		local prompt = string.format("#TH_StarbowBreak:%s:%s", da.to:objectName(), da.damage - 1)
		local ap = room:askForPlayerChosen(player, room:getOtherPlayers(da.to), self:objectName(), prompt, true, true)
		room:removeTag("TH_StarbowBreak_DamageStruct")
		if ap then
			room:damage(sgs.DamageStruct(self:objectName(), da.from, ap, da.damage - 1, da.nature))
			TH_logmessage("#TH_StarbowBreak_reduce", nil, nil, da.to)
			da.damage = 1
			data:setValue(da)
		end
	end
}

TH_Catadioptric = sgs.CreateTriggerSkill{-------禁弹·折反射
	name = "TH_Catadioptric",
	events = { sgs.DamageInflicted },
	priority = -9,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		if not da.chain then return end
		room:setTag("TH_Catadioptric_DamageStruct", data)
		local ap = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "#TH_Catadioptric", true, true)
		room:removeTag("TH_Catadioptric_DamageStruct")
		if ap then
			local new_da = data:toDamage()
			new_da.to = ap
			new_da.damage = da.damage + 1
			new_da.transfer = true
			room:damage(new_da)
			return true
		end
	end
}

TH_SositeVS = sgs.CreateViewAsSkill{--秘弹·之后就一个人都没有了吗？
	name = "TH_Sosite",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		local Hcard = TH_SositeCARD:clone()
		for _, c in ipairs(cards) do
			Hcard:addSubcard(c)
		end
		Hcard:setSkillName(self:objectName())
		return Hcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_SositeCARD")
	end,
}
TH_SositeCARD = sgs.CreateSkillCard{
	name = "TH_SositeCARD",
	skill_name = "TH_Sosite",
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isNude()
	end,
	on_use = function(self, room, source, targets)
		local sb = targets[1]
		if sb:isNude() then return end
		local dis_num = 1 + self:subcardsLength()
		source:gainMark("&TH_Sosite", dis_num)
		local sb = targets[1]
		if sb:getCardCount() <= dis_num then sb:throwAllHandCardsAndEquips()
		else room:askForDiscard(sb, "TH_Sosite", dis_num, dis_num, false, true, "#TH_Sosite::dis_num")
		end
	end
}
TH_Sosite = sgs.CreateTriggerSkill{
	name = "TH_Sosite",
	events = { sgs.DamageCaused },
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_SositeVS,
	on_trigger = function(self, event, player, data)
		if player:getMark("&TH_Sosite") == 0 then return end
		local damage = data:toDamage()
		if damage.chain or not damage.by_user or damage.transfer then return end
		local percent = player:getMark("&TH_Sosite") * 15
		player:loseAllMarks("&TH_Sosite")
		local critical = math.random(1, 100) <= percent
		if critical then
			TH_logmessage("#TH_Sosite_damage", player, damage.damage, nil, damage.damage * 2)
			damage.damage = damage.damage * 2
			data:setValue(damage)
		end
	end
}

--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------FlandreScarlet_Nos
TH_huimie = sgs.CreateDistanceSkill{--毁灭
	name = "#TH_huimie",
	correct_func = function(self, from, to)
		if from:getGeneralName() == "FlandreScarlet" or from:getGeneral2Name() == "FlandreScarlet"
			or from:getGeneralName() == "FlandreScarlet_Nos" or from:getGeneral2Name() == "FlandreScarlet_Nos" then
			return -1
		end
	end
}

TH_fulanhandcard = sgs.CreateMaxCardsSkill{
	name = "#TH_fulanhandcard",
	extra_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getMaxHp() < 4 then
			local x = player:isLord() and 5 or 4
			return math.abs(x - player:getMaxHp())
		end
	end
}

----------------------------
TH_huaidiaoCARD = sgs.CreateSkillCard{--坏掉
	name = "TH_huaidiaoCARD",
	skill_name = "TH_huaidiao",
	on_use = function(self, room, source, targets)
		local t = targets[1]
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		if room:isProhibited(t, source, duel) then return end
		duel:setSkillName("TH_huaidiao")
		if not t:isNude() then
			room:askForDiscard(targets[1], "TH_huaidiao", 1, 1, false, true)
		end
		local use = sgs.CardUseStruct()
		use.card = duel
		use.from = t
		use.to:append(source)
		room:useCard(use)
	end
}

TH_huaidiao = sgs.CreateViewAsSkill{--坏掉
	name = "TH_huaidiao",
	n = 0,
	view_as = function(self, cards)
		local Hcard = TH_huaidiaoCARD:clone()
		return Hcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_huaidiaoCARD")
	end
}

----------------------------
TH_scarlet = sgs.CreateTriggerSkill{--真红
	name = "TH_scarlet",
	events = {sgs.Predamage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card and card:isKindOf("Slash") and card:isRed() and not damage.chain and not damage.transfer and damage.by_user then
			damage.damage = damage.damage + 1
			data:setValue(damage)
			return false
		end
	end
}

----------------------------
TH_Laevatein = sgs.CreateTriggerSkill{--莱瓦汀
	name = "TH_Laevatein",
	events = {sgs.CardUsed, sgs.CardFinished},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("SavageAssault") then
				player:setFlags("TH_Laevatein_on")
				for _, p in sgs.qlist(use.to) do
					if p:objectName() ~= player:objectName() then room:addPlayerMark(p, "Armor_Nullified") end
					if p:getArmor() then room:throwCard(p:getArmor():getEffectiveId(), p, player) end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if player:hasFlag("TH_Laevatein_on") and (use.card:isKindOf("Slash") or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("SavageAssault")) then
				player:setFlags("-TH_Laevatein_on")
				for _, p in sgs.qlist(use.to) do
					room:removePlayerMark(p, "Armor_Nullified")
				end
			end
		end
	end
}

----------------------------
TH_cranberry = sgs.CreateTriggerSkill{--蔓越莓
	name = "TH_cranberry",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = damage.to:getRoom()
		-- if player:hasFlag("TH_huanyue_off") then return end
		if not room:askForSkillInvoke(damage.to, "TH_cranberry", data) then return false end
		for i = 1, damage.damage, 1 do
			damage.to:drawCards(damage.to:getMaxHp())
		end
		if damage.from and room:askForSkillInvoke(damage.to, "TH_cranberry_turnover", data) then damage.from:turnOver() end
	end
}

----------------------------
TH_huanyue = sgs.CreateTriggerSkill{--幻月
	name = "TH_huanyue",
	frequency = sgs.Skill_Wake,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "TH_huanyue", 1)
		player:removeMark("TH_huanyue_wake")
		room:notifySkillInvoked(player, "TH_huanyue")
		room:broadcastSkillInvoke(self:objectName())
		room:setPlayerProperty(player, "chained", sgs.QVariant(false))
		if player:getJudgingArea():length() > 0 then
			local move = sgs.CardsMoveStruct()
			for _, trick in sgs.qlist(player:getJudgingArea()) do
				move.card_ids:append(trick:getEffectiveId())
			end
			move.reason.m_reason = sgs.CardMoveReason_S_REASON_NATURAL_ENTER
			move.to_place = sgs.Player_DiscardPile
			room:moveCardsAtomic(move, true)
		end
		room:setEmotion(player,"FlandreScarlet_Nos")
		room:getThread():delay()
		room:acquireSkill(player, "TH_Laevatein")
		room:acquireSkill(player, "TH_qed")
		room:acquireSkill(player, "TH_huaidiao")
		-- room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 3))
		local recover=sgs.RecoverStruct()
		recover.who=player
		recover.recover=player:getLostHp()
		room:recover(player,recover,true)
		room:detachSkillFromPlayer(player, "TH_sichongcunzai")
		room:detachSkillFromPlayer(player, "TH_cranberry")
		-- room:detachSkillFromPlayer(player, "TH_mingke")
	end,
	can_wake = function(self, event, player, data, room)
		if player:getPhase() ~= sgs.Player_RoundStart or player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end

		if player:getMark("TH_huanyue_wake") >= 1 then return true end
		return false
	end,
}

TH_huanyueTS = sgs.CreateTriggerSkill{--幻月
	name = "#TH_huanyueTS",
	events = { sgs.TurnStart },
	priority = -20,
	can_trigger = function(self, player)
		return player
	end,
	on_trigger = function(self, event, player, data)
		if not player:getNextAlive():hasSkill(self:objectName()) then return end
		local nextp = player:getNextAlive()
		if nextp:getMark("TH_huanyue_wake") >= 1 or nextp:canWake("TH_huanyue") then
			player:getRoom():setPlayerProperty(nextp, "faceup", sgs.QVariant(true))
		end
	end
}

----------------------------
TH_sichongcunzai = sgs.CreateTriggerSkill{--四重存在
	name = "TH_sichongcunzai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageForseen},
	priority = -1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.to:hasSkill(self:objectName()) then return false end
		-- if not room:askForSkillInvoke(damage.to, self:objectName(), data) then player:setFlags("TH_huanyue_off") return false end
		-- player:setFlags("-TH_huanyue_off")
		local judge = sgs.JudgeStruct()
			judge.play_animation = true
			judge.pattern = ".|diamond|.|.|."
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			player:obtainCard(judge.card)
		if judge:isGood() then
			return true
		elseif judge:isBad() then
			if player:hasSkill("TH_huanyue") and player:getMark("TH_huanyue_wake") == 0 then
				player:addMark("TH_huanyue_wake")
			end
		end
	end
}

----------------------------
TH_qed = sgs.CreateTriggerSkill{--qed
	name = "TH_qed",
	frequency = sgs.Skill_Frequent,
	events = {sgs.HpRecover},
	can_trigger = function(self,target)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _, fulan in sgs.qlist(room:getAlivePlayers()) do
			if fulan:hasSkill(self:objectName()) and room:askForSkillInvoke(fulan, self:objectName()) then
				fulan:drawCards(1)
			end
		end
	end
}

----------------------------
TH_mingke=sgs.CreateTriggerSkill{--铭刻
	name = "TH_mingke",
	frequency = sgs.Skill_Compulsory,
	events = {sgs. MaxHpChanged, sgs.PreHpLost, sgs.BeforeGameOverJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs. MaxHpChanged then
			local fuck_madai =player:getMaxHp()
			if fuck_madai<2 then
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(2))
			room:setPlayerProperty(player, "hp", sgs.QVariant(2))
			return true
			end
		elseif event == sgs.PreHpLost and player:getHp() < 2 then return true end
	end
}

--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------remiliascarlet
TH_HeartBreakCARD = sgs.CreateSkillCard{--必杀·碎心
	name = "TH_HeartBreakCARD",
	skill_name = "TH_HeartBreak",
	on_use = function(self, room, source, targets)
		targets[1]:gainMark("@TH_HeartBreak")
		room:setPlayerMark(targets[1], "TH_HeartBreak_target" .. source:objectName(), 1)
	end
}

TH_HeartBreakVS = sgs.CreateViewAsSkill{
	name = "TH_HeartBreak",
	n = 0,
	view_as = function(self, cards)
		local card = TH_HeartBreakCARD:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_HeartBreakCARD")
	end
}
TH_HeartBreak = sgs.CreateTriggerSkill{
	name = "TH_HeartBreak",
	events = { sgs.EventPhaseEnd },
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_HeartBreakVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and (player:getPhase() == sgs.Player_Finish or player:getPhase() == sgs.Player_NotActive) then
			for _, sb in sgs.qlist(room:getOtherPlayers(player)) do
				if sb:getMark("@TH_HeartBreak") > 0 and sb:getMark("TH_HeartBreak_target" .. player:objectName()) > 0 then
					sb:loseMark("@TH_HeartBreak")
					room:setPlayerMark(sb, "TH_HeartBreak_target" .. player:objectName(), 0)
				end
			end
		end
	end
}
TH_HeartBreak_effect = sgs.CreateTriggerSkill{
	name = "#TH_HeartBreak_effect",
	events = { sgs.PreHpRecover },
	frequency = sgs.Skill_Compulsory,
	priority = 9,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		if player:getMark("@TH_HeartBreak") > 0 then return true end
	end
}

TH_ScarletShootCARD = sgs.CreateSkillCard{--绯红之击
	name = "TH_ScarletShootCARD",
	skill_name = "TH_ScarletShoot",
	filter = function(self, targets, to_select)
		return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local sb = targets[1]
		local ids = sgs.IntList()
		for _, c in sgs.qlist(sb:getHandcards()) do
			if c:isRed() then ids:append(c:getEffectiveId()) end
		end
		if ids:length() > 0 then
			local reason = sgs.CardMoveReason()
			reason.m_reason = sgs.CardMoveReason_S_REASON_DISMANTLE
			reason.m_playerId = source:objectName()
			reason.m_skillName = "TH_ScarletShoot"
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = sb
			move.to_place = sgs.Player_DiscardPile
			move.reason = reason
			room:moveCardsAtomic(move, true)
		end
	end
}

TH_ScarletShootVS = sgs.CreateViewAsSkill{
	name = "TH_ScarletShoot",
	n = 0,
	view_as = function(self, cards)
		local card = TH_ScarletShootCARD:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_ScarletShootCARD")
	end
}
TH_ScarletShoot = sgs.CreateTriggerSkill{
	name = "TH_ScarletShoot",
	events = { sgs.NonTrigger },
	frequency = sgs.Skill_Limited,
	view_as_skill = TH_ScarletShootVS,
	on_trigger = function(self, event, player, data)
	end
}


TH_ScarletDestiny = sgs.CreateFilterSkill{--绯色命运
	name = "TH_ScarletDestiny",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		return room:getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceJudge
	end,
	view_as = function(self, card)
		local c = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		c:setSkillName(self:objectName())
		c:setSuit(sgs.Card_Heart)
		c:setModified(true)
		return c
	end,
}
TH_ScarletDestiny_obtain = sgs.CreateTriggerSkill{--绯色命运
	name = "#TH_ScarletDestiny_obtain",
	events = { sgs.FinishJudge },
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not player:hasSkill(self:objectName()) then return end
		local judge = data:toJudge()
		if judge.card:isRed() then
			player:obtainCard(judge.card)
		end
	end
}

TH_hongsebuyecheng = sgs.CreateTriggerSkill{--红色不夜城
	name = "TH_hongsebuyecheng",
	events = { sgs.EventPhaseEnd },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local remilias = room:findPlayersBySkillName(self:objectName())
			if remilias:isEmpty() then return end
			player:drawCards(1)
			if player:hasSkill(self:objectName()) then return end
			if player:getHandcardNum() > player:getHp() and not player:isKongcheng() then
				for _, remilia in sgs.qlist(remilias) do
					local id = room:askForCardChosen(remilia, player, "hej", self:objectName())
					local reason = sgs.CardMoveReason()
					reason.m_reason = sgs.CardMoveReason_S_REASON_EXTRACTION
					reason.m_playerId = remilia:objectName()
					reason.m_skillName = self:objectName()
					room:moveCardTo(sgs.Sanguosha:getCard(id), nil, remilia, sgs.Player_PlaceHand, reason, room:getCardPlace(id) ~= sgs.Player_PlaceHand)
				end
			end
		end
	end
}
--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------remiliascarlet_nos
TH_feixing = sgs.CreateDistanceSkill{--飞行
	name = "TH_feixing",
	correct_func = function(self, from, to)
		if from:hasSkill("TH_feixing") then
			return -1
		end
		if to:hasSkill("TH_feixing") then
			return 1
		end
	end
}

------------------------------------------
TH_RemiliaStalker = sgs.CreateTriggerSkill{--浩劫
	name = "TH_RemiliaStalker",
	events = {sgs.CardOffset},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.to and effect.card:isKindOf("Slash") and effect.to:isAlive() and effect.to:getCardCount(true) > 0 and effect.from:getCardCount(true) > 0
			and room:askForCard(player, ".", "TH_RemiliaStalker_discard", data, self:objectName()) then
			local acard = room:askForCardChosen(player,effect.to,"he",self:objectName())
			if acard then TH_obtainCard(effect.from, acard) end
		end
	end
}

----------------------------------------------------------
TH_hongsehuanxiangxiang=sgs.CreateTriggerSkill{--红色幻想乡
	name = "TH_hongsehuanxiangxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		player:drawCards(1)
	end
}

----------------------------------------------
TH_xixue=sgs.CreateTriggerSkill{--吸血
	name = "TH_xixue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local recover = sgs.RecoverStruct()
		recover.who = player
		room:recover(player, recover, true)
	end
}

--------------------------------------------------------------
TH_SpearTheGungnirCARD = sgs.CreateSkillCard{--神枪
	name = "TH_SpearTheGungnirCARD",
	skill_name = "TH_SpearTheGungnir",
	filter = function(self, targets, to_select)
		return #targets<1 and not to_select:hasSkill("TH_SpearTheGungnir")
	end,
	on_use = function(self, room, source, targets)
		for _, p in sgs.qlist(room:getOtherPlayers(targets[1])) do
			room:setFixedDistance(p, targets[1], 1)
		end
		targets[1]:addMark("TH_STG_target" .. source:objectName())
		room:setPlayerMark(targets[1], "&TH_SpearTheGungnir+to+#".. source:objectName(), 1)
		TH_logmessage("#TH_SpearTheGungnir", source, nil, targets[1])
	end
}

TH_SpearTheGungnirVS = sgs.CreateViewAsSkill{--神枪
	name = "TH_SpearTheGungnir",
	n = 0,
	view_as = function(self, cards)
		local Scard=TH_SpearTheGungnirCARD:clone()
		return Scard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_SpearTheGungnirCARD")
	end
}

TH_SpearTheGungnir = sgs.CreateTriggerSkill{--神枪
	name = "TH_SpearTheGungnir",
	events = {sgs.EventPhaseStart, sgs.Death},
	view_as_skill = TH_SpearTheGungnirVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			local sb
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("TH_STG_target"..player:objectName()) > 0 then
					room:setPlayerMark(p, "TH_STG_target"..player:objectName(), 0)
					room:setPlayerMark(p, "&TH_SpearTheGungnir+to+#".. player:objectName(), 0)
					sb = p
					break
				end
			end
			if not sb then return false end
			for _,p in sgs.qlist(room:getOtherPlayers(sb)) do
				room:removeFixedDistance(p, sb, 1)
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return end
			local sb
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("TH_STG_target"..player:objectName()) > 0 then
					room:setPlayerMark(p, "TH_STG_target"..player:objectName(), 0)
					sb = p
					break
				end
			end
			if not sb then return false end
			for _,p in sgs.qlist(room:getOtherPlayers(sb)) do
				room:removeFixedDistance(p, sb, 1)
			end
		end
	end
}

-------------------------------------------
TH_xingtaiCARD = sgs.CreateSkillCard{
	name = "TH_xingtaiCARD",
	skill_name = "TH_xingtai",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		if source:getMark("TH_xingtai1") == 0 then
			--room:broadcastSkillInvoke(self:objectName())
			room:detachSkillFromPlayer(source, "TH_SpearTheGungnir")
			room:detachSkillFromPlayer(source, "TH_RemiliaStalker")
			room:acquireSkill(source, "TH_xixue")
			room:acquireSkill(source, "TH_feixing")
			source:addMark("TH_xingtai1")
			source:removeMark("TH_xingtai2")
			--room:setEmotion(source,"RemiliaScarlet/1")
			local sb
			for _, ap in sgs.qlist(room:getOtherPlayers(source)) do
				if ap:getMark("TH_STG_target"..source:objectName())>0 then
					room:setPlayerMark(ap, "TH_STG_target"..source:objectName(), 0)
					room:setPlayerMark(ap, "&TH_SpearTheGungnir+to+#".. source:objectName(), 0)
					sb = ap
				end
			end
			if sb then
				for _,p in sgs.qlist(room:getOtherPlayers(sb)) do
					room:setFixedDistance(p, sb, -1)
				end
			end
		elseif source:getMark("TH_xingtai2") == 0 then
			--room:broadcastSkillInvoke(self:objectName())
			room:acquireSkill(source, "TH_SpearTheGungnir")
			room:acquireSkill(source, "TH_RemiliaStalker")
			room:detachSkillFromPlayer(source, "TH_xixue")
			room:detachSkillFromPlayer(source, "TH_feixing")
			source:addMark("TH_xingtai2")
			source:removeMark("TH_xingtai1")
			--room:setEmotion(source,"RemiliaScarlet/2")
		end
	end
}

TH_xingtaiVS = sgs.CreateViewAsSkill{--切换形态
    name = "TH_xingtai",
    n = 0,
	view_as = function(self, cards)
		local xtcard = TH_xingtaiCARD:clone()
		return xtcard
    end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_xingtaiCARD")
	end,
}
TH_xingtai = sgs.CreateTriggerSkill{--切换形态
	name = "TH_xingtai",
	frequency = sgs.Skill_Limited,
	events = {sgs.GameStart},
	view_as_skill = TH_xingtaiVS,
	on_trigger = function(self, event, player, data)
		player:addMark("TH_xingtai2")
	end
}

--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------izayoisakuya
TH_TheWorldCARD = sgs.CreateSkillCard{--the world
    name = "TH_TheWorldCARD",
	skill_name = "TH_TheWorld",
    target_fixed = true,
    will_throw = false,
	on_use = function(self, room, source, targets)
		-- room:broadcastInvoke("animate", "lightbox:TH_TheWorld:4000")
		room:doLightbox("#TH_TheWorld", 4000)
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
			room:setPlayerProperty(p, "faceup", sgs.QVariant(false))
			TH_logmessage("#TurnOver", p, "face_down")
		end
		source:drawCards(3)
		source:loseMark("@TH_theworld")
		room:acquireSkill(source, "TH_LunaClock")
		source:gainMark("@TH_lunaclock")
	end
}

TH_TheWorldVS = sgs.CreateViewAsSkill{--the world
    name = "TH_TheWorld",
    n = 0,
	view_as = function(self, cards)
		local TWcard = TH_TheWorldCARD:clone()
		return TWcard
    end,
	enabled_at_play = function(self, player)
		return player:getMark("@TH_theworld") == 1
	end
}

TH_TheWorld=sgs.CreateTriggerSkill{--the world
	name = "TH_TheWorld",
	frequency = sgs.Skill_Limited,
	events = {},
	view_as_skill = TH_TheWorldVS,
	limit_mark = "@TH_theworld",
	on_trigger = function(self, event, player, data)
	end
}

-----------------------------------------------------

TH_LunaClock=sgs.CreateTriggerSkill{--月时计
	name = "TH_LunaClock",
	events = {sgs.ConfirmDamage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to and not damage.to:faceUp() then
			TH_logmessage("#TriggerSkill", player, self:objectName())
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end
}

---------------------------------------------------------
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
TH_huanzang=sgs.CreateTriggerSkill{--幻葬
	name = "TH_huanzang",
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			local range = player:getAttackRange()
			for _, p in sgs.qlist(use.to) do
				if player:distanceTo(p) == 1 then
					jink_table[index] = 0
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			return false
	end
}

TH_Eternal=sgs.CreateTriggerSkill{--永恒
	name = "TH_Eternal",
	events = {sgs.Predamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and room:askForSkillInvoke(player,self:objectName(),data) then
			damage.from:drawCards(1)
			damage.to:turnOver()
			return true
		end
	end
}

----------------------
TH_Sakuya = sgs.CreateTriggerSkill{--咲夜世界
	name = "TH_Sakuya",
	events = {sgs.DamageForseen},
	priority = 5,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		if player:isNude() then return end
		local pattern = "."
		if da.from then
			if da.from:isMale() then pattern = ".|black"
			elseif da.from:isFemale() then pattern = ".|red"
			end
		end
		if room:askForCard(player, pattern, self:objectName(), data) then return true end
	end
}

--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------hakureireimu

TH_wujiecao=sgs.CreateTriggerSkill{--无节操
	name = "TH_wujiecao",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if not room:askForSkillInvoke(player,self:objectName(),data) then return end
		draw.num = math.random(0,10)
		if draw.num==0 then
			TH_logmessage("#TH_wujiecao0", player)
		elseif draw.num>0 and draw.num < 4 then
			TH_logmessage("#TH_wujiecao1", player)
		elseif draw.num >= 4 then
			TH_logmessage("#TH_wujiecao2", player)
		end
		data:setValue(draw)
	end
}

------------------------------------------------
TH_saiqianxiang = sgs.CreateMaxCardsSkill{--赛钱箱
	name = "TH_saiqianxiang",
	extra_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return player:getMaxHp()
		else
			return 0
		end
	end
}

------------------------------------------------
TH_nafengVS = sgs.CreateViewAsSkill{--纳奉
	name = "TH_nafeng",
	n = 0,
	view_as = function(self, cards)
		local nfcard = TH_nafengCARD:clone()
		return nfcard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@TH_nafeng") == 1
	end
}

TH_nafengCARD = sgs.CreateSkillCard{--纳奉
	name = "TH_nafengCARD",
	skill_name = "TH_nafeng",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		-- room:broadcastInvoke("animate", "lightbox:#TH_nafeng")
		room:doLightbox("#TH_nafeng", 2000)
		source:loseMark("@TH_nafeng")
		local log = sgs.LogMessage()
		log.type = "#TH_nafeng"
		room:sendLog(log)
		room:setPlayerFlag(source, "TH_nafenging")
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
			if not p:getCards("hej"):isEmpty() then
				local card_id = room:askForCardChosen(source, p, "hej", self:objectName())
				TH_obtainCard(source, card_id)
			end
		end
		room:setPlayerFlag(source, "-TH_nafenging")
	end
}

TH_nafeng=sgs.CreateTriggerSkill{--纳奉
	name = "TH_nafeng",
	frequency = sgs.Skill_Limited,
	events = {},
	view_as_skill = TH_nafengVS,
	limit_mark = "@TH_nafeng",
	on_trigger = function(self, event, player, data)
	end
}

TH_bianshen_MagakiReimu = sgs.CreateTriggerSkill{--变身
	name = "#TH_bianshen_MagakiReimu",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() and dying.who:hasSkill(self:objectName()) and player:aliveCount() == playerNumber(player, true) then
			local num = player:getCardCount(true)
			player:throwAllCards()
			local issecond = player:getGeneral2() and player:getGeneral2Name() == "HakureiReimu"
			if player:getGeneralName() == "HakureiReimu" then issecond = false end
			room:changeHero(player, "MagakiReimu",true, true, issecond, false)
			player:addMark("changeHero_MagakiReimu")
			if num > 0 then player:drawCards(num) end
			room:setPlayerFlag(player, "-Global_Dying")
			local currentdying = room:getTag("CurrentDying"):toStringList()
			table.removeOne(currentdying,player:objectName())
			room:setTag("CurrentDying", sgs.QVariant(table.concat(currentdying, "|")))
		end
	end
}

--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------kotiyasanae
TH_wugufengdeng = sgs.CreateViewAsSkill{--五谷丰登
	name = "TH_wugufengdeng",
	n = 0,
	view_as = function(self, cards)
		local aaacard = TH_wugufengdengCARD:clone()
		return aaacard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_wugufengdengCARD")
	end
}

TH_wugufengdengCARD = sgs.CreateSkillCard{--五谷丰登
	name = "TH_wugufengdengCARD",
	skill_name = "TH_wugufengdeng",
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets < 5
	end,
	on_use = function(self, room, source, targets)
		local card_ids = room:getNCards(#targets + 2)
		room:fillAG(card_ids)
		for _, player in ipairs(targets) do
			local cardid
			cardid = room:askForAG(player, card_ids, false, self:objectName())
			if cardid == -1 then
				cardid = card_ids:first()
			end
			card_ids:removeOne(cardid)
			room:takeAG(player, cardid)
		end
		room:clearAG()
		local move = sgs.CardsMoveStruct()
		move.card_ids = card_ids
		move.to_place = sgs.Player_DiscardPile
		move.reason.m_reason = sgs.CardMoveReason_S_REASON_PUT
		room:moveCardsAtomic(move, true)
	end
}

------------------------------------------
TH_Wonder_NwOBNSVS = sgs.CreateViewAsSkill{--奇迹-辉煌
	name = "TH_Wonder_NwOBNS",
	n = 0,
	view_as = function(self, cards)
		local W1card = TH_Wonder_NwOBNSCARD:clone()
		return W1card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_Wonder_NwOBNSCARD")
	end
}

TH_Wonder_NwOBNSCARD = sgs.CreateSkillCard{--奇迹-辉煌
	name = "TH_Wonder_NwOBNSCARD",
	skill_name = "TH_Wonder_NwOBNS",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMark("@TH_nwobns") == 0
	end,
	on_use = function(self, room, source, targets)
		TH_logmessage("#TH_nwobns", targets[1])
		targets[1]:gainMark("@TH_nwobns")
		room:setPlayerMark(source,"TH_Wonder_NwOBNS_source" .. targets[1]:objectName(), 1)
		room:setPlayerMark(targets[1], "TH_Wonder_NwOBNS_target" .. source:objectName(), 1)
	end
}

TH_Wonder_NwOBNS = sgs.CreateTriggerSkill{--奇迹-辉煌
	name = "TH_Wonder_NwOBNS",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart, sgs.Death},
	priority = 3,
	view_as_skill = TH_Wonder_NwOBNSVS,
	can_trigger = function(self, player)
		return player
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			if player:getMark("@TH_nwobns") == 0 then return end
			local sanaes = room:findPlayersBySkillName(self:objectName())
			for _,sanae in sgs.qlist(sanaes) do
				if player:getMark("TH_Wonder_NwOBNS_target" .. sanae:objectName()) > 0 and sanae:getMark("TH_Wonder_NwOBNS_source" .. player:objectName()) > 0 then
					room:setPlayerMark(sanae, "TH_Wonder_NwOBNS_source" .. player:objectName(), 0)
					room:setPlayerMark(player, "TH_Wonder_NwOBNS_target" .. sanae:objectName(), 0)
					local choice = room:askForChoice(sanae, self:objectName(), "recoversb+damagesb")
					if choice == "recoversb" then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover, true)
						player:loseAllMarks("@TH_nwobns")
					elseif choice == "damagesb" then
						local damage = sgs.DamageStruct()
						damage.to = player
						room:damage(damage)
						player:loseAllMarks("@TH_nwobns")
					end
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:hasSkill(self:objectName()) then
				for _, ap in sgs.qlist(room:getAlivePlayers()) do
					if ap:getMark("TH_Wonder_NwOBNS_target" .. death.who:objectName()) > 0
						and death.who:getMark("TH_Wonder_NwOBNS_source" .. ap:objectName()) > 0
						and ap:getMark("@TH_nwobns") then
						room:setPlayerMark(death.who, "TH_Wonder_NwOBNS_source" .. ap:objectName(), 0)
						room:setPlayerMark(ap, "TH_Wonder_NwOBNS_target" .. death.who:objectName(), 0)
						ap:loseAllMarks("@TH_nwobns")
					end
				end
			end
		end
	end
}

-------------------------------------------------------
TH_Miracle_GodsWindVS = sgs.CreateViewAsSkill{--奇迹-风
	name = "TH_Miracle_GodsWind",
	n = 0,
	view_as = function(self, cards)
		local W1card = TH_Miracle_GodsWindCARD:clone()
		return W1card
    end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_Miracle_GodsWindCARD")
	end
}

TH_Miracle_GodsWindCARD = sgs.CreateSkillCard{--奇迹-风
	name = "TH_Miracle_GodsWindCARD",
	skill_name = "TH_Miracle_GodsWind",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMark("@TH_godswind") == 0
	end,
	on_use = function(self, room, source, targets)
		targets[1]:gainMark("@TH_godswind")
		TH_logmessage("#TH_godswind", targets[1])
		room:setPlayerMark(source,"TH_Miracle_GodsWind_source" .. targets[1]:objectName(), 1)
		room:setPlayerMark(targets[1], "TH_Miracle_GodsWind_target" .. source:objectName(), 1)
	end
}

TH_Miracle_GodsWind=sgs.CreateTriggerSkill{--奇迹-风
	name = "TH_Miracle_GodsWind",
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseStart, sgs.Death},
	view_as_skill = TH_Miracle_GodsWindVS,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			local sanaes = room:findPlayersBySkillName(self:objectName())
			for _,sanae in sgs.qlist(sanaes) do
				if player:getMark("@TH_godswind") == 0 then return end
				if player:getMark("TH_Miracle_GodsWind_target" .. sanae:objectName()) > 0 and sanae:getMark("TH_Miracle_GodsWind_source" .. player:objectName()) > 0 then
					room:setPlayerMark(player, "TH_Miracle_GodsWind_target" .. sanae:objectName(), 0)
					room:setPlayerMark(sanae, "TH_Miracle_GodsWind_source" .. player:objectName(), 0)
					local choice = room:askForChoice(sanae, self:objectName(), "drawsb+dissb")
					player:loseAllMarks("@TH_godswind")
					if choice == "drawsb" then
						player:drawCards(2)
					elseif choice == "dissb" then
						if player:getHandcardNum() >= 2 then
							room:askForDiscard(player, self:objectName(), 2, 2, false, false)
						else
							player:throwAllHandCards()
						end
					end
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:hasSkill(self:objectName()) then
				for _, ap in sgs.qlist(room:getAlivePlayers()) do
					if ap:getMark("TH_Miracle_GodsWind_target" .. death.who:objectName()) > 0
						and death.who:getMark("TH_Miracle_GodsWind_source" .. ap:objectName()) > 0
						and ap:getMark("@TH_nwobns") then
						room:setPlayerMark(death.who, "TH_Miracle_GodsWind_source" .. ap:objectName(), 0)
						room:setPlayerMark(ap, "TH_Miracle_GodsWind_target" .. death.who:objectName(), 0)
						ap:loseAllMarks("@TH_godswind")
					end
				end
			end
		end
	end
}


--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------saigyoujiyuyuko
TH_fanhundieVS = sgs.CreateViewAsSkill{--反魂蝶
	name = "TH_fanhundie",
	n = 0,
	view_as = function(self, cards)
		local fcard = TH_fanhundieCARD:clone()
		return fcard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@TH_fhdonce") == 1
	end
}

TH_fanhundieCARD = sgs.CreateSkillCard{--反魂蝶
	name = "TH_fanhundieCARD",
	skill_name = "TH_fanhundie",
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and to_select:getMark("@TH_fanhundie") == 0
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@TH_fhdonce")
		targets[1]:gainMark("@TH_fanhundie")
		room:setPlayerMark(targets[1], "TH_fanhundie_target" .. source:objectName(), 1)
		room:setPlayerMark(targets[1], "&TH_fanhundie+to+#" .. source:objectName(), 1)

	end
}

TH_fanhundie=sgs.CreateTriggerSkill{--反魂蝶
	name = "TH_fanhundie",
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseEnd, sgs.EventPhaseStart, sgs.Death},
	view_as_skill = TH_fanhundieVS,
	limit_mark = "@TH_fhdonce",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			if player:getMark("@TH_fhdonce") == 1 then return false end
			local sb
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@TH_fanhundie") > 0 and p:getMark("TH_fanhundie_target" .. player:objectName()) > 0 then
					sb = p
					break
				end
			end
			if not sb then player:gainMark("@TH_fhdonce") end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			if player:getMark("@TH_fhdonce") == 1 then return false end
			local sb
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@TH_fanhundie") > 0 and p:getMark("TH_fanhundie_target" .. player:objectName()) > 0 then
					sb = p
					break
				end
			end
			if not sb then
				player:gainMark("@TH_fhdonce")
			else
				TH_logmessage("#TH_fhd", player, nil, sb)
				if sb:getMark("@TH_fanhundie") == 1 then
					if sb:getHandcardNum() >= 2 then
						room:askForDiscard(sb, self:objectName(), 2, 2, false, false)
					else
						sb:throwAllHandCards()
					end
					sb:gainMark("@TH_fanhundie", 2)
					player:addMark("TH_xixingyao1")
				elseif sb:getMark("@TH_fanhundie") == 3 then
					if sb:getHandcardNum() >= 3 then
						room:askForDiscard(sb, self:objectName(), 3, 3, false, false)
					else
						sb:throwAllHandCards()
					end
					sb:gainMark("@TH_fanhundie", 2)
					player:addMark("TH_xixingyao2")
				elseif sb:getMark("@TH_fanhundie") == 5 then
					room:loseHp(sb)
					if sb:isAlive() then sb:gainMark("@TH_fanhundie", 3)
					else sb:loseAllMarks("@TH_fanhundie") end
					player:addMark("TH_xixingyao3")
				elseif sb:getMark("@TH_fanhundie") == 8 then
					room:setPlayerMark(sb, "TH_fanhundie_target" .. player:objectName(), 0)
					room:setPlayerMark(sb, "&TH_fanhundie+to+#" .. player:objectName(), 0)
					room:loseMaxHp(sb)
					room:loseHp(sb)
					sb:loseAllMarks("@TH_fanhundie")
					player:gainMark("@TH_fhdonce")
					player:addMark("TH_xixingyao4")
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then return end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("@TH_fanhundie") > 0 and p:getMark("TH_fanhundie_target" .. player:objectName()) > 0 then
					room:setPlayerMark(p, "@TH_fanhundie", 0)
				end
			end
		end
	end
}

--------------------------xixingyao
TH_xixingyaoVS = sgs.CreateViewAsSkill{--西行妖
	name = "TH_xixingyao",
	n = 0,
	view_as = function(self, cards)
		local fcard = TH_xixingyaoCARD:clone()
		return fcard
    end,
	enabled_at_play = function(self, player)
		return true
	end,
}

TH_xixingyaoCARD = sgs.CreateSkillCard{--西行妖
	name = "TH_xixingyaoCARD",
	skill_name = "TH_xixingyao",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local x, y, z = 0, 0, 0
		if source:getMark("TH_xixingyao1") > 0 then
			x = x + source:getMark("TH_xixingyao1") * 2
		end
		if source:getMark("TH_xixingyao2") > 0 then
			x = x + source:getMark("TH_xixingyao2") * 3
		end
		if source:getMark("TH_xixingyao3") > 0 then
			y = y + source:getMark("TH_xixingyao3")
		end
		if source:getMark("TH_xixingyao4") > 0 then
			y = y + source:getMark("TH_xixingyao4")
			z = z + source:getMark("TH_xixingyao4")
		end
		TH_logmessage("#TH_xixingyaomessage1", source, z, nil, y)
		TH_logmessage("#TH_xixingyaomessage2", source, x)
		if x == 0 and y == 0 and z == 0 then return false end
		if not room:askForSkillInvoke(source,"TH_xixingyao") then return false end
		if x > 0 then
			source:drawCards(x)
		end
		if z > 0 then
			room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp() + z))
		end
		if y > 0 then
			local re = sgs.RecoverStruct()
			re.who = source
			re.recover = y
			room:recover(source, re, true)
		end
		source:setMark("TH_xixingyao1", 0)
		source:setMark("TH_xixingyao2", 0)
		source:setMark("TH_xixingyao3", 0)
		source:setMark("TH_xixingyao4", 0)
	end
}

TH_xixingyao = sgs.CreateTriggerSkill{--西行妖
	name = "TH_xixingyao",
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_xixingyaoVS,
	events = {sgs.NonTrigger},
	on_trigger = function(self, event, player, data)
	end
}

-----------------
TH_chihuo = sgs.CreateViewAsSkill{--吃货
	name = "TH_chihuo",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return #selected<1 and not to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local new_card =sgs.Sanguosha:cloneCard("peach", cards[1]:getSuit(), cards[1]:getNumber())
			new_card:addSubcard(cards[1]:getId())
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end,
	enabled_at_play = function(self, player)
		return player:isWounded() and not player:hasUsed("#TH_chihuo")
	end,
	enabled_at_response = function(self, player, pattern)
	    return string.find(pattern, "peach")
	end
}

--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------KonpakuYoumu

TH_renguiVS = sgs.CreateViewAsSkill{--人鬼未来永劫斩
	name = "TH_rengui",
	n = 0,
	view_as = function(self, cards)
	local card = TH_renguiCARD:clone()
		return card
    end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_renguiCARD")
	end
}

TH_renguiCARD = sgs.CreateSkillCard{--人鬼未来永劫斩
	name = "TH_renguiCARD",
	skill_name = "TH_rengui",
	filter = function(self, targets, to_select)
		return #targets == 0 --and not to_select:isLord()
	end,
	on_use = function(self, room, source, targets)
		local t = targets[1]
		for i=1,5,1 do
			if t:isDead() or t == nil then return false end
			local cardid = sgs.IntList()
			local acard = room:drawCard()
			cardid:append(acard)
			local card = sgs.Sanguosha:getCard(acard)
			local move = sgs.CardsMoveStruct()
			move.card_ids = cardid
			move.to_place = sgs.Player_PlaceTable
			move.reason.m_reason = sgs.CardMoveReason_S_REASON_TURNOVER
			room:moveCardsAtomic(move, true)
			card:setSkillName("TH_rengui")
			if card:isKindOf("Peach") then
				room:loseMaxHp(t)
				room:throwCard(card, nil)
			elseif card:isKindOf("Slash") then
				local damage = sgs.DamageStruct()
				damage.from = source
				damage.to = t
				damage.card = card
				room:damage(damage)
				if room:getCardPlace(card:getId()) == sgs.Player_PlaceTable then
					room:throwCard(card, nil)
				end
			elseif card:isKindOf("Jink") then
				room:throwCard(card, nil)
				if t:getHandcardNum() == 0 then
					source:drawCards(1)
				elseif t:getHandcardNum() > 0 then
					room:askForDiscard(t, "TH_rengui", 1, 1, false, false)
					source:drawCards(1)
				end
			else
				room:throwCard(card, nil)
			end
		end
	end
}

TH_rengui = sgs.CreateTriggerSkill{--人鬼未来永劫斩
	name = "TH_rengui",
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_renguiVS,
	events = {sgs.NonTrigger},
	on_trigger = function(self, event, player, data)
	end
}

---------------------------------------------
TH_erdaoliuCARD = sgs.CreateSkillCard{--二刀流
	name = "TH_erdaoliuCARD",
	skill_name = "TH_erdaoliu",
	will_throw = true,
	filter = function(self, targets, to_select)
		return sgs.Self:canSlash(to_select) and #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
		slash:addSubcard(self:getSubcards():first())
		slash:setSkillName("TH_erdaoliu")
		room:useCard(sgs.CardUseStruct(slash, source, targets[1]), false)
	end
}

TH_erdaoliu = sgs.CreateViewAsSkill{--二刀流
	name = "TH_erdaoliu",
	response_pattern = "slash",
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return #selected < 1 and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
				local slashcard = TH_erdaoliuCARD:clone()
				slashcard:addSubcard(cards[1])
				return slashcard
			else
				local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
				slash:addSubcard(cards[1])
				return slash
			end
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_erdaoliuCARD")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}

--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------HouraisanKaguya
--[[
永夜归返　-待宵-
永夜归返　-永世光明-
蓬莱的树海
]]
TH_ShenbaoPLYZCARD = sgs.CreateSkillCard{
	name = "TH_ShenbaoPLYZCARD",
	skill_name = "TH_ShenbaoPLYZ",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		for i = 0, sgs.Sanguosha:getCardCount() - 1 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card:getClassName() == "TH_Weapon_Penglaiyuzhi" then
				room:useCard(sgs.CardUseStruct(card, source, source))
				break
			end
		end
	end
}

TH_ShenbaoPLYZVS = sgs.CreateViewAsSkill{
	name = "TH_ShenbaoPLYZ",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return end
		local scard = TH_ShenbaoPLYZCARD:clone()
		scard:addSubcard(cards[1])
		scard:setSkillName(self:objectName())
		return scard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_ShenbaoPLYZCARD") and not player:hasWeapon("TH_Weapon_Penglaiyuzhi")
	end,
}

TH_ShenbaoPLYZ = sgs.CreateTriggerSkill{
	name = "TH_ShenbaoPLYZ",
	frequency = sgs.Skill_Limited,
	events = { sgs.NonTrigger },
	priority = -33,
	view_as_skill = TH_ShenbaoPLYZVS,
	on_trigger = function(self, event, player, data)
	end
}

TH_YongyeguifanDaixiaoCARD = sgs.CreateSkillCard{
	name = "TH_YongyeguifanDaixiaoCARD",
	skill_name = "TH_YongyeguifanDaixiao",
	on_use = function(self, room, source, targets)
		targets[1]:gainMark("@TH_YongyeguifanDaixiao")
		room:setPlayerMark(targets[1], "TH_YongyeguifanDaixiao_target_" .. source:objectName(), 1)
	end
}

TH_YongyeguifanDaixiaoVS = sgs.CreateViewAsSkill{
	name = "TH_YongyeguifanDaixiao",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = TH_YongyeguifanDaixiaoCARD:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_YongyeguifanDaixiaoCARD")
	end,
}

TH_YongyeguifanDaixiao = sgs.CreateTriggerSkill{
	name = "TH_YongyeguifanDaixiao",
	view_as_skill = TH_YongyeguifanDaixiaoVS,
	events = { sgs.EventPhaseEnd },
	can_trigger = function(self, target)
		return target and target:getPhase() == sgs.Player_Draw
	end,
	on_trigger = function(self, event, player, data)
		if player:getMark("@TH_YongyeguifanDaixiao") <= 0 then return false end
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			for _, kaguya in sgs.qlist(room:getOtherPlayers(player)) do
				if kaguya:hasSkill(self:objectName()) and player:getMark("TH_YongyeguifanDaixiao_target_" .. kaguya:objectName()) > 0 then
					room:setPlayerMark(player, "TH_YongyeguifanDaixiao_target_" .. kaguya:objectName(), 0)
					player:loseMark("@TH_YongyeguifanDaixiao")
					local count = math.floor(player:getHandcardNum() / 2)
					TH_logmessage("#TriggerSkill", kaguya, self:objectName())
					local Card = room:askForExchange(player, self:objectName(), count, count, true, "#TH_YongyeguifanDaixiao::count", false)
					local move = sgs.CardsMoveStruct()
					move.from = player
					move.to = kaguya
					move.card_ids = Card:getSubcards()
					move.to_place = sgs.Player_PlaceHand
					move.reason.m_reason = sgs.CardMoveReason_S_REASON_GIVE
					room:moveCardsAtomic(move, false)
				end
			end
		end
	end
}

TH_YongyeguifanYongshiguangming = sgs.CreateTriggerSkill{
	name = "TH_YongyeguifanYongshiguangming",
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, Kaguya, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Discard then
			local room = Kaguya:getRoom()
			if Kaguya:getHandcardNum() > 0 and room:askForSkillInvoke(Kaguya, self:objectName(), data) then
				room:showAllCards(Kaguya)
				Kaguya:skip(sgs.Player_Discard)
			end
		end
	end
}


--------●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●------------------HouraisanKaguya_Nos
TH_yongyefan = sgs.CreateTriggerSkill{--永夜返
	name = "TH_yongyefan",
	events = { sgs.GameStart, sgs.MaxHpChanged },
	frequency = sgs.Skill_Compulsory,
	priority = -10,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:setTag("TH_yongyefan"..player:objectName(), sgs.QVariant(player:getMaxHp()))
		elseif event == sgs.MaxHpChanged then
			local value = room:getTag("TH_yongyefan"..player:objectName()):toInt()
			if value and value < player:getMaxHp() then
				room:setTag("TH_yongyefan"..player:objectName(), sgs.QVariant(player:getMaxHp()))
			end
		end
	end
}

TH_yongyefanTS = sgs.CreateTriggerSkill{--永夜返
	name = "#TH_yongyefanTS",
	events = { sgs.TurnStart },
	frequency = sgs.Skill_Compulsory,
	priority = -10,
	can_trigger = function(self, player)
		return player
	end,
	on_trigger = function(self, event, player, data)
		if not player:getNextAlive():hasSkill(self:objectName()) then return end
		local room = player:getRoom()
		local nextp = player:getNextAlive()
		local value = room:getTag("TH_yongyefan"..nextp:objectName()):toInt()
		TH_logmessage("$AppendSeparator", player)
		room:setPlayerProperty(nextp, "maxhp", sgs.QVariant(value))
		room:setPlayerProperty(nextp, "hp", sgs.QVariant(value))
		TH_logmessage("#TH_yongyefan", nextp, self:objectName(), nil, value)
	end
}


---------------------------------------

TH_nanti= sgs.CreateViewAsSkill{--难题
	name = "TH_nanti",
	n = 0,
	view_as = function(self, cards)
		local Ncard=TH_nantiCARD:clone()
		return Ncard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_nantiCARD")
	end
}

TH_nantiCARD = sgs.CreateSkillCard{----难题
	name = "TH_nantiCARD",
	skill_name = "TH_nanti",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getCardCount(true)>0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if not target then return false end
		room:setPlayerMark(target, "TH_nanti_target", 1)
		local cardid = sgs.IntList()
		local acard = room:drawCard()
		cardid:append(acard)
		local card = sgs.Sanguosha:getCard(acard)
		local cardsuit = card:getSuitString()
		local number = card:getNumber()
		local move = sgs.CardsMoveStruct()
		move.card_ids = cardid
		move.to_place = sgs.Player_PlaceTable
		move.reason.m_reason = sgs.CardMoveReason_S_REASON_TURNOVER
		room:moveCardsAtomic(move, true)
		room:throwCard(card, nil)
		local choice = room:askForChoice(source, "TH_nanti", "nantisuit+nantibig+nantismall+nantiequip+nantisuicide")
		if choice == "nantisuit" then
			card1 = room:askForCard(target, ".|"..cardsuit.."|.|hand|.", "@TH_nanti1",sgs.QVariant(acard), "TH_nanti")
			room:setPlayerMark(target, "TH_nanti_target", 0)
			if card1 ~= nil then
				target:drawCards(1)
			else
				room:loseHp(target)
				return
			end
		elseif choice == "nantibig" then
			card2 = room:askForCard(target, ".|.|"..number.."~13|hand", "@TH_nanti2",sgs.QVariant(acard), "TH_nanti")
			room:setPlayerMark(target, "TH_nanti_target", 0)
			if card2 ~= nil then
				target:drawCards(1)
			else
				room:loseHp(target)
				return
			end
		elseif choice == "nantismall" then
			card3 = room:askForCard(target, ".|.|1~"..number.."|hand", "@TH_nanti3",sgs.QVariant(acard), "TH_nanti")
			room:setPlayerMark(target, "TH_nanti_target", 0)
			if card3 ~= nil then
				target:drawCards(1)
			else
				room:loseHp(target)
				return
			end
		elseif choice == "nantiequip" then
			card4 = room:askForCard(target, "EquipCard|.|.|.", "@TH_nanti4",sgs.QVariant(acard), "TH_nanti")
			target:removeMark("TH_nanti_target")
			if card4 ~= nil then
				target:drawCards(1)
			else
				room:loseHp(target)
			return
			end
		elseif choice == "nantisuicide" then
			local suicidechoice = room:askForChoice(target, "TH_nantisuicide", "suicideyes+suicideno")
			room:setPlayerMark(target, "TH_nanti_target", 0)
			if suicidechoice == "suicideyes" then
				local damage = sgs.DamageStruct()
				damage.from = target
				room:killPlayer(target,damage)
			elseif suicidechoice =="suicideno" then
				local log2 = sgs.LogMessage()
				log2.type = "#suicideno"
				log2.to:append(target)
				room:sendLog(log2)
				room:setPlayerMark(target, "TH_nanti_suicideno", 1)
				return
			end
		end
	end
}

---------------------------------------------
TH_penglaiyuzhiCARD = sgs.CreateSkillCard{--蓬莱玉枝
	name = "TH_penglaiyuzhiCARD",
	skill_name = "TH_penglaiyuzhi",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		if source:getPile("TH_lightpile"):length() <=6  then
			source:addToPile("TH_lightpile", self, false)
		elseif source:getPile("TH_lightpile"):length() >6 then
			source:clearOnePrivatePile("TH_lightpile")
			room:addPlayerMark(source, "TH_plyzDRAW")
			room:addPlayerMark(source, "&TH_penglaiyuzhi")
		end
	end
}

TH_penglaiyuzhiVS = sgs.CreateViewAsSkill{--蓬莱
	name = "TH_penglaiyuzhi",
	n = 7,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		local lightcard = TH_penglaiyuzhiCARD:clone()
		lightcard:setSkillName(self:objectName())
		local n = sgs.Self:getPile("TH_lightpile"):length()
		if #cards > 7-n then return false end
		if #cards > 0 then
			for _,card in ipairs(cards) do
				lightcard:addSubcard(card)
			end
				return lightcard
		elseif #cards ==0 and sgs.Self:getPile("TH_lightpile"):length() >6 then
			return lightcard
		end
	end,
	enabled_at_play = function(self, player)
		return player:getPile("TH_lightpile"):length() >6 or not player:isKongcheng()
	end,
}

TH_penglaiyuzhi = sgs.CreateTriggerSkill{--蓬莱
	name = "TH_penglaiyuzhi",
	frequency = sgs.Skill_Wake,
	events = {sgs.DrawNCards, sgs.EventPhaseEnd},
	view_as_skill = TH_penglaiyuzhiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			local y = player:getMark("TH_plyzDRAW")
			draw.num = draw.num + y
			data:setValue(draw)
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			if player:getPile("TH_lightpile"):length() >= 7 then
				player:clearOnePrivatePile("TH_lightpile")
				room:addPlayerMark(player, "TH_plyzDRAW")
			end
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------yagokoroeirin
TH_yongye = sgs.CreateDistanceSkill{--永夜
	name = "TH_yongye",
	correct_func=function(self, from, to)
		if to:hasSkill(self:objectName()) then
			return to:getLostHp() + 1
		end
	end,
}

TH_sijianzhinao =  sgs.CreateTriggerSkill{
	name = "TH_sijianzhinao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if effect.card:isKindOf("Indulgence") or effect.card:isKindOf("SupplyShortage") then
			TH_logmessage("#TH_sijianzhinao", player, self:objectName(), nil, effect.card:objectName())
			return true
		end
	end
}

-- TH_sijianzhinaoOLD = sgs.CreateProhibitSkill{ --思兼之脑
	-- name = "TH_sijianzhinaoOLD",
	-- is_prohibited = function(self, from, to, card, others)
		-- if to:hasSkill(self:objectName()) and card then
			-- return (card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage"))
		-- end
		-- return false
	-- end
-- }

TH_penglaizhiyaoVS = sgs.CreateViewAsSkill{----蓬莱之药
	name = "TH_penglaizhiyao",
	n = 0,
	view_as = function(self, cards)
		local pcard=TH_penglaizhiyaoCARD:clone()
		return pcard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@TH_plzy") > 0
	end
}

TH_penglaizhiyaoCARD = sgs.CreateSkillCard{----蓬莱之药
	name = "TH_penglaizhiyaoCARD",
	skill_name = "TH_penglaizhiyao",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@TH_plzy")
		room:setPlayerProperty(targets[1], "maxhp", sgs.QVariant(targets[1]:getMaxHp() + 1))
		room:setPlayerProperty(targets[1], "hp", sgs.QVariant(targets[1]:getHp() + 1))
		local log= sgs.LogMessage()
		log.type = "#penglaizhiyao_use"
		log.from = source
		log.to:append(targets[1])
		room:sendLog(log)
	end
}

TH_penglaizhiyao = sgs.CreateTriggerSkill{---蓬莱之药
	name = "TH_penglaizhiyao",
	events = {sgs.TurnStart, sgs.GameStart},
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_penglaizhiyaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:setPlayerMark(player, "@TH_plzy", 1)
		else
			if player:getMark("@TH_plzy1") < 1 and player:getMark("@TH_plzy2") < 1 and player:getMark("@TH_plzy3") < 1 and player:getMark("@TH_plzy") < 1 then
				player:gainMark("@TH_plzy1")
			elseif player:getMark("@TH_plzy1") > 0 then
				player:loseMark("@TH_plzy1")
				player:gainMark("@TH_plzy2")
			elseif player:getMark("@TH_plzy2") > 0 then
				player:loseMark("@TH_plzy2")
				player:gainMark("@TH_plzy3")
			elseif player:getMark("@TH_plzy3") > 0 then
				player:loseMark("@TH_plzy3")
				player:gainMark("@TH_plzy")
				TH_logmessage("#penglaizhiyao", player)
			end
		end
	end
}

TH_LifeGameCARD = sgs.CreateSkillCard{------生命游戏
	name = "TH_LifeGameCARD",
	skill_name = "TH_LifeGame",
	on_use = function(self, room, source, targets)
		local cardid = sgs.IntList()
		local acard = room:drawCard()
		cardid:append(acard)
		local card = sgs.Sanguosha:getCard(acard)
		local move = sgs.CardsMoveStruct()
		move.card_ids = cardid
		move.to_place = sgs.Player_PlaceTable
		move.reason.m_reason = sgs.CardMoveReason_S_REASON_TURNOVER
		room:moveCardsAtomic(move, true)
		local da = sgs.DamageStruct()
		da.from = source
		da.to = targets[1]
		da.damage = 1
		da.nature = sgs.DamageStruct_Thunder
		if card:getNumber()<7 then
			room:damage(da)
			if targets[1]:isAlive() then room:obtainCard(targets[1], card) end
		elseif card:getNumber()>6 and card:getNumber()<13 then
			room:damage(da)
			if targets[1]:isAlive() then room:obtainCard(targets[1], card) end
			if targets[1]:getCardCount(true) == 0 then return false end
			local acard = room:askForCardChosen(source, targets[1], "he", self:objectName())
			room:obtainCard(source, acard)
		elseif card:getNumber()== 13 then
			local da = sgs.DamageStruct()
			da.from = source
			da.to = targets[1]
			da.damage = targets[1]:getHp()
			da.nature = sgs.DamageStruct_Thunder
			room:damage(da)
			if targets[1]:isAlive() then room:obtainCard(targets[1], card) end
		end
	end
}

TH_LifeGame = sgs.CreateViewAsSkill{-----生命游戏
	name= "TH_LifeGame",
	view_as = function(self, cards)
		local lifecard = TH_LifeGameCARD:clone()
		return lifecard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_LifeGameCARD")
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------reisenudongeininaba
TH_xiepohuanjue = sgs.CreateTargetModSkill{
	name = "TH_xiepohuanjue",
	pattern = "Slash,Snatch",
    extra_target_func = function(self, from, card)
		if from:getWeapon() and from:hasSkill(self:objectName()) and card:isKindOf("Slash") then return 2 end
	end,
	distance_limit_func = function(self, from, card)
		if from:hasSkill("TH_GreatestTreasure") and card:isKindOf("Snatch") then return 999 end
	end,
}

TH_huanlongyueni=sgs.CreateTriggerSkill{----幻胧月睨
	name = "TH_huanlongyueni",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	priority = 3,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da=data:toDamage()
		if not da.to or da.to:isDead() then return end
		if not room:askForSkillInvoke(da.to,self:objectName(),data) then return end
		local equips = da.to:getEquips():length() + 2
		for i = 1, da.damage do
			local cardlist = sgs.IntList()
			for i = 1, equips do
				cardlist:append(room:drawCard())
				local move = sgs.CardsMoveStruct()
				move.card_ids = cardlist
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				move.reason.m_reason = sgs.CardMoveReason_S_REASON_SHOW
				room:moveCardsAtomic(move, false)
				if not cardlist:isEmpty() then
					room:askForYiji(player, cardlist, self:objectName())
				end
			end
		end
	end
}

TH_yuetubingqi = sgs.CreateViewAsSkill{----月兔兵器
	name= "TH_yuetubingqi",
	view_as = function(self, cards)
		return TH_yuetubingqiCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_yuetubingqiCARD")
	end
}

TH_yuetubingqiCARD = sgs.CreateSkillCard{----月兔兵器
	name = "TH_yuetubingqiCARD",
	skill_name = "TH_yuetubingqi",
	target_fixed =true,
	on_use = function(self, room, source, targets)
		if room:getDrawPile():length() == 0 then room:swapPile(false) end
		local cards = room:getDrawPile()
		local n = cards:length()
		local z = 0
		for i = 1, math.min(n, 4) do
			local cardsid = cards:at(math.random(0, n - 1))
			room:showCard(source, cardsid)
			local card = sgs.Sanguosha:getCard(cardsid)
			if card:isKindOf("EquipCard") then
				TH_obtainCard(source, card)
				z = z + 1
			end
		end
		if z == 0 then
			source:drawCards(1)
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------fujiwaranomokou
TH_fengyitianxiang = sgs.CreateViewAsSkill{----凤翼天翔
	name= "TH_fengyitianxiang",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected<1 and to_select:isKindOf("FireSlash")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
		local Hcard = TH_fengyitianxiangCARD:clone()
		Hcard:addSubcard(cards[1]:getId())
		return Hcard
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end
}

TH_fengyitianxiangCARD = sgs.CreateSkillCard{----凤翼天翔
	name = "TH_fengyitianxiangCARD",
	skill_name = "TH_fengyitianxiang",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		--local card = sgs.Sanguosha:getCard(self:getSubcards():at(0))
		local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("TH_fengyitianxiang")
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if p:getAvatarGeneral() then
				room:useCard(sgs.CardUseStruct(slash, source, p), false)
			end
		end
	end
}

TH_Phoenixrevive=sgs.CreateTriggerSkill{----不死鸟重生
	name = "TH_Phoenixrevive",
	events = {sgs.Dying,sgs.EventPhaseStart},
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Dying then
			local dying = data:toDying()
			if dying.who:objectName() ~= player:objectName() then return false end
			if not dying.who:hasSkill(self:objectName()) then return false end
			if player:getMark("Phoenixrevive")>0 then return false end
			if not room:askForSkillInvoke(player,self:objectName()) then return false end
			player:setMark("Phoenixreviveon",1)
			player:setMark("Phoenixrevive", 4)
			player:setMark("Phoenixrevivemaxhp", player:getMaxHp())
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(3))
			-- room:setPlayerProperty(player, "hp", sgs.QVariant(3))
			local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = 3 - player:getHp()
			room:recover(player, recover)
			local log3 = sgs.LogMessage()
			log3.type = "#Phoenixrevive2"
			log3.from = player
			log3.arg = "TH_Phoenixrevive"
			room:sendLog(log3)
			room:setPlayerMark(player, "&TH_Phoenixrevive", 1)
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			if  player:getMark("Phoenixrevive")>0 then
				player:removeMark("Phoenixrevive")
				if player:getMark("Phoenixrevive") < 1 and player:getMark("Phoenixreviveon") > 0 then
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMark("Phoenixrevivemaxhp")+1))
					player:removeMark("Phoenixreviveon")
					local log6= sgs.LogMessage()
					log6.type = "#Phoenixrevive1"
					log6.from = player
					log6.arg = player:getMaxHp()
					room:sendLog(log6)
					room:setPlayerMark(player, "&TH_Phoenixrevive", 0)
				end
			end
		end
	end
}

TH_bumie =sgs.CreateTriggerSkill{----不灭
	name = "TH_bumie",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then --Play
			local i = 0
			for _, id in sgs.qlist(room:getDiscardPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("FireSlash") then
					i = i + 1
				end
			end
			if i >= 4 then
				if not room:askForSkillInvoke(player,self:objectName()) then return false end
				-- player:throwAllHandCardsAndEquips()
				player:throwAllCards()
				if player:getHp() > 1 then room:loseHp(player, player:getHp() - 1) end
				for _, acard in sgs.qlist(room:getDiscardPile()) do
					local bcard = sgs.Sanguosha:getCard(acard)
					if bcard:isKindOf("FireSlash") then
						room:obtainCard(player, bcard)
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() then return false end
			if move.card_ids:isEmpty() then return false end
			if move.to_place == sgs.Player_DiscardPile then
				local ids = sgs.IntList()
				for _, cardid in sgs.qlist(move.card_ids) do
					if cardid == -1 then continue end
					for _, Hcard in sgs.qlist(player:getHandcards()) do
						if cardid == Hcard:getId() then break end
					end
					local card = sgs.Sanguosha:getCard(cardid)
					if card:isKindOf("FireSlash") then
						ids:append(cardid)
					end
				end
				if ids:length() > 0 then
					local newmove = sgs.CardsMoveStruct()
					newmove.to = player
					newmove.card_ids = ids
					newmove.to_place = sgs.Player_PlaceHand
					room:moveCardsAtomic(newmove, true)
				end
			end
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------shikieiki
TH_Guilty = sgs.CreateTriggerSkill{-----罪
	name = "TH_Guilty",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.DamageForseen, sgs.Death},
	can_trigger = function()
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local shikis = room:findPlayersBySkillName(self:objectName())
		if shikis:isEmpty() then return end
		local da = data:toDamage()
		if not da.from then return false end
		if event == sgs.Damaged then
			if da.from:hasSkill(self:objectName()) then return end
			da.from:gainMark("@TH_guilty")
		elseif event == sgs.DamageForseen then
			if da.from and da.from:getMark("@TH_guilty") > 0 and da.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				if da.from:isKongcheng() then
					return true
				else
					TH_obtainCard(player, da.from:getRandomHandCard())
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p, "@TH_guilty", 0)
				end
			end
		end
	end
}

--------------
TH_LastJudgementCARD = sgs.CreateSkillCard{
	name = "TH_LastJudgementCARD",
	skill_name = "TH_LastJudgement",
	target_fixed = true,
}

TH_LastJudgementVS = sgs.CreateViewAsSkill{
	name = "TH_LastJudgement",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = TH_LastJudgementCARD:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@TH_LastJudgement"
	end
}

TH_LastJudgement = sgs.CreateTriggerSkill{---最终审判
	name = "TH_LastJudgement",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = TH_LastJudgementVS,
	events = {sgs.AskForRetrial},
	priority = -2,
	can_trigger = function(self, player)
		return player:hasSkills("guicai|guidao|jilve|huanshi|TH_LastJudgement")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local shikis = room:findPlayersBySkillName(self:objectName())
		if shikis:isEmpty() then return false end
		local judge = data:toJudge()
		for _,shiki in sgs.qlist(shikis) do
			if shiki:getCardCount(true) < 1 then return false end
			local pattern = "@TH_LastJudgement"
			local prompt = string.format("#TH_LastJudgement:%s:%s:%s",player:objectName(),judge.who:objectName(),judge.reason)
			local card = room:askForCard(shiki, pattern, prompt, data, sgs.Card_MethodResponse, judge.who, true)
			if card then
				room:retrial(card, shiki, judge, self:objectName())
				shiki:drawCards(1)
			end
		end
	end
}

----------------------------------
TH_shiwangshenpanVS=sgs.CreateViewAsSkill{----十王审判
	name = "TH_shiwangshenpan",
	n = 0,
	view_as = function(self, cards)
		local scard = TH_shiwangshenpanCARD:clone()
		return scard
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("TH_shiwangshenpan_used")
	end
}

TH_shiwangshenpanCARD = sgs.CreateSkillCard{----十王审判
	name = "TH_shiwangshenpanCARD",
	skill_name = "TH_shiwangshenpan",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local zui = room:askForChoice(source,self:objectName(),"TH_cancel+TH_swsp_one+TH_swsp_all")
		if zui == "TH_cancel" then
			return
		elseif zui == "TH_swsp_one" then
			local zuiplayer = sgs.SPlayerList()
			local maxzui = 0
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
					maxzui = math.max(maxzui, p:getMark("@TH_guilty"))
			end
			if maxzui == 0 then return false end
			for _,mp in sgs.qlist(room:getOtherPlayers(source)) do
				if mp:getMark("@TH_guilty") == maxzui and mp:getHandcardNum() > 0 then
					zuiplayer:append(mp)
				end
			end
			if zuiplayer:isEmpty() then return false end
			local sb=room:askForPlayerChosen(source,zuiplayer,self:objectName())
			sb:loseAllMarks("@TH_guilty")
			for i = 1, math.min(sb:getHandcardNum(),2) do
				TH_obtainCard(source, sb:getRandomHandCard())
				if sb:isKongcheng() then break end
			end
			room:setPlayerFlag(source, "TH_shiwangshenpan_used")
		elseif zui == "TH_swsp_all" then
			local can
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if p:getMark("@TH_guilty") > 0 and not p:isKongcheng() then
					TH_obtainCard(source, p:getRandomHandCard())
					p:loseAllMarks("@TH_guilty")
					can = true
				end
			end
			if can then room:setPlayerFlag(source, "TH_shiwangshenpan_used") end
		end
	end
}

TH_shiwangshenpan = sgs.CreateTriggerSkill{
	name = "TH_shiwangshenpan",
	view_as_skill = TH_shiwangshenpanVS,
	frequency = sgs.Skill_Wake,
	events = {sgs.NonTrigger},
	on_trigger = function(self, event, player, data)
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------shameimaruaya
TH_wenwenxinwenCARD = sgs.CreateSkillCard{---文文新闻
	name = "TH_wenwenxinwenCARD",
	skill_name = "TH_wenwenxinwen",
	will_throw = false,
	target_fixed = false,
	handling_method = sgs.Card_MethodPindian,
	filter = function(self, targets, to_select)
		return #targets < 1 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName() and to_select:getMark("@TH_wenwenxinwen") < 1
	end,
	on_use = function(self, room, source, targets)
		if source:pindian(targets[1], "TH_wenwenxinwen", self) then
			targets[1]:gainMark("@TH_wenwenxinwen")
			targets[1]:addMark("TH_wenwenxinwen"..source:objectName())
			room:setPlayerMark(targets[1], "&TH_wenwenxinwen+to+#"..source:objectName(),1)
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			card:setSkillName("TH_wenwenxinwen")
			card:deleteLater()
			if sgs.Sanguosha:isProhibited(source, targets[1], card) then return end
			room:useCard(sgs.CardUseStruct(card, source, targets[1]), false)
		else
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.damage = 1
			damage.to = source
			room:damage(damage)
		end
	end
}

TH_wenwenxinwenVS = sgs.CreateViewAsSkill{------文文新闻
	name = "TH_wenwenxinwen",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local wcard = TH_wenwenxinwenCARD:clone()
		wcard:addSubcard(cards[1])
		return wcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_wenwenxinwenCARD")
	end,
}

TH_wenwenxinwen = sgs.CreateTriggerSkill{---文文新闻
	name = "TH_wenwenxinwen",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = TH_wenwenxinwenVS,
	events = {sgs.EventPhaseStart,sgs.Damaged},
	can_trigger = function()
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			local ayas = room:findPlayersBySkillName(self:objectName())
			if ayas:isEmpty() then return false end
			for _, aya in sgs.qlist(ayas) do
				if aya:getPhase() == sgs.Player_RoundStart then
					for _,sb in sgs.qlist(room:getOtherPlayers(aya)) do
						if sb:getMark("TH_wenwenxinwen"..aya:objectName()) > 0 and sb:getMark("@TH_wenwenxinwen") > 0 then
							room:setPlayerMark(sb,"TH_wenwenxinwen"..aya:objectName(), 0)
							room:setPlayerMark(sb, "&TH_wenwenxinwen+to+#"..aya:objectName(),0)
							sb:loseMark("@TH_wenwenxinwen")
						end
					end
				end
			end
		elseif event == sgs.Damaged then
			local da = data:toDamage()
			if da.to:getMark("@TH_wenwenxinwen") > 0 then
			if da.to:isKongcheng() then return false end
			room:askForDiscard(da.to, self:objectName(), 1, 1, false, false)
			end
		end
	end
}

----------------------------
TH_IllusionaryDominance = sgs.CreateTriggerSkill{---幻想风靡
	name = "TH_IllusionaryDominance",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged, sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		if event == sgs.Damaged then
			player:setMark("TH_IllusionaryDominance_mark", 1)
			TH_logmessage("#TH_IllusionaryDominance_mark", player, self:objectName())
		elseif event == sgs.Damage then
			local da1 = data:toDamage()
			if not da1.to or da1.to:isDead() or da1.to:objectName() == player:objectName() then return false end
			local da2 = sgs.DamageStruct()
			da2.from = player
			da2.to=da1.to
			da2.damage = 1
			if player:getMark("TH_IllusionaryDominance_mark") > 0 then
				if da1.to:isDead() or da1.to ==nil then return false end
				if not room:askForSkillInvoke(player,self:objectName(), data) then return false end
				TH_logmessage("#TH_IllusionaryDominance_success",player,self:objectName())
				player:removeMark("TH_IllusionaryDominance_mark")
				room:damage(da2)
			elseif player:getMark("TH_IllusionaryDominance_mark") < 1 then
				if player:getHp() >= 5 and math.random(1,5) == 1 then
					if not room:askForSkillInvoke(player,self:objectName(), data) then return false end
					TH_logmessage("#TH_IllusionaryDominance_success",player,self:objectName())
					room:damage(da2)
				elseif player:getHp() == 4 then
					local x = math.random(1,10)
					if x == 1 or x == 2 or x == 3 then
						if not room:askForSkillInvoke(player,self:objectName(), data) then return false end
						TH_logmessage("#TH_IllusionaryDominance_success",player,self:objectName())
						room:damage(da2)
					end
				elseif  player:getHp()==3 then
					local x =math.random(1,5)
					if x==1 or x==2 then
						if not room:askForSkillInvoke(player,self:objectName(), data) then return false end
						TH_logmessage("#TH_IllusionaryDominance_success",player,self:objectName())
						room:damage(da2)
					end
				elseif  player:getHp()==2 then
					local x=math.random(1,2)
					if x==1 then
						if not room:askForSkillInvoke(player,self:objectName(), data) then return false end
						TH_logmessage("#TH_IllusionaryDominance_success",player,self:objectName())
						room:damage(da2)
					end
				elseif  player:getHp()==1 then
					local x = math.random(1,5)
					if x ==1 or x== 2 or x== 3 then
						if not room:askForSkillInvoke(player,self:objectName(), data) then return false end
						TH_logmessage("#TH_IllusionaryDominance_success",player,self:objectName())
						room:damage(da2)
					end
				end
			end
		end
	end
}

-------------------------------------------
TH_fengshenshaonv = sgs.CreateTriggerSkill{--风神少女
	name = "TH_fengshenshaonv",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local i=0
			for i=1,player:getCards("j"):length(),1 do
				if player:isKongcheng() then return false end
				if player:getJudgingArea():isEmpty() then return false end
				if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
				room:askForDiscard(player,self:objectName(),1,1,false,false)
				local card = room:askForCardChosen(player, player, "j", self:objectName())
				local name = sgs.Sanguosha:getCard(card):objectName()
				TH_logmessage("#TH_fengshenshaonvmessage",player,name)
				room:obtainCard(player, card)
			 end
		end
	end
}

TH_fengshenshaonvdis = sgs.CreateDistanceSkill{----风神少女distance
	name = "#TH_fengshenshaonvdis",
	correct_func = function(self, from, to)
	if from:hasSkill(self:objectName()) then
		return -1
	elseif to:hasSkill(self:objectName()) then
		return 1
	end
end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------kazamiyuuka

TH_kaihua = sgs.CreateTriggerSkill{---幻想乡开花
	name = "TH_kaihua",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.GameStart},
	priority = -10,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			player:addToPile("TH_flower",sgs.Sanguosha:getCard(room:drawCard()),false)
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:getPile("TH_flower"):length() < 10 then
			player:addToPile("TH_flower",sgs.Sanguosha:getCard(room:drawCard()),false)
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:getPile("TH_flower"):length() < 10 then
			player:addToPile("TH_flower",sgs.Sanguosha:getCard(room:drawCard()),false)
		end
	end
}

TH_huaniaofengyueCARD = sgs.CreateSkillCard{----花鸟风月，啸风弄月
	name = "TH_huaniaofengyueCARD",
	skill_name = "TH_huaniaofengyue",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local x = source:getPile("TH_flower"):length()
		if x > 0 then
			source:clearOnePrivatePile("TH_flower")
			source:drawCards(math.ceil(x / 2))
		end
	end
}

TH_huaniaofengyueVS=sgs.CreateViewAsSkill{----花鸟风月，啸风弄月
	name = "TH_huaniaofengyue",
	n = 0,
	view_as = function(self, cards)
		local scard = TH_huaniaofengyueCARD:clone()
		return scard
	end,
	enabled_at_play = function(self, player)
		return player:getPile("TH_flower"):length() > 0
	end
}

TH_huaniaofengyue = sgs.CreateTriggerSkill{---------花鸟风月，啸风弄月
	name = "TH_huaniaofengyue",
	events = {sgs.CardsMoveOneTime},
	view_as_skill = TH_huaniaofengyueVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local touhouflower = sgs.IntList()
		touhouflower = player:getPile("TH_flower")
		if touhouflower:isEmpty() then return false end
		local move = data:toMoveOneTime()
		if  move.from == nil or move.from:isDead() then return false end
		if move.from:hasSkill(self:objectName()) then return false end
		if  move.reason.m_reason == sgs.CardMoveReason_S_REASON_THROW and move.from:isAlive() then
			local from
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() == move.from:objectName() then from = p break end
			end
			--TH_logmessage("#TH_huaniaofengyue", from, move.card_ids:length())
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "TH_flower", "")
			room:throwCard(sgs.Sanguosha:getCard(touhouflower:first()), reason, nil)
			player:drawCards(move.card_ids:length() + 1)
		end
	end
}

TH_YuukaSamaCARD = sgs.CreateSkillCard{---------S
	name = "TH_YuukaSamaCARD",
	skill_name = "TH_YuukaSama",
	filter = function(self, targets, to_select)
		return #targets < 2 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1 or #targets== 2
	end,
	on_use = function(self, room, source, targets)
		local touhouflower = source:getPile("TH_flower")
		if touhouflower:isEmpty() then return false end
		room:moveCardTo(sgs.Sanguosha:getCard(touhouflower:at(0)), source, sgs.Player_DiscardPile, true)
		for _, t in ipairs(targets) do
			room:setEmotion(t, "chain")
			room:setPlayerProperty(t, "chained", sgs.QVariant(true))
			local log1 = sgs.LogMessage()
			log1.type = "#TH_YuukaSamaCARD"
			log1.from = source
			log1.to:append(t)
			room:sendLog(log1)
		end
	end
}

TH_YuukaSamaVS=sgs.CreateViewAsSkill{---------S
	name = "TH_YuukaSama",
	n = 0,
	view_as = function(self, cards)
		local scard = TH_YuukaSamaCARD:clone()
		return scard
	end,
	enabled_at_play = function(self, player)
		return player:getPile("TH_flower"):length() > 0
	end
}

TH_YuukaSama= sgs.CreateTriggerSkill{-----------S
	name = "TH_YuukaSama",
	events = {sgs.DamageComplete},
	priority = -1,
	view_as_skill = TH_YuukaSamaVS,
	can_trigger = function(self, event, player, data)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		if da.from and da.from:hasSkill(self:objectName()) then
			if da.to:isDead() then return false end
			local log = sgs.LogMessage()
			log.to:append(da.to)
			log.type = "#TH_YuukaSama"
			room:sendLog(log)
			if not room:askForSkillInvoke(da.from,self:objectName(), data) then return false end
			room:setEmotion(da.to, "chain")
			room:setPlayerProperty(da.to, "chained", sgs.QVariant(true))
			local x = da.to:getLostHp()
			da.to:drawCards(x)
			if x > 1 then
				room:askForDiscard(da.to, "TH_YuukaSama", x - 1, x - 1, false, false)
			end
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------kirisamemarisa
TH_bagualu = sgs.CreateTriggerSkill{-----八卦炉
	name= "TH_bagualu",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_RoundStart then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getArmor() and p:getArmor():isKindOf("EightDiagram") then
					local card = p:getArmor()
					--player:obtainCard(p:getArmor())
					if not p:hasSkill("tuntian") then room:moveCardTo(card, p, sgs.Player_PlaceHand, false) end
					player:obtainCard(card)
					local log1 = sgs.LogMessage()
					log1.type = "#TH_thethiefmarisa1"
					log1.from = player
					log1.to:append(p)
					room:sendLog(log1)
				end
			end
		end
	end
}

------------------------------------
TH_MasterSparkCARD = sgs.CreateSkillCard{----极限火花
	name = "TH_MasterSparkCARD",
	skill_name = "TH_MasterSpark",
	on_use = function(self, room, source, targets)
		local t =targets[1]
		local jj = sgs.JudgeStruct()
		jj.who = source
		jj.pattern= "."
		jj.reason = "TH_MasterSpark"
		jj.good = true
		room:judge(jj)
		local cardsuit = jj.card:getSuitString()
		if source:getArmor() and source:getArmor():isKindOf("EightDiagram") then
			room:setPlayerFlag(t,"TH_MasterSpark_target")
			local card = room:askForCard(source, ".|"..cardsuit.."|.|hand|.",  "@TH_MasterSpark", sgs.QVariant(), "TH_MasterSpark")
			if card == nil then return false end
			if room:askForSkillInvoke(source, "TH_MasterSparkEX") then
				room:setPlayerFlag(t, "-TH_MasterSpark_target")
				room:moveCardTo(source:getArmor(), nil, sgs.Player_DiscardPile, true)
				room:loseMaxHp(t)
				if t:isAlive() then
					local da = sgs.DamageStruct()
					da.from = source
					da.card = card
					da.to = t
					room:damage(da)
				end
				local log2= sgs.LogMessage()
				log2.type = "#TH_MasterSpark1"
				room:sendLog(log2)
			else
				room:setPlayerFlag(t, "-TH_MasterSpark_target")
				local da = sgs.DamageStruct()
				da.from = source
				da.card = card
				da.to = t
				room:damage(da)
				local log1 = sgs.LogMessage()
				log1.type = "#TH_MasterSpark1"
				room:sendLog(log1)
			end
		else
			local card = room:askForCard(source, ".|"..cardsuit.."|.|hand|.", "@TH_MasterSpark", sgs.QVariant(), "TH_MasterSpark")
			if card == nil then return false end
			local da = sgs.DamageStruct()
			da.from = source
			da.card = card
			da.to = t
			room:damage(da)
			local log1 = sgs.LogMessage()
			log1.type = "#TH_MasterSpark1"
			room:sendLog(log1)
		end
	end
}

TH_MasterSpark=sgs.CreateViewAsSkill{------极限火花
	name = "TH_MasterSpark",
	n = 0,
	view_as = function(self, cards)
		local scard = TH_MasterSparkCARD:clone()
		return scard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_MasterSparkCARD") and not player:isKongcheng()
	end
}

--------------------------------------------------------
local touhouGeneral = { "FlandreScarlet", "FlandreScarlet_Nos", "RemiliaScarlet", "RemiliaScarlet_Nos", "IzayoiSakuya", "HakureiReimu", "KotiyaSanae",
		"SaigyoujiYuyuko", "KonpakuYoumu", "HouraisanKaguya", "HouraisanKaguya_Nos", "YagokoroEirin", "ReisenUdongeinInaba", "FujiwaranoMokou", "Shikieiki", "ShameimaruAya",
		"KazamiYuuka", "KirisameMarisa", "KagiyamaHina", "YasakaKanako", "YakumoYukari", "Cirno", "KomeijiSatori", "KomeijiKoishi", "HoshigumaYuugi",
		"ReiujiUtsuho", "KaenbyouRin", "PatchouliKnowledge", "HinanawiTenshi", "NagaeIku", "HoujuuNue", "Nazrin", "TataraKogasa", "HijiriByakuren",
		"IbukiSuika", "UsamiRenko", "MaribelHearn", "ToyosatomiminoMiko", "MagakiReimu"
	}
TH_thethiefmarisa_tempskill={}
TH_thethiefmarisa_tempskill.skillname={}
TH_thethiefmarisa_tempskill.owner={}
TH_thethiefmarisaVS = sgs.CreateViewAsSkill{----------大盗魔理沙
	name = "TH_thethiefmarisa",
	n = 0,
	view_as = function(self,cards)
	local card = TH_thethiefmarisaCARD:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_thethiefmarisaCARD")
	end
}

TH_thethiefmarisaCARD= sgs.CreateSkillCard{-----------------------大盗魔理沙
	name = "TH_thethiefmarisaCARD",
	skill_name = "TH_thethiefmarisa",
	target_fixed = true,
	on_use = function (self, room, source, targets)
		local banskilllist = {"TH_sichongcunzai", "TH_huanyue", "TH_xingtai", "TH_TheWorld", "TH_nafeng", "TH_fanhundie", "TH_xixingyao", "TH_penglaiyuzhi", "TH_yongyefan",
				"TH_penglaizhiyao", "TH_Phoenixrevive", "TH_bumie", "TH_Guilty", "TH_shiwangshenpan", "TH_kaihua", "TH_huaniaofengyue", "TH_ExiledDoll", "TH_shishen",
				"TH_SanaeBuff1", "TH_brokencharm", "TH_MoutainOfFaith", "TH_Nuclear", "TH_TerribleSouvenir", "TH_AllM", "TH_AdventCirno", "TH_PerfectMath",
				"TH_SubterraneanSun", "TH_UndefinedAFOLD", "TH_UndefinedAFOLD_flag", "TH_yinhexi", "TH_chaoren", "TH_moshenfusong", "TH_jiu", "TH_jiuTRIG", "TH_suiyue",
				"TH_bianshen_YakumoYukari", "TH_bianshen_MaribelHearn"}
		local hiddenskill = {"TH_feixing", "TH_xixue", "TH_qed", "TH_Laevatein", "TH_huaidiao", "TH_LunaClock", "TH_UnilateralContract", "TH_qimendunjia",
							"TH_CosmicMarionnette", "TH_GalacticIllusion", "TH_GreatestCaution"}
		local unknowskill = { "TH_death" }
		if #TH_thethiefmarisa_tempskill.owner > 0 then
			local x = 0
			for i=1, #TH_thethiefmarisa_tempskill.owner do
				if TH_thethiefmarisa_tempskill.owner[i-x] == source:objectName() then
					room:handleAcquireDetachSkills(source, "-" .. TH_thethiefmarisa_tempskill.skillname[i-x])
					table.remove(TH_thethiefmarisa_tempskill.skillname,i-x)
					table.remove(TH_thethiefmarisa_tempskill.owner,i-x)
					x=x+1
				end
			end
		end
		local th_general = touhouGeneral
		local toRemove = {}
		for _, p in sgs.qlist(room:getAllPlayers()) do
			table.insert(toRemove, p:getGeneralName())
			if p:getGeneral2() then table.insert(toRemove, p:getGeneral2Name()) end
		end
		table.removeTable(th_general, toRemove)
		TH_shuffle(th_general)
		local touhouGeneralchoice = { th_general[1], th_general[2], th_general[3] }
		local TH_skill = {}
		for _, generalname in ipairs(touhouGeneralchoice) do
			local general=sgs.Sanguosha:getGeneral(generalname)
			for _,touhouskill in sgs.qlist(general:getVisibleSkillList()) do
				local skname = touhouskill:objectName()
				if not source:hasSkill(skname) then
					table.insert(TH_skill, skname)
				end
			end
		end
		table.removeTable(TH_skill, banskilllist)
		table.insert(TH_skill, hiddenskill[math.random(1, #hiddenskill)])
		if math.random(1, 100) == 1 then table.insert(TH_skill, unknowskill[1]) end
		if #TH_skill > 0 then
			local askill = room:askForChoice(source,"TH_thethiefmarisa", table.concat(TH_skill,"+"))
			room:acquireSkill(source, askill)
			table.insert(TH_thethiefmarisa_tempskill.skillname, askill)
			table.insert(TH_thethiefmarisa_tempskill.owner, source:objectName())
		end
		local log1 = sgs.LogMessage()
		log1.type = "#TH_thethiefmarisa"
		log1.from = source
		room:sendLog(log1)
	end
}

TH_thethiefmarisa =sgs.CreateTriggerSkill{
	name= "TH_thethiefmarisa",
	view_as_skill = TH_thethiefmarisaVS,
	events = {sgs.NonTrigger},
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------kagiyamahina
TH_BadFortuneVS=sgs.CreateViewAsSkill{ ------噩运
	name = "TH_BadFortune",
	view_as = function(self, cards)
		local scard = TH_BadFortuneCARD:clone()
		return scard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_BadFortuneCARD")
	end
}

TH_BadFortuneCARD =  sgs.CreateSkillCard{ -----噩运
	name = "TH_BadFortuneCARD",
	skill_name = "TH_BadFortune",
	on_use = function(self, room, source, targets)
		targets[1]:gainMark("@TH_badfortune")
	end
}

TH_BadFortune = sgs.CreateTriggerSkill{  -----噩运
	name = "TH_BadFortune",
	events = {sgs.DrawNCards},
	frequency = sgs.Skill_NotFrequent,
	view_as_skill =TH_BadFortuneVS,
	priority = -2,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		local target
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("@TH_badfortune") > 0 and p:getPhase() == sgs.Player_Draw then
				target = p
				break
			end
		end
		if not target then return false end
		local y = data:toInt()
		local x = math.random(0, y)
		draw.num = draw.num - x
		data:setValue(draw)
		target:loseMark("@TH_badfortune")
		if  x == 0 then return false end
		local log= sgs.LogMessage()
		log.type = "#TH_BadFortune_draw"
		log.to:append(target)
		log.arg = x
		log.arg2 = self:objectName()
		room:sendLog(log)
	end
}

----------------------------------------
TH_brokencharm = sgs.CreateTriggerSkill{------疵痕-损坏的护身符
	name = "TH_brokencharm",
	events = {sgs.CardFinished, sgs.DamageForseen, sgs.EventPhaseEnd, sgs.Death},
	frequency = sgs.Skill_Compulsory,
	priority = -1,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local hinas = room:findPlayersBySkillName(self:objectName())
		if hinas:isEmpty() then return false end
		if event == sgs.CardFinished or (event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish) then
			for _,hina in sgs.qlist(hinas) do
				if hina:getHandcardNum() == 1 and hina:getMark("TH_brokencharm_used") < 1 then
					hina:throwAllHandCards()
					if hina:isKongcheng() then
						local targets = sgs.SPlayerList()
						for _,p in sgs.qlist(room:getOtherPlayers(hina)) do
							if hina:inMyAttackRange(p) then
								targets:append(p)
							end
						end
						if targets:isEmpty() then return end
						local target = room:askForPlayerChosen(hina, targets, self:objectName())
						if target == nil then return false end
						local log = sgs.LogMessage()
						log.type = "#TH_brokencharm"
						log.to:append(target)
						log.arg = self:objectName()
						room:sendLog(log)
						target:gainMark("@TH_brokencharm")
						room:setPlayerMark(target, "TH_brokencharm" .. hina:objectName(), 1)
						room:setPlayerMark(hina, "TH_brokencharm_used", 1)
					end
				end
			end
		elseif event == sgs.DamageForseen then
			local da1 = data:toDamage()
			if not da1.to:hasSkill(self:objectName()) then return false end
			local sb
			for _, p in sgs.qlist(room:getOtherPlayers(da1.to)) do
				if p:getMark("@TH_brokencharm") > 0 and p:getMark("TH_brokencharm" .. da1.to:objectName()) > 0 then
					sb = p
					break
				end
			end
			if sb then
				local da2 = sgs.DamageStruct()
				da2.from = da1.from
				da2.to = sb
				da2.card = da1.card
				da2.reason = "TH_brokencharm"
				room:damage(da2)
				sb:loseMark("@TH_brokencharm")
				room:setPlayerMark(sb, "TH_brokencharm" .. da1.to:objectName(), 0)
				room:setPlayerMark(da1.to, "TH_brokencharm_used", 0)
				return true
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:hasSkill(self:objectName()) then
				for _, p in sgs.qlist(room:getOtherPlayers(death.who)) do
					if p:getMark("@TH_brokencharm") > 0 and p:getMark("TH_brokencharm" .. death.who:objectName()) > 0 then
						p:loseMark("@TH_brokencharm")
						break
					end
				end
			end
			for _, hina in sgs.qlist(hinas) do
				local sb
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("@TH_brokencharm") > 0 and p:getMark("TH_brokencharm" .. hina:objectName()) > 0 then
						sb = p
						break
					end
				end
				if not sb then
					room:setPlayerMark(hina, "TH_brokencharm_used", 0)
				end
			end
		end
	end
}

-------------------------------------------
TH_ExiledDollCARD = sgs.CreateSkillCard{--创符-流刑人偶
	name = "TH_ExiledDollCARD",
	skill_name = "TH_ExiledDoll",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getHp() == 1
	end,
	on_use = function(self, room, source, targets)
		targets[1]:gainMark("@TH_exileddoll", 3)
		room:setPlayerMark(source, "TH_ExiledDoll_used", 1)
	end
}

TH_ExiledDollVS=sgs.CreateViewAsSkill{--创符-流刑人偶
	name = "TH_ExiledDoll",
	n=-2,
	view_as = function(self, cards)
		local scard = TH_ExiledDollCARD:clone()
		return scard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("TH_ExiledDoll_used") < 1
	end
}

TH_ExiledDoll = sgs.CreateTriggerSkill{------创符-流刑人偶
	name = "TH_ExiledDoll",
	events = {sgs.DamageForseen},
	frequency = sgs.Skill_Limited,
	view_as_skill = TH_ExiledDollVS,
	priority = -2,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger=function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageForseen then
			local da = data:toDamage()
			local hinas = room:findPlayersBySkillName(self:objectName())
			if hinas:isEmpty() then return false end
			for _,hina in sgs.qlist(hinas) do
				if da.to:getHp() == 1 and hina:getMark("TH_ExiledDoll_used") < 1 then
					room:setPlayerFlag(da.to, "TH_ExiledDoll_target" .. hina:objectName())
					local invoke = room:askForSkillInvoke(hina, self:objectName(), data)
					room:setPlayerFlag(da.to, "-TH_ExiledDoll_target" .. hina:objectName())
					if invoke then
						da.to:gainMark("@TH_exileddoll", 3)
						room:setPlayerMark(hina, "TH_ExiledDoll_used", 1)
						break
					end
				end
			end
			if da.to:getMark("@TH_exileddoll") > 0 then
				da.to:loseMark("@TH_exileddoll")
				return true
			end
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------YasakaKanako
TH_MiracleofOtensui = sgs.CreateViewAsSkill{------天流-天水奇迹
	name = "TH_MiracleofOtensui",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() and #selected<1
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local wcard = TH_MiracleofOtensuiCARD:clone()
		wcard:addSubcard(cards[1])
		return wcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_MiracleofOtensuiCARD")
	end,
}

TH_MiracleofOtensuiCARD = sgs.CreateSkillCard{--天流-天水奇迹
	name = "TH_MiracleofOtensuiCARD",
	skill_name = "TH_MiracleofOtensui",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local t = targets[1]
		local re = sgs.RecoverStruct()
		if t:isChained() then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:isChained() then
					re.who = p
					room:recover(p,re,true)
					if source:getMark("TH_SanaeBuff1_on") >0 then
						if not room:askForSkillInvoke(source,"#TH_MiracleofOtensui_unlock") then return false end
						room:setPlayerProperty(p, "chained", sgs.QVariant(false))
						room:setEmotion(p,"chain")
						local log= sgs.LogMessage()
						log.type = "#TH_MiracleofOtensui"
						log.to:append(p)
						room:sendLog(log)
					end
				end
			end
		else
			re.who = t
			room:recover(t, re, true)
		end
	end
}

--------------------------------------------------------------------

TH_UnrememberedCropCARD = sgs.CreateSkillCard{----------遗忘之谷
	name = "TH_UnrememberedCropCARD",
	skill_name = "TH_UnrememberedCrop",
	filter = function(self,targets,to_select,player)
		if to_select:objectName() == player:objectName() then return false end
		if to_select:hasSkill("TH_UnrememberedCrop") then return false end
		if sgs.Self:getMark("TH_SanaeBuff1_on") < 1 then
			return #targets < 1 and to_select:getHp() > 3 - self:subcardsLength()
		elseif sgs.Self:getMark("TH_SanaeBuff1_on") == 1 then
			return to_select:getHp() > 2 - self:subcardsLength() and #targets < 1
		end
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(targets[1], "TH_UnrememberedCrop_mark" .. source:objectName(), 1)
	end
}

TH_UnrememberedCropVS=sgs.CreateViewAsSkill{--遗忘之谷
	name = "TH_UnrememberedCrop",
	n=5,
	view_filter = function(self, selected, to_select)
		if sgs.Self:getMark("TH_SanaeBuff1_on") < 1 then
			return #selected < 3
		elseif sgs.Self:getMark("TH_SanaeBuff1_on") == 1 then
			return #selected < 2
		end
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local scard=TH_UnrememberedCropCARD:clone()
			for _,card in ipairs(cards) do
				scard:addSubcard(card)
			end
			scard:setSkillName(self:objectName())
			return scard
		end
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@TH_UnrememberedCrop"
	end
}

TH_UnrememberedCrop_removeskill = {}
TH_UnrememberedCrop_removeskill.temp = {}
TH_UnrememberedCrop_removeskill.owner = {}
TH_UnrememberedCrop = sgs.CreateTriggerSkill{-----遗忘之谷
	name = "TH_UnrememberedCrop",
	events = {sgs.EventPhaseEnd, sgs.EventPhaseStart, sgs.Death},
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = TH_UnrememberedCropVS,
	priority = 7,
	can_trigger = function(self, player)
		return player
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			local kanakos = room:findPlayersBySkillName(self:objectName())
			if kanakos:isEmpty() then return false end
			for _,kanako in sgs.qlist(kanakos) do
				if not kanako:isKongcheng() then
					if room:askForUseCard(kanako, "@@TH_UnrememberedCrop", "TH_UnrememberedCrop") then
						local sb
						for _,p in sgs.qlist(room:getAlivePlayers()) do
							if p:getMark("TH_UnrememberedCrop_mark" .. kanako:objectName()) > 0 then
								sb = p
								break
							end
						end
						if not sb then return end
						for _,skname in sgs.qlist(sb:getVisibleSkillList()) do
							local skillname = skname:objectName()
							room:detachSkillFromPlayer(sb, skillname)
							table.insert(TH_UnrememberedCrop_removeskill.temp, skillname)
							table.insert(TH_UnrememberedCrop_removeskill.owner, sb:objectName())
						end
					end
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if #TH_UnrememberedCrop_removeskill.owner > 0 then
				if death.who:hasSkill(self:objectName()) then
					for _, pp in sgs.qlist(room:getOtherPlayers(death.who)) do
						if pp:getMark("TH_UnrememberedCrop_mark" .. death.who:objectName()) > 0 then
							local x = 0
							for i = 1, #TH_UnrememberedCrop_removeskill.owner do
								if TH_UnrememberedCrop_removeskill.owner[i-x] == pp:objectName() then
									if TH_UnrememberedCrop_removeskill.temp[i-x] ~= "TH_lordskill" or pp:isLord() then
										room:acquireSkill(pp, TH_UnrememberedCrop_removeskill.temp[i - x])
									end
									table.remove(TH_UnrememberedCrop_removeskill.temp, i - x)
									table.remove(TH_UnrememberedCrop_removeskill.owner, i - x)
									x = x + 1
								end
							end
						end
					end
				else
					local x = 0
					for i = 1, #TH_UnrememberedCrop_removeskill.owner do
						if death.who:objectName() == TH_UnrememberedCrop_removeskill.owner[i-x] then
							table.remove(TH_UnrememberedCrop_removeskill.temp, i-x)
							table.remove(TH_UnrememberedCrop_removeskill.owner, i-x)
							x = x + 1
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd
			and (player:getPhase() == sgs.Player_Play or player:getPhase() == sgs.Player_Discard or player:getPhase() == sgs.Player_Finish) then
			if #TH_UnrememberedCrop_removeskill.owner == 0 or #TH_UnrememberedCrop_removeskill.temp == 0 then return end
			local kanakos = room:findPlayersBySkillName(self:objectName())
			if kanakos:isEmpty() then return false end
			for _, kanako in sgs.qlist(kanakos) do
				for _, sb in sgs.qlist(room:getAlivePlayers()) do
					if sb:getMark("TH_UnrememberedCrop_mark" .. kanako:objectName()) > 0 then
						room:setPlayerMark(sb,"TH_UnrememberedCrop_mark" .. kanako:objectName(), 0)
						local x = 0
						for i = 1, #TH_UnrememberedCrop_removeskill.owner do
							if TH_UnrememberedCrop_removeskill.owner[i-x] == sb:objectName() then
								if TH_UnrememberedCrop_removeskill.temp[i-x] ~= "TH_lordskill" or sb:isLord() then
									room:acquireSkill(sb,TH_UnrememberedCrop_removeskill.temp[i - x])
								end
								table.remove(TH_UnrememberedCrop_removeskill.temp, i - x)
								table.remove(TH_UnrememberedCrop_removeskill.owner, i - x)
								x = x + 1
							end
						end
					end
				end
			end
		end
	end
}

------------------------------------------------
TH_MoutainOfFaithCARD = sgs.CreateSkillCard{----信仰之山
	name = "TH_MoutainOfFaithCARD",
	skill_name = "TH_MoutainOfFaith",
	filter = function(self,targets,to_select,player)
		return #targets<1
	end,
	on_use = function(self, room, source, targets)
		local t = targets[1]
		if  source:getMark("TH_SanaeBuff1_on") < 1 and  source:getMark("@TH_faith") >=5 then
			source:loseMark("@TH_faith",5)
			t:drawCards(2)
		elseif source:getMark("TH_SanaeBuff1_on") == 1 and  source:getMark("@TH_faith") >=3 then
			source:loseMark("@TH_faith",3)
			t:drawCards(2)
		end
	end
}

TH_MoutainOfFaithVS=sgs.CreateViewAsSkill{-----信仰之山
	name = "TH_MoutainOfFaith",
	n = 0,
	view_as = function(self, cards)
		local mcard=TH_MoutainOfFaithCARD:clone()
		return mcard
	end,
	enabled_at_play = function(self, player)
		if player:getMark("TH_SanaeBuff1_on") > 0 then
			return  player:getMark("@TH_faith")>=3
		elseif player:getMark("TH_SanaeBuff1_on") <1 then
			return  player:getMark("@TH_faith")>=5
		end
	end,
}

TH_MoutainOfFaith = sgs.CreateTriggerSkill{---信仰之山
	name = "TH_MoutainOfFaith",
	events = {sgs.CardFinished},
	priority = -1,
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = TH_MoutainOfFaithVS,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("TrickCard") and use.card:isNDTrick()then
			local kanakos = room:findPlayersBySkillName(self:objectName())
			if kanakos:isEmpty() then return false end
			for _,kanako in sgs.qlist(kanakos) do
				kanako:gainMark("@TH_faith")
			end
		end
	end
}

TH_SanaeBuff1= sgs.CreateTriggerSkill{--------早苗的BUFF
	name = "TH_SanaeBuff1",
	events = {sgs.GameStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger= function(self, event, player, data)
		local room = player:getRoom()
		local sanaename = "KotiyaSanae"
		local Kanakorole = player:getRole()
		for _, p in sgs.qlist(room:getPlayers()) do
			if p:getGeneralName()==sanaename or p:getGeneral2Name()==sanaename then
				local Sanaerole = p:getRole()
				local Kanakorole = player:getRole()
				if (Sanaerole == "loyalist" or Sanaerole == "lord" or Sanaerole=="renegade") and (Kanakorole == "loyalist" or Kanakorole == "lord" or Kanakorole =="renegade") then
					player:setMark("TH_SanaeBuff1_on",1)
				elseif  Sanaerole == "rebel" and Kanakorole == "rebel" then
					player:setMark("TH_SanaeBuff1_on",1)
				end
			end
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------yakumoyukari
TH_bianshen_MaribelHearn = sgs.CreateTriggerSkill{
	name = "#TH_bianshen_MaribelHearn",
	events = {sgs.GameStart},
	priority = 9,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not player:hasFlag("TH_bianshen_YakumoYukari_used") and not player:hasFlag("TH_bianshen_MaribelHearn_used") and player:getGeneralName()== "YakumoYukari" then
			if not room:askForSkillInvoke(player, self:objectName()) then return end
			room:setPlayerFlag(player, "TH_bianshen_MaribelHearn_used")
			local maxhp = player:getMaxHp()
			room:changeHero(player, "MaribelHearn",true, true, false, true)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
			room:setPlayerProperty(player, "hp", sgs.QVariant(player:getMaxHp()))
		end
	end
}

TH_shengyusiCARD = sgs.CreateSkillCard{----生与死的境界
	name = "TH_shengyusiCARD",
	skill_name = "TH_shengyusi",
	filter = function(self, targets, to_select)
		if sgs.Self:getMark("TH_shengyusi_max") == 1 then
			return #targets == 0 and to_select:getSeat() ~= 1 and to_select:objectName() ~= sgs.Self:objectName()
		else
			return #targets == 0 and to_select:getSeat() ~= sgs.Self:getSeat() + 1 and to_select:objectName() ~= sgs.Self:objectName()
		end
	end,
	on_use = function(self, room, source, targets)
		local t = targets[1]
		local np = source:getNext()
		local log= sgs.LogMessage()
		log.type = "#TH_shengyusi"
		log.to:append(t)
		log.arg = np:getGeneralName()
		room:sendLog(log)
		room:swapSeat(t, np)
		local da = sgs.DamageStruct()
		da.from = source
		da.nature = sgs.DamageStruct_Thunder
		da.to = t
		room:damage(da)
		if t == nil or t:isDead() then return false end
		t:drawCards(t:getLostHp())
		local log =  sgs.LogMessage()
		log.type = "#TurnOver"
		log.from = t
		log.arg = "face_down"
		room:sendLog(log)
		room:setPlayerProperty(t, "faceup", sgs.QVariant(false))
	end
}

TH_shengyusiVS = sgs.CreateViewAsSkill{-----生与死的境界
	name = "TH_shengyusi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1 and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local Hcard = TH_shengyusiCARD:clone()
			Hcard:setSkillName(self:objectName())
			Hcard:addSubcard(card:getId())
			return Hcard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_shengyusiCARD")
	end
}

TH_shengyusi = sgs.CreateTriggerSkill{--------生与死的境界
	name = "TH_shengyusi",
	events = {sgs.TurnStart},
	view_as_skill = TH_shengyusiVS,
	on_trigger = function(self, event, player, data)
		if player:getSeat() == player:getRoom():getAlivePlayers():length() then player:setMark("TH_shengyusi_max", 1)
		else player:setMark("TH_shengyusi_max", 0)
		end
	end
}
-----------------------------------------
TH_sichongjiejie = sgs.CreateTriggerSkill{--------四重结界
	name = "TH_sichongjiejie",
	events = {sgs.TurnStart},
	priority = 3,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:faceUp() or player:isKongcheng() then return end
		if not room:askForSkillInvoke(player,self:objectName()) then return end
		if room:askForDiscard(player,self:objectName(),1,1,false,false) then
			player:turnOver()
		end
	end
}

--------------------------------
TH_shishenCARD = sgs.CreateSkillCard{------式神
	name = "TH_shishenCARD",
	skill_name = "TH_shishen",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		if source:getMark("TH_shishen_off") > 0 then return end
		if not source:getGeneral2() then
			local choice = room:askForChoice(source,"TH_shishen","YakumoRan+YakumoChen")
			if choice == "YakumoRan" then
				if source:getGeneral2() then
					for _,skill in sgs.qlist(source:getGeneral2():getSkillList()) do
						room:detachSkillFromPlayer(source, skill:objectName())
					end
				end
				room:setPlayerProperty(source, "general2", sgs.QVariant("YakumoRan"))
				for _,skill in sgs.qlist(source:getGeneral2():getSkillList()) do
					room:acquireSkill(source, skill:objectName())
				end
			elseif choice == "YakumoChen" then
				if source:getGeneral2() then
					for _,skill in sgs.qlist(source:getGeneral2():getSkillList()) do
						room:detachSkillFromPlayer(source, skill:objectName())
					end
				end
				room:setPlayerProperty(source, "general2", sgs.QVariant("YakumoChen"))
				for _,skill in sgs.qlist(source:getGeneral2():getSkillList()) do
					room:acquireSkill(source, skill:objectName())
				end
			end
		elseif source:getGeneral2Name() ~= "YakumoRan" and source:getGeneral2Name() ~= "YakumoChen" then
			room:acquireSkill(source, "TH_UnilateralContract")
			room:acquireSkill(source, "TH_qimendunjia")
			room:setPlayerMark(source, "TH_shishen_off", 1)
		else
			if source:getGeneral2Name() == "YakumoRan" then
				for _,skill in sgs.qlist(source:getGeneral2():getSkillList()) do
					room:detachSkillFromPlayer(source, skill:objectName())
				end
				room:setPlayerProperty(source, "general2", sgs.QVariant("YakumoChen"))
				for _,skill in sgs.qlist(source:getGeneral2():getSkillList()) do
					room:acquireSkill(source, skill:objectName())
				end
			elseif source:getGeneral2Name() == "YakumoChen" then
				for _,skill in sgs.qlist(source:getGeneral2():getSkillList()) do
					room:detachSkillFromPlayer(source, skill:objectName())
				end
				room:setPlayerProperty(source, "general2", sgs.QVariant("YakumoRan"))
				for _,skill in sgs.qlist(source:getGeneral2():getSkillList()) do
					room:acquireSkill(source, skill:objectName())
				end
			end
		end
		room:filterCards(source, source:getCards("he"), true)
	end
}


TH_shishenVS = sgs.CreateViewAsSkill{------式神
	name = "TH_shishen",
	n = 0,
	view_as = function(self, cards)
		local scard=TH_shishenCARD:clone()
		return scard
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}
TH_shishen= sgs.CreateTriggerSkill{--------式神
	name = "TH_shishen",
	events = {sgs.NonTrigger},
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_shishenVS,
	on_trigger= function(self, event, player, data)
	end
}

------------------------------
TH_menghuanpaoyingVS=sgs.CreateViewAsSkill{---------梦幻泡影
	name = "TH_menghuanpaoying",
	n = 100,
	view_filter = function(self, selected, to_select)
		return #selected < sgs.Self:getHandcardNum() and not to_select:isEquipped()
end,
	view_as = function(self, cards)
		if #cards==sgs.Self:getHandcardNum() then
			local Mcard=TH_menghuanpaoyingCARD:clone()
			for _,card in ipairs(cards) do
				Mcard:addSubcard(card)
			end
			return Mcard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_menghuanpaoyingCARD") and not player:isKongcheng() and player:isWounded()
	end
}

TH_menghuanpaoyingCARD = sgs.CreateSkillCard{------梦幻泡影
	name = "TH_menghuanpaoyingCARD",
	skill_name = "TH_menghuanpaoying",
	filter = function(self, targets, to_select)
		return #targets<sgs.Self:getHandcardNum() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible=function(self, targets)
		return #targets <= sgs.Self:getHandcardNum() and #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		card:setSkillName("TH_menghuanpaoying")
		for _,target in ipairs(targets) do
			if sgs.Sanguosha:isProhibited(source, target, card) then return false end
			room:useCard(sgs.CardUseStruct(card, source, target), false)
		end
	end
}

TH_menghuanpaoying = sgs.CreateTriggerSkill{----------梦幻泡影
	name = "TH_menghuanpaoying",
	events = {sgs.Damage},
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = TH_menghuanpaoyingVS,
	on_trigger= function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		if da.from and da.card and da.card:getSkillName() == "TH_menghuanpaoying" then
			da.from:drawCards(1)
		end
	end
}

----●●●---------yakumoran and yakumochen
TH_UnilateralContractCARD = sgs.CreateSkillCard{------片面义务契约
	name = "TH_UnilateralContractCARD",
	skill_name = "TH_UnilateralContract",
	on_use = function(self, room, source, targets)
		local t = targets[1]
		local y = math.random(1,3)
		if y==1 then
			local x=0
			for _,card in sgs.qlist(t:getCards("h")) do
					if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
						room:setCardFlag(card, "visible")
						x=x+1
					end
				end
			local log =  sgs.LogMessage()
			log.type = "#TH_UnilateralContract_PA"
			log.to:append(t)
			log.arg = x
			room:sendLog(log)
		elseif y==2 then
			local x=0
			for _,card in sgs.qlist(t:getCards("h")) do
					if card:isKindOf("Slash") then
						room:setCardFlag(card, "visible")
						x=x+1
					end
				end
			local log =  sgs.LogMessage()
			log.type = "#TH_UnilateralContract_S"
			log.arg = x
			log.to:append(t)
			room:sendLog(log)
		elseif y==3 then
			local x=0
			for _,card in sgs.qlist(t:getCards("h")) do
					if card:isKindOf("Jink") then
						room:setCardFlag(card, "visible")
						x=x+1
					end
				end
			local log =  sgs.LogMessage()
			log.type = "#TH_UnilateralContract_J"
			log.arg = x
			log.to:append(t)
			room:sendLog(log)
		end
	end
}

TH_UnilateralContract = sgs.CreateViewAsSkill{---------片面义务契约
	name = "TH_UnilateralContract",
	n = 0,
	view_as = function(self, cards)
		local scard = TH_UnilateralContractCARD:clone()
			return scard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_UnilateralContractCARD")
	end
}

------------------------------------------------------------------------------------------
TH_qimendunjia = sgs.CreateTriggerSkill{--------奇门遁甲
	name = "TH_qimendunjia",
	events = {sgs.CardEffected},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.to == nil then return false end
		if effect.from and effect.from:hasSkill(self:objectName()) then return false end
		if effect.to:objectName() ~= player:objectName() then return false end
		local acard = room:drawCard()
		local card = sgs.Sanguosha:getCard(acard)
		local reason = sgs.CardMoveReason()
		reason.m_reason = sgs.CardMoveReason_S_REASON_TURNOVER
		reason.m_playerId = player:objectName()
		room:moveCardTo(card, nil, sgs.Player_PlaceTable, reason,true)
		room:throwCard(card, nil)
		if (not card:isKindOf("Armor") and (card:getNumber() == 2 or card:getNumber() == 4 or card:getNumber() == 8))
			or (player:isKongcheng() and card:getNumber() % 2 == 0) then
			if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
			effect.to = effect.from
			return true
		elseif card:isKindOf("Armor") then
			if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
			if effect.from and effect.card and not effect.card:isKindOf("Collateral") then
				local use = sgs.CardUseStruct()
				use.from = effect.to
				use.to:append(effect.from)
				use.card = effect.card
				room:useCard(use)
			end
			return true
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------Cirno

TH_PerfectMath = sgs.CreateFilterSkill{
	name = "TH_PerfectMath",
	view_filter = function(self, to_select)
		return to_select:getNumber() > 9
	end,
	view_as = function(self, card)
		local card9 = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		card9:setSkillName(self:objectName())
		-- if not card:isKindOf("DelayedTrick") then card9:setNumber(9) end
		card9:setNumber(9)
		card9:setModified(true)
		return card9
	end,
}

-----------------------------
TH_chao9CARD = sgs.CreateSkillCard{------超⑨武神霸斩
	name = "TH_chao9CARD",
	skill_name = "TH_chao9",
	on_use = function(self, room, source, targets)
		for i = 1, 7 do
			-- room:broadcastInvoke("animate", "lightbox:#TH_chao9"..i..":200")
			room:doLightbox("#TH_chao9"..i, 200)
		end
		-- room:broadcastInvoke("animate", "lightbox:#TH_chao99:1000")
		for i = 1, 3 do
			if not targets[1] or targets[1]:isDead() then return end
			local card = sgs.Sanguosha:getCard(room:drawCard())
			source:obtainCard(card, true)
			if card:getNumber() >= 9 then
				local da = sgs.DamageStruct()
				da.from = source
				da.to= targets[1]
				room:damage(da)
			end
			card:setSkillName("TH_chao9")
			room:throwCard(card, nil)
		end
		if self:subcardsLength() == 2 then
			if targets[1]:isDead() then return false end
			local log =  sgs.LogMessage()
			log.type = "#TH_chao9_one"
			room:sendLog(log)
			local dada = sgs.DamageStruct()
			dada.from = source
			dada.to = targets[1]
			room:damage(dada)
		end
	end
}

TH_chao9VS=sgs.CreateViewAsSkill{-------超⑨武神霸斩
	name = "TH_chao9",
	n=2,
	view_filter = function(self, selected, to_select)
		return #selected < 2 and to_select:getNumber() >= 9
	end,
	view_as = function(self, cards)
		if #cards ==1 then
			local bakacard=TH_chao9CARD:clone()
			bakacard:addSubcard(cards[1]:getId())
			return bakacard
		elseif #cards==2 then
			local bakacard=TH_chao9CARD:clone()
			bakacard:addSubcard(cards[1]:getId())
			bakacard:addSubcard(cards[2]:getId())
			return bakacard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_chao9CARD")
	end
}

TH_chao9=sgs.CreateTriggerSkill{---------超⑨武神霸斩
	name = "TH_chao9",
	frequency = sgs.Skill_Limited,
	view_as_skill = TH_chao9VS,
	events = {sgs.NonTrigger},
	on_trigger = function(self, event, player, data)
	end
}

---------------------------------
TH_allbaka = sgs.CreateTriggerSkill{----------笨蛋
	name = "TH_allbaka",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage,sgs.EventPhaseStart},
	priority = 3,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local da = data:toDamage()
			if da.from and not da.from:hasSkill(self:objectName()) then return end
			if da.to ==nil or da.to:isDead() then return false end
			if player:getKingdom() ~= "TH_kingdom_baka" then
				room:setPlayerProperty(player, "kingdom", sgs.QVariant("TH_kingdom_baka"))
			end
			if da.to:getKingdom() == "TH_kingdom_baka" then
				player:drawCards(da.damage)
				for _, ap in sgs.qlist(room:getOtherPlayers(da.to)) do
					if ap:getNextAlive():objectName() == da.to:objectName() or da.to:getNextAlive():objectName() == ap:objectName()
						and ap:getKingdom() ~= "TH_kingdom_baka" then
						room:setPlayerProperty(ap, "kingdom", sgs.QVariant("TH_kingdom_baka"))
						TH_logmessage("#TH_allbaka", player, nil, ap)
					end
				end
			else
				room:setPlayerProperty(da.to, "kingdom", sgs.QVariant("TH_kingdom_baka"))
				TH_logmessage("#TH_allbaka", player, nil, da.to)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:getMark("TH_allbaka_on") < 1 then
			local allplayerbaka = true
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getKingdom() ~= "TH_kingdom_baka" then
					allplayerbaka = false
				end
			end
			if allplayerbaka then
				local log =  sgs.LogMessage()
				log.type = "#TH_allbaka_on"
				room:sendLog(log)
				room:sendLog(log)
				room:sendLog(log)
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+1))
				room:setPlayerProperty(player, "hp", sgs.QVariant(player:getHp()+1))
				player:drawCards(3)
				player:addMark("TH_allbaka_on")
			end
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------komeijisatori
TH_TerribleSouvenirCARD = sgs.CreateSkillCard{
	name = "TH_TerribleSouvenirCARD",
	skill_name = "TH_TerribleSouvenir",
	filter = function(self, targets, to_select)
		return #targets<1 and to_select:objectName()~=sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		targets[1]:gainMark("@TH_terriblesouvenir")
		room:setPlayerMark(targets[1], "TH_TerribleSouvenir_target" .. source:objectName(), 1)
	end
}

TH_TerribleSouvenirVS = sgs.CreateViewAsSkill{------恐怖的回忆
	name = "TH_TerribleSouvenir",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1 and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return end
		local scard = TH_TerribleSouvenirCARD:clone()
		scard:addSubcard(cards[1])
		return scard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_TerribleSouvenirCARD")
	end,
}

TH_TS_damage={}
TH_TS_damage.owner={}
TH_TS_damage.damageStruct={}
TH_TerribleSouvenir = sgs.CreateTriggerSkill{---恐怖的回忆
	name = "TH_TerribleSouvenir",
	events = {sgs.EventPhaseStart, sgs.Damaged, sgs.Death},
	frequency = sgs.Skill_Limited,
	priority = 1,
	view_as_skill = TH_TerribleSouvenirVS,
	can_trigger = function()
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local satoris = room:findPlayersBySkillName(self:objectName())
			if satoris:isEmpty() then return false end
			local da = data:toDamage()
			if da.to:isDead() or da.to == nil then return false end
			for _,satori in sgs.qlist(satoris) do
				if da.to:getMark("@TH_terriblesouvenir") > 0 and da.to:getMark("TH_TerribleSouvenir_target" .. satori:objectName()) > 0 then
					table.insert(TH_TS_damage.damageStruct, da)
					table.insert(TH_TS_damage.owner, satori:objectName())
					TH_logmessage("#TH_TerribleSouvenir_Record", da.from, da.damage, da.to, da.reason)
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then
			if #TH_TS_damage.damageStruct == 0 or #TH_TS_damage.owner == 0 then return end
			for _,sb in sgs.qlist(room:getAlivePlayers()) do
				if sb:getMark("@TH_terriblesouvenir") > 0 and sb:getMark("TH_TerribleSouvenir_target"..player:objectName()) > 0 then
					sb:loseMark("@TH_terriblesouvenir")
					room:setPlayerMark(sb, "TH_TerribleSouvenir_target" .. player:objectName(), 0)
					local x = 0
					for i = 1, #TH_TS_damage.owner do
						if TH_TS_damage.owner[i - x] == player:objectName() then
							local damage = TH_TS_damage.damageStruct[i - x]
							damage.reason = self:objectName()
							local card = room:askForCard(sb, "Slash,Nullification", ("@TH_TerribleSouvenir:%s::%s"):format(damage.from:objectName(), damage.damage), ToData(damage), self:objectName())
							if card==nil then
								TH_logmessage("#TH_TerribleSouvenir_reappear", player, x+1)
								room:damage(damage)
							elseif card then
								TH_logmessage("#TH_TerribleSouvenir_dis", player, x+1)
							end
							table.remove(TH_TS_damage.owner, i - x)
							table.remove(TH_TS_damage.damageStruct, i - x)
							x = x + 1
						end
					end
					if x > 0 then TH_logmessage("#TH_TerribleSouvenir_remove", player, self:objectName()) end
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if #TH_TS_damage.owner == 0 then return end
			if death.who:hasSkill(self:objectName()) then
				local y = 0
				for i = 1 , #TH_TS_damage.owner do
					if TH_TS_damage.owner[i - y] == death.who:objectName() then
						table.remove(TH_TS_damage.owner, i - y)
						table.remove(TH_TS_damage.damageStruct, i - y)
						y = y + 1
					end
				end
			else
				local y = 0
				for i = 1 , #TH_TS_damage.to do
					if TH_TS_damage.to[i - y] == death.who:objectName() then
						table.remove(TH_TS_damage.owner, i - y)
						table.remove(TH_TS_damage.damageStruct, i - y)
						y = y + 1
					end
				end
				if y > 0 then

					TH_logmessage("#TH_TerribleSouvenir_remove", player, self:objectName())
				end
			end
		end
	end
}

TH_HypnosisCARD = sgs.CreateSkillCard{--------恐怖催眠术
	name = "TH_HypnosisCARD",
	skill_name = "TH_Hypnosis",
	on_use = function(self, room, source, targets)
		local cardsid = sgs.IntList()
		local int = targets[1]:getCards("he"):length()
		for _,acard in sgs.qlist(targets[1]:getCards("he")) do
			cardsid:append(acard:getEffectiveId())
		end
		local move = sgs.CardsMoveStruct()
		move.card_ids = cardsid
		move.to = source
		move.to_place = sgs.Player_PlaceHand
		room:moveCardsAtomic(move, false)
		targets[1]:drawCards(math.ceil(int/2))
	end
}

TH_HypnosisVS = sgs.CreateViewAsSkill{------恐怖催眠术
	name = "TH_Hypnosis",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1 and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return end
		local scard = TH_HypnosisCARD:clone()
		scard:addSubcard(cards[1])
		return scard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_HypnosisCARD")
	end,
}

TH_Hypnosis = sgs.CreateTriggerSkill{
	name = "TH_Hypnosis",
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_HypnosisVS,
	events = {sgs.NonTrigger},
	on_trigger = function(self, event, player, data)
	end
}

TH_3rdeye = sgs.CreateTriggerSkill{--------3rdeye
	name = "TH_3rdeye",
	events = {sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		if target:hasSkill("TH_3rdeye") then return false end
		if target:getGeneralName() == "KomeijiKoishi" or target:getGeneral2Name() == "KomeijiKoishi" then return false end
		if target:getGeneralName() == "KomeijiSatori" or target:getGeneral2Name() == "KomeijiSatori" then return false end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Draw then
			local satoris = room:findPlayersBySkillName(self:objectName())
			if satoris:isEmpty() then return false end
			for _,satori in sgs.qlist(satoris) do
				room:showAllCards(player, satori)
			end
		end
	end
}

TH_ShyRose = sgs.CreateTriggerSkill{-----害羞蔷薇
	name = "TH_ShyRose",
	events = {sgs.TargetConfirmed, sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and (player:getGeneralName() == "KomeijiSatori" or player:getGeneral2Name() == "KomeijiSatori")
			and not player:hasSkill("TH_3rdeye") then
			for _, imodo in sgs.qlist(room:getAlivePlayers()) do
				if imodo:getGeneralName() == "KomeijiKoishi" or imodo:getGeneral2Name() == "KomeijiKoishi" then
					if (imodo:getRole() == "lord" or imodo:getRole() == "loyalist" or imodo:getRole() == "renegade") and
					(player:getRole() =="lord" or player:getRole() =="loyalist" or player:getRole() =="renegade") then
						room:acquireSkill(player,"TH_3rdeye")
					elseif  imodo:getRole()== player:getRole() then
						room:acquireSkill(player,"TH_3rdeye")
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.from or use.from:objectName() == player:objectName() then return end
			if use.card:isBlack() and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) and use.to and use.to:contains(player) then
				local card = sgs.Sanguosha:getCard(room:drawCard())
				TH_obtainCard(player, card)
				if card:isBlack() then
					use.from:setFlags("TH_ShyRose_from")
					local invoke = room:askForSkillInvoke(player, self:objectName(), data)
					use.from:setFlags("-TH_ShyRose_from")
					if not invoke then return end
					room:showCard(player, card:getId())
					if use.from:isKongcheng() then return end
					room:askForDiscard(use.from, self:objectName(), 1, 1, false, false)
				end
			end
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------komeijikoishi
TH_RoseHell= sgs.CreateTriggerSkill{------蔷薇地狱
	name = "TH_RoseHell",
	events = { sgs.Damaged, sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and (player:getGeneralName() == "KomeijiKoishi" or player:getGeneral2Name() == "KomeijiKoishi")
			and not player:hasSkill("TH_DNA") then
			for _, oneesan in sgs.qlist(room:getAlivePlayers()) do
				if oneesan:getGeneralName() == "KomeijiSatori" or oneesan:getGeneral2Name() == "KomeijiSatori" then
					if (oneesan:getRole() == "lord" or oneesan:getRole() =="loyalist" or oneesan:getRole() =="renegade") and
					(player:getRole() =="lord" or player:getRole() =="loyalist" or player:getRole() =="renegade") then
						room:acquireSkill(player, "TH_DNA")
					elseif oneesan:getRole() == player:getRole() then
						room:acquireSkill(player, "TH_DNA")
					end
				end
			end
		elseif event == sgs.Damaged then
			local da = data:toDamage()
			if not da.from or da.from:isKongcheng() then return end
			if not room:askForSkillInvoke(player, self:objectName(), data) then return end
			local x = 0
			for _, card in sgs.qlist(da.from:getHandcards()) do
				local id = card:getEffectiveId()
				if id ~= -1 and card:isBlack() then
					local reason = sgs.CardMoveReason()
					reason.m_reason = sgs.CardMoveReason_S_REASON_PUT
					reason.m_playerId = da.from:objectName()
					room:moveCardTo(sgs.Sanguosha:getCard(id), da.from, sgs.Player_DrawPile, reason, false)
					x = x + 1
				end
			end
			if x == 0 then return end
			local log = sgs.LogMessage()
			log.type = "#TH_RoseHell_putback"
			log.from = da.from
			log.arg = x
			room:sendLog(log)
			if x >= 2 then
				local damage = sgs.DamageStruct()
				damage.from = player
				damage.to = da.from
				damage.damage = math.floor(x / 2)
				room:damage(damage)
			end
		end
	end
}

-----------------
TH_wuyishi = sgs.CreateTriggerSkill{-------
	name = "TH_wuyishi",
	events = {sgs.EventPhaseStart},
	on_trigger = function (self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			local n = room:getDiscardPile():length()
			if n == 0 then return false end
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			local cardslist = sgs.IntList()
			for i = 0, math.min(n - 1, 9) do
				cardslist:append(room:getDiscardPile():at(i))
			end
			if cardslist:isEmpty() then return false end
			local x = 3
			if player:hasSkill("TH_DNA") then x = x + 1 end
			for i = 1, x do
				room:fillAG(cardslist, player)
				local cardid = room:askForAG(player, cardslist, false, self:objectName())
				if cardid == -1 then
					cardid = cardslist:first()
				end
				cardslist:removeOne(cardid)
				player:obtainCard(sgs.Sanguosha:getCard(cardid), false)
				room:clearAG(player)
				if cardslist:isEmpty() then break end
			end
			player:skip(sgs.Player_Draw)
			return true
		end
	end
}

----------------------------
TH_DNA = sgs.CreateTriggerSkill{-----------DNA的瑕疵
	name = "TH_DNA",
	events = {sgs.EventPhaseEnd,sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		if player:getGeneralName() == "KomeijiSatori" or player:getGeneral2Name() == "KomeijiSatori" then return end
		if player:getGeneralName() == "KomeijiKoishi" or player:getGeneral2Name() == "KomeijiKoishi" then return end
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local koishi = room:findPlayersBySkillName(self:objectName())
		if koishi:isEmpty() then return end
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play then
			TH_logmessage("#TriggerSkill", player, self:objectName())
			local cardid = sgs.IntList()
			local acard = room:drawCard()
			cardid:append(acard)
			local acard = sgs.Sanguosha:getCard(acard)
			acard:setSkillName(self:objectName())
			local move = sgs.CardsMoveStruct()
			move.card_ids = cardid
			move.to_place = sgs.Player_PlaceTable
			move.reason.m_reason = sgs.CardMoveReason_S_REASON_TURNOVER
			room:moveCardsAtomic(move, true)
			local newmove = sgs.CardsMoveStruct()
			newmove.to_place = sgs.Player_DiscardPile
			newmove.reason.m_reason = sgs.CardMoveReason_S_REASON_THROW
			newmove.reason.m_playerId = player:objectName()
			newmove.reason.m_skillName = "TH_DNA"
			for _, card in sgs.qlist(player:getCards("he")) do
				if card:getType() == acard:getType() then newmove.card_ids:append(card:getEffectiveId()) end
			end
			if newmove.card_ids and newmove.card_ids:length() > 0 then room:moveCardsAtomic(newmove, true) end
			TH_logmessage("#TH_DNA_Dis", player, acard:getType())
			room:throwCard(acard, nil)
		end
	end
}

-------------------
TH_liandemaihuoCARD = sgs.CreateSkillCard{-------恋的埋火
	name = "TH_liandemaihuoCARD",
	skill_name = "TH_liandemaihuo",
	filter = function(self, targets, to_select)
		if to_select:getCardCount(true) == 0 then return false end
		return #targets < 2
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local cards1, cards2 = sgs.IntList(), sgs.IntList()
		for _, card in sgs.qlist(targets[1]:getCards("he")) do
			if card:getEffectiveId() < 0 then continue end
			cards1:append(card:getEffectiveId())
		end
		for _, card in sgs.qlist(targets[2]:getCards("he")) do
			if card:getEffectiveId() < 0 then continue end
			cards2:append(card:getEffectiveId())
		end
		local x = math.abs(cards1:length() - cards2:length())
		local cardmove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct()
		move1.card_ids = cards1
		move1.to = targets[2]
		move1.to_place = sgs.Player_PlaceHand
		local move2 = sgs.CardsMoveStruct()
		move2.card_ids = cards2
		move2.to = targets[1]
		move2.to_place = sgs.Player_PlaceHand
		cardmove:append(move1)
		cardmove:append(move2)
		room:moveCardsAtomic(cardmove, false)
		if x == 0 then return false end
		source:drawCards(math.floor(x / 2))
	end
}

TH_liandemaihuo = sgs.CreateViewAsSkill{------恋的埋火
	name = "TH_liandemaihuo",
	n = 0,
	view_as = function(self, cards)
		return TH_liandemaihuoCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_liandemaihuoCARD")
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------Hoshigumayuugi
TH_huaimiepaohouCARD = sgs.CreateSkillCard{-------------坏灭的咆吼
	name = "TH_huaimiepaohouCARD",
	skill_name = "TH_huaimiepaohou",
	on_use = function(self, room, source, targets)
		local subcard = sgs.Sanguosha:getCard(self:getSubcards():at(0))
		if subcard:isKindOf("NatureSlash") then
			local card = sgs.Sanguosha:cloneCard(subcard:objectName(), subcard:getSuit(), subcard:getNumber())
			local use = sgs.CardUseStruct()
			use.from = source
			use.to:append(targets[1])
			use.card = card
			use.card:setSkillName(self:objectName())
			room:useCard(use)
			-- source:broadcastSkillInvoke("slash")
			return
		end
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		card:setSkillName(self:objectName())
		local use = sgs.CardUseStruct()
		use.from = source
		use.to:append(targets[1])
		use.card = card
		room:useCard(use)
		-- source:broadcastSkillInvoke("slash")
	end
}

TH_huaimiepaohouVS = sgs.CreateViewAsSkill{----------坏灭的咆吼
	name = "TH_huaimiepaohou",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected<1
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return false end
		local hcard = TH_huaimiepaohouCARD:clone()
		hcard:addSubcard(cards[1]:getId())
		return hcard
	end,
	enabled_at_play = function(self, player)
		return player:hasFlag("TH_huaimiepaohou_on") and player:getCardCount(true) > 0
	end,
	enabled_at_response = function(self, player, pattern)
	   return pattern == "slash" and player:hasFlag("TH_huaimiepaohou_on") and player:getCardCount(true) > 0
	end,
}

TH_huaimiepaohou = sgs.CreateTriggerSkill{----------坏灭的咆吼
	name = "TH_huaimiepaohou",
	events = {sgs.Damaged, sgs.EventPhaseChanging},
	view_as_skill = TH_huaimiepaohouVS,
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if event == sgs.Damaged then
			local da = data:toDamage()
			for i=1, da.damage, 1 do
				player:addMark("TH_huaimiepaohou_draw")
			end
		elseif change.to == sgs.Player_Play and player:getMark("TH_huaimiepaohou_draw")>0 then
			player:drawCards(player:getMark("TH_huaimiepaohou_draw"))
			player:setMark("TH_huaimiepaohou_draw",0)
			room:setPlayerFlag(player,"TH_huaimiepaohou_on")
			room:setPlayerMark(player, "&TH_huaimiepaohou-PlayClear", 1)
		end
	end
}

----------------------------------
TH_aoyi_sanbubisha =  sgs.CreateTriggerSkill{-----------四天王奥义。三步必杀
	name = "TH_aoyi_sanbubisha",
	events = {sgs.DamageComplete},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		if not da.to or da.to:isDead() then return false end
		if da.from and not da.from:hasSkill(self:objectName()) then return false end
		if da.card and da.card:isKindOf("Slash") then
			if room:getDrawPile():length()==0 then room:swapPile() end
			local AP= playerNumber(player,true)
			if AP < 6 then return end
			local acardid=room:getDrawPile():at(math.random(0,room:getDrawPile():length()-1))
			local cardids = sgs.IntList()
			cardids:append(acardid)
			local card = sgs.Sanguosha:getCard(acardid)
			local move = sgs.CardsMoveStruct()
			move.card_ids = cardids
			move.to_place = sgs.Player_PlaceTable
			move.reason.m_reason = sgs.CardMoveReason_S_REASON_TURNOVER
			room:moveCardsAtomic(move, true)
			local cardnum = card:getNumber()
			if cardnum>AP then cardnum=cardnum-AP end
			local red
			if card:isRed() then red = true end
			TH_logmessage("#TH_aoyi_sanbubisha_num", player, card:getNumber(), nil, cardnum)
			room:throwCard(card,nil)
			local numdato = playerNumber(da.to)
			local numself = playerNumber(da.from)
			if numdato ~= cardnum and numself ~= cardnum then
				local sb
				for _,pp in sgs.qlist(room:getPlayers()) do
					if playerNumber(pp) == cardnum then
						sb = pp
						break
					end
				end
				TH_logmessage("#TH_aoyi_sanbubisha_target", sb, cardnum, da.to)
				room:swapSeat(sb,da.to)
				TH_logmessage("#TH_aoyi_sanbubisha_fromto", da.from, numself, da.to, cardnum)
				if AP%2 == 0 then
					if numself+AP/2==cardnum or numself-AP/2==cardnum then
						local log =  sgs.LogMessage()
						log.type="#TH_aoyi_sanbubisha"
						room:sendLog(log)
						local deathdamage = sgs.DamageStruct()
						deathdamage.from = da.from
						deathdamage.to = da.to
						-- room:broadcastInvoke("animate", "lightbox:#TH_aoyi_sanbubisha:2000")
						room:doLightbox("#TH_aoyi_sanbubisha", 2000)
						room:getThread():delay(2000)
						room:killPlayer(da.to, deathdamage)
					end
				else
					if (numself+(AP+1)/2==cardnum or numself+(AP-1)/2==cardnum or numself-(AP+1)/2==cardnum or numself-(AP-1)/2==cardnum) and red then
						TH_logmessage("#TH_aoyi_sanbubisha", player)
						local deathdamage = sgs.DamageStruct()
						deathdamage.from = da.from
						-- room:broadcastInvoke("animate", "lightbox:#TH_aoyi_sanbubisha:2000")
						room:doLightbox("#TH_aoyi_sanbubisha", 2000)
						room:getThread():delay(2000)
						room:killPlayer(da.to,deathdamage)
					end
				end
			end
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------ReiujiUtsuho
TH_SubterraneanSun = sgs.CreateTriggerSkill{-------地底的太阳
	name = "TH_SubterraneanSun",
	events = {sgs.DamageInflicted,sgs.DamageComplete},
	priority = -2,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local da = data:toDamage()
				if da.from and da.from:isAlive() and da.from:hasSkill(self:objectName()) then
				da.nature = sgs.DamageStruct_Fire
				data:setValue(da)
				end
		elseif event == sgs.DamageComplete then
			local da = data:toDamage()
			if da.nature == sgs.DamageStruct_Fire then
				local kongs = room:findPlayersBySkillName(self:objectName())
				if kongs:isEmpty() then return end
				for _,kong in sgs.qlist(kongs) do
					kong:gainMark("@TH_nuclear",da.damage)
				end
			end
		end
	end
}

TH_Meltdown = sgs.CreateTriggerSkill{-----地狱极乐熔毁
	name = "TH_Meltdown",
	events = { sgs.Damaged },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		if da.to:isKongcheng() then return false end
		if not da.to or not da.to:isAlive() or da.to:hasSkill(self:objectName()) then return false end
		if da.nature == sgs.DamageStruct_Fire then
			local log =  sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = da.from
			log.arg=self:objectName()
			room:sendLog(log)
			room:askForDiscard(da.to,self:objectName(),1,1,false,false,"#TH_Meltdown")
		end
	end
}

TH_NuclearCARD = sgs.CreateSkillCard{----------核弹
	name = "TH_NuclearCARD",
	skill_name = "TH_Nuclear",
	on_use = function(self, room, source, targets)
		source:loseMark("@TH_nuclear",10)
		room:setPlayerMark(source,"TH_Nuclear_sb"..targets[1]:objectName(),1)
	end
}

TH_NuclearVS=sgs.CreateViewAsSkill{----------核弹
	name = "TH_Nuclear",
	n = 0,
	view_as = function(self, cards)
		return TH_NuclearCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@TH_nuclear")>=10
	end,
}

TH_Nuclearskill={}
TH_Nuclearskill.owner={}
TH_Nuclearskill.target={}
TH_Nuclearskill.cd={}
TH_Nuclear = sgs.CreateTriggerSkill{-----------核弹
	name = "TH_Nuclear",
	events = {sgs.EventPhaseStart,sgs.CardFinished},
	frequency = sgs.Skill_Limited,
	view_as_skill = TH_NuclearVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:objectName() == "TH_NuclearCARD" then
				local sb = use.to:first()
				local mp = playerNumber(player,true)
				local j = playerNumber(player)
				local k = playerNumber(sb)
				local x = 0
				if j > k then
					x = j - k
					if x > mp/2 then x = mp-x end
				elseif j < k then
					x = k - j
					if x > mp/2 then x= mp-x end
				end
				table.insert(TH_Nuclearskill.target,k)
				table.insert(TH_Nuclearskill.owner,player:objectName())
				table.insert(TH_Nuclearskill.cd,x)
				local log =  sgs.LogMessage()
				log.type = "#TH_Nuclear_target"
				log.from = sb
				log.arg = k
				log.arg2 = x
				room:sendLog(log)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_RoundStart then
			if #TH_Nuclearskill.target==0 or #TH_Nuclearskill.cd==0 or TH_Nuclearskill.owner==0 then return end
			for i in pairs(TH_Nuclearskill.owner) do
				if TH_Nuclearskill.owner[i] == player:objectName() then
					if TH_Nuclearskill.cd[i] > 0 then
						TH_Nuclearskill.cd[i] = TH_Nuclearskill.cd[i] - 1
						if TH_Nuclearskill.cd[i] > 0 then
							local log =  sgs.LogMessage()
							log.type = "#TH_Nuclear_Countdown"
							log.arg = TH_Nuclearskill.cd[i]
							room:sendLog(log)
						end
					end
					if TH_Nuclearskill.cd[i] == 0 then
						local n = TH_Nuclearskill.target[i]
						local mp=playerNumber(player,true)
						local k=0
						local sb
						local sbs = sgs.SPlayerList()
						for _,p in sgs.qlist(room:getPlayers()) do
							k=k+1
							if k==n then
								sb=p
							elseif (k+1==n or k+2==n or k-1==n or k-2==n) and p:isAlive() then
								sbs:append(p)
							elseif (k+1-mp == n or k+2-mp == n or k-2+mp ==n or k-1+mp==n) and p:isAlive() then
								sbs:append(p)
							end
						end
						room:broadcastSkillInvoke("TH_Nuclear")
						if sb then
							room:setPlayerMark(player,"TH_Nuclear_sb"..sb:objectName(),0)
							local log =  sgs.LogMessage()
							log.type = "#TH_Nuclear_damage"
							log.to:append(sb)
							room:sendLog(log)
							if sb:isAlive() then
								local da1=sgs.DamageStruct()
								da1.from=player
								da1.to=sb
								da1.damage=sb:getHp()
								da1.nature = sgs.DamageStruct_Fire
								-- room:broadcastInvoke("animate", "lightbox:#TH_Nuclear_hit:2000")
								room:doLightbox("#TH_Nuclear_hit", 2000)
								room:getThread():delay(2000)
								room:damage(da1)
							end
						end
						if sbs:length()>0 then
							if sbs:contains(player) then sbs:removeOne(player) end
							local log =  sgs.LogMessage()
							log.type = "#TH_Nuclear_damages"
							log.from = sb
							log.to = sbs
							room:sendLog(log)
						end
						for i=0,sbs:length()-1 do
							local da2=sgs.DamageStruct()
							da2.from=player
							da2.to=sbs:at(i)
							da2.nature = sgs.DamageStruct_Fire
							da2.reason = "TH_Nuclear"
							room:damage(da2)
						end
					end
				end
			end
			local x = 0
			for i=1 ,#TH_Nuclearskill.owner ,1 do
				if TH_Nuclearskill.owner[i-x] == player:objectName() and TH_Nuclearskill.cd[i-x] <= 0 then
					table.remove(TH_Nuclearskill.owner,i-x)
					table.remove(TH_Nuclearskill.target,i-x)
					table.remove(TH_Nuclearskill.cd,i-x)
					x=x+1
				end
			end
		end
	end
}

TH_BlazeGeyser = sgs.CreateTriggerSkill{---------核焰喷涌
	name = "TH_BlazeGeyser",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local sb = sgs.SPlayerList()
			local mp = playerNumber(player,true)
			local i = playerNumber(player)
			local j = 0
			for _, pp in sgs.qlist(room:getPlayers()) do
				j = j + 1
				if (j - 1 == i or j + 1 == i or j - 1 + mp == i or j + 1 - mp == i) and pp:isAlive() then
					sb:append(pp)
					room:setPlayerFlag(player, "TH_BlazeGeyser_target" .. pp:objectName())
				end
			end
			if sb:isEmpty() then return false end
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			room:setPlayerFlag(sb:first(), "-TH_BlazeGeyser_target")
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg=self:objectName()
			room:sendLog(log)
			for i=1,sb:length() do
				local da = sgs.DamageStruct()
				da.from = player
				da.to = sb:at(i-1)
				da.nature = sgs.DamageStruct_Fire
				da.reason = (sb:length() == 2 and "TH_BlazeGeyser") or ""
				room:damage(da)
			end
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------kaenbyourin
TH_CatWalk =  sgs.CreateTriggerSkill{-----猫步
	name = "TH_CatWalk",
	events = {sgs.CardAsked},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local ask = data:toStringList()
		if #ask == 0 then return end
		if ask[1] == "jink" then
			if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
			--room:askForGuanxing(player, room:getNCards(5, false), false)
			local j = sgs.JudgeStruct()
			j.play_animation=true
			j.who = player
			j.reason = self:objectName()
			j.pattern = ".|club,diamond|.|.|."
			j.good = true
			room:judge(j)
			if j:isGood() then
				local jinkcard = sgs.Sanguosha:cloneCard("jink",sgs.Card_NoSuit,0)
				jinkcard:setSkillName("TH_CatWalk")
				room:provide(jinkcard)
				return true
			end
		elseif ask[1] == "slash" then
			if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
			local j = sgs.JudgeStruct()
			j.play_animation=true
			j.who = player
			j.reason = self:objectName()
			j.pattern = ".|club,diamond|.|.|."
			j.good = true
			room:judge(j)
			if j:isGood() then
				local slashcard = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
				slashcard:setSkillName("TH_CatWalk")
				room:provide(slashcard)
				return true
			end
		end
	end
}

TH_shitifanhuajie = sgs.CreateTriggerSkill{-------尸体
	name = "TH_shitifanhuajie",
	events = {sgs.DrawNCards},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		local room=player:getRoom()
		local n = 0
		for _,sb in sgs.qlist(room:getPlayers()) do
			if sb:isDead() then
				n=n+1
			end
		end
		draw.num = draw.num + n
		data:setValue(draw)
	end
}

TH_ZombieFairyCARD = sgs.CreateSkillCard{-------丧尸妖精
	name= "TH_ZombieFairyCARD",
	skill_name = "TH_ZombieFairy",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local ac = room:askForChoice(source,"TH_ZombieFairyCARD","TH_cancel+TH_ZombieFairy_summon+TH_ZombieFairy_unsummon")
		if ac == "TH_cancel" then
			return
		elseif ac == "TH_ZombieFairy_summon" then
			room:setPlayerFlag(source,"TH_ZombieFairy_used")
			local deathplayer = {}
			local zabing = { "KaenbyouRin_zabingjia", "KaenbyouRin_zabingyi", "KaenbyouRin_zabingbing" }
			for _,p in sgs.qlist(room:getPlayers()) do
				if p:isDead() then
					table.insert(deathplayer, p:getGeneralName())
				end
			end
			for _,p in sgs.qlist(room:getAllPlayers()) do
				for i = 1, #zabing do
					if zabing[i] == p:getGeneralName() and p:getMark("TH_ZombieFairy_Slave" .. source:objectName()) > 0 then
						table.remove(zabing, i)
						i = i - 1
					end
				end
			end
			if #deathplayer == 0 and #zabing > 0 then
				local log =  sgs.LogMessage()
				log.type = "#TH_ZombieFairy_allalive"
				room:sendLog(log)
				return
			end
			if #zabing == 0 and #deathplayer > 0 then
				local log =  sgs.LogMessage()
				log.type = "#TH_ZombieFairy_allzabing"
				room:sendLog(log)
				return
			end
			room:setPlayerFlag(source,"TH_ZombieFairy_used")
			local ap = room:askForChoice(source, "TH_ZombieFairy_shiti", table.concat(deathplayer,"+"))
			local sb
			for _,p in sgs.qlist(room:getPlayers()) do
				if p:getGeneralName() == ap and p:isDead() then
					sb=p
				end
			end
			local zabingname =room:askForGeneral(source,table.concat(zabing,"+"))
			room:changeHero(sb,zabingname,true,true,false,false)
			room:revivePlayer(sb)
			if source:getRole() == "lord" then
				room:setPlayerProperty(sb, "role", sgs.QVariant("loyalist"))
			else
				room:setPlayerProperty(sb, "role", sgs.QVariant(source:getRole()))
			end
			room:setPlayerProperty(sb, "kingdom", sgs.QVariant(source:getKingdom()))
			if not sb:faceUp() then sb:turnOver() end
			sb:drawCards(4)
			room:resetAI(sb)
			room:setPlayerFlag(sb, "TH_ZombieFairy_target")
			room:setPlayerMark(sb, "TH_ZombieFairy_Slave" .. source:objectName(), 1)
		elseif ac == "TH_ZombieFairy_unsummon" then
			local x = 0
			for _,p in sgs.qlist(room:getOtherPlayers(source)) do
				if (p:getGeneralName() == "KaenbyouRin_zabingjia" or p:getGeneralName() == "KaenbyouRin_zabingyi" or p:getGeneralName() == "KaenbyouRin_zabingbing") and
				p:getMark("TH_ZombieFairy_Slave" .. source:objectName())>0 then
					room:killPlayer(p)
					x=x+1
				end
			end
			if x > 0 then
				room:setPlayerFlag(source,"TH_ZombieFairy_used")
				source:drawCards(x)
			end
		end
	end
}

TH_ZombieFairy = sgs.CreateViewAsSkill{---丧尸妖精
	name = "TH_ZombieFairy",
	n = 0,
	view_as = function(self, cards)
		return TH_ZombieFairyCARD:clone()
	end,
	enabled_at_play=function(self, player)
		return not player:hasFlag("TH_ZombieFairy_used")
	end
}

----杂兵甲、乙、丙
TH_GreatestCautionCARD = sgs.CreateSkillCard{--灰暗警告冲击波
	name = "TH_GreatestCautionCARD",
	skill_name = "TH_GreatestCaution",
	on_use = function(self, room, source, targets)
		local da=sgs.DamageStruct()
		da.from=source
		da.to=targets[1]
		da.nature=sgs.DamageStruct_Thunder
		room:damage(da)
	end
}

TH_GreatestCaution=sgs.CreateViewAsSkill{--灰暗警告冲击波
	name = "TH_GreatestCaution",
	n = 0,
	view_as = function(self, cards)
		return TH_GreatestCautionCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_GreatestCautionCARD")
	end
}

TH_GalacticIllusionCARD = sgs.CreateSkillCard{--宇宙大幻觉
	name = "TH_GalacticIllusionCARD",
	skill_name = "TH_GalacticIllusion",
	filter = function(self, targets, to_select)
		return #targets < 2 and to_select:objectName()~=sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("fire_slash")
		slash:setSkillName("TH_GalacticIllusion")
		TH_logmessage("#TH_GalacticIllusion", targets[1], nil, targets[2])
		room:useCard(sgs.CardUseStruct(slash, targets[1], targets[2]), false)
		if targets[1]:isAlive() and targets[2]:isAlive() then
			TH_logmessage("#TH_GalacticIllusion", targets[2], nil, targets[1])
			room:useCard(sgs.CardUseStruct(slash, targets[2], targets[1]), false)
		end
	end
}

TH_GalacticIllusion=sgs.CreateViewAsSkill{--宇宙大幻觉
	name = "TH_GalacticIllusion",
	n = 0,
	view_as = function(self, cards)
		return TH_GalacticIllusionCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_GalacticIllusionCARD")
	end
}

TH_CosmicMarionnetteCARD = sgs.CreateSkillCard{----星辰傀儡线
	name = "TH_CosmicMarionnetteCARD",
	skill_name = "TH_CosmicMarionnette",
	filter = function(self, targets, to_select)
		return to_select:getMark("TH_CosmicMarionnette_target")< 1 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(targets[1],"TH_CosmicMarionnette_target",2)
		targets[1]:turnOver()
	end
}

TH_CosmicMarionnetteVS=sgs.CreateViewAsSkill{---星辰傀儡线
	name = "TH_CosmicMarionnette",
	n=2,
	view_filter =function(self, selected, to_select)
		return #selected<2 and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~= 2 then return end
		local card = TH_CosmicMarionnetteCARD:clone()
		card:addSubcard(cards[1])
		card:addSubcard(cards[2])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_CosmicMarionnetteCARD")
	end
}

TH_CosmicMarionnette =  sgs.CreateTriggerSkill{----星辰傀儡线
	name = "TH_CosmicMarionnette",
	events = {sgs.TurnStart},
	view_as_skill = TH_CosmicMarionnetteVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _,ap in sgs.qlist(room:getAlivePlayers()) do
			if ap:getMark("TH_CosmicMarionnette_target") > 0 then
				room:setPlayerMark(ap,"TH_CosmicMarionnette_target",ap:getMark("TH_CosmicMarionnette_target")-1)
			end
		end
	end
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------patchouliknowledge
TH_qiyaomofa = sgs.CreateTriggerSkill{------七曜魔法
	name = "TH_qiyaomofa",
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isKongcheng() then return false end
		local use = data:toCardUse()
		if not use.to:isEmpty() and use.to:at(0):isDead() then return false end
		if use.card:isKindOf("Nullification") then return false end
		if use.card:isKindOf("Collateral") then return false end
		if use.card:isKindOf("IronChain") and use.to:at(0):isChained() and use.to:at(1) and use.to:at(1):isChained() then return false end
		if (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement")) and use.to and use.to:at(0):getCards("hej"):isEmpty() then return false end
		if use.card:isNDTrick() and not player:hasFlag("TH_qiyaomofa_used") then
			local acard = room:askForCard(player, ".",("#TH_qiyaomofa:%s"):format(use.card:objectName()), data, self:objectName())
			if not acard then return false end
			local bcard = sgs.Sanguosha:cloneCard((use.card:objectName()), acard:getSuit(), acard:getNumber())
			bcard:setSkillName(self:objectName())
			room:setPlayerFlag(player,"TH_qiyaomofa_used")
			local newuse = sgs.CardUseStruct()
			newuse.from = use.from
			if not use.card:isKindOf("ExNihilo") then newuse.to = use.to end
			newuse.card = bcard
			room:useCard(newuse)
			room:setPlayerFlag(player,"-TH_qiyaomofa_used")
		end
	end
}

TH_PhilosophersStoneCARD = sgs.CreateSkillCard{-----贤者之石
	name = "TH_PhilosophersStoneCARD",
	skill_name = "TH_PhilosophersStone",
	target_fixed =true,
	on_use = function(self, room, source, targets)
		if room:getDrawPile():length() == 0 then room:swapPile() end
		local n = room:getDrawPile():length()
		local z = 0
		for i = 0, n do
			local acard = sgs.Sanguosha:getCard(room:getDrawPile():at(i))
			if acard:isNDTrick() then
				TH_obtainCard(source, acard)
				z = z + 1
				if z == 2 then break end
			end
		end
	end
}

TH_PhilosophersStoneVS = sgs.CreateViewAsSkill{------贤者之石
	name = "TH_PhilosophersStone",
	 n = 0,
	view_as = function(self, cards)
		return TH_PhilosophersStoneCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_PhilosophersStoneCARD")
	end,
}

TH_PhilosophersStone =  sgs.CreateTriggerSkill{-----贤者之石
	name = "TH_PhilosophersStone",
	events = {sgs.CardAsked},
	view_as_skill = TH_PhilosophersStoneVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardAsked then
			local str = data:toStringList()
			if #str == 0 then return end
			if str[1] == "jink" then
				if player:hasFlag("TH_PhilosophersStone_jink") then return false end
				if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
				local jinkcard = sgs.Sanguosha:cloneCard("jink",sgs.Card_NoSuit,0)
				jinkcard:setSkillName("TH_PhilosophersStone")
				room:provide(jinkcard)
				room:setPlayerFlag(player,"TH_PhilosophersStone_jink")
				return true
			elseif str[1] =="slash" then
				if player:hasFlag("TH_PhilosophersStone_slash") then return false end
				if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
				local slashcard = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
				slashcard:setSkillName("TH_PhilosophersStone")
				room:provide(slashcard)
				room:setPlayerFlag(player,"TH_PhilosophersStone_slash")
				return true
			end
		end
	end
}

---------------------------------------------------------------------------------------------------------------------------------------hinanawitenshi
TH_AllMUserCARD = sgs.CreateSkillCard{
	name = "TH_AllMUserCARD",
	skill_name = "TH_AllMUser",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		for _, tenshi in sgs.qlist(room:getOtherPlayers(source)) do
			if tenshi:hasSkill("TH_AllM") and not tenshi:hasFlag("TH_M_yamede") then
				local ac = room:askForChoice(tenshi, "TH_AllMUser", "TH_M_no+TH_M_yes")
				if ac == "TH_M_yes" then
					local da = sgs.DamageStruct()
					da.from = source
					da.to = tenshi
					da.nature = sgs.DamageStruct_Thunder
					da.reason = "TH_AllMUser"
					room:damage(da)
					if source:hasSkill("TH_YuukaSama") then
						source:drawCards(3)
					else
						source:drawCards(2)
					end
					room:addPlayerMark(tenshi, "TH_M_yamede")
					if tenshi:getMark("TH_M_yamede") >= tenshi:getMaxHp() then
						room:setPlayerFlag(tenshi, "TH_M_yamede")
					end
				elseif ac == "TH_M_no" then
					room:setPlayerFlag(tenshi, "TH_M_yamede")
				end
			end
		end
	end
}
TH_AllMUserVS = sgs.CreateViewAsSkill{
	name = "TH_AllMUser",
	n = 0,
	view_as = function(self, cards)
		return TH_AllMUserCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
TH_AllMUser = sgs.CreateTriggerSkill{
	name = "TH_AllMUser",
	events = { sgs.EventPhaseEnd },
	view_as_skill = TH_AllMUserVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Discard or player:getPhase() == sgs.Player_NotActive then
			for _, ap in sgs.qlist(room:getAlivePlayers()) do
				if ap:hasSkill("TH_AllM") then
					room:setPlayerFlag(ap, "-TH_M_yamede")
					room:setPlayerMark(ap, "TH_M_dame", 0)
				end
			end
		end
	end
}

TH_AllM = sgs.CreateTriggerSkill{
	name = "TH_AllM",
	events = {sgs.GameStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if not p:hasSkill("TH_AllMUser") and not p:hasSkill(self:objectName()) then
				room:attachSkillToPlayer(p, "TH_AllMUser")
			end
		end
	end
}

TH_mshiCARD = sgs.CreateSkillCard{
	name = "TH_mshiCARD",
	skill_name = "TH_mshi",
	on_use = function(self, room, source, targets)
		room:setPlayerProperty(source, "chained", sgs.QVariant(true))
		room:setEmotion(source, "chain")
		room:setPlayerProperty(targets[1], "chained", sgs.QVariant(true))
		room:setEmotion(targets[1], "chain")
		local da = sgs.DamageStruct()
		da.from = targets[1]
		da.to = source
		da.nature = sgs.DamageStruct_Thunder
		da.reason = "TH_mshi"
		room:damage(da)
	end
}

TH_mshiVS = sgs.CreateViewAsSkill{
	name = "TH_mshi",
	n = 0,
	view_as = function(self,cards)
		local card = TH_mshiCARD:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_mshiCARD")
	end
}

TH_mshi = sgs.CreateTriggerSkill{
	name = "TH_mshi",
	events = {sgs.DamageComplete},
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = TH_mshiVS,
	priority = -1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		if da.nature ~= sgs.DamageStruct_Normal then
			player:drawCards(1)
			if not da.from then return false end
			if da.from and da.to:objectName() == da.from:objectName() then return false end
			if not room:askForSkillInvoke(da.to, self:objectName(), data) then return false end
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = da.to
			log.arg = self:objectName()
			room:sendLog(log)
			room:setEmotion(da.to, "chain")
			room:setPlayerProperty(da.to, "chained", sgs.QVariant(true))
			room:setEmotion(da.from, "chain")
			room:setPlayerProperty(da.from, "chained", sgs.QVariant(true))
			local log = sgs.LogMessage()
			log.type = "#IronChainDamage"
			log.from = da.to
			room:sendLog(log)
			local log = sgs.LogMessage()
			log.type = "#IronChainDamage"
			log.from = da.from
			room:sendLog(log)
		end
	end
}

TH_tianjiedetaozi = sgs.CreateTriggerSkill{
	name = "TH_tianjiedetaozi",
	events = {sgs.HpRecover},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		if player:hasFlag("TH_tianjiedetaozi_use") then return end
		room:setPlayerFlag(player,"TH_tianjiedetaozi_use")
		local re = sgs.RecoverStruct()
		re.who = player
		room:recover(player,re,true)
		room:setPlayerFlag(player,"-TH_tianjiedetaozi_use")
	end
}

---------------------------------------------------------------------------------------------------------------------------------------nagaeiku
TH_longyudianzuan = sgs.CreateTriggerSkill{
	name = "TH_longyudianzuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused, sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		if event == sgs.DamageCaused then
			if da.to:getArmor() and da.to:objectName() ~= player:objectName() then
				room:addPlayerMark(da.to, "Armor_Nullified")
				player:setFlags("TH_longyudianzuan_on")
				da.damage = da.damage + 1
				data:setValue(da)
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
			end
		elseif event == sgs.Damage then
			if player:hasFlag("TH_longyudianzuan_on") then
				player:setFlags("-TH_longyudianzuan_on")
				room:removePlayerMark(da.to, "Armor_Nullified")
			end
		end
	end
}

TH_yuyiruokong = sgs.CreateTriggerSkill{
	name = "TH_yuyiruokong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted},
	can_trigger = function(self,target)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		local ikus = room:findPlayersBySkillName(self:objectName())
		if ikus:isEmpty() then return false end
		if da.nature ~= sgs.DamageStruct_Thunder then return end
		for _,iku in sgs.qlist(ikus) do
			if iku:hasFlag("TH_guanglongzhitanxi_used") then return end
		end
		room:setTag("TH_yuyiruokong_data", data)
		if da.from then
			for _,iku in sgs.qlist(ikus) do
				if da.from:objectName() == iku:objectName() then
					TH_logmessage("#TH_yuyiruokong",da.to)
					if room:askForSkillInvoke(iku,self:objectName(),data) then
						iku:gainMark("@TH_yuyi",da.damage)
						room:removeTag("TH_yuyiruokong_data")
						return true
					end
				end
			end
			for _,iku in sgs.qlist(ikus) do
				if iku:getCardCount(true) == 0 then return end
				if da.from:objectName() ~= iku:objectName() then
					TH_logmessage("#TH_yuyiruokong1",da.to,1)
					if room:askForSkillInvoke(iku,self:objectName(),data) and room:askForDiscard(iku,self:objectName(),1,1,false,true) then
						iku:gainMark("@TH_yuyi",da.damage)
						room:removeTag("TH_yuyiruokong_data")
						return true
					end
				end
			end
		else
			local TH_yuyiruokong_on = false
			for _,iku in sgs.qlist(ikus) do
				TH_logmessage("#TH_yuyiruokong",da.to)
				if room:askForSkillInvoke(iku,self:objectName(),data) then
					iku:gainMark("@TH_yuyi",da.damage)
					room:setPlayerFlag(da.to, "-TH_yuyiruokong_target")
					TH_yuyiruokong_on = true
				end
			end
			if TH_yuyiruokong_on then room:removeTag("TH_yuyiruokong_data") return true end
		end
		room:removeTag("TH_yuyiruokong_data")
	end
}

TH_guanglongzhitanxiCARD = sgs.CreateSkillCard{---光龙
	name = "TH_guanglongzhitanxiCARD",
	skill_name = "TH_guanglongzhitanxi",
	target_fixed = false,
	feasible = function(self, targets)
		return sgs.Self:getMark("@TH_yuyi") >= sgs.Self:aliveCount() - 1 and #targets <= 5 and #targets > 0
	end,
	filter = function(self, targets, to_select)
		return sgs.Self:getMark("@TH_yuyi") >= sgs.Self:aliveCount() - 1 and #targets < 5 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		if #targets == 0 then return end
		room:setPlayerFlag(source, "TH_guanglongzhitanxi_used")
		source:loseMark("@TH_yuyi",source:aliveCount() - 1)
		for _,p in ipairs(targets) do
			local da = sgs.DamageStruct()
			da.from = source
			da.to = p
			da.nature = sgs.DamageStruct_Thunder
			room:damage(da)
		end
		room:setPlayerFlag(source, "-TH_guanglongzhitanxi_used")
	end
}

TH_guanglongzhitanxiVS = sgs.CreateViewAsSkill{--光龙
	name ="TH_guanglongzhitanxi",
	n = 0,
	view_as =function(self,cards)
		return TH_guanglongzhitanxiCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@TH_yuyi") >= player:aliveCount() - 1
	end,
}

TH_guanglongzhitanxi = sgs.CreateTriggerSkill{---光龙
	name = "TH_guanglongzhitanxi",
	events ={sgs.Damage},
	view_as_skill = TH_guanglongzhitanxiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local da = data:toDamage()
		if player:getMark("@TH_yuyi") < 2 then return end
		if not da.to or da.to:isDead() then return end
		if player:hasFlag("TH_guanglongzhitanxi_used") then return end
		if not room:askForSkillInvoke(player, self:objectName(), data) then return end
		room:setPlayerFlag(player, "TH_guanglongzhitanxi_used")
		player:loseMark("@TH_yuyi",2)
		local damage = sgs.DamageStruct()
		damage.from = player
		damage.to = da.to
		damage.nature = sgs.DamageStruct_Thunder
		damage.reason = "TH_guanglongzhitanxi"
		room:damage(damage)
		room:setPlayerFlag(player, "-TH_guanglongzhitanxi_used")
	end
}

TH_longshendeshandianCARD = sgs.CreateSkillCard{
	name = "TH_longshendeshandianCARD",
	skill_name = "TH_longshendeshandian",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and not to_select:containsTrick("lightning")
	end,
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:cloneCard("lightning", sgs.Card_NoSuit, 0)
		card:setSkillName("TH_longshendeshandian")
		card:addSubcard(self:getSubcards():first())
		local use = sgs.CardUseStruct()
		use.from = source
		use.to:append(targets[1])
		use.card = card
		room:useCard(use)
	end

}
TH_longshendeshandianVS = sgs.CreateViewAsSkill{ -----闪电
	name ="TH_longshendeshandian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1
	end,
	view_as =function(self,cards)
		if #cards == 1 then
			local card = TH_longshendeshandianCARD:clone()
			card:addSubcard(cards[1]:getId())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}

TH_longshendeshandian = sgs.CreateTriggerSkill{----闪电
	name = "TH_longshendeshandian",
	events ={sgs.CardFinished},
	view_as_skill = TH_longshendeshandianVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Lightning") then
				if math.random(1, 3) == 1 then player:drawCards(1) end
				local ikus = room:findPlayersBySkillName(self:objectName())
				if ikus:isEmpty() then return false end
				for _,iku in sgs.qlist(ikus) do
					iku:gainMark("@TH_yuyi")
				end
			end
		end
	end
}

---------------------------------------------------------------------------------------------------------------------------------------houjuunue
TH_UndefinedAF = sgs.CreateTriggerSkill{
	name = "TH_UndefinedAF",
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.card:isNDTrick() and effect.from and effect.from:objectName() ~= player:objectName() and effect.to:objectName() == player:objectName() then
			local cardid = room:drawCard()
			TH_obtainCard(player, cardid)
			player:setFlags(self:objectName() .. cardid)
			local invoke = room:askForSkillInvoke(player, self:objectName(), data)
			player:setFlags("-" .. self:objectName() .. cardid)
			if invoke then
				TH_obtainCard(effect.from, cardid)
				return true
			end
		end
	end
}
-- TH_UndefinedAFOLD = sgs.CreateProhibitSkill{ --绝对领域
	-- name = "TH_UndefinedAFOLD",
	-- is_prohibited = function(self, from, to, card, others)
		-- if to and to:hasSkill(self:objectName()) and to:hasFlag("TH_UndefinedAFOLD_on") then
			-- if card and (card:isKindOf("AmazingGrace") or card:isKindOf("GodSalvation") or card:isKindOf("Peach") or card:isKindOf("Analeptic")) then return end
			-- if from and from:objectName() == to:objectName() then return end
			-- return true
		-- end
		-- return false
	-- end
-- }

-- TH_UndefinedAFOLD_flag = sgs.CreateTriggerSkill{
	-- name = "#TH_UndefinedAFOLD_flag",
	-- frequency = sgs.Skill_Compulsory,
	-- events = {sgs.CardUsed},
	-- can_trigger = function(self, target)
		-- return true
	-- end,
	-- on_trigger = function(self, event, player, data)
		-- local room = player:getRoom()
		-- for _,ap in sgs.qlist(room:getOtherPlayers(player)) do
			-- if ap:hasSkill("TH_UndefinedAFOLD") then
				-- x = math.random(1,2)
				-- if x == 1 then
					-- room:setPlayerFlag(ap,"TH_UndefinedAFOLD_on")
					-- TH_logmessage("#TH_UndefinedAFOLD", ap)
				-- else room:setPlayerFlag(ap,"-TH_UndefinedAFOLD_on")
				-- end
			-- end
		-- end
	-- end
-- }

TH_hengongCARD = sgs.CreateSkillCard{
	name = "TH_hengongCARD",
	skill_name = "TH_hengong",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and sgs.Sanguosha:getCard(self:getSubcards():at(0)):getNumber() <= to_select:getHp()
			and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use= function(self, room, source, targets)
		room:setPlayerFlag(source, "TH_hengong_used")
		local da = sgs.DamageStruct()
		da.from = source
		da.to = targets[1]
		room:damage(da)
		local pile = sgs.IntList()
		local number = sgs.Sanguosha:getCard(self:getSubcards():at(0)):getNumber()
		if number == 1 then return end
		for _,id in sgs.qlist(room:getDiscardPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:getNumber() == number - 1 then pile:append(id) end
			if pile:length() >= 10 then break end
		end
		if pile:length() > 0 then
			room:fillAG(pile, source)
			local cardid = room:askForAG(source, pile, false, self:objectName())
			if cardid == -1 then cardid = pile:first() end
			room:moveCardTo(sgs.Sanguosha:getCard(cardid), source, sgs.Player_PlaceHand, false)
			room:clearAG(source)
		end
	end
}

TH_hengongVS = sgs.CreateViewAsSkill{
	name = "TH_hengong",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1
	end,
	view_as = function(self,cards)
		if #cards ~= 1 then return end
		local acard = TH_hengongCARD:clone()
		acard:addSubcard(cards[1])
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("TH_hengong_used")
	end
}

TH_hengong = sgs.CreateTriggerSkill{
	name = "TH_hengong",
	view_as_skill = TH_hengongVS,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			for _, to in sgs.qlist(use.to) do
				if to:objectName() ~= player:objectName() then
					local distance = use.from:distanceTo(to)
					if distance== 1 then
						room:setPlayerFlag(use.from, "-TH_hengong_used")
						local card = to:getEquip(0)
						if card then
							use.from:obtainCard(card)
							if not use.from:getEquip(0) then
								TH_logmessage("#TriggerSkill",use.from,self:objectName())
								room:moveCardTo(card, use.from, sgs.Player_PlaceEquip, true)
							end
						end
					elseif distance == 2 then
						local choices
						local willdamage = true
						if to:getHandcardNum() > 1 then
							choices = "TH_hengong_selfdis"
						end
						for _,ap in sgs.qlist(room:getOtherPlayers(use.from)) do
							if ap:objectName() ~= to:objectName() and ap:getHandcardNum() > 0 then
								if choices then
									choices = choices.."+TH_hengong_otherdis"
								else
									choices = "TH_hengong_otherdis"
								end
								break
							end
						end
						if choices then
							TH_logmessage("#TriggerSkill", use.from, self:objectName())
							local choice = room:askForChoice(to, "TH_hengong", choices)
							if choice == "TH_hengong_selfdis" then
								local card = room:askForDiscard(to,"TH_hengong_selfdis",1,1,false,false)
								if card then willdamage = false end
							elseif choice == "TH_hengong_otherdis" then
								local sb = sgs.QVariant()
								sb:setValue(to)
								room:setTag("TH_hengong_target", sb)
								for _,ap in sgs.qlist(room:getOtherPlayers(use.from)) do
									if ap:objectName() ~= to:objectName() then
										local discard = room:askForDiscard(ap,"TH_hengong_otherdis",1,1,true,false,"#TH_hengong_otherdis")
										if discard then willdamage = false break end
									end
								end
								room:removeTag("TH_hengong_target")
							end
						end
						if willdamage then
							local da = sgs.DamageStruct()
							da.from = use.from
							da.to = to
							room:damage(da)
						end
					end
				end
			end
		end
	end
}

TH_UndefinedUFOCARD = sgs.CreateSkillCard{
	name = "TH_UndefinedUFOCARD",
	skill_name = "TH_UndefinedUFO",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets<1 and to_select:objectName()~=sgs.Self:objectName()
	end,
	on_use= function(self, room, source, targets)
		if targets[1]:getNext():objectName() == source:objectName() then
			TH_logmessage("TH_UndefinedUFO_wrong",source)
			return
		end
		local ap = sgs.QVariant()
		ap:setValue(targets[1]:getNext())
		room:setTag("TH_UndefinedUFO_target"..source:objectName(),ap)
		room:setPlayerMark(source,"TH_UndefinedUFO_mark",2)
		room:setPlayerFlag(source,"TH_UndefinedUFO_off")
	end
}

TH_UndefinedUFOVS = sgs.CreateViewAsSkill{
	name = "TH_UndefinedUFO",
	n = 0,
	view_as = function(self,cards)
		return TH_UndefinedUFOCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("TH_UndefinedUFO_off")
	end
}

TH_UndefinedUFO = sgs.CreateTriggerSkill{
	name = "TH_UndefinedUFO",
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_UndefinedUFOVS,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		local ap = room:getTag("TH_UndefinedUFO_target"..player:objectName()):toPlayer()
		if change.to == sgs.Player_RoundStart then
			if player:getMark("TH_UndefinedUFO_mark")>0 then room:setPlayerFlag(player,"TH_UndefinedUFO_off") end
		elseif change.to == sgs.Player_Start and player:getMark("TH_UndefinedUFO_mark")==1 then
			room:swapSeat(player,ap)
		elseif change.to == sgs.Player_NotActive and player:getMark("TH_UndefinedUFO_mark")>0 then
			player:removeMark("TH_UndefinedUFO_mark")
			if ap and player:getMark("TH_UndefinedUFO_mark")==0 then
				room:removeTag("TH_UndefinedUFO_target"..player:objectName())
				room:swapSeat(player,ap)
			end
		end
	end
}

---------------------------------------------------------------------------------------------------------------------------------------Nazrin
TH_NazrinPendulumCARD = sgs.CreateSkillCard{
	name = "TH_NazrinPendulumCARD",
	skill_name = "TH_NazrinPendulum",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:removeTag("TH_NazrinPendulum_Choice")
		local choice = room:askForChoice(source, "TH_NazrinPendulum", "TH_cancel+Slash+Jink+Peach", sgs.QVariant())
		if choice == "TH_cancel" then return end
		room:setTag("TH_NazrinPendulum_Choice", sgs.QVariant(choice))
		local tag = room:getTag("TH_NazrinPendulum_Choice")
		for _, ap in sgs.qlist(room:getOtherPlayers(source)) do
			if not ap:isKongcheng() then
				for _, pcard in sgs.qlist(ap:getHandcards()) do
					if pcard:isKindOf(choice) then
						room:throwCard(pcard, ap, source)
						room:setPlayerFlag(ap, "TH_NazrinPendulum_threw")
						break
					end
				end
			end
		end
		-- local acard_obname = acard:objectName()
		-- if acard_obname == "fire_slash" or acard_obname == "thunder_slash" then acard_obname = "slash" end
		-- for _, ap in sgs.qlist(room:getOtherPlayers(source)) do
			-- if not ap:isKongcheng() then
				-- for _,pcard in sgs.qlist(ap:getHandcards()) do
					-- local pcard_obname = pcard:objectName()
					-- if pcard_obname == "fire_slash" or acard_obname == "thunder_slash" then pcard_obname = "slash" end
					-- if pcard_obname == acard_obname then
						-- room:throwCard(pcard, ap, source)
						-- break
					-- end
				-- end
			-- end
		-- end
	end
}

TH_NazrinPendulum = sgs.CreateViewAsSkill{
	name = "TH_NazrinPendulum",
	n = 0,
	view_as = function(self,cards)
		return TH_NazrinPendulumCARD:clone()
	end,
	-- view_filter = function(self, selected, to_select)
		-- return #selected<1 and not to_select:isEquipped()
	-- end,
	-- view_as = function(self,cards)
		-- if #cards == 1 then
			-- local acard = TH_NazrinPendulumCARD:clone()
			-- acard:addSubcard(cards[1])
			-- acard:setSkillName("TH_NazrinPendulum")
			-- return acard
		-- end
	-- end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_NazrinPendulumCARD")
	end
}

TH_Detector = sgs.CreateTriggerSkill{
	name = "TH_Detector",
	events = {sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Draw then
			for _, cardid in sgs.qlist(room:getDiscardPile()) do
				local acard = sgs.Sanguosha:getCard(cardid)
				-- local suit = acard:getSuitString()
				local number = acard:getNumber()
				if acard:isKindOf("Snatch") and room:askForCard(player, ".|.|"..number.."|.|.", string.format("#TH_Detector:%s",number), sgs.QVariant(), self:objectName()) then
					player:obtainCard(acard)
				end
			end
		end
	end
}

TH_GreatestTreasureVS = sgs.CreateViewAsSkill{
	name = "TH_GreatestTreasure",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected<1 and not to_select:isEquipped()
	end,
	view_as = function(self,cards)
		if #cards==1 then
			local bcard = sgs.Sanguosha:cloneCard("snatch", cards[1]:getSuit(), cards[1]:getNumber())
			bcard:addSubcard(cards[1])
			bcard:setSkillName("TH_GreatestTreasure")
			return bcard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("TH_GreatestTreasure_used")
	end,
}

TH_GreatestTreasure = sgs.CreateTriggerSkill{
	name = "TH_GreatestTreasure",
	events = { sgs.ChoiceMade, sgs.CardUsed },
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = TH_GreatestTreasureVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ChoiceMade then
			local snatch = data:toString():split(":")
			if snatch[1] == "cardChosen" and snatch[2] == "snatch" then
				local id = tonumber(snatch[3])
				if room:getCardPlace(id) == sgs.Player_PlaceDelayedTrick then return end
				local to_obname, to = snatch[4]
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:objectName() == to_obname then to = p break end
				end
				if to:getCardCount() <= 1 then return end
				local ids = sgs.IntList()
				ids:append(id)
				local cardid = room:askForCardChosen(player, to, "he", self:objectName(), false, sgs.Card_MethodNone, ids)
				if cardid == id then
					local flag = "he"
					if room:getCardPlace(cardid) == sgs.Player_PlaceHand and to:getHandcardNum() >= 2 then flag = "h" end
					local hecards = to:getCards(flag)
					for i = 1, math.huge do
						cardid = hecards:at(math.random(0, hecards:length() - 1)):getEffectiveId()
						if cardid ~= id then break end
					end
				end
				if cardid ~= id then TH_obtainCard(player, cardid) end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Snatch") and use.card:getSkillName() == "TH_GreatestTreasure" then
				room:setPlayerFlag(player, "TH_GreatestTreasure_used")
			end
		end
	end
}

---------------------------------------------------------------------------------------------------------------------------------------IbukiSuika
TH_jiuvs = sgs.CreateViewAsSkill{
	name = "TH_jiu",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1
	end,
	view_as = function(self,cards)
		if sgs.Self:getHp() < 1 and #cards == 1 then
			local jiu_card = sgs.Sanguosha:cloneCard("analeptic", cards[1]:getSuit() ,cards[1]:getNumber())
			jiu_card:addSubcard(cards[1])
			jiu_card:setSkillName("TH_jiu")
			return jiu_card
		elseif sgs.Self:getHp() > 0 then
			local jiu_card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit ,0)
			jiu_card:setSkillName("TH_jiu")
			return jiu_card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("Analeptic")
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "peach") and not player:hasFlag("TH_jiu_used") and player:getHp() < 1
	end,
}

TH_jiu = sgs.CreateTriggerSkill{
	name = "TH_jiu",
	events = {sgs.CardUsed},
	view_as_skill = TH_jiuvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Analeptic") and use.card:getSkillName() == "TH_jiu" and use.from:getHp() < 1 and use.card:subcardsLength() == 0 then
			room:setPlayerFlag(player, "TH_jiu_used")
		end
	end
}

TH_MissingPowerVS = sgs.CreateViewAsSkill{
	name = "TH_MissingPower",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected<1 and to_select:isKindOf("Jink")
	end,
	view_as = function(self,cards)
		if #cards == 1 then
			local acard = sgs.Sanguosha:cloneCard("duel", cards[1]:getSuit(), cards[1]:getNumber())
			acard:addSubcard(cards[1])
			acard:setSkillName("TH_MissingPower")
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return player:getHp() <= 2 or player:hasFlag("TH_suiyue_buff")
	end,
}

TH_MissingPower = sgs.CreateTriggerSkill{
	name = "TH_MissingPower",
	events = {sgs.TargetConfirmed},
	view_as_skill = TH_MissingPowerVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Slash") then
				if use.from:objectName() == player:objectName() then
					local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
					local index = 1
					local targets = use.to
					for _, target in sgs.qlist(targets) do
						if target:getHp() > player:getHp() then
							local log = sgs.LogMessage()
							log.type = "#skill_cant_jink"
							log.from = player
							log.to:append(target)
							log.arg = self:objectName()
							room:sendLog(log)
							jink_table[index] = 0
						end
						index = index + 1
					end
					local jink_data = sgs.QVariant()
					jink_data:setValue(Table2IntList(jink_table))
					player:setTag("Jink_" .. use.card:toString(), jink_data)
				end
			end
		end
	end
}

TH_sanbuhuaifei = sgs.CreateTriggerSkill{
	name = "TH_sanbuhuaifei",
	events = {sgs.CardUsed},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			for _, to in sgs.qlist(use.to) do
				if to:objectName() ~= player:objectName() then
					if player:hasFlag("TH_suiyue_buff") then
						TH_logmessage("#TriggerSkill", to, self:objectName())
						to:throwAllHandCardsAndEquips()
					else
						local ac = playerNumber(player, true)
						if ac < 6 then return end
						local fromnum = playerNumber(player)
						local tonum = playerNumber(to)
						local card = sgs.Sanguosha:getCard(room:drawCard())
						local reason = sgs.CardMoveReason()
						reason.m_reason = sgs.CardMoveReason_S_REASON_TURNOVER
						reason.m_playerId = to:objectName()
						room:moveCardTo(card, nil, sgs.Player_PlaceTable, reason, true)
						local deathnum = card:getNumber()
						while deathnum > ac do
							deathnum = deathnum - ac
						end
						if deathnum == tonum then
							TH_logmessage("#TriggerSkill", to, self:objectName())
							to:throwAllHandCardsAndEquips()
						end
					end
				end
			end
		end
	end
}

----------------------------
TH_suiyueCARD = sgs.CreateSkillCard{
	name = "TH_suiyueCARD",
	skill_name = "TH_suiyue",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("TH_suiyue")
		source:loseMark("@TH_suiyue")
		room:setPlayerMark(source, "TH_suiyue_buff", 3)
		room:setPlayerMark(source, "&TH_suiyue", 3)
		room:setPlayerFlag(source, "TH_suiyue_buff")
	end
}

TH_suiyueVS = sgs.CreateViewAsSkill{
	name = "TH_suiyue",
	n = 0,
	view_as = function(self,cards)
		return TH_suiyueCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@TH_suiyue") == 1
	end
}

TH_suiyue_use = { usetime = {}, owner = {} }
TH_suiyue = sgs.CreateTriggerSkill{
	name = "TH_suiyue",
	events = {sgs.EventPhaseStart, sgs.CardUsed},
	frequency = sgs.Skill_Limited,
	limit_mark = "@TH_suiyue",
	view_as_skill = TH_suiyueVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use and use.card and use.card:getSkillName() == "TH_suiyueCARD" then
				table.insert(TH_suiyue_use.usetime, os.time())
				table.insert(TH_suiyue_use.owner, use.from:objectName())
			end
		elseif sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:getMark("TH_suiyue_buff") > 0 then
			player:removeMark("TH_suiyue_buff")
			player:removeMark("&TH_suiyue")
			local suiyue_on = true
			for i = 1, #TH_suiyue_use.owner do
				if TH_suiyue_use.owner[i] == player:objectName() and TH_suiyue_use.usetime[i] + 264 < os.time() then
					suiyue_on = false
					table.remove(TH_suiyue_use.owner, i)
					table.remove(TH_suiyue_use.usetime, i)
				end
			end
			if suiyue_on then room:setPlayerFlag(player, "TH_suiyue_buff") end
		end
	end
}

---------------------------------------------------------------------------------------------------------------------------------------tatarakogasa
TH_demaciaCARD = sgs.CreateSkillCard{
	name = "TH_demaciaCARD",
	skill_name = "TH_demacia",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		source:gainMark("@TH_demacia")
	end
}

TH_demaciaVS = sgs.CreateViewAsSkill{
	name = "TH_demacia",
	n = 2,
	view_filter = function(self, selected, to_select)
		return #selected < 2
	end,
	view_as = function(self,cards)
		if #cards == 2 then
			local card = TH_demaciaCARD:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getCardCount(true) > 1 and player:getMark("@TH_demacia") < 1
	end,
}

TH_demacia = sgs.CreateTriggerSkill{
	name = "TH_demacia",
	events = {sgs.TurnStart},
	frequency = sgs.Skill_Limited,
	view_as_skill = TH_demaciaVS,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		if not player:hasSkill(self:objectName()) then
			local room = player:getRoom()
			local kogasas = room:findPlayersBySkillName(self:objectName())
			if kogasas:isEmpty() then return end
			for _, kogasa in sgs.qlist(kogasas) do
				if kogasa:getMark("@TH_demacia") == 1 and room:askForSkillInvoke(kogasa, self:objectName()) then
					kogasa:loseMark("@TH_demacia")
					for i = 1 , math.random(1, 10) do
						TH_logmessage("#TH_demacia", player)
					end
					player:turnOver()
				end
			end
		end
	end
}

TH_demaciags = sgs.CreateTriggerSkill{
	name = "#TH_demaciags",
	events = { sgs.GameStart },
	frequency = sgs.Skill_Limited,
	view_as_skill = TH_demaciaVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:setPlayerMark(player, "@TH_demacia", 1)
	end
}

TH_paratrooperCARD = sgs.CreateSkillCard{
	name = "TH_paratrooperCARD",
	skill_name = "TH_paratrooper",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		for _, player in sgs.qlist(room:getOtherPlayers(source)) do
			if card:isKindOf("Weapon") and player:getWeapon() then
				local da = sgs.DamageStruct()
				da.from = source
				da.to = player
				da.reason = "TH_paratrooper"
				room:damage(da)
			elseif card:isKindOf("Armor") and player:getArmor() then
				local da = sgs.DamageStruct()
				da.from = source
				da.to = player
				da.reason = "TH_paratrooper"
				room:damage(da)
			elseif card:isKindOf("DefensiveHorse") and player:getDefensiveHorse() then
				local da = sgs.DamageStruct()
				da.from = source
				da.to = player
				da.reason = "TH_paratrooper"
				room:damage(da)
			elseif card:isKindOf("OffensiveHorse") and player:getOffensiveHorse() then
				local da = sgs.DamageStruct()
				da.from = source
				da.to = player
				da.reason = "TH_paratrooper"
				room:damage(da)
			end
		end
	end
}

TH_paratrooperVS = sgs.CreateViewAsSkill{
	name = "TH_paratrooper",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1 and to_select:isKindOf("EquipCard")
	end,
	view_as = function(self,cards)
		if #cards == 1 then
			local card = TH_paratrooperCARD:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getCardCount(true) > 1 and not player:hasUsed("#TH_paratrooperCARD")
	end,
}

TH_paratrooper = sgs.CreateTriggerSkill{
	name = "TH_paratrooper",
	events = {sgs.CardsMoveOneTime},
	priority = -2,
	view_as_skill = TH_paratrooperVS,
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		if move and move.reason and move.reason.m_reason and move.reason.m_reason == sgs.CardMoveReason_S_REASON_CHANGE_EQUIP and move.card_ids:length() > 0 and move.from and move.from:objectName() ~= player:objectName() then
			for _, cardid in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(cardid)
				if card:isKindOf("EquipCard") then player:obtainCard(card) end
			end
		end
	end
}

TH_UmbrellaCycloneCARD = sgs.CreateSkillCard{
	name = "TH_UmbrellaCycloneCARD",
	skill_name = "TH_UmbrellaCyclone",
	on_use = function(self, room, source, targets)
		local x = source:getMark("@TH_Umbrella")
		local choices
		for i=1, x, 1 do
			if not choices then
				choices = "1"
			else
				choices = choices.."+"..i
			end
		end
		local newdata = sgs.QVariant()
		newdata:setValue(targets[1])
		local ac = room:askForChoice(source, self:objectName(), choices, newdata)
		source:loseMark("@TH_Umbrella", tonumber(ac))
		targets[1]:gainMark("@TH_Umbrella_damage", tonumber(ac))
	end
}

TH_UmbrellaCycloneVS = sgs.CreateViewAsSkill{
	name = "TH_UmbrellaCyclone",
	n = 0,
	view_as = function(self,cards)
		return TH_UmbrellaCycloneCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@TH_Umbrella") > 0 and not player:hasUsed("#TH_UmbrellaCycloneCARD")
	end,
}

TH_UmbrellaCyclone = sgs.CreateTriggerSkill{
	name = "TH_UmbrellaCyclone",
	events = { sgs.Damaged, sgs.DamageForseen },
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_UmbrellaCycloneVS,
	can_trigger = function(self, target)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local da = data:toDamage()
		if event == sgs.Damaged then
			if da.to and da.to:objectName() == player:objectName() and da.to:hasSkill(self:objectName()) and player:isAlive() then
				player:gainMark("@TH_Umbrella", da.damage)
			end
		elseif event == sgs.DamageForseen and da.to:getMark("@TH_Umbrella_damage") > 0 then
			da.damage = da.damage + da.to:getMark("@TH_Umbrella_damage")
			da.to:loseAllMarks("@TH_Umbrella_damage")
			data:setValue(da)
		end
	end
}

---------------------------------------------------------------------------------------------------------------------------------------HijiriByakuren
TH_moshenfusong = sgs.CreateTriggerSkill{
	name = "TH_moshenfusong",
	events = { sgs.AskForPeachesDone},
	frequency = sgs.Skill_Limited,
	limit_mark = "@TH_moshenfusong",
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForPeachesDone then
			local dying = data:toDying()
			if dying.who:getHp() > 0 then return end
			local byakurens = room:findPlayersBySkillName(self:objectName())
			if byakurens:isEmpty() then return end
			for _, byakuren in sgs.qlist(byakurens) do
				if byakuren:getMark("@TH_moshenfusong") == 1 and room:askForSkillInvoke(byakuren, self:objectName(), data) then
					byakuren:loseMark("@TH_moshenfusong")
					room:setEmotion(dying.who, "recover")
					room:setPlayerProperty(dying.who,"hp",sgs.QVariant(dying.who:getMaxHp()))
					dying.who:drawCards(4)
					room:setPlayerFlag(dying.who, "-Global_Dying")
					local currentdying = room:getTag("CurrentDying"):toStringList()
					table.removeOne(currentdying,dying.who:objectName())
					room:setTag("CurrentDying", sgs.QVariant(table.concat(currentdying, "|")))
					break
				end
			end
		end
	end
}

TH_chaorenCARD = sgs.CreateSkillCard{
	name = "TH_chaorenCARD",
	skill_name = "TH_chaoren",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local selfpile = source:getPile("TH_yinhexi_pile")
		local move = sgs.CardsMoveStruct()
		for i=0, 6 do
			move.card_ids:append(selfpile:at(i))
		end
		move.to_place = sgs.Player_DiscardPile
		move.reason.m_reason = sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE
		room:moveCardsAtomic(move,true)
		source:setFlags("TH_chaoren_turn")
	end
}

TH_chaorenVS = sgs.CreateViewAsSkill{
	name = "TH_chaoren",
	n = 0,
	view_as = function(self,cards)
		return TH_chaorenCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_chaorenCARD") and player:getPile("TH_yinhexi_pile"):length() > 6
	end,
}

TH_chaoren = sgs.CreateTriggerSkill{
	name = "TH_chaoren",
	view_as_skill = TH_chaorenVS,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive and player:hasFlag("TH_chaoren_turn") then
			local ndata = sgs.QVariant()
			ndata:setValue(player)
			room:setTag("TH_chaoren_turn", ndata)
		end
	end
}

TH_chaoren_turn = sgs.CreateTriggerSkill{
	name = "#TH_chaoren_turn",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, player)
		return player:getPhase() == sgs.Player_NotActive
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local tag = room:getTag("TH_chaoren_turn")
		if tag then
			local byakuren = tag:toPlayer()
			room:removeTag("TH_chaoren_turn")
			if byakuren and byakuren:isAlive() then
				byakuren:gainAnExtraTurn()
			end
		end
	end
}

TH_yinhexiCARD = sgs.CreateSkillCard{
	name = "TH_yinhexiCARD",
	skill_name = "TH_yinhexi",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local move = sgs.CardsMoveStruct()
		move.card_ids = source:getPile("TH_yinhexi_pile")
		move.to_place = sgs.Player_PlaceHand
		move.to = source
		move.from_pile_name = "TH_yinhexi_pile"
		room:moveCardsAtomic(move, false)
		local exchange_card = room:askForExchange(source, "TH_yinhexi", move.card_ids:length(), move.card_ids:length())
        local players = sgs.SPlayerList()
        players:append(source)
        source:addToPile("TH_yinhexi_pile", exchange_card:getSubcards(), false, players)
        exchange_card:deleteLater()
	end
}

TH_yinhexiVS = sgs.CreateViewAsSkill{
	name = "TH_yinhexi",
	n = 0,
	view_as = function(self,cards)
		return TH_yinhexiCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_yinhexiCARD") and player:getPile("TH_yinhexi_pile"):length() > 0
	end,
}

TH_yinhexi = sgs.CreateTriggerSkill{
	name = "TH_yinhexi",
	view_as_skill = TH_yinhexiVS,
	events = { sgs.EventPhaseStart },
	can_trigger = function()
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Discard then
			local num = player:getHandcardNum() - player:getMaxCards()
			if num < 1 then return end
			local byakurens = room:findPlayersBySkillName(self:objectName())
			if byakurens:isEmpty() then return end
			local cards = room:askForExchange(player, self:objectName() .. "give", num, num, false, self:objectName() .. "discard", true)
			if not cards then return end
			local byakuren = room:askForPlayerChosen(player,  byakurens, self:objectName())
			if not byakuren then return end
			local selfpile = byakuren:getPile("TH_yinhexi_pile")
			if selfpile:length() >= 12 then return end
			for _,card in sgs.qlist(cards:getSubcards()) do
				byakuren:addToPile("TH_yinhexi_pile", card, false)
			end
		elseif player:getPhase() == sgs.Player_Play then
			local byakurens = room:findPlayersBySkillName(self:objectName())
			if byakurens:isEmpty() or byakurens:contains(player) then return end
			local byakuren = room:askForPlayerChosen(player,  byakurens, self:objectName())
			if not byakuren then return end
			local selfpile = byakuren:getPile("TH_yinhexi_pile")
			if selfpile and selfpile:length() > 0 and room:askForSkillInvoke(byakuren, "TH_yinhexi_askcard") then
				for i = 1, math.min(2, byakuren:getPile("TH_yinhexi_pile"):length()) do
					room:fillAG(byakuren:getPile("TH_yinhexi_pile"), player)
					local cardid
					cardid = room:askForAG(player, byakuren:getPile("TH_yinhexi_pile"), true,self:objectName())
					if cardid == -1 then
						room:clearAG(player)
						break
					end
					byakuren:getPile("TH_yinhexi_pile"):removeOne(cardid)
					TH_obtainCard(player, sgs.Sanguosha:getCard(cardid))
					room:clearAG(player)
					if byakuren:getPile("TH_yinhexi_pile"):isEmpty() then break end
				end
			end
		end
	end
}

---------------------------------------------------------------------------------------------------------------------------------------UsamiRenko
TH_ScienceCARD = sgs.CreateSkillCard{--科学
	name = "TH_ScienceCARD",
	skill_name = "TH_Science",
	will_throw = false,
	filter = function(self, selected, to_select)
		return #selected < 1 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local cardid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(cardid)
		local acard = room:askForCardShow(targets[1], source, "TH_Science")
		room:showCard(source, cardid)
		room:showCard(targets[1], acard:getEffectiveId())
		if card:getSuit() == acard:getSuit() then
			TH_obtainCard(targets[1], card)
		else
			TH_obtainCard(source, acard)
		end
	end
}

TH_Science = sgs.CreateViewAsSkill{--科学
	name = "TH_Science",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1 and not to_select:isEquipped()
	end,
	view_as = function(self,cards)
		if #cards == 1 then
			local card = TH_ScienceCARD:clone()
			card:setSkillName(self:objectName())
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_ScienceCARD") and not player:isKongcheng()
	end,
}

TH_UnscientificCARD = sgs.CreateSkillCard{--这不科学
	name = "TH_UnscientificCARD",
	skill_name = "TH_Unscientific",
	will_throw = false,
	filter = function(self, selected, to_select)
		return #selected < 1 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local cardid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(cardid)
		local suit = card:getSuitString()
		room:showCard(source, cardid)
		local askcard = room:askForCard(targets[1], ".|"..suit.."|.|hand", string.format("#TH_Unscientific:%s", suit), sgs.QVariant())
		if not askcard then
			local da = sgs.DamageStruct()
			da.from = source
			da.to = targets[1]
			room:damage(da)
		end
	end
}

TH_UnscientificVS = sgs.CreateViewAsSkill{--这不科学
	name = "TH_Unscientific",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1 and not to_select:isEquipped()
	end,
	view_as = function(self,cards)
		if #cards == 1 then
			local card = TH_UnscientificCARD:clone()
			card:setSkillName(self:objectName())
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_UnscientificCARD") and not player:isKongcheng()
	end,
}

TH_Unscientific = sgs.CreateTriggerSkill{--这不科学
	name = "TH_Unscientific",
	frequency = sgs.Skill_Limited,
	view_as_skill = TH_UnscientificVS,
	events = {sgs.NonTrigger},
	on_trigger = function(self, event, player, data)
	end
}

TH_MoreUnscientificCARD = sgs.CreateSkillCard{--这更不科学
	name = "TH_MoreUnscientificCARD",
	skill_name = "TH_MoreUnscientific",
	filter = function(self, targets, to_select)
		return #targets < 1 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local move = sgs.CardsMoveStruct()
		move.card_ids = room:getNCards(2, false)
		move.to_place = sgs.Player_PlaceTable
		move.reason.m_reason = sgs.CardMoveReason_S_REASON_TURNOVER
		room:moveCardsAtomic(move, true)
		local num = sgs.Sanguosha:getCard(move.card_ids:first()):getNumber() + sgs.Sanguosha:getCard(move.card_ids:last()):getNumber() + 1
		local askcard = room:askForCard(targets[1], ".|.|"..num.."~13|hand|.", string.format("#TH_MoreUnscientific:%s", num - 1), sgs.QVariant())
		if not askcard then
			local da = sgs.DamageStruct()
			da.from =source
			da.to = targets[1]
			room:damage(da)
		end
		room:throwCard(move.card_ids:first(), nil)
		room:throwCard(move.card_ids:last(), nil)
	end
}

TH_MoreUnscientificVS = sgs.CreateViewAsSkill{--这更不科学
	name = "TH_MoreUnscientific",
	n = 0,
	view_as = function(self,cards)
		return TH_MoreUnscientificCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_MoreUnscientificCARD")
	end,
}

TH_MoreUnscientific = sgs.CreateTriggerSkill{---这更不科学
	name = "TH_MoreUnscientific",
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_MoreUnscientificVS,
	events = {sgs.NonTrigger},
	on_trigger = function(self, event, player, data)
	end
}

---------------------------------------------------------------------------------------------------------------------------------------MaribelHearn
TH_yuezhiyaoniao = sgs.CreateTriggerSkill{--月之妖鸟
	name = "TH_yuezhiyaoniao",
	events = {sgs.DrawNCards},
	frequency = sgs.Skill_Compulsory,
	priority = -3,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		local num = draw.num
		local meiris = room:findPlayersBySkillName(self:objectName())
		if meiris:isEmpty() then return end
		for _, meiri in sgs.qlist(meiris) do
			if meiri:getHandcardNum() < player:getHandcardNum() + player:getHp() then
				meiri:drawCards(1)
			end
			if num > 0 then
				local cardids = room:getNCards(num, true)
				local cardstr
				for _, id in sgs.qlist(cardids) do
					if id >= 0 then
						if cardstr then
							cardstr = cardstr.."-"..id
						else
							cardstr = id
						end
					end
				end
				local newdata = sgs.QVariant(cardstr)
				room:fillAG(cardids, meiri)
				local choice = room:askForChoice(meiri, self:objectName(), "TH_yuezhiyaoniao_obtain+TH_yuezhiyaoniao_dis", newdata)
				room:clearAG(meiri)
				if choice == "TH_yuezhiyaoniao_dis" then
					local move = sgs.CardsMoveStruct()
					move.card_ids = cardids
					move.to_place = sgs.Player_DiscardPile
					move.reason.m_reason = sgs.CardMoveReason_S_REASON_PUT
					room:moveCardsAtomic(move, true)
				else
					for _, cardid in sgs.qlist(cardids) do
						local card = sgs.Sanguosha:getCard(cardid)
						if not card:hasFlag("visible") then
							local flag = string.format("%s_%s_%s", "visible", meiri:objectName(), player:objectName())
							room:setCardFlag(cardid, flag, meiri)
						end
					end
					local move = sgs.CardsMoveStruct()
					move.card_ids = cardids
					move.to_place = sgs.Player_PlaceHand
					move.to = player
					move.reason.m_reason = sgs.CardMoveReason_S_REASON_DRAW
					room:moveCardsAtomic(move, false)
					draw.num = 0
					data:setValue(draw)
					num = 0
				end
			end
		end
	end
}

TH_huamaozhihuan = sgs.CreateTriggerSkill{--化猫之幻
	name = "TH_huamaozhihuan",
	events = {sgs.CardResponded, sgs.CardUsed},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card
		if event == sgs.CardResponded then
            card = data:toCardResponse().m_card
        else
            card = data:toCardUse().card
		end
		if card and (card:isKindOf("Slash") or card:isKindOf("Jink")) then
			if not room:askForSkillInvoke(player, self:objectName()) then return false end
			if card:isKindOf("Jink") then
				for _, cardid in sgs.qlist(room:getDiscardPile()) do
					local card = sgs.Sanguosha:getCard(cardid)
					if card:isKindOf("Slash") then
						player:obtainCard(card)
						break
					end
				end
			else
				for _, cardid in sgs.qlist(room:getDiscardPile()) do
					local card = sgs.Sanguosha:getCard(cardid)
					if card:isKindOf("Jink") then
						player:obtainCard(card)
						break
					end
				end
			end
		end
	end
}

TH_mifengCARD = sgs.CreateSkillCard{--密封
	name = "TH_mifengCARD",
	skill_name = "TH_mifeng",
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(targets[1], "TH_mifeng_target")
		room:setPlayerFlag(targets[1], "TH_mifeng_"..source:objectName())
		room:setPlayerMark(targets[1], "&TH_mifeng+to+#"..source:objectName().."-SelfClear", 1)
	end
}

TH_mifengVS = sgs.CreateViewAsSkill{--密封
	name = "TH_mifeng",
	n = 2,
	view_filter = function(self, selected, to_select)
		return #selected < 2 and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local card = TH_mifengCARD:clone()
			card:addSubcard(cards[1])
			card:addSubcard(cards[2])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_mifengCARD")
	end,
}

TH_mifeng = sgs.CreateTriggerSkill{--密封
	name = "TH_mifeng",
	view_as_skill = TH_mifengVS,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start and player:hasFlag("TH_mifeng_target") then
			local room = player:getRoom()
			local cardid = room:drawCard()
			local move = sgs.CardsMoveStruct()
			move.card_ids:append(cardid)
			move.to_place = sgs.Player_PlaceTable
			move.reason.m_reason = sgs.CardMoveReason_S_REASON_TURNOVER
			room:moveCardsAtomic(move, true)
			local card = sgs.Sanguosha:getCard(cardid)
			local num = card:getNumber()
			if num >= 1 and num <= 5 then
				player:skip(sgs.Player_Draw)
			elseif num >= 6 and num <= 8 then
				player:skip(sgs.Player_Discard)
				for _, ap in sgs.qlist(room:getAlivePlayers()) do
					if player:hasFlag("TH_mifeng_"..ap:objectName()) then
						ap:drawCards(3)
					end
				end
			elseif num >= 9 and num<= 13 then
				player:skip(sgs.Player_Play)
			end
		end
	end
}

TH_bianshen_YakumoYukari = sgs.CreateTriggerSkill{--变身
	name = "#TH_bianshen_YakumoYukari",
	events = {sgs.GameStart},
	priority = 9,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if not player:hasFlag("TH_bianshen_MaribelHearn_used") and not player:hasFlag("TH_bianshen_YakumoYukari_used") and player:getGeneralName() == "MaribelHearn" then
			if not room:askForSkillInvoke(player, self:objectName()) then return end
			room:setPlayerFlag(player, "TH_bianshen_YakumoYukari_used")
			local maxhp = player:getMaxHp()
			room:changeHero(player, "YakumoYukari",true, true, false, true)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
			room:setPlayerProperty(player, "hp", sgs.QVariant(player:getMaxHp()))
		end
	end
}

---------------------------------------------------------------------------------------------------------------------------------------ToyosatomiminoMiko
TH_wuwuweizhong = sgs.CreateTriggerSkill{
	name = "TH_wuwuweizhong",
	events = {sgs.ChoiceMade, sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ChoiceMade then
		local str = data:toString()
		local invokestr = str:split(":")
		if invokestr[1] == "skillInvoke" and invokestr[2] ~= self:objectName() and invokestr[3] == "yes" then
			local mikos = room:findPlayersBySkillName(self:objectName())
			if mikos:length() > 0 then
				for _, miko in sgs.qlist(mikos) do
					if miko:getMark("TH_wuwuweizhongdraw") < 20 then
						miko:drawCards(1)
						room:addPlayerMark(miko,"TH_wuwuweizhongdraw",1)
						room:addPlayerMark(miko,"&TH_wuwuweizhong-Clear",1)
					end
				end
			end
		end
		elseif event == sgs.EventPhaseEnd then
			local phase = player:getPhase()
			if phase == sgs.Player_Finish then
				local mikos = room:findPlayersBySkillName(self:objectName())
				if mikos:length() > 0 then
					for _, miko in sgs.qlist(mikos) do
						room:setPlayerMark(miko,"TH_wuwuweizhongdraw",0)
					end
				end
			end
		end
	end
}

TH_jiushizhiguang = sgs.CreateTriggerSkill{
	name = "TH_jiushizhiguang",
	events = {sgs.AskForPeachesDone},
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local dying = data:toDying()
		if dying.who:getHp() > 0 then return end
		local room = player:getRoom()
		local mikos = room:findPlayersBySkillName(self:objectName())
		if mikos:isEmpty() then return end
		for _, miko in sgs.qlist(mikos) do
			if room:askForSkillInvoke(miko, self:objectName(),data) then
				room:loseMaxHp(dying.who)
				local re = sgs.RecoverStruct()
				for _, ap in sgs.qlist(room:getAlivePlayers()) do
					if ap:isWounded() then
						re.who = ap
						room:recover(ap, re, true)
					end
				end
			end
		end
	end
}

TH_shenlingdayuzhouCARD = sgs.CreateSkillCard{
	name = "TH_shenlingdayuzhouCARD",
	skill_name = "TH_shenlingdayuzhou",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		for _, ap in sgs.qlist(room:getOtherPlayers(source)) do
			if source:isDead() then return end
			local choice = room:askForChoice(ap, "TH_shenlingdayuzhou", "TH_givecard+TH_slashto")
			ap:drawCards(1)
			if choice == "TH_slashto" then
				local slash = room:askForUseSlashTo(ap, source, string.format("#TH_shenlingdayuzhou:%s",source:objectName()), false)
				if not slash then
					local da = sgs.DamageStruct()
					da.from = source
					da.to = ap
					da.nature = sgs.DamageStruct_Thunder
					room:damage(da)
				end
			else
				local card = ap:getRandomHandCard()
				TH_obtainCard(source, card, self:objectName())
			end
		end
	end
}

TH_shenlingdayuzhouVS = sgs.CreateViewAsSkill{
	name = "TH_shenlingdayuzhou",
	n = 3,
	view_filter = function(self, selected, to_select)
		return #selected < math.min(math.ceil(sgs.Self:aliveCount()/2), 3)
	end,
	view_as = function(self, cards)
		if #cards == math.min(math.ceil(sgs.Self:aliveCount()/2), 3) then
			local card = TH_shenlingdayuzhouCARD:clone()
			for _, acard in ipairs(cards) do
				card:addSubcard(acard)
			end
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_shenlingdayuzhouCARD")
			and (player:getCardCount(true) >= math.ceil(player:aliveCount()/2) or player:getCardCount(true) >= 3)
	end,
}

TH_shenlingdayuzhou = sgs.CreateTriggerSkill{
	name = "TH_shenlingdayuzhou",
	events ={sgs.NonTrigger},
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_shenlingdayuzhouVS,
	on_trigger = function(self, event, player, data)
	end
}

----------------------------------------------------------------------------------------------------------------------------magakireimu
TH_shenjiCARD = sgs.CreateSkillCard{
	name = "TH_shenjiCARD",
	skill_name = "TH_shenji",
	filter = function(self, targets, to_select)
		return to_select:getCardCount(true) > 0
	end,
	on_use = function(self, room, source, targets)
		local hcard, ecard
		if targets[1]:getHandcardNum() > 0 then
			hcard = room:askForCardChosen(source, targets[1], "h", self:objectName())
		end
		if targets[1]:getEquips():length() > 0 then
			ecard = room:askForCardChosen(source, targets[1], "e", self:objectName())
		end
		if hcard then source:addToPile("TH_shenji_pile", hcard, true) end
		if ecard then source:addToPile("TH_shenji_pile", ecard, true) end
	end
}

TH_shenjiVS = sgs.CreateViewAsSkill{
	name = "TH_shenji",
	n = 0,
	view_as = function(self, cards)
		return TH_shenjiCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_shenjiCARD")
	end
}

TH_shenji = sgs.CreateTriggerSkill{
	name = "TH_shenji",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	view_as_skill = TH_shenjiVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play and player:getPile("TH_shenji_pile"):length() > 0 then
			local room = player:getRoom()
			local move = sgs.CardsMoveStruct()
			move.card_ids = player:getPile("TH_shenji_pile")
			move.to_place = sgs.Player_PlaceHand
			move.to = player
			move.reason.m_reason = sgs.CardMoveReason_S_REASON_EXTRACTION
			room:moveCardsAtomic(move, false)
		end
	end
}

TH_huanghuoCARD = sgs.CreateSkillCard{
	name = "TH_huanghuoCARD",
	skill_name = "TH_huanghuo",
	filter = function(self, targets, to_select)
		return #targets < 1
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(targets[1], "TH_huanghuo_target")
		local lose
		if targets[1]:isWounded() then
			local ac = room:askForChoice(source, self:objectName(), "TH_huanghuo_addmax+TH_huanghuo_losemax")
			if ac == "TH_huanghuo_losemax" then
				room:loseMaxHp(targets[1])
				local re = sgs.RecoverStruct()
				re.who = targets[1]
				room:recover(targets[1], re, true)
				lose = true
			end
		end
		if not lose then
			room:loseHp(targets[1])
			room:setPlayerProperty(targets[1], "maxhp", sgs.QVariant(targets[1]:getMaxHp() + 1))
		end
		room:setPlayerFlag(targets[1], "TH_huanghuo_target")
	end
}

TH_huanghuo = sgs.CreateViewAsSkill{
	name = "TH_huanghuo",
	n = 0,
	view_as = function(self, cards)
		return TH_huanghuoCARD:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_huanghuoCARD")
	end
}

TH_zhongduotian = sgs.CreateTriggerSkill{
	name = "TH_zhongduotian",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			for _, ap in sgs.qlist(room:getOtherPlayers(player)) do
				if not ap:isKongcheng() and player:inMyAttackRange(ap) then
					local card = ap:getRandomHandCard()
					TH_logmessage("#TriggerSkill", ap, self:objectName())
					room:throwCard(card, ap, player)
					player:addMark("TH_zhongduotian_todraw")
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			player:drawCards(player:getMark("TH_zhongduotian_todraw"))
			room:setPlayerMark(player, "TH_zhongduotian_todraw", 0)
		end
	end
}

TH_sishen = sgs.CreateTriggerSkill{
	name = "#TH_sishen",
	events = {sgs.Dying, sgs.Death},
	priority = 5,
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Dying then
			local dying = data:toDying()
			if dying.who:objectName() == player:objectName() and dying.who:hasSkill(self:objectName()) and player:getMark("TH_sishen_used") < 1 then
				if player:getMark("changeHero_MagakiReimu") > 0 then player:removeMark("changeHero_MagakiReimu") return end
				TH_logmessage("#TriggerSkill", player, "TH_sishen")
				local num = player:getCardCount(true)
				player:throwAllHandCardsAndEquips()
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()*3))
				room:setPlayerProperty(player, "hp", sgs.QVariant(player:getMaxHp()))
				player:drawCards(num)
				room:setPlayerMark(player, "TH_sishen_used", 1)
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if not death.damage or not death.damage.from then return end
			if player:hasSkill(self:objectName()) and death.who:objectName() ~= player:objectName() and death.damage.from:objectName() == player:objectName() then
				TH_logmessage("#TriggerSkill", player, "TH_sishen")
				local choice = room:askForChoice(player, self:objectName(), "TH_sishen_skill+TH_sishen_recover", data)
				if choice == "TH_sishen_skill" then
					local skillslist
					for _,askill in sgs.qlist(death.who:getVisibleSkillList()) do
						if not askill:isLordSkill() then
							if not skillslist then
								skillslist = askill:objectName()
							else
								skillslist = skillslist.."+"..askill:objectName()
							end
						end
					end
					if skillslist then
						local skill = room:askForChoice(player, "TH_sishenskilllist", skillslist, data)
						room:acquireSkill(player, skill)
					end
				else
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
					local re = sgs.RecoverStruct()
					re.who = player
					room:recover(player, re, true)
				end
			end
		end
	end
}

-----★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
-----★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
TH_lordskill_subCARD = sgs.CreateSkillCard{
	name = "TH_lordskill_subCARD",
	skill_name = "TH_lordskill_sub",
	target_fixed = false,
	will_throw = true,
	feasible = function(self, targets)
		if sgs.Self:getKingdom() == "wei" or sgs.Self:getKingdom() == "shu" then
			return #targets == 1
		elseif sgs.Self:getKingdom() == "wu" then
			return #targets == 0
		else
			return #targets == 0
		end
	end,
	filter = function(self, targets, to_select)
		if sgs.Self:getKingdom() == "wei" then
			return #targets < 1 and not to_select:isLord() and to_select:objectName() ~= sgs.Self:objectName()
		elseif sgs.Self:getKingdom() == "shu" then
			return #targets < 1 and to_select:getCardCount(true) > 0 and not to_select:isLord() and to_select:objectName() ~= sgs.Self:objectName()
		elseif sgs.Self:getKingdom() == "wu" or sgs.Self:getKingdom() == "qun" then
			return false
		else
			return false
		end
	end,
	on_use = function(self, room, source, targets)
		local lord = room:getLord()
		if not lord or lord:isDead() then return end
		-- TH_logmessage("#TH_invoke_lordskill", source)
		if #targets > 0 then room:setPlayerFlag(targets[1], "TH_lordskill_target") end
		if (source:getKingdom() == "shu" or source:getKingdom() == "wei") and room:askForChoice(lord, "TH_invoke_lordskill", "yes+no") == "no" then return false end
		if source:getKingdom() == "wei" then
			if #targets > 0 then
				local da = sgs.DamageStruct()
				da.from = lord
				da.to = targets[1]
				room:damage(da)
			end
		elseif source:getKingdom() == "shu" then
			if #targets > 0 and targets[1]:getCardCount(true) > 0 then
				local cardid = room:askForCardChosen(lord, targets[1], "hej", self:objectName())
				if cardid then TH_obtainCard(lord, cardid, self:objectName()) end
			end
		elseif source:getKingdom() == "wu" then
			local x = lord:getLostHp()
			lord:drawCards(3 + x)
			local dis_num = math.min(1 + x, lord:getCardCount(true))
			if dis_num > 0 then
				room:askForDiscard(lord, self:objectName(),dis_num ,dis_num ,false, true)
			end
		elseif source:getKingdom() == "qun" then
			source:setFlags("TH_lordskill_exturn")
			TH_logmessage("#TH_lordskill_exturn", lord)
		else
			local choice = room:askForChoice(lord, "TH_lordskill_men", "TH_recover1+TH_draw2+TH_turnover")
			if choice == "TH_recover1" then
				local re = sgs.RecoverStruct()
				re.who = lord
				room:recover(lord, re, true)
			elseif choice == "TH_turnover" then
				lord:turnOver()
			else
				lord:drawCards(2)
			end
		end
		if #targets > 0 then room:setPlayerFlag(targets[1], "-TH_lordskill_target") end
	end,
}

TH_lordskill_subVS = sgs.CreateViewAsSkill{
	name = "TH_lordskill_sub",
	n = 2,
	view_filter = function(self, selected, to_select)
		if sgs.Self:getKingdom() == "wei" then
			return #selected < 1 and to_select:isBlack()
		elseif sgs.Self:getKingdom() == "shu" then
			return #selected < 1 and to_select:isRed()
		elseif sgs.Self:getKingdom() == "wu" then
			return #selected < 1 and to_select:isKindOf("BasicCard")
		elseif sgs.Self:getKingdom() == "qun" then
			if #selected == 0 then return true end
			if #selected > 0 then return to_select:getSuit() == selected[1]:getSuit() end
		else
			return #selected < 1
		end
	end,
	view_as = function(self, cards)
		if sgs.Self:getKingdom() == "qun" and #cards == 2 then
			local scard = TH_lordskill_subCARD:clone()
			scard:setSkillName(self:objectName())
			scard:addSubcard(cards[1])
			scard:addSubcard(cards[2])
			return scard
		elseif sgs.Self:getKingdom() ~= "qun" and #cards == 1 then
			local scard = TH_lordskill_subCARD:clone()
			scard:setSkillName(self:objectName())
			scard:addSubcard(cards[1])
			return scard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#TH_lordskill_subCARD")
	end,
}
TH_lordskill_sub = sgs.CreateTriggerSkill{
	name = "TH_lordskill_sub",
	events = { sgs.EventPhaseChanging },
	view_as_skill = TH_lordskill_subVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive and player:hasFlag("TH_lordskill_exturn") then
			local new_data = sgs.QVariant()
			new_data:setValue(room:getLord())
			room:setTag("TH_lordskill_exturn", new_data)
		end
	end
}

TH_lordskill = sgs.CreateTriggerSkill{
	name = "TH_lordskill$",
	events = { sgs.GameStart},
	frequency = sgs.Skill_Wake,
	priority = -4,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart and player:isLord() then
			if player:hasLordSkill(self:objectName()) and player:isLord() then
				if room:getMode():find("mini") or room:getMode():find("custom_scenario") then return end
				for _, ap in sgs.qlist(room:getOtherPlayers(player)) do
					room:attachSkillToPlayer(ap, "TH_lordskill_sub")
					-- room:detachSkillFromPlayer(ap, self:objectName())
				end
			end
		end
	end
}

TH_lordskill_exturn = sgs.CreateTriggerSkill{
	name = "#TH_lordskill_exturn",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,
	priority = -4,
	global = true,
	can_trigger = function(self, target)
		return target and target:getPhase() == sgs.Player_NotActive
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local tag = room:getTag("TH_lordskill_exturn")
		if tag then
			local target = tag:toPlayer()
			room:removeTag("TH_lordskill_exturn")
			if not target or target:isDead() then return end
			room:setPlayerFlag(target, "isExtraTurn")
			target:gainAnExtraTurn()
		end
	end
}

TH_askforkingdom = sgs.CreateGameStartSkill{
	name = "#TH_askforkingdom",
	frequency = sgs.Skill_Compulsory,
	on_gamestart = function(self, player)
		local room = player:getRoom()
		if room:getMode() == "mini" then return false end
		if room:getMode() == "02_1v1" then return false end
		if room:getMode() == "04_1v3" then return false end
		if room:getMode() == "06_XMode" then return false end
		if room:getMode() == "06_3v3" then return false end
		if room:getMode() == "custom_scenario" then return false end
		if player:getKingdom() == "TH_kingdom_baka" then return end
		if player:getState() == "robot" then
			local str = room:askForChoice(player,self:objectName(),"TH_cancel+wei+shu+wu+qun+TH_kingdom_baka+TH_kingdom_meng")
			if str == "TH_cancel" then
				return
			else
				room:setPlayerProperty(player, "kingdom", sgs.QVariant(str))
				TH_logmessage("#TH_playerkingdom",player,str)
			end
		else
			local kname = room:askForKingdom(player)
			room:setPlayerProperty(player, "kingdom", sgs.QVariant(kname))
			TH_logmessage("#ChooseKingdom", player, kname)
		end
	end
}


-----★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
TH_deathCARD = sgs.CreateSkillCard{
	name = "TH_deathCard",
	skill_name = "TH_death",
	on_use = function(self, room, source, targets)
		local damage = sgs.DamageStruct()
		damage.from = targets[1]
		room:killPlayer(targets[1], damage)
	end,
}

TH_death = sgs.CreateViewAsSkill{
	name = "TH_death",
	n = 0,
	view_as = function(self, cards)
		return TH_deathCard:clone()
	end,
}

---------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------
-- FlandreScarlet_Nos:addSkill(TH_mingke)
FlandreScarlet_Nos:addSkill(TH_sichongcunzai)
FlandreScarlet_Nos:addSkill(TH_cranberry)
FlandreScarlet_Nos:addSkill(TH_huanyue)
FlandreScarlet_Nos:addSkill(TH_huanyueTS)
extension:insertRelatedSkills("TH_huanyue", "#TH_huanyueTS")
FlandreScarlet_Nos:addSkill(TH_scarlet)
FlandreScarlet_Nos:addRelateSkill("TH_Laevatein")
FlandreScarlet_Nos:addRelateSkill("TH_qed")
FlandreScarlet_Nos:addRelateSkill("TH_huaidiao")
-- FlandreScarlet_Nos:addSkill(TH_fulanhandcard)

FlandreScarlet:addSkill(TH_Catadioptric)
-- FlandreScarlet:addSkill(TH_StarbowBreak)
FlandreScarlet:addSkill(TH_ForbiddenFruits)
FlandreScarlet:addSkill(TH_Sosite)

RemiliaScarlet:addSkill(TH_HeartBreak)
RemiliaScarlet:addSkill(TH_HeartBreak_effect)
RemiliaScarlet:addSkill(TH_ScarletDestiny)
RemiliaScarlet:addSkill(TH_ScarletDestiny_obtain)
RemiliaScarlet:addSkill(TH_ScarletShoot)
RemiliaScarlet:addSkill(TH_hongsebuyecheng)
extension:insertRelatedSkills("TH_ScarletDestiny", "#TH_ScarletDestiny_obtain")
extension:insertRelatedSkills("TH_HeartBreak", "#TH_HeartBreak_effect")

RemiliaScarlet_Nos:addSkill(TH_RemiliaStalker)
RemiliaScarlet_Nos:addSkill(TH_xingtai)
RemiliaScarlet_Nos:addSkill(TH_hongsehuanxiangxiang)
RemiliaScarlet_Nos:addSkill(TH_SpearTheGungnir)

IzayoiSakuya:addSkill(TH_TheWorld)
IzayoiSakuya:addSkill(TH_huanzang)
IzayoiSakuya:addSkill(TH_Eternal)
IzayoiSakuya:addSkill(TH_Sakuya)

HakureiReimu:addSkill(TH_wujiecao)
HakureiReimu:addSkill(TH_nafeng)
HakureiReimu:addSkill(TH_saiqianxiang)
HakureiReimu:addSkill(TH_bianshen_MagakiReimu)

KotiyaSanae:addSkill(TH_wugufengdeng)
KotiyaSanae:addSkill(TH_Miracle_GodsWind)
KotiyaSanae:addSkill(TH_Wonder_NwOBNS)

SaigyoujiYuyuko:addSkill(TH_chihuo)
SaigyoujiYuyuko:addSkill(TH_fanhundie)
SaigyoujiYuyuko:addSkill(TH_xixingyao)

KonpakuYoumu:addSkill(TH_erdaoliu)
KonpakuYoumu:addSkill(TH_rengui)

HouraisanKaguya:addSkill(TH_ShenbaoPLYZ)
HouraisanKaguya:addSkill(TH_YongyeguifanDaixiao)
HouraisanKaguya:addSkill(TH_YongyeguifanYongshiguangming)

HouraisanKaguya_Nos:addSkill(TH_nanti)
HouraisanKaguya_Nos:addSkill(TH_penglaiyuzhi)
HouraisanKaguya_Nos:addSkill(TH_yongyefan)
HouraisanKaguya_Nos:addSkill(TH_yongyefanTS)
extension:insertRelatedSkills("TH_yongyefan", "#TH_yongyefanTS")

YagokoroEirin:addSkill(TH_penglaizhiyao)
YagokoroEirin:addSkill(TH_LifeGame)
YagokoroEirin:addSkill(TH_sijianzhinao)
YagokoroEirin:addSkill(TH_yongye)

ReisenUdongeinInaba:addSkill(TH_yuetubingqi)
ReisenUdongeinInaba:addSkill(TH_huanlongyueni)
ReisenUdongeinInaba:addSkill(TH_xiepohuanjue)

FujiwaranoMokou:addSkill(TH_Phoenixrevive)
FujiwaranoMokou:addSkill(TH_fengyitianxiang)
FujiwaranoMokou:addSkill(TH_bumie)

Shikieiki:addSkill(TH_Guilty)
Shikieiki:addSkill(TH_shiwangshenpan)
Shikieiki:addSkill(TH_LastJudgement)

ShameimaruAya:addSkill(TH_wenwenxinwen)
ShameimaruAya:addSkill(TH_fengshenshaonv)
ShameimaruAya:addSkill(TH_fengshenshaonvdis)
ShameimaruAya:addSkill(TH_IllusionaryDominance)

KazamiYuuka:addSkill(TH_kaihua)
KazamiYuuka:addSkill(TH_huaniaofengyue)
KazamiYuuka:addSkill(TH_YuukaSama)

KirisameMarisa:addSkill(TH_bagualu)
KirisameMarisa:addSkill(TH_MasterSpark)
KirisameMarisa:addSkill(TH_thethiefmarisa)

KagiyamaHina:addSkill(TH_brokencharm)
KagiyamaHina:addSkill(TH_BadFortune)
KagiyamaHina:addSkill(TH_ExiledDoll)

YasakaKanako:addSkill(TH_MiracleofOtensui)
YasakaKanako:addSkill(TH_UnrememberedCrop)
YasakaKanako:addSkill(TH_MoutainOfFaith)
YasakaKanako:addSkill(TH_SanaeBuff1)

YakumoYukari:addSkill(TH_shengyusi)
YakumoYukari:addSkill(TH_sichongjiejie)
YakumoYukari:addSkill(TH_menghuanpaoying)
YakumoYukari:addSkill(TH_shishen)
YakumoYukari:addSkill(TH_bianshen_MaribelHearn)
YakumoRan:addSkill(TH_UnilateralContract)
YakumoChen:addSkill(TH_qimendunjia)

Cirno:addSkill(TH_PerfectMath)
Cirno:addSkill(TH_chao9)
Cirno:addSkill(TH_allbaka)

KomeijiSatori:addSkill(TH_ShyRose)
KomeijiSatori:addSkill(TH_Hypnosis)
KomeijiSatori:addSkill(TH_TerribleSouvenir)

KomeijiKoishi:addSkill(TH_RoseHell)
KomeijiKoishi:addSkill(TH_liandemaihuo)
KomeijiKoishi:addSkill(TH_wuyishi)

HoshigumaYuugi:addSkill(TH_huaimiepaohou)
HoshigumaYuugi:addSkill(TH_aoyi_sanbubisha)

ReiujiUtsuho:addSkill(TH_SubterraneanSun)
ReiujiUtsuho:addSkill(TH_Meltdown)
ReiujiUtsuho:addSkill(TH_Nuclear)
ReiujiUtsuho:addSkill(TH_BlazeGeyser)

KaenbyouRin:addSkill(TH_CatWalk)
KaenbyouRin:addSkill(TH_shitifanhuajie)
KaenbyouRin:addSkill(TH_ZombieFairy)
KaenbyouRin_zabingjia:addSkill(TH_GreatestCaution)
KaenbyouRin_zabingyi:addSkill(TH_GalacticIllusion)
KaenbyouRin_zabingbing:addSkill(TH_CosmicMarionnette)

PatchouliKnowledge:addSkill(TH_qiyaomofa)
PatchouliKnowledge:addSkill(TH_PhilosophersStone)

HinanawiTenshi:addSkill(TH_AllM)
HinanawiTenshi:addSkill(TH_tianjiedetaozi)
HinanawiTenshi:addSkill(TH_mshi)

NagaeIku:addSkill(TH_longyudianzuan)
NagaeIku:addSkill(TH_yuyiruokong)
NagaeIku:addSkill(TH_guanglongzhitanxi)
NagaeIku:addSkill(TH_longshendeshandian)

HoujuuNue:addSkill(TH_UndefinedAF)
HoujuuNue:addSkill(TH_hengong)
HoujuuNue:addSkill(TH_UndefinedUFO)

Nazrin:addSkill(TH_GreatestTreasure)
Nazrin:addSkill(TH_Detector)
Nazrin:addSkill(TH_NazrinPendulum)

TataraKogasa:addSkill(TH_UmbrellaCyclone)
TataraKogasa:addSkill(TH_demacia)
TataraKogasa:addSkill(TH_demaciags)
TataraKogasa:addSkill(TH_paratrooper)

HijiriByakuren:addSkill(TH_yinhexi)
HijiriByakuren:addSkill(TH_chaoren)
HijiriByakuren:addSkill(TH_chaoren_turn)
HijiriByakuren:addSkill(TH_moshenfusong)

IbukiSuika:addSkill(TH_suiyue)
IbukiSuika:addSkill(TH_sanbuhuaifei)
IbukiSuika:addSkill(TH_MissingPower)
IbukiSuika:addSkill(TH_jiu)

UsamiRenko:addSkill(TH_Science)
UsamiRenko:addSkill(TH_Unscientific)
UsamiRenko:addSkill(TH_MoreUnscientific)

MaribelHearn:addSkill(TH_yuezhiyaoniao)
MaribelHearn:addSkill(TH_huamaozhihuan)
MaribelHearn:addSkill(TH_mifeng)
MaribelHearn:addSkill(TH_bianshen_YakumoYukari)

ToyosatomiminoMiko:addSkill(TH_wuwuweizhong)
ToyosatomiminoMiko:addSkill(TH_jiushizhiguang)
ToyosatomiminoMiko:addSkill(TH_shenlingdayuzhou)

MagakiReimu:addSkill(TH_shenji)
MagakiReimu:addSkill(TH_huanghuo)
MagakiReimu:addSkill(TH_zhongduotian)
MagakiReimu:addSkill(TH_sishen)

-------------------------------------------------------------●●●●●●●●●●●●●●●●---------------------------------------------------------------------
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#TH_huimie") then skills:append(TH_huimie) end
if not sgs.Sanguosha:getSkill("TH_feixing") then skills:append(TH_feixing) end
if not sgs.Sanguosha:getSkill("TH_xixue") then skills:append(TH_xixue) end
if not sgs.Sanguosha:getSkill("TH_qed") then skills:append(TH_qed) end
if not sgs.Sanguosha:getSkill("TH_Laevatein") then skills:append(TH_Laevatein) end
if not sgs.Sanguosha:getSkill("TH_huaidiao") then skills:append(TH_huaidiao) end

-- if not sgs.Sanguosha:getSkill("#TH_HeartBreak_effect") then skills:append(TH_HeartBreak_effect) end
if not sgs.Sanguosha:getSkill("TH_LunaClock") then skills:append(TH_LunaClock) end
if not sgs.Sanguosha:getSkill("TH_3rdeye") then skills:append(TH_3rdeye) end
if not sgs.Sanguosha:getSkill("TH_DNA") then skills:append(TH_DNA) end
if not sgs.Sanguosha:getSkill("TH_AllMUser") then skills:append(TH_AllMUser) end
if not sgs.Sanguosha:getSkill("TH_death") then skills:append(TH_death) end
if not sgs.Sanguosha:getSkill("#TH_askforkingdom") then skills:append(TH_askforkingdom) end
if not sgs.Sanguosha:getSkill("TH_lordskill") then skills:append(TH_lordskill) end
if not sgs.Sanguosha:getSkill("TH_lordskill_sub") then skills:append(TH_lordskill_sub) end
if not sgs.Sanguosha:getSkill("#TH_lordskill_exturn") then skills:append(TH_lordskill_exturn) end

if not sgs.Sanguosha:getSkill("TH_Weapon_Laevatein") then skills:append(TH_Weapon_Laevatein_skill) end
if not sgs.Sanguosha:getSkill("TH_Weapon_SpearTheGungnir") then skills:append(TH_Weapon_SpearTheGungnir_skill) end
if not sgs.Sanguosha:getSkill("TH_Weapon_Feixiangjian") then skills:append(TH_Weapon_Feixiangjian_skill) end
if not sgs.Sanguosha:getSkill("TH_Weapon_BailouLouguan") then skills:append(TH_Weapon_BailouLouguan_skill) end
if not sgs.Sanguosha:getSkill("TH_Weapon_BailouLouguanTMS") then skills:append(TH_Weapon_BailouLouguanTMS) end
if not sgs.Sanguosha:getSkill("TH_Weapon_Penglaiyuzhi") then skills:append(TH_Weapon_Penglaiyuzhi_skill) end

extension:insertRelatedSkills("TH_lordskill", "#TH_lordskill_exturn")

sgs.Sanguosha:addSkills(skills)

function TH_kingdom()
	for _, touhougeneralname in ipairs(touhouGeneral) do
		local atouhougeneral = sgs.Sanguosha:getGeneral(touhougeneralname)
		if atouhougeneral then
			-- atouhougeneral:addSkill("#TH_askforkingdom")
			atouhougeneral:addSkill("TH_lordskill")
		end
	end
	-- local GeneralName = { "ReanSchwarzer", "AlisaReinford", "LauraSArseid", "FieClaussell", "EmmaMillstein", "SaraValestin", "MilliumOrion",
						-- "AngelicaRogner", "EliotCraig", "GaiusWorzel", "MachiasRegnitz", "JusisAlbarea", "CrowArmbrust" }
	-- for _, name in ipairs(GeneralName) do
		-- local general = sgs.Sanguosha:getGeneral(name)
		-- if general then
			-- general:addSkill("#TH_askforkingdom")
		-- end
	-- end
	-- local asuna = sgs.Sanguosha:getGeneral("YuukiAsuna")
	-- if asuna then asuna:addSkill("TH_lordskill") end
	-- local dc = sgs.Sanguosha:getGeneral("mushun")
	-- dc:addSkill("TH_sichongcunzai")
end
TH_kingdom()
----------------------------@@@@@@@@@@@@@@@--------------
sgs.LoadTranslationTable{
	["touhouproject"] = "lrl神的东方包",

	["TH_Weapon_Laevatein"] = "莱瓦汀",
	[":TH_Weapon_Laevatein"] = "装备牌·武器\
	攻击范围：2\
	技能效果：◆你使用【杀】【万箭齐发】【南蛮入侵】时，他的防具无效，并弃置该防具。◆<font color = 'gold'><b>芙兰朵露</b></font>，弃置其所有装备，若弃置了装备对其造成1点火焰伤害。",

	["TH_Weapon_SpearTheGungnir"] = "冈格尼尔",
	[":TH_Weapon_SpearTheGungnir"] = "装备牌·武器\
	攻击范围：5\
	技能效果：◆你使用【杀】时，可以令该角色不能使用【闪】响应此【杀】。◆<font color = 'gold'><b>蕾米莉亚</b></font>，造成伤害时他需弃置一张手牌。",

	["TH_Weapon_Penglaiyuzhi"] = "蓬莱玉枝",
	[":TH_Weapon_Penglaiyuzhi"] = "装备牌·武器\
	攻击范围：1\
	技能效果：◆每当你使用【杀】结算完成时摸1张牌。◆<font color = 'gold'><b>蓬莱山辉夜</b></font>，摸牌数为2张。",


	["TH_Weapon_BailouLouguan"] = "白楼剑楼观剑",
	[":TH_Weapon_BailouLouguan"] = "装备牌·武器\
	攻击范围：2\
	技能效果：◆每当你使用【杀】指定目标角色后，其需使用两张花色不同的【闪】才能抵消。◆<font color = 'gold'><b>魂魄妖梦</b></font>，可以指定一个额外的目标。",
	["TH_Weapon_BailouLouguan_first"] = "%src 对你使用【杀】，你需要打出二张花色不同的闪，请打出第一张【闪】",
	["TH_Weapon_BailouLouguan_second"] = "%src 对你使用【杀】，你需要打出二张花色不同的闪，请打出第二张【闪】",
	["$TH_Weapon_BailouLouguan"] = "%to 打出的 %card 无效。",

	["TH_Weapon_Feixiangjian"] = "绯想剑",
	[":TH_Weapon_Feixiangjian"] = "装备牌·武器\
	攻击范围：2\
	技能效果：◆你使用【杀】时可以声明一种颜色，改颜色的【闪】无效。◆<font color = 'gold'><b>比那名居天子</b></font>，声明颜色时，可以获得他一张该颜色的【闪】。",
	["red"] = "红色",
	["black"] = "黑色",
	["nosuit"] = "无色",
	["$TH_Weapon_Feixiangjian"] = "%to 打出的 %card 无效。",
	["#TH_Weapon_Feixiangjian_effect"] = "%from 发动<font color = 'gold'><b>【绯想剑】</b></font>选择的颜色是 %arg",

	["FlandreScarlet"] = "禁制-芙兰",
	["@FlandreScarlet"] = "東方project",
	["&FlandreScarlet"] = "禁制-芙兰",
	["#FlandreScarlet"] = "恶魔の妹",
	["TH_ForbiddenFruits"] = "禁忌·禁果",
	[":TH_ForbiddenFruits"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，失去一点体力，你可以选择最多3名其他角色从他们的区域里的一张牌。",
	["TH_Catadioptric"] = "禁弹·折反射",
	[":TH_Catadioptric"] = "当你即将受到连锁伤害时，可以将该伤害转移至其他角色，且该伤害+1。",
	["#TH_Catadioptric"] = "你可以选择一名其他角色，将伤害转移给他，且该伤害+1。",
	["TH_Sosite"] = "秘弹·之后...",
	["&TH_Sosite"] = "秘弹·之后...",
	[":TH_Sosite"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，你可以弃置X（任意数量）张牌，之后选择一名其他角色，你获得X枚“xx”标记，他需弃置X+1张牌",
	["#TH_Sosite"] = "<font color= 'red'>秘弹·之后...</font>你需要弃置 %arg 张牌",
	["#TH_Sosite_damage"] = "%from 触发 <font color= 'gold'><b>秘弹·之后...</b></font> 暴击效果，伤害从 %arg 增至 %arg2 ",

	["FlandreScarlet_Nos"] = "不死-芙兰",
	["@FlandreScarlet_Nos"] = "東方project",
	["&FlandreScarlet_Nos"] = "不死-芙兰",
	["#FlandreScarlet_Nos"] = "恶魔の妹",
	["TH_huanyue"] = "梦幻·幻月",
	[":TH_huanyue"] = "<font color= 'purple'><b>觉醒技</b></font>，若“禁忌.四重存在”效果判定失败，在你下个回合开始时：翻回正面，解除连锁，弃置判断区域的牌，体力上限增加3点；体力恢复满；\
	获得技能“禁忌.莱瓦汀”“坏掉”“QED.495年的波纹”；失去技能“禁忌.蔓越莓的陷阱”“禁忌.四重存在”。",
	["TH_qed"] = "QED.495年的波纹",
	[":TH_qed"] = "<font color = 'blue'><b>锁定技</b></font>，当场上的角色恢复体力时，你摸1张牌",
	["TH_sichongcunzai"] = "禁忌.四重存在",
	[":TH_sichongcunzai"] = "当你将受到伤害时进行一次判定，你获得判定牌，若判定结果不为<font color = 'red'>♦</font>该伤害无效。",
	["TH_cranberry"] = "禁忌.蔓越莓的陷阱",
	["TH_cranberry_turnover"] = "令伤害来源翻面",
	[":TH_cranberry"] = "因“禁忌.四重存在”效果判断失败而受到1点伤害时，你摸X张牌，可以让伤害来源翻面。（X为你的最大体力值）",
	["#TH_fulanhandcard"] = "手牌上限至少为4",
	["#TH_huimie"] = "毁灭",
	[":#TH_huimie"] = "<font color = 'blue'><b>锁定技</b></font>，距离-1,",
	["TH_scarlet"] = "真红",
	[":TH_scarlet"] = "<font color = 'blue'><b>锁定技</b></font>，你使用</b><font color = 'red'><b>红色【杀】</b></font>造成的伤害+1。",
	["TH_huaidiao"] = "坏掉",
	[":TH_huaidiao"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，你选择一名其他角色，他弃1张牌(没有则不弃)，视为角色对你使用一张【决斗】。",
	["TH_Laevatein"] = "禁忌.莱瓦汀",
	[":TH_Laevatein"] = "<font color = 'blue'><b>锁定技</b></font>，你的<font color = '#66ccff'><b>【杀】【大象】【乱射】</b></font>无视防具。",

	["RemiliaScarlet"] = "绯红-蕾米",
	["@RemiliaScarlet"] = "東方project",
	["&RemiliaScarlet"] = "绯红-蕾米",
	["#RemiliaScarlet"] = "永远的鲜红之幼月",
	["TH_HeartBreak"] = "必杀·碎心",
	["@TH_HeartBreak"] = "碎心",
	[":TH_HeartBreak"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名其他角色，直到你的回合结束前，体力回复效果对其无效。",
	["TH_ScarletDestiny"] = "绯色命运",
	[":TH_ScarletDestiny"] = "<font color = 'blue'><b>锁定技</b></font>，你判断区域的牌花色均视为<font color = 'red'>❤</font>，场上判定结束时，若判断牌为红色，你获得之。",
	["TH_ScarletShoot"] = "绯红之击",
	[":TH_ScarletShoot"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名有手牌的其他角色，他必须弃置所有红色手牌。",
	["TH_hongsebuyecheng"] = "红符·红色不夜城",
	[":TH_hongsebuyecheng"] = "<font color = 'blue'><b>锁定技</b></font>，每名角色的结束阶段开始时，他摸一张牌，若他的手牌不小于他的体力值，你获得他一张牌。",

	["RemiliaScarlet_Nos"] = "神枪-蕾米",
	["@RemiliaScarlet_Nos"] = "東方project",
	["&RemiliaScarlet_Nos"] = "神枪-蕾米",
	["#RemiliaScarlet_Nos"] = "永远的鲜红之幼月",
	["TH_RemiliaStalker"] = "浩劫杀阵",
	["TH_RemiliaStalker_discard"] = "你可以弃掉一张牌获得他张牌",
	[":TH_RemiliaStalker"] = "当你的【杀】被【闪】抵消时，可以弃1张牌，获得他1张牌。",
	["TH_feixing"] = "飞行",
	[":TH_feixing"] = "<font color = 'blue'><b>锁定技</b></font>，距离+1，-1。",
	["TH_xingtai"] = "形态切换",
	[":TH_xingtai"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，形态切换",
	["TH_hongsehuanxiangxiang"] = "红色幻想乡",
	[":TH_hongsehuanxiangxiang"] = "<font color = 'blue'><b>锁定技</b></font>，当你造成伤害时，你摸一张牌",
	["TH_SpearTheGungnir"] = "神枪.冈格尼尔",
	["TH_spearthegungnir"] = "神枪.冈格尼尔",
	[":TH_SpearTheGungnir"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，指定一名角色直到你下个回合开始阶段开始时，所有角色到该角色的距离为1。",
	["#TH_SpearTheGungnir"] = "所有角色到 %to 的距离被设定为1",
	["TH_xixue"] = "吸血",
	[":TH_xixue"] = "<font color = 'blue'><b>锁定技</b></font>，当你造成伤害时，你回复1体力",

	["IzayoiSakuya"] = "十六夜",
	["@IzayoiSakuya"] = "東方project",
	["#IzayoiSakuya"] = "红魔馆的女仆",
	["TH_TheWorld"] = "幻世·The World",
	["#TH_TheWorld"] = "幻世·The World",
	["@TH_theworld"] = "幻世·The World",
	[":TH_TheWorld"] = "<font color= 'red'><b>限定技</b></font>，出牌阶段，使所有其他角色呈翻面状态摸1张牌，你摸3张牌并获得技能“月时计”。",
	["TH_huanzang"] = "幻葬·夜雾中的幻影杀人鬼",
	[":TH_huanzang"] = "<font color = 'blue'><b>锁定技</b></font>，对距离1的角色使用【杀】时，此杀无法响应。",
	["TH_Eternal"] = "奇术·永恒的小刀",
	[":TH_Eternal"] = "当你的【杀】将造成伤害时，可以防止伤害，令该角色翻面，你摸1张牌。",
	["TH_Sakuya"] = "咲夜的世界",
	[":TH_Sakuya"] = "当你将受到伤害时，可以弃1张牌（若伤害来源为男性需为黑色牌，若为女性需为红色牌，若无伤害来源不限颜色）使伤害无效。",
	["TH_LunaClock"] = "月时计",
	["@TH_lunaclock"] = "月时计",
	[":TH_LunaClock"] = "<font color = 'blue'><b>锁定技</b></font>，你对处于翻面状态的角色造成伤害时，该伤害+1。",

	["HakureiReimu"] = "无节操灵梦",
	["@HakureiReimu"] = "東方project",
	["#HakureiReimu"] = "无节操",
	["TH_nafeng"] = "纳奉",
	["#TH_nafeng"] = "你们把节操交出来",
	["@TH_nafeng"] = "纳奉",
	[":TH_nafeng"] = "<font color='red'><b>限定技</b></font>，出牌阶段，你可从场上的其他角色的区域里获得1张牌（区域内必须有牌）。",
	["TH_wujiecao"] = "无节操",
	["#TH_wujiecao0"] = "%from仍掉了节操什么好处都没得到，摸了 <font color = 'gold'><b>0</b></font>张牌",
	["#TH_wujiecao1"] = "节操掉在地上",
	["#TH_wujiecao2"] = "节操什么的还是不要好了",
	[":TH_wujiecao"] = "摸牌阶段你摸的牌数为<b>【0-10】</b>的随机数。",
	["TH_saiqianxiang"] = "赛钱箱",
	[":TH_saiqianxiang"] = "<font color = 'blue'><b>锁定技</b></font>，手牌上限额外增加最大体体力值",

	["KotiyaSanae"] = "东风谷早苗",
	["@KotiyaSanae"] = "東方project",
	["#KotiyaSanae"] = "人妻",
	["TH_wugufengdeng"] = "神德·五谷丰登",
	[":TH_wugufengdeng"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，最多选择五名角色，从牌堆取出X张数的牌，依次选择1张牌，其余牌放入弃牌堆。（X为所选人数+2）",
	["TH_Wonder_NwOBNS"] = "奇迹·新星辉煌之夜",
	["TH_wonder_nwobns"] = "奇迹·新星辉煌之夜",
	[":TH_Wonder_NwOBNS"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名角色，在他的回合开始阶段开始时，你进行选择，①：他回复1点体力②：他受到1点伤害(无伤害来源)。",
	["#TH_nwobns"] = "<font color = 'gold'><b>奇迹·新星辉煌之夜</b></font> 效果将在 %from 的回合开始阶段开始时发动",
	["@TH_nwobns"] = "辉煌",
	["recoversb"] = "恢复1点体力",
	["damagesb"] = "受到1点伤害",
	["TH_Miracle_GodsWind"] = "奇迹·神之风",
	["@TH_godswind"] = "神之风",
	["#TH_godswind"] = "<font color = 'gold'><b>奇迹·神之风</b></font>效果将在 %from  的回合开始阶段开始时发动",
	[":TH_Miracle_GodsWind"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名角色，在他的回合开始阶段开始时，你进行选择，①：他摸2张牌②：他弃2张手牌。",
	["drawsb"] = "摸2张牌",
	["dissb"] = "弃2张手牌",

	["SaigyoujiYuyuko"] = "西行幽幽子",
	["@SaigyoujiYuyuko"] = "東方project",
	["#SaigyoujiYuyuko"] = "吃货",
	["TH_fanhundie"] = "反魂蝶",
	[":TH_fanhundie"]  = "<font color='red'><b>限定技</b></font>，出牌阶段，你可以选择一名其他角色，在你的第1个回合结束阶段他弃置1张手牌，第2个回合结束阶段他弃置2张手牌，\
	第3个回合结束阶段他受到1点伤害，第4个回合结束阶段他体力上限-1，受到1点伤害。★“反魂蝶”效果完成或被中断，在你的回合阶段结束时，你重新获得返魂蝶标记。",
	["#TH_fhd"]  = "%to 的<font color = 'gold'> <b>反魂蝶</b></font> 效果发动",
	["@TH_fanhundie"]  = "反魂蝶",
	["@TH_fhdonce"]  = "反魂蝶",
	["TH_chihuo"] = "吃货",
	[":TH_chihuo"]  = "可以把一张非基本牌当做桃来吃",
	["TH_xixingyao"] = "西行妖",
	[":TH_xixingyao"]  = "反魂蝶的效果储存在西行妖上，出牌阶段你可以查看这些效果，可以选择【确定】获得这些效果。",
	["#TH_xixingyaomessage1"]  = "你可以增加 %arg 点体力上限，恢复 %arg2 点体力 ",
	["#TH_xixingyaomessage2"]  = "你可以摸 %arg 张牌。",

	["KonpakuYoumu"] = "魂魄妖梦",
	["@KonpakuYoumu"] = "東方project",
	["&KonpakuYoumu"] = "魂魄妖梦",
	["#KonpakuYoumu"] = "半人半灵",
	["TH_rengui"]= "人鬼·未来永劫斩",
	[":TH_rengui"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名其他角色，翻开牌堆顶部5张牌，对每张牌进行判定，如果是【桃】他体力上限-1，目标如果是【杀】对他造成1点伤害；如果是【闪】他弃掉1张手牌(如果有手牌），你摸1张牌。",
	["TH_erdaoliu"]= "二刀流",
	[":TH_erdaoliu"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，可以将一张手牌当成【杀】对攻击范围内的1个角色打出。★当要求你打出【杀】时也可以响应。",
	["TH_erdaoliuCARD"] = "二刀流",
	["#TH_edl"] = "%from 打出【<font color = 'yellow'><b>杀[无色]</b></font>】目标是 %to",

	["HouraisanKaguya"] = "辉夜-旧",
	["@HouraisanKaguya"] = "東方project",
	["#HouraisanKaguya"] = "永远与须臾的罪人",
	["TH_ShenbaoPLYZVS"] = "神宝·蓬莱玉枝",
	[":TH_ShenbaoPLYZVS"] = "神宝·蓬莱玉枝",
	["TH_YongyeguifanDaixiao"] = "永夜归返·待宵",
	[":TH_YongyeguifanDaixiao"] = "永夜归返·待宵",
	["@TH_YongyeguifanDaixiao"] = "永夜归返·待宵",
	["#TH_YongyeguifanDaixiao"] = "选择 %arg 的手牌交给<font color = 'yellow'><b>蓬莱山辉夜</b></font>",
	["TH_YongyeguifanYongshiguangming"] = "永夜归返·永世光明",
	[":TH_YongyeguifanYongshiguangming"] = "永夜归返·永世光明",

	["HouraisanKaguya_Nos"] = "辉夜",
	["@HouraisanKaguya_Nos"] = "東方project",
	["&HouraisanKaguya_Nos"] = "辉夜",
	["#HouraisanKaguya_Nos"] = "永远与须臾的罪人",
	["TH_yongyefan"] = "永夜返",
	["#TH_yongyefanTS"] = "永夜返",
	[":TH_yongyefan"] = "<font color = 'blue'><b>锁定技</b></font>，每当你的回合开始时，体力和体力上限重置为4点。身份为公主时+1。",
	["#TH_yongyefan"] = "%arg 的效果发动，%from 的体力上限和体力重置为 %arg2 。",
	["TH_nanti"] = "辉夜的难题",
	["TH_nantisuicide"] = "辉夜的难题",
	[":TH_nanti"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名其他角色，展示牌堆顶部1张牌，你选择：①让他打出一张与展示牌花色样的牌，②让他打出一张点数比展示牌大的牌，\
	③让他打出一张比展示牌点数小的牌，④打出1张装备牌，⑤让他自杀？",
	["TH_penglaiyuzhi"] = "蓬莱玉枝",
	["TH_penglaiyuzhiCARD"] = "蓬莱玉枝",
	[":TH_penglaiyuzhi"] = "出牌阶段，可以将手上任意数量的基本牌，当做【光】置于蓬莱玉枝上，可以一次移除7个【光】，使你摸牌阶段摸牌数永久+1。",
	["TH_lightpile"] = "光",
	["nantisuit"] = "让它从手牌打出1张与展示牌花色样的牌",
	["nantibig"] = "让它从手牌打出1张点数比展示牌大的牌",
	["nantismall"] = "让它从手牌打出1张点数比展示牌小的牌",
	["nantiequip"] = "打出1张装备牌(包括已装备)",
	["nantisuicide"] = "让他自杀?",
	["@TH_nanti1"]= "从手牌打出1张与展示牌花色样的牌。",
	["@TH_nanti2"] = "从手牌打出1张点数比展示牌大的牌",
	["@TH_nanti3"] = "从手牌打出1张点数比展示牌小的牌",
	["@TH_nanti4"] = "打出1张装备牌(包括已装备)",
	["suicideyes"] = "自杀",
	["suicideno"] = "顽抗到底",
	["#suicideno"] = "%to 表示要顽抗到底",

	["YagokoroEirin"] = "八意永琳",
	["@YagokoroEirin"] = "東方project",
	["#YagokoroEirin"] = "月之头脑",
	["TH_penglaizhiyao"] = "禁药·蓬莱之药 ",
	[":TH_penglaizhiyao"] = "从游戏开始时计算，你每4个回合的回合开始，获得一瓶“禁药·蓬莱之药”。出牌阶段1次，使一名角色体力和体力上限+1。",
	["#penglaizhiyao"] = "%from 制作了1瓶 “禁药·蓬莱之药” ",
	["#penglaizhiyao_use"] = "%to 体力上限、体力+1。",
	["TH_LifeGame"] = "生命游戏",
	[":TH_LifeGame"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，指定一名其他角色，从摸牌堆顶部翻出1张牌进行判定，该角色获得判定牌。\
	①点数为<b>1~6</b>对该角色造成1点伤害。②点数为<b>7~12</b>对该角色造成一点伤害，你获得该角色1张牌。③点数为<b>13</b>该角色体力恢复至最大值。",
	["TH_sijianzhinao"] = "思兼之脑",
	[":TH_sijianzhinao"] = "<font color = 'blue'><b>锁定技</b></font>，【乐不思蜀】【兵粮寸断】对你无效。",
	["TH_sijianzhinaoOLD"] = "思兼之脑",
	[":TH_sijianzhinaoOLD"] = "<font color = 'blue'><b>锁定技</b></font>，你不能成为【乐不思蜀】【兵粮寸断】的目标。",
	["#TH_sijianzhinao"] = "%from 触发 %arg ,%arg2 对其无效。",
	["TH_yongye"] = "永夜",
	[":TH_yongye"] = "距离+1，每损失1点体力距离+1。",
	["@TH_plzy1"] = "禁药·蓬莱之药1/4",
	["@TH_plzy2"] = "禁药·蓬莱之药2/4",
	["@TH_plzy3"] = "禁药·蓬莱之药3/4",
	["@TH_plzy"] = "禁药·蓬莱之药",

	["ReisenUdongeinInaba"]= "铃仙",
	["@ReisenUdongeinInaba"] = "東方project",
	["&ReisenUdongeinInaba"]= "铃仙",
	["#ReisenUdongeinInaba"]= "疯狂的月兔",
	["TH_xiepohuanjue"] = "胁迫幻觉",
	[":TH_xiepohuanjue"] = "当你装备武器使用【杀】时，可以额外指定2个攻击范围内的角色。",
	["TH_huanlongyueni"] = "幻胧月睨",
	[":TH_huanlongyueni"] = "每受到1点伤害，可以X牌。可以将这些牌分给任意角色。（X为摸装备区牌数+2）",
	["TH_yuetubingqi"] = "月兔兵器",
	[":TH_yuetubingqi"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，从牌堆随机展示4张牌，你获得其中的装备牌。若没有装备牌，你摸1张牌。"	,

	["FujiwaranoMokou"] = "藤原妹红",
	["@FujiwaranoMokou"] = "東方project",
	["#FujiwaranoMokou"] = "蓬莱之人形",
	["TH_fengyitianxiang"] = "凤翼天翔",
	[":TH_fengyitianxiang"] = "出牌阶段，可以从手牌弃置1张【火杀】，视为对除你外的全部角色使用【火杀】。",
	["TH_Phoenixrevive"] = "不死鸟重生",
	[":TH_Phoenixrevive"] = "在通常状态你濒死时，变为重生状态，体力上限设为3点，第4个回合开始阶段回到通常状态。每次重生在通常状态下的体力上限+1。",
	["#Phoenixrevive1"] = "%from <font color = '#66ccff'><b>重生完成，体力上限变为</b></font> %arg ",
	["#Phoenixrevive2"] = "%from <font color = '#66ccff'><b>为重生状态</b></font>",
	["TH_bumie"] = "不灭·不死鸟之尾",
	[":TH_bumie"] = "在你的回合开始阶段开始，当弃牌堆有4张或更多【火杀】时可以发动，弃掉全部张手牌及装备，失去5点体力，可以获得弃牌堆的【火杀】。★你获得除你以外，其他原因弃入弃牌堆的【火杀】。",

	["Shikieiki"] = "四季映姬",
	["@Shikieiki"] = "東方project",
	["#Shikieiki"] = "乐园的最高裁判长",
	["TH_shiwangshenpan"] = "十王审判",
	["TH_shiwangshenpanCARD"] = "十王审判",
	[":TH_shiwangshenpan"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择：①<font color = '#66ccff'><b>【罪】</b></font>最多的角色，获得他最多2张手牌，移除该角色的<font color = '#66ccff'><b>【罪】</b></font>。\
	②获得所有有<font color = '#66ccff'><b>【罪】</b></font>的角色1张手牌，手牌来源移除所有的<font color = '#66ccff'><b>【罪】</b></font>。",
	["TH_swsp_one"] = "【罪】最多的角色",
	["TH_swsp_all"] = "所有有【罪】的角色",
	["TH_LastJudgement"] = "最终审判",
	["#TH_LastJudgement"] = "<font color = 'gold'><b>%src</b></font>的改判回合，可以发动<font color = 'gold'><b>最终审判</b></font>来修改<font color = 'gold'><b>%dest</b></font>的<font color = 'gold'><b>%arg</b></font>判定。",
	["~TH_LastJudgement"] = "选择1张牌→点击<font color = '#66ccff'><b>确定</b></font>",
	[":TH_LastJudgement"] = "判定生效前，可以打出1张牌（包括装备）代替，摸1张牌",
	["TH_Guilty"] = "罪",
	["@TH_guilty"] = "罪",
	[":TH_Guilty"] = "<font color = 'blue'><b>锁定技</b></font>，当你在场上时，造成伤害的伤害来源获得一个<font color = '#66ccff'><b>【罪】</b></font>标记。★有<font color = '#66ccff'><b>【罪】</b></font>的角色对你造成伤害前，你必须获得他1张手牌，否则伤害无效。",

	["ShameimaruAya"] = "射命丸文",
	["@ShameimaruAya"] = "東方project",
	["#ShameimaruAya"] = "传统的幻想文库",
	["TH_IllusionaryDominance"] = "幻想风靡" ,
	[":TH_IllusionaryDominance"] = "<font color = 'blue'><b>锁定技</b></font>，当你造成伤害且体力值为1时，有60%几率追加1点伤害，体力每增加1点几率减少10%，最少20%。\
	当你受到到伤害时会使下一次<font color = '#66ccff'><b>幻想风靡</b></font>效果为必发，效果不叠加。" ,
	["#TH_IllusionaryDominance_success"] = "触发<font color = '#66ccff'><b>幻想风靡</b></font>",
	["#TH_IllusionaryDominance_mark"] = "<font color = '#66ccff'>%from 下一次造成伤害，%arg 为必发效果</font>",
	["TH_fengshenshaonv"] = "风神少女" ,
	[":TH_fengshenshaonv"] = "在你的开始阶段开始时，若你的判断区域有牌，你可以弃掉1张手牌，获得你的判定区域的1张牌。" ,
	["#TH_fengshenshaonvmessage"] = "<font color = '#66ccff'><b>%from 获得了判定区域的【%arg】</b></font>" ,
	["TH_wenwenxinwen"] = "文文新闻" ,
	["@TH_wenwenxinwen"] = "文文新闻" ,
	[":TH_wenwenxinwen"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，指定一名其他角色进行拼点。成功：①直到你的下个回合开始前，角色每次受到伤害需弃掉1张手牌，②视为你对他使用了【杀】。失败：你受到1点伤害。" ,
	["#TH_fengshenshaonvdis"] = "风神少女" ,
	[":TH_fengshenshaonvdis"] = "风神少女" ,

	["KazamiYuuka"] = "风见幽香",
	["@KazamiYuuka"] = "東方project",
	["#KazamiYuuka"] = "四季的鲜花之主 ",
	["TH_kaihua"] = "花符·幻想乡开花",
	["TH_flower"] = " 花",
	[":TH_kaihua"] = "<font color = 'blue'><b>锁定技</b></font>，当你的回合开始阶段开始时和回合结束阶段开始时，从牌堆顶取出1张牌置于你的武将牌上，称为【花】，最多10张。",
	["TH_huaniaofengyue"] = "幻想·花鸟风月、啸风弄月",
	["#TH_huaniaofengyue"] = "%from 弃掉了 %arg 张牌 ",
	[":TH_huaniaofengyue"] = "<font color = 'red'><b>①</b></font>出牌阶段，移除全部【花】，摸【花】数量/2(上取整)张牌。<font color = 'red'><b>②</b></font>其他角色因效果弃牌时，可以移除1张【花】摸弃牌数量+1张牌。",
	["TH_YuukaSama"] = "S",
	["TH_yuukasama"] = "S",
	["#TH_YuukaSama"] = "目标是 %to ",
	["#TH_YuukaSamaCARD"] = "%from 用锁链把 %to 绑起来了",
	[":TH_YuukaSama"] = "<font color = 'red'><b>①</b></font>出牌阶段，移除1张【花】,可以用锁链捆绑2个角色。<font color = 'red'><b>②</b></font>你对角色造成伤害时，可以用锁链捆绑角色，角色摸X(X为已损失体力)张牌，然后弃掉X-1张牌。",

	["KirisameMarisa"] = "大盗魔理沙",
	["@KirisameMarisa"] = "東方project",
	["#KirisameMarisa"] = "普通的魔法使",
	["TH_bagualu"] = "八卦炉",
	[":TH_bagualu"] = "<font color = 'blue'><b>锁定技</b></font>，在你的回合开始阶段开始时，你获得其他角色装备的【八卦阵】。",
	["TH_MasterSpark"] = "恋符·极限火花 ",
	["TH_MasterSparkEX"] = "恋符·极限火花EX",
	["@TH_MasterSpark"] = "弃掉1张与判定牌花色相同的手牌 ",
	[":TH_MasterSpark"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名其他角色，进行判定，弃1张与判定牌花色相同的手牌：对其造成1点伤害。★当你装备有【八卦阵】时可以弃掉【八卦阵】，效果改为减其1点体力上限。",
	["#TH_MasterSpark1"] = "Da☆Ze",
	["TH_thethiefmarisa"] = "大盗魔理沙",
	["#TH_thethiefmarisa"] = "<font color = '#66ccff'><b>%from偷走了重要的东西</b></font>",
	["#TH_thethiefmarisa1"] = "<font color = '#66ccff'><b>%from 似乎从 %to 那里偷走了重要的东西</b></font>",
	[":TH_thethiefmarisa"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，随机选出3个未登场的【东方幻想乡】角色并列出他们的技能列表，你获得选中的1个技能。★技能列表不包括一些不适合获得的技能，每次使用技能会移除已获得的技能。",

	["KagiyamaHina"] = "键山雏",
	["@KagiyamaHina"] = "東方project",
	["#KagiyamaHina"] = "转转",
	["TH_BadFortune"] = "厄符·噩运",
	["@TH_badfortune"] = "厄符·噩运",
	["#TH_BadFortune"] = "%from厄符·噩运%to",
	["#TH_BadFortune_draw"] = "%to %arg2效果，摸牌数减少%arg张",
	[":TH_BadFortune"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名其他角色，使他的下个摸牌阶段的摸牌数减少。",
	["TH_brokencharm"] = "疵痕·损坏的护身符",
	["#TH_brokencharm"] = "%arg 的效果， %to 将代替 %from 承受1点伤害伤害",
	["@TH_brokencharm"] = "损坏的护身符",
	[":TH_brokencharm"] = " <font color = 'blue'><b>锁定技</b></font>，当你只剩1张手牌时，会被强制弃掉，然后指定一名其他角色，你受到的1次伤害无效，伤害来源对该角色造成1点伤害。",
	["TH_ExiledDoll"] = "创符·流刑人偶",
	["#TH_ExiledDoll_message"] = "不是现在",
	["@TH_exileddoll"] = "创符·流刑人偶",
	[":TH_ExiledDoll"] = "<font color='red'><b>限定技</b></font>，★<b>发动的时机</b>：①出牌阶段，选择一名体力为1的角色。②当一名体力为1的角色受到伤害时。★<b>效果</b>：该角色获得3个流刑人偶，每当他受到伤害时，无效伤害，失去1个流刑人偶。",

	["YasakaKanako"] ="八坂神奈子",
	["@YasakaKanako"] = "東方project",
	["#YasakaKanako"] ="山丘与湖的化身",
	["TH_MiracleofOtensui"] = "天流·天水奇迹",
	["TH_miracleofotensui"] = "天流·天水奇迹",
	[":TH_MiracleofOtensui"] = "选择一名角色恢复1点体力，和角色处于连锁状态的其他角色也恢复1点体力。",
	["#TH_MiracleofOtensui"] = "%to 解除了连锁状态。",
	["TH_UnrememberedCrop"] = "遗忘之谷",
	["~TH_UnrememberedCrop"] = "点击技能->选择相应的数量的牌->选择角色",
	[":TH_UnrememberedCrop"] = "当你进入出牌阶段时，可以弃掉X（X最大为3，最小为1）张牌，选择一名体力值大于3-X的角色，直到你的出牌阶段结束前，角色失去所有技能。",
	["TH_MoutainOfFaith"] = "信仰之山",
	["@TH_faith"] = "信仰",
	[":TH_MoutainOfFaith"] = "<font color = 'blue'><b>锁定技</b></font>，场上的角色每次使用非延时锦囊时，你得到1个【信仰】标记。出牌阶段，可以移除5个【标记】，选择一名角色摸2张牌。",
	["TH_SanaeBuff1"] = "守矢神社",
	[":TH_SanaeBuff1"] = "<font color = 'blue'><b>锁定技</b></font>，<font color = '#3299cc'><b>东方谷早苗</b></font>在场，且为友方时。全技能效果提升。",

	["YakumoYukari"] = "八云紫",
	["@YakumoYukari"] = "東方project",
	["#YakumoYukari"] = "境界的妖怪",
	["#TH_bianshen_MaribelHearn"] = "变身",
	["TH_shengyusi"] = "结界·生与死的境界",
	[":TH_shengyusi"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择1张手牌，选择一名角色（不能是你的下1位角色），该角色与你下1位的角色交换位置，该角色受到1点伤害，摸X张牌（X为角色已损失的体力），设为背面朝上。",
	["#TH_shengyusi"] = "%to 与 %arg 交换了位置。",
	["TH_sichongjiejie"] = "境符·四重结界",
	[":TH_sichongjiejie"] = "你的回合开始时，你可以弃掉1张手牌将武将牌重置为正面",
	["TH_menghuanpaoying"] = "深弹幕结界-梦幻泡影-",
	[":TH_menghuanpaoying"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，若你已受伤，选择所有手牌，最多可以选择手牌数的角色，视为对他们使用了【杀】，每造成1点伤害摸1张牌。",
	["TH_shishen"] = "式神",
	[":TH_shishen"] = "召唤<font color = 'blue'><b>·八云蓝</b></font>或<font color = 'orange '><b>·橙</b></font>",
	["YakumoRan"] = "八云蓝",
	["#YakumoRan"] = "策士之九尾",
	["TH_UnilateralContract"] = "片面义务契约",
	[":TH_UnilateralContract"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名角色，告诉你一些信息。",
	["#TH_UnilateralContract_PA"] = "%to 手上有 %arg 张<font color = 'gold '><b>【桃】或【酒】</b></font>",
	["#TH_UnilateralContract_S"] = "%to 手上有 %arg 张<font color = 'gold '><b>【杀】</b></font>",
	["#TH_UnilateralContract_J"] = "%to 手上有 %arg 张<font color = 'gold '><b>【闪】</b></font>",
	["YakumoChen"] = "橙",
	["#YakumoChen"] = "凶兆的黑猫",
	["TH_qimendunjia"] = "奇门遁甲",
	[":TH_qimendunjia"] = "在卡牌的效果对你生效前，翻堆开牌顶牌进行判定，如果点数为2，4，8可以让卡牌的效果无效，如果是【防具牌】可以让卡的效果无效，卡的使用者受到该效果反噬。",

	["Cirno"] = "琪露诺",
	["@Cirno"] = "東方project",
	["#Cirno"] = "⑨",
	["TH_kingdom_baka"] = "⑨",
	[":TH_kingdom_baka"] = "你要变成笨蛋吗？",
	["@TH_baka"] = "⑨",
	["TH_PerfectMath"] = "完美算数教室",
	[":TH_PerfectMath"] = "<font color = 'blue'><b>锁定技</b></font>，你的手牌点数大于⑨的视为⑨。",
	["TH_chao9"] = "奥义·超⑨武神霸斩",
	["#TH_chao9_one"] = "<font color = '#66ccff'><b>超⑨武神霸斩</b></font>",
	["#TH_chao91"] = "奥义",
	["#TH_chao92"] = "超",
	["#TH_chao93"] = "⑨",
	["#TH_chao94"] = "武",
	["#TH_chao95"] = "神",
	["#TH_chao96"] = "霸",
	["#TH_chao97"] = "斩!",
	["#TH_chao99"] = "奥义·超⑨武神霸斩!",
	[":TH_chao9"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择手牌1或2张点数为⑨的牌，指定一名角色，摸3张牌置于桌面，每1张点数为⑨的牌成1点伤害。如果是选择2张点数为⑨的牌，在最后追加1点伤害。",
	["TH_allbaka"] = "笨蛋",
	["#TH_allbaka"] = "%to 变成笨蛋了",
	["#TH_allbaka_on"] = "<font color = '#66ccff'><b>你们都是笨蛋！</b></font>",
	[":TH_allbaka"] = "<font color = 'blue'><b>锁定技</b></font>，你对其他角色造成伤害时，他变成<font color = '#66ccff'><b>笨蛋</b></font>，你对笨蛋造成伤害後，摸X（X为伤害量）张牌。\
	★回合开始阶段开始时1次，场上存活的角色全是<font color = '#66ccff'><b>笨蛋</b></font>时你的体力上限和体力+1。",

	["KomeijiSatori"] = "古明地觉",
	["@KomeijiSatori"] = "東方project",
	["#KomeijiSatori"] = "连怨灵也为之所惧的少女",
	["TH_TerribleSouvenir"] = "恐怖的回忆",
	["@TH_terriblesouvenir"] = "恐怖的回忆",
	["TH_TerribleSouvenir_use"] = "【<font color = 'gold'><b>恐怖的回忆</b></font>】",
	["#TH_TerribleSouvenir_Record"] = "%to 的恐怖的回忆 %arg2 ：伤害来源 %from ，伤害 %arg 点。 ",
	["#TH_TerribleSouvenir_reappear"] = "恐怖的回忆 %arg ",
	["#TH_TerribleSouvenir_dis"] = "恐怖的回忆 %arg 无效",
	["#TH_TerribleSouvenir_remove"] = "%arg 清除",
	["@TH_TerribleSouvenir"] = "恐怖的回忆：请打出1张【杀】或【无懈可击】，否则<font color = 'gold'><b> %src </b></font>将对你造成<font color = 'red'><b> %arg </b></font>点伤害",
	[":TH_TerribleSouvenir"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，弃置1张手牌，选择一名其它角色。如果他在你的下个回合开始阶段开始前，受到任何伤害，在你的下个回合开始阶段开始时，他将再次受到这些伤害。\
	受到“恐怖的回忆”效果造成的伤害前，可以打出【杀】或【无懈可击】抵消每次将受到的伤害。",
	["TH_Hypnosis"] = "恐怖催眠术",
	["TH_Hypnosis_use"] = "【<font color = 'gold'><b>恐怖催眠术</b></font>】",
	[":TH_Hypnosis"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，弃置1张手牌，选择一名其他玩家获得他的牌，他摸X张牌。(X为你获得的牌数/2，向上取整）",
	["TH_3rdeye"] = "读心",
	[":TH_3rdeye"] = "<font color = 'blue'><b>锁定技</b></font>，场上的其他玩家在摸牌阶段结束时必须向你展示手牌。对古明地恋无效。",
	["TH_ShyRose"] = "害羞的蔷薇",
	[":TH_ShyRose"] = "当你被的基本牌或锦囊牌指定为目标后，你摸1张牌。如果是黑色牌，可以展示这张牌，要求卡牌的使用者弃掉1张手牌。",

	["KomeijiKoishi"] = "古明地恋",
	["@KomeijiKoishi"] = "東方project",
	["#KomeijiKoishi"] = "紧闭着的恋之瞳",
	["TH_DNA"] = "DNA的瑕疵",
	["#TH_DNA_Dis"] = "%from 弃置了全部【%arg】。",
	[":TH_DNA"] = "其他玩家进入出牌阶段时，翻开牌堆顶1张牌，该玩家弃置手中和装备区与判断牌类型相同的牌。",
	["TH_wuyishi"] = "无意识",
	[":TH_wuyishi"] = "摸牌阶段开始时，可以放弃摸牌，改为从向你展示弃牌堆顶部10张牌，最多选择其中3张牌。",
	["TH_liandemaihuo"] = "恋的埋火",
	[":TH_liandemaihuo"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择2名不同的角色，你们相互交换所有【手牌】【装备牌】,你X/2（双方交换数量之差，下取整）张牌。",
	["TH_RoseHell"] = "蔷薇地狱",
	["#TH_RoseHell_putback"] = "%from 的 %arg 张 <font color = 'black'><b>黑色</b></font> 手牌被放回牌堆顶",
	[":TH_RoseHell"] = "其他角色对你造成伤害时，可以让该角色把手中的【黑色牌】放回牌堆上，该角色受到X点伤害。（X为放回的牌数/2，向下取整）",

	["HoshigumaYuugi"] = "星熊勇仪",
	["@HoshigumaYuugi"] = "東方project",
	["#HoshigumaYuugi"] = "红色有角三倍速",
	["TH_huaimiepaohou"] = "坏灭咆吼",
	["TH_huaimiepaohouCARD"] = "坏灭咆吼",
	[":TH_huaimiepaohou"] = "你每受到1点伤害，使你在下个回合进入出牌阶段时摸1张牌。在该回合的出牌阶段，可以把牌全部视为【杀】，对其它角色任意出【杀】。",
	["TH_aoyi_sanbubisha"] = "奥义·三步必杀",
	["#TH_aoyi_sanbubisha"] = "四天王奥义·三步必杀",
	["#TH_aoyi_sanbubisha_fromto"] = "%from 的位置 %arg，%to的位置%arg2",
	["#TH_aoyi_sanbubisha_num"] = "展示的点数 %arg ，对应的位置 %arg2 ",
	["#TH_aoyi_sanbubisha_target"] = "%to 与 %from 交换位置 %arg",
	[":TH_aoyi_sanbubisha"] = "<font color = 'blue'><b>锁定技</b></font>，每当你用【杀】对其他角色造成伤害结算完成后。翻开牌顶1张牌，他与该点数对应的位置的角色交换位置（不包括你和他的位置），交换位置后他处于离你最远的位置，他立即死亡。\
	◆只在6人及6人以上发动死亡效果。◆在全体玩家数为奇数时，判定卡为红色才能发动死亡效果。",

	["ReiujiUtsuho"] = "灵乌路空",
	["@ReiujiUtsuho"] = "東方project",
	["#ReiujiUtsuho"] = "难以驾驭的神之火",
	["TH_BlazeGeyser"] = "核焰喷涌",
	[":TH_BlazeGeyser"] = "你的回合结束阶段结束时，你对你周围的2名角色造成1点火焰伤害，◆若他们都已死亡，技能不在发动。",
	["TH_Nuclear"] = "核弹",
	["@TH_nuclear"] = "Nuclear",
	["#TH_Nuclear_Countdown"] = "距离 <font color = 'gold'><b>【核弹】</b></font>命中目标还有 %arg 回合。",
	["#TH_Nuclear_damage"] = " <font color = 'gold'><b>【核弹】</b></font>击中 %to 。",
	["#TH_Nuclear_damages"] = "%from 周围的 %to 受到<font color = 'gold'><b>【核弹】</b></font> 的伤害。",
	["#TH_Nuclear_target"] = "CAUTION：<font color = 'gold'><b>核弹</b></font> 的目标的是 %from 所在的 %arg 号位置，需要 %arg2 回合。",
	["#TH_Nuclear_hit"] = "☢",
	[":TH_Nuclear"] = "出牌阶段，移除10个标记，选择一名其它角色所在的位置。在X（你与他的位置间格数，最小为1）回合后的回合开始阶段开始时，处于该位置角色受到他体力值的伤害。并对他周围2格内的其它角色造成1点伤害。\
	◆死亡角色仍然计算位置。◆核弹命中的位置为发动技能时所选的位置。",
	["TH_Meltdown"] = "地狱极乐熔毁",
	["#TH_Meltdown"] = "<font color = 'gold'><b>灵乌路空</b></font> 触发【地狱极乐熔毁】，弃掉1张手牌",
	[":TH_Meltdown"] = "<font color = 'blue'><b>锁定技</b></font>，场上其它玩家受到火焰伤害时，需弃掉1张手牌",
	["TH_SubterraneanSun"] ="地底的太阳",
	[":TH_SubterraneanSun"] ="<font color = 'blue'><b>锁定技</b></font>，你造成的伤害时，该伤害变为火焰伤害。场上所有火焰伤害结算完成后，你得到1个标记。",

	["KaenbyouRin"] ="火焰猫",
	["@KaenbyouRin"] = "東方project",
	["#KaenbyouRin"] ="地狱的车祸",
	["TH_shitifanhuajie"] ="尸体繁华街",
	[":TH_shitifanhuajie"] ="摸牌阶段你的摸牌数+X/2。◆X为场上已死亡的玩家数量，向下取整。",
	["TH_CatWalk"] ="猫的步伐",
	["TH_CatWalk:jink"] ="是否发动 <font color = 'gold'><b>“猫的步伐”</b></font> ",
	["TH_CatWalk:slash"] ="是否发动 <font color = 'gold'><b>“猫的步伐”</b></font> ",
	[":TH_CatWalk"] ="当你需要使用或打出一张【杀】或【闪】时，你可以进行一次判定，若判定结果♣<font color = 'red'>♦</font>，则视为你使用或打出了一张【杀】或【闪】。",
	["TH_ZombieFairy"] ="丧尸妖精",
	["#TH_ZombieFairy_allalive"] ="都还活着呢，先杀掉个人把，哪怕是队友",
	["#TH_ZombieFairy_allzabing"] ="杂兵们都召唤在场上了。",
	["TH_ZombieFairy_summon"] ="召唤杂兵",
	["TH_ZombieFairy_unsummon"] ="解放杂兵",
	[":TH_ZombieFairy"] ="<font color= 'green'><b>出牌阶段限一次</b></font>，选择1具死亡角色的尸体，召唤【丧尸妖精】与你一起战斗。每次1只，每种限1只。",
	["KaenbyouRin_zabingjia"] ="杂兵甲",
	["&KaenbyouRin_zabingjia"] ="拉达曼迪斯",
	["#KaenbyouRin_zabingjia"] ="丧尸妖精",
	["TH_GreatestCaution"] ="灰暗警告冲击波",
	[":TH_GreatestCaution"] ="<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名其他玩家，你对他造成1点雷伤害。",
	["KaenbyouRin_zabingyi"] ="杂兵乙",
	["&KaenbyouRin_zabingyi"] ="艾亚哥斯",
	["#KaenbyouRin_zabingyi"] ="丧尸妖精",
	["TH_GalacticIllusion"] ="宇宙大幻觉",
	["#TH_GalacticIllusion"] ="%from 对 %to 造成 【<font color = 'yellow'><b>火杀[无色]</b></font>】 的效果",
	["TH_GalacticIllusionCARD"] ="宇宙大幻觉",
	[":TH_GalacticIllusion"] ="<font color= 'green'><b>出牌阶段限一次</b></font>，选择2名其他玩家，相互造成【火杀】的效果。",
	["KaenbyouRin_zabingbing"] ="杂兵丙",
	["&KaenbyouRin_zabingbing"] ="米诺斯",
	["#KaenbyouRin_zabingbing"] ="丧尸妖精",
	["TH_CosmicMarionnette"] ="星辰傀儡线",
	[":TH_CosmicMarionnette"] ="<font color= 'green'><b>出牌阶段限一次</b></font>，弃置2张手牌，选择一名其他玩家，令其翻面。必须间隔1回合才能选择再次选择该角色。",

	["PatchouliKnowledge"] = "帕秋莉",
	["@PatchouliKnowledge"] = "東方project",
	["&PatchouliKnowledge"] = "帕秋莉",
	["#PatchouliKnowledge"] = "不动的大图书馆",
	["TH_PhilosophersStone"] ="贤者之石",
	["TH_PhilosophersStone:slash"] ="是否发动 <font color = 'gold'><b>“贤者之石”</b></font>？",
	["TH_PhilosophersStone:jink"] ="是否发动 <font color = 'gold'><b>“贤者之石”</b></font>？",
	[":TH_PhilosophersStone"] ="★<font color= 'green'><b>出牌阶段限一次</b></font>，从摸牌堆顶摸最多2张非延时锦囊。★当你需要打出、使用【闪】或【杀】时，可以发动视为你打出【闪】或【杀】，每个角色的回合各1次，无法主动使用。",
	["TH_qiyaomofa"] ="七曜魔法",
	[":TH_qiyaomofa"] ="当你使用非延时锦囊结算完成时，可以选择1张手牌视为刚才使用的非延时锦囊使用。◆使用的对象与原来相同。",
	["#TH_qiyaomofa"] = "<font color = 'yellow'><b>七曜魔法</b></font> 的效果，你可以弃掉1张手牌，再次使用 <font color = 'yellow'><b>%src</b></font>",

	["HinanawiTenshi"] = "比那名居天子",
	["@HinanawiTenshi"] = "東方project",
	["#HinanawiTenshi"] = "M子",
	["TH_AllM"] ="全人类的M子",
	["TH_AllMUser"] ="全人类的M子",
	[":TH_AllMUser"] ="出牌阶段可以使用，如果【比那名居天子】选择【接受】，对他造成1点雷属性伤害，你摸2张牌。你每回合最多能使用X次。（X为他的最大体力值）",
	[":TH_AllM"] ="游戏开始时，其他角色获得技能【全人类的M子】，其他角色使用【全人类的M子】时，如果你选择【接受】你受到1点雷属性伤害，该角色摸2张牌。",
	["TH_tianjiedetaozi"] ="天界的桃子",
	[":TH_tianjiedetaozi"] ="<font color = 'blue'><b>锁定技</b></font>，当你的回复体力时，额外回复1点体力，不叠加。",
	["TH_mshi"] ="M",
	["TH_mshi"] ="M",
	["TH_mshiCARD"] ="M",
	[":TH_mshi"] ="★<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名其他玩家，将你和他捆绑，然后他对你造成1点雷属性伤害。<font color = 'blue'><b>锁定技</b></font>，当你受到属性伤害结算完成后，你摸1张牌，并可以将你和伤害来源捆绑。",
	["TH_M_yes"] ="√",
	["TH_M_no"] ="×",

	["NagaeIku"] = "永江衣玖",
	["@NagaeIku"] = "東方project",
	["#NagaeIku"] = "美丽的绯之衣",
	["TH_longyudianzuan"] = "龙鱼电钻",
	[":TH_longyudianzuan"] = "<font color = 'blue'><b>锁定技</b></font>，你对装备着【防具】的角色造成伤害时，追加1点雷属性伤害。",
	["TH_yuyiruokong"] = "羽衣若空",
	["@TH_yuyi"] = "雷",
	["#TH_yuyiruokong"] = "%from 即将受到伤害",
	["#TH_yuyiruokong1"] = "%from 即将受到伤害，发动<font color = 'yellow'><b>【羽衣若空】</b></font>，需要弃掉 %arg 张牌。",
	[":TH_yuyiruokong"] = "场上雷属性伤害命中时，可以弃掉1张牌，使该伤害无效，每点伤害你获得1个【雷】标记。◆如果你是该伤害的来源或伤害无来源，你不需弃掉牌。",
	["TH_guanglongzhitanxi"] = "光龙之叹息",
	["#TH_guanglongzhitanxi"] = "目标是 %to",
	[":TH_guanglongzhitanxi"] = "★当你造成伤害时可以移除2个标记，追加1点雷属性伤害。★当你的【雷】标记大于等于X时，可以移除X个【雷】标记，对其他角色各造成1点雷属性伤害。\
	◆X为场上存活角色的数量。\
	◆【光龙之叹息】造成伤害时不会触发【光龙之叹息】【羽衣若空】【龙鱼电钻】。",
	["TH_longshendeshandian"] = "龙神闪电",
	[":TH_longshendeshandian"] = "将1张手牌当做【闪电】打出，每次使用【闪电】获得1个【雷】标记。◆场上【闪电】的数量不少于场上存活玩家的数量时你不能使用此技能。",

	["HoujuuNue"] = "封兽鵺",
	["@HoujuuNue"] = "東方project",
	["#HoujuuNue"] = "未知幻想飞行少女",
	["TH_UndefinedAF"] = "正体不明·绝对领域",
	[":TH_UndefinedAF"] = "其他角色对你使用非延时类锦囊牌效果生效前，你摸1张牌，可以将这张牌的交给锦囊的使用者，使锦囊的效果对你无效。",
	["TH_UndefinedAFOLD"] = "正体不明·绝对领域",
	["#TH_UndefinedAFOLD"] = "正体不明·绝对领域",
	[":TH_UndefinedAFOLD"] = "其他角色使用【技能】【卡牌】时，1/3几率不能选择你做为目标。",
	["TH_hengong"] = "恨弓·源三位赖政之弓",
	["TH_hengong_selfdis"] = "自己弃掉1张手牌",
	["TH_hengong_otherdis"] = "其他玩家替你弃掉1张手牌",
	["#TH_hengong_otherdis"] = "你可以替杀的目标弃掉1张手牌。",
	[":TH_hengong"] = "★<font color= 'green'><b>出牌阶段限一次</b></font>，选择1张手牌，一名体力不大于所选牌点数的其他角色，对其造成1点伤害。★当你对其他角色使用【杀】时，\
	①距离为1时，获得他的武器，你没有武器则直接装备该武器。并且可以再次使用【恨弓·源三位赖政之弓】。②距离为2时，他或者其他角色替他弃掉1张手牌，否则他受到1点伤害。",
	["TH_UndefinedUFO"] = "正体不明·恐怖的UFO",
	["TH_undefinedufo"] = "正体不明·恐怖的UFO",
	[":TH_UndefinedUFO"] ="<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名其他角色，在你下个回合进入开始阶段时，与该角色下1位角色交换位置，回合结束后，将位置换回来。每次使用后，须间隔1回合才能再次使用。",

	["Nazrin"] = "娜兹玲",
	["@Nazrin"] = "東方project",
	["#Nazrin"] = "探宝的小小大将",
	["TH_GreatestTreasure"] = "无上至宝",
	[":TH_GreatestTreasure"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，将1张手牌当做顺手【牵羊使用】。◆你使用【顺手牵羊】时，选择的不是判断区域的牌，须再选择他1张牌，没有其他牌则不选。",
	["TH_Detector"] = "探测器",
	["#TH_Detector"] = "可以弃置一张点数<font color = 'gold'><b>%src</b></font>的牌，从弃牌堆中捡回1张【顺手牵羊】",
	[":TH_Detector"] = "摸牌阶段结束时，若弃牌堆有【顺手牵羊】，可以从手牌弃掉1张与【顺手牵羊】点数花色相同的牌，从弃牌堆捡回【顺手牵羊】。",
	["TH_nazrinpendulum"] = "娜兹玲的摆子",
	["TH_NazrinPendulum"] = "娜兹玲的摆子",
	["Slash"] = "杀",
	["Jink"] = "闪",
	["Peach"] = "桃",
	[":TH_NazrinPendulum"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，你选择从“杀，闪，桃”中选择，其它角色须弃置1张与你选择的牌名称相同的牌，没有则不弃。",

	["IbukiSuika"] = "伊吹萃香",
	["@IbukiSuika"] = "東方project",
	["#IbukiSuika"] = "百鬼夜行",
	["TH_suiyue"] = "碎月",
	["@TH_suiyue"] = "碎月",
	[":TH_suiyue"] = "<font color='red'><b>限定技</b></font>，播放《碎月》，增强战斗力！BGM结束前的3回合内有效。",
	["TH_jiu"] ="萃香专用酒",
	[":TH_jiu"] ="★<font color= 'green'><b>出牌阶段限一次</b></font>，当你没有使用过【酒】视为使用【酒】.★当你濒死时可以把1张手牌当做【酒】使用。◆每回合各限1次。",
	["TH_sanbuhuaifei"] = "奥义·三步坏废",
	[":TH_sanbuhuaifei"] = "你对目标使用【杀】时，翻开牌堆顶1张牌，若该牌点数与目标位置对应，目标弃掉全部牌。◆场上玩家至少6人，该技能才生效。",
	["TH_MissingPower"] ="鬼符·迷失之力",
	[":TH_MissingPower"] ="★你使用杀时，若目标的体力大于你的体力，此杀不可响应。★当你的体力不大于2时，可以将手牌中的【闪】当做【决斗】使用。",

	["TataraKogasa"] = "多多良小伞",
	["@TataraKogasa"] = "東方project",
	["#TataraKogasa"] = "德玛西亚小伞 ",
	["TH_demacia"] = "德玛西亚",
	["#TH_demacia"] = "<font color = 'gold'><b>德玛西亚</b></font>",
	["@TH_demacia"] = "草丛",
	[":TH_demacia"] = "游戏开始时，你获得1枚【草丛】标记。出牌阶段1次，弃置2张手牌，使你获得1枚【草丛】标记。最多只能拥有1枚【草丛】标记。其他玩家回合开始时，可以移除1枚【草丛】标记，让其武将牌翻面。",
	["TH_paratrooper"] = "伞符·伞兵突击",
	[":TH_paratrooper"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，你可以弃置1张装备牌，如果其他角色装备有此类装备，你对他造成1点伤害。其他角色更换装备时，你获得被换下的装备。",
	["TH_UmbrellaCyclone"] = "虹符·雨伞龙卷",
	["TH_UmbrellaCyclone"] = "虹符·雨伞龙卷",
	["@TH_Umbrella"] = "雨伞龙卷",
	["@TH_Umbrella_damage"] = "雨伞龙卷",
	[":TH_UmbrellaCyclone"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名其他玩家，获得任意数量的标记，他下次受到伤害时，增加标记数量的伤害。当你受到伤害时，每1点伤害可以获得1枚雨伞龙卷标记。",

	["HijiriByakuren"] = "圣白莲",
	["@HijiriByakuren"] = "東方project",
	["#HijiriByakuren"] = "被封印的大魔法使 ",
	["TH_moshenfusong"] = "魔神复诵",
	["@TH_moshenfusong"] = "魔神复诵",
	[":TH_moshenfusong"] = "<font color='red'><b>限定技</b></font>，任何一名角色濒死时，你可以让他满状态原地复活。",
	["TH_chaoren"] = "超人·圣白莲",
	[":TH_chaoren"] = "当【封印】的数量大于6时，可以从【封印】中移除7张牌，在你回合结束后，你进行1个额外的回合。",
	["TH_yinhexi"] = "魔法银河系",
	["TH_yinhexidiscard"] = "若封印未满，你可以选择溢出的手牌，将其交给<font color = '#66ccff'><b>圣白莲</b></font> ",
	["TH_yinhexi_askcard"] = "魔法银河系",
	["#TH_yinhexi_back"] = "选择手牌放回【封印】",
	["TH_yinhexi_pile"] = "封印",
	[":TH_yinhexi"] = "★<font color= 'green'><b>出牌阶段限一次</b></font>，可以选择任意张数的手牌，与【封印】的牌互换。★任何角色弃牌阶段开始时，可以将溢出的手牌置于你的武将牌上，称为【封印】，【封印】多于12张时，弃牌阶段时不再接受弃牌。\
	★任何1位角色出牌阶段开始时，若你同意，他可以从【封印】中选择最多2张牌。",

	["UsamiRenko"] = "宇佐见莲子",
	["@UsamiRenko"] = "東方project",
	["#UsamiRenko"] = "人体GPS",
	["TH_Science"] = "科学",
	[":TH_Science"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，指定一名其他角色，你和他各展示1张手牌，若你们展示的手牌花色不同，你获得他的展示牌，若相同他获得你的展示牌。",
	["TH_Unscientific"] = "这不科学",
	["#TH_Unscientific"] = "弃置1张花色为<font color = 'gold'><b>%src</b></font>的牌，否则你将受到1点伤害。",
	[":TH_Unscientific"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，指定一名其他角色，你向他展示1张手牌，他可以弃置1张与展示牌相同花色的牌，否则你对他造成1点伤害。",
	["TH_MoreUnscientific"] = "这更不科学",
	["#TH_MoreUnscientific"] = "弃置1张点数大于<font color = 'gold'><b>%src</b></font>的牌，否则你将受到1点伤害。",
	[":TH_MoreUnscientific"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，指定一名角色，从牌堆顶翻开2张牌，让他弃置1张点数比展示牌点数之和大的牌，否则你对他造成1点伤害。",

	["MaribelHearn"] = "玛艾露贝莉",
	["@MaribelHearn"] = "東方project",
	["&MaribelHearn"] = "梅莉",
	["#MaribelHearn"] = "阴阳眼魔术师",
	["TH_yuezhiyaoniao"] = "月之妖鸟",
	["TH_yuezhiyaoniao_dis"] = "将这些牌放入弃牌堆",
	["TH_yuezhiyaoniao_obtain"] = "他获得这些牌不再摸牌",
	[":TH_yuezhiyaoniao"] = "<font color = 'blue'><b>锁定技</b></font>，任意一名玩家摸牌阶段开始时，若你的手牌数小于他的手牌数与体力之和，你摸1张牌，然后你观看牌堆顶X张牌，选择：①他获得这些牌不再摸牌。②将这些牌放放入弃牌堆。◆X为他将摸牌的数量。",
	["TH_huamaozhihuan"] = "化猫之幻",
	[":TH_huamaozhihuan"] = "当你打出或使用【闪】时可以从弃牌堆获得1张【杀】，当你打出或使用【杀】时可以从弃牌堆获得1张【闪】",
	["TH_mifeng"] = "秘封",
	[":TH_mifeng"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，弃置2张手牌，指定一名角色翻开牌堆顶的牌进行判断，①点数<b>1-5</b>他跳过摸牌阶段，\
	②<b>6-8</b>他跳过弃牌阶段，你摸3张牌，③<b>9-13</b>他跳过出牌阶段。◆效果将在他的下个回合开始时生效。",
	["#TH_bianshen_YakumoYukari"] = "变身",

	["ToyosatomiminoMiko"] = "丰聪耳神子",
	["@ToyosatomiminoMiko"] = "東方project",
	["#ToyosatomiminoMiko"] = "圣徳道士",
	["TH_jiushizhiguang"] = "光符·救世之光",
	[":TH_jiushizhiguang"] = "场上的角色濒死求桃结束时，若他没有获得桃子，你可以让他体力上限-1，场上所以存活的角色恢复1点体力。",
	["TH_wuwuweizhong"] = "神光·无忤为宗",
	[":TH_wuwuweizhong"] = "<font color = 'blue'><b>锁定技</b></font>，每名角色的回合限20次，任何角色发触发效果选择确定发动时，你摸1张牌。",
	["TH_shenlingdayuzhou"] = "神灵大宇宙",
	["TH_slashto"] = "对她使用【杀】",
	["TH_givecard"] = "交给她1张手牌",
	["#TH_shenlingdayuzhou"] = "你可以对<font color = '#66ccff'><b> %src </b></font>打出1张【杀】，否则<font color = '#66ccff'><b> %src </b></font>将对你造成到1点伤害",
	[":TH_shenlingdayuzhou"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，可以弃置X（X为场上存活玩家数量，下取整，最大为3）张牌，让所有其他角色选择：①交给你1张手牌，②对你使用【杀】，如果他没有打出【杀】，你对他造成1点雷伤害。\
	◆其他角色在选择之后，先摸1张牌，再根据选择发动效果。",

	["MagakiReimu"] = "祸灵梦",
	["@MagakiReimu"] = "東方project",
	["#MagakiReimu"] = "祸美人",
	["TH_shenji"]  = "神忌",
	["TH_shenji_pile"]  = "神忌",
	[":TH_shenji"]  = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名其他角色，可以从他的手牌、装备牌中各选1张牌，将这些牌置于你的武将牌上。在你出牌阶段开始时，获得这些牌。",
	["TH_zhongduotian"] = "终堕天",
	[":TH_zhongduotian"] = "你的开始阶段开始时，处于你攻击范围内的角色须弃置1张牌，有角色因此效果弃牌时，在你的回合结束阶段开始时，你摸X张牌，X为该回合其他角色因此技能效果弃牌数量。",
	["TH_huanghuo"] = "皇祸",
	["TH_huanghuo_addmax"] = "增加1点体力上限，失去1点体力",
	["TH_huanghuo_losemax"] = "失去1点体力上限，恢复1点体力",
	[":TH_huanghuo"] = "<font color= 'green'><b>出牌阶段限一次</b></font>，选择一名角色，你选择①他体力减1点上限，恢复1点体力（他已受伤）。②他失去1点体力，限增加1点体力上限（他体力不小于1）。",
	["#TH_sishen"] = "死神",
	["TH_sishen"] = "死神",
	["TH_sishen_skill"] = "获得他1个技能",
	["TH_sishen_recover"] = "体力和体力上限+1",
	["TH_sishenskilllist"] = "请选择1个技能",
	[":#TH_sishen"] = "★你每杀死一名角色，你可以选择①获得他的1个技能，②你的体力和体力上限+1。★当你濒死时，仅1次，弃置全部手牌和装备牌，摸取等量的牌，体力上限增加2倍，体力恢复满。",

	["TH_lordskill"] = "卖萌",
	["TH_lordskill_subCARD"] = "卖萌",
	[":TH_lordskill"] = "<b>主公技</b>，根据其他角色的国籍产生不同的效果。",
	["TH_lordskill_sub"] = "卖萌",
	["TH_lordskill_men"] = "请选择",
	[":TH_lordskill_sub"] = "根据国籍，出牌阶段1次，不同效果。",
	["TH_invoke_lordskill"] = "正在进行回合的角色使用了技能【卖萌】，是否接受该效果？",
	-- ["#TH_invoke_lordskill"] = "%from 使用了技能<font color = 'gold'><b>【卖萌】</b></font>，是否接受该效果？",
	["#TH_lordskill_exturn"] = "%from 将获得1个额外的回合！",
	["TH_recover1"] = "恢复1点体力",
	["TH_draw2"] = "摸2张牌",
	["TH_turnover"] = "武将牌翻面",

	["TH_death"] = "禁止事项",
	["TH_deathCard"]= "禁止事项",
	[":TH_death"] = "禁止事项",
	["#TH_playerkingdom"] = "%from 选择的国籍是 %arg ",
	["#TH_askforkingdom"] = "选择的国籍",
	["TH_kingdom_meng"] = "萌",
	[":TH_kingdom_meng"] = "卖萌专用选项",
	["TH_cancel"] = "取消",
	[":TH_cancel"] = "取消",

	["TH_TestGeneral"] = "测试",

	["designer:FlandreScarlet"] = "lrl026",
	["designer:FlandreScarlet_Nos"] = "lrl026",
	["designer:RemiliaScarlet"] = "lrl026",
	["designer:RemiliaScarlet_Nos"] = "lrl026",
	["designer:IzayoiSakuya"] = "lrl026",
	["designer:HakureiReimu"] = "lrl026",
	["designer:KotiyaSanae"] = "lrl026",
	["designer:SaigyoujiYuyuko"] = "lrl026",
	["designer:KonpakuYoumu"] = "lrl026",
	["designer:HouraisanKaguya"] = "lrl026",
	["designer:HouraisanKaguya_Nos"] = "lrl026",
	["designer:YagokoroEirin"] = "lrl026",
	["designer:ReisenUdongeinInaba"] = "lrl026",
	["designer:FujiwaranoMokou"] = "lrl026",
	["designer:Shikieiki"] = "lrl026",
	["designer:ShameimaruAya"] = "lrl026",
	["designer:KazamiYuuka"] = "lrl026",
	["designer:KirisameMarisa"] = "lrl026",
	["designer:KagiyamaHina"] = "lrl026",
	["designer:YasakaKanako"] = "lrl026",
	["designer:YakumoYukari"] = "lrl026",
	["designer:YakumoRan"] = "lrl026",
	["designer:YakumoChen"] = "lrl026",
	["designer:Cirno"] = "lrl026",
	["designer:KomeijiSatori"] = "lrl026",
	["designer:KomeijiKoishi"] = "lrl026",
	["designer:HoshigumaYuugi"] = "lrl026",
	["designer:ReiujiUtsuho"] = "lrl026",
	["designer:KaenbyouRin"] = "lrl026",
	["designer:PatchouliKnowledge"] = "lrl026",
	["designer:HinanawiTenshi"] = "lrl026",
	["designer:NagaeIku"] = "lrl026",
	["designer:HoujuuNue"] = "lrl026",
	["designer:Nazrin"] = "lrl026",
	["designer:TataraKogasa"] = "lrl026",
	["designer:HijiriByakuren"] = "lrl026",
	["designer:UsamiRenko"] = "lrl026",
	["designer:MaribelHearn"] = "lrl026",
	["designer:IbukiSuika"] = "lrl026",
	["designer:ToyosatomiminoMiko"] = "lrl026",
	["designer:MagakiReimu"] = "lrl026",

	["illustrator:FlandreScarlet"] = "pixiv",
	["illustrator:FlandreScarlet_Nos"] = "pixiv",
	["illustrator:RemiliaScarlet"] = "pixiv",
	["illustrator:RemiliaScarlet_Nos"] = "pixiv",
	["illustrator:IzayoiSakuya"] = "pixiv",
	["illustrator:HakureiReimu"] = "pixiv",
	["illustrator:KotiyaSanae"] = "pixiv",
	["illustrator:SaigyoujiYuyuko"] = "pixiv",
	["illustrator:KonpakuYoumu"] = "pixiv",
	["illustrator:HouraisanKaguya_Nos"] = "pixiv",
	["illustrator:HouraisanKaguya"] = "pixiv",
	["illustrator:YagokoroEirin"] = "pixiv",
	["illustrator:ReisenUdongeinInaba"] = "pixiv",
	["illustrator:FujiwaranoMokou"] = "pixiv",
	["illustrator:Shikieiki"] = "pixiv",
	["illustrator:ShameimaruAya"] = "pixiv",
	["illustrator:KazamiYuuka"] = "pixiv",
	["illustrator:KirisameMarisa"] = "pixiv",
	["illustrator:KagiyamaHina"] = "pixiv",
	["illustrator:YasakaKanako"] = "pixiv",
	["illustrator:YakumoYukari"] = "pixiv",
	["illustrator:YakumoRan"] = "pixiv",
	["illustrator:YakumoChen"] = "pixiv",
	["illustrator:Cirno"] = "pixiv",
	["illustrator:KomeijiSatori"] = "pixiv",
	["illustrator:KomeijiKoishi"] = "pixiv",
	["illustrator:HoshigumaYuugi"] = "pixiv",
	["illustrator:ReiujiUtsuho"] = "pixiv",
	["illustrator:KaenbyouRin"] = "pixiv",
	["illustrator:PatchouliKnowledge"] = "pixiv",
	["illustrator:HinanawiTenshi"] = "pixiv",
	["illustrator:NagaeIku"] = "pixiv",
	["illustrator:HoujuuNue"] = "pixiv",
	["illustrator:Nazrin"] = "pixiv",
	["illustrator:TataraKogasa"] = "pixiv",
	["illustrator:HijiriByakuren"] = "pixiv",
	["illustrator:UsamiRenko"] = "pixiv",
	["illustrator:MaribelHearn"] = "pixiv",
	["illustrator:IbukiSuika"] = "pixiv",
	["illustrator:ToyosatomiminoMiko"] = "pixiv",
	["illustrator:MagakiReimu"] = "pixiv",

	["cv:FlandreScarlet"] = "暂无",
	["cv:FlandreScarlet_Nos"] = "暂无",
	["cv:RemiliaScarlet"] = "暂无",
	["cv:RemiliaScarlet_Nos"] = "暂无",
	["cv:IzayoiSakuya"] = "暂无",
	["cv:HakureiReimu"] = "暂无",
	["cv:KotiyaSanae"] = "暂无",
	["cv:SaigyoujiYuyuko"] = "暂无",
	["cv:KonpakuYoumu"] = "暂无",
	["cv:HouraisanKaguya"] = "暂无",
	["cv:HouraisanKaguya_Nos"] = "暂无",
	["cv:YagokoroEirin"] = "暂无",
	["cv:ReisenUdongeinInaba"] = "暂无",
	["cv:FujiwaranoMokou"] = "暂无",
	["cv:Shikieiki"] = "暂无",
	["cv:ShameimaruAya"] = "暂无",
	["cv:KazamiYuuka"] = "暂无",
	["cv:KirisameMarisa"] = "暂无",
	["cv:KagiyamaHina"] = "暂无",
	["cv:YasakaKanako"] = "暂无",
	["cv:YakumoYukari"] = "暂无",
	["cv:YakumoRan"] = "暂无",
	["cv:YakumoChen"] = "暂无",
	["cv:Cirno"] = "暂无",
	["cv:KomeijiSatori"] = "暂无",
	["cv:KomeijiKoishi"] = "暂无",
	["cv:HoshigumaYuugi"] = "暂无",
	["cv:ReiujiUtsuho"] = "暂无",
	["cv:KaenbyouRin"] = "暂无",
	["cv:PatchouliKnowledge"] = "暂无",
	["cv:HinanawiTenshi"] = "暂无",
	["cv:NagaeIku"] = "暂无",
	["cv:HoujuuNue"] = "暂无",
	["cv:Nazrin"] = "暂无",
	["cv:TataraKogasa"] = "暂无",
	["cv:HijiriByakuren"] = "暂无",
	["cv:UsamiRenko"] = "暂无",
	["cv:MaribelHearn"] = "暂无",
	["cv:IbukiSuika"] = "暂无",
	["cv:ToyosatomiminoMiko"] = "暂无",
	["cv:MagakiReimu"] = "暂无",

}