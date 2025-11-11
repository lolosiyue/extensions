--module("extensions.fixandadd", package.seeall)
--extension = sgs.Package("fixandadd")
extension = sgs.Package("fixandadd", sgs.Package_GeneralPack)
extension_guandu = sgs.Package("fixandadd_guandu", sgs.Package_GeneralPack)
hulaoguan_card = sgs.Package("hulaoguan_card", sgs.Package_CardPack)
extension_whlw = sgs.Package("extension_whlw", sgs.Package_GeneralPack)
extension_mobile = sgs.Package("extension_mobile", sgs.Package_GeneralPack)
extension_zlzy = sgs.Package("extension_zlzy", sgs.Package_GeneralPack)
extension_hulaoguan = sgs.Package("fixandadd_hulaoguan", sgs.Package_GeneralPack)
extension_twyj = sgs.Package("fixandadd_twyj", sgs.Package_GeneralPack)
extension_heg = sgs.Package("fixandadd_heg", sgs.Package_GeneralPack)
extension_dragonboat = sgs.Package("fixandadd_dragonboat", sgs.Package_GeneralPack)
extension_pray = sgs.Package("extension_pray", sgs.Package_GeneralPack)
extension_fengfangnu_e_card = sgs.Package("extension_fengfangnu_e_card", sgs.Package_CardPack)

shenlvbu2_2017_new = sgs.General(extension_hulaoguan, "shenlvbu2_2017_new", "god", 6, true)
shenlvbu2_2017_new:addSkill("mashu")
shenlvbu2_2017_new:addSkill("wushuang")
shenlvbu2_2017_new:addSkill("xiuluo")

shenwei_2017_new = sgs.CreateDrawCardsSkill{
	name = "shenwei_2017_new",
	frequency = sgs.Skill_Compulsory,
	draw_num_func = function(self, player, n)
		player:getRoom():sendCompulsoryTriggerLog(player, "shenwei_2017_new")
		player:getRoom():broadcastSkillInvoke(self:objectName(), math.random(1,2))
		return n + 3
	end
}
shenlvbu2_2017_new:addSkill(shenwei_2017_new)

--神威手牌上線修改
shenwei_2017_new_maxcards = sgs.CreateMaxCardsSkill{
	name = "shenwei_2017_new_maxcards",
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target, player)
		local n = 0
		if target:hasSkill("shenwei_2017_new") then
			n = n + 3
		end
		return n
	end
}

shenji_2017_new = sgs.CreateTargetModSkill{
	name = "shenji_2017_new",
	frequency = sgs.Skill_Compulsory,
	extra_target_func = function(self, from)
		if from:hasSkill(self:objectName()) and not from:getWeapon() then
			return 2
		end
		return 0
	end
}
shenlvbu2_2017_new:addSkill(shenji_2017_new)

--神戟殺次數修改
shenji_2017_new_slashmore = sgs.CreateTargetModSkill{
	name = "shenji_2017_new_slashmore",
	frequency = sgs.Skill_Compulsory,
	pattern = ".",
	residue_func = function(self, from, card)
		if card:isKindOf("Slash") then
			if from:hasSkill("shenji_2017_new") and not from:getWeapon() then
				return 1
			end
			return 0
		end
	end
}

--神戟技能配音
acquiring_audio = sgs.CreateTriggerSkill{
	name = "acquiring_audio",
	events = {sgs.PreCardUsed},
	global = true,
	priority = 1,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if player:hasSkill("shenji_2017_new") and use.card:isKindOf("Slash") then
				room:broadcastSkillInvoke("shenji_2017_new", math.random(1,2))
			end
		end
	end
}

--把神威手牌上線修改和神戟殺次數修改技能以隱藏方式加到所有武將, 加上配音修正技能
local shenlvbu2_skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("shenji_2017_new_slashmore") then shenlvbu2_skills:append(shenji_2017_new_slashmore) end
if not sgs.Sanguosha:getSkill("shenwei_2017_new_maxcards") then shenlvbu2_skills:append(shenwei_2017_new_maxcards) end
if not sgs.Sanguosha:getSkill("acquiring_audio") then shenlvbu2_skills:append(acquiring_audio) end
sgs.Sanguosha:addSkills(shenlvbu2_skills)


shenlvbuguitwentyeighteen = sgs.General(extension_hulaoguan, "shenlvbuguitwentyeighteen", "god", 6, true)
shenlvbuguitwentyeighteen:addSkill("wushuang")
shenlvbuguitwentyeighteen:addSkill("shenqu")
jiwuCard_2018_new = sgs.CreateSkillCard{
	name = "jiwu_2018_new",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choices = {"qiangxi", "tieji", "xuanfeng", "lua_wansha"}
		local copy = {"qiangxi", "tieji", "xuanfeng", "lua_wansha"}
		for i = 1, 4 do
			if source:hasSkill(choices[i]) then
				table.removeOne(copy, choices[i])
			end
		end
		if #copy > 0 then
			room:addPlayerMark(source, self:objectName().."engine")
			if source:getMark(self:objectName().."engine") > 0 then
				local choice = room:askForChoice(source, self:objectName(), table.concat(copy, "+"))
				room:acquireSkill(source, choice)
				room:addPlayerMark(source, choice.."_skillClear")
				room:removePlayerMark(source, self:objectName().."engine")
			end
		end
	end
}
jiwu_2018_new = sgs.CreateOneCardViewAsSkill{
	name = "jiwu_2018_new",
	filter_pattern = ".",
	view_as = function(self, card)
		local skill_card = jiwuCard_2018_new:clone()
		skill_card:addSubcard(card)
		skill_card:setSkillName(self:objectName())
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasSkill("qiangxi") or not player:hasSkill("tieji") or not player:hasSkill("xuanfeng") or not player:hasSkill("lua_wansha")
	end
}
shenlvbuguitwentyeighteen:addSkill(jiwu_2018_new)
shenlvbuguitwentyeighteen:addRelateSkill("qiangxi")
shenlvbuguitwentyeighteen:addRelateSkill("tieji")
shenlvbuguitwentyeighteen:addRelateSkill("lua_wansha")
shenlvbuguitwentyeighteen:addRelateSkill("xuanfeng")


imba_tunchuDisable = sgs.CreateTriggerSkill{
	name = "imba_tunchuDisable",
	global = true,
	priority = 10,
	events = {sgs.EventLoseSkill, sgs.EventAcquireSkill, sgs.CardsMoveOneTime, sgs.BeforeCardsMove},
	on_trigger = function(self, event, splayer, data, room)
		if event == sgs.EventLoseSkill and data:toString() == "imba_tunchu" then
			room:removePlayerCardLimitation(splayer, "use", "Slash$0")
		elseif event == sgs.EventAcquireSkill and data:toString() == "imba_tunchu" then
			if not splayer:getPile("food"):isEmpty() then
				room:setPlayerCardLimitation(splayer, "use", "Slash", false)
			end
		elseif splayer:isAlive() and splayer:hasSkill("imba_tunchu", true) then
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if move.to and move.to:objectName() == splayer:objectName() and move.to_place == sgs.Player_PlaceSpecial and move.to_pile_name == "food" then
					if splayer:getPile("food"):length() > 0 then
						room:setPlayerCardLimitation(splayer, "use", "Slash", false)
					end
				end
				if splayer:getTag(self:objectName()):toBool() then
					if splayer:getPile("food"):isEmpty() then
						room:removePlayerCardLimitation(splayer, "use", "Slash$0")
					end
					splayer:setTag(self:objectName(), sgs.QVariant(false))
				end
			elseif event == sgs.BeforeCardsMove then
				local move = data:toMoveOneTime()
				if move.from and move.from:objectName() == splayer:objectName() and move.from_places:contains(sgs.Player_PlaceSpecial) then
					if splayer:getPile("food"):length() > 0 then
						splayer:setTag(self:objectName(), sgs.QVariant(true))
					end
				end
			end
		end
		return false
	end
}

play_audio = sgs.CreateTriggerSkill{
	name = "play_audio",
	events = {sgs.EventPhaseProceeding},
	global = true,
	priority = -1,
	on_trigger = function(self, event, splayer, data, room)
		if splayer:getPhase() == sgs.Player_Discard then
			if splayer:hasSkill("new_juejing") then
				room:sendCompulsoryTriggerLog(splayer, "new_juejing")
				room:broadcastSkillInvoke("new_juejing")
			end
		end
	end
}

local skills = sgs.SkillList()

if not sgs.Sanguosha:getSkill("imba_tunchuDisable") then skills:append(imba_tunchuDisable) end
if not sgs.Sanguosha:getSkill("play_audio") then skills:append(play_audio) end


imba_lifeng = sgs.General(extension, "imba_lifeng", "shu", "3", true)
imba_tunchu = sgs.CreateTriggerSkill{
	name = "imba_tunchu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards, sgs.AfterDrawNCards},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DrawNCards then
			if player:getPile("food"):length() > 0 or not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			player:setTag(self:objectName(), sgs.QVariant(true))
			room:broadcastSkillInvoke(self:objectName())
			data:setValue(data:toInt() + 2)
		else
			if not player:getTag(self:objectName()):toBool() then return false end
			player:setTag(self:objectName(), sgs.QVariant(false))
			local cards = room:askForExchange(player, self:objectName(), 999, 1, false, "@imba_tunchu", true)
			if cards then
				player:addToPile("food", cards)
			end
		end
		return false
	end
}
imba_lifeng:addSkill(imba_tunchu)
imba_shuliangCard = sgs.CreateSkillCard{
	name = "imba_shuliang",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:throwCard(sgs.Sanguosha:getCard(self:getSubcards():first()), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", source:objectName(), self:objectName(), ""), nil)
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
imba_shuliangVS = sgs.CreateOneCardViewAsSkill{
	name = "imba_shuliang",
	response_pattern = "@@imba_shuliang",
	filter_pattern = ".|.|.|food",
	expand_pile = "food",
	view_as = function(self, card)
		local first = imba_shuliangCard:clone()
		first:addSubcard(card:getId())
		first:setSkillName(self:objectName())
		return first
	end,
	enabled_at_play = function(self, player)
		return false
	end
}
imba_shuliang = sgs.CreateTriggerSkill{
	name = "imba_shuliang",
	view_as_skill = imba_shuliangVS,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if player:getHp() > player:getHandcardNum() and p:getPile("food"):length() > 0
				and room:askForUseCard(p, "@@imba_shuliang", "@imba_shuliang", -1, sgs.Card_MethodNone) then
				room:addPlayerMark(p, self:objectName().."engine")
				if p:getMark(self:objectName().."engine") > 0 then
					room:doAnimate(1, p:objectName(), player:objectName())
					room:drawCards(player, 2, self:objectName())
					room:removePlayerMark(p, self:objectName().."engine")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getPhase() == sgs.Player_Finish
	end
}
imba_lifeng:addSkill(imba_shuliang)

baosanniang = sgs.General(extension_pray, "baosanniang", "shu", 3, false)
wuniang = sgs.CreateTriggerSkill{
	name = "wuniang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and card:isKindOf("Slash") and player:hasSkill(self:objectName()) then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not p:isNude() and p:objectName() ~= player:objectName() then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local target = room:askForPlayerChosen(player, players, self:objectName(), "wuniang-invoke", true, true)
				if target then
					local id = room:askForCardChosen(player, target, "he", self:objectName())
					room:obtainCard(player, id, false)
					target:drawCards(1)
					room:broadcastSkillInvoke(self:objectName())
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getGeneralName() == "guansuo" or p:getGeneral2Name() == "guansuo" then
							if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:"..p:getSeat())) then
								p:drawCards(1)
							end
						end
					end
				end
			end
		end
		return false
	end
}
baosanniang:addSkill(wuniang)
xushen = sgs.CreateTriggerSkill{
	name = "xushen",
	frequency = sgs.Skill_Limited,
	limit_mark = "@xushen",
	events = {sgs.TargetConfirmed, sgs.HpChanged, sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local source = data:toCardUse().from
			if source and source:isMale() and source:objectName() ~= player:objectName() and player:getHp() <= 0 and player:hasSkill(self:objectName()) then
				room:addPlayerMark(source, "xushen_healer")
			end
		elseif event == sgs.HpChanged then
			if player:getHp() < 1 and player:hasSkill(self:objectName()) then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("xushen_healer") > 0 then
						room:setPlayerMark(p, "xushen_healer", 0)
					end
				end
			end
		elseif event == sgs.AskForPeachesDone then
			local healer
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("xushen_healer") > 0 then
					healer = p
					room:removePlayerMark(p, "xushen_healer")
				end
			end
			local has_guansuo = false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getGeneralName() == "guansuo" or p:getGeneral2Name() == "guansuo"  then
					has_guansuo = true
				end
			end
			if not has_guansuo and healer and player:getMark("@xushen") > 0 and player:hasSkill(self:objectName()) then
				if room:askForSkillInvoke(healer, self:objectName(), data) then
					room:changeHero(healer, "guansuo", false, false)
					room:recover(player, sgs.RecoverStruct(player))
					room:acquireSkill(player, "zhennan")
					room:broadcastSkillInvoke(self:objectName())
					room:removePlayerMark(player, "@xushen")
				end
			end
		end
		return false
	end
}
baosanniang:addSkill(xushen)
zhennan = sgs.CreateTriggerSkill{
	name = "zhennan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("SavageAssault") and use.to and use.to:contains(player) and player:hasSkill(self:objectName()) then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "zhennan-invoke", true, true)
			if target then
				room:damage(sgs.DamageStruct(self:objectName(), player, target, math.random(1,3)))
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		return false
	end
}
baosanniang:addRelateSkill("zhennan")
if not sgs.Sanguosha:getSkill("zhennan") then skills:append(zhennan) end


luoshen_maxcards = sgs.CreateMaxCardsSkill{
	name = "luoshen_maxcards",
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target, player)
		if target:hasSkill("luoshen") then
			local luoshen_count = 0
			for _, card in sgs.list(target:getHandcards()) do
				if target:getMark("luoshen"..card:getId().."-Clear") > 0 then
					luoshen_count = luoshen_count + 1
				end
			end
			return luoshen_count
		end
		return 0
	end
}
if not sgs.Sanguosha:getSkill("luoshen_maxcards") then skills:append(luoshen_maxcards) end

no_bug_caifuren = sgs.General(extension, "no_bug_caifuren", "qun", 3, false)
lua_xianzhouCard = sgs.CreateSkillCard {
	name = "lua_xianzhou",
	target_fixed = false,
	filter = function(self, targets, to_select, player, data)
		if player:hasFlag("lua_xianzhou_target") then
			return #targets < player:getMark("lua_xianzhou_count") and player:inMyAttackRange(to_select) and to_select:objectName() ~= player:objectName()
		end
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		local room = source:getRoom()
		if source:hasFlag("lua_xianzhou_target") then
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.reason = "lua_xianzhou"
			for _, p in ipairs(targets) do
				damage.to = p
				room:damage(damage)
			end
			room:setPlayerFlag(source, "-lua_xianzhou_target")
			room:setPlayerMark(source, "lua_xianzhou_count", 0)
		else
			local target = targets[1]
			room:removePlayerMark(source, "@handover")
			self:addSubcards(source:getEquips())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), "lua_xianzhou", "")
			room:moveCardTo(self, target, sgs.Player_PlaceHand, reason, false)
			local choices = {}
			if source:isWounded() then
				table.insert(choices, "xianzhou_recover")
			end
			local n = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if target:inMyAttackRange(p) then
				n = n + 1
				end
			end
			if n > 0 then
				table.insert(choices, "xianzhou_damage")
			end
			if #choices > 0 then
				local choice = room:askForChoice(target, "lua_xianzhou", table.concat(choices, "+"))
				if choice == "xianzhou_recover" then
					local recover = sgs.RecoverStruct()
					recover.who = target
					recover.recover = math.min(source:getMaxHp() - source:getHp(), self:subcardsLength())
					room:recover(source, recover)
				elseif choice == "xianzhou_damage" then
					room:setPlayerFlag(target, "lua_xianzhou_target")
					room:setPlayerMark(target, "lua_xianzhou_count", self:subcardsLength())
					room:askForUseCard(target, "@@lua_xianzhou", "@lua_xianzhou")
				end
			end
		end
	end,
}
lua_xianzhouVS = sgs.CreateZeroCardViewAsSkill{
	name = "lua_xianzhou",
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self)
		local card = lua_xianzhouCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return player:hasEquip() and player:getMark("@handover") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@lua_xianzhou"
	end,
}

lua_xianzhou = sgs.CreateTriggerSkill{
	name = "lua_xianzhou",
	frequency = sgs.Skill_Limited,
	limit_mark = "@handover",
	view_as_skill = lua_xianzhouVS,
	on_trigger = function()
	end
}
no_bug_caifuren:addSkill("qieting")
no_bug_caifuren:addSkill(lua_xianzhou)

whlw_fanchou = sgs.General(extension_whlw, "whlw_fanchou", "qun", 4)
xingluan = sgs.CreateTriggerSkill{
	name = "xingluan",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.from and use.from:hasSkill(self:objectName()) and use.from:getPhase() == sgs.Player_Play
		and use.from:objectName() == player:objectName() and use.from:getMark(self:objectName().."-Clear") == 0 and use.card and not use.card:isKindOf("SkillCard")
		and use.to:length() == 1 and room:askForSkillInvoke(use.from, self:objectName(), data) then
			local point_six_card = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):getNumber() == 6 then
					point_six_card:append(id)
				end
			end
			if not point_six_card:isEmpty() then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:obtainCard(player, point_six_card:at(0), false)
				room:addPlayerMark(player, self:objectName().."-Clear")
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		return false
	end
}
whlw_fanchou:addSkill(xingluan)

whlw_zhangji = sgs.General(extension_whlw, "whlw_zhangji", "qun", 4)
luemingCard = sgs.CreateSkillCard{
	name = "lueming",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getEquips():length() < sgs.Self:getEquips():length() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, "@lueming_count")
		local choices = {}
		for i = 1, 13, 1 do
			table.insert(choices, i)
		end
		local choice = room:askForChoice(targets[1], self:objectName(), table.concat(choices, "+"))
		ChoiceLog(targets[1], choice)
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|.|"..choice.."|."
		judge.reason = self:objectName()
		judge.who = source
		judge.good = true
		room:judge(judge)
		local log = sgs.LogMessage()
		log.type = "#lueming_judge"
		log.from = source
		if judge:isGood() then
			log.arg = "#lueming_judge_same"
		else
			log.arg = "#lueming_judge_not_same"
		end
		room:sendLog(log)
		if judge:isGood() then
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 2))
		else
			local loot_cards = sgs.QList2Table(targets[1]:getCards("hej"))
			if #loot_cards > 0 then
				room:obtainCard(source, loot_cards[math.random(1, #loot_cards)], false)
			end
		end
	end
}
lueming = sgs.CreateZeroCardViewAsSkill{
	name = "lueming",
	view_as = function()
		return luemingCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lueming")
	end
}
whlw_zhangji:addSkill(lueming)
tunjiunCard = sgs.CreateSkillCard{
	name = "tunjiun",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasEquipArea()
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@tunjiun")
		local equip_type_table = {"Weapon", "Armor", "DefensiveHorse", "OffensiveHorse", "Treasure"}
		for _, card in sgs.qlist(targets[1]:getCards("e")) do
			if card:isKindOf("Weapon") then
				table.removeOne(equip_type_table, "Weapon")
			elseif card:isKindOf("Armor") then
				table.removeOne(equip_type_table, "Armor")
			elseif card:isKindOf("DefensiveHorse") then
				table.removeOne(equip_type_table, "DefensiveHorse")
			elseif card:isKindOf("OffensiveHorse") then
				table.removeOne(equip_type_table, "OffensiveHorse")
			elseif card:isKindOf("Treasure") then
				table.removeOne(equip_type_table, "Treasure")
			end
		end
		local usable_count = source:getMark("@lueming_count")
		if targets[1]:getEquips():length() + usable_count > 5 then
			usable_count = 5 - targets[1]:getEquips():length()
		end
		while usable_count > 0 and #equip_type_table > 0 do
			local equip_type_index = math.random(1, #equip_type_table)
			local equips = {}
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf(equip_type_table[equip_type_index]) then
					local equip_index = sgs.Sanguosha:getCard(id):getRealCard():toEquipCard():location()
				 	if targets[1]:getEquip(equip_index) == nil and targets[1]:hasEquipArea(equip_index) then
						table.insert(equips, sgs.Sanguosha:getCard(id))
					end
				end
			end
			if #equips > 0 then
				local card = equips[math.random(1, #equips)]
				room:useCard(sgs.CardUseStruct(card, targets[1], targets[1]))
				usable_count = usable_count - 1
			end
			table.removeOne(equip_type_table, equip_type_table[equip_type_index])
		end
	end
}
tunjiunVS = sgs.CreateZeroCardViewAsSkill{
	name = "tunjiun",
	view_as = function()
		return tunjiunCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@tunjiun") > 0 and player:getMark("@lueming_count") > 0
	end
}
tunjiun = sgs.CreateTriggerSkill{
	name = "tunjiun",
	frequency = sgs.Skill_Limited,
	view_as_skill = tunjiunVS,
	limit_mark = "@tunjiun",
	on_trigger = function()
	end
}
whlw_zhangji:addSkill(tunjiun)

whlw_guosi = sgs.General(extension_whlw, "whlw_guosi", "qun", 4)
tanbeiCard = sgs.CreateSkillCard{
	name = "tanbei",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local choices = {"tanbei_unlimited_use"}
		local loot_cards = sgs.QList2Table(targets[1]:getCards("hej"))
		if #loot_cards > 0 then
			table.insert(choices, "tanbei_give_card")
		end
		local choice = room:askForChoice(targets[1], self:objectName(), table.concat(choices, "+"))
		ChoiceLog(targets[1], choice)
		if choice == "tanbei_give_card" then
			if #loot_cards > 0 then
				room:obtainCard(source, loot_cards[math.random(1, #loot_cards)], false)
			end
			room:addPlayerMark(source, "juzhanFrom-Clear")
			room:addPlayerMark(targets[1], "juzhanTo-Clear")
		elseif choice == "tanbei_unlimited_use" then
			room:addPlayerMark(source, "fuck_caocao-Clear")
			room:addPlayerMark(targets[1], "@be_fucked-Clear")
		end
	end
}
tanbei = sgs.CreateZeroCardViewAsSkill{
	name = "tanbei",
	view_as = function()
		return tanbeiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#tanbei")
	end
}
whlw_guosi:addSkill(tanbei)
cidaoCard = sgs.CreateSkillCard{
	name = "cidao",
	will_throw = false,
	filter = function(self, targets, to_select)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local snatch = sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber())
		snatch:setSkillName("_"..self:objectName())
		snatch:deleteLater()
		return snatch:targetFilter(targets_list, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, snatch, targets_list) and to_select:getMark("cidao_target") > 1
	end,
	about_to_use = function(self, room, use)
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local snatch = sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber())
		snatch:addSubcard(card:getEffectiveId())
		snatch:setSkillName("_"..self:objectName())
		room:useCard(sgs.CardUseStruct(snatch, use.from, use.to))
	end
}
cidaoVS = sgs.CreateOneCardViewAsSkill{
	name = "cidao",
	--filter_pattern = ".|.|.|hand",
	view_filter = function(self, card)
		return not card:isEquipped() and not sgs.Self:isJilei(card)
	end,
	response_or_use = true,
	view_as = function(self, card)
		local skillcard = cidaoCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@cidao"
	end
}
cidao = sgs.CreateTriggerSkill{
	name = "cidao",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = cidaoVS,
	events = {sgs.CardFinished, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local invoke = false
			if use.from and use.from:hasSkill(self:objectName()) and use.from:getPhase() == sgs.Player_Play and use.card and not use.card:isKindOf("SkillCard") and use.to then
				for _, p in sgs.qlist(use.to) do
					if p:getMark("cidao_target") > 0 then
						invoke = true
						break
					end
				end
				for _, p in sgs.qlist(use.to) do
					if use.to:contains(p) then
						room:addPlayerMark(p, "cidao_target")
					end
				end
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("cidao_target") > 0 and not use.to:contains(p) then
						room:setPlayerMark(p, "cidao_target", 0)
					end
				end
				for _, p in sgs.qlist(use.to) do
					if invoke and p:getMark("cidao_target") > 1 and not p:isAllNude() then
						if not use.card:isKindOf("SkillCard") and p:objectName() ~= player:objectName() and not (use.card:isKindOf("Snatch") and use.card:getSkillName() == "cidao") and player:getMark("has_use_cidao-Clear") == 0 then
							local invoke2 = room:askForUseCard(player, "@cidao", "@cidao", -1, sgs.Card_MethodUse)
							if invoke2 then
								room:setPlayerMark(player, "has_use_cidao-Clear", 1)
								for _, pp in sgs.qlist(room:getAlivePlayers()) do
									if pp:getMark("cidao_target") > 0 then
										room:setPlayerMark(pp, "cidao_target", 0)
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("cidao_target") > 0 then
					room:setPlayerMark(p, "cidao_target", 0)
				end
			end
		end
		return false
	end
}
whlw_guosi:addSkill(cidao)
whlw_lijue = sgs.General(extension_whlw, "whlw_lijue", "qun", 6, true, false, false, 4)
langxi = sgs.CreatePhaseChangeSkill{
	name = "langxi",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() <= player:getHp() and p:objectName() ~= player:objectName() then
					players:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, players, self:objectName(), "langxi-invoke", true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				local damage_num = math.random(0,2)
				if damage_num > 0 then
					room:damage(sgs.DamageStruct(self:objectName(), player, target, damage_num))
				end
			end
		end
	end
}
whlw_lijue:addSkill(langxi)
yisuan = sgs.CreateTriggerSkill{
	name = "yisuan",
	events = {sgs.BeforeCardsMove, sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local invoke = false
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
					invoke = true
				end
			end
			local extract = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
			if player:getPhase() == sgs.Player_Play and move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and extract == sgs.CardMoveReason_S_REASON_USE and invoke and player:getMark("trick_card_can_yisuan-Clear") > 0 and player:getMark(self:objectName().."-Clear") == 0 and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:loseMaxHp(player)
				
				local dummy = sgs.Sanguosha:cloneCard("slash")
				dummy:addSubcards(move.card_ids)
				room:moveCardTo(dummy, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName(), player:objectName(), self:objectName(), ""))
				move:removeCardIds(move.card_ids)
				data:setValue(move)
				
				--for _,id in sgs.qlist(move.card_ids) do
				--	move.from_places:removeAt(listIndexOf(move.card_ids, id))
				--	move.card_ids:removeOne(id)
				--	data:setValue(move)
				--	room:obtainCard(player, sgs.Sanguosha:getCard(id), true)
				--end
				room:addPlayerMark(player, self:objectName().."-Clear")
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("TrickCard") and use.from and use.from:objectName() == player:objectName() and not use.card:isKindOf("SkillCard") then
				room:addPlayerMark(player, "trick_card_can_yisuan-Clear")
			end
		end
		return false
	end
}
whlw_lijue:addSkill(yisuan)

--==============================================全局变量及函数区==============================================--

function HeavenMove(player, id, movein, private_pile_name)  --将卡牌伪移动至&开头的私人牌堆中并限制使用或打出，以达到牌对你可见的效果
	local room = player:getRoom()		 --参数[ServerPlayer *player：可见角色; int id：伪移动卡牌id; bool movein：值true为进入私人牌堆，值false为移出私人牌堆; private_pile_name：私人牌堆名]
	pile_name = private_pile_name or "&talent"
	if movein then
		local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
		sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "guandu_shicai", ""))
		move.to_pile_name = pile_name
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _xuyou = sgs.SPlayerList()
		_xuyou:append(player)
		room:notifyMoveCards(true, moves, false, _xuyou)
		room:notifyMoveCards(false, moves, false, _xuyou)
		room:setPlayerCardLimitation(player, "use,response", "" .. id, true)
		player:setTag("HeavenMove", sgs.QVariant(id))
	else
		local move = sgs.CardsMoveStruct(id, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
		sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "guandu_shicai", ""))
		move.from_pile_name = pile_name
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _xuyou = sgs.SPlayerList()
		_xuyou:append(player)
		room:notifyMoveCards(true, moves, false, _xuyou)
		room:notifyMoveCards(false, moves, false, _xuyou)
		room:removePlayerCardLimitation(player, "use,response", "" .. id .. "$1")
	end
end

--==============================================全局技能区==============================================--
yizanUsedTimes = sgs.CreateTriggerSkill{  --记录技能“翊赞”发动次数（顺带进行连计的改变卡牌目标）
	name = "yizanUsedTimes",
	global = true,
	priority = 10,
	events = {sgs.PreCardUsed, sgs.PreCardResponded},
	on_trigger = function(self, event, splayer, data, room)
		local card
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			card = use.card
			if card:getSkillName() == "m_lianjicard" and (card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack")) then
				local targetList = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasFlag("mobile_lianji") then
						targetList:append(p)
						room:setPlayerFlag(p, "-mobile_lianji")
					end
				end
				if not targetList:isEmpty() then
					use.to = targetList
					data:setValue(use)
				end
			end
			if card:getSkillName() == "mobile_jingong" then
				room:addPlayerMark(splayer, "mobile_jingong")
				room:addPlayerMark(splayer, "mobile_jingong_Play")
			end
		else
			card = data:toCardResponse().m_card
		end
		if card and card:getSkillName() == "yizan" and splayer:getMark("@yizanUsed") < 3 then
			room:addPlayerMark(splayer, "@yizanUsed")
		end
		return false
	end
}

xionghuo_Prohibit = sgs.CreateProhibitSkill{
	name = "#xionghuo_Prohibit",
	is_prohibited = function(self, from, to, card)
		return from:getMark("xionghuo_from-Clear") > 0 and to:getMark("xionghuo_to-Clear") > 0 and card:isKindOf("Slash")
	end
}

xionghuo_Maxcards = sgs.CreateMaxCardsSkill{
	name = "xionghuo_Maxcards",
	extra_func = function(self, target)
		local n = 0
		if target:getMark("xionghuo_debuff-Clear") > 0 then
			n = n - target:getMark("xionghuo_debuff-Clear")
		end
		return n
	end
}

if not sgs.Sanguosha:getSkill("yizanUsedTimes") then skills:append(yizanUsedTimes) end
if not sgs.Sanguosha:getSkill("#xionghuo_Prohibit") then skills:append(xionghuo_Prohibit) end
if not sgs.Sanguosha:getSkill("xionghuo_Maxcards") then skills:append(xionghuo_Maxcards) end

-- 武将：赵广赵统 --
zhaoguangzhaotong = sgs.General(extension_mobile, "zhaoguangzhaotong", "shu", "4", true)
-- 技能：【翊赞】你可以将两张牌（其中至少一张基本牌）当任意基本牌使用或打出。（修改后：你可以将一张基本牌当任意基本牌使用或打出。） --
yizanCard = sgs.CreateSkillCard{
	name = "yizan",
	will_throw = false,
	filter = function(self, targets, to_select)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		if not self:getSubcards():isEmpty() and sgs.Self:getOffensiveHorse() and sgs.Self:getOffensiveHorse():getId() == self:getSubcards():first() then
			rangefix = rangefix + 1
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
				and (card:isKindOf("Slash") and sgs.Self:canSlash(to_select, true, rangefix))
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local card = sgs.Self:getTag("yizan"):toCard()
		return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
			and (card:isKindOf("Slash") and sgs.Self:canSlash(to_select, true, rangefix))
	end,
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = sgs.Self:getTag("yizan"):toCard()
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetsFeasible(plist, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = sgs.Self:getTag("yizan"):toCard()
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room, to_yizan = player:getRoom(), self:getUserString()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local yizan_list = {}
			table.insert(yizan_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(yizan_list, "normal_slash")
				table.insert(yizan_list, "thunder_slash")
				table.insert(yizan_list, "fire_slash")
			end
			to_yizan = room:askForChoice(player, "yizan_slash", table.concat(yizan_list, "+"))
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_yizan == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_yizan == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_yizan
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_yizan")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self, user)
		local room, user_str = user:getRoom(), self:getUserString()
		local to_yizan
		if user_str == "peach+analeptic" then
			local yizan_list = {}
			table.insert(yizan_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(yizan_list, "analeptic")
			end
			to_yizan = room:askForChoice(user, "yizan_saveself", table.concat(yizan_list, "+"))
		elseif user_str == "slash" then
			local yizan_list = {}
			table.insert(yizan_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(yizan_list, "normal_slash")
				table.insert(yizan_list, "thunder_slash")
				table.insert(yizan_list, "fire_slash")
			end
			to_yizan = room:askForChoice(user, "yizan_slash", table.concat(yizan_list, "+"))
		else
			to_yizan = user_str
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_yizan == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_yizan == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_yizan
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("_yizan")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end
}
yizan = sgs.CreateViewAsSkill{
	name = "yizan",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			if sgs.Self:getMark("longyuan") > 0 then
				return to_select:isKindOf("BasicCard")
			else
				return true
			end
		elseif #selected == 1 and sgs.Self:getMark("longyuan") == 0 then
			if selected[1]:isKindOf("BasicCard") then
				return true
			else
				return to_select:isKindOf("BasicCard")
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if (#cards ~= 1 and sgs.Self:getMark("longyuan") > 0) or (#cards ~= 2 and sgs.Self:getMark("longyuan") == 0) then return nil end
		local skillcard = yizanCard:clone()
		skillcard:setSkillName(self:objectName())
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			skillcard:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		end
		local c = sgs.Self:getTag("yizan"):toCard()
		if c then
			skillcard:setUserString(c:objectName())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		local basic = {"slash", "peach"}
		if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
			table.insert(basic, "thunder_slash")
			table.insert(basic, "fire_slash")
			table.insert(basic, "analeptic")
		end
		for _, patt in ipairs(basic) do
			local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, -1)
			if poi and poi:isAvailable(player) and not(patt == "peach" and not player:isWounded()) then
				return true
			end
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
        if string.startsWith(pattern, ".") or string.startsWith(pattern, "@") then return false end
        if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then return false end
        return pattern ~= "nullification"
	end
}
yizan:setGuhuoDialog("l")
zhaoguangzhaotong:addSkill(yizan)
-- 技能：【龙渊】觉醒技，当你使用或打出一张牌时，若你发动过至少三次“翊赞”，则你将其效果改为“你可以将一张基本牌当任意基本牌使用或打出”。 --
longyuan = sgs.CreateTriggerSkill{
	name = "longyuan",
	frequency = sgs.Skill_Wake,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data, room)
		if player:getMark("@yizanUsed") >= 3 and player:getMark(self:objectName()) == 0 then
			room:addPlayerMark(player, self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			sgs.Sanguosha:addTranslationEntry(":yizan", "" .. string.gsub(sgs.Sanguosha:translate(":yizan"), sgs.Sanguosha:translate(":yizan"), sgs.Sanguosha:translate(":yizan-EX")))
			ChangeCheck(player, "zhaoguangzhaotong")
		end
		return false
	end
}
zhaoguangzhaotong:addSkill(longyuan)

-- 武将：许攸（官渡之战身份版） --
guandu_xuyou = sgs.General(extension_guandu, "guandu_xuyou", "qun", "3", true)
-- 技能：【识才】牌堆顶的牌于你的出牌阶段内对你可见；出牌阶段，你可以弃置一张牌并获得牌堆顶的牌，若你的手牌中有此阶段内以此法获得的牌，你不能发动此技能。 --
guandu_shicaiCard = sgs.CreateSkillCard{
	name = "guandu_shicai",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:getCard(room:getDrawPile():first())
		room:obtainCard(source, card, false)
		room:setCardFlag(card, self:objectName())
	end
}
guandu_shicaiVS = sgs.CreateOneCardViewAsSkill{
	name = "guandu_shicai",
	filter_pattern = ".",
	view_as = function(self, card)
		local skillcard = guandu_shicaiCard:clone()
		skillcard:addSubcard(card:getId())
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:hasFlag(self:objectName()) then
				return false
			end
		end
		return player:canDiscard(player, "he")
	end
}
guandu_shicai = sgs.CreateTriggerSkill{
	name = "guandu_shicai",
	view_as_skill = guandu_shicaiVS,
	events = {sgs.EventPhaseStart, sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		local id = room:getDrawPile():first()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				HeavenMove(player, id, true)
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if (move.from_places:contains(sgs.Player_DrawPile) and p:getPhase() == sgs.Player_Play and move.card_ids:contains(p:getTag("HeavenMove"):toInt()))
					or move.to_place == sgs.Player_DrawPile then
					HeavenMove(p, p:getTag("HeavenMove"):toInt(), false)
					p:setTag(self:objectName(), sgs.QVariant(true))
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getPhase() == sgs.Player_Play and p:getTag(self:objectName()):toBool() then
					HeavenMove(p, id, true)
					p:setTag(self:objectName(), sgs.QVariant(false))
				end
			end
		else
			if player:getPhase() == sgs.Player_Play then
				HeavenMove(player, player:getTag("HeavenMove"):toInt(), false)
				for _, card in sgs.qlist(player:getHandcards()) do
					if card:hasFlag(self:objectName()) then
						room:setCardFlag(card, "-" .. self:objectName())
					end
				end
			end
		end
		return false
	end
}
guandu_xuyou:addSkill(guandu_shicai)
-- 技能：【逞功】当一名角色使用牌指定目标后，若目标数不少于2，你可以令其摸一张牌。 --
chenggong = sgs.CreateTriggerSkill{
	name = "chenggong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.to:length() > 1 and not use.card:isKindOf("SkillCard") then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if use.from:isAlive() and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("to_draw:" .. use.from:objectName())) then
					room:doAnimate(1, p:objectName(), use.from:objectName())
					room:drawCards(use.from, 1, self:objectName())
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
guandu_xuyou:addSkill(chenggong)
--[[
	技能：【择主】出牌阶段限一次，你可以选择一至两名其他角色（若你不为主公，则其中必须有主公）。
				  你依次获得他们各一张牌（若目标角色没有牌，则改为你摸一张牌），然后分别将一张牌交给他们。
]]--
gd_zezhuCard = sgs.CreateSkillCard{
	name = "gd_zezhu",
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if sgs.Self:isLord() then
				return to_select:objectName() ~= sgs.Self:objectName()
			else
				return to_select:isLord()
			end
		elseif #targets == 1 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		for i = 1, 2 do
			for j = 1, #targets do
				local to = targets[j]
				if to:isDead() then continue end
				if i == 1 then
					if to:isNude() then
						room:drawCards(source, 1, self:objectName())
					else
						local id = room:askForCardChosen(source, to, "he", self:objectName())
						if id ~= -1 then
							room:obtainCard(source, id, false)
						end
					end
				elseif i == 2 then
					if source:isNude() then continue end
					local card = room:askForCard(source, "..!", "@gd_zezhu-give:" .. to:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:obtainCard(to, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), to:objectName(), self:objectName(), ""), false)
					end
				end
			end
		end
	end
}
gd_zezhu = sgs.CreateZeroCardViewAsSkill{
    name = "gd_zezhu",
    view_as = function()
        return gd_zezhuCard:clone()
    end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#gd_zezhu")
	end
}
guandu_xuyou:addSkill(gd_zezhu)

-- 武将：徐荣 --
xurong = sgs.General(extension_whlw, "xurong", "qun", "4", true)
--[[
	技能：【凶镬】游戏开始时，你获得3枚“暴戾”标记；出牌阶段，你可以交给一名其他角色1枚“暴戾”标记；当你对其他角色造成伤害时，若其有“暴戾”标记，此伤害+1；
	              其他角色的出牌阶段开始时，若其有“暴戾”标记，其移去所有“暴戾”标记并随机选择一项：1.受到你对其造成的1点火焰伤害，且此回合其使用【杀】不能指定你为目标；
	              2.失去1点体力，且此回合其手牌上限-1；3.你随机获得其手牌和装备区里的各一张牌。
]]--
xionghuoCard = sgs.CreateSkillCard{
	name = "xionghuo",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		effect.from:loseMark("@brutal")
		effect.to:gainMark("@brutal")
	end
}
xionghuoVS = sgs.CreateZeroCardViewAsSkill{
	name = "xionghuo",
	view_as = function()
		return xionghuoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@brutal") > 0
	end
}
xionghuo = sgs.CreateTriggerSkill{
	name = "xionghuo",
	view_as_skill = xionghuoVS,
	events = {sgs.GameStart, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			player:gainMark("@brutal", 3)
		else
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() ~= player:objectName() and damage.to:getMark("@brutal") > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, player:objectName(), damage.to:objectName())
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end
}
xionghuo_forPlay = sgs.CreatePhaseChangeSkill{
	name = "#xionghuo_forPlay",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local invoke, sources = not player:hasSkill("xionghuo"), sgs.SPlayerList()
		for _, p in sgs.qlist(room:findPlayersBySkillName("xionghuo")) do
			if p:objectName() ~= player:objectName() then
				invoke = true
				sources:append(p)
			end
		end
		if invoke and not sources:isEmpty() then
			if sources:length() > 1 then
				room:sortByActionOrder(sourses)
			end
			local source = sources:first()
			room:sendCompulsoryTriggerLog(source, "xionghuo")
			room:broadcastSkillInvoke("xionghuo")
			player:loseAllMarks("@brutal")
			local ranNum = math.random(1, 3)
			local log = sgs.LogMessage()
			log.type = "#xionghuo_log"
			log.from = player
			if ranNum == 1 then
				--ChoiceLog(player, "xionghuo_choice1")
				log.arg = "xionghuo_choice1"
				room:sendLog(log)
				room:doAnimate(1, source:objectName(), player:objectName())
				room:damage(sgs.DamageStruct(self:objectName(), source, player, 1, sgs.DamageStruct_Fire))
				room:setPlayerMark(player, "xionghuo_from-Clear", 1)
				room:setPlayerMark(source, "xionghuo_to-Clear", 1)
			elseif ranNum == 2 then
				--ChoiceLog(player, "xionghuo_choice2")
				log.arg = "xionghuo_choice2"
				room:sendLog(log)
				room:loseHp(player)
				room:addPlayerMark(player, "xionghuo_debuff-Clear")
			else
				--ChoiceLog(player, "xionghuo_choice3")
				log.arg = "xionghuo_choice3"
				room:sendLog(log)
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if player:hasEquip() then
					local equip = player:getEquips():at(math.random(0, player:getEquips():length() - 1))
					dummy:addSubcard(equip:getEffectiveId())
				end
				if not player:isKongcheng() then
					local hand = player:getCards("h"):at(math.random(0, player:getCards("h"):length() - 1))
					dummy:addSubcard(hand:getEffectiveId())
				end
				if dummy:subcardsLength() > 0 then
					room:obtainCard(source, dummy, false)
				end
				dummy:deleteLater()
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:getPhase() == sgs.Player_Play and target:getMark("@brutal") > 0
	end
}
xurong:addSkill(xionghuo)
xurong:addSkill(xionghuo_forPlay)
extension:insertRelatedSkills("xionghuo", "#xionghuo_forPlay")
-- 技能：【杀绝】锁定技，当其他角色进入濒死状态时，若其体力值小于0，你获得1枚“暴戾”标记，然后若其因牌造成的伤害而进入濒死状态，你获得此牌。 --
shajue = sgs.CreateTriggerSkill{
	name = "shajue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data, room)
		local dying, players = data:toDying(), room:findPlayersBySkillName(self:objectName())
		room:sortByActionOrder(players)
		for _, p in sgs.qlist(players) do
			if player:getHp() < 0 then
				room:sendCompulsoryTriggerLog(p, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				p:gainMark("@brutal")
				local card = dying.damage.card
				if card then
					local id = card:getEffectiveId()
					if room:getCardPlace(id) == sgs.Player_PlaceTable then
						room:obtainCard(p, card)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
xurong:addSkill(shajue)
lua_wansha = sgs.CreateTriggerSkill{
	name = "lua_wansha",
	events = {sgs.AskForPeaches, sgs.AskForPeachesDone},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			local current = room:getCurrent()
			if current and current:isAlive() and current:hasSkill(self:objectName()) and current:getPhase() ~= sgs.Player_NotActive and current:getMark("lua_wansha_voice") == 0 then
				room:addPlayerMark(current, "lua_wansha_voice")
				room:broadcastSkillInvoke(self:objectName())
			end
			if current and current:isAlive() and current:hasSkill(self:objectName()) and current:getPhase() ~= sgs.Player_NotActive then
				if dying.who and dying.who:objectName() ~= player:objectName() and current:objectName() ~= player:objectName() then
					return true
				end
				--return not (player:getSeat() == current:getSeat() or player:getSeat() == dying.who:getSeat())
			end
		elseif event == sgs.AskForPeachesDone then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("lua_wansha_voice") > 0 then
					room:setPlayerMark(p, "lua_wansha_voice", 0)
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return true
	end
}
if not sgs.Sanguosha:getSkill("lua_wansha") then skills:append(lua_wansha) end

no_bug_caiwenji = sgs.General(extension, "no_bug_caiwenji", "wei", 3, false)
lua_chenqing = sgs.CreateTriggerSkill{
	name = "lua_chenqing",
	events = {sgs.AskForPeaches, sgs.AskForPeachesDone},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.AskForPeaches then
			local dying = data:toDying()
			local current = room:getCurrent()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getMark(self:objectName().."_lun") == 0 and p:getMark("no_more_ask_"..self:objectName()) == 0 then
					local players = sgs.SPlayerList()
					for _, pp in sgs.qlist(room:getAlivePlayers()) do
						if pp:objectName() ~= dying.who:objectName() and pp:objectName() ~= p:objectName() then
							players:append(pp)
						end
					end
					local target = room:askForPlayerChosen(p, players, self:objectName(), "ChenqingAsk", true, true)
					if target == nil then
						room:addPlayerMark(p, "no_more_ask_"..self:objectName())
					end
					if target and target:isAlive() then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(p, self:objectName().."engine")
						if p:getMark(self:objectName().."engine") > 0 then
							room:addPlayerMark(p, self:objectName().."_lun")
							target:drawCards(4, self:objectName())
							local chenqing_throw_cards = room:askForExchange(target, self:objectName(), 4, 4, true, "ChenqingDiscard")
							room:throwCard(chenqing_throw_cards, target, nil)
							local suits = {}
							for _,id in sgs.qlist(chenqing_throw_cards:getSubcards()) do
								if not table.contains(suits, sgs.Sanguosha:getCard(id):getSuit()) then
									table.insert(suits, sgs.Sanguosha:getCard(id):getSuit())
								end
							end
							if #suits == 4 then
								local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
								peach:setSkillName(self:objectName())
								room:useCard(sgs.CardUseStruct(peach, target, dying.who))
							end
						end
					end
				end
			end
		elseif event == sgs.AskForPeachesDone then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("no_more_ask_"..self:objectName()) > 0 then
					room:setPlayerMark(p, "no_more_ask_"..self:objectName(), 0)
				end
			end
		end
		return false
	end,
	can_trigger = function(self,target)
		return target
	end
}
no_bug_caiwenji:addSkill(lua_chenqing)
no_bug_caiwenji:addSkill("moshi")

sec_rev_shenluxun = sgs.General(extension, "sec_rev_shenluxun", "god", 4, true)
sec_rev_shenluxun:addSkill("junlve")
sec_rev_shenluxun:addSkill("cuike")
zhanhuo_sec_revCard = sgs.CreateSkillCard{
	name = "zhanhuo_sec_rev",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getMark("@junlve") and to_select:isChained()
	end,
	about_to_use = function(self, room, use)
		use.from:loseAllMarks("@junlve")
		skill(self, room, use.from, true)
		room:addPlayerMark(use.from, self:objectName().."engine")
		if use.from:getMark(self:objectName().."engine") > 0 then
			room:removePlayerMark(use.from, "@fire_boom_sec_rev")
			for _, p in sgs.qlist(use.to) do
				room:doAnimate(1, use.from:objectName(), p:objectName())
				p:throwAllEquips()
			end
			room:damage(sgs.DamageStruct(self:objectName(), use.from, use.to:first(), 1, sgs.DamageStruct_Fire))
			room:removePlayerMark(use.from, self:objectName().."engine")
		end
	end
}
zhanhuo_sec_revVS = sgs.CreateZeroCardViewAsSkill{
	name = "zhanhuo_sec_rev",
	view_as = function(self, cards)
		return zhanhuo_sec_revCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@fire_boom_sec_rev") > 0
	end
}
zhanhuo_sec_rev = sgs.CreateTriggerSkill{
	name = "zhanhuo_sec_rev",
	frequency = sgs.Skill_Limited,
	limit_mark = "@fire_boom_sec_rev",
	view_as_skill = zhanhuo_sec_revVS,
	on_trigger = function()
	end
}
sec_rev_shenluxun:addSkill(zhanhuo_sec_rev)


olzhixi_filter = sgs.CreateFilterSkill{
	name = "#olzhixi-filter",
	view_filter = function(self, to_select)
		return to_select:isKindOf("TrickCard") and sgs.Sanguosha:currentRoom():getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName("olzhixi")
		local new = sgs.Sanguosha:getWrappedCard(card:getId())
		new:takeOver(slash)
		return new
	end
}
if not sgs.Sanguosha:getSkill("#olzhixi-filter") then skills:append(olzhixi_filter) end

sec_rev_shenzhangliao = sgs.General(extension, "sec_rev_shenzhangliao", "god", 4, true)
zhiti_sec_rev = sgs.CreateTriggerSkill{
	name = "zhiti_sec_rev",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.MarkChanged, sgs.Pindian, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.from_card:getNumber() ~= pindian.to_card:getNumber() then
				local winner = pindian.to
				local loser = pindian.from
				if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
					winner = pindian.from
					loser = pindian.to
				end
				if winner and winner:objectName() == player:objectName() and loser:isWounded() and winner:inMyAttackRange(loser) then
					room:addPlayerMark(player, self:objectName().."engine")
					if player:getMark(self:objectName().."engine") > 0 then
						--ObtainEquipArea(self, player)
						ObtainEquipAreaWithSeparateHorse(self, player)
						room:removePlayerMark(player, self:objectName().."engine")
					end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from:isWounded() and damage.to and damage.to:hasSkill(self:objectName()) and damage.to:inMyAttackRange(damage.from) then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					--ObtainEquipArea(self, player)
					ObtainEquipAreaWithSeparateHorse(self, player)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		else
			local mark = data:toMark()
			if mark.name == self:objectName() and mark.gain > 0 then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					--ObtainEquipArea(self, player)
					ObtainEquipAreaWithSeparateHorse(self, player)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
bukuishishen_sec = sgs.CreateTriggerSkill{
	name = "bukuishishen_sec",
	events = {sgs.EventPhaseStart, sgs.Damage},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local choices = {}
		local choicess = {}
		if event == sgs.Damage and (player:hasSkill("duorui_sec_rev") or player:hasSkill("zhiti_sec_rev")) then
			local damage = data:toDamage()
			local duoruis = {}
			for _, skill in sgs.qlist(damage.to:getVisibleSkillList()) do
				if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited then
					table.insert(duoruis, skill:objectName())
				end
			end
			if player:hasSkill("duorui_sec_rev") and damage.to and damage.to:objectName() ~= player:objectName() and player:getPhase() == sgs.Player_Play and player:getMark("has_used_duorui_sec_rev") == 0 and player:hasEquipArea() and #duoruis > 0 then
				table.insert(choices, "duorui_sec_rev")
			end
			local invoke = false
			for i = 0, 4 do
				if not invoke then
					invoke = not player:hasEquipArea(i)
				end
			end
			if player:hasSkill("zhiti_sec_rev") and damage.card and damage.card:isKindOf("Duel") and invoke and damage.to and damage.to:isWounded() and player:inMyAttackRange(damage.to) then
				table.insert(choices, "zhiti_sec_rev")
			end
			if #choices > 0 then
				local choice = room:askForChoice(player, "SKILL", table.concat(choices, "+"))
				player:setTag(choice, data)
				room:addPlayerMark(player, choice)
				room:removePlayerMark(player, choice)
				local duoruiss = {}
				for _, skill in sgs.qlist(damage.to:getVisibleSkillList()) do
					if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited then
						table.insert(duoruiss, skill:objectName())
					end
				end
				if player:hasSkill("duorui_sec_rev") and damage.to and damage.to:objectName() ~= player:objectName() and player:getPhase() == sgs.Player_Play and player:getMark("has_used_duorui_sec_rev") == 0 and player:hasEquipArea() and #duoruiss > 0 then
					table.insert(choicess, "duorui_sec_rev")
				end
				local invoke = false
				for i = 0, 4 do
					if not invoke then
						invoke = not player:hasEquipArea(i)
					end
				end
				if player:hasSkill("zhiti_sec_rev") and damage.card and damage.card:isKindOf("Duel") and invoke and damage.to and damage.to:isWounded() and player:inMyAttackRange(damage.to) then
					table.insert(choicess, "zhiti_sec_rev")
				end
				table.removeOne(choicess, choice)
				if #choicess > 0 then
					local choicee = room:askForChoice(player, "SKILL", table.concat(choicess, "+"))
					player:setTag(choicee, data)
					room:addPlayerMark(player, choicee)
					room:removePlayerMark(player, choicee)
				end
			end
		end
	end
}
if not sgs.Sanguosha:getSkill("bukuishishen_sec") then skills:append(bukuishishen_sec) end
sec_rev_shenzhangliao_clear_mark = sgs.CreateTriggerSkill{
	name = "sec_rev_shenzhangliao_clear_mark",
	events = {sgs.Deathed, sgs.EventPhaseChanging},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, "Duorui_sec_rev_to") and player:getMark(mark) > 0 then
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							for _, mark in sgs.list(p:getMarkNames()) do
								local duoruis_skill_names = {}
								for _, skill_name in sgs.qlist(p:getVisibleSkillList()) do
									if p:getMark("Duorui_sec_rev"..skill_name:objectName().."from") > 0 then
										table.insert(duoruis_skill_names, "-"..skill_name:objectName())
										room:setPlayerMark(p, "Duorui_sec_rev"..skill_name:objectName().."from", 0)
									end
								end
								if #duoruis_skill_names > 0 then
									room:handleAcquireDetachSkills(p, table.concat(duoruis_skill_names, "|"))
								end
							end
							if p:getMark("has_used_duorui_sec_rev") > 0 then
								room:setPlayerMark(p, "has_used_duorui_sec_rev", 0)
							end
						end
					end
				end
			end
		elseif event == sgs.Deathed then
			local death = data:toDeath()
			for _, mark in sgs.list(death.who:getMarkNames()) do
				if string.find(mark, "Duorui_sec_rev_to") and death.who:getMark(mark) > 0 then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						for _, mark in sgs.list(p:getMarkNames()) do
							local duoruis_skill_names = {}
							for _, skill_name in sgs.qlist(p:getVisibleSkillList()) do
								if p:getMark("Duorui_sec_rev"..skill_name:objectName().."from") > 0 then
									table.insert(duoruis_skill_names, "-"..skill_name:objectName())
									room:setPlayerMark(p, "Duorui_sec_rev"..skill_name:objectName().."from", 0)
								end
							end
							if #duoruis_skill_names > 0 then
								room:handleAcquireDetachSkills(p, table.concat(duoruis_skill_names, "|"))
							end
						end
						if p:getMark("has_used_duorui_sec_rev") > 0 then
							room:setPlayerMark(p, "has_used_duorui_sec_rev", 0)
						end
					end
				end
			end
		end
	end
}
if not sgs.Sanguosha:getSkill("sec_rev_shenzhangliao_clear_mark") then skills:append(sec_rev_shenzhangliao_clear_mark) end
duorui_sec_rev = sgs.CreateTriggerSkill{
	name = "duorui_sec_rev",
	events = {sgs.MarkChanged},
	on_trigger = function(self, event, player, data, room)
		local mark = data:toMark()
		if mark.name == self:objectName() and mark.gain > 0 then
			local damage = player:getTag(self:objectName()):toDamage()
			local duoruis = {}
			if damage.to and damage.to:isAlive() then
				for _, skill in sgs.qlist(damage.to:getVisibleSkillList()) do
					if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited then
						table.insert(duoruis, skill:objectName())
					end
				end
			end
			if #duoruis > 0 then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					--local n = ThrowEquipArea(self, player, true)
					local n = ThrowEquipAreaWithSeparateHorse(self, player, true)
					if n ~= -1 then
						local skill_choice = room:askForChoice(player, self:objectName(), table.concat(duoruis, "+"))
						room:addPlayerMark(damage.to, "Duorui_sec_rev_to"..skill_choice)
						room:addPlayerMark(damage.to, "Qingcheng"..skill_choice)
						room:addPlayerMark(damage.from, "Duorui_sec_rev"..skill_choice.."from")
						room:addPlayerMark(player, "has_used_duorui_sec_rev")
						room:handleAcquireDetachSkills(player, skill_choice)
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
sec_rev_shenzhangliao:addSkill(duorui_sec_rev)
sec_rev_shenzhangliao:addSkill(zhiti_sec_rev)



yuejian_use_record_mark = sgs.CreateTriggerSkill{
	name = "yuejian_use_record_mark",
	global = true,
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		for _, p in sgs.qlist(room:findPlayersBySkillName("yuejian")) do
			if use.from and use.to then
				for _, pp in sgs.qlist(use.to) do
					if pp:objectName() ~= p:objectName() and pp:objectName() ~= use.from:objectName() then
						room:addPlayerMark(use.from, "yuejian_use_"..p:objectName().."-Clear")
					end
				end
			end
		end
	end
}
if not sgs.Sanguosha:getSkill("yuejian_use_record_mark") then skills:append(yuejian_use_record_mark) end

xiahoudun_xhly = sgs.General(extension, "xiahoudun_xhly", "wei", 4, true)
qingjian_xhlyCard = sgs.CreateSkillCard{
	name = "qingjian_xhly",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local current = room:getCurrent()
		local card_type_table = {}
		for _, id in sgs.qlist(self:getSubcards()) do
			if not table.contains(card_type_table, sgs.Sanguosha:getCard(id):getTypeId()) then
				table.insert(card_type_table, sgs.Sanguosha:getCard(id):getTypeId())
			end
			room:showCard(source, id)
		end
		room:setPlayerMark(current, "qingjian_xhly_increase_maxcard-Clear", #card_type_table)
		room:addPlayerMark(source, "has_use_qingjian_xhly-Clear")	--這行加在這很重要，不然這技能和步騭會無限循環到沒牌為止(多次給)
		room:obtainCard(targets[1], self, true)
	end
}
qingjian_xhlyVS = sgs.CreateViewAsSkill{
	name = "qingjian_xhly",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		local skillcard = qingjian_xhlyCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@qingjian_xhly"
	end
}
qingjian_xhly = sgs.CreateTriggerSkill{
	name = "qingjian_xhly",
	global = true,
	view_as_skill = qingjian_xhlyVS,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if not room:getTag("FirstRound"):toBool() and p:getPhase() ~= sgs.Player_Draw and p:getMark("has_use_qingjian_xhly-Clear") == 0
			and move.to and move.to:objectName() == p:objectName() and move.to_place and move.to_place == sgs.Player_PlaceHand
			and p:getMark("do_not_ask_more_qingjian_xhly-Clear") == 0
			then
				room:askForUseCard(p, "@qingjian_xhly", "@qingjian_xhly", -1, sgs.Card_MethodNone)
				room:addPlayerMark(p, "do_not_ask_more_qingjian_xhly-Clear")
			end
		end
	end
}
xiahoudun_xhly:addSkill(qingjian_xhly)
xiahoudun_xhly:addSkill("ganglie")
qingjian_xhly_maxcards = sgs.CreateMaxCardsSkill{
	name = "qingjian_xhly_maxcards",
	extra_func = function(self, target, player)
		local n = 0
		if target:getMark("qingjian_xhly_increase_maxcard-Clear") > 0 then
			n = n + target:getMark("qingjian_xhly_increase_maxcard-Clear")
		end
		return n
	end
}
if not sgs.Sanguosha:getSkill("qingjian_xhly_maxcards") then skills:append(qingjian_xhly_maxcards) end

caoying = sgs.General(extension_pray, "caoying", "wei", 4, false)
lingren = sgs.CreateTriggerSkill{
	name = "lingren",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetSpecified, sgs.DamageCaused, sgs.CardFinished, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) and use.from:objectName() == player:objectName() and player:getMark(self:objectName().."-Clear") == 0
			and use.card and not use.card:isKindOf("SkillCard") and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")
			or use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("FireAttack"))
			and room:askForSkillInvoke(player, self:objectName(), data) then
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(use.to) do
					players:append(p)
				end
				if not players:isEmpty() then
					local target = room:askForPlayerChosen(player, players, self:objectName(), "lingren-invoke", true, true)
					if target then
						room:broadcastSkillInvoke(self:objectName())
						room:addPlayerMark(target, "lingren_damage_buff_to")
						local basic_guess = room:askForChoice(player, "lingren_basic_guess", "lingren_yes+lingren_no")
						local basic_guess_log = sgs.LogMessage()
						basic_guess_log.type = "$lingren_basic_guess"
						basic_guess_log.from = player
						basic_guess_log.to:append(target)
						basic_guess_log.arg = basic_guess
						--room:sendLog(basic_guess_log)
						local trick_guess = room:askForChoice(player, "lingren_trick_guess", "lingren_yes+lingren_no")
						local trick_guess_log = sgs.LogMessage()
						trick_guess_log.type = "$lingren_trick_guess"
						trick_guess_log.from = player
						trick_guess_log.to:append(target)
						trick_guess_log.arg = trick_guess
						--room:sendLog(trick_guess_log)
						local equip_guess = room:askForChoice(player, "lingren_equip_guess", "lingren_yes+lingren_no")
						local equip_guess_log = sgs.LogMessage()
						equip_guess_log.type = "$lingren_equip_guess"
						equip_guess_log.from = player
						equip_guess_log.to:append(target)
						equip_guess_log.arg = equip_guess
						--room:sendLog(equip_guess_log)
						
						local target_handcard_has_basic = false
						local target_handcard_has_trick = false
						local target_handcard_has_equip = false
						for _, c in sgs.qlist(target:getCards("h")) do
							if c:isKindOf("BasicCard") then
								target_handcard_has_basic = true
							end
							if c:isKindOf("TrickCard") then
								target_handcard_has_trick = true
							end
							if c:isKindOf("EquipCard") then
								target_handcard_has_equip = true
							end
						end
						
						local guess_result = 0
						if target_handcard_has_basic then
							if basic_guess == "lingren_yes" then
								guess_result = guess_result + 1
							end
						else
							if basic_guess == "lingren_no" then
								guess_result = guess_result + 1
							end
						end
						if target_handcard_has_trick then
							if trick_guess == "lingren_yes" then
								guess_result = guess_result + 1
							end
						else
							if trick_guess == "lingren_no" then
								guess_result = guess_result + 1
							end
						end
						if target_handcard_has_equip then
							if equip_guess == "lingren_yes" then
								guess_result = guess_result + 1
							end
						else
							if equip_guess == "lingren_no" then
								guess_result = guess_result + 1
							end
						end
						
						local lingren_guess_result = sgs.LogMessage()
						lingren_guess_result.type = "$lingren_guess_result"
						lingren_guess_result.from = player
						lingren_guess_result.arg = guess_result
						--room:sendLog(lingren_guess_result)
						if guess_result >= 1 then
							room:setCardFlag(use.card, "lingren_damage_buff")
							if guess_result >= 2 then
								room:drawCards(player, 2, self:objectName())
								if guess_result == 3 then
									room:handleAcquireDetachSkills(player, "jianxiong|xingshang", true)
								end
							end
						end
						room:addPlayerMark(player, self:objectName().."-Clear")
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.by_user and not damage.chain and not damage.transfer and damage.card:hasFlag("lingren_damage_buff")
			and damage.to and damage.to:getMark("lingren_damage_buff_to") > 0
			then
				local log = sgs.LogMessage()
				log.type = "$lingren_damage_buff"
				log.from = player
				log.to:append(damage.to)
				log.card_str = damage.card:toString()
				log.arg = self:objectName()
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.CardFinished and data:toCardUse().card:hasFlag("lingren_damage_buff") then
			room:setCardFlag(data:toCardUse().card, "-lingren_damage_buff")
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("lingren_damage_buff_to") > 0 then
					room:setPlayerMark(p, "lingren_damage_buff_to", 0)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then
				room:handleAcquireDetachSkills(player, "-jianxiong|-xingshang", true)
			end
		end
		return false
	end
}
caoying:addSkill(lingren)
fujian = sgs.CreateTriggerSkill{
	name = "fujian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
			local min_handcard_num = 1000
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				min_handcard_num = math.min(min_handcard_num, p:getHandcardNum())
			end
			local all_alive_players = {}
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				table.insert(all_alive_players, p)
			end
			local random_target = all_alive_players[math.random(1, #all_alive_players)]
			local being_show_cards = {}
			for _, c in sgs.qlist(random_target:getCards("h")) do
				if #being_show_cards < min_handcard_num then
					table.insert(being_show_cards, c:getId())
				end
			end
			
			if #being_show_cards > 0 then
				room:broadcastSkillInvoke(self:objectName())
				
				local fujian_log = sgs.LogMessage()
				fujian_log.type = "$fujian_to_all_log"
				fujian_log.from = player
				fujian_log.to:append(random_target)
				fujian_log.arg = self:objectName()
				room:sendLog(fujian_log)
				
				local show_card_log = sgs.LogMessage()
				show_card_log.type = "$fujian_show_card"
				show_card_log.from = player
				show_card_log.to:append(random_target)
				show_card_log.card_str = table.concat(being_show_cards, "+")
				show_card_log.arg = self:objectName()
				room:sendLog(show_card_log, player)
				
				room:doAnimate(1, player:objectName(), random_target:objectName())
				local json_value = {
					"",
					false,
					being_show_cards,
				}
				room:doNotify(player, sgs.CommandType.S_COMMAND_SHOW_ALL_CARDS, json.encode(json_value))
			end
		end
	end
}
caoying:addSkill(fujian)
caoying:addRelateSkill("jianxiong")
caoying:addRelateSkill("xingshang")

jixian_ban = sgs.CreateProhibitSkill{
	name = "#jixian_ban",
	is_prohibited = function(self, from, to, card)
		return to:getMark("juexiang_time") > 0 and card:getSuit() == sgs.Card_Club and from:objectName() ~= to:objectName()
	end
}
if not sgs.Sanguosha:getSkill("#jixian_ban") then skills:append(jixian_ban) end
jixian_mark_clear = sgs.CreateTriggerSkill{
	name = "jixian_mark_clear",
	global = true,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and player:getMark("juexiang_time") > 0 then
				room:setPlayerMark(player, "juexiang_time", 0)
			end
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("jixian_mark_clear") then skills:append(jixian_mark_clear) end

DMG_card_recorder = sgs.CreateTriggerSkill{  --记录角色受到的上一次对其造成伤害的卡牌
	name = "DMG_card_recorder",
	global = true,
	events = {sgs.Damaged},
	on_trigger = function(self, event, splayer, data, room)
		local card = data:toDamage().card
		if card and not (card:isKindOf("DelayedTrick") or card:isKindOf("EquipCard") or card:isKindOf("SkillCard")) then
			room:setPlayerProperty(splayer, "DCR", sgs.QVariant(data:toDamage().card:objectName()))
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("DMG_card_recorder") then skills:append(DMG_card_recorder) end

liuye = sgs.General(extension_guandu, "liuye", "wei", "3", true)
polu = sgs.CreateTriggerSkill{
	name = "polu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and not (player:getWeapon() and player:getWeapon():isKindOf("ThunderclapCatapult"))
				and room:getTag("TC_ID"):toInt() > 0 and player:hasEquipArea(0) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local card = sgs.Sanguosha:getCard(room:getTag("TC_ID"):toInt())
				room:useCard(sgs.CardUseStruct(card, player, player))
			end
		else
			for i = 1, data:toDamage().damage do
				if not (player:getWeapon() and player:getWeapon():isKindOf("ThunderclapCatapult")) then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:drawCards(player, 1, self:objectName())
				end
			end
		end
		return false
	end
}
liuye:addSkill(polu)
choulveVS = sgs.CreateZeroCardViewAsSkill{
	name = "choulve",
	response_or_use = true,
	response_pattern = "@@choulve",
	view_as = function(self, card)
		local DCR = sgs.Self:property("DCR"):toString()
		local skillcard = sgs.Sanguosha:cloneCard(DCR, sgs.Card_NoSuit, -1)
		skillcard:setSkillName("_choulve")
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end
}
choulve = sgs.CreatePhaseChangeSkill{
	name = "choulve",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = choulveVS,
	on_phasechange = function(self, player)
		local room, DCR = player:getRoom(), player:property("DCR"):toString()
		if player:getPhase() ~= sgs.Player_Play then return false end
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isNude() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local to = room:askForPlayerChosen(player, targets, self:objectName(), "choulve-invoke", true, true)
			if to then
				room:broadcastSkillInvoke(self:objectName())
				local card = room:askForCard(to, "..", "@choulve-give:" .. player:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					room:obtainCard(player, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, to:objectName(), player:objectName(), self:objectName(), ""), false)
					if DCR == "" then return false end
					local DCR_card = sgs.Sanguosha:cloneCard(DCR, sgs.Card_NoSuit, -1)
					if DCR_card:isAvailable(player) then
						if DCR_card:targetFixed() then
							DCR_card:setSkillName("_choulve")
							if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("CL_askForUseCard:" .. DCR)) then
								room:useCard(sgs.CardUseStruct(DCR_card, player, player), true)
							end
						else
							room:askForUseCard(player, "@@choulve", "@choulve:" .. DCR, -1, sgs.Card_MethodUse, false)
						end
					end
				end
			end
		end
		return false
	end
}
liuye:addSkill(choulve)
xiahoubawitholshensu = sgs.General(extension, "xiahoubawitholshensu", "shu", "4", true)
local function BaobianChange_with_ol_shensu(room, player, hp, skill_name)
	local baobian_skills = player:getTag("BaobianWithOlShensuSkills"):toString():split("+")
	if player:getHp() <= hp then
		if not table.contains(baobian_skills, skill_name) then
			room:notifySkillInvoked(player, "baobian_with_ol_shensu")
			if player:getHp() == hp then
				room:broadcastSkillInvoke("baobian", 4 - hp)
			end
			table.insert(BaobianWithOlShensu_acquired_skills, skill_name)
			table.insert(baobian_skills, skill_name)
		end
	else
		if table.contains(baobian_skills, skill_name) then
			table.insert(BaobianWithOlShensu_detached_skills, "-"..skill_name)
			table.removeOne(baobian_skills, skill_name)
		end
	end
	player:setTag("BaobianWithOlShensuSkills", sgs.QVariant(table.concat(baobian_skills, "+")))
end
baobian_with_ol_shensu = sgs.CreateTriggerSkill{
	name = "baobian_with_ol_shensu",
	events = {sgs.GameStart, sgs.HpChanged, sgs.MaxHpChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local baobian_skills = player:getTag("BaobianWithOlShensuSkills"):toString():split("+")
				local detachList = {}
				for _, skill_name in ipairs(baobian_skills) do
					table.insert(detachList, "-"..skill_name)
				end
				room:handleAcquireDetachSkills(player, table.concat(detachList,"|"))
				player:setTag("BaobianWithOlShensuSkills", sgs.QVariant())
			end
			return false
		elseif event == sgs.EventAcquireSkill then
			if data:toString() ~= self:objectName() then return false end
		end
		if not player:isAlive() or not player:hasSkill(self:objectName(), true) then return false end
		BaobianWithOlShensu_acquired_skills = {}
		BaobianWithOlShensu_detached_skills = {}
		BaobianChange_with_ol_shensu(room, player, 1, "ol_shensu")
		BaobianChange_with_ol_shensu(room, player, 2, "paoxiao")
		BaobianChange_with_ol_shensu(room, player, 3, "tiaoxin")
		if #BaobianWithOlShensu_acquired_skills > 0 or #BaobianWithOlShensu_detached_skills > 0 then
			local final_skill_list = {}
			for _,item in ipairs(BaobianWithOlShensu_acquired_skills) do
				table.insert(final_skill_list, item)
			end
			for _,item in ipairs(BaobianWithOlShensu_detached_skills) do
				table.insert(final_skill_list, item)
			end
			room:handleAcquireDetachSkills(player, table.concat(final_skill_list,"|"))
		end
		return false
	end
}
xiahoubawitholshensu:addSkill(baobian_with_ol_shensu)

no_bug_sunquan = sgs.General(extension, "no_bug_sunquan$", "wu", "4", true)
jiuyuan_no_bug = sgs.CreateTriggerSkill{
	name = "jiuyuan_no_bug$",
	events = {sgs.PreCardUsed},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		local no_bug_sunquans = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasLordSkill(self:objectName()) then
				no_bug_sunquans:append(p)
			end
		end
		if not no_bug_sunquans:isEmpty() then
			local _data = sgs.QVariant()
			for _, p in sgs.qlist(no_bug_sunquans) do
				_data:setValue(p)
				if use.card and use.card:isKindOf("Peach") and player:objectName() ~= p:objectName() and use.to:contains(player) and player:getHp() > p:getHp() and room:askForSkillInvoke(player, self:objectName(), _data) then
					room:broadcastSkillInvoke(self:objectName())
					room:sendCompulsoryTriggerLog(p, self:objectName())
					room:notifySkillInvoked(p, self:objectName())
					room:recover(p, sgs.RecoverStruct(p))
					use.to = sgs.SPlayerList()
					data:setValue(use)
					player:drawCards(1, self:objectName())
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getKingdom() == "wu"
	end
}
no_bug_sunquan:addSkill("zhiheng")
no_bug_sunquan:addSkill(jiuyuan_no_bug)

MusoHalberdSkill = sgs.CreateTriggerSkill{
	name = "MusoHalberdSkill",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.to and damage.to:getMark("Equips_of_Others_Nullified_to_You") == 0
		and damage.card and damage.card:isKindOf("Slash")
		then
			local choices = {}
			table.insert(choices, "muso_halberd_draw")
			if damage.to:isAlive() and not damage.to:isNude() then
				table.insert(choices, "muso_halberd_discard")
			end
			table.insert(choices, "cancel")
			local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
			if choice == "muso_halberd_draw" then
				local msg = sgs.LogMessage()
				msg.type = "#MusoHalberdSkill_log"
				msg.from = player
				room:sendLog(msg)
				ChoiceLog(player, choice)
				player:drawCards(1, self:objectName())
			elseif choice == "muso_halberd_discard" then
				local msg = sgs.LogMessage()
				msg.type = "#MusoHalberdSkill_log"
				msg.from = player
				room:sendLog(msg)
				ChoiceLog(player, choice)
				local id = room:askForCardChosen(player, damage.to, "he", self:objectName())
				if id ~= -1 then
					room:throwCard(sgs.Sanguosha:getCard(id), damage.to, player)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getWeapon() and target:getWeapon():isKindOf("MusoHalberd")
	end
}
if not sgs.Sanguosha:getSkill("MusoHalberdSkill") then skills:append(MusoHalberdSkill) end

MusoHalberd = sgs.CreateWeapon{
	name = "muso_halberd",
	class_name = "MusoHalberd",
	suit = sgs.Card_Diamond,
	number = 12,
	range = 4,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("MusoHalberdSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "MusoHalberdSkill")
	end
}
MusoHalberd:setParent(hulaoguan_card)

LongPheasantTailFeatherPurpleGoldCrownSkill = sgs.CreateTriggerSkill{
	name = "LongPheasantTailFeatherPurpleGoldCrownSkill",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		local change = data:toPhaseChange()
		if change.to and change.to == sgs.Player_Start then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "LongPheasantTailFeatherPurpleGoldCrown-invoke", true, true)
			if target then
				room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("LongPheasantTailFeatherPurpleGoldCrown")
	end
}
if not sgs.Sanguosha:getSkill("LongPheasantTailFeatherPurpleGoldCrownSkill") then skills:append(LongPheasantTailFeatherPurpleGoldCrownSkill) end

LongPheasantTailFeatherPurpleGoldCrown = sgs.CreateTreasure{
	name = "long_pheasant_tail_feather_purple_gold_crown",
	class_name = "LongPheasantTailFeatherPurpleGoldCrown",
	suit = sgs.Card_Diamond,
	number = 1,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("LongPheasantTailFeatherPurpleGoldCrownSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "LongPheasantTailFeatherPurpleGoldCrownSkill")
	end
}
LongPheasantTailFeatherPurpleGoldCrown:setParent(hulaoguan_card)

function lua_armor_null_check(player)
	if #player:getTag("Qinggang"):toStringList() > 0 or player:getMark("Armor_Nullified") > 0 or player:getMark("Equips_Nullified_to_Yourself") > 0 then
		return true
	end
	return false
end

RedCottonHundredFlowerRobeSkill = sgs.CreateTriggerSkill{
	name = "RedCottonHundredFlowerRobeSkill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if not lua_armor_null_check(player) and damage.nature ~= sgs.DamageStruct_Normal then
			local msg = sgs.LogMessage()
			msg.type = "#RedCottonHundredFlowerRobeProtect"
			msg.from = player
			msg.arg = damage.damage
			if damage.nature == sgs.DamageStruct_Fire then
				msg.arg2 = "fire_nature"
			elseif damage.nature == sgs.DamageStruct_Thunder then
				msg.arg2 = "thunder_nature"
			end
			room:sendLog(msg)
			return true
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getArmor() and target:getArmor():isKindOf("RedCottonHundredFlowerRobe")
	end
}
if not sgs.Sanguosha:getSkill("RedCottonHundredFlowerRobeSkill") then skills:append(RedCottonHundredFlowerRobeSkill) end

RedCottonHundredFlowerRobe = sgs.CreateArmor{
	name = "red_cotton_hundred_flower_robe",
	class_name = "RedCottonHundredFlowerRobe",
	suit = sgs.Card_Club,
	number = 1,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("RedCottonHundredFlowerRobeSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "RedCottonHundredFlowerRobeSkill")
	end
}
RedCottonHundredFlowerRobe:setParent(hulaoguan_card)

LinglongLionRoughBandSkill = sgs.CreateTriggerSkill{
	name = "LinglongLionRoughBandSkill",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if not lua_armor_null_check(player) and use.from and use.from:objectName() ~= player:objectName() and use.to:length() == 1
		and use.to:contains(player) and use.card and not use.card:isKindOf("SkillCard") and room:askForSkillInvoke(player, self:objectName(), data)
		then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.who = player
			judge.reason = self:objectName()
			judge.good = true
			room:judge(judge)
			if judge:isGood() then
				local nullified_list = use.nullified_list
				table.insert(nullified_list, player:objectName())
				use.nullified_list = nullified_list
				data:setValue(use)
				local msg = sgs.LogMessage()
				msg.type = "#LinglongLionRoughBandProtect"
				msg.from = player
				room:sendLog(msg)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getArmor() and target:getArmor():isKindOf("LinglongLionRoughBand")
	end
}
if not sgs.Sanguosha:getSkill("LinglongLionRoughBandSkill") then skills:append(LinglongLionRoughBandSkill) end

LinglongLionRoughBand = sgs.CreateArmor{
	name = "linglong_lion_rough_band",
	class_name = "LinglongLionRoughBand",
	suit = sgs.Card_Club,
	number = 2,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("LinglongLionRoughBandSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "LinglongLionRoughBandSkill")
	end
}
LinglongLionRoughBand:setParent(hulaoguan_card)

local LinglongLionRoughBand2 = LinglongLionRoughBand:clone()
LinglongLionRoughBand2:setSuit(sgs.Card_Spade)
LinglongLionRoughBand2:setNumber(2)
LinglongLionRoughBand2:setParent(hulaoguan_card)

move_equips_to_no_equips_area_cheacker = sgs.CreateTriggerSkill{
	name = "move_equips_to_no_equips_area_cheacker",
	global = true,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.to and move.to_place and move.to_place == sgs.Player_PlaceEquip then
			for _,id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("EquipCard") then
					local equip_index = card:getRealCard():toEquipCard():location()
					if not move.to:hasEquipArea(equip_index) then
						move.card_ids:removeOne(id)
						room:moveCardTo(card, nil, sgs.Player_DiscardPile)
						local msg = sgs.LogMessage()
						msg.type = "#Move_to_no_equip_area_log"
						
						--Player類型轉至ServerPlayer
						local log_player
						for _,p in sgs.qlist(room:getAlivePlayers()) do
							if p:objectName() == move.to:objectName() then
								log_player = p
							end
						end
						msg.from = log_player
						
						msg.arg = "EquipArea_"..equip_index
						msg.card_str = card:toString()
						room:sendLog(msg)
					end
				end
			end
			data:setValue(move)
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("move_equips_to_no_equips_area_cheacker") then skills:append(move_equips_to_no_equips_area_cheacker) end

majun = sgs.General(extension_mobile, "majun", "wei", "3", true)
jingxieCard = sgs.CreateSkillCard{
	name = "jingxie",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:showCard(source, self:getSubcards():first())
		local jingxie_equip_card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if jingxie_equip_card:isKindOf("Crossbow") and source:getMark("jingxie_Crossbow_id_"..self:getSubcards():first()) == 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p, "jingxie_Crossbow_id_"..self:getSubcards():first(), 1)
				room:setPlayerMark(p, "@jingxie_Crossbow_"..jingxie_equip_card:getSuitString().."_"..jingxie_equip_card:getNumberString(), 1)
			end
			local log = sgs.LogMessage()
			log.type = "#jingxie_Crossbow_enhance"
			log.from = source
			log.card_str = tostring(self:getSubcards():first())
			room:sendLog(log)
		elseif jingxie_equip_card:isKindOf("EightDiagram") and source:getMark("jingxie_EightDiagram_id_"..self:getSubcards():first()) == 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p, "jingxie_EightDiagram_id_"..self:getSubcards():first(), 1)
				room:setPlayerMark(p, "@jingxie_EightDiagram_"..jingxie_equip_card:getSuitString().."_"..jingxie_equip_card:getNumberString(), 1)
			end
			local log = sgs.LogMessage()
			log.type = "#jingxie_EightDiagram_enhance"
			log.from = source
			log.card_str = tostring(self:getSubcards():first())
			room:sendLog(log)
		elseif jingxie_equip_card:isKindOf("RenwangShield") and source:getMark("jingxie_RenwangShield_id_"..self:getSubcards():first()) == 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p, "jingxie_RenwangShield_id_"..self:getSubcards():first(), 1)
				room:setPlayerMark(p, "@jingxie_RenwangShield_"..jingxie_equip_card:getSuitString().."_"..jingxie_equip_card:getNumberString(), 1)
			end
			local log = sgs.LogMessage()
			log.type = "#jingxie_RenwangShield_enhance"
			log.from = source
			log.card_str = tostring(self:getSubcards():first())
			room:sendLog(log)
		elseif jingxie_equip_card:isKindOf("SilverLion") and source:getMark("jingxie_SilverLion_id_"..self:getSubcards():first()) == 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p, "jingxie_SilverLion_id_"..self:getSubcards():first(), 1)
				room:setPlayerMark(p, "@jingxie_SilverLion_"..jingxie_equip_card:getSuitString().."_"..jingxie_equip_card:getNumberString(), 1)
			end
			local log = sgs.LogMessage()
			log.type = "#jingxie_SilverLion_enhance"
			log.from = source
			log.card_str = tostring(self:getSubcards():first())
			room:sendLog(log)
		elseif jingxie_equip_card:isKindOf("Vine") and source:getMark("jingxie_Vine_id_"..self:getSubcards():first()) == 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p, "jingxie_Vine_id_"..self:getSubcards():first(), 1)
				room:setPlayerMark(p, "@jingxie_Vine_"..jingxie_equip_card:getSuitString().."_"..jingxie_equip_card:getNumberString(), 1)
			end
			local log = sgs.LogMessage()
			log.type = "#jingxie_Vine_enhance"
			log.from = source
			log.card_str = tostring(self:getSubcards():first())
			room:sendLog(log)
		end
	end
}
jingxieVS = sgs.CreateOneCardViewAsSkill{
	name = "jingxie",
	view_filter = function(self, card)
		return card:isKindOf("Crossbow") or card:isKindOf("Armor")
	end,
	view_as = function(self, card)
		local skillcard = jingxieCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
jingxie = sgs.CreateTriggerSkill{
	name = "jingxie",
	view_as_skill = jingxieVS,
	events = {sgs.EnterDying},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		if player:hasSkill(self:objectName()) then
			local card_id = room:askForCard(player, "Armor", "@jingxie", sgs.QVariant(), sgs.Card_MethodRecast)
			if card_id then
				room:moveCardTo(card_id, player, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), ""))
				room:broadcastSkillInvoke("@recast")
				local log = sgs.LogMessage()
				log.type = "#UseCard_Recast"
				log.from = player
				log.card_str = card_id:toString()
				room:sendLog(log)
				player:drawCards(1, "recast")
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1 - player:getHp()
				room:recover(player, recover)
			end
		end
		return false
	end
}
majun:addSkill(jingxie)
jingxie_armor_equip_buff = sgs.CreateTriggerSkill{
	name = "jingxie_armor_equip_buff",
	global = true,
	events = {sgs.StartJudge, sgs.SlashEffected, sgs.BeforeCardsMove, sgs.ChainStateChange},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.StartJudge and not lua_armor_null_check(player) and player:getArmor() and player:getArmor():isKindOf("EightDiagram") and player:getMark("jingxie_EightDiagram_id_"..player:getArmor():getEffectiveId()) > 0 then
			local judge = data:toJudge()
			if judge.reason == "eight_diagram" then
				judge.pattern = ".|spade"
				judge.good = false
				local log = sgs.LogMessage()
				log.type = "#jingxie_EightDiagram_armor_buff"
				log.from = player
				room:sendLog(log)
			end
		end
		if event == sgs.SlashEffected and not lua_armor_null_check(player) and player:getArmor() and player:getArmor():isKindOf("RenwangShield") and player:getMark("jingxie_RenwangShield_id_"..player:getArmor():getEffectiveId()) > 0 then
			local slasheffect = data:toSlashEffect()
			if slasheffect.slash and slasheffect.slash:getSuit() == sgs.Card_Heart and not slasheffect.from:hasWeapon("qinggang_sword") then
				
				local logmsg = sgs.LogMessage()
				logmsg.type = "#jingxie_RenwangShield_armor_buff"
				logmsg.from = player
				room:sendLog(logmsg)
				
				local log = sgs.LogMessage()
				log.type = "#ArmorNullify"
				log.from = player
				log.arg = "renwang_shield"
				log.arg2 = slasheffect.slash:objectName()
				room:sendLog(log)
				return true
			end
		end
		if event == sgs.BeforeCardsMove and player:getArmor() and player:getArmor():isKindOf("SilverLion") and player:getMark("jingxie_SilverLion_id_"..player:getArmor():getEffectiveId()) > 0 and player:isWounded() then
			local move = data:toMoveOneTime()
			
			local invoke = false
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("SilverLion") then
					invoke = true
				end
			end
			
			if invoke and move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
				local log = sgs.LogMessage()
				log.type = "#jingxie_SilverLion_armor_buff"
				log.from = player
				room:sendLog(log)
				player:drawCards(2, self:objectName())
			end
		end
		if event == sgs.ChainStateChange and not lua_armor_null_check(player) and player:getArmor() and player:getArmor():isKindOf("Vine") and player:getMark("jingxie_Vine_id_"..player:getArmor():getEffectiveId()) > 0 then
			if not player:isChained() then
				local log = sgs.LogMessage()
				log.type = "#jingxie_Vine_armor_buff"
				log.from = player
				room:sendLog(log)
				return true
			end
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("jingxie_armor_equip_buff") then skills:append(jingxie_armor_equip_buff) end
qiaosiCard = sgs.CreateSkillCard{
	name = "qiaosi",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local choice_counts = 3
		local qiaosi_cards = {}
		if choice_counts > 0 then
			local qiaosi_two_trick = room:askForChoice(source, "qiaosi_two_trick_choice", "qiaosi_yes+qiaosi_no")
			if qiaosi_two_trick == "qiaosi_yes" then
				choice_counts = choice_counts - 1
				local qiaosi_two_trick_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") and not table.contains(qiaosi_cards, id) and qiaosi_two_trick_count < 2 then
						qiaosi_two_trick_count = qiaosi_two_trick_count + 1
						table.insert(qiaosi_cards, id)
					end
				end
			end
		end
		
		if choice_counts > 0 then
			local qiaosi_one_equip = room:askForChoice(source, "qiaosi_one_equip_choice", "qiaosi_yes+qiaosi_no")
			if qiaosi_one_equip == "qiaosi_yes" then
				choice_counts = choice_counts - 1
				local qiaosi_one_equip_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") and not table.contains(qiaosi_cards, id) and qiaosi_one_equip_count < 1 then
						qiaosi_one_equip_count = qiaosi_one_equip_count + 1
						table.insert(qiaosi_cards, id)
					end
				end
			end
		end
		
		if choice_counts > 0 then
			local qiaosi_one_analeptic_or_slash = room:askForChoice(source, "qiaosi_one_analeptic_or_slash_choice", "qiaosi_yes+qiaosi_no")
			if qiaosi_one_analeptic_or_slash == "qiaosi_yes" then
				choice_counts = choice_counts - 1
				local qiaosi_one_analeptic_or_slash_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if (sgs.Sanguosha:getCard(id):isKindOf("Analeptic") or sgs.Sanguosha:getCard(id):isKindOf("Slash")) and not table.contains(qiaosi_cards, id) and qiaosi_one_analeptic_or_slash_count < 1 then
						qiaosi_one_analeptic_or_slash_count = qiaosi_one_analeptic_or_slash_count + 1
						table.insert(qiaosi_cards, id)
					end
				end
			end
		end
		
		if choice_counts > 0 then
			local qiaosi_one_peach_or_jink = room:askForChoice(source, "qiaosi_one_peach_or_jink_choice", "qiaosi_yes+qiaosi_no")
			if qiaosi_one_peach_or_jink == "qiaosi_yes" then
				choice_counts = choice_counts - 1
				local qiaosi_one_peach_or_jink_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if (sgs.Sanguosha:getCard(id):isKindOf("Peach") or sgs.Sanguosha:getCard(id):isKindOf("Jink")) and not table.contains(qiaosi_cards, id) and qiaosi_one_peach_or_jink_count < 1 then
						qiaosi_one_peach_or_jink_count = qiaosi_one_peach_or_jink_count + 1
						table.insert(qiaosi_cards, id)
					end
				end
			end
		end
		
		if choice_counts > 0 then
			local qiaosi_one_trick = room:askForChoice(source, "qiaosi_one_trick_choice", "qiaosi_yes+qiaosi_no")
			if qiaosi_one_trick == "qiaosi_yes" then
				choice_counts = choice_counts - 1
				local qiaosi_one_trick_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") and not table.contains(qiaosi_cards, id) and qiaosi_one_trick_count < 1 then
						qiaosi_one_trick_count = qiaosi_one_trick_count + 1
						table.insert(qiaosi_cards, id)
					end
				end
			end
		end
		
		if choice_counts > 0 then
			local qiaosi_two_equip = room:askForChoice(source, "qiaosi_two_equip_choice", "qiaosi_yes+qiaosi_no")
			if qiaosi_two_equip == "qiaosi_yes" then
				choice_counts = choice_counts - 1
				local qiaosi_two_equip_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") and not table.contains(qiaosi_cards, id) and qiaosi_two_equip_count < 2 then
						qiaosi_two_equip_count = qiaosi_two_equip_count + 1
						table.insert(qiaosi_cards, id)
					end
				end
			end
		end
		
		local trick_card_counts = 0
		local equip_card_counts = 0
		for _,id in ipairs(qiaosi_cards) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("TrickCard") then
				trick_card_counts = trick_card_counts + 1
			end
			if card:isKindOf("EquipCard") then
				equip_card_counts = equip_card_counts + 1
			end
		end
		if trick_card_counts >= 3 then
			local qiaosi_cards_temp = {}
			for _,id in ipairs(qiaosi_cards) do
				if not sgs.Sanguosha:getCard(id):isKindOf("TrickCard") and not table.contains(qiaosi_cards_temp, id) then
					table.insert(qiaosi_cards_temp, id)
				end
			end
			qiaosi_cards = qiaosi_cards_temp
			local qiaosi_trick_count = 0
			for _,id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") and not table.contains(qiaosi_cards, id) and qiaosi_trick_count < 2 then
					qiaosi_trick_count = qiaosi_trick_count + 1
					table.insert(qiaosi_cards, id)
				end
			end
			local qiaosi_basic_count = 0
			for _,id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") and not table.contains(qiaosi_cards, id) and qiaosi_basic_count < 1 then
					qiaosi_basic_count = qiaosi_basic_count + 1
					table.insert(qiaosi_cards, id)
				end
			end
		end
		if equip_card_counts >= 3 then
			local qiaosi_cards_temp = {}
			for _,id in ipairs(qiaosi_cards) do
				if not sgs.Sanguosha:getCard(id):isKindOf("EquipCard") and not table.contains(qiaosi_cards_temp, id) then
					table.insert(qiaosi_cards_temp, id)
				end
			end
			qiaosi_cards = qiaosi_cards_temp
			local qiaosi_equip_count = 0
			for _,id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") and not table.contains(qiaosi_cards, id) and qiaosi_equip_count < 2 then
					qiaosi_equip_count = qiaosi_equip_count + 1
					table.insert(qiaosi_cards, id)
				end
			end
			local qiaosi_basic_count = 0
			for _,id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") and not table.contains(qiaosi_cards, id) and qiaosi_basic_count < 1 then
					qiaosi_basic_count = qiaosi_basic_count + 1
					table.insert(qiaosi_cards, id)
				end
			end
		end
		
		if #qiaosi_cards > 0 then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _,id in ipairs(qiaosi_cards) do
				dummy:addSubcard(id)
			end
			room:obtainCard(source, dummy, true)
			
			local choice = room:askForChoice(source, self:objectName(), "qiaosi_throw+qiaosi_give")
			if choice == "qiaosi_throw" then
				room:askForDiscard(source, self:objectName(), #qiaosi_cards, #qiaosi_cards, false, true)
			else
				local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(), "qiaosi-invoke", false, true)
				local qiaosi_give_cards = room:askForExchange(source, self:objectName(), #qiaosi_cards, #qiaosi_cards, true, "qiaosi_exchange")
				if target and qiaosi_give_cards then
					room:obtainCard(target, qiaosi_give_cards, false)
				end
			end
		end
	end
}
qiaosi = sgs.CreateZeroCardViewAsSkill{
	name = "qiaosi",
	view_as = function(self, cards)
		return qiaosiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#qiaosi")
	end
}
majun:addSkill(qiaosi)

game_mode_06_ol_added_god_general_weapon_add = sgs.CreateTriggerSkill{
	name = "game_mode_06_ol_added_god_general_weapon_add",
	global = true,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
		if room:getMode() == "06_ol" then
			local draw_pile_god_sword
			for _,id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):isKindOf("GodSword") then
					draw_pile_god_sword = sgs.Sanguosha:getCard(id)
				end
			end
			if draw_pile_god_sword then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getGeneralName() == "new_godzhaoyun" or p:getGeneral2Name() == "new_godzhaoyun" then
						room:moveCardTo(draw_pile_god_sword, nil, p, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, p:objectName(), "gamerule", ""))
					end
				end
			end
		end
		return false
	end
}
if not sgs.Sanguosha:getSkill("game_mode_06_ol_added_god_general_weapon_add") then skills:append(game_mode_06_ol_added_god_general_weapon_add) end

zhangqiying = sgs.General(extension_pray, "zhangqiying", "qun", "3", false)
falu = sgs.CreateTriggerSkill{
	name = "falu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			room:broadcastSkillInvoke(self:objectName())
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:notifySkillInvoked(player, self:objectName())
			room:setPlayerMark(player, "@falu_ziwei", 1)
			room:setPlayerMark(player, "@falu_houtu", 1)
			room:setPlayerMark(player, "@falu_yuqing", 1)
			room:setPlayerMark(player, "@falu_gouchen", 1)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:hasSkill(self:objectName()) and move.from and move.from:objectName() == player:objectName()
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
			and move.to_place == sgs.Player_DiscardPile
			then
				local play_vo = false
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:getSuit() == sgs.Card_Spade and player:getMark("@falu_ziwei") == 0 then
						play_vo = true
						room:setPlayerMark(player, "@falu_ziwei", 1)
					elseif card:getSuit() == sgs.Card_Club and player:getMark("@falu_houtu") == 0 then
						play_vo = true
						room:setPlayerMark(player, "@falu_houtu", 1)
					elseif card:getSuit() == sgs.Card_Heart and player:getMark("@falu_yuqing") == 0 then
						play_vo = true
						room:setPlayerMark(player, "@falu_yuqing", 1)
					elseif card:getSuit() == sgs.Card_Diamond and player:getMark("@falu_gouchen") == 0 then
						play_vo = true
						room:setPlayerMark(player, "@falu_gouchen", 1)
					end
				end
				if play_vo then
					room:broadcastSkillInvoke(self:objectName())
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:notifySkillInvoked(player, self:objectName())
				end
			end
		end
		return false
	end
}
zhangqiying:addSkill(falu)
zhenyiVS = sgs.CreateOneCardViewAsSkill{
	name = "zhenyi",
	view_filter = function(self, card)
		return not card:isEquipped() and not sgs.Self:isJilei(card)
	end,
	response_or_use = true,
	view_as = function(self, card)
		local skillcard = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
		skillcard:addSubcard(card:getEffectiveId())
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@zhenyi"
	end
}
zhenyi = sgs.CreateTriggerSkill{
	name = "zhenyi",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = zhenyiVS,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.AskForRetrial, sgs.AskForPeaches, sgs.DamageCaused, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart or event == sgs.EventAcquireSkill then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:handleAcquireDetachSkills(p, "#zhenyi_spade_5_judge|#zhenyi_heart_5_judge", false)
			end
		elseif event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if player:hasSkill(self:objectName()) and player:getMark("@falu_ziwei") > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
				room:setPlayerMark(player, "@falu_ziwei", 0)
				local choice = room:askForChoice(player, self:objectName(), "zhenyi_Spade+zhenyi_Heart")
				if choice == "zhenyi_Spade" then
					room:setCardFlag(judge.card, "zhenyi_spade_5_judge")
					local cardlists = sgs.CardList()
					cardlists:append(judge.card)
					room:filterCards(judge.who, cardlists, true)
					judge:updateResult()
					
					--已下只對判定條件有judge:isGood()有效
--					room:handleAcquireDetachSkills(judge.who, "#zhenyi_spade_5_judge", false)
--					local cardlists = sgs.CardList()
--					cardlists:append(judge.card)
--					room:filterCards(judge.who, cardlists, true)
--					judge:updateResult()
--					room:handleAcquireDetachSkills(judge.who, "-#zhenyi_spade_5_judge", false)
				elseif choice == "zhenyi_Heart" then
					room:setCardFlag(judge.card, "zhenyi_heart_5_judge")
					local cardlists = sgs.CardList()
					cardlists:append(judge.card)
					room:filterCards(judge.who, cardlists, true)
					judge:updateResult()
					
					--已下只對判定條件有judge:isGood()有效
--					room:handleAcquireDetachSkills(judge.who, "#zhenyi_heart_5_judge", false)
--					local cardlists = sgs.CardList()
--					cardlists:append(judge.card)
--					room:filterCards(judge.who, cardlists, true)
--					judge:updateResult()
--					room:handleAcquireDetachSkills(judge.who, "-#zhenyi_heart_5_judge", false)
				end
			end
		elseif event == sgs.AskForPeaches then
			local dying = data:toDying()
			if dying.who and dying.who:objectName() == player:objectName() and dying.who:hasSkill(self:objectName()) and dying.who:getMark("@falu_houtu") > 0 then
				if room:askForUseCard(dying.who, "@zhenyi", "@zhenyi", -1, sgs.Card_MethodNone) then
					room:setPlayerMark(dying.who, "@falu_houtu", 0)
				end
				
				--以下木馬中的牌看不到
				--local card = room:askForCard(dying.who, ".|.|.|hand", "@zhenyi", data, sgs.Card_MethodNone)
				--if card then
				--	room:setPlayerMark(dying.who, "@falu_houtu", 0)
				--	local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
				--	peach:addSubcard(card:getEffectiveId())
				--	peach:setSkillName(self:objectName())
				--	room:useCard(sgs.CardUseStruct(peach, dying.who, dying.who))
				--end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.from and damage.from:hasSkill(self:objectName()) and damage.from:objectName() == player:objectName() and damage.by_user and not damage.chain and not damage.transfer and damage.from:getMark("@falu_yuqing") > 0 and room:askForSkillInvoke(damage.from, self:objectName(), data) then
				room:setPlayerMark(damage.from, "@falu_yuqing", 0)
				room:broadcastSkillInvoke(self:objectName())
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|black"
				judge.who = damage.from
				judge.reason = self:objectName()
				judge.good = true
				room:judge(judge)
				if judge:isGood() then
					local log = sgs.LogMessage()
					log.type = "$hanyong"
					log.from = damage.from
					if damage.card then
						log.card_str = damage.card:toString()
					else
						log.card_str = -1
					end
					log.arg = self:objectName()
					room:sendLog(log)
					damage.damage = damage.damage + 1
					data:setValue(damage)
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:hasSkill(self:objectName()) and damage.to:objectName() == player:objectName() and damage.to:getMark("@falu_gouchen") > 0 and damage.nature ~= sgs.DamageStruct_Normal
			and room:askForSkillInvoke(damage.to, self:objectName(), data) then
				room:setPlayerMark(damage.to, "@falu_gouchen", 0)
				room:broadcastSkillInvoke(self:objectName())
				local zhenyi_cards = {}
				local zhenyi_basic_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") and zhenyi_basic_count < 1 then
						zhenyi_basic_count = zhenyi_basic_count + 1
						table.insert(zhenyi_cards, id)
					end
				end
				local zhenyi_trick_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") and zhenyi_trick_count < 1 then
						zhenyi_trick_count = zhenyi_trick_count + 1
						table.insert(zhenyi_cards, id)
					end
				end
				local zhenyi_equip_count = 0
				for _,id in sgs.qlist(room:getDrawPile()) do
					if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") and zhenyi_equip_count < 1 then
						zhenyi_equip_count = zhenyi_equip_count + 1
						table.insert(zhenyi_cards, id)
					end
				end
				
				if #zhenyi_cards > 0 then
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					for _,id in ipairs(zhenyi_cards) do
						dummy:addSubcard(id)
					end
					room:obtainCard(damage.to, dummy, false)
				end
			end
		end
		return false
	end
}
zhangqiying:addSkill(zhenyi)
zhenyi_spade_5_judge = sgs.CreateFilterSkill{
	name = "#zhenyi_spade_5_judge",
	view_filter = function(self, to_select)
		return to_select:hasFlag("zhenyi_spade_5_judge")
	end,
	view_as = function(self, card)
		local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		new_card:setSkillName("zhenyi")
		new_card:setSuit(sgs.Card_Spade)
		new_card:setNumber(5)
		new_card:setModified(true)
		return new_card
	end
}
if not sgs.Sanguosha:getSkill("#zhenyi_spade_5_judge") then skills:append(zhenyi_spade_5_judge) end
zhenyi_heart_5_judge = sgs.CreateFilterSkill{
	name = "#zhenyi_heart_5_judge",
	view_filter = function(self, to_select)
		return to_select:hasFlag("zhenyi_heart_5_judge")
	end,
	view_as = function(self, card)
		local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		new_card:setSkillName("zhenyi")
		new_card:setSuit(sgs.Card_Heart)
		new_card:setNumber(5)
		new_card:setModified(true)
		return new_card
	end
}
if not sgs.Sanguosha:getSkill("#zhenyi_heart_5_judge") then skills:append(zhenyi_heart_5_judge) end
clear_zhenyi_judge_card_flag = sgs.CreateTriggerSkill{
	name = "clear_zhenyi_judge_card_flag",
	global = true,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		for _, id in sgs.qlist(move.card_ids) do
			if sgs.Sanguosha:getCard(id):hasFlag("zhenyi_spade_5_judge") then
				room:setCardFlag(sgs.Sanguosha:getCard(id), "-zhenyi_spade_5_judge")
			end
			if sgs.Sanguosha:getCard(id):hasFlag("zhenyi_heart_5_judge") then
				room:setCardFlag(sgs.Sanguosha:getCard(id), "-zhenyi_heart_5_judge")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
if not sgs.Sanguosha:getSkill("clear_zhenyi_judge_card_flag") then skills:append(clear_zhenyi_judge_card_flag) end
dianhua = sgs.CreatePhaseChangeSkill{
	name = "dianhua",
	frequency = sgs.Skill_Frequent,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		local num = player:getMark("@falu_ziwei") + player:getMark("@falu_houtu") + player:getMark("@falu_yuqing") + player:getMark("@falu_gouchen")
		if player:hasSkill(self:objectName()) and num > 0 and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) and room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			local cards = room:getNCards(num, false)
			room:askForGuanxing(player, cards, sgs.Room_GuanxingUpOnly)
		end
	end
}
zhangqiying:addSkill(dianhua)

weiwenzhugezhi = sgs.General(extension_zlzy, "weiwenzhugezhi", "wu", "4", true)
fuhaiCard = sgs.CreateSkillCard{
	name = "fuhai",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local player_table = {}
		local next_player = source
		repeat
			next_player = next_player:getNextAlive()
			if next_player:objectName() ~= source:objectName() then
				table.insert(player_table, next_player)
			end
		until next_player:objectName() == source:objectName()
		
		local player_table_check = table.copyFrom(player_table)
		
		local choices = {}
		if #player_table > 0 then
			if player_table[1]:getMark("fuhai_target-Clear") == 0 and not player_table[1]:isKongcheng() then
				table.insert(choices, "fuhai_next")
			end
			if player_table[#player_table]:getMark("fuhai_target-Clear") == 0 and not player_table[#player_table]:isKongcheng() then
				table.insert(choices, "fuhai_previous")
			end
		end
		
		local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
		ChoiceLog(source, choice)
		if choice == "fuhai_next" then
			table.insert(player_table, source)
		elseif choice == "fuhai_previous" then
			player_table = sgs.reverse(player_table)
			table.insert(player_table, source)
		end
		
		for _, p in ipairs(player_table) do
			if p:isKongcheng() or p:getMark("fuhai_target-Clear") > 0 or source:isKongcheng() then
				break
			end
			if not p:isKongcheng() and p:getMark("fuhai_target-Clear") == 0 and not source:isKongcheng() then
				local card_source = room:askForCard(source, ".|.|.|hand!", "@fuhai-source-show", sgs.QVariant(), sgs.Card_MethodNone)
				local card_target = nil
				if card_source then
					room:showCard(source, card_source:getEffectiveId())
					card_target = room:askForCard(p, ".|.|.|hand!", "@fuhai-show", sgs.QVariant(card_source:getEffectiveId()), sgs.Card_MethodNone)
				end
				if card_source and card_target then
					room:addPlayerMark(source, "fuhai_draw_num-Clear")
					room:addPlayerMark(p, "fuhai_target-Clear")
					room:showCard(p, card_target:getEffectiveId())
					if card_source:getNumber() >= card_target:getNumber() then
						room:throwCard(card_source, source, source)
					else
						room:throwCard(card_target:getEffectiveId(), p, p)
						room:addPlayerMark(source, "fuhai-Clear")
						p:drawCards(source:getMark("fuhai_draw_num-Clear"), self:objectName())
						source:drawCards(source:getMark("fuhai_draw_num-Clear"), self:objectName())
						break
					end
				end
			end
		end
		
		if #player_table_check > 0 then
			if player_table_check[1]:getMark("fuhai_target-Clear") > 0 or player_table_check[1]:isKongcheng() then
				room:addPlayerMark(source, "fuhai_next_check-Clear")
			end
			if player_table_check[#player_table_check]:getMark("fuhai_target-Clear") > 0 or player_table_check[#player_table_check]:isKongcheng() then
				room:addPlayerMark(source, "fuhai_previous_check-Clear")
			end
		end
	end
}
fuhaiVS = sgs.CreateZeroCardViewAsSkill{
	name = "fuhai",
	view_as = function(self, cards)
		return fuhaiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and player:getMark("fuhai-Clear") == 0 and (player:getMark("fuhai_next_check-Clear") == 0 or player:getMark("fuhai_previous_check-Clear") == 0)
	end
}
fuhai = sgs.CreateTriggerSkill{
	name = "fuhai",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = fuhaiVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
			local player_table = {}
			local next_player = player
			repeat
				next_player = next_player:getNextAlive()
				if next_player:objectName() ~= player:objectName() then
					table.insert(player_table, next_player)
				end
			until next_player:objectName() == player:objectName()
			if #player_table > 0 then
				if player_table[1]:isKongcheng() then
					room:addPlayerMark(player, "fuhai_next_check-Clear")
				end
				if player_table[#player_table]:isKongcheng() then
					room:addPlayerMark(player, "fuhai_previous_check-Clear")
				end
			end
		end
		return false
	end
}
weiwenzhugezhi:addSkill(fuhai)

zhanggong = sgs.General(extension_zlzy, "zhanggong", "wei", "3", true)
qianxinbCard = sgs.CreateSkillCard{
	name = "qianxinb",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local alive_num = room:getAlivePlayers():length()
		if room:getDrawPile():length() >= alive_num then
			local choices = {}
			for i = alive_num, math.min(room:getDrawPile():length(), alive_num * self:getSubcards():length()), alive_num do
				local card_id = self:getSubcards():at(i / alive_num - 1)
				local ids = room:getNCards(i - 1, false)
				room:moveCardTo(sgs.Sanguosha:getCard(card_id), source, sgs.Player_DrawPile)
				room:setTag("qianxinb_card_"..card_id, sgs.QVariant(true))
				room:addPlayerMark(targets[1], "qianxinb_"..targets[1]:objectName().."_"..card_id)
				room:setPlayerMark(targets[1], "@qianxinb_target", 1)
				room:returnToTopDrawPile(ids)
			end			
			--room:setPlayerMark(source, "qianxinb_drawpile", 1)
		end
		room:setPlayerMark(source, "qianxinb_drawpile", 1)
	end
}
qianxinbVS = sgs.CreateViewAsSkill{
	name = "qianxinb",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local skillcard = qianxinbCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("qianxinb_drawpile") == 0
	end
}
qianxinb = sgs.CreateTriggerSkill{
	name = "qianxinb",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = qianxinbVS,
	events = {sgs.EventPhaseChanging, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			
			if player:hasSkill(self:objectName()) and change.to and change.to == sgs.Player_Play then
				if room:getDrawPile():length() < room:getAlivePlayers():length() then
					room:setPlayerMark(player, "qianxinb_drawpile", 1)
				end
			end
			
			if change.to and change.to == sgs.Player_Play then
				for _, c in sgs.list(player:getHandcards()) do
					if player:getMark("has_qianxinb_card_in_hand-Clear") > 0 then
						local log = sgs.LogMessage()
						log.type = "$qianxinb_card_in_hand"
						log.from = player
						log.arg = self:objectName()
						room:sendLog(log)
						break
					end
				end
			end
			
			for _, c in sgs.list(player:getHandcards()) do
				if change.to and change.to == sgs.Player_Discard and player:getMark("qianxinb_"..player:objectName().."_"..c:getEffectiveId()) > 0 and player:getMark("has_qianxinb_card_in_hand-Clear") > 0 then
					local log = sgs.LogMessage()
					log.type = "$qianxinb_debuff"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					
					room:setPlayerMark(player, "has_qianxinb_card_in_hand-Clear", 0)
					room:setPlayerMark(player, "@qianxinb_target", 0)
					
					local choices = {"qianxinb_maxcard"}
					for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if p:isAlive() then
							if p:getHandcardNum() < 4 then
								table.insert(choices, "qianxinb_draw")
							end
							local _data = sgs.QVariant()
							_data:setValue(p)
							local choice = room:askForChoice(player, "qianxinb-draw-maxcard", table.concat(choices, "+"), _data)
							ChoiceLog(player, choice)
							if choice == "qianxinb_draw" then
								for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
									if 4 - p:getHandcardNum() > 0 then
										p:drawCards(4 - p:getHandcardNum(), self:objectName())
									end
								end
							elseif choice == "qianxinb_maxcard" then
								room:setPlayerMark(player, "qianxinb_debuff-Clear", 1)
							end
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			
			local has_qianxinb_card = false
			for _,id in sgs.qlist(room:getDrawPile()) do
				if room:getTag("qianxinb_card_"..id):toBool() then
					has_qianxinb_card = true
				end
			end
			if has_qianxinb_card then
				room:setPlayerMark(player, "qianxinb_drawpile", 1)
			else
				room:setPlayerMark(player, "qianxinb_drawpile", 0)
			end
			
			if move.to and move.to:objectName() == player:objectName() then
				for _,id in sgs.qlist(move.card_ids) do
					if room:getTag("qianxinb_card_"..id):toBool() then
						room:setPlayerMark(player, "has_qianxinb_card_in_hand-Clear", 1)
					end
				end
			end
		end
		return false
	end
}
zhanggong:addSkill(qianxinb)
zhenxing = sgs.CreateTriggerSkill{
	name = "zhenxing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish) or event == sgs.Damaged then
			local choice = room:askForChoice(player, "zhenxing_choose_number", "1+2+3+cancel")
			if choice ~= "cancel" then
				room:broadcastSkillInvoke(self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				local ids = sgs.IntList()
				for _,id in sgs.qlist(room:getDrawPile()) do
					if ids:length() < tonumber(choice) then
						ids:append(id)
					end
				end
				--local ids = room:getNCards(tonumber(choice), false)
				local being_show_cards = {}
				for _, id in sgs.qlist(ids) do
					table.insert(being_show_cards, id)
				end
				--已下json去掉第一個角色名參數，因為原碼S_COMMAND_SHOW_ALL_CARDS會將這些牌和這個角色綁定成手牌。尤其是受到火攻的時後，只能展示這張牌，其他手牌不能展示。
				--解決方式如下，讓系統找不到這個綁定角色名，那這些牌也不會被綁定。
				--自定包其他用這方式展示牌的技能也同步修改(都是看牌)
				local json_value = {
					"",
					false,
					being_show_cards,
				}
				room:doNotify(player, sgs.CommandType.S_COMMAND_SHOW_ALL_CARDS, json.encode(json_value))
				
				local ag_ids = sgs.IntList()
				for _, id in sgs.qlist(ids) do
					ag_ids:append(id)
				end
				local spade_tables = {}
				local club_tables = {}
				local heart_tables = {}
				local diamond_tables = {}
				for _, id in sgs.qlist(ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:getSuitString() == "spade" then
						table.insert(spade_tables, card:getSuitString())
					elseif card:getSuitString() == "club" then
						table.insert(club_tables, card:getSuitString())
					elseif card:getSuitString() == "heart" then
						table.insert(heart_tables, card:getSuitString())
					elseif card:getSuitString() == "diamond" then
						table.insert(diamond_tables, card:getSuitString())
					end
				end
				if #spade_tables > 1 then
					for _, id in sgs.qlist(ids) do
						if sgs.Sanguosha:getCard(id):getSuitString() == "spade" then
							ag_ids:removeOne(id)
						end
					end
				end
				if #club_tables > 1 then
					for _, id in sgs.qlist(ids) do
						if sgs.Sanguosha:getCard(id):getSuitString() == "club" then
							ag_ids:removeOne(id)
						end
					end
				end
				if #heart_tables > 1 then
					for _, id in sgs.qlist(ids) do
						if sgs.Sanguosha:getCard(id):getSuitString() == "heart" then
							ag_ids:removeOne(id)
						end
					end
				end
				if #diamond_tables > 1 then
					for _, id in sgs.qlist(ids) do
						if sgs.Sanguosha:getCard(id):getSuitString() == "diamond" then
							ag_ids:removeOne(id)
						end
					end
				end
				if not ag_ids:isEmpty() then
					room:fillAG(ag_ids, player)
					local card_id = room:askForAG(player, ag_ids, false, self:objectName())
					if card_id ~= -1 then
						room:obtainCard(player, sgs.Sanguosha:getCard(card_id), false)
					end
					room:clearAG()
				end
			end
		end
		return false
	end
}
zhanggong:addSkill(zhenxing)
lukai = sgs.General(extension_zlzy, "lukai", "shu", "3", true)
tunanUseCard = sgs.CreateSkillCard{
	name = "tunanUse",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if sgs.Self:hasFlag("useAsSlash") then
			card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
			card:setSkillName("_tunan")
		end
		return card and not card:targetFixed() and card:targetFilter(targets_list, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
	end, 
	feasible = function(self, targets)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		if sgs.Self:hasFlag("useAsSlash") then
			card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
			card:setSkillName("_tunan")
		end
		return card and card:targetsFeasible(targets_list, sgs.Self)
	end,
	about_to_use = function(self, room, use)
		local _guojia = sgs.SPlayerList()
		_guojia:append(use.from)
		local move_to = sgs.CardsMoveStruct(self:getSubcards(), use.from, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
		local moves_to = sgs.CardsMoveList()
		moves_to:append(move_to)
		room:notifyMoveCards(true, moves_to, false, _guojia)
		room:notifyMoveCards(false, moves_to, false, _guojia)
		room:setPlayerFlag(use.from, "-Fake_Move")
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:setCardFlag(card, "-"..self:objectName())
		local card_for_use = sgs.Sanguosha:getCard(self:getSubcards():first())
		if use.from:hasFlag("useAsSlash") then
			card_for_use = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
			card_for_use:addSubcard(card)
			card_for_use:setSkillName("_tunan")
		end
		local targets_list = sgs.SPlayerList()
		for _, p in sgs.qlist(use.to) do
			if not use.from:isProhibited(p, card_for_use) then
				targets_list:append(p)
			end
		end
		room:useCard(sgs.CardUseStruct(card_for_use, use.from, targets_list))
	end
}
tunanCard = sgs.CreateSkillCard{
	name = "tunan",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		if room:getDrawPile():length() > 0 then
			local to = targets[1]
			--local ids = room:getNCards(1, false)
			--local tunan_id = ids:first()
			local ids = sgs.IntList()
			local tunan_id = room:getDrawPile():first()
			ids:append(tunan_id)
			
			room:setCardFlag(sgs.Sanguosha:getCard(tunan_id), self:objectName())
			room:setPlayerFlag(to, "Fake_Move")
			local _guojia = sgs.SPlayerList()
			_guojia:append(to)
			local move = sgs.CardsMoveStruct(ids, nil, to, sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason())
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, _guojia)
			room:notifyMoveCards(false, moves, false, _guojia)
			local choiceList = {}
			local card, choiceOne, choiceTwo = sgs.Sanguosha:getCard(tunan_id), false, false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not choiceOne and card:isAvailable(to) and not room:isProhibited(to, p, card) and card:targetFilter(sgs.PlayerList(), p, to) then
					choiceOne = true
					table.insert(choiceList, "tunan_use")
				end
				if choiceTwo then continue end
				local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
				slash:setSkillName("_tunan")
				if slash:isAvailable(to) and not room:isProhibited(to, p, slash) and slash:targetFilter(sgs.PlayerList(), p, to) then
					choiceTwo = true
					table.insert(choiceList, "tunan_slash")
				end
				slash:deleteLater()
			end
			if #choiceList > 0 then
				local choice = room:askForChoice(to, self:objectName(), table.concat(choiceList, "+"))
				ChoiceLog(to, choice)
				if choice == "tunan_use" then
					room:askForUseCard(to, "@@tunan!", "@tunan_useCard")
				else
					room:setPlayerFlag(to, "useAsSlash")
					room:askForUseCard(to, "@@tunan!", "@tunan")
					room:setPlayerFlag(to, "-useAsSlash")
				end
			else
				--room:getThread():delay(2000)
				local move_to = sgs.CardsMoveStruct(ids, to, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile, sgs.CardMoveReason())
				local moves_to = sgs.CardsMoveList()
				moves_to:append(move_to)
				room:notifyMoveCards(true, moves_to, false, _guojia)
				room:notifyMoveCards(false, moves_to, false, _guojia)
				room:setPlayerFlag(to, "-Fake_Move")
			end
			room:setCardFlag(sgs.Sanguosha:getCard(tunan_id), "-"..self:objectName())
		end
	end
}
tunan = sgs.CreateViewAsSkill{
	n = 1,
	name = "tunan",
	response_pattern = "@@tunan!",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@tunan!" then
			return to_select:hasFlag(self:objectName())
		end
		return false
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@tunan!" then
			if #cards ~= 1 then return nil end
			local skillcard = tunanUseCard:clone()
			skillcard:addSubcard(cards[1])
			return skillcard
		end
		if #cards ~= 0 then return nil end
		return tunanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#tunan")
	end
}
lukai:addSkill(tunan)
bijing = sgs.CreateTriggerSkill{
	name = "bijing",
	global = true,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_Finish then
					if not player:isKongcheng() then
						local card = room:askForCard(player, ".|.|.|hand", "@bijing", data, sgs.Card_MethodNone)
						if card then
							room:notifySkillInvoked(player, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							local log = sgs.LogMessage()
							log.type = "#InvokeSkill"
							log.from = player
							log.arg = self:objectName()
							room:sendLog(log)
							room:addPlayerMark(player, "bijing_card_id_"..card:getEffectiveId())
							room:setPlayerMark(player, "@bijing_card", 1)
						end
					end
				end
				if player:getPhase() == sgs.Player_Start then
					for _, c in sgs.list(player:getHandcards()) do
						if player:getMark("bijing_card_id_"..c:getEffectiveId()) > 0 then
							room:throwCard(c:getEffectiveId(), player, player)
						end
					end
					for _, mark in sgs.list(player:getMarkNames()) do
						if string.find(mark, "bijing_card_id_") and player:getMark(mark) > 0 then
							room:setPlayerMark(player, mark, 0)
							room:setPlayerMark(player, "@bijing_card", 0)
						end
					end
				end
			end
			
			local bijing_target
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				for _, mark in sgs.list(p:getMarkNames()) do
					if string.find(mark, "bijing_card_id_") and p:getMark(mark) > 0 then
						bijing_target = p
					end
				end
			end
			
			if bijing_target then
				if player:getPhase() == sgs.Player_Discard then
					if player:getMark("bijing_debuff-Clear") > 0 then
						local log = sgs.LogMessage()
						log.type = "$bijing_discard"
						log.from = player
						log.to:append(bijing_target)
						room:sendLog(log)
						room:askForDiscard(player, self:objectName(), 2, 2, false, true)
						for _, p in sgs.qlist(room:getAlivePlayers()) do
							for _, mark in sgs.list(p:getMarkNames()) do
								if string.find(mark, "bijing_card_id_") and p:getMark(mark) > 0 then
									room:setPlayerMark(p, mark, 0)
									room:setPlayerMark(p, "@bijing_card", 0)
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill(self:objectName())
			and move.from_places:contains(sgs.Player_PlaceHand) and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
			then
				for _, mark in sgs.list(player:getMarkNames()) do
					for _,id in sgs.qlist(move.card_ids) do
						if player:getMark("bijing_card_id_"..id) > 0 then
							room:addPlayerMark(room:getCurrent(), "bijing_debuff-Clear")
						end
					end
				end
			end
		end
		return false
	end
}
lukai:addSkill(bijing)

sec_jikang = sgs.General(extension_mobile, "sec_jikang", "wei", 3, true)
sec_qingxianCard = sgs.CreateSkillCard{
	name = "sec_qingxian",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getHp() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		for _, target in ipairs(targets) do
			if target:getEquips():length() < source:getEquips():length() then
				room:recover(target, sgs.RecoverStruct(target))
			elseif target:getEquips():length() == source:getEquips():length() then
				target:drawCards(1)
			elseif target:getEquips():length() > source:getEquips():length() then
				room:loseHp(target)
			end
		end
	end,
	feasible = function(self, targets)
		if self:getSubcards():length() ~= #targets then return false end
		return true
	end
}
sec_qingxian = sgs.CreateViewAsSkill{
	name = "sec_qingxian",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local skillcard = sec_qingxianCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#sec_qingxian")
	end
}
sec_jikang:addSkill(sec_qingxian)
sec_juexiang = sgs.CreateTriggerSkill{
	name = "sec_juexiang",
	events = {sgs.Death},
	on_trigger = function(self, event, player, data, room)
		local death = data:toDeath()
		if death.who and death.who:objectName() == player:objectName() then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() ~= player:objectName() then
					players:append(p)
				end
			end
			if death.damage and death.damage.from then
				death.damage.from:throwAllEquips()
				room:loseHp(death.damage.from)
				for _, p in sgs.qlist(players) do
					if p:objectName() == death.damage.from:objectName() then
						players:removeOne(p)
					end
				end
			end
			local target = room:askForPlayerChosen(player, players, self:objectName(), "sec_juexiang-invoke", true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				room:handleAcquireDetachSkills(target, "canyun", true)
				local ids = sgs.IntList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					for _, card in sgs.qlist(p:getCards("ej")) do
						if card:getSuit() == sgs.Card_Club then
							ids:append(card:getEffectiveId())
						end
					end
				end
				if ids:length() > 0 then
					room:fillAG(ids)
					local card_id = room:askForAG(target, ids, true, self:objectName())
					if card_id ~= -1 then
						room:throwCard(sgs.Sanguosha:getCard(card_id), room:getCardOwner(card_id), target)
						room:handleAcquireDetachSkills(target, "sec_juexiang", true)
					end
					room:clearAG()
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}
sec_jikang:addSkill(sec_juexiang)
canyunCard = sgs.CreateSkillCard{
	name = "canyun",
	filter = function(self, targets, to_select)
		return #targets < sgs.Self:getHp() and to_select:objectName() ~= sgs.Self:objectName() and to_select:getMark("canyun_target_"..sgs.Self:objectName()) == 0
	end,
	on_use = function(self, room, source, targets)
		for _, target in ipairs(targets) do
			room:setPlayerMark(target, "canyun_target_"..source:objectName(), 1)
			if target:getEquips():length() < source:getEquips():length() then
				room:recover(target, sgs.RecoverStruct(target))
			elseif target:getEquips():length() == source:getEquips():length() then
				target:drawCards(1)
			elseif target:getEquips():length() > source:getEquips():length() then
				room:loseHp(target)
			end
		end
	end,
	feasible = function(self, targets)
		if self:getSubcards():length() ~= #targets then return false end
		return true
	end
}
canyun = sgs.CreateViewAsSkill{
	name = "canyun",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local skillcard = canyunCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#canyun")
	end
}
if not sgs.Sanguosha:getSkill("canyun") then skills:append(canyun) end
sec_jikang:addRelateSkill("canyun")



twyj_caohong = sgs.General(extension_twyj, "twyj_caohong", "wei", 4, true)
twyj_huzhuCard = sgs.CreateSkillCard{
	name = "twyj_huzhu",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		local card = room:askForCard(targets[1], ".|.|.|hand!", "@twyj_huzhu:" .. source:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
		if card then
			room:moveCardTo(card, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), source:objectName(), self:objectName(), ""))
			local ids = sgs.IntList()
			for _, e in sgs.qlist(source:getCards("e")) do
				ids:append(e:getEffectiveId())
			end
			if ids:length() > 0 then
				room:fillAG(ids)
				local card_id = room:askForAG(targets[1], ids, false, self:objectName())
				if card_id ~= -1 then
					room:obtainCard(targets[1], card_id, true)
				end
				room:clearAG()
				local _data = sgs.QVariant()
				_data:setValue(targets[1])
				if targets[1]:getHp() <= source:getHp() and targets[1]:isWounded() and room:askForSkillInvoke(source, self:objectName(), _data) then
					room:recover(targets[1], sgs.RecoverStruct(targets[1]))
				end
			end
		end
	end
}
twyj_huzhu = sgs.CreateZeroCardViewAsSkill{
	name = "twyj_huzhu",
	view_as = function(self, cards)
		return twyj_huzhuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#twyj_huzhu") and not player:getEquips():isEmpty()
	end
}
twyj_caohong:addSkill(twyj_huzhu)
twyj_liancai = sgs.CreateTriggerSkill{
	name = "twyj_liancai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.TurnOver},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
			player:turnOver()
			local ids = sgs.IntList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				for _, e in sgs.qlist(p:getCards("e")) do
					ids:append(e:getEffectiveId())
				end
			end
			if ids:length() > 0 then
				room:fillAG(ids)
				local card_id = room:askForAG(player, ids, false, self:objectName())
				if card_id ~= -1 then
					room:obtainCard(player, card_id, true)
				end
				room:clearAG()
			end
		elseif event == sgs.TurnOver then
			if player:hasSkill(self:objectName()) and player:getHp() - player:getHandcardNum() > 0 and room:askForSkillInvoke(player, "twyj_liancai_turnover", data) then
				room:broadcastSkillInvoke(self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				player:drawCards(player:getHp() - player:getHandcardNum(), self:objectName())
			end
		end
		return false
	end
}
twyj_caohong:addSkill(twyj_liancai)
twyj_dingfeng = sgs.General(extension_twyj, "twyj_dingfeng", "wu", 4, true)
twyj_qijiaCard = sgs.CreateSkillCard{
	name = "twyj_qijia",
	will_throw = true,
	filter = function(self, targets, to_select)
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		if not self:getSubcards():isEmpty() and sgs.Self:getOffensiveHorse() and sgs.Self:getOffensiveHorse():getId() == self:getSubcards():first() then
			rangefix = rangefix + 1
		end
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:inMyAttackRange(to_select) and sgs.Self:canSlash(to_select, true, rangefix)
	end,
	about_to_use = function(self, room, use)
		local id = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(id)
		local equip_index = card:getRealCard():toEquipCard():location()
		room:setPlayerMark(use.from, self:objectName().."_"..equip_index.."-Clear", 1)
		room:throwCard(id, use.from, use.from)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
		slash:setSkillName(self:objectName())
		room:useCard(sgs.CardUseStruct(slash, use.from, use.to))
	end
}
twyj_qijia = sgs.CreateOneCardViewAsSkill{
	name = "twyj_qijia",
	view_filter = function(self, card)
		if card:isEquipped() then
			local equip_index = card:getRealCard():toEquipCard():location()
			return card:isEquipped() and not sgs.Self:isJilei(card) and sgs.Self:canDiscard(sgs.Self, "e") and sgs.Self:getMark(self:objectName().."_"..equip_index.."-Clear") == 0
		end
		return false
	end,
	view_as = function(self, card)
		local skillcard = twyj_qijiaCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
twyj_dingfeng:addSkill(twyj_qijia)
twyj_zhuchenCard = sgs.CreateSkillCard{
	name = "twyj_zhuchen",
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(targets[1], "twyj_zhuchen_dis_fix")
	end
}
twyj_zhuchen = sgs.CreateOneCardViewAsSkill{
	name = "twyj_zhuchen",
	view_filter = function(self, card)
		return card:isKindOf("Peach") or card:isKindOf("Analeptic")
	end,
	view_as = function(self, card)
		local skillcard = twyj_zhuchenCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
twyj_dingfeng:addSkill(twyj_zhuchen)
twyj_maliang = sgs.General(extension_twyj, "twyj_maliang", "shu", 3, true)
twyj_rangyiUseCard = sgs.CreateSkillCard{
	name = "twyj_rangyiUse",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		return card and not card:targetFixed() and card:targetFilter(targets_list, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
	end, 
	feasible = function(self, targets)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		return card and card:targetsFeasible(targets_list, sgs.Self)
	end,
	about_to_use = function(self, room, use)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, card in sgs.list(use.from:getHandcards()) do
			if card:hasFlag("twyj_rangyi") and card:getEffectiveId() ~= self:getSubcards():first() then
				dummy:addSubcard(card:getEffectiveId())
			end
		end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("twyj_rangyi_source") > 0 then
				room:obtainCard(p, dummy, false)
				break
			end
		end
		local card_for_use = sgs.Sanguosha:getCard(self:getSubcards():first())
		local targets_list = sgs.SPlayerList()
		for _, p in sgs.qlist(use.to) do
			if not use.from:isProhibited(p, card_for_use) then
				targets_list:append(p)
			end
		end
		room:useCard(sgs.CardUseStruct(card_for_use, use.from, targets_list))
	end
}
twyj_rangyiCard = sgs.CreateSkillCard{
	name = "twyj_rangyi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "twyj_rangyi_source", 1)
		local ids = sgs.IntList()
		for _, card in sgs.list(source:getHandcards()) do
			ids:append(card:getEffectiveId())
		end
		for _, id in sgs.qlist(ids) do
			room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName())
		end
		room:obtainCard(targets[1], source:wholeHandCards(), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
		if not room:askForUseCard(targets[1], "@@twyj_rangyi", "@twyj_rangyi") then
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 1))
		end
		for _, id in sgs.qlist(ids) do
			room:setCardFlag(sgs.Sanguosha:getCard(id), "-"..self:objectName())
		end
		room:setPlayerMark(source, "twyj_rangyi_source", 0)
	end
}
twyj_rangyi = sgs.CreateViewAsSkill{
	n = 1,
	name = "twyj_rangyi",
	response_pattern = "@@twyj_rangyi",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@twyj_rangyi" then
			return to_select:hasFlag(self:objectName()) and to_select:isAvailable(sgs.Self)
		end
		return false
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@twyj_rangyi" then
			if #cards ~= 1 then return nil end
			local skillcard = twyj_rangyiUseCard:clone()
			skillcard:addSubcard(cards[1])
			return skillcard
		end
		if #cards ~= 0 then return nil end
		return twyj_rangyiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and not player:hasUsed("#twyj_rangyi")
	end
}
twyj_maliang:addSkill(twyj_rangyi)
twyj_baimei = sgs.CreateTriggerSkill{
	name = "twyj_baimei",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		if player:isKongcheng() then
			local damage = data:toDamage()
			if (damage.nature ~= sgs.DamageStruct_Normal or (damage.card and damage.card:isKindOf("TrickCard"))) and damage.to and damage.to:objectName() == player:objectName() then
				local msg = sgs.LogMessage()
				msg.type = "#twyj_baimei_Protect"
				msg.from = player
				msg.arg = damage.damage
				if damage.nature == sgs.DamageStruct_Fire then
					msg.arg2 = "fire_nature"
				elseif damage.nature == sgs.DamageStruct_Thunder then
					msg.arg2 = "thunder_nature"
				elseif damage.nature == sgs.DamageStruct_Normal then
					msg.arg2 = "normal_nature"
				end
				room:sendLog(msg)
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:removePlayerMark(player, self:objectName().."engine")
					return true
				end
			end
		end
	end
}
twyj_maliang:addSkill(twyj_baimei)

heg_lvmeng = sgs.General(extension_heg, "heg_lvmeng", "wu", 4, true)
heg_keji = sgs.CreateTriggerSkill{
	name = "heg_keji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play and use.card and not use.card:isKindOf("SkillCard") then
				if use.card:getSuit() == sgs.Card_Spade then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Heart then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Club then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Diamond then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				end
				local suit = {}
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, self:objectName().."_") and player:getMark(mark) > 0 then
						table.insert(suit, mark:split("_")[4])
					end
				end
				if #suit >= 2 then
					room:setPlayerMark(player, self:objectName().."-Clear", 1)
				else
					room:setPlayerMark(player, self:objectName().."-Clear", 0)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_Discard and player:hasSkill(self:objectName()) and player:getHandcardNum() >= player:getMaxCards() - 4 and player:getMark(self:objectName().."-Clear") == 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		return false
	end
}
heg_lvmeng:addSkill(heg_keji)
heg_mouduanCard = sgs.CreateSkillCard{
	name = "heg_mouduan",
	filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:getJudgingArea():length() > 0 or to_select:getEquips():length() > 0)
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		if #targets == 0 then return end
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if not targets[1]:hasEquip() and targets[1]:getJudgingArea():length() == 0 then return end
			local card_id = room:askForCardChosen(source, targets[1], "ej", self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			local place = room:getCardPlace(card_id)
			local equip_index = -1
			if place == sgs.Player_PlaceEquip then
				local equip = card:getRealCard():toEquipCard()
				equip_index = equip:location()
			end
			local tos = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if equip_index ~= -1 then
					if not p:getEquip(equip_index) and p:hasEquipArea(equip_index) then
						tos:append(p)
					end
				else
					if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) and p:hasJudgeArea() then
						tos:append(p)
					end
				end
			end
			local tag = sgs.QVariant()
			tag:setValue(targets[1])
			room:setTag("heg_mouduanTarget", tag)
			--local to = room:askForPlayerChosen(source, tos, self:objectName(), "@qiaobian-to" .. card:objectName())
			local to = room:askForPlayerChosen(source, tos, self:objectName(), "@heg_mouduan-to")
			if to then
				room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("heg_mouduanTarget")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
heg_mouduanVS = sgs.CreateZeroCardViewAsSkill{
	name = "heg_mouduan",
	view_as = function(self, cards)
		return heg_mouduanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@heg_mouduan"
	end
}
heg_mouduan = sgs.CreateTriggerSkill{
	name = "heg_mouduan",
	view_as_skill = heg_mouduanVS,
	events = {sgs.CardUsed, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play and use.card and not use.card:isKindOf("SkillCard") then
				
				room:addPlayerMark(player, self:objectName().."_type_"..use.card:getTypeId().."_-Clear")
				
				if use.card:getSuit() == sgs.Card_Spade then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Heart then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Club then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Diamond then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				end
				local suit = {}
				local types = {}
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, self:objectName().."_suit_") and player:getMark(mark) > 0 then
						table.insert(suit, mark:split("_")[4])
					end
					if string.find(mark, self:objectName().."_type_") and player:getMark(mark) > 0 then
						table.insert(types, mark:split("_")[4])
					end
				end
				if #suit >= 4 or #types >= 3 then
					room:setPlayerMark(player, self:objectName().."-Clear", 1)
				else
					room:setPlayerMark(player, self:objectName().."-Clear", 0)
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and player:getMark(self:objectName().."-Clear") > 0 then
			room:askForUseCard(player, "@heg_mouduan", "@heg_mouduan")
		end
		return false
	end
}
heg_lvmeng:addSkill(heg_mouduan)


mobile_simazhao = sgs.General(extension_mobile, "mobile_simazhao", "wei", "3", true)
daigong = sgs.CreateTriggerSkill{
	name = "daigong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.from and damage.to and damage.to:isAlive() and damage.to:objectName() == player:objectName() and not damage.to:isKongcheng()
		and damage.to:getMark("has_use_daigong-Clear") == 0 and room:askForSkillInvoke(damage.to, self:objectName(), data)
		then
			room:notifySkillInvoked(damage.to, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			room:showAllCards(damage.to)
			local choices = {"daigong_no_damage"}
			local give_suit_name_table = {"spade", "club", "heart", "diamond"}
			for _, c in sgs.qlist(damage.to:getHandcards()) do
				if c:getSuitString() == "spade" then
					table.removeOne(give_suit_name_table, c:getSuitString())
				elseif c:getSuitString() == "club" then
					table.removeOne(give_suit_name_table, c:getSuitString())
				elseif c:getSuitString() == "heart" then
					table.removeOne(give_suit_name_table, c:getSuitString())
				elseif c:getSuitString() == "diamond" then
					table.removeOne(give_suit_name_table, c:getSuitString())
				end
			end
			local damage_from_can_give_card = false
			for _, c in sgs.qlist(damage.from:getCards("he")) do
				if table.contains(give_suit_name_table, c:getSuitString()) then
					damage_from_can_give_card = true
				end
			end
			if not damage.from:isNude() and damage_from_can_give_card then
				table.insert(choices, "daigong_give_card")
			end
			local choice = room:askForChoice(damage.from, self:objectName(), table.concat(choices, "+"), data)
			ChoiceLog(damage.from, choice)
			if choice == "daigong_no_damage" then
				local msg = sgs.LogMessage()
				msg.type = "#daigong_Protect"
				msg.from = damage.to
				msg.arg = damage.damage
				if damage.nature == sgs.DamageStruct_Fire then
					msg.arg2 = "fire_nature"
				elseif damage.nature == sgs.DamageStruct_Thunder then
					msg.arg2 = "thunder_nature"
				elseif damage.nature == sgs.DamageStruct_Normal then
					msg.arg2 = "normal_nature"
				end
				room:sendLog(msg)
				return true
			elseif choice == "daigong_give_card" then
				local daigong_pattern = table.concat(give_suit_name_table, ",")
				local daigong_give_card = room:askForCard(damage.from, ".|"..daigong_pattern.."|.|.!", "@daigong-give:" .. damage.to:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
				room:obtainCard(damage.to, daigong_give_card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, damage.from:objectName(), damage.to:objectName(), self:objectName(), ""), false)
			end
			room:addPlayerMark(damage.to, "has_use_daigong-Clear")
		end
	end
}
mobile_simazhao:addSkill(daigong)
mobile_zhaoxinCard = sgs.CreateSkillCard{
	name = "mobile_zhaoxin",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@mobile_zhaoxin" then
			local target = room:getCurrent()
			local card_name = sgs.Sanguosha:getCard(self:getSubcards():first()):objectName()
			if target and target:isAlive() and room:askForSkillInvoke(target, self:objectName(), sgs.QVariant("obtain:"..card_name)) then
				room:obtainCard(target, self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), target:objectName(), self:objectName(), ""), false)
				if room:askForSkillInvoke(source, "mobile_zhaoxin_damage", sgs.QVariant("damage:"..target:objectName())) then
					room:damage(sgs.DamageStruct(self:objectName(), source, target, 1))
				end
			end
		else
			source:addToPile("wang", self)
			source:drawCards(self:getSubcards():length(), self:objectName())
		end
	end
}
mobile_zhaoxinVS = sgs.CreateViewAsSkill{
	name = "mobile_zhaoxin",
	n = 3,
	expand_pile = "wang",
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@mobile_zhaoxin" then
			return sgs.Self:getPile("wang"):contains(to_select:getEffectiveId())
		else
			return not sgs.Self:getPile("wang"):contains(to_select:getEffectiveId())
		end
		return false
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern() == "@@mobile_zhaoxin" then
			if #cards ~= 1 then return nil end
			local skillcard = mobile_zhaoxinCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			skillcard:setSkillName(self:objectName())
			return skillcard
		else
			if #cards == 0 then return nil end
			if #cards + sgs.Self:getPile("wang"):length() > 3 then return nil end
			local skillcard = mobile_zhaoxinCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			skillcard:setSkillName(self:objectName())
			return skillcard
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#mobile_zhaoxin")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@mobile_zhaoxin"
	end
}
mobile_zhaoxin = sgs.CreateTriggerSkill{
	name = "mobile_zhaoxin",
	global = true,
	events = {sgs.EventPhaseEnd},
	view_as_skill = mobile_zhaoxinVS,
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Draw then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if not p:getPile("wang"):isEmpty() and (p:inMyAttackRange(player) or p:objectName() == player:objectName()) then
					room:askForUseCard(p, "@@mobile_zhaoxin", "@mobile_zhaoxin", -1, sgs.Card_MethodNone)
				end
			end
		end
		return false
	end
}
mobile_simazhao:addSkill(mobile_zhaoxin)

mobile_wangyuanji = sgs.General(extension_mobile, "mobile_wangyuanji", "wei", "3", false)
qianchong = sgs.CreateTriggerSkill{
	name = "qianchong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip)) or (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip) then
				local colors = {}
				for _,card in sgs.qlist(player:getEquips()) do
					if not table.contains(colors, GetColor(card)) then
						table.insert(colors, GetColor(card))
					end
				end
				room:notifySkillInvoked(player, self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				--疑似handleAcquireDetachSkills函數重複使用或失去裝備時會不能獲得技能
				--測試情況：一次失去兩個裝備區的裝備牌，再使用裝備後不會獲得對應的技能
				if #colors == 1 then
					room:broadcastSkillInvoke(self:objectName())
					if colors[1] == "red" then
						equip_change_acquire_or_detach_skill(room, player, "-weimu|mingzhe")
						--room:handleAcquireDetachSkills(player, "-weimu|mingzhe", true)
					elseif colors[1] == "black"  then
						equip_change_acquire_or_detach_skill(room, player, "weimu|-mingzhe")
						--room:handleAcquireDetachSkills(player, "weimu|-mingzhe", true)
					end
				end
				if #colors >= 2 or #colors == 0 then
					equip_change_acquire_or_detach_skill(room, player, "-weimu|-mingzhe")
					--room:handleAcquireDetachSkills(player, "-weimu|-mingzhe", true)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local invoke = false
				local colors = {}
				for _,card in sgs.qlist(player:getEquips()) do
					if not table.contains(colors, GetColor(card)) then
						table.insert(colors, GetColor(card))
					end
				end
				if #colors >= 2 or #colors == 0 then
					invoke = true
				end
				if invoke then
					local choices = {"qianchong_basic", "qianchong_trick", "qianchong_equip"}
					local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
					ChoiceLog(player, choice)
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					if choice == "qianchong_basic" then
						room:addPlayerMark(player, "qianchong_basic-Clear")
					elseif choice == "qianchong_trick" then
						room:addPlayerMark(player, "qianchong_trick-Clear")
					elseif choice == "qianchong_equip" then
						room:addPlayerMark(player, "qianchong_equip-Clear")
					end
				end
			end
		end
		return false
	end
}
mobile_wangyuanji:addSkill(qianchong)
shangjian = sgs.CreateTriggerSkill{
	name = "shangjian",
	global = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill(self:objectName())
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
			then
				for _,id in sgs.qlist(move.card_ids) do
					room:addPlayerMark(player, "shangjian_lose_card_num-Clear")
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getMark("shangjian_lose_card_num-Clear") > 0 then
						local lose_num = p:getMark("shangjian_lose_card_num-Clear")
						if lose_num > 0 and lose_num <= p:getHp() and room:askForSkillInvoke(p, self:objectName(), data) then
							room:notifySkillInvoked(p, self:objectName())
							room:broadcastSkillInvoke(self:objectName())
							p:drawCards(lose_num, self:objectName())
						end
					end
				end
			end
		end
		return false
	end
}
mobile_wangyuanji:addSkill(shangjian)
sec_tangzi = sgs.General(extension_dragonboat, "sec_tangzi", "wei")
sec_xingzhao = sgs.CreateTriggerSkill{
	name = "sec_xingzhao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			local wounded_num = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isWounded() then
					wounded_num = wounded_num + 1
				end
			end
			if player:getPhase() == sgs.Player_RoundStart and player:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				equip_change_acquire_or_detach_skill(room, player, "-xunxun")
				if wounded_num >= 1 then
					equip_change_acquire_or_detach_skill(room, player, "xunxun")
					if wounded_num >= 2 then
						room:setPlayerMark(player, "sec_xingzhao_euqip_draw-Clear", 1)
						if wounded_num >= 3 then
							room:setPlayerMark(player, "sec_xingzhao_skip_discard_phase-Clear", 1)
						end
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from:hasSkill(self:objectName()) and use.card and use.card:isKindOf("EquipCard") and use.from:getMark("sec_xingzhao_euqip_draw-Clear") > 0 then
				room:sendCompulsoryTriggerLog(use.from, self:objectName())
				room:notifySkillInvoked(use.from, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 2)
				use.from:drawCards(1, self:objectName())
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if player:hasSkill(self:objectName()) and change.to and change.to == sgs.Player_Discard and player:getMark("sec_xingzhao_skip_discard_phase-Clear") > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
				player:skip(sgs.Player_Discard)
			end
		end
		return false
	end
}
sec_tangzi:addSkill(sec_xingzhao)
sec_tangzi:addRelateSkill("xunxun")

sec_sufei = sgs.General(extension_dragonboat, "sec_sufei", "wu")
sec_lianpian = sgs.CreateTriggerSkill{
	name = "sec_lianpian",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetSpecifying, sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			local invoke = false
			if not use.card:isKindOf("SkillCard") then
				for _, p in sgs.qlist(use.to) do
					if p:getMark(self:objectName()..player:objectName().."_Play") > 0 then
						invoke = true
						break
					end
				end
			end
			for _, p in sgs.qlist(use.to) do
				if use.to:contains(p) then
					room:addPlayerMark(p, self:objectName()..player:objectName().."_Play")
				end
			end
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark(self:objectName()..player:objectName().."_Play") > 0 and not use.to:contains(p) then
					room:setPlayerMark(p, self:objectName()..player:objectName().."_Play", 0)
				end
			end
			if invoke and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play and player:getMark("sec_lianpian_used_times-Clear") < 3 and room:askForSkillInvoke(player, self:objectName(), data) then
				room:addPlayerMark(player, "sec_lianpian_used_times-Clear")
				room:broadcastSkillInvoke(self:objectName())
				local card_ids = room:getNCards(1, false)
				--player:drawCards(1, self:objectName())
				local move = sgs.CardsMoveStruct(card_ids, nil, player, sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DRAW, player:objectName(), self:objectName(), ""))
				room:moveCardsAtomic(move, false)
				local players = sgs.SPlayerList()
				for _, p in sgs.qlist(use.to) do
					if p:getMark(self:objectName()..player:objectName().."_Play") > 1 then
						players:append(p)
					end
				end
				local target = room:askForPlayerChosen(player, players, self:objectName(), "sec_lianpian-invoke", true, true)
				if target then
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:first()), player, target, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), ""))
				end
			end
		elseif event == sgs.EventPhaseEnd then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark(self:objectName()..player:objectName().."_Play") > 0 then
					room:setPlayerMark(p, self:objectName()..player:objectName().."_Play", 0)
				end
			end
		else
			local n = 0
			if event == sgs.CardUsed then
				n = data:toCardUse().to
			else
				if data:toCardResponse().m_isUse then
					card = data:toCardResponse().m_card
				end
			end
			if n == 0 then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark(self:objectName()..player:objectName().."_Play") > 0 then
						room:setPlayerMark(p, self:objectName()..player:objectName().."_Play", 0)
					end
				end
			end
		end
		return false
	end
}
sec_sufei:addSkill(sec_lianpian)

sec_huangquan = sgs.General(extension_dragonboat, "sec_huangquan", "shu", "3")
sec_dianhu = sgs.CreateTriggerSkill{
	name = "sec_dianhu",
	global = true,
	events = {sgs.GameStart, sgs.Damaged, sgs.HpRecover},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart and RIGHT(self, player) then
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "sec_dianhu-invoke", false, true)
			if to then
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:addPlayerMark(to, "@aim")
					room:addPlayerMark(to, "sec_aim"..player:objectName())
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.to and damage.to:getMark("sec_aim"..damage.from:objectName()) > 0 and damage.from:isAlive() and damage.from:hasSkill(self:objectName()) then
				room:sendCompulsoryTriggerLog(damage.from, self:objectName())
				room:notifySkillInvoked(damage.from, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 2)
				damage.from:drawCards(1, self:objectName())
			end
		elseif event == sgs.HpRecover then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:getMark("sec_aim"..p:objectName()) > 0 and player:isAlive() then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					room:notifySkillInvoked(p, self:objectName())
					room:broadcastSkillInvoke(self:objectName(), 1)
					p:drawCards(1, self:objectName())
				end
			end
		end
		return false
	end
}
sec_huangquan:addSkill(sec_dianhu)
sec_jianjiCard = sgs.CreateSkillCard{
	name = "sec_jianji",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local card_ids = room:getNCards(1, false)
		local id = card_ids:first()
		if targets[1]:hasSkill("cunmu") then
			id = room:getDrawPile():last()
		end
		local moves = sgs.CardsMoveList()
		local move = sgs.CardsMoveStruct(card_ids, nil, targets[1], sgs.Player_DrawPile, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DRAW, targets[1]:objectName(), "sec_jianji", ""))
		moves:append(move)
		room:moveCardsAtomic(moves, false)
		if sgs.Sanguosha:getCard(id):isAvailable(targets[1]) then
			room:askForUseCard(targets[1], ""..id, "@sec_jianji")
		end
	end
}
sec_jianji = sgs.CreateZeroCardViewAsSkill{
	name = "sec_jianji",
	view_as = function(self)
		return sec_jianjiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#sec_jianji")
	end
}
sec_huangquan:addSkill(sec_jianji)

ol_caochun = sgs.General(extension_pray, "ol_caochun", "wei")
ol_shanjiaCard = sgs.CreateSkillCard{
	name = "ol_shanjia",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local invoke = true
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") or sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
				invoke = false
			end
		end
		if invoke then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			for _, cd in sgs.qlist(self:getSubcards()) do
				slash:addSubcard(cd)
			end
			slash:deleteLater()
			return slash:targetFilter(targets_list, to_select, sgs.Self)
		end
		return #targets < 0
	end,
	feasible = function(self, targets)
		local invoke = true
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") or sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
				invoke = false
			end
		end
		if invoke then
			return #targets > 0 or #targets == 0
		end
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			room:broadcastSkillInvoke(self:objectName(), 2)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		else
			room:broadcastSkillInvoke(self:objectName(), 1)
		end
	end
}
ol_shanjiaVS = sgs.CreateViewAsSkill{
	name = "ol_shanjia",
	n = 3,
	view_filter = function(self, selected, to_select)
		local x = 3 - sgs.Self:getMark("@ol_shanjia")
		return #selected < x and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		local x = 3 - sgs.Self:getMark("@ol_shanjia")
		if x == 0 then return ol_shanjiaCard:clone() end
		if #cards ~= x then return nil end
		local card = ol_shanjiaCard:clone()
		for _, cd in ipairs(cards) do
			card:addSubcard(cd)
		end
		return card
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@ol_shanjia")
	end
}
ol_shanjia = sgs.CreateTriggerSkill{
	name = "ol_shanjia",
	view_as_skill = ol_shanjiaVS,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
			player:drawCards(3, self:objectName())
			room:askForUseCard(player, "@@ol_shanjia!", "@ol_shanjia", -1, sgs.Card_MethodNone)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill(self:objectName())
			and move.from_places:contains(sgs.Player_PlaceEquip)
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
			then
				local i = 0
				for _,id in sgs.qlist(move.card_ids) do
					if move.from_places:at(i) == sgs.Player_PlaceEquip then
						if player:getMark("@ol_shanjia") < 3 then
							room:addPlayerMark(player, "@ol_shanjia")
						end
					end
					i = i + 1
				end
			end
		end
		return false
	end
}
ol_caochun:addSkill(ol_shanjia)
mangyazhang = sgs.General(extension, "mangyazhang", "qun")
jiedao = sgs.CreateTriggerSkill{
	name = "jiedao",
	global = true,
	events = {sgs.DamageCaused, sgs.DamageComplete},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			if damage.from and damage.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				room:addPlayerMark(player, "jiedao_damage-Clear")
				if player:getMark("jiedao_damage-Clear") == 1 and player:getLostHp() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
					local increase_damage = player:getLostHp()
					room:broadcastSkillInvoke(self:objectName())
					local log = sgs.LogMessage()
					log.type = "$jiedao_increase_damage"
					log.from = player
					if damage.card then
						log.card_str = damage.card:toString()
					else
						log.card_str = -1
					end
					log.arg = self:objectName()
					log.arg2 = increase_damage
					room:sendLog(log)
					damage.damage = damage.damage + increase_damage
					data:setValue(damage)
					room:addPlayerMark(player, "jiedao_invoke_"..increase_damage.."_-Clear")
				end
			end
		elseif event == sgs.DamageComplete then
			if damage.from and damage.to and damage.to:isAlive() then
				local increase_damage = 0
				for _, mark in sgs.list(damage.from:getMarkNames()) do
					if string.find(mark, "jiedao_invoke_") and damage.from:getMark(mark) > 0 then
						increase_damage = mark:split("_")[3]
						room:askForDiscard(damage.from, self:objectName(), increase_damage, increase_damage, false, true)
						room:setPlayerMark(damage.from, "jiedao_invoke_"..increase_damage.."_-Clear", 0)
					end
				end
			end
		end
		return false
	end
}
mangyazhang:addSkill(jiedao)

xugong = sgs.General(extension, "xugong", "wu", 3)
biaozhao = sgs.CreateTriggerSkill{
	name = "biaozhao",
	global = true,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) then
			local id = room:askForCard(player, "..", "@biaozhao", sgs.QVariant(), sgs.Card_MethodNone)
			if id then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				player:addToPile("biao", id)
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if not p:getPile("biao"):isEmpty() and p:hasSkill(self:objectName()) then
						local biao_cards = {}
						for _, biao_id in sgs.qlist(p:getPile("biao")) do
							for _,id in sgs.qlist(move.card_ids) do
								local biao_card = sgs.Sanguosha:getCard(biao_id)
								local move_card = sgs.Sanguosha:getCard(id)
								if biao_card:getSuit() == move_card:getSuit() and biao_card:getNumber() == move_card:getNumber() then
									room:sendCompulsoryTriggerLog(p, self:objectName())
									room:notifySkillInvoked(p, self:objectName())
									room:broadcastSkillInvoke(self:objectName())
									room:loseHp(p, 1)
									if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and move.from then
										--Player類型轉至ServerPlayer
										local move_from_player
										for _,pp in sgs.qlist(room:getAlivePlayers()) do
											if pp:objectName() == move.from:objectName() then
												move_from_player = pp
											end
										end
										room:obtainCard(move_from_player, biao_card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), move.from:objectName(), self:objectName(), ""), false)
									else
										room:throwCard(biao_card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", p:objectName(), self:objectName(), ""), nil)
									end
								end
							end
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			if player:hasSkill(self:objectName()) and not player:getPile("biao"):isEmpty() then
				for _, biao_id in sgs.qlist(player:getPile("biao")) do
					room:throwCard(sgs.Sanguosha:getCard(biao_id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", player:objectName(), self:objectName(), ""), nil)
				end
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "biaozhao-invoke", false, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					if target:isWounded() then
						room:recover(target, sgs.RecoverStruct(target))
					end
					local max_handcard_num = 0
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						max_handcard_num = math.max(max_handcard_num, p:getHandcardNum())
					end
					if math.min(max_handcard_num, 5) > target:getHandcardNum() then
						target:drawCards(math.min(max_handcard_num, 5) - target:getHandcardNum(), self:objectName())
					end
				end
			end
		end
		return false
	end
}
xugong:addSkill(biaozhao)
yechou = sgs.CreateTriggerSkill{
	name = "yechou",
	events = {sgs.Death, sgs.EventPhaseChanging},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local death = data:toDeath()
		if death.who and death.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getLostHp() > 1 then
					players:append(p)
				end
			end
			if not players:isEmpty() then
				local target = room:askForPlayerChosen(player, players, self:objectName(), "yechou-invoke", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(target, "yechou_invoke")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("yechou_invoke") > 0 then
						for _, pp in sgs.qlist(room:getAllPlayers(true)) do
							if not pp:isAlive() and pp:hasSkill(self:objectName()) then
								room:sendCompulsoryTriggerLog(pp, self:objectName())
							end
						end
						room:loseHp(p, 1)
					end
				end
			end
			if change.to and change.to == sgs.Player_RoundStart and player:getMark("yechou_invoke") > 0 then
				room:setPlayerMark(player, "yechou_invoke", 0)
			end
		end
		return false
	end
}
xugong:addSkill(yechou)




lukuangluxiang = sgs.General(extension_guandu, "lukuangluxiang", "qun", 4)

liehouCard = sgs.CreateSkillCard{
	name = "liehou",
	filter = function(self, targets, to_select, player)
		if to_select:objectName() == player:objectName() then return false end
		if #targets == 0 then
			return player:inMyAttackRange(to_select) and not to_select:isKongcheng()
        end
	end,
	on_use = function(self, room, source, targets)
        local target = targets[1]
		if target:isKongcheng() then return false end
		local id = room:askForCardChosen(target, target, "h", "liehou")
		local cd = sgs.Sanguosha:getCard(id)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), source:objectName(), "liehou","")
        room:moveCardTo(cd,source,sgs.Player_PlaceHand,reason)
        local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(target)) do
                    if source:inMyAttackRange(p) then
                        targets:append(p)
                    end
                end
                if targets:isEmpty() then return false end
                local dest = room:askForPlayerChosen(source, targets, self:objectName(), "liehou-invoke")
                if not dest then return false end
                local id = room:askForCardChosen(source, source, "h", "liehou")
                local card = sgs.Sanguosha:getCard(id)
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), dest:objectName(), "liehou","")
                room:moveCardTo(card,dest,sgs.Player_PlaceHand,reason)
        
		end
}
liehou = sgs.CreateZeroCardViewAsSkill{
	name = "liehou",
	view_as = function() 
		return liehouCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#liehou")
	end,
}

qigong = sgs.CreateTriggerSkill{
	name = "qigong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.SlashMissed, sgs.TargetConfirmed, sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
                if use.to and use.to:length() == 1 and use.from:hasSkill(self:objectName()) then
                    room:setCardFlag(use.card, "qigong_canuse")
                end
                if player:hasFlag("qigongUsed") then
                    player:setFlags("-qigongUsed")
                    room:setCardFlag(use.card,"qigong-slash")
                end
			end
		elseif event == sgs.SlashMissed then 
		local effect = data:toSlashEffect()
		local dest = effect.to
		if dest:isAlive() and effect.slash and effect.slash:hasFlag("qigong_canuse") then
			
				local prompt = string.format("qigong-slash:%s", dest:objectName())
				
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:canSlash(dest, nil, false) then
                        targets:append(p)
                    end
                end
                if targets:isEmpty() then return false end
                room:setPlayerFlag(effect.to, "qigong_target")
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "qigong-invoke", true, true)
                room:setPlayerFlag(effect.to, "-qigong_target")
			if not target then return false end
                room:broadcastSkillInvoke(self:objectName())
                target:setFlags("qigongUsed")
				local slash = room:askForUseSlashTo(target, dest, prompt)
				if not slash then
				target:setFlags("-qigongUsed")
					end
				end
		elseif event == sgs.TargetConfirmed then 
		local use = data:toCardUse()
		if (not use.from) or (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) or (not use.card:hasFlag("qigong-slash")) then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			local _data = sgs.QVariant()
			_data:setValue(p)
            jink_table[index] = 0
            local log= sgs.LogMessage()
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
		return false
	end,
    can_trigger = function(self, target)
		return target
	end,
	priority = -1
}

lukuangluxiang:addSkill(liehou)
lukuangluxiang:addSkill(qigong)




gd_shenpei = sgs.General(extension_guandu, "gd_shenpei", "qun", 3)

gangzhi = sgs.CreateTriggerSkill{
	name = "gangzhi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Predamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
        if ((damage.from and damage.from:hasSkill(self:objectName())) or  (damage.to and damage.to:hasSkill(self:objectName())))and (damage.from and damage.from:objectName() ~= damage.to:objectName()) then
        room:broadcastSkillInvoke(self:objectName())
        if damage.from:hasSkill(self:objectName()) then
            room:sendCompulsoryTriggerLog(damage.from, self:objectName(), true)
        end
        if damage.to:hasSkill(self:objectName()) then
            room:sendCompulsoryTriggerLog(damage.to, self:objectName(), true)
        end
		room:loseHp(damage.to, damage.damage)
		return true
        end
	end,
    can_trigger = function(self, target)
		return target
	end,
}


beizhan = sgs.CreateTriggerSkill{
	name = "beizhan",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getHandcardNum() < math.min(5, p:getMaxHp()) then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "beizhan-invoke", true, true)
                if not target then return false end
                room:broadcastSkillInvoke(self:objectName())
                local x = math.min(5, target:getMaxHp()) - target:getHandcardNum()
                target:drawCards(x)
                room:addPlayerMark(target, "beizhan")
                
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:getMark("beizhan") > 0 then
            room:setPlayerMark(player, "beizhan", 0)
            local max = 0
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getHandcardNum() > max then
                    max = p:getHandcardNum()
                end
            end
            if player:getHandcardNum() == max then
                room:addPlayerMark(player, "beizhan-Clear")
            end
        end
	end,
    can_trigger = function(self, target)
		return target
	end,
}
beizhanProhibit = sgs.CreateProhibitSkill{
	name = "#beizhanProhibit" ,
	is_prohibited = function(self, from, to, card)
			if from:getMark("beizhan-Clear") > 0 and from:objectName() ~= to:objectName() then
				return not card:isKindOf("SkillCard")
			end
		return false
	end
}






gd_shenpei:addSkill(gangzhi)
gd_shenpei:addSkill(beizhan)
gd_shenpei:addSkill(beizhanProhibit)
extension_guandu:insertRelatedSkills("beizhan","#beizhanProhibit")


gd_xunchen = sgs.General(extension_guandu, "gd_xunchen", "qun", 3)

fenglueCard = sgs.CreateSkillCard{
	name = "fenglue" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,
	on_use = function(self, room, source, targets)
		local success = source:pindian(targets[1], "fenglue", nil)
		if (success) then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            if not targets[1]:isKongcheng() then
					local id1 = room:askForCardChosen(targets[1], targets[1], "h", self:objectName())
					dummy:addSubcard(id1)
				end
				if not targets[1]:getEquips():isEmpty() then
					local id2 = room:askForCardChosen(targets[1], targets[1], "e", self:objectName())
					dummy:addSubcard(id2)
				end
				if not targets[1]:getJudgingArea():isEmpty() then
					local id3 = room:askForCardChosen(targets[1], targets[1], "j", self:objectName())
					dummy:addSubcard(id3)
				end
				if dummy:subcardsLength() > 0 then
					room:obtainCard(source, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName()), false)
				end
		else
            if not source:isNude() then
                local id = room:askForCardChosen(source, source, "he", self:objectName())
                room:obtainCard(targets[1], sgs.Sanguosha:getCard(id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName()), false)
            end
		end
	end
}
fenglueVS = sgs.CreateZeroCardViewAsSkill{
	name = "fenglue" ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@fenglue")
	end ,
	view_as = function()
        return fenglueCard:clone()
	end
}
fenglue = sgs.CreatePhaseChangeSkill{
	name = "fenglue" ,
	view_as_skill = fenglueVS ,
	on_phasechange = function(self, jianyong)
		if (jianyong:getPhase() == sgs.Player_Play) and (not jianyong:isKongcheng()) then
			local room = jianyong:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(jianyong)
			for _, player in sgs.qlist(other_players) do
				if not player:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if (can_invoke) then
				room:askForUseCard(jianyong, "@@fenglue", "@fenglue-card", 1)
			end
		end
		return false
	end ,
}

fengluePindian = sgs.CreateTriggerSkill{
	name = "#fengluePindian" ,
	events = {sgs.Pindian} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pindian = data:toPindian()
		local to_obtain = nil
		local jianyong = nil
        local get = nil
		if (pindian.from and pindian.from:isAlive() and pindian.from:hasSkill("fenglue")) then
			jianyong = pindian.from
            get = pindian.to
			to_obtain = pindian.from_card
			
		elseif (pindian.to and pindian.to:isAlive() and pindian.to:hasSkill("fenglue")) then
			jianyong = pindian.to
            get = pindian.from
            to_obtain = pindian.to_card
		end
		if jianyong and to_obtain and (room:getCardPlace(to_obtain:getEffectiveId()) == sgs.Player_PlaceTable) and get then
            local dest = sgs.QVariant()
            dest:setValue(get)
			if room:askForSkillInvoke(jianyong, "fenglue", dest) then
				get:obtainCard(to_obtain)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


moushiCard = sgs.CreateSkillCard{
	name = "moushi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return  sgs.Self:objectName() ~= to_select:objectName() and #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:obtainCard(targets[1], self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
		room:addPlayerMark(targets[1], self:objectName()..source:objectName().."_flag")
	end
}
moushiVS = sgs.CreateOneCardViewAsSkill{
	name = "moushi",
	view_filter = function(self, card)
		return not card:isEquipped()
	end,
	view_as = function(self, card)
		local fumancard = moushiCard:clone()
		fumancard:addSubcard(card)
		return fumancard
	end,
    enabled_at_play = function(self, player)
		return not player:hasUsed("#moushi")
	end, 
}
moushi = sgs.CreateTriggerSkill{
	name = "moushi",
	events = {sgs.Damage},
	view_as_skill = moushiVS,
	global = true,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.from:getPhase() == sgs.Player_Play  then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if player:getMark(self:objectName()..p:objectName().."_flag") > 0 and player:getMark(self:objectName()..p:objectName()..damage.to:objectName() .."damage_flag") == 0 then
                        room:addPlayerMark(player, self:objectName()..p:objectName()..damage.to:objectName().."damage_flag")
                        room:sendCompulsoryTriggerLog(p, self:objectName(),true)
                        room:broadcastSkillInvoke(self:objectName())
                        p:drawCards(1)
                    end
                end
            end
        end
		return false
	end
}




gd_xunchen:addSkill(fenglue)
gd_xunchen:addSkill(fengluePindian)
extension_guandu:insertRelatedSkills("fenglue","#fengluePindian")
gd_xunchen:addSkill(moushi)


gd_gaolan = sgs.General(extension_guandu, "gd_gaolan", "qun", 4)


isDamageTrick = function(card)
    if card then
        if card:isKindOf("ArcheryAttack") 
        or card:isKindOf("SavageAssault")
        or card:isKindOf("Duel")
        or card:isKindOf("FireAttack")
        then
            return true
        end
    end
    return false
end



ol_xiying = sgs.CreatePhaseChangeSkill{
	name = "ol_xiying" ,
	on_phasechange = function(self, player)
		if (player:getPhase() == sgs.Player_Play) and (not player:isKongcheng()) then
			local room = player:getRoom()
			local card = room:askForCard(player, "TrickCard,EquipCard|.|.|hand", "@xiying", sgs.QVariant(), sgs.Card_MethodDiscard)
            if card then
                room:addPlayerMark(player, self:objectName().."-Clear")
                room:broadcastSkillInvoke(self:objectName())
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    local dest = sgs.QVariant()
                    dest:setValue(player)
                    local cd = room:askForCard(p, ".|.|.", "@xiying_CardLimitation", dest, sgs.Card_MethodDiscard, player)
                    if not cd then
                        room:addPlayerMark(p, self:objectName().. player:objectName() .."-Clear")
                        room:setPlayerCardLimitation(p, "use,response", ".", false)
                    end
                end
            end
		end
		return false
	end ,
}
xiyingCardLimitation = sgs.CreateTriggerSkill{
	name = "#xiyingCardLimitation" ,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.Damage} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                if player:getMark("ol_xiying-Clear") > 0 and player:getMark("damage_recordplay-Clear") > 0 then
                    room:broadcastSkillInvoke("ol_xiying")
					local cardsIds = sgs.IntList()
                    while (true) do
                        local id = room:getNCards(1, false)
                        local newmove = sgs.CardsMoveStruct()
					newmove.card_ids = id
					newmove.to = player
					newmove.to_place = sgs.Player_PlaceTable
					newmove.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), "ol_xiying", nil)
                    room:moveCardsAtomic(newmove, true)
                    local card = sgs.Sanguosha:getCard(id:first())
                    if card:isKindOf("Slash") or isDamageTrick(card) then
                        room:obtainCard(player, card)
                        break
                    end
                    cardsIds:append(id:first())
                    end
                    if not cardsIds:isEmpty() then
                        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in sgs.qlist(cardsIds) do
							dummy:addSubcard(id)
						end
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), "ol_xiying", nil)
						room:throwCard(dummy, reason, nil)
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
			if change.from == sgs.Player_Play  then 
                if player:getMark("ol_xiying-Clear") > 0 then
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getMark("ol_xiying".. player:objectName() .."-Clear") > 0 then
                            room:setPlayerMark(p, "ol_xiying".. player:objectName() .."-Clear", 0)
                            room:removePlayerCardLimitation(p, "use,response", ".")
                        end
                    end
                end
            end
        end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}


gd_gaolan:addSkill(ol_xiying)
gd_gaolan:addSkill(xiyingCardLimitation)
extension_guandu:insertRelatedSkills("ol_xiying","#xiyingCardLimitation")



caochun = sgs.General(extension_pray, "caochun", "wei")
shanjiaCard = sgs.CreateSkillCard{
	name = "shanjia",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local invoke = true
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") or sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
				invoke = false
			end
		end
		if invoke then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			for _, cd in sgs.qlist(self:getSubcards()) do
				slash:addSubcard(cd)
			end
			slash:deleteLater()
			return slash:targetFilter(targets_list, to_select, sgs.Self)
		end
		return #targets < 0
	end,
	feasible = function(self, targets)
		local invoke = true
		for _, id in sgs.qlist(self:getSubcards()) do
			if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") or sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
				invoke = false
			end
		end
		if invoke then
			return #targets > 0 or #targets == 0
		end
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			room:broadcastSkillInvoke(self:objectName(), 2)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		else
			room:broadcastSkillInvoke(self:objectName(), 1)
		end
	end
}
shanjiaVS = sgs.CreateViewAsSkill{
	name = "shanjia",
	n = 3,
	view_filter = function(self, selected, to_select)
		local x = 3 - sgs.Self:getMark("@shanjia")
		return #selected < x and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		local x = 3 - sgs.Self:getMark("@shanjia")
		if x == 0 then return shanjiaCard:clone() end
		if #cards ~= x then return nil end
		local card = shanjiaCard:clone()
		for _, cd in ipairs(cards) do
			card:addSubcard(cd)
		end
		return card
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@shanjia")
	end
}
shanjia = sgs.CreateTriggerSkill{
	name = "shanjia",
	view_as_skill = shanjiaVS,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
			player:drawCards(3, self:objectName())
			room:askForUseCard(player, "@@shanjia!", "@shanjia", -1, sgs.Card_MethodNone)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill(self:objectName())
			and (move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceHand))
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
			then
				local i = 0
				for _,id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
						if player:getMark("@shanjia") < 3 then
							room:addPlayerMark(player, "@shanjia")
						end
					end
					i = i + 1
				end
			end
		end
		return false
	end
}
shanjiaSlash = sgs.CreateTargetModSkill{
	name = "#shanjiaSlash" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("shanjia") and (card:getSkillName() == "shanjia") then
			return 1000
		else
			return 0
		end
	end
}
caochun:addSkill(shanjia)
caochun:addSkill(shanjiaSlash)
extension_pray:insertRelatedSkills("shanjia","#shanjiaSlash")


caoshuang = sgs.General(extension_pray, "caoshuang", "wei")


tuogu = sgs.CreateTriggerSkill{
	name = "tuogu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
        local tuogu_skill = player:getTag("tuoguSkill"):toString();
		local room = player:getRoom()
		if event == sgs.Death then
            local death = data:toDeath()
            local ac_dt_list = {}
            if player and death.who:objectName() ~= player:objectName() and player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName()) then
                SendComLog(self, player)
                if tuogu_skill ~= "" then
                    table.insert(ac_dt_list,"-"..tuogu_skill)
                end
                local target = player2serverplayer(room,death.who)
                local skill_names = {}
				for _,skill in sgs.qlist(target:getVisibleSkillList())do
					if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake or skill:isAttachedLordSkill() then
						continue
					end
					if not table.contains(skill_names,skill:objectName()) then
						table.insert(skill_names,skill:objectName())
					end
				end
                if #skill_names == 0 then return end
                local dest = sgs.QVariant()
                dest:setValue(player)
                skill_name = room:askForChoice(target, self:objectName(),table.concat(skill_names,"+"), dest)
                if skill_name ~= "" then
                    table.insert(ac_dt_list,skill_name)
                end
                player:setTag("tuoguSkill",sgs.QVariant(skill_name))
                room:handleAcquireDetachSkills(player, table.concat(ac_dt_list,"|"), true)
            end
		end
	end,
    can_trigger = function(self, target)
		return target
	end
}

ol_shanzhuan = sgs.CreateTriggerSkill{
	name = "ol_shanzhuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() ~= damage.to:objectName() then
                if damage.to:getJudgingArea():length() == 0 and damage.to:hasJudgeArea() and not damage.to:isNude() then
                    if player:askForSkillInvoke(self:objectName(), data) then
                        local to_throw = room:askForCardChosen(player, damage.to, "he", self:objectName())
                        local card = sgs.Sanguosha:getCard(to_throw)
                        local to_use
                        if card:isRed() then
                            to_use = sgs.Sanguosha:cloneCard("indulgence",card:getSuit(),card:getNumber())
                        elseif card:isBlack() then
                            to_use = sgs.Sanguosha:cloneCard("supply_shortage",card:getSuit(),card:getNumber())
                        else
                            return
                        end
                        
                        to_use:deleteLater()	    	
                        if not player:isProhibited(damage.to, to_use)  then
                            to_use:addSubcard(card)
                            to_use:setSkillName("ol_shanzhuan")
                            local use = sgs.CardUseStruct()
                            use.card = to_use
                            use.from = damage.to
                            use.to:append(damage.to)
                            room:useCard(use)
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                if player:getMark("damage_record-Clear") == 0 then
                    player:drawCards(1)
                    SendComLog(self, player)
                end
            end
        end
		return false
	end
}
caoshuang:addSkill(tuogu)
caoshuang:addSkill(ol_shanzhuan)




guansuo = sgs.General(extension_pray, "guansuo", "shu")
zhengnan = sgs.CreateTriggerSkill{
	name = "zhengnan",
	events = {sgs.Deathed},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if room:askForSkillInvoke(p, self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(p, self:objectName().."engine")
				if p:getMark(self:objectName().."engine") > 0 then
					p:drawCards(3, self:objectName())
					local choices = {}
					if not p:hasSkill("wusheng") then
						table.insert(choices, "wusheng")
					end
					if not p:hasSkill("ol_zhiman") then
						table.insert(choices, "ol_zhiman")
					end
					if not p:hasSkill("gaidangxia") then
						table.insert(choices, "gaidangxia")
					end
					if #choices > 0 then
						local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"))
						room:acquireSkill(p, choice)
					end
					room:removePlayerMark(p, self:objectName().."engine")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
guansuo:addSkill(zhengnan)
guansuo:addRelateSkill("wusheng")
guansuo:addRelateSkill("gaidangxia")
--guansuo:addRelateSkill("zhiman")
guansuo:addRelateSkill("ol_zhiman")
xiefang = sgs.CreateDistanceSkill{
	name = "xiefang",
	correct_func = function(self, from, to)
		if from:hasSkill(self:objectName()) then
			return -from:getMark(self:objectName())
		end
		return 0
	end
}
guansuo:addSkill(xiefang)

ol_baosanniang = sgs.General(extension_pray, "ol_baosanniang", "shu", 4,false)

ol_wuniang = sgs.CreateTriggerSkill{
	name = "ol_wuniang",
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
		local card = data:toCardUse().card
		if card and card:isKindOf("Slash") and use.to:length() == 1 and use.to:first():isAlive() then
            if player:getMark("ol_wuniang-Clear") == 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                local slash = room:askForUseSlashTo(use.to:first(), player, string.format("ol_wuniang-slash:%s", player:objectName()))
                player:drawCards(1, self:objectName())
                room:addPlayerMark(player, "ol_wuniang-Clear")
            end
		end
		return false
	end,
}

ol_wuniangTargetMod = sgs.CreateTargetModSkill{
	name = "#ol_wuniangTargetMod",
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasSkill("ol_wuniang")  then
			return player:getMark("ol_wuniang-Clear")
		end
	end,
}
ol_xushen = sgs.CreateTriggerSkill{
	name = "ol_xushen",
	frequency = sgs.Skill_Limited,
	limit_mark = "@ol_xushen",
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EnterDying then
			if player:getMark("@ol_xushen") > 0 and room:askForSkillInvoke(player, self:objectName(), data)  then
                room:removePlayerMark(player, "@ol_xushen")
                local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1 - player:getHp()
				room:recover(player, recover)
                room:handleAcquireDetachSkills(player, "ol_zhennan")
                room:broadcastSkillInvoke(self:objectName())
                local has_guansuo = false
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getGeneralName() == "guansuo" or p:getGeneral2Name() == "guansuo"  then
                        has_guansuo = true
                    end
                end
                local targets = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:isMale() then
                        targets:append(p)
                    end
                end
                if not has_guansuo and not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "ol_xushen-invoke", true, true)
                    if not target then return false end
                    if room:askForSkillInvoke(target, "ol_xushen_change", data) then
                        room:changeHero(target, "guansuo", false, false)
                    end
                end
            end
		end
		return false
	end
}


ol_zhennanCard = sgs.CreateSkillCard{
	name = "ol_zhennan",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local card = sgs.Sanguosha:cloneCard("SavageAssault", sgs.Card_NoSuit, 0)
		card:setSkillName(self:objectName())
        card:addSubcards(self:getSubcards())
        local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and not sgs.Self:isProhibited(to_select, card, qtargets) and #targets < self:getSubcards():length() and  to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		local card = sgs.Sanguosha:cloneCard("SavageAssault", sgs.Card_NoSuit, 0)
		card:setSkillName(self:objectName())
        card:addSubcards(self:getSubcards())
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self) and #targets == self:getSubcards():length()
	end,	
	on_validate = function(self, card_use)
		local xunyou = card_use.from
		local room = xunyou:getRoom()
		
		local use_card = sgs.Sanguosha:cloneCard("SavageAssault", sgs.Card_NoSuit, -1)
		use_card:setSkillName(self:objectName())
        use_card:addSubcards(self:getSubcards())
		local available = true
        for _,p in sgs.qlist(card_use.to) do
            room:addPlayerMark(p, self:objectName().."_Play")
        end
        room:setPlayerFlag(xunyou, self:objectName())
		
		local available =  use_card:isAvailable(xunyou)
		if not available then return nil end
		return use_card		
	end,
}
ol_zhennanVS = sgs.CreateViewAsSkill{
	name = "ol_zhennan",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = ol_zhennanCard:clone()
            for _, c in ipairs(cards) do
                card:addSubcard(c)
            end
            card:setSkillName(self:objectName())
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#ol_zhennan")) and (not player:isKongcheng()) 
	end,
}
ol_zhennan = sgs.CreateTriggerSkill{
	name = "ol_zhennan",
	events = {sgs.CardEffected},
    view_as_skill = ol_zhennanVS,
	on_trigger = function(self, event, player, data, room)
        if event == sgs.CardEffected then
            local effect = data:toCardEffect()
            if data:toCardEffect().card:isKindOf("SavageAssault") and effect.to and effect.to:hasSkill(self:objectName()) then
                sendComLog(player, self:objectName(), true)
                local msg = sgs.LogMessage()
                msg.type = "#SkillNullify"
                msg.from = player
                msg.arg = self:objectName()
                msg.arg2 = "savage_assault"
                room:sendLog(msg)
                return true
            end
        end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
ol_zhennanProhibit = sgs.CreateProhibitSkill{
	name = "#ol_zhennanProhibit" ,
	is_prohibited = function(self, from, to, card)
		return  card:getSkillName() == "ol_zhennan" and to:getMark("ol_zhennan_Play") == 0 and from:hasFlag("ol_zhennan")
	end
}


ol_baosanniang:addSkill(ol_wuniang)
ol_baosanniang:addSkill(ol_wuniangTargetMod)
extension_pray:insertRelatedSkills("ol_wuniang","#ol_wuniangTargetMod")
ol_baosanniang:addSkill(ol_xushen)
--ol_baosanniang:addSkill(ol_zhennan)
ol_baosanniang:addSkill(ol_zhennanProhibit)
extension_pray:insertRelatedSkills("ol_zhennan","#ol_zhennanProhibit")
if not sgs.Sanguosha:getSkill("ol_zhennan") then skills:append(ol_zhennan) end
ol_baosanniang:addRelateSkill("ol_zhennan")


ol_wolongfengchu = sgs.General(extension_pray, "ol_wolongfengchu", "shu", 4)


local pos = 0

youlong_select = sgs.CreateSkillCard{
	name = "youlong_select",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		for i = 0, 10000 do
			local card = sgs.Sanguosha:getEngineCard(i)
			if card == nil then break end
			if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
				if card:isAvailable(source) and source:getMark("youlongcard"..card:objectName()) == 0 and 
                ((card:isKindOf("BasicCard") and source:getMark("youlong") == 1 and source:getMark("youlong_Basic_lun") == 0)
                or (card:isNDTrick() and source:getMark("youlong") ~= 1 and source:getMark("youlong_Trick_lun") == 0)) then
					table.insert(choices, card:objectName())
				end
			end
		end
		if next(choices) ~= nil then
			table.insert(choices, "cancel")
			local pattern = room:askForChoice(source, "youlong", table.concat(choices, "+"))
			if pattern and pattern ~= "cancel" then
				local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
                    if poi:targetFixed() then
                        poi:setSkillName("youlong")
                        room:useCard(sgs.CardUseStruct(poi, source, source),true)
                    else
                        pos = getPos(patterns, pattern)
                        room:setPlayerMark(source, "youlongpos", pos)
                        room:askForUseCard(source, "@@youlong", "@youlong:"..pattern)--%src
                    end
			end
		end
	end
}



youlongCard = sgs.CreateSkillCard{
	name = "youlong",
	will_throw = false,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if card and card:targetFixed() then
				return false
			else
				return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
			end
		end
		return true
	end,
	target_fixed = function(self)
		local name = ""
		local card
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				if user:getMark("youlongcard"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(user, "youlong", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
      
		use_card:setSkillName("youlong")
		return use_card

	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+")  then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				if card_use.from:getMark("youlongcard"..name) == 0 then
				table.insert(uses, name)
				end
			end
			local name = room:askForChoice(card_use.from, "youlong", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("youlong")
		local available = true
		for _, p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p, use_card)	then
				available = false
				break
			end
		end
		if not available then return nil end
       
		return use_card
	end
}



youlongVS = sgs.CreateViewAsSkill{
	name = "youlong",
	n = 0,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 0 then
				local acard = youlong_select:clone()
				return acard
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				pattern = "slash+thunder_slash+fire_slash"
			end
			local acard = youlongCard:clone()
			if pattern and pattern == "@@youlong" then
				pattern = patterns[sgs.Self:getMark("youlongpos")]
				if #cards ~= 0 then return end
			else
				if #cards ~= 0 then return end
			end
			if pattern == "peach+analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then
				pattern = "analeptic"
			end
			acard:setUserString(pattern)
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		for _, name in ipairs(patterns) do
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if poi:isAvailable(player) and player:getMark("youlongcard"..name) == 0   and (
            (poi:isKindOf("BasicCard") and player:getMark(self:objectName()) == 1 and player:getMark("youlong_Basic_lun") == 0) or (poi:isKindOf("TrickCard") and player:getMark(self:objectName()) ~= 1 and player:getMark("youlong_Trick_lun") == 0))   then
				table.insert(choices, name)
			end
		end
        local has_equip_area = false
        for i = 0, 4 do
            if player:hasEquipArea(i) then
                has_equip_area = true
                break
            end
        end
		return next(choices) and has_equip_area
	end,
	enabled_at_response = function(self, player, pattern)
		if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		
        --[[local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		for _, name in ipairs(patterns) do
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if poi:isAvailable(player) and player:getMark("youlongcard"..name) == 0   and (
            (poi:isKindOf("BasicCard") and player:getMark(self:objectName()) == 1 and player:getMark("youlong_Basic_lun") == 0) or (poi:isKindOf("TrickCard") and player:getMark(self:objectName()) ~= 1 and player:getMark("youlong_Trick_lun") == 0))   then
				table.insert(choices, name)
			end
		end]]
        
        local has_equip_area = false
        for i = 0, 4 do
            if player:hasEquipArea(i) then
                has_equip_area = true
                break
            end
        end
        if not has_equip_area then return false end
        
		--[[for _, p in pairs(pattern:split("+")) do
			if table.contains(choices, p) then return true end
		end]]
        
        
        local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		for _, name in ipairs(patterns) do
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if poi:isAvailable(player)and player:getMark("youlongcard"..name) == 0   and (
            (poi:isKindOf("BasicCard") and player:getMark(self:objectName()) == 1 and player:getMark("youlong_Basic_lun") == 0) or (poi:isKindOf("TrickCard") and player:getMark(self:objectName()) ~= 1 and player:getMark("youlong_Trick_lun") == 0))  then
				table.insert(choices, name)
			end
		end
		return #choices > 0
        
        
        
	end,
	enabled_at_nullification = function(self, player, pattern)
        local has_equip_area = false
        for i = 0, 4 do
            if player:hasEquipArea(i) then
                has_equip_area = true
                break
            end
        end
		return player:getMark("youlongcardnullification") == 0 and player:getMark(self:objectName()) ~= 1 and has_equip_area and player:getMark("youlong_Trick_lun") == 0
	end
}
youlong = sgs.CreateTriggerSkill{
	name = "youlong",
    view_as_skill = youlongVS,
	events = {sgs.PreCardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Change,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse then
				if card:getSkillName() == "youlong" and player:getMark("youlongcard"..card:objectName()) == 0 then
					room:addPlayerMark(player, "youlongcard"..card:objectName())
                    ThrowEquipArea(self, player, false, true)
					if card:isKindOf("BasicCard") then
                        room:addPlayerMark(player, "youlong_Basic_lun")
                    elseif card:isKindOf("TrickCard") then
                        room:addPlayerMark(player, "youlong_Trick_lun")
                    end
                    ChangeSkill(self, room, player)
                    if player:getMark("luanfen") > 0 then
                        room:setPlayerMark(player, "@luanfen", 0)
                    end
				end
			end
		end
	end
}


luanfen = sgs.CreateTriggerSkill{
	name = "luanfen",
	frequency = sgs.Skill_Limited,
    limit_mark = "@luanfen",
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
        if source:getMaxHp() >= player:getMaxHp() and player:askForSkillInvoke(self:objectName(), data) then
            player:loseMark("@luanfen")
            room:addPlayerMark(player, "luanfen")
            local recover = sgs.RecoverStruct()
            recover.who = player
            recover.recover = 3 - source:getHp()
            room:recover(source, recover)
            local x = 0
            for i = 0, 4 do
                if not source:hasEquipArea(i) then
                    source:obtainEquipArea(i)
                    x = x + 1
                end
            end
            local draw = 6 - x - source:getHandcardNum()
            if draw > 0 then
                source:drawCards(draw)
            end
            if source:objectName() == player:objectName() then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, "youlongcard") and player:getMark(mark) > 0 then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
        end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return target:getMark("@luanfen") > 0
				end
			end
		end
		return false
	end
}




ol_wolongfengchu:addSkill(youlong)
ol_wolongfengchu:addSkill(luanfen)



panshu = sgs.General(extension_pray, "panshu", "wu", 3, false)

ol_weiyi = sgs.CreateTriggerSkill{
	name = "ol_weiyi",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:isDead() then
				return false
			end
			for _, panshu in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if panshu:getMark(self:objectName()..damage.to:objectName()) == 0 then
                    local choiceList = "cancel"
                    if damage.to:getHp() >= panshu:getHp() then
                        choiceList = string.format("%s+%s", choiceList, "ol_weiyi_losehp")
                    end
                    if damage.to:getHp() <= panshu:getHp() then
                        choiceList = string.format("%s+%s", choiceList, "ol_weiyi_recover")
                    end
                    room:setTag("CurrentDamageStruct", data)
                    local choice =room:askForChoice(panshu, self:objectName(),choiceList,data)
                    if choice ~= "cancel" then
                        room:addPlayerMark(panshu, self:objectName()..damage.to:objectName())
                        room:addPlayerMark(damage.to, "@ol_weiyi")
                        if choice == "ol_weiyi_losehp" then
                            room:loseHp(damage.to)
                            room:broadcastSkillInvoke(self:objectName(), 1)
                        else
                            local recover = sgs.RecoverStruct()
                            recover.who = panshu;
                            room:recover(damage.to, recover);
                            room:broadcastSkillInvoke(self:objectName(), 2)
                        end
                    end
                    room:removeTag("CurrentDamageStruct")
                end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}


function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end
local patterns = {"slash", "jink", "peach", "analeptic"}
if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
	table.insert(patterns, 2, "thunder_slash")
	table.insert(patterns, 2, "fire_slash")
	table.insert(patterns, 2, "normal_slash")
end
local slash_patterns = {"slash", "normal_slash", "thunder_slash", "fire_slash"}
function getPos(table, value)
	for i, v in ipairs(table) do
		if v == value then
			return i
		end
	end
	return 0
end
local pos = 0
jinzhi_select = sgs.CreateSkillCard {
	name = "jinzhi_select",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
		local basic = {}
		for _, cd in ipairs(patterns) do
			local card = sgs.Sanguosha:cloneCard(cd, sgs.Card_NoSuit, 0)
			if card then
				card:deleteLater()
				if card:isAvailable(source) then
					if card:getTypeId() == sgs.Card_TypeBasic then
						table.insert(basic, cd)
					end
					if cd == "slash" then
						table.insert(basic, "normal_slash")
					end
				end
			end
		end
		local pattern = room:askForChoice(source, "jinzhi", table.concat(basic, "+"))
		if pattern then
			if string.sub(pattern, -5, -1) == "slash" then
				pos = getPos(slash_patterns, pattern)
				room:setPlayerMark(source, "jinzhiSlashPos", pos)
			end
			pos = getPos(patterns, pattern)
			room:setPlayerMark(source, "jinzhiPos", pos)
			local prompt = string.format("@@jinzhi:%s", pattern)
			room:askForUseCard(source, "@jinzhi", prompt)			
		end
	end,
}

jinzhiCard = sgs.CreateSkillCard {
	name = "jinzhi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	player = nil,
	on_use = function(self, room, source)
		player = source
	end,
	filter = function(self, targets, to_select, player)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@jinzhi" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("jinzhi")
			end
			if card and card:targetFixed() then
				return false
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end		
		local pattern = patterns[player:getMark("jinzhiPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("jinzhi")
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,	
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@jinzhi" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end		
		local pattern = patterns[player:getMark("jinzhiPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		return card and card:targetFixed()
	end,	
	feasible = function(self, targets)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@jinzhi" then
			local card = nil
			if self:getUserString() ~= "" then
				card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
				card:setSkillName("jinzhi")
			end
			local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
			return card and card:targetsFeasible(qtargets, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end		
		local pattern = patterns[sgs.Self:getMark("jinzhiPos")]
		if pattern == "normal_slash" then pattern = "slash" end
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName("jinzhi")
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,	
	on_validate = function(self, card_use)
		local yuji = card_use.from
		local room = yuji:getRoom()		
		local to_guhuo = self:getUserString()		
		if to_guhuo == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@jinzhi" then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "normal_slash")
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			to_guhuo = room:askForChoice(yuji, "jinzhi_slash", table.concat(guhuo_list, "+"))
			pos = getPos(slash_patterns, to_guhuo)
			room:setPlayerMark(yuji, "jinzhiSlashPos", pos)
		end	
			local subcards = self:getSubcards()
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            for _, id in sgs.qlist(subcards) do
                dummy:addSubcard(id)
            end
            room:throwCard(dummy, yuji)
            yuji:drawCards(1)
			local user_str
			if to_guhuo == "slash"  then
				user_str = "slash"
			elseif to_guhuo == "normal_slash" then
				user_str = "slash"
			else
				user_str = to_guhuo
			end
			local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, -1)
			use_card:setSkillName("jinzhi")
			use_card:deleteLater()			
			return use_card
	end,
	on_validate_in_response = function(self, yuji)
		local room = yuji:getRoom()
		local to_guhuo
		if self:getUserString() == "peach+analeptic" then
			local guhuo_list = {}
			table.insert(guhuo_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "analeptic")
			end
			to_guhuo = room:askForChoice(yuji, "guhuo_saveself", table.concat(guhuo_list, "+"))
		elseif self:getUserString() == "slash" then
			local guhuo_list = {}
			table.insert(guhuo_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(guhuo_list, "normal_slash")
				table.insert(guhuo_list, "thunder_slash")
				table.insert(guhuo_list, "fire_slash")
			end
			to_guhuo = room:askForChoice(yuji, "jinzhi_slash", table.concat(guhuo_list, "+"))
			pos = getPos(slash_patterns, to_guhuo)
			room:setPlayerMark(yuji, "jinzhiSlashPos", pos)
		else
			to_guhuo = self:getUserString()
		end		
			local subcards = self:getSubcards()
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            for _, id in sgs.qlist(subcards) do
                dummy:addSubcard(id)
            end
            room:throwCard(dummy, yuji)
            yuji:drawCards(1)
			local user_str
			if to_guhuo == "slash" then
				user_str = "slash"
			elseif to_guhuo == "normal_slash" then
				user_str = "slash"
			else
				user_str = to_guhuo
			end
			local use_card = sgs.Sanguosha:cloneCard(user_str, sgs.Card_NoSuit, -1)
			use_card:setSkillName("jinzhi")
			use_card:deleteLater()
			return use_card
	end
}

jinzhiVS = sgs.CreateViewAsSkill {
	name = "jinzhi",	
	n = 999,	
	enabled_at_response = function(self, player, pattern)
		if pattern == "@jinzhi" then
			return true
		end		
		if pattern == "peach" and player:hasFlag("Global_PreventPeach") then return false end
			return (pattern == "slash")
				or (pattern == "jink")
				or (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")))
				or (string.find(pattern, "analeptic"))
				end,
	enabled_at_play = function(self, player)
		local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then  
		return player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player , newanal)
		end
		return sgs.Slash_IsAvailable(player) or player:isWounded()
	end ,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		elseif #selected > 0 then
			local card = selected[1]
			if GetColor(card) == GetColor(to_select) then
				return true
			end
		end
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if sgs.Sanguosha:getCurrentCardUsePattern() == "@jinzhi" then
				local pattern = patterns[sgs.Self:getMark("jinzhiPos")]
				if pattern == "normal_slash" then pattern = "slash" end
				local c = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
				if c and #cards > 0 and #cards == sgs.Self:getMark("jinzhi_lun") + 1 then
					c:deleteLater()
					local card = jinzhiCard:clone()
					if not string.find(c:objectName(), "slash") then
						card:setUserString(c:objectName())
					else
						card:setUserString(slash_patterns[sgs.Self:getMark("jinzhiSlashPos")])
					end
					for _, cd in ipairs(cards) do
                        card:addSubcard(cd)
                    end
					return card
				else
					return nil
				end
			elseif #cards > 0 and #cards == sgs.Self:getMark("jinzhi_lun") + 1 then
				local card = jinzhiCard:clone()
				card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
				for _, cd in ipairs(cards) do
                    card:addSubcard(cd)
                end
				return card
			else
				return nil
			end
		else
			local cd = jinzhi_select:clone()
			return cd
		end
	end,	
	}

jinzhi = sgs.CreateTriggerSkill
{
	name = "jinzhi",
	events = {sgs.CardUsed, sgs.CardResponded},
	view_as_skill = jinzhiVS,
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
        if event == sgs.CardUsed then
            local curcard = data:toCardUse().card
            if curcard:getSkillName() == "jinzhi"  then
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName().."_lun")
            end
        elseif event == sgs.CardResponded then
            local card = data:toCardResponse().m_card
            if card:getSkillName() == "jinzhi"  then 
                room:broadcastSkillInvoke(self:objectName())
                room:addPlayerMark(player, self:objectName().."_lun")
            end
        end
	end
}




panshu:addSkill(ol_weiyi)
panshu:addSkill(jinzhi)


yuantanyuanshang = sgs.General(extension_pray, "yuantanyuanshang", "qun", 4)
sgs.LoadTranslationTable{
	["yuantanyuanshang"] = "袁谭&袁尚",
	["&yuantanyuanshang"] = "袁谭袁尚",
	["#yuantanyuanshang"] = "兄弟鬩牆",
	["~yuantanyuanshang"] = "兄弟难齐心，该有此果……",
	
}
neifa = sgs.CreatePhaseChangeSkill{
	name = "neifa",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Play then return false end
        local choicelist = "neifa_draw"
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getEquips():length() > 0 or p:getJudgingArea():length() > 0 then
                targets:append(p)
            end
        end
        if not targets:isEmpty() then
            choicelist = string.format("%s+%s", choicelist, "neifa_target")
        end
        choicelist = string.format("%s+%s", choicelist, "cancel")
        local choice = room:askForChoice(player, self:objectName(), choicelist)
        if choice ~= "cancel" then 
            room:broadcastSkillInvoke(self:objectName())
            if choice ==  "neifa_draw" then
                player:drawCards(2, self:objectName())
            else
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "neifa-invoke", true, true)
                if not target then return false end
                local card = room:askForCardChosen(player, target, "je",self:objectName())
                room:obtainCard(player, sgs.Sanguosha:getCard(card), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName()), false)
            end
            if player:canDiscard(player, "he") then
                local card = room:askForCard(player, "..!", "@neifa-discard", sgs.QVariant(), self:objectName())
                if card then
                    if card:isKindOf("BasicCard") then
                        room:setPlayerCardLimitation(player, "use", "TrickCard,EquipCard", true)
                        local n = 1
                        for _, c in sgs.qlist(player:getHandcards()) do
                            for _, p in sgs.qlist(room:getAllPlayers()) do
                                if c:isAvailable(player) then continue end
                                if c:targetFixed() or c:targetFilter(sgs.PlayerList(), p, player) then
                                    n = n + 1
                                    break
                                end
                            end
                        end
                        room:setPlayerMark(player, "neifaBasic-Clear", math.min(n, 6))
                    else
                        room:setPlayerCardLimitation(player, "use", "BasicCard", true)
                        local n = 1
                        for _, c in sgs.qlist(player:getHandcards()) do
                            for _, p in sgs.qlist(room:getAllPlayers()) do
                                if c:isAvailable(player) then continue end
                                if c:targetFixed() or c:targetFilter(sgs.PlayerList(), p, player) then
                                    n = n + 1
                                    break
                                end
                            end
                        end
                        room:setPlayerMark(player, "neifaNotBasic-Clear", math.min(n, 6))
                    end
                end
            end
		end
		return false
	end
}
sgs.LoadTranslationTable{
	["neifa"] = "内伐",
	["neifa_trick"] = "内伐",
	[":neifa"] = "出牌阶段开始时，你可以摸两张牌或获得场上的一张牌，然后弃置一张牌。若弃置的牌是基本牌，本回合你不能使用锦囊牌和装备牌且【杀】的使用次数+X且目标+1；若弃置的牌不是基本牌，本回合你不能使用基本牌，使用的普通锦囊牌的目标+1或-1，本回合前两次使用装备牌时摸X张牌。（X为发动内伐时手牌中不能使用的牌且最多为5） ",
	["@neifa-discard"] = "请弃置一张牌",
    ["neifa_target"] = "获得场上的一张牌",
    ["neifa_draw"] = "摸两张牌",
    ["$neifa1"] = "同室内伐，贻笑外人。",
    ["$neifa2"] = "自相恩残，相煎何急。",
	
}
neifaExtra = sgs.CreateTriggerSkill{
	name = "#neifa-extra",
	events = {sgs.PreCardUsed},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if player:getMark("neifaNotBasic-Clear") > 0 and (use.card:isNDTrick()) and not use.card:isKindOf("Nullification") then
            local available_targets = sgs.SPlayerList()
			if (not use.card:isKindOf("AOE")) and (not use.card:isKindOf("GlobalEffect")) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if (use.to:contains(p) or room:isProhibited(player, p, use.card)) then continue end
					if (use.card:targetFixed()) then
						if (not use.card:isKindOf("Peach")) or (p:isWounded()) then
							available_targets:append(p)
						end
					else
						if (use.card:targetFilter(sgs.PlayerList(), p, player)) then
							available_targets:append(p)
						end
					end
				end
			end
            
            local choices = {}
			table.insert(choices, "cancel")
			if (use.to:length() > 1) then table.insert(choices, 1, "remove") end
			if (not available_targets:isEmpty()) then table.insert(choices, 1, "add") end
			if #choices == 1 then return false end
			local choice = room:askForChoice(player, "neifa_trick", table.concat(choices, "+"), data)
            if (choice == "cancel") then
				return false
			elseif choice == "add" then
                local targets = sgs.SPlayerList()
                local extra = nil
                if not use.card:isKindOf("Collateral") then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if not use.to:contains(p) and not room:isProhibited(player, p, use.card) then
                            targets:append(p)
                        end
                    end
                    if targets:isEmpty() then return false end
                    extra = room:askForPlayerChosen(player, targets, "neifa_trick", "@qiaoshui-add:::" .. use.card:objectName(), true)
                elseif use.card:isKindOf("Collateral") then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if use.to:contains(p) or room:isProhibited(player, p, use.card) then continue end
                        if use.card:targetFilter(sgs.PlayerList(), p, player) then
                            targets:append(p)
                        end
                    end
                    if targets:isEmpty() then return false end
                    local tos = {}
                    for _, t in sgs.qlist(use.to) do
                        table.insert(tos, t:objectName())
                    end
                    room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(use.card:toString()))
                    room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant(table.concat(tos, "+")))
                    local used = room:askForUseCard(player, "@@ExtraCollateral", "@qiaoshui-add:::collateral")
                    room:setPlayerProperty(player, "extra_collateral", sgs.QVariant())
                    room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant())
                    if not used then return false end
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:hasFlag("ExtraCollateralTarget") then
                            room:setPlayerFlag(p, "-ExtraCollateralTarget")
                            extra = p
                            break
                        end
                    end
                end
                if not extra then return false end
                room:broadcastSkillInvoke("neifa")
                use.to:append(extra)
                room:sortByActionOrder(use.to)
                data:setValue(use)
                local msg = sgs.LogMessage()
                msg.type = "#QiaoshuiAdd"
                msg.from = player
                msg.to:append(extra)
                msg.card_str = use.card:toString()
                msg.arg = "neifa"
                room:sendLog(msg)
                room:doAnimate(1, player:objectName(), extra:objectName())
                if use.card:isKindOf("Collateral") then
                    local victim = extra:setTag("collateralVictim"):toPlayer()
                    if victim then
                        local msg = sgs.LogMessage()
                        msg.type = "#CollateralSlash"
                        msg.from = player
                        msg.to:append(victim)
                        room:sendLog(msg)
                        room:doAnimate(1, extra:objectName(), victim:objectName())
                    end
                end
            else
				local removed = room:askForPlayerChosen(player, use.to, "neifa_trick", "@qiaoshui-remove:::" .. use.card:objectName())
				use.to:removeOne(removed)
                data:setValue(use)
            end
		end
		return false
	end
}
NeifaBuff = sgs.CreateTriggerSkill{
	name = "neifa_buff",
	global = true,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, splayer, data, room)
		local n = splayer:getMark("neifaNotBasic-Clear") - 1
		if n > 0 and data:toCardUse().card:isKindOf("EquipCard") then
			if splayer:getMark("neifaTriggered-Clear") >= 2 then return false end
			room:addPlayerMark(splayer, "neifaTriggered-Clear")
			splayer:drawCards(n, self:objectName())
		end
		return false
	end
}

NeifaTargetMod = sgs.CreateTargetModSkill{
	name = "NeifaTargetMod",
	pattern = ".",
	residue_func = function(self, from, card, to)
		local n = 0
		if from:getMark("neifaBasic-Clear") > 0 and card:isKindOf("Slash") then
			n = n + (from:getMark("neifaBasic-Clear") - 1)
		end
		return n
	end,
	extra_target_func = function(self, from, card)
		local n = 0
		if (from:getMark("neifaBasic-Clear") > 0 and card:isKindOf("Slash"))  then
			n = n + 1
		end
		return n
	end,
}


yuantanyuanshang:addSkill(neifa)
yuantanyuanshang:addSkill(neifaExtra)
extension_pray:insertRelatedSkills("neifa", "#neifa-extra")
if not sgs.Sanguosha:getSkill("neifa_buff") then skills:append(NeifaBuff) end
if not sgs.Sanguosha:getSkill("NeifaTargetMod") then skills:append(NeifaTargetMod) end






GoldCombSkill = sgs.CreateTriggerSkill{
	name = "GoldCombSkill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
                if player:getHandcardNum() < math.min(player:getMaxCards(), 5) then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    player:drawCards(math.min(player:getMaxCards(), 5) - player:getHandcardNum())
                end
            end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("GoldComb")
	end
}
if not sgs.Sanguosha:getSkill("GoldCombSkill") then skills:append(GoldCombSkill) end
GoldComb = sgs.CreateTreasure{
	name = "gold_comb",
	class_name = "GoldComb",
	suit = sgs.Card_Heart,
	number = 12,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("GoldCombSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "GoldCombSkill")
	end
}
GoldComb:setParent(extension_fengfangnu_e_card)


JoanCombSkill = sgs.CreateTriggerSkill{
	name = "JoanCombSkill",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
            if damage.damage > 0 and player:canDiscard(player, "h") then
                room:setTag("CurrentDamageStruct", data)
                if room:askForDiscard(player, self:objectName(), damage.damage,damage.damage, true, false) then
                    room:notifySkillInvoked(player, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    return true
                end
                room:removeTag("CurrentDamageStruct")
            end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("JoanComb")
	end
}
if not sgs.Sanguosha:getSkill("JoanCombSkill") then skills:append(JoanCombSkill) end
JoanComb = sgs.CreateTreasure{
	name = "joan_comb",
	class_name = "JoanComb",
	suit = sgs.Card_Spade,
	number = 12,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("JoanCombSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "JoanCombSkill")
	end
}
JoanComb:setParent(extension_fengfangnu_e_card)


RhinoCombSkill = sgs.CreateTriggerSkill{
	name = "RhinoCombSkill",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) then
                local choiceList = "cancel+RhinoComb_judge"
                if not player:isSkipped(sgs.Player_Discard) then
                    choiceList = string.format("%s+%s", choiceList, "RhinoComb_discard")
                end
                local choice =room:askForChoice(player, self:objectName(),choiceList,data)
                if choice == "RhinoComb_judge" then
                    player:skip(sgs.Player_Judge)
                    room:broadcastSkillInvoke(self:objectName())
                elseif choice == "RhinoComb_discard" then
                    player:skip(sgs.Player_Discard)
                    room:broadcastSkillInvoke(self:objectName())
                end
            end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getTreasure() and target:getTreasure():isKindOf("RhinoComb")
	end
}
if not sgs.Sanguosha:getSkill("RhinoCombSkill") then skills:append(RhinoCombSkill) end
RhinoComb = sgs.CreateTreasure{
	name = "rhino_comb",
	class_name = "RhinoComb",
	suit = sgs.Card_Club,
	number = 12,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("RhinoCombSkill")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "RhinoCombSkill")
	end
}
RhinoComb:setParent(extension_fengfangnu_e_card)

fengfangnu = sgs.General(extension_pray, "fengfangnu", "qun", 3, false)




zhuangshu = sgs.CreateTriggerSkill{
	name = "zhuangshu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and not player:getTreasure() and player:hasEquipArea(5) then
                for _, fengfangnu in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    local cd = room:askForCard(fengfangnu, "..", "@zhuangshu", data, self:objectName())
                    if cd then
                        room:sendCompulsoryTriggerLog(fengfangnu, self:objectName())
                        room:broadcastSkillInvoke(self:objectName())
                        local card 
                        if cd:isKindOf("BasicCard") then
                            card = sgs.Sanguosha:getCard(room:getTag("JC_ID"):toInt())
                        elseif cd:isKindOf("TrickCard") then
                            card = sgs.Sanguosha:getCard(room:getTag("RC_ID"):toInt())
                        elseif cd:isKindOf("EquipCard") then
                            card = sgs.Sanguosha:getCard(room:getTag("GC_ID"):toInt())
                        end
                        room:useCard(sgs.CardUseStruct(card, player, player))
                        break
                    end
                end
			end
		elseif event == sgs.GameStart then
			if player:hasEquipArea(5) and player:hasSkill(self:objectName()) then
                local choiceList = {}
                local rc_id = room:getTag("RC_ID"):toInt()
                local jc_id = room:getTag("JC_ID"):toInt()
                local gc_id = room:getTag("GC_ID"):toInt()
                if rc_id > 0 then
                    --choiceList = string.format("%s+%s", choiceList, "zhuangshu_rc")
                    table.insert(choiceList, "zhuangshu_rc")
                end
                if jc_id > 0 then
                    --choiceList = string.format("%s+%s", choiceList, "zhuangshu_jc")
                    table.insert(choiceList, "zhuangshu_jc")
                end
                if gc_id > 0 then
                    --choiceList = string.format("%s+%s", choiceList, "zhuangshu_gc")
                    table.insert(choiceList, "zhuangshu_gc")
                end
                if next(choiceList) ~= nil then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:broadcastSkillInvoke(self:objectName())
                    --local choice =room:askForChoice(player, self:objectName(),choiceList,data)
                    local choice = room:askForChoice(player, self:objectName(), table.concat(choiceList, "+"))
                    local card 
                    if choice == "zhuangshu_rc" then
                        card = sgs.Sanguosha:getCard(room:getTag("RC_ID"):toInt())
                    elseif choice == "zhuangshu_jc" then
                        card = sgs.Sanguosha:getCard(room:getTag("JC_ID"):toInt())
                    elseif choice == "zhuangshu_gc" then
                        card = sgs.Sanguosha:getCard(room:getTag("GC_ID"):toInt())
                    end
                    local equip_index = card:getRealCard():toEquipCard():location()
                    if player:hasEquipArea(equip_index) then
                        room:useCard(sgs.CardUseStruct(card, player, player))
                    end
                end
            end
		end
		return false
	end,
    can_trigger = function(self, target)
		return target
	end
}

zhuangshu_delete = sgs.CreateTriggerSkill{
	name = "#zhuangshu_delete",
	frequency = sgs.Skill_Compulsory,
    global = true,
	priority = 10,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            local rc_id = room:getTag("RC_ID"):toInt()
            local jc_id = room:getTag("JC_ID"):toInt()
            local gc_id = room:getTag("GC_ID"):toInt()
            --[[if move.from_places:contains(sgs.Player_PlaceEquip) and rc_id > 0 and move.card_ids:contains(rc_id) and move.to_place ~= sgs.Player_PlaceEquip then
				local move1 = sgs.CardsMoveStruct(rc_id, nil, nil, room:getCardPlace(rc_id), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, "card_remover", ""))
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
            if move.from_places:contains(sgs.Player_PlaceEquip) and jc_id > 0 and move.card_ids:contains(jc_id) and move.to_place ~= sgs.Player_PlaceEquip then
				local move1 = sgs.CardsMoveStruct(jc_id, nil, nil, room:getCardPlace(jc_id), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, "card_remover", ""))
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end
            if move.from_places:contains(sgs.Player_PlaceEquip) and gc_id > 0 and move.card_ids:contains(gc_id) and move.to_place ~= sgs.Player_PlaceEquip then
				local move1 = sgs.CardsMoveStruct(gc_id, nil, nil, room:getCardPlace(gc_id), sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, "card_remover", ""))
				room:moveCardsAtomic(move1, true)
				--move.card_ids:removeOne(id)
				data:setValue(move)
			end]]
            --player:gainMark("@y")
            destroyEquip(room, move, "RC_ID")
            destroyEquip(room, move, "JC_ID")
            destroyEquip(room, move, "GC_ID")
		end
		return false
	end,
    can_trigger = function(self, target)
		return target
	end
}

chutivs = sgs.CreateViewAsSkill{
	name = "chuti",
	n = 1,
	expand_pile = "chuti",
		view_filter = function(self, selected, to_select)
		local pat = ".|.|.|chuti"
				return  sgs.Sanguosha:matchExpPattern(pat, sgs.Self, to_select)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
		local acard = sgs.Sanguosha:getCard(cards[1]:getEffectiveId())
		acard:addSubcard(cards[1])
		return acard
		end
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern == "@@chuti"
	end
}

chuti = sgs.CreateTriggerSkill{
	name = "chuti",
	events = {sgs.CardsMoveOneTime},
	view_as_skill = chutivs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getMark(self:objectName().. "-Clear") > 0 then return false end
		local move = data:toMoveOneTime() 
		local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) 
		if (flag == sgs.CardMoveReason_S_REASON_DISCARD) and (move.from and (move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or  move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == player:objectName() 
		and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then 
		local will_use = sgs.IntList()
		for _,id in sgs.qlist(move.card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isAvailable(player)  then
				if card:isKindOf("Jink") or card:isKindOf("Nullification") or (card:isKindOf("Peach") and not player:isWounded()) then
					continue
				else
					will_use:append(id)
				end
			end
		end
		if not will_use:isEmpty() then 
			player:addToPile("chuti", will_use)
            local use = room:askForUseCard(player, "@@chuti", "@chuti")
            if use then
                room:addPlayerMark(player, self:objectName().."-Clear")
            end
            end
            if not player:getPile("chuti"):isEmpty() then
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                for _,cd in sgs.qlist(player:getPile("chuti")) do
                    dummy:addSubcard(cd)
                end
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, self:objectName(), "")
                room:throwCard(dummy, reason, nil)
            end
		end
	end
}

chuti_other = sgs.CreateTriggerSkill{
	name = "#chuti_other",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local move = data:toMoveOneTime() 
		local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) 
		if (flag == sgs.CardMoveReason_S_REASON_DISCARD) and (move.from and (move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or  move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == player:objectName() 
		and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then 
		local will_use = sgs.IntList()
		for _,id in sgs.qlist(move.card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isAvailable(player)  then
				if card:isKindOf("Jink") or card:isKindOf("Nullification") or (card:isKindOf("Peach") and not player:isWounded()) then
					continue
				else
					will_use:append(id)
				end
			end
		end
		if not will_use:isEmpty() then 
            for _,fengfangnu in sgs.qlist(room:findPlayersBySkillName("chuti")) do
                if fengfangnu:getMark("chuti-Clear") > 0 or fengfangnu:objectName() == player:objectName() then continue end
                fengfangnu:addToPile("chuti", will_use)
			--while not player:getPile("chuti"):isEmpty() do
                local use = room:askForUseCard(fengfangnu, "@@chuti", "@chuti")
                if use then
                    room:addPlayerMark(fengfangnu, "chuti-Clear")
                    will_use:removeOne(use:getEffectiveId())
                end
				if not fengfangnu:getPile("chuti"):isEmpty() then
					local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    for _,cd in sgs.qlist(fengfangnu:getPile("chuti")) do
                        dummy:addSubcard(cd)
                    end
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", nil, "chuti", "")
                    room:throwCard(dummy, reason, nil)
				end
                if will_use:isEmpty() then 
                    break
                end
                end
			end
		end
	end,
    can_trigger = function(self, target)
		return target and target:getTreasure() and (target:getTreasure():isKindOf("RhinoComb") or target:getTreasure():isKindOf("GoldComb") or target:getTreasure():isKindOf("JoanComb"))
	end
}



fengfangnu:addSkill(zhuangshu)
fengfangnu:addSkill(zhuangshu_delete)
extension_pray:insertRelatedSkills("zhuangshu", "#zhuangshu_delete")
fengfangnu:addSkill(chuti)
fengfangnu:addSkill(chuti_other)
extension_pray:insertRelatedSkills("chuti", "#chuti_other")
fengfangnu:addRelateSkill("JoanCombSkill")
fengfangnu:addRelateSkill("RhinoCombSkill")
fengfangnu:addRelateSkill("GoldCombSkill")




liangxing = sgs.General(extension_whlw, "liangxing", "qun", 4)

lulue = sgs.CreateTriggerSkill{
	name = "lulue" ,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getHandcardNum() < player:getHandcardNum() and not p:isKongcheng() then
					targets:append(p)
				end
			end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "lulue-invoke", true, true)
                if not target then return false end
                room:broadcastSkillInvoke(self:objectName())
                local choice = room:askForChoice(target, self:objectName(), "lulue_slash+lulue_give")
				if choice == "lulue_slash" then
                    target:turnOver()
                    local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    card:setSkillName(self:objectName())
                    local use = sgs.CardUseStruct()
                    use.from = target
                    use.to:append(player)
                    use.card = card
                    room:useCard(use, false)
                else
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), player:objectName(), self:objectName(),"")
                    room:moveCardTo(target:getHandcards(),player,sgs.Player_PlaceHand,reason)
                    player:turnOver()
                end
			end
		end
		return false
	end
}




zhuxi = sgs.CreateTriggerSkill{
	name = "zhuxi" ,
	events = {sgs.DamageCaused, sgs.DamageInflicted} ,
	frequency = sgs.Skill_NotFrequent ,
	priority = 3 ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local damage = data:toDamage()
        if not damage.from then return false end
		if event == sgs.DamageCaused then
            if damage.to:hasSkill(self:objectName()) and 
            ((damage.to:faceUp() and not damage.from:faceUp()) or (not damage.to:faceUp() and damage.from:faceUp())) then
                damage.damage = damage.damage + 1
                room:sendCompulsoryTriggerLog(damage.to, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
            end
            data:setValue(damage)
        elseif event == sgs.DamageInflicted then
            if damage.from:hasSkill(self:objectName()) and 
            ((damage.to:faceUp() and not damage.from:faceUp()) or (not damage.to:faceUp() and damage.from:faceUp())) then
                damage.damage = damage.damage + 1
                sendComLog(player, self:objectName(), true)
                room:sendCompulsoryTriggerLog(damage.from, self:objectName())
                room:broadcastSkillInvoke(self:objectName())
            end
            data:setValue(damage)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

liangxing:addSkill(lulue)
liangxing:addSkill(zhuxi)





sgs.Sanguosha:addSkills(skills)	--這行一定要在最後，不然以skills:append的方式加入可獲得技能不會生效
sgs.LoadTranslationTable{
	["fixandadd"] = "自订包",
	["fixandadd_hulaoguan"] = "虎牢关",
	["fixandadd_guandu"] = "官渡之战",
	["hulaoguan_card"] = "虎牢关装备",
	["extension_whlw"] = "文和乱武",
	["extension_mobile"] = "手机OL",
	["extension_zlzy"] = "逐鹿天下",
	["fixandadd_twyj"] = "台湾一将成名",
	["fixandadd_heg"] = "国战身份局",
	["fixandadd_dragonboat"] = "同舟共济",
    ["extension_pray"] = "祈福",
	
	["shenlvbu2_2017_new"] = "神吕布",
	["#shenlvbu2_2017_new"] = "暴怒战神",
	["illustrator:shenlvbu2_2017_new"] = "LiuHeng",
	["shenwei_2017_new"] = "神威",
	[":shenwei_2017_new"] = "锁定技，摸牌阶段，你多摸三张牌；锁定技，你的手牌上限+3。",
	["$shenwei_2017_new1"] = "我不会输给任何人~",
	["$shenwei_2017_new2"] = "萤烛之火也敢与日月争辉？",
	["shenji_2017_new"] = "神戟",
	[":shenji_2017_new"] = "锁定技，若你的装备区里没有武器牌，你使用【杀】的额外目标数上限+2，次数上限+1。",
	["$shenji_2017_new1"] = "尽想赢我？痴人说梦！",
	["$shenji_2017_new2"] = "杂鱼们都去死吧！",
	["shenlvbuguitwentyeighteen"] = "神吕布",
	["#shenlvbuguitwentyeighteen"] = "神鬼无前",
	["illustrator:shenlvbuguitwentyeighteen"] = "LiuHeng",
	["jiwu_2018_new"] = "极武",
	[":jiwu_2018_new"] = "出牌阶段，你可以弃置一张牌，令你于此回合内拥有一项：“强袭”、“铁骑”、“旋风”、“完杀”。",
	["$jiwu_2018_new1"] = "我。是不可战胜的！",
	["$jiwu_2018_new2"] = "今天，就让你们感受一下真正的绝望~",
	["$lua_wansha1"] = "蝼蚁，怎容偷生！",
	["$lua_wansha2"] = "沉沦吧，在这无边的恐惧！",
	["$tieji3"] = "哈哈哈，破绽百出！",
	["$tieji4"] = "我要让这虎牢关下，血流成河！",
	["~shenlvbuguitwentyeighteen"] = "你们的项上人头，我改日再取~",
	
	
	
	["imba_lifeng"] = "李丰-第二版",
	["&imba_lifeng"] = "李丰",
	["#imba_lifeng"] = "继父尽事",
	["illustrator:imba_lifeng"] = "NOVART",
	["imba_tunchu"] = "屯储",
	[":imba_tunchu"] = "摸牌阶段，若你没有“粮”，则你可以额外摸两张牌，然后你可以将至少一张手牌置于武将牌上，称为“粮”；若你有“粮”，你不能使用【杀】。",
	["$imba_tunchu1"] = "屯粮事大，暂不与尔等计较。",
	["$imba_tunchu2"] = "屯粮待战，莫动刀枪。",
	["@imba_tunchu"] = "你可以将至少一张手牌置为“粮”",
	["imba_shuliang"] = "输粮",
	[":imba_shuliang"] = "一名角色的结束阶段，若其手牌数小于体力值，你可以移去一张“粮”，令其摸两张牌。",
	["$imba_shuliang1"] = "将军持劳，酒肉慰劳。",
	["$imba_shuliang2"] = "将军，牌来了！",
	["@imba_shuliang"] = "你可以发动“输粮”",
	["~imba_shuliang"] = "选择一张“粮”→点击确定",
	["~imba_lifeng"] = "吾有负丞相重托……",
	
	["illustrator:lifeng"] = "NOVART",
	["$tunchu1"] = "屯粮事大，暂不与尔等计较。",
	["$tunchu2"] = "屯粮待战，莫动刀枪。",
	["$shuliang1"] = "将军持劳，酒肉慰劳。",
	["$shuliang2"] = "将军，牌来了！",
	["~lifeng"] = "吾有负丞相重托……",
	
	["baosanniang"] = "鲍三娘",
	["#baosanniang"] = "青不协扶",
	["illustrator:baosanniang"] = "DH",
	["wuniang"] = "武娘",
	[":wuniang"] = "当你使用或打出【杀】时，你可以获得一名其他角色的一张牌，然后其摸一张牌，如果武将“关索”在场，你可以令“关索”也摸一张牌。",
	["wuniang-invoke"] = "你可以获得一名其他角色的一张牌，然后其摸一张牌<br/> <b>操作提示</b>: 选择一名与你不同且有手牌的角色→点击确定<br/>",
	["wuniang:draw"] = "你想发动“武娘”令座位 %src 号关索玩家摸一张牌吗?",
	["$wuniang1"] = "虽为女子身，不输男儿郎",
	["$wuniang2"] = "剑舞轻盈，沙场克敌",
	["xushen"] = "许身",
	[":xushen"] = "限定技，当其他男性角色令你离开濒死状态后，如果“关索”不在场，其可以选择是否用“关索”代替其武将，然后你回复1点体力并获得技能“镇南”。",
	["$xushen1"] = "救命之恩，涌泉相报",
	["$xushen2"] = "解我危难，报君华彩",
	["zhennan"] = "镇南",
	[":zhennan"] = "当你成为【南蛮入侵】的目标时，你可以对一名其他角色造成1~3点随机伤害。",
	["zhennan-invoke"] = "你可以对一名其他角色造成1~3点随机伤害<br/> <b>操作提示</b>: 选择一名与你不同的角色→点击确定<br/>",
	["$zhennan1"] = "镇守南中，夫君无忧",
	["$zhennan2"] = "与君携手，定平蛮夷",
	["~baosanniang"] = "我还想与你…共骑这雪花骏",
	
	
	["$ol_liegong1"] = "中！",
	["$ol_liegong2"] = "百步穿杨！",
	
	["$olqianxi1"] = "喊什么喊，我敢杀你！",
	["$olqianxi2"] = "笑什么笑，叫你得意！",
	
	["$olzishou1"] = "荆襄之地，固若金汤。",
	["$olzishou2"] = "江河霸主，何惧之有？",
	
	["$olmiji1"] = "此计，可歼敌精锐！",
	["$olmiji2"] = "此举，可破敌之围！",
	
	["$olanxu1"] = "和鸾雍雍,万福攸同。",
	["$olanxu2"] = "君子乐胥,万邦之屏。",
	
	["$olrende1"] = "施仁布泽，乃我大汉立国之本。",
	["$olrende2"] = "同心同德，救困扶危！",
	
	["$olshenxian1"] = "愿尽己力，为君分忧。",
	["$olshenxian2"] = "抚慰军心，以安国事。",
	
	["$olmeibu1"] = "萧墙之乱，宫闱之衅，实为吴国之祸啊！",
	["$olmeibu2"] = "若要动手，就请先杀我吧！",
	["$olmumu1"] = "立储乃国家大事，我们姐妹不便参与。",
	["$olmumu2"] = "只求相夫教子，不求参政议事。",
	["$olmeibu21"] = "萧墙之乱，宫闱之衅，实为吴国之祸啊！",
	["$olmeibu22"] = "若要动手，就请先杀我吧！",
	["$olmumu21"] = "立储乃国家大事，我们姐妹不便参与。",
	["$olmumu22"] = "只求相夫教子，不求参政议事。",
	["~ol_sun1uyu"] = "姐姐，你且好自为之。",
	
	["$olpojun1"] = "大军在此！汝等休想前进一步！",
	["$olpojun2"] = "敬请养精蓄锐！",
	
	["$olyongsi1"] = "大汉天下，已半入我手！",
	["$olyongsi2"] = "玉玺在手，天下我有！",
	["$oljixi1"] = "我才是皇帝！",
	["$oljixi2"] = "你们都得听我的号令！",
	
	["$olleiji1"] = "成为黄天之士的祭品吧！",
	["$olleiji2"] = "呼风唤雨，驱雷策电！",
	
	["$yanyu1"] = "伴君一生不寂寞。",
	["$yanyu2"] = "感君一回顾，思君朝与暮。",
	
	["$zhenwei1"] = "",
	
	["$shixin1"] = "释怀之戾气，化君之不悦。",
	["$shixin2"] = "星星之火，安能伤我。",
	
	["$fenyin1"] = "披发亢歌，至死不休。",
	["$fenyin2"] = "力不竭，战不止。",
	
	["$zhanyi1"] = "以战养战，视敌而战。",
	["$zhanyi2"] = "战，可以破敌；意，可以守御。",
	
	["$zhijian2"] = "为臣者，当冒死以谏。",
	
	["$xueyi1"] = "",
	["$xueyi2"] = "",
	
	["$niaoxiang1"] = "此战必是有死无生！",
	["$niaoxiang2"] = "抢占先机，占尽优势！",
	
	["$cihuai1"] = "",
	["$cihuai2"] = "",
	
	["$xunxun3"] = "让我先探他一探。",
	["$xunxun4"] = "船也不是一天就能造出来。",
	
	["$cangji"] = "",
	
	["$nosjizhi1"] = "哼~",
	["$nosjizhi2"] = "哼哼~",
	
	["$chizhong2"] = "",
	
	["#no_bug_caifuren"] = "襄江的蒲苇",
	["no_bug_caifuren"] = "蔡夫人",
	["illustrator:no_bug_caifuren"] = "Dream彼端",
	["designer:no_bug_caifuren"] = "B.LEE",
	["lua_xianzhou"] = "献州",
	[":lua_xianzhou"] = "限定技，出牌阶段，你可以将装备区里的所有牌交给一名角色，令其选择一项：1．令你回复X点体力；2．选择其攻击范围内的一至X名角色，然后对这些角色各造成1点伤害。（X为你以此法交给其的牌数）",
	["xianzhou_damage"] = "对攻击范围内一至X名角色造成伤害",
	["xianzhou_recover"] = "让蔡夫人回复X点体力",
	["@lua_xianzhou"] = "你可以对一至X名角色造成伤害",
	["~lua_xianzhou"] = "选择若干名角色→点击确定",
	["$lua_xianzhou1"] = "献荆襄九郡，图一世之安。",
	["$lua_xianzhou2"] = "丞相挟天威而至，吾等安敢不降？",
	["~no_bug_caifuren"] = "孤儿寡母，何必赶尽杀绝呢...",
	
	["lua_zhiman"] = "制蛮",
	[":lua_zhiman"] = "当你对其他角色造成伤害时，你可以防止此伤害，获得其装备区或判定区里的一张牌。",
	["$lua_zhiman1"] = "蛮夷可抚，不能剿。",
	
	["olpojun_num"] = "选择移除数",
	
	["whlw_fanchou"] = "樊稠",
	["#whlw_fanchou"] = "庸生变难",
	["xingluan"] = "兴乱",
	[":xingluan"] = "出牌阶段限一次，当你使用的仅指定一个目标的牌结算完成后，你可以从牌堆里获得一张点数为6的牌。",
	["$xingluan1"] = "大兴兵争，长安当乱。",
	["$xingluan2"] = "勇猛兴军，乱世当立。",
	["~whlw_fanchou"] = "唉，稚然疑心，甚重......",

	["whlw_zhangji"] = "张济",
	["#whlw_zhangji"] = "武威雄豪",
	["lueming"] = "掠命",
	[":lueming"] = "出牌阶段限一次，你选择一名装备区装备少于你的其他角色，令其选择一个点数，然后你进行判定：若点数相同，你对其造成2点伤害；不同，你随机获得其区域内的一张牌。",
	["#lueming_judge_same"] = "点数相同",
	["#lueming_judge_not_same"] = "点数不同",
	["#lueming_judge"] = "%from 执行掠命的判定结果为 %arg",
	["$lueming1"] = "劫命掠财，毫不费力。",
	["$lueming2"] = "人财，皆掠之，嘿嘿。",
	["tunjiun"] = "屯军",
	[":tunjiun"] = "限定技，出牌阶段，你可以选择一名角色，令其随机使用牌堆中的X张不同类型的装备牌（不替换原有装备，X为你发动“掠命”的次数）",
	["$tunjiun1"] = "得封侯爵，屯军弘农。",
	["$tunjiun2"] = "屯军弘农，养精蓄锐。",
	["~whlw_zhangji"] = "哪里来的乱箭？",

	["whlw_guosi"] = "郭汜",
	["#whlw_guosi"] = "党豺为虐",
	["tanbei"] = "贪狈",
	[":tanbei"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.令你随机获得其区域内的一张牌，此回合不能再对其使用牌；2.令你此回合对其使用牌没有次数和距离限制。",
	["$tanbei1"] = "此机，我怎么会错失。",
	["$tanbei2"] = "你的东西，现在是我的了！",
	["tanbei_give_card"] = "随机获得你区域内的一张牌，此回合不能再对你使用牌",
	["tanbei_unlimited_use"] = "对你使用牌没有次数和距离限制",
	["cidao"] = "伺盗",
	[":cidao"] = "出牌阶段限一次，当你对一名其他角色连续使用两张牌后，你可将一张手牌当【顺手牵羊】对其使用（目标须合法）。",
	["@cidao"] = "你可将一张手牌当【顺手牵羊】对其使用",
	["~cidao"] = "选择一张牌→选择目标→点击确定",
	["$cidao1"] = "连发伺动，顺手可得。",
	["$cidao2"] = "伺机而劫，此地可窃。",
	["~whlw_guosi"] = "伍习，你......",

	["whlw_lijue"] = "李傕",
	["#whlw_lijue"] = "奸谋恶勇",
	["langxi"] = "狼袭",
	[":langxi"] = "准备阶段，你可以对一名体力小于或等于你的其他角色造成0-2点随机伤害。",
	["langxi-invoke"] = "你可以对一名体力小于或等于你的其他角色造成0-2点随机伤害<br/> <b>操作提示</b>: 选择一名体力小于或等于你且与你不同的角色→点击确定<br/>",
	["$langxi1"] = "袭夺之势，如狼噬骨。",
	["$langxi2"] = "引吾至此，怎能不袭掠之？",
	["yisuan"] = "亦算",
	[":yisuan"] = "出牌阶段限一次，当你使用的锦囊牌进入弃牌堆时，你可以减1点体力上限，从弃牌堆获得之。",
	["$yisuan1"] = "吾亦能善算谋划。",
	["$yisuan2"] = "算计人心，我也可略施一二。",
	["~whlw_lijue"] = "若无内讧，也不至如此。",

	["zhaoguangzhaotong"] = "赵广&赵统",
	["&zhaoguangzhaotong"] = "赵广赵统",
	["#zhaoguangzhaotong"] = "效捷致果",
	["yizan"] = "翊赞",
	[":yizan"] = "你可以将两张牌（其中至少一张基本牌）当任意基本牌使用或打出。",
	["$yizan1"] = "",
	["$yizan2"] = "",
	[":yizan-EX"] = "你可以将一张基本牌当任意基本牌使用或打出。",
	["yizan_slash"] = "翊赞",
	["longyuan"] = "龙渊",
	[":longyuan"] = "觉醒技，当你使用或打出一张牌时，若你发动过至少三次“翊赞”，则你将其效果改为“你可以将一张基本牌当任意基本牌使用或打出”。",
	["$longyuan1"] = "",
	["$longyuan2"] = "",
	["~zhaoguangzhaotong"] = "",
	
	["guandu_xuyou"] = "许攸",
	["&guandu_xuyou"] = "许攸",
	["#guandu_xuyou"] = "",
	["guandu_shicai"] = "识才",
	["&talent"] = "识才",
	[":guandu_shicai"] = "牌堆顶的牌于你的出牌阶段内对你可见；出牌阶段，你可以弃置一张牌并获得牌堆顶的牌，若你的手牌中有此阶段内以此法获得的牌，你不能发动此技能。",
	["$guandu_shicai1"] = "遣轻骑以袭许都，大事可成。",
	["$guandu_shicai2"] = "主公不听吾之言，实乃障目不见泰山也！",
	["chenggong"] = "逞功",
	[":chenggong"] = "当一名角色使用牌指定目标后，若目标数不少于2，你可以令其摸一张牌。",
	["chenggong:to_draw"] = "你可以发动“逞功”，令 %src 摸一张牌",
	["gd_zezhu"] = "择主",
	[":gd_zezhu"] = "出牌阶段限一次，你可以选择一至两名其他角色（若你不为主公，则其中必须有主公）。你依次获得他们各一张牌（若目标角色没有牌，则改为你摸一张牌），然后分别将一张牌交给他们。",
	["@gd_zezhu-give"] = "请将一张牌交给 %src",
	["~guandu_xuyou"] = "我军之所以败，皆因尔等指挥不当！",
	
	["xurong"] = "徐荣",
	["&xurong"] = "徐荣",
	["#xurong"] = "魔王之腕",
	["xionghuo"] = "凶镬",
	[":xionghuo"] = "游戏开始时，你获得3枚“暴戾”标记；出牌阶段，你可以交给一名其他角色1枚“暴戾”标记；当你对其他角色造成伤害时，若其有“暴戾”标记，此伤害+1；其他角色的出牌阶段开始时，若其有“暴戾”标记，其移去所有“暴戾”标记并随机选择一项：1.受到你对其造成的1点火焰伤害，且此回合其使用【杀】不能指定你为目标；2.失去1点体力，且此回合其手牌上限-1；3.你随机获得其手牌和装备区里的各一张牌。",
	["$xionghuo1"] = "此镬加之于你，定有所伤！",
	["$xionghuo2"] = "凶镬沿袭，怎会轻易无伤？",
	["@brutal"] = "暴戾",
	["xionghuo_choice1"] = "受到你对其造成的1点火焰伤害，且此回合其使用【杀】不能指定你为目标",
	["xionghuo_choice2"] = "失去1点体力，且此回合其手牌上限-1",
	["xionghuo_choice3"] = "你随机获得其手牌和装备区里的各一张牌",
	["#xionghuo_log"] = "%from 的凶镬效果为 %arg",
	["shajue"] = "杀绝",
	[":shajue"] = "锁定技，当其他角色进入濒死状态时，若其体力值小于0，你获得1枚“暴戾”标记，然后若其因牌造成的伤害而进入濒死状态，你获得此牌。",
	["$shajue1"] = "杀伐决绝，不留后患。",
	["$shajue2"] = "吾既出，必绝之！",
	["~xurong"] = "此生无悔，心中无愧！",

	["dragon_move"] = "移动龙印标记",
	["phoenix_move"] = "移动风印标记",
	["jianjie_death_move"] = "令阵亡角色移转龙印或风印标记",

	["@moshi_ask"] = "你可以发动“默识”",
	["~moshi"] = "选择一张牌→选择目标(若有)→点击确定",

	["lua_wansha"] = "完杀",
	[":lua_wansha"] = "锁定技，不处于濒死状态的其他角色于你的回合内不能使用【桃】。",

	["olzhixi"] = "止息",
	[":olzhixi"] = "若你于出牌阶段内使用过锦囊牌，你的锦囊牌视为【杀】直到回合结束，且穆穆技能发动角色视为在你攻击范围内。",
	["obtain"] = "获得",

	["#jicipindian"] = "%from 执行激词的效果令此牌的点数 %arg 于此次拼点为点数 %arg2",
	
	["~qingjian"] = "选择一张牌→选择目标→点击确定",
	
	["no_bug_caiwenji"] = "OL蔡文姬",
	["&no_bug_caiwenji"] = "蔡文姬",
	["#no_bug_caiwenji"] = "金壁之才",
	["ChenqingAsk"] = "你可以发动“陈情”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["ChenqingDiscard"] = "请弃置四张牌<br/> <b>操作提示</b>: 选择四张牌→点击确定<br/>",
	["lua_chenqing"] = "陈情",
	[":lua_chenqing"] = "<font color=\"green\"><b>每轮限一次，</b></font>当一名角色处于濒死状态时，你可以令另一名其他角色摸四张牌，然后弃置四张牌。若其以此法弃置的四张牌花色各不相同，则视为该角色对濒死的角色使用一张【桃】。",
	["$lua_chenqing1"] = "乱世陈情,字字血泪。",
	["$lua_chenqing2"] = "陈，生死离别之苦；悲，乱世之跌宕。~",
	["~no_bug_caiwenji"] = "命运弄人~",



	["sec_rev_shenluxun"] = "神陆逊-第二版",
	["&sec_rev_shenluxun"] = "神陆逊",
	["#sec_rev_shenluxun"] = "红莲业火",
	["illustrator:sec_rev_shenluxun"] = "Thinking",
	["zhanhuo_sec_rev"] = "绽火",
	[":zhanhuo_sec_rev"] = "限定技，出牌阶段，你可以弃所有“军略”标记并选择至多等量的处于连环状态的角色，这些角色各弃置装备区里的所有牌，然后对其中一名角色造成1点火焰伤害。",
	["$zhanhuo_sec_rev1"] = "绽东吴业火，烧敌军数千！",
	["$zhanhuo_sec_rev2"] = "业火映东水，吴志绽敌营！",
	["~sec_rev_shenluxun"] = "东吴业火，终究熄灭……",



	["@ol_jiewei-to"] = "请选择移动此卡牌的目标角色",

	["@shensu3"] = "你可以跳过弃牌阶段并翻面发动“神速”",

	["juexiang-invoke"] = "你可以发动“绝响”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",

	["sec_rev_shenzhangliao"] = "神张辽-第二版",
	["&sec_rev_shenzhangliao"] = "神张辽",
	["#sec_rev_shenzhangliao"] = "雁门之刑天",
	["illustrator:sec_rev_shenzhangliao"] = "town",
	["duorui_sec_rev"] = "夺锐",
	[":duorui_sec_rev"] = "当你于出牌阶段内对其他角色造成伤害后，你可以废除一个装备栏，然后选择该角色的武将牌上的一个技能（限定技、觉醒技、主公技除外），若如此做，令其于其下回合结束之前此技能无效，然后你于其下回合结束或其死亡之前拥有此技能且不能发动“夺锐”。",
	["$duorui_sec_rev1"] = "夺敌军锐气，杀敌方士气。",
	["$duorui_sec_rev2"] = "尖锐之势，吾亦可一人夺之。",
	["zhiti_sec_rev"] = "止啼",
	[":zhiti_sec_rev"] = "锁定技，当你与攻击范围内已受伤的角色拼点赢时或当你因执行【决斗】而对已受伤的你或攻击范围内已受伤的角色造成伤害后，你选择一项：1.恢复一个坐骑栏以外的装备栏；2.恢复两个坐骑栏；锁定技，你攻击范围内已受伤的其他角色的手牌上限-1；锁定技，当你受到伤害后，若来源在你的攻击范围内且已受伤，你恢复一个装备栏。",
	["$zhiti_sec_rev1"] = "江东小儿安敢啼哭？",
	["$zhiti_sec_rev2"] = "娃闻名止啼，孙损十万休！",
	["~sec_rev_shenzhangliao"] = "我也有被孙仲谋所伤之时？",

	["EquipArea_0"] = "武器栏",
	["EquipArea_1"] = "防具栏",
	["EquipArea_2"] = "防御马",
	["EquipArea_3"] = "进攻马",
	["EquipArea_4"] = "宝物栏",

	

	["$kanpo3"] = "",
	["$kanpo4"] = "",
	
	["~ExtraCollateral"] = "选择另外一名有武器牌目标→选择被杀目标→点击确定",

	["drawCards"] = "摸牌",
	["addDamage"] = "增加伤害",

	["#xiahoudun_xhly"] = "独眼的罗刹",
	["xiahoudun_xhly"] = "星火燎原-夏侯惇",
	["&xiahoudun_xhly"] = "夏侯惇",
	["illustrator:xiahoudun_xhly"] = "DH",
	["qingjian_xhly"] = "清俭",
	[":qingjian_xhly"] = "<font color=\"green\"><b>每回合限一次，</b></font>当你在摸牌阶段外获得牌后，你可以展示任意张牌并交给一名其他角色，你给出的牌每有一种类别，当前回合角色本回合手牌上限+1。",
	["@qingjian_xhly"] = "你可以发动“清俭”",
	["~qingjian_xhly"] = "选择若干张牌→选择目标→点击确定",
	["$qingjian_xhly1"] = "福生于清俭，德生于卑退。",
	["$qingjian_xhly2"] = "钱财乃身外之物。",
	["~xiahoudun_xhly"] = "诸多败绩，有负丞相重托......",

	["#caoying"] = "龙城凤鸣",
	["caoying"] = "曹婴",
	["illustrator:xiahoudun_xhly"] = "花第",
	["lingren"] = "凌人",
	[":lingren"] = "出牌阶段限一次，当你使用【杀】或伤害类锦囊牌指定目标后，你可以猜测其中一个目标的手牌是否有基本牌、锦囊牌或装备牌。至少猜对一项则此牌对其伤害+1；至少猜对两项则你摸两张牌；猜对三项则你获得“奸雄”和“行殇”直到你下回合开始。",
	["lingren-invoke"] = "你可以发动“凌人”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["lingren_basic_guess"] = "是否有基本牌",
	["lingren_trick_guess"] = "是否有锦囊牌",
	["lingren_equip_guess"] = "是否有装备牌",
	["lingren_yes"] = "有",
	["lingren_no"] = "无",
	["$lingren_basic_guess"] = "%from 猜测 %to %arg 基本牌",
	["$lingren_trick_guess"] = "%from 猜測 %to %arg 锦囊牌",
	["$lingren_equip_guess"] = "%from 猜測 %to %arg 装备牌",
	["$lingren_guess_result"] = "%from 猜對 %arg 項 ",
	["$lingren_damage_buff"] = "%from 执行“%arg”的效果，%card 对 %to 的伤害值+1",
	["$lingren1"] = "敌势已缓，修要走了，老贼！",
	["$lingren2"] = "精兵如炬，困龙难飞！",
	["fujian"] = "伏间",
	[":fujian"] = "锁定技，结束阶段，你随机观看一名其他角色的X张手牌（X为全场手牌数最少的角色手牌数）。",
	["$fujian_to_all_log"] = "%from 观看了 %to 若干张手牌",
	["$fujian_show_card"] = "因 %arg 技能，你 ( %from ) 观看 %to 的手牌为 %card",
	["$fujian1"] = "兵者，诡道也。",
	["$fujian2"] = "良资军备，一览无遗。",
	["~caoying"] = "曹魏天下存，魂归故土安。",

	["liuye"] = "刘晔",
	["&liuye"] = "刘晔",
	["#liuye"] = "佐世之才",
	["polu"] = "破橹",
	[":polu"] = "锁定技，回合开始时，若你的装备区内没有【霹雳车】，则你使用一张【霹雳车】；当你受到1点伤害后，若你的装备区内没有【霹雳车】，则你摸一张牌。",
	["$polu1"] = "设此发石车，可破袁军高橹。",
	["$polu2"] = "霹雳之声，震丧敌胆。",
	["choulve"] = "筹略",
	[":choulve"] = "出牌阶段开始时，你可以令一名有牌的其他角色选择是否交给你一张牌，若其选择是，则你可以视为使用上一张对你造成伤害的不为延时锦囊的牌。",
	["choulve-invoke"] = "你可以选择其中一名角色，发动“筹略”",
	["@choulve-give"] = "你可以交给 %src 一张牌",
	["choulve:CL_askForUseCard"] = "你可以使用【%src】",
	["@choulve"] = "请为【%src】选择目标",
	["~choulve"] = "按照此牌使用方式指定角色→点击确定",
	["$choulve1"] = "依此计行，可安军心。",
	["$choulve2"] = "破袁之策，吾已有计。",
	["~liuye"] = "唉~于上不得佐君主，于下不得亲同僚，吾愧为佐世人臣！",	

	["bianshen"] = "变身",
	
	["fuhuo"] = "复活",

	["#xiahoubawitholshensu"] = "棘途壮志",
	["xiahoubawitholshensu"] = "夏侯霸",
	["illustrator:xiahoubawitholshensu"] = "熊猫探员",
	["baobian_with_ol_shensu"] = "豹变",
	[":baobian_with_ol_shensu"] = "锁定技，若你的体力值：不大于3，你拥有“挑衅”；不大于2，你拥有“咆哮”；为1，你拥有“神速”。",
	["$tiaoxin5"] = "跪下受降，饶你不死！",
	["$tiaoxin6"] = "黄口小儿，可听过将军名号？",
	["$paoxiao6"] = "喝啊~~~",
	["$paoxiao7"] = "受死吧！",
	["$ol_shensu3"] = "冲杀敌阵，来去如电！",
	["$ol_shensu4"] = "今日有恙在身，须得速战速决！",
	["~xiahoubawitholshensu"] = "弃魏投蜀，死而无憾……",
	
	["#no_bug_sunquan"] = "年轻的贤君",
	["no_bug_sunquan"] = "孙权",
	["jiuyuan_no_bug"] = "救援",
	[":jiuyuan_no_bug"] = "主公技，当其他吴势力角色对其使用【桃】时，若其体力值大于你，其可以终止此【桃】结算，若如此做，你回复1点体力，其摸一张牌。 ",
	["$jiuyuan_no_bug1"] = "好舒服啊",
	["$jiuyuan_no_bug2"] = "有汝辅佐，甚好！",
	["~no_bug_sunquan"] = "父亲，大哥，仲谋愧矣……",

	["muso_halberd"] = "无双方天戟",
	[":muso_halberd"] = "装备牌·武器<br /><b>攻击范围</b>：4<br /><b>武器技能</b>：你使用【杀】对目标角色造成伤害后，你可以摸一张牌或弃置目标角色一张牌。",
	["MusoHalberdSkill"] = "无双方天戟",
	["#MusoHalberdSkill_log"] = "%from 的“<font color=\"yellow\"><b>无双方天戟</b></font>”效果被触发",
	["muso_halberd_draw"] = "摸一张牌",
	["muso_halberd_discard"] = "弃置目标角色一张牌",

	["long_pheasant_tail_feather_purple_gold_crown"] = "束发紫金冠",
	[":long_pheasant_tail_feather_purple_gold_crown"] = "装备牌·宝物<br /><b>宝物技能</b>：准备阶段，你可以对一名其他角色造成1点伤害。",
	["LongPheasantTailFeatherPurpleGoldCrown-invoke"] = "你可以对一名其他角色造成1点伤害<br/> <b>操作提示</b>: 选择一名与你不同的角色→点击确定<br/>",
	["LongPheasantTailFeatherPurpleGoldCrownSkill"] = "束发紫金冠",

	["red_cotton_hundred_flower_robe"] = "红棉百花袍",
	[":red_cotton_hundred_flower_robe"] = "装备牌·防具<br /><b>防具技能</b>：锁定技，防止你受到的属性伤害。",
	["#RedCottonHundredFlowerRobeProtect"] = "%from 的“<font color=\"yellow\"><b>红棉百花袍</b></font>”效果被触发，防止了 %arg 点伤害[%arg2]",
	
	["linglong_lion_rough_band"] = "玲珑狮蛮带",
	[":linglong_lion_rough_band"] = "装备牌·防具<br /><b>防具技能</b>：当其他角色使用牌指定你为唯一目标后，你可以进行一次判定，若判定结果为红桃，则此牌对你无效。",
	["LinglongLionRoughBandSkill"] = "玲珑狮蛮带",
	["#LinglongLionRoughBandProtect"] = "%from 的“<font color=\"yellow\"><b>玲珑狮蛮带</b></font>”效果被触发",

	["#Move_to_no_equip_area_log"] = "%from 废除 %arg 装备区域，%card 移至弃牌堆",
	
	["#zengdao_BUFF"] = "因 %from 有 “刀”，此次造成的伤害值+1",

	["#majun"] = "没渊瑰璞",
	["majun"] = "马钧",
	["illustrator:majun"] = "NOVART",
	["jingxie"] = "精械",
	[":jingxie"] = "当你进入濒死状态时，你可以重铸一张防具牌，然后令你的体力值回复至1。出牌阶段，你可以展示一张防具牌或【诸葛连弩】然后以以下规则强化此装备牌：\
	【诸葛连弩】攻击范围改至3；\
	【八卦阵】防具技能判定条件改为不为黑桃；\
	【仁王盾】防具技能增加红桃【杀】无效；\
	【白银狮子】触发回复体力时摸两张牌；\
	【藤甲】防具技能增加不会被横置。",
	["$jingxie1"] = "",
	["$jingxie2"] = "",
	["@jingxie"] = "你可以重铸一张防具牌",
	["#jingxie_Crossbow_enhance"] = "因 %from 的精械技能，此房间 %card 攻击范围改至3",
	["#jingxie_EightDiagram_enhance"] = "因 %from 的精械技能，此房间 %card 防具技能判定条件改为不为黑桃",
	["#jingxie_RenwangShield_enhance"] = "因 %from 的精械技能，此房间 %card 防具技能增加红桃【杀】无效",
	["#jingxie_SilverLion_enhance"] = "因 %from 的精械技能，此房间因 %card 回复体力时摸两张牌",
	["#jingxie_Vine_enhance"] = "因 %from 的精械技能，此房间 %card 防具技能增加不会被横置",
	["#jingxie_EightDiagram_armor_buff"] = "因 %from 的【八卦阵】精械过，【八卦阵】判定条件改为不为黑桃",
	["#jingxie_RenwangShield_armor_buff"] = "因 %from 的【仁王盾】精械过，【仁王盾】增加红桃【杀】无效",
	["#jingxie_SilverLion_armor_buff"] = "因 %from 的【白银狮子】精械过，%from 因【白银狮子】回复体力时摸两张牌",
	["#jingxie_Vine_armor_buff"] = "因 %from 的【藤甲】精械过，%from 不会被横置",
	["qiaosi"] = "巧思",
	[":qiaosi"] = "出牌阶段限一次，你可以从已下6个选项中选择至多3个选项：\
	1.获得牌堆里两张锦囊牌；\
	2.获得牌堆里一张装备牌；\
	3.获得牌堆里一张酒或杀；\
	4.获得牌堆里一张桃或闪；\
	5.获得牌堆里一张锦囊牌；\
	6.获得牌堆里两张装备牌；\
	(若获得的锦囊牌或装备牌牌数大于2，其中一张牌换为任意基本牌)。\
	然后你选择一项：1.弃置等量的牌；2.将等量的牌交给一名其他角色。",
	["$qiaosi1"] = "",
	["$qiaosi2"] = "",
	["qiaosi_yes"] = "获得",
	["qiaosi_no"] = "不获得",
	["qiaosi_two_trick_choice"] = "两张锦囊牌",
	["qiaosi_one_equip_choice"] = "一张装备牌",
	["qiaosi_one_analeptic_or_slash_choice"] = "一张酒或杀",
	["qiaosi_one_peach_or_jink_choice"] = "一张桃或闪",
	["qiaosi_one_trick_choice"] = "一张锦囊牌",
	["qiaosi_two_equip_choice"] = "两张装备牌",
	["qiaosi_throw"] = "弃置等量的牌",
	["qiaosi_give"] = "将等量的牌交给一名其他角色",
	["qiaosi-invoke"] = "你可以发动“巧思”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["qiaosi_exchange"] = "请选择等量的牌交给对方<br/> <b>操作提示</b>: 选择牌直到可以点确定<br/>",
	["~majun"] = "",

	["@olyongsi-discard"] = "请弃置一张牌或点取消损失一点体力<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>",

	["#zhangqiying"] = "青黄龙母",
	["zhangqiying"] = "张琪瑛",
	["illustrator:zhangqiying"] = "OL",
	["falu"] = "法箓",
	[":falu"] = "锁定技，当你的牌因弃置而置入弃牌堆后，若其中有：黑桃牌，你获得一枚“紫微”；梅花牌，你获得一枚“后土”；红桃牌，你获得一枚“玉清”；方块牌，你获得一枚“勾陈”（每种标记至多同时拥有一枚）。锁定技，游戏开始时，你获得已上四种标记。",
	["$falu1"] = "求法之道，以司籙籍。",
	["$falu2"] = "取舍有法，方得其法。",
	["zhenyi"] = "真仪",
	[":zhenyi"] = "当一张判定牌生效前，你可以弃一枚“紫微”，然后将判定结果改为黑桃5或红桃5；当你处于濒死状态时，你可以弃一枚“后土”，然后将一张手牌当【桃】使用；当你造成伤害时，你可以弃一枚“玉清”，然后进行一次判定，若判定结果为黑色，此伤害+1；当你受到属性伤害后，你可以弃一枚“勾陈”，然后你从牌堆获得三种类别的牌各一张。",
	["$zhenyi1"] = "不疾不徐，自爱自重。",
	["$zhenyi2"] = "紫薇星辰，斗数之仪。",
	["zhenyi_Spade"] = "黑桃5",
	["zhenyi_Heart"] = "红桃5",
	["@zhenyi"] = "你可以将一张手牌当【桃】使用",
	["~zhenyi"] = "选择一张手牌→点击确定",
	["dianhua"] = "点化",
	[":dianhua"] = "准备阶段或结束阶段，你可以观看牌堆顶X张牌（X为你的“紫微”、“后土”、“玉清”、“勾陈”数量之和）。若如此做，你将这些牌以任意顺序置于牌堆顶。",
	["$dianhua1"] = "大道无形，点化无为。",
	["$dianhua2"] = "得此点化，必得大道。",
	["~zhangqiying"] = "米碎面散，我心欲绝。",

	["#weiwenzhugezhi"] = "夷洲使节",
	["weiwenzhugezhi"] = "卫温&诸葛直",
	["&weiwenzhugezhi"] = "卫温诸葛直",
	["illustrator:weiwenzhugezhi"] = "秋呆呆",
	["fuhai"] = "浮海",
	--[":fuhai"] = "出牌阶段对每名角色限一次，你可以展示一张手牌并选择上家或下家。该角色展示一张手牌，若你的牌点数不小于其展示的牌的点数，你弃置你展示的牌，然后继续对其上家或下家重复此流程；若你展示的牌点数小于其展示的牌的点数，则其弃置其展示的牌，然后你与其各摸X张牌（X为你此回合发动此技能选择的角色数），且你于此阶段不能再发动此技能。",
	[":fuhai"] = "出牌阶段对每名角色限一次，你可以选择上家或下家，你和该角色各展示一张手牌。若你的牌点数不小于其展示的牌的点数，你弃置你展示的牌，然后继续对其上家或下家重复此流程；若你展示的牌点数小于其展示的牌的点数，则其弃置其展示的牌，然后你与其各摸X张牌（X为你此回合发动此技能选择的角色数），且你于此阶段不能再发动此技能。",
	["$fuhai1"] = "宦海沉浮，生死难料！",
	["$fuhai2"] = "跨海南征，波涛起浮。",
	["fuhai_next"] = "下家",
	["fuhai_previous"] = "上家",
	["@fuhai-source-show"] = "请展示一张手牌",
	["@fuhai-show"] = "请展示一张手牌",
	["~weiwenzhugezhi"] = "吾皆海岱清士，岂料生死易逝。",
	
	["#zhanggong"] = "西域长歌",
	["zhanggong"] = "张恭",
	["illustrator:zhanggong"] = "B_Lee",
	["qianxinb"] = "遣信",
	[":qianxinb"] = "出牌阶段限一次，若牌堆中没有“信”，你可以选择一名角色并将任意张手牌放置于牌堆中X倍数的位置（X为存活角色数），称为“信”。该角色弃牌阶段开始时，若其手牌有其本回合获得的“信”，其选择一项：1.令你将手牌摸至四张；2.其本回合手牌上限-2。",
	["$qianxinb_card_in_hand"] = "%from 手牌中有“信” (%arg 技能)",
	["$qianxinb_debuff"] = "%from 手牌中有本回合获得的“信”且是 %arg 技能目标",
	["qianxinb-draw-maxcard"] = "遣信",
	["qianxinb_draw"] = "令其手牌摸至四张",
	["qianxinb_maxcard"] = "本回合手牌上限-2",
	["$qianxinb1"] = "兵困绝地，将至如归！",
	["$qianxinb2"] = "临危之际，速速来援！",
	["zhenxing"] = "镇行",
	[":zhenxing"] = "结束阶段开始时或当你受到伤害后，你可以观看牌堆顶至多三张牌，然后你获得其中与其余牌花色均不相同的一张牌。",
	["zhenxing_choose_number"] = "观看牌数量",
	["$zhenxing1"] = "东征西讨，募军百里挑一。",
	["$zhenxing2"] = "众口铄金，积毁销骨。",
	["~zhanggong"] = "大漠孤烟，孤立无援啊。",
	
	["#lukai"] = "武昌烈臣",
	["lukai"] = "吕凯",
	["illustrator:lukai"] = "OL",
	["tunan"] = "图南",
	[":tunan"] = "出牌阶段限一次，你可以令一名其他角色观看牌堆顶的一张牌，然后其选择一项：1.使用此牌（无距离限制）；2.将此牌当【杀】使用。",
	["tunan_slash"] = "将此牌当【杀】使用",
	["tunan_use"] = "使用此牌（无距离限制）",
	["@tunan"] = "请选择【杀】的目标",
	["~tunan"] = "选择一张牌→选择目标→点击确定",
	["@tunan_useCard"] = "请选择此牌的目标",
	["~tunan_useCard"] = "选择一张牌→选择目标→点击确定",
	["$tunan1"] = "敢问丞相，何日挥师南下？",
	["$tunan2"] = "攻伐之道，一念之间。",
	["bijing"] = "闭境",
	[":bijing"] = "结束阶段开始时，你可以令你的一张手牌于你的下回合开始之前称为“闭境”牌。其他角色的弃牌阶段开始时，若你于此回合失去过“闭境”牌，则其须弃置两张牌。准备阶段开始时，你弃置手牌中的“闭境”牌。",
	["@bijing"] = "你可以令一张手牌为“闭境”牌",
	["$bijing_discard"] = "因 %to 此回合失去过“闭境”牌，%from 须弃置两张牌",
	["$bijing1"] = "拒吴闭境，臣，誓保永昌！",
	["$bijing2"] = "一臣无二主，可战不可降！",
	["~lukai"] = "守节不易，吾愿舍身为蜀。",

	["@hate_to"] = "誓仇",

	["sec_jikang"] = "嵇康",
	["#sec_jikang"] = "峻峰孤松",
	["illustrator:sec_jikang"] = "眉毛子",
	["sec_qingxian"] = "清弦",
	[":sec_qingxian"] = "出牌阶段限一次，你可以选择至多X名其他角色并弃置等量的牌（X为你的体力值）。这些角色依次和你比较装备区里的牌数：小于你的角色回复1点体力；等于你的角色摸一张牌；大于你的角色失去1点体力。若你选择的目标等于X，你摸一张牌。",
	["$sec_qingxian1"] = "抚琴拨弦，悠然自得。",
	["$sec_qingxian2"] = "寄情于琴，和于天地。",
	["sec_juexiang"] = "绝响",
	[":sec_juexiang"] = "当你死亡时，杀死你的角色弃置其装备区里的所有牌并流失1点体力，然后你可以令一名其他角色获得“残韵”，之后其可以弃置场上一张梅花牌，若其如此做，其获得“绝响”。",
	["$sec_juexiang1"] = "此曲，不能绝矣。",
	["$sec_juexiang2"] = "一曲琴音，为我送别。",
	["sec_juexiang-invoke"] = "你可以发动“绝响”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["canyun"] = "残韵",
	[":canyun"] = "出牌阶段限一次，你可以选择至多X名你未选择过的其他角色并弃置等量的牌（X为你的体力值）。这些角色依次和你比较装备区里的牌数：小于你的角色回复1点体力；等于你的角色摸一张牌；大于你的角色失去1点体力。若你选择的目标等于X，你摸一张牌。",
	["$canyun1"] = "抚琴拨弦，悠然自得。",
	["$canyun2"] = "寄情于琴，和于天地。",
	["~sec_jikang"] = "多少遗恨俱随琴音去……",

	
	["twyj_caohong"] = "TW曹洪",
	["&twyj_caohong"] = "曹洪",
	["#twyj_caohong"] = "骠骑将军",
	["illustrator:twyj_caohong"] = "黄人尤",
	["twyj_huzhu"] = "护主",
	[":twyj_huzhu"] = "出牌阶段限一次，若你的装备区有牌，你可以指定一名其他角色，交给你一张手牌，并获得你装备区的一张牌。若其体力值不大于你，你可以令其回复1点体力。",
	["@twyj_huzhu"] = "请交给 %src 一张手牌",
	["twyj_liancai"] = "敛财",
	[":twyj_liancai"] = "结束阶段，你可以翻面，并获得一名角色装备区里的一张牌；每当你翻面时，你可以将手牌补至体力值。",
	["twyj_liancai_turnover"] = "手牌补至体力值",
	
	["twyj_dingfeng"] = "TW丁奉",
	["&twyj_dingfeng"] = "丁奉",
	["#twyj_dingfeng"] = "勇冠全军",
	["illustrator:twyj_dingfeng"] = "柯郁萍",
	["twyj_qijia"] = "弃甲",
	[":twyj_qijia"] = "出牌阶段（装备区每个位置限一次），你可以弃置一张在装备区的牌，视为对一名攻击范围内的其他角色使用【杀】（你以此法使用的【杀】不计入出牌阶段【杀】的使用次数）。",
	["twyj_zhuchen"] = "诛綝",
	[":twyj_zhuchen"] = "出牌阶段，你可以弃置一张【酒】或【桃】并指定一名角色，此阶段视为与该角色距离为1。",

	["twyj_maliang"] = "TW马良",
	["&twyj_maliang"] = "马良",
	["#twyj_maliang"] = "白眉令士",
	["illustrator:twyj_maliang"] = "廖昌翊",
	["twyj_rangyi"] = "攘夷",
	--[":twyj_rangyi"] = "出牌阶段限一次，你可以将所有手牌（至少一张）交给一名其他角色，该角色可以从你给的手牌中合理使用一张手牌，即目标获得使用一张手牌的额外出牌阶段。该张牌结算前，需把剩余手牌还给你，若其不使用手牌，则视为你对其造成1点伤害且手牌不能还给你。",
	[":twyj_rangyi"] = "出牌阶段限一次，你可以将所有手牌（至少一张）交给一名其他角色，该角色可以从你给的手牌中合理使用一张手牌（即目标获得使用一张手牌的额外出牌阶段），该张牌结算前，需把剩余手牌还给你。若其不使用手牌，则视为你对其造成1点伤害且手牌不能还给你。",
	["@twyj_rangyi"] = "请使用一张手牌",
	["~twyj_rangyi"] = "选择一张牌→选择目标→点击确定",
	["twyj_baimei"] = "白眉",
	[":twyj_baimei"] = "锁定技，若你没有手牌，你防止你受到的任何的锦囊牌的伤害和属性的伤害。",
	["#twyj_baimei_Protect"] = "%from 的“<font color=\"yellow\"><b>白眉</b></font>”效果被触发，防止了 %arg 点伤害[%arg2]",

	["#heg_lvmeng"] = "士别三日",
	["heg_lvmeng"] = "吕蒙-国",
	["&heg_lvmeng"] = "吕蒙",
	["illustrator:heg_lvmeng"] = "樱花闪乱",
	["heg_keji"] = "克己",
	[":heg_keji"] = "锁定技，若你未于出牌阶段内使用过颜色不同的牌，则你本回合的手牌上限+4。",
	["$heg_keji1"] = "蓄力待时，不争首功",
	["$heg_keji2"] = "最好的机会还在等着我",
	["heg_mouduan"] = "谋断",
	[":heg_mouduan"] = "结束阶段，若你于出牌阶段内使用过四种花色或三种类别的牌，则你可以移动场上的一张牌。",
	["@heg_mouduan"] = "你可以移动场上的一张牌",
	["~heg_mouduan"] = "选择一名角色→点击确定",
	["@heg_mouduan-to"] = "请选择移动此卡牌的目标角色",
	["$heg_mouduan1"] = "",
	["$heg_mouduan2"] = "",
	["~heg_lvmeng"] = "你……给我等着！",


	["mobile_simazhao"] = "司马昭",
	["#mobile_simazhao"] = "四海威服",
	["illustrator:mobile_simazhao"] = "Thinking",
	["daigong"] = "怠攻",
	[":daigong"] = "<font color=\"green\"><b>每回合限一次，</b></font>当你受到伤害时，你可以展示所有手牌并令伤害来源选择一项：1.交给你一张与所有你手牌花色均不同的一张牌；2.防止此伤害。",
	["$daigong1"] = "",
	["$daigong2"] = "",
	["daigong_no_damage"] = "防止此伤害",
	["daigong_give_card"] = "交给其一张与所有其手牌花色均不同的一张牌",
	["@daigong-give"] = "请交给 %src 一张牌",
	["#daigong_Protect"] = "%from 的“<font color=\"yellow\"><b>怠攻</b></font>”效果被触发，防止了 %arg 点伤害[%arg2]",
	["mobile_zhaoxin"] = "昭心",
	[":mobile_zhaoxin"] = "出牌阶段限一次，你可以将任意张牌置于武将牌上，称为“望”(你的“望”至多为3)，然后摸等量的牌。你和你攻击范围内角色的摸牌阶段结束后，其可以获得一张“望”，然后你可以对其造成1点伤害。",
	["$mobile_zhaoxin1"] = "",
	["$mobile_zhaoxin2"] = "",
	["wang"] = "望",
	["@mobile_zhaoxin"] = "你可以发动“昭心”",
	["~mobile_zhaoxin"] = "选择一张牌→点击确定",
	["mobile_zhaoxin:obtain"] = "你是否要获得此“望”牌 ( %src ) ?",
	["mobile_zhaoxin_damage:damage"] = "你是否要对 %src 造成1点伤害?",
	["~mobile_simazhao"] = "",

	["mobile_wangyuanji"] = "王元姬",
	["#mobile_wangyuanji"] = "情雅抑华",
	["illustrator:mobile_wangyuanji"] = "凝聚永恒",
	["qianchong"] = "谦冲",
	[":qianchong"] = "锁定技，若你的装备区里的牌：均为黑色，你拥有“帷幕”；均为红色，你拥有“明哲”。锁定技，出牌阶段开始时，若你不满足上述条件，则你选择一种类别的牌，本回合你使用此类别的牌无距离限制且不计入使用次数。",
	["$qianchong1"] = "",
	["$qianchong2"] = "",
	["$qianchong3"] = "",
	["qianchong_basic"] = "基本牌无次数和距离限制",
	["qianchong_trick"] = "锦囊牌无次数和距离限制",
	["qianchong_equip"] = "装备牌无次数和距离限制",
	["shangjian"] = "尚俭",
	[":shangjian"] = "一名角色的结束阶段开始时，若你此回合失去牌的数量不大于体力值，你可以摸X张牌（X为此回合失去牌的数量）。",
	["$shangjian1"] = "",
	["$shangjian2"] = "",
	["~mobile_wangyuanji"] = "",

	["sec_tangzi"] = "唐咨-第二版",
	["&sec_tangzi"] = "唐咨",
	["#sec_tangzi"] = "工学之奇才",
	["illustrator:sec_tangzi"] = "NOVART",
	["sec_xingzhao"] = "兴棹",
	[":sec_xingzhao"] = "锁定技，你的回合开始时，若场上受伤的角色数为：1，你本回合拥有“恂恂”；2.你本回合使用装备牌时摸一张牌；3.你本回合跳过弃牌阶段。",
	["$sec_xingzhao1"] = "拿些上好的木料来。",
	["$sec_xingzhao2"] = "精挑细选，方能成百年之计。",
	["$sec_xingzhao3"] = "让我先探他一探。",
	["$sec_xingzhao4"] = "船也不是一天就能造出来。",
	["~sec_xingzhao"] = "偷工减料，要不得呀！",

	["sec_sufei"] = "苏飞-第二版",
	["&sec_sufei"] = "苏飞",
	["#sec_sufei"] = "与子同胞",
	["illustrator:sec_sufei"] = "兴游",
	["sec_lianpian"] = "联翩",
	[":sec_lianpian"] = "你于出牌阶段使用牌连续指定同一名角色为目标(或之一)时，你可以摸一张牌。若如此做，你可以将此牌交给该角色。此效果每回合至多触发三次。",
	["$sec_lianpian1"] = "需持续投入，方有回报。",
	["$sec_lianpian2"] = "心无旁骛，断而敢行！",
	["sec_lianpian-invoke"] = "你可以将此摸牌交给其中一名角色",
	["~sec_sufei"] = "恐不能再与兴霸兄……并肩奋战了……",

	["sec_huangquan"] = "黄权-第二版",
	["&sec_huangquan"] = "黄权",
	["#sec_huangquan"] = "道绝殊途",
	["illustrator:sec_huangquan"] = "兴游",
	["sec_dianhu"] = "点虎",
	[":sec_dianhu"] = "锁定技，游戏开始时，你指定一名其他角色。当你对该角色其造成伤害后或该角色回复体力后，你摸一张牌。",
	["sec_dianhu-invoke"] = "你可以发动“点虎”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["$sec_dianhu1"] = "就用你，给我军祭旗！",
	["$sec_dianhu2"] = "预则立，不预则废！",
	["sec_jianji"] = "谏计",
	["@sec_jianji"] = "你可以发动“谏计”使用牌",
	[":sec_jianji"] = "出牌阶段限一次，你可以令一名其他角色摸一张牌，然后其可以使用之。",
	["$sec_jianji1"] = "锦上添花，不如雪中送炭。",
	["$sec_jianji2"] = "密计交于将军，可解燃眉之困。",
	["~sec_huangquan"] = "魏王厚待于我，降魏又有何错？",

	["$SearchFailed"] = "牌堆无技能要找的牌",

	["ol_caochun"] = "曹纯",
	["#ol_caochun"] = "虎豹骑首",
	["illustrator:ol_caochun"] = "depp",
	["ol_shanjia"] = "缮甲",
	[":ol_shanjia"] = "出牌阶段开始时，你可以摸三张牌，然后弃置三张牌（本局游戏你每失去过一张装备区里的牌，便少弃置一张），若你本次没有弃置基本牌或锦囊牌，你可视为使用【杀】（不计入使用次数限制）。",
	["@ol_shanjia"] = "请弃置若干张牌",
	["~ol_shanjia"] = "选择若干张牌（若有）→点击确定",
	["$ol_shanjia1"] = "",
	["$ol_shanjia2"] = "",
	["~ol_caochun"] = "",
	
	["mangyazhang"] = "忙牙长",
	["#mangyazhang"] = "截头蛮锋",
	["illustrator:mangyazhang"] = "北★MAN",
	["jiedao"] = "截刀",
	[":jiedao"] = "当你每回合第一次造成伤害时，你可令此伤害至多+X（X为你损失的体力值）。然后若受到此伤害的角色没有死亡，你弃置等同于此伤害加值的牌。",
	["$jiedao_increase_damage"] = "%from 执行“%arg”的效果，%card 的伤害值+%arg2",
	["$jiedao1"] = "",
	["$jiedao2"] = "",
	["~mangyazhang"] = "",
	
	["xugong"] = "许贡",
	["#xugong"] = "独计击流",
	["illustrator:xugong"] = "红字虾",
	["biaozhao"] = "表召",
	[":biaozhao"] = "结束阶段开始时，你可以将一张牌置于武将牌上，称为“表”。当有一张与“表”花色点数均相同的牌进入弃牌堆时，移去“表”且你失去1点体力，若此牌是其他角色因弃置而进入弃牌堆，则改为该角色获得“表”。准备阶段开始时，若你的武将牌上有“表”，则移去“表”然后你选择一名角色，该角色回复1点体力且将手牌摸至与全场手牌数最多的人相同（最多摸五张）。",
	["@biaozhao"] = "你可以将一张牌置于武将牌上",
	["biao"] = "表",
	["biaozhao-invoke"] = "选择一名角色回复1点体力且将手牌摸至与全场手牌数最多的人相同（最多摸五张）",
	["$biaozhao1"] = "",
	["$biaozhao2"] = "",
	["yechou"] = "业仇",
	[":yechou"] = "当你死亡时，你可以选择一名已损失体力值大于1的角色。每个回合结束时，该角色失去1点体力直到其回合开始时。",
	["yechou-invoke"] = "你可以发动“业仇”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["$yechou1"] = "",
	["$yechou2"] = "",
	["~xugong"] = "",
	
	
    
    
    ["lukuangluxiang"] = "吕旷吕翔",
    ["&lukuangluxiang"] = "吕旷吕翔 ",
	["#lukuangluxiang"] = "降将封侯 ",
	["~lukuangluxiang"] = "此处可是新野……",    
    ["qigong"] = "齐攻",
    [":qigong"] = "你使用的仅指定单一目标的【杀】被【闪】抵消后，你可令一名角色对该目标再使用一张无距离限制的【杀】，此【杀】不可被响应。 ",
    ["liehou"] = "列侯",
    [":liehou"] = "出牌阶段限一次，你可以令你攻击范围内的一名有手牌的角色交给你一张手牌。若如此做，你需要将一张手牌交给你攻击范围内的另一名其他角色。",
    ["qigong-slash"] = "你可以对 %src 使用一张【杀】",
    ["qigong-invoke"] = "你可以发动“齐攻”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
    ["liehou-invoke"] = "“列侯”<br/> <b>操作提示</b>: 选择一名攻击范围内的角色→点击确定<br/>",
    ["$liehou1"] = "识时务者为俊杰。",
    ["$liehou2"] = "丞相有令，尔敢不从？",
    ["$qigong1"] = "打虎亲兄弟！",
    ["$qigong2"] = "兄弟齐心，其利断金！",
    
    
    ["gd_shenpei"] = "审配",
    ["&gd_shenpei"] = "审配 ",
	["#gd_shenpei"] = "总幕府",
	["~gd_shenpei"] = "吾君在北，但求面北而亡。", 
    ["gangzhi"] = "刚直",
    [":gangzhi"] = "锁定技，其他角色对你造成的伤害、你对其他角色造成的伤害均视为体力流失。",
    ["beizhan"] = "备战",
    [":beizhan"] = "回合结束时，你可以令一名角色将手牌补至体力上限(至多为5)。该角色回合开始时，若其手牌数为全场最多，则其本回合内不能使用牌指定其他角色为目标。",
    ["beizhan-invoke"] = "你可以发动“备战”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
    ["$gangzhi1"] = "死便死，降？断不能降！",
    ["$gangzhi2"] = "只恨箭支太少，不能射杀汝等！",
    ["$beizhan1"] = "今伐曹氏，譬如覆手之举。",
    ["$beizhan2"] = "十，则围之；五，则攻之。",

    ["gd_xunchen"] = "荀谌",
    ["&gd_xunchen"] = "荀谌 ",
	["#gd_xunchen"] = "单锋谋孤城",
	["~gd_xunchen"] = "吾欲赴死，断不做背主之事！", 
    ["fenglue"] = "锋略",
    [":fenglue"] = "出牌阶段开始时，你可以与一名角色拼点。若你：赢，其将其手牌区、装备区、判定区各一张牌交给你；没赢，你交给其一张牌。拼点结算后你可以令其获得你用于此次拼点的牌。",
    ["moushi"] = "谋识",
    [":moushi"] = "出牌阶段限一次，你可以将一张手牌交给一名角色。若如此做，当其于其下回合的出牌阶段内对一名角色造成伤害后，若是此阶段其第一次对该角色造成伤害，你摸一张牌。 ",
    ["@fenglue-card"] = "你可以发动“锋略”",
    ["~fenglue1"] = "选择一名角色→点击确定",
    ["$fenglue1"] = "将军有让贤之名，而身安于太山也，实乃上策。",
    ["$fenglue2"] = "汝能比得上我家主公吗？",
    ["$moushi1"] = "官渡决战，袁公必胜而曹氏必败。",
    ["$moushi2"] = "吾今辅佐袁公，定不会使其覆巢。",

    ["gd_gaolan"] = "高览",
    ["&gd_gaolan"] = "高览 ",
	["#gd_gaolan"] = "名门的峦柱",
	["~gd_gaolan"] = "郭图小辈之计，误军哪！", 
    ["ol_xiying"] = "袭营",
    [":ol_xiying"] = "出牌阶段开始时，你可以弃置一张非基本手牌并令所有其他角色选择一项：1.弃置一张牌；2.此阶段其不能使用或打出牌。结束阶段，若你于本回合出牌阶段内发动过“袭营”且造成过伤害，你从牌堆中获得一张【杀】或伤害类锦囊牌。 ",
    ["$ol_xiying2"] = "此番若攻不能成，我军恐难以再战。",
    ["$ol_xiying1"] = "速袭曹营，以解乌巢之难！",
    ["@xiying"] = "你可以发动“袭营”",
    ["@xiying_CardLimitation"] = "你需弃置一张牌或此阶段其不能使用或打出牌",
 

	["caochun"] = "曹纯-ol",
	["&caochun"] = "曹纯",
	["#caochun"] = "虎豹骑首",
	["illustrator:caochun"] = "depp",
	["shanjia"] = "缮甲",
	[":shanjia"] = "出牌阶段开始时，你可以摸三张牌，弃置三张牌（本局游戏你每失去过一张装备牌，便少弃置一张）。若你未以此法弃置基本牌和锦囊牌，你可以视为使用一张无距离限制且不计入次数的【杀】。",
	["@shanjia"] = "请弃置若干张牌",
	["~shanjia"] = "选择若干张牌（若有）→点击确定",
	["$shanjia1"] = "缮甲厉兵，伺机而行。",
	["$shanjia2"] = "战，当取精锐之兵，而弃驽钝也。",
	["~caochun"] = "银甲在身，竟败于你手……",

	["caoshuang"] = "曹爽",
	["&caoshuang"] = "曹爽",
	["#caoshuang"] = "托孤辅政",
	["~caoshuang"] = "悔不该降了司马懿……",
    ["tuogu"] = "托孤",
    [":tuogu"] = "一名角色死亡时，你可以令其选择其武将牌上一个技能（限定技，觉醒技，主公技除外）。你失去以此法获得的技能，你获得其选择的技能。",
    ["ol_shanzhuan"] = "擅专",
    [":ol_shanzhuan"] = "当你对其他角色造成伤害后，若其判定区没有牌，你将其一张牌置于其判定区。若此牌不为延时锦囊牌且颜色为：红色，此牌视为【乐不思蜀】；黑色，此牌视为【兵粮寸断】；回合结束时，若你本回合未造成过伤害，你可以摸一张牌。",
    ["$tuogu1"] = "君托以六尺之孤，爽当寄百里之命。",
    ["$tuogu2"] = "先帝以大事托我，任重而道远。",
    ["$ol_shanzhuan1"] = "打入冷宫，禁足绝食！",
    ["$ol_shanzhuan2"] = "我言既出，谁敢不从？",

	["guansuo"] = "关索",
	["#guansuo"] = "倜傥孑侠",
	["illustrator:guansuo"] = "depp",
	["zhengnan"] = "征南",
	[":zhengnan"] = "当其他角色死亡后，你可以摸三张牌，然后获得一个技能：武圣；制蛮；当先。",
	["$zhengnan1"] = "末将愿承父志，随丞相出征~",
	["$wusheng8"] = "逆贼！可识得关氏之勇！",
	["$zhiman3"] = "蛮夷可抚，不能剿。",
	["$dangxian3"] = "各位将军，且让小辈先行出战！",
	["xiefang"] = "撷芳",
	[":xiefang"] = "锁定技，你与其他角色距离-X。（X为女性角色数）",
	["~guansuo"] = "只恨天下未平，空留遗志~",

	["ol_baosanniang"] = "鲍三娘-ol",
	["&ol_baosanniang"] = "鲍三娘",
	["#ol_baosanniang"] = "青不协扶",
	["~ol_baosanniang"] = "我还想与你，共骑这雪花驹……",
    ["ol_wuniang-slash"] = "你可以对 %src 使用一张【杀】",
    ["ol_wuniang"] = "武娘",
    [":ol_wuniang"] = "<font color=\"green\"><b>每回合限一次，</b></font>当你于回合内对仅一名角色使用的【杀】结算结束后，你可以令其可以对你使用一张【杀】。你摸一张牌且本回合你可以多使用一张【杀】。",
    ["ol_xushen"] = "许身",
    [":ol_xushen"] = "限定技，当你进入濒死状态时，你可以回复体力至1点并获得“镇南”。若“关索”不在场，你可以令一名男性角色选择是否用“关索”代替其武将牌。",
    ["ol_xushen_change"] = "许身",
    ["ol_zhennan"] = "镇南",
    [":ol_zhennan"] = "【南蛮入侵】对你无效；出牌阶段限一次，你可以将至多X张手牌当做一张【南蛮入侵】对等量的其他角色使用（X为存活的其他角色数）。",
    ["$ol_wuniang1"] = "虽为女子身，不输男儿郎。",
    ["$ol_wuniang2"] = "剑舞轻影，沙场克敌。",
    ["$ol_xushen1"] = "救命之恩，涌泉相报。",
    ["$ol_xushen2"] = "解我危难，报君华彩。",
    ["$ol_zhennan1"] = "镇守南中，夫君无忧。",
    ["$ol_zhennan2"] = "与君携手，定平蛮夷。",

	["ol_wolongfengchu"] = "卧龙&凤雏",
	["&ol_wolongfengchu"] = "卧龙凤雏",
	["#ol_wolongfengchu"] = "扭转乾坤",
	["~ol_wolongfengchu"] = "铁链，东风，也难困这魏军。",
    ["luanfen"] = "鸾凤",
    [":luanfen"] = "限定技，一名角色进入濒死状态时，若其体力上限不小于你，你可以令其体力值回复至3，恢复其被废除的所有装备栏，令其手牌补至6-X张(X为以此法恢复的装备栏数)。若其为你，则重置你通过“游龙”使用过的牌名。",
    ["@luanfen"] = "鸾凤",
    ["youlong"] = "游龙",
	[":youlong"] = "转换技，<font color=\"green\"><b>每轮各限一次，</b></font>你可以废除你的一个装备栏，视为使用一张未以此法使用过的，①普通锦囊牌；②基本牌。",
	[":youlong2"] = "转换技，<font color=\"green\"><b>每轮各限一次，</b></font>你可以废除你的一个装备栏，视为使用一张未以此法使用过的，<font color=\"#01A5AF\"><s>①普通锦囊牌</s></font>；②基本牌。",
	[":youlong1"] = "转换技，<font color=\"green\"><b>每轮各限一次，</b></font>你可以废除你的一个装备栏，视为使用一张未以此法使用过的，①普通锦囊牌；<font color=\"#01A5AF\"><s>②基本牌。</s></font>",
    ["youlong_select"] = "游龙",
    ["@youlong"] = "请选择 %src 目标",
    ["~youlong"] = "选择若干名角色→点击确定",
    ["$youlong1"] = "赤壁献策，再谱春秋。",
    ["$youlong2"] = "卧龙出山，谋定万古。",
    ["$luanfen1"] = "凤栖枯木，浴火涅槃。",
    ["$luanfen2"] = "青鸾归羽，雏凤还巢。",


	["panshu"] = "潘淑",
	["&panshu"] = "潘淑",
	["#panshu"] = "江东神女",
	["~panshu"] = "本为织女，幸蒙帝垂怜……", 
    ["ol_weiyi"] = "威仪",
    [":ol_weiyi"] = "<font color=\"green\"><b>每名角色限一次，</b></font>当一名角色受到伤害后，若其体力值：不小于你，你可以令其失去1点体力；不大于你，你可以令其回复1点体力。",
    ["ol_weiyi_losehp"] = "威仪-你可以令其失去1点体力",
    ["ol_weiyi_recover"] = "威仪-你可以令其回复1点体力",
    ["jinzhi"] = "锦织",
    [":jinzhi"] = "：当你需要使用或打出基本牌时，你可以弃置X张颜色相同的牌并摸一张牌，视为你使用此基本牌。（X为你本轮发动此技能的次数）",
	["jinzhi_select"]  ="锦织",
	["@@jinzhi"]= "你可以弃置X张颜色相同的牌 视为你使用或打出 %src。",
	["~jinzhi"] = "选择任意数量张颜色相同的牌→点击确定",
    ["$ol_weiyi1"] = "无威仪者，不可奉社稷。",
    ["$ol_weiyi2"] = "有威仪者，进止雍容。",
    ["$jinzhi1"] = "织锦为旗，以扬威仪。",
    ["$jinzhi2"] = "坐而织锦，立则为仪。",

    ["extension_fengfangnu_e_card"] = "冯方女专属装备",
    ["gold_comb"] = "金梳",
	[":gold_comb"] = "装备牌·宝物<br /><b>宝物技能</b>：锁定技，出牌阶段结束时，你将手牌补至手牌上限。（至多摸至五张）",
	["GoldCombSkill"] = "金梳",
    ["joan_comb"] = "瓊梳",
	[":joan_comb"] = "装备牌·宝物<br /><b>宝物技能</b>：当你受到伤害时，你可以弃置X张牌，防止此伤害。（X为伤害值）",
	["JoanCombSkill"] = "瓊梳", 
    ["rhino_comb"] = "犀梳",
	[":rhino_comb"] = "装备牌·宝物<br /><b>宝物技能</b>：判定阶段开始前，你可以选择跳过本回合判定阶段或跳过本回合弃牌阶段。",
	["RhinoCombSkill"] = "犀梳",  
    ["RhinoComb_judge"] = "跳过本回合判定阶段",
    ["RhinoComb_discard"] = "跳过本回合弃牌阶段",
 
	["fengfangnu"] = "冯方女",
	["&fengfangnu"] = "冯方女",
	["#fengfangnu"] = "天姿国色",
	["~fengfangnu"] = "毒妇妒我……",  
    ["zhuangshu_rc"] = "犀梳",
    ["zhuangshu_jc"] = "瓊梳",
    ["zhuangshu_gc"] = "金梳",
    ["zhuangshu"] = "妆梳",
    [":zhuangshu"] = "游戏开始时，你选择一张“宝梳”置入宝物栏；一名角色的回合开始时，你可以弃置一张基本/锦囊/装备牌，将【瓊梳】/【犀梳】/【金梳】从游戏外或场上置入其宝物栏；当“宝梳”离开装备区前，销毁之。",
    ["@zhuangshu"] = "你可以发动“妆梳”",
    ["chuti"] = "垂涕",
    [":chuti"] = "<font color=\"green\"><b>每回合限一次，</b></font>当你或装备区有“宝梳”的角色的牌因弃置而置入弃牌堆后，你可以使用其中可使用的一张牌。",
    ["@chuti"] = "你可以使用此牌",
    ["~chuti"] = "选择目标",
    [":GoldCombSkill"] = "锁定技，出牌阶段结束时，你将手牌补至手牌上限。（至多摸至五张）",
    [":RhinoCombSkill"] = "判定阶段开始前，你可以选择跳过本回合判定阶段或跳过本回合弃牌阶段。",
    [":JoanCombSkill"] = "当你受到伤害时，你可以弃置X张牌，防止此伤害。（X为伤害值）",
    ["$zhuangshu1"] = "殿前妆梳，风姿绝世。",
    ["$zhuangshu2"] = "顾影徘徊，丰容靓饰。",
    ["$gold_comb"] = "金梳富贵，蒙君宠幸。",
    ["$joan_comb"] = "鬓怯琼梳，朱颜消瘦。",
    ["$rhino_comb"] = "犀梳斜插，醉倚阑干。",
    ["$chuti1"] = "悲愁垂涕，三日不食。",
    ["$chuti2"] = "宜数涕泣，示忧愁也。",
    ["$GoldCombSkill"] = "金梳富贵，蒙君宠幸。",
    ["$RhinoCombSkill"] = "犀梳斜插，醉倚阑干。",
    ["$JoanCombSkill"] = "鬓怯琼梳，朱颜消瘦。",

    ["liangxing"] = "梁兴",
    ["&liangxing"] = "梁兴",
	["#liangxing"] = "刚毅有度",
	["~liangxing"] = "夏侯渊，你竟敢！",    
    ["lulue"] = "掳掠",
    [":lulue"] = "出牌阶段开始时，你可以选择一名有手牌且手牌数小于你的角色，然后其选择一项：1. 将所有手牌交给你，然后你将武将牌翻面；2. 将武将牌翻面，然后视为对你使用一张【杀】。",
    ["lulue_slash"] = "将武将牌翻面，视为对梁兴使用一张【杀】",
    ["lulue_give"] = "将所有手牌交给梁兴",
    ["zhuxi"] = "追袭",
    [":zhuxi"] = "锁定技，正反面状态与你不同的角色对你造成的伤害时或受到你的伤害时，此伤害+1。 ",
    ["$lulue1"] = "趁火打劫，乘危掳掠！",
    ["$lulue2"] = "天下大乱，掳掠以自保。",
    ["$zhuxi1"] = "得势追袭，胜望在握！",
    ["$zhuxi2"] = "诸将得令，追而袭之！",
 
 
    
    
    
    
    
    
    
    
    
    
    
    
    
    


}

if sgs.GetConfig("starfire", true) then
	sgs.LoadTranslationTable{
		[":qicai"] = "锁定技，你使用锦囊牌无距离限制；锁定技，其他角色不能弃置你装备区里的不为坐骑牌的牌。",
		[":nosqicai"] = "锁定技，你使用锦囊牌无距离限制；锁定技，其他角色不能弃置你装备区里的防具和宝物牌。",
	}
else
	sgs.LoadTranslationTable{
		[":nosqicai"] = "锁定技，你使用锦囊牌无距离限制。",
		[":qicai"] = "锁定技，你使用锦囊牌无距离限制；锁定技，其他角色不能弃置你装备区里的防具和宝物牌。",
	}
end

if sgs.GetConfig("shifei_down", true) then
	sgs.LoadTranslationTable{
		[":shifei"] = "当你需要使用或打出【闪】时，你可以令当前回合角色摸一张牌，然后你弃置手牌数最多的一名角色的一张牌，视为你使用或打出【闪】。",
	}
else
	sgs.LoadTranslationTable{
		 [":shifei"] = "当你需要使用或打出【闪】时，你可以令当前回合角色摸一张牌，然后若其手牌数不为全场最多，你弃置手牌数最多的一名角色的一张牌，视为你使用或打出【闪】。",
	}
end

if sgs.GetConfig("taoluan_down", true) then
	sgs.LoadTranslationTable{
		[":taoluan"] = "若没有角色处于濒死状态，你可以将一张牌当一种未以此法使用过的基本牌或非延时类锦囊牌使用，然后选择一名其他角色，其选择一项：1.交给你一张与之类别不同的牌2.令你失去1点体力且“滔乱”于此回合内无效。",
	}
else
	sgs.LoadTranslationTable{
		[":taoluan"] = "你可以将一张牌当一种未以此法使用过的基本牌或非延时类锦囊牌使用，然后选择一名其他角色，其选择一项：1.交给你一张与之类别不同的牌2.令你失去1点体力且“滔乱”于此回合内无效。",
	}
end

return {extension_heg, extension_hulaoguan, extension_twyj, extension_guandu, extension_dragonboat, extension_whlw, extension_zlzy, extension_mobile, extension, hulaoguan_card, extension_pray, extension_fengfangnu_e_card}